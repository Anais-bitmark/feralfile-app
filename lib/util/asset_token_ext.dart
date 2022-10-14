import 'dart:io';

import 'package:autonomy_flutter/common/environment.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/cloud_database.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/datetime_ext.dart';
import 'package:autonomy_flutter/util/feralfile_extension.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:collection/collection.dart';
import 'package:libauk_dart/libauk_dart.dart';
import 'package:nft_collection/models/asset_token.dart';

extension AssetTokenExtension on AssetToken {
  static final Map<String, Map<String, String>> _tokenUrlMap = {
    "MAIN": {
      "ethereum": "https://etherscan.io/token/{contract}?a={tokenId}",
      "tezos": "https://tzkt.io/{contract}/tokens/{tokenId}/transfers"
    },
    "TEST": {
      "ethereum": "https://rinkeby.etherscan.io/token/{contract}?a={tokenId}",
      "tezos": "https://tzkt.io/{contract}/tokens/{tokenId}/transfers"
    }
  };

  bool get hasMetadata {
    // FIXME
    return galleryThumbnailURL != null;
  }

  String? get tokenURL {
    final network = Environment.appTestnetConfig ? "TEST" : "MAIN";
    final url = _tokenUrlMap[network]?[blockchain]
        ?.replaceAll("{tokenId}", tokenId ?? "")
        .replaceAll("{contract}", contractAddress ?? "");
    return url;
  }

  Future<WalletStorage?> getOwnerWallet() async {
    if (contractAddress == null || tokenId == null) return null;
    if (!(blockchain == "ethereum" && contractType == "erc721") &&
        !(blockchain == "tezos" && contractType == "fa2")) return null;

    //check asset is able to send
    final personas = await injector<CloudDatabase>().personaDao.getPersonas();

    WalletStorage? wallet;
    for (final persona in personas) {
      final String address;
      if (blockchain == "ethereum") {
        address = await persona.wallet().getETHAddress();
      } else {
        address = (await persona.wallet().getTezosWallet()).address;
      }
      if (owners.containsKey(address)) {
        wallet = persona.wallet();
        break;
      }
    }
    return wallet;
  }

  String? getPreviewUrl() {
    if (medium == null) {
      return previewURL;
    }
    if (previewURL != null) {
      return _replaceIPFSPreviewURL(previewURL!, medium!);
    }
    return null;
  }

  String? getThumbnailUrl() {
    if (thumbnailURL != null && thumbnailID != null) {
      return _refineToCloudflareURL(thumbnailURL!, thumbnailID!, "preview");
    }
    return thumbnailURL;
  }

  String? getGalleryThumbnailUrl() {
    if (galleryThumbnailURL != null && thumbnailID != null) {
      return _refineToCloudflareURL(
          galleryThumbnailURL!, thumbnailID!, "thumbnail");
    }
    return galleryThumbnailURL;
  }

  String? getBlockchainUrl() {
    final network = Environment.appTestnetConfig ? "TESTNET" : "MAINNET";
    String? url = blockchainUrl;
    if (url == null || url.isEmpty != false) {
      switch ("${network}_$blockchain") {
        case "MAINNET_ethereum":
          url = "https://etherscan.io/address/$contractAddress";
          break;

        case "TESTNET_ethereum":
          url = "https://rinkeby.etherscan.io/address/$contractAddress}";
          break;

        case "MAINNET_tezos":
        case "TESTNET_tezos":
          url = "https://tzkt.io/$contractAddress";
          break;

        case "MAINNET_bitmark":
          url = "https://registry.bitmark.com/bitmark/$id";
          break;
        case "TESTNET_bitmark":
          url = "https://registry.test.bitmark.com/bitmark/$id";
          break;
      }
    }
    return url;
  }
}

String _replaceIPFSPreviewURL(String url, String medium) {
  // Don't replace CloudflareIPFS in iOS
  // iOS can't render a cloudfare video issue
  // More information: https://stackoverflow.com/questions/33823411/avplayer-fails-to-play-video-sometimes
  if (Platform.isIOS && medium == 'video') {
    return url;
  }

  return url.replacePrefix(DEFAULT_IPFS_PREFIX, Environment.autonomyIpfsPrefix);
}

String _replaceIPFS(String url) {
  return url.replacePrefix(DEFAULT_IPFS_PREFIX, Environment.autonomyIpfsPrefix);
}

String _refineToCloudflareURL(String url, String thumbnailID, String variant) {
  return thumbnailID.isEmpty
      ? _replaceIPFS(url)
      : "$CLOUDFLAREIMAGEURLPREFIX$thumbnailID/$variant";
}

AssetToken createPendingAssetToken({
  required Exhibition exhibition,
  required String owner,
  required String tokenId,
}) {
  final indexerId = exhibition.airdropInfo?.getTokenIndexerId(tokenId);
  final artist = exhibition.artists.firstOrNull;
  final artwork = exhibition.artworks.firstOrNull;
  final contract = exhibition.contracts.firstOrNull;
  return AssetToken(
    artistName: artist?.fullName ?? artist?.alias,
    artistURL: null,
    artistID: artist?.id,
    assetData: null,
    assetID: null,
    assetURL: null,
    basePrice: null,
    baseCurrency: null,
    blockchain: "tezos",
    blockchainUrl: null,
    fungible: false,
    contractType: null,
    tokenId: tokenId,
    contractAddress: contract?.address,
    desc: artwork?.description,
    edition: 0,
    id: indexerId ?? "",
    maxEdition: exhibition.maxEdition,
    medium: null,
    mimeType: null,
    mintedAt: artwork?.createdAt != null
        ? dateFormatterYMDHM.format(artwork!.createdAt!).toUpperCase()
        : null,
    previewURL: exhibition.getThumbnailURL(),
    source: "feralfile-airdrop",
    sourceURL: null,
    thumbnailID: null,
    thumbnailURL: exhibition.getThumbnailURL(),
    galleryThumbnailURL: exhibition.getThumbnailURL(),
    title: exhibition.title,
    ownerAddress: owner,
    owners: {
      owner: 1,
    },
    lastActivityTime: DateTime.now(),
    pending: true,
  );
}

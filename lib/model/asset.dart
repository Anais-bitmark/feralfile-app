class Asset {
  Asset({
    required this.id,
    required this.edition,
    required this.blockchain,
    required this.mintedAt,
    required this.contractType,
    required this.owner,
    required this.projectMetadata,
  });

  String id;
  int edition;
  String blockchain;
  DateTime mintedAt;
  String contractType;
  String owner;
  ProjectMetadata projectMetadata;

  factory Asset.fromJson(Map<String, dynamic> json) => Asset(
        id: json["id"],
        edition: json["edition"],
        blockchain: json["blockchain"],
        mintedAt: DateTime.parse(json["mintedAt"]),
        contractType: json["contractType"],
        owner: json["owner"],
        projectMetadata: ProjectMetadata.fromJson(json["projectMetadata"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "edition": edition,
        "blockchain": blockchain,
        "mintedAt": mintedAt.toIso8601String(),
        "contractType": contractType,
        "owner": owner,
        "projectMetadata": projectMetadata.toJson(),
      };
}

class ProjectMetadata {
  ProjectMetadata({
    required this.origin,
    required this.latest,
  });

  ProjectMetadataData origin;
  ProjectMetadataData latest;

  factory ProjectMetadata.fromJson(Map<String, dynamic> json) =>
      ProjectMetadata(
        origin: ProjectMetadataData.fromJson(json["origin"]),
        latest: ProjectMetadataData.fromJson(json["latest"]),
      );

  Map<String, dynamic> toJson() => {
        "origin": origin.toJson(),
        "latest": latest.toJson(),
      };
}

class ProjectMetadataData {
  ProjectMetadataData({
    required this.artistName,
    required this.artistUrl,
    required this.assetId,
    required this.title,
    required this.description,
    required this.medium,
    required this.maxEdition,
    required this.baseCurrency,
    required this.basePrice,
    required this.source,
    required this.sourceUrl,
    required this.previewUrl,
    required this.thumbnailUrl,
    required this.galleryThumbnailUrl,
    required this.assetData,
    required this.assetUrl,
    required this.artistId,
    required this.originalFileUrl,
    required this.firstMintedAt,
  });

  String? artistName;
  String? artistUrl;
  String? assetId;
  String title;
  String? description;
  String? medium;
  int? maxEdition;
  String? baseCurrency;
  double? basePrice;
  String? source;
  String? sourceUrl;
  String previewUrl;
  String thumbnailUrl;
  String? galleryThumbnailUrl;
  String? assetData;
  String? assetUrl;
  String? artistId;
  String? originalFileUrl;
  DateTime? firstMintedAt;

  factory ProjectMetadataData.fromJson(Map<String, dynamic> json) =>
      ProjectMetadataData(
        artistName: json["artistName"],
        artistUrl: json["artistURL"],
        assetId: json["assetID"],
        title: json["title"],
        description: json["description"],
        medium: json["medium"],
        maxEdition: json["maxEdition"],
        baseCurrency: json["baseCurrency"],
        basePrice: json["basePrice"]?.toDouble(),
        source: json["source"],
        sourceUrl: json["sourceURL"],
        previewUrl: json["previewURL"],
        thumbnailUrl: json["thumbnailURL"],
        galleryThumbnailUrl: json["galleryThumbnailURL"],
        assetData: json["assetData"],
        assetUrl: json["assetURL"],
        artistId: json["artistID"],
        originalFileUrl: json["originalFileURL"],
        firstMintedAt: DateTime.parse(json["firstMintedAt"]),
      );

  Map<String, dynamic> toJson() => {
        "artistName": artistName,
        "artistURL": artistUrl,
        "assetID": assetId,
        "title": title,
        "description": description,
        "medium": medium,
        "maxEdition": maxEdition,
        "baseCurrency": baseCurrency,
        "basePrice": basePrice,
        "source": source,
        "sourceURL": sourceUrl,
        "previewURL": previewUrl,
        "thumbnailURL": thumbnailUrl,
        "galleryThumbnailURL": galleryThumbnailUrl,
        "assetData": assetData,
        "assetURL": assetUrl,
        "artistID": artistId,
        "originalFileURL": originalFileUrl,
        "firstMintedAt": firstMintedAt?.toIso8601String(),
      };
}

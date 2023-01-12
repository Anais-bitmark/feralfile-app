//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/database/entity/announcement_local.dart';
import 'package:floor/floor.dart';

@dao
abstract class AnnouncementLocalDao {
  @Query('SELECT * FROM AnnouncementLocal ORDER BY announceAt DESC')
  Future<List<AnnouncementLocal>> getAnnouncements();

  @Insert(onConflict: OnConflictStrategy.ignore)
  Future<void> insertAnnouncement(AnnouncementLocal announcementLocal);

  @Query(
      'SELECT * FROM AnnouncementLocal WHERE announcementID = :announcementID')
  Future<AnnouncementLocal?> getAnnouncement(String announcementID);

  @Query(
      'UPDATE AnnouncementLocal SET unread = :unread WHERE announcementID = :announcementID')
  Future<void> updateRead(String announcementID, bool unread);

  @Query(
      'SELECT * FROM AnnouncementLocal WHERE category = (:category) AND action = (:action)')
  Future<List<AnnouncementLocal>> getAnnouncementsBy(
      String category, String action);

  @Query('DELETE FROM AnnouncementLocal')
  Future<void> removeAll();
}

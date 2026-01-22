/**
 * ============================================================
 * 資料轉換層 (Mapper Layer)
 * ============================================================
 * @fileoverview 負責將 Google Sheets 的資料結構 (Persistence)
 * 轉換為 App API 的合約格式 (DTO)，以及反向轉換。
 *
 * 欄位順序規範: PK → FK → Required → Optional → Audit
 * 依賴: _config.gs (HEADERS 定義)
 */

const Mapper = {
  // ============================================================
  // Trip Mapper
  // ============================================================
  Trip: {
    /**
     * DB Row → API DTO
     * @param {Object} row - 來自 Trips Sheet 的物件
     * @param {string[]} memberIds - 成員 User ID 列表
     * @returns {Object} DTO
     */
    toDTO: function (row, memberIds = []) {
      if (!row) return null;

      let dayNames = [];
      try {
        if (row.day_names) {
          dayNames = JSON.parse(row.day_names);
        }
      } catch (e) {
        console.warn("Failed to parse day_names for trip " + row.id, e);
      }

      return {
        // PK
        id: row.id,
        // Required
        name: row.name || "",
        start_date: row.start_date || null,
        end_date: row.end_date || null,
        // Optional
        description: row.description || "",
        cover_image: row.cover_image || null,
        is_active: Boolean(row.is_active),
        day_names: dayNames,
        // Computed
        members: memberIds,
        // Audit
        created_at: row.created_at,
        created_by: row.created_by,
        updated_at: row.updated_at,
        updated_by: row.updated_by,
      };
    },

    /**
     * API DTO → DB Row Object
     * @param {Object} dto - 前端傳來的 Trip JSON
     * @param {string} operatorId - 操作者 ID
     * @returns {Object} Persistence Object (key-value)
     */
    toPersistence: function (dto, operatorId) {
      const now = new Date().toISOString();
      return {
        id: dto.id,
        name: dto.name,
        start_date: dto.start_date,
        end_date: dto.end_date,
        description: dto.description || "",
        cover_image: dto.cover_image || "",
        is_active: dto.is_active || false,
        day_names: JSON.stringify(dto.day_names || []),
        created_at: dto.created_at || now,
        created_by: dto.created_by || operatorId,
        updated_at: now,
        updated_by: operatorId,
      };
    },
  },

  // ============================================================
  // Itinerary Mapper
  // ============================================================
  Itinerary: {
    toDTO: function (row) {
      return {
        id: row.id,
        trip_id: row.trip_id,
        day: row.day,
        name: row.name,
        est_time: row.est_time,
        altitude: Number(row.altitude) || 0,
        distance: Number(row.distance) || 0,
        note: row.note || "",
        image_asset: row.image_asset || "",
        is_checked_in: Boolean(row.is_checked_in),
        checked_in_at: row.checked_in_at || null,
        created_at: row.created_at,
        created_by: row.created_by,
        updated_at: row.updated_at,
        updated_by: row.updated_by,
      };
    },

    toPersistence: function (dto, operatorId) {
      const now = new Date().toISOString();
      return {
        id: dto.id,
        trip_id: dto.trip_id,
        day: String(dto.day || ""),
        name: dto.name || "",
        est_time: dto.est_time || "",
        altitude: dto.altitude || 0,
        distance: dto.distance || 0,
        note: dto.note || "",
        image_asset: dto.image_asset || "",
        is_checked_in: dto.is_checked_in || false,
        checked_in_at: dto.checked_in_at || "",
        created_at: dto.created_at || now,
        created_by: dto.created_by || operatorId,
        updated_at: now,
        updated_by: operatorId,
      };
    },
  },

  // ============================================================
  // Message Mapper
  // ============================================================
  Message: {
    toDTO: function (row) {
      return {
        id: row.id,
        trip_id: row.trip_id,
        parent_id: row.parent_id || null,
        user: row.user,
        category: row.category,
        content: row.content,
        timestamp: row.timestamp,
        avatar: row.avatar || DEFAULT_AVATAR,
        created_at: row.created_at,
        created_by: row.created_by,
        updated_at: row.updated_at,
        updated_by: row.updated_by,
      };
    },

    toPersistence: function (dto, operatorId) {
      const now = new Date().toISOString();
      return {
        id: dto.id,
        trip_id: dto.trip_id || "",
        parent_id: dto.parent_id || "",
        user: dto.user || DEFAULT_USER,
        category: dto.category || DEFAULT_CATEGORY,
        content: dto.content || "",
        timestamp: dto.timestamp || now,
        avatar: dto.avatar || DEFAULT_AVATAR,
        created_at: dto.created_at || now,
        created_by: dto.created_by || operatorId,
        updated_at: now,
        updated_by: operatorId,
      };
    },
  },

  // ============================================================
  // GearSet Mapper
  // ============================================================
  GearSet: {
    toDTO: function (row) {
      let items = [];
      let meals = [];
      try {
        if (row.items_json) items = JSON.parse(row.items_json);
        if (row.meals_json) meals = JSON.parse(row.meals_json);
      } catch (e) {
        console.warn("Failed to parse gear json", e);
      }

      return {
        id: row.id,
        trip_id: row.trip_id,
        title: row.title,
        author: row.author,
        visibility: row.visibility,
        key: row.key,
        total_weight: Number(row.total_weight) || 0,
        item_count: Number(row.item_count) || 0,
        items: items,
        meals: meals,
        uploaded_at: row.uploaded_at,
        updated_at: row.updated_at,
        updated_by: row.updated_by,
      };
    },

    /** Summary DTO (不含 items/meals) */
    toSummaryDTO: function (row) {
      return {
        id: row.id,
        trip_id: row.trip_id,
        title: row.title,
        author: row.author,
        visibility: row.visibility,
        total_weight: Number(row.total_weight) || 0,
        item_count: Number(row.item_count) || 0,
        uploaded_at: row.uploaded_at,
      };
    },

    toPersistence: function (dto, operatorId) {
      const now = new Date().toISOString();
      return {
        id: dto.id,
        trip_id: dto.trip_id || "",
        title: dto.title,
        author: dto.author,
        visibility: dto.visibility || "public",
        key: dto.key || "",
        total_weight: dto.total_weight || 0,
        item_count: dto.item_count || 0,
        items_json: JSON.stringify(dto.items || []),
        meals_json: JSON.stringify(dto.meals || []),
        uploaded_at: dto.uploaded_at || now,
        updated_at: now,
        updated_by: operatorId,
      };
    },
  },

  // ============================================================
  // GearLibrary Mapper
  // ============================================================
  GearLibrary: {
    toDTO: function (row) {
      return {
        id: row.id,
        name: row.name,
        weight: Number(row.weight) || 0,
        category: row.category,
        notes: row.notes || "",
        created_at: row.created_at,
        updated_at: row.updated_at,
      };
    },

    toPersistence: function (dto, userId) {
      const now = new Date().toISOString();
      return {
        id: dto.id,
        user_id: userId,
        name: dto.name,
        weight: dto.weight || 0,
        category: dto.category || "Other",
        notes: dto.notes || "",
        created_at: dto.created_at || now,
        created_by: userId,
        updated_at: now,
        updated_by: userId,
      };
    },
  },

  // ============================================================
  // User Mapper
  // ============================================================
  User: {
    toDTO: function (row, roleName) {
      return {
        id: row.id,
        email: row.email,
        display_name: row.display_name,
        avatar: row.avatar,
        role_id: row.role_id,
        role_name: roleName || "",
        is_active: Boolean(row.is_active),
        is_verified: Boolean(row.is_verified),
        created_at: row.created_at,
        last_login_at: row.last_login_at,
      };
    },

    /** 簡化版 DTO (用於成員列表等) */
    toProfileDTO: function (row) {
      return {
        id: row.id,
        email: row.email,
        display_name: row.display_name,
        avatar: row.avatar || DEFAULT_AVATAR,
      };
    },

    toPersistence: function (dto) {
      const now = new Date().toISOString();
      return {
        id: dto.id,
        email: dto.email,
        password_hash: dto.password_hash,
        display_name: dto.display_name,
        avatar: dto.avatar || DEFAULT_AVATAR,
        role_id: dto.role_id,
        is_active: dto.is_active !== false,
        is_verified: dto.is_verified || false,
        verification_code: dto.verification_code || "",
        verification_expiry: dto.verification_expiry || "",
        created_at: dto.created_at || now,
        updated_at: now,
        last_login_at: dto.last_login_at || "",
      };
    },
  },

  // ============================================================
  // Poll Mapper
  // ============================================================
  Poll: {
    /**
     * 組合 Poll DTO (含 Options 及 Votes)
     * @param {Object} pollRow - Polls Sheet 資料
     * @param {Object[]} optionsRows - PollOptions Sheet 資料
     * @param {Object[]} votesRows - PollVotes Sheet 資料
     * @param {string} [currentUserId] - 當前使用者 ID (用於計算 my_votes)
     */
    toDTO: function (pollRow, optionsRows, votesRows, currentUserId) {
      const options = optionsRows
        .filter((o) => o.poll_id === pollRow.id)
        .map((o) => {
          const optionVotes = votesRows.filter((v) => v.option_id === o.id);
          return {
            id: o.id,
            text: o.text,
            creator_id: o.creator_id,
            vote_count: optionVotes.length,
            voters: optionVotes.map((v) => ({
              user_id: v.user_id,
              user_name: v.user_name,
            })),
          };
        });

      const myVotes = currentUserId
        ? votesRows
            .filter(
              (v) => v.poll_id === pollRow.id && v.user_id === currentUserId
            )
            .map((v) => v.option_id)
        : [];

      const totalVotes = votesRows.filter(
        (v) => v.poll_id === pollRow.id
      ).length;

      return {
        id: pollRow.id,
        title: pollRow.title,
        description: pollRow.description || "",
        creator_id: pollRow.creator_id,
        deadline: pollRow.deadline || null,
        is_allow_add_option:
          pollRow.is_allow_add_option === true ||
          pollRow.is_allow_add_option === "TRUE",
        max_option_limit: Number(pollRow.max_option_limit) || 20,
        allow_multiple_votes:
          pollRow.allow_multiple_votes === true ||
          pollRow.allow_multiple_votes === "TRUE",
        result_display_type: pollRow.result_display_type || "realtime",
        status: pollRow.status,
        options: options,
        my_votes: myVotes,
        total_votes: totalVotes,
        created_at: pollRow.created_at,
        created_by: pollRow.created_by,
      };
    },

    toPersistence: function (dto, operatorId) {
      const now = new Date().toISOString();
      return {
        id: dto.id,
        title: dto.title,
        description: dto.description || "",
        creator_id: dto.creator_id || operatorId,
        deadline: dto.deadline || "",
        is_allow_add_option: dto.is_allow_add_option || false,
        max_option_limit: dto.max_option_limit || 20,
        allow_multiple_votes: dto.allow_multiple_votes || false,
        result_display_type: dto.result_display_type || "realtime",
        status: dto.status || "active",
        created_at: dto.created_at || now,
        created_by: dto.created_by || operatorId,
        updated_at: now,
        updated_by: operatorId,
      };
    },
  },

  // ============================================================
  // TripMember Mapper
  // ============================================================
  TripMember: {
    toDTO: function (row, userProfile) {
      return {
        relationship_id: row.id,
        user_id: row.user_id,
        role_code: row.role_code,
        display_name: userProfile ? userProfile.display_name : "Unknown",
        avatar: userProfile ? userProfile.avatar : DEFAULT_AVATAR,
        email: userProfile ? userProfile.email : "",
      };
    },

    toPersistence: function (dto, operatorId) {
      const now = new Date().toISOString();
      return {
        id: dto.id || Utilities.getUuid(),
        trip_id: dto.trip_id,
        user_id: dto.user_id,
        role_code: dto.role_code || "member",
        created_at: dto.created_at || now,
        created_by: dto.created_by || operatorId,
        updated_at: now,
        updated_by: operatorId,
      };
    },
  },

  // ============================================================
  // GroupEvent Mapper
  // ============================================================
  GroupEvent: {
    /**
     * DB Row → API DTO
     * @param {Object} row - 來自 GroupEvents Sheet 的物件
     * @param {Object} extra - { application_count, my_application_status, is_liked }
     * @returns {Object} DTO
     */
    toDTO: function (row, extra = {}) {
      if (!row) return null;

      return {
        // PK
        id: row.id,
        // FK
        creator_id: row.creator_id,
        // Required
        title: row.title || "",
        description: row.description || "",
        location: row.location || "",
        start_date: row.start_date,
        end_date: row.end_date || null,
        max_members: Number(row.max_members) || 10,
        status: row.status || "open",
        // Optional
        approval_required:
          row.approval_required === "TRUE" || row.approval_required === true,
        private_message: row.private_message || "",
        linked_trip_id: row.linked_trip_id || null,
        // 快取/計算
        like_count:
          extra.like_count !== undefined
            ? extra.like_count
            : Number(row.like_count) || 0,
        comment_count:
          extra.comment_count !== undefined
            ? extra.comment_count
            : Number(row.comment_count) || 0,
        // 快照
        creator_name: row.creator_name || "",
        creator_avatar: row.creator_avatar || DEFAULT_AVATAR,
        // Computed (from extra)
        application_count: extra.application_count || 0,
        my_application_status: extra.my_application_status || null,
        is_liked: extra.is_liked || false,
        total_application_count: extra.total_application_count || 0,
        latest_comments: extra.latest_comments || [],
        // Audit
        created_at: row.created_at,
        created_by: row.created_by,
        updated_at: row.updated_at,
        updated_by: row.updated_by,
      };
    },

    /**
     * API Request → DB Row Object
     * @param {Object} dto - 前端傳來的 GroupEvent JSON
     * @param {string} operatorId - 操作者 ID
     * @param {Object} userInfo - { name, avatar } 建立者資訊快照
     * @returns {Object} Persistence Object (key-value)
     */
    toPersistence: function (dto, operatorId, userInfo = {}) {
      const now = new Date().toISOString();
      return {
        id: dto.id || Utilities.getUuid(),
        creator_id: dto.creator_id || operatorId,
        title: dto.title || "",
        description: dto.description || "",
        location: dto.location || "",
        start_date: dto.start_date || "",
        end_date: dto.end_date || "",
        max_members: dto.max_members || 10,
        status: dto.status || "open",
        approval_required: dto.approval_required === true ? "TRUE" : "FALSE",
        private_message: dto.private_message || "",
        linked_trip_id: dto.linked_trip_id || "",
        like_count: 0,
        comment_count: 0,
        creator_name: userInfo.name || "",
        creator_avatar: userInfo.avatar || DEFAULT_AVATAR,
        created_at: dto.created_at || now,
        created_by: dto.created_by || operatorId,
        updated_at: now,
        updated_by: operatorId,
      };
    },
  },

  // ============================================================
  // GroupEventApplication Mapper
  // ============================================================
  GroupEventApplication: {
    /**
     * DB Row → API DTO
     */
    toDTO: function (row) {
      if (!row) return null;

      return {
        // PK
        id: row.id,
        // FK
        event_id: row.event_id,
        user_id: row.user_id,
        // Data
        status: row.status || "pending",
        message: row.message || "",
        // 快照
        user_name: row.user_name || "",
        user_avatar: row.user_avatar || DEFAULT_AVATAR,
        // Audit
        created_at: row.created_at,
        created_by: row.created_by,
        updated_at: row.updated_at,
        updated_by: row.updated_by,
      };
    },

    /**
     * API Request → DB Row Object
     */
    toPersistence: function (dto, operatorId, userInfo = {}) {
      const now = new Date().toISOString();
      return {
        id: dto.id || Utilities.getUuid(),
        event_id: dto.event_id,
        user_id: dto.user_id || operatorId,
        status: dto.status || "pending",
        message: dto.message || "",
        user_name: userInfo.name || "",
        user_avatar: userInfo.avatar || DEFAULT_AVATAR,
        created_at: dto.created_at || now,
        created_by: dto.created_by || operatorId,
        updated_at: now,
        updated_by: operatorId,
      };
    },
  },

  // ============================================================
  // GroupEventComment Mapper
  // ============================================================
  GroupEventComment: {
    /**
     * DB Row → API DTO
     * @param {Object} row - 來自 GroupEventComments Sheet 的物件
     * @returns {Object} DTO
     */
    toDTO: function (row) {
      if (!row) return null;

      return {
        id: row.id,
        event_id: row.event_id,
        user_id: row.user_id,
        content: row.content,
        user_name: row.user_name || "",
        user_avatar: row.user_avatar || DEFAULT_AVATAR,
        created_at: row.created_at,
        created_by: row.created_by,
        updated_at: row.updated_at,
        updated_by: row.updated_by,
      };
    },

    /**
     * API Request → DB Row Object
     * @param {Object} dto - 前端傳來的 Comment JSON (or partial)
     * @param {string} operatorId - 操作者 ID
     * @param {Object} userInfo - { name, avatar }
     * @returns {Object} Persistence Object (key-value)
     */
    toPersistence: function (dto, operatorId, userInfo = {}) {
      const now = new Date().toISOString();
      return {
        id: dto.id || Utilities.getUuid(),
        event_id: dto.event_id,
        user_id: dto.user_id || operatorId,
        content: dto.content,
        user_name: userInfo.name || "",
        user_avatar: userInfo.avatar || DEFAULT_AVATAR,
        created_at: dto.created_at || now,
        created_by: dto.created_by || operatorId,
        updated_at: now,
        updated_by: operatorId,
      };
    },
  },
};

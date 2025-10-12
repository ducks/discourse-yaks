# frozen_string_literal: true

module Jobs
  # Scheduled job to clean up any expired Yak features that were missed.
  #
  # Runs daily as a backup to catch features that weren't cleaned up by the
  # scheduled expiration job (e.g., due to server restarts or job failures).
  #
  # @class CleanupExpiredYakFeatures
  class CleanupExpiredYakFeatures < ::Jobs::Scheduled
    every 1.day

    # Finds and expires any YakFeatureUse records that have passed their
    # expiration time but haven't been processed yet.
    #
    # @param _args [Hash] Unused arguments from job scheduler
    # @returns [void]
    def execute(_args)
      return unless SiteSetting.yaks_enabled

      expired_features = YakFeatureUse
        .expired
        .where(processed_at: nil)
        .includes(:yak_feature, :related_post)

      expired_count = 0
      expired_features.find_each do |feature_use|
        begin
          YakFeatureService.remove_feature_effects(feature_use)
          feature_use.update_column(:processed_at, Time.zone.now)
          expired_count += 1
        rescue => e
          Rails.logger.error "[YakFeatures] Failed to expire feature use #{feature_use.id}: #{e.message}"
        end
      end

      Rails.logger.info "[YakFeatures] Cleanup expired #{expired_count} feature(s)" if expired_count > 0
    end
  end
end

# frozen_string_literal: true

module Jobs
  # Job to expire a single Yak feature at its scheduled expiration time.
  #
  # This job is enqueued with `enqueue_at` when a feature with a duration is
  # purchased, and runs exactly when the feature expires.
  #
  # @class ExpireYakFeature
  class ExpireYakFeature < ::Jobs::Base
    # Expires a single feature use and removes its effects.
    #
    # @param args [Hash] Job arguments
    # @option args [Integer] :feature_use_id The ID of the YakFeatureUse to expire
    # @returns [void]
    def execute(args)
      feature_use_id = args[:feature_use_id]
      return if feature_use_id.blank?

      feature_use = YakFeatureUse.find_by(id: feature_use_id)
      return unless feature_use
      return unless feature_use.expired?
      return if feature_use.processed_at.present?

      begin
        YakFeatureService.remove_feature_effects(feature_use)
        feature_use.update_column(:processed_at, Time.zone.now)
        Rails.logger.info "[YakFeatures] Expired feature use #{feature_use_id}"
      rescue => e
        Rails.logger.error "[YakFeatures] Failed to expire feature use #{feature_use_id}: #{e.message}"
      end
    end
  end
end

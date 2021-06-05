module Fastlane
  module Actions
    class SentryCreateDeployAction < Action
      def self.run(params)
        require 'shellwords'

        Helper::SentryHelper.check_sentry_cli!
        Helper::SentryConfig.parse_api_params(params)

        version = params[:version]
        version = "#{params[:app_identifier]}@#{params[:version]}" if params[:app_identifier]

        has_time = !params[:time].nil?
        has_started = !params[:started].nil?
        has_finished = !params[:finished].nil?

        if !has_time && (has_started && !has_finished || !has_started && has_finished)
          UI.user_error!("Only one parmeter of 'started' and 'finished' found, please provide both.")
        end

        command = [
          "sentry-cli",
          "releases",
          "deploys",
          version,
          "new"
        ]
        command.push('--env').push(params[:env]) unless params[:env].nil?
        command.push('--name').push(params[:name]) unless params[:name].nil?
        command.push('--url').push(params[:deploy_url]) unless params[:deploy_url].nil?
        command.push('--started').push(params[:started]) unless params[:started].nil? || has_time
        command.push('--finished').push(params[:finished]) unless params[:finished].nil? || has_time
        command.push('--time').push(params[:time]) unless params[:time].nil?

        Helper::SentryHelper.call_sentry_cli(command)
        UI.success("Successfully created deploy: #{version}")
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Creates a new release deployment for a project on Sentry"
      end

      def self.details
        [
          "This action allows you to associate deploys to releases for a project on Sentry.",
          "See https://docs.sentry.io/product/cli/releases/#creating-deploys for more information."
        ].join(" ")
      end

      def self.available_options
        Helper::SentryConfig.common_api_config_items + [
          FastlaneCore::ConfigItem.new(key: :version,
                                       description: "Release version to associate the deploy with on Sentry"),
          FastlaneCore::ConfigItem.new(key: :env,
                                       short_option: "-e",
                                       description: "Set the environment for this release. This argument is required. Values that make sense here would be 'production' or 'staging'",
                                       optional: false),
          FastlaneCore::ConfigItem.new(key: :name,
                                       short_option: "-n",
                                       description: "Optional human readable name for this deployment",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :deploy_url,
                                       description: "Optional URL that points to the deployment",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :started,
                                       description: "Optional unix timestamp when the deployment started",
                                       is_string: false,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :finished,
                                       description: "Optional unix timestamp when the deployment finished",
                                       is_string: false,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :time,
                                       short_option: "-t",
                                       description: "Optional deployment duration in seconds. This can be specified alternatively to `started` and `finished`",
                                       is_string: false,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :app_identifier,
                                       short_option: "-a",
                                       env_name: "SENTRY_APP_IDENTIFIER",
                                       description: "App Bundle Identifier, prepended to version",
                                       optional: true)
        ]
      end

      def self.return_value
        nil
      end

      def self.authors
        ["denrase"]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end

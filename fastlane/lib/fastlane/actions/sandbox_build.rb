module Fastlane
  module Actions
    module SharedValues
      SANDBOX_BUILD_UUID = :SANDBOX_BUILD_UUID
    end

    # Copies your project's artifacts into temprorary sandbox folder and runs specified build actions inside
    class SandboxBuildAction < Action
    	attr_accessor :clean
    	attr_accessor :worker_block    	
    	attr_accessor :project_dir    	
    	attr_accessor :build_unique_id
    	    	
      def self.run(params)
      	self.parse_params(params)
				self.initialize_project_dir
				self.create_build_dir_if_needed_and_set_as_working
				self.generate_build_uuid
				self.copy_artifacts_to_build_folder
				self.navigate_to_fastlane
				self.safely_call_worker_block
      end

      def self.description
        [
        	"Copies your project's artifacts into temprorary sandbox folder",
         	"and runs specified build actions inside"
        ].join("\n")
      end

      def self.details
        [
        	"Copies your project's artifacts into temprorary sandbox folder",
         	"and runs specified build actions inside",
         	"Build actions are passed via mandatory `worker_block` parameter",
         	"There's also an optional boolean `clean` parameter which defaults to true",
         	"If `clean` is false, temporary folder is preserved after completion",
         	"This action should not be run when current working directory is changed from",
         	"fastlane's default one"
        ].join("\n")
      end

      def self.output
        [
          ['SANDBOX_BUILD_UUID', 'Unique identifier of build']
        ]
      end

      def self.author
        "soxjke"
      end

      def self.example_code
        [
        	[
        		"sandbox_build(worker_block: {",
        		"  ensure_git_status_clean",
        		"  gym(scheme: \"Debug\", workspace: \"MyApp.xcworkspace\")",
        		"  testflight",        		
        		"})"
        	].join("\n"),
        	[
        		"sandbox_build(",
        		"  clean: false,",
        		"  worker_block: {",
        		"    ensure_git_status_clean",
        		"    gym(scheme: \"Debug\", workspace: \"MyApp.xcworkspace\")",
        		"    testflight",        		
        		"  }",
        		")"
        	].join("\n"),        	
        ]
      end

      def self.category
        :building
      end
      
			def self.step_text
  	    "Sandboxing build"
	    end      
      
      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :clean,
                                       env_name: "FL_SANDBOX_BUILD_CLEAN",
                                       description: "Cleans and removes temporary build folder after execution",
                                       is_string: false,
                                       default_value: true),
          FastlaneCore::ConfigItem.new(key: :worker_block,
                                       env_name: "FL_SANDBOX_BUILD_WORKER_BLOCK",
                                       description: "Block to execute inside temprorary build folder",
                                       is_string: false,
                                       default_value: nil),
        ]      
      end

      def self.is_supported?(platform)
        true
      end
            
# Helper
			BUILD_DIR_NAME = "build"
			EXCLUDE_PATTERNS = [BUILD_DIR_NAME, ".", "..", ".DS_Store"]
			FASTLANE_DIR_NAME = "fastlane"
			
			def self.parse_params(params)
      	@clean = params[:clean].nil? ? true : params[:clean]
      	@worker_block = params[:worker_block]
      	if @worker_block.nil?
      		UI.user_error!("sandbox_build called without worker_block specified")      	
      	end
			end
			
			def self.initialize_project_dir
# 				if Dir.pwd.split('/').last != FASTLANE_DIR_NAME				
#       		UI.user_error!("sandbox_build called from non-default directory")
#       	end				
# 				Dir.chdir("..")
	   		@project_dir = Dir.new(Dir.pwd)			
			end
			
			def self.create_build_dir_if_needed_and_set_as_working
				if not Dir.exist?(BUILD_DIR_NAME)
					Dir.mkdir(BUILD_DIR_NAME)
				end
				Dir.chdir(BUILD_DIR_NAME)
			end

			def self.generate_build_uuid
				@build_unique_id = SecureRandom.uuid
				Actions.lane_context[SharedValues::SANDBOX_BUILD_UUID] = @build_unique_id
			end
			
			def self.copy_artifacts_to_build_folder
				Dir.mkdir(@build_unique_id)
				@project_dir.each {|entry|
					FileUtils.cp_r("#{@project_dir.path}/#{entry}", "#{@build_unique_id}/#{entry}") unless EXCLUDE_PATTERNS.include?(entry)
				}				
			end
			
			def self.navigate_to_fastlane
				Dir.chdir(@build_unique_id)
				Dir.chdir(FASTLANE_DIR_NAME)			
			end
      
      def self.safely_call_worker_block
				begin
					@worker_block.call()
				ensure
					Dir.chdir(@project_dir.path)
					if @clean
						FileUtils.remove_dir("#{BUILD_DIR_NAME}/#{@build_unique_id}")
					end
					Dir.chdir(FASTLANE_DIR_NAME)	
				end      
      end
    end
  end
end

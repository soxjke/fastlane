module Fastlane
  module Helper
    def self.sandbox_build(clean = true, &workerBlock)
      Dir.chdir("..")
   		projectDir = Dir.new(Dir.pwd)
			projectPath = projectDir.path
			if not Dir.exist?("build") then
				Dir.mkdir("build")
			end
			Dir.chdir("build")
			buildUniqueId = SecureRandom.uuid	
			Dir.mkdir(buildUniqueId)
			projectDir.each {|entry|
				FileUtils.cp_r("#{projectPath}/#{entry}", "#{buildUniqueId}/#{entry}") unless ["build", ".", "..", ".DS_Store"].include?(entry)
			}
			Dir.chdir(buildUniqueId)
			Dir.chdir("fastlane")	
	
			begin
				workerBlock.call()
			ensure
				Dir.chdir(projectPath)
				if clean then
					FileUtils.remove_dir("build/#{buildUniqueId}")
				end
				Dir.chdir("fastlane")	
			end
		end
  end
end

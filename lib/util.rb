class Util
    
    # statics
    class << self 
        BUILD_DIR = 'build'

        def find_source_file_for_odt(odt)

            unless (odt.start_with?(BUILD_DIR) && odt.end_with?('odt')) 
                raise "odt filename #{odt} must end with .odt and start with #{BUILD_DIR}" 
            end

            without_build_dir = odt.sub(/^#{BUILD_DIR}/, '')
            without_build_dir
        end
    end

end

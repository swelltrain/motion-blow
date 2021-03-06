unless defined?(Motion::Project::Config)
  raise "motion-blow must be required within a RubyMotion project Rakefile."
end

ENV['MOTION_BLOW_ENV'] = "on"

MB_LIB_DIR = File.dirname(__FILE__)
Motion::Project::App.setup do |app|
  Dir.glob(File.join( MB_LIB_DIR, %w(motion-blow ** *.rb))).each do |file|
    app.files.unshift(file)
  end
end

namespace 'motion' do
  desc 'Dumps screen snapshots for all supported devices'  
  task :blow do
    base_dir   = File.join( App.config.project_dir, %w(spec snapshot) )
    bowel_file = File.join( base_dir, "blow.rb" )
    png_dir    = File.join( base_dir, "pngs" )

    raise "Meow! You need to set up a `snapshot directory in your spec directory" unless File.exists?( base_dir )
    raise "Meow! You must define your script in spec/snapshot/bowels.rb" unless File.exists?( bowel_file )
    raise "Hoy! Unable to find `osascript exec in PATH #{%x[which osascript].inspect}" if %x[which osascript].empty?
    
    FileUtils.rm_r( png_dir ) if File.exists?( png_dir )
    FileUtils.mkdir_p( png_dir )
  
    target = ENV['target'] || App.config.sdk_version

    App.config.device_family.each do |family|  
      retina = ENV['retina'] || family == :ipad ? %w[true] : %w[3.5 4]
      retina.each do |retina|
        dir_name = App.config.device_family_string( family, target, retina )
        
        puts "-"*100
        puts "Generating screens for device: #{dir_name}"
        puts "-"*100
        
        ENV['target']        = target
        ENV['device-family'] = family.to_s
        ENV['retina']        = retina

        %x[rake spec files=#{bowel_file} target=#{target} device_family=#{family} retina=#{retina}]
        snapshots = Dir.glob(File.join(ENV['HOME'], 'Desktop', 'iOS Simulator Screen shot *.png' ) )  
        dump_dir  = File.join( png_dir, dir_name )
        FileUtils.rm_r dump_dir if File.exists?( dump_dir )
        FileUtils.mkdir_p( dump_dir )
        snapshots.each do |snap|
          FileUtils.mv( snap, dump_dir )
        end
      end
    end
  end
end
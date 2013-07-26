require 'buildr/kawa'

define "kawa-android-examples" do

  define 'PlainDemo1' do
    # Run with:
    # CLASSPATH=/home/marius/p/kawa-android/PlainDemo1/target/classes:/usr/local/share/java/kawa.jar java MyMain
    project.version = '1.0'
    compile.options.kawac = ['--main']
  end

  define 'PlainDemo2' do
    # Run with:
    # java -cp target/PlainDemo2-1.0.jar MyMain
    project.version = '1.0'
    compile.options.kawac = ['--main']
    package(:jar).merge('/usr/local/share/java/kawa.jar')
    # Proguard:
    # /opt/android-studio/sdk/tools/proguard/bin/proguard.sh -optimizationpasses 5 -injars target/PlainDemo2-1.0.jar -outjars target/test.jar -libraryjars /usr/lib/jvm/java-7-oracle/jre/lib/rt.jar -dontwarn android.\*\* -keep "class MyMain { *; }" -allowaccessmodification -verbose
    # 421181 after, 2528955 before
  end

  define 'AndroidDemo1' do
    ENV['JAVA_HOME'] ||= `detectjavahome`.chomp # Replace with whatever is the correct path for the JDK
    JAVAHOME =  ENV['JAVA_HOME']
    ENV['KAWA_HOME'] = '/usr/local/share/java'
    SDKPLATFORM = "android-15"
    SDKPATH = "/opt/android-studio/sdk"
    SDKTOOLSPATH = "#{SDKPATH}/build-tools/android-4.2.2"
    ANDROIDJAR = "#{SDKPATH}/platforms/#{SDKPLATFORM}/android.jar"
    STARTACTIVITY = "net.kjeldahl.kawaandroid/.MainActivity"
    TARGETCLASSES = "target/classes"
    BUILD = "build"
    LIBS = "libs"
    project.version = '1.0'
    APKNAME = "AndroidDemo1-#{project.version}"
    compile.options.source = '1.6' # Use Java 1.6 features and bytecode only
    compile.options.target = '1.6'

    resourceFiles = FileList[_("src/main/res/**/*.xml")]

    clean {
      #puts "CLEANING"
      e = 'rm -rf '+_('src/main/gen')+' '+_('build')
      trace(e)
      `#{e}`
    }

    def runcmdlines(cmdlines)
      subname = name.split(':')[1]
      cmdlines.each do |cmd|
        s = "exec: cd #{subname}; #{cmd}"
        trace(s)
        o = `cd #{subname};#{cmd}`
        trace(o)
      end
    end

    subname = name.split(':')[1]

    #puts "MMM "+_("#{BUILD}/resources.ap_")
    #task :androidres => [file(_("#{BUILD}/resources.ap_")) => resourceFiles]  do
    #task :androidres => [file(_("#{BUILD}/resources.ap_"))]  do
    #genresources = file(_("build/classes") => resourceFiles) do |dir|
    file _("#{BUILD}/resources.ap_") do |t|
      mkdir_p _("#{BUILD}/classes")
      mkdir_p _("#{BUILD}/libs")
      runcmdlines(["#{SDKTOOLSPATH}/aapt package -f -M AndroidManifest.xml -A assets -S src/main/res -J #{BUILD}/classes -F #{t} -I #{ANDROIDJAR}"
                   #,"touch #{t}"
                  ])
      #exit();
    end

    #compile.with ANDROIDJAR
    #compile([_("src/main")], _("#{BUILD}/classes")).from genresources.to_s
    #compile([_("src/main")], _("#{BUILD}/classes")).with("#{subname}/#{BUILD}/resources.ap_")
    #compile(_("src/main")).into(_("#{BUILD}/classes")).with("#{BUILD}/resources.ap_")
    compile(_("src/main")).into(_("#{BUILD}/classes")).with(_("#{BUILD}/resources.ap_")).with(ANDROIDJAR)

    #def package_as_sources_spec(spec)
    #  spec.merge({:file => "AA"})
    #end

    
    package(:file => _("#{BUILD}/unoptimized.jar")).merge('/usr/local/share/java/kawa.jar')

    task :androidpkg => [:compile, :package] do
      cmdlines = [
                  "pwd",
                  "ls -lad #{BUILD}",
                  #"mkdir #{BUILD} &> /dev/null; rm -f #{BUILD}/optimized.jar &> /dev/null",
                  #"#{JAVAHOME}/bin/jar cf #{BUILD}/unoptimized.jar -C #{TARGETCLASSES} .",
                  #"#{JAVAHOME}/bin/java -jar #{SDKPATH}/tools/proguard/lib/proguard.jar -include #{SDKPATH}/tools/proguard/proguard-android-optimize.txt -include proguard-local.txt -injars #{BUILD}/unoptimized.jar -injars #{LIBS}/kawa.jar -libraryjars #{ANDROIDJAR} -outjars #{BUILD}/optimized.jar -keep public class net.kjeldahl.pyram.MainActivity",
                  "mv #{BUILD}/unoptimized.jar #{BUILD}/optimized.jar",
                  "rm -rf #{TARGETCLASSES} && mkdir -p #{TARGETCLASSES} && unzip #{BUILD}/optimized.jar -d #{TARGETCLASSES}",
                  "#{SDKTOOLSPATH}/dx --dex --output=#{BUILD}/classes.dex #{TARGETCLASSES}",
                  "cp #{BUILD}/resources.ap_ #{BUILD}/#{APKNAME}.ap_", #; touch #{BUILD}/#{APKNAME}.ap_",
                  "cd #{BUILD}; #{SDKTOOLSPATH}/aapt add #{APKNAME}.ap_ classes.dex",
                  "jarsigner -sigalg MD5withRSA -digestalg SHA1 -keystore my-debug-key.keystore -storepass android -keypass android -signedjar #{BUILD}/#{APKNAME}.apk #{BUILD}/#{APKNAME}.ap_ mydebugkey"
                 ]
      runcmdlines cmdlines
    end

    #task :arun => [:androidpkg] do
    task :arun do
      #Project.local_task('arun') do |name|
      cmdlines = [
                  "adb install -r #{BUILD}/#{APKNAME}.apk",
                  "adb shell am start -n #{STARTACTIVITY}"
                 ]
      runcmdlines cmdlines
    end
  end
end


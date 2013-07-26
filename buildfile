require 'buildr/kawa'

ENV['JAVA_HOME'] ||= `detectjavahome`.chomp # Replace with whatever is the correct path for the JDK
JAVAHOME =  ENV['JAVA_HOME'].chomp
ENV['KAWA_HOME'] ||= '/usr/local/share/java'
KAWAHOME = ENV['KAVA_HOME']
KAWAHOME ||= '/usr/local/share/java'

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
    package(:jar).merge("#{KAWAHOME}/kawa.jar")
    # Proguard:
    # /opt/android-studio/sdk/tools/proguard/bin/proguard.sh -optimizationpasses 5 -injars target/PlainDemo2-1.0.jar -outjars target/test.jar -libraryjars /usr/lib/jvm/java-7-oracle/jre/lib/rt.jar -dontwarn android.\*\* -keep "class MyMain { *; }" -allowaccessmodification -verbose
    # 421181 after, 2528955 before
  end

  define 'AndroidDemo1' do
    SDKPLATFORM = "android-15"
    SDKPATH = "/opt/android-studio/sdk"
    SDKTOOLSPATH = "#{SDKPATH}/build-tools/android-4.2.2"
    ANDROIDJAR = "#{SDKPATH}/platforms/#{SDKPLATFORM}/android.jar"
    STARTACTIVITY = "net.kjeldahl.kawaandroid.MainActivity"
    #STARTCLASS = "net.kjeldahl.kawaandroid.MainActivity"
    BUILD = "build"
    TARGETCLASSES = "#{BUILD}/classes"
    LIBS = "libs"
    APKNAME = "AndroidDemo1"
    $REL = "debug"
    project.version = '1.0'
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
    
    #package(:file => _("#{BUILD}/unoptimized.jar")).merge('/usr/local/share/java/kawa.jar')
    #package(:id => 'unoptimized', :type => :jar).merge('/usr/local/share/java/kawa.jar')
    package(:file => "#{subname}/#{BUILD}/unoptimized.jar").merge('/usr/local/share/java/kawa.jar')

    def apkglines
      [
       #"mkdir #{BUILD} &> /dev/null; rm -f #{BUILD}/optimized.jar &> /dev/null",
       #"#{JAVAHOME}/bin/jar cf #{TARGET}/unoptimized.jar -C #{TARGETCLASSES} .",
       #"#{JAVAHOME}/bin/java -jar #{SDKPATH}/tools/proguard/lib/proguard.jar -include #{SDKPATH}/tools/proguard/proguard-android-optimize.txt -include proguard-local.txt -injars #{BUILD}/unoptimized.jar -injars #{LIBS}/kawa.jar -libraryjars #{ANDROIDJAR} -outjars #{BUILD}/optimized.jar -keep public class net.kjeldahl.pyram.MainActivity",
       "mv #{BUILD}/unoptimized.jar #{BUILD}/optimized.jar",
       "rm -rf #{TARGETCLASSES} && mkdir -p #{TARGETCLASSES} && unzip -q #{BUILD}/optimized.jar -d #{TARGETCLASSES}",
       "#{SDKTOOLSPATH}/dx --dex --output=#{BUILD}/classes.dex #{TARGETCLASSES}",
       "cp #{BUILD}/resources.ap_ #{BUILD}/#{APKNAME}.ap_", #; touch #{BUILD}/#{APKNAME}.ap_",
       "cd #{BUILD}; #{SDKTOOLSPATH}/aapt add #{APKNAME}.ap_ classes.dex",
       "jarsigner -sigalg MD5withRSA -digestalg SHA1 -keystore my-debug-key.keystore -storepass android -keypass android -signedjar #{BUILD}/#{APKNAME}-#{project.version}-#{$REL}.apk #{BUILD}/#{APKNAME}.ap_ mydebugkey"
      ]
    end

    task :pkgdebug => [:compile, :package] do
      runcmdlines apkglines
    end

    task :pkgrelease => [:compile, :package] do
      $REL = "release"
      mylines = apkglines()
      mylines[0] = "#{JAVAHOME}/bin/java -jar #{SDKPATH}/tools/proguard/lib/proguard.jar -include #{SDKPATH}/tools/proguard/proguard-android-optimize.txt -include proguard-local.txt -injars #{BUILD}/unoptimized.jar -libraryjars #{ANDROIDJAR} -outjars #{BUILD}/optimized.jar -keep public class #{STARTACTIVITY} -verbose -optimizationpasses 6"
      runcmdlines mylines
    end

    def arun(mode) 
      start = STARTACTIVITY
      # Reformat net.kjeldahl.kawaandroid.MainActivity to net.kjeldahl.kawaandroid/.MainActivity
      # to keep "am start" happy.
      start = start.gsub(/(.*)(\..*)/, '\1/\2')
      cmdlines = [
                  "adb install -r #{BUILD}/#{APKNAME}-#{project.version}-#{mode}.apk",
                  "adb shell am start -n #{start}"
                 ]
      runcmdlines cmdlines
    end

    #task :arun => [:androidpkg] do
    task :rundebug do
      arun("debug")
    end

    task :runrelease do
      arun("release")
    end

  end
end


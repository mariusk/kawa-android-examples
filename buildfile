require 'buildr/kawa'

ENV['JAVA_HOME'] ||= `detectjavahome`.chomp # Replace with whatever is the correct path for the JDK
JAVAHOME =  ENV['JAVA_HOME'].chomp
ENV['KAWA_HOME'] ||= '/usr/local/share/java'
KAWAHOME = ENV['KAWA_HOME']
KAWA = "#{KAWAHOME}/kawart-1.13.1.jar"

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
    package(:jar).merge(KAWA)
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
    SOURCES = 'src/main'
    BUILD = "build"
    TARGETCLASSES = "#{BUILD}/classes"
    LIBS = "libs"
    APKNAME = "AndroidDemo1"
    $REL = "debug"
    project.version = '1.0'
    compile.options.source = '1.6' # Use Java 1.6 features and bytecode only
    compile.options.target = '1.6'

    clean {
      #puts "CLEANING"
      e = 'rm -rf '+_('#{SOURCES}/gen')+' '+_('build')
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

    file _("#{BUILD}/a") do |t|
    #file _("#{BUILD}/classes") do |t|
      mkdir_p _("#{BUILD}/classes")
      mkdir_p _("#{BUILD}/libs")
      cmdline = "#{SDKTOOLSPATH}/aapt package -f -M AndroidManifest.xml -S #{SOURCES}/res -J #{BUILD}/classes -F #{BUILD}/resources.ap_ -I #{ANDROIDJAR}"
      cmdline += " -S #{SOURCES}/res" if File.directory?("#{SOURCES}/res")
      cmdline += " -A assets" if File.directory?("assets")
      runcmdlines([cmdline, "touch #{t}"])
    end

    #compile(_(SOURCES)).into(_("#{BUILD}/classes")).with(_("#{BUILD}/resources.ap_")).with(ANDROIDJAR)
    compile(_(SOURCES)).into(_("#{BUILD}/classes")).with(_("#{BUILD}/a")).with(ANDROIDJAR)
    
    package(:file => "#{subname}/#{BUILD}/unoptimized.jar").merge(KAWA)

    def apkglines
      [
       "cp #{BUILD}/unoptimized.jar #{BUILD}/optimized.jar",
       "rm -rf #{TARGETCLASSES} && mkdir -p #{TARGETCLASSES} && unzip -q #{BUILD}/optimized.jar -d #{TARGETCLASSES}",
       "#{SDKTOOLSPATH}/dx --dex --output=#{BUILD}/classes.dex #{TARGETCLASSES}",
       "cp #{BUILD}/resources.ap_ #{BUILD}/#{APKNAME}.ap_", #; touch #{BUILD}/#{APKNAME}.ap_",
       #"unzip -l #{BUILD}/#{APKNAME}.ap_ > /tmp/tmp",
       "cd #{BUILD}; #{SDKTOOLSPATH}/aapt add #{APKNAME}.ap_ classes.dex",
       #"cd #{BUILD}; #{SDKTOOLSPATH}/aapt package -F #{APKNAME}.ap_ classes.dex",
       #"cd #{BUILD}; jar cf #{APKNAME}.ap_ classes.dex",
       "jarsigner -sigalg MD5withRSA -digestalg SHA1 -keystore my-debug-key.keystore -storepass android -keypass android -signedjar #{BUILD}/#{APKNAME}-#{project.version}-#{$REL}.apk #{BUILD}/#{APKNAME}.ap_ mydebugkey"
      ]
    end

    task :pkgdebug => [:compile, :package] do
      runcmdlines apkglines
    end

    task :pkgrelease => [:compile, :package] do
      $REL = "release"
      mylines = apkglines()
      mylines.insert(1, "#{JAVAHOME}/bin/java -jar #{SDKPATH}/tools/proguard/lib/proguard.jar -include #{SDKPATH}/tools/proguard/proguard-android-optimize.txt -include proguard-local.txt -injars #{BUILD}/unoptimized.jar -libraryjars #{ANDROIDJAR} -outjars #{BUILD}/optimized.jar -keep public class #{STARTACTIVITY} -verbose -forceprocessing")
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

    task :rundebug do
      arun("debug")
    end

    task :runrelease do
      arun("release")
    end

  end
end


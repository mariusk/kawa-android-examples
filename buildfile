require 'buildr/kawa'

define "kawa-android" do

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

end


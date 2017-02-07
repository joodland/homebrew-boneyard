class Sqsh < Formula
  desc "Sybase Shell"
  homepage "https://sourceforge.net/projects/sqsh/"
  url "https://downloads.sourceforge.net/project/sqsh/sqsh/sqsh-2.5/sqsh-2.5.16.1.tgz"
  sha256 "d6641f365ace60225fc0fa48f82b9dbed77a4e506a0e497eb6889e096b8320f2"

  deprecated_option "enable-x" => "with-x11"

  depends_on :x11 => :optional
  depends_on "freetds"
  depends_on "readline"

  # this patch fixes detection of freetds being installed, it was reported
  # upstream via email and should be fixed in the next release
  patch :DATA

  def install
    args = %W[
      --prefix=#{prefix}
      --mandir=#{man}
      --with-readline
    ]

    readline = Formula["readline"]
    ENV["LIBDIRS"] = readline.opt_lib
    ENV["INCDIRS"] = readline.opt_include

    if build.with? "x11"
      args << "--with-x"
      args << "--x-libraries=#{MacOS::X11.lib}"
      args << "--x-includes=#{MacOS::X11.include}"
    end

    ENV["SYBASE"] = Formula["freetds"].opt_prefix
    system "./configure", *args
    system "make", "install"
    system "make", "install.man"
  end

  test do
    assert_equal "sqsh-#{version}", shell_output("#{bin}/sqsh -v").chomp
  end
end

__END__
diff -Naur sqsh-2.5.orig/configure sqsh-2.5/configure
--- sqsh-2.5.orig/configure	2014-04-14 10:07:04.000000000 +0200
+++ sqsh-2.5/configure	2017-02-07 23:16:15.000000000 +0100
@@ -3937,12 +3937,12 @@
 		# Assume this is a FreeTDS build
 		#
 			SYBASE_VERSION="FreeTDS"
-			if [ "$ac_cv_bit_mode" = "64" -a -f $SYBASE_OCOS/lib64/libct.so ]; then
+			if [ "$ac_cv_bit_mode" = "64" -a -f $SYBASE_OCOS/lib64/libct.a ]; then
 				SYBASE_LIBDIR="$SYBASE_OCOS/lib64"
 			else
 				SYBASE_LIBDIR="$SYBASE_OCOS/lib"
 			fi
-			if [ ! -f $SYBASE_LIBDIR/libct.so ]; then
+			if [ ! -f $SYBASE_LIBDIR/libct.a ]; then
 				{ $as_echo "$as_me:${as_lineno-$LINENO}: result: fail" >&5
 $as_echo "fail" >&6; }
 				as_fn_error $? "No properly installed FreeTDS or Sybase environment found in ${SYBASE_OCOS}." "$LINENO" 5
diff -Naur sqsh-2.5.orig/doc/sqsh.pod sqsh-2.5/doc/sqsh.pod
--- sqsh-2.5.orig/doc/sqsh.pod	2014-03-12 15:19:43.000000000 +0100
+++ sqsh-2.5/doc/sqsh.pod	2017-02-07 23:30:08.000000000 +0100
@@ -145,12 +145,13 @@
 =item -G tds_version

 Set the TDS version to use. Valid versions are 4.0, 4.2, 4.6, 4.9.5, 5.0 and
-freetds additionally supports versions 7.0 and 8.0. The specified value is
-assigned to the variable B<$tds_version>. Input validation is not performed by
-sqsh. However, when an invalid TDS version is specified, the default version of
-5.0 will be used. After a session is setup, the variable B<$tds_version> will be
-set to the TDS version in effect. The variable will not be available if option
--G is not used. Meant for test and debugging purposes only.
+freetds additionally supports versions 7.0, 7.1, 7.2 and 7.3. The specified 
+value is assigned to the variable B<$tds_version>. Input validation is not
+performed by sqsh. However, when an invalid TDS version is specified, the
+default version of 5.0 will be used. After a session is setup, the variable
+B<$tds_version> will be set to the TDS version in effect. The variable will not
+be available if option -G is not used. Meant for test and debugging purposes
+only.

 TDS stands for Tabular Data Stream and is the communication protocol Sybase and
 Microsoft uses for Client-Server communication.
diff -Naur sqsh-2.5.orig/src/cmd_connect.c sqsh-2.5/src/cmd_connect.c
--- sqsh-2.5.orig/src/cmd_connect.c	2014-04-04 10:22:38.000000000 +0200
+++ sqsh-2.5/src/cmd_connect.c	2017-02-07 23:29:46.000000000 +0100
@@ -860,8 +860,12 @@
         /* Then we use freetds which uses enum instead of defines */
         else if (strcmp(tds_version, "7.0") == 0)
             version = CS_TDS_70;
-        else if (strcmp(tds_version, "8.0") == 0)
-            version = CS_TDS_80;
+        else if (strcmp(tds_version, "7.1") == 0)
+            version = CS_TDS_71;
+        else if (strcmp(tds_version, "7.2") == 0)
+            version = CS_TDS_72;
+        else if (strcmp(tds_version, "7.3") == 0)
+            version = CS_TDS_73;
 #endif
         else version = CS_TDS_50; /* default version */

@@ -1258,8 +1262,14 @@
                 case CS_TDS_70:
                     env_set( g_env, "tds_version", "7.0" );
                     break;
-                case CS_TDS_80:
-                    env_set( g_env, "tds_version", "8.0" );
+                case CS_TDS_71:
+                    env_set( g_env, "tds_version", "7.1" );
+                    break;
+                case CS_TDS_72:
+                    env_set( g_env, "tds_version", "7.2" );
+                    break;
+                case CS_TDS_73:
+                    env_set( g_env, "tds_version", "7.3" );
                     break;
 #endif
                 default:

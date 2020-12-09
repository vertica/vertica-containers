# Based on the Devjail Dockerfile

# Base operating system
FROM centos:centos7.5.1804
# https://hub.docker.com/r/sglim2/centos7
# FROM sglim2/centos7

ARG RPM

RUN echo ----------------- rpm is $RPM -----------------------

COPY ./yum.repos.d/docker-ce.repo /etc/yum.repos.d/

# Initial packages to get devtools-7
RUN yum install -y yum-plugin-ovl; yum clean all
RUN yum install -y yum-utils centos-release-scl; yum clean all
RUN yum-config-manager --enable rhel-server-rhscl-7-rpms

# Packages needed to build Vertica UDxes

RUN yum install -y \
        ant \
        binutils \
        compat-libgfortran-41 \
        devtoolset-7-binutils \
        devtoolset-7-binutils-devel \
        devtoolset-7-elfutils \
        devtoolset-7-elfutils-libelf \
        devtoolset-7-elfutils-libs \
        devtoolset-7-gcc \
        devtoolset-7-gcc-c++ \
        devtoolset-7-gcc-gfortran \
        devtoolset-7-gdb \
        devtoolset-7-libasan-devel \
        devtoolset-7-libquadmath-devel \
        devtoolset-7-libstdc++-devel \
        devtoolset-7-oprofile \
        devtoolset-7-runtime \
        devtoolset-7-strace \
        devtoolset-7-valgrind \
        devtoolset-7-valgrind-devel \
        devtoolset-7-libubsan-devel \
        devtoolset-7-libtsan-devel \
        devtoolset-7-liblsan-devel \
        devtoolset-7-libasan-devel \
        doxygen \
        expat \
        flex \
        gettext \
        glibc-devel \
        glibc-headers \
        glibc-static \
        glibc-utils \
        java-1.6.0-openjdk \
        java-1.6.0-openjdk-devel \
        java-1.7.0-openjdk \
        java-1.7.0-openjdk-devel \
        libcurl-devel \
        libgfortran-* \
        libgomp-* \
        libtool \
        libacl-devel \
        make \
        nasm \
        openldap-clients \
        openssl-devel \
        readline-devel \
        redhat-rpm-config \
        rpm-build \
        rpmdevtools \
        sudo \
        tar \
        xmlto \
        && yum clean all \
        && rm -rf /var/cache/yum

COPY $RPM /tmp/$RPM

RUN echo ----------------- rpm is $RPM -----------------------
RUN file /tmp/$RPM
RUN echo ----------------- /tmp/RPM is /tmp/$RPM


# fortunately, this runs in /, so the files get extracted into
# /opt/... where they belong  
RUN rpm2cpio /tmp/$RPM | cpio -idmv \
    ./opt/vertica/bin/VerticaSDK.jar \
    ./opt/vertica/bin/VerticaUDxFence.jar \
    ./opt/vertica/bin/d237f83d0a61c3594829a574c63530b.dat \
    ./opt/vertica/bin/vertica-udx-Java \
    ./opt/vertica/bin/vertica-udx-Java.jar \
    ./opt/vertica/lib/account_malloc.so \
    ./opt/vertica/lib/alloc_monitor.so \
    ./opt/vertica/lib/coarse_alloc_count.so \
    ./opt/vertica/lib/libAutopassCrypto64.so \
    ./opt/vertica/lib/libasan.so.0 \
    ./opt/vertica/lib/libasan.so.1 \
    ./opt/vertica/lib/libasan.so.2 \
    ./opt/vertica/lib/libasan.so.4 \
    ./opt/vertica/lib/libcom_err.so \
    ./opt/vertica/lib/libcom_err.so.3 \
    ./opt/vertica/lib/libcom_err.so.3.0 \
    ./opt/vertica/lib/libcrypto.so \
    ./opt/vertica/lib/libcrypto.so.1.1 \
    ./opt/vertica/lib/libdefaultmalloc.so \
    ./opt/vertica/lib/libdummymalloc.so \
    ./opt/vertica/lib/libgfortran.so.1 \
    ./opt/vertica/lib/libgfortran.so.3 \
    ./opt/vertica/lib/libgfortran.so.4 \
    ./opt/vertica/lib/libgssapi_krb5.so \
    ./opt/vertica/lib/libgssapi_krb5.so.2 \
    ./opt/vertica/lib/libgssapi_krb5.so.2.2 \
    ./opt/vertica/lib/libjemalloc.so \
    ./opt/vertica/lib/libk5crypto.so \
    ./opt/vertica/lib/libk5crypto.so.3 \
    ./opt/vertica/lib/libk5crypto.so.3.1 \
    ./opt/vertica/lib/libkrb5.so \
    ./opt/vertica/lib/libkrb5.so.3 \
    ./opt/vertica/lib/libkrb5.so.3.3 \
    ./opt/vertica/lib/libkrb5support.so \
    ./opt/vertica/lib/libkrb5support.so.0 \
    ./opt/vertica/lib/libkrb5support.so.0.1 \
    ./opt/vertica/lib/liblmx64.so \
    ./opt/vertica/lib/liblsan.so.0 \
    ./opt/vertica/lib/libpgport.a \
    ./opt/vertica/lib/libsane.so.1 \
    ./opt/vertica/lib/libssl.so \
    ./opt/vertica/lib/libssl.so.1.1 \
    ./opt/vertica/lib/libtcmalloc_minimal.so \
    ./opt/vertica/lib/libtsan.so.0 \
    ./opt/vertica/lib/libubsan.so.0 \
    ./opt/vertica/lib/libvmalloc.so \
    ./opt/vertica/lib/mutrace.so \
    ./opt/vertica/lib/pgxs/config/install-sh \
    ./opt/vertica/lib/pgxs/config/mkinstalldirs \
    ./opt/vertica/lib/pgxs/src/Makefile.global \
    ./opt/vertica/lib/pgxs/src/Makefile.port \
    ./opt/vertica/lib/pgxs/src/Makefile.shlib \
    ./opt/vertica/lib/pgxs/src/makefiles/pgxs.mk \
    ./opt/vertica/lib/pgxs/src/nls-global.mk \
    ./opt/vertica/sdk/BuildInfo.java \
    ./opt/vertica/sdk/README.txt \
    ./opt/vertica/sdk/examples \
    ./opt/vertica/sdk/examples/AggregateFunctions \
    ./opt/vertica/sdk/examples/AggregateFunctions.sql \
    ./opt/vertica/sdk/examples/AggregateFunctions/Average.cpp \
    ./opt/vertica/sdk/examples/AggregateFunctions/CountOccurences.cpp \
    ./opt/vertica/sdk/examples/AggregateFunctions/LongestString.cpp \
    ./opt/vertica/sdk/examples/AnalyticFunctions \
    ./opt/vertica/sdk/examples/AnalyticFunctions.sql \
    ./opt/vertica/sdk/examples/AnalyticFunctions/Lag.cpp \
    ./opt/vertica/sdk/examples/AnalyticFunctions/Lead.cpp \
    ./opt/vertica/sdk/examples/AnalyticFunctions/NthValue.cpp \
    ./opt/vertica/sdk/examples/AnalyticFunctions/NthValueUsingParameters.cpp \
    ./opt/vertica/sdk/examples/AnalyticFunctions/Rank.cpp \
    ./opt/vertica/sdk/examples/ApportionLoadFunctions \
    ./opt/vertica/sdk/examples/ApportionLoadFunctions.sql \
    ./opt/vertica/sdk/examples/ApportionLoadFunctions/DelimFilePortionParser.cpp \
    ./opt/vertica/sdk/examples/ApportionLoadFunctions/FilePortionSource.cpp \
    ./opt/vertica/sdk/examples/ApportionLoadFunctions/NativeIntegerParser.cpp \
    ./opt/vertica/sdk/examples/FilterFunctions \
    ./opt/vertica/sdk/examples/FilterFunctions.sql \
    ./opt/vertica/sdk/examples/FilterFunctions/BZip.cpp \
    ./opt/vertica/sdk/examples/FilterFunctions/GZip.cpp \
    ./opt/vertica/sdk/examples/FilterFunctions/Iconverter.cpp \
    ./opt/vertica/sdk/examples/FilterFunctions/SearchAndReplaceFilter.cpp \
    ./opt/vertica/sdk/examples/HelperLibraries \
    ./opt/vertica/sdk/examples/HelperLibraries/ContinuousUDFilter.h \
    ./opt/vertica/sdk/examples/HelperLibraries/ContinuousUDL.h \
    ./opt/vertica/sdk/examples/HelperLibraries/ContinuousUDParser.h \
    ./opt/vertica/sdk/examples/HelperLibraries/ContinuousUDSource.h \
    ./opt/vertica/sdk/examples/HelperLibraries/Coroutine.h \
    ./opt/vertica/sdk/examples/HelperLibraries/CoroutineHelpers.h \
    ./opt/vertica/sdk/examples/HelperLibraries/LoadArgParsers.h \
    ./opt/vertica/sdk/examples/HelperLibraries/StringParsers.h \
    ./opt/vertica/sdk/examples/JavaFunctions.sql \
    ./opt/vertica/sdk/examples/JavaUDAnalytics.sql \
    ./opt/vertica/sdk/examples/JavaUDLFunctions.sql \
    ./opt/vertica/sdk/examples/JavaUDx \
    ./opt/vertica/sdk/examples/JavaUDx/ScalarFunctions \
    ./opt/vertica/sdk/examples/JavaUDx/ScalarFunctions/com \
    ./opt/vertica/sdk/examples/JavaUDx/ScalarFunctions/com/vertica \
    ./opt/vertica/sdk/examples/JavaUDx/ScalarFunctions/com/vertica/JavaLibs \
    ./opt/vertica/sdk/examples/JavaUDx/ScalarFunctions/com/vertica/JavaLibs/Add2intsInfo.java \
    ./opt/vertica/sdk/examples/JavaUDx/ScalarFunctions/com/vertica/JavaLibs/AddAnyIntsInfo.java \
    ./opt/vertica/sdk/examples/JavaUDx/TransformFunctions \
    ./opt/vertica/sdk/examples/JavaUDx/TransformFunctions/com \
    ./opt/vertica/sdk/examples/JavaUDx/TransformFunctions/com/vertica \
    ./opt/vertica/sdk/examples/JavaUDx/TransformFunctions/com/vertica/JavaLibs \
    ./opt/vertica/sdk/examples/JavaUDx/TransformFunctions/com/vertica/JavaLibs/ForwardIndexBuilder.java \
    ./opt/vertica/sdk/examples/JavaUDx/TransformFunctions/com/vertica/JavaLibs/InvertedIndexBuilder.java \
    ./opt/vertica/sdk/examples/JavaUDx/TransformFunctions/com/vertica/JavaLibs/InvertedIndexFactory.java \
    ./opt/vertica/sdk/examples/JavaUDx/TransformFunctions/com/vertica/JavaLibs/PolyTopKFactory.java \
    ./opt/vertica/sdk/examples/JavaUDx/TransformFunctions/com/vertica/JavaLibs/PolyTopKPerPartition.java \
    ./opt/vertica/sdk/examples/JavaUDx/TransformFunctions/com/vertica/JavaLibs/TopKFactory.java \
    ./opt/vertica/sdk/examples/JavaUDx/TransformFunctions/com/vertica/JavaLibs/TopKPerPartitionWithParams.java \
    ./opt/vertica/sdk/examples/JavaUDx/TransformFunctions/com/vertica/JavaLibs/TopKPerPartitionWithParamsFactory.java \
    ./opt/vertica/sdk/examples/JavaUDx/UDAnalytics \
    ./opt/vertica/sdk/examples/JavaUDx/UDAnalytics/com \
    ./opt/vertica/sdk/examples/JavaUDx/UDAnalytics/com/vertica \
    ./opt/vertica/sdk/examples/JavaUDx/UDAnalytics/com/vertica/JavaLibs \
    ./opt/vertica/sdk/examples/JavaUDx/UDAnalytics/com/vertica/JavaLibs/Lag.java \
    ./opt/vertica/sdk/examples/JavaUDx/UDAnalytics/com/vertica/JavaLibs/LagFactory.java \
    ./opt/vertica/sdk/examples/JavaUDx/UDAnalytics/com/vertica/JavaLibs/Lead.java \
    ./opt/vertica/sdk/examples/JavaUDx/UDAnalytics/com/vertica/JavaLibs/LeadFactory.java \
    ./opt/vertica/sdk/examples/JavaUDx/UDAnalytics/com/vertica/JavaLibs/NthValue.java \
    ./opt/vertica/sdk/examples/JavaUDx/UDAnalytics/com/vertica/JavaLibs/NthValueFactory.java \
    ./opt/vertica/sdk/examples/JavaUDx/UDAnalytics/com/vertica/JavaLibs/NthValueUsingParam.java \
    ./opt/vertica/sdk/examples/JavaUDx/UDAnalytics/com/vertica/JavaLibs/NthValueUsingParamFactory.java \
    ./opt/vertica/sdk/examples/JavaUDx/UDAnalytics/com/vertica/JavaLibs/Rank.java \
    ./opt/vertica/sdk/examples/JavaUDx/UDAnalytics/com/vertica/JavaLibs/RankFactory.java \
    ./opt/vertica/sdk/examples/JavaUDx/UDLFunctions \
    ./opt/vertica/sdk/examples/JavaUDx/UDLFunctions/com \
    ./opt/vertica/sdk/examples/JavaUDx/UDLFunctions/com/vertica \
    ./opt/vertica/sdk/examples/JavaUDx/UDLFunctions/com/vertica/JavaLibs \
    ./opt/vertica/sdk/examples/JavaUDx/UDLFunctions/com/vertica/JavaLibs/BasicIntegerParser.java \
    ./opt/vertica/sdk/examples/JavaUDx/UDLFunctions/com/vertica/JavaLibs/BasicIntegerParserFactory.java \
    ./opt/vertica/sdk/examples/JavaUDx/UDLFunctions/com/vertica/JavaLibs/ContinuousIntegerParser.java \
    ./opt/vertica/sdk/examples/JavaUDx/UDLFunctions/com/vertica/JavaLibs/ContinuousIntegerParserFactory.java \
    ./opt/vertica/sdk/examples/JavaUDx/UDLFunctions/com/vertica/JavaLibs/FilePortionSource.java \
    ./opt/vertica/sdk/examples/JavaUDx/UDLFunctions/com/vertica/JavaLibs/FilePortionSourceFactory.java \
    ./opt/vertica/sdk/examples/JavaUDx/UDLFunctions/com/vertica/JavaLibs/FileSource.java \
    ./opt/vertica/sdk/examples/JavaUDx/UDLFunctions/com/vertica/JavaLibs/FileSourceFactory.java \
    ./opt/vertica/sdk/examples/JavaUDx/UDLFunctions/com/vertica/JavaLibs/OneTwoDecoder.java \
    ./opt/vertica/sdk/examples/JavaUDx/UDLFunctions/com/vertica/JavaLibs/OneTwoDecoderFactory.java \
    ./opt/vertica/sdk/examples/LICENSE \
    ./opt/vertica/sdk/examples/ParserFunctions \
    ./opt/vertica/sdk/examples/ParserFunctions.sql \
    ./opt/vertica/sdk/examples/ParserFunctions/BasicIntegerParser.cpp \
    ./opt/vertica/sdk/examples/ParserFunctions/ContinuousIntegerParser.cpp \
    ./opt/vertica/sdk/examples/ParserFunctions/ExampleDelimitedChunker.cpp \
    ./opt/vertica/sdk/examples/ParserFunctions/ExampleDelimitedChunker.h \
    ./opt/vertica/sdk/examples/ParserFunctions/ExampleDelimitedParser.cpp \
    ./opt/vertica/sdk/examples/ParserFunctions/Rfc4180CsvParser.cpp \
    ./opt/vertica/sdk/examples/ParserFunctions/TraditionalCsvParser.cpp \
    ./opt/vertica/sdk/examples/ParserFunctions/libcsv \
    ./opt/vertica/sdk/examples/ParserFunctions/libcsv/libcsv-3.0.1.tar.gz \
    ./opt/vertica/sdk/examples/PythonScalarFunctions.sql \
    ./opt/vertica/sdk/examples/PythonTransformFunctions.sql \
    ./opt/vertica/sdk/examples/README.txt \
    ./opt/vertica/sdk/examples/RFunctions \
    ./opt/vertica/sdk/examples/RFunctions.sql \
    ./opt/vertica/sdk/examples/RFunctions/RFunctions.R \
    ./opt/vertica/sdk/examples/ScalarFunctions \
    ./opt/vertica/sdk/examples/ScalarFunctions.sql \
    ./opt/vertica/sdk/examples/ScalarFunctions/Add2Ints.cpp \
    ./opt/vertica/sdk/examples/ScalarFunctions/AddAnyInts.cpp \
    ./opt/vertica/sdk/examples/ScalarFunctions/DFSWriteRead.cpp \
    ./opt/vertica/sdk/examples/ScalarFunctions/RemoveSpace.cpp \
    ./opt/vertica/sdk/examples/ScalarFunctions/RemoveSymbol.cpp \
    ./opt/vertica/sdk/examples/ScalarFunctions/SessionParameter.cpp \
    ./opt/vertica/sdk/examples/ScalarFunctions/TextConvertUni.cpp \
    ./opt/vertica/sdk/examples/SourceFunctions \
    ./opt/vertica/sdk/examples/SourceFunctions.sql \
    ./opt/vertica/sdk/examples/SourceFunctions/MultiFileCurlSource.cpp \
    ./opt/vertica/sdk/examples/SourceFunctions/NoOpSource.cpp \
    ./opt/vertica/sdk/examples/SourceFunctions/cURL.cpp \
    ./opt/vertica/sdk/examples/SourceFunctions/curl_fopen.cpp \
    ./opt/vertica/sdk/examples/SourceFunctions/curl_fopen.h \
    ./opt/vertica/sdk/examples/SourceFunctions/curl_support \
    ./opt/vertica/sdk/examples/SourceFunctions/curl_support/CoroutineStream.cpp \
    ./opt/vertica/sdk/examples/SourceFunctions/curl_support/CoroutineStream.h \
    ./opt/vertica/sdk/examples/SourceFunctions/curl_support/VDistLib.cpp \
    ./opt/vertica/sdk/examples/SourceFunctions/curl_support/VDistLib.h \
    ./opt/vertica/sdk/examples/SourceFunctions/curl_support/VDistSource.cpp \
    ./opt/vertica/sdk/examples/SourceFunctions/filelib.cpp \
    ./opt/vertica/sdk/examples/TransformFunctions \
    ./opt/vertica/sdk/examples/TransformFunctions.sql \
    ./opt/vertica/sdk/examples/TransformFunctions/ApacheParser.cpp \
    ./opt/vertica/sdk/examples/TransformFunctions/InvertedIndex.cpp \
    ./opt/vertica/sdk/examples/TransformFunctions/PolymorphicTopKPerPartition.cpp \
    ./opt/vertica/sdk/examples/TransformFunctions/StringTokenizer.cpp \
    ./opt/vertica/sdk/examples/TransformFunctions/TopKPerPartition.cpp \
    ./opt/vertica/sdk/examples/TransformFunctions/TopKPerPartitionUsingParams.cpp \
    ./opt/vertica/sdk/examples/data \
    ./opt/vertica/sdk/examples/data/2ints.dat \
    ./opt/vertica/sdk/examples/data/2ints.txt \
    ./opt/vertica/sdk/examples/data/3ints_missing_data.txt \
    ./opt/vertica/sdk/examples/data/3ints_p1.txt \
    ./opt/vertica/sdk/examples/data/3ints_p2.txt \
    ./opt/vertica/sdk/examples/data/3ints_p3.txt \
    ./opt/vertica/sdk/examples/data/apache.txt \
    ./opt/vertica/sdk/examples/data/strings.txt \
    ./opt/vertica/sdk/examples/makefile \
    ./opt/vertica/sdk/examples/python \
    ./opt/vertica/sdk/examples/python/AvgMultiPhaseUDT.py \
    ./opt/vertica/sdk/examples/python/InvertedIndex.py \
    ./opt/vertica/sdk/examples/python/ScalarFunctions.py \
    ./opt/vertica/sdk/examples/python/TransformFunctions.py \
    ./opt/vertica/sdk/include/Arrays/Accessors.h \
    ./opt/vertica/sdk/include/Arrays/Arrays.cpp \
    ./opt/vertica/sdk/include/Arrays/Basics.h \
    ./opt/vertica/sdk/include/Arrays/Parsers.h \
    ./opt/vertica/sdk/include/Arrays/varray.h \
    ./opt/vertica/sdk/include/BasicsSupport.h \
    ./opt/vertica/sdk/include/BasicsUDxShared.h \
    ./opt/vertica/sdk/include/BigInt.cpp \
    ./opt/vertica/sdk/include/BigInt.h \
    ./opt/vertica/sdk/include/BigIntSubs.h \
    ./opt/vertica/sdk/include/BuildAssertions.h \
    ./opt/vertica/sdk/include/BuildInfo.h \
    ./opt/vertica/sdk/include/DateTimeParsing.h \
    ./opt/vertica/sdk/include/EEUDxShared.h \
    ./opt/vertica/sdk/include/IntervalUDx.h \
    ./opt/vertica/sdk/include/Logging.h \
    ./opt/vertica/sdk/include/NumericRoutines.ci \
    ./opt/vertica/sdk/include/NumericRoutinesExt.ci \
    ./opt/vertica/sdk/include/Oids.h \
    ./opt/vertica/sdk/include/PGUDxShared.h \
    ./opt/vertica/sdk/include/ServerFunctions.h \
    ./opt/vertica/sdk/include/TimestampUDxShared.h \
    ./opt/vertica/sdk/include/UdfException.h \
    ./opt/vertica/sdk/include/VArchive.h \
    ./opt/vertica/sdk/include/VAssert.h \
    ./opt/vertica/sdk/include/VValgrind.h \
    ./opt/vertica/sdk/include/Vertica.cpp \
    ./opt/vertica/sdk/include/Vertica.h \
    ./opt/vertica/sdk/include/VerticaDFS.h \
    ./opt/vertica/sdk/include/VerticaErrorCodes.h \
    ./opt/vertica/sdk/include/VerticaModel.h \
    ./opt/vertica/sdk/include/VerticaSymbols.h \
    ./opt/vertica/sdk/include/VerticaUDFS.h \
    ./opt/vertica/sdk/include/VerticaUDFSImpl.h \
    ./opt/vertica/sdk/include/VerticaUDl.h \
    ./opt/vertica/sdk/include/VerticaUDx.h \
    ./opt/vertica/sdk/include/VerticaUDxDebug.h \
    ./opt/vertica/sdk/include/VerticaUDxInternal.h

# Enable devtoolset by default for users
RUN ln -s /opt/rh/devtoolset-7/enable /etc/profile.d/enable-devtools.sh

# Use ld.gold; faster link times
RUN ln -sf /opt/rh/devtoolset-7/root/usr/bin/ld.gold /opt/rh/devtoolset-7/root/etc/alternatives/ld

COPY wrapper /opt/vertica/bin/wrapper

RUN rm -f /tmp/$RPM

ENTRYPOINT [ "/opt/vertica/bin/wrapper" ]

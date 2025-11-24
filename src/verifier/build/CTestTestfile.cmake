# CMake generated Testfile for 
# Source directory: C:/Users/andyj/source/repos/PrecisePointway/master/src/verifier
# Build directory: C:/Users/andyj/source/repos/PrecisePointway/master/src/verifier/build
# 
# This file includes the relevant testing commands required for 
# testing this directory and lists subdirectories to be tested as well.
if(CTEST_CONFIGURATION_TYPE MATCHES "^([Dd][Ee][Bb][Uu][Gg])$")
  add_test(verify_evidence_tests "C:/Users/andyj/source/repos/PrecisePointway/master/src/verifier/build/Debug/verify_evidence_tests.exe")
  set_tests_properties(verify_evidence_tests PROPERTIES  _BACKTRACE_TRIPLES "C:/Users/andyj/source/repos/PrecisePointway/master/src/verifier/CMakeLists.txt;68;add_test;C:/Users/andyj/source/repos/PrecisePointway/master/src/verifier/CMakeLists.txt;0;")
elseif(CTEST_CONFIGURATION_TYPE MATCHES "^([Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
  add_test(verify_evidence_tests "C:/Users/andyj/source/repos/PrecisePointway/master/src/verifier/build/Release/verify_evidence_tests.exe")
  set_tests_properties(verify_evidence_tests PROPERTIES  _BACKTRACE_TRIPLES "C:/Users/andyj/source/repos/PrecisePointway/master/src/verifier/CMakeLists.txt;68;add_test;C:/Users/andyj/source/repos/PrecisePointway/master/src/verifier/CMakeLists.txt;0;")
elseif(CTEST_CONFIGURATION_TYPE MATCHES "^([Mm][Ii][Nn][Ss][Ii][Zz][Ee][Rr][Ee][Ll])$")
  add_test(verify_evidence_tests "C:/Users/andyj/source/repos/PrecisePointway/master/src/verifier/build/MinSizeRel/verify_evidence_tests.exe")
  set_tests_properties(verify_evidence_tests PROPERTIES  _BACKTRACE_TRIPLES "C:/Users/andyj/source/repos/PrecisePointway/master/src/verifier/CMakeLists.txt;68;add_test;C:/Users/andyj/source/repos/PrecisePointway/master/src/verifier/CMakeLists.txt;0;")
elseif(CTEST_CONFIGURATION_TYPE MATCHES "^([Rr][Ee][Ll][Ww][Ii][Tt][Hh][Dd][Ee][Bb][Ii][Nn][Ff][Oo])$")
  add_test(verify_evidence_tests "C:/Users/andyj/source/repos/PrecisePointway/master/src/verifier/build/RelWithDebInfo/verify_evidence_tests.exe")
  set_tests_properties(verify_evidence_tests PROPERTIES  _BACKTRACE_TRIPLES "C:/Users/andyj/source/repos/PrecisePointway/master/src/verifier/CMakeLists.txt;68;add_test;C:/Users/andyj/source/repos/PrecisePointway/master/src/verifier/CMakeLists.txt;0;")
else()
  add_test(verify_evidence_tests NOT_AVAILABLE)
endif()

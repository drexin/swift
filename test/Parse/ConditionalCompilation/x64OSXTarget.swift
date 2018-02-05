// RUN: %swift -typecheck %s -verify -target x86_64-apple-macosx10.9 -parse-stdlib
// RUN: %swift-ide-test -test-input-complete -source-filename=%s -target x86_64-apple-macosx10.9

#if arch(x86_64) && os(OSX) && _runtime(_ObjC) && _endian(little) && _pointer_bit_width(_64)
class C {}
var x = C()
#endif
var y = x


#if arch(x86_64) && os(macOS) && _runtime(_ObjC) && _endian(little) && _pointer_bit_width(_64)
class CC {}
var xx = CC()
#endif
var yy = xx

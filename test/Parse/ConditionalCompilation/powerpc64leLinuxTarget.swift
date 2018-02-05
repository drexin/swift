// RUN: %swift -typecheck %s -verify -target powerpc64le-unknown-linux-gnu -disable-objc-interop -parse-stdlib
// RUN: %swift-ide-test -test-input-complete -source-filename=%s -target powerpc64le-unknown-linux-gnu

#if arch(powerpc64le) && os(Linux) && _runtime(_Native) && _endian(little) && _pointer_bit_width(_64)
class C {}
var x = C()
#endif
var y = x

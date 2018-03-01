#define load_constant(x,y) \
  #if((y >= -0x8000) && (y <= 0x7fff)) \
  li x,y; \
  #else \
  lis x,y@h;\
  ori x,x,y@l;\
  #endif

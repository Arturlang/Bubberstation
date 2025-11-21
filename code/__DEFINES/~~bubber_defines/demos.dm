
#define ADMIN_DEMO(user) "(<a href='?_src_=holder;[HrefToken(forceGlobal = TRUE)];adminopendemo=[REF(user)]'>REPLAY</a>)"

#ifndef DISABLE_DEMOS
#define POST_OVERLAY_CHANGE_DEMOS(changed_on) \
	if(isturf(changed_on)) { \
		SSdemo.marked_turfs?[changed_on] = TRUE; \
	} else if(isobj(changed_on) || ismob(changed_on)) { \
		SSdemo.mark_dirty(changed_on); \
	}
#else
#define POST_OVERLAY_CHANGE_DEMOS(changed_on)
#endif

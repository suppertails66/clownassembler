	move.w	d0,sr
	move.w	#$2700,sr
	move.w	($FFFF8000).w,sr
	move.w	(a0),sr
	move.w	(a0)+,sr
	move.w	-(a0),sr
	move.w	$10(a0),sr
	move.w	(a0,d0.w),sr
	move.w	$10(a0,d0.w),sr
	move	d0,sr
	move	#$2700,sr
	move	($FFFF8000).w,sr
	move	(a0),sr
	move	(a0)+,sr
	move	-(a0),sr
	move	$10(a0),sr
	move	(a0,d0.w),sr
	move	$10(a0,d0.w),sr

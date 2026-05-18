
GLOBAL_VAR_INIT(sound_test_volume, 200)

ADMIN_VERB(test_sound_poison_1, R_NONE, "Test Sound Poison 1", "Test le sound", ADMIN_CATEGORY_GAME)
	playsound(user.mob.loc, 'sound/Unauthorized User Poison 1_take1.ogg', GLOB.sound_test_volume, FALSE)

ADMIN_VERB(test_sound_poison_1_compressed, R_NONE, "Test Sound Poison 1 Compressed", "Test le sound", ADMIN_CATEGORY_GAME)
	playsound(user.mob.loc, 'sound/Unauthorized User Poison 1_take1_compressed.ogg', GLOB.sound_test_volume, FALSE)

// ADMIN_VERB(test_sound_poison_2, R_NONE, "Test Sound Poison 2", "Test le sound", ADMIN_CATEGORY_GAME)
// 	playsound(user.mob.loc, 'sound/Unauthorized User Poison 1_take2.ogg', GLOB.sound_test_volume, FALSE)

// ADMIN_VERB(test_sound_poison_3, R_NONE, "Test Sound Poison 3", "Test le sound", ADMIN_CATEGORY_GAME)
// 	playsound(user.mob.loc, 'sound/Unauthorized User Poison 1_take3.ogg', GLOB.sound_test_volume, FALSE)

// ADMIN_VERB(test_sound_poison_stitched_1, R_NONE, "Test Sound Poison Stitched 1", "Test le sound", ADMIN_CATEGORY_GAME)
// 	playsound(user.mob.loc, 'sound/Unauthorized User Poison 2_take_stitched1.ogg', GLOB.sound_test_volume, FALSE)

// ADMIN_VERB(test_sound_poison_stitched_2, R_NONE, "Test Sound Poison Stitched 2", "Test le sound", ADMIN_CATEGORY_GAME)
// 	playsound(user.mob.loc, 'sound/Unauthorized User Poison 2_take_stitched2.ogg', GLOB.sound_test_volume, FALSE)

// ADMIN_VERB(test_sound_poison_stitched_3, R_NONE, "Test Sound Poison Stitched 3", "Test le sound", ADMIN_CATEGORY_GAME)
// 	playsound(user.mob.loc, 'sound/Unauthorized User Poison 2_take_stitched3.ogg', GLOB.sound_test_volume, FALSE)

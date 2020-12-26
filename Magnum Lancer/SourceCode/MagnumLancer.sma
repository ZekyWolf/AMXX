/*
    ============================
       Main Setting Here
    ============================
*/
            #define ITEM_NAME       "Magnum Lancer"
            #define ITEM_COST       30
            #define ITEM_TEAM       ZP_TEAM_HUMAN

            /* Neccesery for Work this Plugin */
            #define REPAIR_BY_ZEKY

            /* If you want use it for Zombie Plague Mod */
            //#define ZOMBIE_PLAGUE
/*
    ============================
       Main Setting End
    ============================
*/
#if defined REPAIR_BY_ZEKY
    #include <amxmodx>
    #include <amxmisc>
    #include <fakemeta_util>
    #include <engine>
    #include <xs>
    #if defined ZOMBIE_PLAGUE
        #include <zombieplague>
    #endif
    #include <hamsandwich>
#else
    #include <amxmodx>
#endif
 
#define PLUGIN "[ZP] Magnum Lancer"
#define VERSION "2.0"
#define AUTHOR "Bim Bim Cay"
 
// Models
#define v_model         "models/v_sgmissile.mdl"
#define w_model         "models/w_sgmissile.mdl"
#define p_modela        "models/p_sgmissile_a.mdl"
#define p_modelb        "models/p_sgmissile_b.mdl"
 
// Sounds
#define attack1_sound   "weapons/sgmissile-1.wav"
#define attack2_sound   "weapons/sgmissile-2.wav"
#define reload_sound    "weapons/sgmissile_reload.wav"
#define explode_sound   "weapons/sgmissile_exp.wav"
 
// Sprites
#define ef_ball         "sprites/ef_sgmissile_line.spr"
#define ef_explode      "sprites/ef_sgmissile.spr"
#define muzzle_flash1   "sprites/muzzleflash64.spr"
#define muzzle_flash2   "sprites/muzzleflash75.spr"
 
// Anims
#define ANIM_IDLE               0
#define ANIM_RELOAD             1
#define ANIM_DRAW               2
#define ANIM_SHOOT              3
#define ANIM_IDLEB              4
#define ANIM_RELOADB            5
#define ANIM_DRAWB              6
#define ANIM_SHOOTB1            7
#define ANIM_SHOOTB2            8
#define ANIM_SHOOTMISSLE        9
#define ANIM_SHOOTMISSLELAST    10
#define ANIM_MISSLEON           11
 
#define ANIM_EXTENSION          "m249"
 
// Entity Classname
#define BALL_CLASSNAME          "Magnum_EfBall"
#define LINE_CLASSNAME          "Magnum_EfLine"
#define MUZZLEFLASH1_CLASSNAME  "Muzzle_MagnumLancer1"
#define MUZZLEFLASH2_CLASSNAME  "Muzzle_MagnumLancer2"
 
// Configs
#define WEAPON_NAME         "weapon_sgmissile"
#define WEAPON_BASE         "weapon_m3"
 
#define WEAPON_TIME_NEXT_IDLE       10.0
#define WEAPON_TIME_NEXT_ATTACK     0.25
#define WEAPON_TIME_NEXT_ATTACK2    0.4
#define WEAPON_TIME_DELAY_DEPLOY    1.0
#define WEAPON_TIME_DELAY_RELOAD    2.0
#define WEAPON_TIME_DELAY_CHARGE    3.0
 
// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))
 
#define INSTANCE(%0) ((%0 == -1) ? 0 : %0)
#define IsValidPev(%0) (pev_valid(%0) == 2)
#define IsObserver(%0) pev(%0,pev_iuser1)
#define OBS_IN_EYE 4
#define MSGID_WEAPONLIST 78

#define TASK_SHOW_AMMO      10000
 
new g_iszWeaponKey
new g_iForwardDecalIndex
new g_Fire_SprId
 
// Safety
new g_HamBot
new g_IsConnected, g_IsAlive, g_PlayerWeapon[33];

#if defined ZOMBIE_PLAGUE
    new g_iItemID
#endif

#if defined REPAIR_BY_ZEKY
    new bool:iHasMagnum[33];
    static SecondaryAmmo;
    new cvar_damage, Float:WEAPON_SHOOT_DAMAGE;
    new cvar_explode_damage, Float:WEAPON_EXPLODE_DAMAGE;
    new cvar_ammo, WEAPON_MAX_CLIP;
    new cvar_default_ammo, WEAPON_DEFAULT_AMMO;
    new cvar_weapon_explode, Float:WEAPON_EXPLODE_RADIUS;
    new cvar_max_battery, WEAPON_MAX_BATTERY;
#endif

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)
   
    // Safety
    Register_SafetyFunc()
   
    // Forward
    register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
    register_forward(FM_TraceLine, "fw_TraceLine_Post", 1)
    register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")
    register_forward(FM_SetModel, "fw_SetModel")
   
    unregister_forward(FM_DecalIndex, g_iForwardDecalIndex, 1);

    #if defined REPAIR_BY_ZEKY
        // Cvar Register
        cvar_damage             =       register_cvar("MG-Damage", "20.0");
        cvar_explode_damage     =       register_cvar("MG-Explode-Damage", "75.0");
        cvar_ammo               =       register_cvar("MG-Ammo", "30");
        cvar_default_ammo       =       register_cvar("MG-Default-Ammo", "90");
        cvar_weapon_explode     =       register_cvar("MG-Radius-Explode", "50.0");
        cvar_max_battery        =       register_cvar("MG-Max-Battery", "5"); //Max 9

        LoadCvars()
    #endif

    // Think
    register_think(MUZZLEFLASH1_CLASSNAME, "fw_MuzzleFlash1_Think")
    register_think(MUZZLEFLASH2_CLASSNAME, "fw_MuzzleFlash2_Think")
    register_think(BALL_CLASSNAME, "fw_Ball_Think")
    register_think(LINE_CLASSNAME, "fw_Line_Think")
   
    register_touch(BALL_CLASSNAME, "*", "fw_Ball_Touch")
   
    // Ham
    RegisterHam(Ham_Spawn, "weaponbox", "fw_Weaponbox_Spawn_Post", 1)
   
    RegisterHam(Ham_Item_Deploy, WEAPON_BASE, "fw_Item_Deploy_Post", 1)
    RegisterHam(Ham_Item_AddToPlayer, WEAPON_BASE, "fw_Item_AddToPlayer")
    RegisterHam(Ham_Item_PostFrame, WEAPON_BASE, "fw_Item_PostFrame")
    RegisterHam(Ham_Weapon_Reload, WEAPON_BASE, "fw_Weapon_Reload")
    RegisterHam(Ham_Weapon_WeaponIdle, WEAPON_BASE, "fw_Weapon_WeaponIdle")
    RegisterHam(Ham_Weapon_PrimaryAttack, WEAPON_BASE, "fw_Weapon_PrimaryAttack")
   
    RegisterHam(Ham_TraceAttack, "func_breakable", "fw_TraceAttack_Entity")
    RegisterHam(Ham_TraceAttack, "info_target", "fw_TraceAttack_Entity")
    RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack_Entity")
   
    #if defined ZOMBIE_PLAGUE
        g_iItemID = zp_register_extra_item(ITEM_NAME, ITEM_COST, ITEM_TEAM)
    #else
        register_clcmd("say /get", "Get_MyWeapon");
    #endif

    return PLUGIN_CONTINUE;
} 
public plugin_natives()
{
    register_native("zp_get_magnum", "NativeGive", 1);
}
public NativeGive(id){ Get_MyWeapon(id); }

public plugin_precache()
{
    precache_model(v_model)
    precache_model(w_model)
    precache_model(p_modela)
    precache_model(p_modelb)
   
    precache_model(ef_ball)
    precache_model(muzzle_flash1)
    precache_model(muzzle_flash2)
   
    g_Fire_SprId = precache_model(ef_explode)
   
    precache_sound(attack1_sound)
    precache_sound(attack2_sound)
    precache_sound(reload_sound)
    precache_sound(explode_sound)
   
    new TextFile[32]
    formatex(TextFile, charsmax(TextFile), "sprites/%s.txt", WEAPON_NAME)
   
    precache_generic(TextFile)
   
    g_iszWeaponKey = engfunc(EngFunc_AllocString, WEAPON_NAME)
    g_iForwardDecalIndex = register_forward(FM_DecalIndex, "fw_DecalIndex_Post", 1)
   
    register_message(MSGID_WEAPONLIST, "MsgHook_WeaponList")
}
#if defined ZOMBIE_PLAGUE
    public zp_extra_item_selected(id, itemid)
    {
    	if (itemid != g_iItemID)
		    return;

        if(iHasMagnum[id]){
            client_print(id, print_chat, "[ZP] You already have the %s.", ITEM_NAME);
            return;
        }

        Get_MyWeapon(id);
    }
    public zp_user_infected_post(id){ iHasMagnum[id] = false; }
    public zp_user_humanized_post(id){ iHasMagnum[id] = false; }
#endif
#if defined REPAIR_BY_ZEKY
    public LoadCvars()
    {
        WEAPON_MAX_CLIP         =       get_pcvar_num(cvar_ammo);
        WEAPON_DEFAULT_AMMO     =       get_pcvar_num(cvar_default_ammo);
        WEAPON_MAX_BATTERY      =       get_pcvar_num(cvar_max_battery);

        WEAPON_SHOOT_DAMAGE     =       get_pcvar_float(cvar_damage);
        WEAPON_EXPLODE_DAMAGE   =       get_pcvar_float(cvar_explode_damage);
        WEAPON_EXPLODE_RADIUS   =       get_pcvar_float(cvar_weapon_explode);
    }
#endif
public client_putinserver(iPlayer)
{
    Safety_Connected(iPlayer)
   
    if(!g_HamBot && is_user_bot(iPlayer))
    {
        g_HamBot = 1
        set_task(0.1, "Register_HamBot", iPlayer)
    }
    iHasMagnum[iPlayer] = false;
}
 
public Register_HamBot(iPlayer)
{
    Register_SafetyFuncBot(iPlayer)
    RegisterHamFromEntity(Ham_TraceAttack, iPlayer, "fw_TraceAttack_Entity")   
}
 
public client_disconnected(iPlayer)
{
    Safety_Disconnected(iPlayer);
    iHasMagnum[iPlayer] = false;
}
 
public Get_MyWeapon(iPlayer)
{
    Weapon_Give(iPlayer);
}
 
public fw_UpdateClientData_Post(iPlayer, sendweapons, CD_Handle)
{
    enum
    {
        SPEC_MODE,
        SPEC_TARGET,
        SPEC_END
    }
     
    static aSpecInfo[33][SPEC_END]
   
    static iTarget
    static iSpecMode
    static iActiveItem
   
    iTarget = (iSpecMode = IsObserver(iPlayer)) ? pev(iPlayer, pev_iuser2) : iPlayer
   
    if(!is_alive(iTarget))
        return FMRES_IGNORED
   
    iActiveItem = get_pdata_cbase(iTarget, 373, 5)
   
    if(!IsValidPev(iActiveItem) || !IsCustomItem(iActiveItem))
        return FMRES_IGNORED
   
    if(iSpecMode)
    {
        if(aSpecInfo[iPlayer][SPEC_MODE] != iSpecMode)
        {
            aSpecInfo[iPlayer][SPEC_MODE] = iSpecMode
            aSpecInfo[iPlayer][SPEC_TARGET] = 0
        }
       
        if(iSpecMode == OBS_IN_EYE && aSpecInfo[iPlayer][SPEC_TARGET] != iTarget)
        {
            aSpecInfo[iPlayer][SPEC_TARGET] = iTarget
           
            if(get_pdata_int(iActiveItem, 30, 4))
            {
                Weapon_SendAnim(iPlayer, iActiveItem, ANIM_IDLEB)
            }
            else
            {
                Weapon_SendAnim(iPlayer, iActiveItem, ANIM_IDLE)
            }
        }
    }
   
    set_cd(CD_Handle, CD_flNextAttack, get_gametime() + 0.001)
   
    return FMRES_HANDLED
}
 
public fw_TraceLine_Post(Float:TraceStart[3], Float:TraceEnd[3], fNoMonsters, iEntToSkip, iTrace) <FireBullets: Enabled>
{
    static Float:vecEndPos[3]
   
    get_tr2(iTrace, TR_vecEndPos, vecEndPos)
    engfunc(EngFunc_TraceLine, vecEndPos, TraceStart, fNoMonsters, iEntToSkip, 0)
   
    UTIL_GunshotDecalTrace(0)
    UTIL_GunshotDecalTrace(iTrace, true)
}
 
public fw_TraceLine_Post() </* Empty statement */> { /* Fallback */ }
public fw_TraceLine_Post() <FireBullets: Disabled> { /* Do notning */ }
public fw_PlaybackEvent() <FireBullets: Enabled> { return FMRES_SUPERCEDE; }
public fw_PlaybackEvent() </* Empty statement */> { return FMRES_IGNORED; }
public fw_PlaybackEvent() <FireBullets: Disabled> { return FMRES_IGNORED; }
 
/*
    ===============================
        Weaponbox world model. 
    ===============================
*/
public fw_SetModel(iEntity) <WeaponBox: Enabled>
{
    state WeaponBox: Disabled
   
    if(!IsValidPev(iEntity))
        return FMRES_IGNORED
   
    #define MAX_ITEM_TYPES  6
    for(new i, iItem; i < MAX_ITEM_TYPES; i++)
    {
        iItem = get_pdata_cbase(iEntity, 34 + i, 4)
       
        if(IsValidPev(iItem) && IsCustomItem(iItem))
        {
            engfunc(EngFunc_SetModel, iEntity, w_model)
            return FMRES_SUPERCEDE
        }
    }
   
    return FMRES_IGNORED
}
 
public fw_SetModel() </* Empty statement */> { /*  Fallback  */ return FMRES_IGNORED; }
public fw_SetModel() <WeaponBox: Disabled> { /* Do nothing */ return FMRES_IGNORED; }
public fw_Weaponbox_Spawn_Post(iWeaponBox)
{
    if(IsValidPev(iWeaponBox))
    {
        state (IsValidPev(pev(iWeaponBox, pev_owner))) WeaponBox: Enabled
    }
   
    return HAM_IGNORED
}
/*
    ============================
            Weapon's codes.  
    ============================
*/
public fw_Item_Deploy_Post(iItem)
{
    if(!IsCustomItem(iItem))
        return
       
    static iPlayer; iPlayer = get_pdata_cbase(iItem, 41, 4)
    /*static SecondaryAmmo;*/ 
    SecondaryAmmo = get_pdata_int(iItem, 30, 4)
 
    //I need to disable because there is no dummy anim
    //static Sex; Sex = 0 //Get your sex: 0 - Male; 1 - Female
    //set_pev(iItem, pev_body, Sex)
   
    set_pev(iPlayer, pev_viewmodel2, v_model)
   
    if(SecondaryAmmo)
    {
        set_pev(iPlayer, pev_weaponmodel2, p_modelb)
        Weapon_SendAnim(iPlayer, iItem, ANIM_DRAWB)
    }else{
        set_pev(iPlayer, pev_weaponmodel2, p_modela)
        Weapon_SendAnim(iPlayer, iItem, ANIM_DRAW)
    }
 
    Notice(iPlayer)
   
    set_pdata_float(iItem, 48, WEAPON_TIME_DELAY_DEPLOY, 4)
    set_pdata_float(iItem, 38, get_gametime() + WEAPON_TIME_DELAY_CHARGE + WEAPON_TIME_DELAY_DEPLOY, 4)
   
    set_pdata_string(iPlayer, (492) * 4, ANIM_EXTENSION, -1 , 20)
}
 
public fw_Item_PostFrame(iItem)
{
    if(!IsCustomItem(iItem))
        return HAM_IGNORED
   
    static iPlayer; iPlayer = get_pdata_cbase(iItem, 41, 4)
   
    if(get_pdata_int(iItem, 54, 4))
    {
        static iClip; iClip = get_pdata_int(iItem, 51, 4)
        static iPrimaryAmmoIndex; iPrimaryAmmoIndex = PrimaryAmmoIndex(iItem)
        static iAmmoPrimary; iAmmoPrimary = GetAmmoInventory(iPlayer, iPrimaryAmmoIndex)
        static iAmount; iAmount = min(WEAPON_MAX_CLIP - iClip, iAmmoPrimary)
       
        set_pdata_int(iItem, 51, iClip + iAmount, 4)
        SetAmmoInventory(iPlayer, iPrimaryAmmoIndex, iAmmoPrimary - iAmount)
       
        set_pdata_int(iItem, 54, 0, 4)
        set_pdata_float(iItem, 38, get_gametime() + WEAPON_TIME_DELAY_CHARGE, 4)
       
        return HAM_IGNORED
    }  
   
    SecondaryAmmo = get_pdata_int(iItem, 30, 4)
    static Float:flLastEventCheck; flLastEventCheck = get_pdata_float(iItem, 38, 4)
   
    if(flLastEventCheck < get_gametime())
    {
        flLastEventCheck = get_gametime() + WEAPON_TIME_DELAY_CHARGE
        set_pdata_float(iItem, 38, flLastEventCheck, 4)
       
        if(SecondaryAmmo < WEAPON_MAX_BATTERY)
        {
            if(!SecondaryAmmo)
            {
                set_pdata_float(iItem, 48, 1.0, 4)
                Weapon_SendAnim(iPlayer, iItem, ANIM_MISSLEON)
 
                set_pev(iPlayer, pev_weaponmodel2, p_modelb)
            }
           
            SecondaryAmmo++
            set_pdata_int(iItem, 30, SecondaryAmmo, 4)
           
            Notice(iPlayer)
            emit_sound(iPlayer, CHAN_ITEM, reload_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
        }
    }
   
    static iButton; iButton = pev(iPlayer, pev_button)
   
    if(iButton & IN_ATTACK2)
    {
        iButton &= ~IN_ATTACK2
        iButton &= ~IN_ATTACK
        set_pev(iPlayer, pev_button, iButton)
       
        if(!SecondaryAmmo)
            return HAM_IGNORED
           
        if(get_pdata_float(iItem, 47, 4) > 0.0)
            return HAM_IGNORED
           
        set_pdata_float(iItem, 38, get_gametime() + WEAPON_TIME_DELAY_CHARGE, 4)   
       
        set_pdata_float(iItem, 46, WEAPON_TIME_NEXT_ATTACK2, 4)
        set_pdata_float(iItem, 47, WEAPON_TIME_NEXT_ATTACK2, 4)
       
        emit_sound(iPlayer, CHAN_WEAPON, attack2_sound, 1.0, 0.4, 0, 94 + random_num(0, 15))
       
        if(SecondaryAmmo > 1)
        {
            Weapon_SendAnim(iPlayer, iItem, ANIM_SHOOTMISSLE)
            set_pdata_float(iItem, 48, 0.87, 4)
        }else{
            Weapon_SendAnim(iPlayer, iItem, ANIM_SHOOTMISSLELAST)
            set_pdata_float(iItem, 48, 1.2, 4)
           
            set_pev(iPlayer, pev_weaponmodel2, p_modela)
        }
       
        static szAnimation[64]
       
        if(pev(iPlayer, pev_flags) & FL_DUCKING)
        {
            formatex(szAnimation, charsmax(szAnimation), "crouch_shoot_%s", ANIM_EXTENSION)
        }else{
            formatex(szAnimation, charsmax(szAnimation), "ref_shoot_%s", ANIM_EXTENSION)
        }
       
        Player_SetAnimation(iPlayer, szAnimation)
        MakeIcon(iPlayer, SecondaryAmmo, true);
        SecondaryAmmo--
        MakeIcon(iPlayer, SecondaryAmmo, false);
        set_pdata_int(iItem, 30, SecondaryAmmo, 4)
           
        Notice(iPlayer)
       
        Attack2(iPlayer)
        MakeMuzzleFlash2(iPlayer)
    }
   
    return HAM_IGNORED
}
 
public fw_Weapon_Reload(iItem)
{
    if(!IsCustomItem(iItem))
        return HAM_IGNORED
       
    static iPlayer; iPlayer = get_pdata_cbase(iItem, 41, 4)
   
    static iClip; iClip = get_pdata_int(iItem, 51, 4)
    static iPrimaryAmmoIndex; iPrimaryAmmoIndex = PrimaryAmmoIndex(iItem)
    static iAmmoPrimary; iAmmoPrimary = GetAmmoInventory(iPlayer, iPrimaryAmmoIndex)
   
    if(min(WEAPON_MAX_CLIP - iClip, iAmmoPrimary) <= 0)
        return HAM_SUPERCEDE
   
    set_pdata_int(iItem, 51, 0, 4)
   
    ExecuteHam(Ham_Weapon_Reload, iItem)
   
    //Remove shotgun reload
    set_pdata_int(iItem, 55, 0, 4)
    set_pdata_int(iItem, 54, 1, 4)
   
    set_pdata_int(iItem, 51, iClip, 4)
   
    set_pdata_float(iPlayer, 83, WEAPON_TIME_DELAY_RELOAD, 5)
    set_pdata_float(iItem, 48, WEAPON_TIME_DELAY_RELOAD, 4)
   
    static SecondaryAmmo; SecondaryAmmo = get_pdata_int(iItem, 30, 4)
   
    if(SecondaryAmmo)
    {
        Weapon_SendAnim(iPlayer, iItem, ANIM_RELOADB)
    }else{
        Weapon_SendAnim(iPlayer, iItem, ANIM_RELOAD)
    }
   
    return HAM_SUPERCEDE   
}
 
public fw_Weapon_WeaponIdle(iItem)
{
    if(!IsCustomItem(iItem))
        return HAM_IGNORED
       
    static iPlayer; iPlayer = get_pdata_cbase(iItem, 41, 4)
   
    ExecuteHamB(Ham_Weapon_ResetEmptySound, iItem)
 
    if(get_pdata_float(iItem, 48, 4) > 0.0)
        return HAM_SUPERCEDE
   
    set_pdata_float(iItem, 48, WEAPON_TIME_NEXT_IDLE, 4)
   
    static SecondaryAmmo; SecondaryAmmo = get_pdata_int(iItem, 30, 4)
   
    if(SecondaryAmmo)
    {
        Weapon_SendAnim(iPlayer, iItem, ANIM_IDLEB)
    }else{
        Weapon_SendAnim(iPlayer, iItem, ANIM_IDLE)
    }
   
    return HAM_SUPERCEDE
}
 
public fw_Weapon_PrimaryAttack(iItem)
{
    if(!IsCustomItem(iItem))
        return HAM_IGNORED
       
    static iPlayer; iPlayer = get_pdata_cbase(iItem, 41, 4)
    static iClip; iClip = get_pdata_int(iItem, 51, 4)
   
    if(iClip <= 0)
    {
        // No ammo, play empty sound and cancel
        if(get_pdata_int(iItem, 45, 4))
        {
            ExecuteHamB(Ham_Weapon_PlayEmptySound, iItem)
            set_pdata_float(iItem, 46, 0.2, 4)
        }
   
        return HAM_SUPERCEDE
    }
   
    CallOriginalFireBullets(iItem, iPlayer)
   
    static iFlags
    static szAnimation[64], Float:Velocity[3]
 
    iFlags = pev(iPlayer, pev_flags)
   
    if(iFlags & FL_DUCKING)
    {
        formatex(szAnimation, charsmax(szAnimation), "crouch_shoot_%s", ANIM_EXTENSION)
    }else{
        formatex(szAnimation, charsmax(szAnimation), "ref_shoot_%s", ANIM_EXTENSION)
    }
   
    Player_SetAnimation(iPlayer, szAnimation)
   
    static SecondaryAmmo; SecondaryAmmo = get_pdata_int(iItem, 30, 4)
   
    if(SecondaryAmmo)
    {
        Weapon_SendAnim(iPlayer, iItem, random_num(ANIM_SHOOTB1, ANIM_SHOOTB2))
    }else{
        Weapon_SendAnim(iPlayer, iItem, ANIM_SHOOT)
    }
   
    set_pdata_float(iItem, 48, 0.7, 4)
    set_pdata_float(iItem, 46, WEAPON_TIME_NEXT_ATTACK, 4)
    set_pdata_float(iItem, 47, WEAPON_TIME_NEXT_ATTACK, 4)
   
    pev(iPlayer, pev_velocity, Velocity)
   
    if(xs_vec_len(Velocity) > 0){ Weapon_KickBack(iItem, iPlayer, 1.5, 0.45, 0.225, 0.05, 6.5, 2.5, 7); }
    else if(!(iFlags & FL_ONGROUND)){ Weapon_KickBack(iItem, iPlayer, 2.0, 1.0, 0.5, 0.35, 9.0, 6.0, 5); }
    else if(iFlags & FL_DUCKING){ Weapon_KickBack(iItem, iPlayer, 0.9, 0.35, 0.15, 0.025, 5.5, 1.5, 9); }
    else{
        Weapon_KickBack(iItem, iPlayer, 1.0, 0.375, 0.175, 0.0375, 5.75, 1.75, 8);
    }
 
    emit_sound(iPlayer, CHAN_WEAPON, attack1_sound, 1.0, 0.4, 0, 94 + random_num(0, 15))
   
    MakeMuzzleFlash1(iPlayer)
   
    return HAM_SUPERCEDE
}
 
public fw_TraceAttack_Entity(iEntity, iAttacker, Float: flDamage) <FireBullets: Enabled>
{
    SetHamParamFloat(3, WEAPON_SHOOT_DAMAGE)
}
 
public fw_TraceAttack_Entity() </* Empty statement */> { /* Fallback */ }
public fw_TraceAttack_Entity() <FireBullets: Disabled>{ /* Do notning */ }
/*
    ============================
            Weapon list update.     
    ============================
*/
public fw_Item_AddToPlayer(iItem, iPlayer)
{
    if(!IsValidPev(iItem) || !IsValidPev(iPlayer))
        return HAM_IGNORED
   
    MsgHook_WeaponList(MSGID_WEAPONLIST, iItem, iPlayer)
   
    return HAM_IGNORED
}
 
public MsgHook_WeaponList(iMsgID, iMsgDest, iMsgEntity)
{
    static arrWeaponListData[8]
   
    if(!iMsgEntity)
    {
        new szWeaponName[32]
        get_msg_arg_string(1, szWeaponName, charsmax(szWeaponName))
       
        if(!strcmp(szWeaponName, WEAPON_BASE))
        {
            for(new i, a = sizeof arrWeaponListData; i < a; i++)
            {
                arrWeaponListData[i] = get_msg_arg_int(i + 2)
            }
        }
    }else{
        if(!IsCustomItem(iMsgDest) && pev(iMsgDest, pev_impulse))
            return
       
        engfunc(EngFunc_MessageBegin, MSG_ONE, iMsgID, {0.0, 0.0, 0.0}, iMsgEntity)
        write_string(IsCustomItem(iMsgDest) ? WEAPON_NAME : WEAPON_BASE)
       
        for(new i, a = sizeof arrWeaponListData; i < a; i++)
        {
            write_byte(arrWeaponListData[i])
        }
       
        message_end()
    }
}
/*
    ============================
        EFFECTS    
    ============================
*/
public Notice(iPlayer)
{
    if(SecondaryAmmo > 9)
    {
        return PLUGIN_HANDLED;
    }

    MakeIcon(iPlayer, SecondaryAmmo-1, true);
    set_task(0.1, "MakeIconTask", iPlayer);
    return PLUGIN_CONTINUE;
}
public MakeIconTask(iPlayer)
{
    MakeIcon(iPlayer, SecondaryAmmo, false);
    set_task(0.1, "Notice", iPlayer);
}
 
public MakeMuzzleFlash1(iPlayer)
{
    static Ent; Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
    if(!pev_valid(Ent)) return
   
    set_pev(Ent, pev_classname, MUZZLEFLASH1_CLASSNAME)
   
    set_pev(Ent, pev_owner, iPlayer)
    set_pev(Ent, pev_body, 1)
    set_pev(Ent, pev_skin, iPlayer)
    set_pev(Ent, pev_aiment, iPlayer)
    set_pev(Ent, pev_movetype, MOVETYPE_FOLLOW)
   
    set_pev(Ent, pev_scale, 0.085)
    set_pev(Ent, pev_frame, 0.0)
    set_pev(Ent, pev_rendermode, kRenderTransAdd)
    set_pev(Ent, pev_renderamt, 255.0)
   
    engfunc(EngFunc_SetModel, Ent,  muzzle_flash1)
   
    set_pev(Ent, pev_nextthink, get_gametime() + 0.04)
}
 
public fw_MuzzleFlash1_Think(Ent)
{
    if(!pev_valid(Ent))
        return
   
    static Owner; Owner = pev(Ent, pev_owner)
   
    if(!is_alive(Owner))
    {
        set_pev(Ent, pev_flags, FL_KILLME)
        return
    }
   
    static iActiveItem; iActiveItem = get_pdata_cbase(Owner, 373, 5)
   
    if(!IsValidPev(iActiveItem) || !IsCustomItem(iActiveItem))
    {
        set_pev(Ent, pev_flags, FL_KILLME)
        return
    }
 
    static Float:Frame; pev(Ent, pev_frame, Frame)
    if(Frame > 8.0)
    {
        set_pev(Ent, pev_flags, FL_KILLME)
        return
    }else{
        Frame += 1.0
        set_pev(Ent, pev_frame, Frame)
    }
   
    set_pev(Ent, pev_nextthink, get_gametime() + 0.04)
}
 
public MakeMuzzleFlash2(iPlayer)
{
    static Ent
   
    for(new i = 2; i < 5; i++)
    {
        Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
        if(!pev_valid(Ent)) continue
   
        set_pev(Ent, pev_classname, MUZZLEFLASH2_CLASSNAME)
   
        set_pev(Ent, pev_owner, iPlayer)
        set_pev(Ent, pev_body, i)
        set_pev(Ent, pev_skin, iPlayer)
        set_pev(Ent, pev_aiment, iPlayer)
        set_pev(Ent, pev_movetype, MOVETYPE_FOLLOW)
   
        set_pev(Ent, pev_scale, 0.02)
        set_pev(Ent, pev_frame, 0.0)
        set_pev(Ent, pev_rendermode, kRenderTransAdd)
        set_pev(Ent, pev_renderamt, 255.0)
   
        engfunc(EngFunc_SetModel, Ent,  muzzle_flash2)
   
        set_pev(Ent, pev_nextthink, get_gametime() + 0.04)
    }
}
 
public fw_MuzzleFlash2_Think(Ent)
{
    if(!pev_valid(Ent))
        return
   
    static Owner; Owner = pev(Ent, pev_owner)
   
    if(!is_alive(Owner))
    {
        set_pev(Ent, pev_flags, FL_KILLME)
        return
    }
   
    static iActiveItem; iActiveItem = get_pdata_cbase(Owner, 373, 5)
   
    if(!IsValidPev(iActiveItem) || !IsCustomItem(iActiveItem))
    {
        set_pev(Ent, pev_flags, FL_KILLME)
        return
    }
   
    static Float:Frame; pev(Ent, pev_frame, Frame)
    if(Frame > 9.0)
    {
        set_pev(Ent, pev_flags, FL_KILLME)
        return
    }else{
        Frame += 1.0
        set_pev(Ent, pev_frame, Frame)
    }
   
    set_pev(Ent, pev_nextthink, get_gametime() + 0.04)
}
 
public Attack2(iPlayer)
{
    static Float:StartOrigin[3], Float:EndOrigin[9][3]
    Get_WeaponAttachment(iPlayer, StartOrigin, 40.0)
   
    // Left
    Get_Position(iPlayer, 512.0, 50.0, 0.0, EndOrigin[0])
    Get_Position(iPlayer, 512.0, 100.0, 0.0, EndOrigin[1])
    Get_Position(iPlayer, 512.0, 150.0, 0.0, EndOrigin[2])
    Get_Position(iPlayer, 512.0, 200.0, 0.0, EndOrigin[3])
   
    // Center
    Get_Position(iPlayer, 512.0, 0.0, 0.0, EndOrigin[4])
   
    // Right
    Get_Position(iPlayer, 512.0, -50.0, 0.0, EndOrigin[5])
    Get_Position(iPlayer, 512.0, -100.0, 0.0, EndOrigin[6])
    Get_Position(iPlayer, 512.0, -150.0, 0.0, EndOrigin[7])
    Get_Position(iPlayer, 512.0, -200.0, 0.0, EndOrigin[8])
   
    // Create Fire
    for(new i = 0; i < 9; i++) Create_System(iPlayer, StartOrigin, EndOrigin[i])
}
 
public Create_System(iPlayer, Float:StartOrigin[3], Float:EndOrigin[3])
{
    static Ent; Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
   
    if(!pev_valid(Ent))
        return
       
    set_pev(Ent, pev_classname, BALL_CLASSNAME)
    set_pev(Ent, pev_movetype, MOVETYPE_FLYMISSILE)
    set_pev(Ent, pev_solid, SOLID_TRIGGER)
   
    engfunc(EngFunc_SetModel, Ent, ef_ball)
   
    set_pev(Ent, pev_rendermode, kRenderTransAdd)
    set_pev(Ent, pev_renderamt, 150.0)
    set_pev(Ent, pev_scale, 0.3)
    set_pev(Ent, pev_frame, 0.0)
   
    set_pev(Ent, pev_mins, Float:{-5.0, -5.0, -5.0})
    set_pev(Ent, pev_maxs, Float:{5.0, 5.0, 5.0})
   
    set_pev(Ent, pev_origin, StartOrigin)
   
    set_pev(Ent, pev_owner, iPlayer)   
    set_pev(Ent, pev_iuser3, get_user_team(iPlayer))
    set_pev(Ent, pev_fuser4, get_gametime())
   
    // Create Velocity
    static Float:Velocity[3]
    get_speed_vector(StartOrigin, EndOrigin, 1000.0, Velocity)//Or 750, 1500, 2000, 2500
    set_pev(Ent, pev_velocity, Velocity)   
   
    set_pev(Ent, pev_nextthink, get_gametime() + 0.05)
}
 
public fw_Ball_Think(Ent)
{
    if(!pev_valid(Ent))
        return
       
    static Float:Frame
    pev(Ent, pev_frame, Frame)
   
    if(Frame > 14.0)
    {
        static Float:Amount
        pev(Ent, pev_renderamt, Amount)
       
        if(Amount <= 15.0)
        {
            set_pev(Ent, pev_flags, FL_KILLME)
            return
        }
       
        Amount -= 15.0
        set_pev(Ent, pev_renderamt, Amount)
       
        set_pev(Ent, pev_nextthink, get_gametime() + 0.01)
    }else{
        Frame += 1.0
        set_pev(Ent, pev_frame, Frame)
       
        static Float:Origin[3]
        pev(Ent, pev_origin, Origin)
       
        static Float:Scale
        pev(Ent, pev_scale, Scale)
       
        Scale += 0.02
        set_pev(Ent, pev_scale, Scale)
       
        static Float:Time
        pev(Ent, pev_fuser4, Time)
       
        Create_Line(Origin)
        set_pev(Ent, pev_nextthink, get_gametime() + 0.05)
    }
}
 
public fw_Ball_Touch(Ent, Touch)
{
    if(!pev_valid(Ent))
        return
   
    static Classname[36]; pev(Touch, pev_classname, Classname, sizeof(Classname))
   
    if(equali(Classname, BALL_CLASSNAME))
        return
   
    static Float:Origin[3]
    pev(Ent, pev_origin, Origin)
   
    static TE_FLAG
   
    TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
    TE_FLAG |= TE_EXPLFLAG_NOSOUND
    TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
   
    message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
    write_byte(TE_EXPLOSION)
    engfunc(EngFunc_WriteCoord, Origin[0])
    engfunc(EngFunc_WriteCoord, Origin[1])
    engfunc(EngFunc_WriteCoord, Origin[2])
    write_short(g_Fire_SprId)   // sprite index
    write_byte(15)  // scale in 3.4's
    write_byte(15)  // framerate
    write_byte(TE_FLAG) // flags
    message_end()
   
    emit_sound(Ent, CHAN_BODY, explode_sound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
   
    static Team; Team = pev(Ent, pev_iuser3)
    static Owner; Owner = pev(Ent, pev_owner)
   
    static Victim; Victim = -1
    while((Victim = find_ent_in_sphere(Victim, Origin, WEAPON_EXPLODE_RADIUS)) != 0)
    {
        if(is_alive(Victim))
        {
            if(get_user_team(Victim) == Team){ continue; }
        }else{
            if(pev(Victim, pev_takedamage) == DAMAGE_NO){ continue; }
        }
       
        ExecuteHamB(Ham_TakeDamage, Victim, Owner, Owner, WEAPON_EXPLODE_DAMAGE, DMG_BULLET)
    }
   
    set_pev(Ent, pev_flags, FL_KILLME) 
}
 
public Create_Line(Float:Origin[3])
{
    static Ent; Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
   
    if(!pev_valid(Ent))
        return
   
    set_pev(Ent, pev_classname, LINE_CLASSNAME)
    set_pev(Ent, pev_movetype, MOVETYPE_FLYMISSILE)
    set_pev(Ent, pev_solid, SOLID_NOT)
   
    engfunc(EngFunc_SetModel, Ent, ef_ball)
   
    set_pev(Ent, pev_rendermode, kRenderTransAdd)
    set_pev(Ent, pev_renderamt, 120.0)
    set_pev(Ent, pev_scale, 0.3)
    set_pev(Ent, pev_frame, 0.0)
   
    set_pev(Ent, pev_origin, Origin)
   
    set_pev(Ent, pev_nextthink, get_gametime() + 0.05)
}
 
public fw_Line_Think(Ent)
{
    if(!pev_valid(Ent))
        return
       
    static Float:Amount
    pev(Ent, pev_renderamt, Amount)
   
    if(Amount <= 15.0)
    {
        set_pev(Ent, pev_flags, FL_KILLME)
        return
    }
   
    Amount -= 15.0
    set_pev(Ent, pev_renderamt, Amount)
   
    set_pev(Ent, pev_nextthink, get_gametime() + 0.05)
}
/* ===============================
------------- SAFETY -------------
=================================*/
public Register_SafetyFunc()
{
    register_event("CurWeapon", "Safety_CurWeapon", "be", "1=1")
   
    RegisterHam(Ham_Spawn, "player", "fw_Safety_Spawn_Post", 1)
    RegisterHam(Ham_Killed, "player", "fw_Safety_Killed_Post", 1)
}
 
public Register_SafetyFuncBot(iPlayer)
{
    RegisterHamFromEntity(Ham_Spawn, iPlayer, "fw_Safety_Spawn_Post", 1)
    RegisterHamFromEntity(Ham_Killed, iPlayer, "fw_Safety_Killed_Post", 1)
}
 
public Safety_Connected(iPlayer)
{
    Set_BitVar(g_IsConnected, iPlayer)
    UnSet_BitVar(g_IsAlive, iPlayer)
   
    g_PlayerWeapon[iPlayer] = 0
}
 
public Safety_Disconnected(iPlayer)
{
    UnSet_BitVar(g_IsConnected, iPlayer)
    UnSet_BitVar(g_IsAlive, iPlayer)
   
    g_PlayerWeapon[iPlayer] = 0
}
 
public Safety_CurWeapon(iPlayer)
{
    if(!is_alive(iPlayer))
        return
       
    static CSW; CSW = read_data(2)
    if(g_PlayerWeapon[iPlayer] != CSW) g_PlayerWeapon[iPlayer] = CSW
}
 
public fw_Safety_Spawn_Post(iPlayer)
{
    if(!is_user_alive(iPlayer))
        return
       
    Set_BitVar(g_IsAlive, iPlayer)

    if(iHasMagnum[iPlayer]){
        iHasMagnum[iPlayer] = false;
    }
}
 
public fw_Safety_Killed_Post(iPlayer)
{
    UnSet_BitVar(g_IsAlive, iPlayer)
    if(task_exists(TASK_SHOW_AMMO)){
        remove_task(TASK_SHOW_AMMO)
    }
}
 
public is_connected(iPlayer)
{
    if(!(1 <= iPlayer <= 32))
        return 0
    if(!Get_BitVar(g_IsConnected, iPlayer))
        return 0
 
    return 1
}
 
public is_alive(iPlayer)
{
    if(!is_connected(iPlayer))
        return 0
    if(!Get_BitVar(g_IsAlive, iPlayer))
        return 0
       
    return 1
}
 
public get_player_weapon(iPlayer)
{
    if(!is_alive(iPlayer))
        return 0
   
    return g_PlayerWeapon[iPlayer]
}
 
/* ===============================
--------- END OF SAFETY  ---------
=================================*/
IsCustomItem(iItem)
{
    return (pev(iItem, pev_impulse) == g_iszWeaponKey)
}
 
Weapon_Create(Float: Origin[3] = {0.0, 0.0, 0.0}, Float: Angles[3] = {0.0, 0.0, 0.0})
{
    new iWeapon
 
    static iszAllocStringCached
    if (iszAllocStringCached || (iszAllocStringCached = engfunc(EngFunc_AllocString, WEAPON_BASE)))
    {
        iWeapon = engfunc(EngFunc_CreateNamedEntity, iszAllocStringCached)
    }
   
    if(!IsValidPev(iWeapon))
        return FM_NULLENT
   
    dllfunc(DLLFunc_Spawn, iWeapon)
    set_pev(iWeapon, pev_origin, Origin)
 
    set_pdata_int(iWeapon, 51, WEAPON_MAX_CLIP, 4)
    set_pdata_int(iWeapon, 30, 0, 4)
 
    set_pev_string(iWeapon, pev_classname, g_iszWeaponKey)
    set_pev(iWeapon, pev_impulse, g_iszWeaponKey)
    set_pev(iWeapon, pev_angles, Angles)
   
    engfunc(EngFunc_SetModel, iWeapon, w_model)
 
    return iWeapon
}
 
Weapon_Give(iPlayer)
{
    if(!IsValidPev(iPlayer))
    {
        return FM_NULLENT
    }
   
    new iWeapon, Float: vecOrigin[3]
    pev(iPlayer, pev_origin, vecOrigin)
   
    if((iWeapon = Weapon_Create(vecOrigin)) != FM_NULLENT)
    {
        Player_DropWeapons(iPlayer, ExecuteHamB(Ham_Item_ItemSlot, iWeapon))
       
        set_pev(iWeapon, pev_spawnflags, pev(iWeapon, pev_spawnflags) | SF_NORESPAWN)
        dllfunc(DLLFunc_Touch, iWeapon, iPlayer)
       
        SetAmmoInventory(iPlayer, PrimaryAmmoIndex(iWeapon), WEAPON_DEFAULT_AMMO)

        iHasMagnum[iPlayer] = true;
        Notice(iPlayer);
       
        return iWeapon
    }
   
    return FM_NULLENT
}
 
Player_DropWeapons(iPlayer, iSlot)
{
    new szWeaponName[32], iItem = get_pdata_cbase(iPlayer, 367 + iSlot, 5)
 
    while(IsValidPev(iItem))
    {
        pev(iItem, pev_classname, szWeaponName, charsmax(szWeaponName))
        engclient_cmd(iPlayer, "drop", szWeaponName)
 
        iItem = get_pdata_cbase(iItem, 42, 4)
    }
}
/*
    ============================
        Ammo Inventory.
    ============================
*/
PrimaryAmmoIndex(iItem)
{
    return get_pdata_int(iItem, 49, 4)
}
 
GetAmmoInventory(iPlayer, iAmmoIndex)
{
    if(iAmmoIndex == -1)
        return -1
   
    return get_pdata_int(iPlayer, 376 + iAmmoIndex, 5)
}
 
SetAmmoInventory(iPlayer, iAmmoIndex, iAmount)
{
    if(iAmmoIndex == -1)
        return 0
   
    set_pdata_int(iPlayer, 376 + iAmmoIndex, iAmount, 5)
   
    return 1
}
/*
    ============================
       Fire Bullets.
    ============================
*/
CallOriginalFireBullets(iItem, iPlayer)
{
    state FireBullets: Enabled
    static Float:g_Recoil[3]
 
    pev(iPlayer, pev_punchangle, g_Recoil)
    ExecuteHam(Ham_Weapon_PrimaryAttack, iItem)
    set_pev(iPlayer, pev_punchangle, g_Recoil)
   
    state FireBullets: Disabled
}
 
/*
    ============================
       Decals
    ============================
*/
new Array: g_hDecals
 
public fw_DecalIndex_Post()
{
    if(!g_hDecals)
    {
        g_hDecals = ArrayCreate(1, 1)
    }
   
    ArrayPushCell(g_hDecals, get_orig_retval())
}
 
UTIL_GunshotDecalTrace(iTrace, bool: bIsGunshot = false)
{
    static iHit
    static iMessage
    static iDecalIndex
   
    static Float:flFraction
    static Float:vecEndPos[3]
   
    iHit = INSTANCE(get_tr2(iTrace, TR_pHit))
   
    if(iHit && !IsValidPev(iHit) || (pev(iHit, pev_flags) & FL_KILLME))
        return
   
    if(pev(iHit, pev_solid) != SOLID_BSP && pev(iHit, pev_movetype) != MOVETYPE_PUSHSTEP)
        return
   
    iDecalIndex = ExecuteHamB(Ham_DamageDecal, iHit, 0)
   
    if(iDecalIndex < 0 || iDecalIndex >=  ArraySize(g_hDecals))
        return
   
    iDecalIndex = ArrayGetCell(g_hDecals, iDecalIndex)
   
    get_tr2(iTrace, TR_flFraction, flFraction)
    get_tr2(iTrace, TR_vecEndPos, vecEndPos)
   
    if(iDecalIndex < 0 || flFraction >= 1.0)
        return
   
    if(bIsGunshot)
    {
        iMessage = TE_GUNSHOTDECAL
    }else{
        iMessage = TE_DECAL
       
        if(iHit != 0)
        {
            if(iDecalIndex > 255)
            {
                iMessage = TE_DECALHIGH
                iDecalIndex -= 256
            }
        }else{
            iMessage = TE_WORLDDECAL
           
            if(iDecalIndex > 255)
            {
                iMessage = TE_WORLDDECALHIGH
                iDecalIndex -= 256
            }
        }
    }
   
    engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecEndPos, 0)
    write_byte(iMessage)
    engfunc(EngFunc_WriteCoord, vecEndPos[0])
    engfunc(EngFunc_WriteCoord, vecEndPos[1])
    engfunc(EngFunc_WriteCoord, vecEndPos[2])
 
    if(bIsGunshot)
    {
        write_short(iHit)
        write_byte(iDecalIndex)
    }else{
        write_byte(iDecalIndex)
       
        if(iHit)
        {
            write_short(iHit)
        }
    }
   
    message_end()
}
 
/*
    ============================
       Animations
    ============================
*/
stock Weapon_SendAnim(iPlayer, iItem, iAnim)
{
    static i, iCount, iSpectator, aSpectators[32]
   
    set_pev(iPlayer, pev_weaponanim, iAnim)
 
    message_begin(MSG_ONE, SVC_WEAPONANIM, .player = iPlayer)
    write_byte(iAnim)
    write_byte(pev(iItem, pev_body))
    message_end()
   
    if(IsObserver(iPlayer))
        return
   
    get_players(aSpectators, iCount, "bch")
 
    for(i = 0; i < iCount; i++)
    {
        iSpectator = aSpectators[i]
       
        if(IsObserver(iSpectator) != OBS_IN_EYE || pev(iSpectator, pev_iuser2) != iPlayer)
            continue
       
        set_pev(iSpectator, pev_weaponanim, iAnim)
 
        message_begin(MSG_ONE, SVC_WEAPONANIM, .player = iSpectator)
        write_byte(iAnim)
        write_byte(pev(iItem, pev_body))
        message_end()
    }
}
 
stock Player_SetAnimation(iPlayer, szAnim[])
{
    #define ACT_RANGE_ATTACK1   28
   
    // Linux extra offsets
    #define extra_offset_animating   4
    #define extra_offset_player 5
   
    // CBaseAnimating
    #define m_flFrameRate      36
    #define m_flGroundSpeed      37
    #define m_flLastEventCheck   38
    #define m_fSequenceFinished   39
    #define m_fSequenceLoops   40
   
    // CBaseMonster
    #define m_Activity      73
    #define m_IdealActivity      74
   
    // CBasePlayer
    #define m_flLastAttackTime   220
   
    new iAnimDesired, Float:flFrameRate, Float:flGroundSpeed, bool:bLoops
     
    if((iAnimDesired = lookup_sequence(iPlayer, szAnim, flFrameRate, bLoops, flGroundSpeed)) == -1)
    {
        iAnimDesired = 0
    }
   
    static Float:flGametime; flGametime = get_gametime()
 
    set_pev(iPlayer, pev_frame, 0.0)
    set_pev(iPlayer, pev_framerate, 1.0)
    set_pev(iPlayer, pev_animtime, flGametime)
    set_pev(iPlayer, pev_sequence, iAnimDesired)
   
    set_pdata_int(iPlayer, m_fSequenceLoops, bLoops, extra_offset_animating)
    set_pdata_int(iPlayer, m_fSequenceFinished, 0, extra_offset_animating)
   
    set_pdata_float(iPlayer, m_flFrameRate, flFrameRate, extra_offset_animating)
    set_pdata_float(iPlayer, m_flGroundSpeed, flGroundSpeed, extra_offset_animating)
    set_pdata_float(iPlayer, m_flLastEventCheck, flGametime , extra_offset_animating)
   
    set_pdata_int(iPlayer, m_Activity, ACT_RANGE_ATTACK1, extra_offset_player)
    set_pdata_int(iPlayer, m_IdealActivity, ACT_RANGE_ATTACK1, extra_offset_player)  
    set_pdata_float(iPlayer, m_flLastAttackTime, flGametime , extra_offset_player)
}
 
/*
    ============================
       Kick back.
    ============================
*/
Weapon_KickBack(iItem, iPlayer, Float:upBase, Float:lateralBase, Float:upMod, Float:lateralMod, Float:upMax, Float:lateralMax, directionChange)
{
    static iDirection
    static iShotsFired
   
    static Float: Punchangle[3]
    pev(iPlayer, pev_punchangle, Punchangle)
   
    if((iShotsFired = get_pdata_int(iItem, 64, 4)) != 1)
    {
        upBase += iShotsFired * upMod
        lateralBase += iShotsFired * lateralMod
    }
   
    upMax *= -1.0
    Punchangle[0] -= upBase
 
    if(upMax >= Punchangle[0])
    {
        Punchangle[0] = upMax
    }
   
    if((iDirection = get_pdata_int(iItem, 60, 4)))
    {
        Punchangle[1] += lateralBase
       
        if(lateralMax < Punchangle[1])
        {
            Punchangle[1] = lateralMax
        }
    }else{
        lateralMax *= -1.0;
        Punchangle[1] -= lateralBase
       
        if(lateralMax > Punchangle[1])
        {
            Punchangle[1] = lateralMax
        }
    }
   
    if(!random_num(0, directionChange))
    {
        set_pdata_int(iItem, 60, !iDirection, 4)
    }
   
    set_pev(iPlayer, pev_punchangle, Punchangle)
}
 
/*
    ============================
       Some Stocks.
    ============================
*/
stock get_speed_vector(Float:Origin1[3], Float:Origin2[3], Float:Speed, Float:NewVelocity[3])
{
    NewVelocity[0] = Origin2[0] - Origin1[0]
    NewVelocity[1] = Origin2[1] - Origin1[1]
    NewVelocity[2] = Origin2[2] - Origin1[2]
    new Float:num = floatsqroot(Speed*Speed / (NewVelocity[0]*NewVelocity[0] + NewVelocity[1]*NewVelocity[1] + NewVelocity[2]*NewVelocity[2]))
    NewVelocity[0] *= num
    NewVelocity[1] *= num
    NewVelocity[2] *= num
   
    return 1
}
 
stock Get_Position(iPlayer, Float:forw, Float:right, Float:up, Float:vStart[])
{
    new Float:Origin[3], Float:Angles[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
   
    pev(iPlayer, pev_origin, Origin)
    pev(iPlayer, pev_view_ofs,vUp) //for player
    xs_vec_add(Origin, vUp, Origin)
    pev(iPlayer, pev_v_angle, Angles) // if normal entity ,use pev_angles
   
    angle_vector(Angles, ANGLEVECTOR_FORWARD, vForward) //or use EngFunc_AngleVectors
    angle_vector(Angles, ANGLEVECTOR_RIGHT, vRight)
    angle_vector(Angles, ANGLEVECTOR_UP, vUp)
   
    vStart[0] = Origin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
    vStart[1] = Origin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
    vStart[2] = Origin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}
 
stock Get_WeaponAttachment(iPlayer, Float:Output[3], Float:fDis = 40.0)
{
    static Float:vfEnd[3], viEnd[3]
    get_user_origin(iPlayer, viEnd, 3)  
    IVecFVec(viEnd, vfEnd)
   
    static Float:fOrigin[3], Float:fAngle[3]
   
    pev(iPlayer, pev_origin, fOrigin)
    pev(iPlayer, pev_view_ofs, fAngle)
   
    xs_vec_add(fOrigin, fAngle, fOrigin)
   
    static Float:fAttack[3]
   
    xs_vec_sub(vfEnd, fOrigin, fAttack)
    xs_vec_sub(vfEnd, fOrigin, fAttack)
   
    static Float:fRate
   
    fRate = fDis / vector_length(fAttack)
    xs_vec_mul_scalar(fAttack, fRate, fAttack)
   
    xs_vec_add(fOrigin, fAttack, Output)
}
stock MakeIcon(id, ammo, bool:remove)
{
    new num[64];
    formatex(num, 63, "number_%i", ammo);
    if(!(pev(id,pev_button) & FL_ONGROUND) & iHasMagnum[id])
    {    
        message_begin(MSG_ONE, get_user_msgid("StatusIcon"), {0, 0, 0}, id);
        if(remove)
            write_byte(0);
        else
            write_byte(1);
        
        write_string(num);
        write_byte(0);
        write_byte(0);
        write_byte(255);
        message_end();
    }
}  

/**********************************************************************/
/*   ____  ____                                                       */
/*  /   /\/   /                                                       */
/* /___/  \  /                                                        */
/* \   \   \/                                                         */
/*  \   \        Copyright (c) 2003-2013 Xilinx, Inc.                 */
/*  /   /        All Right Reserved.                                  */
/* /---/   /\                                                         */
/* \   \  /  \                                                        */
/*  \___\/\___\                                                       */
/**********************************************************************/


#include "iki.h"
#include <string.h>
#include <math.h>
#ifdef __GNUC__
#include <stdlib.h>
#else
#include <malloc.h>
#define alloca _alloca
#endif
/**********************************************************************/
/*   ____  ____                                                       */
/*  /   /\/   /                                                       */
/* /___/  \  /                                                        */
/* \   \   \/                                                         */
/*  \   \        Copyright (c) 2003-2013 Xilinx, Inc.                 */
/*  /   /        All Right Reserved.                                  */
/* /---/   /\                                                         */
/* \   \  /  \                                                        */
/*  \___\/\___\                                                       */
/**********************************************************************/


#include "iki.h"
#include <string.h>
#include <math.h>
#ifdef __GNUC__
#include <stdlib.h>
#else
#include <malloc.h>
#define alloca _alloca
#endif
typedef void (*funcp)(char *, char *);
extern int main(int, char**);
extern void execute_6(char*, char *);
extern void execute_7(char*, char *);
extern void execute_8(char*, char *);
extern void execute_9(char*, char *);
extern void execute_10(char*, char *);
extern void execute_11(char*, char *);
extern void svlog_sampling_process_execute(char*, char*, char*);
extern void sequence_expr_m_bd6952c9_8e4d9611_2(char*, char *);
extern void sequence_expr_m_bd6952c9_8e4d9611_3(char*, char *);
extern void vlog_sv_sequence_execute_0 (char*, char*, char*);
extern void assertion_action_m_bd6952c9_8e4d9611_1(char*, char *);
extern void sequence_expr_m_bd6952c9_8e4d9611_1(char*, char *);
extern void sequence_expr_m_bd6952c9_8e4d9611_5(char*, char *);
extern void sequence_expr_m_bd6952c9_8e4d9611_6(char*, char *);
extern void sequence_expr_m_bd6952c9_8e4d9611_7(char*, char *);
extern void sequence_expr_m_bd6952c9_8e4d9611_8(char*, char *);
extern void assertion_action_m_bd6952c9_8e4d9611_2(char*, char *);
extern void sequence_expr_m_bd6952c9_8e4d9611_4(char*, char *);
extern void sequence_expr_m_bd6952c9_8e4d9611_10(char*, char *);
extern void sequence_expr_m_bd6952c9_8e4d9611_11(char*, char *);
extern void assertion_action_m_bd6952c9_8e4d9611_3(char*, char *);
extern void sequence_expr_m_bd6952c9_8e4d9611_9(char*, char *);
extern void sequence_expr_m_bd6952c9_8e4d9611_13(char*, char *);
extern void sequence_expr_m_bd6952c9_8e4d9611_14(char*, char *);
extern void assertion_action_m_bd6952c9_8e4d9611_4(char*, char *);
extern void sequence_expr_m_bd6952c9_8e4d9611_12(char*, char *);
extern void sequence_expr_m_bd6952c9_8e4d9611_16(char*, char *);
extern void sequence_expr_m_bd6952c9_8e4d9611_17(char*, char *);
extern void sequence_expr_m_bd6952c9_8e4d9611_18(char*, char *);
extern void assertion_action_m_bd6952c9_8e4d9611_5(char*, char *);
extern void sequence_expr_m_bd6952c9_8e4d9611_15(char*, char *);
extern void execute_46(char*, char *);
extern void execute_47(char*, char *);
extern void execute_48(char*, char *);
extern void execute_49(char*, char *);
extern void execute_3(char*, char *);
extern void execute_4(char*, char *);
extern void execute_5(char*, char *);
extern void execute_16(char*, char *);
extern void execute_17(char*, char *);
extern void vlog_simple_process_execute_0_fast_for_reg(char*, char*, char*);
extern void execute_13(char*, char *);
extern void execute_14(char*, char *);
extern void execute_15(char*, char *);
extern void execute_50(char*, char *);
extern void execute_51(char*, char *);
extern void execute_52(char*, char *);
extern void execute_53(char*, char *);
extern void execute_54(char*, char *);
extern void vlog_transfunc_eventcallback(char*, char*, unsigned, unsigned, unsigned, char *);
funcp funcTab[50] = {(funcp)execute_6, (funcp)execute_7, (funcp)execute_8, (funcp)execute_9, (funcp)execute_10, (funcp)execute_11, (funcp)svlog_sampling_process_execute, (funcp)sequence_expr_m_bd6952c9_8e4d9611_2, (funcp)sequence_expr_m_bd6952c9_8e4d9611_3, (funcp)vlog_sv_sequence_execute_0 , (funcp)assertion_action_m_bd6952c9_8e4d9611_1, (funcp)sequence_expr_m_bd6952c9_8e4d9611_1, (funcp)sequence_expr_m_bd6952c9_8e4d9611_5, (funcp)sequence_expr_m_bd6952c9_8e4d9611_6, (funcp)sequence_expr_m_bd6952c9_8e4d9611_7, (funcp)sequence_expr_m_bd6952c9_8e4d9611_8, (funcp)assertion_action_m_bd6952c9_8e4d9611_2, (funcp)sequence_expr_m_bd6952c9_8e4d9611_4, (funcp)sequence_expr_m_bd6952c9_8e4d9611_10, (funcp)sequence_expr_m_bd6952c9_8e4d9611_11, (funcp)assertion_action_m_bd6952c9_8e4d9611_3, (funcp)sequence_expr_m_bd6952c9_8e4d9611_9, (funcp)sequence_expr_m_bd6952c9_8e4d9611_13, (funcp)sequence_expr_m_bd6952c9_8e4d9611_14, (funcp)assertion_action_m_bd6952c9_8e4d9611_4, (funcp)sequence_expr_m_bd6952c9_8e4d9611_12, (funcp)sequence_expr_m_bd6952c9_8e4d9611_16, (funcp)sequence_expr_m_bd6952c9_8e4d9611_17, (funcp)sequence_expr_m_bd6952c9_8e4d9611_18, (funcp)assertion_action_m_bd6952c9_8e4d9611_5, (funcp)sequence_expr_m_bd6952c9_8e4d9611_15, (funcp)execute_46, (funcp)execute_47, (funcp)execute_48, (funcp)execute_49, (funcp)execute_3, (funcp)execute_4, (funcp)execute_5, (funcp)execute_16, (funcp)execute_17, (funcp)vlog_simple_process_execute_0_fast_for_reg, (funcp)execute_13, (funcp)execute_14, (funcp)execute_15, (funcp)execute_50, (funcp)execute_51, (funcp)execute_52, (funcp)execute_53, (funcp)execute_54, (funcp)vlog_transfunc_eventcallback};
const int NumRelocateId= 50;

void relocate(char *dp)
{
	iki_relocate(dp, "xsim.dir/tb_aer_pixel_behav/xsim.reloc",  (void **)funcTab, 50);

	/*Populate the transaction function pointer field in the whole net structure */
}

void sensitize(char *dp)
{
	iki_sensitize(dp, "xsim.dir/tb_aer_pixel_behav/xsim.reloc");
}

void simulate(char *dp)
{
		iki_schedule_processes_at_time_zero(dp, "xsim.dir/tb_aer_pixel_behav/xsim.reloc");
	// Initialize Verilog nets in mixed simulation, for the cases when the value at time 0 should be propagated from the mixed language Vhdl net
	iki_execute_processes();

	// Schedule resolution functions for the multiply driven Verilog nets that have strength
	// Schedule transaction functions for the singly driven Verilog nets that have strength

}
#include "iki_bridge.h"
void relocate(char *);

void sensitize(char *);

void simulate(char *);

extern SYSTEMCLIB_IMP_DLLSPEC void local_register_implicit_channel(int, char*);
extern void implicit_HDL_SCinstatiate();

extern SYSTEMCLIB_IMP_DLLSPEC int xsim_argc_copy ;
extern SYSTEMCLIB_IMP_DLLSPEC char** xsim_argv_copy ;

int main(int argc, char **argv)
{
    iki_heap_initialize("ms", "isimmm", 0, 2147483648) ;
    iki_set_sv_type_file_path_name("xsim.dir/tb_aer_pixel_behav/xsim.svtype");
    iki_set_crvs_dump_file_path_name("xsim.dir/tb_aer_pixel_behav/xsim.crvsdump");
    void* design_handle = iki_create_design("xsim.dir/tb_aer_pixel_behav/xsim.mem", (void *)relocate, (void *)sensitize, (void *)simulate, 0, isimBridge_getWdbWriter(), 0, argc, argv);
     iki_set_rc_trial_count(100);
    (void) design_handle;
    return iki_simulate_design();
}

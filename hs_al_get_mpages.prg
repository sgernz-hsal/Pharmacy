DROP PROGRAM hs_al_get_mpages:dba GO
CREATE PROGRAM hs_al_get_mpages:dba

;declare RS for interacting with requests

record AVPrequest (
  1 application_number = i4   
  1 position_cd = f8   
  1 prsnl_id = f8   
  1 www_flag = i2   
  1 preftool_ind = i2   
  1 top_view_list_cnt = i4   
  1 top_view_list [*]   
    2 frame_type = c20  
) 

 RECORD AVPreply (
   1 app
     2 application_number = i4
     2 position_cd = f8
     2 prsnl_id = f8
     2 nv_cnt = i4
     2 nv [* ]
       3 name_value_prefs_id = f8
       3 nv_type_flag = i2
       3 pvc_name = c32
       3 pvc_value = vc
       3 sequence = i2
       3 merge_id = f8
       3 merge_name = vc
       3 updt_cnt = i4
   1 view_level_flag = i2
   1 view_cnt = i4
   1 pview [* ]
     2 view_prefs_id = f8
     2 application_number = i4
     2 position_cd = f8
     2 prsnl_id = f8
     2 frame_type = c12
     2 view_name = c12
     2 view_seq = i4
     2 updt_cnt = i4
     2 nv_cnt = i4
     2 nv [* ]
       3 name_value_prefs_id = f8
       3 nv_type_flag = i2
       3 pvc_name = c32
       3 pvc_value = vc
       3 sequence = i2
       3 merge_id = f8
       3 merge_name = vc
       3 updt_cnt = i4
   1 status_data
     2 status = c1
     2 subeventstatus [1 ]
       3 operationname = c25
       3 operationstatus = c1
       3 targetobjectname = c25
       3 targetobjectvalue = vc
 )
 
 record DPrequest (
  1 application_number = i4   
  1 position_cd = f8   
  1 prsnl_id = f8   
  1 person_id = f8   
  1 view_name = vc  
  1 view_seq = i4   
  1 comp_name = vc  
  1 comp_seq = i4   
  1 dont_get_predefined = i4   
) 

 RECORD DPreply (
   1 detail_prefs_id = f8
   1 application_number = i4
   1 position_cd = f8
   1 prsnl_id = f8
   1 person_id = f8
   1 view_name = c12
   1 view_seq = i4
   1 comp_name = c12
   1 comp_seq = i4
   1 updt_cnt = i4
   1 nv_cnt = i4
   1 nv [* ]
     2 name_value_prefs_id = f8
     2 nv_type_flag = i2
     2 pvc_name = c32
     2 pvc_value = vc
     2 updt_cnt = i4
     2 merge_name = vc
     2 merge_id = f8
     2 sequence = i2
   1 status_data
     2 status = c1
     2 subeventstatus [1 ]
       3 operationname = c25
       3 operationstatus = c1
       3 targetobjectname = c25
       3 targetobjectvalue = vc
 )
;declare Main RS for storing the data
RECORD maindata (
  1 pos_cnt = i4
  1 test_dt = vc
  1 pos_list [*]
    2 pos_cd = f8
    2 pos_disp = vc
;    2 app_num = f8
;    2 app_name = vc
    2 reports[*]
      3 frame_type = vc
      3 view_seq = i4
      3 view_nvp_id = f8
      3 view_name = vc
      3 view_disp_seq = i4
      3 ccl_nvp_id = f8
      3 ccl_name = vc
      3 param_nvp_id = f8
      3 param_text = vc
)
;declare RS for storing viewpoints and views

;Set first row of RS to 0 - default all positions


;program variables
declare pc_app_nbr = f8 with public, noconstant(0)
declare pc_app_name = vc with public, noconstant("")
declare rptcnt = i4 with public, noconstant(0)
;;counter and index variables
;declare count = i4 with noconstant(0)
;declare plancnt = i4 with noconstant(0)
;declare ownrcnt = i4 with noconstant(0)
;declare cmpcnt = i4 with noconstant(0)
;declare idx = i4  ;index variable used by internal processing of Expand()


;find application number of PowerChart
select into "NL:"
from application a
where a.object_name = "PowerChart.exe"
;a.description = "HNA: Powerchart"
detail
	pc_app_nbr = a.application_number
	, pc_app_name = trim(a.description)
with time = 60

;hard-code in '0' as position_cd for 'default all positions'
set maindata->test_dt = format(cnvtdatetime(curdate,curtime), "mm/dd/yyyy hh:mm:ss.ccc;;q")
set maindata->pos_cnt = 1
set stat = alterlist(maindata->pos_list, maindata->pos_cnt)
set maindata->pos_list[maindata->pos_cnt].pos_cd = 0
set maindata->pos_list[maindata->pos_cnt].pos_disp = "All Positions"
;set maindata->pos_list[maindata->pos_cnt].app_num = pc_app_nbr
;set maindata->pos_list[maindata->pos_cnt].app_name = pc_app_name

;query to get all postions and store them in Main RS
Select *
from code_value cv
where cv.code_set = 88
and cv.active_ind = 1
and cv.code_value = 11757484
 DETAIL
     maindata->pos_cnt = maindata->pos_cnt + 1
     , stat = alterlist(maindata->pos_list, maindata->pos_cnt)
     , maindata->pos_list[maindata->pos_cnt].pos_cd = cv.code_value
     , maindata->pos_list[maindata->pos_cnt].pos_disp = trim(cv.display)
;     , maindata->pos_list[maindata->pos_cnt].app_num = pc_app_nbr
;     , maindata->pos_list[maindata->pos_cnt].app_name = pc_app_name
 WITH nocounter, time = 60
;end select
;call echorecord(maindata,"scg_test_echorecord1.dat")

;FOR loop to cycle through position list
for(x=1 to size(maindata->pos_list,5))

;fill request RS
set AVPrequest->application_number = pc_app_nbr   
set AVPrequest->position_cd = maindata->pos_list[x].pos_cd    
;set AVPrequest->prsnl_id = f8   
;set AVPrequest->www_flag = i2   
set AVPrequest->preftool_ind = 1   
set AVPrequest->top_view_list_cnt = 2   
set stat = alterlist(AVPrequest->top_view_list,2)
set AVPrequest->top_view_list[1].frame_type = "ORG"
set AVPrequest->top_view_list[2].frame_type = "CHART"

;call request
;format of TDBEXECUTE(appid, taskid, reqid, request_from_type, request_from, reply_to_type, reply_to[,mode]
set stat = tdbexecute(
500017      ;appid - "Preferences Maintenance Tool"
,500255     ;taskid - "UPDATE - PrefMaint"
,500525     ;reqid - "dcp_get_app_view_prefs"
,"REC"     ;request_from_type - "REC" as in "record structure"
,AVPrequest ;request_from - record structure name created in this program (must match what target request is expecting)
,"REC"     ;reply_to_type - "REC" as in "record structure"
,AVPreply  ;reply_to[,mode]- record structure name from the target request
)
;call echorecord(AVPrequest)
;call echorecord(AVPreply)
;call echorecord(AVPreply,"scg_test_echorecord1.dat")

;read reply and save results to main RS
for(y=1 to size(AVPreply->pview,5))
  if((AVPreply->pview[y].frame_type in("ORG","CHART"))
  and (AVPreply->pview[y].view_name="DISCERNRPT"))
  	set rptcnt = rptcnt + 1
  	set stat = alterlist(maindata->pos_list[x].reports, rptcnt)
  	set maindata->pos_list[x].reports[rptcnt].view_nvp_id = AVPreply->pview[y].view_prefs_id
  	set maindata->pos_list[x].reports[rptcnt].view_seq = AVPreply->pview[y].view_seq
  	set maindata->pos_list[x].reports[rptcnt].frame_type = AVPreply->pview[y].frame_type
  	for(z=1 to size(AVPreply->pview[y].nv,5)) ;get individual reports
		if(AVPreply->pview[y].nv[z].pvc_name = "DISPLAY_SEQ")
		  	set maindata->pos_list[x].reports[rptcnt].view_disp_seq = cnvtint(trim(AVPreply->pview[y].nv[z].pvc_value))
		endif
		if(AVPreply->pview[y].nv[z].pvc_name = "VIEW_CAPTION")
		  	set maindata->pos_list[x].reports[rptcnt].view_name = trim(AVPreply->pview[y].nv[z].pvc_value)
		endif
		;fill request RS
		;call request
		;read reply and save results to main RS

	endfor ;get individual reports
	endif

      
;       maindata->pos_list[x].reports  
;       RECORD maindata (
;  1 pos_cnt = i4
;  1 test_dt = vc
;  1 pos_list [*]
;    2 pos_cd = f8
;    2 pos_disp = vc
;;    2 app_num = f8
;;    2 app_name = vc
;    2 reports[*]
;      3 frame_type = vc
;      3 view_seq = i4
;      3 view_nvp_id = f8
;      3 view_name = vc
;      3 view_disp_seq = 14
;      3 ccl_nvp_id = f8
;      3 ccl_name = vc
;      3 param_nvp_id = f8
;      3 param_text = vc
;)
endfor ;read reply and save results to main RS
;

;select into "MINE"
;
;FROM
;     (DUMMYT   D1  WITH SEQ = VALUE(SIZE(cv_record->cv_list, 5)))



ENDFOR ;loop to cycle through position list
call echorecord(maindata,"scg_test_echorecord1.dat")

;FOR loop to cycle through main RS
;based on report_name set up rules for how to clean report_prompts
;save cleaned reprot name
;ENDFOR loop to cycle through main RS

;get viewpoints
;get views
;get components within views including on/off and column sequence (or not sequenced)


END GO

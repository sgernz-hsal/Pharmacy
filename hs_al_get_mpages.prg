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
  1 pos_list [*]
    2 pos_cd = f8
    2 pos_disp = vc
    2 app_num = f8
    2 app_name = vc
    2 reports[*]
      3 frame_type = vc
      3 view_seq = i4
      3 view_nvp_id = f8
      3 view_name = vc
      3 ccl_nvp_id = f8
      3 ccl_name = vc
      3 param_nvp_id = f8
      3 param_text = vc
)
;declare RS for storing viewpoints and views

;Set first row of RS to 0 - default all positions

;query to get all postions and store them in Main RS

;call echorecord(reply,"scg_test_echorecord1.dat")
;FOR loop to cycle through position list

;fill request RS
;call request
;call pharmacy server
;format of TDBEXECUTE(appid, taskid, reqid, request_from_type, request_from, reply_to_type, reply_to[,mode]
;set stat = tdbexecute(
;600005     ;appid - "HNA: Powerchart"
;,3202004   ;taskid - ""
;,3202501   ;reqid - ""
;,"REC"     ;request_from_type - "REC" as in "record structure"
;,requestin ;request_from - record structure name created in this program (must match what target request is expecting)
;,"REC"     ;reply_to_type - "REC" as in "record structure"
;,ReplyOut  ;reply_to[,mode]- record structure name from the target request
;)
;call echorecord(requestin)
;call echorecord(replyout)
;read reply and save results to main RS

;fill request RS
;call request
;read reply and save results to main RS

;ENDFOR loop to cycle through position list

;FOR loop to cycle through main RS
;based on report_name set up rules for how to clean report_prompts
;save cleaned reprot name
;ENDFOR loop to cycle through main RS

;get viewpoints
;get views
;get components within views including on/off and column sequence (or not sequenced)


END GO

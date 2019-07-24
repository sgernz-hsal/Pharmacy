drop program HS_AL_UPDT_MLTM_SCHED go
create program HS_AL_UPDT_MLTM_SCHED
 
prompt
	"Output to File/Printer/MINE" = "MINE"                                                                  ;* Enter or select the
	;<<hidden>>"PROCEED WITH CAUTION:" = 0                                                                  ;* PROCEED WITH CAUTIO
	;<<hidden>>'This updates the drug schedule when run   for all schedules except "Display Report"' = ''   ;* This updates the dr
	, "Multum Drug ID" = ""                                                                                 ;* ex. "d03182"
	;<<hidden>>'Choose "Display Report" to view current settings' = 0                                       ;* Choose "Display Rep
	, "New Schedule" = ""                                                                                   ;* Schedules are 0,1,2
 
with OUTDEV, DRUGID, SCHED
 
;declare record structure
RECORD results (
	1 cnt = i4
	1 qual [*]
	 2 DNUM = vc
	 2 MMDC = i4
	 2 prior_schedule = vc
	 2 prior_updt_dttm = dq8
	 2 prior_updt_cnt = i4
	 2 prior_updt_id = f8
	 2 new_schedule = vc
	 2 new_updt_dttm = dq8
	 2 new_updt_cnt = i4
	 2 new_updt_id = f8
)
 
;variables
declare mltm_drug_id = vc with public, noconstant("")
declare mltm_new_sched = vc with public, noconstant("")
declare err_ind = i4 with public, noconstant(0)
declare err_msg = vc with public, noconstant("ERROR")
declare updt_count = f8 with public, noconstant(0.0)
declare status_msg = vc with public, noconstant("")
declare cntx = i4 with public, noconstant (0)
declare updt_user = f8 with public, noconstant(1)
set mltm_drug_id = trim($DRUGID)
set mltm_new_sched = trim($SCHED)
 
;check for user context
if(REQINFO->UPDT_ID > 0)
 set updt_user = REQINFO->UPDT_ID
else set updt_user = 1; "SYSTEM, SYSTEM"
endif
 
;validate DRUGID prompt
IF(mltm_drug_id="")
 set err_ind = 1
 set err_msg = concat(err_msg, ": Multum Drug ID cannot be blank")
ELSEIF(substring (1 ,2,mltm_drug_id) != "d0")
 set err_ind = 1
 set err_msg = concat(err_msg, ": Multum Drug ID must be format d0####")
endif
IF(err_ind=0)
 ;validate drug ID exists
 select into "NL:"
 *
 from mltm_ndc_main_drug_code mnmdc
 where mnmdc.drug_identifier = mltm_drug_id
 ;reportwriter section
 HEAD REPORT
  results->cnt = 0
 DETAIL
  results->cnt = (results->cnt + 1 )
  , if (results->cnt > size(results->qual, 5)) stat = alterlist(results->qual, (results->cnt + 5)) endif
  , results->qual[results->cnt].DNUM = mnmdc.drug_identifier
  , results->qual[results->cnt].MMDC = mnmdc.main_multum_drug_code
  , results->qual[results->cnt].prior_schedule = mnmdc.csa_schedule
  , results->qual[results->cnt].prior_updt_dttm = mnmdc.updt_dt_tm
  , results->qual[results->cnt].prior_updt_cnt = mnmdc.updt_cnt
  , results->qual[results->cnt].prior_updt_id = mnmdc.updt_id
 FOOT REPORT
  stat = alterlist (results->qual,results->cnt )
 WITH counter, format, separator=" ", time = 60
 ;end select
 if(curqual=0)
  set err_ind = 1
  set err_msg = concat(err_msg, ": Multum Drug ID ", trim(mltm_drug_id), " is not found")
 endif
ENDIF
 
;validate SCHED prompt
IF(mltm_new_sched="")
 set err_ind = 1
 set err_msg = concat(err_msg, ": New Multum schedule cannot be blank")
ELSEIF (mltm_new_sched not in ("0","1","2","3","4","5","REPORT"))
 set err_ind = 1
 set err_msg = concat(err_msg, ": New Multum schedule must be 0, 1, 2, 3, 4, or 5")
ENDIF
 
;only proceed if prompts are valid
IF((err_ind = 0) AND (mltm_new_sched != "REPORT"))
 select into "NL:"
 *
 from mltm_ndc_main_drug_code mnmdc
 where mnmdc.drug_identifier = mltm_drug_id
 and mnmdc.csa_schedule != mltm_new_sched
 with counter, time = 60
 ;end select
 if(curqual>0)  ;only proceed if results are found
  set updt_count = curqual
  update into mltm_ndc_main_drug_code mnmdc
  set mnmdc.csa_schedule = mltm_new_sched;"0"
  , mnmdc.updt_id = updt_user
  , mnmdc.updt_cnt = mnmdc.updt_cnt + 1 ;increases update count
  , mnmdc.updt_dt_tm = cnvtdatetime(curdate,curtime) ;sets update time to now
  , mnmdc.updt_applctx = 3010000 ;sets Discern Visual Developer as update program
  , mnmdc.updt_task = 3011004 ;task = "Backend Explorer program source and programs"
  where mnmdc.drug_identifier = mltm_drug_id;"d03182"
  and mnmdc.csa_schedule != mltm_new_sched;"5"
  COMMIT
 
 ;load updates into RS
 select into "NL:"
 *
 from mltm_ndc_main_drug_code mnmdc
 where mnmdc.drug_identifier = mltm_drug_id
 ;reportwriter section
 DETAIL
  for(cntx=1 to size(results->qual[cntx],5))
   if( (results->qual[cntx].DNUM = mnmdc.drug_identifier) and (results->qual[cntx].MMDC = mnmdc.main_multum_drug_code) )
    results->qual[cntx].new_schedule = mnmdc.csa_schedule
    , results->qual[cntx].new_updt_dttm = mnmdc.updt_dt_tm
    , results->qual[cntx].new_updt_cnt = mnmdc.updt_cnt
    , results->qual[cntx].new_updt_id = mnmdc.updt_id
   endif
  endfor
  , cntx = 0
WITH counter, format, separator=" ", time = 60
;end select
 
/*
;queries for if we decide to add a section to update KDMO refill quantities
select * from mltm_rxb_order mro
where mro.drug_identifier = "d03182"
with time = 20
 
select * from mltm_rxb_order_refill_map mrorm
where mrorm.drug_identifier = "d03182"
with time = 20
 
;update into mltm_rxb_order_refill_map
;set refill_amount = 5,
;UPDT_DT_TM = cnvtdatetime(curdate,curtime3),
;UPDT_ID = <person_id of associate making the change>,
;UPDT_CNT = UPDT_CNT+1 where DRUG_IDENTIFIER = "d03826"
;go
*/
 else
  set err_ind = 1
  set err_msg = concat(err_msg, ": All schedules for ", trim(mltm_drug_id), " already set to ", trim(mltm_new_sched))
 endif
endif
;display status if run in backend
IF ((err_ind = 0 ) )
 CALL echo ("Status: Success")
 CALL echo (build ("Rows updated:" ,trim(cnvtstring(updt_count))))
 set status_msg = build ("Status: Success | Rows updated:" ,trim(cnvtstring(updt_count)))
 ;display record structure to front-end
 if(mltm_new_sched != "REPORT")
  select into $OUTDEV
   DNUM = substring(1,15,trim(results->qual[d1.seq].DNUM))
   , MMDC = substring(1,15,trim(cnvtstring(results->qual[d1.seq].mmdc)))
   , PRIOR_SCHEDULE = substring(1,15,trim(results->qual[d1.seq].prior_schedule))
   , PRIOR_UPDT_DTTM = format(results->qual[d1.seq].prior_updt_dttm, "mm/dd/yyyy hh:mm;;q")
   , PRIOR_UPDT_CNT = substring(1,15,trim(cnvtstring(results->qual[d1.seq].prior_updt_cnt)))
   , PRIOR_UPDT_ID = substring(1,15,trim(cnvtstring(results->qual[d1.seq].prior_updt_id)))
   , PRIOR_UPDT_NAME = trim(substring(1,250,p1.name_full_formatted))
   , SEPARATOR = "   ---->   "
   , NEW_SCHEDULE = substring(1,15,trim(results->qual[d1.seq].new_schedule))
   , NEW_UPDT_DTTM = format(results->qual[d1.seq].new_updt_dttm, "mm/dd/yyyy hh:mm;;q")
   , NEW_UPDT_CNT = substring(1,15,trim(cnvtstring(results->qual[d1.seq].new_updt_cnt)))
   , NEW_UPDT_ID = substring(1,15,trim(cnvtstring(results->qual[d1.seq].new_updt_id)))
   , NEW_UPDT_NAME = trim(substring(1,250,p2.name_full_formatted))
  from (dummyt d1 with seq = size (results->qual, 5) )
  	, prsnl p1
  	, prsnl p2
  plan D1
  join p1 where p1.person_id = results->qual[d1.seq].prior_updt_id
  join p2 where p2.person_id = results->qual[d1.seq].new_updt_id
  WITH nullreport, format, separator = " ", time=1200, format(date,";;q")
  ;end select
 else ;Report mode
  select into $OUTDEV
   DNUM = substring(1,15,trim(results->qual[d1.seq].DNUM))
   , MMDC = substring(1,15,trim(cnvtstring(results->qual[d1.seq].mmdc)))
   , SCHEDULE = substring(1,15,trim(results->qual[d1.seq].prior_schedule))
   , UPDT_DTTM = format(results->qual[d1.seq].prior_updt_dttm, "mm/dd/yyyy hh:mm;;q")
   , UPDT_CNT = substring(1,15,trim(cnvtstring(results->qual[d1.seq].prior_updt_cnt)))
   , UPDT_ID = substring(1,15,trim(cnvtstring(results->qual[d1.seq].prior_updt_id)))
   , UPDT_NAME = trim(substring(1,250,p1.name_full_formatted))
  from (dummyt d1 with seq = size (results->qual, 5) )
  	, prsnl p1
  plan D1
  join p1 where p1.person_id = results->qual[d1.seq].prior_updt_id
  WITH nullreport, format, separator = " ", time=1200, format(date,";;q")
 endif
ELSE
 CALL echo ("Status: Failed")
 CALL echo ("Error occured!" )
 CALL echo (build ("MSG: " , trim(err_msg)))
 set status_msg = build ("Status: Failed | Error Message:" ,trim(err_msg))
 ;display error message to front-end
 Select into $OUTDEV
  Status = substring(1,500,status_msg)
 from dummyt d1
 with time = 20, check, format, separator=" "
ENDIF
 
end
go
 

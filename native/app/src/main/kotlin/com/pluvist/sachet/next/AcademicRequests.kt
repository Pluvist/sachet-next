package com.pluvist.sachet.next

object AcademicRequests {
    fun parameters(feature:String,input:Map<String,String>,now:Long=System.currentTimeMillis()):Map<String,String> {
        val data=linkedMapOf("_search" to "false","nd" to now.toString(),"queryModel.currentPage" to "1",
            "queryModel.sortOrder" to "asc","queryModel.sortName" to "","time" to "0")
        fun value(vararg keys:String)=keys.firstNotNullOfOrNull{input[it]}.orEmpty()
        fun fields(vararg keys:String){keys.forEach{data[it]=value(it)}}
        fun page(size:Int,sort:String=""){data["queryModel.showCount"]=size.toString();data["queryModel.sortName"]=sort}
        when(feature) {
            "grades","exams","textbooks" -> {
                data["xnm"]=value("xnm","cx_xnm","xnm_cx");data["xqm"]=value("xqm","cx_xqm","xqm_cx")
                when(feature) {
                    "grades"->{fields("sfzgcj","kcbj");page(999)}
                    "exams"->{fields("ksmcdmb_id","kch","kc","ksrq","kkbm_id");page(99,"kssj+")}
                    "textbooks"->{fields("autocomplete","kch","jcmc","jczz","cbs","bbh","isbn");data["doType"]="query";page(100,"xnmmc,xqmmc,kcmc,jcmc+")}
                }
            }
            "gpa"->{fields("qsXnxq","zzXnxq","xbx");page(50,"xh+")}
            "cultivation"->{
                data["njdm_id"]=value("nj_cx","njdm_id");data["jg_id"]=value("jg_id");data["zyh_id"]=value("zyh_id_cx","zyh_id")
                fields("dlbs","currentPage_cx");page(1000,"zymc+")
            }
            "curriculum"->{fields("jyxdxnm","jyxdxqm","yxxdxnm","yxxdxqm","shzt","kch","jxzxjhxx_id","xdlx");page(1000,"jyxdxnm,jyxdxqm,kch ")}
            "classrooms" -> {
                val semester=value("dm_cx").split('-')
                require(semester.size==2 && semester[0].matches(Regex("[0-9]{4}")) && semester[1] in listOf("3","12","16")) { "请选择学年学期" }
                data["xnm"]=semester[0];data["xqm"]=semester[1]
                data["zcd"]=bitmask(value("weeks"),60)
                data["xqj"]=numberSet(value("weekdays"),7).sorted().joinToString(",")
                data["jcd"]=bitmask(value("sessions"),11)
                fields("cdejlb_id","qszws","jszws","cdmc","lh","jyfs","cdjylx","sfbhkc")
                listOf("qszws","jszws").forEach{key->require(data[key].isNullOrBlank() || data[key]!!.toIntOrNull()?.let{it>=0}==true){ "座位数请输入非负整数" }}
                val minimum=data["qszws"]?.toIntOrNull();val maximum=data["jszws"]?.toIntOrNull()
                require(minimum==null || maximum==null || minimum<=maximum){ "最大座位数不能小于最小座位数" }
                data["xqh_id"]=input["xqh_id"]?:"02";data["cdlb_id"]=input["cdlb_id"]?:"01";page(9999,"cdmc+")
            }
            else->error("不支持的教务查询")
        }
        return data
    }
    fun numberSet(raw:String,maximum:Int):Set<Int> {
        val values=raw.replace('，',',').split(',').flatMap { part->
            val pair=part.trim().split('-')
            require(pair.size<=2) { "范围格式无效" }
            val first=pair.first().toIntOrNull()?:error("请输入有效的周次、星期或节次")
            val last=pair.last().toIntOrNull()?:error("范围格式无效")
            require(first in 1..maximum && last in first..maximum) { "周次、星期或节次超出范围" }
            (first..last).toList()
        }.toSet()
        require(values.isNotEmpty()) { "至少选择一项" }
        return values
    }
    private fun bitmask(raw:String,maximum:Int)=numberSet(raw,maximum).fold(0L){mask,value->mask or (1L shl(value-1))}.toString()
}

package com.pluvist.sachet.next
import android.webkit.CookieManager
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.compose.foundation.layout.*
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.viewinterop.AndroidView
import androidx.compose.ui.unit.dp
import io.github.neoruaa.glasmio.ui.GlasmioButton

@Composable internal fun WebLoginPage(vm:SachetViewModel,onAuthenticated:(()->Unit)?=null,back:()->Unit) {
    var web by remember{mutableStateOf<WebView?>(null)}
    var submitted by remember{mutableStateOf(false)}
    Column(Modifier.fillMaxSize().safeDrawingPadding()) {
        Row(Modifier.fillMaxWidth().padding(12.dp)){GlasmioButton(onClick=back){Text("返回")}}
        AndroidView(factory={context->WebView(context).apply{
            web=this
            settings.javaScriptEnabled=true;settings.domStorageEnabled=true
            CookieManager.getInstance().setAcceptCookie(true)
            webViewClient=object:WebViewClient(){
                override fun onPageFinished(view:WebView,url:String){
                    val uri=android.net.Uri.parse(url)
                    if(!submitted && uri.scheme=="https" && uri.host=="jw.xtu.edu.cn" && uri.path.orEmpty().contains("index_initMenu")) {
                        val cookie=CookieManager.getInstance().getCookie("https://jw.xtu.edu.cn").orEmpty()
                        if(cookie.isNotBlank()){submitted=true;vm.cookieLogin(cookie,onAuthenticated?:back)}
                    }
                }
            }
            loadUrl("https://jw.xtu.edu.cn/jwglxt/xtgl/login_slogin.html")
        }},modifier=Modifier.fillMaxSize())
    }
    DisposableEffect(Unit){onDispose{web?.stopLoading();web?.destroy();web=null}}
}

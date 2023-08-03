var ajaxhome='https://songtaogui.github.io/';                                // 站点
var ajaxcontent = 'main';                                                   //需要ajax加载的内容
var ajaxsearch_class = 'blog_search';                                       //搜索框class
var ajaxignore_string = new String('#, /album, /wp-, .pdf, .zip, .rar, /goto');     //不需要ajax加载的页面
var ajaxignore = ajaxignore_string.split(', ');
var ajaxloading_code = 'loading...';
var ajaxloading_error_code = '<div class="errajax">AJAX加载失败,可能是网络原因,请刷新重试!</div>';
var ajaxreloadDocumentReady = false;
var ajaxtrack_analytics = false;
var ajaxscroll_top = true;
var ajaxisLoad = false;
var ajaxstarted = false;
var ajaxsearchPath = null;
//var ajaxua = jQuery.browser;
jQuery(document).ready(function() {
    ajaxloadPageInit("");
});
window.onpopstate = function(event) {
    if (ajaxstarted === true && ajaxcheck_ignore(document.location.toString()) == true) {
        ajaxloadPage(document.location.toString(),1);
    }
};
function ajaxloadPageInit(scope){
    jQuery(scope + "a").click(function(event){
        if (this.href.indexOf(ajaxhome) >= 0 && ajaxcheck_ignore(this.href) == true){
            event.preventDefault();
            this.blur();
            var caption = this.title || this.name || "";
            var group = this.rel || false;
            try {
                ajaxclick_code(this);
            } catch(err) {
            }
            ajaxloadPage(this.href);
        }
    });
    jQuery('.' + ajaxsearch_class).each(function(index) {
        if (jQuery(this).attr("action")) {
            ajaxsearchPath = jQuery(this).attr("action");
            jQuery(this).submit(function() {
                submitSearch(jQuery(this).serialize());
                return false;
            });
        }
    });
    if (jQuery('.' + ajaxsearch_class).attr("action")) {} else {
    }
}
function ajaxloadPage(url, push, getData){
    if (!ajaxisLoad){
        if (ajaxscroll_top == true) {
            jQuery('html,body').animate({scrollTop: 0}, 1000);
        }
        ajaxisLoad = true;
        ajaxstarted = true;
        nohttp = url.replace("http://","").replace("https://","");
        firstsla = nohttp.indexOf("/");
        pathpos = url.indexOf(nohttp);
        path = url.substring(pathpos + firstsla);
        if (push != 1) {
            if (typeof window.history.pushState == "function") {
                var stateObj = { foo: 1000 + Math.random()*1001 };
                history.pushState(stateObj, "ajax page loaded...", path);
            } else {
            }
        }
        if (!jQuery('#' + ajaxcontent)) {
        }
        jQuery('#' + ajaxcontent).append(ajaxloading_code);
        jQuery('#' + ajaxcontent).fadeTo("normal", 0.4,function() {
            jQuery('#' + ajaxcontent).fadeIn("normal", function() {
                jQuery.ajax({
                    type: "GET",
                    url: url,
                    data: getData,
                    cache: false,
                    dataType: "html",
                    success: function(data) {
                        ajaxisLoad = false;
                        datax = data.split('<title>');
                        titlesx = data.split('</title>');
                        if (datax.length == 2 || titlesx.length == 2) {
                            data = data.split('<title>')[1];
                            titles = data.split('</title>')[0];
                            jQuery(document).attr('title', (jQuery("<div/>").html(titles).text()));
                        } else {
                        }
                        if (ajaxtrack_analytics == true) {
                            if(typeof _gaq != "undefined") {
                                if (typeof getData == "undefined") {
                                    getData = "";
                                } else {
                                    getData = "?" + getData;
                                }
                                _gaq.push(['_trackPageview', path + getData]);
                            }
                        }
                        data = data.split('id="' + ajaxcontent + '"')[1];
                        data = data.substring(data.indexOf('>') + 1);
                        var depth = 1;
                        var output = '';
                        while(depth > 0) {
                            temp = data.split('</div>')[0];
                            i = 0;
                            pos = temp.indexOf("<div");
                            while (pos != -1) {
                                i++;
                                pos = temp.indexOf("<div", pos + 1);
                            }
                            depth=depth+i-1;
                            output=output+data.split('</div>')[0] + '</div>';
                            data = data.substring(data.indexOf('</div>') + 6);
                        }
                        document.getElementById(ajaxcontent).innerHTML = output;
                        jQuery('#' + ajaxcontent).css("position", "absolute");
                        jQuery('#' + ajaxcontent).css("left", "20000px");
                        jQuery('#' + ajaxcontent).show();
                        ajaxloadPageInit("#" + ajaxcontent + " ");
                        if (ajaxreloadDocumentReady == true) {
                            jQuery(document).trigger("ready");
                        }
                        try {
                            ajaxreload_code();
                        } catch(err) {
                        }
                        jQuery('#' + ajaxcontent).hide();
                        jQuery('#' + ajaxcontent).css("position", "");
                        jQuery('#' + ajaxcontent).css("left", "");
                        jQuery('#' + ajaxcontent).fadeTo("slow", 1, function() {});
                    },
                    error: function(jqXHR, textStatus, errorThrown) {
                        ajaxisLoad = false;
                        document.title = "Error loading requested page!";
                        document.getElementById(ajaxcontent).innerHTML = ajaxloading_error_code;
                    }
                });
            });
        });
    }
}
function submitSearch(param){
    if (!ajaxisLoad){
        ajaxloadPage(ajaxsearchPath, 0, param);
    }
}
function ajaxcheck_ignore(url) {
    for (var i in ajaxignore) {
        if (url.indexOf(ajaxignore[i]) >= 0) {
            return false;
        }
    }
    return true;
}
function ajaxreload_code() {
    //add code here   
}
function ajaxclick_code(thiss) {
    jQuery('ul.nav li').each(function() {
        jQuery(this).removeClass('current-menu-item');
    });
    jQuery(thiss).parents('li').addClass('current-menu-item');
}
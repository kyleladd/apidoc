<%@ Page Language ="C#"%>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="Newtonsoft.Json" %>
<%@ Import Namespace="Newtonsoft.Json.Linq" %>
<%@ Import Namespace="System.Linq" %>
<script runat="server">
    public static string readFile(string filepath){
        try
        {
            using (StreamReader r = new StreamReader(filepath))
            {
                return r.ReadToEnd();
            }
        }
        catch (Exception ex) { }
        return null;
    }

    public static string GetAPIData(string json, string username){
        if (json == null) {
            return null;
        }
        try
        {
            var roles = Roles.GetRolesForUser(username);
            var json_object = JsonConvert.DeserializeObject<JArray>(json).ToObject<List<JToken>>();
            var latest_versions = getLatestVersions(json_object);

            foreach(var article in latest_versions)
            {
                if (article["visibility"] != null)
                {
                    var visibility_object = JsonConvert.DeserializeObject<JToken>((string)article["visibility"]);
                    try
                    {
                        var obj = JToken.Parse(visibility_object + "");
                        if (!obj.SelectToken("users").ToObject<List<string>>().Contains(username))
                        {
                            if (!obj.SelectToken("roles").ToObject<List<string>>().Any(x => roles.Any(y => y == x)))
                            {
                                json_object.RemoveAll(x => x.SelectToken("group")+"" == article.SelectToken("group")+"" && x.SelectToken("name")+"" == article.SelectToken("name")+"");
                            }
                        }
                    }
                    catch (Exception ex) { }
                }
            }
            return JsonConvert.SerializeObject(json_object);
        }
        catch (Exception ex) { }
        return null;
    }

    public static bool IsNewerVersion(string current, string other) {
        var current_version = new Version(current);
        var other_version = new Version(other);
        var result = current_version.CompareTo(other_version);
        if (result > 0)
        {
            return true;
        }
        return false;
    }

    public static List<JToken> getLatestVersions(List<JToken> json_object) {
        var latest_versions = new List<JToken>();
        foreach(var article in json_object)
        {
            var matching_article = latest_versions.FirstOrDefault(x => x.SelectToken("group")+"" == article.SelectToken("group")+"" && x.SelectToken("name")+"" == article.SelectToken("name")+"");
            if (matching_article != null)
            {
                if (IsNewerVersion(article.SelectToken("version") + "", matching_article.SelectToken("version") + ""))
                {
                    latest_versions.RemoveAll(x => x.SelectToken("group")+"" == article.SelectToken("group")+"" && x.SelectToken("name")+"" == article.SelectToken("name")+"");
                    latest_versions.Add(article);
                }
            }
            else {
                latest_versions.Add(article);
            }
        }
        return latest_versions;
    }
</script>
<%
    // Deny access via web.config
    //   <location path="api_data.json">
    //   <system.web>
    //     <authorization>
    //       <deny users="*"  />
    //       <allow users ="" />
    //     </authorization>
    //   </system.web>
    // </location>
    // <location path="api_data.js">
    //   <system.web>
    //     <authorization>
    //       <deny users="*"  />
    //       <allow users ="" />
    //     </authorization>
    //   </system.web>
    // </location>
    string json = readFile(HttpContext.Current.Server.MapPath("api_data.json"));
    var json_object = GetAPIData(json, HttpContext.Current.User.Identity.Name);
    Response.ContentType = "text/javascript;charset=UTF-8";
    Response.Write("define({ \"api\": " + json_object + "});");
%>
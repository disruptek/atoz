
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon CloudWatch Application Insights
## version: 2018-11-25
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon CloudWatch Application Insights for .NET and SQL Server</fullname> <p> Amazon CloudWatch Application Insights for .NET and SQL Server is a service that helps you detect common problems with your .NET and SQL Server-based applications. It enables you to pinpoint the source of issues in your applications (built with technologies such as Microsoft IIS, .NET, and Microsoft SQL Server), by providing key insights into detected problems.</p> <p>After you onboard your application, CloudWatch Application Insights for .NET and SQL Server identifies, recommends, and sets up metrics and logs. It continuously analyzes and correlates your metrics and logs for unusual behavior to surface actionable problems with your application. For example, if your application is slow and unresponsive and leading to HTTP 500 errors in your Application Load Balancer (ALB), Application Insights informs you that a memory pressure problem with your SQL Server database is occurring. It bases this analysis on impactful metrics and log errors. </p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/applicationinsights/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (query: JsonNode = nil; body: JsonNode = nil;
                          header: JsonNode = nil; path: JsonNode = nil;
                          formData: JsonNode = nil): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_599368 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599368](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599368): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low ..
      Scheme.high:
    if scheme notin t.schemes:
      continue
    if scheme in [Scheme.Https, Scheme.Wss]:
      when defined(ssl):
        return some(scheme)
      else:
        continue
    return some(scheme)

proc validateParameter(js: JsonNode; kind: JsonNodeKind; required: bool;
                      default: JsonNode = nil): JsonNode =
  ## ensure an input is of the correct json type and yield
  ## a suitable default value when appropriate
  if js ==
      nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result ==
      nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind ==
        kind, $kind & " expected; received " &
        $js.kind

type
  KeyVal {.used.} = tuple[key: string, val: string]
  PathTokenKind = enum
    ConstantSegment, VariableSegment
  PathToken = tuple[kind: PathTokenKind, value: string]
proc queryString(query: JsonNode): string {.used.} =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.used.} =
  ## reconstitute a path with constants and variable values taken from json
  var head: string
  if segments.len == 0:
    return some("")
  head = segments[0].value
  case segments[0].kind
  of ConstantSegment:
    discard
  of VariableSegment:
    if head notin input:
      return
    let js = input[head]
    case js.kind
    of JInt, JFloat, JNull, JBool:
      head = $js
    of JString:
      head = js.getStr
    else:
      return
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "applicationinsights.ap-northeast-1.amazonaws.com", "ap-southeast-1": "applicationinsights.ap-southeast-1.amazonaws.com", "us-west-2": "applicationinsights.us-west-2.amazonaws.com", "eu-west-2": "applicationinsights.eu-west-2.amazonaws.com", "ap-northeast-3": "applicationinsights.ap-northeast-3.amazonaws.com", "eu-central-1": "applicationinsights.eu-central-1.amazonaws.com", "us-east-2": "applicationinsights.us-east-2.amazonaws.com", "us-east-1": "applicationinsights.us-east-1.amazonaws.com", "cn-northwest-1": "applicationinsights.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "applicationinsights.ap-south-1.amazonaws.com", "eu-north-1": "applicationinsights.eu-north-1.amazonaws.com", "ap-northeast-2": "applicationinsights.ap-northeast-2.amazonaws.com", "us-west-1": "applicationinsights.us-west-1.amazonaws.com", "us-gov-east-1": "applicationinsights.us-gov-east-1.amazonaws.com", "eu-west-3": "applicationinsights.eu-west-3.amazonaws.com", "cn-north-1": "applicationinsights.cn-north-1.amazonaws.com.cn", "sa-east-1": "applicationinsights.sa-east-1.amazonaws.com", "eu-west-1": "applicationinsights.eu-west-1.amazonaws.com", "us-gov-west-1": "applicationinsights.us-gov-west-1.amazonaws.com", "ap-southeast-2": "applicationinsights.ap-southeast-2.amazonaws.com", "ca-central-1": "applicationinsights.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "applicationinsights.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "applicationinsights.ap-southeast-1.amazonaws.com",
      "us-west-2": "applicationinsights.us-west-2.amazonaws.com",
      "eu-west-2": "applicationinsights.eu-west-2.amazonaws.com",
      "ap-northeast-3": "applicationinsights.ap-northeast-3.amazonaws.com",
      "eu-central-1": "applicationinsights.eu-central-1.amazonaws.com",
      "us-east-2": "applicationinsights.us-east-2.amazonaws.com",
      "us-east-1": "applicationinsights.us-east-1.amazonaws.com",
      "cn-northwest-1": "applicationinsights.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "applicationinsights.ap-south-1.amazonaws.com",
      "eu-north-1": "applicationinsights.eu-north-1.amazonaws.com",
      "ap-northeast-2": "applicationinsights.ap-northeast-2.amazonaws.com",
      "us-west-1": "applicationinsights.us-west-1.amazonaws.com",
      "us-gov-east-1": "applicationinsights.us-gov-east-1.amazonaws.com",
      "eu-west-3": "applicationinsights.eu-west-3.amazonaws.com",
      "cn-north-1": "applicationinsights.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "applicationinsights.sa-east-1.amazonaws.com",
      "eu-west-1": "applicationinsights.eu-west-1.amazonaws.com",
      "us-gov-west-1": "applicationinsights.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "applicationinsights.ap-southeast-2.amazonaws.com",
      "ca-central-1": "applicationinsights.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "application-insights"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateApplication_599705 = ref object of OpenApiRestCall_599368
proc url_CreateApplication_599707(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateApplication_599706(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Adds an application that is created from a resource group.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599819 = header.getOrDefault("X-Amz-Date")
  valid_599819 = validateParameter(valid_599819, JString, required = false,
                                 default = nil)
  if valid_599819 != nil:
    section.add "X-Amz-Date", valid_599819
  var valid_599820 = header.getOrDefault("X-Amz-Security-Token")
  valid_599820 = validateParameter(valid_599820, JString, required = false,
                                 default = nil)
  if valid_599820 != nil:
    section.add "X-Amz-Security-Token", valid_599820
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599834 = header.getOrDefault("X-Amz-Target")
  valid_599834 = validateParameter(valid_599834, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.CreateApplication"))
  if valid_599834 != nil:
    section.add "X-Amz-Target", valid_599834
  var valid_599835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599835 = validateParameter(valid_599835, JString, required = false,
                                 default = nil)
  if valid_599835 != nil:
    section.add "X-Amz-Content-Sha256", valid_599835
  var valid_599836 = header.getOrDefault("X-Amz-Algorithm")
  valid_599836 = validateParameter(valid_599836, JString, required = false,
                                 default = nil)
  if valid_599836 != nil:
    section.add "X-Amz-Algorithm", valid_599836
  var valid_599837 = header.getOrDefault("X-Amz-Signature")
  valid_599837 = validateParameter(valid_599837, JString, required = false,
                                 default = nil)
  if valid_599837 != nil:
    section.add "X-Amz-Signature", valid_599837
  var valid_599838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599838 = validateParameter(valid_599838, JString, required = false,
                                 default = nil)
  if valid_599838 != nil:
    section.add "X-Amz-SignedHeaders", valid_599838
  var valid_599839 = header.getOrDefault("X-Amz-Credential")
  valid_599839 = validateParameter(valid_599839, JString, required = false,
                                 default = nil)
  if valid_599839 != nil:
    section.add "X-Amz-Credential", valid_599839
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599863: Call_CreateApplication_599705; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds an application that is created from a resource group.
  ## 
  let valid = call_599863.validator(path, query, header, formData, body)
  let scheme = call_599863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599863.url(scheme.get, call_599863.host, call_599863.base,
                         call_599863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599863, url, valid)

proc call*(call_599934: Call_CreateApplication_599705; body: JsonNode): Recallable =
  ## createApplication
  ## Adds an application that is created from a resource group.
  ##   body: JObject (required)
  var body_599935 = newJObject()
  if body != nil:
    body_599935 = body
  result = call_599934.call(nil, nil, nil, nil, body_599935)

var createApplication* = Call_CreateApplication_599705(name: "createApplication",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.CreateApplication",
    validator: validate_CreateApplication_599706, base: "/",
    url: url_CreateApplication_599707, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateComponent_599974 = ref object of OpenApiRestCall_599368
proc url_CreateComponent_599976(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateComponent_599975(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Creates a custom component by grouping similar standalone instances to monitor.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599977 = header.getOrDefault("X-Amz-Date")
  valid_599977 = validateParameter(valid_599977, JString, required = false,
                                 default = nil)
  if valid_599977 != nil:
    section.add "X-Amz-Date", valid_599977
  var valid_599978 = header.getOrDefault("X-Amz-Security-Token")
  valid_599978 = validateParameter(valid_599978, JString, required = false,
                                 default = nil)
  if valid_599978 != nil:
    section.add "X-Amz-Security-Token", valid_599978
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599979 = header.getOrDefault("X-Amz-Target")
  valid_599979 = validateParameter(valid_599979, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.CreateComponent"))
  if valid_599979 != nil:
    section.add "X-Amz-Target", valid_599979
  var valid_599980 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599980 = validateParameter(valid_599980, JString, required = false,
                                 default = nil)
  if valid_599980 != nil:
    section.add "X-Amz-Content-Sha256", valid_599980
  var valid_599981 = header.getOrDefault("X-Amz-Algorithm")
  valid_599981 = validateParameter(valid_599981, JString, required = false,
                                 default = nil)
  if valid_599981 != nil:
    section.add "X-Amz-Algorithm", valid_599981
  var valid_599982 = header.getOrDefault("X-Amz-Signature")
  valid_599982 = validateParameter(valid_599982, JString, required = false,
                                 default = nil)
  if valid_599982 != nil:
    section.add "X-Amz-Signature", valid_599982
  var valid_599983 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-SignedHeaders", valid_599983
  var valid_599984 = header.getOrDefault("X-Amz-Credential")
  valid_599984 = validateParameter(valid_599984, JString, required = false,
                                 default = nil)
  if valid_599984 != nil:
    section.add "X-Amz-Credential", valid_599984
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599986: Call_CreateComponent_599974; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a custom component by grouping similar standalone instances to monitor.
  ## 
  let valid = call_599986.validator(path, query, header, formData, body)
  let scheme = call_599986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599986.url(scheme.get, call_599986.host, call_599986.base,
                         call_599986.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599986, url, valid)

proc call*(call_599987: Call_CreateComponent_599974; body: JsonNode): Recallable =
  ## createComponent
  ## Creates a custom component by grouping similar standalone instances to monitor.
  ##   body: JObject (required)
  var body_599988 = newJObject()
  if body != nil:
    body_599988 = body
  result = call_599987.call(nil, nil, nil, nil, body_599988)

var createComponent* = Call_CreateComponent_599974(name: "createComponent",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.CreateComponent",
    validator: validate_CreateComponent_599975, base: "/", url: url_CreateComponent_599976,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLogPattern_599989 = ref object of OpenApiRestCall_599368
proc url_CreateLogPattern_599991(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateLogPattern_599990(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Adds an log pattern to a <code>LogPatternSet</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599992 = header.getOrDefault("X-Amz-Date")
  valid_599992 = validateParameter(valid_599992, JString, required = false,
                                 default = nil)
  if valid_599992 != nil:
    section.add "X-Amz-Date", valid_599992
  var valid_599993 = header.getOrDefault("X-Amz-Security-Token")
  valid_599993 = validateParameter(valid_599993, JString, required = false,
                                 default = nil)
  if valid_599993 != nil:
    section.add "X-Amz-Security-Token", valid_599993
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_599994 = header.getOrDefault("X-Amz-Target")
  valid_599994 = validateParameter(valid_599994, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.CreateLogPattern"))
  if valid_599994 != nil:
    section.add "X-Amz-Target", valid_599994
  var valid_599995 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599995 = validateParameter(valid_599995, JString, required = false,
                                 default = nil)
  if valid_599995 != nil:
    section.add "X-Amz-Content-Sha256", valid_599995
  var valid_599996 = header.getOrDefault("X-Amz-Algorithm")
  valid_599996 = validateParameter(valid_599996, JString, required = false,
                                 default = nil)
  if valid_599996 != nil:
    section.add "X-Amz-Algorithm", valid_599996
  var valid_599997 = header.getOrDefault("X-Amz-Signature")
  valid_599997 = validateParameter(valid_599997, JString, required = false,
                                 default = nil)
  if valid_599997 != nil:
    section.add "X-Amz-Signature", valid_599997
  var valid_599998 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599998 = validateParameter(valid_599998, JString, required = false,
                                 default = nil)
  if valid_599998 != nil:
    section.add "X-Amz-SignedHeaders", valid_599998
  var valid_599999 = header.getOrDefault("X-Amz-Credential")
  valid_599999 = validateParameter(valid_599999, JString, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "X-Amz-Credential", valid_599999
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600001: Call_CreateLogPattern_599989; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds an log pattern to a <code>LogPatternSet</code>.
  ## 
  let valid = call_600001.validator(path, query, header, formData, body)
  let scheme = call_600001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600001.url(scheme.get, call_600001.host, call_600001.base,
                         call_600001.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600001, url, valid)

proc call*(call_600002: Call_CreateLogPattern_599989; body: JsonNode): Recallable =
  ## createLogPattern
  ## Adds an log pattern to a <code>LogPatternSet</code>.
  ##   body: JObject (required)
  var body_600003 = newJObject()
  if body != nil:
    body_600003 = body
  result = call_600002.call(nil, nil, nil, nil, body_600003)

var createLogPattern* = Call_CreateLogPattern_599989(name: "createLogPattern",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.CreateLogPattern",
    validator: validate_CreateLogPattern_599990, base: "/",
    url: url_CreateLogPattern_599991, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApplication_600004 = ref object of OpenApiRestCall_599368
proc url_DeleteApplication_600006(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteApplication_600005(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Removes the specified application from monitoring. Does not delete the application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600007 = header.getOrDefault("X-Amz-Date")
  valid_600007 = validateParameter(valid_600007, JString, required = false,
                                 default = nil)
  if valid_600007 != nil:
    section.add "X-Amz-Date", valid_600007
  var valid_600008 = header.getOrDefault("X-Amz-Security-Token")
  valid_600008 = validateParameter(valid_600008, JString, required = false,
                                 default = nil)
  if valid_600008 != nil:
    section.add "X-Amz-Security-Token", valid_600008
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600009 = header.getOrDefault("X-Amz-Target")
  valid_600009 = validateParameter(valid_600009, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.DeleteApplication"))
  if valid_600009 != nil:
    section.add "X-Amz-Target", valid_600009
  var valid_600010 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600010 = validateParameter(valid_600010, JString, required = false,
                                 default = nil)
  if valid_600010 != nil:
    section.add "X-Amz-Content-Sha256", valid_600010
  var valid_600011 = header.getOrDefault("X-Amz-Algorithm")
  valid_600011 = validateParameter(valid_600011, JString, required = false,
                                 default = nil)
  if valid_600011 != nil:
    section.add "X-Amz-Algorithm", valid_600011
  var valid_600012 = header.getOrDefault("X-Amz-Signature")
  valid_600012 = validateParameter(valid_600012, JString, required = false,
                                 default = nil)
  if valid_600012 != nil:
    section.add "X-Amz-Signature", valid_600012
  var valid_600013 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600013 = validateParameter(valid_600013, JString, required = false,
                                 default = nil)
  if valid_600013 != nil:
    section.add "X-Amz-SignedHeaders", valid_600013
  var valid_600014 = header.getOrDefault("X-Amz-Credential")
  valid_600014 = validateParameter(valid_600014, JString, required = false,
                                 default = nil)
  if valid_600014 != nil:
    section.add "X-Amz-Credential", valid_600014
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600016: Call_DeleteApplication_600004; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified application from monitoring. Does not delete the application.
  ## 
  let valid = call_600016.validator(path, query, header, formData, body)
  let scheme = call_600016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600016.url(scheme.get, call_600016.host, call_600016.base,
                         call_600016.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600016, url, valid)

proc call*(call_600017: Call_DeleteApplication_600004; body: JsonNode): Recallable =
  ## deleteApplication
  ## Removes the specified application from monitoring. Does not delete the application.
  ##   body: JObject (required)
  var body_600018 = newJObject()
  if body != nil:
    body_600018 = body
  result = call_600017.call(nil, nil, nil, nil, body_600018)

var deleteApplication* = Call_DeleteApplication_600004(name: "deleteApplication",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.DeleteApplication",
    validator: validate_DeleteApplication_600005, base: "/",
    url: url_DeleteApplication_600006, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteComponent_600019 = ref object of OpenApiRestCall_599368
proc url_DeleteComponent_600021(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteComponent_600020(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Ungroups a custom component. When you ungroup custom components, all applicable monitors that are set up for the component are removed and the instances revert to their standalone status.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600022 = header.getOrDefault("X-Amz-Date")
  valid_600022 = validateParameter(valid_600022, JString, required = false,
                                 default = nil)
  if valid_600022 != nil:
    section.add "X-Amz-Date", valid_600022
  var valid_600023 = header.getOrDefault("X-Amz-Security-Token")
  valid_600023 = validateParameter(valid_600023, JString, required = false,
                                 default = nil)
  if valid_600023 != nil:
    section.add "X-Amz-Security-Token", valid_600023
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600024 = header.getOrDefault("X-Amz-Target")
  valid_600024 = validateParameter(valid_600024, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.DeleteComponent"))
  if valid_600024 != nil:
    section.add "X-Amz-Target", valid_600024
  var valid_600025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600025 = validateParameter(valid_600025, JString, required = false,
                                 default = nil)
  if valid_600025 != nil:
    section.add "X-Amz-Content-Sha256", valid_600025
  var valid_600026 = header.getOrDefault("X-Amz-Algorithm")
  valid_600026 = validateParameter(valid_600026, JString, required = false,
                                 default = nil)
  if valid_600026 != nil:
    section.add "X-Amz-Algorithm", valid_600026
  var valid_600027 = header.getOrDefault("X-Amz-Signature")
  valid_600027 = validateParameter(valid_600027, JString, required = false,
                                 default = nil)
  if valid_600027 != nil:
    section.add "X-Amz-Signature", valid_600027
  var valid_600028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600028 = validateParameter(valid_600028, JString, required = false,
                                 default = nil)
  if valid_600028 != nil:
    section.add "X-Amz-SignedHeaders", valid_600028
  var valid_600029 = header.getOrDefault("X-Amz-Credential")
  valid_600029 = validateParameter(valid_600029, JString, required = false,
                                 default = nil)
  if valid_600029 != nil:
    section.add "X-Amz-Credential", valid_600029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600031: Call_DeleteComponent_600019; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Ungroups a custom component. When you ungroup custom components, all applicable monitors that are set up for the component are removed and the instances revert to their standalone status.
  ## 
  let valid = call_600031.validator(path, query, header, formData, body)
  let scheme = call_600031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600031.url(scheme.get, call_600031.host, call_600031.base,
                         call_600031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600031, url, valid)

proc call*(call_600032: Call_DeleteComponent_600019; body: JsonNode): Recallable =
  ## deleteComponent
  ## Ungroups a custom component. When you ungroup custom components, all applicable monitors that are set up for the component are removed and the instances revert to their standalone status.
  ##   body: JObject (required)
  var body_600033 = newJObject()
  if body != nil:
    body_600033 = body
  result = call_600032.call(nil, nil, nil, nil, body_600033)

var deleteComponent* = Call_DeleteComponent_600019(name: "deleteComponent",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.DeleteComponent",
    validator: validate_DeleteComponent_600020, base: "/", url: url_DeleteComponent_600021,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLogPattern_600034 = ref object of OpenApiRestCall_599368
proc url_DeleteLogPattern_600036(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteLogPattern_600035(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Removes the specified log pattern from a <code>LogPatternSet</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600037 = header.getOrDefault("X-Amz-Date")
  valid_600037 = validateParameter(valid_600037, JString, required = false,
                                 default = nil)
  if valid_600037 != nil:
    section.add "X-Amz-Date", valid_600037
  var valid_600038 = header.getOrDefault("X-Amz-Security-Token")
  valid_600038 = validateParameter(valid_600038, JString, required = false,
                                 default = nil)
  if valid_600038 != nil:
    section.add "X-Amz-Security-Token", valid_600038
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600039 = header.getOrDefault("X-Amz-Target")
  valid_600039 = validateParameter(valid_600039, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.DeleteLogPattern"))
  if valid_600039 != nil:
    section.add "X-Amz-Target", valid_600039
  var valid_600040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600040 = validateParameter(valid_600040, JString, required = false,
                                 default = nil)
  if valid_600040 != nil:
    section.add "X-Amz-Content-Sha256", valid_600040
  var valid_600041 = header.getOrDefault("X-Amz-Algorithm")
  valid_600041 = validateParameter(valid_600041, JString, required = false,
                                 default = nil)
  if valid_600041 != nil:
    section.add "X-Amz-Algorithm", valid_600041
  var valid_600042 = header.getOrDefault("X-Amz-Signature")
  valid_600042 = validateParameter(valid_600042, JString, required = false,
                                 default = nil)
  if valid_600042 != nil:
    section.add "X-Amz-Signature", valid_600042
  var valid_600043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600043 = validateParameter(valid_600043, JString, required = false,
                                 default = nil)
  if valid_600043 != nil:
    section.add "X-Amz-SignedHeaders", valid_600043
  var valid_600044 = header.getOrDefault("X-Amz-Credential")
  valid_600044 = validateParameter(valid_600044, JString, required = false,
                                 default = nil)
  if valid_600044 != nil:
    section.add "X-Amz-Credential", valid_600044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600046: Call_DeleteLogPattern_600034; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified log pattern from a <code>LogPatternSet</code>.
  ## 
  let valid = call_600046.validator(path, query, header, formData, body)
  let scheme = call_600046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600046.url(scheme.get, call_600046.host, call_600046.base,
                         call_600046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600046, url, valid)

proc call*(call_600047: Call_DeleteLogPattern_600034; body: JsonNode): Recallable =
  ## deleteLogPattern
  ## Removes the specified log pattern from a <code>LogPatternSet</code>.
  ##   body: JObject (required)
  var body_600048 = newJObject()
  if body != nil:
    body_600048 = body
  result = call_600047.call(nil, nil, nil, nil, body_600048)

var deleteLogPattern* = Call_DeleteLogPattern_600034(name: "deleteLogPattern",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.DeleteLogPattern",
    validator: validate_DeleteLogPattern_600035, base: "/",
    url: url_DeleteLogPattern_600036, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeApplication_600049 = ref object of OpenApiRestCall_599368
proc url_DescribeApplication_600051(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeApplication_600050(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Describes the application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600052 = header.getOrDefault("X-Amz-Date")
  valid_600052 = validateParameter(valid_600052, JString, required = false,
                                 default = nil)
  if valid_600052 != nil:
    section.add "X-Amz-Date", valid_600052
  var valid_600053 = header.getOrDefault("X-Amz-Security-Token")
  valid_600053 = validateParameter(valid_600053, JString, required = false,
                                 default = nil)
  if valid_600053 != nil:
    section.add "X-Amz-Security-Token", valid_600053
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600054 = header.getOrDefault("X-Amz-Target")
  valid_600054 = validateParameter(valid_600054, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.DescribeApplication"))
  if valid_600054 != nil:
    section.add "X-Amz-Target", valid_600054
  var valid_600055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600055 = validateParameter(valid_600055, JString, required = false,
                                 default = nil)
  if valid_600055 != nil:
    section.add "X-Amz-Content-Sha256", valid_600055
  var valid_600056 = header.getOrDefault("X-Amz-Algorithm")
  valid_600056 = validateParameter(valid_600056, JString, required = false,
                                 default = nil)
  if valid_600056 != nil:
    section.add "X-Amz-Algorithm", valid_600056
  var valid_600057 = header.getOrDefault("X-Amz-Signature")
  valid_600057 = validateParameter(valid_600057, JString, required = false,
                                 default = nil)
  if valid_600057 != nil:
    section.add "X-Amz-Signature", valid_600057
  var valid_600058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600058 = validateParameter(valid_600058, JString, required = false,
                                 default = nil)
  if valid_600058 != nil:
    section.add "X-Amz-SignedHeaders", valid_600058
  var valid_600059 = header.getOrDefault("X-Amz-Credential")
  valid_600059 = validateParameter(valid_600059, JString, required = false,
                                 default = nil)
  if valid_600059 != nil:
    section.add "X-Amz-Credential", valid_600059
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600061: Call_DescribeApplication_600049; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the application.
  ## 
  let valid = call_600061.validator(path, query, header, formData, body)
  let scheme = call_600061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600061.url(scheme.get, call_600061.host, call_600061.base,
                         call_600061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600061, url, valid)

proc call*(call_600062: Call_DescribeApplication_600049; body: JsonNode): Recallable =
  ## describeApplication
  ## Describes the application.
  ##   body: JObject (required)
  var body_600063 = newJObject()
  if body != nil:
    body_600063 = body
  result = call_600062.call(nil, nil, nil, nil, body_600063)

var describeApplication* = Call_DescribeApplication_600049(
    name: "describeApplication", meth: HttpMethod.HttpPost,
    host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.DescribeApplication",
    validator: validate_DescribeApplication_600050, base: "/",
    url: url_DescribeApplication_600051, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeComponent_600064 = ref object of OpenApiRestCall_599368
proc url_DescribeComponent_600066(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeComponent_600065(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Describes a component and lists the resources that are grouped together in a component.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600067 = header.getOrDefault("X-Amz-Date")
  valid_600067 = validateParameter(valid_600067, JString, required = false,
                                 default = nil)
  if valid_600067 != nil:
    section.add "X-Amz-Date", valid_600067
  var valid_600068 = header.getOrDefault("X-Amz-Security-Token")
  valid_600068 = validateParameter(valid_600068, JString, required = false,
                                 default = nil)
  if valid_600068 != nil:
    section.add "X-Amz-Security-Token", valid_600068
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600069 = header.getOrDefault("X-Amz-Target")
  valid_600069 = validateParameter(valid_600069, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.DescribeComponent"))
  if valid_600069 != nil:
    section.add "X-Amz-Target", valid_600069
  var valid_600070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600070 = validateParameter(valid_600070, JString, required = false,
                                 default = nil)
  if valid_600070 != nil:
    section.add "X-Amz-Content-Sha256", valid_600070
  var valid_600071 = header.getOrDefault("X-Amz-Algorithm")
  valid_600071 = validateParameter(valid_600071, JString, required = false,
                                 default = nil)
  if valid_600071 != nil:
    section.add "X-Amz-Algorithm", valid_600071
  var valid_600072 = header.getOrDefault("X-Amz-Signature")
  valid_600072 = validateParameter(valid_600072, JString, required = false,
                                 default = nil)
  if valid_600072 != nil:
    section.add "X-Amz-Signature", valid_600072
  var valid_600073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600073 = validateParameter(valid_600073, JString, required = false,
                                 default = nil)
  if valid_600073 != nil:
    section.add "X-Amz-SignedHeaders", valid_600073
  var valid_600074 = header.getOrDefault("X-Amz-Credential")
  valid_600074 = validateParameter(valid_600074, JString, required = false,
                                 default = nil)
  if valid_600074 != nil:
    section.add "X-Amz-Credential", valid_600074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600076: Call_DescribeComponent_600064; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a component and lists the resources that are grouped together in a component.
  ## 
  let valid = call_600076.validator(path, query, header, formData, body)
  let scheme = call_600076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600076.url(scheme.get, call_600076.host, call_600076.base,
                         call_600076.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600076, url, valid)

proc call*(call_600077: Call_DescribeComponent_600064; body: JsonNode): Recallable =
  ## describeComponent
  ## Describes a component and lists the resources that are grouped together in a component.
  ##   body: JObject (required)
  var body_600078 = newJObject()
  if body != nil:
    body_600078 = body
  result = call_600077.call(nil, nil, nil, nil, body_600078)

var describeComponent* = Call_DescribeComponent_600064(name: "describeComponent",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.DescribeComponent",
    validator: validate_DescribeComponent_600065, base: "/",
    url: url_DescribeComponent_600066, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeComponentConfiguration_600079 = ref object of OpenApiRestCall_599368
proc url_DescribeComponentConfiguration_600081(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeComponentConfiguration_600080(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the monitoring configuration of the component.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600082 = header.getOrDefault("X-Amz-Date")
  valid_600082 = validateParameter(valid_600082, JString, required = false,
                                 default = nil)
  if valid_600082 != nil:
    section.add "X-Amz-Date", valid_600082
  var valid_600083 = header.getOrDefault("X-Amz-Security-Token")
  valid_600083 = validateParameter(valid_600083, JString, required = false,
                                 default = nil)
  if valid_600083 != nil:
    section.add "X-Amz-Security-Token", valid_600083
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600084 = header.getOrDefault("X-Amz-Target")
  valid_600084 = validateParameter(valid_600084, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.DescribeComponentConfiguration"))
  if valid_600084 != nil:
    section.add "X-Amz-Target", valid_600084
  var valid_600085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600085 = validateParameter(valid_600085, JString, required = false,
                                 default = nil)
  if valid_600085 != nil:
    section.add "X-Amz-Content-Sha256", valid_600085
  var valid_600086 = header.getOrDefault("X-Amz-Algorithm")
  valid_600086 = validateParameter(valid_600086, JString, required = false,
                                 default = nil)
  if valid_600086 != nil:
    section.add "X-Amz-Algorithm", valid_600086
  var valid_600087 = header.getOrDefault("X-Amz-Signature")
  valid_600087 = validateParameter(valid_600087, JString, required = false,
                                 default = nil)
  if valid_600087 != nil:
    section.add "X-Amz-Signature", valid_600087
  var valid_600088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600088 = validateParameter(valid_600088, JString, required = false,
                                 default = nil)
  if valid_600088 != nil:
    section.add "X-Amz-SignedHeaders", valid_600088
  var valid_600089 = header.getOrDefault("X-Amz-Credential")
  valid_600089 = validateParameter(valid_600089, JString, required = false,
                                 default = nil)
  if valid_600089 != nil:
    section.add "X-Amz-Credential", valid_600089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600091: Call_DescribeComponentConfiguration_600079; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the monitoring configuration of the component.
  ## 
  let valid = call_600091.validator(path, query, header, formData, body)
  let scheme = call_600091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600091.url(scheme.get, call_600091.host, call_600091.base,
                         call_600091.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600091, url, valid)

proc call*(call_600092: Call_DescribeComponentConfiguration_600079; body: JsonNode): Recallable =
  ## describeComponentConfiguration
  ## Describes the monitoring configuration of the component.
  ##   body: JObject (required)
  var body_600093 = newJObject()
  if body != nil:
    body_600093 = body
  result = call_600092.call(nil, nil, nil, nil, body_600093)

var describeComponentConfiguration* = Call_DescribeComponentConfiguration_600079(
    name: "describeComponentConfiguration", meth: HttpMethod.HttpPost,
    host: "applicationinsights.amazonaws.com", route: "/#X-Amz-Target=EC2WindowsBarleyService.DescribeComponentConfiguration",
    validator: validate_DescribeComponentConfiguration_600080, base: "/",
    url: url_DescribeComponentConfiguration_600081,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeComponentConfigurationRecommendation_600094 = ref object of OpenApiRestCall_599368
proc url_DescribeComponentConfigurationRecommendation_600096(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeComponentConfigurationRecommendation_600095(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the recommended monitoring configuration of the component.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600097 = header.getOrDefault("X-Amz-Date")
  valid_600097 = validateParameter(valid_600097, JString, required = false,
                                 default = nil)
  if valid_600097 != nil:
    section.add "X-Amz-Date", valid_600097
  var valid_600098 = header.getOrDefault("X-Amz-Security-Token")
  valid_600098 = validateParameter(valid_600098, JString, required = false,
                                 default = nil)
  if valid_600098 != nil:
    section.add "X-Amz-Security-Token", valid_600098
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600099 = header.getOrDefault("X-Amz-Target")
  valid_600099 = validateParameter(valid_600099, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.DescribeComponentConfigurationRecommendation"))
  if valid_600099 != nil:
    section.add "X-Amz-Target", valid_600099
  var valid_600100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600100 = validateParameter(valid_600100, JString, required = false,
                                 default = nil)
  if valid_600100 != nil:
    section.add "X-Amz-Content-Sha256", valid_600100
  var valid_600101 = header.getOrDefault("X-Amz-Algorithm")
  valid_600101 = validateParameter(valid_600101, JString, required = false,
                                 default = nil)
  if valid_600101 != nil:
    section.add "X-Amz-Algorithm", valid_600101
  var valid_600102 = header.getOrDefault("X-Amz-Signature")
  valid_600102 = validateParameter(valid_600102, JString, required = false,
                                 default = nil)
  if valid_600102 != nil:
    section.add "X-Amz-Signature", valid_600102
  var valid_600103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600103 = validateParameter(valid_600103, JString, required = false,
                                 default = nil)
  if valid_600103 != nil:
    section.add "X-Amz-SignedHeaders", valid_600103
  var valid_600104 = header.getOrDefault("X-Amz-Credential")
  valid_600104 = validateParameter(valid_600104, JString, required = false,
                                 default = nil)
  if valid_600104 != nil:
    section.add "X-Amz-Credential", valid_600104
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600106: Call_DescribeComponentConfigurationRecommendation_600094;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the recommended monitoring configuration of the component.
  ## 
  let valid = call_600106.validator(path, query, header, formData, body)
  let scheme = call_600106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600106.url(scheme.get, call_600106.host, call_600106.base,
                         call_600106.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600106, url, valid)

proc call*(call_600107: Call_DescribeComponentConfigurationRecommendation_600094;
          body: JsonNode): Recallable =
  ## describeComponentConfigurationRecommendation
  ## Describes the recommended monitoring configuration of the component.
  ##   body: JObject (required)
  var body_600108 = newJObject()
  if body != nil:
    body_600108 = body
  result = call_600107.call(nil, nil, nil, nil, body_600108)

var describeComponentConfigurationRecommendation* = Call_DescribeComponentConfigurationRecommendation_600094(
    name: "describeComponentConfigurationRecommendation",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com", route: "/#X-Amz-Target=EC2WindowsBarleyService.DescribeComponentConfigurationRecommendation",
    validator: validate_DescribeComponentConfigurationRecommendation_600095,
    base: "/", url: url_DescribeComponentConfigurationRecommendation_600096,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLogPattern_600109 = ref object of OpenApiRestCall_599368
proc url_DescribeLogPattern_600111(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeLogPattern_600110(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Describe a specific log pattern from a <code>LogPatternSet</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600112 = header.getOrDefault("X-Amz-Date")
  valid_600112 = validateParameter(valid_600112, JString, required = false,
                                 default = nil)
  if valid_600112 != nil:
    section.add "X-Amz-Date", valid_600112
  var valid_600113 = header.getOrDefault("X-Amz-Security-Token")
  valid_600113 = validateParameter(valid_600113, JString, required = false,
                                 default = nil)
  if valid_600113 != nil:
    section.add "X-Amz-Security-Token", valid_600113
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600114 = header.getOrDefault("X-Amz-Target")
  valid_600114 = validateParameter(valid_600114, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.DescribeLogPattern"))
  if valid_600114 != nil:
    section.add "X-Amz-Target", valid_600114
  var valid_600115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600115 = validateParameter(valid_600115, JString, required = false,
                                 default = nil)
  if valid_600115 != nil:
    section.add "X-Amz-Content-Sha256", valid_600115
  var valid_600116 = header.getOrDefault("X-Amz-Algorithm")
  valid_600116 = validateParameter(valid_600116, JString, required = false,
                                 default = nil)
  if valid_600116 != nil:
    section.add "X-Amz-Algorithm", valid_600116
  var valid_600117 = header.getOrDefault("X-Amz-Signature")
  valid_600117 = validateParameter(valid_600117, JString, required = false,
                                 default = nil)
  if valid_600117 != nil:
    section.add "X-Amz-Signature", valid_600117
  var valid_600118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600118 = validateParameter(valid_600118, JString, required = false,
                                 default = nil)
  if valid_600118 != nil:
    section.add "X-Amz-SignedHeaders", valid_600118
  var valid_600119 = header.getOrDefault("X-Amz-Credential")
  valid_600119 = validateParameter(valid_600119, JString, required = false,
                                 default = nil)
  if valid_600119 != nil:
    section.add "X-Amz-Credential", valid_600119
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600121: Call_DescribeLogPattern_600109; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describe a specific log pattern from a <code>LogPatternSet</code>.
  ## 
  let valid = call_600121.validator(path, query, header, formData, body)
  let scheme = call_600121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600121.url(scheme.get, call_600121.host, call_600121.base,
                         call_600121.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600121, url, valid)

proc call*(call_600122: Call_DescribeLogPattern_600109; body: JsonNode): Recallable =
  ## describeLogPattern
  ## Describe a specific log pattern from a <code>LogPatternSet</code>.
  ##   body: JObject (required)
  var body_600123 = newJObject()
  if body != nil:
    body_600123 = body
  result = call_600122.call(nil, nil, nil, nil, body_600123)

var describeLogPattern* = Call_DescribeLogPattern_600109(
    name: "describeLogPattern", meth: HttpMethod.HttpPost,
    host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.DescribeLogPattern",
    validator: validate_DescribeLogPattern_600110, base: "/",
    url: url_DescribeLogPattern_600111, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeObservation_600124 = ref object of OpenApiRestCall_599368
proc url_DescribeObservation_600126(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeObservation_600125(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Describes an anomaly or error with the application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600127 = header.getOrDefault("X-Amz-Date")
  valid_600127 = validateParameter(valid_600127, JString, required = false,
                                 default = nil)
  if valid_600127 != nil:
    section.add "X-Amz-Date", valid_600127
  var valid_600128 = header.getOrDefault("X-Amz-Security-Token")
  valid_600128 = validateParameter(valid_600128, JString, required = false,
                                 default = nil)
  if valid_600128 != nil:
    section.add "X-Amz-Security-Token", valid_600128
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600129 = header.getOrDefault("X-Amz-Target")
  valid_600129 = validateParameter(valid_600129, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.DescribeObservation"))
  if valid_600129 != nil:
    section.add "X-Amz-Target", valid_600129
  var valid_600130 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600130 = validateParameter(valid_600130, JString, required = false,
                                 default = nil)
  if valid_600130 != nil:
    section.add "X-Amz-Content-Sha256", valid_600130
  var valid_600131 = header.getOrDefault("X-Amz-Algorithm")
  valid_600131 = validateParameter(valid_600131, JString, required = false,
                                 default = nil)
  if valid_600131 != nil:
    section.add "X-Amz-Algorithm", valid_600131
  var valid_600132 = header.getOrDefault("X-Amz-Signature")
  valid_600132 = validateParameter(valid_600132, JString, required = false,
                                 default = nil)
  if valid_600132 != nil:
    section.add "X-Amz-Signature", valid_600132
  var valid_600133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600133 = validateParameter(valid_600133, JString, required = false,
                                 default = nil)
  if valid_600133 != nil:
    section.add "X-Amz-SignedHeaders", valid_600133
  var valid_600134 = header.getOrDefault("X-Amz-Credential")
  valid_600134 = validateParameter(valid_600134, JString, required = false,
                                 default = nil)
  if valid_600134 != nil:
    section.add "X-Amz-Credential", valid_600134
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600136: Call_DescribeObservation_600124; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an anomaly or error with the application.
  ## 
  let valid = call_600136.validator(path, query, header, formData, body)
  let scheme = call_600136.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600136.url(scheme.get, call_600136.host, call_600136.base,
                         call_600136.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600136, url, valid)

proc call*(call_600137: Call_DescribeObservation_600124; body: JsonNode): Recallable =
  ## describeObservation
  ## Describes an anomaly or error with the application.
  ##   body: JObject (required)
  var body_600138 = newJObject()
  if body != nil:
    body_600138 = body
  result = call_600137.call(nil, nil, nil, nil, body_600138)

var describeObservation* = Call_DescribeObservation_600124(
    name: "describeObservation", meth: HttpMethod.HttpPost,
    host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.DescribeObservation",
    validator: validate_DescribeObservation_600125, base: "/",
    url: url_DescribeObservation_600126, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProblem_600139 = ref object of OpenApiRestCall_599368
proc url_DescribeProblem_600141(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProblem_600140(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Describes an application problem.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600142 = header.getOrDefault("X-Amz-Date")
  valid_600142 = validateParameter(valid_600142, JString, required = false,
                                 default = nil)
  if valid_600142 != nil:
    section.add "X-Amz-Date", valid_600142
  var valid_600143 = header.getOrDefault("X-Amz-Security-Token")
  valid_600143 = validateParameter(valid_600143, JString, required = false,
                                 default = nil)
  if valid_600143 != nil:
    section.add "X-Amz-Security-Token", valid_600143
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600144 = header.getOrDefault("X-Amz-Target")
  valid_600144 = validateParameter(valid_600144, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.DescribeProblem"))
  if valid_600144 != nil:
    section.add "X-Amz-Target", valid_600144
  var valid_600145 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600145 = validateParameter(valid_600145, JString, required = false,
                                 default = nil)
  if valid_600145 != nil:
    section.add "X-Amz-Content-Sha256", valid_600145
  var valid_600146 = header.getOrDefault("X-Amz-Algorithm")
  valid_600146 = validateParameter(valid_600146, JString, required = false,
                                 default = nil)
  if valid_600146 != nil:
    section.add "X-Amz-Algorithm", valid_600146
  var valid_600147 = header.getOrDefault("X-Amz-Signature")
  valid_600147 = validateParameter(valid_600147, JString, required = false,
                                 default = nil)
  if valid_600147 != nil:
    section.add "X-Amz-Signature", valid_600147
  var valid_600148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600148 = validateParameter(valid_600148, JString, required = false,
                                 default = nil)
  if valid_600148 != nil:
    section.add "X-Amz-SignedHeaders", valid_600148
  var valid_600149 = header.getOrDefault("X-Amz-Credential")
  valid_600149 = validateParameter(valid_600149, JString, required = false,
                                 default = nil)
  if valid_600149 != nil:
    section.add "X-Amz-Credential", valid_600149
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600151: Call_DescribeProblem_600139; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an application problem.
  ## 
  let valid = call_600151.validator(path, query, header, formData, body)
  let scheme = call_600151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600151.url(scheme.get, call_600151.host, call_600151.base,
                         call_600151.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600151, url, valid)

proc call*(call_600152: Call_DescribeProblem_600139; body: JsonNode): Recallable =
  ## describeProblem
  ## Describes an application problem.
  ##   body: JObject (required)
  var body_600153 = newJObject()
  if body != nil:
    body_600153 = body
  result = call_600152.call(nil, nil, nil, nil, body_600153)

var describeProblem* = Call_DescribeProblem_600139(name: "describeProblem",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.DescribeProblem",
    validator: validate_DescribeProblem_600140, base: "/", url: url_DescribeProblem_600141,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProblemObservations_600154 = ref object of OpenApiRestCall_599368
proc url_DescribeProblemObservations_600156(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProblemObservations_600155(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the anomalies or errors associated with the problem.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600157 = header.getOrDefault("X-Amz-Date")
  valid_600157 = validateParameter(valid_600157, JString, required = false,
                                 default = nil)
  if valid_600157 != nil:
    section.add "X-Amz-Date", valid_600157
  var valid_600158 = header.getOrDefault("X-Amz-Security-Token")
  valid_600158 = validateParameter(valid_600158, JString, required = false,
                                 default = nil)
  if valid_600158 != nil:
    section.add "X-Amz-Security-Token", valid_600158
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600159 = header.getOrDefault("X-Amz-Target")
  valid_600159 = validateParameter(valid_600159, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.DescribeProblemObservations"))
  if valid_600159 != nil:
    section.add "X-Amz-Target", valid_600159
  var valid_600160 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600160 = validateParameter(valid_600160, JString, required = false,
                                 default = nil)
  if valid_600160 != nil:
    section.add "X-Amz-Content-Sha256", valid_600160
  var valid_600161 = header.getOrDefault("X-Amz-Algorithm")
  valid_600161 = validateParameter(valid_600161, JString, required = false,
                                 default = nil)
  if valid_600161 != nil:
    section.add "X-Amz-Algorithm", valid_600161
  var valid_600162 = header.getOrDefault("X-Amz-Signature")
  valid_600162 = validateParameter(valid_600162, JString, required = false,
                                 default = nil)
  if valid_600162 != nil:
    section.add "X-Amz-Signature", valid_600162
  var valid_600163 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600163 = validateParameter(valid_600163, JString, required = false,
                                 default = nil)
  if valid_600163 != nil:
    section.add "X-Amz-SignedHeaders", valid_600163
  var valid_600164 = header.getOrDefault("X-Amz-Credential")
  valid_600164 = validateParameter(valid_600164, JString, required = false,
                                 default = nil)
  if valid_600164 != nil:
    section.add "X-Amz-Credential", valid_600164
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600166: Call_DescribeProblemObservations_600154; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the anomalies or errors associated with the problem.
  ## 
  let valid = call_600166.validator(path, query, header, formData, body)
  let scheme = call_600166.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600166.url(scheme.get, call_600166.host, call_600166.base,
                         call_600166.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600166, url, valid)

proc call*(call_600167: Call_DescribeProblemObservations_600154; body: JsonNode): Recallable =
  ## describeProblemObservations
  ## Describes the anomalies or errors associated with the problem.
  ##   body: JObject (required)
  var body_600168 = newJObject()
  if body != nil:
    body_600168 = body
  result = call_600167.call(nil, nil, nil, nil, body_600168)

var describeProblemObservations* = Call_DescribeProblemObservations_600154(
    name: "describeProblemObservations", meth: HttpMethod.HttpPost,
    host: "applicationinsights.amazonaws.com", route: "/#X-Amz-Target=EC2WindowsBarleyService.DescribeProblemObservations",
    validator: validate_DescribeProblemObservations_600155, base: "/",
    url: url_DescribeProblemObservations_600156,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApplications_600169 = ref object of OpenApiRestCall_599368
proc url_ListApplications_600171(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListApplications_600170(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Lists the IDs of the applications that you are monitoring. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_600172 = query.getOrDefault("NextToken")
  valid_600172 = validateParameter(valid_600172, JString, required = false,
                                 default = nil)
  if valid_600172 != nil:
    section.add "NextToken", valid_600172
  var valid_600173 = query.getOrDefault("MaxResults")
  valid_600173 = validateParameter(valid_600173, JString, required = false,
                                 default = nil)
  if valid_600173 != nil:
    section.add "MaxResults", valid_600173
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600174 = header.getOrDefault("X-Amz-Date")
  valid_600174 = validateParameter(valid_600174, JString, required = false,
                                 default = nil)
  if valid_600174 != nil:
    section.add "X-Amz-Date", valid_600174
  var valid_600175 = header.getOrDefault("X-Amz-Security-Token")
  valid_600175 = validateParameter(valid_600175, JString, required = false,
                                 default = nil)
  if valid_600175 != nil:
    section.add "X-Amz-Security-Token", valid_600175
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600176 = header.getOrDefault("X-Amz-Target")
  valid_600176 = validateParameter(valid_600176, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.ListApplications"))
  if valid_600176 != nil:
    section.add "X-Amz-Target", valid_600176
  var valid_600177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600177 = validateParameter(valid_600177, JString, required = false,
                                 default = nil)
  if valid_600177 != nil:
    section.add "X-Amz-Content-Sha256", valid_600177
  var valid_600178 = header.getOrDefault("X-Amz-Algorithm")
  valid_600178 = validateParameter(valid_600178, JString, required = false,
                                 default = nil)
  if valid_600178 != nil:
    section.add "X-Amz-Algorithm", valid_600178
  var valid_600179 = header.getOrDefault("X-Amz-Signature")
  valid_600179 = validateParameter(valid_600179, JString, required = false,
                                 default = nil)
  if valid_600179 != nil:
    section.add "X-Amz-Signature", valid_600179
  var valid_600180 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600180 = validateParameter(valid_600180, JString, required = false,
                                 default = nil)
  if valid_600180 != nil:
    section.add "X-Amz-SignedHeaders", valid_600180
  var valid_600181 = header.getOrDefault("X-Amz-Credential")
  valid_600181 = validateParameter(valid_600181, JString, required = false,
                                 default = nil)
  if valid_600181 != nil:
    section.add "X-Amz-Credential", valid_600181
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600183: Call_ListApplications_600169; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the IDs of the applications that you are monitoring. 
  ## 
  let valid = call_600183.validator(path, query, header, formData, body)
  let scheme = call_600183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600183.url(scheme.get, call_600183.host, call_600183.base,
                         call_600183.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600183, url, valid)

proc call*(call_600184: Call_ListApplications_600169; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listApplications
  ## Lists the IDs of the applications that you are monitoring. 
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600185 = newJObject()
  var body_600186 = newJObject()
  add(query_600185, "NextToken", newJString(NextToken))
  if body != nil:
    body_600186 = body
  add(query_600185, "MaxResults", newJString(MaxResults))
  result = call_600184.call(nil, query_600185, nil, nil, body_600186)

var listApplications* = Call_ListApplications_600169(name: "listApplications",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.ListApplications",
    validator: validate_ListApplications_600170, base: "/",
    url: url_ListApplications_600171, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListComponents_600188 = ref object of OpenApiRestCall_599368
proc url_ListComponents_600190(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListComponents_600189(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Lists the auto-grouped, standalone, and custom components of the application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_600191 = query.getOrDefault("NextToken")
  valid_600191 = validateParameter(valid_600191, JString, required = false,
                                 default = nil)
  if valid_600191 != nil:
    section.add "NextToken", valid_600191
  var valid_600192 = query.getOrDefault("MaxResults")
  valid_600192 = validateParameter(valid_600192, JString, required = false,
                                 default = nil)
  if valid_600192 != nil:
    section.add "MaxResults", valid_600192
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600193 = header.getOrDefault("X-Amz-Date")
  valid_600193 = validateParameter(valid_600193, JString, required = false,
                                 default = nil)
  if valid_600193 != nil:
    section.add "X-Amz-Date", valid_600193
  var valid_600194 = header.getOrDefault("X-Amz-Security-Token")
  valid_600194 = validateParameter(valid_600194, JString, required = false,
                                 default = nil)
  if valid_600194 != nil:
    section.add "X-Amz-Security-Token", valid_600194
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600195 = header.getOrDefault("X-Amz-Target")
  valid_600195 = validateParameter(valid_600195, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.ListComponents"))
  if valid_600195 != nil:
    section.add "X-Amz-Target", valid_600195
  var valid_600196 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600196 = validateParameter(valid_600196, JString, required = false,
                                 default = nil)
  if valid_600196 != nil:
    section.add "X-Amz-Content-Sha256", valid_600196
  var valid_600197 = header.getOrDefault("X-Amz-Algorithm")
  valid_600197 = validateParameter(valid_600197, JString, required = false,
                                 default = nil)
  if valid_600197 != nil:
    section.add "X-Amz-Algorithm", valid_600197
  var valid_600198 = header.getOrDefault("X-Amz-Signature")
  valid_600198 = validateParameter(valid_600198, JString, required = false,
                                 default = nil)
  if valid_600198 != nil:
    section.add "X-Amz-Signature", valid_600198
  var valid_600199 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600199 = validateParameter(valid_600199, JString, required = false,
                                 default = nil)
  if valid_600199 != nil:
    section.add "X-Amz-SignedHeaders", valid_600199
  var valid_600200 = header.getOrDefault("X-Amz-Credential")
  valid_600200 = validateParameter(valid_600200, JString, required = false,
                                 default = nil)
  if valid_600200 != nil:
    section.add "X-Amz-Credential", valid_600200
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600202: Call_ListComponents_600188; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the auto-grouped, standalone, and custom components of the application.
  ## 
  let valid = call_600202.validator(path, query, header, formData, body)
  let scheme = call_600202.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600202.url(scheme.get, call_600202.host, call_600202.base,
                         call_600202.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600202, url, valid)

proc call*(call_600203: Call_ListComponents_600188; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listComponents
  ## Lists the auto-grouped, standalone, and custom components of the application.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600204 = newJObject()
  var body_600205 = newJObject()
  add(query_600204, "NextToken", newJString(NextToken))
  if body != nil:
    body_600205 = body
  add(query_600204, "MaxResults", newJString(MaxResults))
  result = call_600203.call(nil, query_600204, nil, nil, body_600205)

var listComponents* = Call_ListComponents_600188(name: "listComponents",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.ListComponents",
    validator: validate_ListComponents_600189, base: "/", url: url_ListComponents_600190,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLogPatternSets_600206 = ref object of OpenApiRestCall_599368
proc url_ListLogPatternSets_600208(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListLogPatternSets_600207(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Lists the log pattern sets in the specific application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_600209 = query.getOrDefault("NextToken")
  valid_600209 = validateParameter(valid_600209, JString, required = false,
                                 default = nil)
  if valid_600209 != nil:
    section.add "NextToken", valid_600209
  var valid_600210 = query.getOrDefault("MaxResults")
  valid_600210 = validateParameter(valid_600210, JString, required = false,
                                 default = nil)
  if valid_600210 != nil:
    section.add "MaxResults", valid_600210
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600211 = header.getOrDefault("X-Amz-Date")
  valid_600211 = validateParameter(valid_600211, JString, required = false,
                                 default = nil)
  if valid_600211 != nil:
    section.add "X-Amz-Date", valid_600211
  var valid_600212 = header.getOrDefault("X-Amz-Security-Token")
  valid_600212 = validateParameter(valid_600212, JString, required = false,
                                 default = nil)
  if valid_600212 != nil:
    section.add "X-Amz-Security-Token", valid_600212
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600213 = header.getOrDefault("X-Amz-Target")
  valid_600213 = validateParameter(valid_600213, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.ListLogPatternSets"))
  if valid_600213 != nil:
    section.add "X-Amz-Target", valid_600213
  var valid_600214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600214 = validateParameter(valid_600214, JString, required = false,
                                 default = nil)
  if valid_600214 != nil:
    section.add "X-Amz-Content-Sha256", valid_600214
  var valid_600215 = header.getOrDefault("X-Amz-Algorithm")
  valid_600215 = validateParameter(valid_600215, JString, required = false,
                                 default = nil)
  if valid_600215 != nil:
    section.add "X-Amz-Algorithm", valid_600215
  var valid_600216 = header.getOrDefault("X-Amz-Signature")
  valid_600216 = validateParameter(valid_600216, JString, required = false,
                                 default = nil)
  if valid_600216 != nil:
    section.add "X-Amz-Signature", valid_600216
  var valid_600217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600217 = validateParameter(valid_600217, JString, required = false,
                                 default = nil)
  if valid_600217 != nil:
    section.add "X-Amz-SignedHeaders", valid_600217
  var valid_600218 = header.getOrDefault("X-Amz-Credential")
  valid_600218 = validateParameter(valid_600218, JString, required = false,
                                 default = nil)
  if valid_600218 != nil:
    section.add "X-Amz-Credential", valid_600218
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600220: Call_ListLogPatternSets_600206; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the log pattern sets in the specific application.
  ## 
  let valid = call_600220.validator(path, query, header, formData, body)
  let scheme = call_600220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600220.url(scheme.get, call_600220.host, call_600220.base,
                         call_600220.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600220, url, valid)

proc call*(call_600221: Call_ListLogPatternSets_600206; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listLogPatternSets
  ## Lists the log pattern sets in the specific application.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600222 = newJObject()
  var body_600223 = newJObject()
  add(query_600222, "NextToken", newJString(NextToken))
  if body != nil:
    body_600223 = body
  add(query_600222, "MaxResults", newJString(MaxResults))
  result = call_600221.call(nil, query_600222, nil, nil, body_600223)

var listLogPatternSets* = Call_ListLogPatternSets_600206(
    name: "listLogPatternSets", meth: HttpMethod.HttpPost,
    host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.ListLogPatternSets",
    validator: validate_ListLogPatternSets_600207, base: "/",
    url: url_ListLogPatternSets_600208, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLogPatterns_600224 = ref object of OpenApiRestCall_599368
proc url_ListLogPatterns_600226(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListLogPatterns_600225(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Lists the log patterns in the specific log <code>LogPatternSet</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_600227 = query.getOrDefault("NextToken")
  valid_600227 = validateParameter(valid_600227, JString, required = false,
                                 default = nil)
  if valid_600227 != nil:
    section.add "NextToken", valid_600227
  var valid_600228 = query.getOrDefault("MaxResults")
  valid_600228 = validateParameter(valid_600228, JString, required = false,
                                 default = nil)
  if valid_600228 != nil:
    section.add "MaxResults", valid_600228
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600229 = header.getOrDefault("X-Amz-Date")
  valid_600229 = validateParameter(valid_600229, JString, required = false,
                                 default = nil)
  if valid_600229 != nil:
    section.add "X-Amz-Date", valid_600229
  var valid_600230 = header.getOrDefault("X-Amz-Security-Token")
  valid_600230 = validateParameter(valid_600230, JString, required = false,
                                 default = nil)
  if valid_600230 != nil:
    section.add "X-Amz-Security-Token", valid_600230
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600231 = header.getOrDefault("X-Amz-Target")
  valid_600231 = validateParameter(valid_600231, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.ListLogPatterns"))
  if valid_600231 != nil:
    section.add "X-Amz-Target", valid_600231
  var valid_600232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600232 = validateParameter(valid_600232, JString, required = false,
                                 default = nil)
  if valid_600232 != nil:
    section.add "X-Amz-Content-Sha256", valid_600232
  var valid_600233 = header.getOrDefault("X-Amz-Algorithm")
  valid_600233 = validateParameter(valid_600233, JString, required = false,
                                 default = nil)
  if valid_600233 != nil:
    section.add "X-Amz-Algorithm", valid_600233
  var valid_600234 = header.getOrDefault("X-Amz-Signature")
  valid_600234 = validateParameter(valid_600234, JString, required = false,
                                 default = nil)
  if valid_600234 != nil:
    section.add "X-Amz-Signature", valid_600234
  var valid_600235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600235 = validateParameter(valid_600235, JString, required = false,
                                 default = nil)
  if valid_600235 != nil:
    section.add "X-Amz-SignedHeaders", valid_600235
  var valid_600236 = header.getOrDefault("X-Amz-Credential")
  valid_600236 = validateParameter(valid_600236, JString, required = false,
                                 default = nil)
  if valid_600236 != nil:
    section.add "X-Amz-Credential", valid_600236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600238: Call_ListLogPatterns_600224; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the log patterns in the specific log <code>LogPatternSet</code>.
  ## 
  let valid = call_600238.validator(path, query, header, formData, body)
  let scheme = call_600238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600238.url(scheme.get, call_600238.host, call_600238.base,
                         call_600238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600238, url, valid)

proc call*(call_600239: Call_ListLogPatterns_600224; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listLogPatterns
  ## Lists the log patterns in the specific log <code>LogPatternSet</code>.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600240 = newJObject()
  var body_600241 = newJObject()
  add(query_600240, "NextToken", newJString(NextToken))
  if body != nil:
    body_600241 = body
  add(query_600240, "MaxResults", newJString(MaxResults))
  result = call_600239.call(nil, query_600240, nil, nil, body_600241)

var listLogPatterns* = Call_ListLogPatterns_600224(name: "listLogPatterns",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.ListLogPatterns",
    validator: validate_ListLogPatterns_600225, base: "/", url: url_ListLogPatterns_600226,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProblems_600242 = ref object of OpenApiRestCall_599368
proc url_ListProblems_600244(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListProblems_600243(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the problems with your application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_600245 = query.getOrDefault("NextToken")
  valid_600245 = validateParameter(valid_600245, JString, required = false,
                                 default = nil)
  if valid_600245 != nil:
    section.add "NextToken", valid_600245
  var valid_600246 = query.getOrDefault("MaxResults")
  valid_600246 = validateParameter(valid_600246, JString, required = false,
                                 default = nil)
  if valid_600246 != nil:
    section.add "MaxResults", valid_600246
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600247 = header.getOrDefault("X-Amz-Date")
  valid_600247 = validateParameter(valid_600247, JString, required = false,
                                 default = nil)
  if valid_600247 != nil:
    section.add "X-Amz-Date", valid_600247
  var valid_600248 = header.getOrDefault("X-Amz-Security-Token")
  valid_600248 = validateParameter(valid_600248, JString, required = false,
                                 default = nil)
  if valid_600248 != nil:
    section.add "X-Amz-Security-Token", valid_600248
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600249 = header.getOrDefault("X-Amz-Target")
  valid_600249 = validateParameter(valid_600249, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.ListProblems"))
  if valid_600249 != nil:
    section.add "X-Amz-Target", valid_600249
  var valid_600250 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600250 = validateParameter(valid_600250, JString, required = false,
                                 default = nil)
  if valid_600250 != nil:
    section.add "X-Amz-Content-Sha256", valid_600250
  var valid_600251 = header.getOrDefault("X-Amz-Algorithm")
  valid_600251 = validateParameter(valid_600251, JString, required = false,
                                 default = nil)
  if valid_600251 != nil:
    section.add "X-Amz-Algorithm", valid_600251
  var valid_600252 = header.getOrDefault("X-Amz-Signature")
  valid_600252 = validateParameter(valid_600252, JString, required = false,
                                 default = nil)
  if valid_600252 != nil:
    section.add "X-Amz-Signature", valid_600252
  var valid_600253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600253 = validateParameter(valid_600253, JString, required = false,
                                 default = nil)
  if valid_600253 != nil:
    section.add "X-Amz-SignedHeaders", valid_600253
  var valid_600254 = header.getOrDefault("X-Amz-Credential")
  valid_600254 = validateParameter(valid_600254, JString, required = false,
                                 default = nil)
  if valid_600254 != nil:
    section.add "X-Amz-Credential", valid_600254
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600256: Call_ListProblems_600242; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the problems with your application.
  ## 
  let valid = call_600256.validator(path, query, header, formData, body)
  let scheme = call_600256.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600256.url(scheme.get, call_600256.host, call_600256.base,
                         call_600256.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600256, url, valid)

proc call*(call_600257: Call_ListProblems_600242; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listProblems
  ## Lists the problems with your application.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_600258 = newJObject()
  var body_600259 = newJObject()
  add(query_600258, "NextToken", newJString(NextToken))
  if body != nil:
    body_600259 = body
  add(query_600258, "MaxResults", newJString(MaxResults))
  result = call_600257.call(nil, query_600258, nil, nil, body_600259)

var listProblems* = Call_ListProblems_600242(name: "listProblems",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.ListProblems",
    validator: validate_ListProblems_600243, base: "/", url: url_ListProblems_600244,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_600260 = ref object of OpenApiRestCall_599368
proc url_ListTagsForResource_600262(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_600261(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Retrieve a list of the tags (keys and values) that are associated with a specified application. A <i>tag</i> is a label that you optionally define and associate with an application. Each tag consists of a required <i>tag key</i> and an optional associated <i>tag value</i>. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600263 = header.getOrDefault("X-Amz-Date")
  valid_600263 = validateParameter(valid_600263, JString, required = false,
                                 default = nil)
  if valid_600263 != nil:
    section.add "X-Amz-Date", valid_600263
  var valid_600264 = header.getOrDefault("X-Amz-Security-Token")
  valid_600264 = validateParameter(valid_600264, JString, required = false,
                                 default = nil)
  if valid_600264 != nil:
    section.add "X-Amz-Security-Token", valid_600264
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600265 = header.getOrDefault("X-Amz-Target")
  valid_600265 = validateParameter(valid_600265, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.ListTagsForResource"))
  if valid_600265 != nil:
    section.add "X-Amz-Target", valid_600265
  var valid_600266 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600266 = validateParameter(valid_600266, JString, required = false,
                                 default = nil)
  if valid_600266 != nil:
    section.add "X-Amz-Content-Sha256", valid_600266
  var valid_600267 = header.getOrDefault("X-Amz-Algorithm")
  valid_600267 = validateParameter(valid_600267, JString, required = false,
                                 default = nil)
  if valid_600267 != nil:
    section.add "X-Amz-Algorithm", valid_600267
  var valid_600268 = header.getOrDefault("X-Amz-Signature")
  valid_600268 = validateParameter(valid_600268, JString, required = false,
                                 default = nil)
  if valid_600268 != nil:
    section.add "X-Amz-Signature", valid_600268
  var valid_600269 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600269 = validateParameter(valid_600269, JString, required = false,
                                 default = nil)
  if valid_600269 != nil:
    section.add "X-Amz-SignedHeaders", valid_600269
  var valid_600270 = header.getOrDefault("X-Amz-Credential")
  valid_600270 = validateParameter(valid_600270, JString, required = false,
                                 default = nil)
  if valid_600270 != nil:
    section.add "X-Amz-Credential", valid_600270
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600272: Call_ListTagsForResource_600260; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a list of the tags (keys and values) that are associated with a specified application. A <i>tag</i> is a label that you optionally define and associate with an application. Each tag consists of a required <i>tag key</i> and an optional associated <i>tag value</i>. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.
  ## 
  let valid = call_600272.validator(path, query, header, formData, body)
  let scheme = call_600272.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600272.url(scheme.get, call_600272.host, call_600272.base,
                         call_600272.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600272, url, valid)

proc call*(call_600273: Call_ListTagsForResource_600260; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Retrieve a list of the tags (keys and values) that are associated with a specified application. A <i>tag</i> is a label that you optionally define and associate with an application. Each tag consists of a required <i>tag key</i> and an optional associated <i>tag value</i>. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.
  ##   body: JObject (required)
  var body_600274 = newJObject()
  if body != nil:
    body_600274 = body
  result = call_600273.call(nil, nil, nil, nil, body_600274)

var listTagsForResource* = Call_ListTagsForResource_600260(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.ListTagsForResource",
    validator: validate_ListTagsForResource_600261, base: "/",
    url: url_ListTagsForResource_600262, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_600275 = ref object of OpenApiRestCall_599368
proc url_TagResource_600277(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_600276(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Add one or more tags (keys and values) to a specified application. A <i>tag</i> is a label that you optionally define and associate with an application. Tags can help you categorize and manage application in different ways, such as by purpose, owner, environment, or other criteria. </p> <p>Each tag consists of a required <i>tag key</i> and an associated <i>tag value</i>, both of which you define. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600278 = header.getOrDefault("X-Amz-Date")
  valid_600278 = validateParameter(valid_600278, JString, required = false,
                                 default = nil)
  if valid_600278 != nil:
    section.add "X-Amz-Date", valid_600278
  var valid_600279 = header.getOrDefault("X-Amz-Security-Token")
  valid_600279 = validateParameter(valid_600279, JString, required = false,
                                 default = nil)
  if valid_600279 != nil:
    section.add "X-Amz-Security-Token", valid_600279
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600280 = header.getOrDefault("X-Amz-Target")
  valid_600280 = validateParameter(valid_600280, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.TagResource"))
  if valid_600280 != nil:
    section.add "X-Amz-Target", valid_600280
  var valid_600281 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600281 = validateParameter(valid_600281, JString, required = false,
                                 default = nil)
  if valid_600281 != nil:
    section.add "X-Amz-Content-Sha256", valid_600281
  var valid_600282 = header.getOrDefault("X-Amz-Algorithm")
  valid_600282 = validateParameter(valid_600282, JString, required = false,
                                 default = nil)
  if valid_600282 != nil:
    section.add "X-Amz-Algorithm", valid_600282
  var valid_600283 = header.getOrDefault("X-Amz-Signature")
  valid_600283 = validateParameter(valid_600283, JString, required = false,
                                 default = nil)
  if valid_600283 != nil:
    section.add "X-Amz-Signature", valid_600283
  var valid_600284 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600284 = validateParameter(valid_600284, JString, required = false,
                                 default = nil)
  if valid_600284 != nil:
    section.add "X-Amz-SignedHeaders", valid_600284
  var valid_600285 = header.getOrDefault("X-Amz-Credential")
  valid_600285 = validateParameter(valid_600285, JString, required = false,
                                 default = nil)
  if valid_600285 != nil:
    section.add "X-Amz-Credential", valid_600285
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600287: Call_TagResource_600275; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Add one or more tags (keys and values) to a specified application. A <i>tag</i> is a label that you optionally define and associate with an application. Tags can help you categorize and manage application in different ways, such as by purpose, owner, environment, or other criteria. </p> <p>Each tag consists of a required <i>tag key</i> and an associated <i>tag value</i>, both of which you define. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.</p>
  ## 
  let valid = call_600287.validator(path, query, header, formData, body)
  let scheme = call_600287.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600287.url(scheme.get, call_600287.host, call_600287.base,
                         call_600287.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600287, url, valid)

proc call*(call_600288: Call_TagResource_600275; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Add one or more tags (keys and values) to a specified application. A <i>tag</i> is a label that you optionally define and associate with an application. Tags can help you categorize and manage application in different ways, such as by purpose, owner, environment, or other criteria. </p> <p>Each tag consists of a required <i>tag key</i> and an associated <i>tag value</i>, both of which you define. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.</p>
  ##   body: JObject (required)
  var body_600289 = newJObject()
  if body != nil:
    body_600289 = body
  result = call_600288.call(nil, nil, nil, nil, body_600289)

var tagResource* = Call_TagResource_600275(name: "tagResource",
                                        meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com", route: "/#X-Amz-Target=EC2WindowsBarleyService.TagResource",
                                        validator: validate_TagResource_600276,
                                        base: "/", url: url_TagResource_600277,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_600290 = ref object of OpenApiRestCall_599368
proc url_UntagResource_600292(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_600291(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Remove one or more tags (keys and values) from a specified application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600293 = header.getOrDefault("X-Amz-Date")
  valid_600293 = validateParameter(valid_600293, JString, required = false,
                                 default = nil)
  if valid_600293 != nil:
    section.add "X-Amz-Date", valid_600293
  var valid_600294 = header.getOrDefault("X-Amz-Security-Token")
  valid_600294 = validateParameter(valid_600294, JString, required = false,
                                 default = nil)
  if valid_600294 != nil:
    section.add "X-Amz-Security-Token", valid_600294
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600295 = header.getOrDefault("X-Amz-Target")
  valid_600295 = validateParameter(valid_600295, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.UntagResource"))
  if valid_600295 != nil:
    section.add "X-Amz-Target", valid_600295
  var valid_600296 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600296 = validateParameter(valid_600296, JString, required = false,
                                 default = nil)
  if valid_600296 != nil:
    section.add "X-Amz-Content-Sha256", valid_600296
  var valid_600297 = header.getOrDefault("X-Amz-Algorithm")
  valid_600297 = validateParameter(valid_600297, JString, required = false,
                                 default = nil)
  if valid_600297 != nil:
    section.add "X-Amz-Algorithm", valid_600297
  var valid_600298 = header.getOrDefault("X-Amz-Signature")
  valid_600298 = validateParameter(valid_600298, JString, required = false,
                                 default = nil)
  if valid_600298 != nil:
    section.add "X-Amz-Signature", valid_600298
  var valid_600299 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600299 = validateParameter(valid_600299, JString, required = false,
                                 default = nil)
  if valid_600299 != nil:
    section.add "X-Amz-SignedHeaders", valid_600299
  var valid_600300 = header.getOrDefault("X-Amz-Credential")
  valid_600300 = validateParameter(valid_600300, JString, required = false,
                                 default = nil)
  if valid_600300 != nil:
    section.add "X-Amz-Credential", valid_600300
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600302: Call_UntagResource_600290; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove one or more tags (keys and values) from a specified application.
  ## 
  let valid = call_600302.validator(path, query, header, formData, body)
  let scheme = call_600302.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600302.url(scheme.get, call_600302.host, call_600302.base,
                         call_600302.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600302, url, valid)

proc call*(call_600303: Call_UntagResource_600290; body: JsonNode): Recallable =
  ## untagResource
  ## Remove one or more tags (keys and values) from a specified application.
  ##   body: JObject (required)
  var body_600304 = newJObject()
  if body != nil:
    body_600304 = body
  result = call_600303.call(nil, nil, nil, nil, body_600304)

var untagResource* = Call_UntagResource_600290(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.UntagResource",
    validator: validate_UntagResource_600291, base: "/", url: url_UntagResource_600292,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApplication_600305 = ref object of OpenApiRestCall_599368
proc url_UpdateApplication_600307(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateApplication_600306(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Updates the application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600308 = header.getOrDefault("X-Amz-Date")
  valid_600308 = validateParameter(valid_600308, JString, required = false,
                                 default = nil)
  if valid_600308 != nil:
    section.add "X-Amz-Date", valid_600308
  var valid_600309 = header.getOrDefault("X-Amz-Security-Token")
  valid_600309 = validateParameter(valid_600309, JString, required = false,
                                 default = nil)
  if valid_600309 != nil:
    section.add "X-Amz-Security-Token", valid_600309
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600310 = header.getOrDefault("X-Amz-Target")
  valid_600310 = validateParameter(valid_600310, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.UpdateApplication"))
  if valid_600310 != nil:
    section.add "X-Amz-Target", valid_600310
  var valid_600311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600311 = validateParameter(valid_600311, JString, required = false,
                                 default = nil)
  if valid_600311 != nil:
    section.add "X-Amz-Content-Sha256", valid_600311
  var valid_600312 = header.getOrDefault("X-Amz-Algorithm")
  valid_600312 = validateParameter(valid_600312, JString, required = false,
                                 default = nil)
  if valid_600312 != nil:
    section.add "X-Amz-Algorithm", valid_600312
  var valid_600313 = header.getOrDefault("X-Amz-Signature")
  valid_600313 = validateParameter(valid_600313, JString, required = false,
                                 default = nil)
  if valid_600313 != nil:
    section.add "X-Amz-Signature", valid_600313
  var valid_600314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600314 = validateParameter(valid_600314, JString, required = false,
                                 default = nil)
  if valid_600314 != nil:
    section.add "X-Amz-SignedHeaders", valid_600314
  var valid_600315 = header.getOrDefault("X-Amz-Credential")
  valid_600315 = validateParameter(valid_600315, JString, required = false,
                                 default = nil)
  if valid_600315 != nil:
    section.add "X-Amz-Credential", valid_600315
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600317: Call_UpdateApplication_600305; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the application.
  ## 
  let valid = call_600317.validator(path, query, header, formData, body)
  let scheme = call_600317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600317.url(scheme.get, call_600317.host, call_600317.base,
                         call_600317.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600317, url, valid)

proc call*(call_600318: Call_UpdateApplication_600305; body: JsonNode): Recallable =
  ## updateApplication
  ## Updates the application.
  ##   body: JObject (required)
  var body_600319 = newJObject()
  if body != nil:
    body_600319 = body
  result = call_600318.call(nil, nil, nil, nil, body_600319)

var updateApplication* = Call_UpdateApplication_600305(name: "updateApplication",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.UpdateApplication",
    validator: validate_UpdateApplication_600306, base: "/",
    url: url_UpdateApplication_600307, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateComponent_600320 = ref object of OpenApiRestCall_599368
proc url_UpdateComponent_600322(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateComponent_600321(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Updates the custom component name and/or the list of resources that make up the component.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600323 = header.getOrDefault("X-Amz-Date")
  valid_600323 = validateParameter(valid_600323, JString, required = false,
                                 default = nil)
  if valid_600323 != nil:
    section.add "X-Amz-Date", valid_600323
  var valid_600324 = header.getOrDefault("X-Amz-Security-Token")
  valid_600324 = validateParameter(valid_600324, JString, required = false,
                                 default = nil)
  if valid_600324 != nil:
    section.add "X-Amz-Security-Token", valid_600324
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600325 = header.getOrDefault("X-Amz-Target")
  valid_600325 = validateParameter(valid_600325, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.UpdateComponent"))
  if valid_600325 != nil:
    section.add "X-Amz-Target", valid_600325
  var valid_600326 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600326 = validateParameter(valid_600326, JString, required = false,
                                 default = nil)
  if valid_600326 != nil:
    section.add "X-Amz-Content-Sha256", valid_600326
  var valid_600327 = header.getOrDefault("X-Amz-Algorithm")
  valid_600327 = validateParameter(valid_600327, JString, required = false,
                                 default = nil)
  if valid_600327 != nil:
    section.add "X-Amz-Algorithm", valid_600327
  var valid_600328 = header.getOrDefault("X-Amz-Signature")
  valid_600328 = validateParameter(valid_600328, JString, required = false,
                                 default = nil)
  if valid_600328 != nil:
    section.add "X-Amz-Signature", valid_600328
  var valid_600329 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600329 = validateParameter(valid_600329, JString, required = false,
                                 default = nil)
  if valid_600329 != nil:
    section.add "X-Amz-SignedHeaders", valid_600329
  var valid_600330 = header.getOrDefault("X-Amz-Credential")
  valid_600330 = validateParameter(valid_600330, JString, required = false,
                                 default = nil)
  if valid_600330 != nil:
    section.add "X-Amz-Credential", valid_600330
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600332: Call_UpdateComponent_600320; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the custom component name and/or the list of resources that make up the component.
  ## 
  let valid = call_600332.validator(path, query, header, formData, body)
  let scheme = call_600332.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600332.url(scheme.get, call_600332.host, call_600332.base,
                         call_600332.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600332, url, valid)

proc call*(call_600333: Call_UpdateComponent_600320; body: JsonNode): Recallable =
  ## updateComponent
  ## Updates the custom component name and/or the list of resources that make up the component.
  ##   body: JObject (required)
  var body_600334 = newJObject()
  if body != nil:
    body_600334 = body
  result = call_600333.call(nil, nil, nil, nil, body_600334)

var updateComponent* = Call_UpdateComponent_600320(name: "updateComponent",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.UpdateComponent",
    validator: validate_UpdateComponent_600321, base: "/", url: url_UpdateComponent_600322,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateComponentConfiguration_600335 = ref object of OpenApiRestCall_599368
proc url_UpdateComponentConfiguration_600337(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateComponentConfiguration_600336(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the monitoring configurations for the component. The configuration input parameter is an escaped JSON of the configuration and should match the schema of what is returned by <code>DescribeComponentConfigurationRecommendation</code>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600338 = header.getOrDefault("X-Amz-Date")
  valid_600338 = validateParameter(valid_600338, JString, required = false,
                                 default = nil)
  if valid_600338 != nil:
    section.add "X-Amz-Date", valid_600338
  var valid_600339 = header.getOrDefault("X-Amz-Security-Token")
  valid_600339 = validateParameter(valid_600339, JString, required = false,
                                 default = nil)
  if valid_600339 != nil:
    section.add "X-Amz-Security-Token", valid_600339
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600340 = header.getOrDefault("X-Amz-Target")
  valid_600340 = validateParameter(valid_600340, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.UpdateComponentConfiguration"))
  if valid_600340 != nil:
    section.add "X-Amz-Target", valid_600340
  var valid_600341 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600341 = validateParameter(valid_600341, JString, required = false,
                                 default = nil)
  if valid_600341 != nil:
    section.add "X-Amz-Content-Sha256", valid_600341
  var valid_600342 = header.getOrDefault("X-Amz-Algorithm")
  valid_600342 = validateParameter(valid_600342, JString, required = false,
                                 default = nil)
  if valid_600342 != nil:
    section.add "X-Amz-Algorithm", valid_600342
  var valid_600343 = header.getOrDefault("X-Amz-Signature")
  valid_600343 = validateParameter(valid_600343, JString, required = false,
                                 default = nil)
  if valid_600343 != nil:
    section.add "X-Amz-Signature", valid_600343
  var valid_600344 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600344 = validateParameter(valid_600344, JString, required = false,
                                 default = nil)
  if valid_600344 != nil:
    section.add "X-Amz-SignedHeaders", valid_600344
  var valid_600345 = header.getOrDefault("X-Amz-Credential")
  valid_600345 = validateParameter(valid_600345, JString, required = false,
                                 default = nil)
  if valid_600345 != nil:
    section.add "X-Amz-Credential", valid_600345
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600347: Call_UpdateComponentConfiguration_600335; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the monitoring configurations for the component. The configuration input parameter is an escaped JSON of the configuration and should match the schema of what is returned by <code>DescribeComponentConfigurationRecommendation</code>. 
  ## 
  let valid = call_600347.validator(path, query, header, formData, body)
  let scheme = call_600347.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600347.url(scheme.get, call_600347.host, call_600347.base,
                         call_600347.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600347, url, valid)

proc call*(call_600348: Call_UpdateComponentConfiguration_600335; body: JsonNode): Recallable =
  ## updateComponentConfiguration
  ## Updates the monitoring configurations for the component. The configuration input parameter is an escaped JSON of the configuration and should match the schema of what is returned by <code>DescribeComponentConfigurationRecommendation</code>. 
  ##   body: JObject (required)
  var body_600349 = newJObject()
  if body != nil:
    body_600349 = body
  result = call_600348.call(nil, nil, nil, nil, body_600349)

var updateComponentConfiguration* = Call_UpdateComponentConfiguration_600335(
    name: "updateComponentConfiguration", meth: HttpMethod.HttpPost,
    host: "applicationinsights.amazonaws.com", route: "/#X-Amz-Target=EC2WindowsBarleyService.UpdateComponentConfiguration",
    validator: validate_UpdateComponentConfiguration_600336, base: "/",
    url: url_UpdateComponentConfiguration_600337,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLogPattern_600350 = ref object of OpenApiRestCall_599368
proc url_UpdateLogPattern_600352(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateLogPattern_600351(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Adds a log pattern to a <code>LogPatternSet</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600353 = header.getOrDefault("X-Amz-Date")
  valid_600353 = validateParameter(valid_600353, JString, required = false,
                                 default = nil)
  if valid_600353 != nil:
    section.add "X-Amz-Date", valid_600353
  var valid_600354 = header.getOrDefault("X-Amz-Security-Token")
  valid_600354 = validateParameter(valid_600354, JString, required = false,
                                 default = nil)
  if valid_600354 != nil:
    section.add "X-Amz-Security-Token", valid_600354
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600355 = header.getOrDefault("X-Amz-Target")
  valid_600355 = validateParameter(valid_600355, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.UpdateLogPattern"))
  if valid_600355 != nil:
    section.add "X-Amz-Target", valid_600355
  var valid_600356 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600356 = validateParameter(valid_600356, JString, required = false,
                                 default = nil)
  if valid_600356 != nil:
    section.add "X-Amz-Content-Sha256", valid_600356
  var valid_600357 = header.getOrDefault("X-Amz-Algorithm")
  valid_600357 = validateParameter(valid_600357, JString, required = false,
                                 default = nil)
  if valid_600357 != nil:
    section.add "X-Amz-Algorithm", valid_600357
  var valid_600358 = header.getOrDefault("X-Amz-Signature")
  valid_600358 = validateParameter(valid_600358, JString, required = false,
                                 default = nil)
  if valid_600358 != nil:
    section.add "X-Amz-Signature", valid_600358
  var valid_600359 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600359 = validateParameter(valid_600359, JString, required = false,
                                 default = nil)
  if valid_600359 != nil:
    section.add "X-Amz-SignedHeaders", valid_600359
  var valid_600360 = header.getOrDefault("X-Amz-Credential")
  valid_600360 = validateParameter(valid_600360, JString, required = false,
                                 default = nil)
  if valid_600360 != nil:
    section.add "X-Amz-Credential", valid_600360
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600362: Call_UpdateLogPattern_600350; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a log pattern to a <code>LogPatternSet</code>.
  ## 
  let valid = call_600362.validator(path, query, header, formData, body)
  let scheme = call_600362.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600362.url(scheme.get, call_600362.host, call_600362.base,
                         call_600362.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600362, url, valid)

proc call*(call_600363: Call_UpdateLogPattern_600350; body: JsonNode): Recallable =
  ## updateLogPattern
  ## Adds a log pattern to a <code>LogPatternSet</code>.
  ##   body: JObject (required)
  var body_600364 = newJObject()
  if body != nil:
    body_600364 = body
  result = call_600363.call(nil, nil, nil, nil, body_600364)

var updateLogPattern* = Call_UpdateLogPattern_600350(name: "updateLogPattern",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.UpdateLogPattern",
    validator: validate_UpdateLogPattern_600351, base: "/",
    url: url_UpdateLogPattern_600352, schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", "")
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", "")
    region = os.getEnv("AWS_REGION", "")
  assert secret != "", "need secret key in env"
  assert access != "", "need access key in env"
  assert region != "", "need region in env"
  var
    normal: PathNormal
    url = normalizeUrl(recall.url, query, normalize = normal)
    scheme = parseEnum[Scheme](url.scheme)
  assert scheme in awsServers, "unknown scheme `" & $scheme & "`"
  assert region in awsServers[scheme], "unknown region `" & region & "`"
  url.hostname = awsServers[scheme][region]
  case awsServiceName.toLowerAscii
  of "s3":
    normal = PathNormal.S3
  else:
    normal = PathNormal.Default
  recall.headers["Host"] = url.hostname
  recall.headers["X-Amz-Date"] = date
  let
    algo = SHA256
    scope = credentialScope(region = region, service = awsServiceName, date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers, recall.body,
                             normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date, region = region,
                                 service = awsServiceName, sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)

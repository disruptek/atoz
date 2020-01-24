
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

  OpenApiRestCall_606589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_606589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_606589): Option[Scheme] {.used.} =
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
  Call_CreateApplication_606927 = ref object of OpenApiRestCall_606589
proc url_CreateApplication_606929(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateApplication_606928(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607054 = header.getOrDefault("X-Amz-Target")
  valid_607054 = validateParameter(valid_607054, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.CreateApplication"))
  if valid_607054 != nil:
    section.add "X-Amz-Target", valid_607054
  var valid_607055 = header.getOrDefault("X-Amz-Signature")
  valid_607055 = validateParameter(valid_607055, JString, required = false,
                                 default = nil)
  if valid_607055 != nil:
    section.add "X-Amz-Signature", valid_607055
  var valid_607056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607056 = validateParameter(valid_607056, JString, required = false,
                                 default = nil)
  if valid_607056 != nil:
    section.add "X-Amz-Content-Sha256", valid_607056
  var valid_607057 = header.getOrDefault("X-Amz-Date")
  valid_607057 = validateParameter(valid_607057, JString, required = false,
                                 default = nil)
  if valid_607057 != nil:
    section.add "X-Amz-Date", valid_607057
  var valid_607058 = header.getOrDefault("X-Amz-Credential")
  valid_607058 = validateParameter(valid_607058, JString, required = false,
                                 default = nil)
  if valid_607058 != nil:
    section.add "X-Amz-Credential", valid_607058
  var valid_607059 = header.getOrDefault("X-Amz-Security-Token")
  valid_607059 = validateParameter(valid_607059, JString, required = false,
                                 default = nil)
  if valid_607059 != nil:
    section.add "X-Amz-Security-Token", valid_607059
  var valid_607060 = header.getOrDefault("X-Amz-Algorithm")
  valid_607060 = validateParameter(valid_607060, JString, required = false,
                                 default = nil)
  if valid_607060 != nil:
    section.add "X-Amz-Algorithm", valid_607060
  var valid_607061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607061 = validateParameter(valid_607061, JString, required = false,
                                 default = nil)
  if valid_607061 != nil:
    section.add "X-Amz-SignedHeaders", valid_607061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607085: Call_CreateApplication_606927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds an application that is created from a resource group.
  ## 
  let valid = call_607085.validator(path, query, header, formData, body)
  let scheme = call_607085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607085.url(scheme.get, call_607085.host, call_607085.base,
                         call_607085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607085, url, valid)

proc call*(call_607156: Call_CreateApplication_606927; body: JsonNode): Recallable =
  ## createApplication
  ## Adds an application that is created from a resource group.
  ##   body: JObject (required)
  var body_607157 = newJObject()
  if body != nil:
    body_607157 = body
  result = call_607156.call(nil, nil, nil, nil, body_607157)

var createApplication* = Call_CreateApplication_606927(name: "createApplication",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.CreateApplication",
    validator: validate_CreateApplication_606928, base: "/",
    url: url_CreateApplication_606929, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateComponent_607196 = ref object of OpenApiRestCall_606589
proc url_CreateComponent_607198(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateComponent_607197(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607199 = header.getOrDefault("X-Amz-Target")
  valid_607199 = validateParameter(valid_607199, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.CreateComponent"))
  if valid_607199 != nil:
    section.add "X-Amz-Target", valid_607199
  var valid_607200 = header.getOrDefault("X-Amz-Signature")
  valid_607200 = validateParameter(valid_607200, JString, required = false,
                                 default = nil)
  if valid_607200 != nil:
    section.add "X-Amz-Signature", valid_607200
  var valid_607201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607201 = validateParameter(valid_607201, JString, required = false,
                                 default = nil)
  if valid_607201 != nil:
    section.add "X-Amz-Content-Sha256", valid_607201
  var valid_607202 = header.getOrDefault("X-Amz-Date")
  valid_607202 = validateParameter(valid_607202, JString, required = false,
                                 default = nil)
  if valid_607202 != nil:
    section.add "X-Amz-Date", valid_607202
  var valid_607203 = header.getOrDefault("X-Amz-Credential")
  valid_607203 = validateParameter(valid_607203, JString, required = false,
                                 default = nil)
  if valid_607203 != nil:
    section.add "X-Amz-Credential", valid_607203
  var valid_607204 = header.getOrDefault("X-Amz-Security-Token")
  valid_607204 = validateParameter(valid_607204, JString, required = false,
                                 default = nil)
  if valid_607204 != nil:
    section.add "X-Amz-Security-Token", valid_607204
  var valid_607205 = header.getOrDefault("X-Amz-Algorithm")
  valid_607205 = validateParameter(valid_607205, JString, required = false,
                                 default = nil)
  if valid_607205 != nil:
    section.add "X-Amz-Algorithm", valid_607205
  var valid_607206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607206 = validateParameter(valid_607206, JString, required = false,
                                 default = nil)
  if valid_607206 != nil:
    section.add "X-Amz-SignedHeaders", valid_607206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607208: Call_CreateComponent_607196; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a custom component by grouping similar standalone instances to monitor.
  ## 
  let valid = call_607208.validator(path, query, header, formData, body)
  let scheme = call_607208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607208.url(scheme.get, call_607208.host, call_607208.base,
                         call_607208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607208, url, valid)

proc call*(call_607209: Call_CreateComponent_607196; body: JsonNode): Recallable =
  ## createComponent
  ## Creates a custom component by grouping similar standalone instances to monitor.
  ##   body: JObject (required)
  var body_607210 = newJObject()
  if body != nil:
    body_607210 = body
  result = call_607209.call(nil, nil, nil, nil, body_607210)

var createComponent* = Call_CreateComponent_607196(name: "createComponent",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.CreateComponent",
    validator: validate_CreateComponent_607197, base: "/", url: url_CreateComponent_607198,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLogPattern_607211 = ref object of OpenApiRestCall_606589
proc url_CreateLogPattern_607213(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateLogPattern_607212(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607214 = header.getOrDefault("X-Amz-Target")
  valid_607214 = validateParameter(valid_607214, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.CreateLogPattern"))
  if valid_607214 != nil:
    section.add "X-Amz-Target", valid_607214
  var valid_607215 = header.getOrDefault("X-Amz-Signature")
  valid_607215 = validateParameter(valid_607215, JString, required = false,
                                 default = nil)
  if valid_607215 != nil:
    section.add "X-Amz-Signature", valid_607215
  var valid_607216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607216 = validateParameter(valid_607216, JString, required = false,
                                 default = nil)
  if valid_607216 != nil:
    section.add "X-Amz-Content-Sha256", valid_607216
  var valid_607217 = header.getOrDefault("X-Amz-Date")
  valid_607217 = validateParameter(valid_607217, JString, required = false,
                                 default = nil)
  if valid_607217 != nil:
    section.add "X-Amz-Date", valid_607217
  var valid_607218 = header.getOrDefault("X-Amz-Credential")
  valid_607218 = validateParameter(valid_607218, JString, required = false,
                                 default = nil)
  if valid_607218 != nil:
    section.add "X-Amz-Credential", valid_607218
  var valid_607219 = header.getOrDefault("X-Amz-Security-Token")
  valid_607219 = validateParameter(valid_607219, JString, required = false,
                                 default = nil)
  if valid_607219 != nil:
    section.add "X-Amz-Security-Token", valid_607219
  var valid_607220 = header.getOrDefault("X-Amz-Algorithm")
  valid_607220 = validateParameter(valid_607220, JString, required = false,
                                 default = nil)
  if valid_607220 != nil:
    section.add "X-Amz-Algorithm", valid_607220
  var valid_607221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607221 = validateParameter(valid_607221, JString, required = false,
                                 default = nil)
  if valid_607221 != nil:
    section.add "X-Amz-SignedHeaders", valid_607221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607223: Call_CreateLogPattern_607211; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds an log pattern to a <code>LogPatternSet</code>.
  ## 
  let valid = call_607223.validator(path, query, header, formData, body)
  let scheme = call_607223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607223.url(scheme.get, call_607223.host, call_607223.base,
                         call_607223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607223, url, valid)

proc call*(call_607224: Call_CreateLogPattern_607211; body: JsonNode): Recallable =
  ## createLogPattern
  ## Adds an log pattern to a <code>LogPatternSet</code>.
  ##   body: JObject (required)
  var body_607225 = newJObject()
  if body != nil:
    body_607225 = body
  result = call_607224.call(nil, nil, nil, nil, body_607225)

var createLogPattern* = Call_CreateLogPattern_607211(name: "createLogPattern",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.CreateLogPattern",
    validator: validate_CreateLogPattern_607212, base: "/",
    url: url_CreateLogPattern_607213, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApplication_607226 = ref object of OpenApiRestCall_606589
proc url_DeleteApplication_607228(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteApplication_607227(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607229 = header.getOrDefault("X-Amz-Target")
  valid_607229 = validateParameter(valid_607229, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.DeleteApplication"))
  if valid_607229 != nil:
    section.add "X-Amz-Target", valid_607229
  var valid_607230 = header.getOrDefault("X-Amz-Signature")
  valid_607230 = validateParameter(valid_607230, JString, required = false,
                                 default = nil)
  if valid_607230 != nil:
    section.add "X-Amz-Signature", valid_607230
  var valid_607231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607231 = validateParameter(valid_607231, JString, required = false,
                                 default = nil)
  if valid_607231 != nil:
    section.add "X-Amz-Content-Sha256", valid_607231
  var valid_607232 = header.getOrDefault("X-Amz-Date")
  valid_607232 = validateParameter(valid_607232, JString, required = false,
                                 default = nil)
  if valid_607232 != nil:
    section.add "X-Amz-Date", valid_607232
  var valid_607233 = header.getOrDefault("X-Amz-Credential")
  valid_607233 = validateParameter(valid_607233, JString, required = false,
                                 default = nil)
  if valid_607233 != nil:
    section.add "X-Amz-Credential", valid_607233
  var valid_607234 = header.getOrDefault("X-Amz-Security-Token")
  valid_607234 = validateParameter(valid_607234, JString, required = false,
                                 default = nil)
  if valid_607234 != nil:
    section.add "X-Amz-Security-Token", valid_607234
  var valid_607235 = header.getOrDefault("X-Amz-Algorithm")
  valid_607235 = validateParameter(valid_607235, JString, required = false,
                                 default = nil)
  if valid_607235 != nil:
    section.add "X-Amz-Algorithm", valid_607235
  var valid_607236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607236 = validateParameter(valid_607236, JString, required = false,
                                 default = nil)
  if valid_607236 != nil:
    section.add "X-Amz-SignedHeaders", valid_607236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607238: Call_DeleteApplication_607226; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified application from monitoring. Does not delete the application.
  ## 
  let valid = call_607238.validator(path, query, header, formData, body)
  let scheme = call_607238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607238.url(scheme.get, call_607238.host, call_607238.base,
                         call_607238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607238, url, valid)

proc call*(call_607239: Call_DeleteApplication_607226; body: JsonNode): Recallable =
  ## deleteApplication
  ## Removes the specified application from monitoring. Does not delete the application.
  ##   body: JObject (required)
  var body_607240 = newJObject()
  if body != nil:
    body_607240 = body
  result = call_607239.call(nil, nil, nil, nil, body_607240)

var deleteApplication* = Call_DeleteApplication_607226(name: "deleteApplication",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.DeleteApplication",
    validator: validate_DeleteApplication_607227, base: "/",
    url: url_DeleteApplication_607228, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteComponent_607241 = ref object of OpenApiRestCall_606589
proc url_DeleteComponent_607243(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteComponent_607242(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607244 = header.getOrDefault("X-Amz-Target")
  valid_607244 = validateParameter(valid_607244, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.DeleteComponent"))
  if valid_607244 != nil:
    section.add "X-Amz-Target", valid_607244
  var valid_607245 = header.getOrDefault("X-Amz-Signature")
  valid_607245 = validateParameter(valid_607245, JString, required = false,
                                 default = nil)
  if valid_607245 != nil:
    section.add "X-Amz-Signature", valid_607245
  var valid_607246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607246 = validateParameter(valid_607246, JString, required = false,
                                 default = nil)
  if valid_607246 != nil:
    section.add "X-Amz-Content-Sha256", valid_607246
  var valid_607247 = header.getOrDefault("X-Amz-Date")
  valid_607247 = validateParameter(valid_607247, JString, required = false,
                                 default = nil)
  if valid_607247 != nil:
    section.add "X-Amz-Date", valid_607247
  var valid_607248 = header.getOrDefault("X-Amz-Credential")
  valid_607248 = validateParameter(valid_607248, JString, required = false,
                                 default = nil)
  if valid_607248 != nil:
    section.add "X-Amz-Credential", valid_607248
  var valid_607249 = header.getOrDefault("X-Amz-Security-Token")
  valid_607249 = validateParameter(valid_607249, JString, required = false,
                                 default = nil)
  if valid_607249 != nil:
    section.add "X-Amz-Security-Token", valid_607249
  var valid_607250 = header.getOrDefault("X-Amz-Algorithm")
  valid_607250 = validateParameter(valid_607250, JString, required = false,
                                 default = nil)
  if valid_607250 != nil:
    section.add "X-Amz-Algorithm", valid_607250
  var valid_607251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607251 = validateParameter(valid_607251, JString, required = false,
                                 default = nil)
  if valid_607251 != nil:
    section.add "X-Amz-SignedHeaders", valid_607251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607253: Call_DeleteComponent_607241; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Ungroups a custom component. When you ungroup custom components, all applicable monitors that are set up for the component are removed and the instances revert to their standalone status.
  ## 
  let valid = call_607253.validator(path, query, header, formData, body)
  let scheme = call_607253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607253.url(scheme.get, call_607253.host, call_607253.base,
                         call_607253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607253, url, valid)

proc call*(call_607254: Call_DeleteComponent_607241; body: JsonNode): Recallable =
  ## deleteComponent
  ## Ungroups a custom component. When you ungroup custom components, all applicable monitors that are set up for the component are removed and the instances revert to their standalone status.
  ##   body: JObject (required)
  var body_607255 = newJObject()
  if body != nil:
    body_607255 = body
  result = call_607254.call(nil, nil, nil, nil, body_607255)

var deleteComponent* = Call_DeleteComponent_607241(name: "deleteComponent",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.DeleteComponent",
    validator: validate_DeleteComponent_607242, base: "/", url: url_DeleteComponent_607243,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLogPattern_607256 = ref object of OpenApiRestCall_606589
proc url_DeleteLogPattern_607258(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteLogPattern_607257(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607259 = header.getOrDefault("X-Amz-Target")
  valid_607259 = validateParameter(valid_607259, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.DeleteLogPattern"))
  if valid_607259 != nil:
    section.add "X-Amz-Target", valid_607259
  var valid_607260 = header.getOrDefault("X-Amz-Signature")
  valid_607260 = validateParameter(valid_607260, JString, required = false,
                                 default = nil)
  if valid_607260 != nil:
    section.add "X-Amz-Signature", valid_607260
  var valid_607261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607261 = validateParameter(valid_607261, JString, required = false,
                                 default = nil)
  if valid_607261 != nil:
    section.add "X-Amz-Content-Sha256", valid_607261
  var valid_607262 = header.getOrDefault("X-Amz-Date")
  valid_607262 = validateParameter(valid_607262, JString, required = false,
                                 default = nil)
  if valid_607262 != nil:
    section.add "X-Amz-Date", valid_607262
  var valid_607263 = header.getOrDefault("X-Amz-Credential")
  valid_607263 = validateParameter(valid_607263, JString, required = false,
                                 default = nil)
  if valid_607263 != nil:
    section.add "X-Amz-Credential", valid_607263
  var valid_607264 = header.getOrDefault("X-Amz-Security-Token")
  valid_607264 = validateParameter(valid_607264, JString, required = false,
                                 default = nil)
  if valid_607264 != nil:
    section.add "X-Amz-Security-Token", valid_607264
  var valid_607265 = header.getOrDefault("X-Amz-Algorithm")
  valid_607265 = validateParameter(valid_607265, JString, required = false,
                                 default = nil)
  if valid_607265 != nil:
    section.add "X-Amz-Algorithm", valid_607265
  var valid_607266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607266 = validateParameter(valid_607266, JString, required = false,
                                 default = nil)
  if valid_607266 != nil:
    section.add "X-Amz-SignedHeaders", valid_607266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607268: Call_DeleteLogPattern_607256; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified log pattern from a <code>LogPatternSet</code>.
  ## 
  let valid = call_607268.validator(path, query, header, formData, body)
  let scheme = call_607268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607268.url(scheme.get, call_607268.host, call_607268.base,
                         call_607268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607268, url, valid)

proc call*(call_607269: Call_DeleteLogPattern_607256; body: JsonNode): Recallable =
  ## deleteLogPattern
  ## Removes the specified log pattern from a <code>LogPatternSet</code>.
  ##   body: JObject (required)
  var body_607270 = newJObject()
  if body != nil:
    body_607270 = body
  result = call_607269.call(nil, nil, nil, nil, body_607270)

var deleteLogPattern* = Call_DeleteLogPattern_607256(name: "deleteLogPattern",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.DeleteLogPattern",
    validator: validate_DeleteLogPattern_607257, base: "/",
    url: url_DeleteLogPattern_607258, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeApplication_607271 = ref object of OpenApiRestCall_606589
proc url_DescribeApplication_607273(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeApplication_607272(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607274 = header.getOrDefault("X-Amz-Target")
  valid_607274 = validateParameter(valid_607274, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.DescribeApplication"))
  if valid_607274 != nil:
    section.add "X-Amz-Target", valid_607274
  var valid_607275 = header.getOrDefault("X-Amz-Signature")
  valid_607275 = validateParameter(valid_607275, JString, required = false,
                                 default = nil)
  if valid_607275 != nil:
    section.add "X-Amz-Signature", valid_607275
  var valid_607276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607276 = validateParameter(valid_607276, JString, required = false,
                                 default = nil)
  if valid_607276 != nil:
    section.add "X-Amz-Content-Sha256", valid_607276
  var valid_607277 = header.getOrDefault("X-Amz-Date")
  valid_607277 = validateParameter(valid_607277, JString, required = false,
                                 default = nil)
  if valid_607277 != nil:
    section.add "X-Amz-Date", valid_607277
  var valid_607278 = header.getOrDefault("X-Amz-Credential")
  valid_607278 = validateParameter(valid_607278, JString, required = false,
                                 default = nil)
  if valid_607278 != nil:
    section.add "X-Amz-Credential", valid_607278
  var valid_607279 = header.getOrDefault("X-Amz-Security-Token")
  valid_607279 = validateParameter(valid_607279, JString, required = false,
                                 default = nil)
  if valid_607279 != nil:
    section.add "X-Amz-Security-Token", valid_607279
  var valid_607280 = header.getOrDefault("X-Amz-Algorithm")
  valid_607280 = validateParameter(valid_607280, JString, required = false,
                                 default = nil)
  if valid_607280 != nil:
    section.add "X-Amz-Algorithm", valid_607280
  var valid_607281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607281 = validateParameter(valid_607281, JString, required = false,
                                 default = nil)
  if valid_607281 != nil:
    section.add "X-Amz-SignedHeaders", valid_607281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607283: Call_DescribeApplication_607271; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the application.
  ## 
  let valid = call_607283.validator(path, query, header, formData, body)
  let scheme = call_607283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607283.url(scheme.get, call_607283.host, call_607283.base,
                         call_607283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607283, url, valid)

proc call*(call_607284: Call_DescribeApplication_607271; body: JsonNode): Recallable =
  ## describeApplication
  ## Describes the application.
  ##   body: JObject (required)
  var body_607285 = newJObject()
  if body != nil:
    body_607285 = body
  result = call_607284.call(nil, nil, nil, nil, body_607285)

var describeApplication* = Call_DescribeApplication_607271(
    name: "describeApplication", meth: HttpMethod.HttpPost,
    host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.DescribeApplication",
    validator: validate_DescribeApplication_607272, base: "/",
    url: url_DescribeApplication_607273, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeComponent_607286 = ref object of OpenApiRestCall_606589
proc url_DescribeComponent_607288(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeComponent_607287(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607289 = header.getOrDefault("X-Amz-Target")
  valid_607289 = validateParameter(valid_607289, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.DescribeComponent"))
  if valid_607289 != nil:
    section.add "X-Amz-Target", valid_607289
  var valid_607290 = header.getOrDefault("X-Amz-Signature")
  valid_607290 = validateParameter(valid_607290, JString, required = false,
                                 default = nil)
  if valid_607290 != nil:
    section.add "X-Amz-Signature", valid_607290
  var valid_607291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607291 = validateParameter(valid_607291, JString, required = false,
                                 default = nil)
  if valid_607291 != nil:
    section.add "X-Amz-Content-Sha256", valid_607291
  var valid_607292 = header.getOrDefault("X-Amz-Date")
  valid_607292 = validateParameter(valid_607292, JString, required = false,
                                 default = nil)
  if valid_607292 != nil:
    section.add "X-Amz-Date", valid_607292
  var valid_607293 = header.getOrDefault("X-Amz-Credential")
  valid_607293 = validateParameter(valid_607293, JString, required = false,
                                 default = nil)
  if valid_607293 != nil:
    section.add "X-Amz-Credential", valid_607293
  var valid_607294 = header.getOrDefault("X-Amz-Security-Token")
  valid_607294 = validateParameter(valid_607294, JString, required = false,
                                 default = nil)
  if valid_607294 != nil:
    section.add "X-Amz-Security-Token", valid_607294
  var valid_607295 = header.getOrDefault("X-Amz-Algorithm")
  valid_607295 = validateParameter(valid_607295, JString, required = false,
                                 default = nil)
  if valid_607295 != nil:
    section.add "X-Amz-Algorithm", valid_607295
  var valid_607296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607296 = validateParameter(valid_607296, JString, required = false,
                                 default = nil)
  if valid_607296 != nil:
    section.add "X-Amz-SignedHeaders", valid_607296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607298: Call_DescribeComponent_607286; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a component and lists the resources that are grouped together in a component.
  ## 
  let valid = call_607298.validator(path, query, header, formData, body)
  let scheme = call_607298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607298.url(scheme.get, call_607298.host, call_607298.base,
                         call_607298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607298, url, valid)

proc call*(call_607299: Call_DescribeComponent_607286; body: JsonNode): Recallable =
  ## describeComponent
  ## Describes a component and lists the resources that are grouped together in a component.
  ##   body: JObject (required)
  var body_607300 = newJObject()
  if body != nil:
    body_607300 = body
  result = call_607299.call(nil, nil, nil, nil, body_607300)

var describeComponent* = Call_DescribeComponent_607286(name: "describeComponent",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.DescribeComponent",
    validator: validate_DescribeComponent_607287, base: "/",
    url: url_DescribeComponent_607288, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeComponentConfiguration_607301 = ref object of OpenApiRestCall_606589
proc url_DescribeComponentConfiguration_607303(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeComponentConfiguration_607302(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607304 = header.getOrDefault("X-Amz-Target")
  valid_607304 = validateParameter(valid_607304, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.DescribeComponentConfiguration"))
  if valid_607304 != nil:
    section.add "X-Amz-Target", valid_607304
  var valid_607305 = header.getOrDefault("X-Amz-Signature")
  valid_607305 = validateParameter(valid_607305, JString, required = false,
                                 default = nil)
  if valid_607305 != nil:
    section.add "X-Amz-Signature", valid_607305
  var valid_607306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607306 = validateParameter(valid_607306, JString, required = false,
                                 default = nil)
  if valid_607306 != nil:
    section.add "X-Amz-Content-Sha256", valid_607306
  var valid_607307 = header.getOrDefault("X-Amz-Date")
  valid_607307 = validateParameter(valid_607307, JString, required = false,
                                 default = nil)
  if valid_607307 != nil:
    section.add "X-Amz-Date", valid_607307
  var valid_607308 = header.getOrDefault("X-Amz-Credential")
  valid_607308 = validateParameter(valid_607308, JString, required = false,
                                 default = nil)
  if valid_607308 != nil:
    section.add "X-Amz-Credential", valid_607308
  var valid_607309 = header.getOrDefault("X-Amz-Security-Token")
  valid_607309 = validateParameter(valid_607309, JString, required = false,
                                 default = nil)
  if valid_607309 != nil:
    section.add "X-Amz-Security-Token", valid_607309
  var valid_607310 = header.getOrDefault("X-Amz-Algorithm")
  valid_607310 = validateParameter(valid_607310, JString, required = false,
                                 default = nil)
  if valid_607310 != nil:
    section.add "X-Amz-Algorithm", valid_607310
  var valid_607311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607311 = validateParameter(valid_607311, JString, required = false,
                                 default = nil)
  if valid_607311 != nil:
    section.add "X-Amz-SignedHeaders", valid_607311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607313: Call_DescribeComponentConfiguration_607301; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the monitoring configuration of the component.
  ## 
  let valid = call_607313.validator(path, query, header, formData, body)
  let scheme = call_607313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607313.url(scheme.get, call_607313.host, call_607313.base,
                         call_607313.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607313, url, valid)

proc call*(call_607314: Call_DescribeComponentConfiguration_607301; body: JsonNode): Recallable =
  ## describeComponentConfiguration
  ## Describes the monitoring configuration of the component.
  ##   body: JObject (required)
  var body_607315 = newJObject()
  if body != nil:
    body_607315 = body
  result = call_607314.call(nil, nil, nil, nil, body_607315)

var describeComponentConfiguration* = Call_DescribeComponentConfiguration_607301(
    name: "describeComponentConfiguration", meth: HttpMethod.HttpPost,
    host: "applicationinsights.amazonaws.com", route: "/#X-Amz-Target=EC2WindowsBarleyService.DescribeComponentConfiguration",
    validator: validate_DescribeComponentConfiguration_607302, base: "/",
    url: url_DescribeComponentConfiguration_607303,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeComponentConfigurationRecommendation_607316 = ref object of OpenApiRestCall_606589
proc url_DescribeComponentConfigurationRecommendation_607318(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeComponentConfigurationRecommendation_607317(path: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607319 = header.getOrDefault("X-Amz-Target")
  valid_607319 = validateParameter(valid_607319, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.DescribeComponentConfigurationRecommendation"))
  if valid_607319 != nil:
    section.add "X-Amz-Target", valid_607319
  var valid_607320 = header.getOrDefault("X-Amz-Signature")
  valid_607320 = validateParameter(valid_607320, JString, required = false,
                                 default = nil)
  if valid_607320 != nil:
    section.add "X-Amz-Signature", valid_607320
  var valid_607321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607321 = validateParameter(valid_607321, JString, required = false,
                                 default = nil)
  if valid_607321 != nil:
    section.add "X-Amz-Content-Sha256", valid_607321
  var valid_607322 = header.getOrDefault("X-Amz-Date")
  valid_607322 = validateParameter(valid_607322, JString, required = false,
                                 default = nil)
  if valid_607322 != nil:
    section.add "X-Amz-Date", valid_607322
  var valid_607323 = header.getOrDefault("X-Amz-Credential")
  valid_607323 = validateParameter(valid_607323, JString, required = false,
                                 default = nil)
  if valid_607323 != nil:
    section.add "X-Amz-Credential", valid_607323
  var valid_607324 = header.getOrDefault("X-Amz-Security-Token")
  valid_607324 = validateParameter(valid_607324, JString, required = false,
                                 default = nil)
  if valid_607324 != nil:
    section.add "X-Amz-Security-Token", valid_607324
  var valid_607325 = header.getOrDefault("X-Amz-Algorithm")
  valid_607325 = validateParameter(valid_607325, JString, required = false,
                                 default = nil)
  if valid_607325 != nil:
    section.add "X-Amz-Algorithm", valid_607325
  var valid_607326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607326 = validateParameter(valid_607326, JString, required = false,
                                 default = nil)
  if valid_607326 != nil:
    section.add "X-Amz-SignedHeaders", valid_607326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607328: Call_DescribeComponentConfigurationRecommendation_607316;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the recommended monitoring configuration of the component.
  ## 
  let valid = call_607328.validator(path, query, header, formData, body)
  let scheme = call_607328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607328.url(scheme.get, call_607328.host, call_607328.base,
                         call_607328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607328, url, valid)

proc call*(call_607329: Call_DescribeComponentConfigurationRecommendation_607316;
          body: JsonNode): Recallable =
  ## describeComponentConfigurationRecommendation
  ## Describes the recommended monitoring configuration of the component.
  ##   body: JObject (required)
  var body_607330 = newJObject()
  if body != nil:
    body_607330 = body
  result = call_607329.call(nil, nil, nil, nil, body_607330)

var describeComponentConfigurationRecommendation* = Call_DescribeComponentConfigurationRecommendation_607316(
    name: "describeComponentConfigurationRecommendation",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com", route: "/#X-Amz-Target=EC2WindowsBarleyService.DescribeComponentConfigurationRecommendation",
    validator: validate_DescribeComponentConfigurationRecommendation_607317,
    base: "/", url: url_DescribeComponentConfigurationRecommendation_607318,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLogPattern_607331 = ref object of OpenApiRestCall_606589
proc url_DescribeLogPattern_607333(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeLogPattern_607332(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607334 = header.getOrDefault("X-Amz-Target")
  valid_607334 = validateParameter(valid_607334, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.DescribeLogPattern"))
  if valid_607334 != nil:
    section.add "X-Amz-Target", valid_607334
  var valid_607335 = header.getOrDefault("X-Amz-Signature")
  valid_607335 = validateParameter(valid_607335, JString, required = false,
                                 default = nil)
  if valid_607335 != nil:
    section.add "X-Amz-Signature", valid_607335
  var valid_607336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607336 = validateParameter(valid_607336, JString, required = false,
                                 default = nil)
  if valid_607336 != nil:
    section.add "X-Amz-Content-Sha256", valid_607336
  var valid_607337 = header.getOrDefault("X-Amz-Date")
  valid_607337 = validateParameter(valid_607337, JString, required = false,
                                 default = nil)
  if valid_607337 != nil:
    section.add "X-Amz-Date", valid_607337
  var valid_607338 = header.getOrDefault("X-Amz-Credential")
  valid_607338 = validateParameter(valid_607338, JString, required = false,
                                 default = nil)
  if valid_607338 != nil:
    section.add "X-Amz-Credential", valid_607338
  var valid_607339 = header.getOrDefault("X-Amz-Security-Token")
  valid_607339 = validateParameter(valid_607339, JString, required = false,
                                 default = nil)
  if valid_607339 != nil:
    section.add "X-Amz-Security-Token", valid_607339
  var valid_607340 = header.getOrDefault("X-Amz-Algorithm")
  valid_607340 = validateParameter(valid_607340, JString, required = false,
                                 default = nil)
  if valid_607340 != nil:
    section.add "X-Amz-Algorithm", valid_607340
  var valid_607341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607341 = validateParameter(valid_607341, JString, required = false,
                                 default = nil)
  if valid_607341 != nil:
    section.add "X-Amz-SignedHeaders", valid_607341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607343: Call_DescribeLogPattern_607331; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describe a specific log pattern from a <code>LogPatternSet</code>.
  ## 
  let valid = call_607343.validator(path, query, header, formData, body)
  let scheme = call_607343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607343.url(scheme.get, call_607343.host, call_607343.base,
                         call_607343.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607343, url, valid)

proc call*(call_607344: Call_DescribeLogPattern_607331; body: JsonNode): Recallable =
  ## describeLogPattern
  ## Describe a specific log pattern from a <code>LogPatternSet</code>.
  ##   body: JObject (required)
  var body_607345 = newJObject()
  if body != nil:
    body_607345 = body
  result = call_607344.call(nil, nil, nil, nil, body_607345)

var describeLogPattern* = Call_DescribeLogPattern_607331(
    name: "describeLogPattern", meth: HttpMethod.HttpPost,
    host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.DescribeLogPattern",
    validator: validate_DescribeLogPattern_607332, base: "/",
    url: url_DescribeLogPattern_607333, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeObservation_607346 = ref object of OpenApiRestCall_606589
proc url_DescribeObservation_607348(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeObservation_607347(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607349 = header.getOrDefault("X-Amz-Target")
  valid_607349 = validateParameter(valid_607349, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.DescribeObservation"))
  if valid_607349 != nil:
    section.add "X-Amz-Target", valid_607349
  var valid_607350 = header.getOrDefault("X-Amz-Signature")
  valid_607350 = validateParameter(valid_607350, JString, required = false,
                                 default = nil)
  if valid_607350 != nil:
    section.add "X-Amz-Signature", valid_607350
  var valid_607351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607351 = validateParameter(valid_607351, JString, required = false,
                                 default = nil)
  if valid_607351 != nil:
    section.add "X-Amz-Content-Sha256", valid_607351
  var valid_607352 = header.getOrDefault("X-Amz-Date")
  valid_607352 = validateParameter(valid_607352, JString, required = false,
                                 default = nil)
  if valid_607352 != nil:
    section.add "X-Amz-Date", valid_607352
  var valid_607353 = header.getOrDefault("X-Amz-Credential")
  valid_607353 = validateParameter(valid_607353, JString, required = false,
                                 default = nil)
  if valid_607353 != nil:
    section.add "X-Amz-Credential", valid_607353
  var valid_607354 = header.getOrDefault("X-Amz-Security-Token")
  valid_607354 = validateParameter(valid_607354, JString, required = false,
                                 default = nil)
  if valid_607354 != nil:
    section.add "X-Amz-Security-Token", valid_607354
  var valid_607355 = header.getOrDefault("X-Amz-Algorithm")
  valid_607355 = validateParameter(valid_607355, JString, required = false,
                                 default = nil)
  if valid_607355 != nil:
    section.add "X-Amz-Algorithm", valid_607355
  var valid_607356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607356 = validateParameter(valid_607356, JString, required = false,
                                 default = nil)
  if valid_607356 != nil:
    section.add "X-Amz-SignedHeaders", valid_607356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607358: Call_DescribeObservation_607346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an anomaly or error with the application.
  ## 
  let valid = call_607358.validator(path, query, header, formData, body)
  let scheme = call_607358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607358.url(scheme.get, call_607358.host, call_607358.base,
                         call_607358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607358, url, valid)

proc call*(call_607359: Call_DescribeObservation_607346; body: JsonNode): Recallable =
  ## describeObservation
  ## Describes an anomaly or error with the application.
  ##   body: JObject (required)
  var body_607360 = newJObject()
  if body != nil:
    body_607360 = body
  result = call_607359.call(nil, nil, nil, nil, body_607360)

var describeObservation* = Call_DescribeObservation_607346(
    name: "describeObservation", meth: HttpMethod.HttpPost,
    host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.DescribeObservation",
    validator: validate_DescribeObservation_607347, base: "/",
    url: url_DescribeObservation_607348, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProblem_607361 = ref object of OpenApiRestCall_606589
proc url_DescribeProblem_607363(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProblem_607362(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607364 = header.getOrDefault("X-Amz-Target")
  valid_607364 = validateParameter(valid_607364, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.DescribeProblem"))
  if valid_607364 != nil:
    section.add "X-Amz-Target", valid_607364
  var valid_607365 = header.getOrDefault("X-Amz-Signature")
  valid_607365 = validateParameter(valid_607365, JString, required = false,
                                 default = nil)
  if valid_607365 != nil:
    section.add "X-Amz-Signature", valid_607365
  var valid_607366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607366 = validateParameter(valid_607366, JString, required = false,
                                 default = nil)
  if valid_607366 != nil:
    section.add "X-Amz-Content-Sha256", valid_607366
  var valid_607367 = header.getOrDefault("X-Amz-Date")
  valid_607367 = validateParameter(valid_607367, JString, required = false,
                                 default = nil)
  if valid_607367 != nil:
    section.add "X-Amz-Date", valid_607367
  var valid_607368 = header.getOrDefault("X-Amz-Credential")
  valid_607368 = validateParameter(valid_607368, JString, required = false,
                                 default = nil)
  if valid_607368 != nil:
    section.add "X-Amz-Credential", valid_607368
  var valid_607369 = header.getOrDefault("X-Amz-Security-Token")
  valid_607369 = validateParameter(valid_607369, JString, required = false,
                                 default = nil)
  if valid_607369 != nil:
    section.add "X-Amz-Security-Token", valid_607369
  var valid_607370 = header.getOrDefault("X-Amz-Algorithm")
  valid_607370 = validateParameter(valid_607370, JString, required = false,
                                 default = nil)
  if valid_607370 != nil:
    section.add "X-Amz-Algorithm", valid_607370
  var valid_607371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607371 = validateParameter(valid_607371, JString, required = false,
                                 default = nil)
  if valid_607371 != nil:
    section.add "X-Amz-SignedHeaders", valid_607371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607373: Call_DescribeProblem_607361; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an application problem.
  ## 
  let valid = call_607373.validator(path, query, header, formData, body)
  let scheme = call_607373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607373.url(scheme.get, call_607373.host, call_607373.base,
                         call_607373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607373, url, valid)

proc call*(call_607374: Call_DescribeProblem_607361; body: JsonNode): Recallable =
  ## describeProblem
  ## Describes an application problem.
  ##   body: JObject (required)
  var body_607375 = newJObject()
  if body != nil:
    body_607375 = body
  result = call_607374.call(nil, nil, nil, nil, body_607375)

var describeProblem* = Call_DescribeProblem_607361(name: "describeProblem",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.DescribeProblem",
    validator: validate_DescribeProblem_607362, base: "/", url: url_DescribeProblem_607363,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProblemObservations_607376 = ref object of OpenApiRestCall_606589
proc url_DescribeProblemObservations_607378(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProblemObservations_607377(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607379 = header.getOrDefault("X-Amz-Target")
  valid_607379 = validateParameter(valid_607379, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.DescribeProblemObservations"))
  if valid_607379 != nil:
    section.add "X-Amz-Target", valid_607379
  var valid_607380 = header.getOrDefault("X-Amz-Signature")
  valid_607380 = validateParameter(valid_607380, JString, required = false,
                                 default = nil)
  if valid_607380 != nil:
    section.add "X-Amz-Signature", valid_607380
  var valid_607381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607381 = validateParameter(valid_607381, JString, required = false,
                                 default = nil)
  if valid_607381 != nil:
    section.add "X-Amz-Content-Sha256", valid_607381
  var valid_607382 = header.getOrDefault("X-Amz-Date")
  valid_607382 = validateParameter(valid_607382, JString, required = false,
                                 default = nil)
  if valid_607382 != nil:
    section.add "X-Amz-Date", valid_607382
  var valid_607383 = header.getOrDefault("X-Amz-Credential")
  valid_607383 = validateParameter(valid_607383, JString, required = false,
                                 default = nil)
  if valid_607383 != nil:
    section.add "X-Amz-Credential", valid_607383
  var valid_607384 = header.getOrDefault("X-Amz-Security-Token")
  valid_607384 = validateParameter(valid_607384, JString, required = false,
                                 default = nil)
  if valid_607384 != nil:
    section.add "X-Amz-Security-Token", valid_607384
  var valid_607385 = header.getOrDefault("X-Amz-Algorithm")
  valid_607385 = validateParameter(valid_607385, JString, required = false,
                                 default = nil)
  if valid_607385 != nil:
    section.add "X-Amz-Algorithm", valid_607385
  var valid_607386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607386 = validateParameter(valid_607386, JString, required = false,
                                 default = nil)
  if valid_607386 != nil:
    section.add "X-Amz-SignedHeaders", valid_607386
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607388: Call_DescribeProblemObservations_607376; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the anomalies or errors associated with the problem.
  ## 
  let valid = call_607388.validator(path, query, header, formData, body)
  let scheme = call_607388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607388.url(scheme.get, call_607388.host, call_607388.base,
                         call_607388.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607388, url, valid)

proc call*(call_607389: Call_DescribeProblemObservations_607376; body: JsonNode): Recallable =
  ## describeProblemObservations
  ## Describes the anomalies or errors associated with the problem.
  ##   body: JObject (required)
  var body_607390 = newJObject()
  if body != nil:
    body_607390 = body
  result = call_607389.call(nil, nil, nil, nil, body_607390)

var describeProblemObservations* = Call_DescribeProblemObservations_607376(
    name: "describeProblemObservations", meth: HttpMethod.HttpPost,
    host: "applicationinsights.amazonaws.com", route: "/#X-Amz-Target=EC2WindowsBarleyService.DescribeProblemObservations",
    validator: validate_DescribeProblemObservations_607377, base: "/",
    url: url_DescribeProblemObservations_607378,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApplications_607391 = ref object of OpenApiRestCall_606589
proc url_ListApplications_607393(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListApplications_607392(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Lists the IDs of the applications that you are monitoring. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_607394 = query.getOrDefault("MaxResults")
  valid_607394 = validateParameter(valid_607394, JString, required = false,
                                 default = nil)
  if valid_607394 != nil:
    section.add "MaxResults", valid_607394
  var valid_607395 = query.getOrDefault("NextToken")
  valid_607395 = validateParameter(valid_607395, JString, required = false,
                                 default = nil)
  if valid_607395 != nil:
    section.add "NextToken", valid_607395
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607396 = header.getOrDefault("X-Amz-Target")
  valid_607396 = validateParameter(valid_607396, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.ListApplications"))
  if valid_607396 != nil:
    section.add "X-Amz-Target", valid_607396
  var valid_607397 = header.getOrDefault("X-Amz-Signature")
  valid_607397 = validateParameter(valid_607397, JString, required = false,
                                 default = nil)
  if valid_607397 != nil:
    section.add "X-Amz-Signature", valid_607397
  var valid_607398 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607398 = validateParameter(valid_607398, JString, required = false,
                                 default = nil)
  if valid_607398 != nil:
    section.add "X-Amz-Content-Sha256", valid_607398
  var valid_607399 = header.getOrDefault("X-Amz-Date")
  valid_607399 = validateParameter(valid_607399, JString, required = false,
                                 default = nil)
  if valid_607399 != nil:
    section.add "X-Amz-Date", valid_607399
  var valid_607400 = header.getOrDefault("X-Amz-Credential")
  valid_607400 = validateParameter(valid_607400, JString, required = false,
                                 default = nil)
  if valid_607400 != nil:
    section.add "X-Amz-Credential", valid_607400
  var valid_607401 = header.getOrDefault("X-Amz-Security-Token")
  valid_607401 = validateParameter(valid_607401, JString, required = false,
                                 default = nil)
  if valid_607401 != nil:
    section.add "X-Amz-Security-Token", valid_607401
  var valid_607402 = header.getOrDefault("X-Amz-Algorithm")
  valid_607402 = validateParameter(valid_607402, JString, required = false,
                                 default = nil)
  if valid_607402 != nil:
    section.add "X-Amz-Algorithm", valid_607402
  var valid_607403 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607403 = validateParameter(valid_607403, JString, required = false,
                                 default = nil)
  if valid_607403 != nil:
    section.add "X-Amz-SignedHeaders", valid_607403
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607405: Call_ListApplications_607391; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the IDs of the applications that you are monitoring. 
  ## 
  let valid = call_607405.validator(path, query, header, formData, body)
  let scheme = call_607405.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607405.url(scheme.get, call_607405.host, call_607405.base,
                         call_607405.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607405, url, valid)

proc call*(call_607406: Call_ListApplications_607391; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listApplications
  ## Lists the IDs of the applications that you are monitoring. 
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607407 = newJObject()
  var body_607408 = newJObject()
  add(query_607407, "MaxResults", newJString(MaxResults))
  add(query_607407, "NextToken", newJString(NextToken))
  if body != nil:
    body_607408 = body
  result = call_607406.call(nil, query_607407, nil, nil, body_607408)

var listApplications* = Call_ListApplications_607391(name: "listApplications",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.ListApplications",
    validator: validate_ListApplications_607392, base: "/",
    url: url_ListApplications_607393, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListComponents_607410 = ref object of OpenApiRestCall_606589
proc url_ListComponents_607412(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListComponents_607411(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Lists the auto-grouped, standalone, and custom components of the application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_607413 = query.getOrDefault("MaxResults")
  valid_607413 = validateParameter(valid_607413, JString, required = false,
                                 default = nil)
  if valid_607413 != nil:
    section.add "MaxResults", valid_607413
  var valid_607414 = query.getOrDefault("NextToken")
  valid_607414 = validateParameter(valid_607414, JString, required = false,
                                 default = nil)
  if valid_607414 != nil:
    section.add "NextToken", valid_607414
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607415 = header.getOrDefault("X-Amz-Target")
  valid_607415 = validateParameter(valid_607415, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.ListComponents"))
  if valid_607415 != nil:
    section.add "X-Amz-Target", valid_607415
  var valid_607416 = header.getOrDefault("X-Amz-Signature")
  valid_607416 = validateParameter(valid_607416, JString, required = false,
                                 default = nil)
  if valid_607416 != nil:
    section.add "X-Amz-Signature", valid_607416
  var valid_607417 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607417 = validateParameter(valid_607417, JString, required = false,
                                 default = nil)
  if valid_607417 != nil:
    section.add "X-Amz-Content-Sha256", valid_607417
  var valid_607418 = header.getOrDefault("X-Amz-Date")
  valid_607418 = validateParameter(valid_607418, JString, required = false,
                                 default = nil)
  if valid_607418 != nil:
    section.add "X-Amz-Date", valid_607418
  var valid_607419 = header.getOrDefault("X-Amz-Credential")
  valid_607419 = validateParameter(valid_607419, JString, required = false,
                                 default = nil)
  if valid_607419 != nil:
    section.add "X-Amz-Credential", valid_607419
  var valid_607420 = header.getOrDefault("X-Amz-Security-Token")
  valid_607420 = validateParameter(valid_607420, JString, required = false,
                                 default = nil)
  if valid_607420 != nil:
    section.add "X-Amz-Security-Token", valid_607420
  var valid_607421 = header.getOrDefault("X-Amz-Algorithm")
  valid_607421 = validateParameter(valid_607421, JString, required = false,
                                 default = nil)
  if valid_607421 != nil:
    section.add "X-Amz-Algorithm", valid_607421
  var valid_607422 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607422 = validateParameter(valid_607422, JString, required = false,
                                 default = nil)
  if valid_607422 != nil:
    section.add "X-Amz-SignedHeaders", valid_607422
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607424: Call_ListComponents_607410; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the auto-grouped, standalone, and custom components of the application.
  ## 
  let valid = call_607424.validator(path, query, header, formData, body)
  let scheme = call_607424.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607424.url(scheme.get, call_607424.host, call_607424.base,
                         call_607424.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607424, url, valid)

proc call*(call_607425: Call_ListComponents_607410; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listComponents
  ## Lists the auto-grouped, standalone, and custom components of the application.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607426 = newJObject()
  var body_607427 = newJObject()
  add(query_607426, "MaxResults", newJString(MaxResults))
  add(query_607426, "NextToken", newJString(NextToken))
  if body != nil:
    body_607427 = body
  result = call_607425.call(nil, query_607426, nil, nil, body_607427)

var listComponents* = Call_ListComponents_607410(name: "listComponents",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.ListComponents",
    validator: validate_ListComponents_607411, base: "/", url: url_ListComponents_607412,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurationHistory_607428 = ref object of OpenApiRestCall_606589
proc url_ListConfigurationHistory_607430(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListConfigurationHistory_607429(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Lists the INFO, WARN, and ERROR events for periodic configuration updates performed by Application Insights. Examples of events represented are: </p> <ul> <li> <p>INFO: creating a new alarm or updating an alarm threshold.</p> </li> <li> <p>WARN: alarm not created due to insufficient data points used to predict thresholds.</p> </li> <li> <p>ERROR: alarm not created due to permission errors or exceeding quotas. </p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_607431 = query.getOrDefault("MaxResults")
  valid_607431 = validateParameter(valid_607431, JString, required = false,
                                 default = nil)
  if valid_607431 != nil:
    section.add "MaxResults", valid_607431
  var valid_607432 = query.getOrDefault("NextToken")
  valid_607432 = validateParameter(valid_607432, JString, required = false,
                                 default = nil)
  if valid_607432 != nil:
    section.add "NextToken", valid_607432
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607433 = header.getOrDefault("X-Amz-Target")
  valid_607433 = validateParameter(valid_607433, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.ListConfigurationHistory"))
  if valid_607433 != nil:
    section.add "X-Amz-Target", valid_607433
  var valid_607434 = header.getOrDefault("X-Amz-Signature")
  valid_607434 = validateParameter(valid_607434, JString, required = false,
                                 default = nil)
  if valid_607434 != nil:
    section.add "X-Amz-Signature", valid_607434
  var valid_607435 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607435 = validateParameter(valid_607435, JString, required = false,
                                 default = nil)
  if valid_607435 != nil:
    section.add "X-Amz-Content-Sha256", valid_607435
  var valid_607436 = header.getOrDefault("X-Amz-Date")
  valid_607436 = validateParameter(valid_607436, JString, required = false,
                                 default = nil)
  if valid_607436 != nil:
    section.add "X-Amz-Date", valid_607436
  var valid_607437 = header.getOrDefault("X-Amz-Credential")
  valid_607437 = validateParameter(valid_607437, JString, required = false,
                                 default = nil)
  if valid_607437 != nil:
    section.add "X-Amz-Credential", valid_607437
  var valid_607438 = header.getOrDefault("X-Amz-Security-Token")
  valid_607438 = validateParameter(valid_607438, JString, required = false,
                                 default = nil)
  if valid_607438 != nil:
    section.add "X-Amz-Security-Token", valid_607438
  var valid_607439 = header.getOrDefault("X-Amz-Algorithm")
  valid_607439 = validateParameter(valid_607439, JString, required = false,
                                 default = nil)
  if valid_607439 != nil:
    section.add "X-Amz-Algorithm", valid_607439
  var valid_607440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607440 = validateParameter(valid_607440, JString, required = false,
                                 default = nil)
  if valid_607440 != nil:
    section.add "X-Amz-SignedHeaders", valid_607440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607442: Call_ListConfigurationHistory_607428; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Lists the INFO, WARN, and ERROR events for periodic configuration updates performed by Application Insights. Examples of events represented are: </p> <ul> <li> <p>INFO: creating a new alarm or updating an alarm threshold.</p> </li> <li> <p>WARN: alarm not created due to insufficient data points used to predict thresholds.</p> </li> <li> <p>ERROR: alarm not created due to permission errors or exceeding quotas. </p> </li> </ul>
  ## 
  let valid = call_607442.validator(path, query, header, formData, body)
  let scheme = call_607442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607442.url(scheme.get, call_607442.host, call_607442.base,
                         call_607442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607442, url, valid)

proc call*(call_607443: Call_ListConfigurationHistory_607428; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listConfigurationHistory
  ## <p> Lists the INFO, WARN, and ERROR events for periodic configuration updates performed by Application Insights. Examples of events represented are: </p> <ul> <li> <p>INFO: creating a new alarm or updating an alarm threshold.</p> </li> <li> <p>WARN: alarm not created due to insufficient data points used to predict thresholds.</p> </li> <li> <p>ERROR: alarm not created due to permission errors or exceeding quotas. </p> </li> </ul>
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607444 = newJObject()
  var body_607445 = newJObject()
  add(query_607444, "MaxResults", newJString(MaxResults))
  add(query_607444, "NextToken", newJString(NextToken))
  if body != nil:
    body_607445 = body
  result = call_607443.call(nil, query_607444, nil, nil, body_607445)

var listConfigurationHistory* = Call_ListConfigurationHistory_607428(
    name: "listConfigurationHistory", meth: HttpMethod.HttpPost,
    host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.ListConfigurationHistory",
    validator: validate_ListConfigurationHistory_607429, base: "/",
    url: url_ListConfigurationHistory_607430, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLogPatternSets_607446 = ref object of OpenApiRestCall_606589
proc url_ListLogPatternSets_607448(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListLogPatternSets_607447(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Lists the log pattern sets in the specific application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_607449 = query.getOrDefault("MaxResults")
  valid_607449 = validateParameter(valid_607449, JString, required = false,
                                 default = nil)
  if valid_607449 != nil:
    section.add "MaxResults", valid_607449
  var valid_607450 = query.getOrDefault("NextToken")
  valid_607450 = validateParameter(valid_607450, JString, required = false,
                                 default = nil)
  if valid_607450 != nil:
    section.add "NextToken", valid_607450
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607451 = header.getOrDefault("X-Amz-Target")
  valid_607451 = validateParameter(valid_607451, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.ListLogPatternSets"))
  if valid_607451 != nil:
    section.add "X-Amz-Target", valid_607451
  var valid_607452 = header.getOrDefault("X-Amz-Signature")
  valid_607452 = validateParameter(valid_607452, JString, required = false,
                                 default = nil)
  if valid_607452 != nil:
    section.add "X-Amz-Signature", valid_607452
  var valid_607453 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607453 = validateParameter(valid_607453, JString, required = false,
                                 default = nil)
  if valid_607453 != nil:
    section.add "X-Amz-Content-Sha256", valid_607453
  var valid_607454 = header.getOrDefault("X-Amz-Date")
  valid_607454 = validateParameter(valid_607454, JString, required = false,
                                 default = nil)
  if valid_607454 != nil:
    section.add "X-Amz-Date", valid_607454
  var valid_607455 = header.getOrDefault("X-Amz-Credential")
  valid_607455 = validateParameter(valid_607455, JString, required = false,
                                 default = nil)
  if valid_607455 != nil:
    section.add "X-Amz-Credential", valid_607455
  var valid_607456 = header.getOrDefault("X-Amz-Security-Token")
  valid_607456 = validateParameter(valid_607456, JString, required = false,
                                 default = nil)
  if valid_607456 != nil:
    section.add "X-Amz-Security-Token", valid_607456
  var valid_607457 = header.getOrDefault("X-Amz-Algorithm")
  valid_607457 = validateParameter(valid_607457, JString, required = false,
                                 default = nil)
  if valid_607457 != nil:
    section.add "X-Amz-Algorithm", valid_607457
  var valid_607458 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607458 = validateParameter(valid_607458, JString, required = false,
                                 default = nil)
  if valid_607458 != nil:
    section.add "X-Amz-SignedHeaders", valid_607458
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607460: Call_ListLogPatternSets_607446; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the log pattern sets in the specific application.
  ## 
  let valid = call_607460.validator(path, query, header, formData, body)
  let scheme = call_607460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607460.url(scheme.get, call_607460.host, call_607460.base,
                         call_607460.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607460, url, valid)

proc call*(call_607461: Call_ListLogPatternSets_607446; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listLogPatternSets
  ## Lists the log pattern sets in the specific application.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607462 = newJObject()
  var body_607463 = newJObject()
  add(query_607462, "MaxResults", newJString(MaxResults))
  add(query_607462, "NextToken", newJString(NextToken))
  if body != nil:
    body_607463 = body
  result = call_607461.call(nil, query_607462, nil, nil, body_607463)

var listLogPatternSets* = Call_ListLogPatternSets_607446(
    name: "listLogPatternSets", meth: HttpMethod.HttpPost,
    host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.ListLogPatternSets",
    validator: validate_ListLogPatternSets_607447, base: "/",
    url: url_ListLogPatternSets_607448, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLogPatterns_607464 = ref object of OpenApiRestCall_606589
proc url_ListLogPatterns_607466(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListLogPatterns_607465(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Lists the log patterns in the specific log <code>LogPatternSet</code>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_607467 = query.getOrDefault("MaxResults")
  valid_607467 = validateParameter(valid_607467, JString, required = false,
                                 default = nil)
  if valid_607467 != nil:
    section.add "MaxResults", valid_607467
  var valid_607468 = query.getOrDefault("NextToken")
  valid_607468 = validateParameter(valid_607468, JString, required = false,
                                 default = nil)
  if valid_607468 != nil:
    section.add "NextToken", valid_607468
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607469 = header.getOrDefault("X-Amz-Target")
  valid_607469 = validateParameter(valid_607469, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.ListLogPatterns"))
  if valid_607469 != nil:
    section.add "X-Amz-Target", valid_607469
  var valid_607470 = header.getOrDefault("X-Amz-Signature")
  valid_607470 = validateParameter(valid_607470, JString, required = false,
                                 default = nil)
  if valid_607470 != nil:
    section.add "X-Amz-Signature", valid_607470
  var valid_607471 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607471 = validateParameter(valid_607471, JString, required = false,
                                 default = nil)
  if valid_607471 != nil:
    section.add "X-Amz-Content-Sha256", valid_607471
  var valid_607472 = header.getOrDefault("X-Amz-Date")
  valid_607472 = validateParameter(valid_607472, JString, required = false,
                                 default = nil)
  if valid_607472 != nil:
    section.add "X-Amz-Date", valid_607472
  var valid_607473 = header.getOrDefault("X-Amz-Credential")
  valid_607473 = validateParameter(valid_607473, JString, required = false,
                                 default = nil)
  if valid_607473 != nil:
    section.add "X-Amz-Credential", valid_607473
  var valid_607474 = header.getOrDefault("X-Amz-Security-Token")
  valid_607474 = validateParameter(valid_607474, JString, required = false,
                                 default = nil)
  if valid_607474 != nil:
    section.add "X-Amz-Security-Token", valid_607474
  var valid_607475 = header.getOrDefault("X-Amz-Algorithm")
  valid_607475 = validateParameter(valid_607475, JString, required = false,
                                 default = nil)
  if valid_607475 != nil:
    section.add "X-Amz-Algorithm", valid_607475
  var valid_607476 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607476 = validateParameter(valid_607476, JString, required = false,
                                 default = nil)
  if valid_607476 != nil:
    section.add "X-Amz-SignedHeaders", valid_607476
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607478: Call_ListLogPatterns_607464; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the log patterns in the specific log <code>LogPatternSet</code>.
  ## 
  let valid = call_607478.validator(path, query, header, formData, body)
  let scheme = call_607478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607478.url(scheme.get, call_607478.host, call_607478.base,
                         call_607478.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607478, url, valid)

proc call*(call_607479: Call_ListLogPatterns_607464; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listLogPatterns
  ## Lists the log patterns in the specific log <code>LogPatternSet</code>.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607480 = newJObject()
  var body_607481 = newJObject()
  add(query_607480, "MaxResults", newJString(MaxResults))
  add(query_607480, "NextToken", newJString(NextToken))
  if body != nil:
    body_607481 = body
  result = call_607479.call(nil, query_607480, nil, nil, body_607481)

var listLogPatterns* = Call_ListLogPatterns_607464(name: "listLogPatterns",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.ListLogPatterns",
    validator: validate_ListLogPatterns_607465, base: "/", url: url_ListLogPatterns_607466,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProblems_607482 = ref object of OpenApiRestCall_606589
proc url_ListProblems_607484(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListProblems_607483(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the problems with your application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_607485 = query.getOrDefault("MaxResults")
  valid_607485 = validateParameter(valid_607485, JString, required = false,
                                 default = nil)
  if valid_607485 != nil:
    section.add "MaxResults", valid_607485
  var valid_607486 = query.getOrDefault("NextToken")
  valid_607486 = validateParameter(valid_607486, JString, required = false,
                                 default = nil)
  if valid_607486 != nil:
    section.add "NextToken", valid_607486
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607487 = header.getOrDefault("X-Amz-Target")
  valid_607487 = validateParameter(valid_607487, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.ListProblems"))
  if valid_607487 != nil:
    section.add "X-Amz-Target", valid_607487
  var valid_607488 = header.getOrDefault("X-Amz-Signature")
  valid_607488 = validateParameter(valid_607488, JString, required = false,
                                 default = nil)
  if valid_607488 != nil:
    section.add "X-Amz-Signature", valid_607488
  var valid_607489 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607489 = validateParameter(valid_607489, JString, required = false,
                                 default = nil)
  if valid_607489 != nil:
    section.add "X-Amz-Content-Sha256", valid_607489
  var valid_607490 = header.getOrDefault("X-Amz-Date")
  valid_607490 = validateParameter(valid_607490, JString, required = false,
                                 default = nil)
  if valid_607490 != nil:
    section.add "X-Amz-Date", valid_607490
  var valid_607491 = header.getOrDefault("X-Amz-Credential")
  valid_607491 = validateParameter(valid_607491, JString, required = false,
                                 default = nil)
  if valid_607491 != nil:
    section.add "X-Amz-Credential", valid_607491
  var valid_607492 = header.getOrDefault("X-Amz-Security-Token")
  valid_607492 = validateParameter(valid_607492, JString, required = false,
                                 default = nil)
  if valid_607492 != nil:
    section.add "X-Amz-Security-Token", valid_607492
  var valid_607493 = header.getOrDefault("X-Amz-Algorithm")
  valid_607493 = validateParameter(valid_607493, JString, required = false,
                                 default = nil)
  if valid_607493 != nil:
    section.add "X-Amz-Algorithm", valid_607493
  var valid_607494 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607494 = validateParameter(valid_607494, JString, required = false,
                                 default = nil)
  if valid_607494 != nil:
    section.add "X-Amz-SignedHeaders", valid_607494
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607496: Call_ListProblems_607482; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the problems with your application.
  ## 
  let valid = call_607496.validator(path, query, header, formData, body)
  let scheme = call_607496.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607496.url(scheme.get, call_607496.host, call_607496.base,
                         call_607496.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607496, url, valid)

proc call*(call_607497: Call_ListProblems_607482; body: JsonNode;
          MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listProblems
  ## Lists the problems with your application.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_607498 = newJObject()
  var body_607499 = newJObject()
  add(query_607498, "MaxResults", newJString(MaxResults))
  add(query_607498, "NextToken", newJString(NextToken))
  if body != nil:
    body_607499 = body
  result = call_607497.call(nil, query_607498, nil, nil, body_607499)

var listProblems* = Call_ListProblems_607482(name: "listProblems",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.ListProblems",
    validator: validate_ListProblems_607483, base: "/", url: url_ListProblems_607484,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_607500 = ref object of OpenApiRestCall_606589
proc url_ListTagsForResource_607502(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_607501(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607503 = header.getOrDefault("X-Amz-Target")
  valid_607503 = validateParameter(valid_607503, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.ListTagsForResource"))
  if valid_607503 != nil:
    section.add "X-Amz-Target", valid_607503
  var valid_607504 = header.getOrDefault("X-Amz-Signature")
  valid_607504 = validateParameter(valid_607504, JString, required = false,
                                 default = nil)
  if valid_607504 != nil:
    section.add "X-Amz-Signature", valid_607504
  var valid_607505 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607505 = validateParameter(valid_607505, JString, required = false,
                                 default = nil)
  if valid_607505 != nil:
    section.add "X-Amz-Content-Sha256", valid_607505
  var valid_607506 = header.getOrDefault("X-Amz-Date")
  valid_607506 = validateParameter(valid_607506, JString, required = false,
                                 default = nil)
  if valid_607506 != nil:
    section.add "X-Amz-Date", valid_607506
  var valid_607507 = header.getOrDefault("X-Amz-Credential")
  valid_607507 = validateParameter(valid_607507, JString, required = false,
                                 default = nil)
  if valid_607507 != nil:
    section.add "X-Amz-Credential", valid_607507
  var valid_607508 = header.getOrDefault("X-Amz-Security-Token")
  valid_607508 = validateParameter(valid_607508, JString, required = false,
                                 default = nil)
  if valid_607508 != nil:
    section.add "X-Amz-Security-Token", valid_607508
  var valid_607509 = header.getOrDefault("X-Amz-Algorithm")
  valid_607509 = validateParameter(valid_607509, JString, required = false,
                                 default = nil)
  if valid_607509 != nil:
    section.add "X-Amz-Algorithm", valid_607509
  var valid_607510 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607510 = validateParameter(valid_607510, JString, required = false,
                                 default = nil)
  if valid_607510 != nil:
    section.add "X-Amz-SignedHeaders", valid_607510
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607512: Call_ListTagsForResource_607500; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a list of the tags (keys and values) that are associated with a specified application. A <i>tag</i> is a label that you optionally define and associate with an application. Each tag consists of a required <i>tag key</i> and an optional associated <i>tag value</i>. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.
  ## 
  let valid = call_607512.validator(path, query, header, formData, body)
  let scheme = call_607512.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607512.url(scheme.get, call_607512.host, call_607512.base,
                         call_607512.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607512, url, valid)

proc call*(call_607513: Call_ListTagsForResource_607500; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Retrieve a list of the tags (keys and values) that are associated with a specified application. A <i>tag</i> is a label that you optionally define and associate with an application. Each tag consists of a required <i>tag key</i> and an optional associated <i>tag value</i>. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.
  ##   body: JObject (required)
  var body_607514 = newJObject()
  if body != nil:
    body_607514 = body
  result = call_607513.call(nil, nil, nil, nil, body_607514)

var listTagsForResource* = Call_ListTagsForResource_607500(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.ListTagsForResource",
    validator: validate_ListTagsForResource_607501, base: "/",
    url: url_ListTagsForResource_607502, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_607515 = ref object of OpenApiRestCall_606589
proc url_TagResource_607517(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_607516(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607518 = header.getOrDefault("X-Amz-Target")
  valid_607518 = validateParameter(valid_607518, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.TagResource"))
  if valid_607518 != nil:
    section.add "X-Amz-Target", valid_607518
  var valid_607519 = header.getOrDefault("X-Amz-Signature")
  valid_607519 = validateParameter(valid_607519, JString, required = false,
                                 default = nil)
  if valid_607519 != nil:
    section.add "X-Amz-Signature", valid_607519
  var valid_607520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607520 = validateParameter(valid_607520, JString, required = false,
                                 default = nil)
  if valid_607520 != nil:
    section.add "X-Amz-Content-Sha256", valid_607520
  var valid_607521 = header.getOrDefault("X-Amz-Date")
  valid_607521 = validateParameter(valid_607521, JString, required = false,
                                 default = nil)
  if valid_607521 != nil:
    section.add "X-Amz-Date", valid_607521
  var valid_607522 = header.getOrDefault("X-Amz-Credential")
  valid_607522 = validateParameter(valid_607522, JString, required = false,
                                 default = nil)
  if valid_607522 != nil:
    section.add "X-Amz-Credential", valid_607522
  var valid_607523 = header.getOrDefault("X-Amz-Security-Token")
  valid_607523 = validateParameter(valid_607523, JString, required = false,
                                 default = nil)
  if valid_607523 != nil:
    section.add "X-Amz-Security-Token", valid_607523
  var valid_607524 = header.getOrDefault("X-Amz-Algorithm")
  valid_607524 = validateParameter(valid_607524, JString, required = false,
                                 default = nil)
  if valid_607524 != nil:
    section.add "X-Amz-Algorithm", valid_607524
  var valid_607525 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607525 = validateParameter(valid_607525, JString, required = false,
                                 default = nil)
  if valid_607525 != nil:
    section.add "X-Amz-SignedHeaders", valid_607525
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607527: Call_TagResource_607515; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Add one or more tags (keys and values) to a specified application. A <i>tag</i> is a label that you optionally define and associate with an application. Tags can help you categorize and manage application in different ways, such as by purpose, owner, environment, or other criteria. </p> <p>Each tag consists of a required <i>tag key</i> and an associated <i>tag value</i>, both of which you define. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.</p>
  ## 
  let valid = call_607527.validator(path, query, header, formData, body)
  let scheme = call_607527.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607527.url(scheme.get, call_607527.host, call_607527.base,
                         call_607527.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607527, url, valid)

proc call*(call_607528: Call_TagResource_607515; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Add one or more tags (keys and values) to a specified application. A <i>tag</i> is a label that you optionally define and associate with an application. Tags can help you categorize and manage application in different ways, such as by purpose, owner, environment, or other criteria. </p> <p>Each tag consists of a required <i>tag key</i> and an associated <i>tag value</i>, both of which you define. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.</p>
  ##   body: JObject (required)
  var body_607529 = newJObject()
  if body != nil:
    body_607529 = body
  result = call_607528.call(nil, nil, nil, nil, body_607529)

var tagResource* = Call_TagResource_607515(name: "tagResource",
                                        meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com", route: "/#X-Amz-Target=EC2WindowsBarleyService.TagResource",
                                        validator: validate_TagResource_607516,
                                        base: "/", url: url_TagResource_607517,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_607530 = ref object of OpenApiRestCall_606589
proc url_UntagResource_607532(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_607531(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607533 = header.getOrDefault("X-Amz-Target")
  valid_607533 = validateParameter(valid_607533, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.UntagResource"))
  if valid_607533 != nil:
    section.add "X-Amz-Target", valid_607533
  var valid_607534 = header.getOrDefault("X-Amz-Signature")
  valid_607534 = validateParameter(valid_607534, JString, required = false,
                                 default = nil)
  if valid_607534 != nil:
    section.add "X-Amz-Signature", valid_607534
  var valid_607535 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607535 = validateParameter(valid_607535, JString, required = false,
                                 default = nil)
  if valid_607535 != nil:
    section.add "X-Amz-Content-Sha256", valid_607535
  var valid_607536 = header.getOrDefault("X-Amz-Date")
  valid_607536 = validateParameter(valid_607536, JString, required = false,
                                 default = nil)
  if valid_607536 != nil:
    section.add "X-Amz-Date", valid_607536
  var valid_607537 = header.getOrDefault("X-Amz-Credential")
  valid_607537 = validateParameter(valid_607537, JString, required = false,
                                 default = nil)
  if valid_607537 != nil:
    section.add "X-Amz-Credential", valid_607537
  var valid_607538 = header.getOrDefault("X-Amz-Security-Token")
  valid_607538 = validateParameter(valid_607538, JString, required = false,
                                 default = nil)
  if valid_607538 != nil:
    section.add "X-Amz-Security-Token", valid_607538
  var valid_607539 = header.getOrDefault("X-Amz-Algorithm")
  valid_607539 = validateParameter(valid_607539, JString, required = false,
                                 default = nil)
  if valid_607539 != nil:
    section.add "X-Amz-Algorithm", valid_607539
  var valid_607540 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607540 = validateParameter(valid_607540, JString, required = false,
                                 default = nil)
  if valid_607540 != nil:
    section.add "X-Amz-SignedHeaders", valid_607540
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607542: Call_UntagResource_607530; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove one or more tags (keys and values) from a specified application.
  ## 
  let valid = call_607542.validator(path, query, header, formData, body)
  let scheme = call_607542.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607542.url(scheme.get, call_607542.host, call_607542.base,
                         call_607542.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607542, url, valid)

proc call*(call_607543: Call_UntagResource_607530; body: JsonNode): Recallable =
  ## untagResource
  ## Remove one or more tags (keys and values) from a specified application.
  ##   body: JObject (required)
  var body_607544 = newJObject()
  if body != nil:
    body_607544 = body
  result = call_607543.call(nil, nil, nil, nil, body_607544)

var untagResource* = Call_UntagResource_607530(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.UntagResource",
    validator: validate_UntagResource_607531, base: "/", url: url_UntagResource_607532,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApplication_607545 = ref object of OpenApiRestCall_606589
proc url_UpdateApplication_607547(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateApplication_607546(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607548 = header.getOrDefault("X-Amz-Target")
  valid_607548 = validateParameter(valid_607548, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.UpdateApplication"))
  if valid_607548 != nil:
    section.add "X-Amz-Target", valid_607548
  var valid_607549 = header.getOrDefault("X-Amz-Signature")
  valid_607549 = validateParameter(valid_607549, JString, required = false,
                                 default = nil)
  if valid_607549 != nil:
    section.add "X-Amz-Signature", valid_607549
  var valid_607550 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607550 = validateParameter(valid_607550, JString, required = false,
                                 default = nil)
  if valid_607550 != nil:
    section.add "X-Amz-Content-Sha256", valid_607550
  var valid_607551 = header.getOrDefault("X-Amz-Date")
  valid_607551 = validateParameter(valid_607551, JString, required = false,
                                 default = nil)
  if valid_607551 != nil:
    section.add "X-Amz-Date", valid_607551
  var valid_607552 = header.getOrDefault("X-Amz-Credential")
  valid_607552 = validateParameter(valid_607552, JString, required = false,
                                 default = nil)
  if valid_607552 != nil:
    section.add "X-Amz-Credential", valid_607552
  var valid_607553 = header.getOrDefault("X-Amz-Security-Token")
  valid_607553 = validateParameter(valid_607553, JString, required = false,
                                 default = nil)
  if valid_607553 != nil:
    section.add "X-Amz-Security-Token", valid_607553
  var valid_607554 = header.getOrDefault("X-Amz-Algorithm")
  valid_607554 = validateParameter(valid_607554, JString, required = false,
                                 default = nil)
  if valid_607554 != nil:
    section.add "X-Amz-Algorithm", valid_607554
  var valid_607555 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607555 = validateParameter(valid_607555, JString, required = false,
                                 default = nil)
  if valid_607555 != nil:
    section.add "X-Amz-SignedHeaders", valid_607555
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607557: Call_UpdateApplication_607545; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the application.
  ## 
  let valid = call_607557.validator(path, query, header, formData, body)
  let scheme = call_607557.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607557.url(scheme.get, call_607557.host, call_607557.base,
                         call_607557.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607557, url, valid)

proc call*(call_607558: Call_UpdateApplication_607545; body: JsonNode): Recallable =
  ## updateApplication
  ## Updates the application.
  ##   body: JObject (required)
  var body_607559 = newJObject()
  if body != nil:
    body_607559 = body
  result = call_607558.call(nil, nil, nil, nil, body_607559)

var updateApplication* = Call_UpdateApplication_607545(name: "updateApplication",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.UpdateApplication",
    validator: validate_UpdateApplication_607546, base: "/",
    url: url_UpdateApplication_607547, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateComponent_607560 = ref object of OpenApiRestCall_606589
proc url_UpdateComponent_607562(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateComponent_607561(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607563 = header.getOrDefault("X-Amz-Target")
  valid_607563 = validateParameter(valid_607563, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.UpdateComponent"))
  if valid_607563 != nil:
    section.add "X-Amz-Target", valid_607563
  var valid_607564 = header.getOrDefault("X-Amz-Signature")
  valid_607564 = validateParameter(valid_607564, JString, required = false,
                                 default = nil)
  if valid_607564 != nil:
    section.add "X-Amz-Signature", valid_607564
  var valid_607565 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607565 = validateParameter(valid_607565, JString, required = false,
                                 default = nil)
  if valid_607565 != nil:
    section.add "X-Amz-Content-Sha256", valid_607565
  var valid_607566 = header.getOrDefault("X-Amz-Date")
  valid_607566 = validateParameter(valid_607566, JString, required = false,
                                 default = nil)
  if valid_607566 != nil:
    section.add "X-Amz-Date", valid_607566
  var valid_607567 = header.getOrDefault("X-Amz-Credential")
  valid_607567 = validateParameter(valid_607567, JString, required = false,
                                 default = nil)
  if valid_607567 != nil:
    section.add "X-Amz-Credential", valid_607567
  var valid_607568 = header.getOrDefault("X-Amz-Security-Token")
  valid_607568 = validateParameter(valid_607568, JString, required = false,
                                 default = nil)
  if valid_607568 != nil:
    section.add "X-Amz-Security-Token", valid_607568
  var valid_607569 = header.getOrDefault("X-Amz-Algorithm")
  valid_607569 = validateParameter(valid_607569, JString, required = false,
                                 default = nil)
  if valid_607569 != nil:
    section.add "X-Amz-Algorithm", valid_607569
  var valid_607570 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607570 = validateParameter(valid_607570, JString, required = false,
                                 default = nil)
  if valid_607570 != nil:
    section.add "X-Amz-SignedHeaders", valid_607570
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607572: Call_UpdateComponent_607560; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the custom component name and/or the list of resources that make up the component.
  ## 
  let valid = call_607572.validator(path, query, header, formData, body)
  let scheme = call_607572.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607572.url(scheme.get, call_607572.host, call_607572.base,
                         call_607572.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607572, url, valid)

proc call*(call_607573: Call_UpdateComponent_607560; body: JsonNode): Recallable =
  ## updateComponent
  ## Updates the custom component name and/or the list of resources that make up the component.
  ##   body: JObject (required)
  var body_607574 = newJObject()
  if body != nil:
    body_607574 = body
  result = call_607573.call(nil, nil, nil, nil, body_607574)

var updateComponent* = Call_UpdateComponent_607560(name: "updateComponent",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.UpdateComponent",
    validator: validate_UpdateComponent_607561, base: "/", url: url_UpdateComponent_607562,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateComponentConfiguration_607575 = ref object of OpenApiRestCall_606589
proc url_UpdateComponentConfiguration_607577(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateComponentConfiguration_607576(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607578 = header.getOrDefault("X-Amz-Target")
  valid_607578 = validateParameter(valid_607578, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.UpdateComponentConfiguration"))
  if valid_607578 != nil:
    section.add "X-Amz-Target", valid_607578
  var valid_607579 = header.getOrDefault("X-Amz-Signature")
  valid_607579 = validateParameter(valid_607579, JString, required = false,
                                 default = nil)
  if valid_607579 != nil:
    section.add "X-Amz-Signature", valid_607579
  var valid_607580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607580 = validateParameter(valid_607580, JString, required = false,
                                 default = nil)
  if valid_607580 != nil:
    section.add "X-Amz-Content-Sha256", valid_607580
  var valid_607581 = header.getOrDefault("X-Amz-Date")
  valid_607581 = validateParameter(valid_607581, JString, required = false,
                                 default = nil)
  if valid_607581 != nil:
    section.add "X-Amz-Date", valid_607581
  var valid_607582 = header.getOrDefault("X-Amz-Credential")
  valid_607582 = validateParameter(valid_607582, JString, required = false,
                                 default = nil)
  if valid_607582 != nil:
    section.add "X-Amz-Credential", valid_607582
  var valid_607583 = header.getOrDefault("X-Amz-Security-Token")
  valid_607583 = validateParameter(valid_607583, JString, required = false,
                                 default = nil)
  if valid_607583 != nil:
    section.add "X-Amz-Security-Token", valid_607583
  var valid_607584 = header.getOrDefault("X-Amz-Algorithm")
  valid_607584 = validateParameter(valid_607584, JString, required = false,
                                 default = nil)
  if valid_607584 != nil:
    section.add "X-Amz-Algorithm", valid_607584
  var valid_607585 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607585 = validateParameter(valid_607585, JString, required = false,
                                 default = nil)
  if valid_607585 != nil:
    section.add "X-Amz-SignedHeaders", valid_607585
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607587: Call_UpdateComponentConfiguration_607575; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the monitoring configurations for the component. The configuration input parameter is an escaped JSON of the configuration and should match the schema of what is returned by <code>DescribeComponentConfigurationRecommendation</code>. 
  ## 
  let valid = call_607587.validator(path, query, header, formData, body)
  let scheme = call_607587.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607587.url(scheme.get, call_607587.host, call_607587.base,
                         call_607587.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607587, url, valid)

proc call*(call_607588: Call_UpdateComponentConfiguration_607575; body: JsonNode): Recallable =
  ## updateComponentConfiguration
  ## Updates the monitoring configurations for the component. The configuration input parameter is an escaped JSON of the configuration and should match the schema of what is returned by <code>DescribeComponentConfigurationRecommendation</code>. 
  ##   body: JObject (required)
  var body_607589 = newJObject()
  if body != nil:
    body_607589 = body
  result = call_607588.call(nil, nil, nil, nil, body_607589)

var updateComponentConfiguration* = Call_UpdateComponentConfiguration_607575(
    name: "updateComponentConfiguration", meth: HttpMethod.HttpPost,
    host: "applicationinsights.amazonaws.com", route: "/#X-Amz-Target=EC2WindowsBarleyService.UpdateComponentConfiguration",
    validator: validate_UpdateComponentConfiguration_607576, base: "/",
    url: url_UpdateComponentConfiguration_607577,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLogPattern_607590 = ref object of OpenApiRestCall_606589
proc url_UpdateLogPattern_607592(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateLogPattern_607591(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_607593 = header.getOrDefault("X-Amz-Target")
  valid_607593 = validateParameter(valid_607593, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.UpdateLogPattern"))
  if valid_607593 != nil:
    section.add "X-Amz-Target", valid_607593
  var valid_607594 = header.getOrDefault("X-Amz-Signature")
  valid_607594 = validateParameter(valid_607594, JString, required = false,
                                 default = nil)
  if valid_607594 != nil:
    section.add "X-Amz-Signature", valid_607594
  var valid_607595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607595 = validateParameter(valid_607595, JString, required = false,
                                 default = nil)
  if valid_607595 != nil:
    section.add "X-Amz-Content-Sha256", valid_607595
  var valid_607596 = header.getOrDefault("X-Amz-Date")
  valid_607596 = validateParameter(valid_607596, JString, required = false,
                                 default = nil)
  if valid_607596 != nil:
    section.add "X-Amz-Date", valid_607596
  var valid_607597 = header.getOrDefault("X-Amz-Credential")
  valid_607597 = validateParameter(valid_607597, JString, required = false,
                                 default = nil)
  if valid_607597 != nil:
    section.add "X-Amz-Credential", valid_607597
  var valid_607598 = header.getOrDefault("X-Amz-Security-Token")
  valid_607598 = validateParameter(valid_607598, JString, required = false,
                                 default = nil)
  if valid_607598 != nil:
    section.add "X-Amz-Security-Token", valid_607598
  var valid_607599 = header.getOrDefault("X-Amz-Algorithm")
  valid_607599 = validateParameter(valid_607599, JString, required = false,
                                 default = nil)
  if valid_607599 != nil:
    section.add "X-Amz-Algorithm", valid_607599
  var valid_607600 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607600 = validateParameter(valid_607600, JString, required = false,
                                 default = nil)
  if valid_607600 != nil:
    section.add "X-Amz-SignedHeaders", valid_607600
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607602: Call_UpdateLogPattern_607590; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds a log pattern to a <code>LogPatternSet</code>.
  ## 
  let valid = call_607602.validator(path, query, header, formData, body)
  let scheme = call_607602.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607602.url(scheme.get, call_607602.host, call_607602.base,
                         call_607602.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607602, url, valid)

proc call*(call_607603: Call_UpdateLogPattern_607590; body: JsonNode): Recallable =
  ## updateLogPattern
  ## Adds a log pattern to a <code>LogPatternSet</code>.
  ##   body: JObject (required)
  var body_607604 = newJObject()
  if body != nil:
    body_607604 = body
  result = call_607603.call(nil, nil, nil, nil, body_607604)

var updateLogPattern* = Call_UpdateLogPattern_607590(name: "updateLogPattern",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.UpdateLogPattern",
    validator: validate_UpdateLogPattern_607591, base: "/",
    url: url_UpdateLogPattern_607592, schemes: {Scheme.Https, Scheme.Http})
export
  rest

type
  EnvKind = enum
    BakeIntoBinary = "Baking $1 into the binary",
    FetchFromEnv = "Fetch $1 from the environment"
template sloppyConst(via: EnvKind; name: untyped): untyped =
  import
    macros

  const
    name {.strdefine.}: string = case via
    of BakeIntoBinary:
      getEnv(astToStr(name), "")
    of FetchFromEnv:
      ""
  static :
    let msg = block:
      if name == "":
        "Missing $1 in the environment"
      else:
        $via
    warning msg % [astToStr(name)]

sloppyConst FetchFromEnv, AWS_ACCESS_KEY_ID
sloppyConst FetchFromEnv, AWS_SECRET_ACCESS_KEY
sloppyConst BakeIntoBinary, AWS_REGION
sloppyConst FetchFromEnv, AWS_ACCOUNT_ID
proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", AWS_ACCESS_KEY_ID)
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", AWS_SECRET_ACCESS_KEY)
    region = os.getEnv("AWS_REGION", AWS_REGION)
  assert secret != "", "need $AWS_SECRET_ACCESS_KEY in environment"
  assert access != "", "need $AWS_ACCESS_KEY_ID in environment"
  assert region != "", "need $AWS_REGION in environment"
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
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)


import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

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
  Scheme* {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                             header: JsonNode = nil; formData: JsonNode = nil;
                             body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                    path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_402656044 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656044](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656044): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
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
  if js == nil:
    if required:
      if default != nil:
        return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

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

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.
    used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "applicationinsights.ap-northeast-1.amazonaws.com", "ap-southeast-1": "applicationinsights.ap-southeast-1.amazonaws.com", "us-west-2": "applicationinsights.us-west-2.amazonaws.com", "eu-west-2": "applicationinsights.eu-west-2.amazonaws.com", "ap-northeast-3": "applicationinsights.ap-northeast-3.amazonaws.com", "eu-central-1": "applicationinsights.eu-central-1.amazonaws.com", "us-east-2": "applicationinsights.us-east-2.amazonaws.com", "us-east-1": "applicationinsights.us-east-1.amazonaws.com", "cn-northwest-1": "applicationinsights.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "applicationinsights.ap-south-1.amazonaws.com", "eu-north-1": "applicationinsights.eu-north-1.amazonaws.com", "ap-northeast-2": "applicationinsights.ap-northeast-2.amazonaws.com", "us-west-1": "applicationinsights.us-west-1.amazonaws.com", "us-gov-east-1": "applicationinsights.us-gov-east-1.amazonaws.com", "eu-west-3": "applicationinsights.eu-west-3.amazonaws.com", "cn-north-1": "applicationinsights.cn-north-1.amazonaws.com.cn", "sa-east-1": "applicationinsights.sa-east-1.amazonaws.com", "eu-west-1": "applicationinsights.eu-west-1.amazonaws.com", "us-gov-west-1": "applicationinsights.us-gov-west-1.amazonaws.com", "ap-southeast-2": "applicationinsights.ap-southeast-2.amazonaws.com", "ca-central-1": "applicationinsights.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_CreateApplication_402656294 = ref object of OpenApiRestCall_402656044
proc url_CreateApplication_402656296(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateApplication_402656295(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656390 = header.getOrDefault("X-Amz-Target")
  valid_402656390 = validateParameter(valid_402656390, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.CreateApplication"))
  if valid_402656390 != nil:
    section.add "X-Amz-Target", valid_402656390
  var valid_402656391 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656391 = validateParameter(valid_402656391, JString,
                                      required = false, default = nil)
  if valid_402656391 != nil:
    section.add "X-Amz-Security-Token", valid_402656391
  var valid_402656392 = header.getOrDefault("X-Amz-Signature")
  valid_402656392 = validateParameter(valid_402656392, JString,
                                      required = false, default = nil)
  if valid_402656392 != nil:
    section.add "X-Amz-Signature", valid_402656392
  var valid_402656393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656393 = validateParameter(valid_402656393, JString,
                                      required = false, default = nil)
  if valid_402656393 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656393
  var valid_402656394 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656394 = validateParameter(valid_402656394, JString,
                                      required = false, default = nil)
  if valid_402656394 != nil:
    section.add "X-Amz-Algorithm", valid_402656394
  var valid_402656395 = header.getOrDefault("X-Amz-Date")
  valid_402656395 = validateParameter(valid_402656395, JString,
                                      required = false, default = nil)
  if valid_402656395 != nil:
    section.add "X-Amz-Date", valid_402656395
  var valid_402656396 = header.getOrDefault("X-Amz-Credential")
  valid_402656396 = validateParameter(valid_402656396, JString,
                                      required = false, default = nil)
  if valid_402656396 != nil:
    section.add "X-Amz-Credential", valid_402656396
  var valid_402656397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656397 = validateParameter(valid_402656397, JString,
                                      required = false, default = nil)
  if valid_402656397 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656412: Call_CreateApplication_402656294;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds an application that is created from a resource group.
                                                                                         ## 
  let valid = call_402656412.validator(path, query, header, formData, body, _)
  let scheme = call_402656412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656412.makeUrl(scheme.get, call_402656412.host, call_402656412.base,
                                   call_402656412.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656412, uri, valid, _)

proc call*(call_402656461: Call_CreateApplication_402656294; body: JsonNode): Recallable =
  ## createApplication
  ## Adds an application that is created from a resource group.
  ##   body: JObject (required)
  var body_402656462 = newJObject()
  if body != nil:
    body_402656462 = body
  result = call_402656461.call(nil, nil, nil, nil, body_402656462)

var createApplication* = Call_CreateApplication_402656294(
    name: "createApplication", meth: HttpMethod.HttpPost,
    host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.CreateApplication",
    validator: validate_CreateApplication_402656295, base: "/",
    makeUrl: url_CreateApplication_402656296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateComponent_402656489 = ref object of OpenApiRestCall_402656044
proc url_CreateComponent_402656491(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateComponent_402656490(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656492 = header.getOrDefault("X-Amz-Target")
  valid_402656492 = validateParameter(valid_402656492, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.CreateComponent"))
  if valid_402656492 != nil:
    section.add "X-Amz-Target", valid_402656492
  var valid_402656493 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656493 = validateParameter(valid_402656493, JString,
                                      required = false, default = nil)
  if valid_402656493 != nil:
    section.add "X-Amz-Security-Token", valid_402656493
  var valid_402656494 = header.getOrDefault("X-Amz-Signature")
  valid_402656494 = validateParameter(valid_402656494, JString,
                                      required = false, default = nil)
  if valid_402656494 != nil:
    section.add "X-Amz-Signature", valid_402656494
  var valid_402656495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656495 = validateParameter(valid_402656495, JString,
                                      required = false, default = nil)
  if valid_402656495 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656495
  var valid_402656496 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656496 = validateParameter(valid_402656496, JString,
                                      required = false, default = nil)
  if valid_402656496 != nil:
    section.add "X-Amz-Algorithm", valid_402656496
  var valid_402656497 = header.getOrDefault("X-Amz-Date")
  valid_402656497 = validateParameter(valid_402656497, JString,
                                      required = false, default = nil)
  if valid_402656497 != nil:
    section.add "X-Amz-Date", valid_402656497
  var valid_402656498 = header.getOrDefault("X-Amz-Credential")
  valid_402656498 = validateParameter(valid_402656498, JString,
                                      required = false, default = nil)
  if valid_402656498 != nil:
    section.add "X-Amz-Credential", valid_402656498
  var valid_402656499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656499 = validateParameter(valid_402656499, JString,
                                      required = false, default = nil)
  if valid_402656499 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656499
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656501: Call_CreateComponent_402656489; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a custom component by grouping similar standalone instances to monitor.
                                                                                         ## 
  let valid = call_402656501.validator(path, query, header, formData, body, _)
  let scheme = call_402656501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656501.makeUrl(scheme.get, call_402656501.host, call_402656501.base,
                                   call_402656501.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656501, uri, valid, _)

proc call*(call_402656502: Call_CreateComponent_402656489; body: JsonNode): Recallable =
  ## createComponent
  ## Creates a custom component by grouping similar standalone instances to monitor.
  ##   
                                                                                    ## body: JObject (required)
  var body_402656503 = newJObject()
  if body != nil:
    body_402656503 = body
  result = call_402656502.call(nil, nil, nil, nil, body_402656503)

var createComponent* = Call_CreateComponent_402656489(name: "createComponent",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.CreateComponent",
    validator: validate_CreateComponent_402656490, base: "/",
    makeUrl: url_CreateComponent_402656491, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateLogPattern_402656504 = ref object of OpenApiRestCall_402656044
proc url_CreateLogPattern_402656506(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateLogPattern_402656505(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656507 = header.getOrDefault("X-Amz-Target")
  valid_402656507 = validateParameter(valid_402656507, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.CreateLogPattern"))
  if valid_402656507 != nil:
    section.add "X-Amz-Target", valid_402656507
  var valid_402656508 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656508 = validateParameter(valid_402656508, JString,
                                      required = false, default = nil)
  if valid_402656508 != nil:
    section.add "X-Amz-Security-Token", valid_402656508
  var valid_402656509 = header.getOrDefault("X-Amz-Signature")
  valid_402656509 = validateParameter(valid_402656509, JString,
                                      required = false, default = nil)
  if valid_402656509 != nil:
    section.add "X-Amz-Signature", valid_402656509
  var valid_402656510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656510
  var valid_402656511 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656511 = validateParameter(valid_402656511, JString,
                                      required = false, default = nil)
  if valid_402656511 != nil:
    section.add "X-Amz-Algorithm", valid_402656511
  var valid_402656512 = header.getOrDefault("X-Amz-Date")
  valid_402656512 = validateParameter(valid_402656512, JString,
                                      required = false, default = nil)
  if valid_402656512 != nil:
    section.add "X-Amz-Date", valid_402656512
  var valid_402656513 = header.getOrDefault("X-Amz-Credential")
  valid_402656513 = validateParameter(valid_402656513, JString,
                                      required = false, default = nil)
  if valid_402656513 != nil:
    section.add "X-Amz-Credential", valid_402656513
  var valid_402656514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656514 = validateParameter(valid_402656514, JString,
                                      required = false, default = nil)
  if valid_402656514 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656514
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656516: Call_CreateLogPattern_402656504;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds an log pattern to a <code>LogPatternSet</code>.
                                                                                         ## 
  let valid = call_402656516.validator(path, query, header, formData, body, _)
  let scheme = call_402656516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656516.makeUrl(scheme.get, call_402656516.host, call_402656516.base,
                                   call_402656516.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656516, uri, valid, _)

proc call*(call_402656517: Call_CreateLogPattern_402656504; body: JsonNode): Recallable =
  ## createLogPattern
  ## Adds an log pattern to a <code>LogPatternSet</code>.
  ##   body: JObject (required)
  var body_402656518 = newJObject()
  if body != nil:
    body_402656518 = body
  result = call_402656517.call(nil, nil, nil, nil, body_402656518)

var createLogPattern* = Call_CreateLogPattern_402656504(
    name: "createLogPattern", meth: HttpMethod.HttpPost,
    host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.CreateLogPattern",
    validator: validate_CreateLogPattern_402656505, base: "/",
    makeUrl: url_CreateLogPattern_402656506,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApplication_402656519 = ref object of OpenApiRestCall_402656044
proc url_DeleteApplication_402656521(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteApplication_402656520(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656522 = header.getOrDefault("X-Amz-Target")
  valid_402656522 = validateParameter(valid_402656522, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.DeleteApplication"))
  if valid_402656522 != nil:
    section.add "X-Amz-Target", valid_402656522
  var valid_402656523 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656523 = validateParameter(valid_402656523, JString,
                                      required = false, default = nil)
  if valid_402656523 != nil:
    section.add "X-Amz-Security-Token", valid_402656523
  var valid_402656524 = header.getOrDefault("X-Amz-Signature")
  valid_402656524 = validateParameter(valid_402656524, JString,
                                      required = false, default = nil)
  if valid_402656524 != nil:
    section.add "X-Amz-Signature", valid_402656524
  var valid_402656525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656525
  var valid_402656526 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656526 = validateParameter(valid_402656526, JString,
                                      required = false, default = nil)
  if valid_402656526 != nil:
    section.add "X-Amz-Algorithm", valid_402656526
  var valid_402656527 = header.getOrDefault("X-Amz-Date")
  valid_402656527 = validateParameter(valid_402656527, JString,
                                      required = false, default = nil)
  if valid_402656527 != nil:
    section.add "X-Amz-Date", valid_402656527
  var valid_402656528 = header.getOrDefault("X-Amz-Credential")
  valid_402656528 = validateParameter(valid_402656528, JString,
                                      required = false, default = nil)
  if valid_402656528 != nil:
    section.add "X-Amz-Credential", valid_402656528
  var valid_402656529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656529 = validateParameter(valid_402656529, JString,
                                      required = false, default = nil)
  if valid_402656529 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656529
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656531: Call_DeleteApplication_402656519;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes the specified application from monitoring. Does not delete the application.
                                                                                         ## 
  let valid = call_402656531.validator(path, query, header, formData, body, _)
  let scheme = call_402656531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656531.makeUrl(scheme.get, call_402656531.host, call_402656531.base,
                                   call_402656531.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656531, uri, valid, _)

proc call*(call_402656532: Call_DeleteApplication_402656519; body: JsonNode): Recallable =
  ## deleteApplication
  ## Removes the specified application from monitoring. Does not delete the application.
  ##   
                                                                                        ## body: JObject (required)
  var body_402656533 = newJObject()
  if body != nil:
    body_402656533 = body
  result = call_402656532.call(nil, nil, nil, nil, body_402656533)

var deleteApplication* = Call_DeleteApplication_402656519(
    name: "deleteApplication", meth: HttpMethod.HttpPost,
    host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.DeleteApplication",
    validator: validate_DeleteApplication_402656520, base: "/",
    makeUrl: url_DeleteApplication_402656521,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteComponent_402656534 = ref object of OpenApiRestCall_402656044
proc url_DeleteComponent_402656536(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteComponent_402656535(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656537 = header.getOrDefault("X-Amz-Target")
  valid_402656537 = validateParameter(valid_402656537, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.DeleteComponent"))
  if valid_402656537 != nil:
    section.add "X-Amz-Target", valid_402656537
  var valid_402656538 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656538 = validateParameter(valid_402656538, JString,
                                      required = false, default = nil)
  if valid_402656538 != nil:
    section.add "X-Amz-Security-Token", valid_402656538
  var valid_402656539 = header.getOrDefault("X-Amz-Signature")
  valid_402656539 = validateParameter(valid_402656539, JString,
                                      required = false, default = nil)
  if valid_402656539 != nil:
    section.add "X-Amz-Signature", valid_402656539
  var valid_402656540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656540 = validateParameter(valid_402656540, JString,
                                      required = false, default = nil)
  if valid_402656540 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656540
  var valid_402656541 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656541 = validateParameter(valid_402656541, JString,
                                      required = false, default = nil)
  if valid_402656541 != nil:
    section.add "X-Amz-Algorithm", valid_402656541
  var valid_402656542 = header.getOrDefault("X-Amz-Date")
  valid_402656542 = validateParameter(valid_402656542, JString,
                                      required = false, default = nil)
  if valid_402656542 != nil:
    section.add "X-Amz-Date", valid_402656542
  var valid_402656543 = header.getOrDefault("X-Amz-Credential")
  valid_402656543 = validateParameter(valid_402656543, JString,
                                      required = false, default = nil)
  if valid_402656543 != nil:
    section.add "X-Amz-Credential", valid_402656543
  var valid_402656544 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656544 = validateParameter(valid_402656544, JString,
                                      required = false, default = nil)
  if valid_402656544 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656544
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656546: Call_DeleteComponent_402656534; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Ungroups a custom component. When you ungroup custom components, all applicable monitors that are set up for the component are removed and the instances revert to their standalone status.
                                                                                         ## 
  let valid = call_402656546.validator(path, query, header, formData, body, _)
  let scheme = call_402656546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656546.makeUrl(scheme.get, call_402656546.host, call_402656546.base,
                                   call_402656546.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656546, uri, valid, _)

proc call*(call_402656547: Call_DeleteComponent_402656534; body: JsonNode): Recallable =
  ## deleteComponent
  ## Ungroups a custom component. When you ungroup custom components, all applicable monitors that are set up for the component are removed and the instances revert to their standalone status.
  ##   
                                                                                                                                                                                                ## body: JObject (required)
  var body_402656548 = newJObject()
  if body != nil:
    body_402656548 = body
  result = call_402656547.call(nil, nil, nil, nil, body_402656548)

var deleteComponent* = Call_DeleteComponent_402656534(name: "deleteComponent",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.DeleteComponent",
    validator: validate_DeleteComponent_402656535, base: "/",
    makeUrl: url_DeleteComponent_402656536, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLogPattern_402656549 = ref object of OpenApiRestCall_402656044
proc url_DeleteLogPattern_402656551(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteLogPattern_402656550(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656552 = header.getOrDefault("X-Amz-Target")
  valid_402656552 = validateParameter(valid_402656552, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.DeleteLogPattern"))
  if valid_402656552 != nil:
    section.add "X-Amz-Target", valid_402656552
  var valid_402656553 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656553 = validateParameter(valid_402656553, JString,
                                      required = false, default = nil)
  if valid_402656553 != nil:
    section.add "X-Amz-Security-Token", valid_402656553
  var valid_402656554 = header.getOrDefault("X-Amz-Signature")
  valid_402656554 = validateParameter(valid_402656554, JString,
                                      required = false, default = nil)
  if valid_402656554 != nil:
    section.add "X-Amz-Signature", valid_402656554
  var valid_402656555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656555 = validateParameter(valid_402656555, JString,
                                      required = false, default = nil)
  if valid_402656555 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656555
  var valid_402656556 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656556 = validateParameter(valid_402656556, JString,
                                      required = false, default = nil)
  if valid_402656556 != nil:
    section.add "X-Amz-Algorithm", valid_402656556
  var valid_402656557 = header.getOrDefault("X-Amz-Date")
  valid_402656557 = validateParameter(valid_402656557, JString,
                                      required = false, default = nil)
  if valid_402656557 != nil:
    section.add "X-Amz-Date", valid_402656557
  var valid_402656558 = header.getOrDefault("X-Amz-Credential")
  valid_402656558 = validateParameter(valid_402656558, JString,
                                      required = false, default = nil)
  if valid_402656558 != nil:
    section.add "X-Amz-Credential", valid_402656558
  var valid_402656559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656559 = validateParameter(valid_402656559, JString,
                                      required = false, default = nil)
  if valid_402656559 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656559
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656561: Call_DeleteLogPattern_402656549;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes the specified log pattern from a <code>LogPatternSet</code>.
                                                                                         ## 
  let valid = call_402656561.validator(path, query, header, formData, body, _)
  let scheme = call_402656561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656561.makeUrl(scheme.get, call_402656561.host, call_402656561.base,
                                   call_402656561.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656561, uri, valid, _)

proc call*(call_402656562: Call_DeleteLogPattern_402656549; body: JsonNode): Recallable =
  ## deleteLogPattern
  ## Removes the specified log pattern from a <code>LogPatternSet</code>.
  ##   body: JObject 
                                                                         ## (required)
  var body_402656563 = newJObject()
  if body != nil:
    body_402656563 = body
  result = call_402656562.call(nil, nil, nil, nil, body_402656563)

var deleteLogPattern* = Call_DeleteLogPattern_402656549(
    name: "deleteLogPattern", meth: HttpMethod.HttpPost,
    host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.DeleteLogPattern",
    validator: validate_DeleteLogPattern_402656550, base: "/",
    makeUrl: url_DeleteLogPattern_402656551,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeApplication_402656564 = ref object of OpenApiRestCall_402656044
proc url_DescribeApplication_402656566(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeApplication_402656565(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656567 = header.getOrDefault("X-Amz-Target")
  valid_402656567 = validateParameter(valid_402656567, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.DescribeApplication"))
  if valid_402656567 != nil:
    section.add "X-Amz-Target", valid_402656567
  var valid_402656568 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656568 = validateParameter(valid_402656568, JString,
                                      required = false, default = nil)
  if valid_402656568 != nil:
    section.add "X-Amz-Security-Token", valid_402656568
  var valid_402656569 = header.getOrDefault("X-Amz-Signature")
  valid_402656569 = validateParameter(valid_402656569, JString,
                                      required = false, default = nil)
  if valid_402656569 != nil:
    section.add "X-Amz-Signature", valid_402656569
  var valid_402656570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656570 = validateParameter(valid_402656570, JString,
                                      required = false, default = nil)
  if valid_402656570 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656570
  var valid_402656571 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656571 = validateParameter(valid_402656571, JString,
                                      required = false, default = nil)
  if valid_402656571 != nil:
    section.add "X-Amz-Algorithm", valid_402656571
  var valid_402656572 = header.getOrDefault("X-Amz-Date")
  valid_402656572 = validateParameter(valid_402656572, JString,
                                      required = false, default = nil)
  if valid_402656572 != nil:
    section.add "X-Amz-Date", valid_402656572
  var valid_402656573 = header.getOrDefault("X-Amz-Credential")
  valid_402656573 = validateParameter(valid_402656573, JString,
                                      required = false, default = nil)
  if valid_402656573 != nil:
    section.add "X-Amz-Credential", valid_402656573
  var valid_402656574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656574 = validateParameter(valid_402656574, JString,
                                      required = false, default = nil)
  if valid_402656574 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656574
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656576: Call_DescribeApplication_402656564;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the application.
                                                                                         ## 
  let valid = call_402656576.validator(path, query, header, formData, body, _)
  let scheme = call_402656576.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656576.makeUrl(scheme.get, call_402656576.host, call_402656576.base,
                                   call_402656576.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656576, uri, valid, _)

proc call*(call_402656577: Call_DescribeApplication_402656564; body: JsonNode): Recallable =
  ## describeApplication
  ## Describes the application.
  ##   body: JObject (required)
  var body_402656578 = newJObject()
  if body != nil:
    body_402656578 = body
  result = call_402656577.call(nil, nil, nil, nil, body_402656578)

var describeApplication* = Call_DescribeApplication_402656564(
    name: "describeApplication", meth: HttpMethod.HttpPost,
    host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.DescribeApplication",
    validator: validate_DescribeApplication_402656565, base: "/",
    makeUrl: url_DescribeApplication_402656566,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeComponent_402656579 = ref object of OpenApiRestCall_402656044
proc url_DescribeComponent_402656581(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeComponent_402656580(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656582 = header.getOrDefault("X-Amz-Target")
  valid_402656582 = validateParameter(valid_402656582, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.DescribeComponent"))
  if valid_402656582 != nil:
    section.add "X-Amz-Target", valid_402656582
  var valid_402656583 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656583 = validateParameter(valid_402656583, JString,
                                      required = false, default = nil)
  if valid_402656583 != nil:
    section.add "X-Amz-Security-Token", valid_402656583
  var valid_402656584 = header.getOrDefault("X-Amz-Signature")
  valid_402656584 = validateParameter(valid_402656584, JString,
                                      required = false, default = nil)
  if valid_402656584 != nil:
    section.add "X-Amz-Signature", valid_402656584
  var valid_402656585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656585 = validateParameter(valid_402656585, JString,
                                      required = false, default = nil)
  if valid_402656585 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656585
  var valid_402656586 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656586 = validateParameter(valid_402656586, JString,
                                      required = false, default = nil)
  if valid_402656586 != nil:
    section.add "X-Amz-Algorithm", valid_402656586
  var valid_402656587 = header.getOrDefault("X-Amz-Date")
  valid_402656587 = validateParameter(valid_402656587, JString,
                                      required = false, default = nil)
  if valid_402656587 != nil:
    section.add "X-Amz-Date", valid_402656587
  var valid_402656588 = header.getOrDefault("X-Amz-Credential")
  valid_402656588 = validateParameter(valid_402656588, JString,
                                      required = false, default = nil)
  if valid_402656588 != nil:
    section.add "X-Amz-Credential", valid_402656588
  var valid_402656589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656589 = validateParameter(valid_402656589, JString,
                                      required = false, default = nil)
  if valid_402656589 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656589
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656591: Call_DescribeComponent_402656579;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes a component and lists the resources that are grouped together in a component.
                                                                                         ## 
  let valid = call_402656591.validator(path, query, header, formData, body, _)
  let scheme = call_402656591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656591.makeUrl(scheme.get, call_402656591.host, call_402656591.base,
                                   call_402656591.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656591, uri, valid, _)

proc call*(call_402656592: Call_DescribeComponent_402656579; body: JsonNode): Recallable =
  ## describeComponent
  ## Describes a component and lists the resources that are grouped together in a component.
  ##   
                                                                                            ## body: JObject (required)
  var body_402656593 = newJObject()
  if body != nil:
    body_402656593 = body
  result = call_402656592.call(nil, nil, nil, nil, body_402656593)

var describeComponent* = Call_DescribeComponent_402656579(
    name: "describeComponent", meth: HttpMethod.HttpPost,
    host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.DescribeComponent",
    validator: validate_DescribeComponent_402656580, base: "/",
    makeUrl: url_DescribeComponent_402656581,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeComponentConfiguration_402656594 = ref object of OpenApiRestCall_402656044
proc url_DescribeComponentConfiguration_402656596(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeComponentConfiguration_402656595(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656597 = header.getOrDefault("X-Amz-Target")
  valid_402656597 = validateParameter(valid_402656597, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.DescribeComponentConfiguration"))
  if valid_402656597 != nil:
    section.add "X-Amz-Target", valid_402656597
  var valid_402656598 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656598 = validateParameter(valid_402656598, JString,
                                      required = false, default = nil)
  if valid_402656598 != nil:
    section.add "X-Amz-Security-Token", valid_402656598
  var valid_402656599 = header.getOrDefault("X-Amz-Signature")
  valid_402656599 = validateParameter(valid_402656599, JString,
                                      required = false, default = nil)
  if valid_402656599 != nil:
    section.add "X-Amz-Signature", valid_402656599
  var valid_402656600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656600 = validateParameter(valid_402656600, JString,
                                      required = false, default = nil)
  if valid_402656600 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656600
  var valid_402656601 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656601 = validateParameter(valid_402656601, JString,
                                      required = false, default = nil)
  if valid_402656601 != nil:
    section.add "X-Amz-Algorithm", valid_402656601
  var valid_402656602 = header.getOrDefault("X-Amz-Date")
  valid_402656602 = validateParameter(valid_402656602, JString,
                                      required = false, default = nil)
  if valid_402656602 != nil:
    section.add "X-Amz-Date", valid_402656602
  var valid_402656603 = header.getOrDefault("X-Amz-Credential")
  valid_402656603 = validateParameter(valid_402656603, JString,
                                      required = false, default = nil)
  if valid_402656603 != nil:
    section.add "X-Amz-Credential", valid_402656603
  var valid_402656604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656604 = validateParameter(valid_402656604, JString,
                                      required = false, default = nil)
  if valid_402656604 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656604
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656606: Call_DescribeComponentConfiguration_402656594;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the monitoring configuration of the component.
                                                                                         ## 
  let valid = call_402656606.validator(path, query, header, formData, body, _)
  let scheme = call_402656606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656606.makeUrl(scheme.get, call_402656606.host, call_402656606.base,
                                   call_402656606.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656606, uri, valid, _)

proc call*(call_402656607: Call_DescribeComponentConfiguration_402656594;
           body: JsonNode): Recallable =
  ## describeComponentConfiguration
  ## Describes the monitoring configuration of the component.
  ##   body: JObject (required)
  var body_402656608 = newJObject()
  if body != nil:
    body_402656608 = body
  result = call_402656607.call(nil, nil, nil, nil, body_402656608)

var describeComponentConfiguration* = Call_DescribeComponentConfiguration_402656594(
    name: "describeComponentConfiguration", meth: HttpMethod.HttpPost,
    host: "applicationinsights.amazonaws.com", route: "/#X-Amz-Target=EC2WindowsBarleyService.DescribeComponentConfiguration",
    validator: validate_DescribeComponentConfiguration_402656595, base: "/",
    makeUrl: url_DescribeComponentConfiguration_402656596,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeComponentConfigurationRecommendation_402656609 = ref object of OpenApiRestCall_402656044
proc url_DescribeComponentConfigurationRecommendation_402656611(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeComponentConfigurationRecommendation_402656610(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656612 = header.getOrDefault("X-Amz-Target")
  valid_402656612 = validateParameter(valid_402656612, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.DescribeComponentConfigurationRecommendation"))
  if valid_402656612 != nil:
    section.add "X-Amz-Target", valid_402656612
  var valid_402656613 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656613 = validateParameter(valid_402656613, JString,
                                      required = false, default = nil)
  if valid_402656613 != nil:
    section.add "X-Amz-Security-Token", valid_402656613
  var valid_402656614 = header.getOrDefault("X-Amz-Signature")
  valid_402656614 = validateParameter(valid_402656614, JString,
                                      required = false, default = nil)
  if valid_402656614 != nil:
    section.add "X-Amz-Signature", valid_402656614
  var valid_402656615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656615 = validateParameter(valid_402656615, JString,
                                      required = false, default = nil)
  if valid_402656615 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656615
  var valid_402656616 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656616 = validateParameter(valid_402656616, JString,
                                      required = false, default = nil)
  if valid_402656616 != nil:
    section.add "X-Amz-Algorithm", valid_402656616
  var valid_402656617 = header.getOrDefault("X-Amz-Date")
  valid_402656617 = validateParameter(valid_402656617, JString,
                                      required = false, default = nil)
  if valid_402656617 != nil:
    section.add "X-Amz-Date", valid_402656617
  var valid_402656618 = header.getOrDefault("X-Amz-Credential")
  valid_402656618 = validateParameter(valid_402656618, JString,
                                      required = false, default = nil)
  if valid_402656618 != nil:
    section.add "X-Amz-Credential", valid_402656618
  var valid_402656619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656619 = validateParameter(valid_402656619, JString,
                                      required = false, default = nil)
  if valid_402656619 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656619
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656621: Call_DescribeComponentConfigurationRecommendation_402656609;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the recommended monitoring configuration of the component.
                                                                                         ## 
  let valid = call_402656621.validator(path, query, header, formData, body, _)
  let scheme = call_402656621.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656621.makeUrl(scheme.get, call_402656621.host, call_402656621.base,
                                   call_402656621.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656621, uri, valid, _)

proc call*(call_402656622: Call_DescribeComponentConfigurationRecommendation_402656609;
           body: JsonNode): Recallable =
  ## describeComponentConfigurationRecommendation
  ## Describes the recommended monitoring configuration of the component.
  ##   body: JObject 
                                                                         ## (required)
  var body_402656623 = newJObject()
  if body != nil:
    body_402656623 = body
  result = call_402656622.call(nil, nil, nil, nil, body_402656623)

var describeComponentConfigurationRecommendation* = Call_DescribeComponentConfigurationRecommendation_402656609(
    name: "describeComponentConfigurationRecommendation",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com", route: "/#X-Amz-Target=EC2WindowsBarleyService.DescribeComponentConfigurationRecommendation",
    validator: validate_DescribeComponentConfigurationRecommendation_402656610,
    base: "/", makeUrl: url_DescribeComponentConfigurationRecommendation_402656611,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeLogPattern_402656624 = ref object of OpenApiRestCall_402656044
proc url_DescribeLogPattern_402656626(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeLogPattern_402656625(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656627 = header.getOrDefault("X-Amz-Target")
  valid_402656627 = validateParameter(valid_402656627, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.DescribeLogPattern"))
  if valid_402656627 != nil:
    section.add "X-Amz-Target", valid_402656627
  var valid_402656628 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656628 = validateParameter(valid_402656628, JString,
                                      required = false, default = nil)
  if valid_402656628 != nil:
    section.add "X-Amz-Security-Token", valid_402656628
  var valid_402656629 = header.getOrDefault("X-Amz-Signature")
  valid_402656629 = validateParameter(valid_402656629, JString,
                                      required = false, default = nil)
  if valid_402656629 != nil:
    section.add "X-Amz-Signature", valid_402656629
  var valid_402656630 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656630 = validateParameter(valid_402656630, JString,
                                      required = false, default = nil)
  if valid_402656630 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656630
  var valid_402656631 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656631 = validateParameter(valid_402656631, JString,
                                      required = false, default = nil)
  if valid_402656631 != nil:
    section.add "X-Amz-Algorithm", valid_402656631
  var valid_402656632 = header.getOrDefault("X-Amz-Date")
  valid_402656632 = validateParameter(valid_402656632, JString,
                                      required = false, default = nil)
  if valid_402656632 != nil:
    section.add "X-Amz-Date", valid_402656632
  var valid_402656633 = header.getOrDefault("X-Amz-Credential")
  valid_402656633 = validateParameter(valid_402656633, JString,
                                      required = false, default = nil)
  if valid_402656633 != nil:
    section.add "X-Amz-Credential", valid_402656633
  var valid_402656634 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656634 = validateParameter(valid_402656634, JString,
                                      required = false, default = nil)
  if valid_402656634 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656634
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656636: Call_DescribeLogPattern_402656624;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describe a specific log pattern from a <code>LogPatternSet</code>.
                                                                                         ## 
  let valid = call_402656636.validator(path, query, header, formData, body, _)
  let scheme = call_402656636.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656636.makeUrl(scheme.get, call_402656636.host, call_402656636.base,
                                   call_402656636.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656636, uri, valid, _)

proc call*(call_402656637: Call_DescribeLogPattern_402656624; body: JsonNode): Recallable =
  ## describeLogPattern
  ## Describe a specific log pattern from a <code>LogPatternSet</code>.
  ##   body: JObject 
                                                                       ## (required)
  var body_402656638 = newJObject()
  if body != nil:
    body_402656638 = body
  result = call_402656637.call(nil, nil, nil, nil, body_402656638)

var describeLogPattern* = Call_DescribeLogPattern_402656624(
    name: "describeLogPattern", meth: HttpMethod.HttpPost,
    host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.DescribeLogPattern",
    validator: validate_DescribeLogPattern_402656625, base: "/",
    makeUrl: url_DescribeLogPattern_402656626,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeObservation_402656639 = ref object of OpenApiRestCall_402656044
proc url_DescribeObservation_402656641(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeObservation_402656640(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656642 = header.getOrDefault("X-Amz-Target")
  valid_402656642 = validateParameter(valid_402656642, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.DescribeObservation"))
  if valid_402656642 != nil:
    section.add "X-Amz-Target", valid_402656642
  var valid_402656643 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656643 = validateParameter(valid_402656643, JString,
                                      required = false, default = nil)
  if valid_402656643 != nil:
    section.add "X-Amz-Security-Token", valid_402656643
  var valid_402656644 = header.getOrDefault("X-Amz-Signature")
  valid_402656644 = validateParameter(valid_402656644, JString,
                                      required = false, default = nil)
  if valid_402656644 != nil:
    section.add "X-Amz-Signature", valid_402656644
  var valid_402656645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656645 = validateParameter(valid_402656645, JString,
                                      required = false, default = nil)
  if valid_402656645 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656645
  var valid_402656646 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656646 = validateParameter(valid_402656646, JString,
                                      required = false, default = nil)
  if valid_402656646 != nil:
    section.add "X-Amz-Algorithm", valid_402656646
  var valid_402656647 = header.getOrDefault("X-Amz-Date")
  valid_402656647 = validateParameter(valid_402656647, JString,
                                      required = false, default = nil)
  if valid_402656647 != nil:
    section.add "X-Amz-Date", valid_402656647
  var valid_402656648 = header.getOrDefault("X-Amz-Credential")
  valid_402656648 = validateParameter(valid_402656648, JString,
                                      required = false, default = nil)
  if valid_402656648 != nil:
    section.add "X-Amz-Credential", valid_402656648
  var valid_402656649 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656649 = validateParameter(valid_402656649, JString,
                                      required = false, default = nil)
  if valid_402656649 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656649
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656651: Call_DescribeObservation_402656639;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes an anomaly or error with the application.
                                                                                         ## 
  let valid = call_402656651.validator(path, query, header, formData, body, _)
  let scheme = call_402656651.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656651.makeUrl(scheme.get, call_402656651.host, call_402656651.base,
                                   call_402656651.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656651, uri, valid, _)

proc call*(call_402656652: Call_DescribeObservation_402656639; body: JsonNode): Recallable =
  ## describeObservation
  ## Describes an anomaly or error with the application.
  ##   body: JObject (required)
  var body_402656653 = newJObject()
  if body != nil:
    body_402656653 = body
  result = call_402656652.call(nil, nil, nil, nil, body_402656653)

var describeObservation* = Call_DescribeObservation_402656639(
    name: "describeObservation", meth: HttpMethod.HttpPost,
    host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.DescribeObservation",
    validator: validate_DescribeObservation_402656640, base: "/",
    makeUrl: url_DescribeObservation_402656641,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProblem_402656654 = ref object of OpenApiRestCall_402656044
proc url_DescribeProblem_402656656(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProblem_402656655(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656657 = header.getOrDefault("X-Amz-Target")
  valid_402656657 = validateParameter(valid_402656657, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.DescribeProblem"))
  if valid_402656657 != nil:
    section.add "X-Amz-Target", valid_402656657
  var valid_402656658 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656658 = validateParameter(valid_402656658, JString,
                                      required = false, default = nil)
  if valid_402656658 != nil:
    section.add "X-Amz-Security-Token", valid_402656658
  var valid_402656659 = header.getOrDefault("X-Amz-Signature")
  valid_402656659 = validateParameter(valid_402656659, JString,
                                      required = false, default = nil)
  if valid_402656659 != nil:
    section.add "X-Amz-Signature", valid_402656659
  var valid_402656660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656660 = validateParameter(valid_402656660, JString,
                                      required = false, default = nil)
  if valid_402656660 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656660
  var valid_402656661 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656661 = validateParameter(valid_402656661, JString,
                                      required = false, default = nil)
  if valid_402656661 != nil:
    section.add "X-Amz-Algorithm", valid_402656661
  var valid_402656662 = header.getOrDefault("X-Amz-Date")
  valid_402656662 = validateParameter(valid_402656662, JString,
                                      required = false, default = nil)
  if valid_402656662 != nil:
    section.add "X-Amz-Date", valid_402656662
  var valid_402656663 = header.getOrDefault("X-Amz-Credential")
  valid_402656663 = validateParameter(valid_402656663, JString,
                                      required = false, default = nil)
  if valid_402656663 != nil:
    section.add "X-Amz-Credential", valid_402656663
  var valid_402656664 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656664 = validateParameter(valid_402656664, JString,
                                      required = false, default = nil)
  if valid_402656664 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656664
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656666: Call_DescribeProblem_402656654; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes an application problem.
                                                                                         ## 
  let valid = call_402656666.validator(path, query, header, formData, body, _)
  let scheme = call_402656666.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656666.makeUrl(scheme.get, call_402656666.host, call_402656666.base,
                                   call_402656666.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656666, uri, valid, _)

proc call*(call_402656667: Call_DescribeProblem_402656654; body: JsonNode): Recallable =
  ## describeProblem
  ## Describes an application problem.
  ##   body: JObject (required)
  var body_402656668 = newJObject()
  if body != nil:
    body_402656668 = body
  result = call_402656667.call(nil, nil, nil, nil, body_402656668)

var describeProblem* = Call_DescribeProblem_402656654(name: "describeProblem",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.DescribeProblem",
    validator: validate_DescribeProblem_402656655, base: "/",
    makeUrl: url_DescribeProblem_402656656, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProblemObservations_402656669 = ref object of OpenApiRestCall_402656044
proc url_DescribeProblemObservations_402656671(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeProblemObservations_402656670(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656672 = header.getOrDefault("X-Amz-Target")
  valid_402656672 = validateParameter(valid_402656672, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.DescribeProblemObservations"))
  if valid_402656672 != nil:
    section.add "X-Amz-Target", valid_402656672
  var valid_402656673 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656673 = validateParameter(valid_402656673, JString,
                                      required = false, default = nil)
  if valid_402656673 != nil:
    section.add "X-Amz-Security-Token", valid_402656673
  var valid_402656674 = header.getOrDefault("X-Amz-Signature")
  valid_402656674 = validateParameter(valid_402656674, JString,
                                      required = false, default = nil)
  if valid_402656674 != nil:
    section.add "X-Amz-Signature", valid_402656674
  var valid_402656675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656675 = validateParameter(valid_402656675, JString,
                                      required = false, default = nil)
  if valid_402656675 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656675
  var valid_402656676 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656676 = validateParameter(valid_402656676, JString,
                                      required = false, default = nil)
  if valid_402656676 != nil:
    section.add "X-Amz-Algorithm", valid_402656676
  var valid_402656677 = header.getOrDefault("X-Amz-Date")
  valid_402656677 = validateParameter(valid_402656677, JString,
                                      required = false, default = nil)
  if valid_402656677 != nil:
    section.add "X-Amz-Date", valid_402656677
  var valid_402656678 = header.getOrDefault("X-Amz-Credential")
  valid_402656678 = validateParameter(valid_402656678, JString,
                                      required = false, default = nil)
  if valid_402656678 != nil:
    section.add "X-Amz-Credential", valid_402656678
  var valid_402656679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656679 = validateParameter(valid_402656679, JString,
                                      required = false, default = nil)
  if valid_402656679 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656679
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656681: Call_DescribeProblemObservations_402656669;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the anomalies or errors associated with the problem.
                                                                                         ## 
  let valid = call_402656681.validator(path, query, header, formData, body, _)
  let scheme = call_402656681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656681.makeUrl(scheme.get, call_402656681.host, call_402656681.base,
                                   call_402656681.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656681, uri, valid, _)

proc call*(call_402656682: Call_DescribeProblemObservations_402656669;
           body: JsonNode): Recallable =
  ## describeProblemObservations
  ## Describes the anomalies or errors associated with the problem.
  ##   body: JObject (required)
  var body_402656683 = newJObject()
  if body != nil:
    body_402656683 = body
  result = call_402656682.call(nil, nil, nil, nil, body_402656683)

var describeProblemObservations* = Call_DescribeProblemObservations_402656669(
    name: "describeProblemObservations", meth: HttpMethod.HttpPost,
    host: "applicationinsights.amazonaws.com", route: "/#X-Amz-Target=EC2WindowsBarleyService.DescribeProblemObservations",
    validator: validate_DescribeProblemObservations_402656670, base: "/",
    makeUrl: url_DescribeProblemObservations_402656671,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApplications_402656684 = ref object of OpenApiRestCall_402656044
proc url_ListApplications_402656686(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListApplications_402656685(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656687 = query.getOrDefault("MaxResults")
  valid_402656687 = validateParameter(valid_402656687, JString,
                                      required = false, default = nil)
  if valid_402656687 != nil:
    section.add "MaxResults", valid_402656687
  var valid_402656688 = query.getOrDefault("NextToken")
  valid_402656688 = validateParameter(valid_402656688, JString,
                                      required = false, default = nil)
  if valid_402656688 != nil:
    section.add "NextToken", valid_402656688
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656689 = header.getOrDefault("X-Amz-Target")
  valid_402656689 = validateParameter(valid_402656689, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.ListApplications"))
  if valid_402656689 != nil:
    section.add "X-Amz-Target", valid_402656689
  var valid_402656690 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656690 = validateParameter(valid_402656690, JString,
                                      required = false, default = nil)
  if valid_402656690 != nil:
    section.add "X-Amz-Security-Token", valid_402656690
  var valid_402656691 = header.getOrDefault("X-Amz-Signature")
  valid_402656691 = validateParameter(valid_402656691, JString,
                                      required = false, default = nil)
  if valid_402656691 != nil:
    section.add "X-Amz-Signature", valid_402656691
  var valid_402656692 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656692 = validateParameter(valid_402656692, JString,
                                      required = false, default = nil)
  if valid_402656692 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656692
  var valid_402656693 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656693 = validateParameter(valid_402656693, JString,
                                      required = false, default = nil)
  if valid_402656693 != nil:
    section.add "X-Amz-Algorithm", valid_402656693
  var valid_402656694 = header.getOrDefault("X-Amz-Date")
  valid_402656694 = validateParameter(valid_402656694, JString,
                                      required = false, default = nil)
  if valid_402656694 != nil:
    section.add "X-Amz-Date", valid_402656694
  var valid_402656695 = header.getOrDefault("X-Amz-Credential")
  valid_402656695 = validateParameter(valid_402656695, JString,
                                      required = false, default = nil)
  if valid_402656695 != nil:
    section.add "X-Amz-Credential", valid_402656695
  var valid_402656696 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656696 = validateParameter(valid_402656696, JString,
                                      required = false, default = nil)
  if valid_402656696 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656696
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656698: Call_ListApplications_402656684;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the IDs of the applications that you are monitoring. 
                                                                                         ## 
  let valid = call_402656698.validator(path, query, header, formData, body, _)
  let scheme = call_402656698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656698.makeUrl(scheme.get, call_402656698.host, call_402656698.base,
                                   call_402656698.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656698, uri, valid, _)

proc call*(call_402656699: Call_ListApplications_402656684; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listApplications
  ## Lists the IDs of the applications that you are monitoring. 
  ##   MaxResults: string
                                                                ##             : Pagination limit
  ##   
                                                                                                 ## body: JObject (required)
  ##   
                                                                                                                            ## NextToken: string
                                                                                                                            ##            
                                                                                                                            ## : 
                                                                                                                            ## Pagination 
                                                                                                                            ## token
  var query_402656700 = newJObject()
  var body_402656701 = newJObject()
  add(query_402656700, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656701 = body
  add(query_402656700, "NextToken", newJString(NextToken))
  result = call_402656699.call(nil, query_402656700, nil, nil, body_402656701)

var listApplications* = Call_ListApplications_402656684(
    name: "listApplications", meth: HttpMethod.HttpPost,
    host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.ListApplications",
    validator: validate_ListApplications_402656685, base: "/",
    makeUrl: url_ListApplications_402656686,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListComponents_402656702 = ref object of OpenApiRestCall_402656044
proc url_ListComponents_402656704(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListComponents_402656703(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656705 = query.getOrDefault("MaxResults")
  valid_402656705 = validateParameter(valid_402656705, JString,
                                      required = false, default = nil)
  if valid_402656705 != nil:
    section.add "MaxResults", valid_402656705
  var valid_402656706 = query.getOrDefault("NextToken")
  valid_402656706 = validateParameter(valid_402656706, JString,
                                      required = false, default = nil)
  if valid_402656706 != nil:
    section.add "NextToken", valid_402656706
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656707 = header.getOrDefault("X-Amz-Target")
  valid_402656707 = validateParameter(valid_402656707, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.ListComponents"))
  if valid_402656707 != nil:
    section.add "X-Amz-Target", valid_402656707
  var valid_402656708 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656708 = validateParameter(valid_402656708, JString,
                                      required = false, default = nil)
  if valid_402656708 != nil:
    section.add "X-Amz-Security-Token", valid_402656708
  var valid_402656709 = header.getOrDefault("X-Amz-Signature")
  valid_402656709 = validateParameter(valid_402656709, JString,
                                      required = false, default = nil)
  if valid_402656709 != nil:
    section.add "X-Amz-Signature", valid_402656709
  var valid_402656710 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656710 = validateParameter(valid_402656710, JString,
                                      required = false, default = nil)
  if valid_402656710 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656710
  var valid_402656711 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656711 = validateParameter(valid_402656711, JString,
                                      required = false, default = nil)
  if valid_402656711 != nil:
    section.add "X-Amz-Algorithm", valid_402656711
  var valid_402656712 = header.getOrDefault("X-Amz-Date")
  valid_402656712 = validateParameter(valid_402656712, JString,
                                      required = false, default = nil)
  if valid_402656712 != nil:
    section.add "X-Amz-Date", valid_402656712
  var valid_402656713 = header.getOrDefault("X-Amz-Credential")
  valid_402656713 = validateParameter(valid_402656713, JString,
                                      required = false, default = nil)
  if valid_402656713 != nil:
    section.add "X-Amz-Credential", valid_402656713
  var valid_402656714 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656714 = validateParameter(valid_402656714, JString,
                                      required = false, default = nil)
  if valid_402656714 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656714
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656716: Call_ListComponents_402656702; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the auto-grouped, standalone, and custom components of the application.
                                                                                         ## 
  let valid = call_402656716.validator(path, query, header, formData, body, _)
  let scheme = call_402656716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656716.makeUrl(scheme.get, call_402656716.host, call_402656716.base,
                                   call_402656716.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656716, uri, valid, _)

proc call*(call_402656717: Call_ListComponents_402656702; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listComponents
  ## Lists the auto-grouped, standalone, and custom components of the application.
  ##   
                                                                                  ## MaxResults: string
                                                                                  ##             
                                                                                  ## : 
                                                                                  ## Pagination 
                                                                                  ## limit
  ##   
                                                                                          ## body: JObject (required)
  ##   
                                                                                                                     ## NextToken: string
                                                                                                                     ##            
                                                                                                                     ## : 
                                                                                                                     ## Pagination 
                                                                                                                     ## token
  var query_402656718 = newJObject()
  var body_402656719 = newJObject()
  add(query_402656718, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656719 = body
  add(query_402656718, "NextToken", newJString(NextToken))
  result = call_402656717.call(nil, query_402656718, nil, nil, body_402656719)

var listComponents* = Call_ListComponents_402656702(name: "listComponents",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.ListComponents",
    validator: validate_ListComponents_402656703, base: "/",
    makeUrl: url_ListComponents_402656704, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurationHistory_402656720 = ref object of OpenApiRestCall_402656044
proc url_ListConfigurationHistory_402656722(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListConfigurationHistory_402656721(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_402656723 = query.getOrDefault("MaxResults")
  valid_402656723 = validateParameter(valid_402656723, JString,
                                      required = false, default = nil)
  if valid_402656723 != nil:
    section.add "MaxResults", valid_402656723
  var valid_402656724 = query.getOrDefault("NextToken")
  valid_402656724 = validateParameter(valid_402656724, JString,
                                      required = false, default = nil)
  if valid_402656724 != nil:
    section.add "NextToken", valid_402656724
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656725 = header.getOrDefault("X-Amz-Target")
  valid_402656725 = validateParameter(valid_402656725, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.ListConfigurationHistory"))
  if valid_402656725 != nil:
    section.add "X-Amz-Target", valid_402656725
  var valid_402656726 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656726 = validateParameter(valid_402656726, JString,
                                      required = false, default = nil)
  if valid_402656726 != nil:
    section.add "X-Amz-Security-Token", valid_402656726
  var valid_402656727 = header.getOrDefault("X-Amz-Signature")
  valid_402656727 = validateParameter(valid_402656727, JString,
                                      required = false, default = nil)
  if valid_402656727 != nil:
    section.add "X-Amz-Signature", valid_402656727
  var valid_402656728 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656728 = validateParameter(valid_402656728, JString,
                                      required = false, default = nil)
  if valid_402656728 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656728
  var valid_402656729 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656729 = validateParameter(valid_402656729, JString,
                                      required = false, default = nil)
  if valid_402656729 != nil:
    section.add "X-Amz-Algorithm", valid_402656729
  var valid_402656730 = header.getOrDefault("X-Amz-Date")
  valid_402656730 = validateParameter(valid_402656730, JString,
                                      required = false, default = nil)
  if valid_402656730 != nil:
    section.add "X-Amz-Date", valid_402656730
  var valid_402656731 = header.getOrDefault("X-Amz-Credential")
  valid_402656731 = validateParameter(valid_402656731, JString,
                                      required = false, default = nil)
  if valid_402656731 != nil:
    section.add "X-Amz-Credential", valid_402656731
  var valid_402656732 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656732 = validateParameter(valid_402656732, JString,
                                      required = false, default = nil)
  if valid_402656732 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656732
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656734: Call_ListConfigurationHistory_402656720;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> Lists the INFO, WARN, and ERROR events for periodic configuration updates performed by Application Insights. Examples of events represented are: </p> <ul> <li> <p>INFO: creating a new alarm or updating an alarm threshold.</p> </li> <li> <p>WARN: alarm not created due to insufficient data points used to predict thresholds.</p> </li> <li> <p>ERROR: alarm not created due to permission errors or exceeding quotas. </p> </li> </ul>
                                                                                         ## 
  let valid = call_402656734.validator(path, query, header, formData, body, _)
  let scheme = call_402656734.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656734.makeUrl(scheme.get, call_402656734.host, call_402656734.base,
                                   call_402656734.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656734, uri, valid, _)

proc call*(call_402656735: Call_ListConfigurationHistory_402656720;
           body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listConfigurationHistory
  ## <p> Lists the INFO, WARN, and ERROR events for periodic configuration updates performed by Application Insights. Examples of events represented are: </p> <ul> <li> <p>INFO: creating a new alarm or updating an alarm threshold.</p> </li> <li> <p>WARN: alarm not created due to insufficient data points used to predict thresholds.</p> </li> <li> <p>ERROR: alarm not created due to permission errors or exceeding quotas. </p> </li> </ul>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## MaxResults: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                      ##             
                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## limit
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## NextToken: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## token
  var query_402656736 = newJObject()
  var body_402656737 = newJObject()
  add(query_402656736, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656737 = body
  add(query_402656736, "NextToken", newJString(NextToken))
  result = call_402656735.call(nil, query_402656736, nil, nil, body_402656737)

var listConfigurationHistory* = Call_ListConfigurationHistory_402656720(
    name: "listConfigurationHistory", meth: HttpMethod.HttpPost,
    host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.ListConfigurationHistory",
    validator: validate_ListConfigurationHistory_402656721, base: "/",
    makeUrl: url_ListConfigurationHistory_402656722,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLogPatternSets_402656738 = ref object of OpenApiRestCall_402656044
proc url_ListLogPatternSets_402656740(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListLogPatternSets_402656739(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656741 = query.getOrDefault("MaxResults")
  valid_402656741 = validateParameter(valid_402656741, JString,
                                      required = false, default = nil)
  if valid_402656741 != nil:
    section.add "MaxResults", valid_402656741
  var valid_402656742 = query.getOrDefault("NextToken")
  valid_402656742 = validateParameter(valid_402656742, JString,
                                      required = false, default = nil)
  if valid_402656742 != nil:
    section.add "NextToken", valid_402656742
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656743 = header.getOrDefault("X-Amz-Target")
  valid_402656743 = validateParameter(valid_402656743, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.ListLogPatternSets"))
  if valid_402656743 != nil:
    section.add "X-Amz-Target", valid_402656743
  var valid_402656744 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656744 = validateParameter(valid_402656744, JString,
                                      required = false, default = nil)
  if valid_402656744 != nil:
    section.add "X-Amz-Security-Token", valid_402656744
  var valid_402656745 = header.getOrDefault("X-Amz-Signature")
  valid_402656745 = validateParameter(valid_402656745, JString,
                                      required = false, default = nil)
  if valid_402656745 != nil:
    section.add "X-Amz-Signature", valid_402656745
  var valid_402656746 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656746 = validateParameter(valid_402656746, JString,
                                      required = false, default = nil)
  if valid_402656746 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656746
  var valid_402656747 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656747 = validateParameter(valid_402656747, JString,
                                      required = false, default = nil)
  if valid_402656747 != nil:
    section.add "X-Amz-Algorithm", valid_402656747
  var valid_402656748 = header.getOrDefault("X-Amz-Date")
  valid_402656748 = validateParameter(valid_402656748, JString,
                                      required = false, default = nil)
  if valid_402656748 != nil:
    section.add "X-Amz-Date", valid_402656748
  var valid_402656749 = header.getOrDefault("X-Amz-Credential")
  valid_402656749 = validateParameter(valid_402656749, JString,
                                      required = false, default = nil)
  if valid_402656749 != nil:
    section.add "X-Amz-Credential", valid_402656749
  var valid_402656750 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656750 = validateParameter(valid_402656750, JString,
                                      required = false, default = nil)
  if valid_402656750 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656750
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656752: Call_ListLogPatternSets_402656738;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the log pattern sets in the specific application.
                                                                                         ## 
  let valid = call_402656752.validator(path, query, header, formData, body, _)
  let scheme = call_402656752.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656752.makeUrl(scheme.get, call_402656752.host, call_402656752.base,
                                   call_402656752.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656752, uri, valid, _)

proc call*(call_402656753: Call_ListLogPatternSets_402656738; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listLogPatternSets
  ## Lists the log pattern sets in the specific application.
  ##   MaxResults: string
                                                            ##             : Pagination limit
  ##   
                                                                                             ## body: JObject (required)
  ##   
                                                                                                                        ## NextToken: string
                                                                                                                        ##            
                                                                                                                        ## : 
                                                                                                                        ## Pagination 
                                                                                                                        ## token
  var query_402656754 = newJObject()
  var body_402656755 = newJObject()
  add(query_402656754, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656755 = body
  add(query_402656754, "NextToken", newJString(NextToken))
  result = call_402656753.call(nil, query_402656754, nil, nil, body_402656755)

var listLogPatternSets* = Call_ListLogPatternSets_402656738(
    name: "listLogPatternSets", meth: HttpMethod.HttpPost,
    host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.ListLogPatternSets",
    validator: validate_ListLogPatternSets_402656739, base: "/",
    makeUrl: url_ListLogPatternSets_402656740,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLogPatterns_402656756 = ref object of OpenApiRestCall_402656044
proc url_ListLogPatterns_402656758(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListLogPatterns_402656757(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656759 = query.getOrDefault("MaxResults")
  valid_402656759 = validateParameter(valid_402656759, JString,
                                      required = false, default = nil)
  if valid_402656759 != nil:
    section.add "MaxResults", valid_402656759
  var valid_402656760 = query.getOrDefault("NextToken")
  valid_402656760 = validateParameter(valid_402656760, JString,
                                      required = false, default = nil)
  if valid_402656760 != nil:
    section.add "NextToken", valid_402656760
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656761 = header.getOrDefault("X-Amz-Target")
  valid_402656761 = validateParameter(valid_402656761, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.ListLogPatterns"))
  if valid_402656761 != nil:
    section.add "X-Amz-Target", valid_402656761
  var valid_402656762 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656762 = validateParameter(valid_402656762, JString,
                                      required = false, default = nil)
  if valid_402656762 != nil:
    section.add "X-Amz-Security-Token", valid_402656762
  var valid_402656763 = header.getOrDefault("X-Amz-Signature")
  valid_402656763 = validateParameter(valid_402656763, JString,
                                      required = false, default = nil)
  if valid_402656763 != nil:
    section.add "X-Amz-Signature", valid_402656763
  var valid_402656764 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656764 = validateParameter(valid_402656764, JString,
                                      required = false, default = nil)
  if valid_402656764 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656764
  var valid_402656765 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656765 = validateParameter(valid_402656765, JString,
                                      required = false, default = nil)
  if valid_402656765 != nil:
    section.add "X-Amz-Algorithm", valid_402656765
  var valid_402656766 = header.getOrDefault("X-Amz-Date")
  valid_402656766 = validateParameter(valid_402656766, JString,
                                      required = false, default = nil)
  if valid_402656766 != nil:
    section.add "X-Amz-Date", valid_402656766
  var valid_402656767 = header.getOrDefault("X-Amz-Credential")
  valid_402656767 = validateParameter(valid_402656767, JString,
                                      required = false, default = nil)
  if valid_402656767 != nil:
    section.add "X-Amz-Credential", valid_402656767
  var valid_402656768 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656768 = validateParameter(valid_402656768, JString,
                                      required = false, default = nil)
  if valid_402656768 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656768
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656770: Call_ListLogPatterns_402656756; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the log patterns in the specific log <code>LogPatternSet</code>.
                                                                                         ## 
  let valid = call_402656770.validator(path, query, header, formData, body, _)
  let scheme = call_402656770.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656770.makeUrl(scheme.get, call_402656770.host, call_402656770.base,
                                   call_402656770.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656770, uri, valid, _)

proc call*(call_402656771: Call_ListLogPatterns_402656756; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listLogPatterns
  ## Lists the log patterns in the specific log <code>LogPatternSet</code>.
  ##   
                                                                           ## MaxResults: string
                                                                           ##             
                                                                           ## : 
                                                                           ## Pagination 
                                                                           ## limit
  ##   
                                                                                   ## body: JObject (required)
  ##   
                                                                                                              ## NextToken: string
                                                                                                              ##            
                                                                                                              ## : 
                                                                                                              ## Pagination 
                                                                                                              ## token
  var query_402656772 = newJObject()
  var body_402656773 = newJObject()
  add(query_402656772, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656773 = body
  add(query_402656772, "NextToken", newJString(NextToken))
  result = call_402656771.call(nil, query_402656772, nil, nil, body_402656773)

var listLogPatterns* = Call_ListLogPatterns_402656756(name: "listLogPatterns",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.ListLogPatterns",
    validator: validate_ListLogPatterns_402656757, base: "/",
    makeUrl: url_ListLogPatterns_402656758, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProblems_402656774 = ref object of OpenApiRestCall_402656044
proc url_ListProblems_402656776(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListProblems_402656775(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_402656777 = query.getOrDefault("MaxResults")
  valid_402656777 = validateParameter(valid_402656777, JString,
                                      required = false, default = nil)
  if valid_402656777 != nil:
    section.add "MaxResults", valid_402656777
  var valid_402656778 = query.getOrDefault("NextToken")
  valid_402656778 = validateParameter(valid_402656778, JString,
                                      required = false, default = nil)
  if valid_402656778 != nil:
    section.add "NextToken", valid_402656778
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656779 = header.getOrDefault("X-Amz-Target")
  valid_402656779 = validateParameter(valid_402656779, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.ListProblems"))
  if valid_402656779 != nil:
    section.add "X-Amz-Target", valid_402656779
  var valid_402656780 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656780 = validateParameter(valid_402656780, JString,
                                      required = false, default = nil)
  if valid_402656780 != nil:
    section.add "X-Amz-Security-Token", valid_402656780
  var valid_402656781 = header.getOrDefault("X-Amz-Signature")
  valid_402656781 = validateParameter(valid_402656781, JString,
                                      required = false, default = nil)
  if valid_402656781 != nil:
    section.add "X-Amz-Signature", valid_402656781
  var valid_402656782 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656782 = validateParameter(valid_402656782, JString,
                                      required = false, default = nil)
  if valid_402656782 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656782
  var valid_402656783 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656783 = validateParameter(valid_402656783, JString,
                                      required = false, default = nil)
  if valid_402656783 != nil:
    section.add "X-Amz-Algorithm", valid_402656783
  var valid_402656784 = header.getOrDefault("X-Amz-Date")
  valid_402656784 = validateParameter(valid_402656784, JString,
                                      required = false, default = nil)
  if valid_402656784 != nil:
    section.add "X-Amz-Date", valid_402656784
  var valid_402656785 = header.getOrDefault("X-Amz-Credential")
  valid_402656785 = validateParameter(valid_402656785, JString,
                                      required = false, default = nil)
  if valid_402656785 != nil:
    section.add "X-Amz-Credential", valid_402656785
  var valid_402656786 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656786 = validateParameter(valid_402656786, JString,
                                      required = false, default = nil)
  if valid_402656786 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656786
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656788: Call_ListProblems_402656774; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the problems with your application.
                                                                                         ## 
  let valid = call_402656788.validator(path, query, header, formData, body, _)
  let scheme = call_402656788.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656788.makeUrl(scheme.get, call_402656788.host, call_402656788.base,
                                   call_402656788.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656788, uri, valid, _)

proc call*(call_402656789: Call_ListProblems_402656774; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listProblems
  ## Lists the problems with your application.
  ##   MaxResults: string
                                              ##             : Pagination limit
  ##   
                                                                               ## body: JObject (required)
  ##   
                                                                                                          ## NextToken: string
                                                                                                          ##            
                                                                                                          ## : 
                                                                                                          ## Pagination 
                                                                                                          ## token
  var query_402656790 = newJObject()
  var body_402656791 = newJObject()
  add(query_402656790, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656791 = body
  add(query_402656790, "NextToken", newJString(NextToken))
  result = call_402656789.call(nil, query_402656790, nil, nil, body_402656791)

var listProblems* = Call_ListProblems_402656774(name: "listProblems",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.ListProblems",
    validator: validate_ListProblems_402656775, base: "/",
    makeUrl: url_ListProblems_402656776, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_402656792 = ref object of OpenApiRestCall_402656044
proc url_ListTagsForResource_402656794(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_402656793(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656795 = header.getOrDefault("X-Amz-Target")
  valid_402656795 = validateParameter(valid_402656795, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.ListTagsForResource"))
  if valid_402656795 != nil:
    section.add "X-Amz-Target", valid_402656795
  var valid_402656796 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656796 = validateParameter(valid_402656796, JString,
                                      required = false, default = nil)
  if valid_402656796 != nil:
    section.add "X-Amz-Security-Token", valid_402656796
  var valid_402656797 = header.getOrDefault("X-Amz-Signature")
  valid_402656797 = validateParameter(valid_402656797, JString,
                                      required = false, default = nil)
  if valid_402656797 != nil:
    section.add "X-Amz-Signature", valid_402656797
  var valid_402656798 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656798 = validateParameter(valid_402656798, JString,
                                      required = false, default = nil)
  if valid_402656798 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656798
  var valid_402656799 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656799 = validateParameter(valid_402656799, JString,
                                      required = false, default = nil)
  if valid_402656799 != nil:
    section.add "X-Amz-Algorithm", valid_402656799
  var valid_402656800 = header.getOrDefault("X-Amz-Date")
  valid_402656800 = validateParameter(valid_402656800, JString,
                                      required = false, default = nil)
  if valid_402656800 != nil:
    section.add "X-Amz-Date", valid_402656800
  var valid_402656801 = header.getOrDefault("X-Amz-Credential")
  valid_402656801 = validateParameter(valid_402656801, JString,
                                      required = false, default = nil)
  if valid_402656801 != nil:
    section.add "X-Amz-Credential", valid_402656801
  var valid_402656802 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656802 = validateParameter(valid_402656802, JString,
                                      required = false, default = nil)
  if valid_402656802 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656802
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656804: Call_ListTagsForResource_402656792;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve a list of the tags (keys and values) that are associated with a specified application. A <i>tag</i> is a label that you optionally define and associate with an application. Each tag consists of a required <i>tag key</i> and an optional associated <i>tag value</i>. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.
                                                                                         ## 
  let valid = call_402656804.validator(path, query, header, formData, body, _)
  let scheme = call_402656804.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656804.makeUrl(scheme.get, call_402656804.host, call_402656804.base,
                                   call_402656804.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656804, uri, valid, _)

proc call*(call_402656805: Call_ListTagsForResource_402656792; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Retrieve a list of the tags (keys and values) that are associated with a specified application. A <i>tag</i> is a label that you optionally define and associate with an application. Each tag consists of a required <i>tag key</i> and an optional associated <i>tag value</i>. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                            ## body: JObject (required)
  var body_402656806 = newJObject()
  if body != nil:
    body_402656806 = body
  result = call_402656805.call(nil, nil, nil, nil, body_402656806)

var listTagsForResource* = Call_ListTagsForResource_402656792(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.ListTagsForResource",
    validator: validate_ListTagsForResource_402656793, base: "/",
    makeUrl: url_ListTagsForResource_402656794,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_402656807 = ref object of OpenApiRestCall_402656044
proc url_TagResource_402656809(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_402656808(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656810 = header.getOrDefault("X-Amz-Target")
  valid_402656810 = validateParameter(valid_402656810, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.TagResource"))
  if valid_402656810 != nil:
    section.add "X-Amz-Target", valid_402656810
  var valid_402656811 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656811 = validateParameter(valid_402656811, JString,
                                      required = false, default = nil)
  if valid_402656811 != nil:
    section.add "X-Amz-Security-Token", valid_402656811
  var valid_402656812 = header.getOrDefault("X-Amz-Signature")
  valid_402656812 = validateParameter(valid_402656812, JString,
                                      required = false, default = nil)
  if valid_402656812 != nil:
    section.add "X-Amz-Signature", valid_402656812
  var valid_402656813 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656813 = validateParameter(valid_402656813, JString,
                                      required = false, default = nil)
  if valid_402656813 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656813
  var valid_402656814 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656814 = validateParameter(valid_402656814, JString,
                                      required = false, default = nil)
  if valid_402656814 != nil:
    section.add "X-Amz-Algorithm", valid_402656814
  var valid_402656815 = header.getOrDefault("X-Amz-Date")
  valid_402656815 = validateParameter(valid_402656815, JString,
                                      required = false, default = nil)
  if valid_402656815 != nil:
    section.add "X-Amz-Date", valid_402656815
  var valid_402656816 = header.getOrDefault("X-Amz-Credential")
  valid_402656816 = validateParameter(valid_402656816, JString,
                                      required = false, default = nil)
  if valid_402656816 != nil:
    section.add "X-Amz-Credential", valid_402656816
  var valid_402656817 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656817 = validateParameter(valid_402656817, JString,
                                      required = false, default = nil)
  if valid_402656817 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656817
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656819: Call_TagResource_402656807; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Add one or more tags (keys and values) to a specified application. A <i>tag</i> is a label that you optionally define and associate with an application. Tags can help you categorize and manage application in different ways, such as by purpose, owner, environment, or other criteria. </p> <p>Each tag consists of a required <i>tag key</i> and an associated <i>tag value</i>, both of which you define. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.</p>
                                                                                         ## 
  let valid = call_402656819.validator(path, query, header, formData, body, _)
  let scheme = call_402656819.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656819.makeUrl(scheme.get, call_402656819.host, call_402656819.base,
                                   call_402656819.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656819, uri, valid, _)

proc call*(call_402656820: Call_TagResource_402656807; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Add one or more tags (keys and values) to a specified application. A <i>tag</i> is a label that you optionally define and associate with an application. Tags can help you categorize and manage application in different ways, such as by purpose, owner, environment, or other criteria. </p> <p>Each tag consists of a required <i>tag key</i> and an associated <i>tag value</i>, both of which you define. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## body: JObject (required)
  var body_402656821 = newJObject()
  if body != nil:
    body_402656821 = body
  result = call_402656820.call(nil, nil, nil, nil, body_402656821)

var tagResource* = Call_TagResource_402656807(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.TagResource",
    validator: validate_TagResource_402656808, base: "/",
    makeUrl: url_TagResource_402656809, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_402656822 = ref object of OpenApiRestCall_402656044
proc url_UntagResource_402656824(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_402656823(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656825 = header.getOrDefault("X-Amz-Target")
  valid_402656825 = validateParameter(valid_402656825, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.UntagResource"))
  if valid_402656825 != nil:
    section.add "X-Amz-Target", valid_402656825
  var valid_402656826 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656826 = validateParameter(valid_402656826, JString,
                                      required = false, default = nil)
  if valid_402656826 != nil:
    section.add "X-Amz-Security-Token", valid_402656826
  var valid_402656827 = header.getOrDefault("X-Amz-Signature")
  valid_402656827 = validateParameter(valid_402656827, JString,
                                      required = false, default = nil)
  if valid_402656827 != nil:
    section.add "X-Amz-Signature", valid_402656827
  var valid_402656828 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656828 = validateParameter(valid_402656828, JString,
                                      required = false, default = nil)
  if valid_402656828 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656828
  var valid_402656829 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656829 = validateParameter(valid_402656829, JString,
                                      required = false, default = nil)
  if valid_402656829 != nil:
    section.add "X-Amz-Algorithm", valid_402656829
  var valid_402656830 = header.getOrDefault("X-Amz-Date")
  valid_402656830 = validateParameter(valid_402656830, JString,
                                      required = false, default = nil)
  if valid_402656830 != nil:
    section.add "X-Amz-Date", valid_402656830
  var valid_402656831 = header.getOrDefault("X-Amz-Credential")
  valid_402656831 = validateParameter(valid_402656831, JString,
                                      required = false, default = nil)
  if valid_402656831 != nil:
    section.add "X-Amz-Credential", valid_402656831
  var valid_402656832 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656832 = validateParameter(valid_402656832, JString,
                                      required = false, default = nil)
  if valid_402656832 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656832
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656834: Call_UntagResource_402656822; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Remove one or more tags (keys and values) from a specified application.
                                                                                         ## 
  let valid = call_402656834.validator(path, query, header, formData, body, _)
  let scheme = call_402656834.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656834.makeUrl(scheme.get, call_402656834.host, call_402656834.base,
                                   call_402656834.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656834, uri, valid, _)

proc call*(call_402656835: Call_UntagResource_402656822; body: JsonNode): Recallable =
  ## untagResource
  ## Remove one or more tags (keys and values) from a specified application.
  ##   
                                                                            ## body: JObject (required)
  var body_402656836 = newJObject()
  if body != nil:
    body_402656836 = body
  result = call_402656835.call(nil, nil, nil, nil, body_402656836)

var untagResource* = Call_UntagResource_402656822(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.UntagResource",
    validator: validate_UntagResource_402656823, base: "/",
    makeUrl: url_UntagResource_402656824, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApplication_402656837 = ref object of OpenApiRestCall_402656044
proc url_UpdateApplication_402656839(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateApplication_402656838(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656840 = header.getOrDefault("X-Amz-Target")
  valid_402656840 = validateParameter(valid_402656840, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.UpdateApplication"))
  if valid_402656840 != nil:
    section.add "X-Amz-Target", valid_402656840
  var valid_402656841 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656841 = validateParameter(valid_402656841, JString,
                                      required = false, default = nil)
  if valid_402656841 != nil:
    section.add "X-Amz-Security-Token", valid_402656841
  var valid_402656842 = header.getOrDefault("X-Amz-Signature")
  valid_402656842 = validateParameter(valid_402656842, JString,
                                      required = false, default = nil)
  if valid_402656842 != nil:
    section.add "X-Amz-Signature", valid_402656842
  var valid_402656843 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656843 = validateParameter(valid_402656843, JString,
                                      required = false, default = nil)
  if valid_402656843 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656843
  var valid_402656844 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656844 = validateParameter(valid_402656844, JString,
                                      required = false, default = nil)
  if valid_402656844 != nil:
    section.add "X-Amz-Algorithm", valid_402656844
  var valid_402656845 = header.getOrDefault("X-Amz-Date")
  valid_402656845 = validateParameter(valid_402656845, JString,
                                      required = false, default = nil)
  if valid_402656845 != nil:
    section.add "X-Amz-Date", valid_402656845
  var valid_402656846 = header.getOrDefault("X-Amz-Credential")
  valid_402656846 = validateParameter(valid_402656846, JString,
                                      required = false, default = nil)
  if valid_402656846 != nil:
    section.add "X-Amz-Credential", valid_402656846
  var valid_402656847 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656847 = validateParameter(valid_402656847, JString,
                                      required = false, default = nil)
  if valid_402656847 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656847
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656849: Call_UpdateApplication_402656837;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the application.
                                                                                         ## 
  let valid = call_402656849.validator(path, query, header, formData, body, _)
  let scheme = call_402656849.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656849.makeUrl(scheme.get, call_402656849.host, call_402656849.base,
                                   call_402656849.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656849, uri, valid, _)

proc call*(call_402656850: Call_UpdateApplication_402656837; body: JsonNode): Recallable =
  ## updateApplication
  ## Updates the application.
  ##   body: JObject (required)
  var body_402656851 = newJObject()
  if body != nil:
    body_402656851 = body
  result = call_402656850.call(nil, nil, nil, nil, body_402656851)

var updateApplication* = Call_UpdateApplication_402656837(
    name: "updateApplication", meth: HttpMethod.HttpPost,
    host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.UpdateApplication",
    validator: validate_UpdateApplication_402656838, base: "/",
    makeUrl: url_UpdateApplication_402656839,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateComponent_402656852 = ref object of OpenApiRestCall_402656044
proc url_UpdateComponent_402656854(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateComponent_402656853(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656855 = header.getOrDefault("X-Amz-Target")
  valid_402656855 = validateParameter(valid_402656855, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.UpdateComponent"))
  if valid_402656855 != nil:
    section.add "X-Amz-Target", valid_402656855
  var valid_402656856 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656856 = validateParameter(valid_402656856, JString,
                                      required = false, default = nil)
  if valid_402656856 != nil:
    section.add "X-Amz-Security-Token", valid_402656856
  var valid_402656857 = header.getOrDefault("X-Amz-Signature")
  valid_402656857 = validateParameter(valid_402656857, JString,
                                      required = false, default = nil)
  if valid_402656857 != nil:
    section.add "X-Amz-Signature", valid_402656857
  var valid_402656858 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656858 = validateParameter(valid_402656858, JString,
                                      required = false, default = nil)
  if valid_402656858 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656858
  var valid_402656859 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656859 = validateParameter(valid_402656859, JString,
                                      required = false, default = nil)
  if valid_402656859 != nil:
    section.add "X-Amz-Algorithm", valid_402656859
  var valid_402656860 = header.getOrDefault("X-Amz-Date")
  valid_402656860 = validateParameter(valid_402656860, JString,
                                      required = false, default = nil)
  if valid_402656860 != nil:
    section.add "X-Amz-Date", valid_402656860
  var valid_402656861 = header.getOrDefault("X-Amz-Credential")
  valid_402656861 = validateParameter(valid_402656861, JString,
                                      required = false, default = nil)
  if valid_402656861 != nil:
    section.add "X-Amz-Credential", valid_402656861
  var valid_402656862 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656862 = validateParameter(valid_402656862, JString,
                                      required = false, default = nil)
  if valid_402656862 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656862
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656864: Call_UpdateComponent_402656852; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the custom component name and/or the list of resources that make up the component.
                                                                                         ## 
  let valid = call_402656864.validator(path, query, header, formData, body, _)
  let scheme = call_402656864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656864.makeUrl(scheme.get, call_402656864.host, call_402656864.base,
                                   call_402656864.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656864, uri, valid, _)

proc call*(call_402656865: Call_UpdateComponent_402656852; body: JsonNode): Recallable =
  ## updateComponent
  ## Updates the custom component name and/or the list of resources that make up the component.
  ##   
                                                                                               ## body: JObject (required)
  var body_402656866 = newJObject()
  if body != nil:
    body_402656866 = body
  result = call_402656865.call(nil, nil, nil, nil, body_402656866)

var updateComponent* = Call_UpdateComponent_402656852(name: "updateComponent",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.UpdateComponent",
    validator: validate_UpdateComponent_402656853, base: "/",
    makeUrl: url_UpdateComponent_402656854, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateComponentConfiguration_402656867 = ref object of OpenApiRestCall_402656044
proc url_UpdateComponentConfiguration_402656869(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateComponentConfiguration_402656868(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656870 = header.getOrDefault("X-Amz-Target")
  valid_402656870 = validateParameter(valid_402656870, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.UpdateComponentConfiguration"))
  if valid_402656870 != nil:
    section.add "X-Amz-Target", valid_402656870
  var valid_402656871 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656871 = validateParameter(valid_402656871, JString,
                                      required = false, default = nil)
  if valid_402656871 != nil:
    section.add "X-Amz-Security-Token", valid_402656871
  var valid_402656872 = header.getOrDefault("X-Amz-Signature")
  valid_402656872 = validateParameter(valid_402656872, JString,
                                      required = false, default = nil)
  if valid_402656872 != nil:
    section.add "X-Amz-Signature", valid_402656872
  var valid_402656873 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656873 = validateParameter(valid_402656873, JString,
                                      required = false, default = nil)
  if valid_402656873 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656873
  var valid_402656874 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656874 = validateParameter(valid_402656874, JString,
                                      required = false, default = nil)
  if valid_402656874 != nil:
    section.add "X-Amz-Algorithm", valid_402656874
  var valid_402656875 = header.getOrDefault("X-Amz-Date")
  valid_402656875 = validateParameter(valid_402656875, JString,
                                      required = false, default = nil)
  if valid_402656875 != nil:
    section.add "X-Amz-Date", valid_402656875
  var valid_402656876 = header.getOrDefault("X-Amz-Credential")
  valid_402656876 = validateParameter(valid_402656876, JString,
                                      required = false, default = nil)
  if valid_402656876 != nil:
    section.add "X-Amz-Credential", valid_402656876
  var valid_402656877 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656877 = validateParameter(valid_402656877, JString,
                                      required = false, default = nil)
  if valid_402656877 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656877
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656879: Call_UpdateComponentConfiguration_402656867;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the monitoring configurations for the component. The configuration input parameter is an escaped JSON of the configuration and should match the schema of what is returned by <code>DescribeComponentConfigurationRecommendation</code>. 
                                                                                         ## 
  let valid = call_402656879.validator(path, query, header, formData, body, _)
  let scheme = call_402656879.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656879.makeUrl(scheme.get, call_402656879.host, call_402656879.base,
                                   call_402656879.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656879, uri, valid, _)

proc call*(call_402656880: Call_UpdateComponentConfiguration_402656867;
           body: JsonNode): Recallable =
  ## updateComponentConfiguration
  ## Updates the monitoring configurations for the component. The configuration input parameter is an escaped JSON of the configuration and should match the schema of what is returned by <code>DescribeComponentConfigurationRecommendation</code>. 
  ##   
                                                                                                                                                                                                                                                      ## body: JObject (required)
  var body_402656881 = newJObject()
  if body != nil:
    body_402656881 = body
  result = call_402656880.call(nil, nil, nil, nil, body_402656881)

var updateComponentConfiguration* = Call_UpdateComponentConfiguration_402656867(
    name: "updateComponentConfiguration", meth: HttpMethod.HttpPost,
    host: "applicationinsights.amazonaws.com", route: "/#X-Amz-Target=EC2WindowsBarleyService.UpdateComponentConfiguration",
    validator: validate_UpdateComponentConfiguration_402656868, base: "/",
    makeUrl: url_UpdateComponentConfiguration_402656869,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateLogPattern_402656882 = ref object of OpenApiRestCall_402656044
proc url_UpdateLogPattern_402656884(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateLogPattern_402656883(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656885 = header.getOrDefault("X-Amz-Target")
  valid_402656885 = validateParameter(valid_402656885, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.UpdateLogPattern"))
  if valid_402656885 != nil:
    section.add "X-Amz-Target", valid_402656885
  var valid_402656886 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656886 = validateParameter(valid_402656886, JString,
                                      required = false, default = nil)
  if valid_402656886 != nil:
    section.add "X-Amz-Security-Token", valid_402656886
  var valid_402656887 = header.getOrDefault("X-Amz-Signature")
  valid_402656887 = validateParameter(valid_402656887, JString,
                                      required = false, default = nil)
  if valid_402656887 != nil:
    section.add "X-Amz-Signature", valid_402656887
  var valid_402656888 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656888 = validateParameter(valid_402656888, JString,
                                      required = false, default = nil)
  if valid_402656888 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656888
  var valid_402656889 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656889 = validateParameter(valid_402656889, JString,
                                      required = false, default = nil)
  if valid_402656889 != nil:
    section.add "X-Amz-Algorithm", valid_402656889
  var valid_402656890 = header.getOrDefault("X-Amz-Date")
  valid_402656890 = validateParameter(valid_402656890, JString,
                                      required = false, default = nil)
  if valid_402656890 != nil:
    section.add "X-Amz-Date", valid_402656890
  var valid_402656891 = header.getOrDefault("X-Amz-Credential")
  valid_402656891 = validateParameter(valid_402656891, JString,
                                      required = false, default = nil)
  if valid_402656891 != nil:
    section.add "X-Amz-Credential", valid_402656891
  var valid_402656892 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656892 = validateParameter(valid_402656892, JString,
                                      required = false, default = nil)
  if valid_402656892 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656892
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656894: Call_UpdateLogPattern_402656882;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds a log pattern to a <code>LogPatternSet</code>.
                                                                                         ## 
  let valid = call_402656894.validator(path, query, header, formData, body, _)
  let scheme = call_402656894.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656894.makeUrl(scheme.get, call_402656894.host, call_402656894.base,
                                   call_402656894.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656894, uri, valid, _)

proc call*(call_402656895: Call_UpdateLogPattern_402656882; body: JsonNode): Recallable =
  ## updateLogPattern
  ## Adds a log pattern to a <code>LogPatternSet</code>.
  ##   body: JObject (required)
  var body_402656896 = newJObject()
  if body != nil:
    body_402656896 = body
  result = call_402656895.call(nil, nil, nil, nil, body_402656896)

var updateLogPattern* = Call_UpdateLogPattern_402656882(
    name: "updateLogPattern", meth: HttpMethod.HttpPost,
    host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.UpdateLogPattern",
    validator: validate_UpdateLogPattern_402656883, base: "/",
    makeUrl: url_UpdateLogPattern_402656884,
    schemes: {Scheme.Https, Scheme.Http})
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
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token",
    ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode;
              algo: SigningAlgo = SHA256) =
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
    scope = credentialScope(region = region, service = awsServiceName,
                            date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers,
                               recall.body, normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date,
                                   region = region, service = awsServiceName,
                                   sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}
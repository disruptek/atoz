
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_772597 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_772597](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_772597): Option[Scheme] {.used.} =
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
proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get())

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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_CreateApplication_772933 = ref object of OpenApiRestCall_772597
proc url_CreateApplication_772935(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateApplication_772934(path: JsonNode; query: JsonNode;
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
  var valid_773047 = header.getOrDefault("X-Amz-Date")
  valid_773047 = validateParameter(valid_773047, JString, required = false,
                                 default = nil)
  if valid_773047 != nil:
    section.add "X-Amz-Date", valid_773047
  var valid_773048 = header.getOrDefault("X-Amz-Security-Token")
  valid_773048 = validateParameter(valid_773048, JString, required = false,
                                 default = nil)
  if valid_773048 != nil:
    section.add "X-Amz-Security-Token", valid_773048
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773062 = header.getOrDefault("X-Amz-Target")
  valid_773062 = validateParameter(valid_773062, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.CreateApplication"))
  if valid_773062 != nil:
    section.add "X-Amz-Target", valid_773062
  var valid_773063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773063 = validateParameter(valid_773063, JString, required = false,
                                 default = nil)
  if valid_773063 != nil:
    section.add "X-Amz-Content-Sha256", valid_773063
  var valid_773064 = header.getOrDefault("X-Amz-Algorithm")
  valid_773064 = validateParameter(valid_773064, JString, required = false,
                                 default = nil)
  if valid_773064 != nil:
    section.add "X-Amz-Algorithm", valid_773064
  var valid_773065 = header.getOrDefault("X-Amz-Signature")
  valid_773065 = validateParameter(valid_773065, JString, required = false,
                                 default = nil)
  if valid_773065 != nil:
    section.add "X-Amz-Signature", valid_773065
  var valid_773066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773066 = validateParameter(valid_773066, JString, required = false,
                                 default = nil)
  if valid_773066 != nil:
    section.add "X-Amz-SignedHeaders", valid_773066
  var valid_773067 = header.getOrDefault("X-Amz-Credential")
  valid_773067 = validateParameter(valid_773067, JString, required = false,
                                 default = nil)
  if valid_773067 != nil:
    section.add "X-Amz-Credential", valid_773067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773091: Call_CreateApplication_772933; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds an application that is created from a resource group.
  ## 
  let valid = call_773091.validator(path, query, header, formData, body)
  let scheme = call_773091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773091.url(scheme.get, call_773091.host, call_773091.base,
                         call_773091.route, valid.getOrDefault("path"))
  result = hook(call_773091, url, valid)

proc call*(call_773162: Call_CreateApplication_772933; body: JsonNode): Recallable =
  ## createApplication
  ## Adds an application that is created from a resource group.
  ##   body: JObject (required)
  var body_773163 = newJObject()
  if body != nil:
    body_773163 = body
  result = call_773162.call(nil, nil, nil, nil, body_773163)

var createApplication* = Call_CreateApplication_772933(name: "createApplication",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.CreateApplication",
    validator: validate_CreateApplication_772934, base: "/",
    url: url_CreateApplication_772935, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateComponent_773202 = ref object of OpenApiRestCall_772597
proc url_CreateComponent_773204(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateComponent_773203(path: JsonNode; query: JsonNode;
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
  var valid_773205 = header.getOrDefault("X-Amz-Date")
  valid_773205 = validateParameter(valid_773205, JString, required = false,
                                 default = nil)
  if valid_773205 != nil:
    section.add "X-Amz-Date", valid_773205
  var valid_773206 = header.getOrDefault("X-Amz-Security-Token")
  valid_773206 = validateParameter(valid_773206, JString, required = false,
                                 default = nil)
  if valid_773206 != nil:
    section.add "X-Amz-Security-Token", valid_773206
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773207 = header.getOrDefault("X-Amz-Target")
  valid_773207 = validateParameter(valid_773207, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.CreateComponent"))
  if valid_773207 != nil:
    section.add "X-Amz-Target", valid_773207
  var valid_773208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773208 = validateParameter(valid_773208, JString, required = false,
                                 default = nil)
  if valid_773208 != nil:
    section.add "X-Amz-Content-Sha256", valid_773208
  var valid_773209 = header.getOrDefault("X-Amz-Algorithm")
  valid_773209 = validateParameter(valid_773209, JString, required = false,
                                 default = nil)
  if valid_773209 != nil:
    section.add "X-Amz-Algorithm", valid_773209
  var valid_773210 = header.getOrDefault("X-Amz-Signature")
  valid_773210 = validateParameter(valid_773210, JString, required = false,
                                 default = nil)
  if valid_773210 != nil:
    section.add "X-Amz-Signature", valid_773210
  var valid_773211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773211 = validateParameter(valid_773211, JString, required = false,
                                 default = nil)
  if valid_773211 != nil:
    section.add "X-Amz-SignedHeaders", valid_773211
  var valid_773212 = header.getOrDefault("X-Amz-Credential")
  valid_773212 = validateParameter(valid_773212, JString, required = false,
                                 default = nil)
  if valid_773212 != nil:
    section.add "X-Amz-Credential", valid_773212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773214: Call_CreateComponent_773202; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a custom component by grouping similar standalone instances to monitor.
  ## 
  let valid = call_773214.validator(path, query, header, formData, body)
  let scheme = call_773214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773214.url(scheme.get, call_773214.host, call_773214.base,
                         call_773214.route, valid.getOrDefault("path"))
  result = hook(call_773214, url, valid)

proc call*(call_773215: Call_CreateComponent_773202; body: JsonNode): Recallable =
  ## createComponent
  ## Creates a custom component by grouping similar standalone instances to monitor.
  ##   body: JObject (required)
  var body_773216 = newJObject()
  if body != nil:
    body_773216 = body
  result = call_773215.call(nil, nil, nil, nil, body_773216)

var createComponent* = Call_CreateComponent_773202(name: "createComponent",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.CreateComponent",
    validator: validate_CreateComponent_773203, base: "/", url: url_CreateComponent_773204,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApplication_773217 = ref object of OpenApiRestCall_772597
proc url_DeleteApplication_773219(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteApplication_773218(path: JsonNode; query: JsonNode;
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
  var valid_773220 = header.getOrDefault("X-Amz-Date")
  valid_773220 = validateParameter(valid_773220, JString, required = false,
                                 default = nil)
  if valid_773220 != nil:
    section.add "X-Amz-Date", valid_773220
  var valid_773221 = header.getOrDefault("X-Amz-Security-Token")
  valid_773221 = validateParameter(valid_773221, JString, required = false,
                                 default = nil)
  if valid_773221 != nil:
    section.add "X-Amz-Security-Token", valid_773221
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773222 = header.getOrDefault("X-Amz-Target")
  valid_773222 = validateParameter(valid_773222, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.DeleteApplication"))
  if valid_773222 != nil:
    section.add "X-Amz-Target", valid_773222
  var valid_773223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773223 = validateParameter(valid_773223, JString, required = false,
                                 default = nil)
  if valid_773223 != nil:
    section.add "X-Amz-Content-Sha256", valid_773223
  var valid_773224 = header.getOrDefault("X-Amz-Algorithm")
  valid_773224 = validateParameter(valid_773224, JString, required = false,
                                 default = nil)
  if valid_773224 != nil:
    section.add "X-Amz-Algorithm", valid_773224
  var valid_773225 = header.getOrDefault("X-Amz-Signature")
  valid_773225 = validateParameter(valid_773225, JString, required = false,
                                 default = nil)
  if valid_773225 != nil:
    section.add "X-Amz-Signature", valid_773225
  var valid_773226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773226 = validateParameter(valid_773226, JString, required = false,
                                 default = nil)
  if valid_773226 != nil:
    section.add "X-Amz-SignedHeaders", valid_773226
  var valid_773227 = header.getOrDefault("X-Amz-Credential")
  valid_773227 = validateParameter(valid_773227, JString, required = false,
                                 default = nil)
  if valid_773227 != nil:
    section.add "X-Amz-Credential", valid_773227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773229: Call_DeleteApplication_773217; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified application from monitoring. Does not delete the application.
  ## 
  let valid = call_773229.validator(path, query, header, formData, body)
  let scheme = call_773229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773229.url(scheme.get, call_773229.host, call_773229.base,
                         call_773229.route, valid.getOrDefault("path"))
  result = hook(call_773229, url, valid)

proc call*(call_773230: Call_DeleteApplication_773217; body: JsonNode): Recallable =
  ## deleteApplication
  ## Removes the specified application from monitoring. Does not delete the application.
  ##   body: JObject (required)
  var body_773231 = newJObject()
  if body != nil:
    body_773231 = body
  result = call_773230.call(nil, nil, nil, nil, body_773231)

var deleteApplication* = Call_DeleteApplication_773217(name: "deleteApplication",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.DeleteApplication",
    validator: validate_DeleteApplication_773218, base: "/",
    url: url_DeleteApplication_773219, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteComponent_773232 = ref object of OpenApiRestCall_772597
proc url_DeleteComponent_773234(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteComponent_773233(path: JsonNode; query: JsonNode;
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
  var valid_773235 = header.getOrDefault("X-Amz-Date")
  valid_773235 = validateParameter(valid_773235, JString, required = false,
                                 default = nil)
  if valid_773235 != nil:
    section.add "X-Amz-Date", valid_773235
  var valid_773236 = header.getOrDefault("X-Amz-Security-Token")
  valid_773236 = validateParameter(valid_773236, JString, required = false,
                                 default = nil)
  if valid_773236 != nil:
    section.add "X-Amz-Security-Token", valid_773236
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773237 = header.getOrDefault("X-Amz-Target")
  valid_773237 = validateParameter(valid_773237, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.DeleteComponent"))
  if valid_773237 != nil:
    section.add "X-Amz-Target", valid_773237
  var valid_773238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773238 = validateParameter(valid_773238, JString, required = false,
                                 default = nil)
  if valid_773238 != nil:
    section.add "X-Amz-Content-Sha256", valid_773238
  var valid_773239 = header.getOrDefault("X-Amz-Algorithm")
  valid_773239 = validateParameter(valid_773239, JString, required = false,
                                 default = nil)
  if valid_773239 != nil:
    section.add "X-Amz-Algorithm", valid_773239
  var valid_773240 = header.getOrDefault("X-Amz-Signature")
  valid_773240 = validateParameter(valid_773240, JString, required = false,
                                 default = nil)
  if valid_773240 != nil:
    section.add "X-Amz-Signature", valid_773240
  var valid_773241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773241 = validateParameter(valid_773241, JString, required = false,
                                 default = nil)
  if valid_773241 != nil:
    section.add "X-Amz-SignedHeaders", valid_773241
  var valid_773242 = header.getOrDefault("X-Amz-Credential")
  valid_773242 = validateParameter(valid_773242, JString, required = false,
                                 default = nil)
  if valid_773242 != nil:
    section.add "X-Amz-Credential", valid_773242
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773244: Call_DeleteComponent_773232; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Ungroups a custom component. When you ungroup custom components, all applicable monitors that are set up for the component are removed and the instances revert to their standalone status.
  ## 
  let valid = call_773244.validator(path, query, header, formData, body)
  let scheme = call_773244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773244.url(scheme.get, call_773244.host, call_773244.base,
                         call_773244.route, valid.getOrDefault("path"))
  result = hook(call_773244, url, valid)

proc call*(call_773245: Call_DeleteComponent_773232; body: JsonNode): Recallable =
  ## deleteComponent
  ## Ungroups a custom component. When you ungroup custom components, all applicable monitors that are set up for the component are removed and the instances revert to their standalone status.
  ##   body: JObject (required)
  var body_773246 = newJObject()
  if body != nil:
    body_773246 = body
  result = call_773245.call(nil, nil, nil, nil, body_773246)

var deleteComponent* = Call_DeleteComponent_773232(name: "deleteComponent",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.DeleteComponent",
    validator: validate_DeleteComponent_773233, base: "/", url: url_DeleteComponent_773234,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeApplication_773247 = ref object of OpenApiRestCall_772597
proc url_DescribeApplication_773249(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeApplication_773248(path: JsonNode; query: JsonNode;
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
  var valid_773250 = header.getOrDefault("X-Amz-Date")
  valid_773250 = validateParameter(valid_773250, JString, required = false,
                                 default = nil)
  if valid_773250 != nil:
    section.add "X-Amz-Date", valid_773250
  var valid_773251 = header.getOrDefault("X-Amz-Security-Token")
  valid_773251 = validateParameter(valid_773251, JString, required = false,
                                 default = nil)
  if valid_773251 != nil:
    section.add "X-Amz-Security-Token", valid_773251
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773252 = header.getOrDefault("X-Amz-Target")
  valid_773252 = validateParameter(valid_773252, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.DescribeApplication"))
  if valid_773252 != nil:
    section.add "X-Amz-Target", valid_773252
  var valid_773253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773253 = validateParameter(valid_773253, JString, required = false,
                                 default = nil)
  if valid_773253 != nil:
    section.add "X-Amz-Content-Sha256", valid_773253
  var valid_773254 = header.getOrDefault("X-Amz-Algorithm")
  valid_773254 = validateParameter(valid_773254, JString, required = false,
                                 default = nil)
  if valid_773254 != nil:
    section.add "X-Amz-Algorithm", valid_773254
  var valid_773255 = header.getOrDefault("X-Amz-Signature")
  valid_773255 = validateParameter(valid_773255, JString, required = false,
                                 default = nil)
  if valid_773255 != nil:
    section.add "X-Amz-Signature", valid_773255
  var valid_773256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773256 = validateParameter(valid_773256, JString, required = false,
                                 default = nil)
  if valid_773256 != nil:
    section.add "X-Amz-SignedHeaders", valid_773256
  var valid_773257 = header.getOrDefault("X-Amz-Credential")
  valid_773257 = validateParameter(valid_773257, JString, required = false,
                                 default = nil)
  if valid_773257 != nil:
    section.add "X-Amz-Credential", valid_773257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773259: Call_DescribeApplication_773247; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the application.
  ## 
  let valid = call_773259.validator(path, query, header, formData, body)
  let scheme = call_773259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773259.url(scheme.get, call_773259.host, call_773259.base,
                         call_773259.route, valid.getOrDefault("path"))
  result = hook(call_773259, url, valid)

proc call*(call_773260: Call_DescribeApplication_773247; body: JsonNode): Recallable =
  ## describeApplication
  ## Describes the application.
  ##   body: JObject (required)
  var body_773261 = newJObject()
  if body != nil:
    body_773261 = body
  result = call_773260.call(nil, nil, nil, nil, body_773261)

var describeApplication* = Call_DescribeApplication_773247(
    name: "describeApplication", meth: HttpMethod.HttpPost,
    host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.DescribeApplication",
    validator: validate_DescribeApplication_773248, base: "/",
    url: url_DescribeApplication_773249, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeComponent_773262 = ref object of OpenApiRestCall_772597
proc url_DescribeComponent_773264(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeComponent_773263(path: JsonNode; query: JsonNode;
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
  var valid_773265 = header.getOrDefault("X-Amz-Date")
  valid_773265 = validateParameter(valid_773265, JString, required = false,
                                 default = nil)
  if valid_773265 != nil:
    section.add "X-Amz-Date", valid_773265
  var valid_773266 = header.getOrDefault("X-Amz-Security-Token")
  valid_773266 = validateParameter(valid_773266, JString, required = false,
                                 default = nil)
  if valid_773266 != nil:
    section.add "X-Amz-Security-Token", valid_773266
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773267 = header.getOrDefault("X-Amz-Target")
  valid_773267 = validateParameter(valid_773267, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.DescribeComponent"))
  if valid_773267 != nil:
    section.add "X-Amz-Target", valid_773267
  var valid_773268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773268 = validateParameter(valid_773268, JString, required = false,
                                 default = nil)
  if valid_773268 != nil:
    section.add "X-Amz-Content-Sha256", valid_773268
  var valid_773269 = header.getOrDefault("X-Amz-Algorithm")
  valid_773269 = validateParameter(valid_773269, JString, required = false,
                                 default = nil)
  if valid_773269 != nil:
    section.add "X-Amz-Algorithm", valid_773269
  var valid_773270 = header.getOrDefault("X-Amz-Signature")
  valid_773270 = validateParameter(valid_773270, JString, required = false,
                                 default = nil)
  if valid_773270 != nil:
    section.add "X-Amz-Signature", valid_773270
  var valid_773271 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773271 = validateParameter(valid_773271, JString, required = false,
                                 default = nil)
  if valid_773271 != nil:
    section.add "X-Amz-SignedHeaders", valid_773271
  var valid_773272 = header.getOrDefault("X-Amz-Credential")
  valid_773272 = validateParameter(valid_773272, JString, required = false,
                                 default = nil)
  if valid_773272 != nil:
    section.add "X-Amz-Credential", valid_773272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773274: Call_DescribeComponent_773262; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a component and lists the resources that are grouped together in a component.
  ## 
  let valid = call_773274.validator(path, query, header, formData, body)
  let scheme = call_773274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773274.url(scheme.get, call_773274.host, call_773274.base,
                         call_773274.route, valid.getOrDefault("path"))
  result = hook(call_773274, url, valid)

proc call*(call_773275: Call_DescribeComponent_773262; body: JsonNode): Recallable =
  ## describeComponent
  ## Describes a component and lists the resources that are grouped together in a component.
  ##   body: JObject (required)
  var body_773276 = newJObject()
  if body != nil:
    body_773276 = body
  result = call_773275.call(nil, nil, nil, nil, body_773276)

var describeComponent* = Call_DescribeComponent_773262(name: "describeComponent",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.DescribeComponent",
    validator: validate_DescribeComponent_773263, base: "/",
    url: url_DescribeComponent_773264, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeComponentConfiguration_773277 = ref object of OpenApiRestCall_772597
proc url_DescribeComponentConfiguration_773279(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeComponentConfiguration_773278(path: JsonNode;
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
  var valid_773280 = header.getOrDefault("X-Amz-Date")
  valid_773280 = validateParameter(valid_773280, JString, required = false,
                                 default = nil)
  if valid_773280 != nil:
    section.add "X-Amz-Date", valid_773280
  var valid_773281 = header.getOrDefault("X-Amz-Security-Token")
  valid_773281 = validateParameter(valid_773281, JString, required = false,
                                 default = nil)
  if valid_773281 != nil:
    section.add "X-Amz-Security-Token", valid_773281
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773282 = header.getOrDefault("X-Amz-Target")
  valid_773282 = validateParameter(valid_773282, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.DescribeComponentConfiguration"))
  if valid_773282 != nil:
    section.add "X-Amz-Target", valid_773282
  var valid_773283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773283 = validateParameter(valid_773283, JString, required = false,
                                 default = nil)
  if valid_773283 != nil:
    section.add "X-Amz-Content-Sha256", valid_773283
  var valid_773284 = header.getOrDefault("X-Amz-Algorithm")
  valid_773284 = validateParameter(valid_773284, JString, required = false,
                                 default = nil)
  if valid_773284 != nil:
    section.add "X-Amz-Algorithm", valid_773284
  var valid_773285 = header.getOrDefault("X-Amz-Signature")
  valid_773285 = validateParameter(valid_773285, JString, required = false,
                                 default = nil)
  if valid_773285 != nil:
    section.add "X-Amz-Signature", valid_773285
  var valid_773286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773286 = validateParameter(valid_773286, JString, required = false,
                                 default = nil)
  if valid_773286 != nil:
    section.add "X-Amz-SignedHeaders", valid_773286
  var valid_773287 = header.getOrDefault("X-Amz-Credential")
  valid_773287 = validateParameter(valid_773287, JString, required = false,
                                 default = nil)
  if valid_773287 != nil:
    section.add "X-Amz-Credential", valid_773287
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773289: Call_DescribeComponentConfiguration_773277; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the monitoring configuration of the component.
  ## 
  let valid = call_773289.validator(path, query, header, formData, body)
  let scheme = call_773289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773289.url(scheme.get, call_773289.host, call_773289.base,
                         call_773289.route, valid.getOrDefault("path"))
  result = hook(call_773289, url, valid)

proc call*(call_773290: Call_DescribeComponentConfiguration_773277; body: JsonNode): Recallable =
  ## describeComponentConfiguration
  ## Describes the monitoring configuration of the component.
  ##   body: JObject (required)
  var body_773291 = newJObject()
  if body != nil:
    body_773291 = body
  result = call_773290.call(nil, nil, nil, nil, body_773291)

var describeComponentConfiguration* = Call_DescribeComponentConfiguration_773277(
    name: "describeComponentConfiguration", meth: HttpMethod.HttpPost,
    host: "applicationinsights.amazonaws.com", route: "/#X-Amz-Target=EC2WindowsBarleyService.DescribeComponentConfiguration",
    validator: validate_DescribeComponentConfiguration_773278, base: "/",
    url: url_DescribeComponentConfiguration_773279,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeComponentConfigurationRecommendation_773292 = ref object of OpenApiRestCall_772597
proc url_DescribeComponentConfigurationRecommendation_773294(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeComponentConfigurationRecommendation_773293(path: JsonNode;
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
  var valid_773295 = header.getOrDefault("X-Amz-Date")
  valid_773295 = validateParameter(valid_773295, JString, required = false,
                                 default = nil)
  if valid_773295 != nil:
    section.add "X-Amz-Date", valid_773295
  var valid_773296 = header.getOrDefault("X-Amz-Security-Token")
  valid_773296 = validateParameter(valid_773296, JString, required = false,
                                 default = nil)
  if valid_773296 != nil:
    section.add "X-Amz-Security-Token", valid_773296
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773297 = header.getOrDefault("X-Amz-Target")
  valid_773297 = validateParameter(valid_773297, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.DescribeComponentConfigurationRecommendation"))
  if valid_773297 != nil:
    section.add "X-Amz-Target", valid_773297
  var valid_773298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773298 = validateParameter(valid_773298, JString, required = false,
                                 default = nil)
  if valid_773298 != nil:
    section.add "X-Amz-Content-Sha256", valid_773298
  var valid_773299 = header.getOrDefault("X-Amz-Algorithm")
  valid_773299 = validateParameter(valid_773299, JString, required = false,
                                 default = nil)
  if valid_773299 != nil:
    section.add "X-Amz-Algorithm", valid_773299
  var valid_773300 = header.getOrDefault("X-Amz-Signature")
  valid_773300 = validateParameter(valid_773300, JString, required = false,
                                 default = nil)
  if valid_773300 != nil:
    section.add "X-Amz-Signature", valid_773300
  var valid_773301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773301 = validateParameter(valid_773301, JString, required = false,
                                 default = nil)
  if valid_773301 != nil:
    section.add "X-Amz-SignedHeaders", valid_773301
  var valid_773302 = header.getOrDefault("X-Amz-Credential")
  valid_773302 = validateParameter(valid_773302, JString, required = false,
                                 default = nil)
  if valid_773302 != nil:
    section.add "X-Amz-Credential", valid_773302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773304: Call_DescribeComponentConfigurationRecommendation_773292;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the recommended monitoring configuration of the component.
  ## 
  let valid = call_773304.validator(path, query, header, formData, body)
  let scheme = call_773304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773304.url(scheme.get, call_773304.host, call_773304.base,
                         call_773304.route, valid.getOrDefault("path"))
  result = hook(call_773304, url, valid)

proc call*(call_773305: Call_DescribeComponentConfigurationRecommendation_773292;
          body: JsonNode): Recallable =
  ## describeComponentConfigurationRecommendation
  ## Describes the recommended monitoring configuration of the component.
  ##   body: JObject (required)
  var body_773306 = newJObject()
  if body != nil:
    body_773306 = body
  result = call_773305.call(nil, nil, nil, nil, body_773306)

var describeComponentConfigurationRecommendation* = Call_DescribeComponentConfigurationRecommendation_773292(
    name: "describeComponentConfigurationRecommendation",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com", route: "/#X-Amz-Target=EC2WindowsBarleyService.DescribeComponentConfigurationRecommendation",
    validator: validate_DescribeComponentConfigurationRecommendation_773293,
    base: "/", url: url_DescribeComponentConfigurationRecommendation_773294,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeObservation_773307 = ref object of OpenApiRestCall_772597
proc url_DescribeObservation_773309(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeObservation_773308(path: JsonNode; query: JsonNode;
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
  var valid_773310 = header.getOrDefault("X-Amz-Date")
  valid_773310 = validateParameter(valid_773310, JString, required = false,
                                 default = nil)
  if valid_773310 != nil:
    section.add "X-Amz-Date", valid_773310
  var valid_773311 = header.getOrDefault("X-Amz-Security-Token")
  valid_773311 = validateParameter(valid_773311, JString, required = false,
                                 default = nil)
  if valid_773311 != nil:
    section.add "X-Amz-Security-Token", valid_773311
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773312 = header.getOrDefault("X-Amz-Target")
  valid_773312 = validateParameter(valid_773312, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.DescribeObservation"))
  if valid_773312 != nil:
    section.add "X-Amz-Target", valid_773312
  var valid_773313 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773313 = validateParameter(valid_773313, JString, required = false,
                                 default = nil)
  if valid_773313 != nil:
    section.add "X-Amz-Content-Sha256", valid_773313
  var valid_773314 = header.getOrDefault("X-Amz-Algorithm")
  valid_773314 = validateParameter(valid_773314, JString, required = false,
                                 default = nil)
  if valid_773314 != nil:
    section.add "X-Amz-Algorithm", valid_773314
  var valid_773315 = header.getOrDefault("X-Amz-Signature")
  valid_773315 = validateParameter(valid_773315, JString, required = false,
                                 default = nil)
  if valid_773315 != nil:
    section.add "X-Amz-Signature", valid_773315
  var valid_773316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773316 = validateParameter(valid_773316, JString, required = false,
                                 default = nil)
  if valid_773316 != nil:
    section.add "X-Amz-SignedHeaders", valid_773316
  var valid_773317 = header.getOrDefault("X-Amz-Credential")
  valid_773317 = validateParameter(valid_773317, JString, required = false,
                                 default = nil)
  if valid_773317 != nil:
    section.add "X-Amz-Credential", valid_773317
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773319: Call_DescribeObservation_773307; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an anomaly or error with the application.
  ## 
  let valid = call_773319.validator(path, query, header, formData, body)
  let scheme = call_773319.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773319.url(scheme.get, call_773319.host, call_773319.base,
                         call_773319.route, valid.getOrDefault("path"))
  result = hook(call_773319, url, valid)

proc call*(call_773320: Call_DescribeObservation_773307; body: JsonNode): Recallable =
  ## describeObservation
  ## Describes an anomaly or error with the application.
  ##   body: JObject (required)
  var body_773321 = newJObject()
  if body != nil:
    body_773321 = body
  result = call_773320.call(nil, nil, nil, nil, body_773321)

var describeObservation* = Call_DescribeObservation_773307(
    name: "describeObservation", meth: HttpMethod.HttpPost,
    host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.DescribeObservation",
    validator: validate_DescribeObservation_773308, base: "/",
    url: url_DescribeObservation_773309, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProblem_773322 = ref object of OpenApiRestCall_772597
proc url_DescribeProblem_773324(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeProblem_773323(path: JsonNode; query: JsonNode;
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
  var valid_773325 = header.getOrDefault("X-Amz-Date")
  valid_773325 = validateParameter(valid_773325, JString, required = false,
                                 default = nil)
  if valid_773325 != nil:
    section.add "X-Amz-Date", valid_773325
  var valid_773326 = header.getOrDefault("X-Amz-Security-Token")
  valid_773326 = validateParameter(valid_773326, JString, required = false,
                                 default = nil)
  if valid_773326 != nil:
    section.add "X-Amz-Security-Token", valid_773326
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773327 = header.getOrDefault("X-Amz-Target")
  valid_773327 = validateParameter(valid_773327, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.DescribeProblem"))
  if valid_773327 != nil:
    section.add "X-Amz-Target", valid_773327
  var valid_773328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773328 = validateParameter(valid_773328, JString, required = false,
                                 default = nil)
  if valid_773328 != nil:
    section.add "X-Amz-Content-Sha256", valid_773328
  var valid_773329 = header.getOrDefault("X-Amz-Algorithm")
  valid_773329 = validateParameter(valid_773329, JString, required = false,
                                 default = nil)
  if valid_773329 != nil:
    section.add "X-Amz-Algorithm", valid_773329
  var valid_773330 = header.getOrDefault("X-Amz-Signature")
  valid_773330 = validateParameter(valid_773330, JString, required = false,
                                 default = nil)
  if valid_773330 != nil:
    section.add "X-Amz-Signature", valid_773330
  var valid_773331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773331 = validateParameter(valid_773331, JString, required = false,
                                 default = nil)
  if valid_773331 != nil:
    section.add "X-Amz-SignedHeaders", valid_773331
  var valid_773332 = header.getOrDefault("X-Amz-Credential")
  valid_773332 = validateParameter(valid_773332, JString, required = false,
                                 default = nil)
  if valid_773332 != nil:
    section.add "X-Amz-Credential", valid_773332
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773334: Call_DescribeProblem_773322; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an application problem.
  ## 
  let valid = call_773334.validator(path, query, header, formData, body)
  let scheme = call_773334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773334.url(scheme.get, call_773334.host, call_773334.base,
                         call_773334.route, valid.getOrDefault("path"))
  result = hook(call_773334, url, valid)

proc call*(call_773335: Call_DescribeProblem_773322; body: JsonNode): Recallable =
  ## describeProblem
  ## Describes an application problem.
  ##   body: JObject (required)
  var body_773336 = newJObject()
  if body != nil:
    body_773336 = body
  result = call_773335.call(nil, nil, nil, nil, body_773336)

var describeProblem* = Call_DescribeProblem_773322(name: "describeProblem",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.DescribeProblem",
    validator: validate_DescribeProblem_773323, base: "/", url: url_DescribeProblem_773324,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProblemObservations_773337 = ref object of OpenApiRestCall_772597
proc url_DescribeProblemObservations_773339(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeProblemObservations_773338(path: JsonNode; query: JsonNode;
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
  var valid_773340 = header.getOrDefault("X-Amz-Date")
  valid_773340 = validateParameter(valid_773340, JString, required = false,
                                 default = nil)
  if valid_773340 != nil:
    section.add "X-Amz-Date", valid_773340
  var valid_773341 = header.getOrDefault("X-Amz-Security-Token")
  valid_773341 = validateParameter(valid_773341, JString, required = false,
                                 default = nil)
  if valid_773341 != nil:
    section.add "X-Amz-Security-Token", valid_773341
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773342 = header.getOrDefault("X-Amz-Target")
  valid_773342 = validateParameter(valid_773342, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.DescribeProblemObservations"))
  if valid_773342 != nil:
    section.add "X-Amz-Target", valid_773342
  var valid_773343 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773343 = validateParameter(valid_773343, JString, required = false,
                                 default = nil)
  if valid_773343 != nil:
    section.add "X-Amz-Content-Sha256", valid_773343
  var valid_773344 = header.getOrDefault("X-Amz-Algorithm")
  valid_773344 = validateParameter(valid_773344, JString, required = false,
                                 default = nil)
  if valid_773344 != nil:
    section.add "X-Amz-Algorithm", valid_773344
  var valid_773345 = header.getOrDefault("X-Amz-Signature")
  valid_773345 = validateParameter(valid_773345, JString, required = false,
                                 default = nil)
  if valid_773345 != nil:
    section.add "X-Amz-Signature", valid_773345
  var valid_773346 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773346 = validateParameter(valid_773346, JString, required = false,
                                 default = nil)
  if valid_773346 != nil:
    section.add "X-Amz-SignedHeaders", valid_773346
  var valid_773347 = header.getOrDefault("X-Amz-Credential")
  valid_773347 = validateParameter(valid_773347, JString, required = false,
                                 default = nil)
  if valid_773347 != nil:
    section.add "X-Amz-Credential", valid_773347
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773349: Call_DescribeProblemObservations_773337; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the anomalies or errors associated with the problem.
  ## 
  let valid = call_773349.validator(path, query, header, formData, body)
  let scheme = call_773349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773349.url(scheme.get, call_773349.host, call_773349.base,
                         call_773349.route, valid.getOrDefault("path"))
  result = hook(call_773349, url, valid)

proc call*(call_773350: Call_DescribeProblemObservations_773337; body: JsonNode): Recallable =
  ## describeProblemObservations
  ## Describes the anomalies or errors associated with the problem.
  ##   body: JObject (required)
  var body_773351 = newJObject()
  if body != nil:
    body_773351 = body
  result = call_773350.call(nil, nil, nil, nil, body_773351)

var describeProblemObservations* = Call_DescribeProblemObservations_773337(
    name: "describeProblemObservations", meth: HttpMethod.HttpPost,
    host: "applicationinsights.amazonaws.com", route: "/#X-Amz-Target=EC2WindowsBarleyService.DescribeProblemObservations",
    validator: validate_DescribeProblemObservations_773338, base: "/",
    url: url_DescribeProblemObservations_773339,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApplications_773352 = ref object of OpenApiRestCall_772597
proc url_ListApplications_773354(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListApplications_773353(path: JsonNode; query: JsonNode;
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
  var valid_773355 = query.getOrDefault("NextToken")
  valid_773355 = validateParameter(valid_773355, JString, required = false,
                                 default = nil)
  if valid_773355 != nil:
    section.add "NextToken", valid_773355
  var valid_773356 = query.getOrDefault("MaxResults")
  valid_773356 = validateParameter(valid_773356, JString, required = false,
                                 default = nil)
  if valid_773356 != nil:
    section.add "MaxResults", valid_773356
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
  var valid_773357 = header.getOrDefault("X-Amz-Date")
  valid_773357 = validateParameter(valid_773357, JString, required = false,
                                 default = nil)
  if valid_773357 != nil:
    section.add "X-Amz-Date", valid_773357
  var valid_773358 = header.getOrDefault("X-Amz-Security-Token")
  valid_773358 = validateParameter(valid_773358, JString, required = false,
                                 default = nil)
  if valid_773358 != nil:
    section.add "X-Amz-Security-Token", valid_773358
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773359 = header.getOrDefault("X-Amz-Target")
  valid_773359 = validateParameter(valid_773359, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.ListApplications"))
  if valid_773359 != nil:
    section.add "X-Amz-Target", valid_773359
  var valid_773360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773360 = validateParameter(valid_773360, JString, required = false,
                                 default = nil)
  if valid_773360 != nil:
    section.add "X-Amz-Content-Sha256", valid_773360
  var valid_773361 = header.getOrDefault("X-Amz-Algorithm")
  valid_773361 = validateParameter(valid_773361, JString, required = false,
                                 default = nil)
  if valid_773361 != nil:
    section.add "X-Amz-Algorithm", valid_773361
  var valid_773362 = header.getOrDefault("X-Amz-Signature")
  valid_773362 = validateParameter(valid_773362, JString, required = false,
                                 default = nil)
  if valid_773362 != nil:
    section.add "X-Amz-Signature", valid_773362
  var valid_773363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773363 = validateParameter(valid_773363, JString, required = false,
                                 default = nil)
  if valid_773363 != nil:
    section.add "X-Amz-SignedHeaders", valid_773363
  var valid_773364 = header.getOrDefault("X-Amz-Credential")
  valid_773364 = validateParameter(valid_773364, JString, required = false,
                                 default = nil)
  if valid_773364 != nil:
    section.add "X-Amz-Credential", valid_773364
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773366: Call_ListApplications_773352; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the IDs of the applications that you are monitoring. 
  ## 
  let valid = call_773366.validator(path, query, header, formData, body)
  let scheme = call_773366.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773366.url(scheme.get, call_773366.host, call_773366.base,
                         call_773366.route, valid.getOrDefault("path"))
  result = hook(call_773366, url, valid)

proc call*(call_773367: Call_ListApplications_773352; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listApplications
  ## Lists the IDs of the applications that you are monitoring. 
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773368 = newJObject()
  var body_773369 = newJObject()
  add(query_773368, "NextToken", newJString(NextToken))
  if body != nil:
    body_773369 = body
  add(query_773368, "MaxResults", newJString(MaxResults))
  result = call_773367.call(nil, query_773368, nil, nil, body_773369)

var listApplications* = Call_ListApplications_773352(name: "listApplications",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.ListApplications",
    validator: validate_ListApplications_773353, base: "/",
    url: url_ListApplications_773354, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListComponents_773371 = ref object of OpenApiRestCall_772597
proc url_ListComponents_773373(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListComponents_773372(path: JsonNode; query: JsonNode;
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
  var valid_773374 = query.getOrDefault("NextToken")
  valid_773374 = validateParameter(valid_773374, JString, required = false,
                                 default = nil)
  if valid_773374 != nil:
    section.add "NextToken", valid_773374
  var valid_773375 = query.getOrDefault("MaxResults")
  valid_773375 = validateParameter(valid_773375, JString, required = false,
                                 default = nil)
  if valid_773375 != nil:
    section.add "MaxResults", valid_773375
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
  var valid_773376 = header.getOrDefault("X-Amz-Date")
  valid_773376 = validateParameter(valid_773376, JString, required = false,
                                 default = nil)
  if valid_773376 != nil:
    section.add "X-Amz-Date", valid_773376
  var valid_773377 = header.getOrDefault("X-Amz-Security-Token")
  valid_773377 = validateParameter(valid_773377, JString, required = false,
                                 default = nil)
  if valid_773377 != nil:
    section.add "X-Amz-Security-Token", valid_773377
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773378 = header.getOrDefault("X-Amz-Target")
  valid_773378 = validateParameter(valid_773378, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.ListComponents"))
  if valid_773378 != nil:
    section.add "X-Amz-Target", valid_773378
  var valid_773379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773379 = validateParameter(valid_773379, JString, required = false,
                                 default = nil)
  if valid_773379 != nil:
    section.add "X-Amz-Content-Sha256", valid_773379
  var valid_773380 = header.getOrDefault("X-Amz-Algorithm")
  valid_773380 = validateParameter(valid_773380, JString, required = false,
                                 default = nil)
  if valid_773380 != nil:
    section.add "X-Amz-Algorithm", valid_773380
  var valid_773381 = header.getOrDefault("X-Amz-Signature")
  valid_773381 = validateParameter(valid_773381, JString, required = false,
                                 default = nil)
  if valid_773381 != nil:
    section.add "X-Amz-Signature", valid_773381
  var valid_773382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773382 = validateParameter(valid_773382, JString, required = false,
                                 default = nil)
  if valid_773382 != nil:
    section.add "X-Amz-SignedHeaders", valid_773382
  var valid_773383 = header.getOrDefault("X-Amz-Credential")
  valid_773383 = validateParameter(valid_773383, JString, required = false,
                                 default = nil)
  if valid_773383 != nil:
    section.add "X-Amz-Credential", valid_773383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773385: Call_ListComponents_773371; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the auto-grouped, standalone, and custom components of the application.
  ## 
  let valid = call_773385.validator(path, query, header, formData, body)
  let scheme = call_773385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773385.url(scheme.get, call_773385.host, call_773385.base,
                         call_773385.route, valid.getOrDefault("path"))
  result = hook(call_773385, url, valid)

proc call*(call_773386: Call_ListComponents_773371; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listComponents
  ## Lists the auto-grouped, standalone, and custom components of the application.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773387 = newJObject()
  var body_773388 = newJObject()
  add(query_773387, "NextToken", newJString(NextToken))
  if body != nil:
    body_773388 = body
  add(query_773387, "MaxResults", newJString(MaxResults))
  result = call_773386.call(nil, query_773387, nil, nil, body_773388)

var listComponents* = Call_ListComponents_773371(name: "listComponents",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.ListComponents",
    validator: validate_ListComponents_773372, base: "/", url: url_ListComponents_773373,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProblems_773389 = ref object of OpenApiRestCall_772597
proc url_ListProblems_773391(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListProblems_773390(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_773392 = query.getOrDefault("NextToken")
  valid_773392 = validateParameter(valid_773392, JString, required = false,
                                 default = nil)
  if valid_773392 != nil:
    section.add "NextToken", valid_773392
  var valid_773393 = query.getOrDefault("MaxResults")
  valid_773393 = validateParameter(valid_773393, JString, required = false,
                                 default = nil)
  if valid_773393 != nil:
    section.add "MaxResults", valid_773393
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
  var valid_773394 = header.getOrDefault("X-Amz-Date")
  valid_773394 = validateParameter(valid_773394, JString, required = false,
                                 default = nil)
  if valid_773394 != nil:
    section.add "X-Amz-Date", valid_773394
  var valid_773395 = header.getOrDefault("X-Amz-Security-Token")
  valid_773395 = validateParameter(valid_773395, JString, required = false,
                                 default = nil)
  if valid_773395 != nil:
    section.add "X-Amz-Security-Token", valid_773395
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773396 = header.getOrDefault("X-Amz-Target")
  valid_773396 = validateParameter(valid_773396, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.ListProblems"))
  if valid_773396 != nil:
    section.add "X-Amz-Target", valid_773396
  var valid_773397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773397 = validateParameter(valid_773397, JString, required = false,
                                 default = nil)
  if valid_773397 != nil:
    section.add "X-Amz-Content-Sha256", valid_773397
  var valid_773398 = header.getOrDefault("X-Amz-Algorithm")
  valid_773398 = validateParameter(valid_773398, JString, required = false,
                                 default = nil)
  if valid_773398 != nil:
    section.add "X-Amz-Algorithm", valid_773398
  var valid_773399 = header.getOrDefault("X-Amz-Signature")
  valid_773399 = validateParameter(valid_773399, JString, required = false,
                                 default = nil)
  if valid_773399 != nil:
    section.add "X-Amz-Signature", valid_773399
  var valid_773400 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773400 = validateParameter(valid_773400, JString, required = false,
                                 default = nil)
  if valid_773400 != nil:
    section.add "X-Amz-SignedHeaders", valid_773400
  var valid_773401 = header.getOrDefault("X-Amz-Credential")
  valid_773401 = validateParameter(valid_773401, JString, required = false,
                                 default = nil)
  if valid_773401 != nil:
    section.add "X-Amz-Credential", valid_773401
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773403: Call_ListProblems_773389; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the problems with your application.
  ## 
  let valid = call_773403.validator(path, query, header, formData, body)
  let scheme = call_773403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773403.url(scheme.get, call_773403.host, call_773403.base,
                         call_773403.route, valid.getOrDefault("path"))
  result = hook(call_773403, url, valid)

proc call*(call_773404: Call_ListProblems_773389; body: JsonNode;
          NextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listProblems
  ## Lists the problems with your application.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   MaxResults: string
  ##             : Pagination limit
  var query_773405 = newJObject()
  var body_773406 = newJObject()
  add(query_773405, "NextToken", newJString(NextToken))
  if body != nil:
    body_773406 = body
  add(query_773405, "MaxResults", newJString(MaxResults))
  result = call_773404.call(nil, query_773405, nil, nil, body_773406)

var listProblems* = Call_ListProblems_773389(name: "listProblems",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.ListProblems",
    validator: validate_ListProblems_773390, base: "/", url: url_ListProblems_773391,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApplication_773407 = ref object of OpenApiRestCall_772597
proc url_UpdateApplication_773409(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateApplication_773408(path: JsonNode; query: JsonNode;
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
  var valid_773410 = header.getOrDefault("X-Amz-Date")
  valid_773410 = validateParameter(valid_773410, JString, required = false,
                                 default = nil)
  if valid_773410 != nil:
    section.add "X-Amz-Date", valid_773410
  var valid_773411 = header.getOrDefault("X-Amz-Security-Token")
  valid_773411 = validateParameter(valid_773411, JString, required = false,
                                 default = nil)
  if valid_773411 != nil:
    section.add "X-Amz-Security-Token", valid_773411
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773412 = header.getOrDefault("X-Amz-Target")
  valid_773412 = validateParameter(valid_773412, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.UpdateApplication"))
  if valid_773412 != nil:
    section.add "X-Amz-Target", valid_773412
  var valid_773413 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773413 = validateParameter(valid_773413, JString, required = false,
                                 default = nil)
  if valid_773413 != nil:
    section.add "X-Amz-Content-Sha256", valid_773413
  var valid_773414 = header.getOrDefault("X-Amz-Algorithm")
  valid_773414 = validateParameter(valid_773414, JString, required = false,
                                 default = nil)
  if valid_773414 != nil:
    section.add "X-Amz-Algorithm", valid_773414
  var valid_773415 = header.getOrDefault("X-Amz-Signature")
  valid_773415 = validateParameter(valid_773415, JString, required = false,
                                 default = nil)
  if valid_773415 != nil:
    section.add "X-Amz-Signature", valid_773415
  var valid_773416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773416 = validateParameter(valid_773416, JString, required = false,
                                 default = nil)
  if valid_773416 != nil:
    section.add "X-Amz-SignedHeaders", valid_773416
  var valid_773417 = header.getOrDefault("X-Amz-Credential")
  valid_773417 = validateParameter(valid_773417, JString, required = false,
                                 default = nil)
  if valid_773417 != nil:
    section.add "X-Amz-Credential", valid_773417
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773419: Call_UpdateApplication_773407; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the application.
  ## 
  let valid = call_773419.validator(path, query, header, formData, body)
  let scheme = call_773419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773419.url(scheme.get, call_773419.host, call_773419.base,
                         call_773419.route, valid.getOrDefault("path"))
  result = hook(call_773419, url, valid)

proc call*(call_773420: Call_UpdateApplication_773407; body: JsonNode): Recallable =
  ## updateApplication
  ## Updates the application.
  ##   body: JObject (required)
  var body_773421 = newJObject()
  if body != nil:
    body_773421 = body
  result = call_773420.call(nil, nil, nil, nil, body_773421)

var updateApplication* = Call_UpdateApplication_773407(name: "updateApplication",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.UpdateApplication",
    validator: validate_UpdateApplication_773408, base: "/",
    url: url_UpdateApplication_773409, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateComponent_773422 = ref object of OpenApiRestCall_772597
proc url_UpdateComponent_773424(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateComponent_773423(path: JsonNode; query: JsonNode;
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
  var valid_773425 = header.getOrDefault("X-Amz-Date")
  valid_773425 = validateParameter(valid_773425, JString, required = false,
                                 default = nil)
  if valid_773425 != nil:
    section.add "X-Amz-Date", valid_773425
  var valid_773426 = header.getOrDefault("X-Amz-Security-Token")
  valid_773426 = validateParameter(valid_773426, JString, required = false,
                                 default = nil)
  if valid_773426 != nil:
    section.add "X-Amz-Security-Token", valid_773426
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773427 = header.getOrDefault("X-Amz-Target")
  valid_773427 = validateParameter(valid_773427, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.UpdateComponent"))
  if valid_773427 != nil:
    section.add "X-Amz-Target", valid_773427
  var valid_773428 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773428 = validateParameter(valid_773428, JString, required = false,
                                 default = nil)
  if valid_773428 != nil:
    section.add "X-Amz-Content-Sha256", valid_773428
  var valid_773429 = header.getOrDefault("X-Amz-Algorithm")
  valid_773429 = validateParameter(valid_773429, JString, required = false,
                                 default = nil)
  if valid_773429 != nil:
    section.add "X-Amz-Algorithm", valid_773429
  var valid_773430 = header.getOrDefault("X-Amz-Signature")
  valid_773430 = validateParameter(valid_773430, JString, required = false,
                                 default = nil)
  if valid_773430 != nil:
    section.add "X-Amz-Signature", valid_773430
  var valid_773431 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773431 = validateParameter(valid_773431, JString, required = false,
                                 default = nil)
  if valid_773431 != nil:
    section.add "X-Amz-SignedHeaders", valid_773431
  var valid_773432 = header.getOrDefault("X-Amz-Credential")
  valid_773432 = validateParameter(valid_773432, JString, required = false,
                                 default = nil)
  if valid_773432 != nil:
    section.add "X-Amz-Credential", valid_773432
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773434: Call_UpdateComponent_773422; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the custom component name and/or the list of resources that make up the component.
  ## 
  let valid = call_773434.validator(path, query, header, formData, body)
  let scheme = call_773434.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773434.url(scheme.get, call_773434.host, call_773434.base,
                         call_773434.route, valid.getOrDefault("path"))
  result = hook(call_773434, url, valid)

proc call*(call_773435: Call_UpdateComponent_773422; body: JsonNode): Recallable =
  ## updateComponent
  ## Updates the custom component name and/or the list of resources that make up the component.
  ##   body: JObject (required)
  var body_773436 = newJObject()
  if body != nil:
    body_773436 = body
  result = call_773435.call(nil, nil, nil, nil, body_773436)

var updateComponent* = Call_UpdateComponent_773422(name: "updateComponent",
    meth: HttpMethod.HttpPost, host: "applicationinsights.amazonaws.com",
    route: "/#X-Amz-Target=EC2WindowsBarleyService.UpdateComponent",
    validator: validate_UpdateComponent_773423, base: "/", url: url_UpdateComponent_773424,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateComponentConfiguration_773437 = ref object of OpenApiRestCall_772597
proc url_UpdateComponentConfiguration_773439(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateComponentConfiguration_773438(path: JsonNode; query: JsonNode;
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
  var valid_773440 = header.getOrDefault("X-Amz-Date")
  valid_773440 = validateParameter(valid_773440, JString, required = false,
                                 default = nil)
  if valid_773440 != nil:
    section.add "X-Amz-Date", valid_773440
  var valid_773441 = header.getOrDefault("X-Amz-Security-Token")
  valid_773441 = validateParameter(valid_773441, JString, required = false,
                                 default = nil)
  if valid_773441 != nil:
    section.add "X-Amz-Security-Token", valid_773441
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773442 = header.getOrDefault("X-Amz-Target")
  valid_773442 = validateParameter(valid_773442, JString, required = true, default = newJString(
      "EC2WindowsBarleyService.UpdateComponentConfiguration"))
  if valid_773442 != nil:
    section.add "X-Amz-Target", valid_773442
  var valid_773443 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773443 = validateParameter(valid_773443, JString, required = false,
                                 default = nil)
  if valid_773443 != nil:
    section.add "X-Amz-Content-Sha256", valid_773443
  var valid_773444 = header.getOrDefault("X-Amz-Algorithm")
  valid_773444 = validateParameter(valid_773444, JString, required = false,
                                 default = nil)
  if valid_773444 != nil:
    section.add "X-Amz-Algorithm", valid_773444
  var valid_773445 = header.getOrDefault("X-Amz-Signature")
  valid_773445 = validateParameter(valid_773445, JString, required = false,
                                 default = nil)
  if valid_773445 != nil:
    section.add "X-Amz-Signature", valid_773445
  var valid_773446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773446 = validateParameter(valid_773446, JString, required = false,
                                 default = nil)
  if valid_773446 != nil:
    section.add "X-Amz-SignedHeaders", valid_773446
  var valid_773447 = header.getOrDefault("X-Amz-Credential")
  valid_773447 = validateParameter(valid_773447, JString, required = false,
                                 default = nil)
  if valid_773447 != nil:
    section.add "X-Amz-Credential", valid_773447
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773449: Call_UpdateComponentConfiguration_773437; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the monitoring configurations for the component. The configuration input parameter is an escaped JSON of the configuration and should match the schema of what is returned by <code>DescribeComponentConfigurationRecommendation</code>.
  ## 
  let valid = call_773449.validator(path, query, header, formData, body)
  let scheme = call_773449.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773449.url(scheme.get, call_773449.host, call_773449.base,
                         call_773449.route, valid.getOrDefault("path"))
  result = hook(call_773449, url, valid)

proc call*(call_773450: Call_UpdateComponentConfiguration_773437; body: JsonNode): Recallable =
  ## updateComponentConfiguration
  ## Updates the monitoring configurations for the component. The configuration input parameter is an escaped JSON of the configuration and should match the schema of what is returned by <code>DescribeComponentConfigurationRecommendation</code>.
  ##   body: JObject (required)
  var body_773451 = newJObject()
  if body != nil:
    body_773451 = body
  result = call_773450.call(nil, nil, nil, nil, body_773451)

var updateComponentConfiguration* = Call_UpdateComponentConfiguration_773437(
    name: "updateComponentConfiguration", meth: HttpMethod.HttpPost,
    host: "applicationinsights.amazonaws.com", route: "/#X-Amz-Target=EC2WindowsBarleyService.UpdateComponentConfiguration",
    validator: validate_UpdateComponentConfiguration_773438, base: "/",
    url: url_UpdateComponentConfiguration_773439,
    schemes: {Scheme.Https, Scheme.Http})
proc sign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)

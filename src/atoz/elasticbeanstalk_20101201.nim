
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Elastic Beanstalk
## version: 2010-12-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS Elastic Beanstalk</fullname> <p>AWS Elastic Beanstalk makes it easy for you to create, deploy, and manage scalable, fault-tolerant applications running on the Amazon Web Services cloud.</p> <p>For more information about this product, go to the <a href="http://aws.amazon.com/elasticbeanstalk/">AWS Elastic Beanstalk</a> details page. The location of the latest AWS Elastic Beanstalk WSDL is <a href="http://elasticbeanstalk.s3.amazonaws.com/doc/2010-12-01/AWSElasticBeanstalk.wsdl">http://elasticbeanstalk.s3.amazonaws.com/doc/2010-12-01/AWSElasticBeanstalk.wsdl</a>. To install the Software Development Kits (SDKs), Integrated Development Environment (IDE) Toolkits, and command line tools that enable you to access the API, go to <a href="http://aws.amazon.com/tools/">Tools for Amazon Web Services</a>.</p> <p> <b>Endpoints</b> </p> <p>For a list of region-specific endpoints that AWS Elastic Beanstalk supports, go to <a href="https://docs.aws.amazon.com/general/latest/gr/rande.html#elasticbeanstalk_region">Regions and Endpoints</a> in the <i>Amazon Web Services Glossary</i>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/elasticbeanstalk/
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

  OpenApiRestCall_610659 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610659](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610659): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "elasticbeanstalk.ap-northeast-1.amazonaws.com", "ap-southeast-1": "elasticbeanstalk.ap-southeast-1.amazonaws.com", "us-west-2": "elasticbeanstalk.us-west-2.amazonaws.com", "eu-west-2": "elasticbeanstalk.eu-west-2.amazonaws.com", "ap-northeast-3": "elasticbeanstalk.ap-northeast-3.amazonaws.com", "eu-central-1": "elasticbeanstalk.eu-central-1.amazonaws.com", "us-east-2": "elasticbeanstalk.us-east-2.amazonaws.com", "us-east-1": "elasticbeanstalk.us-east-1.amazonaws.com", "cn-northwest-1": "elasticbeanstalk.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "elasticbeanstalk.ap-south-1.amazonaws.com", "eu-north-1": "elasticbeanstalk.eu-north-1.amazonaws.com", "ap-northeast-2": "elasticbeanstalk.ap-northeast-2.amazonaws.com", "us-west-1": "elasticbeanstalk.us-west-1.amazonaws.com", "us-gov-east-1": "elasticbeanstalk.us-gov-east-1.amazonaws.com", "eu-west-3": "elasticbeanstalk.eu-west-3.amazonaws.com", "cn-north-1": "elasticbeanstalk.cn-north-1.amazonaws.com.cn", "sa-east-1": "elasticbeanstalk.sa-east-1.amazonaws.com", "eu-west-1": "elasticbeanstalk.eu-west-1.amazonaws.com", "us-gov-west-1": "elasticbeanstalk.us-gov-west-1.amazonaws.com", "ap-southeast-2": "elasticbeanstalk.ap-southeast-2.amazonaws.com", "ca-central-1": "elasticbeanstalk.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "elasticbeanstalk.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "elasticbeanstalk.ap-southeast-1.amazonaws.com",
      "us-west-2": "elasticbeanstalk.us-west-2.amazonaws.com",
      "eu-west-2": "elasticbeanstalk.eu-west-2.amazonaws.com",
      "ap-northeast-3": "elasticbeanstalk.ap-northeast-3.amazonaws.com",
      "eu-central-1": "elasticbeanstalk.eu-central-1.amazonaws.com",
      "us-east-2": "elasticbeanstalk.us-east-2.amazonaws.com",
      "us-east-1": "elasticbeanstalk.us-east-1.amazonaws.com",
      "cn-northwest-1": "elasticbeanstalk.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "elasticbeanstalk.ap-south-1.amazonaws.com",
      "eu-north-1": "elasticbeanstalk.eu-north-1.amazonaws.com",
      "ap-northeast-2": "elasticbeanstalk.ap-northeast-2.amazonaws.com",
      "us-west-1": "elasticbeanstalk.us-west-1.amazonaws.com",
      "us-gov-east-1": "elasticbeanstalk.us-gov-east-1.amazonaws.com",
      "eu-west-3": "elasticbeanstalk.eu-west-3.amazonaws.com",
      "cn-north-1": "elasticbeanstalk.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "elasticbeanstalk.sa-east-1.amazonaws.com",
      "eu-west-1": "elasticbeanstalk.eu-west-1.amazonaws.com",
      "us-gov-west-1": "elasticbeanstalk.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "elasticbeanstalk.ap-southeast-2.amazonaws.com",
      "ca-central-1": "elasticbeanstalk.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "elasticbeanstalk"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostAbortEnvironmentUpdate_611269 = ref object of OpenApiRestCall_610659
proc url_PostAbortEnvironmentUpdate_611271(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostAbortEnvironmentUpdate_611270(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Cancels in-progress environment configuration update or application version deployment.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611272 = query.getOrDefault("Action")
  valid_611272 = validateParameter(valid_611272, JString, required = true,
                                 default = newJString("AbortEnvironmentUpdate"))
  if valid_611272 != nil:
    section.add "Action", valid_611272
  var valid_611273 = query.getOrDefault("Version")
  valid_611273 = validateParameter(valid_611273, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_611273 != nil:
    section.add "Version", valid_611273
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611274 = header.getOrDefault("X-Amz-Signature")
  valid_611274 = validateParameter(valid_611274, JString, required = false,
                                 default = nil)
  if valid_611274 != nil:
    section.add "X-Amz-Signature", valid_611274
  var valid_611275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611275 = validateParameter(valid_611275, JString, required = false,
                                 default = nil)
  if valid_611275 != nil:
    section.add "X-Amz-Content-Sha256", valid_611275
  var valid_611276 = header.getOrDefault("X-Amz-Date")
  valid_611276 = validateParameter(valid_611276, JString, required = false,
                                 default = nil)
  if valid_611276 != nil:
    section.add "X-Amz-Date", valid_611276
  var valid_611277 = header.getOrDefault("X-Amz-Credential")
  valid_611277 = validateParameter(valid_611277, JString, required = false,
                                 default = nil)
  if valid_611277 != nil:
    section.add "X-Amz-Credential", valid_611277
  var valid_611278 = header.getOrDefault("X-Amz-Security-Token")
  valid_611278 = validateParameter(valid_611278, JString, required = false,
                                 default = nil)
  if valid_611278 != nil:
    section.add "X-Amz-Security-Token", valid_611278
  var valid_611279 = header.getOrDefault("X-Amz-Algorithm")
  valid_611279 = validateParameter(valid_611279, JString, required = false,
                                 default = nil)
  if valid_611279 != nil:
    section.add "X-Amz-Algorithm", valid_611279
  var valid_611280 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611280 = validateParameter(valid_611280, JString, required = false,
                                 default = nil)
  if valid_611280 != nil:
    section.add "X-Amz-SignedHeaders", valid_611280
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString
  ##                  : This specifies the name of the environment with the in-progress update that you want to cancel.
  ##   EnvironmentId: JString
  ##                : This specifies the ID of the environment with the in-progress update that you want to cancel.
  section = newJObject()
  var valid_611281 = formData.getOrDefault("EnvironmentName")
  valid_611281 = validateParameter(valid_611281, JString, required = false,
                                 default = nil)
  if valid_611281 != nil:
    section.add "EnvironmentName", valid_611281
  var valid_611282 = formData.getOrDefault("EnvironmentId")
  valid_611282 = validateParameter(valid_611282, JString, required = false,
                                 default = nil)
  if valid_611282 != nil:
    section.add "EnvironmentId", valid_611282
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611283: Call_PostAbortEnvironmentUpdate_611269; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels in-progress environment configuration update or application version deployment.
  ## 
  let valid = call_611283.validator(path, query, header, formData, body)
  let scheme = call_611283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611283.url(scheme.get, call_611283.host, call_611283.base,
                         call_611283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611283, url, valid)

proc call*(call_611284: Call_PostAbortEnvironmentUpdate_611269;
          EnvironmentName: string = ""; Action: string = "AbortEnvironmentUpdate";
          EnvironmentId: string = ""; Version: string = "2010-12-01"): Recallable =
  ## postAbortEnvironmentUpdate
  ## Cancels in-progress environment configuration update or application version deployment.
  ##   EnvironmentName: string
  ##                  : This specifies the name of the environment with the in-progress update that you want to cancel.
  ##   Action: string (required)
  ##   EnvironmentId: string
  ##                : This specifies the ID of the environment with the in-progress update that you want to cancel.
  ##   Version: string (required)
  var query_611285 = newJObject()
  var formData_611286 = newJObject()
  add(formData_611286, "EnvironmentName", newJString(EnvironmentName))
  add(query_611285, "Action", newJString(Action))
  add(formData_611286, "EnvironmentId", newJString(EnvironmentId))
  add(query_611285, "Version", newJString(Version))
  result = call_611284.call(nil, query_611285, nil, formData_611286, nil)

var postAbortEnvironmentUpdate* = Call_PostAbortEnvironmentUpdate_611269(
    name: "postAbortEnvironmentUpdate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=AbortEnvironmentUpdate",
    validator: validate_PostAbortEnvironmentUpdate_611270, base: "/",
    url: url_PostAbortEnvironmentUpdate_611271,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAbortEnvironmentUpdate_610997 = ref object of OpenApiRestCall_610659
proc url_GetAbortEnvironmentUpdate_610999(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAbortEnvironmentUpdate_610998(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Cancels in-progress environment configuration update or application version deployment.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   EnvironmentName: JString
  ##                  : This specifies the name of the environment with the in-progress update that you want to cancel.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   EnvironmentId: JString
  ##                : This specifies the ID of the environment with the in-progress update that you want to cancel.
  section = newJObject()
  var valid_611111 = query.getOrDefault("EnvironmentName")
  valid_611111 = validateParameter(valid_611111, JString, required = false,
                                 default = nil)
  if valid_611111 != nil:
    section.add "EnvironmentName", valid_611111
  var valid_611125 = query.getOrDefault("Action")
  valid_611125 = validateParameter(valid_611125, JString, required = true,
                                 default = newJString("AbortEnvironmentUpdate"))
  if valid_611125 != nil:
    section.add "Action", valid_611125
  var valid_611126 = query.getOrDefault("Version")
  valid_611126 = validateParameter(valid_611126, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_611126 != nil:
    section.add "Version", valid_611126
  var valid_611127 = query.getOrDefault("EnvironmentId")
  valid_611127 = validateParameter(valid_611127, JString, required = false,
                                 default = nil)
  if valid_611127 != nil:
    section.add "EnvironmentId", valid_611127
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611128 = header.getOrDefault("X-Amz-Signature")
  valid_611128 = validateParameter(valid_611128, JString, required = false,
                                 default = nil)
  if valid_611128 != nil:
    section.add "X-Amz-Signature", valid_611128
  var valid_611129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611129 = validateParameter(valid_611129, JString, required = false,
                                 default = nil)
  if valid_611129 != nil:
    section.add "X-Amz-Content-Sha256", valid_611129
  var valid_611130 = header.getOrDefault("X-Amz-Date")
  valid_611130 = validateParameter(valid_611130, JString, required = false,
                                 default = nil)
  if valid_611130 != nil:
    section.add "X-Amz-Date", valid_611130
  var valid_611131 = header.getOrDefault("X-Amz-Credential")
  valid_611131 = validateParameter(valid_611131, JString, required = false,
                                 default = nil)
  if valid_611131 != nil:
    section.add "X-Amz-Credential", valid_611131
  var valid_611132 = header.getOrDefault("X-Amz-Security-Token")
  valid_611132 = validateParameter(valid_611132, JString, required = false,
                                 default = nil)
  if valid_611132 != nil:
    section.add "X-Amz-Security-Token", valid_611132
  var valid_611133 = header.getOrDefault("X-Amz-Algorithm")
  valid_611133 = validateParameter(valid_611133, JString, required = false,
                                 default = nil)
  if valid_611133 != nil:
    section.add "X-Amz-Algorithm", valid_611133
  var valid_611134 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611134 = validateParameter(valid_611134, JString, required = false,
                                 default = nil)
  if valid_611134 != nil:
    section.add "X-Amz-SignedHeaders", valid_611134
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611157: Call_GetAbortEnvironmentUpdate_610997; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels in-progress environment configuration update or application version deployment.
  ## 
  let valid = call_611157.validator(path, query, header, formData, body)
  let scheme = call_611157.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611157.url(scheme.get, call_611157.host, call_611157.base,
                         call_611157.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611157, url, valid)

proc call*(call_611228: Call_GetAbortEnvironmentUpdate_610997;
          EnvironmentName: string = ""; Action: string = "AbortEnvironmentUpdate";
          Version: string = "2010-12-01"; EnvironmentId: string = ""): Recallable =
  ## getAbortEnvironmentUpdate
  ## Cancels in-progress environment configuration update or application version deployment.
  ##   EnvironmentName: string
  ##                  : This specifies the name of the environment with the in-progress update that you want to cancel.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   EnvironmentId: string
  ##                : This specifies the ID of the environment with the in-progress update that you want to cancel.
  var query_611229 = newJObject()
  add(query_611229, "EnvironmentName", newJString(EnvironmentName))
  add(query_611229, "Action", newJString(Action))
  add(query_611229, "Version", newJString(Version))
  add(query_611229, "EnvironmentId", newJString(EnvironmentId))
  result = call_611228.call(nil, query_611229, nil, nil, nil)

var getAbortEnvironmentUpdate* = Call_GetAbortEnvironmentUpdate_610997(
    name: "getAbortEnvironmentUpdate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=AbortEnvironmentUpdate",
    validator: validate_GetAbortEnvironmentUpdate_610998, base: "/",
    url: url_GetAbortEnvironmentUpdate_610999,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostApplyEnvironmentManagedAction_611305 = ref object of OpenApiRestCall_610659
proc url_PostApplyEnvironmentManagedAction_611307(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostApplyEnvironmentManagedAction_611306(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Applies a scheduled managed action immediately. A managed action can be applied only if its status is <code>Scheduled</code>. Get the status and action ID of a managed action with <a>DescribeEnvironmentManagedActions</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611308 = query.getOrDefault("Action")
  valid_611308 = validateParameter(valid_611308, JString, required = true, default = newJString(
      "ApplyEnvironmentManagedAction"))
  if valid_611308 != nil:
    section.add "Action", valid_611308
  var valid_611309 = query.getOrDefault("Version")
  valid_611309 = validateParameter(valid_611309, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_611309 != nil:
    section.add "Version", valid_611309
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611310 = header.getOrDefault("X-Amz-Signature")
  valid_611310 = validateParameter(valid_611310, JString, required = false,
                                 default = nil)
  if valid_611310 != nil:
    section.add "X-Amz-Signature", valid_611310
  var valid_611311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611311 = validateParameter(valid_611311, JString, required = false,
                                 default = nil)
  if valid_611311 != nil:
    section.add "X-Amz-Content-Sha256", valid_611311
  var valid_611312 = header.getOrDefault("X-Amz-Date")
  valid_611312 = validateParameter(valid_611312, JString, required = false,
                                 default = nil)
  if valid_611312 != nil:
    section.add "X-Amz-Date", valid_611312
  var valid_611313 = header.getOrDefault("X-Amz-Credential")
  valid_611313 = validateParameter(valid_611313, JString, required = false,
                                 default = nil)
  if valid_611313 != nil:
    section.add "X-Amz-Credential", valid_611313
  var valid_611314 = header.getOrDefault("X-Amz-Security-Token")
  valid_611314 = validateParameter(valid_611314, JString, required = false,
                                 default = nil)
  if valid_611314 != nil:
    section.add "X-Amz-Security-Token", valid_611314
  var valid_611315 = header.getOrDefault("X-Amz-Algorithm")
  valid_611315 = validateParameter(valid_611315, JString, required = false,
                                 default = nil)
  if valid_611315 != nil:
    section.add "X-Amz-Algorithm", valid_611315
  var valid_611316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611316 = validateParameter(valid_611316, JString, required = false,
                                 default = nil)
  if valid_611316 != nil:
    section.add "X-Amz-SignedHeaders", valid_611316
  result.add "header", section
  ## parameters in `formData` object:
  ##   ActionId: JString (required)
  ##           : The action ID of the scheduled managed action to execute.
  ##   EnvironmentName: JString
  ##                  : The name of the target environment.
  ##   EnvironmentId: JString
  ##                : The environment ID of the target environment.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ActionId` field"
  var valid_611317 = formData.getOrDefault("ActionId")
  valid_611317 = validateParameter(valid_611317, JString, required = true,
                                 default = nil)
  if valid_611317 != nil:
    section.add "ActionId", valid_611317
  var valid_611318 = formData.getOrDefault("EnvironmentName")
  valid_611318 = validateParameter(valid_611318, JString, required = false,
                                 default = nil)
  if valid_611318 != nil:
    section.add "EnvironmentName", valid_611318
  var valid_611319 = formData.getOrDefault("EnvironmentId")
  valid_611319 = validateParameter(valid_611319, JString, required = false,
                                 default = nil)
  if valid_611319 != nil:
    section.add "EnvironmentId", valid_611319
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611320: Call_PostApplyEnvironmentManagedAction_611305;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Applies a scheduled managed action immediately. A managed action can be applied only if its status is <code>Scheduled</code>. Get the status and action ID of a managed action with <a>DescribeEnvironmentManagedActions</a>.
  ## 
  let valid = call_611320.validator(path, query, header, formData, body)
  let scheme = call_611320.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611320.url(scheme.get, call_611320.host, call_611320.base,
                         call_611320.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611320, url, valid)

proc call*(call_611321: Call_PostApplyEnvironmentManagedAction_611305;
          ActionId: string; EnvironmentName: string = "";
          Action: string = "ApplyEnvironmentManagedAction";
          EnvironmentId: string = ""; Version: string = "2010-12-01"): Recallable =
  ## postApplyEnvironmentManagedAction
  ## Applies a scheduled managed action immediately. A managed action can be applied only if its status is <code>Scheduled</code>. Get the status and action ID of a managed action with <a>DescribeEnvironmentManagedActions</a>.
  ##   ActionId: string (required)
  ##           : The action ID of the scheduled managed action to execute.
  ##   EnvironmentName: string
  ##                  : The name of the target environment.
  ##   Action: string (required)
  ##   EnvironmentId: string
  ##                : The environment ID of the target environment.
  ##   Version: string (required)
  var query_611322 = newJObject()
  var formData_611323 = newJObject()
  add(formData_611323, "ActionId", newJString(ActionId))
  add(formData_611323, "EnvironmentName", newJString(EnvironmentName))
  add(query_611322, "Action", newJString(Action))
  add(formData_611323, "EnvironmentId", newJString(EnvironmentId))
  add(query_611322, "Version", newJString(Version))
  result = call_611321.call(nil, query_611322, nil, formData_611323, nil)

var postApplyEnvironmentManagedAction* = Call_PostApplyEnvironmentManagedAction_611305(
    name: "postApplyEnvironmentManagedAction", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ApplyEnvironmentManagedAction",
    validator: validate_PostApplyEnvironmentManagedAction_611306, base: "/",
    url: url_PostApplyEnvironmentManagedAction_611307,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplyEnvironmentManagedAction_611287 = ref object of OpenApiRestCall_610659
proc url_GetApplyEnvironmentManagedAction_611289(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetApplyEnvironmentManagedAction_611288(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Applies a scheduled managed action immediately. A managed action can be applied only if its status is <code>Scheduled</code>. Get the status and action ID of a managed action with <a>DescribeEnvironmentManagedActions</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ActionId: JString (required)
  ##           : The action ID of the scheduled managed action to execute.
  ##   EnvironmentName: JString
  ##                  : The name of the target environment.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   EnvironmentId: JString
  ##                : The environment ID of the target environment.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ActionId` field"
  var valid_611290 = query.getOrDefault("ActionId")
  valid_611290 = validateParameter(valid_611290, JString, required = true,
                                 default = nil)
  if valid_611290 != nil:
    section.add "ActionId", valid_611290
  var valid_611291 = query.getOrDefault("EnvironmentName")
  valid_611291 = validateParameter(valid_611291, JString, required = false,
                                 default = nil)
  if valid_611291 != nil:
    section.add "EnvironmentName", valid_611291
  var valid_611292 = query.getOrDefault("Action")
  valid_611292 = validateParameter(valid_611292, JString, required = true, default = newJString(
      "ApplyEnvironmentManagedAction"))
  if valid_611292 != nil:
    section.add "Action", valid_611292
  var valid_611293 = query.getOrDefault("Version")
  valid_611293 = validateParameter(valid_611293, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_611293 != nil:
    section.add "Version", valid_611293
  var valid_611294 = query.getOrDefault("EnvironmentId")
  valid_611294 = validateParameter(valid_611294, JString, required = false,
                                 default = nil)
  if valid_611294 != nil:
    section.add "EnvironmentId", valid_611294
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611295 = header.getOrDefault("X-Amz-Signature")
  valid_611295 = validateParameter(valid_611295, JString, required = false,
                                 default = nil)
  if valid_611295 != nil:
    section.add "X-Amz-Signature", valid_611295
  var valid_611296 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611296 = validateParameter(valid_611296, JString, required = false,
                                 default = nil)
  if valid_611296 != nil:
    section.add "X-Amz-Content-Sha256", valid_611296
  var valid_611297 = header.getOrDefault("X-Amz-Date")
  valid_611297 = validateParameter(valid_611297, JString, required = false,
                                 default = nil)
  if valid_611297 != nil:
    section.add "X-Amz-Date", valid_611297
  var valid_611298 = header.getOrDefault("X-Amz-Credential")
  valid_611298 = validateParameter(valid_611298, JString, required = false,
                                 default = nil)
  if valid_611298 != nil:
    section.add "X-Amz-Credential", valid_611298
  var valid_611299 = header.getOrDefault("X-Amz-Security-Token")
  valid_611299 = validateParameter(valid_611299, JString, required = false,
                                 default = nil)
  if valid_611299 != nil:
    section.add "X-Amz-Security-Token", valid_611299
  var valid_611300 = header.getOrDefault("X-Amz-Algorithm")
  valid_611300 = validateParameter(valid_611300, JString, required = false,
                                 default = nil)
  if valid_611300 != nil:
    section.add "X-Amz-Algorithm", valid_611300
  var valid_611301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611301 = validateParameter(valid_611301, JString, required = false,
                                 default = nil)
  if valid_611301 != nil:
    section.add "X-Amz-SignedHeaders", valid_611301
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611302: Call_GetApplyEnvironmentManagedAction_611287;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Applies a scheduled managed action immediately. A managed action can be applied only if its status is <code>Scheduled</code>. Get the status and action ID of a managed action with <a>DescribeEnvironmentManagedActions</a>.
  ## 
  let valid = call_611302.validator(path, query, header, formData, body)
  let scheme = call_611302.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611302.url(scheme.get, call_611302.host, call_611302.base,
                         call_611302.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611302, url, valid)

proc call*(call_611303: Call_GetApplyEnvironmentManagedAction_611287;
          ActionId: string; EnvironmentName: string = "";
          Action: string = "ApplyEnvironmentManagedAction";
          Version: string = "2010-12-01"; EnvironmentId: string = ""): Recallable =
  ## getApplyEnvironmentManagedAction
  ## Applies a scheduled managed action immediately. A managed action can be applied only if its status is <code>Scheduled</code>. Get the status and action ID of a managed action with <a>DescribeEnvironmentManagedActions</a>.
  ##   ActionId: string (required)
  ##           : The action ID of the scheduled managed action to execute.
  ##   EnvironmentName: string
  ##                  : The name of the target environment.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   EnvironmentId: string
  ##                : The environment ID of the target environment.
  var query_611304 = newJObject()
  add(query_611304, "ActionId", newJString(ActionId))
  add(query_611304, "EnvironmentName", newJString(EnvironmentName))
  add(query_611304, "Action", newJString(Action))
  add(query_611304, "Version", newJString(Version))
  add(query_611304, "EnvironmentId", newJString(EnvironmentId))
  result = call_611303.call(nil, query_611304, nil, nil, nil)

var getApplyEnvironmentManagedAction* = Call_GetApplyEnvironmentManagedAction_611287(
    name: "getApplyEnvironmentManagedAction", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ApplyEnvironmentManagedAction",
    validator: validate_GetApplyEnvironmentManagedAction_611288, base: "/",
    url: url_GetApplyEnvironmentManagedAction_611289,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCheckDNSAvailability_611340 = ref object of OpenApiRestCall_610659
proc url_PostCheckDNSAvailability_611342(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCheckDNSAvailability_611341(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Checks if the specified CNAME is available.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611343 = query.getOrDefault("Action")
  valid_611343 = validateParameter(valid_611343, JString, required = true,
                                 default = newJString("CheckDNSAvailability"))
  if valid_611343 != nil:
    section.add "Action", valid_611343
  var valid_611344 = query.getOrDefault("Version")
  valid_611344 = validateParameter(valid_611344, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_611344 != nil:
    section.add "Version", valid_611344
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611345 = header.getOrDefault("X-Amz-Signature")
  valid_611345 = validateParameter(valid_611345, JString, required = false,
                                 default = nil)
  if valid_611345 != nil:
    section.add "X-Amz-Signature", valid_611345
  var valid_611346 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611346 = validateParameter(valid_611346, JString, required = false,
                                 default = nil)
  if valid_611346 != nil:
    section.add "X-Amz-Content-Sha256", valid_611346
  var valid_611347 = header.getOrDefault("X-Amz-Date")
  valid_611347 = validateParameter(valid_611347, JString, required = false,
                                 default = nil)
  if valid_611347 != nil:
    section.add "X-Amz-Date", valid_611347
  var valid_611348 = header.getOrDefault("X-Amz-Credential")
  valid_611348 = validateParameter(valid_611348, JString, required = false,
                                 default = nil)
  if valid_611348 != nil:
    section.add "X-Amz-Credential", valid_611348
  var valid_611349 = header.getOrDefault("X-Amz-Security-Token")
  valid_611349 = validateParameter(valid_611349, JString, required = false,
                                 default = nil)
  if valid_611349 != nil:
    section.add "X-Amz-Security-Token", valid_611349
  var valid_611350 = header.getOrDefault("X-Amz-Algorithm")
  valid_611350 = validateParameter(valid_611350, JString, required = false,
                                 default = nil)
  if valid_611350 != nil:
    section.add "X-Amz-Algorithm", valid_611350
  var valid_611351 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611351 = validateParameter(valid_611351, JString, required = false,
                                 default = nil)
  if valid_611351 != nil:
    section.add "X-Amz-SignedHeaders", valid_611351
  result.add "header", section
  ## parameters in `formData` object:
  ##   CNAMEPrefix: JString (required)
  ##              : The prefix used when this CNAME is reserved.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `CNAMEPrefix` field"
  var valid_611352 = formData.getOrDefault("CNAMEPrefix")
  valid_611352 = validateParameter(valid_611352, JString, required = true,
                                 default = nil)
  if valid_611352 != nil:
    section.add "CNAMEPrefix", valid_611352
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611353: Call_PostCheckDNSAvailability_611340; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Checks if the specified CNAME is available.
  ## 
  let valid = call_611353.validator(path, query, header, formData, body)
  let scheme = call_611353.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611353.url(scheme.get, call_611353.host, call_611353.base,
                         call_611353.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611353, url, valid)

proc call*(call_611354: Call_PostCheckDNSAvailability_611340; CNAMEPrefix: string;
          Action: string = "CheckDNSAvailability"; Version: string = "2010-12-01"): Recallable =
  ## postCheckDNSAvailability
  ## Checks if the specified CNAME is available.
  ##   CNAMEPrefix: string (required)
  ##              : The prefix used when this CNAME is reserved.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611355 = newJObject()
  var formData_611356 = newJObject()
  add(formData_611356, "CNAMEPrefix", newJString(CNAMEPrefix))
  add(query_611355, "Action", newJString(Action))
  add(query_611355, "Version", newJString(Version))
  result = call_611354.call(nil, query_611355, nil, formData_611356, nil)

var postCheckDNSAvailability* = Call_PostCheckDNSAvailability_611340(
    name: "postCheckDNSAvailability", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CheckDNSAvailability",
    validator: validate_PostCheckDNSAvailability_611341, base: "/",
    url: url_PostCheckDNSAvailability_611342, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCheckDNSAvailability_611324 = ref object of OpenApiRestCall_610659
proc url_GetCheckDNSAvailability_611326(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCheckDNSAvailability_611325(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Checks if the specified CNAME is available.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   CNAMEPrefix: JString (required)
  ##              : The prefix used when this CNAME is reserved.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `CNAMEPrefix` field"
  var valid_611327 = query.getOrDefault("CNAMEPrefix")
  valid_611327 = validateParameter(valid_611327, JString, required = true,
                                 default = nil)
  if valid_611327 != nil:
    section.add "CNAMEPrefix", valid_611327
  var valid_611328 = query.getOrDefault("Action")
  valid_611328 = validateParameter(valid_611328, JString, required = true,
                                 default = newJString("CheckDNSAvailability"))
  if valid_611328 != nil:
    section.add "Action", valid_611328
  var valid_611329 = query.getOrDefault("Version")
  valid_611329 = validateParameter(valid_611329, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_611329 != nil:
    section.add "Version", valid_611329
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611330 = header.getOrDefault("X-Amz-Signature")
  valid_611330 = validateParameter(valid_611330, JString, required = false,
                                 default = nil)
  if valid_611330 != nil:
    section.add "X-Amz-Signature", valid_611330
  var valid_611331 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611331 = validateParameter(valid_611331, JString, required = false,
                                 default = nil)
  if valid_611331 != nil:
    section.add "X-Amz-Content-Sha256", valid_611331
  var valid_611332 = header.getOrDefault("X-Amz-Date")
  valid_611332 = validateParameter(valid_611332, JString, required = false,
                                 default = nil)
  if valid_611332 != nil:
    section.add "X-Amz-Date", valid_611332
  var valid_611333 = header.getOrDefault("X-Amz-Credential")
  valid_611333 = validateParameter(valid_611333, JString, required = false,
                                 default = nil)
  if valid_611333 != nil:
    section.add "X-Amz-Credential", valid_611333
  var valid_611334 = header.getOrDefault("X-Amz-Security-Token")
  valid_611334 = validateParameter(valid_611334, JString, required = false,
                                 default = nil)
  if valid_611334 != nil:
    section.add "X-Amz-Security-Token", valid_611334
  var valid_611335 = header.getOrDefault("X-Amz-Algorithm")
  valid_611335 = validateParameter(valid_611335, JString, required = false,
                                 default = nil)
  if valid_611335 != nil:
    section.add "X-Amz-Algorithm", valid_611335
  var valid_611336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611336 = validateParameter(valid_611336, JString, required = false,
                                 default = nil)
  if valid_611336 != nil:
    section.add "X-Amz-SignedHeaders", valid_611336
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611337: Call_GetCheckDNSAvailability_611324; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Checks if the specified CNAME is available.
  ## 
  let valid = call_611337.validator(path, query, header, formData, body)
  let scheme = call_611337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611337.url(scheme.get, call_611337.host, call_611337.base,
                         call_611337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611337, url, valid)

proc call*(call_611338: Call_GetCheckDNSAvailability_611324; CNAMEPrefix: string;
          Action: string = "CheckDNSAvailability"; Version: string = "2010-12-01"): Recallable =
  ## getCheckDNSAvailability
  ## Checks if the specified CNAME is available.
  ##   CNAMEPrefix: string (required)
  ##              : The prefix used when this CNAME is reserved.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611339 = newJObject()
  add(query_611339, "CNAMEPrefix", newJString(CNAMEPrefix))
  add(query_611339, "Action", newJString(Action))
  add(query_611339, "Version", newJString(Version))
  result = call_611338.call(nil, query_611339, nil, nil, nil)

var getCheckDNSAvailability* = Call_GetCheckDNSAvailability_611324(
    name: "getCheckDNSAvailability", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CheckDNSAvailability",
    validator: validate_GetCheckDNSAvailability_611325, base: "/",
    url: url_GetCheckDNSAvailability_611326, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostComposeEnvironments_611375 = ref object of OpenApiRestCall_610659
proc url_PostComposeEnvironments_611377(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostComposeEnvironments_611376(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Create or update a group of environments that each run a separate component of a single application. Takes a list of version labels that specify application source bundles for each of the environments to create or update. The name of each environment and other required information must be included in the source bundles in an environment manifest named <code>env.yaml</code>. See <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-mgmt-compose.html">Compose Environments</a> for details.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611378 = query.getOrDefault("Action")
  valid_611378 = validateParameter(valid_611378, JString, required = true,
                                 default = newJString("ComposeEnvironments"))
  if valid_611378 != nil:
    section.add "Action", valid_611378
  var valid_611379 = query.getOrDefault("Version")
  valid_611379 = validateParameter(valid_611379, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_611379 != nil:
    section.add "Version", valid_611379
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611380 = header.getOrDefault("X-Amz-Signature")
  valid_611380 = validateParameter(valid_611380, JString, required = false,
                                 default = nil)
  if valid_611380 != nil:
    section.add "X-Amz-Signature", valid_611380
  var valid_611381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611381 = validateParameter(valid_611381, JString, required = false,
                                 default = nil)
  if valid_611381 != nil:
    section.add "X-Amz-Content-Sha256", valid_611381
  var valid_611382 = header.getOrDefault("X-Amz-Date")
  valid_611382 = validateParameter(valid_611382, JString, required = false,
                                 default = nil)
  if valid_611382 != nil:
    section.add "X-Amz-Date", valid_611382
  var valid_611383 = header.getOrDefault("X-Amz-Credential")
  valid_611383 = validateParameter(valid_611383, JString, required = false,
                                 default = nil)
  if valid_611383 != nil:
    section.add "X-Amz-Credential", valid_611383
  var valid_611384 = header.getOrDefault("X-Amz-Security-Token")
  valid_611384 = validateParameter(valid_611384, JString, required = false,
                                 default = nil)
  if valid_611384 != nil:
    section.add "X-Amz-Security-Token", valid_611384
  var valid_611385 = header.getOrDefault("X-Amz-Algorithm")
  valid_611385 = validateParameter(valid_611385, JString, required = false,
                                 default = nil)
  if valid_611385 != nil:
    section.add "X-Amz-Algorithm", valid_611385
  var valid_611386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611386 = validateParameter(valid_611386, JString, required = false,
                                 default = nil)
  if valid_611386 != nil:
    section.add "X-Amz-SignedHeaders", valid_611386
  result.add "header", section
  ## parameters in `formData` object:
  ##   GroupName: JString
  ##            : The name of the group to which the target environments belong. Specify a group name only if the environment name defined in each target environment's manifest ends with a + (plus) character. See <a 
  ## href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-cfg-manifest.html">Environment Manifest (env.yaml)</a> for details.
  ##   ApplicationName: JString
  ##                  : The name of the application to which the specified source bundles belong.
  ##   VersionLabels: JArray
  ##                : A list of version labels, specifying one or more application source bundles that belong to the target application. Each source bundle must include an environment manifest that specifies the name of the environment and the name of the solution stack to use, and optionally can specify environment links to create.
  section = newJObject()
  var valid_611387 = formData.getOrDefault("GroupName")
  valid_611387 = validateParameter(valid_611387, JString, required = false,
                                 default = nil)
  if valid_611387 != nil:
    section.add "GroupName", valid_611387
  var valid_611388 = formData.getOrDefault("ApplicationName")
  valid_611388 = validateParameter(valid_611388, JString, required = false,
                                 default = nil)
  if valid_611388 != nil:
    section.add "ApplicationName", valid_611388
  var valid_611389 = formData.getOrDefault("VersionLabels")
  valid_611389 = validateParameter(valid_611389, JArray, required = false,
                                 default = nil)
  if valid_611389 != nil:
    section.add "VersionLabels", valid_611389
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611390: Call_PostComposeEnvironments_611375; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create or update a group of environments that each run a separate component of a single application. Takes a list of version labels that specify application source bundles for each of the environments to create or update. The name of each environment and other required information must be included in the source bundles in an environment manifest named <code>env.yaml</code>. See <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-mgmt-compose.html">Compose Environments</a> for details.
  ## 
  let valid = call_611390.validator(path, query, header, formData, body)
  let scheme = call_611390.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611390.url(scheme.get, call_611390.host, call_611390.base,
                         call_611390.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611390, url, valid)

proc call*(call_611391: Call_PostComposeEnvironments_611375;
          GroupName: string = ""; ApplicationName: string = "";
          VersionLabels: JsonNode = nil; Action: string = "ComposeEnvironments";
          Version: string = "2010-12-01"): Recallable =
  ## postComposeEnvironments
  ## Create or update a group of environments that each run a separate component of a single application. Takes a list of version labels that specify application source bundles for each of the environments to create or update. The name of each environment and other required information must be included in the source bundles in an environment manifest named <code>env.yaml</code>. See <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-mgmt-compose.html">Compose Environments</a> for details.
  ##   GroupName: string
  ##            : The name of the group to which the target environments belong. Specify a group name only if the environment name defined in each target environment's manifest ends with a + (plus) character. See <a 
  ## href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-cfg-manifest.html">Environment Manifest (env.yaml)</a> for details.
  ##   ApplicationName: string
  ##                  : The name of the application to which the specified source bundles belong.
  ##   VersionLabels: JArray
  ##                : A list of version labels, specifying one or more application source bundles that belong to the target application. Each source bundle must include an environment manifest that specifies the name of the environment and the name of the solution stack to use, and optionally can specify environment links to create.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611392 = newJObject()
  var formData_611393 = newJObject()
  add(formData_611393, "GroupName", newJString(GroupName))
  add(formData_611393, "ApplicationName", newJString(ApplicationName))
  if VersionLabels != nil:
    formData_611393.add "VersionLabels", VersionLabels
  add(query_611392, "Action", newJString(Action))
  add(query_611392, "Version", newJString(Version))
  result = call_611391.call(nil, query_611392, nil, formData_611393, nil)

var postComposeEnvironments* = Call_PostComposeEnvironments_611375(
    name: "postComposeEnvironments", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ComposeEnvironments",
    validator: validate_PostComposeEnvironments_611376, base: "/",
    url: url_PostComposeEnvironments_611377, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetComposeEnvironments_611357 = ref object of OpenApiRestCall_610659
proc url_GetComposeEnvironments_611359(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetComposeEnvironments_611358(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Create or update a group of environments that each run a separate component of a single application. Takes a list of version labels that specify application source bundles for each of the environments to create or update. The name of each environment and other required information must be included in the source bundles in an environment manifest named <code>env.yaml</code>. See <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-mgmt-compose.html">Compose Environments</a> for details.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ApplicationName: JString
  ##                  : The name of the application to which the specified source bundles belong.
  ##   GroupName: JString
  ##            : The name of the group to which the target environments belong. Specify a group name only if the environment name defined in each target environment's manifest ends with a + (plus) character. See <a 
  ## href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-cfg-manifest.html">Environment Manifest (env.yaml)</a> for details.
  ##   VersionLabels: JArray
  ##                : A list of version labels, specifying one or more application source bundles that belong to the target application. Each source bundle must include an environment manifest that specifies the name of the environment and the name of the solution stack to use, and optionally can specify environment links to create.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611360 = query.getOrDefault("ApplicationName")
  valid_611360 = validateParameter(valid_611360, JString, required = false,
                                 default = nil)
  if valid_611360 != nil:
    section.add "ApplicationName", valid_611360
  var valid_611361 = query.getOrDefault("GroupName")
  valid_611361 = validateParameter(valid_611361, JString, required = false,
                                 default = nil)
  if valid_611361 != nil:
    section.add "GroupName", valid_611361
  var valid_611362 = query.getOrDefault("VersionLabels")
  valid_611362 = validateParameter(valid_611362, JArray, required = false,
                                 default = nil)
  if valid_611362 != nil:
    section.add "VersionLabels", valid_611362
  var valid_611363 = query.getOrDefault("Action")
  valid_611363 = validateParameter(valid_611363, JString, required = true,
                                 default = newJString("ComposeEnvironments"))
  if valid_611363 != nil:
    section.add "Action", valid_611363
  var valid_611364 = query.getOrDefault("Version")
  valid_611364 = validateParameter(valid_611364, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_611364 != nil:
    section.add "Version", valid_611364
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611365 = header.getOrDefault("X-Amz-Signature")
  valid_611365 = validateParameter(valid_611365, JString, required = false,
                                 default = nil)
  if valid_611365 != nil:
    section.add "X-Amz-Signature", valid_611365
  var valid_611366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611366 = validateParameter(valid_611366, JString, required = false,
                                 default = nil)
  if valid_611366 != nil:
    section.add "X-Amz-Content-Sha256", valid_611366
  var valid_611367 = header.getOrDefault("X-Amz-Date")
  valid_611367 = validateParameter(valid_611367, JString, required = false,
                                 default = nil)
  if valid_611367 != nil:
    section.add "X-Amz-Date", valid_611367
  var valid_611368 = header.getOrDefault("X-Amz-Credential")
  valid_611368 = validateParameter(valid_611368, JString, required = false,
                                 default = nil)
  if valid_611368 != nil:
    section.add "X-Amz-Credential", valid_611368
  var valid_611369 = header.getOrDefault("X-Amz-Security-Token")
  valid_611369 = validateParameter(valid_611369, JString, required = false,
                                 default = nil)
  if valid_611369 != nil:
    section.add "X-Amz-Security-Token", valid_611369
  var valid_611370 = header.getOrDefault("X-Amz-Algorithm")
  valid_611370 = validateParameter(valid_611370, JString, required = false,
                                 default = nil)
  if valid_611370 != nil:
    section.add "X-Amz-Algorithm", valid_611370
  var valid_611371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611371 = validateParameter(valid_611371, JString, required = false,
                                 default = nil)
  if valid_611371 != nil:
    section.add "X-Amz-SignedHeaders", valid_611371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611372: Call_GetComposeEnvironments_611357; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create or update a group of environments that each run a separate component of a single application. Takes a list of version labels that specify application source bundles for each of the environments to create or update. The name of each environment and other required information must be included in the source bundles in an environment manifest named <code>env.yaml</code>. See <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-mgmt-compose.html">Compose Environments</a> for details.
  ## 
  let valid = call_611372.validator(path, query, header, formData, body)
  let scheme = call_611372.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611372.url(scheme.get, call_611372.host, call_611372.base,
                         call_611372.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611372, url, valid)

proc call*(call_611373: Call_GetComposeEnvironments_611357;
          ApplicationName: string = ""; GroupName: string = "";
          VersionLabels: JsonNode = nil; Action: string = "ComposeEnvironments";
          Version: string = "2010-12-01"): Recallable =
  ## getComposeEnvironments
  ## Create or update a group of environments that each run a separate component of a single application. Takes a list of version labels that specify application source bundles for each of the environments to create or update. The name of each environment and other required information must be included in the source bundles in an environment manifest named <code>env.yaml</code>. See <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-mgmt-compose.html">Compose Environments</a> for details.
  ##   ApplicationName: string
  ##                  : The name of the application to which the specified source bundles belong.
  ##   GroupName: string
  ##            : The name of the group to which the target environments belong. Specify a group name only if the environment name defined in each target environment's manifest ends with a + (plus) character. See <a 
  ## href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-cfg-manifest.html">Environment Manifest (env.yaml)</a> for details.
  ##   VersionLabels: JArray
  ##                : A list of version labels, specifying one or more application source bundles that belong to the target application. Each source bundle must include an environment manifest that specifies the name of the environment and the name of the solution stack to use, and optionally can specify environment links to create.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611374 = newJObject()
  add(query_611374, "ApplicationName", newJString(ApplicationName))
  add(query_611374, "GroupName", newJString(GroupName))
  if VersionLabels != nil:
    query_611374.add "VersionLabels", VersionLabels
  add(query_611374, "Action", newJString(Action))
  add(query_611374, "Version", newJString(Version))
  result = call_611373.call(nil, query_611374, nil, nil, nil)

var getComposeEnvironments* = Call_GetComposeEnvironments_611357(
    name: "getComposeEnvironments", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ComposeEnvironments",
    validator: validate_GetComposeEnvironments_611358, base: "/",
    url: url_GetComposeEnvironments_611359, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateApplication_611414 = ref object of OpenApiRestCall_610659
proc url_PostCreateApplication_611416(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateApplication_611415(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Creates an application that has one configuration template named <code>default</code> and no application versions. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611417 = query.getOrDefault("Action")
  valid_611417 = validateParameter(valid_611417, JString, required = true,
                                 default = newJString("CreateApplication"))
  if valid_611417 != nil:
    section.add "Action", valid_611417
  var valid_611418 = query.getOrDefault("Version")
  valid_611418 = validateParameter(valid_611418, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_611418 != nil:
    section.add "Version", valid_611418
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611419 = header.getOrDefault("X-Amz-Signature")
  valid_611419 = validateParameter(valid_611419, JString, required = false,
                                 default = nil)
  if valid_611419 != nil:
    section.add "X-Amz-Signature", valid_611419
  var valid_611420 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611420 = validateParameter(valid_611420, JString, required = false,
                                 default = nil)
  if valid_611420 != nil:
    section.add "X-Amz-Content-Sha256", valid_611420
  var valid_611421 = header.getOrDefault("X-Amz-Date")
  valid_611421 = validateParameter(valid_611421, JString, required = false,
                                 default = nil)
  if valid_611421 != nil:
    section.add "X-Amz-Date", valid_611421
  var valid_611422 = header.getOrDefault("X-Amz-Credential")
  valid_611422 = validateParameter(valid_611422, JString, required = false,
                                 default = nil)
  if valid_611422 != nil:
    section.add "X-Amz-Credential", valid_611422
  var valid_611423 = header.getOrDefault("X-Amz-Security-Token")
  valid_611423 = validateParameter(valid_611423, JString, required = false,
                                 default = nil)
  if valid_611423 != nil:
    section.add "X-Amz-Security-Token", valid_611423
  var valid_611424 = header.getOrDefault("X-Amz-Algorithm")
  valid_611424 = validateParameter(valid_611424, JString, required = false,
                                 default = nil)
  if valid_611424 != nil:
    section.add "X-Amz-Algorithm", valid_611424
  var valid_611425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611425 = validateParameter(valid_611425, JString, required = false,
                                 default = nil)
  if valid_611425 != nil:
    section.add "X-Amz-SignedHeaders", valid_611425
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceLifecycleConfig.VersionLifecycleConfig: JString
  ##                                                 : The resource lifecycle configuration for an application. Defines lifecycle settings for resources that belong to the application, and the service role that Elastic Beanstalk assumes in order to apply lifecycle settings. The version lifecycle configuration defines lifecycle settings for application versions.
  ## The application version lifecycle configuration.
  ##   ResourceLifecycleConfig.ServiceRole: JString
  ##                                      : The resource lifecycle configuration for an application. Defines lifecycle settings for resources that belong to the application, and the service role that Elastic Beanstalk assumes in order to apply lifecycle settings. The version lifecycle configuration defines lifecycle settings for application versions.
  ## <p>The ARN of an IAM service role that Elastic Beanstalk has permission to assume.</p> <p>The <code>ServiceRole</code> property is required the first time that you provide a <code>VersionLifecycleConfig</code> for the application in one of the supporting calls (<code>CreateApplication</code> or <code>UpdateApplicationResourceLifecycle</code>). After you provide it once, in either one of the calls, Elastic Beanstalk persists the Service Role with the application, and you don't need to specify it again in subsequent <code>UpdateApplicationResourceLifecycle</code> calls. You can, however, specify it in subsequent calls to change the Service Role to another value.</p>
  ##   Description: JString
  ##              : Describes the application.
  ##   ApplicationName: JString (required)
  ##                  : <p>The name of the application.</p> <p>Constraint: This name must be unique within your account. If the specified name already exists, the action returns an <code>InvalidParameterValue</code> error.</p>
  ##   Tags: JArray
  ##       : <p>Specifies the tags applied to the application.</p> <p>Elastic Beanstalk applies these tags only to the application. Environments that you create in the application don't inherit the tags.</p>
  section = newJObject()
  var valid_611426 = formData.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_611426 = validateParameter(valid_611426, JString, required = false,
                                 default = nil)
  if valid_611426 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_611426
  var valid_611427 = formData.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_611427 = validateParameter(valid_611427, JString, required = false,
                                 default = nil)
  if valid_611427 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_611427
  var valid_611428 = formData.getOrDefault("Description")
  valid_611428 = validateParameter(valid_611428, JString, required = false,
                                 default = nil)
  if valid_611428 != nil:
    section.add "Description", valid_611428
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_611429 = formData.getOrDefault("ApplicationName")
  valid_611429 = validateParameter(valid_611429, JString, required = true,
                                 default = nil)
  if valid_611429 != nil:
    section.add "ApplicationName", valid_611429
  var valid_611430 = formData.getOrDefault("Tags")
  valid_611430 = validateParameter(valid_611430, JArray, required = false,
                                 default = nil)
  if valid_611430 != nil:
    section.add "Tags", valid_611430
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611431: Call_PostCreateApplication_611414; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates an application that has one configuration template named <code>default</code> and no application versions. 
  ## 
  let valid = call_611431.validator(path, query, header, formData, body)
  let scheme = call_611431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611431.url(scheme.get, call_611431.host, call_611431.base,
                         call_611431.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611431, url, valid)

proc call*(call_611432: Call_PostCreateApplication_611414; ApplicationName: string;
          ResourceLifecycleConfigVersionLifecycleConfig: string = "";
          ResourceLifecycleConfigServiceRole: string = ""; Description: string = "";
          Action: string = "CreateApplication"; Tags: JsonNode = nil;
          Version: string = "2010-12-01"): Recallable =
  ## postCreateApplication
  ##  Creates an application that has one configuration template named <code>default</code> and no application versions. 
  ##   ResourceLifecycleConfigVersionLifecycleConfig: string
  ##                                                : The resource lifecycle configuration for an application. Defines lifecycle settings for resources that belong to the application, and the service role that Elastic Beanstalk assumes in order to apply lifecycle settings. The version lifecycle configuration defines lifecycle settings for application versions.
  ## The application version lifecycle configuration.
  ##   ResourceLifecycleConfigServiceRole: string
  ##                                     : The resource lifecycle configuration for an application. Defines lifecycle settings for resources that belong to the application, and the service role that Elastic Beanstalk assumes in order to apply lifecycle settings. The version lifecycle configuration defines lifecycle settings for application versions.
  ## <p>The ARN of an IAM service role that Elastic Beanstalk has permission to assume.</p> <p>The <code>ServiceRole</code> property is required the first time that you provide a <code>VersionLifecycleConfig</code> for the application in one of the supporting calls (<code>CreateApplication</code> or <code>UpdateApplicationResourceLifecycle</code>). After you provide it once, in either one of the calls, Elastic Beanstalk persists the Service Role with the application, and you don't need to specify it again in subsequent <code>UpdateApplicationResourceLifecycle</code> calls. You can, however, specify it in subsequent calls to change the Service Role to another value.</p>
  ##   Description: string
  ##              : Describes the application.
  ##   ApplicationName: string (required)
  ##                  : <p>The name of the application.</p> <p>Constraint: This name must be unique within your account. If the specified name already exists, the action returns an <code>InvalidParameterValue</code> error.</p>
  ##   Action: string (required)
  ##   Tags: JArray
  ##       : <p>Specifies the tags applied to the application.</p> <p>Elastic Beanstalk applies these tags only to the application. Environments that you create in the application don't inherit the tags.</p>
  ##   Version: string (required)
  var query_611433 = newJObject()
  var formData_611434 = newJObject()
  add(formData_611434, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  add(formData_611434, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  add(formData_611434, "Description", newJString(Description))
  add(formData_611434, "ApplicationName", newJString(ApplicationName))
  add(query_611433, "Action", newJString(Action))
  if Tags != nil:
    formData_611434.add "Tags", Tags
  add(query_611433, "Version", newJString(Version))
  result = call_611432.call(nil, query_611433, nil, formData_611434, nil)

var postCreateApplication* = Call_PostCreateApplication_611414(
    name: "postCreateApplication", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateApplication",
    validator: validate_PostCreateApplication_611415, base: "/",
    url: url_PostCreateApplication_611416, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateApplication_611394 = ref object of OpenApiRestCall_610659
proc url_GetCreateApplication_611396(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateApplication_611395(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Creates an application that has one configuration template named <code>default</code> and no application versions. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ApplicationName: JString (required)
  ##                  : <p>The name of the application.</p> <p>Constraint: This name must be unique within your account. If the specified name already exists, the action returns an <code>InvalidParameterValue</code> error.</p>
  ##   ResourceLifecycleConfig.ServiceRole: JString
  ##                                      : The resource lifecycle configuration for an application. Defines lifecycle settings for resources that belong to the application, and the service role that Elastic Beanstalk assumes in order to apply lifecycle settings. The version lifecycle configuration defines lifecycle settings for application versions.
  ## <p>The ARN of an IAM service role that Elastic Beanstalk has permission to assume.</p> <p>The <code>ServiceRole</code> property is required the first time that you provide a <code>VersionLifecycleConfig</code> for the application in one of the supporting calls (<code>CreateApplication</code> or <code>UpdateApplicationResourceLifecycle</code>). After you provide it once, in either one of the calls, Elastic Beanstalk persists the Service Role with the application, and you don't need to specify it again in subsequent <code>UpdateApplicationResourceLifecycle</code> calls. You can, however, specify it in subsequent calls to change the Service Role to another value.</p>
  ##   Tags: JArray
  ##       : <p>Specifies the tags applied to the application.</p> <p>Elastic Beanstalk applies these tags only to the application. Environments that you create in the application don't inherit the tags.</p>
  ##   ResourceLifecycleConfig.VersionLifecycleConfig: JString
  ##                                                 : The resource lifecycle configuration for an application. Defines lifecycle settings for resources that belong to the application, and the service role that Elastic Beanstalk assumes in order to apply lifecycle settings. The version lifecycle configuration defines lifecycle settings for application versions.
  ## The application version lifecycle configuration.
  ##   Action: JString (required)
  ##   Description: JString
  ##              : Describes the application.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_611397 = query.getOrDefault("ApplicationName")
  valid_611397 = validateParameter(valid_611397, JString, required = true,
                                 default = nil)
  if valid_611397 != nil:
    section.add "ApplicationName", valid_611397
  var valid_611398 = query.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_611398 = validateParameter(valid_611398, JString, required = false,
                                 default = nil)
  if valid_611398 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_611398
  var valid_611399 = query.getOrDefault("Tags")
  valid_611399 = validateParameter(valid_611399, JArray, required = false,
                                 default = nil)
  if valid_611399 != nil:
    section.add "Tags", valid_611399
  var valid_611400 = query.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_611400 = validateParameter(valid_611400, JString, required = false,
                                 default = nil)
  if valid_611400 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_611400
  var valid_611401 = query.getOrDefault("Action")
  valid_611401 = validateParameter(valid_611401, JString, required = true,
                                 default = newJString("CreateApplication"))
  if valid_611401 != nil:
    section.add "Action", valid_611401
  var valid_611402 = query.getOrDefault("Description")
  valid_611402 = validateParameter(valid_611402, JString, required = false,
                                 default = nil)
  if valid_611402 != nil:
    section.add "Description", valid_611402
  var valid_611403 = query.getOrDefault("Version")
  valid_611403 = validateParameter(valid_611403, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_611403 != nil:
    section.add "Version", valid_611403
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611404 = header.getOrDefault("X-Amz-Signature")
  valid_611404 = validateParameter(valid_611404, JString, required = false,
                                 default = nil)
  if valid_611404 != nil:
    section.add "X-Amz-Signature", valid_611404
  var valid_611405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611405 = validateParameter(valid_611405, JString, required = false,
                                 default = nil)
  if valid_611405 != nil:
    section.add "X-Amz-Content-Sha256", valid_611405
  var valid_611406 = header.getOrDefault("X-Amz-Date")
  valid_611406 = validateParameter(valid_611406, JString, required = false,
                                 default = nil)
  if valid_611406 != nil:
    section.add "X-Amz-Date", valid_611406
  var valid_611407 = header.getOrDefault("X-Amz-Credential")
  valid_611407 = validateParameter(valid_611407, JString, required = false,
                                 default = nil)
  if valid_611407 != nil:
    section.add "X-Amz-Credential", valid_611407
  var valid_611408 = header.getOrDefault("X-Amz-Security-Token")
  valid_611408 = validateParameter(valid_611408, JString, required = false,
                                 default = nil)
  if valid_611408 != nil:
    section.add "X-Amz-Security-Token", valid_611408
  var valid_611409 = header.getOrDefault("X-Amz-Algorithm")
  valid_611409 = validateParameter(valid_611409, JString, required = false,
                                 default = nil)
  if valid_611409 != nil:
    section.add "X-Amz-Algorithm", valid_611409
  var valid_611410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611410 = validateParameter(valid_611410, JString, required = false,
                                 default = nil)
  if valid_611410 != nil:
    section.add "X-Amz-SignedHeaders", valid_611410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611411: Call_GetCreateApplication_611394; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates an application that has one configuration template named <code>default</code> and no application versions. 
  ## 
  let valid = call_611411.validator(path, query, header, formData, body)
  let scheme = call_611411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611411.url(scheme.get, call_611411.host, call_611411.base,
                         call_611411.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611411, url, valid)

proc call*(call_611412: Call_GetCreateApplication_611394; ApplicationName: string;
          ResourceLifecycleConfigServiceRole: string = ""; Tags: JsonNode = nil;
          ResourceLifecycleConfigVersionLifecycleConfig: string = "";
          Action: string = "CreateApplication"; Description: string = "";
          Version: string = "2010-12-01"): Recallable =
  ## getCreateApplication
  ##  Creates an application that has one configuration template named <code>default</code> and no application versions. 
  ##   ApplicationName: string (required)
  ##                  : <p>The name of the application.</p> <p>Constraint: This name must be unique within your account. If the specified name already exists, the action returns an <code>InvalidParameterValue</code> error.</p>
  ##   ResourceLifecycleConfigServiceRole: string
  ##                                     : The resource lifecycle configuration for an application. Defines lifecycle settings for resources that belong to the application, and the service role that Elastic Beanstalk assumes in order to apply lifecycle settings. The version lifecycle configuration defines lifecycle settings for application versions.
  ## <p>The ARN of an IAM service role that Elastic Beanstalk has permission to assume.</p> <p>The <code>ServiceRole</code> property is required the first time that you provide a <code>VersionLifecycleConfig</code> for the application in one of the supporting calls (<code>CreateApplication</code> or <code>UpdateApplicationResourceLifecycle</code>). After you provide it once, in either one of the calls, Elastic Beanstalk persists the Service Role with the application, and you don't need to specify it again in subsequent <code>UpdateApplicationResourceLifecycle</code> calls. You can, however, specify it in subsequent calls to change the Service Role to another value.</p>
  ##   Tags: JArray
  ##       : <p>Specifies the tags applied to the application.</p> <p>Elastic Beanstalk applies these tags only to the application. Environments that you create in the application don't inherit the tags.</p>
  ##   ResourceLifecycleConfigVersionLifecycleConfig: string
  ##                                                : The resource lifecycle configuration for an application. Defines lifecycle settings for resources that belong to the application, and the service role that Elastic Beanstalk assumes in order to apply lifecycle settings. The version lifecycle configuration defines lifecycle settings for application versions.
  ## The application version lifecycle configuration.
  ##   Action: string (required)
  ##   Description: string
  ##              : Describes the application.
  ##   Version: string (required)
  var query_611413 = newJObject()
  add(query_611413, "ApplicationName", newJString(ApplicationName))
  add(query_611413, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  if Tags != nil:
    query_611413.add "Tags", Tags
  add(query_611413, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  add(query_611413, "Action", newJString(Action))
  add(query_611413, "Description", newJString(Description))
  add(query_611413, "Version", newJString(Version))
  result = call_611412.call(nil, query_611413, nil, nil, nil)

var getCreateApplication* = Call_GetCreateApplication_611394(
    name: "getCreateApplication", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateApplication",
    validator: validate_GetCreateApplication_611395, base: "/",
    url: url_GetCreateApplication_611396, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateApplicationVersion_611466 = ref object of OpenApiRestCall_610659
proc url_PostCreateApplicationVersion_611468(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateApplicationVersion_611467(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an application version for the specified application. You can create an application version from a source bundle in Amazon S3, a commit in AWS CodeCommit, or the output of an AWS CodeBuild build as follows:</p> <p>Specify a commit in an AWS CodeCommit repository with <code>SourceBuildInformation</code>.</p> <p>Specify a build in an AWS CodeBuild with <code>SourceBuildInformation</code> and <code>BuildConfiguration</code>.</p> <p>Specify a source bundle in S3 with <code>SourceBundle</code> </p> <p>Omit both <code>SourceBuildInformation</code> and <code>SourceBundle</code> to use the default sample application.</p> <note> <p>Once you create an application version with a specified Amazon S3 bucket and key location, you cannot change that Amazon S3 location. If you change the Amazon S3 location, you receive an exception when you attempt to launch an environment from the application version.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611469 = query.getOrDefault("Action")
  valid_611469 = validateParameter(valid_611469, JString, required = true, default = newJString(
      "CreateApplicationVersion"))
  if valid_611469 != nil:
    section.add "Action", valid_611469
  var valid_611470 = query.getOrDefault("Version")
  valid_611470 = validateParameter(valid_611470, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_611470 != nil:
    section.add "Version", valid_611470
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611471 = header.getOrDefault("X-Amz-Signature")
  valid_611471 = validateParameter(valid_611471, JString, required = false,
                                 default = nil)
  if valid_611471 != nil:
    section.add "X-Amz-Signature", valid_611471
  var valid_611472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611472 = validateParameter(valid_611472, JString, required = false,
                                 default = nil)
  if valid_611472 != nil:
    section.add "X-Amz-Content-Sha256", valid_611472
  var valid_611473 = header.getOrDefault("X-Amz-Date")
  valid_611473 = validateParameter(valid_611473, JString, required = false,
                                 default = nil)
  if valid_611473 != nil:
    section.add "X-Amz-Date", valid_611473
  var valid_611474 = header.getOrDefault("X-Amz-Credential")
  valid_611474 = validateParameter(valid_611474, JString, required = false,
                                 default = nil)
  if valid_611474 != nil:
    section.add "X-Amz-Credential", valid_611474
  var valid_611475 = header.getOrDefault("X-Amz-Security-Token")
  valid_611475 = validateParameter(valid_611475, JString, required = false,
                                 default = nil)
  if valid_611475 != nil:
    section.add "X-Amz-Security-Token", valid_611475
  var valid_611476 = header.getOrDefault("X-Amz-Algorithm")
  valid_611476 = validateParameter(valid_611476, JString, required = false,
                                 default = nil)
  if valid_611476 != nil:
    section.add "X-Amz-Algorithm", valid_611476
  var valid_611477 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611477 = validateParameter(valid_611477, JString, required = false,
                                 default = nil)
  if valid_611477 != nil:
    section.add "X-Amz-SignedHeaders", valid_611477
  result.add "header", section
  ## parameters in `formData` object:
  ##   BuildConfiguration.ComputeType: JString
  ##                                 : Settings for an AWS CodeBuild build.
  ## <p>Information about the compute resources the build project will use.</p> <ul> <li> <p> <code>BUILD_GENERAL1_SMALL: Use up to 3 GB memory and 2 vCPUs for builds</code> </p> </li> <li> <p> <code>BUILD_GENERAL1_MEDIUM: Use up to 7 GB memory and 4 vCPUs for builds</code> </p> </li> <li> <p> <code>BUILD_GENERAL1_LARGE: Use up to 15 GB memory and 8 vCPUs for builds</code> </p> </li> </ul>
  ##   SourceBundle.S3Key: JString
  ##                     : The bucket and key of an item stored in Amazon S3.
  ## The Amazon S3 key where the data is located.
  ##   Process: JBool
  ##          : <p>Pre-processes and validates the environment manifest (<code>env.yaml</code>) and configuration files (<code>*.config</code> files in the <code>.ebextensions</code> folder) in the source bundle. Validating configuration files can identify issues prior to deploying the application version to an environment.</p> <p>You must turn processing on for application versions that you create using AWS CodeBuild or AWS CodeCommit. For application versions built from a source bundle in Amazon S3, processing is optional.</p> <note> <p>The <code>Process</code> option validates Elastic Beanstalk configuration files. It doesn't validate your application's configuration files, like proxy server or Docker configuration.</p> </note>
  ##   SourceBuildInformation.SourceType: JString
  ##                                    : Location of the source code for an application version.
  ## <p>The type of repository.</p> <ul> <li> <p> <code>Git</code> </p> </li> <li> <p> <code>Zip</code> </p> </li> </ul>
  ##   BuildConfiguration.ArtifactName: JString
  ##                                  : Settings for an AWS CodeBuild build.
  ## The name of the artifact of the CodeBuild build. If provided, Elastic Beanstalk stores the build artifact in the S3 location 
  ## <i>S3-bucket</i>/resources/<i>application-name</i>/codebuild/codebuild-<i>version-label</i>-<i>artifact-name</i>.zip. If not provided, Elastic Beanstalk stores the build artifact in the S3 location 
  ## <i>S3-bucket</i>/resources/<i>application-name</i>/codebuild/codebuild-<i>version-label</i>.zip. 
  ##   Description: JString
  ##              : Describes this version.
  ##   VersionLabel: JString (required)
  ##               : <p>A label identifying this version.</p> <p>Constraint: Must be unique per application. If an application version already exists with this label for the specified application, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. </p>
  ##   SourceBuildInformation.SourceRepository: JString
  ##                                          : Location of the source code for an application version.
  ## <p>Location where the repository is stored.</p> <ul> <li> <p> <code>CodeCommit</code> </p> </li> <li> <p> <code>S3</code> </p> </li> </ul>
  ##   AutoCreateApplication: JBool
  ##                        : Set to <code>true</code> to create an application with the specified name if it doesn't already exist.
  ##   SourceBuildInformation.SourceLocation: JString
  ##                                        : Location of the source code for an application version.
  ## <p>The location of the source code, as a formatted string, depending on the value of <code>SourceRepository</code> </p> <ul> <li> <p>For <code>CodeCommit</code>, the format is the repository name and commit ID, separated by a forward slash. For example, <code>my-git-repo/265cfa0cf6af46153527f55d6503ec030551f57a</code>.</p> </li> <li> <p>For <code>S3</code>, the format is the S3 bucket name and object key, separated by a forward slash. For example, <code>my-s3-bucket/Folders/my-source-file</code>.</p> </li> </ul>
  ##   ApplicationName: JString (required)
  ##                  :  The name of the application. If no application is found with this name, and <code>AutoCreateApplication</code> is <code>false</code>, returns an <code>InvalidParameterValue</code> error. 
  ##   BuildConfiguration.Image: JString
  ##                           : Settings for an AWS CodeBuild build.
  ## The ID of the Docker image to use for this build project.
  ##   BuildConfiguration.TimeoutInMinutes: JString
  ##                                      : Settings for an AWS CodeBuild build.
  ## How long in minutes, from 5 to 480 (8 hours), for AWS CodeBuild to wait until timing out any related build that does not get marked as completed. The default is 60 minutes.
  ##   Tags: JArray
  ##       : <p>Specifies the tags applied to the application version.</p> <p>Elastic Beanstalk applies these tags only to the application version. Environments that use the application version don't inherit the tags.</p>
  ##   SourceBundle.S3Bucket: JString
  ##                        : The bucket and key of an item stored in Amazon S3.
  ## The Amazon S3 bucket where the data is located.
  ##   BuildConfiguration.CodeBuildServiceRole: JString
  ##                                          : Settings for an AWS CodeBuild build.
  ## The Amazon Resource Name (ARN) of the AWS Identity and Access Management (IAM) role that enables AWS CodeBuild to interact with dependent AWS services on behalf of the AWS account.
  section = newJObject()
  var valid_611478 = formData.getOrDefault("BuildConfiguration.ComputeType")
  valid_611478 = validateParameter(valid_611478, JString, required = false,
                                 default = nil)
  if valid_611478 != nil:
    section.add "BuildConfiguration.ComputeType", valid_611478
  var valid_611479 = formData.getOrDefault("SourceBundle.S3Key")
  valid_611479 = validateParameter(valid_611479, JString, required = false,
                                 default = nil)
  if valid_611479 != nil:
    section.add "SourceBundle.S3Key", valid_611479
  var valid_611480 = formData.getOrDefault("Process")
  valid_611480 = validateParameter(valid_611480, JBool, required = false, default = nil)
  if valid_611480 != nil:
    section.add "Process", valid_611480
  var valid_611481 = formData.getOrDefault("SourceBuildInformation.SourceType")
  valid_611481 = validateParameter(valid_611481, JString, required = false,
                                 default = nil)
  if valid_611481 != nil:
    section.add "SourceBuildInformation.SourceType", valid_611481
  var valid_611482 = formData.getOrDefault("BuildConfiguration.ArtifactName")
  valid_611482 = validateParameter(valid_611482, JString, required = false,
                                 default = nil)
  if valid_611482 != nil:
    section.add "BuildConfiguration.ArtifactName", valid_611482
  var valid_611483 = formData.getOrDefault("Description")
  valid_611483 = validateParameter(valid_611483, JString, required = false,
                                 default = nil)
  if valid_611483 != nil:
    section.add "Description", valid_611483
  assert formData != nil,
        "formData argument is necessary due to required `VersionLabel` field"
  var valid_611484 = formData.getOrDefault("VersionLabel")
  valid_611484 = validateParameter(valid_611484, JString, required = true,
                                 default = nil)
  if valid_611484 != nil:
    section.add "VersionLabel", valid_611484
  var valid_611485 = formData.getOrDefault("SourceBuildInformation.SourceRepository")
  valid_611485 = validateParameter(valid_611485, JString, required = false,
                                 default = nil)
  if valid_611485 != nil:
    section.add "SourceBuildInformation.SourceRepository", valid_611485
  var valid_611486 = formData.getOrDefault("AutoCreateApplication")
  valid_611486 = validateParameter(valid_611486, JBool, required = false, default = nil)
  if valid_611486 != nil:
    section.add "AutoCreateApplication", valid_611486
  var valid_611487 = formData.getOrDefault("SourceBuildInformation.SourceLocation")
  valid_611487 = validateParameter(valid_611487, JString, required = false,
                                 default = nil)
  if valid_611487 != nil:
    section.add "SourceBuildInformation.SourceLocation", valid_611487
  var valid_611488 = formData.getOrDefault("ApplicationName")
  valid_611488 = validateParameter(valid_611488, JString, required = true,
                                 default = nil)
  if valid_611488 != nil:
    section.add "ApplicationName", valid_611488
  var valid_611489 = formData.getOrDefault("BuildConfiguration.Image")
  valid_611489 = validateParameter(valid_611489, JString, required = false,
                                 default = nil)
  if valid_611489 != nil:
    section.add "BuildConfiguration.Image", valid_611489
  var valid_611490 = formData.getOrDefault("BuildConfiguration.TimeoutInMinutes")
  valid_611490 = validateParameter(valid_611490, JString, required = false,
                                 default = nil)
  if valid_611490 != nil:
    section.add "BuildConfiguration.TimeoutInMinutes", valid_611490
  var valid_611491 = formData.getOrDefault("Tags")
  valid_611491 = validateParameter(valid_611491, JArray, required = false,
                                 default = nil)
  if valid_611491 != nil:
    section.add "Tags", valid_611491
  var valid_611492 = formData.getOrDefault("SourceBundle.S3Bucket")
  valid_611492 = validateParameter(valid_611492, JString, required = false,
                                 default = nil)
  if valid_611492 != nil:
    section.add "SourceBundle.S3Bucket", valid_611492
  var valid_611493 = formData.getOrDefault("BuildConfiguration.CodeBuildServiceRole")
  valid_611493 = validateParameter(valid_611493, JString, required = false,
                                 default = nil)
  if valid_611493 != nil:
    section.add "BuildConfiguration.CodeBuildServiceRole", valid_611493
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611494: Call_PostCreateApplicationVersion_611466; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an application version for the specified application. You can create an application version from a source bundle in Amazon S3, a commit in AWS CodeCommit, or the output of an AWS CodeBuild build as follows:</p> <p>Specify a commit in an AWS CodeCommit repository with <code>SourceBuildInformation</code>.</p> <p>Specify a build in an AWS CodeBuild with <code>SourceBuildInformation</code> and <code>BuildConfiguration</code>.</p> <p>Specify a source bundle in S3 with <code>SourceBundle</code> </p> <p>Omit both <code>SourceBuildInformation</code> and <code>SourceBundle</code> to use the default sample application.</p> <note> <p>Once you create an application version with a specified Amazon S3 bucket and key location, you cannot change that Amazon S3 location. If you change the Amazon S3 location, you receive an exception when you attempt to launch an environment from the application version.</p> </note>
  ## 
  let valid = call_611494.validator(path, query, header, formData, body)
  let scheme = call_611494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611494.url(scheme.get, call_611494.host, call_611494.base,
                         call_611494.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611494, url, valid)

proc call*(call_611495: Call_PostCreateApplicationVersion_611466;
          VersionLabel: string; ApplicationName: string;
          BuildConfigurationComputeType: string = "";
          SourceBundleS3Key: string = ""; Process: bool = false;
          SourceBuildInformationSourceType: string = "";
          BuildConfigurationArtifactName: string = ""; Description: string = "";
          SourceBuildInformationSourceRepository: string = "";
          AutoCreateApplication: bool = false;
          SourceBuildInformationSourceLocation: string = "";
          Action: string = "CreateApplicationVersion";
          BuildConfigurationImage: string = "";
          BuildConfigurationTimeoutInMinutes: string = ""; Tags: JsonNode = nil;
          SourceBundleS3Bucket: string = ""; Version: string = "2010-12-01";
          BuildConfigurationCodeBuildServiceRole: string = ""): Recallable =
  ## postCreateApplicationVersion
  ## <p>Creates an application version for the specified application. You can create an application version from a source bundle in Amazon S3, a commit in AWS CodeCommit, or the output of an AWS CodeBuild build as follows:</p> <p>Specify a commit in an AWS CodeCommit repository with <code>SourceBuildInformation</code>.</p> <p>Specify a build in an AWS CodeBuild with <code>SourceBuildInformation</code> and <code>BuildConfiguration</code>.</p> <p>Specify a source bundle in S3 with <code>SourceBundle</code> </p> <p>Omit both <code>SourceBuildInformation</code> and <code>SourceBundle</code> to use the default sample application.</p> <note> <p>Once you create an application version with a specified Amazon S3 bucket and key location, you cannot change that Amazon S3 location. If you change the Amazon S3 location, you receive an exception when you attempt to launch an environment from the application version.</p> </note>
  ##   BuildConfigurationComputeType: string
  ##                                : Settings for an AWS CodeBuild build.
  ## <p>Information about the compute resources the build project will use.</p> <ul> <li> <p> <code>BUILD_GENERAL1_SMALL: Use up to 3 GB memory and 2 vCPUs for builds</code> </p> </li> <li> <p> <code>BUILD_GENERAL1_MEDIUM: Use up to 7 GB memory and 4 vCPUs for builds</code> </p> </li> <li> <p> <code>BUILD_GENERAL1_LARGE: Use up to 15 GB memory and 8 vCPUs for builds</code> </p> </li> </ul>
  ##   SourceBundleS3Key: string
  ##                    : The bucket and key of an item stored in Amazon S3.
  ## The Amazon S3 key where the data is located.
  ##   Process: bool
  ##          : <p>Pre-processes and validates the environment manifest (<code>env.yaml</code>) and configuration files (<code>*.config</code> files in the <code>.ebextensions</code> folder) in the source bundle. Validating configuration files can identify issues prior to deploying the application version to an environment.</p> <p>You must turn processing on for application versions that you create using AWS CodeBuild or AWS CodeCommit. For application versions built from a source bundle in Amazon S3, processing is optional.</p> <note> <p>The <code>Process</code> option validates Elastic Beanstalk configuration files. It doesn't validate your application's configuration files, like proxy server or Docker configuration.</p> </note>
  ##   SourceBuildInformationSourceType: string
  ##                                   : Location of the source code for an application version.
  ## <p>The type of repository.</p> <ul> <li> <p> <code>Git</code> </p> </li> <li> <p> <code>Zip</code> </p> </li> </ul>
  ##   BuildConfigurationArtifactName: string
  ##                                 : Settings for an AWS CodeBuild build.
  ## The name of the artifact of the CodeBuild build. If provided, Elastic Beanstalk stores the build artifact in the S3 location 
  ## <i>S3-bucket</i>/resources/<i>application-name</i>/codebuild/codebuild-<i>version-label</i>-<i>artifact-name</i>.zip. If not provided, Elastic Beanstalk stores the build artifact in the S3 location 
  ## <i>S3-bucket</i>/resources/<i>application-name</i>/codebuild/codebuild-<i>version-label</i>.zip. 
  ##   Description: string
  ##              : Describes this version.
  ##   VersionLabel: string (required)
  ##               : <p>A label identifying this version.</p> <p>Constraint: Must be unique per application. If an application version already exists with this label for the specified application, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. </p>
  ##   SourceBuildInformationSourceRepository: string
  ##                                         : Location of the source code for an application version.
  ## <p>Location where the repository is stored.</p> <ul> <li> <p> <code>CodeCommit</code> </p> </li> <li> <p> <code>S3</code> </p> </li> </ul>
  ##   AutoCreateApplication: bool
  ##                        : Set to <code>true</code> to create an application with the specified name if it doesn't already exist.
  ##   SourceBuildInformationSourceLocation: string
  ##                                       : Location of the source code for an application version.
  ## <p>The location of the source code, as a formatted string, depending on the value of <code>SourceRepository</code> </p> <ul> <li> <p>For <code>CodeCommit</code>, the format is the repository name and commit ID, separated by a forward slash. For example, <code>my-git-repo/265cfa0cf6af46153527f55d6503ec030551f57a</code>.</p> </li> <li> <p>For <code>S3</code>, the format is the S3 bucket name and object key, separated by a forward slash. For example, <code>my-s3-bucket/Folders/my-source-file</code>.</p> </li> </ul>
  ##   ApplicationName: string (required)
  ##                  :  The name of the application. If no application is found with this name, and <code>AutoCreateApplication</code> is <code>false</code>, returns an <code>InvalidParameterValue</code> error. 
  ##   Action: string (required)
  ##   BuildConfigurationImage: string
  ##                          : Settings for an AWS CodeBuild build.
  ## The ID of the Docker image to use for this build project.
  ##   BuildConfigurationTimeoutInMinutes: string
  ##                                     : Settings for an AWS CodeBuild build.
  ## How long in minutes, from 5 to 480 (8 hours), for AWS CodeBuild to wait until timing out any related build that does not get marked as completed. The default is 60 minutes.
  ##   Tags: JArray
  ##       : <p>Specifies the tags applied to the application version.</p> <p>Elastic Beanstalk applies these tags only to the application version. Environments that use the application version don't inherit the tags.</p>
  ##   SourceBundleS3Bucket: string
  ##                       : The bucket and key of an item stored in Amazon S3.
  ## The Amazon S3 bucket where the data is located.
  ##   Version: string (required)
  ##   BuildConfigurationCodeBuildServiceRole: string
  ##                                         : Settings for an AWS CodeBuild build.
  ## The Amazon Resource Name (ARN) of the AWS Identity and Access Management (IAM) role that enables AWS CodeBuild to interact with dependent AWS services on behalf of the AWS account.
  var query_611496 = newJObject()
  var formData_611497 = newJObject()
  add(formData_611497, "BuildConfiguration.ComputeType",
      newJString(BuildConfigurationComputeType))
  add(formData_611497, "SourceBundle.S3Key", newJString(SourceBundleS3Key))
  add(formData_611497, "Process", newJBool(Process))
  add(formData_611497, "SourceBuildInformation.SourceType",
      newJString(SourceBuildInformationSourceType))
  add(formData_611497, "BuildConfiguration.ArtifactName",
      newJString(BuildConfigurationArtifactName))
  add(formData_611497, "Description", newJString(Description))
  add(formData_611497, "VersionLabel", newJString(VersionLabel))
  add(formData_611497, "SourceBuildInformation.SourceRepository",
      newJString(SourceBuildInformationSourceRepository))
  add(formData_611497, "AutoCreateApplication", newJBool(AutoCreateApplication))
  add(formData_611497, "SourceBuildInformation.SourceLocation",
      newJString(SourceBuildInformationSourceLocation))
  add(formData_611497, "ApplicationName", newJString(ApplicationName))
  add(query_611496, "Action", newJString(Action))
  add(formData_611497, "BuildConfiguration.Image",
      newJString(BuildConfigurationImage))
  add(formData_611497, "BuildConfiguration.TimeoutInMinutes",
      newJString(BuildConfigurationTimeoutInMinutes))
  if Tags != nil:
    formData_611497.add "Tags", Tags
  add(formData_611497, "SourceBundle.S3Bucket", newJString(SourceBundleS3Bucket))
  add(query_611496, "Version", newJString(Version))
  add(formData_611497, "BuildConfiguration.CodeBuildServiceRole",
      newJString(BuildConfigurationCodeBuildServiceRole))
  result = call_611495.call(nil, query_611496, nil, formData_611497, nil)

var postCreateApplicationVersion* = Call_PostCreateApplicationVersion_611466(
    name: "postCreateApplicationVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateApplicationVersion",
    validator: validate_PostCreateApplicationVersion_611467, base: "/",
    url: url_PostCreateApplicationVersion_611468,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateApplicationVersion_611435 = ref object of OpenApiRestCall_610659
proc url_GetCreateApplicationVersion_611437(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateApplicationVersion_611436(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an application version for the specified application. You can create an application version from a source bundle in Amazon S3, a commit in AWS CodeCommit, or the output of an AWS CodeBuild build as follows:</p> <p>Specify a commit in an AWS CodeCommit repository with <code>SourceBuildInformation</code>.</p> <p>Specify a build in an AWS CodeBuild with <code>SourceBuildInformation</code> and <code>BuildConfiguration</code>.</p> <p>Specify a source bundle in S3 with <code>SourceBundle</code> </p> <p>Omit both <code>SourceBuildInformation</code> and <code>SourceBundle</code> to use the default sample application.</p> <note> <p>Once you create an application version with a specified Amazon S3 bucket and key location, you cannot change that Amazon S3 location. If you change the Amazon S3 location, you receive an exception when you attempt to launch an environment from the application version.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ApplicationName: JString (required)
  ##                  :  The name of the application. If no application is found with this name, and <code>AutoCreateApplication</code> is <code>false</code>, returns an <code>InvalidParameterValue</code> error. 
  ##   BuildConfiguration.TimeoutInMinutes: JString
  ##                                      : Settings for an AWS CodeBuild build.
  ## How long in minutes, from 5 to 480 (8 hours), for AWS CodeBuild to wait until timing out any related build that does not get marked as completed. The default is 60 minutes.
  ##   Process: JBool
  ##          : <p>Pre-processes and validates the environment manifest (<code>env.yaml</code>) and configuration files (<code>*.config</code> files in the <code>.ebextensions</code> folder) in the source bundle. Validating configuration files can identify issues prior to deploying the application version to an environment.</p> <p>You must turn processing on for application versions that you create using AWS CodeBuild or AWS CodeCommit. For application versions built from a source bundle in Amazon S3, processing is optional.</p> <note> <p>The <code>Process</code> option validates Elastic Beanstalk configuration files. It doesn't validate your application's configuration files, like proxy server or Docker configuration.</p> </note>
  ##   SourceBuildInformation.SourceLocation: JString
  ##                                        : Location of the source code for an application version.
  ## <p>The location of the source code, as a formatted string, depending on the value of <code>SourceRepository</code> </p> <ul> <li> <p>For <code>CodeCommit</code>, the format is the repository name and commit ID, separated by a forward slash. For example, <code>my-git-repo/265cfa0cf6af46153527f55d6503ec030551f57a</code>.</p> </li> <li> <p>For <code>S3</code>, the format is the S3 bucket name and object key, separated by a forward slash. For example, <code>my-s3-bucket/Folders/my-source-file</code>.</p> </li> </ul>
  ##   VersionLabel: JString (required)
  ##               : <p>A label identifying this version.</p> <p>Constraint: Must be unique per application. If an application version already exists with this label for the specified application, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. </p>
  ##   Tags: JArray
  ##       : <p>Specifies the tags applied to the application version.</p> <p>Elastic Beanstalk applies these tags only to the application version. Environments that use the application version don't inherit the tags.</p>
  ##   AutoCreateApplication: JBool
  ##                        : Set to <code>true</code> to create an application with the specified name if it doesn't already exist.
  ##   BuildConfiguration.Image: JString
  ##                           : Settings for an AWS CodeBuild build.
  ## The ID of the Docker image to use for this build project.
  ##   Action: JString (required)
  ##   Description: JString
  ##              : Describes this version.
  ##   SourceBundle.S3Bucket: JString
  ##                        : The bucket and key of an item stored in Amazon S3.
  ## The Amazon S3 bucket where the data is located.
  ##   SourceBuildInformation.SourceRepository: JString
  ##                                          : Location of the source code for an application version.
  ## <p>Location where the repository is stored.</p> <ul> <li> <p> <code>CodeCommit</code> </p> </li> <li> <p> <code>S3</code> </p> </li> </ul>
  ##   BuildConfiguration.ComputeType: JString
  ##                                 : Settings for an AWS CodeBuild build.
  ## <p>Information about the compute resources the build project will use.</p> <ul> <li> <p> <code>BUILD_GENERAL1_SMALL: Use up to 3 GB memory and 2 vCPUs for builds</code> </p> </li> <li> <p> <code>BUILD_GENERAL1_MEDIUM: Use up to 7 GB memory and 4 vCPUs for builds</code> </p> </li> <li> <p> <code>BUILD_GENERAL1_LARGE: Use up to 15 GB memory and 8 vCPUs for builds</code> </p> </li> </ul>
  ##   SourceBuildInformation.SourceType: JString
  ##                                    : Location of the source code for an application version.
  ## <p>The type of repository.</p> <ul> <li> <p> <code>Git</code> </p> </li> <li> <p> <code>Zip</code> </p> </li> </ul>
  ##   BuildConfiguration.ArtifactName: JString
  ##                                  : Settings for an AWS CodeBuild build.
  ## The name of the artifact of the CodeBuild build. If provided, Elastic Beanstalk stores the build artifact in the S3 location 
  ## <i>S3-bucket</i>/resources/<i>application-name</i>/codebuild/codebuild-<i>version-label</i>-<i>artifact-name</i>.zip. If not provided, Elastic Beanstalk stores the build artifact in the S3 location 
  ## <i>S3-bucket</i>/resources/<i>application-name</i>/codebuild/codebuild-<i>version-label</i>.zip. 
  ##   Version: JString (required)
  ##   SourceBundle.S3Key: JString
  ##                     : The bucket and key of an item stored in Amazon S3.
  ## The Amazon S3 key where the data is located.
  ##   BuildConfiguration.CodeBuildServiceRole: JString
  ##                                          : Settings for an AWS CodeBuild build.
  ## The Amazon Resource Name (ARN) of the AWS Identity and Access Management (IAM) role that enables AWS CodeBuild to interact with dependent AWS services on behalf of the AWS account.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_611438 = query.getOrDefault("ApplicationName")
  valid_611438 = validateParameter(valid_611438, JString, required = true,
                                 default = nil)
  if valid_611438 != nil:
    section.add "ApplicationName", valid_611438
  var valid_611439 = query.getOrDefault("BuildConfiguration.TimeoutInMinutes")
  valid_611439 = validateParameter(valid_611439, JString, required = false,
                                 default = nil)
  if valid_611439 != nil:
    section.add "BuildConfiguration.TimeoutInMinutes", valid_611439
  var valid_611440 = query.getOrDefault("Process")
  valid_611440 = validateParameter(valid_611440, JBool, required = false, default = nil)
  if valid_611440 != nil:
    section.add "Process", valid_611440
  var valid_611441 = query.getOrDefault("SourceBuildInformation.SourceLocation")
  valid_611441 = validateParameter(valid_611441, JString, required = false,
                                 default = nil)
  if valid_611441 != nil:
    section.add "SourceBuildInformation.SourceLocation", valid_611441
  var valid_611442 = query.getOrDefault("VersionLabel")
  valid_611442 = validateParameter(valid_611442, JString, required = true,
                                 default = nil)
  if valid_611442 != nil:
    section.add "VersionLabel", valid_611442
  var valid_611443 = query.getOrDefault("Tags")
  valid_611443 = validateParameter(valid_611443, JArray, required = false,
                                 default = nil)
  if valid_611443 != nil:
    section.add "Tags", valid_611443
  var valid_611444 = query.getOrDefault("AutoCreateApplication")
  valid_611444 = validateParameter(valid_611444, JBool, required = false, default = nil)
  if valid_611444 != nil:
    section.add "AutoCreateApplication", valid_611444
  var valid_611445 = query.getOrDefault("BuildConfiguration.Image")
  valid_611445 = validateParameter(valid_611445, JString, required = false,
                                 default = nil)
  if valid_611445 != nil:
    section.add "BuildConfiguration.Image", valid_611445
  var valid_611446 = query.getOrDefault("Action")
  valid_611446 = validateParameter(valid_611446, JString, required = true, default = newJString(
      "CreateApplicationVersion"))
  if valid_611446 != nil:
    section.add "Action", valid_611446
  var valid_611447 = query.getOrDefault("Description")
  valid_611447 = validateParameter(valid_611447, JString, required = false,
                                 default = nil)
  if valid_611447 != nil:
    section.add "Description", valid_611447
  var valid_611448 = query.getOrDefault("SourceBundle.S3Bucket")
  valid_611448 = validateParameter(valid_611448, JString, required = false,
                                 default = nil)
  if valid_611448 != nil:
    section.add "SourceBundle.S3Bucket", valid_611448
  var valid_611449 = query.getOrDefault("SourceBuildInformation.SourceRepository")
  valid_611449 = validateParameter(valid_611449, JString, required = false,
                                 default = nil)
  if valid_611449 != nil:
    section.add "SourceBuildInformation.SourceRepository", valid_611449
  var valid_611450 = query.getOrDefault("BuildConfiguration.ComputeType")
  valid_611450 = validateParameter(valid_611450, JString, required = false,
                                 default = nil)
  if valid_611450 != nil:
    section.add "BuildConfiguration.ComputeType", valid_611450
  var valid_611451 = query.getOrDefault("SourceBuildInformation.SourceType")
  valid_611451 = validateParameter(valid_611451, JString, required = false,
                                 default = nil)
  if valid_611451 != nil:
    section.add "SourceBuildInformation.SourceType", valid_611451
  var valid_611452 = query.getOrDefault("BuildConfiguration.ArtifactName")
  valid_611452 = validateParameter(valid_611452, JString, required = false,
                                 default = nil)
  if valid_611452 != nil:
    section.add "BuildConfiguration.ArtifactName", valid_611452
  var valid_611453 = query.getOrDefault("Version")
  valid_611453 = validateParameter(valid_611453, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_611453 != nil:
    section.add "Version", valid_611453
  var valid_611454 = query.getOrDefault("SourceBundle.S3Key")
  valid_611454 = validateParameter(valid_611454, JString, required = false,
                                 default = nil)
  if valid_611454 != nil:
    section.add "SourceBundle.S3Key", valid_611454
  var valid_611455 = query.getOrDefault("BuildConfiguration.CodeBuildServiceRole")
  valid_611455 = validateParameter(valid_611455, JString, required = false,
                                 default = nil)
  if valid_611455 != nil:
    section.add "BuildConfiguration.CodeBuildServiceRole", valid_611455
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611456 = header.getOrDefault("X-Amz-Signature")
  valid_611456 = validateParameter(valid_611456, JString, required = false,
                                 default = nil)
  if valid_611456 != nil:
    section.add "X-Amz-Signature", valid_611456
  var valid_611457 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611457 = validateParameter(valid_611457, JString, required = false,
                                 default = nil)
  if valid_611457 != nil:
    section.add "X-Amz-Content-Sha256", valid_611457
  var valid_611458 = header.getOrDefault("X-Amz-Date")
  valid_611458 = validateParameter(valid_611458, JString, required = false,
                                 default = nil)
  if valid_611458 != nil:
    section.add "X-Amz-Date", valid_611458
  var valid_611459 = header.getOrDefault("X-Amz-Credential")
  valid_611459 = validateParameter(valid_611459, JString, required = false,
                                 default = nil)
  if valid_611459 != nil:
    section.add "X-Amz-Credential", valid_611459
  var valid_611460 = header.getOrDefault("X-Amz-Security-Token")
  valid_611460 = validateParameter(valid_611460, JString, required = false,
                                 default = nil)
  if valid_611460 != nil:
    section.add "X-Amz-Security-Token", valid_611460
  var valid_611461 = header.getOrDefault("X-Amz-Algorithm")
  valid_611461 = validateParameter(valid_611461, JString, required = false,
                                 default = nil)
  if valid_611461 != nil:
    section.add "X-Amz-Algorithm", valid_611461
  var valid_611462 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611462 = validateParameter(valid_611462, JString, required = false,
                                 default = nil)
  if valid_611462 != nil:
    section.add "X-Amz-SignedHeaders", valid_611462
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611463: Call_GetCreateApplicationVersion_611435; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an application version for the specified application. You can create an application version from a source bundle in Amazon S3, a commit in AWS CodeCommit, or the output of an AWS CodeBuild build as follows:</p> <p>Specify a commit in an AWS CodeCommit repository with <code>SourceBuildInformation</code>.</p> <p>Specify a build in an AWS CodeBuild with <code>SourceBuildInformation</code> and <code>BuildConfiguration</code>.</p> <p>Specify a source bundle in S3 with <code>SourceBundle</code> </p> <p>Omit both <code>SourceBuildInformation</code> and <code>SourceBundle</code> to use the default sample application.</p> <note> <p>Once you create an application version with a specified Amazon S3 bucket and key location, you cannot change that Amazon S3 location. If you change the Amazon S3 location, you receive an exception when you attempt to launch an environment from the application version.</p> </note>
  ## 
  let valid = call_611463.validator(path, query, header, formData, body)
  let scheme = call_611463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611463.url(scheme.get, call_611463.host, call_611463.base,
                         call_611463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611463, url, valid)

proc call*(call_611464: Call_GetCreateApplicationVersion_611435;
          ApplicationName: string; VersionLabel: string;
          BuildConfigurationTimeoutInMinutes: string = ""; Process: bool = false;
          SourceBuildInformationSourceLocation: string = ""; Tags: JsonNode = nil;
          AutoCreateApplication: bool = false; BuildConfigurationImage: string = "";
          Action: string = "CreateApplicationVersion"; Description: string = "";
          SourceBundleS3Bucket: string = "";
          SourceBuildInformationSourceRepository: string = "";
          BuildConfigurationComputeType: string = "";
          SourceBuildInformationSourceType: string = "";
          BuildConfigurationArtifactName: string = "";
          Version: string = "2010-12-01"; SourceBundleS3Key: string = "";
          BuildConfigurationCodeBuildServiceRole: string = ""): Recallable =
  ## getCreateApplicationVersion
  ## <p>Creates an application version for the specified application. You can create an application version from a source bundle in Amazon S3, a commit in AWS CodeCommit, or the output of an AWS CodeBuild build as follows:</p> <p>Specify a commit in an AWS CodeCommit repository with <code>SourceBuildInformation</code>.</p> <p>Specify a build in an AWS CodeBuild with <code>SourceBuildInformation</code> and <code>BuildConfiguration</code>.</p> <p>Specify a source bundle in S3 with <code>SourceBundle</code> </p> <p>Omit both <code>SourceBuildInformation</code> and <code>SourceBundle</code> to use the default sample application.</p> <note> <p>Once you create an application version with a specified Amazon S3 bucket and key location, you cannot change that Amazon S3 location. If you change the Amazon S3 location, you receive an exception when you attempt to launch an environment from the application version.</p> </note>
  ##   ApplicationName: string (required)
  ##                  :  The name of the application. If no application is found with this name, and <code>AutoCreateApplication</code> is <code>false</code>, returns an <code>InvalidParameterValue</code> error. 
  ##   BuildConfigurationTimeoutInMinutes: string
  ##                                     : Settings for an AWS CodeBuild build.
  ## How long in minutes, from 5 to 480 (8 hours), for AWS CodeBuild to wait until timing out any related build that does not get marked as completed. The default is 60 minutes.
  ##   Process: bool
  ##          : <p>Pre-processes and validates the environment manifest (<code>env.yaml</code>) and configuration files (<code>*.config</code> files in the <code>.ebextensions</code> folder) in the source bundle. Validating configuration files can identify issues prior to deploying the application version to an environment.</p> <p>You must turn processing on for application versions that you create using AWS CodeBuild or AWS CodeCommit. For application versions built from a source bundle in Amazon S3, processing is optional.</p> <note> <p>The <code>Process</code> option validates Elastic Beanstalk configuration files. It doesn't validate your application's configuration files, like proxy server or Docker configuration.</p> </note>
  ##   SourceBuildInformationSourceLocation: string
  ##                                       : Location of the source code for an application version.
  ## <p>The location of the source code, as a formatted string, depending on the value of <code>SourceRepository</code> </p> <ul> <li> <p>For <code>CodeCommit</code>, the format is the repository name and commit ID, separated by a forward slash. For example, <code>my-git-repo/265cfa0cf6af46153527f55d6503ec030551f57a</code>.</p> </li> <li> <p>For <code>S3</code>, the format is the S3 bucket name and object key, separated by a forward slash. For example, <code>my-s3-bucket/Folders/my-source-file</code>.</p> </li> </ul>
  ##   VersionLabel: string (required)
  ##               : <p>A label identifying this version.</p> <p>Constraint: Must be unique per application. If an application version already exists with this label for the specified application, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. </p>
  ##   Tags: JArray
  ##       : <p>Specifies the tags applied to the application version.</p> <p>Elastic Beanstalk applies these tags only to the application version. Environments that use the application version don't inherit the tags.</p>
  ##   AutoCreateApplication: bool
  ##                        : Set to <code>true</code> to create an application with the specified name if it doesn't already exist.
  ##   BuildConfigurationImage: string
  ##                          : Settings for an AWS CodeBuild build.
  ## The ID of the Docker image to use for this build project.
  ##   Action: string (required)
  ##   Description: string
  ##              : Describes this version.
  ##   SourceBundleS3Bucket: string
  ##                       : The bucket and key of an item stored in Amazon S3.
  ## The Amazon S3 bucket where the data is located.
  ##   SourceBuildInformationSourceRepository: string
  ##                                         : Location of the source code for an application version.
  ## <p>Location where the repository is stored.</p> <ul> <li> <p> <code>CodeCommit</code> </p> </li> <li> <p> <code>S3</code> </p> </li> </ul>
  ##   BuildConfigurationComputeType: string
  ##                                : Settings for an AWS CodeBuild build.
  ## <p>Information about the compute resources the build project will use.</p> <ul> <li> <p> <code>BUILD_GENERAL1_SMALL: Use up to 3 GB memory and 2 vCPUs for builds</code> </p> </li> <li> <p> <code>BUILD_GENERAL1_MEDIUM: Use up to 7 GB memory and 4 vCPUs for builds</code> </p> </li> <li> <p> <code>BUILD_GENERAL1_LARGE: Use up to 15 GB memory and 8 vCPUs for builds</code> </p> </li> </ul>
  ##   SourceBuildInformationSourceType: string
  ##                                   : Location of the source code for an application version.
  ## <p>The type of repository.</p> <ul> <li> <p> <code>Git</code> </p> </li> <li> <p> <code>Zip</code> </p> </li> </ul>
  ##   BuildConfigurationArtifactName: string
  ##                                 : Settings for an AWS CodeBuild build.
  ## The name of the artifact of the CodeBuild build. If provided, Elastic Beanstalk stores the build artifact in the S3 location 
  ## <i>S3-bucket</i>/resources/<i>application-name</i>/codebuild/codebuild-<i>version-label</i>-<i>artifact-name</i>.zip. If not provided, Elastic Beanstalk stores the build artifact in the S3 location 
  ## <i>S3-bucket</i>/resources/<i>application-name</i>/codebuild/codebuild-<i>version-label</i>.zip. 
  ##   Version: string (required)
  ##   SourceBundleS3Key: string
  ##                    : The bucket and key of an item stored in Amazon S3.
  ## The Amazon S3 key where the data is located.
  ##   BuildConfigurationCodeBuildServiceRole: string
  ##                                         : Settings for an AWS CodeBuild build.
  ## The Amazon Resource Name (ARN) of the AWS Identity and Access Management (IAM) role that enables AWS CodeBuild to interact with dependent AWS services on behalf of the AWS account.
  var query_611465 = newJObject()
  add(query_611465, "ApplicationName", newJString(ApplicationName))
  add(query_611465, "BuildConfiguration.TimeoutInMinutes",
      newJString(BuildConfigurationTimeoutInMinutes))
  add(query_611465, "Process", newJBool(Process))
  add(query_611465, "SourceBuildInformation.SourceLocation",
      newJString(SourceBuildInformationSourceLocation))
  add(query_611465, "VersionLabel", newJString(VersionLabel))
  if Tags != nil:
    query_611465.add "Tags", Tags
  add(query_611465, "AutoCreateApplication", newJBool(AutoCreateApplication))
  add(query_611465, "BuildConfiguration.Image",
      newJString(BuildConfigurationImage))
  add(query_611465, "Action", newJString(Action))
  add(query_611465, "Description", newJString(Description))
  add(query_611465, "SourceBundle.S3Bucket", newJString(SourceBundleS3Bucket))
  add(query_611465, "SourceBuildInformation.SourceRepository",
      newJString(SourceBuildInformationSourceRepository))
  add(query_611465, "BuildConfiguration.ComputeType",
      newJString(BuildConfigurationComputeType))
  add(query_611465, "SourceBuildInformation.SourceType",
      newJString(SourceBuildInformationSourceType))
  add(query_611465, "BuildConfiguration.ArtifactName",
      newJString(BuildConfigurationArtifactName))
  add(query_611465, "Version", newJString(Version))
  add(query_611465, "SourceBundle.S3Key", newJString(SourceBundleS3Key))
  add(query_611465, "BuildConfiguration.CodeBuildServiceRole",
      newJString(BuildConfigurationCodeBuildServiceRole))
  result = call_611464.call(nil, query_611465, nil, nil, nil)

var getCreateApplicationVersion* = Call_GetCreateApplicationVersion_611435(
    name: "getCreateApplicationVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateApplicationVersion",
    validator: validate_GetCreateApplicationVersion_611436, base: "/",
    url: url_GetCreateApplicationVersion_611437,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateConfigurationTemplate_611523 = ref object of OpenApiRestCall_610659
proc url_PostCreateConfigurationTemplate_611525(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateConfigurationTemplate_611524(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a configuration template. Templates are associated with a specific application and are used to deploy different versions of the application with the same configuration settings.</p> <p>Templates aren't associated with any environment. The <code>EnvironmentName</code> response element is always <code>null</code>.</p> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> <li> <p> <a>DescribeConfigurationSettings</a> </p> </li> <li> <p> <a>ListAvailableSolutionStacks</a> </p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611526 = query.getOrDefault("Action")
  valid_611526 = validateParameter(valid_611526, JString, required = true, default = newJString(
      "CreateConfigurationTemplate"))
  if valid_611526 != nil:
    section.add "Action", valid_611526
  var valid_611527 = query.getOrDefault("Version")
  valid_611527 = validateParameter(valid_611527, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_611527 != nil:
    section.add "Version", valid_611527
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611528 = header.getOrDefault("X-Amz-Signature")
  valid_611528 = validateParameter(valid_611528, JString, required = false,
                                 default = nil)
  if valid_611528 != nil:
    section.add "X-Amz-Signature", valid_611528
  var valid_611529 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611529 = validateParameter(valid_611529, JString, required = false,
                                 default = nil)
  if valid_611529 != nil:
    section.add "X-Amz-Content-Sha256", valid_611529
  var valid_611530 = header.getOrDefault("X-Amz-Date")
  valid_611530 = validateParameter(valid_611530, JString, required = false,
                                 default = nil)
  if valid_611530 != nil:
    section.add "X-Amz-Date", valid_611530
  var valid_611531 = header.getOrDefault("X-Amz-Credential")
  valid_611531 = validateParameter(valid_611531, JString, required = false,
                                 default = nil)
  if valid_611531 != nil:
    section.add "X-Amz-Credential", valid_611531
  var valid_611532 = header.getOrDefault("X-Amz-Security-Token")
  valid_611532 = validateParameter(valid_611532, JString, required = false,
                                 default = nil)
  if valid_611532 != nil:
    section.add "X-Amz-Security-Token", valid_611532
  var valid_611533 = header.getOrDefault("X-Amz-Algorithm")
  valid_611533 = validateParameter(valid_611533, JString, required = false,
                                 default = nil)
  if valid_611533 != nil:
    section.add "X-Amz-Algorithm", valid_611533
  var valid_611534 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611534 = validateParameter(valid_611534, JString, required = false,
                                 default = nil)
  if valid_611534 != nil:
    section.add "X-Amz-SignedHeaders", valid_611534
  result.add "header", section
  ## parameters in `formData` object:
  ##   Description: JString
  ##              : Describes this configuration.
  ##   TemplateName: JString (required)
  ##               : <p>The name of the configuration template.</p> <p>Constraint: This name must be unique per application.</p> <p>Default: If a configuration template already exists with this name, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. </p>
  ##   SourceConfiguration.ApplicationName: JString
  ##                                      : A specification for an environment configuration
  ## The name of the application associated with the configuration.
  ##   SourceConfiguration.TemplateName: JString
  ##                                   : A specification for an environment configuration
  ## The name of the configuration template.
  ##   OptionSettings: JArray
  ##                 : If specified, AWS Elastic Beanstalk sets the specified configuration option to the requested value. The new value overrides the value obtained from the solution stack or the source configuration template.
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to associate with this configuration template. If no application is found with this name, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. 
  ##   Tags: JArray
  ##       : Specifies the tags applied to the configuration template.
  ##   SolutionStackName: JString
  ##                    : <p>The name of the solution stack used by this configuration. The solution stack specifies the operating system, architecture, and application server for a configuration template. It determines the set of configuration options as well as the possible and default values.</p> <p> Use <a>ListAvailableSolutionStacks</a> to obtain a list of available solution stacks. </p> <p> A solution stack name or a source configuration parameter must be specified, otherwise AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. </p> <p>If a solution stack name is not specified and the source configuration parameter is specified, AWS Elastic Beanstalk uses the same solution stack as the source configuration template.</p>
  ##   EnvironmentId: JString
  ##                : The ID of the environment used with this configuration template.
  ##   PlatformArn: JString
  ##              : The ARN of the custom platform.
  section = newJObject()
  var valid_611535 = formData.getOrDefault("Description")
  valid_611535 = validateParameter(valid_611535, JString, required = false,
                                 default = nil)
  if valid_611535 != nil:
    section.add "Description", valid_611535
  assert formData != nil,
        "formData argument is necessary due to required `TemplateName` field"
  var valid_611536 = formData.getOrDefault("TemplateName")
  valid_611536 = validateParameter(valid_611536, JString, required = true,
                                 default = nil)
  if valid_611536 != nil:
    section.add "TemplateName", valid_611536
  var valid_611537 = formData.getOrDefault("SourceConfiguration.ApplicationName")
  valid_611537 = validateParameter(valid_611537, JString, required = false,
                                 default = nil)
  if valid_611537 != nil:
    section.add "SourceConfiguration.ApplicationName", valid_611537
  var valid_611538 = formData.getOrDefault("SourceConfiguration.TemplateName")
  valid_611538 = validateParameter(valid_611538, JString, required = false,
                                 default = nil)
  if valid_611538 != nil:
    section.add "SourceConfiguration.TemplateName", valid_611538
  var valid_611539 = formData.getOrDefault("OptionSettings")
  valid_611539 = validateParameter(valid_611539, JArray, required = false,
                                 default = nil)
  if valid_611539 != nil:
    section.add "OptionSettings", valid_611539
  var valid_611540 = formData.getOrDefault("ApplicationName")
  valid_611540 = validateParameter(valid_611540, JString, required = true,
                                 default = nil)
  if valid_611540 != nil:
    section.add "ApplicationName", valid_611540
  var valid_611541 = formData.getOrDefault("Tags")
  valid_611541 = validateParameter(valid_611541, JArray, required = false,
                                 default = nil)
  if valid_611541 != nil:
    section.add "Tags", valid_611541
  var valid_611542 = formData.getOrDefault("SolutionStackName")
  valid_611542 = validateParameter(valid_611542, JString, required = false,
                                 default = nil)
  if valid_611542 != nil:
    section.add "SolutionStackName", valid_611542
  var valid_611543 = formData.getOrDefault("EnvironmentId")
  valid_611543 = validateParameter(valid_611543, JString, required = false,
                                 default = nil)
  if valid_611543 != nil:
    section.add "EnvironmentId", valid_611543
  var valid_611544 = formData.getOrDefault("PlatformArn")
  valid_611544 = validateParameter(valid_611544, JString, required = false,
                                 default = nil)
  if valid_611544 != nil:
    section.add "PlatformArn", valid_611544
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611545: Call_PostCreateConfigurationTemplate_611523;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a configuration template. Templates are associated with a specific application and are used to deploy different versions of the application with the same configuration settings.</p> <p>Templates aren't associated with any environment. The <code>EnvironmentName</code> response element is always <code>null</code>.</p> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> <li> <p> <a>DescribeConfigurationSettings</a> </p> </li> <li> <p> <a>ListAvailableSolutionStacks</a> </p> </li> </ul>
  ## 
  let valid = call_611545.validator(path, query, header, formData, body)
  let scheme = call_611545.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611545.url(scheme.get, call_611545.host, call_611545.base,
                         call_611545.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611545, url, valid)

proc call*(call_611546: Call_PostCreateConfigurationTemplate_611523;
          TemplateName: string; ApplicationName: string; Description: string = "";
          SourceConfigurationApplicationName: string = "";
          SourceConfigurationTemplateName: string = "";
          OptionSettings: JsonNode = nil;
          Action: string = "CreateConfigurationTemplate"; Tags: JsonNode = nil;
          SolutionStackName: string = ""; EnvironmentId: string = "";
          Version: string = "2010-12-01"; PlatformArn: string = ""): Recallable =
  ## postCreateConfigurationTemplate
  ## <p>Creates a configuration template. Templates are associated with a specific application and are used to deploy different versions of the application with the same configuration settings.</p> <p>Templates aren't associated with any environment. The <code>EnvironmentName</code> response element is always <code>null</code>.</p> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> <li> <p> <a>DescribeConfigurationSettings</a> </p> </li> <li> <p> <a>ListAvailableSolutionStacks</a> </p> </li> </ul>
  ##   Description: string
  ##              : Describes this configuration.
  ##   TemplateName: string (required)
  ##               : <p>The name of the configuration template.</p> <p>Constraint: This name must be unique per application.</p> <p>Default: If a configuration template already exists with this name, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. </p>
  ##   SourceConfigurationApplicationName: string
  ##                                     : A specification for an environment configuration
  ## The name of the application associated with the configuration.
  ##   SourceConfigurationTemplateName: string
  ##                                  : A specification for an environment configuration
  ## The name of the configuration template.
  ##   OptionSettings: JArray
  ##                 : If specified, AWS Elastic Beanstalk sets the specified configuration option to the requested value. The new value overrides the value obtained from the solution stack or the source configuration template.
  ##   ApplicationName: string (required)
  ##                  : The name of the application to associate with this configuration template. If no application is found with this name, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. 
  ##   Action: string (required)
  ##   Tags: JArray
  ##       : Specifies the tags applied to the configuration template.
  ##   SolutionStackName: string
  ##                    : <p>The name of the solution stack used by this configuration. The solution stack specifies the operating system, architecture, and application server for a configuration template. It determines the set of configuration options as well as the possible and default values.</p> <p> Use <a>ListAvailableSolutionStacks</a> to obtain a list of available solution stacks. </p> <p> A solution stack name or a source configuration parameter must be specified, otherwise AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. </p> <p>If a solution stack name is not specified and the source configuration parameter is specified, AWS Elastic Beanstalk uses the same solution stack as the source configuration template.</p>
  ##   EnvironmentId: string
  ##                : The ID of the environment used with this configuration template.
  ##   Version: string (required)
  ##   PlatformArn: string
  ##              : The ARN of the custom platform.
  var query_611547 = newJObject()
  var formData_611548 = newJObject()
  add(formData_611548, "Description", newJString(Description))
  add(formData_611548, "TemplateName", newJString(TemplateName))
  add(formData_611548, "SourceConfiguration.ApplicationName",
      newJString(SourceConfigurationApplicationName))
  add(formData_611548, "SourceConfiguration.TemplateName",
      newJString(SourceConfigurationTemplateName))
  if OptionSettings != nil:
    formData_611548.add "OptionSettings", OptionSettings
  add(formData_611548, "ApplicationName", newJString(ApplicationName))
  add(query_611547, "Action", newJString(Action))
  if Tags != nil:
    formData_611548.add "Tags", Tags
  add(formData_611548, "SolutionStackName", newJString(SolutionStackName))
  add(formData_611548, "EnvironmentId", newJString(EnvironmentId))
  add(query_611547, "Version", newJString(Version))
  add(formData_611548, "PlatformArn", newJString(PlatformArn))
  result = call_611546.call(nil, query_611547, nil, formData_611548, nil)

var postCreateConfigurationTemplate* = Call_PostCreateConfigurationTemplate_611523(
    name: "postCreateConfigurationTemplate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateConfigurationTemplate",
    validator: validate_PostCreateConfigurationTemplate_611524, base: "/",
    url: url_PostCreateConfigurationTemplate_611525,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateConfigurationTemplate_611498 = ref object of OpenApiRestCall_610659
proc url_GetCreateConfigurationTemplate_611500(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateConfigurationTemplate_611499(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a configuration template. Templates are associated with a specific application and are used to deploy different versions of the application with the same configuration settings.</p> <p>Templates aren't associated with any environment. The <code>EnvironmentName</code> response element is always <code>null</code>.</p> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> <li> <p> <a>DescribeConfigurationSettings</a> </p> </li> <li> <p> <a>ListAvailableSolutionStacks</a> </p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to associate with this configuration template. If no application is found with this name, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. 
  ##   Tags: JArray
  ##       : Specifies the tags applied to the configuration template.
  ##   OptionSettings: JArray
  ##                 : If specified, AWS Elastic Beanstalk sets the specified configuration option to the requested value. The new value overrides the value obtained from the solution stack or the source configuration template.
  ##   SourceConfiguration.TemplateName: JString
  ##                                   : A specification for an environment configuration
  ## The name of the configuration template.
  ##   SolutionStackName: JString
  ##                    : <p>The name of the solution stack used by this configuration. The solution stack specifies the operating system, architecture, and application server for a configuration template. It determines the set of configuration options as well as the possible and default values.</p> <p> Use <a>ListAvailableSolutionStacks</a> to obtain a list of available solution stacks. </p> <p> A solution stack name or a source configuration parameter must be specified, otherwise AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. </p> <p>If a solution stack name is not specified and the source configuration parameter is specified, AWS Elastic Beanstalk uses the same solution stack as the source configuration template.</p>
  ##   Action: JString (required)
  ##   Description: JString
  ##              : Describes this configuration.
  ##   PlatformArn: JString
  ##              : The ARN of the custom platform.
  ##   Version: JString (required)
  ##   TemplateName: JString (required)
  ##               : <p>The name of the configuration template.</p> <p>Constraint: This name must be unique per application.</p> <p>Default: If a configuration template already exists with this name, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. </p>
  ##   SourceConfiguration.ApplicationName: JString
  ##                                      : A specification for an environment configuration
  ## The name of the application associated with the configuration.
  ##   EnvironmentId: JString
  ##                : The ID of the environment used with this configuration template.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_611501 = query.getOrDefault("ApplicationName")
  valid_611501 = validateParameter(valid_611501, JString, required = true,
                                 default = nil)
  if valid_611501 != nil:
    section.add "ApplicationName", valid_611501
  var valid_611502 = query.getOrDefault("Tags")
  valid_611502 = validateParameter(valid_611502, JArray, required = false,
                                 default = nil)
  if valid_611502 != nil:
    section.add "Tags", valid_611502
  var valid_611503 = query.getOrDefault("OptionSettings")
  valid_611503 = validateParameter(valid_611503, JArray, required = false,
                                 default = nil)
  if valid_611503 != nil:
    section.add "OptionSettings", valid_611503
  var valid_611504 = query.getOrDefault("SourceConfiguration.TemplateName")
  valid_611504 = validateParameter(valid_611504, JString, required = false,
                                 default = nil)
  if valid_611504 != nil:
    section.add "SourceConfiguration.TemplateName", valid_611504
  var valid_611505 = query.getOrDefault("SolutionStackName")
  valid_611505 = validateParameter(valid_611505, JString, required = false,
                                 default = nil)
  if valid_611505 != nil:
    section.add "SolutionStackName", valid_611505
  var valid_611506 = query.getOrDefault("Action")
  valid_611506 = validateParameter(valid_611506, JString, required = true, default = newJString(
      "CreateConfigurationTemplate"))
  if valid_611506 != nil:
    section.add "Action", valid_611506
  var valid_611507 = query.getOrDefault("Description")
  valid_611507 = validateParameter(valid_611507, JString, required = false,
                                 default = nil)
  if valid_611507 != nil:
    section.add "Description", valid_611507
  var valid_611508 = query.getOrDefault("PlatformArn")
  valid_611508 = validateParameter(valid_611508, JString, required = false,
                                 default = nil)
  if valid_611508 != nil:
    section.add "PlatformArn", valid_611508
  var valid_611509 = query.getOrDefault("Version")
  valid_611509 = validateParameter(valid_611509, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_611509 != nil:
    section.add "Version", valid_611509
  var valid_611510 = query.getOrDefault("TemplateName")
  valid_611510 = validateParameter(valid_611510, JString, required = true,
                                 default = nil)
  if valid_611510 != nil:
    section.add "TemplateName", valid_611510
  var valid_611511 = query.getOrDefault("SourceConfiguration.ApplicationName")
  valid_611511 = validateParameter(valid_611511, JString, required = false,
                                 default = nil)
  if valid_611511 != nil:
    section.add "SourceConfiguration.ApplicationName", valid_611511
  var valid_611512 = query.getOrDefault("EnvironmentId")
  valid_611512 = validateParameter(valid_611512, JString, required = false,
                                 default = nil)
  if valid_611512 != nil:
    section.add "EnvironmentId", valid_611512
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611513 = header.getOrDefault("X-Amz-Signature")
  valid_611513 = validateParameter(valid_611513, JString, required = false,
                                 default = nil)
  if valid_611513 != nil:
    section.add "X-Amz-Signature", valid_611513
  var valid_611514 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611514 = validateParameter(valid_611514, JString, required = false,
                                 default = nil)
  if valid_611514 != nil:
    section.add "X-Amz-Content-Sha256", valid_611514
  var valid_611515 = header.getOrDefault("X-Amz-Date")
  valid_611515 = validateParameter(valid_611515, JString, required = false,
                                 default = nil)
  if valid_611515 != nil:
    section.add "X-Amz-Date", valid_611515
  var valid_611516 = header.getOrDefault("X-Amz-Credential")
  valid_611516 = validateParameter(valid_611516, JString, required = false,
                                 default = nil)
  if valid_611516 != nil:
    section.add "X-Amz-Credential", valid_611516
  var valid_611517 = header.getOrDefault("X-Amz-Security-Token")
  valid_611517 = validateParameter(valid_611517, JString, required = false,
                                 default = nil)
  if valid_611517 != nil:
    section.add "X-Amz-Security-Token", valid_611517
  var valid_611518 = header.getOrDefault("X-Amz-Algorithm")
  valid_611518 = validateParameter(valid_611518, JString, required = false,
                                 default = nil)
  if valid_611518 != nil:
    section.add "X-Amz-Algorithm", valid_611518
  var valid_611519 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611519 = validateParameter(valid_611519, JString, required = false,
                                 default = nil)
  if valid_611519 != nil:
    section.add "X-Amz-SignedHeaders", valid_611519
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611520: Call_GetCreateConfigurationTemplate_611498; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a configuration template. Templates are associated with a specific application and are used to deploy different versions of the application with the same configuration settings.</p> <p>Templates aren't associated with any environment. The <code>EnvironmentName</code> response element is always <code>null</code>.</p> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> <li> <p> <a>DescribeConfigurationSettings</a> </p> </li> <li> <p> <a>ListAvailableSolutionStacks</a> </p> </li> </ul>
  ## 
  let valid = call_611520.validator(path, query, header, formData, body)
  let scheme = call_611520.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611520.url(scheme.get, call_611520.host, call_611520.base,
                         call_611520.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611520, url, valid)

proc call*(call_611521: Call_GetCreateConfigurationTemplate_611498;
          ApplicationName: string; TemplateName: string; Tags: JsonNode = nil;
          OptionSettings: JsonNode = nil;
          SourceConfigurationTemplateName: string = "";
          SolutionStackName: string = "";
          Action: string = "CreateConfigurationTemplate"; Description: string = "";
          PlatformArn: string = ""; Version: string = "2010-12-01";
          SourceConfigurationApplicationName: string = "";
          EnvironmentId: string = ""): Recallable =
  ## getCreateConfigurationTemplate
  ## <p>Creates a configuration template. Templates are associated with a specific application and are used to deploy different versions of the application with the same configuration settings.</p> <p>Templates aren't associated with any environment. The <code>EnvironmentName</code> response element is always <code>null</code>.</p> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> <li> <p> <a>DescribeConfigurationSettings</a> </p> </li> <li> <p> <a>ListAvailableSolutionStacks</a> </p> </li> </ul>
  ##   ApplicationName: string (required)
  ##                  : The name of the application to associate with this configuration template. If no application is found with this name, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. 
  ##   Tags: JArray
  ##       : Specifies the tags applied to the configuration template.
  ##   OptionSettings: JArray
  ##                 : If specified, AWS Elastic Beanstalk sets the specified configuration option to the requested value. The new value overrides the value obtained from the solution stack or the source configuration template.
  ##   SourceConfigurationTemplateName: string
  ##                                  : A specification for an environment configuration
  ## The name of the configuration template.
  ##   SolutionStackName: string
  ##                    : <p>The name of the solution stack used by this configuration. The solution stack specifies the operating system, architecture, and application server for a configuration template. It determines the set of configuration options as well as the possible and default values.</p> <p> Use <a>ListAvailableSolutionStacks</a> to obtain a list of available solution stacks. </p> <p> A solution stack name or a source configuration parameter must be specified, otherwise AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. </p> <p>If a solution stack name is not specified and the source configuration parameter is specified, AWS Elastic Beanstalk uses the same solution stack as the source configuration template.</p>
  ##   Action: string (required)
  ##   Description: string
  ##              : Describes this configuration.
  ##   PlatformArn: string
  ##              : The ARN of the custom platform.
  ##   Version: string (required)
  ##   TemplateName: string (required)
  ##               : <p>The name of the configuration template.</p> <p>Constraint: This name must be unique per application.</p> <p>Default: If a configuration template already exists with this name, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. </p>
  ##   SourceConfigurationApplicationName: string
  ##                                     : A specification for an environment configuration
  ## The name of the application associated with the configuration.
  ##   EnvironmentId: string
  ##                : The ID of the environment used with this configuration template.
  var query_611522 = newJObject()
  add(query_611522, "ApplicationName", newJString(ApplicationName))
  if Tags != nil:
    query_611522.add "Tags", Tags
  if OptionSettings != nil:
    query_611522.add "OptionSettings", OptionSettings
  add(query_611522, "SourceConfiguration.TemplateName",
      newJString(SourceConfigurationTemplateName))
  add(query_611522, "SolutionStackName", newJString(SolutionStackName))
  add(query_611522, "Action", newJString(Action))
  add(query_611522, "Description", newJString(Description))
  add(query_611522, "PlatformArn", newJString(PlatformArn))
  add(query_611522, "Version", newJString(Version))
  add(query_611522, "TemplateName", newJString(TemplateName))
  add(query_611522, "SourceConfiguration.ApplicationName",
      newJString(SourceConfigurationApplicationName))
  add(query_611522, "EnvironmentId", newJString(EnvironmentId))
  result = call_611521.call(nil, query_611522, nil, nil, nil)

var getCreateConfigurationTemplate* = Call_GetCreateConfigurationTemplate_611498(
    name: "getCreateConfigurationTemplate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateConfigurationTemplate",
    validator: validate_GetCreateConfigurationTemplate_611499, base: "/",
    url: url_GetCreateConfigurationTemplate_611500,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEnvironment_611579 = ref object of OpenApiRestCall_610659
proc url_PostCreateEnvironment_611581(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateEnvironment_611580(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Launches an environment for the specified application using the specified configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611582 = query.getOrDefault("Action")
  valid_611582 = validateParameter(valid_611582, JString, required = true,
                                 default = newJString("CreateEnvironment"))
  if valid_611582 != nil:
    section.add "Action", valid_611582
  var valid_611583 = query.getOrDefault("Version")
  valid_611583 = validateParameter(valid_611583, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_611583 != nil:
    section.add "Version", valid_611583
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611584 = header.getOrDefault("X-Amz-Signature")
  valid_611584 = validateParameter(valid_611584, JString, required = false,
                                 default = nil)
  if valid_611584 != nil:
    section.add "X-Amz-Signature", valid_611584
  var valid_611585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611585 = validateParameter(valid_611585, JString, required = false,
                                 default = nil)
  if valid_611585 != nil:
    section.add "X-Amz-Content-Sha256", valid_611585
  var valid_611586 = header.getOrDefault("X-Amz-Date")
  valid_611586 = validateParameter(valid_611586, JString, required = false,
                                 default = nil)
  if valid_611586 != nil:
    section.add "X-Amz-Date", valid_611586
  var valid_611587 = header.getOrDefault("X-Amz-Credential")
  valid_611587 = validateParameter(valid_611587, JString, required = false,
                                 default = nil)
  if valid_611587 != nil:
    section.add "X-Amz-Credential", valid_611587
  var valid_611588 = header.getOrDefault("X-Amz-Security-Token")
  valid_611588 = validateParameter(valid_611588, JString, required = false,
                                 default = nil)
  if valid_611588 != nil:
    section.add "X-Amz-Security-Token", valid_611588
  var valid_611589 = header.getOrDefault("X-Amz-Algorithm")
  valid_611589 = validateParameter(valid_611589, JString, required = false,
                                 default = nil)
  if valid_611589 != nil:
    section.add "X-Amz-Algorithm", valid_611589
  var valid_611590 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611590 = validateParameter(valid_611590, JString, required = false,
                                 default = nil)
  if valid_611590 != nil:
    section.add "X-Amz-SignedHeaders", valid_611590
  result.add "header", section
  ## parameters in `formData` object:
  ##   Description: JString
  ##              : Describes this environment.
  ##   Tier.Type: JString
  ##            : Describes the properties of an environment tier
  ## <p>The type of this environment tier.</p> <p>Valid values:</p> <ul> <li> <p>For <i>Web server tier</i> – <code>Standard</code> </p> </li> <li> <p>For <i>Worker tier</i> – <code>SQS/HTTP</code> </p> </li> </ul>
  ##   EnvironmentName: JString
  ##                  : <p>A unique name for the deployment environment. Used in the application URL.</p> <p>Constraint: Must be from 4 to 40 characters in length. The name can contain only letters, numbers, and hyphens. It cannot start or end with a hyphen. This name must be unique within a region in your account. If the specified name already exists in the region, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. </p> <p>Default: If the CNAME parameter is not specified, the environment name becomes part of the CNAME, and therefore part of the visible URL for your application.</p>
  ##   CNAMEPrefix: JString
  ##              : If specified, the environment attempts to use this value as the prefix for the CNAME. If not specified, the CNAME is generated automatically by appending a random alphanumeric string to the environment name.
  ##   VersionLabel: JString
  ##               : <p>The name of the application version to deploy.</p> <p> If the specified application has no associated application versions, AWS Elastic Beanstalk <code>UpdateEnvironment</code> returns an <code>InvalidParameterValue</code> error. </p> <p>Default: If not specified, AWS Elastic Beanstalk attempts to launch the sample application in the container.</p>
  ##   TemplateName: JString
  ##               :  The name of the configuration template to use in deployment. If no configuration template is found with this name, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. 
  ##   OptionsToRemove: JArray
  ##                  : A list of custom user-defined configuration options to remove from the configuration set for this new environment.
  ##   OptionSettings: JArray
  ##                 : If specified, AWS Elastic Beanstalk sets the specified configuration options to the requested value in the configuration set for the new environment. These override the values obtained from the solution stack or the configuration template.
  ##   GroupName: JString
  ##            : The name of the group to which the target environment belongs. Specify a group name only if the environment's name is specified in an environment manifest and not with the environment name parameter. See <a 
  ## href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-cfg-manifest.html">Environment Manifest (env.yaml)</a> for details.
  ##   ApplicationName: JString (required)
  ##                  : <p>The name of the application that contains the version to be deployed.</p> <p> If no application is found with this name, <code>CreateEnvironment</code> returns an <code>InvalidParameterValue</code> error. </p>
  ##   Tier.Name: JString
  ##            : Describes the properties of an environment tier
  ## <p>The name of this environment tier.</p> <p>Valid values:</p> <ul> <li> <p>For <i>Web server tier</i> – <code>WebServer</code> </p> </li> <li> <p>For <i>Worker tier</i> – <code>Worker</code> </p> </li> </ul>
  ##   Tier.Version: JString
  ##               : Describes the properties of an environment tier
  ## <p>The version of this environment tier. When you don't set a value to it, Elastic Beanstalk uses the latest compatible worker tier version.</p> <note> <p>This member is deprecated. Any specific version that you set may become out of date. We recommend leaving it unspecified.</p> </note>
  ##   Tags: JArray
  ##       : Specifies the tags applied to resources in the environment.
  ##   SolutionStackName: JString
  ##                    : <p>This is an alternative to specifying a template name. If specified, AWS Elastic Beanstalk sets the configuration values to the default values associated with the specified solution stack.</p> <p>For a list of current solution stacks, see <a 
  ## href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/concepts.platforms.html">Elastic Beanstalk Supported Platforms</a>.</p>
  ##   PlatformArn: JString
  ##              : The ARN of the platform.
  section = newJObject()
  var valid_611591 = formData.getOrDefault("Description")
  valid_611591 = validateParameter(valid_611591, JString, required = false,
                                 default = nil)
  if valid_611591 != nil:
    section.add "Description", valid_611591
  var valid_611592 = formData.getOrDefault("Tier.Type")
  valid_611592 = validateParameter(valid_611592, JString, required = false,
                                 default = nil)
  if valid_611592 != nil:
    section.add "Tier.Type", valid_611592
  var valid_611593 = formData.getOrDefault("EnvironmentName")
  valid_611593 = validateParameter(valid_611593, JString, required = false,
                                 default = nil)
  if valid_611593 != nil:
    section.add "EnvironmentName", valid_611593
  var valid_611594 = formData.getOrDefault("CNAMEPrefix")
  valid_611594 = validateParameter(valid_611594, JString, required = false,
                                 default = nil)
  if valid_611594 != nil:
    section.add "CNAMEPrefix", valid_611594
  var valid_611595 = formData.getOrDefault("VersionLabel")
  valid_611595 = validateParameter(valid_611595, JString, required = false,
                                 default = nil)
  if valid_611595 != nil:
    section.add "VersionLabel", valid_611595
  var valid_611596 = formData.getOrDefault("TemplateName")
  valid_611596 = validateParameter(valid_611596, JString, required = false,
                                 default = nil)
  if valid_611596 != nil:
    section.add "TemplateName", valid_611596
  var valid_611597 = formData.getOrDefault("OptionsToRemove")
  valid_611597 = validateParameter(valid_611597, JArray, required = false,
                                 default = nil)
  if valid_611597 != nil:
    section.add "OptionsToRemove", valid_611597
  var valid_611598 = formData.getOrDefault("OptionSettings")
  valid_611598 = validateParameter(valid_611598, JArray, required = false,
                                 default = nil)
  if valid_611598 != nil:
    section.add "OptionSettings", valid_611598
  var valid_611599 = formData.getOrDefault("GroupName")
  valid_611599 = validateParameter(valid_611599, JString, required = false,
                                 default = nil)
  if valid_611599 != nil:
    section.add "GroupName", valid_611599
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_611600 = formData.getOrDefault("ApplicationName")
  valid_611600 = validateParameter(valid_611600, JString, required = true,
                                 default = nil)
  if valid_611600 != nil:
    section.add "ApplicationName", valid_611600
  var valid_611601 = formData.getOrDefault("Tier.Name")
  valid_611601 = validateParameter(valid_611601, JString, required = false,
                                 default = nil)
  if valid_611601 != nil:
    section.add "Tier.Name", valid_611601
  var valid_611602 = formData.getOrDefault("Tier.Version")
  valid_611602 = validateParameter(valid_611602, JString, required = false,
                                 default = nil)
  if valid_611602 != nil:
    section.add "Tier.Version", valid_611602
  var valid_611603 = formData.getOrDefault("Tags")
  valid_611603 = validateParameter(valid_611603, JArray, required = false,
                                 default = nil)
  if valid_611603 != nil:
    section.add "Tags", valid_611603
  var valid_611604 = formData.getOrDefault("SolutionStackName")
  valid_611604 = validateParameter(valid_611604, JString, required = false,
                                 default = nil)
  if valid_611604 != nil:
    section.add "SolutionStackName", valid_611604
  var valid_611605 = formData.getOrDefault("PlatformArn")
  valid_611605 = validateParameter(valid_611605, JString, required = false,
                                 default = nil)
  if valid_611605 != nil:
    section.add "PlatformArn", valid_611605
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611606: Call_PostCreateEnvironment_611579; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Launches an environment for the specified application using the specified configuration.
  ## 
  let valid = call_611606.validator(path, query, header, formData, body)
  let scheme = call_611606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611606.url(scheme.get, call_611606.host, call_611606.base,
                         call_611606.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611606, url, valid)

proc call*(call_611607: Call_PostCreateEnvironment_611579; ApplicationName: string;
          Description: string = ""; TierType: string = ""; EnvironmentName: string = "";
          CNAMEPrefix: string = ""; VersionLabel: string = "";
          TemplateName: string = ""; OptionsToRemove: JsonNode = nil;
          OptionSettings: JsonNode = nil; GroupName: string = ""; TierName: string = "";
          TierVersion: string = ""; Action: string = "CreateEnvironment";
          Tags: JsonNode = nil; SolutionStackName: string = "";
          Version: string = "2010-12-01"; PlatformArn: string = ""): Recallable =
  ## postCreateEnvironment
  ## Launches an environment for the specified application using the specified configuration.
  ##   Description: string
  ##              : Describes this environment.
  ##   TierType: string
  ##           : Describes the properties of an environment tier
  ## <p>The type of this environment tier.</p> <p>Valid values:</p> <ul> <li> <p>For <i>Web server tier</i> – <code>Standard</code> </p> </li> <li> <p>For <i>Worker tier</i> – <code>SQS/HTTP</code> </p> </li> </ul>
  ##   EnvironmentName: string
  ##                  : <p>A unique name for the deployment environment. Used in the application URL.</p> <p>Constraint: Must be from 4 to 40 characters in length. The name can contain only letters, numbers, and hyphens. It cannot start or end with a hyphen. This name must be unique within a region in your account. If the specified name already exists in the region, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. </p> <p>Default: If the CNAME parameter is not specified, the environment name becomes part of the CNAME, and therefore part of the visible URL for your application.</p>
  ##   CNAMEPrefix: string
  ##              : If specified, the environment attempts to use this value as the prefix for the CNAME. If not specified, the CNAME is generated automatically by appending a random alphanumeric string to the environment name.
  ##   VersionLabel: string
  ##               : <p>The name of the application version to deploy.</p> <p> If the specified application has no associated application versions, AWS Elastic Beanstalk <code>UpdateEnvironment</code> returns an <code>InvalidParameterValue</code> error. </p> <p>Default: If not specified, AWS Elastic Beanstalk attempts to launch the sample application in the container.</p>
  ##   TemplateName: string
  ##               :  The name of the configuration template to use in deployment. If no configuration template is found with this name, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. 
  ##   OptionsToRemove: JArray
  ##                  : A list of custom user-defined configuration options to remove from the configuration set for this new environment.
  ##   OptionSettings: JArray
  ##                 : If specified, AWS Elastic Beanstalk sets the specified configuration options to the requested value in the configuration set for the new environment. These override the values obtained from the solution stack or the configuration template.
  ##   GroupName: string
  ##            : The name of the group to which the target environment belongs. Specify a group name only if the environment's name is specified in an environment manifest and not with the environment name parameter. See <a 
  ## href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-cfg-manifest.html">Environment Manifest (env.yaml)</a> for details.
  ##   ApplicationName: string (required)
  ##                  : <p>The name of the application that contains the version to be deployed.</p> <p> If no application is found with this name, <code>CreateEnvironment</code> returns an <code>InvalidParameterValue</code> error. </p>
  ##   TierName: string
  ##           : Describes the properties of an environment tier
  ## <p>The name of this environment tier.</p> <p>Valid values:</p> <ul> <li> <p>For <i>Web server tier</i> – <code>WebServer</code> </p> </li> <li> <p>For <i>Worker tier</i> – <code>Worker</code> </p> </li> </ul>
  ##   TierVersion: string
  ##              : Describes the properties of an environment tier
  ## <p>The version of this environment tier. When you don't set a value to it, Elastic Beanstalk uses the latest compatible worker tier version.</p> <note> <p>This member is deprecated. Any specific version that you set may become out of date. We recommend leaving it unspecified.</p> </note>
  ##   Action: string (required)
  ##   Tags: JArray
  ##       : Specifies the tags applied to resources in the environment.
  ##   SolutionStackName: string
  ##                    : <p>This is an alternative to specifying a template name. If specified, AWS Elastic Beanstalk sets the configuration values to the default values associated with the specified solution stack.</p> <p>For a list of current solution stacks, see <a 
  ## href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/concepts.platforms.html">Elastic Beanstalk Supported Platforms</a>.</p>
  ##   Version: string (required)
  ##   PlatformArn: string
  ##              : The ARN of the platform.
  var query_611608 = newJObject()
  var formData_611609 = newJObject()
  add(formData_611609, "Description", newJString(Description))
  add(formData_611609, "Tier.Type", newJString(TierType))
  add(formData_611609, "EnvironmentName", newJString(EnvironmentName))
  add(formData_611609, "CNAMEPrefix", newJString(CNAMEPrefix))
  add(formData_611609, "VersionLabel", newJString(VersionLabel))
  add(formData_611609, "TemplateName", newJString(TemplateName))
  if OptionsToRemove != nil:
    formData_611609.add "OptionsToRemove", OptionsToRemove
  if OptionSettings != nil:
    formData_611609.add "OptionSettings", OptionSettings
  add(formData_611609, "GroupName", newJString(GroupName))
  add(formData_611609, "ApplicationName", newJString(ApplicationName))
  add(formData_611609, "Tier.Name", newJString(TierName))
  add(formData_611609, "Tier.Version", newJString(TierVersion))
  add(query_611608, "Action", newJString(Action))
  if Tags != nil:
    formData_611609.add "Tags", Tags
  add(formData_611609, "SolutionStackName", newJString(SolutionStackName))
  add(query_611608, "Version", newJString(Version))
  add(formData_611609, "PlatformArn", newJString(PlatformArn))
  result = call_611607.call(nil, query_611608, nil, formData_611609, nil)

var postCreateEnvironment* = Call_PostCreateEnvironment_611579(
    name: "postCreateEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateEnvironment",
    validator: validate_PostCreateEnvironment_611580, base: "/",
    url: url_PostCreateEnvironment_611581, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEnvironment_611549 = ref object of OpenApiRestCall_610659
proc url_GetCreateEnvironment_611551(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateEnvironment_611550(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Launches an environment for the specified application using the specified configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ApplicationName: JString (required)
  ##                  : <p>The name of the application that contains the version to be deployed.</p> <p> If no application is found with this name, <code>CreateEnvironment</code> returns an <code>InvalidParameterValue</code> error. </p>
  ##   CNAMEPrefix: JString
  ##              : If specified, the environment attempts to use this value as the prefix for the CNAME. If not specified, the CNAME is generated automatically by appending a random alphanumeric string to the environment name.
  ##   GroupName: JString
  ##            : The name of the group to which the target environment belongs. Specify a group name only if the environment's name is specified in an environment manifest and not with the environment name parameter. See <a 
  ## href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-cfg-manifest.html">Environment Manifest (env.yaml)</a> for details.
  ##   Tags: JArray
  ##       : Specifies the tags applied to resources in the environment.
  ##   VersionLabel: JString
  ##               : <p>The name of the application version to deploy.</p> <p> If the specified application has no associated application versions, AWS Elastic Beanstalk <code>UpdateEnvironment</code> returns an <code>InvalidParameterValue</code> error. </p> <p>Default: If not specified, AWS Elastic Beanstalk attempts to launch the sample application in the container.</p>
  ##   OptionSettings: JArray
  ##                 : If specified, AWS Elastic Beanstalk sets the specified configuration options to the requested value in the configuration set for the new environment. These override the values obtained from the solution stack or the configuration template.
  ##   SolutionStackName: JString
  ##                    : <p>This is an alternative to specifying a template name. If specified, AWS Elastic Beanstalk sets the configuration values to the default values associated with the specified solution stack.</p> <p>For a list of current solution stacks, see <a 
  ## href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/concepts.platforms.html">Elastic Beanstalk Supported Platforms</a>.</p>
  ##   Tier.Name: JString
  ##            : Describes the properties of an environment tier
  ## <p>The name of this environment tier.</p> <p>Valid values:</p> <ul> <li> <p>For <i>Web server tier</i> – <code>WebServer</code> </p> </li> <li> <p>For <i>Worker tier</i> – <code>Worker</code> </p> </li> </ul>
  ##   EnvironmentName: JString
  ##                  : <p>A unique name for the deployment environment. Used in the application URL.</p> <p>Constraint: Must be from 4 to 40 characters in length. The name can contain only letters, numbers, and hyphens. It cannot start or end with a hyphen. This name must be unique within a region in your account. If the specified name already exists in the region, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. </p> <p>Default: If the CNAME parameter is not specified, the environment name becomes part of the CNAME, and therefore part of the visible URL for your application.</p>
  ##   Action: JString (required)
  ##   Description: JString
  ##              : Describes this environment.
  ##   PlatformArn: JString
  ##              : The ARN of the platform.
  ##   OptionsToRemove: JArray
  ##                  : A list of custom user-defined configuration options to remove from the configuration set for this new environment.
  ##   Version: JString (required)
  ##   TemplateName: JString
  ##               :  The name of the configuration template to use in deployment. If no configuration template is found with this name, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. 
  ##   Tier.Version: JString
  ##               : Describes the properties of an environment tier
  ## <p>The version of this environment tier. When you don't set a value to it, Elastic Beanstalk uses the latest compatible worker tier version.</p> <note> <p>This member is deprecated. Any specific version that you set may become out of date. We recommend leaving it unspecified.</p> </note>
  ##   Tier.Type: JString
  ##            : Describes the properties of an environment tier
  ## <p>The type of this environment tier.</p> <p>Valid values:</p> <ul> <li> <p>For <i>Web server tier</i> – <code>Standard</code> </p> </li> <li> <p>For <i>Worker tier</i> – <code>SQS/HTTP</code> </p> </li> </ul>
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_611552 = query.getOrDefault("ApplicationName")
  valid_611552 = validateParameter(valid_611552, JString, required = true,
                                 default = nil)
  if valid_611552 != nil:
    section.add "ApplicationName", valid_611552
  var valid_611553 = query.getOrDefault("CNAMEPrefix")
  valid_611553 = validateParameter(valid_611553, JString, required = false,
                                 default = nil)
  if valid_611553 != nil:
    section.add "CNAMEPrefix", valid_611553
  var valid_611554 = query.getOrDefault("GroupName")
  valid_611554 = validateParameter(valid_611554, JString, required = false,
                                 default = nil)
  if valid_611554 != nil:
    section.add "GroupName", valid_611554
  var valid_611555 = query.getOrDefault("Tags")
  valid_611555 = validateParameter(valid_611555, JArray, required = false,
                                 default = nil)
  if valid_611555 != nil:
    section.add "Tags", valid_611555
  var valid_611556 = query.getOrDefault("VersionLabel")
  valid_611556 = validateParameter(valid_611556, JString, required = false,
                                 default = nil)
  if valid_611556 != nil:
    section.add "VersionLabel", valid_611556
  var valid_611557 = query.getOrDefault("OptionSettings")
  valid_611557 = validateParameter(valid_611557, JArray, required = false,
                                 default = nil)
  if valid_611557 != nil:
    section.add "OptionSettings", valid_611557
  var valid_611558 = query.getOrDefault("SolutionStackName")
  valid_611558 = validateParameter(valid_611558, JString, required = false,
                                 default = nil)
  if valid_611558 != nil:
    section.add "SolutionStackName", valid_611558
  var valid_611559 = query.getOrDefault("Tier.Name")
  valid_611559 = validateParameter(valid_611559, JString, required = false,
                                 default = nil)
  if valid_611559 != nil:
    section.add "Tier.Name", valid_611559
  var valid_611560 = query.getOrDefault("EnvironmentName")
  valid_611560 = validateParameter(valid_611560, JString, required = false,
                                 default = nil)
  if valid_611560 != nil:
    section.add "EnvironmentName", valid_611560
  var valid_611561 = query.getOrDefault("Action")
  valid_611561 = validateParameter(valid_611561, JString, required = true,
                                 default = newJString("CreateEnvironment"))
  if valid_611561 != nil:
    section.add "Action", valid_611561
  var valid_611562 = query.getOrDefault("Description")
  valid_611562 = validateParameter(valid_611562, JString, required = false,
                                 default = nil)
  if valid_611562 != nil:
    section.add "Description", valid_611562
  var valid_611563 = query.getOrDefault("PlatformArn")
  valid_611563 = validateParameter(valid_611563, JString, required = false,
                                 default = nil)
  if valid_611563 != nil:
    section.add "PlatformArn", valid_611563
  var valid_611564 = query.getOrDefault("OptionsToRemove")
  valid_611564 = validateParameter(valid_611564, JArray, required = false,
                                 default = nil)
  if valid_611564 != nil:
    section.add "OptionsToRemove", valid_611564
  var valid_611565 = query.getOrDefault("Version")
  valid_611565 = validateParameter(valid_611565, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_611565 != nil:
    section.add "Version", valid_611565
  var valid_611566 = query.getOrDefault("TemplateName")
  valid_611566 = validateParameter(valid_611566, JString, required = false,
                                 default = nil)
  if valid_611566 != nil:
    section.add "TemplateName", valid_611566
  var valid_611567 = query.getOrDefault("Tier.Version")
  valid_611567 = validateParameter(valid_611567, JString, required = false,
                                 default = nil)
  if valid_611567 != nil:
    section.add "Tier.Version", valid_611567
  var valid_611568 = query.getOrDefault("Tier.Type")
  valid_611568 = validateParameter(valid_611568, JString, required = false,
                                 default = nil)
  if valid_611568 != nil:
    section.add "Tier.Type", valid_611568
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611569 = header.getOrDefault("X-Amz-Signature")
  valid_611569 = validateParameter(valid_611569, JString, required = false,
                                 default = nil)
  if valid_611569 != nil:
    section.add "X-Amz-Signature", valid_611569
  var valid_611570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611570 = validateParameter(valid_611570, JString, required = false,
                                 default = nil)
  if valid_611570 != nil:
    section.add "X-Amz-Content-Sha256", valid_611570
  var valid_611571 = header.getOrDefault("X-Amz-Date")
  valid_611571 = validateParameter(valid_611571, JString, required = false,
                                 default = nil)
  if valid_611571 != nil:
    section.add "X-Amz-Date", valid_611571
  var valid_611572 = header.getOrDefault("X-Amz-Credential")
  valid_611572 = validateParameter(valid_611572, JString, required = false,
                                 default = nil)
  if valid_611572 != nil:
    section.add "X-Amz-Credential", valid_611572
  var valid_611573 = header.getOrDefault("X-Amz-Security-Token")
  valid_611573 = validateParameter(valid_611573, JString, required = false,
                                 default = nil)
  if valid_611573 != nil:
    section.add "X-Amz-Security-Token", valid_611573
  var valid_611574 = header.getOrDefault("X-Amz-Algorithm")
  valid_611574 = validateParameter(valid_611574, JString, required = false,
                                 default = nil)
  if valid_611574 != nil:
    section.add "X-Amz-Algorithm", valid_611574
  var valid_611575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611575 = validateParameter(valid_611575, JString, required = false,
                                 default = nil)
  if valid_611575 != nil:
    section.add "X-Amz-SignedHeaders", valid_611575
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611576: Call_GetCreateEnvironment_611549; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Launches an environment for the specified application using the specified configuration.
  ## 
  let valid = call_611576.validator(path, query, header, formData, body)
  let scheme = call_611576.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611576.url(scheme.get, call_611576.host, call_611576.base,
                         call_611576.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611576, url, valid)

proc call*(call_611577: Call_GetCreateEnvironment_611549; ApplicationName: string;
          CNAMEPrefix: string = ""; GroupName: string = ""; Tags: JsonNode = nil;
          VersionLabel: string = ""; OptionSettings: JsonNode = nil;
          SolutionStackName: string = ""; TierName: string = "";
          EnvironmentName: string = ""; Action: string = "CreateEnvironment";
          Description: string = ""; PlatformArn: string = "";
          OptionsToRemove: JsonNode = nil; Version: string = "2010-12-01";
          TemplateName: string = ""; TierVersion: string = ""; TierType: string = ""): Recallable =
  ## getCreateEnvironment
  ## Launches an environment for the specified application using the specified configuration.
  ##   ApplicationName: string (required)
  ##                  : <p>The name of the application that contains the version to be deployed.</p> <p> If no application is found with this name, <code>CreateEnvironment</code> returns an <code>InvalidParameterValue</code> error. </p>
  ##   CNAMEPrefix: string
  ##              : If specified, the environment attempts to use this value as the prefix for the CNAME. If not specified, the CNAME is generated automatically by appending a random alphanumeric string to the environment name.
  ##   GroupName: string
  ##            : The name of the group to which the target environment belongs. Specify a group name only if the environment's name is specified in an environment manifest and not with the environment name parameter. See <a 
  ## href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-cfg-manifest.html">Environment Manifest (env.yaml)</a> for details.
  ##   Tags: JArray
  ##       : Specifies the tags applied to resources in the environment.
  ##   VersionLabel: string
  ##               : <p>The name of the application version to deploy.</p> <p> If the specified application has no associated application versions, AWS Elastic Beanstalk <code>UpdateEnvironment</code> returns an <code>InvalidParameterValue</code> error. </p> <p>Default: If not specified, AWS Elastic Beanstalk attempts to launch the sample application in the container.</p>
  ##   OptionSettings: JArray
  ##                 : If specified, AWS Elastic Beanstalk sets the specified configuration options to the requested value in the configuration set for the new environment. These override the values obtained from the solution stack or the configuration template.
  ##   SolutionStackName: string
  ##                    : <p>This is an alternative to specifying a template name. If specified, AWS Elastic Beanstalk sets the configuration values to the default values associated with the specified solution stack.</p> <p>For a list of current solution stacks, see <a 
  ## href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/concepts.platforms.html">Elastic Beanstalk Supported Platforms</a>.</p>
  ##   TierName: string
  ##           : Describes the properties of an environment tier
  ## <p>The name of this environment tier.</p> <p>Valid values:</p> <ul> <li> <p>For <i>Web server tier</i> – <code>WebServer</code> </p> </li> <li> <p>For <i>Worker tier</i> – <code>Worker</code> </p> </li> </ul>
  ##   EnvironmentName: string
  ##                  : <p>A unique name for the deployment environment. Used in the application URL.</p> <p>Constraint: Must be from 4 to 40 characters in length. The name can contain only letters, numbers, and hyphens. It cannot start or end with a hyphen. This name must be unique within a region in your account. If the specified name already exists in the region, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. </p> <p>Default: If the CNAME parameter is not specified, the environment name becomes part of the CNAME, and therefore part of the visible URL for your application.</p>
  ##   Action: string (required)
  ##   Description: string
  ##              : Describes this environment.
  ##   PlatformArn: string
  ##              : The ARN of the platform.
  ##   OptionsToRemove: JArray
  ##                  : A list of custom user-defined configuration options to remove from the configuration set for this new environment.
  ##   Version: string (required)
  ##   TemplateName: string
  ##               :  The name of the configuration template to use in deployment. If no configuration template is found with this name, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. 
  ##   TierVersion: string
  ##              : Describes the properties of an environment tier
  ## <p>The version of this environment tier. When you don't set a value to it, Elastic Beanstalk uses the latest compatible worker tier version.</p> <note> <p>This member is deprecated. Any specific version that you set may become out of date. We recommend leaving it unspecified.</p> </note>
  ##   TierType: string
  ##           : Describes the properties of an environment tier
  ## <p>The type of this environment tier.</p> <p>Valid values:</p> <ul> <li> <p>For <i>Web server tier</i> – <code>Standard</code> </p> </li> <li> <p>For <i>Worker tier</i> – <code>SQS/HTTP</code> </p> </li> </ul>
  var query_611578 = newJObject()
  add(query_611578, "ApplicationName", newJString(ApplicationName))
  add(query_611578, "CNAMEPrefix", newJString(CNAMEPrefix))
  add(query_611578, "GroupName", newJString(GroupName))
  if Tags != nil:
    query_611578.add "Tags", Tags
  add(query_611578, "VersionLabel", newJString(VersionLabel))
  if OptionSettings != nil:
    query_611578.add "OptionSettings", OptionSettings
  add(query_611578, "SolutionStackName", newJString(SolutionStackName))
  add(query_611578, "Tier.Name", newJString(TierName))
  add(query_611578, "EnvironmentName", newJString(EnvironmentName))
  add(query_611578, "Action", newJString(Action))
  add(query_611578, "Description", newJString(Description))
  add(query_611578, "PlatformArn", newJString(PlatformArn))
  if OptionsToRemove != nil:
    query_611578.add "OptionsToRemove", OptionsToRemove
  add(query_611578, "Version", newJString(Version))
  add(query_611578, "TemplateName", newJString(TemplateName))
  add(query_611578, "Tier.Version", newJString(TierVersion))
  add(query_611578, "Tier.Type", newJString(TierType))
  result = call_611577.call(nil, query_611578, nil, nil, nil)

var getCreateEnvironment* = Call_GetCreateEnvironment_611549(
    name: "getCreateEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateEnvironment",
    validator: validate_GetCreateEnvironment_611550, base: "/",
    url: url_GetCreateEnvironment_611551, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreatePlatformVersion_611632 = ref object of OpenApiRestCall_610659
proc url_PostCreatePlatformVersion_611634(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreatePlatformVersion_611633(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Create a new version of your custom platform.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611635 = query.getOrDefault("Action")
  valid_611635 = validateParameter(valid_611635, JString, required = true,
                                 default = newJString("CreatePlatformVersion"))
  if valid_611635 != nil:
    section.add "Action", valid_611635
  var valid_611636 = query.getOrDefault("Version")
  valid_611636 = validateParameter(valid_611636, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_611636 != nil:
    section.add "Version", valid_611636
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611637 = header.getOrDefault("X-Amz-Signature")
  valid_611637 = validateParameter(valid_611637, JString, required = false,
                                 default = nil)
  if valid_611637 != nil:
    section.add "X-Amz-Signature", valid_611637
  var valid_611638 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611638 = validateParameter(valid_611638, JString, required = false,
                                 default = nil)
  if valid_611638 != nil:
    section.add "X-Amz-Content-Sha256", valid_611638
  var valid_611639 = header.getOrDefault("X-Amz-Date")
  valid_611639 = validateParameter(valid_611639, JString, required = false,
                                 default = nil)
  if valid_611639 != nil:
    section.add "X-Amz-Date", valid_611639
  var valid_611640 = header.getOrDefault("X-Amz-Credential")
  valid_611640 = validateParameter(valid_611640, JString, required = false,
                                 default = nil)
  if valid_611640 != nil:
    section.add "X-Amz-Credential", valid_611640
  var valid_611641 = header.getOrDefault("X-Amz-Security-Token")
  valid_611641 = validateParameter(valid_611641, JString, required = false,
                                 default = nil)
  if valid_611641 != nil:
    section.add "X-Amz-Security-Token", valid_611641
  var valid_611642 = header.getOrDefault("X-Amz-Algorithm")
  valid_611642 = validateParameter(valid_611642, JString, required = false,
                                 default = nil)
  if valid_611642 != nil:
    section.add "X-Amz-Algorithm", valid_611642
  var valid_611643 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611643 = validateParameter(valid_611643, JString, required = false,
                                 default = nil)
  if valid_611643 != nil:
    section.add "X-Amz-SignedHeaders", valid_611643
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString
  ##                  : The name of the builder environment.
  ##   PlatformDefinitionBundle.S3Key: JString
  ##                                 : The bucket and key of an item stored in Amazon S3.
  ## The Amazon S3 key where the data is located.
  ##   PlatformVersion: JString (required)
  ##                  : The number, such as 1.0.2, for the new platform version.
  ##   OptionSettings: JArray
  ##                 : The configuration option settings to apply to the builder environment.
  ##   Tags: JArray
  ##       : <p>Specifies the tags applied to the new platform version.</p> <p>Elastic Beanstalk applies these tags only to the platform version. Environments that you create using the platform version don't inherit the tags.</p>
  ##   PlatformDefinitionBundle.S3Bucket: JString
  ##                                    : The bucket and key of an item stored in Amazon S3.
  ## The Amazon S3 bucket where the data is located.
  ##   PlatformName: JString (required)
  ##               : The name of your custom platform.
  section = newJObject()
  var valid_611644 = formData.getOrDefault("EnvironmentName")
  valid_611644 = validateParameter(valid_611644, JString, required = false,
                                 default = nil)
  if valid_611644 != nil:
    section.add "EnvironmentName", valid_611644
  var valid_611645 = formData.getOrDefault("PlatformDefinitionBundle.S3Key")
  valid_611645 = validateParameter(valid_611645, JString, required = false,
                                 default = nil)
  if valid_611645 != nil:
    section.add "PlatformDefinitionBundle.S3Key", valid_611645
  assert formData != nil, "formData argument is necessary due to required `PlatformVersion` field"
  var valid_611646 = formData.getOrDefault("PlatformVersion")
  valid_611646 = validateParameter(valid_611646, JString, required = true,
                                 default = nil)
  if valid_611646 != nil:
    section.add "PlatformVersion", valid_611646
  var valid_611647 = formData.getOrDefault("OptionSettings")
  valid_611647 = validateParameter(valid_611647, JArray, required = false,
                                 default = nil)
  if valid_611647 != nil:
    section.add "OptionSettings", valid_611647
  var valid_611648 = formData.getOrDefault("Tags")
  valid_611648 = validateParameter(valid_611648, JArray, required = false,
                                 default = nil)
  if valid_611648 != nil:
    section.add "Tags", valid_611648
  var valid_611649 = formData.getOrDefault("PlatformDefinitionBundle.S3Bucket")
  valid_611649 = validateParameter(valid_611649, JString, required = false,
                                 default = nil)
  if valid_611649 != nil:
    section.add "PlatformDefinitionBundle.S3Bucket", valid_611649
  var valid_611650 = formData.getOrDefault("PlatformName")
  valid_611650 = validateParameter(valid_611650, JString, required = true,
                                 default = nil)
  if valid_611650 != nil:
    section.add "PlatformName", valid_611650
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611651: Call_PostCreatePlatformVersion_611632; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new version of your custom platform.
  ## 
  let valid = call_611651.validator(path, query, header, formData, body)
  let scheme = call_611651.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611651.url(scheme.get, call_611651.host, call_611651.base,
                         call_611651.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611651, url, valid)

proc call*(call_611652: Call_PostCreatePlatformVersion_611632;
          PlatformVersion: string; PlatformName: string;
          EnvironmentName: string = ""; PlatformDefinitionBundleS3Key: string = "";
          OptionSettings: JsonNode = nil; Action: string = "CreatePlatformVersion";
          Tags: JsonNode = nil; PlatformDefinitionBundleS3Bucket: string = "";
          Version: string = "2010-12-01"): Recallable =
  ## postCreatePlatformVersion
  ## Create a new version of your custom platform.
  ##   EnvironmentName: string
  ##                  : The name of the builder environment.
  ##   PlatformDefinitionBundleS3Key: string
  ##                                : The bucket and key of an item stored in Amazon S3.
  ## The Amazon S3 key where the data is located.
  ##   PlatformVersion: string (required)
  ##                  : The number, such as 1.0.2, for the new platform version.
  ##   OptionSettings: JArray
  ##                 : The configuration option settings to apply to the builder environment.
  ##   Action: string (required)
  ##   Tags: JArray
  ##       : <p>Specifies the tags applied to the new platform version.</p> <p>Elastic Beanstalk applies these tags only to the platform version. Environments that you create using the platform version don't inherit the tags.</p>
  ##   PlatformDefinitionBundleS3Bucket: string
  ##                                   : The bucket and key of an item stored in Amazon S3.
  ## The Amazon S3 bucket where the data is located.
  ##   Version: string (required)
  ##   PlatformName: string (required)
  ##               : The name of your custom platform.
  var query_611653 = newJObject()
  var formData_611654 = newJObject()
  add(formData_611654, "EnvironmentName", newJString(EnvironmentName))
  add(formData_611654, "PlatformDefinitionBundle.S3Key",
      newJString(PlatformDefinitionBundleS3Key))
  add(formData_611654, "PlatformVersion", newJString(PlatformVersion))
  if OptionSettings != nil:
    formData_611654.add "OptionSettings", OptionSettings
  add(query_611653, "Action", newJString(Action))
  if Tags != nil:
    formData_611654.add "Tags", Tags
  add(formData_611654, "PlatformDefinitionBundle.S3Bucket",
      newJString(PlatformDefinitionBundleS3Bucket))
  add(query_611653, "Version", newJString(Version))
  add(formData_611654, "PlatformName", newJString(PlatformName))
  result = call_611652.call(nil, query_611653, nil, formData_611654, nil)

var postCreatePlatformVersion* = Call_PostCreatePlatformVersion_611632(
    name: "postCreatePlatformVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreatePlatformVersion",
    validator: validate_PostCreatePlatformVersion_611633, base: "/",
    url: url_PostCreatePlatformVersion_611634,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreatePlatformVersion_611610 = ref object of OpenApiRestCall_610659
proc url_GetCreatePlatformVersion_611612(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreatePlatformVersion_611611(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Create a new version of your custom platform.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PlatformName: JString (required)
  ##               : The name of your custom platform.
  ##   PlatformVersion: JString (required)
  ##                  : The number, such as 1.0.2, for the new platform version.
  ##   Tags: JArray
  ##       : <p>Specifies the tags applied to the new platform version.</p> <p>Elastic Beanstalk applies these tags only to the platform version. Environments that you create using the platform version don't inherit the tags.</p>
  ##   OptionSettings: JArray
  ##                 : The configuration option settings to apply to the builder environment.
  ##   PlatformDefinitionBundle.S3Bucket: JString
  ##                                    : The bucket and key of an item stored in Amazon S3.
  ## The Amazon S3 bucket where the data is located.
  ##   EnvironmentName: JString
  ##                  : The name of the builder environment.
  ##   Action: JString (required)
  ##   PlatformDefinitionBundle.S3Key: JString
  ##                                 : The bucket and key of an item stored in Amazon S3.
  ## The Amazon S3 key where the data is located.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `PlatformName` field"
  var valid_611613 = query.getOrDefault("PlatformName")
  valid_611613 = validateParameter(valid_611613, JString, required = true,
                                 default = nil)
  if valid_611613 != nil:
    section.add "PlatformName", valid_611613
  var valid_611614 = query.getOrDefault("PlatformVersion")
  valid_611614 = validateParameter(valid_611614, JString, required = true,
                                 default = nil)
  if valid_611614 != nil:
    section.add "PlatformVersion", valid_611614
  var valid_611615 = query.getOrDefault("Tags")
  valid_611615 = validateParameter(valid_611615, JArray, required = false,
                                 default = nil)
  if valid_611615 != nil:
    section.add "Tags", valid_611615
  var valid_611616 = query.getOrDefault("OptionSettings")
  valid_611616 = validateParameter(valid_611616, JArray, required = false,
                                 default = nil)
  if valid_611616 != nil:
    section.add "OptionSettings", valid_611616
  var valid_611617 = query.getOrDefault("PlatformDefinitionBundle.S3Bucket")
  valid_611617 = validateParameter(valid_611617, JString, required = false,
                                 default = nil)
  if valid_611617 != nil:
    section.add "PlatformDefinitionBundle.S3Bucket", valid_611617
  var valid_611618 = query.getOrDefault("EnvironmentName")
  valid_611618 = validateParameter(valid_611618, JString, required = false,
                                 default = nil)
  if valid_611618 != nil:
    section.add "EnvironmentName", valid_611618
  var valid_611619 = query.getOrDefault("Action")
  valid_611619 = validateParameter(valid_611619, JString, required = true,
                                 default = newJString("CreatePlatformVersion"))
  if valid_611619 != nil:
    section.add "Action", valid_611619
  var valid_611620 = query.getOrDefault("PlatformDefinitionBundle.S3Key")
  valid_611620 = validateParameter(valid_611620, JString, required = false,
                                 default = nil)
  if valid_611620 != nil:
    section.add "PlatformDefinitionBundle.S3Key", valid_611620
  var valid_611621 = query.getOrDefault("Version")
  valid_611621 = validateParameter(valid_611621, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_611621 != nil:
    section.add "Version", valid_611621
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611622 = header.getOrDefault("X-Amz-Signature")
  valid_611622 = validateParameter(valid_611622, JString, required = false,
                                 default = nil)
  if valid_611622 != nil:
    section.add "X-Amz-Signature", valid_611622
  var valid_611623 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611623 = validateParameter(valid_611623, JString, required = false,
                                 default = nil)
  if valid_611623 != nil:
    section.add "X-Amz-Content-Sha256", valid_611623
  var valid_611624 = header.getOrDefault("X-Amz-Date")
  valid_611624 = validateParameter(valid_611624, JString, required = false,
                                 default = nil)
  if valid_611624 != nil:
    section.add "X-Amz-Date", valid_611624
  var valid_611625 = header.getOrDefault("X-Amz-Credential")
  valid_611625 = validateParameter(valid_611625, JString, required = false,
                                 default = nil)
  if valid_611625 != nil:
    section.add "X-Amz-Credential", valid_611625
  var valid_611626 = header.getOrDefault("X-Amz-Security-Token")
  valid_611626 = validateParameter(valid_611626, JString, required = false,
                                 default = nil)
  if valid_611626 != nil:
    section.add "X-Amz-Security-Token", valid_611626
  var valid_611627 = header.getOrDefault("X-Amz-Algorithm")
  valid_611627 = validateParameter(valid_611627, JString, required = false,
                                 default = nil)
  if valid_611627 != nil:
    section.add "X-Amz-Algorithm", valid_611627
  var valid_611628 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611628 = validateParameter(valid_611628, JString, required = false,
                                 default = nil)
  if valid_611628 != nil:
    section.add "X-Amz-SignedHeaders", valid_611628
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611629: Call_GetCreatePlatformVersion_611610; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new version of your custom platform.
  ## 
  let valid = call_611629.validator(path, query, header, formData, body)
  let scheme = call_611629.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611629.url(scheme.get, call_611629.host, call_611629.base,
                         call_611629.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611629, url, valid)

proc call*(call_611630: Call_GetCreatePlatformVersion_611610; PlatformName: string;
          PlatformVersion: string; Tags: JsonNode = nil;
          OptionSettings: JsonNode = nil;
          PlatformDefinitionBundleS3Bucket: string = "";
          EnvironmentName: string = ""; Action: string = "CreatePlatformVersion";
          PlatformDefinitionBundleS3Key: string = ""; Version: string = "2010-12-01"): Recallable =
  ## getCreatePlatformVersion
  ## Create a new version of your custom platform.
  ##   PlatformName: string (required)
  ##               : The name of your custom platform.
  ##   PlatformVersion: string (required)
  ##                  : The number, such as 1.0.2, for the new platform version.
  ##   Tags: JArray
  ##       : <p>Specifies the tags applied to the new platform version.</p> <p>Elastic Beanstalk applies these tags only to the platform version. Environments that you create using the platform version don't inherit the tags.</p>
  ##   OptionSettings: JArray
  ##                 : The configuration option settings to apply to the builder environment.
  ##   PlatformDefinitionBundleS3Bucket: string
  ##                                   : The bucket and key of an item stored in Amazon S3.
  ## The Amazon S3 bucket where the data is located.
  ##   EnvironmentName: string
  ##                  : The name of the builder environment.
  ##   Action: string (required)
  ##   PlatformDefinitionBundleS3Key: string
  ##                                : The bucket and key of an item stored in Amazon S3.
  ## The Amazon S3 key where the data is located.
  ##   Version: string (required)
  var query_611631 = newJObject()
  add(query_611631, "PlatformName", newJString(PlatformName))
  add(query_611631, "PlatformVersion", newJString(PlatformVersion))
  if Tags != nil:
    query_611631.add "Tags", Tags
  if OptionSettings != nil:
    query_611631.add "OptionSettings", OptionSettings
  add(query_611631, "PlatformDefinitionBundle.S3Bucket",
      newJString(PlatformDefinitionBundleS3Bucket))
  add(query_611631, "EnvironmentName", newJString(EnvironmentName))
  add(query_611631, "Action", newJString(Action))
  add(query_611631, "PlatformDefinitionBundle.S3Key",
      newJString(PlatformDefinitionBundleS3Key))
  add(query_611631, "Version", newJString(Version))
  result = call_611630.call(nil, query_611631, nil, nil, nil)

var getCreatePlatformVersion* = Call_GetCreatePlatformVersion_611610(
    name: "getCreatePlatformVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreatePlatformVersion",
    validator: validate_GetCreatePlatformVersion_611611, base: "/",
    url: url_GetCreatePlatformVersion_611612, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateStorageLocation_611670 = ref object of OpenApiRestCall_610659
proc url_PostCreateStorageLocation_611672(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateStorageLocation_611671(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611673 = query.getOrDefault("Action")
  valid_611673 = validateParameter(valid_611673, JString, required = true,
                                 default = newJString("CreateStorageLocation"))
  if valid_611673 != nil:
    section.add "Action", valid_611673
  var valid_611674 = query.getOrDefault("Version")
  valid_611674 = validateParameter(valid_611674, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_611674 != nil:
    section.add "Version", valid_611674
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611675 = header.getOrDefault("X-Amz-Signature")
  valid_611675 = validateParameter(valid_611675, JString, required = false,
                                 default = nil)
  if valid_611675 != nil:
    section.add "X-Amz-Signature", valid_611675
  var valid_611676 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611676 = validateParameter(valid_611676, JString, required = false,
                                 default = nil)
  if valid_611676 != nil:
    section.add "X-Amz-Content-Sha256", valid_611676
  var valid_611677 = header.getOrDefault("X-Amz-Date")
  valid_611677 = validateParameter(valid_611677, JString, required = false,
                                 default = nil)
  if valid_611677 != nil:
    section.add "X-Amz-Date", valid_611677
  var valid_611678 = header.getOrDefault("X-Amz-Credential")
  valid_611678 = validateParameter(valid_611678, JString, required = false,
                                 default = nil)
  if valid_611678 != nil:
    section.add "X-Amz-Credential", valid_611678
  var valid_611679 = header.getOrDefault("X-Amz-Security-Token")
  valid_611679 = validateParameter(valid_611679, JString, required = false,
                                 default = nil)
  if valid_611679 != nil:
    section.add "X-Amz-Security-Token", valid_611679
  var valid_611680 = header.getOrDefault("X-Amz-Algorithm")
  valid_611680 = validateParameter(valid_611680, JString, required = false,
                                 default = nil)
  if valid_611680 != nil:
    section.add "X-Amz-Algorithm", valid_611680
  var valid_611681 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611681 = validateParameter(valid_611681, JString, required = false,
                                 default = nil)
  if valid_611681 != nil:
    section.add "X-Amz-SignedHeaders", valid_611681
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611682: Call_PostCreateStorageLocation_611670; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ## 
  let valid = call_611682.validator(path, query, header, formData, body)
  let scheme = call_611682.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611682.url(scheme.get, call_611682.host, call_611682.base,
                         call_611682.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611682, url, valid)

proc call*(call_611683: Call_PostCreateStorageLocation_611670;
          Action: string = "CreateStorageLocation"; Version: string = "2010-12-01"): Recallable =
  ## postCreateStorageLocation
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611684 = newJObject()
  add(query_611684, "Action", newJString(Action))
  add(query_611684, "Version", newJString(Version))
  result = call_611683.call(nil, query_611684, nil, nil, nil)

var postCreateStorageLocation* = Call_PostCreateStorageLocation_611670(
    name: "postCreateStorageLocation", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateStorageLocation",
    validator: validate_PostCreateStorageLocation_611671, base: "/",
    url: url_PostCreateStorageLocation_611672,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateStorageLocation_611655 = ref object of OpenApiRestCall_610659
proc url_GetCreateStorageLocation_611657(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateStorageLocation_611656(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611658 = query.getOrDefault("Action")
  valid_611658 = validateParameter(valid_611658, JString, required = true,
                                 default = newJString("CreateStorageLocation"))
  if valid_611658 != nil:
    section.add "Action", valid_611658
  var valid_611659 = query.getOrDefault("Version")
  valid_611659 = validateParameter(valid_611659, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_611659 != nil:
    section.add "Version", valid_611659
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611660 = header.getOrDefault("X-Amz-Signature")
  valid_611660 = validateParameter(valid_611660, JString, required = false,
                                 default = nil)
  if valid_611660 != nil:
    section.add "X-Amz-Signature", valid_611660
  var valid_611661 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611661 = validateParameter(valid_611661, JString, required = false,
                                 default = nil)
  if valid_611661 != nil:
    section.add "X-Amz-Content-Sha256", valid_611661
  var valid_611662 = header.getOrDefault("X-Amz-Date")
  valid_611662 = validateParameter(valid_611662, JString, required = false,
                                 default = nil)
  if valid_611662 != nil:
    section.add "X-Amz-Date", valid_611662
  var valid_611663 = header.getOrDefault("X-Amz-Credential")
  valid_611663 = validateParameter(valid_611663, JString, required = false,
                                 default = nil)
  if valid_611663 != nil:
    section.add "X-Amz-Credential", valid_611663
  var valid_611664 = header.getOrDefault("X-Amz-Security-Token")
  valid_611664 = validateParameter(valid_611664, JString, required = false,
                                 default = nil)
  if valid_611664 != nil:
    section.add "X-Amz-Security-Token", valid_611664
  var valid_611665 = header.getOrDefault("X-Amz-Algorithm")
  valid_611665 = validateParameter(valid_611665, JString, required = false,
                                 default = nil)
  if valid_611665 != nil:
    section.add "X-Amz-Algorithm", valid_611665
  var valid_611666 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611666 = validateParameter(valid_611666, JString, required = false,
                                 default = nil)
  if valid_611666 != nil:
    section.add "X-Amz-SignedHeaders", valid_611666
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611667: Call_GetCreateStorageLocation_611655; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ## 
  let valid = call_611667.validator(path, query, header, formData, body)
  let scheme = call_611667.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611667.url(scheme.get, call_611667.host, call_611667.base,
                         call_611667.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611667, url, valid)

proc call*(call_611668: Call_GetCreateStorageLocation_611655;
          Action: string = "CreateStorageLocation"; Version: string = "2010-12-01"): Recallable =
  ## getCreateStorageLocation
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611669 = newJObject()
  add(query_611669, "Action", newJString(Action))
  add(query_611669, "Version", newJString(Version))
  result = call_611668.call(nil, query_611669, nil, nil, nil)

var getCreateStorageLocation* = Call_GetCreateStorageLocation_611655(
    name: "getCreateStorageLocation", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateStorageLocation",
    validator: validate_GetCreateStorageLocation_611656, base: "/",
    url: url_GetCreateStorageLocation_611657, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteApplication_611702 = ref object of OpenApiRestCall_610659
proc url_PostDeleteApplication_611704(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteApplication_611703(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the specified application along with all associated versions and configurations. The application versions will not be deleted from your Amazon S3 bucket.</p> <note> <p>You cannot delete an application that has a running environment.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611705 = query.getOrDefault("Action")
  valid_611705 = validateParameter(valid_611705, JString, required = true,
                                 default = newJString("DeleteApplication"))
  if valid_611705 != nil:
    section.add "Action", valid_611705
  var valid_611706 = query.getOrDefault("Version")
  valid_611706 = validateParameter(valid_611706, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_611706 != nil:
    section.add "Version", valid_611706
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611707 = header.getOrDefault("X-Amz-Signature")
  valid_611707 = validateParameter(valid_611707, JString, required = false,
                                 default = nil)
  if valid_611707 != nil:
    section.add "X-Amz-Signature", valid_611707
  var valid_611708 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611708 = validateParameter(valid_611708, JString, required = false,
                                 default = nil)
  if valid_611708 != nil:
    section.add "X-Amz-Content-Sha256", valid_611708
  var valid_611709 = header.getOrDefault("X-Amz-Date")
  valid_611709 = validateParameter(valid_611709, JString, required = false,
                                 default = nil)
  if valid_611709 != nil:
    section.add "X-Amz-Date", valid_611709
  var valid_611710 = header.getOrDefault("X-Amz-Credential")
  valid_611710 = validateParameter(valid_611710, JString, required = false,
                                 default = nil)
  if valid_611710 != nil:
    section.add "X-Amz-Credential", valid_611710
  var valid_611711 = header.getOrDefault("X-Amz-Security-Token")
  valid_611711 = validateParameter(valid_611711, JString, required = false,
                                 default = nil)
  if valid_611711 != nil:
    section.add "X-Amz-Security-Token", valid_611711
  var valid_611712 = header.getOrDefault("X-Amz-Algorithm")
  valid_611712 = validateParameter(valid_611712, JString, required = false,
                                 default = nil)
  if valid_611712 != nil:
    section.add "X-Amz-Algorithm", valid_611712
  var valid_611713 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611713 = validateParameter(valid_611713, JString, required = false,
                                 default = nil)
  if valid_611713 != nil:
    section.add "X-Amz-SignedHeaders", valid_611713
  result.add "header", section
  ## parameters in `formData` object:
  ##   TerminateEnvByForce: JBool
  ##                      : When set to true, running environments will be terminated before deleting the application.
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to delete.
  section = newJObject()
  var valid_611714 = formData.getOrDefault("TerminateEnvByForce")
  valid_611714 = validateParameter(valid_611714, JBool, required = false, default = nil)
  if valid_611714 != nil:
    section.add "TerminateEnvByForce", valid_611714
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_611715 = formData.getOrDefault("ApplicationName")
  valid_611715 = validateParameter(valid_611715, JString, required = true,
                                 default = nil)
  if valid_611715 != nil:
    section.add "ApplicationName", valid_611715
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611716: Call_PostDeleteApplication_611702; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified application along with all associated versions and configurations. The application versions will not be deleted from your Amazon S3 bucket.</p> <note> <p>You cannot delete an application that has a running environment.</p> </note>
  ## 
  let valid = call_611716.validator(path, query, header, formData, body)
  let scheme = call_611716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611716.url(scheme.get, call_611716.host, call_611716.base,
                         call_611716.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611716, url, valid)

proc call*(call_611717: Call_PostDeleteApplication_611702; ApplicationName: string;
          TerminateEnvByForce: bool = false; Action: string = "DeleteApplication";
          Version: string = "2010-12-01"): Recallable =
  ## postDeleteApplication
  ## <p>Deletes the specified application along with all associated versions and configurations. The application versions will not be deleted from your Amazon S3 bucket.</p> <note> <p>You cannot delete an application that has a running environment.</p> </note>
  ##   TerminateEnvByForce: bool
  ##                      : When set to true, running environments will be terminated before deleting the application.
  ##   ApplicationName: string (required)
  ##                  : The name of the application to delete.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611718 = newJObject()
  var formData_611719 = newJObject()
  add(formData_611719, "TerminateEnvByForce", newJBool(TerminateEnvByForce))
  add(formData_611719, "ApplicationName", newJString(ApplicationName))
  add(query_611718, "Action", newJString(Action))
  add(query_611718, "Version", newJString(Version))
  result = call_611717.call(nil, query_611718, nil, formData_611719, nil)

var postDeleteApplication* = Call_PostDeleteApplication_611702(
    name: "postDeleteApplication", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=DeleteApplication",
    validator: validate_PostDeleteApplication_611703, base: "/",
    url: url_PostDeleteApplication_611704, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteApplication_611685 = ref object of OpenApiRestCall_610659
proc url_GetDeleteApplication_611687(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteApplication_611686(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the specified application along with all associated versions and configurations. The application versions will not be deleted from your Amazon S3 bucket.</p> <note> <p>You cannot delete an application that has a running environment.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to delete.
  ##   Action: JString (required)
  ##   TerminateEnvByForce: JBool
  ##                      : When set to true, running environments will be terminated before deleting the application.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_611688 = query.getOrDefault("ApplicationName")
  valid_611688 = validateParameter(valid_611688, JString, required = true,
                                 default = nil)
  if valid_611688 != nil:
    section.add "ApplicationName", valid_611688
  var valid_611689 = query.getOrDefault("Action")
  valid_611689 = validateParameter(valid_611689, JString, required = true,
                                 default = newJString("DeleteApplication"))
  if valid_611689 != nil:
    section.add "Action", valid_611689
  var valid_611690 = query.getOrDefault("TerminateEnvByForce")
  valid_611690 = validateParameter(valid_611690, JBool, required = false, default = nil)
  if valid_611690 != nil:
    section.add "TerminateEnvByForce", valid_611690
  var valid_611691 = query.getOrDefault("Version")
  valid_611691 = validateParameter(valid_611691, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_611691 != nil:
    section.add "Version", valid_611691
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611692 = header.getOrDefault("X-Amz-Signature")
  valid_611692 = validateParameter(valid_611692, JString, required = false,
                                 default = nil)
  if valid_611692 != nil:
    section.add "X-Amz-Signature", valid_611692
  var valid_611693 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611693 = validateParameter(valid_611693, JString, required = false,
                                 default = nil)
  if valid_611693 != nil:
    section.add "X-Amz-Content-Sha256", valid_611693
  var valid_611694 = header.getOrDefault("X-Amz-Date")
  valid_611694 = validateParameter(valid_611694, JString, required = false,
                                 default = nil)
  if valid_611694 != nil:
    section.add "X-Amz-Date", valid_611694
  var valid_611695 = header.getOrDefault("X-Amz-Credential")
  valid_611695 = validateParameter(valid_611695, JString, required = false,
                                 default = nil)
  if valid_611695 != nil:
    section.add "X-Amz-Credential", valid_611695
  var valid_611696 = header.getOrDefault("X-Amz-Security-Token")
  valid_611696 = validateParameter(valid_611696, JString, required = false,
                                 default = nil)
  if valid_611696 != nil:
    section.add "X-Amz-Security-Token", valid_611696
  var valid_611697 = header.getOrDefault("X-Amz-Algorithm")
  valid_611697 = validateParameter(valid_611697, JString, required = false,
                                 default = nil)
  if valid_611697 != nil:
    section.add "X-Amz-Algorithm", valid_611697
  var valid_611698 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611698 = validateParameter(valid_611698, JString, required = false,
                                 default = nil)
  if valid_611698 != nil:
    section.add "X-Amz-SignedHeaders", valid_611698
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611699: Call_GetDeleteApplication_611685; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified application along with all associated versions and configurations. The application versions will not be deleted from your Amazon S3 bucket.</p> <note> <p>You cannot delete an application that has a running environment.</p> </note>
  ## 
  let valid = call_611699.validator(path, query, header, formData, body)
  let scheme = call_611699.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611699.url(scheme.get, call_611699.host, call_611699.base,
                         call_611699.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611699, url, valid)

proc call*(call_611700: Call_GetDeleteApplication_611685; ApplicationName: string;
          Action: string = "DeleteApplication"; TerminateEnvByForce: bool = false;
          Version: string = "2010-12-01"): Recallable =
  ## getDeleteApplication
  ## <p>Deletes the specified application along with all associated versions and configurations. The application versions will not be deleted from your Amazon S3 bucket.</p> <note> <p>You cannot delete an application that has a running environment.</p> </note>
  ##   ApplicationName: string (required)
  ##                  : The name of the application to delete.
  ##   Action: string (required)
  ##   TerminateEnvByForce: bool
  ##                      : When set to true, running environments will be terminated before deleting the application.
  ##   Version: string (required)
  var query_611701 = newJObject()
  add(query_611701, "ApplicationName", newJString(ApplicationName))
  add(query_611701, "Action", newJString(Action))
  add(query_611701, "TerminateEnvByForce", newJBool(TerminateEnvByForce))
  add(query_611701, "Version", newJString(Version))
  result = call_611700.call(nil, query_611701, nil, nil, nil)

var getDeleteApplication* = Call_GetDeleteApplication_611685(
    name: "getDeleteApplication", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=DeleteApplication",
    validator: validate_GetDeleteApplication_611686, base: "/",
    url: url_GetDeleteApplication_611687, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteApplicationVersion_611738 = ref object of OpenApiRestCall_610659
proc url_PostDeleteApplicationVersion_611740(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteApplicationVersion_611739(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the specified version from the specified application.</p> <note> <p>You cannot delete an application version that is associated with a running environment.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611741 = query.getOrDefault("Action")
  valid_611741 = validateParameter(valid_611741, JString, required = true, default = newJString(
      "DeleteApplicationVersion"))
  if valid_611741 != nil:
    section.add "Action", valid_611741
  var valid_611742 = query.getOrDefault("Version")
  valid_611742 = validateParameter(valid_611742, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_611742 != nil:
    section.add "Version", valid_611742
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611743 = header.getOrDefault("X-Amz-Signature")
  valid_611743 = validateParameter(valid_611743, JString, required = false,
                                 default = nil)
  if valid_611743 != nil:
    section.add "X-Amz-Signature", valid_611743
  var valid_611744 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611744 = validateParameter(valid_611744, JString, required = false,
                                 default = nil)
  if valid_611744 != nil:
    section.add "X-Amz-Content-Sha256", valid_611744
  var valid_611745 = header.getOrDefault("X-Amz-Date")
  valid_611745 = validateParameter(valid_611745, JString, required = false,
                                 default = nil)
  if valid_611745 != nil:
    section.add "X-Amz-Date", valid_611745
  var valid_611746 = header.getOrDefault("X-Amz-Credential")
  valid_611746 = validateParameter(valid_611746, JString, required = false,
                                 default = nil)
  if valid_611746 != nil:
    section.add "X-Amz-Credential", valid_611746
  var valid_611747 = header.getOrDefault("X-Amz-Security-Token")
  valid_611747 = validateParameter(valid_611747, JString, required = false,
                                 default = nil)
  if valid_611747 != nil:
    section.add "X-Amz-Security-Token", valid_611747
  var valid_611748 = header.getOrDefault("X-Amz-Algorithm")
  valid_611748 = validateParameter(valid_611748, JString, required = false,
                                 default = nil)
  if valid_611748 != nil:
    section.add "X-Amz-Algorithm", valid_611748
  var valid_611749 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611749 = validateParameter(valid_611749, JString, required = false,
                                 default = nil)
  if valid_611749 != nil:
    section.add "X-Amz-SignedHeaders", valid_611749
  result.add "header", section
  ## parameters in `formData` object:
  ##   VersionLabel: JString (required)
  ##               : The label of the version to delete.
  ##   DeleteSourceBundle: JBool
  ##                     : Set to <code>true</code> to delete the source bundle from your storage bucket. Otherwise, the application version is deleted only from Elastic Beanstalk and the source bundle remains in Amazon S3.
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to which the version belongs.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `VersionLabel` field"
  var valid_611750 = formData.getOrDefault("VersionLabel")
  valid_611750 = validateParameter(valid_611750, JString, required = true,
                                 default = nil)
  if valid_611750 != nil:
    section.add "VersionLabel", valid_611750
  var valid_611751 = formData.getOrDefault("DeleteSourceBundle")
  valid_611751 = validateParameter(valid_611751, JBool, required = false, default = nil)
  if valid_611751 != nil:
    section.add "DeleteSourceBundle", valid_611751
  var valid_611752 = formData.getOrDefault("ApplicationName")
  valid_611752 = validateParameter(valid_611752, JString, required = true,
                                 default = nil)
  if valid_611752 != nil:
    section.add "ApplicationName", valid_611752
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611753: Call_PostDeleteApplicationVersion_611738; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified version from the specified application.</p> <note> <p>You cannot delete an application version that is associated with a running environment.</p> </note>
  ## 
  let valid = call_611753.validator(path, query, header, formData, body)
  let scheme = call_611753.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611753.url(scheme.get, call_611753.host, call_611753.base,
                         call_611753.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611753, url, valid)

proc call*(call_611754: Call_PostDeleteApplicationVersion_611738;
          VersionLabel: string; ApplicationName: string;
          DeleteSourceBundle: bool = false;
          Action: string = "DeleteApplicationVersion";
          Version: string = "2010-12-01"): Recallable =
  ## postDeleteApplicationVersion
  ## <p>Deletes the specified version from the specified application.</p> <note> <p>You cannot delete an application version that is associated with a running environment.</p> </note>
  ##   VersionLabel: string (required)
  ##               : The label of the version to delete.
  ##   DeleteSourceBundle: bool
  ##                     : Set to <code>true</code> to delete the source bundle from your storage bucket. Otherwise, the application version is deleted only from Elastic Beanstalk and the source bundle remains in Amazon S3.
  ##   ApplicationName: string (required)
  ##                  : The name of the application to which the version belongs.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611755 = newJObject()
  var formData_611756 = newJObject()
  add(formData_611756, "VersionLabel", newJString(VersionLabel))
  add(formData_611756, "DeleteSourceBundle", newJBool(DeleteSourceBundle))
  add(formData_611756, "ApplicationName", newJString(ApplicationName))
  add(query_611755, "Action", newJString(Action))
  add(query_611755, "Version", newJString(Version))
  result = call_611754.call(nil, query_611755, nil, formData_611756, nil)

var postDeleteApplicationVersion* = Call_PostDeleteApplicationVersion_611738(
    name: "postDeleteApplicationVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteApplicationVersion",
    validator: validate_PostDeleteApplicationVersion_611739, base: "/",
    url: url_PostDeleteApplicationVersion_611740,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteApplicationVersion_611720 = ref object of OpenApiRestCall_610659
proc url_GetDeleteApplicationVersion_611722(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteApplicationVersion_611721(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the specified version from the specified application.</p> <note> <p>You cannot delete an application version that is associated with a running environment.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to which the version belongs.
  ##   VersionLabel: JString (required)
  ##               : The label of the version to delete.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   DeleteSourceBundle: JBool
  ##                     : Set to <code>true</code> to delete the source bundle from your storage bucket. Otherwise, the application version is deleted only from Elastic Beanstalk and the source bundle remains in Amazon S3.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_611723 = query.getOrDefault("ApplicationName")
  valid_611723 = validateParameter(valid_611723, JString, required = true,
                                 default = nil)
  if valid_611723 != nil:
    section.add "ApplicationName", valid_611723
  var valid_611724 = query.getOrDefault("VersionLabel")
  valid_611724 = validateParameter(valid_611724, JString, required = true,
                                 default = nil)
  if valid_611724 != nil:
    section.add "VersionLabel", valid_611724
  var valid_611725 = query.getOrDefault("Action")
  valid_611725 = validateParameter(valid_611725, JString, required = true, default = newJString(
      "DeleteApplicationVersion"))
  if valid_611725 != nil:
    section.add "Action", valid_611725
  var valid_611726 = query.getOrDefault("Version")
  valid_611726 = validateParameter(valid_611726, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_611726 != nil:
    section.add "Version", valid_611726
  var valid_611727 = query.getOrDefault("DeleteSourceBundle")
  valid_611727 = validateParameter(valid_611727, JBool, required = false, default = nil)
  if valid_611727 != nil:
    section.add "DeleteSourceBundle", valid_611727
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611728 = header.getOrDefault("X-Amz-Signature")
  valid_611728 = validateParameter(valid_611728, JString, required = false,
                                 default = nil)
  if valid_611728 != nil:
    section.add "X-Amz-Signature", valid_611728
  var valid_611729 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611729 = validateParameter(valid_611729, JString, required = false,
                                 default = nil)
  if valid_611729 != nil:
    section.add "X-Amz-Content-Sha256", valid_611729
  var valid_611730 = header.getOrDefault("X-Amz-Date")
  valid_611730 = validateParameter(valid_611730, JString, required = false,
                                 default = nil)
  if valid_611730 != nil:
    section.add "X-Amz-Date", valid_611730
  var valid_611731 = header.getOrDefault("X-Amz-Credential")
  valid_611731 = validateParameter(valid_611731, JString, required = false,
                                 default = nil)
  if valid_611731 != nil:
    section.add "X-Amz-Credential", valid_611731
  var valid_611732 = header.getOrDefault("X-Amz-Security-Token")
  valid_611732 = validateParameter(valid_611732, JString, required = false,
                                 default = nil)
  if valid_611732 != nil:
    section.add "X-Amz-Security-Token", valid_611732
  var valid_611733 = header.getOrDefault("X-Amz-Algorithm")
  valid_611733 = validateParameter(valid_611733, JString, required = false,
                                 default = nil)
  if valid_611733 != nil:
    section.add "X-Amz-Algorithm", valid_611733
  var valid_611734 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611734 = validateParameter(valid_611734, JString, required = false,
                                 default = nil)
  if valid_611734 != nil:
    section.add "X-Amz-SignedHeaders", valid_611734
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611735: Call_GetDeleteApplicationVersion_611720; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified version from the specified application.</p> <note> <p>You cannot delete an application version that is associated with a running environment.</p> </note>
  ## 
  let valid = call_611735.validator(path, query, header, formData, body)
  let scheme = call_611735.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611735.url(scheme.get, call_611735.host, call_611735.base,
                         call_611735.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611735, url, valid)

proc call*(call_611736: Call_GetDeleteApplicationVersion_611720;
          ApplicationName: string; VersionLabel: string;
          Action: string = "DeleteApplicationVersion";
          Version: string = "2010-12-01"; DeleteSourceBundle: bool = false): Recallable =
  ## getDeleteApplicationVersion
  ## <p>Deletes the specified version from the specified application.</p> <note> <p>You cannot delete an application version that is associated with a running environment.</p> </note>
  ##   ApplicationName: string (required)
  ##                  : The name of the application to which the version belongs.
  ##   VersionLabel: string (required)
  ##               : The label of the version to delete.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DeleteSourceBundle: bool
  ##                     : Set to <code>true</code> to delete the source bundle from your storage bucket. Otherwise, the application version is deleted only from Elastic Beanstalk and the source bundle remains in Amazon S3.
  var query_611737 = newJObject()
  add(query_611737, "ApplicationName", newJString(ApplicationName))
  add(query_611737, "VersionLabel", newJString(VersionLabel))
  add(query_611737, "Action", newJString(Action))
  add(query_611737, "Version", newJString(Version))
  add(query_611737, "DeleteSourceBundle", newJBool(DeleteSourceBundle))
  result = call_611736.call(nil, query_611737, nil, nil, nil)

var getDeleteApplicationVersion* = Call_GetDeleteApplicationVersion_611720(
    name: "getDeleteApplicationVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteApplicationVersion",
    validator: validate_GetDeleteApplicationVersion_611721, base: "/",
    url: url_GetDeleteApplicationVersion_611722,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteConfigurationTemplate_611774 = ref object of OpenApiRestCall_610659
proc url_PostDeleteConfigurationTemplate_611776(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteConfigurationTemplate_611775(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the specified configuration template.</p> <note> <p>When you launch an environment using a configuration template, the environment gets a copy of the template. You can delete or modify the environment's copy of the template without affecting the running environment.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611777 = query.getOrDefault("Action")
  valid_611777 = validateParameter(valid_611777, JString, required = true, default = newJString(
      "DeleteConfigurationTemplate"))
  if valid_611777 != nil:
    section.add "Action", valid_611777
  var valid_611778 = query.getOrDefault("Version")
  valid_611778 = validateParameter(valid_611778, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_611778 != nil:
    section.add "Version", valid_611778
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611779 = header.getOrDefault("X-Amz-Signature")
  valid_611779 = validateParameter(valid_611779, JString, required = false,
                                 default = nil)
  if valid_611779 != nil:
    section.add "X-Amz-Signature", valid_611779
  var valid_611780 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611780 = validateParameter(valid_611780, JString, required = false,
                                 default = nil)
  if valid_611780 != nil:
    section.add "X-Amz-Content-Sha256", valid_611780
  var valid_611781 = header.getOrDefault("X-Amz-Date")
  valid_611781 = validateParameter(valid_611781, JString, required = false,
                                 default = nil)
  if valid_611781 != nil:
    section.add "X-Amz-Date", valid_611781
  var valid_611782 = header.getOrDefault("X-Amz-Credential")
  valid_611782 = validateParameter(valid_611782, JString, required = false,
                                 default = nil)
  if valid_611782 != nil:
    section.add "X-Amz-Credential", valid_611782
  var valid_611783 = header.getOrDefault("X-Amz-Security-Token")
  valid_611783 = validateParameter(valid_611783, JString, required = false,
                                 default = nil)
  if valid_611783 != nil:
    section.add "X-Amz-Security-Token", valid_611783
  var valid_611784 = header.getOrDefault("X-Amz-Algorithm")
  valid_611784 = validateParameter(valid_611784, JString, required = false,
                                 default = nil)
  if valid_611784 != nil:
    section.add "X-Amz-Algorithm", valid_611784
  var valid_611785 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611785 = validateParameter(valid_611785, JString, required = false,
                                 default = nil)
  if valid_611785 != nil:
    section.add "X-Amz-SignedHeaders", valid_611785
  result.add "header", section
  ## parameters in `formData` object:
  ##   TemplateName: JString (required)
  ##               : The name of the configuration template to delete.
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to delete the configuration template from.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TemplateName` field"
  var valid_611786 = formData.getOrDefault("TemplateName")
  valid_611786 = validateParameter(valid_611786, JString, required = true,
                                 default = nil)
  if valid_611786 != nil:
    section.add "TemplateName", valid_611786
  var valid_611787 = formData.getOrDefault("ApplicationName")
  valid_611787 = validateParameter(valid_611787, JString, required = true,
                                 default = nil)
  if valid_611787 != nil:
    section.add "ApplicationName", valid_611787
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611788: Call_PostDeleteConfigurationTemplate_611774;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes the specified configuration template.</p> <note> <p>When you launch an environment using a configuration template, the environment gets a copy of the template. You can delete or modify the environment's copy of the template without affecting the running environment.</p> </note>
  ## 
  let valid = call_611788.validator(path, query, header, formData, body)
  let scheme = call_611788.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611788.url(scheme.get, call_611788.host, call_611788.base,
                         call_611788.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611788, url, valid)

proc call*(call_611789: Call_PostDeleteConfigurationTemplate_611774;
          TemplateName: string; ApplicationName: string;
          Action: string = "DeleteConfigurationTemplate";
          Version: string = "2010-12-01"): Recallable =
  ## postDeleteConfigurationTemplate
  ## <p>Deletes the specified configuration template.</p> <note> <p>When you launch an environment using a configuration template, the environment gets a copy of the template. You can delete or modify the environment's copy of the template without affecting the running environment.</p> </note>
  ##   TemplateName: string (required)
  ##               : The name of the configuration template to delete.
  ##   ApplicationName: string (required)
  ##                  : The name of the application to delete the configuration template from.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611790 = newJObject()
  var formData_611791 = newJObject()
  add(formData_611791, "TemplateName", newJString(TemplateName))
  add(formData_611791, "ApplicationName", newJString(ApplicationName))
  add(query_611790, "Action", newJString(Action))
  add(query_611790, "Version", newJString(Version))
  result = call_611789.call(nil, query_611790, nil, formData_611791, nil)

var postDeleteConfigurationTemplate* = Call_PostDeleteConfigurationTemplate_611774(
    name: "postDeleteConfigurationTemplate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteConfigurationTemplate",
    validator: validate_PostDeleteConfigurationTemplate_611775, base: "/",
    url: url_PostDeleteConfigurationTemplate_611776,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteConfigurationTemplate_611757 = ref object of OpenApiRestCall_610659
proc url_GetDeleteConfigurationTemplate_611759(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteConfigurationTemplate_611758(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the specified configuration template.</p> <note> <p>When you launch an environment using a configuration template, the environment gets a copy of the template. You can delete or modify the environment's copy of the template without affecting the running environment.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to delete the configuration template from.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   TemplateName: JString (required)
  ##               : The name of the configuration template to delete.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_611760 = query.getOrDefault("ApplicationName")
  valid_611760 = validateParameter(valid_611760, JString, required = true,
                                 default = nil)
  if valid_611760 != nil:
    section.add "ApplicationName", valid_611760
  var valid_611761 = query.getOrDefault("Action")
  valid_611761 = validateParameter(valid_611761, JString, required = true, default = newJString(
      "DeleteConfigurationTemplate"))
  if valid_611761 != nil:
    section.add "Action", valid_611761
  var valid_611762 = query.getOrDefault("Version")
  valid_611762 = validateParameter(valid_611762, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_611762 != nil:
    section.add "Version", valid_611762
  var valid_611763 = query.getOrDefault("TemplateName")
  valid_611763 = validateParameter(valid_611763, JString, required = true,
                                 default = nil)
  if valid_611763 != nil:
    section.add "TemplateName", valid_611763
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611764 = header.getOrDefault("X-Amz-Signature")
  valid_611764 = validateParameter(valid_611764, JString, required = false,
                                 default = nil)
  if valid_611764 != nil:
    section.add "X-Amz-Signature", valid_611764
  var valid_611765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611765 = validateParameter(valid_611765, JString, required = false,
                                 default = nil)
  if valid_611765 != nil:
    section.add "X-Amz-Content-Sha256", valid_611765
  var valid_611766 = header.getOrDefault("X-Amz-Date")
  valid_611766 = validateParameter(valid_611766, JString, required = false,
                                 default = nil)
  if valid_611766 != nil:
    section.add "X-Amz-Date", valid_611766
  var valid_611767 = header.getOrDefault("X-Amz-Credential")
  valid_611767 = validateParameter(valid_611767, JString, required = false,
                                 default = nil)
  if valid_611767 != nil:
    section.add "X-Amz-Credential", valid_611767
  var valid_611768 = header.getOrDefault("X-Amz-Security-Token")
  valid_611768 = validateParameter(valid_611768, JString, required = false,
                                 default = nil)
  if valid_611768 != nil:
    section.add "X-Amz-Security-Token", valid_611768
  var valid_611769 = header.getOrDefault("X-Amz-Algorithm")
  valid_611769 = validateParameter(valid_611769, JString, required = false,
                                 default = nil)
  if valid_611769 != nil:
    section.add "X-Amz-Algorithm", valid_611769
  var valid_611770 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611770 = validateParameter(valid_611770, JString, required = false,
                                 default = nil)
  if valid_611770 != nil:
    section.add "X-Amz-SignedHeaders", valid_611770
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611771: Call_GetDeleteConfigurationTemplate_611757; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified configuration template.</p> <note> <p>When you launch an environment using a configuration template, the environment gets a copy of the template. You can delete or modify the environment's copy of the template without affecting the running environment.</p> </note>
  ## 
  let valid = call_611771.validator(path, query, header, formData, body)
  let scheme = call_611771.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611771.url(scheme.get, call_611771.host, call_611771.base,
                         call_611771.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611771, url, valid)

proc call*(call_611772: Call_GetDeleteConfigurationTemplate_611757;
          ApplicationName: string; TemplateName: string;
          Action: string = "DeleteConfigurationTemplate";
          Version: string = "2010-12-01"): Recallable =
  ## getDeleteConfigurationTemplate
  ## <p>Deletes the specified configuration template.</p> <note> <p>When you launch an environment using a configuration template, the environment gets a copy of the template. You can delete or modify the environment's copy of the template without affecting the running environment.</p> </note>
  ##   ApplicationName: string (required)
  ##                  : The name of the application to delete the configuration template from.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   TemplateName: string (required)
  ##               : The name of the configuration template to delete.
  var query_611773 = newJObject()
  add(query_611773, "ApplicationName", newJString(ApplicationName))
  add(query_611773, "Action", newJString(Action))
  add(query_611773, "Version", newJString(Version))
  add(query_611773, "TemplateName", newJString(TemplateName))
  result = call_611772.call(nil, query_611773, nil, nil, nil)

var getDeleteConfigurationTemplate* = Call_GetDeleteConfigurationTemplate_611757(
    name: "getDeleteConfigurationTemplate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteConfigurationTemplate",
    validator: validate_GetDeleteConfigurationTemplate_611758, base: "/",
    url: url_GetDeleteConfigurationTemplate_611759,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEnvironmentConfiguration_611809 = ref object of OpenApiRestCall_610659
proc url_PostDeleteEnvironmentConfiguration_611811(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteEnvironmentConfiguration_611810(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the draft configuration associated with the running environment.</p> <p>Updating a running environment with any configuration changes creates a draft configuration set. You can get the draft configuration using <a>DescribeConfigurationSettings</a> while the update is in progress or if the update fails. The <code>DeploymentStatus</code> for the draft configuration indicates whether the deployment is in process or has failed. The draft configuration remains in existence until it is deleted with this action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611812 = query.getOrDefault("Action")
  valid_611812 = validateParameter(valid_611812, JString, required = true, default = newJString(
      "DeleteEnvironmentConfiguration"))
  if valid_611812 != nil:
    section.add "Action", valid_611812
  var valid_611813 = query.getOrDefault("Version")
  valid_611813 = validateParameter(valid_611813, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_611813 != nil:
    section.add "Version", valid_611813
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611814 = header.getOrDefault("X-Amz-Signature")
  valid_611814 = validateParameter(valid_611814, JString, required = false,
                                 default = nil)
  if valid_611814 != nil:
    section.add "X-Amz-Signature", valid_611814
  var valid_611815 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611815 = validateParameter(valid_611815, JString, required = false,
                                 default = nil)
  if valid_611815 != nil:
    section.add "X-Amz-Content-Sha256", valid_611815
  var valid_611816 = header.getOrDefault("X-Amz-Date")
  valid_611816 = validateParameter(valid_611816, JString, required = false,
                                 default = nil)
  if valid_611816 != nil:
    section.add "X-Amz-Date", valid_611816
  var valid_611817 = header.getOrDefault("X-Amz-Credential")
  valid_611817 = validateParameter(valid_611817, JString, required = false,
                                 default = nil)
  if valid_611817 != nil:
    section.add "X-Amz-Credential", valid_611817
  var valid_611818 = header.getOrDefault("X-Amz-Security-Token")
  valid_611818 = validateParameter(valid_611818, JString, required = false,
                                 default = nil)
  if valid_611818 != nil:
    section.add "X-Amz-Security-Token", valid_611818
  var valid_611819 = header.getOrDefault("X-Amz-Algorithm")
  valid_611819 = validateParameter(valid_611819, JString, required = false,
                                 default = nil)
  if valid_611819 != nil:
    section.add "X-Amz-Algorithm", valid_611819
  var valid_611820 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611820 = validateParameter(valid_611820, JString, required = false,
                                 default = nil)
  if valid_611820 != nil:
    section.add "X-Amz-SignedHeaders", valid_611820
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString (required)
  ##                  : The name of the environment to delete the draft configuration from.
  ##   ApplicationName: JString (required)
  ##                  : The name of the application the environment is associated with.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `EnvironmentName` field"
  var valid_611821 = formData.getOrDefault("EnvironmentName")
  valid_611821 = validateParameter(valid_611821, JString, required = true,
                                 default = nil)
  if valid_611821 != nil:
    section.add "EnvironmentName", valid_611821
  var valid_611822 = formData.getOrDefault("ApplicationName")
  valid_611822 = validateParameter(valid_611822, JString, required = true,
                                 default = nil)
  if valid_611822 != nil:
    section.add "ApplicationName", valid_611822
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611823: Call_PostDeleteEnvironmentConfiguration_611809;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes the draft configuration associated with the running environment.</p> <p>Updating a running environment with any configuration changes creates a draft configuration set. You can get the draft configuration using <a>DescribeConfigurationSettings</a> while the update is in progress or if the update fails. The <code>DeploymentStatus</code> for the draft configuration indicates whether the deployment is in process or has failed. The draft configuration remains in existence until it is deleted with this action.</p>
  ## 
  let valid = call_611823.validator(path, query, header, formData, body)
  let scheme = call_611823.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611823.url(scheme.get, call_611823.host, call_611823.base,
                         call_611823.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611823, url, valid)

proc call*(call_611824: Call_PostDeleteEnvironmentConfiguration_611809;
          EnvironmentName: string; ApplicationName: string;
          Action: string = "DeleteEnvironmentConfiguration";
          Version: string = "2010-12-01"): Recallable =
  ## postDeleteEnvironmentConfiguration
  ## <p>Deletes the draft configuration associated with the running environment.</p> <p>Updating a running environment with any configuration changes creates a draft configuration set. You can get the draft configuration using <a>DescribeConfigurationSettings</a> while the update is in progress or if the update fails. The <code>DeploymentStatus</code> for the draft configuration indicates whether the deployment is in process or has failed. The draft configuration remains in existence until it is deleted with this action.</p>
  ##   EnvironmentName: string (required)
  ##                  : The name of the environment to delete the draft configuration from.
  ##   ApplicationName: string (required)
  ##                  : The name of the application the environment is associated with.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611825 = newJObject()
  var formData_611826 = newJObject()
  add(formData_611826, "EnvironmentName", newJString(EnvironmentName))
  add(formData_611826, "ApplicationName", newJString(ApplicationName))
  add(query_611825, "Action", newJString(Action))
  add(query_611825, "Version", newJString(Version))
  result = call_611824.call(nil, query_611825, nil, formData_611826, nil)

var postDeleteEnvironmentConfiguration* = Call_PostDeleteEnvironmentConfiguration_611809(
    name: "postDeleteEnvironmentConfiguration", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteEnvironmentConfiguration",
    validator: validate_PostDeleteEnvironmentConfiguration_611810, base: "/",
    url: url_PostDeleteEnvironmentConfiguration_611811,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEnvironmentConfiguration_611792 = ref object of OpenApiRestCall_610659
proc url_GetDeleteEnvironmentConfiguration_611794(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteEnvironmentConfiguration_611793(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the draft configuration associated with the running environment.</p> <p>Updating a running environment with any configuration changes creates a draft configuration set. You can get the draft configuration using <a>DescribeConfigurationSettings</a> while the update is in progress or if the update fails. The <code>DeploymentStatus</code> for the draft configuration indicates whether the deployment is in process or has failed. The draft configuration remains in existence until it is deleted with this action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ApplicationName: JString (required)
  ##                  : The name of the application the environment is associated with.
  ##   EnvironmentName: JString (required)
  ##                  : The name of the environment to delete the draft configuration from.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_611795 = query.getOrDefault("ApplicationName")
  valid_611795 = validateParameter(valid_611795, JString, required = true,
                                 default = nil)
  if valid_611795 != nil:
    section.add "ApplicationName", valid_611795
  var valid_611796 = query.getOrDefault("EnvironmentName")
  valid_611796 = validateParameter(valid_611796, JString, required = true,
                                 default = nil)
  if valid_611796 != nil:
    section.add "EnvironmentName", valid_611796
  var valid_611797 = query.getOrDefault("Action")
  valid_611797 = validateParameter(valid_611797, JString, required = true, default = newJString(
      "DeleteEnvironmentConfiguration"))
  if valid_611797 != nil:
    section.add "Action", valid_611797
  var valid_611798 = query.getOrDefault("Version")
  valid_611798 = validateParameter(valid_611798, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_611798 != nil:
    section.add "Version", valid_611798
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611799 = header.getOrDefault("X-Amz-Signature")
  valid_611799 = validateParameter(valid_611799, JString, required = false,
                                 default = nil)
  if valid_611799 != nil:
    section.add "X-Amz-Signature", valid_611799
  var valid_611800 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611800 = validateParameter(valid_611800, JString, required = false,
                                 default = nil)
  if valid_611800 != nil:
    section.add "X-Amz-Content-Sha256", valid_611800
  var valid_611801 = header.getOrDefault("X-Amz-Date")
  valid_611801 = validateParameter(valid_611801, JString, required = false,
                                 default = nil)
  if valid_611801 != nil:
    section.add "X-Amz-Date", valid_611801
  var valid_611802 = header.getOrDefault("X-Amz-Credential")
  valid_611802 = validateParameter(valid_611802, JString, required = false,
                                 default = nil)
  if valid_611802 != nil:
    section.add "X-Amz-Credential", valid_611802
  var valid_611803 = header.getOrDefault("X-Amz-Security-Token")
  valid_611803 = validateParameter(valid_611803, JString, required = false,
                                 default = nil)
  if valid_611803 != nil:
    section.add "X-Amz-Security-Token", valid_611803
  var valid_611804 = header.getOrDefault("X-Amz-Algorithm")
  valid_611804 = validateParameter(valid_611804, JString, required = false,
                                 default = nil)
  if valid_611804 != nil:
    section.add "X-Amz-Algorithm", valid_611804
  var valid_611805 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611805 = validateParameter(valid_611805, JString, required = false,
                                 default = nil)
  if valid_611805 != nil:
    section.add "X-Amz-SignedHeaders", valid_611805
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611806: Call_GetDeleteEnvironmentConfiguration_611792;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes the draft configuration associated with the running environment.</p> <p>Updating a running environment with any configuration changes creates a draft configuration set. You can get the draft configuration using <a>DescribeConfigurationSettings</a> while the update is in progress or if the update fails. The <code>DeploymentStatus</code> for the draft configuration indicates whether the deployment is in process or has failed. The draft configuration remains in existence until it is deleted with this action.</p>
  ## 
  let valid = call_611806.validator(path, query, header, formData, body)
  let scheme = call_611806.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611806.url(scheme.get, call_611806.host, call_611806.base,
                         call_611806.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611806, url, valid)

proc call*(call_611807: Call_GetDeleteEnvironmentConfiguration_611792;
          ApplicationName: string; EnvironmentName: string;
          Action: string = "DeleteEnvironmentConfiguration";
          Version: string = "2010-12-01"): Recallable =
  ## getDeleteEnvironmentConfiguration
  ## <p>Deletes the draft configuration associated with the running environment.</p> <p>Updating a running environment with any configuration changes creates a draft configuration set. You can get the draft configuration using <a>DescribeConfigurationSettings</a> while the update is in progress or if the update fails. The <code>DeploymentStatus</code> for the draft configuration indicates whether the deployment is in process or has failed. The draft configuration remains in existence until it is deleted with this action.</p>
  ##   ApplicationName: string (required)
  ##                  : The name of the application the environment is associated with.
  ##   EnvironmentName: string (required)
  ##                  : The name of the environment to delete the draft configuration from.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611808 = newJObject()
  add(query_611808, "ApplicationName", newJString(ApplicationName))
  add(query_611808, "EnvironmentName", newJString(EnvironmentName))
  add(query_611808, "Action", newJString(Action))
  add(query_611808, "Version", newJString(Version))
  result = call_611807.call(nil, query_611808, nil, nil, nil)

var getDeleteEnvironmentConfiguration* = Call_GetDeleteEnvironmentConfiguration_611792(
    name: "getDeleteEnvironmentConfiguration", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteEnvironmentConfiguration",
    validator: validate_GetDeleteEnvironmentConfiguration_611793, base: "/",
    url: url_GetDeleteEnvironmentConfiguration_611794,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeletePlatformVersion_611843 = ref object of OpenApiRestCall_610659
proc url_PostDeletePlatformVersion_611845(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeletePlatformVersion_611844(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the specified version of a custom platform.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611846 = query.getOrDefault("Action")
  valid_611846 = validateParameter(valid_611846, JString, required = true,
                                 default = newJString("DeletePlatformVersion"))
  if valid_611846 != nil:
    section.add "Action", valid_611846
  var valid_611847 = query.getOrDefault("Version")
  valid_611847 = validateParameter(valid_611847, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_611847 != nil:
    section.add "Version", valid_611847
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611848 = header.getOrDefault("X-Amz-Signature")
  valid_611848 = validateParameter(valid_611848, JString, required = false,
                                 default = nil)
  if valid_611848 != nil:
    section.add "X-Amz-Signature", valid_611848
  var valid_611849 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611849 = validateParameter(valid_611849, JString, required = false,
                                 default = nil)
  if valid_611849 != nil:
    section.add "X-Amz-Content-Sha256", valid_611849
  var valid_611850 = header.getOrDefault("X-Amz-Date")
  valid_611850 = validateParameter(valid_611850, JString, required = false,
                                 default = nil)
  if valid_611850 != nil:
    section.add "X-Amz-Date", valid_611850
  var valid_611851 = header.getOrDefault("X-Amz-Credential")
  valid_611851 = validateParameter(valid_611851, JString, required = false,
                                 default = nil)
  if valid_611851 != nil:
    section.add "X-Amz-Credential", valid_611851
  var valid_611852 = header.getOrDefault("X-Amz-Security-Token")
  valid_611852 = validateParameter(valid_611852, JString, required = false,
                                 default = nil)
  if valid_611852 != nil:
    section.add "X-Amz-Security-Token", valid_611852
  var valid_611853 = header.getOrDefault("X-Amz-Algorithm")
  valid_611853 = validateParameter(valid_611853, JString, required = false,
                                 default = nil)
  if valid_611853 != nil:
    section.add "X-Amz-Algorithm", valid_611853
  var valid_611854 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611854 = validateParameter(valid_611854, JString, required = false,
                                 default = nil)
  if valid_611854 != nil:
    section.add "X-Amz-SignedHeaders", valid_611854
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformArn: JString
  ##              : The ARN of the version of the custom platform.
  section = newJObject()
  var valid_611855 = formData.getOrDefault("PlatformArn")
  valid_611855 = validateParameter(valid_611855, JString, required = false,
                                 default = nil)
  if valid_611855 != nil:
    section.add "PlatformArn", valid_611855
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611856: Call_PostDeletePlatformVersion_611843; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified version of a custom platform.
  ## 
  let valid = call_611856.validator(path, query, header, formData, body)
  let scheme = call_611856.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611856.url(scheme.get, call_611856.host, call_611856.base,
                         call_611856.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611856, url, valid)

proc call*(call_611857: Call_PostDeletePlatformVersion_611843;
          Action: string = "DeletePlatformVersion"; Version: string = "2010-12-01";
          PlatformArn: string = ""): Recallable =
  ## postDeletePlatformVersion
  ## Deletes the specified version of a custom platform.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PlatformArn: string
  ##              : The ARN of the version of the custom platform.
  var query_611858 = newJObject()
  var formData_611859 = newJObject()
  add(query_611858, "Action", newJString(Action))
  add(query_611858, "Version", newJString(Version))
  add(formData_611859, "PlatformArn", newJString(PlatformArn))
  result = call_611857.call(nil, query_611858, nil, formData_611859, nil)

var postDeletePlatformVersion* = Call_PostDeletePlatformVersion_611843(
    name: "postDeletePlatformVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeletePlatformVersion",
    validator: validate_PostDeletePlatformVersion_611844, base: "/",
    url: url_PostDeletePlatformVersion_611845,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeletePlatformVersion_611827 = ref object of OpenApiRestCall_610659
proc url_GetDeletePlatformVersion_611829(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeletePlatformVersion_611828(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the specified version of a custom platform.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   PlatformArn: JString
  ##              : The ARN of the version of the custom platform.
  ##   Version: JString (required)
  section = newJObject()
  var valid_611830 = query.getOrDefault("Action")
  valid_611830 = validateParameter(valid_611830, JString, required = true,
                                 default = newJString("DeletePlatformVersion"))
  if valid_611830 != nil:
    section.add "Action", valid_611830
  var valid_611831 = query.getOrDefault("PlatformArn")
  valid_611831 = validateParameter(valid_611831, JString, required = false,
                                 default = nil)
  if valid_611831 != nil:
    section.add "PlatformArn", valid_611831
  var valid_611832 = query.getOrDefault("Version")
  valid_611832 = validateParameter(valid_611832, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_611832 != nil:
    section.add "Version", valid_611832
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611833 = header.getOrDefault("X-Amz-Signature")
  valid_611833 = validateParameter(valid_611833, JString, required = false,
                                 default = nil)
  if valid_611833 != nil:
    section.add "X-Amz-Signature", valid_611833
  var valid_611834 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611834 = validateParameter(valid_611834, JString, required = false,
                                 default = nil)
  if valid_611834 != nil:
    section.add "X-Amz-Content-Sha256", valid_611834
  var valid_611835 = header.getOrDefault("X-Amz-Date")
  valid_611835 = validateParameter(valid_611835, JString, required = false,
                                 default = nil)
  if valid_611835 != nil:
    section.add "X-Amz-Date", valid_611835
  var valid_611836 = header.getOrDefault("X-Amz-Credential")
  valid_611836 = validateParameter(valid_611836, JString, required = false,
                                 default = nil)
  if valid_611836 != nil:
    section.add "X-Amz-Credential", valid_611836
  var valid_611837 = header.getOrDefault("X-Amz-Security-Token")
  valid_611837 = validateParameter(valid_611837, JString, required = false,
                                 default = nil)
  if valid_611837 != nil:
    section.add "X-Amz-Security-Token", valid_611837
  var valid_611838 = header.getOrDefault("X-Amz-Algorithm")
  valid_611838 = validateParameter(valid_611838, JString, required = false,
                                 default = nil)
  if valid_611838 != nil:
    section.add "X-Amz-Algorithm", valid_611838
  var valid_611839 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611839 = validateParameter(valid_611839, JString, required = false,
                                 default = nil)
  if valid_611839 != nil:
    section.add "X-Amz-SignedHeaders", valid_611839
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611840: Call_GetDeletePlatformVersion_611827; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified version of a custom platform.
  ## 
  let valid = call_611840.validator(path, query, header, formData, body)
  let scheme = call_611840.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611840.url(scheme.get, call_611840.host, call_611840.base,
                         call_611840.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611840, url, valid)

proc call*(call_611841: Call_GetDeletePlatformVersion_611827;
          Action: string = "DeletePlatformVersion"; PlatformArn: string = "";
          Version: string = "2010-12-01"): Recallable =
  ## getDeletePlatformVersion
  ## Deletes the specified version of a custom platform.
  ##   Action: string (required)
  ##   PlatformArn: string
  ##              : The ARN of the version of the custom platform.
  ##   Version: string (required)
  var query_611842 = newJObject()
  add(query_611842, "Action", newJString(Action))
  add(query_611842, "PlatformArn", newJString(PlatformArn))
  add(query_611842, "Version", newJString(Version))
  result = call_611841.call(nil, query_611842, nil, nil, nil)

var getDeletePlatformVersion* = Call_GetDeletePlatformVersion_611827(
    name: "getDeletePlatformVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeletePlatformVersion",
    validator: validate_GetDeletePlatformVersion_611828, base: "/",
    url: url_GetDeletePlatformVersion_611829, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAccountAttributes_611875 = ref object of OpenApiRestCall_610659
proc url_PostDescribeAccountAttributes_611877(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeAccountAttributes_611876(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611878 = query.getOrDefault("Action")
  valid_611878 = validateParameter(valid_611878, JString, required = true, default = newJString(
      "DescribeAccountAttributes"))
  if valid_611878 != nil:
    section.add "Action", valid_611878
  var valid_611879 = query.getOrDefault("Version")
  valid_611879 = validateParameter(valid_611879, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_611879 != nil:
    section.add "Version", valid_611879
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611880 = header.getOrDefault("X-Amz-Signature")
  valid_611880 = validateParameter(valid_611880, JString, required = false,
                                 default = nil)
  if valid_611880 != nil:
    section.add "X-Amz-Signature", valid_611880
  var valid_611881 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611881 = validateParameter(valid_611881, JString, required = false,
                                 default = nil)
  if valid_611881 != nil:
    section.add "X-Amz-Content-Sha256", valid_611881
  var valid_611882 = header.getOrDefault("X-Amz-Date")
  valid_611882 = validateParameter(valid_611882, JString, required = false,
                                 default = nil)
  if valid_611882 != nil:
    section.add "X-Amz-Date", valid_611882
  var valid_611883 = header.getOrDefault("X-Amz-Credential")
  valid_611883 = validateParameter(valid_611883, JString, required = false,
                                 default = nil)
  if valid_611883 != nil:
    section.add "X-Amz-Credential", valid_611883
  var valid_611884 = header.getOrDefault("X-Amz-Security-Token")
  valid_611884 = validateParameter(valid_611884, JString, required = false,
                                 default = nil)
  if valid_611884 != nil:
    section.add "X-Amz-Security-Token", valid_611884
  var valid_611885 = header.getOrDefault("X-Amz-Algorithm")
  valid_611885 = validateParameter(valid_611885, JString, required = false,
                                 default = nil)
  if valid_611885 != nil:
    section.add "X-Amz-Algorithm", valid_611885
  var valid_611886 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611886 = validateParameter(valid_611886, JString, required = false,
                                 default = nil)
  if valid_611886 != nil:
    section.add "X-Amz-SignedHeaders", valid_611886
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611887: Call_PostDescribeAccountAttributes_611875; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ## 
  let valid = call_611887.validator(path, query, header, formData, body)
  let scheme = call_611887.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611887.url(scheme.get, call_611887.host, call_611887.base,
                         call_611887.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611887, url, valid)

proc call*(call_611888: Call_PostDescribeAccountAttributes_611875;
          Action: string = "DescribeAccountAttributes";
          Version: string = "2010-12-01"): Recallable =
  ## postDescribeAccountAttributes
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611889 = newJObject()
  add(query_611889, "Action", newJString(Action))
  add(query_611889, "Version", newJString(Version))
  result = call_611888.call(nil, query_611889, nil, nil, nil)

var postDescribeAccountAttributes* = Call_PostDescribeAccountAttributes_611875(
    name: "postDescribeAccountAttributes", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeAccountAttributes",
    validator: validate_PostDescribeAccountAttributes_611876, base: "/",
    url: url_PostDescribeAccountAttributes_611877,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAccountAttributes_611860 = ref object of OpenApiRestCall_610659
proc url_GetDescribeAccountAttributes_611862(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeAccountAttributes_611861(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611863 = query.getOrDefault("Action")
  valid_611863 = validateParameter(valid_611863, JString, required = true, default = newJString(
      "DescribeAccountAttributes"))
  if valid_611863 != nil:
    section.add "Action", valid_611863
  var valid_611864 = query.getOrDefault("Version")
  valid_611864 = validateParameter(valid_611864, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_611864 != nil:
    section.add "Version", valid_611864
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611865 = header.getOrDefault("X-Amz-Signature")
  valid_611865 = validateParameter(valid_611865, JString, required = false,
                                 default = nil)
  if valid_611865 != nil:
    section.add "X-Amz-Signature", valid_611865
  var valid_611866 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611866 = validateParameter(valid_611866, JString, required = false,
                                 default = nil)
  if valid_611866 != nil:
    section.add "X-Amz-Content-Sha256", valid_611866
  var valid_611867 = header.getOrDefault("X-Amz-Date")
  valid_611867 = validateParameter(valid_611867, JString, required = false,
                                 default = nil)
  if valid_611867 != nil:
    section.add "X-Amz-Date", valid_611867
  var valid_611868 = header.getOrDefault("X-Amz-Credential")
  valid_611868 = validateParameter(valid_611868, JString, required = false,
                                 default = nil)
  if valid_611868 != nil:
    section.add "X-Amz-Credential", valid_611868
  var valid_611869 = header.getOrDefault("X-Amz-Security-Token")
  valid_611869 = validateParameter(valid_611869, JString, required = false,
                                 default = nil)
  if valid_611869 != nil:
    section.add "X-Amz-Security-Token", valid_611869
  var valid_611870 = header.getOrDefault("X-Amz-Algorithm")
  valid_611870 = validateParameter(valid_611870, JString, required = false,
                                 default = nil)
  if valid_611870 != nil:
    section.add "X-Amz-Algorithm", valid_611870
  var valid_611871 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611871 = validateParameter(valid_611871, JString, required = false,
                                 default = nil)
  if valid_611871 != nil:
    section.add "X-Amz-SignedHeaders", valid_611871
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611872: Call_GetDescribeAccountAttributes_611860; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ## 
  let valid = call_611872.validator(path, query, header, formData, body)
  let scheme = call_611872.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611872.url(scheme.get, call_611872.host, call_611872.base,
                         call_611872.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611872, url, valid)

proc call*(call_611873: Call_GetDescribeAccountAttributes_611860;
          Action: string = "DescribeAccountAttributes";
          Version: string = "2010-12-01"): Recallable =
  ## getDescribeAccountAttributes
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611874 = newJObject()
  add(query_611874, "Action", newJString(Action))
  add(query_611874, "Version", newJString(Version))
  result = call_611873.call(nil, query_611874, nil, nil, nil)

var getDescribeAccountAttributes* = Call_GetDescribeAccountAttributes_611860(
    name: "getDescribeAccountAttributes", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeAccountAttributes",
    validator: validate_GetDescribeAccountAttributes_611861, base: "/",
    url: url_GetDescribeAccountAttributes_611862,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeApplicationVersions_611909 = ref object of OpenApiRestCall_610659
proc url_PostDescribeApplicationVersions_611911(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeApplicationVersions_611910(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieve a list of application versions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611912 = query.getOrDefault("Action")
  valid_611912 = validateParameter(valid_611912, JString, required = true, default = newJString(
      "DescribeApplicationVersions"))
  if valid_611912 != nil:
    section.add "Action", valid_611912
  var valid_611913 = query.getOrDefault("Version")
  valid_611913 = validateParameter(valid_611913, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_611913 != nil:
    section.add "Version", valid_611913
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611914 = header.getOrDefault("X-Amz-Signature")
  valid_611914 = validateParameter(valid_611914, JString, required = false,
                                 default = nil)
  if valid_611914 != nil:
    section.add "X-Amz-Signature", valid_611914
  var valid_611915 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611915 = validateParameter(valid_611915, JString, required = false,
                                 default = nil)
  if valid_611915 != nil:
    section.add "X-Amz-Content-Sha256", valid_611915
  var valid_611916 = header.getOrDefault("X-Amz-Date")
  valid_611916 = validateParameter(valid_611916, JString, required = false,
                                 default = nil)
  if valid_611916 != nil:
    section.add "X-Amz-Date", valid_611916
  var valid_611917 = header.getOrDefault("X-Amz-Credential")
  valid_611917 = validateParameter(valid_611917, JString, required = false,
                                 default = nil)
  if valid_611917 != nil:
    section.add "X-Amz-Credential", valid_611917
  var valid_611918 = header.getOrDefault("X-Amz-Security-Token")
  valid_611918 = validateParameter(valid_611918, JString, required = false,
                                 default = nil)
  if valid_611918 != nil:
    section.add "X-Amz-Security-Token", valid_611918
  var valid_611919 = header.getOrDefault("X-Amz-Algorithm")
  valid_611919 = validateParameter(valid_611919, JString, required = false,
                                 default = nil)
  if valid_611919 != nil:
    section.add "X-Amz-Algorithm", valid_611919
  var valid_611920 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611920 = validateParameter(valid_611920, JString, required = false,
                                 default = nil)
  if valid_611920 != nil:
    section.add "X-Amz-SignedHeaders", valid_611920
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : <p>For a paginated request. Specify a token from a previous response page to retrieve the next response page. All other parameter values must be identical to the ones specified in the initial request.</p> <p>If no <code>NextToken</code> is specified, the first page is retrieved.</p>
  ##   MaxRecords: JInt
  ##             : <p>For a paginated request. Specify a maximum number of application versions to include in each response.</p> <p>If no <code>MaxRecords</code> is specified, all available application versions are retrieved in a single response.</p>
  ##   VersionLabels: JArray
  ##                : Specify a version label to show a specific application version.
  ##   ApplicationName: JString
  ##                  : Specify an application name to show only application versions for that application.
  section = newJObject()
  var valid_611921 = formData.getOrDefault("NextToken")
  valid_611921 = validateParameter(valid_611921, JString, required = false,
                                 default = nil)
  if valid_611921 != nil:
    section.add "NextToken", valid_611921
  var valid_611922 = formData.getOrDefault("MaxRecords")
  valid_611922 = validateParameter(valid_611922, JInt, required = false, default = nil)
  if valid_611922 != nil:
    section.add "MaxRecords", valid_611922
  var valid_611923 = formData.getOrDefault("VersionLabels")
  valid_611923 = validateParameter(valid_611923, JArray, required = false,
                                 default = nil)
  if valid_611923 != nil:
    section.add "VersionLabels", valid_611923
  var valid_611924 = formData.getOrDefault("ApplicationName")
  valid_611924 = validateParameter(valid_611924, JString, required = false,
                                 default = nil)
  if valid_611924 != nil:
    section.add "ApplicationName", valid_611924
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611925: Call_PostDescribeApplicationVersions_611909;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieve a list of application versions.
  ## 
  let valid = call_611925.validator(path, query, header, formData, body)
  let scheme = call_611925.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611925.url(scheme.get, call_611925.host, call_611925.base,
                         call_611925.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611925, url, valid)

proc call*(call_611926: Call_PostDescribeApplicationVersions_611909;
          NextToken: string = ""; MaxRecords: int = 0; VersionLabels: JsonNode = nil;
          ApplicationName: string = "";
          Action: string = "DescribeApplicationVersions";
          Version: string = "2010-12-01"): Recallable =
  ## postDescribeApplicationVersions
  ## Retrieve a list of application versions.
  ##   NextToken: string
  ##            : <p>For a paginated request. Specify a token from a previous response page to retrieve the next response page. All other parameter values must be identical to the ones specified in the initial request.</p> <p>If no <code>NextToken</code> is specified, the first page is retrieved.</p>
  ##   MaxRecords: int
  ##             : <p>For a paginated request. Specify a maximum number of application versions to include in each response.</p> <p>If no <code>MaxRecords</code> is specified, all available application versions are retrieved in a single response.</p>
  ##   VersionLabels: JArray
  ##                : Specify a version label to show a specific application version.
  ##   ApplicationName: string
  ##                  : Specify an application name to show only application versions for that application.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611927 = newJObject()
  var formData_611928 = newJObject()
  add(formData_611928, "NextToken", newJString(NextToken))
  add(formData_611928, "MaxRecords", newJInt(MaxRecords))
  if VersionLabels != nil:
    formData_611928.add "VersionLabels", VersionLabels
  add(formData_611928, "ApplicationName", newJString(ApplicationName))
  add(query_611927, "Action", newJString(Action))
  add(query_611927, "Version", newJString(Version))
  result = call_611926.call(nil, query_611927, nil, formData_611928, nil)

var postDescribeApplicationVersions* = Call_PostDescribeApplicationVersions_611909(
    name: "postDescribeApplicationVersions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplicationVersions",
    validator: validate_PostDescribeApplicationVersions_611910, base: "/",
    url: url_PostDescribeApplicationVersions_611911,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeApplicationVersions_611890 = ref object of OpenApiRestCall_610659
proc url_GetDescribeApplicationVersions_611892(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeApplicationVersions_611891(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieve a list of application versions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ApplicationName: JString
  ##                  : Specify an application name to show only application versions for that application.
  ##   NextToken: JString
  ##            : <p>For a paginated request. Specify a token from a previous response page to retrieve the next response page. All other parameter values must be identical to the ones specified in the initial request.</p> <p>If no <code>NextToken</code> is specified, the first page is retrieved.</p>
  ##   VersionLabels: JArray
  ##                : Specify a version label to show a specific application version.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   MaxRecords: JInt
  ##             : <p>For a paginated request. Specify a maximum number of application versions to include in each response.</p> <p>If no <code>MaxRecords</code> is specified, all available application versions are retrieved in a single response.</p>
  section = newJObject()
  var valid_611893 = query.getOrDefault("ApplicationName")
  valid_611893 = validateParameter(valid_611893, JString, required = false,
                                 default = nil)
  if valid_611893 != nil:
    section.add "ApplicationName", valid_611893
  var valid_611894 = query.getOrDefault("NextToken")
  valid_611894 = validateParameter(valid_611894, JString, required = false,
                                 default = nil)
  if valid_611894 != nil:
    section.add "NextToken", valid_611894
  var valid_611895 = query.getOrDefault("VersionLabels")
  valid_611895 = validateParameter(valid_611895, JArray, required = false,
                                 default = nil)
  if valid_611895 != nil:
    section.add "VersionLabels", valid_611895
  var valid_611896 = query.getOrDefault("Action")
  valid_611896 = validateParameter(valid_611896, JString, required = true, default = newJString(
      "DescribeApplicationVersions"))
  if valid_611896 != nil:
    section.add "Action", valid_611896
  var valid_611897 = query.getOrDefault("Version")
  valid_611897 = validateParameter(valid_611897, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_611897 != nil:
    section.add "Version", valid_611897
  var valid_611898 = query.getOrDefault("MaxRecords")
  valid_611898 = validateParameter(valid_611898, JInt, required = false, default = nil)
  if valid_611898 != nil:
    section.add "MaxRecords", valid_611898
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611899 = header.getOrDefault("X-Amz-Signature")
  valid_611899 = validateParameter(valid_611899, JString, required = false,
                                 default = nil)
  if valid_611899 != nil:
    section.add "X-Amz-Signature", valid_611899
  var valid_611900 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611900 = validateParameter(valid_611900, JString, required = false,
                                 default = nil)
  if valid_611900 != nil:
    section.add "X-Amz-Content-Sha256", valid_611900
  var valid_611901 = header.getOrDefault("X-Amz-Date")
  valid_611901 = validateParameter(valid_611901, JString, required = false,
                                 default = nil)
  if valid_611901 != nil:
    section.add "X-Amz-Date", valid_611901
  var valid_611902 = header.getOrDefault("X-Amz-Credential")
  valid_611902 = validateParameter(valid_611902, JString, required = false,
                                 default = nil)
  if valid_611902 != nil:
    section.add "X-Amz-Credential", valid_611902
  var valid_611903 = header.getOrDefault("X-Amz-Security-Token")
  valid_611903 = validateParameter(valid_611903, JString, required = false,
                                 default = nil)
  if valid_611903 != nil:
    section.add "X-Amz-Security-Token", valid_611903
  var valid_611904 = header.getOrDefault("X-Amz-Algorithm")
  valid_611904 = validateParameter(valid_611904, JString, required = false,
                                 default = nil)
  if valid_611904 != nil:
    section.add "X-Amz-Algorithm", valid_611904
  var valid_611905 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611905 = validateParameter(valid_611905, JString, required = false,
                                 default = nil)
  if valid_611905 != nil:
    section.add "X-Amz-SignedHeaders", valid_611905
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611906: Call_GetDescribeApplicationVersions_611890; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a list of application versions.
  ## 
  let valid = call_611906.validator(path, query, header, formData, body)
  let scheme = call_611906.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611906.url(scheme.get, call_611906.host, call_611906.base,
                         call_611906.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611906, url, valid)

proc call*(call_611907: Call_GetDescribeApplicationVersions_611890;
          ApplicationName: string = ""; NextToken: string = "";
          VersionLabels: JsonNode = nil;
          Action: string = "DescribeApplicationVersions";
          Version: string = "2010-12-01"; MaxRecords: int = 0): Recallable =
  ## getDescribeApplicationVersions
  ## Retrieve a list of application versions.
  ##   ApplicationName: string
  ##                  : Specify an application name to show only application versions for that application.
  ##   NextToken: string
  ##            : <p>For a paginated request. Specify a token from a previous response page to retrieve the next response page. All other parameter values must be identical to the ones specified in the initial request.</p> <p>If no <code>NextToken</code> is specified, the first page is retrieved.</p>
  ##   VersionLabels: JArray
  ##                : Specify a version label to show a specific application version.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  ##             : <p>For a paginated request. Specify a maximum number of application versions to include in each response.</p> <p>If no <code>MaxRecords</code> is specified, all available application versions are retrieved in a single response.</p>
  var query_611908 = newJObject()
  add(query_611908, "ApplicationName", newJString(ApplicationName))
  add(query_611908, "NextToken", newJString(NextToken))
  if VersionLabels != nil:
    query_611908.add "VersionLabels", VersionLabels
  add(query_611908, "Action", newJString(Action))
  add(query_611908, "Version", newJString(Version))
  add(query_611908, "MaxRecords", newJInt(MaxRecords))
  result = call_611907.call(nil, query_611908, nil, nil, nil)

var getDescribeApplicationVersions* = Call_GetDescribeApplicationVersions_611890(
    name: "getDescribeApplicationVersions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplicationVersions",
    validator: validate_GetDescribeApplicationVersions_611891, base: "/",
    url: url_GetDescribeApplicationVersions_611892,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeApplications_611945 = ref object of OpenApiRestCall_610659
proc url_PostDescribeApplications_611947(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeApplications_611946(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the descriptions of existing applications.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611948 = query.getOrDefault("Action")
  valid_611948 = validateParameter(valid_611948, JString, required = true,
                                 default = newJString("DescribeApplications"))
  if valid_611948 != nil:
    section.add "Action", valid_611948
  var valid_611949 = query.getOrDefault("Version")
  valid_611949 = validateParameter(valid_611949, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_611949 != nil:
    section.add "Version", valid_611949
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611950 = header.getOrDefault("X-Amz-Signature")
  valid_611950 = validateParameter(valid_611950, JString, required = false,
                                 default = nil)
  if valid_611950 != nil:
    section.add "X-Amz-Signature", valid_611950
  var valid_611951 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611951 = validateParameter(valid_611951, JString, required = false,
                                 default = nil)
  if valid_611951 != nil:
    section.add "X-Amz-Content-Sha256", valid_611951
  var valid_611952 = header.getOrDefault("X-Amz-Date")
  valid_611952 = validateParameter(valid_611952, JString, required = false,
                                 default = nil)
  if valid_611952 != nil:
    section.add "X-Amz-Date", valid_611952
  var valid_611953 = header.getOrDefault("X-Amz-Credential")
  valid_611953 = validateParameter(valid_611953, JString, required = false,
                                 default = nil)
  if valid_611953 != nil:
    section.add "X-Amz-Credential", valid_611953
  var valid_611954 = header.getOrDefault("X-Amz-Security-Token")
  valid_611954 = validateParameter(valid_611954, JString, required = false,
                                 default = nil)
  if valid_611954 != nil:
    section.add "X-Amz-Security-Token", valid_611954
  var valid_611955 = header.getOrDefault("X-Amz-Algorithm")
  valid_611955 = validateParameter(valid_611955, JString, required = false,
                                 default = nil)
  if valid_611955 != nil:
    section.add "X-Amz-Algorithm", valid_611955
  var valid_611956 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611956 = validateParameter(valid_611956, JString, required = false,
                                 default = nil)
  if valid_611956 != nil:
    section.add "X-Amz-SignedHeaders", valid_611956
  result.add "header", section
  ## parameters in `formData` object:
  ##   ApplicationNames: JArray
  ##                   : If specified, AWS Elastic Beanstalk restricts the returned descriptions to only include those with the specified names.
  section = newJObject()
  var valid_611957 = formData.getOrDefault("ApplicationNames")
  valid_611957 = validateParameter(valid_611957, JArray, required = false,
                                 default = nil)
  if valid_611957 != nil:
    section.add "ApplicationNames", valid_611957
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611958: Call_PostDescribeApplications_611945; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the descriptions of existing applications.
  ## 
  let valid = call_611958.validator(path, query, header, formData, body)
  let scheme = call_611958.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611958.url(scheme.get, call_611958.host, call_611958.base,
                         call_611958.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611958, url, valid)

proc call*(call_611959: Call_PostDescribeApplications_611945;
          ApplicationNames: JsonNode = nil; Action: string = "DescribeApplications";
          Version: string = "2010-12-01"): Recallable =
  ## postDescribeApplications
  ## Returns the descriptions of existing applications.
  ##   ApplicationNames: JArray
  ##                   : If specified, AWS Elastic Beanstalk restricts the returned descriptions to only include those with the specified names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611960 = newJObject()
  var formData_611961 = newJObject()
  if ApplicationNames != nil:
    formData_611961.add "ApplicationNames", ApplicationNames
  add(query_611960, "Action", newJString(Action))
  add(query_611960, "Version", newJString(Version))
  result = call_611959.call(nil, query_611960, nil, formData_611961, nil)

var postDescribeApplications* = Call_PostDescribeApplications_611945(
    name: "postDescribeApplications", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplications",
    validator: validate_PostDescribeApplications_611946, base: "/",
    url: url_PostDescribeApplications_611947, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeApplications_611929 = ref object of OpenApiRestCall_610659
proc url_GetDescribeApplications_611931(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeApplications_611930(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the descriptions of existing applications.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ApplicationNames: JArray
  ##                   : If specified, AWS Elastic Beanstalk restricts the returned descriptions to only include those with the specified names.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611932 = query.getOrDefault("ApplicationNames")
  valid_611932 = validateParameter(valid_611932, JArray, required = false,
                                 default = nil)
  if valid_611932 != nil:
    section.add "ApplicationNames", valid_611932
  var valid_611933 = query.getOrDefault("Action")
  valid_611933 = validateParameter(valid_611933, JString, required = true,
                                 default = newJString("DescribeApplications"))
  if valid_611933 != nil:
    section.add "Action", valid_611933
  var valid_611934 = query.getOrDefault("Version")
  valid_611934 = validateParameter(valid_611934, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_611934 != nil:
    section.add "Version", valid_611934
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611935 = header.getOrDefault("X-Amz-Signature")
  valid_611935 = validateParameter(valid_611935, JString, required = false,
                                 default = nil)
  if valid_611935 != nil:
    section.add "X-Amz-Signature", valid_611935
  var valid_611936 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611936 = validateParameter(valid_611936, JString, required = false,
                                 default = nil)
  if valid_611936 != nil:
    section.add "X-Amz-Content-Sha256", valid_611936
  var valid_611937 = header.getOrDefault("X-Amz-Date")
  valid_611937 = validateParameter(valid_611937, JString, required = false,
                                 default = nil)
  if valid_611937 != nil:
    section.add "X-Amz-Date", valid_611937
  var valid_611938 = header.getOrDefault("X-Amz-Credential")
  valid_611938 = validateParameter(valid_611938, JString, required = false,
                                 default = nil)
  if valid_611938 != nil:
    section.add "X-Amz-Credential", valid_611938
  var valid_611939 = header.getOrDefault("X-Amz-Security-Token")
  valid_611939 = validateParameter(valid_611939, JString, required = false,
                                 default = nil)
  if valid_611939 != nil:
    section.add "X-Amz-Security-Token", valid_611939
  var valid_611940 = header.getOrDefault("X-Amz-Algorithm")
  valid_611940 = validateParameter(valid_611940, JString, required = false,
                                 default = nil)
  if valid_611940 != nil:
    section.add "X-Amz-Algorithm", valid_611940
  var valid_611941 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611941 = validateParameter(valid_611941, JString, required = false,
                                 default = nil)
  if valid_611941 != nil:
    section.add "X-Amz-SignedHeaders", valid_611941
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611942: Call_GetDescribeApplications_611929; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the descriptions of existing applications.
  ## 
  let valid = call_611942.validator(path, query, header, formData, body)
  let scheme = call_611942.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611942.url(scheme.get, call_611942.host, call_611942.base,
                         call_611942.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611942, url, valid)

proc call*(call_611943: Call_GetDescribeApplications_611929;
          ApplicationNames: JsonNode = nil; Action: string = "DescribeApplications";
          Version: string = "2010-12-01"): Recallable =
  ## getDescribeApplications
  ## Returns the descriptions of existing applications.
  ##   ApplicationNames: JArray
  ##                   : If specified, AWS Elastic Beanstalk restricts the returned descriptions to only include those with the specified names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611944 = newJObject()
  if ApplicationNames != nil:
    query_611944.add "ApplicationNames", ApplicationNames
  add(query_611944, "Action", newJString(Action))
  add(query_611944, "Version", newJString(Version))
  result = call_611943.call(nil, query_611944, nil, nil, nil)

var getDescribeApplications* = Call_GetDescribeApplications_611929(
    name: "getDescribeApplications", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplications",
    validator: validate_GetDescribeApplications_611930, base: "/",
    url: url_GetDescribeApplications_611931, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeConfigurationOptions_611983 = ref object of OpenApiRestCall_610659
proc url_PostDescribeConfigurationOptions_611985(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeConfigurationOptions_611984(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the configuration options that are used in a particular configuration template or environment, or that a specified solution stack defines. The description includes the values the options, their default values, and an indication of the required action on a running environment if an option value is changed.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_611986 = query.getOrDefault("Action")
  valid_611986 = validateParameter(valid_611986, JString, required = true, default = newJString(
      "DescribeConfigurationOptions"))
  if valid_611986 != nil:
    section.add "Action", valid_611986
  var valid_611987 = query.getOrDefault("Version")
  valid_611987 = validateParameter(valid_611987, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_611987 != nil:
    section.add "Version", valid_611987
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611988 = header.getOrDefault("X-Amz-Signature")
  valid_611988 = validateParameter(valid_611988, JString, required = false,
                                 default = nil)
  if valid_611988 != nil:
    section.add "X-Amz-Signature", valid_611988
  var valid_611989 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611989 = validateParameter(valid_611989, JString, required = false,
                                 default = nil)
  if valid_611989 != nil:
    section.add "X-Amz-Content-Sha256", valid_611989
  var valid_611990 = header.getOrDefault("X-Amz-Date")
  valid_611990 = validateParameter(valid_611990, JString, required = false,
                                 default = nil)
  if valid_611990 != nil:
    section.add "X-Amz-Date", valid_611990
  var valid_611991 = header.getOrDefault("X-Amz-Credential")
  valid_611991 = validateParameter(valid_611991, JString, required = false,
                                 default = nil)
  if valid_611991 != nil:
    section.add "X-Amz-Credential", valid_611991
  var valid_611992 = header.getOrDefault("X-Amz-Security-Token")
  valid_611992 = validateParameter(valid_611992, JString, required = false,
                                 default = nil)
  if valid_611992 != nil:
    section.add "X-Amz-Security-Token", valid_611992
  var valid_611993 = header.getOrDefault("X-Amz-Algorithm")
  valid_611993 = validateParameter(valid_611993, JString, required = false,
                                 default = nil)
  if valid_611993 != nil:
    section.add "X-Amz-Algorithm", valid_611993
  var valid_611994 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611994 = validateParameter(valid_611994, JString, required = false,
                                 default = nil)
  if valid_611994 != nil:
    section.add "X-Amz-SignedHeaders", valid_611994
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString
  ##                  : The name of the environment whose configuration options you want to describe.
  ##   TemplateName: JString
  ##               : The name of the configuration template whose configuration options you want to describe.
  ##   Options: JArray
  ##          : If specified, restricts the descriptions to only the specified options.
  ##   ApplicationName: JString
  ##                  : The name of the application associated with the configuration template or environment. Only needed if you want to describe the configuration options associated with either the configuration template or environment.
  ##   SolutionStackName: JString
  ##                    : The name of the solution stack whose configuration options you want to describe.
  ##   PlatformArn: JString
  ##              : The ARN of the custom platform.
  section = newJObject()
  var valid_611995 = formData.getOrDefault("EnvironmentName")
  valid_611995 = validateParameter(valid_611995, JString, required = false,
                                 default = nil)
  if valid_611995 != nil:
    section.add "EnvironmentName", valid_611995
  var valid_611996 = formData.getOrDefault("TemplateName")
  valid_611996 = validateParameter(valid_611996, JString, required = false,
                                 default = nil)
  if valid_611996 != nil:
    section.add "TemplateName", valid_611996
  var valid_611997 = formData.getOrDefault("Options")
  valid_611997 = validateParameter(valid_611997, JArray, required = false,
                                 default = nil)
  if valid_611997 != nil:
    section.add "Options", valid_611997
  var valid_611998 = formData.getOrDefault("ApplicationName")
  valid_611998 = validateParameter(valid_611998, JString, required = false,
                                 default = nil)
  if valid_611998 != nil:
    section.add "ApplicationName", valid_611998
  var valid_611999 = formData.getOrDefault("SolutionStackName")
  valid_611999 = validateParameter(valid_611999, JString, required = false,
                                 default = nil)
  if valid_611999 != nil:
    section.add "SolutionStackName", valid_611999
  var valid_612000 = formData.getOrDefault("PlatformArn")
  valid_612000 = validateParameter(valid_612000, JString, required = false,
                                 default = nil)
  if valid_612000 != nil:
    section.add "PlatformArn", valid_612000
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612001: Call_PostDescribeConfigurationOptions_611983;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the configuration options that are used in a particular configuration template or environment, or that a specified solution stack defines. The description includes the values the options, their default values, and an indication of the required action on a running environment if an option value is changed.
  ## 
  let valid = call_612001.validator(path, query, header, formData, body)
  let scheme = call_612001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612001.url(scheme.get, call_612001.host, call_612001.base,
                         call_612001.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612001, url, valid)

proc call*(call_612002: Call_PostDescribeConfigurationOptions_611983;
          EnvironmentName: string = ""; TemplateName: string = "";
          Options: JsonNode = nil; ApplicationName: string = "";
          Action: string = "DescribeConfigurationOptions";
          SolutionStackName: string = ""; Version: string = "2010-12-01";
          PlatformArn: string = ""): Recallable =
  ## postDescribeConfigurationOptions
  ## Describes the configuration options that are used in a particular configuration template or environment, or that a specified solution stack defines. The description includes the values the options, their default values, and an indication of the required action on a running environment if an option value is changed.
  ##   EnvironmentName: string
  ##                  : The name of the environment whose configuration options you want to describe.
  ##   TemplateName: string
  ##               : The name of the configuration template whose configuration options you want to describe.
  ##   Options: JArray
  ##          : If specified, restricts the descriptions to only the specified options.
  ##   ApplicationName: string
  ##                  : The name of the application associated with the configuration template or environment. Only needed if you want to describe the configuration options associated with either the configuration template or environment.
  ##   Action: string (required)
  ##   SolutionStackName: string
  ##                    : The name of the solution stack whose configuration options you want to describe.
  ##   Version: string (required)
  ##   PlatformArn: string
  ##              : The ARN of the custom platform.
  var query_612003 = newJObject()
  var formData_612004 = newJObject()
  add(formData_612004, "EnvironmentName", newJString(EnvironmentName))
  add(formData_612004, "TemplateName", newJString(TemplateName))
  if Options != nil:
    formData_612004.add "Options", Options
  add(formData_612004, "ApplicationName", newJString(ApplicationName))
  add(query_612003, "Action", newJString(Action))
  add(formData_612004, "SolutionStackName", newJString(SolutionStackName))
  add(query_612003, "Version", newJString(Version))
  add(formData_612004, "PlatformArn", newJString(PlatformArn))
  result = call_612002.call(nil, query_612003, nil, formData_612004, nil)

var postDescribeConfigurationOptions* = Call_PostDescribeConfigurationOptions_611983(
    name: "postDescribeConfigurationOptions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationOptions",
    validator: validate_PostDescribeConfigurationOptions_611984, base: "/",
    url: url_PostDescribeConfigurationOptions_611985,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeConfigurationOptions_611962 = ref object of OpenApiRestCall_610659
proc url_GetDescribeConfigurationOptions_611964(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeConfigurationOptions_611963(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the configuration options that are used in a particular configuration template or environment, or that a specified solution stack defines. The description includes the values the options, their default values, and an indication of the required action on a running environment if an option value is changed.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ApplicationName: JString
  ##                  : The name of the application associated with the configuration template or environment. Only needed if you want to describe the configuration options associated with either the configuration template or environment.
  ##   Options: JArray
  ##          : If specified, restricts the descriptions to only the specified options.
  ##   SolutionStackName: JString
  ##                    : The name of the solution stack whose configuration options you want to describe.
  ##   EnvironmentName: JString
  ##                  : The name of the environment whose configuration options you want to describe.
  ##   Action: JString (required)
  ##   PlatformArn: JString
  ##              : The ARN of the custom platform.
  ##   Version: JString (required)
  ##   TemplateName: JString
  ##               : The name of the configuration template whose configuration options you want to describe.
  section = newJObject()
  var valid_611965 = query.getOrDefault("ApplicationName")
  valid_611965 = validateParameter(valid_611965, JString, required = false,
                                 default = nil)
  if valid_611965 != nil:
    section.add "ApplicationName", valid_611965
  var valid_611966 = query.getOrDefault("Options")
  valid_611966 = validateParameter(valid_611966, JArray, required = false,
                                 default = nil)
  if valid_611966 != nil:
    section.add "Options", valid_611966
  var valid_611967 = query.getOrDefault("SolutionStackName")
  valid_611967 = validateParameter(valid_611967, JString, required = false,
                                 default = nil)
  if valid_611967 != nil:
    section.add "SolutionStackName", valid_611967
  var valid_611968 = query.getOrDefault("EnvironmentName")
  valid_611968 = validateParameter(valid_611968, JString, required = false,
                                 default = nil)
  if valid_611968 != nil:
    section.add "EnvironmentName", valid_611968
  var valid_611969 = query.getOrDefault("Action")
  valid_611969 = validateParameter(valid_611969, JString, required = true, default = newJString(
      "DescribeConfigurationOptions"))
  if valid_611969 != nil:
    section.add "Action", valid_611969
  var valid_611970 = query.getOrDefault("PlatformArn")
  valid_611970 = validateParameter(valid_611970, JString, required = false,
                                 default = nil)
  if valid_611970 != nil:
    section.add "PlatformArn", valid_611970
  var valid_611971 = query.getOrDefault("Version")
  valid_611971 = validateParameter(valid_611971, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_611971 != nil:
    section.add "Version", valid_611971
  var valid_611972 = query.getOrDefault("TemplateName")
  valid_611972 = validateParameter(valid_611972, JString, required = false,
                                 default = nil)
  if valid_611972 != nil:
    section.add "TemplateName", valid_611972
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611973 = header.getOrDefault("X-Amz-Signature")
  valid_611973 = validateParameter(valid_611973, JString, required = false,
                                 default = nil)
  if valid_611973 != nil:
    section.add "X-Amz-Signature", valid_611973
  var valid_611974 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611974 = validateParameter(valid_611974, JString, required = false,
                                 default = nil)
  if valid_611974 != nil:
    section.add "X-Amz-Content-Sha256", valid_611974
  var valid_611975 = header.getOrDefault("X-Amz-Date")
  valid_611975 = validateParameter(valid_611975, JString, required = false,
                                 default = nil)
  if valid_611975 != nil:
    section.add "X-Amz-Date", valid_611975
  var valid_611976 = header.getOrDefault("X-Amz-Credential")
  valid_611976 = validateParameter(valid_611976, JString, required = false,
                                 default = nil)
  if valid_611976 != nil:
    section.add "X-Amz-Credential", valid_611976
  var valid_611977 = header.getOrDefault("X-Amz-Security-Token")
  valid_611977 = validateParameter(valid_611977, JString, required = false,
                                 default = nil)
  if valid_611977 != nil:
    section.add "X-Amz-Security-Token", valid_611977
  var valid_611978 = header.getOrDefault("X-Amz-Algorithm")
  valid_611978 = validateParameter(valid_611978, JString, required = false,
                                 default = nil)
  if valid_611978 != nil:
    section.add "X-Amz-Algorithm", valid_611978
  var valid_611979 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611979 = validateParameter(valid_611979, JString, required = false,
                                 default = nil)
  if valid_611979 != nil:
    section.add "X-Amz-SignedHeaders", valid_611979
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611980: Call_GetDescribeConfigurationOptions_611962;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the configuration options that are used in a particular configuration template or environment, or that a specified solution stack defines. The description includes the values the options, their default values, and an indication of the required action on a running environment if an option value is changed.
  ## 
  let valid = call_611980.validator(path, query, header, formData, body)
  let scheme = call_611980.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611980.url(scheme.get, call_611980.host, call_611980.base,
                         call_611980.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611980, url, valid)

proc call*(call_611981: Call_GetDescribeConfigurationOptions_611962;
          ApplicationName: string = ""; Options: JsonNode = nil;
          SolutionStackName: string = ""; EnvironmentName: string = "";
          Action: string = "DescribeConfigurationOptions"; PlatformArn: string = "";
          Version: string = "2010-12-01"; TemplateName: string = ""): Recallable =
  ## getDescribeConfigurationOptions
  ## Describes the configuration options that are used in a particular configuration template or environment, or that a specified solution stack defines. The description includes the values the options, their default values, and an indication of the required action on a running environment if an option value is changed.
  ##   ApplicationName: string
  ##                  : The name of the application associated with the configuration template or environment. Only needed if you want to describe the configuration options associated with either the configuration template or environment.
  ##   Options: JArray
  ##          : If specified, restricts the descriptions to only the specified options.
  ##   SolutionStackName: string
  ##                    : The name of the solution stack whose configuration options you want to describe.
  ##   EnvironmentName: string
  ##                  : The name of the environment whose configuration options you want to describe.
  ##   Action: string (required)
  ##   PlatformArn: string
  ##              : The ARN of the custom platform.
  ##   Version: string (required)
  ##   TemplateName: string
  ##               : The name of the configuration template whose configuration options you want to describe.
  var query_611982 = newJObject()
  add(query_611982, "ApplicationName", newJString(ApplicationName))
  if Options != nil:
    query_611982.add "Options", Options
  add(query_611982, "SolutionStackName", newJString(SolutionStackName))
  add(query_611982, "EnvironmentName", newJString(EnvironmentName))
  add(query_611982, "Action", newJString(Action))
  add(query_611982, "PlatformArn", newJString(PlatformArn))
  add(query_611982, "Version", newJString(Version))
  add(query_611982, "TemplateName", newJString(TemplateName))
  result = call_611981.call(nil, query_611982, nil, nil, nil)

var getDescribeConfigurationOptions* = Call_GetDescribeConfigurationOptions_611962(
    name: "getDescribeConfigurationOptions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationOptions",
    validator: validate_GetDescribeConfigurationOptions_611963, base: "/",
    url: url_GetDescribeConfigurationOptions_611964,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeConfigurationSettings_612023 = ref object of OpenApiRestCall_610659
proc url_PostDescribeConfigurationSettings_612025(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeConfigurationSettings_612024(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a description of the settings for the specified configuration set, that is, either a configuration template or the configuration set associated with a running environment.</p> <p>When describing the settings for the configuration set associated with a running environment, it is possible to receive two sets of setting descriptions. One is the deployed configuration set, and the other is a draft configuration of an environment that is either in the process of deployment or that failed to deploy.</p> <p>Related Topics</p> <ul> <li> <p> <a>DeleteEnvironmentConfiguration</a> </p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612026 = query.getOrDefault("Action")
  valid_612026 = validateParameter(valid_612026, JString, required = true, default = newJString(
      "DescribeConfigurationSettings"))
  if valid_612026 != nil:
    section.add "Action", valid_612026
  var valid_612027 = query.getOrDefault("Version")
  valid_612027 = validateParameter(valid_612027, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612027 != nil:
    section.add "Version", valid_612027
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612028 = header.getOrDefault("X-Amz-Signature")
  valid_612028 = validateParameter(valid_612028, JString, required = false,
                                 default = nil)
  if valid_612028 != nil:
    section.add "X-Amz-Signature", valid_612028
  var valid_612029 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612029 = validateParameter(valid_612029, JString, required = false,
                                 default = nil)
  if valid_612029 != nil:
    section.add "X-Amz-Content-Sha256", valid_612029
  var valid_612030 = header.getOrDefault("X-Amz-Date")
  valid_612030 = validateParameter(valid_612030, JString, required = false,
                                 default = nil)
  if valid_612030 != nil:
    section.add "X-Amz-Date", valid_612030
  var valid_612031 = header.getOrDefault("X-Amz-Credential")
  valid_612031 = validateParameter(valid_612031, JString, required = false,
                                 default = nil)
  if valid_612031 != nil:
    section.add "X-Amz-Credential", valid_612031
  var valid_612032 = header.getOrDefault("X-Amz-Security-Token")
  valid_612032 = validateParameter(valid_612032, JString, required = false,
                                 default = nil)
  if valid_612032 != nil:
    section.add "X-Amz-Security-Token", valid_612032
  var valid_612033 = header.getOrDefault("X-Amz-Algorithm")
  valid_612033 = validateParameter(valid_612033, JString, required = false,
                                 default = nil)
  if valid_612033 != nil:
    section.add "X-Amz-Algorithm", valid_612033
  var valid_612034 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612034 = validateParameter(valid_612034, JString, required = false,
                                 default = nil)
  if valid_612034 != nil:
    section.add "X-Amz-SignedHeaders", valid_612034
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to describe.</p> <p> Condition: You must specify either this or a TemplateName, but not both. If you specify both, AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   TemplateName: JString
  ##               : <p>The name of the configuration template to describe.</p> <p> Conditional: You must specify either this parameter or an EnvironmentName, but not both. If you specify both, AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. If you do not specify either, AWS Elastic Beanstalk returns a <code>MissingRequiredParameter</code> error. </p>
  ##   ApplicationName: JString (required)
  ##                  : The application for the environment or configuration template.
  section = newJObject()
  var valid_612035 = formData.getOrDefault("EnvironmentName")
  valid_612035 = validateParameter(valid_612035, JString, required = false,
                                 default = nil)
  if valid_612035 != nil:
    section.add "EnvironmentName", valid_612035
  var valid_612036 = formData.getOrDefault("TemplateName")
  valid_612036 = validateParameter(valid_612036, JString, required = false,
                                 default = nil)
  if valid_612036 != nil:
    section.add "TemplateName", valid_612036
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_612037 = formData.getOrDefault("ApplicationName")
  valid_612037 = validateParameter(valid_612037, JString, required = true,
                                 default = nil)
  if valid_612037 != nil:
    section.add "ApplicationName", valid_612037
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612038: Call_PostDescribeConfigurationSettings_612023;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a description of the settings for the specified configuration set, that is, either a configuration template or the configuration set associated with a running environment.</p> <p>When describing the settings for the configuration set associated with a running environment, it is possible to receive two sets of setting descriptions. One is the deployed configuration set, and the other is a draft configuration of an environment that is either in the process of deployment or that failed to deploy.</p> <p>Related Topics</p> <ul> <li> <p> <a>DeleteEnvironmentConfiguration</a> </p> </li> </ul>
  ## 
  let valid = call_612038.validator(path, query, header, formData, body)
  let scheme = call_612038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612038.url(scheme.get, call_612038.host, call_612038.base,
                         call_612038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612038, url, valid)

proc call*(call_612039: Call_PostDescribeConfigurationSettings_612023;
          ApplicationName: string; EnvironmentName: string = "";
          TemplateName: string = "";
          Action: string = "DescribeConfigurationSettings";
          Version: string = "2010-12-01"): Recallable =
  ## postDescribeConfigurationSettings
  ## <p>Returns a description of the settings for the specified configuration set, that is, either a configuration template or the configuration set associated with a running environment.</p> <p>When describing the settings for the configuration set associated with a running environment, it is possible to receive two sets of setting descriptions. One is the deployed configuration set, and the other is a draft configuration of an environment that is either in the process of deployment or that failed to deploy.</p> <p>Related Topics</p> <ul> <li> <p> <a>DeleteEnvironmentConfiguration</a> </p> </li> </ul>
  ##   EnvironmentName: string
  ##                  : <p>The name of the environment to describe.</p> <p> Condition: You must specify either this or a TemplateName, but not both. If you specify both, AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   TemplateName: string
  ##               : <p>The name of the configuration template to describe.</p> <p> Conditional: You must specify either this parameter or an EnvironmentName, but not both. If you specify both, AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. If you do not specify either, AWS Elastic Beanstalk returns a <code>MissingRequiredParameter</code> error. </p>
  ##   ApplicationName: string (required)
  ##                  : The application for the environment or configuration template.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612040 = newJObject()
  var formData_612041 = newJObject()
  add(formData_612041, "EnvironmentName", newJString(EnvironmentName))
  add(formData_612041, "TemplateName", newJString(TemplateName))
  add(formData_612041, "ApplicationName", newJString(ApplicationName))
  add(query_612040, "Action", newJString(Action))
  add(query_612040, "Version", newJString(Version))
  result = call_612039.call(nil, query_612040, nil, formData_612041, nil)

var postDescribeConfigurationSettings* = Call_PostDescribeConfigurationSettings_612023(
    name: "postDescribeConfigurationSettings", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationSettings",
    validator: validate_PostDescribeConfigurationSettings_612024, base: "/",
    url: url_PostDescribeConfigurationSettings_612025,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeConfigurationSettings_612005 = ref object of OpenApiRestCall_610659
proc url_GetDescribeConfigurationSettings_612007(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeConfigurationSettings_612006(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a description of the settings for the specified configuration set, that is, either a configuration template or the configuration set associated with a running environment.</p> <p>When describing the settings for the configuration set associated with a running environment, it is possible to receive two sets of setting descriptions. One is the deployed configuration set, and the other is a draft configuration of an environment that is either in the process of deployment or that failed to deploy.</p> <p>Related Topics</p> <ul> <li> <p> <a>DeleteEnvironmentConfiguration</a> </p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ApplicationName: JString (required)
  ##                  : The application for the environment or configuration template.
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to describe.</p> <p> Condition: You must specify either this or a TemplateName, but not both. If you specify both, AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   TemplateName: JString
  ##               : <p>The name of the configuration template to describe.</p> <p> Conditional: You must specify either this parameter or an EnvironmentName, but not both. If you specify both, AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. If you do not specify either, AWS Elastic Beanstalk returns a <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_612008 = query.getOrDefault("ApplicationName")
  valid_612008 = validateParameter(valid_612008, JString, required = true,
                                 default = nil)
  if valid_612008 != nil:
    section.add "ApplicationName", valid_612008
  var valid_612009 = query.getOrDefault("EnvironmentName")
  valid_612009 = validateParameter(valid_612009, JString, required = false,
                                 default = nil)
  if valid_612009 != nil:
    section.add "EnvironmentName", valid_612009
  var valid_612010 = query.getOrDefault("Action")
  valid_612010 = validateParameter(valid_612010, JString, required = true, default = newJString(
      "DescribeConfigurationSettings"))
  if valid_612010 != nil:
    section.add "Action", valid_612010
  var valid_612011 = query.getOrDefault("Version")
  valid_612011 = validateParameter(valid_612011, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612011 != nil:
    section.add "Version", valid_612011
  var valid_612012 = query.getOrDefault("TemplateName")
  valid_612012 = validateParameter(valid_612012, JString, required = false,
                                 default = nil)
  if valid_612012 != nil:
    section.add "TemplateName", valid_612012
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612013 = header.getOrDefault("X-Amz-Signature")
  valid_612013 = validateParameter(valid_612013, JString, required = false,
                                 default = nil)
  if valid_612013 != nil:
    section.add "X-Amz-Signature", valid_612013
  var valid_612014 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612014 = validateParameter(valid_612014, JString, required = false,
                                 default = nil)
  if valid_612014 != nil:
    section.add "X-Amz-Content-Sha256", valid_612014
  var valid_612015 = header.getOrDefault("X-Amz-Date")
  valid_612015 = validateParameter(valid_612015, JString, required = false,
                                 default = nil)
  if valid_612015 != nil:
    section.add "X-Amz-Date", valid_612015
  var valid_612016 = header.getOrDefault("X-Amz-Credential")
  valid_612016 = validateParameter(valid_612016, JString, required = false,
                                 default = nil)
  if valid_612016 != nil:
    section.add "X-Amz-Credential", valid_612016
  var valid_612017 = header.getOrDefault("X-Amz-Security-Token")
  valid_612017 = validateParameter(valid_612017, JString, required = false,
                                 default = nil)
  if valid_612017 != nil:
    section.add "X-Amz-Security-Token", valid_612017
  var valid_612018 = header.getOrDefault("X-Amz-Algorithm")
  valid_612018 = validateParameter(valid_612018, JString, required = false,
                                 default = nil)
  if valid_612018 != nil:
    section.add "X-Amz-Algorithm", valid_612018
  var valid_612019 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612019 = validateParameter(valid_612019, JString, required = false,
                                 default = nil)
  if valid_612019 != nil:
    section.add "X-Amz-SignedHeaders", valid_612019
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612020: Call_GetDescribeConfigurationSettings_612005;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a description of the settings for the specified configuration set, that is, either a configuration template or the configuration set associated with a running environment.</p> <p>When describing the settings for the configuration set associated with a running environment, it is possible to receive two sets of setting descriptions. One is the deployed configuration set, and the other is a draft configuration of an environment that is either in the process of deployment or that failed to deploy.</p> <p>Related Topics</p> <ul> <li> <p> <a>DeleteEnvironmentConfiguration</a> </p> </li> </ul>
  ## 
  let valid = call_612020.validator(path, query, header, formData, body)
  let scheme = call_612020.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612020.url(scheme.get, call_612020.host, call_612020.base,
                         call_612020.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612020, url, valid)

proc call*(call_612021: Call_GetDescribeConfigurationSettings_612005;
          ApplicationName: string; EnvironmentName: string = "";
          Action: string = "DescribeConfigurationSettings";
          Version: string = "2010-12-01"; TemplateName: string = ""): Recallable =
  ## getDescribeConfigurationSettings
  ## <p>Returns a description of the settings for the specified configuration set, that is, either a configuration template or the configuration set associated with a running environment.</p> <p>When describing the settings for the configuration set associated with a running environment, it is possible to receive two sets of setting descriptions. One is the deployed configuration set, and the other is a draft configuration of an environment that is either in the process of deployment or that failed to deploy.</p> <p>Related Topics</p> <ul> <li> <p> <a>DeleteEnvironmentConfiguration</a> </p> </li> </ul>
  ##   ApplicationName: string (required)
  ##                  : The application for the environment or configuration template.
  ##   EnvironmentName: string
  ##                  : <p>The name of the environment to describe.</p> <p> Condition: You must specify either this or a TemplateName, but not both. If you specify both, AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   TemplateName: string
  ##               : <p>The name of the configuration template to describe.</p> <p> Conditional: You must specify either this parameter or an EnvironmentName, but not both. If you specify both, AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. If you do not specify either, AWS Elastic Beanstalk returns a <code>MissingRequiredParameter</code> error. </p>
  var query_612022 = newJObject()
  add(query_612022, "ApplicationName", newJString(ApplicationName))
  add(query_612022, "EnvironmentName", newJString(EnvironmentName))
  add(query_612022, "Action", newJString(Action))
  add(query_612022, "Version", newJString(Version))
  add(query_612022, "TemplateName", newJString(TemplateName))
  result = call_612021.call(nil, query_612022, nil, nil, nil)

var getDescribeConfigurationSettings* = Call_GetDescribeConfigurationSettings_612005(
    name: "getDescribeConfigurationSettings", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationSettings",
    validator: validate_GetDescribeConfigurationSettings_612006, base: "/",
    url: url_GetDescribeConfigurationSettings_612007,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentHealth_612060 = ref object of OpenApiRestCall_610659
proc url_PostDescribeEnvironmentHealth_612062(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEnvironmentHealth_612061(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about the overall health of the specified environment. The <b>DescribeEnvironmentHealth</b> operation is only available with AWS Elastic Beanstalk Enhanced Health.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612063 = query.getOrDefault("Action")
  valid_612063 = validateParameter(valid_612063, JString, required = true, default = newJString(
      "DescribeEnvironmentHealth"))
  if valid_612063 != nil:
    section.add "Action", valid_612063
  var valid_612064 = query.getOrDefault("Version")
  valid_612064 = validateParameter(valid_612064, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612064 != nil:
    section.add "Version", valid_612064
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612065 = header.getOrDefault("X-Amz-Signature")
  valid_612065 = validateParameter(valid_612065, JString, required = false,
                                 default = nil)
  if valid_612065 != nil:
    section.add "X-Amz-Signature", valid_612065
  var valid_612066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612066 = validateParameter(valid_612066, JString, required = false,
                                 default = nil)
  if valid_612066 != nil:
    section.add "X-Amz-Content-Sha256", valid_612066
  var valid_612067 = header.getOrDefault("X-Amz-Date")
  valid_612067 = validateParameter(valid_612067, JString, required = false,
                                 default = nil)
  if valid_612067 != nil:
    section.add "X-Amz-Date", valid_612067
  var valid_612068 = header.getOrDefault("X-Amz-Credential")
  valid_612068 = validateParameter(valid_612068, JString, required = false,
                                 default = nil)
  if valid_612068 != nil:
    section.add "X-Amz-Credential", valid_612068
  var valid_612069 = header.getOrDefault("X-Amz-Security-Token")
  valid_612069 = validateParameter(valid_612069, JString, required = false,
                                 default = nil)
  if valid_612069 != nil:
    section.add "X-Amz-Security-Token", valid_612069
  var valid_612070 = header.getOrDefault("X-Amz-Algorithm")
  valid_612070 = validateParameter(valid_612070, JString, required = false,
                                 default = nil)
  if valid_612070 != nil:
    section.add "X-Amz-Algorithm", valid_612070
  var valid_612071 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612071 = validateParameter(valid_612071, JString, required = false,
                                 default = nil)
  if valid_612071 != nil:
    section.add "X-Amz-SignedHeaders", valid_612071
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString
  ##                  : <p>Specify the environment by name.</p> <p>You must specify either this or an EnvironmentName, or both.</p>
  ##   AttributeNames: JArray
  ##                 : Specify the response elements to return. To retrieve all attributes, set to <code>All</code>. If no attribute names are specified, returns the name of the environment.
  ##   EnvironmentId: JString
  ##                : <p>Specify the environment by ID.</p> <p>You must specify either this or an EnvironmentName, or both.</p>
  section = newJObject()
  var valid_612072 = formData.getOrDefault("EnvironmentName")
  valid_612072 = validateParameter(valid_612072, JString, required = false,
                                 default = nil)
  if valid_612072 != nil:
    section.add "EnvironmentName", valid_612072
  var valid_612073 = formData.getOrDefault("AttributeNames")
  valid_612073 = validateParameter(valid_612073, JArray, required = false,
                                 default = nil)
  if valid_612073 != nil:
    section.add "AttributeNames", valid_612073
  var valid_612074 = formData.getOrDefault("EnvironmentId")
  valid_612074 = validateParameter(valid_612074, JString, required = false,
                                 default = nil)
  if valid_612074 != nil:
    section.add "EnvironmentId", valid_612074
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612075: Call_PostDescribeEnvironmentHealth_612060; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the overall health of the specified environment. The <b>DescribeEnvironmentHealth</b> operation is only available with AWS Elastic Beanstalk Enhanced Health.
  ## 
  let valid = call_612075.validator(path, query, header, formData, body)
  let scheme = call_612075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612075.url(scheme.get, call_612075.host, call_612075.base,
                         call_612075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612075, url, valid)

proc call*(call_612076: Call_PostDescribeEnvironmentHealth_612060;
          EnvironmentName: string = ""; AttributeNames: JsonNode = nil;
          Action: string = "DescribeEnvironmentHealth"; EnvironmentId: string = "";
          Version: string = "2010-12-01"): Recallable =
  ## postDescribeEnvironmentHealth
  ## Returns information about the overall health of the specified environment. The <b>DescribeEnvironmentHealth</b> operation is only available with AWS Elastic Beanstalk Enhanced Health.
  ##   EnvironmentName: string
  ##                  : <p>Specify the environment by name.</p> <p>You must specify either this or an EnvironmentName, or both.</p>
  ##   AttributeNames: JArray
  ##                 : Specify the response elements to return. To retrieve all attributes, set to <code>All</code>. If no attribute names are specified, returns the name of the environment.
  ##   Action: string (required)
  ##   EnvironmentId: string
  ##                : <p>Specify the environment by ID.</p> <p>You must specify either this or an EnvironmentName, or both.</p>
  ##   Version: string (required)
  var query_612077 = newJObject()
  var formData_612078 = newJObject()
  add(formData_612078, "EnvironmentName", newJString(EnvironmentName))
  if AttributeNames != nil:
    formData_612078.add "AttributeNames", AttributeNames
  add(query_612077, "Action", newJString(Action))
  add(formData_612078, "EnvironmentId", newJString(EnvironmentId))
  add(query_612077, "Version", newJString(Version))
  result = call_612076.call(nil, query_612077, nil, formData_612078, nil)

var postDescribeEnvironmentHealth* = Call_PostDescribeEnvironmentHealth_612060(
    name: "postDescribeEnvironmentHealth", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentHealth",
    validator: validate_PostDescribeEnvironmentHealth_612061, base: "/",
    url: url_PostDescribeEnvironmentHealth_612062,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentHealth_612042 = ref object of OpenApiRestCall_610659
proc url_GetDescribeEnvironmentHealth_612044(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEnvironmentHealth_612043(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about the overall health of the specified environment. The <b>DescribeEnvironmentHealth</b> operation is only available with AWS Elastic Beanstalk Enhanced Health.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   AttributeNames: JArray
  ##                 : Specify the response elements to return. To retrieve all attributes, set to <code>All</code>. If no attribute names are specified, returns the name of the environment.
  ##   EnvironmentName: JString
  ##                  : <p>Specify the environment by name.</p> <p>You must specify either this or an EnvironmentName, or both.</p>
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   EnvironmentId: JString
  ##                : <p>Specify the environment by ID.</p> <p>You must specify either this or an EnvironmentName, or both.</p>
  section = newJObject()
  var valid_612045 = query.getOrDefault("AttributeNames")
  valid_612045 = validateParameter(valid_612045, JArray, required = false,
                                 default = nil)
  if valid_612045 != nil:
    section.add "AttributeNames", valid_612045
  var valid_612046 = query.getOrDefault("EnvironmentName")
  valid_612046 = validateParameter(valid_612046, JString, required = false,
                                 default = nil)
  if valid_612046 != nil:
    section.add "EnvironmentName", valid_612046
  var valid_612047 = query.getOrDefault("Action")
  valid_612047 = validateParameter(valid_612047, JString, required = true, default = newJString(
      "DescribeEnvironmentHealth"))
  if valid_612047 != nil:
    section.add "Action", valid_612047
  var valid_612048 = query.getOrDefault("Version")
  valid_612048 = validateParameter(valid_612048, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612048 != nil:
    section.add "Version", valid_612048
  var valid_612049 = query.getOrDefault("EnvironmentId")
  valid_612049 = validateParameter(valid_612049, JString, required = false,
                                 default = nil)
  if valid_612049 != nil:
    section.add "EnvironmentId", valid_612049
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612050 = header.getOrDefault("X-Amz-Signature")
  valid_612050 = validateParameter(valid_612050, JString, required = false,
                                 default = nil)
  if valid_612050 != nil:
    section.add "X-Amz-Signature", valid_612050
  var valid_612051 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612051 = validateParameter(valid_612051, JString, required = false,
                                 default = nil)
  if valid_612051 != nil:
    section.add "X-Amz-Content-Sha256", valid_612051
  var valid_612052 = header.getOrDefault("X-Amz-Date")
  valid_612052 = validateParameter(valid_612052, JString, required = false,
                                 default = nil)
  if valid_612052 != nil:
    section.add "X-Amz-Date", valid_612052
  var valid_612053 = header.getOrDefault("X-Amz-Credential")
  valid_612053 = validateParameter(valid_612053, JString, required = false,
                                 default = nil)
  if valid_612053 != nil:
    section.add "X-Amz-Credential", valid_612053
  var valid_612054 = header.getOrDefault("X-Amz-Security-Token")
  valid_612054 = validateParameter(valid_612054, JString, required = false,
                                 default = nil)
  if valid_612054 != nil:
    section.add "X-Amz-Security-Token", valid_612054
  var valid_612055 = header.getOrDefault("X-Amz-Algorithm")
  valid_612055 = validateParameter(valid_612055, JString, required = false,
                                 default = nil)
  if valid_612055 != nil:
    section.add "X-Amz-Algorithm", valid_612055
  var valid_612056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612056 = validateParameter(valid_612056, JString, required = false,
                                 default = nil)
  if valid_612056 != nil:
    section.add "X-Amz-SignedHeaders", valid_612056
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612057: Call_GetDescribeEnvironmentHealth_612042; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the overall health of the specified environment. The <b>DescribeEnvironmentHealth</b> operation is only available with AWS Elastic Beanstalk Enhanced Health.
  ## 
  let valid = call_612057.validator(path, query, header, formData, body)
  let scheme = call_612057.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612057.url(scheme.get, call_612057.host, call_612057.base,
                         call_612057.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612057, url, valid)

proc call*(call_612058: Call_GetDescribeEnvironmentHealth_612042;
          AttributeNames: JsonNode = nil; EnvironmentName: string = "";
          Action: string = "DescribeEnvironmentHealth";
          Version: string = "2010-12-01"; EnvironmentId: string = ""): Recallable =
  ## getDescribeEnvironmentHealth
  ## Returns information about the overall health of the specified environment. The <b>DescribeEnvironmentHealth</b> operation is only available with AWS Elastic Beanstalk Enhanced Health.
  ##   AttributeNames: JArray
  ##                 : Specify the response elements to return. To retrieve all attributes, set to <code>All</code>. If no attribute names are specified, returns the name of the environment.
  ##   EnvironmentName: string
  ##                  : <p>Specify the environment by name.</p> <p>You must specify either this or an EnvironmentName, or both.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   EnvironmentId: string
  ##                : <p>Specify the environment by ID.</p> <p>You must specify either this or an EnvironmentName, or both.</p>
  var query_612059 = newJObject()
  if AttributeNames != nil:
    query_612059.add "AttributeNames", AttributeNames
  add(query_612059, "EnvironmentName", newJString(EnvironmentName))
  add(query_612059, "Action", newJString(Action))
  add(query_612059, "Version", newJString(Version))
  add(query_612059, "EnvironmentId", newJString(EnvironmentId))
  result = call_612058.call(nil, query_612059, nil, nil, nil)

var getDescribeEnvironmentHealth* = Call_GetDescribeEnvironmentHealth_612042(
    name: "getDescribeEnvironmentHealth", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentHealth",
    validator: validate_GetDescribeEnvironmentHealth_612043, base: "/",
    url: url_GetDescribeEnvironmentHealth_612044,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentManagedActionHistory_612098 = ref object of OpenApiRestCall_610659
proc url_PostDescribeEnvironmentManagedActionHistory_612100(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEnvironmentManagedActionHistory_612099(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists an environment's completed and failed managed actions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612101 = query.getOrDefault("Action")
  valid_612101 = validateParameter(valid_612101, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActionHistory"))
  if valid_612101 != nil:
    section.add "Action", valid_612101
  var valid_612102 = query.getOrDefault("Version")
  valid_612102 = validateParameter(valid_612102, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612102 != nil:
    section.add "Version", valid_612102
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612103 = header.getOrDefault("X-Amz-Signature")
  valid_612103 = validateParameter(valid_612103, JString, required = false,
                                 default = nil)
  if valid_612103 != nil:
    section.add "X-Amz-Signature", valid_612103
  var valid_612104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612104 = validateParameter(valid_612104, JString, required = false,
                                 default = nil)
  if valid_612104 != nil:
    section.add "X-Amz-Content-Sha256", valid_612104
  var valid_612105 = header.getOrDefault("X-Amz-Date")
  valid_612105 = validateParameter(valid_612105, JString, required = false,
                                 default = nil)
  if valid_612105 != nil:
    section.add "X-Amz-Date", valid_612105
  var valid_612106 = header.getOrDefault("X-Amz-Credential")
  valid_612106 = validateParameter(valid_612106, JString, required = false,
                                 default = nil)
  if valid_612106 != nil:
    section.add "X-Amz-Credential", valid_612106
  var valid_612107 = header.getOrDefault("X-Amz-Security-Token")
  valid_612107 = validateParameter(valid_612107, JString, required = false,
                                 default = nil)
  if valid_612107 != nil:
    section.add "X-Amz-Security-Token", valid_612107
  var valid_612108 = header.getOrDefault("X-Amz-Algorithm")
  valid_612108 = validateParameter(valid_612108, JString, required = false,
                                 default = nil)
  if valid_612108 != nil:
    section.add "X-Amz-Algorithm", valid_612108
  var valid_612109 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612109 = validateParameter(valid_612109, JString, required = false,
                                 default = nil)
  if valid_612109 != nil:
    section.add "X-Amz-SignedHeaders", valid_612109
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : The pagination token returned by a previous request.
  ##   EnvironmentName: JString
  ##                  : The name of the target environment.
  ##   MaxItems: JInt
  ##           : The maximum number of items to return for a single request.
  ##   EnvironmentId: JString
  ##                : The environment ID of the target environment.
  section = newJObject()
  var valid_612110 = formData.getOrDefault("NextToken")
  valid_612110 = validateParameter(valid_612110, JString, required = false,
                                 default = nil)
  if valid_612110 != nil:
    section.add "NextToken", valid_612110
  var valid_612111 = formData.getOrDefault("EnvironmentName")
  valid_612111 = validateParameter(valid_612111, JString, required = false,
                                 default = nil)
  if valid_612111 != nil:
    section.add "EnvironmentName", valid_612111
  var valid_612112 = formData.getOrDefault("MaxItems")
  valid_612112 = validateParameter(valid_612112, JInt, required = false, default = nil)
  if valid_612112 != nil:
    section.add "MaxItems", valid_612112
  var valid_612113 = formData.getOrDefault("EnvironmentId")
  valid_612113 = validateParameter(valid_612113, JString, required = false,
                                 default = nil)
  if valid_612113 != nil:
    section.add "EnvironmentId", valid_612113
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612114: Call_PostDescribeEnvironmentManagedActionHistory_612098;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists an environment's completed and failed managed actions.
  ## 
  let valid = call_612114.validator(path, query, header, formData, body)
  let scheme = call_612114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612114.url(scheme.get, call_612114.host, call_612114.base,
                         call_612114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612114, url, valid)

proc call*(call_612115: Call_PostDescribeEnvironmentManagedActionHistory_612098;
          NextToken: string = ""; EnvironmentName: string = "";
          Action: string = "DescribeEnvironmentManagedActionHistory";
          MaxItems: int = 0; EnvironmentId: string = ""; Version: string = "2010-12-01"): Recallable =
  ## postDescribeEnvironmentManagedActionHistory
  ## Lists an environment's completed and failed managed actions.
  ##   NextToken: string
  ##            : The pagination token returned by a previous request.
  ##   EnvironmentName: string
  ##                  : The name of the target environment.
  ##   Action: string (required)
  ##   MaxItems: int
  ##           : The maximum number of items to return for a single request.
  ##   EnvironmentId: string
  ##                : The environment ID of the target environment.
  ##   Version: string (required)
  var query_612116 = newJObject()
  var formData_612117 = newJObject()
  add(formData_612117, "NextToken", newJString(NextToken))
  add(formData_612117, "EnvironmentName", newJString(EnvironmentName))
  add(query_612116, "Action", newJString(Action))
  add(formData_612117, "MaxItems", newJInt(MaxItems))
  add(formData_612117, "EnvironmentId", newJString(EnvironmentId))
  add(query_612116, "Version", newJString(Version))
  result = call_612115.call(nil, query_612116, nil, formData_612117, nil)

var postDescribeEnvironmentManagedActionHistory* = Call_PostDescribeEnvironmentManagedActionHistory_612098(
    name: "postDescribeEnvironmentManagedActionHistory",
    meth: HttpMethod.HttpPost, host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActionHistory",
    validator: validate_PostDescribeEnvironmentManagedActionHistory_612099,
    base: "/", url: url_PostDescribeEnvironmentManagedActionHistory_612100,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentManagedActionHistory_612079 = ref object of OpenApiRestCall_610659
proc url_GetDescribeEnvironmentManagedActionHistory_612081(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEnvironmentManagedActionHistory_612080(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists an environment's completed and failed managed actions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxItems: JInt
  ##           : The maximum number of items to return for a single request.
  ##   NextToken: JString
  ##            : The pagination token returned by a previous request.
  ##   EnvironmentName: JString
  ##                  : The name of the target environment.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   EnvironmentId: JString
  ##                : The environment ID of the target environment.
  section = newJObject()
  var valid_612082 = query.getOrDefault("MaxItems")
  valid_612082 = validateParameter(valid_612082, JInt, required = false, default = nil)
  if valid_612082 != nil:
    section.add "MaxItems", valid_612082
  var valid_612083 = query.getOrDefault("NextToken")
  valid_612083 = validateParameter(valid_612083, JString, required = false,
                                 default = nil)
  if valid_612083 != nil:
    section.add "NextToken", valid_612083
  var valid_612084 = query.getOrDefault("EnvironmentName")
  valid_612084 = validateParameter(valid_612084, JString, required = false,
                                 default = nil)
  if valid_612084 != nil:
    section.add "EnvironmentName", valid_612084
  var valid_612085 = query.getOrDefault("Action")
  valid_612085 = validateParameter(valid_612085, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActionHistory"))
  if valid_612085 != nil:
    section.add "Action", valid_612085
  var valid_612086 = query.getOrDefault("Version")
  valid_612086 = validateParameter(valid_612086, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612086 != nil:
    section.add "Version", valid_612086
  var valid_612087 = query.getOrDefault("EnvironmentId")
  valid_612087 = validateParameter(valid_612087, JString, required = false,
                                 default = nil)
  if valid_612087 != nil:
    section.add "EnvironmentId", valid_612087
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612088 = header.getOrDefault("X-Amz-Signature")
  valid_612088 = validateParameter(valid_612088, JString, required = false,
                                 default = nil)
  if valid_612088 != nil:
    section.add "X-Amz-Signature", valid_612088
  var valid_612089 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612089 = validateParameter(valid_612089, JString, required = false,
                                 default = nil)
  if valid_612089 != nil:
    section.add "X-Amz-Content-Sha256", valid_612089
  var valid_612090 = header.getOrDefault("X-Amz-Date")
  valid_612090 = validateParameter(valid_612090, JString, required = false,
                                 default = nil)
  if valid_612090 != nil:
    section.add "X-Amz-Date", valid_612090
  var valid_612091 = header.getOrDefault("X-Amz-Credential")
  valid_612091 = validateParameter(valid_612091, JString, required = false,
                                 default = nil)
  if valid_612091 != nil:
    section.add "X-Amz-Credential", valid_612091
  var valid_612092 = header.getOrDefault("X-Amz-Security-Token")
  valid_612092 = validateParameter(valid_612092, JString, required = false,
                                 default = nil)
  if valid_612092 != nil:
    section.add "X-Amz-Security-Token", valid_612092
  var valid_612093 = header.getOrDefault("X-Amz-Algorithm")
  valid_612093 = validateParameter(valid_612093, JString, required = false,
                                 default = nil)
  if valid_612093 != nil:
    section.add "X-Amz-Algorithm", valid_612093
  var valid_612094 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612094 = validateParameter(valid_612094, JString, required = false,
                                 default = nil)
  if valid_612094 != nil:
    section.add "X-Amz-SignedHeaders", valid_612094
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612095: Call_GetDescribeEnvironmentManagedActionHistory_612079;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists an environment's completed and failed managed actions.
  ## 
  let valid = call_612095.validator(path, query, header, formData, body)
  let scheme = call_612095.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612095.url(scheme.get, call_612095.host, call_612095.base,
                         call_612095.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612095, url, valid)

proc call*(call_612096: Call_GetDescribeEnvironmentManagedActionHistory_612079;
          MaxItems: int = 0; NextToken: string = ""; EnvironmentName: string = "";
          Action: string = "DescribeEnvironmentManagedActionHistory";
          Version: string = "2010-12-01"; EnvironmentId: string = ""): Recallable =
  ## getDescribeEnvironmentManagedActionHistory
  ## Lists an environment's completed and failed managed actions.
  ##   MaxItems: int
  ##           : The maximum number of items to return for a single request.
  ##   NextToken: string
  ##            : The pagination token returned by a previous request.
  ##   EnvironmentName: string
  ##                  : The name of the target environment.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   EnvironmentId: string
  ##                : The environment ID of the target environment.
  var query_612097 = newJObject()
  add(query_612097, "MaxItems", newJInt(MaxItems))
  add(query_612097, "NextToken", newJString(NextToken))
  add(query_612097, "EnvironmentName", newJString(EnvironmentName))
  add(query_612097, "Action", newJString(Action))
  add(query_612097, "Version", newJString(Version))
  add(query_612097, "EnvironmentId", newJString(EnvironmentId))
  result = call_612096.call(nil, query_612097, nil, nil, nil)

var getDescribeEnvironmentManagedActionHistory* = Call_GetDescribeEnvironmentManagedActionHistory_612079(
    name: "getDescribeEnvironmentManagedActionHistory", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActionHistory",
    validator: validate_GetDescribeEnvironmentManagedActionHistory_612080,
    base: "/", url: url_GetDescribeEnvironmentManagedActionHistory_612081,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentManagedActions_612136 = ref object of OpenApiRestCall_610659
proc url_PostDescribeEnvironmentManagedActions_612138(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEnvironmentManagedActions_612137(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists an environment's upcoming and in-progress managed actions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612139 = query.getOrDefault("Action")
  valid_612139 = validateParameter(valid_612139, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActions"))
  if valid_612139 != nil:
    section.add "Action", valid_612139
  var valid_612140 = query.getOrDefault("Version")
  valid_612140 = validateParameter(valid_612140, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612140 != nil:
    section.add "Version", valid_612140
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612141 = header.getOrDefault("X-Amz-Signature")
  valid_612141 = validateParameter(valid_612141, JString, required = false,
                                 default = nil)
  if valid_612141 != nil:
    section.add "X-Amz-Signature", valid_612141
  var valid_612142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612142 = validateParameter(valid_612142, JString, required = false,
                                 default = nil)
  if valid_612142 != nil:
    section.add "X-Amz-Content-Sha256", valid_612142
  var valid_612143 = header.getOrDefault("X-Amz-Date")
  valid_612143 = validateParameter(valid_612143, JString, required = false,
                                 default = nil)
  if valid_612143 != nil:
    section.add "X-Amz-Date", valid_612143
  var valid_612144 = header.getOrDefault("X-Amz-Credential")
  valid_612144 = validateParameter(valid_612144, JString, required = false,
                                 default = nil)
  if valid_612144 != nil:
    section.add "X-Amz-Credential", valid_612144
  var valid_612145 = header.getOrDefault("X-Amz-Security-Token")
  valid_612145 = validateParameter(valid_612145, JString, required = false,
                                 default = nil)
  if valid_612145 != nil:
    section.add "X-Amz-Security-Token", valid_612145
  var valid_612146 = header.getOrDefault("X-Amz-Algorithm")
  valid_612146 = validateParameter(valid_612146, JString, required = false,
                                 default = nil)
  if valid_612146 != nil:
    section.add "X-Amz-Algorithm", valid_612146
  var valid_612147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612147 = validateParameter(valid_612147, JString, required = false,
                                 default = nil)
  if valid_612147 != nil:
    section.add "X-Amz-SignedHeaders", valid_612147
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString
  ##                  : The name of the target environment.
  ##   Status: JString
  ##         : To show only actions with a particular status, specify a status.
  ##   EnvironmentId: JString
  ##                : The environment ID of the target environment.
  section = newJObject()
  var valid_612148 = formData.getOrDefault("EnvironmentName")
  valid_612148 = validateParameter(valid_612148, JString, required = false,
                                 default = nil)
  if valid_612148 != nil:
    section.add "EnvironmentName", valid_612148
  var valid_612149 = formData.getOrDefault("Status")
  valid_612149 = validateParameter(valid_612149, JString, required = false,
                                 default = newJString("Scheduled"))
  if valid_612149 != nil:
    section.add "Status", valid_612149
  var valid_612150 = formData.getOrDefault("EnvironmentId")
  valid_612150 = validateParameter(valid_612150, JString, required = false,
                                 default = nil)
  if valid_612150 != nil:
    section.add "EnvironmentId", valid_612150
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612151: Call_PostDescribeEnvironmentManagedActions_612136;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists an environment's upcoming and in-progress managed actions.
  ## 
  let valid = call_612151.validator(path, query, header, formData, body)
  let scheme = call_612151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612151.url(scheme.get, call_612151.host, call_612151.base,
                         call_612151.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612151, url, valid)

proc call*(call_612152: Call_PostDescribeEnvironmentManagedActions_612136;
          EnvironmentName: string = "";
          Action: string = "DescribeEnvironmentManagedActions";
          Status: string = "Scheduled"; EnvironmentId: string = "";
          Version: string = "2010-12-01"): Recallable =
  ## postDescribeEnvironmentManagedActions
  ## Lists an environment's upcoming and in-progress managed actions.
  ##   EnvironmentName: string
  ##                  : The name of the target environment.
  ##   Action: string (required)
  ##   Status: string
  ##         : To show only actions with a particular status, specify a status.
  ##   EnvironmentId: string
  ##                : The environment ID of the target environment.
  ##   Version: string (required)
  var query_612153 = newJObject()
  var formData_612154 = newJObject()
  add(formData_612154, "EnvironmentName", newJString(EnvironmentName))
  add(query_612153, "Action", newJString(Action))
  add(formData_612154, "Status", newJString(Status))
  add(formData_612154, "EnvironmentId", newJString(EnvironmentId))
  add(query_612153, "Version", newJString(Version))
  result = call_612152.call(nil, query_612153, nil, formData_612154, nil)

var postDescribeEnvironmentManagedActions* = Call_PostDescribeEnvironmentManagedActions_612136(
    name: "postDescribeEnvironmentManagedActions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActions",
    validator: validate_PostDescribeEnvironmentManagedActions_612137, base: "/",
    url: url_PostDescribeEnvironmentManagedActions_612138,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentManagedActions_612118 = ref object of OpenApiRestCall_610659
proc url_GetDescribeEnvironmentManagedActions_612120(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEnvironmentManagedActions_612119(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists an environment's upcoming and in-progress managed actions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Status: JString
  ##         : To show only actions with a particular status, specify a status.
  ##   EnvironmentName: JString
  ##                  : The name of the target environment.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   EnvironmentId: JString
  ##                : The environment ID of the target environment.
  section = newJObject()
  var valid_612121 = query.getOrDefault("Status")
  valid_612121 = validateParameter(valid_612121, JString, required = false,
                                 default = newJString("Scheduled"))
  if valid_612121 != nil:
    section.add "Status", valid_612121
  var valid_612122 = query.getOrDefault("EnvironmentName")
  valid_612122 = validateParameter(valid_612122, JString, required = false,
                                 default = nil)
  if valid_612122 != nil:
    section.add "EnvironmentName", valid_612122
  var valid_612123 = query.getOrDefault("Action")
  valid_612123 = validateParameter(valid_612123, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActions"))
  if valid_612123 != nil:
    section.add "Action", valid_612123
  var valid_612124 = query.getOrDefault("Version")
  valid_612124 = validateParameter(valid_612124, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612124 != nil:
    section.add "Version", valid_612124
  var valid_612125 = query.getOrDefault("EnvironmentId")
  valid_612125 = validateParameter(valid_612125, JString, required = false,
                                 default = nil)
  if valid_612125 != nil:
    section.add "EnvironmentId", valid_612125
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612126 = header.getOrDefault("X-Amz-Signature")
  valid_612126 = validateParameter(valid_612126, JString, required = false,
                                 default = nil)
  if valid_612126 != nil:
    section.add "X-Amz-Signature", valid_612126
  var valid_612127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612127 = validateParameter(valid_612127, JString, required = false,
                                 default = nil)
  if valid_612127 != nil:
    section.add "X-Amz-Content-Sha256", valid_612127
  var valid_612128 = header.getOrDefault("X-Amz-Date")
  valid_612128 = validateParameter(valid_612128, JString, required = false,
                                 default = nil)
  if valid_612128 != nil:
    section.add "X-Amz-Date", valid_612128
  var valid_612129 = header.getOrDefault("X-Amz-Credential")
  valid_612129 = validateParameter(valid_612129, JString, required = false,
                                 default = nil)
  if valid_612129 != nil:
    section.add "X-Amz-Credential", valid_612129
  var valid_612130 = header.getOrDefault("X-Amz-Security-Token")
  valid_612130 = validateParameter(valid_612130, JString, required = false,
                                 default = nil)
  if valid_612130 != nil:
    section.add "X-Amz-Security-Token", valid_612130
  var valid_612131 = header.getOrDefault("X-Amz-Algorithm")
  valid_612131 = validateParameter(valid_612131, JString, required = false,
                                 default = nil)
  if valid_612131 != nil:
    section.add "X-Amz-Algorithm", valid_612131
  var valid_612132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612132 = validateParameter(valid_612132, JString, required = false,
                                 default = nil)
  if valid_612132 != nil:
    section.add "X-Amz-SignedHeaders", valid_612132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612133: Call_GetDescribeEnvironmentManagedActions_612118;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists an environment's upcoming and in-progress managed actions.
  ## 
  let valid = call_612133.validator(path, query, header, formData, body)
  let scheme = call_612133.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612133.url(scheme.get, call_612133.host, call_612133.base,
                         call_612133.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612133, url, valid)

proc call*(call_612134: Call_GetDescribeEnvironmentManagedActions_612118;
          Status: string = "Scheduled"; EnvironmentName: string = "";
          Action: string = "DescribeEnvironmentManagedActions";
          Version: string = "2010-12-01"; EnvironmentId: string = ""): Recallable =
  ## getDescribeEnvironmentManagedActions
  ## Lists an environment's upcoming and in-progress managed actions.
  ##   Status: string
  ##         : To show only actions with a particular status, specify a status.
  ##   EnvironmentName: string
  ##                  : The name of the target environment.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   EnvironmentId: string
  ##                : The environment ID of the target environment.
  var query_612135 = newJObject()
  add(query_612135, "Status", newJString(Status))
  add(query_612135, "EnvironmentName", newJString(EnvironmentName))
  add(query_612135, "Action", newJString(Action))
  add(query_612135, "Version", newJString(Version))
  add(query_612135, "EnvironmentId", newJString(EnvironmentId))
  result = call_612134.call(nil, query_612135, nil, nil, nil)

var getDescribeEnvironmentManagedActions* = Call_GetDescribeEnvironmentManagedActions_612118(
    name: "getDescribeEnvironmentManagedActions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActions",
    validator: validate_GetDescribeEnvironmentManagedActions_612119, base: "/",
    url: url_GetDescribeEnvironmentManagedActions_612120,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentResources_612172 = ref object of OpenApiRestCall_610659
proc url_PostDescribeEnvironmentResources_612174(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEnvironmentResources_612173(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns AWS resources for this environment.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612175 = query.getOrDefault("Action")
  valid_612175 = validateParameter(valid_612175, JString, required = true, default = newJString(
      "DescribeEnvironmentResources"))
  if valid_612175 != nil:
    section.add "Action", valid_612175
  var valid_612176 = query.getOrDefault("Version")
  valid_612176 = validateParameter(valid_612176, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612176 != nil:
    section.add "Version", valid_612176
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612177 = header.getOrDefault("X-Amz-Signature")
  valid_612177 = validateParameter(valid_612177, JString, required = false,
                                 default = nil)
  if valid_612177 != nil:
    section.add "X-Amz-Signature", valid_612177
  var valid_612178 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612178 = validateParameter(valid_612178, JString, required = false,
                                 default = nil)
  if valid_612178 != nil:
    section.add "X-Amz-Content-Sha256", valid_612178
  var valid_612179 = header.getOrDefault("X-Amz-Date")
  valid_612179 = validateParameter(valid_612179, JString, required = false,
                                 default = nil)
  if valid_612179 != nil:
    section.add "X-Amz-Date", valid_612179
  var valid_612180 = header.getOrDefault("X-Amz-Credential")
  valid_612180 = validateParameter(valid_612180, JString, required = false,
                                 default = nil)
  if valid_612180 != nil:
    section.add "X-Amz-Credential", valid_612180
  var valid_612181 = header.getOrDefault("X-Amz-Security-Token")
  valid_612181 = validateParameter(valid_612181, JString, required = false,
                                 default = nil)
  if valid_612181 != nil:
    section.add "X-Amz-Security-Token", valid_612181
  var valid_612182 = header.getOrDefault("X-Amz-Algorithm")
  valid_612182 = validateParameter(valid_612182, JString, required = false,
                                 default = nil)
  if valid_612182 != nil:
    section.add "X-Amz-Algorithm", valid_612182
  var valid_612183 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612183 = validateParameter(valid_612183, JString, required = false,
                                 default = nil)
  if valid_612183 != nil:
    section.add "X-Amz-SignedHeaders", valid_612183
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to retrieve AWS resource usage data.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to retrieve AWS resource usage data.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_612184 = formData.getOrDefault("EnvironmentName")
  valid_612184 = validateParameter(valid_612184, JString, required = false,
                                 default = nil)
  if valid_612184 != nil:
    section.add "EnvironmentName", valid_612184
  var valid_612185 = formData.getOrDefault("EnvironmentId")
  valid_612185 = validateParameter(valid_612185, JString, required = false,
                                 default = nil)
  if valid_612185 != nil:
    section.add "EnvironmentId", valid_612185
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612186: Call_PostDescribeEnvironmentResources_612172;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns AWS resources for this environment.
  ## 
  let valid = call_612186.validator(path, query, header, formData, body)
  let scheme = call_612186.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612186.url(scheme.get, call_612186.host, call_612186.base,
                         call_612186.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612186, url, valid)

proc call*(call_612187: Call_PostDescribeEnvironmentResources_612172;
          EnvironmentName: string = "";
          Action: string = "DescribeEnvironmentResources";
          EnvironmentId: string = ""; Version: string = "2010-12-01"): Recallable =
  ## postDescribeEnvironmentResources
  ## Returns AWS resources for this environment.
  ##   EnvironmentName: string
  ##                  : <p>The name of the environment to retrieve AWS resource usage data.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Action: string (required)
  ##   EnvironmentId: string
  ##                : <p>The ID of the environment to retrieve AWS resource usage data.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Version: string (required)
  var query_612188 = newJObject()
  var formData_612189 = newJObject()
  add(formData_612189, "EnvironmentName", newJString(EnvironmentName))
  add(query_612188, "Action", newJString(Action))
  add(formData_612189, "EnvironmentId", newJString(EnvironmentId))
  add(query_612188, "Version", newJString(Version))
  result = call_612187.call(nil, query_612188, nil, formData_612189, nil)

var postDescribeEnvironmentResources* = Call_PostDescribeEnvironmentResources_612172(
    name: "postDescribeEnvironmentResources", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentResources",
    validator: validate_PostDescribeEnvironmentResources_612173, base: "/",
    url: url_PostDescribeEnvironmentResources_612174,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentResources_612155 = ref object of OpenApiRestCall_610659
proc url_GetDescribeEnvironmentResources_612157(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEnvironmentResources_612156(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns AWS resources for this environment.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to retrieve AWS resource usage data.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to retrieve AWS resource usage data.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_612158 = query.getOrDefault("EnvironmentName")
  valid_612158 = validateParameter(valid_612158, JString, required = false,
                                 default = nil)
  if valid_612158 != nil:
    section.add "EnvironmentName", valid_612158
  var valid_612159 = query.getOrDefault("Action")
  valid_612159 = validateParameter(valid_612159, JString, required = true, default = newJString(
      "DescribeEnvironmentResources"))
  if valid_612159 != nil:
    section.add "Action", valid_612159
  var valid_612160 = query.getOrDefault("Version")
  valid_612160 = validateParameter(valid_612160, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612160 != nil:
    section.add "Version", valid_612160
  var valid_612161 = query.getOrDefault("EnvironmentId")
  valid_612161 = validateParameter(valid_612161, JString, required = false,
                                 default = nil)
  if valid_612161 != nil:
    section.add "EnvironmentId", valid_612161
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612162 = header.getOrDefault("X-Amz-Signature")
  valid_612162 = validateParameter(valid_612162, JString, required = false,
                                 default = nil)
  if valid_612162 != nil:
    section.add "X-Amz-Signature", valid_612162
  var valid_612163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612163 = validateParameter(valid_612163, JString, required = false,
                                 default = nil)
  if valid_612163 != nil:
    section.add "X-Amz-Content-Sha256", valid_612163
  var valid_612164 = header.getOrDefault("X-Amz-Date")
  valid_612164 = validateParameter(valid_612164, JString, required = false,
                                 default = nil)
  if valid_612164 != nil:
    section.add "X-Amz-Date", valid_612164
  var valid_612165 = header.getOrDefault("X-Amz-Credential")
  valid_612165 = validateParameter(valid_612165, JString, required = false,
                                 default = nil)
  if valid_612165 != nil:
    section.add "X-Amz-Credential", valid_612165
  var valid_612166 = header.getOrDefault("X-Amz-Security-Token")
  valid_612166 = validateParameter(valid_612166, JString, required = false,
                                 default = nil)
  if valid_612166 != nil:
    section.add "X-Amz-Security-Token", valid_612166
  var valid_612167 = header.getOrDefault("X-Amz-Algorithm")
  valid_612167 = validateParameter(valid_612167, JString, required = false,
                                 default = nil)
  if valid_612167 != nil:
    section.add "X-Amz-Algorithm", valid_612167
  var valid_612168 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612168 = validateParameter(valid_612168, JString, required = false,
                                 default = nil)
  if valid_612168 != nil:
    section.add "X-Amz-SignedHeaders", valid_612168
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612169: Call_GetDescribeEnvironmentResources_612155;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns AWS resources for this environment.
  ## 
  let valid = call_612169.validator(path, query, header, formData, body)
  let scheme = call_612169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612169.url(scheme.get, call_612169.host, call_612169.base,
                         call_612169.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612169, url, valid)

proc call*(call_612170: Call_GetDescribeEnvironmentResources_612155;
          EnvironmentName: string = "";
          Action: string = "DescribeEnvironmentResources";
          Version: string = "2010-12-01"; EnvironmentId: string = ""): Recallable =
  ## getDescribeEnvironmentResources
  ## Returns AWS resources for this environment.
  ##   EnvironmentName: string
  ##                  : <p>The name of the environment to retrieve AWS resource usage data.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   EnvironmentId: string
  ##                : <p>The ID of the environment to retrieve AWS resource usage data.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  var query_612171 = newJObject()
  add(query_612171, "EnvironmentName", newJString(EnvironmentName))
  add(query_612171, "Action", newJString(Action))
  add(query_612171, "Version", newJString(Version))
  add(query_612171, "EnvironmentId", newJString(EnvironmentId))
  result = call_612170.call(nil, query_612171, nil, nil, nil)

var getDescribeEnvironmentResources* = Call_GetDescribeEnvironmentResources_612155(
    name: "getDescribeEnvironmentResources", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentResources",
    validator: validate_GetDescribeEnvironmentResources_612156, base: "/",
    url: url_GetDescribeEnvironmentResources_612157,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironments_612213 = ref object of OpenApiRestCall_610659
proc url_PostDescribeEnvironments_612215(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEnvironments_612214(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns descriptions for existing environments.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612216 = query.getOrDefault("Action")
  valid_612216 = validateParameter(valid_612216, JString, required = true,
                                 default = newJString("DescribeEnvironments"))
  if valid_612216 != nil:
    section.add "Action", valid_612216
  var valid_612217 = query.getOrDefault("Version")
  valid_612217 = validateParameter(valid_612217, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612217 != nil:
    section.add "Version", valid_612217
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612218 = header.getOrDefault("X-Amz-Signature")
  valid_612218 = validateParameter(valid_612218, JString, required = false,
                                 default = nil)
  if valid_612218 != nil:
    section.add "X-Amz-Signature", valid_612218
  var valid_612219 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612219 = validateParameter(valid_612219, JString, required = false,
                                 default = nil)
  if valid_612219 != nil:
    section.add "X-Amz-Content-Sha256", valid_612219
  var valid_612220 = header.getOrDefault("X-Amz-Date")
  valid_612220 = validateParameter(valid_612220, JString, required = false,
                                 default = nil)
  if valid_612220 != nil:
    section.add "X-Amz-Date", valid_612220
  var valid_612221 = header.getOrDefault("X-Amz-Credential")
  valid_612221 = validateParameter(valid_612221, JString, required = false,
                                 default = nil)
  if valid_612221 != nil:
    section.add "X-Amz-Credential", valid_612221
  var valid_612222 = header.getOrDefault("X-Amz-Security-Token")
  valid_612222 = validateParameter(valid_612222, JString, required = false,
                                 default = nil)
  if valid_612222 != nil:
    section.add "X-Amz-Security-Token", valid_612222
  var valid_612223 = header.getOrDefault("X-Amz-Algorithm")
  valid_612223 = validateParameter(valid_612223, JString, required = false,
                                 default = nil)
  if valid_612223 != nil:
    section.add "X-Amz-Algorithm", valid_612223
  var valid_612224 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612224 = validateParameter(valid_612224, JString, required = false,
                                 default = nil)
  if valid_612224 != nil:
    section.add "X-Amz-SignedHeaders", valid_612224
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentNames: JArray
  ##                   : If specified, AWS Elastic Beanstalk restricts the returned descriptions to include only those that have the specified names.
  ##   MaxRecords: JInt
  ##             : <p>For a paginated request. Specify a maximum number of environments to include in each response.</p> <p>If no <code>MaxRecords</code> is specified, all available environments are retrieved in a single response.</p>
  ##   VersionLabel: JString
  ##               : If specified, AWS Elastic Beanstalk restricts the returned descriptions to include only those that are associated with this application version.
  ##   NextToken: JString
  ##            : <p>For a paginated request. Specify a token from a previous response page to retrieve the next response page. All other parameter values must be identical to the ones specified in the initial request.</p> <p>If no <code>NextToken</code> is specified, the first page is retrieved.</p>
  ##   ApplicationName: JString
  ##                  : If specified, AWS Elastic Beanstalk restricts the returned descriptions to include only those that are associated with this application.
  ##   IncludedDeletedBackTo: JString
  ##                        :  If specified when <code>IncludeDeleted</code> is set to <code>true</code>, then environments deleted after this date are displayed. 
  ##   EnvironmentIds: JArray
  ##                 : If specified, AWS Elastic Beanstalk restricts the returned descriptions to include only those that have the specified IDs.
  ##   IncludeDeleted: JBool
  ##                 : <p>Indicates whether to include deleted environments:</p> <p> <code>true</code>: Environments that have been deleted after <code>IncludedDeletedBackTo</code> are displayed.</p> <p> <code>false</code>: Do not include deleted environments.</p>
  section = newJObject()
  var valid_612225 = formData.getOrDefault("EnvironmentNames")
  valid_612225 = validateParameter(valid_612225, JArray, required = false,
                                 default = nil)
  if valid_612225 != nil:
    section.add "EnvironmentNames", valid_612225
  var valid_612226 = formData.getOrDefault("MaxRecords")
  valid_612226 = validateParameter(valid_612226, JInt, required = false, default = nil)
  if valid_612226 != nil:
    section.add "MaxRecords", valid_612226
  var valid_612227 = formData.getOrDefault("VersionLabel")
  valid_612227 = validateParameter(valid_612227, JString, required = false,
                                 default = nil)
  if valid_612227 != nil:
    section.add "VersionLabel", valid_612227
  var valid_612228 = formData.getOrDefault("NextToken")
  valid_612228 = validateParameter(valid_612228, JString, required = false,
                                 default = nil)
  if valid_612228 != nil:
    section.add "NextToken", valid_612228
  var valid_612229 = formData.getOrDefault("ApplicationName")
  valid_612229 = validateParameter(valid_612229, JString, required = false,
                                 default = nil)
  if valid_612229 != nil:
    section.add "ApplicationName", valid_612229
  var valid_612230 = formData.getOrDefault("IncludedDeletedBackTo")
  valid_612230 = validateParameter(valid_612230, JString, required = false,
                                 default = nil)
  if valid_612230 != nil:
    section.add "IncludedDeletedBackTo", valid_612230
  var valid_612231 = formData.getOrDefault("EnvironmentIds")
  valid_612231 = validateParameter(valid_612231, JArray, required = false,
                                 default = nil)
  if valid_612231 != nil:
    section.add "EnvironmentIds", valid_612231
  var valid_612232 = formData.getOrDefault("IncludeDeleted")
  valid_612232 = validateParameter(valid_612232, JBool, required = false, default = nil)
  if valid_612232 != nil:
    section.add "IncludeDeleted", valid_612232
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612233: Call_PostDescribeEnvironments_612213; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns descriptions for existing environments.
  ## 
  let valid = call_612233.validator(path, query, header, formData, body)
  let scheme = call_612233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612233.url(scheme.get, call_612233.host, call_612233.base,
                         call_612233.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612233, url, valid)

proc call*(call_612234: Call_PostDescribeEnvironments_612213;
          EnvironmentNames: JsonNode = nil; MaxRecords: int = 0;
          VersionLabel: string = ""; NextToken: string = "";
          ApplicationName: string = ""; Action: string = "DescribeEnvironments";
          Version: string = "2010-12-01"; IncludedDeletedBackTo: string = "";
          EnvironmentIds: JsonNode = nil; IncludeDeleted: bool = false): Recallable =
  ## postDescribeEnvironments
  ## Returns descriptions for existing environments.
  ##   EnvironmentNames: JArray
  ##                   : If specified, AWS Elastic Beanstalk restricts the returned descriptions to include only those that have the specified names.
  ##   MaxRecords: int
  ##             : <p>For a paginated request. Specify a maximum number of environments to include in each response.</p> <p>If no <code>MaxRecords</code> is specified, all available environments are retrieved in a single response.</p>
  ##   VersionLabel: string
  ##               : If specified, AWS Elastic Beanstalk restricts the returned descriptions to include only those that are associated with this application version.
  ##   NextToken: string
  ##            : <p>For a paginated request. Specify a token from a previous response page to retrieve the next response page. All other parameter values must be identical to the ones specified in the initial request.</p> <p>If no <code>NextToken</code> is specified, the first page is retrieved.</p>
  ##   ApplicationName: string
  ##                  : If specified, AWS Elastic Beanstalk restricts the returned descriptions to include only those that are associated with this application.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   IncludedDeletedBackTo: string
  ##                        :  If specified when <code>IncludeDeleted</code> is set to <code>true</code>, then environments deleted after this date are displayed. 
  ##   EnvironmentIds: JArray
  ##                 : If specified, AWS Elastic Beanstalk restricts the returned descriptions to include only those that have the specified IDs.
  ##   IncludeDeleted: bool
  ##                 : <p>Indicates whether to include deleted environments:</p> <p> <code>true</code>: Environments that have been deleted after <code>IncludedDeletedBackTo</code> are displayed.</p> <p> <code>false</code>: Do not include deleted environments.</p>
  var query_612235 = newJObject()
  var formData_612236 = newJObject()
  if EnvironmentNames != nil:
    formData_612236.add "EnvironmentNames", EnvironmentNames
  add(formData_612236, "MaxRecords", newJInt(MaxRecords))
  add(formData_612236, "VersionLabel", newJString(VersionLabel))
  add(formData_612236, "NextToken", newJString(NextToken))
  add(formData_612236, "ApplicationName", newJString(ApplicationName))
  add(query_612235, "Action", newJString(Action))
  add(query_612235, "Version", newJString(Version))
  add(formData_612236, "IncludedDeletedBackTo", newJString(IncludedDeletedBackTo))
  if EnvironmentIds != nil:
    formData_612236.add "EnvironmentIds", EnvironmentIds
  add(formData_612236, "IncludeDeleted", newJBool(IncludeDeleted))
  result = call_612234.call(nil, query_612235, nil, formData_612236, nil)

var postDescribeEnvironments* = Call_PostDescribeEnvironments_612213(
    name: "postDescribeEnvironments", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironments",
    validator: validate_PostDescribeEnvironments_612214, base: "/",
    url: url_PostDescribeEnvironments_612215, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironments_612190 = ref object of OpenApiRestCall_610659
proc url_GetDescribeEnvironments_612192(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEnvironments_612191(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns descriptions for existing environments.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ApplicationName: JString
  ##                  : If specified, AWS Elastic Beanstalk restricts the returned descriptions to include only those that are associated with this application.
  ##   VersionLabel: JString
  ##               : If specified, AWS Elastic Beanstalk restricts the returned descriptions to include only those that are associated with this application version.
  ##   IncludeDeleted: JBool
  ##                 : <p>Indicates whether to include deleted environments:</p> <p> <code>true</code>: Environments that have been deleted after <code>IncludedDeletedBackTo</code> are displayed.</p> <p> <code>false</code>: Do not include deleted environments.</p>
  ##   NextToken: JString
  ##            : <p>For a paginated request. Specify a token from a previous response page to retrieve the next response page. All other parameter values must be identical to the ones specified in the initial request.</p> <p>If no <code>NextToken</code> is specified, the first page is retrieved.</p>
  ##   EnvironmentNames: JArray
  ##                   : If specified, AWS Elastic Beanstalk restricts the returned descriptions to include only those that have the specified names.
  ##   Action: JString (required)
  ##   EnvironmentIds: JArray
  ##                 : If specified, AWS Elastic Beanstalk restricts the returned descriptions to include only those that have the specified IDs.
  ##   IncludedDeletedBackTo: JString
  ##                        :  If specified when <code>IncludeDeleted</code> is set to <code>true</code>, then environments deleted after this date are displayed. 
  ##   Version: JString (required)
  ##   MaxRecords: JInt
  ##             : <p>For a paginated request. Specify a maximum number of environments to include in each response.</p> <p>If no <code>MaxRecords</code> is specified, all available environments are retrieved in a single response.</p>
  section = newJObject()
  var valid_612193 = query.getOrDefault("ApplicationName")
  valid_612193 = validateParameter(valid_612193, JString, required = false,
                                 default = nil)
  if valid_612193 != nil:
    section.add "ApplicationName", valid_612193
  var valid_612194 = query.getOrDefault("VersionLabel")
  valid_612194 = validateParameter(valid_612194, JString, required = false,
                                 default = nil)
  if valid_612194 != nil:
    section.add "VersionLabel", valid_612194
  var valid_612195 = query.getOrDefault("IncludeDeleted")
  valid_612195 = validateParameter(valid_612195, JBool, required = false, default = nil)
  if valid_612195 != nil:
    section.add "IncludeDeleted", valid_612195
  var valid_612196 = query.getOrDefault("NextToken")
  valid_612196 = validateParameter(valid_612196, JString, required = false,
                                 default = nil)
  if valid_612196 != nil:
    section.add "NextToken", valid_612196
  var valid_612197 = query.getOrDefault("EnvironmentNames")
  valid_612197 = validateParameter(valid_612197, JArray, required = false,
                                 default = nil)
  if valid_612197 != nil:
    section.add "EnvironmentNames", valid_612197
  var valid_612198 = query.getOrDefault("Action")
  valid_612198 = validateParameter(valid_612198, JString, required = true,
                                 default = newJString("DescribeEnvironments"))
  if valid_612198 != nil:
    section.add "Action", valid_612198
  var valid_612199 = query.getOrDefault("EnvironmentIds")
  valid_612199 = validateParameter(valid_612199, JArray, required = false,
                                 default = nil)
  if valid_612199 != nil:
    section.add "EnvironmentIds", valid_612199
  var valid_612200 = query.getOrDefault("IncludedDeletedBackTo")
  valid_612200 = validateParameter(valid_612200, JString, required = false,
                                 default = nil)
  if valid_612200 != nil:
    section.add "IncludedDeletedBackTo", valid_612200
  var valid_612201 = query.getOrDefault("Version")
  valid_612201 = validateParameter(valid_612201, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612201 != nil:
    section.add "Version", valid_612201
  var valid_612202 = query.getOrDefault("MaxRecords")
  valid_612202 = validateParameter(valid_612202, JInt, required = false, default = nil)
  if valid_612202 != nil:
    section.add "MaxRecords", valid_612202
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612203 = header.getOrDefault("X-Amz-Signature")
  valid_612203 = validateParameter(valid_612203, JString, required = false,
                                 default = nil)
  if valid_612203 != nil:
    section.add "X-Amz-Signature", valid_612203
  var valid_612204 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612204 = validateParameter(valid_612204, JString, required = false,
                                 default = nil)
  if valid_612204 != nil:
    section.add "X-Amz-Content-Sha256", valid_612204
  var valid_612205 = header.getOrDefault("X-Amz-Date")
  valid_612205 = validateParameter(valid_612205, JString, required = false,
                                 default = nil)
  if valid_612205 != nil:
    section.add "X-Amz-Date", valid_612205
  var valid_612206 = header.getOrDefault("X-Amz-Credential")
  valid_612206 = validateParameter(valid_612206, JString, required = false,
                                 default = nil)
  if valid_612206 != nil:
    section.add "X-Amz-Credential", valid_612206
  var valid_612207 = header.getOrDefault("X-Amz-Security-Token")
  valid_612207 = validateParameter(valid_612207, JString, required = false,
                                 default = nil)
  if valid_612207 != nil:
    section.add "X-Amz-Security-Token", valid_612207
  var valid_612208 = header.getOrDefault("X-Amz-Algorithm")
  valid_612208 = validateParameter(valid_612208, JString, required = false,
                                 default = nil)
  if valid_612208 != nil:
    section.add "X-Amz-Algorithm", valid_612208
  var valid_612209 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612209 = validateParameter(valid_612209, JString, required = false,
                                 default = nil)
  if valid_612209 != nil:
    section.add "X-Amz-SignedHeaders", valid_612209
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612210: Call_GetDescribeEnvironments_612190; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns descriptions for existing environments.
  ## 
  let valid = call_612210.validator(path, query, header, formData, body)
  let scheme = call_612210.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612210.url(scheme.get, call_612210.host, call_612210.base,
                         call_612210.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612210, url, valid)

proc call*(call_612211: Call_GetDescribeEnvironments_612190;
          ApplicationName: string = ""; VersionLabel: string = "";
          IncludeDeleted: bool = false; NextToken: string = "";
          EnvironmentNames: JsonNode = nil; Action: string = "DescribeEnvironments";
          EnvironmentIds: JsonNode = nil; IncludedDeletedBackTo: string = "";
          Version: string = "2010-12-01"; MaxRecords: int = 0): Recallable =
  ## getDescribeEnvironments
  ## Returns descriptions for existing environments.
  ##   ApplicationName: string
  ##                  : If specified, AWS Elastic Beanstalk restricts the returned descriptions to include only those that are associated with this application.
  ##   VersionLabel: string
  ##               : If specified, AWS Elastic Beanstalk restricts the returned descriptions to include only those that are associated with this application version.
  ##   IncludeDeleted: bool
  ##                 : <p>Indicates whether to include deleted environments:</p> <p> <code>true</code>: Environments that have been deleted after <code>IncludedDeletedBackTo</code> are displayed.</p> <p> <code>false</code>: Do not include deleted environments.</p>
  ##   NextToken: string
  ##            : <p>For a paginated request. Specify a token from a previous response page to retrieve the next response page. All other parameter values must be identical to the ones specified in the initial request.</p> <p>If no <code>NextToken</code> is specified, the first page is retrieved.</p>
  ##   EnvironmentNames: JArray
  ##                   : If specified, AWS Elastic Beanstalk restricts the returned descriptions to include only those that have the specified names.
  ##   Action: string (required)
  ##   EnvironmentIds: JArray
  ##                 : If specified, AWS Elastic Beanstalk restricts the returned descriptions to include only those that have the specified IDs.
  ##   IncludedDeletedBackTo: string
  ##                        :  If specified when <code>IncludeDeleted</code> is set to <code>true</code>, then environments deleted after this date are displayed. 
  ##   Version: string (required)
  ##   MaxRecords: int
  ##             : <p>For a paginated request. Specify a maximum number of environments to include in each response.</p> <p>If no <code>MaxRecords</code> is specified, all available environments are retrieved in a single response.</p>
  var query_612212 = newJObject()
  add(query_612212, "ApplicationName", newJString(ApplicationName))
  add(query_612212, "VersionLabel", newJString(VersionLabel))
  add(query_612212, "IncludeDeleted", newJBool(IncludeDeleted))
  add(query_612212, "NextToken", newJString(NextToken))
  if EnvironmentNames != nil:
    query_612212.add "EnvironmentNames", EnvironmentNames
  add(query_612212, "Action", newJString(Action))
  if EnvironmentIds != nil:
    query_612212.add "EnvironmentIds", EnvironmentIds
  add(query_612212, "IncludedDeletedBackTo", newJString(IncludedDeletedBackTo))
  add(query_612212, "Version", newJString(Version))
  add(query_612212, "MaxRecords", newJInt(MaxRecords))
  result = call_612211.call(nil, query_612212, nil, nil, nil)

var getDescribeEnvironments* = Call_GetDescribeEnvironments_612190(
    name: "getDescribeEnvironments", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironments",
    validator: validate_GetDescribeEnvironments_612191, base: "/",
    url: url_GetDescribeEnvironments_612192, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_612264 = ref object of OpenApiRestCall_610659
proc url_PostDescribeEvents_612266(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEvents_612265(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Returns list of event descriptions matching criteria up to the last 6 weeks.</p> <note> <p>This action returns the most recent 1,000 events from the specified <code>NextToken</code>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612267 = query.getOrDefault("Action")
  valid_612267 = validateParameter(valid_612267, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_612267 != nil:
    section.add "Action", valid_612267
  var valid_612268 = query.getOrDefault("Version")
  valid_612268 = validateParameter(valid_612268, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612268 != nil:
    section.add "Version", valid_612268
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612269 = header.getOrDefault("X-Amz-Signature")
  valid_612269 = validateParameter(valid_612269, JString, required = false,
                                 default = nil)
  if valid_612269 != nil:
    section.add "X-Amz-Signature", valid_612269
  var valid_612270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612270 = validateParameter(valid_612270, JString, required = false,
                                 default = nil)
  if valid_612270 != nil:
    section.add "X-Amz-Content-Sha256", valid_612270
  var valid_612271 = header.getOrDefault("X-Amz-Date")
  valid_612271 = validateParameter(valid_612271, JString, required = false,
                                 default = nil)
  if valid_612271 != nil:
    section.add "X-Amz-Date", valid_612271
  var valid_612272 = header.getOrDefault("X-Amz-Credential")
  valid_612272 = validateParameter(valid_612272, JString, required = false,
                                 default = nil)
  if valid_612272 != nil:
    section.add "X-Amz-Credential", valid_612272
  var valid_612273 = header.getOrDefault("X-Amz-Security-Token")
  valid_612273 = validateParameter(valid_612273, JString, required = false,
                                 default = nil)
  if valid_612273 != nil:
    section.add "X-Amz-Security-Token", valid_612273
  var valid_612274 = header.getOrDefault("X-Amz-Algorithm")
  valid_612274 = validateParameter(valid_612274, JString, required = false,
                                 default = nil)
  if valid_612274 != nil:
    section.add "X-Amz-Algorithm", valid_612274
  var valid_612275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612275 = validateParameter(valid_612275, JString, required = false,
                                 default = nil)
  if valid_612275 != nil:
    section.add "X-Amz-SignedHeaders", valid_612275
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Pagination token. If specified, the events return the next batch of results.
  ##   MaxRecords: JInt
  ##             : Specifies the maximum number of events that can be returned, beginning with the most recent event.
  ##   VersionLabel: JString
  ##               : If specified, AWS Elastic Beanstalk restricts the returned descriptions to those associated with this application version.
  ##   EnvironmentName: JString
  ##                  : If specified, AWS Elastic Beanstalk restricts the returned descriptions to those associated with this environment.
  ##   TemplateName: JString
  ##               : If specified, AWS Elastic Beanstalk restricts the returned descriptions to those that are associated with this environment configuration.
  ##   ApplicationName: JString
  ##                  : If specified, AWS Elastic Beanstalk restricts the returned descriptions to include only those associated with this application.
  ##   EndTime: JString
  ##          :  If specified, AWS Elastic Beanstalk restricts the returned descriptions to those that occur up to, but not including, the <code>EndTime</code>. 
  ##   StartTime: JString
  ##            : If specified, AWS Elastic Beanstalk restricts the returned descriptions to those that occur on or after this time.
  ##   Severity: JString
  ##           : If specified, limits the events returned from this call to include only those with the specified severity or higher.
  ##   RequestId: JString
  ##            : If specified, AWS Elastic Beanstalk restricts the described events to include only those associated with this request ID.
  ##   EnvironmentId: JString
  ##                : If specified, AWS Elastic Beanstalk restricts the returned descriptions to those associated with this environment.
  ##   PlatformArn: JString
  ##              : The ARN of the version of the custom platform.
  section = newJObject()
  var valid_612276 = formData.getOrDefault("NextToken")
  valid_612276 = validateParameter(valid_612276, JString, required = false,
                                 default = nil)
  if valid_612276 != nil:
    section.add "NextToken", valid_612276
  var valid_612277 = formData.getOrDefault("MaxRecords")
  valid_612277 = validateParameter(valid_612277, JInt, required = false, default = nil)
  if valid_612277 != nil:
    section.add "MaxRecords", valid_612277
  var valid_612278 = formData.getOrDefault("VersionLabel")
  valid_612278 = validateParameter(valid_612278, JString, required = false,
                                 default = nil)
  if valid_612278 != nil:
    section.add "VersionLabel", valid_612278
  var valid_612279 = formData.getOrDefault("EnvironmentName")
  valid_612279 = validateParameter(valid_612279, JString, required = false,
                                 default = nil)
  if valid_612279 != nil:
    section.add "EnvironmentName", valid_612279
  var valid_612280 = formData.getOrDefault("TemplateName")
  valid_612280 = validateParameter(valid_612280, JString, required = false,
                                 default = nil)
  if valid_612280 != nil:
    section.add "TemplateName", valid_612280
  var valid_612281 = formData.getOrDefault("ApplicationName")
  valid_612281 = validateParameter(valid_612281, JString, required = false,
                                 default = nil)
  if valid_612281 != nil:
    section.add "ApplicationName", valid_612281
  var valid_612282 = formData.getOrDefault("EndTime")
  valid_612282 = validateParameter(valid_612282, JString, required = false,
                                 default = nil)
  if valid_612282 != nil:
    section.add "EndTime", valid_612282
  var valid_612283 = formData.getOrDefault("StartTime")
  valid_612283 = validateParameter(valid_612283, JString, required = false,
                                 default = nil)
  if valid_612283 != nil:
    section.add "StartTime", valid_612283
  var valid_612284 = formData.getOrDefault("Severity")
  valid_612284 = validateParameter(valid_612284, JString, required = false,
                                 default = newJString("TRACE"))
  if valid_612284 != nil:
    section.add "Severity", valid_612284
  var valid_612285 = formData.getOrDefault("RequestId")
  valid_612285 = validateParameter(valid_612285, JString, required = false,
                                 default = nil)
  if valid_612285 != nil:
    section.add "RequestId", valid_612285
  var valid_612286 = formData.getOrDefault("EnvironmentId")
  valid_612286 = validateParameter(valid_612286, JString, required = false,
                                 default = nil)
  if valid_612286 != nil:
    section.add "EnvironmentId", valid_612286
  var valid_612287 = formData.getOrDefault("PlatformArn")
  valid_612287 = validateParameter(valid_612287, JString, required = false,
                                 default = nil)
  if valid_612287 != nil:
    section.add "PlatformArn", valid_612287
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612288: Call_PostDescribeEvents_612264; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns list of event descriptions matching criteria up to the last 6 weeks.</p> <note> <p>This action returns the most recent 1,000 events from the specified <code>NextToken</code>.</p> </note>
  ## 
  let valid = call_612288.validator(path, query, header, formData, body)
  let scheme = call_612288.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612288.url(scheme.get, call_612288.host, call_612288.base,
                         call_612288.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612288, url, valid)

proc call*(call_612289: Call_PostDescribeEvents_612264; NextToken: string = "";
          MaxRecords: int = 0; VersionLabel: string = ""; EnvironmentName: string = "";
          TemplateName: string = ""; ApplicationName: string = ""; EndTime: string = "";
          StartTime: string = ""; Severity: string = "TRACE";
          Action: string = "DescribeEvents"; RequestId: string = "";
          EnvironmentId: string = ""; Version: string = "2010-12-01";
          PlatformArn: string = ""): Recallable =
  ## postDescribeEvents
  ## <p>Returns list of event descriptions matching criteria up to the last 6 weeks.</p> <note> <p>This action returns the most recent 1,000 events from the specified <code>NextToken</code>.</p> </note>
  ##   NextToken: string
  ##            : Pagination token. If specified, the events return the next batch of results.
  ##   MaxRecords: int
  ##             : Specifies the maximum number of events that can be returned, beginning with the most recent event.
  ##   VersionLabel: string
  ##               : If specified, AWS Elastic Beanstalk restricts the returned descriptions to those associated with this application version.
  ##   EnvironmentName: string
  ##                  : If specified, AWS Elastic Beanstalk restricts the returned descriptions to those associated with this environment.
  ##   TemplateName: string
  ##               : If specified, AWS Elastic Beanstalk restricts the returned descriptions to those that are associated with this environment configuration.
  ##   ApplicationName: string
  ##                  : If specified, AWS Elastic Beanstalk restricts the returned descriptions to include only those associated with this application.
  ##   EndTime: string
  ##          :  If specified, AWS Elastic Beanstalk restricts the returned descriptions to those that occur up to, but not including, the <code>EndTime</code>. 
  ##   StartTime: string
  ##            : If specified, AWS Elastic Beanstalk restricts the returned descriptions to those that occur on or after this time.
  ##   Severity: string
  ##           : If specified, limits the events returned from this call to include only those with the specified severity or higher.
  ##   Action: string (required)
  ##   RequestId: string
  ##            : If specified, AWS Elastic Beanstalk restricts the described events to include only those associated with this request ID.
  ##   EnvironmentId: string
  ##                : If specified, AWS Elastic Beanstalk restricts the returned descriptions to those associated with this environment.
  ##   Version: string (required)
  ##   PlatformArn: string
  ##              : The ARN of the version of the custom platform.
  var query_612290 = newJObject()
  var formData_612291 = newJObject()
  add(formData_612291, "NextToken", newJString(NextToken))
  add(formData_612291, "MaxRecords", newJInt(MaxRecords))
  add(formData_612291, "VersionLabel", newJString(VersionLabel))
  add(formData_612291, "EnvironmentName", newJString(EnvironmentName))
  add(formData_612291, "TemplateName", newJString(TemplateName))
  add(formData_612291, "ApplicationName", newJString(ApplicationName))
  add(formData_612291, "EndTime", newJString(EndTime))
  add(formData_612291, "StartTime", newJString(StartTime))
  add(formData_612291, "Severity", newJString(Severity))
  add(query_612290, "Action", newJString(Action))
  add(formData_612291, "RequestId", newJString(RequestId))
  add(formData_612291, "EnvironmentId", newJString(EnvironmentId))
  add(query_612290, "Version", newJString(Version))
  add(formData_612291, "PlatformArn", newJString(PlatformArn))
  result = call_612289.call(nil, query_612290, nil, formData_612291, nil)

var postDescribeEvents* = Call_PostDescribeEvents_612264(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_612265, base: "/",
    url: url_PostDescribeEvents_612266, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_612237 = ref object of OpenApiRestCall_610659
proc url_GetDescribeEvents_612239(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEvents_612238(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Returns list of event descriptions matching criteria up to the last 6 weeks.</p> <note> <p>This action returns the most recent 1,000 events from the specified <code>NextToken</code>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   RequestId: JString
  ##            : If specified, AWS Elastic Beanstalk restricts the described events to include only those associated with this request ID.
  ##   ApplicationName: JString
  ##                  : If specified, AWS Elastic Beanstalk restricts the returned descriptions to include only those associated with this application.
  ##   VersionLabel: JString
  ##               : If specified, AWS Elastic Beanstalk restricts the returned descriptions to those associated with this application version.
  ##   NextToken: JString
  ##            : Pagination token. If specified, the events return the next batch of results.
  ##   Severity: JString
  ##           : If specified, limits the events returned from this call to include only those with the specified severity or higher.
  ##   EnvironmentName: JString
  ##                  : If specified, AWS Elastic Beanstalk restricts the returned descriptions to those associated with this environment.
  ##   Action: JString (required)
  ##   StartTime: JString
  ##            : If specified, AWS Elastic Beanstalk restricts the returned descriptions to those that occur on or after this time.
  ##   PlatformArn: JString
  ##              : The ARN of the version of the custom platform.
  ##   EndTime: JString
  ##          :  If specified, AWS Elastic Beanstalk restricts the returned descriptions to those that occur up to, but not including, the <code>EndTime</code>. 
  ##   Version: JString (required)
  ##   TemplateName: JString
  ##               : If specified, AWS Elastic Beanstalk restricts the returned descriptions to those that are associated with this environment configuration.
  ##   MaxRecords: JInt
  ##             : Specifies the maximum number of events that can be returned, beginning with the most recent event.
  ##   EnvironmentId: JString
  ##                : If specified, AWS Elastic Beanstalk restricts the returned descriptions to those associated with this environment.
  section = newJObject()
  var valid_612240 = query.getOrDefault("RequestId")
  valid_612240 = validateParameter(valid_612240, JString, required = false,
                                 default = nil)
  if valid_612240 != nil:
    section.add "RequestId", valid_612240
  var valid_612241 = query.getOrDefault("ApplicationName")
  valid_612241 = validateParameter(valid_612241, JString, required = false,
                                 default = nil)
  if valid_612241 != nil:
    section.add "ApplicationName", valid_612241
  var valid_612242 = query.getOrDefault("VersionLabel")
  valid_612242 = validateParameter(valid_612242, JString, required = false,
                                 default = nil)
  if valid_612242 != nil:
    section.add "VersionLabel", valid_612242
  var valid_612243 = query.getOrDefault("NextToken")
  valid_612243 = validateParameter(valid_612243, JString, required = false,
                                 default = nil)
  if valid_612243 != nil:
    section.add "NextToken", valid_612243
  var valid_612244 = query.getOrDefault("Severity")
  valid_612244 = validateParameter(valid_612244, JString, required = false,
                                 default = newJString("TRACE"))
  if valid_612244 != nil:
    section.add "Severity", valid_612244
  var valid_612245 = query.getOrDefault("EnvironmentName")
  valid_612245 = validateParameter(valid_612245, JString, required = false,
                                 default = nil)
  if valid_612245 != nil:
    section.add "EnvironmentName", valid_612245
  var valid_612246 = query.getOrDefault("Action")
  valid_612246 = validateParameter(valid_612246, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_612246 != nil:
    section.add "Action", valid_612246
  var valid_612247 = query.getOrDefault("StartTime")
  valid_612247 = validateParameter(valid_612247, JString, required = false,
                                 default = nil)
  if valid_612247 != nil:
    section.add "StartTime", valid_612247
  var valid_612248 = query.getOrDefault("PlatformArn")
  valid_612248 = validateParameter(valid_612248, JString, required = false,
                                 default = nil)
  if valid_612248 != nil:
    section.add "PlatformArn", valid_612248
  var valid_612249 = query.getOrDefault("EndTime")
  valid_612249 = validateParameter(valid_612249, JString, required = false,
                                 default = nil)
  if valid_612249 != nil:
    section.add "EndTime", valid_612249
  var valid_612250 = query.getOrDefault("Version")
  valid_612250 = validateParameter(valid_612250, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612250 != nil:
    section.add "Version", valid_612250
  var valid_612251 = query.getOrDefault("TemplateName")
  valid_612251 = validateParameter(valid_612251, JString, required = false,
                                 default = nil)
  if valid_612251 != nil:
    section.add "TemplateName", valid_612251
  var valid_612252 = query.getOrDefault("MaxRecords")
  valid_612252 = validateParameter(valid_612252, JInt, required = false, default = nil)
  if valid_612252 != nil:
    section.add "MaxRecords", valid_612252
  var valid_612253 = query.getOrDefault("EnvironmentId")
  valid_612253 = validateParameter(valid_612253, JString, required = false,
                                 default = nil)
  if valid_612253 != nil:
    section.add "EnvironmentId", valid_612253
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612254 = header.getOrDefault("X-Amz-Signature")
  valid_612254 = validateParameter(valid_612254, JString, required = false,
                                 default = nil)
  if valid_612254 != nil:
    section.add "X-Amz-Signature", valid_612254
  var valid_612255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612255 = validateParameter(valid_612255, JString, required = false,
                                 default = nil)
  if valid_612255 != nil:
    section.add "X-Amz-Content-Sha256", valid_612255
  var valid_612256 = header.getOrDefault("X-Amz-Date")
  valid_612256 = validateParameter(valid_612256, JString, required = false,
                                 default = nil)
  if valid_612256 != nil:
    section.add "X-Amz-Date", valid_612256
  var valid_612257 = header.getOrDefault("X-Amz-Credential")
  valid_612257 = validateParameter(valid_612257, JString, required = false,
                                 default = nil)
  if valid_612257 != nil:
    section.add "X-Amz-Credential", valid_612257
  var valid_612258 = header.getOrDefault("X-Amz-Security-Token")
  valid_612258 = validateParameter(valid_612258, JString, required = false,
                                 default = nil)
  if valid_612258 != nil:
    section.add "X-Amz-Security-Token", valid_612258
  var valid_612259 = header.getOrDefault("X-Amz-Algorithm")
  valid_612259 = validateParameter(valid_612259, JString, required = false,
                                 default = nil)
  if valid_612259 != nil:
    section.add "X-Amz-Algorithm", valid_612259
  var valid_612260 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612260 = validateParameter(valid_612260, JString, required = false,
                                 default = nil)
  if valid_612260 != nil:
    section.add "X-Amz-SignedHeaders", valid_612260
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612261: Call_GetDescribeEvents_612237; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns list of event descriptions matching criteria up to the last 6 weeks.</p> <note> <p>This action returns the most recent 1,000 events from the specified <code>NextToken</code>.</p> </note>
  ## 
  let valid = call_612261.validator(path, query, header, formData, body)
  let scheme = call_612261.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612261.url(scheme.get, call_612261.host, call_612261.base,
                         call_612261.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612261, url, valid)

proc call*(call_612262: Call_GetDescribeEvents_612237; RequestId: string = "";
          ApplicationName: string = ""; VersionLabel: string = "";
          NextToken: string = ""; Severity: string = "TRACE";
          EnvironmentName: string = ""; Action: string = "DescribeEvents";
          StartTime: string = ""; PlatformArn: string = ""; EndTime: string = "";
          Version: string = "2010-12-01"; TemplateName: string = "";
          MaxRecords: int = 0; EnvironmentId: string = ""): Recallable =
  ## getDescribeEvents
  ## <p>Returns list of event descriptions matching criteria up to the last 6 weeks.</p> <note> <p>This action returns the most recent 1,000 events from the specified <code>NextToken</code>.</p> </note>
  ##   RequestId: string
  ##            : If specified, AWS Elastic Beanstalk restricts the described events to include only those associated with this request ID.
  ##   ApplicationName: string
  ##                  : If specified, AWS Elastic Beanstalk restricts the returned descriptions to include only those associated with this application.
  ##   VersionLabel: string
  ##               : If specified, AWS Elastic Beanstalk restricts the returned descriptions to those associated with this application version.
  ##   NextToken: string
  ##            : Pagination token. If specified, the events return the next batch of results.
  ##   Severity: string
  ##           : If specified, limits the events returned from this call to include only those with the specified severity or higher.
  ##   EnvironmentName: string
  ##                  : If specified, AWS Elastic Beanstalk restricts the returned descriptions to those associated with this environment.
  ##   Action: string (required)
  ##   StartTime: string
  ##            : If specified, AWS Elastic Beanstalk restricts the returned descriptions to those that occur on or after this time.
  ##   PlatformArn: string
  ##              : The ARN of the version of the custom platform.
  ##   EndTime: string
  ##          :  If specified, AWS Elastic Beanstalk restricts the returned descriptions to those that occur up to, but not including, the <code>EndTime</code>. 
  ##   Version: string (required)
  ##   TemplateName: string
  ##               : If specified, AWS Elastic Beanstalk restricts the returned descriptions to those that are associated with this environment configuration.
  ##   MaxRecords: int
  ##             : Specifies the maximum number of events that can be returned, beginning with the most recent event.
  ##   EnvironmentId: string
  ##                : If specified, AWS Elastic Beanstalk restricts the returned descriptions to those associated with this environment.
  var query_612263 = newJObject()
  add(query_612263, "RequestId", newJString(RequestId))
  add(query_612263, "ApplicationName", newJString(ApplicationName))
  add(query_612263, "VersionLabel", newJString(VersionLabel))
  add(query_612263, "NextToken", newJString(NextToken))
  add(query_612263, "Severity", newJString(Severity))
  add(query_612263, "EnvironmentName", newJString(EnvironmentName))
  add(query_612263, "Action", newJString(Action))
  add(query_612263, "StartTime", newJString(StartTime))
  add(query_612263, "PlatformArn", newJString(PlatformArn))
  add(query_612263, "EndTime", newJString(EndTime))
  add(query_612263, "Version", newJString(Version))
  add(query_612263, "TemplateName", newJString(TemplateName))
  add(query_612263, "MaxRecords", newJInt(MaxRecords))
  add(query_612263, "EnvironmentId", newJString(EnvironmentId))
  result = call_612262.call(nil, query_612263, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_612237(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_612238,
    base: "/", url: url_GetDescribeEvents_612239,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeInstancesHealth_612311 = ref object of OpenApiRestCall_610659
proc url_PostDescribeInstancesHealth_612313(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeInstancesHealth_612312(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves detailed information about the health of instances in your AWS Elastic Beanstalk. This operation requires <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/health-enhanced.html">enhanced health reporting</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612314 = query.getOrDefault("Action")
  valid_612314 = validateParameter(valid_612314, JString, required = true, default = newJString(
      "DescribeInstancesHealth"))
  if valid_612314 != nil:
    section.add "Action", valid_612314
  var valid_612315 = query.getOrDefault("Version")
  valid_612315 = validateParameter(valid_612315, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612315 != nil:
    section.add "Version", valid_612315
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612316 = header.getOrDefault("X-Amz-Signature")
  valid_612316 = validateParameter(valid_612316, JString, required = false,
                                 default = nil)
  if valid_612316 != nil:
    section.add "X-Amz-Signature", valid_612316
  var valid_612317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612317 = validateParameter(valid_612317, JString, required = false,
                                 default = nil)
  if valid_612317 != nil:
    section.add "X-Amz-Content-Sha256", valid_612317
  var valid_612318 = header.getOrDefault("X-Amz-Date")
  valid_612318 = validateParameter(valid_612318, JString, required = false,
                                 default = nil)
  if valid_612318 != nil:
    section.add "X-Amz-Date", valid_612318
  var valid_612319 = header.getOrDefault("X-Amz-Credential")
  valid_612319 = validateParameter(valid_612319, JString, required = false,
                                 default = nil)
  if valid_612319 != nil:
    section.add "X-Amz-Credential", valid_612319
  var valid_612320 = header.getOrDefault("X-Amz-Security-Token")
  valid_612320 = validateParameter(valid_612320, JString, required = false,
                                 default = nil)
  if valid_612320 != nil:
    section.add "X-Amz-Security-Token", valid_612320
  var valid_612321 = header.getOrDefault("X-Amz-Algorithm")
  valid_612321 = validateParameter(valid_612321, JString, required = false,
                                 default = nil)
  if valid_612321 != nil:
    section.add "X-Amz-Algorithm", valid_612321
  var valid_612322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612322 = validateParameter(valid_612322, JString, required = false,
                                 default = nil)
  if valid_612322 != nil:
    section.add "X-Amz-SignedHeaders", valid_612322
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Specify the pagination token returned by a previous call.
  ##   EnvironmentName: JString
  ##                  : Specify the AWS Elastic Beanstalk environment by name.
  ##   AttributeNames: JArray
  ##                 : Specifies the response elements you wish to receive. To retrieve all attributes, set to <code>All</code>. If no attribute names are specified, returns a list of instances.
  ##   EnvironmentId: JString
  ##                : Specify the AWS Elastic Beanstalk environment by ID.
  section = newJObject()
  var valid_612323 = formData.getOrDefault("NextToken")
  valid_612323 = validateParameter(valid_612323, JString, required = false,
                                 default = nil)
  if valid_612323 != nil:
    section.add "NextToken", valid_612323
  var valid_612324 = formData.getOrDefault("EnvironmentName")
  valid_612324 = validateParameter(valid_612324, JString, required = false,
                                 default = nil)
  if valid_612324 != nil:
    section.add "EnvironmentName", valid_612324
  var valid_612325 = formData.getOrDefault("AttributeNames")
  valid_612325 = validateParameter(valid_612325, JArray, required = false,
                                 default = nil)
  if valid_612325 != nil:
    section.add "AttributeNames", valid_612325
  var valid_612326 = formData.getOrDefault("EnvironmentId")
  valid_612326 = validateParameter(valid_612326, JString, required = false,
                                 default = nil)
  if valid_612326 != nil:
    section.add "EnvironmentId", valid_612326
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612327: Call_PostDescribeInstancesHealth_612311; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves detailed information about the health of instances in your AWS Elastic Beanstalk. This operation requires <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/health-enhanced.html">enhanced health reporting</a>.
  ## 
  let valid = call_612327.validator(path, query, header, formData, body)
  let scheme = call_612327.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612327.url(scheme.get, call_612327.host, call_612327.base,
                         call_612327.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612327, url, valid)

proc call*(call_612328: Call_PostDescribeInstancesHealth_612311;
          NextToken: string = ""; EnvironmentName: string = "";
          AttributeNames: JsonNode = nil;
          Action: string = "DescribeInstancesHealth"; EnvironmentId: string = "";
          Version: string = "2010-12-01"): Recallable =
  ## postDescribeInstancesHealth
  ## Retrieves detailed information about the health of instances in your AWS Elastic Beanstalk. This operation requires <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/health-enhanced.html">enhanced health reporting</a>.
  ##   NextToken: string
  ##            : Specify the pagination token returned by a previous call.
  ##   EnvironmentName: string
  ##                  : Specify the AWS Elastic Beanstalk environment by name.
  ##   AttributeNames: JArray
  ##                 : Specifies the response elements you wish to receive. To retrieve all attributes, set to <code>All</code>. If no attribute names are specified, returns a list of instances.
  ##   Action: string (required)
  ##   EnvironmentId: string
  ##                : Specify the AWS Elastic Beanstalk environment by ID.
  ##   Version: string (required)
  var query_612329 = newJObject()
  var formData_612330 = newJObject()
  add(formData_612330, "NextToken", newJString(NextToken))
  add(formData_612330, "EnvironmentName", newJString(EnvironmentName))
  if AttributeNames != nil:
    formData_612330.add "AttributeNames", AttributeNames
  add(query_612329, "Action", newJString(Action))
  add(formData_612330, "EnvironmentId", newJString(EnvironmentId))
  add(query_612329, "Version", newJString(Version))
  result = call_612328.call(nil, query_612329, nil, formData_612330, nil)

var postDescribeInstancesHealth* = Call_PostDescribeInstancesHealth_612311(
    name: "postDescribeInstancesHealth", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeInstancesHealth",
    validator: validate_PostDescribeInstancesHealth_612312, base: "/",
    url: url_PostDescribeInstancesHealth_612313,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeInstancesHealth_612292 = ref object of OpenApiRestCall_610659
proc url_GetDescribeInstancesHealth_612294(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeInstancesHealth_612293(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves detailed information about the health of instances in your AWS Elastic Beanstalk. This operation requires <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/health-enhanced.html">enhanced health reporting</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   AttributeNames: JArray
  ##                 : Specifies the response elements you wish to receive. To retrieve all attributes, set to <code>All</code>. If no attribute names are specified, returns a list of instances.
  ##   NextToken: JString
  ##            : Specify the pagination token returned by a previous call.
  ##   EnvironmentName: JString
  ##                  : Specify the AWS Elastic Beanstalk environment by name.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   EnvironmentId: JString
  ##                : Specify the AWS Elastic Beanstalk environment by ID.
  section = newJObject()
  var valid_612295 = query.getOrDefault("AttributeNames")
  valid_612295 = validateParameter(valid_612295, JArray, required = false,
                                 default = nil)
  if valid_612295 != nil:
    section.add "AttributeNames", valid_612295
  var valid_612296 = query.getOrDefault("NextToken")
  valid_612296 = validateParameter(valid_612296, JString, required = false,
                                 default = nil)
  if valid_612296 != nil:
    section.add "NextToken", valid_612296
  var valid_612297 = query.getOrDefault("EnvironmentName")
  valid_612297 = validateParameter(valid_612297, JString, required = false,
                                 default = nil)
  if valid_612297 != nil:
    section.add "EnvironmentName", valid_612297
  var valid_612298 = query.getOrDefault("Action")
  valid_612298 = validateParameter(valid_612298, JString, required = true, default = newJString(
      "DescribeInstancesHealth"))
  if valid_612298 != nil:
    section.add "Action", valid_612298
  var valid_612299 = query.getOrDefault("Version")
  valid_612299 = validateParameter(valid_612299, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612299 != nil:
    section.add "Version", valid_612299
  var valid_612300 = query.getOrDefault("EnvironmentId")
  valid_612300 = validateParameter(valid_612300, JString, required = false,
                                 default = nil)
  if valid_612300 != nil:
    section.add "EnvironmentId", valid_612300
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612301 = header.getOrDefault("X-Amz-Signature")
  valid_612301 = validateParameter(valid_612301, JString, required = false,
                                 default = nil)
  if valid_612301 != nil:
    section.add "X-Amz-Signature", valid_612301
  var valid_612302 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612302 = validateParameter(valid_612302, JString, required = false,
                                 default = nil)
  if valid_612302 != nil:
    section.add "X-Amz-Content-Sha256", valid_612302
  var valid_612303 = header.getOrDefault("X-Amz-Date")
  valid_612303 = validateParameter(valid_612303, JString, required = false,
                                 default = nil)
  if valid_612303 != nil:
    section.add "X-Amz-Date", valid_612303
  var valid_612304 = header.getOrDefault("X-Amz-Credential")
  valid_612304 = validateParameter(valid_612304, JString, required = false,
                                 default = nil)
  if valid_612304 != nil:
    section.add "X-Amz-Credential", valid_612304
  var valid_612305 = header.getOrDefault("X-Amz-Security-Token")
  valid_612305 = validateParameter(valid_612305, JString, required = false,
                                 default = nil)
  if valid_612305 != nil:
    section.add "X-Amz-Security-Token", valid_612305
  var valid_612306 = header.getOrDefault("X-Amz-Algorithm")
  valid_612306 = validateParameter(valid_612306, JString, required = false,
                                 default = nil)
  if valid_612306 != nil:
    section.add "X-Amz-Algorithm", valid_612306
  var valid_612307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612307 = validateParameter(valid_612307, JString, required = false,
                                 default = nil)
  if valid_612307 != nil:
    section.add "X-Amz-SignedHeaders", valid_612307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612308: Call_GetDescribeInstancesHealth_612292; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves detailed information about the health of instances in your AWS Elastic Beanstalk. This operation requires <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/health-enhanced.html">enhanced health reporting</a>.
  ## 
  let valid = call_612308.validator(path, query, header, formData, body)
  let scheme = call_612308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612308.url(scheme.get, call_612308.host, call_612308.base,
                         call_612308.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612308, url, valid)

proc call*(call_612309: Call_GetDescribeInstancesHealth_612292;
          AttributeNames: JsonNode = nil; NextToken: string = "";
          EnvironmentName: string = ""; Action: string = "DescribeInstancesHealth";
          Version: string = "2010-12-01"; EnvironmentId: string = ""): Recallable =
  ## getDescribeInstancesHealth
  ## Retrieves detailed information about the health of instances in your AWS Elastic Beanstalk. This operation requires <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/health-enhanced.html">enhanced health reporting</a>.
  ##   AttributeNames: JArray
  ##                 : Specifies the response elements you wish to receive. To retrieve all attributes, set to <code>All</code>. If no attribute names are specified, returns a list of instances.
  ##   NextToken: string
  ##            : Specify the pagination token returned by a previous call.
  ##   EnvironmentName: string
  ##                  : Specify the AWS Elastic Beanstalk environment by name.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   EnvironmentId: string
  ##                : Specify the AWS Elastic Beanstalk environment by ID.
  var query_612310 = newJObject()
  if AttributeNames != nil:
    query_612310.add "AttributeNames", AttributeNames
  add(query_612310, "NextToken", newJString(NextToken))
  add(query_612310, "EnvironmentName", newJString(EnvironmentName))
  add(query_612310, "Action", newJString(Action))
  add(query_612310, "Version", newJString(Version))
  add(query_612310, "EnvironmentId", newJString(EnvironmentId))
  result = call_612309.call(nil, query_612310, nil, nil, nil)

var getDescribeInstancesHealth* = Call_GetDescribeInstancesHealth_612292(
    name: "getDescribeInstancesHealth", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeInstancesHealth",
    validator: validate_GetDescribeInstancesHealth_612293, base: "/",
    url: url_GetDescribeInstancesHealth_612294,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribePlatformVersion_612347 = ref object of OpenApiRestCall_610659
proc url_PostDescribePlatformVersion_612349(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribePlatformVersion_612348(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the version of the platform.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612350 = query.getOrDefault("Action")
  valid_612350 = validateParameter(valid_612350, JString, required = true, default = newJString(
      "DescribePlatformVersion"))
  if valid_612350 != nil:
    section.add "Action", valid_612350
  var valid_612351 = query.getOrDefault("Version")
  valid_612351 = validateParameter(valid_612351, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612351 != nil:
    section.add "Version", valid_612351
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612352 = header.getOrDefault("X-Amz-Signature")
  valid_612352 = validateParameter(valid_612352, JString, required = false,
                                 default = nil)
  if valid_612352 != nil:
    section.add "X-Amz-Signature", valid_612352
  var valid_612353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612353 = validateParameter(valid_612353, JString, required = false,
                                 default = nil)
  if valid_612353 != nil:
    section.add "X-Amz-Content-Sha256", valid_612353
  var valid_612354 = header.getOrDefault("X-Amz-Date")
  valid_612354 = validateParameter(valid_612354, JString, required = false,
                                 default = nil)
  if valid_612354 != nil:
    section.add "X-Amz-Date", valid_612354
  var valid_612355 = header.getOrDefault("X-Amz-Credential")
  valid_612355 = validateParameter(valid_612355, JString, required = false,
                                 default = nil)
  if valid_612355 != nil:
    section.add "X-Amz-Credential", valid_612355
  var valid_612356 = header.getOrDefault("X-Amz-Security-Token")
  valid_612356 = validateParameter(valid_612356, JString, required = false,
                                 default = nil)
  if valid_612356 != nil:
    section.add "X-Amz-Security-Token", valid_612356
  var valid_612357 = header.getOrDefault("X-Amz-Algorithm")
  valid_612357 = validateParameter(valid_612357, JString, required = false,
                                 default = nil)
  if valid_612357 != nil:
    section.add "X-Amz-Algorithm", valid_612357
  var valid_612358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612358 = validateParameter(valid_612358, JString, required = false,
                                 default = nil)
  if valid_612358 != nil:
    section.add "X-Amz-SignedHeaders", valid_612358
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformArn: JString
  ##              : The ARN of the version of the platform.
  section = newJObject()
  var valid_612359 = formData.getOrDefault("PlatformArn")
  valid_612359 = validateParameter(valid_612359, JString, required = false,
                                 default = nil)
  if valid_612359 != nil:
    section.add "PlatformArn", valid_612359
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612360: Call_PostDescribePlatformVersion_612347; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the version of the platform.
  ## 
  let valid = call_612360.validator(path, query, header, formData, body)
  let scheme = call_612360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612360.url(scheme.get, call_612360.host, call_612360.base,
                         call_612360.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612360, url, valid)

proc call*(call_612361: Call_PostDescribePlatformVersion_612347;
          Action: string = "DescribePlatformVersion";
          Version: string = "2010-12-01"; PlatformArn: string = ""): Recallable =
  ## postDescribePlatformVersion
  ## Describes the version of the platform.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PlatformArn: string
  ##              : The ARN of the version of the platform.
  var query_612362 = newJObject()
  var formData_612363 = newJObject()
  add(query_612362, "Action", newJString(Action))
  add(query_612362, "Version", newJString(Version))
  add(formData_612363, "PlatformArn", newJString(PlatformArn))
  result = call_612361.call(nil, query_612362, nil, formData_612363, nil)

var postDescribePlatformVersion* = Call_PostDescribePlatformVersion_612347(
    name: "postDescribePlatformVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribePlatformVersion",
    validator: validate_PostDescribePlatformVersion_612348, base: "/",
    url: url_PostDescribePlatformVersion_612349,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribePlatformVersion_612331 = ref object of OpenApiRestCall_610659
proc url_GetDescribePlatformVersion_612333(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribePlatformVersion_612332(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the version of the platform.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   PlatformArn: JString
  ##              : The ARN of the version of the platform.
  ##   Version: JString (required)
  section = newJObject()
  var valid_612334 = query.getOrDefault("Action")
  valid_612334 = validateParameter(valid_612334, JString, required = true, default = newJString(
      "DescribePlatformVersion"))
  if valid_612334 != nil:
    section.add "Action", valid_612334
  var valid_612335 = query.getOrDefault("PlatformArn")
  valid_612335 = validateParameter(valid_612335, JString, required = false,
                                 default = nil)
  if valid_612335 != nil:
    section.add "PlatformArn", valid_612335
  var valid_612336 = query.getOrDefault("Version")
  valid_612336 = validateParameter(valid_612336, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612336 != nil:
    section.add "Version", valid_612336
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612337 = header.getOrDefault("X-Amz-Signature")
  valid_612337 = validateParameter(valid_612337, JString, required = false,
                                 default = nil)
  if valid_612337 != nil:
    section.add "X-Amz-Signature", valid_612337
  var valid_612338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612338 = validateParameter(valid_612338, JString, required = false,
                                 default = nil)
  if valid_612338 != nil:
    section.add "X-Amz-Content-Sha256", valid_612338
  var valid_612339 = header.getOrDefault("X-Amz-Date")
  valid_612339 = validateParameter(valid_612339, JString, required = false,
                                 default = nil)
  if valid_612339 != nil:
    section.add "X-Amz-Date", valid_612339
  var valid_612340 = header.getOrDefault("X-Amz-Credential")
  valid_612340 = validateParameter(valid_612340, JString, required = false,
                                 default = nil)
  if valid_612340 != nil:
    section.add "X-Amz-Credential", valid_612340
  var valid_612341 = header.getOrDefault("X-Amz-Security-Token")
  valid_612341 = validateParameter(valid_612341, JString, required = false,
                                 default = nil)
  if valid_612341 != nil:
    section.add "X-Amz-Security-Token", valid_612341
  var valid_612342 = header.getOrDefault("X-Amz-Algorithm")
  valid_612342 = validateParameter(valid_612342, JString, required = false,
                                 default = nil)
  if valid_612342 != nil:
    section.add "X-Amz-Algorithm", valid_612342
  var valid_612343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612343 = validateParameter(valid_612343, JString, required = false,
                                 default = nil)
  if valid_612343 != nil:
    section.add "X-Amz-SignedHeaders", valid_612343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612344: Call_GetDescribePlatformVersion_612331; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the version of the platform.
  ## 
  let valid = call_612344.validator(path, query, header, formData, body)
  let scheme = call_612344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612344.url(scheme.get, call_612344.host, call_612344.base,
                         call_612344.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612344, url, valid)

proc call*(call_612345: Call_GetDescribePlatformVersion_612331;
          Action: string = "DescribePlatformVersion"; PlatformArn: string = "";
          Version: string = "2010-12-01"): Recallable =
  ## getDescribePlatformVersion
  ## Describes the version of the platform.
  ##   Action: string (required)
  ##   PlatformArn: string
  ##              : The ARN of the version of the platform.
  ##   Version: string (required)
  var query_612346 = newJObject()
  add(query_612346, "Action", newJString(Action))
  add(query_612346, "PlatformArn", newJString(PlatformArn))
  add(query_612346, "Version", newJString(Version))
  result = call_612345.call(nil, query_612346, nil, nil, nil)

var getDescribePlatformVersion* = Call_GetDescribePlatformVersion_612331(
    name: "getDescribePlatformVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribePlatformVersion",
    validator: validate_GetDescribePlatformVersion_612332, base: "/",
    url: url_GetDescribePlatformVersion_612333,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListAvailableSolutionStacks_612379 = ref object of OpenApiRestCall_610659
proc url_PostListAvailableSolutionStacks_612381(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListAvailableSolutionStacks_612380(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612382 = query.getOrDefault("Action")
  valid_612382 = validateParameter(valid_612382, JString, required = true, default = newJString(
      "ListAvailableSolutionStacks"))
  if valid_612382 != nil:
    section.add "Action", valid_612382
  var valid_612383 = query.getOrDefault("Version")
  valid_612383 = validateParameter(valid_612383, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612383 != nil:
    section.add "Version", valid_612383
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612384 = header.getOrDefault("X-Amz-Signature")
  valid_612384 = validateParameter(valid_612384, JString, required = false,
                                 default = nil)
  if valid_612384 != nil:
    section.add "X-Amz-Signature", valid_612384
  var valid_612385 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612385 = validateParameter(valid_612385, JString, required = false,
                                 default = nil)
  if valid_612385 != nil:
    section.add "X-Amz-Content-Sha256", valid_612385
  var valid_612386 = header.getOrDefault("X-Amz-Date")
  valid_612386 = validateParameter(valid_612386, JString, required = false,
                                 default = nil)
  if valid_612386 != nil:
    section.add "X-Amz-Date", valid_612386
  var valid_612387 = header.getOrDefault("X-Amz-Credential")
  valid_612387 = validateParameter(valid_612387, JString, required = false,
                                 default = nil)
  if valid_612387 != nil:
    section.add "X-Amz-Credential", valid_612387
  var valid_612388 = header.getOrDefault("X-Amz-Security-Token")
  valid_612388 = validateParameter(valid_612388, JString, required = false,
                                 default = nil)
  if valid_612388 != nil:
    section.add "X-Amz-Security-Token", valid_612388
  var valid_612389 = header.getOrDefault("X-Amz-Algorithm")
  valid_612389 = validateParameter(valid_612389, JString, required = false,
                                 default = nil)
  if valid_612389 != nil:
    section.add "X-Amz-Algorithm", valid_612389
  var valid_612390 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612390 = validateParameter(valid_612390, JString, required = false,
                                 default = nil)
  if valid_612390 != nil:
    section.add "X-Amz-SignedHeaders", valid_612390
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612391: Call_PostListAvailableSolutionStacks_612379;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ## 
  let valid = call_612391.validator(path, query, header, formData, body)
  let scheme = call_612391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612391.url(scheme.get, call_612391.host, call_612391.base,
                         call_612391.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612391, url, valid)

proc call*(call_612392: Call_PostListAvailableSolutionStacks_612379;
          Action: string = "ListAvailableSolutionStacks";
          Version: string = "2010-12-01"): Recallable =
  ## postListAvailableSolutionStacks
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612393 = newJObject()
  add(query_612393, "Action", newJString(Action))
  add(query_612393, "Version", newJString(Version))
  result = call_612392.call(nil, query_612393, nil, nil, nil)

var postListAvailableSolutionStacks* = Call_PostListAvailableSolutionStacks_612379(
    name: "postListAvailableSolutionStacks", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListAvailableSolutionStacks",
    validator: validate_PostListAvailableSolutionStacks_612380, base: "/",
    url: url_PostListAvailableSolutionStacks_612381,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListAvailableSolutionStacks_612364 = ref object of OpenApiRestCall_610659
proc url_GetListAvailableSolutionStacks_612366(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListAvailableSolutionStacks_612365(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612367 = query.getOrDefault("Action")
  valid_612367 = validateParameter(valid_612367, JString, required = true, default = newJString(
      "ListAvailableSolutionStacks"))
  if valid_612367 != nil:
    section.add "Action", valid_612367
  var valid_612368 = query.getOrDefault("Version")
  valid_612368 = validateParameter(valid_612368, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612368 != nil:
    section.add "Version", valid_612368
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612369 = header.getOrDefault("X-Amz-Signature")
  valid_612369 = validateParameter(valid_612369, JString, required = false,
                                 default = nil)
  if valid_612369 != nil:
    section.add "X-Amz-Signature", valid_612369
  var valid_612370 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612370 = validateParameter(valid_612370, JString, required = false,
                                 default = nil)
  if valid_612370 != nil:
    section.add "X-Amz-Content-Sha256", valid_612370
  var valid_612371 = header.getOrDefault("X-Amz-Date")
  valid_612371 = validateParameter(valid_612371, JString, required = false,
                                 default = nil)
  if valid_612371 != nil:
    section.add "X-Amz-Date", valid_612371
  var valid_612372 = header.getOrDefault("X-Amz-Credential")
  valid_612372 = validateParameter(valid_612372, JString, required = false,
                                 default = nil)
  if valid_612372 != nil:
    section.add "X-Amz-Credential", valid_612372
  var valid_612373 = header.getOrDefault("X-Amz-Security-Token")
  valid_612373 = validateParameter(valid_612373, JString, required = false,
                                 default = nil)
  if valid_612373 != nil:
    section.add "X-Amz-Security-Token", valid_612373
  var valid_612374 = header.getOrDefault("X-Amz-Algorithm")
  valid_612374 = validateParameter(valid_612374, JString, required = false,
                                 default = nil)
  if valid_612374 != nil:
    section.add "X-Amz-Algorithm", valid_612374
  var valid_612375 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612375 = validateParameter(valid_612375, JString, required = false,
                                 default = nil)
  if valid_612375 != nil:
    section.add "X-Amz-SignedHeaders", valid_612375
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612376: Call_GetListAvailableSolutionStacks_612364; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ## 
  let valid = call_612376.validator(path, query, header, formData, body)
  let scheme = call_612376.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612376.url(scheme.get, call_612376.host, call_612376.base,
                         call_612376.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612376, url, valid)

proc call*(call_612377: Call_GetListAvailableSolutionStacks_612364;
          Action: string = "ListAvailableSolutionStacks";
          Version: string = "2010-12-01"): Recallable =
  ## getListAvailableSolutionStacks
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612378 = newJObject()
  add(query_612378, "Action", newJString(Action))
  add(query_612378, "Version", newJString(Version))
  result = call_612377.call(nil, query_612378, nil, nil, nil)

var getListAvailableSolutionStacks* = Call_GetListAvailableSolutionStacks_612364(
    name: "getListAvailableSolutionStacks", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListAvailableSolutionStacks",
    validator: validate_GetListAvailableSolutionStacks_612365, base: "/",
    url: url_GetListAvailableSolutionStacks_612366,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListPlatformVersions_612412 = ref object of OpenApiRestCall_610659
proc url_PostListPlatformVersions_612414(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListPlatformVersions_612413(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the available platforms.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612415 = query.getOrDefault("Action")
  valid_612415 = validateParameter(valid_612415, JString, required = true,
                                 default = newJString("ListPlatformVersions"))
  if valid_612415 != nil:
    section.add "Action", valid_612415
  var valid_612416 = query.getOrDefault("Version")
  valid_612416 = validateParameter(valid_612416, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612416 != nil:
    section.add "Version", valid_612416
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612417 = header.getOrDefault("X-Amz-Signature")
  valid_612417 = validateParameter(valid_612417, JString, required = false,
                                 default = nil)
  if valid_612417 != nil:
    section.add "X-Amz-Signature", valid_612417
  var valid_612418 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612418 = validateParameter(valid_612418, JString, required = false,
                                 default = nil)
  if valid_612418 != nil:
    section.add "X-Amz-Content-Sha256", valid_612418
  var valid_612419 = header.getOrDefault("X-Amz-Date")
  valid_612419 = validateParameter(valid_612419, JString, required = false,
                                 default = nil)
  if valid_612419 != nil:
    section.add "X-Amz-Date", valid_612419
  var valid_612420 = header.getOrDefault("X-Amz-Credential")
  valid_612420 = validateParameter(valid_612420, JString, required = false,
                                 default = nil)
  if valid_612420 != nil:
    section.add "X-Amz-Credential", valid_612420
  var valid_612421 = header.getOrDefault("X-Amz-Security-Token")
  valid_612421 = validateParameter(valid_612421, JString, required = false,
                                 default = nil)
  if valid_612421 != nil:
    section.add "X-Amz-Security-Token", valid_612421
  var valid_612422 = header.getOrDefault("X-Amz-Algorithm")
  valid_612422 = validateParameter(valid_612422, JString, required = false,
                                 default = nil)
  if valid_612422 != nil:
    section.add "X-Amz-Algorithm", valid_612422
  var valid_612423 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612423 = validateParameter(valid_612423, JString, required = false,
                                 default = nil)
  if valid_612423 != nil:
    section.add "X-Amz-SignedHeaders", valid_612423
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : The starting index into the remaining list of platforms. Use the <code>NextToken</code> value from a previous <code>ListPlatformVersion</code> call.
  ##   MaxRecords: JInt
  ##             : The maximum number of platform values returned in one call.
  ##   Filters: JArray
  ##          : List only the platforms where the platform member value relates to one of the supplied values.
  section = newJObject()
  var valid_612424 = formData.getOrDefault("NextToken")
  valid_612424 = validateParameter(valid_612424, JString, required = false,
                                 default = nil)
  if valid_612424 != nil:
    section.add "NextToken", valid_612424
  var valid_612425 = formData.getOrDefault("MaxRecords")
  valid_612425 = validateParameter(valid_612425, JInt, required = false, default = nil)
  if valid_612425 != nil:
    section.add "MaxRecords", valid_612425
  var valid_612426 = formData.getOrDefault("Filters")
  valid_612426 = validateParameter(valid_612426, JArray, required = false,
                                 default = nil)
  if valid_612426 != nil:
    section.add "Filters", valid_612426
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612427: Call_PostListPlatformVersions_612412; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the available platforms.
  ## 
  let valid = call_612427.validator(path, query, header, formData, body)
  let scheme = call_612427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612427.url(scheme.get, call_612427.host, call_612427.base,
                         call_612427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612427, url, valid)

proc call*(call_612428: Call_PostListPlatformVersions_612412;
          NextToken: string = ""; MaxRecords: int = 0;
          Action: string = "ListPlatformVersions"; Filters: JsonNode = nil;
          Version: string = "2010-12-01"): Recallable =
  ## postListPlatformVersions
  ## Lists the available platforms.
  ##   NextToken: string
  ##            : The starting index into the remaining list of platforms. Use the <code>NextToken</code> value from a previous <code>ListPlatformVersion</code> call.
  ##   MaxRecords: int
  ##             : The maximum number of platform values returned in one call.
  ##   Action: string (required)
  ##   Filters: JArray
  ##          : List only the platforms where the platform member value relates to one of the supplied values.
  ##   Version: string (required)
  var query_612429 = newJObject()
  var formData_612430 = newJObject()
  add(formData_612430, "NextToken", newJString(NextToken))
  add(formData_612430, "MaxRecords", newJInt(MaxRecords))
  add(query_612429, "Action", newJString(Action))
  if Filters != nil:
    formData_612430.add "Filters", Filters
  add(query_612429, "Version", newJString(Version))
  result = call_612428.call(nil, query_612429, nil, formData_612430, nil)

var postListPlatformVersions* = Call_PostListPlatformVersions_612412(
    name: "postListPlatformVersions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListPlatformVersions",
    validator: validate_PostListPlatformVersions_612413, base: "/",
    url: url_PostListPlatformVersions_612414, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListPlatformVersions_612394 = ref object of OpenApiRestCall_610659
proc url_GetListPlatformVersions_612396(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListPlatformVersions_612395(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the available platforms.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The starting index into the remaining list of platforms. Use the <code>NextToken</code> value from a previous <code>ListPlatformVersion</code> call.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   Filters: JArray
  ##          : List only the platforms where the platform member value relates to one of the supplied values.
  ##   MaxRecords: JInt
  ##             : The maximum number of platform values returned in one call.
  section = newJObject()
  var valid_612397 = query.getOrDefault("NextToken")
  valid_612397 = validateParameter(valid_612397, JString, required = false,
                                 default = nil)
  if valid_612397 != nil:
    section.add "NextToken", valid_612397
  var valid_612398 = query.getOrDefault("Action")
  valid_612398 = validateParameter(valid_612398, JString, required = true,
                                 default = newJString("ListPlatformVersions"))
  if valid_612398 != nil:
    section.add "Action", valid_612398
  var valid_612399 = query.getOrDefault("Version")
  valid_612399 = validateParameter(valid_612399, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612399 != nil:
    section.add "Version", valid_612399
  var valid_612400 = query.getOrDefault("Filters")
  valid_612400 = validateParameter(valid_612400, JArray, required = false,
                                 default = nil)
  if valid_612400 != nil:
    section.add "Filters", valid_612400
  var valid_612401 = query.getOrDefault("MaxRecords")
  valid_612401 = validateParameter(valid_612401, JInt, required = false, default = nil)
  if valid_612401 != nil:
    section.add "MaxRecords", valid_612401
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612402 = header.getOrDefault("X-Amz-Signature")
  valid_612402 = validateParameter(valid_612402, JString, required = false,
                                 default = nil)
  if valid_612402 != nil:
    section.add "X-Amz-Signature", valid_612402
  var valid_612403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612403 = validateParameter(valid_612403, JString, required = false,
                                 default = nil)
  if valid_612403 != nil:
    section.add "X-Amz-Content-Sha256", valid_612403
  var valid_612404 = header.getOrDefault("X-Amz-Date")
  valid_612404 = validateParameter(valid_612404, JString, required = false,
                                 default = nil)
  if valid_612404 != nil:
    section.add "X-Amz-Date", valid_612404
  var valid_612405 = header.getOrDefault("X-Amz-Credential")
  valid_612405 = validateParameter(valid_612405, JString, required = false,
                                 default = nil)
  if valid_612405 != nil:
    section.add "X-Amz-Credential", valid_612405
  var valid_612406 = header.getOrDefault("X-Amz-Security-Token")
  valid_612406 = validateParameter(valid_612406, JString, required = false,
                                 default = nil)
  if valid_612406 != nil:
    section.add "X-Amz-Security-Token", valid_612406
  var valid_612407 = header.getOrDefault("X-Amz-Algorithm")
  valid_612407 = validateParameter(valid_612407, JString, required = false,
                                 default = nil)
  if valid_612407 != nil:
    section.add "X-Amz-Algorithm", valid_612407
  var valid_612408 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612408 = validateParameter(valid_612408, JString, required = false,
                                 default = nil)
  if valid_612408 != nil:
    section.add "X-Amz-SignedHeaders", valid_612408
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612409: Call_GetListPlatformVersions_612394; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the available platforms.
  ## 
  let valid = call_612409.validator(path, query, header, formData, body)
  let scheme = call_612409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612409.url(scheme.get, call_612409.host, call_612409.base,
                         call_612409.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612409, url, valid)

proc call*(call_612410: Call_GetListPlatformVersions_612394;
          NextToken: string = ""; Action: string = "ListPlatformVersions";
          Version: string = "2010-12-01"; Filters: JsonNode = nil; MaxRecords: int = 0): Recallable =
  ## getListPlatformVersions
  ## Lists the available platforms.
  ##   NextToken: string
  ##            : The starting index into the remaining list of platforms. Use the <code>NextToken</code> value from a previous <code>ListPlatformVersion</code> call.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   Filters: JArray
  ##          : List only the platforms where the platform member value relates to one of the supplied values.
  ##   MaxRecords: int
  ##             : The maximum number of platform values returned in one call.
  var query_612411 = newJObject()
  add(query_612411, "NextToken", newJString(NextToken))
  add(query_612411, "Action", newJString(Action))
  add(query_612411, "Version", newJString(Version))
  if Filters != nil:
    query_612411.add "Filters", Filters
  add(query_612411, "MaxRecords", newJInt(MaxRecords))
  result = call_612410.call(nil, query_612411, nil, nil, nil)

var getListPlatformVersions* = Call_GetListPlatformVersions_612394(
    name: "getListPlatformVersions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListPlatformVersions",
    validator: validate_GetListPlatformVersions_612395, base: "/",
    url: url_GetListPlatformVersions_612396, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_612447 = ref object of OpenApiRestCall_610659
proc url_PostListTagsForResource_612449(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListTagsForResource_612448(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612450 = query.getOrDefault("Action")
  valid_612450 = validateParameter(valid_612450, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_612450 != nil:
    section.add "Action", valid_612450
  var valid_612451 = query.getOrDefault("Version")
  valid_612451 = validateParameter(valid_612451, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612451 != nil:
    section.add "Version", valid_612451
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612452 = header.getOrDefault("X-Amz-Signature")
  valid_612452 = validateParameter(valid_612452, JString, required = false,
                                 default = nil)
  if valid_612452 != nil:
    section.add "X-Amz-Signature", valid_612452
  var valid_612453 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612453 = validateParameter(valid_612453, JString, required = false,
                                 default = nil)
  if valid_612453 != nil:
    section.add "X-Amz-Content-Sha256", valid_612453
  var valid_612454 = header.getOrDefault("X-Amz-Date")
  valid_612454 = validateParameter(valid_612454, JString, required = false,
                                 default = nil)
  if valid_612454 != nil:
    section.add "X-Amz-Date", valid_612454
  var valid_612455 = header.getOrDefault("X-Amz-Credential")
  valid_612455 = validateParameter(valid_612455, JString, required = false,
                                 default = nil)
  if valid_612455 != nil:
    section.add "X-Amz-Credential", valid_612455
  var valid_612456 = header.getOrDefault("X-Amz-Security-Token")
  valid_612456 = validateParameter(valid_612456, JString, required = false,
                                 default = nil)
  if valid_612456 != nil:
    section.add "X-Amz-Security-Token", valid_612456
  var valid_612457 = header.getOrDefault("X-Amz-Algorithm")
  valid_612457 = validateParameter(valid_612457, JString, required = false,
                                 default = nil)
  if valid_612457 != nil:
    section.add "X-Amz-Algorithm", valid_612457
  var valid_612458 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612458 = validateParameter(valid_612458, JString, required = false,
                                 default = nil)
  if valid_612458 != nil:
    section.add "X-Amz-SignedHeaders", valid_612458
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArn: JString (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce for which a tag list is requested.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArn` field"
  var valid_612459 = formData.getOrDefault("ResourceArn")
  valid_612459 = validateParameter(valid_612459, JString, required = true,
                                 default = nil)
  if valid_612459 != nil:
    section.add "ResourceArn", valid_612459
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612460: Call_PostListTagsForResource_612447; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ## 
  let valid = call_612460.validator(path, query, header, formData, body)
  let scheme = call_612460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612460.url(scheme.get, call_612460.host, call_612460.base,
                         call_612460.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612460, url, valid)

proc call*(call_612461: Call_PostListTagsForResource_612447; ResourceArn: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-12-01"): Recallable =
  ## postListTagsForResource
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ##   ResourceArn: string (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce for which a tag list is requested.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612462 = newJObject()
  var formData_612463 = newJObject()
  add(formData_612463, "ResourceArn", newJString(ResourceArn))
  add(query_612462, "Action", newJString(Action))
  add(query_612462, "Version", newJString(Version))
  result = call_612461.call(nil, query_612462, nil, formData_612463, nil)

var postListTagsForResource* = Call_PostListTagsForResource_612447(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_612448, base: "/",
    url: url_PostListTagsForResource_612449, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_612431 = ref object of OpenApiRestCall_610659
proc url_GetListTagsForResource_612433(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListTagsForResource_612432(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ResourceArn: JString (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce for which a tag list is requested.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ResourceArn` field"
  var valid_612434 = query.getOrDefault("ResourceArn")
  valid_612434 = validateParameter(valid_612434, JString, required = true,
                                 default = nil)
  if valid_612434 != nil:
    section.add "ResourceArn", valid_612434
  var valid_612435 = query.getOrDefault("Action")
  valid_612435 = validateParameter(valid_612435, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_612435 != nil:
    section.add "Action", valid_612435
  var valid_612436 = query.getOrDefault("Version")
  valid_612436 = validateParameter(valid_612436, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612436 != nil:
    section.add "Version", valid_612436
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612437 = header.getOrDefault("X-Amz-Signature")
  valid_612437 = validateParameter(valid_612437, JString, required = false,
                                 default = nil)
  if valid_612437 != nil:
    section.add "X-Amz-Signature", valid_612437
  var valid_612438 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612438 = validateParameter(valid_612438, JString, required = false,
                                 default = nil)
  if valid_612438 != nil:
    section.add "X-Amz-Content-Sha256", valid_612438
  var valid_612439 = header.getOrDefault("X-Amz-Date")
  valid_612439 = validateParameter(valid_612439, JString, required = false,
                                 default = nil)
  if valid_612439 != nil:
    section.add "X-Amz-Date", valid_612439
  var valid_612440 = header.getOrDefault("X-Amz-Credential")
  valid_612440 = validateParameter(valid_612440, JString, required = false,
                                 default = nil)
  if valid_612440 != nil:
    section.add "X-Amz-Credential", valid_612440
  var valid_612441 = header.getOrDefault("X-Amz-Security-Token")
  valid_612441 = validateParameter(valid_612441, JString, required = false,
                                 default = nil)
  if valid_612441 != nil:
    section.add "X-Amz-Security-Token", valid_612441
  var valid_612442 = header.getOrDefault("X-Amz-Algorithm")
  valid_612442 = validateParameter(valid_612442, JString, required = false,
                                 default = nil)
  if valid_612442 != nil:
    section.add "X-Amz-Algorithm", valid_612442
  var valid_612443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612443 = validateParameter(valid_612443, JString, required = false,
                                 default = nil)
  if valid_612443 != nil:
    section.add "X-Amz-SignedHeaders", valid_612443
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612444: Call_GetListTagsForResource_612431; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ## 
  let valid = call_612444.validator(path, query, header, formData, body)
  let scheme = call_612444.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612444.url(scheme.get, call_612444.host, call_612444.base,
                         call_612444.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612444, url, valid)

proc call*(call_612445: Call_GetListTagsForResource_612431; ResourceArn: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-12-01"): Recallable =
  ## getListTagsForResource
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ##   ResourceArn: string (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce for which a tag list is requested.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612446 = newJObject()
  add(query_612446, "ResourceArn", newJString(ResourceArn))
  add(query_612446, "Action", newJString(Action))
  add(query_612446, "Version", newJString(Version))
  result = call_612445.call(nil, query_612446, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_612431(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_612432, base: "/",
    url: url_GetListTagsForResource_612433, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebuildEnvironment_612481 = ref object of OpenApiRestCall_610659
proc url_PostRebuildEnvironment_612483(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRebuildEnvironment_612482(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes and recreates all of the AWS resources (for example: the Auto Scaling group, load balancer, etc.) for a specified environment and forces a restart.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612484 = query.getOrDefault("Action")
  valid_612484 = validateParameter(valid_612484, JString, required = true,
                                 default = newJString("RebuildEnvironment"))
  if valid_612484 != nil:
    section.add "Action", valid_612484
  var valid_612485 = query.getOrDefault("Version")
  valid_612485 = validateParameter(valid_612485, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612485 != nil:
    section.add "Version", valid_612485
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612486 = header.getOrDefault("X-Amz-Signature")
  valid_612486 = validateParameter(valid_612486, JString, required = false,
                                 default = nil)
  if valid_612486 != nil:
    section.add "X-Amz-Signature", valid_612486
  var valid_612487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612487 = validateParameter(valid_612487, JString, required = false,
                                 default = nil)
  if valid_612487 != nil:
    section.add "X-Amz-Content-Sha256", valid_612487
  var valid_612488 = header.getOrDefault("X-Amz-Date")
  valid_612488 = validateParameter(valid_612488, JString, required = false,
                                 default = nil)
  if valid_612488 != nil:
    section.add "X-Amz-Date", valid_612488
  var valid_612489 = header.getOrDefault("X-Amz-Credential")
  valid_612489 = validateParameter(valid_612489, JString, required = false,
                                 default = nil)
  if valid_612489 != nil:
    section.add "X-Amz-Credential", valid_612489
  var valid_612490 = header.getOrDefault("X-Amz-Security-Token")
  valid_612490 = validateParameter(valid_612490, JString, required = false,
                                 default = nil)
  if valid_612490 != nil:
    section.add "X-Amz-Security-Token", valid_612490
  var valid_612491 = header.getOrDefault("X-Amz-Algorithm")
  valid_612491 = validateParameter(valid_612491, JString, required = false,
                                 default = nil)
  if valid_612491 != nil:
    section.add "X-Amz-Algorithm", valid_612491
  var valid_612492 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612492 = validateParameter(valid_612492, JString, required = false,
                                 default = nil)
  if valid_612492 != nil:
    section.add "X-Amz-SignedHeaders", valid_612492
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to rebuild.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to rebuild.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_612493 = formData.getOrDefault("EnvironmentName")
  valid_612493 = validateParameter(valid_612493, JString, required = false,
                                 default = nil)
  if valid_612493 != nil:
    section.add "EnvironmentName", valid_612493
  var valid_612494 = formData.getOrDefault("EnvironmentId")
  valid_612494 = validateParameter(valid_612494, JString, required = false,
                                 default = nil)
  if valid_612494 != nil:
    section.add "EnvironmentId", valid_612494
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612495: Call_PostRebuildEnvironment_612481; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes and recreates all of the AWS resources (for example: the Auto Scaling group, load balancer, etc.) for a specified environment and forces a restart.
  ## 
  let valid = call_612495.validator(path, query, header, formData, body)
  let scheme = call_612495.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612495.url(scheme.get, call_612495.host, call_612495.base,
                         call_612495.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612495, url, valid)

proc call*(call_612496: Call_PostRebuildEnvironment_612481;
          EnvironmentName: string = ""; Action: string = "RebuildEnvironment";
          EnvironmentId: string = ""; Version: string = "2010-12-01"): Recallable =
  ## postRebuildEnvironment
  ## Deletes and recreates all of the AWS resources (for example: the Auto Scaling group, load balancer, etc.) for a specified environment and forces a restart.
  ##   EnvironmentName: string
  ##                  : <p>The name of the environment to rebuild.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Action: string (required)
  ##   EnvironmentId: string
  ##                : <p>The ID of the environment to rebuild.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Version: string (required)
  var query_612497 = newJObject()
  var formData_612498 = newJObject()
  add(formData_612498, "EnvironmentName", newJString(EnvironmentName))
  add(query_612497, "Action", newJString(Action))
  add(formData_612498, "EnvironmentId", newJString(EnvironmentId))
  add(query_612497, "Version", newJString(Version))
  result = call_612496.call(nil, query_612497, nil, formData_612498, nil)

var postRebuildEnvironment* = Call_PostRebuildEnvironment_612481(
    name: "postRebuildEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RebuildEnvironment",
    validator: validate_PostRebuildEnvironment_612482, base: "/",
    url: url_PostRebuildEnvironment_612483, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebuildEnvironment_612464 = ref object of OpenApiRestCall_610659
proc url_GetRebuildEnvironment_612466(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRebuildEnvironment_612465(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes and recreates all of the AWS resources (for example: the Auto Scaling group, load balancer, etc.) for a specified environment and forces a restart.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to rebuild.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to rebuild.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_612467 = query.getOrDefault("EnvironmentName")
  valid_612467 = validateParameter(valid_612467, JString, required = false,
                                 default = nil)
  if valid_612467 != nil:
    section.add "EnvironmentName", valid_612467
  var valid_612468 = query.getOrDefault("Action")
  valid_612468 = validateParameter(valid_612468, JString, required = true,
                                 default = newJString("RebuildEnvironment"))
  if valid_612468 != nil:
    section.add "Action", valid_612468
  var valid_612469 = query.getOrDefault("Version")
  valid_612469 = validateParameter(valid_612469, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612469 != nil:
    section.add "Version", valid_612469
  var valid_612470 = query.getOrDefault("EnvironmentId")
  valid_612470 = validateParameter(valid_612470, JString, required = false,
                                 default = nil)
  if valid_612470 != nil:
    section.add "EnvironmentId", valid_612470
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612471 = header.getOrDefault("X-Amz-Signature")
  valid_612471 = validateParameter(valid_612471, JString, required = false,
                                 default = nil)
  if valid_612471 != nil:
    section.add "X-Amz-Signature", valid_612471
  var valid_612472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612472 = validateParameter(valid_612472, JString, required = false,
                                 default = nil)
  if valid_612472 != nil:
    section.add "X-Amz-Content-Sha256", valid_612472
  var valid_612473 = header.getOrDefault("X-Amz-Date")
  valid_612473 = validateParameter(valid_612473, JString, required = false,
                                 default = nil)
  if valid_612473 != nil:
    section.add "X-Amz-Date", valid_612473
  var valid_612474 = header.getOrDefault("X-Amz-Credential")
  valid_612474 = validateParameter(valid_612474, JString, required = false,
                                 default = nil)
  if valid_612474 != nil:
    section.add "X-Amz-Credential", valid_612474
  var valid_612475 = header.getOrDefault("X-Amz-Security-Token")
  valid_612475 = validateParameter(valid_612475, JString, required = false,
                                 default = nil)
  if valid_612475 != nil:
    section.add "X-Amz-Security-Token", valid_612475
  var valid_612476 = header.getOrDefault("X-Amz-Algorithm")
  valid_612476 = validateParameter(valid_612476, JString, required = false,
                                 default = nil)
  if valid_612476 != nil:
    section.add "X-Amz-Algorithm", valid_612476
  var valid_612477 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612477 = validateParameter(valid_612477, JString, required = false,
                                 default = nil)
  if valid_612477 != nil:
    section.add "X-Amz-SignedHeaders", valid_612477
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612478: Call_GetRebuildEnvironment_612464; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes and recreates all of the AWS resources (for example: the Auto Scaling group, load balancer, etc.) for a specified environment and forces a restart.
  ## 
  let valid = call_612478.validator(path, query, header, formData, body)
  let scheme = call_612478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612478.url(scheme.get, call_612478.host, call_612478.base,
                         call_612478.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612478, url, valid)

proc call*(call_612479: Call_GetRebuildEnvironment_612464;
          EnvironmentName: string = ""; Action: string = "RebuildEnvironment";
          Version: string = "2010-12-01"; EnvironmentId: string = ""): Recallable =
  ## getRebuildEnvironment
  ## Deletes and recreates all of the AWS resources (for example: the Auto Scaling group, load balancer, etc.) for a specified environment and forces a restart.
  ##   EnvironmentName: string
  ##                  : <p>The name of the environment to rebuild.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   EnvironmentId: string
  ##                : <p>The ID of the environment to rebuild.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  var query_612480 = newJObject()
  add(query_612480, "EnvironmentName", newJString(EnvironmentName))
  add(query_612480, "Action", newJString(Action))
  add(query_612480, "Version", newJString(Version))
  add(query_612480, "EnvironmentId", newJString(EnvironmentId))
  result = call_612479.call(nil, query_612480, nil, nil, nil)

var getRebuildEnvironment* = Call_GetRebuildEnvironment_612464(
    name: "getRebuildEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RebuildEnvironment",
    validator: validate_GetRebuildEnvironment_612465, base: "/",
    url: url_GetRebuildEnvironment_612466, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRequestEnvironmentInfo_612517 = ref object of OpenApiRestCall_610659
proc url_PostRequestEnvironmentInfo_612519(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRequestEnvironmentInfo_612518(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Initiates a request to compile the specified type of information of the deployed environment.</p> <p> Setting the <code>InfoType</code> to <code>tail</code> compiles the last lines from the application server log files of every Amazon EC2 instance in your environment. </p> <p> Setting the <code>InfoType</code> to <code>bundle</code> compresses the application server log files for every Amazon EC2 instance into a <code>.zip</code> file. Legacy and .NET containers do not support bundle logs. </p> <p> Use <a>RetrieveEnvironmentInfo</a> to obtain the set of logs. </p> <p>Related Topics</p> <ul> <li> <p> <a>RetrieveEnvironmentInfo</a> </p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612520 = query.getOrDefault("Action")
  valid_612520 = validateParameter(valid_612520, JString, required = true,
                                 default = newJString("RequestEnvironmentInfo"))
  if valid_612520 != nil:
    section.add "Action", valid_612520
  var valid_612521 = query.getOrDefault("Version")
  valid_612521 = validateParameter(valid_612521, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612521 != nil:
    section.add "Version", valid_612521
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612522 = header.getOrDefault("X-Amz-Signature")
  valid_612522 = validateParameter(valid_612522, JString, required = false,
                                 default = nil)
  if valid_612522 != nil:
    section.add "X-Amz-Signature", valid_612522
  var valid_612523 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612523 = validateParameter(valid_612523, JString, required = false,
                                 default = nil)
  if valid_612523 != nil:
    section.add "X-Amz-Content-Sha256", valid_612523
  var valid_612524 = header.getOrDefault("X-Amz-Date")
  valid_612524 = validateParameter(valid_612524, JString, required = false,
                                 default = nil)
  if valid_612524 != nil:
    section.add "X-Amz-Date", valid_612524
  var valid_612525 = header.getOrDefault("X-Amz-Credential")
  valid_612525 = validateParameter(valid_612525, JString, required = false,
                                 default = nil)
  if valid_612525 != nil:
    section.add "X-Amz-Credential", valid_612525
  var valid_612526 = header.getOrDefault("X-Amz-Security-Token")
  valid_612526 = validateParameter(valid_612526, JString, required = false,
                                 default = nil)
  if valid_612526 != nil:
    section.add "X-Amz-Security-Token", valid_612526
  var valid_612527 = header.getOrDefault("X-Amz-Algorithm")
  valid_612527 = validateParameter(valid_612527, JString, required = false,
                                 default = nil)
  if valid_612527 != nil:
    section.add "X-Amz-Algorithm", valid_612527
  var valid_612528 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612528 = validateParameter(valid_612528, JString, required = false,
                                 default = nil)
  if valid_612528 != nil:
    section.add "X-Amz-SignedHeaders", valid_612528
  result.add "header", section
  ## parameters in `formData` object:
  ##   InfoType: JString (required)
  ##           : The type of information to request.
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment of the requested data.</p> <p>If no such environment is found, <code>RequestEnvironmentInfo</code> returns an <code>InvalidParameterValue</code> error. </p> <p>Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment of the requested data.</p> <p>If no such environment is found, <code>RequestEnvironmentInfo</code> returns an <code>InvalidParameterValue</code> error. </p> <p>Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_612529 = formData.getOrDefault("InfoType")
  valid_612529 = validateParameter(valid_612529, JString, required = true,
                                 default = newJString("tail"))
  if valid_612529 != nil:
    section.add "InfoType", valid_612529
  var valid_612530 = formData.getOrDefault("EnvironmentName")
  valid_612530 = validateParameter(valid_612530, JString, required = false,
                                 default = nil)
  if valid_612530 != nil:
    section.add "EnvironmentName", valid_612530
  var valid_612531 = formData.getOrDefault("EnvironmentId")
  valid_612531 = validateParameter(valid_612531, JString, required = false,
                                 default = nil)
  if valid_612531 != nil:
    section.add "EnvironmentId", valid_612531
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612532: Call_PostRequestEnvironmentInfo_612517; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a request to compile the specified type of information of the deployed environment.</p> <p> Setting the <code>InfoType</code> to <code>tail</code> compiles the last lines from the application server log files of every Amazon EC2 instance in your environment. </p> <p> Setting the <code>InfoType</code> to <code>bundle</code> compresses the application server log files for every Amazon EC2 instance into a <code>.zip</code> file. Legacy and .NET containers do not support bundle logs. </p> <p> Use <a>RetrieveEnvironmentInfo</a> to obtain the set of logs. </p> <p>Related Topics</p> <ul> <li> <p> <a>RetrieveEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_612532.validator(path, query, header, formData, body)
  let scheme = call_612532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612532.url(scheme.get, call_612532.host, call_612532.base,
                         call_612532.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612532, url, valid)

proc call*(call_612533: Call_PostRequestEnvironmentInfo_612517;
          InfoType: string = "tail"; EnvironmentName: string = "";
          Action: string = "RequestEnvironmentInfo"; EnvironmentId: string = "";
          Version: string = "2010-12-01"): Recallable =
  ## postRequestEnvironmentInfo
  ## <p>Initiates a request to compile the specified type of information of the deployed environment.</p> <p> Setting the <code>InfoType</code> to <code>tail</code> compiles the last lines from the application server log files of every Amazon EC2 instance in your environment. </p> <p> Setting the <code>InfoType</code> to <code>bundle</code> compresses the application server log files for every Amazon EC2 instance into a <code>.zip</code> file. Legacy and .NET containers do not support bundle logs. </p> <p> Use <a>RetrieveEnvironmentInfo</a> to obtain the set of logs. </p> <p>Related Topics</p> <ul> <li> <p> <a>RetrieveEnvironmentInfo</a> </p> </li> </ul>
  ##   InfoType: string (required)
  ##           : The type of information to request.
  ##   EnvironmentName: string
  ##                  : <p>The name of the environment of the requested data.</p> <p>If no such environment is found, <code>RequestEnvironmentInfo</code> returns an <code>InvalidParameterValue</code> error. </p> <p>Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Action: string (required)
  ##   EnvironmentId: string
  ##                : <p>The ID of the environment of the requested data.</p> <p>If no such environment is found, <code>RequestEnvironmentInfo</code> returns an <code>InvalidParameterValue</code> error. </p> <p>Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Version: string (required)
  var query_612534 = newJObject()
  var formData_612535 = newJObject()
  add(formData_612535, "InfoType", newJString(InfoType))
  add(formData_612535, "EnvironmentName", newJString(EnvironmentName))
  add(query_612534, "Action", newJString(Action))
  add(formData_612535, "EnvironmentId", newJString(EnvironmentId))
  add(query_612534, "Version", newJString(Version))
  result = call_612533.call(nil, query_612534, nil, formData_612535, nil)

var postRequestEnvironmentInfo* = Call_PostRequestEnvironmentInfo_612517(
    name: "postRequestEnvironmentInfo", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RequestEnvironmentInfo",
    validator: validate_PostRequestEnvironmentInfo_612518, base: "/",
    url: url_PostRequestEnvironmentInfo_612519,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRequestEnvironmentInfo_612499 = ref object of OpenApiRestCall_610659
proc url_GetRequestEnvironmentInfo_612501(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRequestEnvironmentInfo_612500(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Initiates a request to compile the specified type of information of the deployed environment.</p> <p> Setting the <code>InfoType</code> to <code>tail</code> compiles the last lines from the application server log files of every Amazon EC2 instance in your environment. </p> <p> Setting the <code>InfoType</code> to <code>bundle</code> compresses the application server log files for every Amazon EC2 instance into a <code>.zip</code> file. Legacy and .NET containers do not support bundle logs. </p> <p> Use <a>RetrieveEnvironmentInfo</a> to obtain the set of logs. </p> <p>Related Topics</p> <ul> <li> <p> <a>RetrieveEnvironmentInfo</a> </p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   InfoType: JString (required)
  ##           : The type of information to request.
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment of the requested data.</p> <p>If no such environment is found, <code>RequestEnvironmentInfo</code> returns an <code>InvalidParameterValue</code> error. </p> <p>Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment of the requested data.</p> <p>If no such environment is found, <code>RequestEnvironmentInfo</code> returns an <code>InvalidParameterValue</code> error. </p> <p>Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_612502 = query.getOrDefault("InfoType")
  valid_612502 = validateParameter(valid_612502, JString, required = true,
                                 default = newJString("tail"))
  if valid_612502 != nil:
    section.add "InfoType", valid_612502
  var valid_612503 = query.getOrDefault("EnvironmentName")
  valid_612503 = validateParameter(valid_612503, JString, required = false,
                                 default = nil)
  if valid_612503 != nil:
    section.add "EnvironmentName", valid_612503
  var valid_612504 = query.getOrDefault("Action")
  valid_612504 = validateParameter(valid_612504, JString, required = true,
                                 default = newJString("RequestEnvironmentInfo"))
  if valid_612504 != nil:
    section.add "Action", valid_612504
  var valid_612505 = query.getOrDefault("Version")
  valid_612505 = validateParameter(valid_612505, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612505 != nil:
    section.add "Version", valid_612505
  var valid_612506 = query.getOrDefault("EnvironmentId")
  valid_612506 = validateParameter(valid_612506, JString, required = false,
                                 default = nil)
  if valid_612506 != nil:
    section.add "EnvironmentId", valid_612506
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612507 = header.getOrDefault("X-Amz-Signature")
  valid_612507 = validateParameter(valid_612507, JString, required = false,
                                 default = nil)
  if valid_612507 != nil:
    section.add "X-Amz-Signature", valid_612507
  var valid_612508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612508 = validateParameter(valid_612508, JString, required = false,
                                 default = nil)
  if valid_612508 != nil:
    section.add "X-Amz-Content-Sha256", valid_612508
  var valid_612509 = header.getOrDefault("X-Amz-Date")
  valid_612509 = validateParameter(valid_612509, JString, required = false,
                                 default = nil)
  if valid_612509 != nil:
    section.add "X-Amz-Date", valid_612509
  var valid_612510 = header.getOrDefault("X-Amz-Credential")
  valid_612510 = validateParameter(valid_612510, JString, required = false,
                                 default = nil)
  if valid_612510 != nil:
    section.add "X-Amz-Credential", valid_612510
  var valid_612511 = header.getOrDefault("X-Amz-Security-Token")
  valid_612511 = validateParameter(valid_612511, JString, required = false,
                                 default = nil)
  if valid_612511 != nil:
    section.add "X-Amz-Security-Token", valid_612511
  var valid_612512 = header.getOrDefault("X-Amz-Algorithm")
  valid_612512 = validateParameter(valid_612512, JString, required = false,
                                 default = nil)
  if valid_612512 != nil:
    section.add "X-Amz-Algorithm", valid_612512
  var valid_612513 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612513 = validateParameter(valid_612513, JString, required = false,
                                 default = nil)
  if valid_612513 != nil:
    section.add "X-Amz-SignedHeaders", valid_612513
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612514: Call_GetRequestEnvironmentInfo_612499; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a request to compile the specified type of information of the deployed environment.</p> <p> Setting the <code>InfoType</code> to <code>tail</code> compiles the last lines from the application server log files of every Amazon EC2 instance in your environment. </p> <p> Setting the <code>InfoType</code> to <code>bundle</code> compresses the application server log files for every Amazon EC2 instance into a <code>.zip</code> file. Legacy and .NET containers do not support bundle logs. </p> <p> Use <a>RetrieveEnvironmentInfo</a> to obtain the set of logs. </p> <p>Related Topics</p> <ul> <li> <p> <a>RetrieveEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_612514.validator(path, query, header, formData, body)
  let scheme = call_612514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612514.url(scheme.get, call_612514.host, call_612514.base,
                         call_612514.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612514, url, valid)

proc call*(call_612515: Call_GetRequestEnvironmentInfo_612499;
          InfoType: string = "tail"; EnvironmentName: string = "";
          Action: string = "RequestEnvironmentInfo"; Version: string = "2010-12-01";
          EnvironmentId: string = ""): Recallable =
  ## getRequestEnvironmentInfo
  ## <p>Initiates a request to compile the specified type of information of the deployed environment.</p> <p> Setting the <code>InfoType</code> to <code>tail</code> compiles the last lines from the application server log files of every Amazon EC2 instance in your environment. </p> <p> Setting the <code>InfoType</code> to <code>bundle</code> compresses the application server log files for every Amazon EC2 instance into a <code>.zip</code> file. Legacy and .NET containers do not support bundle logs. </p> <p> Use <a>RetrieveEnvironmentInfo</a> to obtain the set of logs. </p> <p>Related Topics</p> <ul> <li> <p> <a>RetrieveEnvironmentInfo</a> </p> </li> </ul>
  ##   InfoType: string (required)
  ##           : The type of information to request.
  ##   EnvironmentName: string
  ##                  : <p>The name of the environment of the requested data.</p> <p>If no such environment is found, <code>RequestEnvironmentInfo</code> returns an <code>InvalidParameterValue</code> error. </p> <p>Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   EnvironmentId: string
  ##                : <p>The ID of the environment of the requested data.</p> <p>If no such environment is found, <code>RequestEnvironmentInfo</code> returns an <code>InvalidParameterValue</code> error. </p> <p>Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  var query_612516 = newJObject()
  add(query_612516, "InfoType", newJString(InfoType))
  add(query_612516, "EnvironmentName", newJString(EnvironmentName))
  add(query_612516, "Action", newJString(Action))
  add(query_612516, "Version", newJString(Version))
  add(query_612516, "EnvironmentId", newJString(EnvironmentId))
  result = call_612515.call(nil, query_612516, nil, nil, nil)

var getRequestEnvironmentInfo* = Call_GetRequestEnvironmentInfo_612499(
    name: "getRequestEnvironmentInfo", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RequestEnvironmentInfo",
    validator: validate_GetRequestEnvironmentInfo_612500, base: "/",
    url: url_GetRequestEnvironmentInfo_612501,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestartAppServer_612553 = ref object of OpenApiRestCall_610659
proc url_PostRestartAppServer_612555(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRestartAppServer_612554(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Causes the environment to restart the application container server running on each Amazon EC2 instance.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612556 = query.getOrDefault("Action")
  valid_612556 = validateParameter(valid_612556, JString, required = true,
                                 default = newJString("RestartAppServer"))
  if valid_612556 != nil:
    section.add "Action", valid_612556
  var valid_612557 = query.getOrDefault("Version")
  valid_612557 = validateParameter(valid_612557, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612557 != nil:
    section.add "Version", valid_612557
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612558 = header.getOrDefault("X-Amz-Signature")
  valid_612558 = validateParameter(valid_612558, JString, required = false,
                                 default = nil)
  if valid_612558 != nil:
    section.add "X-Amz-Signature", valid_612558
  var valid_612559 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612559 = validateParameter(valid_612559, JString, required = false,
                                 default = nil)
  if valid_612559 != nil:
    section.add "X-Amz-Content-Sha256", valid_612559
  var valid_612560 = header.getOrDefault("X-Amz-Date")
  valid_612560 = validateParameter(valid_612560, JString, required = false,
                                 default = nil)
  if valid_612560 != nil:
    section.add "X-Amz-Date", valid_612560
  var valid_612561 = header.getOrDefault("X-Amz-Credential")
  valid_612561 = validateParameter(valid_612561, JString, required = false,
                                 default = nil)
  if valid_612561 != nil:
    section.add "X-Amz-Credential", valid_612561
  var valid_612562 = header.getOrDefault("X-Amz-Security-Token")
  valid_612562 = validateParameter(valid_612562, JString, required = false,
                                 default = nil)
  if valid_612562 != nil:
    section.add "X-Amz-Security-Token", valid_612562
  var valid_612563 = header.getOrDefault("X-Amz-Algorithm")
  valid_612563 = validateParameter(valid_612563, JString, required = false,
                                 default = nil)
  if valid_612563 != nil:
    section.add "X-Amz-Algorithm", valid_612563
  var valid_612564 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612564 = validateParameter(valid_612564, JString, required = false,
                                 default = nil)
  if valid_612564 != nil:
    section.add "X-Amz-SignedHeaders", valid_612564
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to restart the server for.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to restart the server for.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_612565 = formData.getOrDefault("EnvironmentName")
  valid_612565 = validateParameter(valid_612565, JString, required = false,
                                 default = nil)
  if valid_612565 != nil:
    section.add "EnvironmentName", valid_612565
  var valid_612566 = formData.getOrDefault("EnvironmentId")
  valid_612566 = validateParameter(valid_612566, JString, required = false,
                                 default = nil)
  if valid_612566 != nil:
    section.add "EnvironmentId", valid_612566
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612567: Call_PostRestartAppServer_612553; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Causes the environment to restart the application container server running on each Amazon EC2 instance.
  ## 
  let valid = call_612567.validator(path, query, header, formData, body)
  let scheme = call_612567.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612567.url(scheme.get, call_612567.host, call_612567.base,
                         call_612567.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612567, url, valid)

proc call*(call_612568: Call_PostRestartAppServer_612553;
          EnvironmentName: string = ""; Action: string = "RestartAppServer";
          EnvironmentId: string = ""; Version: string = "2010-12-01"): Recallable =
  ## postRestartAppServer
  ## Causes the environment to restart the application container server running on each Amazon EC2 instance.
  ##   EnvironmentName: string
  ##                  : <p>The name of the environment to restart the server for.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Action: string (required)
  ##   EnvironmentId: string
  ##                : <p>The ID of the environment to restart the server for.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Version: string (required)
  var query_612569 = newJObject()
  var formData_612570 = newJObject()
  add(formData_612570, "EnvironmentName", newJString(EnvironmentName))
  add(query_612569, "Action", newJString(Action))
  add(formData_612570, "EnvironmentId", newJString(EnvironmentId))
  add(query_612569, "Version", newJString(Version))
  result = call_612568.call(nil, query_612569, nil, formData_612570, nil)

var postRestartAppServer* = Call_PostRestartAppServer_612553(
    name: "postRestartAppServer", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RestartAppServer",
    validator: validate_PostRestartAppServer_612554, base: "/",
    url: url_PostRestartAppServer_612555, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestartAppServer_612536 = ref object of OpenApiRestCall_610659
proc url_GetRestartAppServer_612538(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRestartAppServer_612537(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Causes the environment to restart the application container server running on each Amazon EC2 instance.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to restart the server for.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to restart the server for.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_612539 = query.getOrDefault("EnvironmentName")
  valid_612539 = validateParameter(valid_612539, JString, required = false,
                                 default = nil)
  if valid_612539 != nil:
    section.add "EnvironmentName", valid_612539
  var valid_612540 = query.getOrDefault("Action")
  valid_612540 = validateParameter(valid_612540, JString, required = true,
                                 default = newJString("RestartAppServer"))
  if valid_612540 != nil:
    section.add "Action", valid_612540
  var valid_612541 = query.getOrDefault("Version")
  valid_612541 = validateParameter(valid_612541, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612541 != nil:
    section.add "Version", valid_612541
  var valid_612542 = query.getOrDefault("EnvironmentId")
  valid_612542 = validateParameter(valid_612542, JString, required = false,
                                 default = nil)
  if valid_612542 != nil:
    section.add "EnvironmentId", valid_612542
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612543 = header.getOrDefault("X-Amz-Signature")
  valid_612543 = validateParameter(valid_612543, JString, required = false,
                                 default = nil)
  if valid_612543 != nil:
    section.add "X-Amz-Signature", valid_612543
  var valid_612544 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612544 = validateParameter(valid_612544, JString, required = false,
                                 default = nil)
  if valid_612544 != nil:
    section.add "X-Amz-Content-Sha256", valid_612544
  var valid_612545 = header.getOrDefault("X-Amz-Date")
  valid_612545 = validateParameter(valid_612545, JString, required = false,
                                 default = nil)
  if valid_612545 != nil:
    section.add "X-Amz-Date", valid_612545
  var valid_612546 = header.getOrDefault("X-Amz-Credential")
  valid_612546 = validateParameter(valid_612546, JString, required = false,
                                 default = nil)
  if valid_612546 != nil:
    section.add "X-Amz-Credential", valid_612546
  var valid_612547 = header.getOrDefault("X-Amz-Security-Token")
  valid_612547 = validateParameter(valid_612547, JString, required = false,
                                 default = nil)
  if valid_612547 != nil:
    section.add "X-Amz-Security-Token", valid_612547
  var valid_612548 = header.getOrDefault("X-Amz-Algorithm")
  valid_612548 = validateParameter(valid_612548, JString, required = false,
                                 default = nil)
  if valid_612548 != nil:
    section.add "X-Amz-Algorithm", valid_612548
  var valid_612549 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612549 = validateParameter(valid_612549, JString, required = false,
                                 default = nil)
  if valid_612549 != nil:
    section.add "X-Amz-SignedHeaders", valid_612549
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612550: Call_GetRestartAppServer_612536; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Causes the environment to restart the application container server running on each Amazon EC2 instance.
  ## 
  let valid = call_612550.validator(path, query, header, formData, body)
  let scheme = call_612550.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612550.url(scheme.get, call_612550.host, call_612550.base,
                         call_612550.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612550, url, valid)

proc call*(call_612551: Call_GetRestartAppServer_612536;
          EnvironmentName: string = ""; Action: string = "RestartAppServer";
          Version: string = "2010-12-01"; EnvironmentId: string = ""): Recallable =
  ## getRestartAppServer
  ## Causes the environment to restart the application container server running on each Amazon EC2 instance.
  ##   EnvironmentName: string
  ##                  : <p>The name of the environment to restart the server for.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   EnvironmentId: string
  ##                : <p>The ID of the environment to restart the server for.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  var query_612552 = newJObject()
  add(query_612552, "EnvironmentName", newJString(EnvironmentName))
  add(query_612552, "Action", newJString(Action))
  add(query_612552, "Version", newJString(Version))
  add(query_612552, "EnvironmentId", newJString(EnvironmentId))
  result = call_612551.call(nil, query_612552, nil, nil, nil)

var getRestartAppServer* = Call_GetRestartAppServer_612536(
    name: "getRestartAppServer", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RestartAppServer",
    validator: validate_GetRestartAppServer_612537, base: "/",
    url: url_GetRestartAppServer_612538, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRetrieveEnvironmentInfo_612589 = ref object of OpenApiRestCall_610659
proc url_PostRetrieveEnvironmentInfo_612591(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRetrieveEnvironmentInfo_612590(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the compiled information from a <a>RequestEnvironmentInfo</a> request.</p> <p>Related Topics</p> <ul> <li> <p> <a>RequestEnvironmentInfo</a> </p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612592 = query.getOrDefault("Action")
  valid_612592 = validateParameter(valid_612592, JString, required = true, default = newJString(
      "RetrieveEnvironmentInfo"))
  if valid_612592 != nil:
    section.add "Action", valid_612592
  var valid_612593 = query.getOrDefault("Version")
  valid_612593 = validateParameter(valid_612593, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612593 != nil:
    section.add "Version", valid_612593
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612594 = header.getOrDefault("X-Amz-Signature")
  valid_612594 = validateParameter(valid_612594, JString, required = false,
                                 default = nil)
  if valid_612594 != nil:
    section.add "X-Amz-Signature", valid_612594
  var valid_612595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612595 = validateParameter(valid_612595, JString, required = false,
                                 default = nil)
  if valid_612595 != nil:
    section.add "X-Amz-Content-Sha256", valid_612595
  var valid_612596 = header.getOrDefault("X-Amz-Date")
  valid_612596 = validateParameter(valid_612596, JString, required = false,
                                 default = nil)
  if valid_612596 != nil:
    section.add "X-Amz-Date", valid_612596
  var valid_612597 = header.getOrDefault("X-Amz-Credential")
  valid_612597 = validateParameter(valid_612597, JString, required = false,
                                 default = nil)
  if valid_612597 != nil:
    section.add "X-Amz-Credential", valid_612597
  var valid_612598 = header.getOrDefault("X-Amz-Security-Token")
  valid_612598 = validateParameter(valid_612598, JString, required = false,
                                 default = nil)
  if valid_612598 != nil:
    section.add "X-Amz-Security-Token", valid_612598
  var valid_612599 = header.getOrDefault("X-Amz-Algorithm")
  valid_612599 = validateParameter(valid_612599, JString, required = false,
                                 default = nil)
  if valid_612599 != nil:
    section.add "X-Amz-Algorithm", valid_612599
  var valid_612600 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612600 = validateParameter(valid_612600, JString, required = false,
                                 default = nil)
  if valid_612600 != nil:
    section.add "X-Amz-SignedHeaders", valid_612600
  result.add "header", section
  ## parameters in `formData` object:
  ##   InfoType: JString (required)
  ##           : The type of information to retrieve.
  ##   EnvironmentName: JString
  ##                  : <p>The name of the data's environment.</p> <p> If no such environment is found, returns an <code>InvalidParameterValue</code> error. </p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentId: JString
  ##                : <p>The ID of the data's environment.</p> <p>If no such environment is found, returns an <code>InvalidParameterValue</code> error.</p> <p>Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error.</p>
  section = newJObject()
  var valid_612601 = formData.getOrDefault("InfoType")
  valid_612601 = validateParameter(valid_612601, JString, required = true,
                                 default = newJString("tail"))
  if valid_612601 != nil:
    section.add "InfoType", valid_612601
  var valid_612602 = formData.getOrDefault("EnvironmentName")
  valid_612602 = validateParameter(valid_612602, JString, required = false,
                                 default = nil)
  if valid_612602 != nil:
    section.add "EnvironmentName", valid_612602
  var valid_612603 = formData.getOrDefault("EnvironmentId")
  valid_612603 = validateParameter(valid_612603, JString, required = false,
                                 default = nil)
  if valid_612603 != nil:
    section.add "EnvironmentId", valid_612603
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612604: Call_PostRetrieveEnvironmentInfo_612589; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the compiled information from a <a>RequestEnvironmentInfo</a> request.</p> <p>Related Topics</p> <ul> <li> <p> <a>RequestEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_612604.validator(path, query, header, formData, body)
  let scheme = call_612604.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612604.url(scheme.get, call_612604.host, call_612604.base,
                         call_612604.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612604, url, valid)

proc call*(call_612605: Call_PostRetrieveEnvironmentInfo_612589;
          InfoType: string = "tail"; EnvironmentName: string = "";
          Action: string = "RetrieveEnvironmentInfo"; EnvironmentId: string = "";
          Version: string = "2010-12-01"): Recallable =
  ## postRetrieveEnvironmentInfo
  ## <p>Retrieves the compiled information from a <a>RequestEnvironmentInfo</a> request.</p> <p>Related Topics</p> <ul> <li> <p> <a>RequestEnvironmentInfo</a> </p> </li> </ul>
  ##   InfoType: string (required)
  ##           : The type of information to retrieve.
  ##   EnvironmentName: string
  ##                  : <p>The name of the data's environment.</p> <p> If no such environment is found, returns an <code>InvalidParameterValue</code> error. </p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Action: string (required)
  ##   EnvironmentId: string
  ##                : <p>The ID of the data's environment.</p> <p>If no such environment is found, returns an <code>InvalidParameterValue</code> error.</p> <p>Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error.</p>
  ##   Version: string (required)
  var query_612606 = newJObject()
  var formData_612607 = newJObject()
  add(formData_612607, "InfoType", newJString(InfoType))
  add(formData_612607, "EnvironmentName", newJString(EnvironmentName))
  add(query_612606, "Action", newJString(Action))
  add(formData_612607, "EnvironmentId", newJString(EnvironmentId))
  add(query_612606, "Version", newJString(Version))
  result = call_612605.call(nil, query_612606, nil, formData_612607, nil)

var postRetrieveEnvironmentInfo* = Call_PostRetrieveEnvironmentInfo_612589(
    name: "postRetrieveEnvironmentInfo", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RetrieveEnvironmentInfo",
    validator: validate_PostRetrieveEnvironmentInfo_612590, base: "/",
    url: url_PostRetrieveEnvironmentInfo_612591,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRetrieveEnvironmentInfo_612571 = ref object of OpenApiRestCall_610659
proc url_GetRetrieveEnvironmentInfo_612573(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRetrieveEnvironmentInfo_612572(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the compiled information from a <a>RequestEnvironmentInfo</a> request.</p> <p>Related Topics</p> <ul> <li> <p> <a>RequestEnvironmentInfo</a> </p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   InfoType: JString (required)
  ##           : The type of information to retrieve.
  ##   EnvironmentName: JString
  ##                  : <p>The name of the data's environment.</p> <p> If no such environment is found, returns an <code>InvalidParameterValue</code> error. </p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   EnvironmentId: JString
  ##                : <p>The ID of the data's environment.</p> <p>If no such environment is found, returns an <code>InvalidParameterValue</code> error.</p> <p>Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error.</p>
  section = newJObject()
  var valid_612574 = query.getOrDefault("InfoType")
  valid_612574 = validateParameter(valid_612574, JString, required = true,
                                 default = newJString("tail"))
  if valid_612574 != nil:
    section.add "InfoType", valid_612574
  var valid_612575 = query.getOrDefault("EnvironmentName")
  valid_612575 = validateParameter(valid_612575, JString, required = false,
                                 default = nil)
  if valid_612575 != nil:
    section.add "EnvironmentName", valid_612575
  var valid_612576 = query.getOrDefault("Action")
  valid_612576 = validateParameter(valid_612576, JString, required = true, default = newJString(
      "RetrieveEnvironmentInfo"))
  if valid_612576 != nil:
    section.add "Action", valid_612576
  var valid_612577 = query.getOrDefault("Version")
  valid_612577 = validateParameter(valid_612577, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612577 != nil:
    section.add "Version", valid_612577
  var valid_612578 = query.getOrDefault("EnvironmentId")
  valid_612578 = validateParameter(valid_612578, JString, required = false,
                                 default = nil)
  if valid_612578 != nil:
    section.add "EnvironmentId", valid_612578
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612579 = header.getOrDefault("X-Amz-Signature")
  valid_612579 = validateParameter(valid_612579, JString, required = false,
                                 default = nil)
  if valid_612579 != nil:
    section.add "X-Amz-Signature", valid_612579
  var valid_612580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612580 = validateParameter(valid_612580, JString, required = false,
                                 default = nil)
  if valid_612580 != nil:
    section.add "X-Amz-Content-Sha256", valid_612580
  var valid_612581 = header.getOrDefault("X-Amz-Date")
  valid_612581 = validateParameter(valid_612581, JString, required = false,
                                 default = nil)
  if valid_612581 != nil:
    section.add "X-Amz-Date", valid_612581
  var valid_612582 = header.getOrDefault("X-Amz-Credential")
  valid_612582 = validateParameter(valid_612582, JString, required = false,
                                 default = nil)
  if valid_612582 != nil:
    section.add "X-Amz-Credential", valid_612582
  var valid_612583 = header.getOrDefault("X-Amz-Security-Token")
  valid_612583 = validateParameter(valid_612583, JString, required = false,
                                 default = nil)
  if valid_612583 != nil:
    section.add "X-Amz-Security-Token", valid_612583
  var valid_612584 = header.getOrDefault("X-Amz-Algorithm")
  valid_612584 = validateParameter(valid_612584, JString, required = false,
                                 default = nil)
  if valid_612584 != nil:
    section.add "X-Amz-Algorithm", valid_612584
  var valid_612585 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612585 = validateParameter(valid_612585, JString, required = false,
                                 default = nil)
  if valid_612585 != nil:
    section.add "X-Amz-SignedHeaders", valid_612585
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612586: Call_GetRetrieveEnvironmentInfo_612571; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the compiled information from a <a>RequestEnvironmentInfo</a> request.</p> <p>Related Topics</p> <ul> <li> <p> <a>RequestEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_612586.validator(path, query, header, formData, body)
  let scheme = call_612586.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612586.url(scheme.get, call_612586.host, call_612586.base,
                         call_612586.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612586, url, valid)

proc call*(call_612587: Call_GetRetrieveEnvironmentInfo_612571;
          InfoType: string = "tail"; EnvironmentName: string = "";
          Action: string = "RetrieveEnvironmentInfo";
          Version: string = "2010-12-01"; EnvironmentId: string = ""): Recallable =
  ## getRetrieveEnvironmentInfo
  ## <p>Retrieves the compiled information from a <a>RequestEnvironmentInfo</a> request.</p> <p>Related Topics</p> <ul> <li> <p> <a>RequestEnvironmentInfo</a> </p> </li> </ul>
  ##   InfoType: string (required)
  ##           : The type of information to retrieve.
  ##   EnvironmentName: string
  ##                  : <p>The name of the data's environment.</p> <p> If no such environment is found, returns an <code>InvalidParameterValue</code> error. </p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   EnvironmentId: string
  ##                : <p>The ID of the data's environment.</p> <p>If no such environment is found, returns an <code>InvalidParameterValue</code> error.</p> <p>Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error.</p>
  var query_612588 = newJObject()
  add(query_612588, "InfoType", newJString(InfoType))
  add(query_612588, "EnvironmentName", newJString(EnvironmentName))
  add(query_612588, "Action", newJString(Action))
  add(query_612588, "Version", newJString(Version))
  add(query_612588, "EnvironmentId", newJString(EnvironmentId))
  result = call_612587.call(nil, query_612588, nil, nil, nil)

var getRetrieveEnvironmentInfo* = Call_GetRetrieveEnvironmentInfo_612571(
    name: "getRetrieveEnvironmentInfo", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RetrieveEnvironmentInfo",
    validator: validate_GetRetrieveEnvironmentInfo_612572, base: "/",
    url: url_GetRetrieveEnvironmentInfo_612573,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSwapEnvironmentCNAMEs_612627 = ref object of OpenApiRestCall_610659
proc url_PostSwapEnvironmentCNAMEs_612629(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSwapEnvironmentCNAMEs_612628(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Swaps the CNAMEs of two environments.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612630 = query.getOrDefault("Action")
  valid_612630 = validateParameter(valid_612630, JString, required = true,
                                 default = newJString("SwapEnvironmentCNAMEs"))
  if valid_612630 != nil:
    section.add "Action", valid_612630
  var valid_612631 = query.getOrDefault("Version")
  valid_612631 = validateParameter(valid_612631, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612631 != nil:
    section.add "Version", valid_612631
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612632 = header.getOrDefault("X-Amz-Signature")
  valid_612632 = validateParameter(valid_612632, JString, required = false,
                                 default = nil)
  if valid_612632 != nil:
    section.add "X-Amz-Signature", valid_612632
  var valid_612633 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612633 = validateParameter(valid_612633, JString, required = false,
                                 default = nil)
  if valid_612633 != nil:
    section.add "X-Amz-Content-Sha256", valid_612633
  var valid_612634 = header.getOrDefault("X-Amz-Date")
  valid_612634 = validateParameter(valid_612634, JString, required = false,
                                 default = nil)
  if valid_612634 != nil:
    section.add "X-Amz-Date", valid_612634
  var valid_612635 = header.getOrDefault("X-Amz-Credential")
  valid_612635 = validateParameter(valid_612635, JString, required = false,
                                 default = nil)
  if valid_612635 != nil:
    section.add "X-Amz-Credential", valid_612635
  var valid_612636 = header.getOrDefault("X-Amz-Security-Token")
  valid_612636 = validateParameter(valid_612636, JString, required = false,
                                 default = nil)
  if valid_612636 != nil:
    section.add "X-Amz-Security-Token", valid_612636
  var valid_612637 = header.getOrDefault("X-Amz-Algorithm")
  valid_612637 = validateParameter(valid_612637, JString, required = false,
                                 default = nil)
  if valid_612637 != nil:
    section.add "X-Amz-Algorithm", valid_612637
  var valid_612638 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612638 = validateParameter(valid_612638, JString, required = false,
                                 default = nil)
  if valid_612638 != nil:
    section.add "X-Amz-SignedHeaders", valid_612638
  result.add "header", section
  ## parameters in `formData` object:
  ##   DestinationEnvironmentName: JString
  ##                             : <p>The name of the destination environment.</p> <p> Condition: You must specify at least the <code>DestinationEnvironmentID</code> or the <code>DestinationEnvironmentName</code>. You may also specify both. You must specify the <code>SourceEnvironmentName</code> with the <code>DestinationEnvironmentName</code>. </p>
  ##   DestinationEnvironmentId: JString
  ##                           : <p>The ID of the destination environment.</p> <p> Condition: You must specify at least the <code>DestinationEnvironmentID</code> or the <code>DestinationEnvironmentName</code>. You may also specify both. You must specify the <code>SourceEnvironmentId</code> with the <code>DestinationEnvironmentId</code>. </p>
  ##   SourceEnvironmentId: JString
  ##                      : <p>The ID of the source environment.</p> <p> Condition: You must specify at least the <code>SourceEnvironmentID</code> or the <code>SourceEnvironmentName</code>. You may also specify both. If you specify the <code>SourceEnvironmentId</code>, you must specify the <code>DestinationEnvironmentId</code>. </p>
  ##   SourceEnvironmentName: JString
  ##                        : <p>The name of the source environment.</p> <p> Condition: You must specify at least the <code>SourceEnvironmentID</code> or the <code>SourceEnvironmentName</code>. You may also specify both. If you specify the <code>SourceEnvironmentName</code>, you must specify the <code>DestinationEnvironmentName</code>. </p>
  section = newJObject()
  var valid_612639 = formData.getOrDefault("DestinationEnvironmentName")
  valid_612639 = validateParameter(valid_612639, JString, required = false,
                                 default = nil)
  if valid_612639 != nil:
    section.add "DestinationEnvironmentName", valid_612639
  var valid_612640 = formData.getOrDefault("DestinationEnvironmentId")
  valid_612640 = validateParameter(valid_612640, JString, required = false,
                                 default = nil)
  if valid_612640 != nil:
    section.add "DestinationEnvironmentId", valid_612640
  var valid_612641 = formData.getOrDefault("SourceEnvironmentId")
  valid_612641 = validateParameter(valid_612641, JString, required = false,
                                 default = nil)
  if valid_612641 != nil:
    section.add "SourceEnvironmentId", valid_612641
  var valid_612642 = formData.getOrDefault("SourceEnvironmentName")
  valid_612642 = validateParameter(valid_612642, JString, required = false,
                                 default = nil)
  if valid_612642 != nil:
    section.add "SourceEnvironmentName", valid_612642
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612643: Call_PostSwapEnvironmentCNAMEs_612627; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Swaps the CNAMEs of two environments.
  ## 
  let valid = call_612643.validator(path, query, header, formData, body)
  let scheme = call_612643.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612643.url(scheme.get, call_612643.host, call_612643.base,
                         call_612643.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612643, url, valid)

proc call*(call_612644: Call_PostSwapEnvironmentCNAMEs_612627;
          DestinationEnvironmentName: string = "";
          DestinationEnvironmentId: string = ""; SourceEnvironmentId: string = "";
          SourceEnvironmentName: string = "";
          Action: string = "SwapEnvironmentCNAMEs"; Version: string = "2010-12-01"): Recallable =
  ## postSwapEnvironmentCNAMEs
  ## Swaps the CNAMEs of two environments.
  ##   DestinationEnvironmentName: string
  ##                             : <p>The name of the destination environment.</p> <p> Condition: You must specify at least the <code>DestinationEnvironmentID</code> or the <code>DestinationEnvironmentName</code>. You may also specify both. You must specify the <code>SourceEnvironmentName</code> with the <code>DestinationEnvironmentName</code>. </p>
  ##   DestinationEnvironmentId: string
  ##                           : <p>The ID of the destination environment.</p> <p> Condition: You must specify at least the <code>DestinationEnvironmentID</code> or the <code>DestinationEnvironmentName</code>. You may also specify both. You must specify the <code>SourceEnvironmentId</code> with the <code>DestinationEnvironmentId</code>. </p>
  ##   SourceEnvironmentId: string
  ##                      : <p>The ID of the source environment.</p> <p> Condition: You must specify at least the <code>SourceEnvironmentID</code> or the <code>SourceEnvironmentName</code>. You may also specify both. If you specify the <code>SourceEnvironmentId</code>, you must specify the <code>DestinationEnvironmentId</code>. </p>
  ##   SourceEnvironmentName: string
  ##                        : <p>The name of the source environment.</p> <p> Condition: You must specify at least the <code>SourceEnvironmentID</code> or the <code>SourceEnvironmentName</code>. You may also specify both. If you specify the <code>SourceEnvironmentName</code>, you must specify the <code>DestinationEnvironmentName</code>. </p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612645 = newJObject()
  var formData_612646 = newJObject()
  add(formData_612646, "DestinationEnvironmentName",
      newJString(DestinationEnvironmentName))
  add(formData_612646, "DestinationEnvironmentId",
      newJString(DestinationEnvironmentId))
  add(formData_612646, "SourceEnvironmentId", newJString(SourceEnvironmentId))
  add(formData_612646, "SourceEnvironmentName", newJString(SourceEnvironmentName))
  add(query_612645, "Action", newJString(Action))
  add(query_612645, "Version", newJString(Version))
  result = call_612644.call(nil, query_612645, nil, formData_612646, nil)

var postSwapEnvironmentCNAMEs* = Call_PostSwapEnvironmentCNAMEs_612627(
    name: "postSwapEnvironmentCNAMEs", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=SwapEnvironmentCNAMEs",
    validator: validate_PostSwapEnvironmentCNAMEs_612628, base: "/",
    url: url_PostSwapEnvironmentCNAMEs_612629,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSwapEnvironmentCNAMEs_612608 = ref object of OpenApiRestCall_610659
proc url_GetSwapEnvironmentCNAMEs_612610(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSwapEnvironmentCNAMEs_612609(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Swaps the CNAMEs of two environments.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceEnvironmentId: JString
  ##                      : <p>The ID of the source environment.</p> <p> Condition: You must specify at least the <code>SourceEnvironmentID</code> or the <code>SourceEnvironmentName</code>. You may also specify both. If you specify the <code>SourceEnvironmentId</code>, you must specify the <code>DestinationEnvironmentId</code>. </p>
  ##   SourceEnvironmentName: JString
  ##                        : <p>The name of the source environment.</p> <p> Condition: You must specify at least the <code>SourceEnvironmentID</code> or the <code>SourceEnvironmentName</code>. You may also specify both. If you specify the <code>SourceEnvironmentName</code>, you must specify the <code>DestinationEnvironmentName</code>. </p>
  ##   DestinationEnvironmentName: JString
  ##                             : <p>The name of the destination environment.</p> <p> Condition: You must specify at least the <code>DestinationEnvironmentID</code> or the <code>DestinationEnvironmentName</code>. You may also specify both. You must specify the <code>SourceEnvironmentName</code> with the <code>DestinationEnvironmentName</code>. </p>
  ##   Action: JString (required)
  ##   DestinationEnvironmentId: JString
  ##                           : <p>The ID of the destination environment.</p> <p> Condition: You must specify at least the <code>DestinationEnvironmentID</code> or the <code>DestinationEnvironmentName</code>. You may also specify both. You must specify the <code>SourceEnvironmentId</code> with the <code>DestinationEnvironmentId</code>. </p>
  ##   Version: JString (required)
  section = newJObject()
  var valid_612611 = query.getOrDefault("SourceEnvironmentId")
  valid_612611 = validateParameter(valid_612611, JString, required = false,
                                 default = nil)
  if valid_612611 != nil:
    section.add "SourceEnvironmentId", valid_612611
  var valid_612612 = query.getOrDefault("SourceEnvironmentName")
  valid_612612 = validateParameter(valid_612612, JString, required = false,
                                 default = nil)
  if valid_612612 != nil:
    section.add "SourceEnvironmentName", valid_612612
  var valid_612613 = query.getOrDefault("DestinationEnvironmentName")
  valid_612613 = validateParameter(valid_612613, JString, required = false,
                                 default = nil)
  if valid_612613 != nil:
    section.add "DestinationEnvironmentName", valid_612613
  var valid_612614 = query.getOrDefault("Action")
  valid_612614 = validateParameter(valid_612614, JString, required = true,
                                 default = newJString("SwapEnvironmentCNAMEs"))
  if valid_612614 != nil:
    section.add "Action", valid_612614
  var valid_612615 = query.getOrDefault("DestinationEnvironmentId")
  valid_612615 = validateParameter(valid_612615, JString, required = false,
                                 default = nil)
  if valid_612615 != nil:
    section.add "DestinationEnvironmentId", valid_612615
  var valid_612616 = query.getOrDefault("Version")
  valid_612616 = validateParameter(valid_612616, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612616 != nil:
    section.add "Version", valid_612616
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612617 = header.getOrDefault("X-Amz-Signature")
  valid_612617 = validateParameter(valid_612617, JString, required = false,
                                 default = nil)
  if valid_612617 != nil:
    section.add "X-Amz-Signature", valid_612617
  var valid_612618 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612618 = validateParameter(valid_612618, JString, required = false,
                                 default = nil)
  if valid_612618 != nil:
    section.add "X-Amz-Content-Sha256", valid_612618
  var valid_612619 = header.getOrDefault("X-Amz-Date")
  valid_612619 = validateParameter(valid_612619, JString, required = false,
                                 default = nil)
  if valid_612619 != nil:
    section.add "X-Amz-Date", valid_612619
  var valid_612620 = header.getOrDefault("X-Amz-Credential")
  valid_612620 = validateParameter(valid_612620, JString, required = false,
                                 default = nil)
  if valid_612620 != nil:
    section.add "X-Amz-Credential", valid_612620
  var valid_612621 = header.getOrDefault("X-Amz-Security-Token")
  valid_612621 = validateParameter(valid_612621, JString, required = false,
                                 default = nil)
  if valid_612621 != nil:
    section.add "X-Amz-Security-Token", valid_612621
  var valid_612622 = header.getOrDefault("X-Amz-Algorithm")
  valid_612622 = validateParameter(valid_612622, JString, required = false,
                                 default = nil)
  if valid_612622 != nil:
    section.add "X-Amz-Algorithm", valid_612622
  var valid_612623 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612623 = validateParameter(valid_612623, JString, required = false,
                                 default = nil)
  if valid_612623 != nil:
    section.add "X-Amz-SignedHeaders", valid_612623
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612624: Call_GetSwapEnvironmentCNAMEs_612608; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Swaps the CNAMEs of two environments.
  ## 
  let valid = call_612624.validator(path, query, header, formData, body)
  let scheme = call_612624.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612624.url(scheme.get, call_612624.host, call_612624.base,
                         call_612624.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612624, url, valid)

proc call*(call_612625: Call_GetSwapEnvironmentCNAMEs_612608;
          SourceEnvironmentId: string = ""; SourceEnvironmentName: string = "";
          DestinationEnvironmentName: string = "";
          Action: string = "SwapEnvironmentCNAMEs";
          DestinationEnvironmentId: string = ""; Version: string = "2010-12-01"): Recallable =
  ## getSwapEnvironmentCNAMEs
  ## Swaps the CNAMEs of two environments.
  ##   SourceEnvironmentId: string
  ##                      : <p>The ID of the source environment.</p> <p> Condition: You must specify at least the <code>SourceEnvironmentID</code> or the <code>SourceEnvironmentName</code>. You may also specify both. If you specify the <code>SourceEnvironmentId</code>, you must specify the <code>DestinationEnvironmentId</code>. </p>
  ##   SourceEnvironmentName: string
  ##                        : <p>The name of the source environment.</p> <p> Condition: You must specify at least the <code>SourceEnvironmentID</code> or the <code>SourceEnvironmentName</code>. You may also specify both. If you specify the <code>SourceEnvironmentName</code>, you must specify the <code>DestinationEnvironmentName</code>. </p>
  ##   DestinationEnvironmentName: string
  ##                             : <p>The name of the destination environment.</p> <p> Condition: You must specify at least the <code>DestinationEnvironmentID</code> or the <code>DestinationEnvironmentName</code>. You may also specify both. You must specify the <code>SourceEnvironmentName</code> with the <code>DestinationEnvironmentName</code>. </p>
  ##   Action: string (required)
  ##   DestinationEnvironmentId: string
  ##                           : <p>The ID of the destination environment.</p> <p> Condition: You must specify at least the <code>DestinationEnvironmentID</code> or the <code>DestinationEnvironmentName</code>. You may also specify both. You must specify the <code>SourceEnvironmentId</code> with the <code>DestinationEnvironmentId</code>. </p>
  ##   Version: string (required)
  var query_612626 = newJObject()
  add(query_612626, "SourceEnvironmentId", newJString(SourceEnvironmentId))
  add(query_612626, "SourceEnvironmentName", newJString(SourceEnvironmentName))
  add(query_612626, "DestinationEnvironmentName",
      newJString(DestinationEnvironmentName))
  add(query_612626, "Action", newJString(Action))
  add(query_612626, "DestinationEnvironmentId",
      newJString(DestinationEnvironmentId))
  add(query_612626, "Version", newJString(Version))
  result = call_612625.call(nil, query_612626, nil, nil, nil)

var getSwapEnvironmentCNAMEs* = Call_GetSwapEnvironmentCNAMEs_612608(
    name: "getSwapEnvironmentCNAMEs", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=SwapEnvironmentCNAMEs",
    validator: validate_GetSwapEnvironmentCNAMEs_612609, base: "/",
    url: url_GetSwapEnvironmentCNAMEs_612610, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostTerminateEnvironment_612666 = ref object of OpenApiRestCall_610659
proc url_PostTerminateEnvironment_612668(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostTerminateEnvironment_612667(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Terminates the specified environment.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612669 = query.getOrDefault("Action")
  valid_612669 = validateParameter(valid_612669, JString, required = true,
                                 default = newJString("TerminateEnvironment"))
  if valid_612669 != nil:
    section.add "Action", valid_612669
  var valid_612670 = query.getOrDefault("Version")
  valid_612670 = validateParameter(valid_612670, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612670 != nil:
    section.add "Version", valid_612670
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612671 = header.getOrDefault("X-Amz-Signature")
  valid_612671 = validateParameter(valid_612671, JString, required = false,
                                 default = nil)
  if valid_612671 != nil:
    section.add "X-Amz-Signature", valid_612671
  var valid_612672 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612672 = validateParameter(valid_612672, JString, required = false,
                                 default = nil)
  if valid_612672 != nil:
    section.add "X-Amz-Content-Sha256", valid_612672
  var valid_612673 = header.getOrDefault("X-Amz-Date")
  valid_612673 = validateParameter(valid_612673, JString, required = false,
                                 default = nil)
  if valid_612673 != nil:
    section.add "X-Amz-Date", valid_612673
  var valid_612674 = header.getOrDefault("X-Amz-Credential")
  valid_612674 = validateParameter(valid_612674, JString, required = false,
                                 default = nil)
  if valid_612674 != nil:
    section.add "X-Amz-Credential", valid_612674
  var valid_612675 = header.getOrDefault("X-Amz-Security-Token")
  valid_612675 = validateParameter(valid_612675, JString, required = false,
                                 default = nil)
  if valid_612675 != nil:
    section.add "X-Amz-Security-Token", valid_612675
  var valid_612676 = header.getOrDefault("X-Amz-Algorithm")
  valid_612676 = validateParameter(valid_612676, JString, required = false,
                                 default = nil)
  if valid_612676 != nil:
    section.add "X-Amz-Algorithm", valid_612676
  var valid_612677 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612677 = validateParameter(valid_612677, JString, required = false,
                                 default = nil)
  if valid_612677 != nil:
    section.add "X-Amz-SignedHeaders", valid_612677
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to terminate.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   TerminateResources: JBool
  ##                     : <p>Indicates whether the associated AWS resources should shut down when the environment is terminated:</p> <ul> <li> <p> <code>true</code>: The specified environment as well as the associated AWS resources, such as Auto Scaling group and LoadBalancer, are terminated.</p> </li> <li> <p> <code>false</code>: AWS Elastic Beanstalk resource management is removed from the environment, but the AWS resources continue to operate.</p> </li> </ul> <p> For more information, see the <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/ug/"> AWS Elastic Beanstalk User Guide. </a> </p> <p> Default: <code>true</code> </p> <p> Valid Values: <code>true</code> | <code>false</code> </p>
  ##   ForceTerminate: JBool
  ##                 : Terminates the target environment even if another environment in the same group is dependent on it.
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to terminate.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_612678 = formData.getOrDefault("EnvironmentName")
  valid_612678 = validateParameter(valid_612678, JString, required = false,
                                 default = nil)
  if valid_612678 != nil:
    section.add "EnvironmentName", valid_612678
  var valid_612679 = formData.getOrDefault("TerminateResources")
  valid_612679 = validateParameter(valid_612679, JBool, required = false, default = nil)
  if valid_612679 != nil:
    section.add "TerminateResources", valid_612679
  var valid_612680 = formData.getOrDefault("ForceTerminate")
  valid_612680 = validateParameter(valid_612680, JBool, required = false, default = nil)
  if valid_612680 != nil:
    section.add "ForceTerminate", valid_612680
  var valid_612681 = formData.getOrDefault("EnvironmentId")
  valid_612681 = validateParameter(valid_612681, JString, required = false,
                                 default = nil)
  if valid_612681 != nil:
    section.add "EnvironmentId", valid_612681
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612682: Call_PostTerminateEnvironment_612666; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Terminates the specified environment.
  ## 
  let valid = call_612682.validator(path, query, header, formData, body)
  let scheme = call_612682.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612682.url(scheme.get, call_612682.host, call_612682.base,
                         call_612682.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612682, url, valid)

proc call*(call_612683: Call_PostTerminateEnvironment_612666;
          EnvironmentName: string = ""; TerminateResources: bool = false;
          Action: string = "TerminateEnvironment"; ForceTerminate: bool = false;
          EnvironmentId: string = ""; Version: string = "2010-12-01"): Recallable =
  ## postTerminateEnvironment
  ## Terminates the specified environment.
  ##   EnvironmentName: string
  ##                  : <p>The name of the environment to terminate.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   TerminateResources: bool
  ##                     : <p>Indicates whether the associated AWS resources should shut down when the environment is terminated:</p> <ul> <li> <p> <code>true</code>: The specified environment as well as the associated AWS resources, such as Auto Scaling group and LoadBalancer, are terminated.</p> </li> <li> <p> <code>false</code>: AWS Elastic Beanstalk resource management is removed from the environment, but the AWS resources continue to operate.</p> </li> </ul> <p> For more information, see the <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/ug/"> AWS Elastic Beanstalk User Guide. </a> </p> <p> Default: <code>true</code> </p> <p> Valid Values: <code>true</code> | <code>false</code> </p>
  ##   Action: string (required)
  ##   ForceTerminate: bool
  ##                 : Terminates the target environment even if another environment in the same group is dependent on it.
  ##   EnvironmentId: string
  ##                : <p>The ID of the environment to terminate.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Version: string (required)
  var query_612684 = newJObject()
  var formData_612685 = newJObject()
  add(formData_612685, "EnvironmentName", newJString(EnvironmentName))
  add(formData_612685, "TerminateResources", newJBool(TerminateResources))
  add(query_612684, "Action", newJString(Action))
  add(formData_612685, "ForceTerminate", newJBool(ForceTerminate))
  add(formData_612685, "EnvironmentId", newJString(EnvironmentId))
  add(query_612684, "Version", newJString(Version))
  result = call_612683.call(nil, query_612684, nil, formData_612685, nil)

var postTerminateEnvironment* = Call_PostTerminateEnvironment_612666(
    name: "postTerminateEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=TerminateEnvironment",
    validator: validate_PostTerminateEnvironment_612667, base: "/",
    url: url_PostTerminateEnvironment_612668, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTerminateEnvironment_612647 = ref object of OpenApiRestCall_610659
proc url_GetTerminateEnvironment_612649(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTerminateEnvironment_612648(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Terminates the specified environment.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ForceTerminate: JBool
  ##                 : Terminates the target environment even if another environment in the same group is dependent on it.
  ##   TerminateResources: JBool
  ##                     : <p>Indicates whether the associated AWS resources should shut down when the environment is terminated:</p> <ul> <li> <p> <code>true</code>: The specified environment as well as the associated AWS resources, such as Auto Scaling group and LoadBalancer, are terminated.</p> </li> <li> <p> <code>false</code>: AWS Elastic Beanstalk resource management is removed from the environment, but the AWS resources continue to operate.</p> </li> </ul> <p> For more information, see the <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/ug/"> AWS Elastic Beanstalk User Guide. </a> </p> <p> Default: <code>true</code> </p> <p> Valid Values: <code>true</code> | <code>false</code> </p>
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to terminate.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to terminate.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_612650 = query.getOrDefault("ForceTerminate")
  valid_612650 = validateParameter(valid_612650, JBool, required = false, default = nil)
  if valid_612650 != nil:
    section.add "ForceTerminate", valid_612650
  var valid_612651 = query.getOrDefault("TerminateResources")
  valid_612651 = validateParameter(valid_612651, JBool, required = false, default = nil)
  if valid_612651 != nil:
    section.add "TerminateResources", valid_612651
  var valid_612652 = query.getOrDefault("EnvironmentName")
  valid_612652 = validateParameter(valid_612652, JString, required = false,
                                 default = nil)
  if valid_612652 != nil:
    section.add "EnvironmentName", valid_612652
  var valid_612653 = query.getOrDefault("Action")
  valid_612653 = validateParameter(valid_612653, JString, required = true,
                                 default = newJString("TerminateEnvironment"))
  if valid_612653 != nil:
    section.add "Action", valid_612653
  var valid_612654 = query.getOrDefault("Version")
  valid_612654 = validateParameter(valid_612654, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612654 != nil:
    section.add "Version", valid_612654
  var valid_612655 = query.getOrDefault("EnvironmentId")
  valid_612655 = validateParameter(valid_612655, JString, required = false,
                                 default = nil)
  if valid_612655 != nil:
    section.add "EnvironmentId", valid_612655
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612656 = header.getOrDefault("X-Amz-Signature")
  valid_612656 = validateParameter(valid_612656, JString, required = false,
                                 default = nil)
  if valid_612656 != nil:
    section.add "X-Amz-Signature", valid_612656
  var valid_612657 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612657 = validateParameter(valid_612657, JString, required = false,
                                 default = nil)
  if valid_612657 != nil:
    section.add "X-Amz-Content-Sha256", valid_612657
  var valid_612658 = header.getOrDefault("X-Amz-Date")
  valid_612658 = validateParameter(valid_612658, JString, required = false,
                                 default = nil)
  if valid_612658 != nil:
    section.add "X-Amz-Date", valid_612658
  var valid_612659 = header.getOrDefault("X-Amz-Credential")
  valid_612659 = validateParameter(valid_612659, JString, required = false,
                                 default = nil)
  if valid_612659 != nil:
    section.add "X-Amz-Credential", valid_612659
  var valid_612660 = header.getOrDefault("X-Amz-Security-Token")
  valid_612660 = validateParameter(valid_612660, JString, required = false,
                                 default = nil)
  if valid_612660 != nil:
    section.add "X-Amz-Security-Token", valid_612660
  var valid_612661 = header.getOrDefault("X-Amz-Algorithm")
  valid_612661 = validateParameter(valid_612661, JString, required = false,
                                 default = nil)
  if valid_612661 != nil:
    section.add "X-Amz-Algorithm", valid_612661
  var valid_612662 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612662 = validateParameter(valid_612662, JString, required = false,
                                 default = nil)
  if valid_612662 != nil:
    section.add "X-Amz-SignedHeaders", valid_612662
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612663: Call_GetTerminateEnvironment_612647; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Terminates the specified environment.
  ## 
  let valid = call_612663.validator(path, query, header, formData, body)
  let scheme = call_612663.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612663.url(scheme.get, call_612663.host, call_612663.base,
                         call_612663.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612663, url, valid)

proc call*(call_612664: Call_GetTerminateEnvironment_612647;
          ForceTerminate: bool = false; TerminateResources: bool = false;
          EnvironmentName: string = ""; Action: string = "TerminateEnvironment";
          Version: string = "2010-12-01"; EnvironmentId: string = ""): Recallable =
  ## getTerminateEnvironment
  ## Terminates the specified environment.
  ##   ForceTerminate: bool
  ##                 : Terminates the target environment even if another environment in the same group is dependent on it.
  ##   TerminateResources: bool
  ##                     : <p>Indicates whether the associated AWS resources should shut down when the environment is terminated:</p> <ul> <li> <p> <code>true</code>: The specified environment as well as the associated AWS resources, such as Auto Scaling group and LoadBalancer, are terminated.</p> </li> <li> <p> <code>false</code>: AWS Elastic Beanstalk resource management is removed from the environment, but the AWS resources continue to operate.</p> </li> </ul> <p> For more information, see the <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/ug/"> AWS Elastic Beanstalk User Guide. </a> </p> <p> Default: <code>true</code> </p> <p> Valid Values: <code>true</code> | <code>false</code> </p>
  ##   EnvironmentName: string
  ##                  : <p>The name of the environment to terminate.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   EnvironmentId: string
  ##                : <p>The ID of the environment to terminate.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  var query_612665 = newJObject()
  add(query_612665, "ForceTerminate", newJBool(ForceTerminate))
  add(query_612665, "TerminateResources", newJBool(TerminateResources))
  add(query_612665, "EnvironmentName", newJString(EnvironmentName))
  add(query_612665, "Action", newJString(Action))
  add(query_612665, "Version", newJString(Version))
  add(query_612665, "EnvironmentId", newJString(EnvironmentId))
  result = call_612664.call(nil, query_612665, nil, nil, nil)

var getTerminateEnvironment* = Call_GetTerminateEnvironment_612647(
    name: "getTerminateEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=TerminateEnvironment",
    validator: validate_GetTerminateEnvironment_612648, base: "/",
    url: url_GetTerminateEnvironment_612649, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateApplication_612703 = ref object of OpenApiRestCall_610659
proc url_PostUpdateApplication_612705(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateApplication_612704(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the specified application to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear these properties, specify an empty string.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612706 = query.getOrDefault("Action")
  valid_612706 = validateParameter(valid_612706, JString, required = true,
                                 default = newJString("UpdateApplication"))
  if valid_612706 != nil:
    section.add "Action", valid_612706
  var valid_612707 = query.getOrDefault("Version")
  valid_612707 = validateParameter(valid_612707, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612707 != nil:
    section.add "Version", valid_612707
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612708 = header.getOrDefault("X-Amz-Signature")
  valid_612708 = validateParameter(valid_612708, JString, required = false,
                                 default = nil)
  if valid_612708 != nil:
    section.add "X-Amz-Signature", valid_612708
  var valid_612709 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612709 = validateParameter(valid_612709, JString, required = false,
                                 default = nil)
  if valid_612709 != nil:
    section.add "X-Amz-Content-Sha256", valid_612709
  var valid_612710 = header.getOrDefault("X-Amz-Date")
  valid_612710 = validateParameter(valid_612710, JString, required = false,
                                 default = nil)
  if valid_612710 != nil:
    section.add "X-Amz-Date", valid_612710
  var valid_612711 = header.getOrDefault("X-Amz-Credential")
  valid_612711 = validateParameter(valid_612711, JString, required = false,
                                 default = nil)
  if valid_612711 != nil:
    section.add "X-Amz-Credential", valid_612711
  var valid_612712 = header.getOrDefault("X-Amz-Security-Token")
  valid_612712 = validateParameter(valid_612712, JString, required = false,
                                 default = nil)
  if valid_612712 != nil:
    section.add "X-Amz-Security-Token", valid_612712
  var valid_612713 = header.getOrDefault("X-Amz-Algorithm")
  valid_612713 = validateParameter(valid_612713, JString, required = false,
                                 default = nil)
  if valid_612713 != nil:
    section.add "X-Amz-Algorithm", valid_612713
  var valid_612714 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612714 = validateParameter(valid_612714, JString, required = false,
                                 default = nil)
  if valid_612714 != nil:
    section.add "X-Amz-SignedHeaders", valid_612714
  result.add "header", section
  ## parameters in `formData` object:
  ##   Description: JString
  ##              : <p>A new description for the application.</p> <p>Default: If not specified, AWS Elastic Beanstalk does not update the description.</p>
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to update. If no such application is found, <code>UpdateApplication</code> returns an <code>InvalidParameterValue</code> error. 
  section = newJObject()
  var valid_612715 = formData.getOrDefault("Description")
  valid_612715 = validateParameter(valid_612715, JString, required = false,
                                 default = nil)
  if valid_612715 != nil:
    section.add "Description", valid_612715
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_612716 = formData.getOrDefault("ApplicationName")
  valid_612716 = validateParameter(valid_612716, JString, required = true,
                                 default = nil)
  if valid_612716 != nil:
    section.add "ApplicationName", valid_612716
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612717: Call_PostUpdateApplication_612703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified application to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear these properties, specify an empty string.</p> </note>
  ## 
  let valid = call_612717.validator(path, query, header, formData, body)
  let scheme = call_612717.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612717.url(scheme.get, call_612717.host, call_612717.base,
                         call_612717.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612717, url, valid)

proc call*(call_612718: Call_PostUpdateApplication_612703; ApplicationName: string;
          Description: string = ""; Action: string = "UpdateApplication";
          Version: string = "2010-12-01"): Recallable =
  ## postUpdateApplication
  ## <p>Updates the specified application to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear these properties, specify an empty string.</p> </note>
  ##   Description: string
  ##              : <p>A new description for the application.</p> <p>Default: If not specified, AWS Elastic Beanstalk does not update the description.</p>
  ##   ApplicationName: string (required)
  ##                  : The name of the application to update. If no such application is found, <code>UpdateApplication</code> returns an <code>InvalidParameterValue</code> error. 
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612719 = newJObject()
  var formData_612720 = newJObject()
  add(formData_612720, "Description", newJString(Description))
  add(formData_612720, "ApplicationName", newJString(ApplicationName))
  add(query_612719, "Action", newJString(Action))
  add(query_612719, "Version", newJString(Version))
  result = call_612718.call(nil, query_612719, nil, formData_612720, nil)

var postUpdateApplication* = Call_PostUpdateApplication_612703(
    name: "postUpdateApplication", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateApplication",
    validator: validate_PostUpdateApplication_612704, base: "/",
    url: url_PostUpdateApplication_612705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateApplication_612686 = ref object of OpenApiRestCall_610659
proc url_GetUpdateApplication_612688(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateApplication_612687(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the specified application to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear these properties, specify an empty string.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to update. If no such application is found, <code>UpdateApplication</code> returns an <code>InvalidParameterValue</code> error. 
  ##   Action: JString (required)
  ##   Description: JString
  ##              : <p>A new description for the application.</p> <p>Default: If not specified, AWS Elastic Beanstalk does not update the description.</p>
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_612689 = query.getOrDefault("ApplicationName")
  valid_612689 = validateParameter(valid_612689, JString, required = true,
                                 default = nil)
  if valid_612689 != nil:
    section.add "ApplicationName", valid_612689
  var valid_612690 = query.getOrDefault("Action")
  valid_612690 = validateParameter(valid_612690, JString, required = true,
                                 default = newJString("UpdateApplication"))
  if valid_612690 != nil:
    section.add "Action", valid_612690
  var valid_612691 = query.getOrDefault("Description")
  valid_612691 = validateParameter(valid_612691, JString, required = false,
                                 default = nil)
  if valid_612691 != nil:
    section.add "Description", valid_612691
  var valid_612692 = query.getOrDefault("Version")
  valid_612692 = validateParameter(valid_612692, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612692 != nil:
    section.add "Version", valid_612692
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612693 = header.getOrDefault("X-Amz-Signature")
  valid_612693 = validateParameter(valid_612693, JString, required = false,
                                 default = nil)
  if valid_612693 != nil:
    section.add "X-Amz-Signature", valid_612693
  var valid_612694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612694 = validateParameter(valid_612694, JString, required = false,
                                 default = nil)
  if valid_612694 != nil:
    section.add "X-Amz-Content-Sha256", valid_612694
  var valid_612695 = header.getOrDefault("X-Amz-Date")
  valid_612695 = validateParameter(valid_612695, JString, required = false,
                                 default = nil)
  if valid_612695 != nil:
    section.add "X-Amz-Date", valid_612695
  var valid_612696 = header.getOrDefault("X-Amz-Credential")
  valid_612696 = validateParameter(valid_612696, JString, required = false,
                                 default = nil)
  if valid_612696 != nil:
    section.add "X-Amz-Credential", valid_612696
  var valid_612697 = header.getOrDefault("X-Amz-Security-Token")
  valid_612697 = validateParameter(valid_612697, JString, required = false,
                                 default = nil)
  if valid_612697 != nil:
    section.add "X-Amz-Security-Token", valid_612697
  var valid_612698 = header.getOrDefault("X-Amz-Algorithm")
  valid_612698 = validateParameter(valid_612698, JString, required = false,
                                 default = nil)
  if valid_612698 != nil:
    section.add "X-Amz-Algorithm", valid_612698
  var valid_612699 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612699 = validateParameter(valid_612699, JString, required = false,
                                 default = nil)
  if valid_612699 != nil:
    section.add "X-Amz-SignedHeaders", valid_612699
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612700: Call_GetUpdateApplication_612686; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified application to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear these properties, specify an empty string.</p> </note>
  ## 
  let valid = call_612700.validator(path, query, header, formData, body)
  let scheme = call_612700.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612700.url(scheme.get, call_612700.host, call_612700.base,
                         call_612700.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612700, url, valid)

proc call*(call_612701: Call_GetUpdateApplication_612686; ApplicationName: string;
          Action: string = "UpdateApplication"; Description: string = "";
          Version: string = "2010-12-01"): Recallable =
  ## getUpdateApplication
  ## <p>Updates the specified application to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear these properties, specify an empty string.</p> </note>
  ##   ApplicationName: string (required)
  ##                  : The name of the application to update. If no such application is found, <code>UpdateApplication</code> returns an <code>InvalidParameterValue</code> error. 
  ##   Action: string (required)
  ##   Description: string
  ##              : <p>A new description for the application.</p> <p>Default: If not specified, AWS Elastic Beanstalk does not update the description.</p>
  ##   Version: string (required)
  var query_612702 = newJObject()
  add(query_612702, "ApplicationName", newJString(ApplicationName))
  add(query_612702, "Action", newJString(Action))
  add(query_612702, "Description", newJString(Description))
  add(query_612702, "Version", newJString(Version))
  result = call_612701.call(nil, query_612702, nil, nil, nil)

var getUpdateApplication* = Call_GetUpdateApplication_612686(
    name: "getUpdateApplication", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateApplication",
    validator: validate_GetUpdateApplication_612687, base: "/",
    url: url_GetUpdateApplication_612688, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateApplicationResourceLifecycle_612739 = ref object of OpenApiRestCall_610659
proc url_PostUpdateApplicationResourceLifecycle_612741(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateApplicationResourceLifecycle_612740(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Modifies lifecycle settings for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612742 = query.getOrDefault("Action")
  valid_612742 = validateParameter(valid_612742, JString, required = true, default = newJString(
      "UpdateApplicationResourceLifecycle"))
  if valid_612742 != nil:
    section.add "Action", valid_612742
  var valid_612743 = query.getOrDefault("Version")
  valid_612743 = validateParameter(valid_612743, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612743 != nil:
    section.add "Version", valid_612743
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612744 = header.getOrDefault("X-Amz-Signature")
  valid_612744 = validateParameter(valid_612744, JString, required = false,
                                 default = nil)
  if valid_612744 != nil:
    section.add "X-Amz-Signature", valid_612744
  var valid_612745 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612745 = validateParameter(valid_612745, JString, required = false,
                                 default = nil)
  if valid_612745 != nil:
    section.add "X-Amz-Content-Sha256", valid_612745
  var valid_612746 = header.getOrDefault("X-Amz-Date")
  valid_612746 = validateParameter(valid_612746, JString, required = false,
                                 default = nil)
  if valid_612746 != nil:
    section.add "X-Amz-Date", valid_612746
  var valid_612747 = header.getOrDefault("X-Amz-Credential")
  valid_612747 = validateParameter(valid_612747, JString, required = false,
                                 default = nil)
  if valid_612747 != nil:
    section.add "X-Amz-Credential", valid_612747
  var valid_612748 = header.getOrDefault("X-Amz-Security-Token")
  valid_612748 = validateParameter(valid_612748, JString, required = false,
                                 default = nil)
  if valid_612748 != nil:
    section.add "X-Amz-Security-Token", valid_612748
  var valid_612749 = header.getOrDefault("X-Amz-Algorithm")
  valid_612749 = validateParameter(valid_612749, JString, required = false,
                                 default = nil)
  if valid_612749 != nil:
    section.add "X-Amz-Algorithm", valid_612749
  var valid_612750 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612750 = validateParameter(valid_612750, JString, required = false,
                                 default = nil)
  if valid_612750 != nil:
    section.add "X-Amz-SignedHeaders", valid_612750
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceLifecycleConfig.VersionLifecycleConfig: JString
  ##                                                 : The resource lifecycle configuration for an application. Defines lifecycle settings for resources that belong to the application, and the service role that Elastic Beanstalk assumes in order to apply lifecycle settings. The version lifecycle configuration defines lifecycle settings for application versions.
  ## The application version lifecycle configuration.
  ##   ResourceLifecycleConfig.ServiceRole: JString
  ##                                      : The resource lifecycle configuration for an application. Defines lifecycle settings for resources that belong to the application, and the service role that Elastic Beanstalk assumes in order to apply lifecycle settings. The version lifecycle configuration defines lifecycle settings for application versions.
  ## <p>The ARN of an IAM service role that Elastic Beanstalk has permission to assume.</p> <p>The <code>ServiceRole</code> property is required the first time that you provide a <code>VersionLifecycleConfig</code> for the application in one of the supporting calls (<code>CreateApplication</code> or <code>UpdateApplicationResourceLifecycle</code>). After you provide it once, in either one of the calls, Elastic Beanstalk persists the Service Role with the application, and you don't need to specify it again in subsequent <code>UpdateApplicationResourceLifecycle</code> calls. You can, however, specify it in subsequent calls to change the Service Role to another value.</p>
  ##   ApplicationName: JString (required)
  ##                  : The name of the application.
  section = newJObject()
  var valid_612751 = formData.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_612751 = validateParameter(valid_612751, JString, required = false,
                                 default = nil)
  if valid_612751 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_612751
  var valid_612752 = formData.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_612752 = validateParameter(valid_612752, JString, required = false,
                                 default = nil)
  if valid_612752 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_612752
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_612753 = formData.getOrDefault("ApplicationName")
  valid_612753 = validateParameter(valid_612753, JString, required = true,
                                 default = nil)
  if valid_612753 != nil:
    section.add "ApplicationName", valid_612753
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612754: Call_PostUpdateApplicationResourceLifecycle_612739;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Modifies lifecycle settings for an application.
  ## 
  let valid = call_612754.validator(path, query, header, formData, body)
  let scheme = call_612754.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612754.url(scheme.get, call_612754.host, call_612754.base,
                         call_612754.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612754, url, valid)

proc call*(call_612755: Call_PostUpdateApplicationResourceLifecycle_612739;
          ApplicationName: string;
          ResourceLifecycleConfigVersionLifecycleConfig: string = "";
          ResourceLifecycleConfigServiceRole: string = "";
          Action: string = "UpdateApplicationResourceLifecycle";
          Version: string = "2010-12-01"): Recallable =
  ## postUpdateApplicationResourceLifecycle
  ## Modifies lifecycle settings for an application.
  ##   ResourceLifecycleConfigVersionLifecycleConfig: string
  ##                                                : The resource lifecycle configuration for an application. Defines lifecycle settings for resources that belong to the application, and the service role that Elastic Beanstalk assumes in order to apply lifecycle settings. The version lifecycle configuration defines lifecycle settings for application versions.
  ## The application version lifecycle configuration.
  ##   ResourceLifecycleConfigServiceRole: string
  ##                                     : The resource lifecycle configuration for an application. Defines lifecycle settings for resources that belong to the application, and the service role that Elastic Beanstalk assumes in order to apply lifecycle settings. The version lifecycle configuration defines lifecycle settings for application versions.
  ## <p>The ARN of an IAM service role that Elastic Beanstalk has permission to assume.</p> <p>The <code>ServiceRole</code> property is required the first time that you provide a <code>VersionLifecycleConfig</code> for the application in one of the supporting calls (<code>CreateApplication</code> or <code>UpdateApplicationResourceLifecycle</code>). After you provide it once, in either one of the calls, Elastic Beanstalk persists the Service Role with the application, and you don't need to specify it again in subsequent <code>UpdateApplicationResourceLifecycle</code> calls. You can, however, specify it in subsequent calls to change the Service Role to another value.</p>
  ##   ApplicationName: string (required)
  ##                  : The name of the application.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612756 = newJObject()
  var formData_612757 = newJObject()
  add(formData_612757, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  add(formData_612757, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  add(formData_612757, "ApplicationName", newJString(ApplicationName))
  add(query_612756, "Action", newJString(Action))
  add(query_612756, "Version", newJString(Version))
  result = call_612755.call(nil, query_612756, nil, formData_612757, nil)

var postUpdateApplicationResourceLifecycle* = Call_PostUpdateApplicationResourceLifecycle_612739(
    name: "postUpdateApplicationResourceLifecycle", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationResourceLifecycle",
    validator: validate_PostUpdateApplicationResourceLifecycle_612740, base: "/",
    url: url_PostUpdateApplicationResourceLifecycle_612741,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateApplicationResourceLifecycle_612721 = ref object of OpenApiRestCall_610659
proc url_GetUpdateApplicationResourceLifecycle_612723(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateApplicationResourceLifecycle_612722(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Modifies lifecycle settings for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ApplicationName: JString (required)
  ##                  : The name of the application.
  ##   ResourceLifecycleConfig.ServiceRole: JString
  ##                                      : The resource lifecycle configuration for an application. Defines lifecycle settings for resources that belong to the application, and the service role that Elastic Beanstalk assumes in order to apply lifecycle settings. The version lifecycle configuration defines lifecycle settings for application versions.
  ## <p>The ARN of an IAM service role that Elastic Beanstalk has permission to assume.</p> <p>The <code>ServiceRole</code> property is required the first time that you provide a <code>VersionLifecycleConfig</code> for the application in one of the supporting calls (<code>CreateApplication</code> or <code>UpdateApplicationResourceLifecycle</code>). After you provide it once, in either one of the calls, Elastic Beanstalk persists the Service Role with the application, and you don't need to specify it again in subsequent <code>UpdateApplicationResourceLifecycle</code> calls. You can, however, specify it in subsequent calls to change the Service Role to another value.</p>
  ##   ResourceLifecycleConfig.VersionLifecycleConfig: JString
  ##                                                 : The resource lifecycle configuration for an application. Defines lifecycle settings for resources that belong to the application, and the service role that Elastic Beanstalk assumes in order to apply lifecycle settings. The version lifecycle configuration defines lifecycle settings for application versions.
  ## The application version lifecycle configuration.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_612724 = query.getOrDefault("ApplicationName")
  valid_612724 = validateParameter(valid_612724, JString, required = true,
                                 default = nil)
  if valid_612724 != nil:
    section.add "ApplicationName", valid_612724
  var valid_612725 = query.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_612725 = validateParameter(valid_612725, JString, required = false,
                                 default = nil)
  if valid_612725 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_612725
  var valid_612726 = query.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_612726 = validateParameter(valid_612726, JString, required = false,
                                 default = nil)
  if valid_612726 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_612726
  var valid_612727 = query.getOrDefault("Action")
  valid_612727 = validateParameter(valid_612727, JString, required = true, default = newJString(
      "UpdateApplicationResourceLifecycle"))
  if valid_612727 != nil:
    section.add "Action", valid_612727
  var valid_612728 = query.getOrDefault("Version")
  valid_612728 = validateParameter(valid_612728, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612728 != nil:
    section.add "Version", valid_612728
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612729 = header.getOrDefault("X-Amz-Signature")
  valid_612729 = validateParameter(valid_612729, JString, required = false,
                                 default = nil)
  if valid_612729 != nil:
    section.add "X-Amz-Signature", valid_612729
  var valid_612730 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612730 = validateParameter(valid_612730, JString, required = false,
                                 default = nil)
  if valid_612730 != nil:
    section.add "X-Amz-Content-Sha256", valid_612730
  var valid_612731 = header.getOrDefault("X-Amz-Date")
  valid_612731 = validateParameter(valid_612731, JString, required = false,
                                 default = nil)
  if valid_612731 != nil:
    section.add "X-Amz-Date", valid_612731
  var valid_612732 = header.getOrDefault("X-Amz-Credential")
  valid_612732 = validateParameter(valid_612732, JString, required = false,
                                 default = nil)
  if valid_612732 != nil:
    section.add "X-Amz-Credential", valid_612732
  var valid_612733 = header.getOrDefault("X-Amz-Security-Token")
  valid_612733 = validateParameter(valid_612733, JString, required = false,
                                 default = nil)
  if valid_612733 != nil:
    section.add "X-Amz-Security-Token", valid_612733
  var valid_612734 = header.getOrDefault("X-Amz-Algorithm")
  valid_612734 = validateParameter(valid_612734, JString, required = false,
                                 default = nil)
  if valid_612734 != nil:
    section.add "X-Amz-Algorithm", valid_612734
  var valid_612735 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612735 = validateParameter(valid_612735, JString, required = false,
                                 default = nil)
  if valid_612735 != nil:
    section.add "X-Amz-SignedHeaders", valid_612735
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612736: Call_GetUpdateApplicationResourceLifecycle_612721;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Modifies lifecycle settings for an application.
  ## 
  let valid = call_612736.validator(path, query, header, formData, body)
  let scheme = call_612736.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612736.url(scheme.get, call_612736.host, call_612736.base,
                         call_612736.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612736, url, valid)

proc call*(call_612737: Call_GetUpdateApplicationResourceLifecycle_612721;
          ApplicationName: string;
          ResourceLifecycleConfigServiceRole: string = "";
          ResourceLifecycleConfigVersionLifecycleConfig: string = "";
          Action: string = "UpdateApplicationResourceLifecycle";
          Version: string = "2010-12-01"): Recallable =
  ## getUpdateApplicationResourceLifecycle
  ## Modifies lifecycle settings for an application.
  ##   ApplicationName: string (required)
  ##                  : The name of the application.
  ##   ResourceLifecycleConfigServiceRole: string
  ##                                     : The resource lifecycle configuration for an application. Defines lifecycle settings for resources that belong to the application, and the service role that Elastic Beanstalk assumes in order to apply lifecycle settings. The version lifecycle configuration defines lifecycle settings for application versions.
  ## <p>The ARN of an IAM service role that Elastic Beanstalk has permission to assume.</p> <p>The <code>ServiceRole</code> property is required the first time that you provide a <code>VersionLifecycleConfig</code> for the application in one of the supporting calls (<code>CreateApplication</code> or <code>UpdateApplicationResourceLifecycle</code>). After you provide it once, in either one of the calls, Elastic Beanstalk persists the Service Role with the application, and you don't need to specify it again in subsequent <code>UpdateApplicationResourceLifecycle</code> calls. You can, however, specify it in subsequent calls to change the Service Role to another value.</p>
  ##   ResourceLifecycleConfigVersionLifecycleConfig: string
  ##                                                : The resource lifecycle configuration for an application. Defines lifecycle settings for resources that belong to the application, and the service role that Elastic Beanstalk assumes in order to apply lifecycle settings. The version lifecycle configuration defines lifecycle settings for application versions.
  ## The application version lifecycle configuration.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612738 = newJObject()
  add(query_612738, "ApplicationName", newJString(ApplicationName))
  add(query_612738, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  add(query_612738, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  add(query_612738, "Action", newJString(Action))
  add(query_612738, "Version", newJString(Version))
  result = call_612737.call(nil, query_612738, nil, nil, nil)

var getUpdateApplicationResourceLifecycle* = Call_GetUpdateApplicationResourceLifecycle_612721(
    name: "getUpdateApplicationResourceLifecycle", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationResourceLifecycle",
    validator: validate_GetUpdateApplicationResourceLifecycle_612722, base: "/",
    url: url_GetUpdateApplicationResourceLifecycle_612723,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateApplicationVersion_612776 = ref object of OpenApiRestCall_610659
proc url_PostUpdateApplicationVersion_612778(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateApplicationVersion_612777(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the specified application version to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear properties, specify an empty string.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612779 = query.getOrDefault("Action")
  valid_612779 = validateParameter(valid_612779, JString, required = true, default = newJString(
      "UpdateApplicationVersion"))
  if valid_612779 != nil:
    section.add "Action", valid_612779
  var valid_612780 = query.getOrDefault("Version")
  valid_612780 = validateParameter(valid_612780, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612780 != nil:
    section.add "Version", valid_612780
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612781 = header.getOrDefault("X-Amz-Signature")
  valid_612781 = validateParameter(valid_612781, JString, required = false,
                                 default = nil)
  if valid_612781 != nil:
    section.add "X-Amz-Signature", valid_612781
  var valid_612782 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612782 = validateParameter(valid_612782, JString, required = false,
                                 default = nil)
  if valid_612782 != nil:
    section.add "X-Amz-Content-Sha256", valid_612782
  var valid_612783 = header.getOrDefault("X-Amz-Date")
  valid_612783 = validateParameter(valid_612783, JString, required = false,
                                 default = nil)
  if valid_612783 != nil:
    section.add "X-Amz-Date", valid_612783
  var valid_612784 = header.getOrDefault("X-Amz-Credential")
  valid_612784 = validateParameter(valid_612784, JString, required = false,
                                 default = nil)
  if valid_612784 != nil:
    section.add "X-Amz-Credential", valid_612784
  var valid_612785 = header.getOrDefault("X-Amz-Security-Token")
  valid_612785 = validateParameter(valid_612785, JString, required = false,
                                 default = nil)
  if valid_612785 != nil:
    section.add "X-Amz-Security-Token", valid_612785
  var valid_612786 = header.getOrDefault("X-Amz-Algorithm")
  valid_612786 = validateParameter(valid_612786, JString, required = false,
                                 default = nil)
  if valid_612786 != nil:
    section.add "X-Amz-Algorithm", valid_612786
  var valid_612787 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612787 = validateParameter(valid_612787, JString, required = false,
                                 default = nil)
  if valid_612787 != nil:
    section.add "X-Amz-SignedHeaders", valid_612787
  result.add "header", section
  ## parameters in `formData` object:
  ##   Description: JString
  ##              : A new description for this version.
  ##   VersionLabel: JString (required)
  ##               : <p>The name of the version to update.</p> <p>If no application version is found with this label, <code>UpdateApplication</code> returns an <code>InvalidParameterValue</code> error. </p>
  ##   ApplicationName: JString (required)
  ##                  : <p>The name of the application associated with this version.</p> <p> If no application is found with this name, <code>UpdateApplication</code> returns an <code>InvalidParameterValue</code> error.</p>
  section = newJObject()
  var valid_612788 = formData.getOrDefault("Description")
  valid_612788 = validateParameter(valid_612788, JString, required = false,
                                 default = nil)
  if valid_612788 != nil:
    section.add "Description", valid_612788
  assert formData != nil,
        "formData argument is necessary due to required `VersionLabel` field"
  var valid_612789 = formData.getOrDefault("VersionLabel")
  valid_612789 = validateParameter(valid_612789, JString, required = true,
                                 default = nil)
  if valid_612789 != nil:
    section.add "VersionLabel", valid_612789
  var valid_612790 = formData.getOrDefault("ApplicationName")
  valid_612790 = validateParameter(valid_612790, JString, required = true,
                                 default = nil)
  if valid_612790 != nil:
    section.add "ApplicationName", valid_612790
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612791: Call_PostUpdateApplicationVersion_612776; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified application version to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear properties, specify an empty string.</p> </note>
  ## 
  let valid = call_612791.validator(path, query, header, formData, body)
  let scheme = call_612791.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612791.url(scheme.get, call_612791.host, call_612791.base,
                         call_612791.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612791, url, valid)

proc call*(call_612792: Call_PostUpdateApplicationVersion_612776;
          VersionLabel: string; ApplicationName: string; Description: string = "";
          Action: string = "UpdateApplicationVersion";
          Version: string = "2010-12-01"): Recallable =
  ## postUpdateApplicationVersion
  ## <p>Updates the specified application version to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear properties, specify an empty string.</p> </note>
  ##   Description: string
  ##              : A new description for this version.
  ##   VersionLabel: string (required)
  ##               : <p>The name of the version to update.</p> <p>If no application version is found with this label, <code>UpdateApplication</code> returns an <code>InvalidParameterValue</code> error. </p>
  ##   ApplicationName: string (required)
  ##                  : <p>The name of the application associated with this version.</p> <p> If no application is found with this name, <code>UpdateApplication</code> returns an <code>InvalidParameterValue</code> error.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612793 = newJObject()
  var formData_612794 = newJObject()
  add(formData_612794, "Description", newJString(Description))
  add(formData_612794, "VersionLabel", newJString(VersionLabel))
  add(formData_612794, "ApplicationName", newJString(ApplicationName))
  add(query_612793, "Action", newJString(Action))
  add(query_612793, "Version", newJString(Version))
  result = call_612792.call(nil, query_612793, nil, formData_612794, nil)

var postUpdateApplicationVersion* = Call_PostUpdateApplicationVersion_612776(
    name: "postUpdateApplicationVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationVersion",
    validator: validate_PostUpdateApplicationVersion_612777, base: "/",
    url: url_PostUpdateApplicationVersion_612778,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateApplicationVersion_612758 = ref object of OpenApiRestCall_610659
proc url_GetUpdateApplicationVersion_612760(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateApplicationVersion_612759(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the specified application version to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear properties, specify an empty string.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ApplicationName: JString (required)
  ##                  : <p>The name of the application associated with this version.</p> <p> If no application is found with this name, <code>UpdateApplication</code> returns an <code>InvalidParameterValue</code> error.</p>
  ##   VersionLabel: JString (required)
  ##               : <p>The name of the version to update.</p> <p>If no application version is found with this label, <code>UpdateApplication</code> returns an <code>InvalidParameterValue</code> error. </p>
  ##   Action: JString (required)
  ##   Description: JString
  ##              : A new description for this version.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_612761 = query.getOrDefault("ApplicationName")
  valid_612761 = validateParameter(valid_612761, JString, required = true,
                                 default = nil)
  if valid_612761 != nil:
    section.add "ApplicationName", valid_612761
  var valid_612762 = query.getOrDefault("VersionLabel")
  valid_612762 = validateParameter(valid_612762, JString, required = true,
                                 default = nil)
  if valid_612762 != nil:
    section.add "VersionLabel", valid_612762
  var valid_612763 = query.getOrDefault("Action")
  valid_612763 = validateParameter(valid_612763, JString, required = true, default = newJString(
      "UpdateApplicationVersion"))
  if valid_612763 != nil:
    section.add "Action", valid_612763
  var valid_612764 = query.getOrDefault("Description")
  valid_612764 = validateParameter(valid_612764, JString, required = false,
                                 default = nil)
  if valid_612764 != nil:
    section.add "Description", valid_612764
  var valid_612765 = query.getOrDefault("Version")
  valid_612765 = validateParameter(valid_612765, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612765 != nil:
    section.add "Version", valid_612765
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612766 = header.getOrDefault("X-Amz-Signature")
  valid_612766 = validateParameter(valid_612766, JString, required = false,
                                 default = nil)
  if valid_612766 != nil:
    section.add "X-Amz-Signature", valid_612766
  var valid_612767 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612767 = validateParameter(valid_612767, JString, required = false,
                                 default = nil)
  if valid_612767 != nil:
    section.add "X-Amz-Content-Sha256", valid_612767
  var valid_612768 = header.getOrDefault("X-Amz-Date")
  valid_612768 = validateParameter(valid_612768, JString, required = false,
                                 default = nil)
  if valid_612768 != nil:
    section.add "X-Amz-Date", valid_612768
  var valid_612769 = header.getOrDefault("X-Amz-Credential")
  valid_612769 = validateParameter(valid_612769, JString, required = false,
                                 default = nil)
  if valid_612769 != nil:
    section.add "X-Amz-Credential", valid_612769
  var valid_612770 = header.getOrDefault("X-Amz-Security-Token")
  valid_612770 = validateParameter(valid_612770, JString, required = false,
                                 default = nil)
  if valid_612770 != nil:
    section.add "X-Amz-Security-Token", valid_612770
  var valid_612771 = header.getOrDefault("X-Amz-Algorithm")
  valid_612771 = validateParameter(valid_612771, JString, required = false,
                                 default = nil)
  if valid_612771 != nil:
    section.add "X-Amz-Algorithm", valid_612771
  var valid_612772 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612772 = validateParameter(valid_612772, JString, required = false,
                                 default = nil)
  if valid_612772 != nil:
    section.add "X-Amz-SignedHeaders", valid_612772
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612773: Call_GetUpdateApplicationVersion_612758; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified application version to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear properties, specify an empty string.</p> </note>
  ## 
  let valid = call_612773.validator(path, query, header, formData, body)
  let scheme = call_612773.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612773.url(scheme.get, call_612773.host, call_612773.base,
                         call_612773.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612773, url, valid)

proc call*(call_612774: Call_GetUpdateApplicationVersion_612758;
          ApplicationName: string; VersionLabel: string;
          Action: string = "UpdateApplicationVersion"; Description: string = "";
          Version: string = "2010-12-01"): Recallable =
  ## getUpdateApplicationVersion
  ## <p>Updates the specified application version to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear properties, specify an empty string.</p> </note>
  ##   ApplicationName: string (required)
  ##                  : <p>The name of the application associated with this version.</p> <p> If no application is found with this name, <code>UpdateApplication</code> returns an <code>InvalidParameterValue</code> error.</p>
  ##   VersionLabel: string (required)
  ##               : <p>The name of the version to update.</p> <p>If no application version is found with this label, <code>UpdateApplication</code> returns an <code>InvalidParameterValue</code> error. </p>
  ##   Action: string (required)
  ##   Description: string
  ##              : A new description for this version.
  ##   Version: string (required)
  var query_612775 = newJObject()
  add(query_612775, "ApplicationName", newJString(ApplicationName))
  add(query_612775, "VersionLabel", newJString(VersionLabel))
  add(query_612775, "Action", newJString(Action))
  add(query_612775, "Description", newJString(Description))
  add(query_612775, "Version", newJString(Version))
  result = call_612774.call(nil, query_612775, nil, nil, nil)

var getUpdateApplicationVersion* = Call_GetUpdateApplicationVersion_612758(
    name: "getUpdateApplicationVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationVersion",
    validator: validate_GetUpdateApplicationVersion_612759, base: "/",
    url: url_GetUpdateApplicationVersion_612760,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateConfigurationTemplate_612815 = ref object of OpenApiRestCall_610659
proc url_PostUpdateConfigurationTemplate_612817(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateConfigurationTemplate_612816(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the specified configuration template to have the specified properties or configuration option values.</p> <note> <p>If a property (for example, <code>ApplicationName</code>) is not provided, its value remains unchanged. To clear such properties, specify an empty string.</p> </note> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612818 = query.getOrDefault("Action")
  valid_612818 = validateParameter(valid_612818, JString, required = true, default = newJString(
      "UpdateConfigurationTemplate"))
  if valid_612818 != nil:
    section.add "Action", valid_612818
  var valid_612819 = query.getOrDefault("Version")
  valid_612819 = validateParameter(valid_612819, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612819 != nil:
    section.add "Version", valid_612819
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612820 = header.getOrDefault("X-Amz-Signature")
  valid_612820 = validateParameter(valid_612820, JString, required = false,
                                 default = nil)
  if valid_612820 != nil:
    section.add "X-Amz-Signature", valid_612820
  var valid_612821 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612821 = validateParameter(valid_612821, JString, required = false,
                                 default = nil)
  if valid_612821 != nil:
    section.add "X-Amz-Content-Sha256", valid_612821
  var valid_612822 = header.getOrDefault("X-Amz-Date")
  valid_612822 = validateParameter(valid_612822, JString, required = false,
                                 default = nil)
  if valid_612822 != nil:
    section.add "X-Amz-Date", valid_612822
  var valid_612823 = header.getOrDefault("X-Amz-Credential")
  valid_612823 = validateParameter(valid_612823, JString, required = false,
                                 default = nil)
  if valid_612823 != nil:
    section.add "X-Amz-Credential", valid_612823
  var valid_612824 = header.getOrDefault("X-Amz-Security-Token")
  valid_612824 = validateParameter(valid_612824, JString, required = false,
                                 default = nil)
  if valid_612824 != nil:
    section.add "X-Amz-Security-Token", valid_612824
  var valid_612825 = header.getOrDefault("X-Amz-Algorithm")
  valid_612825 = validateParameter(valid_612825, JString, required = false,
                                 default = nil)
  if valid_612825 != nil:
    section.add "X-Amz-Algorithm", valid_612825
  var valid_612826 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612826 = validateParameter(valid_612826, JString, required = false,
                                 default = nil)
  if valid_612826 != nil:
    section.add "X-Amz-SignedHeaders", valid_612826
  result.add "header", section
  ## parameters in `formData` object:
  ##   Description: JString
  ##              : A new description for the configuration.
  ##   TemplateName: JString (required)
  ##               : <p>The name of the configuration template to update.</p> <p> If no configuration template is found with this name, <code>UpdateConfigurationTemplate</code> returns an <code>InvalidParameterValue</code> error. </p>
  ##   OptionsToRemove: JArray
  ##                  : <p>A list of configuration options to remove from the configuration set.</p> <p> Constraint: You can remove only <code>UserDefined</code> configuration options. </p>
  ##   OptionSettings: JArray
  ##                 : A list of configuration option settings to update with the new specified option value.
  ##   ApplicationName: JString (required)
  ##                  : <p>The name of the application associated with the configuration template to update.</p> <p> If no application is found with this name, <code>UpdateConfigurationTemplate</code> returns an <code>InvalidParameterValue</code> error. </p>
  section = newJObject()
  var valid_612827 = formData.getOrDefault("Description")
  valid_612827 = validateParameter(valid_612827, JString, required = false,
                                 default = nil)
  if valid_612827 != nil:
    section.add "Description", valid_612827
  assert formData != nil,
        "formData argument is necessary due to required `TemplateName` field"
  var valid_612828 = formData.getOrDefault("TemplateName")
  valid_612828 = validateParameter(valid_612828, JString, required = true,
                                 default = nil)
  if valid_612828 != nil:
    section.add "TemplateName", valid_612828
  var valid_612829 = formData.getOrDefault("OptionsToRemove")
  valid_612829 = validateParameter(valid_612829, JArray, required = false,
                                 default = nil)
  if valid_612829 != nil:
    section.add "OptionsToRemove", valid_612829
  var valid_612830 = formData.getOrDefault("OptionSettings")
  valid_612830 = validateParameter(valid_612830, JArray, required = false,
                                 default = nil)
  if valid_612830 != nil:
    section.add "OptionSettings", valid_612830
  var valid_612831 = formData.getOrDefault("ApplicationName")
  valid_612831 = validateParameter(valid_612831, JString, required = true,
                                 default = nil)
  if valid_612831 != nil:
    section.add "ApplicationName", valid_612831
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612832: Call_PostUpdateConfigurationTemplate_612815;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Updates the specified configuration template to have the specified properties or configuration option values.</p> <note> <p>If a property (for example, <code>ApplicationName</code>) is not provided, its value remains unchanged. To clear such properties, specify an empty string.</p> </note> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> </ul>
  ## 
  let valid = call_612832.validator(path, query, header, formData, body)
  let scheme = call_612832.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612832.url(scheme.get, call_612832.host, call_612832.base,
                         call_612832.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612832, url, valid)

proc call*(call_612833: Call_PostUpdateConfigurationTemplate_612815;
          TemplateName: string; ApplicationName: string; Description: string = "";
          OptionsToRemove: JsonNode = nil; OptionSettings: JsonNode = nil;
          Action: string = "UpdateConfigurationTemplate";
          Version: string = "2010-12-01"): Recallable =
  ## postUpdateConfigurationTemplate
  ## <p>Updates the specified configuration template to have the specified properties or configuration option values.</p> <note> <p>If a property (for example, <code>ApplicationName</code>) is not provided, its value remains unchanged. To clear such properties, specify an empty string.</p> </note> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> </ul>
  ##   Description: string
  ##              : A new description for the configuration.
  ##   TemplateName: string (required)
  ##               : <p>The name of the configuration template to update.</p> <p> If no configuration template is found with this name, <code>UpdateConfigurationTemplate</code> returns an <code>InvalidParameterValue</code> error. </p>
  ##   OptionsToRemove: JArray
  ##                  : <p>A list of configuration options to remove from the configuration set.</p> <p> Constraint: You can remove only <code>UserDefined</code> configuration options. </p>
  ##   OptionSettings: JArray
  ##                 : A list of configuration option settings to update with the new specified option value.
  ##   ApplicationName: string (required)
  ##                  : <p>The name of the application associated with the configuration template to update.</p> <p> If no application is found with this name, <code>UpdateConfigurationTemplate</code> returns an <code>InvalidParameterValue</code> error. </p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612834 = newJObject()
  var formData_612835 = newJObject()
  add(formData_612835, "Description", newJString(Description))
  add(formData_612835, "TemplateName", newJString(TemplateName))
  if OptionsToRemove != nil:
    formData_612835.add "OptionsToRemove", OptionsToRemove
  if OptionSettings != nil:
    formData_612835.add "OptionSettings", OptionSettings
  add(formData_612835, "ApplicationName", newJString(ApplicationName))
  add(query_612834, "Action", newJString(Action))
  add(query_612834, "Version", newJString(Version))
  result = call_612833.call(nil, query_612834, nil, formData_612835, nil)

var postUpdateConfigurationTemplate* = Call_PostUpdateConfigurationTemplate_612815(
    name: "postUpdateConfigurationTemplate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateConfigurationTemplate",
    validator: validate_PostUpdateConfigurationTemplate_612816, base: "/",
    url: url_PostUpdateConfigurationTemplate_612817,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateConfigurationTemplate_612795 = ref object of OpenApiRestCall_610659
proc url_GetUpdateConfigurationTemplate_612797(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateConfigurationTemplate_612796(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the specified configuration template to have the specified properties or configuration option values.</p> <note> <p>If a property (for example, <code>ApplicationName</code>) is not provided, its value remains unchanged. To clear such properties, specify an empty string.</p> </note> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ApplicationName: JString (required)
  ##                  : <p>The name of the application associated with the configuration template to update.</p> <p> If no application is found with this name, <code>UpdateConfigurationTemplate</code> returns an <code>InvalidParameterValue</code> error. </p>
  ##   OptionSettings: JArray
  ##                 : A list of configuration option settings to update with the new specified option value.
  ##   Action: JString (required)
  ##   Description: JString
  ##              : A new description for the configuration.
  ##   OptionsToRemove: JArray
  ##                  : <p>A list of configuration options to remove from the configuration set.</p> <p> Constraint: You can remove only <code>UserDefined</code> configuration options. </p>
  ##   Version: JString (required)
  ##   TemplateName: JString (required)
  ##               : <p>The name of the configuration template to update.</p> <p> If no configuration template is found with this name, <code>UpdateConfigurationTemplate</code> returns an <code>InvalidParameterValue</code> error. </p>
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_612798 = query.getOrDefault("ApplicationName")
  valid_612798 = validateParameter(valid_612798, JString, required = true,
                                 default = nil)
  if valid_612798 != nil:
    section.add "ApplicationName", valid_612798
  var valid_612799 = query.getOrDefault("OptionSettings")
  valid_612799 = validateParameter(valid_612799, JArray, required = false,
                                 default = nil)
  if valid_612799 != nil:
    section.add "OptionSettings", valid_612799
  var valid_612800 = query.getOrDefault("Action")
  valid_612800 = validateParameter(valid_612800, JString, required = true, default = newJString(
      "UpdateConfigurationTemplate"))
  if valid_612800 != nil:
    section.add "Action", valid_612800
  var valid_612801 = query.getOrDefault("Description")
  valid_612801 = validateParameter(valid_612801, JString, required = false,
                                 default = nil)
  if valid_612801 != nil:
    section.add "Description", valid_612801
  var valid_612802 = query.getOrDefault("OptionsToRemove")
  valid_612802 = validateParameter(valid_612802, JArray, required = false,
                                 default = nil)
  if valid_612802 != nil:
    section.add "OptionsToRemove", valid_612802
  var valid_612803 = query.getOrDefault("Version")
  valid_612803 = validateParameter(valid_612803, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612803 != nil:
    section.add "Version", valid_612803
  var valid_612804 = query.getOrDefault("TemplateName")
  valid_612804 = validateParameter(valid_612804, JString, required = true,
                                 default = nil)
  if valid_612804 != nil:
    section.add "TemplateName", valid_612804
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612805 = header.getOrDefault("X-Amz-Signature")
  valid_612805 = validateParameter(valid_612805, JString, required = false,
                                 default = nil)
  if valid_612805 != nil:
    section.add "X-Amz-Signature", valid_612805
  var valid_612806 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612806 = validateParameter(valid_612806, JString, required = false,
                                 default = nil)
  if valid_612806 != nil:
    section.add "X-Amz-Content-Sha256", valid_612806
  var valid_612807 = header.getOrDefault("X-Amz-Date")
  valid_612807 = validateParameter(valid_612807, JString, required = false,
                                 default = nil)
  if valid_612807 != nil:
    section.add "X-Amz-Date", valid_612807
  var valid_612808 = header.getOrDefault("X-Amz-Credential")
  valid_612808 = validateParameter(valid_612808, JString, required = false,
                                 default = nil)
  if valid_612808 != nil:
    section.add "X-Amz-Credential", valid_612808
  var valid_612809 = header.getOrDefault("X-Amz-Security-Token")
  valid_612809 = validateParameter(valid_612809, JString, required = false,
                                 default = nil)
  if valid_612809 != nil:
    section.add "X-Amz-Security-Token", valid_612809
  var valid_612810 = header.getOrDefault("X-Amz-Algorithm")
  valid_612810 = validateParameter(valid_612810, JString, required = false,
                                 default = nil)
  if valid_612810 != nil:
    section.add "X-Amz-Algorithm", valid_612810
  var valid_612811 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612811 = validateParameter(valid_612811, JString, required = false,
                                 default = nil)
  if valid_612811 != nil:
    section.add "X-Amz-SignedHeaders", valid_612811
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612812: Call_GetUpdateConfigurationTemplate_612795; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified configuration template to have the specified properties or configuration option values.</p> <note> <p>If a property (for example, <code>ApplicationName</code>) is not provided, its value remains unchanged. To clear such properties, specify an empty string.</p> </note> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> </ul>
  ## 
  let valid = call_612812.validator(path, query, header, formData, body)
  let scheme = call_612812.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612812.url(scheme.get, call_612812.host, call_612812.base,
                         call_612812.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612812, url, valid)

proc call*(call_612813: Call_GetUpdateConfigurationTemplate_612795;
          ApplicationName: string; TemplateName: string;
          OptionSettings: JsonNode = nil;
          Action: string = "UpdateConfigurationTemplate"; Description: string = "";
          OptionsToRemove: JsonNode = nil; Version: string = "2010-12-01"): Recallable =
  ## getUpdateConfigurationTemplate
  ## <p>Updates the specified configuration template to have the specified properties or configuration option values.</p> <note> <p>If a property (for example, <code>ApplicationName</code>) is not provided, its value remains unchanged. To clear such properties, specify an empty string.</p> </note> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> </ul>
  ##   ApplicationName: string (required)
  ##                  : <p>The name of the application associated with the configuration template to update.</p> <p> If no application is found with this name, <code>UpdateConfigurationTemplate</code> returns an <code>InvalidParameterValue</code> error. </p>
  ##   OptionSettings: JArray
  ##                 : A list of configuration option settings to update with the new specified option value.
  ##   Action: string (required)
  ##   Description: string
  ##              : A new description for the configuration.
  ##   OptionsToRemove: JArray
  ##                  : <p>A list of configuration options to remove from the configuration set.</p> <p> Constraint: You can remove only <code>UserDefined</code> configuration options. </p>
  ##   Version: string (required)
  ##   TemplateName: string (required)
  ##               : <p>The name of the configuration template to update.</p> <p> If no configuration template is found with this name, <code>UpdateConfigurationTemplate</code> returns an <code>InvalidParameterValue</code> error. </p>
  var query_612814 = newJObject()
  add(query_612814, "ApplicationName", newJString(ApplicationName))
  if OptionSettings != nil:
    query_612814.add "OptionSettings", OptionSettings
  add(query_612814, "Action", newJString(Action))
  add(query_612814, "Description", newJString(Description))
  if OptionsToRemove != nil:
    query_612814.add "OptionsToRemove", OptionsToRemove
  add(query_612814, "Version", newJString(Version))
  add(query_612814, "TemplateName", newJString(TemplateName))
  result = call_612813.call(nil, query_612814, nil, nil, nil)

var getUpdateConfigurationTemplate* = Call_GetUpdateConfigurationTemplate_612795(
    name: "getUpdateConfigurationTemplate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateConfigurationTemplate",
    validator: validate_GetUpdateConfigurationTemplate_612796, base: "/",
    url: url_GetUpdateConfigurationTemplate_612797,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateEnvironment_612865 = ref object of OpenApiRestCall_610659
proc url_PostUpdateEnvironment_612867(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateEnvironment_612866(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the environment description, deploys a new application version, updates the configuration settings to an entirely new configuration template, or updates select configuration option values in the running environment.</p> <p> Attempting to update both the release and configuration is not allowed and AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. </p> <p> When updating the configuration settings to a new template or individual settings, a draft configuration is created and <a>DescribeConfigurationSettings</a> for this environment returns two setting descriptions with different <code>DeploymentStatus</code> values. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612868 = query.getOrDefault("Action")
  valid_612868 = validateParameter(valid_612868, JString, required = true,
                                 default = newJString("UpdateEnvironment"))
  if valid_612868 != nil:
    section.add "Action", valid_612868
  var valid_612869 = query.getOrDefault("Version")
  valid_612869 = validateParameter(valid_612869, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612869 != nil:
    section.add "Version", valid_612869
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612870 = header.getOrDefault("X-Amz-Signature")
  valid_612870 = validateParameter(valid_612870, JString, required = false,
                                 default = nil)
  if valid_612870 != nil:
    section.add "X-Amz-Signature", valid_612870
  var valid_612871 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612871 = validateParameter(valid_612871, JString, required = false,
                                 default = nil)
  if valid_612871 != nil:
    section.add "X-Amz-Content-Sha256", valid_612871
  var valid_612872 = header.getOrDefault("X-Amz-Date")
  valid_612872 = validateParameter(valid_612872, JString, required = false,
                                 default = nil)
  if valid_612872 != nil:
    section.add "X-Amz-Date", valid_612872
  var valid_612873 = header.getOrDefault("X-Amz-Credential")
  valid_612873 = validateParameter(valid_612873, JString, required = false,
                                 default = nil)
  if valid_612873 != nil:
    section.add "X-Amz-Credential", valid_612873
  var valid_612874 = header.getOrDefault("X-Amz-Security-Token")
  valid_612874 = validateParameter(valid_612874, JString, required = false,
                                 default = nil)
  if valid_612874 != nil:
    section.add "X-Amz-Security-Token", valid_612874
  var valid_612875 = header.getOrDefault("X-Amz-Algorithm")
  valid_612875 = validateParameter(valid_612875, JString, required = false,
                                 default = nil)
  if valid_612875 != nil:
    section.add "X-Amz-Algorithm", valid_612875
  var valid_612876 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612876 = validateParameter(valid_612876, JString, required = false,
                                 default = nil)
  if valid_612876 != nil:
    section.add "X-Amz-SignedHeaders", valid_612876
  result.add "header", section
  ## parameters in `formData` object:
  ##   Description: JString
  ##              : If this parameter is specified, AWS Elastic Beanstalk updates the description of this environment.
  ##   Tier.Type: JString
  ##            : Describes the properties of an environment tier
  ## <p>The type of this environment tier.</p> <p>Valid values:</p> <ul> <li> <p>For <i>Web server tier</i> – <code>Standard</code> </p> </li> <li> <p>For <i>Worker tier</i> – <code>SQS/HTTP</code> </p> </li> </ul>
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to update. If no environment with this name exists, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. </p> <p>Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   VersionLabel: JString
  ##               : If this parameter is specified, AWS Elastic Beanstalk deploys the named application version to the environment. If no such application version is found, returns an <code>InvalidParameterValue</code> error. 
  ##   TemplateName: JString
  ##               : If this parameter is specified, AWS Elastic Beanstalk deploys this configuration template to the environment. If no such configuration template is found, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. 
  ##   OptionsToRemove: JArray
  ##                  : A list of custom user-defined configuration options to remove from the configuration set for this environment.
  ##   OptionSettings: JArray
  ##                 : If specified, AWS Elastic Beanstalk updates the configuration set associated with the running environment and sets the specified configuration options to the requested value.
  ##   GroupName: JString
  ##            : The name of the group to which the target environment belongs. Specify a group name only if the environment's name is specified in an environment manifest and not with the environment name or environment ID parameters. See <a 
  ## href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-cfg-manifest.html">Environment Manifest (env.yaml)</a> for details.
  ##   ApplicationName: JString
  ##                  : The name of the application with which the environment is associated.
  ##   Tier.Name: JString
  ##            : Describes the properties of an environment tier
  ## <p>The name of this environment tier.</p> <p>Valid values:</p> <ul> <li> <p>For <i>Web server tier</i> – <code>WebServer</code> </p> </li> <li> <p>For <i>Worker tier</i> – <code>Worker</code> </p> </li> </ul>
  ##   Tier.Version: JString
  ##               : Describes the properties of an environment tier
  ## <p>The version of this environment tier. When you don't set a value to it, Elastic Beanstalk uses the latest compatible worker tier version.</p> <note> <p>This member is deprecated. Any specific version that you set may become out of date. We recommend leaving it unspecified.</p> </note>
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to update.</p> <p>If no environment with this ID exists, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error.</p> <p>Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   SolutionStackName: JString
  ##                    : This specifies the platform version that the environment will run after the environment is updated.
  ##   PlatformArn: JString
  ##              : The ARN of the platform, if used.
  section = newJObject()
  var valid_612877 = formData.getOrDefault("Description")
  valid_612877 = validateParameter(valid_612877, JString, required = false,
                                 default = nil)
  if valid_612877 != nil:
    section.add "Description", valid_612877
  var valid_612878 = formData.getOrDefault("Tier.Type")
  valid_612878 = validateParameter(valid_612878, JString, required = false,
                                 default = nil)
  if valid_612878 != nil:
    section.add "Tier.Type", valid_612878
  var valid_612879 = formData.getOrDefault("EnvironmentName")
  valid_612879 = validateParameter(valid_612879, JString, required = false,
                                 default = nil)
  if valid_612879 != nil:
    section.add "EnvironmentName", valid_612879
  var valid_612880 = formData.getOrDefault("VersionLabel")
  valid_612880 = validateParameter(valid_612880, JString, required = false,
                                 default = nil)
  if valid_612880 != nil:
    section.add "VersionLabel", valid_612880
  var valid_612881 = formData.getOrDefault("TemplateName")
  valid_612881 = validateParameter(valid_612881, JString, required = false,
                                 default = nil)
  if valid_612881 != nil:
    section.add "TemplateName", valid_612881
  var valid_612882 = formData.getOrDefault("OptionsToRemove")
  valid_612882 = validateParameter(valid_612882, JArray, required = false,
                                 default = nil)
  if valid_612882 != nil:
    section.add "OptionsToRemove", valid_612882
  var valid_612883 = formData.getOrDefault("OptionSettings")
  valid_612883 = validateParameter(valid_612883, JArray, required = false,
                                 default = nil)
  if valid_612883 != nil:
    section.add "OptionSettings", valid_612883
  var valid_612884 = formData.getOrDefault("GroupName")
  valid_612884 = validateParameter(valid_612884, JString, required = false,
                                 default = nil)
  if valid_612884 != nil:
    section.add "GroupName", valid_612884
  var valid_612885 = formData.getOrDefault("ApplicationName")
  valid_612885 = validateParameter(valid_612885, JString, required = false,
                                 default = nil)
  if valid_612885 != nil:
    section.add "ApplicationName", valid_612885
  var valid_612886 = formData.getOrDefault("Tier.Name")
  valid_612886 = validateParameter(valid_612886, JString, required = false,
                                 default = nil)
  if valid_612886 != nil:
    section.add "Tier.Name", valid_612886
  var valid_612887 = formData.getOrDefault("Tier.Version")
  valid_612887 = validateParameter(valid_612887, JString, required = false,
                                 default = nil)
  if valid_612887 != nil:
    section.add "Tier.Version", valid_612887
  var valid_612888 = formData.getOrDefault("EnvironmentId")
  valid_612888 = validateParameter(valid_612888, JString, required = false,
                                 default = nil)
  if valid_612888 != nil:
    section.add "EnvironmentId", valid_612888
  var valid_612889 = formData.getOrDefault("SolutionStackName")
  valid_612889 = validateParameter(valid_612889, JString, required = false,
                                 default = nil)
  if valid_612889 != nil:
    section.add "SolutionStackName", valid_612889
  var valid_612890 = formData.getOrDefault("PlatformArn")
  valid_612890 = validateParameter(valid_612890, JString, required = false,
                                 default = nil)
  if valid_612890 != nil:
    section.add "PlatformArn", valid_612890
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612891: Call_PostUpdateEnvironment_612865; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the environment description, deploys a new application version, updates the configuration settings to an entirely new configuration template, or updates select configuration option values in the running environment.</p> <p> Attempting to update both the release and configuration is not allowed and AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. </p> <p> When updating the configuration settings to a new template or individual settings, a draft configuration is created and <a>DescribeConfigurationSettings</a> for this environment returns two setting descriptions with different <code>DeploymentStatus</code> values. </p>
  ## 
  let valid = call_612891.validator(path, query, header, formData, body)
  let scheme = call_612891.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612891.url(scheme.get, call_612891.host, call_612891.base,
                         call_612891.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612891, url, valid)

proc call*(call_612892: Call_PostUpdateEnvironment_612865;
          Description: string = ""; TierType: string = ""; EnvironmentName: string = "";
          VersionLabel: string = ""; TemplateName: string = "";
          OptionsToRemove: JsonNode = nil; OptionSettings: JsonNode = nil;
          GroupName: string = ""; ApplicationName: string = ""; TierName: string = "";
          TierVersion: string = ""; Action: string = "UpdateEnvironment";
          EnvironmentId: string = ""; SolutionStackName: string = "";
          Version: string = "2010-12-01"; PlatformArn: string = ""): Recallable =
  ## postUpdateEnvironment
  ## <p>Updates the environment description, deploys a new application version, updates the configuration settings to an entirely new configuration template, or updates select configuration option values in the running environment.</p> <p> Attempting to update both the release and configuration is not allowed and AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. </p> <p> When updating the configuration settings to a new template or individual settings, a draft configuration is created and <a>DescribeConfigurationSettings</a> for this environment returns two setting descriptions with different <code>DeploymentStatus</code> values. </p>
  ##   Description: string
  ##              : If this parameter is specified, AWS Elastic Beanstalk updates the description of this environment.
  ##   TierType: string
  ##           : Describes the properties of an environment tier
  ## <p>The type of this environment tier.</p> <p>Valid values:</p> <ul> <li> <p>For <i>Web server tier</i> – <code>Standard</code> </p> </li> <li> <p>For <i>Worker tier</i> – <code>SQS/HTTP</code> </p> </li> </ul>
  ##   EnvironmentName: string
  ##                  : <p>The name of the environment to update. If no environment with this name exists, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. </p> <p>Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   VersionLabel: string
  ##               : If this parameter is specified, AWS Elastic Beanstalk deploys the named application version to the environment. If no such application version is found, returns an <code>InvalidParameterValue</code> error. 
  ##   TemplateName: string
  ##               : If this parameter is specified, AWS Elastic Beanstalk deploys this configuration template to the environment. If no such configuration template is found, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. 
  ##   OptionsToRemove: JArray
  ##                  : A list of custom user-defined configuration options to remove from the configuration set for this environment.
  ##   OptionSettings: JArray
  ##                 : If specified, AWS Elastic Beanstalk updates the configuration set associated with the running environment and sets the specified configuration options to the requested value.
  ##   GroupName: string
  ##            : The name of the group to which the target environment belongs. Specify a group name only if the environment's name is specified in an environment manifest and not with the environment name or environment ID parameters. See <a 
  ## href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-cfg-manifest.html">Environment Manifest (env.yaml)</a> for details.
  ##   ApplicationName: string
  ##                  : The name of the application with which the environment is associated.
  ##   TierName: string
  ##           : Describes the properties of an environment tier
  ## <p>The name of this environment tier.</p> <p>Valid values:</p> <ul> <li> <p>For <i>Web server tier</i> – <code>WebServer</code> </p> </li> <li> <p>For <i>Worker tier</i> – <code>Worker</code> </p> </li> </ul>
  ##   TierVersion: string
  ##              : Describes the properties of an environment tier
  ## <p>The version of this environment tier. When you don't set a value to it, Elastic Beanstalk uses the latest compatible worker tier version.</p> <note> <p>This member is deprecated. Any specific version that you set may become out of date. We recommend leaving it unspecified.</p> </note>
  ##   Action: string (required)
  ##   EnvironmentId: string
  ##                : <p>The ID of the environment to update.</p> <p>If no environment with this ID exists, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error.</p> <p>Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   SolutionStackName: string
  ##                    : This specifies the platform version that the environment will run after the environment is updated.
  ##   Version: string (required)
  ##   PlatformArn: string
  ##              : The ARN of the platform, if used.
  var query_612893 = newJObject()
  var formData_612894 = newJObject()
  add(formData_612894, "Description", newJString(Description))
  add(formData_612894, "Tier.Type", newJString(TierType))
  add(formData_612894, "EnvironmentName", newJString(EnvironmentName))
  add(formData_612894, "VersionLabel", newJString(VersionLabel))
  add(formData_612894, "TemplateName", newJString(TemplateName))
  if OptionsToRemove != nil:
    formData_612894.add "OptionsToRemove", OptionsToRemove
  if OptionSettings != nil:
    formData_612894.add "OptionSettings", OptionSettings
  add(formData_612894, "GroupName", newJString(GroupName))
  add(formData_612894, "ApplicationName", newJString(ApplicationName))
  add(formData_612894, "Tier.Name", newJString(TierName))
  add(formData_612894, "Tier.Version", newJString(TierVersion))
  add(query_612893, "Action", newJString(Action))
  add(formData_612894, "EnvironmentId", newJString(EnvironmentId))
  add(formData_612894, "SolutionStackName", newJString(SolutionStackName))
  add(query_612893, "Version", newJString(Version))
  add(formData_612894, "PlatformArn", newJString(PlatformArn))
  result = call_612892.call(nil, query_612893, nil, formData_612894, nil)

var postUpdateEnvironment* = Call_PostUpdateEnvironment_612865(
    name: "postUpdateEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateEnvironment",
    validator: validate_PostUpdateEnvironment_612866, base: "/",
    url: url_PostUpdateEnvironment_612867, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateEnvironment_612836 = ref object of OpenApiRestCall_610659
proc url_GetUpdateEnvironment_612838(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateEnvironment_612837(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the environment description, deploys a new application version, updates the configuration settings to an entirely new configuration template, or updates select configuration option values in the running environment.</p> <p> Attempting to update both the release and configuration is not allowed and AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. </p> <p> When updating the configuration settings to a new template or individual settings, a draft configuration is created and <a>DescribeConfigurationSettings</a> for this environment returns two setting descriptions with different <code>DeploymentStatus</code> values. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ApplicationName: JString
  ##                  : The name of the application with which the environment is associated.
  ##   GroupName: JString
  ##            : The name of the group to which the target environment belongs. Specify a group name only if the environment's name is specified in an environment manifest and not with the environment name or environment ID parameters. See <a 
  ## href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-cfg-manifest.html">Environment Manifest (env.yaml)</a> for details.
  ##   VersionLabel: JString
  ##               : If this parameter is specified, AWS Elastic Beanstalk deploys the named application version to the environment. If no such application version is found, returns an <code>InvalidParameterValue</code> error. 
  ##   OptionSettings: JArray
  ##                 : If specified, AWS Elastic Beanstalk updates the configuration set associated with the running environment and sets the specified configuration options to the requested value.
  ##   SolutionStackName: JString
  ##                    : This specifies the platform version that the environment will run after the environment is updated.
  ##   Tier.Name: JString
  ##            : Describes the properties of an environment tier
  ## <p>The name of this environment tier.</p> <p>Valid values:</p> <ul> <li> <p>For <i>Web server tier</i> – <code>WebServer</code> </p> </li> <li> <p>For <i>Worker tier</i> – <code>Worker</code> </p> </li> </ul>
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to update. If no environment with this name exists, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. </p> <p>Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Action: JString (required)
  ##   Description: JString
  ##              : If this parameter is specified, AWS Elastic Beanstalk updates the description of this environment.
  ##   PlatformArn: JString
  ##              : The ARN of the platform, if used.
  ##   OptionsToRemove: JArray
  ##                  : A list of custom user-defined configuration options to remove from the configuration set for this environment.
  ##   Version: JString (required)
  ##   TemplateName: JString
  ##               : If this parameter is specified, AWS Elastic Beanstalk deploys this configuration template to the environment. If no such configuration template is found, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. 
  ##   Tier.Version: JString
  ##               : Describes the properties of an environment tier
  ## <p>The version of this environment tier. When you don't set a value to it, Elastic Beanstalk uses the latest compatible worker tier version.</p> <note> <p>This member is deprecated. Any specific version that you set may become out of date. We recommend leaving it unspecified.</p> </note>
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to update.</p> <p>If no environment with this ID exists, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error.</p> <p>Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Tier.Type: JString
  ##            : Describes the properties of an environment tier
  ## <p>The type of this environment tier.</p> <p>Valid values:</p> <ul> <li> <p>For <i>Web server tier</i> – <code>Standard</code> </p> </li> <li> <p>For <i>Worker tier</i> – <code>SQS/HTTP</code> </p> </li> </ul>
  section = newJObject()
  var valid_612839 = query.getOrDefault("ApplicationName")
  valid_612839 = validateParameter(valid_612839, JString, required = false,
                                 default = nil)
  if valid_612839 != nil:
    section.add "ApplicationName", valid_612839
  var valid_612840 = query.getOrDefault("GroupName")
  valid_612840 = validateParameter(valid_612840, JString, required = false,
                                 default = nil)
  if valid_612840 != nil:
    section.add "GroupName", valid_612840
  var valid_612841 = query.getOrDefault("VersionLabel")
  valid_612841 = validateParameter(valid_612841, JString, required = false,
                                 default = nil)
  if valid_612841 != nil:
    section.add "VersionLabel", valid_612841
  var valid_612842 = query.getOrDefault("OptionSettings")
  valid_612842 = validateParameter(valid_612842, JArray, required = false,
                                 default = nil)
  if valid_612842 != nil:
    section.add "OptionSettings", valid_612842
  var valid_612843 = query.getOrDefault("SolutionStackName")
  valid_612843 = validateParameter(valid_612843, JString, required = false,
                                 default = nil)
  if valid_612843 != nil:
    section.add "SolutionStackName", valid_612843
  var valid_612844 = query.getOrDefault("Tier.Name")
  valid_612844 = validateParameter(valid_612844, JString, required = false,
                                 default = nil)
  if valid_612844 != nil:
    section.add "Tier.Name", valid_612844
  var valid_612845 = query.getOrDefault("EnvironmentName")
  valid_612845 = validateParameter(valid_612845, JString, required = false,
                                 default = nil)
  if valid_612845 != nil:
    section.add "EnvironmentName", valid_612845
  var valid_612846 = query.getOrDefault("Action")
  valid_612846 = validateParameter(valid_612846, JString, required = true,
                                 default = newJString("UpdateEnvironment"))
  if valid_612846 != nil:
    section.add "Action", valid_612846
  var valid_612847 = query.getOrDefault("Description")
  valid_612847 = validateParameter(valid_612847, JString, required = false,
                                 default = nil)
  if valid_612847 != nil:
    section.add "Description", valid_612847
  var valid_612848 = query.getOrDefault("PlatformArn")
  valid_612848 = validateParameter(valid_612848, JString, required = false,
                                 default = nil)
  if valid_612848 != nil:
    section.add "PlatformArn", valid_612848
  var valid_612849 = query.getOrDefault("OptionsToRemove")
  valid_612849 = validateParameter(valid_612849, JArray, required = false,
                                 default = nil)
  if valid_612849 != nil:
    section.add "OptionsToRemove", valid_612849
  var valid_612850 = query.getOrDefault("Version")
  valid_612850 = validateParameter(valid_612850, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612850 != nil:
    section.add "Version", valid_612850
  var valid_612851 = query.getOrDefault("TemplateName")
  valid_612851 = validateParameter(valid_612851, JString, required = false,
                                 default = nil)
  if valid_612851 != nil:
    section.add "TemplateName", valid_612851
  var valid_612852 = query.getOrDefault("Tier.Version")
  valid_612852 = validateParameter(valid_612852, JString, required = false,
                                 default = nil)
  if valid_612852 != nil:
    section.add "Tier.Version", valid_612852
  var valid_612853 = query.getOrDefault("EnvironmentId")
  valid_612853 = validateParameter(valid_612853, JString, required = false,
                                 default = nil)
  if valid_612853 != nil:
    section.add "EnvironmentId", valid_612853
  var valid_612854 = query.getOrDefault("Tier.Type")
  valid_612854 = validateParameter(valid_612854, JString, required = false,
                                 default = nil)
  if valid_612854 != nil:
    section.add "Tier.Type", valid_612854
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612855 = header.getOrDefault("X-Amz-Signature")
  valid_612855 = validateParameter(valid_612855, JString, required = false,
                                 default = nil)
  if valid_612855 != nil:
    section.add "X-Amz-Signature", valid_612855
  var valid_612856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612856 = validateParameter(valid_612856, JString, required = false,
                                 default = nil)
  if valid_612856 != nil:
    section.add "X-Amz-Content-Sha256", valid_612856
  var valid_612857 = header.getOrDefault("X-Amz-Date")
  valid_612857 = validateParameter(valid_612857, JString, required = false,
                                 default = nil)
  if valid_612857 != nil:
    section.add "X-Amz-Date", valid_612857
  var valid_612858 = header.getOrDefault("X-Amz-Credential")
  valid_612858 = validateParameter(valid_612858, JString, required = false,
                                 default = nil)
  if valid_612858 != nil:
    section.add "X-Amz-Credential", valid_612858
  var valid_612859 = header.getOrDefault("X-Amz-Security-Token")
  valid_612859 = validateParameter(valid_612859, JString, required = false,
                                 default = nil)
  if valid_612859 != nil:
    section.add "X-Amz-Security-Token", valid_612859
  var valid_612860 = header.getOrDefault("X-Amz-Algorithm")
  valid_612860 = validateParameter(valid_612860, JString, required = false,
                                 default = nil)
  if valid_612860 != nil:
    section.add "X-Amz-Algorithm", valid_612860
  var valid_612861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612861 = validateParameter(valid_612861, JString, required = false,
                                 default = nil)
  if valid_612861 != nil:
    section.add "X-Amz-SignedHeaders", valid_612861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612862: Call_GetUpdateEnvironment_612836; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the environment description, deploys a new application version, updates the configuration settings to an entirely new configuration template, or updates select configuration option values in the running environment.</p> <p> Attempting to update both the release and configuration is not allowed and AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. </p> <p> When updating the configuration settings to a new template or individual settings, a draft configuration is created and <a>DescribeConfigurationSettings</a> for this environment returns two setting descriptions with different <code>DeploymentStatus</code> values. </p>
  ## 
  let valid = call_612862.validator(path, query, header, formData, body)
  let scheme = call_612862.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612862.url(scheme.get, call_612862.host, call_612862.base,
                         call_612862.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612862, url, valid)

proc call*(call_612863: Call_GetUpdateEnvironment_612836;
          ApplicationName: string = ""; GroupName: string = "";
          VersionLabel: string = ""; OptionSettings: JsonNode = nil;
          SolutionStackName: string = ""; TierName: string = "";
          EnvironmentName: string = ""; Action: string = "UpdateEnvironment";
          Description: string = ""; PlatformArn: string = "";
          OptionsToRemove: JsonNode = nil; Version: string = "2010-12-01";
          TemplateName: string = ""; TierVersion: string = "";
          EnvironmentId: string = ""; TierType: string = ""): Recallable =
  ## getUpdateEnvironment
  ## <p>Updates the environment description, deploys a new application version, updates the configuration settings to an entirely new configuration template, or updates select configuration option values in the running environment.</p> <p> Attempting to update both the release and configuration is not allowed and AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. </p> <p> When updating the configuration settings to a new template or individual settings, a draft configuration is created and <a>DescribeConfigurationSettings</a> for this environment returns two setting descriptions with different <code>DeploymentStatus</code> values. </p>
  ##   ApplicationName: string
  ##                  : The name of the application with which the environment is associated.
  ##   GroupName: string
  ##            : The name of the group to which the target environment belongs. Specify a group name only if the environment's name is specified in an environment manifest and not with the environment name or environment ID parameters. See <a 
  ## href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-cfg-manifest.html">Environment Manifest (env.yaml)</a> for details.
  ##   VersionLabel: string
  ##               : If this parameter is specified, AWS Elastic Beanstalk deploys the named application version to the environment. If no such application version is found, returns an <code>InvalidParameterValue</code> error. 
  ##   OptionSettings: JArray
  ##                 : If specified, AWS Elastic Beanstalk updates the configuration set associated with the running environment and sets the specified configuration options to the requested value.
  ##   SolutionStackName: string
  ##                    : This specifies the platform version that the environment will run after the environment is updated.
  ##   TierName: string
  ##           : Describes the properties of an environment tier
  ## <p>The name of this environment tier.</p> <p>Valid values:</p> <ul> <li> <p>For <i>Web server tier</i> – <code>WebServer</code> </p> </li> <li> <p>For <i>Worker tier</i> – <code>Worker</code> </p> </li> </ul>
  ##   EnvironmentName: string
  ##                  : <p>The name of the environment to update. If no environment with this name exists, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. </p> <p>Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Action: string (required)
  ##   Description: string
  ##              : If this parameter is specified, AWS Elastic Beanstalk updates the description of this environment.
  ##   PlatformArn: string
  ##              : The ARN of the platform, if used.
  ##   OptionsToRemove: JArray
  ##                  : A list of custom user-defined configuration options to remove from the configuration set for this environment.
  ##   Version: string (required)
  ##   TemplateName: string
  ##               : If this parameter is specified, AWS Elastic Beanstalk deploys this configuration template to the environment. If no such configuration template is found, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. 
  ##   TierVersion: string
  ##              : Describes the properties of an environment tier
  ## <p>The version of this environment tier. When you don't set a value to it, Elastic Beanstalk uses the latest compatible worker tier version.</p> <note> <p>This member is deprecated. Any specific version that you set may become out of date. We recommend leaving it unspecified.</p> </note>
  ##   EnvironmentId: string
  ##                : <p>The ID of the environment to update.</p> <p>If no environment with this ID exists, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error.</p> <p>Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   TierType: string
  ##           : Describes the properties of an environment tier
  ## <p>The type of this environment tier.</p> <p>Valid values:</p> <ul> <li> <p>For <i>Web server tier</i> – <code>Standard</code> </p> </li> <li> <p>For <i>Worker tier</i> – <code>SQS/HTTP</code> </p> </li> </ul>
  var query_612864 = newJObject()
  add(query_612864, "ApplicationName", newJString(ApplicationName))
  add(query_612864, "GroupName", newJString(GroupName))
  add(query_612864, "VersionLabel", newJString(VersionLabel))
  if OptionSettings != nil:
    query_612864.add "OptionSettings", OptionSettings
  add(query_612864, "SolutionStackName", newJString(SolutionStackName))
  add(query_612864, "Tier.Name", newJString(TierName))
  add(query_612864, "EnvironmentName", newJString(EnvironmentName))
  add(query_612864, "Action", newJString(Action))
  add(query_612864, "Description", newJString(Description))
  add(query_612864, "PlatformArn", newJString(PlatformArn))
  if OptionsToRemove != nil:
    query_612864.add "OptionsToRemove", OptionsToRemove
  add(query_612864, "Version", newJString(Version))
  add(query_612864, "TemplateName", newJString(TemplateName))
  add(query_612864, "Tier.Version", newJString(TierVersion))
  add(query_612864, "EnvironmentId", newJString(EnvironmentId))
  add(query_612864, "Tier.Type", newJString(TierType))
  result = call_612863.call(nil, query_612864, nil, nil, nil)

var getUpdateEnvironment* = Call_GetUpdateEnvironment_612836(
    name: "getUpdateEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateEnvironment",
    validator: validate_GetUpdateEnvironment_612837, base: "/",
    url: url_GetUpdateEnvironment_612838, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateTagsForResource_612913 = ref object of OpenApiRestCall_610659
proc url_PostUpdateTagsForResource_612915(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateTagsForResource_612914(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Update the list of tags applied to an AWS Elastic Beanstalk resource. Two lists can be passed: <code>TagsToAdd</code> for tags to add or update, and <code>TagsToRemove</code>.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p> <p>If you create a custom IAM user policy to control permission to this operation, specify one of the following two virtual actions (or both) instead of the API operation name:</p> <dl> <dt>elasticbeanstalk:AddTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tags to add in the <code>TagsToAdd</code> parameter.</p> </dd> <dt>elasticbeanstalk:RemoveTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tag keys to remove in the <code>TagsToRemove</code> parameter.</p> </dd> </dl> <p>For details about creating a custom user policy, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/AWSHowTo.iam.managed-policies.html#AWSHowTo.iam.policies">Creating a Custom User Policy</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612916 = query.getOrDefault("Action")
  valid_612916 = validateParameter(valid_612916, JString, required = true,
                                 default = newJString("UpdateTagsForResource"))
  if valid_612916 != nil:
    section.add "Action", valid_612916
  var valid_612917 = query.getOrDefault("Version")
  valid_612917 = validateParameter(valid_612917, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612917 != nil:
    section.add "Version", valid_612917
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612918 = header.getOrDefault("X-Amz-Signature")
  valid_612918 = validateParameter(valid_612918, JString, required = false,
                                 default = nil)
  if valid_612918 != nil:
    section.add "X-Amz-Signature", valid_612918
  var valid_612919 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612919 = validateParameter(valid_612919, JString, required = false,
                                 default = nil)
  if valid_612919 != nil:
    section.add "X-Amz-Content-Sha256", valid_612919
  var valid_612920 = header.getOrDefault("X-Amz-Date")
  valid_612920 = validateParameter(valid_612920, JString, required = false,
                                 default = nil)
  if valid_612920 != nil:
    section.add "X-Amz-Date", valid_612920
  var valid_612921 = header.getOrDefault("X-Amz-Credential")
  valid_612921 = validateParameter(valid_612921, JString, required = false,
                                 default = nil)
  if valid_612921 != nil:
    section.add "X-Amz-Credential", valid_612921
  var valid_612922 = header.getOrDefault("X-Amz-Security-Token")
  valid_612922 = validateParameter(valid_612922, JString, required = false,
                                 default = nil)
  if valid_612922 != nil:
    section.add "X-Amz-Security-Token", valid_612922
  var valid_612923 = header.getOrDefault("X-Amz-Algorithm")
  valid_612923 = validateParameter(valid_612923, JString, required = false,
                                 default = nil)
  if valid_612923 != nil:
    section.add "X-Amz-Algorithm", valid_612923
  var valid_612924 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612924 = validateParameter(valid_612924, JString, required = false,
                                 default = nil)
  if valid_612924 != nil:
    section.add "X-Amz-SignedHeaders", valid_612924
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArn: JString (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce to be updated.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  ##   TagsToAdd: JArray
  ##            : <p>A list of tags to add or update.</p> <p>If a key of an existing tag is added, the tag's value is updated.</p>
  ##   TagsToRemove: JArray
  ##               : <p>A list of tag keys to remove.</p> <p>If a tag key doesn't exist, it is silently ignored.</p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArn` field"
  var valid_612925 = formData.getOrDefault("ResourceArn")
  valid_612925 = validateParameter(valid_612925, JString, required = true,
                                 default = nil)
  if valid_612925 != nil:
    section.add "ResourceArn", valid_612925
  var valid_612926 = formData.getOrDefault("TagsToAdd")
  valid_612926 = validateParameter(valid_612926, JArray, required = false,
                                 default = nil)
  if valid_612926 != nil:
    section.add "TagsToAdd", valid_612926
  var valid_612927 = formData.getOrDefault("TagsToRemove")
  valid_612927 = validateParameter(valid_612927, JArray, required = false,
                                 default = nil)
  if valid_612927 != nil:
    section.add "TagsToRemove", valid_612927
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612928: Call_PostUpdateTagsForResource_612913; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Update the list of tags applied to an AWS Elastic Beanstalk resource. Two lists can be passed: <code>TagsToAdd</code> for tags to add or update, and <code>TagsToRemove</code>.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p> <p>If you create a custom IAM user policy to control permission to this operation, specify one of the following two virtual actions (or both) instead of the API operation name:</p> <dl> <dt>elasticbeanstalk:AddTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tags to add in the <code>TagsToAdd</code> parameter.</p> </dd> <dt>elasticbeanstalk:RemoveTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tag keys to remove in the <code>TagsToRemove</code> parameter.</p> </dd> </dl> <p>For details about creating a custom user policy, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/AWSHowTo.iam.managed-policies.html#AWSHowTo.iam.policies">Creating a Custom User Policy</a>.</p>
  ## 
  let valid = call_612928.validator(path, query, header, formData, body)
  let scheme = call_612928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612928.url(scheme.get, call_612928.host, call_612928.base,
                         call_612928.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612928, url, valid)

proc call*(call_612929: Call_PostUpdateTagsForResource_612913; ResourceArn: string;
          Action: string = "UpdateTagsForResource"; TagsToAdd: JsonNode = nil;
          TagsToRemove: JsonNode = nil; Version: string = "2010-12-01"): Recallable =
  ## postUpdateTagsForResource
  ## <p>Update the list of tags applied to an AWS Elastic Beanstalk resource. Two lists can be passed: <code>TagsToAdd</code> for tags to add or update, and <code>TagsToRemove</code>.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p> <p>If you create a custom IAM user policy to control permission to this operation, specify one of the following two virtual actions (or both) instead of the API operation name:</p> <dl> <dt>elasticbeanstalk:AddTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tags to add in the <code>TagsToAdd</code> parameter.</p> </dd> <dt>elasticbeanstalk:RemoveTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tag keys to remove in the <code>TagsToRemove</code> parameter.</p> </dd> </dl> <p>For details about creating a custom user policy, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/AWSHowTo.iam.managed-policies.html#AWSHowTo.iam.policies">Creating a Custom User Policy</a>.</p>
  ##   ResourceArn: string (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce to be updated.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  ##   Action: string (required)
  ##   TagsToAdd: JArray
  ##            : <p>A list of tags to add or update.</p> <p>If a key of an existing tag is added, the tag's value is updated.</p>
  ##   TagsToRemove: JArray
  ##               : <p>A list of tag keys to remove.</p> <p>If a tag key doesn't exist, it is silently ignored.</p>
  ##   Version: string (required)
  var query_612930 = newJObject()
  var formData_612931 = newJObject()
  add(formData_612931, "ResourceArn", newJString(ResourceArn))
  add(query_612930, "Action", newJString(Action))
  if TagsToAdd != nil:
    formData_612931.add "TagsToAdd", TagsToAdd
  if TagsToRemove != nil:
    formData_612931.add "TagsToRemove", TagsToRemove
  add(query_612930, "Version", newJString(Version))
  result = call_612929.call(nil, query_612930, nil, formData_612931, nil)

var postUpdateTagsForResource* = Call_PostUpdateTagsForResource_612913(
    name: "postUpdateTagsForResource", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateTagsForResource",
    validator: validate_PostUpdateTagsForResource_612914, base: "/",
    url: url_PostUpdateTagsForResource_612915,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateTagsForResource_612895 = ref object of OpenApiRestCall_610659
proc url_GetUpdateTagsForResource_612897(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateTagsForResource_612896(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Update the list of tags applied to an AWS Elastic Beanstalk resource. Two lists can be passed: <code>TagsToAdd</code> for tags to add or update, and <code>TagsToRemove</code>.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p> <p>If you create a custom IAM user policy to control permission to this operation, specify one of the following two virtual actions (or both) instead of the API operation name:</p> <dl> <dt>elasticbeanstalk:AddTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tags to add in the <code>TagsToAdd</code> parameter.</p> </dd> <dt>elasticbeanstalk:RemoveTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tag keys to remove in the <code>TagsToRemove</code> parameter.</p> </dd> </dl> <p>For details about creating a custom user policy, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/AWSHowTo.iam.managed-policies.html#AWSHowTo.iam.policies">Creating a Custom User Policy</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   TagsToAdd: JArray
  ##            : <p>A list of tags to add or update.</p> <p>If a key of an existing tag is added, the tag's value is updated.</p>
  ##   TagsToRemove: JArray
  ##               : <p>A list of tag keys to remove.</p> <p>If a tag key doesn't exist, it is silently ignored.</p>
  ##   ResourceArn: JString (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce to be updated.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612898 = query.getOrDefault("TagsToAdd")
  valid_612898 = validateParameter(valid_612898, JArray, required = false,
                                 default = nil)
  if valid_612898 != nil:
    section.add "TagsToAdd", valid_612898
  var valid_612899 = query.getOrDefault("TagsToRemove")
  valid_612899 = validateParameter(valid_612899, JArray, required = false,
                                 default = nil)
  if valid_612899 != nil:
    section.add "TagsToRemove", valid_612899
  assert query != nil,
        "query argument is necessary due to required `ResourceArn` field"
  var valid_612900 = query.getOrDefault("ResourceArn")
  valid_612900 = validateParameter(valid_612900, JString, required = true,
                                 default = nil)
  if valid_612900 != nil:
    section.add "ResourceArn", valid_612900
  var valid_612901 = query.getOrDefault("Action")
  valid_612901 = validateParameter(valid_612901, JString, required = true,
                                 default = newJString("UpdateTagsForResource"))
  if valid_612901 != nil:
    section.add "Action", valid_612901
  var valid_612902 = query.getOrDefault("Version")
  valid_612902 = validateParameter(valid_612902, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612902 != nil:
    section.add "Version", valid_612902
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612903 = header.getOrDefault("X-Amz-Signature")
  valid_612903 = validateParameter(valid_612903, JString, required = false,
                                 default = nil)
  if valid_612903 != nil:
    section.add "X-Amz-Signature", valid_612903
  var valid_612904 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612904 = validateParameter(valid_612904, JString, required = false,
                                 default = nil)
  if valid_612904 != nil:
    section.add "X-Amz-Content-Sha256", valid_612904
  var valid_612905 = header.getOrDefault("X-Amz-Date")
  valid_612905 = validateParameter(valid_612905, JString, required = false,
                                 default = nil)
  if valid_612905 != nil:
    section.add "X-Amz-Date", valid_612905
  var valid_612906 = header.getOrDefault("X-Amz-Credential")
  valid_612906 = validateParameter(valid_612906, JString, required = false,
                                 default = nil)
  if valid_612906 != nil:
    section.add "X-Amz-Credential", valid_612906
  var valid_612907 = header.getOrDefault("X-Amz-Security-Token")
  valid_612907 = validateParameter(valid_612907, JString, required = false,
                                 default = nil)
  if valid_612907 != nil:
    section.add "X-Amz-Security-Token", valid_612907
  var valid_612908 = header.getOrDefault("X-Amz-Algorithm")
  valid_612908 = validateParameter(valid_612908, JString, required = false,
                                 default = nil)
  if valid_612908 != nil:
    section.add "X-Amz-Algorithm", valid_612908
  var valid_612909 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612909 = validateParameter(valid_612909, JString, required = false,
                                 default = nil)
  if valid_612909 != nil:
    section.add "X-Amz-SignedHeaders", valid_612909
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612910: Call_GetUpdateTagsForResource_612895; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Update the list of tags applied to an AWS Elastic Beanstalk resource. Two lists can be passed: <code>TagsToAdd</code> for tags to add or update, and <code>TagsToRemove</code>.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p> <p>If you create a custom IAM user policy to control permission to this operation, specify one of the following two virtual actions (or both) instead of the API operation name:</p> <dl> <dt>elasticbeanstalk:AddTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tags to add in the <code>TagsToAdd</code> parameter.</p> </dd> <dt>elasticbeanstalk:RemoveTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tag keys to remove in the <code>TagsToRemove</code> parameter.</p> </dd> </dl> <p>For details about creating a custom user policy, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/AWSHowTo.iam.managed-policies.html#AWSHowTo.iam.policies">Creating a Custom User Policy</a>.</p>
  ## 
  let valid = call_612910.validator(path, query, header, formData, body)
  let scheme = call_612910.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612910.url(scheme.get, call_612910.host, call_612910.base,
                         call_612910.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612910, url, valid)

proc call*(call_612911: Call_GetUpdateTagsForResource_612895; ResourceArn: string;
          TagsToAdd: JsonNode = nil; TagsToRemove: JsonNode = nil;
          Action: string = "UpdateTagsForResource"; Version: string = "2010-12-01"): Recallable =
  ## getUpdateTagsForResource
  ## <p>Update the list of tags applied to an AWS Elastic Beanstalk resource. Two lists can be passed: <code>TagsToAdd</code> for tags to add or update, and <code>TagsToRemove</code>.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p> <p>If you create a custom IAM user policy to control permission to this operation, specify one of the following two virtual actions (or both) instead of the API operation name:</p> <dl> <dt>elasticbeanstalk:AddTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tags to add in the <code>TagsToAdd</code> parameter.</p> </dd> <dt>elasticbeanstalk:RemoveTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tag keys to remove in the <code>TagsToRemove</code> parameter.</p> </dd> </dl> <p>For details about creating a custom user policy, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/AWSHowTo.iam.managed-policies.html#AWSHowTo.iam.policies">Creating a Custom User Policy</a>.</p>
  ##   TagsToAdd: JArray
  ##            : <p>A list of tags to add or update.</p> <p>If a key of an existing tag is added, the tag's value is updated.</p>
  ##   TagsToRemove: JArray
  ##               : <p>A list of tag keys to remove.</p> <p>If a tag key doesn't exist, it is silently ignored.</p>
  ##   ResourceArn: string (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce to be updated.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612912 = newJObject()
  if TagsToAdd != nil:
    query_612912.add "TagsToAdd", TagsToAdd
  if TagsToRemove != nil:
    query_612912.add "TagsToRemove", TagsToRemove
  add(query_612912, "ResourceArn", newJString(ResourceArn))
  add(query_612912, "Action", newJString(Action))
  add(query_612912, "Version", newJString(Version))
  result = call_612911.call(nil, query_612912, nil, nil, nil)

var getUpdateTagsForResource* = Call_GetUpdateTagsForResource_612895(
    name: "getUpdateTagsForResource", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateTagsForResource",
    validator: validate_GetUpdateTagsForResource_612896, base: "/",
    url: url_GetUpdateTagsForResource_612897, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostValidateConfigurationSettings_612951 = ref object of OpenApiRestCall_610659
proc url_PostValidateConfigurationSettings_612953(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostValidateConfigurationSettings_612952(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Takes a set of configuration settings and either a configuration template or environment, and determines whether those values are valid.</p> <p>This action returns a list of messages indicating any errors or warnings associated with the selection of option values.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_612954 = query.getOrDefault("Action")
  valid_612954 = validateParameter(valid_612954, JString, required = true, default = newJString(
      "ValidateConfigurationSettings"))
  if valid_612954 != nil:
    section.add "Action", valid_612954
  var valid_612955 = query.getOrDefault("Version")
  valid_612955 = validateParameter(valid_612955, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612955 != nil:
    section.add "Version", valid_612955
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612956 = header.getOrDefault("X-Amz-Signature")
  valid_612956 = validateParameter(valid_612956, JString, required = false,
                                 default = nil)
  if valid_612956 != nil:
    section.add "X-Amz-Signature", valid_612956
  var valid_612957 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612957 = validateParameter(valid_612957, JString, required = false,
                                 default = nil)
  if valid_612957 != nil:
    section.add "X-Amz-Content-Sha256", valid_612957
  var valid_612958 = header.getOrDefault("X-Amz-Date")
  valid_612958 = validateParameter(valid_612958, JString, required = false,
                                 default = nil)
  if valid_612958 != nil:
    section.add "X-Amz-Date", valid_612958
  var valid_612959 = header.getOrDefault("X-Amz-Credential")
  valid_612959 = validateParameter(valid_612959, JString, required = false,
                                 default = nil)
  if valid_612959 != nil:
    section.add "X-Amz-Credential", valid_612959
  var valid_612960 = header.getOrDefault("X-Amz-Security-Token")
  valid_612960 = validateParameter(valid_612960, JString, required = false,
                                 default = nil)
  if valid_612960 != nil:
    section.add "X-Amz-Security-Token", valid_612960
  var valid_612961 = header.getOrDefault("X-Amz-Algorithm")
  valid_612961 = validateParameter(valid_612961, JString, required = false,
                                 default = nil)
  if valid_612961 != nil:
    section.add "X-Amz-Algorithm", valid_612961
  var valid_612962 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612962 = validateParameter(valid_612962, JString, required = false,
                                 default = nil)
  if valid_612962 != nil:
    section.add "X-Amz-SignedHeaders", valid_612962
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to validate the settings against.</p> <p>Condition: You cannot specify both this and a configuration template name.</p>
  ##   TemplateName: JString
  ##               : <p>The name of the configuration template to validate the settings against.</p> <p>Condition: You cannot specify both this and an environment name.</p>
  ##   OptionSettings: JArray (required)
  ##                 : A list of the options and desired values to evaluate.
  ##   ApplicationName: JString (required)
  ##                  : The name of the application that the configuration template or environment belongs to.
  section = newJObject()
  var valid_612963 = formData.getOrDefault("EnvironmentName")
  valid_612963 = validateParameter(valid_612963, JString, required = false,
                                 default = nil)
  if valid_612963 != nil:
    section.add "EnvironmentName", valid_612963
  var valid_612964 = formData.getOrDefault("TemplateName")
  valid_612964 = validateParameter(valid_612964, JString, required = false,
                                 default = nil)
  if valid_612964 != nil:
    section.add "TemplateName", valid_612964
  assert formData != nil,
        "formData argument is necessary due to required `OptionSettings` field"
  var valid_612965 = formData.getOrDefault("OptionSettings")
  valid_612965 = validateParameter(valid_612965, JArray, required = true, default = nil)
  if valid_612965 != nil:
    section.add "OptionSettings", valid_612965
  var valid_612966 = formData.getOrDefault("ApplicationName")
  valid_612966 = validateParameter(valid_612966, JString, required = true,
                                 default = nil)
  if valid_612966 != nil:
    section.add "ApplicationName", valid_612966
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612967: Call_PostValidateConfigurationSettings_612951;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Takes a set of configuration settings and either a configuration template or environment, and determines whether those values are valid.</p> <p>This action returns a list of messages indicating any errors or warnings associated with the selection of option values.</p>
  ## 
  let valid = call_612967.validator(path, query, header, formData, body)
  let scheme = call_612967.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612967.url(scheme.get, call_612967.host, call_612967.base,
                         call_612967.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612967, url, valid)

proc call*(call_612968: Call_PostValidateConfigurationSettings_612951;
          OptionSettings: JsonNode; ApplicationName: string;
          EnvironmentName: string = ""; TemplateName: string = "";
          Action: string = "ValidateConfigurationSettings";
          Version: string = "2010-12-01"): Recallable =
  ## postValidateConfigurationSettings
  ## <p>Takes a set of configuration settings and either a configuration template or environment, and determines whether those values are valid.</p> <p>This action returns a list of messages indicating any errors or warnings associated with the selection of option values.</p>
  ##   EnvironmentName: string
  ##                  : <p>The name of the environment to validate the settings against.</p> <p>Condition: You cannot specify both this and a configuration template name.</p>
  ##   TemplateName: string
  ##               : <p>The name of the configuration template to validate the settings against.</p> <p>Condition: You cannot specify both this and an environment name.</p>
  ##   OptionSettings: JArray (required)
  ##                 : A list of the options and desired values to evaluate.
  ##   ApplicationName: string (required)
  ##                  : The name of the application that the configuration template or environment belongs to.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_612969 = newJObject()
  var formData_612970 = newJObject()
  add(formData_612970, "EnvironmentName", newJString(EnvironmentName))
  add(formData_612970, "TemplateName", newJString(TemplateName))
  if OptionSettings != nil:
    formData_612970.add "OptionSettings", OptionSettings
  add(formData_612970, "ApplicationName", newJString(ApplicationName))
  add(query_612969, "Action", newJString(Action))
  add(query_612969, "Version", newJString(Version))
  result = call_612968.call(nil, query_612969, nil, formData_612970, nil)

var postValidateConfigurationSettings* = Call_PostValidateConfigurationSettings_612951(
    name: "postValidateConfigurationSettings", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ValidateConfigurationSettings",
    validator: validate_PostValidateConfigurationSettings_612952, base: "/",
    url: url_PostValidateConfigurationSettings_612953,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetValidateConfigurationSettings_612932 = ref object of OpenApiRestCall_610659
proc url_GetValidateConfigurationSettings_612934(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetValidateConfigurationSettings_612933(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Takes a set of configuration settings and either a configuration template or environment, and determines whether those values are valid.</p> <p>This action returns a list of messages indicating any errors or warnings associated with the selection of option values.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ApplicationName: JString (required)
  ##                  : The name of the application that the configuration template or environment belongs to.
  ##   OptionSettings: JArray (required)
  ##                 : A list of the options and desired values to evaluate.
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to validate the settings against.</p> <p>Condition: You cannot specify both this and a configuration template name.</p>
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   TemplateName: JString
  ##               : <p>The name of the configuration template to validate the settings against.</p> <p>Condition: You cannot specify both this and an environment name.</p>
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_612935 = query.getOrDefault("ApplicationName")
  valid_612935 = validateParameter(valid_612935, JString, required = true,
                                 default = nil)
  if valid_612935 != nil:
    section.add "ApplicationName", valid_612935
  var valid_612936 = query.getOrDefault("OptionSettings")
  valid_612936 = validateParameter(valid_612936, JArray, required = true, default = nil)
  if valid_612936 != nil:
    section.add "OptionSettings", valid_612936
  var valid_612937 = query.getOrDefault("EnvironmentName")
  valid_612937 = validateParameter(valid_612937, JString, required = false,
                                 default = nil)
  if valid_612937 != nil:
    section.add "EnvironmentName", valid_612937
  var valid_612938 = query.getOrDefault("Action")
  valid_612938 = validateParameter(valid_612938, JString, required = true, default = newJString(
      "ValidateConfigurationSettings"))
  if valid_612938 != nil:
    section.add "Action", valid_612938
  var valid_612939 = query.getOrDefault("Version")
  valid_612939 = validateParameter(valid_612939, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_612939 != nil:
    section.add "Version", valid_612939
  var valid_612940 = query.getOrDefault("TemplateName")
  valid_612940 = validateParameter(valid_612940, JString, required = false,
                                 default = nil)
  if valid_612940 != nil:
    section.add "TemplateName", valid_612940
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612941 = header.getOrDefault("X-Amz-Signature")
  valid_612941 = validateParameter(valid_612941, JString, required = false,
                                 default = nil)
  if valid_612941 != nil:
    section.add "X-Amz-Signature", valid_612941
  var valid_612942 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612942 = validateParameter(valid_612942, JString, required = false,
                                 default = nil)
  if valid_612942 != nil:
    section.add "X-Amz-Content-Sha256", valid_612942
  var valid_612943 = header.getOrDefault("X-Amz-Date")
  valid_612943 = validateParameter(valid_612943, JString, required = false,
                                 default = nil)
  if valid_612943 != nil:
    section.add "X-Amz-Date", valid_612943
  var valid_612944 = header.getOrDefault("X-Amz-Credential")
  valid_612944 = validateParameter(valid_612944, JString, required = false,
                                 default = nil)
  if valid_612944 != nil:
    section.add "X-Amz-Credential", valid_612944
  var valid_612945 = header.getOrDefault("X-Amz-Security-Token")
  valid_612945 = validateParameter(valid_612945, JString, required = false,
                                 default = nil)
  if valid_612945 != nil:
    section.add "X-Amz-Security-Token", valid_612945
  var valid_612946 = header.getOrDefault("X-Amz-Algorithm")
  valid_612946 = validateParameter(valid_612946, JString, required = false,
                                 default = nil)
  if valid_612946 != nil:
    section.add "X-Amz-Algorithm", valid_612946
  var valid_612947 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612947 = validateParameter(valid_612947, JString, required = false,
                                 default = nil)
  if valid_612947 != nil:
    section.add "X-Amz-SignedHeaders", valid_612947
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612948: Call_GetValidateConfigurationSettings_612932;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Takes a set of configuration settings and either a configuration template or environment, and determines whether those values are valid.</p> <p>This action returns a list of messages indicating any errors or warnings associated with the selection of option values.</p>
  ## 
  let valid = call_612948.validator(path, query, header, formData, body)
  let scheme = call_612948.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612948.url(scheme.get, call_612948.host, call_612948.base,
                         call_612948.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612948, url, valid)

proc call*(call_612949: Call_GetValidateConfigurationSettings_612932;
          ApplicationName: string; OptionSettings: JsonNode;
          EnvironmentName: string = "";
          Action: string = "ValidateConfigurationSettings";
          Version: string = "2010-12-01"; TemplateName: string = ""): Recallable =
  ## getValidateConfigurationSettings
  ## <p>Takes a set of configuration settings and either a configuration template or environment, and determines whether those values are valid.</p> <p>This action returns a list of messages indicating any errors or warnings associated with the selection of option values.</p>
  ##   ApplicationName: string (required)
  ##                  : The name of the application that the configuration template or environment belongs to.
  ##   OptionSettings: JArray (required)
  ##                 : A list of the options and desired values to evaluate.
  ##   EnvironmentName: string
  ##                  : <p>The name of the environment to validate the settings against.</p> <p>Condition: You cannot specify both this and a configuration template name.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  ##   TemplateName: string
  ##               : <p>The name of the configuration template to validate the settings against.</p> <p>Condition: You cannot specify both this and an environment name.</p>
  var query_612950 = newJObject()
  add(query_612950, "ApplicationName", newJString(ApplicationName))
  if OptionSettings != nil:
    query_612950.add "OptionSettings", OptionSettings
  add(query_612950, "EnvironmentName", newJString(EnvironmentName))
  add(query_612950, "Action", newJString(Action))
  add(query_612950, "Version", newJString(Version))
  add(query_612950, "TemplateName", newJString(TemplateName))
  result = call_612949.call(nil, query_612950, nil, nil, nil)

var getValidateConfigurationSettings* = Call_GetValidateConfigurationSettings_612932(
    name: "getValidateConfigurationSettings", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ValidateConfigurationSettings",
    validator: validate_GetValidateConfigurationSettings_612933, base: "/",
    url: url_GetValidateConfigurationSettings_612934,
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

type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  headers[$ContentSha256] = hash(text, SHA256)
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

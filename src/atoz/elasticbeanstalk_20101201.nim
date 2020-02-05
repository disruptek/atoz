
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

  OpenApiRestCall_612659 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612659](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612659): Option[Scheme] {.used.} =
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
  Call_PostAbortEnvironmentUpdate_613269 = ref object of OpenApiRestCall_612659
proc url_PostAbortEnvironmentUpdate_613271(protocol: Scheme; host: string;
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

proc validate_PostAbortEnvironmentUpdate_613270(path: JsonNode; query: JsonNode;
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
  var valid_613272 = query.getOrDefault("Action")
  valid_613272 = validateParameter(valid_613272, JString, required = true,
                                 default = newJString("AbortEnvironmentUpdate"))
  if valid_613272 != nil:
    section.add "Action", valid_613272
  var valid_613273 = query.getOrDefault("Version")
  valid_613273 = validateParameter(valid_613273, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_613273 != nil:
    section.add "Version", valid_613273
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
  var valid_613274 = header.getOrDefault("X-Amz-Signature")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-Signature", valid_613274
  var valid_613275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-Content-Sha256", valid_613275
  var valid_613276 = header.getOrDefault("X-Amz-Date")
  valid_613276 = validateParameter(valid_613276, JString, required = false,
                                 default = nil)
  if valid_613276 != nil:
    section.add "X-Amz-Date", valid_613276
  var valid_613277 = header.getOrDefault("X-Amz-Credential")
  valid_613277 = validateParameter(valid_613277, JString, required = false,
                                 default = nil)
  if valid_613277 != nil:
    section.add "X-Amz-Credential", valid_613277
  var valid_613278 = header.getOrDefault("X-Amz-Security-Token")
  valid_613278 = validateParameter(valid_613278, JString, required = false,
                                 default = nil)
  if valid_613278 != nil:
    section.add "X-Amz-Security-Token", valid_613278
  var valid_613279 = header.getOrDefault("X-Amz-Algorithm")
  valid_613279 = validateParameter(valid_613279, JString, required = false,
                                 default = nil)
  if valid_613279 != nil:
    section.add "X-Amz-Algorithm", valid_613279
  var valid_613280 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613280 = validateParameter(valid_613280, JString, required = false,
                                 default = nil)
  if valid_613280 != nil:
    section.add "X-Amz-SignedHeaders", valid_613280
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString
  ##                  : This specifies the name of the environment with the in-progress update that you want to cancel.
  ##   EnvironmentId: JString
  ##                : This specifies the ID of the environment with the in-progress update that you want to cancel.
  section = newJObject()
  var valid_613281 = formData.getOrDefault("EnvironmentName")
  valid_613281 = validateParameter(valid_613281, JString, required = false,
                                 default = nil)
  if valid_613281 != nil:
    section.add "EnvironmentName", valid_613281
  var valid_613282 = formData.getOrDefault("EnvironmentId")
  valid_613282 = validateParameter(valid_613282, JString, required = false,
                                 default = nil)
  if valid_613282 != nil:
    section.add "EnvironmentId", valid_613282
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613283: Call_PostAbortEnvironmentUpdate_613269; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels in-progress environment configuration update or application version deployment.
  ## 
  let valid = call_613283.validator(path, query, header, formData, body)
  let scheme = call_613283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613283.url(scheme.get, call_613283.host, call_613283.base,
                         call_613283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613283, url, valid)

proc call*(call_613284: Call_PostAbortEnvironmentUpdate_613269;
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
  var query_613285 = newJObject()
  var formData_613286 = newJObject()
  add(formData_613286, "EnvironmentName", newJString(EnvironmentName))
  add(query_613285, "Action", newJString(Action))
  add(formData_613286, "EnvironmentId", newJString(EnvironmentId))
  add(query_613285, "Version", newJString(Version))
  result = call_613284.call(nil, query_613285, nil, formData_613286, nil)

var postAbortEnvironmentUpdate* = Call_PostAbortEnvironmentUpdate_613269(
    name: "postAbortEnvironmentUpdate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=AbortEnvironmentUpdate",
    validator: validate_PostAbortEnvironmentUpdate_613270, base: "/",
    url: url_PostAbortEnvironmentUpdate_613271,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAbortEnvironmentUpdate_612997 = ref object of OpenApiRestCall_612659
proc url_GetAbortEnvironmentUpdate_612999(protocol: Scheme; host: string;
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

proc validate_GetAbortEnvironmentUpdate_612998(path: JsonNode; query: JsonNode;
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
  var valid_613111 = query.getOrDefault("EnvironmentName")
  valid_613111 = validateParameter(valid_613111, JString, required = false,
                                 default = nil)
  if valid_613111 != nil:
    section.add "EnvironmentName", valid_613111
  var valid_613125 = query.getOrDefault("Action")
  valid_613125 = validateParameter(valid_613125, JString, required = true,
                                 default = newJString("AbortEnvironmentUpdate"))
  if valid_613125 != nil:
    section.add "Action", valid_613125
  var valid_613126 = query.getOrDefault("Version")
  valid_613126 = validateParameter(valid_613126, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_613126 != nil:
    section.add "Version", valid_613126
  var valid_613127 = query.getOrDefault("EnvironmentId")
  valid_613127 = validateParameter(valid_613127, JString, required = false,
                                 default = nil)
  if valid_613127 != nil:
    section.add "EnvironmentId", valid_613127
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
  var valid_613128 = header.getOrDefault("X-Amz-Signature")
  valid_613128 = validateParameter(valid_613128, JString, required = false,
                                 default = nil)
  if valid_613128 != nil:
    section.add "X-Amz-Signature", valid_613128
  var valid_613129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613129 = validateParameter(valid_613129, JString, required = false,
                                 default = nil)
  if valid_613129 != nil:
    section.add "X-Amz-Content-Sha256", valid_613129
  var valid_613130 = header.getOrDefault("X-Amz-Date")
  valid_613130 = validateParameter(valid_613130, JString, required = false,
                                 default = nil)
  if valid_613130 != nil:
    section.add "X-Amz-Date", valid_613130
  var valid_613131 = header.getOrDefault("X-Amz-Credential")
  valid_613131 = validateParameter(valid_613131, JString, required = false,
                                 default = nil)
  if valid_613131 != nil:
    section.add "X-Amz-Credential", valid_613131
  var valid_613132 = header.getOrDefault("X-Amz-Security-Token")
  valid_613132 = validateParameter(valid_613132, JString, required = false,
                                 default = nil)
  if valid_613132 != nil:
    section.add "X-Amz-Security-Token", valid_613132
  var valid_613133 = header.getOrDefault("X-Amz-Algorithm")
  valid_613133 = validateParameter(valid_613133, JString, required = false,
                                 default = nil)
  if valid_613133 != nil:
    section.add "X-Amz-Algorithm", valid_613133
  var valid_613134 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613134 = validateParameter(valid_613134, JString, required = false,
                                 default = nil)
  if valid_613134 != nil:
    section.add "X-Amz-SignedHeaders", valid_613134
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613157: Call_GetAbortEnvironmentUpdate_612997; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels in-progress environment configuration update or application version deployment.
  ## 
  let valid = call_613157.validator(path, query, header, formData, body)
  let scheme = call_613157.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613157.url(scheme.get, call_613157.host, call_613157.base,
                         call_613157.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613157, url, valid)

proc call*(call_613228: Call_GetAbortEnvironmentUpdate_612997;
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
  var query_613229 = newJObject()
  add(query_613229, "EnvironmentName", newJString(EnvironmentName))
  add(query_613229, "Action", newJString(Action))
  add(query_613229, "Version", newJString(Version))
  add(query_613229, "EnvironmentId", newJString(EnvironmentId))
  result = call_613228.call(nil, query_613229, nil, nil, nil)

var getAbortEnvironmentUpdate* = Call_GetAbortEnvironmentUpdate_612997(
    name: "getAbortEnvironmentUpdate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=AbortEnvironmentUpdate",
    validator: validate_GetAbortEnvironmentUpdate_612998, base: "/",
    url: url_GetAbortEnvironmentUpdate_612999,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostApplyEnvironmentManagedAction_613305 = ref object of OpenApiRestCall_612659
proc url_PostApplyEnvironmentManagedAction_613307(protocol: Scheme; host: string;
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

proc validate_PostApplyEnvironmentManagedAction_613306(path: JsonNode;
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
  var valid_613308 = query.getOrDefault("Action")
  valid_613308 = validateParameter(valid_613308, JString, required = true, default = newJString(
      "ApplyEnvironmentManagedAction"))
  if valid_613308 != nil:
    section.add "Action", valid_613308
  var valid_613309 = query.getOrDefault("Version")
  valid_613309 = validateParameter(valid_613309, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_613309 != nil:
    section.add "Version", valid_613309
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
  var valid_613310 = header.getOrDefault("X-Amz-Signature")
  valid_613310 = validateParameter(valid_613310, JString, required = false,
                                 default = nil)
  if valid_613310 != nil:
    section.add "X-Amz-Signature", valid_613310
  var valid_613311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613311 = validateParameter(valid_613311, JString, required = false,
                                 default = nil)
  if valid_613311 != nil:
    section.add "X-Amz-Content-Sha256", valid_613311
  var valid_613312 = header.getOrDefault("X-Amz-Date")
  valid_613312 = validateParameter(valid_613312, JString, required = false,
                                 default = nil)
  if valid_613312 != nil:
    section.add "X-Amz-Date", valid_613312
  var valid_613313 = header.getOrDefault("X-Amz-Credential")
  valid_613313 = validateParameter(valid_613313, JString, required = false,
                                 default = nil)
  if valid_613313 != nil:
    section.add "X-Amz-Credential", valid_613313
  var valid_613314 = header.getOrDefault("X-Amz-Security-Token")
  valid_613314 = validateParameter(valid_613314, JString, required = false,
                                 default = nil)
  if valid_613314 != nil:
    section.add "X-Amz-Security-Token", valid_613314
  var valid_613315 = header.getOrDefault("X-Amz-Algorithm")
  valid_613315 = validateParameter(valid_613315, JString, required = false,
                                 default = nil)
  if valid_613315 != nil:
    section.add "X-Amz-Algorithm", valid_613315
  var valid_613316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613316 = validateParameter(valid_613316, JString, required = false,
                                 default = nil)
  if valid_613316 != nil:
    section.add "X-Amz-SignedHeaders", valid_613316
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
  var valid_613317 = formData.getOrDefault("ActionId")
  valid_613317 = validateParameter(valid_613317, JString, required = true,
                                 default = nil)
  if valid_613317 != nil:
    section.add "ActionId", valid_613317
  var valid_613318 = formData.getOrDefault("EnvironmentName")
  valid_613318 = validateParameter(valid_613318, JString, required = false,
                                 default = nil)
  if valid_613318 != nil:
    section.add "EnvironmentName", valid_613318
  var valid_613319 = formData.getOrDefault("EnvironmentId")
  valid_613319 = validateParameter(valid_613319, JString, required = false,
                                 default = nil)
  if valid_613319 != nil:
    section.add "EnvironmentId", valid_613319
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613320: Call_PostApplyEnvironmentManagedAction_613305;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Applies a scheduled managed action immediately. A managed action can be applied only if its status is <code>Scheduled</code>. Get the status and action ID of a managed action with <a>DescribeEnvironmentManagedActions</a>.
  ## 
  let valid = call_613320.validator(path, query, header, formData, body)
  let scheme = call_613320.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613320.url(scheme.get, call_613320.host, call_613320.base,
                         call_613320.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613320, url, valid)

proc call*(call_613321: Call_PostApplyEnvironmentManagedAction_613305;
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
  var query_613322 = newJObject()
  var formData_613323 = newJObject()
  add(formData_613323, "ActionId", newJString(ActionId))
  add(formData_613323, "EnvironmentName", newJString(EnvironmentName))
  add(query_613322, "Action", newJString(Action))
  add(formData_613323, "EnvironmentId", newJString(EnvironmentId))
  add(query_613322, "Version", newJString(Version))
  result = call_613321.call(nil, query_613322, nil, formData_613323, nil)

var postApplyEnvironmentManagedAction* = Call_PostApplyEnvironmentManagedAction_613305(
    name: "postApplyEnvironmentManagedAction", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ApplyEnvironmentManagedAction",
    validator: validate_PostApplyEnvironmentManagedAction_613306, base: "/",
    url: url_PostApplyEnvironmentManagedAction_613307,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplyEnvironmentManagedAction_613287 = ref object of OpenApiRestCall_612659
proc url_GetApplyEnvironmentManagedAction_613289(protocol: Scheme; host: string;
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

proc validate_GetApplyEnvironmentManagedAction_613288(path: JsonNode;
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
  var valid_613290 = query.getOrDefault("ActionId")
  valid_613290 = validateParameter(valid_613290, JString, required = true,
                                 default = nil)
  if valid_613290 != nil:
    section.add "ActionId", valid_613290
  var valid_613291 = query.getOrDefault("EnvironmentName")
  valid_613291 = validateParameter(valid_613291, JString, required = false,
                                 default = nil)
  if valid_613291 != nil:
    section.add "EnvironmentName", valid_613291
  var valid_613292 = query.getOrDefault("Action")
  valid_613292 = validateParameter(valid_613292, JString, required = true, default = newJString(
      "ApplyEnvironmentManagedAction"))
  if valid_613292 != nil:
    section.add "Action", valid_613292
  var valid_613293 = query.getOrDefault("Version")
  valid_613293 = validateParameter(valid_613293, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_613293 != nil:
    section.add "Version", valid_613293
  var valid_613294 = query.getOrDefault("EnvironmentId")
  valid_613294 = validateParameter(valid_613294, JString, required = false,
                                 default = nil)
  if valid_613294 != nil:
    section.add "EnvironmentId", valid_613294
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
  var valid_613295 = header.getOrDefault("X-Amz-Signature")
  valid_613295 = validateParameter(valid_613295, JString, required = false,
                                 default = nil)
  if valid_613295 != nil:
    section.add "X-Amz-Signature", valid_613295
  var valid_613296 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613296 = validateParameter(valid_613296, JString, required = false,
                                 default = nil)
  if valid_613296 != nil:
    section.add "X-Amz-Content-Sha256", valid_613296
  var valid_613297 = header.getOrDefault("X-Amz-Date")
  valid_613297 = validateParameter(valid_613297, JString, required = false,
                                 default = nil)
  if valid_613297 != nil:
    section.add "X-Amz-Date", valid_613297
  var valid_613298 = header.getOrDefault("X-Amz-Credential")
  valid_613298 = validateParameter(valid_613298, JString, required = false,
                                 default = nil)
  if valid_613298 != nil:
    section.add "X-Amz-Credential", valid_613298
  var valid_613299 = header.getOrDefault("X-Amz-Security-Token")
  valid_613299 = validateParameter(valid_613299, JString, required = false,
                                 default = nil)
  if valid_613299 != nil:
    section.add "X-Amz-Security-Token", valid_613299
  var valid_613300 = header.getOrDefault("X-Amz-Algorithm")
  valid_613300 = validateParameter(valid_613300, JString, required = false,
                                 default = nil)
  if valid_613300 != nil:
    section.add "X-Amz-Algorithm", valid_613300
  var valid_613301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613301 = validateParameter(valid_613301, JString, required = false,
                                 default = nil)
  if valid_613301 != nil:
    section.add "X-Amz-SignedHeaders", valid_613301
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613302: Call_GetApplyEnvironmentManagedAction_613287;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Applies a scheduled managed action immediately. A managed action can be applied only if its status is <code>Scheduled</code>. Get the status and action ID of a managed action with <a>DescribeEnvironmentManagedActions</a>.
  ## 
  let valid = call_613302.validator(path, query, header, formData, body)
  let scheme = call_613302.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613302.url(scheme.get, call_613302.host, call_613302.base,
                         call_613302.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613302, url, valid)

proc call*(call_613303: Call_GetApplyEnvironmentManagedAction_613287;
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
  var query_613304 = newJObject()
  add(query_613304, "ActionId", newJString(ActionId))
  add(query_613304, "EnvironmentName", newJString(EnvironmentName))
  add(query_613304, "Action", newJString(Action))
  add(query_613304, "Version", newJString(Version))
  add(query_613304, "EnvironmentId", newJString(EnvironmentId))
  result = call_613303.call(nil, query_613304, nil, nil, nil)

var getApplyEnvironmentManagedAction* = Call_GetApplyEnvironmentManagedAction_613287(
    name: "getApplyEnvironmentManagedAction", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ApplyEnvironmentManagedAction",
    validator: validate_GetApplyEnvironmentManagedAction_613288, base: "/",
    url: url_GetApplyEnvironmentManagedAction_613289,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCheckDNSAvailability_613340 = ref object of OpenApiRestCall_612659
proc url_PostCheckDNSAvailability_613342(protocol: Scheme; host: string;
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

proc validate_PostCheckDNSAvailability_613341(path: JsonNode; query: JsonNode;
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
  var valid_613343 = query.getOrDefault("Action")
  valid_613343 = validateParameter(valid_613343, JString, required = true,
                                 default = newJString("CheckDNSAvailability"))
  if valid_613343 != nil:
    section.add "Action", valid_613343
  var valid_613344 = query.getOrDefault("Version")
  valid_613344 = validateParameter(valid_613344, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_613344 != nil:
    section.add "Version", valid_613344
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
  var valid_613345 = header.getOrDefault("X-Amz-Signature")
  valid_613345 = validateParameter(valid_613345, JString, required = false,
                                 default = nil)
  if valid_613345 != nil:
    section.add "X-Amz-Signature", valid_613345
  var valid_613346 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613346 = validateParameter(valid_613346, JString, required = false,
                                 default = nil)
  if valid_613346 != nil:
    section.add "X-Amz-Content-Sha256", valid_613346
  var valid_613347 = header.getOrDefault("X-Amz-Date")
  valid_613347 = validateParameter(valid_613347, JString, required = false,
                                 default = nil)
  if valid_613347 != nil:
    section.add "X-Amz-Date", valid_613347
  var valid_613348 = header.getOrDefault("X-Amz-Credential")
  valid_613348 = validateParameter(valid_613348, JString, required = false,
                                 default = nil)
  if valid_613348 != nil:
    section.add "X-Amz-Credential", valid_613348
  var valid_613349 = header.getOrDefault("X-Amz-Security-Token")
  valid_613349 = validateParameter(valid_613349, JString, required = false,
                                 default = nil)
  if valid_613349 != nil:
    section.add "X-Amz-Security-Token", valid_613349
  var valid_613350 = header.getOrDefault("X-Amz-Algorithm")
  valid_613350 = validateParameter(valid_613350, JString, required = false,
                                 default = nil)
  if valid_613350 != nil:
    section.add "X-Amz-Algorithm", valid_613350
  var valid_613351 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613351 = validateParameter(valid_613351, JString, required = false,
                                 default = nil)
  if valid_613351 != nil:
    section.add "X-Amz-SignedHeaders", valid_613351
  result.add "header", section
  ## parameters in `formData` object:
  ##   CNAMEPrefix: JString (required)
  ##              : The prefix used when this CNAME is reserved.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `CNAMEPrefix` field"
  var valid_613352 = formData.getOrDefault("CNAMEPrefix")
  valid_613352 = validateParameter(valid_613352, JString, required = true,
                                 default = nil)
  if valid_613352 != nil:
    section.add "CNAMEPrefix", valid_613352
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613353: Call_PostCheckDNSAvailability_613340; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Checks if the specified CNAME is available.
  ## 
  let valid = call_613353.validator(path, query, header, formData, body)
  let scheme = call_613353.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613353.url(scheme.get, call_613353.host, call_613353.base,
                         call_613353.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613353, url, valid)

proc call*(call_613354: Call_PostCheckDNSAvailability_613340; CNAMEPrefix: string;
          Action: string = "CheckDNSAvailability"; Version: string = "2010-12-01"): Recallable =
  ## postCheckDNSAvailability
  ## Checks if the specified CNAME is available.
  ##   CNAMEPrefix: string (required)
  ##              : The prefix used when this CNAME is reserved.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613355 = newJObject()
  var formData_613356 = newJObject()
  add(formData_613356, "CNAMEPrefix", newJString(CNAMEPrefix))
  add(query_613355, "Action", newJString(Action))
  add(query_613355, "Version", newJString(Version))
  result = call_613354.call(nil, query_613355, nil, formData_613356, nil)

var postCheckDNSAvailability* = Call_PostCheckDNSAvailability_613340(
    name: "postCheckDNSAvailability", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CheckDNSAvailability",
    validator: validate_PostCheckDNSAvailability_613341, base: "/",
    url: url_PostCheckDNSAvailability_613342, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCheckDNSAvailability_613324 = ref object of OpenApiRestCall_612659
proc url_GetCheckDNSAvailability_613326(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
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

proc validate_GetCheckDNSAvailability_613325(path: JsonNode; query: JsonNode;
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
  var valid_613327 = query.getOrDefault("CNAMEPrefix")
  valid_613327 = validateParameter(valid_613327, JString, required = true,
                                 default = nil)
  if valid_613327 != nil:
    section.add "CNAMEPrefix", valid_613327
  var valid_613328 = query.getOrDefault("Action")
  valid_613328 = validateParameter(valid_613328, JString, required = true,
                                 default = newJString("CheckDNSAvailability"))
  if valid_613328 != nil:
    section.add "Action", valid_613328
  var valid_613329 = query.getOrDefault("Version")
  valid_613329 = validateParameter(valid_613329, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_613329 != nil:
    section.add "Version", valid_613329
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
  var valid_613330 = header.getOrDefault("X-Amz-Signature")
  valid_613330 = validateParameter(valid_613330, JString, required = false,
                                 default = nil)
  if valid_613330 != nil:
    section.add "X-Amz-Signature", valid_613330
  var valid_613331 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613331 = validateParameter(valid_613331, JString, required = false,
                                 default = nil)
  if valid_613331 != nil:
    section.add "X-Amz-Content-Sha256", valid_613331
  var valid_613332 = header.getOrDefault("X-Amz-Date")
  valid_613332 = validateParameter(valid_613332, JString, required = false,
                                 default = nil)
  if valid_613332 != nil:
    section.add "X-Amz-Date", valid_613332
  var valid_613333 = header.getOrDefault("X-Amz-Credential")
  valid_613333 = validateParameter(valid_613333, JString, required = false,
                                 default = nil)
  if valid_613333 != nil:
    section.add "X-Amz-Credential", valid_613333
  var valid_613334 = header.getOrDefault("X-Amz-Security-Token")
  valid_613334 = validateParameter(valid_613334, JString, required = false,
                                 default = nil)
  if valid_613334 != nil:
    section.add "X-Amz-Security-Token", valid_613334
  var valid_613335 = header.getOrDefault("X-Amz-Algorithm")
  valid_613335 = validateParameter(valid_613335, JString, required = false,
                                 default = nil)
  if valid_613335 != nil:
    section.add "X-Amz-Algorithm", valid_613335
  var valid_613336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613336 = validateParameter(valid_613336, JString, required = false,
                                 default = nil)
  if valid_613336 != nil:
    section.add "X-Amz-SignedHeaders", valid_613336
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613337: Call_GetCheckDNSAvailability_613324; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Checks if the specified CNAME is available.
  ## 
  let valid = call_613337.validator(path, query, header, formData, body)
  let scheme = call_613337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613337.url(scheme.get, call_613337.host, call_613337.base,
                         call_613337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613337, url, valid)

proc call*(call_613338: Call_GetCheckDNSAvailability_613324; CNAMEPrefix: string;
          Action: string = "CheckDNSAvailability"; Version: string = "2010-12-01"): Recallable =
  ## getCheckDNSAvailability
  ## Checks if the specified CNAME is available.
  ##   CNAMEPrefix: string (required)
  ##              : The prefix used when this CNAME is reserved.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613339 = newJObject()
  add(query_613339, "CNAMEPrefix", newJString(CNAMEPrefix))
  add(query_613339, "Action", newJString(Action))
  add(query_613339, "Version", newJString(Version))
  result = call_613338.call(nil, query_613339, nil, nil, nil)

var getCheckDNSAvailability* = Call_GetCheckDNSAvailability_613324(
    name: "getCheckDNSAvailability", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CheckDNSAvailability",
    validator: validate_GetCheckDNSAvailability_613325, base: "/",
    url: url_GetCheckDNSAvailability_613326, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostComposeEnvironments_613375 = ref object of OpenApiRestCall_612659
proc url_PostComposeEnvironments_613377(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
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

proc validate_PostComposeEnvironments_613376(path: JsonNode; query: JsonNode;
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
  var valid_613378 = query.getOrDefault("Action")
  valid_613378 = validateParameter(valid_613378, JString, required = true,
                                 default = newJString("ComposeEnvironments"))
  if valid_613378 != nil:
    section.add "Action", valid_613378
  var valid_613379 = query.getOrDefault("Version")
  valid_613379 = validateParameter(valid_613379, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_613379 != nil:
    section.add "Version", valid_613379
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
  var valid_613380 = header.getOrDefault("X-Amz-Signature")
  valid_613380 = validateParameter(valid_613380, JString, required = false,
                                 default = nil)
  if valid_613380 != nil:
    section.add "X-Amz-Signature", valid_613380
  var valid_613381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613381 = validateParameter(valid_613381, JString, required = false,
                                 default = nil)
  if valid_613381 != nil:
    section.add "X-Amz-Content-Sha256", valid_613381
  var valid_613382 = header.getOrDefault("X-Amz-Date")
  valid_613382 = validateParameter(valid_613382, JString, required = false,
                                 default = nil)
  if valid_613382 != nil:
    section.add "X-Amz-Date", valid_613382
  var valid_613383 = header.getOrDefault("X-Amz-Credential")
  valid_613383 = validateParameter(valid_613383, JString, required = false,
                                 default = nil)
  if valid_613383 != nil:
    section.add "X-Amz-Credential", valid_613383
  var valid_613384 = header.getOrDefault("X-Amz-Security-Token")
  valid_613384 = validateParameter(valid_613384, JString, required = false,
                                 default = nil)
  if valid_613384 != nil:
    section.add "X-Amz-Security-Token", valid_613384
  var valid_613385 = header.getOrDefault("X-Amz-Algorithm")
  valid_613385 = validateParameter(valid_613385, JString, required = false,
                                 default = nil)
  if valid_613385 != nil:
    section.add "X-Amz-Algorithm", valid_613385
  var valid_613386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613386 = validateParameter(valid_613386, JString, required = false,
                                 default = nil)
  if valid_613386 != nil:
    section.add "X-Amz-SignedHeaders", valid_613386
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
  var valid_613387 = formData.getOrDefault("GroupName")
  valid_613387 = validateParameter(valid_613387, JString, required = false,
                                 default = nil)
  if valid_613387 != nil:
    section.add "GroupName", valid_613387
  var valid_613388 = formData.getOrDefault("ApplicationName")
  valid_613388 = validateParameter(valid_613388, JString, required = false,
                                 default = nil)
  if valid_613388 != nil:
    section.add "ApplicationName", valid_613388
  var valid_613389 = formData.getOrDefault("VersionLabels")
  valid_613389 = validateParameter(valid_613389, JArray, required = false,
                                 default = nil)
  if valid_613389 != nil:
    section.add "VersionLabels", valid_613389
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613390: Call_PostComposeEnvironments_613375; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create or update a group of environments that each run a separate component of a single application. Takes a list of version labels that specify application source bundles for each of the environments to create or update. The name of each environment and other required information must be included in the source bundles in an environment manifest named <code>env.yaml</code>. See <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-mgmt-compose.html">Compose Environments</a> for details.
  ## 
  let valid = call_613390.validator(path, query, header, formData, body)
  let scheme = call_613390.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613390.url(scheme.get, call_613390.host, call_613390.base,
                         call_613390.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613390, url, valid)

proc call*(call_613391: Call_PostComposeEnvironments_613375;
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
  var query_613392 = newJObject()
  var formData_613393 = newJObject()
  add(formData_613393, "GroupName", newJString(GroupName))
  add(formData_613393, "ApplicationName", newJString(ApplicationName))
  if VersionLabels != nil:
    formData_613393.add "VersionLabels", VersionLabels
  add(query_613392, "Action", newJString(Action))
  add(query_613392, "Version", newJString(Version))
  result = call_613391.call(nil, query_613392, nil, formData_613393, nil)

var postComposeEnvironments* = Call_PostComposeEnvironments_613375(
    name: "postComposeEnvironments", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ComposeEnvironments",
    validator: validate_PostComposeEnvironments_613376, base: "/",
    url: url_PostComposeEnvironments_613377, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetComposeEnvironments_613357 = ref object of OpenApiRestCall_612659
proc url_GetComposeEnvironments_613359(protocol: Scheme; host: string; base: string;
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

proc validate_GetComposeEnvironments_613358(path: JsonNode; query: JsonNode;
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
  var valid_613360 = query.getOrDefault("ApplicationName")
  valid_613360 = validateParameter(valid_613360, JString, required = false,
                                 default = nil)
  if valid_613360 != nil:
    section.add "ApplicationName", valid_613360
  var valid_613361 = query.getOrDefault("GroupName")
  valid_613361 = validateParameter(valid_613361, JString, required = false,
                                 default = nil)
  if valid_613361 != nil:
    section.add "GroupName", valid_613361
  var valid_613362 = query.getOrDefault("VersionLabels")
  valid_613362 = validateParameter(valid_613362, JArray, required = false,
                                 default = nil)
  if valid_613362 != nil:
    section.add "VersionLabels", valid_613362
  var valid_613363 = query.getOrDefault("Action")
  valid_613363 = validateParameter(valid_613363, JString, required = true,
                                 default = newJString("ComposeEnvironments"))
  if valid_613363 != nil:
    section.add "Action", valid_613363
  var valid_613364 = query.getOrDefault("Version")
  valid_613364 = validateParameter(valid_613364, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_613364 != nil:
    section.add "Version", valid_613364
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
  var valid_613365 = header.getOrDefault("X-Amz-Signature")
  valid_613365 = validateParameter(valid_613365, JString, required = false,
                                 default = nil)
  if valid_613365 != nil:
    section.add "X-Amz-Signature", valid_613365
  var valid_613366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613366 = validateParameter(valid_613366, JString, required = false,
                                 default = nil)
  if valid_613366 != nil:
    section.add "X-Amz-Content-Sha256", valid_613366
  var valid_613367 = header.getOrDefault("X-Amz-Date")
  valid_613367 = validateParameter(valid_613367, JString, required = false,
                                 default = nil)
  if valid_613367 != nil:
    section.add "X-Amz-Date", valid_613367
  var valid_613368 = header.getOrDefault("X-Amz-Credential")
  valid_613368 = validateParameter(valid_613368, JString, required = false,
                                 default = nil)
  if valid_613368 != nil:
    section.add "X-Amz-Credential", valid_613368
  var valid_613369 = header.getOrDefault("X-Amz-Security-Token")
  valid_613369 = validateParameter(valid_613369, JString, required = false,
                                 default = nil)
  if valid_613369 != nil:
    section.add "X-Amz-Security-Token", valid_613369
  var valid_613370 = header.getOrDefault("X-Amz-Algorithm")
  valid_613370 = validateParameter(valid_613370, JString, required = false,
                                 default = nil)
  if valid_613370 != nil:
    section.add "X-Amz-Algorithm", valid_613370
  var valid_613371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613371 = validateParameter(valid_613371, JString, required = false,
                                 default = nil)
  if valid_613371 != nil:
    section.add "X-Amz-SignedHeaders", valid_613371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613372: Call_GetComposeEnvironments_613357; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create or update a group of environments that each run a separate component of a single application. Takes a list of version labels that specify application source bundles for each of the environments to create or update. The name of each environment and other required information must be included in the source bundles in an environment manifest named <code>env.yaml</code>. See <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-mgmt-compose.html">Compose Environments</a> for details.
  ## 
  let valid = call_613372.validator(path, query, header, formData, body)
  let scheme = call_613372.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613372.url(scheme.get, call_613372.host, call_613372.base,
                         call_613372.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613372, url, valid)

proc call*(call_613373: Call_GetComposeEnvironments_613357;
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
  var query_613374 = newJObject()
  add(query_613374, "ApplicationName", newJString(ApplicationName))
  add(query_613374, "GroupName", newJString(GroupName))
  if VersionLabels != nil:
    query_613374.add "VersionLabels", VersionLabels
  add(query_613374, "Action", newJString(Action))
  add(query_613374, "Version", newJString(Version))
  result = call_613373.call(nil, query_613374, nil, nil, nil)

var getComposeEnvironments* = Call_GetComposeEnvironments_613357(
    name: "getComposeEnvironments", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ComposeEnvironments",
    validator: validate_GetComposeEnvironments_613358, base: "/",
    url: url_GetComposeEnvironments_613359, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateApplication_613414 = ref object of OpenApiRestCall_612659
proc url_PostCreateApplication_613416(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateApplication_613415(path: JsonNode; query: JsonNode;
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
  var valid_613417 = query.getOrDefault("Action")
  valid_613417 = validateParameter(valid_613417, JString, required = true,
                                 default = newJString("CreateApplication"))
  if valid_613417 != nil:
    section.add "Action", valid_613417
  var valid_613418 = query.getOrDefault("Version")
  valid_613418 = validateParameter(valid_613418, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_613418 != nil:
    section.add "Version", valid_613418
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
  var valid_613419 = header.getOrDefault("X-Amz-Signature")
  valid_613419 = validateParameter(valid_613419, JString, required = false,
                                 default = nil)
  if valid_613419 != nil:
    section.add "X-Amz-Signature", valid_613419
  var valid_613420 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613420 = validateParameter(valid_613420, JString, required = false,
                                 default = nil)
  if valid_613420 != nil:
    section.add "X-Amz-Content-Sha256", valid_613420
  var valid_613421 = header.getOrDefault("X-Amz-Date")
  valid_613421 = validateParameter(valid_613421, JString, required = false,
                                 default = nil)
  if valid_613421 != nil:
    section.add "X-Amz-Date", valid_613421
  var valid_613422 = header.getOrDefault("X-Amz-Credential")
  valid_613422 = validateParameter(valid_613422, JString, required = false,
                                 default = nil)
  if valid_613422 != nil:
    section.add "X-Amz-Credential", valid_613422
  var valid_613423 = header.getOrDefault("X-Amz-Security-Token")
  valid_613423 = validateParameter(valid_613423, JString, required = false,
                                 default = nil)
  if valid_613423 != nil:
    section.add "X-Amz-Security-Token", valid_613423
  var valid_613424 = header.getOrDefault("X-Amz-Algorithm")
  valid_613424 = validateParameter(valid_613424, JString, required = false,
                                 default = nil)
  if valid_613424 != nil:
    section.add "X-Amz-Algorithm", valid_613424
  var valid_613425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613425 = validateParameter(valid_613425, JString, required = false,
                                 default = nil)
  if valid_613425 != nil:
    section.add "X-Amz-SignedHeaders", valid_613425
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
  var valid_613426 = formData.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_613426 = validateParameter(valid_613426, JString, required = false,
                                 default = nil)
  if valid_613426 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_613426
  var valid_613427 = formData.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_613427 = validateParameter(valid_613427, JString, required = false,
                                 default = nil)
  if valid_613427 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_613427
  var valid_613428 = formData.getOrDefault("Description")
  valid_613428 = validateParameter(valid_613428, JString, required = false,
                                 default = nil)
  if valid_613428 != nil:
    section.add "Description", valid_613428
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_613429 = formData.getOrDefault("ApplicationName")
  valid_613429 = validateParameter(valid_613429, JString, required = true,
                                 default = nil)
  if valid_613429 != nil:
    section.add "ApplicationName", valid_613429
  var valid_613430 = formData.getOrDefault("Tags")
  valid_613430 = validateParameter(valid_613430, JArray, required = false,
                                 default = nil)
  if valid_613430 != nil:
    section.add "Tags", valid_613430
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613431: Call_PostCreateApplication_613414; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates an application that has one configuration template named <code>default</code> and no application versions. 
  ## 
  let valid = call_613431.validator(path, query, header, formData, body)
  let scheme = call_613431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613431.url(scheme.get, call_613431.host, call_613431.base,
                         call_613431.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613431, url, valid)

proc call*(call_613432: Call_PostCreateApplication_613414; ApplicationName: string;
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
  var query_613433 = newJObject()
  var formData_613434 = newJObject()
  add(formData_613434, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  add(formData_613434, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  add(formData_613434, "Description", newJString(Description))
  add(formData_613434, "ApplicationName", newJString(ApplicationName))
  add(query_613433, "Action", newJString(Action))
  if Tags != nil:
    formData_613434.add "Tags", Tags
  add(query_613433, "Version", newJString(Version))
  result = call_613432.call(nil, query_613433, nil, formData_613434, nil)

var postCreateApplication* = Call_PostCreateApplication_613414(
    name: "postCreateApplication", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateApplication",
    validator: validate_PostCreateApplication_613415, base: "/",
    url: url_PostCreateApplication_613416, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateApplication_613394 = ref object of OpenApiRestCall_612659
proc url_GetCreateApplication_613396(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateApplication_613395(path: JsonNode; query: JsonNode;
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
  var valid_613397 = query.getOrDefault("ApplicationName")
  valid_613397 = validateParameter(valid_613397, JString, required = true,
                                 default = nil)
  if valid_613397 != nil:
    section.add "ApplicationName", valid_613397
  var valid_613398 = query.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_613398 = validateParameter(valid_613398, JString, required = false,
                                 default = nil)
  if valid_613398 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_613398
  var valid_613399 = query.getOrDefault("Tags")
  valid_613399 = validateParameter(valid_613399, JArray, required = false,
                                 default = nil)
  if valid_613399 != nil:
    section.add "Tags", valid_613399
  var valid_613400 = query.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_613400 = validateParameter(valid_613400, JString, required = false,
                                 default = nil)
  if valid_613400 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_613400
  var valid_613401 = query.getOrDefault("Action")
  valid_613401 = validateParameter(valid_613401, JString, required = true,
                                 default = newJString("CreateApplication"))
  if valid_613401 != nil:
    section.add "Action", valid_613401
  var valid_613402 = query.getOrDefault("Description")
  valid_613402 = validateParameter(valid_613402, JString, required = false,
                                 default = nil)
  if valid_613402 != nil:
    section.add "Description", valid_613402
  var valid_613403 = query.getOrDefault("Version")
  valid_613403 = validateParameter(valid_613403, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_613403 != nil:
    section.add "Version", valid_613403
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
  var valid_613404 = header.getOrDefault("X-Amz-Signature")
  valid_613404 = validateParameter(valid_613404, JString, required = false,
                                 default = nil)
  if valid_613404 != nil:
    section.add "X-Amz-Signature", valid_613404
  var valid_613405 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613405 = validateParameter(valid_613405, JString, required = false,
                                 default = nil)
  if valid_613405 != nil:
    section.add "X-Amz-Content-Sha256", valid_613405
  var valid_613406 = header.getOrDefault("X-Amz-Date")
  valid_613406 = validateParameter(valid_613406, JString, required = false,
                                 default = nil)
  if valid_613406 != nil:
    section.add "X-Amz-Date", valid_613406
  var valid_613407 = header.getOrDefault("X-Amz-Credential")
  valid_613407 = validateParameter(valid_613407, JString, required = false,
                                 default = nil)
  if valid_613407 != nil:
    section.add "X-Amz-Credential", valid_613407
  var valid_613408 = header.getOrDefault("X-Amz-Security-Token")
  valid_613408 = validateParameter(valid_613408, JString, required = false,
                                 default = nil)
  if valid_613408 != nil:
    section.add "X-Amz-Security-Token", valid_613408
  var valid_613409 = header.getOrDefault("X-Amz-Algorithm")
  valid_613409 = validateParameter(valid_613409, JString, required = false,
                                 default = nil)
  if valid_613409 != nil:
    section.add "X-Amz-Algorithm", valid_613409
  var valid_613410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613410 = validateParameter(valid_613410, JString, required = false,
                                 default = nil)
  if valid_613410 != nil:
    section.add "X-Amz-SignedHeaders", valid_613410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613411: Call_GetCreateApplication_613394; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates an application that has one configuration template named <code>default</code> and no application versions. 
  ## 
  let valid = call_613411.validator(path, query, header, formData, body)
  let scheme = call_613411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613411.url(scheme.get, call_613411.host, call_613411.base,
                         call_613411.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613411, url, valid)

proc call*(call_613412: Call_GetCreateApplication_613394; ApplicationName: string;
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
  var query_613413 = newJObject()
  add(query_613413, "ApplicationName", newJString(ApplicationName))
  add(query_613413, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  if Tags != nil:
    query_613413.add "Tags", Tags
  add(query_613413, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  add(query_613413, "Action", newJString(Action))
  add(query_613413, "Description", newJString(Description))
  add(query_613413, "Version", newJString(Version))
  result = call_613412.call(nil, query_613413, nil, nil, nil)

var getCreateApplication* = Call_GetCreateApplication_613394(
    name: "getCreateApplication", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateApplication",
    validator: validate_GetCreateApplication_613395, base: "/",
    url: url_GetCreateApplication_613396, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateApplicationVersion_613466 = ref object of OpenApiRestCall_612659
proc url_PostCreateApplicationVersion_613468(protocol: Scheme; host: string;
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

proc validate_PostCreateApplicationVersion_613467(path: JsonNode; query: JsonNode;
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
  var valid_613469 = query.getOrDefault("Action")
  valid_613469 = validateParameter(valid_613469, JString, required = true, default = newJString(
      "CreateApplicationVersion"))
  if valid_613469 != nil:
    section.add "Action", valid_613469
  var valid_613470 = query.getOrDefault("Version")
  valid_613470 = validateParameter(valid_613470, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_613470 != nil:
    section.add "Version", valid_613470
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
  var valid_613471 = header.getOrDefault("X-Amz-Signature")
  valid_613471 = validateParameter(valid_613471, JString, required = false,
                                 default = nil)
  if valid_613471 != nil:
    section.add "X-Amz-Signature", valid_613471
  var valid_613472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613472 = validateParameter(valid_613472, JString, required = false,
                                 default = nil)
  if valid_613472 != nil:
    section.add "X-Amz-Content-Sha256", valid_613472
  var valid_613473 = header.getOrDefault("X-Amz-Date")
  valid_613473 = validateParameter(valid_613473, JString, required = false,
                                 default = nil)
  if valid_613473 != nil:
    section.add "X-Amz-Date", valid_613473
  var valid_613474 = header.getOrDefault("X-Amz-Credential")
  valid_613474 = validateParameter(valid_613474, JString, required = false,
                                 default = nil)
  if valid_613474 != nil:
    section.add "X-Amz-Credential", valid_613474
  var valid_613475 = header.getOrDefault("X-Amz-Security-Token")
  valid_613475 = validateParameter(valid_613475, JString, required = false,
                                 default = nil)
  if valid_613475 != nil:
    section.add "X-Amz-Security-Token", valid_613475
  var valid_613476 = header.getOrDefault("X-Amz-Algorithm")
  valid_613476 = validateParameter(valid_613476, JString, required = false,
                                 default = nil)
  if valid_613476 != nil:
    section.add "X-Amz-Algorithm", valid_613476
  var valid_613477 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613477 = validateParameter(valid_613477, JString, required = false,
                                 default = nil)
  if valid_613477 != nil:
    section.add "X-Amz-SignedHeaders", valid_613477
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
  var valid_613478 = formData.getOrDefault("BuildConfiguration.ComputeType")
  valid_613478 = validateParameter(valid_613478, JString, required = false,
                                 default = nil)
  if valid_613478 != nil:
    section.add "BuildConfiguration.ComputeType", valid_613478
  var valid_613479 = formData.getOrDefault("SourceBundle.S3Key")
  valid_613479 = validateParameter(valid_613479, JString, required = false,
                                 default = nil)
  if valid_613479 != nil:
    section.add "SourceBundle.S3Key", valid_613479
  var valid_613480 = formData.getOrDefault("Process")
  valid_613480 = validateParameter(valid_613480, JBool, required = false, default = nil)
  if valid_613480 != nil:
    section.add "Process", valid_613480
  var valid_613481 = formData.getOrDefault("SourceBuildInformation.SourceType")
  valid_613481 = validateParameter(valid_613481, JString, required = false,
                                 default = nil)
  if valid_613481 != nil:
    section.add "SourceBuildInformation.SourceType", valid_613481
  var valid_613482 = formData.getOrDefault("BuildConfiguration.ArtifactName")
  valid_613482 = validateParameter(valid_613482, JString, required = false,
                                 default = nil)
  if valid_613482 != nil:
    section.add "BuildConfiguration.ArtifactName", valid_613482
  var valid_613483 = formData.getOrDefault("Description")
  valid_613483 = validateParameter(valid_613483, JString, required = false,
                                 default = nil)
  if valid_613483 != nil:
    section.add "Description", valid_613483
  assert formData != nil,
        "formData argument is necessary due to required `VersionLabel` field"
  var valid_613484 = formData.getOrDefault("VersionLabel")
  valid_613484 = validateParameter(valid_613484, JString, required = true,
                                 default = nil)
  if valid_613484 != nil:
    section.add "VersionLabel", valid_613484
  var valid_613485 = formData.getOrDefault("SourceBuildInformation.SourceRepository")
  valid_613485 = validateParameter(valid_613485, JString, required = false,
                                 default = nil)
  if valid_613485 != nil:
    section.add "SourceBuildInformation.SourceRepository", valid_613485
  var valid_613486 = formData.getOrDefault("AutoCreateApplication")
  valid_613486 = validateParameter(valid_613486, JBool, required = false, default = nil)
  if valid_613486 != nil:
    section.add "AutoCreateApplication", valid_613486
  var valid_613487 = formData.getOrDefault("SourceBuildInformation.SourceLocation")
  valid_613487 = validateParameter(valid_613487, JString, required = false,
                                 default = nil)
  if valid_613487 != nil:
    section.add "SourceBuildInformation.SourceLocation", valid_613487
  var valid_613488 = formData.getOrDefault("ApplicationName")
  valid_613488 = validateParameter(valid_613488, JString, required = true,
                                 default = nil)
  if valid_613488 != nil:
    section.add "ApplicationName", valid_613488
  var valid_613489 = formData.getOrDefault("BuildConfiguration.Image")
  valid_613489 = validateParameter(valid_613489, JString, required = false,
                                 default = nil)
  if valid_613489 != nil:
    section.add "BuildConfiguration.Image", valid_613489
  var valid_613490 = formData.getOrDefault("BuildConfiguration.TimeoutInMinutes")
  valid_613490 = validateParameter(valid_613490, JString, required = false,
                                 default = nil)
  if valid_613490 != nil:
    section.add "BuildConfiguration.TimeoutInMinutes", valid_613490
  var valid_613491 = formData.getOrDefault("Tags")
  valid_613491 = validateParameter(valid_613491, JArray, required = false,
                                 default = nil)
  if valid_613491 != nil:
    section.add "Tags", valid_613491
  var valid_613492 = formData.getOrDefault("SourceBundle.S3Bucket")
  valid_613492 = validateParameter(valid_613492, JString, required = false,
                                 default = nil)
  if valid_613492 != nil:
    section.add "SourceBundle.S3Bucket", valid_613492
  var valid_613493 = formData.getOrDefault("BuildConfiguration.CodeBuildServiceRole")
  valid_613493 = validateParameter(valid_613493, JString, required = false,
                                 default = nil)
  if valid_613493 != nil:
    section.add "BuildConfiguration.CodeBuildServiceRole", valid_613493
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613494: Call_PostCreateApplicationVersion_613466; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an application version for the specified application. You can create an application version from a source bundle in Amazon S3, a commit in AWS CodeCommit, or the output of an AWS CodeBuild build as follows:</p> <p>Specify a commit in an AWS CodeCommit repository with <code>SourceBuildInformation</code>.</p> <p>Specify a build in an AWS CodeBuild with <code>SourceBuildInformation</code> and <code>BuildConfiguration</code>.</p> <p>Specify a source bundle in S3 with <code>SourceBundle</code> </p> <p>Omit both <code>SourceBuildInformation</code> and <code>SourceBundle</code> to use the default sample application.</p> <note> <p>Once you create an application version with a specified Amazon S3 bucket and key location, you cannot change that Amazon S3 location. If you change the Amazon S3 location, you receive an exception when you attempt to launch an environment from the application version.</p> </note>
  ## 
  let valid = call_613494.validator(path, query, header, formData, body)
  let scheme = call_613494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613494.url(scheme.get, call_613494.host, call_613494.base,
                         call_613494.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613494, url, valid)

proc call*(call_613495: Call_PostCreateApplicationVersion_613466;
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
  var query_613496 = newJObject()
  var formData_613497 = newJObject()
  add(formData_613497, "BuildConfiguration.ComputeType",
      newJString(BuildConfigurationComputeType))
  add(formData_613497, "SourceBundle.S3Key", newJString(SourceBundleS3Key))
  add(formData_613497, "Process", newJBool(Process))
  add(formData_613497, "SourceBuildInformation.SourceType",
      newJString(SourceBuildInformationSourceType))
  add(formData_613497, "BuildConfiguration.ArtifactName",
      newJString(BuildConfigurationArtifactName))
  add(formData_613497, "Description", newJString(Description))
  add(formData_613497, "VersionLabel", newJString(VersionLabel))
  add(formData_613497, "SourceBuildInformation.SourceRepository",
      newJString(SourceBuildInformationSourceRepository))
  add(formData_613497, "AutoCreateApplication", newJBool(AutoCreateApplication))
  add(formData_613497, "SourceBuildInformation.SourceLocation",
      newJString(SourceBuildInformationSourceLocation))
  add(formData_613497, "ApplicationName", newJString(ApplicationName))
  add(query_613496, "Action", newJString(Action))
  add(formData_613497, "BuildConfiguration.Image",
      newJString(BuildConfigurationImage))
  add(formData_613497, "BuildConfiguration.TimeoutInMinutes",
      newJString(BuildConfigurationTimeoutInMinutes))
  if Tags != nil:
    formData_613497.add "Tags", Tags
  add(formData_613497, "SourceBundle.S3Bucket", newJString(SourceBundleS3Bucket))
  add(query_613496, "Version", newJString(Version))
  add(formData_613497, "BuildConfiguration.CodeBuildServiceRole",
      newJString(BuildConfigurationCodeBuildServiceRole))
  result = call_613495.call(nil, query_613496, nil, formData_613497, nil)

var postCreateApplicationVersion* = Call_PostCreateApplicationVersion_613466(
    name: "postCreateApplicationVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateApplicationVersion",
    validator: validate_PostCreateApplicationVersion_613467, base: "/",
    url: url_PostCreateApplicationVersion_613468,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateApplicationVersion_613435 = ref object of OpenApiRestCall_612659
proc url_GetCreateApplicationVersion_613437(protocol: Scheme; host: string;
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

proc validate_GetCreateApplicationVersion_613436(path: JsonNode; query: JsonNode;
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
  var valid_613438 = query.getOrDefault("ApplicationName")
  valid_613438 = validateParameter(valid_613438, JString, required = true,
                                 default = nil)
  if valid_613438 != nil:
    section.add "ApplicationName", valid_613438
  var valid_613439 = query.getOrDefault("BuildConfiguration.TimeoutInMinutes")
  valid_613439 = validateParameter(valid_613439, JString, required = false,
                                 default = nil)
  if valid_613439 != nil:
    section.add "BuildConfiguration.TimeoutInMinutes", valid_613439
  var valid_613440 = query.getOrDefault("Process")
  valid_613440 = validateParameter(valid_613440, JBool, required = false, default = nil)
  if valid_613440 != nil:
    section.add "Process", valid_613440
  var valid_613441 = query.getOrDefault("SourceBuildInformation.SourceLocation")
  valid_613441 = validateParameter(valid_613441, JString, required = false,
                                 default = nil)
  if valid_613441 != nil:
    section.add "SourceBuildInformation.SourceLocation", valid_613441
  var valid_613442 = query.getOrDefault("VersionLabel")
  valid_613442 = validateParameter(valid_613442, JString, required = true,
                                 default = nil)
  if valid_613442 != nil:
    section.add "VersionLabel", valid_613442
  var valid_613443 = query.getOrDefault("Tags")
  valid_613443 = validateParameter(valid_613443, JArray, required = false,
                                 default = nil)
  if valid_613443 != nil:
    section.add "Tags", valid_613443
  var valid_613444 = query.getOrDefault("AutoCreateApplication")
  valid_613444 = validateParameter(valid_613444, JBool, required = false, default = nil)
  if valid_613444 != nil:
    section.add "AutoCreateApplication", valid_613444
  var valid_613445 = query.getOrDefault("BuildConfiguration.Image")
  valid_613445 = validateParameter(valid_613445, JString, required = false,
                                 default = nil)
  if valid_613445 != nil:
    section.add "BuildConfiguration.Image", valid_613445
  var valid_613446 = query.getOrDefault("Action")
  valid_613446 = validateParameter(valid_613446, JString, required = true, default = newJString(
      "CreateApplicationVersion"))
  if valid_613446 != nil:
    section.add "Action", valid_613446
  var valid_613447 = query.getOrDefault("Description")
  valid_613447 = validateParameter(valid_613447, JString, required = false,
                                 default = nil)
  if valid_613447 != nil:
    section.add "Description", valid_613447
  var valid_613448 = query.getOrDefault("SourceBundle.S3Bucket")
  valid_613448 = validateParameter(valid_613448, JString, required = false,
                                 default = nil)
  if valid_613448 != nil:
    section.add "SourceBundle.S3Bucket", valid_613448
  var valid_613449 = query.getOrDefault("SourceBuildInformation.SourceRepository")
  valid_613449 = validateParameter(valid_613449, JString, required = false,
                                 default = nil)
  if valid_613449 != nil:
    section.add "SourceBuildInformation.SourceRepository", valid_613449
  var valid_613450 = query.getOrDefault("BuildConfiguration.ComputeType")
  valid_613450 = validateParameter(valid_613450, JString, required = false,
                                 default = nil)
  if valid_613450 != nil:
    section.add "BuildConfiguration.ComputeType", valid_613450
  var valid_613451 = query.getOrDefault("SourceBuildInformation.SourceType")
  valid_613451 = validateParameter(valid_613451, JString, required = false,
                                 default = nil)
  if valid_613451 != nil:
    section.add "SourceBuildInformation.SourceType", valid_613451
  var valid_613452 = query.getOrDefault("BuildConfiguration.ArtifactName")
  valid_613452 = validateParameter(valid_613452, JString, required = false,
                                 default = nil)
  if valid_613452 != nil:
    section.add "BuildConfiguration.ArtifactName", valid_613452
  var valid_613453 = query.getOrDefault("Version")
  valid_613453 = validateParameter(valid_613453, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_613453 != nil:
    section.add "Version", valid_613453
  var valid_613454 = query.getOrDefault("SourceBundle.S3Key")
  valid_613454 = validateParameter(valid_613454, JString, required = false,
                                 default = nil)
  if valid_613454 != nil:
    section.add "SourceBundle.S3Key", valid_613454
  var valid_613455 = query.getOrDefault("BuildConfiguration.CodeBuildServiceRole")
  valid_613455 = validateParameter(valid_613455, JString, required = false,
                                 default = nil)
  if valid_613455 != nil:
    section.add "BuildConfiguration.CodeBuildServiceRole", valid_613455
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
  var valid_613456 = header.getOrDefault("X-Amz-Signature")
  valid_613456 = validateParameter(valid_613456, JString, required = false,
                                 default = nil)
  if valid_613456 != nil:
    section.add "X-Amz-Signature", valid_613456
  var valid_613457 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613457 = validateParameter(valid_613457, JString, required = false,
                                 default = nil)
  if valid_613457 != nil:
    section.add "X-Amz-Content-Sha256", valid_613457
  var valid_613458 = header.getOrDefault("X-Amz-Date")
  valid_613458 = validateParameter(valid_613458, JString, required = false,
                                 default = nil)
  if valid_613458 != nil:
    section.add "X-Amz-Date", valid_613458
  var valid_613459 = header.getOrDefault("X-Amz-Credential")
  valid_613459 = validateParameter(valid_613459, JString, required = false,
                                 default = nil)
  if valid_613459 != nil:
    section.add "X-Amz-Credential", valid_613459
  var valid_613460 = header.getOrDefault("X-Amz-Security-Token")
  valid_613460 = validateParameter(valid_613460, JString, required = false,
                                 default = nil)
  if valid_613460 != nil:
    section.add "X-Amz-Security-Token", valid_613460
  var valid_613461 = header.getOrDefault("X-Amz-Algorithm")
  valid_613461 = validateParameter(valid_613461, JString, required = false,
                                 default = nil)
  if valid_613461 != nil:
    section.add "X-Amz-Algorithm", valid_613461
  var valid_613462 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613462 = validateParameter(valid_613462, JString, required = false,
                                 default = nil)
  if valid_613462 != nil:
    section.add "X-Amz-SignedHeaders", valid_613462
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613463: Call_GetCreateApplicationVersion_613435; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an application version for the specified application. You can create an application version from a source bundle in Amazon S3, a commit in AWS CodeCommit, or the output of an AWS CodeBuild build as follows:</p> <p>Specify a commit in an AWS CodeCommit repository with <code>SourceBuildInformation</code>.</p> <p>Specify a build in an AWS CodeBuild with <code>SourceBuildInformation</code> and <code>BuildConfiguration</code>.</p> <p>Specify a source bundle in S3 with <code>SourceBundle</code> </p> <p>Omit both <code>SourceBuildInformation</code> and <code>SourceBundle</code> to use the default sample application.</p> <note> <p>Once you create an application version with a specified Amazon S3 bucket and key location, you cannot change that Amazon S3 location. If you change the Amazon S3 location, you receive an exception when you attempt to launch an environment from the application version.</p> </note>
  ## 
  let valid = call_613463.validator(path, query, header, formData, body)
  let scheme = call_613463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613463.url(scheme.get, call_613463.host, call_613463.base,
                         call_613463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613463, url, valid)

proc call*(call_613464: Call_GetCreateApplicationVersion_613435;
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
  var query_613465 = newJObject()
  add(query_613465, "ApplicationName", newJString(ApplicationName))
  add(query_613465, "BuildConfiguration.TimeoutInMinutes",
      newJString(BuildConfigurationTimeoutInMinutes))
  add(query_613465, "Process", newJBool(Process))
  add(query_613465, "SourceBuildInformation.SourceLocation",
      newJString(SourceBuildInformationSourceLocation))
  add(query_613465, "VersionLabel", newJString(VersionLabel))
  if Tags != nil:
    query_613465.add "Tags", Tags
  add(query_613465, "AutoCreateApplication", newJBool(AutoCreateApplication))
  add(query_613465, "BuildConfiguration.Image",
      newJString(BuildConfigurationImage))
  add(query_613465, "Action", newJString(Action))
  add(query_613465, "Description", newJString(Description))
  add(query_613465, "SourceBundle.S3Bucket", newJString(SourceBundleS3Bucket))
  add(query_613465, "SourceBuildInformation.SourceRepository",
      newJString(SourceBuildInformationSourceRepository))
  add(query_613465, "BuildConfiguration.ComputeType",
      newJString(BuildConfigurationComputeType))
  add(query_613465, "SourceBuildInformation.SourceType",
      newJString(SourceBuildInformationSourceType))
  add(query_613465, "BuildConfiguration.ArtifactName",
      newJString(BuildConfigurationArtifactName))
  add(query_613465, "Version", newJString(Version))
  add(query_613465, "SourceBundle.S3Key", newJString(SourceBundleS3Key))
  add(query_613465, "BuildConfiguration.CodeBuildServiceRole",
      newJString(BuildConfigurationCodeBuildServiceRole))
  result = call_613464.call(nil, query_613465, nil, nil, nil)

var getCreateApplicationVersion* = Call_GetCreateApplicationVersion_613435(
    name: "getCreateApplicationVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateApplicationVersion",
    validator: validate_GetCreateApplicationVersion_613436, base: "/",
    url: url_GetCreateApplicationVersion_613437,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateConfigurationTemplate_613523 = ref object of OpenApiRestCall_612659
proc url_PostCreateConfigurationTemplate_613525(protocol: Scheme; host: string;
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

proc validate_PostCreateConfigurationTemplate_613524(path: JsonNode;
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
  var valid_613526 = query.getOrDefault("Action")
  valid_613526 = validateParameter(valid_613526, JString, required = true, default = newJString(
      "CreateConfigurationTemplate"))
  if valid_613526 != nil:
    section.add "Action", valid_613526
  var valid_613527 = query.getOrDefault("Version")
  valid_613527 = validateParameter(valid_613527, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_613527 != nil:
    section.add "Version", valid_613527
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
  var valid_613528 = header.getOrDefault("X-Amz-Signature")
  valid_613528 = validateParameter(valid_613528, JString, required = false,
                                 default = nil)
  if valid_613528 != nil:
    section.add "X-Amz-Signature", valid_613528
  var valid_613529 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613529 = validateParameter(valid_613529, JString, required = false,
                                 default = nil)
  if valid_613529 != nil:
    section.add "X-Amz-Content-Sha256", valid_613529
  var valid_613530 = header.getOrDefault("X-Amz-Date")
  valid_613530 = validateParameter(valid_613530, JString, required = false,
                                 default = nil)
  if valid_613530 != nil:
    section.add "X-Amz-Date", valid_613530
  var valid_613531 = header.getOrDefault("X-Amz-Credential")
  valid_613531 = validateParameter(valid_613531, JString, required = false,
                                 default = nil)
  if valid_613531 != nil:
    section.add "X-Amz-Credential", valid_613531
  var valid_613532 = header.getOrDefault("X-Amz-Security-Token")
  valid_613532 = validateParameter(valid_613532, JString, required = false,
                                 default = nil)
  if valid_613532 != nil:
    section.add "X-Amz-Security-Token", valid_613532
  var valid_613533 = header.getOrDefault("X-Amz-Algorithm")
  valid_613533 = validateParameter(valid_613533, JString, required = false,
                                 default = nil)
  if valid_613533 != nil:
    section.add "X-Amz-Algorithm", valid_613533
  var valid_613534 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613534 = validateParameter(valid_613534, JString, required = false,
                                 default = nil)
  if valid_613534 != nil:
    section.add "X-Amz-SignedHeaders", valid_613534
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
  var valid_613535 = formData.getOrDefault("Description")
  valid_613535 = validateParameter(valid_613535, JString, required = false,
                                 default = nil)
  if valid_613535 != nil:
    section.add "Description", valid_613535
  assert formData != nil,
        "formData argument is necessary due to required `TemplateName` field"
  var valid_613536 = formData.getOrDefault("TemplateName")
  valid_613536 = validateParameter(valid_613536, JString, required = true,
                                 default = nil)
  if valid_613536 != nil:
    section.add "TemplateName", valid_613536
  var valid_613537 = formData.getOrDefault("SourceConfiguration.ApplicationName")
  valid_613537 = validateParameter(valid_613537, JString, required = false,
                                 default = nil)
  if valid_613537 != nil:
    section.add "SourceConfiguration.ApplicationName", valid_613537
  var valid_613538 = formData.getOrDefault("SourceConfiguration.TemplateName")
  valid_613538 = validateParameter(valid_613538, JString, required = false,
                                 default = nil)
  if valid_613538 != nil:
    section.add "SourceConfiguration.TemplateName", valid_613538
  var valid_613539 = formData.getOrDefault("OptionSettings")
  valid_613539 = validateParameter(valid_613539, JArray, required = false,
                                 default = nil)
  if valid_613539 != nil:
    section.add "OptionSettings", valid_613539
  var valid_613540 = formData.getOrDefault("ApplicationName")
  valid_613540 = validateParameter(valid_613540, JString, required = true,
                                 default = nil)
  if valid_613540 != nil:
    section.add "ApplicationName", valid_613540
  var valid_613541 = formData.getOrDefault("Tags")
  valid_613541 = validateParameter(valid_613541, JArray, required = false,
                                 default = nil)
  if valid_613541 != nil:
    section.add "Tags", valid_613541
  var valid_613542 = formData.getOrDefault("SolutionStackName")
  valid_613542 = validateParameter(valid_613542, JString, required = false,
                                 default = nil)
  if valid_613542 != nil:
    section.add "SolutionStackName", valid_613542
  var valid_613543 = formData.getOrDefault("EnvironmentId")
  valid_613543 = validateParameter(valid_613543, JString, required = false,
                                 default = nil)
  if valid_613543 != nil:
    section.add "EnvironmentId", valid_613543
  var valid_613544 = formData.getOrDefault("PlatformArn")
  valid_613544 = validateParameter(valid_613544, JString, required = false,
                                 default = nil)
  if valid_613544 != nil:
    section.add "PlatformArn", valid_613544
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613545: Call_PostCreateConfigurationTemplate_613523;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a configuration template. Templates are associated with a specific application and are used to deploy different versions of the application with the same configuration settings.</p> <p>Templates aren't associated with any environment. The <code>EnvironmentName</code> response element is always <code>null</code>.</p> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> <li> <p> <a>DescribeConfigurationSettings</a> </p> </li> <li> <p> <a>ListAvailableSolutionStacks</a> </p> </li> </ul>
  ## 
  let valid = call_613545.validator(path, query, header, formData, body)
  let scheme = call_613545.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613545.url(scheme.get, call_613545.host, call_613545.base,
                         call_613545.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613545, url, valid)

proc call*(call_613546: Call_PostCreateConfigurationTemplate_613523;
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
  var query_613547 = newJObject()
  var formData_613548 = newJObject()
  add(formData_613548, "Description", newJString(Description))
  add(formData_613548, "TemplateName", newJString(TemplateName))
  add(formData_613548, "SourceConfiguration.ApplicationName",
      newJString(SourceConfigurationApplicationName))
  add(formData_613548, "SourceConfiguration.TemplateName",
      newJString(SourceConfigurationTemplateName))
  if OptionSettings != nil:
    formData_613548.add "OptionSettings", OptionSettings
  add(formData_613548, "ApplicationName", newJString(ApplicationName))
  add(query_613547, "Action", newJString(Action))
  if Tags != nil:
    formData_613548.add "Tags", Tags
  add(formData_613548, "SolutionStackName", newJString(SolutionStackName))
  add(formData_613548, "EnvironmentId", newJString(EnvironmentId))
  add(query_613547, "Version", newJString(Version))
  add(formData_613548, "PlatformArn", newJString(PlatformArn))
  result = call_613546.call(nil, query_613547, nil, formData_613548, nil)

var postCreateConfigurationTemplate* = Call_PostCreateConfigurationTemplate_613523(
    name: "postCreateConfigurationTemplate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateConfigurationTemplate",
    validator: validate_PostCreateConfigurationTemplate_613524, base: "/",
    url: url_PostCreateConfigurationTemplate_613525,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateConfigurationTemplate_613498 = ref object of OpenApiRestCall_612659
proc url_GetCreateConfigurationTemplate_613500(protocol: Scheme; host: string;
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

proc validate_GetCreateConfigurationTemplate_613499(path: JsonNode;
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
  var valid_613501 = query.getOrDefault("ApplicationName")
  valid_613501 = validateParameter(valid_613501, JString, required = true,
                                 default = nil)
  if valid_613501 != nil:
    section.add "ApplicationName", valid_613501
  var valid_613502 = query.getOrDefault("Tags")
  valid_613502 = validateParameter(valid_613502, JArray, required = false,
                                 default = nil)
  if valid_613502 != nil:
    section.add "Tags", valid_613502
  var valid_613503 = query.getOrDefault("OptionSettings")
  valid_613503 = validateParameter(valid_613503, JArray, required = false,
                                 default = nil)
  if valid_613503 != nil:
    section.add "OptionSettings", valid_613503
  var valid_613504 = query.getOrDefault("SourceConfiguration.TemplateName")
  valid_613504 = validateParameter(valid_613504, JString, required = false,
                                 default = nil)
  if valid_613504 != nil:
    section.add "SourceConfiguration.TemplateName", valid_613504
  var valid_613505 = query.getOrDefault("SolutionStackName")
  valid_613505 = validateParameter(valid_613505, JString, required = false,
                                 default = nil)
  if valid_613505 != nil:
    section.add "SolutionStackName", valid_613505
  var valid_613506 = query.getOrDefault("Action")
  valid_613506 = validateParameter(valid_613506, JString, required = true, default = newJString(
      "CreateConfigurationTemplate"))
  if valid_613506 != nil:
    section.add "Action", valid_613506
  var valid_613507 = query.getOrDefault("Description")
  valid_613507 = validateParameter(valid_613507, JString, required = false,
                                 default = nil)
  if valid_613507 != nil:
    section.add "Description", valid_613507
  var valid_613508 = query.getOrDefault("PlatformArn")
  valid_613508 = validateParameter(valid_613508, JString, required = false,
                                 default = nil)
  if valid_613508 != nil:
    section.add "PlatformArn", valid_613508
  var valid_613509 = query.getOrDefault("Version")
  valid_613509 = validateParameter(valid_613509, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_613509 != nil:
    section.add "Version", valid_613509
  var valid_613510 = query.getOrDefault("TemplateName")
  valid_613510 = validateParameter(valid_613510, JString, required = true,
                                 default = nil)
  if valid_613510 != nil:
    section.add "TemplateName", valid_613510
  var valid_613511 = query.getOrDefault("SourceConfiguration.ApplicationName")
  valid_613511 = validateParameter(valid_613511, JString, required = false,
                                 default = nil)
  if valid_613511 != nil:
    section.add "SourceConfiguration.ApplicationName", valid_613511
  var valid_613512 = query.getOrDefault("EnvironmentId")
  valid_613512 = validateParameter(valid_613512, JString, required = false,
                                 default = nil)
  if valid_613512 != nil:
    section.add "EnvironmentId", valid_613512
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
  var valid_613513 = header.getOrDefault("X-Amz-Signature")
  valid_613513 = validateParameter(valid_613513, JString, required = false,
                                 default = nil)
  if valid_613513 != nil:
    section.add "X-Amz-Signature", valid_613513
  var valid_613514 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613514 = validateParameter(valid_613514, JString, required = false,
                                 default = nil)
  if valid_613514 != nil:
    section.add "X-Amz-Content-Sha256", valid_613514
  var valid_613515 = header.getOrDefault("X-Amz-Date")
  valid_613515 = validateParameter(valid_613515, JString, required = false,
                                 default = nil)
  if valid_613515 != nil:
    section.add "X-Amz-Date", valid_613515
  var valid_613516 = header.getOrDefault("X-Amz-Credential")
  valid_613516 = validateParameter(valid_613516, JString, required = false,
                                 default = nil)
  if valid_613516 != nil:
    section.add "X-Amz-Credential", valid_613516
  var valid_613517 = header.getOrDefault("X-Amz-Security-Token")
  valid_613517 = validateParameter(valid_613517, JString, required = false,
                                 default = nil)
  if valid_613517 != nil:
    section.add "X-Amz-Security-Token", valid_613517
  var valid_613518 = header.getOrDefault("X-Amz-Algorithm")
  valid_613518 = validateParameter(valid_613518, JString, required = false,
                                 default = nil)
  if valid_613518 != nil:
    section.add "X-Amz-Algorithm", valid_613518
  var valid_613519 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613519 = validateParameter(valid_613519, JString, required = false,
                                 default = nil)
  if valid_613519 != nil:
    section.add "X-Amz-SignedHeaders", valid_613519
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613520: Call_GetCreateConfigurationTemplate_613498; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a configuration template. Templates are associated with a specific application and are used to deploy different versions of the application with the same configuration settings.</p> <p>Templates aren't associated with any environment. The <code>EnvironmentName</code> response element is always <code>null</code>.</p> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> <li> <p> <a>DescribeConfigurationSettings</a> </p> </li> <li> <p> <a>ListAvailableSolutionStacks</a> </p> </li> </ul>
  ## 
  let valid = call_613520.validator(path, query, header, formData, body)
  let scheme = call_613520.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613520.url(scheme.get, call_613520.host, call_613520.base,
                         call_613520.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613520, url, valid)

proc call*(call_613521: Call_GetCreateConfigurationTemplate_613498;
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
  var query_613522 = newJObject()
  add(query_613522, "ApplicationName", newJString(ApplicationName))
  if Tags != nil:
    query_613522.add "Tags", Tags
  if OptionSettings != nil:
    query_613522.add "OptionSettings", OptionSettings
  add(query_613522, "SourceConfiguration.TemplateName",
      newJString(SourceConfigurationTemplateName))
  add(query_613522, "SolutionStackName", newJString(SolutionStackName))
  add(query_613522, "Action", newJString(Action))
  add(query_613522, "Description", newJString(Description))
  add(query_613522, "PlatformArn", newJString(PlatformArn))
  add(query_613522, "Version", newJString(Version))
  add(query_613522, "TemplateName", newJString(TemplateName))
  add(query_613522, "SourceConfiguration.ApplicationName",
      newJString(SourceConfigurationApplicationName))
  add(query_613522, "EnvironmentId", newJString(EnvironmentId))
  result = call_613521.call(nil, query_613522, nil, nil, nil)

var getCreateConfigurationTemplate* = Call_GetCreateConfigurationTemplate_613498(
    name: "getCreateConfigurationTemplate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateConfigurationTemplate",
    validator: validate_GetCreateConfigurationTemplate_613499, base: "/",
    url: url_GetCreateConfigurationTemplate_613500,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEnvironment_613579 = ref object of OpenApiRestCall_612659
proc url_PostCreateEnvironment_613581(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateEnvironment_613580(path: JsonNode; query: JsonNode;
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
  var valid_613582 = query.getOrDefault("Action")
  valid_613582 = validateParameter(valid_613582, JString, required = true,
                                 default = newJString("CreateEnvironment"))
  if valid_613582 != nil:
    section.add "Action", valid_613582
  var valid_613583 = query.getOrDefault("Version")
  valid_613583 = validateParameter(valid_613583, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_613583 != nil:
    section.add "Version", valid_613583
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
  var valid_613584 = header.getOrDefault("X-Amz-Signature")
  valid_613584 = validateParameter(valid_613584, JString, required = false,
                                 default = nil)
  if valid_613584 != nil:
    section.add "X-Amz-Signature", valid_613584
  var valid_613585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613585 = validateParameter(valid_613585, JString, required = false,
                                 default = nil)
  if valid_613585 != nil:
    section.add "X-Amz-Content-Sha256", valid_613585
  var valid_613586 = header.getOrDefault("X-Amz-Date")
  valid_613586 = validateParameter(valid_613586, JString, required = false,
                                 default = nil)
  if valid_613586 != nil:
    section.add "X-Amz-Date", valid_613586
  var valid_613587 = header.getOrDefault("X-Amz-Credential")
  valid_613587 = validateParameter(valid_613587, JString, required = false,
                                 default = nil)
  if valid_613587 != nil:
    section.add "X-Amz-Credential", valid_613587
  var valid_613588 = header.getOrDefault("X-Amz-Security-Token")
  valid_613588 = validateParameter(valid_613588, JString, required = false,
                                 default = nil)
  if valid_613588 != nil:
    section.add "X-Amz-Security-Token", valid_613588
  var valid_613589 = header.getOrDefault("X-Amz-Algorithm")
  valid_613589 = validateParameter(valid_613589, JString, required = false,
                                 default = nil)
  if valid_613589 != nil:
    section.add "X-Amz-Algorithm", valid_613589
  var valid_613590 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613590 = validateParameter(valid_613590, JString, required = false,
                                 default = nil)
  if valid_613590 != nil:
    section.add "X-Amz-SignedHeaders", valid_613590
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
  var valid_613591 = formData.getOrDefault("Description")
  valid_613591 = validateParameter(valid_613591, JString, required = false,
                                 default = nil)
  if valid_613591 != nil:
    section.add "Description", valid_613591
  var valid_613592 = formData.getOrDefault("Tier.Type")
  valid_613592 = validateParameter(valid_613592, JString, required = false,
                                 default = nil)
  if valid_613592 != nil:
    section.add "Tier.Type", valid_613592
  var valid_613593 = formData.getOrDefault("EnvironmentName")
  valid_613593 = validateParameter(valid_613593, JString, required = false,
                                 default = nil)
  if valid_613593 != nil:
    section.add "EnvironmentName", valid_613593
  var valid_613594 = formData.getOrDefault("CNAMEPrefix")
  valid_613594 = validateParameter(valid_613594, JString, required = false,
                                 default = nil)
  if valid_613594 != nil:
    section.add "CNAMEPrefix", valid_613594
  var valid_613595 = formData.getOrDefault("VersionLabel")
  valid_613595 = validateParameter(valid_613595, JString, required = false,
                                 default = nil)
  if valid_613595 != nil:
    section.add "VersionLabel", valid_613595
  var valid_613596 = formData.getOrDefault("TemplateName")
  valid_613596 = validateParameter(valid_613596, JString, required = false,
                                 default = nil)
  if valid_613596 != nil:
    section.add "TemplateName", valid_613596
  var valid_613597 = formData.getOrDefault("OptionsToRemove")
  valid_613597 = validateParameter(valid_613597, JArray, required = false,
                                 default = nil)
  if valid_613597 != nil:
    section.add "OptionsToRemove", valid_613597
  var valid_613598 = formData.getOrDefault("OptionSettings")
  valid_613598 = validateParameter(valid_613598, JArray, required = false,
                                 default = nil)
  if valid_613598 != nil:
    section.add "OptionSettings", valid_613598
  var valid_613599 = formData.getOrDefault("GroupName")
  valid_613599 = validateParameter(valid_613599, JString, required = false,
                                 default = nil)
  if valid_613599 != nil:
    section.add "GroupName", valid_613599
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_613600 = formData.getOrDefault("ApplicationName")
  valid_613600 = validateParameter(valid_613600, JString, required = true,
                                 default = nil)
  if valid_613600 != nil:
    section.add "ApplicationName", valid_613600
  var valid_613601 = formData.getOrDefault("Tier.Name")
  valid_613601 = validateParameter(valid_613601, JString, required = false,
                                 default = nil)
  if valid_613601 != nil:
    section.add "Tier.Name", valid_613601
  var valid_613602 = formData.getOrDefault("Tier.Version")
  valid_613602 = validateParameter(valid_613602, JString, required = false,
                                 default = nil)
  if valid_613602 != nil:
    section.add "Tier.Version", valid_613602
  var valid_613603 = formData.getOrDefault("Tags")
  valid_613603 = validateParameter(valid_613603, JArray, required = false,
                                 default = nil)
  if valid_613603 != nil:
    section.add "Tags", valid_613603
  var valid_613604 = formData.getOrDefault("SolutionStackName")
  valid_613604 = validateParameter(valid_613604, JString, required = false,
                                 default = nil)
  if valid_613604 != nil:
    section.add "SolutionStackName", valid_613604
  var valid_613605 = formData.getOrDefault("PlatformArn")
  valid_613605 = validateParameter(valid_613605, JString, required = false,
                                 default = nil)
  if valid_613605 != nil:
    section.add "PlatformArn", valid_613605
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613606: Call_PostCreateEnvironment_613579; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Launches an environment for the specified application using the specified configuration.
  ## 
  let valid = call_613606.validator(path, query, header, formData, body)
  let scheme = call_613606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613606.url(scheme.get, call_613606.host, call_613606.base,
                         call_613606.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613606, url, valid)

proc call*(call_613607: Call_PostCreateEnvironment_613579; ApplicationName: string;
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
  var query_613608 = newJObject()
  var formData_613609 = newJObject()
  add(formData_613609, "Description", newJString(Description))
  add(formData_613609, "Tier.Type", newJString(TierType))
  add(formData_613609, "EnvironmentName", newJString(EnvironmentName))
  add(formData_613609, "CNAMEPrefix", newJString(CNAMEPrefix))
  add(formData_613609, "VersionLabel", newJString(VersionLabel))
  add(formData_613609, "TemplateName", newJString(TemplateName))
  if OptionsToRemove != nil:
    formData_613609.add "OptionsToRemove", OptionsToRemove
  if OptionSettings != nil:
    formData_613609.add "OptionSettings", OptionSettings
  add(formData_613609, "GroupName", newJString(GroupName))
  add(formData_613609, "ApplicationName", newJString(ApplicationName))
  add(formData_613609, "Tier.Name", newJString(TierName))
  add(formData_613609, "Tier.Version", newJString(TierVersion))
  add(query_613608, "Action", newJString(Action))
  if Tags != nil:
    formData_613609.add "Tags", Tags
  add(formData_613609, "SolutionStackName", newJString(SolutionStackName))
  add(query_613608, "Version", newJString(Version))
  add(formData_613609, "PlatformArn", newJString(PlatformArn))
  result = call_613607.call(nil, query_613608, nil, formData_613609, nil)

var postCreateEnvironment* = Call_PostCreateEnvironment_613579(
    name: "postCreateEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateEnvironment",
    validator: validate_PostCreateEnvironment_613580, base: "/",
    url: url_PostCreateEnvironment_613581, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEnvironment_613549 = ref object of OpenApiRestCall_612659
proc url_GetCreateEnvironment_613551(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateEnvironment_613550(path: JsonNode; query: JsonNode;
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
  var valid_613552 = query.getOrDefault("ApplicationName")
  valid_613552 = validateParameter(valid_613552, JString, required = true,
                                 default = nil)
  if valid_613552 != nil:
    section.add "ApplicationName", valid_613552
  var valid_613553 = query.getOrDefault("CNAMEPrefix")
  valid_613553 = validateParameter(valid_613553, JString, required = false,
                                 default = nil)
  if valid_613553 != nil:
    section.add "CNAMEPrefix", valid_613553
  var valid_613554 = query.getOrDefault("GroupName")
  valid_613554 = validateParameter(valid_613554, JString, required = false,
                                 default = nil)
  if valid_613554 != nil:
    section.add "GroupName", valid_613554
  var valid_613555 = query.getOrDefault("Tags")
  valid_613555 = validateParameter(valid_613555, JArray, required = false,
                                 default = nil)
  if valid_613555 != nil:
    section.add "Tags", valid_613555
  var valid_613556 = query.getOrDefault("VersionLabel")
  valid_613556 = validateParameter(valid_613556, JString, required = false,
                                 default = nil)
  if valid_613556 != nil:
    section.add "VersionLabel", valid_613556
  var valid_613557 = query.getOrDefault("OptionSettings")
  valid_613557 = validateParameter(valid_613557, JArray, required = false,
                                 default = nil)
  if valid_613557 != nil:
    section.add "OptionSettings", valid_613557
  var valid_613558 = query.getOrDefault("SolutionStackName")
  valid_613558 = validateParameter(valid_613558, JString, required = false,
                                 default = nil)
  if valid_613558 != nil:
    section.add "SolutionStackName", valid_613558
  var valid_613559 = query.getOrDefault("Tier.Name")
  valid_613559 = validateParameter(valid_613559, JString, required = false,
                                 default = nil)
  if valid_613559 != nil:
    section.add "Tier.Name", valid_613559
  var valid_613560 = query.getOrDefault("EnvironmentName")
  valid_613560 = validateParameter(valid_613560, JString, required = false,
                                 default = nil)
  if valid_613560 != nil:
    section.add "EnvironmentName", valid_613560
  var valid_613561 = query.getOrDefault("Action")
  valid_613561 = validateParameter(valid_613561, JString, required = true,
                                 default = newJString("CreateEnvironment"))
  if valid_613561 != nil:
    section.add "Action", valid_613561
  var valid_613562 = query.getOrDefault("Description")
  valid_613562 = validateParameter(valid_613562, JString, required = false,
                                 default = nil)
  if valid_613562 != nil:
    section.add "Description", valid_613562
  var valid_613563 = query.getOrDefault("PlatformArn")
  valid_613563 = validateParameter(valid_613563, JString, required = false,
                                 default = nil)
  if valid_613563 != nil:
    section.add "PlatformArn", valid_613563
  var valid_613564 = query.getOrDefault("OptionsToRemove")
  valid_613564 = validateParameter(valid_613564, JArray, required = false,
                                 default = nil)
  if valid_613564 != nil:
    section.add "OptionsToRemove", valid_613564
  var valid_613565 = query.getOrDefault("Version")
  valid_613565 = validateParameter(valid_613565, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_613565 != nil:
    section.add "Version", valid_613565
  var valid_613566 = query.getOrDefault("TemplateName")
  valid_613566 = validateParameter(valid_613566, JString, required = false,
                                 default = nil)
  if valid_613566 != nil:
    section.add "TemplateName", valid_613566
  var valid_613567 = query.getOrDefault("Tier.Version")
  valid_613567 = validateParameter(valid_613567, JString, required = false,
                                 default = nil)
  if valid_613567 != nil:
    section.add "Tier.Version", valid_613567
  var valid_613568 = query.getOrDefault("Tier.Type")
  valid_613568 = validateParameter(valid_613568, JString, required = false,
                                 default = nil)
  if valid_613568 != nil:
    section.add "Tier.Type", valid_613568
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
  var valid_613569 = header.getOrDefault("X-Amz-Signature")
  valid_613569 = validateParameter(valid_613569, JString, required = false,
                                 default = nil)
  if valid_613569 != nil:
    section.add "X-Amz-Signature", valid_613569
  var valid_613570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613570 = validateParameter(valid_613570, JString, required = false,
                                 default = nil)
  if valid_613570 != nil:
    section.add "X-Amz-Content-Sha256", valid_613570
  var valid_613571 = header.getOrDefault("X-Amz-Date")
  valid_613571 = validateParameter(valid_613571, JString, required = false,
                                 default = nil)
  if valid_613571 != nil:
    section.add "X-Amz-Date", valid_613571
  var valid_613572 = header.getOrDefault("X-Amz-Credential")
  valid_613572 = validateParameter(valid_613572, JString, required = false,
                                 default = nil)
  if valid_613572 != nil:
    section.add "X-Amz-Credential", valid_613572
  var valid_613573 = header.getOrDefault("X-Amz-Security-Token")
  valid_613573 = validateParameter(valid_613573, JString, required = false,
                                 default = nil)
  if valid_613573 != nil:
    section.add "X-Amz-Security-Token", valid_613573
  var valid_613574 = header.getOrDefault("X-Amz-Algorithm")
  valid_613574 = validateParameter(valid_613574, JString, required = false,
                                 default = nil)
  if valid_613574 != nil:
    section.add "X-Amz-Algorithm", valid_613574
  var valid_613575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613575 = validateParameter(valid_613575, JString, required = false,
                                 default = nil)
  if valid_613575 != nil:
    section.add "X-Amz-SignedHeaders", valid_613575
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613576: Call_GetCreateEnvironment_613549; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Launches an environment for the specified application using the specified configuration.
  ## 
  let valid = call_613576.validator(path, query, header, formData, body)
  let scheme = call_613576.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613576.url(scheme.get, call_613576.host, call_613576.base,
                         call_613576.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613576, url, valid)

proc call*(call_613577: Call_GetCreateEnvironment_613549; ApplicationName: string;
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
  var query_613578 = newJObject()
  add(query_613578, "ApplicationName", newJString(ApplicationName))
  add(query_613578, "CNAMEPrefix", newJString(CNAMEPrefix))
  add(query_613578, "GroupName", newJString(GroupName))
  if Tags != nil:
    query_613578.add "Tags", Tags
  add(query_613578, "VersionLabel", newJString(VersionLabel))
  if OptionSettings != nil:
    query_613578.add "OptionSettings", OptionSettings
  add(query_613578, "SolutionStackName", newJString(SolutionStackName))
  add(query_613578, "Tier.Name", newJString(TierName))
  add(query_613578, "EnvironmentName", newJString(EnvironmentName))
  add(query_613578, "Action", newJString(Action))
  add(query_613578, "Description", newJString(Description))
  add(query_613578, "PlatformArn", newJString(PlatformArn))
  if OptionsToRemove != nil:
    query_613578.add "OptionsToRemove", OptionsToRemove
  add(query_613578, "Version", newJString(Version))
  add(query_613578, "TemplateName", newJString(TemplateName))
  add(query_613578, "Tier.Version", newJString(TierVersion))
  add(query_613578, "Tier.Type", newJString(TierType))
  result = call_613577.call(nil, query_613578, nil, nil, nil)

var getCreateEnvironment* = Call_GetCreateEnvironment_613549(
    name: "getCreateEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateEnvironment",
    validator: validate_GetCreateEnvironment_613550, base: "/",
    url: url_GetCreateEnvironment_613551, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreatePlatformVersion_613632 = ref object of OpenApiRestCall_612659
proc url_PostCreatePlatformVersion_613634(protocol: Scheme; host: string;
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

proc validate_PostCreatePlatformVersion_613633(path: JsonNode; query: JsonNode;
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
  var valid_613635 = query.getOrDefault("Action")
  valid_613635 = validateParameter(valid_613635, JString, required = true,
                                 default = newJString("CreatePlatformVersion"))
  if valid_613635 != nil:
    section.add "Action", valid_613635
  var valid_613636 = query.getOrDefault("Version")
  valid_613636 = validateParameter(valid_613636, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_613636 != nil:
    section.add "Version", valid_613636
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
  var valid_613637 = header.getOrDefault("X-Amz-Signature")
  valid_613637 = validateParameter(valid_613637, JString, required = false,
                                 default = nil)
  if valid_613637 != nil:
    section.add "X-Amz-Signature", valid_613637
  var valid_613638 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613638 = validateParameter(valid_613638, JString, required = false,
                                 default = nil)
  if valid_613638 != nil:
    section.add "X-Amz-Content-Sha256", valid_613638
  var valid_613639 = header.getOrDefault("X-Amz-Date")
  valid_613639 = validateParameter(valid_613639, JString, required = false,
                                 default = nil)
  if valid_613639 != nil:
    section.add "X-Amz-Date", valid_613639
  var valid_613640 = header.getOrDefault("X-Amz-Credential")
  valid_613640 = validateParameter(valid_613640, JString, required = false,
                                 default = nil)
  if valid_613640 != nil:
    section.add "X-Amz-Credential", valid_613640
  var valid_613641 = header.getOrDefault("X-Amz-Security-Token")
  valid_613641 = validateParameter(valid_613641, JString, required = false,
                                 default = nil)
  if valid_613641 != nil:
    section.add "X-Amz-Security-Token", valid_613641
  var valid_613642 = header.getOrDefault("X-Amz-Algorithm")
  valid_613642 = validateParameter(valid_613642, JString, required = false,
                                 default = nil)
  if valid_613642 != nil:
    section.add "X-Amz-Algorithm", valid_613642
  var valid_613643 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613643 = validateParameter(valid_613643, JString, required = false,
                                 default = nil)
  if valid_613643 != nil:
    section.add "X-Amz-SignedHeaders", valid_613643
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
  var valid_613644 = formData.getOrDefault("EnvironmentName")
  valid_613644 = validateParameter(valid_613644, JString, required = false,
                                 default = nil)
  if valid_613644 != nil:
    section.add "EnvironmentName", valid_613644
  var valid_613645 = formData.getOrDefault("PlatformDefinitionBundle.S3Key")
  valid_613645 = validateParameter(valid_613645, JString, required = false,
                                 default = nil)
  if valid_613645 != nil:
    section.add "PlatformDefinitionBundle.S3Key", valid_613645
  assert formData != nil, "formData argument is necessary due to required `PlatformVersion` field"
  var valid_613646 = formData.getOrDefault("PlatformVersion")
  valid_613646 = validateParameter(valid_613646, JString, required = true,
                                 default = nil)
  if valid_613646 != nil:
    section.add "PlatformVersion", valid_613646
  var valid_613647 = formData.getOrDefault("OptionSettings")
  valid_613647 = validateParameter(valid_613647, JArray, required = false,
                                 default = nil)
  if valid_613647 != nil:
    section.add "OptionSettings", valid_613647
  var valid_613648 = formData.getOrDefault("Tags")
  valid_613648 = validateParameter(valid_613648, JArray, required = false,
                                 default = nil)
  if valid_613648 != nil:
    section.add "Tags", valid_613648
  var valid_613649 = formData.getOrDefault("PlatformDefinitionBundle.S3Bucket")
  valid_613649 = validateParameter(valid_613649, JString, required = false,
                                 default = nil)
  if valid_613649 != nil:
    section.add "PlatformDefinitionBundle.S3Bucket", valid_613649
  var valid_613650 = formData.getOrDefault("PlatformName")
  valid_613650 = validateParameter(valid_613650, JString, required = true,
                                 default = nil)
  if valid_613650 != nil:
    section.add "PlatformName", valid_613650
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613651: Call_PostCreatePlatformVersion_613632; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new version of your custom platform.
  ## 
  let valid = call_613651.validator(path, query, header, formData, body)
  let scheme = call_613651.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613651.url(scheme.get, call_613651.host, call_613651.base,
                         call_613651.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613651, url, valid)

proc call*(call_613652: Call_PostCreatePlatformVersion_613632;
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
  var query_613653 = newJObject()
  var formData_613654 = newJObject()
  add(formData_613654, "EnvironmentName", newJString(EnvironmentName))
  add(formData_613654, "PlatformDefinitionBundle.S3Key",
      newJString(PlatformDefinitionBundleS3Key))
  add(formData_613654, "PlatformVersion", newJString(PlatformVersion))
  if OptionSettings != nil:
    formData_613654.add "OptionSettings", OptionSettings
  add(query_613653, "Action", newJString(Action))
  if Tags != nil:
    formData_613654.add "Tags", Tags
  add(formData_613654, "PlatformDefinitionBundle.S3Bucket",
      newJString(PlatformDefinitionBundleS3Bucket))
  add(query_613653, "Version", newJString(Version))
  add(formData_613654, "PlatformName", newJString(PlatformName))
  result = call_613652.call(nil, query_613653, nil, formData_613654, nil)

var postCreatePlatformVersion* = Call_PostCreatePlatformVersion_613632(
    name: "postCreatePlatformVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreatePlatformVersion",
    validator: validate_PostCreatePlatformVersion_613633, base: "/",
    url: url_PostCreatePlatformVersion_613634,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreatePlatformVersion_613610 = ref object of OpenApiRestCall_612659
proc url_GetCreatePlatformVersion_613612(protocol: Scheme; host: string;
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

proc validate_GetCreatePlatformVersion_613611(path: JsonNode; query: JsonNode;
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
  var valid_613613 = query.getOrDefault("PlatformName")
  valid_613613 = validateParameter(valid_613613, JString, required = true,
                                 default = nil)
  if valid_613613 != nil:
    section.add "PlatformName", valid_613613
  var valid_613614 = query.getOrDefault("PlatformVersion")
  valid_613614 = validateParameter(valid_613614, JString, required = true,
                                 default = nil)
  if valid_613614 != nil:
    section.add "PlatformVersion", valid_613614
  var valid_613615 = query.getOrDefault("Tags")
  valid_613615 = validateParameter(valid_613615, JArray, required = false,
                                 default = nil)
  if valid_613615 != nil:
    section.add "Tags", valid_613615
  var valid_613616 = query.getOrDefault("OptionSettings")
  valid_613616 = validateParameter(valid_613616, JArray, required = false,
                                 default = nil)
  if valid_613616 != nil:
    section.add "OptionSettings", valid_613616
  var valid_613617 = query.getOrDefault("PlatformDefinitionBundle.S3Bucket")
  valid_613617 = validateParameter(valid_613617, JString, required = false,
                                 default = nil)
  if valid_613617 != nil:
    section.add "PlatformDefinitionBundle.S3Bucket", valid_613617
  var valid_613618 = query.getOrDefault("EnvironmentName")
  valid_613618 = validateParameter(valid_613618, JString, required = false,
                                 default = nil)
  if valid_613618 != nil:
    section.add "EnvironmentName", valid_613618
  var valid_613619 = query.getOrDefault("Action")
  valid_613619 = validateParameter(valid_613619, JString, required = true,
                                 default = newJString("CreatePlatformVersion"))
  if valid_613619 != nil:
    section.add "Action", valid_613619
  var valid_613620 = query.getOrDefault("PlatformDefinitionBundle.S3Key")
  valid_613620 = validateParameter(valid_613620, JString, required = false,
                                 default = nil)
  if valid_613620 != nil:
    section.add "PlatformDefinitionBundle.S3Key", valid_613620
  var valid_613621 = query.getOrDefault("Version")
  valid_613621 = validateParameter(valid_613621, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_613621 != nil:
    section.add "Version", valid_613621
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
  var valid_613622 = header.getOrDefault("X-Amz-Signature")
  valid_613622 = validateParameter(valid_613622, JString, required = false,
                                 default = nil)
  if valid_613622 != nil:
    section.add "X-Amz-Signature", valid_613622
  var valid_613623 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613623 = validateParameter(valid_613623, JString, required = false,
                                 default = nil)
  if valid_613623 != nil:
    section.add "X-Amz-Content-Sha256", valid_613623
  var valid_613624 = header.getOrDefault("X-Amz-Date")
  valid_613624 = validateParameter(valid_613624, JString, required = false,
                                 default = nil)
  if valid_613624 != nil:
    section.add "X-Amz-Date", valid_613624
  var valid_613625 = header.getOrDefault("X-Amz-Credential")
  valid_613625 = validateParameter(valid_613625, JString, required = false,
                                 default = nil)
  if valid_613625 != nil:
    section.add "X-Amz-Credential", valid_613625
  var valid_613626 = header.getOrDefault("X-Amz-Security-Token")
  valid_613626 = validateParameter(valid_613626, JString, required = false,
                                 default = nil)
  if valid_613626 != nil:
    section.add "X-Amz-Security-Token", valid_613626
  var valid_613627 = header.getOrDefault("X-Amz-Algorithm")
  valid_613627 = validateParameter(valid_613627, JString, required = false,
                                 default = nil)
  if valid_613627 != nil:
    section.add "X-Amz-Algorithm", valid_613627
  var valid_613628 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613628 = validateParameter(valid_613628, JString, required = false,
                                 default = nil)
  if valid_613628 != nil:
    section.add "X-Amz-SignedHeaders", valid_613628
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613629: Call_GetCreatePlatformVersion_613610; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new version of your custom platform.
  ## 
  let valid = call_613629.validator(path, query, header, formData, body)
  let scheme = call_613629.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613629.url(scheme.get, call_613629.host, call_613629.base,
                         call_613629.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613629, url, valid)

proc call*(call_613630: Call_GetCreatePlatformVersion_613610; PlatformName: string;
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
  var query_613631 = newJObject()
  add(query_613631, "PlatformName", newJString(PlatformName))
  add(query_613631, "PlatformVersion", newJString(PlatformVersion))
  if Tags != nil:
    query_613631.add "Tags", Tags
  if OptionSettings != nil:
    query_613631.add "OptionSettings", OptionSettings
  add(query_613631, "PlatformDefinitionBundle.S3Bucket",
      newJString(PlatformDefinitionBundleS3Bucket))
  add(query_613631, "EnvironmentName", newJString(EnvironmentName))
  add(query_613631, "Action", newJString(Action))
  add(query_613631, "PlatformDefinitionBundle.S3Key",
      newJString(PlatformDefinitionBundleS3Key))
  add(query_613631, "Version", newJString(Version))
  result = call_613630.call(nil, query_613631, nil, nil, nil)

var getCreatePlatformVersion* = Call_GetCreatePlatformVersion_613610(
    name: "getCreatePlatformVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreatePlatformVersion",
    validator: validate_GetCreatePlatformVersion_613611, base: "/",
    url: url_GetCreatePlatformVersion_613612, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateStorageLocation_613670 = ref object of OpenApiRestCall_612659
proc url_PostCreateStorageLocation_613672(protocol: Scheme; host: string;
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

proc validate_PostCreateStorageLocation_613671(path: JsonNode; query: JsonNode;
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
  var valid_613673 = query.getOrDefault("Action")
  valid_613673 = validateParameter(valid_613673, JString, required = true,
                                 default = newJString("CreateStorageLocation"))
  if valid_613673 != nil:
    section.add "Action", valid_613673
  var valid_613674 = query.getOrDefault("Version")
  valid_613674 = validateParameter(valid_613674, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_613674 != nil:
    section.add "Version", valid_613674
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
  var valid_613675 = header.getOrDefault("X-Amz-Signature")
  valid_613675 = validateParameter(valid_613675, JString, required = false,
                                 default = nil)
  if valid_613675 != nil:
    section.add "X-Amz-Signature", valid_613675
  var valid_613676 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613676 = validateParameter(valid_613676, JString, required = false,
                                 default = nil)
  if valid_613676 != nil:
    section.add "X-Amz-Content-Sha256", valid_613676
  var valid_613677 = header.getOrDefault("X-Amz-Date")
  valid_613677 = validateParameter(valid_613677, JString, required = false,
                                 default = nil)
  if valid_613677 != nil:
    section.add "X-Amz-Date", valid_613677
  var valid_613678 = header.getOrDefault("X-Amz-Credential")
  valid_613678 = validateParameter(valid_613678, JString, required = false,
                                 default = nil)
  if valid_613678 != nil:
    section.add "X-Amz-Credential", valid_613678
  var valid_613679 = header.getOrDefault("X-Amz-Security-Token")
  valid_613679 = validateParameter(valid_613679, JString, required = false,
                                 default = nil)
  if valid_613679 != nil:
    section.add "X-Amz-Security-Token", valid_613679
  var valid_613680 = header.getOrDefault("X-Amz-Algorithm")
  valid_613680 = validateParameter(valid_613680, JString, required = false,
                                 default = nil)
  if valid_613680 != nil:
    section.add "X-Amz-Algorithm", valid_613680
  var valid_613681 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613681 = validateParameter(valid_613681, JString, required = false,
                                 default = nil)
  if valid_613681 != nil:
    section.add "X-Amz-SignedHeaders", valid_613681
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613682: Call_PostCreateStorageLocation_613670; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ## 
  let valid = call_613682.validator(path, query, header, formData, body)
  let scheme = call_613682.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613682.url(scheme.get, call_613682.host, call_613682.base,
                         call_613682.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613682, url, valid)

proc call*(call_613683: Call_PostCreateStorageLocation_613670;
          Action: string = "CreateStorageLocation"; Version: string = "2010-12-01"): Recallable =
  ## postCreateStorageLocation
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613684 = newJObject()
  add(query_613684, "Action", newJString(Action))
  add(query_613684, "Version", newJString(Version))
  result = call_613683.call(nil, query_613684, nil, nil, nil)

var postCreateStorageLocation* = Call_PostCreateStorageLocation_613670(
    name: "postCreateStorageLocation", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateStorageLocation",
    validator: validate_PostCreateStorageLocation_613671, base: "/",
    url: url_PostCreateStorageLocation_613672,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateStorageLocation_613655 = ref object of OpenApiRestCall_612659
proc url_GetCreateStorageLocation_613657(protocol: Scheme; host: string;
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

proc validate_GetCreateStorageLocation_613656(path: JsonNode; query: JsonNode;
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
  var valid_613658 = query.getOrDefault("Action")
  valid_613658 = validateParameter(valid_613658, JString, required = true,
                                 default = newJString("CreateStorageLocation"))
  if valid_613658 != nil:
    section.add "Action", valid_613658
  var valid_613659 = query.getOrDefault("Version")
  valid_613659 = validateParameter(valid_613659, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_613659 != nil:
    section.add "Version", valid_613659
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
  var valid_613660 = header.getOrDefault("X-Amz-Signature")
  valid_613660 = validateParameter(valid_613660, JString, required = false,
                                 default = nil)
  if valid_613660 != nil:
    section.add "X-Amz-Signature", valid_613660
  var valid_613661 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613661 = validateParameter(valid_613661, JString, required = false,
                                 default = nil)
  if valid_613661 != nil:
    section.add "X-Amz-Content-Sha256", valid_613661
  var valid_613662 = header.getOrDefault("X-Amz-Date")
  valid_613662 = validateParameter(valid_613662, JString, required = false,
                                 default = nil)
  if valid_613662 != nil:
    section.add "X-Amz-Date", valid_613662
  var valid_613663 = header.getOrDefault("X-Amz-Credential")
  valid_613663 = validateParameter(valid_613663, JString, required = false,
                                 default = nil)
  if valid_613663 != nil:
    section.add "X-Amz-Credential", valid_613663
  var valid_613664 = header.getOrDefault("X-Amz-Security-Token")
  valid_613664 = validateParameter(valid_613664, JString, required = false,
                                 default = nil)
  if valid_613664 != nil:
    section.add "X-Amz-Security-Token", valid_613664
  var valid_613665 = header.getOrDefault("X-Amz-Algorithm")
  valid_613665 = validateParameter(valid_613665, JString, required = false,
                                 default = nil)
  if valid_613665 != nil:
    section.add "X-Amz-Algorithm", valid_613665
  var valid_613666 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613666 = validateParameter(valid_613666, JString, required = false,
                                 default = nil)
  if valid_613666 != nil:
    section.add "X-Amz-SignedHeaders", valid_613666
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613667: Call_GetCreateStorageLocation_613655; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ## 
  let valid = call_613667.validator(path, query, header, formData, body)
  let scheme = call_613667.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613667.url(scheme.get, call_613667.host, call_613667.base,
                         call_613667.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613667, url, valid)

proc call*(call_613668: Call_GetCreateStorageLocation_613655;
          Action: string = "CreateStorageLocation"; Version: string = "2010-12-01"): Recallable =
  ## getCreateStorageLocation
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613669 = newJObject()
  add(query_613669, "Action", newJString(Action))
  add(query_613669, "Version", newJString(Version))
  result = call_613668.call(nil, query_613669, nil, nil, nil)

var getCreateStorageLocation* = Call_GetCreateStorageLocation_613655(
    name: "getCreateStorageLocation", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateStorageLocation",
    validator: validate_GetCreateStorageLocation_613656, base: "/",
    url: url_GetCreateStorageLocation_613657, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteApplication_613702 = ref object of OpenApiRestCall_612659
proc url_PostDeleteApplication_613704(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteApplication_613703(path: JsonNode; query: JsonNode;
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
  var valid_613705 = query.getOrDefault("Action")
  valid_613705 = validateParameter(valid_613705, JString, required = true,
                                 default = newJString("DeleteApplication"))
  if valid_613705 != nil:
    section.add "Action", valid_613705
  var valid_613706 = query.getOrDefault("Version")
  valid_613706 = validateParameter(valid_613706, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_613706 != nil:
    section.add "Version", valid_613706
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
  var valid_613707 = header.getOrDefault("X-Amz-Signature")
  valid_613707 = validateParameter(valid_613707, JString, required = false,
                                 default = nil)
  if valid_613707 != nil:
    section.add "X-Amz-Signature", valid_613707
  var valid_613708 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613708 = validateParameter(valid_613708, JString, required = false,
                                 default = nil)
  if valid_613708 != nil:
    section.add "X-Amz-Content-Sha256", valid_613708
  var valid_613709 = header.getOrDefault("X-Amz-Date")
  valid_613709 = validateParameter(valid_613709, JString, required = false,
                                 default = nil)
  if valid_613709 != nil:
    section.add "X-Amz-Date", valid_613709
  var valid_613710 = header.getOrDefault("X-Amz-Credential")
  valid_613710 = validateParameter(valid_613710, JString, required = false,
                                 default = nil)
  if valid_613710 != nil:
    section.add "X-Amz-Credential", valid_613710
  var valid_613711 = header.getOrDefault("X-Amz-Security-Token")
  valid_613711 = validateParameter(valid_613711, JString, required = false,
                                 default = nil)
  if valid_613711 != nil:
    section.add "X-Amz-Security-Token", valid_613711
  var valid_613712 = header.getOrDefault("X-Amz-Algorithm")
  valid_613712 = validateParameter(valid_613712, JString, required = false,
                                 default = nil)
  if valid_613712 != nil:
    section.add "X-Amz-Algorithm", valid_613712
  var valid_613713 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613713 = validateParameter(valid_613713, JString, required = false,
                                 default = nil)
  if valid_613713 != nil:
    section.add "X-Amz-SignedHeaders", valid_613713
  result.add "header", section
  ## parameters in `formData` object:
  ##   TerminateEnvByForce: JBool
  ##                      : When set to true, running environments will be terminated before deleting the application.
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to delete.
  section = newJObject()
  var valid_613714 = formData.getOrDefault("TerminateEnvByForce")
  valid_613714 = validateParameter(valid_613714, JBool, required = false, default = nil)
  if valid_613714 != nil:
    section.add "TerminateEnvByForce", valid_613714
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_613715 = formData.getOrDefault("ApplicationName")
  valid_613715 = validateParameter(valid_613715, JString, required = true,
                                 default = nil)
  if valid_613715 != nil:
    section.add "ApplicationName", valid_613715
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613716: Call_PostDeleteApplication_613702; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified application along with all associated versions and configurations. The application versions will not be deleted from your Amazon S3 bucket.</p> <note> <p>You cannot delete an application that has a running environment.</p> </note>
  ## 
  let valid = call_613716.validator(path, query, header, formData, body)
  let scheme = call_613716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613716.url(scheme.get, call_613716.host, call_613716.base,
                         call_613716.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613716, url, valid)

proc call*(call_613717: Call_PostDeleteApplication_613702; ApplicationName: string;
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
  var query_613718 = newJObject()
  var formData_613719 = newJObject()
  add(formData_613719, "TerminateEnvByForce", newJBool(TerminateEnvByForce))
  add(formData_613719, "ApplicationName", newJString(ApplicationName))
  add(query_613718, "Action", newJString(Action))
  add(query_613718, "Version", newJString(Version))
  result = call_613717.call(nil, query_613718, nil, formData_613719, nil)

var postDeleteApplication* = Call_PostDeleteApplication_613702(
    name: "postDeleteApplication", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=DeleteApplication",
    validator: validate_PostDeleteApplication_613703, base: "/",
    url: url_PostDeleteApplication_613704, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteApplication_613685 = ref object of OpenApiRestCall_612659
proc url_GetDeleteApplication_613687(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteApplication_613686(path: JsonNode; query: JsonNode;
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
  var valid_613688 = query.getOrDefault("ApplicationName")
  valid_613688 = validateParameter(valid_613688, JString, required = true,
                                 default = nil)
  if valid_613688 != nil:
    section.add "ApplicationName", valid_613688
  var valid_613689 = query.getOrDefault("Action")
  valid_613689 = validateParameter(valid_613689, JString, required = true,
                                 default = newJString("DeleteApplication"))
  if valid_613689 != nil:
    section.add "Action", valid_613689
  var valid_613690 = query.getOrDefault("TerminateEnvByForce")
  valid_613690 = validateParameter(valid_613690, JBool, required = false, default = nil)
  if valid_613690 != nil:
    section.add "TerminateEnvByForce", valid_613690
  var valid_613691 = query.getOrDefault("Version")
  valid_613691 = validateParameter(valid_613691, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_613691 != nil:
    section.add "Version", valid_613691
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
  var valid_613692 = header.getOrDefault("X-Amz-Signature")
  valid_613692 = validateParameter(valid_613692, JString, required = false,
                                 default = nil)
  if valid_613692 != nil:
    section.add "X-Amz-Signature", valid_613692
  var valid_613693 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613693 = validateParameter(valid_613693, JString, required = false,
                                 default = nil)
  if valid_613693 != nil:
    section.add "X-Amz-Content-Sha256", valid_613693
  var valid_613694 = header.getOrDefault("X-Amz-Date")
  valid_613694 = validateParameter(valid_613694, JString, required = false,
                                 default = nil)
  if valid_613694 != nil:
    section.add "X-Amz-Date", valid_613694
  var valid_613695 = header.getOrDefault("X-Amz-Credential")
  valid_613695 = validateParameter(valid_613695, JString, required = false,
                                 default = nil)
  if valid_613695 != nil:
    section.add "X-Amz-Credential", valid_613695
  var valid_613696 = header.getOrDefault("X-Amz-Security-Token")
  valid_613696 = validateParameter(valid_613696, JString, required = false,
                                 default = nil)
  if valid_613696 != nil:
    section.add "X-Amz-Security-Token", valid_613696
  var valid_613697 = header.getOrDefault("X-Amz-Algorithm")
  valid_613697 = validateParameter(valid_613697, JString, required = false,
                                 default = nil)
  if valid_613697 != nil:
    section.add "X-Amz-Algorithm", valid_613697
  var valid_613698 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613698 = validateParameter(valid_613698, JString, required = false,
                                 default = nil)
  if valid_613698 != nil:
    section.add "X-Amz-SignedHeaders", valid_613698
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613699: Call_GetDeleteApplication_613685; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified application along with all associated versions and configurations. The application versions will not be deleted from your Amazon S3 bucket.</p> <note> <p>You cannot delete an application that has a running environment.</p> </note>
  ## 
  let valid = call_613699.validator(path, query, header, formData, body)
  let scheme = call_613699.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613699.url(scheme.get, call_613699.host, call_613699.base,
                         call_613699.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613699, url, valid)

proc call*(call_613700: Call_GetDeleteApplication_613685; ApplicationName: string;
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
  var query_613701 = newJObject()
  add(query_613701, "ApplicationName", newJString(ApplicationName))
  add(query_613701, "Action", newJString(Action))
  add(query_613701, "TerminateEnvByForce", newJBool(TerminateEnvByForce))
  add(query_613701, "Version", newJString(Version))
  result = call_613700.call(nil, query_613701, nil, nil, nil)

var getDeleteApplication* = Call_GetDeleteApplication_613685(
    name: "getDeleteApplication", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=DeleteApplication",
    validator: validate_GetDeleteApplication_613686, base: "/",
    url: url_GetDeleteApplication_613687, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteApplicationVersion_613738 = ref object of OpenApiRestCall_612659
proc url_PostDeleteApplicationVersion_613740(protocol: Scheme; host: string;
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

proc validate_PostDeleteApplicationVersion_613739(path: JsonNode; query: JsonNode;
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
  var valid_613741 = query.getOrDefault("Action")
  valid_613741 = validateParameter(valid_613741, JString, required = true, default = newJString(
      "DeleteApplicationVersion"))
  if valid_613741 != nil:
    section.add "Action", valid_613741
  var valid_613742 = query.getOrDefault("Version")
  valid_613742 = validateParameter(valid_613742, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_613742 != nil:
    section.add "Version", valid_613742
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
  var valid_613743 = header.getOrDefault("X-Amz-Signature")
  valid_613743 = validateParameter(valid_613743, JString, required = false,
                                 default = nil)
  if valid_613743 != nil:
    section.add "X-Amz-Signature", valid_613743
  var valid_613744 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613744 = validateParameter(valid_613744, JString, required = false,
                                 default = nil)
  if valid_613744 != nil:
    section.add "X-Amz-Content-Sha256", valid_613744
  var valid_613745 = header.getOrDefault("X-Amz-Date")
  valid_613745 = validateParameter(valid_613745, JString, required = false,
                                 default = nil)
  if valid_613745 != nil:
    section.add "X-Amz-Date", valid_613745
  var valid_613746 = header.getOrDefault("X-Amz-Credential")
  valid_613746 = validateParameter(valid_613746, JString, required = false,
                                 default = nil)
  if valid_613746 != nil:
    section.add "X-Amz-Credential", valid_613746
  var valid_613747 = header.getOrDefault("X-Amz-Security-Token")
  valid_613747 = validateParameter(valid_613747, JString, required = false,
                                 default = nil)
  if valid_613747 != nil:
    section.add "X-Amz-Security-Token", valid_613747
  var valid_613748 = header.getOrDefault("X-Amz-Algorithm")
  valid_613748 = validateParameter(valid_613748, JString, required = false,
                                 default = nil)
  if valid_613748 != nil:
    section.add "X-Amz-Algorithm", valid_613748
  var valid_613749 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613749 = validateParameter(valid_613749, JString, required = false,
                                 default = nil)
  if valid_613749 != nil:
    section.add "X-Amz-SignedHeaders", valid_613749
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
  var valid_613750 = formData.getOrDefault("VersionLabel")
  valid_613750 = validateParameter(valid_613750, JString, required = true,
                                 default = nil)
  if valid_613750 != nil:
    section.add "VersionLabel", valid_613750
  var valid_613751 = formData.getOrDefault("DeleteSourceBundle")
  valid_613751 = validateParameter(valid_613751, JBool, required = false, default = nil)
  if valid_613751 != nil:
    section.add "DeleteSourceBundle", valid_613751
  var valid_613752 = formData.getOrDefault("ApplicationName")
  valid_613752 = validateParameter(valid_613752, JString, required = true,
                                 default = nil)
  if valid_613752 != nil:
    section.add "ApplicationName", valid_613752
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613753: Call_PostDeleteApplicationVersion_613738; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified version from the specified application.</p> <note> <p>You cannot delete an application version that is associated with a running environment.</p> </note>
  ## 
  let valid = call_613753.validator(path, query, header, formData, body)
  let scheme = call_613753.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613753.url(scheme.get, call_613753.host, call_613753.base,
                         call_613753.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613753, url, valid)

proc call*(call_613754: Call_PostDeleteApplicationVersion_613738;
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
  var query_613755 = newJObject()
  var formData_613756 = newJObject()
  add(formData_613756, "VersionLabel", newJString(VersionLabel))
  add(formData_613756, "DeleteSourceBundle", newJBool(DeleteSourceBundle))
  add(formData_613756, "ApplicationName", newJString(ApplicationName))
  add(query_613755, "Action", newJString(Action))
  add(query_613755, "Version", newJString(Version))
  result = call_613754.call(nil, query_613755, nil, formData_613756, nil)

var postDeleteApplicationVersion* = Call_PostDeleteApplicationVersion_613738(
    name: "postDeleteApplicationVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteApplicationVersion",
    validator: validate_PostDeleteApplicationVersion_613739, base: "/",
    url: url_PostDeleteApplicationVersion_613740,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteApplicationVersion_613720 = ref object of OpenApiRestCall_612659
proc url_GetDeleteApplicationVersion_613722(protocol: Scheme; host: string;
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

proc validate_GetDeleteApplicationVersion_613721(path: JsonNode; query: JsonNode;
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
  var valid_613723 = query.getOrDefault("ApplicationName")
  valid_613723 = validateParameter(valid_613723, JString, required = true,
                                 default = nil)
  if valid_613723 != nil:
    section.add "ApplicationName", valid_613723
  var valid_613724 = query.getOrDefault("VersionLabel")
  valid_613724 = validateParameter(valid_613724, JString, required = true,
                                 default = nil)
  if valid_613724 != nil:
    section.add "VersionLabel", valid_613724
  var valid_613725 = query.getOrDefault("Action")
  valid_613725 = validateParameter(valid_613725, JString, required = true, default = newJString(
      "DeleteApplicationVersion"))
  if valid_613725 != nil:
    section.add "Action", valid_613725
  var valid_613726 = query.getOrDefault("Version")
  valid_613726 = validateParameter(valid_613726, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_613726 != nil:
    section.add "Version", valid_613726
  var valid_613727 = query.getOrDefault("DeleteSourceBundle")
  valid_613727 = validateParameter(valid_613727, JBool, required = false, default = nil)
  if valid_613727 != nil:
    section.add "DeleteSourceBundle", valid_613727
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
  var valid_613728 = header.getOrDefault("X-Amz-Signature")
  valid_613728 = validateParameter(valid_613728, JString, required = false,
                                 default = nil)
  if valid_613728 != nil:
    section.add "X-Amz-Signature", valid_613728
  var valid_613729 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613729 = validateParameter(valid_613729, JString, required = false,
                                 default = nil)
  if valid_613729 != nil:
    section.add "X-Amz-Content-Sha256", valid_613729
  var valid_613730 = header.getOrDefault("X-Amz-Date")
  valid_613730 = validateParameter(valid_613730, JString, required = false,
                                 default = nil)
  if valid_613730 != nil:
    section.add "X-Amz-Date", valid_613730
  var valid_613731 = header.getOrDefault("X-Amz-Credential")
  valid_613731 = validateParameter(valid_613731, JString, required = false,
                                 default = nil)
  if valid_613731 != nil:
    section.add "X-Amz-Credential", valid_613731
  var valid_613732 = header.getOrDefault("X-Amz-Security-Token")
  valid_613732 = validateParameter(valid_613732, JString, required = false,
                                 default = nil)
  if valid_613732 != nil:
    section.add "X-Amz-Security-Token", valid_613732
  var valid_613733 = header.getOrDefault("X-Amz-Algorithm")
  valid_613733 = validateParameter(valid_613733, JString, required = false,
                                 default = nil)
  if valid_613733 != nil:
    section.add "X-Amz-Algorithm", valid_613733
  var valid_613734 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613734 = validateParameter(valid_613734, JString, required = false,
                                 default = nil)
  if valid_613734 != nil:
    section.add "X-Amz-SignedHeaders", valid_613734
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613735: Call_GetDeleteApplicationVersion_613720; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified version from the specified application.</p> <note> <p>You cannot delete an application version that is associated with a running environment.</p> </note>
  ## 
  let valid = call_613735.validator(path, query, header, formData, body)
  let scheme = call_613735.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613735.url(scheme.get, call_613735.host, call_613735.base,
                         call_613735.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613735, url, valid)

proc call*(call_613736: Call_GetDeleteApplicationVersion_613720;
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
  var query_613737 = newJObject()
  add(query_613737, "ApplicationName", newJString(ApplicationName))
  add(query_613737, "VersionLabel", newJString(VersionLabel))
  add(query_613737, "Action", newJString(Action))
  add(query_613737, "Version", newJString(Version))
  add(query_613737, "DeleteSourceBundle", newJBool(DeleteSourceBundle))
  result = call_613736.call(nil, query_613737, nil, nil, nil)

var getDeleteApplicationVersion* = Call_GetDeleteApplicationVersion_613720(
    name: "getDeleteApplicationVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteApplicationVersion",
    validator: validate_GetDeleteApplicationVersion_613721, base: "/",
    url: url_GetDeleteApplicationVersion_613722,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteConfigurationTemplate_613774 = ref object of OpenApiRestCall_612659
proc url_PostDeleteConfigurationTemplate_613776(protocol: Scheme; host: string;
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

proc validate_PostDeleteConfigurationTemplate_613775(path: JsonNode;
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
  var valid_613777 = query.getOrDefault("Action")
  valid_613777 = validateParameter(valid_613777, JString, required = true, default = newJString(
      "DeleteConfigurationTemplate"))
  if valid_613777 != nil:
    section.add "Action", valid_613777
  var valid_613778 = query.getOrDefault("Version")
  valid_613778 = validateParameter(valid_613778, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_613778 != nil:
    section.add "Version", valid_613778
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
  var valid_613779 = header.getOrDefault("X-Amz-Signature")
  valid_613779 = validateParameter(valid_613779, JString, required = false,
                                 default = nil)
  if valid_613779 != nil:
    section.add "X-Amz-Signature", valid_613779
  var valid_613780 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613780 = validateParameter(valid_613780, JString, required = false,
                                 default = nil)
  if valid_613780 != nil:
    section.add "X-Amz-Content-Sha256", valid_613780
  var valid_613781 = header.getOrDefault("X-Amz-Date")
  valid_613781 = validateParameter(valid_613781, JString, required = false,
                                 default = nil)
  if valid_613781 != nil:
    section.add "X-Amz-Date", valid_613781
  var valid_613782 = header.getOrDefault("X-Amz-Credential")
  valid_613782 = validateParameter(valid_613782, JString, required = false,
                                 default = nil)
  if valid_613782 != nil:
    section.add "X-Amz-Credential", valid_613782
  var valid_613783 = header.getOrDefault("X-Amz-Security-Token")
  valid_613783 = validateParameter(valid_613783, JString, required = false,
                                 default = nil)
  if valid_613783 != nil:
    section.add "X-Amz-Security-Token", valid_613783
  var valid_613784 = header.getOrDefault("X-Amz-Algorithm")
  valid_613784 = validateParameter(valid_613784, JString, required = false,
                                 default = nil)
  if valid_613784 != nil:
    section.add "X-Amz-Algorithm", valid_613784
  var valid_613785 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613785 = validateParameter(valid_613785, JString, required = false,
                                 default = nil)
  if valid_613785 != nil:
    section.add "X-Amz-SignedHeaders", valid_613785
  result.add "header", section
  ## parameters in `formData` object:
  ##   TemplateName: JString (required)
  ##               : The name of the configuration template to delete.
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to delete the configuration template from.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TemplateName` field"
  var valid_613786 = formData.getOrDefault("TemplateName")
  valid_613786 = validateParameter(valid_613786, JString, required = true,
                                 default = nil)
  if valid_613786 != nil:
    section.add "TemplateName", valid_613786
  var valid_613787 = formData.getOrDefault("ApplicationName")
  valid_613787 = validateParameter(valid_613787, JString, required = true,
                                 default = nil)
  if valid_613787 != nil:
    section.add "ApplicationName", valid_613787
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613788: Call_PostDeleteConfigurationTemplate_613774;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes the specified configuration template.</p> <note> <p>When you launch an environment using a configuration template, the environment gets a copy of the template. You can delete or modify the environment's copy of the template without affecting the running environment.</p> </note>
  ## 
  let valid = call_613788.validator(path, query, header, formData, body)
  let scheme = call_613788.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613788.url(scheme.get, call_613788.host, call_613788.base,
                         call_613788.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613788, url, valid)

proc call*(call_613789: Call_PostDeleteConfigurationTemplate_613774;
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
  var query_613790 = newJObject()
  var formData_613791 = newJObject()
  add(formData_613791, "TemplateName", newJString(TemplateName))
  add(formData_613791, "ApplicationName", newJString(ApplicationName))
  add(query_613790, "Action", newJString(Action))
  add(query_613790, "Version", newJString(Version))
  result = call_613789.call(nil, query_613790, nil, formData_613791, nil)

var postDeleteConfigurationTemplate* = Call_PostDeleteConfigurationTemplate_613774(
    name: "postDeleteConfigurationTemplate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteConfigurationTemplate",
    validator: validate_PostDeleteConfigurationTemplate_613775, base: "/",
    url: url_PostDeleteConfigurationTemplate_613776,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteConfigurationTemplate_613757 = ref object of OpenApiRestCall_612659
proc url_GetDeleteConfigurationTemplate_613759(protocol: Scheme; host: string;
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

proc validate_GetDeleteConfigurationTemplate_613758(path: JsonNode;
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
  var valid_613760 = query.getOrDefault("ApplicationName")
  valid_613760 = validateParameter(valid_613760, JString, required = true,
                                 default = nil)
  if valid_613760 != nil:
    section.add "ApplicationName", valid_613760
  var valid_613761 = query.getOrDefault("Action")
  valid_613761 = validateParameter(valid_613761, JString, required = true, default = newJString(
      "DeleteConfigurationTemplate"))
  if valid_613761 != nil:
    section.add "Action", valid_613761
  var valid_613762 = query.getOrDefault("Version")
  valid_613762 = validateParameter(valid_613762, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_613762 != nil:
    section.add "Version", valid_613762
  var valid_613763 = query.getOrDefault("TemplateName")
  valid_613763 = validateParameter(valid_613763, JString, required = true,
                                 default = nil)
  if valid_613763 != nil:
    section.add "TemplateName", valid_613763
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
  var valid_613764 = header.getOrDefault("X-Amz-Signature")
  valid_613764 = validateParameter(valid_613764, JString, required = false,
                                 default = nil)
  if valid_613764 != nil:
    section.add "X-Amz-Signature", valid_613764
  var valid_613765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613765 = validateParameter(valid_613765, JString, required = false,
                                 default = nil)
  if valid_613765 != nil:
    section.add "X-Amz-Content-Sha256", valid_613765
  var valid_613766 = header.getOrDefault("X-Amz-Date")
  valid_613766 = validateParameter(valid_613766, JString, required = false,
                                 default = nil)
  if valid_613766 != nil:
    section.add "X-Amz-Date", valid_613766
  var valid_613767 = header.getOrDefault("X-Amz-Credential")
  valid_613767 = validateParameter(valid_613767, JString, required = false,
                                 default = nil)
  if valid_613767 != nil:
    section.add "X-Amz-Credential", valid_613767
  var valid_613768 = header.getOrDefault("X-Amz-Security-Token")
  valid_613768 = validateParameter(valid_613768, JString, required = false,
                                 default = nil)
  if valid_613768 != nil:
    section.add "X-Amz-Security-Token", valid_613768
  var valid_613769 = header.getOrDefault("X-Amz-Algorithm")
  valid_613769 = validateParameter(valid_613769, JString, required = false,
                                 default = nil)
  if valid_613769 != nil:
    section.add "X-Amz-Algorithm", valid_613769
  var valid_613770 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613770 = validateParameter(valid_613770, JString, required = false,
                                 default = nil)
  if valid_613770 != nil:
    section.add "X-Amz-SignedHeaders", valid_613770
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613771: Call_GetDeleteConfigurationTemplate_613757; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified configuration template.</p> <note> <p>When you launch an environment using a configuration template, the environment gets a copy of the template. You can delete or modify the environment's copy of the template without affecting the running environment.</p> </note>
  ## 
  let valid = call_613771.validator(path, query, header, formData, body)
  let scheme = call_613771.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613771.url(scheme.get, call_613771.host, call_613771.base,
                         call_613771.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613771, url, valid)

proc call*(call_613772: Call_GetDeleteConfigurationTemplate_613757;
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
  var query_613773 = newJObject()
  add(query_613773, "ApplicationName", newJString(ApplicationName))
  add(query_613773, "Action", newJString(Action))
  add(query_613773, "Version", newJString(Version))
  add(query_613773, "TemplateName", newJString(TemplateName))
  result = call_613772.call(nil, query_613773, nil, nil, nil)

var getDeleteConfigurationTemplate* = Call_GetDeleteConfigurationTemplate_613757(
    name: "getDeleteConfigurationTemplate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteConfigurationTemplate",
    validator: validate_GetDeleteConfigurationTemplate_613758, base: "/",
    url: url_GetDeleteConfigurationTemplate_613759,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEnvironmentConfiguration_613809 = ref object of OpenApiRestCall_612659
proc url_PostDeleteEnvironmentConfiguration_613811(protocol: Scheme; host: string;
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

proc validate_PostDeleteEnvironmentConfiguration_613810(path: JsonNode;
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
  var valid_613812 = query.getOrDefault("Action")
  valid_613812 = validateParameter(valid_613812, JString, required = true, default = newJString(
      "DeleteEnvironmentConfiguration"))
  if valid_613812 != nil:
    section.add "Action", valid_613812
  var valid_613813 = query.getOrDefault("Version")
  valid_613813 = validateParameter(valid_613813, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_613813 != nil:
    section.add "Version", valid_613813
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
  var valid_613814 = header.getOrDefault("X-Amz-Signature")
  valid_613814 = validateParameter(valid_613814, JString, required = false,
                                 default = nil)
  if valid_613814 != nil:
    section.add "X-Amz-Signature", valid_613814
  var valid_613815 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613815 = validateParameter(valid_613815, JString, required = false,
                                 default = nil)
  if valid_613815 != nil:
    section.add "X-Amz-Content-Sha256", valid_613815
  var valid_613816 = header.getOrDefault("X-Amz-Date")
  valid_613816 = validateParameter(valid_613816, JString, required = false,
                                 default = nil)
  if valid_613816 != nil:
    section.add "X-Amz-Date", valid_613816
  var valid_613817 = header.getOrDefault("X-Amz-Credential")
  valid_613817 = validateParameter(valid_613817, JString, required = false,
                                 default = nil)
  if valid_613817 != nil:
    section.add "X-Amz-Credential", valid_613817
  var valid_613818 = header.getOrDefault("X-Amz-Security-Token")
  valid_613818 = validateParameter(valid_613818, JString, required = false,
                                 default = nil)
  if valid_613818 != nil:
    section.add "X-Amz-Security-Token", valid_613818
  var valid_613819 = header.getOrDefault("X-Amz-Algorithm")
  valid_613819 = validateParameter(valid_613819, JString, required = false,
                                 default = nil)
  if valid_613819 != nil:
    section.add "X-Amz-Algorithm", valid_613819
  var valid_613820 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613820 = validateParameter(valid_613820, JString, required = false,
                                 default = nil)
  if valid_613820 != nil:
    section.add "X-Amz-SignedHeaders", valid_613820
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString (required)
  ##                  : The name of the environment to delete the draft configuration from.
  ##   ApplicationName: JString (required)
  ##                  : The name of the application the environment is associated with.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `EnvironmentName` field"
  var valid_613821 = formData.getOrDefault("EnvironmentName")
  valid_613821 = validateParameter(valid_613821, JString, required = true,
                                 default = nil)
  if valid_613821 != nil:
    section.add "EnvironmentName", valid_613821
  var valid_613822 = formData.getOrDefault("ApplicationName")
  valid_613822 = validateParameter(valid_613822, JString, required = true,
                                 default = nil)
  if valid_613822 != nil:
    section.add "ApplicationName", valid_613822
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613823: Call_PostDeleteEnvironmentConfiguration_613809;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes the draft configuration associated with the running environment.</p> <p>Updating a running environment with any configuration changes creates a draft configuration set. You can get the draft configuration using <a>DescribeConfigurationSettings</a> while the update is in progress or if the update fails. The <code>DeploymentStatus</code> for the draft configuration indicates whether the deployment is in process or has failed. The draft configuration remains in existence until it is deleted with this action.</p>
  ## 
  let valid = call_613823.validator(path, query, header, formData, body)
  let scheme = call_613823.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613823.url(scheme.get, call_613823.host, call_613823.base,
                         call_613823.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613823, url, valid)

proc call*(call_613824: Call_PostDeleteEnvironmentConfiguration_613809;
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
  var query_613825 = newJObject()
  var formData_613826 = newJObject()
  add(formData_613826, "EnvironmentName", newJString(EnvironmentName))
  add(formData_613826, "ApplicationName", newJString(ApplicationName))
  add(query_613825, "Action", newJString(Action))
  add(query_613825, "Version", newJString(Version))
  result = call_613824.call(nil, query_613825, nil, formData_613826, nil)

var postDeleteEnvironmentConfiguration* = Call_PostDeleteEnvironmentConfiguration_613809(
    name: "postDeleteEnvironmentConfiguration", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteEnvironmentConfiguration",
    validator: validate_PostDeleteEnvironmentConfiguration_613810, base: "/",
    url: url_PostDeleteEnvironmentConfiguration_613811,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEnvironmentConfiguration_613792 = ref object of OpenApiRestCall_612659
proc url_GetDeleteEnvironmentConfiguration_613794(protocol: Scheme; host: string;
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

proc validate_GetDeleteEnvironmentConfiguration_613793(path: JsonNode;
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
  var valid_613795 = query.getOrDefault("ApplicationName")
  valid_613795 = validateParameter(valid_613795, JString, required = true,
                                 default = nil)
  if valid_613795 != nil:
    section.add "ApplicationName", valid_613795
  var valid_613796 = query.getOrDefault("EnvironmentName")
  valid_613796 = validateParameter(valid_613796, JString, required = true,
                                 default = nil)
  if valid_613796 != nil:
    section.add "EnvironmentName", valid_613796
  var valid_613797 = query.getOrDefault("Action")
  valid_613797 = validateParameter(valid_613797, JString, required = true, default = newJString(
      "DeleteEnvironmentConfiguration"))
  if valid_613797 != nil:
    section.add "Action", valid_613797
  var valid_613798 = query.getOrDefault("Version")
  valid_613798 = validateParameter(valid_613798, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_613798 != nil:
    section.add "Version", valid_613798
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
  var valid_613799 = header.getOrDefault("X-Amz-Signature")
  valid_613799 = validateParameter(valid_613799, JString, required = false,
                                 default = nil)
  if valid_613799 != nil:
    section.add "X-Amz-Signature", valid_613799
  var valid_613800 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613800 = validateParameter(valid_613800, JString, required = false,
                                 default = nil)
  if valid_613800 != nil:
    section.add "X-Amz-Content-Sha256", valid_613800
  var valid_613801 = header.getOrDefault("X-Amz-Date")
  valid_613801 = validateParameter(valid_613801, JString, required = false,
                                 default = nil)
  if valid_613801 != nil:
    section.add "X-Amz-Date", valid_613801
  var valid_613802 = header.getOrDefault("X-Amz-Credential")
  valid_613802 = validateParameter(valid_613802, JString, required = false,
                                 default = nil)
  if valid_613802 != nil:
    section.add "X-Amz-Credential", valid_613802
  var valid_613803 = header.getOrDefault("X-Amz-Security-Token")
  valid_613803 = validateParameter(valid_613803, JString, required = false,
                                 default = nil)
  if valid_613803 != nil:
    section.add "X-Amz-Security-Token", valid_613803
  var valid_613804 = header.getOrDefault("X-Amz-Algorithm")
  valid_613804 = validateParameter(valid_613804, JString, required = false,
                                 default = nil)
  if valid_613804 != nil:
    section.add "X-Amz-Algorithm", valid_613804
  var valid_613805 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613805 = validateParameter(valid_613805, JString, required = false,
                                 default = nil)
  if valid_613805 != nil:
    section.add "X-Amz-SignedHeaders", valid_613805
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613806: Call_GetDeleteEnvironmentConfiguration_613792;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes the draft configuration associated with the running environment.</p> <p>Updating a running environment with any configuration changes creates a draft configuration set. You can get the draft configuration using <a>DescribeConfigurationSettings</a> while the update is in progress or if the update fails. The <code>DeploymentStatus</code> for the draft configuration indicates whether the deployment is in process or has failed. The draft configuration remains in existence until it is deleted with this action.</p>
  ## 
  let valid = call_613806.validator(path, query, header, formData, body)
  let scheme = call_613806.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613806.url(scheme.get, call_613806.host, call_613806.base,
                         call_613806.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613806, url, valid)

proc call*(call_613807: Call_GetDeleteEnvironmentConfiguration_613792;
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
  var query_613808 = newJObject()
  add(query_613808, "ApplicationName", newJString(ApplicationName))
  add(query_613808, "EnvironmentName", newJString(EnvironmentName))
  add(query_613808, "Action", newJString(Action))
  add(query_613808, "Version", newJString(Version))
  result = call_613807.call(nil, query_613808, nil, nil, nil)

var getDeleteEnvironmentConfiguration* = Call_GetDeleteEnvironmentConfiguration_613792(
    name: "getDeleteEnvironmentConfiguration", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteEnvironmentConfiguration",
    validator: validate_GetDeleteEnvironmentConfiguration_613793, base: "/",
    url: url_GetDeleteEnvironmentConfiguration_613794,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeletePlatformVersion_613843 = ref object of OpenApiRestCall_612659
proc url_PostDeletePlatformVersion_613845(protocol: Scheme; host: string;
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

proc validate_PostDeletePlatformVersion_613844(path: JsonNode; query: JsonNode;
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
  var valid_613846 = query.getOrDefault("Action")
  valid_613846 = validateParameter(valid_613846, JString, required = true,
                                 default = newJString("DeletePlatformVersion"))
  if valid_613846 != nil:
    section.add "Action", valid_613846
  var valid_613847 = query.getOrDefault("Version")
  valid_613847 = validateParameter(valid_613847, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_613847 != nil:
    section.add "Version", valid_613847
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
  var valid_613848 = header.getOrDefault("X-Amz-Signature")
  valid_613848 = validateParameter(valid_613848, JString, required = false,
                                 default = nil)
  if valid_613848 != nil:
    section.add "X-Amz-Signature", valid_613848
  var valid_613849 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613849 = validateParameter(valid_613849, JString, required = false,
                                 default = nil)
  if valid_613849 != nil:
    section.add "X-Amz-Content-Sha256", valid_613849
  var valid_613850 = header.getOrDefault("X-Amz-Date")
  valid_613850 = validateParameter(valid_613850, JString, required = false,
                                 default = nil)
  if valid_613850 != nil:
    section.add "X-Amz-Date", valid_613850
  var valid_613851 = header.getOrDefault("X-Amz-Credential")
  valid_613851 = validateParameter(valid_613851, JString, required = false,
                                 default = nil)
  if valid_613851 != nil:
    section.add "X-Amz-Credential", valid_613851
  var valid_613852 = header.getOrDefault("X-Amz-Security-Token")
  valid_613852 = validateParameter(valid_613852, JString, required = false,
                                 default = nil)
  if valid_613852 != nil:
    section.add "X-Amz-Security-Token", valid_613852
  var valid_613853 = header.getOrDefault("X-Amz-Algorithm")
  valid_613853 = validateParameter(valid_613853, JString, required = false,
                                 default = nil)
  if valid_613853 != nil:
    section.add "X-Amz-Algorithm", valid_613853
  var valid_613854 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613854 = validateParameter(valid_613854, JString, required = false,
                                 default = nil)
  if valid_613854 != nil:
    section.add "X-Amz-SignedHeaders", valid_613854
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformArn: JString
  ##              : The ARN of the version of the custom platform.
  section = newJObject()
  var valid_613855 = formData.getOrDefault("PlatformArn")
  valid_613855 = validateParameter(valid_613855, JString, required = false,
                                 default = nil)
  if valid_613855 != nil:
    section.add "PlatformArn", valid_613855
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613856: Call_PostDeletePlatformVersion_613843; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified version of a custom platform.
  ## 
  let valid = call_613856.validator(path, query, header, formData, body)
  let scheme = call_613856.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613856.url(scheme.get, call_613856.host, call_613856.base,
                         call_613856.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613856, url, valid)

proc call*(call_613857: Call_PostDeletePlatformVersion_613843;
          Action: string = "DeletePlatformVersion"; Version: string = "2010-12-01";
          PlatformArn: string = ""): Recallable =
  ## postDeletePlatformVersion
  ## Deletes the specified version of a custom platform.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PlatformArn: string
  ##              : The ARN of the version of the custom platform.
  var query_613858 = newJObject()
  var formData_613859 = newJObject()
  add(query_613858, "Action", newJString(Action))
  add(query_613858, "Version", newJString(Version))
  add(formData_613859, "PlatformArn", newJString(PlatformArn))
  result = call_613857.call(nil, query_613858, nil, formData_613859, nil)

var postDeletePlatformVersion* = Call_PostDeletePlatformVersion_613843(
    name: "postDeletePlatformVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeletePlatformVersion",
    validator: validate_PostDeletePlatformVersion_613844, base: "/",
    url: url_PostDeletePlatformVersion_613845,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeletePlatformVersion_613827 = ref object of OpenApiRestCall_612659
proc url_GetDeletePlatformVersion_613829(protocol: Scheme; host: string;
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

proc validate_GetDeletePlatformVersion_613828(path: JsonNode; query: JsonNode;
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
  var valid_613830 = query.getOrDefault("Action")
  valid_613830 = validateParameter(valid_613830, JString, required = true,
                                 default = newJString("DeletePlatformVersion"))
  if valid_613830 != nil:
    section.add "Action", valid_613830
  var valid_613831 = query.getOrDefault("PlatformArn")
  valid_613831 = validateParameter(valid_613831, JString, required = false,
                                 default = nil)
  if valid_613831 != nil:
    section.add "PlatformArn", valid_613831
  var valid_613832 = query.getOrDefault("Version")
  valid_613832 = validateParameter(valid_613832, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_613832 != nil:
    section.add "Version", valid_613832
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
  var valid_613833 = header.getOrDefault("X-Amz-Signature")
  valid_613833 = validateParameter(valid_613833, JString, required = false,
                                 default = nil)
  if valid_613833 != nil:
    section.add "X-Amz-Signature", valid_613833
  var valid_613834 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613834 = validateParameter(valid_613834, JString, required = false,
                                 default = nil)
  if valid_613834 != nil:
    section.add "X-Amz-Content-Sha256", valid_613834
  var valid_613835 = header.getOrDefault("X-Amz-Date")
  valid_613835 = validateParameter(valid_613835, JString, required = false,
                                 default = nil)
  if valid_613835 != nil:
    section.add "X-Amz-Date", valid_613835
  var valid_613836 = header.getOrDefault("X-Amz-Credential")
  valid_613836 = validateParameter(valid_613836, JString, required = false,
                                 default = nil)
  if valid_613836 != nil:
    section.add "X-Amz-Credential", valid_613836
  var valid_613837 = header.getOrDefault("X-Amz-Security-Token")
  valid_613837 = validateParameter(valid_613837, JString, required = false,
                                 default = nil)
  if valid_613837 != nil:
    section.add "X-Amz-Security-Token", valid_613837
  var valid_613838 = header.getOrDefault("X-Amz-Algorithm")
  valid_613838 = validateParameter(valid_613838, JString, required = false,
                                 default = nil)
  if valid_613838 != nil:
    section.add "X-Amz-Algorithm", valid_613838
  var valid_613839 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613839 = validateParameter(valid_613839, JString, required = false,
                                 default = nil)
  if valid_613839 != nil:
    section.add "X-Amz-SignedHeaders", valid_613839
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613840: Call_GetDeletePlatformVersion_613827; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified version of a custom platform.
  ## 
  let valid = call_613840.validator(path, query, header, formData, body)
  let scheme = call_613840.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613840.url(scheme.get, call_613840.host, call_613840.base,
                         call_613840.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613840, url, valid)

proc call*(call_613841: Call_GetDeletePlatformVersion_613827;
          Action: string = "DeletePlatformVersion"; PlatformArn: string = "";
          Version: string = "2010-12-01"): Recallable =
  ## getDeletePlatformVersion
  ## Deletes the specified version of a custom platform.
  ##   Action: string (required)
  ##   PlatformArn: string
  ##              : The ARN of the version of the custom platform.
  ##   Version: string (required)
  var query_613842 = newJObject()
  add(query_613842, "Action", newJString(Action))
  add(query_613842, "PlatformArn", newJString(PlatformArn))
  add(query_613842, "Version", newJString(Version))
  result = call_613841.call(nil, query_613842, nil, nil, nil)

var getDeletePlatformVersion* = Call_GetDeletePlatformVersion_613827(
    name: "getDeletePlatformVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeletePlatformVersion",
    validator: validate_GetDeletePlatformVersion_613828, base: "/",
    url: url_GetDeletePlatformVersion_613829, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAccountAttributes_613875 = ref object of OpenApiRestCall_612659
proc url_PostDescribeAccountAttributes_613877(protocol: Scheme; host: string;
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

proc validate_PostDescribeAccountAttributes_613876(path: JsonNode; query: JsonNode;
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
  var valid_613878 = query.getOrDefault("Action")
  valid_613878 = validateParameter(valid_613878, JString, required = true, default = newJString(
      "DescribeAccountAttributes"))
  if valid_613878 != nil:
    section.add "Action", valid_613878
  var valid_613879 = query.getOrDefault("Version")
  valid_613879 = validateParameter(valid_613879, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_613879 != nil:
    section.add "Version", valid_613879
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
  var valid_613880 = header.getOrDefault("X-Amz-Signature")
  valid_613880 = validateParameter(valid_613880, JString, required = false,
                                 default = nil)
  if valid_613880 != nil:
    section.add "X-Amz-Signature", valid_613880
  var valid_613881 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613881 = validateParameter(valid_613881, JString, required = false,
                                 default = nil)
  if valid_613881 != nil:
    section.add "X-Amz-Content-Sha256", valid_613881
  var valid_613882 = header.getOrDefault("X-Amz-Date")
  valid_613882 = validateParameter(valid_613882, JString, required = false,
                                 default = nil)
  if valid_613882 != nil:
    section.add "X-Amz-Date", valid_613882
  var valid_613883 = header.getOrDefault("X-Amz-Credential")
  valid_613883 = validateParameter(valid_613883, JString, required = false,
                                 default = nil)
  if valid_613883 != nil:
    section.add "X-Amz-Credential", valid_613883
  var valid_613884 = header.getOrDefault("X-Amz-Security-Token")
  valid_613884 = validateParameter(valid_613884, JString, required = false,
                                 default = nil)
  if valid_613884 != nil:
    section.add "X-Amz-Security-Token", valid_613884
  var valid_613885 = header.getOrDefault("X-Amz-Algorithm")
  valid_613885 = validateParameter(valid_613885, JString, required = false,
                                 default = nil)
  if valid_613885 != nil:
    section.add "X-Amz-Algorithm", valid_613885
  var valid_613886 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613886 = validateParameter(valid_613886, JString, required = false,
                                 default = nil)
  if valid_613886 != nil:
    section.add "X-Amz-SignedHeaders", valid_613886
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613887: Call_PostDescribeAccountAttributes_613875; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ## 
  let valid = call_613887.validator(path, query, header, formData, body)
  let scheme = call_613887.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613887.url(scheme.get, call_613887.host, call_613887.base,
                         call_613887.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613887, url, valid)

proc call*(call_613888: Call_PostDescribeAccountAttributes_613875;
          Action: string = "DescribeAccountAttributes";
          Version: string = "2010-12-01"): Recallable =
  ## postDescribeAccountAttributes
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613889 = newJObject()
  add(query_613889, "Action", newJString(Action))
  add(query_613889, "Version", newJString(Version))
  result = call_613888.call(nil, query_613889, nil, nil, nil)

var postDescribeAccountAttributes* = Call_PostDescribeAccountAttributes_613875(
    name: "postDescribeAccountAttributes", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeAccountAttributes",
    validator: validate_PostDescribeAccountAttributes_613876, base: "/",
    url: url_PostDescribeAccountAttributes_613877,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAccountAttributes_613860 = ref object of OpenApiRestCall_612659
proc url_GetDescribeAccountAttributes_613862(protocol: Scheme; host: string;
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

proc validate_GetDescribeAccountAttributes_613861(path: JsonNode; query: JsonNode;
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
  var valid_613863 = query.getOrDefault("Action")
  valid_613863 = validateParameter(valid_613863, JString, required = true, default = newJString(
      "DescribeAccountAttributes"))
  if valid_613863 != nil:
    section.add "Action", valid_613863
  var valid_613864 = query.getOrDefault("Version")
  valid_613864 = validateParameter(valid_613864, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_613864 != nil:
    section.add "Version", valid_613864
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
  var valid_613865 = header.getOrDefault("X-Amz-Signature")
  valid_613865 = validateParameter(valid_613865, JString, required = false,
                                 default = nil)
  if valid_613865 != nil:
    section.add "X-Amz-Signature", valid_613865
  var valid_613866 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613866 = validateParameter(valid_613866, JString, required = false,
                                 default = nil)
  if valid_613866 != nil:
    section.add "X-Amz-Content-Sha256", valid_613866
  var valid_613867 = header.getOrDefault("X-Amz-Date")
  valid_613867 = validateParameter(valid_613867, JString, required = false,
                                 default = nil)
  if valid_613867 != nil:
    section.add "X-Amz-Date", valid_613867
  var valid_613868 = header.getOrDefault("X-Amz-Credential")
  valid_613868 = validateParameter(valid_613868, JString, required = false,
                                 default = nil)
  if valid_613868 != nil:
    section.add "X-Amz-Credential", valid_613868
  var valid_613869 = header.getOrDefault("X-Amz-Security-Token")
  valid_613869 = validateParameter(valid_613869, JString, required = false,
                                 default = nil)
  if valid_613869 != nil:
    section.add "X-Amz-Security-Token", valid_613869
  var valid_613870 = header.getOrDefault("X-Amz-Algorithm")
  valid_613870 = validateParameter(valid_613870, JString, required = false,
                                 default = nil)
  if valid_613870 != nil:
    section.add "X-Amz-Algorithm", valid_613870
  var valid_613871 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613871 = validateParameter(valid_613871, JString, required = false,
                                 default = nil)
  if valid_613871 != nil:
    section.add "X-Amz-SignedHeaders", valid_613871
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613872: Call_GetDescribeAccountAttributes_613860; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ## 
  let valid = call_613872.validator(path, query, header, formData, body)
  let scheme = call_613872.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613872.url(scheme.get, call_613872.host, call_613872.base,
                         call_613872.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613872, url, valid)

proc call*(call_613873: Call_GetDescribeAccountAttributes_613860;
          Action: string = "DescribeAccountAttributes";
          Version: string = "2010-12-01"): Recallable =
  ## getDescribeAccountAttributes
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613874 = newJObject()
  add(query_613874, "Action", newJString(Action))
  add(query_613874, "Version", newJString(Version))
  result = call_613873.call(nil, query_613874, nil, nil, nil)

var getDescribeAccountAttributes* = Call_GetDescribeAccountAttributes_613860(
    name: "getDescribeAccountAttributes", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeAccountAttributes",
    validator: validate_GetDescribeAccountAttributes_613861, base: "/",
    url: url_GetDescribeAccountAttributes_613862,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeApplicationVersions_613909 = ref object of OpenApiRestCall_612659
proc url_PostDescribeApplicationVersions_613911(protocol: Scheme; host: string;
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

proc validate_PostDescribeApplicationVersions_613910(path: JsonNode;
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
  var valid_613912 = query.getOrDefault("Action")
  valid_613912 = validateParameter(valid_613912, JString, required = true, default = newJString(
      "DescribeApplicationVersions"))
  if valid_613912 != nil:
    section.add "Action", valid_613912
  var valid_613913 = query.getOrDefault("Version")
  valid_613913 = validateParameter(valid_613913, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_613913 != nil:
    section.add "Version", valid_613913
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
  var valid_613914 = header.getOrDefault("X-Amz-Signature")
  valid_613914 = validateParameter(valid_613914, JString, required = false,
                                 default = nil)
  if valid_613914 != nil:
    section.add "X-Amz-Signature", valid_613914
  var valid_613915 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613915 = validateParameter(valid_613915, JString, required = false,
                                 default = nil)
  if valid_613915 != nil:
    section.add "X-Amz-Content-Sha256", valid_613915
  var valid_613916 = header.getOrDefault("X-Amz-Date")
  valid_613916 = validateParameter(valid_613916, JString, required = false,
                                 default = nil)
  if valid_613916 != nil:
    section.add "X-Amz-Date", valid_613916
  var valid_613917 = header.getOrDefault("X-Amz-Credential")
  valid_613917 = validateParameter(valid_613917, JString, required = false,
                                 default = nil)
  if valid_613917 != nil:
    section.add "X-Amz-Credential", valid_613917
  var valid_613918 = header.getOrDefault("X-Amz-Security-Token")
  valid_613918 = validateParameter(valid_613918, JString, required = false,
                                 default = nil)
  if valid_613918 != nil:
    section.add "X-Amz-Security-Token", valid_613918
  var valid_613919 = header.getOrDefault("X-Amz-Algorithm")
  valid_613919 = validateParameter(valid_613919, JString, required = false,
                                 default = nil)
  if valid_613919 != nil:
    section.add "X-Amz-Algorithm", valid_613919
  var valid_613920 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613920 = validateParameter(valid_613920, JString, required = false,
                                 default = nil)
  if valid_613920 != nil:
    section.add "X-Amz-SignedHeaders", valid_613920
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
  var valid_613921 = formData.getOrDefault("NextToken")
  valid_613921 = validateParameter(valid_613921, JString, required = false,
                                 default = nil)
  if valid_613921 != nil:
    section.add "NextToken", valid_613921
  var valid_613922 = formData.getOrDefault("MaxRecords")
  valid_613922 = validateParameter(valid_613922, JInt, required = false, default = nil)
  if valid_613922 != nil:
    section.add "MaxRecords", valid_613922
  var valid_613923 = formData.getOrDefault("VersionLabels")
  valid_613923 = validateParameter(valid_613923, JArray, required = false,
                                 default = nil)
  if valid_613923 != nil:
    section.add "VersionLabels", valid_613923
  var valid_613924 = formData.getOrDefault("ApplicationName")
  valid_613924 = validateParameter(valid_613924, JString, required = false,
                                 default = nil)
  if valid_613924 != nil:
    section.add "ApplicationName", valid_613924
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613925: Call_PostDescribeApplicationVersions_613909;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieve a list of application versions.
  ## 
  let valid = call_613925.validator(path, query, header, formData, body)
  let scheme = call_613925.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613925.url(scheme.get, call_613925.host, call_613925.base,
                         call_613925.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613925, url, valid)

proc call*(call_613926: Call_PostDescribeApplicationVersions_613909;
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
  var query_613927 = newJObject()
  var formData_613928 = newJObject()
  add(formData_613928, "NextToken", newJString(NextToken))
  add(formData_613928, "MaxRecords", newJInt(MaxRecords))
  if VersionLabels != nil:
    formData_613928.add "VersionLabels", VersionLabels
  add(formData_613928, "ApplicationName", newJString(ApplicationName))
  add(query_613927, "Action", newJString(Action))
  add(query_613927, "Version", newJString(Version))
  result = call_613926.call(nil, query_613927, nil, formData_613928, nil)

var postDescribeApplicationVersions* = Call_PostDescribeApplicationVersions_613909(
    name: "postDescribeApplicationVersions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplicationVersions",
    validator: validate_PostDescribeApplicationVersions_613910, base: "/",
    url: url_PostDescribeApplicationVersions_613911,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeApplicationVersions_613890 = ref object of OpenApiRestCall_612659
proc url_GetDescribeApplicationVersions_613892(protocol: Scheme; host: string;
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

proc validate_GetDescribeApplicationVersions_613891(path: JsonNode;
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
  var valid_613893 = query.getOrDefault("ApplicationName")
  valid_613893 = validateParameter(valid_613893, JString, required = false,
                                 default = nil)
  if valid_613893 != nil:
    section.add "ApplicationName", valid_613893
  var valid_613894 = query.getOrDefault("NextToken")
  valid_613894 = validateParameter(valid_613894, JString, required = false,
                                 default = nil)
  if valid_613894 != nil:
    section.add "NextToken", valid_613894
  var valid_613895 = query.getOrDefault("VersionLabels")
  valid_613895 = validateParameter(valid_613895, JArray, required = false,
                                 default = nil)
  if valid_613895 != nil:
    section.add "VersionLabels", valid_613895
  var valid_613896 = query.getOrDefault("Action")
  valid_613896 = validateParameter(valid_613896, JString, required = true, default = newJString(
      "DescribeApplicationVersions"))
  if valid_613896 != nil:
    section.add "Action", valid_613896
  var valid_613897 = query.getOrDefault("Version")
  valid_613897 = validateParameter(valid_613897, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_613897 != nil:
    section.add "Version", valid_613897
  var valid_613898 = query.getOrDefault("MaxRecords")
  valid_613898 = validateParameter(valid_613898, JInt, required = false, default = nil)
  if valid_613898 != nil:
    section.add "MaxRecords", valid_613898
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
  var valid_613899 = header.getOrDefault("X-Amz-Signature")
  valid_613899 = validateParameter(valid_613899, JString, required = false,
                                 default = nil)
  if valid_613899 != nil:
    section.add "X-Amz-Signature", valid_613899
  var valid_613900 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613900 = validateParameter(valid_613900, JString, required = false,
                                 default = nil)
  if valid_613900 != nil:
    section.add "X-Amz-Content-Sha256", valid_613900
  var valid_613901 = header.getOrDefault("X-Amz-Date")
  valid_613901 = validateParameter(valid_613901, JString, required = false,
                                 default = nil)
  if valid_613901 != nil:
    section.add "X-Amz-Date", valid_613901
  var valid_613902 = header.getOrDefault("X-Amz-Credential")
  valid_613902 = validateParameter(valid_613902, JString, required = false,
                                 default = nil)
  if valid_613902 != nil:
    section.add "X-Amz-Credential", valid_613902
  var valid_613903 = header.getOrDefault("X-Amz-Security-Token")
  valid_613903 = validateParameter(valid_613903, JString, required = false,
                                 default = nil)
  if valid_613903 != nil:
    section.add "X-Amz-Security-Token", valid_613903
  var valid_613904 = header.getOrDefault("X-Amz-Algorithm")
  valid_613904 = validateParameter(valid_613904, JString, required = false,
                                 default = nil)
  if valid_613904 != nil:
    section.add "X-Amz-Algorithm", valid_613904
  var valid_613905 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613905 = validateParameter(valid_613905, JString, required = false,
                                 default = nil)
  if valid_613905 != nil:
    section.add "X-Amz-SignedHeaders", valid_613905
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613906: Call_GetDescribeApplicationVersions_613890; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a list of application versions.
  ## 
  let valid = call_613906.validator(path, query, header, formData, body)
  let scheme = call_613906.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613906.url(scheme.get, call_613906.host, call_613906.base,
                         call_613906.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613906, url, valid)

proc call*(call_613907: Call_GetDescribeApplicationVersions_613890;
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
  var query_613908 = newJObject()
  add(query_613908, "ApplicationName", newJString(ApplicationName))
  add(query_613908, "NextToken", newJString(NextToken))
  if VersionLabels != nil:
    query_613908.add "VersionLabels", VersionLabels
  add(query_613908, "Action", newJString(Action))
  add(query_613908, "Version", newJString(Version))
  add(query_613908, "MaxRecords", newJInt(MaxRecords))
  result = call_613907.call(nil, query_613908, nil, nil, nil)

var getDescribeApplicationVersions* = Call_GetDescribeApplicationVersions_613890(
    name: "getDescribeApplicationVersions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplicationVersions",
    validator: validate_GetDescribeApplicationVersions_613891, base: "/",
    url: url_GetDescribeApplicationVersions_613892,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeApplications_613945 = ref object of OpenApiRestCall_612659
proc url_PostDescribeApplications_613947(protocol: Scheme; host: string;
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

proc validate_PostDescribeApplications_613946(path: JsonNode; query: JsonNode;
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
  var valid_613948 = query.getOrDefault("Action")
  valid_613948 = validateParameter(valid_613948, JString, required = true,
                                 default = newJString("DescribeApplications"))
  if valid_613948 != nil:
    section.add "Action", valid_613948
  var valid_613949 = query.getOrDefault("Version")
  valid_613949 = validateParameter(valid_613949, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_613949 != nil:
    section.add "Version", valid_613949
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
  var valid_613950 = header.getOrDefault("X-Amz-Signature")
  valid_613950 = validateParameter(valid_613950, JString, required = false,
                                 default = nil)
  if valid_613950 != nil:
    section.add "X-Amz-Signature", valid_613950
  var valid_613951 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613951 = validateParameter(valid_613951, JString, required = false,
                                 default = nil)
  if valid_613951 != nil:
    section.add "X-Amz-Content-Sha256", valid_613951
  var valid_613952 = header.getOrDefault("X-Amz-Date")
  valid_613952 = validateParameter(valid_613952, JString, required = false,
                                 default = nil)
  if valid_613952 != nil:
    section.add "X-Amz-Date", valid_613952
  var valid_613953 = header.getOrDefault("X-Amz-Credential")
  valid_613953 = validateParameter(valid_613953, JString, required = false,
                                 default = nil)
  if valid_613953 != nil:
    section.add "X-Amz-Credential", valid_613953
  var valid_613954 = header.getOrDefault("X-Amz-Security-Token")
  valid_613954 = validateParameter(valid_613954, JString, required = false,
                                 default = nil)
  if valid_613954 != nil:
    section.add "X-Amz-Security-Token", valid_613954
  var valid_613955 = header.getOrDefault("X-Amz-Algorithm")
  valid_613955 = validateParameter(valid_613955, JString, required = false,
                                 default = nil)
  if valid_613955 != nil:
    section.add "X-Amz-Algorithm", valid_613955
  var valid_613956 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613956 = validateParameter(valid_613956, JString, required = false,
                                 default = nil)
  if valid_613956 != nil:
    section.add "X-Amz-SignedHeaders", valid_613956
  result.add "header", section
  ## parameters in `formData` object:
  ##   ApplicationNames: JArray
  ##                   : If specified, AWS Elastic Beanstalk restricts the returned descriptions to only include those with the specified names.
  section = newJObject()
  var valid_613957 = formData.getOrDefault("ApplicationNames")
  valid_613957 = validateParameter(valid_613957, JArray, required = false,
                                 default = nil)
  if valid_613957 != nil:
    section.add "ApplicationNames", valid_613957
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613958: Call_PostDescribeApplications_613945; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the descriptions of existing applications.
  ## 
  let valid = call_613958.validator(path, query, header, formData, body)
  let scheme = call_613958.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613958.url(scheme.get, call_613958.host, call_613958.base,
                         call_613958.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613958, url, valid)

proc call*(call_613959: Call_PostDescribeApplications_613945;
          ApplicationNames: JsonNode = nil; Action: string = "DescribeApplications";
          Version: string = "2010-12-01"): Recallable =
  ## postDescribeApplications
  ## Returns the descriptions of existing applications.
  ##   ApplicationNames: JArray
  ##                   : If specified, AWS Elastic Beanstalk restricts the returned descriptions to only include those with the specified names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613960 = newJObject()
  var formData_613961 = newJObject()
  if ApplicationNames != nil:
    formData_613961.add "ApplicationNames", ApplicationNames
  add(query_613960, "Action", newJString(Action))
  add(query_613960, "Version", newJString(Version))
  result = call_613959.call(nil, query_613960, nil, formData_613961, nil)

var postDescribeApplications* = Call_PostDescribeApplications_613945(
    name: "postDescribeApplications", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplications",
    validator: validate_PostDescribeApplications_613946, base: "/",
    url: url_PostDescribeApplications_613947, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeApplications_613929 = ref object of OpenApiRestCall_612659
proc url_GetDescribeApplications_613931(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
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

proc validate_GetDescribeApplications_613930(path: JsonNode; query: JsonNode;
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
  var valid_613932 = query.getOrDefault("ApplicationNames")
  valid_613932 = validateParameter(valid_613932, JArray, required = false,
                                 default = nil)
  if valid_613932 != nil:
    section.add "ApplicationNames", valid_613932
  var valid_613933 = query.getOrDefault("Action")
  valid_613933 = validateParameter(valid_613933, JString, required = true,
                                 default = newJString("DescribeApplications"))
  if valid_613933 != nil:
    section.add "Action", valid_613933
  var valid_613934 = query.getOrDefault("Version")
  valid_613934 = validateParameter(valid_613934, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_613934 != nil:
    section.add "Version", valid_613934
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
  var valid_613935 = header.getOrDefault("X-Amz-Signature")
  valid_613935 = validateParameter(valid_613935, JString, required = false,
                                 default = nil)
  if valid_613935 != nil:
    section.add "X-Amz-Signature", valid_613935
  var valid_613936 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613936 = validateParameter(valid_613936, JString, required = false,
                                 default = nil)
  if valid_613936 != nil:
    section.add "X-Amz-Content-Sha256", valid_613936
  var valid_613937 = header.getOrDefault("X-Amz-Date")
  valid_613937 = validateParameter(valid_613937, JString, required = false,
                                 default = nil)
  if valid_613937 != nil:
    section.add "X-Amz-Date", valid_613937
  var valid_613938 = header.getOrDefault("X-Amz-Credential")
  valid_613938 = validateParameter(valid_613938, JString, required = false,
                                 default = nil)
  if valid_613938 != nil:
    section.add "X-Amz-Credential", valid_613938
  var valid_613939 = header.getOrDefault("X-Amz-Security-Token")
  valid_613939 = validateParameter(valid_613939, JString, required = false,
                                 default = nil)
  if valid_613939 != nil:
    section.add "X-Amz-Security-Token", valid_613939
  var valid_613940 = header.getOrDefault("X-Amz-Algorithm")
  valid_613940 = validateParameter(valid_613940, JString, required = false,
                                 default = nil)
  if valid_613940 != nil:
    section.add "X-Amz-Algorithm", valid_613940
  var valid_613941 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613941 = validateParameter(valid_613941, JString, required = false,
                                 default = nil)
  if valid_613941 != nil:
    section.add "X-Amz-SignedHeaders", valid_613941
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613942: Call_GetDescribeApplications_613929; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the descriptions of existing applications.
  ## 
  let valid = call_613942.validator(path, query, header, formData, body)
  let scheme = call_613942.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613942.url(scheme.get, call_613942.host, call_613942.base,
                         call_613942.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613942, url, valid)

proc call*(call_613943: Call_GetDescribeApplications_613929;
          ApplicationNames: JsonNode = nil; Action: string = "DescribeApplications";
          Version: string = "2010-12-01"): Recallable =
  ## getDescribeApplications
  ## Returns the descriptions of existing applications.
  ##   ApplicationNames: JArray
  ##                   : If specified, AWS Elastic Beanstalk restricts the returned descriptions to only include those with the specified names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_613944 = newJObject()
  if ApplicationNames != nil:
    query_613944.add "ApplicationNames", ApplicationNames
  add(query_613944, "Action", newJString(Action))
  add(query_613944, "Version", newJString(Version))
  result = call_613943.call(nil, query_613944, nil, nil, nil)

var getDescribeApplications* = Call_GetDescribeApplications_613929(
    name: "getDescribeApplications", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplications",
    validator: validate_GetDescribeApplications_613930, base: "/",
    url: url_GetDescribeApplications_613931, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeConfigurationOptions_613983 = ref object of OpenApiRestCall_612659
proc url_PostDescribeConfigurationOptions_613985(protocol: Scheme; host: string;
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

proc validate_PostDescribeConfigurationOptions_613984(path: JsonNode;
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
  var valid_613986 = query.getOrDefault("Action")
  valid_613986 = validateParameter(valid_613986, JString, required = true, default = newJString(
      "DescribeConfigurationOptions"))
  if valid_613986 != nil:
    section.add "Action", valid_613986
  var valid_613987 = query.getOrDefault("Version")
  valid_613987 = validateParameter(valid_613987, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_613987 != nil:
    section.add "Version", valid_613987
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
  var valid_613988 = header.getOrDefault("X-Amz-Signature")
  valid_613988 = validateParameter(valid_613988, JString, required = false,
                                 default = nil)
  if valid_613988 != nil:
    section.add "X-Amz-Signature", valid_613988
  var valid_613989 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613989 = validateParameter(valid_613989, JString, required = false,
                                 default = nil)
  if valid_613989 != nil:
    section.add "X-Amz-Content-Sha256", valid_613989
  var valid_613990 = header.getOrDefault("X-Amz-Date")
  valid_613990 = validateParameter(valid_613990, JString, required = false,
                                 default = nil)
  if valid_613990 != nil:
    section.add "X-Amz-Date", valid_613990
  var valid_613991 = header.getOrDefault("X-Amz-Credential")
  valid_613991 = validateParameter(valid_613991, JString, required = false,
                                 default = nil)
  if valid_613991 != nil:
    section.add "X-Amz-Credential", valid_613991
  var valid_613992 = header.getOrDefault("X-Amz-Security-Token")
  valid_613992 = validateParameter(valid_613992, JString, required = false,
                                 default = nil)
  if valid_613992 != nil:
    section.add "X-Amz-Security-Token", valid_613992
  var valid_613993 = header.getOrDefault("X-Amz-Algorithm")
  valid_613993 = validateParameter(valid_613993, JString, required = false,
                                 default = nil)
  if valid_613993 != nil:
    section.add "X-Amz-Algorithm", valid_613993
  var valid_613994 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613994 = validateParameter(valid_613994, JString, required = false,
                                 default = nil)
  if valid_613994 != nil:
    section.add "X-Amz-SignedHeaders", valid_613994
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
  var valid_613995 = formData.getOrDefault("EnvironmentName")
  valid_613995 = validateParameter(valid_613995, JString, required = false,
                                 default = nil)
  if valid_613995 != nil:
    section.add "EnvironmentName", valid_613995
  var valid_613996 = formData.getOrDefault("TemplateName")
  valid_613996 = validateParameter(valid_613996, JString, required = false,
                                 default = nil)
  if valid_613996 != nil:
    section.add "TemplateName", valid_613996
  var valid_613997 = formData.getOrDefault("Options")
  valid_613997 = validateParameter(valid_613997, JArray, required = false,
                                 default = nil)
  if valid_613997 != nil:
    section.add "Options", valid_613997
  var valid_613998 = formData.getOrDefault("ApplicationName")
  valid_613998 = validateParameter(valid_613998, JString, required = false,
                                 default = nil)
  if valid_613998 != nil:
    section.add "ApplicationName", valid_613998
  var valid_613999 = formData.getOrDefault("SolutionStackName")
  valid_613999 = validateParameter(valid_613999, JString, required = false,
                                 default = nil)
  if valid_613999 != nil:
    section.add "SolutionStackName", valid_613999
  var valid_614000 = formData.getOrDefault("PlatformArn")
  valid_614000 = validateParameter(valid_614000, JString, required = false,
                                 default = nil)
  if valid_614000 != nil:
    section.add "PlatformArn", valid_614000
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614001: Call_PostDescribeConfigurationOptions_613983;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the configuration options that are used in a particular configuration template or environment, or that a specified solution stack defines. The description includes the values the options, their default values, and an indication of the required action on a running environment if an option value is changed.
  ## 
  let valid = call_614001.validator(path, query, header, formData, body)
  let scheme = call_614001.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614001.url(scheme.get, call_614001.host, call_614001.base,
                         call_614001.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614001, url, valid)

proc call*(call_614002: Call_PostDescribeConfigurationOptions_613983;
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
  var query_614003 = newJObject()
  var formData_614004 = newJObject()
  add(formData_614004, "EnvironmentName", newJString(EnvironmentName))
  add(formData_614004, "TemplateName", newJString(TemplateName))
  if Options != nil:
    formData_614004.add "Options", Options
  add(formData_614004, "ApplicationName", newJString(ApplicationName))
  add(query_614003, "Action", newJString(Action))
  add(formData_614004, "SolutionStackName", newJString(SolutionStackName))
  add(query_614003, "Version", newJString(Version))
  add(formData_614004, "PlatformArn", newJString(PlatformArn))
  result = call_614002.call(nil, query_614003, nil, formData_614004, nil)

var postDescribeConfigurationOptions* = Call_PostDescribeConfigurationOptions_613983(
    name: "postDescribeConfigurationOptions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationOptions",
    validator: validate_PostDescribeConfigurationOptions_613984, base: "/",
    url: url_PostDescribeConfigurationOptions_613985,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeConfigurationOptions_613962 = ref object of OpenApiRestCall_612659
proc url_GetDescribeConfigurationOptions_613964(protocol: Scheme; host: string;
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

proc validate_GetDescribeConfigurationOptions_613963(path: JsonNode;
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
  var valid_613965 = query.getOrDefault("ApplicationName")
  valid_613965 = validateParameter(valid_613965, JString, required = false,
                                 default = nil)
  if valid_613965 != nil:
    section.add "ApplicationName", valid_613965
  var valid_613966 = query.getOrDefault("Options")
  valid_613966 = validateParameter(valid_613966, JArray, required = false,
                                 default = nil)
  if valid_613966 != nil:
    section.add "Options", valid_613966
  var valid_613967 = query.getOrDefault("SolutionStackName")
  valid_613967 = validateParameter(valid_613967, JString, required = false,
                                 default = nil)
  if valid_613967 != nil:
    section.add "SolutionStackName", valid_613967
  var valid_613968 = query.getOrDefault("EnvironmentName")
  valid_613968 = validateParameter(valid_613968, JString, required = false,
                                 default = nil)
  if valid_613968 != nil:
    section.add "EnvironmentName", valid_613968
  var valid_613969 = query.getOrDefault("Action")
  valid_613969 = validateParameter(valid_613969, JString, required = true, default = newJString(
      "DescribeConfigurationOptions"))
  if valid_613969 != nil:
    section.add "Action", valid_613969
  var valid_613970 = query.getOrDefault("PlatformArn")
  valid_613970 = validateParameter(valid_613970, JString, required = false,
                                 default = nil)
  if valid_613970 != nil:
    section.add "PlatformArn", valid_613970
  var valid_613971 = query.getOrDefault("Version")
  valid_613971 = validateParameter(valid_613971, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_613971 != nil:
    section.add "Version", valid_613971
  var valid_613972 = query.getOrDefault("TemplateName")
  valid_613972 = validateParameter(valid_613972, JString, required = false,
                                 default = nil)
  if valid_613972 != nil:
    section.add "TemplateName", valid_613972
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
  var valid_613973 = header.getOrDefault("X-Amz-Signature")
  valid_613973 = validateParameter(valid_613973, JString, required = false,
                                 default = nil)
  if valid_613973 != nil:
    section.add "X-Amz-Signature", valid_613973
  var valid_613974 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613974 = validateParameter(valid_613974, JString, required = false,
                                 default = nil)
  if valid_613974 != nil:
    section.add "X-Amz-Content-Sha256", valid_613974
  var valid_613975 = header.getOrDefault("X-Amz-Date")
  valid_613975 = validateParameter(valid_613975, JString, required = false,
                                 default = nil)
  if valid_613975 != nil:
    section.add "X-Amz-Date", valid_613975
  var valid_613976 = header.getOrDefault("X-Amz-Credential")
  valid_613976 = validateParameter(valid_613976, JString, required = false,
                                 default = nil)
  if valid_613976 != nil:
    section.add "X-Amz-Credential", valid_613976
  var valid_613977 = header.getOrDefault("X-Amz-Security-Token")
  valid_613977 = validateParameter(valid_613977, JString, required = false,
                                 default = nil)
  if valid_613977 != nil:
    section.add "X-Amz-Security-Token", valid_613977
  var valid_613978 = header.getOrDefault("X-Amz-Algorithm")
  valid_613978 = validateParameter(valid_613978, JString, required = false,
                                 default = nil)
  if valid_613978 != nil:
    section.add "X-Amz-Algorithm", valid_613978
  var valid_613979 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613979 = validateParameter(valid_613979, JString, required = false,
                                 default = nil)
  if valid_613979 != nil:
    section.add "X-Amz-SignedHeaders", valid_613979
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613980: Call_GetDescribeConfigurationOptions_613962;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the configuration options that are used in a particular configuration template or environment, or that a specified solution stack defines. The description includes the values the options, their default values, and an indication of the required action on a running environment if an option value is changed.
  ## 
  let valid = call_613980.validator(path, query, header, formData, body)
  let scheme = call_613980.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613980.url(scheme.get, call_613980.host, call_613980.base,
                         call_613980.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613980, url, valid)

proc call*(call_613981: Call_GetDescribeConfigurationOptions_613962;
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
  var query_613982 = newJObject()
  add(query_613982, "ApplicationName", newJString(ApplicationName))
  if Options != nil:
    query_613982.add "Options", Options
  add(query_613982, "SolutionStackName", newJString(SolutionStackName))
  add(query_613982, "EnvironmentName", newJString(EnvironmentName))
  add(query_613982, "Action", newJString(Action))
  add(query_613982, "PlatformArn", newJString(PlatformArn))
  add(query_613982, "Version", newJString(Version))
  add(query_613982, "TemplateName", newJString(TemplateName))
  result = call_613981.call(nil, query_613982, nil, nil, nil)

var getDescribeConfigurationOptions* = Call_GetDescribeConfigurationOptions_613962(
    name: "getDescribeConfigurationOptions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationOptions",
    validator: validate_GetDescribeConfigurationOptions_613963, base: "/",
    url: url_GetDescribeConfigurationOptions_613964,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeConfigurationSettings_614023 = ref object of OpenApiRestCall_612659
proc url_PostDescribeConfigurationSettings_614025(protocol: Scheme; host: string;
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

proc validate_PostDescribeConfigurationSettings_614024(path: JsonNode;
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
  var valid_614026 = query.getOrDefault("Action")
  valid_614026 = validateParameter(valid_614026, JString, required = true, default = newJString(
      "DescribeConfigurationSettings"))
  if valid_614026 != nil:
    section.add "Action", valid_614026
  var valid_614027 = query.getOrDefault("Version")
  valid_614027 = validateParameter(valid_614027, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614027 != nil:
    section.add "Version", valid_614027
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
  var valid_614028 = header.getOrDefault("X-Amz-Signature")
  valid_614028 = validateParameter(valid_614028, JString, required = false,
                                 default = nil)
  if valid_614028 != nil:
    section.add "X-Amz-Signature", valid_614028
  var valid_614029 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614029 = validateParameter(valid_614029, JString, required = false,
                                 default = nil)
  if valid_614029 != nil:
    section.add "X-Amz-Content-Sha256", valid_614029
  var valid_614030 = header.getOrDefault("X-Amz-Date")
  valid_614030 = validateParameter(valid_614030, JString, required = false,
                                 default = nil)
  if valid_614030 != nil:
    section.add "X-Amz-Date", valid_614030
  var valid_614031 = header.getOrDefault("X-Amz-Credential")
  valid_614031 = validateParameter(valid_614031, JString, required = false,
                                 default = nil)
  if valid_614031 != nil:
    section.add "X-Amz-Credential", valid_614031
  var valid_614032 = header.getOrDefault("X-Amz-Security-Token")
  valid_614032 = validateParameter(valid_614032, JString, required = false,
                                 default = nil)
  if valid_614032 != nil:
    section.add "X-Amz-Security-Token", valid_614032
  var valid_614033 = header.getOrDefault("X-Amz-Algorithm")
  valid_614033 = validateParameter(valid_614033, JString, required = false,
                                 default = nil)
  if valid_614033 != nil:
    section.add "X-Amz-Algorithm", valid_614033
  var valid_614034 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614034 = validateParameter(valid_614034, JString, required = false,
                                 default = nil)
  if valid_614034 != nil:
    section.add "X-Amz-SignedHeaders", valid_614034
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to describe.</p> <p> Condition: You must specify either this or a TemplateName, but not both. If you specify both, AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   TemplateName: JString
  ##               : <p>The name of the configuration template to describe.</p> <p> Conditional: You must specify either this parameter or an EnvironmentName, but not both. If you specify both, AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. If you do not specify either, AWS Elastic Beanstalk returns a <code>MissingRequiredParameter</code> error. </p>
  ##   ApplicationName: JString (required)
  ##                  : The application for the environment or configuration template.
  section = newJObject()
  var valid_614035 = formData.getOrDefault("EnvironmentName")
  valid_614035 = validateParameter(valid_614035, JString, required = false,
                                 default = nil)
  if valid_614035 != nil:
    section.add "EnvironmentName", valid_614035
  var valid_614036 = formData.getOrDefault("TemplateName")
  valid_614036 = validateParameter(valid_614036, JString, required = false,
                                 default = nil)
  if valid_614036 != nil:
    section.add "TemplateName", valid_614036
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_614037 = formData.getOrDefault("ApplicationName")
  valid_614037 = validateParameter(valid_614037, JString, required = true,
                                 default = nil)
  if valid_614037 != nil:
    section.add "ApplicationName", valid_614037
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614038: Call_PostDescribeConfigurationSettings_614023;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a description of the settings for the specified configuration set, that is, either a configuration template or the configuration set associated with a running environment.</p> <p>When describing the settings for the configuration set associated with a running environment, it is possible to receive two sets of setting descriptions. One is the deployed configuration set, and the other is a draft configuration of an environment that is either in the process of deployment or that failed to deploy.</p> <p>Related Topics</p> <ul> <li> <p> <a>DeleteEnvironmentConfiguration</a> </p> </li> </ul>
  ## 
  let valid = call_614038.validator(path, query, header, formData, body)
  let scheme = call_614038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614038.url(scheme.get, call_614038.host, call_614038.base,
                         call_614038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614038, url, valid)

proc call*(call_614039: Call_PostDescribeConfigurationSettings_614023;
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
  var query_614040 = newJObject()
  var formData_614041 = newJObject()
  add(formData_614041, "EnvironmentName", newJString(EnvironmentName))
  add(formData_614041, "TemplateName", newJString(TemplateName))
  add(formData_614041, "ApplicationName", newJString(ApplicationName))
  add(query_614040, "Action", newJString(Action))
  add(query_614040, "Version", newJString(Version))
  result = call_614039.call(nil, query_614040, nil, formData_614041, nil)

var postDescribeConfigurationSettings* = Call_PostDescribeConfigurationSettings_614023(
    name: "postDescribeConfigurationSettings", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationSettings",
    validator: validate_PostDescribeConfigurationSettings_614024, base: "/",
    url: url_PostDescribeConfigurationSettings_614025,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeConfigurationSettings_614005 = ref object of OpenApiRestCall_612659
proc url_GetDescribeConfigurationSettings_614007(protocol: Scheme; host: string;
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

proc validate_GetDescribeConfigurationSettings_614006(path: JsonNode;
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
  var valid_614008 = query.getOrDefault("ApplicationName")
  valid_614008 = validateParameter(valid_614008, JString, required = true,
                                 default = nil)
  if valid_614008 != nil:
    section.add "ApplicationName", valid_614008
  var valid_614009 = query.getOrDefault("EnvironmentName")
  valid_614009 = validateParameter(valid_614009, JString, required = false,
                                 default = nil)
  if valid_614009 != nil:
    section.add "EnvironmentName", valid_614009
  var valid_614010 = query.getOrDefault("Action")
  valid_614010 = validateParameter(valid_614010, JString, required = true, default = newJString(
      "DescribeConfigurationSettings"))
  if valid_614010 != nil:
    section.add "Action", valid_614010
  var valid_614011 = query.getOrDefault("Version")
  valid_614011 = validateParameter(valid_614011, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614011 != nil:
    section.add "Version", valid_614011
  var valid_614012 = query.getOrDefault("TemplateName")
  valid_614012 = validateParameter(valid_614012, JString, required = false,
                                 default = nil)
  if valid_614012 != nil:
    section.add "TemplateName", valid_614012
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
  var valid_614013 = header.getOrDefault("X-Amz-Signature")
  valid_614013 = validateParameter(valid_614013, JString, required = false,
                                 default = nil)
  if valid_614013 != nil:
    section.add "X-Amz-Signature", valid_614013
  var valid_614014 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614014 = validateParameter(valid_614014, JString, required = false,
                                 default = nil)
  if valid_614014 != nil:
    section.add "X-Amz-Content-Sha256", valid_614014
  var valid_614015 = header.getOrDefault("X-Amz-Date")
  valid_614015 = validateParameter(valid_614015, JString, required = false,
                                 default = nil)
  if valid_614015 != nil:
    section.add "X-Amz-Date", valid_614015
  var valid_614016 = header.getOrDefault("X-Amz-Credential")
  valid_614016 = validateParameter(valid_614016, JString, required = false,
                                 default = nil)
  if valid_614016 != nil:
    section.add "X-Amz-Credential", valid_614016
  var valid_614017 = header.getOrDefault("X-Amz-Security-Token")
  valid_614017 = validateParameter(valid_614017, JString, required = false,
                                 default = nil)
  if valid_614017 != nil:
    section.add "X-Amz-Security-Token", valid_614017
  var valid_614018 = header.getOrDefault("X-Amz-Algorithm")
  valid_614018 = validateParameter(valid_614018, JString, required = false,
                                 default = nil)
  if valid_614018 != nil:
    section.add "X-Amz-Algorithm", valid_614018
  var valid_614019 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614019 = validateParameter(valid_614019, JString, required = false,
                                 default = nil)
  if valid_614019 != nil:
    section.add "X-Amz-SignedHeaders", valid_614019
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614020: Call_GetDescribeConfigurationSettings_614005;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a description of the settings for the specified configuration set, that is, either a configuration template or the configuration set associated with a running environment.</p> <p>When describing the settings for the configuration set associated with a running environment, it is possible to receive two sets of setting descriptions. One is the deployed configuration set, and the other is a draft configuration of an environment that is either in the process of deployment or that failed to deploy.</p> <p>Related Topics</p> <ul> <li> <p> <a>DeleteEnvironmentConfiguration</a> </p> </li> </ul>
  ## 
  let valid = call_614020.validator(path, query, header, formData, body)
  let scheme = call_614020.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614020.url(scheme.get, call_614020.host, call_614020.base,
                         call_614020.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614020, url, valid)

proc call*(call_614021: Call_GetDescribeConfigurationSettings_614005;
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
  var query_614022 = newJObject()
  add(query_614022, "ApplicationName", newJString(ApplicationName))
  add(query_614022, "EnvironmentName", newJString(EnvironmentName))
  add(query_614022, "Action", newJString(Action))
  add(query_614022, "Version", newJString(Version))
  add(query_614022, "TemplateName", newJString(TemplateName))
  result = call_614021.call(nil, query_614022, nil, nil, nil)

var getDescribeConfigurationSettings* = Call_GetDescribeConfigurationSettings_614005(
    name: "getDescribeConfigurationSettings", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationSettings",
    validator: validate_GetDescribeConfigurationSettings_614006, base: "/",
    url: url_GetDescribeConfigurationSettings_614007,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentHealth_614060 = ref object of OpenApiRestCall_612659
proc url_PostDescribeEnvironmentHealth_614062(protocol: Scheme; host: string;
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

proc validate_PostDescribeEnvironmentHealth_614061(path: JsonNode; query: JsonNode;
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
  var valid_614063 = query.getOrDefault("Action")
  valid_614063 = validateParameter(valid_614063, JString, required = true, default = newJString(
      "DescribeEnvironmentHealth"))
  if valid_614063 != nil:
    section.add "Action", valid_614063
  var valid_614064 = query.getOrDefault("Version")
  valid_614064 = validateParameter(valid_614064, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614064 != nil:
    section.add "Version", valid_614064
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
  var valid_614065 = header.getOrDefault("X-Amz-Signature")
  valid_614065 = validateParameter(valid_614065, JString, required = false,
                                 default = nil)
  if valid_614065 != nil:
    section.add "X-Amz-Signature", valid_614065
  var valid_614066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614066 = validateParameter(valid_614066, JString, required = false,
                                 default = nil)
  if valid_614066 != nil:
    section.add "X-Amz-Content-Sha256", valid_614066
  var valid_614067 = header.getOrDefault("X-Amz-Date")
  valid_614067 = validateParameter(valid_614067, JString, required = false,
                                 default = nil)
  if valid_614067 != nil:
    section.add "X-Amz-Date", valid_614067
  var valid_614068 = header.getOrDefault("X-Amz-Credential")
  valid_614068 = validateParameter(valid_614068, JString, required = false,
                                 default = nil)
  if valid_614068 != nil:
    section.add "X-Amz-Credential", valid_614068
  var valid_614069 = header.getOrDefault("X-Amz-Security-Token")
  valid_614069 = validateParameter(valid_614069, JString, required = false,
                                 default = nil)
  if valid_614069 != nil:
    section.add "X-Amz-Security-Token", valid_614069
  var valid_614070 = header.getOrDefault("X-Amz-Algorithm")
  valid_614070 = validateParameter(valid_614070, JString, required = false,
                                 default = nil)
  if valid_614070 != nil:
    section.add "X-Amz-Algorithm", valid_614070
  var valid_614071 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614071 = validateParameter(valid_614071, JString, required = false,
                                 default = nil)
  if valid_614071 != nil:
    section.add "X-Amz-SignedHeaders", valid_614071
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString
  ##                  : <p>Specify the environment by name.</p> <p>You must specify either this or an EnvironmentName, or both.</p>
  ##   AttributeNames: JArray
  ##                 : Specify the response elements to return. To retrieve all attributes, set to <code>All</code>. If no attribute names are specified, returns the name of the environment.
  ##   EnvironmentId: JString
  ##                : <p>Specify the environment by ID.</p> <p>You must specify either this or an EnvironmentName, or both.</p>
  section = newJObject()
  var valid_614072 = formData.getOrDefault("EnvironmentName")
  valid_614072 = validateParameter(valid_614072, JString, required = false,
                                 default = nil)
  if valid_614072 != nil:
    section.add "EnvironmentName", valid_614072
  var valid_614073 = formData.getOrDefault("AttributeNames")
  valid_614073 = validateParameter(valid_614073, JArray, required = false,
                                 default = nil)
  if valid_614073 != nil:
    section.add "AttributeNames", valid_614073
  var valid_614074 = formData.getOrDefault("EnvironmentId")
  valid_614074 = validateParameter(valid_614074, JString, required = false,
                                 default = nil)
  if valid_614074 != nil:
    section.add "EnvironmentId", valid_614074
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614075: Call_PostDescribeEnvironmentHealth_614060; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the overall health of the specified environment. The <b>DescribeEnvironmentHealth</b> operation is only available with AWS Elastic Beanstalk Enhanced Health.
  ## 
  let valid = call_614075.validator(path, query, header, formData, body)
  let scheme = call_614075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614075.url(scheme.get, call_614075.host, call_614075.base,
                         call_614075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614075, url, valid)

proc call*(call_614076: Call_PostDescribeEnvironmentHealth_614060;
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
  var query_614077 = newJObject()
  var formData_614078 = newJObject()
  add(formData_614078, "EnvironmentName", newJString(EnvironmentName))
  if AttributeNames != nil:
    formData_614078.add "AttributeNames", AttributeNames
  add(query_614077, "Action", newJString(Action))
  add(formData_614078, "EnvironmentId", newJString(EnvironmentId))
  add(query_614077, "Version", newJString(Version))
  result = call_614076.call(nil, query_614077, nil, formData_614078, nil)

var postDescribeEnvironmentHealth* = Call_PostDescribeEnvironmentHealth_614060(
    name: "postDescribeEnvironmentHealth", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentHealth",
    validator: validate_PostDescribeEnvironmentHealth_614061, base: "/",
    url: url_PostDescribeEnvironmentHealth_614062,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentHealth_614042 = ref object of OpenApiRestCall_612659
proc url_GetDescribeEnvironmentHealth_614044(protocol: Scheme; host: string;
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

proc validate_GetDescribeEnvironmentHealth_614043(path: JsonNode; query: JsonNode;
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
  var valid_614045 = query.getOrDefault("AttributeNames")
  valid_614045 = validateParameter(valid_614045, JArray, required = false,
                                 default = nil)
  if valid_614045 != nil:
    section.add "AttributeNames", valid_614045
  var valid_614046 = query.getOrDefault("EnvironmentName")
  valid_614046 = validateParameter(valid_614046, JString, required = false,
                                 default = nil)
  if valid_614046 != nil:
    section.add "EnvironmentName", valid_614046
  var valid_614047 = query.getOrDefault("Action")
  valid_614047 = validateParameter(valid_614047, JString, required = true, default = newJString(
      "DescribeEnvironmentHealth"))
  if valid_614047 != nil:
    section.add "Action", valid_614047
  var valid_614048 = query.getOrDefault("Version")
  valid_614048 = validateParameter(valid_614048, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614048 != nil:
    section.add "Version", valid_614048
  var valid_614049 = query.getOrDefault("EnvironmentId")
  valid_614049 = validateParameter(valid_614049, JString, required = false,
                                 default = nil)
  if valid_614049 != nil:
    section.add "EnvironmentId", valid_614049
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
  var valid_614050 = header.getOrDefault("X-Amz-Signature")
  valid_614050 = validateParameter(valid_614050, JString, required = false,
                                 default = nil)
  if valid_614050 != nil:
    section.add "X-Amz-Signature", valid_614050
  var valid_614051 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614051 = validateParameter(valid_614051, JString, required = false,
                                 default = nil)
  if valid_614051 != nil:
    section.add "X-Amz-Content-Sha256", valid_614051
  var valid_614052 = header.getOrDefault("X-Amz-Date")
  valid_614052 = validateParameter(valid_614052, JString, required = false,
                                 default = nil)
  if valid_614052 != nil:
    section.add "X-Amz-Date", valid_614052
  var valid_614053 = header.getOrDefault("X-Amz-Credential")
  valid_614053 = validateParameter(valid_614053, JString, required = false,
                                 default = nil)
  if valid_614053 != nil:
    section.add "X-Amz-Credential", valid_614053
  var valid_614054 = header.getOrDefault("X-Amz-Security-Token")
  valid_614054 = validateParameter(valid_614054, JString, required = false,
                                 default = nil)
  if valid_614054 != nil:
    section.add "X-Amz-Security-Token", valid_614054
  var valid_614055 = header.getOrDefault("X-Amz-Algorithm")
  valid_614055 = validateParameter(valid_614055, JString, required = false,
                                 default = nil)
  if valid_614055 != nil:
    section.add "X-Amz-Algorithm", valid_614055
  var valid_614056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614056 = validateParameter(valid_614056, JString, required = false,
                                 default = nil)
  if valid_614056 != nil:
    section.add "X-Amz-SignedHeaders", valid_614056
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614057: Call_GetDescribeEnvironmentHealth_614042; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the overall health of the specified environment. The <b>DescribeEnvironmentHealth</b> operation is only available with AWS Elastic Beanstalk Enhanced Health.
  ## 
  let valid = call_614057.validator(path, query, header, formData, body)
  let scheme = call_614057.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614057.url(scheme.get, call_614057.host, call_614057.base,
                         call_614057.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614057, url, valid)

proc call*(call_614058: Call_GetDescribeEnvironmentHealth_614042;
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
  var query_614059 = newJObject()
  if AttributeNames != nil:
    query_614059.add "AttributeNames", AttributeNames
  add(query_614059, "EnvironmentName", newJString(EnvironmentName))
  add(query_614059, "Action", newJString(Action))
  add(query_614059, "Version", newJString(Version))
  add(query_614059, "EnvironmentId", newJString(EnvironmentId))
  result = call_614058.call(nil, query_614059, nil, nil, nil)

var getDescribeEnvironmentHealth* = Call_GetDescribeEnvironmentHealth_614042(
    name: "getDescribeEnvironmentHealth", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentHealth",
    validator: validate_GetDescribeEnvironmentHealth_614043, base: "/",
    url: url_GetDescribeEnvironmentHealth_614044,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentManagedActionHistory_614098 = ref object of OpenApiRestCall_612659
proc url_PostDescribeEnvironmentManagedActionHistory_614100(protocol: Scheme;
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

proc validate_PostDescribeEnvironmentManagedActionHistory_614099(path: JsonNode;
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
  var valid_614101 = query.getOrDefault("Action")
  valid_614101 = validateParameter(valid_614101, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActionHistory"))
  if valid_614101 != nil:
    section.add "Action", valid_614101
  var valid_614102 = query.getOrDefault("Version")
  valid_614102 = validateParameter(valid_614102, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614102 != nil:
    section.add "Version", valid_614102
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
  var valid_614103 = header.getOrDefault("X-Amz-Signature")
  valid_614103 = validateParameter(valid_614103, JString, required = false,
                                 default = nil)
  if valid_614103 != nil:
    section.add "X-Amz-Signature", valid_614103
  var valid_614104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614104 = validateParameter(valid_614104, JString, required = false,
                                 default = nil)
  if valid_614104 != nil:
    section.add "X-Amz-Content-Sha256", valid_614104
  var valid_614105 = header.getOrDefault("X-Amz-Date")
  valid_614105 = validateParameter(valid_614105, JString, required = false,
                                 default = nil)
  if valid_614105 != nil:
    section.add "X-Amz-Date", valid_614105
  var valid_614106 = header.getOrDefault("X-Amz-Credential")
  valid_614106 = validateParameter(valid_614106, JString, required = false,
                                 default = nil)
  if valid_614106 != nil:
    section.add "X-Amz-Credential", valid_614106
  var valid_614107 = header.getOrDefault("X-Amz-Security-Token")
  valid_614107 = validateParameter(valid_614107, JString, required = false,
                                 default = nil)
  if valid_614107 != nil:
    section.add "X-Amz-Security-Token", valid_614107
  var valid_614108 = header.getOrDefault("X-Amz-Algorithm")
  valid_614108 = validateParameter(valid_614108, JString, required = false,
                                 default = nil)
  if valid_614108 != nil:
    section.add "X-Amz-Algorithm", valid_614108
  var valid_614109 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614109 = validateParameter(valid_614109, JString, required = false,
                                 default = nil)
  if valid_614109 != nil:
    section.add "X-Amz-SignedHeaders", valid_614109
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
  var valid_614110 = formData.getOrDefault("NextToken")
  valid_614110 = validateParameter(valid_614110, JString, required = false,
                                 default = nil)
  if valid_614110 != nil:
    section.add "NextToken", valid_614110
  var valid_614111 = formData.getOrDefault("EnvironmentName")
  valid_614111 = validateParameter(valid_614111, JString, required = false,
                                 default = nil)
  if valid_614111 != nil:
    section.add "EnvironmentName", valid_614111
  var valid_614112 = formData.getOrDefault("MaxItems")
  valid_614112 = validateParameter(valid_614112, JInt, required = false, default = nil)
  if valid_614112 != nil:
    section.add "MaxItems", valid_614112
  var valid_614113 = formData.getOrDefault("EnvironmentId")
  valid_614113 = validateParameter(valid_614113, JString, required = false,
                                 default = nil)
  if valid_614113 != nil:
    section.add "EnvironmentId", valid_614113
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614114: Call_PostDescribeEnvironmentManagedActionHistory_614098;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists an environment's completed and failed managed actions.
  ## 
  let valid = call_614114.validator(path, query, header, formData, body)
  let scheme = call_614114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614114.url(scheme.get, call_614114.host, call_614114.base,
                         call_614114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614114, url, valid)

proc call*(call_614115: Call_PostDescribeEnvironmentManagedActionHistory_614098;
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
  var query_614116 = newJObject()
  var formData_614117 = newJObject()
  add(formData_614117, "NextToken", newJString(NextToken))
  add(formData_614117, "EnvironmentName", newJString(EnvironmentName))
  add(query_614116, "Action", newJString(Action))
  add(formData_614117, "MaxItems", newJInt(MaxItems))
  add(formData_614117, "EnvironmentId", newJString(EnvironmentId))
  add(query_614116, "Version", newJString(Version))
  result = call_614115.call(nil, query_614116, nil, formData_614117, nil)

var postDescribeEnvironmentManagedActionHistory* = Call_PostDescribeEnvironmentManagedActionHistory_614098(
    name: "postDescribeEnvironmentManagedActionHistory",
    meth: HttpMethod.HttpPost, host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActionHistory",
    validator: validate_PostDescribeEnvironmentManagedActionHistory_614099,
    base: "/", url: url_PostDescribeEnvironmentManagedActionHistory_614100,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentManagedActionHistory_614079 = ref object of OpenApiRestCall_612659
proc url_GetDescribeEnvironmentManagedActionHistory_614081(protocol: Scheme;
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

proc validate_GetDescribeEnvironmentManagedActionHistory_614080(path: JsonNode;
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
  var valid_614082 = query.getOrDefault("MaxItems")
  valid_614082 = validateParameter(valid_614082, JInt, required = false, default = nil)
  if valid_614082 != nil:
    section.add "MaxItems", valid_614082
  var valid_614083 = query.getOrDefault("NextToken")
  valid_614083 = validateParameter(valid_614083, JString, required = false,
                                 default = nil)
  if valid_614083 != nil:
    section.add "NextToken", valid_614083
  var valid_614084 = query.getOrDefault("EnvironmentName")
  valid_614084 = validateParameter(valid_614084, JString, required = false,
                                 default = nil)
  if valid_614084 != nil:
    section.add "EnvironmentName", valid_614084
  var valid_614085 = query.getOrDefault("Action")
  valid_614085 = validateParameter(valid_614085, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActionHistory"))
  if valid_614085 != nil:
    section.add "Action", valid_614085
  var valid_614086 = query.getOrDefault("Version")
  valid_614086 = validateParameter(valid_614086, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614086 != nil:
    section.add "Version", valid_614086
  var valid_614087 = query.getOrDefault("EnvironmentId")
  valid_614087 = validateParameter(valid_614087, JString, required = false,
                                 default = nil)
  if valid_614087 != nil:
    section.add "EnvironmentId", valid_614087
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
  var valid_614088 = header.getOrDefault("X-Amz-Signature")
  valid_614088 = validateParameter(valid_614088, JString, required = false,
                                 default = nil)
  if valid_614088 != nil:
    section.add "X-Amz-Signature", valid_614088
  var valid_614089 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614089 = validateParameter(valid_614089, JString, required = false,
                                 default = nil)
  if valid_614089 != nil:
    section.add "X-Amz-Content-Sha256", valid_614089
  var valid_614090 = header.getOrDefault("X-Amz-Date")
  valid_614090 = validateParameter(valid_614090, JString, required = false,
                                 default = nil)
  if valid_614090 != nil:
    section.add "X-Amz-Date", valid_614090
  var valid_614091 = header.getOrDefault("X-Amz-Credential")
  valid_614091 = validateParameter(valid_614091, JString, required = false,
                                 default = nil)
  if valid_614091 != nil:
    section.add "X-Amz-Credential", valid_614091
  var valid_614092 = header.getOrDefault("X-Amz-Security-Token")
  valid_614092 = validateParameter(valid_614092, JString, required = false,
                                 default = nil)
  if valid_614092 != nil:
    section.add "X-Amz-Security-Token", valid_614092
  var valid_614093 = header.getOrDefault("X-Amz-Algorithm")
  valid_614093 = validateParameter(valid_614093, JString, required = false,
                                 default = nil)
  if valid_614093 != nil:
    section.add "X-Amz-Algorithm", valid_614093
  var valid_614094 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614094 = validateParameter(valid_614094, JString, required = false,
                                 default = nil)
  if valid_614094 != nil:
    section.add "X-Amz-SignedHeaders", valid_614094
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614095: Call_GetDescribeEnvironmentManagedActionHistory_614079;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists an environment's completed and failed managed actions.
  ## 
  let valid = call_614095.validator(path, query, header, formData, body)
  let scheme = call_614095.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614095.url(scheme.get, call_614095.host, call_614095.base,
                         call_614095.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614095, url, valid)

proc call*(call_614096: Call_GetDescribeEnvironmentManagedActionHistory_614079;
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
  var query_614097 = newJObject()
  add(query_614097, "MaxItems", newJInt(MaxItems))
  add(query_614097, "NextToken", newJString(NextToken))
  add(query_614097, "EnvironmentName", newJString(EnvironmentName))
  add(query_614097, "Action", newJString(Action))
  add(query_614097, "Version", newJString(Version))
  add(query_614097, "EnvironmentId", newJString(EnvironmentId))
  result = call_614096.call(nil, query_614097, nil, nil, nil)

var getDescribeEnvironmentManagedActionHistory* = Call_GetDescribeEnvironmentManagedActionHistory_614079(
    name: "getDescribeEnvironmentManagedActionHistory", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActionHistory",
    validator: validate_GetDescribeEnvironmentManagedActionHistory_614080,
    base: "/", url: url_GetDescribeEnvironmentManagedActionHistory_614081,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentManagedActions_614136 = ref object of OpenApiRestCall_612659
proc url_PostDescribeEnvironmentManagedActions_614138(protocol: Scheme;
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

proc validate_PostDescribeEnvironmentManagedActions_614137(path: JsonNode;
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
  var valid_614139 = query.getOrDefault("Action")
  valid_614139 = validateParameter(valid_614139, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActions"))
  if valid_614139 != nil:
    section.add "Action", valid_614139
  var valid_614140 = query.getOrDefault("Version")
  valid_614140 = validateParameter(valid_614140, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614140 != nil:
    section.add "Version", valid_614140
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
  var valid_614141 = header.getOrDefault("X-Amz-Signature")
  valid_614141 = validateParameter(valid_614141, JString, required = false,
                                 default = nil)
  if valid_614141 != nil:
    section.add "X-Amz-Signature", valid_614141
  var valid_614142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614142 = validateParameter(valid_614142, JString, required = false,
                                 default = nil)
  if valid_614142 != nil:
    section.add "X-Amz-Content-Sha256", valid_614142
  var valid_614143 = header.getOrDefault("X-Amz-Date")
  valid_614143 = validateParameter(valid_614143, JString, required = false,
                                 default = nil)
  if valid_614143 != nil:
    section.add "X-Amz-Date", valid_614143
  var valid_614144 = header.getOrDefault("X-Amz-Credential")
  valid_614144 = validateParameter(valid_614144, JString, required = false,
                                 default = nil)
  if valid_614144 != nil:
    section.add "X-Amz-Credential", valid_614144
  var valid_614145 = header.getOrDefault("X-Amz-Security-Token")
  valid_614145 = validateParameter(valid_614145, JString, required = false,
                                 default = nil)
  if valid_614145 != nil:
    section.add "X-Amz-Security-Token", valid_614145
  var valid_614146 = header.getOrDefault("X-Amz-Algorithm")
  valid_614146 = validateParameter(valid_614146, JString, required = false,
                                 default = nil)
  if valid_614146 != nil:
    section.add "X-Amz-Algorithm", valid_614146
  var valid_614147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614147 = validateParameter(valid_614147, JString, required = false,
                                 default = nil)
  if valid_614147 != nil:
    section.add "X-Amz-SignedHeaders", valid_614147
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString
  ##                  : The name of the target environment.
  ##   Status: JString
  ##         : To show only actions with a particular status, specify a status.
  ##   EnvironmentId: JString
  ##                : The environment ID of the target environment.
  section = newJObject()
  var valid_614148 = formData.getOrDefault("EnvironmentName")
  valid_614148 = validateParameter(valid_614148, JString, required = false,
                                 default = nil)
  if valid_614148 != nil:
    section.add "EnvironmentName", valid_614148
  var valid_614149 = formData.getOrDefault("Status")
  valid_614149 = validateParameter(valid_614149, JString, required = false,
                                 default = newJString("Scheduled"))
  if valid_614149 != nil:
    section.add "Status", valid_614149
  var valid_614150 = formData.getOrDefault("EnvironmentId")
  valid_614150 = validateParameter(valid_614150, JString, required = false,
                                 default = nil)
  if valid_614150 != nil:
    section.add "EnvironmentId", valid_614150
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614151: Call_PostDescribeEnvironmentManagedActions_614136;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists an environment's upcoming and in-progress managed actions.
  ## 
  let valid = call_614151.validator(path, query, header, formData, body)
  let scheme = call_614151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614151.url(scheme.get, call_614151.host, call_614151.base,
                         call_614151.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614151, url, valid)

proc call*(call_614152: Call_PostDescribeEnvironmentManagedActions_614136;
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
  var query_614153 = newJObject()
  var formData_614154 = newJObject()
  add(formData_614154, "EnvironmentName", newJString(EnvironmentName))
  add(query_614153, "Action", newJString(Action))
  add(formData_614154, "Status", newJString(Status))
  add(formData_614154, "EnvironmentId", newJString(EnvironmentId))
  add(query_614153, "Version", newJString(Version))
  result = call_614152.call(nil, query_614153, nil, formData_614154, nil)

var postDescribeEnvironmentManagedActions* = Call_PostDescribeEnvironmentManagedActions_614136(
    name: "postDescribeEnvironmentManagedActions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActions",
    validator: validate_PostDescribeEnvironmentManagedActions_614137, base: "/",
    url: url_PostDescribeEnvironmentManagedActions_614138,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentManagedActions_614118 = ref object of OpenApiRestCall_612659
proc url_GetDescribeEnvironmentManagedActions_614120(protocol: Scheme;
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

proc validate_GetDescribeEnvironmentManagedActions_614119(path: JsonNode;
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
  var valid_614121 = query.getOrDefault("Status")
  valid_614121 = validateParameter(valid_614121, JString, required = false,
                                 default = newJString("Scheduled"))
  if valid_614121 != nil:
    section.add "Status", valid_614121
  var valid_614122 = query.getOrDefault("EnvironmentName")
  valid_614122 = validateParameter(valid_614122, JString, required = false,
                                 default = nil)
  if valid_614122 != nil:
    section.add "EnvironmentName", valid_614122
  var valid_614123 = query.getOrDefault("Action")
  valid_614123 = validateParameter(valid_614123, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActions"))
  if valid_614123 != nil:
    section.add "Action", valid_614123
  var valid_614124 = query.getOrDefault("Version")
  valid_614124 = validateParameter(valid_614124, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614124 != nil:
    section.add "Version", valid_614124
  var valid_614125 = query.getOrDefault("EnvironmentId")
  valid_614125 = validateParameter(valid_614125, JString, required = false,
                                 default = nil)
  if valid_614125 != nil:
    section.add "EnvironmentId", valid_614125
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
  var valid_614126 = header.getOrDefault("X-Amz-Signature")
  valid_614126 = validateParameter(valid_614126, JString, required = false,
                                 default = nil)
  if valid_614126 != nil:
    section.add "X-Amz-Signature", valid_614126
  var valid_614127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614127 = validateParameter(valid_614127, JString, required = false,
                                 default = nil)
  if valid_614127 != nil:
    section.add "X-Amz-Content-Sha256", valid_614127
  var valid_614128 = header.getOrDefault("X-Amz-Date")
  valid_614128 = validateParameter(valid_614128, JString, required = false,
                                 default = nil)
  if valid_614128 != nil:
    section.add "X-Amz-Date", valid_614128
  var valid_614129 = header.getOrDefault("X-Amz-Credential")
  valid_614129 = validateParameter(valid_614129, JString, required = false,
                                 default = nil)
  if valid_614129 != nil:
    section.add "X-Amz-Credential", valid_614129
  var valid_614130 = header.getOrDefault("X-Amz-Security-Token")
  valid_614130 = validateParameter(valid_614130, JString, required = false,
                                 default = nil)
  if valid_614130 != nil:
    section.add "X-Amz-Security-Token", valid_614130
  var valid_614131 = header.getOrDefault("X-Amz-Algorithm")
  valid_614131 = validateParameter(valid_614131, JString, required = false,
                                 default = nil)
  if valid_614131 != nil:
    section.add "X-Amz-Algorithm", valid_614131
  var valid_614132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614132 = validateParameter(valid_614132, JString, required = false,
                                 default = nil)
  if valid_614132 != nil:
    section.add "X-Amz-SignedHeaders", valid_614132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614133: Call_GetDescribeEnvironmentManagedActions_614118;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists an environment's upcoming and in-progress managed actions.
  ## 
  let valid = call_614133.validator(path, query, header, formData, body)
  let scheme = call_614133.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614133.url(scheme.get, call_614133.host, call_614133.base,
                         call_614133.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614133, url, valid)

proc call*(call_614134: Call_GetDescribeEnvironmentManagedActions_614118;
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
  var query_614135 = newJObject()
  add(query_614135, "Status", newJString(Status))
  add(query_614135, "EnvironmentName", newJString(EnvironmentName))
  add(query_614135, "Action", newJString(Action))
  add(query_614135, "Version", newJString(Version))
  add(query_614135, "EnvironmentId", newJString(EnvironmentId))
  result = call_614134.call(nil, query_614135, nil, nil, nil)

var getDescribeEnvironmentManagedActions* = Call_GetDescribeEnvironmentManagedActions_614118(
    name: "getDescribeEnvironmentManagedActions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActions",
    validator: validate_GetDescribeEnvironmentManagedActions_614119, base: "/",
    url: url_GetDescribeEnvironmentManagedActions_614120,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentResources_614172 = ref object of OpenApiRestCall_612659
proc url_PostDescribeEnvironmentResources_614174(protocol: Scheme; host: string;
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

proc validate_PostDescribeEnvironmentResources_614173(path: JsonNode;
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
  var valid_614175 = query.getOrDefault("Action")
  valid_614175 = validateParameter(valid_614175, JString, required = true, default = newJString(
      "DescribeEnvironmentResources"))
  if valid_614175 != nil:
    section.add "Action", valid_614175
  var valid_614176 = query.getOrDefault("Version")
  valid_614176 = validateParameter(valid_614176, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614176 != nil:
    section.add "Version", valid_614176
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
  var valid_614177 = header.getOrDefault("X-Amz-Signature")
  valid_614177 = validateParameter(valid_614177, JString, required = false,
                                 default = nil)
  if valid_614177 != nil:
    section.add "X-Amz-Signature", valid_614177
  var valid_614178 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614178 = validateParameter(valid_614178, JString, required = false,
                                 default = nil)
  if valid_614178 != nil:
    section.add "X-Amz-Content-Sha256", valid_614178
  var valid_614179 = header.getOrDefault("X-Amz-Date")
  valid_614179 = validateParameter(valid_614179, JString, required = false,
                                 default = nil)
  if valid_614179 != nil:
    section.add "X-Amz-Date", valid_614179
  var valid_614180 = header.getOrDefault("X-Amz-Credential")
  valid_614180 = validateParameter(valid_614180, JString, required = false,
                                 default = nil)
  if valid_614180 != nil:
    section.add "X-Amz-Credential", valid_614180
  var valid_614181 = header.getOrDefault("X-Amz-Security-Token")
  valid_614181 = validateParameter(valid_614181, JString, required = false,
                                 default = nil)
  if valid_614181 != nil:
    section.add "X-Amz-Security-Token", valid_614181
  var valid_614182 = header.getOrDefault("X-Amz-Algorithm")
  valid_614182 = validateParameter(valid_614182, JString, required = false,
                                 default = nil)
  if valid_614182 != nil:
    section.add "X-Amz-Algorithm", valid_614182
  var valid_614183 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614183 = validateParameter(valid_614183, JString, required = false,
                                 default = nil)
  if valid_614183 != nil:
    section.add "X-Amz-SignedHeaders", valid_614183
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to retrieve AWS resource usage data.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to retrieve AWS resource usage data.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_614184 = formData.getOrDefault("EnvironmentName")
  valid_614184 = validateParameter(valid_614184, JString, required = false,
                                 default = nil)
  if valid_614184 != nil:
    section.add "EnvironmentName", valid_614184
  var valid_614185 = formData.getOrDefault("EnvironmentId")
  valid_614185 = validateParameter(valid_614185, JString, required = false,
                                 default = nil)
  if valid_614185 != nil:
    section.add "EnvironmentId", valid_614185
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614186: Call_PostDescribeEnvironmentResources_614172;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns AWS resources for this environment.
  ## 
  let valid = call_614186.validator(path, query, header, formData, body)
  let scheme = call_614186.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614186.url(scheme.get, call_614186.host, call_614186.base,
                         call_614186.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614186, url, valid)

proc call*(call_614187: Call_PostDescribeEnvironmentResources_614172;
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
  var query_614188 = newJObject()
  var formData_614189 = newJObject()
  add(formData_614189, "EnvironmentName", newJString(EnvironmentName))
  add(query_614188, "Action", newJString(Action))
  add(formData_614189, "EnvironmentId", newJString(EnvironmentId))
  add(query_614188, "Version", newJString(Version))
  result = call_614187.call(nil, query_614188, nil, formData_614189, nil)

var postDescribeEnvironmentResources* = Call_PostDescribeEnvironmentResources_614172(
    name: "postDescribeEnvironmentResources", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentResources",
    validator: validate_PostDescribeEnvironmentResources_614173, base: "/",
    url: url_PostDescribeEnvironmentResources_614174,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentResources_614155 = ref object of OpenApiRestCall_612659
proc url_GetDescribeEnvironmentResources_614157(protocol: Scheme; host: string;
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

proc validate_GetDescribeEnvironmentResources_614156(path: JsonNode;
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
  var valid_614158 = query.getOrDefault("EnvironmentName")
  valid_614158 = validateParameter(valid_614158, JString, required = false,
                                 default = nil)
  if valid_614158 != nil:
    section.add "EnvironmentName", valid_614158
  var valid_614159 = query.getOrDefault("Action")
  valid_614159 = validateParameter(valid_614159, JString, required = true, default = newJString(
      "DescribeEnvironmentResources"))
  if valid_614159 != nil:
    section.add "Action", valid_614159
  var valid_614160 = query.getOrDefault("Version")
  valid_614160 = validateParameter(valid_614160, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614160 != nil:
    section.add "Version", valid_614160
  var valid_614161 = query.getOrDefault("EnvironmentId")
  valid_614161 = validateParameter(valid_614161, JString, required = false,
                                 default = nil)
  if valid_614161 != nil:
    section.add "EnvironmentId", valid_614161
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
  var valid_614162 = header.getOrDefault("X-Amz-Signature")
  valid_614162 = validateParameter(valid_614162, JString, required = false,
                                 default = nil)
  if valid_614162 != nil:
    section.add "X-Amz-Signature", valid_614162
  var valid_614163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614163 = validateParameter(valid_614163, JString, required = false,
                                 default = nil)
  if valid_614163 != nil:
    section.add "X-Amz-Content-Sha256", valid_614163
  var valid_614164 = header.getOrDefault("X-Amz-Date")
  valid_614164 = validateParameter(valid_614164, JString, required = false,
                                 default = nil)
  if valid_614164 != nil:
    section.add "X-Amz-Date", valid_614164
  var valid_614165 = header.getOrDefault("X-Amz-Credential")
  valid_614165 = validateParameter(valid_614165, JString, required = false,
                                 default = nil)
  if valid_614165 != nil:
    section.add "X-Amz-Credential", valid_614165
  var valid_614166 = header.getOrDefault("X-Amz-Security-Token")
  valid_614166 = validateParameter(valid_614166, JString, required = false,
                                 default = nil)
  if valid_614166 != nil:
    section.add "X-Amz-Security-Token", valid_614166
  var valid_614167 = header.getOrDefault("X-Amz-Algorithm")
  valid_614167 = validateParameter(valid_614167, JString, required = false,
                                 default = nil)
  if valid_614167 != nil:
    section.add "X-Amz-Algorithm", valid_614167
  var valid_614168 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614168 = validateParameter(valid_614168, JString, required = false,
                                 default = nil)
  if valid_614168 != nil:
    section.add "X-Amz-SignedHeaders", valid_614168
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614169: Call_GetDescribeEnvironmentResources_614155;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns AWS resources for this environment.
  ## 
  let valid = call_614169.validator(path, query, header, formData, body)
  let scheme = call_614169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614169.url(scheme.get, call_614169.host, call_614169.base,
                         call_614169.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614169, url, valid)

proc call*(call_614170: Call_GetDescribeEnvironmentResources_614155;
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
  var query_614171 = newJObject()
  add(query_614171, "EnvironmentName", newJString(EnvironmentName))
  add(query_614171, "Action", newJString(Action))
  add(query_614171, "Version", newJString(Version))
  add(query_614171, "EnvironmentId", newJString(EnvironmentId))
  result = call_614170.call(nil, query_614171, nil, nil, nil)

var getDescribeEnvironmentResources* = Call_GetDescribeEnvironmentResources_614155(
    name: "getDescribeEnvironmentResources", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentResources",
    validator: validate_GetDescribeEnvironmentResources_614156, base: "/",
    url: url_GetDescribeEnvironmentResources_614157,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironments_614213 = ref object of OpenApiRestCall_612659
proc url_PostDescribeEnvironments_614215(protocol: Scheme; host: string;
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

proc validate_PostDescribeEnvironments_614214(path: JsonNode; query: JsonNode;
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
  var valid_614216 = query.getOrDefault("Action")
  valid_614216 = validateParameter(valid_614216, JString, required = true,
                                 default = newJString("DescribeEnvironments"))
  if valid_614216 != nil:
    section.add "Action", valid_614216
  var valid_614217 = query.getOrDefault("Version")
  valid_614217 = validateParameter(valid_614217, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614217 != nil:
    section.add "Version", valid_614217
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
  var valid_614218 = header.getOrDefault("X-Amz-Signature")
  valid_614218 = validateParameter(valid_614218, JString, required = false,
                                 default = nil)
  if valid_614218 != nil:
    section.add "X-Amz-Signature", valid_614218
  var valid_614219 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614219 = validateParameter(valid_614219, JString, required = false,
                                 default = nil)
  if valid_614219 != nil:
    section.add "X-Amz-Content-Sha256", valid_614219
  var valid_614220 = header.getOrDefault("X-Amz-Date")
  valid_614220 = validateParameter(valid_614220, JString, required = false,
                                 default = nil)
  if valid_614220 != nil:
    section.add "X-Amz-Date", valid_614220
  var valid_614221 = header.getOrDefault("X-Amz-Credential")
  valid_614221 = validateParameter(valid_614221, JString, required = false,
                                 default = nil)
  if valid_614221 != nil:
    section.add "X-Amz-Credential", valid_614221
  var valid_614222 = header.getOrDefault("X-Amz-Security-Token")
  valid_614222 = validateParameter(valid_614222, JString, required = false,
                                 default = nil)
  if valid_614222 != nil:
    section.add "X-Amz-Security-Token", valid_614222
  var valid_614223 = header.getOrDefault("X-Amz-Algorithm")
  valid_614223 = validateParameter(valid_614223, JString, required = false,
                                 default = nil)
  if valid_614223 != nil:
    section.add "X-Amz-Algorithm", valid_614223
  var valid_614224 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614224 = validateParameter(valid_614224, JString, required = false,
                                 default = nil)
  if valid_614224 != nil:
    section.add "X-Amz-SignedHeaders", valid_614224
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
  var valid_614225 = formData.getOrDefault("EnvironmentNames")
  valid_614225 = validateParameter(valid_614225, JArray, required = false,
                                 default = nil)
  if valid_614225 != nil:
    section.add "EnvironmentNames", valid_614225
  var valid_614226 = formData.getOrDefault("MaxRecords")
  valid_614226 = validateParameter(valid_614226, JInt, required = false, default = nil)
  if valid_614226 != nil:
    section.add "MaxRecords", valid_614226
  var valid_614227 = formData.getOrDefault("VersionLabel")
  valid_614227 = validateParameter(valid_614227, JString, required = false,
                                 default = nil)
  if valid_614227 != nil:
    section.add "VersionLabel", valid_614227
  var valid_614228 = formData.getOrDefault("NextToken")
  valid_614228 = validateParameter(valid_614228, JString, required = false,
                                 default = nil)
  if valid_614228 != nil:
    section.add "NextToken", valid_614228
  var valid_614229 = formData.getOrDefault("ApplicationName")
  valid_614229 = validateParameter(valid_614229, JString, required = false,
                                 default = nil)
  if valid_614229 != nil:
    section.add "ApplicationName", valid_614229
  var valid_614230 = formData.getOrDefault("IncludedDeletedBackTo")
  valid_614230 = validateParameter(valid_614230, JString, required = false,
                                 default = nil)
  if valid_614230 != nil:
    section.add "IncludedDeletedBackTo", valid_614230
  var valid_614231 = formData.getOrDefault("EnvironmentIds")
  valid_614231 = validateParameter(valid_614231, JArray, required = false,
                                 default = nil)
  if valid_614231 != nil:
    section.add "EnvironmentIds", valid_614231
  var valid_614232 = formData.getOrDefault("IncludeDeleted")
  valid_614232 = validateParameter(valid_614232, JBool, required = false, default = nil)
  if valid_614232 != nil:
    section.add "IncludeDeleted", valid_614232
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614233: Call_PostDescribeEnvironments_614213; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns descriptions for existing environments.
  ## 
  let valid = call_614233.validator(path, query, header, formData, body)
  let scheme = call_614233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614233.url(scheme.get, call_614233.host, call_614233.base,
                         call_614233.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614233, url, valid)

proc call*(call_614234: Call_PostDescribeEnvironments_614213;
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
  var query_614235 = newJObject()
  var formData_614236 = newJObject()
  if EnvironmentNames != nil:
    formData_614236.add "EnvironmentNames", EnvironmentNames
  add(formData_614236, "MaxRecords", newJInt(MaxRecords))
  add(formData_614236, "VersionLabel", newJString(VersionLabel))
  add(formData_614236, "NextToken", newJString(NextToken))
  add(formData_614236, "ApplicationName", newJString(ApplicationName))
  add(query_614235, "Action", newJString(Action))
  add(query_614235, "Version", newJString(Version))
  add(formData_614236, "IncludedDeletedBackTo", newJString(IncludedDeletedBackTo))
  if EnvironmentIds != nil:
    formData_614236.add "EnvironmentIds", EnvironmentIds
  add(formData_614236, "IncludeDeleted", newJBool(IncludeDeleted))
  result = call_614234.call(nil, query_614235, nil, formData_614236, nil)

var postDescribeEnvironments* = Call_PostDescribeEnvironments_614213(
    name: "postDescribeEnvironments", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironments",
    validator: validate_PostDescribeEnvironments_614214, base: "/",
    url: url_PostDescribeEnvironments_614215, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironments_614190 = ref object of OpenApiRestCall_612659
proc url_GetDescribeEnvironments_614192(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
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

proc validate_GetDescribeEnvironments_614191(path: JsonNode; query: JsonNode;
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
  var valid_614193 = query.getOrDefault("ApplicationName")
  valid_614193 = validateParameter(valid_614193, JString, required = false,
                                 default = nil)
  if valid_614193 != nil:
    section.add "ApplicationName", valid_614193
  var valid_614194 = query.getOrDefault("VersionLabel")
  valid_614194 = validateParameter(valid_614194, JString, required = false,
                                 default = nil)
  if valid_614194 != nil:
    section.add "VersionLabel", valid_614194
  var valid_614195 = query.getOrDefault("IncludeDeleted")
  valid_614195 = validateParameter(valid_614195, JBool, required = false, default = nil)
  if valid_614195 != nil:
    section.add "IncludeDeleted", valid_614195
  var valid_614196 = query.getOrDefault("NextToken")
  valid_614196 = validateParameter(valid_614196, JString, required = false,
                                 default = nil)
  if valid_614196 != nil:
    section.add "NextToken", valid_614196
  var valid_614197 = query.getOrDefault("EnvironmentNames")
  valid_614197 = validateParameter(valid_614197, JArray, required = false,
                                 default = nil)
  if valid_614197 != nil:
    section.add "EnvironmentNames", valid_614197
  var valid_614198 = query.getOrDefault("Action")
  valid_614198 = validateParameter(valid_614198, JString, required = true,
                                 default = newJString("DescribeEnvironments"))
  if valid_614198 != nil:
    section.add "Action", valid_614198
  var valid_614199 = query.getOrDefault("EnvironmentIds")
  valid_614199 = validateParameter(valid_614199, JArray, required = false,
                                 default = nil)
  if valid_614199 != nil:
    section.add "EnvironmentIds", valid_614199
  var valid_614200 = query.getOrDefault("IncludedDeletedBackTo")
  valid_614200 = validateParameter(valid_614200, JString, required = false,
                                 default = nil)
  if valid_614200 != nil:
    section.add "IncludedDeletedBackTo", valid_614200
  var valid_614201 = query.getOrDefault("Version")
  valid_614201 = validateParameter(valid_614201, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614201 != nil:
    section.add "Version", valid_614201
  var valid_614202 = query.getOrDefault("MaxRecords")
  valid_614202 = validateParameter(valid_614202, JInt, required = false, default = nil)
  if valid_614202 != nil:
    section.add "MaxRecords", valid_614202
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
  var valid_614203 = header.getOrDefault("X-Amz-Signature")
  valid_614203 = validateParameter(valid_614203, JString, required = false,
                                 default = nil)
  if valid_614203 != nil:
    section.add "X-Amz-Signature", valid_614203
  var valid_614204 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614204 = validateParameter(valid_614204, JString, required = false,
                                 default = nil)
  if valid_614204 != nil:
    section.add "X-Amz-Content-Sha256", valid_614204
  var valid_614205 = header.getOrDefault("X-Amz-Date")
  valid_614205 = validateParameter(valid_614205, JString, required = false,
                                 default = nil)
  if valid_614205 != nil:
    section.add "X-Amz-Date", valid_614205
  var valid_614206 = header.getOrDefault("X-Amz-Credential")
  valid_614206 = validateParameter(valid_614206, JString, required = false,
                                 default = nil)
  if valid_614206 != nil:
    section.add "X-Amz-Credential", valid_614206
  var valid_614207 = header.getOrDefault("X-Amz-Security-Token")
  valid_614207 = validateParameter(valid_614207, JString, required = false,
                                 default = nil)
  if valid_614207 != nil:
    section.add "X-Amz-Security-Token", valid_614207
  var valid_614208 = header.getOrDefault("X-Amz-Algorithm")
  valid_614208 = validateParameter(valid_614208, JString, required = false,
                                 default = nil)
  if valid_614208 != nil:
    section.add "X-Amz-Algorithm", valid_614208
  var valid_614209 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614209 = validateParameter(valid_614209, JString, required = false,
                                 default = nil)
  if valid_614209 != nil:
    section.add "X-Amz-SignedHeaders", valid_614209
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614210: Call_GetDescribeEnvironments_614190; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns descriptions for existing environments.
  ## 
  let valid = call_614210.validator(path, query, header, formData, body)
  let scheme = call_614210.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614210.url(scheme.get, call_614210.host, call_614210.base,
                         call_614210.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614210, url, valid)

proc call*(call_614211: Call_GetDescribeEnvironments_614190;
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
  var query_614212 = newJObject()
  add(query_614212, "ApplicationName", newJString(ApplicationName))
  add(query_614212, "VersionLabel", newJString(VersionLabel))
  add(query_614212, "IncludeDeleted", newJBool(IncludeDeleted))
  add(query_614212, "NextToken", newJString(NextToken))
  if EnvironmentNames != nil:
    query_614212.add "EnvironmentNames", EnvironmentNames
  add(query_614212, "Action", newJString(Action))
  if EnvironmentIds != nil:
    query_614212.add "EnvironmentIds", EnvironmentIds
  add(query_614212, "IncludedDeletedBackTo", newJString(IncludedDeletedBackTo))
  add(query_614212, "Version", newJString(Version))
  add(query_614212, "MaxRecords", newJInt(MaxRecords))
  result = call_614211.call(nil, query_614212, nil, nil, nil)

var getDescribeEnvironments* = Call_GetDescribeEnvironments_614190(
    name: "getDescribeEnvironments", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironments",
    validator: validate_GetDescribeEnvironments_614191, base: "/",
    url: url_GetDescribeEnvironments_614192, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_614264 = ref object of OpenApiRestCall_612659
proc url_PostDescribeEvents_614266(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeEvents_614265(path: JsonNode; query: JsonNode;
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
  var valid_614267 = query.getOrDefault("Action")
  valid_614267 = validateParameter(valid_614267, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_614267 != nil:
    section.add "Action", valid_614267
  var valid_614268 = query.getOrDefault("Version")
  valid_614268 = validateParameter(valid_614268, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614268 != nil:
    section.add "Version", valid_614268
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
  var valid_614269 = header.getOrDefault("X-Amz-Signature")
  valid_614269 = validateParameter(valid_614269, JString, required = false,
                                 default = nil)
  if valid_614269 != nil:
    section.add "X-Amz-Signature", valid_614269
  var valid_614270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614270 = validateParameter(valid_614270, JString, required = false,
                                 default = nil)
  if valid_614270 != nil:
    section.add "X-Amz-Content-Sha256", valid_614270
  var valid_614271 = header.getOrDefault("X-Amz-Date")
  valid_614271 = validateParameter(valid_614271, JString, required = false,
                                 default = nil)
  if valid_614271 != nil:
    section.add "X-Amz-Date", valid_614271
  var valid_614272 = header.getOrDefault("X-Amz-Credential")
  valid_614272 = validateParameter(valid_614272, JString, required = false,
                                 default = nil)
  if valid_614272 != nil:
    section.add "X-Amz-Credential", valid_614272
  var valid_614273 = header.getOrDefault("X-Amz-Security-Token")
  valid_614273 = validateParameter(valid_614273, JString, required = false,
                                 default = nil)
  if valid_614273 != nil:
    section.add "X-Amz-Security-Token", valid_614273
  var valid_614274 = header.getOrDefault("X-Amz-Algorithm")
  valid_614274 = validateParameter(valid_614274, JString, required = false,
                                 default = nil)
  if valid_614274 != nil:
    section.add "X-Amz-Algorithm", valid_614274
  var valid_614275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614275 = validateParameter(valid_614275, JString, required = false,
                                 default = nil)
  if valid_614275 != nil:
    section.add "X-Amz-SignedHeaders", valid_614275
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
  var valid_614276 = formData.getOrDefault("NextToken")
  valid_614276 = validateParameter(valid_614276, JString, required = false,
                                 default = nil)
  if valid_614276 != nil:
    section.add "NextToken", valid_614276
  var valid_614277 = formData.getOrDefault("MaxRecords")
  valid_614277 = validateParameter(valid_614277, JInt, required = false, default = nil)
  if valid_614277 != nil:
    section.add "MaxRecords", valid_614277
  var valid_614278 = formData.getOrDefault("VersionLabel")
  valid_614278 = validateParameter(valid_614278, JString, required = false,
                                 default = nil)
  if valid_614278 != nil:
    section.add "VersionLabel", valid_614278
  var valid_614279 = formData.getOrDefault("EnvironmentName")
  valid_614279 = validateParameter(valid_614279, JString, required = false,
                                 default = nil)
  if valid_614279 != nil:
    section.add "EnvironmentName", valid_614279
  var valid_614280 = formData.getOrDefault("TemplateName")
  valid_614280 = validateParameter(valid_614280, JString, required = false,
                                 default = nil)
  if valid_614280 != nil:
    section.add "TemplateName", valid_614280
  var valid_614281 = formData.getOrDefault("ApplicationName")
  valid_614281 = validateParameter(valid_614281, JString, required = false,
                                 default = nil)
  if valid_614281 != nil:
    section.add "ApplicationName", valid_614281
  var valid_614282 = formData.getOrDefault("EndTime")
  valid_614282 = validateParameter(valid_614282, JString, required = false,
                                 default = nil)
  if valid_614282 != nil:
    section.add "EndTime", valid_614282
  var valid_614283 = formData.getOrDefault("StartTime")
  valid_614283 = validateParameter(valid_614283, JString, required = false,
                                 default = nil)
  if valid_614283 != nil:
    section.add "StartTime", valid_614283
  var valid_614284 = formData.getOrDefault("Severity")
  valid_614284 = validateParameter(valid_614284, JString, required = false,
                                 default = newJString("TRACE"))
  if valid_614284 != nil:
    section.add "Severity", valid_614284
  var valid_614285 = formData.getOrDefault("RequestId")
  valid_614285 = validateParameter(valid_614285, JString, required = false,
                                 default = nil)
  if valid_614285 != nil:
    section.add "RequestId", valid_614285
  var valid_614286 = formData.getOrDefault("EnvironmentId")
  valid_614286 = validateParameter(valid_614286, JString, required = false,
                                 default = nil)
  if valid_614286 != nil:
    section.add "EnvironmentId", valid_614286
  var valid_614287 = formData.getOrDefault("PlatformArn")
  valid_614287 = validateParameter(valid_614287, JString, required = false,
                                 default = nil)
  if valid_614287 != nil:
    section.add "PlatformArn", valid_614287
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614288: Call_PostDescribeEvents_614264; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns list of event descriptions matching criteria up to the last 6 weeks.</p> <note> <p>This action returns the most recent 1,000 events from the specified <code>NextToken</code>.</p> </note>
  ## 
  let valid = call_614288.validator(path, query, header, formData, body)
  let scheme = call_614288.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614288.url(scheme.get, call_614288.host, call_614288.base,
                         call_614288.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614288, url, valid)

proc call*(call_614289: Call_PostDescribeEvents_614264; NextToken: string = "";
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
  var query_614290 = newJObject()
  var formData_614291 = newJObject()
  add(formData_614291, "NextToken", newJString(NextToken))
  add(formData_614291, "MaxRecords", newJInt(MaxRecords))
  add(formData_614291, "VersionLabel", newJString(VersionLabel))
  add(formData_614291, "EnvironmentName", newJString(EnvironmentName))
  add(formData_614291, "TemplateName", newJString(TemplateName))
  add(formData_614291, "ApplicationName", newJString(ApplicationName))
  add(formData_614291, "EndTime", newJString(EndTime))
  add(formData_614291, "StartTime", newJString(StartTime))
  add(formData_614291, "Severity", newJString(Severity))
  add(query_614290, "Action", newJString(Action))
  add(formData_614291, "RequestId", newJString(RequestId))
  add(formData_614291, "EnvironmentId", newJString(EnvironmentId))
  add(query_614290, "Version", newJString(Version))
  add(formData_614291, "PlatformArn", newJString(PlatformArn))
  result = call_614289.call(nil, query_614290, nil, formData_614291, nil)

var postDescribeEvents* = Call_PostDescribeEvents_614264(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_614265, base: "/",
    url: url_PostDescribeEvents_614266, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_614237 = ref object of OpenApiRestCall_612659
proc url_GetDescribeEvents_614239(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeEvents_614238(path: JsonNode; query: JsonNode;
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
  var valid_614240 = query.getOrDefault("RequestId")
  valid_614240 = validateParameter(valid_614240, JString, required = false,
                                 default = nil)
  if valid_614240 != nil:
    section.add "RequestId", valid_614240
  var valid_614241 = query.getOrDefault("ApplicationName")
  valid_614241 = validateParameter(valid_614241, JString, required = false,
                                 default = nil)
  if valid_614241 != nil:
    section.add "ApplicationName", valid_614241
  var valid_614242 = query.getOrDefault("VersionLabel")
  valid_614242 = validateParameter(valid_614242, JString, required = false,
                                 default = nil)
  if valid_614242 != nil:
    section.add "VersionLabel", valid_614242
  var valid_614243 = query.getOrDefault("NextToken")
  valid_614243 = validateParameter(valid_614243, JString, required = false,
                                 default = nil)
  if valid_614243 != nil:
    section.add "NextToken", valid_614243
  var valid_614244 = query.getOrDefault("Severity")
  valid_614244 = validateParameter(valid_614244, JString, required = false,
                                 default = newJString("TRACE"))
  if valid_614244 != nil:
    section.add "Severity", valid_614244
  var valid_614245 = query.getOrDefault("EnvironmentName")
  valid_614245 = validateParameter(valid_614245, JString, required = false,
                                 default = nil)
  if valid_614245 != nil:
    section.add "EnvironmentName", valid_614245
  var valid_614246 = query.getOrDefault("Action")
  valid_614246 = validateParameter(valid_614246, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_614246 != nil:
    section.add "Action", valid_614246
  var valid_614247 = query.getOrDefault("StartTime")
  valid_614247 = validateParameter(valid_614247, JString, required = false,
                                 default = nil)
  if valid_614247 != nil:
    section.add "StartTime", valid_614247
  var valid_614248 = query.getOrDefault("PlatformArn")
  valid_614248 = validateParameter(valid_614248, JString, required = false,
                                 default = nil)
  if valid_614248 != nil:
    section.add "PlatformArn", valid_614248
  var valid_614249 = query.getOrDefault("EndTime")
  valid_614249 = validateParameter(valid_614249, JString, required = false,
                                 default = nil)
  if valid_614249 != nil:
    section.add "EndTime", valid_614249
  var valid_614250 = query.getOrDefault("Version")
  valid_614250 = validateParameter(valid_614250, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614250 != nil:
    section.add "Version", valid_614250
  var valid_614251 = query.getOrDefault("TemplateName")
  valid_614251 = validateParameter(valid_614251, JString, required = false,
                                 default = nil)
  if valid_614251 != nil:
    section.add "TemplateName", valid_614251
  var valid_614252 = query.getOrDefault("MaxRecords")
  valid_614252 = validateParameter(valid_614252, JInt, required = false, default = nil)
  if valid_614252 != nil:
    section.add "MaxRecords", valid_614252
  var valid_614253 = query.getOrDefault("EnvironmentId")
  valid_614253 = validateParameter(valid_614253, JString, required = false,
                                 default = nil)
  if valid_614253 != nil:
    section.add "EnvironmentId", valid_614253
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
  var valid_614254 = header.getOrDefault("X-Amz-Signature")
  valid_614254 = validateParameter(valid_614254, JString, required = false,
                                 default = nil)
  if valid_614254 != nil:
    section.add "X-Amz-Signature", valid_614254
  var valid_614255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614255 = validateParameter(valid_614255, JString, required = false,
                                 default = nil)
  if valid_614255 != nil:
    section.add "X-Amz-Content-Sha256", valid_614255
  var valid_614256 = header.getOrDefault("X-Amz-Date")
  valid_614256 = validateParameter(valid_614256, JString, required = false,
                                 default = nil)
  if valid_614256 != nil:
    section.add "X-Amz-Date", valid_614256
  var valid_614257 = header.getOrDefault("X-Amz-Credential")
  valid_614257 = validateParameter(valid_614257, JString, required = false,
                                 default = nil)
  if valid_614257 != nil:
    section.add "X-Amz-Credential", valid_614257
  var valid_614258 = header.getOrDefault("X-Amz-Security-Token")
  valid_614258 = validateParameter(valid_614258, JString, required = false,
                                 default = nil)
  if valid_614258 != nil:
    section.add "X-Amz-Security-Token", valid_614258
  var valid_614259 = header.getOrDefault("X-Amz-Algorithm")
  valid_614259 = validateParameter(valid_614259, JString, required = false,
                                 default = nil)
  if valid_614259 != nil:
    section.add "X-Amz-Algorithm", valid_614259
  var valid_614260 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614260 = validateParameter(valid_614260, JString, required = false,
                                 default = nil)
  if valid_614260 != nil:
    section.add "X-Amz-SignedHeaders", valid_614260
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614261: Call_GetDescribeEvents_614237; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns list of event descriptions matching criteria up to the last 6 weeks.</p> <note> <p>This action returns the most recent 1,000 events from the specified <code>NextToken</code>.</p> </note>
  ## 
  let valid = call_614261.validator(path, query, header, formData, body)
  let scheme = call_614261.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614261.url(scheme.get, call_614261.host, call_614261.base,
                         call_614261.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614261, url, valid)

proc call*(call_614262: Call_GetDescribeEvents_614237; RequestId: string = "";
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
  var query_614263 = newJObject()
  add(query_614263, "RequestId", newJString(RequestId))
  add(query_614263, "ApplicationName", newJString(ApplicationName))
  add(query_614263, "VersionLabel", newJString(VersionLabel))
  add(query_614263, "NextToken", newJString(NextToken))
  add(query_614263, "Severity", newJString(Severity))
  add(query_614263, "EnvironmentName", newJString(EnvironmentName))
  add(query_614263, "Action", newJString(Action))
  add(query_614263, "StartTime", newJString(StartTime))
  add(query_614263, "PlatformArn", newJString(PlatformArn))
  add(query_614263, "EndTime", newJString(EndTime))
  add(query_614263, "Version", newJString(Version))
  add(query_614263, "TemplateName", newJString(TemplateName))
  add(query_614263, "MaxRecords", newJInt(MaxRecords))
  add(query_614263, "EnvironmentId", newJString(EnvironmentId))
  result = call_614262.call(nil, query_614263, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_614237(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_614238,
    base: "/", url: url_GetDescribeEvents_614239,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeInstancesHealth_614311 = ref object of OpenApiRestCall_612659
proc url_PostDescribeInstancesHealth_614313(protocol: Scheme; host: string;
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

proc validate_PostDescribeInstancesHealth_614312(path: JsonNode; query: JsonNode;
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
  var valid_614314 = query.getOrDefault("Action")
  valid_614314 = validateParameter(valid_614314, JString, required = true, default = newJString(
      "DescribeInstancesHealth"))
  if valid_614314 != nil:
    section.add "Action", valid_614314
  var valid_614315 = query.getOrDefault("Version")
  valid_614315 = validateParameter(valid_614315, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614315 != nil:
    section.add "Version", valid_614315
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
  var valid_614316 = header.getOrDefault("X-Amz-Signature")
  valid_614316 = validateParameter(valid_614316, JString, required = false,
                                 default = nil)
  if valid_614316 != nil:
    section.add "X-Amz-Signature", valid_614316
  var valid_614317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614317 = validateParameter(valid_614317, JString, required = false,
                                 default = nil)
  if valid_614317 != nil:
    section.add "X-Amz-Content-Sha256", valid_614317
  var valid_614318 = header.getOrDefault("X-Amz-Date")
  valid_614318 = validateParameter(valid_614318, JString, required = false,
                                 default = nil)
  if valid_614318 != nil:
    section.add "X-Amz-Date", valid_614318
  var valid_614319 = header.getOrDefault("X-Amz-Credential")
  valid_614319 = validateParameter(valid_614319, JString, required = false,
                                 default = nil)
  if valid_614319 != nil:
    section.add "X-Amz-Credential", valid_614319
  var valid_614320 = header.getOrDefault("X-Amz-Security-Token")
  valid_614320 = validateParameter(valid_614320, JString, required = false,
                                 default = nil)
  if valid_614320 != nil:
    section.add "X-Amz-Security-Token", valid_614320
  var valid_614321 = header.getOrDefault("X-Amz-Algorithm")
  valid_614321 = validateParameter(valid_614321, JString, required = false,
                                 default = nil)
  if valid_614321 != nil:
    section.add "X-Amz-Algorithm", valid_614321
  var valid_614322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614322 = validateParameter(valid_614322, JString, required = false,
                                 default = nil)
  if valid_614322 != nil:
    section.add "X-Amz-SignedHeaders", valid_614322
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
  var valid_614323 = formData.getOrDefault("NextToken")
  valid_614323 = validateParameter(valid_614323, JString, required = false,
                                 default = nil)
  if valid_614323 != nil:
    section.add "NextToken", valid_614323
  var valid_614324 = formData.getOrDefault("EnvironmentName")
  valid_614324 = validateParameter(valid_614324, JString, required = false,
                                 default = nil)
  if valid_614324 != nil:
    section.add "EnvironmentName", valid_614324
  var valid_614325 = formData.getOrDefault("AttributeNames")
  valid_614325 = validateParameter(valid_614325, JArray, required = false,
                                 default = nil)
  if valid_614325 != nil:
    section.add "AttributeNames", valid_614325
  var valid_614326 = formData.getOrDefault("EnvironmentId")
  valid_614326 = validateParameter(valid_614326, JString, required = false,
                                 default = nil)
  if valid_614326 != nil:
    section.add "EnvironmentId", valid_614326
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614327: Call_PostDescribeInstancesHealth_614311; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves detailed information about the health of instances in your AWS Elastic Beanstalk. This operation requires <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/health-enhanced.html">enhanced health reporting</a>.
  ## 
  let valid = call_614327.validator(path, query, header, formData, body)
  let scheme = call_614327.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614327.url(scheme.get, call_614327.host, call_614327.base,
                         call_614327.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614327, url, valid)

proc call*(call_614328: Call_PostDescribeInstancesHealth_614311;
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
  var query_614329 = newJObject()
  var formData_614330 = newJObject()
  add(formData_614330, "NextToken", newJString(NextToken))
  add(formData_614330, "EnvironmentName", newJString(EnvironmentName))
  if AttributeNames != nil:
    formData_614330.add "AttributeNames", AttributeNames
  add(query_614329, "Action", newJString(Action))
  add(formData_614330, "EnvironmentId", newJString(EnvironmentId))
  add(query_614329, "Version", newJString(Version))
  result = call_614328.call(nil, query_614329, nil, formData_614330, nil)

var postDescribeInstancesHealth* = Call_PostDescribeInstancesHealth_614311(
    name: "postDescribeInstancesHealth", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeInstancesHealth",
    validator: validate_PostDescribeInstancesHealth_614312, base: "/",
    url: url_PostDescribeInstancesHealth_614313,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeInstancesHealth_614292 = ref object of OpenApiRestCall_612659
proc url_GetDescribeInstancesHealth_614294(protocol: Scheme; host: string;
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

proc validate_GetDescribeInstancesHealth_614293(path: JsonNode; query: JsonNode;
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
  var valid_614295 = query.getOrDefault("AttributeNames")
  valid_614295 = validateParameter(valid_614295, JArray, required = false,
                                 default = nil)
  if valid_614295 != nil:
    section.add "AttributeNames", valid_614295
  var valid_614296 = query.getOrDefault("NextToken")
  valid_614296 = validateParameter(valid_614296, JString, required = false,
                                 default = nil)
  if valid_614296 != nil:
    section.add "NextToken", valid_614296
  var valid_614297 = query.getOrDefault("EnvironmentName")
  valid_614297 = validateParameter(valid_614297, JString, required = false,
                                 default = nil)
  if valid_614297 != nil:
    section.add "EnvironmentName", valid_614297
  var valid_614298 = query.getOrDefault("Action")
  valid_614298 = validateParameter(valid_614298, JString, required = true, default = newJString(
      "DescribeInstancesHealth"))
  if valid_614298 != nil:
    section.add "Action", valid_614298
  var valid_614299 = query.getOrDefault("Version")
  valid_614299 = validateParameter(valid_614299, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614299 != nil:
    section.add "Version", valid_614299
  var valid_614300 = query.getOrDefault("EnvironmentId")
  valid_614300 = validateParameter(valid_614300, JString, required = false,
                                 default = nil)
  if valid_614300 != nil:
    section.add "EnvironmentId", valid_614300
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
  var valid_614301 = header.getOrDefault("X-Amz-Signature")
  valid_614301 = validateParameter(valid_614301, JString, required = false,
                                 default = nil)
  if valid_614301 != nil:
    section.add "X-Amz-Signature", valid_614301
  var valid_614302 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614302 = validateParameter(valid_614302, JString, required = false,
                                 default = nil)
  if valid_614302 != nil:
    section.add "X-Amz-Content-Sha256", valid_614302
  var valid_614303 = header.getOrDefault("X-Amz-Date")
  valid_614303 = validateParameter(valid_614303, JString, required = false,
                                 default = nil)
  if valid_614303 != nil:
    section.add "X-Amz-Date", valid_614303
  var valid_614304 = header.getOrDefault("X-Amz-Credential")
  valid_614304 = validateParameter(valid_614304, JString, required = false,
                                 default = nil)
  if valid_614304 != nil:
    section.add "X-Amz-Credential", valid_614304
  var valid_614305 = header.getOrDefault("X-Amz-Security-Token")
  valid_614305 = validateParameter(valid_614305, JString, required = false,
                                 default = nil)
  if valid_614305 != nil:
    section.add "X-Amz-Security-Token", valid_614305
  var valid_614306 = header.getOrDefault("X-Amz-Algorithm")
  valid_614306 = validateParameter(valid_614306, JString, required = false,
                                 default = nil)
  if valid_614306 != nil:
    section.add "X-Amz-Algorithm", valid_614306
  var valid_614307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614307 = validateParameter(valid_614307, JString, required = false,
                                 default = nil)
  if valid_614307 != nil:
    section.add "X-Amz-SignedHeaders", valid_614307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614308: Call_GetDescribeInstancesHealth_614292; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves detailed information about the health of instances in your AWS Elastic Beanstalk. This operation requires <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/health-enhanced.html">enhanced health reporting</a>.
  ## 
  let valid = call_614308.validator(path, query, header, formData, body)
  let scheme = call_614308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614308.url(scheme.get, call_614308.host, call_614308.base,
                         call_614308.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614308, url, valid)

proc call*(call_614309: Call_GetDescribeInstancesHealth_614292;
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
  var query_614310 = newJObject()
  if AttributeNames != nil:
    query_614310.add "AttributeNames", AttributeNames
  add(query_614310, "NextToken", newJString(NextToken))
  add(query_614310, "EnvironmentName", newJString(EnvironmentName))
  add(query_614310, "Action", newJString(Action))
  add(query_614310, "Version", newJString(Version))
  add(query_614310, "EnvironmentId", newJString(EnvironmentId))
  result = call_614309.call(nil, query_614310, nil, nil, nil)

var getDescribeInstancesHealth* = Call_GetDescribeInstancesHealth_614292(
    name: "getDescribeInstancesHealth", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeInstancesHealth",
    validator: validate_GetDescribeInstancesHealth_614293, base: "/",
    url: url_GetDescribeInstancesHealth_614294,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribePlatformVersion_614347 = ref object of OpenApiRestCall_612659
proc url_PostDescribePlatformVersion_614349(protocol: Scheme; host: string;
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

proc validate_PostDescribePlatformVersion_614348(path: JsonNode; query: JsonNode;
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
  var valid_614350 = query.getOrDefault("Action")
  valid_614350 = validateParameter(valid_614350, JString, required = true, default = newJString(
      "DescribePlatformVersion"))
  if valid_614350 != nil:
    section.add "Action", valid_614350
  var valid_614351 = query.getOrDefault("Version")
  valid_614351 = validateParameter(valid_614351, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614351 != nil:
    section.add "Version", valid_614351
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
  var valid_614352 = header.getOrDefault("X-Amz-Signature")
  valid_614352 = validateParameter(valid_614352, JString, required = false,
                                 default = nil)
  if valid_614352 != nil:
    section.add "X-Amz-Signature", valid_614352
  var valid_614353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614353 = validateParameter(valid_614353, JString, required = false,
                                 default = nil)
  if valid_614353 != nil:
    section.add "X-Amz-Content-Sha256", valid_614353
  var valid_614354 = header.getOrDefault("X-Amz-Date")
  valid_614354 = validateParameter(valid_614354, JString, required = false,
                                 default = nil)
  if valid_614354 != nil:
    section.add "X-Amz-Date", valid_614354
  var valid_614355 = header.getOrDefault("X-Amz-Credential")
  valid_614355 = validateParameter(valid_614355, JString, required = false,
                                 default = nil)
  if valid_614355 != nil:
    section.add "X-Amz-Credential", valid_614355
  var valid_614356 = header.getOrDefault("X-Amz-Security-Token")
  valid_614356 = validateParameter(valid_614356, JString, required = false,
                                 default = nil)
  if valid_614356 != nil:
    section.add "X-Amz-Security-Token", valid_614356
  var valid_614357 = header.getOrDefault("X-Amz-Algorithm")
  valid_614357 = validateParameter(valid_614357, JString, required = false,
                                 default = nil)
  if valid_614357 != nil:
    section.add "X-Amz-Algorithm", valid_614357
  var valid_614358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614358 = validateParameter(valid_614358, JString, required = false,
                                 default = nil)
  if valid_614358 != nil:
    section.add "X-Amz-SignedHeaders", valid_614358
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformArn: JString
  ##              : The ARN of the version of the platform.
  section = newJObject()
  var valid_614359 = formData.getOrDefault("PlatformArn")
  valid_614359 = validateParameter(valid_614359, JString, required = false,
                                 default = nil)
  if valid_614359 != nil:
    section.add "PlatformArn", valid_614359
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614360: Call_PostDescribePlatformVersion_614347; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the version of the platform.
  ## 
  let valid = call_614360.validator(path, query, header, formData, body)
  let scheme = call_614360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614360.url(scheme.get, call_614360.host, call_614360.base,
                         call_614360.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614360, url, valid)

proc call*(call_614361: Call_PostDescribePlatformVersion_614347;
          Action: string = "DescribePlatformVersion";
          Version: string = "2010-12-01"; PlatformArn: string = ""): Recallable =
  ## postDescribePlatformVersion
  ## Describes the version of the platform.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PlatformArn: string
  ##              : The ARN of the version of the platform.
  var query_614362 = newJObject()
  var formData_614363 = newJObject()
  add(query_614362, "Action", newJString(Action))
  add(query_614362, "Version", newJString(Version))
  add(formData_614363, "PlatformArn", newJString(PlatformArn))
  result = call_614361.call(nil, query_614362, nil, formData_614363, nil)

var postDescribePlatformVersion* = Call_PostDescribePlatformVersion_614347(
    name: "postDescribePlatformVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribePlatformVersion",
    validator: validate_PostDescribePlatformVersion_614348, base: "/",
    url: url_PostDescribePlatformVersion_614349,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribePlatformVersion_614331 = ref object of OpenApiRestCall_612659
proc url_GetDescribePlatformVersion_614333(protocol: Scheme; host: string;
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

proc validate_GetDescribePlatformVersion_614332(path: JsonNode; query: JsonNode;
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
  var valid_614334 = query.getOrDefault("Action")
  valid_614334 = validateParameter(valid_614334, JString, required = true, default = newJString(
      "DescribePlatformVersion"))
  if valid_614334 != nil:
    section.add "Action", valid_614334
  var valid_614335 = query.getOrDefault("PlatformArn")
  valid_614335 = validateParameter(valid_614335, JString, required = false,
                                 default = nil)
  if valid_614335 != nil:
    section.add "PlatformArn", valid_614335
  var valid_614336 = query.getOrDefault("Version")
  valid_614336 = validateParameter(valid_614336, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614336 != nil:
    section.add "Version", valid_614336
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
  var valid_614337 = header.getOrDefault("X-Amz-Signature")
  valid_614337 = validateParameter(valid_614337, JString, required = false,
                                 default = nil)
  if valid_614337 != nil:
    section.add "X-Amz-Signature", valid_614337
  var valid_614338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614338 = validateParameter(valid_614338, JString, required = false,
                                 default = nil)
  if valid_614338 != nil:
    section.add "X-Amz-Content-Sha256", valid_614338
  var valid_614339 = header.getOrDefault("X-Amz-Date")
  valid_614339 = validateParameter(valid_614339, JString, required = false,
                                 default = nil)
  if valid_614339 != nil:
    section.add "X-Amz-Date", valid_614339
  var valid_614340 = header.getOrDefault("X-Amz-Credential")
  valid_614340 = validateParameter(valid_614340, JString, required = false,
                                 default = nil)
  if valid_614340 != nil:
    section.add "X-Amz-Credential", valid_614340
  var valid_614341 = header.getOrDefault("X-Amz-Security-Token")
  valid_614341 = validateParameter(valid_614341, JString, required = false,
                                 default = nil)
  if valid_614341 != nil:
    section.add "X-Amz-Security-Token", valid_614341
  var valid_614342 = header.getOrDefault("X-Amz-Algorithm")
  valid_614342 = validateParameter(valid_614342, JString, required = false,
                                 default = nil)
  if valid_614342 != nil:
    section.add "X-Amz-Algorithm", valid_614342
  var valid_614343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614343 = validateParameter(valid_614343, JString, required = false,
                                 default = nil)
  if valid_614343 != nil:
    section.add "X-Amz-SignedHeaders", valid_614343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614344: Call_GetDescribePlatformVersion_614331; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the version of the platform.
  ## 
  let valid = call_614344.validator(path, query, header, formData, body)
  let scheme = call_614344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614344.url(scheme.get, call_614344.host, call_614344.base,
                         call_614344.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614344, url, valid)

proc call*(call_614345: Call_GetDescribePlatformVersion_614331;
          Action: string = "DescribePlatformVersion"; PlatformArn: string = "";
          Version: string = "2010-12-01"): Recallable =
  ## getDescribePlatformVersion
  ## Describes the version of the platform.
  ##   Action: string (required)
  ##   PlatformArn: string
  ##              : The ARN of the version of the platform.
  ##   Version: string (required)
  var query_614346 = newJObject()
  add(query_614346, "Action", newJString(Action))
  add(query_614346, "PlatformArn", newJString(PlatformArn))
  add(query_614346, "Version", newJString(Version))
  result = call_614345.call(nil, query_614346, nil, nil, nil)

var getDescribePlatformVersion* = Call_GetDescribePlatformVersion_614331(
    name: "getDescribePlatformVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribePlatformVersion",
    validator: validate_GetDescribePlatformVersion_614332, base: "/",
    url: url_GetDescribePlatformVersion_614333,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListAvailableSolutionStacks_614379 = ref object of OpenApiRestCall_612659
proc url_PostListAvailableSolutionStacks_614381(protocol: Scheme; host: string;
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

proc validate_PostListAvailableSolutionStacks_614380(path: JsonNode;
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
  var valid_614382 = query.getOrDefault("Action")
  valid_614382 = validateParameter(valid_614382, JString, required = true, default = newJString(
      "ListAvailableSolutionStacks"))
  if valid_614382 != nil:
    section.add "Action", valid_614382
  var valid_614383 = query.getOrDefault("Version")
  valid_614383 = validateParameter(valid_614383, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614383 != nil:
    section.add "Version", valid_614383
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
  var valid_614384 = header.getOrDefault("X-Amz-Signature")
  valid_614384 = validateParameter(valid_614384, JString, required = false,
                                 default = nil)
  if valid_614384 != nil:
    section.add "X-Amz-Signature", valid_614384
  var valid_614385 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614385 = validateParameter(valid_614385, JString, required = false,
                                 default = nil)
  if valid_614385 != nil:
    section.add "X-Amz-Content-Sha256", valid_614385
  var valid_614386 = header.getOrDefault("X-Amz-Date")
  valid_614386 = validateParameter(valid_614386, JString, required = false,
                                 default = nil)
  if valid_614386 != nil:
    section.add "X-Amz-Date", valid_614386
  var valid_614387 = header.getOrDefault("X-Amz-Credential")
  valid_614387 = validateParameter(valid_614387, JString, required = false,
                                 default = nil)
  if valid_614387 != nil:
    section.add "X-Amz-Credential", valid_614387
  var valid_614388 = header.getOrDefault("X-Amz-Security-Token")
  valid_614388 = validateParameter(valid_614388, JString, required = false,
                                 default = nil)
  if valid_614388 != nil:
    section.add "X-Amz-Security-Token", valid_614388
  var valid_614389 = header.getOrDefault("X-Amz-Algorithm")
  valid_614389 = validateParameter(valid_614389, JString, required = false,
                                 default = nil)
  if valid_614389 != nil:
    section.add "X-Amz-Algorithm", valid_614389
  var valid_614390 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614390 = validateParameter(valid_614390, JString, required = false,
                                 default = nil)
  if valid_614390 != nil:
    section.add "X-Amz-SignedHeaders", valid_614390
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614391: Call_PostListAvailableSolutionStacks_614379;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ## 
  let valid = call_614391.validator(path, query, header, formData, body)
  let scheme = call_614391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614391.url(scheme.get, call_614391.host, call_614391.base,
                         call_614391.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614391, url, valid)

proc call*(call_614392: Call_PostListAvailableSolutionStacks_614379;
          Action: string = "ListAvailableSolutionStacks";
          Version: string = "2010-12-01"): Recallable =
  ## postListAvailableSolutionStacks
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_614393 = newJObject()
  add(query_614393, "Action", newJString(Action))
  add(query_614393, "Version", newJString(Version))
  result = call_614392.call(nil, query_614393, nil, nil, nil)

var postListAvailableSolutionStacks* = Call_PostListAvailableSolutionStacks_614379(
    name: "postListAvailableSolutionStacks", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListAvailableSolutionStacks",
    validator: validate_PostListAvailableSolutionStacks_614380, base: "/",
    url: url_PostListAvailableSolutionStacks_614381,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListAvailableSolutionStacks_614364 = ref object of OpenApiRestCall_612659
proc url_GetListAvailableSolutionStacks_614366(protocol: Scheme; host: string;
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

proc validate_GetListAvailableSolutionStacks_614365(path: JsonNode;
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
  var valid_614367 = query.getOrDefault("Action")
  valid_614367 = validateParameter(valid_614367, JString, required = true, default = newJString(
      "ListAvailableSolutionStacks"))
  if valid_614367 != nil:
    section.add "Action", valid_614367
  var valid_614368 = query.getOrDefault("Version")
  valid_614368 = validateParameter(valid_614368, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614368 != nil:
    section.add "Version", valid_614368
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
  var valid_614369 = header.getOrDefault("X-Amz-Signature")
  valid_614369 = validateParameter(valid_614369, JString, required = false,
                                 default = nil)
  if valid_614369 != nil:
    section.add "X-Amz-Signature", valid_614369
  var valid_614370 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614370 = validateParameter(valid_614370, JString, required = false,
                                 default = nil)
  if valid_614370 != nil:
    section.add "X-Amz-Content-Sha256", valid_614370
  var valid_614371 = header.getOrDefault("X-Amz-Date")
  valid_614371 = validateParameter(valid_614371, JString, required = false,
                                 default = nil)
  if valid_614371 != nil:
    section.add "X-Amz-Date", valid_614371
  var valid_614372 = header.getOrDefault("X-Amz-Credential")
  valid_614372 = validateParameter(valid_614372, JString, required = false,
                                 default = nil)
  if valid_614372 != nil:
    section.add "X-Amz-Credential", valid_614372
  var valid_614373 = header.getOrDefault("X-Amz-Security-Token")
  valid_614373 = validateParameter(valid_614373, JString, required = false,
                                 default = nil)
  if valid_614373 != nil:
    section.add "X-Amz-Security-Token", valid_614373
  var valid_614374 = header.getOrDefault("X-Amz-Algorithm")
  valid_614374 = validateParameter(valid_614374, JString, required = false,
                                 default = nil)
  if valid_614374 != nil:
    section.add "X-Amz-Algorithm", valid_614374
  var valid_614375 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614375 = validateParameter(valid_614375, JString, required = false,
                                 default = nil)
  if valid_614375 != nil:
    section.add "X-Amz-SignedHeaders", valid_614375
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614376: Call_GetListAvailableSolutionStacks_614364; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ## 
  let valid = call_614376.validator(path, query, header, formData, body)
  let scheme = call_614376.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614376.url(scheme.get, call_614376.host, call_614376.base,
                         call_614376.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614376, url, valid)

proc call*(call_614377: Call_GetListAvailableSolutionStacks_614364;
          Action: string = "ListAvailableSolutionStacks";
          Version: string = "2010-12-01"): Recallable =
  ## getListAvailableSolutionStacks
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_614378 = newJObject()
  add(query_614378, "Action", newJString(Action))
  add(query_614378, "Version", newJString(Version))
  result = call_614377.call(nil, query_614378, nil, nil, nil)

var getListAvailableSolutionStacks* = Call_GetListAvailableSolutionStacks_614364(
    name: "getListAvailableSolutionStacks", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListAvailableSolutionStacks",
    validator: validate_GetListAvailableSolutionStacks_614365, base: "/",
    url: url_GetListAvailableSolutionStacks_614366,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListPlatformVersions_614412 = ref object of OpenApiRestCall_612659
proc url_PostListPlatformVersions_614414(protocol: Scheme; host: string;
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

proc validate_PostListPlatformVersions_614413(path: JsonNode; query: JsonNode;
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
  var valid_614415 = query.getOrDefault("Action")
  valid_614415 = validateParameter(valid_614415, JString, required = true,
                                 default = newJString("ListPlatformVersions"))
  if valid_614415 != nil:
    section.add "Action", valid_614415
  var valid_614416 = query.getOrDefault("Version")
  valid_614416 = validateParameter(valid_614416, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614416 != nil:
    section.add "Version", valid_614416
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
  var valid_614417 = header.getOrDefault("X-Amz-Signature")
  valid_614417 = validateParameter(valid_614417, JString, required = false,
                                 default = nil)
  if valid_614417 != nil:
    section.add "X-Amz-Signature", valid_614417
  var valid_614418 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614418 = validateParameter(valid_614418, JString, required = false,
                                 default = nil)
  if valid_614418 != nil:
    section.add "X-Amz-Content-Sha256", valid_614418
  var valid_614419 = header.getOrDefault("X-Amz-Date")
  valid_614419 = validateParameter(valid_614419, JString, required = false,
                                 default = nil)
  if valid_614419 != nil:
    section.add "X-Amz-Date", valid_614419
  var valid_614420 = header.getOrDefault("X-Amz-Credential")
  valid_614420 = validateParameter(valid_614420, JString, required = false,
                                 default = nil)
  if valid_614420 != nil:
    section.add "X-Amz-Credential", valid_614420
  var valid_614421 = header.getOrDefault("X-Amz-Security-Token")
  valid_614421 = validateParameter(valid_614421, JString, required = false,
                                 default = nil)
  if valid_614421 != nil:
    section.add "X-Amz-Security-Token", valid_614421
  var valid_614422 = header.getOrDefault("X-Amz-Algorithm")
  valid_614422 = validateParameter(valid_614422, JString, required = false,
                                 default = nil)
  if valid_614422 != nil:
    section.add "X-Amz-Algorithm", valid_614422
  var valid_614423 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614423 = validateParameter(valid_614423, JString, required = false,
                                 default = nil)
  if valid_614423 != nil:
    section.add "X-Amz-SignedHeaders", valid_614423
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : The starting index into the remaining list of platforms. Use the <code>NextToken</code> value from a previous <code>ListPlatformVersion</code> call.
  ##   MaxRecords: JInt
  ##             : The maximum number of platform values returned in one call.
  ##   Filters: JArray
  ##          : List only the platforms where the platform member value relates to one of the supplied values.
  section = newJObject()
  var valid_614424 = formData.getOrDefault("NextToken")
  valid_614424 = validateParameter(valid_614424, JString, required = false,
                                 default = nil)
  if valid_614424 != nil:
    section.add "NextToken", valid_614424
  var valid_614425 = formData.getOrDefault("MaxRecords")
  valid_614425 = validateParameter(valid_614425, JInt, required = false, default = nil)
  if valid_614425 != nil:
    section.add "MaxRecords", valid_614425
  var valid_614426 = formData.getOrDefault("Filters")
  valid_614426 = validateParameter(valid_614426, JArray, required = false,
                                 default = nil)
  if valid_614426 != nil:
    section.add "Filters", valid_614426
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614427: Call_PostListPlatformVersions_614412; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the available platforms.
  ## 
  let valid = call_614427.validator(path, query, header, formData, body)
  let scheme = call_614427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614427.url(scheme.get, call_614427.host, call_614427.base,
                         call_614427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614427, url, valid)

proc call*(call_614428: Call_PostListPlatformVersions_614412;
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
  var query_614429 = newJObject()
  var formData_614430 = newJObject()
  add(formData_614430, "NextToken", newJString(NextToken))
  add(formData_614430, "MaxRecords", newJInt(MaxRecords))
  add(query_614429, "Action", newJString(Action))
  if Filters != nil:
    formData_614430.add "Filters", Filters
  add(query_614429, "Version", newJString(Version))
  result = call_614428.call(nil, query_614429, nil, formData_614430, nil)

var postListPlatformVersions* = Call_PostListPlatformVersions_614412(
    name: "postListPlatformVersions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListPlatformVersions",
    validator: validate_PostListPlatformVersions_614413, base: "/",
    url: url_PostListPlatformVersions_614414, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListPlatformVersions_614394 = ref object of OpenApiRestCall_612659
proc url_GetListPlatformVersions_614396(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
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

proc validate_GetListPlatformVersions_614395(path: JsonNode; query: JsonNode;
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
  var valid_614397 = query.getOrDefault("NextToken")
  valid_614397 = validateParameter(valid_614397, JString, required = false,
                                 default = nil)
  if valid_614397 != nil:
    section.add "NextToken", valid_614397
  var valid_614398 = query.getOrDefault("Action")
  valid_614398 = validateParameter(valid_614398, JString, required = true,
                                 default = newJString("ListPlatformVersions"))
  if valid_614398 != nil:
    section.add "Action", valid_614398
  var valid_614399 = query.getOrDefault("Version")
  valid_614399 = validateParameter(valid_614399, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614399 != nil:
    section.add "Version", valid_614399
  var valid_614400 = query.getOrDefault("Filters")
  valid_614400 = validateParameter(valid_614400, JArray, required = false,
                                 default = nil)
  if valid_614400 != nil:
    section.add "Filters", valid_614400
  var valid_614401 = query.getOrDefault("MaxRecords")
  valid_614401 = validateParameter(valid_614401, JInt, required = false, default = nil)
  if valid_614401 != nil:
    section.add "MaxRecords", valid_614401
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
  var valid_614402 = header.getOrDefault("X-Amz-Signature")
  valid_614402 = validateParameter(valid_614402, JString, required = false,
                                 default = nil)
  if valid_614402 != nil:
    section.add "X-Amz-Signature", valid_614402
  var valid_614403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614403 = validateParameter(valid_614403, JString, required = false,
                                 default = nil)
  if valid_614403 != nil:
    section.add "X-Amz-Content-Sha256", valid_614403
  var valid_614404 = header.getOrDefault("X-Amz-Date")
  valid_614404 = validateParameter(valid_614404, JString, required = false,
                                 default = nil)
  if valid_614404 != nil:
    section.add "X-Amz-Date", valid_614404
  var valid_614405 = header.getOrDefault("X-Amz-Credential")
  valid_614405 = validateParameter(valid_614405, JString, required = false,
                                 default = nil)
  if valid_614405 != nil:
    section.add "X-Amz-Credential", valid_614405
  var valid_614406 = header.getOrDefault("X-Amz-Security-Token")
  valid_614406 = validateParameter(valid_614406, JString, required = false,
                                 default = nil)
  if valid_614406 != nil:
    section.add "X-Amz-Security-Token", valid_614406
  var valid_614407 = header.getOrDefault("X-Amz-Algorithm")
  valid_614407 = validateParameter(valid_614407, JString, required = false,
                                 default = nil)
  if valid_614407 != nil:
    section.add "X-Amz-Algorithm", valid_614407
  var valid_614408 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614408 = validateParameter(valid_614408, JString, required = false,
                                 default = nil)
  if valid_614408 != nil:
    section.add "X-Amz-SignedHeaders", valid_614408
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614409: Call_GetListPlatformVersions_614394; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the available platforms.
  ## 
  let valid = call_614409.validator(path, query, header, formData, body)
  let scheme = call_614409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614409.url(scheme.get, call_614409.host, call_614409.base,
                         call_614409.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614409, url, valid)

proc call*(call_614410: Call_GetListPlatformVersions_614394;
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
  var query_614411 = newJObject()
  add(query_614411, "NextToken", newJString(NextToken))
  add(query_614411, "Action", newJString(Action))
  add(query_614411, "Version", newJString(Version))
  if Filters != nil:
    query_614411.add "Filters", Filters
  add(query_614411, "MaxRecords", newJInt(MaxRecords))
  result = call_614410.call(nil, query_614411, nil, nil, nil)

var getListPlatformVersions* = Call_GetListPlatformVersions_614394(
    name: "getListPlatformVersions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListPlatformVersions",
    validator: validate_GetListPlatformVersions_614395, base: "/",
    url: url_GetListPlatformVersions_614396, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_614447 = ref object of OpenApiRestCall_612659
proc url_PostListTagsForResource_614449(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
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

proc validate_PostListTagsForResource_614448(path: JsonNode; query: JsonNode;
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
  var valid_614450 = query.getOrDefault("Action")
  valid_614450 = validateParameter(valid_614450, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_614450 != nil:
    section.add "Action", valid_614450
  var valid_614451 = query.getOrDefault("Version")
  valid_614451 = validateParameter(valid_614451, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614451 != nil:
    section.add "Version", valid_614451
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
  var valid_614452 = header.getOrDefault("X-Amz-Signature")
  valid_614452 = validateParameter(valid_614452, JString, required = false,
                                 default = nil)
  if valid_614452 != nil:
    section.add "X-Amz-Signature", valid_614452
  var valid_614453 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614453 = validateParameter(valid_614453, JString, required = false,
                                 default = nil)
  if valid_614453 != nil:
    section.add "X-Amz-Content-Sha256", valid_614453
  var valid_614454 = header.getOrDefault("X-Amz-Date")
  valid_614454 = validateParameter(valid_614454, JString, required = false,
                                 default = nil)
  if valid_614454 != nil:
    section.add "X-Amz-Date", valid_614454
  var valid_614455 = header.getOrDefault("X-Amz-Credential")
  valid_614455 = validateParameter(valid_614455, JString, required = false,
                                 default = nil)
  if valid_614455 != nil:
    section.add "X-Amz-Credential", valid_614455
  var valid_614456 = header.getOrDefault("X-Amz-Security-Token")
  valid_614456 = validateParameter(valid_614456, JString, required = false,
                                 default = nil)
  if valid_614456 != nil:
    section.add "X-Amz-Security-Token", valid_614456
  var valid_614457 = header.getOrDefault("X-Amz-Algorithm")
  valid_614457 = validateParameter(valid_614457, JString, required = false,
                                 default = nil)
  if valid_614457 != nil:
    section.add "X-Amz-Algorithm", valid_614457
  var valid_614458 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614458 = validateParameter(valid_614458, JString, required = false,
                                 default = nil)
  if valid_614458 != nil:
    section.add "X-Amz-SignedHeaders", valid_614458
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArn: JString (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce for which a tag list is requested.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArn` field"
  var valid_614459 = formData.getOrDefault("ResourceArn")
  valid_614459 = validateParameter(valid_614459, JString, required = true,
                                 default = nil)
  if valid_614459 != nil:
    section.add "ResourceArn", valid_614459
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614460: Call_PostListTagsForResource_614447; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ## 
  let valid = call_614460.validator(path, query, header, formData, body)
  let scheme = call_614460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614460.url(scheme.get, call_614460.host, call_614460.base,
                         call_614460.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614460, url, valid)

proc call*(call_614461: Call_PostListTagsForResource_614447; ResourceArn: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-12-01"): Recallable =
  ## postListTagsForResource
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ##   ResourceArn: string (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce for which a tag list is requested.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_614462 = newJObject()
  var formData_614463 = newJObject()
  add(formData_614463, "ResourceArn", newJString(ResourceArn))
  add(query_614462, "Action", newJString(Action))
  add(query_614462, "Version", newJString(Version))
  result = call_614461.call(nil, query_614462, nil, formData_614463, nil)

var postListTagsForResource* = Call_PostListTagsForResource_614447(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_614448, base: "/",
    url: url_PostListTagsForResource_614449, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_614431 = ref object of OpenApiRestCall_612659
proc url_GetListTagsForResource_614433(protocol: Scheme; host: string; base: string;
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

proc validate_GetListTagsForResource_614432(path: JsonNode; query: JsonNode;
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
  var valid_614434 = query.getOrDefault("ResourceArn")
  valid_614434 = validateParameter(valid_614434, JString, required = true,
                                 default = nil)
  if valid_614434 != nil:
    section.add "ResourceArn", valid_614434
  var valid_614435 = query.getOrDefault("Action")
  valid_614435 = validateParameter(valid_614435, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_614435 != nil:
    section.add "Action", valid_614435
  var valid_614436 = query.getOrDefault("Version")
  valid_614436 = validateParameter(valid_614436, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614436 != nil:
    section.add "Version", valid_614436
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
  var valid_614437 = header.getOrDefault("X-Amz-Signature")
  valid_614437 = validateParameter(valid_614437, JString, required = false,
                                 default = nil)
  if valid_614437 != nil:
    section.add "X-Amz-Signature", valid_614437
  var valid_614438 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614438 = validateParameter(valid_614438, JString, required = false,
                                 default = nil)
  if valid_614438 != nil:
    section.add "X-Amz-Content-Sha256", valid_614438
  var valid_614439 = header.getOrDefault("X-Amz-Date")
  valid_614439 = validateParameter(valid_614439, JString, required = false,
                                 default = nil)
  if valid_614439 != nil:
    section.add "X-Amz-Date", valid_614439
  var valid_614440 = header.getOrDefault("X-Amz-Credential")
  valid_614440 = validateParameter(valid_614440, JString, required = false,
                                 default = nil)
  if valid_614440 != nil:
    section.add "X-Amz-Credential", valid_614440
  var valid_614441 = header.getOrDefault("X-Amz-Security-Token")
  valid_614441 = validateParameter(valid_614441, JString, required = false,
                                 default = nil)
  if valid_614441 != nil:
    section.add "X-Amz-Security-Token", valid_614441
  var valid_614442 = header.getOrDefault("X-Amz-Algorithm")
  valid_614442 = validateParameter(valid_614442, JString, required = false,
                                 default = nil)
  if valid_614442 != nil:
    section.add "X-Amz-Algorithm", valid_614442
  var valid_614443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614443 = validateParameter(valid_614443, JString, required = false,
                                 default = nil)
  if valid_614443 != nil:
    section.add "X-Amz-SignedHeaders", valid_614443
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614444: Call_GetListTagsForResource_614431; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ## 
  let valid = call_614444.validator(path, query, header, formData, body)
  let scheme = call_614444.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614444.url(scheme.get, call_614444.host, call_614444.base,
                         call_614444.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614444, url, valid)

proc call*(call_614445: Call_GetListTagsForResource_614431; ResourceArn: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-12-01"): Recallable =
  ## getListTagsForResource
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ##   ResourceArn: string (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce for which a tag list is requested.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_614446 = newJObject()
  add(query_614446, "ResourceArn", newJString(ResourceArn))
  add(query_614446, "Action", newJString(Action))
  add(query_614446, "Version", newJString(Version))
  result = call_614445.call(nil, query_614446, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_614431(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_614432, base: "/",
    url: url_GetListTagsForResource_614433, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebuildEnvironment_614481 = ref object of OpenApiRestCall_612659
proc url_PostRebuildEnvironment_614483(protocol: Scheme; host: string; base: string;
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

proc validate_PostRebuildEnvironment_614482(path: JsonNode; query: JsonNode;
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
  var valid_614484 = query.getOrDefault("Action")
  valid_614484 = validateParameter(valid_614484, JString, required = true,
                                 default = newJString("RebuildEnvironment"))
  if valid_614484 != nil:
    section.add "Action", valid_614484
  var valid_614485 = query.getOrDefault("Version")
  valid_614485 = validateParameter(valid_614485, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614485 != nil:
    section.add "Version", valid_614485
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
  var valid_614486 = header.getOrDefault("X-Amz-Signature")
  valid_614486 = validateParameter(valid_614486, JString, required = false,
                                 default = nil)
  if valid_614486 != nil:
    section.add "X-Amz-Signature", valid_614486
  var valid_614487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614487 = validateParameter(valid_614487, JString, required = false,
                                 default = nil)
  if valid_614487 != nil:
    section.add "X-Amz-Content-Sha256", valid_614487
  var valid_614488 = header.getOrDefault("X-Amz-Date")
  valid_614488 = validateParameter(valid_614488, JString, required = false,
                                 default = nil)
  if valid_614488 != nil:
    section.add "X-Amz-Date", valid_614488
  var valid_614489 = header.getOrDefault("X-Amz-Credential")
  valid_614489 = validateParameter(valid_614489, JString, required = false,
                                 default = nil)
  if valid_614489 != nil:
    section.add "X-Amz-Credential", valid_614489
  var valid_614490 = header.getOrDefault("X-Amz-Security-Token")
  valid_614490 = validateParameter(valid_614490, JString, required = false,
                                 default = nil)
  if valid_614490 != nil:
    section.add "X-Amz-Security-Token", valid_614490
  var valid_614491 = header.getOrDefault("X-Amz-Algorithm")
  valid_614491 = validateParameter(valid_614491, JString, required = false,
                                 default = nil)
  if valid_614491 != nil:
    section.add "X-Amz-Algorithm", valid_614491
  var valid_614492 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614492 = validateParameter(valid_614492, JString, required = false,
                                 default = nil)
  if valid_614492 != nil:
    section.add "X-Amz-SignedHeaders", valid_614492
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to rebuild.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to rebuild.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_614493 = formData.getOrDefault("EnvironmentName")
  valid_614493 = validateParameter(valid_614493, JString, required = false,
                                 default = nil)
  if valid_614493 != nil:
    section.add "EnvironmentName", valid_614493
  var valid_614494 = formData.getOrDefault("EnvironmentId")
  valid_614494 = validateParameter(valid_614494, JString, required = false,
                                 default = nil)
  if valid_614494 != nil:
    section.add "EnvironmentId", valid_614494
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614495: Call_PostRebuildEnvironment_614481; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes and recreates all of the AWS resources (for example: the Auto Scaling group, load balancer, etc.) for a specified environment and forces a restart.
  ## 
  let valid = call_614495.validator(path, query, header, formData, body)
  let scheme = call_614495.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614495.url(scheme.get, call_614495.host, call_614495.base,
                         call_614495.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614495, url, valid)

proc call*(call_614496: Call_PostRebuildEnvironment_614481;
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
  var query_614497 = newJObject()
  var formData_614498 = newJObject()
  add(formData_614498, "EnvironmentName", newJString(EnvironmentName))
  add(query_614497, "Action", newJString(Action))
  add(formData_614498, "EnvironmentId", newJString(EnvironmentId))
  add(query_614497, "Version", newJString(Version))
  result = call_614496.call(nil, query_614497, nil, formData_614498, nil)

var postRebuildEnvironment* = Call_PostRebuildEnvironment_614481(
    name: "postRebuildEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RebuildEnvironment",
    validator: validate_PostRebuildEnvironment_614482, base: "/",
    url: url_PostRebuildEnvironment_614483, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebuildEnvironment_614464 = ref object of OpenApiRestCall_612659
proc url_GetRebuildEnvironment_614466(protocol: Scheme; host: string; base: string;
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

proc validate_GetRebuildEnvironment_614465(path: JsonNode; query: JsonNode;
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
  var valid_614467 = query.getOrDefault("EnvironmentName")
  valid_614467 = validateParameter(valid_614467, JString, required = false,
                                 default = nil)
  if valid_614467 != nil:
    section.add "EnvironmentName", valid_614467
  var valid_614468 = query.getOrDefault("Action")
  valid_614468 = validateParameter(valid_614468, JString, required = true,
                                 default = newJString("RebuildEnvironment"))
  if valid_614468 != nil:
    section.add "Action", valid_614468
  var valid_614469 = query.getOrDefault("Version")
  valid_614469 = validateParameter(valid_614469, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614469 != nil:
    section.add "Version", valid_614469
  var valid_614470 = query.getOrDefault("EnvironmentId")
  valid_614470 = validateParameter(valid_614470, JString, required = false,
                                 default = nil)
  if valid_614470 != nil:
    section.add "EnvironmentId", valid_614470
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
  var valid_614471 = header.getOrDefault("X-Amz-Signature")
  valid_614471 = validateParameter(valid_614471, JString, required = false,
                                 default = nil)
  if valid_614471 != nil:
    section.add "X-Amz-Signature", valid_614471
  var valid_614472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614472 = validateParameter(valid_614472, JString, required = false,
                                 default = nil)
  if valid_614472 != nil:
    section.add "X-Amz-Content-Sha256", valid_614472
  var valid_614473 = header.getOrDefault("X-Amz-Date")
  valid_614473 = validateParameter(valid_614473, JString, required = false,
                                 default = nil)
  if valid_614473 != nil:
    section.add "X-Amz-Date", valid_614473
  var valid_614474 = header.getOrDefault("X-Amz-Credential")
  valid_614474 = validateParameter(valid_614474, JString, required = false,
                                 default = nil)
  if valid_614474 != nil:
    section.add "X-Amz-Credential", valid_614474
  var valid_614475 = header.getOrDefault("X-Amz-Security-Token")
  valid_614475 = validateParameter(valid_614475, JString, required = false,
                                 default = nil)
  if valid_614475 != nil:
    section.add "X-Amz-Security-Token", valid_614475
  var valid_614476 = header.getOrDefault("X-Amz-Algorithm")
  valid_614476 = validateParameter(valid_614476, JString, required = false,
                                 default = nil)
  if valid_614476 != nil:
    section.add "X-Amz-Algorithm", valid_614476
  var valid_614477 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614477 = validateParameter(valid_614477, JString, required = false,
                                 default = nil)
  if valid_614477 != nil:
    section.add "X-Amz-SignedHeaders", valid_614477
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614478: Call_GetRebuildEnvironment_614464; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes and recreates all of the AWS resources (for example: the Auto Scaling group, load balancer, etc.) for a specified environment and forces a restart.
  ## 
  let valid = call_614478.validator(path, query, header, formData, body)
  let scheme = call_614478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614478.url(scheme.get, call_614478.host, call_614478.base,
                         call_614478.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614478, url, valid)

proc call*(call_614479: Call_GetRebuildEnvironment_614464;
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
  var query_614480 = newJObject()
  add(query_614480, "EnvironmentName", newJString(EnvironmentName))
  add(query_614480, "Action", newJString(Action))
  add(query_614480, "Version", newJString(Version))
  add(query_614480, "EnvironmentId", newJString(EnvironmentId))
  result = call_614479.call(nil, query_614480, nil, nil, nil)

var getRebuildEnvironment* = Call_GetRebuildEnvironment_614464(
    name: "getRebuildEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RebuildEnvironment",
    validator: validate_GetRebuildEnvironment_614465, base: "/",
    url: url_GetRebuildEnvironment_614466, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRequestEnvironmentInfo_614517 = ref object of OpenApiRestCall_612659
proc url_PostRequestEnvironmentInfo_614519(protocol: Scheme; host: string;
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

proc validate_PostRequestEnvironmentInfo_614518(path: JsonNode; query: JsonNode;
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
  var valid_614520 = query.getOrDefault("Action")
  valid_614520 = validateParameter(valid_614520, JString, required = true,
                                 default = newJString("RequestEnvironmentInfo"))
  if valid_614520 != nil:
    section.add "Action", valid_614520
  var valid_614521 = query.getOrDefault("Version")
  valid_614521 = validateParameter(valid_614521, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614521 != nil:
    section.add "Version", valid_614521
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
  var valid_614522 = header.getOrDefault("X-Amz-Signature")
  valid_614522 = validateParameter(valid_614522, JString, required = false,
                                 default = nil)
  if valid_614522 != nil:
    section.add "X-Amz-Signature", valid_614522
  var valid_614523 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614523 = validateParameter(valid_614523, JString, required = false,
                                 default = nil)
  if valid_614523 != nil:
    section.add "X-Amz-Content-Sha256", valid_614523
  var valid_614524 = header.getOrDefault("X-Amz-Date")
  valid_614524 = validateParameter(valid_614524, JString, required = false,
                                 default = nil)
  if valid_614524 != nil:
    section.add "X-Amz-Date", valid_614524
  var valid_614525 = header.getOrDefault("X-Amz-Credential")
  valid_614525 = validateParameter(valid_614525, JString, required = false,
                                 default = nil)
  if valid_614525 != nil:
    section.add "X-Amz-Credential", valid_614525
  var valid_614526 = header.getOrDefault("X-Amz-Security-Token")
  valid_614526 = validateParameter(valid_614526, JString, required = false,
                                 default = nil)
  if valid_614526 != nil:
    section.add "X-Amz-Security-Token", valid_614526
  var valid_614527 = header.getOrDefault("X-Amz-Algorithm")
  valid_614527 = validateParameter(valid_614527, JString, required = false,
                                 default = nil)
  if valid_614527 != nil:
    section.add "X-Amz-Algorithm", valid_614527
  var valid_614528 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614528 = validateParameter(valid_614528, JString, required = false,
                                 default = nil)
  if valid_614528 != nil:
    section.add "X-Amz-SignedHeaders", valid_614528
  result.add "header", section
  ## parameters in `formData` object:
  ##   InfoType: JString (required)
  ##           : The type of information to request.
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment of the requested data.</p> <p>If no such environment is found, <code>RequestEnvironmentInfo</code> returns an <code>InvalidParameterValue</code> error. </p> <p>Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment of the requested data.</p> <p>If no such environment is found, <code>RequestEnvironmentInfo</code> returns an <code>InvalidParameterValue</code> error. </p> <p>Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_614529 = formData.getOrDefault("InfoType")
  valid_614529 = validateParameter(valid_614529, JString, required = true,
                                 default = newJString("tail"))
  if valid_614529 != nil:
    section.add "InfoType", valid_614529
  var valid_614530 = formData.getOrDefault("EnvironmentName")
  valid_614530 = validateParameter(valid_614530, JString, required = false,
                                 default = nil)
  if valid_614530 != nil:
    section.add "EnvironmentName", valid_614530
  var valid_614531 = formData.getOrDefault("EnvironmentId")
  valid_614531 = validateParameter(valid_614531, JString, required = false,
                                 default = nil)
  if valid_614531 != nil:
    section.add "EnvironmentId", valid_614531
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614532: Call_PostRequestEnvironmentInfo_614517; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a request to compile the specified type of information of the deployed environment.</p> <p> Setting the <code>InfoType</code> to <code>tail</code> compiles the last lines from the application server log files of every Amazon EC2 instance in your environment. </p> <p> Setting the <code>InfoType</code> to <code>bundle</code> compresses the application server log files for every Amazon EC2 instance into a <code>.zip</code> file. Legacy and .NET containers do not support bundle logs. </p> <p> Use <a>RetrieveEnvironmentInfo</a> to obtain the set of logs. </p> <p>Related Topics</p> <ul> <li> <p> <a>RetrieveEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_614532.validator(path, query, header, formData, body)
  let scheme = call_614532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614532.url(scheme.get, call_614532.host, call_614532.base,
                         call_614532.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614532, url, valid)

proc call*(call_614533: Call_PostRequestEnvironmentInfo_614517;
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
  var query_614534 = newJObject()
  var formData_614535 = newJObject()
  add(formData_614535, "InfoType", newJString(InfoType))
  add(formData_614535, "EnvironmentName", newJString(EnvironmentName))
  add(query_614534, "Action", newJString(Action))
  add(formData_614535, "EnvironmentId", newJString(EnvironmentId))
  add(query_614534, "Version", newJString(Version))
  result = call_614533.call(nil, query_614534, nil, formData_614535, nil)

var postRequestEnvironmentInfo* = Call_PostRequestEnvironmentInfo_614517(
    name: "postRequestEnvironmentInfo", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RequestEnvironmentInfo",
    validator: validate_PostRequestEnvironmentInfo_614518, base: "/",
    url: url_PostRequestEnvironmentInfo_614519,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRequestEnvironmentInfo_614499 = ref object of OpenApiRestCall_612659
proc url_GetRequestEnvironmentInfo_614501(protocol: Scheme; host: string;
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

proc validate_GetRequestEnvironmentInfo_614500(path: JsonNode; query: JsonNode;
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
  var valid_614502 = query.getOrDefault("InfoType")
  valid_614502 = validateParameter(valid_614502, JString, required = true,
                                 default = newJString("tail"))
  if valid_614502 != nil:
    section.add "InfoType", valid_614502
  var valid_614503 = query.getOrDefault("EnvironmentName")
  valid_614503 = validateParameter(valid_614503, JString, required = false,
                                 default = nil)
  if valid_614503 != nil:
    section.add "EnvironmentName", valid_614503
  var valid_614504 = query.getOrDefault("Action")
  valid_614504 = validateParameter(valid_614504, JString, required = true,
                                 default = newJString("RequestEnvironmentInfo"))
  if valid_614504 != nil:
    section.add "Action", valid_614504
  var valid_614505 = query.getOrDefault("Version")
  valid_614505 = validateParameter(valid_614505, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614505 != nil:
    section.add "Version", valid_614505
  var valid_614506 = query.getOrDefault("EnvironmentId")
  valid_614506 = validateParameter(valid_614506, JString, required = false,
                                 default = nil)
  if valid_614506 != nil:
    section.add "EnvironmentId", valid_614506
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
  var valid_614507 = header.getOrDefault("X-Amz-Signature")
  valid_614507 = validateParameter(valid_614507, JString, required = false,
                                 default = nil)
  if valid_614507 != nil:
    section.add "X-Amz-Signature", valid_614507
  var valid_614508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614508 = validateParameter(valid_614508, JString, required = false,
                                 default = nil)
  if valid_614508 != nil:
    section.add "X-Amz-Content-Sha256", valid_614508
  var valid_614509 = header.getOrDefault("X-Amz-Date")
  valid_614509 = validateParameter(valid_614509, JString, required = false,
                                 default = nil)
  if valid_614509 != nil:
    section.add "X-Amz-Date", valid_614509
  var valid_614510 = header.getOrDefault("X-Amz-Credential")
  valid_614510 = validateParameter(valid_614510, JString, required = false,
                                 default = nil)
  if valid_614510 != nil:
    section.add "X-Amz-Credential", valid_614510
  var valid_614511 = header.getOrDefault("X-Amz-Security-Token")
  valid_614511 = validateParameter(valid_614511, JString, required = false,
                                 default = nil)
  if valid_614511 != nil:
    section.add "X-Amz-Security-Token", valid_614511
  var valid_614512 = header.getOrDefault("X-Amz-Algorithm")
  valid_614512 = validateParameter(valid_614512, JString, required = false,
                                 default = nil)
  if valid_614512 != nil:
    section.add "X-Amz-Algorithm", valid_614512
  var valid_614513 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614513 = validateParameter(valid_614513, JString, required = false,
                                 default = nil)
  if valid_614513 != nil:
    section.add "X-Amz-SignedHeaders", valid_614513
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614514: Call_GetRequestEnvironmentInfo_614499; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a request to compile the specified type of information of the deployed environment.</p> <p> Setting the <code>InfoType</code> to <code>tail</code> compiles the last lines from the application server log files of every Amazon EC2 instance in your environment. </p> <p> Setting the <code>InfoType</code> to <code>bundle</code> compresses the application server log files for every Amazon EC2 instance into a <code>.zip</code> file. Legacy and .NET containers do not support bundle logs. </p> <p> Use <a>RetrieveEnvironmentInfo</a> to obtain the set of logs. </p> <p>Related Topics</p> <ul> <li> <p> <a>RetrieveEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_614514.validator(path, query, header, formData, body)
  let scheme = call_614514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614514.url(scheme.get, call_614514.host, call_614514.base,
                         call_614514.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614514, url, valid)

proc call*(call_614515: Call_GetRequestEnvironmentInfo_614499;
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
  var query_614516 = newJObject()
  add(query_614516, "InfoType", newJString(InfoType))
  add(query_614516, "EnvironmentName", newJString(EnvironmentName))
  add(query_614516, "Action", newJString(Action))
  add(query_614516, "Version", newJString(Version))
  add(query_614516, "EnvironmentId", newJString(EnvironmentId))
  result = call_614515.call(nil, query_614516, nil, nil, nil)

var getRequestEnvironmentInfo* = Call_GetRequestEnvironmentInfo_614499(
    name: "getRequestEnvironmentInfo", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RequestEnvironmentInfo",
    validator: validate_GetRequestEnvironmentInfo_614500, base: "/",
    url: url_GetRequestEnvironmentInfo_614501,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestartAppServer_614553 = ref object of OpenApiRestCall_612659
proc url_PostRestartAppServer_614555(protocol: Scheme; host: string; base: string;
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

proc validate_PostRestartAppServer_614554(path: JsonNode; query: JsonNode;
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
  var valid_614556 = query.getOrDefault("Action")
  valid_614556 = validateParameter(valid_614556, JString, required = true,
                                 default = newJString("RestartAppServer"))
  if valid_614556 != nil:
    section.add "Action", valid_614556
  var valid_614557 = query.getOrDefault("Version")
  valid_614557 = validateParameter(valid_614557, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614557 != nil:
    section.add "Version", valid_614557
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
  var valid_614558 = header.getOrDefault("X-Amz-Signature")
  valid_614558 = validateParameter(valid_614558, JString, required = false,
                                 default = nil)
  if valid_614558 != nil:
    section.add "X-Amz-Signature", valid_614558
  var valid_614559 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614559 = validateParameter(valid_614559, JString, required = false,
                                 default = nil)
  if valid_614559 != nil:
    section.add "X-Amz-Content-Sha256", valid_614559
  var valid_614560 = header.getOrDefault("X-Amz-Date")
  valid_614560 = validateParameter(valid_614560, JString, required = false,
                                 default = nil)
  if valid_614560 != nil:
    section.add "X-Amz-Date", valid_614560
  var valid_614561 = header.getOrDefault("X-Amz-Credential")
  valid_614561 = validateParameter(valid_614561, JString, required = false,
                                 default = nil)
  if valid_614561 != nil:
    section.add "X-Amz-Credential", valid_614561
  var valid_614562 = header.getOrDefault("X-Amz-Security-Token")
  valid_614562 = validateParameter(valid_614562, JString, required = false,
                                 default = nil)
  if valid_614562 != nil:
    section.add "X-Amz-Security-Token", valid_614562
  var valid_614563 = header.getOrDefault("X-Amz-Algorithm")
  valid_614563 = validateParameter(valid_614563, JString, required = false,
                                 default = nil)
  if valid_614563 != nil:
    section.add "X-Amz-Algorithm", valid_614563
  var valid_614564 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614564 = validateParameter(valid_614564, JString, required = false,
                                 default = nil)
  if valid_614564 != nil:
    section.add "X-Amz-SignedHeaders", valid_614564
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to restart the server for.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to restart the server for.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_614565 = formData.getOrDefault("EnvironmentName")
  valid_614565 = validateParameter(valid_614565, JString, required = false,
                                 default = nil)
  if valid_614565 != nil:
    section.add "EnvironmentName", valid_614565
  var valid_614566 = formData.getOrDefault("EnvironmentId")
  valid_614566 = validateParameter(valid_614566, JString, required = false,
                                 default = nil)
  if valid_614566 != nil:
    section.add "EnvironmentId", valid_614566
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614567: Call_PostRestartAppServer_614553; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Causes the environment to restart the application container server running on each Amazon EC2 instance.
  ## 
  let valid = call_614567.validator(path, query, header, formData, body)
  let scheme = call_614567.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614567.url(scheme.get, call_614567.host, call_614567.base,
                         call_614567.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614567, url, valid)

proc call*(call_614568: Call_PostRestartAppServer_614553;
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
  var query_614569 = newJObject()
  var formData_614570 = newJObject()
  add(formData_614570, "EnvironmentName", newJString(EnvironmentName))
  add(query_614569, "Action", newJString(Action))
  add(formData_614570, "EnvironmentId", newJString(EnvironmentId))
  add(query_614569, "Version", newJString(Version))
  result = call_614568.call(nil, query_614569, nil, formData_614570, nil)

var postRestartAppServer* = Call_PostRestartAppServer_614553(
    name: "postRestartAppServer", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RestartAppServer",
    validator: validate_PostRestartAppServer_614554, base: "/",
    url: url_PostRestartAppServer_614555, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestartAppServer_614536 = ref object of OpenApiRestCall_612659
proc url_GetRestartAppServer_614538(protocol: Scheme; host: string; base: string;
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

proc validate_GetRestartAppServer_614537(path: JsonNode; query: JsonNode;
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
  var valid_614539 = query.getOrDefault("EnvironmentName")
  valid_614539 = validateParameter(valid_614539, JString, required = false,
                                 default = nil)
  if valid_614539 != nil:
    section.add "EnvironmentName", valid_614539
  var valid_614540 = query.getOrDefault("Action")
  valid_614540 = validateParameter(valid_614540, JString, required = true,
                                 default = newJString("RestartAppServer"))
  if valid_614540 != nil:
    section.add "Action", valid_614540
  var valid_614541 = query.getOrDefault("Version")
  valid_614541 = validateParameter(valid_614541, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614541 != nil:
    section.add "Version", valid_614541
  var valid_614542 = query.getOrDefault("EnvironmentId")
  valid_614542 = validateParameter(valid_614542, JString, required = false,
                                 default = nil)
  if valid_614542 != nil:
    section.add "EnvironmentId", valid_614542
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
  var valid_614543 = header.getOrDefault("X-Amz-Signature")
  valid_614543 = validateParameter(valid_614543, JString, required = false,
                                 default = nil)
  if valid_614543 != nil:
    section.add "X-Amz-Signature", valid_614543
  var valid_614544 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614544 = validateParameter(valid_614544, JString, required = false,
                                 default = nil)
  if valid_614544 != nil:
    section.add "X-Amz-Content-Sha256", valid_614544
  var valid_614545 = header.getOrDefault("X-Amz-Date")
  valid_614545 = validateParameter(valid_614545, JString, required = false,
                                 default = nil)
  if valid_614545 != nil:
    section.add "X-Amz-Date", valid_614545
  var valid_614546 = header.getOrDefault("X-Amz-Credential")
  valid_614546 = validateParameter(valid_614546, JString, required = false,
                                 default = nil)
  if valid_614546 != nil:
    section.add "X-Amz-Credential", valid_614546
  var valid_614547 = header.getOrDefault("X-Amz-Security-Token")
  valid_614547 = validateParameter(valid_614547, JString, required = false,
                                 default = nil)
  if valid_614547 != nil:
    section.add "X-Amz-Security-Token", valid_614547
  var valid_614548 = header.getOrDefault("X-Amz-Algorithm")
  valid_614548 = validateParameter(valid_614548, JString, required = false,
                                 default = nil)
  if valid_614548 != nil:
    section.add "X-Amz-Algorithm", valid_614548
  var valid_614549 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614549 = validateParameter(valid_614549, JString, required = false,
                                 default = nil)
  if valid_614549 != nil:
    section.add "X-Amz-SignedHeaders", valid_614549
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614550: Call_GetRestartAppServer_614536; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Causes the environment to restart the application container server running on each Amazon EC2 instance.
  ## 
  let valid = call_614550.validator(path, query, header, formData, body)
  let scheme = call_614550.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614550.url(scheme.get, call_614550.host, call_614550.base,
                         call_614550.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614550, url, valid)

proc call*(call_614551: Call_GetRestartAppServer_614536;
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
  var query_614552 = newJObject()
  add(query_614552, "EnvironmentName", newJString(EnvironmentName))
  add(query_614552, "Action", newJString(Action))
  add(query_614552, "Version", newJString(Version))
  add(query_614552, "EnvironmentId", newJString(EnvironmentId))
  result = call_614551.call(nil, query_614552, nil, nil, nil)

var getRestartAppServer* = Call_GetRestartAppServer_614536(
    name: "getRestartAppServer", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RestartAppServer",
    validator: validate_GetRestartAppServer_614537, base: "/",
    url: url_GetRestartAppServer_614538, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRetrieveEnvironmentInfo_614589 = ref object of OpenApiRestCall_612659
proc url_PostRetrieveEnvironmentInfo_614591(protocol: Scheme; host: string;
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

proc validate_PostRetrieveEnvironmentInfo_614590(path: JsonNode; query: JsonNode;
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
  var valid_614592 = query.getOrDefault("Action")
  valid_614592 = validateParameter(valid_614592, JString, required = true, default = newJString(
      "RetrieveEnvironmentInfo"))
  if valid_614592 != nil:
    section.add "Action", valid_614592
  var valid_614593 = query.getOrDefault("Version")
  valid_614593 = validateParameter(valid_614593, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614593 != nil:
    section.add "Version", valid_614593
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
  var valid_614594 = header.getOrDefault("X-Amz-Signature")
  valid_614594 = validateParameter(valid_614594, JString, required = false,
                                 default = nil)
  if valid_614594 != nil:
    section.add "X-Amz-Signature", valid_614594
  var valid_614595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614595 = validateParameter(valid_614595, JString, required = false,
                                 default = nil)
  if valid_614595 != nil:
    section.add "X-Amz-Content-Sha256", valid_614595
  var valid_614596 = header.getOrDefault("X-Amz-Date")
  valid_614596 = validateParameter(valid_614596, JString, required = false,
                                 default = nil)
  if valid_614596 != nil:
    section.add "X-Amz-Date", valid_614596
  var valid_614597 = header.getOrDefault("X-Amz-Credential")
  valid_614597 = validateParameter(valid_614597, JString, required = false,
                                 default = nil)
  if valid_614597 != nil:
    section.add "X-Amz-Credential", valid_614597
  var valid_614598 = header.getOrDefault("X-Amz-Security-Token")
  valid_614598 = validateParameter(valid_614598, JString, required = false,
                                 default = nil)
  if valid_614598 != nil:
    section.add "X-Amz-Security-Token", valid_614598
  var valid_614599 = header.getOrDefault("X-Amz-Algorithm")
  valid_614599 = validateParameter(valid_614599, JString, required = false,
                                 default = nil)
  if valid_614599 != nil:
    section.add "X-Amz-Algorithm", valid_614599
  var valid_614600 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614600 = validateParameter(valid_614600, JString, required = false,
                                 default = nil)
  if valid_614600 != nil:
    section.add "X-Amz-SignedHeaders", valid_614600
  result.add "header", section
  ## parameters in `formData` object:
  ##   InfoType: JString (required)
  ##           : The type of information to retrieve.
  ##   EnvironmentName: JString
  ##                  : <p>The name of the data's environment.</p> <p> If no such environment is found, returns an <code>InvalidParameterValue</code> error. </p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentId: JString
  ##                : <p>The ID of the data's environment.</p> <p>If no such environment is found, returns an <code>InvalidParameterValue</code> error.</p> <p>Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error.</p>
  section = newJObject()
  var valid_614601 = formData.getOrDefault("InfoType")
  valid_614601 = validateParameter(valid_614601, JString, required = true,
                                 default = newJString("tail"))
  if valid_614601 != nil:
    section.add "InfoType", valid_614601
  var valid_614602 = formData.getOrDefault("EnvironmentName")
  valid_614602 = validateParameter(valid_614602, JString, required = false,
                                 default = nil)
  if valid_614602 != nil:
    section.add "EnvironmentName", valid_614602
  var valid_614603 = formData.getOrDefault("EnvironmentId")
  valid_614603 = validateParameter(valid_614603, JString, required = false,
                                 default = nil)
  if valid_614603 != nil:
    section.add "EnvironmentId", valid_614603
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614604: Call_PostRetrieveEnvironmentInfo_614589; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the compiled information from a <a>RequestEnvironmentInfo</a> request.</p> <p>Related Topics</p> <ul> <li> <p> <a>RequestEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_614604.validator(path, query, header, formData, body)
  let scheme = call_614604.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614604.url(scheme.get, call_614604.host, call_614604.base,
                         call_614604.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614604, url, valid)

proc call*(call_614605: Call_PostRetrieveEnvironmentInfo_614589;
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
  var query_614606 = newJObject()
  var formData_614607 = newJObject()
  add(formData_614607, "InfoType", newJString(InfoType))
  add(formData_614607, "EnvironmentName", newJString(EnvironmentName))
  add(query_614606, "Action", newJString(Action))
  add(formData_614607, "EnvironmentId", newJString(EnvironmentId))
  add(query_614606, "Version", newJString(Version))
  result = call_614605.call(nil, query_614606, nil, formData_614607, nil)

var postRetrieveEnvironmentInfo* = Call_PostRetrieveEnvironmentInfo_614589(
    name: "postRetrieveEnvironmentInfo", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RetrieveEnvironmentInfo",
    validator: validate_PostRetrieveEnvironmentInfo_614590, base: "/",
    url: url_PostRetrieveEnvironmentInfo_614591,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRetrieveEnvironmentInfo_614571 = ref object of OpenApiRestCall_612659
proc url_GetRetrieveEnvironmentInfo_614573(protocol: Scheme; host: string;
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

proc validate_GetRetrieveEnvironmentInfo_614572(path: JsonNode; query: JsonNode;
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
  var valid_614574 = query.getOrDefault("InfoType")
  valid_614574 = validateParameter(valid_614574, JString, required = true,
                                 default = newJString("tail"))
  if valid_614574 != nil:
    section.add "InfoType", valid_614574
  var valid_614575 = query.getOrDefault("EnvironmentName")
  valid_614575 = validateParameter(valid_614575, JString, required = false,
                                 default = nil)
  if valid_614575 != nil:
    section.add "EnvironmentName", valid_614575
  var valid_614576 = query.getOrDefault("Action")
  valid_614576 = validateParameter(valid_614576, JString, required = true, default = newJString(
      "RetrieveEnvironmentInfo"))
  if valid_614576 != nil:
    section.add "Action", valid_614576
  var valid_614577 = query.getOrDefault("Version")
  valid_614577 = validateParameter(valid_614577, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614577 != nil:
    section.add "Version", valid_614577
  var valid_614578 = query.getOrDefault("EnvironmentId")
  valid_614578 = validateParameter(valid_614578, JString, required = false,
                                 default = nil)
  if valid_614578 != nil:
    section.add "EnvironmentId", valid_614578
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
  var valid_614579 = header.getOrDefault("X-Amz-Signature")
  valid_614579 = validateParameter(valid_614579, JString, required = false,
                                 default = nil)
  if valid_614579 != nil:
    section.add "X-Amz-Signature", valid_614579
  var valid_614580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614580 = validateParameter(valid_614580, JString, required = false,
                                 default = nil)
  if valid_614580 != nil:
    section.add "X-Amz-Content-Sha256", valid_614580
  var valid_614581 = header.getOrDefault("X-Amz-Date")
  valid_614581 = validateParameter(valid_614581, JString, required = false,
                                 default = nil)
  if valid_614581 != nil:
    section.add "X-Amz-Date", valid_614581
  var valid_614582 = header.getOrDefault("X-Amz-Credential")
  valid_614582 = validateParameter(valid_614582, JString, required = false,
                                 default = nil)
  if valid_614582 != nil:
    section.add "X-Amz-Credential", valid_614582
  var valid_614583 = header.getOrDefault("X-Amz-Security-Token")
  valid_614583 = validateParameter(valid_614583, JString, required = false,
                                 default = nil)
  if valid_614583 != nil:
    section.add "X-Amz-Security-Token", valid_614583
  var valid_614584 = header.getOrDefault("X-Amz-Algorithm")
  valid_614584 = validateParameter(valid_614584, JString, required = false,
                                 default = nil)
  if valid_614584 != nil:
    section.add "X-Amz-Algorithm", valid_614584
  var valid_614585 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614585 = validateParameter(valid_614585, JString, required = false,
                                 default = nil)
  if valid_614585 != nil:
    section.add "X-Amz-SignedHeaders", valid_614585
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614586: Call_GetRetrieveEnvironmentInfo_614571; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the compiled information from a <a>RequestEnvironmentInfo</a> request.</p> <p>Related Topics</p> <ul> <li> <p> <a>RequestEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_614586.validator(path, query, header, formData, body)
  let scheme = call_614586.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614586.url(scheme.get, call_614586.host, call_614586.base,
                         call_614586.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614586, url, valid)

proc call*(call_614587: Call_GetRetrieveEnvironmentInfo_614571;
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
  var query_614588 = newJObject()
  add(query_614588, "InfoType", newJString(InfoType))
  add(query_614588, "EnvironmentName", newJString(EnvironmentName))
  add(query_614588, "Action", newJString(Action))
  add(query_614588, "Version", newJString(Version))
  add(query_614588, "EnvironmentId", newJString(EnvironmentId))
  result = call_614587.call(nil, query_614588, nil, nil, nil)

var getRetrieveEnvironmentInfo* = Call_GetRetrieveEnvironmentInfo_614571(
    name: "getRetrieveEnvironmentInfo", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RetrieveEnvironmentInfo",
    validator: validate_GetRetrieveEnvironmentInfo_614572, base: "/",
    url: url_GetRetrieveEnvironmentInfo_614573,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSwapEnvironmentCNAMEs_614627 = ref object of OpenApiRestCall_612659
proc url_PostSwapEnvironmentCNAMEs_614629(protocol: Scheme; host: string;
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

proc validate_PostSwapEnvironmentCNAMEs_614628(path: JsonNode; query: JsonNode;
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
  var valid_614630 = query.getOrDefault("Action")
  valid_614630 = validateParameter(valid_614630, JString, required = true,
                                 default = newJString("SwapEnvironmentCNAMEs"))
  if valid_614630 != nil:
    section.add "Action", valid_614630
  var valid_614631 = query.getOrDefault("Version")
  valid_614631 = validateParameter(valid_614631, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614631 != nil:
    section.add "Version", valid_614631
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
  var valid_614632 = header.getOrDefault("X-Amz-Signature")
  valid_614632 = validateParameter(valid_614632, JString, required = false,
                                 default = nil)
  if valid_614632 != nil:
    section.add "X-Amz-Signature", valid_614632
  var valid_614633 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614633 = validateParameter(valid_614633, JString, required = false,
                                 default = nil)
  if valid_614633 != nil:
    section.add "X-Amz-Content-Sha256", valid_614633
  var valid_614634 = header.getOrDefault("X-Amz-Date")
  valid_614634 = validateParameter(valid_614634, JString, required = false,
                                 default = nil)
  if valid_614634 != nil:
    section.add "X-Amz-Date", valid_614634
  var valid_614635 = header.getOrDefault("X-Amz-Credential")
  valid_614635 = validateParameter(valid_614635, JString, required = false,
                                 default = nil)
  if valid_614635 != nil:
    section.add "X-Amz-Credential", valid_614635
  var valid_614636 = header.getOrDefault("X-Amz-Security-Token")
  valid_614636 = validateParameter(valid_614636, JString, required = false,
                                 default = nil)
  if valid_614636 != nil:
    section.add "X-Amz-Security-Token", valid_614636
  var valid_614637 = header.getOrDefault("X-Amz-Algorithm")
  valid_614637 = validateParameter(valid_614637, JString, required = false,
                                 default = nil)
  if valid_614637 != nil:
    section.add "X-Amz-Algorithm", valid_614637
  var valid_614638 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614638 = validateParameter(valid_614638, JString, required = false,
                                 default = nil)
  if valid_614638 != nil:
    section.add "X-Amz-SignedHeaders", valid_614638
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
  var valid_614639 = formData.getOrDefault("DestinationEnvironmentName")
  valid_614639 = validateParameter(valid_614639, JString, required = false,
                                 default = nil)
  if valid_614639 != nil:
    section.add "DestinationEnvironmentName", valid_614639
  var valid_614640 = formData.getOrDefault("DestinationEnvironmentId")
  valid_614640 = validateParameter(valid_614640, JString, required = false,
                                 default = nil)
  if valid_614640 != nil:
    section.add "DestinationEnvironmentId", valid_614640
  var valid_614641 = formData.getOrDefault("SourceEnvironmentId")
  valid_614641 = validateParameter(valid_614641, JString, required = false,
                                 default = nil)
  if valid_614641 != nil:
    section.add "SourceEnvironmentId", valid_614641
  var valid_614642 = formData.getOrDefault("SourceEnvironmentName")
  valid_614642 = validateParameter(valid_614642, JString, required = false,
                                 default = nil)
  if valid_614642 != nil:
    section.add "SourceEnvironmentName", valid_614642
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614643: Call_PostSwapEnvironmentCNAMEs_614627; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Swaps the CNAMEs of two environments.
  ## 
  let valid = call_614643.validator(path, query, header, formData, body)
  let scheme = call_614643.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614643.url(scheme.get, call_614643.host, call_614643.base,
                         call_614643.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614643, url, valid)

proc call*(call_614644: Call_PostSwapEnvironmentCNAMEs_614627;
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
  var query_614645 = newJObject()
  var formData_614646 = newJObject()
  add(formData_614646, "DestinationEnvironmentName",
      newJString(DestinationEnvironmentName))
  add(formData_614646, "DestinationEnvironmentId",
      newJString(DestinationEnvironmentId))
  add(formData_614646, "SourceEnvironmentId", newJString(SourceEnvironmentId))
  add(formData_614646, "SourceEnvironmentName", newJString(SourceEnvironmentName))
  add(query_614645, "Action", newJString(Action))
  add(query_614645, "Version", newJString(Version))
  result = call_614644.call(nil, query_614645, nil, formData_614646, nil)

var postSwapEnvironmentCNAMEs* = Call_PostSwapEnvironmentCNAMEs_614627(
    name: "postSwapEnvironmentCNAMEs", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=SwapEnvironmentCNAMEs",
    validator: validate_PostSwapEnvironmentCNAMEs_614628, base: "/",
    url: url_PostSwapEnvironmentCNAMEs_614629,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSwapEnvironmentCNAMEs_614608 = ref object of OpenApiRestCall_612659
proc url_GetSwapEnvironmentCNAMEs_614610(protocol: Scheme; host: string;
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

proc validate_GetSwapEnvironmentCNAMEs_614609(path: JsonNode; query: JsonNode;
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
  var valid_614611 = query.getOrDefault("SourceEnvironmentId")
  valid_614611 = validateParameter(valid_614611, JString, required = false,
                                 default = nil)
  if valid_614611 != nil:
    section.add "SourceEnvironmentId", valid_614611
  var valid_614612 = query.getOrDefault("SourceEnvironmentName")
  valid_614612 = validateParameter(valid_614612, JString, required = false,
                                 default = nil)
  if valid_614612 != nil:
    section.add "SourceEnvironmentName", valid_614612
  var valid_614613 = query.getOrDefault("DestinationEnvironmentName")
  valid_614613 = validateParameter(valid_614613, JString, required = false,
                                 default = nil)
  if valid_614613 != nil:
    section.add "DestinationEnvironmentName", valid_614613
  var valid_614614 = query.getOrDefault("Action")
  valid_614614 = validateParameter(valid_614614, JString, required = true,
                                 default = newJString("SwapEnvironmentCNAMEs"))
  if valid_614614 != nil:
    section.add "Action", valid_614614
  var valid_614615 = query.getOrDefault("DestinationEnvironmentId")
  valid_614615 = validateParameter(valid_614615, JString, required = false,
                                 default = nil)
  if valid_614615 != nil:
    section.add "DestinationEnvironmentId", valid_614615
  var valid_614616 = query.getOrDefault("Version")
  valid_614616 = validateParameter(valid_614616, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614616 != nil:
    section.add "Version", valid_614616
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
  var valid_614617 = header.getOrDefault("X-Amz-Signature")
  valid_614617 = validateParameter(valid_614617, JString, required = false,
                                 default = nil)
  if valid_614617 != nil:
    section.add "X-Amz-Signature", valid_614617
  var valid_614618 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614618 = validateParameter(valid_614618, JString, required = false,
                                 default = nil)
  if valid_614618 != nil:
    section.add "X-Amz-Content-Sha256", valid_614618
  var valid_614619 = header.getOrDefault("X-Amz-Date")
  valid_614619 = validateParameter(valid_614619, JString, required = false,
                                 default = nil)
  if valid_614619 != nil:
    section.add "X-Amz-Date", valid_614619
  var valid_614620 = header.getOrDefault("X-Amz-Credential")
  valid_614620 = validateParameter(valid_614620, JString, required = false,
                                 default = nil)
  if valid_614620 != nil:
    section.add "X-Amz-Credential", valid_614620
  var valid_614621 = header.getOrDefault("X-Amz-Security-Token")
  valid_614621 = validateParameter(valid_614621, JString, required = false,
                                 default = nil)
  if valid_614621 != nil:
    section.add "X-Amz-Security-Token", valid_614621
  var valid_614622 = header.getOrDefault("X-Amz-Algorithm")
  valid_614622 = validateParameter(valid_614622, JString, required = false,
                                 default = nil)
  if valid_614622 != nil:
    section.add "X-Amz-Algorithm", valid_614622
  var valid_614623 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614623 = validateParameter(valid_614623, JString, required = false,
                                 default = nil)
  if valid_614623 != nil:
    section.add "X-Amz-SignedHeaders", valid_614623
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614624: Call_GetSwapEnvironmentCNAMEs_614608; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Swaps the CNAMEs of two environments.
  ## 
  let valid = call_614624.validator(path, query, header, formData, body)
  let scheme = call_614624.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614624.url(scheme.get, call_614624.host, call_614624.base,
                         call_614624.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614624, url, valid)

proc call*(call_614625: Call_GetSwapEnvironmentCNAMEs_614608;
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
  var query_614626 = newJObject()
  add(query_614626, "SourceEnvironmentId", newJString(SourceEnvironmentId))
  add(query_614626, "SourceEnvironmentName", newJString(SourceEnvironmentName))
  add(query_614626, "DestinationEnvironmentName",
      newJString(DestinationEnvironmentName))
  add(query_614626, "Action", newJString(Action))
  add(query_614626, "DestinationEnvironmentId",
      newJString(DestinationEnvironmentId))
  add(query_614626, "Version", newJString(Version))
  result = call_614625.call(nil, query_614626, nil, nil, nil)

var getSwapEnvironmentCNAMEs* = Call_GetSwapEnvironmentCNAMEs_614608(
    name: "getSwapEnvironmentCNAMEs", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=SwapEnvironmentCNAMEs",
    validator: validate_GetSwapEnvironmentCNAMEs_614609, base: "/",
    url: url_GetSwapEnvironmentCNAMEs_614610, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostTerminateEnvironment_614666 = ref object of OpenApiRestCall_612659
proc url_PostTerminateEnvironment_614668(protocol: Scheme; host: string;
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

proc validate_PostTerminateEnvironment_614667(path: JsonNode; query: JsonNode;
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
  var valid_614669 = query.getOrDefault("Action")
  valid_614669 = validateParameter(valid_614669, JString, required = true,
                                 default = newJString("TerminateEnvironment"))
  if valid_614669 != nil:
    section.add "Action", valid_614669
  var valid_614670 = query.getOrDefault("Version")
  valid_614670 = validateParameter(valid_614670, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614670 != nil:
    section.add "Version", valid_614670
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
  var valid_614671 = header.getOrDefault("X-Amz-Signature")
  valid_614671 = validateParameter(valid_614671, JString, required = false,
                                 default = nil)
  if valid_614671 != nil:
    section.add "X-Amz-Signature", valid_614671
  var valid_614672 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614672 = validateParameter(valid_614672, JString, required = false,
                                 default = nil)
  if valid_614672 != nil:
    section.add "X-Amz-Content-Sha256", valid_614672
  var valid_614673 = header.getOrDefault("X-Amz-Date")
  valid_614673 = validateParameter(valid_614673, JString, required = false,
                                 default = nil)
  if valid_614673 != nil:
    section.add "X-Amz-Date", valid_614673
  var valid_614674 = header.getOrDefault("X-Amz-Credential")
  valid_614674 = validateParameter(valid_614674, JString, required = false,
                                 default = nil)
  if valid_614674 != nil:
    section.add "X-Amz-Credential", valid_614674
  var valid_614675 = header.getOrDefault("X-Amz-Security-Token")
  valid_614675 = validateParameter(valid_614675, JString, required = false,
                                 default = nil)
  if valid_614675 != nil:
    section.add "X-Amz-Security-Token", valid_614675
  var valid_614676 = header.getOrDefault("X-Amz-Algorithm")
  valid_614676 = validateParameter(valid_614676, JString, required = false,
                                 default = nil)
  if valid_614676 != nil:
    section.add "X-Amz-Algorithm", valid_614676
  var valid_614677 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614677 = validateParameter(valid_614677, JString, required = false,
                                 default = nil)
  if valid_614677 != nil:
    section.add "X-Amz-SignedHeaders", valid_614677
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
  var valid_614678 = formData.getOrDefault("EnvironmentName")
  valid_614678 = validateParameter(valid_614678, JString, required = false,
                                 default = nil)
  if valid_614678 != nil:
    section.add "EnvironmentName", valid_614678
  var valid_614679 = formData.getOrDefault("TerminateResources")
  valid_614679 = validateParameter(valid_614679, JBool, required = false, default = nil)
  if valid_614679 != nil:
    section.add "TerminateResources", valid_614679
  var valid_614680 = formData.getOrDefault("ForceTerminate")
  valid_614680 = validateParameter(valid_614680, JBool, required = false, default = nil)
  if valid_614680 != nil:
    section.add "ForceTerminate", valid_614680
  var valid_614681 = formData.getOrDefault("EnvironmentId")
  valid_614681 = validateParameter(valid_614681, JString, required = false,
                                 default = nil)
  if valid_614681 != nil:
    section.add "EnvironmentId", valid_614681
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614682: Call_PostTerminateEnvironment_614666; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Terminates the specified environment.
  ## 
  let valid = call_614682.validator(path, query, header, formData, body)
  let scheme = call_614682.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614682.url(scheme.get, call_614682.host, call_614682.base,
                         call_614682.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614682, url, valid)

proc call*(call_614683: Call_PostTerminateEnvironment_614666;
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
  var query_614684 = newJObject()
  var formData_614685 = newJObject()
  add(formData_614685, "EnvironmentName", newJString(EnvironmentName))
  add(formData_614685, "TerminateResources", newJBool(TerminateResources))
  add(query_614684, "Action", newJString(Action))
  add(formData_614685, "ForceTerminate", newJBool(ForceTerminate))
  add(formData_614685, "EnvironmentId", newJString(EnvironmentId))
  add(query_614684, "Version", newJString(Version))
  result = call_614683.call(nil, query_614684, nil, formData_614685, nil)

var postTerminateEnvironment* = Call_PostTerminateEnvironment_614666(
    name: "postTerminateEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=TerminateEnvironment",
    validator: validate_PostTerminateEnvironment_614667, base: "/",
    url: url_PostTerminateEnvironment_614668, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTerminateEnvironment_614647 = ref object of OpenApiRestCall_612659
proc url_GetTerminateEnvironment_614649(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
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

proc validate_GetTerminateEnvironment_614648(path: JsonNode; query: JsonNode;
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
  var valid_614650 = query.getOrDefault("ForceTerminate")
  valid_614650 = validateParameter(valid_614650, JBool, required = false, default = nil)
  if valid_614650 != nil:
    section.add "ForceTerminate", valid_614650
  var valid_614651 = query.getOrDefault("TerminateResources")
  valid_614651 = validateParameter(valid_614651, JBool, required = false, default = nil)
  if valid_614651 != nil:
    section.add "TerminateResources", valid_614651
  var valid_614652 = query.getOrDefault("EnvironmentName")
  valid_614652 = validateParameter(valid_614652, JString, required = false,
                                 default = nil)
  if valid_614652 != nil:
    section.add "EnvironmentName", valid_614652
  var valid_614653 = query.getOrDefault("Action")
  valid_614653 = validateParameter(valid_614653, JString, required = true,
                                 default = newJString("TerminateEnvironment"))
  if valid_614653 != nil:
    section.add "Action", valid_614653
  var valid_614654 = query.getOrDefault("Version")
  valid_614654 = validateParameter(valid_614654, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614654 != nil:
    section.add "Version", valid_614654
  var valid_614655 = query.getOrDefault("EnvironmentId")
  valid_614655 = validateParameter(valid_614655, JString, required = false,
                                 default = nil)
  if valid_614655 != nil:
    section.add "EnvironmentId", valid_614655
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
  var valid_614656 = header.getOrDefault("X-Amz-Signature")
  valid_614656 = validateParameter(valid_614656, JString, required = false,
                                 default = nil)
  if valid_614656 != nil:
    section.add "X-Amz-Signature", valid_614656
  var valid_614657 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614657 = validateParameter(valid_614657, JString, required = false,
                                 default = nil)
  if valid_614657 != nil:
    section.add "X-Amz-Content-Sha256", valid_614657
  var valid_614658 = header.getOrDefault("X-Amz-Date")
  valid_614658 = validateParameter(valid_614658, JString, required = false,
                                 default = nil)
  if valid_614658 != nil:
    section.add "X-Amz-Date", valid_614658
  var valid_614659 = header.getOrDefault("X-Amz-Credential")
  valid_614659 = validateParameter(valid_614659, JString, required = false,
                                 default = nil)
  if valid_614659 != nil:
    section.add "X-Amz-Credential", valid_614659
  var valid_614660 = header.getOrDefault("X-Amz-Security-Token")
  valid_614660 = validateParameter(valid_614660, JString, required = false,
                                 default = nil)
  if valid_614660 != nil:
    section.add "X-Amz-Security-Token", valid_614660
  var valid_614661 = header.getOrDefault("X-Amz-Algorithm")
  valid_614661 = validateParameter(valid_614661, JString, required = false,
                                 default = nil)
  if valid_614661 != nil:
    section.add "X-Amz-Algorithm", valid_614661
  var valid_614662 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614662 = validateParameter(valid_614662, JString, required = false,
                                 default = nil)
  if valid_614662 != nil:
    section.add "X-Amz-SignedHeaders", valid_614662
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614663: Call_GetTerminateEnvironment_614647; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Terminates the specified environment.
  ## 
  let valid = call_614663.validator(path, query, header, formData, body)
  let scheme = call_614663.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614663.url(scheme.get, call_614663.host, call_614663.base,
                         call_614663.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614663, url, valid)

proc call*(call_614664: Call_GetTerminateEnvironment_614647;
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
  var query_614665 = newJObject()
  add(query_614665, "ForceTerminate", newJBool(ForceTerminate))
  add(query_614665, "TerminateResources", newJBool(TerminateResources))
  add(query_614665, "EnvironmentName", newJString(EnvironmentName))
  add(query_614665, "Action", newJString(Action))
  add(query_614665, "Version", newJString(Version))
  add(query_614665, "EnvironmentId", newJString(EnvironmentId))
  result = call_614664.call(nil, query_614665, nil, nil, nil)

var getTerminateEnvironment* = Call_GetTerminateEnvironment_614647(
    name: "getTerminateEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=TerminateEnvironment",
    validator: validate_GetTerminateEnvironment_614648, base: "/",
    url: url_GetTerminateEnvironment_614649, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateApplication_614703 = ref object of OpenApiRestCall_612659
proc url_PostUpdateApplication_614705(protocol: Scheme; host: string; base: string;
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

proc validate_PostUpdateApplication_614704(path: JsonNode; query: JsonNode;
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
  var valid_614706 = query.getOrDefault("Action")
  valid_614706 = validateParameter(valid_614706, JString, required = true,
                                 default = newJString("UpdateApplication"))
  if valid_614706 != nil:
    section.add "Action", valid_614706
  var valid_614707 = query.getOrDefault("Version")
  valid_614707 = validateParameter(valid_614707, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614707 != nil:
    section.add "Version", valid_614707
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
  var valid_614708 = header.getOrDefault("X-Amz-Signature")
  valid_614708 = validateParameter(valid_614708, JString, required = false,
                                 default = nil)
  if valid_614708 != nil:
    section.add "X-Amz-Signature", valid_614708
  var valid_614709 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614709 = validateParameter(valid_614709, JString, required = false,
                                 default = nil)
  if valid_614709 != nil:
    section.add "X-Amz-Content-Sha256", valid_614709
  var valid_614710 = header.getOrDefault("X-Amz-Date")
  valid_614710 = validateParameter(valid_614710, JString, required = false,
                                 default = nil)
  if valid_614710 != nil:
    section.add "X-Amz-Date", valid_614710
  var valid_614711 = header.getOrDefault("X-Amz-Credential")
  valid_614711 = validateParameter(valid_614711, JString, required = false,
                                 default = nil)
  if valid_614711 != nil:
    section.add "X-Amz-Credential", valid_614711
  var valid_614712 = header.getOrDefault("X-Amz-Security-Token")
  valid_614712 = validateParameter(valid_614712, JString, required = false,
                                 default = nil)
  if valid_614712 != nil:
    section.add "X-Amz-Security-Token", valid_614712
  var valid_614713 = header.getOrDefault("X-Amz-Algorithm")
  valid_614713 = validateParameter(valid_614713, JString, required = false,
                                 default = nil)
  if valid_614713 != nil:
    section.add "X-Amz-Algorithm", valid_614713
  var valid_614714 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614714 = validateParameter(valid_614714, JString, required = false,
                                 default = nil)
  if valid_614714 != nil:
    section.add "X-Amz-SignedHeaders", valid_614714
  result.add "header", section
  ## parameters in `formData` object:
  ##   Description: JString
  ##              : <p>A new description for the application.</p> <p>Default: If not specified, AWS Elastic Beanstalk does not update the description.</p>
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to update. If no such application is found, <code>UpdateApplication</code> returns an <code>InvalidParameterValue</code> error. 
  section = newJObject()
  var valid_614715 = formData.getOrDefault("Description")
  valid_614715 = validateParameter(valid_614715, JString, required = false,
                                 default = nil)
  if valid_614715 != nil:
    section.add "Description", valid_614715
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_614716 = formData.getOrDefault("ApplicationName")
  valid_614716 = validateParameter(valid_614716, JString, required = true,
                                 default = nil)
  if valid_614716 != nil:
    section.add "ApplicationName", valid_614716
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614717: Call_PostUpdateApplication_614703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified application to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear these properties, specify an empty string.</p> </note>
  ## 
  let valid = call_614717.validator(path, query, header, formData, body)
  let scheme = call_614717.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614717.url(scheme.get, call_614717.host, call_614717.base,
                         call_614717.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614717, url, valid)

proc call*(call_614718: Call_PostUpdateApplication_614703; ApplicationName: string;
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
  var query_614719 = newJObject()
  var formData_614720 = newJObject()
  add(formData_614720, "Description", newJString(Description))
  add(formData_614720, "ApplicationName", newJString(ApplicationName))
  add(query_614719, "Action", newJString(Action))
  add(query_614719, "Version", newJString(Version))
  result = call_614718.call(nil, query_614719, nil, formData_614720, nil)

var postUpdateApplication* = Call_PostUpdateApplication_614703(
    name: "postUpdateApplication", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateApplication",
    validator: validate_PostUpdateApplication_614704, base: "/",
    url: url_PostUpdateApplication_614705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateApplication_614686 = ref object of OpenApiRestCall_612659
proc url_GetUpdateApplication_614688(protocol: Scheme; host: string; base: string;
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

proc validate_GetUpdateApplication_614687(path: JsonNode; query: JsonNode;
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
  var valid_614689 = query.getOrDefault("ApplicationName")
  valid_614689 = validateParameter(valid_614689, JString, required = true,
                                 default = nil)
  if valid_614689 != nil:
    section.add "ApplicationName", valid_614689
  var valid_614690 = query.getOrDefault("Action")
  valid_614690 = validateParameter(valid_614690, JString, required = true,
                                 default = newJString("UpdateApplication"))
  if valid_614690 != nil:
    section.add "Action", valid_614690
  var valid_614691 = query.getOrDefault("Description")
  valid_614691 = validateParameter(valid_614691, JString, required = false,
                                 default = nil)
  if valid_614691 != nil:
    section.add "Description", valid_614691
  var valid_614692 = query.getOrDefault("Version")
  valid_614692 = validateParameter(valid_614692, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614692 != nil:
    section.add "Version", valid_614692
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
  var valid_614693 = header.getOrDefault("X-Amz-Signature")
  valid_614693 = validateParameter(valid_614693, JString, required = false,
                                 default = nil)
  if valid_614693 != nil:
    section.add "X-Amz-Signature", valid_614693
  var valid_614694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614694 = validateParameter(valid_614694, JString, required = false,
                                 default = nil)
  if valid_614694 != nil:
    section.add "X-Amz-Content-Sha256", valid_614694
  var valid_614695 = header.getOrDefault("X-Amz-Date")
  valid_614695 = validateParameter(valid_614695, JString, required = false,
                                 default = nil)
  if valid_614695 != nil:
    section.add "X-Amz-Date", valid_614695
  var valid_614696 = header.getOrDefault("X-Amz-Credential")
  valid_614696 = validateParameter(valid_614696, JString, required = false,
                                 default = nil)
  if valid_614696 != nil:
    section.add "X-Amz-Credential", valid_614696
  var valid_614697 = header.getOrDefault("X-Amz-Security-Token")
  valid_614697 = validateParameter(valid_614697, JString, required = false,
                                 default = nil)
  if valid_614697 != nil:
    section.add "X-Amz-Security-Token", valid_614697
  var valid_614698 = header.getOrDefault("X-Amz-Algorithm")
  valid_614698 = validateParameter(valid_614698, JString, required = false,
                                 default = nil)
  if valid_614698 != nil:
    section.add "X-Amz-Algorithm", valid_614698
  var valid_614699 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614699 = validateParameter(valid_614699, JString, required = false,
                                 default = nil)
  if valid_614699 != nil:
    section.add "X-Amz-SignedHeaders", valid_614699
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614700: Call_GetUpdateApplication_614686; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified application to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear these properties, specify an empty string.</p> </note>
  ## 
  let valid = call_614700.validator(path, query, header, formData, body)
  let scheme = call_614700.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614700.url(scheme.get, call_614700.host, call_614700.base,
                         call_614700.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614700, url, valid)

proc call*(call_614701: Call_GetUpdateApplication_614686; ApplicationName: string;
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
  var query_614702 = newJObject()
  add(query_614702, "ApplicationName", newJString(ApplicationName))
  add(query_614702, "Action", newJString(Action))
  add(query_614702, "Description", newJString(Description))
  add(query_614702, "Version", newJString(Version))
  result = call_614701.call(nil, query_614702, nil, nil, nil)

var getUpdateApplication* = Call_GetUpdateApplication_614686(
    name: "getUpdateApplication", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateApplication",
    validator: validate_GetUpdateApplication_614687, base: "/",
    url: url_GetUpdateApplication_614688, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateApplicationResourceLifecycle_614739 = ref object of OpenApiRestCall_612659
proc url_PostUpdateApplicationResourceLifecycle_614741(protocol: Scheme;
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

proc validate_PostUpdateApplicationResourceLifecycle_614740(path: JsonNode;
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
  var valid_614742 = query.getOrDefault("Action")
  valid_614742 = validateParameter(valid_614742, JString, required = true, default = newJString(
      "UpdateApplicationResourceLifecycle"))
  if valid_614742 != nil:
    section.add "Action", valid_614742
  var valid_614743 = query.getOrDefault("Version")
  valid_614743 = validateParameter(valid_614743, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614743 != nil:
    section.add "Version", valid_614743
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
  var valid_614744 = header.getOrDefault("X-Amz-Signature")
  valid_614744 = validateParameter(valid_614744, JString, required = false,
                                 default = nil)
  if valid_614744 != nil:
    section.add "X-Amz-Signature", valid_614744
  var valid_614745 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614745 = validateParameter(valid_614745, JString, required = false,
                                 default = nil)
  if valid_614745 != nil:
    section.add "X-Amz-Content-Sha256", valid_614745
  var valid_614746 = header.getOrDefault("X-Amz-Date")
  valid_614746 = validateParameter(valid_614746, JString, required = false,
                                 default = nil)
  if valid_614746 != nil:
    section.add "X-Amz-Date", valid_614746
  var valid_614747 = header.getOrDefault("X-Amz-Credential")
  valid_614747 = validateParameter(valid_614747, JString, required = false,
                                 default = nil)
  if valid_614747 != nil:
    section.add "X-Amz-Credential", valid_614747
  var valid_614748 = header.getOrDefault("X-Amz-Security-Token")
  valid_614748 = validateParameter(valid_614748, JString, required = false,
                                 default = nil)
  if valid_614748 != nil:
    section.add "X-Amz-Security-Token", valid_614748
  var valid_614749 = header.getOrDefault("X-Amz-Algorithm")
  valid_614749 = validateParameter(valid_614749, JString, required = false,
                                 default = nil)
  if valid_614749 != nil:
    section.add "X-Amz-Algorithm", valid_614749
  var valid_614750 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614750 = validateParameter(valid_614750, JString, required = false,
                                 default = nil)
  if valid_614750 != nil:
    section.add "X-Amz-SignedHeaders", valid_614750
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
  var valid_614751 = formData.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_614751 = validateParameter(valid_614751, JString, required = false,
                                 default = nil)
  if valid_614751 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_614751
  var valid_614752 = formData.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_614752 = validateParameter(valid_614752, JString, required = false,
                                 default = nil)
  if valid_614752 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_614752
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_614753 = formData.getOrDefault("ApplicationName")
  valid_614753 = validateParameter(valid_614753, JString, required = true,
                                 default = nil)
  if valid_614753 != nil:
    section.add "ApplicationName", valid_614753
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614754: Call_PostUpdateApplicationResourceLifecycle_614739;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Modifies lifecycle settings for an application.
  ## 
  let valid = call_614754.validator(path, query, header, formData, body)
  let scheme = call_614754.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614754.url(scheme.get, call_614754.host, call_614754.base,
                         call_614754.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614754, url, valid)

proc call*(call_614755: Call_PostUpdateApplicationResourceLifecycle_614739;
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
  var query_614756 = newJObject()
  var formData_614757 = newJObject()
  add(formData_614757, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  add(formData_614757, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  add(formData_614757, "ApplicationName", newJString(ApplicationName))
  add(query_614756, "Action", newJString(Action))
  add(query_614756, "Version", newJString(Version))
  result = call_614755.call(nil, query_614756, nil, formData_614757, nil)

var postUpdateApplicationResourceLifecycle* = Call_PostUpdateApplicationResourceLifecycle_614739(
    name: "postUpdateApplicationResourceLifecycle", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationResourceLifecycle",
    validator: validate_PostUpdateApplicationResourceLifecycle_614740, base: "/",
    url: url_PostUpdateApplicationResourceLifecycle_614741,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateApplicationResourceLifecycle_614721 = ref object of OpenApiRestCall_612659
proc url_GetUpdateApplicationResourceLifecycle_614723(protocol: Scheme;
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

proc validate_GetUpdateApplicationResourceLifecycle_614722(path: JsonNode;
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
  var valid_614724 = query.getOrDefault("ApplicationName")
  valid_614724 = validateParameter(valid_614724, JString, required = true,
                                 default = nil)
  if valid_614724 != nil:
    section.add "ApplicationName", valid_614724
  var valid_614725 = query.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_614725 = validateParameter(valid_614725, JString, required = false,
                                 default = nil)
  if valid_614725 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_614725
  var valid_614726 = query.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_614726 = validateParameter(valid_614726, JString, required = false,
                                 default = nil)
  if valid_614726 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_614726
  var valid_614727 = query.getOrDefault("Action")
  valid_614727 = validateParameter(valid_614727, JString, required = true, default = newJString(
      "UpdateApplicationResourceLifecycle"))
  if valid_614727 != nil:
    section.add "Action", valid_614727
  var valid_614728 = query.getOrDefault("Version")
  valid_614728 = validateParameter(valid_614728, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614728 != nil:
    section.add "Version", valid_614728
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
  var valid_614729 = header.getOrDefault("X-Amz-Signature")
  valid_614729 = validateParameter(valid_614729, JString, required = false,
                                 default = nil)
  if valid_614729 != nil:
    section.add "X-Amz-Signature", valid_614729
  var valid_614730 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614730 = validateParameter(valid_614730, JString, required = false,
                                 default = nil)
  if valid_614730 != nil:
    section.add "X-Amz-Content-Sha256", valid_614730
  var valid_614731 = header.getOrDefault("X-Amz-Date")
  valid_614731 = validateParameter(valid_614731, JString, required = false,
                                 default = nil)
  if valid_614731 != nil:
    section.add "X-Amz-Date", valid_614731
  var valid_614732 = header.getOrDefault("X-Amz-Credential")
  valid_614732 = validateParameter(valid_614732, JString, required = false,
                                 default = nil)
  if valid_614732 != nil:
    section.add "X-Amz-Credential", valid_614732
  var valid_614733 = header.getOrDefault("X-Amz-Security-Token")
  valid_614733 = validateParameter(valid_614733, JString, required = false,
                                 default = nil)
  if valid_614733 != nil:
    section.add "X-Amz-Security-Token", valid_614733
  var valid_614734 = header.getOrDefault("X-Amz-Algorithm")
  valid_614734 = validateParameter(valid_614734, JString, required = false,
                                 default = nil)
  if valid_614734 != nil:
    section.add "X-Amz-Algorithm", valid_614734
  var valid_614735 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614735 = validateParameter(valid_614735, JString, required = false,
                                 default = nil)
  if valid_614735 != nil:
    section.add "X-Amz-SignedHeaders", valid_614735
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614736: Call_GetUpdateApplicationResourceLifecycle_614721;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Modifies lifecycle settings for an application.
  ## 
  let valid = call_614736.validator(path, query, header, formData, body)
  let scheme = call_614736.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614736.url(scheme.get, call_614736.host, call_614736.base,
                         call_614736.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614736, url, valid)

proc call*(call_614737: Call_GetUpdateApplicationResourceLifecycle_614721;
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
  var query_614738 = newJObject()
  add(query_614738, "ApplicationName", newJString(ApplicationName))
  add(query_614738, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  add(query_614738, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  add(query_614738, "Action", newJString(Action))
  add(query_614738, "Version", newJString(Version))
  result = call_614737.call(nil, query_614738, nil, nil, nil)

var getUpdateApplicationResourceLifecycle* = Call_GetUpdateApplicationResourceLifecycle_614721(
    name: "getUpdateApplicationResourceLifecycle", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationResourceLifecycle",
    validator: validate_GetUpdateApplicationResourceLifecycle_614722, base: "/",
    url: url_GetUpdateApplicationResourceLifecycle_614723,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateApplicationVersion_614776 = ref object of OpenApiRestCall_612659
proc url_PostUpdateApplicationVersion_614778(protocol: Scheme; host: string;
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

proc validate_PostUpdateApplicationVersion_614777(path: JsonNode; query: JsonNode;
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
  var valid_614779 = query.getOrDefault("Action")
  valid_614779 = validateParameter(valid_614779, JString, required = true, default = newJString(
      "UpdateApplicationVersion"))
  if valid_614779 != nil:
    section.add "Action", valid_614779
  var valid_614780 = query.getOrDefault("Version")
  valid_614780 = validateParameter(valid_614780, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614780 != nil:
    section.add "Version", valid_614780
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
  var valid_614781 = header.getOrDefault("X-Amz-Signature")
  valid_614781 = validateParameter(valid_614781, JString, required = false,
                                 default = nil)
  if valid_614781 != nil:
    section.add "X-Amz-Signature", valid_614781
  var valid_614782 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614782 = validateParameter(valid_614782, JString, required = false,
                                 default = nil)
  if valid_614782 != nil:
    section.add "X-Amz-Content-Sha256", valid_614782
  var valid_614783 = header.getOrDefault("X-Amz-Date")
  valid_614783 = validateParameter(valid_614783, JString, required = false,
                                 default = nil)
  if valid_614783 != nil:
    section.add "X-Amz-Date", valid_614783
  var valid_614784 = header.getOrDefault("X-Amz-Credential")
  valid_614784 = validateParameter(valid_614784, JString, required = false,
                                 default = nil)
  if valid_614784 != nil:
    section.add "X-Amz-Credential", valid_614784
  var valid_614785 = header.getOrDefault("X-Amz-Security-Token")
  valid_614785 = validateParameter(valid_614785, JString, required = false,
                                 default = nil)
  if valid_614785 != nil:
    section.add "X-Amz-Security-Token", valid_614785
  var valid_614786 = header.getOrDefault("X-Amz-Algorithm")
  valid_614786 = validateParameter(valid_614786, JString, required = false,
                                 default = nil)
  if valid_614786 != nil:
    section.add "X-Amz-Algorithm", valid_614786
  var valid_614787 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614787 = validateParameter(valid_614787, JString, required = false,
                                 default = nil)
  if valid_614787 != nil:
    section.add "X-Amz-SignedHeaders", valid_614787
  result.add "header", section
  ## parameters in `formData` object:
  ##   Description: JString
  ##              : A new description for this version.
  ##   VersionLabel: JString (required)
  ##               : <p>The name of the version to update.</p> <p>If no application version is found with this label, <code>UpdateApplication</code> returns an <code>InvalidParameterValue</code> error. </p>
  ##   ApplicationName: JString (required)
  ##                  : <p>The name of the application associated with this version.</p> <p> If no application is found with this name, <code>UpdateApplication</code> returns an <code>InvalidParameterValue</code> error.</p>
  section = newJObject()
  var valid_614788 = formData.getOrDefault("Description")
  valid_614788 = validateParameter(valid_614788, JString, required = false,
                                 default = nil)
  if valid_614788 != nil:
    section.add "Description", valid_614788
  assert formData != nil,
        "formData argument is necessary due to required `VersionLabel` field"
  var valid_614789 = formData.getOrDefault("VersionLabel")
  valid_614789 = validateParameter(valid_614789, JString, required = true,
                                 default = nil)
  if valid_614789 != nil:
    section.add "VersionLabel", valid_614789
  var valid_614790 = formData.getOrDefault("ApplicationName")
  valid_614790 = validateParameter(valid_614790, JString, required = true,
                                 default = nil)
  if valid_614790 != nil:
    section.add "ApplicationName", valid_614790
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614791: Call_PostUpdateApplicationVersion_614776; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified application version to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear properties, specify an empty string.</p> </note>
  ## 
  let valid = call_614791.validator(path, query, header, formData, body)
  let scheme = call_614791.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614791.url(scheme.get, call_614791.host, call_614791.base,
                         call_614791.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614791, url, valid)

proc call*(call_614792: Call_PostUpdateApplicationVersion_614776;
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
  var query_614793 = newJObject()
  var formData_614794 = newJObject()
  add(formData_614794, "Description", newJString(Description))
  add(formData_614794, "VersionLabel", newJString(VersionLabel))
  add(formData_614794, "ApplicationName", newJString(ApplicationName))
  add(query_614793, "Action", newJString(Action))
  add(query_614793, "Version", newJString(Version))
  result = call_614792.call(nil, query_614793, nil, formData_614794, nil)

var postUpdateApplicationVersion* = Call_PostUpdateApplicationVersion_614776(
    name: "postUpdateApplicationVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationVersion",
    validator: validate_PostUpdateApplicationVersion_614777, base: "/",
    url: url_PostUpdateApplicationVersion_614778,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateApplicationVersion_614758 = ref object of OpenApiRestCall_612659
proc url_GetUpdateApplicationVersion_614760(protocol: Scheme; host: string;
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

proc validate_GetUpdateApplicationVersion_614759(path: JsonNode; query: JsonNode;
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
  var valid_614761 = query.getOrDefault("ApplicationName")
  valid_614761 = validateParameter(valid_614761, JString, required = true,
                                 default = nil)
  if valid_614761 != nil:
    section.add "ApplicationName", valid_614761
  var valid_614762 = query.getOrDefault("VersionLabel")
  valid_614762 = validateParameter(valid_614762, JString, required = true,
                                 default = nil)
  if valid_614762 != nil:
    section.add "VersionLabel", valid_614762
  var valid_614763 = query.getOrDefault("Action")
  valid_614763 = validateParameter(valid_614763, JString, required = true, default = newJString(
      "UpdateApplicationVersion"))
  if valid_614763 != nil:
    section.add "Action", valid_614763
  var valid_614764 = query.getOrDefault("Description")
  valid_614764 = validateParameter(valid_614764, JString, required = false,
                                 default = nil)
  if valid_614764 != nil:
    section.add "Description", valid_614764
  var valid_614765 = query.getOrDefault("Version")
  valid_614765 = validateParameter(valid_614765, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614765 != nil:
    section.add "Version", valid_614765
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
  var valid_614766 = header.getOrDefault("X-Amz-Signature")
  valid_614766 = validateParameter(valid_614766, JString, required = false,
                                 default = nil)
  if valid_614766 != nil:
    section.add "X-Amz-Signature", valid_614766
  var valid_614767 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614767 = validateParameter(valid_614767, JString, required = false,
                                 default = nil)
  if valid_614767 != nil:
    section.add "X-Amz-Content-Sha256", valid_614767
  var valid_614768 = header.getOrDefault("X-Amz-Date")
  valid_614768 = validateParameter(valid_614768, JString, required = false,
                                 default = nil)
  if valid_614768 != nil:
    section.add "X-Amz-Date", valid_614768
  var valid_614769 = header.getOrDefault("X-Amz-Credential")
  valid_614769 = validateParameter(valid_614769, JString, required = false,
                                 default = nil)
  if valid_614769 != nil:
    section.add "X-Amz-Credential", valid_614769
  var valid_614770 = header.getOrDefault("X-Amz-Security-Token")
  valid_614770 = validateParameter(valid_614770, JString, required = false,
                                 default = nil)
  if valid_614770 != nil:
    section.add "X-Amz-Security-Token", valid_614770
  var valid_614771 = header.getOrDefault("X-Amz-Algorithm")
  valid_614771 = validateParameter(valid_614771, JString, required = false,
                                 default = nil)
  if valid_614771 != nil:
    section.add "X-Amz-Algorithm", valid_614771
  var valid_614772 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614772 = validateParameter(valid_614772, JString, required = false,
                                 default = nil)
  if valid_614772 != nil:
    section.add "X-Amz-SignedHeaders", valid_614772
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614773: Call_GetUpdateApplicationVersion_614758; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified application version to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear properties, specify an empty string.</p> </note>
  ## 
  let valid = call_614773.validator(path, query, header, formData, body)
  let scheme = call_614773.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614773.url(scheme.get, call_614773.host, call_614773.base,
                         call_614773.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614773, url, valid)

proc call*(call_614774: Call_GetUpdateApplicationVersion_614758;
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
  var query_614775 = newJObject()
  add(query_614775, "ApplicationName", newJString(ApplicationName))
  add(query_614775, "VersionLabel", newJString(VersionLabel))
  add(query_614775, "Action", newJString(Action))
  add(query_614775, "Description", newJString(Description))
  add(query_614775, "Version", newJString(Version))
  result = call_614774.call(nil, query_614775, nil, nil, nil)

var getUpdateApplicationVersion* = Call_GetUpdateApplicationVersion_614758(
    name: "getUpdateApplicationVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationVersion",
    validator: validate_GetUpdateApplicationVersion_614759, base: "/",
    url: url_GetUpdateApplicationVersion_614760,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateConfigurationTemplate_614815 = ref object of OpenApiRestCall_612659
proc url_PostUpdateConfigurationTemplate_614817(protocol: Scheme; host: string;
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

proc validate_PostUpdateConfigurationTemplate_614816(path: JsonNode;
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
  var valid_614818 = query.getOrDefault("Action")
  valid_614818 = validateParameter(valid_614818, JString, required = true, default = newJString(
      "UpdateConfigurationTemplate"))
  if valid_614818 != nil:
    section.add "Action", valid_614818
  var valid_614819 = query.getOrDefault("Version")
  valid_614819 = validateParameter(valid_614819, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614819 != nil:
    section.add "Version", valid_614819
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
  var valid_614820 = header.getOrDefault("X-Amz-Signature")
  valid_614820 = validateParameter(valid_614820, JString, required = false,
                                 default = nil)
  if valid_614820 != nil:
    section.add "X-Amz-Signature", valid_614820
  var valid_614821 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614821 = validateParameter(valid_614821, JString, required = false,
                                 default = nil)
  if valid_614821 != nil:
    section.add "X-Amz-Content-Sha256", valid_614821
  var valid_614822 = header.getOrDefault("X-Amz-Date")
  valid_614822 = validateParameter(valid_614822, JString, required = false,
                                 default = nil)
  if valid_614822 != nil:
    section.add "X-Amz-Date", valid_614822
  var valid_614823 = header.getOrDefault("X-Amz-Credential")
  valid_614823 = validateParameter(valid_614823, JString, required = false,
                                 default = nil)
  if valid_614823 != nil:
    section.add "X-Amz-Credential", valid_614823
  var valid_614824 = header.getOrDefault("X-Amz-Security-Token")
  valid_614824 = validateParameter(valid_614824, JString, required = false,
                                 default = nil)
  if valid_614824 != nil:
    section.add "X-Amz-Security-Token", valid_614824
  var valid_614825 = header.getOrDefault("X-Amz-Algorithm")
  valid_614825 = validateParameter(valid_614825, JString, required = false,
                                 default = nil)
  if valid_614825 != nil:
    section.add "X-Amz-Algorithm", valid_614825
  var valid_614826 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614826 = validateParameter(valid_614826, JString, required = false,
                                 default = nil)
  if valid_614826 != nil:
    section.add "X-Amz-SignedHeaders", valid_614826
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
  var valid_614827 = formData.getOrDefault("Description")
  valid_614827 = validateParameter(valid_614827, JString, required = false,
                                 default = nil)
  if valid_614827 != nil:
    section.add "Description", valid_614827
  assert formData != nil,
        "formData argument is necessary due to required `TemplateName` field"
  var valid_614828 = formData.getOrDefault("TemplateName")
  valid_614828 = validateParameter(valid_614828, JString, required = true,
                                 default = nil)
  if valid_614828 != nil:
    section.add "TemplateName", valid_614828
  var valid_614829 = formData.getOrDefault("OptionsToRemove")
  valid_614829 = validateParameter(valid_614829, JArray, required = false,
                                 default = nil)
  if valid_614829 != nil:
    section.add "OptionsToRemove", valid_614829
  var valid_614830 = formData.getOrDefault("OptionSettings")
  valid_614830 = validateParameter(valid_614830, JArray, required = false,
                                 default = nil)
  if valid_614830 != nil:
    section.add "OptionSettings", valid_614830
  var valid_614831 = formData.getOrDefault("ApplicationName")
  valid_614831 = validateParameter(valid_614831, JString, required = true,
                                 default = nil)
  if valid_614831 != nil:
    section.add "ApplicationName", valid_614831
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614832: Call_PostUpdateConfigurationTemplate_614815;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Updates the specified configuration template to have the specified properties or configuration option values.</p> <note> <p>If a property (for example, <code>ApplicationName</code>) is not provided, its value remains unchanged. To clear such properties, specify an empty string.</p> </note> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> </ul>
  ## 
  let valid = call_614832.validator(path, query, header, formData, body)
  let scheme = call_614832.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614832.url(scheme.get, call_614832.host, call_614832.base,
                         call_614832.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614832, url, valid)

proc call*(call_614833: Call_PostUpdateConfigurationTemplate_614815;
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
  var query_614834 = newJObject()
  var formData_614835 = newJObject()
  add(formData_614835, "Description", newJString(Description))
  add(formData_614835, "TemplateName", newJString(TemplateName))
  if OptionsToRemove != nil:
    formData_614835.add "OptionsToRemove", OptionsToRemove
  if OptionSettings != nil:
    formData_614835.add "OptionSettings", OptionSettings
  add(formData_614835, "ApplicationName", newJString(ApplicationName))
  add(query_614834, "Action", newJString(Action))
  add(query_614834, "Version", newJString(Version))
  result = call_614833.call(nil, query_614834, nil, formData_614835, nil)

var postUpdateConfigurationTemplate* = Call_PostUpdateConfigurationTemplate_614815(
    name: "postUpdateConfigurationTemplate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateConfigurationTemplate",
    validator: validate_PostUpdateConfigurationTemplate_614816, base: "/",
    url: url_PostUpdateConfigurationTemplate_614817,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateConfigurationTemplate_614795 = ref object of OpenApiRestCall_612659
proc url_GetUpdateConfigurationTemplate_614797(protocol: Scheme; host: string;
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

proc validate_GetUpdateConfigurationTemplate_614796(path: JsonNode;
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
  var valid_614798 = query.getOrDefault("ApplicationName")
  valid_614798 = validateParameter(valid_614798, JString, required = true,
                                 default = nil)
  if valid_614798 != nil:
    section.add "ApplicationName", valid_614798
  var valid_614799 = query.getOrDefault("OptionSettings")
  valid_614799 = validateParameter(valid_614799, JArray, required = false,
                                 default = nil)
  if valid_614799 != nil:
    section.add "OptionSettings", valid_614799
  var valid_614800 = query.getOrDefault("Action")
  valid_614800 = validateParameter(valid_614800, JString, required = true, default = newJString(
      "UpdateConfigurationTemplate"))
  if valid_614800 != nil:
    section.add "Action", valid_614800
  var valid_614801 = query.getOrDefault("Description")
  valid_614801 = validateParameter(valid_614801, JString, required = false,
                                 default = nil)
  if valid_614801 != nil:
    section.add "Description", valid_614801
  var valid_614802 = query.getOrDefault("OptionsToRemove")
  valid_614802 = validateParameter(valid_614802, JArray, required = false,
                                 default = nil)
  if valid_614802 != nil:
    section.add "OptionsToRemove", valid_614802
  var valid_614803 = query.getOrDefault("Version")
  valid_614803 = validateParameter(valid_614803, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614803 != nil:
    section.add "Version", valid_614803
  var valid_614804 = query.getOrDefault("TemplateName")
  valid_614804 = validateParameter(valid_614804, JString, required = true,
                                 default = nil)
  if valid_614804 != nil:
    section.add "TemplateName", valid_614804
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
  var valid_614805 = header.getOrDefault("X-Amz-Signature")
  valid_614805 = validateParameter(valid_614805, JString, required = false,
                                 default = nil)
  if valid_614805 != nil:
    section.add "X-Amz-Signature", valid_614805
  var valid_614806 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614806 = validateParameter(valid_614806, JString, required = false,
                                 default = nil)
  if valid_614806 != nil:
    section.add "X-Amz-Content-Sha256", valid_614806
  var valid_614807 = header.getOrDefault("X-Amz-Date")
  valid_614807 = validateParameter(valid_614807, JString, required = false,
                                 default = nil)
  if valid_614807 != nil:
    section.add "X-Amz-Date", valid_614807
  var valid_614808 = header.getOrDefault("X-Amz-Credential")
  valid_614808 = validateParameter(valid_614808, JString, required = false,
                                 default = nil)
  if valid_614808 != nil:
    section.add "X-Amz-Credential", valid_614808
  var valid_614809 = header.getOrDefault("X-Amz-Security-Token")
  valid_614809 = validateParameter(valid_614809, JString, required = false,
                                 default = nil)
  if valid_614809 != nil:
    section.add "X-Amz-Security-Token", valid_614809
  var valid_614810 = header.getOrDefault("X-Amz-Algorithm")
  valid_614810 = validateParameter(valid_614810, JString, required = false,
                                 default = nil)
  if valid_614810 != nil:
    section.add "X-Amz-Algorithm", valid_614810
  var valid_614811 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614811 = validateParameter(valid_614811, JString, required = false,
                                 default = nil)
  if valid_614811 != nil:
    section.add "X-Amz-SignedHeaders", valid_614811
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614812: Call_GetUpdateConfigurationTemplate_614795; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified configuration template to have the specified properties or configuration option values.</p> <note> <p>If a property (for example, <code>ApplicationName</code>) is not provided, its value remains unchanged. To clear such properties, specify an empty string.</p> </note> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> </ul>
  ## 
  let valid = call_614812.validator(path, query, header, formData, body)
  let scheme = call_614812.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614812.url(scheme.get, call_614812.host, call_614812.base,
                         call_614812.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614812, url, valid)

proc call*(call_614813: Call_GetUpdateConfigurationTemplate_614795;
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
  var query_614814 = newJObject()
  add(query_614814, "ApplicationName", newJString(ApplicationName))
  if OptionSettings != nil:
    query_614814.add "OptionSettings", OptionSettings
  add(query_614814, "Action", newJString(Action))
  add(query_614814, "Description", newJString(Description))
  if OptionsToRemove != nil:
    query_614814.add "OptionsToRemove", OptionsToRemove
  add(query_614814, "Version", newJString(Version))
  add(query_614814, "TemplateName", newJString(TemplateName))
  result = call_614813.call(nil, query_614814, nil, nil, nil)

var getUpdateConfigurationTemplate* = Call_GetUpdateConfigurationTemplate_614795(
    name: "getUpdateConfigurationTemplate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateConfigurationTemplate",
    validator: validate_GetUpdateConfigurationTemplate_614796, base: "/",
    url: url_GetUpdateConfigurationTemplate_614797,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateEnvironment_614865 = ref object of OpenApiRestCall_612659
proc url_PostUpdateEnvironment_614867(protocol: Scheme; host: string; base: string;
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

proc validate_PostUpdateEnvironment_614866(path: JsonNode; query: JsonNode;
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
  var valid_614868 = query.getOrDefault("Action")
  valid_614868 = validateParameter(valid_614868, JString, required = true,
                                 default = newJString("UpdateEnvironment"))
  if valid_614868 != nil:
    section.add "Action", valid_614868
  var valid_614869 = query.getOrDefault("Version")
  valid_614869 = validateParameter(valid_614869, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614869 != nil:
    section.add "Version", valid_614869
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
  var valid_614870 = header.getOrDefault("X-Amz-Signature")
  valid_614870 = validateParameter(valid_614870, JString, required = false,
                                 default = nil)
  if valid_614870 != nil:
    section.add "X-Amz-Signature", valid_614870
  var valid_614871 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614871 = validateParameter(valid_614871, JString, required = false,
                                 default = nil)
  if valid_614871 != nil:
    section.add "X-Amz-Content-Sha256", valid_614871
  var valid_614872 = header.getOrDefault("X-Amz-Date")
  valid_614872 = validateParameter(valid_614872, JString, required = false,
                                 default = nil)
  if valid_614872 != nil:
    section.add "X-Amz-Date", valid_614872
  var valid_614873 = header.getOrDefault("X-Amz-Credential")
  valid_614873 = validateParameter(valid_614873, JString, required = false,
                                 default = nil)
  if valid_614873 != nil:
    section.add "X-Amz-Credential", valid_614873
  var valid_614874 = header.getOrDefault("X-Amz-Security-Token")
  valid_614874 = validateParameter(valid_614874, JString, required = false,
                                 default = nil)
  if valid_614874 != nil:
    section.add "X-Amz-Security-Token", valid_614874
  var valid_614875 = header.getOrDefault("X-Amz-Algorithm")
  valid_614875 = validateParameter(valid_614875, JString, required = false,
                                 default = nil)
  if valid_614875 != nil:
    section.add "X-Amz-Algorithm", valid_614875
  var valid_614876 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614876 = validateParameter(valid_614876, JString, required = false,
                                 default = nil)
  if valid_614876 != nil:
    section.add "X-Amz-SignedHeaders", valid_614876
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
  var valid_614877 = formData.getOrDefault("Description")
  valid_614877 = validateParameter(valid_614877, JString, required = false,
                                 default = nil)
  if valid_614877 != nil:
    section.add "Description", valid_614877
  var valid_614878 = formData.getOrDefault("Tier.Type")
  valid_614878 = validateParameter(valid_614878, JString, required = false,
                                 default = nil)
  if valid_614878 != nil:
    section.add "Tier.Type", valid_614878
  var valid_614879 = formData.getOrDefault("EnvironmentName")
  valid_614879 = validateParameter(valid_614879, JString, required = false,
                                 default = nil)
  if valid_614879 != nil:
    section.add "EnvironmentName", valid_614879
  var valid_614880 = formData.getOrDefault("VersionLabel")
  valid_614880 = validateParameter(valid_614880, JString, required = false,
                                 default = nil)
  if valid_614880 != nil:
    section.add "VersionLabel", valid_614880
  var valid_614881 = formData.getOrDefault("TemplateName")
  valid_614881 = validateParameter(valid_614881, JString, required = false,
                                 default = nil)
  if valid_614881 != nil:
    section.add "TemplateName", valid_614881
  var valid_614882 = formData.getOrDefault("OptionsToRemove")
  valid_614882 = validateParameter(valid_614882, JArray, required = false,
                                 default = nil)
  if valid_614882 != nil:
    section.add "OptionsToRemove", valid_614882
  var valid_614883 = formData.getOrDefault("OptionSettings")
  valid_614883 = validateParameter(valid_614883, JArray, required = false,
                                 default = nil)
  if valid_614883 != nil:
    section.add "OptionSettings", valid_614883
  var valid_614884 = formData.getOrDefault("GroupName")
  valid_614884 = validateParameter(valid_614884, JString, required = false,
                                 default = nil)
  if valid_614884 != nil:
    section.add "GroupName", valid_614884
  var valid_614885 = formData.getOrDefault("ApplicationName")
  valid_614885 = validateParameter(valid_614885, JString, required = false,
                                 default = nil)
  if valid_614885 != nil:
    section.add "ApplicationName", valid_614885
  var valid_614886 = formData.getOrDefault("Tier.Name")
  valid_614886 = validateParameter(valid_614886, JString, required = false,
                                 default = nil)
  if valid_614886 != nil:
    section.add "Tier.Name", valid_614886
  var valid_614887 = formData.getOrDefault("Tier.Version")
  valid_614887 = validateParameter(valid_614887, JString, required = false,
                                 default = nil)
  if valid_614887 != nil:
    section.add "Tier.Version", valid_614887
  var valid_614888 = formData.getOrDefault("EnvironmentId")
  valid_614888 = validateParameter(valid_614888, JString, required = false,
                                 default = nil)
  if valid_614888 != nil:
    section.add "EnvironmentId", valid_614888
  var valid_614889 = formData.getOrDefault("SolutionStackName")
  valid_614889 = validateParameter(valid_614889, JString, required = false,
                                 default = nil)
  if valid_614889 != nil:
    section.add "SolutionStackName", valid_614889
  var valid_614890 = formData.getOrDefault("PlatformArn")
  valid_614890 = validateParameter(valid_614890, JString, required = false,
                                 default = nil)
  if valid_614890 != nil:
    section.add "PlatformArn", valid_614890
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614891: Call_PostUpdateEnvironment_614865; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the environment description, deploys a new application version, updates the configuration settings to an entirely new configuration template, or updates select configuration option values in the running environment.</p> <p> Attempting to update both the release and configuration is not allowed and AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. </p> <p> When updating the configuration settings to a new template or individual settings, a draft configuration is created and <a>DescribeConfigurationSettings</a> for this environment returns two setting descriptions with different <code>DeploymentStatus</code> values. </p>
  ## 
  let valid = call_614891.validator(path, query, header, formData, body)
  let scheme = call_614891.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614891.url(scheme.get, call_614891.host, call_614891.base,
                         call_614891.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614891, url, valid)

proc call*(call_614892: Call_PostUpdateEnvironment_614865;
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
  var query_614893 = newJObject()
  var formData_614894 = newJObject()
  add(formData_614894, "Description", newJString(Description))
  add(formData_614894, "Tier.Type", newJString(TierType))
  add(formData_614894, "EnvironmentName", newJString(EnvironmentName))
  add(formData_614894, "VersionLabel", newJString(VersionLabel))
  add(formData_614894, "TemplateName", newJString(TemplateName))
  if OptionsToRemove != nil:
    formData_614894.add "OptionsToRemove", OptionsToRemove
  if OptionSettings != nil:
    formData_614894.add "OptionSettings", OptionSettings
  add(formData_614894, "GroupName", newJString(GroupName))
  add(formData_614894, "ApplicationName", newJString(ApplicationName))
  add(formData_614894, "Tier.Name", newJString(TierName))
  add(formData_614894, "Tier.Version", newJString(TierVersion))
  add(query_614893, "Action", newJString(Action))
  add(formData_614894, "EnvironmentId", newJString(EnvironmentId))
  add(formData_614894, "SolutionStackName", newJString(SolutionStackName))
  add(query_614893, "Version", newJString(Version))
  add(formData_614894, "PlatformArn", newJString(PlatformArn))
  result = call_614892.call(nil, query_614893, nil, formData_614894, nil)

var postUpdateEnvironment* = Call_PostUpdateEnvironment_614865(
    name: "postUpdateEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateEnvironment",
    validator: validate_PostUpdateEnvironment_614866, base: "/",
    url: url_PostUpdateEnvironment_614867, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateEnvironment_614836 = ref object of OpenApiRestCall_612659
proc url_GetUpdateEnvironment_614838(protocol: Scheme; host: string; base: string;
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

proc validate_GetUpdateEnvironment_614837(path: JsonNode; query: JsonNode;
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
  var valid_614839 = query.getOrDefault("ApplicationName")
  valid_614839 = validateParameter(valid_614839, JString, required = false,
                                 default = nil)
  if valid_614839 != nil:
    section.add "ApplicationName", valid_614839
  var valid_614840 = query.getOrDefault("GroupName")
  valid_614840 = validateParameter(valid_614840, JString, required = false,
                                 default = nil)
  if valid_614840 != nil:
    section.add "GroupName", valid_614840
  var valid_614841 = query.getOrDefault("VersionLabel")
  valid_614841 = validateParameter(valid_614841, JString, required = false,
                                 default = nil)
  if valid_614841 != nil:
    section.add "VersionLabel", valid_614841
  var valid_614842 = query.getOrDefault("OptionSettings")
  valid_614842 = validateParameter(valid_614842, JArray, required = false,
                                 default = nil)
  if valid_614842 != nil:
    section.add "OptionSettings", valid_614842
  var valid_614843 = query.getOrDefault("SolutionStackName")
  valid_614843 = validateParameter(valid_614843, JString, required = false,
                                 default = nil)
  if valid_614843 != nil:
    section.add "SolutionStackName", valid_614843
  var valid_614844 = query.getOrDefault("Tier.Name")
  valid_614844 = validateParameter(valid_614844, JString, required = false,
                                 default = nil)
  if valid_614844 != nil:
    section.add "Tier.Name", valid_614844
  var valid_614845 = query.getOrDefault("EnvironmentName")
  valid_614845 = validateParameter(valid_614845, JString, required = false,
                                 default = nil)
  if valid_614845 != nil:
    section.add "EnvironmentName", valid_614845
  var valid_614846 = query.getOrDefault("Action")
  valid_614846 = validateParameter(valid_614846, JString, required = true,
                                 default = newJString("UpdateEnvironment"))
  if valid_614846 != nil:
    section.add "Action", valid_614846
  var valid_614847 = query.getOrDefault("Description")
  valid_614847 = validateParameter(valid_614847, JString, required = false,
                                 default = nil)
  if valid_614847 != nil:
    section.add "Description", valid_614847
  var valid_614848 = query.getOrDefault("PlatformArn")
  valid_614848 = validateParameter(valid_614848, JString, required = false,
                                 default = nil)
  if valid_614848 != nil:
    section.add "PlatformArn", valid_614848
  var valid_614849 = query.getOrDefault("OptionsToRemove")
  valid_614849 = validateParameter(valid_614849, JArray, required = false,
                                 default = nil)
  if valid_614849 != nil:
    section.add "OptionsToRemove", valid_614849
  var valid_614850 = query.getOrDefault("Version")
  valid_614850 = validateParameter(valid_614850, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614850 != nil:
    section.add "Version", valid_614850
  var valid_614851 = query.getOrDefault("TemplateName")
  valid_614851 = validateParameter(valid_614851, JString, required = false,
                                 default = nil)
  if valid_614851 != nil:
    section.add "TemplateName", valid_614851
  var valid_614852 = query.getOrDefault("Tier.Version")
  valid_614852 = validateParameter(valid_614852, JString, required = false,
                                 default = nil)
  if valid_614852 != nil:
    section.add "Tier.Version", valid_614852
  var valid_614853 = query.getOrDefault("EnvironmentId")
  valid_614853 = validateParameter(valid_614853, JString, required = false,
                                 default = nil)
  if valid_614853 != nil:
    section.add "EnvironmentId", valid_614853
  var valid_614854 = query.getOrDefault("Tier.Type")
  valid_614854 = validateParameter(valid_614854, JString, required = false,
                                 default = nil)
  if valid_614854 != nil:
    section.add "Tier.Type", valid_614854
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
  var valid_614855 = header.getOrDefault("X-Amz-Signature")
  valid_614855 = validateParameter(valid_614855, JString, required = false,
                                 default = nil)
  if valid_614855 != nil:
    section.add "X-Amz-Signature", valid_614855
  var valid_614856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614856 = validateParameter(valid_614856, JString, required = false,
                                 default = nil)
  if valid_614856 != nil:
    section.add "X-Amz-Content-Sha256", valid_614856
  var valid_614857 = header.getOrDefault("X-Amz-Date")
  valid_614857 = validateParameter(valid_614857, JString, required = false,
                                 default = nil)
  if valid_614857 != nil:
    section.add "X-Amz-Date", valid_614857
  var valid_614858 = header.getOrDefault("X-Amz-Credential")
  valid_614858 = validateParameter(valid_614858, JString, required = false,
                                 default = nil)
  if valid_614858 != nil:
    section.add "X-Amz-Credential", valid_614858
  var valid_614859 = header.getOrDefault("X-Amz-Security-Token")
  valid_614859 = validateParameter(valid_614859, JString, required = false,
                                 default = nil)
  if valid_614859 != nil:
    section.add "X-Amz-Security-Token", valid_614859
  var valid_614860 = header.getOrDefault("X-Amz-Algorithm")
  valid_614860 = validateParameter(valid_614860, JString, required = false,
                                 default = nil)
  if valid_614860 != nil:
    section.add "X-Amz-Algorithm", valid_614860
  var valid_614861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614861 = validateParameter(valid_614861, JString, required = false,
                                 default = nil)
  if valid_614861 != nil:
    section.add "X-Amz-SignedHeaders", valid_614861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614862: Call_GetUpdateEnvironment_614836; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the environment description, deploys a new application version, updates the configuration settings to an entirely new configuration template, or updates select configuration option values in the running environment.</p> <p> Attempting to update both the release and configuration is not allowed and AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. </p> <p> When updating the configuration settings to a new template or individual settings, a draft configuration is created and <a>DescribeConfigurationSettings</a> for this environment returns two setting descriptions with different <code>DeploymentStatus</code> values. </p>
  ## 
  let valid = call_614862.validator(path, query, header, formData, body)
  let scheme = call_614862.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614862.url(scheme.get, call_614862.host, call_614862.base,
                         call_614862.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614862, url, valid)

proc call*(call_614863: Call_GetUpdateEnvironment_614836;
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
  var query_614864 = newJObject()
  add(query_614864, "ApplicationName", newJString(ApplicationName))
  add(query_614864, "GroupName", newJString(GroupName))
  add(query_614864, "VersionLabel", newJString(VersionLabel))
  if OptionSettings != nil:
    query_614864.add "OptionSettings", OptionSettings
  add(query_614864, "SolutionStackName", newJString(SolutionStackName))
  add(query_614864, "Tier.Name", newJString(TierName))
  add(query_614864, "EnvironmentName", newJString(EnvironmentName))
  add(query_614864, "Action", newJString(Action))
  add(query_614864, "Description", newJString(Description))
  add(query_614864, "PlatformArn", newJString(PlatformArn))
  if OptionsToRemove != nil:
    query_614864.add "OptionsToRemove", OptionsToRemove
  add(query_614864, "Version", newJString(Version))
  add(query_614864, "TemplateName", newJString(TemplateName))
  add(query_614864, "Tier.Version", newJString(TierVersion))
  add(query_614864, "EnvironmentId", newJString(EnvironmentId))
  add(query_614864, "Tier.Type", newJString(TierType))
  result = call_614863.call(nil, query_614864, nil, nil, nil)

var getUpdateEnvironment* = Call_GetUpdateEnvironment_614836(
    name: "getUpdateEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateEnvironment",
    validator: validate_GetUpdateEnvironment_614837, base: "/",
    url: url_GetUpdateEnvironment_614838, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateTagsForResource_614913 = ref object of OpenApiRestCall_612659
proc url_PostUpdateTagsForResource_614915(protocol: Scheme; host: string;
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

proc validate_PostUpdateTagsForResource_614914(path: JsonNode; query: JsonNode;
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
  var valid_614916 = query.getOrDefault("Action")
  valid_614916 = validateParameter(valid_614916, JString, required = true,
                                 default = newJString("UpdateTagsForResource"))
  if valid_614916 != nil:
    section.add "Action", valid_614916
  var valid_614917 = query.getOrDefault("Version")
  valid_614917 = validateParameter(valid_614917, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614917 != nil:
    section.add "Version", valid_614917
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
  var valid_614918 = header.getOrDefault("X-Amz-Signature")
  valid_614918 = validateParameter(valid_614918, JString, required = false,
                                 default = nil)
  if valid_614918 != nil:
    section.add "X-Amz-Signature", valid_614918
  var valid_614919 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614919 = validateParameter(valid_614919, JString, required = false,
                                 default = nil)
  if valid_614919 != nil:
    section.add "X-Amz-Content-Sha256", valid_614919
  var valid_614920 = header.getOrDefault("X-Amz-Date")
  valid_614920 = validateParameter(valid_614920, JString, required = false,
                                 default = nil)
  if valid_614920 != nil:
    section.add "X-Amz-Date", valid_614920
  var valid_614921 = header.getOrDefault("X-Amz-Credential")
  valid_614921 = validateParameter(valid_614921, JString, required = false,
                                 default = nil)
  if valid_614921 != nil:
    section.add "X-Amz-Credential", valid_614921
  var valid_614922 = header.getOrDefault("X-Amz-Security-Token")
  valid_614922 = validateParameter(valid_614922, JString, required = false,
                                 default = nil)
  if valid_614922 != nil:
    section.add "X-Amz-Security-Token", valid_614922
  var valid_614923 = header.getOrDefault("X-Amz-Algorithm")
  valid_614923 = validateParameter(valid_614923, JString, required = false,
                                 default = nil)
  if valid_614923 != nil:
    section.add "X-Amz-Algorithm", valid_614923
  var valid_614924 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614924 = validateParameter(valid_614924, JString, required = false,
                                 default = nil)
  if valid_614924 != nil:
    section.add "X-Amz-SignedHeaders", valid_614924
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
  var valid_614925 = formData.getOrDefault("ResourceArn")
  valid_614925 = validateParameter(valid_614925, JString, required = true,
                                 default = nil)
  if valid_614925 != nil:
    section.add "ResourceArn", valid_614925
  var valid_614926 = formData.getOrDefault("TagsToAdd")
  valid_614926 = validateParameter(valid_614926, JArray, required = false,
                                 default = nil)
  if valid_614926 != nil:
    section.add "TagsToAdd", valid_614926
  var valid_614927 = formData.getOrDefault("TagsToRemove")
  valid_614927 = validateParameter(valid_614927, JArray, required = false,
                                 default = nil)
  if valid_614927 != nil:
    section.add "TagsToRemove", valid_614927
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614928: Call_PostUpdateTagsForResource_614913; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Update the list of tags applied to an AWS Elastic Beanstalk resource. Two lists can be passed: <code>TagsToAdd</code> for tags to add or update, and <code>TagsToRemove</code>.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p> <p>If you create a custom IAM user policy to control permission to this operation, specify one of the following two virtual actions (or both) instead of the API operation name:</p> <dl> <dt>elasticbeanstalk:AddTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tags to add in the <code>TagsToAdd</code> parameter.</p> </dd> <dt>elasticbeanstalk:RemoveTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tag keys to remove in the <code>TagsToRemove</code> parameter.</p> </dd> </dl> <p>For details about creating a custom user policy, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/AWSHowTo.iam.managed-policies.html#AWSHowTo.iam.policies">Creating a Custom User Policy</a>.</p>
  ## 
  let valid = call_614928.validator(path, query, header, formData, body)
  let scheme = call_614928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614928.url(scheme.get, call_614928.host, call_614928.base,
                         call_614928.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614928, url, valid)

proc call*(call_614929: Call_PostUpdateTagsForResource_614913; ResourceArn: string;
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
  var query_614930 = newJObject()
  var formData_614931 = newJObject()
  add(formData_614931, "ResourceArn", newJString(ResourceArn))
  add(query_614930, "Action", newJString(Action))
  if TagsToAdd != nil:
    formData_614931.add "TagsToAdd", TagsToAdd
  if TagsToRemove != nil:
    formData_614931.add "TagsToRemove", TagsToRemove
  add(query_614930, "Version", newJString(Version))
  result = call_614929.call(nil, query_614930, nil, formData_614931, nil)

var postUpdateTagsForResource* = Call_PostUpdateTagsForResource_614913(
    name: "postUpdateTagsForResource", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateTagsForResource",
    validator: validate_PostUpdateTagsForResource_614914, base: "/",
    url: url_PostUpdateTagsForResource_614915,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateTagsForResource_614895 = ref object of OpenApiRestCall_612659
proc url_GetUpdateTagsForResource_614897(protocol: Scheme; host: string;
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

proc validate_GetUpdateTagsForResource_614896(path: JsonNode; query: JsonNode;
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
  var valid_614898 = query.getOrDefault("TagsToAdd")
  valid_614898 = validateParameter(valid_614898, JArray, required = false,
                                 default = nil)
  if valid_614898 != nil:
    section.add "TagsToAdd", valid_614898
  var valid_614899 = query.getOrDefault("TagsToRemove")
  valid_614899 = validateParameter(valid_614899, JArray, required = false,
                                 default = nil)
  if valid_614899 != nil:
    section.add "TagsToRemove", valid_614899
  assert query != nil,
        "query argument is necessary due to required `ResourceArn` field"
  var valid_614900 = query.getOrDefault("ResourceArn")
  valid_614900 = validateParameter(valid_614900, JString, required = true,
                                 default = nil)
  if valid_614900 != nil:
    section.add "ResourceArn", valid_614900
  var valid_614901 = query.getOrDefault("Action")
  valid_614901 = validateParameter(valid_614901, JString, required = true,
                                 default = newJString("UpdateTagsForResource"))
  if valid_614901 != nil:
    section.add "Action", valid_614901
  var valid_614902 = query.getOrDefault("Version")
  valid_614902 = validateParameter(valid_614902, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614902 != nil:
    section.add "Version", valid_614902
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
  var valid_614903 = header.getOrDefault("X-Amz-Signature")
  valid_614903 = validateParameter(valid_614903, JString, required = false,
                                 default = nil)
  if valid_614903 != nil:
    section.add "X-Amz-Signature", valid_614903
  var valid_614904 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614904 = validateParameter(valid_614904, JString, required = false,
                                 default = nil)
  if valid_614904 != nil:
    section.add "X-Amz-Content-Sha256", valid_614904
  var valid_614905 = header.getOrDefault("X-Amz-Date")
  valid_614905 = validateParameter(valid_614905, JString, required = false,
                                 default = nil)
  if valid_614905 != nil:
    section.add "X-Amz-Date", valid_614905
  var valid_614906 = header.getOrDefault("X-Amz-Credential")
  valid_614906 = validateParameter(valid_614906, JString, required = false,
                                 default = nil)
  if valid_614906 != nil:
    section.add "X-Amz-Credential", valid_614906
  var valid_614907 = header.getOrDefault("X-Amz-Security-Token")
  valid_614907 = validateParameter(valid_614907, JString, required = false,
                                 default = nil)
  if valid_614907 != nil:
    section.add "X-Amz-Security-Token", valid_614907
  var valid_614908 = header.getOrDefault("X-Amz-Algorithm")
  valid_614908 = validateParameter(valid_614908, JString, required = false,
                                 default = nil)
  if valid_614908 != nil:
    section.add "X-Amz-Algorithm", valid_614908
  var valid_614909 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614909 = validateParameter(valid_614909, JString, required = false,
                                 default = nil)
  if valid_614909 != nil:
    section.add "X-Amz-SignedHeaders", valid_614909
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614910: Call_GetUpdateTagsForResource_614895; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Update the list of tags applied to an AWS Elastic Beanstalk resource. Two lists can be passed: <code>TagsToAdd</code> for tags to add or update, and <code>TagsToRemove</code>.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p> <p>If you create a custom IAM user policy to control permission to this operation, specify one of the following two virtual actions (or both) instead of the API operation name:</p> <dl> <dt>elasticbeanstalk:AddTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tags to add in the <code>TagsToAdd</code> parameter.</p> </dd> <dt>elasticbeanstalk:RemoveTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tag keys to remove in the <code>TagsToRemove</code> parameter.</p> </dd> </dl> <p>For details about creating a custom user policy, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/AWSHowTo.iam.managed-policies.html#AWSHowTo.iam.policies">Creating a Custom User Policy</a>.</p>
  ## 
  let valid = call_614910.validator(path, query, header, formData, body)
  let scheme = call_614910.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614910.url(scheme.get, call_614910.host, call_614910.base,
                         call_614910.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614910, url, valid)

proc call*(call_614911: Call_GetUpdateTagsForResource_614895; ResourceArn: string;
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
  var query_614912 = newJObject()
  if TagsToAdd != nil:
    query_614912.add "TagsToAdd", TagsToAdd
  if TagsToRemove != nil:
    query_614912.add "TagsToRemove", TagsToRemove
  add(query_614912, "ResourceArn", newJString(ResourceArn))
  add(query_614912, "Action", newJString(Action))
  add(query_614912, "Version", newJString(Version))
  result = call_614911.call(nil, query_614912, nil, nil, nil)

var getUpdateTagsForResource* = Call_GetUpdateTagsForResource_614895(
    name: "getUpdateTagsForResource", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateTagsForResource",
    validator: validate_GetUpdateTagsForResource_614896, base: "/",
    url: url_GetUpdateTagsForResource_614897, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostValidateConfigurationSettings_614951 = ref object of OpenApiRestCall_612659
proc url_PostValidateConfigurationSettings_614953(protocol: Scheme; host: string;
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

proc validate_PostValidateConfigurationSettings_614952(path: JsonNode;
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
  var valid_614954 = query.getOrDefault("Action")
  valid_614954 = validateParameter(valid_614954, JString, required = true, default = newJString(
      "ValidateConfigurationSettings"))
  if valid_614954 != nil:
    section.add "Action", valid_614954
  var valid_614955 = query.getOrDefault("Version")
  valid_614955 = validateParameter(valid_614955, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614955 != nil:
    section.add "Version", valid_614955
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
  var valid_614956 = header.getOrDefault("X-Amz-Signature")
  valid_614956 = validateParameter(valid_614956, JString, required = false,
                                 default = nil)
  if valid_614956 != nil:
    section.add "X-Amz-Signature", valid_614956
  var valid_614957 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614957 = validateParameter(valid_614957, JString, required = false,
                                 default = nil)
  if valid_614957 != nil:
    section.add "X-Amz-Content-Sha256", valid_614957
  var valid_614958 = header.getOrDefault("X-Amz-Date")
  valid_614958 = validateParameter(valid_614958, JString, required = false,
                                 default = nil)
  if valid_614958 != nil:
    section.add "X-Amz-Date", valid_614958
  var valid_614959 = header.getOrDefault("X-Amz-Credential")
  valid_614959 = validateParameter(valid_614959, JString, required = false,
                                 default = nil)
  if valid_614959 != nil:
    section.add "X-Amz-Credential", valid_614959
  var valid_614960 = header.getOrDefault("X-Amz-Security-Token")
  valid_614960 = validateParameter(valid_614960, JString, required = false,
                                 default = nil)
  if valid_614960 != nil:
    section.add "X-Amz-Security-Token", valid_614960
  var valid_614961 = header.getOrDefault("X-Amz-Algorithm")
  valid_614961 = validateParameter(valid_614961, JString, required = false,
                                 default = nil)
  if valid_614961 != nil:
    section.add "X-Amz-Algorithm", valid_614961
  var valid_614962 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614962 = validateParameter(valid_614962, JString, required = false,
                                 default = nil)
  if valid_614962 != nil:
    section.add "X-Amz-SignedHeaders", valid_614962
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
  var valid_614963 = formData.getOrDefault("EnvironmentName")
  valid_614963 = validateParameter(valid_614963, JString, required = false,
                                 default = nil)
  if valid_614963 != nil:
    section.add "EnvironmentName", valid_614963
  var valid_614964 = formData.getOrDefault("TemplateName")
  valid_614964 = validateParameter(valid_614964, JString, required = false,
                                 default = nil)
  if valid_614964 != nil:
    section.add "TemplateName", valid_614964
  assert formData != nil,
        "formData argument is necessary due to required `OptionSettings` field"
  var valid_614965 = formData.getOrDefault("OptionSettings")
  valid_614965 = validateParameter(valid_614965, JArray, required = true, default = nil)
  if valid_614965 != nil:
    section.add "OptionSettings", valid_614965
  var valid_614966 = formData.getOrDefault("ApplicationName")
  valid_614966 = validateParameter(valid_614966, JString, required = true,
                                 default = nil)
  if valid_614966 != nil:
    section.add "ApplicationName", valid_614966
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614967: Call_PostValidateConfigurationSettings_614951;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Takes a set of configuration settings and either a configuration template or environment, and determines whether those values are valid.</p> <p>This action returns a list of messages indicating any errors or warnings associated with the selection of option values.</p>
  ## 
  let valid = call_614967.validator(path, query, header, formData, body)
  let scheme = call_614967.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614967.url(scheme.get, call_614967.host, call_614967.base,
                         call_614967.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614967, url, valid)

proc call*(call_614968: Call_PostValidateConfigurationSettings_614951;
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
  var query_614969 = newJObject()
  var formData_614970 = newJObject()
  add(formData_614970, "EnvironmentName", newJString(EnvironmentName))
  add(formData_614970, "TemplateName", newJString(TemplateName))
  if OptionSettings != nil:
    formData_614970.add "OptionSettings", OptionSettings
  add(formData_614970, "ApplicationName", newJString(ApplicationName))
  add(query_614969, "Action", newJString(Action))
  add(query_614969, "Version", newJString(Version))
  result = call_614968.call(nil, query_614969, nil, formData_614970, nil)

var postValidateConfigurationSettings* = Call_PostValidateConfigurationSettings_614951(
    name: "postValidateConfigurationSettings", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ValidateConfigurationSettings",
    validator: validate_PostValidateConfigurationSettings_614952, base: "/",
    url: url_PostValidateConfigurationSettings_614953,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetValidateConfigurationSettings_614932 = ref object of OpenApiRestCall_612659
proc url_GetValidateConfigurationSettings_614934(protocol: Scheme; host: string;
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

proc validate_GetValidateConfigurationSettings_614933(path: JsonNode;
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
  var valid_614935 = query.getOrDefault("ApplicationName")
  valid_614935 = validateParameter(valid_614935, JString, required = true,
                                 default = nil)
  if valid_614935 != nil:
    section.add "ApplicationName", valid_614935
  var valid_614936 = query.getOrDefault("OptionSettings")
  valid_614936 = validateParameter(valid_614936, JArray, required = true, default = nil)
  if valid_614936 != nil:
    section.add "OptionSettings", valid_614936
  var valid_614937 = query.getOrDefault("EnvironmentName")
  valid_614937 = validateParameter(valid_614937, JString, required = false,
                                 default = nil)
  if valid_614937 != nil:
    section.add "EnvironmentName", valid_614937
  var valid_614938 = query.getOrDefault("Action")
  valid_614938 = validateParameter(valid_614938, JString, required = true, default = newJString(
      "ValidateConfigurationSettings"))
  if valid_614938 != nil:
    section.add "Action", valid_614938
  var valid_614939 = query.getOrDefault("Version")
  valid_614939 = validateParameter(valid_614939, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_614939 != nil:
    section.add "Version", valid_614939
  var valid_614940 = query.getOrDefault("TemplateName")
  valid_614940 = validateParameter(valid_614940, JString, required = false,
                                 default = nil)
  if valid_614940 != nil:
    section.add "TemplateName", valid_614940
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
  var valid_614941 = header.getOrDefault("X-Amz-Signature")
  valid_614941 = validateParameter(valid_614941, JString, required = false,
                                 default = nil)
  if valid_614941 != nil:
    section.add "X-Amz-Signature", valid_614941
  var valid_614942 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614942 = validateParameter(valid_614942, JString, required = false,
                                 default = nil)
  if valid_614942 != nil:
    section.add "X-Amz-Content-Sha256", valid_614942
  var valid_614943 = header.getOrDefault("X-Amz-Date")
  valid_614943 = validateParameter(valid_614943, JString, required = false,
                                 default = nil)
  if valid_614943 != nil:
    section.add "X-Amz-Date", valid_614943
  var valid_614944 = header.getOrDefault("X-Amz-Credential")
  valid_614944 = validateParameter(valid_614944, JString, required = false,
                                 default = nil)
  if valid_614944 != nil:
    section.add "X-Amz-Credential", valid_614944
  var valid_614945 = header.getOrDefault("X-Amz-Security-Token")
  valid_614945 = validateParameter(valid_614945, JString, required = false,
                                 default = nil)
  if valid_614945 != nil:
    section.add "X-Amz-Security-Token", valid_614945
  var valid_614946 = header.getOrDefault("X-Amz-Algorithm")
  valid_614946 = validateParameter(valid_614946, JString, required = false,
                                 default = nil)
  if valid_614946 != nil:
    section.add "X-Amz-Algorithm", valid_614946
  var valid_614947 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614947 = validateParameter(valid_614947, JString, required = false,
                                 default = nil)
  if valid_614947 != nil:
    section.add "X-Amz-SignedHeaders", valid_614947
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614948: Call_GetValidateConfigurationSettings_614932;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Takes a set of configuration settings and either a configuration template or environment, and determines whether those values are valid.</p> <p>This action returns a list of messages indicating any errors or warnings associated with the selection of option values.</p>
  ## 
  let valid = call_614948.validator(path, query, header, formData, body)
  let scheme = call_614948.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614948.url(scheme.get, call_614948.host, call_614948.base,
                         call_614948.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614948, url, valid)

proc call*(call_614949: Call_GetValidateConfigurationSettings_614932;
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
  var query_614950 = newJObject()
  add(query_614950, "ApplicationName", newJString(ApplicationName))
  if OptionSettings != nil:
    query_614950.add "OptionSettings", OptionSettings
  add(query_614950, "EnvironmentName", newJString(EnvironmentName))
  add(query_614950, "Action", newJString(Action))
  add(query_614950, "Version", newJString(Version))
  add(query_614950, "TemplateName", newJString(TemplateName))
  result = call_614949.call(nil, query_614950, nil, nil, nil)

var getValidateConfigurationSettings* = Call_GetValidateConfigurationSettings_614932(
    name: "getValidateConfigurationSettings", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ValidateConfigurationSettings",
    validator: validate_GetValidateConfigurationSettings_614933, base: "/",
    url: url_GetValidateConfigurationSettings_614934,
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

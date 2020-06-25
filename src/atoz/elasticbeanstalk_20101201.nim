
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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

  OpenApiRestCall_21625437 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625437](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625437): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_PostAbortEnvironmentUpdate_21626038 = ref object of OpenApiRestCall_21625437
proc url_PostAbortEnvironmentUpdate_21626040(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostAbortEnvironmentUpdate_21626039(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626041 = query.getOrDefault("Action")
  valid_21626041 = validateParameter(valid_21626041, JString, required = true, default = newJString(
      "AbortEnvironmentUpdate"))
  if valid_21626041 != nil:
    section.add "Action", valid_21626041
  var valid_21626042 = query.getOrDefault("Version")
  valid_21626042 = validateParameter(valid_21626042, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626042 != nil:
    section.add "Version", valid_21626042
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626043 = header.getOrDefault("X-Amz-Date")
  valid_21626043 = validateParameter(valid_21626043, JString, required = false,
                                   default = nil)
  if valid_21626043 != nil:
    section.add "X-Amz-Date", valid_21626043
  var valid_21626044 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626044 = validateParameter(valid_21626044, JString, required = false,
                                   default = nil)
  if valid_21626044 != nil:
    section.add "X-Amz-Security-Token", valid_21626044
  var valid_21626045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626045 = validateParameter(valid_21626045, JString, required = false,
                                   default = nil)
  if valid_21626045 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626045
  var valid_21626046 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626046 = validateParameter(valid_21626046, JString, required = false,
                                   default = nil)
  if valid_21626046 != nil:
    section.add "X-Amz-Algorithm", valid_21626046
  var valid_21626047 = header.getOrDefault("X-Amz-Signature")
  valid_21626047 = validateParameter(valid_21626047, JString, required = false,
                                   default = nil)
  if valid_21626047 != nil:
    section.add "X-Amz-Signature", valid_21626047
  var valid_21626048 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626048 = validateParameter(valid_21626048, JString, required = false,
                                   default = nil)
  if valid_21626048 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626048
  var valid_21626049 = header.getOrDefault("X-Amz-Credential")
  valid_21626049 = validateParameter(valid_21626049, JString, required = false,
                                   default = nil)
  if valid_21626049 != nil:
    section.add "X-Amz-Credential", valid_21626049
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentId: JString
  ##                : This specifies the ID of the environment with the in-progress update that you want to cancel.
  ##   EnvironmentName: JString
  ##                  : This specifies the name of the environment with the in-progress update that you want to cancel.
  section = newJObject()
  var valid_21626050 = formData.getOrDefault("EnvironmentId")
  valid_21626050 = validateParameter(valid_21626050, JString, required = false,
                                   default = nil)
  if valid_21626050 != nil:
    section.add "EnvironmentId", valid_21626050
  var valid_21626051 = formData.getOrDefault("EnvironmentName")
  valid_21626051 = validateParameter(valid_21626051, JString, required = false,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "EnvironmentName", valid_21626051
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626052: Call_PostAbortEnvironmentUpdate_21626038;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Cancels in-progress environment configuration update or application version deployment.
  ## 
  let valid = call_21626052.validator(path, query, header, formData, body, _)
  let scheme = call_21626052.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626052.makeUrl(scheme.get, call_21626052.host, call_21626052.base,
                               call_21626052.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626052, uri, valid, _)

proc call*(call_21626053: Call_PostAbortEnvironmentUpdate_21626038;
          EnvironmentId: string = ""; EnvironmentName: string = "";
          Action: string = "AbortEnvironmentUpdate"; Version: string = "2010-12-01"): Recallable =
  ## postAbortEnvironmentUpdate
  ## Cancels in-progress environment configuration update or application version deployment.
  ##   EnvironmentId: string
  ##                : This specifies the ID of the environment with the in-progress update that you want to cancel.
  ##   EnvironmentName: string
  ##                  : This specifies the name of the environment with the in-progress update that you want to cancel.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626054 = newJObject()
  var formData_21626055 = newJObject()
  add(formData_21626055, "EnvironmentId", newJString(EnvironmentId))
  add(formData_21626055, "EnvironmentName", newJString(EnvironmentName))
  add(query_21626054, "Action", newJString(Action))
  add(query_21626054, "Version", newJString(Version))
  result = call_21626053.call(nil, query_21626054, nil, formData_21626055, nil)

var postAbortEnvironmentUpdate* = Call_PostAbortEnvironmentUpdate_21626038(
    name: "postAbortEnvironmentUpdate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=AbortEnvironmentUpdate",
    validator: validate_PostAbortEnvironmentUpdate_21626039, base: "/",
    makeUrl: url_PostAbortEnvironmentUpdate_21626040,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAbortEnvironmentUpdate_21625781 = ref object of OpenApiRestCall_21625437
proc url_GetAbortEnvironmentUpdate_21625783(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAbortEnvironmentUpdate_21625782(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   EnvironmentId: JString
  ##                : This specifies the ID of the environment with the in-progress update that you want to cancel.
  ##   Version: JString (required)
  section = newJObject()
  var valid_21625884 = query.getOrDefault("EnvironmentName")
  valid_21625884 = validateParameter(valid_21625884, JString, required = false,
                                   default = nil)
  if valid_21625884 != nil:
    section.add "EnvironmentName", valid_21625884
  var valid_21625899 = query.getOrDefault("Action")
  valid_21625899 = validateParameter(valid_21625899, JString, required = true, default = newJString(
      "AbortEnvironmentUpdate"))
  if valid_21625899 != nil:
    section.add "Action", valid_21625899
  var valid_21625900 = query.getOrDefault("EnvironmentId")
  valid_21625900 = validateParameter(valid_21625900, JString, required = false,
                                   default = nil)
  if valid_21625900 != nil:
    section.add "EnvironmentId", valid_21625900
  var valid_21625901 = query.getOrDefault("Version")
  valid_21625901 = validateParameter(valid_21625901, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21625901 != nil:
    section.add "Version", valid_21625901
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21625902 = header.getOrDefault("X-Amz-Date")
  valid_21625902 = validateParameter(valid_21625902, JString, required = false,
                                   default = nil)
  if valid_21625902 != nil:
    section.add "X-Amz-Date", valid_21625902
  var valid_21625903 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625903 = validateParameter(valid_21625903, JString, required = false,
                                   default = nil)
  if valid_21625903 != nil:
    section.add "X-Amz-Security-Token", valid_21625903
  var valid_21625904 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625904 = validateParameter(valid_21625904, JString, required = false,
                                   default = nil)
  if valid_21625904 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625904
  var valid_21625905 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625905 = validateParameter(valid_21625905, JString, required = false,
                                   default = nil)
  if valid_21625905 != nil:
    section.add "X-Amz-Algorithm", valid_21625905
  var valid_21625906 = header.getOrDefault("X-Amz-Signature")
  valid_21625906 = validateParameter(valid_21625906, JString, required = false,
                                   default = nil)
  if valid_21625906 != nil:
    section.add "X-Amz-Signature", valid_21625906
  var valid_21625907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625907 = validateParameter(valid_21625907, JString, required = false,
                                   default = nil)
  if valid_21625907 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625907
  var valid_21625908 = header.getOrDefault("X-Amz-Credential")
  valid_21625908 = validateParameter(valid_21625908, JString, required = false,
                                   default = nil)
  if valid_21625908 != nil:
    section.add "X-Amz-Credential", valid_21625908
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21625933: Call_GetAbortEnvironmentUpdate_21625781;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Cancels in-progress environment configuration update or application version deployment.
  ## 
  let valid = call_21625933.validator(path, query, header, formData, body, _)
  let scheme = call_21625933.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625933.makeUrl(scheme.get, call_21625933.host, call_21625933.base,
                               call_21625933.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625933, uri, valid, _)

proc call*(call_21625996: Call_GetAbortEnvironmentUpdate_21625781;
          EnvironmentName: string = ""; Action: string = "AbortEnvironmentUpdate";
          EnvironmentId: string = ""; Version: string = "2010-12-01"): Recallable =
  ## getAbortEnvironmentUpdate
  ## Cancels in-progress environment configuration update or application version deployment.
  ##   EnvironmentName: string
  ##                  : This specifies the name of the environment with the in-progress update that you want to cancel.
  ##   Action: string (required)
  ##   EnvironmentId: string
  ##                : This specifies the ID of the environment with the in-progress update that you want to cancel.
  ##   Version: string (required)
  var query_21625998 = newJObject()
  add(query_21625998, "EnvironmentName", newJString(EnvironmentName))
  add(query_21625998, "Action", newJString(Action))
  add(query_21625998, "EnvironmentId", newJString(EnvironmentId))
  add(query_21625998, "Version", newJString(Version))
  result = call_21625996.call(nil, query_21625998, nil, nil, nil)

var getAbortEnvironmentUpdate* = Call_GetAbortEnvironmentUpdate_21625781(
    name: "getAbortEnvironmentUpdate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=AbortEnvironmentUpdate",
    validator: validate_GetAbortEnvironmentUpdate_21625782, base: "/",
    makeUrl: url_GetAbortEnvironmentUpdate_21625783,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostApplyEnvironmentManagedAction_21626074 = ref object of OpenApiRestCall_21625437
proc url_PostApplyEnvironmentManagedAction_21626076(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostApplyEnvironmentManagedAction_21626075(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626077 = query.getOrDefault("Action")
  valid_21626077 = validateParameter(valid_21626077, JString, required = true, default = newJString(
      "ApplyEnvironmentManagedAction"))
  if valid_21626077 != nil:
    section.add "Action", valid_21626077
  var valid_21626078 = query.getOrDefault("Version")
  valid_21626078 = validateParameter(valid_21626078, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626078 != nil:
    section.add "Version", valid_21626078
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626079 = header.getOrDefault("X-Amz-Date")
  valid_21626079 = validateParameter(valid_21626079, JString, required = false,
                                   default = nil)
  if valid_21626079 != nil:
    section.add "X-Amz-Date", valid_21626079
  var valid_21626080 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626080 = validateParameter(valid_21626080, JString, required = false,
                                   default = nil)
  if valid_21626080 != nil:
    section.add "X-Amz-Security-Token", valid_21626080
  var valid_21626081 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626081 = validateParameter(valid_21626081, JString, required = false,
                                   default = nil)
  if valid_21626081 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626081
  var valid_21626082 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626082 = validateParameter(valid_21626082, JString, required = false,
                                   default = nil)
  if valid_21626082 != nil:
    section.add "X-Amz-Algorithm", valid_21626082
  var valid_21626083 = header.getOrDefault("X-Amz-Signature")
  valid_21626083 = validateParameter(valid_21626083, JString, required = false,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "X-Amz-Signature", valid_21626083
  var valid_21626084 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626084 = validateParameter(valid_21626084, JString, required = false,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626084
  var valid_21626085 = header.getOrDefault("X-Amz-Credential")
  valid_21626085 = validateParameter(valid_21626085, JString, required = false,
                                   default = nil)
  if valid_21626085 != nil:
    section.add "X-Amz-Credential", valid_21626085
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentId: JString
  ##                : The environment ID of the target environment.
  ##   EnvironmentName: JString
  ##                  : The name of the target environment.
  ##   ActionId: JString (required)
  ##           : The action ID of the scheduled managed action to execute.
  section = newJObject()
  var valid_21626086 = formData.getOrDefault("EnvironmentId")
  valid_21626086 = validateParameter(valid_21626086, JString, required = false,
                                   default = nil)
  if valid_21626086 != nil:
    section.add "EnvironmentId", valid_21626086
  var valid_21626087 = formData.getOrDefault("EnvironmentName")
  valid_21626087 = validateParameter(valid_21626087, JString, required = false,
                                   default = nil)
  if valid_21626087 != nil:
    section.add "EnvironmentName", valid_21626087
  assert formData != nil,
        "formData argument is necessary due to required `ActionId` field"
  var valid_21626088 = formData.getOrDefault("ActionId")
  valid_21626088 = validateParameter(valid_21626088, JString, required = true,
                                   default = nil)
  if valid_21626088 != nil:
    section.add "ActionId", valid_21626088
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626089: Call_PostApplyEnvironmentManagedAction_21626074;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Applies a scheduled managed action immediately. A managed action can be applied only if its status is <code>Scheduled</code>. Get the status and action ID of a managed action with <a>DescribeEnvironmentManagedActions</a>.
  ## 
  let valid = call_21626089.validator(path, query, header, formData, body, _)
  let scheme = call_21626089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626089.makeUrl(scheme.get, call_21626089.host, call_21626089.base,
                               call_21626089.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626089, uri, valid, _)

proc call*(call_21626090: Call_PostApplyEnvironmentManagedAction_21626074;
          ActionId: string; EnvironmentId: string = ""; EnvironmentName: string = "";
          Action: string = "ApplyEnvironmentManagedAction";
          Version: string = "2010-12-01"): Recallable =
  ## postApplyEnvironmentManagedAction
  ## Applies a scheduled managed action immediately. A managed action can be applied only if its status is <code>Scheduled</code>. Get the status and action ID of a managed action with <a>DescribeEnvironmentManagedActions</a>.
  ##   EnvironmentId: string
  ##                : The environment ID of the target environment.
  ##   EnvironmentName: string
  ##                  : The name of the target environment.
  ##   Action: string (required)
  ##   ActionId: string (required)
  ##           : The action ID of the scheduled managed action to execute.
  ##   Version: string (required)
  var query_21626091 = newJObject()
  var formData_21626092 = newJObject()
  add(formData_21626092, "EnvironmentId", newJString(EnvironmentId))
  add(formData_21626092, "EnvironmentName", newJString(EnvironmentName))
  add(query_21626091, "Action", newJString(Action))
  add(formData_21626092, "ActionId", newJString(ActionId))
  add(query_21626091, "Version", newJString(Version))
  result = call_21626090.call(nil, query_21626091, nil, formData_21626092, nil)

var postApplyEnvironmentManagedAction* = Call_PostApplyEnvironmentManagedAction_21626074(
    name: "postApplyEnvironmentManagedAction", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ApplyEnvironmentManagedAction",
    validator: validate_PostApplyEnvironmentManagedAction_21626075, base: "/",
    makeUrl: url_PostApplyEnvironmentManagedAction_21626076,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplyEnvironmentManagedAction_21626056 = ref object of OpenApiRestCall_21625437
proc url_GetApplyEnvironmentManagedAction_21626058(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetApplyEnvironmentManagedAction_21626057(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Applies a scheduled managed action immediately. A managed action can be applied only if its status is <code>Scheduled</code>. Get the status and action ID of a managed action with <a>DescribeEnvironmentManagedActions</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   EnvironmentName: JString
  ##                  : The name of the target environment.
  ##   Action: JString (required)
  ##   EnvironmentId: JString
  ##                : The environment ID of the target environment.
  ##   ActionId: JString (required)
  ##           : The action ID of the scheduled managed action to execute.
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626059 = query.getOrDefault("EnvironmentName")
  valid_21626059 = validateParameter(valid_21626059, JString, required = false,
                                   default = nil)
  if valid_21626059 != nil:
    section.add "EnvironmentName", valid_21626059
  var valid_21626060 = query.getOrDefault("Action")
  valid_21626060 = validateParameter(valid_21626060, JString, required = true, default = newJString(
      "ApplyEnvironmentManagedAction"))
  if valid_21626060 != nil:
    section.add "Action", valid_21626060
  var valid_21626061 = query.getOrDefault("EnvironmentId")
  valid_21626061 = validateParameter(valid_21626061, JString, required = false,
                                   default = nil)
  if valid_21626061 != nil:
    section.add "EnvironmentId", valid_21626061
  var valid_21626062 = query.getOrDefault("ActionId")
  valid_21626062 = validateParameter(valid_21626062, JString, required = true,
                                   default = nil)
  if valid_21626062 != nil:
    section.add "ActionId", valid_21626062
  var valid_21626063 = query.getOrDefault("Version")
  valid_21626063 = validateParameter(valid_21626063, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626063 != nil:
    section.add "Version", valid_21626063
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626064 = header.getOrDefault("X-Amz-Date")
  valid_21626064 = validateParameter(valid_21626064, JString, required = false,
                                   default = nil)
  if valid_21626064 != nil:
    section.add "X-Amz-Date", valid_21626064
  var valid_21626065 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626065 = validateParameter(valid_21626065, JString, required = false,
                                   default = nil)
  if valid_21626065 != nil:
    section.add "X-Amz-Security-Token", valid_21626065
  var valid_21626066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626066 = validateParameter(valid_21626066, JString, required = false,
                                   default = nil)
  if valid_21626066 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626066
  var valid_21626067 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626067 = validateParameter(valid_21626067, JString, required = false,
                                   default = nil)
  if valid_21626067 != nil:
    section.add "X-Amz-Algorithm", valid_21626067
  var valid_21626068 = header.getOrDefault("X-Amz-Signature")
  valid_21626068 = validateParameter(valid_21626068, JString, required = false,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "X-Amz-Signature", valid_21626068
  var valid_21626069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626069 = validateParameter(valid_21626069, JString, required = false,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626069
  var valid_21626070 = header.getOrDefault("X-Amz-Credential")
  valid_21626070 = validateParameter(valid_21626070, JString, required = false,
                                   default = nil)
  if valid_21626070 != nil:
    section.add "X-Amz-Credential", valid_21626070
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626071: Call_GetApplyEnvironmentManagedAction_21626056;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Applies a scheduled managed action immediately. A managed action can be applied only if its status is <code>Scheduled</code>. Get the status and action ID of a managed action with <a>DescribeEnvironmentManagedActions</a>.
  ## 
  let valid = call_21626071.validator(path, query, header, formData, body, _)
  let scheme = call_21626071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626071.makeUrl(scheme.get, call_21626071.host, call_21626071.base,
                               call_21626071.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626071, uri, valid, _)

proc call*(call_21626072: Call_GetApplyEnvironmentManagedAction_21626056;
          ActionId: string; EnvironmentName: string = "";
          Action: string = "ApplyEnvironmentManagedAction";
          EnvironmentId: string = ""; Version: string = "2010-12-01"): Recallable =
  ## getApplyEnvironmentManagedAction
  ## Applies a scheduled managed action immediately. A managed action can be applied only if its status is <code>Scheduled</code>. Get the status and action ID of a managed action with <a>DescribeEnvironmentManagedActions</a>.
  ##   EnvironmentName: string
  ##                  : The name of the target environment.
  ##   Action: string (required)
  ##   EnvironmentId: string
  ##                : The environment ID of the target environment.
  ##   ActionId: string (required)
  ##           : The action ID of the scheduled managed action to execute.
  ##   Version: string (required)
  var query_21626073 = newJObject()
  add(query_21626073, "EnvironmentName", newJString(EnvironmentName))
  add(query_21626073, "Action", newJString(Action))
  add(query_21626073, "EnvironmentId", newJString(EnvironmentId))
  add(query_21626073, "ActionId", newJString(ActionId))
  add(query_21626073, "Version", newJString(Version))
  result = call_21626072.call(nil, query_21626073, nil, nil, nil)

var getApplyEnvironmentManagedAction* = Call_GetApplyEnvironmentManagedAction_21626056(
    name: "getApplyEnvironmentManagedAction", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ApplyEnvironmentManagedAction",
    validator: validate_GetApplyEnvironmentManagedAction_21626057, base: "/",
    makeUrl: url_GetApplyEnvironmentManagedAction_21626058,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCheckDNSAvailability_21626109 = ref object of OpenApiRestCall_21625437
proc url_PostCheckDNSAvailability_21626111(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCheckDNSAvailability_21626110(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626112 = query.getOrDefault("Action")
  valid_21626112 = validateParameter(valid_21626112, JString, required = true,
                                   default = newJString("CheckDNSAvailability"))
  if valid_21626112 != nil:
    section.add "Action", valid_21626112
  var valid_21626113 = query.getOrDefault("Version")
  valid_21626113 = validateParameter(valid_21626113, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626113 != nil:
    section.add "Version", valid_21626113
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626114 = header.getOrDefault("X-Amz-Date")
  valid_21626114 = validateParameter(valid_21626114, JString, required = false,
                                   default = nil)
  if valid_21626114 != nil:
    section.add "X-Amz-Date", valid_21626114
  var valid_21626115 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626115 = validateParameter(valid_21626115, JString, required = false,
                                   default = nil)
  if valid_21626115 != nil:
    section.add "X-Amz-Security-Token", valid_21626115
  var valid_21626116 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626116 = validateParameter(valid_21626116, JString, required = false,
                                   default = nil)
  if valid_21626116 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626116
  var valid_21626117 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626117 = validateParameter(valid_21626117, JString, required = false,
                                   default = nil)
  if valid_21626117 != nil:
    section.add "X-Amz-Algorithm", valid_21626117
  var valid_21626118 = header.getOrDefault("X-Amz-Signature")
  valid_21626118 = validateParameter(valid_21626118, JString, required = false,
                                   default = nil)
  if valid_21626118 != nil:
    section.add "X-Amz-Signature", valid_21626118
  var valid_21626119 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626119 = validateParameter(valid_21626119, JString, required = false,
                                   default = nil)
  if valid_21626119 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626119
  var valid_21626120 = header.getOrDefault("X-Amz-Credential")
  valid_21626120 = validateParameter(valid_21626120, JString, required = false,
                                   default = nil)
  if valid_21626120 != nil:
    section.add "X-Amz-Credential", valid_21626120
  result.add "header", section
  ## parameters in `formData` object:
  ##   CNAMEPrefix: JString (required)
  ##              : The prefix used when this CNAME is reserved.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `CNAMEPrefix` field"
  var valid_21626121 = formData.getOrDefault("CNAMEPrefix")
  valid_21626121 = validateParameter(valid_21626121, JString, required = true,
                                   default = nil)
  if valid_21626121 != nil:
    section.add "CNAMEPrefix", valid_21626121
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626122: Call_PostCheckDNSAvailability_21626109;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Checks if the specified CNAME is available.
  ## 
  let valid = call_21626122.validator(path, query, header, formData, body, _)
  let scheme = call_21626122.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626122.makeUrl(scheme.get, call_21626122.host, call_21626122.base,
                               call_21626122.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626122, uri, valid, _)

proc call*(call_21626123: Call_PostCheckDNSAvailability_21626109;
          CNAMEPrefix: string; Action: string = "CheckDNSAvailability";
          Version: string = "2010-12-01"): Recallable =
  ## postCheckDNSAvailability
  ## Checks if the specified CNAME is available.
  ##   CNAMEPrefix: string (required)
  ##              : The prefix used when this CNAME is reserved.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626124 = newJObject()
  var formData_21626125 = newJObject()
  add(formData_21626125, "CNAMEPrefix", newJString(CNAMEPrefix))
  add(query_21626124, "Action", newJString(Action))
  add(query_21626124, "Version", newJString(Version))
  result = call_21626123.call(nil, query_21626124, nil, formData_21626125, nil)

var postCheckDNSAvailability* = Call_PostCheckDNSAvailability_21626109(
    name: "postCheckDNSAvailability", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CheckDNSAvailability",
    validator: validate_PostCheckDNSAvailability_21626110, base: "/",
    makeUrl: url_PostCheckDNSAvailability_21626111,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCheckDNSAvailability_21626093 = ref object of OpenApiRestCall_21625437
proc url_GetCheckDNSAvailability_21626095(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCheckDNSAvailability_21626094(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Checks if the specified CNAME is available.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   CNAMEPrefix: JString (required)
  ##              : The prefix used when this CNAME is reserved.
  section = newJObject()
  var valid_21626096 = query.getOrDefault("Action")
  valid_21626096 = validateParameter(valid_21626096, JString, required = true,
                                   default = newJString("CheckDNSAvailability"))
  if valid_21626096 != nil:
    section.add "Action", valid_21626096
  var valid_21626097 = query.getOrDefault("Version")
  valid_21626097 = validateParameter(valid_21626097, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626097 != nil:
    section.add "Version", valid_21626097
  var valid_21626098 = query.getOrDefault("CNAMEPrefix")
  valid_21626098 = validateParameter(valid_21626098, JString, required = true,
                                   default = nil)
  if valid_21626098 != nil:
    section.add "CNAMEPrefix", valid_21626098
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626099 = header.getOrDefault("X-Amz-Date")
  valid_21626099 = validateParameter(valid_21626099, JString, required = false,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "X-Amz-Date", valid_21626099
  var valid_21626100 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626100 = validateParameter(valid_21626100, JString, required = false,
                                   default = nil)
  if valid_21626100 != nil:
    section.add "X-Amz-Security-Token", valid_21626100
  var valid_21626101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626101 = validateParameter(valid_21626101, JString, required = false,
                                   default = nil)
  if valid_21626101 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626101
  var valid_21626102 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626102 = validateParameter(valid_21626102, JString, required = false,
                                   default = nil)
  if valid_21626102 != nil:
    section.add "X-Amz-Algorithm", valid_21626102
  var valid_21626103 = header.getOrDefault("X-Amz-Signature")
  valid_21626103 = validateParameter(valid_21626103, JString, required = false,
                                   default = nil)
  if valid_21626103 != nil:
    section.add "X-Amz-Signature", valid_21626103
  var valid_21626104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626104 = validateParameter(valid_21626104, JString, required = false,
                                   default = nil)
  if valid_21626104 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626104
  var valid_21626105 = header.getOrDefault("X-Amz-Credential")
  valid_21626105 = validateParameter(valid_21626105, JString, required = false,
                                   default = nil)
  if valid_21626105 != nil:
    section.add "X-Amz-Credential", valid_21626105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626106: Call_GetCheckDNSAvailability_21626093;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Checks if the specified CNAME is available.
  ## 
  let valid = call_21626106.validator(path, query, header, formData, body, _)
  let scheme = call_21626106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626106.makeUrl(scheme.get, call_21626106.host, call_21626106.base,
                               call_21626106.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626106, uri, valid, _)

proc call*(call_21626107: Call_GetCheckDNSAvailability_21626093;
          CNAMEPrefix: string; Action: string = "CheckDNSAvailability";
          Version: string = "2010-12-01"): Recallable =
  ## getCheckDNSAvailability
  ## Checks if the specified CNAME is available.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   CNAMEPrefix: string (required)
  ##              : The prefix used when this CNAME is reserved.
  var query_21626108 = newJObject()
  add(query_21626108, "Action", newJString(Action))
  add(query_21626108, "Version", newJString(Version))
  add(query_21626108, "CNAMEPrefix", newJString(CNAMEPrefix))
  result = call_21626107.call(nil, query_21626108, nil, nil, nil)

var getCheckDNSAvailability* = Call_GetCheckDNSAvailability_21626093(
    name: "getCheckDNSAvailability", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CheckDNSAvailability",
    validator: validate_GetCheckDNSAvailability_21626094, base: "/",
    makeUrl: url_GetCheckDNSAvailability_21626095,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostComposeEnvironments_21626144 = ref object of OpenApiRestCall_21625437
proc url_PostComposeEnvironments_21626146(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostComposeEnvironments_21626145(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626147 = query.getOrDefault("Action")
  valid_21626147 = validateParameter(valid_21626147, JString, required = true,
                                   default = newJString("ComposeEnvironments"))
  if valid_21626147 != nil:
    section.add "Action", valid_21626147
  var valid_21626148 = query.getOrDefault("Version")
  valid_21626148 = validateParameter(valid_21626148, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626148 != nil:
    section.add "Version", valid_21626148
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626149 = header.getOrDefault("X-Amz-Date")
  valid_21626149 = validateParameter(valid_21626149, JString, required = false,
                                   default = nil)
  if valid_21626149 != nil:
    section.add "X-Amz-Date", valid_21626149
  var valid_21626150 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626150 = validateParameter(valid_21626150, JString, required = false,
                                   default = nil)
  if valid_21626150 != nil:
    section.add "X-Amz-Security-Token", valid_21626150
  var valid_21626151 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626151 = validateParameter(valid_21626151, JString, required = false,
                                   default = nil)
  if valid_21626151 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626151
  var valid_21626152 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626152 = validateParameter(valid_21626152, JString, required = false,
                                   default = nil)
  if valid_21626152 != nil:
    section.add "X-Amz-Algorithm", valid_21626152
  var valid_21626153 = header.getOrDefault("X-Amz-Signature")
  valid_21626153 = validateParameter(valid_21626153, JString, required = false,
                                   default = nil)
  if valid_21626153 != nil:
    section.add "X-Amz-Signature", valid_21626153
  var valid_21626154 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626154 = validateParameter(valid_21626154, JString, required = false,
                                   default = nil)
  if valid_21626154 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626154
  var valid_21626155 = header.getOrDefault("X-Amz-Credential")
  valid_21626155 = validateParameter(valid_21626155, JString, required = false,
                                   default = nil)
  if valid_21626155 != nil:
    section.add "X-Amz-Credential", valid_21626155
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
  var valid_21626156 = formData.getOrDefault("GroupName")
  valid_21626156 = validateParameter(valid_21626156, JString, required = false,
                                   default = nil)
  if valid_21626156 != nil:
    section.add "GroupName", valid_21626156
  var valid_21626157 = formData.getOrDefault("ApplicationName")
  valid_21626157 = validateParameter(valid_21626157, JString, required = false,
                                   default = nil)
  if valid_21626157 != nil:
    section.add "ApplicationName", valid_21626157
  var valid_21626158 = formData.getOrDefault("VersionLabels")
  valid_21626158 = validateParameter(valid_21626158, JArray, required = false,
                                   default = nil)
  if valid_21626158 != nil:
    section.add "VersionLabels", valid_21626158
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626159: Call_PostComposeEnvironments_21626144;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Create or update a group of environments that each run a separate component of a single application. Takes a list of version labels that specify application source bundles for each of the environments to create or update. The name of each environment and other required information must be included in the source bundles in an environment manifest named <code>env.yaml</code>. See <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-mgmt-compose.html">Compose Environments</a> for details.
  ## 
  let valid = call_21626159.validator(path, query, header, formData, body, _)
  let scheme = call_21626159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626159.makeUrl(scheme.get, call_21626159.host, call_21626159.base,
                               call_21626159.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626159, uri, valid, _)

proc call*(call_21626160: Call_PostComposeEnvironments_21626144;
          GroupName: string = ""; Action: string = "ComposeEnvironments";
          ApplicationName: string = ""; Version: string = "2010-12-01";
          VersionLabels: JsonNode = nil): Recallable =
  ## postComposeEnvironments
  ## Create or update a group of environments that each run a separate component of a single application. Takes a list of version labels that specify application source bundles for each of the environments to create or update. The name of each environment and other required information must be included in the source bundles in an environment manifest named <code>env.yaml</code>. See <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-mgmt-compose.html">Compose Environments</a> for details.
  ##   GroupName: string
  ##            : The name of the group to which the target environments belong. Specify a group name only if the environment name defined in each target environment's manifest ends with a + (plus) character. See <a 
  ## href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-cfg-manifest.html">Environment Manifest (env.yaml)</a> for details.
  ##   Action: string (required)
  ##   ApplicationName: string
  ##                  : The name of the application to which the specified source bundles belong.
  ##   Version: string (required)
  ##   VersionLabels: JArray
  ##                : A list of version labels, specifying one or more application source bundles that belong to the target application. Each source bundle must include an environment manifest that specifies the name of the environment and the name of the solution stack to use, and optionally can specify environment links to create.
  var query_21626161 = newJObject()
  var formData_21626162 = newJObject()
  add(formData_21626162, "GroupName", newJString(GroupName))
  add(query_21626161, "Action", newJString(Action))
  add(formData_21626162, "ApplicationName", newJString(ApplicationName))
  add(query_21626161, "Version", newJString(Version))
  if VersionLabels != nil:
    formData_21626162.add "VersionLabels", VersionLabels
  result = call_21626160.call(nil, query_21626161, nil, formData_21626162, nil)

var postComposeEnvironments* = Call_PostComposeEnvironments_21626144(
    name: "postComposeEnvironments", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ComposeEnvironments",
    validator: validate_PostComposeEnvironments_21626145, base: "/",
    makeUrl: url_PostComposeEnvironments_21626146,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetComposeEnvironments_21626126 = ref object of OpenApiRestCall_21625437
proc url_GetComposeEnvironments_21626128(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetComposeEnvironments_21626127(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Create or update a group of environments that each run a separate component of a single application. Takes a list of version labels that specify application source bundles for each of the environments to create or update. The name of each environment and other required information must be included in the source bundles in an environment manifest named <code>env.yaml</code>. See <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-mgmt-compose.html">Compose Environments</a> for details.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ApplicationName: JString
  ##                  : The name of the application to which the specified source bundles belong.
  ##   Action: JString (required)
  ##   GroupName: JString
  ##            : The name of the group to which the target environments belong. Specify a group name only if the environment name defined in each target environment's manifest ends with a + (plus) character. See <a 
  ## href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-cfg-manifest.html">Environment Manifest (env.yaml)</a> for details.
  ##   VersionLabels: JArray
  ##                : A list of version labels, specifying one or more application source bundles that belong to the target application. Each source bundle must include an environment manifest that specifies the name of the environment and the name of the solution stack to use, and optionally can specify environment links to create.
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626129 = query.getOrDefault("ApplicationName")
  valid_21626129 = validateParameter(valid_21626129, JString, required = false,
                                   default = nil)
  if valid_21626129 != nil:
    section.add "ApplicationName", valid_21626129
  var valid_21626130 = query.getOrDefault("Action")
  valid_21626130 = validateParameter(valid_21626130, JString, required = true,
                                   default = newJString("ComposeEnvironments"))
  if valid_21626130 != nil:
    section.add "Action", valid_21626130
  var valid_21626131 = query.getOrDefault("GroupName")
  valid_21626131 = validateParameter(valid_21626131, JString, required = false,
                                   default = nil)
  if valid_21626131 != nil:
    section.add "GroupName", valid_21626131
  var valid_21626132 = query.getOrDefault("VersionLabels")
  valid_21626132 = validateParameter(valid_21626132, JArray, required = false,
                                   default = nil)
  if valid_21626132 != nil:
    section.add "VersionLabels", valid_21626132
  var valid_21626133 = query.getOrDefault("Version")
  valid_21626133 = validateParameter(valid_21626133, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626133 != nil:
    section.add "Version", valid_21626133
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626134 = header.getOrDefault("X-Amz-Date")
  valid_21626134 = validateParameter(valid_21626134, JString, required = false,
                                   default = nil)
  if valid_21626134 != nil:
    section.add "X-Amz-Date", valid_21626134
  var valid_21626135 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626135 = validateParameter(valid_21626135, JString, required = false,
                                   default = nil)
  if valid_21626135 != nil:
    section.add "X-Amz-Security-Token", valid_21626135
  var valid_21626136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626136 = validateParameter(valid_21626136, JString, required = false,
                                   default = nil)
  if valid_21626136 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626136
  var valid_21626137 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626137 = validateParameter(valid_21626137, JString, required = false,
                                   default = nil)
  if valid_21626137 != nil:
    section.add "X-Amz-Algorithm", valid_21626137
  var valid_21626138 = header.getOrDefault("X-Amz-Signature")
  valid_21626138 = validateParameter(valid_21626138, JString, required = false,
                                   default = nil)
  if valid_21626138 != nil:
    section.add "X-Amz-Signature", valid_21626138
  var valid_21626139 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626139 = validateParameter(valid_21626139, JString, required = false,
                                   default = nil)
  if valid_21626139 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626139
  var valid_21626140 = header.getOrDefault("X-Amz-Credential")
  valid_21626140 = validateParameter(valid_21626140, JString, required = false,
                                   default = nil)
  if valid_21626140 != nil:
    section.add "X-Amz-Credential", valid_21626140
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626141: Call_GetComposeEnvironments_21626126;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Create or update a group of environments that each run a separate component of a single application. Takes a list of version labels that specify application source bundles for each of the environments to create or update. The name of each environment and other required information must be included in the source bundles in an environment manifest named <code>env.yaml</code>. See <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-mgmt-compose.html">Compose Environments</a> for details.
  ## 
  let valid = call_21626141.validator(path, query, header, formData, body, _)
  let scheme = call_21626141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626141.makeUrl(scheme.get, call_21626141.host, call_21626141.base,
                               call_21626141.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626141, uri, valid, _)

proc call*(call_21626142: Call_GetComposeEnvironments_21626126;
          ApplicationName: string = ""; Action: string = "ComposeEnvironments";
          GroupName: string = ""; VersionLabels: JsonNode = nil;
          Version: string = "2010-12-01"): Recallable =
  ## getComposeEnvironments
  ## Create or update a group of environments that each run a separate component of a single application. Takes a list of version labels that specify application source bundles for each of the environments to create or update. The name of each environment and other required information must be included in the source bundles in an environment manifest named <code>env.yaml</code>. See <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-mgmt-compose.html">Compose Environments</a> for details.
  ##   ApplicationName: string
  ##                  : The name of the application to which the specified source bundles belong.
  ##   Action: string (required)
  ##   GroupName: string
  ##            : The name of the group to which the target environments belong. Specify a group name only if the environment name defined in each target environment's manifest ends with a + (plus) character. See <a 
  ## href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-cfg-manifest.html">Environment Manifest (env.yaml)</a> for details.
  ##   VersionLabels: JArray
  ##                : A list of version labels, specifying one or more application source bundles that belong to the target application. Each source bundle must include an environment manifest that specifies the name of the environment and the name of the solution stack to use, and optionally can specify environment links to create.
  ##   Version: string (required)
  var query_21626143 = newJObject()
  add(query_21626143, "ApplicationName", newJString(ApplicationName))
  add(query_21626143, "Action", newJString(Action))
  add(query_21626143, "GroupName", newJString(GroupName))
  if VersionLabels != nil:
    query_21626143.add "VersionLabels", VersionLabels
  add(query_21626143, "Version", newJString(Version))
  result = call_21626142.call(nil, query_21626143, nil, nil, nil)

var getComposeEnvironments* = Call_GetComposeEnvironments_21626126(
    name: "getComposeEnvironments", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ComposeEnvironments",
    validator: validate_GetComposeEnvironments_21626127, base: "/",
    makeUrl: url_GetComposeEnvironments_21626128,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateApplication_21626183 = ref object of OpenApiRestCall_21625437
proc url_PostCreateApplication_21626185(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateApplication_21626184(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626186 = query.getOrDefault("Action")
  valid_21626186 = validateParameter(valid_21626186, JString, required = true,
                                   default = newJString("CreateApplication"))
  if valid_21626186 != nil:
    section.add "Action", valid_21626186
  var valid_21626187 = query.getOrDefault("Version")
  valid_21626187 = validateParameter(valid_21626187, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626187 != nil:
    section.add "Version", valid_21626187
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626188 = header.getOrDefault("X-Amz-Date")
  valid_21626188 = validateParameter(valid_21626188, JString, required = false,
                                   default = nil)
  if valid_21626188 != nil:
    section.add "X-Amz-Date", valid_21626188
  var valid_21626189 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626189 = validateParameter(valid_21626189, JString, required = false,
                                   default = nil)
  if valid_21626189 != nil:
    section.add "X-Amz-Security-Token", valid_21626189
  var valid_21626190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626190 = validateParameter(valid_21626190, JString, required = false,
                                   default = nil)
  if valid_21626190 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626190
  var valid_21626191 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626191 = validateParameter(valid_21626191, JString, required = false,
                                   default = nil)
  if valid_21626191 != nil:
    section.add "X-Amz-Algorithm", valid_21626191
  var valid_21626192 = header.getOrDefault("X-Amz-Signature")
  valid_21626192 = validateParameter(valid_21626192, JString, required = false,
                                   default = nil)
  if valid_21626192 != nil:
    section.add "X-Amz-Signature", valid_21626192
  var valid_21626193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626193 = validateParameter(valid_21626193, JString, required = false,
                                   default = nil)
  if valid_21626193 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626193
  var valid_21626194 = header.getOrDefault("X-Amz-Credential")
  valid_21626194 = validateParameter(valid_21626194, JString, required = false,
                                   default = nil)
  if valid_21626194 != nil:
    section.add "X-Amz-Credential", valid_21626194
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceLifecycleConfig.VersionLifecycleConfig: JString
  ##                                                 : The resource lifecycle configuration for an application. Defines lifecycle settings for resources that belong to the application, and the service role that Elastic Beanstalk assumes in order to apply lifecycle settings. The version lifecycle configuration defines lifecycle settings for application versions.
  ## The application version lifecycle configuration.
  ##   Tags: JArray
  ##       : <p>Specifies the tags applied to the application.</p> <p>Elastic Beanstalk applies these tags only to the application. Environments that you create in the application don't inherit the tags.</p>
  ##   ResourceLifecycleConfig.ServiceRole: JString
  ##                                      : The resource lifecycle configuration for an application. Defines lifecycle settings for resources that belong to the application, and the service role that Elastic Beanstalk assumes in order to apply lifecycle settings. The version lifecycle configuration defines lifecycle settings for application versions.
  ## <p>The ARN of an IAM service role that Elastic Beanstalk has permission to assume.</p> <p>The <code>ServiceRole</code> property is required the first time that you provide a <code>VersionLifecycleConfig</code> for the application in one of the supporting calls (<code>CreateApplication</code> or <code>UpdateApplicationResourceLifecycle</code>). After you provide it once, in either one of the calls, Elastic Beanstalk persists the Service Role with the application, and you don't need to specify it again in subsequent <code>UpdateApplicationResourceLifecycle</code> calls. You can, however, specify it in subsequent calls to change the Service Role to another value.</p>
  ##   ApplicationName: JString (required)
  ##                  : <p>The name of the application.</p> <p>Constraint: This name must be unique within your account. If the specified name already exists, the action returns an <code>InvalidParameterValue</code> error.</p>
  ##   Description: JString
  ##              : Describes the application.
  section = newJObject()
  var valid_21626195 = formData.getOrDefault(
      "ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_21626195 = validateParameter(valid_21626195, JString, required = false,
                                   default = nil)
  if valid_21626195 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_21626195
  var valid_21626196 = formData.getOrDefault("Tags")
  valid_21626196 = validateParameter(valid_21626196, JArray, required = false,
                                   default = nil)
  if valid_21626196 != nil:
    section.add "Tags", valid_21626196
  var valid_21626197 = formData.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_21626197 = validateParameter(valid_21626197, JString, required = false,
                                   default = nil)
  if valid_21626197 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_21626197
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_21626198 = formData.getOrDefault("ApplicationName")
  valid_21626198 = validateParameter(valid_21626198, JString, required = true,
                                   default = nil)
  if valid_21626198 != nil:
    section.add "ApplicationName", valid_21626198
  var valid_21626199 = formData.getOrDefault("Description")
  valid_21626199 = validateParameter(valid_21626199, JString, required = false,
                                   default = nil)
  if valid_21626199 != nil:
    section.add "Description", valid_21626199
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626200: Call_PostCreateApplication_21626183;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ##  Creates an application that has one configuration template named <code>default</code> and no application versions. 
  ## 
  let valid = call_21626200.validator(path, query, header, formData, body, _)
  let scheme = call_21626200.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626200.makeUrl(scheme.get, call_21626200.host, call_21626200.base,
                               call_21626200.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626200, uri, valid, _)

proc call*(call_21626201: Call_PostCreateApplication_21626183;
          ApplicationName: string;
          ResourceLifecycleConfigVersionLifecycleConfig: string = "";
          Tags: JsonNode = nil; ResourceLifecycleConfigServiceRole: string = "";
          Action: string = "CreateApplication"; Version: string = "2010-12-01";
          Description: string = ""): Recallable =
  ## postCreateApplication
  ##  Creates an application that has one configuration template named <code>default</code> and no application versions. 
  ##   ResourceLifecycleConfigVersionLifecycleConfig: string
  ##                                                : The resource lifecycle configuration for an application. Defines lifecycle settings for resources that belong to the application, and the service role that Elastic Beanstalk assumes in order to apply lifecycle settings. The version lifecycle configuration defines lifecycle settings for application versions.
  ## The application version lifecycle configuration.
  ##   Tags: JArray
  ##       : <p>Specifies the tags applied to the application.</p> <p>Elastic Beanstalk applies these tags only to the application. Environments that you create in the application don't inherit the tags.</p>
  ##   ResourceLifecycleConfigServiceRole: string
  ##                                     : The resource lifecycle configuration for an application. Defines lifecycle settings for resources that belong to the application, and the service role that Elastic Beanstalk assumes in order to apply lifecycle settings. The version lifecycle configuration defines lifecycle settings for application versions.
  ## <p>The ARN of an IAM service role that Elastic Beanstalk has permission to assume.</p> <p>The <code>ServiceRole</code> property is required the first time that you provide a <code>VersionLifecycleConfig</code> for the application in one of the supporting calls (<code>CreateApplication</code> or <code>UpdateApplicationResourceLifecycle</code>). After you provide it once, in either one of the calls, Elastic Beanstalk persists the Service Role with the application, and you don't need to specify it again in subsequent <code>UpdateApplicationResourceLifecycle</code> calls. You can, however, specify it in subsequent calls to change the Service Role to another value.</p>
  ##   Action: string (required)
  ##   ApplicationName: string (required)
  ##                  : <p>The name of the application.</p> <p>Constraint: This name must be unique within your account. If the specified name already exists, the action returns an <code>InvalidParameterValue</code> error.</p>
  ##   Version: string (required)
  ##   Description: string
  ##              : Describes the application.
  var query_21626202 = newJObject()
  var formData_21626203 = newJObject()
  add(formData_21626203, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  if Tags != nil:
    formData_21626203.add "Tags", Tags
  add(formData_21626203, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  add(query_21626202, "Action", newJString(Action))
  add(formData_21626203, "ApplicationName", newJString(ApplicationName))
  add(query_21626202, "Version", newJString(Version))
  add(formData_21626203, "Description", newJString(Description))
  result = call_21626201.call(nil, query_21626202, nil, formData_21626203, nil)

var postCreateApplication* = Call_PostCreateApplication_21626183(
    name: "postCreateApplication", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateApplication",
    validator: validate_PostCreateApplication_21626184, base: "/",
    makeUrl: url_PostCreateApplication_21626185,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateApplication_21626163 = ref object of OpenApiRestCall_21625437
proc url_GetCreateApplication_21626165(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateApplication_21626164(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ##  Creates an application that has one configuration template named <code>default</code> and no application versions. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ResourceLifecycleConfig.VersionLifecycleConfig: JString
  ##                                                 : The resource lifecycle configuration for an application. Defines lifecycle settings for resources that belong to the application, and the service role that Elastic Beanstalk assumes in order to apply lifecycle settings. The version lifecycle configuration defines lifecycle settings for application versions.
  ## The application version lifecycle configuration.
  ##   ApplicationName: JString (required)
  ##                  : <p>The name of the application.</p> <p>Constraint: This name must be unique within your account. If the specified name already exists, the action returns an <code>InvalidParameterValue</code> error.</p>
  ##   Description: JString
  ##              : Describes the application.
  ##   ResourceLifecycleConfig.ServiceRole: JString
  ##                                      : The resource lifecycle configuration for an application. Defines lifecycle settings for resources that belong to the application, and the service role that Elastic Beanstalk assumes in order to apply lifecycle settings. The version lifecycle configuration defines lifecycle settings for application versions.
  ## <p>The ARN of an IAM service role that Elastic Beanstalk has permission to assume.</p> <p>The <code>ServiceRole</code> property is required the first time that you provide a <code>VersionLifecycleConfig</code> for the application in one of the supporting calls (<code>CreateApplication</code> or <code>UpdateApplicationResourceLifecycle</code>). After you provide it once, in either one of the calls, Elastic Beanstalk persists the Service Role with the application, and you don't need to specify it again in subsequent <code>UpdateApplicationResourceLifecycle</code> calls. You can, however, specify it in subsequent calls to change the Service Role to another value.</p>
  ##   Tags: JArray
  ##       : <p>Specifies the tags applied to the application.</p> <p>Elastic Beanstalk applies these tags only to the application. Environments that you create in the application don't inherit the tags.</p>
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626166 = query.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_21626166 = validateParameter(valid_21626166, JString, required = false,
                                   default = nil)
  if valid_21626166 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_21626166
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_21626167 = query.getOrDefault("ApplicationName")
  valid_21626167 = validateParameter(valid_21626167, JString, required = true,
                                   default = nil)
  if valid_21626167 != nil:
    section.add "ApplicationName", valid_21626167
  var valid_21626168 = query.getOrDefault("Description")
  valid_21626168 = validateParameter(valid_21626168, JString, required = false,
                                   default = nil)
  if valid_21626168 != nil:
    section.add "Description", valid_21626168
  var valid_21626169 = query.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_21626169 = validateParameter(valid_21626169, JString, required = false,
                                   default = nil)
  if valid_21626169 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_21626169
  var valid_21626170 = query.getOrDefault("Tags")
  valid_21626170 = validateParameter(valid_21626170, JArray, required = false,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "Tags", valid_21626170
  var valid_21626171 = query.getOrDefault("Action")
  valid_21626171 = validateParameter(valid_21626171, JString, required = true,
                                   default = newJString("CreateApplication"))
  if valid_21626171 != nil:
    section.add "Action", valid_21626171
  var valid_21626172 = query.getOrDefault("Version")
  valid_21626172 = validateParameter(valid_21626172, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626172 != nil:
    section.add "Version", valid_21626172
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626173 = header.getOrDefault("X-Amz-Date")
  valid_21626173 = validateParameter(valid_21626173, JString, required = false,
                                   default = nil)
  if valid_21626173 != nil:
    section.add "X-Amz-Date", valid_21626173
  var valid_21626174 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626174 = validateParameter(valid_21626174, JString, required = false,
                                   default = nil)
  if valid_21626174 != nil:
    section.add "X-Amz-Security-Token", valid_21626174
  var valid_21626175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626175 = validateParameter(valid_21626175, JString, required = false,
                                   default = nil)
  if valid_21626175 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626175
  var valid_21626176 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626176 = validateParameter(valid_21626176, JString, required = false,
                                   default = nil)
  if valid_21626176 != nil:
    section.add "X-Amz-Algorithm", valid_21626176
  var valid_21626177 = header.getOrDefault("X-Amz-Signature")
  valid_21626177 = validateParameter(valid_21626177, JString, required = false,
                                   default = nil)
  if valid_21626177 != nil:
    section.add "X-Amz-Signature", valid_21626177
  var valid_21626178 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626178 = validateParameter(valid_21626178, JString, required = false,
                                   default = nil)
  if valid_21626178 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626178
  var valid_21626179 = header.getOrDefault("X-Amz-Credential")
  valid_21626179 = validateParameter(valid_21626179, JString, required = false,
                                   default = nil)
  if valid_21626179 != nil:
    section.add "X-Amz-Credential", valid_21626179
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626180: Call_GetCreateApplication_21626163; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ##  Creates an application that has one configuration template named <code>default</code> and no application versions. 
  ## 
  let valid = call_21626180.validator(path, query, header, formData, body, _)
  let scheme = call_21626180.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626180.makeUrl(scheme.get, call_21626180.host, call_21626180.base,
                               call_21626180.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626180, uri, valid, _)

proc call*(call_21626181: Call_GetCreateApplication_21626163;
          ApplicationName: string;
          ResourceLifecycleConfigVersionLifecycleConfig: string = "";
          Description: string = ""; ResourceLifecycleConfigServiceRole: string = "";
          Tags: JsonNode = nil; Action: string = "CreateApplication";
          Version: string = "2010-12-01"): Recallable =
  ## getCreateApplication
  ##  Creates an application that has one configuration template named <code>default</code> and no application versions. 
  ##   ResourceLifecycleConfigVersionLifecycleConfig: string
  ##                                                : The resource lifecycle configuration for an application. Defines lifecycle settings for resources that belong to the application, and the service role that Elastic Beanstalk assumes in order to apply lifecycle settings. The version lifecycle configuration defines lifecycle settings for application versions.
  ## The application version lifecycle configuration.
  ##   ApplicationName: string (required)
  ##                  : <p>The name of the application.</p> <p>Constraint: This name must be unique within your account. If the specified name already exists, the action returns an <code>InvalidParameterValue</code> error.</p>
  ##   Description: string
  ##              : Describes the application.
  ##   ResourceLifecycleConfigServiceRole: string
  ##                                     : The resource lifecycle configuration for an application. Defines lifecycle settings for resources that belong to the application, and the service role that Elastic Beanstalk assumes in order to apply lifecycle settings. The version lifecycle configuration defines lifecycle settings for application versions.
  ## <p>The ARN of an IAM service role that Elastic Beanstalk has permission to assume.</p> <p>The <code>ServiceRole</code> property is required the first time that you provide a <code>VersionLifecycleConfig</code> for the application in one of the supporting calls (<code>CreateApplication</code> or <code>UpdateApplicationResourceLifecycle</code>). After you provide it once, in either one of the calls, Elastic Beanstalk persists the Service Role with the application, and you don't need to specify it again in subsequent <code>UpdateApplicationResourceLifecycle</code> calls. You can, however, specify it in subsequent calls to change the Service Role to another value.</p>
  ##   Tags: JArray
  ##       : <p>Specifies the tags applied to the application.</p> <p>Elastic Beanstalk applies these tags only to the application. Environments that you create in the application don't inherit the tags.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626182 = newJObject()
  add(query_21626182, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  add(query_21626182, "ApplicationName", newJString(ApplicationName))
  add(query_21626182, "Description", newJString(Description))
  add(query_21626182, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  if Tags != nil:
    query_21626182.add "Tags", Tags
  add(query_21626182, "Action", newJString(Action))
  add(query_21626182, "Version", newJString(Version))
  result = call_21626181.call(nil, query_21626182, nil, nil, nil)

var getCreateApplication* = Call_GetCreateApplication_21626163(
    name: "getCreateApplication", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateApplication",
    validator: validate_GetCreateApplication_21626164, base: "/",
    makeUrl: url_GetCreateApplication_21626165,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateApplicationVersion_21626235 = ref object of OpenApiRestCall_21625437
proc url_PostCreateApplicationVersion_21626237(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateApplicationVersion_21626236(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626238 = query.getOrDefault("Action")
  valid_21626238 = validateParameter(valid_21626238, JString, required = true, default = newJString(
      "CreateApplicationVersion"))
  if valid_21626238 != nil:
    section.add "Action", valid_21626238
  var valid_21626239 = query.getOrDefault("Version")
  valid_21626239 = validateParameter(valid_21626239, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626239 != nil:
    section.add "Version", valid_21626239
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626240 = header.getOrDefault("X-Amz-Date")
  valid_21626240 = validateParameter(valid_21626240, JString, required = false,
                                   default = nil)
  if valid_21626240 != nil:
    section.add "X-Amz-Date", valid_21626240
  var valid_21626241 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626241 = validateParameter(valid_21626241, JString, required = false,
                                   default = nil)
  if valid_21626241 != nil:
    section.add "X-Amz-Security-Token", valid_21626241
  var valid_21626242 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626242 = validateParameter(valid_21626242, JString, required = false,
                                   default = nil)
  if valid_21626242 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626242
  var valid_21626243 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626243 = validateParameter(valid_21626243, JString, required = false,
                                   default = nil)
  if valid_21626243 != nil:
    section.add "X-Amz-Algorithm", valid_21626243
  var valid_21626244 = header.getOrDefault("X-Amz-Signature")
  valid_21626244 = validateParameter(valid_21626244, JString, required = false,
                                   default = nil)
  if valid_21626244 != nil:
    section.add "X-Amz-Signature", valid_21626244
  var valid_21626245 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626245 = validateParameter(valid_21626245, JString, required = false,
                                   default = nil)
  if valid_21626245 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626245
  var valid_21626246 = header.getOrDefault("X-Amz-Credential")
  valid_21626246 = validateParameter(valid_21626246, JString, required = false,
                                   default = nil)
  if valid_21626246 != nil:
    section.add "X-Amz-Credential", valid_21626246
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceBundle.S3Key: JString
  ##                     : The bucket and key of an item stored in Amazon S3.
  ## The Amazon S3 key where the data is located.
  ##   VersionLabel: JString (required)
  ##               : <p>A label identifying this version.</p> <p>Constraint: Must be unique per application. If an application version already exists with this label for the specified application, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. </p>
  ##   SourceBundle.S3Bucket: JString
  ##                        : The bucket and key of an item stored in Amazon S3.
  ## The Amazon S3 bucket where the data is located.
  ##   BuildConfiguration.ComputeType: JString
  ##                                 : Settings for an AWS CodeBuild build.
  ## <p>Information about the compute resources the build project will use.</p> <ul> <li> <p> <code>BUILD_GENERAL1_SMALL: Use up to 3 GB memory and 2 vCPUs for builds</code> </p> </li> <li> <p> <code>BUILD_GENERAL1_MEDIUM: Use up to 7 GB memory and 4 vCPUs for builds</code> </p> </li> <li> <p> <code>BUILD_GENERAL1_LARGE: Use up to 15 GB memory and 8 vCPUs for builds</code> </p> </li> </ul>
  ##   SourceBuildInformation.SourceType: JString
  ##                                    : Location of the source code for an application version.
  ## <p>The type of repository.</p> <ul> <li> <p> <code>Git</code> </p> </li> <li> <p> <code>Zip</code> </p> </li> </ul>
  ##   Tags: JArray
  ##       : <p>Specifies the tags applied to the application version.</p> <p>Elastic Beanstalk applies these tags only to the application version. Environments that use the application version don't inherit the tags.</p>
  ##   AutoCreateApplication: JBool
  ##                        : Set to <code>true</code> to create an application with the specified name if it doesn't already exist.
  ##   SourceBuildInformation.SourceLocation: JString
  ##                                        : Location of the source code for an application version.
  ## <p>The location of the source code, as a formatted string, depending on the value of <code>SourceRepository</code> </p> <ul> <li> <p>For <code>CodeCommit</code>, the format is the repository name and commit ID, separated by a forward slash. For example, <code>my-git-repo/265cfa0cf6af46153527f55d6503ec030551f57a</code>.</p> </li> <li> <p>For <code>S3</code>, the format is the S3 bucket name and object key, separated by a forward slash. For example, <code>my-s3-bucket/Folders/my-source-file</code>.</p> </li> </ul>
  ##   BuildConfiguration.CodeBuildServiceRole: JString
  ##                                          : Settings for an AWS CodeBuild build.
  ## The Amazon Resource Name (ARN) of the AWS Identity and Access Management (IAM) role that enables AWS CodeBuild to interact with dependent AWS services on behalf of the AWS account.
  ##   ApplicationName: JString (required)
  ##                  :  The name of the application. If no application is found with this name, and <code>AutoCreateApplication</code> is <code>false</code>, returns an <code>InvalidParameterValue</code> error. 
  ##   BuildConfiguration.ArtifactName: JString
  ##                                  : Settings for an AWS CodeBuild build.
  ## The name of the artifact of the CodeBuild build. If provided, Elastic Beanstalk stores the build artifact in the S3 location 
  ## <i>S3-bucket</i>/resources/<i>application-name</i>/codebuild/codebuild-<i>version-label</i>-<i>artifact-name</i>.zip. If not provided, Elastic Beanstalk stores the build artifact in the S3 location 
  ## <i>S3-bucket</i>/resources/<i>application-name</i>/codebuild/codebuild-<i>version-label</i>.zip. 
  ##   BuildConfiguration.TimeoutInMinutes: JString
  ##                                      : Settings for an AWS CodeBuild build.
  ## How long in minutes, from 5 to 480 (8 hours), for AWS CodeBuild to wait until timing out any related build that does not get marked as completed. The default is 60 minutes.
  ##   SourceBuildInformation.SourceRepository: JString
  ##                                          : Location of the source code for an application version.
  ## <p>Location where the repository is stored.</p> <ul> <li> <p> <code>CodeCommit</code> </p> </li> <li> <p> <code>S3</code> </p> </li> </ul>
  ##   Description: JString
  ##              : Describes this version.
  ##   BuildConfiguration.Image: JString
  ##                           : Settings for an AWS CodeBuild build.
  ## The ID of the Docker image to use for this build project.
  ##   Process: JBool
  ##          : <p>Pre-processes and validates the environment manifest (<code>env.yaml</code>) and configuration files (<code>*.config</code> files in the <code>.ebextensions</code> folder) in the source bundle. Validating configuration files can identify issues prior to deploying the application version to an environment.</p> <p>You must turn processing on for application versions that you create using AWS CodeBuild or AWS CodeCommit. For application versions built from a source bundle in Amazon S3, processing is optional.</p> <note> <p>The <code>Process</code> option validates Elastic Beanstalk configuration files. It doesn't validate your application's configuration files, like proxy server or Docker configuration.</p> </note>
  section = newJObject()
  var valid_21626247 = formData.getOrDefault("SourceBundle.S3Key")
  valid_21626247 = validateParameter(valid_21626247, JString, required = false,
                                   default = nil)
  if valid_21626247 != nil:
    section.add "SourceBundle.S3Key", valid_21626247
  assert formData != nil,
        "formData argument is necessary due to required `VersionLabel` field"
  var valid_21626248 = formData.getOrDefault("VersionLabel")
  valid_21626248 = validateParameter(valid_21626248, JString, required = true,
                                   default = nil)
  if valid_21626248 != nil:
    section.add "VersionLabel", valid_21626248
  var valid_21626249 = formData.getOrDefault("SourceBundle.S3Bucket")
  valid_21626249 = validateParameter(valid_21626249, JString, required = false,
                                   default = nil)
  if valid_21626249 != nil:
    section.add "SourceBundle.S3Bucket", valid_21626249
  var valid_21626250 = formData.getOrDefault("BuildConfiguration.ComputeType")
  valid_21626250 = validateParameter(valid_21626250, JString, required = false,
                                   default = nil)
  if valid_21626250 != nil:
    section.add "BuildConfiguration.ComputeType", valid_21626250
  var valid_21626251 = formData.getOrDefault("SourceBuildInformation.SourceType")
  valid_21626251 = validateParameter(valid_21626251, JString, required = false,
                                   default = nil)
  if valid_21626251 != nil:
    section.add "SourceBuildInformation.SourceType", valid_21626251
  var valid_21626252 = formData.getOrDefault("Tags")
  valid_21626252 = validateParameter(valid_21626252, JArray, required = false,
                                   default = nil)
  if valid_21626252 != nil:
    section.add "Tags", valid_21626252
  var valid_21626253 = formData.getOrDefault("AutoCreateApplication")
  valid_21626253 = validateParameter(valid_21626253, JBool, required = false,
                                   default = nil)
  if valid_21626253 != nil:
    section.add "AutoCreateApplication", valid_21626253
  var valid_21626254 = formData.getOrDefault(
      "SourceBuildInformation.SourceLocation")
  valid_21626254 = validateParameter(valid_21626254, JString, required = false,
                                   default = nil)
  if valid_21626254 != nil:
    section.add "SourceBuildInformation.SourceLocation", valid_21626254
  var valid_21626255 = formData.getOrDefault(
      "BuildConfiguration.CodeBuildServiceRole")
  valid_21626255 = validateParameter(valid_21626255, JString, required = false,
                                   default = nil)
  if valid_21626255 != nil:
    section.add "BuildConfiguration.CodeBuildServiceRole", valid_21626255
  var valid_21626256 = formData.getOrDefault("ApplicationName")
  valid_21626256 = validateParameter(valid_21626256, JString, required = true,
                                   default = nil)
  if valid_21626256 != nil:
    section.add "ApplicationName", valid_21626256
  var valid_21626257 = formData.getOrDefault("BuildConfiguration.ArtifactName")
  valid_21626257 = validateParameter(valid_21626257, JString, required = false,
                                   default = nil)
  if valid_21626257 != nil:
    section.add "BuildConfiguration.ArtifactName", valid_21626257
  var valid_21626258 = formData.getOrDefault("BuildConfiguration.TimeoutInMinutes")
  valid_21626258 = validateParameter(valid_21626258, JString, required = false,
                                   default = nil)
  if valid_21626258 != nil:
    section.add "BuildConfiguration.TimeoutInMinutes", valid_21626258
  var valid_21626259 = formData.getOrDefault(
      "SourceBuildInformation.SourceRepository")
  valid_21626259 = validateParameter(valid_21626259, JString, required = false,
                                   default = nil)
  if valid_21626259 != nil:
    section.add "SourceBuildInformation.SourceRepository", valid_21626259
  var valid_21626260 = formData.getOrDefault("Description")
  valid_21626260 = validateParameter(valid_21626260, JString, required = false,
                                   default = nil)
  if valid_21626260 != nil:
    section.add "Description", valid_21626260
  var valid_21626261 = formData.getOrDefault("BuildConfiguration.Image")
  valid_21626261 = validateParameter(valid_21626261, JString, required = false,
                                   default = nil)
  if valid_21626261 != nil:
    section.add "BuildConfiguration.Image", valid_21626261
  var valid_21626262 = formData.getOrDefault("Process")
  valid_21626262 = validateParameter(valid_21626262, JBool, required = false,
                                   default = nil)
  if valid_21626262 != nil:
    section.add "Process", valid_21626262
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626263: Call_PostCreateApplicationVersion_21626235;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates an application version for the specified application. You can create an application version from a source bundle in Amazon S3, a commit in AWS CodeCommit, or the output of an AWS CodeBuild build as follows:</p> <p>Specify a commit in an AWS CodeCommit repository with <code>SourceBuildInformation</code>.</p> <p>Specify a build in an AWS CodeBuild with <code>SourceBuildInformation</code> and <code>BuildConfiguration</code>.</p> <p>Specify a source bundle in S3 with <code>SourceBundle</code> </p> <p>Omit both <code>SourceBuildInformation</code> and <code>SourceBundle</code> to use the default sample application.</p> <note> <p>Once you create an application version with a specified Amazon S3 bucket and key location, you cannot change that Amazon S3 location. If you change the Amazon S3 location, you receive an exception when you attempt to launch an environment from the application version.</p> </note>
  ## 
  let valid = call_21626263.validator(path, query, header, formData, body, _)
  let scheme = call_21626263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626263.makeUrl(scheme.get, call_21626263.host, call_21626263.base,
                               call_21626263.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626263, uri, valid, _)

proc call*(call_21626264: Call_PostCreateApplicationVersion_21626235;
          VersionLabel: string; ApplicationName: string;
          SourceBundleS3Key: string = ""; SourceBundleS3Bucket: string = "";
          BuildConfigurationComputeType: string = "";
          SourceBuildInformationSourceType: string = ""; Tags: JsonNode = nil;
          AutoCreateApplication: bool = false;
          SourceBuildInformationSourceLocation: string = "";
          Action: string = "CreateApplicationVersion";
          BuildConfigurationCodeBuildServiceRole: string = "";
          BuildConfigurationArtifactName: string = "";
          BuildConfigurationTimeoutInMinutes: string = "";
          SourceBuildInformationSourceRepository: string = "";
          Description: string = ""; BuildConfigurationImage: string = "";
          Process: bool = false; Version: string = "2010-12-01"): Recallable =
  ## postCreateApplicationVersion
  ## <p>Creates an application version for the specified application. You can create an application version from a source bundle in Amazon S3, a commit in AWS CodeCommit, or the output of an AWS CodeBuild build as follows:</p> <p>Specify a commit in an AWS CodeCommit repository with <code>SourceBuildInformation</code>.</p> <p>Specify a build in an AWS CodeBuild with <code>SourceBuildInformation</code> and <code>BuildConfiguration</code>.</p> <p>Specify a source bundle in S3 with <code>SourceBundle</code> </p> <p>Omit both <code>SourceBuildInformation</code> and <code>SourceBundle</code> to use the default sample application.</p> <note> <p>Once you create an application version with a specified Amazon S3 bucket and key location, you cannot change that Amazon S3 location. If you change the Amazon S3 location, you receive an exception when you attempt to launch an environment from the application version.</p> </note>
  ##   SourceBundleS3Key: string
  ##                    : The bucket and key of an item stored in Amazon S3.
  ## The Amazon S3 key where the data is located.
  ##   VersionLabel: string (required)
  ##               : <p>A label identifying this version.</p> <p>Constraint: Must be unique per application. If an application version already exists with this label for the specified application, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. </p>
  ##   SourceBundleS3Bucket: string
  ##                       : The bucket and key of an item stored in Amazon S3.
  ## The Amazon S3 bucket where the data is located.
  ##   BuildConfigurationComputeType: string
  ##                                : Settings for an AWS CodeBuild build.
  ## <p>Information about the compute resources the build project will use.</p> <ul> <li> <p> <code>BUILD_GENERAL1_SMALL: Use up to 3 GB memory and 2 vCPUs for builds</code> </p> </li> <li> <p> <code>BUILD_GENERAL1_MEDIUM: Use up to 7 GB memory and 4 vCPUs for builds</code> </p> </li> <li> <p> <code>BUILD_GENERAL1_LARGE: Use up to 15 GB memory and 8 vCPUs for builds</code> </p> </li> </ul>
  ##   SourceBuildInformationSourceType: string
  ##                                   : Location of the source code for an application version.
  ## <p>The type of repository.</p> <ul> <li> <p> <code>Git</code> </p> </li> <li> <p> <code>Zip</code> </p> </li> </ul>
  ##   Tags: JArray
  ##       : <p>Specifies the tags applied to the application version.</p> <p>Elastic Beanstalk applies these tags only to the application version. Environments that use the application version don't inherit the tags.</p>
  ##   AutoCreateApplication: bool
  ##                        : Set to <code>true</code> to create an application with the specified name if it doesn't already exist.
  ##   SourceBuildInformationSourceLocation: string
  ##                                       : Location of the source code for an application version.
  ## <p>The location of the source code, as a formatted string, depending on the value of <code>SourceRepository</code> </p> <ul> <li> <p>For <code>CodeCommit</code>, the format is the repository name and commit ID, separated by a forward slash. For example, <code>my-git-repo/265cfa0cf6af46153527f55d6503ec030551f57a</code>.</p> </li> <li> <p>For <code>S3</code>, the format is the S3 bucket name and object key, separated by a forward slash. For example, <code>my-s3-bucket/Folders/my-source-file</code>.</p> </li> </ul>
  ##   Action: string (required)
  ##   BuildConfigurationCodeBuildServiceRole: string
  ##                                         : Settings for an AWS CodeBuild build.
  ## The Amazon Resource Name (ARN) of the AWS Identity and Access Management (IAM) role that enables AWS CodeBuild to interact with dependent AWS services on behalf of the AWS account.
  ##   ApplicationName: string (required)
  ##                  :  The name of the application. If no application is found with this name, and <code>AutoCreateApplication</code> is <code>false</code>, returns an <code>InvalidParameterValue</code> error. 
  ##   BuildConfigurationArtifactName: string
  ##                                 : Settings for an AWS CodeBuild build.
  ## The name of the artifact of the CodeBuild build. If provided, Elastic Beanstalk stores the build artifact in the S3 location 
  ## <i>S3-bucket</i>/resources/<i>application-name</i>/codebuild/codebuild-<i>version-label</i>-<i>artifact-name</i>.zip. If not provided, Elastic Beanstalk stores the build artifact in the S3 location 
  ## <i>S3-bucket</i>/resources/<i>application-name</i>/codebuild/codebuild-<i>version-label</i>.zip. 
  ##   BuildConfigurationTimeoutInMinutes: string
  ##                                     : Settings for an AWS CodeBuild build.
  ## How long in minutes, from 5 to 480 (8 hours), for AWS CodeBuild to wait until timing out any related build that does not get marked as completed. The default is 60 minutes.
  ##   SourceBuildInformationSourceRepository: string
  ##                                         : Location of the source code for an application version.
  ## <p>Location where the repository is stored.</p> <ul> <li> <p> <code>CodeCommit</code> </p> </li> <li> <p> <code>S3</code> </p> </li> </ul>
  ##   Description: string
  ##              : Describes this version.
  ##   BuildConfigurationImage: string
  ##                          : Settings for an AWS CodeBuild build.
  ## The ID of the Docker image to use for this build project.
  ##   Process: bool
  ##          : <p>Pre-processes and validates the environment manifest (<code>env.yaml</code>) and configuration files (<code>*.config</code> files in the <code>.ebextensions</code> folder) in the source bundle. Validating configuration files can identify issues prior to deploying the application version to an environment.</p> <p>You must turn processing on for application versions that you create using AWS CodeBuild or AWS CodeCommit. For application versions built from a source bundle in Amazon S3, processing is optional.</p> <note> <p>The <code>Process</code> option validates Elastic Beanstalk configuration files. It doesn't validate your application's configuration files, like proxy server or Docker configuration.</p> </note>
  ##   Version: string (required)
  var query_21626265 = newJObject()
  var formData_21626266 = newJObject()
  add(formData_21626266, "SourceBundle.S3Key", newJString(SourceBundleS3Key))
  add(formData_21626266, "VersionLabel", newJString(VersionLabel))
  add(formData_21626266, "SourceBundle.S3Bucket", newJString(SourceBundleS3Bucket))
  add(formData_21626266, "BuildConfiguration.ComputeType",
      newJString(BuildConfigurationComputeType))
  add(formData_21626266, "SourceBuildInformation.SourceType",
      newJString(SourceBuildInformationSourceType))
  if Tags != nil:
    formData_21626266.add "Tags", Tags
  add(formData_21626266, "AutoCreateApplication", newJBool(AutoCreateApplication))
  add(formData_21626266, "SourceBuildInformation.SourceLocation",
      newJString(SourceBuildInformationSourceLocation))
  add(query_21626265, "Action", newJString(Action))
  add(formData_21626266, "BuildConfiguration.CodeBuildServiceRole",
      newJString(BuildConfigurationCodeBuildServiceRole))
  add(formData_21626266, "ApplicationName", newJString(ApplicationName))
  add(formData_21626266, "BuildConfiguration.ArtifactName",
      newJString(BuildConfigurationArtifactName))
  add(formData_21626266, "BuildConfiguration.TimeoutInMinutes",
      newJString(BuildConfigurationTimeoutInMinutes))
  add(formData_21626266, "SourceBuildInformation.SourceRepository",
      newJString(SourceBuildInformationSourceRepository))
  add(formData_21626266, "Description", newJString(Description))
  add(formData_21626266, "BuildConfiguration.Image",
      newJString(BuildConfigurationImage))
  add(formData_21626266, "Process", newJBool(Process))
  add(query_21626265, "Version", newJString(Version))
  result = call_21626264.call(nil, query_21626265, nil, formData_21626266, nil)

var postCreateApplicationVersion* = Call_PostCreateApplicationVersion_21626235(
    name: "postCreateApplicationVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateApplicationVersion",
    validator: validate_PostCreateApplicationVersion_21626236, base: "/",
    makeUrl: url_PostCreateApplicationVersion_21626237,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateApplicationVersion_21626204 = ref object of OpenApiRestCall_21625437
proc url_GetCreateApplicationVersion_21626206(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateApplicationVersion_21626205(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates an application version for the specified application. You can create an application version from a source bundle in Amazon S3, a commit in AWS CodeCommit, or the output of an AWS CodeBuild build as follows:</p> <p>Specify a commit in an AWS CodeCommit repository with <code>SourceBuildInformation</code>.</p> <p>Specify a build in an AWS CodeBuild with <code>SourceBuildInformation</code> and <code>BuildConfiguration</code>.</p> <p>Specify a source bundle in S3 with <code>SourceBundle</code> </p> <p>Omit both <code>SourceBuildInformation</code> and <code>SourceBundle</code> to use the default sample application.</p> <note> <p>Once you create an application version with a specified Amazon S3 bucket and key location, you cannot change that Amazon S3 location. If you change the Amazon S3 location, you receive an exception when you attempt to launch an environment from the application version.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   BuildConfiguration.TimeoutInMinutes: JString
  ##                                      : Settings for an AWS CodeBuild build.
  ## How long in minutes, from 5 to 480 (8 hours), for AWS CodeBuild to wait until timing out any related build that does not get marked as completed. The default is 60 minutes.
  ##   SourceBundle.S3Bucket: JString
  ##                        : The bucket and key of an item stored in Amazon S3.
  ## The Amazon S3 bucket where the data is located.
  ##   BuildConfiguration.ComputeType: JString
  ##                                 : Settings for an AWS CodeBuild build.
  ## <p>Information about the compute resources the build project will use.</p> <ul> <li> <p> <code>BUILD_GENERAL1_SMALL: Use up to 3 GB memory and 2 vCPUs for builds</code> </p> </li> <li> <p> <code>BUILD_GENERAL1_MEDIUM: Use up to 7 GB memory and 4 vCPUs for builds</code> </p> </li> <li> <p> <code>BUILD_GENERAL1_LARGE: Use up to 15 GB memory and 8 vCPUs for builds</code> </p> </li> </ul>
  ##   VersionLabel: JString (required)
  ##               : <p>A label identifying this version.</p> <p>Constraint: Must be unique per application. If an application version already exists with this label for the specified application, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. </p>
  ##   BuildConfiguration.ArtifactName: JString
  ##                                  : Settings for an AWS CodeBuild build.
  ## The name of the artifact of the CodeBuild build. If provided, Elastic Beanstalk stores the build artifact in the S3 location 
  ## <i>S3-bucket</i>/resources/<i>application-name</i>/codebuild/codebuild-<i>version-label</i>-<i>artifact-name</i>.zip. If not provided, Elastic Beanstalk stores the build artifact in the S3 location 
  ## <i>S3-bucket</i>/resources/<i>application-name</i>/codebuild/codebuild-<i>version-label</i>.zip. 
  ##   ApplicationName: JString (required)
  ##                  :  The name of the application. If no application is found with this name, and <code>AutoCreateApplication</code> is <code>false</code>, returns an <code>InvalidParameterValue</code> error. 
  ##   Description: JString
  ##              : Describes this version.
  ##   BuildConfiguration.Image: JString
  ##                           : Settings for an AWS CodeBuild build.
  ## The ID of the Docker image to use for this build project.
  ##   SourceBuildInformation.SourceLocation: JString
  ##                                        : Location of the source code for an application version.
  ## <p>The location of the source code, as a formatted string, depending on the value of <code>SourceRepository</code> </p> <ul> <li> <p>For <code>CodeCommit</code>, the format is the repository name and commit ID, separated by a forward slash. For example, <code>my-git-repo/265cfa0cf6af46153527f55d6503ec030551f57a</code>.</p> </li> <li> <p>For <code>S3</code>, the format is the S3 bucket name and object key, separated by a forward slash. For example, <code>my-s3-bucket/Folders/my-source-file</code>.</p> </li> </ul>
  ##   SourceBundle.S3Key: JString
  ##                     : The bucket and key of an item stored in Amazon S3.
  ## The Amazon S3 key where the data is located.
  ##   Tags: JArray
  ##       : <p>Specifies the tags applied to the application version.</p> <p>Elastic Beanstalk applies these tags only to the application version. Environments that use the application version don't inherit the tags.</p>
  ##   AutoCreateApplication: JBool
  ##                        : Set to <code>true</code> to create an application with the specified name if it doesn't already exist.
  ##   Action: JString (required)
  ##   SourceBuildInformation.SourceType: JString
  ##                                    : Location of the source code for an application version.
  ## <p>The type of repository.</p> <ul> <li> <p> <code>Git</code> </p> </li> <li> <p> <code>Zip</code> </p> </li> </ul>
  ##   BuildConfiguration.CodeBuildServiceRole: JString
  ##                                          : Settings for an AWS CodeBuild build.
  ## The Amazon Resource Name (ARN) of the AWS Identity and Access Management (IAM) role that enables AWS CodeBuild to interact with dependent AWS services on behalf of the AWS account.
  ##   Process: JBool
  ##          : <p>Pre-processes and validates the environment manifest (<code>env.yaml</code>) and configuration files (<code>*.config</code> files in the <code>.ebextensions</code> folder) in the source bundle. Validating configuration files can identify issues prior to deploying the application version to an environment.</p> <p>You must turn processing on for application versions that you create using AWS CodeBuild or AWS CodeCommit. For application versions built from a source bundle in Amazon S3, processing is optional.</p> <note> <p>The <code>Process</code> option validates Elastic Beanstalk configuration files. It doesn't validate your application's configuration files, like proxy server or Docker configuration.</p> </note>
  ##   SourceBuildInformation.SourceRepository: JString
  ##                                          : Location of the source code for an application version.
  ## <p>Location where the repository is stored.</p> <ul> <li> <p> <code>CodeCommit</code> </p> </li> <li> <p> <code>S3</code> </p> </li> </ul>
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626207 = query.getOrDefault("BuildConfiguration.TimeoutInMinutes")
  valid_21626207 = validateParameter(valid_21626207, JString, required = false,
                                   default = nil)
  if valid_21626207 != nil:
    section.add "BuildConfiguration.TimeoutInMinutes", valid_21626207
  var valid_21626208 = query.getOrDefault("SourceBundle.S3Bucket")
  valid_21626208 = validateParameter(valid_21626208, JString, required = false,
                                   default = nil)
  if valid_21626208 != nil:
    section.add "SourceBundle.S3Bucket", valid_21626208
  var valid_21626209 = query.getOrDefault("BuildConfiguration.ComputeType")
  valid_21626209 = validateParameter(valid_21626209, JString, required = false,
                                   default = nil)
  if valid_21626209 != nil:
    section.add "BuildConfiguration.ComputeType", valid_21626209
  assert query != nil,
        "query argument is necessary due to required `VersionLabel` field"
  var valid_21626210 = query.getOrDefault("VersionLabel")
  valid_21626210 = validateParameter(valid_21626210, JString, required = true,
                                   default = nil)
  if valid_21626210 != nil:
    section.add "VersionLabel", valid_21626210
  var valid_21626211 = query.getOrDefault("BuildConfiguration.ArtifactName")
  valid_21626211 = validateParameter(valid_21626211, JString, required = false,
                                   default = nil)
  if valid_21626211 != nil:
    section.add "BuildConfiguration.ArtifactName", valid_21626211
  var valid_21626212 = query.getOrDefault("ApplicationName")
  valid_21626212 = validateParameter(valid_21626212, JString, required = true,
                                   default = nil)
  if valid_21626212 != nil:
    section.add "ApplicationName", valid_21626212
  var valid_21626213 = query.getOrDefault("Description")
  valid_21626213 = validateParameter(valid_21626213, JString, required = false,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "Description", valid_21626213
  var valid_21626214 = query.getOrDefault("BuildConfiguration.Image")
  valid_21626214 = validateParameter(valid_21626214, JString, required = false,
                                   default = nil)
  if valid_21626214 != nil:
    section.add "BuildConfiguration.Image", valid_21626214
  var valid_21626215 = query.getOrDefault("SourceBuildInformation.SourceLocation")
  valid_21626215 = validateParameter(valid_21626215, JString, required = false,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "SourceBuildInformation.SourceLocation", valid_21626215
  var valid_21626216 = query.getOrDefault("SourceBundle.S3Key")
  valid_21626216 = validateParameter(valid_21626216, JString, required = false,
                                   default = nil)
  if valid_21626216 != nil:
    section.add "SourceBundle.S3Key", valid_21626216
  var valid_21626217 = query.getOrDefault("Tags")
  valid_21626217 = validateParameter(valid_21626217, JArray, required = false,
                                   default = nil)
  if valid_21626217 != nil:
    section.add "Tags", valid_21626217
  var valid_21626218 = query.getOrDefault("AutoCreateApplication")
  valid_21626218 = validateParameter(valid_21626218, JBool, required = false,
                                   default = nil)
  if valid_21626218 != nil:
    section.add "AutoCreateApplication", valid_21626218
  var valid_21626219 = query.getOrDefault("Action")
  valid_21626219 = validateParameter(valid_21626219, JString, required = true, default = newJString(
      "CreateApplicationVersion"))
  if valid_21626219 != nil:
    section.add "Action", valid_21626219
  var valid_21626220 = query.getOrDefault("SourceBuildInformation.SourceType")
  valid_21626220 = validateParameter(valid_21626220, JString, required = false,
                                   default = nil)
  if valid_21626220 != nil:
    section.add "SourceBuildInformation.SourceType", valid_21626220
  var valid_21626221 = query.getOrDefault("BuildConfiguration.CodeBuildServiceRole")
  valid_21626221 = validateParameter(valid_21626221, JString, required = false,
                                   default = nil)
  if valid_21626221 != nil:
    section.add "BuildConfiguration.CodeBuildServiceRole", valid_21626221
  var valid_21626222 = query.getOrDefault("Process")
  valid_21626222 = validateParameter(valid_21626222, JBool, required = false,
                                   default = nil)
  if valid_21626222 != nil:
    section.add "Process", valid_21626222
  var valid_21626223 = query.getOrDefault("SourceBuildInformation.SourceRepository")
  valid_21626223 = validateParameter(valid_21626223, JString, required = false,
                                   default = nil)
  if valid_21626223 != nil:
    section.add "SourceBuildInformation.SourceRepository", valid_21626223
  var valid_21626224 = query.getOrDefault("Version")
  valid_21626224 = validateParameter(valid_21626224, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626224 != nil:
    section.add "Version", valid_21626224
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626225 = header.getOrDefault("X-Amz-Date")
  valid_21626225 = validateParameter(valid_21626225, JString, required = false,
                                   default = nil)
  if valid_21626225 != nil:
    section.add "X-Amz-Date", valid_21626225
  var valid_21626226 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626226 = validateParameter(valid_21626226, JString, required = false,
                                   default = nil)
  if valid_21626226 != nil:
    section.add "X-Amz-Security-Token", valid_21626226
  var valid_21626227 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626227 = validateParameter(valid_21626227, JString, required = false,
                                   default = nil)
  if valid_21626227 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626227
  var valid_21626228 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626228 = validateParameter(valid_21626228, JString, required = false,
                                   default = nil)
  if valid_21626228 != nil:
    section.add "X-Amz-Algorithm", valid_21626228
  var valid_21626229 = header.getOrDefault("X-Amz-Signature")
  valid_21626229 = validateParameter(valid_21626229, JString, required = false,
                                   default = nil)
  if valid_21626229 != nil:
    section.add "X-Amz-Signature", valid_21626229
  var valid_21626230 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626230 = validateParameter(valid_21626230, JString, required = false,
                                   default = nil)
  if valid_21626230 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626230
  var valid_21626231 = header.getOrDefault("X-Amz-Credential")
  valid_21626231 = validateParameter(valid_21626231, JString, required = false,
                                   default = nil)
  if valid_21626231 != nil:
    section.add "X-Amz-Credential", valid_21626231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626232: Call_GetCreateApplicationVersion_21626204;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates an application version for the specified application. You can create an application version from a source bundle in Amazon S3, a commit in AWS CodeCommit, or the output of an AWS CodeBuild build as follows:</p> <p>Specify a commit in an AWS CodeCommit repository with <code>SourceBuildInformation</code>.</p> <p>Specify a build in an AWS CodeBuild with <code>SourceBuildInformation</code> and <code>BuildConfiguration</code>.</p> <p>Specify a source bundle in S3 with <code>SourceBundle</code> </p> <p>Omit both <code>SourceBuildInformation</code> and <code>SourceBundle</code> to use the default sample application.</p> <note> <p>Once you create an application version with a specified Amazon S3 bucket and key location, you cannot change that Amazon S3 location. If you change the Amazon S3 location, you receive an exception when you attempt to launch an environment from the application version.</p> </note>
  ## 
  let valid = call_21626232.validator(path, query, header, formData, body, _)
  let scheme = call_21626232.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626232.makeUrl(scheme.get, call_21626232.host, call_21626232.base,
                               call_21626232.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626232, uri, valid, _)

proc call*(call_21626233: Call_GetCreateApplicationVersion_21626204;
          VersionLabel: string; ApplicationName: string;
          BuildConfigurationTimeoutInMinutes: string = "";
          SourceBundleS3Bucket: string = "";
          BuildConfigurationComputeType: string = "";
          BuildConfigurationArtifactName: string = ""; Description: string = "";
          BuildConfigurationImage: string = "";
          SourceBuildInformationSourceLocation: string = "";
          SourceBundleS3Key: string = ""; Tags: JsonNode = nil;
          AutoCreateApplication: bool = false;
          Action: string = "CreateApplicationVersion";
          SourceBuildInformationSourceType: string = "";
          BuildConfigurationCodeBuildServiceRole: string = "";
          Process: bool = false;
          SourceBuildInformationSourceRepository: string = "";
          Version: string = "2010-12-01"): Recallable =
  ## getCreateApplicationVersion
  ## <p>Creates an application version for the specified application. You can create an application version from a source bundle in Amazon S3, a commit in AWS CodeCommit, or the output of an AWS CodeBuild build as follows:</p> <p>Specify a commit in an AWS CodeCommit repository with <code>SourceBuildInformation</code>.</p> <p>Specify a build in an AWS CodeBuild with <code>SourceBuildInformation</code> and <code>BuildConfiguration</code>.</p> <p>Specify a source bundle in S3 with <code>SourceBundle</code> </p> <p>Omit both <code>SourceBuildInformation</code> and <code>SourceBundle</code> to use the default sample application.</p> <note> <p>Once you create an application version with a specified Amazon S3 bucket and key location, you cannot change that Amazon S3 location. If you change the Amazon S3 location, you receive an exception when you attempt to launch an environment from the application version.</p> </note>
  ##   BuildConfigurationTimeoutInMinutes: string
  ##                                     : Settings for an AWS CodeBuild build.
  ## How long in minutes, from 5 to 480 (8 hours), for AWS CodeBuild to wait until timing out any related build that does not get marked as completed. The default is 60 minutes.
  ##   SourceBundleS3Bucket: string
  ##                       : The bucket and key of an item stored in Amazon S3.
  ## The Amazon S3 bucket where the data is located.
  ##   BuildConfigurationComputeType: string
  ##                                : Settings for an AWS CodeBuild build.
  ## <p>Information about the compute resources the build project will use.</p> <ul> <li> <p> <code>BUILD_GENERAL1_SMALL: Use up to 3 GB memory and 2 vCPUs for builds</code> </p> </li> <li> <p> <code>BUILD_GENERAL1_MEDIUM: Use up to 7 GB memory and 4 vCPUs for builds</code> </p> </li> <li> <p> <code>BUILD_GENERAL1_LARGE: Use up to 15 GB memory and 8 vCPUs for builds</code> </p> </li> </ul>
  ##   VersionLabel: string (required)
  ##               : <p>A label identifying this version.</p> <p>Constraint: Must be unique per application. If an application version already exists with this label for the specified application, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. </p>
  ##   BuildConfigurationArtifactName: string
  ##                                 : Settings for an AWS CodeBuild build.
  ## The name of the artifact of the CodeBuild build. If provided, Elastic Beanstalk stores the build artifact in the S3 location 
  ## <i>S3-bucket</i>/resources/<i>application-name</i>/codebuild/codebuild-<i>version-label</i>-<i>artifact-name</i>.zip. If not provided, Elastic Beanstalk stores the build artifact in the S3 location 
  ## <i>S3-bucket</i>/resources/<i>application-name</i>/codebuild/codebuild-<i>version-label</i>.zip. 
  ##   ApplicationName: string (required)
  ##                  :  The name of the application. If no application is found with this name, and <code>AutoCreateApplication</code> is <code>false</code>, returns an <code>InvalidParameterValue</code> error. 
  ##   Description: string
  ##              : Describes this version.
  ##   BuildConfigurationImage: string
  ##                          : Settings for an AWS CodeBuild build.
  ## The ID of the Docker image to use for this build project.
  ##   SourceBuildInformationSourceLocation: string
  ##                                       : Location of the source code for an application version.
  ## <p>The location of the source code, as a formatted string, depending on the value of <code>SourceRepository</code> </p> <ul> <li> <p>For <code>CodeCommit</code>, the format is the repository name and commit ID, separated by a forward slash. For example, <code>my-git-repo/265cfa0cf6af46153527f55d6503ec030551f57a</code>.</p> </li> <li> <p>For <code>S3</code>, the format is the S3 bucket name and object key, separated by a forward slash. For example, <code>my-s3-bucket/Folders/my-source-file</code>.</p> </li> </ul>
  ##   SourceBundleS3Key: string
  ##                    : The bucket and key of an item stored in Amazon S3.
  ## The Amazon S3 key where the data is located.
  ##   Tags: JArray
  ##       : <p>Specifies the tags applied to the application version.</p> <p>Elastic Beanstalk applies these tags only to the application version. Environments that use the application version don't inherit the tags.</p>
  ##   AutoCreateApplication: bool
  ##                        : Set to <code>true</code> to create an application with the specified name if it doesn't already exist.
  ##   Action: string (required)
  ##   SourceBuildInformationSourceType: string
  ##                                   : Location of the source code for an application version.
  ## <p>The type of repository.</p> <ul> <li> <p> <code>Git</code> </p> </li> <li> <p> <code>Zip</code> </p> </li> </ul>
  ##   BuildConfigurationCodeBuildServiceRole: string
  ##                                         : Settings for an AWS CodeBuild build.
  ## The Amazon Resource Name (ARN) of the AWS Identity and Access Management (IAM) role that enables AWS CodeBuild to interact with dependent AWS services on behalf of the AWS account.
  ##   Process: bool
  ##          : <p>Pre-processes and validates the environment manifest (<code>env.yaml</code>) and configuration files (<code>*.config</code> files in the <code>.ebextensions</code> folder) in the source bundle. Validating configuration files can identify issues prior to deploying the application version to an environment.</p> <p>You must turn processing on for application versions that you create using AWS CodeBuild or AWS CodeCommit. For application versions built from a source bundle in Amazon S3, processing is optional.</p> <note> <p>The <code>Process</code> option validates Elastic Beanstalk configuration files. It doesn't validate your application's configuration files, like proxy server or Docker configuration.</p> </note>
  ##   SourceBuildInformationSourceRepository: string
  ##                                         : Location of the source code for an application version.
  ## <p>Location where the repository is stored.</p> <ul> <li> <p> <code>CodeCommit</code> </p> </li> <li> <p> <code>S3</code> </p> </li> </ul>
  ##   Version: string (required)
  var query_21626234 = newJObject()
  add(query_21626234, "BuildConfiguration.TimeoutInMinutes",
      newJString(BuildConfigurationTimeoutInMinutes))
  add(query_21626234, "SourceBundle.S3Bucket", newJString(SourceBundleS3Bucket))
  add(query_21626234, "BuildConfiguration.ComputeType",
      newJString(BuildConfigurationComputeType))
  add(query_21626234, "VersionLabel", newJString(VersionLabel))
  add(query_21626234, "BuildConfiguration.ArtifactName",
      newJString(BuildConfigurationArtifactName))
  add(query_21626234, "ApplicationName", newJString(ApplicationName))
  add(query_21626234, "Description", newJString(Description))
  add(query_21626234, "BuildConfiguration.Image",
      newJString(BuildConfigurationImage))
  add(query_21626234, "SourceBuildInformation.SourceLocation",
      newJString(SourceBuildInformationSourceLocation))
  add(query_21626234, "SourceBundle.S3Key", newJString(SourceBundleS3Key))
  if Tags != nil:
    query_21626234.add "Tags", Tags
  add(query_21626234, "AutoCreateApplication", newJBool(AutoCreateApplication))
  add(query_21626234, "Action", newJString(Action))
  add(query_21626234, "SourceBuildInformation.SourceType",
      newJString(SourceBuildInformationSourceType))
  add(query_21626234, "BuildConfiguration.CodeBuildServiceRole",
      newJString(BuildConfigurationCodeBuildServiceRole))
  add(query_21626234, "Process", newJBool(Process))
  add(query_21626234, "SourceBuildInformation.SourceRepository",
      newJString(SourceBuildInformationSourceRepository))
  add(query_21626234, "Version", newJString(Version))
  result = call_21626233.call(nil, query_21626234, nil, nil, nil)

var getCreateApplicationVersion* = Call_GetCreateApplicationVersion_21626204(
    name: "getCreateApplicationVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateApplicationVersion",
    validator: validate_GetCreateApplicationVersion_21626205, base: "/",
    makeUrl: url_GetCreateApplicationVersion_21626206,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateConfigurationTemplate_21626292 = ref object of OpenApiRestCall_21625437
proc url_PostCreateConfigurationTemplate_21626294(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateConfigurationTemplate_21626293(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626295 = query.getOrDefault("Action")
  valid_21626295 = validateParameter(valid_21626295, JString, required = true, default = newJString(
      "CreateConfigurationTemplate"))
  if valid_21626295 != nil:
    section.add "Action", valid_21626295
  var valid_21626296 = query.getOrDefault("Version")
  valid_21626296 = validateParameter(valid_21626296, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626296 != nil:
    section.add "Version", valid_21626296
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626297 = header.getOrDefault("X-Amz-Date")
  valid_21626297 = validateParameter(valid_21626297, JString, required = false,
                                   default = nil)
  if valid_21626297 != nil:
    section.add "X-Amz-Date", valid_21626297
  var valid_21626298 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626298 = validateParameter(valid_21626298, JString, required = false,
                                   default = nil)
  if valid_21626298 != nil:
    section.add "X-Amz-Security-Token", valid_21626298
  var valid_21626299 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626299 = validateParameter(valid_21626299, JString, required = false,
                                   default = nil)
  if valid_21626299 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626299
  var valid_21626300 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626300 = validateParameter(valid_21626300, JString, required = false,
                                   default = nil)
  if valid_21626300 != nil:
    section.add "X-Amz-Algorithm", valid_21626300
  var valid_21626301 = header.getOrDefault("X-Amz-Signature")
  valid_21626301 = validateParameter(valid_21626301, JString, required = false,
                                   default = nil)
  if valid_21626301 != nil:
    section.add "X-Amz-Signature", valid_21626301
  var valid_21626302 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626302 = validateParameter(valid_21626302, JString, required = false,
                                   default = nil)
  if valid_21626302 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626302
  var valid_21626303 = header.getOrDefault("X-Amz-Credential")
  valid_21626303 = validateParameter(valid_21626303, JString, required = false,
                                   default = nil)
  if valid_21626303 != nil:
    section.add "X-Amz-Credential", valid_21626303
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionSettings: JArray
  ##                 : If specified, AWS Elastic Beanstalk sets the specified configuration option to the requested value. The new value overrides the value obtained from the solution stack or the source configuration template.
  ##   Tags: JArray
  ##       : Specifies the tags applied to the configuration template.
  ##   SolutionStackName: JString
  ##                    : <p>The name of the solution stack used by this configuration. The solution stack specifies the operating system, architecture, and application server for a configuration template. It determines the set of configuration options as well as the possible and default values.</p> <p> Use <a>ListAvailableSolutionStacks</a> to obtain a list of available solution stacks. </p> <p> A solution stack name or a source configuration parameter must be specified, otherwise AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. </p> <p>If a solution stack name is not specified and the source configuration parameter is specified, AWS Elastic Beanstalk uses the same solution stack as the source configuration template.</p>
  ##   SourceConfiguration.ApplicationName: JString
  ##                                      : A specification for an environment configuration
  ## The name of the application associated with the configuration.
  ##   EnvironmentId: JString
  ##                : The ID of the environment used with this configuration template.
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to associate with this configuration template. If no application is found with this name, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. 
  ##   PlatformArn: JString
  ##              : The ARN of the custom platform.
  ##   TemplateName: JString (required)
  ##               : <p>The name of the configuration template.</p> <p>Constraint: This name must be unique per application.</p> <p>Default: If a configuration template already exists with this name, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. </p>
  ##   Description: JString
  ##              : Describes this configuration.
  ##   SourceConfiguration.TemplateName: JString
  ##                                   : A specification for an environment configuration
  ## The name of the configuration template.
  section = newJObject()
  var valid_21626304 = formData.getOrDefault("OptionSettings")
  valid_21626304 = validateParameter(valid_21626304, JArray, required = false,
                                   default = nil)
  if valid_21626304 != nil:
    section.add "OptionSettings", valid_21626304
  var valid_21626305 = formData.getOrDefault("Tags")
  valid_21626305 = validateParameter(valid_21626305, JArray, required = false,
                                   default = nil)
  if valid_21626305 != nil:
    section.add "Tags", valid_21626305
  var valid_21626306 = formData.getOrDefault("SolutionStackName")
  valid_21626306 = validateParameter(valid_21626306, JString, required = false,
                                   default = nil)
  if valid_21626306 != nil:
    section.add "SolutionStackName", valid_21626306
  var valid_21626307 = formData.getOrDefault("SourceConfiguration.ApplicationName")
  valid_21626307 = validateParameter(valid_21626307, JString, required = false,
                                   default = nil)
  if valid_21626307 != nil:
    section.add "SourceConfiguration.ApplicationName", valid_21626307
  var valid_21626308 = formData.getOrDefault("EnvironmentId")
  valid_21626308 = validateParameter(valid_21626308, JString, required = false,
                                   default = nil)
  if valid_21626308 != nil:
    section.add "EnvironmentId", valid_21626308
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_21626309 = formData.getOrDefault("ApplicationName")
  valid_21626309 = validateParameter(valid_21626309, JString, required = true,
                                   default = nil)
  if valid_21626309 != nil:
    section.add "ApplicationName", valid_21626309
  var valid_21626310 = formData.getOrDefault("PlatformArn")
  valid_21626310 = validateParameter(valid_21626310, JString, required = false,
                                   default = nil)
  if valid_21626310 != nil:
    section.add "PlatformArn", valid_21626310
  var valid_21626311 = formData.getOrDefault("TemplateName")
  valid_21626311 = validateParameter(valid_21626311, JString, required = true,
                                   default = nil)
  if valid_21626311 != nil:
    section.add "TemplateName", valid_21626311
  var valid_21626312 = formData.getOrDefault("Description")
  valid_21626312 = validateParameter(valid_21626312, JString, required = false,
                                   default = nil)
  if valid_21626312 != nil:
    section.add "Description", valid_21626312
  var valid_21626313 = formData.getOrDefault("SourceConfiguration.TemplateName")
  valid_21626313 = validateParameter(valid_21626313, JString, required = false,
                                   default = nil)
  if valid_21626313 != nil:
    section.add "SourceConfiguration.TemplateName", valid_21626313
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626314: Call_PostCreateConfigurationTemplate_21626292;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a configuration template. Templates are associated with a specific application and are used to deploy different versions of the application with the same configuration settings.</p> <p>Templates aren't associated with any environment. The <code>EnvironmentName</code> response element is always <code>null</code>.</p> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> <li> <p> <a>DescribeConfigurationSettings</a> </p> </li> <li> <p> <a>ListAvailableSolutionStacks</a> </p> </li> </ul>
  ## 
  let valid = call_21626314.validator(path, query, header, formData, body, _)
  let scheme = call_21626314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626314.makeUrl(scheme.get, call_21626314.host, call_21626314.base,
                               call_21626314.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626314, uri, valid, _)

proc call*(call_21626315: Call_PostCreateConfigurationTemplate_21626292;
          ApplicationName: string; TemplateName: string;
          OptionSettings: JsonNode = nil; Tags: JsonNode = nil;
          SolutionStackName: string = "";
          SourceConfigurationApplicationName: string = "";
          EnvironmentId: string = "";
          Action: string = "CreateConfigurationTemplate"; PlatformArn: string = "";
          Version: string = "2010-12-01"; Description: string = "";
          SourceConfigurationTemplateName: string = ""): Recallable =
  ## postCreateConfigurationTemplate
  ## <p>Creates a configuration template. Templates are associated with a specific application and are used to deploy different versions of the application with the same configuration settings.</p> <p>Templates aren't associated with any environment. The <code>EnvironmentName</code> response element is always <code>null</code>.</p> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> <li> <p> <a>DescribeConfigurationSettings</a> </p> </li> <li> <p> <a>ListAvailableSolutionStacks</a> </p> </li> </ul>
  ##   OptionSettings: JArray
  ##                 : If specified, AWS Elastic Beanstalk sets the specified configuration option to the requested value. The new value overrides the value obtained from the solution stack or the source configuration template.
  ##   Tags: JArray
  ##       : Specifies the tags applied to the configuration template.
  ##   SolutionStackName: string
  ##                    : <p>The name of the solution stack used by this configuration. The solution stack specifies the operating system, architecture, and application server for a configuration template. It determines the set of configuration options as well as the possible and default values.</p> <p> Use <a>ListAvailableSolutionStacks</a> to obtain a list of available solution stacks. </p> <p> A solution stack name or a source configuration parameter must be specified, otherwise AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. </p> <p>If a solution stack name is not specified and the source configuration parameter is specified, AWS Elastic Beanstalk uses the same solution stack as the source configuration template.</p>
  ##   SourceConfigurationApplicationName: string
  ##                                     : A specification for an environment configuration
  ## The name of the application associated with the configuration.
  ##   EnvironmentId: string
  ##                : The ID of the environment used with this configuration template.
  ##   Action: string (required)
  ##   ApplicationName: string (required)
  ##                  : The name of the application to associate with this configuration template. If no application is found with this name, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. 
  ##   PlatformArn: string
  ##              : The ARN of the custom platform.
  ##   TemplateName: string (required)
  ##               : <p>The name of the configuration template.</p> <p>Constraint: This name must be unique per application.</p> <p>Default: If a configuration template already exists with this name, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. </p>
  ##   Version: string (required)
  ##   Description: string
  ##              : Describes this configuration.
  ##   SourceConfigurationTemplateName: string
  ##                                  : A specification for an environment configuration
  ## The name of the configuration template.
  var query_21626316 = newJObject()
  var formData_21626317 = newJObject()
  if OptionSettings != nil:
    formData_21626317.add "OptionSettings", OptionSettings
  if Tags != nil:
    formData_21626317.add "Tags", Tags
  add(formData_21626317, "SolutionStackName", newJString(SolutionStackName))
  add(formData_21626317, "SourceConfiguration.ApplicationName",
      newJString(SourceConfigurationApplicationName))
  add(formData_21626317, "EnvironmentId", newJString(EnvironmentId))
  add(query_21626316, "Action", newJString(Action))
  add(formData_21626317, "ApplicationName", newJString(ApplicationName))
  add(formData_21626317, "PlatformArn", newJString(PlatformArn))
  add(formData_21626317, "TemplateName", newJString(TemplateName))
  add(query_21626316, "Version", newJString(Version))
  add(formData_21626317, "Description", newJString(Description))
  add(formData_21626317, "SourceConfiguration.TemplateName",
      newJString(SourceConfigurationTemplateName))
  result = call_21626315.call(nil, query_21626316, nil, formData_21626317, nil)

var postCreateConfigurationTemplate* = Call_PostCreateConfigurationTemplate_21626292(
    name: "postCreateConfigurationTemplate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateConfigurationTemplate",
    validator: validate_PostCreateConfigurationTemplate_21626293, base: "/",
    makeUrl: url_PostCreateConfigurationTemplate_21626294,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateConfigurationTemplate_21626267 = ref object of OpenApiRestCall_21625437
proc url_GetCreateConfigurationTemplate_21626269(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateConfigurationTemplate_21626268(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Creates a configuration template. Templates are associated with a specific application and are used to deploy different versions of the application with the same configuration settings.</p> <p>Templates aren't associated with any environment. The <code>EnvironmentName</code> response element is always <code>null</code>.</p> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> <li> <p> <a>DescribeConfigurationSettings</a> </p> </li> <li> <p> <a>ListAvailableSolutionStacks</a> </p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceConfiguration.ApplicationName: JString
  ##                                      : A specification for an environment configuration
  ## The name of the application associated with the configuration.
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to associate with this configuration template. If no application is found with this name, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. 
  ##   Description: JString
  ##              : Describes this configuration.
  ##   PlatformArn: JString
  ##              : The ARN of the custom platform.
  ##   Tags: JArray
  ##       : Specifies the tags applied to the configuration template.
  ##   Action: JString (required)
  ##   SolutionStackName: JString
  ##                    : <p>The name of the solution stack used by this configuration. The solution stack specifies the operating system, architecture, and application server for a configuration template. It determines the set of configuration options as well as the possible and default values.</p> <p> Use <a>ListAvailableSolutionStacks</a> to obtain a list of available solution stacks. </p> <p> A solution stack name or a source configuration parameter must be specified, otherwise AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. </p> <p>If a solution stack name is not specified and the source configuration parameter is specified, AWS Elastic Beanstalk uses the same solution stack as the source configuration template.</p>
  ##   EnvironmentId: JString
  ##                : The ID of the environment used with this configuration template.
  ##   TemplateName: JString (required)
  ##               : <p>The name of the configuration template.</p> <p>Constraint: This name must be unique per application.</p> <p>Default: If a configuration template already exists with this name, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. </p>
  ##   OptionSettings: JArray
  ##                 : If specified, AWS Elastic Beanstalk sets the specified configuration option to the requested value. The new value overrides the value obtained from the solution stack or the source configuration template.
  ##   Version: JString (required)
  ##   SourceConfiguration.TemplateName: JString
  ##                                   : A specification for an environment configuration
  ## The name of the configuration template.
  section = newJObject()
  var valid_21626270 = query.getOrDefault("SourceConfiguration.ApplicationName")
  valid_21626270 = validateParameter(valid_21626270, JString, required = false,
                                   default = nil)
  if valid_21626270 != nil:
    section.add "SourceConfiguration.ApplicationName", valid_21626270
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_21626271 = query.getOrDefault("ApplicationName")
  valid_21626271 = validateParameter(valid_21626271, JString, required = true,
                                   default = nil)
  if valid_21626271 != nil:
    section.add "ApplicationName", valid_21626271
  var valid_21626272 = query.getOrDefault("Description")
  valid_21626272 = validateParameter(valid_21626272, JString, required = false,
                                   default = nil)
  if valid_21626272 != nil:
    section.add "Description", valid_21626272
  var valid_21626273 = query.getOrDefault("PlatformArn")
  valid_21626273 = validateParameter(valid_21626273, JString, required = false,
                                   default = nil)
  if valid_21626273 != nil:
    section.add "PlatformArn", valid_21626273
  var valid_21626274 = query.getOrDefault("Tags")
  valid_21626274 = validateParameter(valid_21626274, JArray, required = false,
                                   default = nil)
  if valid_21626274 != nil:
    section.add "Tags", valid_21626274
  var valid_21626275 = query.getOrDefault("Action")
  valid_21626275 = validateParameter(valid_21626275, JString, required = true, default = newJString(
      "CreateConfigurationTemplate"))
  if valid_21626275 != nil:
    section.add "Action", valid_21626275
  var valid_21626276 = query.getOrDefault("SolutionStackName")
  valid_21626276 = validateParameter(valid_21626276, JString, required = false,
                                   default = nil)
  if valid_21626276 != nil:
    section.add "SolutionStackName", valid_21626276
  var valid_21626277 = query.getOrDefault("EnvironmentId")
  valid_21626277 = validateParameter(valid_21626277, JString, required = false,
                                   default = nil)
  if valid_21626277 != nil:
    section.add "EnvironmentId", valid_21626277
  var valid_21626278 = query.getOrDefault("TemplateName")
  valid_21626278 = validateParameter(valid_21626278, JString, required = true,
                                   default = nil)
  if valid_21626278 != nil:
    section.add "TemplateName", valid_21626278
  var valid_21626279 = query.getOrDefault("OptionSettings")
  valid_21626279 = validateParameter(valid_21626279, JArray, required = false,
                                   default = nil)
  if valid_21626279 != nil:
    section.add "OptionSettings", valid_21626279
  var valid_21626280 = query.getOrDefault("Version")
  valid_21626280 = validateParameter(valid_21626280, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626280 != nil:
    section.add "Version", valid_21626280
  var valid_21626281 = query.getOrDefault("SourceConfiguration.TemplateName")
  valid_21626281 = validateParameter(valid_21626281, JString, required = false,
                                   default = nil)
  if valid_21626281 != nil:
    section.add "SourceConfiguration.TemplateName", valid_21626281
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626282 = header.getOrDefault("X-Amz-Date")
  valid_21626282 = validateParameter(valid_21626282, JString, required = false,
                                   default = nil)
  if valid_21626282 != nil:
    section.add "X-Amz-Date", valid_21626282
  var valid_21626283 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626283 = validateParameter(valid_21626283, JString, required = false,
                                   default = nil)
  if valid_21626283 != nil:
    section.add "X-Amz-Security-Token", valid_21626283
  var valid_21626284 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626284 = validateParameter(valid_21626284, JString, required = false,
                                   default = nil)
  if valid_21626284 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626284
  var valid_21626285 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626285 = validateParameter(valid_21626285, JString, required = false,
                                   default = nil)
  if valid_21626285 != nil:
    section.add "X-Amz-Algorithm", valid_21626285
  var valid_21626286 = header.getOrDefault("X-Amz-Signature")
  valid_21626286 = validateParameter(valid_21626286, JString, required = false,
                                   default = nil)
  if valid_21626286 != nil:
    section.add "X-Amz-Signature", valid_21626286
  var valid_21626287 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626287 = validateParameter(valid_21626287, JString, required = false,
                                   default = nil)
  if valid_21626287 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626287
  var valid_21626288 = header.getOrDefault("X-Amz-Credential")
  valid_21626288 = validateParameter(valid_21626288, JString, required = false,
                                   default = nil)
  if valid_21626288 != nil:
    section.add "X-Amz-Credential", valid_21626288
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626289: Call_GetCreateConfigurationTemplate_21626267;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a configuration template. Templates are associated with a specific application and are used to deploy different versions of the application with the same configuration settings.</p> <p>Templates aren't associated with any environment. The <code>EnvironmentName</code> response element is always <code>null</code>.</p> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> <li> <p> <a>DescribeConfigurationSettings</a> </p> </li> <li> <p> <a>ListAvailableSolutionStacks</a> </p> </li> </ul>
  ## 
  let valid = call_21626289.validator(path, query, header, formData, body, _)
  let scheme = call_21626289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626289.makeUrl(scheme.get, call_21626289.host, call_21626289.base,
                               call_21626289.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626289, uri, valid, _)

proc call*(call_21626290: Call_GetCreateConfigurationTemplate_21626267;
          ApplicationName: string; TemplateName: string;
          SourceConfigurationApplicationName: string = ""; Description: string = "";
          PlatformArn: string = ""; Tags: JsonNode = nil;
          Action: string = "CreateConfigurationTemplate";
          SolutionStackName: string = ""; EnvironmentId: string = "";
          OptionSettings: JsonNode = nil; Version: string = "2010-12-01";
          SourceConfigurationTemplateName: string = ""): Recallable =
  ## getCreateConfigurationTemplate
  ## <p>Creates a configuration template. Templates are associated with a specific application and are used to deploy different versions of the application with the same configuration settings.</p> <p>Templates aren't associated with any environment. The <code>EnvironmentName</code> response element is always <code>null</code>.</p> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> <li> <p> <a>DescribeConfigurationSettings</a> </p> </li> <li> <p> <a>ListAvailableSolutionStacks</a> </p> </li> </ul>
  ##   SourceConfigurationApplicationName: string
  ##                                     : A specification for an environment configuration
  ## The name of the application associated with the configuration.
  ##   ApplicationName: string (required)
  ##                  : The name of the application to associate with this configuration template. If no application is found with this name, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. 
  ##   Description: string
  ##              : Describes this configuration.
  ##   PlatformArn: string
  ##              : The ARN of the custom platform.
  ##   Tags: JArray
  ##       : Specifies the tags applied to the configuration template.
  ##   Action: string (required)
  ##   SolutionStackName: string
  ##                    : <p>The name of the solution stack used by this configuration. The solution stack specifies the operating system, architecture, and application server for a configuration template. It determines the set of configuration options as well as the possible and default values.</p> <p> Use <a>ListAvailableSolutionStacks</a> to obtain a list of available solution stacks. </p> <p> A solution stack name or a source configuration parameter must be specified, otherwise AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. </p> <p>If a solution stack name is not specified and the source configuration parameter is specified, AWS Elastic Beanstalk uses the same solution stack as the source configuration template.</p>
  ##   EnvironmentId: string
  ##                : The ID of the environment used with this configuration template.
  ##   TemplateName: string (required)
  ##               : <p>The name of the configuration template.</p> <p>Constraint: This name must be unique per application.</p> <p>Default: If a configuration template already exists with this name, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. </p>
  ##   OptionSettings: JArray
  ##                 : If specified, AWS Elastic Beanstalk sets the specified configuration option to the requested value. The new value overrides the value obtained from the solution stack or the source configuration template.
  ##   Version: string (required)
  ##   SourceConfigurationTemplateName: string
  ##                                  : A specification for an environment configuration
  ## The name of the configuration template.
  var query_21626291 = newJObject()
  add(query_21626291, "SourceConfiguration.ApplicationName",
      newJString(SourceConfigurationApplicationName))
  add(query_21626291, "ApplicationName", newJString(ApplicationName))
  add(query_21626291, "Description", newJString(Description))
  add(query_21626291, "PlatformArn", newJString(PlatformArn))
  if Tags != nil:
    query_21626291.add "Tags", Tags
  add(query_21626291, "Action", newJString(Action))
  add(query_21626291, "SolutionStackName", newJString(SolutionStackName))
  add(query_21626291, "EnvironmentId", newJString(EnvironmentId))
  add(query_21626291, "TemplateName", newJString(TemplateName))
  if OptionSettings != nil:
    query_21626291.add "OptionSettings", OptionSettings
  add(query_21626291, "Version", newJString(Version))
  add(query_21626291, "SourceConfiguration.TemplateName",
      newJString(SourceConfigurationTemplateName))
  result = call_21626290.call(nil, query_21626291, nil, nil, nil)

var getCreateConfigurationTemplate* = Call_GetCreateConfigurationTemplate_21626267(
    name: "getCreateConfigurationTemplate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateConfigurationTemplate",
    validator: validate_GetCreateConfigurationTemplate_21626268, base: "/",
    makeUrl: url_GetCreateConfigurationTemplate_21626269,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEnvironment_21626348 = ref object of OpenApiRestCall_21625437
proc url_PostCreateEnvironment_21626350(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateEnvironment_21626349(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626351 = query.getOrDefault("Action")
  valid_21626351 = validateParameter(valid_21626351, JString, required = true,
                                   default = newJString("CreateEnvironment"))
  if valid_21626351 != nil:
    section.add "Action", valid_21626351
  var valid_21626352 = query.getOrDefault("Version")
  valid_21626352 = validateParameter(valid_21626352, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626352 != nil:
    section.add "Version", valid_21626352
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626353 = header.getOrDefault("X-Amz-Date")
  valid_21626353 = validateParameter(valid_21626353, JString, required = false,
                                   default = nil)
  if valid_21626353 != nil:
    section.add "X-Amz-Date", valid_21626353
  var valid_21626354 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626354 = validateParameter(valid_21626354, JString, required = false,
                                   default = nil)
  if valid_21626354 != nil:
    section.add "X-Amz-Security-Token", valid_21626354
  var valid_21626355 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626355 = validateParameter(valid_21626355, JString, required = false,
                                   default = nil)
  if valid_21626355 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626355
  var valid_21626356 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626356 = validateParameter(valid_21626356, JString, required = false,
                                   default = nil)
  if valid_21626356 != nil:
    section.add "X-Amz-Algorithm", valid_21626356
  var valid_21626357 = header.getOrDefault("X-Amz-Signature")
  valid_21626357 = validateParameter(valid_21626357, JString, required = false,
                                   default = nil)
  if valid_21626357 != nil:
    section.add "X-Amz-Signature", valid_21626357
  var valid_21626358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626358 = validateParameter(valid_21626358, JString, required = false,
                                   default = nil)
  if valid_21626358 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626358
  var valid_21626359 = header.getOrDefault("X-Amz-Credential")
  valid_21626359 = validateParameter(valid_21626359, JString, required = false,
                                   default = nil)
  if valid_21626359 != nil:
    section.add "X-Amz-Credential", valid_21626359
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tier.Name: JString
  ##            : Describes the properties of an environment tier
  ## <p>The name of this environment tier.</p> <p>Valid values:</p> <ul> <li> <p>For <i>Web server tier</i> – <code>WebServer</code> </p> </li> <li> <p>For <i>Worker tier</i> – <code>Worker</code> </p> </li> </ul>
  ##   OptionsToRemove: JArray
  ##                  : A list of custom user-defined configuration options to remove from the configuration set for this new environment.
  ##   VersionLabel: JString
  ##               : <p>The name of the application version to deploy.</p> <p> If the specified application has no associated application versions, AWS Elastic Beanstalk <code>UpdateEnvironment</code> returns an <code>InvalidParameterValue</code> error. </p> <p>Default: If not specified, AWS Elastic Beanstalk attempts to launch the sample application in the container.</p>
  ##   OptionSettings: JArray
  ##                 : If specified, AWS Elastic Beanstalk sets the specified configuration options to the requested value in the configuration set for the new environment. These override the values obtained from the solution stack or the configuration template.
  ##   GroupName: JString
  ##            : The name of the group to which the target environment belongs. Specify a group name only if the environment's name is specified in an environment manifest and not with the environment name parameter. See <a 
  ## href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-cfg-manifest.html">Environment Manifest (env.yaml)</a> for details.
  ##   Tags: JArray
  ##       : Specifies the tags applied to resources in the environment.
  ##   CNAMEPrefix: JString
  ##              : If specified, the environment attempts to use this value as the prefix for the CNAME. If not specified, the CNAME is generated automatically by appending a random alphanumeric string to the environment name.
  ##   SolutionStackName: JString
  ##                    : <p>This is an alternative to specifying a template name. If specified, AWS Elastic Beanstalk sets the configuration values to the default values associated with the specified solution stack.</p> <p>For a list of current solution stacks, see <a 
  ## href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/concepts.platforms.html">Elastic Beanstalk Supported Platforms</a>.</p>
  ##   EnvironmentName: JString
  ##                  : <p>A unique name for the deployment environment. Used in the application URL.</p> <p>Constraint: Must be from 4 to 40 characters in length. The name can contain only letters, numbers, and hyphens. It cannot start or end with a hyphen. This name must be unique within a region in your account. If the specified name already exists in the region, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. </p> <p>Default: If the CNAME parameter is not specified, the environment name becomes part of the CNAME, and therefore part of the visible URL for your application.</p>
  ##   Tier.Type: JString
  ##            : Describes the properties of an environment tier
  ## <p>The type of this environment tier.</p> <p>Valid values:</p> <ul> <li> <p>For <i>Web server tier</i> – <code>Standard</code> </p> </li> <li> <p>For <i>Worker tier</i> – <code>SQS/HTTP</code> </p> </li> </ul>
  ##   ApplicationName: JString (required)
  ##                  : <p>The name of the application that contains the version to be deployed.</p> <p> If no application is found with this name, <code>CreateEnvironment</code> returns an <code>InvalidParameterValue</code> error. </p>
  ##   PlatformArn: JString
  ##              : The ARN of the platform.
  ##   TemplateName: JString
  ##               :  The name of the configuration template to use in deployment. If no configuration template is found with this name, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. 
  ##   Description: JString
  ##              : Describes this environment.
  ##   Tier.Version: JString
  ##               : Describes the properties of an environment tier
  ## <p>The version of this environment tier. When you don't set a value to it, Elastic Beanstalk uses the latest compatible worker tier version.</p> <note> <p>This member is deprecated. Any specific version that you set may become out of date. We recommend leaving it unspecified.</p> </note>
  section = newJObject()
  var valid_21626360 = formData.getOrDefault("Tier.Name")
  valid_21626360 = validateParameter(valid_21626360, JString, required = false,
                                   default = nil)
  if valid_21626360 != nil:
    section.add "Tier.Name", valid_21626360
  var valid_21626361 = formData.getOrDefault("OptionsToRemove")
  valid_21626361 = validateParameter(valid_21626361, JArray, required = false,
                                   default = nil)
  if valid_21626361 != nil:
    section.add "OptionsToRemove", valid_21626361
  var valid_21626362 = formData.getOrDefault("VersionLabel")
  valid_21626362 = validateParameter(valid_21626362, JString, required = false,
                                   default = nil)
  if valid_21626362 != nil:
    section.add "VersionLabel", valid_21626362
  var valid_21626363 = formData.getOrDefault("OptionSettings")
  valid_21626363 = validateParameter(valid_21626363, JArray, required = false,
                                   default = nil)
  if valid_21626363 != nil:
    section.add "OptionSettings", valid_21626363
  var valid_21626364 = formData.getOrDefault("GroupName")
  valid_21626364 = validateParameter(valid_21626364, JString, required = false,
                                   default = nil)
  if valid_21626364 != nil:
    section.add "GroupName", valid_21626364
  var valid_21626365 = formData.getOrDefault("Tags")
  valid_21626365 = validateParameter(valid_21626365, JArray, required = false,
                                   default = nil)
  if valid_21626365 != nil:
    section.add "Tags", valid_21626365
  var valid_21626366 = formData.getOrDefault("CNAMEPrefix")
  valid_21626366 = validateParameter(valid_21626366, JString, required = false,
                                   default = nil)
  if valid_21626366 != nil:
    section.add "CNAMEPrefix", valid_21626366
  var valid_21626367 = formData.getOrDefault("SolutionStackName")
  valid_21626367 = validateParameter(valid_21626367, JString, required = false,
                                   default = nil)
  if valid_21626367 != nil:
    section.add "SolutionStackName", valid_21626367
  var valid_21626368 = formData.getOrDefault("EnvironmentName")
  valid_21626368 = validateParameter(valid_21626368, JString, required = false,
                                   default = nil)
  if valid_21626368 != nil:
    section.add "EnvironmentName", valid_21626368
  var valid_21626369 = formData.getOrDefault("Tier.Type")
  valid_21626369 = validateParameter(valid_21626369, JString, required = false,
                                   default = nil)
  if valid_21626369 != nil:
    section.add "Tier.Type", valid_21626369
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_21626370 = formData.getOrDefault("ApplicationName")
  valid_21626370 = validateParameter(valid_21626370, JString, required = true,
                                   default = nil)
  if valid_21626370 != nil:
    section.add "ApplicationName", valid_21626370
  var valid_21626371 = formData.getOrDefault("PlatformArn")
  valid_21626371 = validateParameter(valid_21626371, JString, required = false,
                                   default = nil)
  if valid_21626371 != nil:
    section.add "PlatformArn", valid_21626371
  var valid_21626372 = formData.getOrDefault("TemplateName")
  valid_21626372 = validateParameter(valid_21626372, JString, required = false,
                                   default = nil)
  if valid_21626372 != nil:
    section.add "TemplateName", valid_21626372
  var valid_21626373 = formData.getOrDefault("Description")
  valid_21626373 = validateParameter(valid_21626373, JString, required = false,
                                   default = nil)
  if valid_21626373 != nil:
    section.add "Description", valid_21626373
  var valid_21626374 = formData.getOrDefault("Tier.Version")
  valid_21626374 = validateParameter(valid_21626374, JString, required = false,
                                   default = nil)
  if valid_21626374 != nil:
    section.add "Tier.Version", valid_21626374
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626375: Call_PostCreateEnvironment_21626348;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Launches an environment for the specified application using the specified configuration.
  ## 
  let valid = call_21626375.validator(path, query, header, formData, body, _)
  let scheme = call_21626375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626375.makeUrl(scheme.get, call_21626375.host, call_21626375.base,
                               call_21626375.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626375, uri, valid, _)

proc call*(call_21626376: Call_PostCreateEnvironment_21626348;
          ApplicationName: string; TierName: string = "";
          OptionsToRemove: JsonNode = nil; VersionLabel: string = "";
          OptionSettings: JsonNode = nil; GroupName: string = ""; Tags: JsonNode = nil;
          CNAMEPrefix: string = ""; SolutionStackName: string = "";
          EnvironmentName: string = ""; TierType: string = "";
          Action: string = "CreateEnvironment"; PlatformArn: string = "";
          TemplateName: string = ""; Version: string = "2010-12-01";
          Description: string = ""; TierVersion: string = ""): Recallable =
  ## postCreateEnvironment
  ## Launches an environment for the specified application using the specified configuration.
  ##   TierName: string
  ##           : Describes the properties of an environment tier
  ## <p>The name of this environment tier.</p> <p>Valid values:</p> <ul> <li> <p>For <i>Web server tier</i> – <code>WebServer</code> </p> </li> <li> <p>For <i>Worker tier</i> – <code>Worker</code> </p> </li> </ul>
  ##   OptionsToRemove: JArray
  ##                  : A list of custom user-defined configuration options to remove from the configuration set for this new environment.
  ##   VersionLabel: string
  ##               : <p>The name of the application version to deploy.</p> <p> If the specified application has no associated application versions, AWS Elastic Beanstalk <code>UpdateEnvironment</code> returns an <code>InvalidParameterValue</code> error. </p> <p>Default: If not specified, AWS Elastic Beanstalk attempts to launch the sample application in the container.</p>
  ##   OptionSettings: JArray
  ##                 : If specified, AWS Elastic Beanstalk sets the specified configuration options to the requested value in the configuration set for the new environment. These override the values obtained from the solution stack or the configuration template.
  ##   GroupName: string
  ##            : The name of the group to which the target environment belongs. Specify a group name only if the environment's name is specified in an environment manifest and not with the environment name parameter. See <a 
  ## href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-cfg-manifest.html">Environment Manifest (env.yaml)</a> for details.
  ##   Tags: JArray
  ##       : Specifies the tags applied to resources in the environment.
  ##   CNAMEPrefix: string
  ##              : If specified, the environment attempts to use this value as the prefix for the CNAME. If not specified, the CNAME is generated automatically by appending a random alphanumeric string to the environment name.
  ##   SolutionStackName: string
  ##                    : <p>This is an alternative to specifying a template name. If specified, AWS Elastic Beanstalk sets the configuration values to the default values associated with the specified solution stack.</p> <p>For a list of current solution stacks, see <a 
  ## href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/concepts.platforms.html">Elastic Beanstalk Supported Platforms</a>.</p>
  ##   EnvironmentName: string
  ##                  : <p>A unique name for the deployment environment. Used in the application URL.</p> <p>Constraint: Must be from 4 to 40 characters in length. The name can contain only letters, numbers, and hyphens. It cannot start or end with a hyphen. This name must be unique within a region in your account. If the specified name already exists in the region, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. </p> <p>Default: If the CNAME parameter is not specified, the environment name becomes part of the CNAME, and therefore part of the visible URL for your application.</p>
  ##   TierType: string
  ##           : Describes the properties of an environment tier
  ## <p>The type of this environment tier.</p> <p>Valid values:</p> <ul> <li> <p>For <i>Web server tier</i> – <code>Standard</code> </p> </li> <li> <p>For <i>Worker tier</i> – <code>SQS/HTTP</code> </p> </li> </ul>
  ##   Action: string (required)
  ##   ApplicationName: string (required)
  ##                  : <p>The name of the application that contains the version to be deployed.</p> <p> If no application is found with this name, <code>CreateEnvironment</code> returns an <code>InvalidParameterValue</code> error. </p>
  ##   PlatformArn: string
  ##              : The ARN of the platform.
  ##   TemplateName: string
  ##               :  The name of the configuration template to use in deployment. If no configuration template is found with this name, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. 
  ##   Version: string (required)
  ##   Description: string
  ##              : Describes this environment.
  ##   TierVersion: string
  ##              : Describes the properties of an environment tier
  ## <p>The version of this environment tier. When you don't set a value to it, Elastic Beanstalk uses the latest compatible worker tier version.</p> <note> <p>This member is deprecated. Any specific version that you set may become out of date. We recommend leaving it unspecified.</p> </note>
  var query_21626377 = newJObject()
  var formData_21626378 = newJObject()
  add(formData_21626378, "Tier.Name", newJString(TierName))
  if OptionsToRemove != nil:
    formData_21626378.add "OptionsToRemove", OptionsToRemove
  add(formData_21626378, "VersionLabel", newJString(VersionLabel))
  if OptionSettings != nil:
    formData_21626378.add "OptionSettings", OptionSettings
  add(formData_21626378, "GroupName", newJString(GroupName))
  if Tags != nil:
    formData_21626378.add "Tags", Tags
  add(formData_21626378, "CNAMEPrefix", newJString(CNAMEPrefix))
  add(formData_21626378, "SolutionStackName", newJString(SolutionStackName))
  add(formData_21626378, "EnvironmentName", newJString(EnvironmentName))
  add(formData_21626378, "Tier.Type", newJString(TierType))
  add(query_21626377, "Action", newJString(Action))
  add(formData_21626378, "ApplicationName", newJString(ApplicationName))
  add(formData_21626378, "PlatformArn", newJString(PlatformArn))
  add(formData_21626378, "TemplateName", newJString(TemplateName))
  add(query_21626377, "Version", newJString(Version))
  add(formData_21626378, "Description", newJString(Description))
  add(formData_21626378, "Tier.Version", newJString(TierVersion))
  result = call_21626376.call(nil, query_21626377, nil, formData_21626378, nil)

var postCreateEnvironment* = Call_PostCreateEnvironment_21626348(
    name: "postCreateEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateEnvironment",
    validator: validate_PostCreateEnvironment_21626349, base: "/",
    makeUrl: url_PostCreateEnvironment_21626350,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEnvironment_21626318 = ref object of OpenApiRestCall_21625437
proc url_GetCreateEnvironment_21626320(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateEnvironment_21626319(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Launches an environment for the specified application using the specified configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tier.Name: JString
  ##            : Describes the properties of an environment tier
  ## <p>The name of this environment tier.</p> <p>Valid values:</p> <ul> <li> <p>For <i>Web server tier</i> – <code>WebServer</code> </p> </li> <li> <p>For <i>Worker tier</i> – <code>Worker</code> </p> </li> </ul>
  ##   VersionLabel: JString
  ##               : <p>The name of the application version to deploy.</p> <p> If the specified application has no associated application versions, AWS Elastic Beanstalk <code>UpdateEnvironment</code> returns an <code>InvalidParameterValue</code> error. </p> <p>Default: If not specified, AWS Elastic Beanstalk attempts to launch the sample application in the container.</p>
  ##   ApplicationName: JString (required)
  ##                  : <p>The name of the application that contains the version to be deployed.</p> <p> If no application is found with this name, <code>CreateEnvironment</code> returns an <code>InvalidParameterValue</code> error. </p>
  ##   Description: JString
  ##              : Describes this environment.
  ##   OptionsToRemove: JArray
  ##                  : A list of custom user-defined configuration options to remove from the configuration set for this new environment.
  ##   PlatformArn: JString
  ##              : The ARN of the platform.
  ##   Tags: JArray
  ##       : Specifies the tags applied to resources in the environment.
  ##   EnvironmentName: JString
  ##                  : <p>A unique name for the deployment environment. Used in the application URL.</p> <p>Constraint: Must be from 4 to 40 characters in length. The name can contain only letters, numbers, and hyphens. It cannot start or end with a hyphen. This name must be unique within a region in your account. If the specified name already exists in the region, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. </p> <p>Default: If the CNAME parameter is not specified, the environment name becomes part of the CNAME, and therefore part of the visible URL for your application.</p>
  ##   Action: JString (required)
  ##   SolutionStackName: JString
  ##                    : <p>This is an alternative to specifying a template name. If specified, AWS Elastic Beanstalk sets the configuration values to the default values associated with the specified solution stack.</p> <p>For a list of current solution stacks, see <a 
  ## href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/concepts.platforms.html">Elastic Beanstalk Supported Platforms</a>.</p>
  ##   Tier.Version: JString
  ##               : Describes the properties of an environment tier
  ## <p>The version of this environment tier. When you don't set a value to it, Elastic Beanstalk uses the latest compatible worker tier version.</p> <note> <p>This member is deprecated. Any specific version that you set may become out of date. We recommend leaving it unspecified.</p> </note>
  ##   TemplateName: JString
  ##               :  The name of the configuration template to use in deployment. If no configuration template is found with this name, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. 
  ##   GroupName: JString
  ##            : The name of the group to which the target environment belongs. Specify a group name only if the environment's name is specified in an environment manifest and not with the environment name parameter. See <a 
  ## href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-cfg-manifest.html">Environment Manifest (env.yaml)</a> for details.
  ##   OptionSettings: JArray
  ##                 : If specified, AWS Elastic Beanstalk sets the specified configuration options to the requested value in the configuration set for the new environment. These override the values obtained from the solution stack or the configuration template.
  ##   Tier.Type: JString
  ##            : Describes the properties of an environment tier
  ## <p>The type of this environment tier.</p> <p>Valid values:</p> <ul> <li> <p>For <i>Web server tier</i> – <code>Standard</code> </p> </li> <li> <p>For <i>Worker tier</i> – <code>SQS/HTTP</code> </p> </li> </ul>
  ##   Version: JString (required)
  ##   CNAMEPrefix: JString
  ##              : If specified, the environment attempts to use this value as the prefix for the CNAME. If not specified, the CNAME is generated automatically by appending a random alphanumeric string to the environment name.
  section = newJObject()
  var valid_21626321 = query.getOrDefault("Tier.Name")
  valid_21626321 = validateParameter(valid_21626321, JString, required = false,
                                   default = nil)
  if valid_21626321 != nil:
    section.add "Tier.Name", valid_21626321
  var valid_21626322 = query.getOrDefault("VersionLabel")
  valid_21626322 = validateParameter(valid_21626322, JString, required = false,
                                   default = nil)
  if valid_21626322 != nil:
    section.add "VersionLabel", valid_21626322
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_21626323 = query.getOrDefault("ApplicationName")
  valid_21626323 = validateParameter(valid_21626323, JString, required = true,
                                   default = nil)
  if valid_21626323 != nil:
    section.add "ApplicationName", valid_21626323
  var valid_21626324 = query.getOrDefault("Description")
  valid_21626324 = validateParameter(valid_21626324, JString, required = false,
                                   default = nil)
  if valid_21626324 != nil:
    section.add "Description", valid_21626324
  var valid_21626325 = query.getOrDefault("OptionsToRemove")
  valid_21626325 = validateParameter(valid_21626325, JArray, required = false,
                                   default = nil)
  if valid_21626325 != nil:
    section.add "OptionsToRemove", valid_21626325
  var valid_21626326 = query.getOrDefault("PlatformArn")
  valid_21626326 = validateParameter(valid_21626326, JString, required = false,
                                   default = nil)
  if valid_21626326 != nil:
    section.add "PlatformArn", valid_21626326
  var valid_21626327 = query.getOrDefault("Tags")
  valid_21626327 = validateParameter(valid_21626327, JArray, required = false,
                                   default = nil)
  if valid_21626327 != nil:
    section.add "Tags", valid_21626327
  var valid_21626328 = query.getOrDefault("EnvironmentName")
  valid_21626328 = validateParameter(valid_21626328, JString, required = false,
                                   default = nil)
  if valid_21626328 != nil:
    section.add "EnvironmentName", valid_21626328
  var valid_21626329 = query.getOrDefault("Action")
  valid_21626329 = validateParameter(valid_21626329, JString, required = true,
                                   default = newJString("CreateEnvironment"))
  if valid_21626329 != nil:
    section.add "Action", valid_21626329
  var valid_21626330 = query.getOrDefault("SolutionStackName")
  valid_21626330 = validateParameter(valid_21626330, JString, required = false,
                                   default = nil)
  if valid_21626330 != nil:
    section.add "SolutionStackName", valid_21626330
  var valid_21626331 = query.getOrDefault("Tier.Version")
  valid_21626331 = validateParameter(valid_21626331, JString, required = false,
                                   default = nil)
  if valid_21626331 != nil:
    section.add "Tier.Version", valid_21626331
  var valid_21626332 = query.getOrDefault("TemplateName")
  valid_21626332 = validateParameter(valid_21626332, JString, required = false,
                                   default = nil)
  if valid_21626332 != nil:
    section.add "TemplateName", valid_21626332
  var valid_21626333 = query.getOrDefault("GroupName")
  valid_21626333 = validateParameter(valid_21626333, JString, required = false,
                                   default = nil)
  if valid_21626333 != nil:
    section.add "GroupName", valid_21626333
  var valid_21626334 = query.getOrDefault("OptionSettings")
  valid_21626334 = validateParameter(valid_21626334, JArray, required = false,
                                   default = nil)
  if valid_21626334 != nil:
    section.add "OptionSettings", valid_21626334
  var valid_21626335 = query.getOrDefault("Tier.Type")
  valid_21626335 = validateParameter(valid_21626335, JString, required = false,
                                   default = nil)
  if valid_21626335 != nil:
    section.add "Tier.Type", valid_21626335
  var valid_21626336 = query.getOrDefault("Version")
  valid_21626336 = validateParameter(valid_21626336, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626336 != nil:
    section.add "Version", valid_21626336
  var valid_21626337 = query.getOrDefault("CNAMEPrefix")
  valid_21626337 = validateParameter(valid_21626337, JString, required = false,
                                   default = nil)
  if valid_21626337 != nil:
    section.add "CNAMEPrefix", valid_21626337
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626338 = header.getOrDefault("X-Amz-Date")
  valid_21626338 = validateParameter(valid_21626338, JString, required = false,
                                   default = nil)
  if valid_21626338 != nil:
    section.add "X-Amz-Date", valid_21626338
  var valid_21626339 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626339 = validateParameter(valid_21626339, JString, required = false,
                                   default = nil)
  if valid_21626339 != nil:
    section.add "X-Amz-Security-Token", valid_21626339
  var valid_21626340 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626340 = validateParameter(valid_21626340, JString, required = false,
                                   default = nil)
  if valid_21626340 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626340
  var valid_21626341 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626341 = validateParameter(valid_21626341, JString, required = false,
                                   default = nil)
  if valid_21626341 != nil:
    section.add "X-Amz-Algorithm", valid_21626341
  var valid_21626342 = header.getOrDefault("X-Amz-Signature")
  valid_21626342 = validateParameter(valid_21626342, JString, required = false,
                                   default = nil)
  if valid_21626342 != nil:
    section.add "X-Amz-Signature", valid_21626342
  var valid_21626343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626343 = validateParameter(valid_21626343, JString, required = false,
                                   default = nil)
  if valid_21626343 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626343
  var valid_21626344 = header.getOrDefault("X-Amz-Credential")
  valid_21626344 = validateParameter(valid_21626344, JString, required = false,
                                   default = nil)
  if valid_21626344 != nil:
    section.add "X-Amz-Credential", valid_21626344
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626345: Call_GetCreateEnvironment_21626318; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Launches an environment for the specified application using the specified configuration.
  ## 
  let valid = call_21626345.validator(path, query, header, formData, body, _)
  let scheme = call_21626345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626345.makeUrl(scheme.get, call_21626345.host, call_21626345.base,
                               call_21626345.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626345, uri, valid, _)

proc call*(call_21626346: Call_GetCreateEnvironment_21626318;
          ApplicationName: string; TierName: string = ""; VersionLabel: string = "";
          Description: string = ""; OptionsToRemove: JsonNode = nil;
          PlatformArn: string = ""; Tags: JsonNode = nil; EnvironmentName: string = "";
          Action: string = "CreateEnvironment"; SolutionStackName: string = "";
          TierVersion: string = ""; TemplateName: string = ""; GroupName: string = "";
          OptionSettings: JsonNode = nil; TierType: string = "";
          Version: string = "2010-12-01"; CNAMEPrefix: string = ""): Recallable =
  ## getCreateEnvironment
  ## Launches an environment for the specified application using the specified configuration.
  ##   TierName: string
  ##           : Describes the properties of an environment tier
  ## <p>The name of this environment tier.</p> <p>Valid values:</p> <ul> <li> <p>For <i>Web server tier</i> – <code>WebServer</code> </p> </li> <li> <p>For <i>Worker tier</i> – <code>Worker</code> </p> </li> </ul>
  ##   VersionLabel: string
  ##               : <p>The name of the application version to deploy.</p> <p> If the specified application has no associated application versions, AWS Elastic Beanstalk <code>UpdateEnvironment</code> returns an <code>InvalidParameterValue</code> error. </p> <p>Default: If not specified, AWS Elastic Beanstalk attempts to launch the sample application in the container.</p>
  ##   ApplicationName: string (required)
  ##                  : <p>The name of the application that contains the version to be deployed.</p> <p> If no application is found with this name, <code>CreateEnvironment</code> returns an <code>InvalidParameterValue</code> error. </p>
  ##   Description: string
  ##              : Describes this environment.
  ##   OptionsToRemove: JArray
  ##                  : A list of custom user-defined configuration options to remove from the configuration set for this new environment.
  ##   PlatformArn: string
  ##              : The ARN of the platform.
  ##   Tags: JArray
  ##       : Specifies the tags applied to resources in the environment.
  ##   EnvironmentName: string
  ##                  : <p>A unique name for the deployment environment. Used in the application URL.</p> <p>Constraint: Must be from 4 to 40 characters in length. The name can contain only letters, numbers, and hyphens. It cannot start or end with a hyphen. This name must be unique within a region in your account. If the specified name already exists in the region, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. </p> <p>Default: If the CNAME parameter is not specified, the environment name becomes part of the CNAME, and therefore part of the visible URL for your application.</p>
  ##   Action: string (required)
  ##   SolutionStackName: string
  ##                    : <p>This is an alternative to specifying a template name. If specified, AWS Elastic Beanstalk sets the configuration values to the default values associated with the specified solution stack.</p> <p>For a list of current solution stacks, see <a 
  ## href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/concepts.platforms.html">Elastic Beanstalk Supported Platforms</a>.</p>
  ##   TierVersion: string
  ##              : Describes the properties of an environment tier
  ## <p>The version of this environment tier. When you don't set a value to it, Elastic Beanstalk uses the latest compatible worker tier version.</p> <note> <p>This member is deprecated. Any specific version that you set may become out of date. We recommend leaving it unspecified.</p> </note>
  ##   TemplateName: string
  ##               :  The name of the configuration template to use in deployment. If no configuration template is found with this name, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. 
  ##   GroupName: string
  ##            : The name of the group to which the target environment belongs. Specify a group name only if the environment's name is specified in an environment manifest and not with the environment name parameter. See <a 
  ## href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-cfg-manifest.html">Environment Manifest (env.yaml)</a> for details.
  ##   OptionSettings: JArray
  ##                 : If specified, AWS Elastic Beanstalk sets the specified configuration options to the requested value in the configuration set for the new environment. These override the values obtained from the solution stack or the configuration template.
  ##   TierType: string
  ##           : Describes the properties of an environment tier
  ## <p>The type of this environment tier.</p> <p>Valid values:</p> <ul> <li> <p>For <i>Web server tier</i> – <code>Standard</code> </p> </li> <li> <p>For <i>Worker tier</i> – <code>SQS/HTTP</code> </p> </li> </ul>
  ##   Version: string (required)
  ##   CNAMEPrefix: string
  ##              : If specified, the environment attempts to use this value as the prefix for the CNAME. If not specified, the CNAME is generated automatically by appending a random alphanumeric string to the environment name.
  var query_21626347 = newJObject()
  add(query_21626347, "Tier.Name", newJString(TierName))
  add(query_21626347, "VersionLabel", newJString(VersionLabel))
  add(query_21626347, "ApplicationName", newJString(ApplicationName))
  add(query_21626347, "Description", newJString(Description))
  if OptionsToRemove != nil:
    query_21626347.add "OptionsToRemove", OptionsToRemove
  add(query_21626347, "PlatformArn", newJString(PlatformArn))
  if Tags != nil:
    query_21626347.add "Tags", Tags
  add(query_21626347, "EnvironmentName", newJString(EnvironmentName))
  add(query_21626347, "Action", newJString(Action))
  add(query_21626347, "SolutionStackName", newJString(SolutionStackName))
  add(query_21626347, "Tier.Version", newJString(TierVersion))
  add(query_21626347, "TemplateName", newJString(TemplateName))
  add(query_21626347, "GroupName", newJString(GroupName))
  if OptionSettings != nil:
    query_21626347.add "OptionSettings", OptionSettings
  add(query_21626347, "Tier.Type", newJString(TierType))
  add(query_21626347, "Version", newJString(Version))
  add(query_21626347, "CNAMEPrefix", newJString(CNAMEPrefix))
  result = call_21626346.call(nil, query_21626347, nil, nil, nil)

var getCreateEnvironment* = Call_GetCreateEnvironment_21626318(
    name: "getCreateEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateEnvironment",
    validator: validate_GetCreateEnvironment_21626319, base: "/",
    makeUrl: url_GetCreateEnvironment_21626320,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreatePlatformVersion_21626401 = ref object of OpenApiRestCall_21625437
proc url_PostCreatePlatformVersion_21626403(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreatePlatformVersion_21626402(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626404 = query.getOrDefault("Action")
  valid_21626404 = validateParameter(valid_21626404, JString, required = true, default = newJString(
      "CreatePlatformVersion"))
  if valid_21626404 != nil:
    section.add "Action", valid_21626404
  var valid_21626405 = query.getOrDefault("Version")
  valid_21626405 = validateParameter(valid_21626405, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626405 != nil:
    section.add "Version", valid_21626405
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626406 = header.getOrDefault("X-Amz-Date")
  valid_21626406 = validateParameter(valid_21626406, JString, required = false,
                                   default = nil)
  if valid_21626406 != nil:
    section.add "X-Amz-Date", valid_21626406
  var valid_21626407 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626407 = validateParameter(valid_21626407, JString, required = false,
                                   default = nil)
  if valid_21626407 != nil:
    section.add "X-Amz-Security-Token", valid_21626407
  var valid_21626408 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626408 = validateParameter(valid_21626408, JString, required = false,
                                   default = nil)
  if valid_21626408 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626408
  var valid_21626409 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626409 = validateParameter(valid_21626409, JString, required = false,
                                   default = nil)
  if valid_21626409 != nil:
    section.add "X-Amz-Algorithm", valid_21626409
  var valid_21626410 = header.getOrDefault("X-Amz-Signature")
  valid_21626410 = validateParameter(valid_21626410, JString, required = false,
                                   default = nil)
  if valid_21626410 != nil:
    section.add "X-Amz-Signature", valid_21626410
  var valid_21626411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626411 = validateParameter(valid_21626411, JString, required = false,
                                   default = nil)
  if valid_21626411 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626411
  var valid_21626412 = header.getOrDefault("X-Amz-Credential")
  valid_21626412 = validateParameter(valid_21626412, JString, required = false,
                                   default = nil)
  if valid_21626412 != nil:
    section.add "X-Amz-Credential", valid_21626412
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformName: JString (required)
  ##               : The name of your custom platform.
  ##   PlatformDefinitionBundle.S3Key: JString
  ##                                 : The bucket and key of an item stored in Amazon S3.
  ## The Amazon S3 key where the data is located.
  ##   OptionSettings: JArray
  ##                 : The configuration option settings to apply to the builder environment.
  ##   Tags: JArray
  ##       : <p>Specifies the tags applied to the new platform version.</p> <p>Elastic Beanstalk applies these tags only to the platform version. Environments that you create using the platform version don't inherit the tags.</p>
  ##   EnvironmentName: JString
  ##                  : The name of the builder environment.
  ##   PlatformDefinitionBundle.S3Bucket: JString
  ##                                    : The bucket and key of an item stored in Amazon S3.
  ## The Amazon S3 bucket where the data is located.
  ##   PlatformVersion: JString (required)
  ##                  : The number, such as 1.0.2, for the new platform version.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `PlatformName` field"
  var valid_21626413 = formData.getOrDefault("PlatformName")
  valid_21626413 = validateParameter(valid_21626413, JString, required = true,
                                   default = nil)
  if valid_21626413 != nil:
    section.add "PlatformName", valid_21626413
  var valid_21626414 = formData.getOrDefault("PlatformDefinitionBundle.S3Key")
  valid_21626414 = validateParameter(valid_21626414, JString, required = false,
                                   default = nil)
  if valid_21626414 != nil:
    section.add "PlatformDefinitionBundle.S3Key", valid_21626414
  var valid_21626415 = formData.getOrDefault("OptionSettings")
  valid_21626415 = validateParameter(valid_21626415, JArray, required = false,
                                   default = nil)
  if valid_21626415 != nil:
    section.add "OptionSettings", valid_21626415
  var valid_21626416 = formData.getOrDefault("Tags")
  valid_21626416 = validateParameter(valid_21626416, JArray, required = false,
                                   default = nil)
  if valid_21626416 != nil:
    section.add "Tags", valid_21626416
  var valid_21626417 = formData.getOrDefault("EnvironmentName")
  valid_21626417 = validateParameter(valid_21626417, JString, required = false,
                                   default = nil)
  if valid_21626417 != nil:
    section.add "EnvironmentName", valid_21626417
  var valid_21626418 = formData.getOrDefault("PlatformDefinitionBundle.S3Bucket")
  valid_21626418 = validateParameter(valid_21626418, JString, required = false,
                                   default = nil)
  if valid_21626418 != nil:
    section.add "PlatformDefinitionBundle.S3Bucket", valid_21626418
  var valid_21626419 = formData.getOrDefault("PlatformVersion")
  valid_21626419 = validateParameter(valid_21626419, JString, required = true,
                                   default = nil)
  if valid_21626419 != nil:
    section.add "PlatformVersion", valid_21626419
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626420: Call_PostCreatePlatformVersion_21626401;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Create a new version of your custom platform.
  ## 
  let valid = call_21626420.validator(path, query, header, formData, body, _)
  let scheme = call_21626420.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626420.makeUrl(scheme.get, call_21626420.host, call_21626420.base,
                               call_21626420.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626420, uri, valid, _)

proc call*(call_21626421: Call_PostCreatePlatformVersion_21626401;
          PlatformName: string; PlatformVersion: string;
          PlatformDefinitionBundleS3Key: string = "";
          OptionSettings: JsonNode = nil; Tags: JsonNode = nil;
          EnvironmentName: string = "";
          PlatformDefinitionBundleS3Bucket: string = "";
          Action: string = "CreatePlatformVersion"; Version: string = "2010-12-01"): Recallable =
  ## postCreatePlatformVersion
  ## Create a new version of your custom platform.
  ##   PlatformName: string (required)
  ##               : The name of your custom platform.
  ##   PlatformDefinitionBundleS3Key: string
  ##                                : The bucket and key of an item stored in Amazon S3.
  ## The Amazon S3 key where the data is located.
  ##   OptionSettings: JArray
  ##                 : The configuration option settings to apply to the builder environment.
  ##   Tags: JArray
  ##       : <p>Specifies the tags applied to the new platform version.</p> <p>Elastic Beanstalk applies these tags only to the platform version. Environments that you create using the platform version don't inherit the tags.</p>
  ##   EnvironmentName: string
  ##                  : The name of the builder environment.
  ##   PlatformDefinitionBundleS3Bucket: string
  ##                                   : The bucket and key of an item stored in Amazon S3.
  ## The Amazon S3 bucket where the data is located.
  ##   Action: string (required)
  ##   PlatformVersion: string (required)
  ##                  : The number, such as 1.0.2, for the new platform version.
  ##   Version: string (required)
  var query_21626422 = newJObject()
  var formData_21626423 = newJObject()
  add(formData_21626423, "PlatformName", newJString(PlatformName))
  add(formData_21626423, "PlatformDefinitionBundle.S3Key",
      newJString(PlatformDefinitionBundleS3Key))
  if OptionSettings != nil:
    formData_21626423.add "OptionSettings", OptionSettings
  if Tags != nil:
    formData_21626423.add "Tags", Tags
  add(formData_21626423, "EnvironmentName", newJString(EnvironmentName))
  add(formData_21626423, "PlatformDefinitionBundle.S3Bucket",
      newJString(PlatformDefinitionBundleS3Bucket))
  add(query_21626422, "Action", newJString(Action))
  add(formData_21626423, "PlatformVersion", newJString(PlatformVersion))
  add(query_21626422, "Version", newJString(Version))
  result = call_21626421.call(nil, query_21626422, nil, formData_21626423, nil)

var postCreatePlatformVersion* = Call_PostCreatePlatformVersion_21626401(
    name: "postCreatePlatformVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreatePlatformVersion",
    validator: validate_PostCreatePlatformVersion_21626402, base: "/",
    makeUrl: url_PostCreatePlatformVersion_21626403,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreatePlatformVersion_21626379 = ref object of OpenApiRestCall_21625437
proc url_GetCreatePlatformVersion_21626381(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreatePlatformVersion_21626380(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Create a new version of your custom platform.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray
  ##       : <p>Specifies the tags applied to the new platform version.</p> <p>Elastic Beanstalk applies these tags only to the platform version. Environments that you create using the platform version don't inherit the tags.</p>
  ##   EnvironmentName: JString
  ##                  : The name of the builder environment.
  ##   PlatformDefinitionBundle.S3Key: JString
  ##                                 : The bucket and key of an item stored in Amazon S3.
  ## The Amazon S3 key where the data is located.
  ##   Action: JString (required)
  ##   OptionSettings: JArray
  ##                 : The configuration option settings to apply to the builder environment.
  ##   PlatformName: JString (required)
  ##               : The name of your custom platform.
  ##   Version: JString (required)
  ##   PlatformDefinitionBundle.S3Bucket: JString
  ##                                    : The bucket and key of an item stored in Amazon S3.
  ## The Amazon S3 bucket where the data is located.
  ##   PlatformVersion: JString (required)
  ##                  : The number, such as 1.0.2, for the new platform version.
  section = newJObject()
  var valid_21626382 = query.getOrDefault("Tags")
  valid_21626382 = validateParameter(valid_21626382, JArray, required = false,
                                   default = nil)
  if valid_21626382 != nil:
    section.add "Tags", valid_21626382
  var valid_21626383 = query.getOrDefault("EnvironmentName")
  valid_21626383 = validateParameter(valid_21626383, JString, required = false,
                                   default = nil)
  if valid_21626383 != nil:
    section.add "EnvironmentName", valid_21626383
  var valid_21626384 = query.getOrDefault("PlatformDefinitionBundle.S3Key")
  valid_21626384 = validateParameter(valid_21626384, JString, required = false,
                                   default = nil)
  if valid_21626384 != nil:
    section.add "PlatformDefinitionBundle.S3Key", valid_21626384
  var valid_21626385 = query.getOrDefault("Action")
  valid_21626385 = validateParameter(valid_21626385, JString, required = true, default = newJString(
      "CreatePlatformVersion"))
  if valid_21626385 != nil:
    section.add "Action", valid_21626385
  var valid_21626386 = query.getOrDefault("OptionSettings")
  valid_21626386 = validateParameter(valid_21626386, JArray, required = false,
                                   default = nil)
  if valid_21626386 != nil:
    section.add "OptionSettings", valid_21626386
  var valid_21626387 = query.getOrDefault("PlatformName")
  valid_21626387 = validateParameter(valid_21626387, JString, required = true,
                                   default = nil)
  if valid_21626387 != nil:
    section.add "PlatformName", valid_21626387
  var valid_21626388 = query.getOrDefault("Version")
  valid_21626388 = validateParameter(valid_21626388, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626388 != nil:
    section.add "Version", valid_21626388
  var valid_21626389 = query.getOrDefault("PlatformDefinitionBundle.S3Bucket")
  valid_21626389 = validateParameter(valid_21626389, JString, required = false,
                                   default = nil)
  if valid_21626389 != nil:
    section.add "PlatformDefinitionBundle.S3Bucket", valid_21626389
  var valid_21626390 = query.getOrDefault("PlatformVersion")
  valid_21626390 = validateParameter(valid_21626390, JString, required = true,
                                   default = nil)
  if valid_21626390 != nil:
    section.add "PlatformVersion", valid_21626390
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626391 = header.getOrDefault("X-Amz-Date")
  valid_21626391 = validateParameter(valid_21626391, JString, required = false,
                                   default = nil)
  if valid_21626391 != nil:
    section.add "X-Amz-Date", valid_21626391
  var valid_21626392 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626392 = validateParameter(valid_21626392, JString, required = false,
                                   default = nil)
  if valid_21626392 != nil:
    section.add "X-Amz-Security-Token", valid_21626392
  var valid_21626393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626393 = validateParameter(valid_21626393, JString, required = false,
                                   default = nil)
  if valid_21626393 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626393
  var valid_21626394 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626394 = validateParameter(valid_21626394, JString, required = false,
                                   default = nil)
  if valid_21626394 != nil:
    section.add "X-Amz-Algorithm", valid_21626394
  var valid_21626395 = header.getOrDefault("X-Amz-Signature")
  valid_21626395 = validateParameter(valid_21626395, JString, required = false,
                                   default = nil)
  if valid_21626395 != nil:
    section.add "X-Amz-Signature", valid_21626395
  var valid_21626396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626396 = validateParameter(valid_21626396, JString, required = false,
                                   default = nil)
  if valid_21626396 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626396
  var valid_21626397 = header.getOrDefault("X-Amz-Credential")
  valid_21626397 = validateParameter(valid_21626397, JString, required = false,
                                   default = nil)
  if valid_21626397 != nil:
    section.add "X-Amz-Credential", valid_21626397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626398: Call_GetCreatePlatformVersion_21626379;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Create a new version of your custom platform.
  ## 
  let valid = call_21626398.validator(path, query, header, formData, body, _)
  let scheme = call_21626398.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626398.makeUrl(scheme.get, call_21626398.host, call_21626398.base,
                               call_21626398.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626398, uri, valid, _)

proc call*(call_21626399: Call_GetCreatePlatformVersion_21626379;
          PlatformName: string; PlatformVersion: string; Tags: JsonNode = nil;
          EnvironmentName: string = ""; PlatformDefinitionBundleS3Key: string = "";
          Action: string = "CreatePlatformVersion"; OptionSettings: JsonNode = nil;
          Version: string = "2010-12-01";
          PlatformDefinitionBundleS3Bucket: string = ""): Recallable =
  ## getCreatePlatformVersion
  ## Create a new version of your custom platform.
  ##   Tags: JArray
  ##       : <p>Specifies the tags applied to the new platform version.</p> <p>Elastic Beanstalk applies these tags only to the platform version. Environments that you create using the platform version don't inherit the tags.</p>
  ##   EnvironmentName: string
  ##                  : The name of the builder environment.
  ##   PlatformDefinitionBundleS3Key: string
  ##                                : The bucket and key of an item stored in Amazon S3.
  ## The Amazon S3 key where the data is located.
  ##   Action: string (required)
  ##   OptionSettings: JArray
  ##                 : The configuration option settings to apply to the builder environment.
  ##   PlatformName: string (required)
  ##               : The name of your custom platform.
  ##   Version: string (required)
  ##   PlatformDefinitionBundleS3Bucket: string
  ##                                   : The bucket and key of an item stored in Amazon S3.
  ## The Amazon S3 bucket where the data is located.
  ##   PlatformVersion: string (required)
  ##                  : The number, such as 1.0.2, for the new platform version.
  var query_21626400 = newJObject()
  if Tags != nil:
    query_21626400.add "Tags", Tags
  add(query_21626400, "EnvironmentName", newJString(EnvironmentName))
  add(query_21626400, "PlatformDefinitionBundle.S3Key",
      newJString(PlatformDefinitionBundleS3Key))
  add(query_21626400, "Action", newJString(Action))
  if OptionSettings != nil:
    query_21626400.add "OptionSettings", OptionSettings
  add(query_21626400, "PlatformName", newJString(PlatformName))
  add(query_21626400, "Version", newJString(Version))
  add(query_21626400, "PlatformDefinitionBundle.S3Bucket",
      newJString(PlatformDefinitionBundleS3Bucket))
  add(query_21626400, "PlatformVersion", newJString(PlatformVersion))
  result = call_21626399.call(nil, query_21626400, nil, nil, nil)

var getCreatePlatformVersion* = Call_GetCreatePlatformVersion_21626379(
    name: "getCreatePlatformVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreatePlatformVersion",
    validator: validate_GetCreatePlatformVersion_21626380, base: "/",
    makeUrl: url_GetCreatePlatformVersion_21626381,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateStorageLocation_21626439 = ref object of OpenApiRestCall_21625437
proc url_PostCreateStorageLocation_21626441(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateStorageLocation_21626440(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626442 = query.getOrDefault("Action")
  valid_21626442 = validateParameter(valid_21626442, JString, required = true, default = newJString(
      "CreateStorageLocation"))
  if valid_21626442 != nil:
    section.add "Action", valid_21626442
  var valid_21626443 = query.getOrDefault("Version")
  valid_21626443 = validateParameter(valid_21626443, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626443 != nil:
    section.add "Version", valid_21626443
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626444 = header.getOrDefault("X-Amz-Date")
  valid_21626444 = validateParameter(valid_21626444, JString, required = false,
                                   default = nil)
  if valid_21626444 != nil:
    section.add "X-Amz-Date", valid_21626444
  var valid_21626445 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626445 = validateParameter(valid_21626445, JString, required = false,
                                   default = nil)
  if valid_21626445 != nil:
    section.add "X-Amz-Security-Token", valid_21626445
  var valid_21626446 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626446 = validateParameter(valid_21626446, JString, required = false,
                                   default = nil)
  if valid_21626446 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626446
  var valid_21626447 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626447 = validateParameter(valid_21626447, JString, required = false,
                                   default = nil)
  if valid_21626447 != nil:
    section.add "X-Amz-Algorithm", valid_21626447
  var valid_21626448 = header.getOrDefault("X-Amz-Signature")
  valid_21626448 = validateParameter(valid_21626448, JString, required = false,
                                   default = nil)
  if valid_21626448 != nil:
    section.add "X-Amz-Signature", valid_21626448
  var valid_21626449 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626449 = validateParameter(valid_21626449, JString, required = false,
                                   default = nil)
  if valid_21626449 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626449
  var valid_21626450 = header.getOrDefault("X-Amz-Credential")
  valid_21626450 = validateParameter(valid_21626450, JString, required = false,
                                   default = nil)
  if valid_21626450 != nil:
    section.add "X-Amz-Credential", valid_21626450
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626451: Call_PostCreateStorageLocation_21626439;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ## 
  let valid = call_21626451.validator(path, query, header, formData, body, _)
  let scheme = call_21626451.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626451.makeUrl(scheme.get, call_21626451.host, call_21626451.base,
                               call_21626451.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626451, uri, valid, _)

proc call*(call_21626452: Call_PostCreateStorageLocation_21626439;
          Action: string = "CreateStorageLocation"; Version: string = "2010-12-01"): Recallable =
  ## postCreateStorageLocation
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626453 = newJObject()
  add(query_21626453, "Action", newJString(Action))
  add(query_21626453, "Version", newJString(Version))
  result = call_21626452.call(nil, query_21626453, nil, nil, nil)

var postCreateStorageLocation* = Call_PostCreateStorageLocation_21626439(
    name: "postCreateStorageLocation", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateStorageLocation",
    validator: validate_PostCreateStorageLocation_21626440, base: "/",
    makeUrl: url_PostCreateStorageLocation_21626441,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateStorageLocation_21626424 = ref object of OpenApiRestCall_21625437
proc url_GetCreateStorageLocation_21626426(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateStorageLocation_21626425(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626427 = query.getOrDefault("Action")
  valid_21626427 = validateParameter(valid_21626427, JString, required = true, default = newJString(
      "CreateStorageLocation"))
  if valid_21626427 != nil:
    section.add "Action", valid_21626427
  var valid_21626428 = query.getOrDefault("Version")
  valid_21626428 = validateParameter(valid_21626428, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626428 != nil:
    section.add "Version", valid_21626428
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626429 = header.getOrDefault("X-Amz-Date")
  valid_21626429 = validateParameter(valid_21626429, JString, required = false,
                                   default = nil)
  if valid_21626429 != nil:
    section.add "X-Amz-Date", valid_21626429
  var valid_21626430 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626430 = validateParameter(valid_21626430, JString, required = false,
                                   default = nil)
  if valid_21626430 != nil:
    section.add "X-Amz-Security-Token", valid_21626430
  var valid_21626431 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626431 = validateParameter(valid_21626431, JString, required = false,
                                   default = nil)
  if valid_21626431 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626431
  var valid_21626432 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626432 = validateParameter(valid_21626432, JString, required = false,
                                   default = nil)
  if valid_21626432 != nil:
    section.add "X-Amz-Algorithm", valid_21626432
  var valid_21626433 = header.getOrDefault("X-Amz-Signature")
  valid_21626433 = validateParameter(valid_21626433, JString, required = false,
                                   default = nil)
  if valid_21626433 != nil:
    section.add "X-Amz-Signature", valid_21626433
  var valid_21626434 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626434 = validateParameter(valid_21626434, JString, required = false,
                                   default = nil)
  if valid_21626434 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626434
  var valid_21626435 = header.getOrDefault("X-Amz-Credential")
  valid_21626435 = validateParameter(valid_21626435, JString, required = false,
                                   default = nil)
  if valid_21626435 != nil:
    section.add "X-Amz-Credential", valid_21626435
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626436: Call_GetCreateStorageLocation_21626424;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ## 
  let valid = call_21626436.validator(path, query, header, formData, body, _)
  let scheme = call_21626436.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626436.makeUrl(scheme.get, call_21626436.host, call_21626436.base,
                               call_21626436.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626436, uri, valid, _)

proc call*(call_21626437: Call_GetCreateStorageLocation_21626424;
          Action: string = "CreateStorageLocation"; Version: string = "2010-12-01"): Recallable =
  ## getCreateStorageLocation
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626438 = newJObject()
  add(query_21626438, "Action", newJString(Action))
  add(query_21626438, "Version", newJString(Version))
  result = call_21626437.call(nil, query_21626438, nil, nil, nil)

var getCreateStorageLocation* = Call_GetCreateStorageLocation_21626424(
    name: "getCreateStorageLocation", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateStorageLocation",
    validator: validate_GetCreateStorageLocation_21626425, base: "/",
    makeUrl: url_GetCreateStorageLocation_21626426,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteApplication_21626471 = ref object of OpenApiRestCall_21625437
proc url_PostDeleteApplication_21626473(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteApplication_21626472(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626474 = query.getOrDefault("Action")
  valid_21626474 = validateParameter(valid_21626474, JString, required = true,
                                   default = newJString("DeleteApplication"))
  if valid_21626474 != nil:
    section.add "Action", valid_21626474
  var valid_21626475 = query.getOrDefault("Version")
  valid_21626475 = validateParameter(valid_21626475, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626475 != nil:
    section.add "Version", valid_21626475
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626476 = header.getOrDefault("X-Amz-Date")
  valid_21626476 = validateParameter(valid_21626476, JString, required = false,
                                   default = nil)
  if valid_21626476 != nil:
    section.add "X-Amz-Date", valid_21626476
  var valid_21626477 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626477 = validateParameter(valid_21626477, JString, required = false,
                                   default = nil)
  if valid_21626477 != nil:
    section.add "X-Amz-Security-Token", valid_21626477
  var valid_21626478 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626478 = validateParameter(valid_21626478, JString, required = false,
                                   default = nil)
  if valid_21626478 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626478
  var valid_21626479 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626479 = validateParameter(valid_21626479, JString, required = false,
                                   default = nil)
  if valid_21626479 != nil:
    section.add "X-Amz-Algorithm", valid_21626479
  var valid_21626480 = header.getOrDefault("X-Amz-Signature")
  valid_21626480 = validateParameter(valid_21626480, JString, required = false,
                                   default = nil)
  if valid_21626480 != nil:
    section.add "X-Amz-Signature", valid_21626480
  var valid_21626481 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626481 = validateParameter(valid_21626481, JString, required = false,
                                   default = nil)
  if valid_21626481 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626481
  var valid_21626482 = header.getOrDefault("X-Amz-Credential")
  valid_21626482 = validateParameter(valid_21626482, JString, required = false,
                                   default = nil)
  if valid_21626482 != nil:
    section.add "X-Amz-Credential", valid_21626482
  result.add "header", section
  ## parameters in `formData` object:
  ##   TerminateEnvByForce: JBool
  ##                      : When set to true, running environments will be terminated before deleting the application.
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to delete.
  section = newJObject()
  var valid_21626483 = formData.getOrDefault("TerminateEnvByForce")
  valid_21626483 = validateParameter(valid_21626483, JBool, required = false,
                                   default = nil)
  if valid_21626483 != nil:
    section.add "TerminateEnvByForce", valid_21626483
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_21626484 = formData.getOrDefault("ApplicationName")
  valid_21626484 = validateParameter(valid_21626484, JString, required = true,
                                   default = nil)
  if valid_21626484 != nil:
    section.add "ApplicationName", valid_21626484
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626485: Call_PostDeleteApplication_21626471;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified application along with all associated versions and configurations. The application versions will not be deleted from your Amazon S3 bucket.</p> <note> <p>You cannot delete an application that has a running environment.</p> </note>
  ## 
  let valid = call_21626485.validator(path, query, header, formData, body, _)
  let scheme = call_21626485.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626485.makeUrl(scheme.get, call_21626485.host, call_21626485.base,
                               call_21626485.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626485, uri, valid, _)

proc call*(call_21626486: Call_PostDeleteApplication_21626471;
          ApplicationName: string; TerminateEnvByForce: bool = false;
          Action: string = "DeleteApplication"; Version: string = "2010-12-01"): Recallable =
  ## postDeleteApplication
  ## <p>Deletes the specified application along with all associated versions and configurations. The application versions will not be deleted from your Amazon S3 bucket.</p> <note> <p>You cannot delete an application that has a running environment.</p> </note>
  ##   TerminateEnvByForce: bool
  ##                      : When set to true, running environments will be terminated before deleting the application.
  ##   Action: string (required)
  ##   ApplicationName: string (required)
  ##                  : The name of the application to delete.
  ##   Version: string (required)
  var query_21626487 = newJObject()
  var formData_21626488 = newJObject()
  add(formData_21626488, "TerminateEnvByForce", newJBool(TerminateEnvByForce))
  add(query_21626487, "Action", newJString(Action))
  add(formData_21626488, "ApplicationName", newJString(ApplicationName))
  add(query_21626487, "Version", newJString(Version))
  result = call_21626486.call(nil, query_21626487, nil, formData_21626488, nil)

var postDeleteApplication* = Call_PostDeleteApplication_21626471(
    name: "postDeleteApplication", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=DeleteApplication",
    validator: validate_PostDeleteApplication_21626472, base: "/",
    makeUrl: url_PostDeleteApplication_21626473,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteApplication_21626454 = ref object of OpenApiRestCall_21625437
proc url_GetDeleteApplication_21626456(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteApplication_21626455(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deletes the specified application along with all associated versions and configurations. The application versions will not be deleted from your Amazon S3 bucket.</p> <note> <p>You cannot delete an application that has a running environment.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   TerminateEnvByForce: JBool
  ##                      : When set to true, running environments will be terminated before deleting the application.
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to delete.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626457 = query.getOrDefault("TerminateEnvByForce")
  valid_21626457 = validateParameter(valid_21626457, JBool, required = false,
                                   default = nil)
  if valid_21626457 != nil:
    section.add "TerminateEnvByForce", valid_21626457
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_21626458 = query.getOrDefault("ApplicationName")
  valid_21626458 = validateParameter(valid_21626458, JString, required = true,
                                   default = nil)
  if valid_21626458 != nil:
    section.add "ApplicationName", valid_21626458
  var valid_21626459 = query.getOrDefault("Action")
  valid_21626459 = validateParameter(valid_21626459, JString, required = true,
                                   default = newJString("DeleteApplication"))
  if valid_21626459 != nil:
    section.add "Action", valid_21626459
  var valid_21626460 = query.getOrDefault("Version")
  valid_21626460 = validateParameter(valid_21626460, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626460 != nil:
    section.add "Version", valid_21626460
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626461 = header.getOrDefault("X-Amz-Date")
  valid_21626461 = validateParameter(valid_21626461, JString, required = false,
                                   default = nil)
  if valid_21626461 != nil:
    section.add "X-Amz-Date", valid_21626461
  var valid_21626462 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626462 = validateParameter(valid_21626462, JString, required = false,
                                   default = nil)
  if valid_21626462 != nil:
    section.add "X-Amz-Security-Token", valid_21626462
  var valid_21626463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626463 = validateParameter(valid_21626463, JString, required = false,
                                   default = nil)
  if valid_21626463 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626463
  var valid_21626464 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626464 = validateParameter(valid_21626464, JString, required = false,
                                   default = nil)
  if valid_21626464 != nil:
    section.add "X-Amz-Algorithm", valid_21626464
  var valid_21626465 = header.getOrDefault("X-Amz-Signature")
  valid_21626465 = validateParameter(valid_21626465, JString, required = false,
                                   default = nil)
  if valid_21626465 != nil:
    section.add "X-Amz-Signature", valid_21626465
  var valid_21626466 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626466 = validateParameter(valid_21626466, JString, required = false,
                                   default = nil)
  if valid_21626466 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626466
  var valid_21626467 = header.getOrDefault("X-Amz-Credential")
  valid_21626467 = validateParameter(valid_21626467, JString, required = false,
                                   default = nil)
  if valid_21626467 != nil:
    section.add "X-Amz-Credential", valid_21626467
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626468: Call_GetDeleteApplication_21626454; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified application along with all associated versions and configurations. The application versions will not be deleted from your Amazon S3 bucket.</p> <note> <p>You cannot delete an application that has a running environment.</p> </note>
  ## 
  let valid = call_21626468.validator(path, query, header, formData, body, _)
  let scheme = call_21626468.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626468.makeUrl(scheme.get, call_21626468.host, call_21626468.base,
                               call_21626468.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626468, uri, valid, _)

proc call*(call_21626469: Call_GetDeleteApplication_21626454;
          ApplicationName: string; TerminateEnvByForce: bool = false;
          Action: string = "DeleteApplication"; Version: string = "2010-12-01"): Recallable =
  ## getDeleteApplication
  ## <p>Deletes the specified application along with all associated versions and configurations. The application versions will not be deleted from your Amazon S3 bucket.</p> <note> <p>You cannot delete an application that has a running environment.</p> </note>
  ##   TerminateEnvByForce: bool
  ##                      : When set to true, running environments will be terminated before deleting the application.
  ##   ApplicationName: string (required)
  ##                  : The name of the application to delete.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626470 = newJObject()
  add(query_21626470, "TerminateEnvByForce", newJBool(TerminateEnvByForce))
  add(query_21626470, "ApplicationName", newJString(ApplicationName))
  add(query_21626470, "Action", newJString(Action))
  add(query_21626470, "Version", newJString(Version))
  result = call_21626469.call(nil, query_21626470, nil, nil, nil)

var getDeleteApplication* = Call_GetDeleteApplication_21626454(
    name: "getDeleteApplication", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=DeleteApplication",
    validator: validate_GetDeleteApplication_21626455, base: "/",
    makeUrl: url_GetDeleteApplication_21626456,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteApplicationVersion_21626507 = ref object of OpenApiRestCall_21625437
proc url_PostDeleteApplicationVersion_21626509(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteApplicationVersion_21626508(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626510 = query.getOrDefault("Action")
  valid_21626510 = validateParameter(valid_21626510, JString, required = true, default = newJString(
      "DeleteApplicationVersion"))
  if valid_21626510 != nil:
    section.add "Action", valid_21626510
  var valid_21626511 = query.getOrDefault("Version")
  valid_21626511 = validateParameter(valid_21626511, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626511 != nil:
    section.add "Version", valid_21626511
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626512 = header.getOrDefault("X-Amz-Date")
  valid_21626512 = validateParameter(valid_21626512, JString, required = false,
                                   default = nil)
  if valid_21626512 != nil:
    section.add "X-Amz-Date", valid_21626512
  var valid_21626513 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626513 = validateParameter(valid_21626513, JString, required = false,
                                   default = nil)
  if valid_21626513 != nil:
    section.add "X-Amz-Security-Token", valid_21626513
  var valid_21626514 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626514 = validateParameter(valid_21626514, JString, required = false,
                                   default = nil)
  if valid_21626514 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626514
  var valid_21626515 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626515 = validateParameter(valid_21626515, JString, required = false,
                                   default = nil)
  if valid_21626515 != nil:
    section.add "X-Amz-Algorithm", valid_21626515
  var valid_21626516 = header.getOrDefault("X-Amz-Signature")
  valid_21626516 = validateParameter(valid_21626516, JString, required = false,
                                   default = nil)
  if valid_21626516 != nil:
    section.add "X-Amz-Signature", valid_21626516
  var valid_21626517 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626517 = validateParameter(valid_21626517, JString, required = false,
                                   default = nil)
  if valid_21626517 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626517
  var valid_21626518 = header.getOrDefault("X-Amz-Credential")
  valid_21626518 = validateParameter(valid_21626518, JString, required = false,
                                   default = nil)
  if valid_21626518 != nil:
    section.add "X-Amz-Credential", valid_21626518
  result.add "header", section
  ## parameters in `formData` object:
  ##   DeleteSourceBundle: JBool
  ##                     : Set to <code>true</code> to delete the source bundle from your storage bucket. Otherwise, the application version is deleted only from Elastic Beanstalk and the source bundle remains in Amazon S3.
  ##   VersionLabel: JString (required)
  ##               : The label of the version to delete.
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to which the version belongs.
  section = newJObject()
  var valid_21626519 = formData.getOrDefault("DeleteSourceBundle")
  valid_21626519 = validateParameter(valid_21626519, JBool, required = false,
                                   default = nil)
  if valid_21626519 != nil:
    section.add "DeleteSourceBundle", valid_21626519
  assert formData != nil,
        "formData argument is necessary due to required `VersionLabel` field"
  var valid_21626520 = formData.getOrDefault("VersionLabel")
  valid_21626520 = validateParameter(valid_21626520, JString, required = true,
                                   default = nil)
  if valid_21626520 != nil:
    section.add "VersionLabel", valid_21626520
  var valid_21626521 = formData.getOrDefault("ApplicationName")
  valid_21626521 = validateParameter(valid_21626521, JString, required = true,
                                   default = nil)
  if valid_21626521 != nil:
    section.add "ApplicationName", valid_21626521
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626522: Call_PostDeleteApplicationVersion_21626507;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified version from the specified application.</p> <note> <p>You cannot delete an application version that is associated with a running environment.</p> </note>
  ## 
  let valid = call_21626522.validator(path, query, header, formData, body, _)
  let scheme = call_21626522.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626522.makeUrl(scheme.get, call_21626522.host, call_21626522.base,
                               call_21626522.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626522, uri, valid, _)

proc call*(call_21626523: Call_PostDeleteApplicationVersion_21626507;
          VersionLabel: string; ApplicationName: string;
          DeleteSourceBundle: bool = false;
          Action: string = "DeleteApplicationVersion";
          Version: string = "2010-12-01"): Recallable =
  ## postDeleteApplicationVersion
  ## <p>Deletes the specified version from the specified application.</p> <note> <p>You cannot delete an application version that is associated with a running environment.</p> </note>
  ##   DeleteSourceBundle: bool
  ##                     : Set to <code>true</code> to delete the source bundle from your storage bucket. Otherwise, the application version is deleted only from Elastic Beanstalk and the source bundle remains in Amazon S3.
  ##   VersionLabel: string (required)
  ##               : The label of the version to delete.
  ##   Action: string (required)
  ##   ApplicationName: string (required)
  ##                  : The name of the application to which the version belongs.
  ##   Version: string (required)
  var query_21626524 = newJObject()
  var formData_21626525 = newJObject()
  add(formData_21626525, "DeleteSourceBundle", newJBool(DeleteSourceBundle))
  add(formData_21626525, "VersionLabel", newJString(VersionLabel))
  add(query_21626524, "Action", newJString(Action))
  add(formData_21626525, "ApplicationName", newJString(ApplicationName))
  add(query_21626524, "Version", newJString(Version))
  result = call_21626523.call(nil, query_21626524, nil, formData_21626525, nil)

var postDeleteApplicationVersion* = Call_PostDeleteApplicationVersion_21626507(
    name: "postDeleteApplicationVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteApplicationVersion",
    validator: validate_PostDeleteApplicationVersion_21626508, base: "/",
    makeUrl: url_PostDeleteApplicationVersion_21626509,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteApplicationVersion_21626489 = ref object of OpenApiRestCall_21625437
proc url_GetDeleteApplicationVersion_21626491(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteApplicationVersion_21626490(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deletes the specified version from the specified application.</p> <note> <p>You cannot delete an application version that is associated with a running environment.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   VersionLabel: JString (required)
  ##               : The label of the version to delete.
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to which the version belongs.
  ##   Action: JString (required)
  ##   DeleteSourceBundle: JBool
  ##                     : Set to <code>true</code> to delete the source bundle from your storage bucket. Otherwise, the application version is deleted only from Elastic Beanstalk and the source bundle remains in Amazon S3.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `VersionLabel` field"
  var valid_21626492 = query.getOrDefault("VersionLabel")
  valid_21626492 = validateParameter(valid_21626492, JString, required = true,
                                   default = nil)
  if valid_21626492 != nil:
    section.add "VersionLabel", valid_21626492
  var valid_21626493 = query.getOrDefault("ApplicationName")
  valid_21626493 = validateParameter(valid_21626493, JString, required = true,
                                   default = nil)
  if valid_21626493 != nil:
    section.add "ApplicationName", valid_21626493
  var valid_21626494 = query.getOrDefault("Action")
  valid_21626494 = validateParameter(valid_21626494, JString, required = true, default = newJString(
      "DeleteApplicationVersion"))
  if valid_21626494 != nil:
    section.add "Action", valid_21626494
  var valid_21626495 = query.getOrDefault("DeleteSourceBundle")
  valid_21626495 = validateParameter(valid_21626495, JBool, required = false,
                                   default = nil)
  if valid_21626495 != nil:
    section.add "DeleteSourceBundle", valid_21626495
  var valid_21626496 = query.getOrDefault("Version")
  valid_21626496 = validateParameter(valid_21626496, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626496 != nil:
    section.add "Version", valid_21626496
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626497 = header.getOrDefault("X-Amz-Date")
  valid_21626497 = validateParameter(valid_21626497, JString, required = false,
                                   default = nil)
  if valid_21626497 != nil:
    section.add "X-Amz-Date", valid_21626497
  var valid_21626498 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626498 = validateParameter(valid_21626498, JString, required = false,
                                   default = nil)
  if valid_21626498 != nil:
    section.add "X-Amz-Security-Token", valid_21626498
  var valid_21626499 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626499 = validateParameter(valid_21626499, JString, required = false,
                                   default = nil)
  if valid_21626499 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626499
  var valid_21626500 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626500 = validateParameter(valid_21626500, JString, required = false,
                                   default = nil)
  if valid_21626500 != nil:
    section.add "X-Amz-Algorithm", valid_21626500
  var valid_21626501 = header.getOrDefault("X-Amz-Signature")
  valid_21626501 = validateParameter(valid_21626501, JString, required = false,
                                   default = nil)
  if valid_21626501 != nil:
    section.add "X-Amz-Signature", valid_21626501
  var valid_21626502 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626502 = validateParameter(valid_21626502, JString, required = false,
                                   default = nil)
  if valid_21626502 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626502
  var valid_21626503 = header.getOrDefault("X-Amz-Credential")
  valid_21626503 = validateParameter(valid_21626503, JString, required = false,
                                   default = nil)
  if valid_21626503 != nil:
    section.add "X-Amz-Credential", valid_21626503
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626504: Call_GetDeleteApplicationVersion_21626489;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified version from the specified application.</p> <note> <p>You cannot delete an application version that is associated with a running environment.</p> </note>
  ## 
  let valid = call_21626504.validator(path, query, header, formData, body, _)
  let scheme = call_21626504.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626504.makeUrl(scheme.get, call_21626504.host, call_21626504.base,
                               call_21626504.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626504, uri, valid, _)

proc call*(call_21626505: Call_GetDeleteApplicationVersion_21626489;
          VersionLabel: string; ApplicationName: string;
          Action: string = "DeleteApplicationVersion";
          DeleteSourceBundle: bool = false; Version: string = "2010-12-01"): Recallable =
  ## getDeleteApplicationVersion
  ## <p>Deletes the specified version from the specified application.</p> <note> <p>You cannot delete an application version that is associated with a running environment.</p> </note>
  ##   VersionLabel: string (required)
  ##               : The label of the version to delete.
  ##   ApplicationName: string (required)
  ##                  : The name of the application to which the version belongs.
  ##   Action: string (required)
  ##   DeleteSourceBundle: bool
  ##                     : Set to <code>true</code> to delete the source bundle from your storage bucket. Otherwise, the application version is deleted only from Elastic Beanstalk and the source bundle remains in Amazon S3.
  ##   Version: string (required)
  var query_21626506 = newJObject()
  add(query_21626506, "VersionLabel", newJString(VersionLabel))
  add(query_21626506, "ApplicationName", newJString(ApplicationName))
  add(query_21626506, "Action", newJString(Action))
  add(query_21626506, "DeleteSourceBundle", newJBool(DeleteSourceBundle))
  add(query_21626506, "Version", newJString(Version))
  result = call_21626505.call(nil, query_21626506, nil, nil, nil)

var getDeleteApplicationVersion* = Call_GetDeleteApplicationVersion_21626489(
    name: "getDeleteApplicationVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteApplicationVersion",
    validator: validate_GetDeleteApplicationVersion_21626490, base: "/",
    makeUrl: url_GetDeleteApplicationVersion_21626491,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteConfigurationTemplate_21626543 = ref object of OpenApiRestCall_21625437
proc url_PostDeleteConfigurationTemplate_21626545(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteConfigurationTemplate_21626544(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626546 = query.getOrDefault("Action")
  valid_21626546 = validateParameter(valid_21626546, JString, required = true, default = newJString(
      "DeleteConfigurationTemplate"))
  if valid_21626546 != nil:
    section.add "Action", valid_21626546
  var valid_21626547 = query.getOrDefault("Version")
  valid_21626547 = validateParameter(valid_21626547, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626547 != nil:
    section.add "Version", valid_21626547
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626548 = header.getOrDefault("X-Amz-Date")
  valid_21626548 = validateParameter(valid_21626548, JString, required = false,
                                   default = nil)
  if valid_21626548 != nil:
    section.add "X-Amz-Date", valid_21626548
  var valid_21626549 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626549 = validateParameter(valid_21626549, JString, required = false,
                                   default = nil)
  if valid_21626549 != nil:
    section.add "X-Amz-Security-Token", valid_21626549
  var valid_21626550 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626550 = validateParameter(valid_21626550, JString, required = false,
                                   default = nil)
  if valid_21626550 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626550
  var valid_21626551 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626551 = validateParameter(valid_21626551, JString, required = false,
                                   default = nil)
  if valid_21626551 != nil:
    section.add "X-Amz-Algorithm", valid_21626551
  var valid_21626552 = header.getOrDefault("X-Amz-Signature")
  valid_21626552 = validateParameter(valid_21626552, JString, required = false,
                                   default = nil)
  if valid_21626552 != nil:
    section.add "X-Amz-Signature", valid_21626552
  var valid_21626553 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626553 = validateParameter(valid_21626553, JString, required = false,
                                   default = nil)
  if valid_21626553 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626553
  var valid_21626554 = header.getOrDefault("X-Amz-Credential")
  valid_21626554 = validateParameter(valid_21626554, JString, required = false,
                                   default = nil)
  if valid_21626554 != nil:
    section.add "X-Amz-Credential", valid_21626554
  result.add "header", section
  ## parameters in `formData` object:
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to delete the configuration template from.
  ##   TemplateName: JString (required)
  ##               : The name of the configuration template to delete.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_21626555 = formData.getOrDefault("ApplicationName")
  valid_21626555 = validateParameter(valid_21626555, JString, required = true,
                                   default = nil)
  if valid_21626555 != nil:
    section.add "ApplicationName", valid_21626555
  var valid_21626556 = formData.getOrDefault("TemplateName")
  valid_21626556 = validateParameter(valid_21626556, JString, required = true,
                                   default = nil)
  if valid_21626556 != nil:
    section.add "TemplateName", valid_21626556
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626557: Call_PostDeleteConfigurationTemplate_21626543;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified configuration template.</p> <note> <p>When you launch an environment using a configuration template, the environment gets a copy of the template. You can delete or modify the environment's copy of the template without affecting the running environment.</p> </note>
  ## 
  let valid = call_21626557.validator(path, query, header, formData, body, _)
  let scheme = call_21626557.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626557.makeUrl(scheme.get, call_21626557.host, call_21626557.base,
                               call_21626557.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626557, uri, valid, _)

proc call*(call_21626558: Call_PostDeleteConfigurationTemplate_21626543;
          ApplicationName: string; TemplateName: string;
          Action: string = "DeleteConfigurationTemplate";
          Version: string = "2010-12-01"): Recallable =
  ## postDeleteConfigurationTemplate
  ## <p>Deletes the specified configuration template.</p> <note> <p>When you launch an environment using a configuration template, the environment gets a copy of the template. You can delete or modify the environment's copy of the template without affecting the running environment.</p> </note>
  ##   Action: string (required)
  ##   ApplicationName: string (required)
  ##                  : The name of the application to delete the configuration template from.
  ##   TemplateName: string (required)
  ##               : The name of the configuration template to delete.
  ##   Version: string (required)
  var query_21626559 = newJObject()
  var formData_21626560 = newJObject()
  add(query_21626559, "Action", newJString(Action))
  add(formData_21626560, "ApplicationName", newJString(ApplicationName))
  add(formData_21626560, "TemplateName", newJString(TemplateName))
  add(query_21626559, "Version", newJString(Version))
  result = call_21626558.call(nil, query_21626559, nil, formData_21626560, nil)

var postDeleteConfigurationTemplate* = Call_PostDeleteConfigurationTemplate_21626543(
    name: "postDeleteConfigurationTemplate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteConfigurationTemplate",
    validator: validate_PostDeleteConfigurationTemplate_21626544, base: "/",
    makeUrl: url_PostDeleteConfigurationTemplate_21626545,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteConfigurationTemplate_21626526 = ref object of OpenApiRestCall_21625437
proc url_GetDeleteConfigurationTemplate_21626528(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteConfigurationTemplate_21626527(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   TemplateName: JString (required)
  ##               : The name of the configuration template to delete.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_21626529 = query.getOrDefault("ApplicationName")
  valid_21626529 = validateParameter(valid_21626529, JString, required = true,
                                   default = nil)
  if valid_21626529 != nil:
    section.add "ApplicationName", valid_21626529
  var valid_21626530 = query.getOrDefault("Action")
  valid_21626530 = validateParameter(valid_21626530, JString, required = true, default = newJString(
      "DeleteConfigurationTemplate"))
  if valid_21626530 != nil:
    section.add "Action", valid_21626530
  var valid_21626531 = query.getOrDefault("TemplateName")
  valid_21626531 = validateParameter(valid_21626531, JString, required = true,
                                   default = nil)
  if valid_21626531 != nil:
    section.add "TemplateName", valid_21626531
  var valid_21626532 = query.getOrDefault("Version")
  valid_21626532 = validateParameter(valid_21626532, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626532 != nil:
    section.add "Version", valid_21626532
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626533 = header.getOrDefault("X-Amz-Date")
  valid_21626533 = validateParameter(valid_21626533, JString, required = false,
                                   default = nil)
  if valid_21626533 != nil:
    section.add "X-Amz-Date", valid_21626533
  var valid_21626534 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626534 = validateParameter(valid_21626534, JString, required = false,
                                   default = nil)
  if valid_21626534 != nil:
    section.add "X-Amz-Security-Token", valid_21626534
  var valid_21626535 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626535 = validateParameter(valid_21626535, JString, required = false,
                                   default = nil)
  if valid_21626535 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626535
  var valid_21626536 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626536 = validateParameter(valid_21626536, JString, required = false,
                                   default = nil)
  if valid_21626536 != nil:
    section.add "X-Amz-Algorithm", valid_21626536
  var valid_21626537 = header.getOrDefault("X-Amz-Signature")
  valid_21626537 = validateParameter(valid_21626537, JString, required = false,
                                   default = nil)
  if valid_21626537 != nil:
    section.add "X-Amz-Signature", valid_21626537
  var valid_21626538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626538 = validateParameter(valid_21626538, JString, required = false,
                                   default = nil)
  if valid_21626538 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626538
  var valid_21626539 = header.getOrDefault("X-Amz-Credential")
  valid_21626539 = validateParameter(valid_21626539, JString, required = false,
                                   default = nil)
  if valid_21626539 != nil:
    section.add "X-Amz-Credential", valid_21626539
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626540: Call_GetDeleteConfigurationTemplate_21626526;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the specified configuration template.</p> <note> <p>When you launch an environment using a configuration template, the environment gets a copy of the template. You can delete or modify the environment's copy of the template without affecting the running environment.</p> </note>
  ## 
  let valid = call_21626540.validator(path, query, header, formData, body, _)
  let scheme = call_21626540.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626540.makeUrl(scheme.get, call_21626540.host, call_21626540.base,
                               call_21626540.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626540, uri, valid, _)

proc call*(call_21626541: Call_GetDeleteConfigurationTemplate_21626526;
          ApplicationName: string; TemplateName: string;
          Action: string = "DeleteConfigurationTemplate";
          Version: string = "2010-12-01"): Recallable =
  ## getDeleteConfigurationTemplate
  ## <p>Deletes the specified configuration template.</p> <note> <p>When you launch an environment using a configuration template, the environment gets a copy of the template. You can delete or modify the environment's copy of the template without affecting the running environment.</p> </note>
  ##   ApplicationName: string (required)
  ##                  : The name of the application to delete the configuration template from.
  ##   Action: string (required)
  ##   TemplateName: string (required)
  ##               : The name of the configuration template to delete.
  ##   Version: string (required)
  var query_21626542 = newJObject()
  add(query_21626542, "ApplicationName", newJString(ApplicationName))
  add(query_21626542, "Action", newJString(Action))
  add(query_21626542, "TemplateName", newJString(TemplateName))
  add(query_21626542, "Version", newJString(Version))
  result = call_21626541.call(nil, query_21626542, nil, nil, nil)

var getDeleteConfigurationTemplate* = Call_GetDeleteConfigurationTemplate_21626526(
    name: "getDeleteConfigurationTemplate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteConfigurationTemplate",
    validator: validate_GetDeleteConfigurationTemplate_21626527, base: "/",
    makeUrl: url_GetDeleteConfigurationTemplate_21626528,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEnvironmentConfiguration_21626578 = ref object of OpenApiRestCall_21625437
proc url_PostDeleteEnvironmentConfiguration_21626580(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteEnvironmentConfiguration_21626579(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626581 = query.getOrDefault("Action")
  valid_21626581 = validateParameter(valid_21626581, JString, required = true, default = newJString(
      "DeleteEnvironmentConfiguration"))
  if valid_21626581 != nil:
    section.add "Action", valid_21626581
  var valid_21626582 = query.getOrDefault("Version")
  valid_21626582 = validateParameter(valid_21626582, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626582 != nil:
    section.add "Version", valid_21626582
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626583 = header.getOrDefault("X-Amz-Date")
  valid_21626583 = validateParameter(valid_21626583, JString, required = false,
                                   default = nil)
  if valid_21626583 != nil:
    section.add "X-Amz-Date", valid_21626583
  var valid_21626584 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626584 = validateParameter(valid_21626584, JString, required = false,
                                   default = nil)
  if valid_21626584 != nil:
    section.add "X-Amz-Security-Token", valid_21626584
  var valid_21626585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626585 = validateParameter(valid_21626585, JString, required = false,
                                   default = nil)
  if valid_21626585 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626585
  var valid_21626586 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626586 = validateParameter(valid_21626586, JString, required = false,
                                   default = nil)
  if valid_21626586 != nil:
    section.add "X-Amz-Algorithm", valid_21626586
  var valid_21626587 = header.getOrDefault("X-Amz-Signature")
  valid_21626587 = validateParameter(valid_21626587, JString, required = false,
                                   default = nil)
  if valid_21626587 != nil:
    section.add "X-Amz-Signature", valid_21626587
  var valid_21626588 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626588 = validateParameter(valid_21626588, JString, required = false,
                                   default = nil)
  if valid_21626588 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626588
  var valid_21626589 = header.getOrDefault("X-Amz-Credential")
  valid_21626589 = validateParameter(valid_21626589, JString, required = false,
                                   default = nil)
  if valid_21626589 != nil:
    section.add "X-Amz-Credential", valid_21626589
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString (required)
  ##                  : The name of the environment to delete the draft configuration from.
  ##   ApplicationName: JString (required)
  ##                  : The name of the application the environment is associated with.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `EnvironmentName` field"
  var valid_21626590 = formData.getOrDefault("EnvironmentName")
  valid_21626590 = validateParameter(valid_21626590, JString, required = true,
                                   default = nil)
  if valid_21626590 != nil:
    section.add "EnvironmentName", valid_21626590
  var valid_21626591 = formData.getOrDefault("ApplicationName")
  valid_21626591 = validateParameter(valid_21626591, JString, required = true,
                                   default = nil)
  if valid_21626591 != nil:
    section.add "ApplicationName", valid_21626591
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626592: Call_PostDeleteEnvironmentConfiguration_21626578;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the draft configuration associated with the running environment.</p> <p>Updating a running environment with any configuration changes creates a draft configuration set. You can get the draft configuration using <a>DescribeConfigurationSettings</a> while the update is in progress or if the update fails. The <code>DeploymentStatus</code> for the draft configuration indicates whether the deployment is in process or has failed. The draft configuration remains in existence until it is deleted with this action.</p>
  ## 
  let valid = call_21626592.validator(path, query, header, formData, body, _)
  let scheme = call_21626592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626592.makeUrl(scheme.get, call_21626592.host, call_21626592.base,
                               call_21626592.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626592, uri, valid, _)

proc call*(call_21626593: Call_PostDeleteEnvironmentConfiguration_21626578;
          EnvironmentName: string; ApplicationName: string;
          Action: string = "DeleteEnvironmentConfiguration";
          Version: string = "2010-12-01"): Recallable =
  ## postDeleteEnvironmentConfiguration
  ## <p>Deletes the draft configuration associated with the running environment.</p> <p>Updating a running environment with any configuration changes creates a draft configuration set. You can get the draft configuration using <a>DescribeConfigurationSettings</a> while the update is in progress or if the update fails. The <code>DeploymentStatus</code> for the draft configuration indicates whether the deployment is in process or has failed. The draft configuration remains in existence until it is deleted with this action.</p>
  ##   EnvironmentName: string (required)
  ##                  : The name of the environment to delete the draft configuration from.
  ##   Action: string (required)
  ##   ApplicationName: string (required)
  ##                  : The name of the application the environment is associated with.
  ##   Version: string (required)
  var query_21626594 = newJObject()
  var formData_21626595 = newJObject()
  add(formData_21626595, "EnvironmentName", newJString(EnvironmentName))
  add(query_21626594, "Action", newJString(Action))
  add(formData_21626595, "ApplicationName", newJString(ApplicationName))
  add(query_21626594, "Version", newJString(Version))
  result = call_21626593.call(nil, query_21626594, nil, formData_21626595, nil)

var postDeleteEnvironmentConfiguration* = Call_PostDeleteEnvironmentConfiguration_21626578(
    name: "postDeleteEnvironmentConfiguration", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteEnvironmentConfiguration",
    validator: validate_PostDeleteEnvironmentConfiguration_21626579, base: "/",
    makeUrl: url_PostDeleteEnvironmentConfiguration_21626580,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEnvironmentConfiguration_21626561 = ref object of OpenApiRestCall_21625437
proc url_GetDeleteEnvironmentConfiguration_21626563(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteEnvironmentConfiguration_21626562(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626564 = query.getOrDefault("ApplicationName")
  valid_21626564 = validateParameter(valid_21626564, JString, required = true,
                                   default = nil)
  if valid_21626564 != nil:
    section.add "ApplicationName", valid_21626564
  var valid_21626565 = query.getOrDefault("EnvironmentName")
  valid_21626565 = validateParameter(valid_21626565, JString, required = true,
                                   default = nil)
  if valid_21626565 != nil:
    section.add "EnvironmentName", valid_21626565
  var valid_21626566 = query.getOrDefault("Action")
  valid_21626566 = validateParameter(valid_21626566, JString, required = true, default = newJString(
      "DeleteEnvironmentConfiguration"))
  if valid_21626566 != nil:
    section.add "Action", valid_21626566
  var valid_21626567 = query.getOrDefault("Version")
  valid_21626567 = validateParameter(valid_21626567, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626567 != nil:
    section.add "Version", valid_21626567
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626568 = header.getOrDefault("X-Amz-Date")
  valid_21626568 = validateParameter(valid_21626568, JString, required = false,
                                   default = nil)
  if valid_21626568 != nil:
    section.add "X-Amz-Date", valid_21626568
  var valid_21626569 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626569 = validateParameter(valid_21626569, JString, required = false,
                                   default = nil)
  if valid_21626569 != nil:
    section.add "X-Amz-Security-Token", valid_21626569
  var valid_21626570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626570 = validateParameter(valid_21626570, JString, required = false,
                                   default = nil)
  if valid_21626570 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626570
  var valid_21626571 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626571 = validateParameter(valid_21626571, JString, required = false,
                                   default = nil)
  if valid_21626571 != nil:
    section.add "X-Amz-Algorithm", valid_21626571
  var valid_21626572 = header.getOrDefault("X-Amz-Signature")
  valid_21626572 = validateParameter(valid_21626572, JString, required = false,
                                   default = nil)
  if valid_21626572 != nil:
    section.add "X-Amz-Signature", valid_21626572
  var valid_21626573 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626573 = validateParameter(valid_21626573, JString, required = false,
                                   default = nil)
  if valid_21626573 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626573
  var valid_21626574 = header.getOrDefault("X-Amz-Credential")
  valid_21626574 = validateParameter(valid_21626574, JString, required = false,
                                   default = nil)
  if valid_21626574 != nil:
    section.add "X-Amz-Credential", valid_21626574
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626575: Call_GetDeleteEnvironmentConfiguration_21626561;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the draft configuration associated with the running environment.</p> <p>Updating a running environment with any configuration changes creates a draft configuration set. You can get the draft configuration using <a>DescribeConfigurationSettings</a> while the update is in progress or if the update fails. The <code>DeploymentStatus</code> for the draft configuration indicates whether the deployment is in process or has failed. The draft configuration remains in existence until it is deleted with this action.</p>
  ## 
  let valid = call_21626575.validator(path, query, header, formData, body, _)
  let scheme = call_21626575.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626575.makeUrl(scheme.get, call_21626575.host, call_21626575.base,
                               call_21626575.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626575, uri, valid, _)

proc call*(call_21626576: Call_GetDeleteEnvironmentConfiguration_21626561;
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
  var query_21626577 = newJObject()
  add(query_21626577, "ApplicationName", newJString(ApplicationName))
  add(query_21626577, "EnvironmentName", newJString(EnvironmentName))
  add(query_21626577, "Action", newJString(Action))
  add(query_21626577, "Version", newJString(Version))
  result = call_21626576.call(nil, query_21626577, nil, nil, nil)

var getDeleteEnvironmentConfiguration* = Call_GetDeleteEnvironmentConfiguration_21626561(
    name: "getDeleteEnvironmentConfiguration", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteEnvironmentConfiguration",
    validator: validate_GetDeleteEnvironmentConfiguration_21626562, base: "/",
    makeUrl: url_GetDeleteEnvironmentConfiguration_21626563,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeletePlatformVersion_21626612 = ref object of OpenApiRestCall_21625437
proc url_PostDeletePlatformVersion_21626614(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeletePlatformVersion_21626613(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626615 = query.getOrDefault("Action")
  valid_21626615 = validateParameter(valid_21626615, JString, required = true, default = newJString(
      "DeletePlatformVersion"))
  if valid_21626615 != nil:
    section.add "Action", valid_21626615
  var valid_21626616 = query.getOrDefault("Version")
  valid_21626616 = validateParameter(valid_21626616, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626616 != nil:
    section.add "Version", valid_21626616
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626617 = header.getOrDefault("X-Amz-Date")
  valid_21626617 = validateParameter(valid_21626617, JString, required = false,
                                   default = nil)
  if valid_21626617 != nil:
    section.add "X-Amz-Date", valid_21626617
  var valid_21626618 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626618 = validateParameter(valid_21626618, JString, required = false,
                                   default = nil)
  if valid_21626618 != nil:
    section.add "X-Amz-Security-Token", valid_21626618
  var valid_21626619 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626619 = validateParameter(valid_21626619, JString, required = false,
                                   default = nil)
  if valid_21626619 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626619
  var valid_21626620 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626620 = validateParameter(valid_21626620, JString, required = false,
                                   default = nil)
  if valid_21626620 != nil:
    section.add "X-Amz-Algorithm", valid_21626620
  var valid_21626621 = header.getOrDefault("X-Amz-Signature")
  valid_21626621 = validateParameter(valid_21626621, JString, required = false,
                                   default = nil)
  if valid_21626621 != nil:
    section.add "X-Amz-Signature", valid_21626621
  var valid_21626622 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626622 = validateParameter(valid_21626622, JString, required = false,
                                   default = nil)
  if valid_21626622 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626622
  var valid_21626623 = header.getOrDefault("X-Amz-Credential")
  valid_21626623 = validateParameter(valid_21626623, JString, required = false,
                                   default = nil)
  if valid_21626623 != nil:
    section.add "X-Amz-Credential", valid_21626623
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformArn: JString
  ##              : The ARN of the version of the custom platform.
  section = newJObject()
  var valid_21626624 = formData.getOrDefault("PlatformArn")
  valid_21626624 = validateParameter(valid_21626624, JString, required = false,
                                   default = nil)
  if valid_21626624 != nil:
    section.add "PlatformArn", valid_21626624
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626625: Call_PostDeletePlatformVersion_21626612;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified version of a custom platform.
  ## 
  let valid = call_21626625.validator(path, query, header, formData, body, _)
  let scheme = call_21626625.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626625.makeUrl(scheme.get, call_21626625.host, call_21626625.base,
                               call_21626625.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626625, uri, valid, _)

proc call*(call_21626626: Call_PostDeletePlatformVersion_21626612;
          Action: string = "DeletePlatformVersion"; PlatformArn: string = "";
          Version: string = "2010-12-01"): Recallable =
  ## postDeletePlatformVersion
  ## Deletes the specified version of a custom platform.
  ##   Action: string (required)
  ##   PlatformArn: string
  ##              : The ARN of the version of the custom platform.
  ##   Version: string (required)
  var query_21626627 = newJObject()
  var formData_21626628 = newJObject()
  add(query_21626627, "Action", newJString(Action))
  add(formData_21626628, "PlatformArn", newJString(PlatformArn))
  add(query_21626627, "Version", newJString(Version))
  result = call_21626626.call(nil, query_21626627, nil, formData_21626628, nil)

var postDeletePlatformVersion* = Call_PostDeletePlatformVersion_21626612(
    name: "postDeletePlatformVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeletePlatformVersion",
    validator: validate_PostDeletePlatformVersion_21626613, base: "/",
    makeUrl: url_PostDeletePlatformVersion_21626614,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeletePlatformVersion_21626596 = ref object of OpenApiRestCall_21625437
proc url_GetDeletePlatformVersion_21626598(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeletePlatformVersion_21626597(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the specified version of a custom platform.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PlatformArn: JString
  ##              : The ARN of the version of the custom platform.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626599 = query.getOrDefault("PlatformArn")
  valid_21626599 = validateParameter(valid_21626599, JString, required = false,
                                   default = nil)
  if valid_21626599 != nil:
    section.add "PlatformArn", valid_21626599
  var valid_21626600 = query.getOrDefault("Action")
  valid_21626600 = validateParameter(valid_21626600, JString, required = true, default = newJString(
      "DeletePlatformVersion"))
  if valid_21626600 != nil:
    section.add "Action", valid_21626600
  var valid_21626601 = query.getOrDefault("Version")
  valid_21626601 = validateParameter(valid_21626601, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626601 != nil:
    section.add "Version", valid_21626601
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626602 = header.getOrDefault("X-Amz-Date")
  valid_21626602 = validateParameter(valid_21626602, JString, required = false,
                                   default = nil)
  if valid_21626602 != nil:
    section.add "X-Amz-Date", valid_21626602
  var valid_21626603 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626603 = validateParameter(valid_21626603, JString, required = false,
                                   default = nil)
  if valid_21626603 != nil:
    section.add "X-Amz-Security-Token", valid_21626603
  var valid_21626604 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626604 = validateParameter(valid_21626604, JString, required = false,
                                   default = nil)
  if valid_21626604 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626604
  var valid_21626605 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626605 = validateParameter(valid_21626605, JString, required = false,
                                   default = nil)
  if valid_21626605 != nil:
    section.add "X-Amz-Algorithm", valid_21626605
  var valid_21626606 = header.getOrDefault("X-Amz-Signature")
  valid_21626606 = validateParameter(valid_21626606, JString, required = false,
                                   default = nil)
  if valid_21626606 != nil:
    section.add "X-Amz-Signature", valid_21626606
  var valid_21626607 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626607 = validateParameter(valid_21626607, JString, required = false,
                                   default = nil)
  if valid_21626607 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626607
  var valid_21626608 = header.getOrDefault("X-Amz-Credential")
  valid_21626608 = validateParameter(valid_21626608, JString, required = false,
                                   default = nil)
  if valid_21626608 != nil:
    section.add "X-Amz-Credential", valid_21626608
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626609: Call_GetDeletePlatformVersion_21626596;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the specified version of a custom platform.
  ## 
  let valid = call_21626609.validator(path, query, header, formData, body, _)
  let scheme = call_21626609.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626609.makeUrl(scheme.get, call_21626609.host, call_21626609.base,
                               call_21626609.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626609, uri, valid, _)

proc call*(call_21626610: Call_GetDeletePlatformVersion_21626596;
          PlatformArn: string = ""; Action: string = "DeletePlatformVersion";
          Version: string = "2010-12-01"): Recallable =
  ## getDeletePlatformVersion
  ## Deletes the specified version of a custom platform.
  ##   PlatformArn: string
  ##              : The ARN of the version of the custom platform.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626611 = newJObject()
  add(query_21626611, "PlatformArn", newJString(PlatformArn))
  add(query_21626611, "Action", newJString(Action))
  add(query_21626611, "Version", newJString(Version))
  result = call_21626610.call(nil, query_21626611, nil, nil, nil)

var getDeletePlatformVersion* = Call_GetDeletePlatformVersion_21626596(
    name: "getDeletePlatformVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeletePlatformVersion",
    validator: validate_GetDeletePlatformVersion_21626597, base: "/",
    makeUrl: url_GetDeletePlatformVersion_21626598,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAccountAttributes_21626644 = ref object of OpenApiRestCall_21625437
proc url_PostDescribeAccountAttributes_21626646(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeAccountAttributes_21626645(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626647 = query.getOrDefault("Action")
  valid_21626647 = validateParameter(valid_21626647, JString, required = true, default = newJString(
      "DescribeAccountAttributes"))
  if valid_21626647 != nil:
    section.add "Action", valid_21626647
  var valid_21626648 = query.getOrDefault("Version")
  valid_21626648 = validateParameter(valid_21626648, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626648 != nil:
    section.add "Version", valid_21626648
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626649 = header.getOrDefault("X-Amz-Date")
  valid_21626649 = validateParameter(valid_21626649, JString, required = false,
                                   default = nil)
  if valid_21626649 != nil:
    section.add "X-Amz-Date", valid_21626649
  var valid_21626650 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626650 = validateParameter(valid_21626650, JString, required = false,
                                   default = nil)
  if valid_21626650 != nil:
    section.add "X-Amz-Security-Token", valid_21626650
  var valid_21626651 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626651 = validateParameter(valid_21626651, JString, required = false,
                                   default = nil)
  if valid_21626651 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626651
  var valid_21626652 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626652 = validateParameter(valid_21626652, JString, required = false,
                                   default = nil)
  if valid_21626652 != nil:
    section.add "X-Amz-Algorithm", valid_21626652
  var valid_21626653 = header.getOrDefault("X-Amz-Signature")
  valid_21626653 = validateParameter(valid_21626653, JString, required = false,
                                   default = nil)
  if valid_21626653 != nil:
    section.add "X-Amz-Signature", valid_21626653
  var valid_21626654 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626654 = validateParameter(valid_21626654, JString, required = false,
                                   default = nil)
  if valid_21626654 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626654
  var valid_21626655 = header.getOrDefault("X-Amz-Credential")
  valid_21626655 = validateParameter(valid_21626655, JString, required = false,
                                   default = nil)
  if valid_21626655 != nil:
    section.add "X-Amz-Credential", valid_21626655
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626656: Call_PostDescribeAccountAttributes_21626644;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ## 
  let valid = call_21626656.validator(path, query, header, formData, body, _)
  let scheme = call_21626656.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626656.makeUrl(scheme.get, call_21626656.host, call_21626656.base,
                               call_21626656.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626656, uri, valid, _)

proc call*(call_21626657: Call_PostDescribeAccountAttributes_21626644;
          Action: string = "DescribeAccountAttributes";
          Version: string = "2010-12-01"): Recallable =
  ## postDescribeAccountAttributes
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626658 = newJObject()
  add(query_21626658, "Action", newJString(Action))
  add(query_21626658, "Version", newJString(Version))
  result = call_21626657.call(nil, query_21626658, nil, nil, nil)

var postDescribeAccountAttributes* = Call_PostDescribeAccountAttributes_21626644(
    name: "postDescribeAccountAttributes", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeAccountAttributes",
    validator: validate_PostDescribeAccountAttributes_21626645, base: "/",
    makeUrl: url_PostDescribeAccountAttributes_21626646,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAccountAttributes_21626629 = ref object of OpenApiRestCall_21625437
proc url_GetDescribeAccountAttributes_21626631(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeAccountAttributes_21626630(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626632 = query.getOrDefault("Action")
  valid_21626632 = validateParameter(valid_21626632, JString, required = true, default = newJString(
      "DescribeAccountAttributes"))
  if valid_21626632 != nil:
    section.add "Action", valid_21626632
  var valid_21626633 = query.getOrDefault("Version")
  valid_21626633 = validateParameter(valid_21626633, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626633 != nil:
    section.add "Version", valid_21626633
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626634 = header.getOrDefault("X-Amz-Date")
  valid_21626634 = validateParameter(valid_21626634, JString, required = false,
                                   default = nil)
  if valid_21626634 != nil:
    section.add "X-Amz-Date", valid_21626634
  var valid_21626635 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626635 = validateParameter(valid_21626635, JString, required = false,
                                   default = nil)
  if valid_21626635 != nil:
    section.add "X-Amz-Security-Token", valid_21626635
  var valid_21626636 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626636 = validateParameter(valid_21626636, JString, required = false,
                                   default = nil)
  if valid_21626636 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626636
  var valid_21626637 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626637 = validateParameter(valid_21626637, JString, required = false,
                                   default = nil)
  if valid_21626637 != nil:
    section.add "X-Amz-Algorithm", valid_21626637
  var valid_21626638 = header.getOrDefault("X-Amz-Signature")
  valid_21626638 = validateParameter(valid_21626638, JString, required = false,
                                   default = nil)
  if valid_21626638 != nil:
    section.add "X-Amz-Signature", valid_21626638
  var valid_21626639 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626639 = validateParameter(valid_21626639, JString, required = false,
                                   default = nil)
  if valid_21626639 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626639
  var valid_21626640 = header.getOrDefault("X-Amz-Credential")
  valid_21626640 = validateParameter(valid_21626640, JString, required = false,
                                   default = nil)
  if valid_21626640 != nil:
    section.add "X-Amz-Credential", valid_21626640
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626641: Call_GetDescribeAccountAttributes_21626629;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ## 
  let valid = call_21626641.validator(path, query, header, formData, body, _)
  let scheme = call_21626641.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626641.makeUrl(scheme.get, call_21626641.host, call_21626641.base,
                               call_21626641.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626641, uri, valid, _)

proc call*(call_21626642: Call_GetDescribeAccountAttributes_21626629;
          Action: string = "DescribeAccountAttributes";
          Version: string = "2010-12-01"): Recallable =
  ## getDescribeAccountAttributes
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626643 = newJObject()
  add(query_21626643, "Action", newJString(Action))
  add(query_21626643, "Version", newJString(Version))
  result = call_21626642.call(nil, query_21626643, nil, nil, nil)

var getDescribeAccountAttributes* = Call_GetDescribeAccountAttributes_21626629(
    name: "getDescribeAccountAttributes", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeAccountAttributes",
    validator: validate_GetDescribeAccountAttributes_21626630, base: "/",
    makeUrl: url_GetDescribeAccountAttributes_21626631,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeApplicationVersions_21626678 = ref object of OpenApiRestCall_21625437
proc url_PostDescribeApplicationVersions_21626680(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeApplicationVersions_21626679(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626681 = query.getOrDefault("Action")
  valid_21626681 = validateParameter(valid_21626681, JString, required = true, default = newJString(
      "DescribeApplicationVersions"))
  if valid_21626681 != nil:
    section.add "Action", valid_21626681
  var valid_21626682 = query.getOrDefault("Version")
  valid_21626682 = validateParameter(valid_21626682, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626682 != nil:
    section.add "Version", valid_21626682
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626683 = header.getOrDefault("X-Amz-Date")
  valid_21626683 = validateParameter(valid_21626683, JString, required = false,
                                   default = nil)
  if valid_21626683 != nil:
    section.add "X-Amz-Date", valid_21626683
  var valid_21626684 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626684 = validateParameter(valid_21626684, JString, required = false,
                                   default = nil)
  if valid_21626684 != nil:
    section.add "X-Amz-Security-Token", valid_21626684
  var valid_21626685 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626685 = validateParameter(valid_21626685, JString, required = false,
                                   default = nil)
  if valid_21626685 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626685
  var valid_21626686 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626686 = validateParameter(valid_21626686, JString, required = false,
                                   default = nil)
  if valid_21626686 != nil:
    section.add "X-Amz-Algorithm", valid_21626686
  var valid_21626687 = header.getOrDefault("X-Amz-Signature")
  valid_21626687 = validateParameter(valid_21626687, JString, required = false,
                                   default = nil)
  if valid_21626687 != nil:
    section.add "X-Amz-Signature", valid_21626687
  var valid_21626688 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626688 = validateParameter(valid_21626688, JString, required = false,
                                   default = nil)
  if valid_21626688 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626688
  var valid_21626689 = header.getOrDefault("X-Amz-Credential")
  valid_21626689 = validateParameter(valid_21626689, JString, required = false,
                                   default = nil)
  if valid_21626689 != nil:
    section.add "X-Amz-Credential", valid_21626689
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : <p>For a paginated request. Specify a token from a previous response page to retrieve the next response page. All other parameter values must be identical to the ones specified in the initial request.</p> <p>If no <code>NextToken</code> is specified, the first page is retrieved.</p>
  ##   ApplicationName: JString
  ##                  : Specify an application name to show only application versions for that application.
  ##   MaxRecords: JInt
  ##             : <p>For a paginated request. Specify a maximum number of application versions to include in each response.</p> <p>If no <code>MaxRecords</code> is specified, all available application versions are retrieved in a single response.</p>
  ##   VersionLabels: JArray
  ##                : Specify a version label to show a specific application version.
  section = newJObject()
  var valid_21626690 = formData.getOrDefault("NextToken")
  valid_21626690 = validateParameter(valid_21626690, JString, required = false,
                                   default = nil)
  if valid_21626690 != nil:
    section.add "NextToken", valid_21626690
  var valid_21626691 = formData.getOrDefault("ApplicationName")
  valid_21626691 = validateParameter(valid_21626691, JString, required = false,
                                   default = nil)
  if valid_21626691 != nil:
    section.add "ApplicationName", valid_21626691
  var valid_21626692 = formData.getOrDefault("MaxRecords")
  valid_21626692 = validateParameter(valid_21626692, JInt, required = false,
                                   default = nil)
  if valid_21626692 != nil:
    section.add "MaxRecords", valid_21626692
  var valid_21626693 = formData.getOrDefault("VersionLabels")
  valid_21626693 = validateParameter(valid_21626693, JArray, required = false,
                                   default = nil)
  if valid_21626693 != nil:
    section.add "VersionLabels", valid_21626693
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626694: Call_PostDescribeApplicationVersions_21626678;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve a list of application versions.
  ## 
  let valid = call_21626694.validator(path, query, header, formData, body, _)
  let scheme = call_21626694.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626694.makeUrl(scheme.get, call_21626694.host, call_21626694.base,
                               call_21626694.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626694, uri, valid, _)

proc call*(call_21626695: Call_PostDescribeApplicationVersions_21626678;
          NextToken: string = ""; Action: string = "DescribeApplicationVersions";
          ApplicationName: string = ""; MaxRecords: int = 0;
          Version: string = "2010-12-01"; VersionLabels: JsonNode = nil): Recallable =
  ## postDescribeApplicationVersions
  ## Retrieve a list of application versions.
  ##   NextToken: string
  ##            : <p>For a paginated request. Specify a token from a previous response page to retrieve the next response page. All other parameter values must be identical to the ones specified in the initial request.</p> <p>If no <code>NextToken</code> is specified, the first page is retrieved.</p>
  ##   Action: string (required)
  ##   ApplicationName: string
  ##                  : Specify an application name to show only application versions for that application.
  ##   MaxRecords: int
  ##             : <p>For a paginated request. Specify a maximum number of application versions to include in each response.</p> <p>If no <code>MaxRecords</code> is specified, all available application versions are retrieved in a single response.</p>
  ##   Version: string (required)
  ##   VersionLabels: JArray
  ##                : Specify a version label to show a specific application version.
  var query_21626696 = newJObject()
  var formData_21626697 = newJObject()
  add(formData_21626697, "NextToken", newJString(NextToken))
  add(query_21626696, "Action", newJString(Action))
  add(formData_21626697, "ApplicationName", newJString(ApplicationName))
  add(formData_21626697, "MaxRecords", newJInt(MaxRecords))
  add(query_21626696, "Version", newJString(Version))
  if VersionLabels != nil:
    formData_21626697.add "VersionLabels", VersionLabels
  result = call_21626695.call(nil, query_21626696, nil, formData_21626697, nil)

var postDescribeApplicationVersions* = Call_PostDescribeApplicationVersions_21626678(
    name: "postDescribeApplicationVersions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplicationVersions",
    validator: validate_PostDescribeApplicationVersions_21626679, base: "/",
    makeUrl: url_PostDescribeApplicationVersions_21626680,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeApplicationVersions_21626659 = ref object of OpenApiRestCall_21625437
proc url_GetDescribeApplicationVersions_21626661(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeApplicationVersions_21626660(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Retrieve a list of application versions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##             : <p>For a paginated request. Specify a maximum number of application versions to include in each response.</p> <p>If no <code>MaxRecords</code> is specified, all available application versions are retrieved in a single response.</p>
  ##   ApplicationName: JString
  ##                  : Specify an application name to show only application versions for that application.
  ##   NextToken: JString
  ##            : <p>For a paginated request. Specify a token from a previous response page to retrieve the next response page. All other parameter values must be identical to the ones specified in the initial request.</p> <p>If no <code>NextToken</code> is specified, the first page is retrieved.</p>
  ##   Action: JString (required)
  ##   VersionLabels: JArray
  ##                : Specify a version label to show a specific application version.
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626662 = query.getOrDefault("MaxRecords")
  valid_21626662 = validateParameter(valid_21626662, JInt, required = false,
                                   default = nil)
  if valid_21626662 != nil:
    section.add "MaxRecords", valid_21626662
  var valid_21626663 = query.getOrDefault("ApplicationName")
  valid_21626663 = validateParameter(valid_21626663, JString, required = false,
                                   default = nil)
  if valid_21626663 != nil:
    section.add "ApplicationName", valid_21626663
  var valid_21626664 = query.getOrDefault("NextToken")
  valid_21626664 = validateParameter(valid_21626664, JString, required = false,
                                   default = nil)
  if valid_21626664 != nil:
    section.add "NextToken", valid_21626664
  var valid_21626665 = query.getOrDefault("Action")
  valid_21626665 = validateParameter(valid_21626665, JString, required = true, default = newJString(
      "DescribeApplicationVersions"))
  if valid_21626665 != nil:
    section.add "Action", valid_21626665
  var valid_21626666 = query.getOrDefault("VersionLabels")
  valid_21626666 = validateParameter(valid_21626666, JArray, required = false,
                                   default = nil)
  if valid_21626666 != nil:
    section.add "VersionLabels", valid_21626666
  var valid_21626667 = query.getOrDefault("Version")
  valid_21626667 = validateParameter(valid_21626667, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626667 != nil:
    section.add "Version", valid_21626667
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626668 = header.getOrDefault("X-Amz-Date")
  valid_21626668 = validateParameter(valid_21626668, JString, required = false,
                                   default = nil)
  if valid_21626668 != nil:
    section.add "X-Amz-Date", valid_21626668
  var valid_21626669 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626669 = validateParameter(valid_21626669, JString, required = false,
                                   default = nil)
  if valid_21626669 != nil:
    section.add "X-Amz-Security-Token", valid_21626669
  var valid_21626670 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626670 = validateParameter(valid_21626670, JString, required = false,
                                   default = nil)
  if valid_21626670 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626670
  var valid_21626671 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626671 = validateParameter(valid_21626671, JString, required = false,
                                   default = nil)
  if valid_21626671 != nil:
    section.add "X-Amz-Algorithm", valid_21626671
  var valid_21626672 = header.getOrDefault("X-Amz-Signature")
  valid_21626672 = validateParameter(valid_21626672, JString, required = false,
                                   default = nil)
  if valid_21626672 != nil:
    section.add "X-Amz-Signature", valid_21626672
  var valid_21626673 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626673 = validateParameter(valid_21626673, JString, required = false,
                                   default = nil)
  if valid_21626673 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626673
  var valid_21626674 = header.getOrDefault("X-Amz-Credential")
  valid_21626674 = validateParameter(valid_21626674, JString, required = false,
                                   default = nil)
  if valid_21626674 != nil:
    section.add "X-Amz-Credential", valid_21626674
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626675: Call_GetDescribeApplicationVersions_21626659;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve a list of application versions.
  ## 
  let valid = call_21626675.validator(path, query, header, formData, body, _)
  let scheme = call_21626675.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626675.makeUrl(scheme.get, call_21626675.host, call_21626675.base,
                               call_21626675.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626675, uri, valid, _)

proc call*(call_21626676: Call_GetDescribeApplicationVersions_21626659;
          MaxRecords: int = 0; ApplicationName: string = ""; NextToken: string = "";
          Action: string = "DescribeApplicationVersions";
          VersionLabels: JsonNode = nil; Version: string = "2010-12-01"): Recallable =
  ## getDescribeApplicationVersions
  ## Retrieve a list of application versions.
  ##   MaxRecords: int
  ##             : <p>For a paginated request. Specify a maximum number of application versions to include in each response.</p> <p>If no <code>MaxRecords</code> is specified, all available application versions are retrieved in a single response.</p>
  ##   ApplicationName: string
  ##                  : Specify an application name to show only application versions for that application.
  ##   NextToken: string
  ##            : <p>For a paginated request. Specify a token from a previous response page to retrieve the next response page. All other parameter values must be identical to the ones specified in the initial request.</p> <p>If no <code>NextToken</code> is specified, the first page is retrieved.</p>
  ##   Action: string (required)
  ##   VersionLabels: JArray
  ##                : Specify a version label to show a specific application version.
  ##   Version: string (required)
  var query_21626677 = newJObject()
  add(query_21626677, "MaxRecords", newJInt(MaxRecords))
  add(query_21626677, "ApplicationName", newJString(ApplicationName))
  add(query_21626677, "NextToken", newJString(NextToken))
  add(query_21626677, "Action", newJString(Action))
  if VersionLabels != nil:
    query_21626677.add "VersionLabels", VersionLabels
  add(query_21626677, "Version", newJString(Version))
  result = call_21626676.call(nil, query_21626677, nil, nil, nil)

var getDescribeApplicationVersions* = Call_GetDescribeApplicationVersions_21626659(
    name: "getDescribeApplicationVersions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplicationVersions",
    validator: validate_GetDescribeApplicationVersions_21626660, base: "/",
    makeUrl: url_GetDescribeApplicationVersions_21626661,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeApplications_21626714 = ref object of OpenApiRestCall_21625437
proc url_PostDescribeApplications_21626716(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeApplications_21626715(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626717 = query.getOrDefault("Action")
  valid_21626717 = validateParameter(valid_21626717, JString, required = true,
                                   default = newJString("DescribeApplications"))
  if valid_21626717 != nil:
    section.add "Action", valid_21626717
  var valid_21626718 = query.getOrDefault("Version")
  valid_21626718 = validateParameter(valid_21626718, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626718 != nil:
    section.add "Version", valid_21626718
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626719 = header.getOrDefault("X-Amz-Date")
  valid_21626719 = validateParameter(valid_21626719, JString, required = false,
                                   default = nil)
  if valid_21626719 != nil:
    section.add "X-Amz-Date", valid_21626719
  var valid_21626720 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626720 = validateParameter(valid_21626720, JString, required = false,
                                   default = nil)
  if valid_21626720 != nil:
    section.add "X-Amz-Security-Token", valid_21626720
  var valid_21626721 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626721 = validateParameter(valid_21626721, JString, required = false,
                                   default = nil)
  if valid_21626721 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626721
  var valid_21626722 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626722 = validateParameter(valid_21626722, JString, required = false,
                                   default = nil)
  if valid_21626722 != nil:
    section.add "X-Amz-Algorithm", valid_21626722
  var valid_21626723 = header.getOrDefault("X-Amz-Signature")
  valid_21626723 = validateParameter(valid_21626723, JString, required = false,
                                   default = nil)
  if valid_21626723 != nil:
    section.add "X-Amz-Signature", valid_21626723
  var valid_21626724 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626724 = validateParameter(valid_21626724, JString, required = false,
                                   default = nil)
  if valid_21626724 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626724
  var valid_21626725 = header.getOrDefault("X-Amz-Credential")
  valid_21626725 = validateParameter(valid_21626725, JString, required = false,
                                   default = nil)
  if valid_21626725 != nil:
    section.add "X-Amz-Credential", valid_21626725
  result.add "header", section
  ## parameters in `formData` object:
  ##   ApplicationNames: JArray
  ##                   : If specified, AWS Elastic Beanstalk restricts the returned descriptions to only include those with the specified names.
  section = newJObject()
  var valid_21626726 = formData.getOrDefault("ApplicationNames")
  valid_21626726 = validateParameter(valid_21626726, JArray, required = false,
                                   default = nil)
  if valid_21626726 != nil:
    section.add "ApplicationNames", valid_21626726
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626727: Call_PostDescribeApplications_21626714;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the descriptions of existing applications.
  ## 
  let valid = call_21626727.validator(path, query, header, formData, body, _)
  let scheme = call_21626727.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626727.makeUrl(scheme.get, call_21626727.host, call_21626727.base,
                               call_21626727.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626727, uri, valid, _)

proc call*(call_21626728: Call_PostDescribeApplications_21626714;
          ApplicationNames: JsonNode = nil; Action: string = "DescribeApplications";
          Version: string = "2010-12-01"): Recallable =
  ## postDescribeApplications
  ## Returns the descriptions of existing applications.
  ##   ApplicationNames: JArray
  ##                   : If specified, AWS Elastic Beanstalk restricts the returned descriptions to only include those with the specified names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626729 = newJObject()
  var formData_21626730 = newJObject()
  if ApplicationNames != nil:
    formData_21626730.add "ApplicationNames", ApplicationNames
  add(query_21626729, "Action", newJString(Action))
  add(query_21626729, "Version", newJString(Version))
  result = call_21626728.call(nil, query_21626729, nil, formData_21626730, nil)

var postDescribeApplications* = Call_PostDescribeApplications_21626714(
    name: "postDescribeApplications", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplications",
    validator: validate_PostDescribeApplications_21626715, base: "/",
    makeUrl: url_PostDescribeApplications_21626716,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeApplications_21626698 = ref object of OpenApiRestCall_21625437
proc url_GetDescribeApplications_21626700(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeApplications_21626699(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626701 = query.getOrDefault("ApplicationNames")
  valid_21626701 = validateParameter(valid_21626701, JArray, required = false,
                                   default = nil)
  if valid_21626701 != nil:
    section.add "ApplicationNames", valid_21626701
  var valid_21626702 = query.getOrDefault("Action")
  valid_21626702 = validateParameter(valid_21626702, JString, required = true,
                                   default = newJString("DescribeApplications"))
  if valid_21626702 != nil:
    section.add "Action", valid_21626702
  var valid_21626703 = query.getOrDefault("Version")
  valid_21626703 = validateParameter(valid_21626703, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626703 != nil:
    section.add "Version", valid_21626703
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626704 = header.getOrDefault("X-Amz-Date")
  valid_21626704 = validateParameter(valid_21626704, JString, required = false,
                                   default = nil)
  if valid_21626704 != nil:
    section.add "X-Amz-Date", valid_21626704
  var valid_21626705 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626705 = validateParameter(valid_21626705, JString, required = false,
                                   default = nil)
  if valid_21626705 != nil:
    section.add "X-Amz-Security-Token", valid_21626705
  var valid_21626706 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626706 = validateParameter(valid_21626706, JString, required = false,
                                   default = nil)
  if valid_21626706 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626706
  var valid_21626707 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626707 = validateParameter(valid_21626707, JString, required = false,
                                   default = nil)
  if valid_21626707 != nil:
    section.add "X-Amz-Algorithm", valid_21626707
  var valid_21626708 = header.getOrDefault("X-Amz-Signature")
  valid_21626708 = validateParameter(valid_21626708, JString, required = false,
                                   default = nil)
  if valid_21626708 != nil:
    section.add "X-Amz-Signature", valid_21626708
  var valid_21626709 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626709 = validateParameter(valid_21626709, JString, required = false,
                                   default = nil)
  if valid_21626709 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626709
  var valid_21626710 = header.getOrDefault("X-Amz-Credential")
  valid_21626710 = validateParameter(valid_21626710, JString, required = false,
                                   default = nil)
  if valid_21626710 != nil:
    section.add "X-Amz-Credential", valid_21626710
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626711: Call_GetDescribeApplications_21626698;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the descriptions of existing applications.
  ## 
  let valid = call_21626711.validator(path, query, header, formData, body, _)
  let scheme = call_21626711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626711.makeUrl(scheme.get, call_21626711.host, call_21626711.base,
                               call_21626711.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626711, uri, valid, _)

proc call*(call_21626712: Call_GetDescribeApplications_21626698;
          ApplicationNames: JsonNode = nil; Action: string = "DescribeApplications";
          Version: string = "2010-12-01"): Recallable =
  ## getDescribeApplications
  ## Returns the descriptions of existing applications.
  ##   ApplicationNames: JArray
  ##                   : If specified, AWS Elastic Beanstalk restricts the returned descriptions to only include those with the specified names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626713 = newJObject()
  if ApplicationNames != nil:
    query_21626713.add "ApplicationNames", ApplicationNames
  add(query_21626713, "Action", newJString(Action))
  add(query_21626713, "Version", newJString(Version))
  result = call_21626712.call(nil, query_21626713, nil, nil, nil)

var getDescribeApplications* = Call_GetDescribeApplications_21626698(
    name: "getDescribeApplications", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplications",
    validator: validate_GetDescribeApplications_21626699, base: "/",
    makeUrl: url_GetDescribeApplications_21626700,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeConfigurationOptions_21626752 = ref object of OpenApiRestCall_21625437
proc url_PostDescribeConfigurationOptions_21626754(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeConfigurationOptions_21626753(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626755 = query.getOrDefault("Action")
  valid_21626755 = validateParameter(valid_21626755, JString, required = true, default = newJString(
      "DescribeConfigurationOptions"))
  if valid_21626755 != nil:
    section.add "Action", valid_21626755
  var valid_21626756 = query.getOrDefault("Version")
  valid_21626756 = validateParameter(valid_21626756, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626756 != nil:
    section.add "Version", valid_21626756
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626757 = header.getOrDefault("X-Amz-Date")
  valid_21626757 = validateParameter(valid_21626757, JString, required = false,
                                   default = nil)
  if valid_21626757 != nil:
    section.add "X-Amz-Date", valid_21626757
  var valid_21626758 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626758 = validateParameter(valid_21626758, JString, required = false,
                                   default = nil)
  if valid_21626758 != nil:
    section.add "X-Amz-Security-Token", valid_21626758
  var valid_21626759 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626759 = validateParameter(valid_21626759, JString, required = false,
                                   default = nil)
  if valid_21626759 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626759
  var valid_21626760 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626760 = validateParameter(valid_21626760, JString, required = false,
                                   default = nil)
  if valid_21626760 != nil:
    section.add "X-Amz-Algorithm", valid_21626760
  var valid_21626761 = header.getOrDefault("X-Amz-Signature")
  valid_21626761 = validateParameter(valid_21626761, JString, required = false,
                                   default = nil)
  if valid_21626761 != nil:
    section.add "X-Amz-Signature", valid_21626761
  var valid_21626762 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626762 = validateParameter(valid_21626762, JString, required = false,
                                   default = nil)
  if valid_21626762 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626762
  var valid_21626763 = header.getOrDefault("X-Amz-Credential")
  valid_21626763 = validateParameter(valid_21626763, JString, required = false,
                                   default = nil)
  if valid_21626763 != nil:
    section.add "X-Amz-Credential", valid_21626763
  result.add "header", section
  ## parameters in `formData` object:
  ##   Options: JArray
  ##          : If specified, restricts the descriptions to only the specified options.
  ##   SolutionStackName: JString
  ##                    : The name of the solution stack whose configuration options you want to describe.
  ##   EnvironmentName: JString
  ##                  : The name of the environment whose configuration options you want to describe.
  ##   ApplicationName: JString
  ##                  : The name of the application associated with the configuration template or environment. Only needed if you want to describe the configuration options associated with either the configuration template or environment.
  ##   PlatformArn: JString
  ##              : The ARN of the custom platform.
  ##   TemplateName: JString
  ##               : The name of the configuration template whose configuration options you want to describe.
  section = newJObject()
  var valid_21626764 = formData.getOrDefault("Options")
  valid_21626764 = validateParameter(valid_21626764, JArray, required = false,
                                   default = nil)
  if valid_21626764 != nil:
    section.add "Options", valid_21626764
  var valid_21626765 = formData.getOrDefault("SolutionStackName")
  valid_21626765 = validateParameter(valid_21626765, JString, required = false,
                                   default = nil)
  if valid_21626765 != nil:
    section.add "SolutionStackName", valid_21626765
  var valid_21626766 = formData.getOrDefault("EnvironmentName")
  valid_21626766 = validateParameter(valid_21626766, JString, required = false,
                                   default = nil)
  if valid_21626766 != nil:
    section.add "EnvironmentName", valid_21626766
  var valid_21626767 = formData.getOrDefault("ApplicationName")
  valid_21626767 = validateParameter(valid_21626767, JString, required = false,
                                   default = nil)
  if valid_21626767 != nil:
    section.add "ApplicationName", valid_21626767
  var valid_21626768 = formData.getOrDefault("PlatformArn")
  valid_21626768 = validateParameter(valid_21626768, JString, required = false,
                                   default = nil)
  if valid_21626768 != nil:
    section.add "PlatformArn", valid_21626768
  var valid_21626769 = formData.getOrDefault("TemplateName")
  valid_21626769 = validateParameter(valid_21626769, JString, required = false,
                                   default = nil)
  if valid_21626769 != nil:
    section.add "TemplateName", valid_21626769
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626770: Call_PostDescribeConfigurationOptions_21626752;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the configuration options that are used in a particular configuration template or environment, or that a specified solution stack defines. The description includes the values the options, their default values, and an indication of the required action on a running environment if an option value is changed.
  ## 
  let valid = call_21626770.validator(path, query, header, formData, body, _)
  let scheme = call_21626770.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626770.makeUrl(scheme.get, call_21626770.host, call_21626770.base,
                               call_21626770.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626770, uri, valid, _)

proc call*(call_21626771: Call_PostDescribeConfigurationOptions_21626752;
          Options: JsonNode = nil; SolutionStackName: string = "";
          EnvironmentName: string = "";
          Action: string = "DescribeConfigurationOptions";
          ApplicationName: string = ""; PlatformArn: string = "";
          TemplateName: string = ""; Version: string = "2010-12-01"): Recallable =
  ## postDescribeConfigurationOptions
  ## Describes the configuration options that are used in a particular configuration template or environment, or that a specified solution stack defines. The description includes the values the options, their default values, and an indication of the required action on a running environment if an option value is changed.
  ##   Options: JArray
  ##          : If specified, restricts the descriptions to only the specified options.
  ##   SolutionStackName: string
  ##                    : The name of the solution stack whose configuration options you want to describe.
  ##   EnvironmentName: string
  ##                  : The name of the environment whose configuration options you want to describe.
  ##   Action: string (required)
  ##   ApplicationName: string
  ##                  : The name of the application associated with the configuration template or environment. Only needed if you want to describe the configuration options associated with either the configuration template or environment.
  ##   PlatformArn: string
  ##              : The ARN of the custom platform.
  ##   TemplateName: string
  ##               : The name of the configuration template whose configuration options you want to describe.
  ##   Version: string (required)
  var query_21626772 = newJObject()
  var formData_21626773 = newJObject()
  if Options != nil:
    formData_21626773.add "Options", Options
  add(formData_21626773, "SolutionStackName", newJString(SolutionStackName))
  add(formData_21626773, "EnvironmentName", newJString(EnvironmentName))
  add(query_21626772, "Action", newJString(Action))
  add(formData_21626773, "ApplicationName", newJString(ApplicationName))
  add(formData_21626773, "PlatformArn", newJString(PlatformArn))
  add(formData_21626773, "TemplateName", newJString(TemplateName))
  add(query_21626772, "Version", newJString(Version))
  result = call_21626771.call(nil, query_21626772, nil, formData_21626773, nil)

var postDescribeConfigurationOptions* = Call_PostDescribeConfigurationOptions_21626752(
    name: "postDescribeConfigurationOptions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationOptions",
    validator: validate_PostDescribeConfigurationOptions_21626753, base: "/",
    makeUrl: url_PostDescribeConfigurationOptions_21626754,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeConfigurationOptions_21626731 = ref object of OpenApiRestCall_21625437
proc url_GetDescribeConfigurationOptions_21626733(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeConfigurationOptions_21626732(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Describes the configuration options that are used in a particular configuration template or environment, or that a specified solution stack defines. The description includes the values the options, their default values, and an indication of the required action on a running environment if an option value is changed.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Options: JArray
  ##          : If specified, restricts the descriptions to only the specified options.
  ##   ApplicationName: JString
  ##                  : The name of the application associated with the configuration template or environment. Only needed if you want to describe the configuration options associated with either the configuration template or environment.
  ##   PlatformArn: JString
  ##              : The ARN of the custom platform.
  ##   EnvironmentName: JString
  ##                  : The name of the environment whose configuration options you want to describe.
  ##   Action: JString (required)
  ##   SolutionStackName: JString
  ##                    : The name of the solution stack whose configuration options you want to describe.
  ##   TemplateName: JString
  ##               : The name of the configuration template whose configuration options you want to describe.
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626734 = query.getOrDefault("Options")
  valid_21626734 = validateParameter(valid_21626734, JArray, required = false,
                                   default = nil)
  if valid_21626734 != nil:
    section.add "Options", valid_21626734
  var valid_21626735 = query.getOrDefault("ApplicationName")
  valid_21626735 = validateParameter(valid_21626735, JString, required = false,
                                   default = nil)
  if valid_21626735 != nil:
    section.add "ApplicationName", valid_21626735
  var valid_21626736 = query.getOrDefault("PlatformArn")
  valid_21626736 = validateParameter(valid_21626736, JString, required = false,
                                   default = nil)
  if valid_21626736 != nil:
    section.add "PlatformArn", valid_21626736
  var valid_21626737 = query.getOrDefault("EnvironmentName")
  valid_21626737 = validateParameter(valid_21626737, JString, required = false,
                                   default = nil)
  if valid_21626737 != nil:
    section.add "EnvironmentName", valid_21626737
  var valid_21626738 = query.getOrDefault("Action")
  valid_21626738 = validateParameter(valid_21626738, JString, required = true, default = newJString(
      "DescribeConfigurationOptions"))
  if valid_21626738 != nil:
    section.add "Action", valid_21626738
  var valid_21626739 = query.getOrDefault("SolutionStackName")
  valid_21626739 = validateParameter(valid_21626739, JString, required = false,
                                   default = nil)
  if valid_21626739 != nil:
    section.add "SolutionStackName", valid_21626739
  var valid_21626740 = query.getOrDefault("TemplateName")
  valid_21626740 = validateParameter(valid_21626740, JString, required = false,
                                   default = nil)
  if valid_21626740 != nil:
    section.add "TemplateName", valid_21626740
  var valid_21626741 = query.getOrDefault("Version")
  valid_21626741 = validateParameter(valid_21626741, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626741 != nil:
    section.add "Version", valid_21626741
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626742 = header.getOrDefault("X-Amz-Date")
  valid_21626742 = validateParameter(valid_21626742, JString, required = false,
                                   default = nil)
  if valid_21626742 != nil:
    section.add "X-Amz-Date", valid_21626742
  var valid_21626743 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626743 = validateParameter(valid_21626743, JString, required = false,
                                   default = nil)
  if valid_21626743 != nil:
    section.add "X-Amz-Security-Token", valid_21626743
  var valid_21626744 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626744 = validateParameter(valid_21626744, JString, required = false,
                                   default = nil)
  if valid_21626744 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626744
  var valid_21626745 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626745 = validateParameter(valid_21626745, JString, required = false,
                                   default = nil)
  if valid_21626745 != nil:
    section.add "X-Amz-Algorithm", valid_21626745
  var valid_21626746 = header.getOrDefault("X-Amz-Signature")
  valid_21626746 = validateParameter(valid_21626746, JString, required = false,
                                   default = nil)
  if valid_21626746 != nil:
    section.add "X-Amz-Signature", valid_21626746
  var valid_21626747 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626747 = validateParameter(valid_21626747, JString, required = false,
                                   default = nil)
  if valid_21626747 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626747
  var valid_21626748 = header.getOrDefault("X-Amz-Credential")
  valid_21626748 = validateParameter(valid_21626748, JString, required = false,
                                   default = nil)
  if valid_21626748 != nil:
    section.add "X-Amz-Credential", valid_21626748
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626749: Call_GetDescribeConfigurationOptions_21626731;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the configuration options that are used in a particular configuration template or environment, or that a specified solution stack defines. The description includes the values the options, their default values, and an indication of the required action on a running environment if an option value is changed.
  ## 
  let valid = call_21626749.validator(path, query, header, formData, body, _)
  let scheme = call_21626749.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626749.makeUrl(scheme.get, call_21626749.host, call_21626749.base,
                               call_21626749.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626749, uri, valid, _)

proc call*(call_21626750: Call_GetDescribeConfigurationOptions_21626731;
          Options: JsonNode = nil; ApplicationName: string = "";
          PlatformArn: string = ""; EnvironmentName: string = "";
          Action: string = "DescribeConfigurationOptions";
          SolutionStackName: string = ""; TemplateName: string = "";
          Version: string = "2010-12-01"): Recallable =
  ## getDescribeConfigurationOptions
  ## Describes the configuration options that are used in a particular configuration template or environment, or that a specified solution stack defines. The description includes the values the options, their default values, and an indication of the required action on a running environment if an option value is changed.
  ##   Options: JArray
  ##          : If specified, restricts the descriptions to only the specified options.
  ##   ApplicationName: string
  ##                  : The name of the application associated with the configuration template or environment. Only needed if you want to describe the configuration options associated with either the configuration template or environment.
  ##   PlatformArn: string
  ##              : The ARN of the custom platform.
  ##   EnvironmentName: string
  ##                  : The name of the environment whose configuration options you want to describe.
  ##   Action: string (required)
  ##   SolutionStackName: string
  ##                    : The name of the solution stack whose configuration options you want to describe.
  ##   TemplateName: string
  ##               : The name of the configuration template whose configuration options you want to describe.
  ##   Version: string (required)
  var query_21626751 = newJObject()
  if Options != nil:
    query_21626751.add "Options", Options
  add(query_21626751, "ApplicationName", newJString(ApplicationName))
  add(query_21626751, "PlatformArn", newJString(PlatformArn))
  add(query_21626751, "EnvironmentName", newJString(EnvironmentName))
  add(query_21626751, "Action", newJString(Action))
  add(query_21626751, "SolutionStackName", newJString(SolutionStackName))
  add(query_21626751, "TemplateName", newJString(TemplateName))
  add(query_21626751, "Version", newJString(Version))
  result = call_21626750.call(nil, query_21626751, nil, nil, nil)

var getDescribeConfigurationOptions* = Call_GetDescribeConfigurationOptions_21626731(
    name: "getDescribeConfigurationOptions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationOptions",
    validator: validate_GetDescribeConfigurationOptions_21626732, base: "/",
    makeUrl: url_GetDescribeConfigurationOptions_21626733,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeConfigurationSettings_21626792 = ref object of OpenApiRestCall_21625437
proc url_PostDescribeConfigurationSettings_21626794(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeConfigurationSettings_21626793(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626795 = query.getOrDefault("Action")
  valid_21626795 = validateParameter(valid_21626795, JString, required = true, default = newJString(
      "DescribeConfigurationSettings"))
  if valid_21626795 != nil:
    section.add "Action", valid_21626795
  var valid_21626796 = query.getOrDefault("Version")
  valid_21626796 = validateParameter(valid_21626796, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626796 != nil:
    section.add "Version", valid_21626796
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626797 = header.getOrDefault("X-Amz-Date")
  valid_21626797 = validateParameter(valid_21626797, JString, required = false,
                                   default = nil)
  if valid_21626797 != nil:
    section.add "X-Amz-Date", valid_21626797
  var valid_21626798 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626798 = validateParameter(valid_21626798, JString, required = false,
                                   default = nil)
  if valid_21626798 != nil:
    section.add "X-Amz-Security-Token", valid_21626798
  var valid_21626799 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626799 = validateParameter(valid_21626799, JString, required = false,
                                   default = nil)
  if valid_21626799 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626799
  var valid_21626800 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626800 = validateParameter(valid_21626800, JString, required = false,
                                   default = nil)
  if valid_21626800 != nil:
    section.add "X-Amz-Algorithm", valid_21626800
  var valid_21626801 = header.getOrDefault("X-Amz-Signature")
  valid_21626801 = validateParameter(valid_21626801, JString, required = false,
                                   default = nil)
  if valid_21626801 != nil:
    section.add "X-Amz-Signature", valid_21626801
  var valid_21626802 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626802 = validateParameter(valid_21626802, JString, required = false,
                                   default = nil)
  if valid_21626802 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626802
  var valid_21626803 = header.getOrDefault("X-Amz-Credential")
  valid_21626803 = validateParameter(valid_21626803, JString, required = false,
                                   default = nil)
  if valid_21626803 != nil:
    section.add "X-Amz-Credential", valid_21626803
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to describe.</p> <p> Condition: You must specify either this or a TemplateName, but not both. If you specify both, AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   ApplicationName: JString (required)
  ##                  : The application for the environment or configuration template.
  ##   TemplateName: JString
  ##               : <p>The name of the configuration template to describe.</p> <p> Conditional: You must specify either this parameter or an EnvironmentName, but not both. If you specify both, AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. If you do not specify either, AWS Elastic Beanstalk returns a <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_21626804 = formData.getOrDefault("EnvironmentName")
  valid_21626804 = validateParameter(valid_21626804, JString, required = false,
                                   default = nil)
  if valid_21626804 != nil:
    section.add "EnvironmentName", valid_21626804
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_21626805 = formData.getOrDefault("ApplicationName")
  valid_21626805 = validateParameter(valid_21626805, JString, required = true,
                                   default = nil)
  if valid_21626805 != nil:
    section.add "ApplicationName", valid_21626805
  var valid_21626806 = formData.getOrDefault("TemplateName")
  valid_21626806 = validateParameter(valid_21626806, JString, required = false,
                                   default = nil)
  if valid_21626806 != nil:
    section.add "TemplateName", valid_21626806
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626807: Call_PostDescribeConfigurationSettings_21626792;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a description of the settings for the specified configuration set, that is, either a configuration template or the configuration set associated with a running environment.</p> <p>When describing the settings for the configuration set associated with a running environment, it is possible to receive two sets of setting descriptions. One is the deployed configuration set, and the other is a draft configuration of an environment that is either in the process of deployment or that failed to deploy.</p> <p>Related Topics</p> <ul> <li> <p> <a>DeleteEnvironmentConfiguration</a> </p> </li> </ul>
  ## 
  let valid = call_21626807.validator(path, query, header, formData, body, _)
  let scheme = call_21626807.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626807.makeUrl(scheme.get, call_21626807.host, call_21626807.base,
                               call_21626807.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626807, uri, valid, _)

proc call*(call_21626808: Call_PostDescribeConfigurationSettings_21626792;
          ApplicationName: string; EnvironmentName: string = "";
          Action: string = "DescribeConfigurationSettings";
          TemplateName: string = ""; Version: string = "2010-12-01"): Recallable =
  ## postDescribeConfigurationSettings
  ## <p>Returns a description of the settings for the specified configuration set, that is, either a configuration template or the configuration set associated with a running environment.</p> <p>When describing the settings for the configuration set associated with a running environment, it is possible to receive two sets of setting descriptions. One is the deployed configuration set, and the other is a draft configuration of an environment that is either in the process of deployment or that failed to deploy.</p> <p>Related Topics</p> <ul> <li> <p> <a>DeleteEnvironmentConfiguration</a> </p> </li> </ul>
  ##   EnvironmentName: string
  ##                  : <p>The name of the environment to describe.</p> <p> Condition: You must specify either this or a TemplateName, but not both. If you specify both, AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Action: string (required)
  ##   ApplicationName: string (required)
  ##                  : The application for the environment or configuration template.
  ##   TemplateName: string
  ##               : <p>The name of the configuration template to describe.</p> <p> Conditional: You must specify either this parameter or an EnvironmentName, but not both. If you specify both, AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. If you do not specify either, AWS Elastic Beanstalk returns a <code>MissingRequiredParameter</code> error. </p>
  ##   Version: string (required)
  var query_21626809 = newJObject()
  var formData_21626810 = newJObject()
  add(formData_21626810, "EnvironmentName", newJString(EnvironmentName))
  add(query_21626809, "Action", newJString(Action))
  add(formData_21626810, "ApplicationName", newJString(ApplicationName))
  add(formData_21626810, "TemplateName", newJString(TemplateName))
  add(query_21626809, "Version", newJString(Version))
  result = call_21626808.call(nil, query_21626809, nil, formData_21626810, nil)

var postDescribeConfigurationSettings* = Call_PostDescribeConfigurationSettings_21626792(
    name: "postDescribeConfigurationSettings", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationSettings",
    validator: validate_PostDescribeConfigurationSettings_21626793, base: "/",
    makeUrl: url_PostDescribeConfigurationSettings_21626794,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeConfigurationSettings_21626774 = ref object of OpenApiRestCall_21625437
proc url_GetDescribeConfigurationSettings_21626776(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeConfigurationSettings_21626775(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   TemplateName: JString
  ##               : <p>The name of the configuration template to describe.</p> <p> Conditional: You must specify either this parameter or an EnvironmentName, but not both. If you specify both, AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. If you do not specify either, AWS Elastic Beanstalk returns a <code>MissingRequiredParameter</code> error. </p>
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_21626777 = query.getOrDefault("ApplicationName")
  valid_21626777 = validateParameter(valid_21626777, JString, required = true,
                                   default = nil)
  if valid_21626777 != nil:
    section.add "ApplicationName", valid_21626777
  var valid_21626778 = query.getOrDefault("EnvironmentName")
  valid_21626778 = validateParameter(valid_21626778, JString, required = false,
                                   default = nil)
  if valid_21626778 != nil:
    section.add "EnvironmentName", valid_21626778
  var valid_21626779 = query.getOrDefault("Action")
  valid_21626779 = validateParameter(valid_21626779, JString, required = true, default = newJString(
      "DescribeConfigurationSettings"))
  if valid_21626779 != nil:
    section.add "Action", valid_21626779
  var valid_21626780 = query.getOrDefault("TemplateName")
  valid_21626780 = validateParameter(valid_21626780, JString, required = false,
                                   default = nil)
  if valid_21626780 != nil:
    section.add "TemplateName", valid_21626780
  var valid_21626781 = query.getOrDefault("Version")
  valid_21626781 = validateParameter(valid_21626781, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626781 != nil:
    section.add "Version", valid_21626781
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626782 = header.getOrDefault("X-Amz-Date")
  valid_21626782 = validateParameter(valid_21626782, JString, required = false,
                                   default = nil)
  if valid_21626782 != nil:
    section.add "X-Amz-Date", valid_21626782
  var valid_21626783 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626783 = validateParameter(valid_21626783, JString, required = false,
                                   default = nil)
  if valid_21626783 != nil:
    section.add "X-Amz-Security-Token", valid_21626783
  var valid_21626784 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626784 = validateParameter(valid_21626784, JString, required = false,
                                   default = nil)
  if valid_21626784 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626784
  var valid_21626785 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626785 = validateParameter(valid_21626785, JString, required = false,
                                   default = nil)
  if valid_21626785 != nil:
    section.add "X-Amz-Algorithm", valid_21626785
  var valid_21626786 = header.getOrDefault("X-Amz-Signature")
  valid_21626786 = validateParameter(valid_21626786, JString, required = false,
                                   default = nil)
  if valid_21626786 != nil:
    section.add "X-Amz-Signature", valid_21626786
  var valid_21626787 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626787 = validateParameter(valid_21626787, JString, required = false,
                                   default = nil)
  if valid_21626787 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626787
  var valid_21626788 = header.getOrDefault("X-Amz-Credential")
  valid_21626788 = validateParameter(valid_21626788, JString, required = false,
                                   default = nil)
  if valid_21626788 != nil:
    section.add "X-Amz-Credential", valid_21626788
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626789: Call_GetDescribeConfigurationSettings_21626774;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a description of the settings for the specified configuration set, that is, either a configuration template or the configuration set associated with a running environment.</p> <p>When describing the settings for the configuration set associated with a running environment, it is possible to receive two sets of setting descriptions. One is the deployed configuration set, and the other is a draft configuration of an environment that is either in the process of deployment or that failed to deploy.</p> <p>Related Topics</p> <ul> <li> <p> <a>DeleteEnvironmentConfiguration</a> </p> </li> </ul>
  ## 
  let valid = call_21626789.validator(path, query, header, formData, body, _)
  let scheme = call_21626789.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626789.makeUrl(scheme.get, call_21626789.host, call_21626789.base,
                               call_21626789.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626789, uri, valid, _)

proc call*(call_21626790: Call_GetDescribeConfigurationSettings_21626774;
          ApplicationName: string; EnvironmentName: string = "";
          Action: string = "DescribeConfigurationSettings";
          TemplateName: string = ""; Version: string = "2010-12-01"): Recallable =
  ## getDescribeConfigurationSettings
  ## <p>Returns a description of the settings for the specified configuration set, that is, either a configuration template or the configuration set associated with a running environment.</p> <p>When describing the settings for the configuration set associated with a running environment, it is possible to receive two sets of setting descriptions. One is the deployed configuration set, and the other is a draft configuration of an environment that is either in the process of deployment or that failed to deploy.</p> <p>Related Topics</p> <ul> <li> <p> <a>DeleteEnvironmentConfiguration</a> </p> </li> </ul>
  ##   ApplicationName: string (required)
  ##                  : The application for the environment or configuration template.
  ##   EnvironmentName: string
  ##                  : <p>The name of the environment to describe.</p> <p> Condition: You must specify either this or a TemplateName, but not both. If you specify both, AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Action: string (required)
  ##   TemplateName: string
  ##               : <p>The name of the configuration template to describe.</p> <p> Conditional: You must specify either this parameter or an EnvironmentName, but not both. If you specify both, AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. If you do not specify either, AWS Elastic Beanstalk returns a <code>MissingRequiredParameter</code> error. </p>
  ##   Version: string (required)
  var query_21626791 = newJObject()
  add(query_21626791, "ApplicationName", newJString(ApplicationName))
  add(query_21626791, "EnvironmentName", newJString(EnvironmentName))
  add(query_21626791, "Action", newJString(Action))
  add(query_21626791, "TemplateName", newJString(TemplateName))
  add(query_21626791, "Version", newJString(Version))
  result = call_21626790.call(nil, query_21626791, nil, nil, nil)

var getDescribeConfigurationSettings* = Call_GetDescribeConfigurationSettings_21626774(
    name: "getDescribeConfigurationSettings", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationSettings",
    validator: validate_GetDescribeConfigurationSettings_21626775, base: "/",
    makeUrl: url_GetDescribeConfigurationSettings_21626776,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentHealth_21626829 = ref object of OpenApiRestCall_21625437
proc url_PostDescribeEnvironmentHealth_21626831(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEnvironmentHealth_21626830(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626832 = query.getOrDefault("Action")
  valid_21626832 = validateParameter(valid_21626832, JString, required = true, default = newJString(
      "DescribeEnvironmentHealth"))
  if valid_21626832 != nil:
    section.add "Action", valid_21626832
  var valid_21626833 = query.getOrDefault("Version")
  valid_21626833 = validateParameter(valid_21626833, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626833 != nil:
    section.add "Version", valid_21626833
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626834 = header.getOrDefault("X-Amz-Date")
  valid_21626834 = validateParameter(valid_21626834, JString, required = false,
                                   default = nil)
  if valid_21626834 != nil:
    section.add "X-Amz-Date", valid_21626834
  var valid_21626835 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626835 = validateParameter(valid_21626835, JString, required = false,
                                   default = nil)
  if valid_21626835 != nil:
    section.add "X-Amz-Security-Token", valid_21626835
  var valid_21626836 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626836 = validateParameter(valid_21626836, JString, required = false,
                                   default = nil)
  if valid_21626836 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626836
  var valid_21626837 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626837 = validateParameter(valid_21626837, JString, required = false,
                                   default = nil)
  if valid_21626837 != nil:
    section.add "X-Amz-Algorithm", valid_21626837
  var valid_21626838 = header.getOrDefault("X-Amz-Signature")
  valid_21626838 = validateParameter(valid_21626838, JString, required = false,
                                   default = nil)
  if valid_21626838 != nil:
    section.add "X-Amz-Signature", valid_21626838
  var valid_21626839 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626839 = validateParameter(valid_21626839, JString, required = false,
                                   default = nil)
  if valid_21626839 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626839
  var valid_21626840 = header.getOrDefault("X-Amz-Credential")
  valid_21626840 = validateParameter(valid_21626840, JString, required = false,
                                   default = nil)
  if valid_21626840 != nil:
    section.add "X-Amz-Credential", valid_21626840
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentId: JString
  ##                : <p>Specify the environment by ID.</p> <p>You must specify either this or an EnvironmentName, or both.</p>
  ##   EnvironmentName: JString
  ##                  : <p>Specify the environment by name.</p> <p>You must specify either this or an EnvironmentName, or both.</p>
  ##   AttributeNames: JArray
  ##                 : Specify the response elements to return. To retrieve all attributes, set to <code>All</code>. If no attribute names are specified, returns the name of the environment.
  section = newJObject()
  var valid_21626841 = formData.getOrDefault("EnvironmentId")
  valid_21626841 = validateParameter(valid_21626841, JString, required = false,
                                   default = nil)
  if valid_21626841 != nil:
    section.add "EnvironmentId", valid_21626841
  var valid_21626842 = formData.getOrDefault("EnvironmentName")
  valid_21626842 = validateParameter(valid_21626842, JString, required = false,
                                   default = nil)
  if valid_21626842 != nil:
    section.add "EnvironmentName", valid_21626842
  var valid_21626843 = formData.getOrDefault("AttributeNames")
  valid_21626843 = validateParameter(valid_21626843, JArray, required = false,
                                   default = nil)
  if valid_21626843 != nil:
    section.add "AttributeNames", valid_21626843
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626844: Call_PostDescribeEnvironmentHealth_21626829;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about the overall health of the specified environment. The <b>DescribeEnvironmentHealth</b> operation is only available with AWS Elastic Beanstalk Enhanced Health.
  ## 
  let valid = call_21626844.validator(path, query, header, formData, body, _)
  let scheme = call_21626844.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626844.makeUrl(scheme.get, call_21626844.host, call_21626844.base,
                               call_21626844.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626844, uri, valid, _)

proc call*(call_21626845: Call_PostDescribeEnvironmentHealth_21626829;
          EnvironmentId: string = ""; EnvironmentName: string = "";
          Action: string = "DescribeEnvironmentHealth";
          AttributeNames: JsonNode = nil; Version: string = "2010-12-01"): Recallable =
  ## postDescribeEnvironmentHealth
  ## Returns information about the overall health of the specified environment. The <b>DescribeEnvironmentHealth</b> operation is only available with AWS Elastic Beanstalk Enhanced Health.
  ##   EnvironmentId: string
  ##                : <p>Specify the environment by ID.</p> <p>You must specify either this or an EnvironmentName, or both.</p>
  ##   EnvironmentName: string
  ##                  : <p>Specify the environment by name.</p> <p>You must specify either this or an EnvironmentName, or both.</p>
  ##   Action: string (required)
  ##   AttributeNames: JArray
  ##                 : Specify the response elements to return. To retrieve all attributes, set to <code>All</code>. If no attribute names are specified, returns the name of the environment.
  ##   Version: string (required)
  var query_21626846 = newJObject()
  var formData_21626847 = newJObject()
  add(formData_21626847, "EnvironmentId", newJString(EnvironmentId))
  add(formData_21626847, "EnvironmentName", newJString(EnvironmentName))
  add(query_21626846, "Action", newJString(Action))
  if AttributeNames != nil:
    formData_21626847.add "AttributeNames", AttributeNames
  add(query_21626846, "Version", newJString(Version))
  result = call_21626845.call(nil, query_21626846, nil, formData_21626847, nil)

var postDescribeEnvironmentHealth* = Call_PostDescribeEnvironmentHealth_21626829(
    name: "postDescribeEnvironmentHealth", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentHealth",
    validator: validate_PostDescribeEnvironmentHealth_21626830, base: "/",
    makeUrl: url_PostDescribeEnvironmentHealth_21626831,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentHealth_21626811 = ref object of OpenApiRestCall_21625437
proc url_GetDescribeEnvironmentHealth_21626813(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEnvironmentHealth_21626812(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   EnvironmentId: JString
  ##                : <p>Specify the environment by ID.</p> <p>You must specify either this or an EnvironmentName, or both.</p>
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626814 = query.getOrDefault("AttributeNames")
  valid_21626814 = validateParameter(valid_21626814, JArray, required = false,
                                   default = nil)
  if valid_21626814 != nil:
    section.add "AttributeNames", valid_21626814
  var valid_21626815 = query.getOrDefault("EnvironmentName")
  valid_21626815 = validateParameter(valid_21626815, JString, required = false,
                                   default = nil)
  if valid_21626815 != nil:
    section.add "EnvironmentName", valid_21626815
  var valid_21626816 = query.getOrDefault("Action")
  valid_21626816 = validateParameter(valid_21626816, JString, required = true, default = newJString(
      "DescribeEnvironmentHealth"))
  if valid_21626816 != nil:
    section.add "Action", valid_21626816
  var valid_21626817 = query.getOrDefault("EnvironmentId")
  valid_21626817 = validateParameter(valid_21626817, JString, required = false,
                                   default = nil)
  if valid_21626817 != nil:
    section.add "EnvironmentId", valid_21626817
  var valid_21626818 = query.getOrDefault("Version")
  valid_21626818 = validateParameter(valid_21626818, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626818 != nil:
    section.add "Version", valid_21626818
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626819 = header.getOrDefault("X-Amz-Date")
  valid_21626819 = validateParameter(valid_21626819, JString, required = false,
                                   default = nil)
  if valid_21626819 != nil:
    section.add "X-Amz-Date", valid_21626819
  var valid_21626820 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626820 = validateParameter(valid_21626820, JString, required = false,
                                   default = nil)
  if valid_21626820 != nil:
    section.add "X-Amz-Security-Token", valid_21626820
  var valid_21626821 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626821 = validateParameter(valid_21626821, JString, required = false,
                                   default = nil)
  if valid_21626821 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626821
  var valid_21626822 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626822 = validateParameter(valid_21626822, JString, required = false,
                                   default = nil)
  if valid_21626822 != nil:
    section.add "X-Amz-Algorithm", valid_21626822
  var valid_21626823 = header.getOrDefault("X-Amz-Signature")
  valid_21626823 = validateParameter(valid_21626823, JString, required = false,
                                   default = nil)
  if valid_21626823 != nil:
    section.add "X-Amz-Signature", valid_21626823
  var valid_21626824 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626824 = validateParameter(valid_21626824, JString, required = false,
                                   default = nil)
  if valid_21626824 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626824
  var valid_21626825 = header.getOrDefault("X-Amz-Credential")
  valid_21626825 = validateParameter(valid_21626825, JString, required = false,
                                   default = nil)
  if valid_21626825 != nil:
    section.add "X-Amz-Credential", valid_21626825
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626826: Call_GetDescribeEnvironmentHealth_21626811;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about the overall health of the specified environment. The <b>DescribeEnvironmentHealth</b> operation is only available with AWS Elastic Beanstalk Enhanced Health.
  ## 
  let valid = call_21626826.validator(path, query, header, formData, body, _)
  let scheme = call_21626826.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626826.makeUrl(scheme.get, call_21626826.host, call_21626826.base,
                               call_21626826.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626826, uri, valid, _)

proc call*(call_21626827: Call_GetDescribeEnvironmentHealth_21626811;
          AttributeNames: JsonNode = nil; EnvironmentName: string = "";
          Action: string = "DescribeEnvironmentHealth"; EnvironmentId: string = "";
          Version: string = "2010-12-01"): Recallable =
  ## getDescribeEnvironmentHealth
  ## Returns information about the overall health of the specified environment. The <b>DescribeEnvironmentHealth</b> operation is only available with AWS Elastic Beanstalk Enhanced Health.
  ##   AttributeNames: JArray
  ##                 : Specify the response elements to return. To retrieve all attributes, set to <code>All</code>. If no attribute names are specified, returns the name of the environment.
  ##   EnvironmentName: string
  ##                  : <p>Specify the environment by name.</p> <p>You must specify either this or an EnvironmentName, or both.</p>
  ##   Action: string (required)
  ##   EnvironmentId: string
  ##                : <p>Specify the environment by ID.</p> <p>You must specify either this or an EnvironmentName, or both.</p>
  ##   Version: string (required)
  var query_21626828 = newJObject()
  if AttributeNames != nil:
    query_21626828.add "AttributeNames", AttributeNames
  add(query_21626828, "EnvironmentName", newJString(EnvironmentName))
  add(query_21626828, "Action", newJString(Action))
  add(query_21626828, "EnvironmentId", newJString(EnvironmentId))
  add(query_21626828, "Version", newJString(Version))
  result = call_21626827.call(nil, query_21626828, nil, nil, nil)

var getDescribeEnvironmentHealth* = Call_GetDescribeEnvironmentHealth_21626811(
    name: "getDescribeEnvironmentHealth", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentHealth",
    validator: validate_GetDescribeEnvironmentHealth_21626812, base: "/",
    makeUrl: url_GetDescribeEnvironmentHealth_21626813,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentManagedActionHistory_21626867 = ref object of OpenApiRestCall_21625437
proc url_PostDescribeEnvironmentManagedActionHistory_21626869(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEnvironmentManagedActionHistory_21626868(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626870 = query.getOrDefault("Action")
  valid_21626870 = validateParameter(valid_21626870, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActionHistory"))
  if valid_21626870 != nil:
    section.add "Action", valid_21626870
  var valid_21626871 = query.getOrDefault("Version")
  valid_21626871 = validateParameter(valid_21626871, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626871 != nil:
    section.add "Version", valid_21626871
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626872 = header.getOrDefault("X-Amz-Date")
  valid_21626872 = validateParameter(valid_21626872, JString, required = false,
                                   default = nil)
  if valid_21626872 != nil:
    section.add "X-Amz-Date", valid_21626872
  var valid_21626873 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626873 = validateParameter(valid_21626873, JString, required = false,
                                   default = nil)
  if valid_21626873 != nil:
    section.add "X-Amz-Security-Token", valid_21626873
  var valid_21626874 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626874 = validateParameter(valid_21626874, JString, required = false,
                                   default = nil)
  if valid_21626874 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626874
  var valid_21626875 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626875 = validateParameter(valid_21626875, JString, required = false,
                                   default = nil)
  if valid_21626875 != nil:
    section.add "X-Amz-Algorithm", valid_21626875
  var valid_21626876 = header.getOrDefault("X-Amz-Signature")
  valid_21626876 = validateParameter(valid_21626876, JString, required = false,
                                   default = nil)
  if valid_21626876 != nil:
    section.add "X-Amz-Signature", valid_21626876
  var valid_21626877 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626877 = validateParameter(valid_21626877, JString, required = false,
                                   default = nil)
  if valid_21626877 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626877
  var valid_21626878 = header.getOrDefault("X-Amz-Credential")
  valid_21626878 = validateParameter(valid_21626878, JString, required = false,
                                   default = nil)
  if valid_21626878 != nil:
    section.add "X-Amz-Credential", valid_21626878
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : The pagination token returned by a previous request.
  ##   EnvironmentId: JString
  ##                : The environment ID of the target environment.
  ##   EnvironmentName: JString
  ##                  : The name of the target environment.
  ##   MaxItems: JInt
  ##           : The maximum number of items to return for a single request.
  section = newJObject()
  var valid_21626879 = formData.getOrDefault("NextToken")
  valid_21626879 = validateParameter(valid_21626879, JString, required = false,
                                   default = nil)
  if valid_21626879 != nil:
    section.add "NextToken", valid_21626879
  var valid_21626880 = formData.getOrDefault("EnvironmentId")
  valid_21626880 = validateParameter(valid_21626880, JString, required = false,
                                   default = nil)
  if valid_21626880 != nil:
    section.add "EnvironmentId", valid_21626880
  var valid_21626881 = formData.getOrDefault("EnvironmentName")
  valid_21626881 = validateParameter(valid_21626881, JString, required = false,
                                   default = nil)
  if valid_21626881 != nil:
    section.add "EnvironmentName", valid_21626881
  var valid_21626882 = formData.getOrDefault("MaxItems")
  valid_21626882 = validateParameter(valid_21626882, JInt, required = false,
                                   default = nil)
  if valid_21626882 != nil:
    section.add "MaxItems", valid_21626882
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626883: Call_PostDescribeEnvironmentManagedActionHistory_21626867;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists an environment's completed and failed managed actions.
  ## 
  let valid = call_21626883.validator(path, query, header, formData, body, _)
  let scheme = call_21626883.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626883.makeUrl(scheme.get, call_21626883.host, call_21626883.base,
                               call_21626883.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626883, uri, valid, _)

proc call*(call_21626884: Call_PostDescribeEnvironmentManagedActionHistory_21626867;
          NextToken: string = ""; EnvironmentId: string = "";
          EnvironmentName: string = "";
          Action: string = "DescribeEnvironmentManagedActionHistory";
          MaxItems: int = 0; Version: string = "2010-12-01"): Recallable =
  ## postDescribeEnvironmentManagedActionHistory
  ## Lists an environment's completed and failed managed actions.
  ##   NextToken: string
  ##            : The pagination token returned by a previous request.
  ##   EnvironmentId: string
  ##                : The environment ID of the target environment.
  ##   EnvironmentName: string
  ##                  : The name of the target environment.
  ##   Action: string (required)
  ##   MaxItems: int
  ##           : The maximum number of items to return for a single request.
  ##   Version: string (required)
  var query_21626885 = newJObject()
  var formData_21626886 = newJObject()
  add(formData_21626886, "NextToken", newJString(NextToken))
  add(formData_21626886, "EnvironmentId", newJString(EnvironmentId))
  add(formData_21626886, "EnvironmentName", newJString(EnvironmentName))
  add(query_21626885, "Action", newJString(Action))
  add(formData_21626886, "MaxItems", newJInt(MaxItems))
  add(query_21626885, "Version", newJString(Version))
  result = call_21626884.call(nil, query_21626885, nil, formData_21626886, nil)

var postDescribeEnvironmentManagedActionHistory* = Call_PostDescribeEnvironmentManagedActionHistory_21626867(
    name: "postDescribeEnvironmentManagedActionHistory",
    meth: HttpMethod.HttpPost, host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActionHistory",
    validator: validate_PostDescribeEnvironmentManagedActionHistory_21626868,
    base: "/", makeUrl: url_PostDescribeEnvironmentManagedActionHistory_21626869,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentManagedActionHistory_21626848 = ref object of OpenApiRestCall_21625437
proc url_GetDescribeEnvironmentManagedActionHistory_21626850(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEnvironmentManagedActionHistory_21626849(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Lists an environment's completed and failed managed actions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The pagination token returned by a previous request.
  ##   EnvironmentName: JString
  ##                  : The name of the target environment.
  ##   Action: JString (required)
  ##   EnvironmentId: JString
  ##                : The environment ID of the target environment.
  ##   MaxItems: JInt
  ##           : The maximum number of items to return for a single request.
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626851 = query.getOrDefault("NextToken")
  valid_21626851 = validateParameter(valid_21626851, JString, required = false,
                                   default = nil)
  if valid_21626851 != nil:
    section.add "NextToken", valid_21626851
  var valid_21626852 = query.getOrDefault("EnvironmentName")
  valid_21626852 = validateParameter(valid_21626852, JString, required = false,
                                   default = nil)
  if valid_21626852 != nil:
    section.add "EnvironmentName", valid_21626852
  var valid_21626853 = query.getOrDefault("Action")
  valid_21626853 = validateParameter(valid_21626853, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActionHistory"))
  if valid_21626853 != nil:
    section.add "Action", valid_21626853
  var valid_21626854 = query.getOrDefault("EnvironmentId")
  valid_21626854 = validateParameter(valid_21626854, JString, required = false,
                                   default = nil)
  if valid_21626854 != nil:
    section.add "EnvironmentId", valid_21626854
  var valid_21626855 = query.getOrDefault("MaxItems")
  valid_21626855 = validateParameter(valid_21626855, JInt, required = false,
                                   default = nil)
  if valid_21626855 != nil:
    section.add "MaxItems", valid_21626855
  var valid_21626856 = query.getOrDefault("Version")
  valid_21626856 = validateParameter(valid_21626856, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626856 != nil:
    section.add "Version", valid_21626856
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626857 = header.getOrDefault("X-Amz-Date")
  valid_21626857 = validateParameter(valid_21626857, JString, required = false,
                                   default = nil)
  if valid_21626857 != nil:
    section.add "X-Amz-Date", valid_21626857
  var valid_21626858 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626858 = validateParameter(valid_21626858, JString, required = false,
                                   default = nil)
  if valid_21626858 != nil:
    section.add "X-Amz-Security-Token", valid_21626858
  var valid_21626859 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626859 = validateParameter(valid_21626859, JString, required = false,
                                   default = nil)
  if valid_21626859 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626859
  var valid_21626860 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626860 = validateParameter(valid_21626860, JString, required = false,
                                   default = nil)
  if valid_21626860 != nil:
    section.add "X-Amz-Algorithm", valid_21626860
  var valid_21626861 = header.getOrDefault("X-Amz-Signature")
  valid_21626861 = validateParameter(valid_21626861, JString, required = false,
                                   default = nil)
  if valid_21626861 != nil:
    section.add "X-Amz-Signature", valid_21626861
  var valid_21626862 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626862 = validateParameter(valid_21626862, JString, required = false,
                                   default = nil)
  if valid_21626862 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626862
  var valid_21626863 = header.getOrDefault("X-Amz-Credential")
  valid_21626863 = validateParameter(valid_21626863, JString, required = false,
                                   default = nil)
  if valid_21626863 != nil:
    section.add "X-Amz-Credential", valid_21626863
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626864: Call_GetDescribeEnvironmentManagedActionHistory_21626848;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists an environment's completed and failed managed actions.
  ## 
  let valid = call_21626864.validator(path, query, header, formData, body, _)
  let scheme = call_21626864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626864.makeUrl(scheme.get, call_21626864.host, call_21626864.base,
                               call_21626864.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626864, uri, valid, _)

proc call*(call_21626865: Call_GetDescribeEnvironmentManagedActionHistory_21626848;
          NextToken: string = ""; EnvironmentName: string = "";
          Action: string = "DescribeEnvironmentManagedActionHistory";
          EnvironmentId: string = ""; MaxItems: int = 0; Version: string = "2010-12-01"): Recallable =
  ## getDescribeEnvironmentManagedActionHistory
  ## Lists an environment's completed and failed managed actions.
  ##   NextToken: string
  ##            : The pagination token returned by a previous request.
  ##   EnvironmentName: string
  ##                  : The name of the target environment.
  ##   Action: string (required)
  ##   EnvironmentId: string
  ##                : The environment ID of the target environment.
  ##   MaxItems: int
  ##           : The maximum number of items to return for a single request.
  ##   Version: string (required)
  var query_21626866 = newJObject()
  add(query_21626866, "NextToken", newJString(NextToken))
  add(query_21626866, "EnvironmentName", newJString(EnvironmentName))
  add(query_21626866, "Action", newJString(Action))
  add(query_21626866, "EnvironmentId", newJString(EnvironmentId))
  add(query_21626866, "MaxItems", newJInt(MaxItems))
  add(query_21626866, "Version", newJString(Version))
  result = call_21626865.call(nil, query_21626866, nil, nil, nil)

var getDescribeEnvironmentManagedActionHistory* = Call_GetDescribeEnvironmentManagedActionHistory_21626848(
    name: "getDescribeEnvironmentManagedActionHistory", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActionHistory",
    validator: validate_GetDescribeEnvironmentManagedActionHistory_21626849,
    base: "/", makeUrl: url_GetDescribeEnvironmentManagedActionHistory_21626850,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentManagedActions_21626905 = ref object of OpenApiRestCall_21625437
proc url_PostDescribeEnvironmentManagedActions_21626907(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEnvironmentManagedActions_21626906(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626908 = query.getOrDefault("Action")
  valid_21626908 = validateParameter(valid_21626908, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActions"))
  if valid_21626908 != nil:
    section.add "Action", valid_21626908
  var valid_21626909 = query.getOrDefault("Version")
  valid_21626909 = validateParameter(valid_21626909, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626909 != nil:
    section.add "Version", valid_21626909
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626910 = header.getOrDefault("X-Amz-Date")
  valid_21626910 = validateParameter(valid_21626910, JString, required = false,
                                   default = nil)
  if valid_21626910 != nil:
    section.add "X-Amz-Date", valid_21626910
  var valid_21626911 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626911 = validateParameter(valid_21626911, JString, required = false,
                                   default = nil)
  if valid_21626911 != nil:
    section.add "X-Amz-Security-Token", valid_21626911
  var valid_21626912 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626912 = validateParameter(valid_21626912, JString, required = false,
                                   default = nil)
  if valid_21626912 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626912
  var valid_21626913 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626913 = validateParameter(valid_21626913, JString, required = false,
                                   default = nil)
  if valid_21626913 != nil:
    section.add "X-Amz-Algorithm", valid_21626913
  var valid_21626914 = header.getOrDefault("X-Amz-Signature")
  valid_21626914 = validateParameter(valid_21626914, JString, required = false,
                                   default = nil)
  if valid_21626914 != nil:
    section.add "X-Amz-Signature", valid_21626914
  var valid_21626915 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626915 = validateParameter(valid_21626915, JString, required = false,
                                   default = nil)
  if valid_21626915 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626915
  var valid_21626916 = header.getOrDefault("X-Amz-Credential")
  valid_21626916 = validateParameter(valid_21626916, JString, required = false,
                                   default = nil)
  if valid_21626916 != nil:
    section.add "X-Amz-Credential", valid_21626916
  result.add "header", section
  ## parameters in `formData` object:
  ##   Status: JString
  ##         : To show only actions with a particular status, specify a status.
  ##   EnvironmentId: JString
  ##                : The environment ID of the target environment.
  ##   EnvironmentName: JString
  ##                  : The name of the target environment.
  section = newJObject()
  var valid_21626917 = formData.getOrDefault("Status")
  valid_21626917 = validateParameter(valid_21626917, JString, required = false,
                                   default = newJString("Scheduled"))
  if valid_21626917 != nil:
    section.add "Status", valid_21626917
  var valid_21626918 = formData.getOrDefault("EnvironmentId")
  valid_21626918 = validateParameter(valid_21626918, JString, required = false,
                                   default = nil)
  if valid_21626918 != nil:
    section.add "EnvironmentId", valid_21626918
  var valid_21626919 = formData.getOrDefault("EnvironmentName")
  valid_21626919 = validateParameter(valid_21626919, JString, required = false,
                                   default = nil)
  if valid_21626919 != nil:
    section.add "EnvironmentName", valid_21626919
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626920: Call_PostDescribeEnvironmentManagedActions_21626905;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists an environment's upcoming and in-progress managed actions.
  ## 
  let valid = call_21626920.validator(path, query, header, formData, body, _)
  let scheme = call_21626920.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626920.makeUrl(scheme.get, call_21626920.host, call_21626920.base,
                               call_21626920.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626920, uri, valid, _)

proc call*(call_21626921: Call_PostDescribeEnvironmentManagedActions_21626905;
          Status: string = "Scheduled"; EnvironmentId: string = "";
          EnvironmentName: string = "";
          Action: string = "DescribeEnvironmentManagedActions";
          Version: string = "2010-12-01"): Recallable =
  ## postDescribeEnvironmentManagedActions
  ## Lists an environment's upcoming and in-progress managed actions.
  ##   Status: string
  ##         : To show only actions with a particular status, specify a status.
  ##   EnvironmentId: string
  ##                : The environment ID of the target environment.
  ##   EnvironmentName: string
  ##                  : The name of the target environment.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626922 = newJObject()
  var formData_21626923 = newJObject()
  add(formData_21626923, "Status", newJString(Status))
  add(formData_21626923, "EnvironmentId", newJString(EnvironmentId))
  add(formData_21626923, "EnvironmentName", newJString(EnvironmentName))
  add(query_21626922, "Action", newJString(Action))
  add(query_21626922, "Version", newJString(Version))
  result = call_21626921.call(nil, query_21626922, nil, formData_21626923, nil)

var postDescribeEnvironmentManagedActions* = Call_PostDescribeEnvironmentManagedActions_21626905(
    name: "postDescribeEnvironmentManagedActions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActions",
    validator: validate_PostDescribeEnvironmentManagedActions_21626906, base: "/",
    makeUrl: url_PostDescribeEnvironmentManagedActions_21626907,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentManagedActions_21626887 = ref object of OpenApiRestCall_21625437
proc url_GetDescribeEnvironmentManagedActions_21626889(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEnvironmentManagedActions_21626888(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   EnvironmentId: JString
  ##                : The environment ID of the target environment.
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626890 = query.getOrDefault("Status")
  valid_21626890 = validateParameter(valid_21626890, JString, required = false,
                                   default = newJString("Scheduled"))
  if valid_21626890 != nil:
    section.add "Status", valid_21626890
  var valid_21626891 = query.getOrDefault("EnvironmentName")
  valid_21626891 = validateParameter(valid_21626891, JString, required = false,
                                   default = nil)
  if valid_21626891 != nil:
    section.add "EnvironmentName", valid_21626891
  var valid_21626892 = query.getOrDefault("Action")
  valid_21626892 = validateParameter(valid_21626892, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActions"))
  if valid_21626892 != nil:
    section.add "Action", valid_21626892
  var valid_21626893 = query.getOrDefault("EnvironmentId")
  valid_21626893 = validateParameter(valid_21626893, JString, required = false,
                                   default = nil)
  if valid_21626893 != nil:
    section.add "EnvironmentId", valid_21626893
  var valid_21626894 = query.getOrDefault("Version")
  valid_21626894 = validateParameter(valid_21626894, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626894 != nil:
    section.add "Version", valid_21626894
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626895 = header.getOrDefault("X-Amz-Date")
  valid_21626895 = validateParameter(valid_21626895, JString, required = false,
                                   default = nil)
  if valid_21626895 != nil:
    section.add "X-Amz-Date", valid_21626895
  var valid_21626896 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626896 = validateParameter(valid_21626896, JString, required = false,
                                   default = nil)
  if valid_21626896 != nil:
    section.add "X-Amz-Security-Token", valid_21626896
  var valid_21626897 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626897 = validateParameter(valid_21626897, JString, required = false,
                                   default = nil)
  if valid_21626897 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626897
  var valid_21626898 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626898 = validateParameter(valid_21626898, JString, required = false,
                                   default = nil)
  if valid_21626898 != nil:
    section.add "X-Amz-Algorithm", valid_21626898
  var valid_21626899 = header.getOrDefault("X-Amz-Signature")
  valid_21626899 = validateParameter(valid_21626899, JString, required = false,
                                   default = nil)
  if valid_21626899 != nil:
    section.add "X-Amz-Signature", valid_21626899
  var valid_21626900 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626900 = validateParameter(valid_21626900, JString, required = false,
                                   default = nil)
  if valid_21626900 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626900
  var valid_21626901 = header.getOrDefault("X-Amz-Credential")
  valid_21626901 = validateParameter(valid_21626901, JString, required = false,
                                   default = nil)
  if valid_21626901 != nil:
    section.add "X-Amz-Credential", valid_21626901
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626902: Call_GetDescribeEnvironmentManagedActions_21626887;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists an environment's upcoming and in-progress managed actions.
  ## 
  let valid = call_21626902.validator(path, query, header, formData, body, _)
  let scheme = call_21626902.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626902.makeUrl(scheme.get, call_21626902.host, call_21626902.base,
                               call_21626902.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626902, uri, valid, _)

proc call*(call_21626903: Call_GetDescribeEnvironmentManagedActions_21626887;
          Status: string = "Scheduled"; EnvironmentName: string = "";
          Action: string = "DescribeEnvironmentManagedActions";
          EnvironmentId: string = ""; Version: string = "2010-12-01"): Recallable =
  ## getDescribeEnvironmentManagedActions
  ## Lists an environment's upcoming and in-progress managed actions.
  ##   Status: string
  ##         : To show only actions with a particular status, specify a status.
  ##   EnvironmentName: string
  ##                  : The name of the target environment.
  ##   Action: string (required)
  ##   EnvironmentId: string
  ##                : The environment ID of the target environment.
  ##   Version: string (required)
  var query_21626904 = newJObject()
  add(query_21626904, "Status", newJString(Status))
  add(query_21626904, "EnvironmentName", newJString(EnvironmentName))
  add(query_21626904, "Action", newJString(Action))
  add(query_21626904, "EnvironmentId", newJString(EnvironmentId))
  add(query_21626904, "Version", newJString(Version))
  result = call_21626903.call(nil, query_21626904, nil, nil, nil)

var getDescribeEnvironmentManagedActions* = Call_GetDescribeEnvironmentManagedActions_21626887(
    name: "getDescribeEnvironmentManagedActions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActions",
    validator: validate_GetDescribeEnvironmentManagedActions_21626888, base: "/",
    makeUrl: url_GetDescribeEnvironmentManagedActions_21626889,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentResources_21626941 = ref object of OpenApiRestCall_21625437
proc url_PostDescribeEnvironmentResources_21626943(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEnvironmentResources_21626942(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626944 = query.getOrDefault("Action")
  valid_21626944 = validateParameter(valid_21626944, JString, required = true, default = newJString(
      "DescribeEnvironmentResources"))
  if valid_21626944 != nil:
    section.add "Action", valid_21626944
  var valid_21626945 = query.getOrDefault("Version")
  valid_21626945 = validateParameter(valid_21626945, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626945 != nil:
    section.add "Version", valid_21626945
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626946 = header.getOrDefault("X-Amz-Date")
  valid_21626946 = validateParameter(valid_21626946, JString, required = false,
                                   default = nil)
  if valid_21626946 != nil:
    section.add "X-Amz-Date", valid_21626946
  var valid_21626947 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626947 = validateParameter(valid_21626947, JString, required = false,
                                   default = nil)
  if valid_21626947 != nil:
    section.add "X-Amz-Security-Token", valid_21626947
  var valid_21626948 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626948 = validateParameter(valid_21626948, JString, required = false,
                                   default = nil)
  if valid_21626948 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626948
  var valid_21626949 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626949 = validateParameter(valid_21626949, JString, required = false,
                                   default = nil)
  if valid_21626949 != nil:
    section.add "X-Amz-Algorithm", valid_21626949
  var valid_21626950 = header.getOrDefault("X-Amz-Signature")
  valid_21626950 = validateParameter(valid_21626950, JString, required = false,
                                   default = nil)
  if valid_21626950 != nil:
    section.add "X-Amz-Signature", valid_21626950
  var valid_21626951 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626951 = validateParameter(valid_21626951, JString, required = false,
                                   default = nil)
  if valid_21626951 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626951
  var valid_21626952 = header.getOrDefault("X-Amz-Credential")
  valid_21626952 = validateParameter(valid_21626952, JString, required = false,
                                   default = nil)
  if valid_21626952 != nil:
    section.add "X-Amz-Credential", valid_21626952
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to retrieve AWS resource usage data.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to retrieve AWS resource usage data.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_21626953 = formData.getOrDefault("EnvironmentId")
  valid_21626953 = validateParameter(valid_21626953, JString, required = false,
                                   default = nil)
  if valid_21626953 != nil:
    section.add "EnvironmentId", valid_21626953
  var valid_21626954 = formData.getOrDefault("EnvironmentName")
  valid_21626954 = validateParameter(valid_21626954, JString, required = false,
                                   default = nil)
  if valid_21626954 != nil:
    section.add "EnvironmentName", valid_21626954
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626955: Call_PostDescribeEnvironmentResources_21626941;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns AWS resources for this environment.
  ## 
  let valid = call_21626955.validator(path, query, header, formData, body, _)
  let scheme = call_21626955.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626955.makeUrl(scheme.get, call_21626955.host, call_21626955.base,
                               call_21626955.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626955, uri, valid, _)

proc call*(call_21626956: Call_PostDescribeEnvironmentResources_21626941;
          EnvironmentId: string = ""; EnvironmentName: string = "";
          Action: string = "DescribeEnvironmentResources";
          Version: string = "2010-12-01"): Recallable =
  ## postDescribeEnvironmentResources
  ## Returns AWS resources for this environment.
  ##   EnvironmentId: string
  ##                : <p>The ID of the environment to retrieve AWS resource usage data.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentName: string
  ##                  : <p>The name of the environment to retrieve AWS resource usage data.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626957 = newJObject()
  var formData_21626958 = newJObject()
  add(formData_21626958, "EnvironmentId", newJString(EnvironmentId))
  add(formData_21626958, "EnvironmentName", newJString(EnvironmentName))
  add(query_21626957, "Action", newJString(Action))
  add(query_21626957, "Version", newJString(Version))
  result = call_21626956.call(nil, query_21626957, nil, formData_21626958, nil)

var postDescribeEnvironmentResources* = Call_PostDescribeEnvironmentResources_21626941(
    name: "postDescribeEnvironmentResources", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentResources",
    validator: validate_PostDescribeEnvironmentResources_21626942, base: "/",
    makeUrl: url_PostDescribeEnvironmentResources_21626943,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentResources_21626924 = ref object of OpenApiRestCall_21625437
proc url_GetDescribeEnvironmentResources_21626926(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEnvironmentResources_21626925(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to retrieve AWS resource usage data.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626927 = query.getOrDefault("EnvironmentName")
  valid_21626927 = validateParameter(valid_21626927, JString, required = false,
                                   default = nil)
  if valid_21626927 != nil:
    section.add "EnvironmentName", valid_21626927
  var valid_21626928 = query.getOrDefault("Action")
  valid_21626928 = validateParameter(valid_21626928, JString, required = true, default = newJString(
      "DescribeEnvironmentResources"))
  if valid_21626928 != nil:
    section.add "Action", valid_21626928
  var valid_21626929 = query.getOrDefault("EnvironmentId")
  valid_21626929 = validateParameter(valid_21626929, JString, required = false,
                                   default = nil)
  if valid_21626929 != nil:
    section.add "EnvironmentId", valid_21626929
  var valid_21626930 = query.getOrDefault("Version")
  valid_21626930 = validateParameter(valid_21626930, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626930 != nil:
    section.add "Version", valid_21626930
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626931 = header.getOrDefault("X-Amz-Date")
  valid_21626931 = validateParameter(valid_21626931, JString, required = false,
                                   default = nil)
  if valid_21626931 != nil:
    section.add "X-Amz-Date", valid_21626931
  var valid_21626932 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626932 = validateParameter(valid_21626932, JString, required = false,
                                   default = nil)
  if valid_21626932 != nil:
    section.add "X-Amz-Security-Token", valid_21626932
  var valid_21626933 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626933 = validateParameter(valid_21626933, JString, required = false,
                                   default = nil)
  if valid_21626933 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626933
  var valid_21626934 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626934 = validateParameter(valid_21626934, JString, required = false,
                                   default = nil)
  if valid_21626934 != nil:
    section.add "X-Amz-Algorithm", valid_21626934
  var valid_21626935 = header.getOrDefault("X-Amz-Signature")
  valid_21626935 = validateParameter(valid_21626935, JString, required = false,
                                   default = nil)
  if valid_21626935 != nil:
    section.add "X-Amz-Signature", valid_21626935
  var valid_21626936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626936 = validateParameter(valid_21626936, JString, required = false,
                                   default = nil)
  if valid_21626936 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626936
  var valid_21626937 = header.getOrDefault("X-Amz-Credential")
  valid_21626937 = validateParameter(valid_21626937, JString, required = false,
                                   default = nil)
  if valid_21626937 != nil:
    section.add "X-Amz-Credential", valid_21626937
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626938: Call_GetDescribeEnvironmentResources_21626924;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns AWS resources for this environment.
  ## 
  let valid = call_21626938.validator(path, query, header, formData, body, _)
  let scheme = call_21626938.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626938.makeUrl(scheme.get, call_21626938.host, call_21626938.base,
                               call_21626938.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626938, uri, valid, _)

proc call*(call_21626939: Call_GetDescribeEnvironmentResources_21626924;
          EnvironmentName: string = "";
          Action: string = "DescribeEnvironmentResources";
          EnvironmentId: string = ""; Version: string = "2010-12-01"): Recallable =
  ## getDescribeEnvironmentResources
  ## Returns AWS resources for this environment.
  ##   EnvironmentName: string
  ##                  : <p>The name of the environment to retrieve AWS resource usage data.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Action: string (required)
  ##   EnvironmentId: string
  ##                : <p>The ID of the environment to retrieve AWS resource usage data.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Version: string (required)
  var query_21626940 = newJObject()
  add(query_21626940, "EnvironmentName", newJString(EnvironmentName))
  add(query_21626940, "Action", newJString(Action))
  add(query_21626940, "EnvironmentId", newJString(EnvironmentId))
  add(query_21626940, "Version", newJString(Version))
  result = call_21626939.call(nil, query_21626940, nil, nil, nil)

var getDescribeEnvironmentResources* = Call_GetDescribeEnvironmentResources_21626924(
    name: "getDescribeEnvironmentResources", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentResources",
    validator: validate_GetDescribeEnvironmentResources_21626925, base: "/",
    makeUrl: url_GetDescribeEnvironmentResources_21626926,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironments_21626982 = ref object of OpenApiRestCall_21625437
proc url_PostDescribeEnvironments_21626984(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEnvironments_21626983(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626985 = query.getOrDefault("Action")
  valid_21626985 = validateParameter(valid_21626985, JString, required = true,
                                   default = newJString("DescribeEnvironments"))
  if valid_21626985 != nil:
    section.add "Action", valid_21626985
  var valid_21626986 = query.getOrDefault("Version")
  valid_21626986 = validateParameter(valid_21626986, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626986 != nil:
    section.add "Version", valid_21626986
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626987 = header.getOrDefault("X-Amz-Date")
  valid_21626987 = validateParameter(valid_21626987, JString, required = false,
                                   default = nil)
  if valid_21626987 != nil:
    section.add "X-Amz-Date", valid_21626987
  var valid_21626988 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626988 = validateParameter(valid_21626988, JString, required = false,
                                   default = nil)
  if valid_21626988 != nil:
    section.add "X-Amz-Security-Token", valid_21626988
  var valid_21626989 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626989 = validateParameter(valid_21626989, JString, required = false,
                                   default = nil)
  if valid_21626989 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626989
  var valid_21626990 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626990 = validateParameter(valid_21626990, JString, required = false,
                                   default = nil)
  if valid_21626990 != nil:
    section.add "X-Amz-Algorithm", valid_21626990
  var valid_21626991 = header.getOrDefault("X-Amz-Signature")
  valid_21626991 = validateParameter(valid_21626991, JString, required = false,
                                   default = nil)
  if valid_21626991 != nil:
    section.add "X-Amz-Signature", valid_21626991
  var valid_21626992 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626992 = validateParameter(valid_21626992, JString, required = false,
                                   default = nil)
  if valid_21626992 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626992
  var valid_21626993 = header.getOrDefault("X-Amz-Credential")
  valid_21626993 = validateParameter(valid_21626993, JString, required = false,
                                   default = nil)
  if valid_21626993 != nil:
    section.add "X-Amz-Credential", valid_21626993
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : <p>For a paginated request. Specify a token from a previous response page to retrieve the next response page. All other parameter values must be identical to the ones specified in the initial request.</p> <p>If no <code>NextToken</code> is specified, the first page is retrieved.</p>
  ##   VersionLabel: JString
  ##               : If specified, AWS Elastic Beanstalk restricts the returned descriptions to include only those that are associated with this application version.
  ##   EnvironmentNames: JArray
  ##                   : If specified, AWS Elastic Beanstalk restricts the returned descriptions to include only those that have the specified names.
  ##   IncludedDeletedBackTo: JString
  ##                        :  If specified when <code>IncludeDeleted</code> is set to <code>true</code>, then environments deleted after this date are displayed. 
  ##   ApplicationName: JString
  ##                  : If specified, AWS Elastic Beanstalk restricts the returned descriptions to include only those that are associated with this application.
  ##   EnvironmentIds: JArray
  ##                 : If specified, AWS Elastic Beanstalk restricts the returned descriptions to include only those that have the specified IDs.
  ##   IncludeDeleted: JBool
  ##                 : <p>Indicates whether to include deleted environments:</p> <p> <code>true</code>: Environments that have been deleted after <code>IncludedDeletedBackTo</code> are displayed.</p> <p> <code>false</code>: Do not include deleted environments.</p>
  ##   MaxRecords: JInt
  ##             : <p>For a paginated request. Specify a maximum number of environments to include in each response.</p> <p>If no <code>MaxRecords</code> is specified, all available environments are retrieved in a single response.</p>
  section = newJObject()
  var valid_21626994 = formData.getOrDefault("NextToken")
  valid_21626994 = validateParameter(valid_21626994, JString, required = false,
                                   default = nil)
  if valid_21626994 != nil:
    section.add "NextToken", valid_21626994
  var valid_21626995 = formData.getOrDefault("VersionLabel")
  valid_21626995 = validateParameter(valid_21626995, JString, required = false,
                                   default = nil)
  if valid_21626995 != nil:
    section.add "VersionLabel", valid_21626995
  var valid_21626996 = formData.getOrDefault("EnvironmentNames")
  valid_21626996 = validateParameter(valid_21626996, JArray, required = false,
                                   default = nil)
  if valid_21626996 != nil:
    section.add "EnvironmentNames", valid_21626996
  var valid_21626997 = formData.getOrDefault("IncludedDeletedBackTo")
  valid_21626997 = validateParameter(valid_21626997, JString, required = false,
                                   default = nil)
  if valid_21626997 != nil:
    section.add "IncludedDeletedBackTo", valid_21626997
  var valid_21626998 = formData.getOrDefault("ApplicationName")
  valid_21626998 = validateParameter(valid_21626998, JString, required = false,
                                   default = nil)
  if valid_21626998 != nil:
    section.add "ApplicationName", valid_21626998
  var valid_21626999 = formData.getOrDefault("EnvironmentIds")
  valid_21626999 = validateParameter(valid_21626999, JArray, required = false,
                                   default = nil)
  if valid_21626999 != nil:
    section.add "EnvironmentIds", valid_21626999
  var valid_21627000 = formData.getOrDefault("IncludeDeleted")
  valid_21627000 = validateParameter(valid_21627000, JBool, required = false,
                                   default = nil)
  if valid_21627000 != nil:
    section.add "IncludeDeleted", valid_21627000
  var valid_21627001 = formData.getOrDefault("MaxRecords")
  valid_21627001 = validateParameter(valid_21627001, JInt, required = false,
                                   default = nil)
  if valid_21627001 != nil:
    section.add "MaxRecords", valid_21627001
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627002: Call_PostDescribeEnvironments_21626982;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns descriptions for existing environments.
  ## 
  let valid = call_21627002.validator(path, query, header, formData, body, _)
  let scheme = call_21627002.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627002.makeUrl(scheme.get, call_21627002.host, call_21627002.base,
                               call_21627002.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627002, uri, valid, _)

proc call*(call_21627003: Call_PostDescribeEnvironments_21626982;
          NextToken: string = ""; VersionLabel: string = "";
          EnvironmentNames: JsonNode = nil; IncludedDeletedBackTo: string = "";
          Action: string = "DescribeEnvironments"; ApplicationName: string = "";
          EnvironmentIds: JsonNode = nil; IncludeDeleted: bool = false;
          MaxRecords: int = 0; Version: string = "2010-12-01"): Recallable =
  ## postDescribeEnvironments
  ## Returns descriptions for existing environments.
  ##   NextToken: string
  ##            : <p>For a paginated request. Specify a token from a previous response page to retrieve the next response page. All other parameter values must be identical to the ones specified in the initial request.</p> <p>If no <code>NextToken</code> is specified, the first page is retrieved.</p>
  ##   VersionLabel: string
  ##               : If specified, AWS Elastic Beanstalk restricts the returned descriptions to include only those that are associated with this application version.
  ##   EnvironmentNames: JArray
  ##                   : If specified, AWS Elastic Beanstalk restricts the returned descriptions to include only those that have the specified names.
  ##   IncludedDeletedBackTo: string
  ##                        :  If specified when <code>IncludeDeleted</code> is set to <code>true</code>, then environments deleted after this date are displayed. 
  ##   Action: string (required)
  ##   ApplicationName: string
  ##                  : If specified, AWS Elastic Beanstalk restricts the returned descriptions to include only those that are associated with this application.
  ##   EnvironmentIds: JArray
  ##                 : If specified, AWS Elastic Beanstalk restricts the returned descriptions to include only those that have the specified IDs.
  ##   IncludeDeleted: bool
  ##                 : <p>Indicates whether to include deleted environments:</p> <p> <code>true</code>: Environments that have been deleted after <code>IncludedDeletedBackTo</code> are displayed.</p> <p> <code>false</code>: Do not include deleted environments.</p>
  ##   MaxRecords: int
  ##             : <p>For a paginated request. Specify a maximum number of environments to include in each response.</p> <p>If no <code>MaxRecords</code> is specified, all available environments are retrieved in a single response.</p>
  ##   Version: string (required)
  var query_21627004 = newJObject()
  var formData_21627005 = newJObject()
  add(formData_21627005, "NextToken", newJString(NextToken))
  add(formData_21627005, "VersionLabel", newJString(VersionLabel))
  if EnvironmentNames != nil:
    formData_21627005.add "EnvironmentNames", EnvironmentNames
  add(formData_21627005, "IncludedDeletedBackTo",
      newJString(IncludedDeletedBackTo))
  add(query_21627004, "Action", newJString(Action))
  add(formData_21627005, "ApplicationName", newJString(ApplicationName))
  if EnvironmentIds != nil:
    formData_21627005.add "EnvironmentIds", EnvironmentIds
  add(formData_21627005, "IncludeDeleted", newJBool(IncludeDeleted))
  add(formData_21627005, "MaxRecords", newJInt(MaxRecords))
  add(query_21627004, "Version", newJString(Version))
  result = call_21627003.call(nil, query_21627004, nil, formData_21627005, nil)

var postDescribeEnvironments* = Call_PostDescribeEnvironments_21626982(
    name: "postDescribeEnvironments", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironments",
    validator: validate_PostDescribeEnvironments_21626983, base: "/",
    makeUrl: url_PostDescribeEnvironments_21626984,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironments_21626959 = ref object of OpenApiRestCall_21625437
proc url_GetDescribeEnvironments_21626961(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEnvironments_21626960(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns descriptions for existing environments.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   VersionLabel: JString
  ##               : If specified, AWS Elastic Beanstalk restricts the returned descriptions to include only those that are associated with this application version.
  ##   MaxRecords: JInt
  ##             : <p>For a paginated request. Specify a maximum number of environments to include in each response.</p> <p>If no <code>MaxRecords</code> is specified, all available environments are retrieved in a single response.</p>
  ##   ApplicationName: JString
  ##                  : If specified, AWS Elastic Beanstalk restricts the returned descriptions to include only those that are associated with this application.
  ##   IncludeDeleted: JBool
  ##                 : <p>Indicates whether to include deleted environments:</p> <p> <code>true</code>: Environments that have been deleted after <code>IncludedDeletedBackTo</code> are displayed.</p> <p> <code>false</code>: Do not include deleted environments.</p>
  ##   NextToken: JString
  ##            : <p>For a paginated request. Specify a token from a previous response page to retrieve the next response page. All other parameter values must be identical to the ones specified in the initial request.</p> <p>If no <code>NextToken</code> is specified, the first page is retrieved.</p>
  ##   EnvironmentIds: JArray
  ##                 : If specified, AWS Elastic Beanstalk restricts the returned descriptions to include only those that have the specified IDs.
  ##   Action: JString (required)
  ##   IncludedDeletedBackTo: JString
  ##                        :  If specified when <code>IncludeDeleted</code> is set to <code>true</code>, then environments deleted after this date are displayed. 
  ##   EnvironmentNames: JArray
  ##                   : If specified, AWS Elastic Beanstalk restricts the returned descriptions to include only those that have the specified names.
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626962 = query.getOrDefault("VersionLabel")
  valid_21626962 = validateParameter(valid_21626962, JString, required = false,
                                   default = nil)
  if valid_21626962 != nil:
    section.add "VersionLabel", valid_21626962
  var valid_21626963 = query.getOrDefault("MaxRecords")
  valid_21626963 = validateParameter(valid_21626963, JInt, required = false,
                                   default = nil)
  if valid_21626963 != nil:
    section.add "MaxRecords", valid_21626963
  var valid_21626964 = query.getOrDefault("ApplicationName")
  valid_21626964 = validateParameter(valid_21626964, JString, required = false,
                                   default = nil)
  if valid_21626964 != nil:
    section.add "ApplicationName", valid_21626964
  var valid_21626965 = query.getOrDefault("IncludeDeleted")
  valid_21626965 = validateParameter(valid_21626965, JBool, required = false,
                                   default = nil)
  if valid_21626965 != nil:
    section.add "IncludeDeleted", valid_21626965
  var valid_21626966 = query.getOrDefault("NextToken")
  valid_21626966 = validateParameter(valid_21626966, JString, required = false,
                                   default = nil)
  if valid_21626966 != nil:
    section.add "NextToken", valid_21626966
  var valid_21626967 = query.getOrDefault("EnvironmentIds")
  valid_21626967 = validateParameter(valid_21626967, JArray, required = false,
                                   default = nil)
  if valid_21626967 != nil:
    section.add "EnvironmentIds", valid_21626967
  var valid_21626968 = query.getOrDefault("Action")
  valid_21626968 = validateParameter(valid_21626968, JString, required = true,
                                   default = newJString("DescribeEnvironments"))
  if valid_21626968 != nil:
    section.add "Action", valid_21626968
  var valid_21626969 = query.getOrDefault("IncludedDeletedBackTo")
  valid_21626969 = validateParameter(valid_21626969, JString, required = false,
                                   default = nil)
  if valid_21626969 != nil:
    section.add "IncludedDeletedBackTo", valid_21626969
  var valid_21626970 = query.getOrDefault("EnvironmentNames")
  valid_21626970 = validateParameter(valid_21626970, JArray, required = false,
                                   default = nil)
  if valid_21626970 != nil:
    section.add "EnvironmentNames", valid_21626970
  var valid_21626971 = query.getOrDefault("Version")
  valid_21626971 = validateParameter(valid_21626971, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21626971 != nil:
    section.add "Version", valid_21626971
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21626972 = header.getOrDefault("X-Amz-Date")
  valid_21626972 = validateParameter(valid_21626972, JString, required = false,
                                   default = nil)
  if valid_21626972 != nil:
    section.add "X-Amz-Date", valid_21626972
  var valid_21626973 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626973 = validateParameter(valid_21626973, JString, required = false,
                                   default = nil)
  if valid_21626973 != nil:
    section.add "X-Amz-Security-Token", valid_21626973
  var valid_21626974 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626974 = validateParameter(valid_21626974, JString, required = false,
                                   default = nil)
  if valid_21626974 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626974
  var valid_21626975 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626975 = validateParameter(valid_21626975, JString, required = false,
                                   default = nil)
  if valid_21626975 != nil:
    section.add "X-Amz-Algorithm", valid_21626975
  var valid_21626976 = header.getOrDefault("X-Amz-Signature")
  valid_21626976 = validateParameter(valid_21626976, JString, required = false,
                                   default = nil)
  if valid_21626976 != nil:
    section.add "X-Amz-Signature", valid_21626976
  var valid_21626977 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626977 = validateParameter(valid_21626977, JString, required = false,
                                   default = nil)
  if valid_21626977 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626977
  var valid_21626978 = header.getOrDefault("X-Amz-Credential")
  valid_21626978 = validateParameter(valid_21626978, JString, required = false,
                                   default = nil)
  if valid_21626978 != nil:
    section.add "X-Amz-Credential", valid_21626978
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626979: Call_GetDescribeEnvironments_21626959;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns descriptions for existing environments.
  ## 
  let valid = call_21626979.validator(path, query, header, formData, body, _)
  let scheme = call_21626979.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626979.makeUrl(scheme.get, call_21626979.host, call_21626979.base,
                               call_21626979.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626979, uri, valid, _)

proc call*(call_21626980: Call_GetDescribeEnvironments_21626959;
          VersionLabel: string = ""; MaxRecords: int = 0; ApplicationName: string = "";
          IncludeDeleted: bool = false; NextToken: string = "";
          EnvironmentIds: JsonNode = nil; Action: string = "DescribeEnvironments";
          IncludedDeletedBackTo: string = ""; EnvironmentNames: JsonNode = nil;
          Version: string = "2010-12-01"): Recallable =
  ## getDescribeEnvironments
  ## Returns descriptions for existing environments.
  ##   VersionLabel: string
  ##               : If specified, AWS Elastic Beanstalk restricts the returned descriptions to include only those that are associated with this application version.
  ##   MaxRecords: int
  ##             : <p>For a paginated request. Specify a maximum number of environments to include in each response.</p> <p>If no <code>MaxRecords</code> is specified, all available environments are retrieved in a single response.</p>
  ##   ApplicationName: string
  ##                  : If specified, AWS Elastic Beanstalk restricts the returned descriptions to include only those that are associated with this application.
  ##   IncludeDeleted: bool
  ##                 : <p>Indicates whether to include deleted environments:</p> <p> <code>true</code>: Environments that have been deleted after <code>IncludedDeletedBackTo</code> are displayed.</p> <p> <code>false</code>: Do not include deleted environments.</p>
  ##   NextToken: string
  ##            : <p>For a paginated request. Specify a token from a previous response page to retrieve the next response page. All other parameter values must be identical to the ones specified in the initial request.</p> <p>If no <code>NextToken</code> is specified, the first page is retrieved.</p>
  ##   EnvironmentIds: JArray
  ##                 : If specified, AWS Elastic Beanstalk restricts the returned descriptions to include only those that have the specified IDs.
  ##   Action: string (required)
  ##   IncludedDeletedBackTo: string
  ##                        :  If specified when <code>IncludeDeleted</code> is set to <code>true</code>, then environments deleted after this date are displayed. 
  ##   EnvironmentNames: JArray
  ##                   : If specified, AWS Elastic Beanstalk restricts the returned descriptions to include only those that have the specified names.
  ##   Version: string (required)
  var query_21626981 = newJObject()
  add(query_21626981, "VersionLabel", newJString(VersionLabel))
  add(query_21626981, "MaxRecords", newJInt(MaxRecords))
  add(query_21626981, "ApplicationName", newJString(ApplicationName))
  add(query_21626981, "IncludeDeleted", newJBool(IncludeDeleted))
  add(query_21626981, "NextToken", newJString(NextToken))
  if EnvironmentIds != nil:
    query_21626981.add "EnvironmentIds", EnvironmentIds
  add(query_21626981, "Action", newJString(Action))
  add(query_21626981, "IncludedDeletedBackTo", newJString(IncludedDeletedBackTo))
  if EnvironmentNames != nil:
    query_21626981.add "EnvironmentNames", EnvironmentNames
  add(query_21626981, "Version", newJString(Version))
  result = call_21626980.call(nil, query_21626981, nil, nil, nil)

var getDescribeEnvironments* = Call_GetDescribeEnvironments_21626959(
    name: "getDescribeEnvironments", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironments",
    validator: validate_GetDescribeEnvironments_21626960, base: "/",
    makeUrl: url_GetDescribeEnvironments_21626961,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_21627033 = ref object of OpenApiRestCall_21625437
proc url_PostDescribeEvents_21627035(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEvents_21627034(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627036 = query.getOrDefault("Action")
  valid_21627036 = validateParameter(valid_21627036, JString, required = true,
                                   default = newJString("DescribeEvents"))
  if valid_21627036 != nil:
    section.add "Action", valid_21627036
  var valid_21627037 = query.getOrDefault("Version")
  valid_21627037 = validateParameter(valid_21627037, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21627037 != nil:
    section.add "Version", valid_21627037
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627038 = header.getOrDefault("X-Amz-Date")
  valid_21627038 = validateParameter(valid_21627038, JString, required = false,
                                   default = nil)
  if valid_21627038 != nil:
    section.add "X-Amz-Date", valid_21627038
  var valid_21627039 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627039 = validateParameter(valid_21627039, JString, required = false,
                                   default = nil)
  if valid_21627039 != nil:
    section.add "X-Amz-Security-Token", valid_21627039
  var valid_21627040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627040 = validateParameter(valid_21627040, JString, required = false,
                                   default = nil)
  if valid_21627040 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627040
  var valid_21627041 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627041 = validateParameter(valid_21627041, JString, required = false,
                                   default = nil)
  if valid_21627041 != nil:
    section.add "X-Amz-Algorithm", valid_21627041
  var valid_21627042 = header.getOrDefault("X-Amz-Signature")
  valid_21627042 = validateParameter(valid_21627042, JString, required = false,
                                   default = nil)
  if valid_21627042 != nil:
    section.add "X-Amz-Signature", valid_21627042
  var valid_21627043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627043 = validateParameter(valid_21627043, JString, required = false,
                                   default = nil)
  if valid_21627043 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627043
  var valid_21627044 = header.getOrDefault("X-Amz-Credential")
  valid_21627044 = validateParameter(valid_21627044, JString, required = false,
                                   default = nil)
  if valid_21627044 != nil:
    section.add "X-Amz-Credential", valid_21627044
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Pagination token. If specified, the events return the next batch of results.
  ##   VersionLabel: JString
  ##               : If specified, AWS Elastic Beanstalk restricts the returned descriptions to those associated with this application version.
  ##   Severity: JString
  ##           : If specified, limits the events returned from this call to include only those with the specified severity or higher.
  ##   EnvironmentId: JString
  ##                : If specified, AWS Elastic Beanstalk restricts the returned descriptions to those associated with this environment.
  ##   EnvironmentName: JString
  ##                  : If specified, AWS Elastic Beanstalk restricts the returned descriptions to those associated with this environment.
  ##   StartTime: JString
  ##            : If specified, AWS Elastic Beanstalk restricts the returned descriptions to those that occur on or after this time.
  ##   ApplicationName: JString
  ##                  : If specified, AWS Elastic Beanstalk restricts the returned descriptions to include only those associated with this application.
  ##   EndTime: JString
  ##          :  If specified, AWS Elastic Beanstalk restricts the returned descriptions to those that occur up to, but not including, the <code>EndTime</code>. 
  ##   PlatformArn: JString
  ##              : The ARN of the version of the custom platform.
  ##   MaxRecords: JInt
  ##             : Specifies the maximum number of events that can be returned, beginning with the most recent event.
  ##   RequestId: JString
  ##            : If specified, AWS Elastic Beanstalk restricts the described events to include only those associated with this request ID.
  ##   TemplateName: JString
  ##               : If specified, AWS Elastic Beanstalk restricts the returned descriptions to those that are associated with this environment configuration.
  section = newJObject()
  var valid_21627045 = formData.getOrDefault("NextToken")
  valid_21627045 = validateParameter(valid_21627045, JString, required = false,
                                   default = nil)
  if valid_21627045 != nil:
    section.add "NextToken", valid_21627045
  var valid_21627046 = formData.getOrDefault("VersionLabel")
  valid_21627046 = validateParameter(valid_21627046, JString, required = false,
                                   default = nil)
  if valid_21627046 != nil:
    section.add "VersionLabel", valid_21627046
  var valid_21627047 = formData.getOrDefault("Severity")
  valid_21627047 = validateParameter(valid_21627047, JString, required = false,
                                   default = newJString("TRACE"))
  if valid_21627047 != nil:
    section.add "Severity", valid_21627047
  var valid_21627048 = formData.getOrDefault("EnvironmentId")
  valid_21627048 = validateParameter(valid_21627048, JString, required = false,
                                   default = nil)
  if valid_21627048 != nil:
    section.add "EnvironmentId", valid_21627048
  var valid_21627049 = formData.getOrDefault("EnvironmentName")
  valid_21627049 = validateParameter(valid_21627049, JString, required = false,
                                   default = nil)
  if valid_21627049 != nil:
    section.add "EnvironmentName", valid_21627049
  var valid_21627050 = formData.getOrDefault("StartTime")
  valid_21627050 = validateParameter(valid_21627050, JString, required = false,
                                   default = nil)
  if valid_21627050 != nil:
    section.add "StartTime", valid_21627050
  var valid_21627051 = formData.getOrDefault("ApplicationName")
  valid_21627051 = validateParameter(valid_21627051, JString, required = false,
                                   default = nil)
  if valid_21627051 != nil:
    section.add "ApplicationName", valid_21627051
  var valid_21627052 = formData.getOrDefault("EndTime")
  valid_21627052 = validateParameter(valid_21627052, JString, required = false,
                                   default = nil)
  if valid_21627052 != nil:
    section.add "EndTime", valid_21627052
  var valid_21627053 = formData.getOrDefault("PlatformArn")
  valid_21627053 = validateParameter(valid_21627053, JString, required = false,
                                   default = nil)
  if valid_21627053 != nil:
    section.add "PlatformArn", valid_21627053
  var valid_21627054 = formData.getOrDefault("MaxRecords")
  valid_21627054 = validateParameter(valid_21627054, JInt, required = false,
                                   default = nil)
  if valid_21627054 != nil:
    section.add "MaxRecords", valid_21627054
  var valid_21627055 = formData.getOrDefault("RequestId")
  valid_21627055 = validateParameter(valid_21627055, JString, required = false,
                                   default = nil)
  if valid_21627055 != nil:
    section.add "RequestId", valid_21627055
  var valid_21627056 = formData.getOrDefault("TemplateName")
  valid_21627056 = validateParameter(valid_21627056, JString, required = false,
                                   default = nil)
  if valid_21627056 != nil:
    section.add "TemplateName", valid_21627056
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627057: Call_PostDescribeEvents_21627033; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns list of event descriptions matching criteria up to the last 6 weeks.</p> <note> <p>This action returns the most recent 1,000 events from the specified <code>NextToken</code>.</p> </note>
  ## 
  let valid = call_21627057.validator(path, query, header, formData, body, _)
  let scheme = call_21627057.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627057.makeUrl(scheme.get, call_21627057.host, call_21627057.base,
                               call_21627057.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627057, uri, valid, _)

proc call*(call_21627058: Call_PostDescribeEvents_21627033; NextToken: string = "";
          VersionLabel: string = ""; Severity: string = "TRACE";
          EnvironmentId: string = ""; EnvironmentName: string = "";
          StartTime: string = ""; Action: string = "DescribeEvents";
          ApplicationName: string = ""; EndTime: string = ""; PlatformArn: string = "";
          MaxRecords: int = 0; RequestId: string = ""; TemplateName: string = "";
          Version: string = "2010-12-01"): Recallable =
  ## postDescribeEvents
  ## <p>Returns list of event descriptions matching criteria up to the last 6 weeks.</p> <note> <p>This action returns the most recent 1,000 events from the specified <code>NextToken</code>.</p> </note>
  ##   NextToken: string
  ##            : Pagination token. If specified, the events return the next batch of results.
  ##   VersionLabel: string
  ##               : If specified, AWS Elastic Beanstalk restricts the returned descriptions to those associated with this application version.
  ##   Severity: string
  ##           : If specified, limits the events returned from this call to include only those with the specified severity or higher.
  ##   EnvironmentId: string
  ##                : If specified, AWS Elastic Beanstalk restricts the returned descriptions to those associated with this environment.
  ##   EnvironmentName: string
  ##                  : If specified, AWS Elastic Beanstalk restricts the returned descriptions to those associated with this environment.
  ##   StartTime: string
  ##            : If specified, AWS Elastic Beanstalk restricts the returned descriptions to those that occur on or after this time.
  ##   Action: string (required)
  ##   ApplicationName: string
  ##                  : If specified, AWS Elastic Beanstalk restricts the returned descriptions to include only those associated with this application.
  ##   EndTime: string
  ##          :  If specified, AWS Elastic Beanstalk restricts the returned descriptions to those that occur up to, but not including, the <code>EndTime</code>. 
  ##   PlatformArn: string
  ##              : The ARN of the version of the custom platform.
  ##   MaxRecords: int
  ##             : Specifies the maximum number of events that can be returned, beginning with the most recent event.
  ##   RequestId: string
  ##            : If specified, AWS Elastic Beanstalk restricts the described events to include only those associated with this request ID.
  ##   TemplateName: string
  ##               : If specified, AWS Elastic Beanstalk restricts the returned descriptions to those that are associated with this environment configuration.
  ##   Version: string (required)
  var query_21627059 = newJObject()
  var formData_21627060 = newJObject()
  add(formData_21627060, "NextToken", newJString(NextToken))
  add(formData_21627060, "VersionLabel", newJString(VersionLabel))
  add(formData_21627060, "Severity", newJString(Severity))
  add(formData_21627060, "EnvironmentId", newJString(EnvironmentId))
  add(formData_21627060, "EnvironmentName", newJString(EnvironmentName))
  add(formData_21627060, "StartTime", newJString(StartTime))
  add(query_21627059, "Action", newJString(Action))
  add(formData_21627060, "ApplicationName", newJString(ApplicationName))
  add(formData_21627060, "EndTime", newJString(EndTime))
  add(formData_21627060, "PlatformArn", newJString(PlatformArn))
  add(formData_21627060, "MaxRecords", newJInt(MaxRecords))
  add(formData_21627060, "RequestId", newJString(RequestId))
  add(formData_21627060, "TemplateName", newJString(TemplateName))
  add(query_21627059, "Version", newJString(Version))
  result = call_21627058.call(nil, query_21627059, nil, formData_21627060, nil)

var postDescribeEvents* = Call_PostDescribeEvents_21627033(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_21627034, base: "/",
    makeUrl: url_PostDescribeEvents_21627035, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_21627006 = ref object of OpenApiRestCall_21625437
proc url_GetDescribeEvents_21627008(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEvents_21627007(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns list of event descriptions matching criteria up to the last 6 weeks.</p> <note> <p>This action returns the most recent 1,000 events from the specified <code>NextToken</code>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   VersionLabel: JString
  ##               : If specified, AWS Elastic Beanstalk restricts the returned descriptions to those associated with this application version.
  ##   MaxRecords: JInt
  ##             : Specifies the maximum number of events that can be returned, beginning with the most recent event.
  ##   ApplicationName: JString
  ##                  : If specified, AWS Elastic Beanstalk restricts the returned descriptions to include only those associated with this application.
  ##   StartTime: JString
  ##            : If specified, AWS Elastic Beanstalk restricts the returned descriptions to those that occur on or after this time.
  ##   PlatformArn: JString
  ##              : The ARN of the version of the custom platform.
  ##   NextToken: JString
  ##            : Pagination token. If specified, the events return the next batch of results.
  ##   EnvironmentName: JString
  ##                  : If specified, AWS Elastic Beanstalk restricts the returned descriptions to those associated with this environment.
  ##   Action: JString (required)
  ##   EnvironmentId: JString
  ##                : If specified, AWS Elastic Beanstalk restricts the returned descriptions to those associated with this environment.
  ##   TemplateName: JString
  ##               : If specified, AWS Elastic Beanstalk restricts the returned descriptions to those that are associated with this environment configuration.
  ##   Severity: JString
  ##           : If specified, limits the events returned from this call to include only those with the specified severity or higher.
  ##   RequestId: JString
  ##            : If specified, AWS Elastic Beanstalk restricts the described events to include only those associated with this request ID.
  ##   EndTime: JString
  ##          :  If specified, AWS Elastic Beanstalk restricts the returned descriptions to those that occur up to, but not including, the <code>EndTime</code>. 
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627009 = query.getOrDefault("VersionLabel")
  valid_21627009 = validateParameter(valid_21627009, JString, required = false,
                                   default = nil)
  if valid_21627009 != nil:
    section.add "VersionLabel", valid_21627009
  var valid_21627010 = query.getOrDefault("MaxRecords")
  valid_21627010 = validateParameter(valid_21627010, JInt, required = false,
                                   default = nil)
  if valid_21627010 != nil:
    section.add "MaxRecords", valid_21627010
  var valid_21627011 = query.getOrDefault("ApplicationName")
  valid_21627011 = validateParameter(valid_21627011, JString, required = false,
                                   default = nil)
  if valid_21627011 != nil:
    section.add "ApplicationName", valid_21627011
  var valid_21627012 = query.getOrDefault("StartTime")
  valid_21627012 = validateParameter(valid_21627012, JString, required = false,
                                   default = nil)
  if valid_21627012 != nil:
    section.add "StartTime", valid_21627012
  var valid_21627013 = query.getOrDefault("PlatformArn")
  valid_21627013 = validateParameter(valid_21627013, JString, required = false,
                                   default = nil)
  if valid_21627013 != nil:
    section.add "PlatformArn", valid_21627013
  var valid_21627014 = query.getOrDefault("NextToken")
  valid_21627014 = validateParameter(valid_21627014, JString, required = false,
                                   default = nil)
  if valid_21627014 != nil:
    section.add "NextToken", valid_21627014
  var valid_21627015 = query.getOrDefault("EnvironmentName")
  valid_21627015 = validateParameter(valid_21627015, JString, required = false,
                                   default = nil)
  if valid_21627015 != nil:
    section.add "EnvironmentName", valid_21627015
  var valid_21627016 = query.getOrDefault("Action")
  valid_21627016 = validateParameter(valid_21627016, JString, required = true,
                                   default = newJString("DescribeEvents"))
  if valid_21627016 != nil:
    section.add "Action", valid_21627016
  var valid_21627017 = query.getOrDefault("EnvironmentId")
  valid_21627017 = validateParameter(valid_21627017, JString, required = false,
                                   default = nil)
  if valid_21627017 != nil:
    section.add "EnvironmentId", valid_21627017
  var valid_21627018 = query.getOrDefault("TemplateName")
  valid_21627018 = validateParameter(valid_21627018, JString, required = false,
                                   default = nil)
  if valid_21627018 != nil:
    section.add "TemplateName", valid_21627018
  var valid_21627019 = query.getOrDefault("Severity")
  valid_21627019 = validateParameter(valid_21627019, JString, required = false,
                                   default = newJString("TRACE"))
  if valid_21627019 != nil:
    section.add "Severity", valid_21627019
  var valid_21627020 = query.getOrDefault("RequestId")
  valid_21627020 = validateParameter(valid_21627020, JString, required = false,
                                   default = nil)
  if valid_21627020 != nil:
    section.add "RequestId", valid_21627020
  var valid_21627021 = query.getOrDefault("EndTime")
  valid_21627021 = validateParameter(valid_21627021, JString, required = false,
                                   default = nil)
  if valid_21627021 != nil:
    section.add "EndTime", valid_21627021
  var valid_21627022 = query.getOrDefault("Version")
  valid_21627022 = validateParameter(valid_21627022, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21627022 != nil:
    section.add "Version", valid_21627022
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627023 = header.getOrDefault("X-Amz-Date")
  valid_21627023 = validateParameter(valid_21627023, JString, required = false,
                                   default = nil)
  if valid_21627023 != nil:
    section.add "X-Amz-Date", valid_21627023
  var valid_21627024 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627024 = validateParameter(valid_21627024, JString, required = false,
                                   default = nil)
  if valid_21627024 != nil:
    section.add "X-Amz-Security-Token", valid_21627024
  var valid_21627025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627025 = validateParameter(valid_21627025, JString, required = false,
                                   default = nil)
  if valid_21627025 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627025
  var valid_21627026 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627026 = validateParameter(valid_21627026, JString, required = false,
                                   default = nil)
  if valid_21627026 != nil:
    section.add "X-Amz-Algorithm", valid_21627026
  var valid_21627027 = header.getOrDefault("X-Amz-Signature")
  valid_21627027 = validateParameter(valid_21627027, JString, required = false,
                                   default = nil)
  if valid_21627027 != nil:
    section.add "X-Amz-Signature", valid_21627027
  var valid_21627028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627028 = validateParameter(valid_21627028, JString, required = false,
                                   default = nil)
  if valid_21627028 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627028
  var valid_21627029 = header.getOrDefault("X-Amz-Credential")
  valid_21627029 = validateParameter(valid_21627029, JString, required = false,
                                   default = nil)
  if valid_21627029 != nil:
    section.add "X-Amz-Credential", valid_21627029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627030: Call_GetDescribeEvents_21627006; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns list of event descriptions matching criteria up to the last 6 weeks.</p> <note> <p>This action returns the most recent 1,000 events from the specified <code>NextToken</code>.</p> </note>
  ## 
  let valid = call_21627030.validator(path, query, header, formData, body, _)
  let scheme = call_21627030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627030.makeUrl(scheme.get, call_21627030.host, call_21627030.base,
                               call_21627030.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627030, uri, valid, _)

proc call*(call_21627031: Call_GetDescribeEvents_21627006;
          VersionLabel: string = ""; MaxRecords: int = 0; ApplicationName: string = "";
          StartTime: string = ""; PlatformArn: string = ""; NextToken: string = "";
          EnvironmentName: string = ""; Action: string = "DescribeEvents";
          EnvironmentId: string = ""; TemplateName: string = "";
          Severity: string = "TRACE"; RequestId: string = ""; EndTime: string = "";
          Version: string = "2010-12-01"): Recallable =
  ## getDescribeEvents
  ## <p>Returns list of event descriptions matching criteria up to the last 6 weeks.</p> <note> <p>This action returns the most recent 1,000 events from the specified <code>NextToken</code>.</p> </note>
  ##   VersionLabel: string
  ##               : If specified, AWS Elastic Beanstalk restricts the returned descriptions to those associated with this application version.
  ##   MaxRecords: int
  ##             : Specifies the maximum number of events that can be returned, beginning with the most recent event.
  ##   ApplicationName: string
  ##                  : If specified, AWS Elastic Beanstalk restricts the returned descriptions to include only those associated with this application.
  ##   StartTime: string
  ##            : If specified, AWS Elastic Beanstalk restricts the returned descriptions to those that occur on or after this time.
  ##   PlatformArn: string
  ##              : The ARN of the version of the custom platform.
  ##   NextToken: string
  ##            : Pagination token. If specified, the events return the next batch of results.
  ##   EnvironmentName: string
  ##                  : If specified, AWS Elastic Beanstalk restricts the returned descriptions to those associated with this environment.
  ##   Action: string (required)
  ##   EnvironmentId: string
  ##                : If specified, AWS Elastic Beanstalk restricts the returned descriptions to those associated with this environment.
  ##   TemplateName: string
  ##               : If specified, AWS Elastic Beanstalk restricts the returned descriptions to those that are associated with this environment configuration.
  ##   Severity: string
  ##           : If specified, limits the events returned from this call to include only those with the specified severity or higher.
  ##   RequestId: string
  ##            : If specified, AWS Elastic Beanstalk restricts the described events to include only those associated with this request ID.
  ##   EndTime: string
  ##          :  If specified, AWS Elastic Beanstalk restricts the returned descriptions to those that occur up to, but not including, the <code>EndTime</code>. 
  ##   Version: string (required)
  var query_21627032 = newJObject()
  add(query_21627032, "VersionLabel", newJString(VersionLabel))
  add(query_21627032, "MaxRecords", newJInt(MaxRecords))
  add(query_21627032, "ApplicationName", newJString(ApplicationName))
  add(query_21627032, "StartTime", newJString(StartTime))
  add(query_21627032, "PlatformArn", newJString(PlatformArn))
  add(query_21627032, "NextToken", newJString(NextToken))
  add(query_21627032, "EnvironmentName", newJString(EnvironmentName))
  add(query_21627032, "Action", newJString(Action))
  add(query_21627032, "EnvironmentId", newJString(EnvironmentId))
  add(query_21627032, "TemplateName", newJString(TemplateName))
  add(query_21627032, "Severity", newJString(Severity))
  add(query_21627032, "RequestId", newJString(RequestId))
  add(query_21627032, "EndTime", newJString(EndTime))
  add(query_21627032, "Version", newJString(Version))
  result = call_21627031.call(nil, query_21627032, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_21627006(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_21627007,
    base: "/", makeUrl: url_GetDescribeEvents_21627008,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeInstancesHealth_21627080 = ref object of OpenApiRestCall_21625437
proc url_PostDescribeInstancesHealth_21627082(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeInstancesHealth_21627081(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627083 = query.getOrDefault("Action")
  valid_21627083 = validateParameter(valid_21627083, JString, required = true, default = newJString(
      "DescribeInstancesHealth"))
  if valid_21627083 != nil:
    section.add "Action", valid_21627083
  var valid_21627084 = query.getOrDefault("Version")
  valid_21627084 = validateParameter(valid_21627084, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21627084 != nil:
    section.add "Version", valid_21627084
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627085 = header.getOrDefault("X-Amz-Date")
  valid_21627085 = validateParameter(valid_21627085, JString, required = false,
                                   default = nil)
  if valid_21627085 != nil:
    section.add "X-Amz-Date", valid_21627085
  var valid_21627086 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627086 = validateParameter(valid_21627086, JString, required = false,
                                   default = nil)
  if valid_21627086 != nil:
    section.add "X-Amz-Security-Token", valid_21627086
  var valid_21627087 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627087 = validateParameter(valid_21627087, JString, required = false,
                                   default = nil)
  if valid_21627087 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627087
  var valid_21627088 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627088 = validateParameter(valid_21627088, JString, required = false,
                                   default = nil)
  if valid_21627088 != nil:
    section.add "X-Amz-Algorithm", valid_21627088
  var valid_21627089 = header.getOrDefault("X-Amz-Signature")
  valid_21627089 = validateParameter(valid_21627089, JString, required = false,
                                   default = nil)
  if valid_21627089 != nil:
    section.add "X-Amz-Signature", valid_21627089
  var valid_21627090 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627090 = validateParameter(valid_21627090, JString, required = false,
                                   default = nil)
  if valid_21627090 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627090
  var valid_21627091 = header.getOrDefault("X-Amz-Credential")
  valid_21627091 = validateParameter(valid_21627091, JString, required = false,
                                   default = nil)
  if valid_21627091 != nil:
    section.add "X-Amz-Credential", valid_21627091
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : Specify the pagination token returned by a previous call.
  ##   EnvironmentId: JString
  ##                : Specify the AWS Elastic Beanstalk environment by ID.
  ##   EnvironmentName: JString
  ##                  : Specify the AWS Elastic Beanstalk environment by name.
  ##   AttributeNames: JArray
  ##                 : Specifies the response elements you wish to receive. To retrieve all attributes, set to <code>All</code>. If no attribute names are specified, returns a list of instances.
  section = newJObject()
  var valid_21627092 = formData.getOrDefault("NextToken")
  valid_21627092 = validateParameter(valid_21627092, JString, required = false,
                                   default = nil)
  if valid_21627092 != nil:
    section.add "NextToken", valid_21627092
  var valid_21627093 = formData.getOrDefault("EnvironmentId")
  valid_21627093 = validateParameter(valid_21627093, JString, required = false,
                                   default = nil)
  if valid_21627093 != nil:
    section.add "EnvironmentId", valid_21627093
  var valid_21627094 = formData.getOrDefault("EnvironmentName")
  valid_21627094 = validateParameter(valid_21627094, JString, required = false,
                                   default = nil)
  if valid_21627094 != nil:
    section.add "EnvironmentName", valid_21627094
  var valid_21627095 = formData.getOrDefault("AttributeNames")
  valid_21627095 = validateParameter(valid_21627095, JArray, required = false,
                                   default = nil)
  if valid_21627095 != nil:
    section.add "AttributeNames", valid_21627095
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627096: Call_PostDescribeInstancesHealth_21627080;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves detailed information about the health of instances in your AWS Elastic Beanstalk. This operation requires <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/health-enhanced.html">enhanced health reporting</a>.
  ## 
  let valid = call_21627096.validator(path, query, header, formData, body, _)
  let scheme = call_21627096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627096.makeUrl(scheme.get, call_21627096.host, call_21627096.base,
                               call_21627096.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627096, uri, valid, _)

proc call*(call_21627097: Call_PostDescribeInstancesHealth_21627080;
          NextToken: string = ""; EnvironmentId: string = "";
          EnvironmentName: string = ""; Action: string = "DescribeInstancesHealth";
          AttributeNames: JsonNode = nil; Version: string = "2010-12-01"): Recallable =
  ## postDescribeInstancesHealth
  ## Retrieves detailed information about the health of instances in your AWS Elastic Beanstalk. This operation requires <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/health-enhanced.html">enhanced health reporting</a>.
  ##   NextToken: string
  ##            : Specify the pagination token returned by a previous call.
  ##   EnvironmentId: string
  ##                : Specify the AWS Elastic Beanstalk environment by ID.
  ##   EnvironmentName: string
  ##                  : Specify the AWS Elastic Beanstalk environment by name.
  ##   Action: string (required)
  ##   AttributeNames: JArray
  ##                 : Specifies the response elements you wish to receive. To retrieve all attributes, set to <code>All</code>. If no attribute names are specified, returns a list of instances.
  ##   Version: string (required)
  var query_21627098 = newJObject()
  var formData_21627099 = newJObject()
  add(formData_21627099, "NextToken", newJString(NextToken))
  add(formData_21627099, "EnvironmentId", newJString(EnvironmentId))
  add(formData_21627099, "EnvironmentName", newJString(EnvironmentName))
  add(query_21627098, "Action", newJString(Action))
  if AttributeNames != nil:
    formData_21627099.add "AttributeNames", AttributeNames
  add(query_21627098, "Version", newJString(Version))
  result = call_21627097.call(nil, query_21627098, nil, formData_21627099, nil)

var postDescribeInstancesHealth* = Call_PostDescribeInstancesHealth_21627080(
    name: "postDescribeInstancesHealth", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeInstancesHealth",
    validator: validate_PostDescribeInstancesHealth_21627081, base: "/",
    makeUrl: url_PostDescribeInstancesHealth_21627082,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeInstancesHealth_21627061 = ref object of OpenApiRestCall_21625437
proc url_GetDescribeInstancesHealth_21627063(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeInstancesHealth_21627062(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   EnvironmentId: JString
  ##                : Specify the AWS Elastic Beanstalk environment by ID.
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627064 = query.getOrDefault("AttributeNames")
  valid_21627064 = validateParameter(valid_21627064, JArray, required = false,
                                   default = nil)
  if valid_21627064 != nil:
    section.add "AttributeNames", valid_21627064
  var valid_21627065 = query.getOrDefault("NextToken")
  valid_21627065 = validateParameter(valid_21627065, JString, required = false,
                                   default = nil)
  if valid_21627065 != nil:
    section.add "NextToken", valid_21627065
  var valid_21627066 = query.getOrDefault("EnvironmentName")
  valid_21627066 = validateParameter(valid_21627066, JString, required = false,
                                   default = nil)
  if valid_21627066 != nil:
    section.add "EnvironmentName", valid_21627066
  var valid_21627067 = query.getOrDefault("Action")
  valid_21627067 = validateParameter(valid_21627067, JString, required = true, default = newJString(
      "DescribeInstancesHealth"))
  if valid_21627067 != nil:
    section.add "Action", valid_21627067
  var valid_21627068 = query.getOrDefault("EnvironmentId")
  valid_21627068 = validateParameter(valid_21627068, JString, required = false,
                                   default = nil)
  if valid_21627068 != nil:
    section.add "EnvironmentId", valid_21627068
  var valid_21627069 = query.getOrDefault("Version")
  valid_21627069 = validateParameter(valid_21627069, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21627069 != nil:
    section.add "Version", valid_21627069
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627070 = header.getOrDefault("X-Amz-Date")
  valid_21627070 = validateParameter(valid_21627070, JString, required = false,
                                   default = nil)
  if valid_21627070 != nil:
    section.add "X-Amz-Date", valid_21627070
  var valid_21627071 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627071 = validateParameter(valid_21627071, JString, required = false,
                                   default = nil)
  if valid_21627071 != nil:
    section.add "X-Amz-Security-Token", valid_21627071
  var valid_21627072 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627072 = validateParameter(valid_21627072, JString, required = false,
                                   default = nil)
  if valid_21627072 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627072
  var valid_21627073 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627073 = validateParameter(valid_21627073, JString, required = false,
                                   default = nil)
  if valid_21627073 != nil:
    section.add "X-Amz-Algorithm", valid_21627073
  var valid_21627074 = header.getOrDefault("X-Amz-Signature")
  valid_21627074 = validateParameter(valid_21627074, JString, required = false,
                                   default = nil)
  if valid_21627074 != nil:
    section.add "X-Amz-Signature", valid_21627074
  var valid_21627075 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627075 = validateParameter(valid_21627075, JString, required = false,
                                   default = nil)
  if valid_21627075 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627075
  var valid_21627076 = header.getOrDefault("X-Amz-Credential")
  valid_21627076 = validateParameter(valid_21627076, JString, required = false,
                                   default = nil)
  if valid_21627076 != nil:
    section.add "X-Amz-Credential", valid_21627076
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627077: Call_GetDescribeInstancesHealth_21627061;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves detailed information about the health of instances in your AWS Elastic Beanstalk. This operation requires <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/health-enhanced.html">enhanced health reporting</a>.
  ## 
  let valid = call_21627077.validator(path, query, header, formData, body, _)
  let scheme = call_21627077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627077.makeUrl(scheme.get, call_21627077.host, call_21627077.base,
                               call_21627077.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627077, uri, valid, _)

proc call*(call_21627078: Call_GetDescribeInstancesHealth_21627061;
          AttributeNames: JsonNode = nil; NextToken: string = "";
          EnvironmentName: string = ""; Action: string = "DescribeInstancesHealth";
          EnvironmentId: string = ""; Version: string = "2010-12-01"): Recallable =
  ## getDescribeInstancesHealth
  ## Retrieves detailed information about the health of instances in your AWS Elastic Beanstalk. This operation requires <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/health-enhanced.html">enhanced health reporting</a>.
  ##   AttributeNames: JArray
  ##                 : Specifies the response elements you wish to receive. To retrieve all attributes, set to <code>All</code>. If no attribute names are specified, returns a list of instances.
  ##   NextToken: string
  ##            : Specify the pagination token returned by a previous call.
  ##   EnvironmentName: string
  ##                  : Specify the AWS Elastic Beanstalk environment by name.
  ##   Action: string (required)
  ##   EnvironmentId: string
  ##                : Specify the AWS Elastic Beanstalk environment by ID.
  ##   Version: string (required)
  var query_21627079 = newJObject()
  if AttributeNames != nil:
    query_21627079.add "AttributeNames", AttributeNames
  add(query_21627079, "NextToken", newJString(NextToken))
  add(query_21627079, "EnvironmentName", newJString(EnvironmentName))
  add(query_21627079, "Action", newJString(Action))
  add(query_21627079, "EnvironmentId", newJString(EnvironmentId))
  add(query_21627079, "Version", newJString(Version))
  result = call_21627078.call(nil, query_21627079, nil, nil, nil)

var getDescribeInstancesHealth* = Call_GetDescribeInstancesHealth_21627061(
    name: "getDescribeInstancesHealth", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeInstancesHealth",
    validator: validate_GetDescribeInstancesHealth_21627062, base: "/",
    makeUrl: url_GetDescribeInstancesHealth_21627063,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribePlatformVersion_21627116 = ref object of OpenApiRestCall_21625437
proc url_PostDescribePlatformVersion_21627118(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribePlatformVersion_21627117(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627119 = query.getOrDefault("Action")
  valid_21627119 = validateParameter(valid_21627119, JString, required = true, default = newJString(
      "DescribePlatformVersion"))
  if valid_21627119 != nil:
    section.add "Action", valid_21627119
  var valid_21627120 = query.getOrDefault("Version")
  valid_21627120 = validateParameter(valid_21627120, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21627120 != nil:
    section.add "Version", valid_21627120
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627121 = header.getOrDefault("X-Amz-Date")
  valid_21627121 = validateParameter(valid_21627121, JString, required = false,
                                   default = nil)
  if valid_21627121 != nil:
    section.add "X-Amz-Date", valid_21627121
  var valid_21627122 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627122 = validateParameter(valid_21627122, JString, required = false,
                                   default = nil)
  if valid_21627122 != nil:
    section.add "X-Amz-Security-Token", valid_21627122
  var valid_21627123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627123 = validateParameter(valid_21627123, JString, required = false,
                                   default = nil)
  if valid_21627123 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627123
  var valid_21627124 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627124 = validateParameter(valid_21627124, JString, required = false,
                                   default = nil)
  if valid_21627124 != nil:
    section.add "X-Amz-Algorithm", valid_21627124
  var valid_21627125 = header.getOrDefault("X-Amz-Signature")
  valid_21627125 = validateParameter(valid_21627125, JString, required = false,
                                   default = nil)
  if valid_21627125 != nil:
    section.add "X-Amz-Signature", valid_21627125
  var valid_21627126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627126 = validateParameter(valid_21627126, JString, required = false,
                                   default = nil)
  if valid_21627126 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627126
  var valid_21627127 = header.getOrDefault("X-Amz-Credential")
  valid_21627127 = validateParameter(valid_21627127, JString, required = false,
                                   default = nil)
  if valid_21627127 != nil:
    section.add "X-Amz-Credential", valid_21627127
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformArn: JString
  ##              : The ARN of the version of the platform.
  section = newJObject()
  var valid_21627128 = formData.getOrDefault("PlatformArn")
  valid_21627128 = validateParameter(valid_21627128, JString, required = false,
                                   default = nil)
  if valid_21627128 != nil:
    section.add "PlatformArn", valid_21627128
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627129: Call_PostDescribePlatformVersion_21627116;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the version of the platform.
  ## 
  let valid = call_21627129.validator(path, query, header, formData, body, _)
  let scheme = call_21627129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627129.makeUrl(scheme.get, call_21627129.host, call_21627129.base,
                               call_21627129.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627129, uri, valid, _)

proc call*(call_21627130: Call_PostDescribePlatformVersion_21627116;
          Action: string = "DescribePlatformVersion"; PlatformArn: string = "";
          Version: string = "2010-12-01"): Recallable =
  ## postDescribePlatformVersion
  ## Describes the version of the platform.
  ##   Action: string (required)
  ##   PlatformArn: string
  ##              : The ARN of the version of the platform.
  ##   Version: string (required)
  var query_21627131 = newJObject()
  var formData_21627132 = newJObject()
  add(query_21627131, "Action", newJString(Action))
  add(formData_21627132, "PlatformArn", newJString(PlatformArn))
  add(query_21627131, "Version", newJString(Version))
  result = call_21627130.call(nil, query_21627131, nil, formData_21627132, nil)

var postDescribePlatformVersion* = Call_PostDescribePlatformVersion_21627116(
    name: "postDescribePlatformVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribePlatformVersion",
    validator: validate_PostDescribePlatformVersion_21627117, base: "/",
    makeUrl: url_PostDescribePlatformVersion_21627118,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribePlatformVersion_21627100 = ref object of OpenApiRestCall_21625437
proc url_GetDescribePlatformVersion_21627102(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribePlatformVersion_21627101(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Describes the version of the platform.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PlatformArn: JString
  ##              : The ARN of the version of the platform.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627103 = query.getOrDefault("PlatformArn")
  valid_21627103 = validateParameter(valid_21627103, JString, required = false,
                                   default = nil)
  if valid_21627103 != nil:
    section.add "PlatformArn", valid_21627103
  var valid_21627104 = query.getOrDefault("Action")
  valid_21627104 = validateParameter(valid_21627104, JString, required = true, default = newJString(
      "DescribePlatformVersion"))
  if valid_21627104 != nil:
    section.add "Action", valid_21627104
  var valid_21627105 = query.getOrDefault("Version")
  valid_21627105 = validateParameter(valid_21627105, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21627105 != nil:
    section.add "Version", valid_21627105
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627106 = header.getOrDefault("X-Amz-Date")
  valid_21627106 = validateParameter(valid_21627106, JString, required = false,
                                   default = nil)
  if valid_21627106 != nil:
    section.add "X-Amz-Date", valid_21627106
  var valid_21627107 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627107 = validateParameter(valid_21627107, JString, required = false,
                                   default = nil)
  if valid_21627107 != nil:
    section.add "X-Amz-Security-Token", valid_21627107
  var valid_21627108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627108 = validateParameter(valid_21627108, JString, required = false,
                                   default = nil)
  if valid_21627108 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627108
  var valid_21627109 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627109 = validateParameter(valid_21627109, JString, required = false,
                                   default = nil)
  if valid_21627109 != nil:
    section.add "X-Amz-Algorithm", valid_21627109
  var valid_21627110 = header.getOrDefault("X-Amz-Signature")
  valid_21627110 = validateParameter(valid_21627110, JString, required = false,
                                   default = nil)
  if valid_21627110 != nil:
    section.add "X-Amz-Signature", valid_21627110
  var valid_21627111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627111 = validateParameter(valid_21627111, JString, required = false,
                                   default = nil)
  if valid_21627111 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627111
  var valid_21627112 = header.getOrDefault("X-Amz-Credential")
  valid_21627112 = validateParameter(valid_21627112, JString, required = false,
                                   default = nil)
  if valid_21627112 != nil:
    section.add "X-Amz-Credential", valid_21627112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627113: Call_GetDescribePlatformVersion_21627100;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the version of the platform.
  ## 
  let valid = call_21627113.validator(path, query, header, formData, body, _)
  let scheme = call_21627113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627113.makeUrl(scheme.get, call_21627113.host, call_21627113.base,
                               call_21627113.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627113, uri, valid, _)

proc call*(call_21627114: Call_GetDescribePlatformVersion_21627100;
          PlatformArn: string = ""; Action: string = "DescribePlatformVersion";
          Version: string = "2010-12-01"): Recallable =
  ## getDescribePlatformVersion
  ## Describes the version of the platform.
  ##   PlatformArn: string
  ##              : The ARN of the version of the platform.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21627115 = newJObject()
  add(query_21627115, "PlatformArn", newJString(PlatformArn))
  add(query_21627115, "Action", newJString(Action))
  add(query_21627115, "Version", newJString(Version))
  result = call_21627114.call(nil, query_21627115, nil, nil, nil)

var getDescribePlatformVersion* = Call_GetDescribePlatformVersion_21627100(
    name: "getDescribePlatformVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribePlatformVersion",
    validator: validate_GetDescribePlatformVersion_21627101, base: "/",
    makeUrl: url_GetDescribePlatformVersion_21627102,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListAvailableSolutionStacks_21627148 = ref object of OpenApiRestCall_21625437
proc url_PostListAvailableSolutionStacks_21627150(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListAvailableSolutionStacks_21627149(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627151 = query.getOrDefault("Action")
  valid_21627151 = validateParameter(valid_21627151, JString, required = true, default = newJString(
      "ListAvailableSolutionStacks"))
  if valid_21627151 != nil:
    section.add "Action", valid_21627151
  var valid_21627152 = query.getOrDefault("Version")
  valid_21627152 = validateParameter(valid_21627152, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21627152 != nil:
    section.add "Version", valid_21627152
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627153 = header.getOrDefault("X-Amz-Date")
  valid_21627153 = validateParameter(valid_21627153, JString, required = false,
                                   default = nil)
  if valid_21627153 != nil:
    section.add "X-Amz-Date", valid_21627153
  var valid_21627154 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627154 = validateParameter(valid_21627154, JString, required = false,
                                   default = nil)
  if valid_21627154 != nil:
    section.add "X-Amz-Security-Token", valid_21627154
  var valid_21627155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627155 = validateParameter(valid_21627155, JString, required = false,
                                   default = nil)
  if valid_21627155 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627155
  var valid_21627156 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627156 = validateParameter(valid_21627156, JString, required = false,
                                   default = nil)
  if valid_21627156 != nil:
    section.add "X-Amz-Algorithm", valid_21627156
  var valid_21627157 = header.getOrDefault("X-Amz-Signature")
  valid_21627157 = validateParameter(valid_21627157, JString, required = false,
                                   default = nil)
  if valid_21627157 != nil:
    section.add "X-Amz-Signature", valid_21627157
  var valid_21627158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627158 = validateParameter(valid_21627158, JString, required = false,
                                   default = nil)
  if valid_21627158 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627158
  var valid_21627159 = header.getOrDefault("X-Amz-Credential")
  valid_21627159 = validateParameter(valid_21627159, JString, required = false,
                                   default = nil)
  if valid_21627159 != nil:
    section.add "X-Amz-Credential", valid_21627159
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627160: Call_PostListAvailableSolutionStacks_21627148;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ## 
  let valid = call_21627160.validator(path, query, header, formData, body, _)
  let scheme = call_21627160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627160.makeUrl(scheme.get, call_21627160.host, call_21627160.base,
                               call_21627160.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627160, uri, valid, _)

proc call*(call_21627161: Call_PostListAvailableSolutionStacks_21627148;
          Action: string = "ListAvailableSolutionStacks";
          Version: string = "2010-12-01"): Recallable =
  ## postListAvailableSolutionStacks
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21627162 = newJObject()
  add(query_21627162, "Action", newJString(Action))
  add(query_21627162, "Version", newJString(Version))
  result = call_21627161.call(nil, query_21627162, nil, nil, nil)

var postListAvailableSolutionStacks* = Call_PostListAvailableSolutionStacks_21627148(
    name: "postListAvailableSolutionStacks", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListAvailableSolutionStacks",
    validator: validate_PostListAvailableSolutionStacks_21627149, base: "/",
    makeUrl: url_PostListAvailableSolutionStacks_21627150,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListAvailableSolutionStacks_21627133 = ref object of OpenApiRestCall_21625437
proc url_GetListAvailableSolutionStacks_21627135(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListAvailableSolutionStacks_21627134(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627136 = query.getOrDefault("Action")
  valid_21627136 = validateParameter(valid_21627136, JString, required = true, default = newJString(
      "ListAvailableSolutionStacks"))
  if valid_21627136 != nil:
    section.add "Action", valid_21627136
  var valid_21627137 = query.getOrDefault("Version")
  valid_21627137 = validateParameter(valid_21627137, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21627137 != nil:
    section.add "Version", valid_21627137
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627138 = header.getOrDefault("X-Amz-Date")
  valid_21627138 = validateParameter(valid_21627138, JString, required = false,
                                   default = nil)
  if valid_21627138 != nil:
    section.add "X-Amz-Date", valid_21627138
  var valid_21627139 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627139 = validateParameter(valid_21627139, JString, required = false,
                                   default = nil)
  if valid_21627139 != nil:
    section.add "X-Amz-Security-Token", valid_21627139
  var valid_21627140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627140 = validateParameter(valid_21627140, JString, required = false,
                                   default = nil)
  if valid_21627140 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627140
  var valid_21627141 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627141 = validateParameter(valid_21627141, JString, required = false,
                                   default = nil)
  if valid_21627141 != nil:
    section.add "X-Amz-Algorithm", valid_21627141
  var valid_21627142 = header.getOrDefault("X-Amz-Signature")
  valid_21627142 = validateParameter(valid_21627142, JString, required = false,
                                   default = nil)
  if valid_21627142 != nil:
    section.add "X-Amz-Signature", valid_21627142
  var valid_21627143 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627143 = validateParameter(valid_21627143, JString, required = false,
                                   default = nil)
  if valid_21627143 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627143
  var valid_21627144 = header.getOrDefault("X-Amz-Credential")
  valid_21627144 = validateParameter(valid_21627144, JString, required = false,
                                   default = nil)
  if valid_21627144 != nil:
    section.add "X-Amz-Credential", valid_21627144
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627145: Call_GetListAvailableSolutionStacks_21627133;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ## 
  let valid = call_21627145.validator(path, query, header, formData, body, _)
  let scheme = call_21627145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627145.makeUrl(scheme.get, call_21627145.host, call_21627145.base,
                               call_21627145.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627145, uri, valid, _)

proc call*(call_21627146: Call_GetListAvailableSolutionStacks_21627133;
          Action: string = "ListAvailableSolutionStacks";
          Version: string = "2010-12-01"): Recallable =
  ## getListAvailableSolutionStacks
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21627147 = newJObject()
  add(query_21627147, "Action", newJString(Action))
  add(query_21627147, "Version", newJString(Version))
  result = call_21627146.call(nil, query_21627147, nil, nil, nil)

var getListAvailableSolutionStacks* = Call_GetListAvailableSolutionStacks_21627133(
    name: "getListAvailableSolutionStacks", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListAvailableSolutionStacks",
    validator: validate_GetListAvailableSolutionStacks_21627134, base: "/",
    makeUrl: url_GetListAvailableSolutionStacks_21627135,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListPlatformVersions_21627181 = ref object of OpenApiRestCall_21625437
proc url_PostListPlatformVersions_21627183(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListPlatformVersions_21627182(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627184 = query.getOrDefault("Action")
  valid_21627184 = validateParameter(valid_21627184, JString, required = true,
                                   default = newJString("ListPlatformVersions"))
  if valid_21627184 != nil:
    section.add "Action", valid_21627184
  var valid_21627185 = query.getOrDefault("Version")
  valid_21627185 = validateParameter(valid_21627185, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21627185 != nil:
    section.add "Version", valid_21627185
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627186 = header.getOrDefault("X-Amz-Date")
  valid_21627186 = validateParameter(valid_21627186, JString, required = false,
                                   default = nil)
  if valid_21627186 != nil:
    section.add "X-Amz-Date", valid_21627186
  var valid_21627187 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627187 = validateParameter(valid_21627187, JString, required = false,
                                   default = nil)
  if valid_21627187 != nil:
    section.add "X-Amz-Security-Token", valid_21627187
  var valid_21627188 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627188 = validateParameter(valid_21627188, JString, required = false,
                                   default = nil)
  if valid_21627188 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627188
  var valid_21627189 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627189 = validateParameter(valid_21627189, JString, required = false,
                                   default = nil)
  if valid_21627189 != nil:
    section.add "X-Amz-Algorithm", valid_21627189
  var valid_21627190 = header.getOrDefault("X-Amz-Signature")
  valid_21627190 = validateParameter(valid_21627190, JString, required = false,
                                   default = nil)
  if valid_21627190 != nil:
    section.add "X-Amz-Signature", valid_21627190
  var valid_21627191 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627191 = validateParameter(valid_21627191, JString, required = false,
                                   default = nil)
  if valid_21627191 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627191
  var valid_21627192 = header.getOrDefault("X-Amz-Credential")
  valid_21627192 = validateParameter(valid_21627192, JString, required = false,
                                   default = nil)
  if valid_21627192 != nil:
    section.add "X-Amz-Credential", valid_21627192
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : The starting index into the remaining list of platforms. Use the <code>NextToken</code> value from a previous <code>ListPlatformVersion</code> call.
  ##   Filters: JArray
  ##          : List only the platforms where the platform member value relates to one of the supplied values.
  ##   MaxRecords: JInt
  ##             : The maximum number of platform values returned in one call.
  section = newJObject()
  var valid_21627193 = formData.getOrDefault("NextToken")
  valid_21627193 = validateParameter(valid_21627193, JString, required = false,
                                   default = nil)
  if valid_21627193 != nil:
    section.add "NextToken", valid_21627193
  var valid_21627194 = formData.getOrDefault("Filters")
  valid_21627194 = validateParameter(valid_21627194, JArray, required = false,
                                   default = nil)
  if valid_21627194 != nil:
    section.add "Filters", valid_21627194
  var valid_21627195 = formData.getOrDefault("MaxRecords")
  valid_21627195 = validateParameter(valid_21627195, JInt, required = false,
                                   default = nil)
  if valid_21627195 != nil:
    section.add "MaxRecords", valid_21627195
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627196: Call_PostListPlatformVersions_21627181;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the available platforms.
  ## 
  let valid = call_21627196.validator(path, query, header, formData, body, _)
  let scheme = call_21627196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627196.makeUrl(scheme.get, call_21627196.host, call_21627196.base,
                               call_21627196.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627196, uri, valid, _)

proc call*(call_21627197: Call_PostListPlatformVersions_21627181;
          NextToken: string = ""; Action: string = "ListPlatformVersions";
          Filters: JsonNode = nil; MaxRecords: int = 0; Version: string = "2010-12-01"): Recallable =
  ## postListPlatformVersions
  ## Lists the available platforms.
  ##   NextToken: string
  ##            : The starting index into the remaining list of platforms. Use the <code>NextToken</code> value from a previous <code>ListPlatformVersion</code> call.
  ##   Action: string (required)
  ##   Filters: JArray
  ##          : List only the platforms where the platform member value relates to one of the supplied values.
  ##   MaxRecords: int
  ##             : The maximum number of platform values returned in one call.
  ##   Version: string (required)
  var query_21627198 = newJObject()
  var formData_21627199 = newJObject()
  add(formData_21627199, "NextToken", newJString(NextToken))
  add(query_21627198, "Action", newJString(Action))
  if Filters != nil:
    formData_21627199.add "Filters", Filters
  add(formData_21627199, "MaxRecords", newJInt(MaxRecords))
  add(query_21627198, "Version", newJString(Version))
  result = call_21627197.call(nil, query_21627198, nil, formData_21627199, nil)

var postListPlatformVersions* = Call_PostListPlatformVersions_21627181(
    name: "postListPlatformVersions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListPlatformVersions",
    validator: validate_PostListPlatformVersions_21627182, base: "/",
    makeUrl: url_PostListPlatformVersions_21627183,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListPlatformVersions_21627163 = ref object of OpenApiRestCall_21625437
proc url_GetListPlatformVersions_21627165(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListPlatformVersions_21627164(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the available platforms.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##             : The maximum number of platform values returned in one call.
  ##   Filters: JArray
  ##          : List only the platforms where the platform member value relates to one of the supplied values.
  ##   NextToken: JString
  ##            : The starting index into the remaining list of platforms. Use the <code>NextToken</code> value from a previous <code>ListPlatformVersion</code> call.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627166 = query.getOrDefault("MaxRecords")
  valid_21627166 = validateParameter(valid_21627166, JInt, required = false,
                                   default = nil)
  if valid_21627166 != nil:
    section.add "MaxRecords", valid_21627166
  var valid_21627167 = query.getOrDefault("Filters")
  valid_21627167 = validateParameter(valid_21627167, JArray, required = false,
                                   default = nil)
  if valid_21627167 != nil:
    section.add "Filters", valid_21627167
  var valid_21627168 = query.getOrDefault("NextToken")
  valid_21627168 = validateParameter(valid_21627168, JString, required = false,
                                   default = nil)
  if valid_21627168 != nil:
    section.add "NextToken", valid_21627168
  var valid_21627169 = query.getOrDefault("Action")
  valid_21627169 = validateParameter(valid_21627169, JString, required = true,
                                   default = newJString("ListPlatformVersions"))
  if valid_21627169 != nil:
    section.add "Action", valid_21627169
  var valid_21627170 = query.getOrDefault("Version")
  valid_21627170 = validateParameter(valid_21627170, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21627170 != nil:
    section.add "Version", valid_21627170
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627171 = header.getOrDefault("X-Amz-Date")
  valid_21627171 = validateParameter(valid_21627171, JString, required = false,
                                   default = nil)
  if valid_21627171 != nil:
    section.add "X-Amz-Date", valid_21627171
  var valid_21627172 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627172 = validateParameter(valid_21627172, JString, required = false,
                                   default = nil)
  if valid_21627172 != nil:
    section.add "X-Amz-Security-Token", valid_21627172
  var valid_21627173 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627173 = validateParameter(valid_21627173, JString, required = false,
                                   default = nil)
  if valid_21627173 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627173
  var valid_21627174 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627174 = validateParameter(valid_21627174, JString, required = false,
                                   default = nil)
  if valid_21627174 != nil:
    section.add "X-Amz-Algorithm", valid_21627174
  var valid_21627175 = header.getOrDefault("X-Amz-Signature")
  valid_21627175 = validateParameter(valid_21627175, JString, required = false,
                                   default = nil)
  if valid_21627175 != nil:
    section.add "X-Amz-Signature", valid_21627175
  var valid_21627176 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627176 = validateParameter(valid_21627176, JString, required = false,
                                   default = nil)
  if valid_21627176 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627176
  var valid_21627177 = header.getOrDefault("X-Amz-Credential")
  valid_21627177 = validateParameter(valid_21627177, JString, required = false,
                                   default = nil)
  if valid_21627177 != nil:
    section.add "X-Amz-Credential", valid_21627177
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627178: Call_GetListPlatformVersions_21627163;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the available platforms.
  ## 
  let valid = call_21627178.validator(path, query, header, formData, body, _)
  let scheme = call_21627178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627178.makeUrl(scheme.get, call_21627178.host, call_21627178.base,
                               call_21627178.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627178, uri, valid, _)

proc call*(call_21627179: Call_GetListPlatformVersions_21627163;
          MaxRecords: int = 0; Filters: JsonNode = nil; NextToken: string = "";
          Action: string = "ListPlatformVersions"; Version: string = "2010-12-01"): Recallable =
  ## getListPlatformVersions
  ## Lists the available platforms.
  ##   MaxRecords: int
  ##             : The maximum number of platform values returned in one call.
  ##   Filters: JArray
  ##          : List only the platforms where the platform member value relates to one of the supplied values.
  ##   NextToken: string
  ##            : The starting index into the remaining list of platforms. Use the <code>NextToken</code> value from a previous <code>ListPlatformVersion</code> call.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21627180 = newJObject()
  add(query_21627180, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_21627180.add "Filters", Filters
  add(query_21627180, "NextToken", newJString(NextToken))
  add(query_21627180, "Action", newJString(Action))
  add(query_21627180, "Version", newJString(Version))
  result = call_21627179.call(nil, query_21627180, nil, nil, nil)

var getListPlatformVersions* = Call_GetListPlatformVersions_21627163(
    name: "getListPlatformVersions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListPlatformVersions",
    validator: validate_GetListPlatformVersions_21627164, base: "/",
    makeUrl: url_GetListPlatformVersions_21627165,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_21627216 = ref object of OpenApiRestCall_21625437
proc url_PostListTagsForResource_21627218(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListTagsForResource_21627217(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627219 = query.getOrDefault("Action")
  valid_21627219 = validateParameter(valid_21627219, JString, required = true,
                                   default = newJString("ListTagsForResource"))
  if valid_21627219 != nil:
    section.add "Action", valid_21627219
  var valid_21627220 = query.getOrDefault("Version")
  valid_21627220 = validateParameter(valid_21627220, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21627220 != nil:
    section.add "Version", valid_21627220
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627221 = header.getOrDefault("X-Amz-Date")
  valid_21627221 = validateParameter(valid_21627221, JString, required = false,
                                   default = nil)
  if valid_21627221 != nil:
    section.add "X-Amz-Date", valid_21627221
  var valid_21627222 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627222 = validateParameter(valid_21627222, JString, required = false,
                                   default = nil)
  if valid_21627222 != nil:
    section.add "X-Amz-Security-Token", valid_21627222
  var valid_21627223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627223 = validateParameter(valid_21627223, JString, required = false,
                                   default = nil)
  if valid_21627223 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627223
  var valid_21627224 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627224 = validateParameter(valid_21627224, JString, required = false,
                                   default = nil)
  if valid_21627224 != nil:
    section.add "X-Amz-Algorithm", valid_21627224
  var valid_21627225 = header.getOrDefault("X-Amz-Signature")
  valid_21627225 = validateParameter(valid_21627225, JString, required = false,
                                   default = nil)
  if valid_21627225 != nil:
    section.add "X-Amz-Signature", valid_21627225
  var valid_21627226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627226 = validateParameter(valid_21627226, JString, required = false,
                                   default = nil)
  if valid_21627226 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627226
  var valid_21627227 = header.getOrDefault("X-Amz-Credential")
  valid_21627227 = validateParameter(valid_21627227, JString, required = false,
                                   default = nil)
  if valid_21627227 != nil:
    section.add "X-Amz-Credential", valid_21627227
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArn: JString (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce for which a tag list is requested.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArn` field"
  var valid_21627228 = formData.getOrDefault("ResourceArn")
  valid_21627228 = validateParameter(valid_21627228, JString, required = true,
                                   default = nil)
  if valid_21627228 != nil:
    section.add "ResourceArn", valid_21627228
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627229: Call_PostListTagsForResource_21627216;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ## 
  let valid = call_21627229.validator(path, query, header, formData, body, _)
  let scheme = call_21627229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627229.makeUrl(scheme.get, call_21627229.host, call_21627229.base,
                               call_21627229.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627229, uri, valid, _)

proc call*(call_21627230: Call_PostListTagsForResource_21627216;
          ResourceArn: string; Action: string = "ListTagsForResource";
          Version: string = "2010-12-01"): Recallable =
  ## postListTagsForResource
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ##   Action: string (required)
  ##   ResourceArn: string (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce for which a tag list is requested.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  ##   Version: string (required)
  var query_21627231 = newJObject()
  var formData_21627232 = newJObject()
  add(query_21627231, "Action", newJString(Action))
  add(formData_21627232, "ResourceArn", newJString(ResourceArn))
  add(query_21627231, "Version", newJString(Version))
  result = call_21627230.call(nil, query_21627231, nil, formData_21627232, nil)

var postListTagsForResource* = Call_PostListTagsForResource_21627216(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_21627217, base: "/",
    makeUrl: url_PostListTagsForResource_21627218,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_21627200 = ref object of OpenApiRestCall_21625437
proc url_GetListTagsForResource_21627202(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListTagsForResource_21627201(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627203 = query.getOrDefault("ResourceArn")
  valid_21627203 = validateParameter(valid_21627203, JString, required = true,
                                   default = nil)
  if valid_21627203 != nil:
    section.add "ResourceArn", valid_21627203
  var valid_21627204 = query.getOrDefault("Action")
  valid_21627204 = validateParameter(valid_21627204, JString, required = true,
                                   default = newJString("ListTagsForResource"))
  if valid_21627204 != nil:
    section.add "Action", valid_21627204
  var valid_21627205 = query.getOrDefault("Version")
  valid_21627205 = validateParameter(valid_21627205, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21627205 != nil:
    section.add "Version", valid_21627205
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627206 = header.getOrDefault("X-Amz-Date")
  valid_21627206 = validateParameter(valid_21627206, JString, required = false,
                                   default = nil)
  if valid_21627206 != nil:
    section.add "X-Amz-Date", valid_21627206
  var valid_21627207 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627207 = validateParameter(valid_21627207, JString, required = false,
                                   default = nil)
  if valid_21627207 != nil:
    section.add "X-Amz-Security-Token", valid_21627207
  var valid_21627208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627208 = validateParameter(valid_21627208, JString, required = false,
                                   default = nil)
  if valid_21627208 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627208
  var valid_21627209 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627209 = validateParameter(valid_21627209, JString, required = false,
                                   default = nil)
  if valid_21627209 != nil:
    section.add "X-Amz-Algorithm", valid_21627209
  var valid_21627210 = header.getOrDefault("X-Amz-Signature")
  valid_21627210 = validateParameter(valid_21627210, JString, required = false,
                                   default = nil)
  if valid_21627210 != nil:
    section.add "X-Amz-Signature", valid_21627210
  var valid_21627211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627211 = validateParameter(valid_21627211, JString, required = false,
                                   default = nil)
  if valid_21627211 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627211
  var valid_21627212 = header.getOrDefault("X-Amz-Credential")
  valid_21627212 = validateParameter(valid_21627212, JString, required = false,
                                   default = nil)
  if valid_21627212 != nil:
    section.add "X-Amz-Credential", valid_21627212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627213: Call_GetListTagsForResource_21627200;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ## 
  let valid = call_21627213.validator(path, query, header, formData, body, _)
  let scheme = call_21627213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627213.makeUrl(scheme.get, call_21627213.host, call_21627213.base,
                               call_21627213.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627213, uri, valid, _)

proc call*(call_21627214: Call_GetListTagsForResource_21627200;
          ResourceArn: string; Action: string = "ListTagsForResource";
          Version: string = "2010-12-01"): Recallable =
  ## getListTagsForResource
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ##   ResourceArn: string (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce for which a tag list is requested.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21627215 = newJObject()
  add(query_21627215, "ResourceArn", newJString(ResourceArn))
  add(query_21627215, "Action", newJString(Action))
  add(query_21627215, "Version", newJString(Version))
  result = call_21627214.call(nil, query_21627215, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_21627200(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_21627201, base: "/",
    makeUrl: url_GetListTagsForResource_21627202,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebuildEnvironment_21627250 = ref object of OpenApiRestCall_21625437
proc url_PostRebuildEnvironment_21627252(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRebuildEnvironment_21627251(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627253 = query.getOrDefault("Action")
  valid_21627253 = validateParameter(valid_21627253, JString, required = true,
                                   default = newJString("RebuildEnvironment"))
  if valid_21627253 != nil:
    section.add "Action", valid_21627253
  var valid_21627254 = query.getOrDefault("Version")
  valid_21627254 = validateParameter(valid_21627254, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21627254 != nil:
    section.add "Version", valid_21627254
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627255 = header.getOrDefault("X-Amz-Date")
  valid_21627255 = validateParameter(valid_21627255, JString, required = false,
                                   default = nil)
  if valid_21627255 != nil:
    section.add "X-Amz-Date", valid_21627255
  var valid_21627256 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627256 = validateParameter(valid_21627256, JString, required = false,
                                   default = nil)
  if valid_21627256 != nil:
    section.add "X-Amz-Security-Token", valid_21627256
  var valid_21627257 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627257 = validateParameter(valid_21627257, JString, required = false,
                                   default = nil)
  if valid_21627257 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627257
  var valid_21627258 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627258 = validateParameter(valid_21627258, JString, required = false,
                                   default = nil)
  if valid_21627258 != nil:
    section.add "X-Amz-Algorithm", valid_21627258
  var valid_21627259 = header.getOrDefault("X-Amz-Signature")
  valid_21627259 = validateParameter(valid_21627259, JString, required = false,
                                   default = nil)
  if valid_21627259 != nil:
    section.add "X-Amz-Signature", valid_21627259
  var valid_21627260 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627260 = validateParameter(valid_21627260, JString, required = false,
                                   default = nil)
  if valid_21627260 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627260
  var valid_21627261 = header.getOrDefault("X-Amz-Credential")
  valid_21627261 = validateParameter(valid_21627261, JString, required = false,
                                   default = nil)
  if valid_21627261 != nil:
    section.add "X-Amz-Credential", valid_21627261
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to rebuild.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to rebuild.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_21627262 = formData.getOrDefault("EnvironmentId")
  valid_21627262 = validateParameter(valid_21627262, JString, required = false,
                                   default = nil)
  if valid_21627262 != nil:
    section.add "EnvironmentId", valid_21627262
  var valid_21627263 = formData.getOrDefault("EnvironmentName")
  valid_21627263 = validateParameter(valid_21627263, JString, required = false,
                                   default = nil)
  if valid_21627263 != nil:
    section.add "EnvironmentName", valid_21627263
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627264: Call_PostRebuildEnvironment_21627250;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes and recreates all of the AWS resources (for example: the Auto Scaling group, load balancer, etc.) for a specified environment and forces a restart.
  ## 
  let valid = call_21627264.validator(path, query, header, formData, body, _)
  let scheme = call_21627264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627264.makeUrl(scheme.get, call_21627264.host, call_21627264.base,
                               call_21627264.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627264, uri, valid, _)

proc call*(call_21627265: Call_PostRebuildEnvironment_21627250;
          EnvironmentId: string = ""; EnvironmentName: string = "";
          Action: string = "RebuildEnvironment"; Version: string = "2010-12-01"): Recallable =
  ## postRebuildEnvironment
  ## Deletes and recreates all of the AWS resources (for example: the Auto Scaling group, load balancer, etc.) for a specified environment and forces a restart.
  ##   EnvironmentId: string
  ##                : <p>The ID of the environment to rebuild.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentName: string
  ##                  : <p>The name of the environment to rebuild.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21627266 = newJObject()
  var formData_21627267 = newJObject()
  add(formData_21627267, "EnvironmentId", newJString(EnvironmentId))
  add(formData_21627267, "EnvironmentName", newJString(EnvironmentName))
  add(query_21627266, "Action", newJString(Action))
  add(query_21627266, "Version", newJString(Version))
  result = call_21627265.call(nil, query_21627266, nil, formData_21627267, nil)

var postRebuildEnvironment* = Call_PostRebuildEnvironment_21627250(
    name: "postRebuildEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RebuildEnvironment",
    validator: validate_PostRebuildEnvironment_21627251, base: "/",
    makeUrl: url_PostRebuildEnvironment_21627252,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebuildEnvironment_21627233 = ref object of OpenApiRestCall_21625437
proc url_GetRebuildEnvironment_21627235(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRebuildEnvironment_21627234(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to rebuild.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627236 = query.getOrDefault("EnvironmentName")
  valid_21627236 = validateParameter(valid_21627236, JString, required = false,
                                   default = nil)
  if valid_21627236 != nil:
    section.add "EnvironmentName", valid_21627236
  var valid_21627237 = query.getOrDefault("Action")
  valid_21627237 = validateParameter(valid_21627237, JString, required = true,
                                   default = newJString("RebuildEnvironment"))
  if valid_21627237 != nil:
    section.add "Action", valid_21627237
  var valid_21627238 = query.getOrDefault("EnvironmentId")
  valid_21627238 = validateParameter(valid_21627238, JString, required = false,
                                   default = nil)
  if valid_21627238 != nil:
    section.add "EnvironmentId", valid_21627238
  var valid_21627239 = query.getOrDefault("Version")
  valid_21627239 = validateParameter(valid_21627239, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21627239 != nil:
    section.add "Version", valid_21627239
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627240 = header.getOrDefault("X-Amz-Date")
  valid_21627240 = validateParameter(valid_21627240, JString, required = false,
                                   default = nil)
  if valid_21627240 != nil:
    section.add "X-Amz-Date", valid_21627240
  var valid_21627241 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627241 = validateParameter(valid_21627241, JString, required = false,
                                   default = nil)
  if valid_21627241 != nil:
    section.add "X-Amz-Security-Token", valid_21627241
  var valid_21627242 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627242 = validateParameter(valid_21627242, JString, required = false,
                                   default = nil)
  if valid_21627242 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627242
  var valid_21627243 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627243 = validateParameter(valid_21627243, JString, required = false,
                                   default = nil)
  if valid_21627243 != nil:
    section.add "X-Amz-Algorithm", valid_21627243
  var valid_21627244 = header.getOrDefault("X-Amz-Signature")
  valid_21627244 = validateParameter(valid_21627244, JString, required = false,
                                   default = nil)
  if valid_21627244 != nil:
    section.add "X-Amz-Signature", valid_21627244
  var valid_21627245 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627245 = validateParameter(valid_21627245, JString, required = false,
                                   default = nil)
  if valid_21627245 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627245
  var valid_21627246 = header.getOrDefault("X-Amz-Credential")
  valid_21627246 = validateParameter(valid_21627246, JString, required = false,
                                   default = nil)
  if valid_21627246 != nil:
    section.add "X-Amz-Credential", valid_21627246
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627247: Call_GetRebuildEnvironment_21627233;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes and recreates all of the AWS resources (for example: the Auto Scaling group, load balancer, etc.) for a specified environment and forces a restart.
  ## 
  let valid = call_21627247.validator(path, query, header, formData, body, _)
  let scheme = call_21627247.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627247.makeUrl(scheme.get, call_21627247.host, call_21627247.base,
                               call_21627247.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627247, uri, valid, _)

proc call*(call_21627248: Call_GetRebuildEnvironment_21627233;
          EnvironmentName: string = ""; Action: string = "RebuildEnvironment";
          EnvironmentId: string = ""; Version: string = "2010-12-01"): Recallable =
  ## getRebuildEnvironment
  ## Deletes and recreates all of the AWS resources (for example: the Auto Scaling group, load balancer, etc.) for a specified environment and forces a restart.
  ##   EnvironmentName: string
  ##                  : <p>The name of the environment to rebuild.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Action: string (required)
  ##   EnvironmentId: string
  ##                : <p>The ID of the environment to rebuild.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Version: string (required)
  var query_21627249 = newJObject()
  add(query_21627249, "EnvironmentName", newJString(EnvironmentName))
  add(query_21627249, "Action", newJString(Action))
  add(query_21627249, "EnvironmentId", newJString(EnvironmentId))
  add(query_21627249, "Version", newJString(Version))
  result = call_21627248.call(nil, query_21627249, nil, nil, nil)

var getRebuildEnvironment* = Call_GetRebuildEnvironment_21627233(
    name: "getRebuildEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RebuildEnvironment",
    validator: validate_GetRebuildEnvironment_21627234, base: "/",
    makeUrl: url_GetRebuildEnvironment_21627235,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRequestEnvironmentInfo_21627286 = ref object of OpenApiRestCall_21625437
proc url_PostRequestEnvironmentInfo_21627288(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRequestEnvironmentInfo_21627287(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627289 = query.getOrDefault("Action")
  valid_21627289 = validateParameter(valid_21627289, JString, required = true, default = newJString(
      "RequestEnvironmentInfo"))
  if valid_21627289 != nil:
    section.add "Action", valid_21627289
  var valid_21627290 = query.getOrDefault("Version")
  valid_21627290 = validateParameter(valid_21627290, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21627290 != nil:
    section.add "Version", valid_21627290
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627291 = header.getOrDefault("X-Amz-Date")
  valid_21627291 = validateParameter(valid_21627291, JString, required = false,
                                   default = nil)
  if valid_21627291 != nil:
    section.add "X-Amz-Date", valid_21627291
  var valid_21627292 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627292 = validateParameter(valid_21627292, JString, required = false,
                                   default = nil)
  if valid_21627292 != nil:
    section.add "X-Amz-Security-Token", valid_21627292
  var valid_21627293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627293 = validateParameter(valid_21627293, JString, required = false,
                                   default = nil)
  if valid_21627293 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627293
  var valid_21627294 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627294 = validateParameter(valid_21627294, JString, required = false,
                                   default = nil)
  if valid_21627294 != nil:
    section.add "X-Amz-Algorithm", valid_21627294
  var valid_21627295 = header.getOrDefault("X-Amz-Signature")
  valid_21627295 = validateParameter(valid_21627295, JString, required = false,
                                   default = nil)
  if valid_21627295 != nil:
    section.add "X-Amz-Signature", valid_21627295
  var valid_21627296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627296 = validateParameter(valid_21627296, JString, required = false,
                                   default = nil)
  if valid_21627296 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627296
  var valid_21627297 = header.getOrDefault("X-Amz-Credential")
  valid_21627297 = validateParameter(valid_21627297, JString, required = false,
                                   default = nil)
  if valid_21627297 != nil:
    section.add "X-Amz-Credential", valid_21627297
  result.add "header", section
  ## parameters in `formData` object:
  ##   InfoType: JString (required)
  ##           : The type of information to request.
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment of the requested data.</p> <p>If no such environment is found, <code>RequestEnvironmentInfo</code> returns an <code>InvalidParameterValue</code> error. </p> <p>Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment of the requested data.</p> <p>If no such environment is found, <code>RequestEnvironmentInfo</code> returns an <code>InvalidParameterValue</code> error. </p> <p>Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_21627298 = formData.getOrDefault("InfoType")
  valid_21627298 = validateParameter(valid_21627298, JString, required = true,
                                   default = newJString("tail"))
  if valid_21627298 != nil:
    section.add "InfoType", valid_21627298
  var valid_21627299 = formData.getOrDefault("EnvironmentId")
  valid_21627299 = validateParameter(valid_21627299, JString, required = false,
                                   default = nil)
  if valid_21627299 != nil:
    section.add "EnvironmentId", valid_21627299
  var valid_21627300 = formData.getOrDefault("EnvironmentName")
  valid_21627300 = validateParameter(valid_21627300, JString, required = false,
                                   default = nil)
  if valid_21627300 != nil:
    section.add "EnvironmentName", valid_21627300
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627301: Call_PostRequestEnvironmentInfo_21627286;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Initiates a request to compile the specified type of information of the deployed environment.</p> <p> Setting the <code>InfoType</code> to <code>tail</code> compiles the last lines from the application server log files of every Amazon EC2 instance in your environment. </p> <p> Setting the <code>InfoType</code> to <code>bundle</code> compresses the application server log files for every Amazon EC2 instance into a <code>.zip</code> file. Legacy and .NET containers do not support bundle logs. </p> <p> Use <a>RetrieveEnvironmentInfo</a> to obtain the set of logs. </p> <p>Related Topics</p> <ul> <li> <p> <a>RetrieveEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_21627301.validator(path, query, header, formData, body, _)
  let scheme = call_21627301.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627301.makeUrl(scheme.get, call_21627301.host, call_21627301.base,
                               call_21627301.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627301, uri, valid, _)

proc call*(call_21627302: Call_PostRequestEnvironmentInfo_21627286;
          InfoType: string = "tail"; EnvironmentId: string = "";
          EnvironmentName: string = ""; Action: string = "RequestEnvironmentInfo";
          Version: string = "2010-12-01"): Recallable =
  ## postRequestEnvironmentInfo
  ## <p>Initiates a request to compile the specified type of information of the deployed environment.</p> <p> Setting the <code>InfoType</code> to <code>tail</code> compiles the last lines from the application server log files of every Amazon EC2 instance in your environment. </p> <p> Setting the <code>InfoType</code> to <code>bundle</code> compresses the application server log files for every Amazon EC2 instance into a <code>.zip</code> file. Legacy and .NET containers do not support bundle logs. </p> <p> Use <a>RetrieveEnvironmentInfo</a> to obtain the set of logs. </p> <p>Related Topics</p> <ul> <li> <p> <a>RetrieveEnvironmentInfo</a> </p> </li> </ul>
  ##   InfoType: string (required)
  ##           : The type of information to request.
  ##   EnvironmentId: string
  ##                : <p>The ID of the environment of the requested data.</p> <p>If no such environment is found, <code>RequestEnvironmentInfo</code> returns an <code>InvalidParameterValue</code> error. </p> <p>Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentName: string
  ##                  : <p>The name of the environment of the requested data.</p> <p>If no such environment is found, <code>RequestEnvironmentInfo</code> returns an <code>InvalidParameterValue</code> error. </p> <p>Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21627303 = newJObject()
  var formData_21627304 = newJObject()
  add(formData_21627304, "InfoType", newJString(InfoType))
  add(formData_21627304, "EnvironmentId", newJString(EnvironmentId))
  add(formData_21627304, "EnvironmentName", newJString(EnvironmentName))
  add(query_21627303, "Action", newJString(Action))
  add(query_21627303, "Version", newJString(Version))
  result = call_21627302.call(nil, query_21627303, nil, formData_21627304, nil)

var postRequestEnvironmentInfo* = Call_PostRequestEnvironmentInfo_21627286(
    name: "postRequestEnvironmentInfo", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RequestEnvironmentInfo",
    validator: validate_PostRequestEnvironmentInfo_21627287, base: "/",
    makeUrl: url_PostRequestEnvironmentInfo_21627288,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRequestEnvironmentInfo_21627268 = ref object of OpenApiRestCall_21625437
proc url_GetRequestEnvironmentInfo_21627270(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRequestEnvironmentInfo_21627269(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment of the requested data.</p> <p>If no such environment is found, <code>RequestEnvironmentInfo</code> returns an <code>InvalidParameterValue</code> error. </p> <p>Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627271 = query.getOrDefault("InfoType")
  valid_21627271 = validateParameter(valid_21627271, JString, required = true,
                                   default = newJString("tail"))
  if valid_21627271 != nil:
    section.add "InfoType", valid_21627271
  var valid_21627272 = query.getOrDefault("EnvironmentName")
  valid_21627272 = validateParameter(valid_21627272, JString, required = false,
                                   default = nil)
  if valid_21627272 != nil:
    section.add "EnvironmentName", valid_21627272
  var valid_21627273 = query.getOrDefault("Action")
  valid_21627273 = validateParameter(valid_21627273, JString, required = true, default = newJString(
      "RequestEnvironmentInfo"))
  if valid_21627273 != nil:
    section.add "Action", valid_21627273
  var valid_21627274 = query.getOrDefault("EnvironmentId")
  valid_21627274 = validateParameter(valid_21627274, JString, required = false,
                                   default = nil)
  if valid_21627274 != nil:
    section.add "EnvironmentId", valid_21627274
  var valid_21627275 = query.getOrDefault("Version")
  valid_21627275 = validateParameter(valid_21627275, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21627275 != nil:
    section.add "Version", valid_21627275
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627276 = header.getOrDefault("X-Amz-Date")
  valid_21627276 = validateParameter(valid_21627276, JString, required = false,
                                   default = nil)
  if valid_21627276 != nil:
    section.add "X-Amz-Date", valid_21627276
  var valid_21627277 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627277 = validateParameter(valid_21627277, JString, required = false,
                                   default = nil)
  if valid_21627277 != nil:
    section.add "X-Amz-Security-Token", valid_21627277
  var valid_21627278 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627278 = validateParameter(valid_21627278, JString, required = false,
                                   default = nil)
  if valid_21627278 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627278
  var valid_21627279 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627279 = validateParameter(valid_21627279, JString, required = false,
                                   default = nil)
  if valid_21627279 != nil:
    section.add "X-Amz-Algorithm", valid_21627279
  var valid_21627280 = header.getOrDefault("X-Amz-Signature")
  valid_21627280 = validateParameter(valid_21627280, JString, required = false,
                                   default = nil)
  if valid_21627280 != nil:
    section.add "X-Amz-Signature", valid_21627280
  var valid_21627281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627281 = validateParameter(valid_21627281, JString, required = false,
                                   default = nil)
  if valid_21627281 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627281
  var valid_21627282 = header.getOrDefault("X-Amz-Credential")
  valid_21627282 = validateParameter(valid_21627282, JString, required = false,
                                   default = nil)
  if valid_21627282 != nil:
    section.add "X-Amz-Credential", valid_21627282
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627283: Call_GetRequestEnvironmentInfo_21627268;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Initiates a request to compile the specified type of information of the deployed environment.</p> <p> Setting the <code>InfoType</code> to <code>tail</code> compiles the last lines from the application server log files of every Amazon EC2 instance in your environment. </p> <p> Setting the <code>InfoType</code> to <code>bundle</code> compresses the application server log files for every Amazon EC2 instance into a <code>.zip</code> file. Legacy and .NET containers do not support bundle logs. </p> <p> Use <a>RetrieveEnvironmentInfo</a> to obtain the set of logs. </p> <p>Related Topics</p> <ul> <li> <p> <a>RetrieveEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_21627283.validator(path, query, header, formData, body, _)
  let scheme = call_21627283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627283.makeUrl(scheme.get, call_21627283.host, call_21627283.base,
                               call_21627283.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627283, uri, valid, _)

proc call*(call_21627284: Call_GetRequestEnvironmentInfo_21627268;
          InfoType: string = "tail"; EnvironmentName: string = "";
          Action: string = "RequestEnvironmentInfo"; EnvironmentId: string = "";
          Version: string = "2010-12-01"): Recallable =
  ## getRequestEnvironmentInfo
  ## <p>Initiates a request to compile the specified type of information of the deployed environment.</p> <p> Setting the <code>InfoType</code> to <code>tail</code> compiles the last lines from the application server log files of every Amazon EC2 instance in your environment. </p> <p> Setting the <code>InfoType</code> to <code>bundle</code> compresses the application server log files for every Amazon EC2 instance into a <code>.zip</code> file. Legacy and .NET containers do not support bundle logs. </p> <p> Use <a>RetrieveEnvironmentInfo</a> to obtain the set of logs. </p> <p>Related Topics</p> <ul> <li> <p> <a>RetrieveEnvironmentInfo</a> </p> </li> </ul>
  ##   InfoType: string (required)
  ##           : The type of information to request.
  ##   EnvironmentName: string
  ##                  : <p>The name of the environment of the requested data.</p> <p>If no such environment is found, <code>RequestEnvironmentInfo</code> returns an <code>InvalidParameterValue</code> error. </p> <p>Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Action: string (required)
  ##   EnvironmentId: string
  ##                : <p>The ID of the environment of the requested data.</p> <p>If no such environment is found, <code>RequestEnvironmentInfo</code> returns an <code>InvalidParameterValue</code> error. </p> <p>Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Version: string (required)
  var query_21627285 = newJObject()
  add(query_21627285, "InfoType", newJString(InfoType))
  add(query_21627285, "EnvironmentName", newJString(EnvironmentName))
  add(query_21627285, "Action", newJString(Action))
  add(query_21627285, "EnvironmentId", newJString(EnvironmentId))
  add(query_21627285, "Version", newJString(Version))
  result = call_21627284.call(nil, query_21627285, nil, nil, nil)

var getRequestEnvironmentInfo* = Call_GetRequestEnvironmentInfo_21627268(
    name: "getRequestEnvironmentInfo", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RequestEnvironmentInfo",
    validator: validate_GetRequestEnvironmentInfo_21627269, base: "/",
    makeUrl: url_GetRequestEnvironmentInfo_21627270,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestartAppServer_21627322 = ref object of OpenApiRestCall_21625437
proc url_PostRestartAppServer_21627324(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRestartAppServer_21627323(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627325 = query.getOrDefault("Action")
  valid_21627325 = validateParameter(valid_21627325, JString, required = true,
                                   default = newJString("RestartAppServer"))
  if valid_21627325 != nil:
    section.add "Action", valid_21627325
  var valid_21627326 = query.getOrDefault("Version")
  valid_21627326 = validateParameter(valid_21627326, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21627326 != nil:
    section.add "Version", valid_21627326
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627327 = header.getOrDefault("X-Amz-Date")
  valid_21627327 = validateParameter(valid_21627327, JString, required = false,
                                   default = nil)
  if valid_21627327 != nil:
    section.add "X-Amz-Date", valid_21627327
  var valid_21627328 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627328 = validateParameter(valid_21627328, JString, required = false,
                                   default = nil)
  if valid_21627328 != nil:
    section.add "X-Amz-Security-Token", valid_21627328
  var valid_21627329 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627329 = validateParameter(valid_21627329, JString, required = false,
                                   default = nil)
  if valid_21627329 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627329
  var valid_21627330 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627330 = validateParameter(valid_21627330, JString, required = false,
                                   default = nil)
  if valid_21627330 != nil:
    section.add "X-Amz-Algorithm", valid_21627330
  var valid_21627331 = header.getOrDefault("X-Amz-Signature")
  valid_21627331 = validateParameter(valid_21627331, JString, required = false,
                                   default = nil)
  if valid_21627331 != nil:
    section.add "X-Amz-Signature", valid_21627331
  var valid_21627332 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627332 = validateParameter(valid_21627332, JString, required = false,
                                   default = nil)
  if valid_21627332 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627332
  var valid_21627333 = header.getOrDefault("X-Amz-Credential")
  valid_21627333 = validateParameter(valid_21627333, JString, required = false,
                                   default = nil)
  if valid_21627333 != nil:
    section.add "X-Amz-Credential", valid_21627333
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to restart the server for.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to restart the server for.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_21627334 = formData.getOrDefault("EnvironmentId")
  valid_21627334 = validateParameter(valid_21627334, JString, required = false,
                                   default = nil)
  if valid_21627334 != nil:
    section.add "EnvironmentId", valid_21627334
  var valid_21627335 = formData.getOrDefault("EnvironmentName")
  valid_21627335 = validateParameter(valid_21627335, JString, required = false,
                                   default = nil)
  if valid_21627335 != nil:
    section.add "EnvironmentName", valid_21627335
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627336: Call_PostRestartAppServer_21627322; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Causes the environment to restart the application container server running on each Amazon EC2 instance.
  ## 
  let valid = call_21627336.validator(path, query, header, formData, body, _)
  let scheme = call_21627336.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627336.makeUrl(scheme.get, call_21627336.host, call_21627336.base,
                               call_21627336.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627336, uri, valid, _)

proc call*(call_21627337: Call_PostRestartAppServer_21627322;
          EnvironmentId: string = ""; EnvironmentName: string = "";
          Action: string = "RestartAppServer"; Version: string = "2010-12-01"): Recallable =
  ## postRestartAppServer
  ## Causes the environment to restart the application container server running on each Amazon EC2 instance.
  ##   EnvironmentId: string
  ##                : <p>The ID of the environment to restart the server for.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentName: string
  ##                  : <p>The name of the environment to restart the server for.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21627338 = newJObject()
  var formData_21627339 = newJObject()
  add(formData_21627339, "EnvironmentId", newJString(EnvironmentId))
  add(formData_21627339, "EnvironmentName", newJString(EnvironmentName))
  add(query_21627338, "Action", newJString(Action))
  add(query_21627338, "Version", newJString(Version))
  result = call_21627337.call(nil, query_21627338, nil, formData_21627339, nil)

var postRestartAppServer* = Call_PostRestartAppServer_21627322(
    name: "postRestartAppServer", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RestartAppServer",
    validator: validate_PostRestartAppServer_21627323, base: "/",
    makeUrl: url_PostRestartAppServer_21627324,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestartAppServer_21627305 = ref object of OpenApiRestCall_21625437
proc url_GetRestartAppServer_21627307(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRestartAppServer_21627306(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to restart the server for.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627308 = query.getOrDefault("EnvironmentName")
  valid_21627308 = validateParameter(valid_21627308, JString, required = false,
                                   default = nil)
  if valid_21627308 != nil:
    section.add "EnvironmentName", valid_21627308
  var valid_21627309 = query.getOrDefault("Action")
  valid_21627309 = validateParameter(valid_21627309, JString, required = true,
                                   default = newJString("RestartAppServer"))
  if valid_21627309 != nil:
    section.add "Action", valid_21627309
  var valid_21627310 = query.getOrDefault("EnvironmentId")
  valid_21627310 = validateParameter(valid_21627310, JString, required = false,
                                   default = nil)
  if valid_21627310 != nil:
    section.add "EnvironmentId", valid_21627310
  var valid_21627311 = query.getOrDefault("Version")
  valid_21627311 = validateParameter(valid_21627311, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21627311 != nil:
    section.add "Version", valid_21627311
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627312 = header.getOrDefault("X-Amz-Date")
  valid_21627312 = validateParameter(valid_21627312, JString, required = false,
                                   default = nil)
  if valid_21627312 != nil:
    section.add "X-Amz-Date", valid_21627312
  var valid_21627313 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627313 = validateParameter(valid_21627313, JString, required = false,
                                   default = nil)
  if valid_21627313 != nil:
    section.add "X-Amz-Security-Token", valid_21627313
  var valid_21627314 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627314 = validateParameter(valid_21627314, JString, required = false,
                                   default = nil)
  if valid_21627314 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627314
  var valid_21627315 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627315 = validateParameter(valid_21627315, JString, required = false,
                                   default = nil)
  if valid_21627315 != nil:
    section.add "X-Amz-Algorithm", valid_21627315
  var valid_21627316 = header.getOrDefault("X-Amz-Signature")
  valid_21627316 = validateParameter(valid_21627316, JString, required = false,
                                   default = nil)
  if valid_21627316 != nil:
    section.add "X-Amz-Signature", valid_21627316
  var valid_21627317 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627317 = validateParameter(valid_21627317, JString, required = false,
                                   default = nil)
  if valid_21627317 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627317
  var valid_21627318 = header.getOrDefault("X-Amz-Credential")
  valid_21627318 = validateParameter(valid_21627318, JString, required = false,
                                   default = nil)
  if valid_21627318 != nil:
    section.add "X-Amz-Credential", valid_21627318
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627319: Call_GetRestartAppServer_21627305; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Causes the environment to restart the application container server running on each Amazon EC2 instance.
  ## 
  let valid = call_21627319.validator(path, query, header, formData, body, _)
  let scheme = call_21627319.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627319.makeUrl(scheme.get, call_21627319.host, call_21627319.base,
                               call_21627319.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627319, uri, valid, _)

proc call*(call_21627320: Call_GetRestartAppServer_21627305;
          EnvironmentName: string = ""; Action: string = "RestartAppServer";
          EnvironmentId: string = ""; Version: string = "2010-12-01"): Recallable =
  ## getRestartAppServer
  ## Causes the environment to restart the application container server running on each Amazon EC2 instance.
  ##   EnvironmentName: string
  ##                  : <p>The name of the environment to restart the server for.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Action: string (required)
  ##   EnvironmentId: string
  ##                : <p>The ID of the environment to restart the server for.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Version: string (required)
  var query_21627321 = newJObject()
  add(query_21627321, "EnvironmentName", newJString(EnvironmentName))
  add(query_21627321, "Action", newJString(Action))
  add(query_21627321, "EnvironmentId", newJString(EnvironmentId))
  add(query_21627321, "Version", newJString(Version))
  result = call_21627320.call(nil, query_21627321, nil, nil, nil)

var getRestartAppServer* = Call_GetRestartAppServer_21627305(
    name: "getRestartAppServer", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RestartAppServer",
    validator: validate_GetRestartAppServer_21627306, base: "/",
    makeUrl: url_GetRestartAppServer_21627307,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRetrieveEnvironmentInfo_21627358 = ref object of OpenApiRestCall_21625437
proc url_PostRetrieveEnvironmentInfo_21627360(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRetrieveEnvironmentInfo_21627359(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627361 = query.getOrDefault("Action")
  valid_21627361 = validateParameter(valid_21627361, JString, required = true, default = newJString(
      "RetrieveEnvironmentInfo"))
  if valid_21627361 != nil:
    section.add "Action", valid_21627361
  var valid_21627362 = query.getOrDefault("Version")
  valid_21627362 = validateParameter(valid_21627362, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21627362 != nil:
    section.add "Version", valid_21627362
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627363 = header.getOrDefault("X-Amz-Date")
  valid_21627363 = validateParameter(valid_21627363, JString, required = false,
                                   default = nil)
  if valid_21627363 != nil:
    section.add "X-Amz-Date", valid_21627363
  var valid_21627364 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627364 = validateParameter(valid_21627364, JString, required = false,
                                   default = nil)
  if valid_21627364 != nil:
    section.add "X-Amz-Security-Token", valid_21627364
  var valid_21627365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627365 = validateParameter(valid_21627365, JString, required = false,
                                   default = nil)
  if valid_21627365 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627365
  var valid_21627366 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627366 = validateParameter(valid_21627366, JString, required = false,
                                   default = nil)
  if valid_21627366 != nil:
    section.add "X-Amz-Algorithm", valid_21627366
  var valid_21627367 = header.getOrDefault("X-Amz-Signature")
  valid_21627367 = validateParameter(valid_21627367, JString, required = false,
                                   default = nil)
  if valid_21627367 != nil:
    section.add "X-Amz-Signature", valid_21627367
  var valid_21627368 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627368 = validateParameter(valid_21627368, JString, required = false,
                                   default = nil)
  if valid_21627368 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627368
  var valid_21627369 = header.getOrDefault("X-Amz-Credential")
  valid_21627369 = validateParameter(valid_21627369, JString, required = false,
                                   default = nil)
  if valid_21627369 != nil:
    section.add "X-Amz-Credential", valid_21627369
  result.add "header", section
  ## parameters in `formData` object:
  ##   InfoType: JString (required)
  ##           : The type of information to retrieve.
  ##   EnvironmentId: JString
  ##                : <p>The ID of the data's environment.</p> <p>If no such environment is found, returns an <code>InvalidParameterValue</code> error.</p> <p>Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error.</p>
  ##   EnvironmentName: JString
  ##                  : <p>The name of the data's environment.</p> <p> If no such environment is found, returns an <code>InvalidParameterValue</code> error. </p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_21627370 = formData.getOrDefault("InfoType")
  valid_21627370 = validateParameter(valid_21627370, JString, required = true,
                                   default = newJString("tail"))
  if valid_21627370 != nil:
    section.add "InfoType", valid_21627370
  var valid_21627371 = formData.getOrDefault("EnvironmentId")
  valid_21627371 = validateParameter(valid_21627371, JString, required = false,
                                   default = nil)
  if valid_21627371 != nil:
    section.add "EnvironmentId", valid_21627371
  var valid_21627372 = formData.getOrDefault("EnvironmentName")
  valid_21627372 = validateParameter(valid_21627372, JString, required = false,
                                   default = nil)
  if valid_21627372 != nil:
    section.add "EnvironmentName", valid_21627372
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627373: Call_PostRetrieveEnvironmentInfo_21627358;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves the compiled information from a <a>RequestEnvironmentInfo</a> request.</p> <p>Related Topics</p> <ul> <li> <p> <a>RequestEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_21627373.validator(path, query, header, formData, body, _)
  let scheme = call_21627373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627373.makeUrl(scheme.get, call_21627373.host, call_21627373.base,
                               call_21627373.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627373, uri, valid, _)

proc call*(call_21627374: Call_PostRetrieveEnvironmentInfo_21627358;
          InfoType: string = "tail"; EnvironmentId: string = "";
          EnvironmentName: string = ""; Action: string = "RetrieveEnvironmentInfo";
          Version: string = "2010-12-01"): Recallable =
  ## postRetrieveEnvironmentInfo
  ## <p>Retrieves the compiled information from a <a>RequestEnvironmentInfo</a> request.</p> <p>Related Topics</p> <ul> <li> <p> <a>RequestEnvironmentInfo</a> </p> </li> </ul>
  ##   InfoType: string (required)
  ##           : The type of information to retrieve.
  ##   EnvironmentId: string
  ##                : <p>The ID of the data's environment.</p> <p>If no such environment is found, returns an <code>InvalidParameterValue</code> error.</p> <p>Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error.</p>
  ##   EnvironmentName: string
  ##                  : <p>The name of the data's environment.</p> <p> If no such environment is found, returns an <code>InvalidParameterValue</code> error. </p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21627375 = newJObject()
  var formData_21627376 = newJObject()
  add(formData_21627376, "InfoType", newJString(InfoType))
  add(formData_21627376, "EnvironmentId", newJString(EnvironmentId))
  add(formData_21627376, "EnvironmentName", newJString(EnvironmentName))
  add(query_21627375, "Action", newJString(Action))
  add(query_21627375, "Version", newJString(Version))
  result = call_21627374.call(nil, query_21627375, nil, formData_21627376, nil)

var postRetrieveEnvironmentInfo* = Call_PostRetrieveEnvironmentInfo_21627358(
    name: "postRetrieveEnvironmentInfo", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RetrieveEnvironmentInfo",
    validator: validate_PostRetrieveEnvironmentInfo_21627359, base: "/",
    makeUrl: url_PostRetrieveEnvironmentInfo_21627360,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRetrieveEnvironmentInfo_21627340 = ref object of OpenApiRestCall_21625437
proc url_GetRetrieveEnvironmentInfo_21627342(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRetrieveEnvironmentInfo_21627341(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  ##   EnvironmentId: JString
  ##                : <p>The ID of the data's environment.</p> <p>If no such environment is found, returns an <code>InvalidParameterValue</code> error.</p> <p>Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error.</p>
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627343 = query.getOrDefault("InfoType")
  valid_21627343 = validateParameter(valid_21627343, JString, required = true,
                                   default = newJString("tail"))
  if valid_21627343 != nil:
    section.add "InfoType", valid_21627343
  var valid_21627344 = query.getOrDefault("EnvironmentName")
  valid_21627344 = validateParameter(valid_21627344, JString, required = false,
                                   default = nil)
  if valid_21627344 != nil:
    section.add "EnvironmentName", valid_21627344
  var valid_21627345 = query.getOrDefault("Action")
  valid_21627345 = validateParameter(valid_21627345, JString, required = true, default = newJString(
      "RetrieveEnvironmentInfo"))
  if valid_21627345 != nil:
    section.add "Action", valid_21627345
  var valid_21627346 = query.getOrDefault("EnvironmentId")
  valid_21627346 = validateParameter(valid_21627346, JString, required = false,
                                   default = nil)
  if valid_21627346 != nil:
    section.add "EnvironmentId", valid_21627346
  var valid_21627347 = query.getOrDefault("Version")
  valid_21627347 = validateParameter(valid_21627347, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21627347 != nil:
    section.add "Version", valid_21627347
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627348 = header.getOrDefault("X-Amz-Date")
  valid_21627348 = validateParameter(valid_21627348, JString, required = false,
                                   default = nil)
  if valid_21627348 != nil:
    section.add "X-Amz-Date", valid_21627348
  var valid_21627349 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627349 = validateParameter(valid_21627349, JString, required = false,
                                   default = nil)
  if valid_21627349 != nil:
    section.add "X-Amz-Security-Token", valid_21627349
  var valid_21627350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627350 = validateParameter(valid_21627350, JString, required = false,
                                   default = nil)
  if valid_21627350 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627350
  var valid_21627351 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627351 = validateParameter(valid_21627351, JString, required = false,
                                   default = nil)
  if valid_21627351 != nil:
    section.add "X-Amz-Algorithm", valid_21627351
  var valid_21627352 = header.getOrDefault("X-Amz-Signature")
  valid_21627352 = validateParameter(valid_21627352, JString, required = false,
                                   default = nil)
  if valid_21627352 != nil:
    section.add "X-Amz-Signature", valid_21627352
  var valid_21627353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627353 = validateParameter(valid_21627353, JString, required = false,
                                   default = nil)
  if valid_21627353 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627353
  var valid_21627354 = header.getOrDefault("X-Amz-Credential")
  valid_21627354 = validateParameter(valid_21627354, JString, required = false,
                                   default = nil)
  if valid_21627354 != nil:
    section.add "X-Amz-Credential", valid_21627354
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627355: Call_GetRetrieveEnvironmentInfo_21627340;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves the compiled information from a <a>RequestEnvironmentInfo</a> request.</p> <p>Related Topics</p> <ul> <li> <p> <a>RequestEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_21627355.validator(path, query, header, formData, body, _)
  let scheme = call_21627355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627355.makeUrl(scheme.get, call_21627355.host, call_21627355.base,
                               call_21627355.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627355, uri, valid, _)

proc call*(call_21627356: Call_GetRetrieveEnvironmentInfo_21627340;
          InfoType: string = "tail"; EnvironmentName: string = "";
          Action: string = "RetrieveEnvironmentInfo"; EnvironmentId: string = "";
          Version: string = "2010-12-01"): Recallable =
  ## getRetrieveEnvironmentInfo
  ## <p>Retrieves the compiled information from a <a>RequestEnvironmentInfo</a> request.</p> <p>Related Topics</p> <ul> <li> <p> <a>RequestEnvironmentInfo</a> </p> </li> </ul>
  ##   InfoType: string (required)
  ##           : The type of information to retrieve.
  ##   EnvironmentName: string
  ##                  : <p>The name of the data's environment.</p> <p> If no such environment is found, returns an <code>InvalidParameterValue</code> error. </p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Action: string (required)
  ##   EnvironmentId: string
  ##                : <p>The ID of the data's environment.</p> <p>If no such environment is found, returns an <code>InvalidParameterValue</code> error.</p> <p>Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error.</p>
  ##   Version: string (required)
  var query_21627357 = newJObject()
  add(query_21627357, "InfoType", newJString(InfoType))
  add(query_21627357, "EnvironmentName", newJString(EnvironmentName))
  add(query_21627357, "Action", newJString(Action))
  add(query_21627357, "EnvironmentId", newJString(EnvironmentId))
  add(query_21627357, "Version", newJString(Version))
  result = call_21627356.call(nil, query_21627357, nil, nil, nil)

var getRetrieveEnvironmentInfo* = Call_GetRetrieveEnvironmentInfo_21627340(
    name: "getRetrieveEnvironmentInfo", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RetrieveEnvironmentInfo",
    validator: validate_GetRetrieveEnvironmentInfo_21627341, base: "/",
    makeUrl: url_GetRetrieveEnvironmentInfo_21627342,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSwapEnvironmentCNAMEs_21627396 = ref object of OpenApiRestCall_21625437
proc url_PostSwapEnvironmentCNAMEs_21627398(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSwapEnvironmentCNAMEs_21627397(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627399 = query.getOrDefault("Action")
  valid_21627399 = validateParameter(valid_21627399, JString, required = true, default = newJString(
      "SwapEnvironmentCNAMEs"))
  if valid_21627399 != nil:
    section.add "Action", valid_21627399
  var valid_21627400 = query.getOrDefault("Version")
  valid_21627400 = validateParameter(valid_21627400, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21627400 != nil:
    section.add "Version", valid_21627400
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627401 = header.getOrDefault("X-Amz-Date")
  valid_21627401 = validateParameter(valid_21627401, JString, required = false,
                                   default = nil)
  if valid_21627401 != nil:
    section.add "X-Amz-Date", valid_21627401
  var valid_21627402 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627402 = validateParameter(valid_21627402, JString, required = false,
                                   default = nil)
  if valid_21627402 != nil:
    section.add "X-Amz-Security-Token", valid_21627402
  var valid_21627403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627403 = validateParameter(valid_21627403, JString, required = false,
                                   default = nil)
  if valid_21627403 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627403
  var valid_21627404 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627404 = validateParameter(valid_21627404, JString, required = false,
                                   default = nil)
  if valid_21627404 != nil:
    section.add "X-Amz-Algorithm", valid_21627404
  var valid_21627405 = header.getOrDefault("X-Amz-Signature")
  valid_21627405 = validateParameter(valid_21627405, JString, required = false,
                                   default = nil)
  if valid_21627405 != nil:
    section.add "X-Amz-Signature", valid_21627405
  var valid_21627406 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627406 = validateParameter(valid_21627406, JString, required = false,
                                   default = nil)
  if valid_21627406 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627406
  var valid_21627407 = header.getOrDefault("X-Amz-Credential")
  valid_21627407 = validateParameter(valid_21627407, JString, required = false,
                                   default = nil)
  if valid_21627407 != nil:
    section.add "X-Amz-Credential", valid_21627407
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceEnvironmentName: JString
  ##                        : <p>The name of the source environment.</p> <p> Condition: You must specify at least the <code>SourceEnvironmentID</code> or the <code>SourceEnvironmentName</code>. You may also specify both. If you specify the <code>SourceEnvironmentName</code>, you must specify the <code>DestinationEnvironmentName</code>. </p>
  ##   SourceEnvironmentId: JString
  ##                      : <p>The ID of the source environment.</p> <p> Condition: You must specify at least the <code>SourceEnvironmentID</code> or the <code>SourceEnvironmentName</code>. You may also specify both. If you specify the <code>SourceEnvironmentId</code>, you must specify the <code>DestinationEnvironmentId</code>. </p>
  ##   DestinationEnvironmentId: JString
  ##                           : <p>The ID of the destination environment.</p> <p> Condition: You must specify at least the <code>DestinationEnvironmentID</code> or the <code>DestinationEnvironmentName</code>. You may also specify both. You must specify the <code>SourceEnvironmentId</code> with the <code>DestinationEnvironmentId</code>. </p>
  ##   DestinationEnvironmentName: JString
  ##                             : <p>The name of the destination environment.</p> <p> Condition: You must specify at least the <code>DestinationEnvironmentID</code> or the <code>DestinationEnvironmentName</code>. You may also specify both. You must specify the <code>SourceEnvironmentName</code> with the <code>DestinationEnvironmentName</code>. </p>
  section = newJObject()
  var valid_21627408 = formData.getOrDefault("SourceEnvironmentName")
  valid_21627408 = validateParameter(valid_21627408, JString, required = false,
                                   default = nil)
  if valid_21627408 != nil:
    section.add "SourceEnvironmentName", valid_21627408
  var valid_21627409 = formData.getOrDefault("SourceEnvironmentId")
  valid_21627409 = validateParameter(valid_21627409, JString, required = false,
                                   default = nil)
  if valid_21627409 != nil:
    section.add "SourceEnvironmentId", valid_21627409
  var valid_21627410 = formData.getOrDefault("DestinationEnvironmentId")
  valid_21627410 = validateParameter(valid_21627410, JString, required = false,
                                   default = nil)
  if valid_21627410 != nil:
    section.add "DestinationEnvironmentId", valid_21627410
  var valid_21627411 = formData.getOrDefault("DestinationEnvironmentName")
  valid_21627411 = validateParameter(valid_21627411, JString, required = false,
                                   default = nil)
  if valid_21627411 != nil:
    section.add "DestinationEnvironmentName", valid_21627411
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627412: Call_PostSwapEnvironmentCNAMEs_21627396;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Swaps the CNAMEs of two environments.
  ## 
  let valid = call_21627412.validator(path, query, header, formData, body, _)
  let scheme = call_21627412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627412.makeUrl(scheme.get, call_21627412.host, call_21627412.base,
                               call_21627412.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627412, uri, valid, _)

proc call*(call_21627413: Call_PostSwapEnvironmentCNAMEs_21627396;
          SourceEnvironmentName: string = ""; SourceEnvironmentId: string = "";
          DestinationEnvironmentId: string = "";
          DestinationEnvironmentName: string = "";
          Action: string = "SwapEnvironmentCNAMEs"; Version: string = "2010-12-01"): Recallable =
  ## postSwapEnvironmentCNAMEs
  ## Swaps the CNAMEs of two environments.
  ##   SourceEnvironmentName: string
  ##                        : <p>The name of the source environment.</p> <p> Condition: You must specify at least the <code>SourceEnvironmentID</code> or the <code>SourceEnvironmentName</code>. You may also specify both. If you specify the <code>SourceEnvironmentName</code>, you must specify the <code>DestinationEnvironmentName</code>. </p>
  ##   SourceEnvironmentId: string
  ##                      : <p>The ID of the source environment.</p> <p> Condition: You must specify at least the <code>SourceEnvironmentID</code> or the <code>SourceEnvironmentName</code>. You may also specify both. If you specify the <code>SourceEnvironmentId</code>, you must specify the <code>DestinationEnvironmentId</code>. </p>
  ##   DestinationEnvironmentId: string
  ##                           : <p>The ID of the destination environment.</p> <p> Condition: You must specify at least the <code>DestinationEnvironmentID</code> or the <code>DestinationEnvironmentName</code>. You may also specify both. You must specify the <code>SourceEnvironmentId</code> with the <code>DestinationEnvironmentId</code>. </p>
  ##   DestinationEnvironmentName: string
  ##                             : <p>The name of the destination environment.</p> <p> Condition: You must specify at least the <code>DestinationEnvironmentID</code> or the <code>DestinationEnvironmentName</code>. You may also specify both. You must specify the <code>SourceEnvironmentName</code> with the <code>DestinationEnvironmentName</code>. </p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21627414 = newJObject()
  var formData_21627415 = newJObject()
  add(formData_21627415, "SourceEnvironmentName",
      newJString(SourceEnvironmentName))
  add(formData_21627415, "SourceEnvironmentId", newJString(SourceEnvironmentId))
  add(formData_21627415, "DestinationEnvironmentId",
      newJString(DestinationEnvironmentId))
  add(formData_21627415, "DestinationEnvironmentName",
      newJString(DestinationEnvironmentName))
  add(query_21627414, "Action", newJString(Action))
  add(query_21627414, "Version", newJString(Version))
  result = call_21627413.call(nil, query_21627414, nil, formData_21627415, nil)

var postSwapEnvironmentCNAMEs* = Call_PostSwapEnvironmentCNAMEs_21627396(
    name: "postSwapEnvironmentCNAMEs", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=SwapEnvironmentCNAMEs",
    validator: validate_PostSwapEnvironmentCNAMEs_21627397, base: "/",
    makeUrl: url_PostSwapEnvironmentCNAMEs_21627398,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSwapEnvironmentCNAMEs_21627377 = ref object of OpenApiRestCall_21625437
proc url_GetSwapEnvironmentCNAMEs_21627379(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSwapEnvironmentCNAMEs_21627378(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Swaps the CNAMEs of two environments.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceEnvironmentId: JString
  ##                      : <p>The ID of the source environment.</p> <p> Condition: You must specify at least the <code>SourceEnvironmentID</code> or the <code>SourceEnvironmentName</code>. You may also specify both. If you specify the <code>SourceEnvironmentId</code>, you must specify the <code>DestinationEnvironmentId</code>. </p>
  ##   DestinationEnvironmentName: JString
  ##                             : <p>The name of the destination environment.</p> <p> Condition: You must specify at least the <code>DestinationEnvironmentID</code> or the <code>DestinationEnvironmentName</code>. You may also specify both. You must specify the <code>SourceEnvironmentName</code> with the <code>DestinationEnvironmentName</code>. </p>
  ##   Action: JString (required)
  ##   SourceEnvironmentName: JString
  ##                        : <p>The name of the source environment.</p> <p> Condition: You must specify at least the <code>SourceEnvironmentID</code> or the <code>SourceEnvironmentName</code>. You may also specify both. If you specify the <code>SourceEnvironmentName</code>, you must specify the <code>DestinationEnvironmentName</code>. </p>
  ##   DestinationEnvironmentId: JString
  ##                           : <p>The ID of the destination environment.</p> <p> Condition: You must specify at least the <code>DestinationEnvironmentID</code> or the <code>DestinationEnvironmentName</code>. You may also specify both. You must specify the <code>SourceEnvironmentId</code> with the <code>DestinationEnvironmentId</code>. </p>
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627380 = query.getOrDefault("SourceEnvironmentId")
  valid_21627380 = validateParameter(valid_21627380, JString, required = false,
                                   default = nil)
  if valid_21627380 != nil:
    section.add "SourceEnvironmentId", valid_21627380
  var valid_21627381 = query.getOrDefault("DestinationEnvironmentName")
  valid_21627381 = validateParameter(valid_21627381, JString, required = false,
                                   default = nil)
  if valid_21627381 != nil:
    section.add "DestinationEnvironmentName", valid_21627381
  var valid_21627382 = query.getOrDefault("Action")
  valid_21627382 = validateParameter(valid_21627382, JString, required = true, default = newJString(
      "SwapEnvironmentCNAMEs"))
  if valid_21627382 != nil:
    section.add "Action", valid_21627382
  var valid_21627383 = query.getOrDefault("SourceEnvironmentName")
  valid_21627383 = validateParameter(valid_21627383, JString, required = false,
                                   default = nil)
  if valid_21627383 != nil:
    section.add "SourceEnvironmentName", valid_21627383
  var valid_21627384 = query.getOrDefault("DestinationEnvironmentId")
  valid_21627384 = validateParameter(valid_21627384, JString, required = false,
                                   default = nil)
  if valid_21627384 != nil:
    section.add "DestinationEnvironmentId", valid_21627384
  var valid_21627385 = query.getOrDefault("Version")
  valid_21627385 = validateParameter(valid_21627385, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21627385 != nil:
    section.add "Version", valid_21627385
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627386 = header.getOrDefault("X-Amz-Date")
  valid_21627386 = validateParameter(valid_21627386, JString, required = false,
                                   default = nil)
  if valid_21627386 != nil:
    section.add "X-Amz-Date", valid_21627386
  var valid_21627387 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627387 = validateParameter(valid_21627387, JString, required = false,
                                   default = nil)
  if valid_21627387 != nil:
    section.add "X-Amz-Security-Token", valid_21627387
  var valid_21627388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627388 = validateParameter(valid_21627388, JString, required = false,
                                   default = nil)
  if valid_21627388 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627388
  var valid_21627389 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627389 = validateParameter(valid_21627389, JString, required = false,
                                   default = nil)
  if valid_21627389 != nil:
    section.add "X-Amz-Algorithm", valid_21627389
  var valid_21627390 = header.getOrDefault("X-Amz-Signature")
  valid_21627390 = validateParameter(valid_21627390, JString, required = false,
                                   default = nil)
  if valid_21627390 != nil:
    section.add "X-Amz-Signature", valid_21627390
  var valid_21627391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627391 = validateParameter(valid_21627391, JString, required = false,
                                   default = nil)
  if valid_21627391 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627391
  var valid_21627392 = header.getOrDefault("X-Amz-Credential")
  valid_21627392 = validateParameter(valid_21627392, JString, required = false,
                                   default = nil)
  if valid_21627392 != nil:
    section.add "X-Amz-Credential", valid_21627392
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627393: Call_GetSwapEnvironmentCNAMEs_21627377;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Swaps the CNAMEs of two environments.
  ## 
  let valid = call_21627393.validator(path, query, header, formData, body, _)
  let scheme = call_21627393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627393.makeUrl(scheme.get, call_21627393.host, call_21627393.base,
                               call_21627393.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627393, uri, valid, _)

proc call*(call_21627394: Call_GetSwapEnvironmentCNAMEs_21627377;
          SourceEnvironmentId: string = ""; DestinationEnvironmentName: string = "";
          Action: string = "SwapEnvironmentCNAMEs";
          SourceEnvironmentName: string = ""; DestinationEnvironmentId: string = "";
          Version: string = "2010-12-01"): Recallable =
  ## getSwapEnvironmentCNAMEs
  ## Swaps the CNAMEs of two environments.
  ##   SourceEnvironmentId: string
  ##                      : <p>The ID of the source environment.</p> <p> Condition: You must specify at least the <code>SourceEnvironmentID</code> or the <code>SourceEnvironmentName</code>. You may also specify both. If you specify the <code>SourceEnvironmentId</code>, you must specify the <code>DestinationEnvironmentId</code>. </p>
  ##   DestinationEnvironmentName: string
  ##                             : <p>The name of the destination environment.</p> <p> Condition: You must specify at least the <code>DestinationEnvironmentID</code> or the <code>DestinationEnvironmentName</code>. You may also specify both. You must specify the <code>SourceEnvironmentName</code> with the <code>DestinationEnvironmentName</code>. </p>
  ##   Action: string (required)
  ##   SourceEnvironmentName: string
  ##                        : <p>The name of the source environment.</p> <p> Condition: You must specify at least the <code>SourceEnvironmentID</code> or the <code>SourceEnvironmentName</code>. You may also specify both. If you specify the <code>SourceEnvironmentName</code>, you must specify the <code>DestinationEnvironmentName</code>. </p>
  ##   DestinationEnvironmentId: string
  ##                           : <p>The ID of the destination environment.</p> <p> Condition: You must specify at least the <code>DestinationEnvironmentID</code> or the <code>DestinationEnvironmentName</code>. You may also specify both. You must specify the <code>SourceEnvironmentId</code> with the <code>DestinationEnvironmentId</code>. </p>
  ##   Version: string (required)
  var query_21627395 = newJObject()
  add(query_21627395, "SourceEnvironmentId", newJString(SourceEnvironmentId))
  add(query_21627395, "DestinationEnvironmentName",
      newJString(DestinationEnvironmentName))
  add(query_21627395, "Action", newJString(Action))
  add(query_21627395, "SourceEnvironmentName", newJString(SourceEnvironmentName))
  add(query_21627395, "DestinationEnvironmentId",
      newJString(DestinationEnvironmentId))
  add(query_21627395, "Version", newJString(Version))
  result = call_21627394.call(nil, query_21627395, nil, nil, nil)

var getSwapEnvironmentCNAMEs* = Call_GetSwapEnvironmentCNAMEs_21627377(
    name: "getSwapEnvironmentCNAMEs", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=SwapEnvironmentCNAMEs",
    validator: validate_GetSwapEnvironmentCNAMEs_21627378, base: "/",
    makeUrl: url_GetSwapEnvironmentCNAMEs_21627379,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostTerminateEnvironment_21627435 = ref object of OpenApiRestCall_21625437
proc url_PostTerminateEnvironment_21627437(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostTerminateEnvironment_21627436(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627438 = query.getOrDefault("Action")
  valid_21627438 = validateParameter(valid_21627438, JString, required = true,
                                   default = newJString("TerminateEnvironment"))
  if valid_21627438 != nil:
    section.add "Action", valid_21627438
  var valid_21627439 = query.getOrDefault("Version")
  valid_21627439 = validateParameter(valid_21627439, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21627439 != nil:
    section.add "Version", valid_21627439
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627440 = header.getOrDefault("X-Amz-Date")
  valid_21627440 = validateParameter(valid_21627440, JString, required = false,
                                   default = nil)
  if valid_21627440 != nil:
    section.add "X-Amz-Date", valid_21627440
  var valid_21627441 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627441 = validateParameter(valid_21627441, JString, required = false,
                                   default = nil)
  if valid_21627441 != nil:
    section.add "X-Amz-Security-Token", valid_21627441
  var valid_21627442 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627442 = validateParameter(valid_21627442, JString, required = false,
                                   default = nil)
  if valid_21627442 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627442
  var valid_21627443 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627443 = validateParameter(valid_21627443, JString, required = false,
                                   default = nil)
  if valid_21627443 != nil:
    section.add "X-Amz-Algorithm", valid_21627443
  var valid_21627444 = header.getOrDefault("X-Amz-Signature")
  valid_21627444 = validateParameter(valid_21627444, JString, required = false,
                                   default = nil)
  if valid_21627444 != nil:
    section.add "X-Amz-Signature", valid_21627444
  var valid_21627445 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627445 = validateParameter(valid_21627445, JString, required = false,
                                   default = nil)
  if valid_21627445 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627445
  var valid_21627446 = header.getOrDefault("X-Amz-Credential")
  valid_21627446 = validateParameter(valid_21627446, JString, required = false,
                                   default = nil)
  if valid_21627446 != nil:
    section.add "X-Amz-Credential", valid_21627446
  result.add "header", section
  ## parameters in `formData` object:
  ##   ForceTerminate: JBool
  ##                 : Terminates the target environment even if another environment in the same group is dependent on it.
  ##   TerminateResources: JBool
  ##                     : <p>Indicates whether the associated AWS resources should shut down when the environment is terminated:</p> <ul> <li> <p> <code>true</code>: The specified environment as well as the associated AWS resources, such as Auto Scaling group and LoadBalancer, are terminated.</p> </li> <li> <p> <code>false</code>: AWS Elastic Beanstalk resource management is removed from the environment, but the AWS resources continue to operate.</p> </li> </ul> <p> For more information, see the <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/ug/"> AWS Elastic Beanstalk User Guide. </a> </p> <p> Default: <code>true</code> </p> <p> Valid Values: <code>true</code> | <code>false</code> </p>
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to terminate.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to terminate.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_21627447 = formData.getOrDefault("ForceTerminate")
  valid_21627447 = validateParameter(valid_21627447, JBool, required = false,
                                   default = nil)
  if valid_21627447 != nil:
    section.add "ForceTerminate", valid_21627447
  var valid_21627448 = formData.getOrDefault("TerminateResources")
  valid_21627448 = validateParameter(valid_21627448, JBool, required = false,
                                   default = nil)
  if valid_21627448 != nil:
    section.add "TerminateResources", valid_21627448
  var valid_21627449 = formData.getOrDefault("EnvironmentId")
  valid_21627449 = validateParameter(valid_21627449, JString, required = false,
                                   default = nil)
  if valid_21627449 != nil:
    section.add "EnvironmentId", valid_21627449
  var valid_21627450 = formData.getOrDefault("EnvironmentName")
  valid_21627450 = validateParameter(valid_21627450, JString, required = false,
                                   default = nil)
  if valid_21627450 != nil:
    section.add "EnvironmentName", valid_21627450
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627451: Call_PostTerminateEnvironment_21627435;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Terminates the specified environment.
  ## 
  let valid = call_21627451.validator(path, query, header, formData, body, _)
  let scheme = call_21627451.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627451.makeUrl(scheme.get, call_21627451.host, call_21627451.base,
                               call_21627451.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627451, uri, valid, _)

proc call*(call_21627452: Call_PostTerminateEnvironment_21627435;
          ForceTerminate: bool = false; TerminateResources: bool = false;
          EnvironmentId: string = ""; EnvironmentName: string = "";
          Action: string = "TerminateEnvironment"; Version: string = "2010-12-01"): Recallable =
  ## postTerminateEnvironment
  ## Terminates the specified environment.
  ##   ForceTerminate: bool
  ##                 : Terminates the target environment even if another environment in the same group is dependent on it.
  ##   TerminateResources: bool
  ##                     : <p>Indicates whether the associated AWS resources should shut down when the environment is terminated:</p> <ul> <li> <p> <code>true</code>: The specified environment as well as the associated AWS resources, such as Auto Scaling group and LoadBalancer, are terminated.</p> </li> <li> <p> <code>false</code>: AWS Elastic Beanstalk resource management is removed from the environment, but the AWS resources continue to operate.</p> </li> </ul> <p> For more information, see the <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/ug/"> AWS Elastic Beanstalk User Guide. </a> </p> <p> Default: <code>true</code> </p> <p> Valid Values: <code>true</code> | <code>false</code> </p>
  ##   EnvironmentId: string
  ##                : <p>The ID of the environment to terminate.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentName: string
  ##                  : <p>The name of the environment to terminate.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21627453 = newJObject()
  var formData_21627454 = newJObject()
  add(formData_21627454, "ForceTerminate", newJBool(ForceTerminate))
  add(formData_21627454, "TerminateResources", newJBool(TerminateResources))
  add(formData_21627454, "EnvironmentId", newJString(EnvironmentId))
  add(formData_21627454, "EnvironmentName", newJString(EnvironmentName))
  add(query_21627453, "Action", newJString(Action))
  add(query_21627453, "Version", newJString(Version))
  result = call_21627452.call(nil, query_21627453, nil, formData_21627454, nil)

var postTerminateEnvironment* = Call_PostTerminateEnvironment_21627435(
    name: "postTerminateEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=TerminateEnvironment",
    validator: validate_PostTerminateEnvironment_21627436, base: "/",
    makeUrl: url_PostTerminateEnvironment_21627437,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTerminateEnvironment_21627416 = ref object of OpenApiRestCall_21625437
proc url_GetTerminateEnvironment_21627418(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTerminateEnvironment_21627417(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Terminates the specified environment.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to terminate.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Action: JString (required)
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to terminate.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   ForceTerminate: JBool
  ##                 : Terminates the target environment even if another environment in the same group is dependent on it.
  ##   TerminateResources: JBool
  ##                     : <p>Indicates whether the associated AWS resources should shut down when the environment is terminated:</p> <ul> <li> <p> <code>true</code>: The specified environment as well as the associated AWS resources, such as Auto Scaling group and LoadBalancer, are terminated.</p> </li> <li> <p> <code>false</code>: AWS Elastic Beanstalk resource management is removed from the environment, but the AWS resources continue to operate.</p> </li> </ul> <p> For more information, see the <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/ug/"> AWS Elastic Beanstalk User Guide. </a> </p> <p> Default: <code>true</code> </p> <p> Valid Values: <code>true</code> | <code>false</code> </p>
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627419 = query.getOrDefault("EnvironmentName")
  valid_21627419 = validateParameter(valid_21627419, JString, required = false,
                                   default = nil)
  if valid_21627419 != nil:
    section.add "EnvironmentName", valid_21627419
  var valid_21627420 = query.getOrDefault("Action")
  valid_21627420 = validateParameter(valid_21627420, JString, required = true,
                                   default = newJString("TerminateEnvironment"))
  if valid_21627420 != nil:
    section.add "Action", valid_21627420
  var valid_21627421 = query.getOrDefault("EnvironmentId")
  valid_21627421 = validateParameter(valid_21627421, JString, required = false,
                                   default = nil)
  if valid_21627421 != nil:
    section.add "EnvironmentId", valid_21627421
  var valid_21627422 = query.getOrDefault("ForceTerminate")
  valid_21627422 = validateParameter(valid_21627422, JBool, required = false,
                                   default = nil)
  if valid_21627422 != nil:
    section.add "ForceTerminate", valid_21627422
  var valid_21627423 = query.getOrDefault("TerminateResources")
  valid_21627423 = validateParameter(valid_21627423, JBool, required = false,
                                   default = nil)
  if valid_21627423 != nil:
    section.add "TerminateResources", valid_21627423
  var valid_21627424 = query.getOrDefault("Version")
  valid_21627424 = validateParameter(valid_21627424, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21627424 != nil:
    section.add "Version", valid_21627424
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627425 = header.getOrDefault("X-Amz-Date")
  valid_21627425 = validateParameter(valid_21627425, JString, required = false,
                                   default = nil)
  if valid_21627425 != nil:
    section.add "X-Amz-Date", valid_21627425
  var valid_21627426 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627426 = validateParameter(valid_21627426, JString, required = false,
                                   default = nil)
  if valid_21627426 != nil:
    section.add "X-Amz-Security-Token", valid_21627426
  var valid_21627427 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627427 = validateParameter(valid_21627427, JString, required = false,
                                   default = nil)
  if valid_21627427 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627427
  var valid_21627428 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627428 = validateParameter(valid_21627428, JString, required = false,
                                   default = nil)
  if valid_21627428 != nil:
    section.add "X-Amz-Algorithm", valid_21627428
  var valid_21627429 = header.getOrDefault("X-Amz-Signature")
  valid_21627429 = validateParameter(valid_21627429, JString, required = false,
                                   default = nil)
  if valid_21627429 != nil:
    section.add "X-Amz-Signature", valid_21627429
  var valid_21627430 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627430 = validateParameter(valid_21627430, JString, required = false,
                                   default = nil)
  if valid_21627430 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627430
  var valid_21627431 = header.getOrDefault("X-Amz-Credential")
  valid_21627431 = validateParameter(valid_21627431, JString, required = false,
                                   default = nil)
  if valid_21627431 != nil:
    section.add "X-Amz-Credential", valid_21627431
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627432: Call_GetTerminateEnvironment_21627416;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Terminates the specified environment.
  ## 
  let valid = call_21627432.validator(path, query, header, formData, body, _)
  let scheme = call_21627432.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627432.makeUrl(scheme.get, call_21627432.host, call_21627432.base,
                               call_21627432.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627432, uri, valid, _)

proc call*(call_21627433: Call_GetTerminateEnvironment_21627416;
          EnvironmentName: string = ""; Action: string = "TerminateEnvironment";
          EnvironmentId: string = ""; ForceTerminate: bool = false;
          TerminateResources: bool = false; Version: string = "2010-12-01"): Recallable =
  ## getTerminateEnvironment
  ## Terminates the specified environment.
  ##   EnvironmentName: string
  ##                  : <p>The name of the environment to terminate.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Action: string (required)
  ##   EnvironmentId: string
  ##                : <p>The ID of the environment to terminate.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   ForceTerminate: bool
  ##                 : Terminates the target environment even if another environment in the same group is dependent on it.
  ##   TerminateResources: bool
  ##                     : <p>Indicates whether the associated AWS resources should shut down when the environment is terminated:</p> <ul> <li> <p> <code>true</code>: The specified environment as well as the associated AWS resources, such as Auto Scaling group and LoadBalancer, are terminated.</p> </li> <li> <p> <code>false</code>: AWS Elastic Beanstalk resource management is removed from the environment, but the AWS resources continue to operate.</p> </li> </ul> <p> For more information, see the <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/ug/"> AWS Elastic Beanstalk User Guide. </a> </p> <p> Default: <code>true</code> </p> <p> Valid Values: <code>true</code> | <code>false</code> </p>
  ##   Version: string (required)
  var query_21627434 = newJObject()
  add(query_21627434, "EnvironmentName", newJString(EnvironmentName))
  add(query_21627434, "Action", newJString(Action))
  add(query_21627434, "EnvironmentId", newJString(EnvironmentId))
  add(query_21627434, "ForceTerminate", newJBool(ForceTerminate))
  add(query_21627434, "TerminateResources", newJBool(TerminateResources))
  add(query_21627434, "Version", newJString(Version))
  result = call_21627433.call(nil, query_21627434, nil, nil, nil)

var getTerminateEnvironment* = Call_GetTerminateEnvironment_21627416(
    name: "getTerminateEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=TerminateEnvironment",
    validator: validate_GetTerminateEnvironment_21627417, base: "/",
    makeUrl: url_GetTerminateEnvironment_21627418,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateApplication_21627472 = ref object of OpenApiRestCall_21625437
proc url_PostUpdateApplication_21627474(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateApplication_21627473(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627475 = query.getOrDefault("Action")
  valid_21627475 = validateParameter(valid_21627475, JString, required = true,
                                   default = newJString("UpdateApplication"))
  if valid_21627475 != nil:
    section.add "Action", valid_21627475
  var valid_21627476 = query.getOrDefault("Version")
  valid_21627476 = validateParameter(valid_21627476, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21627476 != nil:
    section.add "Version", valid_21627476
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627477 = header.getOrDefault("X-Amz-Date")
  valid_21627477 = validateParameter(valid_21627477, JString, required = false,
                                   default = nil)
  if valid_21627477 != nil:
    section.add "X-Amz-Date", valid_21627477
  var valid_21627478 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627478 = validateParameter(valid_21627478, JString, required = false,
                                   default = nil)
  if valid_21627478 != nil:
    section.add "X-Amz-Security-Token", valid_21627478
  var valid_21627479 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627479 = validateParameter(valid_21627479, JString, required = false,
                                   default = nil)
  if valid_21627479 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627479
  var valid_21627480 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627480 = validateParameter(valid_21627480, JString, required = false,
                                   default = nil)
  if valid_21627480 != nil:
    section.add "X-Amz-Algorithm", valid_21627480
  var valid_21627481 = header.getOrDefault("X-Amz-Signature")
  valid_21627481 = validateParameter(valid_21627481, JString, required = false,
                                   default = nil)
  if valid_21627481 != nil:
    section.add "X-Amz-Signature", valid_21627481
  var valid_21627482 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627482 = validateParameter(valid_21627482, JString, required = false,
                                   default = nil)
  if valid_21627482 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627482
  var valid_21627483 = header.getOrDefault("X-Amz-Credential")
  valid_21627483 = validateParameter(valid_21627483, JString, required = false,
                                   default = nil)
  if valid_21627483 != nil:
    section.add "X-Amz-Credential", valid_21627483
  result.add "header", section
  ## parameters in `formData` object:
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to update. If no such application is found, <code>UpdateApplication</code> returns an <code>InvalidParameterValue</code> error. 
  ##   Description: JString
  ##              : <p>A new description for the application.</p> <p>Default: If not specified, AWS Elastic Beanstalk does not update the description.</p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_21627484 = formData.getOrDefault("ApplicationName")
  valid_21627484 = validateParameter(valid_21627484, JString, required = true,
                                   default = nil)
  if valid_21627484 != nil:
    section.add "ApplicationName", valid_21627484
  var valid_21627485 = formData.getOrDefault("Description")
  valid_21627485 = validateParameter(valid_21627485, JString, required = false,
                                   default = nil)
  if valid_21627485 != nil:
    section.add "Description", valid_21627485
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627486: Call_PostUpdateApplication_21627472;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates the specified application to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear these properties, specify an empty string.</p> </note>
  ## 
  let valid = call_21627486.validator(path, query, header, formData, body, _)
  let scheme = call_21627486.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627486.makeUrl(scheme.get, call_21627486.host, call_21627486.base,
                               call_21627486.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627486, uri, valid, _)

proc call*(call_21627487: Call_PostUpdateApplication_21627472;
          ApplicationName: string; Action: string = "UpdateApplication";
          Version: string = "2010-12-01"; Description: string = ""): Recallable =
  ## postUpdateApplication
  ## <p>Updates the specified application to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear these properties, specify an empty string.</p> </note>
  ##   Action: string (required)
  ##   ApplicationName: string (required)
  ##                  : The name of the application to update. If no such application is found, <code>UpdateApplication</code> returns an <code>InvalidParameterValue</code> error. 
  ##   Version: string (required)
  ##   Description: string
  ##              : <p>A new description for the application.</p> <p>Default: If not specified, AWS Elastic Beanstalk does not update the description.</p>
  var query_21627488 = newJObject()
  var formData_21627489 = newJObject()
  add(query_21627488, "Action", newJString(Action))
  add(formData_21627489, "ApplicationName", newJString(ApplicationName))
  add(query_21627488, "Version", newJString(Version))
  add(formData_21627489, "Description", newJString(Description))
  result = call_21627487.call(nil, query_21627488, nil, formData_21627489, nil)

var postUpdateApplication* = Call_PostUpdateApplication_21627472(
    name: "postUpdateApplication", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateApplication",
    validator: validate_PostUpdateApplication_21627473, base: "/",
    makeUrl: url_PostUpdateApplication_21627474,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateApplication_21627455 = ref object of OpenApiRestCall_21625437
proc url_GetUpdateApplication_21627457(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateApplication_21627456(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Updates the specified application to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear these properties, specify an empty string.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to update. If no such application is found, <code>UpdateApplication</code> returns an <code>InvalidParameterValue</code> error. 
  ##   Description: JString
  ##              : <p>A new description for the application.</p> <p>Default: If not specified, AWS Elastic Beanstalk does not update the description.</p>
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_21627458 = query.getOrDefault("ApplicationName")
  valid_21627458 = validateParameter(valid_21627458, JString, required = true,
                                   default = nil)
  if valid_21627458 != nil:
    section.add "ApplicationName", valid_21627458
  var valid_21627459 = query.getOrDefault("Description")
  valid_21627459 = validateParameter(valid_21627459, JString, required = false,
                                   default = nil)
  if valid_21627459 != nil:
    section.add "Description", valid_21627459
  var valid_21627460 = query.getOrDefault("Action")
  valid_21627460 = validateParameter(valid_21627460, JString, required = true,
                                   default = newJString("UpdateApplication"))
  if valid_21627460 != nil:
    section.add "Action", valid_21627460
  var valid_21627461 = query.getOrDefault("Version")
  valid_21627461 = validateParameter(valid_21627461, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21627461 != nil:
    section.add "Version", valid_21627461
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627462 = header.getOrDefault("X-Amz-Date")
  valid_21627462 = validateParameter(valid_21627462, JString, required = false,
                                   default = nil)
  if valid_21627462 != nil:
    section.add "X-Amz-Date", valid_21627462
  var valid_21627463 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627463 = validateParameter(valid_21627463, JString, required = false,
                                   default = nil)
  if valid_21627463 != nil:
    section.add "X-Amz-Security-Token", valid_21627463
  var valid_21627464 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627464 = validateParameter(valid_21627464, JString, required = false,
                                   default = nil)
  if valid_21627464 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627464
  var valid_21627465 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627465 = validateParameter(valid_21627465, JString, required = false,
                                   default = nil)
  if valid_21627465 != nil:
    section.add "X-Amz-Algorithm", valid_21627465
  var valid_21627466 = header.getOrDefault("X-Amz-Signature")
  valid_21627466 = validateParameter(valid_21627466, JString, required = false,
                                   default = nil)
  if valid_21627466 != nil:
    section.add "X-Amz-Signature", valid_21627466
  var valid_21627467 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627467 = validateParameter(valid_21627467, JString, required = false,
                                   default = nil)
  if valid_21627467 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627467
  var valid_21627468 = header.getOrDefault("X-Amz-Credential")
  valid_21627468 = validateParameter(valid_21627468, JString, required = false,
                                   default = nil)
  if valid_21627468 != nil:
    section.add "X-Amz-Credential", valid_21627468
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627469: Call_GetUpdateApplication_21627455; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates the specified application to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear these properties, specify an empty string.</p> </note>
  ## 
  let valid = call_21627469.validator(path, query, header, formData, body, _)
  let scheme = call_21627469.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627469.makeUrl(scheme.get, call_21627469.host, call_21627469.base,
                               call_21627469.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627469, uri, valid, _)

proc call*(call_21627470: Call_GetUpdateApplication_21627455;
          ApplicationName: string; Description: string = "";
          Action: string = "UpdateApplication"; Version: string = "2010-12-01"): Recallable =
  ## getUpdateApplication
  ## <p>Updates the specified application to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear these properties, specify an empty string.</p> </note>
  ##   ApplicationName: string (required)
  ##                  : The name of the application to update. If no such application is found, <code>UpdateApplication</code> returns an <code>InvalidParameterValue</code> error. 
  ##   Description: string
  ##              : <p>A new description for the application.</p> <p>Default: If not specified, AWS Elastic Beanstalk does not update the description.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21627471 = newJObject()
  add(query_21627471, "ApplicationName", newJString(ApplicationName))
  add(query_21627471, "Description", newJString(Description))
  add(query_21627471, "Action", newJString(Action))
  add(query_21627471, "Version", newJString(Version))
  result = call_21627470.call(nil, query_21627471, nil, nil, nil)

var getUpdateApplication* = Call_GetUpdateApplication_21627455(
    name: "getUpdateApplication", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateApplication",
    validator: validate_GetUpdateApplication_21627456, base: "/",
    makeUrl: url_GetUpdateApplication_21627457,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateApplicationResourceLifecycle_21627508 = ref object of OpenApiRestCall_21625437
proc url_PostUpdateApplicationResourceLifecycle_21627510(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateApplicationResourceLifecycle_21627509(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627511 = query.getOrDefault("Action")
  valid_21627511 = validateParameter(valid_21627511, JString, required = true, default = newJString(
      "UpdateApplicationResourceLifecycle"))
  if valid_21627511 != nil:
    section.add "Action", valid_21627511
  var valid_21627512 = query.getOrDefault("Version")
  valid_21627512 = validateParameter(valid_21627512, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21627512 != nil:
    section.add "Version", valid_21627512
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627513 = header.getOrDefault("X-Amz-Date")
  valid_21627513 = validateParameter(valid_21627513, JString, required = false,
                                   default = nil)
  if valid_21627513 != nil:
    section.add "X-Amz-Date", valid_21627513
  var valid_21627514 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627514 = validateParameter(valid_21627514, JString, required = false,
                                   default = nil)
  if valid_21627514 != nil:
    section.add "X-Amz-Security-Token", valid_21627514
  var valid_21627515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627515 = validateParameter(valid_21627515, JString, required = false,
                                   default = nil)
  if valid_21627515 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627515
  var valid_21627516 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627516 = validateParameter(valid_21627516, JString, required = false,
                                   default = nil)
  if valid_21627516 != nil:
    section.add "X-Amz-Algorithm", valid_21627516
  var valid_21627517 = header.getOrDefault("X-Amz-Signature")
  valid_21627517 = validateParameter(valid_21627517, JString, required = false,
                                   default = nil)
  if valid_21627517 != nil:
    section.add "X-Amz-Signature", valid_21627517
  var valid_21627518 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627518 = validateParameter(valid_21627518, JString, required = false,
                                   default = nil)
  if valid_21627518 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627518
  var valid_21627519 = header.getOrDefault("X-Amz-Credential")
  valid_21627519 = validateParameter(valid_21627519, JString, required = false,
                                   default = nil)
  if valid_21627519 != nil:
    section.add "X-Amz-Credential", valid_21627519
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
  var valid_21627520 = formData.getOrDefault(
      "ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_21627520 = validateParameter(valid_21627520, JString, required = false,
                                   default = nil)
  if valid_21627520 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_21627520
  var valid_21627521 = formData.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_21627521 = validateParameter(valid_21627521, JString, required = false,
                                   default = nil)
  if valid_21627521 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_21627521
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_21627522 = formData.getOrDefault("ApplicationName")
  valid_21627522 = validateParameter(valid_21627522, JString, required = true,
                                   default = nil)
  if valid_21627522 != nil:
    section.add "ApplicationName", valid_21627522
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627523: Call_PostUpdateApplicationResourceLifecycle_21627508;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Modifies lifecycle settings for an application.
  ## 
  let valid = call_21627523.validator(path, query, header, formData, body, _)
  let scheme = call_21627523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627523.makeUrl(scheme.get, call_21627523.host, call_21627523.base,
                               call_21627523.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627523, uri, valid, _)

proc call*(call_21627524: Call_PostUpdateApplicationResourceLifecycle_21627508;
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
  ##   Action: string (required)
  ##   ApplicationName: string (required)
  ##                  : The name of the application.
  ##   Version: string (required)
  var query_21627525 = newJObject()
  var formData_21627526 = newJObject()
  add(formData_21627526, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  add(formData_21627526, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  add(query_21627525, "Action", newJString(Action))
  add(formData_21627526, "ApplicationName", newJString(ApplicationName))
  add(query_21627525, "Version", newJString(Version))
  result = call_21627524.call(nil, query_21627525, nil, formData_21627526, nil)

var postUpdateApplicationResourceLifecycle* = Call_PostUpdateApplicationResourceLifecycle_21627508(
    name: "postUpdateApplicationResourceLifecycle", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationResourceLifecycle",
    validator: validate_PostUpdateApplicationResourceLifecycle_21627509,
    base: "/", makeUrl: url_PostUpdateApplicationResourceLifecycle_21627510,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateApplicationResourceLifecycle_21627490 = ref object of OpenApiRestCall_21625437
proc url_GetUpdateApplicationResourceLifecycle_21627492(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateApplicationResourceLifecycle_21627491(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Modifies lifecycle settings for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ResourceLifecycleConfig.VersionLifecycleConfig: JString
  ##                                                 : The resource lifecycle configuration for an application. Defines lifecycle settings for resources that belong to the application, and the service role that Elastic Beanstalk assumes in order to apply lifecycle settings. The version lifecycle configuration defines lifecycle settings for application versions.
  ## The application version lifecycle configuration.
  ##   ApplicationName: JString (required)
  ##                  : The name of the application.
  ##   ResourceLifecycleConfig.ServiceRole: JString
  ##                                      : The resource lifecycle configuration for an application. Defines lifecycle settings for resources that belong to the application, and the service role that Elastic Beanstalk assumes in order to apply lifecycle settings. The version lifecycle configuration defines lifecycle settings for application versions.
  ## <p>The ARN of an IAM service role that Elastic Beanstalk has permission to assume.</p> <p>The <code>ServiceRole</code> property is required the first time that you provide a <code>VersionLifecycleConfig</code> for the application in one of the supporting calls (<code>CreateApplication</code> or <code>UpdateApplicationResourceLifecycle</code>). After you provide it once, in either one of the calls, Elastic Beanstalk persists the Service Role with the application, and you don't need to specify it again in subsequent <code>UpdateApplicationResourceLifecycle</code> calls. You can, however, specify it in subsequent calls to change the Service Role to another value.</p>
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627493 = query.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_21627493 = validateParameter(valid_21627493, JString, required = false,
                                   default = nil)
  if valid_21627493 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_21627493
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_21627494 = query.getOrDefault("ApplicationName")
  valid_21627494 = validateParameter(valid_21627494, JString, required = true,
                                   default = nil)
  if valid_21627494 != nil:
    section.add "ApplicationName", valid_21627494
  var valid_21627495 = query.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_21627495 = validateParameter(valid_21627495, JString, required = false,
                                   default = nil)
  if valid_21627495 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_21627495
  var valid_21627496 = query.getOrDefault("Action")
  valid_21627496 = validateParameter(valid_21627496, JString, required = true, default = newJString(
      "UpdateApplicationResourceLifecycle"))
  if valid_21627496 != nil:
    section.add "Action", valid_21627496
  var valid_21627497 = query.getOrDefault("Version")
  valid_21627497 = validateParameter(valid_21627497, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21627497 != nil:
    section.add "Version", valid_21627497
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627498 = header.getOrDefault("X-Amz-Date")
  valid_21627498 = validateParameter(valid_21627498, JString, required = false,
                                   default = nil)
  if valid_21627498 != nil:
    section.add "X-Amz-Date", valid_21627498
  var valid_21627499 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627499 = validateParameter(valid_21627499, JString, required = false,
                                   default = nil)
  if valid_21627499 != nil:
    section.add "X-Amz-Security-Token", valid_21627499
  var valid_21627500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627500 = validateParameter(valid_21627500, JString, required = false,
                                   default = nil)
  if valid_21627500 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627500
  var valid_21627501 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627501 = validateParameter(valid_21627501, JString, required = false,
                                   default = nil)
  if valid_21627501 != nil:
    section.add "X-Amz-Algorithm", valid_21627501
  var valid_21627502 = header.getOrDefault("X-Amz-Signature")
  valid_21627502 = validateParameter(valid_21627502, JString, required = false,
                                   default = nil)
  if valid_21627502 != nil:
    section.add "X-Amz-Signature", valid_21627502
  var valid_21627503 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627503 = validateParameter(valid_21627503, JString, required = false,
                                   default = nil)
  if valid_21627503 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627503
  var valid_21627504 = header.getOrDefault("X-Amz-Credential")
  valid_21627504 = validateParameter(valid_21627504, JString, required = false,
                                   default = nil)
  if valid_21627504 != nil:
    section.add "X-Amz-Credential", valid_21627504
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627505: Call_GetUpdateApplicationResourceLifecycle_21627490;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Modifies lifecycle settings for an application.
  ## 
  let valid = call_21627505.validator(path, query, header, formData, body, _)
  let scheme = call_21627505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627505.makeUrl(scheme.get, call_21627505.host, call_21627505.base,
                               call_21627505.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627505, uri, valid, _)

proc call*(call_21627506: Call_GetUpdateApplicationResourceLifecycle_21627490;
          ApplicationName: string;
          ResourceLifecycleConfigVersionLifecycleConfig: string = "";
          ResourceLifecycleConfigServiceRole: string = "";
          Action: string = "UpdateApplicationResourceLifecycle";
          Version: string = "2010-12-01"): Recallable =
  ## getUpdateApplicationResourceLifecycle
  ## Modifies lifecycle settings for an application.
  ##   ResourceLifecycleConfigVersionLifecycleConfig: string
  ##                                                : The resource lifecycle configuration for an application. Defines lifecycle settings for resources that belong to the application, and the service role that Elastic Beanstalk assumes in order to apply lifecycle settings. The version lifecycle configuration defines lifecycle settings for application versions.
  ## The application version lifecycle configuration.
  ##   ApplicationName: string (required)
  ##                  : The name of the application.
  ##   ResourceLifecycleConfigServiceRole: string
  ##                                     : The resource lifecycle configuration for an application. Defines lifecycle settings for resources that belong to the application, and the service role that Elastic Beanstalk assumes in order to apply lifecycle settings. The version lifecycle configuration defines lifecycle settings for application versions.
  ## <p>The ARN of an IAM service role that Elastic Beanstalk has permission to assume.</p> <p>The <code>ServiceRole</code> property is required the first time that you provide a <code>VersionLifecycleConfig</code> for the application in one of the supporting calls (<code>CreateApplication</code> or <code>UpdateApplicationResourceLifecycle</code>). After you provide it once, in either one of the calls, Elastic Beanstalk persists the Service Role with the application, and you don't need to specify it again in subsequent <code>UpdateApplicationResourceLifecycle</code> calls. You can, however, specify it in subsequent calls to change the Service Role to another value.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21627507 = newJObject()
  add(query_21627507, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  add(query_21627507, "ApplicationName", newJString(ApplicationName))
  add(query_21627507, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  add(query_21627507, "Action", newJString(Action))
  add(query_21627507, "Version", newJString(Version))
  result = call_21627506.call(nil, query_21627507, nil, nil, nil)

var getUpdateApplicationResourceLifecycle* = Call_GetUpdateApplicationResourceLifecycle_21627490(
    name: "getUpdateApplicationResourceLifecycle", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationResourceLifecycle",
    validator: validate_GetUpdateApplicationResourceLifecycle_21627491, base: "/",
    makeUrl: url_GetUpdateApplicationResourceLifecycle_21627492,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateApplicationVersion_21627545 = ref object of OpenApiRestCall_21625437
proc url_PostUpdateApplicationVersion_21627547(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateApplicationVersion_21627546(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627548 = query.getOrDefault("Action")
  valid_21627548 = validateParameter(valid_21627548, JString, required = true, default = newJString(
      "UpdateApplicationVersion"))
  if valid_21627548 != nil:
    section.add "Action", valid_21627548
  var valid_21627549 = query.getOrDefault("Version")
  valid_21627549 = validateParameter(valid_21627549, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21627549 != nil:
    section.add "Version", valid_21627549
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627550 = header.getOrDefault("X-Amz-Date")
  valid_21627550 = validateParameter(valid_21627550, JString, required = false,
                                   default = nil)
  if valid_21627550 != nil:
    section.add "X-Amz-Date", valid_21627550
  var valid_21627551 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627551 = validateParameter(valid_21627551, JString, required = false,
                                   default = nil)
  if valid_21627551 != nil:
    section.add "X-Amz-Security-Token", valid_21627551
  var valid_21627552 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627552 = validateParameter(valid_21627552, JString, required = false,
                                   default = nil)
  if valid_21627552 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627552
  var valid_21627553 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627553 = validateParameter(valid_21627553, JString, required = false,
                                   default = nil)
  if valid_21627553 != nil:
    section.add "X-Amz-Algorithm", valid_21627553
  var valid_21627554 = header.getOrDefault("X-Amz-Signature")
  valid_21627554 = validateParameter(valid_21627554, JString, required = false,
                                   default = nil)
  if valid_21627554 != nil:
    section.add "X-Amz-Signature", valid_21627554
  var valid_21627555 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627555 = validateParameter(valid_21627555, JString, required = false,
                                   default = nil)
  if valid_21627555 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627555
  var valid_21627556 = header.getOrDefault("X-Amz-Credential")
  valid_21627556 = validateParameter(valid_21627556, JString, required = false,
                                   default = nil)
  if valid_21627556 != nil:
    section.add "X-Amz-Credential", valid_21627556
  result.add "header", section
  ## parameters in `formData` object:
  ##   VersionLabel: JString (required)
  ##               : <p>The name of the version to update.</p> <p>If no application version is found with this label, <code>UpdateApplication</code> returns an <code>InvalidParameterValue</code> error. </p>
  ##   ApplicationName: JString (required)
  ##                  : <p>The name of the application associated with this version.</p> <p> If no application is found with this name, <code>UpdateApplication</code> returns an <code>InvalidParameterValue</code> error.</p>
  ##   Description: JString
  ##              : A new description for this version.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `VersionLabel` field"
  var valid_21627557 = formData.getOrDefault("VersionLabel")
  valid_21627557 = validateParameter(valid_21627557, JString, required = true,
                                   default = nil)
  if valid_21627557 != nil:
    section.add "VersionLabel", valid_21627557
  var valid_21627558 = formData.getOrDefault("ApplicationName")
  valid_21627558 = validateParameter(valid_21627558, JString, required = true,
                                   default = nil)
  if valid_21627558 != nil:
    section.add "ApplicationName", valid_21627558
  var valid_21627559 = formData.getOrDefault("Description")
  valid_21627559 = validateParameter(valid_21627559, JString, required = false,
                                   default = nil)
  if valid_21627559 != nil:
    section.add "Description", valid_21627559
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627560: Call_PostUpdateApplicationVersion_21627545;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates the specified application version to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear properties, specify an empty string.</p> </note>
  ## 
  let valid = call_21627560.validator(path, query, header, formData, body, _)
  let scheme = call_21627560.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627560.makeUrl(scheme.get, call_21627560.host, call_21627560.base,
                               call_21627560.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627560, uri, valid, _)

proc call*(call_21627561: Call_PostUpdateApplicationVersion_21627545;
          VersionLabel: string; ApplicationName: string;
          Action: string = "UpdateApplicationVersion";
          Version: string = "2010-12-01"; Description: string = ""): Recallable =
  ## postUpdateApplicationVersion
  ## <p>Updates the specified application version to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear properties, specify an empty string.</p> </note>
  ##   VersionLabel: string (required)
  ##               : <p>The name of the version to update.</p> <p>If no application version is found with this label, <code>UpdateApplication</code> returns an <code>InvalidParameterValue</code> error. </p>
  ##   Action: string (required)
  ##   ApplicationName: string (required)
  ##                  : <p>The name of the application associated with this version.</p> <p> If no application is found with this name, <code>UpdateApplication</code> returns an <code>InvalidParameterValue</code> error.</p>
  ##   Version: string (required)
  ##   Description: string
  ##              : A new description for this version.
  var query_21627562 = newJObject()
  var formData_21627563 = newJObject()
  add(formData_21627563, "VersionLabel", newJString(VersionLabel))
  add(query_21627562, "Action", newJString(Action))
  add(formData_21627563, "ApplicationName", newJString(ApplicationName))
  add(query_21627562, "Version", newJString(Version))
  add(formData_21627563, "Description", newJString(Description))
  result = call_21627561.call(nil, query_21627562, nil, formData_21627563, nil)

var postUpdateApplicationVersion* = Call_PostUpdateApplicationVersion_21627545(
    name: "postUpdateApplicationVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationVersion",
    validator: validate_PostUpdateApplicationVersion_21627546, base: "/",
    makeUrl: url_PostUpdateApplicationVersion_21627547,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateApplicationVersion_21627527 = ref object of OpenApiRestCall_21625437
proc url_GetUpdateApplicationVersion_21627529(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateApplicationVersion_21627528(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Updates the specified application version to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear properties, specify an empty string.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   VersionLabel: JString (required)
  ##               : <p>The name of the version to update.</p> <p>If no application version is found with this label, <code>UpdateApplication</code> returns an <code>InvalidParameterValue</code> error. </p>
  ##   ApplicationName: JString (required)
  ##                  : <p>The name of the application associated with this version.</p> <p> If no application is found with this name, <code>UpdateApplication</code> returns an <code>InvalidParameterValue</code> error.</p>
  ##   Description: JString
  ##              : A new description for this version.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `VersionLabel` field"
  var valid_21627530 = query.getOrDefault("VersionLabel")
  valid_21627530 = validateParameter(valid_21627530, JString, required = true,
                                   default = nil)
  if valid_21627530 != nil:
    section.add "VersionLabel", valid_21627530
  var valid_21627531 = query.getOrDefault("ApplicationName")
  valid_21627531 = validateParameter(valid_21627531, JString, required = true,
                                   default = nil)
  if valid_21627531 != nil:
    section.add "ApplicationName", valid_21627531
  var valid_21627532 = query.getOrDefault("Description")
  valid_21627532 = validateParameter(valid_21627532, JString, required = false,
                                   default = nil)
  if valid_21627532 != nil:
    section.add "Description", valid_21627532
  var valid_21627533 = query.getOrDefault("Action")
  valid_21627533 = validateParameter(valid_21627533, JString, required = true, default = newJString(
      "UpdateApplicationVersion"))
  if valid_21627533 != nil:
    section.add "Action", valid_21627533
  var valid_21627534 = query.getOrDefault("Version")
  valid_21627534 = validateParameter(valid_21627534, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21627534 != nil:
    section.add "Version", valid_21627534
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627535 = header.getOrDefault("X-Amz-Date")
  valid_21627535 = validateParameter(valid_21627535, JString, required = false,
                                   default = nil)
  if valid_21627535 != nil:
    section.add "X-Amz-Date", valid_21627535
  var valid_21627536 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627536 = validateParameter(valid_21627536, JString, required = false,
                                   default = nil)
  if valid_21627536 != nil:
    section.add "X-Amz-Security-Token", valid_21627536
  var valid_21627537 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627537 = validateParameter(valid_21627537, JString, required = false,
                                   default = nil)
  if valid_21627537 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627537
  var valid_21627538 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627538 = validateParameter(valid_21627538, JString, required = false,
                                   default = nil)
  if valid_21627538 != nil:
    section.add "X-Amz-Algorithm", valid_21627538
  var valid_21627539 = header.getOrDefault("X-Amz-Signature")
  valid_21627539 = validateParameter(valid_21627539, JString, required = false,
                                   default = nil)
  if valid_21627539 != nil:
    section.add "X-Amz-Signature", valid_21627539
  var valid_21627540 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627540 = validateParameter(valid_21627540, JString, required = false,
                                   default = nil)
  if valid_21627540 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627540
  var valid_21627541 = header.getOrDefault("X-Amz-Credential")
  valid_21627541 = validateParameter(valid_21627541, JString, required = false,
                                   default = nil)
  if valid_21627541 != nil:
    section.add "X-Amz-Credential", valid_21627541
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627542: Call_GetUpdateApplicationVersion_21627527;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates the specified application version to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear properties, specify an empty string.</p> </note>
  ## 
  let valid = call_21627542.validator(path, query, header, formData, body, _)
  let scheme = call_21627542.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627542.makeUrl(scheme.get, call_21627542.host, call_21627542.base,
                               call_21627542.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627542, uri, valid, _)

proc call*(call_21627543: Call_GetUpdateApplicationVersion_21627527;
          VersionLabel: string; ApplicationName: string; Description: string = "";
          Action: string = "UpdateApplicationVersion";
          Version: string = "2010-12-01"): Recallable =
  ## getUpdateApplicationVersion
  ## <p>Updates the specified application version to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear properties, specify an empty string.</p> </note>
  ##   VersionLabel: string (required)
  ##               : <p>The name of the version to update.</p> <p>If no application version is found with this label, <code>UpdateApplication</code> returns an <code>InvalidParameterValue</code> error. </p>
  ##   ApplicationName: string (required)
  ##                  : <p>The name of the application associated with this version.</p> <p> If no application is found with this name, <code>UpdateApplication</code> returns an <code>InvalidParameterValue</code> error.</p>
  ##   Description: string
  ##              : A new description for this version.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21627544 = newJObject()
  add(query_21627544, "VersionLabel", newJString(VersionLabel))
  add(query_21627544, "ApplicationName", newJString(ApplicationName))
  add(query_21627544, "Description", newJString(Description))
  add(query_21627544, "Action", newJString(Action))
  add(query_21627544, "Version", newJString(Version))
  result = call_21627543.call(nil, query_21627544, nil, nil, nil)

var getUpdateApplicationVersion* = Call_GetUpdateApplicationVersion_21627527(
    name: "getUpdateApplicationVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationVersion",
    validator: validate_GetUpdateApplicationVersion_21627528, base: "/",
    makeUrl: url_GetUpdateApplicationVersion_21627529,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateConfigurationTemplate_21627584 = ref object of OpenApiRestCall_21625437
proc url_PostUpdateConfigurationTemplate_21627586(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateConfigurationTemplate_21627585(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627587 = query.getOrDefault("Action")
  valid_21627587 = validateParameter(valid_21627587, JString, required = true, default = newJString(
      "UpdateConfigurationTemplate"))
  if valid_21627587 != nil:
    section.add "Action", valid_21627587
  var valid_21627588 = query.getOrDefault("Version")
  valid_21627588 = validateParameter(valid_21627588, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21627588 != nil:
    section.add "Version", valid_21627588
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627589 = header.getOrDefault("X-Amz-Date")
  valid_21627589 = validateParameter(valid_21627589, JString, required = false,
                                   default = nil)
  if valid_21627589 != nil:
    section.add "X-Amz-Date", valid_21627589
  var valid_21627590 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627590 = validateParameter(valid_21627590, JString, required = false,
                                   default = nil)
  if valid_21627590 != nil:
    section.add "X-Amz-Security-Token", valid_21627590
  var valid_21627591 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627591 = validateParameter(valid_21627591, JString, required = false,
                                   default = nil)
  if valid_21627591 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627591
  var valid_21627592 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627592 = validateParameter(valid_21627592, JString, required = false,
                                   default = nil)
  if valid_21627592 != nil:
    section.add "X-Amz-Algorithm", valid_21627592
  var valid_21627593 = header.getOrDefault("X-Amz-Signature")
  valid_21627593 = validateParameter(valid_21627593, JString, required = false,
                                   default = nil)
  if valid_21627593 != nil:
    section.add "X-Amz-Signature", valid_21627593
  var valid_21627594 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627594 = validateParameter(valid_21627594, JString, required = false,
                                   default = nil)
  if valid_21627594 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627594
  var valid_21627595 = header.getOrDefault("X-Amz-Credential")
  valid_21627595 = validateParameter(valid_21627595, JString, required = false,
                                   default = nil)
  if valid_21627595 != nil:
    section.add "X-Amz-Credential", valid_21627595
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionsToRemove: JArray
  ##                  : <p>A list of configuration options to remove from the configuration set.</p> <p> Constraint: You can remove only <code>UserDefined</code> configuration options. </p>
  ##   OptionSettings: JArray
  ##                 : A list of configuration option settings to update with the new specified option value.
  ##   ApplicationName: JString (required)
  ##                  : <p>The name of the application associated with the configuration template to update.</p> <p> If no application is found with this name, <code>UpdateConfigurationTemplate</code> returns an <code>InvalidParameterValue</code> error. </p>
  ##   TemplateName: JString (required)
  ##               : <p>The name of the configuration template to update.</p> <p> If no configuration template is found with this name, <code>UpdateConfigurationTemplate</code> returns an <code>InvalidParameterValue</code> error. </p>
  ##   Description: JString
  ##              : A new description for the configuration.
  section = newJObject()
  var valid_21627596 = formData.getOrDefault("OptionsToRemove")
  valid_21627596 = validateParameter(valid_21627596, JArray, required = false,
                                   default = nil)
  if valid_21627596 != nil:
    section.add "OptionsToRemove", valid_21627596
  var valid_21627597 = formData.getOrDefault("OptionSettings")
  valid_21627597 = validateParameter(valid_21627597, JArray, required = false,
                                   default = nil)
  if valid_21627597 != nil:
    section.add "OptionSettings", valid_21627597
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_21627598 = formData.getOrDefault("ApplicationName")
  valid_21627598 = validateParameter(valid_21627598, JString, required = true,
                                   default = nil)
  if valid_21627598 != nil:
    section.add "ApplicationName", valid_21627598
  var valid_21627599 = formData.getOrDefault("TemplateName")
  valid_21627599 = validateParameter(valid_21627599, JString, required = true,
                                   default = nil)
  if valid_21627599 != nil:
    section.add "TemplateName", valid_21627599
  var valid_21627600 = formData.getOrDefault("Description")
  valid_21627600 = validateParameter(valid_21627600, JString, required = false,
                                   default = nil)
  if valid_21627600 != nil:
    section.add "Description", valid_21627600
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627601: Call_PostUpdateConfigurationTemplate_21627584;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates the specified configuration template to have the specified properties or configuration option values.</p> <note> <p>If a property (for example, <code>ApplicationName</code>) is not provided, its value remains unchanged. To clear such properties, specify an empty string.</p> </note> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> </ul>
  ## 
  let valid = call_21627601.validator(path, query, header, formData, body, _)
  let scheme = call_21627601.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627601.makeUrl(scheme.get, call_21627601.host, call_21627601.base,
                               call_21627601.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627601, uri, valid, _)

proc call*(call_21627602: Call_PostUpdateConfigurationTemplate_21627584;
          ApplicationName: string; TemplateName: string;
          OptionsToRemove: JsonNode = nil; OptionSettings: JsonNode = nil;
          Action: string = "UpdateConfigurationTemplate";
          Version: string = "2010-12-01"; Description: string = ""): Recallable =
  ## postUpdateConfigurationTemplate
  ## <p>Updates the specified configuration template to have the specified properties or configuration option values.</p> <note> <p>If a property (for example, <code>ApplicationName</code>) is not provided, its value remains unchanged. To clear such properties, specify an empty string.</p> </note> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> </ul>
  ##   OptionsToRemove: JArray
  ##                  : <p>A list of configuration options to remove from the configuration set.</p> <p> Constraint: You can remove only <code>UserDefined</code> configuration options. </p>
  ##   OptionSettings: JArray
  ##                 : A list of configuration option settings to update with the new specified option value.
  ##   Action: string (required)
  ##   ApplicationName: string (required)
  ##                  : <p>The name of the application associated with the configuration template to update.</p> <p> If no application is found with this name, <code>UpdateConfigurationTemplate</code> returns an <code>InvalidParameterValue</code> error. </p>
  ##   TemplateName: string (required)
  ##               : <p>The name of the configuration template to update.</p> <p> If no configuration template is found with this name, <code>UpdateConfigurationTemplate</code> returns an <code>InvalidParameterValue</code> error. </p>
  ##   Version: string (required)
  ##   Description: string
  ##              : A new description for the configuration.
  var query_21627603 = newJObject()
  var formData_21627604 = newJObject()
  if OptionsToRemove != nil:
    formData_21627604.add "OptionsToRemove", OptionsToRemove
  if OptionSettings != nil:
    formData_21627604.add "OptionSettings", OptionSettings
  add(query_21627603, "Action", newJString(Action))
  add(formData_21627604, "ApplicationName", newJString(ApplicationName))
  add(formData_21627604, "TemplateName", newJString(TemplateName))
  add(query_21627603, "Version", newJString(Version))
  add(formData_21627604, "Description", newJString(Description))
  result = call_21627602.call(nil, query_21627603, nil, formData_21627604, nil)

var postUpdateConfigurationTemplate* = Call_PostUpdateConfigurationTemplate_21627584(
    name: "postUpdateConfigurationTemplate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateConfigurationTemplate",
    validator: validate_PostUpdateConfigurationTemplate_21627585, base: "/",
    makeUrl: url_PostUpdateConfigurationTemplate_21627586,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateConfigurationTemplate_21627564 = ref object of OpenApiRestCall_21625437
proc url_GetUpdateConfigurationTemplate_21627566(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateConfigurationTemplate_21627565(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Updates the specified configuration template to have the specified properties or configuration option values.</p> <note> <p>If a property (for example, <code>ApplicationName</code>) is not provided, its value remains unchanged. To clear such properties, specify an empty string.</p> </note> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ApplicationName: JString (required)
  ##                  : <p>The name of the application associated with the configuration template to update.</p> <p> If no application is found with this name, <code>UpdateConfigurationTemplate</code> returns an <code>InvalidParameterValue</code> error. </p>
  ##   Description: JString
  ##              : A new description for the configuration.
  ##   OptionsToRemove: JArray
  ##                  : <p>A list of configuration options to remove from the configuration set.</p> <p> Constraint: You can remove only <code>UserDefined</code> configuration options. </p>
  ##   Action: JString (required)
  ##   TemplateName: JString (required)
  ##               : <p>The name of the configuration template to update.</p> <p> If no configuration template is found with this name, <code>UpdateConfigurationTemplate</code> returns an <code>InvalidParameterValue</code> error. </p>
  ##   OptionSettings: JArray
  ##                 : A list of configuration option settings to update with the new specified option value.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_21627567 = query.getOrDefault("ApplicationName")
  valid_21627567 = validateParameter(valid_21627567, JString, required = true,
                                   default = nil)
  if valid_21627567 != nil:
    section.add "ApplicationName", valid_21627567
  var valid_21627568 = query.getOrDefault("Description")
  valid_21627568 = validateParameter(valid_21627568, JString, required = false,
                                   default = nil)
  if valid_21627568 != nil:
    section.add "Description", valid_21627568
  var valid_21627569 = query.getOrDefault("OptionsToRemove")
  valid_21627569 = validateParameter(valid_21627569, JArray, required = false,
                                   default = nil)
  if valid_21627569 != nil:
    section.add "OptionsToRemove", valid_21627569
  var valid_21627570 = query.getOrDefault("Action")
  valid_21627570 = validateParameter(valid_21627570, JString, required = true, default = newJString(
      "UpdateConfigurationTemplate"))
  if valid_21627570 != nil:
    section.add "Action", valid_21627570
  var valid_21627571 = query.getOrDefault("TemplateName")
  valid_21627571 = validateParameter(valid_21627571, JString, required = true,
                                   default = nil)
  if valid_21627571 != nil:
    section.add "TemplateName", valid_21627571
  var valid_21627572 = query.getOrDefault("OptionSettings")
  valid_21627572 = validateParameter(valid_21627572, JArray, required = false,
                                   default = nil)
  if valid_21627572 != nil:
    section.add "OptionSettings", valid_21627572
  var valid_21627573 = query.getOrDefault("Version")
  valid_21627573 = validateParameter(valid_21627573, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21627573 != nil:
    section.add "Version", valid_21627573
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627574 = header.getOrDefault("X-Amz-Date")
  valid_21627574 = validateParameter(valid_21627574, JString, required = false,
                                   default = nil)
  if valid_21627574 != nil:
    section.add "X-Amz-Date", valid_21627574
  var valid_21627575 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627575 = validateParameter(valid_21627575, JString, required = false,
                                   default = nil)
  if valid_21627575 != nil:
    section.add "X-Amz-Security-Token", valid_21627575
  var valid_21627576 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627576 = validateParameter(valid_21627576, JString, required = false,
                                   default = nil)
  if valid_21627576 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627576
  var valid_21627577 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627577 = validateParameter(valid_21627577, JString, required = false,
                                   default = nil)
  if valid_21627577 != nil:
    section.add "X-Amz-Algorithm", valid_21627577
  var valid_21627578 = header.getOrDefault("X-Amz-Signature")
  valid_21627578 = validateParameter(valid_21627578, JString, required = false,
                                   default = nil)
  if valid_21627578 != nil:
    section.add "X-Amz-Signature", valid_21627578
  var valid_21627579 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627579 = validateParameter(valid_21627579, JString, required = false,
                                   default = nil)
  if valid_21627579 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627579
  var valid_21627580 = header.getOrDefault("X-Amz-Credential")
  valid_21627580 = validateParameter(valid_21627580, JString, required = false,
                                   default = nil)
  if valid_21627580 != nil:
    section.add "X-Amz-Credential", valid_21627580
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627581: Call_GetUpdateConfigurationTemplate_21627564;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates the specified configuration template to have the specified properties or configuration option values.</p> <note> <p>If a property (for example, <code>ApplicationName</code>) is not provided, its value remains unchanged. To clear such properties, specify an empty string.</p> </note> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> </ul>
  ## 
  let valid = call_21627581.validator(path, query, header, formData, body, _)
  let scheme = call_21627581.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627581.makeUrl(scheme.get, call_21627581.host, call_21627581.base,
                               call_21627581.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627581, uri, valid, _)

proc call*(call_21627582: Call_GetUpdateConfigurationTemplate_21627564;
          ApplicationName: string; TemplateName: string; Description: string = "";
          OptionsToRemove: JsonNode = nil;
          Action: string = "UpdateConfigurationTemplate";
          OptionSettings: JsonNode = nil; Version: string = "2010-12-01"): Recallable =
  ## getUpdateConfigurationTemplate
  ## <p>Updates the specified configuration template to have the specified properties or configuration option values.</p> <note> <p>If a property (for example, <code>ApplicationName</code>) is not provided, its value remains unchanged. To clear such properties, specify an empty string.</p> </note> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> </ul>
  ##   ApplicationName: string (required)
  ##                  : <p>The name of the application associated with the configuration template to update.</p> <p> If no application is found with this name, <code>UpdateConfigurationTemplate</code> returns an <code>InvalidParameterValue</code> error. </p>
  ##   Description: string
  ##              : A new description for the configuration.
  ##   OptionsToRemove: JArray
  ##                  : <p>A list of configuration options to remove from the configuration set.</p> <p> Constraint: You can remove only <code>UserDefined</code> configuration options. </p>
  ##   Action: string (required)
  ##   TemplateName: string (required)
  ##               : <p>The name of the configuration template to update.</p> <p> If no configuration template is found with this name, <code>UpdateConfigurationTemplate</code> returns an <code>InvalidParameterValue</code> error. </p>
  ##   OptionSettings: JArray
  ##                 : A list of configuration option settings to update with the new specified option value.
  ##   Version: string (required)
  var query_21627583 = newJObject()
  add(query_21627583, "ApplicationName", newJString(ApplicationName))
  add(query_21627583, "Description", newJString(Description))
  if OptionsToRemove != nil:
    query_21627583.add "OptionsToRemove", OptionsToRemove
  add(query_21627583, "Action", newJString(Action))
  add(query_21627583, "TemplateName", newJString(TemplateName))
  if OptionSettings != nil:
    query_21627583.add "OptionSettings", OptionSettings
  add(query_21627583, "Version", newJString(Version))
  result = call_21627582.call(nil, query_21627583, nil, nil, nil)

var getUpdateConfigurationTemplate* = Call_GetUpdateConfigurationTemplate_21627564(
    name: "getUpdateConfigurationTemplate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateConfigurationTemplate",
    validator: validate_GetUpdateConfigurationTemplate_21627565, base: "/",
    makeUrl: url_GetUpdateConfigurationTemplate_21627566,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateEnvironment_21627634 = ref object of OpenApiRestCall_21625437
proc url_PostUpdateEnvironment_21627636(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateEnvironment_21627635(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627637 = query.getOrDefault("Action")
  valid_21627637 = validateParameter(valid_21627637, JString, required = true,
                                   default = newJString("UpdateEnvironment"))
  if valid_21627637 != nil:
    section.add "Action", valid_21627637
  var valid_21627638 = query.getOrDefault("Version")
  valid_21627638 = validateParameter(valid_21627638, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21627638 != nil:
    section.add "Version", valid_21627638
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627639 = header.getOrDefault("X-Amz-Date")
  valid_21627639 = validateParameter(valid_21627639, JString, required = false,
                                   default = nil)
  if valid_21627639 != nil:
    section.add "X-Amz-Date", valid_21627639
  var valid_21627640 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627640 = validateParameter(valid_21627640, JString, required = false,
                                   default = nil)
  if valid_21627640 != nil:
    section.add "X-Amz-Security-Token", valid_21627640
  var valid_21627641 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627641 = validateParameter(valid_21627641, JString, required = false,
                                   default = nil)
  if valid_21627641 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627641
  var valid_21627642 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627642 = validateParameter(valid_21627642, JString, required = false,
                                   default = nil)
  if valid_21627642 != nil:
    section.add "X-Amz-Algorithm", valid_21627642
  var valid_21627643 = header.getOrDefault("X-Amz-Signature")
  valid_21627643 = validateParameter(valid_21627643, JString, required = false,
                                   default = nil)
  if valid_21627643 != nil:
    section.add "X-Amz-Signature", valid_21627643
  var valid_21627644 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627644 = validateParameter(valid_21627644, JString, required = false,
                                   default = nil)
  if valid_21627644 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627644
  var valid_21627645 = header.getOrDefault("X-Amz-Credential")
  valid_21627645 = validateParameter(valid_21627645, JString, required = false,
                                   default = nil)
  if valid_21627645 != nil:
    section.add "X-Amz-Credential", valid_21627645
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tier.Name: JString
  ##            : Describes the properties of an environment tier
  ## <p>The name of this environment tier.</p> <p>Valid values:</p> <ul> <li> <p>For <i>Web server tier</i> – <code>WebServer</code> </p> </li> <li> <p>For <i>Worker tier</i> – <code>Worker</code> </p> </li> </ul>
  ##   OptionsToRemove: JArray
  ##                  : A list of custom user-defined configuration options to remove from the configuration set for this environment.
  ##   VersionLabel: JString
  ##               : If this parameter is specified, AWS Elastic Beanstalk deploys the named application version to the environment. If no such application version is found, returns an <code>InvalidParameterValue</code> error. 
  ##   OptionSettings: JArray
  ##                 : If specified, AWS Elastic Beanstalk updates the configuration set associated with the running environment and sets the specified configuration options to the requested value.
  ##   GroupName: JString
  ##            : The name of the group to which the target environment belongs. Specify a group name only if the environment's name is specified in an environment manifest and not with the environment name or environment ID parameters. See <a 
  ## href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-cfg-manifest.html">Environment Manifest (env.yaml)</a> for details.
  ##   SolutionStackName: JString
  ##                    : This specifies the platform version that the environment will run after the environment is updated.
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to update.</p> <p>If no environment with this ID exists, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error.</p> <p>Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to update. If no environment with this name exists, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. </p> <p>Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Tier.Type: JString
  ##            : Describes the properties of an environment tier
  ## <p>The type of this environment tier.</p> <p>Valid values:</p> <ul> <li> <p>For <i>Web server tier</i> – <code>Standard</code> </p> </li> <li> <p>For <i>Worker tier</i> – <code>SQS/HTTP</code> </p> </li> </ul>
  ##   ApplicationName: JString
  ##                  : The name of the application with which the environment is associated.
  ##   PlatformArn: JString
  ##              : The ARN of the platform, if used.
  ##   TemplateName: JString
  ##               : If this parameter is specified, AWS Elastic Beanstalk deploys this configuration template to the environment. If no such configuration template is found, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. 
  ##   Description: JString
  ##              : If this parameter is specified, AWS Elastic Beanstalk updates the description of this environment.
  ##   Tier.Version: JString
  ##               : Describes the properties of an environment tier
  ## <p>The version of this environment tier. When you don't set a value to it, Elastic Beanstalk uses the latest compatible worker tier version.</p> <note> <p>This member is deprecated. Any specific version that you set may become out of date. We recommend leaving it unspecified.</p> </note>
  section = newJObject()
  var valid_21627646 = formData.getOrDefault("Tier.Name")
  valid_21627646 = validateParameter(valid_21627646, JString, required = false,
                                   default = nil)
  if valid_21627646 != nil:
    section.add "Tier.Name", valid_21627646
  var valid_21627647 = formData.getOrDefault("OptionsToRemove")
  valid_21627647 = validateParameter(valid_21627647, JArray, required = false,
                                   default = nil)
  if valid_21627647 != nil:
    section.add "OptionsToRemove", valid_21627647
  var valid_21627648 = formData.getOrDefault("VersionLabel")
  valid_21627648 = validateParameter(valid_21627648, JString, required = false,
                                   default = nil)
  if valid_21627648 != nil:
    section.add "VersionLabel", valid_21627648
  var valid_21627649 = formData.getOrDefault("OptionSettings")
  valid_21627649 = validateParameter(valid_21627649, JArray, required = false,
                                   default = nil)
  if valid_21627649 != nil:
    section.add "OptionSettings", valid_21627649
  var valid_21627650 = formData.getOrDefault("GroupName")
  valid_21627650 = validateParameter(valid_21627650, JString, required = false,
                                   default = nil)
  if valid_21627650 != nil:
    section.add "GroupName", valid_21627650
  var valid_21627651 = formData.getOrDefault("SolutionStackName")
  valid_21627651 = validateParameter(valid_21627651, JString, required = false,
                                   default = nil)
  if valid_21627651 != nil:
    section.add "SolutionStackName", valid_21627651
  var valid_21627652 = formData.getOrDefault("EnvironmentId")
  valid_21627652 = validateParameter(valid_21627652, JString, required = false,
                                   default = nil)
  if valid_21627652 != nil:
    section.add "EnvironmentId", valid_21627652
  var valid_21627653 = formData.getOrDefault("EnvironmentName")
  valid_21627653 = validateParameter(valid_21627653, JString, required = false,
                                   default = nil)
  if valid_21627653 != nil:
    section.add "EnvironmentName", valid_21627653
  var valid_21627654 = formData.getOrDefault("Tier.Type")
  valid_21627654 = validateParameter(valid_21627654, JString, required = false,
                                   default = nil)
  if valid_21627654 != nil:
    section.add "Tier.Type", valid_21627654
  var valid_21627655 = formData.getOrDefault("ApplicationName")
  valid_21627655 = validateParameter(valid_21627655, JString, required = false,
                                   default = nil)
  if valid_21627655 != nil:
    section.add "ApplicationName", valid_21627655
  var valid_21627656 = formData.getOrDefault("PlatformArn")
  valid_21627656 = validateParameter(valid_21627656, JString, required = false,
                                   default = nil)
  if valid_21627656 != nil:
    section.add "PlatformArn", valid_21627656
  var valid_21627657 = formData.getOrDefault("TemplateName")
  valid_21627657 = validateParameter(valid_21627657, JString, required = false,
                                   default = nil)
  if valid_21627657 != nil:
    section.add "TemplateName", valid_21627657
  var valid_21627658 = formData.getOrDefault("Description")
  valid_21627658 = validateParameter(valid_21627658, JString, required = false,
                                   default = nil)
  if valid_21627658 != nil:
    section.add "Description", valid_21627658
  var valid_21627659 = formData.getOrDefault("Tier.Version")
  valid_21627659 = validateParameter(valid_21627659, JString, required = false,
                                   default = nil)
  if valid_21627659 != nil:
    section.add "Tier.Version", valid_21627659
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627660: Call_PostUpdateEnvironment_21627634;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates the environment description, deploys a new application version, updates the configuration settings to an entirely new configuration template, or updates select configuration option values in the running environment.</p> <p> Attempting to update both the release and configuration is not allowed and AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. </p> <p> When updating the configuration settings to a new template or individual settings, a draft configuration is created and <a>DescribeConfigurationSettings</a> for this environment returns two setting descriptions with different <code>DeploymentStatus</code> values. </p>
  ## 
  let valid = call_21627660.validator(path, query, header, formData, body, _)
  let scheme = call_21627660.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627660.makeUrl(scheme.get, call_21627660.host, call_21627660.base,
                               call_21627660.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627660, uri, valid, _)

proc call*(call_21627661: Call_PostUpdateEnvironment_21627634;
          TierName: string = ""; OptionsToRemove: JsonNode = nil;
          VersionLabel: string = ""; OptionSettings: JsonNode = nil;
          GroupName: string = ""; SolutionStackName: string = "";
          EnvironmentId: string = ""; EnvironmentName: string = "";
          TierType: string = ""; Action: string = "UpdateEnvironment";
          ApplicationName: string = ""; PlatformArn: string = "";
          TemplateName: string = ""; Version: string = "2010-12-01";
          Description: string = ""; TierVersion: string = ""): Recallable =
  ## postUpdateEnvironment
  ## <p>Updates the environment description, deploys a new application version, updates the configuration settings to an entirely new configuration template, or updates select configuration option values in the running environment.</p> <p> Attempting to update both the release and configuration is not allowed and AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. </p> <p> When updating the configuration settings to a new template or individual settings, a draft configuration is created and <a>DescribeConfigurationSettings</a> for this environment returns two setting descriptions with different <code>DeploymentStatus</code> values. </p>
  ##   TierName: string
  ##           : Describes the properties of an environment tier
  ## <p>The name of this environment tier.</p> <p>Valid values:</p> <ul> <li> <p>For <i>Web server tier</i> – <code>WebServer</code> </p> </li> <li> <p>For <i>Worker tier</i> – <code>Worker</code> </p> </li> </ul>
  ##   OptionsToRemove: JArray
  ##                  : A list of custom user-defined configuration options to remove from the configuration set for this environment.
  ##   VersionLabel: string
  ##               : If this parameter is specified, AWS Elastic Beanstalk deploys the named application version to the environment. If no such application version is found, returns an <code>InvalidParameterValue</code> error. 
  ##   OptionSettings: JArray
  ##                 : If specified, AWS Elastic Beanstalk updates the configuration set associated with the running environment and sets the specified configuration options to the requested value.
  ##   GroupName: string
  ##            : The name of the group to which the target environment belongs. Specify a group name only if the environment's name is specified in an environment manifest and not with the environment name or environment ID parameters. See <a 
  ## href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-cfg-manifest.html">Environment Manifest (env.yaml)</a> for details.
  ##   SolutionStackName: string
  ##                    : This specifies the platform version that the environment will run after the environment is updated.
  ##   EnvironmentId: string
  ##                : <p>The ID of the environment to update.</p> <p>If no environment with this ID exists, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error.</p> <p>Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentName: string
  ##                  : <p>The name of the environment to update. If no environment with this name exists, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. </p> <p>Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   TierType: string
  ##           : Describes the properties of an environment tier
  ## <p>The type of this environment tier.</p> <p>Valid values:</p> <ul> <li> <p>For <i>Web server tier</i> – <code>Standard</code> </p> </li> <li> <p>For <i>Worker tier</i> – <code>SQS/HTTP</code> </p> </li> </ul>
  ##   Action: string (required)
  ##   ApplicationName: string
  ##                  : The name of the application with which the environment is associated.
  ##   PlatformArn: string
  ##              : The ARN of the platform, if used.
  ##   TemplateName: string
  ##               : If this parameter is specified, AWS Elastic Beanstalk deploys this configuration template to the environment. If no such configuration template is found, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. 
  ##   Version: string (required)
  ##   Description: string
  ##              : If this parameter is specified, AWS Elastic Beanstalk updates the description of this environment.
  ##   TierVersion: string
  ##              : Describes the properties of an environment tier
  ## <p>The version of this environment tier. When you don't set a value to it, Elastic Beanstalk uses the latest compatible worker tier version.</p> <note> <p>This member is deprecated. Any specific version that you set may become out of date. We recommend leaving it unspecified.</p> </note>
  var query_21627662 = newJObject()
  var formData_21627663 = newJObject()
  add(formData_21627663, "Tier.Name", newJString(TierName))
  if OptionsToRemove != nil:
    formData_21627663.add "OptionsToRemove", OptionsToRemove
  add(formData_21627663, "VersionLabel", newJString(VersionLabel))
  if OptionSettings != nil:
    formData_21627663.add "OptionSettings", OptionSettings
  add(formData_21627663, "GroupName", newJString(GroupName))
  add(formData_21627663, "SolutionStackName", newJString(SolutionStackName))
  add(formData_21627663, "EnvironmentId", newJString(EnvironmentId))
  add(formData_21627663, "EnvironmentName", newJString(EnvironmentName))
  add(formData_21627663, "Tier.Type", newJString(TierType))
  add(query_21627662, "Action", newJString(Action))
  add(formData_21627663, "ApplicationName", newJString(ApplicationName))
  add(formData_21627663, "PlatformArn", newJString(PlatformArn))
  add(formData_21627663, "TemplateName", newJString(TemplateName))
  add(query_21627662, "Version", newJString(Version))
  add(formData_21627663, "Description", newJString(Description))
  add(formData_21627663, "Tier.Version", newJString(TierVersion))
  result = call_21627661.call(nil, query_21627662, nil, formData_21627663, nil)

var postUpdateEnvironment* = Call_PostUpdateEnvironment_21627634(
    name: "postUpdateEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateEnvironment",
    validator: validate_PostUpdateEnvironment_21627635, base: "/",
    makeUrl: url_PostUpdateEnvironment_21627636,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateEnvironment_21627605 = ref object of OpenApiRestCall_21625437
proc url_GetUpdateEnvironment_21627607(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateEnvironment_21627606(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Updates the environment description, deploys a new application version, updates the configuration settings to an entirely new configuration template, or updates select configuration option values in the running environment.</p> <p> Attempting to update both the release and configuration is not allowed and AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. </p> <p> When updating the configuration settings to a new template or individual settings, a draft configuration is created and <a>DescribeConfigurationSettings</a> for this environment returns two setting descriptions with different <code>DeploymentStatus</code> values. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tier.Name: JString
  ##            : Describes the properties of an environment tier
  ## <p>The name of this environment tier.</p> <p>Valid values:</p> <ul> <li> <p>For <i>Web server tier</i> – <code>WebServer</code> </p> </li> <li> <p>For <i>Worker tier</i> – <code>Worker</code> </p> </li> </ul>
  ##   VersionLabel: JString
  ##               : If this parameter is specified, AWS Elastic Beanstalk deploys the named application version to the environment. If no such application version is found, returns an <code>InvalidParameterValue</code> error. 
  ##   ApplicationName: JString
  ##                  : The name of the application with which the environment is associated.
  ##   Description: JString
  ##              : If this parameter is specified, AWS Elastic Beanstalk updates the description of this environment.
  ##   OptionsToRemove: JArray
  ##                  : A list of custom user-defined configuration options to remove from the configuration set for this environment.
  ##   PlatformArn: JString
  ##              : The ARN of the platform, if used.
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to update. If no environment with this name exists, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. </p> <p>Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Action: JString (required)
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to update.</p> <p>If no environment with this ID exists, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error.</p> <p>Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Tier.Version: JString
  ##               : Describes the properties of an environment tier
  ## <p>The version of this environment tier. When you don't set a value to it, Elastic Beanstalk uses the latest compatible worker tier version.</p> <note> <p>This member is deprecated. Any specific version that you set may become out of date. We recommend leaving it unspecified.</p> </note>
  ##   SolutionStackName: JString
  ##                    : This specifies the platform version that the environment will run after the environment is updated.
  ##   TemplateName: JString
  ##               : If this parameter is specified, AWS Elastic Beanstalk deploys this configuration template to the environment. If no such configuration template is found, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. 
  ##   GroupName: JString
  ##            : The name of the group to which the target environment belongs. Specify a group name only if the environment's name is specified in an environment manifest and not with the environment name or environment ID parameters. See <a 
  ## href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-cfg-manifest.html">Environment Manifest (env.yaml)</a> for details.
  ##   OptionSettings: JArray
  ##                 : If specified, AWS Elastic Beanstalk updates the configuration set associated with the running environment and sets the specified configuration options to the requested value.
  ##   Tier.Type: JString
  ##            : Describes the properties of an environment tier
  ## <p>The type of this environment tier.</p> <p>Valid values:</p> <ul> <li> <p>For <i>Web server tier</i> – <code>Standard</code> </p> </li> <li> <p>For <i>Worker tier</i> – <code>SQS/HTTP</code> </p> </li> </ul>
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627608 = query.getOrDefault("Tier.Name")
  valid_21627608 = validateParameter(valid_21627608, JString, required = false,
                                   default = nil)
  if valid_21627608 != nil:
    section.add "Tier.Name", valid_21627608
  var valid_21627609 = query.getOrDefault("VersionLabel")
  valid_21627609 = validateParameter(valid_21627609, JString, required = false,
                                   default = nil)
  if valid_21627609 != nil:
    section.add "VersionLabel", valid_21627609
  var valid_21627610 = query.getOrDefault("ApplicationName")
  valid_21627610 = validateParameter(valid_21627610, JString, required = false,
                                   default = nil)
  if valid_21627610 != nil:
    section.add "ApplicationName", valid_21627610
  var valid_21627611 = query.getOrDefault("Description")
  valid_21627611 = validateParameter(valid_21627611, JString, required = false,
                                   default = nil)
  if valid_21627611 != nil:
    section.add "Description", valid_21627611
  var valid_21627612 = query.getOrDefault("OptionsToRemove")
  valid_21627612 = validateParameter(valid_21627612, JArray, required = false,
                                   default = nil)
  if valid_21627612 != nil:
    section.add "OptionsToRemove", valid_21627612
  var valid_21627613 = query.getOrDefault("PlatformArn")
  valid_21627613 = validateParameter(valid_21627613, JString, required = false,
                                   default = nil)
  if valid_21627613 != nil:
    section.add "PlatformArn", valid_21627613
  var valid_21627614 = query.getOrDefault("EnvironmentName")
  valid_21627614 = validateParameter(valid_21627614, JString, required = false,
                                   default = nil)
  if valid_21627614 != nil:
    section.add "EnvironmentName", valid_21627614
  var valid_21627615 = query.getOrDefault("Action")
  valid_21627615 = validateParameter(valid_21627615, JString, required = true,
                                   default = newJString("UpdateEnvironment"))
  if valid_21627615 != nil:
    section.add "Action", valid_21627615
  var valid_21627616 = query.getOrDefault("EnvironmentId")
  valid_21627616 = validateParameter(valid_21627616, JString, required = false,
                                   default = nil)
  if valid_21627616 != nil:
    section.add "EnvironmentId", valid_21627616
  var valid_21627617 = query.getOrDefault("Tier.Version")
  valid_21627617 = validateParameter(valid_21627617, JString, required = false,
                                   default = nil)
  if valid_21627617 != nil:
    section.add "Tier.Version", valid_21627617
  var valid_21627618 = query.getOrDefault("SolutionStackName")
  valid_21627618 = validateParameter(valid_21627618, JString, required = false,
                                   default = nil)
  if valid_21627618 != nil:
    section.add "SolutionStackName", valid_21627618
  var valid_21627619 = query.getOrDefault("TemplateName")
  valid_21627619 = validateParameter(valid_21627619, JString, required = false,
                                   default = nil)
  if valid_21627619 != nil:
    section.add "TemplateName", valid_21627619
  var valid_21627620 = query.getOrDefault("GroupName")
  valid_21627620 = validateParameter(valid_21627620, JString, required = false,
                                   default = nil)
  if valid_21627620 != nil:
    section.add "GroupName", valid_21627620
  var valid_21627621 = query.getOrDefault("OptionSettings")
  valid_21627621 = validateParameter(valid_21627621, JArray, required = false,
                                   default = nil)
  if valid_21627621 != nil:
    section.add "OptionSettings", valid_21627621
  var valid_21627622 = query.getOrDefault("Tier.Type")
  valid_21627622 = validateParameter(valid_21627622, JString, required = false,
                                   default = nil)
  if valid_21627622 != nil:
    section.add "Tier.Type", valid_21627622
  var valid_21627623 = query.getOrDefault("Version")
  valid_21627623 = validateParameter(valid_21627623, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21627623 != nil:
    section.add "Version", valid_21627623
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627624 = header.getOrDefault("X-Amz-Date")
  valid_21627624 = validateParameter(valid_21627624, JString, required = false,
                                   default = nil)
  if valid_21627624 != nil:
    section.add "X-Amz-Date", valid_21627624
  var valid_21627625 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627625 = validateParameter(valid_21627625, JString, required = false,
                                   default = nil)
  if valid_21627625 != nil:
    section.add "X-Amz-Security-Token", valid_21627625
  var valid_21627626 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627626 = validateParameter(valid_21627626, JString, required = false,
                                   default = nil)
  if valid_21627626 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627626
  var valid_21627627 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627627 = validateParameter(valid_21627627, JString, required = false,
                                   default = nil)
  if valid_21627627 != nil:
    section.add "X-Amz-Algorithm", valid_21627627
  var valid_21627628 = header.getOrDefault("X-Amz-Signature")
  valid_21627628 = validateParameter(valid_21627628, JString, required = false,
                                   default = nil)
  if valid_21627628 != nil:
    section.add "X-Amz-Signature", valid_21627628
  var valid_21627629 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627629 = validateParameter(valid_21627629, JString, required = false,
                                   default = nil)
  if valid_21627629 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627629
  var valid_21627630 = header.getOrDefault("X-Amz-Credential")
  valid_21627630 = validateParameter(valid_21627630, JString, required = false,
                                   default = nil)
  if valid_21627630 != nil:
    section.add "X-Amz-Credential", valid_21627630
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627631: Call_GetUpdateEnvironment_21627605; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates the environment description, deploys a new application version, updates the configuration settings to an entirely new configuration template, or updates select configuration option values in the running environment.</p> <p> Attempting to update both the release and configuration is not allowed and AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. </p> <p> When updating the configuration settings to a new template or individual settings, a draft configuration is created and <a>DescribeConfigurationSettings</a> for this environment returns two setting descriptions with different <code>DeploymentStatus</code> values. </p>
  ## 
  let valid = call_21627631.validator(path, query, header, formData, body, _)
  let scheme = call_21627631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627631.makeUrl(scheme.get, call_21627631.host, call_21627631.base,
                               call_21627631.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627631, uri, valid, _)

proc call*(call_21627632: Call_GetUpdateEnvironment_21627605;
          TierName: string = ""; VersionLabel: string = "";
          ApplicationName: string = ""; Description: string = "";
          OptionsToRemove: JsonNode = nil; PlatformArn: string = "";
          EnvironmentName: string = ""; Action: string = "UpdateEnvironment";
          EnvironmentId: string = ""; TierVersion: string = "";
          SolutionStackName: string = ""; TemplateName: string = "";
          GroupName: string = ""; OptionSettings: JsonNode = nil; TierType: string = "";
          Version: string = "2010-12-01"): Recallable =
  ## getUpdateEnvironment
  ## <p>Updates the environment description, deploys a new application version, updates the configuration settings to an entirely new configuration template, or updates select configuration option values in the running environment.</p> <p> Attempting to update both the release and configuration is not allowed and AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. </p> <p> When updating the configuration settings to a new template or individual settings, a draft configuration is created and <a>DescribeConfigurationSettings</a> for this environment returns two setting descriptions with different <code>DeploymentStatus</code> values. </p>
  ##   TierName: string
  ##           : Describes the properties of an environment tier
  ## <p>The name of this environment tier.</p> <p>Valid values:</p> <ul> <li> <p>For <i>Web server tier</i> – <code>WebServer</code> </p> </li> <li> <p>For <i>Worker tier</i> – <code>Worker</code> </p> </li> </ul>
  ##   VersionLabel: string
  ##               : If this parameter is specified, AWS Elastic Beanstalk deploys the named application version to the environment. If no such application version is found, returns an <code>InvalidParameterValue</code> error. 
  ##   ApplicationName: string
  ##                  : The name of the application with which the environment is associated.
  ##   Description: string
  ##              : If this parameter is specified, AWS Elastic Beanstalk updates the description of this environment.
  ##   OptionsToRemove: JArray
  ##                  : A list of custom user-defined configuration options to remove from the configuration set for this environment.
  ##   PlatformArn: string
  ##              : The ARN of the platform, if used.
  ##   EnvironmentName: string
  ##                  : <p>The name of the environment to update. If no environment with this name exists, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. </p> <p>Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Action: string (required)
  ##   EnvironmentId: string
  ##                : <p>The ID of the environment to update.</p> <p>If no environment with this ID exists, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error.</p> <p>Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   TierVersion: string
  ##              : Describes the properties of an environment tier
  ## <p>The version of this environment tier. When you don't set a value to it, Elastic Beanstalk uses the latest compatible worker tier version.</p> <note> <p>This member is deprecated. Any specific version that you set may become out of date. We recommend leaving it unspecified.</p> </note>
  ##   SolutionStackName: string
  ##                    : This specifies the platform version that the environment will run after the environment is updated.
  ##   TemplateName: string
  ##               : If this parameter is specified, AWS Elastic Beanstalk deploys this configuration template to the environment. If no such configuration template is found, AWS Elastic Beanstalk returns an <code>InvalidParameterValue</code> error. 
  ##   GroupName: string
  ##            : The name of the group to which the target environment belongs. Specify a group name only if the environment's name is specified in an environment manifest and not with the environment name or environment ID parameters. See <a 
  ## href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-cfg-manifest.html">Environment Manifest (env.yaml)</a> for details.
  ##   OptionSettings: JArray
  ##                 : If specified, AWS Elastic Beanstalk updates the configuration set associated with the running environment and sets the specified configuration options to the requested value.
  ##   TierType: string
  ##           : Describes the properties of an environment tier
  ## <p>The type of this environment tier.</p> <p>Valid values:</p> <ul> <li> <p>For <i>Web server tier</i> – <code>Standard</code> </p> </li> <li> <p>For <i>Worker tier</i> – <code>SQS/HTTP</code> </p> </li> </ul>
  ##   Version: string (required)
  var query_21627633 = newJObject()
  add(query_21627633, "Tier.Name", newJString(TierName))
  add(query_21627633, "VersionLabel", newJString(VersionLabel))
  add(query_21627633, "ApplicationName", newJString(ApplicationName))
  add(query_21627633, "Description", newJString(Description))
  if OptionsToRemove != nil:
    query_21627633.add "OptionsToRemove", OptionsToRemove
  add(query_21627633, "PlatformArn", newJString(PlatformArn))
  add(query_21627633, "EnvironmentName", newJString(EnvironmentName))
  add(query_21627633, "Action", newJString(Action))
  add(query_21627633, "EnvironmentId", newJString(EnvironmentId))
  add(query_21627633, "Tier.Version", newJString(TierVersion))
  add(query_21627633, "SolutionStackName", newJString(SolutionStackName))
  add(query_21627633, "TemplateName", newJString(TemplateName))
  add(query_21627633, "GroupName", newJString(GroupName))
  if OptionSettings != nil:
    query_21627633.add "OptionSettings", OptionSettings
  add(query_21627633, "Tier.Type", newJString(TierType))
  add(query_21627633, "Version", newJString(Version))
  result = call_21627632.call(nil, query_21627633, nil, nil, nil)

var getUpdateEnvironment* = Call_GetUpdateEnvironment_21627605(
    name: "getUpdateEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateEnvironment",
    validator: validate_GetUpdateEnvironment_21627606, base: "/",
    makeUrl: url_GetUpdateEnvironment_21627607,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateTagsForResource_21627682 = ref object of OpenApiRestCall_21625437
proc url_PostUpdateTagsForResource_21627684(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateTagsForResource_21627683(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21627685 = query.getOrDefault("Action")
  valid_21627685 = validateParameter(valid_21627685, JString, required = true, default = newJString(
      "UpdateTagsForResource"))
  if valid_21627685 != nil:
    section.add "Action", valid_21627685
  var valid_21627686 = query.getOrDefault("Version")
  valid_21627686 = validateParameter(valid_21627686, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21627686 != nil:
    section.add "Version", valid_21627686
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627687 = header.getOrDefault("X-Amz-Date")
  valid_21627687 = validateParameter(valid_21627687, JString, required = false,
                                   default = nil)
  if valid_21627687 != nil:
    section.add "X-Amz-Date", valid_21627687
  var valid_21627688 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627688 = validateParameter(valid_21627688, JString, required = false,
                                   default = nil)
  if valid_21627688 != nil:
    section.add "X-Amz-Security-Token", valid_21627688
  var valid_21627689 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627689 = validateParameter(valid_21627689, JString, required = false,
                                   default = nil)
  if valid_21627689 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627689
  var valid_21627690 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627690 = validateParameter(valid_21627690, JString, required = false,
                                   default = nil)
  if valid_21627690 != nil:
    section.add "X-Amz-Algorithm", valid_21627690
  var valid_21627691 = header.getOrDefault("X-Amz-Signature")
  valid_21627691 = validateParameter(valid_21627691, JString, required = false,
                                   default = nil)
  if valid_21627691 != nil:
    section.add "X-Amz-Signature", valid_21627691
  var valid_21627692 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627692 = validateParameter(valid_21627692, JString, required = false,
                                   default = nil)
  if valid_21627692 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627692
  var valid_21627693 = header.getOrDefault("X-Amz-Credential")
  valid_21627693 = validateParameter(valid_21627693, JString, required = false,
                                   default = nil)
  if valid_21627693 != nil:
    section.add "X-Amz-Credential", valid_21627693
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagsToAdd: JArray
  ##            : <p>A list of tags to add or update.</p> <p>If a key of an existing tag is added, the tag's value is updated.</p>
  ##   TagsToRemove: JArray
  ##               : <p>A list of tag keys to remove.</p> <p>If a tag key doesn't exist, it is silently ignored.</p>
  ##   ResourceArn: JString (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce to be updated.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  section = newJObject()
  var valid_21627694 = formData.getOrDefault("TagsToAdd")
  valid_21627694 = validateParameter(valid_21627694, JArray, required = false,
                                   default = nil)
  if valid_21627694 != nil:
    section.add "TagsToAdd", valid_21627694
  var valid_21627695 = formData.getOrDefault("TagsToRemove")
  valid_21627695 = validateParameter(valid_21627695, JArray, required = false,
                                   default = nil)
  if valid_21627695 != nil:
    section.add "TagsToRemove", valid_21627695
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArn` field"
  var valid_21627696 = formData.getOrDefault("ResourceArn")
  valid_21627696 = validateParameter(valid_21627696, JString, required = true,
                                   default = nil)
  if valid_21627696 != nil:
    section.add "ResourceArn", valid_21627696
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627697: Call_PostUpdateTagsForResource_21627682;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Update the list of tags applied to an AWS Elastic Beanstalk resource. Two lists can be passed: <code>TagsToAdd</code> for tags to add or update, and <code>TagsToRemove</code>.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p> <p>If you create a custom IAM user policy to control permission to this operation, specify one of the following two virtual actions (or both) instead of the API operation name:</p> <dl> <dt>elasticbeanstalk:AddTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tags to add in the <code>TagsToAdd</code> parameter.</p> </dd> <dt>elasticbeanstalk:RemoveTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tag keys to remove in the <code>TagsToRemove</code> parameter.</p> </dd> </dl> <p>For details about creating a custom user policy, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/AWSHowTo.iam.managed-policies.html#AWSHowTo.iam.policies">Creating a Custom User Policy</a>.</p>
  ## 
  let valid = call_21627697.validator(path, query, header, formData, body, _)
  let scheme = call_21627697.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627697.makeUrl(scheme.get, call_21627697.host, call_21627697.base,
                               call_21627697.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627697, uri, valid, _)

proc call*(call_21627698: Call_PostUpdateTagsForResource_21627682;
          ResourceArn: string; TagsToAdd: JsonNode = nil;
          TagsToRemove: JsonNode = nil; Action: string = "UpdateTagsForResource";
          Version: string = "2010-12-01"): Recallable =
  ## postUpdateTagsForResource
  ## <p>Update the list of tags applied to an AWS Elastic Beanstalk resource. Two lists can be passed: <code>TagsToAdd</code> for tags to add or update, and <code>TagsToRemove</code>.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p> <p>If you create a custom IAM user policy to control permission to this operation, specify one of the following two virtual actions (or both) instead of the API operation name:</p> <dl> <dt>elasticbeanstalk:AddTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tags to add in the <code>TagsToAdd</code> parameter.</p> </dd> <dt>elasticbeanstalk:RemoveTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tag keys to remove in the <code>TagsToRemove</code> parameter.</p> </dd> </dl> <p>For details about creating a custom user policy, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/AWSHowTo.iam.managed-policies.html#AWSHowTo.iam.policies">Creating a Custom User Policy</a>.</p>
  ##   TagsToAdd: JArray
  ##            : <p>A list of tags to add or update.</p> <p>If a key of an existing tag is added, the tag's value is updated.</p>
  ##   TagsToRemove: JArray
  ##               : <p>A list of tag keys to remove.</p> <p>If a tag key doesn't exist, it is silently ignored.</p>
  ##   Action: string (required)
  ##   ResourceArn: string (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce to be updated.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  ##   Version: string (required)
  var query_21627699 = newJObject()
  var formData_21627700 = newJObject()
  if TagsToAdd != nil:
    formData_21627700.add "TagsToAdd", TagsToAdd
  if TagsToRemove != nil:
    formData_21627700.add "TagsToRemove", TagsToRemove
  add(query_21627699, "Action", newJString(Action))
  add(formData_21627700, "ResourceArn", newJString(ResourceArn))
  add(query_21627699, "Version", newJString(Version))
  result = call_21627698.call(nil, query_21627699, nil, formData_21627700, nil)

var postUpdateTagsForResource* = Call_PostUpdateTagsForResource_21627682(
    name: "postUpdateTagsForResource", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateTagsForResource",
    validator: validate_PostUpdateTagsForResource_21627683, base: "/",
    makeUrl: url_PostUpdateTagsForResource_21627684,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateTagsForResource_21627664 = ref object of OpenApiRestCall_21625437
proc url_GetUpdateTagsForResource_21627666(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateTagsForResource_21627665(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Update the list of tags applied to an AWS Elastic Beanstalk resource. Two lists can be passed: <code>TagsToAdd</code> for tags to add or update, and <code>TagsToRemove</code>.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p> <p>If you create a custom IAM user policy to control permission to this operation, specify one of the following two virtual actions (or both) instead of the API operation name:</p> <dl> <dt>elasticbeanstalk:AddTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tags to add in the <code>TagsToAdd</code> parameter.</p> </dd> <dt>elasticbeanstalk:RemoveTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tag keys to remove in the <code>TagsToRemove</code> parameter.</p> </dd> </dl> <p>For details about creating a custom user policy, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/AWSHowTo.iam.managed-policies.html#AWSHowTo.iam.policies">Creating a Custom User Policy</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ResourceArn: JString (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce to be updated.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  ##   Action: JString (required)
  ##   TagsToAdd: JArray
  ##            : <p>A list of tags to add or update.</p> <p>If a key of an existing tag is added, the tag's value is updated.</p>
  ##   Version: JString (required)
  ##   TagsToRemove: JArray
  ##               : <p>A list of tag keys to remove.</p> <p>If a tag key doesn't exist, it is silently ignored.</p>
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ResourceArn` field"
  var valid_21627667 = query.getOrDefault("ResourceArn")
  valid_21627667 = validateParameter(valid_21627667, JString, required = true,
                                   default = nil)
  if valid_21627667 != nil:
    section.add "ResourceArn", valid_21627667
  var valid_21627668 = query.getOrDefault("Action")
  valid_21627668 = validateParameter(valid_21627668, JString, required = true, default = newJString(
      "UpdateTagsForResource"))
  if valid_21627668 != nil:
    section.add "Action", valid_21627668
  var valid_21627669 = query.getOrDefault("TagsToAdd")
  valid_21627669 = validateParameter(valid_21627669, JArray, required = false,
                                   default = nil)
  if valid_21627669 != nil:
    section.add "TagsToAdd", valid_21627669
  var valid_21627670 = query.getOrDefault("Version")
  valid_21627670 = validateParameter(valid_21627670, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21627670 != nil:
    section.add "Version", valid_21627670
  var valid_21627671 = query.getOrDefault("TagsToRemove")
  valid_21627671 = validateParameter(valid_21627671, JArray, required = false,
                                   default = nil)
  if valid_21627671 != nil:
    section.add "TagsToRemove", valid_21627671
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627672 = header.getOrDefault("X-Amz-Date")
  valid_21627672 = validateParameter(valid_21627672, JString, required = false,
                                   default = nil)
  if valid_21627672 != nil:
    section.add "X-Amz-Date", valid_21627672
  var valid_21627673 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627673 = validateParameter(valid_21627673, JString, required = false,
                                   default = nil)
  if valid_21627673 != nil:
    section.add "X-Amz-Security-Token", valid_21627673
  var valid_21627674 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627674 = validateParameter(valid_21627674, JString, required = false,
                                   default = nil)
  if valid_21627674 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627674
  var valid_21627675 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627675 = validateParameter(valid_21627675, JString, required = false,
                                   default = nil)
  if valid_21627675 != nil:
    section.add "X-Amz-Algorithm", valid_21627675
  var valid_21627676 = header.getOrDefault("X-Amz-Signature")
  valid_21627676 = validateParameter(valid_21627676, JString, required = false,
                                   default = nil)
  if valid_21627676 != nil:
    section.add "X-Amz-Signature", valid_21627676
  var valid_21627677 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627677 = validateParameter(valid_21627677, JString, required = false,
                                   default = nil)
  if valid_21627677 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627677
  var valid_21627678 = header.getOrDefault("X-Amz-Credential")
  valid_21627678 = validateParameter(valid_21627678, JString, required = false,
                                   default = nil)
  if valid_21627678 != nil:
    section.add "X-Amz-Credential", valid_21627678
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627679: Call_GetUpdateTagsForResource_21627664;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Update the list of tags applied to an AWS Elastic Beanstalk resource. Two lists can be passed: <code>TagsToAdd</code> for tags to add or update, and <code>TagsToRemove</code>.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p> <p>If you create a custom IAM user policy to control permission to this operation, specify one of the following two virtual actions (or both) instead of the API operation name:</p> <dl> <dt>elasticbeanstalk:AddTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tags to add in the <code>TagsToAdd</code> parameter.</p> </dd> <dt>elasticbeanstalk:RemoveTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tag keys to remove in the <code>TagsToRemove</code> parameter.</p> </dd> </dl> <p>For details about creating a custom user policy, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/AWSHowTo.iam.managed-policies.html#AWSHowTo.iam.policies">Creating a Custom User Policy</a>.</p>
  ## 
  let valid = call_21627679.validator(path, query, header, formData, body, _)
  let scheme = call_21627679.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627679.makeUrl(scheme.get, call_21627679.host, call_21627679.base,
                               call_21627679.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627679, uri, valid, _)

proc call*(call_21627680: Call_GetUpdateTagsForResource_21627664;
          ResourceArn: string; Action: string = "UpdateTagsForResource";
          TagsToAdd: JsonNode = nil; Version: string = "2010-12-01";
          TagsToRemove: JsonNode = nil): Recallable =
  ## getUpdateTagsForResource
  ## <p>Update the list of tags applied to an AWS Elastic Beanstalk resource. Two lists can be passed: <code>TagsToAdd</code> for tags to add or update, and <code>TagsToRemove</code>.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p> <p>If you create a custom IAM user policy to control permission to this operation, specify one of the following two virtual actions (or both) instead of the API operation name:</p> <dl> <dt>elasticbeanstalk:AddTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tags to add in the <code>TagsToAdd</code> parameter.</p> </dd> <dt>elasticbeanstalk:RemoveTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tag keys to remove in the <code>TagsToRemove</code> parameter.</p> </dd> </dl> <p>For details about creating a custom user policy, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/AWSHowTo.iam.managed-policies.html#AWSHowTo.iam.policies">Creating a Custom User Policy</a>.</p>
  ##   ResourceArn: string (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce to be updated.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  ##   Action: string (required)
  ##   TagsToAdd: JArray
  ##            : <p>A list of tags to add or update.</p> <p>If a key of an existing tag is added, the tag's value is updated.</p>
  ##   Version: string (required)
  ##   TagsToRemove: JArray
  ##               : <p>A list of tag keys to remove.</p> <p>If a tag key doesn't exist, it is silently ignored.</p>
  var query_21627681 = newJObject()
  add(query_21627681, "ResourceArn", newJString(ResourceArn))
  add(query_21627681, "Action", newJString(Action))
  if TagsToAdd != nil:
    query_21627681.add "TagsToAdd", TagsToAdd
  add(query_21627681, "Version", newJString(Version))
  if TagsToRemove != nil:
    query_21627681.add "TagsToRemove", TagsToRemove
  result = call_21627680.call(nil, query_21627681, nil, nil, nil)

var getUpdateTagsForResource* = Call_GetUpdateTagsForResource_21627664(
    name: "getUpdateTagsForResource", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateTagsForResource",
    validator: validate_GetUpdateTagsForResource_21627665, base: "/",
    makeUrl: url_GetUpdateTagsForResource_21627666,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostValidateConfigurationSettings_21627720 = ref object of OpenApiRestCall_21625437
proc url_PostValidateConfigurationSettings_21627722(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostValidateConfigurationSettings_21627721(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21627723 = query.getOrDefault("Action")
  valid_21627723 = validateParameter(valid_21627723, JString, required = true, default = newJString(
      "ValidateConfigurationSettings"))
  if valid_21627723 != nil:
    section.add "Action", valid_21627723
  var valid_21627724 = query.getOrDefault("Version")
  valid_21627724 = validateParameter(valid_21627724, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21627724 != nil:
    section.add "Version", valid_21627724
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627725 = header.getOrDefault("X-Amz-Date")
  valid_21627725 = validateParameter(valid_21627725, JString, required = false,
                                   default = nil)
  if valid_21627725 != nil:
    section.add "X-Amz-Date", valid_21627725
  var valid_21627726 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627726 = validateParameter(valid_21627726, JString, required = false,
                                   default = nil)
  if valid_21627726 != nil:
    section.add "X-Amz-Security-Token", valid_21627726
  var valid_21627727 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627727 = validateParameter(valid_21627727, JString, required = false,
                                   default = nil)
  if valid_21627727 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627727
  var valid_21627728 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627728 = validateParameter(valid_21627728, JString, required = false,
                                   default = nil)
  if valid_21627728 != nil:
    section.add "X-Amz-Algorithm", valid_21627728
  var valid_21627729 = header.getOrDefault("X-Amz-Signature")
  valid_21627729 = validateParameter(valid_21627729, JString, required = false,
                                   default = nil)
  if valid_21627729 != nil:
    section.add "X-Amz-Signature", valid_21627729
  var valid_21627730 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627730 = validateParameter(valid_21627730, JString, required = false,
                                   default = nil)
  if valid_21627730 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627730
  var valid_21627731 = header.getOrDefault("X-Amz-Credential")
  valid_21627731 = validateParameter(valid_21627731, JString, required = false,
                                   default = nil)
  if valid_21627731 != nil:
    section.add "X-Amz-Credential", valid_21627731
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionSettings: JArray (required)
  ##                 : A list of the options and desired values to evaluate.
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to validate the settings against.</p> <p>Condition: You cannot specify both this and a configuration template name.</p>
  ##   ApplicationName: JString (required)
  ##                  : The name of the application that the configuration template or environment belongs to.
  ##   TemplateName: JString
  ##               : <p>The name of the configuration template to validate the settings against.</p> <p>Condition: You cannot specify both this and an environment name.</p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `OptionSettings` field"
  var valid_21627732 = formData.getOrDefault("OptionSettings")
  valid_21627732 = validateParameter(valid_21627732, JArray, required = true,
                                   default = nil)
  if valid_21627732 != nil:
    section.add "OptionSettings", valid_21627732
  var valid_21627733 = formData.getOrDefault("EnvironmentName")
  valid_21627733 = validateParameter(valid_21627733, JString, required = false,
                                   default = nil)
  if valid_21627733 != nil:
    section.add "EnvironmentName", valid_21627733
  var valid_21627734 = formData.getOrDefault("ApplicationName")
  valid_21627734 = validateParameter(valid_21627734, JString, required = true,
                                   default = nil)
  if valid_21627734 != nil:
    section.add "ApplicationName", valid_21627734
  var valid_21627735 = formData.getOrDefault("TemplateName")
  valid_21627735 = validateParameter(valid_21627735, JString, required = false,
                                   default = nil)
  if valid_21627735 != nil:
    section.add "TemplateName", valid_21627735
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627736: Call_PostValidateConfigurationSettings_21627720;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Takes a set of configuration settings and either a configuration template or environment, and determines whether those values are valid.</p> <p>This action returns a list of messages indicating any errors or warnings associated with the selection of option values.</p>
  ## 
  let valid = call_21627736.validator(path, query, header, formData, body, _)
  let scheme = call_21627736.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627736.makeUrl(scheme.get, call_21627736.host, call_21627736.base,
                               call_21627736.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627736, uri, valid, _)

proc call*(call_21627737: Call_PostValidateConfigurationSettings_21627720;
          OptionSettings: JsonNode; ApplicationName: string;
          EnvironmentName: string = "";
          Action: string = "ValidateConfigurationSettings";
          TemplateName: string = ""; Version: string = "2010-12-01"): Recallable =
  ## postValidateConfigurationSettings
  ## <p>Takes a set of configuration settings and either a configuration template or environment, and determines whether those values are valid.</p> <p>This action returns a list of messages indicating any errors or warnings associated with the selection of option values.</p>
  ##   OptionSettings: JArray (required)
  ##                 : A list of the options and desired values to evaluate.
  ##   EnvironmentName: string
  ##                  : <p>The name of the environment to validate the settings against.</p> <p>Condition: You cannot specify both this and a configuration template name.</p>
  ##   Action: string (required)
  ##   ApplicationName: string (required)
  ##                  : The name of the application that the configuration template or environment belongs to.
  ##   TemplateName: string
  ##               : <p>The name of the configuration template to validate the settings against.</p> <p>Condition: You cannot specify both this and an environment name.</p>
  ##   Version: string (required)
  var query_21627738 = newJObject()
  var formData_21627739 = newJObject()
  if OptionSettings != nil:
    formData_21627739.add "OptionSettings", OptionSettings
  add(formData_21627739, "EnvironmentName", newJString(EnvironmentName))
  add(query_21627738, "Action", newJString(Action))
  add(formData_21627739, "ApplicationName", newJString(ApplicationName))
  add(formData_21627739, "TemplateName", newJString(TemplateName))
  add(query_21627738, "Version", newJString(Version))
  result = call_21627737.call(nil, query_21627738, nil, formData_21627739, nil)

var postValidateConfigurationSettings* = Call_PostValidateConfigurationSettings_21627720(
    name: "postValidateConfigurationSettings", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ValidateConfigurationSettings",
    validator: validate_PostValidateConfigurationSettings_21627721, base: "/",
    makeUrl: url_PostValidateConfigurationSettings_21627722,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetValidateConfigurationSettings_21627701 = ref object of OpenApiRestCall_21625437
proc url_GetValidateConfigurationSettings_21627703(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetValidateConfigurationSettings_21627702(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Takes a set of configuration settings and either a configuration template or environment, and determines whether those values are valid.</p> <p>This action returns a list of messages indicating any errors or warnings associated with the selection of option values.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ApplicationName: JString (required)
  ##                  : The name of the application that the configuration template or environment belongs to.
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to validate the settings against.</p> <p>Condition: You cannot specify both this and a configuration template name.</p>
  ##   Action: JString (required)
  ##   TemplateName: JString
  ##               : <p>The name of the configuration template to validate the settings against.</p> <p>Condition: You cannot specify both this and an environment name.</p>
  ##   OptionSettings: JArray (required)
  ##                 : A list of the options and desired values to evaluate.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_21627704 = query.getOrDefault("ApplicationName")
  valid_21627704 = validateParameter(valid_21627704, JString, required = true,
                                   default = nil)
  if valid_21627704 != nil:
    section.add "ApplicationName", valid_21627704
  var valid_21627705 = query.getOrDefault("EnvironmentName")
  valid_21627705 = validateParameter(valid_21627705, JString, required = false,
                                   default = nil)
  if valid_21627705 != nil:
    section.add "EnvironmentName", valid_21627705
  var valid_21627706 = query.getOrDefault("Action")
  valid_21627706 = validateParameter(valid_21627706, JString, required = true, default = newJString(
      "ValidateConfigurationSettings"))
  if valid_21627706 != nil:
    section.add "Action", valid_21627706
  var valid_21627707 = query.getOrDefault("TemplateName")
  valid_21627707 = validateParameter(valid_21627707, JString, required = false,
                                   default = nil)
  if valid_21627707 != nil:
    section.add "TemplateName", valid_21627707
  var valid_21627708 = query.getOrDefault("OptionSettings")
  valid_21627708 = validateParameter(valid_21627708, JArray, required = true,
                                   default = nil)
  if valid_21627708 != nil:
    section.add "OptionSettings", valid_21627708
  var valid_21627709 = query.getOrDefault("Version")
  valid_21627709 = validateParameter(valid_21627709, JString, required = true,
                                   default = newJString("2010-12-01"))
  if valid_21627709 != nil:
    section.add "Version", valid_21627709
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_21627710 = header.getOrDefault("X-Amz-Date")
  valid_21627710 = validateParameter(valid_21627710, JString, required = false,
                                   default = nil)
  if valid_21627710 != nil:
    section.add "X-Amz-Date", valid_21627710
  var valid_21627711 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627711 = validateParameter(valid_21627711, JString, required = false,
                                   default = nil)
  if valid_21627711 != nil:
    section.add "X-Amz-Security-Token", valid_21627711
  var valid_21627712 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627712 = validateParameter(valid_21627712, JString, required = false,
                                   default = nil)
  if valid_21627712 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627712
  var valid_21627713 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627713 = validateParameter(valid_21627713, JString, required = false,
                                   default = nil)
  if valid_21627713 != nil:
    section.add "X-Amz-Algorithm", valid_21627713
  var valid_21627714 = header.getOrDefault("X-Amz-Signature")
  valid_21627714 = validateParameter(valid_21627714, JString, required = false,
                                   default = nil)
  if valid_21627714 != nil:
    section.add "X-Amz-Signature", valid_21627714
  var valid_21627715 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627715 = validateParameter(valid_21627715, JString, required = false,
                                   default = nil)
  if valid_21627715 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627715
  var valid_21627716 = header.getOrDefault("X-Amz-Credential")
  valid_21627716 = validateParameter(valid_21627716, JString, required = false,
                                   default = nil)
  if valid_21627716 != nil:
    section.add "X-Amz-Credential", valid_21627716
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627717: Call_GetValidateConfigurationSettings_21627701;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Takes a set of configuration settings and either a configuration template or environment, and determines whether those values are valid.</p> <p>This action returns a list of messages indicating any errors or warnings associated with the selection of option values.</p>
  ## 
  let valid = call_21627717.validator(path, query, header, formData, body, _)
  let scheme = call_21627717.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627717.makeUrl(scheme.get, call_21627717.host, call_21627717.base,
                               call_21627717.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627717, uri, valid, _)

proc call*(call_21627718: Call_GetValidateConfigurationSettings_21627701;
          ApplicationName: string; OptionSettings: JsonNode;
          EnvironmentName: string = "";
          Action: string = "ValidateConfigurationSettings";
          TemplateName: string = ""; Version: string = "2010-12-01"): Recallable =
  ## getValidateConfigurationSettings
  ## <p>Takes a set of configuration settings and either a configuration template or environment, and determines whether those values are valid.</p> <p>This action returns a list of messages indicating any errors or warnings associated with the selection of option values.</p>
  ##   ApplicationName: string (required)
  ##                  : The name of the application that the configuration template or environment belongs to.
  ##   EnvironmentName: string
  ##                  : <p>The name of the environment to validate the settings against.</p> <p>Condition: You cannot specify both this and a configuration template name.</p>
  ##   Action: string (required)
  ##   TemplateName: string
  ##               : <p>The name of the configuration template to validate the settings against.</p> <p>Condition: You cannot specify both this and an environment name.</p>
  ##   OptionSettings: JArray (required)
  ##                 : A list of the options and desired values to evaluate.
  ##   Version: string (required)
  var query_21627719 = newJObject()
  add(query_21627719, "ApplicationName", newJString(ApplicationName))
  add(query_21627719, "EnvironmentName", newJString(EnvironmentName))
  add(query_21627719, "Action", newJString(Action))
  add(query_21627719, "TemplateName", newJString(TemplateName))
  if OptionSettings != nil:
    query_21627719.add "OptionSettings", OptionSettings
  add(query_21627719, "Version", newJString(Version))
  result = call_21627718.call(nil, query_21627719, nil, nil, nil)

var getValidateConfigurationSettings* = Call_GetValidateConfigurationSettings_21627701(
    name: "getValidateConfigurationSettings", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ValidateConfigurationSettings",
    validator: validate_GetValidateConfigurationSettings_21627702, base: "/",
    makeUrl: url_GetValidateConfigurationSettings_21627703,
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
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
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
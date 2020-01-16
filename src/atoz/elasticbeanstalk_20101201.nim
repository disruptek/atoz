
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

  OpenApiRestCall_605590 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605590](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605590): Option[Scheme] {.used.} =
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
  Call_PostAbortEnvironmentUpdate_606200 = ref object of OpenApiRestCall_605590
proc url_PostAbortEnvironmentUpdate_606202(protocol: Scheme; host: string;
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

proc validate_PostAbortEnvironmentUpdate_606201(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606203 = query.getOrDefault("Action")
  valid_606203 = validateParameter(valid_606203, JString, required = true,
                                 default = newJString("AbortEnvironmentUpdate"))
  if valid_606203 != nil:
    section.add "Action", valid_606203
  var valid_606204 = query.getOrDefault("Version")
  valid_606204 = validateParameter(valid_606204, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_606204 != nil:
    section.add "Version", valid_606204
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
  var valid_606205 = header.getOrDefault("X-Amz-Signature")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-Signature", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-Content-Sha256", valid_606206
  var valid_606207 = header.getOrDefault("X-Amz-Date")
  valid_606207 = validateParameter(valid_606207, JString, required = false,
                                 default = nil)
  if valid_606207 != nil:
    section.add "X-Amz-Date", valid_606207
  var valid_606208 = header.getOrDefault("X-Amz-Credential")
  valid_606208 = validateParameter(valid_606208, JString, required = false,
                                 default = nil)
  if valid_606208 != nil:
    section.add "X-Amz-Credential", valid_606208
  var valid_606209 = header.getOrDefault("X-Amz-Security-Token")
  valid_606209 = validateParameter(valid_606209, JString, required = false,
                                 default = nil)
  if valid_606209 != nil:
    section.add "X-Amz-Security-Token", valid_606209
  var valid_606210 = header.getOrDefault("X-Amz-Algorithm")
  valid_606210 = validateParameter(valid_606210, JString, required = false,
                                 default = nil)
  if valid_606210 != nil:
    section.add "X-Amz-Algorithm", valid_606210
  var valid_606211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606211 = validateParameter(valid_606211, JString, required = false,
                                 default = nil)
  if valid_606211 != nil:
    section.add "X-Amz-SignedHeaders", valid_606211
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString
  ##                  : This specifies the name of the environment with the in-progress update that you want to cancel.
  ##   EnvironmentId: JString
  ##                : This specifies the ID of the environment with the in-progress update that you want to cancel.
  section = newJObject()
  var valid_606212 = formData.getOrDefault("EnvironmentName")
  valid_606212 = validateParameter(valid_606212, JString, required = false,
                                 default = nil)
  if valid_606212 != nil:
    section.add "EnvironmentName", valid_606212
  var valid_606213 = formData.getOrDefault("EnvironmentId")
  valid_606213 = validateParameter(valid_606213, JString, required = false,
                                 default = nil)
  if valid_606213 != nil:
    section.add "EnvironmentId", valid_606213
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606214: Call_PostAbortEnvironmentUpdate_606200; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels in-progress environment configuration update or application version deployment.
  ## 
  let valid = call_606214.validator(path, query, header, formData, body)
  let scheme = call_606214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606214.url(scheme.get, call_606214.host, call_606214.base,
                         call_606214.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606214, url, valid)

proc call*(call_606215: Call_PostAbortEnvironmentUpdate_606200;
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
  var query_606216 = newJObject()
  var formData_606217 = newJObject()
  add(formData_606217, "EnvironmentName", newJString(EnvironmentName))
  add(query_606216, "Action", newJString(Action))
  add(formData_606217, "EnvironmentId", newJString(EnvironmentId))
  add(query_606216, "Version", newJString(Version))
  result = call_606215.call(nil, query_606216, nil, formData_606217, nil)

var postAbortEnvironmentUpdate* = Call_PostAbortEnvironmentUpdate_606200(
    name: "postAbortEnvironmentUpdate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=AbortEnvironmentUpdate",
    validator: validate_PostAbortEnvironmentUpdate_606201, base: "/",
    url: url_PostAbortEnvironmentUpdate_606202,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAbortEnvironmentUpdate_605928 = ref object of OpenApiRestCall_605590
proc url_GetAbortEnvironmentUpdate_605930(protocol: Scheme; host: string;
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

proc validate_GetAbortEnvironmentUpdate_605929(path: JsonNode; query: JsonNode;
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
  var valid_606042 = query.getOrDefault("EnvironmentName")
  valid_606042 = validateParameter(valid_606042, JString, required = false,
                                 default = nil)
  if valid_606042 != nil:
    section.add "EnvironmentName", valid_606042
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606056 = query.getOrDefault("Action")
  valid_606056 = validateParameter(valid_606056, JString, required = true,
                                 default = newJString("AbortEnvironmentUpdate"))
  if valid_606056 != nil:
    section.add "Action", valid_606056
  var valid_606057 = query.getOrDefault("Version")
  valid_606057 = validateParameter(valid_606057, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_606057 != nil:
    section.add "Version", valid_606057
  var valid_606058 = query.getOrDefault("EnvironmentId")
  valid_606058 = validateParameter(valid_606058, JString, required = false,
                                 default = nil)
  if valid_606058 != nil:
    section.add "EnvironmentId", valid_606058
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
  var valid_606059 = header.getOrDefault("X-Amz-Signature")
  valid_606059 = validateParameter(valid_606059, JString, required = false,
                                 default = nil)
  if valid_606059 != nil:
    section.add "X-Amz-Signature", valid_606059
  var valid_606060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606060 = validateParameter(valid_606060, JString, required = false,
                                 default = nil)
  if valid_606060 != nil:
    section.add "X-Amz-Content-Sha256", valid_606060
  var valid_606061 = header.getOrDefault("X-Amz-Date")
  valid_606061 = validateParameter(valid_606061, JString, required = false,
                                 default = nil)
  if valid_606061 != nil:
    section.add "X-Amz-Date", valid_606061
  var valid_606062 = header.getOrDefault("X-Amz-Credential")
  valid_606062 = validateParameter(valid_606062, JString, required = false,
                                 default = nil)
  if valid_606062 != nil:
    section.add "X-Amz-Credential", valid_606062
  var valid_606063 = header.getOrDefault("X-Amz-Security-Token")
  valid_606063 = validateParameter(valid_606063, JString, required = false,
                                 default = nil)
  if valid_606063 != nil:
    section.add "X-Amz-Security-Token", valid_606063
  var valid_606064 = header.getOrDefault("X-Amz-Algorithm")
  valid_606064 = validateParameter(valid_606064, JString, required = false,
                                 default = nil)
  if valid_606064 != nil:
    section.add "X-Amz-Algorithm", valid_606064
  var valid_606065 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606065 = validateParameter(valid_606065, JString, required = false,
                                 default = nil)
  if valid_606065 != nil:
    section.add "X-Amz-SignedHeaders", valid_606065
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606088: Call_GetAbortEnvironmentUpdate_605928; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels in-progress environment configuration update or application version deployment.
  ## 
  let valid = call_606088.validator(path, query, header, formData, body)
  let scheme = call_606088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606088.url(scheme.get, call_606088.host, call_606088.base,
                         call_606088.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606088, url, valid)

proc call*(call_606159: Call_GetAbortEnvironmentUpdate_605928;
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
  var query_606160 = newJObject()
  add(query_606160, "EnvironmentName", newJString(EnvironmentName))
  add(query_606160, "Action", newJString(Action))
  add(query_606160, "Version", newJString(Version))
  add(query_606160, "EnvironmentId", newJString(EnvironmentId))
  result = call_606159.call(nil, query_606160, nil, nil, nil)

var getAbortEnvironmentUpdate* = Call_GetAbortEnvironmentUpdate_605928(
    name: "getAbortEnvironmentUpdate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=AbortEnvironmentUpdate",
    validator: validate_GetAbortEnvironmentUpdate_605929, base: "/",
    url: url_GetAbortEnvironmentUpdate_605930,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostApplyEnvironmentManagedAction_606236 = ref object of OpenApiRestCall_605590
proc url_PostApplyEnvironmentManagedAction_606238(protocol: Scheme; host: string;
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

proc validate_PostApplyEnvironmentManagedAction_606237(path: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606239 = query.getOrDefault("Action")
  valid_606239 = validateParameter(valid_606239, JString, required = true, default = newJString(
      "ApplyEnvironmentManagedAction"))
  if valid_606239 != nil:
    section.add "Action", valid_606239
  var valid_606240 = query.getOrDefault("Version")
  valid_606240 = validateParameter(valid_606240, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_606240 != nil:
    section.add "Version", valid_606240
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
  var valid_606241 = header.getOrDefault("X-Amz-Signature")
  valid_606241 = validateParameter(valid_606241, JString, required = false,
                                 default = nil)
  if valid_606241 != nil:
    section.add "X-Amz-Signature", valid_606241
  var valid_606242 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606242 = validateParameter(valid_606242, JString, required = false,
                                 default = nil)
  if valid_606242 != nil:
    section.add "X-Amz-Content-Sha256", valid_606242
  var valid_606243 = header.getOrDefault("X-Amz-Date")
  valid_606243 = validateParameter(valid_606243, JString, required = false,
                                 default = nil)
  if valid_606243 != nil:
    section.add "X-Amz-Date", valid_606243
  var valid_606244 = header.getOrDefault("X-Amz-Credential")
  valid_606244 = validateParameter(valid_606244, JString, required = false,
                                 default = nil)
  if valid_606244 != nil:
    section.add "X-Amz-Credential", valid_606244
  var valid_606245 = header.getOrDefault("X-Amz-Security-Token")
  valid_606245 = validateParameter(valid_606245, JString, required = false,
                                 default = nil)
  if valid_606245 != nil:
    section.add "X-Amz-Security-Token", valid_606245
  var valid_606246 = header.getOrDefault("X-Amz-Algorithm")
  valid_606246 = validateParameter(valid_606246, JString, required = false,
                                 default = nil)
  if valid_606246 != nil:
    section.add "X-Amz-Algorithm", valid_606246
  var valid_606247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606247 = validateParameter(valid_606247, JString, required = false,
                                 default = nil)
  if valid_606247 != nil:
    section.add "X-Amz-SignedHeaders", valid_606247
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
  var valid_606248 = formData.getOrDefault("ActionId")
  valid_606248 = validateParameter(valid_606248, JString, required = true,
                                 default = nil)
  if valid_606248 != nil:
    section.add "ActionId", valid_606248
  var valid_606249 = formData.getOrDefault("EnvironmentName")
  valid_606249 = validateParameter(valid_606249, JString, required = false,
                                 default = nil)
  if valid_606249 != nil:
    section.add "EnvironmentName", valid_606249
  var valid_606250 = formData.getOrDefault("EnvironmentId")
  valid_606250 = validateParameter(valid_606250, JString, required = false,
                                 default = nil)
  if valid_606250 != nil:
    section.add "EnvironmentId", valid_606250
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606251: Call_PostApplyEnvironmentManagedAction_606236;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Applies a scheduled managed action immediately. A managed action can be applied only if its status is <code>Scheduled</code>. Get the status and action ID of a managed action with <a>DescribeEnvironmentManagedActions</a>.
  ## 
  let valid = call_606251.validator(path, query, header, formData, body)
  let scheme = call_606251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606251.url(scheme.get, call_606251.host, call_606251.base,
                         call_606251.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606251, url, valid)

proc call*(call_606252: Call_PostApplyEnvironmentManagedAction_606236;
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
  var query_606253 = newJObject()
  var formData_606254 = newJObject()
  add(formData_606254, "ActionId", newJString(ActionId))
  add(formData_606254, "EnvironmentName", newJString(EnvironmentName))
  add(query_606253, "Action", newJString(Action))
  add(formData_606254, "EnvironmentId", newJString(EnvironmentId))
  add(query_606253, "Version", newJString(Version))
  result = call_606252.call(nil, query_606253, nil, formData_606254, nil)

var postApplyEnvironmentManagedAction* = Call_PostApplyEnvironmentManagedAction_606236(
    name: "postApplyEnvironmentManagedAction", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ApplyEnvironmentManagedAction",
    validator: validate_PostApplyEnvironmentManagedAction_606237, base: "/",
    url: url_PostApplyEnvironmentManagedAction_606238,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplyEnvironmentManagedAction_606218 = ref object of OpenApiRestCall_605590
proc url_GetApplyEnvironmentManagedAction_606220(protocol: Scheme; host: string;
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

proc validate_GetApplyEnvironmentManagedAction_606219(path: JsonNode;
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
  var valid_606221 = query.getOrDefault("ActionId")
  valid_606221 = validateParameter(valid_606221, JString, required = true,
                                 default = nil)
  if valid_606221 != nil:
    section.add "ActionId", valid_606221
  var valid_606222 = query.getOrDefault("EnvironmentName")
  valid_606222 = validateParameter(valid_606222, JString, required = false,
                                 default = nil)
  if valid_606222 != nil:
    section.add "EnvironmentName", valid_606222
  var valid_606223 = query.getOrDefault("Action")
  valid_606223 = validateParameter(valid_606223, JString, required = true, default = newJString(
      "ApplyEnvironmentManagedAction"))
  if valid_606223 != nil:
    section.add "Action", valid_606223
  var valid_606224 = query.getOrDefault("Version")
  valid_606224 = validateParameter(valid_606224, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_606224 != nil:
    section.add "Version", valid_606224
  var valid_606225 = query.getOrDefault("EnvironmentId")
  valid_606225 = validateParameter(valid_606225, JString, required = false,
                                 default = nil)
  if valid_606225 != nil:
    section.add "EnvironmentId", valid_606225
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
  var valid_606226 = header.getOrDefault("X-Amz-Signature")
  valid_606226 = validateParameter(valid_606226, JString, required = false,
                                 default = nil)
  if valid_606226 != nil:
    section.add "X-Amz-Signature", valid_606226
  var valid_606227 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606227 = validateParameter(valid_606227, JString, required = false,
                                 default = nil)
  if valid_606227 != nil:
    section.add "X-Amz-Content-Sha256", valid_606227
  var valid_606228 = header.getOrDefault("X-Amz-Date")
  valid_606228 = validateParameter(valid_606228, JString, required = false,
                                 default = nil)
  if valid_606228 != nil:
    section.add "X-Amz-Date", valid_606228
  var valid_606229 = header.getOrDefault("X-Amz-Credential")
  valid_606229 = validateParameter(valid_606229, JString, required = false,
                                 default = nil)
  if valid_606229 != nil:
    section.add "X-Amz-Credential", valid_606229
  var valid_606230 = header.getOrDefault("X-Amz-Security-Token")
  valid_606230 = validateParameter(valid_606230, JString, required = false,
                                 default = nil)
  if valid_606230 != nil:
    section.add "X-Amz-Security-Token", valid_606230
  var valid_606231 = header.getOrDefault("X-Amz-Algorithm")
  valid_606231 = validateParameter(valid_606231, JString, required = false,
                                 default = nil)
  if valid_606231 != nil:
    section.add "X-Amz-Algorithm", valid_606231
  var valid_606232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606232 = validateParameter(valid_606232, JString, required = false,
                                 default = nil)
  if valid_606232 != nil:
    section.add "X-Amz-SignedHeaders", valid_606232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606233: Call_GetApplyEnvironmentManagedAction_606218;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Applies a scheduled managed action immediately. A managed action can be applied only if its status is <code>Scheduled</code>. Get the status and action ID of a managed action with <a>DescribeEnvironmentManagedActions</a>.
  ## 
  let valid = call_606233.validator(path, query, header, formData, body)
  let scheme = call_606233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606233.url(scheme.get, call_606233.host, call_606233.base,
                         call_606233.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606233, url, valid)

proc call*(call_606234: Call_GetApplyEnvironmentManagedAction_606218;
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
  var query_606235 = newJObject()
  add(query_606235, "ActionId", newJString(ActionId))
  add(query_606235, "EnvironmentName", newJString(EnvironmentName))
  add(query_606235, "Action", newJString(Action))
  add(query_606235, "Version", newJString(Version))
  add(query_606235, "EnvironmentId", newJString(EnvironmentId))
  result = call_606234.call(nil, query_606235, nil, nil, nil)

var getApplyEnvironmentManagedAction* = Call_GetApplyEnvironmentManagedAction_606218(
    name: "getApplyEnvironmentManagedAction", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ApplyEnvironmentManagedAction",
    validator: validate_GetApplyEnvironmentManagedAction_606219, base: "/",
    url: url_GetApplyEnvironmentManagedAction_606220,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCheckDNSAvailability_606271 = ref object of OpenApiRestCall_605590
proc url_PostCheckDNSAvailability_606273(protocol: Scheme; host: string;
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

proc validate_PostCheckDNSAvailability_606272(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606274 = query.getOrDefault("Action")
  valid_606274 = validateParameter(valid_606274, JString, required = true,
                                 default = newJString("CheckDNSAvailability"))
  if valid_606274 != nil:
    section.add "Action", valid_606274
  var valid_606275 = query.getOrDefault("Version")
  valid_606275 = validateParameter(valid_606275, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_606275 != nil:
    section.add "Version", valid_606275
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
  var valid_606276 = header.getOrDefault("X-Amz-Signature")
  valid_606276 = validateParameter(valid_606276, JString, required = false,
                                 default = nil)
  if valid_606276 != nil:
    section.add "X-Amz-Signature", valid_606276
  var valid_606277 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606277 = validateParameter(valid_606277, JString, required = false,
                                 default = nil)
  if valid_606277 != nil:
    section.add "X-Amz-Content-Sha256", valid_606277
  var valid_606278 = header.getOrDefault("X-Amz-Date")
  valid_606278 = validateParameter(valid_606278, JString, required = false,
                                 default = nil)
  if valid_606278 != nil:
    section.add "X-Amz-Date", valid_606278
  var valid_606279 = header.getOrDefault("X-Amz-Credential")
  valid_606279 = validateParameter(valid_606279, JString, required = false,
                                 default = nil)
  if valid_606279 != nil:
    section.add "X-Amz-Credential", valid_606279
  var valid_606280 = header.getOrDefault("X-Amz-Security-Token")
  valid_606280 = validateParameter(valid_606280, JString, required = false,
                                 default = nil)
  if valid_606280 != nil:
    section.add "X-Amz-Security-Token", valid_606280
  var valid_606281 = header.getOrDefault("X-Amz-Algorithm")
  valid_606281 = validateParameter(valid_606281, JString, required = false,
                                 default = nil)
  if valid_606281 != nil:
    section.add "X-Amz-Algorithm", valid_606281
  var valid_606282 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606282 = validateParameter(valid_606282, JString, required = false,
                                 default = nil)
  if valid_606282 != nil:
    section.add "X-Amz-SignedHeaders", valid_606282
  result.add "header", section
  ## parameters in `formData` object:
  ##   CNAMEPrefix: JString (required)
  ##              : The prefix used when this CNAME is reserved.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `CNAMEPrefix` field"
  var valid_606283 = formData.getOrDefault("CNAMEPrefix")
  valid_606283 = validateParameter(valid_606283, JString, required = true,
                                 default = nil)
  if valid_606283 != nil:
    section.add "CNAMEPrefix", valid_606283
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606284: Call_PostCheckDNSAvailability_606271; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Checks if the specified CNAME is available.
  ## 
  let valid = call_606284.validator(path, query, header, formData, body)
  let scheme = call_606284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606284.url(scheme.get, call_606284.host, call_606284.base,
                         call_606284.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606284, url, valid)

proc call*(call_606285: Call_PostCheckDNSAvailability_606271; CNAMEPrefix: string;
          Action: string = "CheckDNSAvailability"; Version: string = "2010-12-01"): Recallable =
  ## postCheckDNSAvailability
  ## Checks if the specified CNAME is available.
  ##   CNAMEPrefix: string (required)
  ##              : The prefix used when this CNAME is reserved.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606286 = newJObject()
  var formData_606287 = newJObject()
  add(formData_606287, "CNAMEPrefix", newJString(CNAMEPrefix))
  add(query_606286, "Action", newJString(Action))
  add(query_606286, "Version", newJString(Version))
  result = call_606285.call(nil, query_606286, nil, formData_606287, nil)

var postCheckDNSAvailability* = Call_PostCheckDNSAvailability_606271(
    name: "postCheckDNSAvailability", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CheckDNSAvailability",
    validator: validate_PostCheckDNSAvailability_606272, base: "/",
    url: url_PostCheckDNSAvailability_606273, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCheckDNSAvailability_606255 = ref object of OpenApiRestCall_605590
proc url_GetCheckDNSAvailability_606257(protocol: Scheme; host: string; base: string;
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

proc validate_GetCheckDNSAvailability_606256(path: JsonNode; query: JsonNode;
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
  var valid_606258 = query.getOrDefault("CNAMEPrefix")
  valid_606258 = validateParameter(valid_606258, JString, required = true,
                                 default = nil)
  if valid_606258 != nil:
    section.add "CNAMEPrefix", valid_606258
  var valid_606259 = query.getOrDefault("Action")
  valid_606259 = validateParameter(valid_606259, JString, required = true,
                                 default = newJString("CheckDNSAvailability"))
  if valid_606259 != nil:
    section.add "Action", valid_606259
  var valid_606260 = query.getOrDefault("Version")
  valid_606260 = validateParameter(valid_606260, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_606260 != nil:
    section.add "Version", valid_606260
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
  var valid_606261 = header.getOrDefault("X-Amz-Signature")
  valid_606261 = validateParameter(valid_606261, JString, required = false,
                                 default = nil)
  if valid_606261 != nil:
    section.add "X-Amz-Signature", valid_606261
  var valid_606262 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606262 = validateParameter(valid_606262, JString, required = false,
                                 default = nil)
  if valid_606262 != nil:
    section.add "X-Amz-Content-Sha256", valid_606262
  var valid_606263 = header.getOrDefault("X-Amz-Date")
  valid_606263 = validateParameter(valid_606263, JString, required = false,
                                 default = nil)
  if valid_606263 != nil:
    section.add "X-Amz-Date", valid_606263
  var valid_606264 = header.getOrDefault("X-Amz-Credential")
  valid_606264 = validateParameter(valid_606264, JString, required = false,
                                 default = nil)
  if valid_606264 != nil:
    section.add "X-Amz-Credential", valid_606264
  var valid_606265 = header.getOrDefault("X-Amz-Security-Token")
  valid_606265 = validateParameter(valid_606265, JString, required = false,
                                 default = nil)
  if valid_606265 != nil:
    section.add "X-Amz-Security-Token", valid_606265
  var valid_606266 = header.getOrDefault("X-Amz-Algorithm")
  valid_606266 = validateParameter(valid_606266, JString, required = false,
                                 default = nil)
  if valid_606266 != nil:
    section.add "X-Amz-Algorithm", valid_606266
  var valid_606267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606267 = validateParameter(valid_606267, JString, required = false,
                                 default = nil)
  if valid_606267 != nil:
    section.add "X-Amz-SignedHeaders", valid_606267
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606268: Call_GetCheckDNSAvailability_606255; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Checks if the specified CNAME is available.
  ## 
  let valid = call_606268.validator(path, query, header, formData, body)
  let scheme = call_606268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606268.url(scheme.get, call_606268.host, call_606268.base,
                         call_606268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606268, url, valid)

proc call*(call_606269: Call_GetCheckDNSAvailability_606255; CNAMEPrefix: string;
          Action: string = "CheckDNSAvailability"; Version: string = "2010-12-01"): Recallable =
  ## getCheckDNSAvailability
  ## Checks if the specified CNAME is available.
  ##   CNAMEPrefix: string (required)
  ##              : The prefix used when this CNAME is reserved.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606270 = newJObject()
  add(query_606270, "CNAMEPrefix", newJString(CNAMEPrefix))
  add(query_606270, "Action", newJString(Action))
  add(query_606270, "Version", newJString(Version))
  result = call_606269.call(nil, query_606270, nil, nil, nil)

var getCheckDNSAvailability* = Call_GetCheckDNSAvailability_606255(
    name: "getCheckDNSAvailability", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CheckDNSAvailability",
    validator: validate_GetCheckDNSAvailability_606256, base: "/",
    url: url_GetCheckDNSAvailability_606257, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostComposeEnvironments_606306 = ref object of OpenApiRestCall_605590
proc url_PostComposeEnvironments_606308(protocol: Scheme; host: string; base: string;
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

proc validate_PostComposeEnvironments_606307(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606309 = query.getOrDefault("Action")
  valid_606309 = validateParameter(valid_606309, JString, required = true,
                                 default = newJString("ComposeEnvironments"))
  if valid_606309 != nil:
    section.add "Action", valid_606309
  var valid_606310 = query.getOrDefault("Version")
  valid_606310 = validateParameter(valid_606310, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_606310 != nil:
    section.add "Version", valid_606310
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
  var valid_606311 = header.getOrDefault("X-Amz-Signature")
  valid_606311 = validateParameter(valid_606311, JString, required = false,
                                 default = nil)
  if valid_606311 != nil:
    section.add "X-Amz-Signature", valid_606311
  var valid_606312 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606312 = validateParameter(valid_606312, JString, required = false,
                                 default = nil)
  if valid_606312 != nil:
    section.add "X-Amz-Content-Sha256", valid_606312
  var valid_606313 = header.getOrDefault("X-Amz-Date")
  valid_606313 = validateParameter(valid_606313, JString, required = false,
                                 default = nil)
  if valid_606313 != nil:
    section.add "X-Amz-Date", valid_606313
  var valid_606314 = header.getOrDefault("X-Amz-Credential")
  valid_606314 = validateParameter(valid_606314, JString, required = false,
                                 default = nil)
  if valid_606314 != nil:
    section.add "X-Amz-Credential", valid_606314
  var valid_606315 = header.getOrDefault("X-Amz-Security-Token")
  valid_606315 = validateParameter(valid_606315, JString, required = false,
                                 default = nil)
  if valid_606315 != nil:
    section.add "X-Amz-Security-Token", valid_606315
  var valid_606316 = header.getOrDefault("X-Amz-Algorithm")
  valid_606316 = validateParameter(valid_606316, JString, required = false,
                                 default = nil)
  if valid_606316 != nil:
    section.add "X-Amz-Algorithm", valid_606316
  var valid_606317 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606317 = validateParameter(valid_606317, JString, required = false,
                                 default = nil)
  if valid_606317 != nil:
    section.add "X-Amz-SignedHeaders", valid_606317
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
  var valid_606318 = formData.getOrDefault("GroupName")
  valid_606318 = validateParameter(valid_606318, JString, required = false,
                                 default = nil)
  if valid_606318 != nil:
    section.add "GroupName", valid_606318
  var valid_606319 = formData.getOrDefault("ApplicationName")
  valid_606319 = validateParameter(valid_606319, JString, required = false,
                                 default = nil)
  if valid_606319 != nil:
    section.add "ApplicationName", valid_606319
  var valid_606320 = formData.getOrDefault("VersionLabels")
  valid_606320 = validateParameter(valid_606320, JArray, required = false,
                                 default = nil)
  if valid_606320 != nil:
    section.add "VersionLabels", valid_606320
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606321: Call_PostComposeEnvironments_606306; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create or update a group of environments that each run a separate component of a single application. Takes a list of version labels that specify application source bundles for each of the environments to create or update. The name of each environment and other required information must be included in the source bundles in an environment manifest named <code>env.yaml</code>. See <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-mgmt-compose.html">Compose Environments</a> for details.
  ## 
  let valid = call_606321.validator(path, query, header, formData, body)
  let scheme = call_606321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606321.url(scheme.get, call_606321.host, call_606321.base,
                         call_606321.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606321, url, valid)

proc call*(call_606322: Call_PostComposeEnvironments_606306;
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
  var query_606323 = newJObject()
  var formData_606324 = newJObject()
  add(formData_606324, "GroupName", newJString(GroupName))
  add(formData_606324, "ApplicationName", newJString(ApplicationName))
  if VersionLabels != nil:
    formData_606324.add "VersionLabels", VersionLabels
  add(query_606323, "Action", newJString(Action))
  add(query_606323, "Version", newJString(Version))
  result = call_606322.call(nil, query_606323, nil, formData_606324, nil)

var postComposeEnvironments* = Call_PostComposeEnvironments_606306(
    name: "postComposeEnvironments", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ComposeEnvironments",
    validator: validate_PostComposeEnvironments_606307, base: "/",
    url: url_PostComposeEnvironments_606308, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetComposeEnvironments_606288 = ref object of OpenApiRestCall_605590
proc url_GetComposeEnvironments_606290(protocol: Scheme; host: string; base: string;
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

proc validate_GetComposeEnvironments_606289(path: JsonNode; query: JsonNode;
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
  var valid_606291 = query.getOrDefault("ApplicationName")
  valid_606291 = validateParameter(valid_606291, JString, required = false,
                                 default = nil)
  if valid_606291 != nil:
    section.add "ApplicationName", valid_606291
  var valid_606292 = query.getOrDefault("GroupName")
  valid_606292 = validateParameter(valid_606292, JString, required = false,
                                 default = nil)
  if valid_606292 != nil:
    section.add "GroupName", valid_606292
  var valid_606293 = query.getOrDefault("VersionLabels")
  valid_606293 = validateParameter(valid_606293, JArray, required = false,
                                 default = nil)
  if valid_606293 != nil:
    section.add "VersionLabels", valid_606293
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606294 = query.getOrDefault("Action")
  valid_606294 = validateParameter(valid_606294, JString, required = true,
                                 default = newJString("ComposeEnvironments"))
  if valid_606294 != nil:
    section.add "Action", valid_606294
  var valid_606295 = query.getOrDefault("Version")
  valid_606295 = validateParameter(valid_606295, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_606295 != nil:
    section.add "Version", valid_606295
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
  var valid_606296 = header.getOrDefault("X-Amz-Signature")
  valid_606296 = validateParameter(valid_606296, JString, required = false,
                                 default = nil)
  if valid_606296 != nil:
    section.add "X-Amz-Signature", valid_606296
  var valid_606297 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606297 = validateParameter(valid_606297, JString, required = false,
                                 default = nil)
  if valid_606297 != nil:
    section.add "X-Amz-Content-Sha256", valid_606297
  var valid_606298 = header.getOrDefault("X-Amz-Date")
  valid_606298 = validateParameter(valid_606298, JString, required = false,
                                 default = nil)
  if valid_606298 != nil:
    section.add "X-Amz-Date", valid_606298
  var valid_606299 = header.getOrDefault("X-Amz-Credential")
  valid_606299 = validateParameter(valid_606299, JString, required = false,
                                 default = nil)
  if valid_606299 != nil:
    section.add "X-Amz-Credential", valid_606299
  var valid_606300 = header.getOrDefault("X-Amz-Security-Token")
  valid_606300 = validateParameter(valid_606300, JString, required = false,
                                 default = nil)
  if valid_606300 != nil:
    section.add "X-Amz-Security-Token", valid_606300
  var valid_606301 = header.getOrDefault("X-Amz-Algorithm")
  valid_606301 = validateParameter(valid_606301, JString, required = false,
                                 default = nil)
  if valid_606301 != nil:
    section.add "X-Amz-Algorithm", valid_606301
  var valid_606302 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606302 = validateParameter(valid_606302, JString, required = false,
                                 default = nil)
  if valid_606302 != nil:
    section.add "X-Amz-SignedHeaders", valid_606302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606303: Call_GetComposeEnvironments_606288; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create or update a group of environments that each run a separate component of a single application. Takes a list of version labels that specify application source bundles for each of the environments to create or update. The name of each environment and other required information must be included in the source bundles in an environment manifest named <code>env.yaml</code>. See <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-mgmt-compose.html">Compose Environments</a> for details.
  ## 
  let valid = call_606303.validator(path, query, header, formData, body)
  let scheme = call_606303.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606303.url(scheme.get, call_606303.host, call_606303.base,
                         call_606303.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606303, url, valid)

proc call*(call_606304: Call_GetComposeEnvironments_606288;
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
  var query_606305 = newJObject()
  add(query_606305, "ApplicationName", newJString(ApplicationName))
  add(query_606305, "GroupName", newJString(GroupName))
  if VersionLabels != nil:
    query_606305.add "VersionLabels", VersionLabels
  add(query_606305, "Action", newJString(Action))
  add(query_606305, "Version", newJString(Version))
  result = call_606304.call(nil, query_606305, nil, nil, nil)

var getComposeEnvironments* = Call_GetComposeEnvironments_606288(
    name: "getComposeEnvironments", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ComposeEnvironments",
    validator: validate_GetComposeEnvironments_606289, base: "/",
    url: url_GetComposeEnvironments_606290, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateApplication_606345 = ref object of OpenApiRestCall_605590
proc url_PostCreateApplication_606347(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateApplication_606346(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606348 = query.getOrDefault("Action")
  valid_606348 = validateParameter(valid_606348, JString, required = true,
                                 default = newJString("CreateApplication"))
  if valid_606348 != nil:
    section.add "Action", valid_606348
  var valid_606349 = query.getOrDefault("Version")
  valid_606349 = validateParameter(valid_606349, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_606349 != nil:
    section.add "Version", valid_606349
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
  var valid_606350 = header.getOrDefault("X-Amz-Signature")
  valid_606350 = validateParameter(valid_606350, JString, required = false,
                                 default = nil)
  if valid_606350 != nil:
    section.add "X-Amz-Signature", valid_606350
  var valid_606351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606351 = validateParameter(valid_606351, JString, required = false,
                                 default = nil)
  if valid_606351 != nil:
    section.add "X-Amz-Content-Sha256", valid_606351
  var valid_606352 = header.getOrDefault("X-Amz-Date")
  valid_606352 = validateParameter(valid_606352, JString, required = false,
                                 default = nil)
  if valid_606352 != nil:
    section.add "X-Amz-Date", valid_606352
  var valid_606353 = header.getOrDefault("X-Amz-Credential")
  valid_606353 = validateParameter(valid_606353, JString, required = false,
                                 default = nil)
  if valid_606353 != nil:
    section.add "X-Amz-Credential", valid_606353
  var valid_606354 = header.getOrDefault("X-Amz-Security-Token")
  valid_606354 = validateParameter(valid_606354, JString, required = false,
                                 default = nil)
  if valid_606354 != nil:
    section.add "X-Amz-Security-Token", valid_606354
  var valid_606355 = header.getOrDefault("X-Amz-Algorithm")
  valid_606355 = validateParameter(valid_606355, JString, required = false,
                                 default = nil)
  if valid_606355 != nil:
    section.add "X-Amz-Algorithm", valid_606355
  var valid_606356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606356 = validateParameter(valid_606356, JString, required = false,
                                 default = nil)
  if valid_606356 != nil:
    section.add "X-Amz-SignedHeaders", valid_606356
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
  var valid_606357 = formData.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_606357 = validateParameter(valid_606357, JString, required = false,
                                 default = nil)
  if valid_606357 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_606357
  var valid_606358 = formData.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_606358 = validateParameter(valid_606358, JString, required = false,
                                 default = nil)
  if valid_606358 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_606358
  var valid_606359 = formData.getOrDefault("Description")
  valid_606359 = validateParameter(valid_606359, JString, required = false,
                                 default = nil)
  if valid_606359 != nil:
    section.add "Description", valid_606359
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_606360 = formData.getOrDefault("ApplicationName")
  valid_606360 = validateParameter(valid_606360, JString, required = true,
                                 default = nil)
  if valid_606360 != nil:
    section.add "ApplicationName", valid_606360
  var valid_606361 = formData.getOrDefault("Tags")
  valid_606361 = validateParameter(valid_606361, JArray, required = false,
                                 default = nil)
  if valid_606361 != nil:
    section.add "Tags", valid_606361
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606362: Call_PostCreateApplication_606345; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates an application that has one configuration template named <code>default</code> and no application versions. 
  ## 
  let valid = call_606362.validator(path, query, header, formData, body)
  let scheme = call_606362.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606362.url(scheme.get, call_606362.host, call_606362.base,
                         call_606362.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606362, url, valid)

proc call*(call_606363: Call_PostCreateApplication_606345; ApplicationName: string;
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
  var query_606364 = newJObject()
  var formData_606365 = newJObject()
  add(formData_606365, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  add(formData_606365, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  add(formData_606365, "Description", newJString(Description))
  add(formData_606365, "ApplicationName", newJString(ApplicationName))
  add(query_606364, "Action", newJString(Action))
  if Tags != nil:
    formData_606365.add "Tags", Tags
  add(query_606364, "Version", newJString(Version))
  result = call_606363.call(nil, query_606364, nil, formData_606365, nil)

var postCreateApplication* = Call_PostCreateApplication_606345(
    name: "postCreateApplication", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateApplication",
    validator: validate_PostCreateApplication_606346, base: "/",
    url: url_PostCreateApplication_606347, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateApplication_606325 = ref object of OpenApiRestCall_605590
proc url_GetCreateApplication_606327(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateApplication_606326(path: JsonNode; query: JsonNode;
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
  var valid_606328 = query.getOrDefault("ApplicationName")
  valid_606328 = validateParameter(valid_606328, JString, required = true,
                                 default = nil)
  if valid_606328 != nil:
    section.add "ApplicationName", valid_606328
  var valid_606329 = query.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_606329 = validateParameter(valid_606329, JString, required = false,
                                 default = nil)
  if valid_606329 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_606329
  var valid_606330 = query.getOrDefault("Tags")
  valid_606330 = validateParameter(valid_606330, JArray, required = false,
                                 default = nil)
  if valid_606330 != nil:
    section.add "Tags", valid_606330
  var valid_606331 = query.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_606331 = validateParameter(valid_606331, JString, required = false,
                                 default = nil)
  if valid_606331 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_606331
  var valid_606332 = query.getOrDefault("Action")
  valid_606332 = validateParameter(valid_606332, JString, required = true,
                                 default = newJString("CreateApplication"))
  if valid_606332 != nil:
    section.add "Action", valid_606332
  var valid_606333 = query.getOrDefault("Description")
  valid_606333 = validateParameter(valid_606333, JString, required = false,
                                 default = nil)
  if valid_606333 != nil:
    section.add "Description", valid_606333
  var valid_606334 = query.getOrDefault("Version")
  valid_606334 = validateParameter(valid_606334, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_606334 != nil:
    section.add "Version", valid_606334
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
  var valid_606335 = header.getOrDefault("X-Amz-Signature")
  valid_606335 = validateParameter(valid_606335, JString, required = false,
                                 default = nil)
  if valid_606335 != nil:
    section.add "X-Amz-Signature", valid_606335
  var valid_606336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606336 = validateParameter(valid_606336, JString, required = false,
                                 default = nil)
  if valid_606336 != nil:
    section.add "X-Amz-Content-Sha256", valid_606336
  var valid_606337 = header.getOrDefault("X-Amz-Date")
  valid_606337 = validateParameter(valid_606337, JString, required = false,
                                 default = nil)
  if valid_606337 != nil:
    section.add "X-Amz-Date", valid_606337
  var valid_606338 = header.getOrDefault("X-Amz-Credential")
  valid_606338 = validateParameter(valid_606338, JString, required = false,
                                 default = nil)
  if valid_606338 != nil:
    section.add "X-Amz-Credential", valid_606338
  var valid_606339 = header.getOrDefault("X-Amz-Security-Token")
  valid_606339 = validateParameter(valid_606339, JString, required = false,
                                 default = nil)
  if valid_606339 != nil:
    section.add "X-Amz-Security-Token", valid_606339
  var valid_606340 = header.getOrDefault("X-Amz-Algorithm")
  valid_606340 = validateParameter(valid_606340, JString, required = false,
                                 default = nil)
  if valid_606340 != nil:
    section.add "X-Amz-Algorithm", valid_606340
  var valid_606341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606341 = validateParameter(valid_606341, JString, required = false,
                                 default = nil)
  if valid_606341 != nil:
    section.add "X-Amz-SignedHeaders", valid_606341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606342: Call_GetCreateApplication_606325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates an application that has one configuration template named <code>default</code> and no application versions. 
  ## 
  let valid = call_606342.validator(path, query, header, formData, body)
  let scheme = call_606342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606342.url(scheme.get, call_606342.host, call_606342.base,
                         call_606342.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606342, url, valid)

proc call*(call_606343: Call_GetCreateApplication_606325; ApplicationName: string;
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
  var query_606344 = newJObject()
  add(query_606344, "ApplicationName", newJString(ApplicationName))
  add(query_606344, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  if Tags != nil:
    query_606344.add "Tags", Tags
  add(query_606344, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  add(query_606344, "Action", newJString(Action))
  add(query_606344, "Description", newJString(Description))
  add(query_606344, "Version", newJString(Version))
  result = call_606343.call(nil, query_606344, nil, nil, nil)

var getCreateApplication* = Call_GetCreateApplication_606325(
    name: "getCreateApplication", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateApplication",
    validator: validate_GetCreateApplication_606326, base: "/",
    url: url_GetCreateApplication_606327, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateApplicationVersion_606397 = ref object of OpenApiRestCall_605590
proc url_PostCreateApplicationVersion_606399(protocol: Scheme; host: string;
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

proc validate_PostCreateApplicationVersion_606398(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606400 = query.getOrDefault("Action")
  valid_606400 = validateParameter(valid_606400, JString, required = true, default = newJString(
      "CreateApplicationVersion"))
  if valid_606400 != nil:
    section.add "Action", valid_606400
  var valid_606401 = query.getOrDefault("Version")
  valid_606401 = validateParameter(valid_606401, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_606401 != nil:
    section.add "Version", valid_606401
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
  var valid_606402 = header.getOrDefault("X-Amz-Signature")
  valid_606402 = validateParameter(valid_606402, JString, required = false,
                                 default = nil)
  if valid_606402 != nil:
    section.add "X-Amz-Signature", valid_606402
  var valid_606403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606403 = validateParameter(valid_606403, JString, required = false,
                                 default = nil)
  if valid_606403 != nil:
    section.add "X-Amz-Content-Sha256", valid_606403
  var valid_606404 = header.getOrDefault("X-Amz-Date")
  valid_606404 = validateParameter(valid_606404, JString, required = false,
                                 default = nil)
  if valid_606404 != nil:
    section.add "X-Amz-Date", valid_606404
  var valid_606405 = header.getOrDefault("X-Amz-Credential")
  valid_606405 = validateParameter(valid_606405, JString, required = false,
                                 default = nil)
  if valid_606405 != nil:
    section.add "X-Amz-Credential", valid_606405
  var valid_606406 = header.getOrDefault("X-Amz-Security-Token")
  valid_606406 = validateParameter(valid_606406, JString, required = false,
                                 default = nil)
  if valid_606406 != nil:
    section.add "X-Amz-Security-Token", valid_606406
  var valid_606407 = header.getOrDefault("X-Amz-Algorithm")
  valid_606407 = validateParameter(valid_606407, JString, required = false,
                                 default = nil)
  if valid_606407 != nil:
    section.add "X-Amz-Algorithm", valid_606407
  var valid_606408 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606408 = validateParameter(valid_606408, JString, required = false,
                                 default = nil)
  if valid_606408 != nil:
    section.add "X-Amz-SignedHeaders", valid_606408
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
  var valid_606409 = formData.getOrDefault("BuildConfiguration.ComputeType")
  valid_606409 = validateParameter(valid_606409, JString, required = false,
                                 default = nil)
  if valid_606409 != nil:
    section.add "BuildConfiguration.ComputeType", valid_606409
  var valid_606410 = formData.getOrDefault("SourceBundle.S3Key")
  valid_606410 = validateParameter(valid_606410, JString, required = false,
                                 default = nil)
  if valid_606410 != nil:
    section.add "SourceBundle.S3Key", valid_606410
  var valid_606411 = formData.getOrDefault("Process")
  valid_606411 = validateParameter(valid_606411, JBool, required = false, default = nil)
  if valid_606411 != nil:
    section.add "Process", valid_606411
  var valid_606412 = formData.getOrDefault("SourceBuildInformation.SourceType")
  valid_606412 = validateParameter(valid_606412, JString, required = false,
                                 default = nil)
  if valid_606412 != nil:
    section.add "SourceBuildInformation.SourceType", valid_606412
  var valid_606413 = formData.getOrDefault("BuildConfiguration.ArtifactName")
  valid_606413 = validateParameter(valid_606413, JString, required = false,
                                 default = nil)
  if valid_606413 != nil:
    section.add "BuildConfiguration.ArtifactName", valid_606413
  var valid_606414 = formData.getOrDefault("Description")
  valid_606414 = validateParameter(valid_606414, JString, required = false,
                                 default = nil)
  if valid_606414 != nil:
    section.add "Description", valid_606414
  assert formData != nil,
        "formData argument is necessary due to required `VersionLabel` field"
  var valid_606415 = formData.getOrDefault("VersionLabel")
  valid_606415 = validateParameter(valid_606415, JString, required = true,
                                 default = nil)
  if valid_606415 != nil:
    section.add "VersionLabel", valid_606415
  var valid_606416 = formData.getOrDefault("SourceBuildInformation.SourceRepository")
  valid_606416 = validateParameter(valid_606416, JString, required = false,
                                 default = nil)
  if valid_606416 != nil:
    section.add "SourceBuildInformation.SourceRepository", valid_606416
  var valid_606417 = formData.getOrDefault("AutoCreateApplication")
  valid_606417 = validateParameter(valid_606417, JBool, required = false, default = nil)
  if valid_606417 != nil:
    section.add "AutoCreateApplication", valid_606417
  var valid_606418 = formData.getOrDefault("SourceBuildInformation.SourceLocation")
  valid_606418 = validateParameter(valid_606418, JString, required = false,
                                 default = nil)
  if valid_606418 != nil:
    section.add "SourceBuildInformation.SourceLocation", valid_606418
  var valid_606419 = formData.getOrDefault("ApplicationName")
  valid_606419 = validateParameter(valid_606419, JString, required = true,
                                 default = nil)
  if valid_606419 != nil:
    section.add "ApplicationName", valid_606419
  var valid_606420 = formData.getOrDefault("BuildConfiguration.Image")
  valid_606420 = validateParameter(valid_606420, JString, required = false,
                                 default = nil)
  if valid_606420 != nil:
    section.add "BuildConfiguration.Image", valid_606420
  var valid_606421 = formData.getOrDefault("BuildConfiguration.TimeoutInMinutes")
  valid_606421 = validateParameter(valid_606421, JString, required = false,
                                 default = nil)
  if valid_606421 != nil:
    section.add "BuildConfiguration.TimeoutInMinutes", valid_606421
  var valid_606422 = formData.getOrDefault("Tags")
  valid_606422 = validateParameter(valid_606422, JArray, required = false,
                                 default = nil)
  if valid_606422 != nil:
    section.add "Tags", valid_606422
  var valid_606423 = formData.getOrDefault("SourceBundle.S3Bucket")
  valid_606423 = validateParameter(valid_606423, JString, required = false,
                                 default = nil)
  if valid_606423 != nil:
    section.add "SourceBundle.S3Bucket", valid_606423
  var valid_606424 = formData.getOrDefault("BuildConfiguration.CodeBuildServiceRole")
  valid_606424 = validateParameter(valid_606424, JString, required = false,
                                 default = nil)
  if valid_606424 != nil:
    section.add "BuildConfiguration.CodeBuildServiceRole", valid_606424
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606425: Call_PostCreateApplicationVersion_606397; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an application version for the specified application. You can create an application version from a source bundle in Amazon S3, a commit in AWS CodeCommit, or the output of an AWS CodeBuild build as follows:</p> <p>Specify a commit in an AWS CodeCommit repository with <code>SourceBuildInformation</code>.</p> <p>Specify a build in an AWS CodeBuild with <code>SourceBuildInformation</code> and <code>BuildConfiguration</code>.</p> <p>Specify a source bundle in S3 with <code>SourceBundle</code> </p> <p>Omit both <code>SourceBuildInformation</code> and <code>SourceBundle</code> to use the default sample application.</p> <note> <p>Once you create an application version with a specified Amazon S3 bucket and key location, you cannot change that Amazon S3 location. If you change the Amazon S3 location, you receive an exception when you attempt to launch an environment from the application version.</p> </note>
  ## 
  let valid = call_606425.validator(path, query, header, formData, body)
  let scheme = call_606425.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606425.url(scheme.get, call_606425.host, call_606425.base,
                         call_606425.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606425, url, valid)

proc call*(call_606426: Call_PostCreateApplicationVersion_606397;
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
  var query_606427 = newJObject()
  var formData_606428 = newJObject()
  add(formData_606428, "BuildConfiguration.ComputeType",
      newJString(BuildConfigurationComputeType))
  add(formData_606428, "SourceBundle.S3Key", newJString(SourceBundleS3Key))
  add(formData_606428, "Process", newJBool(Process))
  add(formData_606428, "SourceBuildInformation.SourceType",
      newJString(SourceBuildInformationSourceType))
  add(formData_606428, "BuildConfiguration.ArtifactName",
      newJString(BuildConfigurationArtifactName))
  add(formData_606428, "Description", newJString(Description))
  add(formData_606428, "VersionLabel", newJString(VersionLabel))
  add(formData_606428, "SourceBuildInformation.SourceRepository",
      newJString(SourceBuildInformationSourceRepository))
  add(formData_606428, "AutoCreateApplication", newJBool(AutoCreateApplication))
  add(formData_606428, "SourceBuildInformation.SourceLocation",
      newJString(SourceBuildInformationSourceLocation))
  add(formData_606428, "ApplicationName", newJString(ApplicationName))
  add(query_606427, "Action", newJString(Action))
  add(formData_606428, "BuildConfiguration.Image",
      newJString(BuildConfigurationImage))
  add(formData_606428, "BuildConfiguration.TimeoutInMinutes",
      newJString(BuildConfigurationTimeoutInMinutes))
  if Tags != nil:
    formData_606428.add "Tags", Tags
  add(formData_606428, "SourceBundle.S3Bucket", newJString(SourceBundleS3Bucket))
  add(query_606427, "Version", newJString(Version))
  add(formData_606428, "BuildConfiguration.CodeBuildServiceRole",
      newJString(BuildConfigurationCodeBuildServiceRole))
  result = call_606426.call(nil, query_606427, nil, formData_606428, nil)

var postCreateApplicationVersion* = Call_PostCreateApplicationVersion_606397(
    name: "postCreateApplicationVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateApplicationVersion",
    validator: validate_PostCreateApplicationVersion_606398, base: "/",
    url: url_PostCreateApplicationVersion_606399,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateApplicationVersion_606366 = ref object of OpenApiRestCall_605590
proc url_GetCreateApplicationVersion_606368(protocol: Scheme; host: string;
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

proc validate_GetCreateApplicationVersion_606367(path: JsonNode; query: JsonNode;
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
  var valid_606369 = query.getOrDefault("ApplicationName")
  valid_606369 = validateParameter(valid_606369, JString, required = true,
                                 default = nil)
  if valid_606369 != nil:
    section.add "ApplicationName", valid_606369
  var valid_606370 = query.getOrDefault("BuildConfiguration.TimeoutInMinutes")
  valid_606370 = validateParameter(valid_606370, JString, required = false,
                                 default = nil)
  if valid_606370 != nil:
    section.add "BuildConfiguration.TimeoutInMinutes", valid_606370
  var valid_606371 = query.getOrDefault("Process")
  valid_606371 = validateParameter(valid_606371, JBool, required = false, default = nil)
  if valid_606371 != nil:
    section.add "Process", valid_606371
  var valid_606372 = query.getOrDefault("SourceBuildInformation.SourceLocation")
  valid_606372 = validateParameter(valid_606372, JString, required = false,
                                 default = nil)
  if valid_606372 != nil:
    section.add "SourceBuildInformation.SourceLocation", valid_606372
  var valid_606373 = query.getOrDefault("VersionLabel")
  valid_606373 = validateParameter(valid_606373, JString, required = true,
                                 default = nil)
  if valid_606373 != nil:
    section.add "VersionLabel", valid_606373
  var valid_606374 = query.getOrDefault("Tags")
  valid_606374 = validateParameter(valid_606374, JArray, required = false,
                                 default = nil)
  if valid_606374 != nil:
    section.add "Tags", valid_606374
  var valid_606375 = query.getOrDefault("AutoCreateApplication")
  valid_606375 = validateParameter(valid_606375, JBool, required = false, default = nil)
  if valid_606375 != nil:
    section.add "AutoCreateApplication", valid_606375
  var valid_606376 = query.getOrDefault("BuildConfiguration.Image")
  valid_606376 = validateParameter(valid_606376, JString, required = false,
                                 default = nil)
  if valid_606376 != nil:
    section.add "BuildConfiguration.Image", valid_606376
  var valid_606377 = query.getOrDefault("Action")
  valid_606377 = validateParameter(valid_606377, JString, required = true, default = newJString(
      "CreateApplicationVersion"))
  if valid_606377 != nil:
    section.add "Action", valid_606377
  var valid_606378 = query.getOrDefault("Description")
  valid_606378 = validateParameter(valid_606378, JString, required = false,
                                 default = nil)
  if valid_606378 != nil:
    section.add "Description", valid_606378
  var valid_606379 = query.getOrDefault("SourceBundle.S3Bucket")
  valid_606379 = validateParameter(valid_606379, JString, required = false,
                                 default = nil)
  if valid_606379 != nil:
    section.add "SourceBundle.S3Bucket", valid_606379
  var valid_606380 = query.getOrDefault("SourceBuildInformation.SourceRepository")
  valid_606380 = validateParameter(valid_606380, JString, required = false,
                                 default = nil)
  if valid_606380 != nil:
    section.add "SourceBuildInformation.SourceRepository", valid_606380
  var valid_606381 = query.getOrDefault("BuildConfiguration.ComputeType")
  valid_606381 = validateParameter(valid_606381, JString, required = false,
                                 default = nil)
  if valid_606381 != nil:
    section.add "BuildConfiguration.ComputeType", valid_606381
  var valid_606382 = query.getOrDefault("SourceBuildInformation.SourceType")
  valid_606382 = validateParameter(valid_606382, JString, required = false,
                                 default = nil)
  if valid_606382 != nil:
    section.add "SourceBuildInformation.SourceType", valid_606382
  var valid_606383 = query.getOrDefault("BuildConfiguration.ArtifactName")
  valid_606383 = validateParameter(valid_606383, JString, required = false,
                                 default = nil)
  if valid_606383 != nil:
    section.add "BuildConfiguration.ArtifactName", valid_606383
  var valid_606384 = query.getOrDefault("Version")
  valid_606384 = validateParameter(valid_606384, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_606384 != nil:
    section.add "Version", valid_606384
  var valid_606385 = query.getOrDefault("SourceBundle.S3Key")
  valid_606385 = validateParameter(valid_606385, JString, required = false,
                                 default = nil)
  if valid_606385 != nil:
    section.add "SourceBundle.S3Key", valid_606385
  var valid_606386 = query.getOrDefault("BuildConfiguration.CodeBuildServiceRole")
  valid_606386 = validateParameter(valid_606386, JString, required = false,
                                 default = nil)
  if valid_606386 != nil:
    section.add "BuildConfiguration.CodeBuildServiceRole", valid_606386
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
  var valid_606387 = header.getOrDefault("X-Amz-Signature")
  valid_606387 = validateParameter(valid_606387, JString, required = false,
                                 default = nil)
  if valid_606387 != nil:
    section.add "X-Amz-Signature", valid_606387
  var valid_606388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606388 = validateParameter(valid_606388, JString, required = false,
                                 default = nil)
  if valid_606388 != nil:
    section.add "X-Amz-Content-Sha256", valid_606388
  var valid_606389 = header.getOrDefault("X-Amz-Date")
  valid_606389 = validateParameter(valid_606389, JString, required = false,
                                 default = nil)
  if valid_606389 != nil:
    section.add "X-Amz-Date", valid_606389
  var valid_606390 = header.getOrDefault("X-Amz-Credential")
  valid_606390 = validateParameter(valid_606390, JString, required = false,
                                 default = nil)
  if valid_606390 != nil:
    section.add "X-Amz-Credential", valid_606390
  var valid_606391 = header.getOrDefault("X-Amz-Security-Token")
  valid_606391 = validateParameter(valid_606391, JString, required = false,
                                 default = nil)
  if valid_606391 != nil:
    section.add "X-Amz-Security-Token", valid_606391
  var valid_606392 = header.getOrDefault("X-Amz-Algorithm")
  valid_606392 = validateParameter(valid_606392, JString, required = false,
                                 default = nil)
  if valid_606392 != nil:
    section.add "X-Amz-Algorithm", valid_606392
  var valid_606393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606393 = validateParameter(valid_606393, JString, required = false,
                                 default = nil)
  if valid_606393 != nil:
    section.add "X-Amz-SignedHeaders", valid_606393
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606394: Call_GetCreateApplicationVersion_606366; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an application version for the specified application. You can create an application version from a source bundle in Amazon S3, a commit in AWS CodeCommit, or the output of an AWS CodeBuild build as follows:</p> <p>Specify a commit in an AWS CodeCommit repository with <code>SourceBuildInformation</code>.</p> <p>Specify a build in an AWS CodeBuild with <code>SourceBuildInformation</code> and <code>BuildConfiguration</code>.</p> <p>Specify a source bundle in S3 with <code>SourceBundle</code> </p> <p>Omit both <code>SourceBuildInformation</code> and <code>SourceBundle</code> to use the default sample application.</p> <note> <p>Once you create an application version with a specified Amazon S3 bucket and key location, you cannot change that Amazon S3 location. If you change the Amazon S3 location, you receive an exception when you attempt to launch an environment from the application version.</p> </note>
  ## 
  let valid = call_606394.validator(path, query, header, formData, body)
  let scheme = call_606394.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606394.url(scheme.get, call_606394.host, call_606394.base,
                         call_606394.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606394, url, valid)

proc call*(call_606395: Call_GetCreateApplicationVersion_606366;
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
  var query_606396 = newJObject()
  add(query_606396, "ApplicationName", newJString(ApplicationName))
  add(query_606396, "BuildConfiguration.TimeoutInMinutes",
      newJString(BuildConfigurationTimeoutInMinutes))
  add(query_606396, "Process", newJBool(Process))
  add(query_606396, "SourceBuildInformation.SourceLocation",
      newJString(SourceBuildInformationSourceLocation))
  add(query_606396, "VersionLabel", newJString(VersionLabel))
  if Tags != nil:
    query_606396.add "Tags", Tags
  add(query_606396, "AutoCreateApplication", newJBool(AutoCreateApplication))
  add(query_606396, "BuildConfiguration.Image",
      newJString(BuildConfigurationImage))
  add(query_606396, "Action", newJString(Action))
  add(query_606396, "Description", newJString(Description))
  add(query_606396, "SourceBundle.S3Bucket", newJString(SourceBundleS3Bucket))
  add(query_606396, "SourceBuildInformation.SourceRepository",
      newJString(SourceBuildInformationSourceRepository))
  add(query_606396, "BuildConfiguration.ComputeType",
      newJString(BuildConfigurationComputeType))
  add(query_606396, "SourceBuildInformation.SourceType",
      newJString(SourceBuildInformationSourceType))
  add(query_606396, "BuildConfiguration.ArtifactName",
      newJString(BuildConfigurationArtifactName))
  add(query_606396, "Version", newJString(Version))
  add(query_606396, "SourceBundle.S3Key", newJString(SourceBundleS3Key))
  add(query_606396, "BuildConfiguration.CodeBuildServiceRole",
      newJString(BuildConfigurationCodeBuildServiceRole))
  result = call_606395.call(nil, query_606396, nil, nil, nil)

var getCreateApplicationVersion* = Call_GetCreateApplicationVersion_606366(
    name: "getCreateApplicationVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateApplicationVersion",
    validator: validate_GetCreateApplicationVersion_606367, base: "/",
    url: url_GetCreateApplicationVersion_606368,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateConfigurationTemplate_606454 = ref object of OpenApiRestCall_605590
proc url_PostCreateConfigurationTemplate_606456(protocol: Scheme; host: string;
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

proc validate_PostCreateConfigurationTemplate_606455(path: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606457 = query.getOrDefault("Action")
  valid_606457 = validateParameter(valid_606457, JString, required = true, default = newJString(
      "CreateConfigurationTemplate"))
  if valid_606457 != nil:
    section.add "Action", valid_606457
  var valid_606458 = query.getOrDefault("Version")
  valid_606458 = validateParameter(valid_606458, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_606458 != nil:
    section.add "Version", valid_606458
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
  var valid_606459 = header.getOrDefault("X-Amz-Signature")
  valid_606459 = validateParameter(valid_606459, JString, required = false,
                                 default = nil)
  if valid_606459 != nil:
    section.add "X-Amz-Signature", valid_606459
  var valid_606460 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606460 = validateParameter(valid_606460, JString, required = false,
                                 default = nil)
  if valid_606460 != nil:
    section.add "X-Amz-Content-Sha256", valid_606460
  var valid_606461 = header.getOrDefault("X-Amz-Date")
  valid_606461 = validateParameter(valid_606461, JString, required = false,
                                 default = nil)
  if valid_606461 != nil:
    section.add "X-Amz-Date", valid_606461
  var valid_606462 = header.getOrDefault("X-Amz-Credential")
  valid_606462 = validateParameter(valid_606462, JString, required = false,
                                 default = nil)
  if valid_606462 != nil:
    section.add "X-Amz-Credential", valid_606462
  var valid_606463 = header.getOrDefault("X-Amz-Security-Token")
  valid_606463 = validateParameter(valid_606463, JString, required = false,
                                 default = nil)
  if valid_606463 != nil:
    section.add "X-Amz-Security-Token", valid_606463
  var valid_606464 = header.getOrDefault("X-Amz-Algorithm")
  valid_606464 = validateParameter(valid_606464, JString, required = false,
                                 default = nil)
  if valid_606464 != nil:
    section.add "X-Amz-Algorithm", valid_606464
  var valid_606465 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606465 = validateParameter(valid_606465, JString, required = false,
                                 default = nil)
  if valid_606465 != nil:
    section.add "X-Amz-SignedHeaders", valid_606465
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
  var valid_606466 = formData.getOrDefault("Description")
  valid_606466 = validateParameter(valid_606466, JString, required = false,
                                 default = nil)
  if valid_606466 != nil:
    section.add "Description", valid_606466
  assert formData != nil,
        "formData argument is necessary due to required `TemplateName` field"
  var valid_606467 = formData.getOrDefault("TemplateName")
  valid_606467 = validateParameter(valid_606467, JString, required = true,
                                 default = nil)
  if valid_606467 != nil:
    section.add "TemplateName", valid_606467
  var valid_606468 = formData.getOrDefault("SourceConfiguration.ApplicationName")
  valid_606468 = validateParameter(valid_606468, JString, required = false,
                                 default = nil)
  if valid_606468 != nil:
    section.add "SourceConfiguration.ApplicationName", valid_606468
  var valid_606469 = formData.getOrDefault("SourceConfiguration.TemplateName")
  valid_606469 = validateParameter(valid_606469, JString, required = false,
                                 default = nil)
  if valid_606469 != nil:
    section.add "SourceConfiguration.TemplateName", valid_606469
  var valid_606470 = formData.getOrDefault("OptionSettings")
  valid_606470 = validateParameter(valid_606470, JArray, required = false,
                                 default = nil)
  if valid_606470 != nil:
    section.add "OptionSettings", valid_606470
  var valid_606471 = formData.getOrDefault("ApplicationName")
  valid_606471 = validateParameter(valid_606471, JString, required = true,
                                 default = nil)
  if valid_606471 != nil:
    section.add "ApplicationName", valid_606471
  var valid_606472 = formData.getOrDefault("Tags")
  valid_606472 = validateParameter(valid_606472, JArray, required = false,
                                 default = nil)
  if valid_606472 != nil:
    section.add "Tags", valid_606472
  var valid_606473 = formData.getOrDefault("SolutionStackName")
  valid_606473 = validateParameter(valid_606473, JString, required = false,
                                 default = nil)
  if valid_606473 != nil:
    section.add "SolutionStackName", valid_606473
  var valid_606474 = formData.getOrDefault("EnvironmentId")
  valid_606474 = validateParameter(valid_606474, JString, required = false,
                                 default = nil)
  if valid_606474 != nil:
    section.add "EnvironmentId", valid_606474
  var valid_606475 = formData.getOrDefault("PlatformArn")
  valid_606475 = validateParameter(valid_606475, JString, required = false,
                                 default = nil)
  if valid_606475 != nil:
    section.add "PlatformArn", valid_606475
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606476: Call_PostCreateConfigurationTemplate_606454;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a configuration template. Templates are associated with a specific application and are used to deploy different versions of the application with the same configuration settings.</p> <p>Templates aren't associated with any environment. The <code>EnvironmentName</code> response element is always <code>null</code>.</p> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> <li> <p> <a>DescribeConfigurationSettings</a> </p> </li> <li> <p> <a>ListAvailableSolutionStacks</a> </p> </li> </ul>
  ## 
  let valid = call_606476.validator(path, query, header, formData, body)
  let scheme = call_606476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606476.url(scheme.get, call_606476.host, call_606476.base,
                         call_606476.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606476, url, valid)

proc call*(call_606477: Call_PostCreateConfigurationTemplate_606454;
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
  var query_606478 = newJObject()
  var formData_606479 = newJObject()
  add(formData_606479, "Description", newJString(Description))
  add(formData_606479, "TemplateName", newJString(TemplateName))
  add(formData_606479, "SourceConfiguration.ApplicationName",
      newJString(SourceConfigurationApplicationName))
  add(formData_606479, "SourceConfiguration.TemplateName",
      newJString(SourceConfigurationTemplateName))
  if OptionSettings != nil:
    formData_606479.add "OptionSettings", OptionSettings
  add(formData_606479, "ApplicationName", newJString(ApplicationName))
  add(query_606478, "Action", newJString(Action))
  if Tags != nil:
    formData_606479.add "Tags", Tags
  add(formData_606479, "SolutionStackName", newJString(SolutionStackName))
  add(formData_606479, "EnvironmentId", newJString(EnvironmentId))
  add(query_606478, "Version", newJString(Version))
  add(formData_606479, "PlatformArn", newJString(PlatformArn))
  result = call_606477.call(nil, query_606478, nil, formData_606479, nil)

var postCreateConfigurationTemplate* = Call_PostCreateConfigurationTemplate_606454(
    name: "postCreateConfigurationTemplate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateConfigurationTemplate",
    validator: validate_PostCreateConfigurationTemplate_606455, base: "/",
    url: url_PostCreateConfigurationTemplate_606456,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateConfigurationTemplate_606429 = ref object of OpenApiRestCall_605590
proc url_GetCreateConfigurationTemplate_606431(protocol: Scheme; host: string;
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

proc validate_GetCreateConfigurationTemplate_606430(path: JsonNode;
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
  var valid_606432 = query.getOrDefault("ApplicationName")
  valid_606432 = validateParameter(valid_606432, JString, required = true,
                                 default = nil)
  if valid_606432 != nil:
    section.add "ApplicationName", valid_606432
  var valid_606433 = query.getOrDefault("Tags")
  valid_606433 = validateParameter(valid_606433, JArray, required = false,
                                 default = nil)
  if valid_606433 != nil:
    section.add "Tags", valid_606433
  var valid_606434 = query.getOrDefault("OptionSettings")
  valid_606434 = validateParameter(valid_606434, JArray, required = false,
                                 default = nil)
  if valid_606434 != nil:
    section.add "OptionSettings", valid_606434
  var valid_606435 = query.getOrDefault("SourceConfiguration.TemplateName")
  valid_606435 = validateParameter(valid_606435, JString, required = false,
                                 default = nil)
  if valid_606435 != nil:
    section.add "SourceConfiguration.TemplateName", valid_606435
  var valid_606436 = query.getOrDefault("SolutionStackName")
  valid_606436 = validateParameter(valid_606436, JString, required = false,
                                 default = nil)
  if valid_606436 != nil:
    section.add "SolutionStackName", valid_606436
  var valid_606437 = query.getOrDefault("Action")
  valid_606437 = validateParameter(valid_606437, JString, required = true, default = newJString(
      "CreateConfigurationTemplate"))
  if valid_606437 != nil:
    section.add "Action", valid_606437
  var valid_606438 = query.getOrDefault("Description")
  valid_606438 = validateParameter(valid_606438, JString, required = false,
                                 default = nil)
  if valid_606438 != nil:
    section.add "Description", valid_606438
  var valid_606439 = query.getOrDefault("PlatformArn")
  valid_606439 = validateParameter(valid_606439, JString, required = false,
                                 default = nil)
  if valid_606439 != nil:
    section.add "PlatformArn", valid_606439
  var valid_606440 = query.getOrDefault("Version")
  valid_606440 = validateParameter(valid_606440, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_606440 != nil:
    section.add "Version", valid_606440
  var valid_606441 = query.getOrDefault("TemplateName")
  valid_606441 = validateParameter(valid_606441, JString, required = true,
                                 default = nil)
  if valid_606441 != nil:
    section.add "TemplateName", valid_606441
  var valid_606442 = query.getOrDefault("SourceConfiguration.ApplicationName")
  valid_606442 = validateParameter(valid_606442, JString, required = false,
                                 default = nil)
  if valid_606442 != nil:
    section.add "SourceConfiguration.ApplicationName", valid_606442
  var valid_606443 = query.getOrDefault("EnvironmentId")
  valid_606443 = validateParameter(valid_606443, JString, required = false,
                                 default = nil)
  if valid_606443 != nil:
    section.add "EnvironmentId", valid_606443
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
  var valid_606444 = header.getOrDefault("X-Amz-Signature")
  valid_606444 = validateParameter(valid_606444, JString, required = false,
                                 default = nil)
  if valid_606444 != nil:
    section.add "X-Amz-Signature", valid_606444
  var valid_606445 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606445 = validateParameter(valid_606445, JString, required = false,
                                 default = nil)
  if valid_606445 != nil:
    section.add "X-Amz-Content-Sha256", valid_606445
  var valid_606446 = header.getOrDefault("X-Amz-Date")
  valid_606446 = validateParameter(valid_606446, JString, required = false,
                                 default = nil)
  if valid_606446 != nil:
    section.add "X-Amz-Date", valid_606446
  var valid_606447 = header.getOrDefault("X-Amz-Credential")
  valid_606447 = validateParameter(valid_606447, JString, required = false,
                                 default = nil)
  if valid_606447 != nil:
    section.add "X-Amz-Credential", valid_606447
  var valid_606448 = header.getOrDefault("X-Amz-Security-Token")
  valid_606448 = validateParameter(valid_606448, JString, required = false,
                                 default = nil)
  if valid_606448 != nil:
    section.add "X-Amz-Security-Token", valid_606448
  var valid_606449 = header.getOrDefault("X-Amz-Algorithm")
  valid_606449 = validateParameter(valid_606449, JString, required = false,
                                 default = nil)
  if valid_606449 != nil:
    section.add "X-Amz-Algorithm", valid_606449
  var valid_606450 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606450 = validateParameter(valid_606450, JString, required = false,
                                 default = nil)
  if valid_606450 != nil:
    section.add "X-Amz-SignedHeaders", valid_606450
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606451: Call_GetCreateConfigurationTemplate_606429; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a configuration template. Templates are associated with a specific application and are used to deploy different versions of the application with the same configuration settings.</p> <p>Templates aren't associated with any environment. The <code>EnvironmentName</code> response element is always <code>null</code>.</p> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> <li> <p> <a>DescribeConfigurationSettings</a> </p> </li> <li> <p> <a>ListAvailableSolutionStacks</a> </p> </li> </ul>
  ## 
  let valid = call_606451.validator(path, query, header, formData, body)
  let scheme = call_606451.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606451.url(scheme.get, call_606451.host, call_606451.base,
                         call_606451.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606451, url, valid)

proc call*(call_606452: Call_GetCreateConfigurationTemplate_606429;
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
  var query_606453 = newJObject()
  add(query_606453, "ApplicationName", newJString(ApplicationName))
  if Tags != nil:
    query_606453.add "Tags", Tags
  if OptionSettings != nil:
    query_606453.add "OptionSettings", OptionSettings
  add(query_606453, "SourceConfiguration.TemplateName",
      newJString(SourceConfigurationTemplateName))
  add(query_606453, "SolutionStackName", newJString(SolutionStackName))
  add(query_606453, "Action", newJString(Action))
  add(query_606453, "Description", newJString(Description))
  add(query_606453, "PlatformArn", newJString(PlatformArn))
  add(query_606453, "Version", newJString(Version))
  add(query_606453, "TemplateName", newJString(TemplateName))
  add(query_606453, "SourceConfiguration.ApplicationName",
      newJString(SourceConfigurationApplicationName))
  add(query_606453, "EnvironmentId", newJString(EnvironmentId))
  result = call_606452.call(nil, query_606453, nil, nil, nil)

var getCreateConfigurationTemplate* = Call_GetCreateConfigurationTemplate_606429(
    name: "getCreateConfigurationTemplate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateConfigurationTemplate",
    validator: validate_GetCreateConfigurationTemplate_606430, base: "/",
    url: url_GetCreateConfigurationTemplate_606431,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEnvironment_606510 = ref object of OpenApiRestCall_605590
proc url_PostCreateEnvironment_606512(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateEnvironment_606511(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606513 = query.getOrDefault("Action")
  valid_606513 = validateParameter(valid_606513, JString, required = true,
                                 default = newJString("CreateEnvironment"))
  if valid_606513 != nil:
    section.add "Action", valid_606513
  var valid_606514 = query.getOrDefault("Version")
  valid_606514 = validateParameter(valid_606514, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_606514 != nil:
    section.add "Version", valid_606514
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
  var valid_606515 = header.getOrDefault("X-Amz-Signature")
  valid_606515 = validateParameter(valid_606515, JString, required = false,
                                 default = nil)
  if valid_606515 != nil:
    section.add "X-Amz-Signature", valid_606515
  var valid_606516 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606516 = validateParameter(valid_606516, JString, required = false,
                                 default = nil)
  if valid_606516 != nil:
    section.add "X-Amz-Content-Sha256", valid_606516
  var valid_606517 = header.getOrDefault("X-Amz-Date")
  valid_606517 = validateParameter(valid_606517, JString, required = false,
                                 default = nil)
  if valid_606517 != nil:
    section.add "X-Amz-Date", valid_606517
  var valid_606518 = header.getOrDefault("X-Amz-Credential")
  valid_606518 = validateParameter(valid_606518, JString, required = false,
                                 default = nil)
  if valid_606518 != nil:
    section.add "X-Amz-Credential", valid_606518
  var valid_606519 = header.getOrDefault("X-Amz-Security-Token")
  valid_606519 = validateParameter(valid_606519, JString, required = false,
                                 default = nil)
  if valid_606519 != nil:
    section.add "X-Amz-Security-Token", valid_606519
  var valid_606520 = header.getOrDefault("X-Amz-Algorithm")
  valid_606520 = validateParameter(valid_606520, JString, required = false,
                                 default = nil)
  if valid_606520 != nil:
    section.add "X-Amz-Algorithm", valid_606520
  var valid_606521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606521 = validateParameter(valid_606521, JString, required = false,
                                 default = nil)
  if valid_606521 != nil:
    section.add "X-Amz-SignedHeaders", valid_606521
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
  var valid_606522 = formData.getOrDefault("Description")
  valid_606522 = validateParameter(valid_606522, JString, required = false,
                                 default = nil)
  if valid_606522 != nil:
    section.add "Description", valid_606522
  var valid_606523 = formData.getOrDefault("Tier.Type")
  valid_606523 = validateParameter(valid_606523, JString, required = false,
                                 default = nil)
  if valid_606523 != nil:
    section.add "Tier.Type", valid_606523
  var valid_606524 = formData.getOrDefault("EnvironmentName")
  valid_606524 = validateParameter(valid_606524, JString, required = false,
                                 default = nil)
  if valid_606524 != nil:
    section.add "EnvironmentName", valid_606524
  var valid_606525 = formData.getOrDefault("CNAMEPrefix")
  valid_606525 = validateParameter(valid_606525, JString, required = false,
                                 default = nil)
  if valid_606525 != nil:
    section.add "CNAMEPrefix", valid_606525
  var valid_606526 = formData.getOrDefault("VersionLabel")
  valid_606526 = validateParameter(valid_606526, JString, required = false,
                                 default = nil)
  if valid_606526 != nil:
    section.add "VersionLabel", valid_606526
  var valid_606527 = formData.getOrDefault("TemplateName")
  valid_606527 = validateParameter(valid_606527, JString, required = false,
                                 default = nil)
  if valid_606527 != nil:
    section.add "TemplateName", valid_606527
  var valid_606528 = formData.getOrDefault("OptionsToRemove")
  valid_606528 = validateParameter(valid_606528, JArray, required = false,
                                 default = nil)
  if valid_606528 != nil:
    section.add "OptionsToRemove", valid_606528
  var valid_606529 = formData.getOrDefault("OptionSettings")
  valid_606529 = validateParameter(valid_606529, JArray, required = false,
                                 default = nil)
  if valid_606529 != nil:
    section.add "OptionSettings", valid_606529
  var valid_606530 = formData.getOrDefault("GroupName")
  valid_606530 = validateParameter(valid_606530, JString, required = false,
                                 default = nil)
  if valid_606530 != nil:
    section.add "GroupName", valid_606530
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_606531 = formData.getOrDefault("ApplicationName")
  valid_606531 = validateParameter(valid_606531, JString, required = true,
                                 default = nil)
  if valid_606531 != nil:
    section.add "ApplicationName", valid_606531
  var valid_606532 = formData.getOrDefault("Tier.Name")
  valid_606532 = validateParameter(valid_606532, JString, required = false,
                                 default = nil)
  if valid_606532 != nil:
    section.add "Tier.Name", valid_606532
  var valid_606533 = formData.getOrDefault("Tier.Version")
  valid_606533 = validateParameter(valid_606533, JString, required = false,
                                 default = nil)
  if valid_606533 != nil:
    section.add "Tier.Version", valid_606533
  var valid_606534 = formData.getOrDefault("Tags")
  valid_606534 = validateParameter(valid_606534, JArray, required = false,
                                 default = nil)
  if valid_606534 != nil:
    section.add "Tags", valid_606534
  var valid_606535 = formData.getOrDefault("SolutionStackName")
  valid_606535 = validateParameter(valid_606535, JString, required = false,
                                 default = nil)
  if valid_606535 != nil:
    section.add "SolutionStackName", valid_606535
  var valid_606536 = formData.getOrDefault("PlatformArn")
  valid_606536 = validateParameter(valid_606536, JString, required = false,
                                 default = nil)
  if valid_606536 != nil:
    section.add "PlatformArn", valid_606536
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606537: Call_PostCreateEnvironment_606510; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Launches an environment for the specified application using the specified configuration.
  ## 
  let valid = call_606537.validator(path, query, header, formData, body)
  let scheme = call_606537.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606537.url(scheme.get, call_606537.host, call_606537.base,
                         call_606537.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606537, url, valid)

proc call*(call_606538: Call_PostCreateEnvironment_606510; ApplicationName: string;
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
  var query_606539 = newJObject()
  var formData_606540 = newJObject()
  add(formData_606540, "Description", newJString(Description))
  add(formData_606540, "Tier.Type", newJString(TierType))
  add(formData_606540, "EnvironmentName", newJString(EnvironmentName))
  add(formData_606540, "CNAMEPrefix", newJString(CNAMEPrefix))
  add(formData_606540, "VersionLabel", newJString(VersionLabel))
  add(formData_606540, "TemplateName", newJString(TemplateName))
  if OptionsToRemove != nil:
    formData_606540.add "OptionsToRemove", OptionsToRemove
  if OptionSettings != nil:
    formData_606540.add "OptionSettings", OptionSettings
  add(formData_606540, "GroupName", newJString(GroupName))
  add(formData_606540, "ApplicationName", newJString(ApplicationName))
  add(formData_606540, "Tier.Name", newJString(TierName))
  add(formData_606540, "Tier.Version", newJString(TierVersion))
  add(query_606539, "Action", newJString(Action))
  if Tags != nil:
    formData_606540.add "Tags", Tags
  add(formData_606540, "SolutionStackName", newJString(SolutionStackName))
  add(query_606539, "Version", newJString(Version))
  add(formData_606540, "PlatformArn", newJString(PlatformArn))
  result = call_606538.call(nil, query_606539, nil, formData_606540, nil)

var postCreateEnvironment* = Call_PostCreateEnvironment_606510(
    name: "postCreateEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateEnvironment",
    validator: validate_PostCreateEnvironment_606511, base: "/",
    url: url_PostCreateEnvironment_606512, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEnvironment_606480 = ref object of OpenApiRestCall_605590
proc url_GetCreateEnvironment_606482(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateEnvironment_606481(path: JsonNode; query: JsonNode;
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
  var valid_606483 = query.getOrDefault("ApplicationName")
  valid_606483 = validateParameter(valid_606483, JString, required = true,
                                 default = nil)
  if valid_606483 != nil:
    section.add "ApplicationName", valid_606483
  var valid_606484 = query.getOrDefault("CNAMEPrefix")
  valid_606484 = validateParameter(valid_606484, JString, required = false,
                                 default = nil)
  if valid_606484 != nil:
    section.add "CNAMEPrefix", valid_606484
  var valid_606485 = query.getOrDefault("GroupName")
  valid_606485 = validateParameter(valid_606485, JString, required = false,
                                 default = nil)
  if valid_606485 != nil:
    section.add "GroupName", valid_606485
  var valid_606486 = query.getOrDefault("Tags")
  valid_606486 = validateParameter(valid_606486, JArray, required = false,
                                 default = nil)
  if valid_606486 != nil:
    section.add "Tags", valid_606486
  var valid_606487 = query.getOrDefault("VersionLabel")
  valid_606487 = validateParameter(valid_606487, JString, required = false,
                                 default = nil)
  if valid_606487 != nil:
    section.add "VersionLabel", valid_606487
  var valid_606488 = query.getOrDefault("OptionSettings")
  valid_606488 = validateParameter(valid_606488, JArray, required = false,
                                 default = nil)
  if valid_606488 != nil:
    section.add "OptionSettings", valid_606488
  var valid_606489 = query.getOrDefault("SolutionStackName")
  valid_606489 = validateParameter(valid_606489, JString, required = false,
                                 default = nil)
  if valid_606489 != nil:
    section.add "SolutionStackName", valid_606489
  var valid_606490 = query.getOrDefault("Tier.Name")
  valid_606490 = validateParameter(valid_606490, JString, required = false,
                                 default = nil)
  if valid_606490 != nil:
    section.add "Tier.Name", valid_606490
  var valid_606491 = query.getOrDefault("EnvironmentName")
  valid_606491 = validateParameter(valid_606491, JString, required = false,
                                 default = nil)
  if valid_606491 != nil:
    section.add "EnvironmentName", valid_606491
  var valid_606492 = query.getOrDefault("Action")
  valid_606492 = validateParameter(valid_606492, JString, required = true,
                                 default = newJString("CreateEnvironment"))
  if valid_606492 != nil:
    section.add "Action", valid_606492
  var valid_606493 = query.getOrDefault("Description")
  valid_606493 = validateParameter(valid_606493, JString, required = false,
                                 default = nil)
  if valid_606493 != nil:
    section.add "Description", valid_606493
  var valid_606494 = query.getOrDefault("PlatformArn")
  valid_606494 = validateParameter(valid_606494, JString, required = false,
                                 default = nil)
  if valid_606494 != nil:
    section.add "PlatformArn", valid_606494
  var valid_606495 = query.getOrDefault("OptionsToRemove")
  valid_606495 = validateParameter(valid_606495, JArray, required = false,
                                 default = nil)
  if valid_606495 != nil:
    section.add "OptionsToRemove", valid_606495
  var valid_606496 = query.getOrDefault("Version")
  valid_606496 = validateParameter(valid_606496, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_606496 != nil:
    section.add "Version", valid_606496
  var valid_606497 = query.getOrDefault("TemplateName")
  valid_606497 = validateParameter(valid_606497, JString, required = false,
                                 default = nil)
  if valid_606497 != nil:
    section.add "TemplateName", valid_606497
  var valid_606498 = query.getOrDefault("Tier.Version")
  valid_606498 = validateParameter(valid_606498, JString, required = false,
                                 default = nil)
  if valid_606498 != nil:
    section.add "Tier.Version", valid_606498
  var valid_606499 = query.getOrDefault("Tier.Type")
  valid_606499 = validateParameter(valid_606499, JString, required = false,
                                 default = nil)
  if valid_606499 != nil:
    section.add "Tier.Type", valid_606499
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
  var valid_606500 = header.getOrDefault("X-Amz-Signature")
  valid_606500 = validateParameter(valid_606500, JString, required = false,
                                 default = nil)
  if valid_606500 != nil:
    section.add "X-Amz-Signature", valid_606500
  var valid_606501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606501 = validateParameter(valid_606501, JString, required = false,
                                 default = nil)
  if valid_606501 != nil:
    section.add "X-Amz-Content-Sha256", valid_606501
  var valid_606502 = header.getOrDefault("X-Amz-Date")
  valid_606502 = validateParameter(valid_606502, JString, required = false,
                                 default = nil)
  if valid_606502 != nil:
    section.add "X-Amz-Date", valid_606502
  var valid_606503 = header.getOrDefault("X-Amz-Credential")
  valid_606503 = validateParameter(valid_606503, JString, required = false,
                                 default = nil)
  if valid_606503 != nil:
    section.add "X-Amz-Credential", valid_606503
  var valid_606504 = header.getOrDefault("X-Amz-Security-Token")
  valid_606504 = validateParameter(valid_606504, JString, required = false,
                                 default = nil)
  if valid_606504 != nil:
    section.add "X-Amz-Security-Token", valid_606504
  var valid_606505 = header.getOrDefault("X-Amz-Algorithm")
  valid_606505 = validateParameter(valid_606505, JString, required = false,
                                 default = nil)
  if valid_606505 != nil:
    section.add "X-Amz-Algorithm", valid_606505
  var valid_606506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606506 = validateParameter(valid_606506, JString, required = false,
                                 default = nil)
  if valid_606506 != nil:
    section.add "X-Amz-SignedHeaders", valid_606506
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606507: Call_GetCreateEnvironment_606480; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Launches an environment for the specified application using the specified configuration.
  ## 
  let valid = call_606507.validator(path, query, header, formData, body)
  let scheme = call_606507.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606507.url(scheme.get, call_606507.host, call_606507.base,
                         call_606507.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606507, url, valid)

proc call*(call_606508: Call_GetCreateEnvironment_606480; ApplicationName: string;
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
  var query_606509 = newJObject()
  add(query_606509, "ApplicationName", newJString(ApplicationName))
  add(query_606509, "CNAMEPrefix", newJString(CNAMEPrefix))
  add(query_606509, "GroupName", newJString(GroupName))
  if Tags != nil:
    query_606509.add "Tags", Tags
  add(query_606509, "VersionLabel", newJString(VersionLabel))
  if OptionSettings != nil:
    query_606509.add "OptionSettings", OptionSettings
  add(query_606509, "SolutionStackName", newJString(SolutionStackName))
  add(query_606509, "Tier.Name", newJString(TierName))
  add(query_606509, "EnvironmentName", newJString(EnvironmentName))
  add(query_606509, "Action", newJString(Action))
  add(query_606509, "Description", newJString(Description))
  add(query_606509, "PlatformArn", newJString(PlatformArn))
  if OptionsToRemove != nil:
    query_606509.add "OptionsToRemove", OptionsToRemove
  add(query_606509, "Version", newJString(Version))
  add(query_606509, "TemplateName", newJString(TemplateName))
  add(query_606509, "Tier.Version", newJString(TierVersion))
  add(query_606509, "Tier.Type", newJString(TierType))
  result = call_606508.call(nil, query_606509, nil, nil, nil)

var getCreateEnvironment* = Call_GetCreateEnvironment_606480(
    name: "getCreateEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateEnvironment",
    validator: validate_GetCreateEnvironment_606481, base: "/",
    url: url_GetCreateEnvironment_606482, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreatePlatformVersion_606563 = ref object of OpenApiRestCall_605590
proc url_PostCreatePlatformVersion_606565(protocol: Scheme; host: string;
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

proc validate_PostCreatePlatformVersion_606564(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606566 = query.getOrDefault("Action")
  valid_606566 = validateParameter(valid_606566, JString, required = true,
                                 default = newJString("CreatePlatformVersion"))
  if valid_606566 != nil:
    section.add "Action", valid_606566
  var valid_606567 = query.getOrDefault("Version")
  valid_606567 = validateParameter(valid_606567, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_606567 != nil:
    section.add "Version", valid_606567
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
  var valid_606568 = header.getOrDefault("X-Amz-Signature")
  valid_606568 = validateParameter(valid_606568, JString, required = false,
                                 default = nil)
  if valid_606568 != nil:
    section.add "X-Amz-Signature", valid_606568
  var valid_606569 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606569 = validateParameter(valid_606569, JString, required = false,
                                 default = nil)
  if valid_606569 != nil:
    section.add "X-Amz-Content-Sha256", valid_606569
  var valid_606570 = header.getOrDefault("X-Amz-Date")
  valid_606570 = validateParameter(valid_606570, JString, required = false,
                                 default = nil)
  if valid_606570 != nil:
    section.add "X-Amz-Date", valid_606570
  var valid_606571 = header.getOrDefault("X-Amz-Credential")
  valid_606571 = validateParameter(valid_606571, JString, required = false,
                                 default = nil)
  if valid_606571 != nil:
    section.add "X-Amz-Credential", valid_606571
  var valid_606572 = header.getOrDefault("X-Amz-Security-Token")
  valid_606572 = validateParameter(valid_606572, JString, required = false,
                                 default = nil)
  if valid_606572 != nil:
    section.add "X-Amz-Security-Token", valid_606572
  var valid_606573 = header.getOrDefault("X-Amz-Algorithm")
  valid_606573 = validateParameter(valid_606573, JString, required = false,
                                 default = nil)
  if valid_606573 != nil:
    section.add "X-Amz-Algorithm", valid_606573
  var valid_606574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606574 = validateParameter(valid_606574, JString, required = false,
                                 default = nil)
  if valid_606574 != nil:
    section.add "X-Amz-SignedHeaders", valid_606574
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
  var valid_606575 = formData.getOrDefault("EnvironmentName")
  valid_606575 = validateParameter(valid_606575, JString, required = false,
                                 default = nil)
  if valid_606575 != nil:
    section.add "EnvironmentName", valid_606575
  var valid_606576 = formData.getOrDefault("PlatformDefinitionBundle.S3Key")
  valid_606576 = validateParameter(valid_606576, JString, required = false,
                                 default = nil)
  if valid_606576 != nil:
    section.add "PlatformDefinitionBundle.S3Key", valid_606576
  assert formData != nil, "formData argument is necessary due to required `PlatformVersion` field"
  var valid_606577 = formData.getOrDefault("PlatformVersion")
  valid_606577 = validateParameter(valid_606577, JString, required = true,
                                 default = nil)
  if valid_606577 != nil:
    section.add "PlatformVersion", valid_606577
  var valid_606578 = formData.getOrDefault("OptionSettings")
  valid_606578 = validateParameter(valid_606578, JArray, required = false,
                                 default = nil)
  if valid_606578 != nil:
    section.add "OptionSettings", valid_606578
  var valid_606579 = formData.getOrDefault("Tags")
  valid_606579 = validateParameter(valid_606579, JArray, required = false,
                                 default = nil)
  if valid_606579 != nil:
    section.add "Tags", valid_606579
  var valid_606580 = formData.getOrDefault("PlatformDefinitionBundle.S3Bucket")
  valid_606580 = validateParameter(valid_606580, JString, required = false,
                                 default = nil)
  if valid_606580 != nil:
    section.add "PlatformDefinitionBundle.S3Bucket", valid_606580
  var valid_606581 = formData.getOrDefault("PlatformName")
  valid_606581 = validateParameter(valid_606581, JString, required = true,
                                 default = nil)
  if valid_606581 != nil:
    section.add "PlatformName", valid_606581
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606582: Call_PostCreatePlatformVersion_606563; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new version of your custom platform.
  ## 
  let valid = call_606582.validator(path, query, header, formData, body)
  let scheme = call_606582.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606582.url(scheme.get, call_606582.host, call_606582.base,
                         call_606582.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606582, url, valid)

proc call*(call_606583: Call_PostCreatePlatformVersion_606563;
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
  var query_606584 = newJObject()
  var formData_606585 = newJObject()
  add(formData_606585, "EnvironmentName", newJString(EnvironmentName))
  add(formData_606585, "PlatformDefinitionBundle.S3Key",
      newJString(PlatformDefinitionBundleS3Key))
  add(formData_606585, "PlatformVersion", newJString(PlatformVersion))
  if OptionSettings != nil:
    formData_606585.add "OptionSettings", OptionSettings
  add(query_606584, "Action", newJString(Action))
  if Tags != nil:
    formData_606585.add "Tags", Tags
  add(formData_606585, "PlatformDefinitionBundle.S3Bucket",
      newJString(PlatformDefinitionBundleS3Bucket))
  add(query_606584, "Version", newJString(Version))
  add(formData_606585, "PlatformName", newJString(PlatformName))
  result = call_606583.call(nil, query_606584, nil, formData_606585, nil)

var postCreatePlatformVersion* = Call_PostCreatePlatformVersion_606563(
    name: "postCreatePlatformVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreatePlatformVersion",
    validator: validate_PostCreatePlatformVersion_606564, base: "/",
    url: url_PostCreatePlatformVersion_606565,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreatePlatformVersion_606541 = ref object of OpenApiRestCall_605590
proc url_GetCreatePlatformVersion_606543(protocol: Scheme; host: string;
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

proc validate_GetCreatePlatformVersion_606542(path: JsonNode; query: JsonNode;
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
  var valid_606544 = query.getOrDefault("PlatformName")
  valid_606544 = validateParameter(valid_606544, JString, required = true,
                                 default = nil)
  if valid_606544 != nil:
    section.add "PlatformName", valid_606544
  var valid_606545 = query.getOrDefault("PlatformVersion")
  valid_606545 = validateParameter(valid_606545, JString, required = true,
                                 default = nil)
  if valid_606545 != nil:
    section.add "PlatformVersion", valid_606545
  var valid_606546 = query.getOrDefault("Tags")
  valid_606546 = validateParameter(valid_606546, JArray, required = false,
                                 default = nil)
  if valid_606546 != nil:
    section.add "Tags", valid_606546
  var valid_606547 = query.getOrDefault("OptionSettings")
  valid_606547 = validateParameter(valid_606547, JArray, required = false,
                                 default = nil)
  if valid_606547 != nil:
    section.add "OptionSettings", valid_606547
  var valid_606548 = query.getOrDefault("PlatformDefinitionBundle.S3Bucket")
  valid_606548 = validateParameter(valid_606548, JString, required = false,
                                 default = nil)
  if valid_606548 != nil:
    section.add "PlatformDefinitionBundle.S3Bucket", valid_606548
  var valid_606549 = query.getOrDefault("EnvironmentName")
  valid_606549 = validateParameter(valid_606549, JString, required = false,
                                 default = nil)
  if valid_606549 != nil:
    section.add "EnvironmentName", valid_606549
  var valid_606550 = query.getOrDefault("Action")
  valid_606550 = validateParameter(valid_606550, JString, required = true,
                                 default = newJString("CreatePlatformVersion"))
  if valid_606550 != nil:
    section.add "Action", valid_606550
  var valid_606551 = query.getOrDefault("PlatformDefinitionBundle.S3Key")
  valid_606551 = validateParameter(valid_606551, JString, required = false,
                                 default = nil)
  if valid_606551 != nil:
    section.add "PlatformDefinitionBundle.S3Key", valid_606551
  var valid_606552 = query.getOrDefault("Version")
  valid_606552 = validateParameter(valid_606552, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_606552 != nil:
    section.add "Version", valid_606552
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
  var valid_606553 = header.getOrDefault("X-Amz-Signature")
  valid_606553 = validateParameter(valid_606553, JString, required = false,
                                 default = nil)
  if valid_606553 != nil:
    section.add "X-Amz-Signature", valid_606553
  var valid_606554 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606554 = validateParameter(valid_606554, JString, required = false,
                                 default = nil)
  if valid_606554 != nil:
    section.add "X-Amz-Content-Sha256", valid_606554
  var valid_606555 = header.getOrDefault("X-Amz-Date")
  valid_606555 = validateParameter(valid_606555, JString, required = false,
                                 default = nil)
  if valid_606555 != nil:
    section.add "X-Amz-Date", valid_606555
  var valid_606556 = header.getOrDefault("X-Amz-Credential")
  valid_606556 = validateParameter(valid_606556, JString, required = false,
                                 default = nil)
  if valid_606556 != nil:
    section.add "X-Amz-Credential", valid_606556
  var valid_606557 = header.getOrDefault("X-Amz-Security-Token")
  valid_606557 = validateParameter(valid_606557, JString, required = false,
                                 default = nil)
  if valid_606557 != nil:
    section.add "X-Amz-Security-Token", valid_606557
  var valid_606558 = header.getOrDefault("X-Amz-Algorithm")
  valid_606558 = validateParameter(valid_606558, JString, required = false,
                                 default = nil)
  if valid_606558 != nil:
    section.add "X-Amz-Algorithm", valid_606558
  var valid_606559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606559 = validateParameter(valid_606559, JString, required = false,
                                 default = nil)
  if valid_606559 != nil:
    section.add "X-Amz-SignedHeaders", valid_606559
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606560: Call_GetCreatePlatformVersion_606541; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new version of your custom platform.
  ## 
  let valid = call_606560.validator(path, query, header, formData, body)
  let scheme = call_606560.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606560.url(scheme.get, call_606560.host, call_606560.base,
                         call_606560.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606560, url, valid)

proc call*(call_606561: Call_GetCreatePlatformVersion_606541; PlatformName: string;
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
  var query_606562 = newJObject()
  add(query_606562, "PlatformName", newJString(PlatformName))
  add(query_606562, "PlatformVersion", newJString(PlatformVersion))
  if Tags != nil:
    query_606562.add "Tags", Tags
  if OptionSettings != nil:
    query_606562.add "OptionSettings", OptionSettings
  add(query_606562, "PlatformDefinitionBundle.S3Bucket",
      newJString(PlatformDefinitionBundleS3Bucket))
  add(query_606562, "EnvironmentName", newJString(EnvironmentName))
  add(query_606562, "Action", newJString(Action))
  add(query_606562, "PlatformDefinitionBundle.S3Key",
      newJString(PlatformDefinitionBundleS3Key))
  add(query_606562, "Version", newJString(Version))
  result = call_606561.call(nil, query_606562, nil, nil, nil)

var getCreatePlatformVersion* = Call_GetCreatePlatformVersion_606541(
    name: "getCreatePlatformVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreatePlatformVersion",
    validator: validate_GetCreatePlatformVersion_606542, base: "/",
    url: url_GetCreatePlatformVersion_606543, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateStorageLocation_606601 = ref object of OpenApiRestCall_605590
proc url_PostCreateStorageLocation_606603(protocol: Scheme; host: string;
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

proc validate_PostCreateStorageLocation_606602(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606604 = query.getOrDefault("Action")
  valid_606604 = validateParameter(valid_606604, JString, required = true,
                                 default = newJString("CreateStorageLocation"))
  if valid_606604 != nil:
    section.add "Action", valid_606604
  var valid_606605 = query.getOrDefault("Version")
  valid_606605 = validateParameter(valid_606605, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_606605 != nil:
    section.add "Version", valid_606605
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
  var valid_606606 = header.getOrDefault("X-Amz-Signature")
  valid_606606 = validateParameter(valid_606606, JString, required = false,
                                 default = nil)
  if valid_606606 != nil:
    section.add "X-Amz-Signature", valid_606606
  var valid_606607 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606607 = validateParameter(valid_606607, JString, required = false,
                                 default = nil)
  if valid_606607 != nil:
    section.add "X-Amz-Content-Sha256", valid_606607
  var valid_606608 = header.getOrDefault("X-Amz-Date")
  valid_606608 = validateParameter(valid_606608, JString, required = false,
                                 default = nil)
  if valid_606608 != nil:
    section.add "X-Amz-Date", valid_606608
  var valid_606609 = header.getOrDefault("X-Amz-Credential")
  valid_606609 = validateParameter(valid_606609, JString, required = false,
                                 default = nil)
  if valid_606609 != nil:
    section.add "X-Amz-Credential", valid_606609
  var valid_606610 = header.getOrDefault("X-Amz-Security-Token")
  valid_606610 = validateParameter(valid_606610, JString, required = false,
                                 default = nil)
  if valid_606610 != nil:
    section.add "X-Amz-Security-Token", valid_606610
  var valid_606611 = header.getOrDefault("X-Amz-Algorithm")
  valid_606611 = validateParameter(valid_606611, JString, required = false,
                                 default = nil)
  if valid_606611 != nil:
    section.add "X-Amz-Algorithm", valid_606611
  var valid_606612 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606612 = validateParameter(valid_606612, JString, required = false,
                                 default = nil)
  if valid_606612 != nil:
    section.add "X-Amz-SignedHeaders", valid_606612
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606613: Call_PostCreateStorageLocation_606601; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ## 
  let valid = call_606613.validator(path, query, header, formData, body)
  let scheme = call_606613.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606613.url(scheme.get, call_606613.host, call_606613.base,
                         call_606613.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606613, url, valid)

proc call*(call_606614: Call_PostCreateStorageLocation_606601;
          Action: string = "CreateStorageLocation"; Version: string = "2010-12-01"): Recallable =
  ## postCreateStorageLocation
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606615 = newJObject()
  add(query_606615, "Action", newJString(Action))
  add(query_606615, "Version", newJString(Version))
  result = call_606614.call(nil, query_606615, nil, nil, nil)

var postCreateStorageLocation* = Call_PostCreateStorageLocation_606601(
    name: "postCreateStorageLocation", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateStorageLocation",
    validator: validate_PostCreateStorageLocation_606602, base: "/",
    url: url_PostCreateStorageLocation_606603,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateStorageLocation_606586 = ref object of OpenApiRestCall_605590
proc url_GetCreateStorageLocation_606588(protocol: Scheme; host: string;
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

proc validate_GetCreateStorageLocation_606587(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606589 = query.getOrDefault("Action")
  valid_606589 = validateParameter(valid_606589, JString, required = true,
                                 default = newJString("CreateStorageLocation"))
  if valid_606589 != nil:
    section.add "Action", valid_606589
  var valid_606590 = query.getOrDefault("Version")
  valid_606590 = validateParameter(valid_606590, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_606590 != nil:
    section.add "Version", valid_606590
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
  var valid_606591 = header.getOrDefault("X-Amz-Signature")
  valid_606591 = validateParameter(valid_606591, JString, required = false,
                                 default = nil)
  if valid_606591 != nil:
    section.add "X-Amz-Signature", valid_606591
  var valid_606592 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606592 = validateParameter(valid_606592, JString, required = false,
                                 default = nil)
  if valid_606592 != nil:
    section.add "X-Amz-Content-Sha256", valid_606592
  var valid_606593 = header.getOrDefault("X-Amz-Date")
  valid_606593 = validateParameter(valid_606593, JString, required = false,
                                 default = nil)
  if valid_606593 != nil:
    section.add "X-Amz-Date", valid_606593
  var valid_606594 = header.getOrDefault("X-Amz-Credential")
  valid_606594 = validateParameter(valid_606594, JString, required = false,
                                 default = nil)
  if valid_606594 != nil:
    section.add "X-Amz-Credential", valid_606594
  var valid_606595 = header.getOrDefault("X-Amz-Security-Token")
  valid_606595 = validateParameter(valid_606595, JString, required = false,
                                 default = nil)
  if valid_606595 != nil:
    section.add "X-Amz-Security-Token", valid_606595
  var valid_606596 = header.getOrDefault("X-Amz-Algorithm")
  valid_606596 = validateParameter(valid_606596, JString, required = false,
                                 default = nil)
  if valid_606596 != nil:
    section.add "X-Amz-Algorithm", valid_606596
  var valid_606597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606597 = validateParameter(valid_606597, JString, required = false,
                                 default = nil)
  if valid_606597 != nil:
    section.add "X-Amz-SignedHeaders", valid_606597
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606598: Call_GetCreateStorageLocation_606586; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ## 
  let valid = call_606598.validator(path, query, header, formData, body)
  let scheme = call_606598.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606598.url(scheme.get, call_606598.host, call_606598.base,
                         call_606598.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606598, url, valid)

proc call*(call_606599: Call_GetCreateStorageLocation_606586;
          Action: string = "CreateStorageLocation"; Version: string = "2010-12-01"): Recallable =
  ## getCreateStorageLocation
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606600 = newJObject()
  add(query_606600, "Action", newJString(Action))
  add(query_606600, "Version", newJString(Version))
  result = call_606599.call(nil, query_606600, nil, nil, nil)

var getCreateStorageLocation* = Call_GetCreateStorageLocation_606586(
    name: "getCreateStorageLocation", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateStorageLocation",
    validator: validate_GetCreateStorageLocation_606587, base: "/",
    url: url_GetCreateStorageLocation_606588, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteApplication_606633 = ref object of OpenApiRestCall_605590
proc url_PostDeleteApplication_606635(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteApplication_606634(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606636 = query.getOrDefault("Action")
  valid_606636 = validateParameter(valid_606636, JString, required = true,
                                 default = newJString("DeleteApplication"))
  if valid_606636 != nil:
    section.add "Action", valid_606636
  var valid_606637 = query.getOrDefault("Version")
  valid_606637 = validateParameter(valid_606637, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_606637 != nil:
    section.add "Version", valid_606637
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
  var valid_606638 = header.getOrDefault("X-Amz-Signature")
  valid_606638 = validateParameter(valid_606638, JString, required = false,
                                 default = nil)
  if valid_606638 != nil:
    section.add "X-Amz-Signature", valid_606638
  var valid_606639 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606639 = validateParameter(valid_606639, JString, required = false,
                                 default = nil)
  if valid_606639 != nil:
    section.add "X-Amz-Content-Sha256", valid_606639
  var valid_606640 = header.getOrDefault("X-Amz-Date")
  valid_606640 = validateParameter(valid_606640, JString, required = false,
                                 default = nil)
  if valid_606640 != nil:
    section.add "X-Amz-Date", valid_606640
  var valid_606641 = header.getOrDefault("X-Amz-Credential")
  valid_606641 = validateParameter(valid_606641, JString, required = false,
                                 default = nil)
  if valid_606641 != nil:
    section.add "X-Amz-Credential", valid_606641
  var valid_606642 = header.getOrDefault("X-Amz-Security-Token")
  valid_606642 = validateParameter(valid_606642, JString, required = false,
                                 default = nil)
  if valid_606642 != nil:
    section.add "X-Amz-Security-Token", valid_606642
  var valid_606643 = header.getOrDefault("X-Amz-Algorithm")
  valid_606643 = validateParameter(valid_606643, JString, required = false,
                                 default = nil)
  if valid_606643 != nil:
    section.add "X-Amz-Algorithm", valid_606643
  var valid_606644 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606644 = validateParameter(valid_606644, JString, required = false,
                                 default = nil)
  if valid_606644 != nil:
    section.add "X-Amz-SignedHeaders", valid_606644
  result.add "header", section
  ## parameters in `formData` object:
  ##   TerminateEnvByForce: JBool
  ##                      : When set to true, running environments will be terminated before deleting the application.
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to delete.
  section = newJObject()
  var valid_606645 = formData.getOrDefault("TerminateEnvByForce")
  valid_606645 = validateParameter(valid_606645, JBool, required = false, default = nil)
  if valid_606645 != nil:
    section.add "TerminateEnvByForce", valid_606645
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_606646 = formData.getOrDefault("ApplicationName")
  valid_606646 = validateParameter(valid_606646, JString, required = true,
                                 default = nil)
  if valid_606646 != nil:
    section.add "ApplicationName", valid_606646
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606647: Call_PostDeleteApplication_606633; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified application along with all associated versions and configurations. The application versions will not be deleted from your Amazon S3 bucket.</p> <note> <p>You cannot delete an application that has a running environment.</p> </note>
  ## 
  let valid = call_606647.validator(path, query, header, formData, body)
  let scheme = call_606647.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606647.url(scheme.get, call_606647.host, call_606647.base,
                         call_606647.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606647, url, valid)

proc call*(call_606648: Call_PostDeleteApplication_606633; ApplicationName: string;
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
  var query_606649 = newJObject()
  var formData_606650 = newJObject()
  add(formData_606650, "TerminateEnvByForce", newJBool(TerminateEnvByForce))
  add(formData_606650, "ApplicationName", newJString(ApplicationName))
  add(query_606649, "Action", newJString(Action))
  add(query_606649, "Version", newJString(Version))
  result = call_606648.call(nil, query_606649, nil, formData_606650, nil)

var postDeleteApplication* = Call_PostDeleteApplication_606633(
    name: "postDeleteApplication", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=DeleteApplication",
    validator: validate_PostDeleteApplication_606634, base: "/",
    url: url_PostDeleteApplication_606635, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteApplication_606616 = ref object of OpenApiRestCall_605590
proc url_GetDeleteApplication_606618(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteApplication_606617(path: JsonNode; query: JsonNode;
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
  var valid_606619 = query.getOrDefault("ApplicationName")
  valid_606619 = validateParameter(valid_606619, JString, required = true,
                                 default = nil)
  if valid_606619 != nil:
    section.add "ApplicationName", valid_606619
  var valid_606620 = query.getOrDefault("Action")
  valid_606620 = validateParameter(valid_606620, JString, required = true,
                                 default = newJString("DeleteApplication"))
  if valid_606620 != nil:
    section.add "Action", valid_606620
  var valid_606621 = query.getOrDefault("TerminateEnvByForce")
  valid_606621 = validateParameter(valid_606621, JBool, required = false, default = nil)
  if valid_606621 != nil:
    section.add "TerminateEnvByForce", valid_606621
  var valid_606622 = query.getOrDefault("Version")
  valid_606622 = validateParameter(valid_606622, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_606622 != nil:
    section.add "Version", valid_606622
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
  var valid_606623 = header.getOrDefault("X-Amz-Signature")
  valid_606623 = validateParameter(valid_606623, JString, required = false,
                                 default = nil)
  if valid_606623 != nil:
    section.add "X-Amz-Signature", valid_606623
  var valid_606624 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606624 = validateParameter(valid_606624, JString, required = false,
                                 default = nil)
  if valid_606624 != nil:
    section.add "X-Amz-Content-Sha256", valid_606624
  var valid_606625 = header.getOrDefault("X-Amz-Date")
  valid_606625 = validateParameter(valid_606625, JString, required = false,
                                 default = nil)
  if valid_606625 != nil:
    section.add "X-Amz-Date", valid_606625
  var valid_606626 = header.getOrDefault("X-Amz-Credential")
  valid_606626 = validateParameter(valid_606626, JString, required = false,
                                 default = nil)
  if valid_606626 != nil:
    section.add "X-Amz-Credential", valid_606626
  var valid_606627 = header.getOrDefault("X-Amz-Security-Token")
  valid_606627 = validateParameter(valid_606627, JString, required = false,
                                 default = nil)
  if valid_606627 != nil:
    section.add "X-Amz-Security-Token", valid_606627
  var valid_606628 = header.getOrDefault("X-Amz-Algorithm")
  valid_606628 = validateParameter(valid_606628, JString, required = false,
                                 default = nil)
  if valid_606628 != nil:
    section.add "X-Amz-Algorithm", valid_606628
  var valid_606629 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606629 = validateParameter(valid_606629, JString, required = false,
                                 default = nil)
  if valid_606629 != nil:
    section.add "X-Amz-SignedHeaders", valid_606629
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606630: Call_GetDeleteApplication_606616; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified application along with all associated versions and configurations. The application versions will not be deleted from your Amazon S3 bucket.</p> <note> <p>You cannot delete an application that has a running environment.</p> </note>
  ## 
  let valid = call_606630.validator(path, query, header, formData, body)
  let scheme = call_606630.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606630.url(scheme.get, call_606630.host, call_606630.base,
                         call_606630.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606630, url, valid)

proc call*(call_606631: Call_GetDeleteApplication_606616; ApplicationName: string;
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
  var query_606632 = newJObject()
  add(query_606632, "ApplicationName", newJString(ApplicationName))
  add(query_606632, "Action", newJString(Action))
  add(query_606632, "TerminateEnvByForce", newJBool(TerminateEnvByForce))
  add(query_606632, "Version", newJString(Version))
  result = call_606631.call(nil, query_606632, nil, nil, nil)

var getDeleteApplication* = Call_GetDeleteApplication_606616(
    name: "getDeleteApplication", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=DeleteApplication",
    validator: validate_GetDeleteApplication_606617, base: "/",
    url: url_GetDeleteApplication_606618, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteApplicationVersion_606669 = ref object of OpenApiRestCall_605590
proc url_PostDeleteApplicationVersion_606671(protocol: Scheme; host: string;
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

proc validate_PostDeleteApplicationVersion_606670(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606672 = query.getOrDefault("Action")
  valid_606672 = validateParameter(valid_606672, JString, required = true, default = newJString(
      "DeleteApplicationVersion"))
  if valid_606672 != nil:
    section.add "Action", valid_606672
  var valid_606673 = query.getOrDefault("Version")
  valid_606673 = validateParameter(valid_606673, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_606673 != nil:
    section.add "Version", valid_606673
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
  var valid_606674 = header.getOrDefault("X-Amz-Signature")
  valid_606674 = validateParameter(valid_606674, JString, required = false,
                                 default = nil)
  if valid_606674 != nil:
    section.add "X-Amz-Signature", valid_606674
  var valid_606675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606675 = validateParameter(valid_606675, JString, required = false,
                                 default = nil)
  if valid_606675 != nil:
    section.add "X-Amz-Content-Sha256", valid_606675
  var valid_606676 = header.getOrDefault("X-Amz-Date")
  valid_606676 = validateParameter(valid_606676, JString, required = false,
                                 default = nil)
  if valid_606676 != nil:
    section.add "X-Amz-Date", valid_606676
  var valid_606677 = header.getOrDefault("X-Amz-Credential")
  valid_606677 = validateParameter(valid_606677, JString, required = false,
                                 default = nil)
  if valid_606677 != nil:
    section.add "X-Amz-Credential", valid_606677
  var valid_606678 = header.getOrDefault("X-Amz-Security-Token")
  valid_606678 = validateParameter(valid_606678, JString, required = false,
                                 default = nil)
  if valid_606678 != nil:
    section.add "X-Amz-Security-Token", valid_606678
  var valid_606679 = header.getOrDefault("X-Amz-Algorithm")
  valid_606679 = validateParameter(valid_606679, JString, required = false,
                                 default = nil)
  if valid_606679 != nil:
    section.add "X-Amz-Algorithm", valid_606679
  var valid_606680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606680 = validateParameter(valid_606680, JString, required = false,
                                 default = nil)
  if valid_606680 != nil:
    section.add "X-Amz-SignedHeaders", valid_606680
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
  var valid_606681 = formData.getOrDefault("VersionLabel")
  valid_606681 = validateParameter(valid_606681, JString, required = true,
                                 default = nil)
  if valid_606681 != nil:
    section.add "VersionLabel", valid_606681
  var valid_606682 = formData.getOrDefault("DeleteSourceBundle")
  valid_606682 = validateParameter(valid_606682, JBool, required = false, default = nil)
  if valid_606682 != nil:
    section.add "DeleteSourceBundle", valid_606682
  var valid_606683 = formData.getOrDefault("ApplicationName")
  valid_606683 = validateParameter(valid_606683, JString, required = true,
                                 default = nil)
  if valid_606683 != nil:
    section.add "ApplicationName", valid_606683
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606684: Call_PostDeleteApplicationVersion_606669; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified version from the specified application.</p> <note> <p>You cannot delete an application version that is associated with a running environment.</p> </note>
  ## 
  let valid = call_606684.validator(path, query, header, formData, body)
  let scheme = call_606684.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606684.url(scheme.get, call_606684.host, call_606684.base,
                         call_606684.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606684, url, valid)

proc call*(call_606685: Call_PostDeleteApplicationVersion_606669;
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
  var query_606686 = newJObject()
  var formData_606687 = newJObject()
  add(formData_606687, "VersionLabel", newJString(VersionLabel))
  add(formData_606687, "DeleteSourceBundle", newJBool(DeleteSourceBundle))
  add(formData_606687, "ApplicationName", newJString(ApplicationName))
  add(query_606686, "Action", newJString(Action))
  add(query_606686, "Version", newJString(Version))
  result = call_606685.call(nil, query_606686, nil, formData_606687, nil)

var postDeleteApplicationVersion* = Call_PostDeleteApplicationVersion_606669(
    name: "postDeleteApplicationVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteApplicationVersion",
    validator: validate_PostDeleteApplicationVersion_606670, base: "/",
    url: url_PostDeleteApplicationVersion_606671,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteApplicationVersion_606651 = ref object of OpenApiRestCall_605590
proc url_GetDeleteApplicationVersion_606653(protocol: Scheme; host: string;
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

proc validate_GetDeleteApplicationVersion_606652(path: JsonNode; query: JsonNode;
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
  var valid_606654 = query.getOrDefault("ApplicationName")
  valid_606654 = validateParameter(valid_606654, JString, required = true,
                                 default = nil)
  if valid_606654 != nil:
    section.add "ApplicationName", valid_606654
  var valid_606655 = query.getOrDefault("VersionLabel")
  valid_606655 = validateParameter(valid_606655, JString, required = true,
                                 default = nil)
  if valid_606655 != nil:
    section.add "VersionLabel", valid_606655
  var valid_606656 = query.getOrDefault("Action")
  valid_606656 = validateParameter(valid_606656, JString, required = true, default = newJString(
      "DeleteApplicationVersion"))
  if valid_606656 != nil:
    section.add "Action", valid_606656
  var valid_606657 = query.getOrDefault("Version")
  valid_606657 = validateParameter(valid_606657, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_606657 != nil:
    section.add "Version", valid_606657
  var valid_606658 = query.getOrDefault("DeleteSourceBundle")
  valid_606658 = validateParameter(valid_606658, JBool, required = false, default = nil)
  if valid_606658 != nil:
    section.add "DeleteSourceBundle", valid_606658
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
  var valid_606659 = header.getOrDefault("X-Amz-Signature")
  valid_606659 = validateParameter(valid_606659, JString, required = false,
                                 default = nil)
  if valid_606659 != nil:
    section.add "X-Amz-Signature", valid_606659
  var valid_606660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606660 = validateParameter(valid_606660, JString, required = false,
                                 default = nil)
  if valid_606660 != nil:
    section.add "X-Amz-Content-Sha256", valid_606660
  var valid_606661 = header.getOrDefault("X-Amz-Date")
  valid_606661 = validateParameter(valid_606661, JString, required = false,
                                 default = nil)
  if valid_606661 != nil:
    section.add "X-Amz-Date", valid_606661
  var valid_606662 = header.getOrDefault("X-Amz-Credential")
  valid_606662 = validateParameter(valid_606662, JString, required = false,
                                 default = nil)
  if valid_606662 != nil:
    section.add "X-Amz-Credential", valid_606662
  var valid_606663 = header.getOrDefault("X-Amz-Security-Token")
  valid_606663 = validateParameter(valid_606663, JString, required = false,
                                 default = nil)
  if valid_606663 != nil:
    section.add "X-Amz-Security-Token", valid_606663
  var valid_606664 = header.getOrDefault("X-Amz-Algorithm")
  valid_606664 = validateParameter(valid_606664, JString, required = false,
                                 default = nil)
  if valid_606664 != nil:
    section.add "X-Amz-Algorithm", valid_606664
  var valid_606665 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606665 = validateParameter(valid_606665, JString, required = false,
                                 default = nil)
  if valid_606665 != nil:
    section.add "X-Amz-SignedHeaders", valid_606665
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606666: Call_GetDeleteApplicationVersion_606651; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified version from the specified application.</p> <note> <p>You cannot delete an application version that is associated with a running environment.</p> </note>
  ## 
  let valid = call_606666.validator(path, query, header, formData, body)
  let scheme = call_606666.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606666.url(scheme.get, call_606666.host, call_606666.base,
                         call_606666.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606666, url, valid)

proc call*(call_606667: Call_GetDeleteApplicationVersion_606651;
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
  var query_606668 = newJObject()
  add(query_606668, "ApplicationName", newJString(ApplicationName))
  add(query_606668, "VersionLabel", newJString(VersionLabel))
  add(query_606668, "Action", newJString(Action))
  add(query_606668, "Version", newJString(Version))
  add(query_606668, "DeleteSourceBundle", newJBool(DeleteSourceBundle))
  result = call_606667.call(nil, query_606668, nil, nil, nil)

var getDeleteApplicationVersion* = Call_GetDeleteApplicationVersion_606651(
    name: "getDeleteApplicationVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteApplicationVersion",
    validator: validate_GetDeleteApplicationVersion_606652, base: "/",
    url: url_GetDeleteApplicationVersion_606653,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteConfigurationTemplate_606705 = ref object of OpenApiRestCall_605590
proc url_PostDeleteConfigurationTemplate_606707(protocol: Scheme; host: string;
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

proc validate_PostDeleteConfigurationTemplate_606706(path: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606708 = query.getOrDefault("Action")
  valid_606708 = validateParameter(valid_606708, JString, required = true, default = newJString(
      "DeleteConfigurationTemplate"))
  if valid_606708 != nil:
    section.add "Action", valid_606708
  var valid_606709 = query.getOrDefault("Version")
  valid_606709 = validateParameter(valid_606709, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_606709 != nil:
    section.add "Version", valid_606709
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
  var valid_606710 = header.getOrDefault("X-Amz-Signature")
  valid_606710 = validateParameter(valid_606710, JString, required = false,
                                 default = nil)
  if valid_606710 != nil:
    section.add "X-Amz-Signature", valid_606710
  var valid_606711 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606711 = validateParameter(valid_606711, JString, required = false,
                                 default = nil)
  if valid_606711 != nil:
    section.add "X-Amz-Content-Sha256", valid_606711
  var valid_606712 = header.getOrDefault("X-Amz-Date")
  valid_606712 = validateParameter(valid_606712, JString, required = false,
                                 default = nil)
  if valid_606712 != nil:
    section.add "X-Amz-Date", valid_606712
  var valid_606713 = header.getOrDefault("X-Amz-Credential")
  valid_606713 = validateParameter(valid_606713, JString, required = false,
                                 default = nil)
  if valid_606713 != nil:
    section.add "X-Amz-Credential", valid_606713
  var valid_606714 = header.getOrDefault("X-Amz-Security-Token")
  valid_606714 = validateParameter(valid_606714, JString, required = false,
                                 default = nil)
  if valid_606714 != nil:
    section.add "X-Amz-Security-Token", valid_606714
  var valid_606715 = header.getOrDefault("X-Amz-Algorithm")
  valid_606715 = validateParameter(valid_606715, JString, required = false,
                                 default = nil)
  if valid_606715 != nil:
    section.add "X-Amz-Algorithm", valid_606715
  var valid_606716 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606716 = validateParameter(valid_606716, JString, required = false,
                                 default = nil)
  if valid_606716 != nil:
    section.add "X-Amz-SignedHeaders", valid_606716
  result.add "header", section
  ## parameters in `formData` object:
  ##   TemplateName: JString (required)
  ##               : The name of the configuration template to delete.
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to delete the configuration template from.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TemplateName` field"
  var valid_606717 = formData.getOrDefault("TemplateName")
  valid_606717 = validateParameter(valid_606717, JString, required = true,
                                 default = nil)
  if valid_606717 != nil:
    section.add "TemplateName", valid_606717
  var valid_606718 = formData.getOrDefault("ApplicationName")
  valid_606718 = validateParameter(valid_606718, JString, required = true,
                                 default = nil)
  if valid_606718 != nil:
    section.add "ApplicationName", valid_606718
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606719: Call_PostDeleteConfigurationTemplate_606705;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes the specified configuration template.</p> <note> <p>When you launch an environment using a configuration template, the environment gets a copy of the template. You can delete or modify the environment's copy of the template without affecting the running environment.</p> </note>
  ## 
  let valid = call_606719.validator(path, query, header, formData, body)
  let scheme = call_606719.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606719.url(scheme.get, call_606719.host, call_606719.base,
                         call_606719.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606719, url, valid)

proc call*(call_606720: Call_PostDeleteConfigurationTemplate_606705;
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
  var query_606721 = newJObject()
  var formData_606722 = newJObject()
  add(formData_606722, "TemplateName", newJString(TemplateName))
  add(formData_606722, "ApplicationName", newJString(ApplicationName))
  add(query_606721, "Action", newJString(Action))
  add(query_606721, "Version", newJString(Version))
  result = call_606720.call(nil, query_606721, nil, formData_606722, nil)

var postDeleteConfigurationTemplate* = Call_PostDeleteConfigurationTemplate_606705(
    name: "postDeleteConfigurationTemplate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteConfigurationTemplate",
    validator: validate_PostDeleteConfigurationTemplate_606706, base: "/",
    url: url_PostDeleteConfigurationTemplate_606707,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteConfigurationTemplate_606688 = ref object of OpenApiRestCall_605590
proc url_GetDeleteConfigurationTemplate_606690(protocol: Scheme; host: string;
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

proc validate_GetDeleteConfigurationTemplate_606689(path: JsonNode;
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
  var valid_606691 = query.getOrDefault("ApplicationName")
  valid_606691 = validateParameter(valid_606691, JString, required = true,
                                 default = nil)
  if valid_606691 != nil:
    section.add "ApplicationName", valid_606691
  var valid_606692 = query.getOrDefault("Action")
  valid_606692 = validateParameter(valid_606692, JString, required = true, default = newJString(
      "DeleteConfigurationTemplate"))
  if valid_606692 != nil:
    section.add "Action", valid_606692
  var valid_606693 = query.getOrDefault("Version")
  valid_606693 = validateParameter(valid_606693, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_606693 != nil:
    section.add "Version", valid_606693
  var valid_606694 = query.getOrDefault("TemplateName")
  valid_606694 = validateParameter(valid_606694, JString, required = true,
                                 default = nil)
  if valid_606694 != nil:
    section.add "TemplateName", valid_606694
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
  var valid_606695 = header.getOrDefault("X-Amz-Signature")
  valid_606695 = validateParameter(valid_606695, JString, required = false,
                                 default = nil)
  if valid_606695 != nil:
    section.add "X-Amz-Signature", valid_606695
  var valid_606696 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606696 = validateParameter(valid_606696, JString, required = false,
                                 default = nil)
  if valid_606696 != nil:
    section.add "X-Amz-Content-Sha256", valid_606696
  var valid_606697 = header.getOrDefault("X-Amz-Date")
  valid_606697 = validateParameter(valid_606697, JString, required = false,
                                 default = nil)
  if valid_606697 != nil:
    section.add "X-Amz-Date", valid_606697
  var valid_606698 = header.getOrDefault("X-Amz-Credential")
  valid_606698 = validateParameter(valid_606698, JString, required = false,
                                 default = nil)
  if valid_606698 != nil:
    section.add "X-Amz-Credential", valid_606698
  var valid_606699 = header.getOrDefault("X-Amz-Security-Token")
  valid_606699 = validateParameter(valid_606699, JString, required = false,
                                 default = nil)
  if valid_606699 != nil:
    section.add "X-Amz-Security-Token", valid_606699
  var valid_606700 = header.getOrDefault("X-Amz-Algorithm")
  valid_606700 = validateParameter(valid_606700, JString, required = false,
                                 default = nil)
  if valid_606700 != nil:
    section.add "X-Amz-Algorithm", valid_606700
  var valid_606701 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606701 = validateParameter(valid_606701, JString, required = false,
                                 default = nil)
  if valid_606701 != nil:
    section.add "X-Amz-SignedHeaders", valid_606701
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606702: Call_GetDeleteConfigurationTemplate_606688; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified configuration template.</p> <note> <p>When you launch an environment using a configuration template, the environment gets a copy of the template. You can delete or modify the environment's copy of the template without affecting the running environment.</p> </note>
  ## 
  let valid = call_606702.validator(path, query, header, formData, body)
  let scheme = call_606702.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606702.url(scheme.get, call_606702.host, call_606702.base,
                         call_606702.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606702, url, valid)

proc call*(call_606703: Call_GetDeleteConfigurationTemplate_606688;
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
  var query_606704 = newJObject()
  add(query_606704, "ApplicationName", newJString(ApplicationName))
  add(query_606704, "Action", newJString(Action))
  add(query_606704, "Version", newJString(Version))
  add(query_606704, "TemplateName", newJString(TemplateName))
  result = call_606703.call(nil, query_606704, nil, nil, nil)

var getDeleteConfigurationTemplate* = Call_GetDeleteConfigurationTemplate_606688(
    name: "getDeleteConfigurationTemplate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteConfigurationTemplate",
    validator: validate_GetDeleteConfigurationTemplate_606689, base: "/",
    url: url_GetDeleteConfigurationTemplate_606690,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEnvironmentConfiguration_606740 = ref object of OpenApiRestCall_605590
proc url_PostDeleteEnvironmentConfiguration_606742(protocol: Scheme; host: string;
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

proc validate_PostDeleteEnvironmentConfiguration_606741(path: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606743 = query.getOrDefault("Action")
  valid_606743 = validateParameter(valid_606743, JString, required = true, default = newJString(
      "DeleteEnvironmentConfiguration"))
  if valid_606743 != nil:
    section.add "Action", valid_606743
  var valid_606744 = query.getOrDefault("Version")
  valid_606744 = validateParameter(valid_606744, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_606744 != nil:
    section.add "Version", valid_606744
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
  var valid_606745 = header.getOrDefault("X-Amz-Signature")
  valid_606745 = validateParameter(valid_606745, JString, required = false,
                                 default = nil)
  if valid_606745 != nil:
    section.add "X-Amz-Signature", valid_606745
  var valid_606746 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606746 = validateParameter(valid_606746, JString, required = false,
                                 default = nil)
  if valid_606746 != nil:
    section.add "X-Amz-Content-Sha256", valid_606746
  var valid_606747 = header.getOrDefault("X-Amz-Date")
  valid_606747 = validateParameter(valid_606747, JString, required = false,
                                 default = nil)
  if valid_606747 != nil:
    section.add "X-Amz-Date", valid_606747
  var valid_606748 = header.getOrDefault("X-Amz-Credential")
  valid_606748 = validateParameter(valid_606748, JString, required = false,
                                 default = nil)
  if valid_606748 != nil:
    section.add "X-Amz-Credential", valid_606748
  var valid_606749 = header.getOrDefault("X-Amz-Security-Token")
  valid_606749 = validateParameter(valid_606749, JString, required = false,
                                 default = nil)
  if valid_606749 != nil:
    section.add "X-Amz-Security-Token", valid_606749
  var valid_606750 = header.getOrDefault("X-Amz-Algorithm")
  valid_606750 = validateParameter(valid_606750, JString, required = false,
                                 default = nil)
  if valid_606750 != nil:
    section.add "X-Amz-Algorithm", valid_606750
  var valid_606751 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606751 = validateParameter(valid_606751, JString, required = false,
                                 default = nil)
  if valid_606751 != nil:
    section.add "X-Amz-SignedHeaders", valid_606751
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString (required)
  ##                  : The name of the environment to delete the draft configuration from.
  ##   ApplicationName: JString (required)
  ##                  : The name of the application the environment is associated with.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `EnvironmentName` field"
  var valid_606752 = formData.getOrDefault("EnvironmentName")
  valid_606752 = validateParameter(valid_606752, JString, required = true,
                                 default = nil)
  if valid_606752 != nil:
    section.add "EnvironmentName", valid_606752
  var valid_606753 = formData.getOrDefault("ApplicationName")
  valid_606753 = validateParameter(valid_606753, JString, required = true,
                                 default = nil)
  if valid_606753 != nil:
    section.add "ApplicationName", valid_606753
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606754: Call_PostDeleteEnvironmentConfiguration_606740;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes the draft configuration associated with the running environment.</p> <p>Updating a running environment with any configuration changes creates a draft configuration set. You can get the draft configuration using <a>DescribeConfigurationSettings</a> while the update is in progress or if the update fails. The <code>DeploymentStatus</code> for the draft configuration indicates whether the deployment is in process or has failed. The draft configuration remains in existence until it is deleted with this action.</p>
  ## 
  let valid = call_606754.validator(path, query, header, formData, body)
  let scheme = call_606754.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606754.url(scheme.get, call_606754.host, call_606754.base,
                         call_606754.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606754, url, valid)

proc call*(call_606755: Call_PostDeleteEnvironmentConfiguration_606740;
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
  var query_606756 = newJObject()
  var formData_606757 = newJObject()
  add(formData_606757, "EnvironmentName", newJString(EnvironmentName))
  add(formData_606757, "ApplicationName", newJString(ApplicationName))
  add(query_606756, "Action", newJString(Action))
  add(query_606756, "Version", newJString(Version))
  result = call_606755.call(nil, query_606756, nil, formData_606757, nil)

var postDeleteEnvironmentConfiguration* = Call_PostDeleteEnvironmentConfiguration_606740(
    name: "postDeleteEnvironmentConfiguration", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteEnvironmentConfiguration",
    validator: validate_PostDeleteEnvironmentConfiguration_606741, base: "/",
    url: url_PostDeleteEnvironmentConfiguration_606742,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEnvironmentConfiguration_606723 = ref object of OpenApiRestCall_605590
proc url_GetDeleteEnvironmentConfiguration_606725(protocol: Scheme; host: string;
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

proc validate_GetDeleteEnvironmentConfiguration_606724(path: JsonNode;
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
  var valid_606726 = query.getOrDefault("ApplicationName")
  valid_606726 = validateParameter(valid_606726, JString, required = true,
                                 default = nil)
  if valid_606726 != nil:
    section.add "ApplicationName", valid_606726
  var valid_606727 = query.getOrDefault("EnvironmentName")
  valid_606727 = validateParameter(valid_606727, JString, required = true,
                                 default = nil)
  if valid_606727 != nil:
    section.add "EnvironmentName", valid_606727
  var valid_606728 = query.getOrDefault("Action")
  valid_606728 = validateParameter(valid_606728, JString, required = true, default = newJString(
      "DeleteEnvironmentConfiguration"))
  if valid_606728 != nil:
    section.add "Action", valid_606728
  var valid_606729 = query.getOrDefault("Version")
  valid_606729 = validateParameter(valid_606729, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_606729 != nil:
    section.add "Version", valid_606729
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
  var valid_606730 = header.getOrDefault("X-Amz-Signature")
  valid_606730 = validateParameter(valid_606730, JString, required = false,
                                 default = nil)
  if valid_606730 != nil:
    section.add "X-Amz-Signature", valid_606730
  var valid_606731 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606731 = validateParameter(valid_606731, JString, required = false,
                                 default = nil)
  if valid_606731 != nil:
    section.add "X-Amz-Content-Sha256", valid_606731
  var valid_606732 = header.getOrDefault("X-Amz-Date")
  valid_606732 = validateParameter(valid_606732, JString, required = false,
                                 default = nil)
  if valid_606732 != nil:
    section.add "X-Amz-Date", valid_606732
  var valid_606733 = header.getOrDefault("X-Amz-Credential")
  valid_606733 = validateParameter(valid_606733, JString, required = false,
                                 default = nil)
  if valid_606733 != nil:
    section.add "X-Amz-Credential", valid_606733
  var valid_606734 = header.getOrDefault("X-Amz-Security-Token")
  valid_606734 = validateParameter(valid_606734, JString, required = false,
                                 default = nil)
  if valid_606734 != nil:
    section.add "X-Amz-Security-Token", valid_606734
  var valid_606735 = header.getOrDefault("X-Amz-Algorithm")
  valid_606735 = validateParameter(valid_606735, JString, required = false,
                                 default = nil)
  if valid_606735 != nil:
    section.add "X-Amz-Algorithm", valid_606735
  var valid_606736 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606736 = validateParameter(valid_606736, JString, required = false,
                                 default = nil)
  if valid_606736 != nil:
    section.add "X-Amz-SignedHeaders", valid_606736
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606737: Call_GetDeleteEnvironmentConfiguration_606723;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes the draft configuration associated with the running environment.</p> <p>Updating a running environment with any configuration changes creates a draft configuration set. You can get the draft configuration using <a>DescribeConfigurationSettings</a> while the update is in progress or if the update fails. The <code>DeploymentStatus</code> for the draft configuration indicates whether the deployment is in process or has failed. The draft configuration remains in existence until it is deleted with this action.</p>
  ## 
  let valid = call_606737.validator(path, query, header, formData, body)
  let scheme = call_606737.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606737.url(scheme.get, call_606737.host, call_606737.base,
                         call_606737.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606737, url, valid)

proc call*(call_606738: Call_GetDeleteEnvironmentConfiguration_606723;
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
  var query_606739 = newJObject()
  add(query_606739, "ApplicationName", newJString(ApplicationName))
  add(query_606739, "EnvironmentName", newJString(EnvironmentName))
  add(query_606739, "Action", newJString(Action))
  add(query_606739, "Version", newJString(Version))
  result = call_606738.call(nil, query_606739, nil, nil, nil)

var getDeleteEnvironmentConfiguration* = Call_GetDeleteEnvironmentConfiguration_606723(
    name: "getDeleteEnvironmentConfiguration", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteEnvironmentConfiguration",
    validator: validate_GetDeleteEnvironmentConfiguration_606724, base: "/",
    url: url_GetDeleteEnvironmentConfiguration_606725,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeletePlatformVersion_606774 = ref object of OpenApiRestCall_605590
proc url_PostDeletePlatformVersion_606776(protocol: Scheme; host: string;
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

proc validate_PostDeletePlatformVersion_606775(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606777 = query.getOrDefault("Action")
  valid_606777 = validateParameter(valid_606777, JString, required = true,
                                 default = newJString("DeletePlatformVersion"))
  if valid_606777 != nil:
    section.add "Action", valid_606777
  var valid_606778 = query.getOrDefault("Version")
  valid_606778 = validateParameter(valid_606778, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_606778 != nil:
    section.add "Version", valid_606778
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
  var valid_606779 = header.getOrDefault("X-Amz-Signature")
  valid_606779 = validateParameter(valid_606779, JString, required = false,
                                 default = nil)
  if valid_606779 != nil:
    section.add "X-Amz-Signature", valid_606779
  var valid_606780 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606780 = validateParameter(valid_606780, JString, required = false,
                                 default = nil)
  if valid_606780 != nil:
    section.add "X-Amz-Content-Sha256", valid_606780
  var valid_606781 = header.getOrDefault("X-Amz-Date")
  valid_606781 = validateParameter(valid_606781, JString, required = false,
                                 default = nil)
  if valid_606781 != nil:
    section.add "X-Amz-Date", valid_606781
  var valid_606782 = header.getOrDefault("X-Amz-Credential")
  valid_606782 = validateParameter(valid_606782, JString, required = false,
                                 default = nil)
  if valid_606782 != nil:
    section.add "X-Amz-Credential", valid_606782
  var valid_606783 = header.getOrDefault("X-Amz-Security-Token")
  valid_606783 = validateParameter(valid_606783, JString, required = false,
                                 default = nil)
  if valid_606783 != nil:
    section.add "X-Amz-Security-Token", valid_606783
  var valid_606784 = header.getOrDefault("X-Amz-Algorithm")
  valid_606784 = validateParameter(valid_606784, JString, required = false,
                                 default = nil)
  if valid_606784 != nil:
    section.add "X-Amz-Algorithm", valid_606784
  var valid_606785 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606785 = validateParameter(valid_606785, JString, required = false,
                                 default = nil)
  if valid_606785 != nil:
    section.add "X-Amz-SignedHeaders", valid_606785
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformArn: JString
  ##              : The ARN of the version of the custom platform.
  section = newJObject()
  var valid_606786 = formData.getOrDefault("PlatformArn")
  valid_606786 = validateParameter(valid_606786, JString, required = false,
                                 default = nil)
  if valid_606786 != nil:
    section.add "PlatformArn", valid_606786
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606787: Call_PostDeletePlatformVersion_606774; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified version of a custom platform.
  ## 
  let valid = call_606787.validator(path, query, header, formData, body)
  let scheme = call_606787.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606787.url(scheme.get, call_606787.host, call_606787.base,
                         call_606787.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606787, url, valid)

proc call*(call_606788: Call_PostDeletePlatformVersion_606774;
          Action: string = "DeletePlatformVersion"; Version: string = "2010-12-01";
          PlatformArn: string = ""): Recallable =
  ## postDeletePlatformVersion
  ## Deletes the specified version of a custom platform.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PlatformArn: string
  ##              : The ARN of the version of the custom platform.
  var query_606789 = newJObject()
  var formData_606790 = newJObject()
  add(query_606789, "Action", newJString(Action))
  add(query_606789, "Version", newJString(Version))
  add(formData_606790, "PlatformArn", newJString(PlatformArn))
  result = call_606788.call(nil, query_606789, nil, formData_606790, nil)

var postDeletePlatformVersion* = Call_PostDeletePlatformVersion_606774(
    name: "postDeletePlatformVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeletePlatformVersion",
    validator: validate_PostDeletePlatformVersion_606775, base: "/",
    url: url_PostDeletePlatformVersion_606776,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeletePlatformVersion_606758 = ref object of OpenApiRestCall_605590
proc url_GetDeletePlatformVersion_606760(protocol: Scheme; host: string;
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

proc validate_GetDeletePlatformVersion_606759(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606761 = query.getOrDefault("Action")
  valid_606761 = validateParameter(valid_606761, JString, required = true,
                                 default = newJString("DeletePlatformVersion"))
  if valid_606761 != nil:
    section.add "Action", valid_606761
  var valid_606762 = query.getOrDefault("PlatformArn")
  valid_606762 = validateParameter(valid_606762, JString, required = false,
                                 default = nil)
  if valid_606762 != nil:
    section.add "PlatformArn", valid_606762
  var valid_606763 = query.getOrDefault("Version")
  valid_606763 = validateParameter(valid_606763, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_606763 != nil:
    section.add "Version", valid_606763
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
  var valid_606764 = header.getOrDefault("X-Amz-Signature")
  valid_606764 = validateParameter(valid_606764, JString, required = false,
                                 default = nil)
  if valid_606764 != nil:
    section.add "X-Amz-Signature", valid_606764
  var valid_606765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606765 = validateParameter(valid_606765, JString, required = false,
                                 default = nil)
  if valid_606765 != nil:
    section.add "X-Amz-Content-Sha256", valid_606765
  var valid_606766 = header.getOrDefault("X-Amz-Date")
  valid_606766 = validateParameter(valid_606766, JString, required = false,
                                 default = nil)
  if valid_606766 != nil:
    section.add "X-Amz-Date", valid_606766
  var valid_606767 = header.getOrDefault("X-Amz-Credential")
  valid_606767 = validateParameter(valid_606767, JString, required = false,
                                 default = nil)
  if valid_606767 != nil:
    section.add "X-Amz-Credential", valid_606767
  var valid_606768 = header.getOrDefault("X-Amz-Security-Token")
  valid_606768 = validateParameter(valid_606768, JString, required = false,
                                 default = nil)
  if valid_606768 != nil:
    section.add "X-Amz-Security-Token", valid_606768
  var valid_606769 = header.getOrDefault("X-Amz-Algorithm")
  valid_606769 = validateParameter(valid_606769, JString, required = false,
                                 default = nil)
  if valid_606769 != nil:
    section.add "X-Amz-Algorithm", valid_606769
  var valid_606770 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606770 = validateParameter(valid_606770, JString, required = false,
                                 default = nil)
  if valid_606770 != nil:
    section.add "X-Amz-SignedHeaders", valid_606770
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606771: Call_GetDeletePlatformVersion_606758; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified version of a custom platform.
  ## 
  let valid = call_606771.validator(path, query, header, formData, body)
  let scheme = call_606771.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606771.url(scheme.get, call_606771.host, call_606771.base,
                         call_606771.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606771, url, valid)

proc call*(call_606772: Call_GetDeletePlatformVersion_606758;
          Action: string = "DeletePlatformVersion"; PlatformArn: string = "";
          Version: string = "2010-12-01"): Recallable =
  ## getDeletePlatformVersion
  ## Deletes the specified version of a custom platform.
  ##   Action: string (required)
  ##   PlatformArn: string
  ##              : The ARN of the version of the custom platform.
  ##   Version: string (required)
  var query_606773 = newJObject()
  add(query_606773, "Action", newJString(Action))
  add(query_606773, "PlatformArn", newJString(PlatformArn))
  add(query_606773, "Version", newJString(Version))
  result = call_606772.call(nil, query_606773, nil, nil, nil)

var getDeletePlatformVersion* = Call_GetDeletePlatformVersion_606758(
    name: "getDeletePlatformVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeletePlatformVersion",
    validator: validate_GetDeletePlatformVersion_606759, base: "/",
    url: url_GetDeletePlatformVersion_606760, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAccountAttributes_606806 = ref object of OpenApiRestCall_605590
proc url_PostDescribeAccountAttributes_606808(protocol: Scheme; host: string;
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

proc validate_PostDescribeAccountAttributes_606807(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606809 = query.getOrDefault("Action")
  valid_606809 = validateParameter(valid_606809, JString, required = true, default = newJString(
      "DescribeAccountAttributes"))
  if valid_606809 != nil:
    section.add "Action", valid_606809
  var valid_606810 = query.getOrDefault("Version")
  valid_606810 = validateParameter(valid_606810, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_606810 != nil:
    section.add "Version", valid_606810
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
  var valid_606811 = header.getOrDefault("X-Amz-Signature")
  valid_606811 = validateParameter(valid_606811, JString, required = false,
                                 default = nil)
  if valid_606811 != nil:
    section.add "X-Amz-Signature", valid_606811
  var valid_606812 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606812 = validateParameter(valid_606812, JString, required = false,
                                 default = nil)
  if valid_606812 != nil:
    section.add "X-Amz-Content-Sha256", valid_606812
  var valid_606813 = header.getOrDefault("X-Amz-Date")
  valid_606813 = validateParameter(valid_606813, JString, required = false,
                                 default = nil)
  if valid_606813 != nil:
    section.add "X-Amz-Date", valid_606813
  var valid_606814 = header.getOrDefault("X-Amz-Credential")
  valid_606814 = validateParameter(valid_606814, JString, required = false,
                                 default = nil)
  if valid_606814 != nil:
    section.add "X-Amz-Credential", valid_606814
  var valid_606815 = header.getOrDefault("X-Amz-Security-Token")
  valid_606815 = validateParameter(valid_606815, JString, required = false,
                                 default = nil)
  if valid_606815 != nil:
    section.add "X-Amz-Security-Token", valid_606815
  var valid_606816 = header.getOrDefault("X-Amz-Algorithm")
  valid_606816 = validateParameter(valid_606816, JString, required = false,
                                 default = nil)
  if valid_606816 != nil:
    section.add "X-Amz-Algorithm", valid_606816
  var valid_606817 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606817 = validateParameter(valid_606817, JString, required = false,
                                 default = nil)
  if valid_606817 != nil:
    section.add "X-Amz-SignedHeaders", valid_606817
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606818: Call_PostDescribeAccountAttributes_606806; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ## 
  let valid = call_606818.validator(path, query, header, formData, body)
  let scheme = call_606818.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606818.url(scheme.get, call_606818.host, call_606818.base,
                         call_606818.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606818, url, valid)

proc call*(call_606819: Call_PostDescribeAccountAttributes_606806;
          Action: string = "DescribeAccountAttributes";
          Version: string = "2010-12-01"): Recallable =
  ## postDescribeAccountAttributes
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606820 = newJObject()
  add(query_606820, "Action", newJString(Action))
  add(query_606820, "Version", newJString(Version))
  result = call_606819.call(nil, query_606820, nil, nil, nil)

var postDescribeAccountAttributes* = Call_PostDescribeAccountAttributes_606806(
    name: "postDescribeAccountAttributes", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeAccountAttributes",
    validator: validate_PostDescribeAccountAttributes_606807, base: "/",
    url: url_PostDescribeAccountAttributes_606808,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAccountAttributes_606791 = ref object of OpenApiRestCall_605590
proc url_GetDescribeAccountAttributes_606793(protocol: Scheme; host: string;
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

proc validate_GetDescribeAccountAttributes_606792(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606794 = query.getOrDefault("Action")
  valid_606794 = validateParameter(valid_606794, JString, required = true, default = newJString(
      "DescribeAccountAttributes"))
  if valid_606794 != nil:
    section.add "Action", valid_606794
  var valid_606795 = query.getOrDefault("Version")
  valid_606795 = validateParameter(valid_606795, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_606795 != nil:
    section.add "Version", valid_606795
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
  var valid_606796 = header.getOrDefault("X-Amz-Signature")
  valid_606796 = validateParameter(valid_606796, JString, required = false,
                                 default = nil)
  if valid_606796 != nil:
    section.add "X-Amz-Signature", valid_606796
  var valid_606797 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606797 = validateParameter(valid_606797, JString, required = false,
                                 default = nil)
  if valid_606797 != nil:
    section.add "X-Amz-Content-Sha256", valid_606797
  var valid_606798 = header.getOrDefault("X-Amz-Date")
  valid_606798 = validateParameter(valid_606798, JString, required = false,
                                 default = nil)
  if valid_606798 != nil:
    section.add "X-Amz-Date", valid_606798
  var valid_606799 = header.getOrDefault("X-Amz-Credential")
  valid_606799 = validateParameter(valid_606799, JString, required = false,
                                 default = nil)
  if valid_606799 != nil:
    section.add "X-Amz-Credential", valid_606799
  var valid_606800 = header.getOrDefault("X-Amz-Security-Token")
  valid_606800 = validateParameter(valid_606800, JString, required = false,
                                 default = nil)
  if valid_606800 != nil:
    section.add "X-Amz-Security-Token", valid_606800
  var valid_606801 = header.getOrDefault("X-Amz-Algorithm")
  valid_606801 = validateParameter(valid_606801, JString, required = false,
                                 default = nil)
  if valid_606801 != nil:
    section.add "X-Amz-Algorithm", valid_606801
  var valid_606802 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606802 = validateParameter(valid_606802, JString, required = false,
                                 default = nil)
  if valid_606802 != nil:
    section.add "X-Amz-SignedHeaders", valid_606802
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606803: Call_GetDescribeAccountAttributes_606791; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ## 
  let valid = call_606803.validator(path, query, header, formData, body)
  let scheme = call_606803.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606803.url(scheme.get, call_606803.host, call_606803.base,
                         call_606803.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606803, url, valid)

proc call*(call_606804: Call_GetDescribeAccountAttributes_606791;
          Action: string = "DescribeAccountAttributes";
          Version: string = "2010-12-01"): Recallable =
  ## getDescribeAccountAttributes
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606805 = newJObject()
  add(query_606805, "Action", newJString(Action))
  add(query_606805, "Version", newJString(Version))
  result = call_606804.call(nil, query_606805, nil, nil, nil)

var getDescribeAccountAttributes* = Call_GetDescribeAccountAttributes_606791(
    name: "getDescribeAccountAttributes", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeAccountAttributes",
    validator: validate_GetDescribeAccountAttributes_606792, base: "/",
    url: url_GetDescribeAccountAttributes_606793,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeApplicationVersions_606840 = ref object of OpenApiRestCall_605590
proc url_PostDescribeApplicationVersions_606842(protocol: Scheme; host: string;
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

proc validate_PostDescribeApplicationVersions_606841(path: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606843 = query.getOrDefault("Action")
  valid_606843 = validateParameter(valid_606843, JString, required = true, default = newJString(
      "DescribeApplicationVersions"))
  if valid_606843 != nil:
    section.add "Action", valid_606843
  var valid_606844 = query.getOrDefault("Version")
  valid_606844 = validateParameter(valid_606844, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_606844 != nil:
    section.add "Version", valid_606844
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
  var valid_606845 = header.getOrDefault("X-Amz-Signature")
  valid_606845 = validateParameter(valid_606845, JString, required = false,
                                 default = nil)
  if valid_606845 != nil:
    section.add "X-Amz-Signature", valid_606845
  var valid_606846 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606846 = validateParameter(valid_606846, JString, required = false,
                                 default = nil)
  if valid_606846 != nil:
    section.add "X-Amz-Content-Sha256", valid_606846
  var valid_606847 = header.getOrDefault("X-Amz-Date")
  valid_606847 = validateParameter(valid_606847, JString, required = false,
                                 default = nil)
  if valid_606847 != nil:
    section.add "X-Amz-Date", valid_606847
  var valid_606848 = header.getOrDefault("X-Amz-Credential")
  valid_606848 = validateParameter(valid_606848, JString, required = false,
                                 default = nil)
  if valid_606848 != nil:
    section.add "X-Amz-Credential", valid_606848
  var valid_606849 = header.getOrDefault("X-Amz-Security-Token")
  valid_606849 = validateParameter(valid_606849, JString, required = false,
                                 default = nil)
  if valid_606849 != nil:
    section.add "X-Amz-Security-Token", valid_606849
  var valid_606850 = header.getOrDefault("X-Amz-Algorithm")
  valid_606850 = validateParameter(valid_606850, JString, required = false,
                                 default = nil)
  if valid_606850 != nil:
    section.add "X-Amz-Algorithm", valid_606850
  var valid_606851 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606851 = validateParameter(valid_606851, JString, required = false,
                                 default = nil)
  if valid_606851 != nil:
    section.add "X-Amz-SignedHeaders", valid_606851
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
  var valid_606852 = formData.getOrDefault("NextToken")
  valid_606852 = validateParameter(valid_606852, JString, required = false,
                                 default = nil)
  if valid_606852 != nil:
    section.add "NextToken", valid_606852
  var valid_606853 = formData.getOrDefault("MaxRecords")
  valid_606853 = validateParameter(valid_606853, JInt, required = false, default = nil)
  if valid_606853 != nil:
    section.add "MaxRecords", valid_606853
  var valid_606854 = formData.getOrDefault("VersionLabels")
  valid_606854 = validateParameter(valid_606854, JArray, required = false,
                                 default = nil)
  if valid_606854 != nil:
    section.add "VersionLabels", valid_606854
  var valid_606855 = formData.getOrDefault("ApplicationName")
  valid_606855 = validateParameter(valid_606855, JString, required = false,
                                 default = nil)
  if valid_606855 != nil:
    section.add "ApplicationName", valid_606855
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606856: Call_PostDescribeApplicationVersions_606840;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieve a list of application versions.
  ## 
  let valid = call_606856.validator(path, query, header, formData, body)
  let scheme = call_606856.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606856.url(scheme.get, call_606856.host, call_606856.base,
                         call_606856.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606856, url, valid)

proc call*(call_606857: Call_PostDescribeApplicationVersions_606840;
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
  var query_606858 = newJObject()
  var formData_606859 = newJObject()
  add(formData_606859, "NextToken", newJString(NextToken))
  add(formData_606859, "MaxRecords", newJInt(MaxRecords))
  if VersionLabels != nil:
    formData_606859.add "VersionLabels", VersionLabels
  add(formData_606859, "ApplicationName", newJString(ApplicationName))
  add(query_606858, "Action", newJString(Action))
  add(query_606858, "Version", newJString(Version))
  result = call_606857.call(nil, query_606858, nil, formData_606859, nil)

var postDescribeApplicationVersions* = Call_PostDescribeApplicationVersions_606840(
    name: "postDescribeApplicationVersions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplicationVersions",
    validator: validate_PostDescribeApplicationVersions_606841, base: "/",
    url: url_PostDescribeApplicationVersions_606842,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeApplicationVersions_606821 = ref object of OpenApiRestCall_605590
proc url_GetDescribeApplicationVersions_606823(protocol: Scheme; host: string;
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

proc validate_GetDescribeApplicationVersions_606822(path: JsonNode;
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
  var valid_606824 = query.getOrDefault("ApplicationName")
  valid_606824 = validateParameter(valid_606824, JString, required = false,
                                 default = nil)
  if valid_606824 != nil:
    section.add "ApplicationName", valid_606824
  var valid_606825 = query.getOrDefault("NextToken")
  valid_606825 = validateParameter(valid_606825, JString, required = false,
                                 default = nil)
  if valid_606825 != nil:
    section.add "NextToken", valid_606825
  var valid_606826 = query.getOrDefault("VersionLabels")
  valid_606826 = validateParameter(valid_606826, JArray, required = false,
                                 default = nil)
  if valid_606826 != nil:
    section.add "VersionLabels", valid_606826
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606827 = query.getOrDefault("Action")
  valid_606827 = validateParameter(valid_606827, JString, required = true, default = newJString(
      "DescribeApplicationVersions"))
  if valid_606827 != nil:
    section.add "Action", valid_606827
  var valid_606828 = query.getOrDefault("Version")
  valid_606828 = validateParameter(valid_606828, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_606828 != nil:
    section.add "Version", valid_606828
  var valid_606829 = query.getOrDefault("MaxRecords")
  valid_606829 = validateParameter(valid_606829, JInt, required = false, default = nil)
  if valid_606829 != nil:
    section.add "MaxRecords", valid_606829
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
  var valid_606830 = header.getOrDefault("X-Amz-Signature")
  valid_606830 = validateParameter(valid_606830, JString, required = false,
                                 default = nil)
  if valid_606830 != nil:
    section.add "X-Amz-Signature", valid_606830
  var valid_606831 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606831 = validateParameter(valid_606831, JString, required = false,
                                 default = nil)
  if valid_606831 != nil:
    section.add "X-Amz-Content-Sha256", valid_606831
  var valid_606832 = header.getOrDefault("X-Amz-Date")
  valid_606832 = validateParameter(valid_606832, JString, required = false,
                                 default = nil)
  if valid_606832 != nil:
    section.add "X-Amz-Date", valid_606832
  var valid_606833 = header.getOrDefault("X-Amz-Credential")
  valid_606833 = validateParameter(valid_606833, JString, required = false,
                                 default = nil)
  if valid_606833 != nil:
    section.add "X-Amz-Credential", valid_606833
  var valid_606834 = header.getOrDefault("X-Amz-Security-Token")
  valid_606834 = validateParameter(valid_606834, JString, required = false,
                                 default = nil)
  if valid_606834 != nil:
    section.add "X-Amz-Security-Token", valid_606834
  var valid_606835 = header.getOrDefault("X-Amz-Algorithm")
  valid_606835 = validateParameter(valid_606835, JString, required = false,
                                 default = nil)
  if valid_606835 != nil:
    section.add "X-Amz-Algorithm", valid_606835
  var valid_606836 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606836 = validateParameter(valid_606836, JString, required = false,
                                 default = nil)
  if valid_606836 != nil:
    section.add "X-Amz-SignedHeaders", valid_606836
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606837: Call_GetDescribeApplicationVersions_606821; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a list of application versions.
  ## 
  let valid = call_606837.validator(path, query, header, formData, body)
  let scheme = call_606837.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606837.url(scheme.get, call_606837.host, call_606837.base,
                         call_606837.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606837, url, valid)

proc call*(call_606838: Call_GetDescribeApplicationVersions_606821;
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
  var query_606839 = newJObject()
  add(query_606839, "ApplicationName", newJString(ApplicationName))
  add(query_606839, "NextToken", newJString(NextToken))
  if VersionLabels != nil:
    query_606839.add "VersionLabels", VersionLabels
  add(query_606839, "Action", newJString(Action))
  add(query_606839, "Version", newJString(Version))
  add(query_606839, "MaxRecords", newJInt(MaxRecords))
  result = call_606838.call(nil, query_606839, nil, nil, nil)

var getDescribeApplicationVersions* = Call_GetDescribeApplicationVersions_606821(
    name: "getDescribeApplicationVersions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplicationVersions",
    validator: validate_GetDescribeApplicationVersions_606822, base: "/",
    url: url_GetDescribeApplicationVersions_606823,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeApplications_606876 = ref object of OpenApiRestCall_605590
proc url_PostDescribeApplications_606878(protocol: Scheme; host: string;
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

proc validate_PostDescribeApplications_606877(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606879 = query.getOrDefault("Action")
  valid_606879 = validateParameter(valid_606879, JString, required = true,
                                 default = newJString("DescribeApplications"))
  if valid_606879 != nil:
    section.add "Action", valid_606879
  var valid_606880 = query.getOrDefault("Version")
  valid_606880 = validateParameter(valid_606880, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_606880 != nil:
    section.add "Version", valid_606880
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
  var valid_606881 = header.getOrDefault("X-Amz-Signature")
  valid_606881 = validateParameter(valid_606881, JString, required = false,
                                 default = nil)
  if valid_606881 != nil:
    section.add "X-Amz-Signature", valid_606881
  var valid_606882 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606882 = validateParameter(valid_606882, JString, required = false,
                                 default = nil)
  if valid_606882 != nil:
    section.add "X-Amz-Content-Sha256", valid_606882
  var valid_606883 = header.getOrDefault("X-Amz-Date")
  valid_606883 = validateParameter(valid_606883, JString, required = false,
                                 default = nil)
  if valid_606883 != nil:
    section.add "X-Amz-Date", valid_606883
  var valid_606884 = header.getOrDefault("X-Amz-Credential")
  valid_606884 = validateParameter(valid_606884, JString, required = false,
                                 default = nil)
  if valid_606884 != nil:
    section.add "X-Amz-Credential", valid_606884
  var valid_606885 = header.getOrDefault("X-Amz-Security-Token")
  valid_606885 = validateParameter(valid_606885, JString, required = false,
                                 default = nil)
  if valid_606885 != nil:
    section.add "X-Amz-Security-Token", valid_606885
  var valid_606886 = header.getOrDefault("X-Amz-Algorithm")
  valid_606886 = validateParameter(valid_606886, JString, required = false,
                                 default = nil)
  if valid_606886 != nil:
    section.add "X-Amz-Algorithm", valid_606886
  var valid_606887 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606887 = validateParameter(valid_606887, JString, required = false,
                                 default = nil)
  if valid_606887 != nil:
    section.add "X-Amz-SignedHeaders", valid_606887
  result.add "header", section
  ## parameters in `formData` object:
  ##   ApplicationNames: JArray
  ##                   : If specified, AWS Elastic Beanstalk restricts the returned descriptions to only include those with the specified names.
  section = newJObject()
  var valid_606888 = formData.getOrDefault("ApplicationNames")
  valid_606888 = validateParameter(valid_606888, JArray, required = false,
                                 default = nil)
  if valid_606888 != nil:
    section.add "ApplicationNames", valid_606888
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606889: Call_PostDescribeApplications_606876; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the descriptions of existing applications.
  ## 
  let valid = call_606889.validator(path, query, header, formData, body)
  let scheme = call_606889.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606889.url(scheme.get, call_606889.host, call_606889.base,
                         call_606889.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606889, url, valid)

proc call*(call_606890: Call_PostDescribeApplications_606876;
          ApplicationNames: JsonNode = nil; Action: string = "DescribeApplications";
          Version: string = "2010-12-01"): Recallable =
  ## postDescribeApplications
  ## Returns the descriptions of existing applications.
  ##   ApplicationNames: JArray
  ##                   : If specified, AWS Elastic Beanstalk restricts the returned descriptions to only include those with the specified names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606891 = newJObject()
  var formData_606892 = newJObject()
  if ApplicationNames != nil:
    formData_606892.add "ApplicationNames", ApplicationNames
  add(query_606891, "Action", newJString(Action))
  add(query_606891, "Version", newJString(Version))
  result = call_606890.call(nil, query_606891, nil, formData_606892, nil)

var postDescribeApplications* = Call_PostDescribeApplications_606876(
    name: "postDescribeApplications", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplications",
    validator: validate_PostDescribeApplications_606877, base: "/",
    url: url_PostDescribeApplications_606878, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeApplications_606860 = ref object of OpenApiRestCall_605590
proc url_GetDescribeApplications_606862(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeApplications_606861(path: JsonNode; query: JsonNode;
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
  var valid_606863 = query.getOrDefault("ApplicationNames")
  valid_606863 = validateParameter(valid_606863, JArray, required = false,
                                 default = nil)
  if valid_606863 != nil:
    section.add "ApplicationNames", valid_606863
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606864 = query.getOrDefault("Action")
  valid_606864 = validateParameter(valid_606864, JString, required = true,
                                 default = newJString("DescribeApplications"))
  if valid_606864 != nil:
    section.add "Action", valid_606864
  var valid_606865 = query.getOrDefault("Version")
  valid_606865 = validateParameter(valid_606865, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_606865 != nil:
    section.add "Version", valid_606865
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
  var valid_606866 = header.getOrDefault("X-Amz-Signature")
  valid_606866 = validateParameter(valid_606866, JString, required = false,
                                 default = nil)
  if valid_606866 != nil:
    section.add "X-Amz-Signature", valid_606866
  var valid_606867 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606867 = validateParameter(valid_606867, JString, required = false,
                                 default = nil)
  if valid_606867 != nil:
    section.add "X-Amz-Content-Sha256", valid_606867
  var valid_606868 = header.getOrDefault("X-Amz-Date")
  valid_606868 = validateParameter(valid_606868, JString, required = false,
                                 default = nil)
  if valid_606868 != nil:
    section.add "X-Amz-Date", valid_606868
  var valid_606869 = header.getOrDefault("X-Amz-Credential")
  valid_606869 = validateParameter(valid_606869, JString, required = false,
                                 default = nil)
  if valid_606869 != nil:
    section.add "X-Amz-Credential", valid_606869
  var valid_606870 = header.getOrDefault("X-Amz-Security-Token")
  valid_606870 = validateParameter(valid_606870, JString, required = false,
                                 default = nil)
  if valid_606870 != nil:
    section.add "X-Amz-Security-Token", valid_606870
  var valid_606871 = header.getOrDefault("X-Amz-Algorithm")
  valid_606871 = validateParameter(valid_606871, JString, required = false,
                                 default = nil)
  if valid_606871 != nil:
    section.add "X-Amz-Algorithm", valid_606871
  var valid_606872 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606872 = validateParameter(valid_606872, JString, required = false,
                                 default = nil)
  if valid_606872 != nil:
    section.add "X-Amz-SignedHeaders", valid_606872
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606873: Call_GetDescribeApplications_606860; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the descriptions of existing applications.
  ## 
  let valid = call_606873.validator(path, query, header, formData, body)
  let scheme = call_606873.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606873.url(scheme.get, call_606873.host, call_606873.base,
                         call_606873.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606873, url, valid)

proc call*(call_606874: Call_GetDescribeApplications_606860;
          ApplicationNames: JsonNode = nil; Action: string = "DescribeApplications";
          Version: string = "2010-12-01"): Recallable =
  ## getDescribeApplications
  ## Returns the descriptions of existing applications.
  ##   ApplicationNames: JArray
  ##                   : If specified, AWS Elastic Beanstalk restricts the returned descriptions to only include those with the specified names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606875 = newJObject()
  if ApplicationNames != nil:
    query_606875.add "ApplicationNames", ApplicationNames
  add(query_606875, "Action", newJString(Action))
  add(query_606875, "Version", newJString(Version))
  result = call_606874.call(nil, query_606875, nil, nil, nil)

var getDescribeApplications* = Call_GetDescribeApplications_606860(
    name: "getDescribeApplications", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplications",
    validator: validate_GetDescribeApplications_606861, base: "/",
    url: url_GetDescribeApplications_606862, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeConfigurationOptions_606914 = ref object of OpenApiRestCall_605590
proc url_PostDescribeConfigurationOptions_606916(protocol: Scheme; host: string;
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

proc validate_PostDescribeConfigurationOptions_606915(path: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606917 = query.getOrDefault("Action")
  valid_606917 = validateParameter(valid_606917, JString, required = true, default = newJString(
      "DescribeConfigurationOptions"))
  if valid_606917 != nil:
    section.add "Action", valid_606917
  var valid_606918 = query.getOrDefault("Version")
  valid_606918 = validateParameter(valid_606918, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_606918 != nil:
    section.add "Version", valid_606918
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
  var valid_606919 = header.getOrDefault("X-Amz-Signature")
  valid_606919 = validateParameter(valid_606919, JString, required = false,
                                 default = nil)
  if valid_606919 != nil:
    section.add "X-Amz-Signature", valid_606919
  var valid_606920 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606920 = validateParameter(valid_606920, JString, required = false,
                                 default = nil)
  if valid_606920 != nil:
    section.add "X-Amz-Content-Sha256", valid_606920
  var valid_606921 = header.getOrDefault("X-Amz-Date")
  valid_606921 = validateParameter(valid_606921, JString, required = false,
                                 default = nil)
  if valid_606921 != nil:
    section.add "X-Amz-Date", valid_606921
  var valid_606922 = header.getOrDefault("X-Amz-Credential")
  valid_606922 = validateParameter(valid_606922, JString, required = false,
                                 default = nil)
  if valid_606922 != nil:
    section.add "X-Amz-Credential", valid_606922
  var valid_606923 = header.getOrDefault("X-Amz-Security-Token")
  valid_606923 = validateParameter(valid_606923, JString, required = false,
                                 default = nil)
  if valid_606923 != nil:
    section.add "X-Amz-Security-Token", valid_606923
  var valid_606924 = header.getOrDefault("X-Amz-Algorithm")
  valid_606924 = validateParameter(valid_606924, JString, required = false,
                                 default = nil)
  if valid_606924 != nil:
    section.add "X-Amz-Algorithm", valid_606924
  var valid_606925 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606925 = validateParameter(valid_606925, JString, required = false,
                                 default = nil)
  if valid_606925 != nil:
    section.add "X-Amz-SignedHeaders", valid_606925
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
  var valid_606926 = formData.getOrDefault("EnvironmentName")
  valid_606926 = validateParameter(valid_606926, JString, required = false,
                                 default = nil)
  if valid_606926 != nil:
    section.add "EnvironmentName", valid_606926
  var valid_606927 = formData.getOrDefault("TemplateName")
  valid_606927 = validateParameter(valid_606927, JString, required = false,
                                 default = nil)
  if valid_606927 != nil:
    section.add "TemplateName", valid_606927
  var valid_606928 = formData.getOrDefault("Options")
  valid_606928 = validateParameter(valid_606928, JArray, required = false,
                                 default = nil)
  if valid_606928 != nil:
    section.add "Options", valid_606928
  var valid_606929 = formData.getOrDefault("ApplicationName")
  valid_606929 = validateParameter(valid_606929, JString, required = false,
                                 default = nil)
  if valid_606929 != nil:
    section.add "ApplicationName", valid_606929
  var valid_606930 = formData.getOrDefault("SolutionStackName")
  valid_606930 = validateParameter(valid_606930, JString, required = false,
                                 default = nil)
  if valid_606930 != nil:
    section.add "SolutionStackName", valid_606930
  var valid_606931 = formData.getOrDefault("PlatformArn")
  valid_606931 = validateParameter(valid_606931, JString, required = false,
                                 default = nil)
  if valid_606931 != nil:
    section.add "PlatformArn", valid_606931
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606932: Call_PostDescribeConfigurationOptions_606914;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the configuration options that are used in a particular configuration template or environment, or that a specified solution stack defines. The description includes the values the options, their default values, and an indication of the required action on a running environment if an option value is changed.
  ## 
  let valid = call_606932.validator(path, query, header, formData, body)
  let scheme = call_606932.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606932.url(scheme.get, call_606932.host, call_606932.base,
                         call_606932.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606932, url, valid)

proc call*(call_606933: Call_PostDescribeConfigurationOptions_606914;
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
  var query_606934 = newJObject()
  var formData_606935 = newJObject()
  add(formData_606935, "EnvironmentName", newJString(EnvironmentName))
  add(formData_606935, "TemplateName", newJString(TemplateName))
  if Options != nil:
    formData_606935.add "Options", Options
  add(formData_606935, "ApplicationName", newJString(ApplicationName))
  add(query_606934, "Action", newJString(Action))
  add(formData_606935, "SolutionStackName", newJString(SolutionStackName))
  add(query_606934, "Version", newJString(Version))
  add(formData_606935, "PlatformArn", newJString(PlatformArn))
  result = call_606933.call(nil, query_606934, nil, formData_606935, nil)

var postDescribeConfigurationOptions* = Call_PostDescribeConfigurationOptions_606914(
    name: "postDescribeConfigurationOptions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationOptions",
    validator: validate_PostDescribeConfigurationOptions_606915, base: "/",
    url: url_PostDescribeConfigurationOptions_606916,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeConfigurationOptions_606893 = ref object of OpenApiRestCall_605590
proc url_GetDescribeConfigurationOptions_606895(protocol: Scheme; host: string;
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

proc validate_GetDescribeConfigurationOptions_606894(path: JsonNode;
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
  var valid_606896 = query.getOrDefault("ApplicationName")
  valid_606896 = validateParameter(valid_606896, JString, required = false,
                                 default = nil)
  if valid_606896 != nil:
    section.add "ApplicationName", valid_606896
  var valid_606897 = query.getOrDefault("Options")
  valid_606897 = validateParameter(valid_606897, JArray, required = false,
                                 default = nil)
  if valid_606897 != nil:
    section.add "Options", valid_606897
  var valid_606898 = query.getOrDefault("SolutionStackName")
  valid_606898 = validateParameter(valid_606898, JString, required = false,
                                 default = nil)
  if valid_606898 != nil:
    section.add "SolutionStackName", valid_606898
  var valid_606899 = query.getOrDefault("EnvironmentName")
  valid_606899 = validateParameter(valid_606899, JString, required = false,
                                 default = nil)
  if valid_606899 != nil:
    section.add "EnvironmentName", valid_606899
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606900 = query.getOrDefault("Action")
  valid_606900 = validateParameter(valid_606900, JString, required = true, default = newJString(
      "DescribeConfigurationOptions"))
  if valid_606900 != nil:
    section.add "Action", valid_606900
  var valid_606901 = query.getOrDefault("PlatformArn")
  valid_606901 = validateParameter(valid_606901, JString, required = false,
                                 default = nil)
  if valid_606901 != nil:
    section.add "PlatformArn", valid_606901
  var valid_606902 = query.getOrDefault("Version")
  valid_606902 = validateParameter(valid_606902, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_606902 != nil:
    section.add "Version", valid_606902
  var valid_606903 = query.getOrDefault("TemplateName")
  valid_606903 = validateParameter(valid_606903, JString, required = false,
                                 default = nil)
  if valid_606903 != nil:
    section.add "TemplateName", valid_606903
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
  var valid_606904 = header.getOrDefault("X-Amz-Signature")
  valid_606904 = validateParameter(valid_606904, JString, required = false,
                                 default = nil)
  if valid_606904 != nil:
    section.add "X-Amz-Signature", valid_606904
  var valid_606905 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606905 = validateParameter(valid_606905, JString, required = false,
                                 default = nil)
  if valid_606905 != nil:
    section.add "X-Amz-Content-Sha256", valid_606905
  var valid_606906 = header.getOrDefault("X-Amz-Date")
  valid_606906 = validateParameter(valid_606906, JString, required = false,
                                 default = nil)
  if valid_606906 != nil:
    section.add "X-Amz-Date", valid_606906
  var valid_606907 = header.getOrDefault("X-Amz-Credential")
  valid_606907 = validateParameter(valid_606907, JString, required = false,
                                 default = nil)
  if valid_606907 != nil:
    section.add "X-Amz-Credential", valid_606907
  var valid_606908 = header.getOrDefault("X-Amz-Security-Token")
  valid_606908 = validateParameter(valid_606908, JString, required = false,
                                 default = nil)
  if valid_606908 != nil:
    section.add "X-Amz-Security-Token", valid_606908
  var valid_606909 = header.getOrDefault("X-Amz-Algorithm")
  valid_606909 = validateParameter(valid_606909, JString, required = false,
                                 default = nil)
  if valid_606909 != nil:
    section.add "X-Amz-Algorithm", valid_606909
  var valid_606910 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606910 = validateParameter(valid_606910, JString, required = false,
                                 default = nil)
  if valid_606910 != nil:
    section.add "X-Amz-SignedHeaders", valid_606910
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606911: Call_GetDescribeConfigurationOptions_606893;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the configuration options that are used in a particular configuration template or environment, or that a specified solution stack defines. The description includes the values the options, their default values, and an indication of the required action on a running environment if an option value is changed.
  ## 
  let valid = call_606911.validator(path, query, header, formData, body)
  let scheme = call_606911.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606911.url(scheme.get, call_606911.host, call_606911.base,
                         call_606911.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606911, url, valid)

proc call*(call_606912: Call_GetDescribeConfigurationOptions_606893;
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
  var query_606913 = newJObject()
  add(query_606913, "ApplicationName", newJString(ApplicationName))
  if Options != nil:
    query_606913.add "Options", Options
  add(query_606913, "SolutionStackName", newJString(SolutionStackName))
  add(query_606913, "EnvironmentName", newJString(EnvironmentName))
  add(query_606913, "Action", newJString(Action))
  add(query_606913, "PlatformArn", newJString(PlatformArn))
  add(query_606913, "Version", newJString(Version))
  add(query_606913, "TemplateName", newJString(TemplateName))
  result = call_606912.call(nil, query_606913, nil, nil, nil)

var getDescribeConfigurationOptions* = Call_GetDescribeConfigurationOptions_606893(
    name: "getDescribeConfigurationOptions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationOptions",
    validator: validate_GetDescribeConfigurationOptions_606894, base: "/",
    url: url_GetDescribeConfigurationOptions_606895,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeConfigurationSettings_606954 = ref object of OpenApiRestCall_605590
proc url_PostDescribeConfigurationSettings_606956(protocol: Scheme; host: string;
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

proc validate_PostDescribeConfigurationSettings_606955(path: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606957 = query.getOrDefault("Action")
  valid_606957 = validateParameter(valid_606957, JString, required = true, default = newJString(
      "DescribeConfigurationSettings"))
  if valid_606957 != nil:
    section.add "Action", valid_606957
  var valid_606958 = query.getOrDefault("Version")
  valid_606958 = validateParameter(valid_606958, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_606958 != nil:
    section.add "Version", valid_606958
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
  var valid_606959 = header.getOrDefault("X-Amz-Signature")
  valid_606959 = validateParameter(valid_606959, JString, required = false,
                                 default = nil)
  if valid_606959 != nil:
    section.add "X-Amz-Signature", valid_606959
  var valid_606960 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606960 = validateParameter(valid_606960, JString, required = false,
                                 default = nil)
  if valid_606960 != nil:
    section.add "X-Amz-Content-Sha256", valid_606960
  var valid_606961 = header.getOrDefault("X-Amz-Date")
  valid_606961 = validateParameter(valid_606961, JString, required = false,
                                 default = nil)
  if valid_606961 != nil:
    section.add "X-Amz-Date", valid_606961
  var valid_606962 = header.getOrDefault("X-Amz-Credential")
  valid_606962 = validateParameter(valid_606962, JString, required = false,
                                 default = nil)
  if valid_606962 != nil:
    section.add "X-Amz-Credential", valid_606962
  var valid_606963 = header.getOrDefault("X-Amz-Security-Token")
  valid_606963 = validateParameter(valid_606963, JString, required = false,
                                 default = nil)
  if valid_606963 != nil:
    section.add "X-Amz-Security-Token", valid_606963
  var valid_606964 = header.getOrDefault("X-Amz-Algorithm")
  valid_606964 = validateParameter(valid_606964, JString, required = false,
                                 default = nil)
  if valid_606964 != nil:
    section.add "X-Amz-Algorithm", valid_606964
  var valid_606965 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606965 = validateParameter(valid_606965, JString, required = false,
                                 default = nil)
  if valid_606965 != nil:
    section.add "X-Amz-SignedHeaders", valid_606965
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to describe.</p> <p> Condition: You must specify either this or a TemplateName, but not both. If you specify both, AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   TemplateName: JString
  ##               : <p>The name of the configuration template to describe.</p> <p> Conditional: You must specify either this parameter or an EnvironmentName, but not both. If you specify both, AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. If you do not specify either, AWS Elastic Beanstalk returns a <code>MissingRequiredParameter</code> error. </p>
  ##   ApplicationName: JString (required)
  ##                  : The application for the environment or configuration template.
  section = newJObject()
  var valid_606966 = formData.getOrDefault("EnvironmentName")
  valid_606966 = validateParameter(valid_606966, JString, required = false,
                                 default = nil)
  if valid_606966 != nil:
    section.add "EnvironmentName", valid_606966
  var valid_606967 = formData.getOrDefault("TemplateName")
  valid_606967 = validateParameter(valid_606967, JString, required = false,
                                 default = nil)
  if valid_606967 != nil:
    section.add "TemplateName", valid_606967
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_606968 = formData.getOrDefault("ApplicationName")
  valid_606968 = validateParameter(valid_606968, JString, required = true,
                                 default = nil)
  if valid_606968 != nil:
    section.add "ApplicationName", valid_606968
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606969: Call_PostDescribeConfigurationSettings_606954;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a description of the settings for the specified configuration set, that is, either a configuration template or the configuration set associated with a running environment.</p> <p>When describing the settings for the configuration set associated with a running environment, it is possible to receive two sets of setting descriptions. One is the deployed configuration set, and the other is a draft configuration of an environment that is either in the process of deployment or that failed to deploy.</p> <p>Related Topics</p> <ul> <li> <p> <a>DeleteEnvironmentConfiguration</a> </p> </li> </ul>
  ## 
  let valid = call_606969.validator(path, query, header, formData, body)
  let scheme = call_606969.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606969.url(scheme.get, call_606969.host, call_606969.base,
                         call_606969.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606969, url, valid)

proc call*(call_606970: Call_PostDescribeConfigurationSettings_606954;
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
  var query_606971 = newJObject()
  var formData_606972 = newJObject()
  add(formData_606972, "EnvironmentName", newJString(EnvironmentName))
  add(formData_606972, "TemplateName", newJString(TemplateName))
  add(formData_606972, "ApplicationName", newJString(ApplicationName))
  add(query_606971, "Action", newJString(Action))
  add(query_606971, "Version", newJString(Version))
  result = call_606970.call(nil, query_606971, nil, formData_606972, nil)

var postDescribeConfigurationSettings* = Call_PostDescribeConfigurationSettings_606954(
    name: "postDescribeConfigurationSettings", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationSettings",
    validator: validate_PostDescribeConfigurationSettings_606955, base: "/",
    url: url_PostDescribeConfigurationSettings_606956,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeConfigurationSettings_606936 = ref object of OpenApiRestCall_605590
proc url_GetDescribeConfigurationSettings_606938(protocol: Scheme; host: string;
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

proc validate_GetDescribeConfigurationSettings_606937(path: JsonNode;
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
  var valid_606939 = query.getOrDefault("ApplicationName")
  valid_606939 = validateParameter(valid_606939, JString, required = true,
                                 default = nil)
  if valid_606939 != nil:
    section.add "ApplicationName", valid_606939
  var valid_606940 = query.getOrDefault("EnvironmentName")
  valid_606940 = validateParameter(valid_606940, JString, required = false,
                                 default = nil)
  if valid_606940 != nil:
    section.add "EnvironmentName", valid_606940
  var valid_606941 = query.getOrDefault("Action")
  valid_606941 = validateParameter(valid_606941, JString, required = true, default = newJString(
      "DescribeConfigurationSettings"))
  if valid_606941 != nil:
    section.add "Action", valid_606941
  var valid_606942 = query.getOrDefault("Version")
  valid_606942 = validateParameter(valid_606942, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_606942 != nil:
    section.add "Version", valid_606942
  var valid_606943 = query.getOrDefault("TemplateName")
  valid_606943 = validateParameter(valid_606943, JString, required = false,
                                 default = nil)
  if valid_606943 != nil:
    section.add "TemplateName", valid_606943
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
  var valid_606944 = header.getOrDefault("X-Amz-Signature")
  valid_606944 = validateParameter(valid_606944, JString, required = false,
                                 default = nil)
  if valid_606944 != nil:
    section.add "X-Amz-Signature", valid_606944
  var valid_606945 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606945 = validateParameter(valid_606945, JString, required = false,
                                 default = nil)
  if valid_606945 != nil:
    section.add "X-Amz-Content-Sha256", valid_606945
  var valid_606946 = header.getOrDefault("X-Amz-Date")
  valid_606946 = validateParameter(valid_606946, JString, required = false,
                                 default = nil)
  if valid_606946 != nil:
    section.add "X-Amz-Date", valid_606946
  var valid_606947 = header.getOrDefault("X-Amz-Credential")
  valid_606947 = validateParameter(valid_606947, JString, required = false,
                                 default = nil)
  if valid_606947 != nil:
    section.add "X-Amz-Credential", valid_606947
  var valid_606948 = header.getOrDefault("X-Amz-Security-Token")
  valid_606948 = validateParameter(valid_606948, JString, required = false,
                                 default = nil)
  if valid_606948 != nil:
    section.add "X-Amz-Security-Token", valid_606948
  var valid_606949 = header.getOrDefault("X-Amz-Algorithm")
  valid_606949 = validateParameter(valid_606949, JString, required = false,
                                 default = nil)
  if valid_606949 != nil:
    section.add "X-Amz-Algorithm", valid_606949
  var valid_606950 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606950 = validateParameter(valid_606950, JString, required = false,
                                 default = nil)
  if valid_606950 != nil:
    section.add "X-Amz-SignedHeaders", valid_606950
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606951: Call_GetDescribeConfigurationSettings_606936;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a description of the settings for the specified configuration set, that is, either a configuration template or the configuration set associated with a running environment.</p> <p>When describing the settings for the configuration set associated with a running environment, it is possible to receive two sets of setting descriptions. One is the deployed configuration set, and the other is a draft configuration of an environment that is either in the process of deployment or that failed to deploy.</p> <p>Related Topics</p> <ul> <li> <p> <a>DeleteEnvironmentConfiguration</a> </p> </li> </ul>
  ## 
  let valid = call_606951.validator(path, query, header, formData, body)
  let scheme = call_606951.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606951.url(scheme.get, call_606951.host, call_606951.base,
                         call_606951.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606951, url, valid)

proc call*(call_606952: Call_GetDescribeConfigurationSettings_606936;
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
  var query_606953 = newJObject()
  add(query_606953, "ApplicationName", newJString(ApplicationName))
  add(query_606953, "EnvironmentName", newJString(EnvironmentName))
  add(query_606953, "Action", newJString(Action))
  add(query_606953, "Version", newJString(Version))
  add(query_606953, "TemplateName", newJString(TemplateName))
  result = call_606952.call(nil, query_606953, nil, nil, nil)

var getDescribeConfigurationSettings* = Call_GetDescribeConfigurationSettings_606936(
    name: "getDescribeConfigurationSettings", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationSettings",
    validator: validate_GetDescribeConfigurationSettings_606937, base: "/",
    url: url_GetDescribeConfigurationSettings_606938,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentHealth_606991 = ref object of OpenApiRestCall_605590
proc url_PostDescribeEnvironmentHealth_606993(protocol: Scheme; host: string;
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

proc validate_PostDescribeEnvironmentHealth_606992(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606994 = query.getOrDefault("Action")
  valid_606994 = validateParameter(valid_606994, JString, required = true, default = newJString(
      "DescribeEnvironmentHealth"))
  if valid_606994 != nil:
    section.add "Action", valid_606994
  var valid_606995 = query.getOrDefault("Version")
  valid_606995 = validateParameter(valid_606995, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_606995 != nil:
    section.add "Version", valid_606995
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
  var valid_606996 = header.getOrDefault("X-Amz-Signature")
  valid_606996 = validateParameter(valid_606996, JString, required = false,
                                 default = nil)
  if valid_606996 != nil:
    section.add "X-Amz-Signature", valid_606996
  var valid_606997 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606997 = validateParameter(valid_606997, JString, required = false,
                                 default = nil)
  if valid_606997 != nil:
    section.add "X-Amz-Content-Sha256", valid_606997
  var valid_606998 = header.getOrDefault("X-Amz-Date")
  valid_606998 = validateParameter(valid_606998, JString, required = false,
                                 default = nil)
  if valid_606998 != nil:
    section.add "X-Amz-Date", valid_606998
  var valid_606999 = header.getOrDefault("X-Amz-Credential")
  valid_606999 = validateParameter(valid_606999, JString, required = false,
                                 default = nil)
  if valid_606999 != nil:
    section.add "X-Amz-Credential", valid_606999
  var valid_607000 = header.getOrDefault("X-Amz-Security-Token")
  valid_607000 = validateParameter(valid_607000, JString, required = false,
                                 default = nil)
  if valid_607000 != nil:
    section.add "X-Amz-Security-Token", valid_607000
  var valid_607001 = header.getOrDefault("X-Amz-Algorithm")
  valid_607001 = validateParameter(valid_607001, JString, required = false,
                                 default = nil)
  if valid_607001 != nil:
    section.add "X-Amz-Algorithm", valid_607001
  var valid_607002 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607002 = validateParameter(valid_607002, JString, required = false,
                                 default = nil)
  if valid_607002 != nil:
    section.add "X-Amz-SignedHeaders", valid_607002
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString
  ##                  : <p>Specify the environment by name.</p> <p>You must specify either this or an EnvironmentName, or both.</p>
  ##   AttributeNames: JArray
  ##                 : Specify the response elements to return. To retrieve all attributes, set to <code>All</code>. If no attribute names are specified, returns the name of the environment.
  ##   EnvironmentId: JString
  ##                : <p>Specify the environment by ID.</p> <p>You must specify either this or an EnvironmentName, or both.</p>
  section = newJObject()
  var valid_607003 = formData.getOrDefault("EnvironmentName")
  valid_607003 = validateParameter(valid_607003, JString, required = false,
                                 default = nil)
  if valid_607003 != nil:
    section.add "EnvironmentName", valid_607003
  var valid_607004 = formData.getOrDefault("AttributeNames")
  valid_607004 = validateParameter(valid_607004, JArray, required = false,
                                 default = nil)
  if valid_607004 != nil:
    section.add "AttributeNames", valid_607004
  var valid_607005 = formData.getOrDefault("EnvironmentId")
  valid_607005 = validateParameter(valid_607005, JString, required = false,
                                 default = nil)
  if valid_607005 != nil:
    section.add "EnvironmentId", valid_607005
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607006: Call_PostDescribeEnvironmentHealth_606991; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the overall health of the specified environment. The <b>DescribeEnvironmentHealth</b> operation is only available with AWS Elastic Beanstalk Enhanced Health.
  ## 
  let valid = call_607006.validator(path, query, header, formData, body)
  let scheme = call_607006.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607006.url(scheme.get, call_607006.host, call_607006.base,
                         call_607006.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607006, url, valid)

proc call*(call_607007: Call_PostDescribeEnvironmentHealth_606991;
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
  var query_607008 = newJObject()
  var formData_607009 = newJObject()
  add(formData_607009, "EnvironmentName", newJString(EnvironmentName))
  if AttributeNames != nil:
    formData_607009.add "AttributeNames", AttributeNames
  add(query_607008, "Action", newJString(Action))
  add(formData_607009, "EnvironmentId", newJString(EnvironmentId))
  add(query_607008, "Version", newJString(Version))
  result = call_607007.call(nil, query_607008, nil, formData_607009, nil)

var postDescribeEnvironmentHealth* = Call_PostDescribeEnvironmentHealth_606991(
    name: "postDescribeEnvironmentHealth", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentHealth",
    validator: validate_PostDescribeEnvironmentHealth_606992, base: "/",
    url: url_PostDescribeEnvironmentHealth_606993,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentHealth_606973 = ref object of OpenApiRestCall_605590
proc url_GetDescribeEnvironmentHealth_606975(protocol: Scheme; host: string;
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

proc validate_GetDescribeEnvironmentHealth_606974(path: JsonNode; query: JsonNode;
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
  var valid_606976 = query.getOrDefault("AttributeNames")
  valid_606976 = validateParameter(valid_606976, JArray, required = false,
                                 default = nil)
  if valid_606976 != nil:
    section.add "AttributeNames", valid_606976
  var valid_606977 = query.getOrDefault("EnvironmentName")
  valid_606977 = validateParameter(valid_606977, JString, required = false,
                                 default = nil)
  if valid_606977 != nil:
    section.add "EnvironmentName", valid_606977
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606978 = query.getOrDefault("Action")
  valid_606978 = validateParameter(valid_606978, JString, required = true, default = newJString(
      "DescribeEnvironmentHealth"))
  if valid_606978 != nil:
    section.add "Action", valid_606978
  var valid_606979 = query.getOrDefault("Version")
  valid_606979 = validateParameter(valid_606979, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_606979 != nil:
    section.add "Version", valid_606979
  var valid_606980 = query.getOrDefault("EnvironmentId")
  valid_606980 = validateParameter(valid_606980, JString, required = false,
                                 default = nil)
  if valid_606980 != nil:
    section.add "EnvironmentId", valid_606980
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
  var valid_606981 = header.getOrDefault("X-Amz-Signature")
  valid_606981 = validateParameter(valid_606981, JString, required = false,
                                 default = nil)
  if valid_606981 != nil:
    section.add "X-Amz-Signature", valid_606981
  var valid_606982 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606982 = validateParameter(valid_606982, JString, required = false,
                                 default = nil)
  if valid_606982 != nil:
    section.add "X-Amz-Content-Sha256", valid_606982
  var valid_606983 = header.getOrDefault("X-Amz-Date")
  valid_606983 = validateParameter(valid_606983, JString, required = false,
                                 default = nil)
  if valid_606983 != nil:
    section.add "X-Amz-Date", valid_606983
  var valid_606984 = header.getOrDefault("X-Amz-Credential")
  valid_606984 = validateParameter(valid_606984, JString, required = false,
                                 default = nil)
  if valid_606984 != nil:
    section.add "X-Amz-Credential", valid_606984
  var valid_606985 = header.getOrDefault("X-Amz-Security-Token")
  valid_606985 = validateParameter(valid_606985, JString, required = false,
                                 default = nil)
  if valid_606985 != nil:
    section.add "X-Amz-Security-Token", valid_606985
  var valid_606986 = header.getOrDefault("X-Amz-Algorithm")
  valid_606986 = validateParameter(valid_606986, JString, required = false,
                                 default = nil)
  if valid_606986 != nil:
    section.add "X-Amz-Algorithm", valid_606986
  var valid_606987 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606987 = validateParameter(valid_606987, JString, required = false,
                                 default = nil)
  if valid_606987 != nil:
    section.add "X-Amz-SignedHeaders", valid_606987
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606988: Call_GetDescribeEnvironmentHealth_606973; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the overall health of the specified environment. The <b>DescribeEnvironmentHealth</b> operation is only available with AWS Elastic Beanstalk Enhanced Health.
  ## 
  let valid = call_606988.validator(path, query, header, formData, body)
  let scheme = call_606988.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606988.url(scheme.get, call_606988.host, call_606988.base,
                         call_606988.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606988, url, valid)

proc call*(call_606989: Call_GetDescribeEnvironmentHealth_606973;
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
  var query_606990 = newJObject()
  if AttributeNames != nil:
    query_606990.add "AttributeNames", AttributeNames
  add(query_606990, "EnvironmentName", newJString(EnvironmentName))
  add(query_606990, "Action", newJString(Action))
  add(query_606990, "Version", newJString(Version))
  add(query_606990, "EnvironmentId", newJString(EnvironmentId))
  result = call_606989.call(nil, query_606990, nil, nil, nil)

var getDescribeEnvironmentHealth* = Call_GetDescribeEnvironmentHealth_606973(
    name: "getDescribeEnvironmentHealth", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentHealth",
    validator: validate_GetDescribeEnvironmentHealth_606974, base: "/",
    url: url_GetDescribeEnvironmentHealth_606975,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentManagedActionHistory_607029 = ref object of OpenApiRestCall_605590
proc url_PostDescribeEnvironmentManagedActionHistory_607031(protocol: Scheme;
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

proc validate_PostDescribeEnvironmentManagedActionHistory_607030(path: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607032 = query.getOrDefault("Action")
  valid_607032 = validateParameter(valid_607032, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActionHistory"))
  if valid_607032 != nil:
    section.add "Action", valid_607032
  var valid_607033 = query.getOrDefault("Version")
  valid_607033 = validateParameter(valid_607033, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_607033 != nil:
    section.add "Version", valid_607033
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
  var valid_607034 = header.getOrDefault("X-Amz-Signature")
  valid_607034 = validateParameter(valid_607034, JString, required = false,
                                 default = nil)
  if valid_607034 != nil:
    section.add "X-Amz-Signature", valid_607034
  var valid_607035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607035 = validateParameter(valid_607035, JString, required = false,
                                 default = nil)
  if valid_607035 != nil:
    section.add "X-Amz-Content-Sha256", valid_607035
  var valid_607036 = header.getOrDefault("X-Amz-Date")
  valid_607036 = validateParameter(valid_607036, JString, required = false,
                                 default = nil)
  if valid_607036 != nil:
    section.add "X-Amz-Date", valid_607036
  var valid_607037 = header.getOrDefault("X-Amz-Credential")
  valid_607037 = validateParameter(valid_607037, JString, required = false,
                                 default = nil)
  if valid_607037 != nil:
    section.add "X-Amz-Credential", valid_607037
  var valid_607038 = header.getOrDefault("X-Amz-Security-Token")
  valid_607038 = validateParameter(valid_607038, JString, required = false,
                                 default = nil)
  if valid_607038 != nil:
    section.add "X-Amz-Security-Token", valid_607038
  var valid_607039 = header.getOrDefault("X-Amz-Algorithm")
  valid_607039 = validateParameter(valid_607039, JString, required = false,
                                 default = nil)
  if valid_607039 != nil:
    section.add "X-Amz-Algorithm", valid_607039
  var valid_607040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607040 = validateParameter(valid_607040, JString, required = false,
                                 default = nil)
  if valid_607040 != nil:
    section.add "X-Amz-SignedHeaders", valid_607040
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
  var valid_607041 = formData.getOrDefault("NextToken")
  valid_607041 = validateParameter(valid_607041, JString, required = false,
                                 default = nil)
  if valid_607041 != nil:
    section.add "NextToken", valid_607041
  var valid_607042 = formData.getOrDefault("EnvironmentName")
  valid_607042 = validateParameter(valid_607042, JString, required = false,
                                 default = nil)
  if valid_607042 != nil:
    section.add "EnvironmentName", valid_607042
  var valid_607043 = formData.getOrDefault("MaxItems")
  valid_607043 = validateParameter(valid_607043, JInt, required = false, default = nil)
  if valid_607043 != nil:
    section.add "MaxItems", valid_607043
  var valid_607044 = formData.getOrDefault("EnvironmentId")
  valid_607044 = validateParameter(valid_607044, JString, required = false,
                                 default = nil)
  if valid_607044 != nil:
    section.add "EnvironmentId", valid_607044
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607045: Call_PostDescribeEnvironmentManagedActionHistory_607029;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists an environment's completed and failed managed actions.
  ## 
  let valid = call_607045.validator(path, query, header, formData, body)
  let scheme = call_607045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607045.url(scheme.get, call_607045.host, call_607045.base,
                         call_607045.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607045, url, valid)

proc call*(call_607046: Call_PostDescribeEnvironmentManagedActionHistory_607029;
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
  var query_607047 = newJObject()
  var formData_607048 = newJObject()
  add(formData_607048, "NextToken", newJString(NextToken))
  add(formData_607048, "EnvironmentName", newJString(EnvironmentName))
  add(query_607047, "Action", newJString(Action))
  add(formData_607048, "MaxItems", newJInt(MaxItems))
  add(formData_607048, "EnvironmentId", newJString(EnvironmentId))
  add(query_607047, "Version", newJString(Version))
  result = call_607046.call(nil, query_607047, nil, formData_607048, nil)

var postDescribeEnvironmentManagedActionHistory* = Call_PostDescribeEnvironmentManagedActionHistory_607029(
    name: "postDescribeEnvironmentManagedActionHistory",
    meth: HttpMethod.HttpPost, host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActionHistory",
    validator: validate_PostDescribeEnvironmentManagedActionHistory_607030,
    base: "/", url: url_PostDescribeEnvironmentManagedActionHistory_607031,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentManagedActionHistory_607010 = ref object of OpenApiRestCall_605590
proc url_GetDescribeEnvironmentManagedActionHistory_607012(protocol: Scheme;
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

proc validate_GetDescribeEnvironmentManagedActionHistory_607011(path: JsonNode;
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
  var valid_607013 = query.getOrDefault("MaxItems")
  valid_607013 = validateParameter(valid_607013, JInt, required = false, default = nil)
  if valid_607013 != nil:
    section.add "MaxItems", valid_607013
  var valid_607014 = query.getOrDefault("NextToken")
  valid_607014 = validateParameter(valid_607014, JString, required = false,
                                 default = nil)
  if valid_607014 != nil:
    section.add "NextToken", valid_607014
  var valid_607015 = query.getOrDefault("EnvironmentName")
  valid_607015 = validateParameter(valid_607015, JString, required = false,
                                 default = nil)
  if valid_607015 != nil:
    section.add "EnvironmentName", valid_607015
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607016 = query.getOrDefault("Action")
  valid_607016 = validateParameter(valid_607016, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActionHistory"))
  if valid_607016 != nil:
    section.add "Action", valid_607016
  var valid_607017 = query.getOrDefault("Version")
  valid_607017 = validateParameter(valid_607017, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_607017 != nil:
    section.add "Version", valid_607017
  var valid_607018 = query.getOrDefault("EnvironmentId")
  valid_607018 = validateParameter(valid_607018, JString, required = false,
                                 default = nil)
  if valid_607018 != nil:
    section.add "EnvironmentId", valid_607018
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
  var valid_607019 = header.getOrDefault("X-Amz-Signature")
  valid_607019 = validateParameter(valid_607019, JString, required = false,
                                 default = nil)
  if valid_607019 != nil:
    section.add "X-Amz-Signature", valid_607019
  var valid_607020 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607020 = validateParameter(valid_607020, JString, required = false,
                                 default = nil)
  if valid_607020 != nil:
    section.add "X-Amz-Content-Sha256", valid_607020
  var valid_607021 = header.getOrDefault("X-Amz-Date")
  valid_607021 = validateParameter(valid_607021, JString, required = false,
                                 default = nil)
  if valid_607021 != nil:
    section.add "X-Amz-Date", valid_607021
  var valid_607022 = header.getOrDefault("X-Amz-Credential")
  valid_607022 = validateParameter(valid_607022, JString, required = false,
                                 default = nil)
  if valid_607022 != nil:
    section.add "X-Amz-Credential", valid_607022
  var valid_607023 = header.getOrDefault("X-Amz-Security-Token")
  valid_607023 = validateParameter(valid_607023, JString, required = false,
                                 default = nil)
  if valid_607023 != nil:
    section.add "X-Amz-Security-Token", valid_607023
  var valid_607024 = header.getOrDefault("X-Amz-Algorithm")
  valid_607024 = validateParameter(valid_607024, JString, required = false,
                                 default = nil)
  if valid_607024 != nil:
    section.add "X-Amz-Algorithm", valid_607024
  var valid_607025 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607025 = validateParameter(valid_607025, JString, required = false,
                                 default = nil)
  if valid_607025 != nil:
    section.add "X-Amz-SignedHeaders", valid_607025
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607026: Call_GetDescribeEnvironmentManagedActionHistory_607010;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists an environment's completed and failed managed actions.
  ## 
  let valid = call_607026.validator(path, query, header, formData, body)
  let scheme = call_607026.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607026.url(scheme.get, call_607026.host, call_607026.base,
                         call_607026.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607026, url, valid)

proc call*(call_607027: Call_GetDescribeEnvironmentManagedActionHistory_607010;
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
  var query_607028 = newJObject()
  add(query_607028, "MaxItems", newJInt(MaxItems))
  add(query_607028, "NextToken", newJString(NextToken))
  add(query_607028, "EnvironmentName", newJString(EnvironmentName))
  add(query_607028, "Action", newJString(Action))
  add(query_607028, "Version", newJString(Version))
  add(query_607028, "EnvironmentId", newJString(EnvironmentId))
  result = call_607027.call(nil, query_607028, nil, nil, nil)

var getDescribeEnvironmentManagedActionHistory* = Call_GetDescribeEnvironmentManagedActionHistory_607010(
    name: "getDescribeEnvironmentManagedActionHistory", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActionHistory",
    validator: validate_GetDescribeEnvironmentManagedActionHistory_607011,
    base: "/", url: url_GetDescribeEnvironmentManagedActionHistory_607012,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentManagedActions_607067 = ref object of OpenApiRestCall_605590
proc url_PostDescribeEnvironmentManagedActions_607069(protocol: Scheme;
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

proc validate_PostDescribeEnvironmentManagedActions_607068(path: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607070 = query.getOrDefault("Action")
  valid_607070 = validateParameter(valid_607070, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActions"))
  if valid_607070 != nil:
    section.add "Action", valid_607070
  var valid_607071 = query.getOrDefault("Version")
  valid_607071 = validateParameter(valid_607071, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_607071 != nil:
    section.add "Version", valid_607071
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
  var valid_607072 = header.getOrDefault("X-Amz-Signature")
  valid_607072 = validateParameter(valid_607072, JString, required = false,
                                 default = nil)
  if valid_607072 != nil:
    section.add "X-Amz-Signature", valid_607072
  var valid_607073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607073 = validateParameter(valid_607073, JString, required = false,
                                 default = nil)
  if valid_607073 != nil:
    section.add "X-Amz-Content-Sha256", valid_607073
  var valid_607074 = header.getOrDefault("X-Amz-Date")
  valid_607074 = validateParameter(valid_607074, JString, required = false,
                                 default = nil)
  if valid_607074 != nil:
    section.add "X-Amz-Date", valid_607074
  var valid_607075 = header.getOrDefault("X-Amz-Credential")
  valid_607075 = validateParameter(valid_607075, JString, required = false,
                                 default = nil)
  if valid_607075 != nil:
    section.add "X-Amz-Credential", valid_607075
  var valid_607076 = header.getOrDefault("X-Amz-Security-Token")
  valid_607076 = validateParameter(valid_607076, JString, required = false,
                                 default = nil)
  if valid_607076 != nil:
    section.add "X-Amz-Security-Token", valid_607076
  var valid_607077 = header.getOrDefault("X-Amz-Algorithm")
  valid_607077 = validateParameter(valid_607077, JString, required = false,
                                 default = nil)
  if valid_607077 != nil:
    section.add "X-Amz-Algorithm", valid_607077
  var valid_607078 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607078 = validateParameter(valid_607078, JString, required = false,
                                 default = nil)
  if valid_607078 != nil:
    section.add "X-Amz-SignedHeaders", valid_607078
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString
  ##                  : The name of the target environment.
  ##   Status: JString
  ##         : To show only actions with a particular status, specify a status.
  ##   EnvironmentId: JString
  ##                : The environment ID of the target environment.
  section = newJObject()
  var valid_607079 = formData.getOrDefault("EnvironmentName")
  valid_607079 = validateParameter(valid_607079, JString, required = false,
                                 default = nil)
  if valid_607079 != nil:
    section.add "EnvironmentName", valid_607079
  var valid_607080 = formData.getOrDefault("Status")
  valid_607080 = validateParameter(valid_607080, JString, required = false,
                                 default = newJString("Scheduled"))
  if valid_607080 != nil:
    section.add "Status", valid_607080
  var valid_607081 = formData.getOrDefault("EnvironmentId")
  valid_607081 = validateParameter(valid_607081, JString, required = false,
                                 default = nil)
  if valid_607081 != nil:
    section.add "EnvironmentId", valid_607081
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607082: Call_PostDescribeEnvironmentManagedActions_607067;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists an environment's upcoming and in-progress managed actions.
  ## 
  let valid = call_607082.validator(path, query, header, formData, body)
  let scheme = call_607082.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607082.url(scheme.get, call_607082.host, call_607082.base,
                         call_607082.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607082, url, valid)

proc call*(call_607083: Call_PostDescribeEnvironmentManagedActions_607067;
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
  var query_607084 = newJObject()
  var formData_607085 = newJObject()
  add(formData_607085, "EnvironmentName", newJString(EnvironmentName))
  add(query_607084, "Action", newJString(Action))
  add(formData_607085, "Status", newJString(Status))
  add(formData_607085, "EnvironmentId", newJString(EnvironmentId))
  add(query_607084, "Version", newJString(Version))
  result = call_607083.call(nil, query_607084, nil, formData_607085, nil)

var postDescribeEnvironmentManagedActions* = Call_PostDescribeEnvironmentManagedActions_607067(
    name: "postDescribeEnvironmentManagedActions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActions",
    validator: validate_PostDescribeEnvironmentManagedActions_607068, base: "/",
    url: url_PostDescribeEnvironmentManagedActions_607069,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentManagedActions_607049 = ref object of OpenApiRestCall_605590
proc url_GetDescribeEnvironmentManagedActions_607051(protocol: Scheme;
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

proc validate_GetDescribeEnvironmentManagedActions_607050(path: JsonNode;
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
  var valid_607052 = query.getOrDefault("Status")
  valid_607052 = validateParameter(valid_607052, JString, required = false,
                                 default = newJString("Scheduled"))
  if valid_607052 != nil:
    section.add "Status", valid_607052
  var valid_607053 = query.getOrDefault("EnvironmentName")
  valid_607053 = validateParameter(valid_607053, JString, required = false,
                                 default = nil)
  if valid_607053 != nil:
    section.add "EnvironmentName", valid_607053
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607054 = query.getOrDefault("Action")
  valid_607054 = validateParameter(valid_607054, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActions"))
  if valid_607054 != nil:
    section.add "Action", valid_607054
  var valid_607055 = query.getOrDefault("Version")
  valid_607055 = validateParameter(valid_607055, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_607055 != nil:
    section.add "Version", valid_607055
  var valid_607056 = query.getOrDefault("EnvironmentId")
  valid_607056 = validateParameter(valid_607056, JString, required = false,
                                 default = nil)
  if valid_607056 != nil:
    section.add "EnvironmentId", valid_607056
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
  var valid_607057 = header.getOrDefault("X-Amz-Signature")
  valid_607057 = validateParameter(valid_607057, JString, required = false,
                                 default = nil)
  if valid_607057 != nil:
    section.add "X-Amz-Signature", valid_607057
  var valid_607058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607058 = validateParameter(valid_607058, JString, required = false,
                                 default = nil)
  if valid_607058 != nil:
    section.add "X-Amz-Content-Sha256", valid_607058
  var valid_607059 = header.getOrDefault("X-Amz-Date")
  valid_607059 = validateParameter(valid_607059, JString, required = false,
                                 default = nil)
  if valid_607059 != nil:
    section.add "X-Amz-Date", valid_607059
  var valid_607060 = header.getOrDefault("X-Amz-Credential")
  valid_607060 = validateParameter(valid_607060, JString, required = false,
                                 default = nil)
  if valid_607060 != nil:
    section.add "X-Amz-Credential", valid_607060
  var valid_607061 = header.getOrDefault("X-Amz-Security-Token")
  valid_607061 = validateParameter(valid_607061, JString, required = false,
                                 default = nil)
  if valid_607061 != nil:
    section.add "X-Amz-Security-Token", valid_607061
  var valid_607062 = header.getOrDefault("X-Amz-Algorithm")
  valid_607062 = validateParameter(valid_607062, JString, required = false,
                                 default = nil)
  if valid_607062 != nil:
    section.add "X-Amz-Algorithm", valid_607062
  var valid_607063 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607063 = validateParameter(valid_607063, JString, required = false,
                                 default = nil)
  if valid_607063 != nil:
    section.add "X-Amz-SignedHeaders", valid_607063
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607064: Call_GetDescribeEnvironmentManagedActions_607049;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists an environment's upcoming and in-progress managed actions.
  ## 
  let valid = call_607064.validator(path, query, header, formData, body)
  let scheme = call_607064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607064.url(scheme.get, call_607064.host, call_607064.base,
                         call_607064.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607064, url, valid)

proc call*(call_607065: Call_GetDescribeEnvironmentManagedActions_607049;
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
  var query_607066 = newJObject()
  add(query_607066, "Status", newJString(Status))
  add(query_607066, "EnvironmentName", newJString(EnvironmentName))
  add(query_607066, "Action", newJString(Action))
  add(query_607066, "Version", newJString(Version))
  add(query_607066, "EnvironmentId", newJString(EnvironmentId))
  result = call_607065.call(nil, query_607066, nil, nil, nil)

var getDescribeEnvironmentManagedActions* = Call_GetDescribeEnvironmentManagedActions_607049(
    name: "getDescribeEnvironmentManagedActions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActions",
    validator: validate_GetDescribeEnvironmentManagedActions_607050, base: "/",
    url: url_GetDescribeEnvironmentManagedActions_607051,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentResources_607103 = ref object of OpenApiRestCall_605590
proc url_PostDescribeEnvironmentResources_607105(protocol: Scheme; host: string;
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

proc validate_PostDescribeEnvironmentResources_607104(path: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607106 = query.getOrDefault("Action")
  valid_607106 = validateParameter(valid_607106, JString, required = true, default = newJString(
      "DescribeEnvironmentResources"))
  if valid_607106 != nil:
    section.add "Action", valid_607106
  var valid_607107 = query.getOrDefault("Version")
  valid_607107 = validateParameter(valid_607107, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_607107 != nil:
    section.add "Version", valid_607107
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
  var valid_607108 = header.getOrDefault("X-Amz-Signature")
  valid_607108 = validateParameter(valid_607108, JString, required = false,
                                 default = nil)
  if valid_607108 != nil:
    section.add "X-Amz-Signature", valid_607108
  var valid_607109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607109 = validateParameter(valid_607109, JString, required = false,
                                 default = nil)
  if valid_607109 != nil:
    section.add "X-Amz-Content-Sha256", valid_607109
  var valid_607110 = header.getOrDefault("X-Amz-Date")
  valid_607110 = validateParameter(valid_607110, JString, required = false,
                                 default = nil)
  if valid_607110 != nil:
    section.add "X-Amz-Date", valid_607110
  var valid_607111 = header.getOrDefault("X-Amz-Credential")
  valid_607111 = validateParameter(valid_607111, JString, required = false,
                                 default = nil)
  if valid_607111 != nil:
    section.add "X-Amz-Credential", valid_607111
  var valid_607112 = header.getOrDefault("X-Amz-Security-Token")
  valid_607112 = validateParameter(valid_607112, JString, required = false,
                                 default = nil)
  if valid_607112 != nil:
    section.add "X-Amz-Security-Token", valid_607112
  var valid_607113 = header.getOrDefault("X-Amz-Algorithm")
  valid_607113 = validateParameter(valid_607113, JString, required = false,
                                 default = nil)
  if valid_607113 != nil:
    section.add "X-Amz-Algorithm", valid_607113
  var valid_607114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607114 = validateParameter(valid_607114, JString, required = false,
                                 default = nil)
  if valid_607114 != nil:
    section.add "X-Amz-SignedHeaders", valid_607114
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to retrieve AWS resource usage data.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to retrieve AWS resource usage data.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_607115 = formData.getOrDefault("EnvironmentName")
  valid_607115 = validateParameter(valid_607115, JString, required = false,
                                 default = nil)
  if valid_607115 != nil:
    section.add "EnvironmentName", valid_607115
  var valid_607116 = formData.getOrDefault("EnvironmentId")
  valid_607116 = validateParameter(valid_607116, JString, required = false,
                                 default = nil)
  if valid_607116 != nil:
    section.add "EnvironmentId", valid_607116
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607117: Call_PostDescribeEnvironmentResources_607103;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns AWS resources for this environment.
  ## 
  let valid = call_607117.validator(path, query, header, formData, body)
  let scheme = call_607117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607117.url(scheme.get, call_607117.host, call_607117.base,
                         call_607117.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607117, url, valid)

proc call*(call_607118: Call_PostDescribeEnvironmentResources_607103;
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
  var query_607119 = newJObject()
  var formData_607120 = newJObject()
  add(formData_607120, "EnvironmentName", newJString(EnvironmentName))
  add(query_607119, "Action", newJString(Action))
  add(formData_607120, "EnvironmentId", newJString(EnvironmentId))
  add(query_607119, "Version", newJString(Version))
  result = call_607118.call(nil, query_607119, nil, formData_607120, nil)

var postDescribeEnvironmentResources* = Call_PostDescribeEnvironmentResources_607103(
    name: "postDescribeEnvironmentResources", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentResources",
    validator: validate_PostDescribeEnvironmentResources_607104, base: "/",
    url: url_PostDescribeEnvironmentResources_607105,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentResources_607086 = ref object of OpenApiRestCall_605590
proc url_GetDescribeEnvironmentResources_607088(protocol: Scheme; host: string;
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

proc validate_GetDescribeEnvironmentResources_607087(path: JsonNode;
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
  var valid_607089 = query.getOrDefault("EnvironmentName")
  valid_607089 = validateParameter(valid_607089, JString, required = false,
                                 default = nil)
  if valid_607089 != nil:
    section.add "EnvironmentName", valid_607089
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607090 = query.getOrDefault("Action")
  valid_607090 = validateParameter(valid_607090, JString, required = true, default = newJString(
      "DescribeEnvironmentResources"))
  if valid_607090 != nil:
    section.add "Action", valid_607090
  var valid_607091 = query.getOrDefault("Version")
  valid_607091 = validateParameter(valid_607091, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_607091 != nil:
    section.add "Version", valid_607091
  var valid_607092 = query.getOrDefault("EnvironmentId")
  valid_607092 = validateParameter(valid_607092, JString, required = false,
                                 default = nil)
  if valid_607092 != nil:
    section.add "EnvironmentId", valid_607092
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
  var valid_607093 = header.getOrDefault("X-Amz-Signature")
  valid_607093 = validateParameter(valid_607093, JString, required = false,
                                 default = nil)
  if valid_607093 != nil:
    section.add "X-Amz-Signature", valid_607093
  var valid_607094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607094 = validateParameter(valid_607094, JString, required = false,
                                 default = nil)
  if valid_607094 != nil:
    section.add "X-Amz-Content-Sha256", valid_607094
  var valid_607095 = header.getOrDefault("X-Amz-Date")
  valid_607095 = validateParameter(valid_607095, JString, required = false,
                                 default = nil)
  if valid_607095 != nil:
    section.add "X-Amz-Date", valid_607095
  var valid_607096 = header.getOrDefault("X-Amz-Credential")
  valid_607096 = validateParameter(valid_607096, JString, required = false,
                                 default = nil)
  if valid_607096 != nil:
    section.add "X-Amz-Credential", valid_607096
  var valid_607097 = header.getOrDefault("X-Amz-Security-Token")
  valid_607097 = validateParameter(valid_607097, JString, required = false,
                                 default = nil)
  if valid_607097 != nil:
    section.add "X-Amz-Security-Token", valid_607097
  var valid_607098 = header.getOrDefault("X-Amz-Algorithm")
  valid_607098 = validateParameter(valid_607098, JString, required = false,
                                 default = nil)
  if valid_607098 != nil:
    section.add "X-Amz-Algorithm", valid_607098
  var valid_607099 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607099 = validateParameter(valid_607099, JString, required = false,
                                 default = nil)
  if valid_607099 != nil:
    section.add "X-Amz-SignedHeaders", valid_607099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607100: Call_GetDescribeEnvironmentResources_607086;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns AWS resources for this environment.
  ## 
  let valid = call_607100.validator(path, query, header, formData, body)
  let scheme = call_607100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607100.url(scheme.get, call_607100.host, call_607100.base,
                         call_607100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607100, url, valid)

proc call*(call_607101: Call_GetDescribeEnvironmentResources_607086;
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
  var query_607102 = newJObject()
  add(query_607102, "EnvironmentName", newJString(EnvironmentName))
  add(query_607102, "Action", newJString(Action))
  add(query_607102, "Version", newJString(Version))
  add(query_607102, "EnvironmentId", newJString(EnvironmentId))
  result = call_607101.call(nil, query_607102, nil, nil, nil)

var getDescribeEnvironmentResources* = Call_GetDescribeEnvironmentResources_607086(
    name: "getDescribeEnvironmentResources", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentResources",
    validator: validate_GetDescribeEnvironmentResources_607087, base: "/",
    url: url_GetDescribeEnvironmentResources_607088,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironments_607144 = ref object of OpenApiRestCall_605590
proc url_PostDescribeEnvironments_607146(protocol: Scheme; host: string;
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

proc validate_PostDescribeEnvironments_607145(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607147 = query.getOrDefault("Action")
  valid_607147 = validateParameter(valid_607147, JString, required = true,
                                 default = newJString("DescribeEnvironments"))
  if valid_607147 != nil:
    section.add "Action", valid_607147
  var valid_607148 = query.getOrDefault("Version")
  valid_607148 = validateParameter(valid_607148, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_607148 != nil:
    section.add "Version", valid_607148
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
  var valid_607149 = header.getOrDefault("X-Amz-Signature")
  valid_607149 = validateParameter(valid_607149, JString, required = false,
                                 default = nil)
  if valid_607149 != nil:
    section.add "X-Amz-Signature", valid_607149
  var valid_607150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607150 = validateParameter(valid_607150, JString, required = false,
                                 default = nil)
  if valid_607150 != nil:
    section.add "X-Amz-Content-Sha256", valid_607150
  var valid_607151 = header.getOrDefault("X-Amz-Date")
  valid_607151 = validateParameter(valid_607151, JString, required = false,
                                 default = nil)
  if valid_607151 != nil:
    section.add "X-Amz-Date", valid_607151
  var valid_607152 = header.getOrDefault("X-Amz-Credential")
  valid_607152 = validateParameter(valid_607152, JString, required = false,
                                 default = nil)
  if valid_607152 != nil:
    section.add "X-Amz-Credential", valid_607152
  var valid_607153 = header.getOrDefault("X-Amz-Security-Token")
  valid_607153 = validateParameter(valid_607153, JString, required = false,
                                 default = nil)
  if valid_607153 != nil:
    section.add "X-Amz-Security-Token", valid_607153
  var valid_607154 = header.getOrDefault("X-Amz-Algorithm")
  valid_607154 = validateParameter(valid_607154, JString, required = false,
                                 default = nil)
  if valid_607154 != nil:
    section.add "X-Amz-Algorithm", valid_607154
  var valid_607155 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607155 = validateParameter(valid_607155, JString, required = false,
                                 default = nil)
  if valid_607155 != nil:
    section.add "X-Amz-SignedHeaders", valid_607155
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
  var valid_607156 = formData.getOrDefault("EnvironmentNames")
  valid_607156 = validateParameter(valid_607156, JArray, required = false,
                                 default = nil)
  if valid_607156 != nil:
    section.add "EnvironmentNames", valid_607156
  var valid_607157 = formData.getOrDefault("MaxRecords")
  valid_607157 = validateParameter(valid_607157, JInt, required = false, default = nil)
  if valid_607157 != nil:
    section.add "MaxRecords", valid_607157
  var valid_607158 = formData.getOrDefault("VersionLabel")
  valid_607158 = validateParameter(valid_607158, JString, required = false,
                                 default = nil)
  if valid_607158 != nil:
    section.add "VersionLabel", valid_607158
  var valid_607159 = formData.getOrDefault("NextToken")
  valid_607159 = validateParameter(valid_607159, JString, required = false,
                                 default = nil)
  if valid_607159 != nil:
    section.add "NextToken", valid_607159
  var valid_607160 = formData.getOrDefault("ApplicationName")
  valid_607160 = validateParameter(valid_607160, JString, required = false,
                                 default = nil)
  if valid_607160 != nil:
    section.add "ApplicationName", valid_607160
  var valid_607161 = formData.getOrDefault("IncludedDeletedBackTo")
  valid_607161 = validateParameter(valid_607161, JString, required = false,
                                 default = nil)
  if valid_607161 != nil:
    section.add "IncludedDeletedBackTo", valid_607161
  var valid_607162 = formData.getOrDefault("EnvironmentIds")
  valid_607162 = validateParameter(valid_607162, JArray, required = false,
                                 default = nil)
  if valid_607162 != nil:
    section.add "EnvironmentIds", valid_607162
  var valid_607163 = formData.getOrDefault("IncludeDeleted")
  valid_607163 = validateParameter(valid_607163, JBool, required = false, default = nil)
  if valid_607163 != nil:
    section.add "IncludeDeleted", valid_607163
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607164: Call_PostDescribeEnvironments_607144; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns descriptions for existing environments.
  ## 
  let valid = call_607164.validator(path, query, header, formData, body)
  let scheme = call_607164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607164.url(scheme.get, call_607164.host, call_607164.base,
                         call_607164.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607164, url, valid)

proc call*(call_607165: Call_PostDescribeEnvironments_607144;
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
  var query_607166 = newJObject()
  var formData_607167 = newJObject()
  if EnvironmentNames != nil:
    formData_607167.add "EnvironmentNames", EnvironmentNames
  add(formData_607167, "MaxRecords", newJInt(MaxRecords))
  add(formData_607167, "VersionLabel", newJString(VersionLabel))
  add(formData_607167, "NextToken", newJString(NextToken))
  add(formData_607167, "ApplicationName", newJString(ApplicationName))
  add(query_607166, "Action", newJString(Action))
  add(query_607166, "Version", newJString(Version))
  add(formData_607167, "IncludedDeletedBackTo", newJString(IncludedDeletedBackTo))
  if EnvironmentIds != nil:
    formData_607167.add "EnvironmentIds", EnvironmentIds
  add(formData_607167, "IncludeDeleted", newJBool(IncludeDeleted))
  result = call_607165.call(nil, query_607166, nil, formData_607167, nil)

var postDescribeEnvironments* = Call_PostDescribeEnvironments_607144(
    name: "postDescribeEnvironments", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironments",
    validator: validate_PostDescribeEnvironments_607145, base: "/",
    url: url_PostDescribeEnvironments_607146, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironments_607121 = ref object of OpenApiRestCall_605590
proc url_GetDescribeEnvironments_607123(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeEnvironments_607122(path: JsonNode; query: JsonNode;
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
  var valid_607124 = query.getOrDefault("ApplicationName")
  valid_607124 = validateParameter(valid_607124, JString, required = false,
                                 default = nil)
  if valid_607124 != nil:
    section.add "ApplicationName", valid_607124
  var valid_607125 = query.getOrDefault("VersionLabel")
  valid_607125 = validateParameter(valid_607125, JString, required = false,
                                 default = nil)
  if valid_607125 != nil:
    section.add "VersionLabel", valid_607125
  var valid_607126 = query.getOrDefault("IncludeDeleted")
  valid_607126 = validateParameter(valid_607126, JBool, required = false, default = nil)
  if valid_607126 != nil:
    section.add "IncludeDeleted", valid_607126
  var valid_607127 = query.getOrDefault("NextToken")
  valid_607127 = validateParameter(valid_607127, JString, required = false,
                                 default = nil)
  if valid_607127 != nil:
    section.add "NextToken", valid_607127
  var valid_607128 = query.getOrDefault("EnvironmentNames")
  valid_607128 = validateParameter(valid_607128, JArray, required = false,
                                 default = nil)
  if valid_607128 != nil:
    section.add "EnvironmentNames", valid_607128
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607129 = query.getOrDefault("Action")
  valid_607129 = validateParameter(valid_607129, JString, required = true,
                                 default = newJString("DescribeEnvironments"))
  if valid_607129 != nil:
    section.add "Action", valid_607129
  var valid_607130 = query.getOrDefault("EnvironmentIds")
  valid_607130 = validateParameter(valid_607130, JArray, required = false,
                                 default = nil)
  if valid_607130 != nil:
    section.add "EnvironmentIds", valid_607130
  var valid_607131 = query.getOrDefault("IncludedDeletedBackTo")
  valid_607131 = validateParameter(valid_607131, JString, required = false,
                                 default = nil)
  if valid_607131 != nil:
    section.add "IncludedDeletedBackTo", valid_607131
  var valid_607132 = query.getOrDefault("Version")
  valid_607132 = validateParameter(valid_607132, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_607132 != nil:
    section.add "Version", valid_607132
  var valid_607133 = query.getOrDefault("MaxRecords")
  valid_607133 = validateParameter(valid_607133, JInt, required = false, default = nil)
  if valid_607133 != nil:
    section.add "MaxRecords", valid_607133
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
  var valid_607134 = header.getOrDefault("X-Amz-Signature")
  valid_607134 = validateParameter(valid_607134, JString, required = false,
                                 default = nil)
  if valid_607134 != nil:
    section.add "X-Amz-Signature", valid_607134
  var valid_607135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607135 = validateParameter(valid_607135, JString, required = false,
                                 default = nil)
  if valid_607135 != nil:
    section.add "X-Amz-Content-Sha256", valid_607135
  var valid_607136 = header.getOrDefault("X-Amz-Date")
  valid_607136 = validateParameter(valid_607136, JString, required = false,
                                 default = nil)
  if valid_607136 != nil:
    section.add "X-Amz-Date", valid_607136
  var valid_607137 = header.getOrDefault("X-Amz-Credential")
  valid_607137 = validateParameter(valid_607137, JString, required = false,
                                 default = nil)
  if valid_607137 != nil:
    section.add "X-Amz-Credential", valid_607137
  var valid_607138 = header.getOrDefault("X-Amz-Security-Token")
  valid_607138 = validateParameter(valid_607138, JString, required = false,
                                 default = nil)
  if valid_607138 != nil:
    section.add "X-Amz-Security-Token", valid_607138
  var valid_607139 = header.getOrDefault("X-Amz-Algorithm")
  valid_607139 = validateParameter(valid_607139, JString, required = false,
                                 default = nil)
  if valid_607139 != nil:
    section.add "X-Amz-Algorithm", valid_607139
  var valid_607140 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607140 = validateParameter(valid_607140, JString, required = false,
                                 default = nil)
  if valid_607140 != nil:
    section.add "X-Amz-SignedHeaders", valid_607140
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607141: Call_GetDescribeEnvironments_607121; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns descriptions for existing environments.
  ## 
  let valid = call_607141.validator(path, query, header, formData, body)
  let scheme = call_607141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607141.url(scheme.get, call_607141.host, call_607141.base,
                         call_607141.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607141, url, valid)

proc call*(call_607142: Call_GetDescribeEnvironments_607121;
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
  var query_607143 = newJObject()
  add(query_607143, "ApplicationName", newJString(ApplicationName))
  add(query_607143, "VersionLabel", newJString(VersionLabel))
  add(query_607143, "IncludeDeleted", newJBool(IncludeDeleted))
  add(query_607143, "NextToken", newJString(NextToken))
  if EnvironmentNames != nil:
    query_607143.add "EnvironmentNames", EnvironmentNames
  add(query_607143, "Action", newJString(Action))
  if EnvironmentIds != nil:
    query_607143.add "EnvironmentIds", EnvironmentIds
  add(query_607143, "IncludedDeletedBackTo", newJString(IncludedDeletedBackTo))
  add(query_607143, "Version", newJString(Version))
  add(query_607143, "MaxRecords", newJInt(MaxRecords))
  result = call_607142.call(nil, query_607143, nil, nil, nil)

var getDescribeEnvironments* = Call_GetDescribeEnvironments_607121(
    name: "getDescribeEnvironments", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironments",
    validator: validate_GetDescribeEnvironments_607122, base: "/",
    url: url_GetDescribeEnvironments_607123, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_607195 = ref object of OpenApiRestCall_605590
proc url_PostDescribeEvents_607197(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeEvents_607196(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607198 = query.getOrDefault("Action")
  valid_607198 = validateParameter(valid_607198, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_607198 != nil:
    section.add "Action", valid_607198
  var valid_607199 = query.getOrDefault("Version")
  valid_607199 = validateParameter(valid_607199, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_607199 != nil:
    section.add "Version", valid_607199
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
  var valid_607207 = formData.getOrDefault("NextToken")
  valid_607207 = validateParameter(valid_607207, JString, required = false,
                                 default = nil)
  if valid_607207 != nil:
    section.add "NextToken", valid_607207
  var valid_607208 = formData.getOrDefault("MaxRecords")
  valid_607208 = validateParameter(valid_607208, JInt, required = false, default = nil)
  if valid_607208 != nil:
    section.add "MaxRecords", valid_607208
  var valid_607209 = formData.getOrDefault("VersionLabel")
  valid_607209 = validateParameter(valid_607209, JString, required = false,
                                 default = nil)
  if valid_607209 != nil:
    section.add "VersionLabel", valid_607209
  var valid_607210 = formData.getOrDefault("EnvironmentName")
  valid_607210 = validateParameter(valid_607210, JString, required = false,
                                 default = nil)
  if valid_607210 != nil:
    section.add "EnvironmentName", valid_607210
  var valid_607211 = formData.getOrDefault("TemplateName")
  valid_607211 = validateParameter(valid_607211, JString, required = false,
                                 default = nil)
  if valid_607211 != nil:
    section.add "TemplateName", valid_607211
  var valid_607212 = formData.getOrDefault("ApplicationName")
  valid_607212 = validateParameter(valid_607212, JString, required = false,
                                 default = nil)
  if valid_607212 != nil:
    section.add "ApplicationName", valid_607212
  var valid_607213 = formData.getOrDefault("EndTime")
  valid_607213 = validateParameter(valid_607213, JString, required = false,
                                 default = nil)
  if valid_607213 != nil:
    section.add "EndTime", valid_607213
  var valid_607214 = formData.getOrDefault("StartTime")
  valid_607214 = validateParameter(valid_607214, JString, required = false,
                                 default = nil)
  if valid_607214 != nil:
    section.add "StartTime", valid_607214
  var valid_607215 = formData.getOrDefault("Severity")
  valid_607215 = validateParameter(valid_607215, JString, required = false,
                                 default = newJString("TRACE"))
  if valid_607215 != nil:
    section.add "Severity", valid_607215
  var valid_607216 = formData.getOrDefault("RequestId")
  valid_607216 = validateParameter(valid_607216, JString, required = false,
                                 default = nil)
  if valid_607216 != nil:
    section.add "RequestId", valid_607216
  var valid_607217 = formData.getOrDefault("EnvironmentId")
  valid_607217 = validateParameter(valid_607217, JString, required = false,
                                 default = nil)
  if valid_607217 != nil:
    section.add "EnvironmentId", valid_607217
  var valid_607218 = formData.getOrDefault("PlatformArn")
  valid_607218 = validateParameter(valid_607218, JString, required = false,
                                 default = nil)
  if valid_607218 != nil:
    section.add "PlatformArn", valid_607218
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607219: Call_PostDescribeEvents_607195; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns list of event descriptions matching criteria up to the last 6 weeks.</p> <note> <p>This action returns the most recent 1,000 events from the specified <code>NextToken</code>.</p> </note>
  ## 
  let valid = call_607219.validator(path, query, header, formData, body)
  let scheme = call_607219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607219.url(scheme.get, call_607219.host, call_607219.base,
                         call_607219.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607219, url, valid)

proc call*(call_607220: Call_PostDescribeEvents_607195; NextToken: string = "";
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
  var query_607221 = newJObject()
  var formData_607222 = newJObject()
  add(formData_607222, "NextToken", newJString(NextToken))
  add(formData_607222, "MaxRecords", newJInt(MaxRecords))
  add(formData_607222, "VersionLabel", newJString(VersionLabel))
  add(formData_607222, "EnvironmentName", newJString(EnvironmentName))
  add(formData_607222, "TemplateName", newJString(TemplateName))
  add(formData_607222, "ApplicationName", newJString(ApplicationName))
  add(formData_607222, "EndTime", newJString(EndTime))
  add(formData_607222, "StartTime", newJString(StartTime))
  add(formData_607222, "Severity", newJString(Severity))
  add(query_607221, "Action", newJString(Action))
  add(formData_607222, "RequestId", newJString(RequestId))
  add(formData_607222, "EnvironmentId", newJString(EnvironmentId))
  add(query_607221, "Version", newJString(Version))
  add(formData_607222, "PlatformArn", newJString(PlatformArn))
  result = call_607220.call(nil, query_607221, nil, formData_607222, nil)

var postDescribeEvents* = Call_PostDescribeEvents_607195(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_607196, base: "/",
    url: url_PostDescribeEvents_607197, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_607168 = ref object of OpenApiRestCall_605590
proc url_GetDescribeEvents_607170(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeEvents_607169(path: JsonNode; query: JsonNode;
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
  var valid_607171 = query.getOrDefault("RequestId")
  valid_607171 = validateParameter(valid_607171, JString, required = false,
                                 default = nil)
  if valid_607171 != nil:
    section.add "RequestId", valid_607171
  var valid_607172 = query.getOrDefault("ApplicationName")
  valid_607172 = validateParameter(valid_607172, JString, required = false,
                                 default = nil)
  if valid_607172 != nil:
    section.add "ApplicationName", valid_607172
  var valid_607173 = query.getOrDefault("VersionLabel")
  valid_607173 = validateParameter(valid_607173, JString, required = false,
                                 default = nil)
  if valid_607173 != nil:
    section.add "VersionLabel", valid_607173
  var valid_607174 = query.getOrDefault("NextToken")
  valid_607174 = validateParameter(valid_607174, JString, required = false,
                                 default = nil)
  if valid_607174 != nil:
    section.add "NextToken", valid_607174
  var valid_607175 = query.getOrDefault("Severity")
  valid_607175 = validateParameter(valid_607175, JString, required = false,
                                 default = newJString("TRACE"))
  if valid_607175 != nil:
    section.add "Severity", valid_607175
  var valid_607176 = query.getOrDefault("EnvironmentName")
  valid_607176 = validateParameter(valid_607176, JString, required = false,
                                 default = nil)
  if valid_607176 != nil:
    section.add "EnvironmentName", valid_607176
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607177 = query.getOrDefault("Action")
  valid_607177 = validateParameter(valid_607177, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_607177 != nil:
    section.add "Action", valid_607177
  var valid_607178 = query.getOrDefault("StartTime")
  valid_607178 = validateParameter(valid_607178, JString, required = false,
                                 default = nil)
  if valid_607178 != nil:
    section.add "StartTime", valid_607178
  var valid_607179 = query.getOrDefault("PlatformArn")
  valid_607179 = validateParameter(valid_607179, JString, required = false,
                                 default = nil)
  if valid_607179 != nil:
    section.add "PlatformArn", valid_607179
  var valid_607180 = query.getOrDefault("EndTime")
  valid_607180 = validateParameter(valid_607180, JString, required = false,
                                 default = nil)
  if valid_607180 != nil:
    section.add "EndTime", valid_607180
  var valid_607181 = query.getOrDefault("Version")
  valid_607181 = validateParameter(valid_607181, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_607181 != nil:
    section.add "Version", valid_607181
  var valid_607182 = query.getOrDefault("TemplateName")
  valid_607182 = validateParameter(valid_607182, JString, required = false,
                                 default = nil)
  if valid_607182 != nil:
    section.add "TemplateName", valid_607182
  var valid_607183 = query.getOrDefault("MaxRecords")
  valid_607183 = validateParameter(valid_607183, JInt, required = false, default = nil)
  if valid_607183 != nil:
    section.add "MaxRecords", valid_607183
  var valid_607184 = query.getOrDefault("EnvironmentId")
  valid_607184 = validateParameter(valid_607184, JString, required = false,
                                 default = nil)
  if valid_607184 != nil:
    section.add "EnvironmentId", valid_607184
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
  var valid_607185 = header.getOrDefault("X-Amz-Signature")
  valid_607185 = validateParameter(valid_607185, JString, required = false,
                                 default = nil)
  if valid_607185 != nil:
    section.add "X-Amz-Signature", valid_607185
  var valid_607186 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607186 = validateParameter(valid_607186, JString, required = false,
                                 default = nil)
  if valid_607186 != nil:
    section.add "X-Amz-Content-Sha256", valid_607186
  var valid_607187 = header.getOrDefault("X-Amz-Date")
  valid_607187 = validateParameter(valid_607187, JString, required = false,
                                 default = nil)
  if valid_607187 != nil:
    section.add "X-Amz-Date", valid_607187
  var valid_607188 = header.getOrDefault("X-Amz-Credential")
  valid_607188 = validateParameter(valid_607188, JString, required = false,
                                 default = nil)
  if valid_607188 != nil:
    section.add "X-Amz-Credential", valid_607188
  var valid_607189 = header.getOrDefault("X-Amz-Security-Token")
  valid_607189 = validateParameter(valid_607189, JString, required = false,
                                 default = nil)
  if valid_607189 != nil:
    section.add "X-Amz-Security-Token", valid_607189
  var valid_607190 = header.getOrDefault("X-Amz-Algorithm")
  valid_607190 = validateParameter(valid_607190, JString, required = false,
                                 default = nil)
  if valid_607190 != nil:
    section.add "X-Amz-Algorithm", valid_607190
  var valid_607191 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607191 = validateParameter(valid_607191, JString, required = false,
                                 default = nil)
  if valid_607191 != nil:
    section.add "X-Amz-SignedHeaders", valid_607191
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607192: Call_GetDescribeEvents_607168; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns list of event descriptions matching criteria up to the last 6 weeks.</p> <note> <p>This action returns the most recent 1,000 events from the specified <code>NextToken</code>.</p> </note>
  ## 
  let valid = call_607192.validator(path, query, header, formData, body)
  let scheme = call_607192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607192.url(scheme.get, call_607192.host, call_607192.base,
                         call_607192.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607192, url, valid)

proc call*(call_607193: Call_GetDescribeEvents_607168; RequestId: string = "";
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
  var query_607194 = newJObject()
  add(query_607194, "RequestId", newJString(RequestId))
  add(query_607194, "ApplicationName", newJString(ApplicationName))
  add(query_607194, "VersionLabel", newJString(VersionLabel))
  add(query_607194, "NextToken", newJString(NextToken))
  add(query_607194, "Severity", newJString(Severity))
  add(query_607194, "EnvironmentName", newJString(EnvironmentName))
  add(query_607194, "Action", newJString(Action))
  add(query_607194, "StartTime", newJString(StartTime))
  add(query_607194, "PlatformArn", newJString(PlatformArn))
  add(query_607194, "EndTime", newJString(EndTime))
  add(query_607194, "Version", newJString(Version))
  add(query_607194, "TemplateName", newJString(TemplateName))
  add(query_607194, "MaxRecords", newJInt(MaxRecords))
  add(query_607194, "EnvironmentId", newJString(EnvironmentId))
  result = call_607193.call(nil, query_607194, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_607168(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_607169,
    base: "/", url: url_GetDescribeEvents_607170,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeInstancesHealth_607242 = ref object of OpenApiRestCall_605590
proc url_PostDescribeInstancesHealth_607244(protocol: Scheme; host: string;
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

proc validate_PostDescribeInstancesHealth_607243(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607245 = query.getOrDefault("Action")
  valid_607245 = validateParameter(valid_607245, JString, required = true, default = newJString(
      "DescribeInstancesHealth"))
  if valid_607245 != nil:
    section.add "Action", valid_607245
  var valid_607246 = query.getOrDefault("Version")
  valid_607246 = validateParameter(valid_607246, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_607246 != nil:
    section.add "Version", valid_607246
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
  var valid_607247 = header.getOrDefault("X-Amz-Signature")
  valid_607247 = validateParameter(valid_607247, JString, required = false,
                                 default = nil)
  if valid_607247 != nil:
    section.add "X-Amz-Signature", valid_607247
  var valid_607248 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607248 = validateParameter(valid_607248, JString, required = false,
                                 default = nil)
  if valid_607248 != nil:
    section.add "X-Amz-Content-Sha256", valid_607248
  var valid_607249 = header.getOrDefault("X-Amz-Date")
  valid_607249 = validateParameter(valid_607249, JString, required = false,
                                 default = nil)
  if valid_607249 != nil:
    section.add "X-Amz-Date", valid_607249
  var valid_607250 = header.getOrDefault("X-Amz-Credential")
  valid_607250 = validateParameter(valid_607250, JString, required = false,
                                 default = nil)
  if valid_607250 != nil:
    section.add "X-Amz-Credential", valid_607250
  var valid_607251 = header.getOrDefault("X-Amz-Security-Token")
  valid_607251 = validateParameter(valid_607251, JString, required = false,
                                 default = nil)
  if valid_607251 != nil:
    section.add "X-Amz-Security-Token", valid_607251
  var valid_607252 = header.getOrDefault("X-Amz-Algorithm")
  valid_607252 = validateParameter(valid_607252, JString, required = false,
                                 default = nil)
  if valid_607252 != nil:
    section.add "X-Amz-Algorithm", valid_607252
  var valid_607253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607253 = validateParameter(valid_607253, JString, required = false,
                                 default = nil)
  if valid_607253 != nil:
    section.add "X-Amz-SignedHeaders", valid_607253
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
  var valid_607254 = formData.getOrDefault("NextToken")
  valid_607254 = validateParameter(valid_607254, JString, required = false,
                                 default = nil)
  if valid_607254 != nil:
    section.add "NextToken", valid_607254
  var valid_607255 = formData.getOrDefault("EnvironmentName")
  valid_607255 = validateParameter(valid_607255, JString, required = false,
                                 default = nil)
  if valid_607255 != nil:
    section.add "EnvironmentName", valid_607255
  var valid_607256 = formData.getOrDefault("AttributeNames")
  valid_607256 = validateParameter(valid_607256, JArray, required = false,
                                 default = nil)
  if valid_607256 != nil:
    section.add "AttributeNames", valid_607256
  var valid_607257 = formData.getOrDefault("EnvironmentId")
  valid_607257 = validateParameter(valid_607257, JString, required = false,
                                 default = nil)
  if valid_607257 != nil:
    section.add "EnvironmentId", valid_607257
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607258: Call_PostDescribeInstancesHealth_607242; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves detailed information about the health of instances in your AWS Elastic Beanstalk. This operation requires <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/health-enhanced.html">enhanced health reporting</a>.
  ## 
  let valid = call_607258.validator(path, query, header, formData, body)
  let scheme = call_607258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607258.url(scheme.get, call_607258.host, call_607258.base,
                         call_607258.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607258, url, valid)

proc call*(call_607259: Call_PostDescribeInstancesHealth_607242;
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
  var query_607260 = newJObject()
  var formData_607261 = newJObject()
  add(formData_607261, "NextToken", newJString(NextToken))
  add(formData_607261, "EnvironmentName", newJString(EnvironmentName))
  if AttributeNames != nil:
    formData_607261.add "AttributeNames", AttributeNames
  add(query_607260, "Action", newJString(Action))
  add(formData_607261, "EnvironmentId", newJString(EnvironmentId))
  add(query_607260, "Version", newJString(Version))
  result = call_607259.call(nil, query_607260, nil, formData_607261, nil)

var postDescribeInstancesHealth* = Call_PostDescribeInstancesHealth_607242(
    name: "postDescribeInstancesHealth", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeInstancesHealth",
    validator: validate_PostDescribeInstancesHealth_607243, base: "/",
    url: url_PostDescribeInstancesHealth_607244,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeInstancesHealth_607223 = ref object of OpenApiRestCall_605590
proc url_GetDescribeInstancesHealth_607225(protocol: Scheme; host: string;
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

proc validate_GetDescribeInstancesHealth_607224(path: JsonNode; query: JsonNode;
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
  var valid_607226 = query.getOrDefault("AttributeNames")
  valid_607226 = validateParameter(valid_607226, JArray, required = false,
                                 default = nil)
  if valid_607226 != nil:
    section.add "AttributeNames", valid_607226
  var valid_607227 = query.getOrDefault("NextToken")
  valid_607227 = validateParameter(valid_607227, JString, required = false,
                                 default = nil)
  if valid_607227 != nil:
    section.add "NextToken", valid_607227
  var valid_607228 = query.getOrDefault("EnvironmentName")
  valid_607228 = validateParameter(valid_607228, JString, required = false,
                                 default = nil)
  if valid_607228 != nil:
    section.add "EnvironmentName", valid_607228
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607229 = query.getOrDefault("Action")
  valid_607229 = validateParameter(valid_607229, JString, required = true, default = newJString(
      "DescribeInstancesHealth"))
  if valid_607229 != nil:
    section.add "Action", valid_607229
  var valid_607230 = query.getOrDefault("Version")
  valid_607230 = validateParameter(valid_607230, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_607230 != nil:
    section.add "Version", valid_607230
  var valid_607231 = query.getOrDefault("EnvironmentId")
  valid_607231 = validateParameter(valid_607231, JString, required = false,
                                 default = nil)
  if valid_607231 != nil:
    section.add "EnvironmentId", valid_607231
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
  var valid_607232 = header.getOrDefault("X-Amz-Signature")
  valid_607232 = validateParameter(valid_607232, JString, required = false,
                                 default = nil)
  if valid_607232 != nil:
    section.add "X-Amz-Signature", valid_607232
  var valid_607233 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607233 = validateParameter(valid_607233, JString, required = false,
                                 default = nil)
  if valid_607233 != nil:
    section.add "X-Amz-Content-Sha256", valid_607233
  var valid_607234 = header.getOrDefault("X-Amz-Date")
  valid_607234 = validateParameter(valid_607234, JString, required = false,
                                 default = nil)
  if valid_607234 != nil:
    section.add "X-Amz-Date", valid_607234
  var valid_607235 = header.getOrDefault("X-Amz-Credential")
  valid_607235 = validateParameter(valid_607235, JString, required = false,
                                 default = nil)
  if valid_607235 != nil:
    section.add "X-Amz-Credential", valid_607235
  var valid_607236 = header.getOrDefault("X-Amz-Security-Token")
  valid_607236 = validateParameter(valid_607236, JString, required = false,
                                 default = nil)
  if valid_607236 != nil:
    section.add "X-Amz-Security-Token", valid_607236
  var valid_607237 = header.getOrDefault("X-Amz-Algorithm")
  valid_607237 = validateParameter(valid_607237, JString, required = false,
                                 default = nil)
  if valid_607237 != nil:
    section.add "X-Amz-Algorithm", valid_607237
  var valid_607238 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607238 = validateParameter(valid_607238, JString, required = false,
                                 default = nil)
  if valid_607238 != nil:
    section.add "X-Amz-SignedHeaders", valid_607238
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607239: Call_GetDescribeInstancesHealth_607223; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves detailed information about the health of instances in your AWS Elastic Beanstalk. This operation requires <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/health-enhanced.html">enhanced health reporting</a>.
  ## 
  let valid = call_607239.validator(path, query, header, formData, body)
  let scheme = call_607239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607239.url(scheme.get, call_607239.host, call_607239.base,
                         call_607239.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607239, url, valid)

proc call*(call_607240: Call_GetDescribeInstancesHealth_607223;
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
  var query_607241 = newJObject()
  if AttributeNames != nil:
    query_607241.add "AttributeNames", AttributeNames
  add(query_607241, "NextToken", newJString(NextToken))
  add(query_607241, "EnvironmentName", newJString(EnvironmentName))
  add(query_607241, "Action", newJString(Action))
  add(query_607241, "Version", newJString(Version))
  add(query_607241, "EnvironmentId", newJString(EnvironmentId))
  result = call_607240.call(nil, query_607241, nil, nil, nil)

var getDescribeInstancesHealth* = Call_GetDescribeInstancesHealth_607223(
    name: "getDescribeInstancesHealth", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeInstancesHealth",
    validator: validate_GetDescribeInstancesHealth_607224, base: "/",
    url: url_GetDescribeInstancesHealth_607225,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribePlatformVersion_607278 = ref object of OpenApiRestCall_605590
proc url_PostDescribePlatformVersion_607280(protocol: Scheme; host: string;
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

proc validate_PostDescribePlatformVersion_607279(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607281 = query.getOrDefault("Action")
  valid_607281 = validateParameter(valid_607281, JString, required = true, default = newJString(
      "DescribePlatformVersion"))
  if valid_607281 != nil:
    section.add "Action", valid_607281
  var valid_607282 = query.getOrDefault("Version")
  valid_607282 = validateParameter(valid_607282, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_607282 != nil:
    section.add "Version", valid_607282
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
  var valid_607283 = header.getOrDefault("X-Amz-Signature")
  valid_607283 = validateParameter(valid_607283, JString, required = false,
                                 default = nil)
  if valid_607283 != nil:
    section.add "X-Amz-Signature", valid_607283
  var valid_607284 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607284 = validateParameter(valid_607284, JString, required = false,
                                 default = nil)
  if valid_607284 != nil:
    section.add "X-Amz-Content-Sha256", valid_607284
  var valid_607285 = header.getOrDefault("X-Amz-Date")
  valid_607285 = validateParameter(valid_607285, JString, required = false,
                                 default = nil)
  if valid_607285 != nil:
    section.add "X-Amz-Date", valid_607285
  var valid_607286 = header.getOrDefault("X-Amz-Credential")
  valid_607286 = validateParameter(valid_607286, JString, required = false,
                                 default = nil)
  if valid_607286 != nil:
    section.add "X-Amz-Credential", valid_607286
  var valid_607287 = header.getOrDefault("X-Amz-Security-Token")
  valid_607287 = validateParameter(valid_607287, JString, required = false,
                                 default = nil)
  if valid_607287 != nil:
    section.add "X-Amz-Security-Token", valid_607287
  var valid_607288 = header.getOrDefault("X-Amz-Algorithm")
  valid_607288 = validateParameter(valid_607288, JString, required = false,
                                 default = nil)
  if valid_607288 != nil:
    section.add "X-Amz-Algorithm", valid_607288
  var valid_607289 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607289 = validateParameter(valid_607289, JString, required = false,
                                 default = nil)
  if valid_607289 != nil:
    section.add "X-Amz-SignedHeaders", valid_607289
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformArn: JString
  ##              : The ARN of the version of the platform.
  section = newJObject()
  var valid_607290 = formData.getOrDefault("PlatformArn")
  valid_607290 = validateParameter(valid_607290, JString, required = false,
                                 default = nil)
  if valid_607290 != nil:
    section.add "PlatformArn", valid_607290
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607291: Call_PostDescribePlatformVersion_607278; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the version of the platform.
  ## 
  let valid = call_607291.validator(path, query, header, formData, body)
  let scheme = call_607291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607291.url(scheme.get, call_607291.host, call_607291.base,
                         call_607291.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607291, url, valid)

proc call*(call_607292: Call_PostDescribePlatformVersion_607278;
          Action: string = "DescribePlatformVersion";
          Version: string = "2010-12-01"; PlatformArn: string = ""): Recallable =
  ## postDescribePlatformVersion
  ## Describes the version of the platform.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PlatformArn: string
  ##              : The ARN of the version of the platform.
  var query_607293 = newJObject()
  var formData_607294 = newJObject()
  add(query_607293, "Action", newJString(Action))
  add(query_607293, "Version", newJString(Version))
  add(formData_607294, "PlatformArn", newJString(PlatformArn))
  result = call_607292.call(nil, query_607293, nil, formData_607294, nil)

var postDescribePlatformVersion* = Call_PostDescribePlatformVersion_607278(
    name: "postDescribePlatformVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribePlatformVersion",
    validator: validate_PostDescribePlatformVersion_607279, base: "/",
    url: url_PostDescribePlatformVersion_607280,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribePlatformVersion_607262 = ref object of OpenApiRestCall_605590
proc url_GetDescribePlatformVersion_607264(protocol: Scheme; host: string;
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

proc validate_GetDescribePlatformVersion_607263(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607265 = query.getOrDefault("Action")
  valid_607265 = validateParameter(valid_607265, JString, required = true, default = newJString(
      "DescribePlatformVersion"))
  if valid_607265 != nil:
    section.add "Action", valid_607265
  var valid_607266 = query.getOrDefault("PlatformArn")
  valid_607266 = validateParameter(valid_607266, JString, required = false,
                                 default = nil)
  if valid_607266 != nil:
    section.add "PlatformArn", valid_607266
  var valid_607267 = query.getOrDefault("Version")
  valid_607267 = validateParameter(valid_607267, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_607267 != nil:
    section.add "Version", valid_607267
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
  var valid_607268 = header.getOrDefault("X-Amz-Signature")
  valid_607268 = validateParameter(valid_607268, JString, required = false,
                                 default = nil)
  if valid_607268 != nil:
    section.add "X-Amz-Signature", valid_607268
  var valid_607269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607269 = validateParameter(valid_607269, JString, required = false,
                                 default = nil)
  if valid_607269 != nil:
    section.add "X-Amz-Content-Sha256", valid_607269
  var valid_607270 = header.getOrDefault("X-Amz-Date")
  valid_607270 = validateParameter(valid_607270, JString, required = false,
                                 default = nil)
  if valid_607270 != nil:
    section.add "X-Amz-Date", valid_607270
  var valid_607271 = header.getOrDefault("X-Amz-Credential")
  valid_607271 = validateParameter(valid_607271, JString, required = false,
                                 default = nil)
  if valid_607271 != nil:
    section.add "X-Amz-Credential", valid_607271
  var valid_607272 = header.getOrDefault("X-Amz-Security-Token")
  valid_607272 = validateParameter(valid_607272, JString, required = false,
                                 default = nil)
  if valid_607272 != nil:
    section.add "X-Amz-Security-Token", valid_607272
  var valid_607273 = header.getOrDefault("X-Amz-Algorithm")
  valid_607273 = validateParameter(valid_607273, JString, required = false,
                                 default = nil)
  if valid_607273 != nil:
    section.add "X-Amz-Algorithm", valid_607273
  var valid_607274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607274 = validateParameter(valid_607274, JString, required = false,
                                 default = nil)
  if valid_607274 != nil:
    section.add "X-Amz-SignedHeaders", valid_607274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607275: Call_GetDescribePlatformVersion_607262; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the version of the platform.
  ## 
  let valid = call_607275.validator(path, query, header, formData, body)
  let scheme = call_607275.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607275.url(scheme.get, call_607275.host, call_607275.base,
                         call_607275.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607275, url, valid)

proc call*(call_607276: Call_GetDescribePlatformVersion_607262;
          Action: string = "DescribePlatformVersion"; PlatformArn: string = "";
          Version: string = "2010-12-01"): Recallable =
  ## getDescribePlatformVersion
  ## Describes the version of the platform.
  ##   Action: string (required)
  ##   PlatformArn: string
  ##              : The ARN of the version of the platform.
  ##   Version: string (required)
  var query_607277 = newJObject()
  add(query_607277, "Action", newJString(Action))
  add(query_607277, "PlatformArn", newJString(PlatformArn))
  add(query_607277, "Version", newJString(Version))
  result = call_607276.call(nil, query_607277, nil, nil, nil)

var getDescribePlatformVersion* = Call_GetDescribePlatformVersion_607262(
    name: "getDescribePlatformVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribePlatformVersion",
    validator: validate_GetDescribePlatformVersion_607263, base: "/",
    url: url_GetDescribePlatformVersion_607264,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListAvailableSolutionStacks_607310 = ref object of OpenApiRestCall_605590
proc url_PostListAvailableSolutionStacks_607312(protocol: Scheme; host: string;
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

proc validate_PostListAvailableSolutionStacks_607311(path: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607313 = query.getOrDefault("Action")
  valid_607313 = validateParameter(valid_607313, JString, required = true, default = newJString(
      "ListAvailableSolutionStacks"))
  if valid_607313 != nil:
    section.add "Action", valid_607313
  var valid_607314 = query.getOrDefault("Version")
  valid_607314 = validateParameter(valid_607314, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_607314 != nil:
    section.add "Version", valid_607314
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
  var valid_607315 = header.getOrDefault("X-Amz-Signature")
  valid_607315 = validateParameter(valid_607315, JString, required = false,
                                 default = nil)
  if valid_607315 != nil:
    section.add "X-Amz-Signature", valid_607315
  var valid_607316 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607316 = validateParameter(valid_607316, JString, required = false,
                                 default = nil)
  if valid_607316 != nil:
    section.add "X-Amz-Content-Sha256", valid_607316
  var valid_607317 = header.getOrDefault("X-Amz-Date")
  valid_607317 = validateParameter(valid_607317, JString, required = false,
                                 default = nil)
  if valid_607317 != nil:
    section.add "X-Amz-Date", valid_607317
  var valid_607318 = header.getOrDefault("X-Amz-Credential")
  valid_607318 = validateParameter(valid_607318, JString, required = false,
                                 default = nil)
  if valid_607318 != nil:
    section.add "X-Amz-Credential", valid_607318
  var valid_607319 = header.getOrDefault("X-Amz-Security-Token")
  valid_607319 = validateParameter(valid_607319, JString, required = false,
                                 default = nil)
  if valid_607319 != nil:
    section.add "X-Amz-Security-Token", valid_607319
  var valid_607320 = header.getOrDefault("X-Amz-Algorithm")
  valid_607320 = validateParameter(valid_607320, JString, required = false,
                                 default = nil)
  if valid_607320 != nil:
    section.add "X-Amz-Algorithm", valid_607320
  var valid_607321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607321 = validateParameter(valid_607321, JString, required = false,
                                 default = nil)
  if valid_607321 != nil:
    section.add "X-Amz-SignedHeaders", valid_607321
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607322: Call_PostListAvailableSolutionStacks_607310;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ## 
  let valid = call_607322.validator(path, query, header, formData, body)
  let scheme = call_607322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607322.url(scheme.get, call_607322.host, call_607322.base,
                         call_607322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607322, url, valid)

proc call*(call_607323: Call_PostListAvailableSolutionStacks_607310;
          Action: string = "ListAvailableSolutionStacks";
          Version: string = "2010-12-01"): Recallable =
  ## postListAvailableSolutionStacks
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607324 = newJObject()
  add(query_607324, "Action", newJString(Action))
  add(query_607324, "Version", newJString(Version))
  result = call_607323.call(nil, query_607324, nil, nil, nil)

var postListAvailableSolutionStacks* = Call_PostListAvailableSolutionStacks_607310(
    name: "postListAvailableSolutionStacks", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListAvailableSolutionStacks",
    validator: validate_PostListAvailableSolutionStacks_607311, base: "/",
    url: url_PostListAvailableSolutionStacks_607312,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListAvailableSolutionStacks_607295 = ref object of OpenApiRestCall_605590
proc url_GetListAvailableSolutionStacks_607297(protocol: Scheme; host: string;
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

proc validate_GetListAvailableSolutionStacks_607296(path: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607298 = query.getOrDefault("Action")
  valid_607298 = validateParameter(valid_607298, JString, required = true, default = newJString(
      "ListAvailableSolutionStacks"))
  if valid_607298 != nil:
    section.add "Action", valid_607298
  var valid_607299 = query.getOrDefault("Version")
  valid_607299 = validateParameter(valid_607299, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_607299 != nil:
    section.add "Version", valid_607299
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
  var valid_607300 = header.getOrDefault("X-Amz-Signature")
  valid_607300 = validateParameter(valid_607300, JString, required = false,
                                 default = nil)
  if valid_607300 != nil:
    section.add "X-Amz-Signature", valid_607300
  var valid_607301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607301 = validateParameter(valid_607301, JString, required = false,
                                 default = nil)
  if valid_607301 != nil:
    section.add "X-Amz-Content-Sha256", valid_607301
  var valid_607302 = header.getOrDefault("X-Amz-Date")
  valid_607302 = validateParameter(valid_607302, JString, required = false,
                                 default = nil)
  if valid_607302 != nil:
    section.add "X-Amz-Date", valid_607302
  var valid_607303 = header.getOrDefault("X-Amz-Credential")
  valid_607303 = validateParameter(valid_607303, JString, required = false,
                                 default = nil)
  if valid_607303 != nil:
    section.add "X-Amz-Credential", valid_607303
  var valid_607304 = header.getOrDefault("X-Amz-Security-Token")
  valid_607304 = validateParameter(valid_607304, JString, required = false,
                                 default = nil)
  if valid_607304 != nil:
    section.add "X-Amz-Security-Token", valid_607304
  var valid_607305 = header.getOrDefault("X-Amz-Algorithm")
  valid_607305 = validateParameter(valid_607305, JString, required = false,
                                 default = nil)
  if valid_607305 != nil:
    section.add "X-Amz-Algorithm", valid_607305
  var valid_607306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607306 = validateParameter(valid_607306, JString, required = false,
                                 default = nil)
  if valid_607306 != nil:
    section.add "X-Amz-SignedHeaders", valid_607306
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607307: Call_GetListAvailableSolutionStacks_607295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ## 
  let valid = call_607307.validator(path, query, header, formData, body)
  let scheme = call_607307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607307.url(scheme.get, call_607307.host, call_607307.base,
                         call_607307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607307, url, valid)

proc call*(call_607308: Call_GetListAvailableSolutionStacks_607295;
          Action: string = "ListAvailableSolutionStacks";
          Version: string = "2010-12-01"): Recallable =
  ## getListAvailableSolutionStacks
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607309 = newJObject()
  add(query_607309, "Action", newJString(Action))
  add(query_607309, "Version", newJString(Version))
  result = call_607308.call(nil, query_607309, nil, nil, nil)

var getListAvailableSolutionStacks* = Call_GetListAvailableSolutionStacks_607295(
    name: "getListAvailableSolutionStacks", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListAvailableSolutionStacks",
    validator: validate_GetListAvailableSolutionStacks_607296, base: "/",
    url: url_GetListAvailableSolutionStacks_607297,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListPlatformVersions_607343 = ref object of OpenApiRestCall_605590
proc url_PostListPlatformVersions_607345(protocol: Scheme; host: string;
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

proc validate_PostListPlatformVersions_607344(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607346 = query.getOrDefault("Action")
  valid_607346 = validateParameter(valid_607346, JString, required = true,
                                 default = newJString("ListPlatformVersions"))
  if valid_607346 != nil:
    section.add "Action", valid_607346
  var valid_607347 = query.getOrDefault("Version")
  valid_607347 = validateParameter(valid_607347, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_607347 != nil:
    section.add "Version", valid_607347
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
  var valid_607348 = header.getOrDefault("X-Amz-Signature")
  valid_607348 = validateParameter(valid_607348, JString, required = false,
                                 default = nil)
  if valid_607348 != nil:
    section.add "X-Amz-Signature", valid_607348
  var valid_607349 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607349 = validateParameter(valid_607349, JString, required = false,
                                 default = nil)
  if valid_607349 != nil:
    section.add "X-Amz-Content-Sha256", valid_607349
  var valid_607350 = header.getOrDefault("X-Amz-Date")
  valid_607350 = validateParameter(valid_607350, JString, required = false,
                                 default = nil)
  if valid_607350 != nil:
    section.add "X-Amz-Date", valid_607350
  var valid_607351 = header.getOrDefault("X-Amz-Credential")
  valid_607351 = validateParameter(valid_607351, JString, required = false,
                                 default = nil)
  if valid_607351 != nil:
    section.add "X-Amz-Credential", valid_607351
  var valid_607352 = header.getOrDefault("X-Amz-Security-Token")
  valid_607352 = validateParameter(valid_607352, JString, required = false,
                                 default = nil)
  if valid_607352 != nil:
    section.add "X-Amz-Security-Token", valid_607352
  var valid_607353 = header.getOrDefault("X-Amz-Algorithm")
  valid_607353 = validateParameter(valid_607353, JString, required = false,
                                 default = nil)
  if valid_607353 != nil:
    section.add "X-Amz-Algorithm", valid_607353
  var valid_607354 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607354 = validateParameter(valid_607354, JString, required = false,
                                 default = nil)
  if valid_607354 != nil:
    section.add "X-Amz-SignedHeaders", valid_607354
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : The starting index into the remaining list of platforms. Use the <code>NextToken</code> value from a previous <code>ListPlatformVersion</code> call.
  ##   MaxRecords: JInt
  ##             : The maximum number of platform values returned in one call.
  ##   Filters: JArray
  ##          : List only the platforms where the platform member value relates to one of the supplied values.
  section = newJObject()
  var valid_607355 = formData.getOrDefault("NextToken")
  valid_607355 = validateParameter(valid_607355, JString, required = false,
                                 default = nil)
  if valid_607355 != nil:
    section.add "NextToken", valid_607355
  var valid_607356 = formData.getOrDefault("MaxRecords")
  valid_607356 = validateParameter(valid_607356, JInt, required = false, default = nil)
  if valid_607356 != nil:
    section.add "MaxRecords", valid_607356
  var valid_607357 = formData.getOrDefault("Filters")
  valid_607357 = validateParameter(valid_607357, JArray, required = false,
                                 default = nil)
  if valid_607357 != nil:
    section.add "Filters", valid_607357
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607358: Call_PostListPlatformVersions_607343; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the available platforms.
  ## 
  let valid = call_607358.validator(path, query, header, formData, body)
  let scheme = call_607358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607358.url(scheme.get, call_607358.host, call_607358.base,
                         call_607358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607358, url, valid)

proc call*(call_607359: Call_PostListPlatformVersions_607343;
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
  var query_607360 = newJObject()
  var formData_607361 = newJObject()
  add(formData_607361, "NextToken", newJString(NextToken))
  add(formData_607361, "MaxRecords", newJInt(MaxRecords))
  add(query_607360, "Action", newJString(Action))
  if Filters != nil:
    formData_607361.add "Filters", Filters
  add(query_607360, "Version", newJString(Version))
  result = call_607359.call(nil, query_607360, nil, formData_607361, nil)

var postListPlatformVersions* = Call_PostListPlatformVersions_607343(
    name: "postListPlatformVersions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListPlatformVersions",
    validator: validate_PostListPlatformVersions_607344, base: "/",
    url: url_PostListPlatformVersions_607345, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListPlatformVersions_607325 = ref object of OpenApiRestCall_605590
proc url_GetListPlatformVersions_607327(protocol: Scheme; host: string; base: string;
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

proc validate_GetListPlatformVersions_607326(path: JsonNode; query: JsonNode;
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
  var valid_607328 = query.getOrDefault("NextToken")
  valid_607328 = validateParameter(valid_607328, JString, required = false,
                                 default = nil)
  if valid_607328 != nil:
    section.add "NextToken", valid_607328
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607329 = query.getOrDefault("Action")
  valid_607329 = validateParameter(valid_607329, JString, required = true,
                                 default = newJString("ListPlatformVersions"))
  if valid_607329 != nil:
    section.add "Action", valid_607329
  var valid_607330 = query.getOrDefault("Version")
  valid_607330 = validateParameter(valid_607330, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_607330 != nil:
    section.add "Version", valid_607330
  var valid_607331 = query.getOrDefault("Filters")
  valid_607331 = validateParameter(valid_607331, JArray, required = false,
                                 default = nil)
  if valid_607331 != nil:
    section.add "Filters", valid_607331
  var valid_607332 = query.getOrDefault("MaxRecords")
  valid_607332 = validateParameter(valid_607332, JInt, required = false, default = nil)
  if valid_607332 != nil:
    section.add "MaxRecords", valid_607332
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
  var valid_607333 = header.getOrDefault("X-Amz-Signature")
  valid_607333 = validateParameter(valid_607333, JString, required = false,
                                 default = nil)
  if valid_607333 != nil:
    section.add "X-Amz-Signature", valid_607333
  var valid_607334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607334 = validateParameter(valid_607334, JString, required = false,
                                 default = nil)
  if valid_607334 != nil:
    section.add "X-Amz-Content-Sha256", valid_607334
  var valid_607335 = header.getOrDefault("X-Amz-Date")
  valid_607335 = validateParameter(valid_607335, JString, required = false,
                                 default = nil)
  if valid_607335 != nil:
    section.add "X-Amz-Date", valid_607335
  var valid_607336 = header.getOrDefault("X-Amz-Credential")
  valid_607336 = validateParameter(valid_607336, JString, required = false,
                                 default = nil)
  if valid_607336 != nil:
    section.add "X-Amz-Credential", valid_607336
  var valid_607337 = header.getOrDefault("X-Amz-Security-Token")
  valid_607337 = validateParameter(valid_607337, JString, required = false,
                                 default = nil)
  if valid_607337 != nil:
    section.add "X-Amz-Security-Token", valid_607337
  var valid_607338 = header.getOrDefault("X-Amz-Algorithm")
  valid_607338 = validateParameter(valid_607338, JString, required = false,
                                 default = nil)
  if valid_607338 != nil:
    section.add "X-Amz-Algorithm", valid_607338
  var valid_607339 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607339 = validateParameter(valid_607339, JString, required = false,
                                 default = nil)
  if valid_607339 != nil:
    section.add "X-Amz-SignedHeaders", valid_607339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607340: Call_GetListPlatformVersions_607325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the available platforms.
  ## 
  let valid = call_607340.validator(path, query, header, formData, body)
  let scheme = call_607340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607340.url(scheme.get, call_607340.host, call_607340.base,
                         call_607340.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607340, url, valid)

proc call*(call_607341: Call_GetListPlatformVersions_607325;
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
  var query_607342 = newJObject()
  add(query_607342, "NextToken", newJString(NextToken))
  add(query_607342, "Action", newJString(Action))
  add(query_607342, "Version", newJString(Version))
  if Filters != nil:
    query_607342.add "Filters", Filters
  add(query_607342, "MaxRecords", newJInt(MaxRecords))
  result = call_607341.call(nil, query_607342, nil, nil, nil)

var getListPlatformVersions* = Call_GetListPlatformVersions_607325(
    name: "getListPlatformVersions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListPlatformVersions",
    validator: validate_GetListPlatformVersions_607326, base: "/",
    url: url_GetListPlatformVersions_607327, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_607378 = ref object of OpenApiRestCall_605590
proc url_PostListTagsForResource_607380(protocol: Scheme; host: string; base: string;
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

proc validate_PostListTagsForResource_607379(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607381 = query.getOrDefault("Action")
  valid_607381 = validateParameter(valid_607381, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_607381 != nil:
    section.add "Action", valid_607381
  var valid_607382 = query.getOrDefault("Version")
  valid_607382 = validateParameter(valid_607382, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_607382 != nil:
    section.add "Version", valid_607382
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
  var valid_607383 = header.getOrDefault("X-Amz-Signature")
  valid_607383 = validateParameter(valid_607383, JString, required = false,
                                 default = nil)
  if valid_607383 != nil:
    section.add "X-Amz-Signature", valid_607383
  var valid_607384 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607384 = validateParameter(valid_607384, JString, required = false,
                                 default = nil)
  if valid_607384 != nil:
    section.add "X-Amz-Content-Sha256", valid_607384
  var valid_607385 = header.getOrDefault("X-Amz-Date")
  valid_607385 = validateParameter(valid_607385, JString, required = false,
                                 default = nil)
  if valid_607385 != nil:
    section.add "X-Amz-Date", valid_607385
  var valid_607386 = header.getOrDefault("X-Amz-Credential")
  valid_607386 = validateParameter(valid_607386, JString, required = false,
                                 default = nil)
  if valid_607386 != nil:
    section.add "X-Amz-Credential", valid_607386
  var valid_607387 = header.getOrDefault("X-Amz-Security-Token")
  valid_607387 = validateParameter(valid_607387, JString, required = false,
                                 default = nil)
  if valid_607387 != nil:
    section.add "X-Amz-Security-Token", valid_607387
  var valid_607388 = header.getOrDefault("X-Amz-Algorithm")
  valid_607388 = validateParameter(valid_607388, JString, required = false,
                                 default = nil)
  if valid_607388 != nil:
    section.add "X-Amz-Algorithm", valid_607388
  var valid_607389 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607389 = validateParameter(valid_607389, JString, required = false,
                                 default = nil)
  if valid_607389 != nil:
    section.add "X-Amz-SignedHeaders", valid_607389
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArn: JString (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce for which a tag list is requested.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArn` field"
  var valid_607390 = formData.getOrDefault("ResourceArn")
  valid_607390 = validateParameter(valid_607390, JString, required = true,
                                 default = nil)
  if valid_607390 != nil:
    section.add "ResourceArn", valid_607390
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607391: Call_PostListTagsForResource_607378; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ## 
  let valid = call_607391.validator(path, query, header, formData, body)
  let scheme = call_607391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607391.url(scheme.get, call_607391.host, call_607391.base,
                         call_607391.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607391, url, valid)

proc call*(call_607392: Call_PostListTagsForResource_607378; ResourceArn: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-12-01"): Recallable =
  ## postListTagsForResource
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ##   ResourceArn: string (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce for which a tag list is requested.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607393 = newJObject()
  var formData_607394 = newJObject()
  add(formData_607394, "ResourceArn", newJString(ResourceArn))
  add(query_607393, "Action", newJString(Action))
  add(query_607393, "Version", newJString(Version))
  result = call_607392.call(nil, query_607393, nil, formData_607394, nil)

var postListTagsForResource* = Call_PostListTagsForResource_607378(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_607379, base: "/",
    url: url_PostListTagsForResource_607380, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_607362 = ref object of OpenApiRestCall_605590
proc url_GetListTagsForResource_607364(protocol: Scheme; host: string; base: string;
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

proc validate_GetListTagsForResource_607363(path: JsonNode; query: JsonNode;
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
  var valid_607365 = query.getOrDefault("ResourceArn")
  valid_607365 = validateParameter(valid_607365, JString, required = true,
                                 default = nil)
  if valid_607365 != nil:
    section.add "ResourceArn", valid_607365
  var valid_607366 = query.getOrDefault("Action")
  valid_607366 = validateParameter(valid_607366, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_607366 != nil:
    section.add "Action", valid_607366
  var valid_607367 = query.getOrDefault("Version")
  valid_607367 = validateParameter(valid_607367, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_607367 != nil:
    section.add "Version", valid_607367
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
  var valid_607368 = header.getOrDefault("X-Amz-Signature")
  valid_607368 = validateParameter(valid_607368, JString, required = false,
                                 default = nil)
  if valid_607368 != nil:
    section.add "X-Amz-Signature", valid_607368
  var valid_607369 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607369 = validateParameter(valid_607369, JString, required = false,
                                 default = nil)
  if valid_607369 != nil:
    section.add "X-Amz-Content-Sha256", valid_607369
  var valid_607370 = header.getOrDefault("X-Amz-Date")
  valid_607370 = validateParameter(valid_607370, JString, required = false,
                                 default = nil)
  if valid_607370 != nil:
    section.add "X-Amz-Date", valid_607370
  var valid_607371 = header.getOrDefault("X-Amz-Credential")
  valid_607371 = validateParameter(valid_607371, JString, required = false,
                                 default = nil)
  if valid_607371 != nil:
    section.add "X-Amz-Credential", valid_607371
  var valid_607372 = header.getOrDefault("X-Amz-Security-Token")
  valid_607372 = validateParameter(valid_607372, JString, required = false,
                                 default = nil)
  if valid_607372 != nil:
    section.add "X-Amz-Security-Token", valid_607372
  var valid_607373 = header.getOrDefault("X-Amz-Algorithm")
  valid_607373 = validateParameter(valid_607373, JString, required = false,
                                 default = nil)
  if valid_607373 != nil:
    section.add "X-Amz-Algorithm", valid_607373
  var valid_607374 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607374 = validateParameter(valid_607374, JString, required = false,
                                 default = nil)
  if valid_607374 != nil:
    section.add "X-Amz-SignedHeaders", valid_607374
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607375: Call_GetListTagsForResource_607362; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ## 
  let valid = call_607375.validator(path, query, header, formData, body)
  let scheme = call_607375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607375.url(scheme.get, call_607375.host, call_607375.base,
                         call_607375.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607375, url, valid)

proc call*(call_607376: Call_GetListTagsForResource_607362; ResourceArn: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-12-01"): Recallable =
  ## getListTagsForResource
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ##   ResourceArn: string (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce for which a tag list is requested.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_607377 = newJObject()
  add(query_607377, "ResourceArn", newJString(ResourceArn))
  add(query_607377, "Action", newJString(Action))
  add(query_607377, "Version", newJString(Version))
  result = call_607376.call(nil, query_607377, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_607362(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_607363, base: "/",
    url: url_GetListTagsForResource_607364, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebuildEnvironment_607412 = ref object of OpenApiRestCall_605590
proc url_PostRebuildEnvironment_607414(protocol: Scheme; host: string; base: string;
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

proc validate_PostRebuildEnvironment_607413(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607415 = query.getOrDefault("Action")
  valid_607415 = validateParameter(valid_607415, JString, required = true,
                                 default = newJString("RebuildEnvironment"))
  if valid_607415 != nil:
    section.add "Action", valid_607415
  var valid_607416 = query.getOrDefault("Version")
  valid_607416 = validateParameter(valid_607416, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_607416 != nil:
    section.add "Version", valid_607416
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
  var valid_607417 = header.getOrDefault("X-Amz-Signature")
  valid_607417 = validateParameter(valid_607417, JString, required = false,
                                 default = nil)
  if valid_607417 != nil:
    section.add "X-Amz-Signature", valid_607417
  var valid_607418 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607418 = validateParameter(valid_607418, JString, required = false,
                                 default = nil)
  if valid_607418 != nil:
    section.add "X-Amz-Content-Sha256", valid_607418
  var valid_607419 = header.getOrDefault("X-Amz-Date")
  valid_607419 = validateParameter(valid_607419, JString, required = false,
                                 default = nil)
  if valid_607419 != nil:
    section.add "X-Amz-Date", valid_607419
  var valid_607420 = header.getOrDefault("X-Amz-Credential")
  valid_607420 = validateParameter(valid_607420, JString, required = false,
                                 default = nil)
  if valid_607420 != nil:
    section.add "X-Amz-Credential", valid_607420
  var valid_607421 = header.getOrDefault("X-Amz-Security-Token")
  valid_607421 = validateParameter(valid_607421, JString, required = false,
                                 default = nil)
  if valid_607421 != nil:
    section.add "X-Amz-Security-Token", valid_607421
  var valid_607422 = header.getOrDefault("X-Amz-Algorithm")
  valid_607422 = validateParameter(valid_607422, JString, required = false,
                                 default = nil)
  if valid_607422 != nil:
    section.add "X-Amz-Algorithm", valid_607422
  var valid_607423 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607423 = validateParameter(valid_607423, JString, required = false,
                                 default = nil)
  if valid_607423 != nil:
    section.add "X-Amz-SignedHeaders", valid_607423
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to rebuild.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to rebuild.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_607424 = formData.getOrDefault("EnvironmentName")
  valid_607424 = validateParameter(valid_607424, JString, required = false,
                                 default = nil)
  if valid_607424 != nil:
    section.add "EnvironmentName", valid_607424
  var valid_607425 = formData.getOrDefault("EnvironmentId")
  valid_607425 = validateParameter(valid_607425, JString, required = false,
                                 default = nil)
  if valid_607425 != nil:
    section.add "EnvironmentId", valid_607425
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607426: Call_PostRebuildEnvironment_607412; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes and recreates all of the AWS resources (for example: the Auto Scaling group, load balancer, etc.) for a specified environment and forces a restart.
  ## 
  let valid = call_607426.validator(path, query, header, formData, body)
  let scheme = call_607426.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607426.url(scheme.get, call_607426.host, call_607426.base,
                         call_607426.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607426, url, valid)

proc call*(call_607427: Call_PostRebuildEnvironment_607412;
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
  var query_607428 = newJObject()
  var formData_607429 = newJObject()
  add(formData_607429, "EnvironmentName", newJString(EnvironmentName))
  add(query_607428, "Action", newJString(Action))
  add(formData_607429, "EnvironmentId", newJString(EnvironmentId))
  add(query_607428, "Version", newJString(Version))
  result = call_607427.call(nil, query_607428, nil, formData_607429, nil)

var postRebuildEnvironment* = Call_PostRebuildEnvironment_607412(
    name: "postRebuildEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RebuildEnvironment",
    validator: validate_PostRebuildEnvironment_607413, base: "/",
    url: url_PostRebuildEnvironment_607414, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebuildEnvironment_607395 = ref object of OpenApiRestCall_605590
proc url_GetRebuildEnvironment_607397(protocol: Scheme; host: string; base: string;
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

proc validate_GetRebuildEnvironment_607396(path: JsonNode; query: JsonNode;
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
  var valid_607398 = query.getOrDefault("EnvironmentName")
  valid_607398 = validateParameter(valid_607398, JString, required = false,
                                 default = nil)
  if valid_607398 != nil:
    section.add "EnvironmentName", valid_607398
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607399 = query.getOrDefault("Action")
  valid_607399 = validateParameter(valid_607399, JString, required = true,
                                 default = newJString("RebuildEnvironment"))
  if valid_607399 != nil:
    section.add "Action", valid_607399
  var valid_607400 = query.getOrDefault("Version")
  valid_607400 = validateParameter(valid_607400, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_607400 != nil:
    section.add "Version", valid_607400
  var valid_607401 = query.getOrDefault("EnvironmentId")
  valid_607401 = validateParameter(valid_607401, JString, required = false,
                                 default = nil)
  if valid_607401 != nil:
    section.add "EnvironmentId", valid_607401
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
  var valid_607402 = header.getOrDefault("X-Amz-Signature")
  valid_607402 = validateParameter(valid_607402, JString, required = false,
                                 default = nil)
  if valid_607402 != nil:
    section.add "X-Amz-Signature", valid_607402
  var valid_607403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607403 = validateParameter(valid_607403, JString, required = false,
                                 default = nil)
  if valid_607403 != nil:
    section.add "X-Amz-Content-Sha256", valid_607403
  var valid_607404 = header.getOrDefault("X-Amz-Date")
  valid_607404 = validateParameter(valid_607404, JString, required = false,
                                 default = nil)
  if valid_607404 != nil:
    section.add "X-Amz-Date", valid_607404
  var valid_607405 = header.getOrDefault("X-Amz-Credential")
  valid_607405 = validateParameter(valid_607405, JString, required = false,
                                 default = nil)
  if valid_607405 != nil:
    section.add "X-Amz-Credential", valid_607405
  var valid_607406 = header.getOrDefault("X-Amz-Security-Token")
  valid_607406 = validateParameter(valid_607406, JString, required = false,
                                 default = nil)
  if valid_607406 != nil:
    section.add "X-Amz-Security-Token", valid_607406
  var valid_607407 = header.getOrDefault("X-Amz-Algorithm")
  valid_607407 = validateParameter(valid_607407, JString, required = false,
                                 default = nil)
  if valid_607407 != nil:
    section.add "X-Amz-Algorithm", valid_607407
  var valid_607408 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607408 = validateParameter(valid_607408, JString, required = false,
                                 default = nil)
  if valid_607408 != nil:
    section.add "X-Amz-SignedHeaders", valid_607408
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607409: Call_GetRebuildEnvironment_607395; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes and recreates all of the AWS resources (for example: the Auto Scaling group, load balancer, etc.) for a specified environment and forces a restart.
  ## 
  let valid = call_607409.validator(path, query, header, formData, body)
  let scheme = call_607409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607409.url(scheme.get, call_607409.host, call_607409.base,
                         call_607409.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607409, url, valid)

proc call*(call_607410: Call_GetRebuildEnvironment_607395;
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
  var query_607411 = newJObject()
  add(query_607411, "EnvironmentName", newJString(EnvironmentName))
  add(query_607411, "Action", newJString(Action))
  add(query_607411, "Version", newJString(Version))
  add(query_607411, "EnvironmentId", newJString(EnvironmentId))
  result = call_607410.call(nil, query_607411, nil, nil, nil)

var getRebuildEnvironment* = Call_GetRebuildEnvironment_607395(
    name: "getRebuildEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RebuildEnvironment",
    validator: validate_GetRebuildEnvironment_607396, base: "/",
    url: url_GetRebuildEnvironment_607397, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRequestEnvironmentInfo_607448 = ref object of OpenApiRestCall_605590
proc url_PostRequestEnvironmentInfo_607450(protocol: Scheme; host: string;
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

proc validate_PostRequestEnvironmentInfo_607449(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607451 = query.getOrDefault("Action")
  valid_607451 = validateParameter(valid_607451, JString, required = true,
                                 default = newJString("RequestEnvironmentInfo"))
  if valid_607451 != nil:
    section.add "Action", valid_607451
  var valid_607452 = query.getOrDefault("Version")
  valid_607452 = validateParameter(valid_607452, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_607452 != nil:
    section.add "Version", valid_607452
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
  var valid_607453 = header.getOrDefault("X-Amz-Signature")
  valid_607453 = validateParameter(valid_607453, JString, required = false,
                                 default = nil)
  if valid_607453 != nil:
    section.add "X-Amz-Signature", valid_607453
  var valid_607454 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607454 = validateParameter(valid_607454, JString, required = false,
                                 default = nil)
  if valid_607454 != nil:
    section.add "X-Amz-Content-Sha256", valid_607454
  var valid_607455 = header.getOrDefault("X-Amz-Date")
  valid_607455 = validateParameter(valid_607455, JString, required = false,
                                 default = nil)
  if valid_607455 != nil:
    section.add "X-Amz-Date", valid_607455
  var valid_607456 = header.getOrDefault("X-Amz-Credential")
  valid_607456 = validateParameter(valid_607456, JString, required = false,
                                 default = nil)
  if valid_607456 != nil:
    section.add "X-Amz-Credential", valid_607456
  var valid_607457 = header.getOrDefault("X-Amz-Security-Token")
  valid_607457 = validateParameter(valid_607457, JString, required = false,
                                 default = nil)
  if valid_607457 != nil:
    section.add "X-Amz-Security-Token", valid_607457
  var valid_607458 = header.getOrDefault("X-Amz-Algorithm")
  valid_607458 = validateParameter(valid_607458, JString, required = false,
                                 default = nil)
  if valid_607458 != nil:
    section.add "X-Amz-Algorithm", valid_607458
  var valid_607459 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607459 = validateParameter(valid_607459, JString, required = false,
                                 default = nil)
  if valid_607459 != nil:
    section.add "X-Amz-SignedHeaders", valid_607459
  result.add "header", section
  ## parameters in `formData` object:
  ##   InfoType: JString (required)
  ##           : The type of information to request.
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment of the requested data.</p> <p>If no such environment is found, <code>RequestEnvironmentInfo</code> returns an <code>InvalidParameterValue</code> error. </p> <p>Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment of the requested data.</p> <p>If no such environment is found, <code>RequestEnvironmentInfo</code> returns an <code>InvalidParameterValue</code> error. </p> <p>Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `InfoType` field"
  var valid_607460 = formData.getOrDefault("InfoType")
  valid_607460 = validateParameter(valid_607460, JString, required = true,
                                 default = newJString("tail"))
  if valid_607460 != nil:
    section.add "InfoType", valid_607460
  var valid_607461 = formData.getOrDefault("EnvironmentName")
  valid_607461 = validateParameter(valid_607461, JString, required = false,
                                 default = nil)
  if valid_607461 != nil:
    section.add "EnvironmentName", valid_607461
  var valid_607462 = formData.getOrDefault("EnvironmentId")
  valid_607462 = validateParameter(valid_607462, JString, required = false,
                                 default = nil)
  if valid_607462 != nil:
    section.add "EnvironmentId", valid_607462
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607463: Call_PostRequestEnvironmentInfo_607448; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a request to compile the specified type of information of the deployed environment.</p> <p> Setting the <code>InfoType</code> to <code>tail</code> compiles the last lines from the application server log files of every Amazon EC2 instance in your environment. </p> <p> Setting the <code>InfoType</code> to <code>bundle</code> compresses the application server log files for every Amazon EC2 instance into a <code>.zip</code> file. Legacy and .NET containers do not support bundle logs. </p> <p> Use <a>RetrieveEnvironmentInfo</a> to obtain the set of logs. </p> <p>Related Topics</p> <ul> <li> <p> <a>RetrieveEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_607463.validator(path, query, header, formData, body)
  let scheme = call_607463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607463.url(scheme.get, call_607463.host, call_607463.base,
                         call_607463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607463, url, valid)

proc call*(call_607464: Call_PostRequestEnvironmentInfo_607448;
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
  var query_607465 = newJObject()
  var formData_607466 = newJObject()
  add(formData_607466, "InfoType", newJString(InfoType))
  add(formData_607466, "EnvironmentName", newJString(EnvironmentName))
  add(query_607465, "Action", newJString(Action))
  add(formData_607466, "EnvironmentId", newJString(EnvironmentId))
  add(query_607465, "Version", newJString(Version))
  result = call_607464.call(nil, query_607465, nil, formData_607466, nil)

var postRequestEnvironmentInfo* = Call_PostRequestEnvironmentInfo_607448(
    name: "postRequestEnvironmentInfo", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RequestEnvironmentInfo",
    validator: validate_PostRequestEnvironmentInfo_607449, base: "/",
    url: url_PostRequestEnvironmentInfo_607450,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRequestEnvironmentInfo_607430 = ref object of OpenApiRestCall_605590
proc url_GetRequestEnvironmentInfo_607432(protocol: Scheme; host: string;
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

proc validate_GetRequestEnvironmentInfo_607431(path: JsonNode; query: JsonNode;
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
  assert query != nil,
        "query argument is necessary due to required `InfoType` field"
  var valid_607433 = query.getOrDefault("InfoType")
  valid_607433 = validateParameter(valid_607433, JString, required = true,
                                 default = newJString("tail"))
  if valid_607433 != nil:
    section.add "InfoType", valid_607433
  var valid_607434 = query.getOrDefault("EnvironmentName")
  valid_607434 = validateParameter(valid_607434, JString, required = false,
                                 default = nil)
  if valid_607434 != nil:
    section.add "EnvironmentName", valid_607434
  var valid_607435 = query.getOrDefault("Action")
  valid_607435 = validateParameter(valid_607435, JString, required = true,
                                 default = newJString("RequestEnvironmentInfo"))
  if valid_607435 != nil:
    section.add "Action", valid_607435
  var valid_607436 = query.getOrDefault("Version")
  valid_607436 = validateParameter(valid_607436, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_607436 != nil:
    section.add "Version", valid_607436
  var valid_607437 = query.getOrDefault("EnvironmentId")
  valid_607437 = validateParameter(valid_607437, JString, required = false,
                                 default = nil)
  if valid_607437 != nil:
    section.add "EnvironmentId", valid_607437
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
  var valid_607438 = header.getOrDefault("X-Amz-Signature")
  valid_607438 = validateParameter(valid_607438, JString, required = false,
                                 default = nil)
  if valid_607438 != nil:
    section.add "X-Amz-Signature", valid_607438
  var valid_607439 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607439 = validateParameter(valid_607439, JString, required = false,
                                 default = nil)
  if valid_607439 != nil:
    section.add "X-Amz-Content-Sha256", valid_607439
  var valid_607440 = header.getOrDefault("X-Amz-Date")
  valid_607440 = validateParameter(valid_607440, JString, required = false,
                                 default = nil)
  if valid_607440 != nil:
    section.add "X-Amz-Date", valid_607440
  var valid_607441 = header.getOrDefault("X-Amz-Credential")
  valid_607441 = validateParameter(valid_607441, JString, required = false,
                                 default = nil)
  if valid_607441 != nil:
    section.add "X-Amz-Credential", valid_607441
  var valid_607442 = header.getOrDefault("X-Amz-Security-Token")
  valid_607442 = validateParameter(valid_607442, JString, required = false,
                                 default = nil)
  if valid_607442 != nil:
    section.add "X-Amz-Security-Token", valid_607442
  var valid_607443 = header.getOrDefault("X-Amz-Algorithm")
  valid_607443 = validateParameter(valid_607443, JString, required = false,
                                 default = nil)
  if valid_607443 != nil:
    section.add "X-Amz-Algorithm", valid_607443
  var valid_607444 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607444 = validateParameter(valid_607444, JString, required = false,
                                 default = nil)
  if valid_607444 != nil:
    section.add "X-Amz-SignedHeaders", valid_607444
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607445: Call_GetRequestEnvironmentInfo_607430; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a request to compile the specified type of information of the deployed environment.</p> <p> Setting the <code>InfoType</code> to <code>tail</code> compiles the last lines from the application server log files of every Amazon EC2 instance in your environment. </p> <p> Setting the <code>InfoType</code> to <code>bundle</code> compresses the application server log files for every Amazon EC2 instance into a <code>.zip</code> file. Legacy and .NET containers do not support bundle logs. </p> <p> Use <a>RetrieveEnvironmentInfo</a> to obtain the set of logs. </p> <p>Related Topics</p> <ul> <li> <p> <a>RetrieveEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_607445.validator(path, query, header, formData, body)
  let scheme = call_607445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607445.url(scheme.get, call_607445.host, call_607445.base,
                         call_607445.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607445, url, valid)

proc call*(call_607446: Call_GetRequestEnvironmentInfo_607430;
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
  var query_607447 = newJObject()
  add(query_607447, "InfoType", newJString(InfoType))
  add(query_607447, "EnvironmentName", newJString(EnvironmentName))
  add(query_607447, "Action", newJString(Action))
  add(query_607447, "Version", newJString(Version))
  add(query_607447, "EnvironmentId", newJString(EnvironmentId))
  result = call_607446.call(nil, query_607447, nil, nil, nil)

var getRequestEnvironmentInfo* = Call_GetRequestEnvironmentInfo_607430(
    name: "getRequestEnvironmentInfo", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RequestEnvironmentInfo",
    validator: validate_GetRequestEnvironmentInfo_607431, base: "/",
    url: url_GetRequestEnvironmentInfo_607432,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestartAppServer_607484 = ref object of OpenApiRestCall_605590
proc url_PostRestartAppServer_607486(protocol: Scheme; host: string; base: string;
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

proc validate_PostRestartAppServer_607485(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607487 = query.getOrDefault("Action")
  valid_607487 = validateParameter(valid_607487, JString, required = true,
                                 default = newJString("RestartAppServer"))
  if valid_607487 != nil:
    section.add "Action", valid_607487
  var valid_607488 = query.getOrDefault("Version")
  valid_607488 = validateParameter(valid_607488, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_607488 != nil:
    section.add "Version", valid_607488
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
  var valid_607489 = header.getOrDefault("X-Amz-Signature")
  valid_607489 = validateParameter(valid_607489, JString, required = false,
                                 default = nil)
  if valid_607489 != nil:
    section.add "X-Amz-Signature", valid_607489
  var valid_607490 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607490 = validateParameter(valid_607490, JString, required = false,
                                 default = nil)
  if valid_607490 != nil:
    section.add "X-Amz-Content-Sha256", valid_607490
  var valid_607491 = header.getOrDefault("X-Amz-Date")
  valid_607491 = validateParameter(valid_607491, JString, required = false,
                                 default = nil)
  if valid_607491 != nil:
    section.add "X-Amz-Date", valid_607491
  var valid_607492 = header.getOrDefault("X-Amz-Credential")
  valid_607492 = validateParameter(valid_607492, JString, required = false,
                                 default = nil)
  if valid_607492 != nil:
    section.add "X-Amz-Credential", valid_607492
  var valid_607493 = header.getOrDefault("X-Amz-Security-Token")
  valid_607493 = validateParameter(valid_607493, JString, required = false,
                                 default = nil)
  if valid_607493 != nil:
    section.add "X-Amz-Security-Token", valid_607493
  var valid_607494 = header.getOrDefault("X-Amz-Algorithm")
  valid_607494 = validateParameter(valid_607494, JString, required = false,
                                 default = nil)
  if valid_607494 != nil:
    section.add "X-Amz-Algorithm", valid_607494
  var valid_607495 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607495 = validateParameter(valid_607495, JString, required = false,
                                 default = nil)
  if valid_607495 != nil:
    section.add "X-Amz-SignedHeaders", valid_607495
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to restart the server for.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to restart the server for.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_607496 = formData.getOrDefault("EnvironmentName")
  valid_607496 = validateParameter(valid_607496, JString, required = false,
                                 default = nil)
  if valid_607496 != nil:
    section.add "EnvironmentName", valid_607496
  var valid_607497 = formData.getOrDefault("EnvironmentId")
  valid_607497 = validateParameter(valid_607497, JString, required = false,
                                 default = nil)
  if valid_607497 != nil:
    section.add "EnvironmentId", valid_607497
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607498: Call_PostRestartAppServer_607484; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Causes the environment to restart the application container server running on each Amazon EC2 instance.
  ## 
  let valid = call_607498.validator(path, query, header, formData, body)
  let scheme = call_607498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607498.url(scheme.get, call_607498.host, call_607498.base,
                         call_607498.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607498, url, valid)

proc call*(call_607499: Call_PostRestartAppServer_607484;
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
  var query_607500 = newJObject()
  var formData_607501 = newJObject()
  add(formData_607501, "EnvironmentName", newJString(EnvironmentName))
  add(query_607500, "Action", newJString(Action))
  add(formData_607501, "EnvironmentId", newJString(EnvironmentId))
  add(query_607500, "Version", newJString(Version))
  result = call_607499.call(nil, query_607500, nil, formData_607501, nil)

var postRestartAppServer* = Call_PostRestartAppServer_607484(
    name: "postRestartAppServer", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RestartAppServer",
    validator: validate_PostRestartAppServer_607485, base: "/",
    url: url_PostRestartAppServer_607486, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestartAppServer_607467 = ref object of OpenApiRestCall_605590
proc url_GetRestartAppServer_607469(protocol: Scheme; host: string; base: string;
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

proc validate_GetRestartAppServer_607468(path: JsonNode; query: JsonNode;
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
  var valid_607470 = query.getOrDefault("EnvironmentName")
  valid_607470 = validateParameter(valid_607470, JString, required = false,
                                 default = nil)
  if valid_607470 != nil:
    section.add "EnvironmentName", valid_607470
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607471 = query.getOrDefault("Action")
  valid_607471 = validateParameter(valid_607471, JString, required = true,
                                 default = newJString("RestartAppServer"))
  if valid_607471 != nil:
    section.add "Action", valid_607471
  var valid_607472 = query.getOrDefault("Version")
  valid_607472 = validateParameter(valid_607472, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_607472 != nil:
    section.add "Version", valid_607472
  var valid_607473 = query.getOrDefault("EnvironmentId")
  valid_607473 = validateParameter(valid_607473, JString, required = false,
                                 default = nil)
  if valid_607473 != nil:
    section.add "EnvironmentId", valid_607473
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
  var valid_607474 = header.getOrDefault("X-Amz-Signature")
  valid_607474 = validateParameter(valid_607474, JString, required = false,
                                 default = nil)
  if valid_607474 != nil:
    section.add "X-Amz-Signature", valid_607474
  var valid_607475 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607475 = validateParameter(valid_607475, JString, required = false,
                                 default = nil)
  if valid_607475 != nil:
    section.add "X-Amz-Content-Sha256", valid_607475
  var valid_607476 = header.getOrDefault("X-Amz-Date")
  valid_607476 = validateParameter(valid_607476, JString, required = false,
                                 default = nil)
  if valid_607476 != nil:
    section.add "X-Amz-Date", valid_607476
  var valid_607477 = header.getOrDefault("X-Amz-Credential")
  valid_607477 = validateParameter(valid_607477, JString, required = false,
                                 default = nil)
  if valid_607477 != nil:
    section.add "X-Amz-Credential", valid_607477
  var valid_607478 = header.getOrDefault("X-Amz-Security-Token")
  valid_607478 = validateParameter(valid_607478, JString, required = false,
                                 default = nil)
  if valid_607478 != nil:
    section.add "X-Amz-Security-Token", valid_607478
  var valid_607479 = header.getOrDefault("X-Amz-Algorithm")
  valid_607479 = validateParameter(valid_607479, JString, required = false,
                                 default = nil)
  if valid_607479 != nil:
    section.add "X-Amz-Algorithm", valid_607479
  var valid_607480 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607480 = validateParameter(valid_607480, JString, required = false,
                                 default = nil)
  if valid_607480 != nil:
    section.add "X-Amz-SignedHeaders", valid_607480
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607481: Call_GetRestartAppServer_607467; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Causes the environment to restart the application container server running on each Amazon EC2 instance.
  ## 
  let valid = call_607481.validator(path, query, header, formData, body)
  let scheme = call_607481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607481.url(scheme.get, call_607481.host, call_607481.base,
                         call_607481.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607481, url, valid)

proc call*(call_607482: Call_GetRestartAppServer_607467;
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
  var query_607483 = newJObject()
  add(query_607483, "EnvironmentName", newJString(EnvironmentName))
  add(query_607483, "Action", newJString(Action))
  add(query_607483, "Version", newJString(Version))
  add(query_607483, "EnvironmentId", newJString(EnvironmentId))
  result = call_607482.call(nil, query_607483, nil, nil, nil)

var getRestartAppServer* = Call_GetRestartAppServer_607467(
    name: "getRestartAppServer", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RestartAppServer",
    validator: validate_GetRestartAppServer_607468, base: "/",
    url: url_GetRestartAppServer_607469, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRetrieveEnvironmentInfo_607520 = ref object of OpenApiRestCall_605590
proc url_PostRetrieveEnvironmentInfo_607522(protocol: Scheme; host: string;
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

proc validate_PostRetrieveEnvironmentInfo_607521(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607523 = query.getOrDefault("Action")
  valid_607523 = validateParameter(valid_607523, JString, required = true, default = newJString(
      "RetrieveEnvironmentInfo"))
  if valid_607523 != nil:
    section.add "Action", valid_607523
  var valid_607524 = query.getOrDefault("Version")
  valid_607524 = validateParameter(valid_607524, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_607524 != nil:
    section.add "Version", valid_607524
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
  var valid_607525 = header.getOrDefault("X-Amz-Signature")
  valid_607525 = validateParameter(valid_607525, JString, required = false,
                                 default = nil)
  if valid_607525 != nil:
    section.add "X-Amz-Signature", valid_607525
  var valid_607526 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607526 = validateParameter(valid_607526, JString, required = false,
                                 default = nil)
  if valid_607526 != nil:
    section.add "X-Amz-Content-Sha256", valid_607526
  var valid_607527 = header.getOrDefault("X-Amz-Date")
  valid_607527 = validateParameter(valid_607527, JString, required = false,
                                 default = nil)
  if valid_607527 != nil:
    section.add "X-Amz-Date", valid_607527
  var valid_607528 = header.getOrDefault("X-Amz-Credential")
  valid_607528 = validateParameter(valid_607528, JString, required = false,
                                 default = nil)
  if valid_607528 != nil:
    section.add "X-Amz-Credential", valid_607528
  var valid_607529 = header.getOrDefault("X-Amz-Security-Token")
  valid_607529 = validateParameter(valid_607529, JString, required = false,
                                 default = nil)
  if valid_607529 != nil:
    section.add "X-Amz-Security-Token", valid_607529
  var valid_607530 = header.getOrDefault("X-Amz-Algorithm")
  valid_607530 = validateParameter(valid_607530, JString, required = false,
                                 default = nil)
  if valid_607530 != nil:
    section.add "X-Amz-Algorithm", valid_607530
  var valid_607531 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607531 = validateParameter(valid_607531, JString, required = false,
                                 default = nil)
  if valid_607531 != nil:
    section.add "X-Amz-SignedHeaders", valid_607531
  result.add "header", section
  ## parameters in `formData` object:
  ##   InfoType: JString (required)
  ##           : The type of information to retrieve.
  ##   EnvironmentName: JString
  ##                  : <p>The name of the data's environment.</p> <p> If no such environment is found, returns an <code>InvalidParameterValue</code> error. </p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentId: JString
  ##                : <p>The ID of the data's environment.</p> <p>If no such environment is found, returns an <code>InvalidParameterValue</code> error.</p> <p>Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error.</p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `InfoType` field"
  var valid_607532 = formData.getOrDefault("InfoType")
  valid_607532 = validateParameter(valid_607532, JString, required = true,
                                 default = newJString("tail"))
  if valid_607532 != nil:
    section.add "InfoType", valid_607532
  var valid_607533 = formData.getOrDefault("EnvironmentName")
  valid_607533 = validateParameter(valid_607533, JString, required = false,
                                 default = nil)
  if valid_607533 != nil:
    section.add "EnvironmentName", valid_607533
  var valid_607534 = formData.getOrDefault("EnvironmentId")
  valid_607534 = validateParameter(valid_607534, JString, required = false,
                                 default = nil)
  if valid_607534 != nil:
    section.add "EnvironmentId", valid_607534
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607535: Call_PostRetrieveEnvironmentInfo_607520; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the compiled information from a <a>RequestEnvironmentInfo</a> request.</p> <p>Related Topics</p> <ul> <li> <p> <a>RequestEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_607535.validator(path, query, header, formData, body)
  let scheme = call_607535.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607535.url(scheme.get, call_607535.host, call_607535.base,
                         call_607535.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607535, url, valid)

proc call*(call_607536: Call_PostRetrieveEnvironmentInfo_607520;
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
  var query_607537 = newJObject()
  var formData_607538 = newJObject()
  add(formData_607538, "InfoType", newJString(InfoType))
  add(formData_607538, "EnvironmentName", newJString(EnvironmentName))
  add(query_607537, "Action", newJString(Action))
  add(formData_607538, "EnvironmentId", newJString(EnvironmentId))
  add(query_607537, "Version", newJString(Version))
  result = call_607536.call(nil, query_607537, nil, formData_607538, nil)

var postRetrieveEnvironmentInfo* = Call_PostRetrieveEnvironmentInfo_607520(
    name: "postRetrieveEnvironmentInfo", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RetrieveEnvironmentInfo",
    validator: validate_PostRetrieveEnvironmentInfo_607521, base: "/",
    url: url_PostRetrieveEnvironmentInfo_607522,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRetrieveEnvironmentInfo_607502 = ref object of OpenApiRestCall_605590
proc url_GetRetrieveEnvironmentInfo_607504(protocol: Scheme; host: string;
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

proc validate_GetRetrieveEnvironmentInfo_607503(path: JsonNode; query: JsonNode;
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
  assert query != nil,
        "query argument is necessary due to required `InfoType` field"
  var valid_607505 = query.getOrDefault("InfoType")
  valid_607505 = validateParameter(valid_607505, JString, required = true,
                                 default = newJString("tail"))
  if valid_607505 != nil:
    section.add "InfoType", valid_607505
  var valid_607506 = query.getOrDefault("EnvironmentName")
  valid_607506 = validateParameter(valid_607506, JString, required = false,
                                 default = nil)
  if valid_607506 != nil:
    section.add "EnvironmentName", valid_607506
  var valid_607507 = query.getOrDefault("Action")
  valid_607507 = validateParameter(valid_607507, JString, required = true, default = newJString(
      "RetrieveEnvironmentInfo"))
  if valid_607507 != nil:
    section.add "Action", valid_607507
  var valid_607508 = query.getOrDefault("Version")
  valid_607508 = validateParameter(valid_607508, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_607508 != nil:
    section.add "Version", valid_607508
  var valid_607509 = query.getOrDefault("EnvironmentId")
  valid_607509 = validateParameter(valid_607509, JString, required = false,
                                 default = nil)
  if valid_607509 != nil:
    section.add "EnvironmentId", valid_607509
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
  var valid_607510 = header.getOrDefault("X-Amz-Signature")
  valid_607510 = validateParameter(valid_607510, JString, required = false,
                                 default = nil)
  if valid_607510 != nil:
    section.add "X-Amz-Signature", valid_607510
  var valid_607511 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607511 = validateParameter(valid_607511, JString, required = false,
                                 default = nil)
  if valid_607511 != nil:
    section.add "X-Amz-Content-Sha256", valid_607511
  var valid_607512 = header.getOrDefault("X-Amz-Date")
  valid_607512 = validateParameter(valid_607512, JString, required = false,
                                 default = nil)
  if valid_607512 != nil:
    section.add "X-Amz-Date", valid_607512
  var valid_607513 = header.getOrDefault("X-Amz-Credential")
  valid_607513 = validateParameter(valid_607513, JString, required = false,
                                 default = nil)
  if valid_607513 != nil:
    section.add "X-Amz-Credential", valid_607513
  var valid_607514 = header.getOrDefault("X-Amz-Security-Token")
  valid_607514 = validateParameter(valid_607514, JString, required = false,
                                 default = nil)
  if valid_607514 != nil:
    section.add "X-Amz-Security-Token", valid_607514
  var valid_607515 = header.getOrDefault("X-Amz-Algorithm")
  valid_607515 = validateParameter(valid_607515, JString, required = false,
                                 default = nil)
  if valid_607515 != nil:
    section.add "X-Amz-Algorithm", valid_607515
  var valid_607516 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607516 = validateParameter(valid_607516, JString, required = false,
                                 default = nil)
  if valid_607516 != nil:
    section.add "X-Amz-SignedHeaders", valid_607516
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607517: Call_GetRetrieveEnvironmentInfo_607502; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the compiled information from a <a>RequestEnvironmentInfo</a> request.</p> <p>Related Topics</p> <ul> <li> <p> <a>RequestEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_607517.validator(path, query, header, formData, body)
  let scheme = call_607517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607517.url(scheme.get, call_607517.host, call_607517.base,
                         call_607517.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607517, url, valid)

proc call*(call_607518: Call_GetRetrieveEnvironmentInfo_607502;
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
  var query_607519 = newJObject()
  add(query_607519, "InfoType", newJString(InfoType))
  add(query_607519, "EnvironmentName", newJString(EnvironmentName))
  add(query_607519, "Action", newJString(Action))
  add(query_607519, "Version", newJString(Version))
  add(query_607519, "EnvironmentId", newJString(EnvironmentId))
  result = call_607518.call(nil, query_607519, nil, nil, nil)

var getRetrieveEnvironmentInfo* = Call_GetRetrieveEnvironmentInfo_607502(
    name: "getRetrieveEnvironmentInfo", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RetrieveEnvironmentInfo",
    validator: validate_GetRetrieveEnvironmentInfo_607503, base: "/",
    url: url_GetRetrieveEnvironmentInfo_607504,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSwapEnvironmentCNAMEs_607558 = ref object of OpenApiRestCall_605590
proc url_PostSwapEnvironmentCNAMEs_607560(protocol: Scheme; host: string;
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

proc validate_PostSwapEnvironmentCNAMEs_607559(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607561 = query.getOrDefault("Action")
  valid_607561 = validateParameter(valid_607561, JString, required = true,
                                 default = newJString("SwapEnvironmentCNAMEs"))
  if valid_607561 != nil:
    section.add "Action", valid_607561
  var valid_607562 = query.getOrDefault("Version")
  valid_607562 = validateParameter(valid_607562, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_607562 != nil:
    section.add "Version", valid_607562
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
  var valid_607563 = header.getOrDefault("X-Amz-Signature")
  valid_607563 = validateParameter(valid_607563, JString, required = false,
                                 default = nil)
  if valid_607563 != nil:
    section.add "X-Amz-Signature", valid_607563
  var valid_607564 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607564 = validateParameter(valid_607564, JString, required = false,
                                 default = nil)
  if valid_607564 != nil:
    section.add "X-Amz-Content-Sha256", valid_607564
  var valid_607565 = header.getOrDefault("X-Amz-Date")
  valid_607565 = validateParameter(valid_607565, JString, required = false,
                                 default = nil)
  if valid_607565 != nil:
    section.add "X-Amz-Date", valid_607565
  var valid_607566 = header.getOrDefault("X-Amz-Credential")
  valid_607566 = validateParameter(valid_607566, JString, required = false,
                                 default = nil)
  if valid_607566 != nil:
    section.add "X-Amz-Credential", valid_607566
  var valid_607567 = header.getOrDefault("X-Amz-Security-Token")
  valid_607567 = validateParameter(valid_607567, JString, required = false,
                                 default = nil)
  if valid_607567 != nil:
    section.add "X-Amz-Security-Token", valid_607567
  var valid_607568 = header.getOrDefault("X-Amz-Algorithm")
  valid_607568 = validateParameter(valid_607568, JString, required = false,
                                 default = nil)
  if valid_607568 != nil:
    section.add "X-Amz-Algorithm", valid_607568
  var valid_607569 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607569 = validateParameter(valid_607569, JString, required = false,
                                 default = nil)
  if valid_607569 != nil:
    section.add "X-Amz-SignedHeaders", valid_607569
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
  var valid_607570 = formData.getOrDefault("DestinationEnvironmentName")
  valid_607570 = validateParameter(valid_607570, JString, required = false,
                                 default = nil)
  if valid_607570 != nil:
    section.add "DestinationEnvironmentName", valid_607570
  var valid_607571 = formData.getOrDefault("DestinationEnvironmentId")
  valid_607571 = validateParameter(valid_607571, JString, required = false,
                                 default = nil)
  if valid_607571 != nil:
    section.add "DestinationEnvironmentId", valid_607571
  var valid_607572 = formData.getOrDefault("SourceEnvironmentId")
  valid_607572 = validateParameter(valid_607572, JString, required = false,
                                 default = nil)
  if valid_607572 != nil:
    section.add "SourceEnvironmentId", valid_607572
  var valid_607573 = formData.getOrDefault("SourceEnvironmentName")
  valid_607573 = validateParameter(valid_607573, JString, required = false,
                                 default = nil)
  if valid_607573 != nil:
    section.add "SourceEnvironmentName", valid_607573
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607574: Call_PostSwapEnvironmentCNAMEs_607558; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Swaps the CNAMEs of two environments.
  ## 
  let valid = call_607574.validator(path, query, header, formData, body)
  let scheme = call_607574.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607574.url(scheme.get, call_607574.host, call_607574.base,
                         call_607574.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607574, url, valid)

proc call*(call_607575: Call_PostSwapEnvironmentCNAMEs_607558;
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
  var query_607576 = newJObject()
  var formData_607577 = newJObject()
  add(formData_607577, "DestinationEnvironmentName",
      newJString(DestinationEnvironmentName))
  add(formData_607577, "DestinationEnvironmentId",
      newJString(DestinationEnvironmentId))
  add(formData_607577, "SourceEnvironmentId", newJString(SourceEnvironmentId))
  add(formData_607577, "SourceEnvironmentName", newJString(SourceEnvironmentName))
  add(query_607576, "Action", newJString(Action))
  add(query_607576, "Version", newJString(Version))
  result = call_607575.call(nil, query_607576, nil, formData_607577, nil)

var postSwapEnvironmentCNAMEs* = Call_PostSwapEnvironmentCNAMEs_607558(
    name: "postSwapEnvironmentCNAMEs", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=SwapEnvironmentCNAMEs",
    validator: validate_PostSwapEnvironmentCNAMEs_607559, base: "/",
    url: url_PostSwapEnvironmentCNAMEs_607560,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSwapEnvironmentCNAMEs_607539 = ref object of OpenApiRestCall_605590
proc url_GetSwapEnvironmentCNAMEs_607541(protocol: Scheme; host: string;
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

proc validate_GetSwapEnvironmentCNAMEs_607540(path: JsonNode; query: JsonNode;
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
  var valid_607542 = query.getOrDefault("SourceEnvironmentId")
  valid_607542 = validateParameter(valid_607542, JString, required = false,
                                 default = nil)
  if valid_607542 != nil:
    section.add "SourceEnvironmentId", valid_607542
  var valid_607543 = query.getOrDefault("SourceEnvironmentName")
  valid_607543 = validateParameter(valid_607543, JString, required = false,
                                 default = nil)
  if valid_607543 != nil:
    section.add "SourceEnvironmentName", valid_607543
  var valid_607544 = query.getOrDefault("DestinationEnvironmentName")
  valid_607544 = validateParameter(valid_607544, JString, required = false,
                                 default = nil)
  if valid_607544 != nil:
    section.add "DestinationEnvironmentName", valid_607544
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607545 = query.getOrDefault("Action")
  valid_607545 = validateParameter(valid_607545, JString, required = true,
                                 default = newJString("SwapEnvironmentCNAMEs"))
  if valid_607545 != nil:
    section.add "Action", valid_607545
  var valid_607546 = query.getOrDefault("DestinationEnvironmentId")
  valid_607546 = validateParameter(valid_607546, JString, required = false,
                                 default = nil)
  if valid_607546 != nil:
    section.add "DestinationEnvironmentId", valid_607546
  var valid_607547 = query.getOrDefault("Version")
  valid_607547 = validateParameter(valid_607547, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_607547 != nil:
    section.add "Version", valid_607547
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
  var valid_607548 = header.getOrDefault("X-Amz-Signature")
  valid_607548 = validateParameter(valid_607548, JString, required = false,
                                 default = nil)
  if valid_607548 != nil:
    section.add "X-Amz-Signature", valid_607548
  var valid_607549 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607549 = validateParameter(valid_607549, JString, required = false,
                                 default = nil)
  if valid_607549 != nil:
    section.add "X-Amz-Content-Sha256", valid_607549
  var valid_607550 = header.getOrDefault("X-Amz-Date")
  valid_607550 = validateParameter(valid_607550, JString, required = false,
                                 default = nil)
  if valid_607550 != nil:
    section.add "X-Amz-Date", valid_607550
  var valid_607551 = header.getOrDefault("X-Amz-Credential")
  valid_607551 = validateParameter(valid_607551, JString, required = false,
                                 default = nil)
  if valid_607551 != nil:
    section.add "X-Amz-Credential", valid_607551
  var valid_607552 = header.getOrDefault("X-Amz-Security-Token")
  valid_607552 = validateParameter(valid_607552, JString, required = false,
                                 default = nil)
  if valid_607552 != nil:
    section.add "X-Amz-Security-Token", valid_607552
  var valid_607553 = header.getOrDefault("X-Amz-Algorithm")
  valid_607553 = validateParameter(valid_607553, JString, required = false,
                                 default = nil)
  if valid_607553 != nil:
    section.add "X-Amz-Algorithm", valid_607553
  var valid_607554 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607554 = validateParameter(valid_607554, JString, required = false,
                                 default = nil)
  if valid_607554 != nil:
    section.add "X-Amz-SignedHeaders", valid_607554
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607555: Call_GetSwapEnvironmentCNAMEs_607539; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Swaps the CNAMEs of two environments.
  ## 
  let valid = call_607555.validator(path, query, header, formData, body)
  let scheme = call_607555.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607555.url(scheme.get, call_607555.host, call_607555.base,
                         call_607555.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607555, url, valid)

proc call*(call_607556: Call_GetSwapEnvironmentCNAMEs_607539;
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
  var query_607557 = newJObject()
  add(query_607557, "SourceEnvironmentId", newJString(SourceEnvironmentId))
  add(query_607557, "SourceEnvironmentName", newJString(SourceEnvironmentName))
  add(query_607557, "DestinationEnvironmentName",
      newJString(DestinationEnvironmentName))
  add(query_607557, "Action", newJString(Action))
  add(query_607557, "DestinationEnvironmentId",
      newJString(DestinationEnvironmentId))
  add(query_607557, "Version", newJString(Version))
  result = call_607556.call(nil, query_607557, nil, nil, nil)

var getSwapEnvironmentCNAMEs* = Call_GetSwapEnvironmentCNAMEs_607539(
    name: "getSwapEnvironmentCNAMEs", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=SwapEnvironmentCNAMEs",
    validator: validate_GetSwapEnvironmentCNAMEs_607540, base: "/",
    url: url_GetSwapEnvironmentCNAMEs_607541, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostTerminateEnvironment_607597 = ref object of OpenApiRestCall_605590
proc url_PostTerminateEnvironment_607599(protocol: Scheme; host: string;
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

proc validate_PostTerminateEnvironment_607598(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607600 = query.getOrDefault("Action")
  valid_607600 = validateParameter(valid_607600, JString, required = true,
                                 default = newJString("TerminateEnvironment"))
  if valid_607600 != nil:
    section.add "Action", valid_607600
  var valid_607601 = query.getOrDefault("Version")
  valid_607601 = validateParameter(valid_607601, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_607601 != nil:
    section.add "Version", valid_607601
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
  var valid_607602 = header.getOrDefault("X-Amz-Signature")
  valid_607602 = validateParameter(valid_607602, JString, required = false,
                                 default = nil)
  if valid_607602 != nil:
    section.add "X-Amz-Signature", valid_607602
  var valid_607603 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607603 = validateParameter(valid_607603, JString, required = false,
                                 default = nil)
  if valid_607603 != nil:
    section.add "X-Amz-Content-Sha256", valid_607603
  var valid_607604 = header.getOrDefault("X-Amz-Date")
  valid_607604 = validateParameter(valid_607604, JString, required = false,
                                 default = nil)
  if valid_607604 != nil:
    section.add "X-Amz-Date", valid_607604
  var valid_607605 = header.getOrDefault("X-Amz-Credential")
  valid_607605 = validateParameter(valid_607605, JString, required = false,
                                 default = nil)
  if valid_607605 != nil:
    section.add "X-Amz-Credential", valid_607605
  var valid_607606 = header.getOrDefault("X-Amz-Security-Token")
  valid_607606 = validateParameter(valid_607606, JString, required = false,
                                 default = nil)
  if valid_607606 != nil:
    section.add "X-Amz-Security-Token", valid_607606
  var valid_607607 = header.getOrDefault("X-Amz-Algorithm")
  valid_607607 = validateParameter(valid_607607, JString, required = false,
                                 default = nil)
  if valid_607607 != nil:
    section.add "X-Amz-Algorithm", valid_607607
  var valid_607608 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607608 = validateParameter(valid_607608, JString, required = false,
                                 default = nil)
  if valid_607608 != nil:
    section.add "X-Amz-SignedHeaders", valid_607608
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
  var valid_607609 = formData.getOrDefault("EnvironmentName")
  valid_607609 = validateParameter(valid_607609, JString, required = false,
                                 default = nil)
  if valid_607609 != nil:
    section.add "EnvironmentName", valid_607609
  var valid_607610 = formData.getOrDefault("TerminateResources")
  valid_607610 = validateParameter(valid_607610, JBool, required = false, default = nil)
  if valid_607610 != nil:
    section.add "TerminateResources", valid_607610
  var valid_607611 = formData.getOrDefault("ForceTerminate")
  valid_607611 = validateParameter(valid_607611, JBool, required = false, default = nil)
  if valid_607611 != nil:
    section.add "ForceTerminate", valid_607611
  var valid_607612 = formData.getOrDefault("EnvironmentId")
  valid_607612 = validateParameter(valid_607612, JString, required = false,
                                 default = nil)
  if valid_607612 != nil:
    section.add "EnvironmentId", valid_607612
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607613: Call_PostTerminateEnvironment_607597; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Terminates the specified environment.
  ## 
  let valid = call_607613.validator(path, query, header, formData, body)
  let scheme = call_607613.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607613.url(scheme.get, call_607613.host, call_607613.base,
                         call_607613.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607613, url, valid)

proc call*(call_607614: Call_PostTerminateEnvironment_607597;
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
  var query_607615 = newJObject()
  var formData_607616 = newJObject()
  add(formData_607616, "EnvironmentName", newJString(EnvironmentName))
  add(formData_607616, "TerminateResources", newJBool(TerminateResources))
  add(query_607615, "Action", newJString(Action))
  add(formData_607616, "ForceTerminate", newJBool(ForceTerminate))
  add(formData_607616, "EnvironmentId", newJString(EnvironmentId))
  add(query_607615, "Version", newJString(Version))
  result = call_607614.call(nil, query_607615, nil, formData_607616, nil)

var postTerminateEnvironment* = Call_PostTerminateEnvironment_607597(
    name: "postTerminateEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=TerminateEnvironment",
    validator: validate_PostTerminateEnvironment_607598, base: "/",
    url: url_PostTerminateEnvironment_607599, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTerminateEnvironment_607578 = ref object of OpenApiRestCall_605590
proc url_GetTerminateEnvironment_607580(protocol: Scheme; host: string; base: string;
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

proc validate_GetTerminateEnvironment_607579(path: JsonNode; query: JsonNode;
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
  var valid_607581 = query.getOrDefault("ForceTerminate")
  valid_607581 = validateParameter(valid_607581, JBool, required = false, default = nil)
  if valid_607581 != nil:
    section.add "ForceTerminate", valid_607581
  var valid_607582 = query.getOrDefault("TerminateResources")
  valid_607582 = validateParameter(valid_607582, JBool, required = false, default = nil)
  if valid_607582 != nil:
    section.add "TerminateResources", valid_607582
  var valid_607583 = query.getOrDefault("EnvironmentName")
  valid_607583 = validateParameter(valid_607583, JString, required = false,
                                 default = nil)
  if valid_607583 != nil:
    section.add "EnvironmentName", valid_607583
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607584 = query.getOrDefault("Action")
  valid_607584 = validateParameter(valid_607584, JString, required = true,
                                 default = newJString("TerminateEnvironment"))
  if valid_607584 != nil:
    section.add "Action", valid_607584
  var valid_607585 = query.getOrDefault("Version")
  valid_607585 = validateParameter(valid_607585, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_607585 != nil:
    section.add "Version", valid_607585
  var valid_607586 = query.getOrDefault("EnvironmentId")
  valid_607586 = validateParameter(valid_607586, JString, required = false,
                                 default = nil)
  if valid_607586 != nil:
    section.add "EnvironmentId", valid_607586
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
  var valid_607587 = header.getOrDefault("X-Amz-Signature")
  valid_607587 = validateParameter(valid_607587, JString, required = false,
                                 default = nil)
  if valid_607587 != nil:
    section.add "X-Amz-Signature", valid_607587
  var valid_607588 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607588 = validateParameter(valid_607588, JString, required = false,
                                 default = nil)
  if valid_607588 != nil:
    section.add "X-Amz-Content-Sha256", valid_607588
  var valid_607589 = header.getOrDefault("X-Amz-Date")
  valid_607589 = validateParameter(valid_607589, JString, required = false,
                                 default = nil)
  if valid_607589 != nil:
    section.add "X-Amz-Date", valid_607589
  var valid_607590 = header.getOrDefault("X-Amz-Credential")
  valid_607590 = validateParameter(valid_607590, JString, required = false,
                                 default = nil)
  if valid_607590 != nil:
    section.add "X-Amz-Credential", valid_607590
  var valid_607591 = header.getOrDefault("X-Amz-Security-Token")
  valid_607591 = validateParameter(valid_607591, JString, required = false,
                                 default = nil)
  if valid_607591 != nil:
    section.add "X-Amz-Security-Token", valid_607591
  var valid_607592 = header.getOrDefault("X-Amz-Algorithm")
  valid_607592 = validateParameter(valid_607592, JString, required = false,
                                 default = nil)
  if valid_607592 != nil:
    section.add "X-Amz-Algorithm", valid_607592
  var valid_607593 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607593 = validateParameter(valid_607593, JString, required = false,
                                 default = nil)
  if valid_607593 != nil:
    section.add "X-Amz-SignedHeaders", valid_607593
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607594: Call_GetTerminateEnvironment_607578; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Terminates the specified environment.
  ## 
  let valid = call_607594.validator(path, query, header, formData, body)
  let scheme = call_607594.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607594.url(scheme.get, call_607594.host, call_607594.base,
                         call_607594.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607594, url, valid)

proc call*(call_607595: Call_GetTerminateEnvironment_607578;
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
  var query_607596 = newJObject()
  add(query_607596, "ForceTerminate", newJBool(ForceTerminate))
  add(query_607596, "TerminateResources", newJBool(TerminateResources))
  add(query_607596, "EnvironmentName", newJString(EnvironmentName))
  add(query_607596, "Action", newJString(Action))
  add(query_607596, "Version", newJString(Version))
  add(query_607596, "EnvironmentId", newJString(EnvironmentId))
  result = call_607595.call(nil, query_607596, nil, nil, nil)

var getTerminateEnvironment* = Call_GetTerminateEnvironment_607578(
    name: "getTerminateEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=TerminateEnvironment",
    validator: validate_GetTerminateEnvironment_607579, base: "/",
    url: url_GetTerminateEnvironment_607580, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateApplication_607634 = ref object of OpenApiRestCall_605590
proc url_PostUpdateApplication_607636(protocol: Scheme; host: string; base: string;
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

proc validate_PostUpdateApplication_607635(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607637 = query.getOrDefault("Action")
  valid_607637 = validateParameter(valid_607637, JString, required = true,
                                 default = newJString("UpdateApplication"))
  if valid_607637 != nil:
    section.add "Action", valid_607637
  var valid_607638 = query.getOrDefault("Version")
  valid_607638 = validateParameter(valid_607638, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_607638 != nil:
    section.add "Version", valid_607638
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
  var valid_607639 = header.getOrDefault("X-Amz-Signature")
  valid_607639 = validateParameter(valid_607639, JString, required = false,
                                 default = nil)
  if valid_607639 != nil:
    section.add "X-Amz-Signature", valid_607639
  var valid_607640 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607640 = validateParameter(valid_607640, JString, required = false,
                                 default = nil)
  if valid_607640 != nil:
    section.add "X-Amz-Content-Sha256", valid_607640
  var valid_607641 = header.getOrDefault("X-Amz-Date")
  valid_607641 = validateParameter(valid_607641, JString, required = false,
                                 default = nil)
  if valid_607641 != nil:
    section.add "X-Amz-Date", valid_607641
  var valid_607642 = header.getOrDefault("X-Amz-Credential")
  valid_607642 = validateParameter(valid_607642, JString, required = false,
                                 default = nil)
  if valid_607642 != nil:
    section.add "X-Amz-Credential", valid_607642
  var valid_607643 = header.getOrDefault("X-Amz-Security-Token")
  valid_607643 = validateParameter(valid_607643, JString, required = false,
                                 default = nil)
  if valid_607643 != nil:
    section.add "X-Amz-Security-Token", valid_607643
  var valid_607644 = header.getOrDefault("X-Amz-Algorithm")
  valid_607644 = validateParameter(valid_607644, JString, required = false,
                                 default = nil)
  if valid_607644 != nil:
    section.add "X-Amz-Algorithm", valid_607644
  var valid_607645 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607645 = validateParameter(valid_607645, JString, required = false,
                                 default = nil)
  if valid_607645 != nil:
    section.add "X-Amz-SignedHeaders", valid_607645
  result.add "header", section
  ## parameters in `formData` object:
  ##   Description: JString
  ##              : <p>A new description for the application.</p> <p>Default: If not specified, AWS Elastic Beanstalk does not update the description.</p>
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to update. If no such application is found, <code>UpdateApplication</code> returns an <code>InvalidParameterValue</code> error. 
  section = newJObject()
  var valid_607646 = formData.getOrDefault("Description")
  valid_607646 = validateParameter(valid_607646, JString, required = false,
                                 default = nil)
  if valid_607646 != nil:
    section.add "Description", valid_607646
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_607647 = formData.getOrDefault("ApplicationName")
  valid_607647 = validateParameter(valid_607647, JString, required = true,
                                 default = nil)
  if valid_607647 != nil:
    section.add "ApplicationName", valid_607647
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607648: Call_PostUpdateApplication_607634; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified application to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear these properties, specify an empty string.</p> </note>
  ## 
  let valid = call_607648.validator(path, query, header, formData, body)
  let scheme = call_607648.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607648.url(scheme.get, call_607648.host, call_607648.base,
                         call_607648.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607648, url, valid)

proc call*(call_607649: Call_PostUpdateApplication_607634; ApplicationName: string;
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
  var query_607650 = newJObject()
  var formData_607651 = newJObject()
  add(formData_607651, "Description", newJString(Description))
  add(formData_607651, "ApplicationName", newJString(ApplicationName))
  add(query_607650, "Action", newJString(Action))
  add(query_607650, "Version", newJString(Version))
  result = call_607649.call(nil, query_607650, nil, formData_607651, nil)

var postUpdateApplication* = Call_PostUpdateApplication_607634(
    name: "postUpdateApplication", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateApplication",
    validator: validate_PostUpdateApplication_607635, base: "/",
    url: url_PostUpdateApplication_607636, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateApplication_607617 = ref object of OpenApiRestCall_605590
proc url_GetUpdateApplication_607619(protocol: Scheme; host: string; base: string;
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

proc validate_GetUpdateApplication_607618(path: JsonNode; query: JsonNode;
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
  var valid_607620 = query.getOrDefault("ApplicationName")
  valid_607620 = validateParameter(valid_607620, JString, required = true,
                                 default = nil)
  if valid_607620 != nil:
    section.add "ApplicationName", valid_607620
  var valid_607621 = query.getOrDefault("Action")
  valid_607621 = validateParameter(valid_607621, JString, required = true,
                                 default = newJString("UpdateApplication"))
  if valid_607621 != nil:
    section.add "Action", valid_607621
  var valid_607622 = query.getOrDefault("Description")
  valid_607622 = validateParameter(valid_607622, JString, required = false,
                                 default = nil)
  if valid_607622 != nil:
    section.add "Description", valid_607622
  var valid_607623 = query.getOrDefault("Version")
  valid_607623 = validateParameter(valid_607623, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_607623 != nil:
    section.add "Version", valid_607623
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
  var valid_607624 = header.getOrDefault("X-Amz-Signature")
  valid_607624 = validateParameter(valid_607624, JString, required = false,
                                 default = nil)
  if valid_607624 != nil:
    section.add "X-Amz-Signature", valid_607624
  var valid_607625 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607625 = validateParameter(valid_607625, JString, required = false,
                                 default = nil)
  if valid_607625 != nil:
    section.add "X-Amz-Content-Sha256", valid_607625
  var valid_607626 = header.getOrDefault("X-Amz-Date")
  valid_607626 = validateParameter(valid_607626, JString, required = false,
                                 default = nil)
  if valid_607626 != nil:
    section.add "X-Amz-Date", valid_607626
  var valid_607627 = header.getOrDefault("X-Amz-Credential")
  valid_607627 = validateParameter(valid_607627, JString, required = false,
                                 default = nil)
  if valid_607627 != nil:
    section.add "X-Amz-Credential", valid_607627
  var valid_607628 = header.getOrDefault("X-Amz-Security-Token")
  valid_607628 = validateParameter(valid_607628, JString, required = false,
                                 default = nil)
  if valid_607628 != nil:
    section.add "X-Amz-Security-Token", valid_607628
  var valid_607629 = header.getOrDefault("X-Amz-Algorithm")
  valid_607629 = validateParameter(valid_607629, JString, required = false,
                                 default = nil)
  if valid_607629 != nil:
    section.add "X-Amz-Algorithm", valid_607629
  var valid_607630 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607630 = validateParameter(valid_607630, JString, required = false,
                                 default = nil)
  if valid_607630 != nil:
    section.add "X-Amz-SignedHeaders", valid_607630
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607631: Call_GetUpdateApplication_607617; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified application to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear these properties, specify an empty string.</p> </note>
  ## 
  let valid = call_607631.validator(path, query, header, formData, body)
  let scheme = call_607631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607631.url(scheme.get, call_607631.host, call_607631.base,
                         call_607631.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607631, url, valid)

proc call*(call_607632: Call_GetUpdateApplication_607617; ApplicationName: string;
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
  var query_607633 = newJObject()
  add(query_607633, "ApplicationName", newJString(ApplicationName))
  add(query_607633, "Action", newJString(Action))
  add(query_607633, "Description", newJString(Description))
  add(query_607633, "Version", newJString(Version))
  result = call_607632.call(nil, query_607633, nil, nil, nil)

var getUpdateApplication* = Call_GetUpdateApplication_607617(
    name: "getUpdateApplication", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateApplication",
    validator: validate_GetUpdateApplication_607618, base: "/",
    url: url_GetUpdateApplication_607619, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateApplicationResourceLifecycle_607670 = ref object of OpenApiRestCall_605590
proc url_PostUpdateApplicationResourceLifecycle_607672(protocol: Scheme;
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

proc validate_PostUpdateApplicationResourceLifecycle_607671(path: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607673 = query.getOrDefault("Action")
  valid_607673 = validateParameter(valid_607673, JString, required = true, default = newJString(
      "UpdateApplicationResourceLifecycle"))
  if valid_607673 != nil:
    section.add "Action", valid_607673
  var valid_607674 = query.getOrDefault("Version")
  valid_607674 = validateParameter(valid_607674, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_607674 != nil:
    section.add "Version", valid_607674
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
  var valid_607675 = header.getOrDefault("X-Amz-Signature")
  valid_607675 = validateParameter(valid_607675, JString, required = false,
                                 default = nil)
  if valid_607675 != nil:
    section.add "X-Amz-Signature", valid_607675
  var valid_607676 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607676 = validateParameter(valid_607676, JString, required = false,
                                 default = nil)
  if valid_607676 != nil:
    section.add "X-Amz-Content-Sha256", valid_607676
  var valid_607677 = header.getOrDefault("X-Amz-Date")
  valid_607677 = validateParameter(valid_607677, JString, required = false,
                                 default = nil)
  if valid_607677 != nil:
    section.add "X-Amz-Date", valid_607677
  var valid_607678 = header.getOrDefault("X-Amz-Credential")
  valid_607678 = validateParameter(valid_607678, JString, required = false,
                                 default = nil)
  if valid_607678 != nil:
    section.add "X-Amz-Credential", valid_607678
  var valid_607679 = header.getOrDefault("X-Amz-Security-Token")
  valid_607679 = validateParameter(valid_607679, JString, required = false,
                                 default = nil)
  if valid_607679 != nil:
    section.add "X-Amz-Security-Token", valid_607679
  var valid_607680 = header.getOrDefault("X-Amz-Algorithm")
  valid_607680 = validateParameter(valid_607680, JString, required = false,
                                 default = nil)
  if valid_607680 != nil:
    section.add "X-Amz-Algorithm", valid_607680
  var valid_607681 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607681 = validateParameter(valid_607681, JString, required = false,
                                 default = nil)
  if valid_607681 != nil:
    section.add "X-Amz-SignedHeaders", valid_607681
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
  var valid_607682 = formData.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_607682 = validateParameter(valid_607682, JString, required = false,
                                 default = nil)
  if valid_607682 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_607682
  var valid_607683 = formData.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_607683 = validateParameter(valid_607683, JString, required = false,
                                 default = nil)
  if valid_607683 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_607683
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_607684 = formData.getOrDefault("ApplicationName")
  valid_607684 = validateParameter(valid_607684, JString, required = true,
                                 default = nil)
  if valid_607684 != nil:
    section.add "ApplicationName", valid_607684
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607685: Call_PostUpdateApplicationResourceLifecycle_607670;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Modifies lifecycle settings for an application.
  ## 
  let valid = call_607685.validator(path, query, header, formData, body)
  let scheme = call_607685.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607685.url(scheme.get, call_607685.host, call_607685.base,
                         call_607685.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607685, url, valid)

proc call*(call_607686: Call_PostUpdateApplicationResourceLifecycle_607670;
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
  var query_607687 = newJObject()
  var formData_607688 = newJObject()
  add(formData_607688, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  add(formData_607688, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  add(formData_607688, "ApplicationName", newJString(ApplicationName))
  add(query_607687, "Action", newJString(Action))
  add(query_607687, "Version", newJString(Version))
  result = call_607686.call(nil, query_607687, nil, formData_607688, nil)

var postUpdateApplicationResourceLifecycle* = Call_PostUpdateApplicationResourceLifecycle_607670(
    name: "postUpdateApplicationResourceLifecycle", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationResourceLifecycle",
    validator: validate_PostUpdateApplicationResourceLifecycle_607671, base: "/",
    url: url_PostUpdateApplicationResourceLifecycle_607672,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateApplicationResourceLifecycle_607652 = ref object of OpenApiRestCall_605590
proc url_GetUpdateApplicationResourceLifecycle_607654(protocol: Scheme;
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

proc validate_GetUpdateApplicationResourceLifecycle_607653(path: JsonNode;
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
  var valid_607655 = query.getOrDefault("ApplicationName")
  valid_607655 = validateParameter(valid_607655, JString, required = true,
                                 default = nil)
  if valid_607655 != nil:
    section.add "ApplicationName", valid_607655
  var valid_607656 = query.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_607656 = validateParameter(valid_607656, JString, required = false,
                                 default = nil)
  if valid_607656 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_607656
  var valid_607657 = query.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_607657 = validateParameter(valid_607657, JString, required = false,
                                 default = nil)
  if valid_607657 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_607657
  var valid_607658 = query.getOrDefault("Action")
  valid_607658 = validateParameter(valid_607658, JString, required = true, default = newJString(
      "UpdateApplicationResourceLifecycle"))
  if valid_607658 != nil:
    section.add "Action", valid_607658
  var valid_607659 = query.getOrDefault("Version")
  valid_607659 = validateParameter(valid_607659, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_607659 != nil:
    section.add "Version", valid_607659
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
  var valid_607660 = header.getOrDefault("X-Amz-Signature")
  valid_607660 = validateParameter(valid_607660, JString, required = false,
                                 default = nil)
  if valid_607660 != nil:
    section.add "X-Amz-Signature", valid_607660
  var valid_607661 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607661 = validateParameter(valid_607661, JString, required = false,
                                 default = nil)
  if valid_607661 != nil:
    section.add "X-Amz-Content-Sha256", valid_607661
  var valid_607662 = header.getOrDefault("X-Amz-Date")
  valid_607662 = validateParameter(valid_607662, JString, required = false,
                                 default = nil)
  if valid_607662 != nil:
    section.add "X-Amz-Date", valid_607662
  var valid_607663 = header.getOrDefault("X-Amz-Credential")
  valid_607663 = validateParameter(valid_607663, JString, required = false,
                                 default = nil)
  if valid_607663 != nil:
    section.add "X-Amz-Credential", valid_607663
  var valid_607664 = header.getOrDefault("X-Amz-Security-Token")
  valid_607664 = validateParameter(valid_607664, JString, required = false,
                                 default = nil)
  if valid_607664 != nil:
    section.add "X-Amz-Security-Token", valid_607664
  var valid_607665 = header.getOrDefault("X-Amz-Algorithm")
  valid_607665 = validateParameter(valid_607665, JString, required = false,
                                 default = nil)
  if valid_607665 != nil:
    section.add "X-Amz-Algorithm", valid_607665
  var valid_607666 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607666 = validateParameter(valid_607666, JString, required = false,
                                 default = nil)
  if valid_607666 != nil:
    section.add "X-Amz-SignedHeaders", valid_607666
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607667: Call_GetUpdateApplicationResourceLifecycle_607652;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Modifies lifecycle settings for an application.
  ## 
  let valid = call_607667.validator(path, query, header, formData, body)
  let scheme = call_607667.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607667.url(scheme.get, call_607667.host, call_607667.base,
                         call_607667.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607667, url, valid)

proc call*(call_607668: Call_GetUpdateApplicationResourceLifecycle_607652;
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
  var query_607669 = newJObject()
  add(query_607669, "ApplicationName", newJString(ApplicationName))
  add(query_607669, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  add(query_607669, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  add(query_607669, "Action", newJString(Action))
  add(query_607669, "Version", newJString(Version))
  result = call_607668.call(nil, query_607669, nil, nil, nil)

var getUpdateApplicationResourceLifecycle* = Call_GetUpdateApplicationResourceLifecycle_607652(
    name: "getUpdateApplicationResourceLifecycle", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationResourceLifecycle",
    validator: validate_GetUpdateApplicationResourceLifecycle_607653, base: "/",
    url: url_GetUpdateApplicationResourceLifecycle_607654,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateApplicationVersion_607707 = ref object of OpenApiRestCall_605590
proc url_PostUpdateApplicationVersion_607709(protocol: Scheme; host: string;
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

proc validate_PostUpdateApplicationVersion_607708(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607710 = query.getOrDefault("Action")
  valid_607710 = validateParameter(valid_607710, JString, required = true, default = newJString(
      "UpdateApplicationVersion"))
  if valid_607710 != nil:
    section.add "Action", valid_607710
  var valid_607711 = query.getOrDefault("Version")
  valid_607711 = validateParameter(valid_607711, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_607711 != nil:
    section.add "Version", valid_607711
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
  var valid_607712 = header.getOrDefault("X-Amz-Signature")
  valid_607712 = validateParameter(valid_607712, JString, required = false,
                                 default = nil)
  if valid_607712 != nil:
    section.add "X-Amz-Signature", valid_607712
  var valid_607713 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607713 = validateParameter(valid_607713, JString, required = false,
                                 default = nil)
  if valid_607713 != nil:
    section.add "X-Amz-Content-Sha256", valid_607713
  var valid_607714 = header.getOrDefault("X-Amz-Date")
  valid_607714 = validateParameter(valid_607714, JString, required = false,
                                 default = nil)
  if valid_607714 != nil:
    section.add "X-Amz-Date", valid_607714
  var valid_607715 = header.getOrDefault("X-Amz-Credential")
  valid_607715 = validateParameter(valid_607715, JString, required = false,
                                 default = nil)
  if valid_607715 != nil:
    section.add "X-Amz-Credential", valid_607715
  var valid_607716 = header.getOrDefault("X-Amz-Security-Token")
  valid_607716 = validateParameter(valid_607716, JString, required = false,
                                 default = nil)
  if valid_607716 != nil:
    section.add "X-Amz-Security-Token", valid_607716
  var valid_607717 = header.getOrDefault("X-Amz-Algorithm")
  valid_607717 = validateParameter(valid_607717, JString, required = false,
                                 default = nil)
  if valid_607717 != nil:
    section.add "X-Amz-Algorithm", valid_607717
  var valid_607718 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607718 = validateParameter(valid_607718, JString, required = false,
                                 default = nil)
  if valid_607718 != nil:
    section.add "X-Amz-SignedHeaders", valid_607718
  result.add "header", section
  ## parameters in `formData` object:
  ##   Description: JString
  ##              : A new description for this version.
  ##   VersionLabel: JString (required)
  ##               : <p>The name of the version to update.</p> <p>If no application version is found with this label, <code>UpdateApplication</code> returns an <code>InvalidParameterValue</code> error. </p>
  ##   ApplicationName: JString (required)
  ##                  : <p>The name of the application associated with this version.</p> <p> If no application is found with this name, <code>UpdateApplication</code> returns an <code>InvalidParameterValue</code> error.</p>
  section = newJObject()
  var valid_607719 = formData.getOrDefault("Description")
  valid_607719 = validateParameter(valid_607719, JString, required = false,
                                 default = nil)
  if valid_607719 != nil:
    section.add "Description", valid_607719
  assert formData != nil,
        "formData argument is necessary due to required `VersionLabel` field"
  var valid_607720 = formData.getOrDefault("VersionLabel")
  valid_607720 = validateParameter(valid_607720, JString, required = true,
                                 default = nil)
  if valid_607720 != nil:
    section.add "VersionLabel", valid_607720
  var valid_607721 = formData.getOrDefault("ApplicationName")
  valid_607721 = validateParameter(valid_607721, JString, required = true,
                                 default = nil)
  if valid_607721 != nil:
    section.add "ApplicationName", valid_607721
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607722: Call_PostUpdateApplicationVersion_607707; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified application version to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear properties, specify an empty string.</p> </note>
  ## 
  let valid = call_607722.validator(path, query, header, formData, body)
  let scheme = call_607722.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607722.url(scheme.get, call_607722.host, call_607722.base,
                         call_607722.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607722, url, valid)

proc call*(call_607723: Call_PostUpdateApplicationVersion_607707;
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
  var query_607724 = newJObject()
  var formData_607725 = newJObject()
  add(formData_607725, "Description", newJString(Description))
  add(formData_607725, "VersionLabel", newJString(VersionLabel))
  add(formData_607725, "ApplicationName", newJString(ApplicationName))
  add(query_607724, "Action", newJString(Action))
  add(query_607724, "Version", newJString(Version))
  result = call_607723.call(nil, query_607724, nil, formData_607725, nil)

var postUpdateApplicationVersion* = Call_PostUpdateApplicationVersion_607707(
    name: "postUpdateApplicationVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationVersion",
    validator: validate_PostUpdateApplicationVersion_607708, base: "/",
    url: url_PostUpdateApplicationVersion_607709,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateApplicationVersion_607689 = ref object of OpenApiRestCall_605590
proc url_GetUpdateApplicationVersion_607691(protocol: Scheme; host: string;
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

proc validate_GetUpdateApplicationVersion_607690(path: JsonNode; query: JsonNode;
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
  var valid_607692 = query.getOrDefault("ApplicationName")
  valid_607692 = validateParameter(valid_607692, JString, required = true,
                                 default = nil)
  if valid_607692 != nil:
    section.add "ApplicationName", valid_607692
  var valid_607693 = query.getOrDefault("VersionLabel")
  valid_607693 = validateParameter(valid_607693, JString, required = true,
                                 default = nil)
  if valid_607693 != nil:
    section.add "VersionLabel", valid_607693
  var valid_607694 = query.getOrDefault("Action")
  valid_607694 = validateParameter(valid_607694, JString, required = true, default = newJString(
      "UpdateApplicationVersion"))
  if valid_607694 != nil:
    section.add "Action", valid_607694
  var valid_607695 = query.getOrDefault("Description")
  valid_607695 = validateParameter(valid_607695, JString, required = false,
                                 default = nil)
  if valid_607695 != nil:
    section.add "Description", valid_607695
  var valid_607696 = query.getOrDefault("Version")
  valid_607696 = validateParameter(valid_607696, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_607696 != nil:
    section.add "Version", valid_607696
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
  var valid_607697 = header.getOrDefault("X-Amz-Signature")
  valid_607697 = validateParameter(valid_607697, JString, required = false,
                                 default = nil)
  if valid_607697 != nil:
    section.add "X-Amz-Signature", valid_607697
  var valid_607698 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607698 = validateParameter(valid_607698, JString, required = false,
                                 default = nil)
  if valid_607698 != nil:
    section.add "X-Amz-Content-Sha256", valid_607698
  var valid_607699 = header.getOrDefault("X-Amz-Date")
  valid_607699 = validateParameter(valid_607699, JString, required = false,
                                 default = nil)
  if valid_607699 != nil:
    section.add "X-Amz-Date", valid_607699
  var valid_607700 = header.getOrDefault("X-Amz-Credential")
  valid_607700 = validateParameter(valid_607700, JString, required = false,
                                 default = nil)
  if valid_607700 != nil:
    section.add "X-Amz-Credential", valid_607700
  var valid_607701 = header.getOrDefault("X-Amz-Security-Token")
  valid_607701 = validateParameter(valid_607701, JString, required = false,
                                 default = nil)
  if valid_607701 != nil:
    section.add "X-Amz-Security-Token", valid_607701
  var valid_607702 = header.getOrDefault("X-Amz-Algorithm")
  valid_607702 = validateParameter(valid_607702, JString, required = false,
                                 default = nil)
  if valid_607702 != nil:
    section.add "X-Amz-Algorithm", valid_607702
  var valid_607703 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607703 = validateParameter(valid_607703, JString, required = false,
                                 default = nil)
  if valid_607703 != nil:
    section.add "X-Amz-SignedHeaders", valid_607703
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607704: Call_GetUpdateApplicationVersion_607689; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified application version to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear properties, specify an empty string.</p> </note>
  ## 
  let valid = call_607704.validator(path, query, header, formData, body)
  let scheme = call_607704.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607704.url(scheme.get, call_607704.host, call_607704.base,
                         call_607704.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607704, url, valid)

proc call*(call_607705: Call_GetUpdateApplicationVersion_607689;
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
  var query_607706 = newJObject()
  add(query_607706, "ApplicationName", newJString(ApplicationName))
  add(query_607706, "VersionLabel", newJString(VersionLabel))
  add(query_607706, "Action", newJString(Action))
  add(query_607706, "Description", newJString(Description))
  add(query_607706, "Version", newJString(Version))
  result = call_607705.call(nil, query_607706, nil, nil, nil)

var getUpdateApplicationVersion* = Call_GetUpdateApplicationVersion_607689(
    name: "getUpdateApplicationVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationVersion",
    validator: validate_GetUpdateApplicationVersion_607690, base: "/",
    url: url_GetUpdateApplicationVersion_607691,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateConfigurationTemplate_607746 = ref object of OpenApiRestCall_605590
proc url_PostUpdateConfigurationTemplate_607748(protocol: Scheme; host: string;
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

proc validate_PostUpdateConfigurationTemplate_607747(path: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607749 = query.getOrDefault("Action")
  valid_607749 = validateParameter(valid_607749, JString, required = true, default = newJString(
      "UpdateConfigurationTemplate"))
  if valid_607749 != nil:
    section.add "Action", valid_607749
  var valid_607750 = query.getOrDefault("Version")
  valid_607750 = validateParameter(valid_607750, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_607750 != nil:
    section.add "Version", valid_607750
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
  var valid_607751 = header.getOrDefault("X-Amz-Signature")
  valid_607751 = validateParameter(valid_607751, JString, required = false,
                                 default = nil)
  if valid_607751 != nil:
    section.add "X-Amz-Signature", valid_607751
  var valid_607752 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607752 = validateParameter(valid_607752, JString, required = false,
                                 default = nil)
  if valid_607752 != nil:
    section.add "X-Amz-Content-Sha256", valid_607752
  var valid_607753 = header.getOrDefault("X-Amz-Date")
  valid_607753 = validateParameter(valid_607753, JString, required = false,
                                 default = nil)
  if valid_607753 != nil:
    section.add "X-Amz-Date", valid_607753
  var valid_607754 = header.getOrDefault("X-Amz-Credential")
  valid_607754 = validateParameter(valid_607754, JString, required = false,
                                 default = nil)
  if valid_607754 != nil:
    section.add "X-Amz-Credential", valid_607754
  var valid_607755 = header.getOrDefault("X-Amz-Security-Token")
  valid_607755 = validateParameter(valid_607755, JString, required = false,
                                 default = nil)
  if valid_607755 != nil:
    section.add "X-Amz-Security-Token", valid_607755
  var valid_607756 = header.getOrDefault("X-Amz-Algorithm")
  valid_607756 = validateParameter(valid_607756, JString, required = false,
                                 default = nil)
  if valid_607756 != nil:
    section.add "X-Amz-Algorithm", valid_607756
  var valid_607757 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607757 = validateParameter(valid_607757, JString, required = false,
                                 default = nil)
  if valid_607757 != nil:
    section.add "X-Amz-SignedHeaders", valid_607757
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
  var valid_607758 = formData.getOrDefault("Description")
  valid_607758 = validateParameter(valid_607758, JString, required = false,
                                 default = nil)
  if valid_607758 != nil:
    section.add "Description", valid_607758
  assert formData != nil,
        "formData argument is necessary due to required `TemplateName` field"
  var valid_607759 = formData.getOrDefault("TemplateName")
  valid_607759 = validateParameter(valid_607759, JString, required = true,
                                 default = nil)
  if valid_607759 != nil:
    section.add "TemplateName", valid_607759
  var valid_607760 = formData.getOrDefault("OptionsToRemove")
  valid_607760 = validateParameter(valid_607760, JArray, required = false,
                                 default = nil)
  if valid_607760 != nil:
    section.add "OptionsToRemove", valid_607760
  var valid_607761 = formData.getOrDefault("OptionSettings")
  valid_607761 = validateParameter(valid_607761, JArray, required = false,
                                 default = nil)
  if valid_607761 != nil:
    section.add "OptionSettings", valid_607761
  var valid_607762 = formData.getOrDefault("ApplicationName")
  valid_607762 = validateParameter(valid_607762, JString, required = true,
                                 default = nil)
  if valid_607762 != nil:
    section.add "ApplicationName", valid_607762
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607763: Call_PostUpdateConfigurationTemplate_607746;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Updates the specified configuration template to have the specified properties or configuration option values.</p> <note> <p>If a property (for example, <code>ApplicationName</code>) is not provided, its value remains unchanged. To clear such properties, specify an empty string.</p> </note> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> </ul>
  ## 
  let valid = call_607763.validator(path, query, header, formData, body)
  let scheme = call_607763.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607763.url(scheme.get, call_607763.host, call_607763.base,
                         call_607763.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607763, url, valid)

proc call*(call_607764: Call_PostUpdateConfigurationTemplate_607746;
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
  var query_607765 = newJObject()
  var formData_607766 = newJObject()
  add(formData_607766, "Description", newJString(Description))
  add(formData_607766, "TemplateName", newJString(TemplateName))
  if OptionsToRemove != nil:
    formData_607766.add "OptionsToRemove", OptionsToRemove
  if OptionSettings != nil:
    formData_607766.add "OptionSettings", OptionSettings
  add(formData_607766, "ApplicationName", newJString(ApplicationName))
  add(query_607765, "Action", newJString(Action))
  add(query_607765, "Version", newJString(Version))
  result = call_607764.call(nil, query_607765, nil, formData_607766, nil)

var postUpdateConfigurationTemplate* = Call_PostUpdateConfigurationTemplate_607746(
    name: "postUpdateConfigurationTemplate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateConfigurationTemplate",
    validator: validate_PostUpdateConfigurationTemplate_607747, base: "/",
    url: url_PostUpdateConfigurationTemplate_607748,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateConfigurationTemplate_607726 = ref object of OpenApiRestCall_605590
proc url_GetUpdateConfigurationTemplate_607728(protocol: Scheme; host: string;
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

proc validate_GetUpdateConfigurationTemplate_607727(path: JsonNode;
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
  var valid_607729 = query.getOrDefault("ApplicationName")
  valid_607729 = validateParameter(valid_607729, JString, required = true,
                                 default = nil)
  if valid_607729 != nil:
    section.add "ApplicationName", valid_607729
  var valid_607730 = query.getOrDefault("OptionSettings")
  valid_607730 = validateParameter(valid_607730, JArray, required = false,
                                 default = nil)
  if valid_607730 != nil:
    section.add "OptionSettings", valid_607730
  var valid_607731 = query.getOrDefault("Action")
  valid_607731 = validateParameter(valid_607731, JString, required = true, default = newJString(
      "UpdateConfigurationTemplate"))
  if valid_607731 != nil:
    section.add "Action", valid_607731
  var valid_607732 = query.getOrDefault("Description")
  valid_607732 = validateParameter(valid_607732, JString, required = false,
                                 default = nil)
  if valid_607732 != nil:
    section.add "Description", valid_607732
  var valid_607733 = query.getOrDefault("OptionsToRemove")
  valid_607733 = validateParameter(valid_607733, JArray, required = false,
                                 default = nil)
  if valid_607733 != nil:
    section.add "OptionsToRemove", valid_607733
  var valid_607734 = query.getOrDefault("Version")
  valid_607734 = validateParameter(valid_607734, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_607734 != nil:
    section.add "Version", valid_607734
  var valid_607735 = query.getOrDefault("TemplateName")
  valid_607735 = validateParameter(valid_607735, JString, required = true,
                                 default = nil)
  if valid_607735 != nil:
    section.add "TemplateName", valid_607735
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
  var valid_607736 = header.getOrDefault("X-Amz-Signature")
  valid_607736 = validateParameter(valid_607736, JString, required = false,
                                 default = nil)
  if valid_607736 != nil:
    section.add "X-Amz-Signature", valid_607736
  var valid_607737 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607737 = validateParameter(valid_607737, JString, required = false,
                                 default = nil)
  if valid_607737 != nil:
    section.add "X-Amz-Content-Sha256", valid_607737
  var valid_607738 = header.getOrDefault("X-Amz-Date")
  valid_607738 = validateParameter(valid_607738, JString, required = false,
                                 default = nil)
  if valid_607738 != nil:
    section.add "X-Amz-Date", valid_607738
  var valid_607739 = header.getOrDefault("X-Amz-Credential")
  valid_607739 = validateParameter(valid_607739, JString, required = false,
                                 default = nil)
  if valid_607739 != nil:
    section.add "X-Amz-Credential", valid_607739
  var valid_607740 = header.getOrDefault("X-Amz-Security-Token")
  valid_607740 = validateParameter(valid_607740, JString, required = false,
                                 default = nil)
  if valid_607740 != nil:
    section.add "X-Amz-Security-Token", valid_607740
  var valid_607741 = header.getOrDefault("X-Amz-Algorithm")
  valid_607741 = validateParameter(valid_607741, JString, required = false,
                                 default = nil)
  if valid_607741 != nil:
    section.add "X-Amz-Algorithm", valid_607741
  var valid_607742 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607742 = validateParameter(valid_607742, JString, required = false,
                                 default = nil)
  if valid_607742 != nil:
    section.add "X-Amz-SignedHeaders", valid_607742
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607743: Call_GetUpdateConfigurationTemplate_607726; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified configuration template to have the specified properties or configuration option values.</p> <note> <p>If a property (for example, <code>ApplicationName</code>) is not provided, its value remains unchanged. To clear such properties, specify an empty string.</p> </note> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> </ul>
  ## 
  let valid = call_607743.validator(path, query, header, formData, body)
  let scheme = call_607743.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607743.url(scheme.get, call_607743.host, call_607743.base,
                         call_607743.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607743, url, valid)

proc call*(call_607744: Call_GetUpdateConfigurationTemplate_607726;
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
  var query_607745 = newJObject()
  add(query_607745, "ApplicationName", newJString(ApplicationName))
  if OptionSettings != nil:
    query_607745.add "OptionSettings", OptionSettings
  add(query_607745, "Action", newJString(Action))
  add(query_607745, "Description", newJString(Description))
  if OptionsToRemove != nil:
    query_607745.add "OptionsToRemove", OptionsToRemove
  add(query_607745, "Version", newJString(Version))
  add(query_607745, "TemplateName", newJString(TemplateName))
  result = call_607744.call(nil, query_607745, nil, nil, nil)

var getUpdateConfigurationTemplate* = Call_GetUpdateConfigurationTemplate_607726(
    name: "getUpdateConfigurationTemplate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateConfigurationTemplate",
    validator: validate_GetUpdateConfigurationTemplate_607727, base: "/",
    url: url_GetUpdateConfigurationTemplate_607728,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateEnvironment_607796 = ref object of OpenApiRestCall_605590
proc url_PostUpdateEnvironment_607798(protocol: Scheme; host: string; base: string;
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

proc validate_PostUpdateEnvironment_607797(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607799 = query.getOrDefault("Action")
  valid_607799 = validateParameter(valid_607799, JString, required = true,
                                 default = newJString("UpdateEnvironment"))
  if valid_607799 != nil:
    section.add "Action", valid_607799
  var valid_607800 = query.getOrDefault("Version")
  valid_607800 = validateParameter(valid_607800, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_607800 != nil:
    section.add "Version", valid_607800
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
  var valid_607801 = header.getOrDefault("X-Amz-Signature")
  valid_607801 = validateParameter(valid_607801, JString, required = false,
                                 default = nil)
  if valid_607801 != nil:
    section.add "X-Amz-Signature", valid_607801
  var valid_607802 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607802 = validateParameter(valid_607802, JString, required = false,
                                 default = nil)
  if valid_607802 != nil:
    section.add "X-Amz-Content-Sha256", valid_607802
  var valid_607803 = header.getOrDefault("X-Amz-Date")
  valid_607803 = validateParameter(valid_607803, JString, required = false,
                                 default = nil)
  if valid_607803 != nil:
    section.add "X-Amz-Date", valid_607803
  var valid_607804 = header.getOrDefault("X-Amz-Credential")
  valid_607804 = validateParameter(valid_607804, JString, required = false,
                                 default = nil)
  if valid_607804 != nil:
    section.add "X-Amz-Credential", valid_607804
  var valid_607805 = header.getOrDefault("X-Amz-Security-Token")
  valid_607805 = validateParameter(valid_607805, JString, required = false,
                                 default = nil)
  if valid_607805 != nil:
    section.add "X-Amz-Security-Token", valid_607805
  var valid_607806 = header.getOrDefault("X-Amz-Algorithm")
  valid_607806 = validateParameter(valid_607806, JString, required = false,
                                 default = nil)
  if valid_607806 != nil:
    section.add "X-Amz-Algorithm", valid_607806
  var valid_607807 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607807 = validateParameter(valid_607807, JString, required = false,
                                 default = nil)
  if valid_607807 != nil:
    section.add "X-Amz-SignedHeaders", valid_607807
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
  var valid_607808 = formData.getOrDefault("Description")
  valid_607808 = validateParameter(valid_607808, JString, required = false,
                                 default = nil)
  if valid_607808 != nil:
    section.add "Description", valid_607808
  var valid_607809 = formData.getOrDefault("Tier.Type")
  valid_607809 = validateParameter(valid_607809, JString, required = false,
                                 default = nil)
  if valid_607809 != nil:
    section.add "Tier.Type", valid_607809
  var valid_607810 = formData.getOrDefault("EnvironmentName")
  valid_607810 = validateParameter(valid_607810, JString, required = false,
                                 default = nil)
  if valid_607810 != nil:
    section.add "EnvironmentName", valid_607810
  var valid_607811 = formData.getOrDefault("VersionLabel")
  valid_607811 = validateParameter(valid_607811, JString, required = false,
                                 default = nil)
  if valid_607811 != nil:
    section.add "VersionLabel", valid_607811
  var valid_607812 = formData.getOrDefault("TemplateName")
  valid_607812 = validateParameter(valid_607812, JString, required = false,
                                 default = nil)
  if valid_607812 != nil:
    section.add "TemplateName", valid_607812
  var valid_607813 = formData.getOrDefault("OptionsToRemove")
  valid_607813 = validateParameter(valid_607813, JArray, required = false,
                                 default = nil)
  if valid_607813 != nil:
    section.add "OptionsToRemove", valid_607813
  var valid_607814 = formData.getOrDefault("OptionSettings")
  valid_607814 = validateParameter(valid_607814, JArray, required = false,
                                 default = nil)
  if valid_607814 != nil:
    section.add "OptionSettings", valid_607814
  var valid_607815 = formData.getOrDefault("GroupName")
  valid_607815 = validateParameter(valid_607815, JString, required = false,
                                 default = nil)
  if valid_607815 != nil:
    section.add "GroupName", valid_607815
  var valid_607816 = formData.getOrDefault("ApplicationName")
  valid_607816 = validateParameter(valid_607816, JString, required = false,
                                 default = nil)
  if valid_607816 != nil:
    section.add "ApplicationName", valid_607816
  var valid_607817 = formData.getOrDefault("Tier.Name")
  valid_607817 = validateParameter(valid_607817, JString, required = false,
                                 default = nil)
  if valid_607817 != nil:
    section.add "Tier.Name", valid_607817
  var valid_607818 = formData.getOrDefault("Tier.Version")
  valid_607818 = validateParameter(valid_607818, JString, required = false,
                                 default = nil)
  if valid_607818 != nil:
    section.add "Tier.Version", valid_607818
  var valid_607819 = formData.getOrDefault("EnvironmentId")
  valid_607819 = validateParameter(valid_607819, JString, required = false,
                                 default = nil)
  if valid_607819 != nil:
    section.add "EnvironmentId", valid_607819
  var valid_607820 = formData.getOrDefault("SolutionStackName")
  valid_607820 = validateParameter(valid_607820, JString, required = false,
                                 default = nil)
  if valid_607820 != nil:
    section.add "SolutionStackName", valid_607820
  var valid_607821 = formData.getOrDefault("PlatformArn")
  valid_607821 = validateParameter(valid_607821, JString, required = false,
                                 default = nil)
  if valid_607821 != nil:
    section.add "PlatformArn", valid_607821
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607822: Call_PostUpdateEnvironment_607796; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the environment description, deploys a new application version, updates the configuration settings to an entirely new configuration template, or updates select configuration option values in the running environment.</p> <p> Attempting to update both the release and configuration is not allowed and AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. </p> <p> When updating the configuration settings to a new template or individual settings, a draft configuration is created and <a>DescribeConfigurationSettings</a> for this environment returns two setting descriptions with different <code>DeploymentStatus</code> values. </p>
  ## 
  let valid = call_607822.validator(path, query, header, formData, body)
  let scheme = call_607822.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607822.url(scheme.get, call_607822.host, call_607822.base,
                         call_607822.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607822, url, valid)

proc call*(call_607823: Call_PostUpdateEnvironment_607796;
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
  var query_607824 = newJObject()
  var formData_607825 = newJObject()
  add(formData_607825, "Description", newJString(Description))
  add(formData_607825, "Tier.Type", newJString(TierType))
  add(formData_607825, "EnvironmentName", newJString(EnvironmentName))
  add(formData_607825, "VersionLabel", newJString(VersionLabel))
  add(formData_607825, "TemplateName", newJString(TemplateName))
  if OptionsToRemove != nil:
    formData_607825.add "OptionsToRemove", OptionsToRemove
  if OptionSettings != nil:
    formData_607825.add "OptionSettings", OptionSettings
  add(formData_607825, "GroupName", newJString(GroupName))
  add(formData_607825, "ApplicationName", newJString(ApplicationName))
  add(formData_607825, "Tier.Name", newJString(TierName))
  add(formData_607825, "Tier.Version", newJString(TierVersion))
  add(query_607824, "Action", newJString(Action))
  add(formData_607825, "EnvironmentId", newJString(EnvironmentId))
  add(formData_607825, "SolutionStackName", newJString(SolutionStackName))
  add(query_607824, "Version", newJString(Version))
  add(formData_607825, "PlatformArn", newJString(PlatformArn))
  result = call_607823.call(nil, query_607824, nil, formData_607825, nil)

var postUpdateEnvironment* = Call_PostUpdateEnvironment_607796(
    name: "postUpdateEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateEnvironment",
    validator: validate_PostUpdateEnvironment_607797, base: "/",
    url: url_PostUpdateEnvironment_607798, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateEnvironment_607767 = ref object of OpenApiRestCall_605590
proc url_GetUpdateEnvironment_607769(protocol: Scheme; host: string; base: string;
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

proc validate_GetUpdateEnvironment_607768(path: JsonNode; query: JsonNode;
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
  var valid_607770 = query.getOrDefault("ApplicationName")
  valid_607770 = validateParameter(valid_607770, JString, required = false,
                                 default = nil)
  if valid_607770 != nil:
    section.add "ApplicationName", valid_607770
  var valid_607771 = query.getOrDefault("GroupName")
  valid_607771 = validateParameter(valid_607771, JString, required = false,
                                 default = nil)
  if valid_607771 != nil:
    section.add "GroupName", valid_607771
  var valid_607772 = query.getOrDefault("VersionLabel")
  valid_607772 = validateParameter(valid_607772, JString, required = false,
                                 default = nil)
  if valid_607772 != nil:
    section.add "VersionLabel", valid_607772
  var valid_607773 = query.getOrDefault("OptionSettings")
  valid_607773 = validateParameter(valid_607773, JArray, required = false,
                                 default = nil)
  if valid_607773 != nil:
    section.add "OptionSettings", valid_607773
  var valid_607774 = query.getOrDefault("SolutionStackName")
  valid_607774 = validateParameter(valid_607774, JString, required = false,
                                 default = nil)
  if valid_607774 != nil:
    section.add "SolutionStackName", valid_607774
  var valid_607775 = query.getOrDefault("Tier.Name")
  valid_607775 = validateParameter(valid_607775, JString, required = false,
                                 default = nil)
  if valid_607775 != nil:
    section.add "Tier.Name", valid_607775
  var valid_607776 = query.getOrDefault("EnvironmentName")
  valid_607776 = validateParameter(valid_607776, JString, required = false,
                                 default = nil)
  if valid_607776 != nil:
    section.add "EnvironmentName", valid_607776
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607777 = query.getOrDefault("Action")
  valid_607777 = validateParameter(valid_607777, JString, required = true,
                                 default = newJString("UpdateEnvironment"))
  if valid_607777 != nil:
    section.add "Action", valid_607777
  var valid_607778 = query.getOrDefault("Description")
  valid_607778 = validateParameter(valid_607778, JString, required = false,
                                 default = nil)
  if valid_607778 != nil:
    section.add "Description", valid_607778
  var valid_607779 = query.getOrDefault("PlatformArn")
  valid_607779 = validateParameter(valid_607779, JString, required = false,
                                 default = nil)
  if valid_607779 != nil:
    section.add "PlatformArn", valid_607779
  var valid_607780 = query.getOrDefault("OptionsToRemove")
  valid_607780 = validateParameter(valid_607780, JArray, required = false,
                                 default = nil)
  if valid_607780 != nil:
    section.add "OptionsToRemove", valid_607780
  var valid_607781 = query.getOrDefault("Version")
  valid_607781 = validateParameter(valid_607781, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_607781 != nil:
    section.add "Version", valid_607781
  var valid_607782 = query.getOrDefault("TemplateName")
  valid_607782 = validateParameter(valid_607782, JString, required = false,
                                 default = nil)
  if valid_607782 != nil:
    section.add "TemplateName", valid_607782
  var valid_607783 = query.getOrDefault("Tier.Version")
  valid_607783 = validateParameter(valid_607783, JString, required = false,
                                 default = nil)
  if valid_607783 != nil:
    section.add "Tier.Version", valid_607783
  var valid_607784 = query.getOrDefault("EnvironmentId")
  valid_607784 = validateParameter(valid_607784, JString, required = false,
                                 default = nil)
  if valid_607784 != nil:
    section.add "EnvironmentId", valid_607784
  var valid_607785 = query.getOrDefault("Tier.Type")
  valid_607785 = validateParameter(valid_607785, JString, required = false,
                                 default = nil)
  if valid_607785 != nil:
    section.add "Tier.Type", valid_607785
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
  var valid_607786 = header.getOrDefault("X-Amz-Signature")
  valid_607786 = validateParameter(valid_607786, JString, required = false,
                                 default = nil)
  if valid_607786 != nil:
    section.add "X-Amz-Signature", valid_607786
  var valid_607787 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607787 = validateParameter(valid_607787, JString, required = false,
                                 default = nil)
  if valid_607787 != nil:
    section.add "X-Amz-Content-Sha256", valid_607787
  var valid_607788 = header.getOrDefault("X-Amz-Date")
  valid_607788 = validateParameter(valid_607788, JString, required = false,
                                 default = nil)
  if valid_607788 != nil:
    section.add "X-Amz-Date", valid_607788
  var valid_607789 = header.getOrDefault("X-Amz-Credential")
  valid_607789 = validateParameter(valid_607789, JString, required = false,
                                 default = nil)
  if valid_607789 != nil:
    section.add "X-Amz-Credential", valid_607789
  var valid_607790 = header.getOrDefault("X-Amz-Security-Token")
  valid_607790 = validateParameter(valid_607790, JString, required = false,
                                 default = nil)
  if valid_607790 != nil:
    section.add "X-Amz-Security-Token", valid_607790
  var valid_607791 = header.getOrDefault("X-Amz-Algorithm")
  valid_607791 = validateParameter(valid_607791, JString, required = false,
                                 default = nil)
  if valid_607791 != nil:
    section.add "X-Amz-Algorithm", valid_607791
  var valid_607792 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607792 = validateParameter(valid_607792, JString, required = false,
                                 default = nil)
  if valid_607792 != nil:
    section.add "X-Amz-SignedHeaders", valid_607792
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607793: Call_GetUpdateEnvironment_607767; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the environment description, deploys a new application version, updates the configuration settings to an entirely new configuration template, or updates select configuration option values in the running environment.</p> <p> Attempting to update both the release and configuration is not allowed and AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. </p> <p> When updating the configuration settings to a new template or individual settings, a draft configuration is created and <a>DescribeConfigurationSettings</a> for this environment returns two setting descriptions with different <code>DeploymentStatus</code> values. </p>
  ## 
  let valid = call_607793.validator(path, query, header, formData, body)
  let scheme = call_607793.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607793.url(scheme.get, call_607793.host, call_607793.base,
                         call_607793.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607793, url, valid)

proc call*(call_607794: Call_GetUpdateEnvironment_607767;
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
  var query_607795 = newJObject()
  add(query_607795, "ApplicationName", newJString(ApplicationName))
  add(query_607795, "GroupName", newJString(GroupName))
  add(query_607795, "VersionLabel", newJString(VersionLabel))
  if OptionSettings != nil:
    query_607795.add "OptionSettings", OptionSettings
  add(query_607795, "SolutionStackName", newJString(SolutionStackName))
  add(query_607795, "Tier.Name", newJString(TierName))
  add(query_607795, "EnvironmentName", newJString(EnvironmentName))
  add(query_607795, "Action", newJString(Action))
  add(query_607795, "Description", newJString(Description))
  add(query_607795, "PlatformArn", newJString(PlatformArn))
  if OptionsToRemove != nil:
    query_607795.add "OptionsToRemove", OptionsToRemove
  add(query_607795, "Version", newJString(Version))
  add(query_607795, "TemplateName", newJString(TemplateName))
  add(query_607795, "Tier.Version", newJString(TierVersion))
  add(query_607795, "EnvironmentId", newJString(EnvironmentId))
  add(query_607795, "Tier.Type", newJString(TierType))
  result = call_607794.call(nil, query_607795, nil, nil, nil)

var getUpdateEnvironment* = Call_GetUpdateEnvironment_607767(
    name: "getUpdateEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateEnvironment",
    validator: validate_GetUpdateEnvironment_607768, base: "/",
    url: url_GetUpdateEnvironment_607769, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateTagsForResource_607844 = ref object of OpenApiRestCall_605590
proc url_PostUpdateTagsForResource_607846(protocol: Scheme; host: string;
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

proc validate_PostUpdateTagsForResource_607845(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607847 = query.getOrDefault("Action")
  valid_607847 = validateParameter(valid_607847, JString, required = true,
                                 default = newJString("UpdateTagsForResource"))
  if valid_607847 != nil:
    section.add "Action", valid_607847
  var valid_607848 = query.getOrDefault("Version")
  valid_607848 = validateParameter(valid_607848, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_607848 != nil:
    section.add "Version", valid_607848
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
  var valid_607849 = header.getOrDefault("X-Amz-Signature")
  valid_607849 = validateParameter(valid_607849, JString, required = false,
                                 default = nil)
  if valid_607849 != nil:
    section.add "X-Amz-Signature", valid_607849
  var valid_607850 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607850 = validateParameter(valid_607850, JString, required = false,
                                 default = nil)
  if valid_607850 != nil:
    section.add "X-Amz-Content-Sha256", valid_607850
  var valid_607851 = header.getOrDefault("X-Amz-Date")
  valid_607851 = validateParameter(valid_607851, JString, required = false,
                                 default = nil)
  if valid_607851 != nil:
    section.add "X-Amz-Date", valid_607851
  var valid_607852 = header.getOrDefault("X-Amz-Credential")
  valid_607852 = validateParameter(valid_607852, JString, required = false,
                                 default = nil)
  if valid_607852 != nil:
    section.add "X-Amz-Credential", valid_607852
  var valid_607853 = header.getOrDefault("X-Amz-Security-Token")
  valid_607853 = validateParameter(valid_607853, JString, required = false,
                                 default = nil)
  if valid_607853 != nil:
    section.add "X-Amz-Security-Token", valid_607853
  var valid_607854 = header.getOrDefault("X-Amz-Algorithm")
  valid_607854 = validateParameter(valid_607854, JString, required = false,
                                 default = nil)
  if valid_607854 != nil:
    section.add "X-Amz-Algorithm", valid_607854
  var valid_607855 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607855 = validateParameter(valid_607855, JString, required = false,
                                 default = nil)
  if valid_607855 != nil:
    section.add "X-Amz-SignedHeaders", valid_607855
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
  var valid_607856 = formData.getOrDefault("ResourceArn")
  valid_607856 = validateParameter(valid_607856, JString, required = true,
                                 default = nil)
  if valid_607856 != nil:
    section.add "ResourceArn", valid_607856
  var valid_607857 = formData.getOrDefault("TagsToAdd")
  valid_607857 = validateParameter(valid_607857, JArray, required = false,
                                 default = nil)
  if valid_607857 != nil:
    section.add "TagsToAdd", valid_607857
  var valid_607858 = formData.getOrDefault("TagsToRemove")
  valid_607858 = validateParameter(valid_607858, JArray, required = false,
                                 default = nil)
  if valid_607858 != nil:
    section.add "TagsToRemove", valid_607858
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607859: Call_PostUpdateTagsForResource_607844; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Update the list of tags applied to an AWS Elastic Beanstalk resource. Two lists can be passed: <code>TagsToAdd</code> for tags to add or update, and <code>TagsToRemove</code>.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p> <p>If you create a custom IAM user policy to control permission to this operation, specify one of the following two virtual actions (or both) instead of the API operation name:</p> <dl> <dt>elasticbeanstalk:AddTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tags to add in the <code>TagsToAdd</code> parameter.</p> </dd> <dt>elasticbeanstalk:RemoveTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tag keys to remove in the <code>TagsToRemove</code> parameter.</p> </dd> </dl> <p>For details about creating a custom user policy, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/AWSHowTo.iam.managed-policies.html#AWSHowTo.iam.policies">Creating a Custom User Policy</a>.</p>
  ## 
  let valid = call_607859.validator(path, query, header, formData, body)
  let scheme = call_607859.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607859.url(scheme.get, call_607859.host, call_607859.base,
                         call_607859.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607859, url, valid)

proc call*(call_607860: Call_PostUpdateTagsForResource_607844; ResourceArn: string;
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
  var query_607861 = newJObject()
  var formData_607862 = newJObject()
  add(formData_607862, "ResourceArn", newJString(ResourceArn))
  add(query_607861, "Action", newJString(Action))
  if TagsToAdd != nil:
    formData_607862.add "TagsToAdd", TagsToAdd
  if TagsToRemove != nil:
    formData_607862.add "TagsToRemove", TagsToRemove
  add(query_607861, "Version", newJString(Version))
  result = call_607860.call(nil, query_607861, nil, formData_607862, nil)

var postUpdateTagsForResource* = Call_PostUpdateTagsForResource_607844(
    name: "postUpdateTagsForResource", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateTagsForResource",
    validator: validate_PostUpdateTagsForResource_607845, base: "/",
    url: url_PostUpdateTagsForResource_607846,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateTagsForResource_607826 = ref object of OpenApiRestCall_605590
proc url_GetUpdateTagsForResource_607828(protocol: Scheme; host: string;
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

proc validate_GetUpdateTagsForResource_607827(path: JsonNode; query: JsonNode;
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
  var valid_607829 = query.getOrDefault("TagsToAdd")
  valid_607829 = validateParameter(valid_607829, JArray, required = false,
                                 default = nil)
  if valid_607829 != nil:
    section.add "TagsToAdd", valid_607829
  var valid_607830 = query.getOrDefault("TagsToRemove")
  valid_607830 = validateParameter(valid_607830, JArray, required = false,
                                 default = nil)
  if valid_607830 != nil:
    section.add "TagsToRemove", valid_607830
  assert query != nil,
        "query argument is necessary due to required `ResourceArn` field"
  var valid_607831 = query.getOrDefault("ResourceArn")
  valid_607831 = validateParameter(valid_607831, JString, required = true,
                                 default = nil)
  if valid_607831 != nil:
    section.add "ResourceArn", valid_607831
  var valid_607832 = query.getOrDefault("Action")
  valid_607832 = validateParameter(valid_607832, JString, required = true,
                                 default = newJString("UpdateTagsForResource"))
  if valid_607832 != nil:
    section.add "Action", valid_607832
  var valid_607833 = query.getOrDefault("Version")
  valid_607833 = validateParameter(valid_607833, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_607833 != nil:
    section.add "Version", valid_607833
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
  var valid_607834 = header.getOrDefault("X-Amz-Signature")
  valid_607834 = validateParameter(valid_607834, JString, required = false,
                                 default = nil)
  if valid_607834 != nil:
    section.add "X-Amz-Signature", valid_607834
  var valid_607835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607835 = validateParameter(valid_607835, JString, required = false,
                                 default = nil)
  if valid_607835 != nil:
    section.add "X-Amz-Content-Sha256", valid_607835
  var valid_607836 = header.getOrDefault("X-Amz-Date")
  valid_607836 = validateParameter(valid_607836, JString, required = false,
                                 default = nil)
  if valid_607836 != nil:
    section.add "X-Amz-Date", valid_607836
  var valid_607837 = header.getOrDefault("X-Amz-Credential")
  valid_607837 = validateParameter(valid_607837, JString, required = false,
                                 default = nil)
  if valid_607837 != nil:
    section.add "X-Amz-Credential", valid_607837
  var valid_607838 = header.getOrDefault("X-Amz-Security-Token")
  valid_607838 = validateParameter(valid_607838, JString, required = false,
                                 default = nil)
  if valid_607838 != nil:
    section.add "X-Amz-Security-Token", valid_607838
  var valid_607839 = header.getOrDefault("X-Amz-Algorithm")
  valid_607839 = validateParameter(valid_607839, JString, required = false,
                                 default = nil)
  if valid_607839 != nil:
    section.add "X-Amz-Algorithm", valid_607839
  var valid_607840 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607840 = validateParameter(valid_607840, JString, required = false,
                                 default = nil)
  if valid_607840 != nil:
    section.add "X-Amz-SignedHeaders", valid_607840
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607841: Call_GetUpdateTagsForResource_607826; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Update the list of tags applied to an AWS Elastic Beanstalk resource. Two lists can be passed: <code>TagsToAdd</code> for tags to add or update, and <code>TagsToRemove</code>.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p> <p>If you create a custom IAM user policy to control permission to this operation, specify one of the following two virtual actions (or both) instead of the API operation name:</p> <dl> <dt>elasticbeanstalk:AddTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tags to add in the <code>TagsToAdd</code> parameter.</p> </dd> <dt>elasticbeanstalk:RemoveTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tag keys to remove in the <code>TagsToRemove</code> parameter.</p> </dd> </dl> <p>For details about creating a custom user policy, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/AWSHowTo.iam.managed-policies.html#AWSHowTo.iam.policies">Creating a Custom User Policy</a>.</p>
  ## 
  let valid = call_607841.validator(path, query, header, formData, body)
  let scheme = call_607841.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607841.url(scheme.get, call_607841.host, call_607841.base,
                         call_607841.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607841, url, valid)

proc call*(call_607842: Call_GetUpdateTagsForResource_607826; ResourceArn: string;
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
  var query_607843 = newJObject()
  if TagsToAdd != nil:
    query_607843.add "TagsToAdd", TagsToAdd
  if TagsToRemove != nil:
    query_607843.add "TagsToRemove", TagsToRemove
  add(query_607843, "ResourceArn", newJString(ResourceArn))
  add(query_607843, "Action", newJString(Action))
  add(query_607843, "Version", newJString(Version))
  result = call_607842.call(nil, query_607843, nil, nil, nil)

var getUpdateTagsForResource* = Call_GetUpdateTagsForResource_607826(
    name: "getUpdateTagsForResource", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateTagsForResource",
    validator: validate_GetUpdateTagsForResource_607827, base: "/",
    url: url_GetUpdateTagsForResource_607828, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostValidateConfigurationSettings_607882 = ref object of OpenApiRestCall_605590
proc url_PostValidateConfigurationSettings_607884(protocol: Scheme; host: string;
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

proc validate_PostValidateConfigurationSettings_607883(path: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_607885 = query.getOrDefault("Action")
  valid_607885 = validateParameter(valid_607885, JString, required = true, default = newJString(
      "ValidateConfigurationSettings"))
  if valid_607885 != nil:
    section.add "Action", valid_607885
  var valid_607886 = query.getOrDefault("Version")
  valid_607886 = validateParameter(valid_607886, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_607886 != nil:
    section.add "Version", valid_607886
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
  var valid_607887 = header.getOrDefault("X-Amz-Signature")
  valid_607887 = validateParameter(valid_607887, JString, required = false,
                                 default = nil)
  if valid_607887 != nil:
    section.add "X-Amz-Signature", valid_607887
  var valid_607888 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607888 = validateParameter(valid_607888, JString, required = false,
                                 default = nil)
  if valid_607888 != nil:
    section.add "X-Amz-Content-Sha256", valid_607888
  var valid_607889 = header.getOrDefault("X-Amz-Date")
  valid_607889 = validateParameter(valid_607889, JString, required = false,
                                 default = nil)
  if valid_607889 != nil:
    section.add "X-Amz-Date", valid_607889
  var valid_607890 = header.getOrDefault("X-Amz-Credential")
  valid_607890 = validateParameter(valid_607890, JString, required = false,
                                 default = nil)
  if valid_607890 != nil:
    section.add "X-Amz-Credential", valid_607890
  var valid_607891 = header.getOrDefault("X-Amz-Security-Token")
  valid_607891 = validateParameter(valid_607891, JString, required = false,
                                 default = nil)
  if valid_607891 != nil:
    section.add "X-Amz-Security-Token", valid_607891
  var valid_607892 = header.getOrDefault("X-Amz-Algorithm")
  valid_607892 = validateParameter(valid_607892, JString, required = false,
                                 default = nil)
  if valid_607892 != nil:
    section.add "X-Amz-Algorithm", valid_607892
  var valid_607893 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607893 = validateParameter(valid_607893, JString, required = false,
                                 default = nil)
  if valid_607893 != nil:
    section.add "X-Amz-SignedHeaders", valid_607893
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
  var valid_607894 = formData.getOrDefault("EnvironmentName")
  valid_607894 = validateParameter(valid_607894, JString, required = false,
                                 default = nil)
  if valid_607894 != nil:
    section.add "EnvironmentName", valid_607894
  var valid_607895 = formData.getOrDefault("TemplateName")
  valid_607895 = validateParameter(valid_607895, JString, required = false,
                                 default = nil)
  if valid_607895 != nil:
    section.add "TemplateName", valid_607895
  assert formData != nil,
        "formData argument is necessary due to required `OptionSettings` field"
  var valid_607896 = formData.getOrDefault("OptionSettings")
  valid_607896 = validateParameter(valid_607896, JArray, required = true, default = nil)
  if valid_607896 != nil:
    section.add "OptionSettings", valid_607896
  var valid_607897 = formData.getOrDefault("ApplicationName")
  valid_607897 = validateParameter(valid_607897, JString, required = true,
                                 default = nil)
  if valid_607897 != nil:
    section.add "ApplicationName", valid_607897
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607898: Call_PostValidateConfigurationSettings_607882;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Takes a set of configuration settings and either a configuration template or environment, and determines whether those values are valid.</p> <p>This action returns a list of messages indicating any errors or warnings associated with the selection of option values.</p>
  ## 
  let valid = call_607898.validator(path, query, header, formData, body)
  let scheme = call_607898.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607898.url(scheme.get, call_607898.host, call_607898.base,
                         call_607898.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607898, url, valid)

proc call*(call_607899: Call_PostValidateConfigurationSettings_607882;
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
  var query_607900 = newJObject()
  var formData_607901 = newJObject()
  add(formData_607901, "EnvironmentName", newJString(EnvironmentName))
  add(formData_607901, "TemplateName", newJString(TemplateName))
  if OptionSettings != nil:
    formData_607901.add "OptionSettings", OptionSettings
  add(formData_607901, "ApplicationName", newJString(ApplicationName))
  add(query_607900, "Action", newJString(Action))
  add(query_607900, "Version", newJString(Version))
  result = call_607899.call(nil, query_607900, nil, formData_607901, nil)

var postValidateConfigurationSettings* = Call_PostValidateConfigurationSettings_607882(
    name: "postValidateConfigurationSettings", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ValidateConfigurationSettings",
    validator: validate_PostValidateConfigurationSettings_607883, base: "/",
    url: url_PostValidateConfigurationSettings_607884,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetValidateConfigurationSettings_607863 = ref object of OpenApiRestCall_605590
proc url_GetValidateConfigurationSettings_607865(protocol: Scheme; host: string;
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

proc validate_GetValidateConfigurationSettings_607864(path: JsonNode;
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
  var valid_607866 = query.getOrDefault("ApplicationName")
  valid_607866 = validateParameter(valid_607866, JString, required = true,
                                 default = nil)
  if valid_607866 != nil:
    section.add "ApplicationName", valid_607866
  var valid_607867 = query.getOrDefault("OptionSettings")
  valid_607867 = validateParameter(valid_607867, JArray, required = true, default = nil)
  if valid_607867 != nil:
    section.add "OptionSettings", valid_607867
  var valid_607868 = query.getOrDefault("EnvironmentName")
  valid_607868 = validateParameter(valid_607868, JString, required = false,
                                 default = nil)
  if valid_607868 != nil:
    section.add "EnvironmentName", valid_607868
  var valid_607869 = query.getOrDefault("Action")
  valid_607869 = validateParameter(valid_607869, JString, required = true, default = newJString(
      "ValidateConfigurationSettings"))
  if valid_607869 != nil:
    section.add "Action", valid_607869
  var valid_607870 = query.getOrDefault("Version")
  valid_607870 = validateParameter(valid_607870, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_607870 != nil:
    section.add "Version", valid_607870
  var valid_607871 = query.getOrDefault("TemplateName")
  valid_607871 = validateParameter(valid_607871, JString, required = false,
                                 default = nil)
  if valid_607871 != nil:
    section.add "TemplateName", valid_607871
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
  var valid_607872 = header.getOrDefault("X-Amz-Signature")
  valid_607872 = validateParameter(valid_607872, JString, required = false,
                                 default = nil)
  if valid_607872 != nil:
    section.add "X-Amz-Signature", valid_607872
  var valid_607873 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607873 = validateParameter(valid_607873, JString, required = false,
                                 default = nil)
  if valid_607873 != nil:
    section.add "X-Amz-Content-Sha256", valid_607873
  var valid_607874 = header.getOrDefault("X-Amz-Date")
  valid_607874 = validateParameter(valid_607874, JString, required = false,
                                 default = nil)
  if valid_607874 != nil:
    section.add "X-Amz-Date", valid_607874
  var valid_607875 = header.getOrDefault("X-Amz-Credential")
  valid_607875 = validateParameter(valid_607875, JString, required = false,
                                 default = nil)
  if valid_607875 != nil:
    section.add "X-Amz-Credential", valid_607875
  var valid_607876 = header.getOrDefault("X-Amz-Security-Token")
  valid_607876 = validateParameter(valid_607876, JString, required = false,
                                 default = nil)
  if valid_607876 != nil:
    section.add "X-Amz-Security-Token", valid_607876
  var valid_607877 = header.getOrDefault("X-Amz-Algorithm")
  valid_607877 = validateParameter(valid_607877, JString, required = false,
                                 default = nil)
  if valid_607877 != nil:
    section.add "X-Amz-Algorithm", valid_607877
  var valid_607878 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607878 = validateParameter(valid_607878, JString, required = false,
                                 default = nil)
  if valid_607878 != nil:
    section.add "X-Amz-SignedHeaders", valid_607878
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607879: Call_GetValidateConfigurationSettings_607863;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Takes a set of configuration settings and either a configuration template or environment, and determines whether those values are valid.</p> <p>This action returns a list of messages indicating any errors or warnings associated with the selection of option values.</p>
  ## 
  let valid = call_607879.validator(path, query, header, formData, body)
  let scheme = call_607879.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607879.url(scheme.get, call_607879.host, call_607879.base,
                         call_607879.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607879, url, valid)

proc call*(call_607880: Call_GetValidateConfigurationSettings_607863;
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
  var query_607881 = newJObject()
  add(query_607881, "ApplicationName", newJString(ApplicationName))
  if OptionSettings != nil:
    query_607881.add "OptionSettings", OptionSettings
  add(query_607881, "EnvironmentName", newJString(EnvironmentName))
  add(query_607881, "Action", newJString(Action))
  add(query_607881, "Version", newJString(Version))
  add(query_607881, "TemplateName", newJString(TemplateName))
  result = call_607880.call(nil, query_607881, nil, nil, nil)

var getValidateConfigurationSettings* = Call_GetValidateConfigurationSettings_607863(
    name: "getValidateConfigurationSettings", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ValidateConfigurationSettings",
    validator: validate_GetValidateConfigurationSettings_607864, base: "/",
    url: url_GetValidateConfigurationSettings_607865,
    schemes: {Scheme.Https, Scheme.Http})
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
  result = newRecallable(call, url, headers, $input.getOrDefault("body"))
  result.atozSign(input.getOrDefault("query"), SHA256)

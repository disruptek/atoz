
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_602467 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602467](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602467): Option[Scheme] {.used.} =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostAbortEnvironmentUpdate_603076 = ref object of OpenApiRestCall_602467
proc url_PostAbortEnvironmentUpdate_603078(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostAbortEnvironmentUpdate_603077(path: JsonNode; query: JsonNode;
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
  var valid_603079 = query.getOrDefault("Action")
  valid_603079 = validateParameter(valid_603079, JString, required = true,
                                 default = newJString("AbortEnvironmentUpdate"))
  if valid_603079 != nil:
    section.add "Action", valid_603079
  var valid_603080 = query.getOrDefault("Version")
  valid_603080 = validateParameter(valid_603080, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603080 != nil:
    section.add "Version", valid_603080
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
  var valid_603081 = header.getOrDefault("X-Amz-Date")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-Date", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Security-Token")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Security-Token", valid_603082
  var valid_603083 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603083 = validateParameter(valid_603083, JString, required = false,
                                 default = nil)
  if valid_603083 != nil:
    section.add "X-Amz-Content-Sha256", valid_603083
  var valid_603084 = header.getOrDefault("X-Amz-Algorithm")
  valid_603084 = validateParameter(valid_603084, JString, required = false,
                                 default = nil)
  if valid_603084 != nil:
    section.add "X-Amz-Algorithm", valid_603084
  var valid_603085 = header.getOrDefault("X-Amz-Signature")
  valid_603085 = validateParameter(valid_603085, JString, required = false,
                                 default = nil)
  if valid_603085 != nil:
    section.add "X-Amz-Signature", valid_603085
  var valid_603086 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603086 = validateParameter(valid_603086, JString, required = false,
                                 default = nil)
  if valid_603086 != nil:
    section.add "X-Amz-SignedHeaders", valid_603086
  var valid_603087 = header.getOrDefault("X-Amz-Credential")
  valid_603087 = validateParameter(valid_603087, JString, required = false,
                                 default = nil)
  if valid_603087 != nil:
    section.add "X-Amz-Credential", valid_603087
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentId: JString
  ##                : This specifies the ID of the environment with the in-progress update that you want to cancel.
  ##   EnvironmentName: JString
  ##                  : This specifies the name of the environment with the in-progress update that you want to cancel.
  section = newJObject()
  var valid_603088 = formData.getOrDefault("EnvironmentId")
  valid_603088 = validateParameter(valid_603088, JString, required = false,
                                 default = nil)
  if valid_603088 != nil:
    section.add "EnvironmentId", valid_603088
  var valid_603089 = formData.getOrDefault("EnvironmentName")
  valid_603089 = validateParameter(valid_603089, JString, required = false,
                                 default = nil)
  if valid_603089 != nil:
    section.add "EnvironmentName", valid_603089
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603090: Call_PostAbortEnvironmentUpdate_603076; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels in-progress environment configuration update or application version deployment.
  ## 
  let valid = call_603090.validator(path, query, header, formData, body)
  let scheme = call_603090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603090.url(scheme.get, call_603090.host, call_603090.base,
                         call_603090.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603090, url, valid)

proc call*(call_603091: Call_PostAbortEnvironmentUpdate_603076;
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
  var query_603092 = newJObject()
  var formData_603093 = newJObject()
  add(formData_603093, "EnvironmentId", newJString(EnvironmentId))
  add(formData_603093, "EnvironmentName", newJString(EnvironmentName))
  add(query_603092, "Action", newJString(Action))
  add(query_603092, "Version", newJString(Version))
  result = call_603091.call(nil, query_603092, nil, formData_603093, nil)

var postAbortEnvironmentUpdate* = Call_PostAbortEnvironmentUpdate_603076(
    name: "postAbortEnvironmentUpdate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=AbortEnvironmentUpdate",
    validator: validate_PostAbortEnvironmentUpdate_603077, base: "/",
    url: url_PostAbortEnvironmentUpdate_603078,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAbortEnvironmentUpdate_602804 = ref object of OpenApiRestCall_602467
proc url_GetAbortEnvironmentUpdate_602806(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAbortEnvironmentUpdate_602805(path: JsonNode; query: JsonNode;
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
  ##   EnvironmentId: JString
  ##                : This specifies the ID of the environment with the in-progress update that you want to cancel.
  ##   Version: JString (required)
  section = newJObject()
  var valid_602918 = query.getOrDefault("EnvironmentName")
  valid_602918 = validateParameter(valid_602918, JString, required = false,
                                 default = nil)
  if valid_602918 != nil:
    section.add "EnvironmentName", valid_602918
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602932 = query.getOrDefault("Action")
  valid_602932 = validateParameter(valid_602932, JString, required = true,
                                 default = newJString("AbortEnvironmentUpdate"))
  if valid_602932 != nil:
    section.add "Action", valid_602932
  var valid_602933 = query.getOrDefault("EnvironmentId")
  valid_602933 = validateParameter(valid_602933, JString, required = false,
                                 default = nil)
  if valid_602933 != nil:
    section.add "EnvironmentId", valid_602933
  var valid_602934 = query.getOrDefault("Version")
  valid_602934 = validateParameter(valid_602934, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602934 != nil:
    section.add "Version", valid_602934
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
  var valid_602935 = header.getOrDefault("X-Amz-Date")
  valid_602935 = validateParameter(valid_602935, JString, required = false,
                                 default = nil)
  if valid_602935 != nil:
    section.add "X-Amz-Date", valid_602935
  var valid_602936 = header.getOrDefault("X-Amz-Security-Token")
  valid_602936 = validateParameter(valid_602936, JString, required = false,
                                 default = nil)
  if valid_602936 != nil:
    section.add "X-Amz-Security-Token", valid_602936
  var valid_602937 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602937 = validateParameter(valid_602937, JString, required = false,
                                 default = nil)
  if valid_602937 != nil:
    section.add "X-Amz-Content-Sha256", valid_602937
  var valid_602938 = header.getOrDefault("X-Amz-Algorithm")
  valid_602938 = validateParameter(valid_602938, JString, required = false,
                                 default = nil)
  if valid_602938 != nil:
    section.add "X-Amz-Algorithm", valid_602938
  var valid_602939 = header.getOrDefault("X-Amz-Signature")
  valid_602939 = validateParameter(valid_602939, JString, required = false,
                                 default = nil)
  if valid_602939 != nil:
    section.add "X-Amz-Signature", valid_602939
  var valid_602940 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602940 = validateParameter(valid_602940, JString, required = false,
                                 default = nil)
  if valid_602940 != nil:
    section.add "X-Amz-SignedHeaders", valid_602940
  var valid_602941 = header.getOrDefault("X-Amz-Credential")
  valid_602941 = validateParameter(valid_602941, JString, required = false,
                                 default = nil)
  if valid_602941 != nil:
    section.add "X-Amz-Credential", valid_602941
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602964: Call_GetAbortEnvironmentUpdate_602804; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels in-progress environment configuration update or application version deployment.
  ## 
  let valid = call_602964.validator(path, query, header, formData, body)
  let scheme = call_602964.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602964.url(scheme.get, call_602964.host, call_602964.base,
                         call_602964.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602964, url, valid)

proc call*(call_603035: Call_GetAbortEnvironmentUpdate_602804;
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
  var query_603036 = newJObject()
  add(query_603036, "EnvironmentName", newJString(EnvironmentName))
  add(query_603036, "Action", newJString(Action))
  add(query_603036, "EnvironmentId", newJString(EnvironmentId))
  add(query_603036, "Version", newJString(Version))
  result = call_603035.call(nil, query_603036, nil, nil, nil)

var getAbortEnvironmentUpdate* = Call_GetAbortEnvironmentUpdate_602804(
    name: "getAbortEnvironmentUpdate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=AbortEnvironmentUpdate",
    validator: validate_GetAbortEnvironmentUpdate_602805, base: "/",
    url: url_GetAbortEnvironmentUpdate_602806,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostApplyEnvironmentManagedAction_603112 = ref object of OpenApiRestCall_602467
proc url_PostApplyEnvironmentManagedAction_603114(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostApplyEnvironmentManagedAction_603113(path: JsonNode;
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
  var valid_603115 = query.getOrDefault("Action")
  valid_603115 = validateParameter(valid_603115, JString, required = true, default = newJString(
      "ApplyEnvironmentManagedAction"))
  if valid_603115 != nil:
    section.add "Action", valid_603115
  var valid_603116 = query.getOrDefault("Version")
  valid_603116 = validateParameter(valid_603116, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603116 != nil:
    section.add "Version", valid_603116
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
  var valid_603117 = header.getOrDefault("X-Amz-Date")
  valid_603117 = validateParameter(valid_603117, JString, required = false,
                                 default = nil)
  if valid_603117 != nil:
    section.add "X-Amz-Date", valid_603117
  var valid_603118 = header.getOrDefault("X-Amz-Security-Token")
  valid_603118 = validateParameter(valid_603118, JString, required = false,
                                 default = nil)
  if valid_603118 != nil:
    section.add "X-Amz-Security-Token", valid_603118
  var valid_603119 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603119 = validateParameter(valid_603119, JString, required = false,
                                 default = nil)
  if valid_603119 != nil:
    section.add "X-Amz-Content-Sha256", valid_603119
  var valid_603120 = header.getOrDefault("X-Amz-Algorithm")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Algorithm", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-Signature")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Signature", valid_603121
  var valid_603122 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603122 = validateParameter(valid_603122, JString, required = false,
                                 default = nil)
  if valid_603122 != nil:
    section.add "X-Amz-SignedHeaders", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-Credential")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-Credential", valid_603123
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentId: JString
  ##                : The environment ID of the target environment.
  ##   EnvironmentName: JString
  ##                  : The name of the target environment.
  ##   ActionId: JString (required)
  ##           : The action ID of the scheduled managed action to execute.
  section = newJObject()
  var valid_603124 = formData.getOrDefault("EnvironmentId")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "EnvironmentId", valid_603124
  var valid_603125 = formData.getOrDefault("EnvironmentName")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "EnvironmentName", valid_603125
  assert formData != nil,
        "formData argument is necessary due to required `ActionId` field"
  var valid_603126 = formData.getOrDefault("ActionId")
  valid_603126 = validateParameter(valid_603126, JString, required = true,
                                 default = nil)
  if valid_603126 != nil:
    section.add "ActionId", valid_603126
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603127: Call_PostApplyEnvironmentManagedAction_603112;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Applies a scheduled managed action immediately. A managed action can be applied only if its status is <code>Scheduled</code>. Get the status and action ID of a managed action with <a>DescribeEnvironmentManagedActions</a>.
  ## 
  let valid = call_603127.validator(path, query, header, formData, body)
  let scheme = call_603127.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603127.url(scheme.get, call_603127.host, call_603127.base,
                         call_603127.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603127, url, valid)

proc call*(call_603128: Call_PostApplyEnvironmentManagedAction_603112;
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
  var query_603129 = newJObject()
  var formData_603130 = newJObject()
  add(formData_603130, "EnvironmentId", newJString(EnvironmentId))
  add(formData_603130, "EnvironmentName", newJString(EnvironmentName))
  add(query_603129, "Action", newJString(Action))
  add(formData_603130, "ActionId", newJString(ActionId))
  add(query_603129, "Version", newJString(Version))
  result = call_603128.call(nil, query_603129, nil, formData_603130, nil)

var postApplyEnvironmentManagedAction* = Call_PostApplyEnvironmentManagedAction_603112(
    name: "postApplyEnvironmentManagedAction", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ApplyEnvironmentManagedAction",
    validator: validate_PostApplyEnvironmentManagedAction_603113, base: "/",
    url: url_PostApplyEnvironmentManagedAction_603114,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplyEnvironmentManagedAction_603094 = ref object of OpenApiRestCall_602467
proc url_GetApplyEnvironmentManagedAction_603096(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetApplyEnvironmentManagedAction_603095(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_603097 = query.getOrDefault("EnvironmentName")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "EnvironmentName", valid_603097
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603098 = query.getOrDefault("Action")
  valid_603098 = validateParameter(valid_603098, JString, required = true, default = newJString(
      "ApplyEnvironmentManagedAction"))
  if valid_603098 != nil:
    section.add "Action", valid_603098
  var valid_603099 = query.getOrDefault("EnvironmentId")
  valid_603099 = validateParameter(valid_603099, JString, required = false,
                                 default = nil)
  if valid_603099 != nil:
    section.add "EnvironmentId", valid_603099
  var valid_603100 = query.getOrDefault("ActionId")
  valid_603100 = validateParameter(valid_603100, JString, required = true,
                                 default = nil)
  if valid_603100 != nil:
    section.add "ActionId", valid_603100
  var valid_603101 = query.getOrDefault("Version")
  valid_603101 = validateParameter(valid_603101, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603101 != nil:
    section.add "Version", valid_603101
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
  var valid_603102 = header.getOrDefault("X-Amz-Date")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "X-Amz-Date", valid_603102
  var valid_603103 = header.getOrDefault("X-Amz-Security-Token")
  valid_603103 = validateParameter(valid_603103, JString, required = false,
                                 default = nil)
  if valid_603103 != nil:
    section.add "X-Amz-Security-Token", valid_603103
  var valid_603104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603104 = validateParameter(valid_603104, JString, required = false,
                                 default = nil)
  if valid_603104 != nil:
    section.add "X-Amz-Content-Sha256", valid_603104
  var valid_603105 = header.getOrDefault("X-Amz-Algorithm")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Algorithm", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Signature")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Signature", valid_603106
  var valid_603107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603107 = validateParameter(valid_603107, JString, required = false,
                                 default = nil)
  if valid_603107 != nil:
    section.add "X-Amz-SignedHeaders", valid_603107
  var valid_603108 = header.getOrDefault("X-Amz-Credential")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "X-Amz-Credential", valid_603108
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603109: Call_GetApplyEnvironmentManagedAction_603094;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Applies a scheduled managed action immediately. A managed action can be applied only if its status is <code>Scheduled</code>. Get the status and action ID of a managed action with <a>DescribeEnvironmentManagedActions</a>.
  ## 
  let valid = call_603109.validator(path, query, header, formData, body)
  let scheme = call_603109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603109.url(scheme.get, call_603109.host, call_603109.base,
                         call_603109.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603109, url, valid)

proc call*(call_603110: Call_GetApplyEnvironmentManagedAction_603094;
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
  var query_603111 = newJObject()
  add(query_603111, "EnvironmentName", newJString(EnvironmentName))
  add(query_603111, "Action", newJString(Action))
  add(query_603111, "EnvironmentId", newJString(EnvironmentId))
  add(query_603111, "ActionId", newJString(ActionId))
  add(query_603111, "Version", newJString(Version))
  result = call_603110.call(nil, query_603111, nil, nil, nil)

var getApplyEnvironmentManagedAction* = Call_GetApplyEnvironmentManagedAction_603094(
    name: "getApplyEnvironmentManagedAction", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ApplyEnvironmentManagedAction",
    validator: validate_GetApplyEnvironmentManagedAction_603095, base: "/",
    url: url_GetApplyEnvironmentManagedAction_603096,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCheckDNSAvailability_603147 = ref object of OpenApiRestCall_602467
proc url_PostCheckDNSAvailability_603149(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCheckDNSAvailability_603148(path: JsonNode; query: JsonNode;
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
  var valid_603150 = query.getOrDefault("Action")
  valid_603150 = validateParameter(valid_603150, JString, required = true,
                                 default = newJString("CheckDNSAvailability"))
  if valid_603150 != nil:
    section.add "Action", valid_603150
  var valid_603151 = query.getOrDefault("Version")
  valid_603151 = validateParameter(valid_603151, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603151 != nil:
    section.add "Version", valid_603151
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
  var valid_603152 = header.getOrDefault("X-Amz-Date")
  valid_603152 = validateParameter(valid_603152, JString, required = false,
                                 default = nil)
  if valid_603152 != nil:
    section.add "X-Amz-Date", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-Security-Token")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-Security-Token", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Content-Sha256", valid_603154
  var valid_603155 = header.getOrDefault("X-Amz-Algorithm")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-Algorithm", valid_603155
  var valid_603156 = header.getOrDefault("X-Amz-Signature")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-Signature", valid_603156
  var valid_603157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "X-Amz-SignedHeaders", valid_603157
  var valid_603158 = header.getOrDefault("X-Amz-Credential")
  valid_603158 = validateParameter(valid_603158, JString, required = false,
                                 default = nil)
  if valid_603158 != nil:
    section.add "X-Amz-Credential", valid_603158
  result.add "header", section
  ## parameters in `formData` object:
  ##   CNAMEPrefix: JString (required)
  ##              : The prefix used when this CNAME is reserved.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `CNAMEPrefix` field"
  var valid_603159 = formData.getOrDefault("CNAMEPrefix")
  valid_603159 = validateParameter(valid_603159, JString, required = true,
                                 default = nil)
  if valid_603159 != nil:
    section.add "CNAMEPrefix", valid_603159
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603160: Call_PostCheckDNSAvailability_603147; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Checks if the specified CNAME is available.
  ## 
  let valid = call_603160.validator(path, query, header, formData, body)
  let scheme = call_603160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603160.url(scheme.get, call_603160.host, call_603160.base,
                         call_603160.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603160, url, valid)

proc call*(call_603161: Call_PostCheckDNSAvailability_603147; CNAMEPrefix: string;
          Action: string = "CheckDNSAvailability"; Version: string = "2010-12-01"): Recallable =
  ## postCheckDNSAvailability
  ## Checks if the specified CNAME is available.
  ##   CNAMEPrefix: string (required)
  ##              : The prefix used when this CNAME is reserved.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603162 = newJObject()
  var formData_603163 = newJObject()
  add(formData_603163, "CNAMEPrefix", newJString(CNAMEPrefix))
  add(query_603162, "Action", newJString(Action))
  add(query_603162, "Version", newJString(Version))
  result = call_603161.call(nil, query_603162, nil, formData_603163, nil)

var postCheckDNSAvailability* = Call_PostCheckDNSAvailability_603147(
    name: "postCheckDNSAvailability", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CheckDNSAvailability",
    validator: validate_PostCheckDNSAvailability_603148, base: "/",
    url: url_PostCheckDNSAvailability_603149, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCheckDNSAvailability_603131 = ref object of OpenApiRestCall_602467
proc url_GetCheckDNSAvailability_603133(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCheckDNSAvailability_603132(path: JsonNode; query: JsonNode;
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
  ##   CNAMEPrefix: JString (required)
  ##              : The prefix used when this CNAME is reserved.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603134 = query.getOrDefault("Action")
  valid_603134 = validateParameter(valid_603134, JString, required = true,
                                 default = newJString("CheckDNSAvailability"))
  if valid_603134 != nil:
    section.add "Action", valid_603134
  var valid_603135 = query.getOrDefault("Version")
  valid_603135 = validateParameter(valid_603135, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603135 != nil:
    section.add "Version", valid_603135
  var valid_603136 = query.getOrDefault("CNAMEPrefix")
  valid_603136 = validateParameter(valid_603136, JString, required = true,
                                 default = nil)
  if valid_603136 != nil:
    section.add "CNAMEPrefix", valid_603136
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
  var valid_603137 = header.getOrDefault("X-Amz-Date")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "X-Amz-Date", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-Security-Token")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Security-Token", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Content-Sha256", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-Algorithm")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-Algorithm", valid_603140
  var valid_603141 = header.getOrDefault("X-Amz-Signature")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-Signature", valid_603141
  var valid_603142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-SignedHeaders", valid_603142
  var valid_603143 = header.getOrDefault("X-Amz-Credential")
  valid_603143 = validateParameter(valid_603143, JString, required = false,
                                 default = nil)
  if valid_603143 != nil:
    section.add "X-Amz-Credential", valid_603143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603144: Call_GetCheckDNSAvailability_603131; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Checks if the specified CNAME is available.
  ## 
  let valid = call_603144.validator(path, query, header, formData, body)
  let scheme = call_603144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603144.url(scheme.get, call_603144.host, call_603144.base,
                         call_603144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603144, url, valid)

proc call*(call_603145: Call_GetCheckDNSAvailability_603131; CNAMEPrefix: string;
          Action: string = "CheckDNSAvailability"; Version: string = "2010-12-01"): Recallable =
  ## getCheckDNSAvailability
  ## Checks if the specified CNAME is available.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   CNAMEPrefix: string (required)
  ##              : The prefix used when this CNAME is reserved.
  var query_603146 = newJObject()
  add(query_603146, "Action", newJString(Action))
  add(query_603146, "Version", newJString(Version))
  add(query_603146, "CNAMEPrefix", newJString(CNAMEPrefix))
  result = call_603145.call(nil, query_603146, nil, nil, nil)

var getCheckDNSAvailability* = Call_GetCheckDNSAvailability_603131(
    name: "getCheckDNSAvailability", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CheckDNSAvailability",
    validator: validate_GetCheckDNSAvailability_603132, base: "/",
    url: url_GetCheckDNSAvailability_603133, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostComposeEnvironments_603182 = ref object of OpenApiRestCall_602467
proc url_PostComposeEnvironments_603184(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostComposeEnvironments_603183(path: JsonNode; query: JsonNode;
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
  var valid_603185 = query.getOrDefault("Action")
  valid_603185 = validateParameter(valid_603185, JString, required = true,
                                 default = newJString("ComposeEnvironments"))
  if valid_603185 != nil:
    section.add "Action", valid_603185
  var valid_603186 = query.getOrDefault("Version")
  valid_603186 = validateParameter(valid_603186, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603186 != nil:
    section.add "Version", valid_603186
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
  var valid_603187 = header.getOrDefault("X-Amz-Date")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "X-Amz-Date", valid_603187
  var valid_603188 = header.getOrDefault("X-Amz-Security-Token")
  valid_603188 = validateParameter(valid_603188, JString, required = false,
                                 default = nil)
  if valid_603188 != nil:
    section.add "X-Amz-Security-Token", valid_603188
  var valid_603189 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603189 = validateParameter(valid_603189, JString, required = false,
                                 default = nil)
  if valid_603189 != nil:
    section.add "X-Amz-Content-Sha256", valid_603189
  var valid_603190 = header.getOrDefault("X-Amz-Algorithm")
  valid_603190 = validateParameter(valid_603190, JString, required = false,
                                 default = nil)
  if valid_603190 != nil:
    section.add "X-Amz-Algorithm", valid_603190
  var valid_603191 = header.getOrDefault("X-Amz-Signature")
  valid_603191 = validateParameter(valid_603191, JString, required = false,
                                 default = nil)
  if valid_603191 != nil:
    section.add "X-Amz-Signature", valid_603191
  var valid_603192 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603192 = validateParameter(valid_603192, JString, required = false,
                                 default = nil)
  if valid_603192 != nil:
    section.add "X-Amz-SignedHeaders", valid_603192
  var valid_603193 = header.getOrDefault("X-Amz-Credential")
  valid_603193 = validateParameter(valid_603193, JString, required = false,
                                 default = nil)
  if valid_603193 != nil:
    section.add "X-Amz-Credential", valid_603193
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
  var valid_603194 = formData.getOrDefault("GroupName")
  valid_603194 = validateParameter(valid_603194, JString, required = false,
                                 default = nil)
  if valid_603194 != nil:
    section.add "GroupName", valid_603194
  var valid_603195 = formData.getOrDefault("ApplicationName")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "ApplicationName", valid_603195
  var valid_603196 = formData.getOrDefault("VersionLabels")
  valid_603196 = validateParameter(valid_603196, JArray, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "VersionLabels", valid_603196
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603197: Call_PostComposeEnvironments_603182; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create or update a group of environments that each run a separate component of a single application. Takes a list of version labels that specify application source bundles for each of the environments to create or update. The name of each environment and other required information must be included in the source bundles in an environment manifest named <code>env.yaml</code>. See <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-mgmt-compose.html">Compose Environments</a> for details.
  ## 
  let valid = call_603197.validator(path, query, header, formData, body)
  let scheme = call_603197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603197.url(scheme.get, call_603197.host, call_603197.base,
                         call_603197.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603197, url, valid)

proc call*(call_603198: Call_PostComposeEnvironments_603182;
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
  var query_603199 = newJObject()
  var formData_603200 = newJObject()
  add(formData_603200, "GroupName", newJString(GroupName))
  add(query_603199, "Action", newJString(Action))
  add(formData_603200, "ApplicationName", newJString(ApplicationName))
  add(query_603199, "Version", newJString(Version))
  if VersionLabels != nil:
    formData_603200.add "VersionLabels", VersionLabels
  result = call_603198.call(nil, query_603199, nil, formData_603200, nil)

var postComposeEnvironments* = Call_PostComposeEnvironments_603182(
    name: "postComposeEnvironments", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ComposeEnvironments",
    validator: validate_PostComposeEnvironments_603183, base: "/",
    url: url_PostComposeEnvironments_603184, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetComposeEnvironments_603164 = ref object of OpenApiRestCall_602467
proc url_GetComposeEnvironments_603166(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetComposeEnvironments_603165(path: JsonNode; query: JsonNode;
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
  ##   Action: JString (required)
  ##   GroupName: JString
  ##            : The name of the group to which the target environments belong. Specify a group name only if the environment name defined in each target environment's manifest ends with a + (plus) character. See <a 
  ## href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-cfg-manifest.html">Environment Manifest (env.yaml)</a> for details.
  ##   VersionLabels: JArray
  ##                : A list of version labels, specifying one or more application source bundles that belong to the target application. Each source bundle must include an environment manifest that specifies the name of the environment and the name of the solution stack to use, and optionally can specify environment links to create.
  ##   Version: JString (required)
  section = newJObject()
  var valid_603167 = query.getOrDefault("ApplicationName")
  valid_603167 = validateParameter(valid_603167, JString, required = false,
                                 default = nil)
  if valid_603167 != nil:
    section.add "ApplicationName", valid_603167
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603168 = query.getOrDefault("Action")
  valid_603168 = validateParameter(valid_603168, JString, required = true,
                                 default = newJString("ComposeEnvironments"))
  if valid_603168 != nil:
    section.add "Action", valid_603168
  var valid_603169 = query.getOrDefault("GroupName")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "GroupName", valid_603169
  var valid_603170 = query.getOrDefault("VersionLabels")
  valid_603170 = validateParameter(valid_603170, JArray, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "VersionLabels", valid_603170
  var valid_603171 = query.getOrDefault("Version")
  valid_603171 = validateParameter(valid_603171, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603171 != nil:
    section.add "Version", valid_603171
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
  var valid_603172 = header.getOrDefault("X-Amz-Date")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "X-Amz-Date", valid_603172
  var valid_603173 = header.getOrDefault("X-Amz-Security-Token")
  valid_603173 = validateParameter(valid_603173, JString, required = false,
                                 default = nil)
  if valid_603173 != nil:
    section.add "X-Amz-Security-Token", valid_603173
  var valid_603174 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603174 = validateParameter(valid_603174, JString, required = false,
                                 default = nil)
  if valid_603174 != nil:
    section.add "X-Amz-Content-Sha256", valid_603174
  var valid_603175 = header.getOrDefault("X-Amz-Algorithm")
  valid_603175 = validateParameter(valid_603175, JString, required = false,
                                 default = nil)
  if valid_603175 != nil:
    section.add "X-Amz-Algorithm", valid_603175
  var valid_603176 = header.getOrDefault("X-Amz-Signature")
  valid_603176 = validateParameter(valid_603176, JString, required = false,
                                 default = nil)
  if valid_603176 != nil:
    section.add "X-Amz-Signature", valid_603176
  var valid_603177 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603177 = validateParameter(valid_603177, JString, required = false,
                                 default = nil)
  if valid_603177 != nil:
    section.add "X-Amz-SignedHeaders", valid_603177
  var valid_603178 = header.getOrDefault("X-Amz-Credential")
  valid_603178 = validateParameter(valid_603178, JString, required = false,
                                 default = nil)
  if valid_603178 != nil:
    section.add "X-Amz-Credential", valid_603178
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603179: Call_GetComposeEnvironments_603164; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create or update a group of environments that each run a separate component of a single application. Takes a list of version labels that specify application source bundles for each of the environments to create or update. The name of each environment and other required information must be included in the source bundles in an environment manifest named <code>env.yaml</code>. See <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-mgmt-compose.html">Compose Environments</a> for details.
  ## 
  let valid = call_603179.validator(path, query, header, formData, body)
  let scheme = call_603179.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603179.url(scheme.get, call_603179.host, call_603179.base,
                         call_603179.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603179, url, valid)

proc call*(call_603180: Call_GetComposeEnvironments_603164;
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
  var query_603181 = newJObject()
  add(query_603181, "ApplicationName", newJString(ApplicationName))
  add(query_603181, "Action", newJString(Action))
  add(query_603181, "GroupName", newJString(GroupName))
  if VersionLabels != nil:
    query_603181.add "VersionLabels", VersionLabels
  add(query_603181, "Version", newJString(Version))
  result = call_603180.call(nil, query_603181, nil, nil, nil)

var getComposeEnvironments* = Call_GetComposeEnvironments_603164(
    name: "getComposeEnvironments", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ComposeEnvironments",
    validator: validate_GetComposeEnvironments_603165, base: "/",
    url: url_GetComposeEnvironments_603166, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateApplication_603221 = ref object of OpenApiRestCall_602467
proc url_PostCreateApplication_603223(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateApplication_603222(path: JsonNode; query: JsonNode;
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
  var valid_603224 = query.getOrDefault("Action")
  valid_603224 = validateParameter(valid_603224, JString, required = true,
                                 default = newJString("CreateApplication"))
  if valid_603224 != nil:
    section.add "Action", valid_603224
  var valid_603225 = query.getOrDefault("Version")
  valid_603225 = validateParameter(valid_603225, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603225 != nil:
    section.add "Version", valid_603225
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
  var valid_603226 = header.getOrDefault("X-Amz-Date")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-Date", valid_603226
  var valid_603227 = header.getOrDefault("X-Amz-Security-Token")
  valid_603227 = validateParameter(valid_603227, JString, required = false,
                                 default = nil)
  if valid_603227 != nil:
    section.add "X-Amz-Security-Token", valid_603227
  var valid_603228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "X-Amz-Content-Sha256", valid_603228
  var valid_603229 = header.getOrDefault("X-Amz-Algorithm")
  valid_603229 = validateParameter(valid_603229, JString, required = false,
                                 default = nil)
  if valid_603229 != nil:
    section.add "X-Amz-Algorithm", valid_603229
  var valid_603230 = header.getOrDefault("X-Amz-Signature")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "X-Amz-Signature", valid_603230
  var valid_603231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603231 = validateParameter(valid_603231, JString, required = false,
                                 default = nil)
  if valid_603231 != nil:
    section.add "X-Amz-SignedHeaders", valid_603231
  var valid_603232 = header.getOrDefault("X-Amz-Credential")
  valid_603232 = validateParameter(valid_603232, JString, required = false,
                                 default = nil)
  if valid_603232 != nil:
    section.add "X-Amz-Credential", valid_603232
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
  var valid_603233 = formData.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_603233 = validateParameter(valid_603233, JString, required = false,
                                 default = nil)
  if valid_603233 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_603233
  var valid_603234 = formData.getOrDefault("Tags")
  valid_603234 = validateParameter(valid_603234, JArray, required = false,
                                 default = nil)
  if valid_603234 != nil:
    section.add "Tags", valid_603234
  var valid_603235 = formData.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_603235 = validateParameter(valid_603235, JString, required = false,
                                 default = nil)
  if valid_603235 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_603235
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_603236 = formData.getOrDefault("ApplicationName")
  valid_603236 = validateParameter(valid_603236, JString, required = true,
                                 default = nil)
  if valid_603236 != nil:
    section.add "ApplicationName", valid_603236
  var valid_603237 = formData.getOrDefault("Description")
  valid_603237 = validateParameter(valid_603237, JString, required = false,
                                 default = nil)
  if valid_603237 != nil:
    section.add "Description", valid_603237
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603238: Call_PostCreateApplication_603221; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates an application that has one configuration template named <code>default</code> and no application versions. 
  ## 
  let valid = call_603238.validator(path, query, header, formData, body)
  let scheme = call_603238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603238.url(scheme.get, call_603238.host, call_603238.base,
                         call_603238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603238, url, valid)

proc call*(call_603239: Call_PostCreateApplication_603221; ApplicationName: string;
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
  var query_603240 = newJObject()
  var formData_603241 = newJObject()
  add(formData_603241, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  if Tags != nil:
    formData_603241.add "Tags", Tags
  add(formData_603241, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  add(query_603240, "Action", newJString(Action))
  add(formData_603241, "ApplicationName", newJString(ApplicationName))
  add(query_603240, "Version", newJString(Version))
  add(formData_603241, "Description", newJString(Description))
  result = call_603239.call(nil, query_603240, nil, formData_603241, nil)

var postCreateApplication* = Call_PostCreateApplication_603221(
    name: "postCreateApplication", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateApplication",
    validator: validate_PostCreateApplication_603222, base: "/",
    url: url_PostCreateApplication_603223, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateApplication_603201 = ref object of OpenApiRestCall_602467
proc url_GetCreateApplication_603203(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateApplication_603202(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_603204 = query.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_603204 = validateParameter(valid_603204, JString, required = false,
                                 default = nil)
  if valid_603204 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_603204
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_603205 = query.getOrDefault("ApplicationName")
  valid_603205 = validateParameter(valid_603205, JString, required = true,
                                 default = nil)
  if valid_603205 != nil:
    section.add "ApplicationName", valid_603205
  var valid_603206 = query.getOrDefault("Description")
  valid_603206 = validateParameter(valid_603206, JString, required = false,
                                 default = nil)
  if valid_603206 != nil:
    section.add "Description", valid_603206
  var valid_603207 = query.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_603207 = validateParameter(valid_603207, JString, required = false,
                                 default = nil)
  if valid_603207 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_603207
  var valid_603208 = query.getOrDefault("Tags")
  valid_603208 = validateParameter(valid_603208, JArray, required = false,
                                 default = nil)
  if valid_603208 != nil:
    section.add "Tags", valid_603208
  var valid_603209 = query.getOrDefault("Action")
  valid_603209 = validateParameter(valid_603209, JString, required = true,
                                 default = newJString("CreateApplication"))
  if valid_603209 != nil:
    section.add "Action", valid_603209
  var valid_603210 = query.getOrDefault("Version")
  valid_603210 = validateParameter(valid_603210, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603210 != nil:
    section.add "Version", valid_603210
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
  var valid_603211 = header.getOrDefault("X-Amz-Date")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "X-Amz-Date", valid_603211
  var valid_603212 = header.getOrDefault("X-Amz-Security-Token")
  valid_603212 = validateParameter(valid_603212, JString, required = false,
                                 default = nil)
  if valid_603212 != nil:
    section.add "X-Amz-Security-Token", valid_603212
  var valid_603213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603213 = validateParameter(valid_603213, JString, required = false,
                                 default = nil)
  if valid_603213 != nil:
    section.add "X-Amz-Content-Sha256", valid_603213
  var valid_603214 = header.getOrDefault("X-Amz-Algorithm")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "X-Amz-Algorithm", valid_603214
  var valid_603215 = header.getOrDefault("X-Amz-Signature")
  valid_603215 = validateParameter(valid_603215, JString, required = false,
                                 default = nil)
  if valid_603215 != nil:
    section.add "X-Amz-Signature", valid_603215
  var valid_603216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "X-Amz-SignedHeaders", valid_603216
  var valid_603217 = header.getOrDefault("X-Amz-Credential")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "X-Amz-Credential", valid_603217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603218: Call_GetCreateApplication_603201; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates an application that has one configuration template named <code>default</code> and no application versions. 
  ## 
  let valid = call_603218.validator(path, query, header, formData, body)
  let scheme = call_603218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603218.url(scheme.get, call_603218.host, call_603218.base,
                         call_603218.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603218, url, valid)

proc call*(call_603219: Call_GetCreateApplication_603201; ApplicationName: string;
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
  var query_603220 = newJObject()
  add(query_603220, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  add(query_603220, "ApplicationName", newJString(ApplicationName))
  add(query_603220, "Description", newJString(Description))
  add(query_603220, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  if Tags != nil:
    query_603220.add "Tags", Tags
  add(query_603220, "Action", newJString(Action))
  add(query_603220, "Version", newJString(Version))
  result = call_603219.call(nil, query_603220, nil, nil, nil)

var getCreateApplication* = Call_GetCreateApplication_603201(
    name: "getCreateApplication", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateApplication",
    validator: validate_GetCreateApplication_603202, base: "/",
    url: url_GetCreateApplication_603203, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateApplicationVersion_603273 = ref object of OpenApiRestCall_602467
proc url_PostCreateApplicationVersion_603275(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateApplicationVersion_603274(path: JsonNode; query: JsonNode;
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
  var valid_603276 = query.getOrDefault("Action")
  valid_603276 = validateParameter(valid_603276, JString, required = true, default = newJString(
      "CreateApplicationVersion"))
  if valid_603276 != nil:
    section.add "Action", valid_603276
  var valid_603277 = query.getOrDefault("Version")
  valid_603277 = validateParameter(valid_603277, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603277 != nil:
    section.add "Version", valid_603277
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
  var valid_603278 = header.getOrDefault("X-Amz-Date")
  valid_603278 = validateParameter(valid_603278, JString, required = false,
                                 default = nil)
  if valid_603278 != nil:
    section.add "X-Amz-Date", valid_603278
  var valid_603279 = header.getOrDefault("X-Amz-Security-Token")
  valid_603279 = validateParameter(valid_603279, JString, required = false,
                                 default = nil)
  if valid_603279 != nil:
    section.add "X-Amz-Security-Token", valid_603279
  var valid_603280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603280 = validateParameter(valid_603280, JString, required = false,
                                 default = nil)
  if valid_603280 != nil:
    section.add "X-Amz-Content-Sha256", valid_603280
  var valid_603281 = header.getOrDefault("X-Amz-Algorithm")
  valid_603281 = validateParameter(valid_603281, JString, required = false,
                                 default = nil)
  if valid_603281 != nil:
    section.add "X-Amz-Algorithm", valid_603281
  var valid_603282 = header.getOrDefault("X-Amz-Signature")
  valid_603282 = validateParameter(valid_603282, JString, required = false,
                                 default = nil)
  if valid_603282 != nil:
    section.add "X-Amz-Signature", valid_603282
  var valid_603283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603283 = validateParameter(valid_603283, JString, required = false,
                                 default = nil)
  if valid_603283 != nil:
    section.add "X-Amz-SignedHeaders", valid_603283
  var valid_603284 = header.getOrDefault("X-Amz-Credential")
  valid_603284 = validateParameter(valid_603284, JString, required = false,
                                 default = nil)
  if valid_603284 != nil:
    section.add "X-Amz-Credential", valid_603284
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
  var valid_603285 = formData.getOrDefault("SourceBundle.S3Key")
  valid_603285 = validateParameter(valid_603285, JString, required = false,
                                 default = nil)
  if valid_603285 != nil:
    section.add "SourceBundle.S3Key", valid_603285
  assert formData != nil,
        "formData argument is necessary due to required `VersionLabel` field"
  var valid_603286 = formData.getOrDefault("VersionLabel")
  valid_603286 = validateParameter(valid_603286, JString, required = true,
                                 default = nil)
  if valid_603286 != nil:
    section.add "VersionLabel", valid_603286
  var valid_603287 = formData.getOrDefault("SourceBundle.S3Bucket")
  valid_603287 = validateParameter(valid_603287, JString, required = false,
                                 default = nil)
  if valid_603287 != nil:
    section.add "SourceBundle.S3Bucket", valid_603287
  var valid_603288 = formData.getOrDefault("BuildConfiguration.ComputeType")
  valid_603288 = validateParameter(valid_603288, JString, required = false,
                                 default = nil)
  if valid_603288 != nil:
    section.add "BuildConfiguration.ComputeType", valid_603288
  var valid_603289 = formData.getOrDefault("SourceBuildInformation.SourceType")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "SourceBuildInformation.SourceType", valid_603289
  var valid_603290 = formData.getOrDefault("Tags")
  valid_603290 = validateParameter(valid_603290, JArray, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "Tags", valid_603290
  var valid_603291 = formData.getOrDefault("AutoCreateApplication")
  valid_603291 = validateParameter(valid_603291, JBool, required = false, default = nil)
  if valid_603291 != nil:
    section.add "AutoCreateApplication", valid_603291
  var valid_603292 = formData.getOrDefault("SourceBuildInformation.SourceLocation")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "SourceBuildInformation.SourceLocation", valid_603292
  var valid_603293 = formData.getOrDefault("BuildConfiguration.CodeBuildServiceRole")
  valid_603293 = validateParameter(valid_603293, JString, required = false,
                                 default = nil)
  if valid_603293 != nil:
    section.add "BuildConfiguration.CodeBuildServiceRole", valid_603293
  var valid_603294 = formData.getOrDefault("ApplicationName")
  valid_603294 = validateParameter(valid_603294, JString, required = true,
                                 default = nil)
  if valid_603294 != nil:
    section.add "ApplicationName", valid_603294
  var valid_603295 = formData.getOrDefault("BuildConfiguration.ArtifactName")
  valid_603295 = validateParameter(valid_603295, JString, required = false,
                                 default = nil)
  if valid_603295 != nil:
    section.add "BuildConfiguration.ArtifactName", valid_603295
  var valid_603296 = formData.getOrDefault("BuildConfiguration.TimeoutInMinutes")
  valid_603296 = validateParameter(valid_603296, JString, required = false,
                                 default = nil)
  if valid_603296 != nil:
    section.add "BuildConfiguration.TimeoutInMinutes", valid_603296
  var valid_603297 = formData.getOrDefault("SourceBuildInformation.SourceRepository")
  valid_603297 = validateParameter(valid_603297, JString, required = false,
                                 default = nil)
  if valid_603297 != nil:
    section.add "SourceBuildInformation.SourceRepository", valid_603297
  var valid_603298 = formData.getOrDefault("Description")
  valid_603298 = validateParameter(valid_603298, JString, required = false,
                                 default = nil)
  if valid_603298 != nil:
    section.add "Description", valid_603298
  var valid_603299 = formData.getOrDefault("BuildConfiguration.Image")
  valid_603299 = validateParameter(valid_603299, JString, required = false,
                                 default = nil)
  if valid_603299 != nil:
    section.add "BuildConfiguration.Image", valid_603299
  var valid_603300 = formData.getOrDefault("Process")
  valid_603300 = validateParameter(valid_603300, JBool, required = false, default = nil)
  if valid_603300 != nil:
    section.add "Process", valid_603300
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603301: Call_PostCreateApplicationVersion_603273; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an application version for the specified application. You can create an application version from a source bundle in Amazon S3, a commit in AWS CodeCommit, or the output of an AWS CodeBuild build as follows:</p> <p>Specify a commit in an AWS CodeCommit repository with <code>SourceBuildInformation</code>.</p> <p>Specify a build in an AWS CodeBuild with <code>SourceBuildInformation</code> and <code>BuildConfiguration</code>.</p> <p>Specify a source bundle in S3 with <code>SourceBundle</code> </p> <p>Omit both <code>SourceBuildInformation</code> and <code>SourceBundle</code> to use the default sample application.</p> <note> <p>Once you create an application version with a specified Amazon S3 bucket and key location, you cannot change that Amazon S3 location. If you change the Amazon S3 location, you receive an exception when you attempt to launch an environment from the application version.</p> </note>
  ## 
  let valid = call_603301.validator(path, query, header, formData, body)
  let scheme = call_603301.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603301.url(scheme.get, call_603301.host, call_603301.base,
                         call_603301.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603301, url, valid)

proc call*(call_603302: Call_PostCreateApplicationVersion_603273;
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
  var query_603303 = newJObject()
  var formData_603304 = newJObject()
  add(formData_603304, "SourceBundle.S3Key", newJString(SourceBundleS3Key))
  add(formData_603304, "VersionLabel", newJString(VersionLabel))
  add(formData_603304, "SourceBundle.S3Bucket", newJString(SourceBundleS3Bucket))
  add(formData_603304, "BuildConfiguration.ComputeType",
      newJString(BuildConfigurationComputeType))
  add(formData_603304, "SourceBuildInformation.SourceType",
      newJString(SourceBuildInformationSourceType))
  if Tags != nil:
    formData_603304.add "Tags", Tags
  add(formData_603304, "AutoCreateApplication", newJBool(AutoCreateApplication))
  add(formData_603304, "SourceBuildInformation.SourceLocation",
      newJString(SourceBuildInformationSourceLocation))
  add(query_603303, "Action", newJString(Action))
  add(formData_603304, "BuildConfiguration.CodeBuildServiceRole",
      newJString(BuildConfigurationCodeBuildServiceRole))
  add(formData_603304, "ApplicationName", newJString(ApplicationName))
  add(formData_603304, "BuildConfiguration.ArtifactName",
      newJString(BuildConfigurationArtifactName))
  add(formData_603304, "BuildConfiguration.TimeoutInMinutes",
      newJString(BuildConfigurationTimeoutInMinutes))
  add(formData_603304, "SourceBuildInformation.SourceRepository",
      newJString(SourceBuildInformationSourceRepository))
  add(formData_603304, "Description", newJString(Description))
  add(formData_603304, "BuildConfiguration.Image",
      newJString(BuildConfigurationImage))
  add(formData_603304, "Process", newJBool(Process))
  add(query_603303, "Version", newJString(Version))
  result = call_603302.call(nil, query_603303, nil, formData_603304, nil)

var postCreateApplicationVersion* = Call_PostCreateApplicationVersion_603273(
    name: "postCreateApplicationVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateApplicationVersion",
    validator: validate_PostCreateApplicationVersion_603274, base: "/",
    url: url_PostCreateApplicationVersion_603275,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateApplicationVersion_603242 = ref object of OpenApiRestCall_602467
proc url_GetCreateApplicationVersion_603244(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateApplicationVersion_603243(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_603245 = query.getOrDefault("BuildConfiguration.TimeoutInMinutes")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "BuildConfiguration.TimeoutInMinutes", valid_603245
  var valid_603246 = query.getOrDefault("SourceBundle.S3Bucket")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "SourceBundle.S3Bucket", valid_603246
  var valid_603247 = query.getOrDefault("BuildConfiguration.ComputeType")
  valid_603247 = validateParameter(valid_603247, JString, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "BuildConfiguration.ComputeType", valid_603247
  assert query != nil,
        "query argument is necessary due to required `VersionLabel` field"
  var valid_603248 = query.getOrDefault("VersionLabel")
  valid_603248 = validateParameter(valid_603248, JString, required = true,
                                 default = nil)
  if valid_603248 != nil:
    section.add "VersionLabel", valid_603248
  var valid_603249 = query.getOrDefault("BuildConfiguration.ArtifactName")
  valid_603249 = validateParameter(valid_603249, JString, required = false,
                                 default = nil)
  if valid_603249 != nil:
    section.add "BuildConfiguration.ArtifactName", valid_603249
  var valid_603250 = query.getOrDefault("ApplicationName")
  valid_603250 = validateParameter(valid_603250, JString, required = true,
                                 default = nil)
  if valid_603250 != nil:
    section.add "ApplicationName", valid_603250
  var valid_603251 = query.getOrDefault("Description")
  valid_603251 = validateParameter(valid_603251, JString, required = false,
                                 default = nil)
  if valid_603251 != nil:
    section.add "Description", valid_603251
  var valid_603252 = query.getOrDefault("BuildConfiguration.Image")
  valid_603252 = validateParameter(valid_603252, JString, required = false,
                                 default = nil)
  if valid_603252 != nil:
    section.add "BuildConfiguration.Image", valid_603252
  var valid_603253 = query.getOrDefault("SourceBuildInformation.SourceLocation")
  valid_603253 = validateParameter(valid_603253, JString, required = false,
                                 default = nil)
  if valid_603253 != nil:
    section.add "SourceBuildInformation.SourceLocation", valid_603253
  var valid_603254 = query.getOrDefault("SourceBundle.S3Key")
  valid_603254 = validateParameter(valid_603254, JString, required = false,
                                 default = nil)
  if valid_603254 != nil:
    section.add "SourceBundle.S3Key", valid_603254
  var valid_603255 = query.getOrDefault("Tags")
  valid_603255 = validateParameter(valid_603255, JArray, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "Tags", valid_603255
  var valid_603256 = query.getOrDefault("AutoCreateApplication")
  valid_603256 = validateParameter(valid_603256, JBool, required = false, default = nil)
  if valid_603256 != nil:
    section.add "AutoCreateApplication", valid_603256
  var valid_603257 = query.getOrDefault("Action")
  valid_603257 = validateParameter(valid_603257, JString, required = true, default = newJString(
      "CreateApplicationVersion"))
  if valid_603257 != nil:
    section.add "Action", valid_603257
  var valid_603258 = query.getOrDefault("SourceBuildInformation.SourceType")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "SourceBuildInformation.SourceType", valid_603258
  var valid_603259 = query.getOrDefault("BuildConfiguration.CodeBuildServiceRole")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "BuildConfiguration.CodeBuildServiceRole", valid_603259
  var valid_603260 = query.getOrDefault("Process")
  valid_603260 = validateParameter(valid_603260, JBool, required = false, default = nil)
  if valid_603260 != nil:
    section.add "Process", valid_603260
  var valid_603261 = query.getOrDefault("SourceBuildInformation.SourceRepository")
  valid_603261 = validateParameter(valid_603261, JString, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "SourceBuildInformation.SourceRepository", valid_603261
  var valid_603262 = query.getOrDefault("Version")
  valid_603262 = validateParameter(valid_603262, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603262 != nil:
    section.add "Version", valid_603262
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
  var valid_603263 = header.getOrDefault("X-Amz-Date")
  valid_603263 = validateParameter(valid_603263, JString, required = false,
                                 default = nil)
  if valid_603263 != nil:
    section.add "X-Amz-Date", valid_603263
  var valid_603264 = header.getOrDefault("X-Amz-Security-Token")
  valid_603264 = validateParameter(valid_603264, JString, required = false,
                                 default = nil)
  if valid_603264 != nil:
    section.add "X-Amz-Security-Token", valid_603264
  var valid_603265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603265 = validateParameter(valid_603265, JString, required = false,
                                 default = nil)
  if valid_603265 != nil:
    section.add "X-Amz-Content-Sha256", valid_603265
  var valid_603266 = header.getOrDefault("X-Amz-Algorithm")
  valid_603266 = validateParameter(valid_603266, JString, required = false,
                                 default = nil)
  if valid_603266 != nil:
    section.add "X-Amz-Algorithm", valid_603266
  var valid_603267 = header.getOrDefault("X-Amz-Signature")
  valid_603267 = validateParameter(valid_603267, JString, required = false,
                                 default = nil)
  if valid_603267 != nil:
    section.add "X-Amz-Signature", valid_603267
  var valid_603268 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603268 = validateParameter(valid_603268, JString, required = false,
                                 default = nil)
  if valid_603268 != nil:
    section.add "X-Amz-SignedHeaders", valid_603268
  var valid_603269 = header.getOrDefault("X-Amz-Credential")
  valid_603269 = validateParameter(valid_603269, JString, required = false,
                                 default = nil)
  if valid_603269 != nil:
    section.add "X-Amz-Credential", valid_603269
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603270: Call_GetCreateApplicationVersion_603242; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an application version for the specified application. You can create an application version from a source bundle in Amazon S3, a commit in AWS CodeCommit, or the output of an AWS CodeBuild build as follows:</p> <p>Specify a commit in an AWS CodeCommit repository with <code>SourceBuildInformation</code>.</p> <p>Specify a build in an AWS CodeBuild with <code>SourceBuildInformation</code> and <code>BuildConfiguration</code>.</p> <p>Specify a source bundle in S3 with <code>SourceBundle</code> </p> <p>Omit both <code>SourceBuildInformation</code> and <code>SourceBundle</code> to use the default sample application.</p> <note> <p>Once you create an application version with a specified Amazon S3 bucket and key location, you cannot change that Amazon S3 location. If you change the Amazon S3 location, you receive an exception when you attempt to launch an environment from the application version.</p> </note>
  ## 
  let valid = call_603270.validator(path, query, header, formData, body)
  let scheme = call_603270.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603270.url(scheme.get, call_603270.host, call_603270.base,
                         call_603270.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603270, url, valid)

proc call*(call_603271: Call_GetCreateApplicationVersion_603242;
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
  var query_603272 = newJObject()
  add(query_603272, "BuildConfiguration.TimeoutInMinutes",
      newJString(BuildConfigurationTimeoutInMinutes))
  add(query_603272, "SourceBundle.S3Bucket", newJString(SourceBundleS3Bucket))
  add(query_603272, "BuildConfiguration.ComputeType",
      newJString(BuildConfigurationComputeType))
  add(query_603272, "VersionLabel", newJString(VersionLabel))
  add(query_603272, "BuildConfiguration.ArtifactName",
      newJString(BuildConfigurationArtifactName))
  add(query_603272, "ApplicationName", newJString(ApplicationName))
  add(query_603272, "Description", newJString(Description))
  add(query_603272, "BuildConfiguration.Image",
      newJString(BuildConfigurationImage))
  add(query_603272, "SourceBuildInformation.SourceLocation",
      newJString(SourceBuildInformationSourceLocation))
  add(query_603272, "SourceBundle.S3Key", newJString(SourceBundleS3Key))
  if Tags != nil:
    query_603272.add "Tags", Tags
  add(query_603272, "AutoCreateApplication", newJBool(AutoCreateApplication))
  add(query_603272, "Action", newJString(Action))
  add(query_603272, "SourceBuildInformation.SourceType",
      newJString(SourceBuildInformationSourceType))
  add(query_603272, "BuildConfiguration.CodeBuildServiceRole",
      newJString(BuildConfigurationCodeBuildServiceRole))
  add(query_603272, "Process", newJBool(Process))
  add(query_603272, "SourceBuildInformation.SourceRepository",
      newJString(SourceBuildInformationSourceRepository))
  add(query_603272, "Version", newJString(Version))
  result = call_603271.call(nil, query_603272, nil, nil, nil)

var getCreateApplicationVersion* = Call_GetCreateApplicationVersion_603242(
    name: "getCreateApplicationVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateApplicationVersion",
    validator: validate_GetCreateApplicationVersion_603243, base: "/",
    url: url_GetCreateApplicationVersion_603244,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateConfigurationTemplate_603330 = ref object of OpenApiRestCall_602467
proc url_PostCreateConfigurationTemplate_603332(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateConfigurationTemplate_603331(path: JsonNode;
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
  var valid_603333 = query.getOrDefault("Action")
  valid_603333 = validateParameter(valid_603333, JString, required = true, default = newJString(
      "CreateConfigurationTemplate"))
  if valid_603333 != nil:
    section.add "Action", valid_603333
  var valid_603334 = query.getOrDefault("Version")
  valid_603334 = validateParameter(valid_603334, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603334 != nil:
    section.add "Version", valid_603334
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
  var valid_603335 = header.getOrDefault("X-Amz-Date")
  valid_603335 = validateParameter(valid_603335, JString, required = false,
                                 default = nil)
  if valid_603335 != nil:
    section.add "X-Amz-Date", valid_603335
  var valid_603336 = header.getOrDefault("X-Amz-Security-Token")
  valid_603336 = validateParameter(valid_603336, JString, required = false,
                                 default = nil)
  if valid_603336 != nil:
    section.add "X-Amz-Security-Token", valid_603336
  var valid_603337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603337 = validateParameter(valid_603337, JString, required = false,
                                 default = nil)
  if valid_603337 != nil:
    section.add "X-Amz-Content-Sha256", valid_603337
  var valid_603338 = header.getOrDefault("X-Amz-Algorithm")
  valid_603338 = validateParameter(valid_603338, JString, required = false,
                                 default = nil)
  if valid_603338 != nil:
    section.add "X-Amz-Algorithm", valid_603338
  var valid_603339 = header.getOrDefault("X-Amz-Signature")
  valid_603339 = validateParameter(valid_603339, JString, required = false,
                                 default = nil)
  if valid_603339 != nil:
    section.add "X-Amz-Signature", valid_603339
  var valid_603340 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603340 = validateParameter(valid_603340, JString, required = false,
                                 default = nil)
  if valid_603340 != nil:
    section.add "X-Amz-SignedHeaders", valid_603340
  var valid_603341 = header.getOrDefault("X-Amz-Credential")
  valid_603341 = validateParameter(valid_603341, JString, required = false,
                                 default = nil)
  if valid_603341 != nil:
    section.add "X-Amz-Credential", valid_603341
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
  var valid_603342 = formData.getOrDefault("OptionSettings")
  valid_603342 = validateParameter(valid_603342, JArray, required = false,
                                 default = nil)
  if valid_603342 != nil:
    section.add "OptionSettings", valid_603342
  var valid_603343 = formData.getOrDefault("Tags")
  valid_603343 = validateParameter(valid_603343, JArray, required = false,
                                 default = nil)
  if valid_603343 != nil:
    section.add "Tags", valid_603343
  var valid_603344 = formData.getOrDefault("SolutionStackName")
  valid_603344 = validateParameter(valid_603344, JString, required = false,
                                 default = nil)
  if valid_603344 != nil:
    section.add "SolutionStackName", valid_603344
  var valid_603345 = formData.getOrDefault("SourceConfiguration.ApplicationName")
  valid_603345 = validateParameter(valid_603345, JString, required = false,
                                 default = nil)
  if valid_603345 != nil:
    section.add "SourceConfiguration.ApplicationName", valid_603345
  var valid_603346 = formData.getOrDefault("EnvironmentId")
  valid_603346 = validateParameter(valid_603346, JString, required = false,
                                 default = nil)
  if valid_603346 != nil:
    section.add "EnvironmentId", valid_603346
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_603347 = formData.getOrDefault("ApplicationName")
  valid_603347 = validateParameter(valid_603347, JString, required = true,
                                 default = nil)
  if valid_603347 != nil:
    section.add "ApplicationName", valid_603347
  var valid_603348 = formData.getOrDefault("PlatformArn")
  valid_603348 = validateParameter(valid_603348, JString, required = false,
                                 default = nil)
  if valid_603348 != nil:
    section.add "PlatformArn", valid_603348
  var valid_603349 = formData.getOrDefault("TemplateName")
  valid_603349 = validateParameter(valid_603349, JString, required = true,
                                 default = nil)
  if valid_603349 != nil:
    section.add "TemplateName", valid_603349
  var valid_603350 = formData.getOrDefault("Description")
  valid_603350 = validateParameter(valid_603350, JString, required = false,
                                 default = nil)
  if valid_603350 != nil:
    section.add "Description", valid_603350
  var valid_603351 = formData.getOrDefault("SourceConfiguration.TemplateName")
  valid_603351 = validateParameter(valid_603351, JString, required = false,
                                 default = nil)
  if valid_603351 != nil:
    section.add "SourceConfiguration.TemplateName", valid_603351
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603352: Call_PostCreateConfigurationTemplate_603330;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a configuration template. Templates are associated with a specific application and are used to deploy different versions of the application with the same configuration settings.</p> <p>Templates aren't associated with any environment. The <code>EnvironmentName</code> response element is always <code>null</code>.</p> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> <li> <p> <a>DescribeConfigurationSettings</a> </p> </li> <li> <p> <a>ListAvailableSolutionStacks</a> </p> </li> </ul>
  ## 
  let valid = call_603352.validator(path, query, header, formData, body)
  let scheme = call_603352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603352.url(scheme.get, call_603352.host, call_603352.base,
                         call_603352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603352, url, valid)

proc call*(call_603353: Call_PostCreateConfigurationTemplate_603330;
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
  var query_603354 = newJObject()
  var formData_603355 = newJObject()
  if OptionSettings != nil:
    formData_603355.add "OptionSettings", OptionSettings
  if Tags != nil:
    formData_603355.add "Tags", Tags
  add(formData_603355, "SolutionStackName", newJString(SolutionStackName))
  add(formData_603355, "SourceConfiguration.ApplicationName",
      newJString(SourceConfigurationApplicationName))
  add(formData_603355, "EnvironmentId", newJString(EnvironmentId))
  add(query_603354, "Action", newJString(Action))
  add(formData_603355, "ApplicationName", newJString(ApplicationName))
  add(formData_603355, "PlatformArn", newJString(PlatformArn))
  add(formData_603355, "TemplateName", newJString(TemplateName))
  add(query_603354, "Version", newJString(Version))
  add(formData_603355, "Description", newJString(Description))
  add(formData_603355, "SourceConfiguration.TemplateName",
      newJString(SourceConfigurationTemplateName))
  result = call_603353.call(nil, query_603354, nil, formData_603355, nil)

var postCreateConfigurationTemplate* = Call_PostCreateConfigurationTemplate_603330(
    name: "postCreateConfigurationTemplate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateConfigurationTemplate",
    validator: validate_PostCreateConfigurationTemplate_603331, base: "/",
    url: url_PostCreateConfigurationTemplate_603332,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateConfigurationTemplate_603305 = ref object of OpenApiRestCall_602467
proc url_GetCreateConfigurationTemplate_603307(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateConfigurationTemplate_603306(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_603308 = query.getOrDefault("SourceConfiguration.ApplicationName")
  valid_603308 = validateParameter(valid_603308, JString, required = false,
                                 default = nil)
  if valid_603308 != nil:
    section.add "SourceConfiguration.ApplicationName", valid_603308
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_603309 = query.getOrDefault("ApplicationName")
  valid_603309 = validateParameter(valid_603309, JString, required = true,
                                 default = nil)
  if valid_603309 != nil:
    section.add "ApplicationName", valid_603309
  var valid_603310 = query.getOrDefault("Description")
  valid_603310 = validateParameter(valid_603310, JString, required = false,
                                 default = nil)
  if valid_603310 != nil:
    section.add "Description", valid_603310
  var valid_603311 = query.getOrDefault("PlatformArn")
  valid_603311 = validateParameter(valid_603311, JString, required = false,
                                 default = nil)
  if valid_603311 != nil:
    section.add "PlatformArn", valid_603311
  var valid_603312 = query.getOrDefault("Tags")
  valid_603312 = validateParameter(valid_603312, JArray, required = false,
                                 default = nil)
  if valid_603312 != nil:
    section.add "Tags", valid_603312
  var valid_603313 = query.getOrDefault("Action")
  valid_603313 = validateParameter(valid_603313, JString, required = true, default = newJString(
      "CreateConfigurationTemplate"))
  if valid_603313 != nil:
    section.add "Action", valid_603313
  var valid_603314 = query.getOrDefault("SolutionStackName")
  valid_603314 = validateParameter(valid_603314, JString, required = false,
                                 default = nil)
  if valid_603314 != nil:
    section.add "SolutionStackName", valid_603314
  var valid_603315 = query.getOrDefault("EnvironmentId")
  valid_603315 = validateParameter(valid_603315, JString, required = false,
                                 default = nil)
  if valid_603315 != nil:
    section.add "EnvironmentId", valid_603315
  var valid_603316 = query.getOrDefault("TemplateName")
  valid_603316 = validateParameter(valid_603316, JString, required = true,
                                 default = nil)
  if valid_603316 != nil:
    section.add "TemplateName", valid_603316
  var valid_603317 = query.getOrDefault("OptionSettings")
  valid_603317 = validateParameter(valid_603317, JArray, required = false,
                                 default = nil)
  if valid_603317 != nil:
    section.add "OptionSettings", valid_603317
  var valid_603318 = query.getOrDefault("Version")
  valid_603318 = validateParameter(valid_603318, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603318 != nil:
    section.add "Version", valid_603318
  var valid_603319 = query.getOrDefault("SourceConfiguration.TemplateName")
  valid_603319 = validateParameter(valid_603319, JString, required = false,
                                 default = nil)
  if valid_603319 != nil:
    section.add "SourceConfiguration.TemplateName", valid_603319
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
  var valid_603320 = header.getOrDefault("X-Amz-Date")
  valid_603320 = validateParameter(valid_603320, JString, required = false,
                                 default = nil)
  if valid_603320 != nil:
    section.add "X-Amz-Date", valid_603320
  var valid_603321 = header.getOrDefault("X-Amz-Security-Token")
  valid_603321 = validateParameter(valid_603321, JString, required = false,
                                 default = nil)
  if valid_603321 != nil:
    section.add "X-Amz-Security-Token", valid_603321
  var valid_603322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603322 = validateParameter(valid_603322, JString, required = false,
                                 default = nil)
  if valid_603322 != nil:
    section.add "X-Amz-Content-Sha256", valid_603322
  var valid_603323 = header.getOrDefault("X-Amz-Algorithm")
  valid_603323 = validateParameter(valid_603323, JString, required = false,
                                 default = nil)
  if valid_603323 != nil:
    section.add "X-Amz-Algorithm", valid_603323
  var valid_603324 = header.getOrDefault("X-Amz-Signature")
  valid_603324 = validateParameter(valid_603324, JString, required = false,
                                 default = nil)
  if valid_603324 != nil:
    section.add "X-Amz-Signature", valid_603324
  var valid_603325 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603325 = validateParameter(valid_603325, JString, required = false,
                                 default = nil)
  if valid_603325 != nil:
    section.add "X-Amz-SignedHeaders", valid_603325
  var valid_603326 = header.getOrDefault("X-Amz-Credential")
  valid_603326 = validateParameter(valid_603326, JString, required = false,
                                 default = nil)
  if valid_603326 != nil:
    section.add "X-Amz-Credential", valid_603326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603327: Call_GetCreateConfigurationTemplate_603305; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a configuration template. Templates are associated with a specific application and are used to deploy different versions of the application with the same configuration settings.</p> <p>Templates aren't associated with any environment. The <code>EnvironmentName</code> response element is always <code>null</code>.</p> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> <li> <p> <a>DescribeConfigurationSettings</a> </p> </li> <li> <p> <a>ListAvailableSolutionStacks</a> </p> </li> </ul>
  ## 
  let valid = call_603327.validator(path, query, header, formData, body)
  let scheme = call_603327.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603327.url(scheme.get, call_603327.host, call_603327.base,
                         call_603327.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603327, url, valid)

proc call*(call_603328: Call_GetCreateConfigurationTemplate_603305;
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
  var query_603329 = newJObject()
  add(query_603329, "SourceConfiguration.ApplicationName",
      newJString(SourceConfigurationApplicationName))
  add(query_603329, "ApplicationName", newJString(ApplicationName))
  add(query_603329, "Description", newJString(Description))
  add(query_603329, "PlatformArn", newJString(PlatformArn))
  if Tags != nil:
    query_603329.add "Tags", Tags
  add(query_603329, "Action", newJString(Action))
  add(query_603329, "SolutionStackName", newJString(SolutionStackName))
  add(query_603329, "EnvironmentId", newJString(EnvironmentId))
  add(query_603329, "TemplateName", newJString(TemplateName))
  if OptionSettings != nil:
    query_603329.add "OptionSettings", OptionSettings
  add(query_603329, "Version", newJString(Version))
  add(query_603329, "SourceConfiguration.TemplateName",
      newJString(SourceConfigurationTemplateName))
  result = call_603328.call(nil, query_603329, nil, nil, nil)

var getCreateConfigurationTemplate* = Call_GetCreateConfigurationTemplate_603305(
    name: "getCreateConfigurationTemplate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateConfigurationTemplate",
    validator: validate_GetCreateConfigurationTemplate_603306, base: "/",
    url: url_GetCreateConfigurationTemplate_603307,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEnvironment_603386 = ref object of OpenApiRestCall_602467
proc url_PostCreateEnvironment_603388(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateEnvironment_603387(path: JsonNode; query: JsonNode;
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
  var valid_603389 = query.getOrDefault("Action")
  valid_603389 = validateParameter(valid_603389, JString, required = true,
                                 default = newJString("CreateEnvironment"))
  if valid_603389 != nil:
    section.add "Action", valid_603389
  var valid_603390 = query.getOrDefault("Version")
  valid_603390 = validateParameter(valid_603390, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603390 != nil:
    section.add "Version", valid_603390
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
  var valid_603391 = header.getOrDefault("X-Amz-Date")
  valid_603391 = validateParameter(valid_603391, JString, required = false,
                                 default = nil)
  if valid_603391 != nil:
    section.add "X-Amz-Date", valid_603391
  var valid_603392 = header.getOrDefault("X-Amz-Security-Token")
  valid_603392 = validateParameter(valid_603392, JString, required = false,
                                 default = nil)
  if valid_603392 != nil:
    section.add "X-Amz-Security-Token", valid_603392
  var valid_603393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603393 = validateParameter(valid_603393, JString, required = false,
                                 default = nil)
  if valid_603393 != nil:
    section.add "X-Amz-Content-Sha256", valid_603393
  var valid_603394 = header.getOrDefault("X-Amz-Algorithm")
  valid_603394 = validateParameter(valid_603394, JString, required = false,
                                 default = nil)
  if valid_603394 != nil:
    section.add "X-Amz-Algorithm", valid_603394
  var valid_603395 = header.getOrDefault("X-Amz-Signature")
  valid_603395 = validateParameter(valid_603395, JString, required = false,
                                 default = nil)
  if valid_603395 != nil:
    section.add "X-Amz-Signature", valid_603395
  var valid_603396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603396 = validateParameter(valid_603396, JString, required = false,
                                 default = nil)
  if valid_603396 != nil:
    section.add "X-Amz-SignedHeaders", valid_603396
  var valid_603397 = header.getOrDefault("X-Amz-Credential")
  valid_603397 = validateParameter(valid_603397, JString, required = false,
                                 default = nil)
  if valid_603397 != nil:
    section.add "X-Amz-Credential", valid_603397
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
  var valid_603398 = formData.getOrDefault("Tier.Name")
  valid_603398 = validateParameter(valid_603398, JString, required = false,
                                 default = nil)
  if valid_603398 != nil:
    section.add "Tier.Name", valid_603398
  var valid_603399 = formData.getOrDefault("OptionsToRemove")
  valid_603399 = validateParameter(valid_603399, JArray, required = false,
                                 default = nil)
  if valid_603399 != nil:
    section.add "OptionsToRemove", valid_603399
  var valid_603400 = formData.getOrDefault("VersionLabel")
  valid_603400 = validateParameter(valid_603400, JString, required = false,
                                 default = nil)
  if valid_603400 != nil:
    section.add "VersionLabel", valid_603400
  var valid_603401 = formData.getOrDefault("OptionSettings")
  valid_603401 = validateParameter(valid_603401, JArray, required = false,
                                 default = nil)
  if valid_603401 != nil:
    section.add "OptionSettings", valid_603401
  var valid_603402 = formData.getOrDefault("GroupName")
  valid_603402 = validateParameter(valid_603402, JString, required = false,
                                 default = nil)
  if valid_603402 != nil:
    section.add "GroupName", valid_603402
  var valid_603403 = formData.getOrDefault("Tags")
  valid_603403 = validateParameter(valid_603403, JArray, required = false,
                                 default = nil)
  if valid_603403 != nil:
    section.add "Tags", valid_603403
  var valid_603404 = formData.getOrDefault("CNAMEPrefix")
  valid_603404 = validateParameter(valid_603404, JString, required = false,
                                 default = nil)
  if valid_603404 != nil:
    section.add "CNAMEPrefix", valid_603404
  var valid_603405 = formData.getOrDefault("SolutionStackName")
  valid_603405 = validateParameter(valid_603405, JString, required = false,
                                 default = nil)
  if valid_603405 != nil:
    section.add "SolutionStackName", valid_603405
  var valid_603406 = formData.getOrDefault("EnvironmentName")
  valid_603406 = validateParameter(valid_603406, JString, required = false,
                                 default = nil)
  if valid_603406 != nil:
    section.add "EnvironmentName", valid_603406
  var valid_603407 = formData.getOrDefault("Tier.Type")
  valid_603407 = validateParameter(valid_603407, JString, required = false,
                                 default = nil)
  if valid_603407 != nil:
    section.add "Tier.Type", valid_603407
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_603408 = formData.getOrDefault("ApplicationName")
  valid_603408 = validateParameter(valid_603408, JString, required = true,
                                 default = nil)
  if valid_603408 != nil:
    section.add "ApplicationName", valid_603408
  var valid_603409 = formData.getOrDefault("PlatformArn")
  valid_603409 = validateParameter(valid_603409, JString, required = false,
                                 default = nil)
  if valid_603409 != nil:
    section.add "PlatformArn", valid_603409
  var valid_603410 = formData.getOrDefault("TemplateName")
  valid_603410 = validateParameter(valid_603410, JString, required = false,
                                 default = nil)
  if valid_603410 != nil:
    section.add "TemplateName", valid_603410
  var valid_603411 = formData.getOrDefault("Description")
  valid_603411 = validateParameter(valid_603411, JString, required = false,
                                 default = nil)
  if valid_603411 != nil:
    section.add "Description", valid_603411
  var valid_603412 = formData.getOrDefault("Tier.Version")
  valid_603412 = validateParameter(valid_603412, JString, required = false,
                                 default = nil)
  if valid_603412 != nil:
    section.add "Tier.Version", valid_603412
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603413: Call_PostCreateEnvironment_603386; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Launches an environment for the specified application using the specified configuration.
  ## 
  let valid = call_603413.validator(path, query, header, formData, body)
  let scheme = call_603413.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603413.url(scheme.get, call_603413.host, call_603413.base,
                         call_603413.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603413, url, valid)

proc call*(call_603414: Call_PostCreateEnvironment_603386; ApplicationName: string;
          TierName: string = ""; OptionsToRemove: JsonNode = nil;
          VersionLabel: string = ""; OptionSettings: JsonNode = nil;
          GroupName: string = ""; Tags: JsonNode = nil; CNAMEPrefix: string = "";
          SolutionStackName: string = ""; EnvironmentName: string = "";
          TierType: string = ""; Action: string = "CreateEnvironment";
          PlatformArn: string = ""; TemplateName: string = "";
          Version: string = "2010-12-01"; Description: string = "";
          TierVersion: string = ""): Recallable =
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
  var query_603415 = newJObject()
  var formData_603416 = newJObject()
  add(formData_603416, "Tier.Name", newJString(TierName))
  if OptionsToRemove != nil:
    formData_603416.add "OptionsToRemove", OptionsToRemove
  add(formData_603416, "VersionLabel", newJString(VersionLabel))
  if OptionSettings != nil:
    formData_603416.add "OptionSettings", OptionSettings
  add(formData_603416, "GroupName", newJString(GroupName))
  if Tags != nil:
    formData_603416.add "Tags", Tags
  add(formData_603416, "CNAMEPrefix", newJString(CNAMEPrefix))
  add(formData_603416, "SolutionStackName", newJString(SolutionStackName))
  add(formData_603416, "EnvironmentName", newJString(EnvironmentName))
  add(formData_603416, "Tier.Type", newJString(TierType))
  add(query_603415, "Action", newJString(Action))
  add(formData_603416, "ApplicationName", newJString(ApplicationName))
  add(formData_603416, "PlatformArn", newJString(PlatformArn))
  add(formData_603416, "TemplateName", newJString(TemplateName))
  add(query_603415, "Version", newJString(Version))
  add(formData_603416, "Description", newJString(Description))
  add(formData_603416, "Tier.Version", newJString(TierVersion))
  result = call_603414.call(nil, query_603415, nil, formData_603416, nil)

var postCreateEnvironment* = Call_PostCreateEnvironment_603386(
    name: "postCreateEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateEnvironment",
    validator: validate_PostCreateEnvironment_603387, base: "/",
    url: url_PostCreateEnvironment_603388, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEnvironment_603356 = ref object of OpenApiRestCall_602467
proc url_GetCreateEnvironment_603358(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateEnvironment_603357(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_603359 = query.getOrDefault("Tier.Name")
  valid_603359 = validateParameter(valid_603359, JString, required = false,
                                 default = nil)
  if valid_603359 != nil:
    section.add "Tier.Name", valid_603359
  var valid_603360 = query.getOrDefault("VersionLabel")
  valid_603360 = validateParameter(valid_603360, JString, required = false,
                                 default = nil)
  if valid_603360 != nil:
    section.add "VersionLabel", valid_603360
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_603361 = query.getOrDefault("ApplicationName")
  valid_603361 = validateParameter(valid_603361, JString, required = true,
                                 default = nil)
  if valid_603361 != nil:
    section.add "ApplicationName", valid_603361
  var valid_603362 = query.getOrDefault("Description")
  valid_603362 = validateParameter(valid_603362, JString, required = false,
                                 default = nil)
  if valid_603362 != nil:
    section.add "Description", valid_603362
  var valid_603363 = query.getOrDefault("OptionsToRemove")
  valid_603363 = validateParameter(valid_603363, JArray, required = false,
                                 default = nil)
  if valid_603363 != nil:
    section.add "OptionsToRemove", valid_603363
  var valid_603364 = query.getOrDefault("PlatformArn")
  valid_603364 = validateParameter(valid_603364, JString, required = false,
                                 default = nil)
  if valid_603364 != nil:
    section.add "PlatformArn", valid_603364
  var valid_603365 = query.getOrDefault("Tags")
  valid_603365 = validateParameter(valid_603365, JArray, required = false,
                                 default = nil)
  if valid_603365 != nil:
    section.add "Tags", valid_603365
  var valid_603366 = query.getOrDefault("EnvironmentName")
  valid_603366 = validateParameter(valid_603366, JString, required = false,
                                 default = nil)
  if valid_603366 != nil:
    section.add "EnvironmentName", valid_603366
  var valid_603367 = query.getOrDefault("Action")
  valid_603367 = validateParameter(valid_603367, JString, required = true,
                                 default = newJString("CreateEnvironment"))
  if valid_603367 != nil:
    section.add "Action", valid_603367
  var valid_603368 = query.getOrDefault("SolutionStackName")
  valid_603368 = validateParameter(valid_603368, JString, required = false,
                                 default = nil)
  if valid_603368 != nil:
    section.add "SolutionStackName", valid_603368
  var valid_603369 = query.getOrDefault("Tier.Version")
  valid_603369 = validateParameter(valid_603369, JString, required = false,
                                 default = nil)
  if valid_603369 != nil:
    section.add "Tier.Version", valid_603369
  var valid_603370 = query.getOrDefault("TemplateName")
  valid_603370 = validateParameter(valid_603370, JString, required = false,
                                 default = nil)
  if valid_603370 != nil:
    section.add "TemplateName", valid_603370
  var valid_603371 = query.getOrDefault("GroupName")
  valid_603371 = validateParameter(valid_603371, JString, required = false,
                                 default = nil)
  if valid_603371 != nil:
    section.add "GroupName", valid_603371
  var valid_603372 = query.getOrDefault("OptionSettings")
  valid_603372 = validateParameter(valid_603372, JArray, required = false,
                                 default = nil)
  if valid_603372 != nil:
    section.add "OptionSettings", valid_603372
  var valid_603373 = query.getOrDefault("Tier.Type")
  valid_603373 = validateParameter(valid_603373, JString, required = false,
                                 default = nil)
  if valid_603373 != nil:
    section.add "Tier.Type", valid_603373
  var valid_603374 = query.getOrDefault("Version")
  valid_603374 = validateParameter(valid_603374, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603374 != nil:
    section.add "Version", valid_603374
  var valid_603375 = query.getOrDefault("CNAMEPrefix")
  valid_603375 = validateParameter(valid_603375, JString, required = false,
                                 default = nil)
  if valid_603375 != nil:
    section.add "CNAMEPrefix", valid_603375
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
  var valid_603376 = header.getOrDefault("X-Amz-Date")
  valid_603376 = validateParameter(valid_603376, JString, required = false,
                                 default = nil)
  if valid_603376 != nil:
    section.add "X-Amz-Date", valid_603376
  var valid_603377 = header.getOrDefault("X-Amz-Security-Token")
  valid_603377 = validateParameter(valid_603377, JString, required = false,
                                 default = nil)
  if valid_603377 != nil:
    section.add "X-Amz-Security-Token", valid_603377
  var valid_603378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603378 = validateParameter(valid_603378, JString, required = false,
                                 default = nil)
  if valid_603378 != nil:
    section.add "X-Amz-Content-Sha256", valid_603378
  var valid_603379 = header.getOrDefault("X-Amz-Algorithm")
  valid_603379 = validateParameter(valid_603379, JString, required = false,
                                 default = nil)
  if valid_603379 != nil:
    section.add "X-Amz-Algorithm", valid_603379
  var valid_603380 = header.getOrDefault("X-Amz-Signature")
  valid_603380 = validateParameter(valid_603380, JString, required = false,
                                 default = nil)
  if valid_603380 != nil:
    section.add "X-Amz-Signature", valid_603380
  var valid_603381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603381 = validateParameter(valid_603381, JString, required = false,
                                 default = nil)
  if valid_603381 != nil:
    section.add "X-Amz-SignedHeaders", valid_603381
  var valid_603382 = header.getOrDefault("X-Amz-Credential")
  valid_603382 = validateParameter(valid_603382, JString, required = false,
                                 default = nil)
  if valid_603382 != nil:
    section.add "X-Amz-Credential", valid_603382
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603383: Call_GetCreateEnvironment_603356; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Launches an environment for the specified application using the specified configuration.
  ## 
  let valid = call_603383.validator(path, query, header, formData, body)
  let scheme = call_603383.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603383.url(scheme.get, call_603383.host, call_603383.base,
                         call_603383.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603383, url, valid)

proc call*(call_603384: Call_GetCreateEnvironment_603356; ApplicationName: string;
          TierName: string = ""; VersionLabel: string = ""; Description: string = "";
          OptionsToRemove: JsonNode = nil; PlatformArn: string = "";
          Tags: JsonNode = nil; EnvironmentName: string = "";
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
  var query_603385 = newJObject()
  add(query_603385, "Tier.Name", newJString(TierName))
  add(query_603385, "VersionLabel", newJString(VersionLabel))
  add(query_603385, "ApplicationName", newJString(ApplicationName))
  add(query_603385, "Description", newJString(Description))
  if OptionsToRemove != nil:
    query_603385.add "OptionsToRemove", OptionsToRemove
  add(query_603385, "PlatformArn", newJString(PlatformArn))
  if Tags != nil:
    query_603385.add "Tags", Tags
  add(query_603385, "EnvironmentName", newJString(EnvironmentName))
  add(query_603385, "Action", newJString(Action))
  add(query_603385, "SolutionStackName", newJString(SolutionStackName))
  add(query_603385, "Tier.Version", newJString(TierVersion))
  add(query_603385, "TemplateName", newJString(TemplateName))
  add(query_603385, "GroupName", newJString(GroupName))
  if OptionSettings != nil:
    query_603385.add "OptionSettings", OptionSettings
  add(query_603385, "Tier.Type", newJString(TierType))
  add(query_603385, "Version", newJString(Version))
  add(query_603385, "CNAMEPrefix", newJString(CNAMEPrefix))
  result = call_603384.call(nil, query_603385, nil, nil, nil)

var getCreateEnvironment* = Call_GetCreateEnvironment_603356(
    name: "getCreateEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateEnvironment",
    validator: validate_GetCreateEnvironment_603357, base: "/",
    url: url_GetCreateEnvironment_603358, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreatePlatformVersion_603439 = ref object of OpenApiRestCall_602467
proc url_PostCreatePlatformVersion_603441(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreatePlatformVersion_603440(path: JsonNode; query: JsonNode;
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
  var valid_603442 = query.getOrDefault("Action")
  valid_603442 = validateParameter(valid_603442, JString, required = true,
                                 default = newJString("CreatePlatformVersion"))
  if valid_603442 != nil:
    section.add "Action", valid_603442
  var valid_603443 = query.getOrDefault("Version")
  valid_603443 = validateParameter(valid_603443, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603443 != nil:
    section.add "Version", valid_603443
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
  var valid_603444 = header.getOrDefault("X-Amz-Date")
  valid_603444 = validateParameter(valid_603444, JString, required = false,
                                 default = nil)
  if valid_603444 != nil:
    section.add "X-Amz-Date", valid_603444
  var valid_603445 = header.getOrDefault("X-Amz-Security-Token")
  valid_603445 = validateParameter(valid_603445, JString, required = false,
                                 default = nil)
  if valid_603445 != nil:
    section.add "X-Amz-Security-Token", valid_603445
  var valid_603446 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603446 = validateParameter(valid_603446, JString, required = false,
                                 default = nil)
  if valid_603446 != nil:
    section.add "X-Amz-Content-Sha256", valid_603446
  var valid_603447 = header.getOrDefault("X-Amz-Algorithm")
  valid_603447 = validateParameter(valid_603447, JString, required = false,
                                 default = nil)
  if valid_603447 != nil:
    section.add "X-Amz-Algorithm", valid_603447
  var valid_603448 = header.getOrDefault("X-Amz-Signature")
  valid_603448 = validateParameter(valid_603448, JString, required = false,
                                 default = nil)
  if valid_603448 != nil:
    section.add "X-Amz-Signature", valid_603448
  var valid_603449 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603449 = validateParameter(valid_603449, JString, required = false,
                                 default = nil)
  if valid_603449 != nil:
    section.add "X-Amz-SignedHeaders", valid_603449
  var valid_603450 = header.getOrDefault("X-Amz-Credential")
  valid_603450 = validateParameter(valid_603450, JString, required = false,
                                 default = nil)
  if valid_603450 != nil:
    section.add "X-Amz-Credential", valid_603450
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
  var valid_603451 = formData.getOrDefault("PlatformName")
  valid_603451 = validateParameter(valid_603451, JString, required = true,
                                 default = nil)
  if valid_603451 != nil:
    section.add "PlatformName", valid_603451
  var valid_603452 = formData.getOrDefault("PlatformDefinitionBundle.S3Key")
  valid_603452 = validateParameter(valid_603452, JString, required = false,
                                 default = nil)
  if valid_603452 != nil:
    section.add "PlatformDefinitionBundle.S3Key", valid_603452
  var valid_603453 = formData.getOrDefault("OptionSettings")
  valid_603453 = validateParameter(valid_603453, JArray, required = false,
                                 default = nil)
  if valid_603453 != nil:
    section.add "OptionSettings", valid_603453
  var valid_603454 = formData.getOrDefault("Tags")
  valid_603454 = validateParameter(valid_603454, JArray, required = false,
                                 default = nil)
  if valid_603454 != nil:
    section.add "Tags", valid_603454
  var valid_603455 = formData.getOrDefault("EnvironmentName")
  valid_603455 = validateParameter(valid_603455, JString, required = false,
                                 default = nil)
  if valid_603455 != nil:
    section.add "EnvironmentName", valid_603455
  var valid_603456 = formData.getOrDefault("PlatformDefinitionBundle.S3Bucket")
  valid_603456 = validateParameter(valid_603456, JString, required = false,
                                 default = nil)
  if valid_603456 != nil:
    section.add "PlatformDefinitionBundle.S3Bucket", valid_603456
  var valid_603457 = formData.getOrDefault("PlatformVersion")
  valid_603457 = validateParameter(valid_603457, JString, required = true,
                                 default = nil)
  if valid_603457 != nil:
    section.add "PlatformVersion", valid_603457
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603458: Call_PostCreatePlatformVersion_603439; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new version of your custom platform.
  ## 
  let valid = call_603458.validator(path, query, header, formData, body)
  let scheme = call_603458.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603458.url(scheme.get, call_603458.host, call_603458.base,
                         call_603458.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603458, url, valid)

proc call*(call_603459: Call_PostCreatePlatformVersion_603439;
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
  var query_603460 = newJObject()
  var formData_603461 = newJObject()
  add(formData_603461, "PlatformName", newJString(PlatformName))
  add(formData_603461, "PlatformDefinitionBundle.S3Key",
      newJString(PlatformDefinitionBundleS3Key))
  if OptionSettings != nil:
    formData_603461.add "OptionSettings", OptionSettings
  if Tags != nil:
    formData_603461.add "Tags", Tags
  add(formData_603461, "EnvironmentName", newJString(EnvironmentName))
  add(formData_603461, "PlatformDefinitionBundle.S3Bucket",
      newJString(PlatformDefinitionBundleS3Bucket))
  add(query_603460, "Action", newJString(Action))
  add(formData_603461, "PlatformVersion", newJString(PlatformVersion))
  add(query_603460, "Version", newJString(Version))
  result = call_603459.call(nil, query_603460, nil, formData_603461, nil)

var postCreatePlatformVersion* = Call_PostCreatePlatformVersion_603439(
    name: "postCreatePlatformVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreatePlatformVersion",
    validator: validate_PostCreatePlatformVersion_603440, base: "/",
    url: url_PostCreatePlatformVersion_603441,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreatePlatformVersion_603417 = ref object of OpenApiRestCall_602467
proc url_GetCreatePlatformVersion_603419(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreatePlatformVersion_603418(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_603420 = query.getOrDefault("Tags")
  valid_603420 = validateParameter(valid_603420, JArray, required = false,
                                 default = nil)
  if valid_603420 != nil:
    section.add "Tags", valid_603420
  var valid_603421 = query.getOrDefault("EnvironmentName")
  valid_603421 = validateParameter(valid_603421, JString, required = false,
                                 default = nil)
  if valid_603421 != nil:
    section.add "EnvironmentName", valid_603421
  var valid_603422 = query.getOrDefault("PlatformDefinitionBundle.S3Key")
  valid_603422 = validateParameter(valid_603422, JString, required = false,
                                 default = nil)
  if valid_603422 != nil:
    section.add "PlatformDefinitionBundle.S3Key", valid_603422
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603423 = query.getOrDefault("Action")
  valid_603423 = validateParameter(valid_603423, JString, required = true,
                                 default = newJString("CreatePlatformVersion"))
  if valid_603423 != nil:
    section.add "Action", valid_603423
  var valid_603424 = query.getOrDefault("OptionSettings")
  valid_603424 = validateParameter(valid_603424, JArray, required = false,
                                 default = nil)
  if valid_603424 != nil:
    section.add "OptionSettings", valid_603424
  var valid_603425 = query.getOrDefault("PlatformName")
  valid_603425 = validateParameter(valid_603425, JString, required = true,
                                 default = nil)
  if valid_603425 != nil:
    section.add "PlatformName", valid_603425
  var valid_603426 = query.getOrDefault("Version")
  valid_603426 = validateParameter(valid_603426, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603426 != nil:
    section.add "Version", valid_603426
  var valid_603427 = query.getOrDefault("PlatformDefinitionBundle.S3Bucket")
  valid_603427 = validateParameter(valid_603427, JString, required = false,
                                 default = nil)
  if valid_603427 != nil:
    section.add "PlatformDefinitionBundle.S3Bucket", valid_603427
  var valid_603428 = query.getOrDefault("PlatformVersion")
  valid_603428 = validateParameter(valid_603428, JString, required = true,
                                 default = nil)
  if valid_603428 != nil:
    section.add "PlatformVersion", valid_603428
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
  var valid_603429 = header.getOrDefault("X-Amz-Date")
  valid_603429 = validateParameter(valid_603429, JString, required = false,
                                 default = nil)
  if valid_603429 != nil:
    section.add "X-Amz-Date", valid_603429
  var valid_603430 = header.getOrDefault("X-Amz-Security-Token")
  valid_603430 = validateParameter(valid_603430, JString, required = false,
                                 default = nil)
  if valid_603430 != nil:
    section.add "X-Amz-Security-Token", valid_603430
  var valid_603431 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603431 = validateParameter(valid_603431, JString, required = false,
                                 default = nil)
  if valid_603431 != nil:
    section.add "X-Amz-Content-Sha256", valid_603431
  var valid_603432 = header.getOrDefault("X-Amz-Algorithm")
  valid_603432 = validateParameter(valid_603432, JString, required = false,
                                 default = nil)
  if valid_603432 != nil:
    section.add "X-Amz-Algorithm", valid_603432
  var valid_603433 = header.getOrDefault("X-Amz-Signature")
  valid_603433 = validateParameter(valid_603433, JString, required = false,
                                 default = nil)
  if valid_603433 != nil:
    section.add "X-Amz-Signature", valid_603433
  var valid_603434 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603434 = validateParameter(valid_603434, JString, required = false,
                                 default = nil)
  if valid_603434 != nil:
    section.add "X-Amz-SignedHeaders", valid_603434
  var valid_603435 = header.getOrDefault("X-Amz-Credential")
  valid_603435 = validateParameter(valid_603435, JString, required = false,
                                 default = nil)
  if valid_603435 != nil:
    section.add "X-Amz-Credential", valid_603435
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603436: Call_GetCreatePlatformVersion_603417; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new version of your custom platform.
  ## 
  let valid = call_603436.validator(path, query, header, formData, body)
  let scheme = call_603436.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603436.url(scheme.get, call_603436.host, call_603436.base,
                         call_603436.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603436, url, valid)

proc call*(call_603437: Call_GetCreatePlatformVersion_603417; PlatformName: string;
          PlatformVersion: string; Tags: JsonNode = nil; EnvironmentName: string = "";
          PlatformDefinitionBundleS3Key: string = "";
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
  var query_603438 = newJObject()
  if Tags != nil:
    query_603438.add "Tags", Tags
  add(query_603438, "EnvironmentName", newJString(EnvironmentName))
  add(query_603438, "PlatformDefinitionBundle.S3Key",
      newJString(PlatformDefinitionBundleS3Key))
  add(query_603438, "Action", newJString(Action))
  if OptionSettings != nil:
    query_603438.add "OptionSettings", OptionSettings
  add(query_603438, "PlatformName", newJString(PlatformName))
  add(query_603438, "Version", newJString(Version))
  add(query_603438, "PlatformDefinitionBundle.S3Bucket",
      newJString(PlatformDefinitionBundleS3Bucket))
  add(query_603438, "PlatformVersion", newJString(PlatformVersion))
  result = call_603437.call(nil, query_603438, nil, nil, nil)

var getCreatePlatformVersion* = Call_GetCreatePlatformVersion_603417(
    name: "getCreatePlatformVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreatePlatformVersion",
    validator: validate_GetCreatePlatformVersion_603418, base: "/",
    url: url_GetCreatePlatformVersion_603419, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateStorageLocation_603477 = ref object of OpenApiRestCall_602467
proc url_PostCreateStorageLocation_603479(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateStorageLocation_603478(path: JsonNode; query: JsonNode;
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
  var valid_603480 = query.getOrDefault("Action")
  valid_603480 = validateParameter(valid_603480, JString, required = true,
                                 default = newJString("CreateStorageLocation"))
  if valid_603480 != nil:
    section.add "Action", valid_603480
  var valid_603481 = query.getOrDefault("Version")
  valid_603481 = validateParameter(valid_603481, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603481 != nil:
    section.add "Version", valid_603481
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
  var valid_603482 = header.getOrDefault("X-Amz-Date")
  valid_603482 = validateParameter(valid_603482, JString, required = false,
                                 default = nil)
  if valid_603482 != nil:
    section.add "X-Amz-Date", valid_603482
  var valid_603483 = header.getOrDefault("X-Amz-Security-Token")
  valid_603483 = validateParameter(valid_603483, JString, required = false,
                                 default = nil)
  if valid_603483 != nil:
    section.add "X-Amz-Security-Token", valid_603483
  var valid_603484 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603484 = validateParameter(valid_603484, JString, required = false,
                                 default = nil)
  if valid_603484 != nil:
    section.add "X-Amz-Content-Sha256", valid_603484
  var valid_603485 = header.getOrDefault("X-Amz-Algorithm")
  valid_603485 = validateParameter(valid_603485, JString, required = false,
                                 default = nil)
  if valid_603485 != nil:
    section.add "X-Amz-Algorithm", valid_603485
  var valid_603486 = header.getOrDefault("X-Amz-Signature")
  valid_603486 = validateParameter(valid_603486, JString, required = false,
                                 default = nil)
  if valid_603486 != nil:
    section.add "X-Amz-Signature", valid_603486
  var valid_603487 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603487 = validateParameter(valid_603487, JString, required = false,
                                 default = nil)
  if valid_603487 != nil:
    section.add "X-Amz-SignedHeaders", valid_603487
  var valid_603488 = header.getOrDefault("X-Amz-Credential")
  valid_603488 = validateParameter(valid_603488, JString, required = false,
                                 default = nil)
  if valid_603488 != nil:
    section.add "X-Amz-Credential", valid_603488
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603489: Call_PostCreateStorageLocation_603477; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ## 
  let valid = call_603489.validator(path, query, header, formData, body)
  let scheme = call_603489.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603489.url(scheme.get, call_603489.host, call_603489.base,
                         call_603489.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603489, url, valid)

proc call*(call_603490: Call_PostCreateStorageLocation_603477;
          Action: string = "CreateStorageLocation"; Version: string = "2010-12-01"): Recallable =
  ## postCreateStorageLocation
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603491 = newJObject()
  add(query_603491, "Action", newJString(Action))
  add(query_603491, "Version", newJString(Version))
  result = call_603490.call(nil, query_603491, nil, nil, nil)

var postCreateStorageLocation* = Call_PostCreateStorageLocation_603477(
    name: "postCreateStorageLocation", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateStorageLocation",
    validator: validate_PostCreateStorageLocation_603478, base: "/",
    url: url_PostCreateStorageLocation_603479,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateStorageLocation_603462 = ref object of OpenApiRestCall_602467
proc url_GetCreateStorageLocation_603464(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateStorageLocation_603463(path: JsonNode; query: JsonNode;
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
  var valid_603465 = query.getOrDefault("Action")
  valid_603465 = validateParameter(valid_603465, JString, required = true,
                                 default = newJString("CreateStorageLocation"))
  if valid_603465 != nil:
    section.add "Action", valid_603465
  var valid_603466 = query.getOrDefault("Version")
  valid_603466 = validateParameter(valid_603466, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603466 != nil:
    section.add "Version", valid_603466
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
  var valid_603467 = header.getOrDefault("X-Amz-Date")
  valid_603467 = validateParameter(valid_603467, JString, required = false,
                                 default = nil)
  if valid_603467 != nil:
    section.add "X-Amz-Date", valid_603467
  var valid_603468 = header.getOrDefault("X-Amz-Security-Token")
  valid_603468 = validateParameter(valid_603468, JString, required = false,
                                 default = nil)
  if valid_603468 != nil:
    section.add "X-Amz-Security-Token", valid_603468
  var valid_603469 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603469 = validateParameter(valid_603469, JString, required = false,
                                 default = nil)
  if valid_603469 != nil:
    section.add "X-Amz-Content-Sha256", valid_603469
  var valid_603470 = header.getOrDefault("X-Amz-Algorithm")
  valid_603470 = validateParameter(valid_603470, JString, required = false,
                                 default = nil)
  if valid_603470 != nil:
    section.add "X-Amz-Algorithm", valid_603470
  var valid_603471 = header.getOrDefault("X-Amz-Signature")
  valid_603471 = validateParameter(valid_603471, JString, required = false,
                                 default = nil)
  if valid_603471 != nil:
    section.add "X-Amz-Signature", valid_603471
  var valid_603472 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603472 = validateParameter(valid_603472, JString, required = false,
                                 default = nil)
  if valid_603472 != nil:
    section.add "X-Amz-SignedHeaders", valid_603472
  var valid_603473 = header.getOrDefault("X-Amz-Credential")
  valid_603473 = validateParameter(valid_603473, JString, required = false,
                                 default = nil)
  if valid_603473 != nil:
    section.add "X-Amz-Credential", valid_603473
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603474: Call_GetCreateStorageLocation_603462; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ## 
  let valid = call_603474.validator(path, query, header, formData, body)
  let scheme = call_603474.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603474.url(scheme.get, call_603474.host, call_603474.base,
                         call_603474.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603474, url, valid)

proc call*(call_603475: Call_GetCreateStorageLocation_603462;
          Action: string = "CreateStorageLocation"; Version: string = "2010-12-01"): Recallable =
  ## getCreateStorageLocation
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603476 = newJObject()
  add(query_603476, "Action", newJString(Action))
  add(query_603476, "Version", newJString(Version))
  result = call_603475.call(nil, query_603476, nil, nil, nil)

var getCreateStorageLocation* = Call_GetCreateStorageLocation_603462(
    name: "getCreateStorageLocation", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateStorageLocation",
    validator: validate_GetCreateStorageLocation_603463, base: "/",
    url: url_GetCreateStorageLocation_603464, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteApplication_603509 = ref object of OpenApiRestCall_602467
proc url_PostDeleteApplication_603511(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteApplication_603510(path: JsonNode; query: JsonNode;
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
  var valid_603512 = query.getOrDefault("Action")
  valid_603512 = validateParameter(valid_603512, JString, required = true,
                                 default = newJString("DeleteApplication"))
  if valid_603512 != nil:
    section.add "Action", valid_603512
  var valid_603513 = query.getOrDefault("Version")
  valid_603513 = validateParameter(valid_603513, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603513 != nil:
    section.add "Version", valid_603513
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
  var valid_603514 = header.getOrDefault("X-Amz-Date")
  valid_603514 = validateParameter(valid_603514, JString, required = false,
                                 default = nil)
  if valid_603514 != nil:
    section.add "X-Amz-Date", valid_603514
  var valid_603515 = header.getOrDefault("X-Amz-Security-Token")
  valid_603515 = validateParameter(valid_603515, JString, required = false,
                                 default = nil)
  if valid_603515 != nil:
    section.add "X-Amz-Security-Token", valid_603515
  var valid_603516 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603516 = validateParameter(valid_603516, JString, required = false,
                                 default = nil)
  if valid_603516 != nil:
    section.add "X-Amz-Content-Sha256", valid_603516
  var valid_603517 = header.getOrDefault("X-Amz-Algorithm")
  valid_603517 = validateParameter(valid_603517, JString, required = false,
                                 default = nil)
  if valid_603517 != nil:
    section.add "X-Amz-Algorithm", valid_603517
  var valid_603518 = header.getOrDefault("X-Amz-Signature")
  valid_603518 = validateParameter(valid_603518, JString, required = false,
                                 default = nil)
  if valid_603518 != nil:
    section.add "X-Amz-Signature", valid_603518
  var valid_603519 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603519 = validateParameter(valid_603519, JString, required = false,
                                 default = nil)
  if valid_603519 != nil:
    section.add "X-Amz-SignedHeaders", valid_603519
  var valid_603520 = header.getOrDefault("X-Amz-Credential")
  valid_603520 = validateParameter(valid_603520, JString, required = false,
                                 default = nil)
  if valid_603520 != nil:
    section.add "X-Amz-Credential", valid_603520
  result.add "header", section
  ## parameters in `formData` object:
  ##   TerminateEnvByForce: JBool
  ##                      : When set to true, running environments will be terminated before deleting the application.
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to delete.
  section = newJObject()
  var valid_603521 = formData.getOrDefault("TerminateEnvByForce")
  valid_603521 = validateParameter(valid_603521, JBool, required = false, default = nil)
  if valid_603521 != nil:
    section.add "TerminateEnvByForce", valid_603521
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_603522 = formData.getOrDefault("ApplicationName")
  valid_603522 = validateParameter(valid_603522, JString, required = true,
                                 default = nil)
  if valid_603522 != nil:
    section.add "ApplicationName", valid_603522
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603523: Call_PostDeleteApplication_603509; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified application along with all associated versions and configurations. The application versions will not be deleted from your Amazon S3 bucket.</p> <note> <p>You cannot delete an application that has a running environment.</p> </note>
  ## 
  let valid = call_603523.validator(path, query, header, formData, body)
  let scheme = call_603523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603523.url(scheme.get, call_603523.host, call_603523.base,
                         call_603523.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603523, url, valid)

proc call*(call_603524: Call_PostDeleteApplication_603509; ApplicationName: string;
          TerminateEnvByForce: bool = false; Action: string = "DeleteApplication";
          Version: string = "2010-12-01"): Recallable =
  ## postDeleteApplication
  ## <p>Deletes the specified application along with all associated versions and configurations. The application versions will not be deleted from your Amazon S3 bucket.</p> <note> <p>You cannot delete an application that has a running environment.</p> </note>
  ##   TerminateEnvByForce: bool
  ##                      : When set to true, running environments will be terminated before deleting the application.
  ##   Action: string (required)
  ##   ApplicationName: string (required)
  ##                  : The name of the application to delete.
  ##   Version: string (required)
  var query_603525 = newJObject()
  var formData_603526 = newJObject()
  add(formData_603526, "TerminateEnvByForce", newJBool(TerminateEnvByForce))
  add(query_603525, "Action", newJString(Action))
  add(formData_603526, "ApplicationName", newJString(ApplicationName))
  add(query_603525, "Version", newJString(Version))
  result = call_603524.call(nil, query_603525, nil, formData_603526, nil)

var postDeleteApplication* = Call_PostDeleteApplication_603509(
    name: "postDeleteApplication", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=DeleteApplication",
    validator: validate_PostDeleteApplication_603510, base: "/",
    url: url_PostDeleteApplication_603511, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteApplication_603492 = ref object of OpenApiRestCall_602467
proc url_GetDeleteApplication_603494(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteApplication_603493(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_603495 = query.getOrDefault("TerminateEnvByForce")
  valid_603495 = validateParameter(valid_603495, JBool, required = false, default = nil)
  if valid_603495 != nil:
    section.add "TerminateEnvByForce", valid_603495
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_603496 = query.getOrDefault("ApplicationName")
  valid_603496 = validateParameter(valid_603496, JString, required = true,
                                 default = nil)
  if valid_603496 != nil:
    section.add "ApplicationName", valid_603496
  var valid_603497 = query.getOrDefault("Action")
  valid_603497 = validateParameter(valid_603497, JString, required = true,
                                 default = newJString("DeleteApplication"))
  if valid_603497 != nil:
    section.add "Action", valid_603497
  var valid_603498 = query.getOrDefault("Version")
  valid_603498 = validateParameter(valid_603498, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603498 != nil:
    section.add "Version", valid_603498
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
  var valid_603499 = header.getOrDefault("X-Amz-Date")
  valid_603499 = validateParameter(valid_603499, JString, required = false,
                                 default = nil)
  if valid_603499 != nil:
    section.add "X-Amz-Date", valid_603499
  var valid_603500 = header.getOrDefault("X-Amz-Security-Token")
  valid_603500 = validateParameter(valid_603500, JString, required = false,
                                 default = nil)
  if valid_603500 != nil:
    section.add "X-Amz-Security-Token", valid_603500
  var valid_603501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603501 = validateParameter(valid_603501, JString, required = false,
                                 default = nil)
  if valid_603501 != nil:
    section.add "X-Amz-Content-Sha256", valid_603501
  var valid_603502 = header.getOrDefault("X-Amz-Algorithm")
  valid_603502 = validateParameter(valid_603502, JString, required = false,
                                 default = nil)
  if valid_603502 != nil:
    section.add "X-Amz-Algorithm", valid_603502
  var valid_603503 = header.getOrDefault("X-Amz-Signature")
  valid_603503 = validateParameter(valid_603503, JString, required = false,
                                 default = nil)
  if valid_603503 != nil:
    section.add "X-Amz-Signature", valid_603503
  var valid_603504 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603504 = validateParameter(valid_603504, JString, required = false,
                                 default = nil)
  if valid_603504 != nil:
    section.add "X-Amz-SignedHeaders", valid_603504
  var valid_603505 = header.getOrDefault("X-Amz-Credential")
  valid_603505 = validateParameter(valid_603505, JString, required = false,
                                 default = nil)
  if valid_603505 != nil:
    section.add "X-Amz-Credential", valid_603505
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603506: Call_GetDeleteApplication_603492; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified application along with all associated versions and configurations. The application versions will not be deleted from your Amazon S3 bucket.</p> <note> <p>You cannot delete an application that has a running environment.</p> </note>
  ## 
  let valid = call_603506.validator(path, query, header, formData, body)
  let scheme = call_603506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603506.url(scheme.get, call_603506.host, call_603506.base,
                         call_603506.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603506, url, valid)

proc call*(call_603507: Call_GetDeleteApplication_603492; ApplicationName: string;
          TerminateEnvByForce: bool = false; Action: string = "DeleteApplication";
          Version: string = "2010-12-01"): Recallable =
  ## getDeleteApplication
  ## <p>Deletes the specified application along with all associated versions and configurations. The application versions will not be deleted from your Amazon S3 bucket.</p> <note> <p>You cannot delete an application that has a running environment.</p> </note>
  ##   TerminateEnvByForce: bool
  ##                      : When set to true, running environments will be terminated before deleting the application.
  ##   ApplicationName: string (required)
  ##                  : The name of the application to delete.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603508 = newJObject()
  add(query_603508, "TerminateEnvByForce", newJBool(TerminateEnvByForce))
  add(query_603508, "ApplicationName", newJString(ApplicationName))
  add(query_603508, "Action", newJString(Action))
  add(query_603508, "Version", newJString(Version))
  result = call_603507.call(nil, query_603508, nil, nil, nil)

var getDeleteApplication* = Call_GetDeleteApplication_603492(
    name: "getDeleteApplication", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=DeleteApplication",
    validator: validate_GetDeleteApplication_603493, base: "/",
    url: url_GetDeleteApplication_603494, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteApplicationVersion_603545 = ref object of OpenApiRestCall_602467
proc url_PostDeleteApplicationVersion_603547(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteApplicationVersion_603546(path: JsonNode; query: JsonNode;
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
  var valid_603548 = query.getOrDefault("Action")
  valid_603548 = validateParameter(valid_603548, JString, required = true, default = newJString(
      "DeleteApplicationVersion"))
  if valid_603548 != nil:
    section.add "Action", valid_603548
  var valid_603549 = query.getOrDefault("Version")
  valid_603549 = validateParameter(valid_603549, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603549 != nil:
    section.add "Version", valid_603549
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
  var valid_603550 = header.getOrDefault("X-Amz-Date")
  valid_603550 = validateParameter(valid_603550, JString, required = false,
                                 default = nil)
  if valid_603550 != nil:
    section.add "X-Amz-Date", valid_603550
  var valid_603551 = header.getOrDefault("X-Amz-Security-Token")
  valid_603551 = validateParameter(valid_603551, JString, required = false,
                                 default = nil)
  if valid_603551 != nil:
    section.add "X-Amz-Security-Token", valid_603551
  var valid_603552 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603552 = validateParameter(valid_603552, JString, required = false,
                                 default = nil)
  if valid_603552 != nil:
    section.add "X-Amz-Content-Sha256", valid_603552
  var valid_603553 = header.getOrDefault("X-Amz-Algorithm")
  valid_603553 = validateParameter(valid_603553, JString, required = false,
                                 default = nil)
  if valid_603553 != nil:
    section.add "X-Amz-Algorithm", valid_603553
  var valid_603554 = header.getOrDefault("X-Amz-Signature")
  valid_603554 = validateParameter(valid_603554, JString, required = false,
                                 default = nil)
  if valid_603554 != nil:
    section.add "X-Amz-Signature", valid_603554
  var valid_603555 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603555 = validateParameter(valid_603555, JString, required = false,
                                 default = nil)
  if valid_603555 != nil:
    section.add "X-Amz-SignedHeaders", valid_603555
  var valid_603556 = header.getOrDefault("X-Amz-Credential")
  valid_603556 = validateParameter(valid_603556, JString, required = false,
                                 default = nil)
  if valid_603556 != nil:
    section.add "X-Amz-Credential", valid_603556
  result.add "header", section
  ## parameters in `formData` object:
  ##   DeleteSourceBundle: JBool
  ##                     : Set to <code>true</code> to delete the source bundle from your storage bucket. Otherwise, the application version is deleted only from Elastic Beanstalk and the source bundle remains in Amazon S3.
  ##   VersionLabel: JString (required)
  ##               : The label of the version to delete.
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to which the version belongs.
  section = newJObject()
  var valid_603557 = formData.getOrDefault("DeleteSourceBundle")
  valid_603557 = validateParameter(valid_603557, JBool, required = false, default = nil)
  if valid_603557 != nil:
    section.add "DeleteSourceBundle", valid_603557
  assert formData != nil,
        "formData argument is necessary due to required `VersionLabel` field"
  var valid_603558 = formData.getOrDefault("VersionLabel")
  valid_603558 = validateParameter(valid_603558, JString, required = true,
                                 default = nil)
  if valid_603558 != nil:
    section.add "VersionLabel", valid_603558
  var valid_603559 = formData.getOrDefault("ApplicationName")
  valid_603559 = validateParameter(valid_603559, JString, required = true,
                                 default = nil)
  if valid_603559 != nil:
    section.add "ApplicationName", valid_603559
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603560: Call_PostDeleteApplicationVersion_603545; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified version from the specified application.</p> <note> <p>You cannot delete an application version that is associated with a running environment.</p> </note>
  ## 
  let valid = call_603560.validator(path, query, header, formData, body)
  let scheme = call_603560.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603560.url(scheme.get, call_603560.host, call_603560.base,
                         call_603560.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603560, url, valid)

proc call*(call_603561: Call_PostDeleteApplicationVersion_603545;
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
  var query_603562 = newJObject()
  var formData_603563 = newJObject()
  add(formData_603563, "DeleteSourceBundle", newJBool(DeleteSourceBundle))
  add(formData_603563, "VersionLabel", newJString(VersionLabel))
  add(query_603562, "Action", newJString(Action))
  add(formData_603563, "ApplicationName", newJString(ApplicationName))
  add(query_603562, "Version", newJString(Version))
  result = call_603561.call(nil, query_603562, nil, formData_603563, nil)

var postDeleteApplicationVersion* = Call_PostDeleteApplicationVersion_603545(
    name: "postDeleteApplicationVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteApplicationVersion",
    validator: validate_PostDeleteApplicationVersion_603546, base: "/",
    url: url_PostDeleteApplicationVersion_603547,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteApplicationVersion_603527 = ref object of OpenApiRestCall_602467
proc url_GetDeleteApplicationVersion_603529(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteApplicationVersion_603528(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_603530 = query.getOrDefault("VersionLabel")
  valid_603530 = validateParameter(valid_603530, JString, required = true,
                                 default = nil)
  if valid_603530 != nil:
    section.add "VersionLabel", valid_603530
  var valid_603531 = query.getOrDefault("ApplicationName")
  valid_603531 = validateParameter(valid_603531, JString, required = true,
                                 default = nil)
  if valid_603531 != nil:
    section.add "ApplicationName", valid_603531
  var valid_603532 = query.getOrDefault("Action")
  valid_603532 = validateParameter(valid_603532, JString, required = true, default = newJString(
      "DeleteApplicationVersion"))
  if valid_603532 != nil:
    section.add "Action", valid_603532
  var valid_603533 = query.getOrDefault("DeleteSourceBundle")
  valid_603533 = validateParameter(valid_603533, JBool, required = false, default = nil)
  if valid_603533 != nil:
    section.add "DeleteSourceBundle", valid_603533
  var valid_603534 = query.getOrDefault("Version")
  valid_603534 = validateParameter(valid_603534, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603534 != nil:
    section.add "Version", valid_603534
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
  var valid_603535 = header.getOrDefault("X-Amz-Date")
  valid_603535 = validateParameter(valid_603535, JString, required = false,
                                 default = nil)
  if valid_603535 != nil:
    section.add "X-Amz-Date", valid_603535
  var valid_603536 = header.getOrDefault("X-Amz-Security-Token")
  valid_603536 = validateParameter(valid_603536, JString, required = false,
                                 default = nil)
  if valid_603536 != nil:
    section.add "X-Amz-Security-Token", valid_603536
  var valid_603537 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603537 = validateParameter(valid_603537, JString, required = false,
                                 default = nil)
  if valid_603537 != nil:
    section.add "X-Amz-Content-Sha256", valid_603537
  var valid_603538 = header.getOrDefault("X-Amz-Algorithm")
  valid_603538 = validateParameter(valid_603538, JString, required = false,
                                 default = nil)
  if valid_603538 != nil:
    section.add "X-Amz-Algorithm", valid_603538
  var valid_603539 = header.getOrDefault("X-Amz-Signature")
  valid_603539 = validateParameter(valid_603539, JString, required = false,
                                 default = nil)
  if valid_603539 != nil:
    section.add "X-Amz-Signature", valid_603539
  var valid_603540 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603540 = validateParameter(valid_603540, JString, required = false,
                                 default = nil)
  if valid_603540 != nil:
    section.add "X-Amz-SignedHeaders", valid_603540
  var valid_603541 = header.getOrDefault("X-Amz-Credential")
  valid_603541 = validateParameter(valid_603541, JString, required = false,
                                 default = nil)
  if valid_603541 != nil:
    section.add "X-Amz-Credential", valid_603541
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603542: Call_GetDeleteApplicationVersion_603527; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified version from the specified application.</p> <note> <p>You cannot delete an application version that is associated with a running environment.</p> </note>
  ## 
  let valid = call_603542.validator(path, query, header, formData, body)
  let scheme = call_603542.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603542.url(scheme.get, call_603542.host, call_603542.base,
                         call_603542.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603542, url, valid)

proc call*(call_603543: Call_GetDeleteApplicationVersion_603527;
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
  var query_603544 = newJObject()
  add(query_603544, "VersionLabel", newJString(VersionLabel))
  add(query_603544, "ApplicationName", newJString(ApplicationName))
  add(query_603544, "Action", newJString(Action))
  add(query_603544, "DeleteSourceBundle", newJBool(DeleteSourceBundle))
  add(query_603544, "Version", newJString(Version))
  result = call_603543.call(nil, query_603544, nil, nil, nil)

var getDeleteApplicationVersion* = Call_GetDeleteApplicationVersion_603527(
    name: "getDeleteApplicationVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteApplicationVersion",
    validator: validate_GetDeleteApplicationVersion_603528, base: "/",
    url: url_GetDeleteApplicationVersion_603529,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteConfigurationTemplate_603581 = ref object of OpenApiRestCall_602467
proc url_PostDeleteConfigurationTemplate_603583(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteConfigurationTemplate_603582(path: JsonNode;
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
  var valid_603584 = query.getOrDefault("Action")
  valid_603584 = validateParameter(valid_603584, JString, required = true, default = newJString(
      "DeleteConfigurationTemplate"))
  if valid_603584 != nil:
    section.add "Action", valid_603584
  var valid_603585 = query.getOrDefault("Version")
  valid_603585 = validateParameter(valid_603585, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603585 != nil:
    section.add "Version", valid_603585
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
  var valid_603586 = header.getOrDefault("X-Amz-Date")
  valid_603586 = validateParameter(valid_603586, JString, required = false,
                                 default = nil)
  if valid_603586 != nil:
    section.add "X-Amz-Date", valid_603586
  var valid_603587 = header.getOrDefault("X-Amz-Security-Token")
  valid_603587 = validateParameter(valid_603587, JString, required = false,
                                 default = nil)
  if valid_603587 != nil:
    section.add "X-Amz-Security-Token", valid_603587
  var valid_603588 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603588 = validateParameter(valid_603588, JString, required = false,
                                 default = nil)
  if valid_603588 != nil:
    section.add "X-Amz-Content-Sha256", valid_603588
  var valid_603589 = header.getOrDefault("X-Amz-Algorithm")
  valid_603589 = validateParameter(valid_603589, JString, required = false,
                                 default = nil)
  if valid_603589 != nil:
    section.add "X-Amz-Algorithm", valid_603589
  var valid_603590 = header.getOrDefault("X-Amz-Signature")
  valid_603590 = validateParameter(valid_603590, JString, required = false,
                                 default = nil)
  if valid_603590 != nil:
    section.add "X-Amz-Signature", valid_603590
  var valid_603591 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603591 = validateParameter(valid_603591, JString, required = false,
                                 default = nil)
  if valid_603591 != nil:
    section.add "X-Amz-SignedHeaders", valid_603591
  var valid_603592 = header.getOrDefault("X-Amz-Credential")
  valid_603592 = validateParameter(valid_603592, JString, required = false,
                                 default = nil)
  if valid_603592 != nil:
    section.add "X-Amz-Credential", valid_603592
  result.add "header", section
  ## parameters in `formData` object:
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to delete the configuration template from.
  ##   TemplateName: JString (required)
  ##               : The name of the configuration template to delete.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_603593 = formData.getOrDefault("ApplicationName")
  valid_603593 = validateParameter(valid_603593, JString, required = true,
                                 default = nil)
  if valid_603593 != nil:
    section.add "ApplicationName", valid_603593
  var valid_603594 = formData.getOrDefault("TemplateName")
  valid_603594 = validateParameter(valid_603594, JString, required = true,
                                 default = nil)
  if valid_603594 != nil:
    section.add "TemplateName", valid_603594
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603595: Call_PostDeleteConfigurationTemplate_603581;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes the specified configuration template.</p> <note> <p>When you launch an environment using a configuration template, the environment gets a copy of the template. You can delete or modify the environment's copy of the template without affecting the running environment.</p> </note>
  ## 
  let valid = call_603595.validator(path, query, header, formData, body)
  let scheme = call_603595.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603595.url(scheme.get, call_603595.host, call_603595.base,
                         call_603595.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603595, url, valid)

proc call*(call_603596: Call_PostDeleteConfigurationTemplate_603581;
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
  var query_603597 = newJObject()
  var formData_603598 = newJObject()
  add(query_603597, "Action", newJString(Action))
  add(formData_603598, "ApplicationName", newJString(ApplicationName))
  add(formData_603598, "TemplateName", newJString(TemplateName))
  add(query_603597, "Version", newJString(Version))
  result = call_603596.call(nil, query_603597, nil, formData_603598, nil)

var postDeleteConfigurationTemplate* = Call_PostDeleteConfigurationTemplate_603581(
    name: "postDeleteConfigurationTemplate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteConfigurationTemplate",
    validator: validate_PostDeleteConfigurationTemplate_603582, base: "/",
    url: url_PostDeleteConfigurationTemplate_603583,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteConfigurationTemplate_603564 = ref object of OpenApiRestCall_602467
proc url_GetDeleteConfigurationTemplate_603566(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteConfigurationTemplate_603565(path: JsonNode;
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
  ##   TemplateName: JString (required)
  ##               : The name of the configuration template to delete.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_603567 = query.getOrDefault("ApplicationName")
  valid_603567 = validateParameter(valid_603567, JString, required = true,
                                 default = nil)
  if valid_603567 != nil:
    section.add "ApplicationName", valid_603567
  var valid_603568 = query.getOrDefault("Action")
  valid_603568 = validateParameter(valid_603568, JString, required = true, default = newJString(
      "DeleteConfigurationTemplate"))
  if valid_603568 != nil:
    section.add "Action", valid_603568
  var valid_603569 = query.getOrDefault("TemplateName")
  valid_603569 = validateParameter(valid_603569, JString, required = true,
                                 default = nil)
  if valid_603569 != nil:
    section.add "TemplateName", valid_603569
  var valid_603570 = query.getOrDefault("Version")
  valid_603570 = validateParameter(valid_603570, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603570 != nil:
    section.add "Version", valid_603570
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
  var valid_603571 = header.getOrDefault("X-Amz-Date")
  valid_603571 = validateParameter(valid_603571, JString, required = false,
                                 default = nil)
  if valid_603571 != nil:
    section.add "X-Amz-Date", valid_603571
  var valid_603572 = header.getOrDefault("X-Amz-Security-Token")
  valid_603572 = validateParameter(valid_603572, JString, required = false,
                                 default = nil)
  if valid_603572 != nil:
    section.add "X-Amz-Security-Token", valid_603572
  var valid_603573 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603573 = validateParameter(valid_603573, JString, required = false,
                                 default = nil)
  if valid_603573 != nil:
    section.add "X-Amz-Content-Sha256", valid_603573
  var valid_603574 = header.getOrDefault("X-Amz-Algorithm")
  valid_603574 = validateParameter(valid_603574, JString, required = false,
                                 default = nil)
  if valid_603574 != nil:
    section.add "X-Amz-Algorithm", valid_603574
  var valid_603575 = header.getOrDefault("X-Amz-Signature")
  valid_603575 = validateParameter(valid_603575, JString, required = false,
                                 default = nil)
  if valid_603575 != nil:
    section.add "X-Amz-Signature", valid_603575
  var valid_603576 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603576 = validateParameter(valid_603576, JString, required = false,
                                 default = nil)
  if valid_603576 != nil:
    section.add "X-Amz-SignedHeaders", valid_603576
  var valid_603577 = header.getOrDefault("X-Amz-Credential")
  valid_603577 = validateParameter(valid_603577, JString, required = false,
                                 default = nil)
  if valid_603577 != nil:
    section.add "X-Amz-Credential", valid_603577
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603578: Call_GetDeleteConfigurationTemplate_603564; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified configuration template.</p> <note> <p>When you launch an environment using a configuration template, the environment gets a copy of the template. You can delete or modify the environment's copy of the template without affecting the running environment.</p> </note>
  ## 
  let valid = call_603578.validator(path, query, header, formData, body)
  let scheme = call_603578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603578.url(scheme.get, call_603578.host, call_603578.base,
                         call_603578.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603578, url, valid)

proc call*(call_603579: Call_GetDeleteConfigurationTemplate_603564;
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
  var query_603580 = newJObject()
  add(query_603580, "ApplicationName", newJString(ApplicationName))
  add(query_603580, "Action", newJString(Action))
  add(query_603580, "TemplateName", newJString(TemplateName))
  add(query_603580, "Version", newJString(Version))
  result = call_603579.call(nil, query_603580, nil, nil, nil)

var getDeleteConfigurationTemplate* = Call_GetDeleteConfigurationTemplate_603564(
    name: "getDeleteConfigurationTemplate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteConfigurationTemplate",
    validator: validate_GetDeleteConfigurationTemplate_603565, base: "/",
    url: url_GetDeleteConfigurationTemplate_603566,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEnvironmentConfiguration_603616 = ref object of OpenApiRestCall_602467
proc url_PostDeleteEnvironmentConfiguration_603618(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteEnvironmentConfiguration_603617(path: JsonNode;
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
  var valid_603619 = query.getOrDefault("Action")
  valid_603619 = validateParameter(valid_603619, JString, required = true, default = newJString(
      "DeleteEnvironmentConfiguration"))
  if valid_603619 != nil:
    section.add "Action", valid_603619
  var valid_603620 = query.getOrDefault("Version")
  valid_603620 = validateParameter(valid_603620, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603620 != nil:
    section.add "Version", valid_603620
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
  var valid_603621 = header.getOrDefault("X-Amz-Date")
  valid_603621 = validateParameter(valid_603621, JString, required = false,
                                 default = nil)
  if valid_603621 != nil:
    section.add "X-Amz-Date", valid_603621
  var valid_603622 = header.getOrDefault("X-Amz-Security-Token")
  valid_603622 = validateParameter(valid_603622, JString, required = false,
                                 default = nil)
  if valid_603622 != nil:
    section.add "X-Amz-Security-Token", valid_603622
  var valid_603623 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603623 = validateParameter(valid_603623, JString, required = false,
                                 default = nil)
  if valid_603623 != nil:
    section.add "X-Amz-Content-Sha256", valid_603623
  var valid_603624 = header.getOrDefault("X-Amz-Algorithm")
  valid_603624 = validateParameter(valid_603624, JString, required = false,
                                 default = nil)
  if valid_603624 != nil:
    section.add "X-Amz-Algorithm", valid_603624
  var valid_603625 = header.getOrDefault("X-Amz-Signature")
  valid_603625 = validateParameter(valid_603625, JString, required = false,
                                 default = nil)
  if valid_603625 != nil:
    section.add "X-Amz-Signature", valid_603625
  var valid_603626 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603626 = validateParameter(valid_603626, JString, required = false,
                                 default = nil)
  if valid_603626 != nil:
    section.add "X-Amz-SignedHeaders", valid_603626
  var valid_603627 = header.getOrDefault("X-Amz-Credential")
  valid_603627 = validateParameter(valid_603627, JString, required = false,
                                 default = nil)
  if valid_603627 != nil:
    section.add "X-Amz-Credential", valid_603627
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString (required)
  ##                  : The name of the environment to delete the draft configuration from.
  ##   ApplicationName: JString (required)
  ##                  : The name of the application the environment is associated with.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `EnvironmentName` field"
  var valid_603628 = formData.getOrDefault("EnvironmentName")
  valid_603628 = validateParameter(valid_603628, JString, required = true,
                                 default = nil)
  if valid_603628 != nil:
    section.add "EnvironmentName", valid_603628
  var valid_603629 = formData.getOrDefault("ApplicationName")
  valid_603629 = validateParameter(valid_603629, JString, required = true,
                                 default = nil)
  if valid_603629 != nil:
    section.add "ApplicationName", valid_603629
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603630: Call_PostDeleteEnvironmentConfiguration_603616;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes the draft configuration associated with the running environment.</p> <p>Updating a running environment with any configuration changes creates a draft configuration set. You can get the draft configuration using <a>DescribeConfigurationSettings</a> while the update is in progress or if the update fails. The <code>DeploymentStatus</code> for the draft configuration indicates whether the deployment is in process or has failed. The draft configuration remains in existence until it is deleted with this action.</p>
  ## 
  let valid = call_603630.validator(path, query, header, formData, body)
  let scheme = call_603630.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603630.url(scheme.get, call_603630.host, call_603630.base,
                         call_603630.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603630, url, valid)

proc call*(call_603631: Call_PostDeleteEnvironmentConfiguration_603616;
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
  var query_603632 = newJObject()
  var formData_603633 = newJObject()
  add(formData_603633, "EnvironmentName", newJString(EnvironmentName))
  add(query_603632, "Action", newJString(Action))
  add(formData_603633, "ApplicationName", newJString(ApplicationName))
  add(query_603632, "Version", newJString(Version))
  result = call_603631.call(nil, query_603632, nil, formData_603633, nil)

var postDeleteEnvironmentConfiguration* = Call_PostDeleteEnvironmentConfiguration_603616(
    name: "postDeleteEnvironmentConfiguration", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteEnvironmentConfiguration",
    validator: validate_PostDeleteEnvironmentConfiguration_603617, base: "/",
    url: url_PostDeleteEnvironmentConfiguration_603618,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEnvironmentConfiguration_603599 = ref object of OpenApiRestCall_602467
proc url_GetDeleteEnvironmentConfiguration_603601(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteEnvironmentConfiguration_603600(path: JsonNode;
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
  var valid_603602 = query.getOrDefault("ApplicationName")
  valid_603602 = validateParameter(valid_603602, JString, required = true,
                                 default = nil)
  if valid_603602 != nil:
    section.add "ApplicationName", valid_603602
  var valid_603603 = query.getOrDefault("EnvironmentName")
  valid_603603 = validateParameter(valid_603603, JString, required = true,
                                 default = nil)
  if valid_603603 != nil:
    section.add "EnvironmentName", valid_603603
  var valid_603604 = query.getOrDefault("Action")
  valid_603604 = validateParameter(valid_603604, JString, required = true, default = newJString(
      "DeleteEnvironmentConfiguration"))
  if valid_603604 != nil:
    section.add "Action", valid_603604
  var valid_603605 = query.getOrDefault("Version")
  valid_603605 = validateParameter(valid_603605, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603605 != nil:
    section.add "Version", valid_603605
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
  var valid_603606 = header.getOrDefault("X-Amz-Date")
  valid_603606 = validateParameter(valid_603606, JString, required = false,
                                 default = nil)
  if valid_603606 != nil:
    section.add "X-Amz-Date", valid_603606
  var valid_603607 = header.getOrDefault("X-Amz-Security-Token")
  valid_603607 = validateParameter(valid_603607, JString, required = false,
                                 default = nil)
  if valid_603607 != nil:
    section.add "X-Amz-Security-Token", valid_603607
  var valid_603608 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603608 = validateParameter(valid_603608, JString, required = false,
                                 default = nil)
  if valid_603608 != nil:
    section.add "X-Amz-Content-Sha256", valid_603608
  var valid_603609 = header.getOrDefault("X-Amz-Algorithm")
  valid_603609 = validateParameter(valid_603609, JString, required = false,
                                 default = nil)
  if valid_603609 != nil:
    section.add "X-Amz-Algorithm", valid_603609
  var valid_603610 = header.getOrDefault("X-Amz-Signature")
  valid_603610 = validateParameter(valid_603610, JString, required = false,
                                 default = nil)
  if valid_603610 != nil:
    section.add "X-Amz-Signature", valid_603610
  var valid_603611 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603611 = validateParameter(valid_603611, JString, required = false,
                                 default = nil)
  if valid_603611 != nil:
    section.add "X-Amz-SignedHeaders", valid_603611
  var valid_603612 = header.getOrDefault("X-Amz-Credential")
  valid_603612 = validateParameter(valid_603612, JString, required = false,
                                 default = nil)
  if valid_603612 != nil:
    section.add "X-Amz-Credential", valid_603612
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603613: Call_GetDeleteEnvironmentConfiguration_603599;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes the draft configuration associated with the running environment.</p> <p>Updating a running environment with any configuration changes creates a draft configuration set. You can get the draft configuration using <a>DescribeConfigurationSettings</a> while the update is in progress or if the update fails. The <code>DeploymentStatus</code> for the draft configuration indicates whether the deployment is in process or has failed. The draft configuration remains in existence until it is deleted with this action.</p>
  ## 
  let valid = call_603613.validator(path, query, header, formData, body)
  let scheme = call_603613.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603613.url(scheme.get, call_603613.host, call_603613.base,
                         call_603613.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603613, url, valid)

proc call*(call_603614: Call_GetDeleteEnvironmentConfiguration_603599;
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
  var query_603615 = newJObject()
  add(query_603615, "ApplicationName", newJString(ApplicationName))
  add(query_603615, "EnvironmentName", newJString(EnvironmentName))
  add(query_603615, "Action", newJString(Action))
  add(query_603615, "Version", newJString(Version))
  result = call_603614.call(nil, query_603615, nil, nil, nil)

var getDeleteEnvironmentConfiguration* = Call_GetDeleteEnvironmentConfiguration_603599(
    name: "getDeleteEnvironmentConfiguration", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteEnvironmentConfiguration",
    validator: validate_GetDeleteEnvironmentConfiguration_603600, base: "/",
    url: url_GetDeleteEnvironmentConfiguration_603601,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeletePlatformVersion_603650 = ref object of OpenApiRestCall_602467
proc url_PostDeletePlatformVersion_603652(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeletePlatformVersion_603651(path: JsonNode; query: JsonNode;
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
  var valid_603653 = query.getOrDefault("Action")
  valid_603653 = validateParameter(valid_603653, JString, required = true,
                                 default = newJString("DeletePlatformVersion"))
  if valid_603653 != nil:
    section.add "Action", valid_603653
  var valid_603654 = query.getOrDefault("Version")
  valid_603654 = validateParameter(valid_603654, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603654 != nil:
    section.add "Version", valid_603654
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
  var valid_603655 = header.getOrDefault("X-Amz-Date")
  valid_603655 = validateParameter(valid_603655, JString, required = false,
                                 default = nil)
  if valid_603655 != nil:
    section.add "X-Amz-Date", valid_603655
  var valid_603656 = header.getOrDefault("X-Amz-Security-Token")
  valid_603656 = validateParameter(valid_603656, JString, required = false,
                                 default = nil)
  if valid_603656 != nil:
    section.add "X-Amz-Security-Token", valid_603656
  var valid_603657 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603657 = validateParameter(valid_603657, JString, required = false,
                                 default = nil)
  if valid_603657 != nil:
    section.add "X-Amz-Content-Sha256", valid_603657
  var valid_603658 = header.getOrDefault("X-Amz-Algorithm")
  valid_603658 = validateParameter(valid_603658, JString, required = false,
                                 default = nil)
  if valid_603658 != nil:
    section.add "X-Amz-Algorithm", valid_603658
  var valid_603659 = header.getOrDefault("X-Amz-Signature")
  valid_603659 = validateParameter(valid_603659, JString, required = false,
                                 default = nil)
  if valid_603659 != nil:
    section.add "X-Amz-Signature", valid_603659
  var valid_603660 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603660 = validateParameter(valid_603660, JString, required = false,
                                 default = nil)
  if valid_603660 != nil:
    section.add "X-Amz-SignedHeaders", valid_603660
  var valid_603661 = header.getOrDefault("X-Amz-Credential")
  valid_603661 = validateParameter(valid_603661, JString, required = false,
                                 default = nil)
  if valid_603661 != nil:
    section.add "X-Amz-Credential", valid_603661
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformArn: JString
  ##              : The ARN of the version of the custom platform.
  section = newJObject()
  var valid_603662 = formData.getOrDefault("PlatformArn")
  valid_603662 = validateParameter(valid_603662, JString, required = false,
                                 default = nil)
  if valid_603662 != nil:
    section.add "PlatformArn", valid_603662
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603663: Call_PostDeletePlatformVersion_603650; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified version of a custom platform.
  ## 
  let valid = call_603663.validator(path, query, header, formData, body)
  let scheme = call_603663.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603663.url(scheme.get, call_603663.host, call_603663.base,
                         call_603663.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603663, url, valid)

proc call*(call_603664: Call_PostDeletePlatformVersion_603650;
          Action: string = "DeletePlatformVersion"; PlatformArn: string = "";
          Version: string = "2010-12-01"): Recallable =
  ## postDeletePlatformVersion
  ## Deletes the specified version of a custom platform.
  ##   Action: string (required)
  ##   PlatformArn: string
  ##              : The ARN of the version of the custom platform.
  ##   Version: string (required)
  var query_603665 = newJObject()
  var formData_603666 = newJObject()
  add(query_603665, "Action", newJString(Action))
  add(formData_603666, "PlatformArn", newJString(PlatformArn))
  add(query_603665, "Version", newJString(Version))
  result = call_603664.call(nil, query_603665, nil, formData_603666, nil)

var postDeletePlatformVersion* = Call_PostDeletePlatformVersion_603650(
    name: "postDeletePlatformVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeletePlatformVersion",
    validator: validate_PostDeletePlatformVersion_603651, base: "/",
    url: url_PostDeletePlatformVersion_603652,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeletePlatformVersion_603634 = ref object of OpenApiRestCall_602467
proc url_GetDeletePlatformVersion_603636(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeletePlatformVersion_603635(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_603637 = query.getOrDefault("PlatformArn")
  valid_603637 = validateParameter(valid_603637, JString, required = false,
                                 default = nil)
  if valid_603637 != nil:
    section.add "PlatformArn", valid_603637
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603638 = query.getOrDefault("Action")
  valid_603638 = validateParameter(valid_603638, JString, required = true,
                                 default = newJString("DeletePlatformVersion"))
  if valid_603638 != nil:
    section.add "Action", valid_603638
  var valid_603639 = query.getOrDefault("Version")
  valid_603639 = validateParameter(valid_603639, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603639 != nil:
    section.add "Version", valid_603639
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
  var valid_603640 = header.getOrDefault("X-Amz-Date")
  valid_603640 = validateParameter(valid_603640, JString, required = false,
                                 default = nil)
  if valid_603640 != nil:
    section.add "X-Amz-Date", valid_603640
  var valid_603641 = header.getOrDefault("X-Amz-Security-Token")
  valid_603641 = validateParameter(valid_603641, JString, required = false,
                                 default = nil)
  if valid_603641 != nil:
    section.add "X-Amz-Security-Token", valid_603641
  var valid_603642 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603642 = validateParameter(valid_603642, JString, required = false,
                                 default = nil)
  if valid_603642 != nil:
    section.add "X-Amz-Content-Sha256", valid_603642
  var valid_603643 = header.getOrDefault("X-Amz-Algorithm")
  valid_603643 = validateParameter(valid_603643, JString, required = false,
                                 default = nil)
  if valid_603643 != nil:
    section.add "X-Amz-Algorithm", valid_603643
  var valid_603644 = header.getOrDefault("X-Amz-Signature")
  valid_603644 = validateParameter(valid_603644, JString, required = false,
                                 default = nil)
  if valid_603644 != nil:
    section.add "X-Amz-Signature", valid_603644
  var valid_603645 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603645 = validateParameter(valid_603645, JString, required = false,
                                 default = nil)
  if valid_603645 != nil:
    section.add "X-Amz-SignedHeaders", valid_603645
  var valid_603646 = header.getOrDefault("X-Amz-Credential")
  valid_603646 = validateParameter(valid_603646, JString, required = false,
                                 default = nil)
  if valid_603646 != nil:
    section.add "X-Amz-Credential", valid_603646
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603647: Call_GetDeletePlatformVersion_603634; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified version of a custom platform.
  ## 
  let valid = call_603647.validator(path, query, header, formData, body)
  let scheme = call_603647.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603647.url(scheme.get, call_603647.host, call_603647.base,
                         call_603647.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603647, url, valid)

proc call*(call_603648: Call_GetDeletePlatformVersion_603634;
          PlatformArn: string = ""; Action: string = "DeletePlatformVersion";
          Version: string = "2010-12-01"): Recallable =
  ## getDeletePlatformVersion
  ## Deletes the specified version of a custom platform.
  ##   PlatformArn: string
  ##              : The ARN of the version of the custom platform.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603649 = newJObject()
  add(query_603649, "PlatformArn", newJString(PlatformArn))
  add(query_603649, "Action", newJString(Action))
  add(query_603649, "Version", newJString(Version))
  result = call_603648.call(nil, query_603649, nil, nil, nil)

var getDeletePlatformVersion* = Call_GetDeletePlatformVersion_603634(
    name: "getDeletePlatformVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeletePlatformVersion",
    validator: validate_GetDeletePlatformVersion_603635, base: "/",
    url: url_GetDeletePlatformVersion_603636, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAccountAttributes_603682 = ref object of OpenApiRestCall_602467
proc url_PostDescribeAccountAttributes_603684(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeAccountAttributes_603683(path: JsonNode; query: JsonNode;
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
  var valid_603685 = query.getOrDefault("Action")
  valid_603685 = validateParameter(valid_603685, JString, required = true, default = newJString(
      "DescribeAccountAttributes"))
  if valid_603685 != nil:
    section.add "Action", valid_603685
  var valid_603686 = query.getOrDefault("Version")
  valid_603686 = validateParameter(valid_603686, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603686 != nil:
    section.add "Version", valid_603686
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
  var valid_603687 = header.getOrDefault("X-Amz-Date")
  valid_603687 = validateParameter(valid_603687, JString, required = false,
                                 default = nil)
  if valid_603687 != nil:
    section.add "X-Amz-Date", valid_603687
  var valid_603688 = header.getOrDefault("X-Amz-Security-Token")
  valid_603688 = validateParameter(valid_603688, JString, required = false,
                                 default = nil)
  if valid_603688 != nil:
    section.add "X-Amz-Security-Token", valid_603688
  var valid_603689 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603689 = validateParameter(valid_603689, JString, required = false,
                                 default = nil)
  if valid_603689 != nil:
    section.add "X-Amz-Content-Sha256", valid_603689
  var valid_603690 = header.getOrDefault("X-Amz-Algorithm")
  valid_603690 = validateParameter(valid_603690, JString, required = false,
                                 default = nil)
  if valid_603690 != nil:
    section.add "X-Amz-Algorithm", valid_603690
  var valid_603691 = header.getOrDefault("X-Amz-Signature")
  valid_603691 = validateParameter(valid_603691, JString, required = false,
                                 default = nil)
  if valid_603691 != nil:
    section.add "X-Amz-Signature", valid_603691
  var valid_603692 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603692 = validateParameter(valid_603692, JString, required = false,
                                 default = nil)
  if valid_603692 != nil:
    section.add "X-Amz-SignedHeaders", valid_603692
  var valid_603693 = header.getOrDefault("X-Amz-Credential")
  valid_603693 = validateParameter(valid_603693, JString, required = false,
                                 default = nil)
  if valid_603693 != nil:
    section.add "X-Amz-Credential", valid_603693
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603694: Call_PostDescribeAccountAttributes_603682; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ## 
  let valid = call_603694.validator(path, query, header, formData, body)
  let scheme = call_603694.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603694.url(scheme.get, call_603694.host, call_603694.base,
                         call_603694.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603694, url, valid)

proc call*(call_603695: Call_PostDescribeAccountAttributes_603682;
          Action: string = "DescribeAccountAttributes";
          Version: string = "2010-12-01"): Recallable =
  ## postDescribeAccountAttributes
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603696 = newJObject()
  add(query_603696, "Action", newJString(Action))
  add(query_603696, "Version", newJString(Version))
  result = call_603695.call(nil, query_603696, nil, nil, nil)

var postDescribeAccountAttributes* = Call_PostDescribeAccountAttributes_603682(
    name: "postDescribeAccountAttributes", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeAccountAttributes",
    validator: validate_PostDescribeAccountAttributes_603683, base: "/",
    url: url_PostDescribeAccountAttributes_603684,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAccountAttributes_603667 = ref object of OpenApiRestCall_602467
proc url_GetDescribeAccountAttributes_603669(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeAccountAttributes_603668(path: JsonNode; query: JsonNode;
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
  var valid_603670 = query.getOrDefault("Action")
  valid_603670 = validateParameter(valid_603670, JString, required = true, default = newJString(
      "DescribeAccountAttributes"))
  if valid_603670 != nil:
    section.add "Action", valid_603670
  var valid_603671 = query.getOrDefault("Version")
  valid_603671 = validateParameter(valid_603671, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603671 != nil:
    section.add "Version", valid_603671
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
  var valid_603672 = header.getOrDefault("X-Amz-Date")
  valid_603672 = validateParameter(valid_603672, JString, required = false,
                                 default = nil)
  if valid_603672 != nil:
    section.add "X-Amz-Date", valid_603672
  var valid_603673 = header.getOrDefault("X-Amz-Security-Token")
  valid_603673 = validateParameter(valid_603673, JString, required = false,
                                 default = nil)
  if valid_603673 != nil:
    section.add "X-Amz-Security-Token", valid_603673
  var valid_603674 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603674 = validateParameter(valid_603674, JString, required = false,
                                 default = nil)
  if valid_603674 != nil:
    section.add "X-Amz-Content-Sha256", valid_603674
  var valid_603675 = header.getOrDefault("X-Amz-Algorithm")
  valid_603675 = validateParameter(valid_603675, JString, required = false,
                                 default = nil)
  if valid_603675 != nil:
    section.add "X-Amz-Algorithm", valid_603675
  var valid_603676 = header.getOrDefault("X-Amz-Signature")
  valid_603676 = validateParameter(valid_603676, JString, required = false,
                                 default = nil)
  if valid_603676 != nil:
    section.add "X-Amz-Signature", valid_603676
  var valid_603677 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603677 = validateParameter(valid_603677, JString, required = false,
                                 default = nil)
  if valid_603677 != nil:
    section.add "X-Amz-SignedHeaders", valid_603677
  var valid_603678 = header.getOrDefault("X-Amz-Credential")
  valid_603678 = validateParameter(valid_603678, JString, required = false,
                                 default = nil)
  if valid_603678 != nil:
    section.add "X-Amz-Credential", valid_603678
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603679: Call_GetDescribeAccountAttributes_603667; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ## 
  let valid = call_603679.validator(path, query, header, formData, body)
  let scheme = call_603679.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603679.url(scheme.get, call_603679.host, call_603679.base,
                         call_603679.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603679, url, valid)

proc call*(call_603680: Call_GetDescribeAccountAttributes_603667;
          Action: string = "DescribeAccountAttributes";
          Version: string = "2010-12-01"): Recallable =
  ## getDescribeAccountAttributes
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603681 = newJObject()
  add(query_603681, "Action", newJString(Action))
  add(query_603681, "Version", newJString(Version))
  result = call_603680.call(nil, query_603681, nil, nil, nil)

var getDescribeAccountAttributes* = Call_GetDescribeAccountAttributes_603667(
    name: "getDescribeAccountAttributes", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeAccountAttributes",
    validator: validate_GetDescribeAccountAttributes_603668, base: "/",
    url: url_GetDescribeAccountAttributes_603669,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeApplicationVersions_603716 = ref object of OpenApiRestCall_602467
proc url_PostDescribeApplicationVersions_603718(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeApplicationVersions_603717(path: JsonNode;
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
  var valid_603719 = query.getOrDefault("Action")
  valid_603719 = validateParameter(valid_603719, JString, required = true, default = newJString(
      "DescribeApplicationVersions"))
  if valid_603719 != nil:
    section.add "Action", valid_603719
  var valid_603720 = query.getOrDefault("Version")
  valid_603720 = validateParameter(valid_603720, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603720 != nil:
    section.add "Version", valid_603720
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
  var valid_603721 = header.getOrDefault("X-Amz-Date")
  valid_603721 = validateParameter(valid_603721, JString, required = false,
                                 default = nil)
  if valid_603721 != nil:
    section.add "X-Amz-Date", valid_603721
  var valid_603722 = header.getOrDefault("X-Amz-Security-Token")
  valid_603722 = validateParameter(valid_603722, JString, required = false,
                                 default = nil)
  if valid_603722 != nil:
    section.add "X-Amz-Security-Token", valid_603722
  var valid_603723 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603723 = validateParameter(valid_603723, JString, required = false,
                                 default = nil)
  if valid_603723 != nil:
    section.add "X-Amz-Content-Sha256", valid_603723
  var valid_603724 = header.getOrDefault("X-Amz-Algorithm")
  valid_603724 = validateParameter(valid_603724, JString, required = false,
                                 default = nil)
  if valid_603724 != nil:
    section.add "X-Amz-Algorithm", valid_603724
  var valid_603725 = header.getOrDefault("X-Amz-Signature")
  valid_603725 = validateParameter(valid_603725, JString, required = false,
                                 default = nil)
  if valid_603725 != nil:
    section.add "X-Amz-Signature", valid_603725
  var valid_603726 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603726 = validateParameter(valid_603726, JString, required = false,
                                 default = nil)
  if valid_603726 != nil:
    section.add "X-Amz-SignedHeaders", valid_603726
  var valid_603727 = header.getOrDefault("X-Amz-Credential")
  valid_603727 = validateParameter(valid_603727, JString, required = false,
                                 default = nil)
  if valid_603727 != nil:
    section.add "X-Amz-Credential", valid_603727
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
  var valid_603728 = formData.getOrDefault("NextToken")
  valid_603728 = validateParameter(valid_603728, JString, required = false,
                                 default = nil)
  if valid_603728 != nil:
    section.add "NextToken", valid_603728
  var valid_603729 = formData.getOrDefault("ApplicationName")
  valid_603729 = validateParameter(valid_603729, JString, required = false,
                                 default = nil)
  if valid_603729 != nil:
    section.add "ApplicationName", valid_603729
  var valid_603730 = formData.getOrDefault("MaxRecords")
  valid_603730 = validateParameter(valid_603730, JInt, required = false, default = nil)
  if valid_603730 != nil:
    section.add "MaxRecords", valid_603730
  var valid_603731 = formData.getOrDefault("VersionLabels")
  valid_603731 = validateParameter(valid_603731, JArray, required = false,
                                 default = nil)
  if valid_603731 != nil:
    section.add "VersionLabels", valid_603731
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603732: Call_PostDescribeApplicationVersions_603716;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieve a list of application versions.
  ## 
  let valid = call_603732.validator(path, query, header, formData, body)
  let scheme = call_603732.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603732.url(scheme.get, call_603732.host, call_603732.base,
                         call_603732.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603732, url, valid)

proc call*(call_603733: Call_PostDescribeApplicationVersions_603716;
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
  var query_603734 = newJObject()
  var formData_603735 = newJObject()
  add(formData_603735, "NextToken", newJString(NextToken))
  add(query_603734, "Action", newJString(Action))
  add(formData_603735, "ApplicationName", newJString(ApplicationName))
  add(formData_603735, "MaxRecords", newJInt(MaxRecords))
  add(query_603734, "Version", newJString(Version))
  if VersionLabels != nil:
    formData_603735.add "VersionLabels", VersionLabels
  result = call_603733.call(nil, query_603734, nil, formData_603735, nil)

var postDescribeApplicationVersions* = Call_PostDescribeApplicationVersions_603716(
    name: "postDescribeApplicationVersions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplicationVersions",
    validator: validate_PostDescribeApplicationVersions_603717, base: "/",
    url: url_PostDescribeApplicationVersions_603718,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeApplicationVersions_603697 = ref object of OpenApiRestCall_602467
proc url_GetDescribeApplicationVersions_603699(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeApplicationVersions_603698(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_603700 = query.getOrDefault("MaxRecords")
  valid_603700 = validateParameter(valid_603700, JInt, required = false, default = nil)
  if valid_603700 != nil:
    section.add "MaxRecords", valid_603700
  var valid_603701 = query.getOrDefault("ApplicationName")
  valid_603701 = validateParameter(valid_603701, JString, required = false,
                                 default = nil)
  if valid_603701 != nil:
    section.add "ApplicationName", valid_603701
  var valid_603702 = query.getOrDefault("NextToken")
  valid_603702 = validateParameter(valid_603702, JString, required = false,
                                 default = nil)
  if valid_603702 != nil:
    section.add "NextToken", valid_603702
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603703 = query.getOrDefault("Action")
  valid_603703 = validateParameter(valid_603703, JString, required = true, default = newJString(
      "DescribeApplicationVersions"))
  if valid_603703 != nil:
    section.add "Action", valid_603703
  var valid_603704 = query.getOrDefault("VersionLabels")
  valid_603704 = validateParameter(valid_603704, JArray, required = false,
                                 default = nil)
  if valid_603704 != nil:
    section.add "VersionLabels", valid_603704
  var valid_603705 = query.getOrDefault("Version")
  valid_603705 = validateParameter(valid_603705, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603705 != nil:
    section.add "Version", valid_603705
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
  var valid_603706 = header.getOrDefault("X-Amz-Date")
  valid_603706 = validateParameter(valid_603706, JString, required = false,
                                 default = nil)
  if valid_603706 != nil:
    section.add "X-Amz-Date", valid_603706
  var valid_603707 = header.getOrDefault("X-Amz-Security-Token")
  valid_603707 = validateParameter(valid_603707, JString, required = false,
                                 default = nil)
  if valid_603707 != nil:
    section.add "X-Amz-Security-Token", valid_603707
  var valid_603708 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603708 = validateParameter(valid_603708, JString, required = false,
                                 default = nil)
  if valid_603708 != nil:
    section.add "X-Amz-Content-Sha256", valid_603708
  var valid_603709 = header.getOrDefault("X-Amz-Algorithm")
  valid_603709 = validateParameter(valid_603709, JString, required = false,
                                 default = nil)
  if valid_603709 != nil:
    section.add "X-Amz-Algorithm", valid_603709
  var valid_603710 = header.getOrDefault("X-Amz-Signature")
  valid_603710 = validateParameter(valid_603710, JString, required = false,
                                 default = nil)
  if valid_603710 != nil:
    section.add "X-Amz-Signature", valid_603710
  var valid_603711 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603711 = validateParameter(valid_603711, JString, required = false,
                                 default = nil)
  if valid_603711 != nil:
    section.add "X-Amz-SignedHeaders", valid_603711
  var valid_603712 = header.getOrDefault("X-Amz-Credential")
  valid_603712 = validateParameter(valid_603712, JString, required = false,
                                 default = nil)
  if valid_603712 != nil:
    section.add "X-Amz-Credential", valid_603712
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603713: Call_GetDescribeApplicationVersions_603697; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a list of application versions.
  ## 
  let valid = call_603713.validator(path, query, header, formData, body)
  let scheme = call_603713.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603713.url(scheme.get, call_603713.host, call_603713.base,
                         call_603713.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603713, url, valid)

proc call*(call_603714: Call_GetDescribeApplicationVersions_603697;
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
  var query_603715 = newJObject()
  add(query_603715, "MaxRecords", newJInt(MaxRecords))
  add(query_603715, "ApplicationName", newJString(ApplicationName))
  add(query_603715, "NextToken", newJString(NextToken))
  add(query_603715, "Action", newJString(Action))
  if VersionLabels != nil:
    query_603715.add "VersionLabels", VersionLabels
  add(query_603715, "Version", newJString(Version))
  result = call_603714.call(nil, query_603715, nil, nil, nil)

var getDescribeApplicationVersions* = Call_GetDescribeApplicationVersions_603697(
    name: "getDescribeApplicationVersions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplicationVersions",
    validator: validate_GetDescribeApplicationVersions_603698, base: "/",
    url: url_GetDescribeApplicationVersions_603699,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeApplications_603752 = ref object of OpenApiRestCall_602467
proc url_PostDescribeApplications_603754(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeApplications_603753(path: JsonNode; query: JsonNode;
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
  var valid_603755 = query.getOrDefault("Action")
  valid_603755 = validateParameter(valid_603755, JString, required = true,
                                 default = newJString("DescribeApplications"))
  if valid_603755 != nil:
    section.add "Action", valid_603755
  var valid_603756 = query.getOrDefault("Version")
  valid_603756 = validateParameter(valid_603756, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603756 != nil:
    section.add "Version", valid_603756
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
  var valid_603757 = header.getOrDefault("X-Amz-Date")
  valid_603757 = validateParameter(valid_603757, JString, required = false,
                                 default = nil)
  if valid_603757 != nil:
    section.add "X-Amz-Date", valid_603757
  var valid_603758 = header.getOrDefault("X-Amz-Security-Token")
  valid_603758 = validateParameter(valid_603758, JString, required = false,
                                 default = nil)
  if valid_603758 != nil:
    section.add "X-Amz-Security-Token", valid_603758
  var valid_603759 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603759 = validateParameter(valid_603759, JString, required = false,
                                 default = nil)
  if valid_603759 != nil:
    section.add "X-Amz-Content-Sha256", valid_603759
  var valid_603760 = header.getOrDefault("X-Amz-Algorithm")
  valid_603760 = validateParameter(valid_603760, JString, required = false,
                                 default = nil)
  if valid_603760 != nil:
    section.add "X-Amz-Algorithm", valid_603760
  var valid_603761 = header.getOrDefault("X-Amz-Signature")
  valid_603761 = validateParameter(valid_603761, JString, required = false,
                                 default = nil)
  if valid_603761 != nil:
    section.add "X-Amz-Signature", valid_603761
  var valid_603762 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603762 = validateParameter(valid_603762, JString, required = false,
                                 default = nil)
  if valid_603762 != nil:
    section.add "X-Amz-SignedHeaders", valid_603762
  var valid_603763 = header.getOrDefault("X-Amz-Credential")
  valid_603763 = validateParameter(valid_603763, JString, required = false,
                                 default = nil)
  if valid_603763 != nil:
    section.add "X-Amz-Credential", valid_603763
  result.add "header", section
  ## parameters in `formData` object:
  ##   ApplicationNames: JArray
  ##                   : If specified, AWS Elastic Beanstalk restricts the returned descriptions to only include those with the specified names.
  section = newJObject()
  var valid_603764 = formData.getOrDefault("ApplicationNames")
  valid_603764 = validateParameter(valid_603764, JArray, required = false,
                                 default = nil)
  if valid_603764 != nil:
    section.add "ApplicationNames", valid_603764
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603765: Call_PostDescribeApplications_603752; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the descriptions of existing applications.
  ## 
  let valid = call_603765.validator(path, query, header, formData, body)
  let scheme = call_603765.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603765.url(scheme.get, call_603765.host, call_603765.base,
                         call_603765.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603765, url, valid)

proc call*(call_603766: Call_PostDescribeApplications_603752;
          ApplicationNames: JsonNode = nil; Action: string = "DescribeApplications";
          Version: string = "2010-12-01"): Recallable =
  ## postDescribeApplications
  ## Returns the descriptions of existing applications.
  ##   ApplicationNames: JArray
  ##                   : If specified, AWS Elastic Beanstalk restricts the returned descriptions to only include those with the specified names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603767 = newJObject()
  var formData_603768 = newJObject()
  if ApplicationNames != nil:
    formData_603768.add "ApplicationNames", ApplicationNames
  add(query_603767, "Action", newJString(Action))
  add(query_603767, "Version", newJString(Version))
  result = call_603766.call(nil, query_603767, nil, formData_603768, nil)

var postDescribeApplications* = Call_PostDescribeApplications_603752(
    name: "postDescribeApplications", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplications",
    validator: validate_PostDescribeApplications_603753, base: "/",
    url: url_PostDescribeApplications_603754, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeApplications_603736 = ref object of OpenApiRestCall_602467
proc url_GetDescribeApplications_603738(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeApplications_603737(path: JsonNode; query: JsonNode;
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
  var valid_603739 = query.getOrDefault("ApplicationNames")
  valid_603739 = validateParameter(valid_603739, JArray, required = false,
                                 default = nil)
  if valid_603739 != nil:
    section.add "ApplicationNames", valid_603739
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603740 = query.getOrDefault("Action")
  valid_603740 = validateParameter(valid_603740, JString, required = true,
                                 default = newJString("DescribeApplications"))
  if valid_603740 != nil:
    section.add "Action", valid_603740
  var valid_603741 = query.getOrDefault("Version")
  valid_603741 = validateParameter(valid_603741, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603741 != nil:
    section.add "Version", valid_603741
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
  var valid_603742 = header.getOrDefault("X-Amz-Date")
  valid_603742 = validateParameter(valid_603742, JString, required = false,
                                 default = nil)
  if valid_603742 != nil:
    section.add "X-Amz-Date", valid_603742
  var valid_603743 = header.getOrDefault("X-Amz-Security-Token")
  valid_603743 = validateParameter(valid_603743, JString, required = false,
                                 default = nil)
  if valid_603743 != nil:
    section.add "X-Amz-Security-Token", valid_603743
  var valid_603744 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603744 = validateParameter(valid_603744, JString, required = false,
                                 default = nil)
  if valid_603744 != nil:
    section.add "X-Amz-Content-Sha256", valid_603744
  var valid_603745 = header.getOrDefault("X-Amz-Algorithm")
  valid_603745 = validateParameter(valid_603745, JString, required = false,
                                 default = nil)
  if valid_603745 != nil:
    section.add "X-Amz-Algorithm", valid_603745
  var valid_603746 = header.getOrDefault("X-Amz-Signature")
  valid_603746 = validateParameter(valid_603746, JString, required = false,
                                 default = nil)
  if valid_603746 != nil:
    section.add "X-Amz-Signature", valid_603746
  var valid_603747 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603747 = validateParameter(valid_603747, JString, required = false,
                                 default = nil)
  if valid_603747 != nil:
    section.add "X-Amz-SignedHeaders", valid_603747
  var valid_603748 = header.getOrDefault("X-Amz-Credential")
  valid_603748 = validateParameter(valid_603748, JString, required = false,
                                 default = nil)
  if valid_603748 != nil:
    section.add "X-Amz-Credential", valid_603748
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603749: Call_GetDescribeApplications_603736; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the descriptions of existing applications.
  ## 
  let valid = call_603749.validator(path, query, header, formData, body)
  let scheme = call_603749.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603749.url(scheme.get, call_603749.host, call_603749.base,
                         call_603749.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603749, url, valid)

proc call*(call_603750: Call_GetDescribeApplications_603736;
          ApplicationNames: JsonNode = nil; Action: string = "DescribeApplications";
          Version: string = "2010-12-01"): Recallable =
  ## getDescribeApplications
  ## Returns the descriptions of existing applications.
  ##   ApplicationNames: JArray
  ##                   : If specified, AWS Elastic Beanstalk restricts the returned descriptions to only include those with the specified names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603751 = newJObject()
  if ApplicationNames != nil:
    query_603751.add "ApplicationNames", ApplicationNames
  add(query_603751, "Action", newJString(Action))
  add(query_603751, "Version", newJString(Version))
  result = call_603750.call(nil, query_603751, nil, nil, nil)

var getDescribeApplications* = Call_GetDescribeApplications_603736(
    name: "getDescribeApplications", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplications",
    validator: validate_GetDescribeApplications_603737, base: "/",
    url: url_GetDescribeApplications_603738, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeConfigurationOptions_603790 = ref object of OpenApiRestCall_602467
proc url_PostDescribeConfigurationOptions_603792(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeConfigurationOptions_603791(path: JsonNode;
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
  var valid_603793 = query.getOrDefault("Action")
  valid_603793 = validateParameter(valid_603793, JString, required = true, default = newJString(
      "DescribeConfigurationOptions"))
  if valid_603793 != nil:
    section.add "Action", valid_603793
  var valid_603794 = query.getOrDefault("Version")
  valid_603794 = validateParameter(valid_603794, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603794 != nil:
    section.add "Version", valid_603794
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
  var valid_603795 = header.getOrDefault("X-Amz-Date")
  valid_603795 = validateParameter(valid_603795, JString, required = false,
                                 default = nil)
  if valid_603795 != nil:
    section.add "X-Amz-Date", valid_603795
  var valid_603796 = header.getOrDefault("X-Amz-Security-Token")
  valid_603796 = validateParameter(valid_603796, JString, required = false,
                                 default = nil)
  if valid_603796 != nil:
    section.add "X-Amz-Security-Token", valid_603796
  var valid_603797 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603797 = validateParameter(valid_603797, JString, required = false,
                                 default = nil)
  if valid_603797 != nil:
    section.add "X-Amz-Content-Sha256", valid_603797
  var valid_603798 = header.getOrDefault("X-Amz-Algorithm")
  valid_603798 = validateParameter(valid_603798, JString, required = false,
                                 default = nil)
  if valid_603798 != nil:
    section.add "X-Amz-Algorithm", valid_603798
  var valid_603799 = header.getOrDefault("X-Amz-Signature")
  valid_603799 = validateParameter(valid_603799, JString, required = false,
                                 default = nil)
  if valid_603799 != nil:
    section.add "X-Amz-Signature", valid_603799
  var valid_603800 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603800 = validateParameter(valid_603800, JString, required = false,
                                 default = nil)
  if valid_603800 != nil:
    section.add "X-Amz-SignedHeaders", valid_603800
  var valid_603801 = header.getOrDefault("X-Amz-Credential")
  valid_603801 = validateParameter(valid_603801, JString, required = false,
                                 default = nil)
  if valid_603801 != nil:
    section.add "X-Amz-Credential", valid_603801
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
  var valid_603802 = formData.getOrDefault("Options")
  valid_603802 = validateParameter(valid_603802, JArray, required = false,
                                 default = nil)
  if valid_603802 != nil:
    section.add "Options", valid_603802
  var valid_603803 = formData.getOrDefault("SolutionStackName")
  valid_603803 = validateParameter(valid_603803, JString, required = false,
                                 default = nil)
  if valid_603803 != nil:
    section.add "SolutionStackName", valid_603803
  var valid_603804 = formData.getOrDefault("EnvironmentName")
  valid_603804 = validateParameter(valid_603804, JString, required = false,
                                 default = nil)
  if valid_603804 != nil:
    section.add "EnvironmentName", valid_603804
  var valid_603805 = formData.getOrDefault("ApplicationName")
  valid_603805 = validateParameter(valid_603805, JString, required = false,
                                 default = nil)
  if valid_603805 != nil:
    section.add "ApplicationName", valid_603805
  var valid_603806 = formData.getOrDefault("PlatformArn")
  valid_603806 = validateParameter(valid_603806, JString, required = false,
                                 default = nil)
  if valid_603806 != nil:
    section.add "PlatformArn", valid_603806
  var valid_603807 = formData.getOrDefault("TemplateName")
  valid_603807 = validateParameter(valid_603807, JString, required = false,
                                 default = nil)
  if valid_603807 != nil:
    section.add "TemplateName", valid_603807
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603808: Call_PostDescribeConfigurationOptions_603790;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the configuration options that are used in a particular configuration template or environment, or that a specified solution stack defines. The description includes the values the options, their default values, and an indication of the required action on a running environment if an option value is changed.
  ## 
  let valid = call_603808.validator(path, query, header, formData, body)
  let scheme = call_603808.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603808.url(scheme.get, call_603808.host, call_603808.base,
                         call_603808.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603808, url, valid)

proc call*(call_603809: Call_PostDescribeConfigurationOptions_603790;
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
  var query_603810 = newJObject()
  var formData_603811 = newJObject()
  if Options != nil:
    formData_603811.add "Options", Options
  add(formData_603811, "SolutionStackName", newJString(SolutionStackName))
  add(formData_603811, "EnvironmentName", newJString(EnvironmentName))
  add(query_603810, "Action", newJString(Action))
  add(formData_603811, "ApplicationName", newJString(ApplicationName))
  add(formData_603811, "PlatformArn", newJString(PlatformArn))
  add(formData_603811, "TemplateName", newJString(TemplateName))
  add(query_603810, "Version", newJString(Version))
  result = call_603809.call(nil, query_603810, nil, formData_603811, nil)

var postDescribeConfigurationOptions* = Call_PostDescribeConfigurationOptions_603790(
    name: "postDescribeConfigurationOptions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationOptions",
    validator: validate_PostDescribeConfigurationOptions_603791, base: "/",
    url: url_PostDescribeConfigurationOptions_603792,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeConfigurationOptions_603769 = ref object of OpenApiRestCall_602467
proc url_GetDescribeConfigurationOptions_603771(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeConfigurationOptions_603770(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_603772 = query.getOrDefault("Options")
  valid_603772 = validateParameter(valid_603772, JArray, required = false,
                                 default = nil)
  if valid_603772 != nil:
    section.add "Options", valid_603772
  var valid_603773 = query.getOrDefault("ApplicationName")
  valid_603773 = validateParameter(valid_603773, JString, required = false,
                                 default = nil)
  if valid_603773 != nil:
    section.add "ApplicationName", valid_603773
  var valid_603774 = query.getOrDefault("PlatformArn")
  valid_603774 = validateParameter(valid_603774, JString, required = false,
                                 default = nil)
  if valid_603774 != nil:
    section.add "PlatformArn", valid_603774
  var valid_603775 = query.getOrDefault("EnvironmentName")
  valid_603775 = validateParameter(valid_603775, JString, required = false,
                                 default = nil)
  if valid_603775 != nil:
    section.add "EnvironmentName", valid_603775
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603776 = query.getOrDefault("Action")
  valid_603776 = validateParameter(valid_603776, JString, required = true, default = newJString(
      "DescribeConfigurationOptions"))
  if valid_603776 != nil:
    section.add "Action", valid_603776
  var valid_603777 = query.getOrDefault("SolutionStackName")
  valid_603777 = validateParameter(valid_603777, JString, required = false,
                                 default = nil)
  if valid_603777 != nil:
    section.add "SolutionStackName", valid_603777
  var valid_603778 = query.getOrDefault("TemplateName")
  valid_603778 = validateParameter(valid_603778, JString, required = false,
                                 default = nil)
  if valid_603778 != nil:
    section.add "TemplateName", valid_603778
  var valid_603779 = query.getOrDefault("Version")
  valid_603779 = validateParameter(valid_603779, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603779 != nil:
    section.add "Version", valid_603779
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
  var valid_603780 = header.getOrDefault("X-Amz-Date")
  valid_603780 = validateParameter(valid_603780, JString, required = false,
                                 default = nil)
  if valid_603780 != nil:
    section.add "X-Amz-Date", valid_603780
  var valid_603781 = header.getOrDefault("X-Amz-Security-Token")
  valid_603781 = validateParameter(valid_603781, JString, required = false,
                                 default = nil)
  if valid_603781 != nil:
    section.add "X-Amz-Security-Token", valid_603781
  var valid_603782 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603782 = validateParameter(valid_603782, JString, required = false,
                                 default = nil)
  if valid_603782 != nil:
    section.add "X-Amz-Content-Sha256", valid_603782
  var valid_603783 = header.getOrDefault("X-Amz-Algorithm")
  valid_603783 = validateParameter(valid_603783, JString, required = false,
                                 default = nil)
  if valid_603783 != nil:
    section.add "X-Amz-Algorithm", valid_603783
  var valid_603784 = header.getOrDefault("X-Amz-Signature")
  valid_603784 = validateParameter(valid_603784, JString, required = false,
                                 default = nil)
  if valid_603784 != nil:
    section.add "X-Amz-Signature", valid_603784
  var valid_603785 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603785 = validateParameter(valid_603785, JString, required = false,
                                 default = nil)
  if valid_603785 != nil:
    section.add "X-Amz-SignedHeaders", valid_603785
  var valid_603786 = header.getOrDefault("X-Amz-Credential")
  valid_603786 = validateParameter(valid_603786, JString, required = false,
                                 default = nil)
  if valid_603786 != nil:
    section.add "X-Amz-Credential", valid_603786
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603787: Call_GetDescribeConfigurationOptions_603769;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the configuration options that are used in a particular configuration template or environment, or that a specified solution stack defines. The description includes the values the options, their default values, and an indication of the required action on a running environment if an option value is changed.
  ## 
  let valid = call_603787.validator(path, query, header, formData, body)
  let scheme = call_603787.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603787.url(scheme.get, call_603787.host, call_603787.base,
                         call_603787.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603787, url, valid)

proc call*(call_603788: Call_GetDescribeConfigurationOptions_603769;
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
  var query_603789 = newJObject()
  if Options != nil:
    query_603789.add "Options", Options
  add(query_603789, "ApplicationName", newJString(ApplicationName))
  add(query_603789, "PlatformArn", newJString(PlatformArn))
  add(query_603789, "EnvironmentName", newJString(EnvironmentName))
  add(query_603789, "Action", newJString(Action))
  add(query_603789, "SolutionStackName", newJString(SolutionStackName))
  add(query_603789, "TemplateName", newJString(TemplateName))
  add(query_603789, "Version", newJString(Version))
  result = call_603788.call(nil, query_603789, nil, nil, nil)

var getDescribeConfigurationOptions* = Call_GetDescribeConfigurationOptions_603769(
    name: "getDescribeConfigurationOptions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationOptions",
    validator: validate_GetDescribeConfigurationOptions_603770, base: "/",
    url: url_GetDescribeConfigurationOptions_603771,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeConfigurationSettings_603830 = ref object of OpenApiRestCall_602467
proc url_PostDescribeConfigurationSettings_603832(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeConfigurationSettings_603831(path: JsonNode;
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
  var valid_603833 = query.getOrDefault("Action")
  valid_603833 = validateParameter(valid_603833, JString, required = true, default = newJString(
      "DescribeConfigurationSettings"))
  if valid_603833 != nil:
    section.add "Action", valid_603833
  var valid_603834 = query.getOrDefault("Version")
  valid_603834 = validateParameter(valid_603834, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603834 != nil:
    section.add "Version", valid_603834
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
  var valid_603835 = header.getOrDefault("X-Amz-Date")
  valid_603835 = validateParameter(valid_603835, JString, required = false,
                                 default = nil)
  if valid_603835 != nil:
    section.add "X-Amz-Date", valid_603835
  var valid_603836 = header.getOrDefault("X-Amz-Security-Token")
  valid_603836 = validateParameter(valid_603836, JString, required = false,
                                 default = nil)
  if valid_603836 != nil:
    section.add "X-Amz-Security-Token", valid_603836
  var valid_603837 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603837 = validateParameter(valid_603837, JString, required = false,
                                 default = nil)
  if valid_603837 != nil:
    section.add "X-Amz-Content-Sha256", valid_603837
  var valid_603838 = header.getOrDefault("X-Amz-Algorithm")
  valid_603838 = validateParameter(valid_603838, JString, required = false,
                                 default = nil)
  if valid_603838 != nil:
    section.add "X-Amz-Algorithm", valid_603838
  var valid_603839 = header.getOrDefault("X-Amz-Signature")
  valid_603839 = validateParameter(valid_603839, JString, required = false,
                                 default = nil)
  if valid_603839 != nil:
    section.add "X-Amz-Signature", valid_603839
  var valid_603840 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603840 = validateParameter(valid_603840, JString, required = false,
                                 default = nil)
  if valid_603840 != nil:
    section.add "X-Amz-SignedHeaders", valid_603840
  var valid_603841 = header.getOrDefault("X-Amz-Credential")
  valid_603841 = validateParameter(valid_603841, JString, required = false,
                                 default = nil)
  if valid_603841 != nil:
    section.add "X-Amz-Credential", valid_603841
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to describe.</p> <p> Condition: You must specify either this or a TemplateName, but not both. If you specify both, AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   ApplicationName: JString (required)
  ##                  : The application for the environment or configuration template.
  ##   TemplateName: JString
  ##               : <p>The name of the configuration template to describe.</p> <p> Conditional: You must specify either this parameter or an EnvironmentName, but not both. If you specify both, AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. If you do not specify either, AWS Elastic Beanstalk returns a <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_603842 = formData.getOrDefault("EnvironmentName")
  valid_603842 = validateParameter(valid_603842, JString, required = false,
                                 default = nil)
  if valid_603842 != nil:
    section.add "EnvironmentName", valid_603842
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_603843 = formData.getOrDefault("ApplicationName")
  valid_603843 = validateParameter(valid_603843, JString, required = true,
                                 default = nil)
  if valid_603843 != nil:
    section.add "ApplicationName", valid_603843
  var valid_603844 = formData.getOrDefault("TemplateName")
  valid_603844 = validateParameter(valid_603844, JString, required = false,
                                 default = nil)
  if valid_603844 != nil:
    section.add "TemplateName", valid_603844
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603845: Call_PostDescribeConfigurationSettings_603830;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a description of the settings for the specified configuration set, that is, either a configuration template or the configuration set associated with a running environment.</p> <p>When describing the settings for the configuration set associated with a running environment, it is possible to receive two sets of setting descriptions. One is the deployed configuration set, and the other is a draft configuration of an environment that is either in the process of deployment or that failed to deploy.</p> <p>Related Topics</p> <ul> <li> <p> <a>DeleteEnvironmentConfiguration</a> </p> </li> </ul>
  ## 
  let valid = call_603845.validator(path, query, header, formData, body)
  let scheme = call_603845.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603845.url(scheme.get, call_603845.host, call_603845.base,
                         call_603845.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603845, url, valid)

proc call*(call_603846: Call_PostDescribeConfigurationSettings_603830;
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
  var query_603847 = newJObject()
  var formData_603848 = newJObject()
  add(formData_603848, "EnvironmentName", newJString(EnvironmentName))
  add(query_603847, "Action", newJString(Action))
  add(formData_603848, "ApplicationName", newJString(ApplicationName))
  add(formData_603848, "TemplateName", newJString(TemplateName))
  add(query_603847, "Version", newJString(Version))
  result = call_603846.call(nil, query_603847, nil, formData_603848, nil)

var postDescribeConfigurationSettings* = Call_PostDescribeConfigurationSettings_603830(
    name: "postDescribeConfigurationSettings", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationSettings",
    validator: validate_PostDescribeConfigurationSettings_603831, base: "/",
    url: url_PostDescribeConfigurationSettings_603832,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeConfigurationSettings_603812 = ref object of OpenApiRestCall_602467
proc url_GetDescribeConfigurationSettings_603814(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeConfigurationSettings_603813(path: JsonNode;
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
  ##   TemplateName: JString
  ##               : <p>The name of the configuration template to describe.</p> <p> Conditional: You must specify either this parameter or an EnvironmentName, but not both. If you specify both, AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. If you do not specify either, AWS Elastic Beanstalk returns a <code>MissingRequiredParameter</code> error. </p>
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_603815 = query.getOrDefault("ApplicationName")
  valid_603815 = validateParameter(valid_603815, JString, required = true,
                                 default = nil)
  if valid_603815 != nil:
    section.add "ApplicationName", valid_603815
  var valid_603816 = query.getOrDefault("EnvironmentName")
  valid_603816 = validateParameter(valid_603816, JString, required = false,
                                 default = nil)
  if valid_603816 != nil:
    section.add "EnvironmentName", valid_603816
  var valid_603817 = query.getOrDefault("Action")
  valid_603817 = validateParameter(valid_603817, JString, required = true, default = newJString(
      "DescribeConfigurationSettings"))
  if valid_603817 != nil:
    section.add "Action", valid_603817
  var valid_603818 = query.getOrDefault("TemplateName")
  valid_603818 = validateParameter(valid_603818, JString, required = false,
                                 default = nil)
  if valid_603818 != nil:
    section.add "TemplateName", valid_603818
  var valid_603819 = query.getOrDefault("Version")
  valid_603819 = validateParameter(valid_603819, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603819 != nil:
    section.add "Version", valid_603819
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
  var valid_603820 = header.getOrDefault("X-Amz-Date")
  valid_603820 = validateParameter(valid_603820, JString, required = false,
                                 default = nil)
  if valid_603820 != nil:
    section.add "X-Amz-Date", valid_603820
  var valid_603821 = header.getOrDefault("X-Amz-Security-Token")
  valid_603821 = validateParameter(valid_603821, JString, required = false,
                                 default = nil)
  if valid_603821 != nil:
    section.add "X-Amz-Security-Token", valid_603821
  var valid_603822 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603822 = validateParameter(valid_603822, JString, required = false,
                                 default = nil)
  if valid_603822 != nil:
    section.add "X-Amz-Content-Sha256", valid_603822
  var valid_603823 = header.getOrDefault("X-Amz-Algorithm")
  valid_603823 = validateParameter(valid_603823, JString, required = false,
                                 default = nil)
  if valid_603823 != nil:
    section.add "X-Amz-Algorithm", valid_603823
  var valid_603824 = header.getOrDefault("X-Amz-Signature")
  valid_603824 = validateParameter(valid_603824, JString, required = false,
                                 default = nil)
  if valid_603824 != nil:
    section.add "X-Amz-Signature", valid_603824
  var valid_603825 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603825 = validateParameter(valid_603825, JString, required = false,
                                 default = nil)
  if valid_603825 != nil:
    section.add "X-Amz-SignedHeaders", valid_603825
  var valid_603826 = header.getOrDefault("X-Amz-Credential")
  valid_603826 = validateParameter(valid_603826, JString, required = false,
                                 default = nil)
  if valid_603826 != nil:
    section.add "X-Amz-Credential", valid_603826
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603827: Call_GetDescribeConfigurationSettings_603812;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a description of the settings for the specified configuration set, that is, either a configuration template or the configuration set associated with a running environment.</p> <p>When describing the settings for the configuration set associated with a running environment, it is possible to receive two sets of setting descriptions. One is the deployed configuration set, and the other is a draft configuration of an environment that is either in the process of deployment or that failed to deploy.</p> <p>Related Topics</p> <ul> <li> <p> <a>DeleteEnvironmentConfiguration</a> </p> </li> </ul>
  ## 
  let valid = call_603827.validator(path, query, header, formData, body)
  let scheme = call_603827.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603827.url(scheme.get, call_603827.host, call_603827.base,
                         call_603827.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603827, url, valid)

proc call*(call_603828: Call_GetDescribeConfigurationSettings_603812;
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
  var query_603829 = newJObject()
  add(query_603829, "ApplicationName", newJString(ApplicationName))
  add(query_603829, "EnvironmentName", newJString(EnvironmentName))
  add(query_603829, "Action", newJString(Action))
  add(query_603829, "TemplateName", newJString(TemplateName))
  add(query_603829, "Version", newJString(Version))
  result = call_603828.call(nil, query_603829, nil, nil, nil)

var getDescribeConfigurationSettings* = Call_GetDescribeConfigurationSettings_603812(
    name: "getDescribeConfigurationSettings", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationSettings",
    validator: validate_GetDescribeConfigurationSettings_603813, base: "/",
    url: url_GetDescribeConfigurationSettings_603814,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentHealth_603867 = ref object of OpenApiRestCall_602467
proc url_PostDescribeEnvironmentHealth_603869(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEnvironmentHealth_603868(path: JsonNode; query: JsonNode;
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
  var valid_603870 = query.getOrDefault("Action")
  valid_603870 = validateParameter(valid_603870, JString, required = true, default = newJString(
      "DescribeEnvironmentHealth"))
  if valid_603870 != nil:
    section.add "Action", valid_603870
  var valid_603871 = query.getOrDefault("Version")
  valid_603871 = validateParameter(valid_603871, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603871 != nil:
    section.add "Version", valid_603871
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
  var valid_603872 = header.getOrDefault("X-Amz-Date")
  valid_603872 = validateParameter(valid_603872, JString, required = false,
                                 default = nil)
  if valid_603872 != nil:
    section.add "X-Amz-Date", valid_603872
  var valid_603873 = header.getOrDefault("X-Amz-Security-Token")
  valid_603873 = validateParameter(valid_603873, JString, required = false,
                                 default = nil)
  if valid_603873 != nil:
    section.add "X-Amz-Security-Token", valid_603873
  var valid_603874 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603874 = validateParameter(valid_603874, JString, required = false,
                                 default = nil)
  if valid_603874 != nil:
    section.add "X-Amz-Content-Sha256", valid_603874
  var valid_603875 = header.getOrDefault("X-Amz-Algorithm")
  valid_603875 = validateParameter(valid_603875, JString, required = false,
                                 default = nil)
  if valid_603875 != nil:
    section.add "X-Amz-Algorithm", valid_603875
  var valid_603876 = header.getOrDefault("X-Amz-Signature")
  valid_603876 = validateParameter(valid_603876, JString, required = false,
                                 default = nil)
  if valid_603876 != nil:
    section.add "X-Amz-Signature", valid_603876
  var valid_603877 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603877 = validateParameter(valid_603877, JString, required = false,
                                 default = nil)
  if valid_603877 != nil:
    section.add "X-Amz-SignedHeaders", valid_603877
  var valid_603878 = header.getOrDefault("X-Amz-Credential")
  valid_603878 = validateParameter(valid_603878, JString, required = false,
                                 default = nil)
  if valid_603878 != nil:
    section.add "X-Amz-Credential", valid_603878
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentId: JString
  ##                : <p>Specify the environment by ID.</p> <p>You must specify either this or an EnvironmentName, or both.</p>
  ##   EnvironmentName: JString
  ##                  : <p>Specify the environment by name.</p> <p>You must specify either this or an EnvironmentName, or both.</p>
  ##   AttributeNames: JArray
  ##                 : Specify the response elements to return. To retrieve all attributes, set to <code>All</code>. If no attribute names are specified, returns the name of the environment.
  section = newJObject()
  var valid_603879 = formData.getOrDefault("EnvironmentId")
  valid_603879 = validateParameter(valid_603879, JString, required = false,
                                 default = nil)
  if valid_603879 != nil:
    section.add "EnvironmentId", valid_603879
  var valid_603880 = formData.getOrDefault("EnvironmentName")
  valid_603880 = validateParameter(valid_603880, JString, required = false,
                                 default = nil)
  if valid_603880 != nil:
    section.add "EnvironmentName", valid_603880
  var valid_603881 = formData.getOrDefault("AttributeNames")
  valid_603881 = validateParameter(valid_603881, JArray, required = false,
                                 default = nil)
  if valid_603881 != nil:
    section.add "AttributeNames", valid_603881
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603882: Call_PostDescribeEnvironmentHealth_603867; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the overall health of the specified environment. The <b>DescribeEnvironmentHealth</b> operation is only available with AWS Elastic Beanstalk Enhanced Health.
  ## 
  let valid = call_603882.validator(path, query, header, formData, body)
  let scheme = call_603882.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603882.url(scheme.get, call_603882.host, call_603882.base,
                         call_603882.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603882, url, valid)

proc call*(call_603883: Call_PostDescribeEnvironmentHealth_603867;
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
  var query_603884 = newJObject()
  var formData_603885 = newJObject()
  add(formData_603885, "EnvironmentId", newJString(EnvironmentId))
  add(formData_603885, "EnvironmentName", newJString(EnvironmentName))
  add(query_603884, "Action", newJString(Action))
  if AttributeNames != nil:
    formData_603885.add "AttributeNames", AttributeNames
  add(query_603884, "Version", newJString(Version))
  result = call_603883.call(nil, query_603884, nil, formData_603885, nil)

var postDescribeEnvironmentHealth* = Call_PostDescribeEnvironmentHealth_603867(
    name: "postDescribeEnvironmentHealth", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentHealth",
    validator: validate_PostDescribeEnvironmentHealth_603868, base: "/",
    url: url_PostDescribeEnvironmentHealth_603869,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentHealth_603849 = ref object of OpenApiRestCall_602467
proc url_GetDescribeEnvironmentHealth_603851(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEnvironmentHealth_603850(path: JsonNode; query: JsonNode;
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
  ##   EnvironmentId: JString
  ##                : <p>Specify the environment by ID.</p> <p>You must specify either this or an EnvironmentName, or both.</p>
  ##   Version: JString (required)
  section = newJObject()
  var valid_603852 = query.getOrDefault("AttributeNames")
  valid_603852 = validateParameter(valid_603852, JArray, required = false,
                                 default = nil)
  if valid_603852 != nil:
    section.add "AttributeNames", valid_603852
  var valid_603853 = query.getOrDefault("EnvironmentName")
  valid_603853 = validateParameter(valid_603853, JString, required = false,
                                 default = nil)
  if valid_603853 != nil:
    section.add "EnvironmentName", valid_603853
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603854 = query.getOrDefault("Action")
  valid_603854 = validateParameter(valid_603854, JString, required = true, default = newJString(
      "DescribeEnvironmentHealth"))
  if valid_603854 != nil:
    section.add "Action", valid_603854
  var valid_603855 = query.getOrDefault("EnvironmentId")
  valid_603855 = validateParameter(valid_603855, JString, required = false,
                                 default = nil)
  if valid_603855 != nil:
    section.add "EnvironmentId", valid_603855
  var valid_603856 = query.getOrDefault("Version")
  valid_603856 = validateParameter(valid_603856, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603856 != nil:
    section.add "Version", valid_603856
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
  var valid_603857 = header.getOrDefault("X-Amz-Date")
  valid_603857 = validateParameter(valid_603857, JString, required = false,
                                 default = nil)
  if valid_603857 != nil:
    section.add "X-Amz-Date", valid_603857
  var valid_603858 = header.getOrDefault("X-Amz-Security-Token")
  valid_603858 = validateParameter(valid_603858, JString, required = false,
                                 default = nil)
  if valid_603858 != nil:
    section.add "X-Amz-Security-Token", valid_603858
  var valid_603859 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603859 = validateParameter(valid_603859, JString, required = false,
                                 default = nil)
  if valid_603859 != nil:
    section.add "X-Amz-Content-Sha256", valid_603859
  var valid_603860 = header.getOrDefault("X-Amz-Algorithm")
  valid_603860 = validateParameter(valid_603860, JString, required = false,
                                 default = nil)
  if valid_603860 != nil:
    section.add "X-Amz-Algorithm", valid_603860
  var valid_603861 = header.getOrDefault("X-Amz-Signature")
  valid_603861 = validateParameter(valid_603861, JString, required = false,
                                 default = nil)
  if valid_603861 != nil:
    section.add "X-Amz-Signature", valid_603861
  var valid_603862 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603862 = validateParameter(valid_603862, JString, required = false,
                                 default = nil)
  if valid_603862 != nil:
    section.add "X-Amz-SignedHeaders", valid_603862
  var valid_603863 = header.getOrDefault("X-Amz-Credential")
  valid_603863 = validateParameter(valid_603863, JString, required = false,
                                 default = nil)
  if valid_603863 != nil:
    section.add "X-Amz-Credential", valid_603863
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603864: Call_GetDescribeEnvironmentHealth_603849; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the overall health of the specified environment. The <b>DescribeEnvironmentHealth</b> operation is only available with AWS Elastic Beanstalk Enhanced Health.
  ## 
  let valid = call_603864.validator(path, query, header, formData, body)
  let scheme = call_603864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603864.url(scheme.get, call_603864.host, call_603864.base,
                         call_603864.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603864, url, valid)

proc call*(call_603865: Call_GetDescribeEnvironmentHealth_603849;
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
  var query_603866 = newJObject()
  if AttributeNames != nil:
    query_603866.add "AttributeNames", AttributeNames
  add(query_603866, "EnvironmentName", newJString(EnvironmentName))
  add(query_603866, "Action", newJString(Action))
  add(query_603866, "EnvironmentId", newJString(EnvironmentId))
  add(query_603866, "Version", newJString(Version))
  result = call_603865.call(nil, query_603866, nil, nil, nil)

var getDescribeEnvironmentHealth* = Call_GetDescribeEnvironmentHealth_603849(
    name: "getDescribeEnvironmentHealth", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentHealth",
    validator: validate_GetDescribeEnvironmentHealth_603850, base: "/",
    url: url_GetDescribeEnvironmentHealth_603851,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentManagedActionHistory_603905 = ref object of OpenApiRestCall_602467
proc url_PostDescribeEnvironmentManagedActionHistory_603907(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEnvironmentManagedActionHistory_603906(path: JsonNode;
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
  var valid_603908 = query.getOrDefault("Action")
  valid_603908 = validateParameter(valid_603908, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActionHistory"))
  if valid_603908 != nil:
    section.add "Action", valid_603908
  var valid_603909 = query.getOrDefault("Version")
  valid_603909 = validateParameter(valid_603909, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603909 != nil:
    section.add "Version", valid_603909
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
  var valid_603910 = header.getOrDefault("X-Amz-Date")
  valid_603910 = validateParameter(valid_603910, JString, required = false,
                                 default = nil)
  if valid_603910 != nil:
    section.add "X-Amz-Date", valid_603910
  var valid_603911 = header.getOrDefault("X-Amz-Security-Token")
  valid_603911 = validateParameter(valid_603911, JString, required = false,
                                 default = nil)
  if valid_603911 != nil:
    section.add "X-Amz-Security-Token", valid_603911
  var valid_603912 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603912 = validateParameter(valid_603912, JString, required = false,
                                 default = nil)
  if valid_603912 != nil:
    section.add "X-Amz-Content-Sha256", valid_603912
  var valid_603913 = header.getOrDefault("X-Amz-Algorithm")
  valid_603913 = validateParameter(valid_603913, JString, required = false,
                                 default = nil)
  if valid_603913 != nil:
    section.add "X-Amz-Algorithm", valid_603913
  var valid_603914 = header.getOrDefault("X-Amz-Signature")
  valid_603914 = validateParameter(valid_603914, JString, required = false,
                                 default = nil)
  if valid_603914 != nil:
    section.add "X-Amz-Signature", valid_603914
  var valid_603915 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603915 = validateParameter(valid_603915, JString, required = false,
                                 default = nil)
  if valid_603915 != nil:
    section.add "X-Amz-SignedHeaders", valid_603915
  var valid_603916 = header.getOrDefault("X-Amz-Credential")
  valid_603916 = validateParameter(valid_603916, JString, required = false,
                                 default = nil)
  if valid_603916 != nil:
    section.add "X-Amz-Credential", valid_603916
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
  var valid_603917 = formData.getOrDefault("NextToken")
  valid_603917 = validateParameter(valid_603917, JString, required = false,
                                 default = nil)
  if valid_603917 != nil:
    section.add "NextToken", valid_603917
  var valid_603918 = formData.getOrDefault("EnvironmentId")
  valid_603918 = validateParameter(valid_603918, JString, required = false,
                                 default = nil)
  if valid_603918 != nil:
    section.add "EnvironmentId", valid_603918
  var valid_603919 = formData.getOrDefault("EnvironmentName")
  valid_603919 = validateParameter(valid_603919, JString, required = false,
                                 default = nil)
  if valid_603919 != nil:
    section.add "EnvironmentName", valid_603919
  var valid_603920 = formData.getOrDefault("MaxItems")
  valid_603920 = validateParameter(valid_603920, JInt, required = false, default = nil)
  if valid_603920 != nil:
    section.add "MaxItems", valid_603920
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603921: Call_PostDescribeEnvironmentManagedActionHistory_603905;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists an environment's completed and failed managed actions.
  ## 
  let valid = call_603921.validator(path, query, header, formData, body)
  let scheme = call_603921.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603921.url(scheme.get, call_603921.host, call_603921.base,
                         call_603921.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603921, url, valid)

proc call*(call_603922: Call_PostDescribeEnvironmentManagedActionHistory_603905;
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
  var query_603923 = newJObject()
  var formData_603924 = newJObject()
  add(formData_603924, "NextToken", newJString(NextToken))
  add(formData_603924, "EnvironmentId", newJString(EnvironmentId))
  add(formData_603924, "EnvironmentName", newJString(EnvironmentName))
  add(query_603923, "Action", newJString(Action))
  add(formData_603924, "MaxItems", newJInt(MaxItems))
  add(query_603923, "Version", newJString(Version))
  result = call_603922.call(nil, query_603923, nil, formData_603924, nil)

var postDescribeEnvironmentManagedActionHistory* = Call_PostDescribeEnvironmentManagedActionHistory_603905(
    name: "postDescribeEnvironmentManagedActionHistory",
    meth: HttpMethod.HttpPost, host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActionHistory",
    validator: validate_PostDescribeEnvironmentManagedActionHistory_603906,
    base: "/", url: url_PostDescribeEnvironmentManagedActionHistory_603907,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentManagedActionHistory_603886 = ref object of OpenApiRestCall_602467
proc url_GetDescribeEnvironmentManagedActionHistory_603888(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEnvironmentManagedActionHistory_603887(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_603889 = query.getOrDefault("NextToken")
  valid_603889 = validateParameter(valid_603889, JString, required = false,
                                 default = nil)
  if valid_603889 != nil:
    section.add "NextToken", valid_603889
  var valid_603890 = query.getOrDefault("EnvironmentName")
  valid_603890 = validateParameter(valid_603890, JString, required = false,
                                 default = nil)
  if valid_603890 != nil:
    section.add "EnvironmentName", valid_603890
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603891 = query.getOrDefault("Action")
  valid_603891 = validateParameter(valid_603891, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActionHistory"))
  if valid_603891 != nil:
    section.add "Action", valid_603891
  var valid_603892 = query.getOrDefault("EnvironmentId")
  valid_603892 = validateParameter(valid_603892, JString, required = false,
                                 default = nil)
  if valid_603892 != nil:
    section.add "EnvironmentId", valid_603892
  var valid_603893 = query.getOrDefault("MaxItems")
  valid_603893 = validateParameter(valid_603893, JInt, required = false, default = nil)
  if valid_603893 != nil:
    section.add "MaxItems", valid_603893
  var valid_603894 = query.getOrDefault("Version")
  valid_603894 = validateParameter(valid_603894, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603894 != nil:
    section.add "Version", valid_603894
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
  var valid_603895 = header.getOrDefault("X-Amz-Date")
  valid_603895 = validateParameter(valid_603895, JString, required = false,
                                 default = nil)
  if valid_603895 != nil:
    section.add "X-Amz-Date", valid_603895
  var valid_603896 = header.getOrDefault("X-Amz-Security-Token")
  valid_603896 = validateParameter(valid_603896, JString, required = false,
                                 default = nil)
  if valid_603896 != nil:
    section.add "X-Amz-Security-Token", valid_603896
  var valid_603897 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603897 = validateParameter(valid_603897, JString, required = false,
                                 default = nil)
  if valid_603897 != nil:
    section.add "X-Amz-Content-Sha256", valid_603897
  var valid_603898 = header.getOrDefault("X-Amz-Algorithm")
  valid_603898 = validateParameter(valid_603898, JString, required = false,
                                 default = nil)
  if valid_603898 != nil:
    section.add "X-Amz-Algorithm", valid_603898
  var valid_603899 = header.getOrDefault("X-Amz-Signature")
  valid_603899 = validateParameter(valid_603899, JString, required = false,
                                 default = nil)
  if valid_603899 != nil:
    section.add "X-Amz-Signature", valid_603899
  var valid_603900 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603900 = validateParameter(valid_603900, JString, required = false,
                                 default = nil)
  if valid_603900 != nil:
    section.add "X-Amz-SignedHeaders", valid_603900
  var valid_603901 = header.getOrDefault("X-Amz-Credential")
  valid_603901 = validateParameter(valid_603901, JString, required = false,
                                 default = nil)
  if valid_603901 != nil:
    section.add "X-Amz-Credential", valid_603901
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603902: Call_GetDescribeEnvironmentManagedActionHistory_603886;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists an environment's completed and failed managed actions.
  ## 
  let valid = call_603902.validator(path, query, header, formData, body)
  let scheme = call_603902.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603902.url(scheme.get, call_603902.host, call_603902.base,
                         call_603902.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603902, url, valid)

proc call*(call_603903: Call_GetDescribeEnvironmentManagedActionHistory_603886;
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
  var query_603904 = newJObject()
  add(query_603904, "NextToken", newJString(NextToken))
  add(query_603904, "EnvironmentName", newJString(EnvironmentName))
  add(query_603904, "Action", newJString(Action))
  add(query_603904, "EnvironmentId", newJString(EnvironmentId))
  add(query_603904, "MaxItems", newJInt(MaxItems))
  add(query_603904, "Version", newJString(Version))
  result = call_603903.call(nil, query_603904, nil, nil, nil)

var getDescribeEnvironmentManagedActionHistory* = Call_GetDescribeEnvironmentManagedActionHistory_603886(
    name: "getDescribeEnvironmentManagedActionHistory", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActionHistory",
    validator: validate_GetDescribeEnvironmentManagedActionHistory_603887,
    base: "/", url: url_GetDescribeEnvironmentManagedActionHistory_603888,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentManagedActions_603943 = ref object of OpenApiRestCall_602467
proc url_PostDescribeEnvironmentManagedActions_603945(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEnvironmentManagedActions_603944(path: JsonNode;
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
  var valid_603946 = query.getOrDefault("Action")
  valid_603946 = validateParameter(valid_603946, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActions"))
  if valid_603946 != nil:
    section.add "Action", valid_603946
  var valid_603947 = query.getOrDefault("Version")
  valid_603947 = validateParameter(valid_603947, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603947 != nil:
    section.add "Version", valid_603947
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
  var valid_603948 = header.getOrDefault("X-Amz-Date")
  valid_603948 = validateParameter(valid_603948, JString, required = false,
                                 default = nil)
  if valid_603948 != nil:
    section.add "X-Amz-Date", valid_603948
  var valid_603949 = header.getOrDefault("X-Amz-Security-Token")
  valid_603949 = validateParameter(valid_603949, JString, required = false,
                                 default = nil)
  if valid_603949 != nil:
    section.add "X-Amz-Security-Token", valid_603949
  var valid_603950 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603950 = validateParameter(valid_603950, JString, required = false,
                                 default = nil)
  if valid_603950 != nil:
    section.add "X-Amz-Content-Sha256", valid_603950
  var valid_603951 = header.getOrDefault("X-Amz-Algorithm")
  valid_603951 = validateParameter(valid_603951, JString, required = false,
                                 default = nil)
  if valid_603951 != nil:
    section.add "X-Amz-Algorithm", valid_603951
  var valid_603952 = header.getOrDefault("X-Amz-Signature")
  valid_603952 = validateParameter(valid_603952, JString, required = false,
                                 default = nil)
  if valid_603952 != nil:
    section.add "X-Amz-Signature", valid_603952
  var valid_603953 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603953 = validateParameter(valid_603953, JString, required = false,
                                 default = nil)
  if valid_603953 != nil:
    section.add "X-Amz-SignedHeaders", valid_603953
  var valid_603954 = header.getOrDefault("X-Amz-Credential")
  valid_603954 = validateParameter(valid_603954, JString, required = false,
                                 default = nil)
  if valid_603954 != nil:
    section.add "X-Amz-Credential", valid_603954
  result.add "header", section
  ## parameters in `formData` object:
  ##   Status: JString
  ##         : To show only actions with a particular status, specify a status.
  ##   EnvironmentId: JString
  ##                : The environment ID of the target environment.
  ##   EnvironmentName: JString
  ##                  : The name of the target environment.
  section = newJObject()
  var valid_603955 = formData.getOrDefault("Status")
  valid_603955 = validateParameter(valid_603955, JString, required = false,
                                 default = newJString("Scheduled"))
  if valid_603955 != nil:
    section.add "Status", valid_603955
  var valid_603956 = formData.getOrDefault("EnvironmentId")
  valid_603956 = validateParameter(valid_603956, JString, required = false,
                                 default = nil)
  if valid_603956 != nil:
    section.add "EnvironmentId", valid_603956
  var valid_603957 = formData.getOrDefault("EnvironmentName")
  valid_603957 = validateParameter(valid_603957, JString, required = false,
                                 default = nil)
  if valid_603957 != nil:
    section.add "EnvironmentName", valid_603957
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603958: Call_PostDescribeEnvironmentManagedActions_603943;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists an environment's upcoming and in-progress managed actions.
  ## 
  let valid = call_603958.validator(path, query, header, formData, body)
  let scheme = call_603958.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603958.url(scheme.get, call_603958.host, call_603958.base,
                         call_603958.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603958, url, valid)

proc call*(call_603959: Call_PostDescribeEnvironmentManagedActions_603943;
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
  var query_603960 = newJObject()
  var formData_603961 = newJObject()
  add(formData_603961, "Status", newJString(Status))
  add(formData_603961, "EnvironmentId", newJString(EnvironmentId))
  add(formData_603961, "EnvironmentName", newJString(EnvironmentName))
  add(query_603960, "Action", newJString(Action))
  add(query_603960, "Version", newJString(Version))
  result = call_603959.call(nil, query_603960, nil, formData_603961, nil)

var postDescribeEnvironmentManagedActions* = Call_PostDescribeEnvironmentManagedActions_603943(
    name: "postDescribeEnvironmentManagedActions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActions",
    validator: validate_PostDescribeEnvironmentManagedActions_603944, base: "/",
    url: url_PostDescribeEnvironmentManagedActions_603945,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentManagedActions_603925 = ref object of OpenApiRestCall_602467
proc url_GetDescribeEnvironmentManagedActions_603927(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEnvironmentManagedActions_603926(path: JsonNode;
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
  ##   EnvironmentId: JString
  ##                : The environment ID of the target environment.
  ##   Version: JString (required)
  section = newJObject()
  var valid_603928 = query.getOrDefault("Status")
  valid_603928 = validateParameter(valid_603928, JString, required = false,
                                 default = newJString("Scheduled"))
  if valid_603928 != nil:
    section.add "Status", valid_603928
  var valid_603929 = query.getOrDefault("EnvironmentName")
  valid_603929 = validateParameter(valid_603929, JString, required = false,
                                 default = nil)
  if valid_603929 != nil:
    section.add "EnvironmentName", valid_603929
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603930 = query.getOrDefault("Action")
  valid_603930 = validateParameter(valid_603930, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActions"))
  if valid_603930 != nil:
    section.add "Action", valid_603930
  var valid_603931 = query.getOrDefault("EnvironmentId")
  valid_603931 = validateParameter(valid_603931, JString, required = false,
                                 default = nil)
  if valid_603931 != nil:
    section.add "EnvironmentId", valid_603931
  var valid_603932 = query.getOrDefault("Version")
  valid_603932 = validateParameter(valid_603932, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603932 != nil:
    section.add "Version", valid_603932
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
  var valid_603933 = header.getOrDefault("X-Amz-Date")
  valid_603933 = validateParameter(valid_603933, JString, required = false,
                                 default = nil)
  if valid_603933 != nil:
    section.add "X-Amz-Date", valid_603933
  var valid_603934 = header.getOrDefault("X-Amz-Security-Token")
  valid_603934 = validateParameter(valid_603934, JString, required = false,
                                 default = nil)
  if valid_603934 != nil:
    section.add "X-Amz-Security-Token", valid_603934
  var valid_603935 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603935 = validateParameter(valid_603935, JString, required = false,
                                 default = nil)
  if valid_603935 != nil:
    section.add "X-Amz-Content-Sha256", valid_603935
  var valid_603936 = header.getOrDefault("X-Amz-Algorithm")
  valid_603936 = validateParameter(valid_603936, JString, required = false,
                                 default = nil)
  if valid_603936 != nil:
    section.add "X-Amz-Algorithm", valid_603936
  var valid_603937 = header.getOrDefault("X-Amz-Signature")
  valid_603937 = validateParameter(valid_603937, JString, required = false,
                                 default = nil)
  if valid_603937 != nil:
    section.add "X-Amz-Signature", valid_603937
  var valid_603938 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603938 = validateParameter(valid_603938, JString, required = false,
                                 default = nil)
  if valid_603938 != nil:
    section.add "X-Amz-SignedHeaders", valid_603938
  var valid_603939 = header.getOrDefault("X-Amz-Credential")
  valid_603939 = validateParameter(valid_603939, JString, required = false,
                                 default = nil)
  if valid_603939 != nil:
    section.add "X-Amz-Credential", valid_603939
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603940: Call_GetDescribeEnvironmentManagedActions_603925;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists an environment's upcoming and in-progress managed actions.
  ## 
  let valid = call_603940.validator(path, query, header, formData, body)
  let scheme = call_603940.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603940.url(scheme.get, call_603940.host, call_603940.base,
                         call_603940.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603940, url, valid)

proc call*(call_603941: Call_GetDescribeEnvironmentManagedActions_603925;
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
  var query_603942 = newJObject()
  add(query_603942, "Status", newJString(Status))
  add(query_603942, "EnvironmentName", newJString(EnvironmentName))
  add(query_603942, "Action", newJString(Action))
  add(query_603942, "EnvironmentId", newJString(EnvironmentId))
  add(query_603942, "Version", newJString(Version))
  result = call_603941.call(nil, query_603942, nil, nil, nil)

var getDescribeEnvironmentManagedActions* = Call_GetDescribeEnvironmentManagedActions_603925(
    name: "getDescribeEnvironmentManagedActions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActions",
    validator: validate_GetDescribeEnvironmentManagedActions_603926, base: "/",
    url: url_GetDescribeEnvironmentManagedActions_603927,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentResources_603979 = ref object of OpenApiRestCall_602467
proc url_PostDescribeEnvironmentResources_603981(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEnvironmentResources_603980(path: JsonNode;
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
  var valid_603982 = query.getOrDefault("Action")
  valid_603982 = validateParameter(valid_603982, JString, required = true, default = newJString(
      "DescribeEnvironmentResources"))
  if valid_603982 != nil:
    section.add "Action", valid_603982
  var valid_603983 = query.getOrDefault("Version")
  valid_603983 = validateParameter(valid_603983, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603983 != nil:
    section.add "Version", valid_603983
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
  var valid_603984 = header.getOrDefault("X-Amz-Date")
  valid_603984 = validateParameter(valid_603984, JString, required = false,
                                 default = nil)
  if valid_603984 != nil:
    section.add "X-Amz-Date", valid_603984
  var valid_603985 = header.getOrDefault("X-Amz-Security-Token")
  valid_603985 = validateParameter(valid_603985, JString, required = false,
                                 default = nil)
  if valid_603985 != nil:
    section.add "X-Amz-Security-Token", valid_603985
  var valid_603986 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603986 = validateParameter(valid_603986, JString, required = false,
                                 default = nil)
  if valid_603986 != nil:
    section.add "X-Amz-Content-Sha256", valid_603986
  var valid_603987 = header.getOrDefault("X-Amz-Algorithm")
  valid_603987 = validateParameter(valid_603987, JString, required = false,
                                 default = nil)
  if valid_603987 != nil:
    section.add "X-Amz-Algorithm", valid_603987
  var valid_603988 = header.getOrDefault("X-Amz-Signature")
  valid_603988 = validateParameter(valid_603988, JString, required = false,
                                 default = nil)
  if valid_603988 != nil:
    section.add "X-Amz-Signature", valid_603988
  var valid_603989 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603989 = validateParameter(valid_603989, JString, required = false,
                                 default = nil)
  if valid_603989 != nil:
    section.add "X-Amz-SignedHeaders", valid_603989
  var valid_603990 = header.getOrDefault("X-Amz-Credential")
  valid_603990 = validateParameter(valid_603990, JString, required = false,
                                 default = nil)
  if valid_603990 != nil:
    section.add "X-Amz-Credential", valid_603990
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to retrieve AWS resource usage data.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to retrieve AWS resource usage data.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_603991 = formData.getOrDefault("EnvironmentId")
  valid_603991 = validateParameter(valid_603991, JString, required = false,
                                 default = nil)
  if valid_603991 != nil:
    section.add "EnvironmentId", valid_603991
  var valid_603992 = formData.getOrDefault("EnvironmentName")
  valid_603992 = validateParameter(valid_603992, JString, required = false,
                                 default = nil)
  if valid_603992 != nil:
    section.add "EnvironmentName", valid_603992
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603993: Call_PostDescribeEnvironmentResources_603979;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns AWS resources for this environment.
  ## 
  let valid = call_603993.validator(path, query, header, formData, body)
  let scheme = call_603993.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603993.url(scheme.get, call_603993.host, call_603993.base,
                         call_603993.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603993, url, valid)

proc call*(call_603994: Call_PostDescribeEnvironmentResources_603979;
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
  var query_603995 = newJObject()
  var formData_603996 = newJObject()
  add(formData_603996, "EnvironmentId", newJString(EnvironmentId))
  add(formData_603996, "EnvironmentName", newJString(EnvironmentName))
  add(query_603995, "Action", newJString(Action))
  add(query_603995, "Version", newJString(Version))
  result = call_603994.call(nil, query_603995, nil, formData_603996, nil)

var postDescribeEnvironmentResources* = Call_PostDescribeEnvironmentResources_603979(
    name: "postDescribeEnvironmentResources", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentResources",
    validator: validate_PostDescribeEnvironmentResources_603980, base: "/",
    url: url_PostDescribeEnvironmentResources_603981,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentResources_603962 = ref object of OpenApiRestCall_602467
proc url_GetDescribeEnvironmentResources_603964(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEnvironmentResources_603963(path: JsonNode;
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
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to retrieve AWS resource usage data.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Version: JString (required)
  section = newJObject()
  var valid_603965 = query.getOrDefault("EnvironmentName")
  valid_603965 = validateParameter(valid_603965, JString, required = false,
                                 default = nil)
  if valid_603965 != nil:
    section.add "EnvironmentName", valid_603965
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603966 = query.getOrDefault("Action")
  valid_603966 = validateParameter(valid_603966, JString, required = true, default = newJString(
      "DescribeEnvironmentResources"))
  if valid_603966 != nil:
    section.add "Action", valid_603966
  var valid_603967 = query.getOrDefault("EnvironmentId")
  valid_603967 = validateParameter(valid_603967, JString, required = false,
                                 default = nil)
  if valid_603967 != nil:
    section.add "EnvironmentId", valid_603967
  var valid_603968 = query.getOrDefault("Version")
  valid_603968 = validateParameter(valid_603968, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603968 != nil:
    section.add "Version", valid_603968
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
  var valid_603969 = header.getOrDefault("X-Amz-Date")
  valid_603969 = validateParameter(valid_603969, JString, required = false,
                                 default = nil)
  if valid_603969 != nil:
    section.add "X-Amz-Date", valid_603969
  var valid_603970 = header.getOrDefault("X-Amz-Security-Token")
  valid_603970 = validateParameter(valid_603970, JString, required = false,
                                 default = nil)
  if valid_603970 != nil:
    section.add "X-Amz-Security-Token", valid_603970
  var valid_603971 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603971 = validateParameter(valid_603971, JString, required = false,
                                 default = nil)
  if valid_603971 != nil:
    section.add "X-Amz-Content-Sha256", valid_603971
  var valid_603972 = header.getOrDefault("X-Amz-Algorithm")
  valid_603972 = validateParameter(valid_603972, JString, required = false,
                                 default = nil)
  if valid_603972 != nil:
    section.add "X-Amz-Algorithm", valid_603972
  var valid_603973 = header.getOrDefault("X-Amz-Signature")
  valid_603973 = validateParameter(valid_603973, JString, required = false,
                                 default = nil)
  if valid_603973 != nil:
    section.add "X-Amz-Signature", valid_603973
  var valid_603974 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603974 = validateParameter(valid_603974, JString, required = false,
                                 default = nil)
  if valid_603974 != nil:
    section.add "X-Amz-SignedHeaders", valid_603974
  var valid_603975 = header.getOrDefault("X-Amz-Credential")
  valid_603975 = validateParameter(valid_603975, JString, required = false,
                                 default = nil)
  if valid_603975 != nil:
    section.add "X-Amz-Credential", valid_603975
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603976: Call_GetDescribeEnvironmentResources_603962;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns AWS resources for this environment.
  ## 
  let valid = call_603976.validator(path, query, header, formData, body)
  let scheme = call_603976.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603976.url(scheme.get, call_603976.host, call_603976.base,
                         call_603976.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603976, url, valid)

proc call*(call_603977: Call_GetDescribeEnvironmentResources_603962;
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
  var query_603978 = newJObject()
  add(query_603978, "EnvironmentName", newJString(EnvironmentName))
  add(query_603978, "Action", newJString(Action))
  add(query_603978, "EnvironmentId", newJString(EnvironmentId))
  add(query_603978, "Version", newJString(Version))
  result = call_603977.call(nil, query_603978, nil, nil, nil)

var getDescribeEnvironmentResources* = Call_GetDescribeEnvironmentResources_603962(
    name: "getDescribeEnvironmentResources", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentResources",
    validator: validate_GetDescribeEnvironmentResources_603963, base: "/",
    url: url_GetDescribeEnvironmentResources_603964,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironments_604020 = ref object of OpenApiRestCall_602467
proc url_PostDescribeEnvironments_604022(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEnvironments_604021(path: JsonNode; query: JsonNode;
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
  var valid_604023 = query.getOrDefault("Action")
  valid_604023 = validateParameter(valid_604023, JString, required = true,
                                 default = newJString("DescribeEnvironments"))
  if valid_604023 != nil:
    section.add "Action", valid_604023
  var valid_604024 = query.getOrDefault("Version")
  valid_604024 = validateParameter(valid_604024, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604024 != nil:
    section.add "Version", valid_604024
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
  var valid_604025 = header.getOrDefault("X-Amz-Date")
  valid_604025 = validateParameter(valid_604025, JString, required = false,
                                 default = nil)
  if valid_604025 != nil:
    section.add "X-Amz-Date", valid_604025
  var valid_604026 = header.getOrDefault("X-Amz-Security-Token")
  valid_604026 = validateParameter(valid_604026, JString, required = false,
                                 default = nil)
  if valid_604026 != nil:
    section.add "X-Amz-Security-Token", valid_604026
  var valid_604027 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604027 = validateParameter(valid_604027, JString, required = false,
                                 default = nil)
  if valid_604027 != nil:
    section.add "X-Amz-Content-Sha256", valid_604027
  var valid_604028 = header.getOrDefault("X-Amz-Algorithm")
  valid_604028 = validateParameter(valid_604028, JString, required = false,
                                 default = nil)
  if valid_604028 != nil:
    section.add "X-Amz-Algorithm", valid_604028
  var valid_604029 = header.getOrDefault("X-Amz-Signature")
  valid_604029 = validateParameter(valid_604029, JString, required = false,
                                 default = nil)
  if valid_604029 != nil:
    section.add "X-Amz-Signature", valid_604029
  var valid_604030 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604030 = validateParameter(valid_604030, JString, required = false,
                                 default = nil)
  if valid_604030 != nil:
    section.add "X-Amz-SignedHeaders", valid_604030
  var valid_604031 = header.getOrDefault("X-Amz-Credential")
  valid_604031 = validateParameter(valid_604031, JString, required = false,
                                 default = nil)
  if valid_604031 != nil:
    section.add "X-Amz-Credential", valid_604031
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
  var valid_604032 = formData.getOrDefault("NextToken")
  valid_604032 = validateParameter(valid_604032, JString, required = false,
                                 default = nil)
  if valid_604032 != nil:
    section.add "NextToken", valid_604032
  var valid_604033 = formData.getOrDefault("VersionLabel")
  valid_604033 = validateParameter(valid_604033, JString, required = false,
                                 default = nil)
  if valid_604033 != nil:
    section.add "VersionLabel", valid_604033
  var valid_604034 = formData.getOrDefault("EnvironmentNames")
  valid_604034 = validateParameter(valid_604034, JArray, required = false,
                                 default = nil)
  if valid_604034 != nil:
    section.add "EnvironmentNames", valid_604034
  var valid_604035 = formData.getOrDefault("IncludedDeletedBackTo")
  valid_604035 = validateParameter(valid_604035, JString, required = false,
                                 default = nil)
  if valid_604035 != nil:
    section.add "IncludedDeletedBackTo", valid_604035
  var valid_604036 = formData.getOrDefault("ApplicationName")
  valid_604036 = validateParameter(valid_604036, JString, required = false,
                                 default = nil)
  if valid_604036 != nil:
    section.add "ApplicationName", valid_604036
  var valid_604037 = formData.getOrDefault("EnvironmentIds")
  valid_604037 = validateParameter(valid_604037, JArray, required = false,
                                 default = nil)
  if valid_604037 != nil:
    section.add "EnvironmentIds", valid_604037
  var valid_604038 = formData.getOrDefault("IncludeDeleted")
  valid_604038 = validateParameter(valid_604038, JBool, required = false, default = nil)
  if valid_604038 != nil:
    section.add "IncludeDeleted", valid_604038
  var valid_604039 = formData.getOrDefault("MaxRecords")
  valid_604039 = validateParameter(valid_604039, JInt, required = false, default = nil)
  if valid_604039 != nil:
    section.add "MaxRecords", valid_604039
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604040: Call_PostDescribeEnvironments_604020; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns descriptions for existing environments.
  ## 
  let valid = call_604040.validator(path, query, header, formData, body)
  let scheme = call_604040.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604040.url(scheme.get, call_604040.host, call_604040.base,
                         call_604040.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604040, url, valid)

proc call*(call_604041: Call_PostDescribeEnvironments_604020;
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
  var query_604042 = newJObject()
  var formData_604043 = newJObject()
  add(formData_604043, "NextToken", newJString(NextToken))
  add(formData_604043, "VersionLabel", newJString(VersionLabel))
  if EnvironmentNames != nil:
    formData_604043.add "EnvironmentNames", EnvironmentNames
  add(formData_604043, "IncludedDeletedBackTo", newJString(IncludedDeletedBackTo))
  add(query_604042, "Action", newJString(Action))
  add(formData_604043, "ApplicationName", newJString(ApplicationName))
  if EnvironmentIds != nil:
    formData_604043.add "EnvironmentIds", EnvironmentIds
  add(formData_604043, "IncludeDeleted", newJBool(IncludeDeleted))
  add(formData_604043, "MaxRecords", newJInt(MaxRecords))
  add(query_604042, "Version", newJString(Version))
  result = call_604041.call(nil, query_604042, nil, formData_604043, nil)

var postDescribeEnvironments* = Call_PostDescribeEnvironments_604020(
    name: "postDescribeEnvironments", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironments",
    validator: validate_PostDescribeEnvironments_604021, base: "/",
    url: url_PostDescribeEnvironments_604022, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironments_603997 = ref object of OpenApiRestCall_602467
proc url_GetDescribeEnvironments_603999(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEnvironments_603998(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_604000 = query.getOrDefault("VersionLabel")
  valid_604000 = validateParameter(valid_604000, JString, required = false,
                                 default = nil)
  if valid_604000 != nil:
    section.add "VersionLabel", valid_604000
  var valid_604001 = query.getOrDefault("MaxRecords")
  valid_604001 = validateParameter(valid_604001, JInt, required = false, default = nil)
  if valid_604001 != nil:
    section.add "MaxRecords", valid_604001
  var valid_604002 = query.getOrDefault("ApplicationName")
  valid_604002 = validateParameter(valid_604002, JString, required = false,
                                 default = nil)
  if valid_604002 != nil:
    section.add "ApplicationName", valid_604002
  var valid_604003 = query.getOrDefault("IncludeDeleted")
  valid_604003 = validateParameter(valid_604003, JBool, required = false, default = nil)
  if valid_604003 != nil:
    section.add "IncludeDeleted", valid_604003
  var valid_604004 = query.getOrDefault("NextToken")
  valid_604004 = validateParameter(valid_604004, JString, required = false,
                                 default = nil)
  if valid_604004 != nil:
    section.add "NextToken", valid_604004
  var valid_604005 = query.getOrDefault("EnvironmentIds")
  valid_604005 = validateParameter(valid_604005, JArray, required = false,
                                 default = nil)
  if valid_604005 != nil:
    section.add "EnvironmentIds", valid_604005
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604006 = query.getOrDefault("Action")
  valid_604006 = validateParameter(valid_604006, JString, required = true,
                                 default = newJString("DescribeEnvironments"))
  if valid_604006 != nil:
    section.add "Action", valid_604006
  var valid_604007 = query.getOrDefault("IncludedDeletedBackTo")
  valid_604007 = validateParameter(valid_604007, JString, required = false,
                                 default = nil)
  if valid_604007 != nil:
    section.add "IncludedDeletedBackTo", valid_604007
  var valid_604008 = query.getOrDefault("EnvironmentNames")
  valid_604008 = validateParameter(valid_604008, JArray, required = false,
                                 default = nil)
  if valid_604008 != nil:
    section.add "EnvironmentNames", valid_604008
  var valid_604009 = query.getOrDefault("Version")
  valid_604009 = validateParameter(valid_604009, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604009 != nil:
    section.add "Version", valid_604009
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
  var valid_604010 = header.getOrDefault("X-Amz-Date")
  valid_604010 = validateParameter(valid_604010, JString, required = false,
                                 default = nil)
  if valid_604010 != nil:
    section.add "X-Amz-Date", valid_604010
  var valid_604011 = header.getOrDefault("X-Amz-Security-Token")
  valid_604011 = validateParameter(valid_604011, JString, required = false,
                                 default = nil)
  if valid_604011 != nil:
    section.add "X-Amz-Security-Token", valid_604011
  var valid_604012 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604012 = validateParameter(valid_604012, JString, required = false,
                                 default = nil)
  if valid_604012 != nil:
    section.add "X-Amz-Content-Sha256", valid_604012
  var valid_604013 = header.getOrDefault("X-Amz-Algorithm")
  valid_604013 = validateParameter(valid_604013, JString, required = false,
                                 default = nil)
  if valid_604013 != nil:
    section.add "X-Amz-Algorithm", valid_604013
  var valid_604014 = header.getOrDefault("X-Amz-Signature")
  valid_604014 = validateParameter(valid_604014, JString, required = false,
                                 default = nil)
  if valid_604014 != nil:
    section.add "X-Amz-Signature", valid_604014
  var valid_604015 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604015 = validateParameter(valid_604015, JString, required = false,
                                 default = nil)
  if valid_604015 != nil:
    section.add "X-Amz-SignedHeaders", valid_604015
  var valid_604016 = header.getOrDefault("X-Amz-Credential")
  valid_604016 = validateParameter(valid_604016, JString, required = false,
                                 default = nil)
  if valid_604016 != nil:
    section.add "X-Amz-Credential", valid_604016
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604017: Call_GetDescribeEnvironments_603997; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns descriptions for existing environments.
  ## 
  let valid = call_604017.validator(path, query, header, formData, body)
  let scheme = call_604017.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604017.url(scheme.get, call_604017.host, call_604017.base,
                         call_604017.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604017, url, valid)

proc call*(call_604018: Call_GetDescribeEnvironments_603997;
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
  var query_604019 = newJObject()
  add(query_604019, "VersionLabel", newJString(VersionLabel))
  add(query_604019, "MaxRecords", newJInt(MaxRecords))
  add(query_604019, "ApplicationName", newJString(ApplicationName))
  add(query_604019, "IncludeDeleted", newJBool(IncludeDeleted))
  add(query_604019, "NextToken", newJString(NextToken))
  if EnvironmentIds != nil:
    query_604019.add "EnvironmentIds", EnvironmentIds
  add(query_604019, "Action", newJString(Action))
  add(query_604019, "IncludedDeletedBackTo", newJString(IncludedDeletedBackTo))
  if EnvironmentNames != nil:
    query_604019.add "EnvironmentNames", EnvironmentNames
  add(query_604019, "Version", newJString(Version))
  result = call_604018.call(nil, query_604019, nil, nil, nil)

var getDescribeEnvironments* = Call_GetDescribeEnvironments_603997(
    name: "getDescribeEnvironments", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironments",
    validator: validate_GetDescribeEnvironments_603998, base: "/",
    url: url_GetDescribeEnvironments_603999, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_604071 = ref object of OpenApiRestCall_602467
proc url_PostDescribeEvents_604073(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEvents_604072(path: JsonNode; query: JsonNode;
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
  var valid_604074 = query.getOrDefault("Action")
  valid_604074 = validateParameter(valid_604074, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_604074 != nil:
    section.add "Action", valid_604074
  var valid_604075 = query.getOrDefault("Version")
  valid_604075 = validateParameter(valid_604075, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604075 != nil:
    section.add "Version", valid_604075
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
  var valid_604076 = header.getOrDefault("X-Amz-Date")
  valid_604076 = validateParameter(valid_604076, JString, required = false,
                                 default = nil)
  if valid_604076 != nil:
    section.add "X-Amz-Date", valid_604076
  var valid_604077 = header.getOrDefault("X-Amz-Security-Token")
  valid_604077 = validateParameter(valid_604077, JString, required = false,
                                 default = nil)
  if valid_604077 != nil:
    section.add "X-Amz-Security-Token", valid_604077
  var valid_604078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604078 = validateParameter(valid_604078, JString, required = false,
                                 default = nil)
  if valid_604078 != nil:
    section.add "X-Amz-Content-Sha256", valid_604078
  var valid_604079 = header.getOrDefault("X-Amz-Algorithm")
  valid_604079 = validateParameter(valid_604079, JString, required = false,
                                 default = nil)
  if valid_604079 != nil:
    section.add "X-Amz-Algorithm", valid_604079
  var valid_604080 = header.getOrDefault("X-Amz-Signature")
  valid_604080 = validateParameter(valid_604080, JString, required = false,
                                 default = nil)
  if valid_604080 != nil:
    section.add "X-Amz-Signature", valid_604080
  var valid_604081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604081 = validateParameter(valid_604081, JString, required = false,
                                 default = nil)
  if valid_604081 != nil:
    section.add "X-Amz-SignedHeaders", valid_604081
  var valid_604082 = header.getOrDefault("X-Amz-Credential")
  valid_604082 = validateParameter(valid_604082, JString, required = false,
                                 default = nil)
  if valid_604082 != nil:
    section.add "X-Amz-Credential", valid_604082
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
  var valid_604083 = formData.getOrDefault("NextToken")
  valid_604083 = validateParameter(valid_604083, JString, required = false,
                                 default = nil)
  if valid_604083 != nil:
    section.add "NextToken", valid_604083
  var valid_604084 = formData.getOrDefault("VersionLabel")
  valid_604084 = validateParameter(valid_604084, JString, required = false,
                                 default = nil)
  if valid_604084 != nil:
    section.add "VersionLabel", valid_604084
  var valid_604085 = formData.getOrDefault("Severity")
  valid_604085 = validateParameter(valid_604085, JString, required = false,
                                 default = newJString("TRACE"))
  if valid_604085 != nil:
    section.add "Severity", valid_604085
  var valid_604086 = formData.getOrDefault("EnvironmentId")
  valid_604086 = validateParameter(valid_604086, JString, required = false,
                                 default = nil)
  if valid_604086 != nil:
    section.add "EnvironmentId", valid_604086
  var valid_604087 = formData.getOrDefault("EnvironmentName")
  valid_604087 = validateParameter(valid_604087, JString, required = false,
                                 default = nil)
  if valid_604087 != nil:
    section.add "EnvironmentName", valid_604087
  var valid_604088 = formData.getOrDefault("StartTime")
  valid_604088 = validateParameter(valid_604088, JString, required = false,
                                 default = nil)
  if valid_604088 != nil:
    section.add "StartTime", valid_604088
  var valid_604089 = formData.getOrDefault("ApplicationName")
  valid_604089 = validateParameter(valid_604089, JString, required = false,
                                 default = nil)
  if valid_604089 != nil:
    section.add "ApplicationName", valid_604089
  var valid_604090 = formData.getOrDefault("EndTime")
  valid_604090 = validateParameter(valid_604090, JString, required = false,
                                 default = nil)
  if valid_604090 != nil:
    section.add "EndTime", valid_604090
  var valid_604091 = formData.getOrDefault("PlatformArn")
  valid_604091 = validateParameter(valid_604091, JString, required = false,
                                 default = nil)
  if valid_604091 != nil:
    section.add "PlatformArn", valid_604091
  var valid_604092 = formData.getOrDefault("MaxRecords")
  valid_604092 = validateParameter(valid_604092, JInt, required = false, default = nil)
  if valid_604092 != nil:
    section.add "MaxRecords", valid_604092
  var valid_604093 = formData.getOrDefault("RequestId")
  valid_604093 = validateParameter(valid_604093, JString, required = false,
                                 default = nil)
  if valid_604093 != nil:
    section.add "RequestId", valid_604093
  var valid_604094 = formData.getOrDefault("TemplateName")
  valid_604094 = validateParameter(valid_604094, JString, required = false,
                                 default = nil)
  if valid_604094 != nil:
    section.add "TemplateName", valid_604094
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604095: Call_PostDescribeEvents_604071; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns list of event descriptions matching criteria up to the last 6 weeks.</p> <note> <p>This action returns the most recent 1,000 events from the specified <code>NextToken</code>.</p> </note>
  ## 
  let valid = call_604095.validator(path, query, header, formData, body)
  let scheme = call_604095.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604095.url(scheme.get, call_604095.host, call_604095.base,
                         call_604095.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604095, url, valid)

proc call*(call_604096: Call_PostDescribeEvents_604071; NextToken: string = "";
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
  var query_604097 = newJObject()
  var formData_604098 = newJObject()
  add(formData_604098, "NextToken", newJString(NextToken))
  add(formData_604098, "VersionLabel", newJString(VersionLabel))
  add(formData_604098, "Severity", newJString(Severity))
  add(formData_604098, "EnvironmentId", newJString(EnvironmentId))
  add(formData_604098, "EnvironmentName", newJString(EnvironmentName))
  add(formData_604098, "StartTime", newJString(StartTime))
  add(query_604097, "Action", newJString(Action))
  add(formData_604098, "ApplicationName", newJString(ApplicationName))
  add(formData_604098, "EndTime", newJString(EndTime))
  add(formData_604098, "PlatformArn", newJString(PlatformArn))
  add(formData_604098, "MaxRecords", newJInt(MaxRecords))
  add(formData_604098, "RequestId", newJString(RequestId))
  add(formData_604098, "TemplateName", newJString(TemplateName))
  add(query_604097, "Version", newJString(Version))
  result = call_604096.call(nil, query_604097, nil, formData_604098, nil)

var postDescribeEvents* = Call_PostDescribeEvents_604071(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_604072, base: "/",
    url: url_PostDescribeEvents_604073, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_604044 = ref object of OpenApiRestCall_602467
proc url_GetDescribeEvents_604046(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEvents_604045(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_604047 = query.getOrDefault("VersionLabel")
  valid_604047 = validateParameter(valid_604047, JString, required = false,
                                 default = nil)
  if valid_604047 != nil:
    section.add "VersionLabel", valid_604047
  var valid_604048 = query.getOrDefault("MaxRecords")
  valid_604048 = validateParameter(valid_604048, JInt, required = false, default = nil)
  if valid_604048 != nil:
    section.add "MaxRecords", valid_604048
  var valid_604049 = query.getOrDefault("ApplicationName")
  valid_604049 = validateParameter(valid_604049, JString, required = false,
                                 default = nil)
  if valid_604049 != nil:
    section.add "ApplicationName", valid_604049
  var valid_604050 = query.getOrDefault("StartTime")
  valid_604050 = validateParameter(valid_604050, JString, required = false,
                                 default = nil)
  if valid_604050 != nil:
    section.add "StartTime", valid_604050
  var valid_604051 = query.getOrDefault("PlatformArn")
  valid_604051 = validateParameter(valid_604051, JString, required = false,
                                 default = nil)
  if valid_604051 != nil:
    section.add "PlatformArn", valid_604051
  var valid_604052 = query.getOrDefault("NextToken")
  valid_604052 = validateParameter(valid_604052, JString, required = false,
                                 default = nil)
  if valid_604052 != nil:
    section.add "NextToken", valid_604052
  var valid_604053 = query.getOrDefault("EnvironmentName")
  valid_604053 = validateParameter(valid_604053, JString, required = false,
                                 default = nil)
  if valid_604053 != nil:
    section.add "EnvironmentName", valid_604053
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604054 = query.getOrDefault("Action")
  valid_604054 = validateParameter(valid_604054, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_604054 != nil:
    section.add "Action", valid_604054
  var valid_604055 = query.getOrDefault("EnvironmentId")
  valid_604055 = validateParameter(valid_604055, JString, required = false,
                                 default = nil)
  if valid_604055 != nil:
    section.add "EnvironmentId", valid_604055
  var valid_604056 = query.getOrDefault("TemplateName")
  valid_604056 = validateParameter(valid_604056, JString, required = false,
                                 default = nil)
  if valid_604056 != nil:
    section.add "TemplateName", valid_604056
  var valid_604057 = query.getOrDefault("Severity")
  valid_604057 = validateParameter(valid_604057, JString, required = false,
                                 default = newJString("TRACE"))
  if valid_604057 != nil:
    section.add "Severity", valid_604057
  var valid_604058 = query.getOrDefault("RequestId")
  valid_604058 = validateParameter(valid_604058, JString, required = false,
                                 default = nil)
  if valid_604058 != nil:
    section.add "RequestId", valid_604058
  var valid_604059 = query.getOrDefault("EndTime")
  valid_604059 = validateParameter(valid_604059, JString, required = false,
                                 default = nil)
  if valid_604059 != nil:
    section.add "EndTime", valid_604059
  var valid_604060 = query.getOrDefault("Version")
  valid_604060 = validateParameter(valid_604060, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604060 != nil:
    section.add "Version", valid_604060
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
  var valid_604061 = header.getOrDefault("X-Amz-Date")
  valid_604061 = validateParameter(valid_604061, JString, required = false,
                                 default = nil)
  if valid_604061 != nil:
    section.add "X-Amz-Date", valid_604061
  var valid_604062 = header.getOrDefault("X-Amz-Security-Token")
  valid_604062 = validateParameter(valid_604062, JString, required = false,
                                 default = nil)
  if valid_604062 != nil:
    section.add "X-Amz-Security-Token", valid_604062
  var valid_604063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604063 = validateParameter(valid_604063, JString, required = false,
                                 default = nil)
  if valid_604063 != nil:
    section.add "X-Amz-Content-Sha256", valid_604063
  var valid_604064 = header.getOrDefault("X-Amz-Algorithm")
  valid_604064 = validateParameter(valid_604064, JString, required = false,
                                 default = nil)
  if valid_604064 != nil:
    section.add "X-Amz-Algorithm", valid_604064
  var valid_604065 = header.getOrDefault("X-Amz-Signature")
  valid_604065 = validateParameter(valid_604065, JString, required = false,
                                 default = nil)
  if valid_604065 != nil:
    section.add "X-Amz-Signature", valid_604065
  var valid_604066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604066 = validateParameter(valid_604066, JString, required = false,
                                 default = nil)
  if valid_604066 != nil:
    section.add "X-Amz-SignedHeaders", valid_604066
  var valid_604067 = header.getOrDefault("X-Amz-Credential")
  valid_604067 = validateParameter(valid_604067, JString, required = false,
                                 default = nil)
  if valid_604067 != nil:
    section.add "X-Amz-Credential", valid_604067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604068: Call_GetDescribeEvents_604044; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns list of event descriptions matching criteria up to the last 6 weeks.</p> <note> <p>This action returns the most recent 1,000 events from the specified <code>NextToken</code>.</p> </note>
  ## 
  let valid = call_604068.validator(path, query, header, formData, body)
  let scheme = call_604068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604068.url(scheme.get, call_604068.host, call_604068.base,
                         call_604068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604068, url, valid)

proc call*(call_604069: Call_GetDescribeEvents_604044; VersionLabel: string = "";
          MaxRecords: int = 0; ApplicationName: string = ""; StartTime: string = "";
          PlatformArn: string = ""; NextToken: string = "";
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
  var query_604070 = newJObject()
  add(query_604070, "VersionLabel", newJString(VersionLabel))
  add(query_604070, "MaxRecords", newJInt(MaxRecords))
  add(query_604070, "ApplicationName", newJString(ApplicationName))
  add(query_604070, "StartTime", newJString(StartTime))
  add(query_604070, "PlatformArn", newJString(PlatformArn))
  add(query_604070, "NextToken", newJString(NextToken))
  add(query_604070, "EnvironmentName", newJString(EnvironmentName))
  add(query_604070, "Action", newJString(Action))
  add(query_604070, "EnvironmentId", newJString(EnvironmentId))
  add(query_604070, "TemplateName", newJString(TemplateName))
  add(query_604070, "Severity", newJString(Severity))
  add(query_604070, "RequestId", newJString(RequestId))
  add(query_604070, "EndTime", newJString(EndTime))
  add(query_604070, "Version", newJString(Version))
  result = call_604069.call(nil, query_604070, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_604044(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_604045,
    base: "/", url: url_GetDescribeEvents_604046,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeInstancesHealth_604118 = ref object of OpenApiRestCall_602467
proc url_PostDescribeInstancesHealth_604120(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeInstancesHealth_604119(path: JsonNode; query: JsonNode;
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
  var valid_604121 = query.getOrDefault("Action")
  valid_604121 = validateParameter(valid_604121, JString, required = true, default = newJString(
      "DescribeInstancesHealth"))
  if valid_604121 != nil:
    section.add "Action", valid_604121
  var valid_604122 = query.getOrDefault("Version")
  valid_604122 = validateParameter(valid_604122, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604122 != nil:
    section.add "Version", valid_604122
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
  var valid_604123 = header.getOrDefault("X-Amz-Date")
  valid_604123 = validateParameter(valid_604123, JString, required = false,
                                 default = nil)
  if valid_604123 != nil:
    section.add "X-Amz-Date", valid_604123
  var valid_604124 = header.getOrDefault("X-Amz-Security-Token")
  valid_604124 = validateParameter(valid_604124, JString, required = false,
                                 default = nil)
  if valid_604124 != nil:
    section.add "X-Amz-Security-Token", valid_604124
  var valid_604125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604125 = validateParameter(valid_604125, JString, required = false,
                                 default = nil)
  if valid_604125 != nil:
    section.add "X-Amz-Content-Sha256", valid_604125
  var valid_604126 = header.getOrDefault("X-Amz-Algorithm")
  valid_604126 = validateParameter(valid_604126, JString, required = false,
                                 default = nil)
  if valid_604126 != nil:
    section.add "X-Amz-Algorithm", valid_604126
  var valid_604127 = header.getOrDefault("X-Amz-Signature")
  valid_604127 = validateParameter(valid_604127, JString, required = false,
                                 default = nil)
  if valid_604127 != nil:
    section.add "X-Amz-Signature", valid_604127
  var valid_604128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604128 = validateParameter(valid_604128, JString, required = false,
                                 default = nil)
  if valid_604128 != nil:
    section.add "X-Amz-SignedHeaders", valid_604128
  var valid_604129 = header.getOrDefault("X-Amz-Credential")
  valid_604129 = validateParameter(valid_604129, JString, required = false,
                                 default = nil)
  if valid_604129 != nil:
    section.add "X-Amz-Credential", valid_604129
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
  var valid_604130 = formData.getOrDefault("NextToken")
  valid_604130 = validateParameter(valid_604130, JString, required = false,
                                 default = nil)
  if valid_604130 != nil:
    section.add "NextToken", valid_604130
  var valid_604131 = formData.getOrDefault("EnvironmentId")
  valid_604131 = validateParameter(valid_604131, JString, required = false,
                                 default = nil)
  if valid_604131 != nil:
    section.add "EnvironmentId", valid_604131
  var valid_604132 = formData.getOrDefault("EnvironmentName")
  valid_604132 = validateParameter(valid_604132, JString, required = false,
                                 default = nil)
  if valid_604132 != nil:
    section.add "EnvironmentName", valid_604132
  var valid_604133 = formData.getOrDefault("AttributeNames")
  valid_604133 = validateParameter(valid_604133, JArray, required = false,
                                 default = nil)
  if valid_604133 != nil:
    section.add "AttributeNames", valid_604133
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604134: Call_PostDescribeInstancesHealth_604118; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves detailed information about the health of instances in your AWS Elastic Beanstalk. This operation requires <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/health-enhanced.html">enhanced health reporting</a>.
  ## 
  let valid = call_604134.validator(path, query, header, formData, body)
  let scheme = call_604134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604134.url(scheme.get, call_604134.host, call_604134.base,
                         call_604134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604134, url, valid)

proc call*(call_604135: Call_PostDescribeInstancesHealth_604118;
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
  var query_604136 = newJObject()
  var formData_604137 = newJObject()
  add(formData_604137, "NextToken", newJString(NextToken))
  add(formData_604137, "EnvironmentId", newJString(EnvironmentId))
  add(formData_604137, "EnvironmentName", newJString(EnvironmentName))
  add(query_604136, "Action", newJString(Action))
  if AttributeNames != nil:
    formData_604137.add "AttributeNames", AttributeNames
  add(query_604136, "Version", newJString(Version))
  result = call_604135.call(nil, query_604136, nil, formData_604137, nil)

var postDescribeInstancesHealth* = Call_PostDescribeInstancesHealth_604118(
    name: "postDescribeInstancesHealth", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeInstancesHealth",
    validator: validate_PostDescribeInstancesHealth_604119, base: "/",
    url: url_PostDescribeInstancesHealth_604120,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeInstancesHealth_604099 = ref object of OpenApiRestCall_602467
proc url_GetDescribeInstancesHealth_604101(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeInstancesHealth_604100(path: JsonNode; query: JsonNode;
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
  ##   EnvironmentId: JString
  ##                : Specify the AWS Elastic Beanstalk environment by ID.
  ##   Version: JString (required)
  section = newJObject()
  var valid_604102 = query.getOrDefault("AttributeNames")
  valid_604102 = validateParameter(valid_604102, JArray, required = false,
                                 default = nil)
  if valid_604102 != nil:
    section.add "AttributeNames", valid_604102
  var valid_604103 = query.getOrDefault("NextToken")
  valid_604103 = validateParameter(valid_604103, JString, required = false,
                                 default = nil)
  if valid_604103 != nil:
    section.add "NextToken", valid_604103
  var valid_604104 = query.getOrDefault("EnvironmentName")
  valid_604104 = validateParameter(valid_604104, JString, required = false,
                                 default = nil)
  if valid_604104 != nil:
    section.add "EnvironmentName", valid_604104
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604105 = query.getOrDefault("Action")
  valid_604105 = validateParameter(valid_604105, JString, required = true, default = newJString(
      "DescribeInstancesHealth"))
  if valid_604105 != nil:
    section.add "Action", valid_604105
  var valid_604106 = query.getOrDefault("EnvironmentId")
  valid_604106 = validateParameter(valid_604106, JString, required = false,
                                 default = nil)
  if valid_604106 != nil:
    section.add "EnvironmentId", valid_604106
  var valid_604107 = query.getOrDefault("Version")
  valid_604107 = validateParameter(valid_604107, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604107 != nil:
    section.add "Version", valid_604107
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
  var valid_604108 = header.getOrDefault("X-Amz-Date")
  valid_604108 = validateParameter(valid_604108, JString, required = false,
                                 default = nil)
  if valid_604108 != nil:
    section.add "X-Amz-Date", valid_604108
  var valid_604109 = header.getOrDefault("X-Amz-Security-Token")
  valid_604109 = validateParameter(valid_604109, JString, required = false,
                                 default = nil)
  if valid_604109 != nil:
    section.add "X-Amz-Security-Token", valid_604109
  var valid_604110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604110 = validateParameter(valid_604110, JString, required = false,
                                 default = nil)
  if valid_604110 != nil:
    section.add "X-Amz-Content-Sha256", valid_604110
  var valid_604111 = header.getOrDefault("X-Amz-Algorithm")
  valid_604111 = validateParameter(valid_604111, JString, required = false,
                                 default = nil)
  if valid_604111 != nil:
    section.add "X-Amz-Algorithm", valid_604111
  var valid_604112 = header.getOrDefault("X-Amz-Signature")
  valid_604112 = validateParameter(valid_604112, JString, required = false,
                                 default = nil)
  if valid_604112 != nil:
    section.add "X-Amz-Signature", valid_604112
  var valid_604113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604113 = validateParameter(valid_604113, JString, required = false,
                                 default = nil)
  if valid_604113 != nil:
    section.add "X-Amz-SignedHeaders", valid_604113
  var valid_604114 = header.getOrDefault("X-Amz-Credential")
  valid_604114 = validateParameter(valid_604114, JString, required = false,
                                 default = nil)
  if valid_604114 != nil:
    section.add "X-Amz-Credential", valid_604114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604115: Call_GetDescribeInstancesHealth_604099; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves detailed information about the health of instances in your AWS Elastic Beanstalk. This operation requires <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/health-enhanced.html">enhanced health reporting</a>.
  ## 
  let valid = call_604115.validator(path, query, header, formData, body)
  let scheme = call_604115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604115.url(scheme.get, call_604115.host, call_604115.base,
                         call_604115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604115, url, valid)

proc call*(call_604116: Call_GetDescribeInstancesHealth_604099;
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
  var query_604117 = newJObject()
  if AttributeNames != nil:
    query_604117.add "AttributeNames", AttributeNames
  add(query_604117, "NextToken", newJString(NextToken))
  add(query_604117, "EnvironmentName", newJString(EnvironmentName))
  add(query_604117, "Action", newJString(Action))
  add(query_604117, "EnvironmentId", newJString(EnvironmentId))
  add(query_604117, "Version", newJString(Version))
  result = call_604116.call(nil, query_604117, nil, nil, nil)

var getDescribeInstancesHealth* = Call_GetDescribeInstancesHealth_604099(
    name: "getDescribeInstancesHealth", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeInstancesHealth",
    validator: validate_GetDescribeInstancesHealth_604100, base: "/",
    url: url_GetDescribeInstancesHealth_604101,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribePlatformVersion_604154 = ref object of OpenApiRestCall_602467
proc url_PostDescribePlatformVersion_604156(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribePlatformVersion_604155(path: JsonNode; query: JsonNode;
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
  var valid_604157 = query.getOrDefault("Action")
  valid_604157 = validateParameter(valid_604157, JString, required = true, default = newJString(
      "DescribePlatformVersion"))
  if valid_604157 != nil:
    section.add "Action", valid_604157
  var valid_604158 = query.getOrDefault("Version")
  valid_604158 = validateParameter(valid_604158, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604158 != nil:
    section.add "Version", valid_604158
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
  var valid_604159 = header.getOrDefault("X-Amz-Date")
  valid_604159 = validateParameter(valid_604159, JString, required = false,
                                 default = nil)
  if valid_604159 != nil:
    section.add "X-Amz-Date", valid_604159
  var valid_604160 = header.getOrDefault("X-Amz-Security-Token")
  valid_604160 = validateParameter(valid_604160, JString, required = false,
                                 default = nil)
  if valid_604160 != nil:
    section.add "X-Amz-Security-Token", valid_604160
  var valid_604161 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604161 = validateParameter(valid_604161, JString, required = false,
                                 default = nil)
  if valid_604161 != nil:
    section.add "X-Amz-Content-Sha256", valid_604161
  var valid_604162 = header.getOrDefault("X-Amz-Algorithm")
  valid_604162 = validateParameter(valid_604162, JString, required = false,
                                 default = nil)
  if valid_604162 != nil:
    section.add "X-Amz-Algorithm", valid_604162
  var valid_604163 = header.getOrDefault("X-Amz-Signature")
  valid_604163 = validateParameter(valid_604163, JString, required = false,
                                 default = nil)
  if valid_604163 != nil:
    section.add "X-Amz-Signature", valid_604163
  var valid_604164 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604164 = validateParameter(valid_604164, JString, required = false,
                                 default = nil)
  if valid_604164 != nil:
    section.add "X-Amz-SignedHeaders", valid_604164
  var valid_604165 = header.getOrDefault("X-Amz-Credential")
  valid_604165 = validateParameter(valid_604165, JString, required = false,
                                 default = nil)
  if valid_604165 != nil:
    section.add "X-Amz-Credential", valid_604165
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformArn: JString
  ##              : The ARN of the version of the platform.
  section = newJObject()
  var valid_604166 = formData.getOrDefault("PlatformArn")
  valid_604166 = validateParameter(valid_604166, JString, required = false,
                                 default = nil)
  if valid_604166 != nil:
    section.add "PlatformArn", valid_604166
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604167: Call_PostDescribePlatformVersion_604154; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the version of the platform.
  ## 
  let valid = call_604167.validator(path, query, header, formData, body)
  let scheme = call_604167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604167.url(scheme.get, call_604167.host, call_604167.base,
                         call_604167.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604167, url, valid)

proc call*(call_604168: Call_PostDescribePlatformVersion_604154;
          Action: string = "DescribePlatformVersion"; PlatformArn: string = "";
          Version: string = "2010-12-01"): Recallable =
  ## postDescribePlatformVersion
  ## Describes the version of the platform.
  ##   Action: string (required)
  ##   PlatformArn: string
  ##              : The ARN of the version of the platform.
  ##   Version: string (required)
  var query_604169 = newJObject()
  var formData_604170 = newJObject()
  add(query_604169, "Action", newJString(Action))
  add(formData_604170, "PlatformArn", newJString(PlatformArn))
  add(query_604169, "Version", newJString(Version))
  result = call_604168.call(nil, query_604169, nil, formData_604170, nil)

var postDescribePlatformVersion* = Call_PostDescribePlatformVersion_604154(
    name: "postDescribePlatformVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribePlatformVersion",
    validator: validate_PostDescribePlatformVersion_604155, base: "/",
    url: url_PostDescribePlatformVersion_604156,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribePlatformVersion_604138 = ref object of OpenApiRestCall_602467
proc url_GetDescribePlatformVersion_604140(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribePlatformVersion_604139(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_604141 = query.getOrDefault("PlatformArn")
  valid_604141 = validateParameter(valid_604141, JString, required = false,
                                 default = nil)
  if valid_604141 != nil:
    section.add "PlatformArn", valid_604141
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604142 = query.getOrDefault("Action")
  valid_604142 = validateParameter(valid_604142, JString, required = true, default = newJString(
      "DescribePlatformVersion"))
  if valid_604142 != nil:
    section.add "Action", valid_604142
  var valid_604143 = query.getOrDefault("Version")
  valid_604143 = validateParameter(valid_604143, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604143 != nil:
    section.add "Version", valid_604143
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
  var valid_604144 = header.getOrDefault("X-Amz-Date")
  valid_604144 = validateParameter(valid_604144, JString, required = false,
                                 default = nil)
  if valid_604144 != nil:
    section.add "X-Amz-Date", valid_604144
  var valid_604145 = header.getOrDefault("X-Amz-Security-Token")
  valid_604145 = validateParameter(valid_604145, JString, required = false,
                                 default = nil)
  if valid_604145 != nil:
    section.add "X-Amz-Security-Token", valid_604145
  var valid_604146 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604146 = validateParameter(valid_604146, JString, required = false,
                                 default = nil)
  if valid_604146 != nil:
    section.add "X-Amz-Content-Sha256", valid_604146
  var valid_604147 = header.getOrDefault("X-Amz-Algorithm")
  valid_604147 = validateParameter(valid_604147, JString, required = false,
                                 default = nil)
  if valid_604147 != nil:
    section.add "X-Amz-Algorithm", valid_604147
  var valid_604148 = header.getOrDefault("X-Amz-Signature")
  valid_604148 = validateParameter(valid_604148, JString, required = false,
                                 default = nil)
  if valid_604148 != nil:
    section.add "X-Amz-Signature", valid_604148
  var valid_604149 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604149 = validateParameter(valid_604149, JString, required = false,
                                 default = nil)
  if valid_604149 != nil:
    section.add "X-Amz-SignedHeaders", valid_604149
  var valid_604150 = header.getOrDefault("X-Amz-Credential")
  valid_604150 = validateParameter(valid_604150, JString, required = false,
                                 default = nil)
  if valid_604150 != nil:
    section.add "X-Amz-Credential", valid_604150
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604151: Call_GetDescribePlatformVersion_604138; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the version of the platform.
  ## 
  let valid = call_604151.validator(path, query, header, formData, body)
  let scheme = call_604151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604151.url(scheme.get, call_604151.host, call_604151.base,
                         call_604151.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604151, url, valid)

proc call*(call_604152: Call_GetDescribePlatformVersion_604138;
          PlatformArn: string = ""; Action: string = "DescribePlatformVersion";
          Version: string = "2010-12-01"): Recallable =
  ## getDescribePlatformVersion
  ## Describes the version of the platform.
  ##   PlatformArn: string
  ##              : The ARN of the version of the platform.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604153 = newJObject()
  add(query_604153, "PlatformArn", newJString(PlatformArn))
  add(query_604153, "Action", newJString(Action))
  add(query_604153, "Version", newJString(Version))
  result = call_604152.call(nil, query_604153, nil, nil, nil)

var getDescribePlatformVersion* = Call_GetDescribePlatformVersion_604138(
    name: "getDescribePlatformVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribePlatformVersion",
    validator: validate_GetDescribePlatformVersion_604139, base: "/",
    url: url_GetDescribePlatformVersion_604140,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListAvailableSolutionStacks_604186 = ref object of OpenApiRestCall_602467
proc url_PostListAvailableSolutionStacks_604188(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListAvailableSolutionStacks_604187(path: JsonNode;
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
  var valid_604189 = query.getOrDefault("Action")
  valid_604189 = validateParameter(valid_604189, JString, required = true, default = newJString(
      "ListAvailableSolutionStacks"))
  if valid_604189 != nil:
    section.add "Action", valid_604189
  var valid_604190 = query.getOrDefault("Version")
  valid_604190 = validateParameter(valid_604190, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604190 != nil:
    section.add "Version", valid_604190
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
  var valid_604191 = header.getOrDefault("X-Amz-Date")
  valid_604191 = validateParameter(valid_604191, JString, required = false,
                                 default = nil)
  if valid_604191 != nil:
    section.add "X-Amz-Date", valid_604191
  var valid_604192 = header.getOrDefault("X-Amz-Security-Token")
  valid_604192 = validateParameter(valid_604192, JString, required = false,
                                 default = nil)
  if valid_604192 != nil:
    section.add "X-Amz-Security-Token", valid_604192
  var valid_604193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604193 = validateParameter(valid_604193, JString, required = false,
                                 default = nil)
  if valid_604193 != nil:
    section.add "X-Amz-Content-Sha256", valid_604193
  var valid_604194 = header.getOrDefault("X-Amz-Algorithm")
  valid_604194 = validateParameter(valid_604194, JString, required = false,
                                 default = nil)
  if valid_604194 != nil:
    section.add "X-Amz-Algorithm", valid_604194
  var valid_604195 = header.getOrDefault("X-Amz-Signature")
  valid_604195 = validateParameter(valid_604195, JString, required = false,
                                 default = nil)
  if valid_604195 != nil:
    section.add "X-Amz-Signature", valid_604195
  var valid_604196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604196 = validateParameter(valid_604196, JString, required = false,
                                 default = nil)
  if valid_604196 != nil:
    section.add "X-Amz-SignedHeaders", valid_604196
  var valid_604197 = header.getOrDefault("X-Amz-Credential")
  valid_604197 = validateParameter(valid_604197, JString, required = false,
                                 default = nil)
  if valid_604197 != nil:
    section.add "X-Amz-Credential", valid_604197
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604198: Call_PostListAvailableSolutionStacks_604186;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ## 
  let valid = call_604198.validator(path, query, header, formData, body)
  let scheme = call_604198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604198.url(scheme.get, call_604198.host, call_604198.base,
                         call_604198.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604198, url, valid)

proc call*(call_604199: Call_PostListAvailableSolutionStacks_604186;
          Action: string = "ListAvailableSolutionStacks";
          Version: string = "2010-12-01"): Recallable =
  ## postListAvailableSolutionStacks
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604200 = newJObject()
  add(query_604200, "Action", newJString(Action))
  add(query_604200, "Version", newJString(Version))
  result = call_604199.call(nil, query_604200, nil, nil, nil)

var postListAvailableSolutionStacks* = Call_PostListAvailableSolutionStacks_604186(
    name: "postListAvailableSolutionStacks", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListAvailableSolutionStacks",
    validator: validate_PostListAvailableSolutionStacks_604187, base: "/",
    url: url_PostListAvailableSolutionStacks_604188,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListAvailableSolutionStacks_604171 = ref object of OpenApiRestCall_602467
proc url_GetListAvailableSolutionStacks_604173(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListAvailableSolutionStacks_604172(path: JsonNode;
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
  var valid_604174 = query.getOrDefault("Action")
  valid_604174 = validateParameter(valid_604174, JString, required = true, default = newJString(
      "ListAvailableSolutionStacks"))
  if valid_604174 != nil:
    section.add "Action", valid_604174
  var valid_604175 = query.getOrDefault("Version")
  valid_604175 = validateParameter(valid_604175, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604175 != nil:
    section.add "Version", valid_604175
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
  var valid_604176 = header.getOrDefault("X-Amz-Date")
  valid_604176 = validateParameter(valid_604176, JString, required = false,
                                 default = nil)
  if valid_604176 != nil:
    section.add "X-Amz-Date", valid_604176
  var valid_604177 = header.getOrDefault("X-Amz-Security-Token")
  valid_604177 = validateParameter(valid_604177, JString, required = false,
                                 default = nil)
  if valid_604177 != nil:
    section.add "X-Amz-Security-Token", valid_604177
  var valid_604178 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604178 = validateParameter(valid_604178, JString, required = false,
                                 default = nil)
  if valid_604178 != nil:
    section.add "X-Amz-Content-Sha256", valid_604178
  var valid_604179 = header.getOrDefault("X-Amz-Algorithm")
  valid_604179 = validateParameter(valid_604179, JString, required = false,
                                 default = nil)
  if valid_604179 != nil:
    section.add "X-Amz-Algorithm", valid_604179
  var valid_604180 = header.getOrDefault("X-Amz-Signature")
  valid_604180 = validateParameter(valid_604180, JString, required = false,
                                 default = nil)
  if valid_604180 != nil:
    section.add "X-Amz-Signature", valid_604180
  var valid_604181 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604181 = validateParameter(valid_604181, JString, required = false,
                                 default = nil)
  if valid_604181 != nil:
    section.add "X-Amz-SignedHeaders", valid_604181
  var valid_604182 = header.getOrDefault("X-Amz-Credential")
  valid_604182 = validateParameter(valid_604182, JString, required = false,
                                 default = nil)
  if valid_604182 != nil:
    section.add "X-Amz-Credential", valid_604182
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604183: Call_GetListAvailableSolutionStacks_604171; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ## 
  let valid = call_604183.validator(path, query, header, formData, body)
  let scheme = call_604183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604183.url(scheme.get, call_604183.host, call_604183.base,
                         call_604183.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604183, url, valid)

proc call*(call_604184: Call_GetListAvailableSolutionStacks_604171;
          Action: string = "ListAvailableSolutionStacks";
          Version: string = "2010-12-01"): Recallable =
  ## getListAvailableSolutionStacks
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604185 = newJObject()
  add(query_604185, "Action", newJString(Action))
  add(query_604185, "Version", newJString(Version))
  result = call_604184.call(nil, query_604185, nil, nil, nil)

var getListAvailableSolutionStacks* = Call_GetListAvailableSolutionStacks_604171(
    name: "getListAvailableSolutionStacks", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListAvailableSolutionStacks",
    validator: validate_GetListAvailableSolutionStacks_604172, base: "/",
    url: url_GetListAvailableSolutionStacks_604173,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListPlatformVersions_604219 = ref object of OpenApiRestCall_602467
proc url_PostListPlatformVersions_604221(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListPlatformVersions_604220(path: JsonNode; query: JsonNode;
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
  var valid_604222 = query.getOrDefault("Action")
  valid_604222 = validateParameter(valid_604222, JString, required = true,
                                 default = newJString("ListPlatformVersions"))
  if valid_604222 != nil:
    section.add "Action", valid_604222
  var valid_604223 = query.getOrDefault("Version")
  valid_604223 = validateParameter(valid_604223, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604223 != nil:
    section.add "Version", valid_604223
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
  var valid_604224 = header.getOrDefault("X-Amz-Date")
  valid_604224 = validateParameter(valid_604224, JString, required = false,
                                 default = nil)
  if valid_604224 != nil:
    section.add "X-Amz-Date", valid_604224
  var valid_604225 = header.getOrDefault("X-Amz-Security-Token")
  valid_604225 = validateParameter(valid_604225, JString, required = false,
                                 default = nil)
  if valid_604225 != nil:
    section.add "X-Amz-Security-Token", valid_604225
  var valid_604226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604226 = validateParameter(valid_604226, JString, required = false,
                                 default = nil)
  if valid_604226 != nil:
    section.add "X-Amz-Content-Sha256", valid_604226
  var valid_604227 = header.getOrDefault("X-Amz-Algorithm")
  valid_604227 = validateParameter(valid_604227, JString, required = false,
                                 default = nil)
  if valid_604227 != nil:
    section.add "X-Amz-Algorithm", valid_604227
  var valid_604228 = header.getOrDefault("X-Amz-Signature")
  valid_604228 = validateParameter(valid_604228, JString, required = false,
                                 default = nil)
  if valid_604228 != nil:
    section.add "X-Amz-Signature", valid_604228
  var valid_604229 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604229 = validateParameter(valid_604229, JString, required = false,
                                 default = nil)
  if valid_604229 != nil:
    section.add "X-Amz-SignedHeaders", valid_604229
  var valid_604230 = header.getOrDefault("X-Amz-Credential")
  valid_604230 = validateParameter(valid_604230, JString, required = false,
                                 default = nil)
  if valid_604230 != nil:
    section.add "X-Amz-Credential", valid_604230
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : The starting index into the remaining list of platforms. Use the <code>NextToken</code> value from a previous <code>ListPlatformVersion</code> call.
  ##   Filters: JArray
  ##          : List only the platforms where the platform member value relates to one of the supplied values.
  ##   MaxRecords: JInt
  ##             : The maximum number of platform values returned in one call.
  section = newJObject()
  var valid_604231 = formData.getOrDefault("NextToken")
  valid_604231 = validateParameter(valid_604231, JString, required = false,
                                 default = nil)
  if valid_604231 != nil:
    section.add "NextToken", valid_604231
  var valid_604232 = formData.getOrDefault("Filters")
  valid_604232 = validateParameter(valid_604232, JArray, required = false,
                                 default = nil)
  if valid_604232 != nil:
    section.add "Filters", valid_604232
  var valid_604233 = formData.getOrDefault("MaxRecords")
  valid_604233 = validateParameter(valid_604233, JInt, required = false, default = nil)
  if valid_604233 != nil:
    section.add "MaxRecords", valid_604233
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604234: Call_PostListPlatformVersions_604219; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the available platforms.
  ## 
  let valid = call_604234.validator(path, query, header, formData, body)
  let scheme = call_604234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604234.url(scheme.get, call_604234.host, call_604234.base,
                         call_604234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604234, url, valid)

proc call*(call_604235: Call_PostListPlatformVersions_604219;
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
  var query_604236 = newJObject()
  var formData_604237 = newJObject()
  add(formData_604237, "NextToken", newJString(NextToken))
  add(query_604236, "Action", newJString(Action))
  if Filters != nil:
    formData_604237.add "Filters", Filters
  add(formData_604237, "MaxRecords", newJInt(MaxRecords))
  add(query_604236, "Version", newJString(Version))
  result = call_604235.call(nil, query_604236, nil, formData_604237, nil)

var postListPlatformVersions* = Call_PostListPlatformVersions_604219(
    name: "postListPlatformVersions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListPlatformVersions",
    validator: validate_PostListPlatformVersions_604220, base: "/",
    url: url_PostListPlatformVersions_604221, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListPlatformVersions_604201 = ref object of OpenApiRestCall_602467
proc url_GetListPlatformVersions_604203(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListPlatformVersions_604202(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_604204 = query.getOrDefault("MaxRecords")
  valid_604204 = validateParameter(valid_604204, JInt, required = false, default = nil)
  if valid_604204 != nil:
    section.add "MaxRecords", valid_604204
  var valid_604205 = query.getOrDefault("Filters")
  valid_604205 = validateParameter(valid_604205, JArray, required = false,
                                 default = nil)
  if valid_604205 != nil:
    section.add "Filters", valid_604205
  var valid_604206 = query.getOrDefault("NextToken")
  valid_604206 = validateParameter(valid_604206, JString, required = false,
                                 default = nil)
  if valid_604206 != nil:
    section.add "NextToken", valid_604206
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604207 = query.getOrDefault("Action")
  valid_604207 = validateParameter(valid_604207, JString, required = true,
                                 default = newJString("ListPlatformVersions"))
  if valid_604207 != nil:
    section.add "Action", valid_604207
  var valid_604208 = query.getOrDefault("Version")
  valid_604208 = validateParameter(valid_604208, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604208 != nil:
    section.add "Version", valid_604208
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
  var valid_604209 = header.getOrDefault("X-Amz-Date")
  valid_604209 = validateParameter(valid_604209, JString, required = false,
                                 default = nil)
  if valid_604209 != nil:
    section.add "X-Amz-Date", valid_604209
  var valid_604210 = header.getOrDefault("X-Amz-Security-Token")
  valid_604210 = validateParameter(valid_604210, JString, required = false,
                                 default = nil)
  if valid_604210 != nil:
    section.add "X-Amz-Security-Token", valid_604210
  var valid_604211 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604211 = validateParameter(valid_604211, JString, required = false,
                                 default = nil)
  if valid_604211 != nil:
    section.add "X-Amz-Content-Sha256", valid_604211
  var valid_604212 = header.getOrDefault("X-Amz-Algorithm")
  valid_604212 = validateParameter(valid_604212, JString, required = false,
                                 default = nil)
  if valid_604212 != nil:
    section.add "X-Amz-Algorithm", valid_604212
  var valid_604213 = header.getOrDefault("X-Amz-Signature")
  valid_604213 = validateParameter(valid_604213, JString, required = false,
                                 default = nil)
  if valid_604213 != nil:
    section.add "X-Amz-Signature", valid_604213
  var valid_604214 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604214 = validateParameter(valid_604214, JString, required = false,
                                 default = nil)
  if valid_604214 != nil:
    section.add "X-Amz-SignedHeaders", valid_604214
  var valid_604215 = header.getOrDefault("X-Amz-Credential")
  valid_604215 = validateParameter(valid_604215, JString, required = false,
                                 default = nil)
  if valid_604215 != nil:
    section.add "X-Amz-Credential", valid_604215
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604216: Call_GetListPlatformVersions_604201; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the available platforms.
  ## 
  let valid = call_604216.validator(path, query, header, formData, body)
  let scheme = call_604216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604216.url(scheme.get, call_604216.host, call_604216.base,
                         call_604216.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604216, url, valid)

proc call*(call_604217: Call_GetListPlatformVersions_604201; MaxRecords: int = 0;
          Filters: JsonNode = nil; NextToken: string = "";
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
  var query_604218 = newJObject()
  add(query_604218, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_604218.add "Filters", Filters
  add(query_604218, "NextToken", newJString(NextToken))
  add(query_604218, "Action", newJString(Action))
  add(query_604218, "Version", newJString(Version))
  result = call_604217.call(nil, query_604218, nil, nil, nil)

var getListPlatformVersions* = Call_GetListPlatformVersions_604201(
    name: "getListPlatformVersions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListPlatformVersions",
    validator: validate_GetListPlatformVersions_604202, base: "/",
    url: url_GetListPlatformVersions_604203, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_604254 = ref object of OpenApiRestCall_602467
proc url_PostListTagsForResource_604256(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListTagsForResource_604255(path: JsonNode; query: JsonNode;
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
  var valid_604257 = query.getOrDefault("Action")
  valid_604257 = validateParameter(valid_604257, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_604257 != nil:
    section.add "Action", valid_604257
  var valid_604258 = query.getOrDefault("Version")
  valid_604258 = validateParameter(valid_604258, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604258 != nil:
    section.add "Version", valid_604258
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
  var valid_604259 = header.getOrDefault("X-Amz-Date")
  valid_604259 = validateParameter(valid_604259, JString, required = false,
                                 default = nil)
  if valid_604259 != nil:
    section.add "X-Amz-Date", valid_604259
  var valid_604260 = header.getOrDefault("X-Amz-Security-Token")
  valid_604260 = validateParameter(valid_604260, JString, required = false,
                                 default = nil)
  if valid_604260 != nil:
    section.add "X-Amz-Security-Token", valid_604260
  var valid_604261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604261 = validateParameter(valid_604261, JString, required = false,
                                 default = nil)
  if valid_604261 != nil:
    section.add "X-Amz-Content-Sha256", valid_604261
  var valid_604262 = header.getOrDefault("X-Amz-Algorithm")
  valid_604262 = validateParameter(valid_604262, JString, required = false,
                                 default = nil)
  if valid_604262 != nil:
    section.add "X-Amz-Algorithm", valid_604262
  var valid_604263 = header.getOrDefault("X-Amz-Signature")
  valid_604263 = validateParameter(valid_604263, JString, required = false,
                                 default = nil)
  if valid_604263 != nil:
    section.add "X-Amz-Signature", valid_604263
  var valid_604264 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604264 = validateParameter(valid_604264, JString, required = false,
                                 default = nil)
  if valid_604264 != nil:
    section.add "X-Amz-SignedHeaders", valid_604264
  var valid_604265 = header.getOrDefault("X-Amz-Credential")
  valid_604265 = validateParameter(valid_604265, JString, required = false,
                                 default = nil)
  if valid_604265 != nil:
    section.add "X-Amz-Credential", valid_604265
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArn: JString (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce for which a tag list is requested.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArn` field"
  var valid_604266 = formData.getOrDefault("ResourceArn")
  valid_604266 = validateParameter(valid_604266, JString, required = true,
                                 default = nil)
  if valid_604266 != nil:
    section.add "ResourceArn", valid_604266
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604267: Call_PostListTagsForResource_604254; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ## 
  let valid = call_604267.validator(path, query, header, formData, body)
  let scheme = call_604267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604267.url(scheme.get, call_604267.host, call_604267.base,
                         call_604267.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604267, url, valid)

proc call*(call_604268: Call_PostListTagsForResource_604254; ResourceArn: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-12-01"): Recallable =
  ## postListTagsForResource
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ##   Action: string (required)
  ##   ResourceArn: string (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce for which a tag list is requested.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  ##   Version: string (required)
  var query_604269 = newJObject()
  var formData_604270 = newJObject()
  add(query_604269, "Action", newJString(Action))
  add(formData_604270, "ResourceArn", newJString(ResourceArn))
  add(query_604269, "Version", newJString(Version))
  result = call_604268.call(nil, query_604269, nil, formData_604270, nil)

var postListTagsForResource* = Call_PostListTagsForResource_604254(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_604255, base: "/",
    url: url_PostListTagsForResource_604256, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_604238 = ref object of OpenApiRestCall_602467
proc url_GetListTagsForResource_604240(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListTagsForResource_604239(path: JsonNode; query: JsonNode;
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
  var valid_604241 = query.getOrDefault("ResourceArn")
  valid_604241 = validateParameter(valid_604241, JString, required = true,
                                 default = nil)
  if valid_604241 != nil:
    section.add "ResourceArn", valid_604241
  var valid_604242 = query.getOrDefault("Action")
  valid_604242 = validateParameter(valid_604242, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_604242 != nil:
    section.add "Action", valid_604242
  var valid_604243 = query.getOrDefault("Version")
  valid_604243 = validateParameter(valid_604243, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604243 != nil:
    section.add "Version", valid_604243
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
  var valid_604244 = header.getOrDefault("X-Amz-Date")
  valid_604244 = validateParameter(valid_604244, JString, required = false,
                                 default = nil)
  if valid_604244 != nil:
    section.add "X-Amz-Date", valid_604244
  var valid_604245 = header.getOrDefault("X-Amz-Security-Token")
  valid_604245 = validateParameter(valid_604245, JString, required = false,
                                 default = nil)
  if valid_604245 != nil:
    section.add "X-Amz-Security-Token", valid_604245
  var valid_604246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604246 = validateParameter(valid_604246, JString, required = false,
                                 default = nil)
  if valid_604246 != nil:
    section.add "X-Amz-Content-Sha256", valid_604246
  var valid_604247 = header.getOrDefault("X-Amz-Algorithm")
  valid_604247 = validateParameter(valid_604247, JString, required = false,
                                 default = nil)
  if valid_604247 != nil:
    section.add "X-Amz-Algorithm", valid_604247
  var valid_604248 = header.getOrDefault("X-Amz-Signature")
  valid_604248 = validateParameter(valid_604248, JString, required = false,
                                 default = nil)
  if valid_604248 != nil:
    section.add "X-Amz-Signature", valid_604248
  var valid_604249 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604249 = validateParameter(valid_604249, JString, required = false,
                                 default = nil)
  if valid_604249 != nil:
    section.add "X-Amz-SignedHeaders", valid_604249
  var valid_604250 = header.getOrDefault("X-Amz-Credential")
  valid_604250 = validateParameter(valid_604250, JString, required = false,
                                 default = nil)
  if valid_604250 != nil:
    section.add "X-Amz-Credential", valid_604250
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604251: Call_GetListTagsForResource_604238; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ## 
  let valid = call_604251.validator(path, query, header, formData, body)
  let scheme = call_604251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604251.url(scheme.get, call_604251.host, call_604251.base,
                         call_604251.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604251, url, valid)

proc call*(call_604252: Call_GetListTagsForResource_604238; ResourceArn: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-12-01"): Recallable =
  ## getListTagsForResource
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ##   ResourceArn: string (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce for which a tag list is requested.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604253 = newJObject()
  add(query_604253, "ResourceArn", newJString(ResourceArn))
  add(query_604253, "Action", newJString(Action))
  add(query_604253, "Version", newJString(Version))
  result = call_604252.call(nil, query_604253, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_604238(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_604239, base: "/",
    url: url_GetListTagsForResource_604240, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebuildEnvironment_604288 = ref object of OpenApiRestCall_602467
proc url_PostRebuildEnvironment_604290(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRebuildEnvironment_604289(path: JsonNode; query: JsonNode;
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
  var valid_604291 = query.getOrDefault("Action")
  valid_604291 = validateParameter(valid_604291, JString, required = true,
                                 default = newJString("RebuildEnvironment"))
  if valid_604291 != nil:
    section.add "Action", valid_604291
  var valid_604292 = query.getOrDefault("Version")
  valid_604292 = validateParameter(valid_604292, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604292 != nil:
    section.add "Version", valid_604292
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
  var valid_604293 = header.getOrDefault("X-Amz-Date")
  valid_604293 = validateParameter(valid_604293, JString, required = false,
                                 default = nil)
  if valid_604293 != nil:
    section.add "X-Amz-Date", valid_604293
  var valid_604294 = header.getOrDefault("X-Amz-Security-Token")
  valid_604294 = validateParameter(valid_604294, JString, required = false,
                                 default = nil)
  if valid_604294 != nil:
    section.add "X-Amz-Security-Token", valid_604294
  var valid_604295 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604295 = validateParameter(valid_604295, JString, required = false,
                                 default = nil)
  if valid_604295 != nil:
    section.add "X-Amz-Content-Sha256", valid_604295
  var valid_604296 = header.getOrDefault("X-Amz-Algorithm")
  valid_604296 = validateParameter(valid_604296, JString, required = false,
                                 default = nil)
  if valid_604296 != nil:
    section.add "X-Amz-Algorithm", valid_604296
  var valid_604297 = header.getOrDefault("X-Amz-Signature")
  valid_604297 = validateParameter(valid_604297, JString, required = false,
                                 default = nil)
  if valid_604297 != nil:
    section.add "X-Amz-Signature", valid_604297
  var valid_604298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604298 = validateParameter(valid_604298, JString, required = false,
                                 default = nil)
  if valid_604298 != nil:
    section.add "X-Amz-SignedHeaders", valid_604298
  var valid_604299 = header.getOrDefault("X-Amz-Credential")
  valid_604299 = validateParameter(valid_604299, JString, required = false,
                                 default = nil)
  if valid_604299 != nil:
    section.add "X-Amz-Credential", valid_604299
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to rebuild.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to rebuild.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_604300 = formData.getOrDefault("EnvironmentId")
  valid_604300 = validateParameter(valid_604300, JString, required = false,
                                 default = nil)
  if valid_604300 != nil:
    section.add "EnvironmentId", valid_604300
  var valid_604301 = formData.getOrDefault("EnvironmentName")
  valid_604301 = validateParameter(valid_604301, JString, required = false,
                                 default = nil)
  if valid_604301 != nil:
    section.add "EnvironmentName", valid_604301
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604302: Call_PostRebuildEnvironment_604288; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes and recreates all of the AWS resources (for example: the Auto Scaling group, load balancer, etc.) for a specified environment and forces a restart.
  ## 
  let valid = call_604302.validator(path, query, header, formData, body)
  let scheme = call_604302.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604302.url(scheme.get, call_604302.host, call_604302.base,
                         call_604302.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604302, url, valid)

proc call*(call_604303: Call_PostRebuildEnvironment_604288;
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
  var query_604304 = newJObject()
  var formData_604305 = newJObject()
  add(formData_604305, "EnvironmentId", newJString(EnvironmentId))
  add(formData_604305, "EnvironmentName", newJString(EnvironmentName))
  add(query_604304, "Action", newJString(Action))
  add(query_604304, "Version", newJString(Version))
  result = call_604303.call(nil, query_604304, nil, formData_604305, nil)

var postRebuildEnvironment* = Call_PostRebuildEnvironment_604288(
    name: "postRebuildEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RebuildEnvironment",
    validator: validate_PostRebuildEnvironment_604289, base: "/",
    url: url_PostRebuildEnvironment_604290, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebuildEnvironment_604271 = ref object of OpenApiRestCall_602467
proc url_GetRebuildEnvironment_604273(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRebuildEnvironment_604272(path: JsonNode; query: JsonNode;
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
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to rebuild.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Version: JString (required)
  section = newJObject()
  var valid_604274 = query.getOrDefault("EnvironmentName")
  valid_604274 = validateParameter(valid_604274, JString, required = false,
                                 default = nil)
  if valid_604274 != nil:
    section.add "EnvironmentName", valid_604274
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604275 = query.getOrDefault("Action")
  valid_604275 = validateParameter(valid_604275, JString, required = true,
                                 default = newJString("RebuildEnvironment"))
  if valid_604275 != nil:
    section.add "Action", valid_604275
  var valid_604276 = query.getOrDefault("EnvironmentId")
  valid_604276 = validateParameter(valid_604276, JString, required = false,
                                 default = nil)
  if valid_604276 != nil:
    section.add "EnvironmentId", valid_604276
  var valid_604277 = query.getOrDefault("Version")
  valid_604277 = validateParameter(valid_604277, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604277 != nil:
    section.add "Version", valid_604277
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
  var valid_604278 = header.getOrDefault("X-Amz-Date")
  valid_604278 = validateParameter(valid_604278, JString, required = false,
                                 default = nil)
  if valid_604278 != nil:
    section.add "X-Amz-Date", valid_604278
  var valid_604279 = header.getOrDefault("X-Amz-Security-Token")
  valid_604279 = validateParameter(valid_604279, JString, required = false,
                                 default = nil)
  if valid_604279 != nil:
    section.add "X-Amz-Security-Token", valid_604279
  var valid_604280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604280 = validateParameter(valid_604280, JString, required = false,
                                 default = nil)
  if valid_604280 != nil:
    section.add "X-Amz-Content-Sha256", valid_604280
  var valid_604281 = header.getOrDefault("X-Amz-Algorithm")
  valid_604281 = validateParameter(valid_604281, JString, required = false,
                                 default = nil)
  if valid_604281 != nil:
    section.add "X-Amz-Algorithm", valid_604281
  var valid_604282 = header.getOrDefault("X-Amz-Signature")
  valid_604282 = validateParameter(valid_604282, JString, required = false,
                                 default = nil)
  if valid_604282 != nil:
    section.add "X-Amz-Signature", valid_604282
  var valid_604283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604283 = validateParameter(valid_604283, JString, required = false,
                                 default = nil)
  if valid_604283 != nil:
    section.add "X-Amz-SignedHeaders", valid_604283
  var valid_604284 = header.getOrDefault("X-Amz-Credential")
  valid_604284 = validateParameter(valid_604284, JString, required = false,
                                 default = nil)
  if valid_604284 != nil:
    section.add "X-Amz-Credential", valid_604284
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604285: Call_GetRebuildEnvironment_604271; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes and recreates all of the AWS resources (for example: the Auto Scaling group, load balancer, etc.) for a specified environment and forces a restart.
  ## 
  let valid = call_604285.validator(path, query, header, formData, body)
  let scheme = call_604285.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604285.url(scheme.get, call_604285.host, call_604285.base,
                         call_604285.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604285, url, valid)

proc call*(call_604286: Call_GetRebuildEnvironment_604271;
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
  var query_604287 = newJObject()
  add(query_604287, "EnvironmentName", newJString(EnvironmentName))
  add(query_604287, "Action", newJString(Action))
  add(query_604287, "EnvironmentId", newJString(EnvironmentId))
  add(query_604287, "Version", newJString(Version))
  result = call_604286.call(nil, query_604287, nil, nil, nil)

var getRebuildEnvironment* = Call_GetRebuildEnvironment_604271(
    name: "getRebuildEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RebuildEnvironment",
    validator: validate_GetRebuildEnvironment_604272, base: "/",
    url: url_GetRebuildEnvironment_604273, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRequestEnvironmentInfo_604324 = ref object of OpenApiRestCall_602467
proc url_PostRequestEnvironmentInfo_604326(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRequestEnvironmentInfo_604325(path: JsonNode; query: JsonNode;
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
  var valid_604327 = query.getOrDefault("Action")
  valid_604327 = validateParameter(valid_604327, JString, required = true,
                                 default = newJString("RequestEnvironmentInfo"))
  if valid_604327 != nil:
    section.add "Action", valid_604327
  var valid_604328 = query.getOrDefault("Version")
  valid_604328 = validateParameter(valid_604328, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604328 != nil:
    section.add "Version", valid_604328
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
  var valid_604329 = header.getOrDefault("X-Amz-Date")
  valid_604329 = validateParameter(valid_604329, JString, required = false,
                                 default = nil)
  if valid_604329 != nil:
    section.add "X-Amz-Date", valid_604329
  var valid_604330 = header.getOrDefault("X-Amz-Security-Token")
  valid_604330 = validateParameter(valid_604330, JString, required = false,
                                 default = nil)
  if valid_604330 != nil:
    section.add "X-Amz-Security-Token", valid_604330
  var valid_604331 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604331 = validateParameter(valid_604331, JString, required = false,
                                 default = nil)
  if valid_604331 != nil:
    section.add "X-Amz-Content-Sha256", valid_604331
  var valid_604332 = header.getOrDefault("X-Amz-Algorithm")
  valid_604332 = validateParameter(valid_604332, JString, required = false,
                                 default = nil)
  if valid_604332 != nil:
    section.add "X-Amz-Algorithm", valid_604332
  var valid_604333 = header.getOrDefault("X-Amz-Signature")
  valid_604333 = validateParameter(valid_604333, JString, required = false,
                                 default = nil)
  if valid_604333 != nil:
    section.add "X-Amz-Signature", valid_604333
  var valid_604334 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604334 = validateParameter(valid_604334, JString, required = false,
                                 default = nil)
  if valid_604334 != nil:
    section.add "X-Amz-SignedHeaders", valid_604334
  var valid_604335 = header.getOrDefault("X-Amz-Credential")
  valid_604335 = validateParameter(valid_604335, JString, required = false,
                                 default = nil)
  if valid_604335 != nil:
    section.add "X-Amz-Credential", valid_604335
  result.add "header", section
  ## parameters in `formData` object:
  ##   InfoType: JString (required)
  ##           : The type of information to request.
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment of the requested data.</p> <p>If no such environment is found, <code>RequestEnvironmentInfo</code> returns an <code>InvalidParameterValue</code> error. </p> <p>Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment of the requested data.</p> <p>If no such environment is found, <code>RequestEnvironmentInfo</code> returns an <code>InvalidParameterValue</code> error. </p> <p>Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `InfoType` field"
  var valid_604336 = formData.getOrDefault("InfoType")
  valid_604336 = validateParameter(valid_604336, JString, required = true,
                                 default = newJString("tail"))
  if valid_604336 != nil:
    section.add "InfoType", valid_604336
  var valid_604337 = formData.getOrDefault("EnvironmentId")
  valid_604337 = validateParameter(valid_604337, JString, required = false,
                                 default = nil)
  if valid_604337 != nil:
    section.add "EnvironmentId", valid_604337
  var valid_604338 = formData.getOrDefault("EnvironmentName")
  valid_604338 = validateParameter(valid_604338, JString, required = false,
                                 default = nil)
  if valid_604338 != nil:
    section.add "EnvironmentName", valid_604338
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604339: Call_PostRequestEnvironmentInfo_604324; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a request to compile the specified type of information of the deployed environment.</p> <p> Setting the <code>InfoType</code> to <code>tail</code> compiles the last lines from the application server log files of every Amazon EC2 instance in your environment. </p> <p> Setting the <code>InfoType</code> to <code>bundle</code> compresses the application server log files for every Amazon EC2 instance into a <code>.zip</code> file. Legacy and .NET containers do not support bundle logs. </p> <p> Use <a>RetrieveEnvironmentInfo</a> to obtain the set of logs. </p> <p>Related Topics</p> <ul> <li> <p> <a>RetrieveEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_604339.validator(path, query, header, formData, body)
  let scheme = call_604339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604339.url(scheme.get, call_604339.host, call_604339.base,
                         call_604339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604339, url, valid)

proc call*(call_604340: Call_PostRequestEnvironmentInfo_604324;
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
  var query_604341 = newJObject()
  var formData_604342 = newJObject()
  add(formData_604342, "InfoType", newJString(InfoType))
  add(formData_604342, "EnvironmentId", newJString(EnvironmentId))
  add(formData_604342, "EnvironmentName", newJString(EnvironmentName))
  add(query_604341, "Action", newJString(Action))
  add(query_604341, "Version", newJString(Version))
  result = call_604340.call(nil, query_604341, nil, formData_604342, nil)

var postRequestEnvironmentInfo* = Call_PostRequestEnvironmentInfo_604324(
    name: "postRequestEnvironmentInfo", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RequestEnvironmentInfo",
    validator: validate_PostRequestEnvironmentInfo_604325, base: "/",
    url: url_PostRequestEnvironmentInfo_604326,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRequestEnvironmentInfo_604306 = ref object of OpenApiRestCall_602467
proc url_GetRequestEnvironmentInfo_604308(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRequestEnvironmentInfo_604307(path: JsonNode; query: JsonNode;
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
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment of the requested data.</p> <p>If no such environment is found, <code>RequestEnvironmentInfo</code> returns an <code>InvalidParameterValue</code> error. </p> <p>Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `InfoType` field"
  var valid_604309 = query.getOrDefault("InfoType")
  valid_604309 = validateParameter(valid_604309, JString, required = true,
                                 default = newJString("tail"))
  if valid_604309 != nil:
    section.add "InfoType", valid_604309
  var valid_604310 = query.getOrDefault("EnvironmentName")
  valid_604310 = validateParameter(valid_604310, JString, required = false,
                                 default = nil)
  if valid_604310 != nil:
    section.add "EnvironmentName", valid_604310
  var valid_604311 = query.getOrDefault("Action")
  valid_604311 = validateParameter(valid_604311, JString, required = true,
                                 default = newJString("RequestEnvironmentInfo"))
  if valid_604311 != nil:
    section.add "Action", valid_604311
  var valid_604312 = query.getOrDefault("EnvironmentId")
  valid_604312 = validateParameter(valid_604312, JString, required = false,
                                 default = nil)
  if valid_604312 != nil:
    section.add "EnvironmentId", valid_604312
  var valid_604313 = query.getOrDefault("Version")
  valid_604313 = validateParameter(valid_604313, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604313 != nil:
    section.add "Version", valid_604313
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
  var valid_604314 = header.getOrDefault("X-Amz-Date")
  valid_604314 = validateParameter(valid_604314, JString, required = false,
                                 default = nil)
  if valid_604314 != nil:
    section.add "X-Amz-Date", valid_604314
  var valid_604315 = header.getOrDefault("X-Amz-Security-Token")
  valid_604315 = validateParameter(valid_604315, JString, required = false,
                                 default = nil)
  if valid_604315 != nil:
    section.add "X-Amz-Security-Token", valid_604315
  var valid_604316 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604316 = validateParameter(valid_604316, JString, required = false,
                                 default = nil)
  if valid_604316 != nil:
    section.add "X-Amz-Content-Sha256", valid_604316
  var valid_604317 = header.getOrDefault("X-Amz-Algorithm")
  valid_604317 = validateParameter(valid_604317, JString, required = false,
                                 default = nil)
  if valid_604317 != nil:
    section.add "X-Amz-Algorithm", valid_604317
  var valid_604318 = header.getOrDefault("X-Amz-Signature")
  valid_604318 = validateParameter(valid_604318, JString, required = false,
                                 default = nil)
  if valid_604318 != nil:
    section.add "X-Amz-Signature", valid_604318
  var valid_604319 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604319 = validateParameter(valid_604319, JString, required = false,
                                 default = nil)
  if valid_604319 != nil:
    section.add "X-Amz-SignedHeaders", valid_604319
  var valid_604320 = header.getOrDefault("X-Amz-Credential")
  valid_604320 = validateParameter(valid_604320, JString, required = false,
                                 default = nil)
  if valid_604320 != nil:
    section.add "X-Amz-Credential", valid_604320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604321: Call_GetRequestEnvironmentInfo_604306; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a request to compile the specified type of information of the deployed environment.</p> <p> Setting the <code>InfoType</code> to <code>tail</code> compiles the last lines from the application server log files of every Amazon EC2 instance in your environment. </p> <p> Setting the <code>InfoType</code> to <code>bundle</code> compresses the application server log files for every Amazon EC2 instance into a <code>.zip</code> file. Legacy and .NET containers do not support bundle logs. </p> <p> Use <a>RetrieveEnvironmentInfo</a> to obtain the set of logs. </p> <p>Related Topics</p> <ul> <li> <p> <a>RetrieveEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_604321.validator(path, query, header, formData, body)
  let scheme = call_604321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604321.url(scheme.get, call_604321.host, call_604321.base,
                         call_604321.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604321, url, valid)

proc call*(call_604322: Call_GetRequestEnvironmentInfo_604306;
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
  var query_604323 = newJObject()
  add(query_604323, "InfoType", newJString(InfoType))
  add(query_604323, "EnvironmentName", newJString(EnvironmentName))
  add(query_604323, "Action", newJString(Action))
  add(query_604323, "EnvironmentId", newJString(EnvironmentId))
  add(query_604323, "Version", newJString(Version))
  result = call_604322.call(nil, query_604323, nil, nil, nil)

var getRequestEnvironmentInfo* = Call_GetRequestEnvironmentInfo_604306(
    name: "getRequestEnvironmentInfo", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RequestEnvironmentInfo",
    validator: validate_GetRequestEnvironmentInfo_604307, base: "/",
    url: url_GetRequestEnvironmentInfo_604308,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestartAppServer_604360 = ref object of OpenApiRestCall_602467
proc url_PostRestartAppServer_604362(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRestartAppServer_604361(path: JsonNode; query: JsonNode;
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
  var valid_604363 = query.getOrDefault("Action")
  valid_604363 = validateParameter(valid_604363, JString, required = true,
                                 default = newJString("RestartAppServer"))
  if valid_604363 != nil:
    section.add "Action", valid_604363
  var valid_604364 = query.getOrDefault("Version")
  valid_604364 = validateParameter(valid_604364, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604364 != nil:
    section.add "Version", valid_604364
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
  var valid_604365 = header.getOrDefault("X-Amz-Date")
  valid_604365 = validateParameter(valid_604365, JString, required = false,
                                 default = nil)
  if valid_604365 != nil:
    section.add "X-Amz-Date", valid_604365
  var valid_604366 = header.getOrDefault("X-Amz-Security-Token")
  valid_604366 = validateParameter(valid_604366, JString, required = false,
                                 default = nil)
  if valid_604366 != nil:
    section.add "X-Amz-Security-Token", valid_604366
  var valid_604367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604367 = validateParameter(valid_604367, JString, required = false,
                                 default = nil)
  if valid_604367 != nil:
    section.add "X-Amz-Content-Sha256", valid_604367
  var valid_604368 = header.getOrDefault("X-Amz-Algorithm")
  valid_604368 = validateParameter(valid_604368, JString, required = false,
                                 default = nil)
  if valid_604368 != nil:
    section.add "X-Amz-Algorithm", valid_604368
  var valid_604369 = header.getOrDefault("X-Amz-Signature")
  valid_604369 = validateParameter(valid_604369, JString, required = false,
                                 default = nil)
  if valid_604369 != nil:
    section.add "X-Amz-Signature", valid_604369
  var valid_604370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604370 = validateParameter(valid_604370, JString, required = false,
                                 default = nil)
  if valid_604370 != nil:
    section.add "X-Amz-SignedHeaders", valid_604370
  var valid_604371 = header.getOrDefault("X-Amz-Credential")
  valid_604371 = validateParameter(valid_604371, JString, required = false,
                                 default = nil)
  if valid_604371 != nil:
    section.add "X-Amz-Credential", valid_604371
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to restart the server for.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to restart the server for.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_604372 = formData.getOrDefault("EnvironmentId")
  valid_604372 = validateParameter(valid_604372, JString, required = false,
                                 default = nil)
  if valid_604372 != nil:
    section.add "EnvironmentId", valid_604372
  var valid_604373 = formData.getOrDefault("EnvironmentName")
  valid_604373 = validateParameter(valid_604373, JString, required = false,
                                 default = nil)
  if valid_604373 != nil:
    section.add "EnvironmentName", valid_604373
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604374: Call_PostRestartAppServer_604360; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Causes the environment to restart the application container server running on each Amazon EC2 instance.
  ## 
  let valid = call_604374.validator(path, query, header, formData, body)
  let scheme = call_604374.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604374.url(scheme.get, call_604374.host, call_604374.base,
                         call_604374.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604374, url, valid)

proc call*(call_604375: Call_PostRestartAppServer_604360;
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
  var query_604376 = newJObject()
  var formData_604377 = newJObject()
  add(formData_604377, "EnvironmentId", newJString(EnvironmentId))
  add(formData_604377, "EnvironmentName", newJString(EnvironmentName))
  add(query_604376, "Action", newJString(Action))
  add(query_604376, "Version", newJString(Version))
  result = call_604375.call(nil, query_604376, nil, formData_604377, nil)

var postRestartAppServer* = Call_PostRestartAppServer_604360(
    name: "postRestartAppServer", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RestartAppServer",
    validator: validate_PostRestartAppServer_604361, base: "/",
    url: url_PostRestartAppServer_604362, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestartAppServer_604343 = ref object of OpenApiRestCall_602467
proc url_GetRestartAppServer_604345(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRestartAppServer_604344(path: JsonNode; query: JsonNode;
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
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to restart the server for.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   Version: JString (required)
  section = newJObject()
  var valid_604346 = query.getOrDefault("EnvironmentName")
  valid_604346 = validateParameter(valid_604346, JString, required = false,
                                 default = nil)
  if valid_604346 != nil:
    section.add "EnvironmentName", valid_604346
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604347 = query.getOrDefault("Action")
  valid_604347 = validateParameter(valid_604347, JString, required = true,
                                 default = newJString("RestartAppServer"))
  if valid_604347 != nil:
    section.add "Action", valid_604347
  var valid_604348 = query.getOrDefault("EnvironmentId")
  valid_604348 = validateParameter(valid_604348, JString, required = false,
                                 default = nil)
  if valid_604348 != nil:
    section.add "EnvironmentId", valid_604348
  var valid_604349 = query.getOrDefault("Version")
  valid_604349 = validateParameter(valid_604349, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604349 != nil:
    section.add "Version", valid_604349
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
  var valid_604350 = header.getOrDefault("X-Amz-Date")
  valid_604350 = validateParameter(valid_604350, JString, required = false,
                                 default = nil)
  if valid_604350 != nil:
    section.add "X-Amz-Date", valid_604350
  var valid_604351 = header.getOrDefault("X-Amz-Security-Token")
  valid_604351 = validateParameter(valid_604351, JString, required = false,
                                 default = nil)
  if valid_604351 != nil:
    section.add "X-Amz-Security-Token", valid_604351
  var valid_604352 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604352 = validateParameter(valid_604352, JString, required = false,
                                 default = nil)
  if valid_604352 != nil:
    section.add "X-Amz-Content-Sha256", valid_604352
  var valid_604353 = header.getOrDefault("X-Amz-Algorithm")
  valid_604353 = validateParameter(valid_604353, JString, required = false,
                                 default = nil)
  if valid_604353 != nil:
    section.add "X-Amz-Algorithm", valid_604353
  var valid_604354 = header.getOrDefault("X-Amz-Signature")
  valid_604354 = validateParameter(valid_604354, JString, required = false,
                                 default = nil)
  if valid_604354 != nil:
    section.add "X-Amz-Signature", valid_604354
  var valid_604355 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604355 = validateParameter(valid_604355, JString, required = false,
                                 default = nil)
  if valid_604355 != nil:
    section.add "X-Amz-SignedHeaders", valid_604355
  var valid_604356 = header.getOrDefault("X-Amz-Credential")
  valid_604356 = validateParameter(valid_604356, JString, required = false,
                                 default = nil)
  if valid_604356 != nil:
    section.add "X-Amz-Credential", valid_604356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604357: Call_GetRestartAppServer_604343; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Causes the environment to restart the application container server running on each Amazon EC2 instance.
  ## 
  let valid = call_604357.validator(path, query, header, formData, body)
  let scheme = call_604357.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604357.url(scheme.get, call_604357.host, call_604357.base,
                         call_604357.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604357, url, valid)

proc call*(call_604358: Call_GetRestartAppServer_604343;
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
  var query_604359 = newJObject()
  add(query_604359, "EnvironmentName", newJString(EnvironmentName))
  add(query_604359, "Action", newJString(Action))
  add(query_604359, "EnvironmentId", newJString(EnvironmentId))
  add(query_604359, "Version", newJString(Version))
  result = call_604358.call(nil, query_604359, nil, nil, nil)

var getRestartAppServer* = Call_GetRestartAppServer_604343(
    name: "getRestartAppServer", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RestartAppServer",
    validator: validate_GetRestartAppServer_604344, base: "/",
    url: url_GetRestartAppServer_604345, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRetrieveEnvironmentInfo_604396 = ref object of OpenApiRestCall_602467
proc url_PostRetrieveEnvironmentInfo_604398(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRetrieveEnvironmentInfo_604397(path: JsonNode; query: JsonNode;
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
  var valid_604399 = query.getOrDefault("Action")
  valid_604399 = validateParameter(valid_604399, JString, required = true, default = newJString(
      "RetrieveEnvironmentInfo"))
  if valid_604399 != nil:
    section.add "Action", valid_604399
  var valid_604400 = query.getOrDefault("Version")
  valid_604400 = validateParameter(valid_604400, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604400 != nil:
    section.add "Version", valid_604400
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
  var valid_604401 = header.getOrDefault("X-Amz-Date")
  valid_604401 = validateParameter(valid_604401, JString, required = false,
                                 default = nil)
  if valid_604401 != nil:
    section.add "X-Amz-Date", valid_604401
  var valid_604402 = header.getOrDefault("X-Amz-Security-Token")
  valid_604402 = validateParameter(valid_604402, JString, required = false,
                                 default = nil)
  if valid_604402 != nil:
    section.add "X-Amz-Security-Token", valid_604402
  var valid_604403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604403 = validateParameter(valid_604403, JString, required = false,
                                 default = nil)
  if valid_604403 != nil:
    section.add "X-Amz-Content-Sha256", valid_604403
  var valid_604404 = header.getOrDefault("X-Amz-Algorithm")
  valid_604404 = validateParameter(valid_604404, JString, required = false,
                                 default = nil)
  if valid_604404 != nil:
    section.add "X-Amz-Algorithm", valid_604404
  var valid_604405 = header.getOrDefault("X-Amz-Signature")
  valid_604405 = validateParameter(valid_604405, JString, required = false,
                                 default = nil)
  if valid_604405 != nil:
    section.add "X-Amz-Signature", valid_604405
  var valid_604406 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604406 = validateParameter(valid_604406, JString, required = false,
                                 default = nil)
  if valid_604406 != nil:
    section.add "X-Amz-SignedHeaders", valid_604406
  var valid_604407 = header.getOrDefault("X-Amz-Credential")
  valid_604407 = validateParameter(valid_604407, JString, required = false,
                                 default = nil)
  if valid_604407 != nil:
    section.add "X-Amz-Credential", valid_604407
  result.add "header", section
  ## parameters in `formData` object:
  ##   InfoType: JString (required)
  ##           : The type of information to retrieve.
  ##   EnvironmentId: JString
  ##                : <p>The ID of the data's environment.</p> <p>If no such environment is found, returns an <code>InvalidParameterValue</code> error.</p> <p>Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error.</p>
  ##   EnvironmentName: JString
  ##                  : <p>The name of the data's environment.</p> <p> If no such environment is found, returns an <code>InvalidParameterValue</code> error. </p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `InfoType` field"
  var valid_604408 = formData.getOrDefault("InfoType")
  valid_604408 = validateParameter(valid_604408, JString, required = true,
                                 default = newJString("tail"))
  if valid_604408 != nil:
    section.add "InfoType", valid_604408
  var valid_604409 = formData.getOrDefault("EnvironmentId")
  valid_604409 = validateParameter(valid_604409, JString, required = false,
                                 default = nil)
  if valid_604409 != nil:
    section.add "EnvironmentId", valid_604409
  var valid_604410 = formData.getOrDefault("EnvironmentName")
  valid_604410 = validateParameter(valid_604410, JString, required = false,
                                 default = nil)
  if valid_604410 != nil:
    section.add "EnvironmentName", valid_604410
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604411: Call_PostRetrieveEnvironmentInfo_604396; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the compiled information from a <a>RequestEnvironmentInfo</a> request.</p> <p>Related Topics</p> <ul> <li> <p> <a>RequestEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_604411.validator(path, query, header, formData, body)
  let scheme = call_604411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604411.url(scheme.get, call_604411.host, call_604411.base,
                         call_604411.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604411, url, valid)

proc call*(call_604412: Call_PostRetrieveEnvironmentInfo_604396;
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
  var query_604413 = newJObject()
  var formData_604414 = newJObject()
  add(formData_604414, "InfoType", newJString(InfoType))
  add(formData_604414, "EnvironmentId", newJString(EnvironmentId))
  add(formData_604414, "EnvironmentName", newJString(EnvironmentName))
  add(query_604413, "Action", newJString(Action))
  add(query_604413, "Version", newJString(Version))
  result = call_604412.call(nil, query_604413, nil, formData_604414, nil)

var postRetrieveEnvironmentInfo* = Call_PostRetrieveEnvironmentInfo_604396(
    name: "postRetrieveEnvironmentInfo", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RetrieveEnvironmentInfo",
    validator: validate_PostRetrieveEnvironmentInfo_604397, base: "/",
    url: url_PostRetrieveEnvironmentInfo_604398,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRetrieveEnvironmentInfo_604378 = ref object of OpenApiRestCall_602467
proc url_GetRetrieveEnvironmentInfo_604380(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRetrieveEnvironmentInfo_604379(path: JsonNode; query: JsonNode;
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
  ##   EnvironmentId: JString
  ##                : <p>The ID of the data's environment.</p> <p>If no such environment is found, returns an <code>InvalidParameterValue</code> error.</p> <p>Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error.</p>
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `InfoType` field"
  var valid_604381 = query.getOrDefault("InfoType")
  valid_604381 = validateParameter(valid_604381, JString, required = true,
                                 default = newJString("tail"))
  if valid_604381 != nil:
    section.add "InfoType", valid_604381
  var valid_604382 = query.getOrDefault("EnvironmentName")
  valid_604382 = validateParameter(valid_604382, JString, required = false,
                                 default = nil)
  if valid_604382 != nil:
    section.add "EnvironmentName", valid_604382
  var valid_604383 = query.getOrDefault("Action")
  valid_604383 = validateParameter(valid_604383, JString, required = true, default = newJString(
      "RetrieveEnvironmentInfo"))
  if valid_604383 != nil:
    section.add "Action", valid_604383
  var valid_604384 = query.getOrDefault("EnvironmentId")
  valid_604384 = validateParameter(valid_604384, JString, required = false,
                                 default = nil)
  if valid_604384 != nil:
    section.add "EnvironmentId", valid_604384
  var valid_604385 = query.getOrDefault("Version")
  valid_604385 = validateParameter(valid_604385, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604385 != nil:
    section.add "Version", valid_604385
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
  var valid_604386 = header.getOrDefault("X-Amz-Date")
  valid_604386 = validateParameter(valid_604386, JString, required = false,
                                 default = nil)
  if valid_604386 != nil:
    section.add "X-Amz-Date", valid_604386
  var valid_604387 = header.getOrDefault("X-Amz-Security-Token")
  valid_604387 = validateParameter(valid_604387, JString, required = false,
                                 default = nil)
  if valid_604387 != nil:
    section.add "X-Amz-Security-Token", valid_604387
  var valid_604388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604388 = validateParameter(valid_604388, JString, required = false,
                                 default = nil)
  if valid_604388 != nil:
    section.add "X-Amz-Content-Sha256", valid_604388
  var valid_604389 = header.getOrDefault("X-Amz-Algorithm")
  valid_604389 = validateParameter(valid_604389, JString, required = false,
                                 default = nil)
  if valid_604389 != nil:
    section.add "X-Amz-Algorithm", valid_604389
  var valid_604390 = header.getOrDefault("X-Amz-Signature")
  valid_604390 = validateParameter(valid_604390, JString, required = false,
                                 default = nil)
  if valid_604390 != nil:
    section.add "X-Amz-Signature", valid_604390
  var valid_604391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604391 = validateParameter(valid_604391, JString, required = false,
                                 default = nil)
  if valid_604391 != nil:
    section.add "X-Amz-SignedHeaders", valid_604391
  var valid_604392 = header.getOrDefault("X-Amz-Credential")
  valid_604392 = validateParameter(valid_604392, JString, required = false,
                                 default = nil)
  if valid_604392 != nil:
    section.add "X-Amz-Credential", valid_604392
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604393: Call_GetRetrieveEnvironmentInfo_604378; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the compiled information from a <a>RequestEnvironmentInfo</a> request.</p> <p>Related Topics</p> <ul> <li> <p> <a>RequestEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_604393.validator(path, query, header, formData, body)
  let scheme = call_604393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604393.url(scheme.get, call_604393.host, call_604393.base,
                         call_604393.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604393, url, valid)

proc call*(call_604394: Call_GetRetrieveEnvironmentInfo_604378;
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
  var query_604395 = newJObject()
  add(query_604395, "InfoType", newJString(InfoType))
  add(query_604395, "EnvironmentName", newJString(EnvironmentName))
  add(query_604395, "Action", newJString(Action))
  add(query_604395, "EnvironmentId", newJString(EnvironmentId))
  add(query_604395, "Version", newJString(Version))
  result = call_604394.call(nil, query_604395, nil, nil, nil)

var getRetrieveEnvironmentInfo* = Call_GetRetrieveEnvironmentInfo_604378(
    name: "getRetrieveEnvironmentInfo", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RetrieveEnvironmentInfo",
    validator: validate_GetRetrieveEnvironmentInfo_604379, base: "/",
    url: url_GetRetrieveEnvironmentInfo_604380,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSwapEnvironmentCNAMEs_604434 = ref object of OpenApiRestCall_602467
proc url_PostSwapEnvironmentCNAMEs_604436(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSwapEnvironmentCNAMEs_604435(path: JsonNode; query: JsonNode;
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
  var valid_604437 = query.getOrDefault("Action")
  valid_604437 = validateParameter(valid_604437, JString, required = true,
                                 default = newJString("SwapEnvironmentCNAMEs"))
  if valid_604437 != nil:
    section.add "Action", valid_604437
  var valid_604438 = query.getOrDefault("Version")
  valid_604438 = validateParameter(valid_604438, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604438 != nil:
    section.add "Version", valid_604438
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
  var valid_604439 = header.getOrDefault("X-Amz-Date")
  valid_604439 = validateParameter(valid_604439, JString, required = false,
                                 default = nil)
  if valid_604439 != nil:
    section.add "X-Amz-Date", valid_604439
  var valid_604440 = header.getOrDefault("X-Amz-Security-Token")
  valid_604440 = validateParameter(valid_604440, JString, required = false,
                                 default = nil)
  if valid_604440 != nil:
    section.add "X-Amz-Security-Token", valid_604440
  var valid_604441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604441 = validateParameter(valid_604441, JString, required = false,
                                 default = nil)
  if valid_604441 != nil:
    section.add "X-Amz-Content-Sha256", valid_604441
  var valid_604442 = header.getOrDefault("X-Amz-Algorithm")
  valid_604442 = validateParameter(valid_604442, JString, required = false,
                                 default = nil)
  if valid_604442 != nil:
    section.add "X-Amz-Algorithm", valid_604442
  var valid_604443 = header.getOrDefault("X-Amz-Signature")
  valid_604443 = validateParameter(valid_604443, JString, required = false,
                                 default = nil)
  if valid_604443 != nil:
    section.add "X-Amz-Signature", valid_604443
  var valid_604444 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604444 = validateParameter(valid_604444, JString, required = false,
                                 default = nil)
  if valid_604444 != nil:
    section.add "X-Amz-SignedHeaders", valid_604444
  var valid_604445 = header.getOrDefault("X-Amz-Credential")
  valid_604445 = validateParameter(valid_604445, JString, required = false,
                                 default = nil)
  if valid_604445 != nil:
    section.add "X-Amz-Credential", valid_604445
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
  var valid_604446 = formData.getOrDefault("SourceEnvironmentName")
  valid_604446 = validateParameter(valid_604446, JString, required = false,
                                 default = nil)
  if valid_604446 != nil:
    section.add "SourceEnvironmentName", valid_604446
  var valid_604447 = formData.getOrDefault("SourceEnvironmentId")
  valid_604447 = validateParameter(valid_604447, JString, required = false,
                                 default = nil)
  if valid_604447 != nil:
    section.add "SourceEnvironmentId", valid_604447
  var valid_604448 = formData.getOrDefault("DestinationEnvironmentId")
  valid_604448 = validateParameter(valid_604448, JString, required = false,
                                 default = nil)
  if valid_604448 != nil:
    section.add "DestinationEnvironmentId", valid_604448
  var valid_604449 = formData.getOrDefault("DestinationEnvironmentName")
  valid_604449 = validateParameter(valid_604449, JString, required = false,
                                 default = nil)
  if valid_604449 != nil:
    section.add "DestinationEnvironmentName", valid_604449
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604450: Call_PostSwapEnvironmentCNAMEs_604434; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Swaps the CNAMEs of two environments.
  ## 
  let valid = call_604450.validator(path, query, header, formData, body)
  let scheme = call_604450.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604450.url(scheme.get, call_604450.host, call_604450.base,
                         call_604450.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604450, url, valid)

proc call*(call_604451: Call_PostSwapEnvironmentCNAMEs_604434;
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
  var query_604452 = newJObject()
  var formData_604453 = newJObject()
  add(formData_604453, "SourceEnvironmentName", newJString(SourceEnvironmentName))
  add(formData_604453, "SourceEnvironmentId", newJString(SourceEnvironmentId))
  add(formData_604453, "DestinationEnvironmentId",
      newJString(DestinationEnvironmentId))
  add(formData_604453, "DestinationEnvironmentName",
      newJString(DestinationEnvironmentName))
  add(query_604452, "Action", newJString(Action))
  add(query_604452, "Version", newJString(Version))
  result = call_604451.call(nil, query_604452, nil, formData_604453, nil)

var postSwapEnvironmentCNAMEs* = Call_PostSwapEnvironmentCNAMEs_604434(
    name: "postSwapEnvironmentCNAMEs", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=SwapEnvironmentCNAMEs",
    validator: validate_PostSwapEnvironmentCNAMEs_604435, base: "/",
    url: url_PostSwapEnvironmentCNAMEs_604436,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSwapEnvironmentCNAMEs_604415 = ref object of OpenApiRestCall_602467
proc url_GetSwapEnvironmentCNAMEs_604417(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSwapEnvironmentCNAMEs_604416(path: JsonNode; query: JsonNode;
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
  ##   DestinationEnvironmentName: JString
  ##                             : <p>The name of the destination environment.</p> <p> Condition: You must specify at least the <code>DestinationEnvironmentID</code> or the <code>DestinationEnvironmentName</code>. You may also specify both. You must specify the <code>SourceEnvironmentName</code> with the <code>DestinationEnvironmentName</code>. </p>
  ##   Action: JString (required)
  ##   SourceEnvironmentName: JString
  ##                        : <p>The name of the source environment.</p> <p> Condition: You must specify at least the <code>SourceEnvironmentID</code> or the <code>SourceEnvironmentName</code>. You may also specify both. If you specify the <code>SourceEnvironmentName</code>, you must specify the <code>DestinationEnvironmentName</code>. </p>
  ##   DestinationEnvironmentId: JString
  ##                           : <p>The ID of the destination environment.</p> <p> Condition: You must specify at least the <code>DestinationEnvironmentID</code> or the <code>DestinationEnvironmentName</code>. You may also specify both. You must specify the <code>SourceEnvironmentId</code> with the <code>DestinationEnvironmentId</code>. </p>
  ##   Version: JString (required)
  section = newJObject()
  var valid_604418 = query.getOrDefault("SourceEnvironmentId")
  valid_604418 = validateParameter(valid_604418, JString, required = false,
                                 default = nil)
  if valid_604418 != nil:
    section.add "SourceEnvironmentId", valid_604418
  var valid_604419 = query.getOrDefault("DestinationEnvironmentName")
  valid_604419 = validateParameter(valid_604419, JString, required = false,
                                 default = nil)
  if valid_604419 != nil:
    section.add "DestinationEnvironmentName", valid_604419
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604420 = query.getOrDefault("Action")
  valid_604420 = validateParameter(valid_604420, JString, required = true,
                                 default = newJString("SwapEnvironmentCNAMEs"))
  if valid_604420 != nil:
    section.add "Action", valid_604420
  var valid_604421 = query.getOrDefault("SourceEnvironmentName")
  valid_604421 = validateParameter(valid_604421, JString, required = false,
                                 default = nil)
  if valid_604421 != nil:
    section.add "SourceEnvironmentName", valid_604421
  var valid_604422 = query.getOrDefault("DestinationEnvironmentId")
  valid_604422 = validateParameter(valid_604422, JString, required = false,
                                 default = nil)
  if valid_604422 != nil:
    section.add "DestinationEnvironmentId", valid_604422
  var valid_604423 = query.getOrDefault("Version")
  valid_604423 = validateParameter(valid_604423, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604423 != nil:
    section.add "Version", valid_604423
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
  var valid_604424 = header.getOrDefault("X-Amz-Date")
  valid_604424 = validateParameter(valid_604424, JString, required = false,
                                 default = nil)
  if valid_604424 != nil:
    section.add "X-Amz-Date", valid_604424
  var valid_604425 = header.getOrDefault("X-Amz-Security-Token")
  valid_604425 = validateParameter(valid_604425, JString, required = false,
                                 default = nil)
  if valid_604425 != nil:
    section.add "X-Amz-Security-Token", valid_604425
  var valid_604426 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604426 = validateParameter(valid_604426, JString, required = false,
                                 default = nil)
  if valid_604426 != nil:
    section.add "X-Amz-Content-Sha256", valid_604426
  var valid_604427 = header.getOrDefault("X-Amz-Algorithm")
  valid_604427 = validateParameter(valid_604427, JString, required = false,
                                 default = nil)
  if valid_604427 != nil:
    section.add "X-Amz-Algorithm", valid_604427
  var valid_604428 = header.getOrDefault("X-Amz-Signature")
  valid_604428 = validateParameter(valid_604428, JString, required = false,
                                 default = nil)
  if valid_604428 != nil:
    section.add "X-Amz-Signature", valid_604428
  var valid_604429 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604429 = validateParameter(valid_604429, JString, required = false,
                                 default = nil)
  if valid_604429 != nil:
    section.add "X-Amz-SignedHeaders", valid_604429
  var valid_604430 = header.getOrDefault("X-Amz-Credential")
  valid_604430 = validateParameter(valid_604430, JString, required = false,
                                 default = nil)
  if valid_604430 != nil:
    section.add "X-Amz-Credential", valid_604430
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604431: Call_GetSwapEnvironmentCNAMEs_604415; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Swaps the CNAMEs of two environments.
  ## 
  let valid = call_604431.validator(path, query, header, formData, body)
  let scheme = call_604431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604431.url(scheme.get, call_604431.host, call_604431.base,
                         call_604431.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604431, url, valid)

proc call*(call_604432: Call_GetSwapEnvironmentCNAMEs_604415;
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
  var query_604433 = newJObject()
  add(query_604433, "SourceEnvironmentId", newJString(SourceEnvironmentId))
  add(query_604433, "DestinationEnvironmentName",
      newJString(DestinationEnvironmentName))
  add(query_604433, "Action", newJString(Action))
  add(query_604433, "SourceEnvironmentName", newJString(SourceEnvironmentName))
  add(query_604433, "DestinationEnvironmentId",
      newJString(DestinationEnvironmentId))
  add(query_604433, "Version", newJString(Version))
  result = call_604432.call(nil, query_604433, nil, nil, nil)

var getSwapEnvironmentCNAMEs* = Call_GetSwapEnvironmentCNAMEs_604415(
    name: "getSwapEnvironmentCNAMEs", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=SwapEnvironmentCNAMEs",
    validator: validate_GetSwapEnvironmentCNAMEs_604416, base: "/",
    url: url_GetSwapEnvironmentCNAMEs_604417, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostTerminateEnvironment_604473 = ref object of OpenApiRestCall_602467
proc url_PostTerminateEnvironment_604475(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostTerminateEnvironment_604474(path: JsonNode; query: JsonNode;
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
  var valid_604476 = query.getOrDefault("Action")
  valid_604476 = validateParameter(valid_604476, JString, required = true,
                                 default = newJString("TerminateEnvironment"))
  if valid_604476 != nil:
    section.add "Action", valid_604476
  var valid_604477 = query.getOrDefault("Version")
  valid_604477 = validateParameter(valid_604477, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604477 != nil:
    section.add "Version", valid_604477
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
  var valid_604478 = header.getOrDefault("X-Amz-Date")
  valid_604478 = validateParameter(valid_604478, JString, required = false,
                                 default = nil)
  if valid_604478 != nil:
    section.add "X-Amz-Date", valid_604478
  var valid_604479 = header.getOrDefault("X-Amz-Security-Token")
  valid_604479 = validateParameter(valid_604479, JString, required = false,
                                 default = nil)
  if valid_604479 != nil:
    section.add "X-Amz-Security-Token", valid_604479
  var valid_604480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604480 = validateParameter(valid_604480, JString, required = false,
                                 default = nil)
  if valid_604480 != nil:
    section.add "X-Amz-Content-Sha256", valid_604480
  var valid_604481 = header.getOrDefault("X-Amz-Algorithm")
  valid_604481 = validateParameter(valid_604481, JString, required = false,
                                 default = nil)
  if valid_604481 != nil:
    section.add "X-Amz-Algorithm", valid_604481
  var valid_604482 = header.getOrDefault("X-Amz-Signature")
  valid_604482 = validateParameter(valid_604482, JString, required = false,
                                 default = nil)
  if valid_604482 != nil:
    section.add "X-Amz-Signature", valid_604482
  var valid_604483 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604483 = validateParameter(valid_604483, JString, required = false,
                                 default = nil)
  if valid_604483 != nil:
    section.add "X-Amz-SignedHeaders", valid_604483
  var valid_604484 = header.getOrDefault("X-Amz-Credential")
  valid_604484 = validateParameter(valid_604484, JString, required = false,
                                 default = nil)
  if valid_604484 != nil:
    section.add "X-Amz-Credential", valid_604484
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
  var valid_604485 = formData.getOrDefault("ForceTerminate")
  valid_604485 = validateParameter(valid_604485, JBool, required = false, default = nil)
  if valid_604485 != nil:
    section.add "ForceTerminate", valid_604485
  var valid_604486 = formData.getOrDefault("TerminateResources")
  valid_604486 = validateParameter(valid_604486, JBool, required = false, default = nil)
  if valid_604486 != nil:
    section.add "TerminateResources", valid_604486
  var valid_604487 = formData.getOrDefault("EnvironmentId")
  valid_604487 = validateParameter(valid_604487, JString, required = false,
                                 default = nil)
  if valid_604487 != nil:
    section.add "EnvironmentId", valid_604487
  var valid_604488 = formData.getOrDefault("EnvironmentName")
  valid_604488 = validateParameter(valid_604488, JString, required = false,
                                 default = nil)
  if valid_604488 != nil:
    section.add "EnvironmentName", valid_604488
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604489: Call_PostTerminateEnvironment_604473; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Terminates the specified environment.
  ## 
  let valid = call_604489.validator(path, query, header, formData, body)
  let scheme = call_604489.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604489.url(scheme.get, call_604489.host, call_604489.base,
                         call_604489.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604489, url, valid)

proc call*(call_604490: Call_PostTerminateEnvironment_604473;
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
  var query_604491 = newJObject()
  var formData_604492 = newJObject()
  add(formData_604492, "ForceTerminate", newJBool(ForceTerminate))
  add(formData_604492, "TerminateResources", newJBool(TerminateResources))
  add(formData_604492, "EnvironmentId", newJString(EnvironmentId))
  add(formData_604492, "EnvironmentName", newJString(EnvironmentName))
  add(query_604491, "Action", newJString(Action))
  add(query_604491, "Version", newJString(Version))
  result = call_604490.call(nil, query_604491, nil, formData_604492, nil)

var postTerminateEnvironment* = Call_PostTerminateEnvironment_604473(
    name: "postTerminateEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=TerminateEnvironment",
    validator: validate_PostTerminateEnvironment_604474, base: "/",
    url: url_PostTerminateEnvironment_604475, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTerminateEnvironment_604454 = ref object of OpenApiRestCall_602467
proc url_GetTerminateEnvironment_604456(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetTerminateEnvironment_604455(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_604457 = query.getOrDefault("EnvironmentName")
  valid_604457 = validateParameter(valid_604457, JString, required = false,
                                 default = nil)
  if valid_604457 != nil:
    section.add "EnvironmentName", valid_604457
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604458 = query.getOrDefault("Action")
  valid_604458 = validateParameter(valid_604458, JString, required = true,
                                 default = newJString("TerminateEnvironment"))
  if valid_604458 != nil:
    section.add "Action", valid_604458
  var valid_604459 = query.getOrDefault("EnvironmentId")
  valid_604459 = validateParameter(valid_604459, JString, required = false,
                                 default = nil)
  if valid_604459 != nil:
    section.add "EnvironmentId", valid_604459
  var valid_604460 = query.getOrDefault("ForceTerminate")
  valid_604460 = validateParameter(valid_604460, JBool, required = false, default = nil)
  if valid_604460 != nil:
    section.add "ForceTerminate", valid_604460
  var valid_604461 = query.getOrDefault("TerminateResources")
  valid_604461 = validateParameter(valid_604461, JBool, required = false, default = nil)
  if valid_604461 != nil:
    section.add "TerminateResources", valid_604461
  var valid_604462 = query.getOrDefault("Version")
  valid_604462 = validateParameter(valid_604462, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604462 != nil:
    section.add "Version", valid_604462
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
  var valid_604463 = header.getOrDefault("X-Amz-Date")
  valid_604463 = validateParameter(valid_604463, JString, required = false,
                                 default = nil)
  if valid_604463 != nil:
    section.add "X-Amz-Date", valid_604463
  var valid_604464 = header.getOrDefault("X-Amz-Security-Token")
  valid_604464 = validateParameter(valid_604464, JString, required = false,
                                 default = nil)
  if valid_604464 != nil:
    section.add "X-Amz-Security-Token", valid_604464
  var valid_604465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604465 = validateParameter(valid_604465, JString, required = false,
                                 default = nil)
  if valid_604465 != nil:
    section.add "X-Amz-Content-Sha256", valid_604465
  var valid_604466 = header.getOrDefault("X-Amz-Algorithm")
  valid_604466 = validateParameter(valid_604466, JString, required = false,
                                 default = nil)
  if valid_604466 != nil:
    section.add "X-Amz-Algorithm", valid_604466
  var valid_604467 = header.getOrDefault("X-Amz-Signature")
  valid_604467 = validateParameter(valid_604467, JString, required = false,
                                 default = nil)
  if valid_604467 != nil:
    section.add "X-Amz-Signature", valid_604467
  var valid_604468 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604468 = validateParameter(valid_604468, JString, required = false,
                                 default = nil)
  if valid_604468 != nil:
    section.add "X-Amz-SignedHeaders", valid_604468
  var valid_604469 = header.getOrDefault("X-Amz-Credential")
  valid_604469 = validateParameter(valid_604469, JString, required = false,
                                 default = nil)
  if valid_604469 != nil:
    section.add "X-Amz-Credential", valid_604469
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604470: Call_GetTerminateEnvironment_604454; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Terminates the specified environment.
  ## 
  let valid = call_604470.validator(path, query, header, formData, body)
  let scheme = call_604470.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604470.url(scheme.get, call_604470.host, call_604470.base,
                         call_604470.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604470, url, valid)

proc call*(call_604471: Call_GetTerminateEnvironment_604454;
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
  var query_604472 = newJObject()
  add(query_604472, "EnvironmentName", newJString(EnvironmentName))
  add(query_604472, "Action", newJString(Action))
  add(query_604472, "EnvironmentId", newJString(EnvironmentId))
  add(query_604472, "ForceTerminate", newJBool(ForceTerminate))
  add(query_604472, "TerminateResources", newJBool(TerminateResources))
  add(query_604472, "Version", newJString(Version))
  result = call_604471.call(nil, query_604472, nil, nil, nil)

var getTerminateEnvironment* = Call_GetTerminateEnvironment_604454(
    name: "getTerminateEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=TerminateEnvironment",
    validator: validate_GetTerminateEnvironment_604455, base: "/",
    url: url_GetTerminateEnvironment_604456, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateApplication_604510 = ref object of OpenApiRestCall_602467
proc url_PostUpdateApplication_604512(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateApplication_604511(path: JsonNode; query: JsonNode;
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
  var valid_604513 = query.getOrDefault("Action")
  valid_604513 = validateParameter(valid_604513, JString, required = true,
                                 default = newJString("UpdateApplication"))
  if valid_604513 != nil:
    section.add "Action", valid_604513
  var valid_604514 = query.getOrDefault("Version")
  valid_604514 = validateParameter(valid_604514, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604514 != nil:
    section.add "Version", valid_604514
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
  var valid_604515 = header.getOrDefault("X-Amz-Date")
  valid_604515 = validateParameter(valid_604515, JString, required = false,
                                 default = nil)
  if valid_604515 != nil:
    section.add "X-Amz-Date", valid_604515
  var valid_604516 = header.getOrDefault("X-Amz-Security-Token")
  valid_604516 = validateParameter(valid_604516, JString, required = false,
                                 default = nil)
  if valid_604516 != nil:
    section.add "X-Amz-Security-Token", valid_604516
  var valid_604517 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604517 = validateParameter(valid_604517, JString, required = false,
                                 default = nil)
  if valid_604517 != nil:
    section.add "X-Amz-Content-Sha256", valid_604517
  var valid_604518 = header.getOrDefault("X-Amz-Algorithm")
  valid_604518 = validateParameter(valid_604518, JString, required = false,
                                 default = nil)
  if valid_604518 != nil:
    section.add "X-Amz-Algorithm", valid_604518
  var valid_604519 = header.getOrDefault("X-Amz-Signature")
  valid_604519 = validateParameter(valid_604519, JString, required = false,
                                 default = nil)
  if valid_604519 != nil:
    section.add "X-Amz-Signature", valid_604519
  var valid_604520 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604520 = validateParameter(valid_604520, JString, required = false,
                                 default = nil)
  if valid_604520 != nil:
    section.add "X-Amz-SignedHeaders", valid_604520
  var valid_604521 = header.getOrDefault("X-Amz-Credential")
  valid_604521 = validateParameter(valid_604521, JString, required = false,
                                 default = nil)
  if valid_604521 != nil:
    section.add "X-Amz-Credential", valid_604521
  result.add "header", section
  ## parameters in `formData` object:
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to update. If no such application is found, <code>UpdateApplication</code> returns an <code>InvalidParameterValue</code> error. 
  ##   Description: JString
  ##              : <p>A new description for the application.</p> <p>Default: If not specified, AWS Elastic Beanstalk does not update the description.</p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_604522 = formData.getOrDefault("ApplicationName")
  valid_604522 = validateParameter(valid_604522, JString, required = true,
                                 default = nil)
  if valid_604522 != nil:
    section.add "ApplicationName", valid_604522
  var valid_604523 = formData.getOrDefault("Description")
  valid_604523 = validateParameter(valid_604523, JString, required = false,
                                 default = nil)
  if valid_604523 != nil:
    section.add "Description", valid_604523
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604524: Call_PostUpdateApplication_604510; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified application to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear these properties, specify an empty string.</p> </note>
  ## 
  let valid = call_604524.validator(path, query, header, formData, body)
  let scheme = call_604524.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604524.url(scheme.get, call_604524.host, call_604524.base,
                         call_604524.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604524, url, valid)

proc call*(call_604525: Call_PostUpdateApplication_604510; ApplicationName: string;
          Action: string = "UpdateApplication"; Version: string = "2010-12-01";
          Description: string = ""): Recallable =
  ## postUpdateApplication
  ## <p>Updates the specified application to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear these properties, specify an empty string.</p> </note>
  ##   Action: string (required)
  ##   ApplicationName: string (required)
  ##                  : The name of the application to update. If no such application is found, <code>UpdateApplication</code> returns an <code>InvalidParameterValue</code> error. 
  ##   Version: string (required)
  ##   Description: string
  ##              : <p>A new description for the application.</p> <p>Default: If not specified, AWS Elastic Beanstalk does not update the description.</p>
  var query_604526 = newJObject()
  var formData_604527 = newJObject()
  add(query_604526, "Action", newJString(Action))
  add(formData_604527, "ApplicationName", newJString(ApplicationName))
  add(query_604526, "Version", newJString(Version))
  add(formData_604527, "Description", newJString(Description))
  result = call_604525.call(nil, query_604526, nil, formData_604527, nil)

var postUpdateApplication* = Call_PostUpdateApplication_604510(
    name: "postUpdateApplication", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateApplication",
    validator: validate_PostUpdateApplication_604511, base: "/",
    url: url_PostUpdateApplication_604512, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateApplication_604493 = ref object of OpenApiRestCall_602467
proc url_GetUpdateApplication_604495(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateApplication_604494(path: JsonNode; query: JsonNode;
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
  ##   Description: JString
  ##              : <p>A new description for the application.</p> <p>Default: If not specified, AWS Elastic Beanstalk does not update the description.</p>
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_604496 = query.getOrDefault("ApplicationName")
  valid_604496 = validateParameter(valid_604496, JString, required = true,
                                 default = nil)
  if valid_604496 != nil:
    section.add "ApplicationName", valid_604496
  var valid_604497 = query.getOrDefault("Description")
  valid_604497 = validateParameter(valid_604497, JString, required = false,
                                 default = nil)
  if valid_604497 != nil:
    section.add "Description", valid_604497
  var valid_604498 = query.getOrDefault("Action")
  valid_604498 = validateParameter(valid_604498, JString, required = true,
                                 default = newJString("UpdateApplication"))
  if valid_604498 != nil:
    section.add "Action", valid_604498
  var valid_604499 = query.getOrDefault("Version")
  valid_604499 = validateParameter(valid_604499, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604499 != nil:
    section.add "Version", valid_604499
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
  var valid_604500 = header.getOrDefault("X-Amz-Date")
  valid_604500 = validateParameter(valid_604500, JString, required = false,
                                 default = nil)
  if valid_604500 != nil:
    section.add "X-Amz-Date", valid_604500
  var valid_604501 = header.getOrDefault("X-Amz-Security-Token")
  valid_604501 = validateParameter(valid_604501, JString, required = false,
                                 default = nil)
  if valid_604501 != nil:
    section.add "X-Amz-Security-Token", valid_604501
  var valid_604502 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604502 = validateParameter(valid_604502, JString, required = false,
                                 default = nil)
  if valid_604502 != nil:
    section.add "X-Amz-Content-Sha256", valid_604502
  var valid_604503 = header.getOrDefault("X-Amz-Algorithm")
  valid_604503 = validateParameter(valid_604503, JString, required = false,
                                 default = nil)
  if valid_604503 != nil:
    section.add "X-Amz-Algorithm", valid_604503
  var valid_604504 = header.getOrDefault("X-Amz-Signature")
  valid_604504 = validateParameter(valid_604504, JString, required = false,
                                 default = nil)
  if valid_604504 != nil:
    section.add "X-Amz-Signature", valid_604504
  var valid_604505 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604505 = validateParameter(valid_604505, JString, required = false,
                                 default = nil)
  if valid_604505 != nil:
    section.add "X-Amz-SignedHeaders", valid_604505
  var valid_604506 = header.getOrDefault("X-Amz-Credential")
  valid_604506 = validateParameter(valid_604506, JString, required = false,
                                 default = nil)
  if valid_604506 != nil:
    section.add "X-Amz-Credential", valid_604506
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604507: Call_GetUpdateApplication_604493; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified application to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear these properties, specify an empty string.</p> </note>
  ## 
  let valid = call_604507.validator(path, query, header, formData, body)
  let scheme = call_604507.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604507.url(scheme.get, call_604507.host, call_604507.base,
                         call_604507.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604507, url, valid)

proc call*(call_604508: Call_GetUpdateApplication_604493; ApplicationName: string;
          Description: string = ""; Action: string = "UpdateApplication";
          Version: string = "2010-12-01"): Recallable =
  ## getUpdateApplication
  ## <p>Updates the specified application to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear these properties, specify an empty string.</p> </note>
  ##   ApplicationName: string (required)
  ##                  : The name of the application to update. If no such application is found, <code>UpdateApplication</code> returns an <code>InvalidParameterValue</code> error. 
  ##   Description: string
  ##              : <p>A new description for the application.</p> <p>Default: If not specified, AWS Elastic Beanstalk does not update the description.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604509 = newJObject()
  add(query_604509, "ApplicationName", newJString(ApplicationName))
  add(query_604509, "Description", newJString(Description))
  add(query_604509, "Action", newJString(Action))
  add(query_604509, "Version", newJString(Version))
  result = call_604508.call(nil, query_604509, nil, nil, nil)

var getUpdateApplication* = Call_GetUpdateApplication_604493(
    name: "getUpdateApplication", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateApplication",
    validator: validate_GetUpdateApplication_604494, base: "/",
    url: url_GetUpdateApplication_604495, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateApplicationResourceLifecycle_604546 = ref object of OpenApiRestCall_602467
proc url_PostUpdateApplicationResourceLifecycle_604548(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateApplicationResourceLifecycle_604547(path: JsonNode;
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
  var valid_604549 = query.getOrDefault("Action")
  valid_604549 = validateParameter(valid_604549, JString, required = true, default = newJString(
      "UpdateApplicationResourceLifecycle"))
  if valid_604549 != nil:
    section.add "Action", valid_604549
  var valid_604550 = query.getOrDefault("Version")
  valid_604550 = validateParameter(valid_604550, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604550 != nil:
    section.add "Version", valid_604550
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
  var valid_604551 = header.getOrDefault("X-Amz-Date")
  valid_604551 = validateParameter(valid_604551, JString, required = false,
                                 default = nil)
  if valid_604551 != nil:
    section.add "X-Amz-Date", valid_604551
  var valid_604552 = header.getOrDefault("X-Amz-Security-Token")
  valid_604552 = validateParameter(valid_604552, JString, required = false,
                                 default = nil)
  if valid_604552 != nil:
    section.add "X-Amz-Security-Token", valid_604552
  var valid_604553 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604553 = validateParameter(valid_604553, JString, required = false,
                                 default = nil)
  if valid_604553 != nil:
    section.add "X-Amz-Content-Sha256", valid_604553
  var valid_604554 = header.getOrDefault("X-Amz-Algorithm")
  valid_604554 = validateParameter(valid_604554, JString, required = false,
                                 default = nil)
  if valid_604554 != nil:
    section.add "X-Amz-Algorithm", valid_604554
  var valid_604555 = header.getOrDefault("X-Amz-Signature")
  valid_604555 = validateParameter(valid_604555, JString, required = false,
                                 default = nil)
  if valid_604555 != nil:
    section.add "X-Amz-Signature", valid_604555
  var valid_604556 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604556 = validateParameter(valid_604556, JString, required = false,
                                 default = nil)
  if valid_604556 != nil:
    section.add "X-Amz-SignedHeaders", valid_604556
  var valid_604557 = header.getOrDefault("X-Amz-Credential")
  valid_604557 = validateParameter(valid_604557, JString, required = false,
                                 default = nil)
  if valid_604557 != nil:
    section.add "X-Amz-Credential", valid_604557
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
  var valid_604558 = formData.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_604558 = validateParameter(valid_604558, JString, required = false,
                                 default = nil)
  if valid_604558 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_604558
  var valid_604559 = formData.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_604559 = validateParameter(valid_604559, JString, required = false,
                                 default = nil)
  if valid_604559 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_604559
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_604560 = formData.getOrDefault("ApplicationName")
  valid_604560 = validateParameter(valid_604560, JString, required = true,
                                 default = nil)
  if valid_604560 != nil:
    section.add "ApplicationName", valid_604560
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604561: Call_PostUpdateApplicationResourceLifecycle_604546;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Modifies lifecycle settings for an application.
  ## 
  let valid = call_604561.validator(path, query, header, formData, body)
  let scheme = call_604561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604561.url(scheme.get, call_604561.host, call_604561.base,
                         call_604561.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604561, url, valid)

proc call*(call_604562: Call_PostUpdateApplicationResourceLifecycle_604546;
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
  var query_604563 = newJObject()
  var formData_604564 = newJObject()
  add(formData_604564, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  add(formData_604564, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  add(query_604563, "Action", newJString(Action))
  add(formData_604564, "ApplicationName", newJString(ApplicationName))
  add(query_604563, "Version", newJString(Version))
  result = call_604562.call(nil, query_604563, nil, formData_604564, nil)

var postUpdateApplicationResourceLifecycle* = Call_PostUpdateApplicationResourceLifecycle_604546(
    name: "postUpdateApplicationResourceLifecycle", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationResourceLifecycle",
    validator: validate_PostUpdateApplicationResourceLifecycle_604547, base: "/",
    url: url_PostUpdateApplicationResourceLifecycle_604548,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateApplicationResourceLifecycle_604528 = ref object of OpenApiRestCall_602467
proc url_GetUpdateApplicationResourceLifecycle_604530(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateApplicationResourceLifecycle_604529(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_604531 = query.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_604531 = validateParameter(valid_604531, JString, required = false,
                                 default = nil)
  if valid_604531 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_604531
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_604532 = query.getOrDefault("ApplicationName")
  valid_604532 = validateParameter(valid_604532, JString, required = true,
                                 default = nil)
  if valid_604532 != nil:
    section.add "ApplicationName", valid_604532
  var valid_604533 = query.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_604533 = validateParameter(valid_604533, JString, required = false,
                                 default = nil)
  if valid_604533 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_604533
  var valid_604534 = query.getOrDefault("Action")
  valid_604534 = validateParameter(valid_604534, JString, required = true, default = newJString(
      "UpdateApplicationResourceLifecycle"))
  if valid_604534 != nil:
    section.add "Action", valid_604534
  var valid_604535 = query.getOrDefault("Version")
  valid_604535 = validateParameter(valid_604535, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604535 != nil:
    section.add "Version", valid_604535
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
  var valid_604536 = header.getOrDefault("X-Amz-Date")
  valid_604536 = validateParameter(valid_604536, JString, required = false,
                                 default = nil)
  if valid_604536 != nil:
    section.add "X-Amz-Date", valid_604536
  var valid_604537 = header.getOrDefault("X-Amz-Security-Token")
  valid_604537 = validateParameter(valid_604537, JString, required = false,
                                 default = nil)
  if valid_604537 != nil:
    section.add "X-Amz-Security-Token", valid_604537
  var valid_604538 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604538 = validateParameter(valid_604538, JString, required = false,
                                 default = nil)
  if valid_604538 != nil:
    section.add "X-Amz-Content-Sha256", valid_604538
  var valid_604539 = header.getOrDefault("X-Amz-Algorithm")
  valid_604539 = validateParameter(valid_604539, JString, required = false,
                                 default = nil)
  if valid_604539 != nil:
    section.add "X-Amz-Algorithm", valid_604539
  var valid_604540 = header.getOrDefault("X-Amz-Signature")
  valid_604540 = validateParameter(valid_604540, JString, required = false,
                                 default = nil)
  if valid_604540 != nil:
    section.add "X-Amz-Signature", valid_604540
  var valid_604541 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604541 = validateParameter(valid_604541, JString, required = false,
                                 default = nil)
  if valid_604541 != nil:
    section.add "X-Amz-SignedHeaders", valid_604541
  var valid_604542 = header.getOrDefault("X-Amz-Credential")
  valid_604542 = validateParameter(valid_604542, JString, required = false,
                                 default = nil)
  if valid_604542 != nil:
    section.add "X-Amz-Credential", valid_604542
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604543: Call_GetUpdateApplicationResourceLifecycle_604528;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Modifies lifecycle settings for an application.
  ## 
  let valid = call_604543.validator(path, query, header, formData, body)
  let scheme = call_604543.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604543.url(scheme.get, call_604543.host, call_604543.base,
                         call_604543.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604543, url, valid)

proc call*(call_604544: Call_GetUpdateApplicationResourceLifecycle_604528;
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
  var query_604545 = newJObject()
  add(query_604545, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  add(query_604545, "ApplicationName", newJString(ApplicationName))
  add(query_604545, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  add(query_604545, "Action", newJString(Action))
  add(query_604545, "Version", newJString(Version))
  result = call_604544.call(nil, query_604545, nil, nil, nil)

var getUpdateApplicationResourceLifecycle* = Call_GetUpdateApplicationResourceLifecycle_604528(
    name: "getUpdateApplicationResourceLifecycle", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationResourceLifecycle",
    validator: validate_GetUpdateApplicationResourceLifecycle_604529, base: "/",
    url: url_GetUpdateApplicationResourceLifecycle_604530,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateApplicationVersion_604583 = ref object of OpenApiRestCall_602467
proc url_PostUpdateApplicationVersion_604585(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateApplicationVersion_604584(path: JsonNode; query: JsonNode;
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
  var valid_604586 = query.getOrDefault("Action")
  valid_604586 = validateParameter(valid_604586, JString, required = true, default = newJString(
      "UpdateApplicationVersion"))
  if valid_604586 != nil:
    section.add "Action", valid_604586
  var valid_604587 = query.getOrDefault("Version")
  valid_604587 = validateParameter(valid_604587, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604587 != nil:
    section.add "Version", valid_604587
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
  var valid_604588 = header.getOrDefault("X-Amz-Date")
  valid_604588 = validateParameter(valid_604588, JString, required = false,
                                 default = nil)
  if valid_604588 != nil:
    section.add "X-Amz-Date", valid_604588
  var valid_604589 = header.getOrDefault("X-Amz-Security-Token")
  valid_604589 = validateParameter(valid_604589, JString, required = false,
                                 default = nil)
  if valid_604589 != nil:
    section.add "X-Amz-Security-Token", valid_604589
  var valid_604590 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604590 = validateParameter(valid_604590, JString, required = false,
                                 default = nil)
  if valid_604590 != nil:
    section.add "X-Amz-Content-Sha256", valid_604590
  var valid_604591 = header.getOrDefault("X-Amz-Algorithm")
  valid_604591 = validateParameter(valid_604591, JString, required = false,
                                 default = nil)
  if valid_604591 != nil:
    section.add "X-Amz-Algorithm", valid_604591
  var valid_604592 = header.getOrDefault("X-Amz-Signature")
  valid_604592 = validateParameter(valid_604592, JString, required = false,
                                 default = nil)
  if valid_604592 != nil:
    section.add "X-Amz-Signature", valid_604592
  var valid_604593 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604593 = validateParameter(valid_604593, JString, required = false,
                                 default = nil)
  if valid_604593 != nil:
    section.add "X-Amz-SignedHeaders", valid_604593
  var valid_604594 = header.getOrDefault("X-Amz-Credential")
  valid_604594 = validateParameter(valid_604594, JString, required = false,
                                 default = nil)
  if valid_604594 != nil:
    section.add "X-Amz-Credential", valid_604594
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
  var valid_604595 = formData.getOrDefault("VersionLabel")
  valid_604595 = validateParameter(valid_604595, JString, required = true,
                                 default = nil)
  if valid_604595 != nil:
    section.add "VersionLabel", valid_604595
  var valid_604596 = formData.getOrDefault("ApplicationName")
  valid_604596 = validateParameter(valid_604596, JString, required = true,
                                 default = nil)
  if valid_604596 != nil:
    section.add "ApplicationName", valid_604596
  var valid_604597 = formData.getOrDefault("Description")
  valid_604597 = validateParameter(valid_604597, JString, required = false,
                                 default = nil)
  if valid_604597 != nil:
    section.add "Description", valid_604597
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604598: Call_PostUpdateApplicationVersion_604583; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified application version to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear properties, specify an empty string.</p> </note>
  ## 
  let valid = call_604598.validator(path, query, header, formData, body)
  let scheme = call_604598.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604598.url(scheme.get, call_604598.host, call_604598.base,
                         call_604598.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604598, url, valid)

proc call*(call_604599: Call_PostUpdateApplicationVersion_604583;
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
  var query_604600 = newJObject()
  var formData_604601 = newJObject()
  add(formData_604601, "VersionLabel", newJString(VersionLabel))
  add(query_604600, "Action", newJString(Action))
  add(formData_604601, "ApplicationName", newJString(ApplicationName))
  add(query_604600, "Version", newJString(Version))
  add(formData_604601, "Description", newJString(Description))
  result = call_604599.call(nil, query_604600, nil, formData_604601, nil)

var postUpdateApplicationVersion* = Call_PostUpdateApplicationVersion_604583(
    name: "postUpdateApplicationVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationVersion",
    validator: validate_PostUpdateApplicationVersion_604584, base: "/",
    url: url_PostUpdateApplicationVersion_604585,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateApplicationVersion_604565 = ref object of OpenApiRestCall_602467
proc url_GetUpdateApplicationVersion_604567(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateApplicationVersion_604566(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_604568 = query.getOrDefault("VersionLabel")
  valid_604568 = validateParameter(valid_604568, JString, required = true,
                                 default = nil)
  if valid_604568 != nil:
    section.add "VersionLabel", valid_604568
  var valid_604569 = query.getOrDefault("ApplicationName")
  valid_604569 = validateParameter(valid_604569, JString, required = true,
                                 default = nil)
  if valid_604569 != nil:
    section.add "ApplicationName", valid_604569
  var valid_604570 = query.getOrDefault("Description")
  valid_604570 = validateParameter(valid_604570, JString, required = false,
                                 default = nil)
  if valid_604570 != nil:
    section.add "Description", valid_604570
  var valid_604571 = query.getOrDefault("Action")
  valid_604571 = validateParameter(valid_604571, JString, required = true, default = newJString(
      "UpdateApplicationVersion"))
  if valid_604571 != nil:
    section.add "Action", valid_604571
  var valid_604572 = query.getOrDefault("Version")
  valid_604572 = validateParameter(valid_604572, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604572 != nil:
    section.add "Version", valid_604572
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
  var valid_604573 = header.getOrDefault("X-Amz-Date")
  valid_604573 = validateParameter(valid_604573, JString, required = false,
                                 default = nil)
  if valid_604573 != nil:
    section.add "X-Amz-Date", valid_604573
  var valid_604574 = header.getOrDefault("X-Amz-Security-Token")
  valid_604574 = validateParameter(valid_604574, JString, required = false,
                                 default = nil)
  if valid_604574 != nil:
    section.add "X-Amz-Security-Token", valid_604574
  var valid_604575 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604575 = validateParameter(valid_604575, JString, required = false,
                                 default = nil)
  if valid_604575 != nil:
    section.add "X-Amz-Content-Sha256", valid_604575
  var valid_604576 = header.getOrDefault("X-Amz-Algorithm")
  valid_604576 = validateParameter(valid_604576, JString, required = false,
                                 default = nil)
  if valid_604576 != nil:
    section.add "X-Amz-Algorithm", valid_604576
  var valid_604577 = header.getOrDefault("X-Amz-Signature")
  valid_604577 = validateParameter(valid_604577, JString, required = false,
                                 default = nil)
  if valid_604577 != nil:
    section.add "X-Amz-Signature", valid_604577
  var valid_604578 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604578 = validateParameter(valid_604578, JString, required = false,
                                 default = nil)
  if valid_604578 != nil:
    section.add "X-Amz-SignedHeaders", valid_604578
  var valid_604579 = header.getOrDefault("X-Amz-Credential")
  valid_604579 = validateParameter(valid_604579, JString, required = false,
                                 default = nil)
  if valid_604579 != nil:
    section.add "X-Amz-Credential", valid_604579
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604580: Call_GetUpdateApplicationVersion_604565; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified application version to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear properties, specify an empty string.</p> </note>
  ## 
  let valid = call_604580.validator(path, query, header, formData, body)
  let scheme = call_604580.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604580.url(scheme.get, call_604580.host, call_604580.base,
                         call_604580.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604580, url, valid)

proc call*(call_604581: Call_GetUpdateApplicationVersion_604565;
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
  var query_604582 = newJObject()
  add(query_604582, "VersionLabel", newJString(VersionLabel))
  add(query_604582, "ApplicationName", newJString(ApplicationName))
  add(query_604582, "Description", newJString(Description))
  add(query_604582, "Action", newJString(Action))
  add(query_604582, "Version", newJString(Version))
  result = call_604581.call(nil, query_604582, nil, nil, nil)

var getUpdateApplicationVersion* = Call_GetUpdateApplicationVersion_604565(
    name: "getUpdateApplicationVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationVersion",
    validator: validate_GetUpdateApplicationVersion_604566, base: "/",
    url: url_GetUpdateApplicationVersion_604567,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateConfigurationTemplate_604622 = ref object of OpenApiRestCall_602467
proc url_PostUpdateConfigurationTemplate_604624(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateConfigurationTemplate_604623(path: JsonNode;
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
  var valid_604625 = query.getOrDefault("Action")
  valid_604625 = validateParameter(valid_604625, JString, required = true, default = newJString(
      "UpdateConfigurationTemplate"))
  if valid_604625 != nil:
    section.add "Action", valid_604625
  var valid_604626 = query.getOrDefault("Version")
  valid_604626 = validateParameter(valid_604626, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604626 != nil:
    section.add "Version", valid_604626
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
  var valid_604627 = header.getOrDefault("X-Amz-Date")
  valid_604627 = validateParameter(valid_604627, JString, required = false,
                                 default = nil)
  if valid_604627 != nil:
    section.add "X-Amz-Date", valid_604627
  var valid_604628 = header.getOrDefault("X-Amz-Security-Token")
  valid_604628 = validateParameter(valid_604628, JString, required = false,
                                 default = nil)
  if valid_604628 != nil:
    section.add "X-Amz-Security-Token", valid_604628
  var valid_604629 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604629 = validateParameter(valid_604629, JString, required = false,
                                 default = nil)
  if valid_604629 != nil:
    section.add "X-Amz-Content-Sha256", valid_604629
  var valid_604630 = header.getOrDefault("X-Amz-Algorithm")
  valid_604630 = validateParameter(valid_604630, JString, required = false,
                                 default = nil)
  if valid_604630 != nil:
    section.add "X-Amz-Algorithm", valid_604630
  var valid_604631 = header.getOrDefault("X-Amz-Signature")
  valid_604631 = validateParameter(valid_604631, JString, required = false,
                                 default = nil)
  if valid_604631 != nil:
    section.add "X-Amz-Signature", valid_604631
  var valid_604632 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604632 = validateParameter(valid_604632, JString, required = false,
                                 default = nil)
  if valid_604632 != nil:
    section.add "X-Amz-SignedHeaders", valid_604632
  var valid_604633 = header.getOrDefault("X-Amz-Credential")
  valid_604633 = validateParameter(valid_604633, JString, required = false,
                                 default = nil)
  if valid_604633 != nil:
    section.add "X-Amz-Credential", valid_604633
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
  var valid_604634 = formData.getOrDefault("OptionsToRemove")
  valid_604634 = validateParameter(valid_604634, JArray, required = false,
                                 default = nil)
  if valid_604634 != nil:
    section.add "OptionsToRemove", valid_604634
  var valid_604635 = formData.getOrDefault("OptionSettings")
  valid_604635 = validateParameter(valid_604635, JArray, required = false,
                                 default = nil)
  if valid_604635 != nil:
    section.add "OptionSettings", valid_604635
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_604636 = formData.getOrDefault("ApplicationName")
  valid_604636 = validateParameter(valid_604636, JString, required = true,
                                 default = nil)
  if valid_604636 != nil:
    section.add "ApplicationName", valid_604636
  var valid_604637 = formData.getOrDefault("TemplateName")
  valid_604637 = validateParameter(valid_604637, JString, required = true,
                                 default = nil)
  if valid_604637 != nil:
    section.add "TemplateName", valid_604637
  var valid_604638 = formData.getOrDefault("Description")
  valid_604638 = validateParameter(valid_604638, JString, required = false,
                                 default = nil)
  if valid_604638 != nil:
    section.add "Description", valid_604638
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604639: Call_PostUpdateConfigurationTemplate_604622;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Updates the specified configuration template to have the specified properties or configuration option values.</p> <note> <p>If a property (for example, <code>ApplicationName</code>) is not provided, its value remains unchanged. To clear such properties, specify an empty string.</p> </note> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> </ul>
  ## 
  let valid = call_604639.validator(path, query, header, formData, body)
  let scheme = call_604639.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604639.url(scheme.get, call_604639.host, call_604639.base,
                         call_604639.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604639, url, valid)

proc call*(call_604640: Call_PostUpdateConfigurationTemplate_604622;
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
  var query_604641 = newJObject()
  var formData_604642 = newJObject()
  if OptionsToRemove != nil:
    formData_604642.add "OptionsToRemove", OptionsToRemove
  if OptionSettings != nil:
    formData_604642.add "OptionSettings", OptionSettings
  add(query_604641, "Action", newJString(Action))
  add(formData_604642, "ApplicationName", newJString(ApplicationName))
  add(formData_604642, "TemplateName", newJString(TemplateName))
  add(query_604641, "Version", newJString(Version))
  add(formData_604642, "Description", newJString(Description))
  result = call_604640.call(nil, query_604641, nil, formData_604642, nil)

var postUpdateConfigurationTemplate* = Call_PostUpdateConfigurationTemplate_604622(
    name: "postUpdateConfigurationTemplate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateConfigurationTemplate",
    validator: validate_PostUpdateConfigurationTemplate_604623, base: "/",
    url: url_PostUpdateConfigurationTemplate_604624,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateConfigurationTemplate_604602 = ref object of OpenApiRestCall_602467
proc url_GetUpdateConfigurationTemplate_604604(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateConfigurationTemplate_604603(path: JsonNode;
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
  var valid_604605 = query.getOrDefault("ApplicationName")
  valid_604605 = validateParameter(valid_604605, JString, required = true,
                                 default = nil)
  if valid_604605 != nil:
    section.add "ApplicationName", valid_604605
  var valid_604606 = query.getOrDefault("Description")
  valid_604606 = validateParameter(valid_604606, JString, required = false,
                                 default = nil)
  if valid_604606 != nil:
    section.add "Description", valid_604606
  var valid_604607 = query.getOrDefault("OptionsToRemove")
  valid_604607 = validateParameter(valid_604607, JArray, required = false,
                                 default = nil)
  if valid_604607 != nil:
    section.add "OptionsToRemove", valid_604607
  var valid_604608 = query.getOrDefault("Action")
  valid_604608 = validateParameter(valid_604608, JString, required = true, default = newJString(
      "UpdateConfigurationTemplate"))
  if valid_604608 != nil:
    section.add "Action", valid_604608
  var valid_604609 = query.getOrDefault("TemplateName")
  valid_604609 = validateParameter(valid_604609, JString, required = true,
                                 default = nil)
  if valid_604609 != nil:
    section.add "TemplateName", valid_604609
  var valid_604610 = query.getOrDefault("OptionSettings")
  valid_604610 = validateParameter(valid_604610, JArray, required = false,
                                 default = nil)
  if valid_604610 != nil:
    section.add "OptionSettings", valid_604610
  var valid_604611 = query.getOrDefault("Version")
  valid_604611 = validateParameter(valid_604611, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604611 != nil:
    section.add "Version", valid_604611
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
  var valid_604612 = header.getOrDefault("X-Amz-Date")
  valid_604612 = validateParameter(valid_604612, JString, required = false,
                                 default = nil)
  if valid_604612 != nil:
    section.add "X-Amz-Date", valid_604612
  var valid_604613 = header.getOrDefault("X-Amz-Security-Token")
  valid_604613 = validateParameter(valid_604613, JString, required = false,
                                 default = nil)
  if valid_604613 != nil:
    section.add "X-Amz-Security-Token", valid_604613
  var valid_604614 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604614 = validateParameter(valid_604614, JString, required = false,
                                 default = nil)
  if valid_604614 != nil:
    section.add "X-Amz-Content-Sha256", valid_604614
  var valid_604615 = header.getOrDefault("X-Amz-Algorithm")
  valid_604615 = validateParameter(valid_604615, JString, required = false,
                                 default = nil)
  if valid_604615 != nil:
    section.add "X-Amz-Algorithm", valid_604615
  var valid_604616 = header.getOrDefault("X-Amz-Signature")
  valid_604616 = validateParameter(valid_604616, JString, required = false,
                                 default = nil)
  if valid_604616 != nil:
    section.add "X-Amz-Signature", valid_604616
  var valid_604617 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604617 = validateParameter(valid_604617, JString, required = false,
                                 default = nil)
  if valid_604617 != nil:
    section.add "X-Amz-SignedHeaders", valid_604617
  var valid_604618 = header.getOrDefault("X-Amz-Credential")
  valid_604618 = validateParameter(valid_604618, JString, required = false,
                                 default = nil)
  if valid_604618 != nil:
    section.add "X-Amz-Credential", valid_604618
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604619: Call_GetUpdateConfigurationTemplate_604602; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified configuration template to have the specified properties or configuration option values.</p> <note> <p>If a property (for example, <code>ApplicationName</code>) is not provided, its value remains unchanged. To clear such properties, specify an empty string.</p> </note> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> </ul>
  ## 
  let valid = call_604619.validator(path, query, header, formData, body)
  let scheme = call_604619.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604619.url(scheme.get, call_604619.host, call_604619.base,
                         call_604619.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604619, url, valid)

proc call*(call_604620: Call_GetUpdateConfigurationTemplate_604602;
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
  var query_604621 = newJObject()
  add(query_604621, "ApplicationName", newJString(ApplicationName))
  add(query_604621, "Description", newJString(Description))
  if OptionsToRemove != nil:
    query_604621.add "OptionsToRemove", OptionsToRemove
  add(query_604621, "Action", newJString(Action))
  add(query_604621, "TemplateName", newJString(TemplateName))
  if OptionSettings != nil:
    query_604621.add "OptionSettings", OptionSettings
  add(query_604621, "Version", newJString(Version))
  result = call_604620.call(nil, query_604621, nil, nil, nil)

var getUpdateConfigurationTemplate* = Call_GetUpdateConfigurationTemplate_604602(
    name: "getUpdateConfigurationTemplate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateConfigurationTemplate",
    validator: validate_GetUpdateConfigurationTemplate_604603, base: "/",
    url: url_GetUpdateConfigurationTemplate_604604,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateEnvironment_604672 = ref object of OpenApiRestCall_602467
proc url_PostUpdateEnvironment_604674(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateEnvironment_604673(path: JsonNode; query: JsonNode;
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
  var valid_604675 = query.getOrDefault("Action")
  valid_604675 = validateParameter(valid_604675, JString, required = true,
                                 default = newJString("UpdateEnvironment"))
  if valid_604675 != nil:
    section.add "Action", valid_604675
  var valid_604676 = query.getOrDefault("Version")
  valid_604676 = validateParameter(valid_604676, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604676 != nil:
    section.add "Version", valid_604676
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
  var valid_604677 = header.getOrDefault("X-Amz-Date")
  valid_604677 = validateParameter(valid_604677, JString, required = false,
                                 default = nil)
  if valid_604677 != nil:
    section.add "X-Amz-Date", valid_604677
  var valid_604678 = header.getOrDefault("X-Amz-Security-Token")
  valid_604678 = validateParameter(valid_604678, JString, required = false,
                                 default = nil)
  if valid_604678 != nil:
    section.add "X-Amz-Security-Token", valid_604678
  var valid_604679 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604679 = validateParameter(valid_604679, JString, required = false,
                                 default = nil)
  if valid_604679 != nil:
    section.add "X-Amz-Content-Sha256", valid_604679
  var valid_604680 = header.getOrDefault("X-Amz-Algorithm")
  valid_604680 = validateParameter(valid_604680, JString, required = false,
                                 default = nil)
  if valid_604680 != nil:
    section.add "X-Amz-Algorithm", valid_604680
  var valid_604681 = header.getOrDefault("X-Amz-Signature")
  valid_604681 = validateParameter(valid_604681, JString, required = false,
                                 default = nil)
  if valid_604681 != nil:
    section.add "X-Amz-Signature", valid_604681
  var valid_604682 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604682 = validateParameter(valid_604682, JString, required = false,
                                 default = nil)
  if valid_604682 != nil:
    section.add "X-Amz-SignedHeaders", valid_604682
  var valid_604683 = header.getOrDefault("X-Amz-Credential")
  valid_604683 = validateParameter(valid_604683, JString, required = false,
                                 default = nil)
  if valid_604683 != nil:
    section.add "X-Amz-Credential", valid_604683
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
  var valid_604684 = formData.getOrDefault("Tier.Name")
  valid_604684 = validateParameter(valid_604684, JString, required = false,
                                 default = nil)
  if valid_604684 != nil:
    section.add "Tier.Name", valid_604684
  var valid_604685 = formData.getOrDefault("OptionsToRemove")
  valid_604685 = validateParameter(valid_604685, JArray, required = false,
                                 default = nil)
  if valid_604685 != nil:
    section.add "OptionsToRemove", valid_604685
  var valid_604686 = formData.getOrDefault("VersionLabel")
  valid_604686 = validateParameter(valid_604686, JString, required = false,
                                 default = nil)
  if valid_604686 != nil:
    section.add "VersionLabel", valid_604686
  var valid_604687 = formData.getOrDefault("OptionSettings")
  valid_604687 = validateParameter(valid_604687, JArray, required = false,
                                 default = nil)
  if valid_604687 != nil:
    section.add "OptionSettings", valid_604687
  var valid_604688 = formData.getOrDefault("GroupName")
  valid_604688 = validateParameter(valid_604688, JString, required = false,
                                 default = nil)
  if valid_604688 != nil:
    section.add "GroupName", valid_604688
  var valid_604689 = formData.getOrDefault("SolutionStackName")
  valid_604689 = validateParameter(valid_604689, JString, required = false,
                                 default = nil)
  if valid_604689 != nil:
    section.add "SolutionStackName", valid_604689
  var valid_604690 = formData.getOrDefault("EnvironmentId")
  valid_604690 = validateParameter(valid_604690, JString, required = false,
                                 default = nil)
  if valid_604690 != nil:
    section.add "EnvironmentId", valid_604690
  var valid_604691 = formData.getOrDefault("EnvironmentName")
  valid_604691 = validateParameter(valid_604691, JString, required = false,
                                 default = nil)
  if valid_604691 != nil:
    section.add "EnvironmentName", valid_604691
  var valid_604692 = formData.getOrDefault("Tier.Type")
  valid_604692 = validateParameter(valid_604692, JString, required = false,
                                 default = nil)
  if valid_604692 != nil:
    section.add "Tier.Type", valid_604692
  var valid_604693 = formData.getOrDefault("ApplicationName")
  valid_604693 = validateParameter(valid_604693, JString, required = false,
                                 default = nil)
  if valid_604693 != nil:
    section.add "ApplicationName", valid_604693
  var valid_604694 = formData.getOrDefault("PlatformArn")
  valid_604694 = validateParameter(valid_604694, JString, required = false,
                                 default = nil)
  if valid_604694 != nil:
    section.add "PlatformArn", valid_604694
  var valid_604695 = formData.getOrDefault("TemplateName")
  valid_604695 = validateParameter(valid_604695, JString, required = false,
                                 default = nil)
  if valid_604695 != nil:
    section.add "TemplateName", valid_604695
  var valid_604696 = formData.getOrDefault("Description")
  valid_604696 = validateParameter(valid_604696, JString, required = false,
                                 default = nil)
  if valid_604696 != nil:
    section.add "Description", valid_604696
  var valid_604697 = formData.getOrDefault("Tier.Version")
  valid_604697 = validateParameter(valid_604697, JString, required = false,
                                 default = nil)
  if valid_604697 != nil:
    section.add "Tier.Version", valid_604697
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604698: Call_PostUpdateEnvironment_604672; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the environment description, deploys a new application version, updates the configuration settings to an entirely new configuration template, or updates select configuration option values in the running environment.</p> <p> Attempting to update both the release and configuration is not allowed and AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. </p> <p> When updating the configuration settings to a new template or individual settings, a draft configuration is created and <a>DescribeConfigurationSettings</a> for this environment returns two setting descriptions with different <code>DeploymentStatus</code> values. </p>
  ## 
  let valid = call_604698.validator(path, query, header, formData, body)
  let scheme = call_604698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604698.url(scheme.get, call_604698.host, call_604698.base,
                         call_604698.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604698, url, valid)

proc call*(call_604699: Call_PostUpdateEnvironment_604672; TierName: string = "";
          OptionsToRemove: JsonNode = nil; VersionLabel: string = "";
          OptionSettings: JsonNode = nil; GroupName: string = "";
          SolutionStackName: string = ""; EnvironmentId: string = "";
          EnvironmentName: string = ""; TierType: string = "";
          Action: string = "UpdateEnvironment"; ApplicationName: string = "";
          PlatformArn: string = ""; TemplateName: string = "";
          Version: string = "2010-12-01"; Description: string = "";
          TierVersion: string = ""): Recallable =
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
  var query_604700 = newJObject()
  var formData_604701 = newJObject()
  add(formData_604701, "Tier.Name", newJString(TierName))
  if OptionsToRemove != nil:
    formData_604701.add "OptionsToRemove", OptionsToRemove
  add(formData_604701, "VersionLabel", newJString(VersionLabel))
  if OptionSettings != nil:
    formData_604701.add "OptionSettings", OptionSettings
  add(formData_604701, "GroupName", newJString(GroupName))
  add(formData_604701, "SolutionStackName", newJString(SolutionStackName))
  add(formData_604701, "EnvironmentId", newJString(EnvironmentId))
  add(formData_604701, "EnvironmentName", newJString(EnvironmentName))
  add(formData_604701, "Tier.Type", newJString(TierType))
  add(query_604700, "Action", newJString(Action))
  add(formData_604701, "ApplicationName", newJString(ApplicationName))
  add(formData_604701, "PlatformArn", newJString(PlatformArn))
  add(formData_604701, "TemplateName", newJString(TemplateName))
  add(query_604700, "Version", newJString(Version))
  add(formData_604701, "Description", newJString(Description))
  add(formData_604701, "Tier.Version", newJString(TierVersion))
  result = call_604699.call(nil, query_604700, nil, formData_604701, nil)

var postUpdateEnvironment* = Call_PostUpdateEnvironment_604672(
    name: "postUpdateEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateEnvironment",
    validator: validate_PostUpdateEnvironment_604673, base: "/",
    url: url_PostUpdateEnvironment_604674, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateEnvironment_604643 = ref object of OpenApiRestCall_602467
proc url_GetUpdateEnvironment_604645(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateEnvironment_604644(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_604646 = query.getOrDefault("Tier.Name")
  valid_604646 = validateParameter(valid_604646, JString, required = false,
                                 default = nil)
  if valid_604646 != nil:
    section.add "Tier.Name", valid_604646
  var valid_604647 = query.getOrDefault("VersionLabel")
  valid_604647 = validateParameter(valid_604647, JString, required = false,
                                 default = nil)
  if valid_604647 != nil:
    section.add "VersionLabel", valid_604647
  var valid_604648 = query.getOrDefault("ApplicationName")
  valid_604648 = validateParameter(valid_604648, JString, required = false,
                                 default = nil)
  if valid_604648 != nil:
    section.add "ApplicationName", valid_604648
  var valid_604649 = query.getOrDefault("Description")
  valid_604649 = validateParameter(valid_604649, JString, required = false,
                                 default = nil)
  if valid_604649 != nil:
    section.add "Description", valid_604649
  var valid_604650 = query.getOrDefault("OptionsToRemove")
  valid_604650 = validateParameter(valid_604650, JArray, required = false,
                                 default = nil)
  if valid_604650 != nil:
    section.add "OptionsToRemove", valid_604650
  var valid_604651 = query.getOrDefault("PlatformArn")
  valid_604651 = validateParameter(valid_604651, JString, required = false,
                                 default = nil)
  if valid_604651 != nil:
    section.add "PlatformArn", valid_604651
  var valid_604652 = query.getOrDefault("EnvironmentName")
  valid_604652 = validateParameter(valid_604652, JString, required = false,
                                 default = nil)
  if valid_604652 != nil:
    section.add "EnvironmentName", valid_604652
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604653 = query.getOrDefault("Action")
  valid_604653 = validateParameter(valid_604653, JString, required = true,
                                 default = newJString("UpdateEnvironment"))
  if valid_604653 != nil:
    section.add "Action", valid_604653
  var valid_604654 = query.getOrDefault("EnvironmentId")
  valid_604654 = validateParameter(valid_604654, JString, required = false,
                                 default = nil)
  if valid_604654 != nil:
    section.add "EnvironmentId", valid_604654
  var valid_604655 = query.getOrDefault("Tier.Version")
  valid_604655 = validateParameter(valid_604655, JString, required = false,
                                 default = nil)
  if valid_604655 != nil:
    section.add "Tier.Version", valid_604655
  var valid_604656 = query.getOrDefault("SolutionStackName")
  valid_604656 = validateParameter(valid_604656, JString, required = false,
                                 default = nil)
  if valid_604656 != nil:
    section.add "SolutionStackName", valid_604656
  var valid_604657 = query.getOrDefault("TemplateName")
  valid_604657 = validateParameter(valid_604657, JString, required = false,
                                 default = nil)
  if valid_604657 != nil:
    section.add "TemplateName", valid_604657
  var valid_604658 = query.getOrDefault("GroupName")
  valid_604658 = validateParameter(valid_604658, JString, required = false,
                                 default = nil)
  if valid_604658 != nil:
    section.add "GroupName", valid_604658
  var valid_604659 = query.getOrDefault("OptionSettings")
  valid_604659 = validateParameter(valid_604659, JArray, required = false,
                                 default = nil)
  if valid_604659 != nil:
    section.add "OptionSettings", valid_604659
  var valid_604660 = query.getOrDefault("Tier.Type")
  valid_604660 = validateParameter(valid_604660, JString, required = false,
                                 default = nil)
  if valid_604660 != nil:
    section.add "Tier.Type", valid_604660
  var valid_604661 = query.getOrDefault("Version")
  valid_604661 = validateParameter(valid_604661, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604661 != nil:
    section.add "Version", valid_604661
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
  var valid_604662 = header.getOrDefault("X-Amz-Date")
  valid_604662 = validateParameter(valid_604662, JString, required = false,
                                 default = nil)
  if valid_604662 != nil:
    section.add "X-Amz-Date", valid_604662
  var valid_604663 = header.getOrDefault("X-Amz-Security-Token")
  valid_604663 = validateParameter(valid_604663, JString, required = false,
                                 default = nil)
  if valid_604663 != nil:
    section.add "X-Amz-Security-Token", valid_604663
  var valid_604664 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604664 = validateParameter(valid_604664, JString, required = false,
                                 default = nil)
  if valid_604664 != nil:
    section.add "X-Amz-Content-Sha256", valid_604664
  var valid_604665 = header.getOrDefault("X-Amz-Algorithm")
  valid_604665 = validateParameter(valid_604665, JString, required = false,
                                 default = nil)
  if valid_604665 != nil:
    section.add "X-Amz-Algorithm", valid_604665
  var valid_604666 = header.getOrDefault("X-Amz-Signature")
  valid_604666 = validateParameter(valid_604666, JString, required = false,
                                 default = nil)
  if valid_604666 != nil:
    section.add "X-Amz-Signature", valid_604666
  var valid_604667 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604667 = validateParameter(valid_604667, JString, required = false,
                                 default = nil)
  if valid_604667 != nil:
    section.add "X-Amz-SignedHeaders", valid_604667
  var valid_604668 = header.getOrDefault("X-Amz-Credential")
  valid_604668 = validateParameter(valid_604668, JString, required = false,
                                 default = nil)
  if valid_604668 != nil:
    section.add "X-Amz-Credential", valid_604668
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604669: Call_GetUpdateEnvironment_604643; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the environment description, deploys a new application version, updates the configuration settings to an entirely new configuration template, or updates select configuration option values in the running environment.</p> <p> Attempting to update both the release and configuration is not allowed and AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. </p> <p> When updating the configuration settings to a new template or individual settings, a draft configuration is created and <a>DescribeConfigurationSettings</a> for this environment returns two setting descriptions with different <code>DeploymentStatus</code> values. </p>
  ## 
  let valid = call_604669.validator(path, query, header, formData, body)
  let scheme = call_604669.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604669.url(scheme.get, call_604669.host, call_604669.base,
                         call_604669.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604669, url, valid)

proc call*(call_604670: Call_GetUpdateEnvironment_604643; TierName: string = "";
          VersionLabel: string = ""; ApplicationName: string = "";
          Description: string = ""; OptionsToRemove: JsonNode = nil;
          PlatformArn: string = ""; EnvironmentName: string = "";
          Action: string = "UpdateEnvironment"; EnvironmentId: string = "";
          TierVersion: string = ""; SolutionStackName: string = "";
          TemplateName: string = ""; GroupName: string = "";
          OptionSettings: JsonNode = nil; TierType: string = "";
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
  var query_604671 = newJObject()
  add(query_604671, "Tier.Name", newJString(TierName))
  add(query_604671, "VersionLabel", newJString(VersionLabel))
  add(query_604671, "ApplicationName", newJString(ApplicationName))
  add(query_604671, "Description", newJString(Description))
  if OptionsToRemove != nil:
    query_604671.add "OptionsToRemove", OptionsToRemove
  add(query_604671, "PlatformArn", newJString(PlatformArn))
  add(query_604671, "EnvironmentName", newJString(EnvironmentName))
  add(query_604671, "Action", newJString(Action))
  add(query_604671, "EnvironmentId", newJString(EnvironmentId))
  add(query_604671, "Tier.Version", newJString(TierVersion))
  add(query_604671, "SolutionStackName", newJString(SolutionStackName))
  add(query_604671, "TemplateName", newJString(TemplateName))
  add(query_604671, "GroupName", newJString(GroupName))
  if OptionSettings != nil:
    query_604671.add "OptionSettings", OptionSettings
  add(query_604671, "Tier.Type", newJString(TierType))
  add(query_604671, "Version", newJString(Version))
  result = call_604670.call(nil, query_604671, nil, nil, nil)

var getUpdateEnvironment* = Call_GetUpdateEnvironment_604643(
    name: "getUpdateEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateEnvironment",
    validator: validate_GetUpdateEnvironment_604644, base: "/",
    url: url_GetUpdateEnvironment_604645, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateTagsForResource_604720 = ref object of OpenApiRestCall_602467
proc url_PostUpdateTagsForResource_604722(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateTagsForResource_604721(path: JsonNode; query: JsonNode;
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
  var valid_604723 = query.getOrDefault("Action")
  valid_604723 = validateParameter(valid_604723, JString, required = true,
                                 default = newJString("UpdateTagsForResource"))
  if valid_604723 != nil:
    section.add "Action", valid_604723
  var valid_604724 = query.getOrDefault("Version")
  valid_604724 = validateParameter(valid_604724, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604724 != nil:
    section.add "Version", valid_604724
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
  var valid_604725 = header.getOrDefault("X-Amz-Date")
  valid_604725 = validateParameter(valid_604725, JString, required = false,
                                 default = nil)
  if valid_604725 != nil:
    section.add "X-Amz-Date", valid_604725
  var valid_604726 = header.getOrDefault("X-Amz-Security-Token")
  valid_604726 = validateParameter(valid_604726, JString, required = false,
                                 default = nil)
  if valid_604726 != nil:
    section.add "X-Amz-Security-Token", valid_604726
  var valid_604727 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604727 = validateParameter(valid_604727, JString, required = false,
                                 default = nil)
  if valid_604727 != nil:
    section.add "X-Amz-Content-Sha256", valid_604727
  var valid_604728 = header.getOrDefault("X-Amz-Algorithm")
  valid_604728 = validateParameter(valid_604728, JString, required = false,
                                 default = nil)
  if valid_604728 != nil:
    section.add "X-Amz-Algorithm", valid_604728
  var valid_604729 = header.getOrDefault("X-Amz-Signature")
  valid_604729 = validateParameter(valid_604729, JString, required = false,
                                 default = nil)
  if valid_604729 != nil:
    section.add "X-Amz-Signature", valid_604729
  var valid_604730 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604730 = validateParameter(valid_604730, JString, required = false,
                                 default = nil)
  if valid_604730 != nil:
    section.add "X-Amz-SignedHeaders", valid_604730
  var valid_604731 = header.getOrDefault("X-Amz-Credential")
  valid_604731 = validateParameter(valid_604731, JString, required = false,
                                 default = nil)
  if valid_604731 != nil:
    section.add "X-Amz-Credential", valid_604731
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagsToAdd: JArray
  ##            : <p>A list of tags to add or update.</p> <p>If a key of an existing tag is added, the tag's value is updated.</p>
  ##   TagsToRemove: JArray
  ##               : <p>A list of tag keys to remove.</p> <p>If a tag key doesn't exist, it is silently ignored.</p>
  ##   ResourceArn: JString (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce to be updated.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  section = newJObject()
  var valid_604732 = formData.getOrDefault("TagsToAdd")
  valid_604732 = validateParameter(valid_604732, JArray, required = false,
                                 default = nil)
  if valid_604732 != nil:
    section.add "TagsToAdd", valid_604732
  var valid_604733 = formData.getOrDefault("TagsToRemove")
  valid_604733 = validateParameter(valid_604733, JArray, required = false,
                                 default = nil)
  if valid_604733 != nil:
    section.add "TagsToRemove", valid_604733
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArn` field"
  var valid_604734 = formData.getOrDefault("ResourceArn")
  valid_604734 = validateParameter(valid_604734, JString, required = true,
                                 default = nil)
  if valid_604734 != nil:
    section.add "ResourceArn", valid_604734
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604735: Call_PostUpdateTagsForResource_604720; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Update the list of tags applied to an AWS Elastic Beanstalk resource. Two lists can be passed: <code>TagsToAdd</code> for tags to add or update, and <code>TagsToRemove</code>.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p> <p>If you create a custom IAM user policy to control permission to this operation, specify one of the following two virtual actions (or both) instead of the API operation name:</p> <dl> <dt>elasticbeanstalk:AddTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tags to add in the <code>TagsToAdd</code> parameter.</p> </dd> <dt>elasticbeanstalk:RemoveTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tag keys to remove in the <code>TagsToRemove</code> parameter.</p> </dd> </dl> <p>For details about creating a custom user policy, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/AWSHowTo.iam.managed-policies.html#AWSHowTo.iam.policies">Creating a Custom User Policy</a>.</p>
  ## 
  let valid = call_604735.validator(path, query, header, formData, body)
  let scheme = call_604735.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604735.url(scheme.get, call_604735.host, call_604735.base,
                         call_604735.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604735, url, valid)

proc call*(call_604736: Call_PostUpdateTagsForResource_604720; ResourceArn: string;
          TagsToAdd: JsonNode = nil; TagsToRemove: JsonNode = nil;
          Action: string = "UpdateTagsForResource"; Version: string = "2010-12-01"): Recallable =
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
  var query_604737 = newJObject()
  var formData_604738 = newJObject()
  if TagsToAdd != nil:
    formData_604738.add "TagsToAdd", TagsToAdd
  if TagsToRemove != nil:
    formData_604738.add "TagsToRemove", TagsToRemove
  add(query_604737, "Action", newJString(Action))
  add(formData_604738, "ResourceArn", newJString(ResourceArn))
  add(query_604737, "Version", newJString(Version))
  result = call_604736.call(nil, query_604737, nil, formData_604738, nil)

var postUpdateTagsForResource* = Call_PostUpdateTagsForResource_604720(
    name: "postUpdateTagsForResource", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateTagsForResource",
    validator: validate_PostUpdateTagsForResource_604721, base: "/",
    url: url_PostUpdateTagsForResource_604722,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateTagsForResource_604702 = ref object of OpenApiRestCall_602467
proc url_GetUpdateTagsForResource_604704(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateTagsForResource_604703(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_604705 = query.getOrDefault("ResourceArn")
  valid_604705 = validateParameter(valid_604705, JString, required = true,
                                 default = nil)
  if valid_604705 != nil:
    section.add "ResourceArn", valid_604705
  var valid_604706 = query.getOrDefault("Action")
  valid_604706 = validateParameter(valid_604706, JString, required = true,
                                 default = newJString("UpdateTagsForResource"))
  if valid_604706 != nil:
    section.add "Action", valid_604706
  var valid_604707 = query.getOrDefault("TagsToAdd")
  valid_604707 = validateParameter(valid_604707, JArray, required = false,
                                 default = nil)
  if valid_604707 != nil:
    section.add "TagsToAdd", valid_604707
  var valid_604708 = query.getOrDefault("Version")
  valid_604708 = validateParameter(valid_604708, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604708 != nil:
    section.add "Version", valid_604708
  var valid_604709 = query.getOrDefault("TagsToRemove")
  valid_604709 = validateParameter(valid_604709, JArray, required = false,
                                 default = nil)
  if valid_604709 != nil:
    section.add "TagsToRemove", valid_604709
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
  var valid_604710 = header.getOrDefault("X-Amz-Date")
  valid_604710 = validateParameter(valid_604710, JString, required = false,
                                 default = nil)
  if valid_604710 != nil:
    section.add "X-Amz-Date", valid_604710
  var valid_604711 = header.getOrDefault("X-Amz-Security-Token")
  valid_604711 = validateParameter(valid_604711, JString, required = false,
                                 default = nil)
  if valid_604711 != nil:
    section.add "X-Amz-Security-Token", valid_604711
  var valid_604712 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604712 = validateParameter(valid_604712, JString, required = false,
                                 default = nil)
  if valid_604712 != nil:
    section.add "X-Amz-Content-Sha256", valid_604712
  var valid_604713 = header.getOrDefault("X-Amz-Algorithm")
  valid_604713 = validateParameter(valid_604713, JString, required = false,
                                 default = nil)
  if valid_604713 != nil:
    section.add "X-Amz-Algorithm", valid_604713
  var valid_604714 = header.getOrDefault("X-Amz-Signature")
  valid_604714 = validateParameter(valid_604714, JString, required = false,
                                 default = nil)
  if valid_604714 != nil:
    section.add "X-Amz-Signature", valid_604714
  var valid_604715 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604715 = validateParameter(valid_604715, JString, required = false,
                                 default = nil)
  if valid_604715 != nil:
    section.add "X-Amz-SignedHeaders", valid_604715
  var valid_604716 = header.getOrDefault("X-Amz-Credential")
  valid_604716 = validateParameter(valid_604716, JString, required = false,
                                 default = nil)
  if valid_604716 != nil:
    section.add "X-Amz-Credential", valid_604716
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604717: Call_GetUpdateTagsForResource_604702; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Update the list of tags applied to an AWS Elastic Beanstalk resource. Two lists can be passed: <code>TagsToAdd</code> for tags to add or update, and <code>TagsToRemove</code>.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p> <p>If you create a custom IAM user policy to control permission to this operation, specify one of the following two virtual actions (or both) instead of the API operation name:</p> <dl> <dt>elasticbeanstalk:AddTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tags to add in the <code>TagsToAdd</code> parameter.</p> </dd> <dt>elasticbeanstalk:RemoveTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tag keys to remove in the <code>TagsToRemove</code> parameter.</p> </dd> </dl> <p>For details about creating a custom user policy, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/AWSHowTo.iam.managed-policies.html#AWSHowTo.iam.policies">Creating a Custom User Policy</a>.</p>
  ## 
  let valid = call_604717.validator(path, query, header, formData, body)
  let scheme = call_604717.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604717.url(scheme.get, call_604717.host, call_604717.base,
                         call_604717.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604717, url, valid)

proc call*(call_604718: Call_GetUpdateTagsForResource_604702; ResourceArn: string;
          Action: string = "UpdateTagsForResource"; TagsToAdd: JsonNode = nil;
          Version: string = "2010-12-01"; TagsToRemove: JsonNode = nil): Recallable =
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
  var query_604719 = newJObject()
  add(query_604719, "ResourceArn", newJString(ResourceArn))
  add(query_604719, "Action", newJString(Action))
  if TagsToAdd != nil:
    query_604719.add "TagsToAdd", TagsToAdd
  add(query_604719, "Version", newJString(Version))
  if TagsToRemove != nil:
    query_604719.add "TagsToRemove", TagsToRemove
  result = call_604718.call(nil, query_604719, nil, nil, nil)

var getUpdateTagsForResource* = Call_GetUpdateTagsForResource_604702(
    name: "getUpdateTagsForResource", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateTagsForResource",
    validator: validate_GetUpdateTagsForResource_604703, base: "/",
    url: url_GetUpdateTagsForResource_604704, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostValidateConfigurationSettings_604758 = ref object of OpenApiRestCall_602467
proc url_PostValidateConfigurationSettings_604760(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostValidateConfigurationSettings_604759(path: JsonNode;
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
  var valid_604761 = query.getOrDefault("Action")
  valid_604761 = validateParameter(valid_604761, JString, required = true, default = newJString(
      "ValidateConfigurationSettings"))
  if valid_604761 != nil:
    section.add "Action", valid_604761
  var valid_604762 = query.getOrDefault("Version")
  valid_604762 = validateParameter(valid_604762, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604762 != nil:
    section.add "Version", valid_604762
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
  var valid_604763 = header.getOrDefault("X-Amz-Date")
  valid_604763 = validateParameter(valid_604763, JString, required = false,
                                 default = nil)
  if valid_604763 != nil:
    section.add "X-Amz-Date", valid_604763
  var valid_604764 = header.getOrDefault("X-Amz-Security-Token")
  valid_604764 = validateParameter(valid_604764, JString, required = false,
                                 default = nil)
  if valid_604764 != nil:
    section.add "X-Amz-Security-Token", valid_604764
  var valid_604765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604765 = validateParameter(valid_604765, JString, required = false,
                                 default = nil)
  if valid_604765 != nil:
    section.add "X-Amz-Content-Sha256", valid_604765
  var valid_604766 = header.getOrDefault("X-Amz-Algorithm")
  valid_604766 = validateParameter(valid_604766, JString, required = false,
                                 default = nil)
  if valid_604766 != nil:
    section.add "X-Amz-Algorithm", valid_604766
  var valid_604767 = header.getOrDefault("X-Amz-Signature")
  valid_604767 = validateParameter(valid_604767, JString, required = false,
                                 default = nil)
  if valid_604767 != nil:
    section.add "X-Amz-Signature", valid_604767
  var valid_604768 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604768 = validateParameter(valid_604768, JString, required = false,
                                 default = nil)
  if valid_604768 != nil:
    section.add "X-Amz-SignedHeaders", valid_604768
  var valid_604769 = header.getOrDefault("X-Amz-Credential")
  valid_604769 = validateParameter(valid_604769, JString, required = false,
                                 default = nil)
  if valid_604769 != nil:
    section.add "X-Amz-Credential", valid_604769
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
  var valid_604770 = formData.getOrDefault("OptionSettings")
  valid_604770 = validateParameter(valid_604770, JArray, required = true, default = nil)
  if valid_604770 != nil:
    section.add "OptionSettings", valid_604770
  var valid_604771 = formData.getOrDefault("EnvironmentName")
  valid_604771 = validateParameter(valid_604771, JString, required = false,
                                 default = nil)
  if valid_604771 != nil:
    section.add "EnvironmentName", valid_604771
  var valid_604772 = formData.getOrDefault("ApplicationName")
  valid_604772 = validateParameter(valid_604772, JString, required = true,
                                 default = nil)
  if valid_604772 != nil:
    section.add "ApplicationName", valid_604772
  var valid_604773 = formData.getOrDefault("TemplateName")
  valid_604773 = validateParameter(valid_604773, JString, required = false,
                                 default = nil)
  if valid_604773 != nil:
    section.add "TemplateName", valid_604773
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604774: Call_PostValidateConfigurationSettings_604758;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Takes a set of configuration settings and either a configuration template or environment, and determines whether those values are valid.</p> <p>This action returns a list of messages indicating any errors or warnings associated with the selection of option values.</p>
  ## 
  let valid = call_604774.validator(path, query, header, formData, body)
  let scheme = call_604774.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604774.url(scheme.get, call_604774.host, call_604774.base,
                         call_604774.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604774, url, valid)

proc call*(call_604775: Call_PostValidateConfigurationSettings_604758;
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
  var query_604776 = newJObject()
  var formData_604777 = newJObject()
  if OptionSettings != nil:
    formData_604777.add "OptionSettings", OptionSettings
  add(formData_604777, "EnvironmentName", newJString(EnvironmentName))
  add(query_604776, "Action", newJString(Action))
  add(formData_604777, "ApplicationName", newJString(ApplicationName))
  add(formData_604777, "TemplateName", newJString(TemplateName))
  add(query_604776, "Version", newJString(Version))
  result = call_604775.call(nil, query_604776, nil, formData_604777, nil)

var postValidateConfigurationSettings* = Call_PostValidateConfigurationSettings_604758(
    name: "postValidateConfigurationSettings", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ValidateConfigurationSettings",
    validator: validate_PostValidateConfigurationSettings_604759, base: "/",
    url: url_PostValidateConfigurationSettings_604760,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetValidateConfigurationSettings_604739 = ref object of OpenApiRestCall_602467
proc url_GetValidateConfigurationSettings_604741(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetValidateConfigurationSettings_604740(path: JsonNode;
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
  var valid_604742 = query.getOrDefault("ApplicationName")
  valid_604742 = validateParameter(valid_604742, JString, required = true,
                                 default = nil)
  if valid_604742 != nil:
    section.add "ApplicationName", valid_604742
  var valid_604743 = query.getOrDefault("EnvironmentName")
  valid_604743 = validateParameter(valid_604743, JString, required = false,
                                 default = nil)
  if valid_604743 != nil:
    section.add "EnvironmentName", valid_604743
  var valid_604744 = query.getOrDefault("Action")
  valid_604744 = validateParameter(valid_604744, JString, required = true, default = newJString(
      "ValidateConfigurationSettings"))
  if valid_604744 != nil:
    section.add "Action", valid_604744
  var valid_604745 = query.getOrDefault("TemplateName")
  valid_604745 = validateParameter(valid_604745, JString, required = false,
                                 default = nil)
  if valid_604745 != nil:
    section.add "TemplateName", valid_604745
  var valid_604746 = query.getOrDefault("OptionSettings")
  valid_604746 = validateParameter(valid_604746, JArray, required = true, default = nil)
  if valid_604746 != nil:
    section.add "OptionSettings", valid_604746
  var valid_604747 = query.getOrDefault("Version")
  valid_604747 = validateParameter(valid_604747, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604747 != nil:
    section.add "Version", valid_604747
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
  var valid_604748 = header.getOrDefault("X-Amz-Date")
  valid_604748 = validateParameter(valid_604748, JString, required = false,
                                 default = nil)
  if valid_604748 != nil:
    section.add "X-Amz-Date", valid_604748
  var valid_604749 = header.getOrDefault("X-Amz-Security-Token")
  valid_604749 = validateParameter(valid_604749, JString, required = false,
                                 default = nil)
  if valid_604749 != nil:
    section.add "X-Amz-Security-Token", valid_604749
  var valid_604750 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604750 = validateParameter(valid_604750, JString, required = false,
                                 default = nil)
  if valid_604750 != nil:
    section.add "X-Amz-Content-Sha256", valid_604750
  var valid_604751 = header.getOrDefault("X-Amz-Algorithm")
  valid_604751 = validateParameter(valid_604751, JString, required = false,
                                 default = nil)
  if valid_604751 != nil:
    section.add "X-Amz-Algorithm", valid_604751
  var valid_604752 = header.getOrDefault("X-Amz-Signature")
  valid_604752 = validateParameter(valid_604752, JString, required = false,
                                 default = nil)
  if valid_604752 != nil:
    section.add "X-Amz-Signature", valid_604752
  var valid_604753 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604753 = validateParameter(valid_604753, JString, required = false,
                                 default = nil)
  if valid_604753 != nil:
    section.add "X-Amz-SignedHeaders", valid_604753
  var valid_604754 = header.getOrDefault("X-Amz-Credential")
  valid_604754 = validateParameter(valid_604754, JString, required = false,
                                 default = nil)
  if valid_604754 != nil:
    section.add "X-Amz-Credential", valid_604754
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604755: Call_GetValidateConfigurationSettings_604739;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Takes a set of configuration settings and either a configuration template or environment, and determines whether those values are valid.</p> <p>This action returns a list of messages indicating any errors or warnings associated with the selection of option values.</p>
  ## 
  let valid = call_604755.validator(path, query, header, formData, body)
  let scheme = call_604755.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604755.url(scheme.get, call_604755.host, call_604755.base,
                         call_604755.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604755, url, valid)

proc call*(call_604756: Call_GetValidateConfigurationSettings_604739;
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
  var query_604757 = newJObject()
  add(query_604757, "ApplicationName", newJString(ApplicationName))
  add(query_604757, "EnvironmentName", newJString(EnvironmentName))
  add(query_604757, "Action", newJString(Action))
  add(query_604757, "TemplateName", newJString(TemplateName))
  if OptionSettings != nil:
    query_604757.add "OptionSettings", OptionSettings
  add(query_604757, "Version", newJString(Version))
  result = call_604756.call(nil, query_604757, nil, nil, nil)

var getValidateConfigurationSettings* = Call_GetValidateConfigurationSettings_604739(
    name: "getValidateConfigurationSettings", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ValidateConfigurationSettings",
    validator: validate_GetValidateConfigurationSettings_604740, base: "/",
    url: url_GetValidateConfigurationSettings_604741,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

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
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)

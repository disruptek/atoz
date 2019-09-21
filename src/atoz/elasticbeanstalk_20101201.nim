
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_602434 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602434](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602434): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_PostAbortEnvironmentUpdate_603043 = ref object of OpenApiRestCall_602434
proc url_PostAbortEnvironmentUpdate_603045(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostAbortEnvironmentUpdate_603044(path: JsonNode; query: JsonNode;
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
  var valid_603046 = query.getOrDefault("Action")
  valid_603046 = validateParameter(valid_603046, JString, required = true,
                                 default = newJString("AbortEnvironmentUpdate"))
  if valid_603046 != nil:
    section.add "Action", valid_603046
  var valid_603047 = query.getOrDefault("Version")
  valid_603047 = validateParameter(valid_603047, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603047 != nil:
    section.add "Version", valid_603047
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
  var valid_603048 = header.getOrDefault("X-Amz-Date")
  valid_603048 = validateParameter(valid_603048, JString, required = false,
                                 default = nil)
  if valid_603048 != nil:
    section.add "X-Amz-Date", valid_603048
  var valid_603049 = header.getOrDefault("X-Amz-Security-Token")
  valid_603049 = validateParameter(valid_603049, JString, required = false,
                                 default = nil)
  if valid_603049 != nil:
    section.add "X-Amz-Security-Token", valid_603049
  var valid_603050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603050 = validateParameter(valid_603050, JString, required = false,
                                 default = nil)
  if valid_603050 != nil:
    section.add "X-Amz-Content-Sha256", valid_603050
  var valid_603051 = header.getOrDefault("X-Amz-Algorithm")
  valid_603051 = validateParameter(valid_603051, JString, required = false,
                                 default = nil)
  if valid_603051 != nil:
    section.add "X-Amz-Algorithm", valid_603051
  var valid_603052 = header.getOrDefault("X-Amz-Signature")
  valid_603052 = validateParameter(valid_603052, JString, required = false,
                                 default = nil)
  if valid_603052 != nil:
    section.add "X-Amz-Signature", valid_603052
  var valid_603053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603053 = validateParameter(valid_603053, JString, required = false,
                                 default = nil)
  if valid_603053 != nil:
    section.add "X-Amz-SignedHeaders", valid_603053
  var valid_603054 = header.getOrDefault("X-Amz-Credential")
  valid_603054 = validateParameter(valid_603054, JString, required = false,
                                 default = nil)
  if valid_603054 != nil:
    section.add "X-Amz-Credential", valid_603054
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentId: JString
  ##                : This specifies the ID of the environment with the in-progress update that you want to cancel.
  ##   EnvironmentName: JString
  ##                  : This specifies the name of the environment with the in-progress update that you want to cancel.
  section = newJObject()
  var valid_603055 = formData.getOrDefault("EnvironmentId")
  valid_603055 = validateParameter(valid_603055, JString, required = false,
                                 default = nil)
  if valid_603055 != nil:
    section.add "EnvironmentId", valid_603055
  var valid_603056 = formData.getOrDefault("EnvironmentName")
  valid_603056 = validateParameter(valid_603056, JString, required = false,
                                 default = nil)
  if valid_603056 != nil:
    section.add "EnvironmentName", valid_603056
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603057: Call_PostAbortEnvironmentUpdate_603043; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels in-progress environment configuration update or application version deployment.
  ## 
  let valid = call_603057.validator(path, query, header, formData, body)
  let scheme = call_603057.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603057.url(scheme.get, call_603057.host, call_603057.base,
                         call_603057.route, valid.getOrDefault("path"))
  result = hook(call_603057, url, valid)

proc call*(call_603058: Call_PostAbortEnvironmentUpdate_603043;
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
  var query_603059 = newJObject()
  var formData_603060 = newJObject()
  add(formData_603060, "EnvironmentId", newJString(EnvironmentId))
  add(formData_603060, "EnvironmentName", newJString(EnvironmentName))
  add(query_603059, "Action", newJString(Action))
  add(query_603059, "Version", newJString(Version))
  result = call_603058.call(nil, query_603059, nil, formData_603060, nil)

var postAbortEnvironmentUpdate* = Call_PostAbortEnvironmentUpdate_603043(
    name: "postAbortEnvironmentUpdate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=AbortEnvironmentUpdate",
    validator: validate_PostAbortEnvironmentUpdate_603044, base: "/",
    url: url_PostAbortEnvironmentUpdate_603045,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAbortEnvironmentUpdate_602771 = ref object of OpenApiRestCall_602434
proc url_GetAbortEnvironmentUpdate_602773(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAbortEnvironmentUpdate_602772(path: JsonNode; query: JsonNode;
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
  var valid_602885 = query.getOrDefault("EnvironmentName")
  valid_602885 = validateParameter(valid_602885, JString, required = false,
                                 default = nil)
  if valid_602885 != nil:
    section.add "EnvironmentName", valid_602885
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602899 = query.getOrDefault("Action")
  valid_602899 = validateParameter(valid_602899, JString, required = true,
                                 default = newJString("AbortEnvironmentUpdate"))
  if valid_602899 != nil:
    section.add "Action", valid_602899
  var valid_602900 = query.getOrDefault("EnvironmentId")
  valid_602900 = validateParameter(valid_602900, JString, required = false,
                                 default = nil)
  if valid_602900 != nil:
    section.add "EnvironmentId", valid_602900
  var valid_602901 = query.getOrDefault("Version")
  valid_602901 = validateParameter(valid_602901, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602901 != nil:
    section.add "Version", valid_602901
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
  var valid_602902 = header.getOrDefault("X-Amz-Date")
  valid_602902 = validateParameter(valid_602902, JString, required = false,
                                 default = nil)
  if valid_602902 != nil:
    section.add "X-Amz-Date", valid_602902
  var valid_602903 = header.getOrDefault("X-Amz-Security-Token")
  valid_602903 = validateParameter(valid_602903, JString, required = false,
                                 default = nil)
  if valid_602903 != nil:
    section.add "X-Amz-Security-Token", valid_602903
  var valid_602904 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602904 = validateParameter(valid_602904, JString, required = false,
                                 default = nil)
  if valid_602904 != nil:
    section.add "X-Amz-Content-Sha256", valid_602904
  var valid_602905 = header.getOrDefault("X-Amz-Algorithm")
  valid_602905 = validateParameter(valid_602905, JString, required = false,
                                 default = nil)
  if valid_602905 != nil:
    section.add "X-Amz-Algorithm", valid_602905
  var valid_602906 = header.getOrDefault("X-Amz-Signature")
  valid_602906 = validateParameter(valid_602906, JString, required = false,
                                 default = nil)
  if valid_602906 != nil:
    section.add "X-Amz-Signature", valid_602906
  var valid_602907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602907 = validateParameter(valid_602907, JString, required = false,
                                 default = nil)
  if valid_602907 != nil:
    section.add "X-Amz-SignedHeaders", valid_602907
  var valid_602908 = header.getOrDefault("X-Amz-Credential")
  valid_602908 = validateParameter(valid_602908, JString, required = false,
                                 default = nil)
  if valid_602908 != nil:
    section.add "X-Amz-Credential", valid_602908
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602931: Call_GetAbortEnvironmentUpdate_602771; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels in-progress environment configuration update or application version deployment.
  ## 
  let valid = call_602931.validator(path, query, header, formData, body)
  let scheme = call_602931.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602931.url(scheme.get, call_602931.host, call_602931.base,
                         call_602931.route, valid.getOrDefault("path"))
  result = hook(call_602931, url, valid)

proc call*(call_603002: Call_GetAbortEnvironmentUpdate_602771;
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
  var query_603003 = newJObject()
  add(query_603003, "EnvironmentName", newJString(EnvironmentName))
  add(query_603003, "Action", newJString(Action))
  add(query_603003, "EnvironmentId", newJString(EnvironmentId))
  add(query_603003, "Version", newJString(Version))
  result = call_603002.call(nil, query_603003, nil, nil, nil)

var getAbortEnvironmentUpdate* = Call_GetAbortEnvironmentUpdate_602771(
    name: "getAbortEnvironmentUpdate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=AbortEnvironmentUpdate",
    validator: validate_GetAbortEnvironmentUpdate_602772, base: "/",
    url: url_GetAbortEnvironmentUpdate_602773,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostApplyEnvironmentManagedAction_603079 = ref object of OpenApiRestCall_602434
proc url_PostApplyEnvironmentManagedAction_603081(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostApplyEnvironmentManagedAction_603080(path: JsonNode;
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
  var valid_603082 = query.getOrDefault("Action")
  valid_603082 = validateParameter(valid_603082, JString, required = true, default = newJString(
      "ApplyEnvironmentManagedAction"))
  if valid_603082 != nil:
    section.add "Action", valid_603082
  var valid_603083 = query.getOrDefault("Version")
  valid_603083 = validateParameter(valid_603083, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603083 != nil:
    section.add "Version", valid_603083
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
  var valid_603084 = header.getOrDefault("X-Amz-Date")
  valid_603084 = validateParameter(valid_603084, JString, required = false,
                                 default = nil)
  if valid_603084 != nil:
    section.add "X-Amz-Date", valid_603084
  var valid_603085 = header.getOrDefault("X-Amz-Security-Token")
  valid_603085 = validateParameter(valid_603085, JString, required = false,
                                 default = nil)
  if valid_603085 != nil:
    section.add "X-Amz-Security-Token", valid_603085
  var valid_603086 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603086 = validateParameter(valid_603086, JString, required = false,
                                 default = nil)
  if valid_603086 != nil:
    section.add "X-Amz-Content-Sha256", valid_603086
  var valid_603087 = header.getOrDefault("X-Amz-Algorithm")
  valid_603087 = validateParameter(valid_603087, JString, required = false,
                                 default = nil)
  if valid_603087 != nil:
    section.add "X-Amz-Algorithm", valid_603087
  var valid_603088 = header.getOrDefault("X-Amz-Signature")
  valid_603088 = validateParameter(valid_603088, JString, required = false,
                                 default = nil)
  if valid_603088 != nil:
    section.add "X-Amz-Signature", valid_603088
  var valid_603089 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603089 = validateParameter(valid_603089, JString, required = false,
                                 default = nil)
  if valid_603089 != nil:
    section.add "X-Amz-SignedHeaders", valid_603089
  var valid_603090 = header.getOrDefault("X-Amz-Credential")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-Credential", valid_603090
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentId: JString
  ##                : The environment ID of the target environment.
  ##   EnvironmentName: JString
  ##                  : The name of the target environment.
  ##   ActionId: JString (required)
  ##           : The action ID of the scheduled managed action to execute.
  section = newJObject()
  var valid_603091 = formData.getOrDefault("EnvironmentId")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "EnvironmentId", valid_603091
  var valid_603092 = formData.getOrDefault("EnvironmentName")
  valid_603092 = validateParameter(valid_603092, JString, required = false,
                                 default = nil)
  if valid_603092 != nil:
    section.add "EnvironmentName", valid_603092
  assert formData != nil,
        "formData argument is necessary due to required `ActionId` field"
  var valid_603093 = formData.getOrDefault("ActionId")
  valid_603093 = validateParameter(valid_603093, JString, required = true,
                                 default = nil)
  if valid_603093 != nil:
    section.add "ActionId", valid_603093
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603094: Call_PostApplyEnvironmentManagedAction_603079;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Applies a scheduled managed action immediately. A managed action can be applied only if its status is <code>Scheduled</code>. Get the status and action ID of a managed action with <a>DescribeEnvironmentManagedActions</a>.
  ## 
  let valid = call_603094.validator(path, query, header, formData, body)
  let scheme = call_603094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603094.url(scheme.get, call_603094.host, call_603094.base,
                         call_603094.route, valid.getOrDefault("path"))
  result = hook(call_603094, url, valid)

proc call*(call_603095: Call_PostApplyEnvironmentManagedAction_603079;
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
  var query_603096 = newJObject()
  var formData_603097 = newJObject()
  add(formData_603097, "EnvironmentId", newJString(EnvironmentId))
  add(formData_603097, "EnvironmentName", newJString(EnvironmentName))
  add(query_603096, "Action", newJString(Action))
  add(formData_603097, "ActionId", newJString(ActionId))
  add(query_603096, "Version", newJString(Version))
  result = call_603095.call(nil, query_603096, nil, formData_603097, nil)

var postApplyEnvironmentManagedAction* = Call_PostApplyEnvironmentManagedAction_603079(
    name: "postApplyEnvironmentManagedAction", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ApplyEnvironmentManagedAction",
    validator: validate_PostApplyEnvironmentManagedAction_603080, base: "/",
    url: url_PostApplyEnvironmentManagedAction_603081,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplyEnvironmentManagedAction_603061 = ref object of OpenApiRestCall_602434
proc url_GetApplyEnvironmentManagedAction_603063(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetApplyEnvironmentManagedAction_603062(path: JsonNode;
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
  var valid_603064 = query.getOrDefault("EnvironmentName")
  valid_603064 = validateParameter(valid_603064, JString, required = false,
                                 default = nil)
  if valid_603064 != nil:
    section.add "EnvironmentName", valid_603064
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603065 = query.getOrDefault("Action")
  valid_603065 = validateParameter(valid_603065, JString, required = true, default = newJString(
      "ApplyEnvironmentManagedAction"))
  if valid_603065 != nil:
    section.add "Action", valid_603065
  var valid_603066 = query.getOrDefault("EnvironmentId")
  valid_603066 = validateParameter(valid_603066, JString, required = false,
                                 default = nil)
  if valid_603066 != nil:
    section.add "EnvironmentId", valid_603066
  var valid_603067 = query.getOrDefault("ActionId")
  valid_603067 = validateParameter(valid_603067, JString, required = true,
                                 default = nil)
  if valid_603067 != nil:
    section.add "ActionId", valid_603067
  var valid_603068 = query.getOrDefault("Version")
  valid_603068 = validateParameter(valid_603068, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603068 != nil:
    section.add "Version", valid_603068
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
  var valid_603069 = header.getOrDefault("X-Amz-Date")
  valid_603069 = validateParameter(valid_603069, JString, required = false,
                                 default = nil)
  if valid_603069 != nil:
    section.add "X-Amz-Date", valid_603069
  var valid_603070 = header.getOrDefault("X-Amz-Security-Token")
  valid_603070 = validateParameter(valid_603070, JString, required = false,
                                 default = nil)
  if valid_603070 != nil:
    section.add "X-Amz-Security-Token", valid_603070
  var valid_603071 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603071 = validateParameter(valid_603071, JString, required = false,
                                 default = nil)
  if valid_603071 != nil:
    section.add "X-Amz-Content-Sha256", valid_603071
  var valid_603072 = header.getOrDefault("X-Amz-Algorithm")
  valid_603072 = validateParameter(valid_603072, JString, required = false,
                                 default = nil)
  if valid_603072 != nil:
    section.add "X-Amz-Algorithm", valid_603072
  var valid_603073 = header.getOrDefault("X-Amz-Signature")
  valid_603073 = validateParameter(valid_603073, JString, required = false,
                                 default = nil)
  if valid_603073 != nil:
    section.add "X-Amz-Signature", valid_603073
  var valid_603074 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603074 = validateParameter(valid_603074, JString, required = false,
                                 default = nil)
  if valid_603074 != nil:
    section.add "X-Amz-SignedHeaders", valid_603074
  var valid_603075 = header.getOrDefault("X-Amz-Credential")
  valid_603075 = validateParameter(valid_603075, JString, required = false,
                                 default = nil)
  if valid_603075 != nil:
    section.add "X-Amz-Credential", valid_603075
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603076: Call_GetApplyEnvironmentManagedAction_603061;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Applies a scheduled managed action immediately. A managed action can be applied only if its status is <code>Scheduled</code>. Get the status and action ID of a managed action with <a>DescribeEnvironmentManagedActions</a>.
  ## 
  let valid = call_603076.validator(path, query, header, formData, body)
  let scheme = call_603076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603076.url(scheme.get, call_603076.host, call_603076.base,
                         call_603076.route, valid.getOrDefault("path"))
  result = hook(call_603076, url, valid)

proc call*(call_603077: Call_GetApplyEnvironmentManagedAction_603061;
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
  var query_603078 = newJObject()
  add(query_603078, "EnvironmentName", newJString(EnvironmentName))
  add(query_603078, "Action", newJString(Action))
  add(query_603078, "EnvironmentId", newJString(EnvironmentId))
  add(query_603078, "ActionId", newJString(ActionId))
  add(query_603078, "Version", newJString(Version))
  result = call_603077.call(nil, query_603078, nil, nil, nil)

var getApplyEnvironmentManagedAction* = Call_GetApplyEnvironmentManagedAction_603061(
    name: "getApplyEnvironmentManagedAction", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ApplyEnvironmentManagedAction",
    validator: validate_GetApplyEnvironmentManagedAction_603062, base: "/",
    url: url_GetApplyEnvironmentManagedAction_603063,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCheckDNSAvailability_603114 = ref object of OpenApiRestCall_602434
proc url_PostCheckDNSAvailability_603116(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCheckDNSAvailability_603115(path: JsonNode; query: JsonNode;
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
  var valid_603117 = query.getOrDefault("Action")
  valid_603117 = validateParameter(valid_603117, JString, required = true,
                                 default = newJString("CheckDNSAvailability"))
  if valid_603117 != nil:
    section.add "Action", valid_603117
  var valid_603118 = query.getOrDefault("Version")
  valid_603118 = validateParameter(valid_603118, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603118 != nil:
    section.add "Version", valid_603118
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
  var valid_603119 = header.getOrDefault("X-Amz-Date")
  valid_603119 = validateParameter(valid_603119, JString, required = false,
                                 default = nil)
  if valid_603119 != nil:
    section.add "X-Amz-Date", valid_603119
  var valid_603120 = header.getOrDefault("X-Amz-Security-Token")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Security-Token", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Content-Sha256", valid_603121
  var valid_603122 = header.getOrDefault("X-Amz-Algorithm")
  valid_603122 = validateParameter(valid_603122, JString, required = false,
                                 default = nil)
  if valid_603122 != nil:
    section.add "X-Amz-Algorithm", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-Signature")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-Signature", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-SignedHeaders", valid_603124
  var valid_603125 = header.getOrDefault("X-Amz-Credential")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "X-Amz-Credential", valid_603125
  result.add "header", section
  ## parameters in `formData` object:
  ##   CNAMEPrefix: JString (required)
  ##              : The prefix used when this CNAME is reserved.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `CNAMEPrefix` field"
  var valid_603126 = formData.getOrDefault("CNAMEPrefix")
  valid_603126 = validateParameter(valid_603126, JString, required = true,
                                 default = nil)
  if valid_603126 != nil:
    section.add "CNAMEPrefix", valid_603126
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603127: Call_PostCheckDNSAvailability_603114; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Checks if the specified CNAME is available.
  ## 
  let valid = call_603127.validator(path, query, header, formData, body)
  let scheme = call_603127.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603127.url(scheme.get, call_603127.host, call_603127.base,
                         call_603127.route, valid.getOrDefault("path"))
  result = hook(call_603127, url, valid)

proc call*(call_603128: Call_PostCheckDNSAvailability_603114; CNAMEPrefix: string;
          Action: string = "CheckDNSAvailability"; Version: string = "2010-12-01"): Recallable =
  ## postCheckDNSAvailability
  ## Checks if the specified CNAME is available.
  ##   CNAMEPrefix: string (required)
  ##              : The prefix used when this CNAME is reserved.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603129 = newJObject()
  var formData_603130 = newJObject()
  add(formData_603130, "CNAMEPrefix", newJString(CNAMEPrefix))
  add(query_603129, "Action", newJString(Action))
  add(query_603129, "Version", newJString(Version))
  result = call_603128.call(nil, query_603129, nil, formData_603130, nil)

var postCheckDNSAvailability* = Call_PostCheckDNSAvailability_603114(
    name: "postCheckDNSAvailability", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CheckDNSAvailability",
    validator: validate_PostCheckDNSAvailability_603115, base: "/",
    url: url_PostCheckDNSAvailability_603116, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCheckDNSAvailability_603098 = ref object of OpenApiRestCall_602434
proc url_GetCheckDNSAvailability_603100(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCheckDNSAvailability_603099(path: JsonNode; query: JsonNode;
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
  var valid_603101 = query.getOrDefault("Action")
  valid_603101 = validateParameter(valid_603101, JString, required = true,
                                 default = newJString("CheckDNSAvailability"))
  if valid_603101 != nil:
    section.add "Action", valid_603101
  var valid_603102 = query.getOrDefault("Version")
  valid_603102 = validateParameter(valid_603102, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603102 != nil:
    section.add "Version", valid_603102
  var valid_603103 = query.getOrDefault("CNAMEPrefix")
  valid_603103 = validateParameter(valid_603103, JString, required = true,
                                 default = nil)
  if valid_603103 != nil:
    section.add "CNAMEPrefix", valid_603103
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
  var valid_603104 = header.getOrDefault("X-Amz-Date")
  valid_603104 = validateParameter(valid_603104, JString, required = false,
                                 default = nil)
  if valid_603104 != nil:
    section.add "X-Amz-Date", valid_603104
  var valid_603105 = header.getOrDefault("X-Amz-Security-Token")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Security-Token", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Content-Sha256", valid_603106
  var valid_603107 = header.getOrDefault("X-Amz-Algorithm")
  valid_603107 = validateParameter(valid_603107, JString, required = false,
                                 default = nil)
  if valid_603107 != nil:
    section.add "X-Amz-Algorithm", valid_603107
  var valid_603108 = header.getOrDefault("X-Amz-Signature")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "X-Amz-Signature", valid_603108
  var valid_603109 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "X-Amz-SignedHeaders", valid_603109
  var valid_603110 = header.getOrDefault("X-Amz-Credential")
  valid_603110 = validateParameter(valid_603110, JString, required = false,
                                 default = nil)
  if valid_603110 != nil:
    section.add "X-Amz-Credential", valid_603110
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603111: Call_GetCheckDNSAvailability_603098; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Checks if the specified CNAME is available.
  ## 
  let valid = call_603111.validator(path, query, header, formData, body)
  let scheme = call_603111.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603111.url(scheme.get, call_603111.host, call_603111.base,
                         call_603111.route, valid.getOrDefault("path"))
  result = hook(call_603111, url, valid)

proc call*(call_603112: Call_GetCheckDNSAvailability_603098; CNAMEPrefix: string;
          Action: string = "CheckDNSAvailability"; Version: string = "2010-12-01"): Recallable =
  ## getCheckDNSAvailability
  ## Checks if the specified CNAME is available.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   CNAMEPrefix: string (required)
  ##              : The prefix used when this CNAME is reserved.
  var query_603113 = newJObject()
  add(query_603113, "Action", newJString(Action))
  add(query_603113, "Version", newJString(Version))
  add(query_603113, "CNAMEPrefix", newJString(CNAMEPrefix))
  result = call_603112.call(nil, query_603113, nil, nil, nil)

var getCheckDNSAvailability* = Call_GetCheckDNSAvailability_603098(
    name: "getCheckDNSAvailability", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CheckDNSAvailability",
    validator: validate_GetCheckDNSAvailability_603099, base: "/",
    url: url_GetCheckDNSAvailability_603100, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostComposeEnvironments_603149 = ref object of OpenApiRestCall_602434
proc url_PostComposeEnvironments_603151(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostComposeEnvironments_603150(path: JsonNode; query: JsonNode;
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
  var valid_603152 = query.getOrDefault("Action")
  valid_603152 = validateParameter(valid_603152, JString, required = true,
                                 default = newJString("ComposeEnvironments"))
  if valid_603152 != nil:
    section.add "Action", valid_603152
  var valid_603153 = query.getOrDefault("Version")
  valid_603153 = validateParameter(valid_603153, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603153 != nil:
    section.add "Version", valid_603153
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
  var valid_603154 = header.getOrDefault("X-Amz-Date")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Date", valid_603154
  var valid_603155 = header.getOrDefault("X-Amz-Security-Token")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-Security-Token", valid_603155
  var valid_603156 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-Content-Sha256", valid_603156
  var valid_603157 = header.getOrDefault("X-Amz-Algorithm")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "X-Amz-Algorithm", valid_603157
  var valid_603158 = header.getOrDefault("X-Amz-Signature")
  valid_603158 = validateParameter(valid_603158, JString, required = false,
                                 default = nil)
  if valid_603158 != nil:
    section.add "X-Amz-Signature", valid_603158
  var valid_603159 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603159 = validateParameter(valid_603159, JString, required = false,
                                 default = nil)
  if valid_603159 != nil:
    section.add "X-Amz-SignedHeaders", valid_603159
  var valid_603160 = header.getOrDefault("X-Amz-Credential")
  valid_603160 = validateParameter(valid_603160, JString, required = false,
                                 default = nil)
  if valid_603160 != nil:
    section.add "X-Amz-Credential", valid_603160
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
  var valid_603161 = formData.getOrDefault("GroupName")
  valid_603161 = validateParameter(valid_603161, JString, required = false,
                                 default = nil)
  if valid_603161 != nil:
    section.add "GroupName", valid_603161
  var valid_603162 = formData.getOrDefault("ApplicationName")
  valid_603162 = validateParameter(valid_603162, JString, required = false,
                                 default = nil)
  if valid_603162 != nil:
    section.add "ApplicationName", valid_603162
  var valid_603163 = formData.getOrDefault("VersionLabels")
  valid_603163 = validateParameter(valid_603163, JArray, required = false,
                                 default = nil)
  if valid_603163 != nil:
    section.add "VersionLabels", valid_603163
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603164: Call_PostComposeEnvironments_603149; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create or update a group of environments that each run a separate component of a single application. Takes a list of version labels that specify application source bundles for each of the environments to create or update. The name of each environment and other required information must be included in the source bundles in an environment manifest named <code>env.yaml</code>. See <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-mgmt-compose.html">Compose Environments</a> for details.
  ## 
  let valid = call_603164.validator(path, query, header, formData, body)
  let scheme = call_603164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603164.url(scheme.get, call_603164.host, call_603164.base,
                         call_603164.route, valid.getOrDefault("path"))
  result = hook(call_603164, url, valid)

proc call*(call_603165: Call_PostComposeEnvironments_603149;
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
  var query_603166 = newJObject()
  var formData_603167 = newJObject()
  add(formData_603167, "GroupName", newJString(GroupName))
  add(query_603166, "Action", newJString(Action))
  add(formData_603167, "ApplicationName", newJString(ApplicationName))
  add(query_603166, "Version", newJString(Version))
  if VersionLabels != nil:
    formData_603167.add "VersionLabels", VersionLabels
  result = call_603165.call(nil, query_603166, nil, formData_603167, nil)

var postComposeEnvironments* = Call_PostComposeEnvironments_603149(
    name: "postComposeEnvironments", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ComposeEnvironments",
    validator: validate_PostComposeEnvironments_603150, base: "/",
    url: url_PostComposeEnvironments_603151, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetComposeEnvironments_603131 = ref object of OpenApiRestCall_602434
proc url_GetComposeEnvironments_603133(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetComposeEnvironments_603132(path: JsonNode; query: JsonNode;
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
  var valid_603134 = query.getOrDefault("ApplicationName")
  valid_603134 = validateParameter(valid_603134, JString, required = false,
                                 default = nil)
  if valid_603134 != nil:
    section.add "ApplicationName", valid_603134
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603135 = query.getOrDefault("Action")
  valid_603135 = validateParameter(valid_603135, JString, required = true,
                                 default = newJString("ComposeEnvironments"))
  if valid_603135 != nil:
    section.add "Action", valid_603135
  var valid_603136 = query.getOrDefault("GroupName")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "GroupName", valid_603136
  var valid_603137 = query.getOrDefault("VersionLabels")
  valid_603137 = validateParameter(valid_603137, JArray, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "VersionLabels", valid_603137
  var valid_603138 = query.getOrDefault("Version")
  valid_603138 = validateParameter(valid_603138, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603138 != nil:
    section.add "Version", valid_603138
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
  var valid_603139 = header.getOrDefault("X-Amz-Date")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Date", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-Security-Token")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-Security-Token", valid_603140
  var valid_603141 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-Content-Sha256", valid_603141
  var valid_603142 = header.getOrDefault("X-Amz-Algorithm")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-Algorithm", valid_603142
  var valid_603143 = header.getOrDefault("X-Amz-Signature")
  valid_603143 = validateParameter(valid_603143, JString, required = false,
                                 default = nil)
  if valid_603143 != nil:
    section.add "X-Amz-Signature", valid_603143
  var valid_603144 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603144 = validateParameter(valid_603144, JString, required = false,
                                 default = nil)
  if valid_603144 != nil:
    section.add "X-Amz-SignedHeaders", valid_603144
  var valid_603145 = header.getOrDefault("X-Amz-Credential")
  valid_603145 = validateParameter(valid_603145, JString, required = false,
                                 default = nil)
  if valid_603145 != nil:
    section.add "X-Amz-Credential", valid_603145
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603146: Call_GetComposeEnvironments_603131; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create or update a group of environments that each run a separate component of a single application. Takes a list of version labels that specify application source bundles for each of the environments to create or update. The name of each environment and other required information must be included in the source bundles in an environment manifest named <code>env.yaml</code>. See <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-mgmt-compose.html">Compose Environments</a> for details.
  ## 
  let valid = call_603146.validator(path, query, header, formData, body)
  let scheme = call_603146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603146.url(scheme.get, call_603146.host, call_603146.base,
                         call_603146.route, valid.getOrDefault("path"))
  result = hook(call_603146, url, valid)

proc call*(call_603147: Call_GetComposeEnvironments_603131;
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
  var query_603148 = newJObject()
  add(query_603148, "ApplicationName", newJString(ApplicationName))
  add(query_603148, "Action", newJString(Action))
  add(query_603148, "GroupName", newJString(GroupName))
  if VersionLabels != nil:
    query_603148.add "VersionLabels", VersionLabels
  add(query_603148, "Version", newJString(Version))
  result = call_603147.call(nil, query_603148, nil, nil, nil)

var getComposeEnvironments* = Call_GetComposeEnvironments_603131(
    name: "getComposeEnvironments", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ComposeEnvironments",
    validator: validate_GetComposeEnvironments_603132, base: "/",
    url: url_GetComposeEnvironments_603133, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateApplication_603188 = ref object of OpenApiRestCall_602434
proc url_PostCreateApplication_603190(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateApplication_603189(path: JsonNode; query: JsonNode;
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
  var valid_603191 = query.getOrDefault("Action")
  valid_603191 = validateParameter(valid_603191, JString, required = true,
                                 default = newJString("CreateApplication"))
  if valid_603191 != nil:
    section.add "Action", valid_603191
  var valid_603192 = query.getOrDefault("Version")
  valid_603192 = validateParameter(valid_603192, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603192 != nil:
    section.add "Version", valid_603192
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
  var valid_603193 = header.getOrDefault("X-Amz-Date")
  valid_603193 = validateParameter(valid_603193, JString, required = false,
                                 default = nil)
  if valid_603193 != nil:
    section.add "X-Amz-Date", valid_603193
  var valid_603194 = header.getOrDefault("X-Amz-Security-Token")
  valid_603194 = validateParameter(valid_603194, JString, required = false,
                                 default = nil)
  if valid_603194 != nil:
    section.add "X-Amz-Security-Token", valid_603194
  var valid_603195 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-Content-Sha256", valid_603195
  var valid_603196 = header.getOrDefault("X-Amz-Algorithm")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "X-Amz-Algorithm", valid_603196
  var valid_603197 = header.getOrDefault("X-Amz-Signature")
  valid_603197 = validateParameter(valid_603197, JString, required = false,
                                 default = nil)
  if valid_603197 != nil:
    section.add "X-Amz-Signature", valid_603197
  var valid_603198 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-SignedHeaders", valid_603198
  var valid_603199 = header.getOrDefault("X-Amz-Credential")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-Credential", valid_603199
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
  var valid_603200 = formData.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_603200
  var valid_603201 = formData.getOrDefault("Tags")
  valid_603201 = validateParameter(valid_603201, JArray, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "Tags", valid_603201
  var valid_603202 = formData.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_603202
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_603203 = formData.getOrDefault("ApplicationName")
  valid_603203 = validateParameter(valid_603203, JString, required = true,
                                 default = nil)
  if valid_603203 != nil:
    section.add "ApplicationName", valid_603203
  var valid_603204 = formData.getOrDefault("Description")
  valid_603204 = validateParameter(valid_603204, JString, required = false,
                                 default = nil)
  if valid_603204 != nil:
    section.add "Description", valid_603204
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603205: Call_PostCreateApplication_603188; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates an application that has one configuration template named <code>default</code> and no application versions. 
  ## 
  let valid = call_603205.validator(path, query, header, formData, body)
  let scheme = call_603205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603205.url(scheme.get, call_603205.host, call_603205.base,
                         call_603205.route, valid.getOrDefault("path"))
  result = hook(call_603205, url, valid)

proc call*(call_603206: Call_PostCreateApplication_603188; ApplicationName: string;
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
  var query_603207 = newJObject()
  var formData_603208 = newJObject()
  add(formData_603208, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  if Tags != nil:
    formData_603208.add "Tags", Tags
  add(formData_603208, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  add(query_603207, "Action", newJString(Action))
  add(formData_603208, "ApplicationName", newJString(ApplicationName))
  add(query_603207, "Version", newJString(Version))
  add(formData_603208, "Description", newJString(Description))
  result = call_603206.call(nil, query_603207, nil, formData_603208, nil)

var postCreateApplication* = Call_PostCreateApplication_603188(
    name: "postCreateApplication", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateApplication",
    validator: validate_PostCreateApplication_603189, base: "/",
    url: url_PostCreateApplication_603190, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateApplication_603168 = ref object of OpenApiRestCall_602434
proc url_GetCreateApplication_603170(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateApplication_603169(path: JsonNode; query: JsonNode;
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
  var valid_603171 = query.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_603171
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_603172 = query.getOrDefault("ApplicationName")
  valid_603172 = validateParameter(valid_603172, JString, required = true,
                                 default = nil)
  if valid_603172 != nil:
    section.add "ApplicationName", valid_603172
  var valid_603173 = query.getOrDefault("Description")
  valid_603173 = validateParameter(valid_603173, JString, required = false,
                                 default = nil)
  if valid_603173 != nil:
    section.add "Description", valid_603173
  var valid_603174 = query.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_603174 = validateParameter(valid_603174, JString, required = false,
                                 default = nil)
  if valid_603174 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_603174
  var valid_603175 = query.getOrDefault("Tags")
  valid_603175 = validateParameter(valid_603175, JArray, required = false,
                                 default = nil)
  if valid_603175 != nil:
    section.add "Tags", valid_603175
  var valid_603176 = query.getOrDefault("Action")
  valid_603176 = validateParameter(valid_603176, JString, required = true,
                                 default = newJString("CreateApplication"))
  if valid_603176 != nil:
    section.add "Action", valid_603176
  var valid_603177 = query.getOrDefault("Version")
  valid_603177 = validateParameter(valid_603177, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603177 != nil:
    section.add "Version", valid_603177
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
  var valid_603178 = header.getOrDefault("X-Amz-Date")
  valid_603178 = validateParameter(valid_603178, JString, required = false,
                                 default = nil)
  if valid_603178 != nil:
    section.add "X-Amz-Date", valid_603178
  var valid_603179 = header.getOrDefault("X-Amz-Security-Token")
  valid_603179 = validateParameter(valid_603179, JString, required = false,
                                 default = nil)
  if valid_603179 != nil:
    section.add "X-Amz-Security-Token", valid_603179
  var valid_603180 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "X-Amz-Content-Sha256", valid_603180
  var valid_603181 = header.getOrDefault("X-Amz-Algorithm")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "X-Amz-Algorithm", valid_603181
  var valid_603182 = header.getOrDefault("X-Amz-Signature")
  valid_603182 = validateParameter(valid_603182, JString, required = false,
                                 default = nil)
  if valid_603182 != nil:
    section.add "X-Amz-Signature", valid_603182
  var valid_603183 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "X-Amz-SignedHeaders", valid_603183
  var valid_603184 = header.getOrDefault("X-Amz-Credential")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "X-Amz-Credential", valid_603184
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603185: Call_GetCreateApplication_603168; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates an application that has one configuration template named <code>default</code> and no application versions. 
  ## 
  let valid = call_603185.validator(path, query, header, formData, body)
  let scheme = call_603185.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603185.url(scheme.get, call_603185.host, call_603185.base,
                         call_603185.route, valid.getOrDefault("path"))
  result = hook(call_603185, url, valid)

proc call*(call_603186: Call_GetCreateApplication_603168; ApplicationName: string;
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
  var query_603187 = newJObject()
  add(query_603187, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  add(query_603187, "ApplicationName", newJString(ApplicationName))
  add(query_603187, "Description", newJString(Description))
  add(query_603187, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  if Tags != nil:
    query_603187.add "Tags", Tags
  add(query_603187, "Action", newJString(Action))
  add(query_603187, "Version", newJString(Version))
  result = call_603186.call(nil, query_603187, nil, nil, nil)

var getCreateApplication* = Call_GetCreateApplication_603168(
    name: "getCreateApplication", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateApplication",
    validator: validate_GetCreateApplication_603169, base: "/",
    url: url_GetCreateApplication_603170, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateApplicationVersion_603240 = ref object of OpenApiRestCall_602434
proc url_PostCreateApplicationVersion_603242(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateApplicationVersion_603241(path: JsonNode; query: JsonNode;
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
  var valid_603243 = query.getOrDefault("Action")
  valid_603243 = validateParameter(valid_603243, JString, required = true, default = newJString(
      "CreateApplicationVersion"))
  if valid_603243 != nil:
    section.add "Action", valid_603243
  var valid_603244 = query.getOrDefault("Version")
  valid_603244 = validateParameter(valid_603244, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603244 != nil:
    section.add "Version", valid_603244
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
  var valid_603245 = header.getOrDefault("X-Amz-Date")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "X-Amz-Date", valid_603245
  var valid_603246 = header.getOrDefault("X-Amz-Security-Token")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "X-Amz-Security-Token", valid_603246
  var valid_603247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603247 = validateParameter(valid_603247, JString, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "X-Amz-Content-Sha256", valid_603247
  var valid_603248 = header.getOrDefault("X-Amz-Algorithm")
  valid_603248 = validateParameter(valid_603248, JString, required = false,
                                 default = nil)
  if valid_603248 != nil:
    section.add "X-Amz-Algorithm", valid_603248
  var valid_603249 = header.getOrDefault("X-Amz-Signature")
  valid_603249 = validateParameter(valid_603249, JString, required = false,
                                 default = nil)
  if valid_603249 != nil:
    section.add "X-Amz-Signature", valid_603249
  var valid_603250 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603250 = validateParameter(valid_603250, JString, required = false,
                                 default = nil)
  if valid_603250 != nil:
    section.add "X-Amz-SignedHeaders", valid_603250
  var valid_603251 = header.getOrDefault("X-Amz-Credential")
  valid_603251 = validateParameter(valid_603251, JString, required = false,
                                 default = nil)
  if valid_603251 != nil:
    section.add "X-Amz-Credential", valid_603251
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
  var valid_603252 = formData.getOrDefault("SourceBundle.S3Key")
  valid_603252 = validateParameter(valid_603252, JString, required = false,
                                 default = nil)
  if valid_603252 != nil:
    section.add "SourceBundle.S3Key", valid_603252
  assert formData != nil,
        "formData argument is necessary due to required `VersionLabel` field"
  var valid_603253 = formData.getOrDefault("VersionLabel")
  valid_603253 = validateParameter(valid_603253, JString, required = true,
                                 default = nil)
  if valid_603253 != nil:
    section.add "VersionLabel", valid_603253
  var valid_603254 = formData.getOrDefault("SourceBundle.S3Bucket")
  valid_603254 = validateParameter(valid_603254, JString, required = false,
                                 default = nil)
  if valid_603254 != nil:
    section.add "SourceBundle.S3Bucket", valid_603254
  var valid_603255 = formData.getOrDefault("BuildConfiguration.ComputeType")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "BuildConfiguration.ComputeType", valid_603255
  var valid_603256 = formData.getOrDefault("SourceBuildInformation.SourceType")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = nil)
  if valid_603256 != nil:
    section.add "SourceBuildInformation.SourceType", valid_603256
  var valid_603257 = formData.getOrDefault("Tags")
  valid_603257 = validateParameter(valid_603257, JArray, required = false,
                                 default = nil)
  if valid_603257 != nil:
    section.add "Tags", valid_603257
  var valid_603258 = formData.getOrDefault("AutoCreateApplication")
  valid_603258 = validateParameter(valid_603258, JBool, required = false, default = nil)
  if valid_603258 != nil:
    section.add "AutoCreateApplication", valid_603258
  var valid_603259 = formData.getOrDefault("SourceBuildInformation.SourceLocation")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "SourceBuildInformation.SourceLocation", valid_603259
  var valid_603260 = formData.getOrDefault("BuildConfiguration.CodeBuildServiceRole")
  valid_603260 = validateParameter(valid_603260, JString, required = false,
                                 default = nil)
  if valid_603260 != nil:
    section.add "BuildConfiguration.CodeBuildServiceRole", valid_603260
  var valid_603261 = formData.getOrDefault("ApplicationName")
  valid_603261 = validateParameter(valid_603261, JString, required = true,
                                 default = nil)
  if valid_603261 != nil:
    section.add "ApplicationName", valid_603261
  var valid_603262 = formData.getOrDefault("BuildConfiguration.ArtifactName")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "BuildConfiguration.ArtifactName", valid_603262
  var valid_603263 = formData.getOrDefault("BuildConfiguration.TimeoutInMinutes")
  valid_603263 = validateParameter(valid_603263, JString, required = false,
                                 default = nil)
  if valid_603263 != nil:
    section.add "BuildConfiguration.TimeoutInMinutes", valid_603263
  var valid_603264 = formData.getOrDefault("SourceBuildInformation.SourceRepository")
  valid_603264 = validateParameter(valid_603264, JString, required = false,
                                 default = nil)
  if valid_603264 != nil:
    section.add "SourceBuildInformation.SourceRepository", valid_603264
  var valid_603265 = formData.getOrDefault("Description")
  valid_603265 = validateParameter(valid_603265, JString, required = false,
                                 default = nil)
  if valid_603265 != nil:
    section.add "Description", valid_603265
  var valid_603266 = formData.getOrDefault("BuildConfiguration.Image")
  valid_603266 = validateParameter(valid_603266, JString, required = false,
                                 default = nil)
  if valid_603266 != nil:
    section.add "BuildConfiguration.Image", valid_603266
  var valid_603267 = formData.getOrDefault("Process")
  valid_603267 = validateParameter(valid_603267, JBool, required = false, default = nil)
  if valid_603267 != nil:
    section.add "Process", valid_603267
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603268: Call_PostCreateApplicationVersion_603240; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an application version for the specified application. You can create an application version from a source bundle in Amazon S3, a commit in AWS CodeCommit, or the output of an AWS CodeBuild build as follows:</p> <p>Specify a commit in an AWS CodeCommit repository with <code>SourceBuildInformation</code>.</p> <p>Specify a build in an AWS CodeBuild with <code>SourceBuildInformation</code> and <code>BuildConfiguration</code>.</p> <p>Specify a source bundle in S3 with <code>SourceBundle</code> </p> <p>Omit both <code>SourceBuildInformation</code> and <code>SourceBundle</code> to use the default sample application.</p> <note> <p>Once you create an application version with a specified Amazon S3 bucket and key location, you cannot change that Amazon S3 location. If you change the Amazon S3 location, you receive an exception when you attempt to launch an environment from the application version.</p> </note>
  ## 
  let valid = call_603268.validator(path, query, header, formData, body)
  let scheme = call_603268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603268.url(scheme.get, call_603268.host, call_603268.base,
                         call_603268.route, valid.getOrDefault("path"))
  result = hook(call_603268, url, valid)

proc call*(call_603269: Call_PostCreateApplicationVersion_603240;
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
  var query_603270 = newJObject()
  var formData_603271 = newJObject()
  add(formData_603271, "SourceBundle.S3Key", newJString(SourceBundleS3Key))
  add(formData_603271, "VersionLabel", newJString(VersionLabel))
  add(formData_603271, "SourceBundle.S3Bucket", newJString(SourceBundleS3Bucket))
  add(formData_603271, "BuildConfiguration.ComputeType",
      newJString(BuildConfigurationComputeType))
  add(formData_603271, "SourceBuildInformation.SourceType",
      newJString(SourceBuildInformationSourceType))
  if Tags != nil:
    formData_603271.add "Tags", Tags
  add(formData_603271, "AutoCreateApplication", newJBool(AutoCreateApplication))
  add(formData_603271, "SourceBuildInformation.SourceLocation",
      newJString(SourceBuildInformationSourceLocation))
  add(query_603270, "Action", newJString(Action))
  add(formData_603271, "BuildConfiguration.CodeBuildServiceRole",
      newJString(BuildConfigurationCodeBuildServiceRole))
  add(formData_603271, "ApplicationName", newJString(ApplicationName))
  add(formData_603271, "BuildConfiguration.ArtifactName",
      newJString(BuildConfigurationArtifactName))
  add(formData_603271, "BuildConfiguration.TimeoutInMinutes",
      newJString(BuildConfigurationTimeoutInMinutes))
  add(formData_603271, "SourceBuildInformation.SourceRepository",
      newJString(SourceBuildInformationSourceRepository))
  add(formData_603271, "Description", newJString(Description))
  add(formData_603271, "BuildConfiguration.Image",
      newJString(BuildConfigurationImage))
  add(formData_603271, "Process", newJBool(Process))
  add(query_603270, "Version", newJString(Version))
  result = call_603269.call(nil, query_603270, nil, formData_603271, nil)

var postCreateApplicationVersion* = Call_PostCreateApplicationVersion_603240(
    name: "postCreateApplicationVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateApplicationVersion",
    validator: validate_PostCreateApplicationVersion_603241, base: "/",
    url: url_PostCreateApplicationVersion_603242,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateApplicationVersion_603209 = ref object of OpenApiRestCall_602434
proc url_GetCreateApplicationVersion_603211(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateApplicationVersion_603210(path: JsonNode; query: JsonNode;
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
  var valid_603212 = query.getOrDefault("BuildConfiguration.TimeoutInMinutes")
  valid_603212 = validateParameter(valid_603212, JString, required = false,
                                 default = nil)
  if valid_603212 != nil:
    section.add "BuildConfiguration.TimeoutInMinutes", valid_603212
  var valid_603213 = query.getOrDefault("SourceBundle.S3Bucket")
  valid_603213 = validateParameter(valid_603213, JString, required = false,
                                 default = nil)
  if valid_603213 != nil:
    section.add "SourceBundle.S3Bucket", valid_603213
  var valid_603214 = query.getOrDefault("BuildConfiguration.ComputeType")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "BuildConfiguration.ComputeType", valid_603214
  assert query != nil,
        "query argument is necessary due to required `VersionLabel` field"
  var valid_603215 = query.getOrDefault("VersionLabel")
  valid_603215 = validateParameter(valid_603215, JString, required = true,
                                 default = nil)
  if valid_603215 != nil:
    section.add "VersionLabel", valid_603215
  var valid_603216 = query.getOrDefault("BuildConfiguration.ArtifactName")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "BuildConfiguration.ArtifactName", valid_603216
  var valid_603217 = query.getOrDefault("ApplicationName")
  valid_603217 = validateParameter(valid_603217, JString, required = true,
                                 default = nil)
  if valid_603217 != nil:
    section.add "ApplicationName", valid_603217
  var valid_603218 = query.getOrDefault("Description")
  valid_603218 = validateParameter(valid_603218, JString, required = false,
                                 default = nil)
  if valid_603218 != nil:
    section.add "Description", valid_603218
  var valid_603219 = query.getOrDefault("BuildConfiguration.Image")
  valid_603219 = validateParameter(valid_603219, JString, required = false,
                                 default = nil)
  if valid_603219 != nil:
    section.add "BuildConfiguration.Image", valid_603219
  var valid_603220 = query.getOrDefault("SourceBuildInformation.SourceLocation")
  valid_603220 = validateParameter(valid_603220, JString, required = false,
                                 default = nil)
  if valid_603220 != nil:
    section.add "SourceBuildInformation.SourceLocation", valid_603220
  var valid_603221 = query.getOrDefault("SourceBundle.S3Key")
  valid_603221 = validateParameter(valid_603221, JString, required = false,
                                 default = nil)
  if valid_603221 != nil:
    section.add "SourceBundle.S3Key", valid_603221
  var valid_603222 = query.getOrDefault("Tags")
  valid_603222 = validateParameter(valid_603222, JArray, required = false,
                                 default = nil)
  if valid_603222 != nil:
    section.add "Tags", valid_603222
  var valid_603223 = query.getOrDefault("AutoCreateApplication")
  valid_603223 = validateParameter(valid_603223, JBool, required = false, default = nil)
  if valid_603223 != nil:
    section.add "AutoCreateApplication", valid_603223
  var valid_603224 = query.getOrDefault("Action")
  valid_603224 = validateParameter(valid_603224, JString, required = true, default = newJString(
      "CreateApplicationVersion"))
  if valid_603224 != nil:
    section.add "Action", valid_603224
  var valid_603225 = query.getOrDefault("SourceBuildInformation.SourceType")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "SourceBuildInformation.SourceType", valid_603225
  var valid_603226 = query.getOrDefault("BuildConfiguration.CodeBuildServiceRole")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "BuildConfiguration.CodeBuildServiceRole", valid_603226
  var valid_603227 = query.getOrDefault("Process")
  valid_603227 = validateParameter(valid_603227, JBool, required = false, default = nil)
  if valid_603227 != nil:
    section.add "Process", valid_603227
  var valid_603228 = query.getOrDefault("SourceBuildInformation.SourceRepository")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "SourceBuildInformation.SourceRepository", valid_603228
  var valid_603229 = query.getOrDefault("Version")
  valid_603229 = validateParameter(valid_603229, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603229 != nil:
    section.add "Version", valid_603229
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
  var valid_603230 = header.getOrDefault("X-Amz-Date")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "X-Amz-Date", valid_603230
  var valid_603231 = header.getOrDefault("X-Amz-Security-Token")
  valid_603231 = validateParameter(valid_603231, JString, required = false,
                                 default = nil)
  if valid_603231 != nil:
    section.add "X-Amz-Security-Token", valid_603231
  var valid_603232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603232 = validateParameter(valid_603232, JString, required = false,
                                 default = nil)
  if valid_603232 != nil:
    section.add "X-Amz-Content-Sha256", valid_603232
  var valid_603233 = header.getOrDefault("X-Amz-Algorithm")
  valid_603233 = validateParameter(valid_603233, JString, required = false,
                                 default = nil)
  if valid_603233 != nil:
    section.add "X-Amz-Algorithm", valid_603233
  var valid_603234 = header.getOrDefault("X-Amz-Signature")
  valid_603234 = validateParameter(valid_603234, JString, required = false,
                                 default = nil)
  if valid_603234 != nil:
    section.add "X-Amz-Signature", valid_603234
  var valid_603235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603235 = validateParameter(valid_603235, JString, required = false,
                                 default = nil)
  if valid_603235 != nil:
    section.add "X-Amz-SignedHeaders", valid_603235
  var valid_603236 = header.getOrDefault("X-Amz-Credential")
  valid_603236 = validateParameter(valid_603236, JString, required = false,
                                 default = nil)
  if valid_603236 != nil:
    section.add "X-Amz-Credential", valid_603236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603237: Call_GetCreateApplicationVersion_603209; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an application version for the specified application. You can create an application version from a source bundle in Amazon S3, a commit in AWS CodeCommit, or the output of an AWS CodeBuild build as follows:</p> <p>Specify a commit in an AWS CodeCommit repository with <code>SourceBuildInformation</code>.</p> <p>Specify a build in an AWS CodeBuild with <code>SourceBuildInformation</code> and <code>BuildConfiguration</code>.</p> <p>Specify a source bundle in S3 with <code>SourceBundle</code> </p> <p>Omit both <code>SourceBuildInformation</code> and <code>SourceBundle</code> to use the default sample application.</p> <note> <p>Once you create an application version with a specified Amazon S3 bucket and key location, you cannot change that Amazon S3 location. If you change the Amazon S3 location, you receive an exception when you attempt to launch an environment from the application version.</p> </note>
  ## 
  let valid = call_603237.validator(path, query, header, formData, body)
  let scheme = call_603237.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603237.url(scheme.get, call_603237.host, call_603237.base,
                         call_603237.route, valid.getOrDefault("path"))
  result = hook(call_603237, url, valid)

proc call*(call_603238: Call_GetCreateApplicationVersion_603209;
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
  var query_603239 = newJObject()
  add(query_603239, "BuildConfiguration.TimeoutInMinutes",
      newJString(BuildConfigurationTimeoutInMinutes))
  add(query_603239, "SourceBundle.S3Bucket", newJString(SourceBundleS3Bucket))
  add(query_603239, "BuildConfiguration.ComputeType",
      newJString(BuildConfigurationComputeType))
  add(query_603239, "VersionLabel", newJString(VersionLabel))
  add(query_603239, "BuildConfiguration.ArtifactName",
      newJString(BuildConfigurationArtifactName))
  add(query_603239, "ApplicationName", newJString(ApplicationName))
  add(query_603239, "Description", newJString(Description))
  add(query_603239, "BuildConfiguration.Image",
      newJString(BuildConfigurationImage))
  add(query_603239, "SourceBuildInformation.SourceLocation",
      newJString(SourceBuildInformationSourceLocation))
  add(query_603239, "SourceBundle.S3Key", newJString(SourceBundleS3Key))
  if Tags != nil:
    query_603239.add "Tags", Tags
  add(query_603239, "AutoCreateApplication", newJBool(AutoCreateApplication))
  add(query_603239, "Action", newJString(Action))
  add(query_603239, "SourceBuildInformation.SourceType",
      newJString(SourceBuildInformationSourceType))
  add(query_603239, "BuildConfiguration.CodeBuildServiceRole",
      newJString(BuildConfigurationCodeBuildServiceRole))
  add(query_603239, "Process", newJBool(Process))
  add(query_603239, "SourceBuildInformation.SourceRepository",
      newJString(SourceBuildInformationSourceRepository))
  add(query_603239, "Version", newJString(Version))
  result = call_603238.call(nil, query_603239, nil, nil, nil)

var getCreateApplicationVersion* = Call_GetCreateApplicationVersion_603209(
    name: "getCreateApplicationVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateApplicationVersion",
    validator: validate_GetCreateApplicationVersion_603210, base: "/",
    url: url_GetCreateApplicationVersion_603211,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateConfigurationTemplate_603297 = ref object of OpenApiRestCall_602434
proc url_PostCreateConfigurationTemplate_603299(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateConfigurationTemplate_603298(path: JsonNode;
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
  var valid_603300 = query.getOrDefault("Action")
  valid_603300 = validateParameter(valid_603300, JString, required = true, default = newJString(
      "CreateConfigurationTemplate"))
  if valid_603300 != nil:
    section.add "Action", valid_603300
  var valid_603301 = query.getOrDefault("Version")
  valid_603301 = validateParameter(valid_603301, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603301 != nil:
    section.add "Version", valid_603301
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
  var valid_603302 = header.getOrDefault("X-Amz-Date")
  valid_603302 = validateParameter(valid_603302, JString, required = false,
                                 default = nil)
  if valid_603302 != nil:
    section.add "X-Amz-Date", valid_603302
  var valid_603303 = header.getOrDefault("X-Amz-Security-Token")
  valid_603303 = validateParameter(valid_603303, JString, required = false,
                                 default = nil)
  if valid_603303 != nil:
    section.add "X-Amz-Security-Token", valid_603303
  var valid_603304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603304 = validateParameter(valid_603304, JString, required = false,
                                 default = nil)
  if valid_603304 != nil:
    section.add "X-Amz-Content-Sha256", valid_603304
  var valid_603305 = header.getOrDefault("X-Amz-Algorithm")
  valid_603305 = validateParameter(valid_603305, JString, required = false,
                                 default = nil)
  if valid_603305 != nil:
    section.add "X-Amz-Algorithm", valid_603305
  var valid_603306 = header.getOrDefault("X-Amz-Signature")
  valid_603306 = validateParameter(valid_603306, JString, required = false,
                                 default = nil)
  if valid_603306 != nil:
    section.add "X-Amz-Signature", valid_603306
  var valid_603307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603307 = validateParameter(valid_603307, JString, required = false,
                                 default = nil)
  if valid_603307 != nil:
    section.add "X-Amz-SignedHeaders", valid_603307
  var valid_603308 = header.getOrDefault("X-Amz-Credential")
  valid_603308 = validateParameter(valid_603308, JString, required = false,
                                 default = nil)
  if valid_603308 != nil:
    section.add "X-Amz-Credential", valid_603308
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
  var valid_603309 = formData.getOrDefault("OptionSettings")
  valid_603309 = validateParameter(valid_603309, JArray, required = false,
                                 default = nil)
  if valid_603309 != nil:
    section.add "OptionSettings", valid_603309
  var valid_603310 = formData.getOrDefault("Tags")
  valid_603310 = validateParameter(valid_603310, JArray, required = false,
                                 default = nil)
  if valid_603310 != nil:
    section.add "Tags", valid_603310
  var valid_603311 = formData.getOrDefault("SolutionStackName")
  valid_603311 = validateParameter(valid_603311, JString, required = false,
                                 default = nil)
  if valid_603311 != nil:
    section.add "SolutionStackName", valid_603311
  var valid_603312 = formData.getOrDefault("SourceConfiguration.ApplicationName")
  valid_603312 = validateParameter(valid_603312, JString, required = false,
                                 default = nil)
  if valid_603312 != nil:
    section.add "SourceConfiguration.ApplicationName", valid_603312
  var valid_603313 = formData.getOrDefault("EnvironmentId")
  valid_603313 = validateParameter(valid_603313, JString, required = false,
                                 default = nil)
  if valid_603313 != nil:
    section.add "EnvironmentId", valid_603313
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_603314 = formData.getOrDefault("ApplicationName")
  valid_603314 = validateParameter(valid_603314, JString, required = true,
                                 default = nil)
  if valid_603314 != nil:
    section.add "ApplicationName", valid_603314
  var valid_603315 = formData.getOrDefault("PlatformArn")
  valid_603315 = validateParameter(valid_603315, JString, required = false,
                                 default = nil)
  if valid_603315 != nil:
    section.add "PlatformArn", valid_603315
  var valid_603316 = formData.getOrDefault("TemplateName")
  valid_603316 = validateParameter(valid_603316, JString, required = true,
                                 default = nil)
  if valid_603316 != nil:
    section.add "TemplateName", valid_603316
  var valid_603317 = formData.getOrDefault("Description")
  valid_603317 = validateParameter(valid_603317, JString, required = false,
                                 default = nil)
  if valid_603317 != nil:
    section.add "Description", valid_603317
  var valid_603318 = formData.getOrDefault("SourceConfiguration.TemplateName")
  valid_603318 = validateParameter(valid_603318, JString, required = false,
                                 default = nil)
  if valid_603318 != nil:
    section.add "SourceConfiguration.TemplateName", valid_603318
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603319: Call_PostCreateConfigurationTemplate_603297;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a configuration template. Templates are associated with a specific application and are used to deploy different versions of the application with the same configuration settings.</p> <p>Templates aren't associated with any environment. The <code>EnvironmentName</code> response element is always <code>null</code>.</p> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> <li> <p> <a>DescribeConfigurationSettings</a> </p> </li> <li> <p> <a>ListAvailableSolutionStacks</a> </p> </li> </ul>
  ## 
  let valid = call_603319.validator(path, query, header, formData, body)
  let scheme = call_603319.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603319.url(scheme.get, call_603319.host, call_603319.base,
                         call_603319.route, valid.getOrDefault("path"))
  result = hook(call_603319, url, valid)

proc call*(call_603320: Call_PostCreateConfigurationTemplate_603297;
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
  var query_603321 = newJObject()
  var formData_603322 = newJObject()
  if OptionSettings != nil:
    formData_603322.add "OptionSettings", OptionSettings
  if Tags != nil:
    formData_603322.add "Tags", Tags
  add(formData_603322, "SolutionStackName", newJString(SolutionStackName))
  add(formData_603322, "SourceConfiguration.ApplicationName",
      newJString(SourceConfigurationApplicationName))
  add(formData_603322, "EnvironmentId", newJString(EnvironmentId))
  add(query_603321, "Action", newJString(Action))
  add(formData_603322, "ApplicationName", newJString(ApplicationName))
  add(formData_603322, "PlatformArn", newJString(PlatformArn))
  add(formData_603322, "TemplateName", newJString(TemplateName))
  add(query_603321, "Version", newJString(Version))
  add(formData_603322, "Description", newJString(Description))
  add(formData_603322, "SourceConfiguration.TemplateName",
      newJString(SourceConfigurationTemplateName))
  result = call_603320.call(nil, query_603321, nil, formData_603322, nil)

var postCreateConfigurationTemplate* = Call_PostCreateConfigurationTemplate_603297(
    name: "postCreateConfigurationTemplate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateConfigurationTemplate",
    validator: validate_PostCreateConfigurationTemplate_603298, base: "/",
    url: url_PostCreateConfigurationTemplate_603299,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateConfigurationTemplate_603272 = ref object of OpenApiRestCall_602434
proc url_GetCreateConfigurationTemplate_603274(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateConfigurationTemplate_603273(path: JsonNode;
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
  var valid_603275 = query.getOrDefault("SourceConfiguration.ApplicationName")
  valid_603275 = validateParameter(valid_603275, JString, required = false,
                                 default = nil)
  if valid_603275 != nil:
    section.add "SourceConfiguration.ApplicationName", valid_603275
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_603276 = query.getOrDefault("ApplicationName")
  valid_603276 = validateParameter(valid_603276, JString, required = true,
                                 default = nil)
  if valid_603276 != nil:
    section.add "ApplicationName", valid_603276
  var valid_603277 = query.getOrDefault("Description")
  valid_603277 = validateParameter(valid_603277, JString, required = false,
                                 default = nil)
  if valid_603277 != nil:
    section.add "Description", valid_603277
  var valid_603278 = query.getOrDefault("PlatformArn")
  valid_603278 = validateParameter(valid_603278, JString, required = false,
                                 default = nil)
  if valid_603278 != nil:
    section.add "PlatformArn", valid_603278
  var valid_603279 = query.getOrDefault("Tags")
  valid_603279 = validateParameter(valid_603279, JArray, required = false,
                                 default = nil)
  if valid_603279 != nil:
    section.add "Tags", valid_603279
  var valid_603280 = query.getOrDefault("Action")
  valid_603280 = validateParameter(valid_603280, JString, required = true, default = newJString(
      "CreateConfigurationTemplate"))
  if valid_603280 != nil:
    section.add "Action", valid_603280
  var valid_603281 = query.getOrDefault("SolutionStackName")
  valid_603281 = validateParameter(valid_603281, JString, required = false,
                                 default = nil)
  if valid_603281 != nil:
    section.add "SolutionStackName", valid_603281
  var valid_603282 = query.getOrDefault("EnvironmentId")
  valid_603282 = validateParameter(valid_603282, JString, required = false,
                                 default = nil)
  if valid_603282 != nil:
    section.add "EnvironmentId", valid_603282
  var valid_603283 = query.getOrDefault("TemplateName")
  valid_603283 = validateParameter(valid_603283, JString, required = true,
                                 default = nil)
  if valid_603283 != nil:
    section.add "TemplateName", valid_603283
  var valid_603284 = query.getOrDefault("OptionSettings")
  valid_603284 = validateParameter(valid_603284, JArray, required = false,
                                 default = nil)
  if valid_603284 != nil:
    section.add "OptionSettings", valid_603284
  var valid_603285 = query.getOrDefault("Version")
  valid_603285 = validateParameter(valid_603285, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603285 != nil:
    section.add "Version", valid_603285
  var valid_603286 = query.getOrDefault("SourceConfiguration.TemplateName")
  valid_603286 = validateParameter(valid_603286, JString, required = false,
                                 default = nil)
  if valid_603286 != nil:
    section.add "SourceConfiguration.TemplateName", valid_603286
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
  var valid_603287 = header.getOrDefault("X-Amz-Date")
  valid_603287 = validateParameter(valid_603287, JString, required = false,
                                 default = nil)
  if valid_603287 != nil:
    section.add "X-Amz-Date", valid_603287
  var valid_603288 = header.getOrDefault("X-Amz-Security-Token")
  valid_603288 = validateParameter(valid_603288, JString, required = false,
                                 default = nil)
  if valid_603288 != nil:
    section.add "X-Amz-Security-Token", valid_603288
  var valid_603289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "X-Amz-Content-Sha256", valid_603289
  var valid_603290 = header.getOrDefault("X-Amz-Algorithm")
  valid_603290 = validateParameter(valid_603290, JString, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "X-Amz-Algorithm", valid_603290
  var valid_603291 = header.getOrDefault("X-Amz-Signature")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "X-Amz-Signature", valid_603291
  var valid_603292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "X-Amz-SignedHeaders", valid_603292
  var valid_603293 = header.getOrDefault("X-Amz-Credential")
  valid_603293 = validateParameter(valid_603293, JString, required = false,
                                 default = nil)
  if valid_603293 != nil:
    section.add "X-Amz-Credential", valid_603293
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603294: Call_GetCreateConfigurationTemplate_603272; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a configuration template. Templates are associated with a specific application and are used to deploy different versions of the application with the same configuration settings.</p> <p>Templates aren't associated with any environment. The <code>EnvironmentName</code> response element is always <code>null</code>.</p> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> <li> <p> <a>DescribeConfigurationSettings</a> </p> </li> <li> <p> <a>ListAvailableSolutionStacks</a> </p> </li> </ul>
  ## 
  let valid = call_603294.validator(path, query, header, formData, body)
  let scheme = call_603294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603294.url(scheme.get, call_603294.host, call_603294.base,
                         call_603294.route, valid.getOrDefault("path"))
  result = hook(call_603294, url, valid)

proc call*(call_603295: Call_GetCreateConfigurationTemplate_603272;
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
  var query_603296 = newJObject()
  add(query_603296, "SourceConfiguration.ApplicationName",
      newJString(SourceConfigurationApplicationName))
  add(query_603296, "ApplicationName", newJString(ApplicationName))
  add(query_603296, "Description", newJString(Description))
  add(query_603296, "PlatformArn", newJString(PlatformArn))
  if Tags != nil:
    query_603296.add "Tags", Tags
  add(query_603296, "Action", newJString(Action))
  add(query_603296, "SolutionStackName", newJString(SolutionStackName))
  add(query_603296, "EnvironmentId", newJString(EnvironmentId))
  add(query_603296, "TemplateName", newJString(TemplateName))
  if OptionSettings != nil:
    query_603296.add "OptionSettings", OptionSettings
  add(query_603296, "Version", newJString(Version))
  add(query_603296, "SourceConfiguration.TemplateName",
      newJString(SourceConfigurationTemplateName))
  result = call_603295.call(nil, query_603296, nil, nil, nil)

var getCreateConfigurationTemplate* = Call_GetCreateConfigurationTemplate_603272(
    name: "getCreateConfigurationTemplate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateConfigurationTemplate",
    validator: validate_GetCreateConfigurationTemplate_603273, base: "/",
    url: url_GetCreateConfigurationTemplate_603274,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEnvironment_603353 = ref object of OpenApiRestCall_602434
proc url_PostCreateEnvironment_603355(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateEnvironment_603354(path: JsonNode; query: JsonNode;
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
  var valid_603356 = query.getOrDefault("Action")
  valid_603356 = validateParameter(valid_603356, JString, required = true,
                                 default = newJString("CreateEnvironment"))
  if valid_603356 != nil:
    section.add "Action", valid_603356
  var valid_603357 = query.getOrDefault("Version")
  valid_603357 = validateParameter(valid_603357, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603357 != nil:
    section.add "Version", valid_603357
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
  var valid_603358 = header.getOrDefault("X-Amz-Date")
  valid_603358 = validateParameter(valid_603358, JString, required = false,
                                 default = nil)
  if valid_603358 != nil:
    section.add "X-Amz-Date", valid_603358
  var valid_603359 = header.getOrDefault("X-Amz-Security-Token")
  valid_603359 = validateParameter(valid_603359, JString, required = false,
                                 default = nil)
  if valid_603359 != nil:
    section.add "X-Amz-Security-Token", valid_603359
  var valid_603360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603360 = validateParameter(valid_603360, JString, required = false,
                                 default = nil)
  if valid_603360 != nil:
    section.add "X-Amz-Content-Sha256", valid_603360
  var valid_603361 = header.getOrDefault("X-Amz-Algorithm")
  valid_603361 = validateParameter(valid_603361, JString, required = false,
                                 default = nil)
  if valid_603361 != nil:
    section.add "X-Amz-Algorithm", valid_603361
  var valid_603362 = header.getOrDefault("X-Amz-Signature")
  valid_603362 = validateParameter(valid_603362, JString, required = false,
                                 default = nil)
  if valid_603362 != nil:
    section.add "X-Amz-Signature", valid_603362
  var valid_603363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603363 = validateParameter(valid_603363, JString, required = false,
                                 default = nil)
  if valid_603363 != nil:
    section.add "X-Amz-SignedHeaders", valid_603363
  var valid_603364 = header.getOrDefault("X-Amz-Credential")
  valid_603364 = validateParameter(valid_603364, JString, required = false,
                                 default = nil)
  if valid_603364 != nil:
    section.add "X-Amz-Credential", valid_603364
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
  var valid_603365 = formData.getOrDefault("Tier.Name")
  valid_603365 = validateParameter(valid_603365, JString, required = false,
                                 default = nil)
  if valid_603365 != nil:
    section.add "Tier.Name", valid_603365
  var valid_603366 = formData.getOrDefault("OptionsToRemove")
  valid_603366 = validateParameter(valid_603366, JArray, required = false,
                                 default = nil)
  if valid_603366 != nil:
    section.add "OptionsToRemove", valid_603366
  var valid_603367 = formData.getOrDefault("VersionLabel")
  valid_603367 = validateParameter(valid_603367, JString, required = false,
                                 default = nil)
  if valid_603367 != nil:
    section.add "VersionLabel", valid_603367
  var valid_603368 = formData.getOrDefault("OptionSettings")
  valid_603368 = validateParameter(valid_603368, JArray, required = false,
                                 default = nil)
  if valid_603368 != nil:
    section.add "OptionSettings", valid_603368
  var valid_603369 = formData.getOrDefault("GroupName")
  valid_603369 = validateParameter(valid_603369, JString, required = false,
                                 default = nil)
  if valid_603369 != nil:
    section.add "GroupName", valid_603369
  var valid_603370 = formData.getOrDefault("Tags")
  valid_603370 = validateParameter(valid_603370, JArray, required = false,
                                 default = nil)
  if valid_603370 != nil:
    section.add "Tags", valid_603370
  var valid_603371 = formData.getOrDefault("CNAMEPrefix")
  valid_603371 = validateParameter(valid_603371, JString, required = false,
                                 default = nil)
  if valid_603371 != nil:
    section.add "CNAMEPrefix", valid_603371
  var valid_603372 = formData.getOrDefault("SolutionStackName")
  valid_603372 = validateParameter(valid_603372, JString, required = false,
                                 default = nil)
  if valid_603372 != nil:
    section.add "SolutionStackName", valid_603372
  var valid_603373 = formData.getOrDefault("EnvironmentName")
  valid_603373 = validateParameter(valid_603373, JString, required = false,
                                 default = nil)
  if valid_603373 != nil:
    section.add "EnvironmentName", valid_603373
  var valid_603374 = formData.getOrDefault("Tier.Type")
  valid_603374 = validateParameter(valid_603374, JString, required = false,
                                 default = nil)
  if valid_603374 != nil:
    section.add "Tier.Type", valid_603374
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_603375 = formData.getOrDefault("ApplicationName")
  valid_603375 = validateParameter(valid_603375, JString, required = true,
                                 default = nil)
  if valid_603375 != nil:
    section.add "ApplicationName", valid_603375
  var valid_603376 = formData.getOrDefault("PlatformArn")
  valid_603376 = validateParameter(valid_603376, JString, required = false,
                                 default = nil)
  if valid_603376 != nil:
    section.add "PlatformArn", valid_603376
  var valid_603377 = formData.getOrDefault("TemplateName")
  valid_603377 = validateParameter(valid_603377, JString, required = false,
                                 default = nil)
  if valid_603377 != nil:
    section.add "TemplateName", valid_603377
  var valid_603378 = formData.getOrDefault("Description")
  valid_603378 = validateParameter(valid_603378, JString, required = false,
                                 default = nil)
  if valid_603378 != nil:
    section.add "Description", valid_603378
  var valid_603379 = formData.getOrDefault("Tier.Version")
  valid_603379 = validateParameter(valid_603379, JString, required = false,
                                 default = nil)
  if valid_603379 != nil:
    section.add "Tier.Version", valid_603379
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603380: Call_PostCreateEnvironment_603353; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Launches an environment for the specified application using the specified configuration.
  ## 
  let valid = call_603380.validator(path, query, header, formData, body)
  let scheme = call_603380.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603380.url(scheme.get, call_603380.host, call_603380.base,
                         call_603380.route, valid.getOrDefault("path"))
  result = hook(call_603380, url, valid)

proc call*(call_603381: Call_PostCreateEnvironment_603353; ApplicationName: string;
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
  var query_603382 = newJObject()
  var formData_603383 = newJObject()
  add(formData_603383, "Tier.Name", newJString(TierName))
  if OptionsToRemove != nil:
    formData_603383.add "OptionsToRemove", OptionsToRemove
  add(formData_603383, "VersionLabel", newJString(VersionLabel))
  if OptionSettings != nil:
    formData_603383.add "OptionSettings", OptionSettings
  add(formData_603383, "GroupName", newJString(GroupName))
  if Tags != nil:
    formData_603383.add "Tags", Tags
  add(formData_603383, "CNAMEPrefix", newJString(CNAMEPrefix))
  add(formData_603383, "SolutionStackName", newJString(SolutionStackName))
  add(formData_603383, "EnvironmentName", newJString(EnvironmentName))
  add(formData_603383, "Tier.Type", newJString(TierType))
  add(query_603382, "Action", newJString(Action))
  add(formData_603383, "ApplicationName", newJString(ApplicationName))
  add(formData_603383, "PlatformArn", newJString(PlatformArn))
  add(formData_603383, "TemplateName", newJString(TemplateName))
  add(query_603382, "Version", newJString(Version))
  add(formData_603383, "Description", newJString(Description))
  add(formData_603383, "Tier.Version", newJString(TierVersion))
  result = call_603381.call(nil, query_603382, nil, formData_603383, nil)

var postCreateEnvironment* = Call_PostCreateEnvironment_603353(
    name: "postCreateEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateEnvironment",
    validator: validate_PostCreateEnvironment_603354, base: "/",
    url: url_PostCreateEnvironment_603355, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEnvironment_603323 = ref object of OpenApiRestCall_602434
proc url_GetCreateEnvironment_603325(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateEnvironment_603324(path: JsonNode; query: JsonNode;
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
  var valid_603326 = query.getOrDefault("Tier.Name")
  valid_603326 = validateParameter(valid_603326, JString, required = false,
                                 default = nil)
  if valid_603326 != nil:
    section.add "Tier.Name", valid_603326
  var valid_603327 = query.getOrDefault("VersionLabel")
  valid_603327 = validateParameter(valid_603327, JString, required = false,
                                 default = nil)
  if valid_603327 != nil:
    section.add "VersionLabel", valid_603327
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_603328 = query.getOrDefault("ApplicationName")
  valid_603328 = validateParameter(valid_603328, JString, required = true,
                                 default = nil)
  if valid_603328 != nil:
    section.add "ApplicationName", valid_603328
  var valid_603329 = query.getOrDefault("Description")
  valid_603329 = validateParameter(valid_603329, JString, required = false,
                                 default = nil)
  if valid_603329 != nil:
    section.add "Description", valid_603329
  var valid_603330 = query.getOrDefault("OptionsToRemove")
  valid_603330 = validateParameter(valid_603330, JArray, required = false,
                                 default = nil)
  if valid_603330 != nil:
    section.add "OptionsToRemove", valid_603330
  var valid_603331 = query.getOrDefault("PlatformArn")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "PlatformArn", valid_603331
  var valid_603332 = query.getOrDefault("Tags")
  valid_603332 = validateParameter(valid_603332, JArray, required = false,
                                 default = nil)
  if valid_603332 != nil:
    section.add "Tags", valid_603332
  var valid_603333 = query.getOrDefault("EnvironmentName")
  valid_603333 = validateParameter(valid_603333, JString, required = false,
                                 default = nil)
  if valid_603333 != nil:
    section.add "EnvironmentName", valid_603333
  var valid_603334 = query.getOrDefault("Action")
  valid_603334 = validateParameter(valid_603334, JString, required = true,
                                 default = newJString("CreateEnvironment"))
  if valid_603334 != nil:
    section.add "Action", valid_603334
  var valid_603335 = query.getOrDefault("SolutionStackName")
  valid_603335 = validateParameter(valid_603335, JString, required = false,
                                 default = nil)
  if valid_603335 != nil:
    section.add "SolutionStackName", valid_603335
  var valid_603336 = query.getOrDefault("Tier.Version")
  valid_603336 = validateParameter(valid_603336, JString, required = false,
                                 default = nil)
  if valid_603336 != nil:
    section.add "Tier.Version", valid_603336
  var valid_603337 = query.getOrDefault("TemplateName")
  valid_603337 = validateParameter(valid_603337, JString, required = false,
                                 default = nil)
  if valid_603337 != nil:
    section.add "TemplateName", valid_603337
  var valid_603338 = query.getOrDefault("GroupName")
  valid_603338 = validateParameter(valid_603338, JString, required = false,
                                 default = nil)
  if valid_603338 != nil:
    section.add "GroupName", valid_603338
  var valid_603339 = query.getOrDefault("OptionSettings")
  valid_603339 = validateParameter(valid_603339, JArray, required = false,
                                 default = nil)
  if valid_603339 != nil:
    section.add "OptionSettings", valid_603339
  var valid_603340 = query.getOrDefault("Tier.Type")
  valid_603340 = validateParameter(valid_603340, JString, required = false,
                                 default = nil)
  if valid_603340 != nil:
    section.add "Tier.Type", valid_603340
  var valid_603341 = query.getOrDefault("Version")
  valid_603341 = validateParameter(valid_603341, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603341 != nil:
    section.add "Version", valid_603341
  var valid_603342 = query.getOrDefault("CNAMEPrefix")
  valid_603342 = validateParameter(valid_603342, JString, required = false,
                                 default = nil)
  if valid_603342 != nil:
    section.add "CNAMEPrefix", valid_603342
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
  var valid_603343 = header.getOrDefault("X-Amz-Date")
  valid_603343 = validateParameter(valid_603343, JString, required = false,
                                 default = nil)
  if valid_603343 != nil:
    section.add "X-Amz-Date", valid_603343
  var valid_603344 = header.getOrDefault("X-Amz-Security-Token")
  valid_603344 = validateParameter(valid_603344, JString, required = false,
                                 default = nil)
  if valid_603344 != nil:
    section.add "X-Amz-Security-Token", valid_603344
  var valid_603345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603345 = validateParameter(valid_603345, JString, required = false,
                                 default = nil)
  if valid_603345 != nil:
    section.add "X-Amz-Content-Sha256", valid_603345
  var valid_603346 = header.getOrDefault("X-Amz-Algorithm")
  valid_603346 = validateParameter(valid_603346, JString, required = false,
                                 default = nil)
  if valid_603346 != nil:
    section.add "X-Amz-Algorithm", valid_603346
  var valid_603347 = header.getOrDefault("X-Amz-Signature")
  valid_603347 = validateParameter(valid_603347, JString, required = false,
                                 default = nil)
  if valid_603347 != nil:
    section.add "X-Amz-Signature", valid_603347
  var valid_603348 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603348 = validateParameter(valid_603348, JString, required = false,
                                 default = nil)
  if valid_603348 != nil:
    section.add "X-Amz-SignedHeaders", valid_603348
  var valid_603349 = header.getOrDefault("X-Amz-Credential")
  valid_603349 = validateParameter(valid_603349, JString, required = false,
                                 default = nil)
  if valid_603349 != nil:
    section.add "X-Amz-Credential", valid_603349
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603350: Call_GetCreateEnvironment_603323; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Launches an environment for the specified application using the specified configuration.
  ## 
  let valid = call_603350.validator(path, query, header, formData, body)
  let scheme = call_603350.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603350.url(scheme.get, call_603350.host, call_603350.base,
                         call_603350.route, valid.getOrDefault("path"))
  result = hook(call_603350, url, valid)

proc call*(call_603351: Call_GetCreateEnvironment_603323; ApplicationName: string;
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
  var query_603352 = newJObject()
  add(query_603352, "Tier.Name", newJString(TierName))
  add(query_603352, "VersionLabel", newJString(VersionLabel))
  add(query_603352, "ApplicationName", newJString(ApplicationName))
  add(query_603352, "Description", newJString(Description))
  if OptionsToRemove != nil:
    query_603352.add "OptionsToRemove", OptionsToRemove
  add(query_603352, "PlatformArn", newJString(PlatformArn))
  if Tags != nil:
    query_603352.add "Tags", Tags
  add(query_603352, "EnvironmentName", newJString(EnvironmentName))
  add(query_603352, "Action", newJString(Action))
  add(query_603352, "SolutionStackName", newJString(SolutionStackName))
  add(query_603352, "Tier.Version", newJString(TierVersion))
  add(query_603352, "TemplateName", newJString(TemplateName))
  add(query_603352, "GroupName", newJString(GroupName))
  if OptionSettings != nil:
    query_603352.add "OptionSettings", OptionSettings
  add(query_603352, "Tier.Type", newJString(TierType))
  add(query_603352, "Version", newJString(Version))
  add(query_603352, "CNAMEPrefix", newJString(CNAMEPrefix))
  result = call_603351.call(nil, query_603352, nil, nil, nil)

var getCreateEnvironment* = Call_GetCreateEnvironment_603323(
    name: "getCreateEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateEnvironment",
    validator: validate_GetCreateEnvironment_603324, base: "/",
    url: url_GetCreateEnvironment_603325, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreatePlatformVersion_603406 = ref object of OpenApiRestCall_602434
proc url_PostCreatePlatformVersion_603408(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreatePlatformVersion_603407(path: JsonNode; query: JsonNode;
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
  var valid_603409 = query.getOrDefault("Action")
  valid_603409 = validateParameter(valid_603409, JString, required = true,
                                 default = newJString("CreatePlatformVersion"))
  if valid_603409 != nil:
    section.add "Action", valid_603409
  var valid_603410 = query.getOrDefault("Version")
  valid_603410 = validateParameter(valid_603410, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603410 != nil:
    section.add "Version", valid_603410
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
  var valid_603411 = header.getOrDefault("X-Amz-Date")
  valid_603411 = validateParameter(valid_603411, JString, required = false,
                                 default = nil)
  if valid_603411 != nil:
    section.add "X-Amz-Date", valid_603411
  var valid_603412 = header.getOrDefault("X-Amz-Security-Token")
  valid_603412 = validateParameter(valid_603412, JString, required = false,
                                 default = nil)
  if valid_603412 != nil:
    section.add "X-Amz-Security-Token", valid_603412
  var valid_603413 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603413 = validateParameter(valid_603413, JString, required = false,
                                 default = nil)
  if valid_603413 != nil:
    section.add "X-Amz-Content-Sha256", valid_603413
  var valid_603414 = header.getOrDefault("X-Amz-Algorithm")
  valid_603414 = validateParameter(valid_603414, JString, required = false,
                                 default = nil)
  if valid_603414 != nil:
    section.add "X-Amz-Algorithm", valid_603414
  var valid_603415 = header.getOrDefault("X-Amz-Signature")
  valid_603415 = validateParameter(valid_603415, JString, required = false,
                                 default = nil)
  if valid_603415 != nil:
    section.add "X-Amz-Signature", valid_603415
  var valid_603416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603416 = validateParameter(valid_603416, JString, required = false,
                                 default = nil)
  if valid_603416 != nil:
    section.add "X-Amz-SignedHeaders", valid_603416
  var valid_603417 = header.getOrDefault("X-Amz-Credential")
  valid_603417 = validateParameter(valid_603417, JString, required = false,
                                 default = nil)
  if valid_603417 != nil:
    section.add "X-Amz-Credential", valid_603417
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
  var valid_603418 = formData.getOrDefault("PlatformName")
  valid_603418 = validateParameter(valid_603418, JString, required = true,
                                 default = nil)
  if valid_603418 != nil:
    section.add "PlatformName", valid_603418
  var valid_603419 = formData.getOrDefault("PlatformDefinitionBundle.S3Key")
  valid_603419 = validateParameter(valid_603419, JString, required = false,
                                 default = nil)
  if valid_603419 != nil:
    section.add "PlatformDefinitionBundle.S3Key", valid_603419
  var valid_603420 = formData.getOrDefault("OptionSettings")
  valid_603420 = validateParameter(valid_603420, JArray, required = false,
                                 default = nil)
  if valid_603420 != nil:
    section.add "OptionSettings", valid_603420
  var valid_603421 = formData.getOrDefault("Tags")
  valid_603421 = validateParameter(valid_603421, JArray, required = false,
                                 default = nil)
  if valid_603421 != nil:
    section.add "Tags", valid_603421
  var valid_603422 = formData.getOrDefault("EnvironmentName")
  valid_603422 = validateParameter(valid_603422, JString, required = false,
                                 default = nil)
  if valid_603422 != nil:
    section.add "EnvironmentName", valid_603422
  var valid_603423 = formData.getOrDefault("PlatformDefinitionBundle.S3Bucket")
  valid_603423 = validateParameter(valid_603423, JString, required = false,
                                 default = nil)
  if valid_603423 != nil:
    section.add "PlatformDefinitionBundle.S3Bucket", valid_603423
  var valid_603424 = formData.getOrDefault("PlatformVersion")
  valid_603424 = validateParameter(valid_603424, JString, required = true,
                                 default = nil)
  if valid_603424 != nil:
    section.add "PlatformVersion", valid_603424
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603425: Call_PostCreatePlatformVersion_603406; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new version of your custom platform.
  ## 
  let valid = call_603425.validator(path, query, header, formData, body)
  let scheme = call_603425.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603425.url(scheme.get, call_603425.host, call_603425.base,
                         call_603425.route, valid.getOrDefault("path"))
  result = hook(call_603425, url, valid)

proc call*(call_603426: Call_PostCreatePlatformVersion_603406;
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
  var query_603427 = newJObject()
  var formData_603428 = newJObject()
  add(formData_603428, "PlatformName", newJString(PlatformName))
  add(formData_603428, "PlatformDefinitionBundle.S3Key",
      newJString(PlatformDefinitionBundleS3Key))
  if OptionSettings != nil:
    formData_603428.add "OptionSettings", OptionSettings
  if Tags != nil:
    formData_603428.add "Tags", Tags
  add(formData_603428, "EnvironmentName", newJString(EnvironmentName))
  add(formData_603428, "PlatformDefinitionBundle.S3Bucket",
      newJString(PlatformDefinitionBundleS3Bucket))
  add(query_603427, "Action", newJString(Action))
  add(formData_603428, "PlatformVersion", newJString(PlatformVersion))
  add(query_603427, "Version", newJString(Version))
  result = call_603426.call(nil, query_603427, nil, formData_603428, nil)

var postCreatePlatformVersion* = Call_PostCreatePlatformVersion_603406(
    name: "postCreatePlatformVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreatePlatformVersion",
    validator: validate_PostCreatePlatformVersion_603407, base: "/",
    url: url_PostCreatePlatformVersion_603408,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreatePlatformVersion_603384 = ref object of OpenApiRestCall_602434
proc url_GetCreatePlatformVersion_603386(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreatePlatformVersion_603385(path: JsonNode; query: JsonNode;
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
  var valid_603387 = query.getOrDefault("Tags")
  valid_603387 = validateParameter(valid_603387, JArray, required = false,
                                 default = nil)
  if valid_603387 != nil:
    section.add "Tags", valid_603387
  var valid_603388 = query.getOrDefault("EnvironmentName")
  valid_603388 = validateParameter(valid_603388, JString, required = false,
                                 default = nil)
  if valid_603388 != nil:
    section.add "EnvironmentName", valid_603388
  var valid_603389 = query.getOrDefault("PlatformDefinitionBundle.S3Key")
  valid_603389 = validateParameter(valid_603389, JString, required = false,
                                 default = nil)
  if valid_603389 != nil:
    section.add "PlatformDefinitionBundle.S3Key", valid_603389
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603390 = query.getOrDefault("Action")
  valid_603390 = validateParameter(valid_603390, JString, required = true,
                                 default = newJString("CreatePlatformVersion"))
  if valid_603390 != nil:
    section.add "Action", valid_603390
  var valid_603391 = query.getOrDefault("OptionSettings")
  valid_603391 = validateParameter(valid_603391, JArray, required = false,
                                 default = nil)
  if valid_603391 != nil:
    section.add "OptionSettings", valid_603391
  var valid_603392 = query.getOrDefault("PlatformName")
  valid_603392 = validateParameter(valid_603392, JString, required = true,
                                 default = nil)
  if valid_603392 != nil:
    section.add "PlatformName", valid_603392
  var valid_603393 = query.getOrDefault("Version")
  valid_603393 = validateParameter(valid_603393, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603393 != nil:
    section.add "Version", valid_603393
  var valid_603394 = query.getOrDefault("PlatformDefinitionBundle.S3Bucket")
  valid_603394 = validateParameter(valid_603394, JString, required = false,
                                 default = nil)
  if valid_603394 != nil:
    section.add "PlatformDefinitionBundle.S3Bucket", valid_603394
  var valid_603395 = query.getOrDefault("PlatformVersion")
  valid_603395 = validateParameter(valid_603395, JString, required = true,
                                 default = nil)
  if valid_603395 != nil:
    section.add "PlatformVersion", valid_603395
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
  var valid_603396 = header.getOrDefault("X-Amz-Date")
  valid_603396 = validateParameter(valid_603396, JString, required = false,
                                 default = nil)
  if valid_603396 != nil:
    section.add "X-Amz-Date", valid_603396
  var valid_603397 = header.getOrDefault("X-Amz-Security-Token")
  valid_603397 = validateParameter(valid_603397, JString, required = false,
                                 default = nil)
  if valid_603397 != nil:
    section.add "X-Amz-Security-Token", valid_603397
  var valid_603398 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603398 = validateParameter(valid_603398, JString, required = false,
                                 default = nil)
  if valid_603398 != nil:
    section.add "X-Amz-Content-Sha256", valid_603398
  var valid_603399 = header.getOrDefault("X-Amz-Algorithm")
  valid_603399 = validateParameter(valid_603399, JString, required = false,
                                 default = nil)
  if valid_603399 != nil:
    section.add "X-Amz-Algorithm", valid_603399
  var valid_603400 = header.getOrDefault("X-Amz-Signature")
  valid_603400 = validateParameter(valid_603400, JString, required = false,
                                 default = nil)
  if valid_603400 != nil:
    section.add "X-Amz-Signature", valid_603400
  var valid_603401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603401 = validateParameter(valid_603401, JString, required = false,
                                 default = nil)
  if valid_603401 != nil:
    section.add "X-Amz-SignedHeaders", valid_603401
  var valid_603402 = header.getOrDefault("X-Amz-Credential")
  valid_603402 = validateParameter(valid_603402, JString, required = false,
                                 default = nil)
  if valid_603402 != nil:
    section.add "X-Amz-Credential", valid_603402
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603403: Call_GetCreatePlatformVersion_603384; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new version of your custom platform.
  ## 
  let valid = call_603403.validator(path, query, header, formData, body)
  let scheme = call_603403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603403.url(scheme.get, call_603403.host, call_603403.base,
                         call_603403.route, valid.getOrDefault("path"))
  result = hook(call_603403, url, valid)

proc call*(call_603404: Call_GetCreatePlatformVersion_603384; PlatformName: string;
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
  var query_603405 = newJObject()
  if Tags != nil:
    query_603405.add "Tags", Tags
  add(query_603405, "EnvironmentName", newJString(EnvironmentName))
  add(query_603405, "PlatformDefinitionBundle.S3Key",
      newJString(PlatformDefinitionBundleS3Key))
  add(query_603405, "Action", newJString(Action))
  if OptionSettings != nil:
    query_603405.add "OptionSettings", OptionSettings
  add(query_603405, "PlatformName", newJString(PlatformName))
  add(query_603405, "Version", newJString(Version))
  add(query_603405, "PlatformDefinitionBundle.S3Bucket",
      newJString(PlatformDefinitionBundleS3Bucket))
  add(query_603405, "PlatformVersion", newJString(PlatformVersion))
  result = call_603404.call(nil, query_603405, nil, nil, nil)

var getCreatePlatformVersion* = Call_GetCreatePlatformVersion_603384(
    name: "getCreatePlatformVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreatePlatformVersion",
    validator: validate_GetCreatePlatformVersion_603385, base: "/",
    url: url_GetCreatePlatformVersion_603386, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateStorageLocation_603444 = ref object of OpenApiRestCall_602434
proc url_PostCreateStorageLocation_603446(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateStorageLocation_603445(path: JsonNode; query: JsonNode;
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
  var valid_603447 = query.getOrDefault("Action")
  valid_603447 = validateParameter(valid_603447, JString, required = true,
                                 default = newJString("CreateStorageLocation"))
  if valid_603447 != nil:
    section.add "Action", valid_603447
  var valid_603448 = query.getOrDefault("Version")
  valid_603448 = validateParameter(valid_603448, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603448 != nil:
    section.add "Version", valid_603448
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
  var valid_603449 = header.getOrDefault("X-Amz-Date")
  valid_603449 = validateParameter(valid_603449, JString, required = false,
                                 default = nil)
  if valid_603449 != nil:
    section.add "X-Amz-Date", valid_603449
  var valid_603450 = header.getOrDefault("X-Amz-Security-Token")
  valid_603450 = validateParameter(valid_603450, JString, required = false,
                                 default = nil)
  if valid_603450 != nil:
    section.add "X-Amz-Security-Token", valid_603450
  var valid_603451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603451 = validateParameter(valid_603451, JString, required = false,
                                 default = nil)
  if valid_603451 != nil:
    section.add "X-Amz-Content-Sha256", valid_603451
  var valid_603452 = header.getOrDefault("X-Amz-Algorithm")
  valid_603452 = validateParameter(valid_603452, JString, required = false,
                                 default = nil)
  if valid_603452 != nil:
    section.add "X-Amz-Algorithm", valid_603452
  var valid_603453 = header.getOrDefault("X-Amz-Signature")
  valid_603453 = validateParameter(valid_603453, JString, required = false,
                                 default = nil)
  if valid_603453 != nil:
    section.add "X-Amz-Signature", valid_603453
  var valid_603454 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603454 = validateParameter(valid_603454, JString, required = false,
                                 default = nil)
  if valid_603454 != nil:
    section.add "X-Amz-SignedHeaders", valid_603454
  var valid_603455 = header.getOrDefault("X-Amz-Credential")
  valid_603455 = validateParameter(valid_603455, JString, required = false,
                                 default = nil)
  if valid_603455 != nil:
    section.add "X-Amz-Credential", valid_603455
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603456: Call_PostCreateStorageLocation_603444; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ## 
  let valid = call_603456.validator(path, query, header, formData, body)
  let scheme = call_603456.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603456.url(scheme.get, call_603456.host, call_603456.base,
                         call_603456.route, valid.getOrDefault("path"))
  result = hook(call_603456, url, valid)

proc call*(call_603457: Call_PostCreateStorageLocation_603444;
          Action: string = "CreateStorageLocation"; Version: string = "2010-12-01"): Recallable =
  ## postCreateStorageLocation
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603458 = newJObject()
  add(query_603458, "Action", newJString(Action))
  add(query_603458, "Version", newJString(Version))
  result = call_603457.call(nil, query_603458, nil, nil, nil)

var postCreateStorageLocation* = Call_PostCreateStorageLocation_603444(
    name: "postCreateStorageLocation", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateStorageLocation",
    validator: validate_PostCreateStorageLocation_603445, base: "/",
    url: url_PostCreateStorageLocation_603446,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateStorageLocation_603429 = ref object of OpenApiRestCall_602434
proc url_GetCreateStorageLocation_603431(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateStorageLocation_603430(path: JsonNode; query: JsonNode;
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
  var valid_603432 = query.getOrDefault("Action")
  valid_603432 = validateParameter(valid_603432, JString, required = true,
                                 default = newJString("CreateStorageLocation"))
  if valid_603432 != nil:
    section.add "Action", valid_603432
  var valid_603433 = query.getOrDefault("Version")
  valid_603433 = validateParameter(valid_603433, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603433 != nil:
    section.add "Version", valid_603433
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
  var valid_603434 = header.getOrDefault("X-Amz-Date")
  valid_603434 = validateParameter(valid_603434, JString, required = false,
                                 default = nil)
  if valid_603434 != nil:
    section.add "X-Amz-Date", valid_603434
  var valid_603435 = header.getOrDefault("X-Amz-Security-Token")
  valid_603435 = validateParameter(valid_603435, JString, required = false,
                                 default = nil)
  if valid_603435 != nil:
    section.add "X-Amz-Security-Token", valid_603435
  var valid_603436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603436 = validateParameter(valid_603436, JString, required = false,
                                 default = nil)
  if valid_603436 != nil:
    section.add "X-Amz-Content-Sha256", valid_603436
  var valid_603437 = header.getOrDefault("X-Amz-Algorithm")
  valid_603437 = validateParameter(valid_603437, JString, required = false,
                                 default = nil)
  if valid_603437 != nil:
    section.add "X-Amz-Algorithm", valid_603437
  var valid_603438 = header.getOrDefault("X-Amz-Signature")
  valid_603438 = validateParameter(valid_603438, JString, required = false,
                                 default = nil)
  if valid_603438 != nil:
    section.add "X-Amz-Signature", valid_603438
  var valid_603439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603439 = validateParameter(valid_603439, JString, required = false,
                                 default = nil)
  if valid_603439 != nil:
    section.add "X-Amz-SignedHeaders", valid_603439
  var valid_603440 = header.getOrDefault("X-Amz-Credential")
  valid_603440 = validateParameter(valid_603440, JString, required = false,
                                 default = nil)
  if valid_603440 != nil:
    section.add "X-Amz-Credential", valid_603440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603441: Call_GetCreateStorageLocation_603429; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ## 
  let valid = call_603441.validator(path, query, header, formData, body)
  let scheme = call_603441.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603441.url(scheme.get, call_603441.host, call_603441.base,
                         call_603441.route, valid.getOrDefault("path"))
  result = hook(call_603441, url, valid)

proc call*(call_603442: Call_GetCreateStorageLocation_603429;
          Action: string = "CreateStorageLocation"; Version: string = "2010-12-01"): Recallable =
  ## getCreateStorageLocation
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603443 = newJObject()
  add(query_603443, "Action", newJString(Action))
  add(query_603443, "Version", newJString(Version))
  result = call_603442.call(nil, query_603443, nil, nil, nil)

var getCreateStorageLocation* = Call_GetCreateStorageLocation_603429(
    name: "getCreateStorageLocation", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateStorageLocation",
    validator: validate_GetCreateStorageLocation_603430, base: "/",
    url: url_GetCreateStorageLocation_603431, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteApplication_603476 = ref object of OpenApiRestCall_602434
proc url_PostDeleteApplication_603478(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteApplication_603477(path: JsonNode; query: JsonNode;
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
  var valid_603479 = query.getOrDefault("Action")
  valid_603479 = validateParameter(valid_603479, JString, required = true,
                                 default = newJString("DeleteApplication"))
  if valid_603479 != nil:
    section.add "Action", valid_603479
  var valid_603480 = query.getOrDefault("Version")
  valid_603480 = validateParameter(valid_603480, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603480 != nil:
    section.add "Version", valid_603480
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
  var valid_603481 = header.getOrDefault("X-Amz-Date")
  valid_603481 = validateParameter(valid_603481, JString, required = false,
                                 default = nil)
  if valid_603481 != nil:
    section.add "X-Amz-Date", valid_603481
  var valid_603482 = header.getOrDefault("X-Amz-Security-Token")
  valid_603482 = validateParameter(valid_603482, JString, required = false,
                                 default = nil)
  if valid_603482 != nil:
    section.add "X-Amz-Security-Token", valid_603482
  var valid_603483 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603483 = validateParameter(valid_603483, JString, required = false,
                                 default = nil)
  if valid_603483 != nil:
    section.add "X-Amz-Content-Sha256", valid_603483
  var valid_603484 = header.getOrDefault("X-Amz-Algorithm")
  valid_603484 = validateParameter(valid_603484, JString, required = false,
                                 default = nil)
  if valid_603484 != nil:
    section.add "X-Amz-Algorithm", valid_603484
  var valid_603485 = header.getOrDefault("X-Amz-Signature")
  valid_603485 = validateParameter(valid_603485, JString, required = false,
                                 default = nil)
  if valid_603485 != nil:
    section.add "X-Amz-Signature", valid_603485
  var valid_603486 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603486 = validateParameter(valid_603486, JString, required = false,
                                 default = nil)
  if valid_603486 != nil:
    section.add "X-Amz-SignedHeaders", valid_603486
  var valid_603487 = header.getOrDefault("X-Amz-Credential")
  valid_603487 = validateParameter(valid_603487, JString, required = false,
                                 default = nil)
  if valid_603487 != nil:
    section.add "X-Amz-Credential", valid_603487
  result.add "header", section
  ## parameters in `formData` object:
  ##   TerminateEnvByForce: JBool
  ##                      : When set to true, running environments will be terminated before deleting the application.
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to delete.
  section = newJObject()
  var valid_603488 = formData.getOrDefault("TerminateEnvByForce")
  valid_603488 = validateParameter(valid_603488, JBool, required = false, default = nil)
  if valid_603488 != nil:
    section.add "TerminateEnvByForce", valid_603488
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_603489 = formData.getOrDefault("ApplicationName")
  valid_603489 = validateParameter(valid_603489, JString, required = true,
                                 default = nil)
  if valid_603489 != nil:
    section.add "ApplicationName", valid_603489
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603490: Call_PostDeleteApplication_603476; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified application along with all associated versions and configurations. The application versions will not be deleted from your Amazon S3 bucket.</p> <note> <p>You cannot delete an application that has a running environment.</p> </note>
  ## 
  let valid = call_603490.validator(path, query, header, formData, body)
  let scheme = call_603490.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603490.url(scheme.get, call_603490.host, call_603490.base,
                         call_603490.route, valid.getOrDefault("path"))
  result = hook(call_603490, url, valid)

proc call*(call_603491: Call_PostDeleteApplication_603476; ApplicationName: string;
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
  var query_603492 = newJObject()
  var formData_603493 = newJObject()
  add(formData_603493, "TerminateEnvByForce", newJBool(TerminateEnvByForce))
  add(query_603492, "Action", newJString(Action))
  add(formData_603493, "ApplicationName", newJString(ApplicationName))
  add(query_603492, "Version", newJString(Version))
  result = call_603491.call(nil, query_603492, nil, formData_603493, nil)

var postDeleteApplication* = Call_PostDeleteApplication_603476(
    name: "postDeleteApplication", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=DeleteApplication",
    validator: validate_PostDeleteApplication_603477, base: "/",
    url: url_PostDeleteApplication_603478, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteApplication_603459 = ref object of OpenApiRestCall_602434
proc url_GetDeleteApplication_603461(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteApplication_603460(path: JsonNode; query: JsonNode;
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
  var valid_603462 = query.getOrDefault("TerminateEnvByForce")
  valid_603462 = validateParameter(valid_603462, JBool, required = false, default = nil)
  if valid_603462 != nil:
    section.add "TerminateEnvByForce", valid_603462
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_603463 = query.getOrDefault("ApplicationName")
  valid_603463 = validateParameter(valid_603463, JString, required = true,
                                 default = nil)
  if valid_603463 != nil:
    section.add "ApplicationName", valid_603463
  var valid_603464 = query.getOrDefault("Action")
  valid_603464 = validateParameter(valid_603464, JString, required = true,
                                 default = newJString("DeleteApplication"))
  if valid_603464 != nil:
    section.add "Action", valid_603464
  var valid_603465 = query.getOrDefault("Version")
  valid_603465 = validateParameter(valid_603465, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603465 != nil:
    section.add "Version", valid_603465
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
  var valid_603466 = header.getOrDefault("X-Amz-Date")
  valid_603466 = validateParameter(valid_603466, JString, required = false,
                                 default = nil)
  if valid_603466 != nil:
    section.add "X-Amz-Date", valid_603466
  var valid_603467 = header.getOrDefault("X-Amz-Security-Token")
  valid_603467 = validateParameter(valid_603467, JString, required = false,
                                 default = nil)
  if valid_603467 != nil:
    section.add "X-Amz-Security-Token", valid_603467
  var valid_603468 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603468 = validateParameter(valid_603468, JString, required = false,
                                 default = nil)
  if valid_603468 != nil:
    section.add "X-Amz-Content-Sha256", valid_603468
  var valid_603469 = header.getOrDefault("X-Amz-Algorithm")
  valid_603469 = validateParameter(valid_603469, JString, required = false,
                                 default = nil)
  if valid_603469 != nil:
    section.add "X-Amz-Algorithm", valid_603469
  var valid_603470 = header.getOrDefault("X-Amz-Signature")
  valid_603470 = validateParameter(valid_603470, JString, required = false,
                                 default = nil)
  if valid_603470 != nil:
    section.add "X-Amz-Signature", valid_603470
  var valid_603471 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603471 = validateParameter(valid_603471, JString, required = false,
                                 default = nil)
  if valid_603471 != nil:
    section.add "X-Amz-SignedHeaders", valid_603471
  var valid_603472 = header.getOrDefault("X-Amz-Credential")
  valid_603472 = validateParameter(valid_603472, JString, required = false,
                                 default = nil)
  if valid_603472 != nil:
    section.add "X-Amz-Credential", valid_603472
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603473: Call_GetDeleteApplication_603459; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified application along with all associated versions and configurations. The application versions will not be deleted from your Amazon S3 bucket.</p> <note> <p>You cannot delete an application that has a running environment.</p> </note>
  ## 
  let valid = call_603473.validator(path, query, header, formData, body)
  let scheme = call_603473.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603473.url(scheme.get, call_603473.host, call_603473.base,
                         call_603473.route, valid.getOrDefault("path"))
  result = hook(call_603473, url, valid)

proc call*(call_603474: Call_GetDeleteApplication_603459; ApplicationName: string;
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
  var query_603475 = newJObject()
  add(query_603475, "TerminateEnvByForce", newJBool(TerminateEnvByForce))
  add(query_603475, "ApplicationName", newJString(ApplicationName))
  add(query_603475, "Action", newJString(Action))
  add(query_603475, "Version", newJString(Version))
  result = call_603474.call(nil, query_603475, nil, nil, nil)

var getDeleteApplication* = Call_GetDeleteApplication_603459(
    name: "getDeleteApplication", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=DeleteApplication",
    validator: validate_GetDeleteApplication_603460, base: "/",
    url: url_GetDeleteApplication_603461, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteApplicationVersion_603512 = ref object of OpenApiRestCall_602434
proc url_PostDeleteApplicationVersion_603514(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteApplicationVersion_603513(path: JsonNode; query: JsonNode;
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
  var valid_603515 = query.getOrDefault("Action")
  valid_603515 = validateParameter(valid_603515, JString, required = true, default = newJString(
      "DeleteApplicationVersion"))
  if valid_603515 != nil:
    section.add "Action", valid_603515
  var valid_603516 = query.getOrDefault("Version")
  valid_603516 = validateParameter(valid_603516, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603516 != nil:
    section.add "Version", valid_603516
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
  var valid_603517 = header.getOrDefault("X-Amz-Date")
  valid_603517 = validateParameter(valid_603517, JString, required = false,
                                 default = nil)
  if valid_603517 != nil:
    section.add "X-Amz-Date", valid_603517
  var valid_603518 = header.getOrDefault("X-Amz-Security-Token")
  valid_603518 = validateParameter(valid_603518, JString, required = false,
                                 default = nil)
  if valid_603518 != nil:
    section.add "X-Amz-Security-Token", valid_603518
  var valid_603519 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603519 = validateParameter(valid_603519, JString, required = false,
                                 default = nil)
  if valid_603519 != nil:
    section.add "X-Amz-Content-Sha256", valid_603519
  var valid_603520 = header.getOrDefault("X-Amz-Algorithm")
  valid_603520 = validateParameter(valid_603520, JString, required = false,
                                 default = nil)
  if valid_603520 != nil:
    section.add "X-Amz-Algorithm", valid_603520
  var valid_603521 = header.getOrDefault("X-Amz-Signature")
  valid_603521 = validateParameter(valid_603521, JString, required = false,
                                 default = nil)
  if valid_603521 != nil:
    section.add "X-Amz-Signature", valid_603521
  var valid_603522 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603522 = validateParameter(valid_603522, JString, required = false,
                                 default = nil)
  if valid_603522 != nil:
    section.add "X-Amz-SignedHeaders", valid_603522
  var valid_603523 = header.getOrDefault("X-Amz-Credential")
  valid_603523 = validateParameter(valid_603523, JString, required = false,
                                 default = nil)
  if valid_603523 != nil:
    section.add "X-Amz-Credential", valid_603523
  result.add "header", section
  ## parameters in `formData` object:
  ##   DeleteSourceBundle: JBool
  ##                     : Set to <code>true</code> to delete the source bundle from your storage bucket. Otherwise, the application version is deleted only from Elastic Beanstalk and the source bundle remains in Amazon S3.
  ##   VersionLabel: JString (required)
  ##               : The label of the version to delete.
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to which the version belongs.
  section = newJObject()
  var valid_603524 = formData.getOrDefault("DeleteSourceBundle")
  valid_603524 = validateParameter(valid_603524, JBool, required = false, default = nil)
  if valid_603524 != nil:
    section.add "DeleteSourceBundle", valid_603524
  assert formData != nil,
        "formData argument is necessary due to required `VersionLabel` field"
  var valid_603525 = formData.getOrDefault("VersionLabel")
  valid_603525 = validateParameter(valid_603525, JString, required = true,
                                 default = nil)
  if valid_603525 != nil:
    section.add "VersionLabel", valid_603525
  var valid_603526 = formData.getOrDefault("ApplicationName")
  valid_603526 = validateParameter(valid_603526, JString, required = true,
                                 default = nil)
  if valid_603526 != nil:
    section.add "ApplicationName", valid_603526
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603527: Call_PostDeleteApplicationVersion_603512; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified version from the specified application.</p> <note> <p>You cannot delete an application version that is associated with a running environment.</p> </note>
  ## 
  let valid = call_603527.validator(path, query, header, formData, body)
  let scheme = call_603527.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603527.url(scheme.get, call_603527.host, call_603527.base,
                         call_603527.route, valid.getOrDefault("path"))
  result = hook(call_603527, url, valid)

proc call*(call_603528: Call_PostDeleteApplicationVersion_603512;
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
  var query_603529 = newJObject()
  var formData_603530 = newJObject()
  add(formData_603530, "DeleteSourceBundle", newJBool(DeleteSourceBundle))
  add(formData_603530, "VersionLabel", newJString(VersionLabel))
  add(query_603529, "Action", newJString(Action))
  add(formData_603530, "ApplicationName", newJString(ApplicationName))
  add(query_603529, "Version", newJString(Version))
  result = call_603528.call(nil, query_603529, nil, formData_603530, nil)

var postDeleteApplicationVersion* = Call_PostDeleteApplicationVersion_603512(
    name: "postDeleteApplicationVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteApplicationVersion",
    validator: validate_PostDeleteApplicationVersion_603513, base: "/",
    url: url_PostDeleteApplicationVersion_603514,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteApplicationVersion_603494 = ref object of OpenApiRestCall_602434
proc url_GetDeleteApplicationVersion_603496(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteApplicationVersion_603495(path: JsonNode; query: JsonNode;
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
  var valid_603497 = query.getOrDefault("VersionLabel")
  valid_603497 = validateParameter(valid_603497, JString, required = true,
                                 default = nil)
  if valid_603497 != nil:
    section.add "VersionLabel", valid_603497
  var valid_603498 = query.getOrDefault("ApplicationName")
  valid_603498 = validateParameter(valid_603498, JString, required = true,
                                 default = nil)
  if valid_603498 != nil:
    section.add "ApplicationName", valid_603498
  var valid_603499 = query.getOrDefault("Action")
  valid_603499 = validateParameter(valid_603499, JString, required = true, default = newJString(
      "DeleteApplicationVersion"))
  if valid_603499 != nil:
    section.add "Action", valid_603499
  var valid_603500 = query.getOrDefault("DeleteSourceBundle")
  valid_603500 = validateParameter(valid_603500, JBool, required = false, default = nil)
  if valid_603500 != nil:
    section.add "DeleteSourceBundle", valid_603500
  var valid_603501 = query.getOrDefault("Version")
  valid_603501 = validateParameter(valid_603501, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603501 != nil:
    section.add "Version", valid_603501
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
  var valid_603502 = header.getOrDefault("X-Amz-Date")
  valid_603502 = validateParameter(valid_603502, JString, required = false,
                                 default = nil)
  if valid_603502 != nil:
    section.add "X-Amz-Date", valid_603502
  var valid_603503 = header.getOrDefault("X-Amz-Security-Token")
  valid_603503 = validateParameter(valid_603503, JString, required = false,
                                 default = nil)
  if valid_603503 != nil:
    section.add "X-Amz-Security-Token", valid_603503
  var valid_603504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603504 = validateParameter(valid_603504, JString, required = false,
                                 default = nil)
  if valid_603504 != nil:
    section.add "X-Amz-Content-Sha256", valid_603504
  var valid_603505 = header.getOrDefault("X-Amz-Algorithm")
  valid_603505 = validateParameter(valid_603505, JString, required = false,
                                 default = nil)
  if valid_603505 != nil:
    section.add "X-Amz-Algorithm", valid_603505
  var valid_603506 = header.getOrDefault("X-Amz-Signature")
  valid_603506 = validateParameter(valid_603506, JString, required = false,
                                 default = nil)
  if valid_603506 != nil:
    section.add "X-Amz-Signature", valid_603506
  var valid_603507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603507 = validateParameter(valid_603507, JString, required = false,
                                 default = nil)
  if valid_603507 != nil:
    section.add "X-Amz-SignedHeaders", valid_603507
  var valid_603508 = header.getOrDefault("X-Amz-Credential")
  valid_603508 = validateParameter(valid_603508, JString, required = false,
                                 default = nil)
  if valid_603508 != nil:
    section.add "X-Amz-Credential", valid_603508
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603509: Call_GetDeleteApplicationVersion_603494; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified version from the specified application.</p> <note> <p>You cannot delete an application version that is associated with a running environment.</p> </note>
  ## 
  let valid = call_603509.validator(path, query, header, formData, body)
  let scheme = call_603509.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603509.url(scheme.get, call_603509.host, call_603509.base,
                         call_603509.route, valid.getOrDefault("path"))
  result = hook(call_603509, url, valid)

proc call*(call_603510: Call_GetDeleteApplicationVersion_603494;
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
  var query_603511 = newJObject()
  add(query_603511, "VersionLabel", newJString(VersionLabel))
  add(query_603511, "ApplicationName", newJString(ApplicationName))
  add(query_603511, "Action", newJString(Action))
  add(query_603511, "DeleteSourceBundle", newJBool(DeleteSourceBundle))
  add(query_603511, "Version", newJString(Version))
  result = call_603510.call(nil, query_603511, nil, nil, nil)

var getDeleteApplicationVersion* = Call_GetDeleteApplicationVersion_603494(
    name: "getDeleteApplicationVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteApplicationVersion",
    validator: validate_GetDeleteApplicationVersion_603495, base: "/",
    url: url_GetDeleteApplicationVersion_603496,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteConfigurationTemplate_603548 = ref object of OpenApiRestCall_602434
proc url_PostDeleteConfigurationTemplate_603550(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteConfigurationTemplate_603549(path: JsonNode;
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
  var valid_603551 = query.getOrDefault("Action")
  valid_603551 = validateParameter(valid_603551, JString, required = true, default = newJString(
      "DeleteConfigurationTemplate"))
  if valid_603551 != nil:
    section.add "Action", valid_603551
  var valid_603552 = query.getOrDefault("Version")
  valid_603552 = validateParameter(valid_603552, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603552 != nil:
    section.add "Version", valid_603552
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
  var valid_603553 = header.getOrDefault("X-Amz-Date")
  valid_603553 = validateParameter(valid_603553, JString, required = false,
                                 default = nil)
  if valid_603553 != nil:
    section.add "X-Amz-Date", valid_603553
  var valid_603554 = header.getOrDefault("X-Amz-Security-Token")
  valid_603554 = validateParameter(valid_603554, JString, required = false,
                                 default = nil)
  if valid_603554 != nil:
    section.add "X-Amz-Security-Token", valid_603554
  var valid_603555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603555 = validateParameter(valid_603555, JString, required = false,
                                 default = nil)
  if valid_603555 != nil:
    section.add "X-Amz-Content-Sha256", valid_603555
  var valid_603556 = header.getOrDefault("X-Amz-Algorithm")
  valid_603556 = validateParameter(valid_603556, JString, required = false,
                                 default = nil)
  if valid_603556 != nil:
    section.add "X-Amz-Algorithm", valid_603556
  var valid_603557 = header.getOrDefault("X-Amz-Signature")
  valid_603557 = validateParameter(valid_603557, JString, required = false,
                                 default = nil)
  if valid_603557 != nil:
    section.add "X-Amz-Signature", valid_603557
  var valid_603558 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603558 = validateParameter(valid_603558, JString, required = false,
                                 default = nil)
  if valid_603558 != nil:
    section.add "X-Amz-SignedHeaders", valid_603558
  var valid_603559 = header.getOrDefault("X-Amz-Credential")
  valid_603559 = validateParameter(valid_603559, JString, required = false,
                                 default = nil)
  if valid_603559 != nil:
    section.add "X-Amz-Credential", valid_603559
  result.add "header", section
  ## parameters in `formData` object:
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to delete the configuration template from.
  ##   TemplateName: JString (required)
  ##               : The name of the configuration template to delete.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_603560 = formData.getOrDefault("ApplicationName")
  valid_603560 = validateParameter(valid_603560, JString, required = true,
                                 default = nil)
  if valid_603560 != nil:
    section.add "ApplicationName", valid_603560
  var valid_603561 = formData.getOrDefault("TemplateName")
  valid_603561 = validateParameter(valid_603561, JString, required = true,
                                 default = nil)
  if valid_603561 != nil:
    section.add "TemplateName", valid_603561
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603562: Call_PostDeleteConfigurationTemplate_603548;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes the specified configuration template.</p> <note> <p>When you launch an environment using a configuration template, the environment gets a copy of the template. You can delete or modify the environment's copy of the template without affecting the running environment.</p> </note>
  ## 
  let valid = call_603562.validator(path, query, header, formData, body)
  let scheme = call_603562.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603562.url(scheme.get, call_603562.host, call_603562.base,
                         call_603562.route, valid.getOrDefault("path"))
  result = hook(call_603562, url, valid)

proc call*(call_603563: Call_PostDeleteConfigurationTemplate_603548;
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
  var query_603564 = newJObject()
  var formData_603565 = newJObject()
  add(query_603564, "Action", newJString(Action))
  add(formData_603565, "ApplicationName", newJString(ApplicationName))
  add(formData_603565, "TemplateName", newJString(TemplateName))
  add(query_603564, "Version", newJString(Version))
  result = call_603563.call(nil, query_603564, nil, formData_603565, nil)

var postDeleteConfigurationTemplate* = Call_PostDeleteConfigurationTemplate_603548(
    name: "postDeleteConfigurationTemplate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteConfigurationTemplate",
    validator: validate_PostDeleteConfigurationTemplate_603549, base: "/",
    url: url_PostDeleteConfigurationTemplate_603550,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteConfigurationTemplate_603531 = ref object of OpenApiRestCall_602434
proc url_GetDeleteConfigurationTemplate_603533(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteConfigurationTemplate_603532(path: JsonNode;
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
  var valid_603534 = query.getOrDefault("ApplicationName")
  valid_603534 = validateParameter(valid_603534, JString, required = true,
                                 default = nil)
  if valid_603534 != nil:
    section.add "ApplicationName", valid_603534
  var valid_603535 = query.getOrDefault("Action")
  valid_603535 = validateParameter(valid_603535, JString, required = true, default = newJString(
      "DeleteConfigurationTemplate"))
  if valid_603535 != nil:
    section.add "Action", valid_603535
  var valid_603536 = query.getOrDefault("TemplateName")
  valid_603536 = validateParameter(valid_603536, JString, required = true,
                                 default = nil)
  if valid_603536 != nil:
    section.add "TemplateName", valid_603536
  var valid_603537 = query.getOrDefault("Version")
  valid_603537 = validateParameter(valid_603537, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603537 != nil:
    section.add "Version", valid_603537
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
  var valid_603538 = header.getOrDefault("X-Amz-Date")
  valid_603538 = validateParameter(valid_603538, JString, required = false,
                                 default = nil)
  if valid_603538 != nil:
    section.add "X-Amz-Date", valid_603538
  var valid_603539 = header.getOrDefault("X-Amz-Security-Token")
  valid_603539 = validateParameter(valid_603539, JString, required = false,
                                 default = nil)
  if valid_603539 != nil:
    section.add "X-Amz-Security-Token", valid_603539
  var valid_603540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603540 = validateParameter(valid_603540, JString, required = false,
                                 default = nil)
  if valid_603540 != nil:
    section.add "X-Amz-Content-Sha256", valid_603540
  var valid_603541 = header.getOrDefault("X-Amz-Algorithm")
  valid_603541 = validateParameter(valid_603541, JString, required = false,
                                 default = nil)
  if valid_603541 != nil:
    section.add "X-Amz-Algorithm", valid_603541
  var valid_603542 = header.getOrDefault("X-Amz-Signature")
  valid_603542 = validateParameter(valid_603542, JString, required = false,
                                 default = nil)
  if valid_603542 != nil:
    section.add "X-Amz-Signature", valid_603542
  var valid_603543 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603543 = validateParameter(valid_603543, JString, required = false,
                                 default = nil)
  if valid_603543 != nil:
    section.add "X-Amz-SignedHeaders", valid_603543
  var valid_603544 = header.getOrDefault("X-Amz-Credential")
  valid_603544 = validateParameter(valid_603544, JString, required = false,
                                 default = nil)
  if valid_603544 != nil:
    section.add "X-Amz-Credential", valid_603544
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603545: Call_GetDeleteConfigurationTemplate_603531; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified configuration template.</p> <note> <p>When you launch an environment using a configuration template, the environment gets a copy of the template. You can delete or modify the environment's copy of the template without affecting the running environment.</p> </note>
  ## 
  let valid = call_603545.validator(path, query, header, formData, body)
  let scheme = call_603545.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603545.url(scheme.get, call_603545.host, call_603545.base,
                         call_603545.route, valid.getOrDefault("path"))
  result = hook(call_603545, url, valid)

proc call*(call_603546: Call_GetDeleteConfigurationTemplate_603531;
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
  var query_603547 = newJObject()
  add(query_603547, "ApplicationName", newJString(ApplicationName))
  add(query_603547, "Action", newJString(Action))
  add(query_603547, "TemplateName", newJString(TemplateName))
  add(query_603547, "Version", newJString(Version))
  result = call_603546.call(nil, query_603547, nil, nil, nil)

var getDeleteConfigurationTemplate* = Call_GetDeleteConfigurationTemplate_603531(
    name: "getDeleteConfigurationTemplate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteConfigurationTemplate",
    validator: validate_GetDeleteConfigurationTemplate_603532, base: "/",
    url: url_GetDeleteConfigurationTemplate_603533,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEnvironmentConfiguration_603583 = ref object of OpenApiRestCall_602434
proc url_PostDeleteEnvironmentConfiguration_603585(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteEnvironmentConfiguration_603584(path: JsonNode;
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
  var valid_603586 = query.getOrDefault("Action")
  valid_603586 = validateParameter(valid_603586, JString, required = true, default = newJString(
      "DeleteEnvironmentConfiguration"))
  if valid_603586 != nil:
    section.add "Action", valid_603586
  var valid_603587 = query.getOrDefault("Version")
  valid_603587 = validateParameter(valid_603587, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603587 != nil:
    section.add "Version", valid_603587
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
  var valid_603588 = header.getOrDefault("X-Amz-Date")
  valid_603588 = validateParameter(valid_603588, JString, required = false,
                                 default = nil)
  if valid_603588 != nil:
    section.add "X-Amz-Date", valid_603588
  var valid_603589 = header.getOrDefault("X-Amz-Security-Token")
  valid_603589 = validateParameter(valid_603589, JString, required = false,
                                 default = nil)
  if valid_603589 != nil:
    section.add "X-Amz-Security-Token", valid_603589
  var valid_603590 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603590 = validateParameter(valid_603590, JString, required = false,
                                 default = nil)
  if valid_603590 != nil:
    section.add "X-Amz-Content-Sha256", valid_603590
  var valid_603591 = header.getOrDefault("X-Amz-Algorithm")
  valid_603591 = validateParameter(valid_603591, JString, required = false,
                                 default = nil)
  if valid_603591 != nil:
    section.add "X-Amz-Algorithm", valid_603591
  var valid_603592 = header.getOrDefault("X-Amz-Signature")
  valid_603592 = validateParameter(valid_603592, JString, required = false,
                                 default = nil)
  if valid_603592 != nil:
    section.add "X-Amz-Signature", valid_603592
  var valid_603593 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603593 = validateParameter(valid_603593, JString, required = false,
                                 default = nil)
  if valid_603593 != nil:
    section.add "X-Amz-SignedHeaders", valid_603593
  var valid_603594 = header.getOrDefault("X-Amz-Credential")
  valid_603594 = validateParameter(valid_603594, JString, required = false,
                                 default = nil)
  if valid_603594 != nil:
    section.add "X-Amz-Credential", valid_603594
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString (required)
  ##                  : The name of the environment to delete the draft configuration from.
  ##   ApplicationName: JString (required)
  ##                  : The name of the application the environment is associated with.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `EnvironmentName` field"
  var valid_603595 = formData.getOrDefault("EnvironmentName")
  valid_603595 = validateParameter(valid_603595, JString, required = true,
                                 default = nil)
  if valid_603595 != nil:
    section.add "EnvironmentName", valid_603595
  var valid_603596 = formData.getOrDefault("ApplicationName")
  valid_603596 = validateParameter(valid_603596, JString, required = true,
                                 default = nil)
  if valid_603596 != nil:
    section.add "ApplicationName", valid_603596
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603597: Call_PostDeleteEnvironmentConfiguration_603583;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes the draft configuration associated with the running environment.</p> <p>Updating a running environment with any configuration changes creates a draft configuration set. You can get the draft configuration using <a>DescribeConfigurationSettings</a> while the update is in progress or if the update fails. The <code>DeploymentStatus</code> for the draft configuration indicates whether the deployment is in process or has failed. The draft configuration remains in existence until it is deleted with this action.</p>
  ## 
  let valid = call_603597.validator(path, query, header, formData, body)
  let scheme = call_603597.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603597.url(scheme.get, call_603597.host, call_603597.base,
                         call_603597.route, valid.getOrDefault("path"))
  result = hook(call_603597, url, valid)

proc call*(call_603598: Call_PostDeleteEnvironmentConfiguration_603583;
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
  var query_603599 = newJObject()
  var formData_603600 = newJObject()
  add(formData_603600, "EnvironmentName", newJString(EnvironmentName))
  add(query_603599, "Action", newJString(Action))
  add(formData_603600, "ApplicationName", newJString(ApplicationName))
  add(query_603599, "Version", newJString(Version))
  result = call_603598.call(nil, query_603599, nil, formData_603600, nil)

var postDeleteEnvironmentConfiguration* = Call_PostDeleteEnvironmentConfiguration_603583(
    name: "postDeleteEnvironmentConfiguration", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteEnvironmentConfiguration",
    validator: validate_PostDeleteEnvironmentConfiguration_603584, base: "/",
    url: url_PostDeleteEnvironmentConfiguration_603585,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEnvironmentConfiguration_603566 = ref object of OpenApiRestCall_602434
proc url_GetDeleteEnvironmentConfiguration_603568(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteEnvironmentConfiguration_603567(path: JsonNode;
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
  var valid_603569 = query.getOrDefault("ApplicationName")
  valid_603569 = validateParameter(valid_603569, JString, required = true,
                                 default = nil)
  if valid_603569 != nil:
    section.add "ApplicationName", valid_603569
  var valid_603570 = query.getOrDefault("EnvironmentName")
  valid_603570 = validateParameter(valid_603570, JString, required = true,
                                 default = nil)
  if valid_603570 != nil:
    section.add "EnvironmentName", valid_603570
  var valid_603571 = query.getOrDefault("Action")
  valid_603571 = validateParameter(valid_603571, JString, required = true, default = newJString(
      "DeleteEnvironmentConfiguration"))
  if valid_603571 != nil:
    section.add "Action", valid_603571
  var valid_603572 = query.getOrDefault("Version")
  valid_603572 = validateParameter(valid_603572, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603572 != nil:
    section.add "Version", valid_603572
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
  var valid_603573 = header.getOrDefault("X-Amz-Date")
  valid_603573 = validateParameter(valid_603573, JString, required = false,
                                 default = nil)
  if valid_603573 != nil:
    section.add "X-Amz-Date", valid_603573
  var valid_603574 = header.getOrDefault("X-Amz-Security-Token")
  valid_603574 = validateParameter(valid_603574, JString, required = false,
                                 default = nil)
  if valid_603574 != nil:
    section.add "X-Amz-Security-Token", valid_603574
  var valid_603575 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603575 = validateParameter(valid_603575, JString, required = false,
                                 default = nil)
  if valid_603575 != nil:
    section.add "X-Amz-Content-Sha256", valid_603575
  var valid_603576 = header.getOrDefault("X-Amz-Algorithm")
  valid_603576 = validateParameter(valid_603576, JString, required = false,
                                 default = nil)
  if valid_603576 != nil:
    section.add "X-Amz-Algorithm", valid_603576
  var valid_603577 = header.getOrDefault("X-Amz-Signature")
  valid_603577 = validateParameter(valid_603577, JString, required = false,
                                 default = nil)
  if valid_603577 != nil:
    section.add "X-Amz-Signature", valid_603577
  var valid_603578 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603578 = validateParameter(valid_603578, JString, required = false,
                                 default = nil)
  if valid_603578 != nil:
    section.add "X-Amz-SignedHeaders", valid_603578
  var valid_603579 = header.getOrDefault("X-Amz-Credential")
  valid_603579 = validateParameter(valid_603579, JString, required = false,
                                 default = nil)
  if valid_603579 != nil:
    section.add "X-Amz-Credential", valid_603579
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603580: Call_GetDeleteEnvironmentConfiguration_603566;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes the draft configuration associated with the running environment.</p> <p>Updating a running environment with any configuration changes creates a draft configuration set. You can get the draft configuration using <a>DescribeConfigurationSettings</a> while the update is in progress or if the update fails. The <code>DeploymentStatus</code> for the draft configuration indicates whether the deployment is in process or has failed. The draft configuration remains in existence until it is deleted with this action.</p>
  ## 
  let valid = call_603580.validator(path, query, header, formData, body)
  let scheme = call_603580.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603580.url(scheme.get, call_603580.host, call_603580.base,
                         call_603580.route, valid.getOrDefault("path"))
  result = hook(call_603580, url, valid)

proc call*(call_603581: Call_GetDeleteEnvironmentConfiguration_603566;
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
  var query_603582 = newJObject()
  add(query_603582, "ApplicationName", newJString(ApplicationName))
  add(query_603582, "EnvironmentName", newJString(EnvironmentName))
  add(query_603582, "Action", newJString(Action))
  add(query_603582, "Version", newJString(Version))
  result = call_603581.call(nil, query_603582, nil, nil, nil)

var getDeleteEnvironmentConfiguration* = Call_GetDeleteEnvironmentConfiguration_603566(
    name: "getDeleteEnvironmentConfiguration", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteEnvironmentConfiguration",
    validator: validate_GetDeleteEnvironmentConfiguration_603567, base: "/",
    url: url_GetDeleteEnvironmentConfiguration_603568,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeletePlatformVersion_603617 = ref object of OpenApiRestCall_602434
proc url_PostDeletePlatformVersion_603619(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeletePlatformVersion_603618(path: JsonNode; query: JsonNode;
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
  var valid_603620 = query.getOrDefault("Action")
  valid_603620 = validateParameter(valid_603620, JString, required = true,
                                 default = newJString("DeletePlatformVersion"))
  if valid_603620 != nil:
    section.add "Action", valid_603620
  var valid_603621 = query.getOrDefault("Version")
  valid_603621 = validateParameter(valid_603621, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603621 != nil:
    section.add "Version", valid_603621
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
  var valid_603622 = header.getOrDefault("X-Amz-Date")
  valid_603622 = validateParameter(valid_603622, JString, required = false,
                                 default = nil)
  if valid_603622 != nil:
    section.add "X-Amz-Date", valid_603622
  var valid_603623 = header.getOrDefault("X-Amz-Security-Token")
  valid_603623 = validateParameter(valid_603623, JString, required = false,
                                 default = nil)
  if valid_603623 != nil:
    section.add "X-Amz-Security-Token", valid_603623
  var valid_603624 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603624 = validateParameter(valid_603624, JString, required = false,
                                 default = nil)
  if valid_603624 != nil:
    section.add "X-Amz-Content-Sha256", valid_603624
  var valid_603625 = header.getOrDefault("X-Amz-Algorithm")
  valid_603625 = validateParameter(valid_603625, JString, required = false,
                                 default = nil)
  if valid_603625 != nil:
    section.add "X-Amz-Algorithm", valid_603625
  var valid_603626 = header.getOrDefault("X-Amz-Signature")
  valid_603626 = validateParameter(valid_603626, JString, required = false,
                                 default = nil)
  if valid_603626 != nil:
    section.add "X-Amz-Signature", valid_603626
  var valid_603627 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603627 = validateParameter(valid_603627, JString, required = false,
                                 default = nil)
  if valid_603627 != nil:
    section.add "X-Amz-SignedHeaders", valid_603627
  var valid_603628 = header.getOrDefault("X-Amz-Credential")
  valid_603628 = validateParameter(valid_603628, JString, required = false,
                                 default = nil)
  if valid_603628 != nil:
    section.add "X-Amz-Credential", valid_603628
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformArn: JString
  ##              : The ARN of the version of the custom platform.
  section = newJObject()
  var valid_603629 = formData.getOrDefault("PlatformArn")
  valid_603629 = validateParameter(valid_603629, JString, required = false,
                                 default = nil)
  if valid_603629 != nil:
    section.add "PlatformArn", valid_603629
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603630: Call_PostDeletePlatformVersion_603617; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified version of a custom platform.
  ## 
  let valid = call_603630.validator(path, query, header, formData, body)
  let scheme = call_603630.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603630.url(scheme.get, call_603630.host, call_603630.base,
                         call_603630.route, valid.getOrDefault("path"))
  result = hook(call_603630, url, valid)

proc call*(call_603631: Call_PostDeletePlatformVersion_603617;
          Action: string = "DeletePlatformVersion"; PlatformArn: string = "";
          Version: string = "2010-12-01"): Recallable =
  ## postDeletePlatformVersion
  ## Deletes the specified version of a custom platform.
  ##   Action: string (required)
  ##   PlatformArn: string
  ##              : The ARN of the version of the custom platform.
  ##   Version: string (required)
  var query_603632 = newJObject()
  var formData_603633 = newJObject()
  add(query_603632, "Action", newJString(Action))
  add(formData_603633, "PlatformArn", newJString(PlatformArn))
  add(query_603632, "Version", newJString(Version))
  result = call_603631.call(nil, query_603632, nil, formData_603633, nil)

var postDeletePlatformVersion* = Call_PostDeletePlatformVersion_603617(
    name: "postDeletePlatformVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeletePlatformVersion",
    validator: validate_PostDeletePlatformVersion_603618, base: "/",
    url: url_PostDeletePlatformVersion_603619,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeletePlatformVersion_603601 = ref object of OpenApiRestCall_602434
proc url_GetDeletePlatformVersion_603603(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeletePlatformVersion_603602(path: JsonNode; query: JsonNode;
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
  var valid_603604 = query.getOrDefault("PlatformArn")
  valid_603604 = validateParameter(valid_603604, JString, required = false,
                                 default = nil)
  if valid_603604 != nil:
    section.add "PlatformArn", valid_603604
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603605 = query.getOrDefault("Action")
  valid_603605 = validateParameter(valid_603605, JString, required = true,
                                 default = newJString("DeletePlatformVersion"))
  if valid_603605 != nil:
    section.add "Action", valid_603605
  var valid_603606 = query.getOrDefault("Version")
  valid_603606 = validateParameter(valid_603606, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603606 != nil:
    section.add "Version", valid_603606
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
  var valid_603607 = header.getOrDefault("X-Amz-Date")
  valid_603607 = validateParameter(valid_603607, JString, required = false,
                                 default = nil)
  if valid_603607 != nil:
    section.add "X-Amz-Date", valid_603607
  var valid_603608 = header.getOrDefault("X-Amz-Security-Token")
  valid_603608 = validateParameter(valid_603608, JString, required = false,
                                 default = nil)
  if valid_603608 != nil:
    section.add "X-Amz-Security-Token", valid_603608
  var valid_603609 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603609 = validateParameter(valid_603609, JString, required = false,
                                 default = nil)
  if valid_603609 != nil:
    section.add "X-Amz-Content-Sha256", valid_603609
  var valid_603610 = header.getOrDefault("X-Amz-Algorithm")
  valid_603610 = validateParameter(valid_603610, JString, required = false,
                                 default = nil)
  if valid_603610 != nil:
    section.add "X-Amz-Algorithm", valid_603610
  var valid_603611 = header.getOrDefault("X-Amz-Signature")
  valid_603611 = validateParameter(valid_603611, JString, required = false,
                                 default = nil)
  if valid_603611 != nil:
    section.add "X-Amz-Signature", valid_603611
  var valid_603612 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603612 = validateParameter(valid_603612, JString, required = false,
                                 default = nil)
  if valid_603612 != nil:
    section.add "X-Amz-SignedHeaders", valid_603612
  var valid_603613 = header.getOrDefault("X-Amz-Credential")
  valid_603613 = validateParameter(valid_603613, JString, required = false,
                                 default = nil)
  if valid_603613 != nil:
    section.add "X-Amz-Credential", valid_603613
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603614: Call_GetDeletePlatformVersion_603601; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified version of a custom platform.
  ## 
  let valid = call_603614.validator(path, query, header, formData, body)
  let scheme = call_603614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603614.url(scheme.get, call_603614.host, call_603614.base,
                         call_603614.route, valid.getOrDefault("path"))
  result = hook(call_603614, url, valid)

proc call*(call_603615: Call_GetDeletePlatformVersion_603601;
          PlatformArn: string = ""; Action: string = "DeletePlatformVersion";
          Version: string = "2010-12-01"): Recallable =
  ## getDeletePlatformVersion
  ## Deletes the specified version of a custom platform.
  ##   PlatformArn: string
  ##              : The ARN of the version of the custom platform.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603616 = newJObject()
  add(query_603616, "PlatformArn", newJString(PlatformArn))
  add(query_603616, "Action", newJString(Action))
  add(query_603616, "Version", newJString(Version))
  result = call_603615.call(nil, query_603616, nil, nil, nil)

var getDeletePlatformVersion* = Call_GetDeletePlatformVersion_603601(
    name: "getDeletePlatformVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeletePlatformVersion",
    validator: validate_GetDeletePlatformVersion_603602, base: "/",
    url: url_GetDeletePlatformVersion_603603, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAccountAttributes_603649 = ref object of OpenApiRestCall_602434
proc url_PostDescribeAccountAttributes_603651(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeAccountAttributes_603650(path: JsonNode; query: JsonNode;
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
  var valid_603652 = query.getOrDefault("Action")
  valid_603652 = validateParameter(valid_603652, JString, required = true, default = newJString(
      "DescribeAccountAttributes"))
  if valid_603652 != nil:
    section.add "Action", valid_603652
  var valid_603653 = query.getOrDefault("Version")
  valid_603653 = validateParameter(valid_603653, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603653 != nil:
    section.add "Version", valid_603653
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
  var valid_603654 = header.getOrDefault("X-Amz-Date")
  valid_603654 = validateParameter(valid_603654, JString, required = false,
                                 default = nil)
  if valid_603654 != nil:
    section.add "X-Amz-Date", valid_603654
  var valid_603655 = header.getOrDefault("X-Amz-Security-Token")
  valid_603655 = validateParameter(valid_603655, JString, required = false,
                                 default = nil)
  if valid_603655 != nil:
    section.add "X-Amz-Security-Token", valid_603655
  var valid_603656 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603656 = validateParameter(valid_603656, JString, required = false,
                                 default = nil)
  if valid_603656 != nil:
    section.add "X-Amz-Content-Sha256", valid_603656
  var valid_603657 = header.getOrDefault("X-Amz-Algorithm")
  valid_603657 = validateParameter(valid_603657, JString, required = false,
                                 default = nil)
  if valid_603657 != nil:
    section.add "X-Amz-Algorithm", valid_603657
  var valid_603658 = header.getOrDefault("X-Amz-Signature")
  valid_603658 = validateParameter(valid_603658, JString, required = false,
                                 default = nil)
  if valid_603658 != nil:
    section.add "X-Amz-Signature", valid_603658
  var valid_603659 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603659 = validateParameter(valid_603659, JString, required = false,
                                 default = nil)
  if valid_603659 != nil:
    section.add "X-Amz-SignedHeaders", valid_603659
  var valid_603660 = header.getOrDefault("X-Amz-Credential")
  valid_603660 = validateParameter(valid_603660, JString, required = false,
                                 default = nil)
  if valid_603660 != nil:
    section.add "X-Amz-Credential", valid_603660
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603661: Call_PostDescribeAccountAttributes_603649; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ## 
  let valid = call_603661.validator(path, query, header, formData, body)
  let scheme = call_603661.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603661.url(scheme.get, call_603661.host, call_603661.base,
                         call_603661.route, valid.getOrDefault("path"))
  result = hook(call_603661, url, valid)

proc call*(call_603662: Call_PostDescribeAccountAttributes_603649;
          Action: string = "DescribeAccountAttributes";
          Version: string = "2010-12-01"): Recallable =
  ## postDescribeAccountAttributes
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603663 = newJObject()
  add(query_603663, "Action", newJString(Action))
  add(query_603663, "Version", newJString(Version))
  result = call_603662.call(nil, query_603663, nil, nil, nil)

var postDescribeAccountAttributes* = Call_PostDescribeAccountAttributes_603649(
    name: "postDescribeAccountAttributes", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeAccountAttributes",
    validator: validate_PostDescribeAccountAttributes_603650, base: "/",
    url: url_PostDescribeAccountAttributes_603651,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAccountAttributes_603634 = ref object of OpenApiRestCall_602434
proc url_GetDescribeAccountAttributes_603636(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeAccountAttributes_603635(path: JsonNode; query: JsonNode;
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
  var valid_603637 = query.getOrDefault("Action")
  valid_603637 = validateParameter(valid_603637, JString, required = true, default = newJString(
      "DescribeAccountAttributes"))
  if valid_603637 != nil:
    section.add "Action", valid_603637
  var valid_603638 = query.getOrDefault("Version")
  valid_603638 = validateParameter(valid_603638, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603638 != nil:
    section.add "Version", valid_603638
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
  var valid_603639 = header.getOrDefault("X-Amz-Date")
  valid_603639 = validateParameter(valid_603639, JString, required = false,
                                 default = nil)
  if valid_603639 != nil:
    section.add "X-Amz-Date", valid_603639
  var valid_603640 = header.getOrDefault("X-Amz-Security-Token")
  valid_603640 = validateParameter(valid_603640, JString, required = false,
                                 default = nil)
  if valid_603640 != nil:
    section.add "X-Amz-Security-Token", valid_603640
  var valid_603641 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603641 = validateParameter(valid_603641, JString, required = false,
                                 default = nil)
  if valid_603641 != nil:
    section.add "X-Amz-Content-Sha256", valid_603641
  var valid_603642 = header.getOrDefault("X-Amz-Algorithm")
  valid_603642 = validateParameter(valid_603642, JString, required = false,
                                 default = nil)
  if valid_603642 != nil:
    section.add "X-Amz-Algorithm", valid_603642
  var valid_603643 = header.getOrDefault("X-Amz-Signature")
  valid_603643 = validateParameter(valid_603643, JString, required = false,
                                 default = nil)
  if valid_603643 != nil:
    section.add "X-Amz-Signature", valid_603643
  var valid_603644 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603644 = validateParameter(valid_603644, JString, required = false,
                                 default = nil)
  if valid_603644 != nil:
    section.add "X-Amz-SignedHeaders", valid_603644
  var valid_603645 = header.getOrDefault("X-Amz-Credential")
  valid_603645 = validateParameter(valid_603645, JString, required = false,
                                 default = nil)
  if valid_603645 != nil:
    section.add "X-Amz-Credential", valid_603645
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603646: Call_GetDescribeAccountAttributes_603634; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ## 
  let valid = call_603646.validator(path, query, header, formData, body)
  let scheme = call_603646.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603646.url(scheme.get, call_603646.host, call_603646.base,
                         call_603646.route, valid.getOrDefault("path"))
  result = hook(call_603646, url, valid)

proc call*(call_603647: Call_GetDescribeAccountAttributes_603634;
          Action: string = "DescribeAccountAttributes";
          Version: string = "2010-12-01"): Recallable =
  ## getDescribeAccountAttributes
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603648 = newJObject()
  add(query_603648, "Action", newJString(Action))
  add(query_603648, "Version", newJString(Version))
  result = call_603647.call(nil, query_603648, nil, nil, nil)

var getDescribeAccountAttributes* = Call_GetDescribeAccountAttributes_603634(
    name: "getDescribeAccountAttributes", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeAccountAttributes",
    validator: validate_GetDescribeAccountAttributes_603635, base: "/",
    url: url_GetDescribeAccountAttributes_603636,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeApplicationVersions_603683 = ref object of OpenApiRestCall_602434
proc url_PostDescribeApplicationVersions_603685(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeApplicationVersions_603684(path: JsonNode;
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
  var valid_603686 = query.getOrDefault("Action")
  valid_603686 = validateParameter(valid_603686, JString, required = true, default = newJString(
      "DescribeApplicationVersions"))
  if valid_603686 != nil:
    section.add "Action", valid_603686
  var valid_603687 = query.getOrDefault("Version")
  valid_603687 = validateParameter(valid_603687, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603687 != nil:
    section.add "Version", valid_603687
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
  var valid_603688 = header.getOrDefault("X-Amz-Date")
  valid_603688 = validateParameter(valid_603688, JString, required = false,
                                 default = nil)
  if valid_603688 != nil:
    section.add "X-Amz-Date", valid_603688
  var valid_603689 = header.getOrDefault("X-Amz-Security-Token")
  valid_603689 = validateParameter(valid_603689, JString, required = false,
                                 default = nil)
  if valid_603689 != nil:
    section.add "X-Amz-Security-Token", valid_603689
  var valid_603690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603690 = validateParameter(valid_603690, JString, required = false,
                                 default = nil)
  if valid_603690 != nil:
    section.add "X-Amz-Content-Sha256", valid_603690
  var valid_603691 = header.getOrDefault("X-Amz-Algorithm")
  valid_603691 = validateParameter(valid_603691, JString, required = false,
                                 default = nil)
  if valid_603691 != nil:
    section.add "X-Amz-Algorithm", valid_603691
  var valid_603692 = header.getOrDefault("X-Amz-Signature")
  valid_603692 = validateParameter(valid_603692, JString, required = false,
                                 default = nil)
  if valid_603692 != nil:
    section.add "X-Amz-Signature", valid_603692
  var valid_603693 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603693 = validateParameter(valid_603693, JString, required = false,
                                 default = nil)
  if valid_603693 != nil:
    section.add "X-Amz-SignedHeaders", valid_603693
  var valid_603694 = header.getOrDefault("X-Amz-Credential")
  valid_603694 = validateParameter(valid_603694, JString, required = false,
                                 default = nil)
  if valid_603694 != nil:
    section.add "X-Amz-Credential", valid_603694
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
  var valid_603695 = formData.getOrDefault("NextToken")
  valid_603695 = validateParameter(valid_603695, JString, required = false,
                                 default = nil)
  if valid_603695 != nil:
    section.add "NextToken", valid_603695
  var valid_603696 = formData.getOrDefault("ApplicationName")
  valid_603696 = validateParameter(valid_603696, JString, required = false,
                                 default = nil)
  if valid_603696 != nil:
    section.add "ApplicationName", valid_603696
  var valid_603697 = formData.getOrDefault("MaxRecords")
  valid_603697 = validateParameter(valid_603697, JInt, required = false, default = nil)
  if valid_603697 != nil:
    section.add "MaxRecords", valid_603697
  var valid_603698 = formData.getOrDefault("VersionLabels")
  valid_603698 = validateParameter(valid_603698, JArray, required = false,
                                 default = nil)
  if valid_603698 != nil:
    section.add "VersionLabels", valid_603698
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603699: Call_PostDescribeApplicationVersions_603683;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieve a list of application versions.
  ## 
  let valid = call_603699.validator(path, query, header, formData, body)
  let scheme = call_603699.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603699.url(scheme.get, call_603699.host, call_603699.base,
                         call_603699.route, valid.getOrDefault("path"))
  result = hook(call_603699, url, valid)

proc call*(call_603700: Call_PostDescribeApplicationVersions_603683;
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
  var query_603701 = newJObject()
  var formData_603702 = newJObject()
  add(formData_603702, "NextToken", newJString(NextToken))
  add(query_603701, "Action", newJString(Action))
  add(formData_603702, "ApplicationName", newJString(ApplicationName))
  add(formData_603702, "MaxRecords", newJInt(MaxRecords))
  add(query_603701, "Version", newJString(Version))
  if VersionLabels != nil:
    formData_603702.add "VersionLabels", VersionLabels
  result = call_603700.call(nil, query_603701, nil, formData_603702, nil)

var postDescribeApplicationVersions* = Call_PostDescribeApplicationVersions_603683(
    name: "postDescribeApplicationVersions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplicationVersions",
    validator: validate_PostDescribeApplicationVersions_603684, base: "/",
    url: url_PostDescribeApplicationVersions_603685,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeApplicationVersions_603664 = ref object of OpenApiRestCall_602434
proc url_GetDescribeApplicationVersions_603666(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeApplicationVersions_603665(path: JsonNode;
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
  var valid_603667 = query.getOrDefault("MaxRecords")
  valid_603667 = validateParameter(valid_603667, JInt, required = false, default = nil)
  if valid_603667 != nil:
    section.add "MaxRecords", valid_603667
  var valid_603668 = query.getOrDefault("ApplicationName")
  valid_603668 = validateParameter(valid_603668, JString, required = false,
                                 default = nil)
  if valid_603668 != nil:
    section.add "ApplicationName", valid_603668
  var valid_603669 = query.getOrDefault("NextToken")
  valid_603669 = validateParameter(valid_603669, JString, required = false,
                                 default = nil)
  if valid_603669 != nil:
    section.add "NextToken", valid_603669
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603670 = query.getOrDefault("Action")
  valid_603670 = validateParameter(valid_603670, JString, required = true, default = newJString(
      "DescribeApplicationVersions"))
  if valid_603670 != nil:
    section.add "Action", valid_603670
  var valid_603671 = query.getOrDefault("VersionLabels")
  valid_603671 = validateParameter(valid_603671, JArray, required = false,
                                 default = nil)
  if valid_603671 != nil:
    section.add "VersionLabels", valid_603671
  var valid_603672 = query.getOrDefault("Version")
  valid_603672 = validateParameter(valid_603672, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603672 != nil:
    section.add "Version", valid_603672
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
  var valid_603673 = header.getOrDefault("X-Amz-Date")
  valid_603673 = validateParameter(valid_603673, JString, required = false,
                                 default = nil)
  if valid_603673 != nil:
    section.add "X-Amz-Date", valid_603673
  var valid_603674 = header.getOrDefault("X-Amz-Security-Token")
  valid_603674 = validateParameter(valid_603674, JString, required = false,
                                 default = nil)
  if valid_603674 != nil:
    section.add "X-Amz-Security-Token", valid_603674
  var valid_603675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603675 = validateParameter(valid_603675, JString, required = false,
                                 default = nil)
  if valid_603675 != nil:
    section.add "X-Amz-Content-Sha256", valid_603675
  var valid_603676 = header.getOrDefault("X-Amz-Algorithm")
  valid_603676 = validateParameter(valid_603676, JString, required = false,
                                 default = nil)
  if valid_603676 != nil:
    section.add "X-Amz-Algorithm", valid_603676
  var valid_603677 = header.getOrDefault("X-Amz-Signature")
  valid_603677 = validateParameter(valid_603677, JString, required = false,
                                 default = nil)
  if valid_603677 != nil:
    section.add "X-Amz-Signature", valid_603677
  var valid_603678 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603678 = validateParameter(valid_603678, JString, required = false,
                                 default = nil)
  if valid_603678 != nil:
    section.add "X-Amz-SignedHeaders", valid_603678
  var valid_603679 = header.getOrDefault("X-Amz-Credential")
  valid_603679 = validateParameter(valid_603679, JString, required = false,
                                 default = nil)
  if valid_603679 != nil:
    section.add "X-Amz-Credential", valid_603679
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603680: Call_GetDescribeApplicationVersions_603664; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a list of application versions.
  ## 
  let valid = call_603680.validator(path, query, header, formData, body)
  let scheme = call_603680.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603680.url(scheme.get, call_603680.host, call_603680.base,
                         call_603680.route, valid.getOrDefault("path"))
  result = hook(call_603680, url, valid)

proc call*(call_603681: Call_GetDescribeApplicationVersions_603664;
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
  var query_603682 = newJObject()
  add(query_603682, "MaxRecords", newJInt(MaxRecords))
  add(query_603682, "ApplicationName", newJString(ApplicationName))
  add(query_603682, "NextToken", newJString(NextToken))
  add(query_603682, "Action", newJString(Action))
  if VersionLabels != nil:
    query_603682.add "VersionLabels", VersionLabels
  add(query_603682, "Version", newJString(Version))
  result = call_603681.call(nil, query_603682, nil, nil, nil)

var getDescribeApplicationVersions* = Call_GetDescribeApplicationVersions_603664(
    name: "getDescribeApplicationVersions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplicationVersions",
    validator: validate_GetDescribeApplicationVersions_603665, base: "/",
    url: url_GetDescribeApplicationVersions_603666,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeApplications_603719 = ref object of OpenApiRestCall_602434
proc url_PostDescribeApplications_603721(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeApplications_603720(path: JsonNode; query: JsonNode;
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
  var valid_603722 = query.getOrDefault("Action")
  valid_603722 = validateParameter(valid_603722, JString, required = true,
                                 default = newJString("DescribeApplications"))
  if valid_603722 != nil:
    section.add "Action", valid_603722
  var valid_603723 = query.getOrDefault("Version")
  valid_603723 = validateParameter(valid_603723, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603723 != nil:
    section.add "Version", valid_603723
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
  var valid_603724 = header.getOrDefault("X-Amz-Date")
  valid_603724 = validateParameter(valid_603724, JString, required = false,
                                 default = nil)
  if valid_603724 != nil:
    section.add "X-Amz-Date", valid_603724
  var valid_603725 = header.getOrDefault("X-Amz-Security-Token")
  valid_603725 = validateParameter(valid_603725, JString, required = false,
                                 default = nil)
  if valid_603725 != nil:
    section.add "X-Amz-Security-Token", valid_603725
  var valid_603726 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603726 = validateParameter(valid_603726, JString, required = false,
                                 default = nil)
  if valid_603726 != nil:
    section.add "X-Amz-Content-Sha256", valid_603726
  var valid_603727 = header.getOrDefault("X-Amz-Algorithm")
  valid_603727 = validateParameter(valid_603727, JString, required = false,
                                 default = nil)
  if valid_603727 != nil:
    section.add "X-Amz-Algorithm", valid_603727
  var valid_603728 = header.getOrDefault("X-Amz-Signature")
  valid_603728 = validateParameter(valid_603728, JString, required = false,
                                 default = nil)
  if valid_603728 != nil:
    section.add "X-Amz-Signature", valid_603728
  var valid_603729 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603729 = validateParameter(valid_603729, JString, required = false,
                                 default = nil)
  if valid_603729 != nil:
    section.add "X-Amz-SignedHeaders", valid_603729
  var valid_603730 = header.getOrDefault("X-Amz-Credential")
  valid_603730 = validateParameter(valid_603730, JString, required = false,
                                 default = nil)
  if valid_603730 != nil:
    section.add "X-Amz-Credential", valid_603730
  result.add "header", section
  ## parameters in `formData` object:
  ##   ApplicationNames: JArray
  ##                   : If specified, AWS Elastic Beanstalk restricts the returned descriptions to only include those with the specified names.
  section = newJObject()
  var valid_603731 = formData.getOrDefault("ApplicationNames")
  valid_603731 = validateParameter(valid_603731, JArray, required = false,
                                 default = nil)
  if valid_603731 != nil:
    section.add "ApplicationNames", valid_603731
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603732: Call_PostDescribeApplications_603719; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the descriptions of existing applications.
  ## 
  let valid = call_603732.validator(path, query, header, formData, body)
  let scheme = call_603732.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603732.url(scheme.get, call_603732.host, call_603732.base,
                         call_603732.route, valid.getOrDefault("path"))
  result = hook(call_603732, url, valid)

proc call*(call_603733: Call_PostDescribeApplications_603719;
          ApplicationNames: JsonNode = nil; Action: string = "DescribeApplications";
          Version: string = "2010-12-01"): Recallable =
  ## postDescribeApplications
  ## Returns the descriptions of existing applications.
  ##   ApplicationNames: JArray
  ##                   : If specified, AWS Elastic Beanstalk restricts the returned descriptions to only include those with the specified names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603734 = newJObject()
  var formData_603735 = newJObject()
  if ApplicationNames != nil:
    formData_603735.add "ApplicationNames", ApplicationNames
  add(query_603734, "Action", newJString(Action))
  add(query_603734, "Version", newJString(Version))
  result = call_603733.call(nil, query_603734, nil, formData_603735, nil)

var postDescribeApplications* = Call_PostDescribeApplications_603719(
    name: "postDescribeApplications", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplications",
    validator: validate_PostDescribeApplications_603720, base: "/",
    url: url_PostDescribeApplications_603721, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeApplications_603703 = ref object of OpenApiRestCall_602434
proc url_GetDescribeApplications_603705(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeApplications_603704(path: JsonNode; query: JsonNode;
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
  var valid_603706 = query.getOrDefault("ApplicationNames")
  valid_603706 = validateParameter(valid_603706, JArray, required = false,
                                 default = nil)
  if valid_603706 != nil:
    section.add "ApplicationNames", valid_603706
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603707 = query.getOrDefault("Action")
  valid_603707 = validateParameter(valid_603707, JString, required = true,
                                 default = newJString("DescribeApplications"))
  if valid_603707 != nil:
    section.add "Action", valid_603707
  var valid_603708 = query.getOrDefault("Version")
  valid_603708 = validateParameter(valid_603708, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603708 != nil:
    section.add "Version", valid_603708
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
  var valid_603709 = header.getOrDefault("X-Amz-Date")
  valid_603709 = validateParameter(valid_603709, JString, required = false,
                                 default = nil)
  if valid_603709 != nil:
    section.add "X-Amz-Date", valid_603709
  var valid_603710 = header.getOrDefault("X-Amz-Security-Token")
  valid_603710 = validateParameter(valid_603710, JString, required = false,
                                 default = nil)
  if valid_603710 != nil:
    section.add "X-Amz-Security-Token", valid_603710
  var valid_603711 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603711 = validateParameter(valid_603711, JString, required = false,
                                 default = nil)
  if valid_603711 != nil:
    section.add "X-Amz-Content-Sha256", valid_603711
  var valid_603712 = header.getOrDefault("X-Amz-Algorithm")
  valid_603712 = validateParameter(valid_603712, JString, required = false,
                                 default = nil)
  if valid_603712 != nil:
    section.add "X-Amz-Algorithm", valid_603712
  var valid_603713 = header.getOrDefault("X-Amz-Signature")
  valid_603713 = validateParameter(valid_603713, JString, required = false,
                                 default = nil)
  if valid_603713 != nil:
    section.add "X-Amz-Signature", valid_603713
  var valid_603714 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603714 = validateParameter(valid_603714, JString, required = false,
                                 default = nil)
  if valid_603714 != nil:
    section.add "X-Amz-SignedHeaders", valid_603714
  var valid_603715 = header.getOrDefault("X-Amz-Credential")
  valid_603715 = validateParameter(valid_603715, JString, required = false,
                                 default = nil)
  if valid_603715 != nil:
    section.add "X-Amz-Credential", valid_603715
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603716: Call_GetDescribeApplications_603703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the descriptions of existing applications.
  ## 
  let valid = call_603716.validator(path, query, header, formData, body)
  let scheme = call_603716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603716.url(scheme.get, call_603716.host, call_603716.base,
                         call_603716.route, valid.getOrDefault("path"))
  result = hook(call_603716, url, valid)

proc call*(call_603717: Call_GetDescribeApplications_603703;
          ApplicationNames: JsonNode = nil; Action: string = "DescribeApplications";
          Version: string = "2010-12-01"): Recallable =
  ## getDescribeApplications
  ## Returns the descriptions of existing applications.
  ##   ApplicationNames: JArray
  ##                   : If specified, AWS Elastic Beanstalk restricts the returned descriptions to only include those with the specified names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603718 = newJObject()
  if ApplicationNames != nil:
    query_603718.add "ApplicationNames", ApplicationNames
  add(query_603718, "Action", newJString(Action))
  add(query_603718, "Version", newJString(Version))
  result = call_603717.call(nil, query_603718, nil, nil, nil)

var getDescribeApplications* = Call_GetDescribeApplications_603703(
    name: "getDescribeApplications", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplications",
    validator: validate_GetDescribeApplications_603704, base: "/",
    url: url_GetDescribeApplications_603705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeConfigurationOptions_603757 = ref object of OpenApiRestCall_602434
proc url_PostDescribeConfigurationOptions_603759(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeConfigurationOptions_603758(path: JsonNode;
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
  var valid_603760 = query.getOrDefault("Action")
  valid_603760 = validateParameter(valid_603760, JString, required = true, default = newJString(
      "DescribeConfigurationOptions"))
  if valid_603760 != nil:
    section.add "Action", valid_603760
  var valid_603761 = query.getOrDefault("Version")
  valid_603761 = validateParameter(valid_603761, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603761 != nil:
    section.add "Version", valid_603761
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
  var valid_603762 = header.getOrDefault("X-Amz-Date")
  valid_603762 = validateParameter(valid_603762, JString, required = false,
                                 default = nil)
  if valid_603762 != nil:
    section.add "X-Amz-Date", valid_603762
  var valid_603763 = header.getOrDefault("X-Amz-Security-Token")
  valid_603763 = validateParameter(valid_603763, JString, required = false,
                                 default = nil)
  if valid_603763 != nil:
    section.add "X-Amz-Security-Token", valid_603763
  var valid_603764 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603764 = validateParameter(valid_603764, JString, required = false,
                                 default = nil)
  if valid_603764 != nil:
    section.add "X-Amz-Content-Sha256", valid_603764
  var valid_603765 = header.getOrDefault("X-Amz-Algorithm")
  valid_603765 = validateParameter(valid_603765, JString, required = false,
                                 default = nil)
  if valid_603765 != nil:
    section.add "X-Amz-Algorithm", valid_603765
  var valid_603766 = header.getOrDefault("X-Amz-Signature")
  valid_603766 = validateParameter(valid_603766, JString, required = false,
                                 default = nil)
  if valid_603766 != nil:
    section.add "X-Amz-Signature", valid_603766
  var valid_603767 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603767 = validateParameter(valid_603767, JString, required = false,
                                 default = nil)
  if valid_603767 != nil:
    section.add "X-Amz-SignedHeaders", valid_603767
  var valid_603768 = header.getOrDefault("X-Amz-Credential")
  valid_603768 = validateParameter(valid_603768, JString, required = false,
                                 default = nil)
  if valid_603768 != nil:
    section.add "X-Amz-Credential", valid_603768
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
  var valid_603769 = formData.getOrDefault("Options")
  valid_603769 = validateParameter(valid_603769, JArray, required = false,
                                 default = nil)
  if valid_603769 != nil:
    section.add "Options", valid_603769
  var valid_603770 = formData.getOrDefault("SolutionStackName")
  valid_603770 = validateParameter(valid_603770, JString, required = false,
                                 default = nil)
  if valid_603770 != nil:
    section.add "SolutionStackName", valid_603770
  var valid_603771 = formData.getOrDefault("EnvironmentName")
  valid_603771 = validateParameter(valid_603771, JString, required = false,
                                 default = nil)
  if valid_603771 != nil:
    section.add "EnvironmentName", valid_603771
  var valid_603772 = formData.getOrDefault("ApplicationName")
  valid_603772 = validateParameter(valid_603772, JString, required = false,
                                 default = nil)
  if valid_603772 != nil:
    section.add "ApplicationName", valid_603772
  var valid_603773 = formData.getOrDefault("PlatformArn")
  valid_603773 = validateParameter(valid_603773, JString, required = false,
                                 default = nil)
  if valid_603773 != nil:
    section.add "PlatformArn", valid_603773
  var valid_603774 = formData.getOrDefault("TemplateName")
  valid_603774 = validateParameter(valid_603774, JString, required = false,
                                 default = nil)
  if valid_603774 != nil:
    section.add "TemplateName", valid_603774
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603775: Call_PostDescribeConfigurationOptions_603757;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the configuration options that are used in a particular configuration template or environment, or that a specified solution stack defines. The description includes the values the options, their default values, and an indication of the required action on a running environment if an option value is changed.
  ## 
  let valid = call_603775.validator(path, query, header, formData, body)
  let scheme = call_603775.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603775.url(scheme.get, call_603775.host, call_603775.base,
                         call_603775.route, valid.getOrDefault("path"))
  result = hook(call_603775, url, valid)

proc call*(call_603776: Call_PostDescribeConfigurationOptions_603757;
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
  var query_603777 = newJObject()
  var formData_603778 = newJObject()
  if Options != nil:
    formData_603778.add "Options", Options
  add(formData_603778, "SolutionStackName", newJString(SolutionStackName))
  add(formData_603778, "EnvironmentName", newJString(EnvironmentName))
  add(query_603777, "Action", newJString(Action))
  add(formData_603778, "ApplicationName", newJString(ApplicationName))
  add(formData_603778, "PlatformArn", newJString(PlatformArn))
  add(formData_603778, "TemplateName", newJString(TemplateName))
  add(query_603777, "Version", newJString(Version))
  result = call_603776.call(nil, query_603777, nil, formData_603778, nil)

var postDescribeConfigurationOptions* = Call_PostDescribeConfigurationOptions_603757(
    name: "postDescribeConfigurationOptions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationOptions",
    validator: validate_PostDescribeConfigurationOptions_603758, base: "/",
    url: url_PostDescribeConfigurationOptions_603759,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeConfigurationOptions_603736 = ref object of OpenApiRestCall_602434
proc url_GetDescribeConfigurationOptions_603738(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeConfigurationOptions_603737(path: JsonNode;
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
  var valid_603739 = query.getOrDefault("Options")
  valid_603739 = validateParameter(valid_603739, JArray, required = false,
                                 default = nil)
  if valid_603739 != nil:
    section.add "Options", valid_603739
  var valid_603740 = query.getOrDefault("ApplicationName")
  valid_603740 = validateParameter(valid_603740, JString, required = false,
                                 default = nil)
  if valid_603740 != nil:
    section.add "ApplicationName", valid_603740
  var valid_603741 = query.getOrDefault("PlatformArn")
  valid_603741 = validateParameter(valid_603741, JString, required = false,
                                 default = nil)
  if valid_603741 != nil:
    section.add "PlatformArn", valid_603741
  var valid_603742 = query.getOrDefault("EnvironmentName")
  valid_603742 = validateParameter(valid_603742, JString, required = false,
                                 default = nil)
  if valid_603742 != nil:
    section.add "EnvironmentName", valid_603742
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603743 = query.getOrDefault("Action")
  valid_603743 = validateParameter(valid_603743, JString, required = true, default = newJString(
      "DescribeConfigurationOptions"))
  if valid_603743 != nil:
    section.add "Action", valid_603743
  var valid_603744 = query.getOrDefault("SolutionStackName")
  valid_603744 = validateParameter(valid_603744, JString, required = false,
                                 default = nil)
  if valid_603744 != nil:
    section.add "SolutionStackName", valid_603744
  var valid_603745 = query.getOrDefault("TemplateName")
  valid_603745 = validateParameter(valid_603745, JString, required = false,
                                 default = nil)
  if valid_603745 != nil:
    section.add "TemplateName", valid_603745
  var valid_603746 = query.getOrDefault("Version")
  valid_603746 = validateParameter(valid_603746, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603746 != nil:
    section.add "Version", valid_603746
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
  var valid_603747 = header.getOrDefault("X-Amz-Date")
  valid_603747 = validateParameter(valid_603747, JString, required = false,
                                 default = nil)
  if valid_603747 != nil:
    section.add "X-Amz-Date", valid_603747
  var valid_603748 = header.getOrDefault("X-Amz-Security-Token")
  valid_603748 = validateParameter(valid_603748, JString, required = false,
                                 default = nil)
  if valid_603748 != nil:
    section.add "X-Amz-Security-Token", valid_603748
  var valid_603749 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603749 = validateParameter(valid_603749, JString, required = false,
                                 default = nil)
  if valid_603749 != nil:
    section.add "X-Amz-Content-Sha256", valid_603749
  var valid_603750 = header.getOrDefault("X-Amz-Algorithm")
  valid_603750 = validateParameter(valid_603750, JString, required = false,
                                 default = nil)
  if valid_603750 != nil:
    section.add "X-Amz-Algorithm", valid_603750
  var valid_603751 = header.getOrDefault("X-Amz-Signature")
  valid_603751 = validateParameter(valid_603751, JString, required = false,
                                 default = nil)
  if valid_603751 != nil:
    section.add "X-Amz-Signature", valid_603751
  var valid_603752 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603752 = validateParameter(valid_603752, JString, required = false,
                                 default = nil)
  if valid_603752 != nil:
    section.add "X-Amz-SignedHeaders", valid_603752
  var valid_603753 = header.getOrDefault("X-Amz-Credential")
  valid_603753 = validateParameter(valid_603753, JString, required = false,
                                 default = nil)
  if valid_603753 != nil:
    section.add "X-Amz-Credential", valid_603753
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603754: Call_GetDescribeConfigurationOptions_603736;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the configuration options that are used in a particular configuration template or environment, or that a specified solution stack defines. The description includes the values the options, their default values, and an indication of the required action on a running environment if an option value is changed.
  ## 
  let valid = call_603754.validator(path, query, header, formData, body)
  let scheme = call_603754.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603754.url(scheme.get, call_603754.host, call_603754.base,
                         call_603754.route, valid.getOrDefault("path"))
  result = hook(call_603754, url, valid)

proc call*(call_603755: Call_GetDescribeConfigurationOptions_603736;
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
  var query_603756 = newJObject()
  if Options != nil:
    query_603756.add "Options", Options
  add(query_603756, "ApplicationName", newJString(ApplicationName))
  add(query_603756, "PlatformArn", newJString(PlatformArn))
  add(query_603756, "EnvironmentName", newJString(EnvironmentName))
  add(query_603756, "Action", newJString(Action))
  add(query_603756, "SolutionStackName", newJString(SolutionStackName))
  add(query_603756, "TemplateName", newJString(TemplateName))
  add(query_603756, "Version", newJString(Version))
  result = call_603755.call(nil, query_603756, nil, nil, nil)

var getDescribeConfigurationOptions* = Call_GetDescribeConfigurationOptions_603736(
    name: "getDescribeConfigurationOptions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationOptions",
    validator: validate_GetDescribeConfigurationOptions_603737, base: "/",
    url: url_GetDescribeConfigurationOptions_603738,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeConfigurationSettings_603797 = ref object of OpenApiRestCall_602434
proc url_PostDescribeConfigurationSettings_603799(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeConfigurationSettings_603798(path: JsonNode;
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
  var valid_603800 = query.getOrDefault("Action")
  valid_603800 = validateParameter(valid_603800, JString, required = true, default = newJString(
      "DescribeConfigurationSettings"))
  if valid_603800 != nil:
    section.add "Action", valid_603800
  var valid_603801 = query.getOrDefault("Version")
  valid_603801 = validateParameter(valid_603801, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603801 != nil:
    section.add "Version", valid_603801
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
  var valid_603802 = header.getOrDefault("X-Amz-Date")
  valid_603802 = validateParameter(valid_603802, JString, required = false,
                                 default = nil)
  if valid_603802 != nil:
    section.add "X-Amz-Date", valid_603802
  var valid_603803 = header.getOrDefault("X-Amz-Security-Token")
  valid_603803 = validateParameter(valid_603803, JString, required = false,
                                 default = nil)
  if valid_603803 != nil:
    section.add "X-Amz-Security-Token", valid_603803
  var valid_603804 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603804 = validateParameter(valid_603804, JString, required = false,
                                 default = nil)
  if valid_603804 != nil:
    section.add "X-Amz-Content-Sha256", valid_603804
  var valid_603805 = header.getOrDefault("X-Amz-Algorithm")
  valid_603805 = validateParameter(valid_603805, JString, required = false,
                                 default = nil)
  if valid_603805 != nil:
    section.add "X-Amz-Algorithm", valid_603805
  var valid_603806 = header.getOrDefault("X-Amz-Signature")
  valid_603806 = validateParameter(valid_603806, JString, required = false,
                                 default = nil)
  if valid_603806 != nil:
    section.add "X-Amz-Signature", valid_603806
  var valid_603807 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603807 = validateParameter(valid_603807, JString, required = false,
                                 default = nil)
  if valid_603807 != nil:
    section.add "X-Amz-SignedHeaders", valid_603807
  var valid_603808 = header.getOrDefault("X-Amz-Credential")
  valid_603808 = validateParameter(valid_603808, JString, required = false,
                                 default = nil)
  if valid_603808 != nil:
    section.add "X-Amz-Credential", valid_603808
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to describe.</p> <p> Condition: You must specify either this or a TemplateName, but not both. If you specify both, AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   ApplicationName: JString (required)
  ##                  : The application for the environment or configuration template.
  ##   TemplateName: JString
  ##               : <p>The name of the configuration template to describe.</p> <p> Conditional: You must specify either this parameter or an EnvironmentName, but not both. If you specify both, AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. If you do not specify either, AWS Elastic Beanstalk returns a <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_603809 = formData.getOrDefault("EnvironmentName")
  valid_603809 = validateParameter(valid_603809, JString, required = false,
                                 default = nil)
  if valid_603809 != nil:
    section.add "EnvironmentName", valid_603809
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_603810 = formData.getOrDefault("ApplicationName")
  valid_603810 = validateParameter(valid_603810, JString, required = true,
                                 default = nil)
  if valid_603810 != nil:
    section.add "ApplicationName", valid_603810
  var valid_603811 = formData.getOrDefault("TemplateName")
  valid_603811 = validateParameter(valid_603811, JString, required = false,
                                 default = nil)
  if valid_603811 != nil:
    section.add "TemplateName", valid_603811
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603812: Call_PostDescribeConfigurationSettings_603797;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a description of the settings for the specified configuration set, that is, either a configuration template or the configuration set associated with a running environment.</p> <p>When describing the settings for the configuration set associated with a running environment, it is possible to receive two sets of setting descriptions. One is the deployed configuration set, and the other is a draft configuration of an environment that is either in the process of deployment or that failed to deploy.</p> <p>Related Topics</p> <ul> <li> <p> <a>DeleteEnvironmentConfiguration</a> </p> </li> </ul>
  ## 
  let valid = call_603812.validator(path, query, header, formData, body)
  let scheme = call_603812.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603812.url(scheme.get, call_603812.host, call_603812.base,
                         call_603812.route, valid.getOrDefault("path"))
  result = hook(call_603812, url, valid)

proc call*(call_603813: Call_PostDescribeConfigurationSettings_603797;
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
  var query_603814 = newJObject()
  var formData_603815 = newJObject()
  add(formData_603815, "EnvironmentName", newJString(EnvironmentName))
  add(query_603814, "Action", newJString(Action))
  add(formData_603815, "ApplicationName", newJString(ApplicationName))
  add(formData_603815, "TemplateName", newJString(TemplateName))
  add(query_603814, "Version", newJString(Version))
  result = call_603813.call(nil, query_603814, nil, formData_603815, nil)

var postDescribeConfigurationSettings* = Call_PostDescribeConfigurationSettings_603797(
    name: "postDescribeConfigurationSettings", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationSettings",
    validator: validate_PostDescribeConfigurationSettings_603798, base: "/",
    url: url_PostDescribeConfigurationSettings_603799,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeConfigurationSettings_603779 = ref object of OpenApiRestCall_602434
proc url_GetDescribeConfigurationSettings_603781(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeConfigurationSettings_603780(path: JsonNode;
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
  var valid_603782 = query.getOrDefault("ApplicationName")
  valid_603782 = validateParameter(valid_603782, JString, required = true,
                                 default = nil)
  if valid_603782 != nil:
    section.add "ApplicationName", valid_603782
  var valid_603783 = query.getOrDefault("EnvironmentName")
  valid_603783 = validateParameter(valid_603783, JString, required = false,
                                 default = nil)
  if valid_603783 != nil:
    section.add "EnvironmentName", valid_603783
  var valid_603784 = query.getOrDefault("Action")
  valid_603784 = validateParameter(valid_603784, JString, required = true, default = newJString(
      "DescribeConfigurationSettings"))
  if valid_603784 != nil:
    section.add "Action", valid_603784
  var valid_603785 = query.getOrDefault("TemplateName")
  valid_603785 = validateParameter(valid_603785, JString, required = false,
                                 default = nil)
  if valid_603785 != nil:
    section.add "TemplateName", valid_603785
  var valid_603786 = query.getOrDefault("Version")
  valid_603786 = validateParameter(valid_603786, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603786 != nil:
    section.add "Version", valid_603786
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
  var valid_603787 = header.getOrDefault("X-Amz-Date")
  valid_603787 = validateParameter(valid_603787, JString, required = false,
                                 default = nil)
  if valid_603787 != nil:
    section.add "X-Amz-Date", valid_603787
  var valid_603788 = header.getOrDefault("X-Amz-Security-Token")
  valid_603788 = validateParameter(valid_603788, JString, required = false,
                                 default = nil)
  if valid_603788 != nil:
    section.add "X-Amz-Security-Token", valid_603788
  var valid_603789 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603789 = validateParameter(valid_603789, JString, required = false,
                                 default = nil)
  if valid_603789 != nil:
    section.add "X-Amz-Content-Sha256", valid_603789
  var valid_603790 = header.getOrDefault("X-Amz-Algorithm")
  valid_603790 = validateParameter(valid_603790, JString, required = false,
                                 default = nil)
  if valid_603790 != nil:
    section.add "X-Amz-Algorithm", valid_603790
  var valid_603791 = header.getOrDefault("X-Amz-Signature")
  valid_603791 = validateParameter(valid_603791, JString, required = false,
                                 default = nil)
  if valid_603791 != nil:
    section.add "X-Amz-Signature", valid_603791
  var valid_603792 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603792 = validateParameter(valid_603792, JString, required = false,
                                 default = nil)
  if valid_603792 != nil:
    section.add "X-Amz-SignedHeaders", valid_603792
  var valid_603793 = header.getOrDefault("X-Amz-Credential")
  valid_603793 = validateParameter(valid_603793, JString, required = false,
                                 default = nil)
  if valid_603793 != nil:
    section.add "X-Amz-Credential", valid_603793
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603794: Call_GetDescribeConfigurationSettings_603779;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a description of the settings for the specified configuration set, that is, either a configuration template or the configuration set associated with a running environment.</p> <p>When describing the settings for the configuration set associated with a running environment, it is possible to receive two sets of setting descriptions. One is the deployed configuration set, and the other is a draft configuration of an environment that is either in the process of deployment or that failed to deploy.</p> <p>Related Topics</p> <ul> <li> <p> <a>DeleteEnvironmentConfiguration</a> </p> </li> </ul>
  ## 
  let valid = call_603794.validator(path, query, header, formData, body)
  let scheme = call_603794.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603794.url(scheme.get, call_603794.host, call_603794.base,
                         call_603794.route, valid.getOrDefault("path"))
  result = hook(call_603794, url, valid)

proc call*(call_603795: Call_GetDescribeConfigurationSettings_603779;
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
  var query_603796 = newJObject()
  add(query_603796, "ApplicationName", newJString(ApplicationName))
  add(query_603796, "EnvironmentName", newJString(EnvironmentName))
  add(query_603796, "Action", newJString(Action))
  add(query_603796, "TemplateName", newJString(TemplateName))
  add(query_603796, "Version", newJString(Version))
  result = call_603795.call(nil, query_603796, nil, nil, nil)

var getDescribeConfigurationSettings* = Call_GetDescribeConfigurationSettings_603779(
    name: "getDescribeConfigurationSettings", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationSettings",
    validator: validate_GetDescribeConfigurationSettings_603780, base: "/",
    url: url_GetDescribeConfigurationSettings_603781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentHealth_603834 = ref object of OpenApiRestCall_602434
proc url_PostDescribeEnvironmentHealth_603836(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEnvironmentHealth_603835(path: JsonNode; query: JsonNode;
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
  var valid_603837 = query.getOrDefault("Action")
  valid_603837 = validateParameter(valid_603837, JString, required = true, default = newJString(
      "DescribeEnvironmentHealth"))
  if valid_603837 != nil:
    section.add "Action", valid_603837
  var valid_603838 = query.getOrDefault("Version")
  valid_603838 = validateParameter(valid_603838, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603838 != nil:
    section.add "Version", valid_603838
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
  var valid_603839 = header.getOrDefault("X-Amz-Date")
  valid_603839 = validateParameter(valid_603839, JString, required = false,
                                 default = nil)
  if valid_603839 != nil:
    section.add "X-Amz-Date", valid_603839
  var valid_603840 = header.getOrDefault("X-Amz-Security-Token")
  valid_603840 = validateParameter(valid_603840, JString, required = false,
                                 default = nil)
  if valid_603840 != nil:
    section.add "X-Amz-Security-Token", valid_603840
  var valid_603841 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603841 = validateParameter(valid_603841, JString, required = false,
                                 default = nil)
  if valid_603841 != nil:
    section.add "X-Amz-Content-Sha256", valid_603841
  var valid_603842 = header.getOrDefault("X-Amz-Algorithm")
  valid_603842 = validateParameter(valid_603842, JString, required = false,
                                 default = nil)
  if valid_603842 != nil:
    section.add "X-Amz-Algorithm", valid_603842
  var valid_603843 = header.getOrDefault("X-Amz-Signature")
  valid_603843 = validateParameter(valid_603843, JString, required = false,
                                 default = nil)
  if valid_603843 != nil:
    section.add "X-Amz-Signature", valid_603843
  var valid_603844 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603844 = validateParameter(valid_603844, JString, required = false,
                                 default = nil)
  if valid_603844 != nil:
    section.add "X-Amz-SignedHeaders", valid_603844
  var valid_603845 = header.getOrDefault("X-Amz-Credential")
  valid_603845 = validateParameter(valid_603845, JString, required = false,
                                 default = nil)
  if valid_603845 != nil:
    section.add "X-Amz-Credential", valid_603845
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentId: JString
  ##                : <p>Specify the environment by ID.</p> <p>You must specify either this or an EnvironmentName, or both.</p>
  ##   EnvironmentName: JString
  ##                  : <p>Specify the environment by name.</p> <p>You must specify either this or an EnvironmentName, or both.</p>
  ##   AttributeNames: JArray
  ##                 : Specify the response elements to return. To retrieve all attributes, set to <code>All</code>. If no attribute names are specified, returns the name of the environment.
  section = newJObject()
  var valid_603846 = formData.getOrDefault("EnvironmentId")
  valid_603846 = validateParameter(valid_603846, JString, required = false,
                                 default = nil)
  if valid_603846 != nil:
    section.add "EnvironmentId", valid_603846
  var valid_603847 = formData.getOrDefault("EnvironmentName")
  valid_603847 = validateParameter(valid_603847, JString, required = false,
                                 default = nil)
  if valid_603847 != nil:
    section.add "EnvironmentName", valid_603847
  var valid_603848 = formData.getOrDefault("AttributeNames")
  valid_603848 = validateParameter(valid_603848, JArray, required = false,
                                 default = nil)
  if valid_603848 != nil:
    section.add "AttributeNames", valid_603848
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603849: Call_PostDescribeEnvironmentHealth_603834; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the overall health of the specified environment. The <b>DescribeEnvironmentHealth</b> operation is only available with AWS Elastic Beanstalk Enhanced Health.
  ## 
  let valid = call_603849.validator(path, query, header, formData, body)
  let scheme = call_603849.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603849.url(scheme.get, call_603849.host, call_603849.base,
                         call_603849.route, valid.getOrDefault("path"))
  result = hook(call_603849, url, valid)

proc call*(call_603850: Call_PostDescribeEnvironmentHealth_603834;
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
  var query_603851 = newJObject()
  var formData_603852 = newJObject()
  add(formData_603852, "EnvironmentId", newJString(EnvironmentId))
  add(formData_603852, "EnvironmentName", newJString(EnvironmentName))
  add(query_603851, "Action", newJString(Action))
  if AttributeNames != nil:
    formData_603852.add "AttributeNames", AttributeNames
  add(query_603851, "Version", newJString(Version))
  result = call_603850.call(nil, query_603851, nil, formData_603852, nil)

var postDescribeEnvironmentHealth* = Call_PostDescribeEnvironmentHealth_603834(
    name: "postDescribeEnvironmentHealth", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentHealth",
    validator: validate_PostDescribeEnvironmentHealth_603835, base: "/",
    url: url_PostDescribeEnvironmentHealth_603836,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentHealth_603816 = ref object of OpenApiRestCall_602434
proc url_GetDescribeEnvironmentHealth_603818(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEnvironmentHealth_603817(path: JsonNode; query: JsonNode;
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
  var valid_603819 = query.getOrDefault("AttributeNames")
  valid_603819 = validateParameter(valid_603819, JArray, required = false,
                                 default = nil)
  if valid_603819 != nil:
    section.add "AttributeNames", valid_603819
  var valid_603820 = query.getOrDefault("EnvironmentName")
  valid_603820 = validateParameter(valid_603820, JString, required = false,
                                 default = nil)
  if valid_603820 != nil:
    section.add "EnvironmentName", valid_603820
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603821 = query.getOrDefault("Action")
  valid_603821 = validateParameter(valid_603821, JString, required = true, default = newJString(
      "DescribeEnvironmentHealth"))
  if valid_603821 != nil:
    section.add "Action", valid_603821
  var valid_603822 = query.getOrDefault("EnvironmentId")
  valid_603822 = validateParameter(valid_603822, JString, required = false,
                                 default = nil)
  if valid_603822 != nil:
    section.add "EnvironmentId", valid_603822
  var valid_603823 = query.getOrDefault("Version")
  valid_603823 = validateParameter(valid_603823, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603823 != nil:
    section.add "Version", valid_603823
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
  var valid_603824 = header.getOrDefault("X-Amz-Date")
  valid_603824 = validateParameter(valid_603824, JString, required = false,
                                 default = nil)
  if valid_603824 != nil:
    section.add "X-Amz-Date", valid_603824
  var valid_603825 = header.getOrDefault("X-Amz-Security-Token")
  valid_603825 = validateParameter(valid_603825, JString, required = false,
                                 default = nil)
  if valid_603825 != nil:
    section.add "X-Amz-Security-Token", valid_603825
  var valid_603826 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603826 = validateParameter(valid_603826, JString, required = false,
                                 default = nil)
  if valid_603826 != nil:
    section.add "X-Amz-Content-Sha256", valid_603826
  var valid_603827 = header.getOrDefault("X-Amz-Algorithm")
  valid_603827 = validateParameter(valid_603827, JString, required = false,
                                 default = nil)
  if valid_603827 != nil:
    section.add "X-Amz-Algorithm", valid_603827
  var valid_603828 = header.getOrDefault("X-Amz-Signature")
  valid_603828 = validateParameter(valid_603828, JString, required = false,
                                 default = nil)
  if valid_603828 != nil:
    section.add "X-Amz-Signature", valid_603828
  var valid_603829 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603829 = validateParameter(valid_603829, JString, required = false,
                                 default = nil)
  if valid_603829 != nil:
    section.add "X-Amz-SignedHeaders", valid_603829
  var valid_603830 = header.getOrDefault("X-Amz-Credential")
  valid_603830 = validateParameter(valid_603830, JString, required = false,
                                 default = nil)
  if valid_603830 != nil:
    section.add "X-Amz-Credential", valid_603830
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603831: Call_GetDescribeEnvironmentHealth_603816; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the overall health of the specified environment. The <b>DescribeEnvironmentHealth</b> operation is only available with AWS Elastic Beanstalk Enhanced Health.
  ## 
  let valid = call_603831.validator(path, query, header, formData, body)
  let scheme = call_603831.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603831.url(scheme.get, call_603831.host, call_603831.base,
                         call_603831.route, valid.getOrDefault("path"))
  result = hook(call_603831, url, valid)

proc call*(call_603832: Call_GetDescribeEnvironmentHealth_603816;
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
  var query_603833 = newJObject()
  if AttributeNames != nil:
    query_603833.add "AttributeNames", AttributeNames
  add(query_603833, "EnvironmentName", newJString(EnvironmentName))
  add(query_603833, "Action", newJString(Action))
  add(query_603833, "EnvironmentId", newJString(EnvironmentId))
  add(query_603833, "Version", newJString(Version))
  result = call_603832.call(nil, query_603833, nil, nil, nil)

var getDescribeEnvironmentHealth* = Call_GetDescribeEnvironmentHealth_603816(
    name: "getDescribeEnvironmentHealth", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentHealth",
    validator: validate_GetDescribeEnvironmentHealth_603817, base: "/",
    url: url_GetDescribeEnvironmentHealth_603818,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentManagedActionHistory_603872 = ref object of OpenApiRestCall_602434
proc url_PostDescribeEnvironmentManagedActionHistory_603874(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEnvironmentManagedActionHistory_603873(path: JsonNode;
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
  var valid_603875 = query.getOrDefault("Action")
  valid_603875 = validateParameter(valid_603875, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActionHistory"))
  if valid_603875 != nil:
    section.add "Action", valid_603875
  var valid_603876 = query.getOrDefault("Version")
  valid_603876 = validateParameter(valid_603876, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603876 != nil:
    section.add "Version", valid_603876
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
  var valid_603877 = header.getOrDefault("X-Amz-Date")
  valid_603877 = validateParameter(valid_603877, JString, required = false,
                                 default = nil)
  if valid_603877 != nil:
    section.add "X-Amz-Date", valid_603877
  var valid_603878 = header.getOrDefault("X-Amz-Security-Token")
  valid_603878 = validateParameter(valid_603878, JString, required = false,
                                 default = nil)
  if valid_603878 != nil:
    section.add "X-Amz-Security-Token", valid_603878
  var valid_603879 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603879 = validateParameter(valid_603879, JString, required = false,
                                 default = nil)
  if valid_603879 != nil:
    section.add "X-Amz-Content-Sha256", valid_603879
  var valid_603880 = header.getOrDefault("X-Amz-Algorithm")
  valid_603880 = validateParameter(valid_603880, JString, required = false,
                                 default = nil)
  if valid_603880 != nil:
    section.add "X-Amz-Algorithm", valid_603880
  var valid_603881 = header.getOrDefault("X-Amz-Signature")
  valid_603881 = validateParameter(valid_603881, JString, required = false,
                                 default = nil)
  if valid_603881 != nil:
    section.add "X-Amz-Signature", valid_603881
  var valid_603882 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603882 = validateParameter(valid_603882, JString, required = false,
                                 default = nil)
  if valid_603882 != nil:
    section.add "X-Amz-SignedHeaders", valid_603882
  var valid_603883 = header.getOrDefault("X-Amz-Credential")
  valid_603883 = validateParameter(valid_603883, JString, required = false,
                                 default = nil)
  if valid_603883 != nil:
    section.add "X-Amz-Credential", valid_603883
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
  var valid_603884 = formData.getOrDefault("NextToken")
  valid_603884 = validateParameter(valid_603884, JString, required = false,
                                 default = nil)
  if valid_603884 != nil:
    section.add "NextToken", valid_603884
  var valid_603885 = formData.getOrDefault("EnvironmentId")
  valid_603885 = validateParameter(valid_603885, JString, required = false,
                                 default = nil)
  if valid_603885 != nil:
    section.add "EnvironmentId", valid_603885
  var valid_603886 = formData.getOrDefault("EnvironmentName")
  valid_603886 = validateParameter(valid_603886, JString, required = false,
                                 default = nil)
  if valid_603886 != nil:
    section.add "EnvironmentName", valid_603886
  var valid_603887 = formData.getOrDefault("MaxItems")
  valid_603887 = validateParameter(valid_603887, JInt, required = false, default = nil)
  if valid_603887 != nil:
    section.add "MaxItems", valid_603887
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603888: Call_PostDescribeEnvironmentManagedActionHistory_603872;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists an environment's completed and failed managed actions.
  ## 
  let valid = call_603888.validator(path, query, header, formData, body)
  let scheme = call_603888.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603888.url(scheme.get, call_603888.host, call_603888.base,
                         call_603888.route, valid.getOrDefault("path"))
  result = hook(call_603888, url, valid)

proc call*(call_603889: Call_PostDescribeEnvironmentManagedActionHistory_603872;
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
  var query_603890 = newJObject()
  var formData_603891 = newJObject()
  add(formData_603891, "NextToken", newJString(NextToken))
  add(formData_603891, "EnvironmentId", newJString(EnvironmentId))
  add(formData_603891, "EnvironmentName", newJString(EnvironmentName))
  add(query_603890, "Action", newJString(Action))
  add(formData_603891, "MaxItems", newJInt(MaxItems))
  add(query_603890, "Version", newJString(Version))
  result = call_603889.call(nil, query_603890, nil, formData_603891, nil)

var postDescribeEnvironmentManagedActionHistory* = Call_PostDescribeEnvironmentManagedActionHistory_603872(
    name: "postDescribeEnvironmentManagedActionHistory",
    meth: HttpMethod.HttpPost, host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActionHistory",
    validator: validate_PostDescribeEnvironmentManagedActionHistory_603873,
    base: "/", url: url_PostDescribeEnvironmentManagedActionHistory_603874,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentManagedActionHistory_603853 = ref object of OpenApiRestCall_602434
proc url_GetDescribeEnvironmentManagedActionHistory_603855(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEnvironmentManagedActionHistory_603854(path: JsonNode;
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
  var valid_603856 = query.getOrDefault("NextToken")
  valid_603856 = validateParameter(valid_603856, JString, required = false,
                                 default = nil)
  if valid_603856 != nil:
    section.add "NextToken", valid_603856
  var valid_603857 = query.getOrDefault("EnvironmentName")
  valid_603857 = validateParameter(valid_603857, JString, required = false,
                                 default = nil)
  if valid_603857 != nil:
    section.add "EnvironmentName", valid_603857
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603858 = query.getOrDefault("Action")
  valid_603858 = validateParameter(valid_603858, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActionHistory"))
  if valid_603858 != nil:
    section.add "Action", valid_603858
  var valid_603859 = query.getOrDefault("EnvironmentId")
  valid_603859 = validateParameter(valid_603859, JString, required = false,
                                 default = nil)
  if valid_603859 != nil:
    section.add "EnvironmentId", valid_603859
  var valid_603860 = query.getOrDefault("MaxItems")
  valid_603860 = validateParameter(valid_603860, JInt, required = false, default = nil)
  if valid_603860 != nil:
    section.add "MaxItems", valid_603860
  var valid_603861 = query.getOrDefault("Version")
  valid_603861 = validateParameter(valid_603861, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603861 != nil:
    section.add "Version", valid_603861
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
  var valid_603862 = header.getOrDefault("X-Amz-Date")
  valid_603862 = validateParameter(valid_603862, JString, required = false,
                                 default = nil)
  if valid_603862 != nil:
    section.add "X-Amz-Date", valid_603862
  var valid_603863 = header.getOrDefault("X-Amz-Security-Token")
  valid_603863 = validateParameter(valid_603863, JString, required = false,
                                 default = nil)
  if valid_603863 != nil:
    section.add "X-Amz-Security-Token", valid_603863
  var valid_603864 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603864 = validateParameter(valid_603864, JString, required = false,
                                 default = nil)
  if valid_603864 != nil:
    section.add "X-Amz-Content-Sha256", valid_603864
  var valid_603865 = header.getOrDefault("X-Amz-Algorithm")
  valid_603865 = validateParameter(valid_603865, JString, required = false,
                                 default = nil)
  if valid_603865 != nil:
    section.add "X-Amz-Algorithm", valid_603865
  var valid_603866 = header.getOrDefault("X-Amz-Signature")
  valid_603866 = validateParameter(valid_603866, JString, required = false,
                                 default = nil)
  if valid_603866 != nil:
    section.add "X-Amz-Signature", valid_603866
  var valid_603867 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603867 = validateParameter(valid_603867, JString, required = false,
                                 default = nil)
  if valid_603867 != nil:
    section.add "X-Amz-SignedHeaders", valid_603867
  var valid_603868 = header.getOrDefault("X-Amz-Credential")
  valid_603868 = validateParameter(valid_603868, JString, required = false,
                                 default = nil)
  if valid_603868 != nil:
    section.add "X-Amz-Credential", valid_603868
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603869: Call_GetDescribeEnvironmentManagedActionHistory_603853;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists an environment's completed and failed managed actions.
  ## 
  let valid = call_603869.validator(path, query, header, formData, body)
  let scheme = call_603869.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603869.url(scheme.get, call_603869.host, call_603869.base,
                         call_603869.route, valid.getOrDefault("path"))
  result = hook(call_603869, url, valid)

proc call*(call_603870: Call_GetDescribeEnvironmentManagedActionHistory_603853;
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
  var query_603871 = newJObject()
  add(query_603871, "NextToken", newJString(NextToken))
  add(query_603871, "EnvironmentName", newJString(EnvironmentName))
  add(query_603871, "Action", newJString(Action))
  add(query_603871, "EnvironmentId", newJString(EnvironmentId))
  add(query_603871, "MaxItems", newJInt(MaxItems))
  add(query_603871, "Version", newJString(Version))
  result = call_603870.call(nil, query_603871, nil, nil, nil)

var getDescribeEnvironmentManagedActionHistory* = Call_GetDescribeEnvironmentManagedActionHistory_603853(
    name: "getDescribeEnvironmentManagedActionHistory", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActionHistory",
    validator: validate_GetDescribeEnvironmentManagedActionHistory_603854,
    base: "/", url: url_GetDescribeEnvironmentManagedActionHistory_603855,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentManagedActions_603910 = ref object of OpenApiRestCall_602434
proc url_PostDescribeEnvironmentManagedActions_603912(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEnvironmentManagedActions_603911(path: JsonNode;
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
  var valid_603913 = query.getOrDefault("Action")
  valid_603913 = validateParameter(valid_603913, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActions"))
  if valid_603913 != nil:
    section.add "Action", valid_603913
  var valid_603914 = query.getOrDefault("Version")
  valid_603914 = validateParameter(valid_603914, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603914 != nil:
    section.add "Version", valid_603914
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
  var valid_603915 = header.getOrDefault("X-Amz-Date")
  valid_603915 = validateParameter(valid_603915, JString, required = false,
                                 default = nil)
  if valid_603915 != nil:
    section.add "X-Amz-Date", valid_603915
  var valid_603916 = header.getOrDefault("X-Amz-Security-Token")
  valid_603916 = validateParameter(valid_603916, JString, required = false,
                                 default = nil)
  if valid_603916 != nil:
    section.add "X-Amz-Security-Token", valid_603916
  var valid_603917 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603917 = validateParameter(valid_603917, JString, required = false,
                                 default = nil)
  if valid_603917 != nil:
    section.add "X-Amz-Content-Sha256", valid_603917
  var valid_603918 = header.getOrDefault("X-Amz-Algorithm")
  valid_603918 = validateParameter(valid_603918, JString, required = false,
                                 default = nil)
  if valid_603918 != nil:
    section.add "X-Amz-Algorithm", valid_603918
  var valid_603919 = header.getOrDefault("X-Amz-Signature")
  valid_603919 = validateParameter(valid_603919, JString, required = false,
                                 default = nil)
  if valid_603919 != nil:
    section.add "X-Amz-Signature", valid_603919
  var valid_603920 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603920 = validateParameter(valid_603920, JString, required = false,
                                 default = nil)
  if valid_603920 != nil:
    section.add "X-Amz-SignedHeaders", valid_603920
  var valid_603921 = header.getOrDefault("X-Amz-Credential")
  valid_603921 = validateParameter(valid_603921, JString, required = false,
                                 default = nil)
  if valid_603921 != nil:
    section.add "X-Amz-Credential", valid_603921
  result.add "header", section
  ## parameters in `formData` object:
  ##   Status: JString
  ##         : To show only actions with a particular status, specify a status.
  ##   EnvironmentId: JString
  ##                : The environment ID of the target environment.
  ##   EnvironmentName: JString
  ##                  : The name of the target environment.
  section = newJObject()
  var valid_603922 = formData.getOrDefault("Status")
  valid_603922 = validateParameter(valid_603922, JString, required = false,
                                 default = newJString("Scheduled"))
  if valid_603922 != nil:
    section.add "Status", valid_603922
  var valid_603923 = formData.getOrDefault("EnvironmentId")
  valid_603923 = validateParameter(valid_603923, JString, required = false,
                                 default = nil)
  if valid_603923 != nil:
    section.add "EnvironmentId", valid_603923
  var valid_603924 = formData.getOrDefault("EnvironmentName")
  valid_603924 = validateParameter(valid_603924, JString, required = false,
                                 default = nil)
  if valid_603924 != nil:
    section.add "EnvironmentName", valid_603924
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603925: Call_PostDescribeEnvironmentManagedActions_603910;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists an environment's upcoming and in-progress managed actions.
  ## 
  let valid = call_603925.validator(path, query, header, formData, body)
  let scheme = call_603925.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603925.url(scheme.get, call_603925.host, call_603925.base,
                         call_603925.route, valid.getOrDefault("path"))
  result = hook(call_603925, url, valid)

proc call*(call_603926: Call_PostDescribeEnvironmentManagedActions_603910;
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
  var query_603927 = newJObject()
  var formData_603928 = newJObject()
  add(formData_603928, "Status", newJString(Status))
  add(formData_603928, "EnvironmentId", newJString(EnvironmentId))
  add(formData_603928, "EnvironmentName", newJString(EnvironmentName))
  add(query_603927, "Action", newJString(Action))
  add(query_603927, "Version", newJString(Version))
  result = call_603926.call(nil, query_603927, nil, formData_603928, nil)

var postDescribeEnvironmentManagedActions* = Call_PostDescribeEnvironmentManagedActions_603910(
    name: "postDescribeEnvironmentManagedActions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActions",
    validator: validate_PostDescribeEnvironmentManagedActions_603911, base: "/",
    url: url_PostDescribeEnvironmentManagedActions_603912,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentManagedActions_603892 = ref object of OpenApiRestCall_602434
proc url_GetDescribeEnvironmentManagedActions_603894(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEnvironmentManagedActions_603893(path: JsonNode;
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
  var valid_603895 = query.getOrDefault("Status")
  valid_603895 = validateParameter(valid_603895, JString, required = false,
                                 default = newJString("Scheduled"))
  if valid_603895 != nil:
    section.add "Status", valid_603895
  var valid_603896 = query.getOrDefault("EnvironmentName")
  valid_603896 = validateParameter(valid_603896, JString, required = false,
                                 default = nil)
  if valid_603896 != nil:
    section.add "EnvironmentName", valid_603896
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603897 = query.getOrDefault("Action")
  valid_603897 = validateParameter(valid_603897, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActions"))
  if valid_603897 != nil:
    section.add "Action", valid_603897
  var valid_603898 = query.getOrDefault("EnvironmentId")
  valid_603898 = validateParameter(valid_603898, JString, required = false,
                                 default = nil)
  if valid_603898 != nil:
    section.add "EnvironmentId", valid_603898
  var valid_603899 = query.getOrDefault("Version")
  valid_603899 = validateParameter(valid_603899, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603899 != nil:
    section.add "Version", valid_603899
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
  var valid_603900 = header.getOrDefault("X-Amz-Date")
  valid_603900 = validateParameter(valid_603900, JString, required = false,
                                 default = nil)
  if valid_603900 != nil:
    section.add "X-Amz-Date", valid_603900
  var valid_603901 = header.getOrDefault("X-Amz-Security-Token")
  valid_603901 = validateParameter(valid_603901, JString, required = false,
                                 default = nil)
  if valid_603901 != nil:
    section.add "X-Amz-Security-Token", valid_603901
  var valid_603902 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603902 = validateParameter(valid_603902, JString, required = false,
                                 default = nil)
  if valid_603902 != nil:
    section.add "X-Amz-Content-Sha256", valid_603902
  var valid_603903 = header.getOrDefault("X-Amz-Algorithm")
  valid_603903 = validateParameter(valid_603903, JString, required = false,
                                 default = nil)
  if valid_603903 != nil:
    section.add "X-Amz-Algorithm", valid_603903
  var valid_603904 = header.getOrDefault("X-Amz-Signature")
  valid_603904 = validateParameter(valid_603904, JString, required = false,
                                 default = nil)
  if valid_603904 != nil:
    section.add "X-Amz-Signature", valid_603904
  var valid_603905 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603905 = validateParameter(valid_603905, JString, required = false,
                                 default = nil)
  if valid_603905 != nil:
    section.add "X-Amz-SignedHeaders", valid_603905
  var valid_603906 = header.getOrDefault("X-Amz-Credential")
  valid_603906 = validateParameter(valid_603906, JString, required = false,
                                 default = nil)
  if valid_603906 != nil:
    section.add "X-Amz-Credential", valid_603906
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603907: Call_GetDescribeEnvironmentManagedActions_603892;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists an environment's upcoming and in-progress managed actions.
  ## 
  let valid = call_603907.validator(path, query, header, formData, body)
  let scheme = call_603907.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603907.url(scheme.get, call_603907.host, call_603907.base,
                         call_603907.route, valid.getOrDefault("path"))
  result = hook(call_603907, url, valid)

proc call*(call_603908: Call_GetDescribeEnvironmentManagedActions_603892;
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
  var query_603909 = newJObject()
  add(query_603909, "Status", newJString(Status))
  add(query_603909, "EnvironmentName", newJString(EnvironmentName))
  add(query_603909, "Action", newJString(Action))
  add(query_603909, "EnvironmentId", newJString(EnvironmentId))
  add(query_603909, "Version", newJString(Version))
  result = call_603908.call(nil, query_603909, nil, nil, nil)

var getDescribeEnvironmentManagedActions* = Call_GetDescribeEnvironmentManagedActions_603892(
    name: "getDescribeEnvironmentManagedActions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActions",
    validator: validate_GetDescribeEnvironmentManagedActions_603893, base: "/",
    url: url_GetDescribeEnvironmentManagedActions_603894,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentResources_603946 = ref object of OpenApiRestCall_602434
proc url_PostDescribeEnvironmentResources_603948(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEnvironmentResources_603947(path: JsonNode;
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
  var valid_603949 = query.getOrDefault("Action")
  valid_603949 = validateParameter(valid_603949, JString, required = true, default = newJString(
      "DescribeEnvironmentResources"))
  if valid_603949 != nil:
    section.add "Action", valid_603949
  var valid_603950 = query.getOrDefault("Version")
  valid_603950 = validateParameter(valid_603950, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603950 != nil:
    section.add "Version", valid_603950
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
  var valid_603951 = header.getOrDefault("X-Amz-Date")
  valid_603951 = validateParameter(valid_603951, JString, required = false,
                                 default = nil)
  if valid_603951 != nil:
    section.add "X-Amz-Date", valid_603951
  var valid_603952 = header.getOrDefault("X-Amz-Security-Token")
  valid_603952 = validateParameter(valid_603952, JString, required = false,
                                 default = nil)
  if valid_603952 != nil:
    section.add "X-Amz-Security-Token", valid_603952
  var valid_603953 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603953 = validateParameter(valid_603953, JString, required = false,
                                 default = nil)
  if valid_603953 != nil:
    section.add "X-Amz-Content-Sha256", valid_603953
  var valid_603954 = header.getOrDefault("X-Amz-Algorithm")
  valid_603954 = validateParameter(valid_603954, JString, required = false,
                                 default = nil)
  if valid_603954 != nil:
    section.add "X-Amz-Algorithm", valid_603954
  var valid_603955 = header.getOrDefault("X-Amz-Signature")
  valid_603955 = validateParameter(valid_603955, JString, required = false,
                                 default = nil)
  if valid_603955 != nil:
    section.add "X-Amz-Signature", valid_603955
  var valid_603956 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603956 = validateParameter(valid_603956, JString, required = false,
                                 default = nil)
  if valid_603956 != nil:
    section.add "X-Amz-SignedHeaders", valid_603956
  var valid_603957 = header.getOrDefault("X-Amz-Credential")
  valid_603957 = validateParameter(valid_603957, JString, required = false,
                                 default = nil)
  if valid_603957 != nil:
    section.add "X-Amz-Credential", valid_603957
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to retrieve AWS resource usage data.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to retrieve AWS resource usage data.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_603958 = formData.getOrDefault("EnvironmentId")
  valid_603958 = validateParameter(valid_603958, JString, required = false,
                                 default = nil)
  if valid_603958 != nil:
    section.add "EnvironmentId", valid_603958
  var valid_603959 = formData.getOrDefault("EnvironmentName")
  valid_603959 = validateParameter(valid_603959, JString, required = false,
                                 default = nil)
  if valid_603959 != nil:
    section.add "EnvironmentName", valid_603959
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603960: Call_PostDescribeEnvironmentResources_603946;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns AWS resources for this environment.
  ## 
  let valid = call_603960.validator(path, query, header, formData, body)
  let scheme = call_603960.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603960.url(scheme.get, call_603960.host, call_603960.base,
                         call_603960.route, valid.getOrDefault("path"))
  result = hook(call_603960, url, valid)

proc call*(call_603961: Call_PostDescribeEnvironmentResources_603946;
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
  var query_603962 = newJObject()
  var formData_603963 = newJObject()
  add(formData_603963, "EnvironmentId", newJString(EnvironmentId))
  add(formData_603963, "EnvironmentName", newJString(EnvironmentName))
  add(query_603962, "Action", newJString(Action))
  add(query_603962, "Version", newJString(Version))
  result = call_603961.call(nil, query_603962, nil, formData_603963, nil)

var postDescribeEnvironmentResources* = Call_PostDescribeEnvironmentResources_603946(
    name: "postDescribeEnvironmentResources", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentResources",
    validator: validate_PostDescribeEnvironmentResources_603947, base: "/",
    url: url_PostDescribeEnvironmentResources_603948,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentResources_603929 = ref object of OpenApiRestCall_602434
proc url_GetDescribeEnvironmentResources_603931(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEnvironmentResources_603930(path: JsonNode;
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
  var valid_603932 = query.getOrDefault("EnvironmentName")
  valid_603932 = validateParameter(valid_603932, JString, required = false,
                                 default = nil)
  if valid_603932 != nil:
    section.add "EnvironmentName", valid_603932
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603933 = query.getOrDefault("Action")
  valid_603933 = validateParameter(valid_603933, JString, required = true, default = newJString(
      "DescribeEnvironmentResources"))
  if valid_603933 != nil:
    section.add "Action", valid_603933
  var valid_603934 = query.getOrDefault("EnvironmentId")
  valid_603934 = validateParameter(valid_603934, JString, required = false,
                                 default = nil)
  if valid_603934 != nil:
    section.add "EnvironmentId", valid_603934
  var valid_603935 = query.getOrDefault("Version")
  valid_603935 = validateParameter(valid_603935, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603935 != nil:
    section.add "Version", valid_603935
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
  var valid_603936 = header.getOrDefault("X-Amz-Date")
  valid_603936 = validateParameter(valid_603936, JString, required = false,
                                 default = nil)
  if valid_603936 != nil:
    section.add "X-Amz-Date", valid_603936
  var valid_603937 = header.getOrDefault("X-Amz-Security-Token")
  valid_603937 = validateParameter(valid_603937, JString, required = false,
                                 default = nil)
  if valid_603937 != nil:
    section.add "X-Amz-Security-Token", valid_603937
  var valid_603938 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603938 = validateParameter(valid_603938, JString, required = false,
                                 default = nil)
  if valid_603938 != nil:
    section.add "X-Amz-Content-Sha256", valid_603938
  var valid_603939 = header.getOrDefault("X-Amz-Algorithm")
  valid_603939 = validateParameter(valid_603939, JString, required = false,
                                 default = nil)
  if valid_603939 != nil:
    section.add "X-Amz-Algorithm", valid_603939
  var valid_603940 = header.getOrDefault("X-Amz-Signature")
  valid_603940 = validateParameter(valid_603940, JString, required = false,
                                 default = nil)
  if valid_603940 != nil:
    section.add "X-Amz-Signature", valid_603940
  var valid_603941 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603941 = validateParameter(valid_603941, JString, required = false,
                                 default = nil)
  if valid_603941 != nil:
    section.add "X-Amz-SignedHeaders", valid_603941
  var valid_603942 = header.getOrDefault("X-Amz-Credential")
  valid_603942 = validateParameter(valid_603942, JString, required = false,
                                 default = nil)
  if valid_603942 != nil:
    section.add "X-Amz-Credential", valid_603942
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603943: Call_GetDescribeEnvironmentResources_603929;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns AWS resources for this environment.
  ## 
  let valid = call_603943.validator(path, query, header, formData, body)
  let scheme = call_603943.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603943.url(scheme.get, call_603943.host, call_603943.base,
                         call_603943.route, valid.getOrDefault("path"))
  result = hook(call_603943, url, valid)

proc call*(call_603944: Call_GetDescribeEnvironmentResources_603929;
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
  var query_603945 = newJObject()
  add(query_603945, "EnvironmentName", newJString(EnvironmentName))
  add(query_603945, "Action", newJString(Action))
  add(query_603945, "EnvironmentId", newJString(EnvironmentId))
  add(query_603945, "Version", newJString(Version))
  result = call_603944.call(nil, query_603945, nil, nil, nil)

var getDescribeEnvironmentResources* = Call_GetDescribeEnvironmentResources_603929(
    name: "getDescribeEnvironmentResources", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentResources",
    validator: validate_GetDescribeEnvironmentResources_603930, base: "/",
    url: url_GetDescribeEnvironmentResources_603931,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironments_603987 = ref object of OpenApiRestCall_602434
proc url_PostDescribeEnvironments_603989(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEnvironments_603988(path: JsonNode; query: JsonNode;
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
  var valid_603990 = query.getOrDefault("Action")
  valid_603990 = validateParameter(valid_603990, JString, required = true,
                                 default = newJString("DescribeEnvironments"))
  if valid_603990 != nil:
    section.add "Action", valid_603990
  var valid_603991 = query.getOrDefault("Version")
  valid_603991 = validateParameter(valid_603991, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603991 != nil:
    section.add "Version", valid_603991
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
  var valid_603992 = header.getOrDefault("X-Amz-Date")
  valid_603992 = validateParameter(valid_603992, JString, required = false,
                                 default = nil)
  if valid_603992 != nil:
    section.add "X-Amz-Date", valid_603992
  var valid_603993 = header.getOrDefault("X-Amz-Security-Token")
  valid_603993 = validateParameter(valid_603993, JString, required = false,
                                 default = nil)
  if valid_603993 != nil:
    section.add "X-Amz-Security-Token", valid_603993
  var valid_603994 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603994 = validateParameter(valid_603994, JString, required = false,
                                 default = nil)
  if valid_603994 != nil:
    section.add "X-Amz-Content-Sha256", valid_603994
  var valid_603995 = header.getOrDefault("X-Amz-Algorithm")
  valid_603995 = validateParameter(valid_603995, JString, required = false,
                                 default = nil)
  if valid_603995 != nil:
    section.add "X-Amz-Algorithm", valid_603995
  var valid_603996 = header.getOrDefault("X-Amz-Signature")
  valid_603996 = validateParameter(valid_603996, JString, required = false,
                                 default = nil)
  if valid_603996 != nil:
    section.add "X-Amz-Signature", valid_603996
  var valid_603997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603997 = validateParameter(valid_603997, JString, required = false,
                                 default = nil)
  if valid_603997 != nil:
    section.add "X-Amz-SignedHeaders", valid_603997
  var valid_603998 = header.getOrDefault("X-Amz-Credential")
  valid_603998 = validateParameter(valid_603998, JString, required = false,
                                 default = nil)
  if valid_603998 != nil:
    section.add "X-Amz-Credential", valid_603998
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
  var valid_603999 = formData.getOrDefault("NextToken")
  valid_603999 = validateParameter(valid_603999, JString, required = false,
                                 default = nil)
  if valid_603999 != nil:
    section.add "NextToken", valid_603999
  var valid_604000 = formData.getOrDefault("VersionLabel")
  valid_604000 = validateParameter(valid_604000, JString, required = false,
                                 default = nil)
  if valid_604000 != nil:
    section.add "VersionLabel", valid_604000
  var valid_604001 = formData.getOrDefault("EnvironmentNames")
  valid_604001 = validateParameter(valid_604001, JArray, required = false,
                                 default = nil)
  if valid_604001 != nil:
    section.add "EnvironmentNames", valid_604001
  var valid_604002 = formData.getOrDefault("IncludedDeletedBackTo")
  valid_604002 = validateParameter(valid_604002, JString, required = false,
                                 default = nil)
  if valid_604002 != nil:
    section.add "IncludedDeletedBackTo", valid_604002
  var valid_604003 = formData.getOrDefault("ApplicationName")
  valid_604003 = validateParameter(valid_604003, JString, required = false,
                                 default = nil)
  if valid_604003 != nil:
    section.add "ApplicationName", valid_604003
  var valid_604004 = formData.getOrDefault("EnvironmentIds")
  valid_604004 = validateParameter(valid_604004, JArray, required = false,
                                 default = nil)
  if valid_604004 != nil:
    section.add "EnvironmentIds", valid_604004
  var valid_604005 = formData.getOrDefault("IncludeDeleted")
  valid_604005 = validateParameter(valid_604005, JBool, required = false, default = nil)
  if valid_604005 != nil:
    section.add "IncludeDeleted", valid_604005
  var valid_604006 = formData.getOrDefault("MaxRecords")
  valid_604006 = validateParameter(valid_604006, JInt, required = false, default = nil)
  if valid_604006 != nil:
    section.add "MaxRecords", valid_604006
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604007: Call_PostDescribeEnvironments_603987; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns descriptions for existing environments.
  ## 
  let valid = call_604007.validator(path, query, header, formData, body)
  let scheme = call_604007.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604007.url(scheme.get, call_604007.host, call_604007.base,
                         call_604007.route, valid.getOrDefault("path"))
  result = hook(call_604007, url, valid)

proc call*(call_604008: Call_PostDescribeEnvironments_603987;
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
  var query_604009 = newJObject()
  var formData_604010 = newJObject()
  add(formData_604010, "NextToken", newJString(NextToken))
  add(formData_604010, "VersionLabel", newJString(VersionLabel))
  if EnvironmentNames != nil:
    formData_604010.add "EnvironmentNames", EnvironmentNames
  add(formData_604010, "IncludedDeletedBackTo", newJString(IncludedDeletedBackTo))
  add(query_604009, "Action", newJString(Action))
  add(formData_604010, "ApplicationName", newJString(ApplicationName))
  if EnvironmentIds != nil:
    formData_604010.add "EnvironmentIds", EnvironmentIds
  add(formData_604010, "IncludeDeleted", newJBool(IncludeDeleted))
  add(formData_604010, "MaxRecords", newJInt(MaxRecords))
  add(query_604009, "Version", newJString(Version))
  result = call_604008.call(nil, query_604009, nil, formData_604010, nil)

var postDescribeEnvironments* = Call_PostDescribeEnvironments_603987(
    name: "postDescribeEnvironments", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironments",
    validator: validate_PostDescribeEnvironments_603988, base: "/",
    url: url_PostDescribeEnvironments_603989, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironments_603964 = ref object of OpenApiRestCall_602434
proc url_GetDescribeEnvironments_603966(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEnvironments_603965(path: JsonNode; query: JsonNode;
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
  var valid_603967 = query.getOrDefault("VersionLabel")
  valid_603967 = validateParameter(valid_603967, JString, required = false,
                                 default = nil)
  if valid_603967 != nil:
    section.add "VersionLabel", valid_603967
  var valid_603968 = query.getOrDefault("MaxRecords")
  valid_603968 = validateParameter(valid_603968, JInt, required = false, default = nil)
  if valid_603968 != nil:
    section.add "MaxRecords", valid_603968
  var valid_603969 = query.getOrDefault("ApplicationName")
  valid_603969 = validateParameter(valid_603969, JString, required = false,
                                 default = nil)
  if valid_603969 != nil:
    section.add "ApplicationName", valid_603969
  var valid_603970 = query.getOrDefault("IncludeDeleted")
  valid_603970 = validateParameter(valid_603970, JBool, required = false, default = nil)
  if valid_603970 != nil:
    section.add "IncludeDeleted", valid_603970
  var valid_603971 = query.getOrDefault("NextToken")
  valid_603971 = validateParameter(valid_603971, JString, required = false,
                                 default = nil)
  if valid_603971 != nil:
    section.add "NextToken", valid_603971
  var valid_603972 = query.getOrDefault("EnvironmentIds")
  valid_603972 = validateParameter(valid_603972, JArray, required = false,
                                 default = nil)
  if valid_603972 != nil:
    section.add "EnvironmentIds", valid_603972
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603973 = query.getOrDefault("Action")
  valid_603973 = validateParameter(valid_603973, JString, required = true,
                                 default = newJString("DescribeEnvironments"))
  if valid_603973 != nil:
    section.add "Action", valid_603973
  var valid_603974 = query.getOrDefault("IncludedDeletedBackTo")
  valid_603974 = validateParameter(valid_603974, JString, required = false,
                                 default = nil)
  if valid_603974 != nil:
    section.add "IncludedDeletedBackTo", valid_603974
  var valid_603975 = query.getOrDefault("EnvironmentNames")
  valid_603975 = validateParameter(valid_603975, JArray, required = false,
                                 default = nil)
  if valid_603975 != nil:
    section.add "EnvironmentNames", valid_603975
  var valid_603976 = query.getOrDefault("Version")
  valid_603976 = validateParameter(valid_603976, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603976 != nil:
    section.add "Version", valid_603976
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
  var valid_603977 = header.getOrDefault("X-Amz-Date")
  valid_603977 = validateParameter(valid_603977, JString, required = false,
                                 default = nil)
  if valid_603977 != nil:
    section.add "X-Amz-Date", valid_603977
  var valid_603978 = header.getOrDefault("X-Amz-Security-Token")
  valid_603978 = validateParameter(valid_603978, JString, required = false,
                                 default = nil)
  if valid_603978 != nil:
    section.add "X-Amz-Security-Token", valid_603978
  var valid_603979 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603979 = validateParameter(valid_603979, JString, required = false,
                                 default = nil)
  if valid_603979 != nil:
    section.add "X-Amz-Content-Sha256", valid_603979
  var valid_603980 = header.getOrDefault("X-Amz-Algorithm")
  valid_603980 = validateParameter(valid_603980, JString, required = false,
                                 default = nil)
  if valid_603980 != nil:
    section.add "X-Amz-Algorithm", valid_603980
  var valid_603981 = header.getOrDefault("X-Amz-Signature")
  valid_603981 = validateParameter(valid_603981, JString, required = false,
                                 default = nil)
  if valid_603981 != nil:
    section.add "X-Amz-Signature", valid_603981
  var valid_603982 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603982 = validateParameter(valid_603982, JString, required = false,
                                 default = nil)
  if valid_603982 != nil:
    section.add "X-Amz-SignedHeaders", valid_603982
  var valid_603983 = header.getOrDefault("X-Amz-Credential")
  valid_603983 = validateParameter(valid_603983, JString, required = false,
                                 default = nil)
  if valid_603983 != nil:
    section.add "X-Amz-Credential", valid_603983
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603984: Call_GetDescribeEnvironments_603964; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns descriptions for existing environments.
  ## 
  let valid = call_603984.validator(path, query, header, formData, body)
  let scheme = call_603984.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603984.url(scheme.get, call_603984.host, call_603984.base,
                         call_603984.route, valid.getOrDefault("path"))
  result = hook(call_603984, url, valid)

proc call*(call_603985: Call_GetDescribeEnvironments_603964;
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
  var query_603986 = newJObject()
  add(query_603986, "VersionLabel", newJString(VersionLabel))
  add(query_603986, "MaxRecords", newJInt(MaxRecords))
  add(query_603986, "ApplicationName", newJString(ApplicationName))
  add(query_603986, "IncludeDeleted", newJBool(IncludeDeleted))
  add(query_603986, "NextToken", newJString(NextToken))
  if EnvironmentIds != nil:
    query_603986.add "EnvironmentIds", EnvironmentIds
  add(query_603986, "Action", newJString(Action))
  add(query_603986, "IncludedDeletedBackTo", newJString(IncludedDeletedBackTo))
  if EnvironmentNames != nil:
    query_603986.add "EnvironmentNames", EnvironmentNames
  add(query_603986, "Version", newJString(Version))
  result = call_603985.call(nil, query_603986, nil, nil, nil)

var getDescribeEnvironments* = Call_GetDescribeEnvironments_603964(
    name: "getDescribeEnvironments", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironments",
    validator: validate_GetDescribeEnvironments_603965, base: "/",
    url: url_GetDescribeEnvironments_603966, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_604038 = ref object of OpenApiRestCall_602434
proc url_PostDescribeEvents_604040(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEvents_604039(path: JsonNode; query: JsonNode;
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
  var valid_604041 = query.getOrDefault("Action")
  valid_604041 = validateParameter(valid_604041, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_604041 != nil:
    section.add "Action", valid_604041
  var valid_604042 = query.getOrDefault("Version")
  valid_604042 = validateParameter(valid_604042, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604042 != nil:
    section.add "Version", valid_604042
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
  var valid_604043 = header.getOrDefault("X-Amz-Date")
  valid_604043 = validateParameter(valid_604043, JString, required = false,
                                 default = nil)
  if valid_604043 != nil:
    section.add "X-Amz-Date", valid_604043
  var valid_604044 = header.getOrDefault("X-Amz-Security-Token")
  valid_604044 = validateParameter(valid_604044, JString, required = false,
                                 default = nil)
  if valid_604044 != nil:
    section.add "X-Amz-Security-Token", valid_604044
  var valid_604045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604045 = validateParameter(valid_604045, JString, required = false,
                                 default = nil)
  if valid_604045 != nil:
    section.add "X-Amz-Content-Sha256", valid_604045
  var valid_604046 = header.getOrDefault("X-Amz-Algorithm")
  valid_604046 = validateParameter(valid_604046, JString, required = false,
                                 default = nil)
  if valid_604046 != nil:
    section.add "X-Amz-Algorithm", valid_604046
  var valid_604047 = header.getOrDefault("X-Amz-Signature")
  valid_604047 = validateParameter(valid_604047, JString, required = false,
                                 default = nil)
  if valid_604047 != nil:
    section.add "X-Amz-Signature", valid_604047
  var valid_604048 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604048 = validateParameter(valid_604048, JString, required = false,
                                 default = nil)
  if valid_604048 != nil:
    section.add "X-Amz-SignedHeaders", valid_604048
  var valid_604049 = header.getOrDefault("X-Amz-Credential")
  valid_604049 = validateParameter(valid_604049, JString, required = false,
                                 default = nil)
  if valid_604049 != nil:
    section.add "X-Amz-Credential", valid_604049
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
  var valid_604050 = formData.getOrDefault("NextToken")
  valid_604050 = validateParameter(valid_604050, JString, required = false,
                                 default = nil)
  if valid_604050 != nil:
    section.add "NextToken", valid_604050
  var valid_604051 = formData.getOrDefault("VersionLabel")
  valid_604051 = validateParameter(valid_604051, JString, required = false,
                                 default = nil)
  if valid_604051 != nil:
    section.add "VersionLabel", valid_604051
  var valid_604052 = formData.getOrDefault("Severity")
  valid_604052 = validateParameter(valid_604052, JString, required = false,
                                 default = newJString("TRACE"))
  if valid_604052 != nil:
    section.add "Severity", valid_604052
  var valid_604053 = formData.getOrDefault("EnvironmentId")
  valid_604053 = validateParameter(valid_604053, JString, required = false,
                                 default = nil)
  if valid_604053 != nil:
    section.add "EnvironmentId", valid_604053
  var valid_604054 = formData.getOrDefault("EnvironmentName")
  valid_604054 = validateParameter(valid_604054, JString, required = false,
                                 default = nil)
  if valid_604054 != nil:
    section.add "EnvironmentName", valid_604054
  var valid_604055 = formData.getOrDefault("StartTime")
  valid_604055 = validateParameter(valid_604055, JString, required = false,
                                 default = nil)
  if valid_604055 != nil:
    section.add "StartTime", valid_604055
  var valid_604056 = formData.getOrDefault("ApplicationName")
  valid_604056 = validateParameter(valid_604056, JString, required = false,
                                 default = nil)
  if valid_604056 != nil:
    section.add "ApplicationName", valid_604056
  var valid_604057 = formData.getOrDefault("EndTime")
  valid_604057 = validateParameter(valid_604057, JString, required = false,
                                 default = nil)
  if valid_604057 != nil:
    section.add "EndTime", valid_604057
  var valid_604058 = formData.getOrDefault("PlatformArn")
  valid_604058 = validateParameter(valid_604058, JString, required = false,
                                 default = nil)
  if valid_604058 != nil:
    section.add "PlatformArn", valid_604058
  var valid_604059 = formData.getOrDefault("MaxRecords")
  valid_604059 = validateParameter(valid_604059, JInt, required = false, default = nil)
  if valid_604059 != nil:
    section.add "MaxRecords", valid_604059
  var valid_604060 = formData.getOrDefault("RequestId")
  valid_604060 = validateParameter(valid_604060, JString, required = false,
                                 default = nil)
  if valid_604060 != nil:
    section.add "RequestId", valid_604060
  var valid_604061 = formData.getOrDefault("TemplateName")
  valid_604061 = validateParameter(valid_604061, JString, required = false,
                                 default = nil)
  if valid_604061 != nil:
    section.add "TemplateName", valid_604061
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604062: Call_PostDescribeEvents_604038; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns list of event descriptions matching criteria up to the last 6 weeks.</p> <note> <p>This action returns the most recent 1,000 events from the specified <code>NextToken</code>.</p> </note>
  ## 
  let valid = call_604062.validator(path, query, header, formData, body)
  let scheme = call_604062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604062.url(scheme.get, call_604062.host, call_604062.base,
                         call_604062.route, valid.getOrDefault("path"))
  result = hook(call_604062, url, valid)

proc call*(call_604063: Call_PostDescribeEvents_604038; NextToken: string = "";
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
  var query_604064 = newJObject()
  var formData_604065 = newJObject()
  add(formData_604065, "NextToken", newJString(NextToken))
  add(formData_604065, "VersionLabel", newJString(VersionLabel))
  add(formData_604065, "Severity", newJString(Severity))
  add(formData_604065, "EnvironmentId", newJString(EnvironmentId))
  add(formData_604065, "EnvironmentName", newJString(EnvironmentName))
  add(formData_604065, "StartTime", newJString(StartTime))
  add(query_604064, "Action", newJString(Action))
  add(formData_604065, "ApplicationName", newJString(ApplicationName))
  add(formData_604065, "EndTime", newJString(EndTime))
  add(formData_604065, "PlatformArn", newJString(PlatformArn))
  add(formData_604065, "MaxRecords", newJInt(MaxRecords))
  add(formData_604065, "RequestId", newJString(RequestId))
  add(formData_604065, "TemplateName", newJString(TemplateName))
  add(query_604064, "Version", newJString(Version))
  result = call_604063.call(nil, query_604064, nil, formData_604065, nil)

var postDescribeEvents* = Call_PostDescribeEvents_604038(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_604039, base: "/",
    url: url_PostDescribeEvents_604040, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_604011 = ref object of OpenApiRestCall_602434
proc url_GetDescribeEvents_604013(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEvents_604012(path: JsonNode; query: JsonNode;
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
  var valid_604014 = query.getOrDefault("VersionLabel")
  valid_604014 = validateParameter(valid_604014, JString, required = false,
                                 default = nil)
  if valid_604014 != nil:
    section.add "VersionLabel", valid_604014
  var valid_604015 = query.getOrDefault("MaxRecords")
  valid_604015 = validateParameter(valid_604015, JInt, required = false, default = nil)
  if valid_604015 != nil:
    section.add "MaxRecords", valid_604015
  var valid_604016 = query.getOrDefault("ApplicationName")
  valid_604016 = validateParameter(valid_604016, JString, required = false,
                                 default = nil)
  if valid_604016 != nil:
    section.add "ApplicationName", valid_604016
  var valid_604017 = query.getOrDefault("StartTime")
  valid_604017 = validateParameter(valid_604017, JString, required = false,
                                 default = nil)
  if valid_604017 != nil:
    section.add "StartTime", valid_604017
  var valid_604018 = query.getOrDefault("PlatformArn")
  valid_604018 = validateParameter(valid_604018, JString, required = false,
                                 default = nil)
  if valid_604018 != nil:
    section.add "PlatformArn", valid_604018
  var valid_604019 = query.getOrDefault("NextToken")
  valid_604019 = validateParameter(valid_604019, JString, required = false,
                                 default = nil)
  if valid_604019 != nil:
    section.add "NextToken", valid_604019
  var valid_604020 = query.getOrDefault("EnvironmentName")
  valid_604020 = validateParameter(valid_604020, JString, required = false,
                                 default = nil)
  if valid_604020 != nil:
    section.add "EnvironmentName", valid_604020
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604021 = query.getOrDefault("Action")
  valid_604021 = validateParameter(valid_604021, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_604021 != nil:
    section.add "Action", valid_604021
  var valid_604022 = query.getOrDefault("EnvironmentId")
  valid_604022 = validateParameter(valid_604022, JString, required = false,
                                 default = nil)
  if valid_604022 != nil:
    section.add "EnvironmentId", valid_604022
  var valid_604023 = query.getOrDefault("TemplateName")
  valid_604023 = validateParameter(valid_604023, JString, required = false,
                                 default = nil)
  if valid_604023 != nil:
    section.add "TemplateName", valid_604023
  var valid_604024 = query.getOrDefault("Severity")
  valid_604024 = validateParameter(valid_604024, JString, required = false,
                                 default = newJString("TRACE"))
  if valid_604024 != nil:
    section.add "Severity", valid_604024
  var valid_604025 = query.getOrDefault("RequestId")
  valid_604025 = validateParameter(valid_604025, JString, required = false,
                                 default = nil)
  if valid_604025 != nil:
    section.add "RequestId", valid_604025
  var valid_604026 = query.getOrDefault("EndTime")
  valid_604026 = validateParameter(valid_604026, JString, required = false,
                                 default = nil)
  if valid_604026 != nil:
    section.add "EndTime", valid_604026
  var valid_604027 = query.getOrDefault("Version")
  valid_604027 = validateParameter(valid_604027, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604027 != nil:
    section.add "Version", valid_604027
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
  var valid_604028 = header.getOrDefault("X-Amz-Date")
  valid_604028 = validateParameter(valid_604028, JString, required = false,
                                 default = nil)
  if valid_604028 != nil:
    section.add "X-Amz-Date", valid_604028
  var valid_604029 = header.getOrDefault("X-Amz-Security-Token")
  valid_604029 = validateParameter(valid_604029, JString, required = false,
                                 default = nil)
  if valid_604029 != nil:
    section.add "X-Amz-Security-Token", valid_604029
  var valid_604030 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604030 = validateParameter(valid_604030, JString, required = false,
                                 default = nil)
  if valid_604030 != nil:
    section.add "X-Amz-Content-Sha256", valid_604030
  var valid_604031 = header.getOrDefault("X-Amz-Algorithm")
  valid_604031 = validateParameter(valid_604031, JString, required = false,
                                 default = nil)
  if valid_604031 != nil:
    section.add "X-Amz-Algorithm", valid_604031
  var valid_604032 = header.getOrDefault("X-Amz-Signature")
  valid_604032 = validateParameter(valid_604032, JString, required = false,
                                 default = nil)
  if valid_604032 != nil:
    section.add "X-Amz-Signature", valid_604032
  var valid_604033 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604033 = validateParameter(valid_604033, JString, required = false,
                                 default = nil)
  if valid_604033 != nil:
    section.add "X-Amz-SignedHeaders", valid_604033
  var valid_604034 = header.getOrDefault("X-Amz-Credential")
  valid_604034 = validateParameter(valid_604034, JString, required = false,
                                 default = nil)
  if valid_604034 != nil:
    section.add "X-Amz-Credential", valid_604034
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604035: Call_GetDescribeEvents_604011; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns list of event descriptions matching criteria up to the last 6 weeks.</p> <note> <p>This action returns the most recent 1,000 events from the specified <code>NextToken</code>.</p> </note>
  ## 
  let valid = call_604035.validator(path, query, header, formData, body)
  let scheme = call_604035.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604035.url(scheme.get, call_604035.host, call_604035.base,
                         call_604035.route, valid.getOrDefault("path"))
  result = hook(call_604035, url, valid)

proc call*(call_604036: Call_GetDescribeEvents_604011; VersionLabel: string = "";
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
  var query_604037 = newJObject()
  add(query_604037, "VersionLabel", newJString(VersionLabel))
  add(query_604037, "MaxRecords", newJInt(MaxRecords))
  add(query_604037, "ApplicationName", newJString(ApplicationName))
  add(query_604037, "StartTime", newJString(StartTime))
  add(query_604037, "PlatformArn", newJString(PlatformArn))
  add(query_604037, "NextToken", newJString(NextToken))
  add(query_604037, "EnvironmentName", newJString(EnvironmentName))
  add(query_604037, "Action", newJString(Action))
  add(query_604037, "EnvironmentId", newJString(EnvironmentId))
  add(query_604037, "TemplateName", newJString(TemplateName))
  add(query_604037, "Severity", newJString(Severity))
  add(query_604037, "RequestId", newJString(RequestId))
  add(query_604037, "EndTime", newJString(EndTime))
  add(query_604037, "Version", newJString(Version))
  result = call_604036.call(nil, query_604037, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_604011(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_604012,
    base: "/", url: url_GetDescribeEvents_604013,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeInstancesHealth_604085 = ref object of OpenApiRestCall_602434
proc url_PostDescribeInstancesHealth_604087(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeInstancesHealth_604086(path: JsonNode; query: JsonNode;
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
  var valid_604088 = query.getOrDefault("Action")
  valid_604088 = validateParameter(valid_604088, JString, required = true, default = newJString(
      "DescribeInstancesHealth"))
  if valid_604088 != nil:
    section.add "Action", valid_604088
  var valid_604089 = query.getOrDefault("Version")
  valid_604089 = validateParameter(valid_604089, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604089 != nil:
    section.add "Version", valid_604089
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
  var valid_604090 = header.getOrDefault("X-Amz-Date")
  valid_604090 = validateParameter(valid_604090, JString, required = false,
                                 default = nil)
  if valid_604090 != nil:
    section.add "X-Amz-Date", valid_604090
  var valid_604091 = header.getOrDefault("X-Amz-Security-Token")
  valid_604091 = validateParameter(valid_604091, JString, required = false,
                                 default = nil)
  if valid_604091 != nil:
    section.add "X-Amz-Security-Token", valid_604091
  var valid_604092 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604092 = validateParameter(valid_604092, JString, required = false,
                                 default = nil)
  if valid_604092 != nil:
    section.add "X-Amz-Content-Sha256", valid_604092
  var valid_604093 = header.getOrDefault("X-Amz-Algorithm")
  valid_604093 = validateParameter(valid_604093, JString, required = false,
                                 default = nil)
  if valid_604093 != nil:
    section.add "X-Amz-Algorithm", valid_604093
  var valid_604094 = header.getOrDefault("X-Amz-Signature")
  valid_604094 = validateParameter(valid_604094, JString, required = false,
                                 default = nil)
  if valid_604094 != nil:
    section.add "X-Amz-Signature", valid_604094
  var valid_604095 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604095 = validateParameter(valid_604095, JString, required = false,
                                 default = nil)
  if valid_604095 != nil:
    section.add "X-Amz-SignedHeaders", valid_604095
  var valid_604096 = header.getOrDefault("X-Amz-Credential")
  valid_604096 = validateParameter(valid_604096, JString, required = false,
                                 default = nil)
  if valid_604096 != nil:
    section.add "X-Amz-Credential", valid_604096
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
  var valid_604097 = formData.getOrDefault("NextToken")
  valid_604097 = validateParameter(valid_604097, JString, required = false,
                                 default = nil)
  if valid_604097 != nil:
    section.add "NextToken", valid_604097
  var valid_604098 = formData.getOrDefault("EnvironmentId")
  valid_604098 = validateParameter(valid_604098, JString, required = false,
                                 default = nil)
  if valid_604098 != nil:
    section.add "EnvironmentId", valid_604098
  var valid_604099 = formData.getOrDefault("EnvironmentName")
  valid_604099 = validateParameter(valid_604099, JString, required = false,
                                 default = nil)
  if valid_604099 != nil:
    section.add "EnvironmentName", valid_604099
  var valid_604100 = formData.getOrDefault("AttributeNames")
  valid_604100 = validateParameter(valid_604100, JArray, required = false,
                                 default = nil)
  if valid_604100 != nil:
    section.add "AttributeNames", valid_604100
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604101: Call_PostDescribeInstancesHealth_604085; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves detailed information about the health of instances in your AWS Elastic Beanstalk. This operation requires <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/health-enhanced.html">enhanced health reporting</a>.
  ## 
  let valid = call_604101.validator(path, query, header, formData, body)
  let scheme = call_604101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604101.url(scheme.get, call_604101.host, call_604101.base,
                         call_604101.route, valid.getOrDefault("path"))
  result = hook(call_604101, url, valid)

proc call*(call_604102: Call_PostDescribeInstancesHealth_604085;
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
  var query_604103 = newJObject()
  var formData_604104 = newJObject()
  add(formData_604104, "NextToken", newJString(NextToken))
  add(formData_604104, "EnvironmentId", newJString(EnvironmentId))
  add(formData_604104, "EnvironmentName", newJString(EnvironmentName))
  add(query_604103, "Action", newJString(Action))
  if AttributeNames != nil:
    formData_604104.add "AttributeNames", AttributeNames
  add(query_604103, "Version", newJString(Version))
  result = call_604102.call(nil, query_604103, nil, formData_604104, nil)

var postDescribeInstancesHealth* = Call_PostDescribeInstancesHealth_604085(
    name: "postDescribeInstancesHealth", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeInstancesHealth",
    validator: validate_PostDescribeInstancesHealth_604086, base: "/",
    url: url_PostDescribeInstancesHealth_604087,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeInstancesHealth_604066 = ref object of OpenApiRestCall_602434
proc url_GetDescribeInstancesHealth_604068(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeInstancesHealth_604067(path: JsonNode; query: JsonNode;
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
  var valid_604069 = query.getOrDefault("AttributeNames")
  valid_604069 = validateParameter(valid_604069, JArray, required = false,
                                 default = nil)
  if valid_604069 != nil:
    section.add "AttributeNames", valid_604069
  var valid_604070 = query.getOrDefault("NextToken")
  valid_604070 = validateParameter(valid_604070, JString, required = false,
                                 default = nil)
  if valid_604070 != nil:
    section.add "NextToken", valid_604070
  var valid_604071 = query.getOrDefault("EnvironmentName")
  valid_604071 = validateParameter(valid_604071, JString, required = false,
                                 default = nil)
  if valid_604071 != nil:
    section.add "EnvironmentName", valid_604071
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604072 = query.getOrDefault("Action")
  valid_604072 = validateParameter(valid_604072, JString, required = true, default = newJString(
      "DescribeInstancesHealth"))
  if valid_604072 != nil:
    section.add "Action", valid_604072
  var valid_604073 = query.getOrDefault("EnvironmentId")
  valid_604073 = validateParameter(valid_604073, JString, required = false,
                                 default = nil)
  if valid_604073 != nil:
    section.add "EnvironmentId", valid_604073
  var valid_604074 = query.getOrDefault("Version")
  valid_604074 = validateParameter(valid_604074, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604074 != nil:
    section.add "Version", valid_604074
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
  var valid_604075 = header.getOrDefault("X-Amz-Date")
  valid_604075 = validateParameter(valid_604075, JString, required = false,
                                 default = nil)
  if valid_604075 != nil:
    section.add "X-Amz-Date", valid_604075
  var valid_604076 = header.getOrDefault("X-Amz-Security-Token")
  valid_604076 = validateParameter(valid_604076, JString, required = false,
                                 default = nil)
  if valid_604076 != nil:
    section.add "X-Amz-Security-Token", valid_604076
  var valid_604077 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604077 = validateParameter(valid_604077, JString, required = false,
                                 default = nil)
  if valid_604077 != nil:
    section.add "X-Amz-Content-Sha256", valid_604077
  var valid_604078 = header.getOrDefault("X-Amz-Algorithm")
  valid_604078 = validateParameter(valid_604078, JString, required = false,
                                 default = nil)
  if valid_604078 != nil:
    section.add "X-Amz-Algorithm", valid_604078
  var valid_604079 = header.getOrDefault("X-Amz-Signature")
  valid_604079 = validateParameter(valid_604079, JString, required = false,
                                 default = nil)
  if valid_604079 != nil:
    section.add "X-Amz-Signature", valid_604079
  var valid_604080 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604080 = validateParameter(valid_604080, JString, required = false,
                                 default = nil)
  if valid_604080 != nil:
    section.add "X-Amz-SignedHeaders", valid_604080
  var valid_604081 = header.getOrDefault("X-Amz-Credential")
  valid_604081 = validateParameter(valid_604081, JString, required = false,
                                 default = nil)
  if valid_604081 != nil:
    section.add "X-Amz-Credential", valid_604081
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604082: Call_GetDescribeInstancesHealth_604066; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves detailed information about the health of instances in your AWS Elastic Beanstalk. This operation requires <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/health-enhanced.html">enhanced health reporting</a>.
  ## 
  let valid = call_604082.validator(path, query, header, formData, body)
  let scheme = call_604082.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604082.url(scheme.get, call_604082.host, call_604082.base,
                         call_604082.route, valid.getOrDefault("path"))
  result = hook(call_604082, url, valid)

proc call*(call_604083: Call_GetDescribeInstancesHealth_604066;
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
  var query_604084 = newJObject()
  if AttributeNames != nil:
    query_604084.add "AttributeNames", AttributeNames
  add(query_604084, "NextToken", newJString(NextToken))
  add(query_604084, "EnvironmentName", newJString(EnvironmentName))
  add(query_604084, "Action", newJString(Action))
  add(query_604084, "EnvironmentId", newJString(EnvironmentId))
  add(query_604084, "Version", newJString(Version))
  result = call_604083.call(nil, query_604084, nil, nil, nil)

var getDescribeInstancesHealth* = Call_GetDescribeInstancesHealth_604066(
    name: "getDescribeInstancesHealth", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeInstancesHealth",
    validator: validate_GetDescribeInstancesHealth_604067, base: "/",
    url: url_GetDescribeInstancesHealth_604068,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribePlatformVersion_604121 = ref object of OpenApiRestCall_602434
proc url_PostDescribePlatformVersion_604123(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribePlatformVersion_604122(path: JsonNode; query: JsonNode;
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
  var valid_604124 = query.getOrDefault("Action")
  valid_604124 = validateParameter(valid_604124, JString, required = true, default = newJString(
      "DescribePlatformVersion"))
  if valid_604124 != nil:
    section.add "Action", valid_604124
  var valid_604125 = query.getOrDefault("Version")
  valid_604125 = validateParameter(valid_604125, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604125 != nil:
    section.add "Version", valid_604125
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
  var valid_604126 = header.getOrDefault("X-Amz-Date")
  valid_604126 = validateParameter(valid_604126, JString, required = false,
                                 default = nil)
  if valid_604126 != nil:
    section.add "X-Amz-Date", valid_604126
  var valid_604127 = header.getOrDefault("X-Amz-Security-Token")
  valid_604127 = validateParameter(valid_604127, JString, required = false,
                                 default = nil)
  if valid_604127 != nil:
    section.add "X-Amz-Security-Token", valid_604127
  var valid_604128 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604128 = validateParameter(valid_604128, JString, required = false,
                                 default = nil)
  if valid_604128 != nil:
    section.add "X-Amz-Content-Sha256", valid_604128
  var valid_604129 = header.getOrDefault("X-Amz-Algorithm")
  valid_604129 = validateParameter(valid_604129, JString, required = false,
                                 default = nil)
  if valid_604129 != nil:
    section.add "X-Amz-Algorithm", valid_604129
  var valid_604130 = header.getOrDefault("X-Amz-Signature")
  valid_604130 = validateParameter(valid_604130, JString, required = false,
                                 default = nil)
  if valid_604130 != nil:
    section.add "X-Amz-Signature", valid_604130
  var valid_604131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604131 = validateParameter(valid_604131, JString, required = false,
                                 default = nil)
  if valid_604131 != nil:
    section.add "X-Amz-SignedHeaders", valid_604131
  var valid_604132 = header.getOrDefault("X-Amz-Credential")
  valid_604132 = validateParameter(valid_604132, JString, required = false,
                                 default = nil)
  if valid_604132 != nil:
    section.add "X-Amz-Credential", valid_604132
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformArn: JString
  ##              : The ARN of the version of the platform.
  section = newJObject()
  var valid_604133 = formData.getOrDefault("PlatformArn")
  valid_604133 = validateParameter(valid_604133, JString, required = false,
                                 default = nil)
  if valid_604133 != nil:
    section.add "PlatformArn", valid_604133
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604134: Call_PostDescribePlatformVersion_604121; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the version of the platform.
  ## 
  let valid = call_604134.validator(path, query, header, formData, body)
  let scheme = call_604134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604134.url(scheme.get, call_604134.host, call_604134.base,
                         call_604134.route, valid.getOrDefault("path"))
  result = hook(call_604134, url, valid)

proc call*(call_604135: Call_PostDescribePlatformVersion_604121;
          Action: string = "DescribePlatformVersion"; PlatformArn: string = "";
          Version: string = "2010-12-01"): Recallable =
  ## postDescribePlatformVersion
  ## Describes the version of the platform.
  ##   Action: string (required)
  ##   PlatformArn: string
  ##              : The ARN of the version of the platform.
  ##   Version: string (required)
  var query_604136 = newJObject()
  var formData_604137 = newJObject()
  add(query_604136, "Action", newJString(Action))
  add(formData_604137, "PlatformArn", newJString(PlatformArn))
  add(query_604136, "Version", newJString(Version))
  result = call_604135.call(nil, query_604136, nil, formData_604137, nil)

var postDescribePlatformVersion* = Call_PostDescribePlatformVersion_604121(
    name: "postDescribePlatformVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribePlatformVersion",
    validator: validate_PostDescribePlatformVersion_604122, base: "/",
    url: url_PostDescribePlatformVersion_604123,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribePlatformVersion_604105 = ref object of OpenApiRestCall_602434
proc url_GetDescribePlatformVersion_604107(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribePlatformVersion_604106(path: JsonNode; query: JsonNode;
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
  var valid_604108 = query.getOrDefault("PlatformArn")
  valid_604108 = validateParameter(valid_604108, JString, required = false,
                                 default = nil)
  if valid_604108 != nil:
    section.add "PlatformArn", valid_604108
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604109 = query.getOrDefault("Action")
  valid_604109 = validateParameter(valid_604109, JString, required = true, default = newJString(
      "DescribePlatformVersion"))
  if valid_604109 != nil:
    section.add "Action", valid_604109
  var valid_604110 = query.getOrDefault("Version")
  valid_604110 = validateParameter(valid_604110, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604110 != nil:
    section.add "Version", valid_604110
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
  var valid_604111 = header.getOrDefault("X-Amz-Date")
  valid_604111 = validateParameter(valid_604111, JString, required = false,
                                 default = nil)
  if valid_604111 != nil:
    section.add "X-Amz-Date", valid_604111
  var valid_604112 = header.getOrDefault("X-Amz-Security-Token")
  valid_604112 = validateParameter(valid_604112, JString, required = false,
                                 default = nil)
  if valid_604112 != nil:
    section.add "X-Amz-Security-Token", valid_604112
  var valid_604113 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604113 = validateParameter(valid_604113, JString, required = false,
                                 default = nil)
  if valid_604113 != nil:
    section.add "X-Amz-Content-Sha256", valid_604113
  var valid_604114 = header.getOrDefault("X-Amz-Algorithm")
  valid_604114 = validateParameter(valid_604114, JString, required = false,
                                 default = nil)
  if valid_604114 != nil:
    section.add "X-Amz-Algorithm", valid_604114
  var valid_604115 = header.getOrDefault("X-Amz-Signature")
  valid_604115 = validateParameter(valid_604115, JString, required = false,
                                 default = nil)
  if valid_604115 != nil:
    section.add "X-Amz-Signature", valid_604115
  var valid_604116 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604116 = validateParameter(valid_604116, JString, required = false,
                                 default = nil)
  if valid_604116 != nil:
    section.add "X-Amz-SignedHeaders", valid_604116
  var valid_604117 = header.getOrDefault("X-Amz-Credential")
  valid_604117 = validateParameter(valid_604117, JString, required = false,
                                 default = nil)
  if valid_604117 != nil:
    section.add "X-Amz-Credential", valid_604117
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604118: Call_GetDescribePlatformVersion_604105; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the version of the platform.
  ## 
  let valid = call_604118.validator(path, query, header, formData, body)
  let scheme = call_604118.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604118.url(scheme.get, call_604118.host, call_604118.base,
                         call_604118.route, valid.getOrDefault("path"))
  result = hook(call_604118, url, valid)

proc call*(call_604119: Call_GetDescribePlatformVersion_604105;
          PlatformArn: string = ""; Action: string = "DescribePlatformVersion";
          Version: string = "2010-12-01"): Recallable =
  ## getDescribePlatformVersion
  ## Describes the version of the platform.
  ##   PlatformArn: string
  ##              : The ARN of the version of the platform.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604120 = newJObject()
  add(query_604120, "PlatformArn", newJString(PlatformArn))
  add(query_604120, "Action", newJString(Action))
  add(query_604120, "Version", newJString(Version))
  result = call_604119.call(nil, query_604120, nil, nil, nil)

var getDescribePlatformVersion* = Call_GetDescribePlatformVersion_604105(
    name: "getDescribePlatformVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribePlatformVersion",
    validator: validate_GetDescribePlatformVersion_604106, base: "/",
    url: url_GetDescribePlatformVersion_604107,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListAvailableSolutionStacks_604153 = ref object of OpenApiRestCall_602434
proc url_PostListAvailableSolutionStacks_604155(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListAvailableSolutionStacks_604154(path: JsonNode;
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
  var valid_604156 = query.getOrDefault("Action")
  valid_604156 = validateParameter(valid_604156, JString, required = true, default = newJString(
      "ListAvailableSolutionStacks"))
  if valid_604156 != nil:
    section.add "Action", valid_604156
  var valid_604157 = query.getOrDefault("Version")
  valid_604157 = validateParameter(valid_604157, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604157 != nil:
    section.add "Version", valid_604157
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
  var valid_604158 = header.getOrDefault("X-Amz-Date")
  valid_604158 = validateParameter(valid_604158, JString, required = false,
                                 default = nil)
  if valid_604158 != nil:
    section.add "X-Amz-Date", valid_604158
  var valid_604159 = header.getOrDefault("X-Amz-Security-Token")
  valid_604159 = validateParameter(valid_604159, JString, required = false,
                                 default = nil)
  if valid_604159 != nil:
    section.add "X-Amz-Security-Token", valid_604159
  var valid_604160 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604160 = validateParameter(valid_604160, JString, required = false,
                                 default = nil)
  if valid_604160 != nil:
    section.add "X-Amz-Content-Sha256", valid_604160
  var valid_604161 = header.getOrDefault("X-Amz-Algorithm")
  valid_604161 = validateParameter(valid_604161, JString, required = false,
                                 default = nil)
  if valid_604161 != nil:
    section.add "X-Amz-Algorithm", valid_604161
  var valid_604162 = header.getOrDefault("X-Amz-Signature")
  valid_604162 = validateParameter(valid_604162, JString, required = false,
                                 default = nil)
  if valid_604162 != nil:
    section.add "X-Amz-Signature", valid_604162
  var valid_604163 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604163 = validateParameter(valid_604163, JString, required = false,
                                 default = nil)
  if valid_604163 != nil:
    section.add "X-Amz-SignedHeaders", valid_604163
  var valid_604164 = header.getOrDefault("X-Amz-Credential")
  valid_604164 = validateParameter(valid_604164, JString, required = false,
                                 default = nil)
  if valid_604164 != nil:
    section.add "X-Amz-Credential", valid_604164
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604165: Call_PostListAvailableSolutionStacks_604153;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ## 
  let valid = call_604165.validator(path, query, header, formData, body)
  let scheme = call_604165.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604165.url(scheme.get, call_604165.host, call_604165.base,
                         call_604165.route, valid.getOrDefault("path"))
  result = hook(call_604165, url, valid)

proc call*(call_604166: Call_PostListAvailableSolutionStacks_604153;
          Action: string = "ListAvailableSolutionStacks";
          Version: string = "2010-12-01"): Recallable =
  ## postListAvailableSolutionStacks
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604167 = newJObject()
  add(query_604167, "Action", newJString(Action))
  add(query_604167, "Version", newJString(Version))
  result = call_604166.call(nil, query_604167, nil, nil, nil)

var postListAvailableSolutionStacks* = Call_PostListAvailableSolutionStacks_604153(
    name: "postListAvailableSolutionStacks", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListAvailableSolutionStacks",
    validator: validate_PostListAvailableSolutionStacks_604154, base: "/",
    url: url_PostListAvailableSolutionStacks_604155,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListAvailableSolutionStacks_604138 = ref object of OpenApiRestCall_602434
proc url_GetListAvailableSolutionStacks_604140(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListAvailableSolutionStacks_604139(path: JsonNode;
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
  var valid_604141 = query.getOrDefault("Action")
  valid_604141 = validateParameter(valid_604141, JString, required = true, default = newJString(
      "ListAvailableSolutionStacks"))
  if valid_604141 != nil:
    section.add "Action", valid_604141
  var valid_604142 = query.getOrDefault("Version")
  valid_604142 = validateParameter(valid_604142, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604142 != nil:
    section.add "Version", valid_604142
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
  var valid_604143 = header.getOrDefault("X-Amz-Date")
  valid_604143 = validateParameter(valid_604143, JString, required = false,
                                 default = nil)
  if valid_604143 != nil:
    section.add "X-Amz-Date", valid_604143
  var valid_604144 = header.getOrDefault("X-Amz-Security-Token")
  valid_604144 = validateParameter(valid_604144, JString, required = false,
                                 default = nil)
  if valid_604144 != nil:
    section.add "X-Amz-Security-Token", valid_604144
  var valid_604145 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604145 = validateParameter(valid_604145, JString, required = false,
                                 default = nil)
  if valid_604145 != nil:
    section.add "X-Amz-Content-Sha256", valid_604145
  var valid_604146 = header.getOrDefault("X-Amz-Algorithm")
  valid_604146 = validateParameter(valid_604146, JString, required = false,
                                 default = nil)
  if valid_604146 != nil:
    section.add "X-Amz-Algorithm", valid_604146
  var valid_604147 = header.getOrDefault("X-Amz-Signature")
  valid_604147 = validateParameter(valid_604147, JString, required = false,
                                 default = nil)
  if valid_604147 != nil:
    section.add "X-Amz-Signature", valid_604147
  var valid_604148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604148 = validateParameter(valid_604148, JString, required = false,
                                 default = nil)
  if valid_604148 != nil:
    section.add "X-Amz-SignedHeaders", valid_604148
  var valid_604149 = header.getOrDefault("X-Amz-Credential")
  valid_604149 = validateParameter(valid_604149, JString, required = false,
                                 default = nil)
  if valid_604149 != nil:
    section.add "X-Amz-Credential", valid_604149
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604150: Call_GetListAvailableSolutionStacks_604138; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ## 
  let valid = call_604150.validator(path, query, header, formData, body)
  let scheme = call_604150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604150.url(scheme.get, call_604150.host, call_604150.base,
                         call_604150.route, valid.getOrDefault("path"))
  result = hook(call_604150, url, valid)

proc call*(call_604151: Call_GetListAvailableSolutionStacks_604138;
          Action: string = "ListAvailableSolutionStacks";
          Version: string = "2010-12-01"): Recallable =
  ## getListAvailableSolutionStacks
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604152 = newJObject()
  add(query_604152, "Action", newJString(Action))
  add(query_604152, "Version", newJString(Version))
  result = call_604151.call(nil, query_604152, nil, nil, nil)

var getListAvailableSolutionStacks* = Call_GetListAvailableSolutionStacks_604138(
    name: "getListAvailableSolutionStacks", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListAvailableSolutionStacks",
    validator: validate_GetListAvailableSolutionStacks_604139, base: "/",
    url: url_GetListAvailableSolutionStacks_604140,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListPlatformVersions_604186 = ref object of OpenApiRestCall_602434
proc url_PostListPlatformVersions_604188(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListPlatformVersions_604187(path: JsonNode; query: JsonNode;
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
  var valid_604189 = query.getOrDefault("Action")
  valid_604189 = validateParameter(valid_604189, JString, required = true,
                                 default = newJString("ListPlatformVersions"))
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
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : The starting index into the remaining list of platforms. Use the <code>NextToken</code> value from a previous <code>ListPlatformVersion</code> call.
  ##   Filters: JArray
  ##          : List only the platforms where the platform member value relates to one of the supplied values.
  ##   MaxRecords: JInt
  ##             : The maximum number of platform values returned in one call.
  section = newJObject()
  var valid_604198 = formData.getOrDefault("NextToken")
  valid_604198 = validateParameter(valid_604198, JString, required = false,
                                 default = nil)
  if valid_604198 != nil:
    section.add "NextToken", valid_604198
  var valid_604199 = formData.getOrDefault("Filters")
  valid_604199 = validateParameter(valid_604199, JArray, required = false,
                                 default = nil)
  if valid_604199 != nil:
    section.add "Filters", valid_604199
  var valid_604200 = formData.getOrDefault("MaxRecords")
  valid_604200 = validateParameter(valid_604200, JInt, required = false, default = nil)
  if valid_604200 != nil:
    section.add "MaxRecords", valid_604200
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604201: Call_PostListPlatformVersions_604186; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the available platforms.
  ## 
  let valid = call_604201.validator(path, query, header, formData, body)
  let scheme = call_604201.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604201.url(scheme.get, call_604201.host, call_604201.base,
                         call_604201.route, valid.getOrDefault("path"))
  result = hook(call_604201, url, valid)

proc call*(call_604202: Call_PostListPlatformVersions_604186;
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
  var query_604203 = newJObject()
  var formData_604204 = newJObject()
  add(formData_604204, "NextToken", newJString(NextToken))
  add(query_604203, "Action", newJString(Action))
  if Filters != nil:
    formData_604204.add "Filters", Filters
  add(formData_604204, "MaxRecords", newJInt(MaxRecords))
  add(query_604203, "Version", newJString(Version))
  result = call_604202.call(nil, query_604203, nil, formData_604204, nil)

var postListPlatformVersions* = Call_PostListPlatformVersions_604186(
    name: "postListPlatformVersions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListPlatformVersions",
    validator: validate_PostListPlatformVersions_604187, base: "/",
    url: url_PostListPlatformVersions_604188, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListPlatformVersions_604168 = ref object of OpenApiRestCall_602434
proc url_GetListPlatformVersions_604170(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListPlatformVersions_604169(path: JsonNode; query: JsonNode;
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
  var valid_604171 = query.getOrDefault("MaxRecords")
  valid_604171 = validateParameter(valid_604171, JInt, required = false, default = nil)
  if valid_604171 != nil:
    section.add "MaxRecords", valid_604171
  var valid_604172 = query.getOrDefault("Filters")
  valid_604172 = validateParameter(valid_604172, JArray, required = false,
                                 default = nil)
  if valid_604172 != nil:
    section.add "Filters", valid_604172
  var valid_604173 = query.getOrDefault("NextToken")
  valid_604173 = validateParameter(valid_604173, JString, required = false,
                                 default = nil)
  if valid_604173 != nil:
    section.add "NextToken", valid_604173
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604174 = query.getOrDefault("Action")
  valid_604174 = validateParameter(valid_604174, JString, required = true,
                                 default = newJString("ListPlatformVersions"))
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

proc call*(call_604183: Call_GetListPlatformVersions_604168; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the available platforms.
  ## 
  let valid = call_604183.validator(path, query, header, formData, body)
  let scheme = call_604183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604183.url(scheme.get, call_604183.host, call_604183.base,
                         call_604183.route, valid.getOrDefault("path"))
  result = hook(call_604183, url, valid)

proc call*(call_604184: Call_GetListPlatformVersions_604168; MaxRecords: int = 0;
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
  var query_604185 = newJObject()
  add(query_604185, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_604185.add "Filters", Filters
  add(query_604185, "NextToken", newJString(NextToken))
  add(query_604185, "Action", newJString(Action))
  add(query_604185, "Version", newJString(Version))
  result = call_604184.call(nil, query_604185, nil, nil, nil)

var getListPlatformVersions* = Call_GetListPlatformVersions_604168(
    name: "getListPlatformVersions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListPlatformVersions",
    validator: validate_GetListPlatformVersions_604169, base: "/",
    url: url_GetListPlatformVersions_604170, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_604221 = ref object of OpenApiRestCall_602434
proc url_PostListTagsForResource_604223(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListTagsForResource_604222(path: JsonNode; query: JsonNode;
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
  var valid_604224 = query.getOrDefault("Action")
  valid_604224 = validateParameter(valid_604224, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_604224 != nil:
    section.add "Action", valid_604224
  var valid_604225 = query.getOrDefault("Version")
  valid_604225 = validateParameter(valid_604225, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604225 != nil:
    section.add "Version", valid_604225
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
  var valid_604226 = header.getOrDefault("X-Amz-Date")
  valid_604226 = validateParameter(valid_604226, JString, required = false,
                                 default = nil)
  if valid_604226 != nil:
    section.add "X-Amz-Date", valid_604226
  var valid_604227 = header.getOrDefault("X-Amz-Security-Token")
  valid_604227 = validateParameter(valid_604227, JString, required = false,
                                 default = nil)
  if valid_604227 != nil:
    section.add "X-Amz-Security-Token", valid_604227
  var valid_604228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604228 = validateParameter(valid_604228, JString, required = false,
                                 default = nil)
  if valid_604228 != nil:
    section.add "X-Amz-Content-Sha256", valid_604228
  var valid_604229 = header.getOrDefault("X-Amz-Algorithm")
  valid_604229 = validateParameter(valid_604229, JString, required = false,
                                 default = nil)
  if valid_604229 != nil:
    section.add "X-Amz-Algorithm", valid_604229
  var valid_604230 = header.getOrDefault("X-Amz-Signature")
  valid_604230 = validateParameter(valid_604230, JString, required = false,
                                 default = nil)
  if valid_604230 != nil:
    section.add "X-Amz-Signature", valid_604230
  var valid_604231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604231 = validateParameter(valid_604231, JString, required = false,
                                 default = nil)
  if valid_604231 != nil:
    section.add "X-Amz-SignedHeaders", valid_604231
  var valid_604232 = header.getOrDefault("X-Amz-Credential")
  valid_604232 = validateParameter(valid_604232, JString, required = false,
                                 default = nil)
  if valid_604232 != nil:
    section.add "X-Amz-Credential", valid_604232
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArn: JString (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce for which a tag list is requested.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArn` field"
  var valid_604233 = formData.getOrDefault("ResourceArn")
  valid_604233 = validateParameter(valid_604233, JString, required = true,
                                 default = nil)
  if valid_604233 != nil:
    section.add "ResourceArn", valid_604233
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604234: Call_PostListTagsForResource_604221; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ## 
  let valid = call_604234.validator(path, query, header, formData, body)
  let scheme = call_604234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604234.url(scheme.get, call_604234.host, call_604234.base,
                         call_604234.route, valid.getOrDefault("path"))
  result = hook(call_604234, url, valid)

proc call*(call_604235: Call_PostListTagsForResource_604221; ResourceArn: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-12-01"): Recallable =
  ## postListTagsForResource
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ##   Action: string (required)
  ##   ResourceArn: string (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce for which a tag list is requested.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  ##   Version: string (required)
  var query_604236 = newJObject()
  var formData_604237 = newJObject()
  add(query_604236, "Action", newJString(Action))
  add(formData_604237, "ResourceArn", newJString(ResourceArn))
  add(query_604236, "Version", newJString(Version))
  result = call_604235.call(nil, query_604236, nil, formData_604237, nil)

var postListTagsForResource* = Call_PostListTagsForResource_604221(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_604222, base: "/",
    url: url_PostListTagsForResource_604223, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_604205 = ref object of OpenApiRestCall_602434
proc url_GetListTagsForResource_604207(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListTagsForResource_604206(path: JsonNode; query: JsonNode;
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
  var valid_604208 = query.getOrDefault("ResourceArn")
  valid_604208 = validateParameter(valid_604208, JString, required = true,
                                 default = nil)
  if valid_604208 != nil:
    section.add "ResourceArn", valid_604208
  var valid_604209 = query.getOrDefault("Action")
  valid_604209 = validateParameter(valid_604209, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_604209 != nil:
    section.add "Action", valid_604209
  var valid_604210 = query.getOrDefault("Version")
  valid_604210 = validateParameter(valid_604210, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604210 != nil:
    section.add "Version", valid_604210
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
  var valid_604211 = header.getOrDefault("X-Amz-Date")
  valid_604211 = validateParameter(valid_604211, JString, required = false,
                                 default = nil)
  if valid_604211 != nil:
    section.add "X-Amz-Date", valid_604211
  var valid_604212 = header.getOrDefault("X-Amz-Security-Token")
  valid_604212 = validateParameter(valid_604212, JString, required = false,
                                 default = nil)
  if valid_604212 != nil:
    section.add "X-Amz-Security-Token", valid_604212
  var valid_604213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604213 = validateParameter(valid_604213, JString, required = false,
                                 default = nil)
  if valid_604213 != nil:
    section.add "X-Amz-Content-Sha256", valid_604213
  var valid_604214 = header.getOrDefault("X-Amz-Algorithm")
  valid_604214 = validateParameter(valid_604214, JString, required = false,
                                 default = nil)
  if valid_604214 != nil:
    section.add "X-Amz-Algorithm", valid_604214
  var valid_604215 = header.getOrDefault("X-Amz-Signature")
  valid_604215 = validateParameter(valid_604215, JString, required = false,
                                 default = nil)
  if valid_604215 != nil:
    section.add "X-Amz-Signature", valid_604215
  var valid_604216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604216 = validateParameter(valid_604216, JString, required = false,
                                 default = nil)
  if valid_604216 != nil:
    section.add "X-Amz-SignedHeaders", valid_604216
  var valid_604217 = header.getOrDefault("X-Amz-Credential")
  valid_604217 = validateParameter(valid_604217, JString, required = false,
                                 default = nil)
  if valid_604217 != nil:
    section.add "X-Amz-Credential", valid_604217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604218: Call_GetListTagsForResource_604205; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ## 
  let valid = call_604218.validator(path, query, header, formData, body)
  let scheme = call_604218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604218.url(scheme.get, call_604218.host, call_604218.base,
                         call_604218.route, valid.getOrDefault("path"))
  result = hook(call_604218, url, valid)

proc call*(call_604219: Call_GetListTagsForResource_604205; ResourceArn: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-12-01"): Recallable =
  ## getListTagsForResource
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ##   ResourceArn: string (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce for which a tag list is requested.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604220 = newJObject()
  add(query_604220, "ResourceArn", newJString(ResourceArn))
  add(query_604220, "Action", newJString(Action))
  add(query_604220, "Version", newJString(Version))
  result = call_604219.call(nil, query_604220, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_604205(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_604206, base: "/",
    url: url_GetListTagsForResource_604207, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebuildEnvironment_604255 = ref object of OpenApiRestCall_602434
proc url_PostRebuildEnvironment_604257(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRebuildEnvironment_604256(path: JsonNode; query: JsonNode;
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
  var valid_604258 = query.getOrDefault("Action")
  valid_604258 = validateParameter(valid_604258, JString, required = true,
                                 default = newJString("RebuildEnvironment"))
  if valid_604258 != nil:
    section.add "Action", valid_604258
  var valid_604259 = query.getOrDefault("Version")
  valid_604259 = validateParameter(valid_604259, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604259 != nil:
    section.add "Version", valid_604259
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
  var valid_604260 = header.getOrDefault("X-Amz-Date")
  valid_604260 = validateParameter(valid_604260, JString, required = false,
                                 default = nil)
  if valid_604260 != nil:
    section.add "X-Amz-Date", valid_604260
  var valid_604261 = header.getOrDefault("X-Amz-Security-Token")
  valid_604261 = validateParameter(valid_604261, JString, required = false,
                                 default = nil)
  if valid_604261 != nil:
    section.add "X-Amz-Security-Token", valid_604261
  var valid_604262 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604262 = validateParameter(valid_604262, JString, required = false,
                                 default = nil)
  if valid_604262 != nil:
    section.add "X-Amz-Content-Sha256", valid_604262
  var valid_604263 = header.getOrDefault("X-Amz-Algorithm")
  valid_604263 = validateParameter(valid_604263, JString, required = false,
                                 default = nil)
  if valid_604263 != nil:
    section.add "X-Amz-Algorithm", valid_604263
  var valid_604264 = header.getOrDefault("X-Amz-Signature")
  valid_604264 = validateParameter(valid_604264, JString, required = false,
                                 default = nil)
  if valid_604264 != nil:
    section.add "X-Amz-Signature", valid_604264
  var valid_604265 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604265 = validateParameter(valid_604265, JString, required = false,
                                 default = nil)
  if valid_604265 != nil:
    section.add "X-Amz-SignedHeaders", valid_604265
  var valid_604266 = header.getOrDefault("X-Amz-Credential")
  valid_604266 = validateParameter(valid_604266, JString, required = false,
                                 default = nil)
  if valid_604266 != nil:
    section.add "X-Amz-Credential", valid_604266
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to rebuild.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to rebuild.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_604267 = formData.getOrDefault("EnvironmentId")
  valid_604267 = validateParameter(valid_604267, JString, required = false,
                                 default = nil)
  if valid_604267 != nil:
    section.add "EnvironmentId", valid_604267
  var valid_604268 = formData.getOrDefault("EnvironmentName")
  valid_604268 = validateParameter(valid_604268, JString, required = false,
                                 default = nil)
  if valid_604268 != nil:
    section.add "EnvironmentName", valid_604268
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604269: Call_PostRebuildEnvironment_604255; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes and recreates all of the AWS resources (for example: the Auto Scaling group, load balancer, etc.) for a specified environment and forces a restart.
  ## 
  let valid = call_604269.validator(path, query, header, formData, body)
  let scheme = call_604269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604269.url(scheme.get, call_604269.host, call_604269.base,
                         call_604269.route, valid.getOrDefault("path"))
  result = hook(call_604269, url, valid)

proc call*(call_604270: Call_PostRebuildEnvironment_604255;
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
  var query_604271 = newJObject()
  var formData_604272 = newJObject()
  add(formData_604272, "EnvironmentId", newJString(EnvironmentId))
  add(formData_604272, "EnvironmentName", newJString(EnvironmentName))
  add(query_604271, "Action", newJString(Action))
  add(query_604271, "Version", newJString(Version))
  result = call_604270.call(nil, query_604271, nil, formData_604272, nil)

var postRebuildEnvironment* = Call_PostRebuildEnvironment_604255(
    name: "postRebuildEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RebuildEnvironment",
    validator: validate_PostRebuildEnvironment_604256, base: "/",
    url: url_PostRebuildEnvironment_604257, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebuildEnvironment_604238 = ref object of OpenApiRestCall_602434
proc url_GetRebuildEnvironment_604240(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRebuildEnvironment_604239(path: JsonNode; query: JsonNode;
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
  var valid_604241 = query.getOrDefault("EnvironmentName")
  valid_604241 = validateParameter(valid_604241, JString, required = false,
                                 default = nil)
  if valid_604241 != nil:
    section.add "EnvironmentName", valid_604241
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604242 = query.getOrDefault("Action")
  valid_604242 = validateParameter(valid_604242, JString, required = true,
                                 default = newJString("RebuildEnvironment"))
  if valid_604242 != nil:
    section.add "Action", valid_604242
  var valid_604243 = query.getOrDefault("EnvironmentId")
  valid_604243 = validateParameter(valid_604243, JString, required = false,
                                 default = nil)
  if valid_604243 != nil:
    section.add "EnvironmentId", valid_604243
  var valid_604244 = query.getOrDefault("Version")
  valid_604244 = validateParameter(valid_604244, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604244 != nil:
    section.add "Version", valid_604244
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
  var valid_604245 = header.getOrDefault("X-Amz-Date")
  valid_604245 = validateParameter(valid_604245, JString, required = false,
                                 default = nil)
  if valid_604245 != nil:
    section.add "X-Amz-Date", valid_604245
  var valid_604246 = header.getOrDefault("X-Amz-Security-Token")
  valid_604246 = validateParameter(valid_604246, JString, required = false,
                                 default = nil)
  if valid_604246 != nil:
    section.add "X-Amz-Security-Token", valid_604246
  var valid_604247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604247 = validateParameter(valid_604247, JString, required = false,
                                 default = nil)
  if valid_604247 != nil:
    section.add "X-Amz-Content-Sha256", valid_604247
  var valid_604248 = header.getOrDefault("X-Amz-Algorithm")
  valid_604248 = validateParameter(valid_604248, JString, required = false,
                                 default = nil)
  if valid_604248 != nil:
    section.add "X-Amz-Algorithm", valid_604248
  var valid_604249 = header.getOrDefault("X-Amz-Signature")
  valid_604249 = validateParameter(valid_604249, JString, required = false,
                                 default = nil)
  if valid_604249 != nil:
    section.add "X-Amz-Signature", valid_604249
  var valid_604250 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604250 = validateParameter(valid_604250, JString, required = false,
                                 default = nil)
  if valid_604250 != nil:
    section.add "X-Amz-SignedHeaders", valid_604250
  var valid_604251 = header.getOrDefault("X-Amz-Credential")
  valid_604251 = validateParameter(valid_604251, JString, required = false,
                                 default = nil)
  if valid_604251 != nil:
    section.add "X-Amz-Credential", valid_604251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604252: Call_GetRebuildEnvironment_604238; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes and recreates all of the AWS resources (for example: the Auto Scaling group, load balancer, etc.) for a specified environment and forces a restart.
  ## 
  let valid = call_604252.validator(path, query, header, formData, body)
  let scheme = call_604252.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604252.url(scheme.get, call_604252.host, call_604252.base,
                         call_604252.route, valid.getOrDefault("path"))
  result = hook(call_604252, url, valid)

proc call*(call_604253: Call_GetRebuildEnvironment_604238;
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
  var query_604254 = newJObject()
  add(query_604254, "EnvironmentName", newJString(EnvironmentName))
  add(query_604254, "Action", newJString(Action))
  add(query_604254, "EnvironmentId", newJString(EnvironmentId))
  add(query_604254, "Version", newJString(Version))
  result = call_604253.call(nil, query_604254, nil, nil, nil)

var getRebuildEnvironment* = Call_GetRebuildEnvironment_604238(
    name: "getRebuildEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RebuildEnvironment",
    validator: validate_GetRebuildEnvironment_604239, base: "/",
    url: url_GetRebuildEnvironment_604240, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRequestEnvironmentInfo_604291 = ref object of OpenApiRestCall_602434
proc url_PostRequestEnvironmentInfo_604293(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRequestEnvironmentInfo_604292(path: JsonNode; query: JsonNode;
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
  var valid_604294 = query.getOrDefault("Action")
  valid_604294 = validateParameter(valid_604294, JString, required = true,
                                 default = newJString("RequestEnvironmentInfo"))
  if valid_604294 != nil:
    section.add "Action", valid_604294
  var valid_604295 = query.getOrDefault("Version")
  valid_604295 = validateParameter(valid_604295, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604295 != nil:
    section.add "Version", valid_604295
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
  var valid_604296 = header.getOrDefault("X-Amz-Date")
  valid_604296 = validateParameter(valid_604296, JString, required = false,
                                 default = nil)
  if valid_604296 != nil:
    section.add "X-Amz-Date", valid_604296
  var valid_604297 = header.getOrDefault("X-Amz-Security-Token")
  valid_604297 = validateParameter(valid_604297, JString, required = false,
                                 default = nil)
  if valid_604297 != nil:
    section.add "X-Amz-Security-Token", valid_604297
  var valid_604298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604298 = validateParameter(valid_604298, JString, required = false,
                                 default = nil)
  if valid_604298 != nil:
    section.add "X-Amz-Content-Sha256", valid_604298
  var valid_604299 = header.getOrDefault("X-Amz-Algorithm")
  valid_604299 = validateParameter(valid_604299, JString, required = false,
                                 default = nil)
  if valid_604299 != nil:
    section.add "X-Amz-Algorithm", valid_604299
  var valid_604300 = header.getOrDefault("X-Amz-Signature")
  valid_604300 = validateParameter(valid_604300, JString, required = false,
                                 default = nil)
  if valid_604300 != nil:
    section.add "X-Amz-Signature", valid_604300
  var valid_604301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604301 = validateParameter(valid_604301, JString, required = false,
                                 default = nil)
  if valid_604301 != nil:
    section.add "X-Amz-SignedHeaders", valid_604301
  var valid_604302 = header.getOrDefault("X-Amz-Credential")
  valid_604302 = validateParameter(valid_604302, JString, required = false,
                                 default = nil)
  if valid_604302 != nil:
    section.add "X-Amz-Credential", valid_604302
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
  var valid_604303 = formData.getOrDefault("InfoType")
  valid_604303 = validateParameter(valid_604303, JString, required = true,
                                 default = newJString("tail"))
  if valid_604303 != nil:
    section.add "InfoType", valid_604303
  var valid_604304 = formData.getOrDefault("EnvironmentId")
  valid_604304 = validateParameter(valid_604304, JString, required = false,
                                 default = nil)
  if valid_604304 != nil:
    section.add "EnvironmentId", valid_604304
  var valid_604305 = formData.getOrDefault("EnvironmentName")
  valid_604305 = validateParameter(valid_604305, JString, required = false,
                                 default = nil)
  if valid_604305 != nil:
    section.add "EnvironmentName", valid_604305
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604306: Call_PostRequestEnvironmentInfo_604291; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a request to compile the specified type of information of the deployed environment.</p> <p> Setting the <code>InfoType</code> to <code>tail</code> compiles the last lines from the application server log files of every Amazon EC2 instance in your environment. </p> <p> Setting the <code>InfoType</code> to <code>bundle</code> compresses the application server log files for every Amazon EC2 instance into a <code>.zip</code> file. Legacy and .NET containers do not support bundle logs. </p> <p> Use <a>RetrieveEnvironmentInfo</a> to obtain the set of logs. </p> <p>Related Topics</p> <ul> <li> <p> <a>RetrieveEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_604306.validator(path, query, header, formData, body)
  let scheme = call_604306.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604306.url(scheme.get, call_604306.host, call_604306.base,
                         call_604306.route, valid.getOrDefault("path"))
  result = hook(call_604306, url, valid)

proc call*(call_604307: Call_PostRequestEnvironmentInfo_604291;
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
  var query_604308 = newJObject()
  var formData_604309 = newJObject()
  add(formData_604309, "InfoType", newJString(InfoType))
  add(formData_604309, "EnvironmentId", newJString(EnvironmentId))
  add(formData_604309, "EnvironmentName", newJString(EnvironmentName))
  add(query_604308, "Action", newJString(Action))
  add(query_604308, "Version", newJString(Version))
  result = call_604307.call(nil, query_604308, nil, formData_604309, nil)

var postRequestEnvironmentInfo* = Call_PostRequestEnvironmentInfo_604291(
    name: "postRequestEnvironmentInfo", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RequestEnvironmentInfo",
    validator: validate_PostRequestEnvironmentInfo_604292, base: "/",
    url: url_PostRequestEnvironmentInfo_604293,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRequestEnvironmentInfo_604273 = ref object of OpenApiRestCall_602434
proc url_GetRequestEnvironmentInfo_604275(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRequestEnvironmentInfo_604274(path: JsonNode; query: JsonNode;
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
  var valid_604276 = query.getOrDefault("InfoType")
  valid_604276 = validateParameter(valid_604276, JString, required = true,
                                 default = newJString("tail"))
  if valid_604276 != nil:
    section.add "InfoType", valid_604276
  var valid_604277 = query.getOrDefault("EnvironmentName")
  valid_604277 = validateParameter(valid_604277, JString, required = false,
                                 default = nil)
  if valid_604277 != nil:
    section.add "EnvironmentName", valid_604277
  var valid_604278 = query.getOrDefault("Action")
  valid_604278 = validateParameter(valid_604278, JString, required = true,
                                 default = newJString("RequestEnvironmentInfo"))
  if valid_604278 != nil:
    section.add "Action", valid_604278
  var valid_604279 = query.getOrDefault("EnvironmentId")
  valid_604279 = validateParameter(valid_604279, JString, required = false,
                                 default = nil)
  if valid_604279 != nil:
    section.add "EnvironmentId", valid_604279
  var valid_604280 = query.getOrDefault("Version")
  valid_604280 = validateParameter(valid_604280, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604280 != nil:
    section.add "Version", valid_604280
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
  var valid_604281 = header.getOrDefault("X-Amz-Date")
  valid_604281 = validateParameter(valid_604281, JString, required = false,
                                 default = nil)
  if valid_604281 != nil:
    section.add "X-Amz-Date", valid_604281
  var valid_604282 = header.getOrDefault("X-Amz-Security-Token")
  valid_604282 = validateParameter(valid_604282, JString, required = false,
                                 default = nil)
  if valid_604282 != nil:
    section.add "X-Amz-Security-Token", valid_604282
  var valid_604283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604283 = validateParameter(valid_604283, JString, required = false,
                                 default = nil)
  if valid_604283 != nil:
    section.add "X-Amz-Content-Sha256", valid_604283
  var valid_604284 = header.getOrDefault("X-Amz-Algorithm")
  valid_604284 = validateParameter(valid_604284, JString, required = false,
                                 default = nil)
  if valid_604284 != nil:
    section.add "X-Amz-Algorithm", valid_604284
  var valid_604285 = header.getOrDefault("X-Amz-Signature")
  valid_604285 = validateParameter(valid_604285, JString, required = false,
                                 default = nil)
  if valid_604285 != nil:
    section.add "X-Amz-Signature", valid_604285
  var valid_604286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604286 = validateParameter(valid_604286, JString, required = false,
                                 default = nil)
  if valid_604286 != nil:
    section.add "X-Amz-SignedHeaders", valid_604286
  var valid_604287 = header.getOrDefault("X-Amz-Credential")
  valid_604287 = validateParameter(valid_604287, JString, required = false,
                                 default = nil)
  if valid_604287 != nil:
    section.add "X-Amz-Credential", valid_604287
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604288: Call_GetRequestEnvironmentInfo_604273; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a request to compile the specified type of information of the deployed environment.</p> <p> Setting the <code>InfoType</code> to <code>tail</code> compiles the last lines from the application server log files of every Amazon EC2 instance in your environment. </p> <p> Setting the <code>InfoType</code> to <code>bundle</code> compresses the application server log files for every Amazon EC2 instance into a <code>.zip</code> file. Legacy and .NET containers do not support bundle logs. </p> <p> Use <a>RetrieveEnvironmentInfo</a> to obtain the set of logs. </p> <p>Related Topics</p> <ul> <li> <p> <a>RetrieveEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_604288.validator(path, query, header, formData, body)
  let scheme = call_604288.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604288.url(scheme.get, call_604288.host, call_604288.base,
                         call_604288.route, valid.getOrDefault("path"))
  result = hook(call_604288, url, valid)

proc call*(call_604289: Call_GetRequestEnvironmentInfo_604273;
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
  var query_604290 = newJObject()
  add(query_604290, "InfoType", newJString(InfoType))
  add(query_604290, "EnvironmentName", newJString(EnvironmentName))
  add(query_604290, "Action", newJString(Action))
  add(query_604290, "EnvironmentId", newJString(EnvironmentId))
  add(query_604290, "Version", newJString(Version))
  result = call_604289.call(nil, query_604290, nil, nil, nil)

var getRequestEnvironmentInfo* = Call_GetRequestEnvironmentInfo_604273(
    name: "getRequestEnvironmentInfo", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RequestEnvironmentInfo",
    validator: validate_GetRequestEnvironmentInfo_604274, base: "/",
    url: url_GetRequestEnvironmentInfo_604275,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestartAppServer_604327 = ref object of OpenApiRestCall_602434
proc url_PostRestartAppServer_604329(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRestartAppServer_604328(path: JsonNode; query: JsonNode;
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
  var valid_604330 = query.getOrDefault("Action")
  valid_604330 = validateParameter(valid_604330, JString, required = true,
                                 default = newJString("RestartAppServer"))
  if valid_604330 != nil:
    section.add "Action", valid_604330
  var valid_604331 = query.getOrDefault("Version")
  valid_604331 = validateParameter(valid_604331, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604331 != nil:
    section.add "Version", valid_604331
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
  var valid_604332 = header.getOrDefault("X-Amz-Date")
  valid_604332 = validateParameter(valid_604332, JString, required = false,
                                 default = nil)
  if valid_604332 != nil:
    section.add "X-Amz-Date", valid_604332
  var valid_604333 = header.getOrDefault("X-Amz-Security-Token")
  valid_604333 = validateParameter(valid_604333, JString, required = false,
                                 default = nil)
  if valid_604333 != nil:
    section.add "X-Amz-Security-Token", valid_604333
  var valid_604334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604334 = validateParameter(valid_604334, JString, required = false,
                                 default = nil)
  if valid_604334 != nil:
    section.add "X-Amz-Content-Sha256", valid_604334
  var valid_604335 = header.getOrDefault("X-Amz-Algorithm")
  valid_604335 = validateParameter(valid_604335, JString, required = false,
                                 default = nil)
  if valid_604335 != nil:
    section.add "X-Amz-Algorithm", valid_604335
  var valid_604336 = header.getOrDefault("X-Amz-Signature")
  valid_604336 = validateParameter(valid_604336, JString, required = false,
                                 default = nil)
  if valid_604336 != nil:
    section.add "X-Amz-Signature", valid_604336
  var valid_604337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604337 = validateParameter(valid_604337, JString, required = false,
                                 default = nil)
  if valid_604337 != nil:
    section.add "X-Amz-SignedHeaders", valid_604337
  var valid_604338 = header.getOrDefault("X-Amz-Credential")
  valid_604338 = validateParameter(valid_604338, JString, required = false,
                                 default = nil)
  if valid_604338 != nil:
    section.add "X-Amz-Credential", valid_604338
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to restart the server for.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to restart the server for.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_604339 = formData.getOrDefault("EnvironmentId")
  valid_604339 = validateParameter(valid_604339, JString, required = false,
                                 default = nil)
  if valid_604339 != nil:
    section.add "EnvironmentId", valid_604339
  var valid_604340 = formData.getOrDefault("EnvironmentName")
  valid_604340 = validateParameter(valid_604340, JString, required = false,
                                 default = nil)
  if valid_604340 != nil:
    section.add "EnvironmentName", valid_604340
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604341: Call_PostRestartAppServer_604327; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Causes the environment to restart the application container server running on each Amazon EC2 instance.
  ## 
  let valid = call_604341.validator(path, query, header, formData, body)
  let scheme = call_604341.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604341.url(scheme.get, call_604341.host, call_604341.base,
                         call_604341.route, valid.getOrDefault("path"))
  result = hook(call_604341, url, valid)

proc call*(call_604342: Call_PostRestartAppServer_604327;
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
  var query_604343 = newJObject()
  var formData_604344 = newJObject()
  add(formData_604344, "EnvironmentId", newJString(EnvironmentId))
  add(formData_604344, "EnvironmentName", newJString(EnvironmentName))
  add(query_604343, "Action", newJString(Action))
  add(query_604343, "Version", newJString(Version))
  result = call_604342.call(nil, query_604343, nil, formData_604344, nil)

var postRestartAppServer* = Call_PostRestartAppServer_604327(
    name: "postRestartAppServer", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RestartAppServer",
    validator: validate_PostRestartAppServer_604328, base: "/",
    url: url_PostRestartAppServer_604329, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestartAppServer_604310 = ref object of OpenApiRestCall_602434
proc url_GetRestartAppServer_604312(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRestartAppServer_604311(path: JsonNode; query: JsonNode;
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
  var valid_604313 = query.getOrDefault("EnvironmentName")
  valid_604313 = validateParameter(valid_604313, JString, required = false,
                                 default = nil)
  if valid_604313 != nil:
    section.add "EnvironmentName", valid_604313
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604314 = query.getOrDefault("Action")
  valid_604314 = validateParameter(valid_604314, JString, required = true,
                                 default = newJString("RestartAppServer"))
  if valid_604314 != nil:
    section.add "Action", valid_604314
  var valid_604315 = query.getOrDefault("EnvironmentId")
  valid_604315 = validateParameter(valid_604315, JString, required = false,
                                 default = nil)
  if valid_604315 != nil:
    section.add "EnvironmentId", valid_604315
  var valid_604316 = query.getOrDefault("Version")
  valid_604316 = validateParameter(valid_604316, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604316 != nil:
    section.add "Version", valid_604316
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
  var valid_604317 = header.getOrDefault("X-Amz-Date")
  valid_604317 = validateParameter(valid_604317, JString, required = false,
                                 default = nil)
  if valid_604317 != nil:
    section.add "X-Amz-Date", valid_604317
  var valid_604318 = header.getOrDefault("X-Amz-Security-Token")
  valid_604318 = validateParameter(valid_604318, JString, required = false,
                                 default = nil)
  if valid_604318 != nil:
    section.add "X-Amz-Security-Token", valid_604318
  var valid_604319 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604319 = validateParameter(valid_604319, JString, required = false,
                                 default = nil)
  if valid_604319 != nil:
    section.add "X-Amz-Content-Sha256", valid_604319
  var valid_604320 = header.getOrDefault("X-Amz-Algorithm")
  valid_604320 = validateParameter(valid_604320, JString, required = false,
                                 default = nil)
  if valid_604320 != nil:
    section.add "X-Amz-Algorithm", valid_604320
  var valid_604321 = header.getOrDefault("X-Amz-Signature")
  valid_604321 = validateParameter(valid_604321, JString, required = false,
                                 default = nil)
  if valid_604321 != nil:
    section.add "X-Amz-Signature", valid_604321
  var valid_604322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604322 = validateParameter(valid_604322, JString, required = false,
                                 default = nil)
  if valid_604322 != nil:
    section.add "X-Amz-SignedHeaders", valid_604322
  var valid_604323 = header.getOrDefault("X-Amz-Credential")
  valid_604323 = validateParameter(valid_604323, JString, required = false,
                                 default = nil)
  if valid_604323 != nil:
    section.add "X-Amz-Credential", valid_604323
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604324: Call_GetRestartAppServer_604310; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Causes the environment to restart the application container server running on each Amazon EC2 instance.
  ## 
  let valid = call_604324.validator(path, query, header, formData, body)
  let scheme = call_604324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604324.url(scheme.get, call_604324.host, call_604324.base,
                         call_604324.route, valid.getOrDefault("path"))
  result = hook(call_604324, url, valid)

proc call*(call_604325: Call_GetRestartAppServer_604310;
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
  var query_604326 = newJObject()
  add(query_604326, "EnvironmentName", newJString(EnvironmentName))
  add(query_604326, "Action", newJString(Action))
  add(query_604326, "EnvironmentId", newJString(EnvironmentId))
  add(query_604326, "Version", newJString(Version))
  result = call_604325.call(nil, query_604326, nil, nil, nil)

var getRestartAppServer* = Call_GetRestartAppServer_604310(
    name: "getRestartAppServer", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RestartAppServer",
    validator: validate_GetRestartAppServer_604311, base: "/",
    url: url_GetRestartAppServer_604312, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRetrieveEnvironmentInfo_604363 = ref object of OpenApiRestCall_602434
proc url_PostRetrieveEnvironmentInfo_604365(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRetrieveEnvironmentInfo_604364(path: JsonNode; query: JsonNode;
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
  var valid_604366 = query.getOrDefault("Action")
  valid_604366 = validateParameter(valid_604366, JString, required = true, default = newJString(
      "RetrieveEnvironmentInfo"))
  if valid_604366 != nil:
    section.add "Action", valid_604366
  var valid_604367 = query.getOrDefault("Version")
  valid_604367 = validateParameter(valid_604367, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604367 != nil:
    section.add "Version", valid_604367
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
  var valid_604368 = header.getOrDefault("X-Amz-Date")
  valid_604368 = validateParameter(valid_604368, JString, required = false,
                                 default = nil)
  if valid_604368 != nil:
    section.add "X-Amz-Date", valid_604368
  var valid_604369 = header.getOrDefault("X-Amz-Security-Token")
  valid_604369 = validateParameter(valid_604369, JString, required = false,
                                 default = nil)
  if valid_604369 != nil:
    section.add "X-Amz-Security-Token", valid_604369
  var valid_604370 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604370 = validateParameter(valid_604370, JString, required = false,
                                 default = nil)
  if valid_604370 != nil:
    section.add "X-Amz-Content-Sha256", valid_604370
  var valid_604371 = header.getOrDefault("X-Amz-Algorithm")
  valid_604371 = validateParameter(valid_604371, JString, required = false,
                                 default = nil)
  if valid_604371 != nil:
    section.add "X-Amz-Algorithm", valid_604371
  var valid_604372 = header.getOrDefault("X-Amz-Signature")
  valid_604372 = validateParameter(valid_604372, JString, required = false,
                                 default = nil)
  if valid_604372 != nil:
    section.add "X-Amz-Signature", valid_604372
  var valid_604373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604373 = validateParameter(valid_604373, JString, required = false,
                                 default = nil)
  if valid_604373 != nil:
    section.add "X-Amz-SignedHeaders", valid_604373
  var valid_604374 = header.getOrDefault("X-Amz-Credential")
  valid_604374 = validateParameter(valid_604374, JString, required = false,
                                 default = nil)
  if valid_604374 != nil:
    section.add "X-Amz-Credential", valid_604374
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
  var valid_604375 = formData.getOrDefault("InfoType")
  valid_604375 = validateParameter(valid_604375, JString, required = true,
                                 default = newJString("tail"))
  if valid_604375 != nil:
    section.add "InfoType", valid_604375
  var valid_604376 = formData.getOrDefault("EnvironmentId")
  valid_604376 = validateParameter(valid_604376, JString, required = false,
                                 default = nil)
  if valid_604376 != nil:
    section.add "EnvironmentId", valid_604376
  var valid_604377 = formData.getOrDefault("EnvironmentName")
  valid_604377 = validateParameter(valid_604377, JString, required = false,
                                 default = nil)
  if valid_604377 != nil:
    section.add "EnvironmentName", valid_604377
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604378: Call_PostRetrieveEnvironmentInfo_604363; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the compiled information from a <a>RequestEnvironmentInfo</a> request.</p> <p>Related Topics</p> <ul> <li> <p> <a>RequestEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_604378.validator(path, query, header, formData, body)
  let scheme = call_604378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604378.url(scheme.get, call_604378.host, call_604378.base,
                         call_604378.route, valid.getOrDefault("path"))
  result = hook(call_604378, url, valid)

proc call*(call_604379: Call_PostRetrieveEnvironmentInfo_604363;
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
  var query_604380 = newJObject()
  var formData_604381 = newJObject()
  add(formData_604381, "InfoType", newJString(InfoType))
  add(formData_604381, "EnvironmentId", newJString(EnvironmentId))
  add(formData_604381, "EnvironmentName", newJString(EnvironmentName))
  add(query_604380, "Action", newJString(Action))
  add(query_604380, "Version", newJString(Version))
  result = call_604379.call(nil, query_604380, nil, formData_604381, nil)

var postRetrieveEnvironmentInfo* = Call_PostRetrieveEnvironmentInfo_604363(
    name: "postRetrieveEnvironmentInfo", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RetrieveEnvironmentInfo",
    validator: validate_PostRetrieveEnvironmentInfo_604364, base: "/",
    url: url_PostRetrieveEnvironmentInfo_604365,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRetrieveEnvironmentInfo_604345 = ref object of OpenApiRestCall_602434
proc url_GetRetrieveEnvironmentInfo_604347(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRetrieveEnvironmentInfo_604346(path: JsonNode; query: JsonNode;
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
  var valid_604348 = query.getOrDefault("InfoType")
  valid_604348 = validateParameter(valid_604348, JString, required = true,
                                 default = newJString("tail"))
  if valid_604348 != nil:
    section.add "InfoType", valid_604348
  var valid_604349 = query.getOrDefault("EnvironmentName")
  valid_604349 = validateParameter(valid_604349, JString, required = false,
                                 default = nil)
  if valid_604349 != nil:
    section.add "EnvironmentName", valid_604349
  var valid_604350 = query.getOrDefault("Action")
  valid_604350 = validateParameter(valid_604350, JString, required = true, default = newJString(
      "RetrieveEnvironmentInfo"))
  if valid_604350 != nil:
    section.add "Action", valid_604350
  var valid_604351 = query.getOrDefault("EnvironmentId")
  valid_604351 = validateParameter(valid_604351, JString, required = false,
                                 default = nil)
  if valid_604351 != nil:
    section.add "EnvironmentId", valid_604351
  var valid_604352 = query.getOrDefault("Version")
  valid_604352 = validateParameter(valid_604352, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604352 != nil:
    section.add "Version", valid_604352
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
  var valid_604353 = header.getOrDefault("X-Amz-Date")
  valid_604353 = validateParameter(valid_604353, JString, required = false,
                                 default = nil)
  if valid_604353 != nil:
    section.add "X-Amz-Date", valid_604353
  var valid_604354 = header.getOrDefault("X-Amz-Security-Token")
  valid_604354 = validateParameter(valid_604354, JString, required = false,
                                 default = nil)
  if valid_604354 != nil:
    section.add "X-Amz-Security-Token", valid_604354
  var valid_604355 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604355 = validateParameter(valid_604355, JString, required = false,
                                 default = nil)
  if valid_604355 != nil:
    section.add "X-Amz-Content-Sha256", valid_604355
  var valid_604356 = header.getOrDefault("X-Amz-Algorithm")
  valid_604356 = validateParameter(valid_604356, JString, required = false,
                                 default = nil)
  if valid_604356 != nil:
    section.add "X-Amz-Algorithm", valid_604356
  var valid_604357 = header.getOrDefault("X-Amz-Signature")
  valid_604357 = validateParameter(valid_604357, JString, required = false,
                                 default = nil)
  if valid_604357 != nil:
    section.add "X-Amz-Signature", valid_604357
  var valid_604358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604358 = validateParameter(valid_604358, JString, required = false,
                                 default = nil)
  if valid_604358 != nil:
    section.add "X-Amz-SignedHeaders", valid_604358
  var valid_604359 = header.getOrDefault("X-Amz-Credential")
  valid_604359 = validateParameter(valid_604359, JString, required = false,
                                 default = nil)
  if valid_604359 != nil:
    section.add "X-Amz-Credential", valid_604359
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604360: Call_GetRetrieveEnvironmentInfo_604345; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the compiled information from a <a>RequestEnvironmentInfo</a> request.</p> <p>Related Topics</p> <ul> <li> <p> <a>RequestEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_604360.validator(path, query, header, formData, body)
  let scheme = call_604360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604360.url(scheme.get, call_604360.host, call_604360.base,
                         call_604360.route, valid.getOrDefault("path"))
  result = hook(call_604360, url, valid)

proc call*(call_604361: Call_GetRetrieveEnvironmentInfo_604345;
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
  var query_604362 = newJObject()
  add(query_604362, "InfoType", newJString(InfoType))
  add(query_604362, "EnvironmentName", newJString(EnvironmentName))
  add(query_604362, "Action", newJString(Action))
  add(query_604362, "EnvironmentId", newJString(EnvironmentId))
  add(query_604362, "Version", newJString(Version))
  result = call_604361.call(nil, query_604362, nil, nil, nil)

var getRetrieveEnvironmentInfo* = Call_GetRetrieveEnvironmentInfo_604345(
    name: "getRetrieveEnvironmentInfo", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RetrieveEnvironmentInfo",
    validator: validate_GetRetrieveEnvironmentInfo_604346, base: "/",
    url: url_GetRetrieveEnvironmentInfo_604347,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSwapEnvironmentCNAMEs_604401 = ref object of OpenApiRestCall_602434
proc url_PostSwapEnvironmentCNAMEs_604403(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostSwapEnvironmentCNAMEs_604402(path: JsonNode; query: JsonNode;
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
  var valid_604404 = query.getOrDefault("Action")
  valid_604404 = validateParameter(valid_604404, JString, required = true,
                                 default = newJString("SwapEnvironmentCNAMEs"))
  if valid_604404 != nil:
    section.add "Action", valid_604404
  var valid_604405 = query.getOrDefault("Version")
  valid_604405 = validateParameter(valid_604405, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604405 != nil:
    section.add "Version", valid_604405
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
  var valid_604406 = header.getOrDefault("X-Amz-Date")
  valid_604406 = validateParameter(valid_604406, JString, required = false,
                                 default = nil)
  if valid_604406 != nil:
    section.add "X-Amz-Date", valid_604406
  var valid_604407 = header.getOrDefault("X-Amz-Security-Token")
  valid_604407 = validateParameter(valid_604407, JString, required = false,
                                 default = nil)
  if valid_604407 != nil:
    section.add "X-Amz-Security-Token", valid_604407
  var valid_604408 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604408 = validateParameter(valid_604408, JString, required = false,
                                 default = nil)
  if valid_604408 != nil:
    section.add "X-Amz-Content-Sha256", valid_604408
  var valid_604409 = header.getOrDefault("X-Amz-Algorithm")
  valid_604409 = validateParameter(valid_604409, JString, required = false,
                                 default = nil)
  if valid_604409 != nil:
    section.add "X-Amz-Algorithm", valid_604409
  var valid_604410 = header.getOrDefault("X-Amz-Signature")
  valid_604410 = validateParameter(valid_604410, JString, required = false,
                                 default = nil)
  if valid_604410 != nil:
    section.add "X-Amz-Signature", valid_604410
  var valid_604411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604411 = validateParameter(valid_604411, JString, required = false,
                                 default = nil)
  if valid_604411 != nil:
    section.add "X-Amz-SignedHeaders", valid_604411
  var valid_604412 = header.getOrDefault("X-Amz-Credential")
  valid_604412 = validateParameter(valid_604412, JString, required = false,
                                 default = nil)
  if valid_604412 != nil:
    section.add "X-Amz-Credential", valid_604412
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
  var valid_604413 = formData.getOrDefault("SourceEnvironmentName")
  valid_604413 = validateParameter(valid_604413, JString, required = false,
                                 default = nil)
  if valid_604413 != nil:
    section.add "SourceEnvironmentName", valid_604413
  var valid_604414 = formData.getOrDefault("SourceEnvironmentId")
  valid_604414 = validateParameter(valid_604414, JString, required = false,
                                 default = nil)
  if valid_604414 != nil:
    section.add "SourceEnvironmentId", valid_604414
  var valid_604415 = formData.getOrDefault("DestinationEnvironmentId")
  valid_604415 = validateParameter(valid_604415, JString, required = false,
                                 default = nil)
  if valid_604415 != nil:
    section.add "DestinationEnvironmentId", valid_604415
  var valid_604416 = formData.getOrDefault("DestinationEnvironmentName")
  valid_604416 = validateParameter(valid_604416, JString, required = false,
                                 default = nil)
  if valid_604416 != nil:
    section.add "DestinationEnvironmentName", valid_604416
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604417: Call_PostSwapEnvironmentCNAMEs_604401; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Swaps the CNAMEs of two environments.
  ## 
  let valid = call_604417.validator(path, query, header, formData, body)
  let scheme = call_604417.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604417.url(scheme.get, call_604417.host, call_604417.base,
                         call_604417.route, valid.getOrDefault("path"))
  result = hook(call_604417, url, valid)

proc call*(call_604418: Call_PostSwapEnvironmentCNAMEs_604401;
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
  var query_604419 = newJObject()
  var formData_604420 = newJObject()
  add(formData_604420, "SourceEnvironmentName", newJString(SourceEnvironmentName))
  add(formData_604420, "SourceEnvironmentId", newJString(SourceEnvironmentId))
  add(formData_604420, "DestinationEnvironmentId",
      newJString(DestinationEnvironmentId))
  add(formData_604420, "DestinationEnvironmentName",
      newJString(DestinationEnvironmentName))
  add(query_604419, "Action", newJString(Action))
  add(query_604419, "Version", newJString(Version))
  result = call_604418.call(nil, query_604419, nil, formData_604420, nil)

var postSwapEnvironmentCNAMEs* = Call_PostSwapEnvironmentCNAMEs_604401(
    name: "postSwapEnvironmentCNAMEs", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=SwapEnvironmentCNAMEs",
    validator: validate_PostSwapEnvironmentCNAMEs_604402, base: "/",
    url: url_PostSwapEnvironmentCNAMEs_604403,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSwapEnvironmentCNAMEs_604382 = ref object of OpenApiRestCall_602434
proc url_GetSwapEnvironmentCNAMEs_604384(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSwapEnvironmentCNAMEs_604383(path: JsonNode; query: JsonNode;
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
  var valid_604385 = query.getOrDefault("SourceEnvironmentId")
  valid_604385 = validateParameter(valid_604385, JString, required = false,
                                 default = nil)
  if valid_604385 != nil:
    section.add "SourceEnvironmentId", valid_604385
  var valid_604386 = query.getOrDefault("DestinationEnvironmentName")
  valid_604386 = validateParameter(valid_604386, JString, required = false,
                                 default = nil)
  if valid_604386 != nil:
    section.add "DestinationEnvironmentName", valid_604386
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604387 = query.getOrDefault("Action")
  valid_604387 = validateParameter(valid_604387, JString, required = true,
                                 default = newJString("SwapEnvironmentCNAMEs"))
  if valid_604387 != nil:
    section.add "Action", valid_604387
  var valid_604388 = query.getOrDefault("SourceEnvironmentName")
  valid_604388 = validateParameter(valid_604388, JString, required = false,
                                 default = nil)
  if valid_604388 != nil:
    section.add "SourceEnvironmentName", valid_604388
  var valid_604389 = query.getOrDefault("DestinationEnvironmentId")
  valid_604389 = validateParameter(valid_604389, JString, required = false,
                                 default = nil)
  if valid_604389 != nil:
    section.add "DestinationEnvironmentId", valid_604389
  var valid_604390 = query.getOrDefault("Version")
  valid_604390 = validateParameter(valid_604390, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604390 != nil:
    section.add "Version", valid_604390
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
  var valid_604391 = header.getOrDefault("X-Amz-Date")
  valid_604391 = validateParameter(valid_604391, JString, required = false,
                                 default = nil)
  if valid_604391 != nil:
    section.add "X-Amz-Date", valid_604391
  var valid_604392 = header.getOrDefault("X-Amz-Security-Token")
  valid_604392 = validateParameter(valid_604392, JString, required = false,
                                 default = nil)
  if valid_604392 != nil:
    section.add "X-Amz-Security-Token", valid_604392
  var valid_604393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604393 = validateParameter(valid_604393, JString, required = false,
                                 default = nil)
  if valid_604393 != nil:
    section.add "X-Amz-Content-Sha256", valid_604393
  var valid_604394 = header.getOrDefault("X-Amz-Algorithm")
  valid_604394 = validateParameter(valid_604394, JString, required = false,
                                 default = nil)
  if valid_604394 != nil:
    section.add "X-Amz-Algorithm", valid_604394
  var valid_604395 = header.getOrDefault("X-Amz-Signature")
  valid_604395 = validateParameter(valid_604395, JString, required = false,
                                 default = nil)
  if valid_604395 != nil:
    section.add "X-Amz-Signature", valid_604395
  var valid_604396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604396 = validateParameter(valid_604396, JString, required = false,
                                 default = nil)
  if valid_604396 != nil:
    section.add "X-Amz-SignedHeaders", valid_604396
  var valid_604397 = header.getOrDefault("X-Amz-Credential")
  valid_604397 = validateParameter(valid_604397, JString, required = false,
                                 default = nil)
  if valid_604397 != nil:
    section.add "X-Amz-Credential", valid_604397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604398: Call_GetSwapEnvironmentCNAMEs_604382; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Swaps the CNAMEs of two environments.
  ## 
  let valid = call_604398.validator(path, query, header, formData, body)
  let scheme = call_604398.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604398.url(scheme.get, call_604398.host, call_604398.base,
                         call_604398.route, valid.getOrDefault("path"))
  result = hook(call_604398, url, valid)

proc call*(call_604399: Call_GetSwapEnvironmentCNAMEs_604382;
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
  var query_604400 = newJObject()
  add(query_604400, "SourceEnvironmentId", newJString(SourceEnvironmentId))
  add(query_604400, "DestinationEnvironmentName",
      newJString(DestinationEnvironmentName))
  add(query_604400, "Action", newJString(Action))
  add(query_604400, "SourceEnvironmentName", newJString(SourceEnvironmentName))
  add(query_604400, "DestinationEnvironmentId",
      newJString(DestinationEnvironmentId))
  add(query_604400, "Version", newJString(Version))
  result = call_604399.call(nil, query_604400, nil, nil, nil)

var getSwapEnvironmentCNAMEs* = Call_GetSwapEnvironmentCNAMEs_604382(
    name: "getSwapEnvironmentCNAMEs", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=SwapEnvironmentCNAMEs",
    validator: validate_GetSwapEnvironmentCNAMEs_604383, base: "/",
    url: url_GetSwapEnvironmentCNAMEs_604384, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostTerminateEnvironment_604440 = ref object of OpenApiRestCall_602434
proc url_PostTerminateEnvironment_604442(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostTerminateEnvironment_604441(path: JsonNode; query: JsonNode;
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
  var valid_604443 = query.getOrDefault("Action")
  valid_604443 = validateParameter(valid_604443, JString, required = true,
                                 default = newJString("TerminateEnvironment"))
  if valid_604443 != nil:
    section.add "Action", valid_604443
  var valid_604444 = query.getOrDefault("Version")
  valid_604444 = validateParameter(valid_604444, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604444 != nil:
    section.add "Version", valid_604444
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
  var valid_604445 = header.getOrDefault("X-Amz-Date")
  valid_604445 = validateParameter(valid_604445, JString, required = false,
                                 default = nil)
  if valid_604445 != nil:
    section.add "X-Amz-Date", valid_604445
  var valid_604446 = header.getOrDefault("X-Amz-Security-Token")
  valid_604446 = validateParameter(valid_604446, JString, required = false,
                                 default = nil)
  if valid_604446 != nil:
    section.add "X-Amz-Security-Token", valid_604446
  var valid_604447 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604447 = validateParameter(valid_604447, JString, required = false,
                                 default = nil)
  if valid_604447 != nil:
    section.add "X-Amz-Content-Sha256", valid_604447
  var valid_604448 = header.getOrDefault("X-Amz-Algorithm")
  valid_604448 = validateParameter(valid_604448, JString, required = false,
                                 default = nil)
  if valid_604448 != nil:
    section.add "X-Amz-Algorithm", valid_604448
  var valid_604449 = header.getOrDefault("X-Amz-Signature")
  valid_604449 = validateParameter(valid_604449, JString, required = false,
                                 default = nil)
  if valid_604449 != nil:
    section.add "X-Amz-Signature", valid_604449
  var valid_604450 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604450 = validateParameter(valid_604450, JString, required = false,
                                 default = nil)
  if valid_604450 != nil:
    section.add "X-Amz-SignedHeaders", valid_604450
  var valid_604451 = header.getOrDefault("X-Amz-Credential")
  valid_604451 = validateParameter(valid_604451, JString, required = false,
                                 default = nil)
  if valid_604451 != nil:
    section.add "X-Amz-Credential", valid_604451
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
  var valid_604452 = formData.getOrDefault("ForceTerminate")
  valid_604452 = validateParameter(valid_604452, JBool, required = false, default = nil)
  if valid_604452 != nil:
    section.add "ForceTerminate", valid_604452
  var valid_604453 = formData.getOrDefault("TerminateResources")
  valid_604453 = validateParameter(valid_604453, JBool, required = false, default = nil)
  if valid_604453 != nil:
    section.add "TerminateResources", valid_604453
  var valid_604454 = formData.getOrDefault("EnvironmentId")
  valid_604454 = validateParameter(valid_604454, JString, required = false,
                                 default = nil)
  if valid_604454 != nil:
    section.add "EnvironmentId", valid_604454
  var valid_604455 = formData.getOrDefault("EnvironmentName")
  valid_604455 = validateParameter(valid_604455, JString, required = false,
                                 default = nil)
  if valid_604455 != nil:
    section.add "EnvironmentName", valid_604455
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604456: Call_PostTerminateEnvironment_604440; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Terminates the specified environment.
  ## 
  let valid = call_604456.validator(path, query, header, formData, body)
  let scheme = call_604456.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604456.url(scheme.get, call_604456.host, call_604456.base,
                         call_604456.route, valid.getOrDefault("path"))
  result = hook(call_604456, url, valid)

proc call*(call_604457: Call_PostTerminateEnvironment_604440;
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
  var query_604458 = newJObject()
  var formData_604459 = newJObject()
  add(formData_604459, "ForceTerminate", newJBool(ForceTerminate))
  add(formData_604459, "TerminateResources", newJBool(TerminateResources))
  add(formData_604459, "EnvironmentId", newJString(EnvironmentId))
  add(formData_604459, "EnvironmentName", newJString(EnvironmentName))
  add(query_604458, "Action", newJString(Action))
  add(query_604458, "Version", newJString(Version))
  result = call_604457.call(nil, query_604458, nil, formData_604459, nil)

var postTerminateEnvironment* = Call_PostTerminateEnvironment_604440(
    name: "postTerminateEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=TerminateEnvironment",
    validator: validate_PostTerminateEnvironment_604441, base: "/",
    url: url_PostTerminateEnvironment_604442, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTerminateEnvironment_604421 = ref object of OpenApiRestCall_602434
proc url_GetTerminateEnvironment_604423(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetTerminateEnvironment_604422(path: JsonNode; query: JsonNode;
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
  var valid_604424 = query.getOrDefault("EnvironmentName")
  valid_604424 = validateParameter(valid_604424, JString, required = false,
                                 default = nil)
  if valid_604424 != nil:
    section.add "EnvironmentName", valid_604424
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604425 = query.getOrDefault("Action")
  valid_604425 = validateParameter(valid_604425, JString, required = true,
                                 default = newJString("TerminateEnvironment"))
  if valid_604425 != nil:
    section.add "Action", valid_604425
  var valid_604426 = query.getOrDefault("EnvironmentId")
  valid_604426 = validateParameter(valid_604426, JString, required = false,
                                 default = nil)
  if valid_604426 != nil:
    section.add "EnvironmentId", valid_604426
  var valid_604427 = query.getOrDefault("ForceTerminate")
  valid_604427 = validateParameter(valid_604427, JBool, required = false, default = nil)
  if valid_604427 != nil:
    section.add "ForceTerminate", valid_604427
  var valid_604428 = query.getOrDefault("TerminateResources")
  valid_604428 = validateParameter(valid_604428, JBool, required = false, default = nil)
  if valid_604428 != nil:
    section.add "TerminateResources", valid_604428
  var valid_604429 = query.getOrDefault("Version")
  valid_604429 = validateParameter(valid_604429, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604429 != nil:
    section.add "Version", valid_604429
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
  var valid_604430 = header.getOrDefault("X-Amz-Date")
  valid_604430 = validateParameter(valid_604430, JString, required = false,
                                 default = nil)
  if valid_604430 != nil:
    section.add "X-Amz-Date", valid_604430
  var valid_604431 = header.getOrDefault("X-Amz-Security-Token")
  valid_604431 = validateParameter(valid_604431, JString, required = false,
                                 default = nil)
  if valid_604431 != nil:
    section.add "X-Amz-Security-Token", valid_604431
  var valid_604432 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604432 = validateParameter(valid_604432, JString, required = false,
                                 default = nil)
  if valid_604432 != nil:
    section.add "X-Amz-Content-Sha256", valid_604432
  var valid_604433 = header.getOrDefault("X-Amz-Algorithm")
  valid_604433 = validateParameter(valid_604433, JString, required = false,
                                 default = nil)
  if valid_604433 != nil:
    section.add "X-Amz-Algorithm", valid_604433
  var valid_604434 = header.getOrDefault("X-Amz-Signature")
  valid_604434 = validateParameter(valid_604434, JString, required = false,
                                 default = nil)
  if valid_604434 != nil:
    section.add "X-Amz-Signature", valid_604434
  var valid_604435 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604435 = validateParameter(valid_604435, JString, required = false,
                                 default = nil)
  if valid_604435 != nil:
    section.add "X-Amz-SignedHeaders", valid_604435
  var valid_604436 = header.getOrDefault("X-Amz-Credential")
  valid_604436 = validateParameter(valid_604436, JString, required = false,
                                 default = nil)
  if valid_604436 != nil:
    section.add "X-Amz-Credential", valid_604436
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604437: Call_GetTerminateEnvironment_604421; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Terminates the specified environment.
  ## 
  let valid = call_604437.validator(path, query, header, formData, body)
  let scheme = call_604437.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604437.url(scheme.get, call_604437.host, call_604437.base,
                         call_604437.route, valid.getOrDefault("path"))
  result = hook(call_604437, url, valid)

proc call*(call_604438: Call_GetTerminateEnvironment_604421;
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
  var query_604439 = newJObject()
  add(query_604439, "EnvironmentName", newJString(EnvironmentName))
  add(query_604439, "Action", newJString(Action))
  add(query_604439, "EnvironmentId", newJString(EnvironmentId))
  add(query_604439, "ForceTerminate", newJBool(ForceTerminate))
  add(query_604439, "TerminateResources", newJBool(TerminateResources))
  add(query_604439, "Version", newJString(Version))
  result = call_604438.call(nil, query_604439, nil, nil, nil)

var getTerminateEnvironment* = Call_GetTerminateEnvironment_604421(
    name: "getTerminateEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=TerminateEnvironment",
    validator: validate_GetTerminateEnvironment_604422, base: "/",
    url: url_GetTerminateEnvironment_604423, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateApplication_604477 = ref object of OpenApiRestCall_602434
proc url_PostUpdateApplication_604479(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostUpdateApplication_604478(path: JsonNode; query: JsonNode;
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
  var valid_604480 = query.getOrDefault("Action")
  valid_604480 = validateParameter(valid_604480, JString, required = true,
                                 default = newJString("UpdateApplication"))
  if valid_604480 != nil:
    section.add "Action", valid_604480
  var valid_604481 = query.getOrDefault("Version")
  valid_604481 = validateParameter(valid_604481, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604481 != nil:
    section.add "Version", valid_604481
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
  var valid_604482 = header.getOrDefault("X-Amz-Date")
  valid_604482 = validateParameter(valid_604482, JString, required = false,
                                 default = nil)
  if valid_604482 != nil:
    section.add "X-Amz-Date", valid_604482
  var valid_604483 = header.getOrDefault("X-Amz-Security-Token")
  valid_604483 = validateParameter(valid_604483, JString, required = false,
                                 default = nil)
  if valid_604483 != nil:
    section.add "X-Amz-Security-Token", valid_604483
  var valid_604484 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604484 = validateParameter(valid_604484, JString, required = false,
                                 default = nil)
  if valid_604484 != nil:
    section.add "X-Amz-Content-Sha256", valid_604484
  var valid_604485 = header.getOrDefault("X-Amz-Algorithm")
  valid_604485 = validateParameter(valid_604485, JString, required = false,
                                 default = nil)
  if valid_604485 != nil:
    section.add "X-Amz-Algorithm", valid_604485
  var valid_604486 = header.getOrDefault("X-Amz-Signature")
  valid_604486 = validateParameter(valid_604486, JString, required = false,
                                 default = nil)
  if valid_604486 != nil:
    section.add "X-Amz-Signature", valid_604486
  var valid_604487 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604487 = validateParameter(valid_604487, JString, required = false,
                                 default = nil)
  if valid_604487 != nil:
    section.add "X-Amz-SignedHeaders", valid_604487
  var valid_604488 = header.getOrDefault("X-Amz-Credential")
  valid_604488 = validateParameter(valid_604488, JString, required = false,
                                 default = nil)
  if valid_604488 != nil:
    section.add "X-Amz-Credential", valid_604488
  result.add "header", section
  ## parameters in `formData` object:
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to update. If no such application is found, <code>UpdateApplication</code> returns an <code>InvalidParameterValue</code> error. 
  ##   Description: JString
  ##              : <p>A new description for the application.</p> <p>Default: If not specified, AWS Elastic Beanstalk does not update the description.</p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_604489 = formData.getOrDefault("ApplicationName")
  valid_604489 = validateParameter(valid_604489, JString, required = true,
                                 default = nil)
  if valid_604489 != nil:
    section.add "ApplicationName", valid_604489
  var valid_604490 = formData.getOrDefault("Description")
  valid_604490 = validateParameter(valid_604490, JString, required = false,
                                 default = nil)
  if valid_604490 != nil:
    section.add "Description", valid_604490
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604491: Call_PostUpdateApplication_604477; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified application to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear these properties, specify an empty string.</p> </note>
  ## 
  let valid = call_604491.validator(path, query, header, formData, body)
  let scheme = call_604491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604491.url(scheme.get, call_604491.host, call_604491.base,
                         call_604491.route, valid.getOrDefault("path"))
  result = hook(call_604491, url, valid)

proc call*(call_604492: Call_PostUpdateApplication_604477; ApplicationName: string;
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
  var query_604493 = newJObject()
  var formData_604494 = newJObject()
  add(query_604493, "Action", newJString(Action))
  add(formData_604494, "ApplicationName", newJString(ApplicationName))
  add(query_604493, "Version", newJString(Version))
  add(formData_604494, "Description", newJString(Description))
  result = call_604492.call(nil, query_604493, nil, formData_604494, nil)

var postUpdateApplication* = Call_PostUpdateApplication_604477(
    name: "postUpdateApplication", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateApplication",
    validator: validate_PostUpdateApplication_604478, base: "/",
    url: url_PostUpdateApplication_604479, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateApplication_604460 = ref object of OpenApiRestCall_602434
proc url_GetUpdateApplication_604462(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUpdateApplication_604461(path: JsonNode; query: JsonNode;
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
  var valid_604463 = query.getOrDefault("ApplicationName")
  valid_604463 = validateParameter(valid_604463, JString, required = true,
                                 default = nil)
  if valid_604463 != nil:
    section.add "ApplicationName", valid_604463
  var valid_604464 = query.getOrDefault("Description")
  valid_604464 = validateParameter(valid_604464, JString, required = false,
                                 default = nil)
  if valid_604464 != nil:
    section.add "Description", valid_604464
  var valid_604465 = query.getOrDefault("Action")
  valid_604465 = validateParameter(valid_604465, JString, required = true,
                                 default = newJString("UpdateApplication"))
  if valid_604465 != nil:
    section.add "Action", valid_604465
  var valid_604466 = query.getOrDefault("Version")
  valid_604466 = validateParameter(valid_604466, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604466 != nil:
    section.add "Version", valid_604466
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
  var valid_604467 = header.getOrDefault("X-Amz-Date")
  valid_604467 = validateParameter(valid_604467, JString, required = false,
                                 default = nil)
  if valid_604467 != nil:
    section.add "X-Amz-Date", valid_604467
  var valid_604468 = header.getOrDefault("X-Amz-Security-Token")
  valid_604468 = validateParameter(valid_604468, JString, required = false,
                                 default = nil)
  if valid_604468 != nil:
    section.add "X-Amz-Security-Token", valid_604468
  var valid_604469 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604469 = validateParameter(valid_604469, JString, required = false,
                                 default = nil)
  if valid_604469 != nil:
    section.add "X-Amz-Content-Sha256", valid_604469
  var valid_604470 = header.getOrDefault("X-Amz-Algorithm")
  valid_604470 = validateParameter(valid_604470, JString, required = false,
                                 default = nil)
  if valid_604470 != nil:
    section.add "X-Amz-Algorithm", valid_604470
  var valid_604471 = header.getOrDefault("X-Amz-Signature")
  valid_604471 = validateParameter(valid_604471, JString, required = false,
                                 default = nil)
  if valid_604471 != nil:
    section.add "X-Amz-Signature", valid_604471
  var valid_604472 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604472 = validateParameter(valid_604472, JString, required = false,
                                 default = nil)
  if valid_604472 != nil:
    section.add "X-Amz-SignedHeaders", valid_604472
  var valid_604473 = header.getOrDefault("X-Amz-Credential")
  valid_604473 = validateParameter(valid_604473, JString, required = false,
                                 default = nil)
  if valid_604473 != nil:
    section.add "X-Amz-Credential", valid_604473
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604474: Call_GetUpdateApplication_604460; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified application to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear these properties, specify an empty string.</p> </note>
  ## 
  let valid = call_604474.validator(path, query, header, formData, body)
  let scheme = call_604474.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604474.url(scheme.get, call_604474.host, call_604474.base,
                         call_604474.route, valid.getOrDefault("path"))
  result = hook(call_604474, url, valid)

proc call*(call_604475: Call_GetUpdateApplication_604460; ApplicationName: string;
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
  var query_604476 = newJObject()
  add(query_604476, "ApplicationName", newJString(ApplicationName))
  add(query_604476, "Description", newJString(Description))
  add(query_604476, "Action", newJString(Action))
  add(query_604476, "Version", newJString(Version))
  result = call_604475.call(nil, query_604476, nil, nil, nil)

var getUpdateApplication* = Call_GetUpdateApplication_604460(
    name: "getUpdateApplication", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateApplication",
    validator: validate_GetUpdateApplication_604461, base: "/",
    url: url_GetUpdateApplication_604462, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateApplicationResourceLifecycle_604513 = ref object of OpenApiRestCall_602434
proc url_PostUpdateApplicationResourceLifecycle_604515(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostUpdateApplicationResourceLifecycle_604514(path: JsonNode;
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
  var valid_604516 = query.getOrDefault("Action")
  valid_604516 = validateParameter(valid_604516, JString, required = true, default = newJString(
      "UpdateApplicationResourceLifecycle"))
  if valid_604516 != nil:
    section.add "Action", valid_604516
  var valid_604517 = query.getOrDefault("Version")
  valid_604517 = validateParameter(valid_604517, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604517 != nil:
    section.add "Version", valid_604517
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
  var valid_604518 = header.getOrDefault("X-Amz-Date")
  valid_604518 = validateParameter(valid_604518, JString, required = false,
                                 default = nil)
  if valid_604518 != nil:
    section.add "X-Amz-Date", valid_604518
  var valid_604519 = header.getOrDefault("X-Amz-Security-Token")
  valid_604519 = validateParameter(valid_604519, JString, required = false,
                                 default = nil)
  if valid_604519 != nil:
    section.add "X-Amz-Security-Token", valid_604519
  var valid_604520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604520 = validateParameter(valid_604520, JString, required = false,
                                 default = nil)
  if valid_604520 != nil:
    section.add "X-Amz-Content-Sha256", valid_604520
  var valid_604521 = header.getOrDefault("X-Amz-Algorithm")
  valid_604521 = validateParameter(valid_604521, JString, required = false,
                                 default = nil)
  if valid_604521 != nil:
    section.add "X-Amz-Algorithm", valid_604521
  var valid_604522 = header.getOrDefault("X-Amz-Signature")
  valid_604522 = validateParameter(valid_604522, JString, required = false,
                                 default = nil)
  if valid_604522 != nil:
    section.add "X-Amz-Signature", valid_604522
  var valid_604523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604523 = validateParameter(valid_604523, JString, required = false,
                                 default = nil)
  if valid_604523 != nil:
    section.add "X-Amz-SignedHeaders", valid_604523
  var valid_604524 = header.getOrDefault("X-Amz-Credential")
  valid_604524 = validateParameter(valid_604524, JString, required = false,
                                 default = nil)
  if valid_604524 != nil:
    section.add "X-Amz-Credential", valid_604524
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
  var valid_604525 = formData.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_604525 = validateParameter(valid_604525, JString, required = false,
                                 default = nil)
  if valid_604525 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_604525
  var valid_604526 = formData.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_604526 = validateParameter(valid_604526, JString, required = false,
                                 default = nil)
  if valid_604526 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_604526
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_604527 = formData.getOrDefault("ApplicationName")
  valid_604527 = validateParameter(valid_604527, JString, required = true,
                                 default = nil)
  if valid_604527 != nil:
    section.add "ApplicationName", valid_604527
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604528: Call_PostUpdateApplicationResourceLifecycle_604513;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Modifies lifecycle settings for an application.
  ## 
  let valid = call_604528.validator(path, query, header, formData, body)
  let scheme = call_604528.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604528.url(scheme.get, call_604528.host, call_604528.base,
                         call_604528.route, valid.getOrDefault("path"))
  result = hook(call_604528, url, valid)

proc call*(call_604529: Call_PostUpdateApplicationResourceLifecycle_604513;
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
  var query_604530 = newJObject()
  var formData_604531 = newJObject()
  add(formData_604531, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  add(formData_604531, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  add(query_604530, "Action", newJString(Action))
  add(formData_604531, "ApplicationName", newJString(ApplicationName))
  add(query_604530, "Version", newJString(Version))
  result = call_604529.call(nil, query_604530, nil, formData_604531, nil)

var postUpdateApplicationResourceLifecycle* = Call_PostUpdateApplicationResourceLifecycle_604513(
    name: "postUpdateApplicationResourceLifecycle", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationResourceLifecycle",
    validator: validate_PostUpdateApplicationResourceLifecycle_604514, base: "/",
    url: url_PostUpdateApplicationResourceLifecycle_604515,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateApplicationResourceLifecycle_604495 = ref object of OpenApiRestCall_602434
proc url_GetUpdateApplicationResourceLifecycle_604497(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUpdateApplicationResourceLifecycle_604496(path: JsonNode;
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
  var valid_604498 = query.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_604498 = validateParameter(valid_604498, JString, required = false,
                                 default = nil)
  if valid_604498 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_604498
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_604499 = query.getOrDefault("ApplicationName")
  valid_604499 = validateParameter(valid_604499, JString, required = true,
                                 default = nil)
  if valid_604499 != nil:
    section.add "ApplicationName", valid_604499
  var valid_604500 = query.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_604500 = validateParameter(valid_604500, JString, required = false,
                                 default = nil)
  if valid_604500 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_604500
  var valid_604501 = query.getOrDefault("Action")
  valid_604501 = validateParameter(valid_604501, JString, required = true, default = newJString(
      "UpdateApplicationResourceLifecycle"))
  if valid_604501 != nil:
    section.add "Action", valid_604501
  var valid_604502 = query.getOrDefault("Version")
  valid_604502 = validateParameter(valid_604502, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604502 != nil:
    section.add "Version", valid_604502
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
  var valid_604503 = header.getOrDefault("X-Amz-Date")
  valid_604503 = validateParameter(valid_604503, JString, required = false,
                                 default = nil)
  if valid_604503 != nil:
    section.add "X-Amz-Date", valid_604503
  var valid_604504 = header.getOrDefault("X-Amz-Security-Token")
  valid_604504 = validateParameter(valid_604504, JString, required = false,
                                 default = nil)
  if valid_604504 != nil:
    section.add "X-Amz-Security-Token", valid_604504
  var valid_604505 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604505 = validateParameter(valid_604505, JString, required = false,
                                 default = nil)
  if valid_604505 != nil:
    section.add "X-Amz-Content-Sha256", valid_604505
  var valid_604506 = header.getOrDefault("X-Amz-Algorithm")
  valid_604506 = validateParameter(valid_604506, JString, required = false,
                                 default = nil)
  if valid_604506 != nil:
    section.add "X-Amz-Algorithm", valid_604506
  var valid_604507 = header.getOrDefault("X-Amz-Signature")
  valid_604507 = validateParameter(valid_604507, JString, required = false,
                                 default = nil)
  if valid_604507 != nil:
    section.add "X-Amz-Signature", valid_604507
  var valid_604508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604508 = validateParameter(valid_604508, JString, required = false,
                                 default = nil)
  if valid_604508 != nil:
    section.add "X-Amz-SignedHeaders", valid_604508
  var valid_604509 = header.getOrDefault("X-Amz-Credential")
  valid_604509 = validateParameter(valid_604509, JString, required = false,
                                 default = nil)
  if valid_604509 != nil:
    section.add "X-Amz-Credential", valid_604509
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604510: Call_GetUpdateApplicationResourceLifecycle_604495;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Modifies lifecycle settings for an application.
  ## 
  let valid = call_604510.validator(path, query, header, formData, body)
  let scheme = call_604510.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604510.url(scheme.get, call_604510.host, call_604510.base,
                         call_604510.route, valid.getOrDefault("path"))
  result = hook(call_604510, url, valid)

proc call*(call_604511: Call_GetUpdateApplicationResourceLifecycle_604495;
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
  var query_604512 = newJObject()
  add(query_604512, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  add(query_604512, "ApplicationName", newJString(ApplicationName))
  add(query_604512, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  add(query_604512, "Action", newJString(Action))
  add(query_604512, "Version", newJString(Version))
  result = call_604511.call(nil, query_604512, nil, nil, nil)

var getUpdateApplicationResourceLifecycle* = Call_GetUpdateApplicationResourceLifecycle_604495(
    name: "getUpdateApplicationResourceLifecycle", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationResourceLifecycle",
    validator: validate_GetUpdateApplicationResourceLifecycle_604496, base: "/",
    url: url_GetUpdateApplicationResourceLifecycle_604497,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateApplicationVersion_604550 = ref object of OpenApiRestCall_602434
proc url_PostUpdateApplicationVersion_604552(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostUpdateApplicationVersion_604551(path: JsonNode; query: JsonNode;
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
  var valid_604553 = query.getOrDefault("Action")
  valid_604553 = validateParameter(valid_604553, JString, required = true, default = newJString(
      "UpdateApplicationVersion"))
  if valid_604553 != nil:
    section.add "Action", valid_604553
  var valid_604554 = query.getOrDefault("Version")
  valid_604554 = validateParameter(valid_604554, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604554 != nil:
    section.add "Version", valid_604554
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
  var valid_604555 = header.getOrDefault("X-Amz-Date")
  valid_604555 = validateParameter(valid_604555, JString, required = false,
                                 default = nil)
  if valid_604555 != nil:
    section.add "X-Amz-Date", valid_604555
  var valid_604556 = header.getOrDefault("X-Amz-Security-Token")
  valid_604556 = validateParameter(valid_604556, JString, required = false,
                                 default = nil)
  if valid_604556 != nil:
    section.add "X-Amz-Security-Token", valid_604556
  var valid_604557 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604557 = validateParameter(valid_604557, JString, required = false,
                                 default = nil)
  if valid_604557 != nil:
    section.add "X-Amz-Content-Sha256", valid_604557
  var valid_604558 = header.getOrDefault("X-Amz-Algorithm")
  valid_604558 = validateParameter(valid_604558, JString, required = false,
                                 default = nil)
  if valid_604558 != nil:
    section.add "X-Amz-Algorithm", valid_604558
  var valid_604559 = header.getOrDefault("X-Amz-Signature")
  valid_604559 = validateParameter(valid_604559, JString, required = false,
                                 default = nil)
  if valid_604559 != nil:
    section.add "X-Amz-Signature", valid_604559
  var valid_604560 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604560 = validateParameter(valid_604560, JString, required = false,
                                 default = nil)
  if valid_604560 != nil:
    section.add "X-Amz-SignedHeaders", valid_604560
  var valid_604561 = header.getOrDefault("X-Amz-Credential")
  valid_604561 = validateParameter(valid_604561, JString, required = false,
                                 default = nil)
  if valid_604561 != nil:
    section.add "X-Amz-Credential", valid_604561
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
  var valid_604562 = formData.getOrDefault("VersionLabel")
  valid_604562 = validateParameter(valid_604562, JString, required = true,
                                 default = nil)
  if valid_604562 != nil:
    section.add "VersionLabel", valid_604562
  var valid_604563 = formData.getOrDefault("ApplicationName")
  valid_604563 = validateParameter(valid_604563, JString, required = true,
                                 default = nil)
  if valid_604563 != nil:
    section.add "ApplicationName", valid_604563
  var valid_604564 = formData.getOrDefault("Description")
  valid_604564 = validateParameter(valid_604564, JString, required = false,
                                 default = nil)
  if valid_604564 != nil:
    section.add "Description", valid_604564
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604565: Call_PostUpdateApplicationVersion_604550; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified application version to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear properties, specify an empty string.</p> </note>
  ## 
  let valid = call_604565.validator(path, query, header, formData, body)
  let scheme = call_604565.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604565.url(scheme.get, call_604565.host, call_604565.base,
                         call_604565.route, valid.getOrDefault("path"))
  result = hook(call_604565, url, valid)

proc call*(call_604566: Call_PostUpdateApplicationVersion_604550;
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
  var query_604567 = newJObject()
  var formData_604568 = newJObject()
  add(formData_604568, "VersionLabel", newJString(VersionLabel))
  add(query_604567, "Action", newJString(Action))
  add(formData_604568, "ApplicationName", newJString(ApplicationName))
  add(query_604567, "Version", newJString(Version))
  add(formData_604568, "Description", newJString(Description))
  result = call_604566.call(nil, query_604567, nil, formData_604568, nil)

var postUpdateApplicationVersion* = Call_PostUpdateApplicationVersion_604550(
    name: "postUpdateApplicationVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationVersion",
    validator: validate_PostUpdateApplicationVersion_604551, base: "/",
    url: url_PostUpdateApplicationVersion_604552,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateApplicationVersion_604532 = ref object of OpenApiRestCall_602434
proc url_GetUpdateApplicationVersion_604534(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUpdateApplicationVersion_604533(path: JsonNode; query: JsonNode;
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
  var valid_604535 = query.getOrDefault("VersionLabel")
  valid_604535 = validateParameter(valid_604535, JString, required = true,
                                 default = nil)
  if valid_604535 != nil:
    section.add "VersionLabel", valid_604535
  var valid_604536 = query.getOrDefault("ApplicationName")
  valid_604536 = validateParameter(valid_604536, JString, required = true,
                                 default = nil)
  if valid_604536 != nil:
    section.add "ApplicationName", valid_604536
  var valid_604537 = query.getOrDefault("Description")
  valid_604537 = validateParameter(valid_604537, JString, required = false,
                                 default = nil)
  if valid_604537 != nil:
    section.add "Description", valid_604537
  var valid_604538 = query.getOrDefault("Action")
  valid_604538 = validateParameter(valid_604538, JString, required = true, default = newJString(
      "UpdateApplicationVersion"))
  if valid_604538 != nil:
    section.add "Action", valid_604538
  var valid_604539 = query.getOrDefault("Version")
  valid_604539 = validateParameter(valid_604539, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604539 != nil:
    section.add "Version", valid_604539
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
  var valid_604540 = header.getOrDefault("X-Amz-Date")
  valid_604540 = validateParameter(valid_604540, JString, required = false,
                                 default = nil)
  if valid_604540 != nil:
    section.add "X-Amz-Date", valid_604540
  var valid_604541 = header.getOrDefault("X-Amz-Security-Token")
  valid_604541 = validateParameter(valid_604541, JString, required = false,
                                 default = nil)
  if valid_604541 != nil:
    section.add "X-Amz-Security-Token", valid_604541
  var valid_604542 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604542 = validateParameter(valid_604542, JString, required = false,
                                 default = nil)
  if valid_604542 != nil:
    section.add "X-Amz-Content-Sha256", valid_604542
  var valid_604543 = header.getOrDefault("X-Amz-Algorithm")
  valid_604543 = validateParameter(valid_604543, JString, required = false,
                                 default = nil)
  if valid_604543 != nil:
    section.add "X-Amz-Algorithm", valid_604543
  var valid_604544 = header.getOrDefault("X-Amz-Signature")
  valid_604544 = validateParameter(valid_604544, JString, required = false,
                                 default = nil)
  if valid_604544 != nil:
    section.add "X-Amz-Signature", valid_604544
  var valid_604545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604545 = validateParameter(valid_604545, JString, required = false,
                                 default = nil)
  if valid_604545 != nil:
    section.add "X-Amz-SignedHeaders", valid_604545
  var valid_604546 = header.getOrDefault("X-Amz-Credential")
  valid_604546 = validateParameter(valid_604546, JString, required = false,
                                 default = nil)
  if valid_604546 != nil:
    section.add "X-Amz-Credential", valid_604546
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604547: Call_GetUpdateApplicationVersion_604532; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified application version to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear properties, specify an empty string.</p> </note>
  ## 
  let valid = call_604547.validator(path, query, header, formData, body)
  let scheme = call_604547.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604547.url(scheme.get, call_604547.host, call_604547.base,
                         call_604547.route, valid.getOrDefault("path"))
  result = hook(call_604547, url, valid)

proc call*(call_604548: Call_GetUpdateApplicationVersion_604532;
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
  var query_604549 = newJObject()
  add(query_604549, "VersionLabel", newJString(VersionLabel))
  add(query_604549, "ApplicationName", newJString(ApplicationName))
  add(query_604549, "Description", newJString(Description))
  add(query_604549, "Action", newJString(Action))
  add(query_604549, "Version", newJString(Version))
  result = call_604548.call(nil, query_604549, nil, nil, nil)

var getUpdateApplicationVersion* = Call_GetUpdateApplicationVersion_604532(
    name: "getUpdateApplicationVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationVersion",
    validator: validate_GetUpdateApplicationVersion_604533, base: "/",
    url: url_GetUpdateApplicationVersion_604534,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateConfigurationTemplate_604589 = ref object of OpenApiRestCall_602434
proc url_PostUpdateConfigurationTemplate_604591(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostUpdateConfigurationTemplate_604590(path: JsonNode;
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
  var valid_604592 = query.getOrDefault("Action")
  valid_604592 = validateParameter(valid_604592, JString, required = true, default = newJString(
      "UpdateConfigurationTemplate"))
  if valid_604592 != nil:
    section.add "Action", valid_604592
  var valid_604593 = query.getOrDefault("Version")
  valid_604593 = validateParameter(valid_604593, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604593 != nil:
    section.add "Version", valid_604593
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
  var valid_604594 = header.getOrDefault("X-Amz-Date")
  valid_604594 = validateParameter(valid_604594, JString, required = false,
                                 default = nil)
  if valid_604594 != nil:
    section.add "X-Amz-Date", valid_604594
  var valid_604595 = header.getOrDefault("X-Amz-Security-Token")
  valid_604595 = validateParameter(valid_604595, JString, required = false,
                                 default = nil)
  if valid_604595 != nil:
    section.add "X-Amz-Security-Token", valid_604595
  var valid_604596 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604596 = validateParameter(valid_604596, JString, required = false,
                                 default = nil)
  if valid_604596 != nil:
    section.add "X-Amz-Content-Sha256", valid_604596
  var valid_604597 = header.getOrDefault("X-Amz-Algorithm")
  valid_604597 = validateParameter(valid_604597, JString, required = false,
                                 default = nil)
  if valid_604597 != nil:
    section.add "X-Amz-Algorithm", valid_604597
  var valid_604598 = header.getOrDefault("X-Amz-Signature")
  valid_604598 = validateParameter(valid_604598, JString, required = false,
                                 default = nil)
  if valid_604598 != nil:
    section.add "X-Amz-Signature", valid_604598
  var valid_604599 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604599 = validateParameter(valid_604599, JString, required = false,
                                 default = nil)
  if valid_604599 != nil:
    section.add "X-Amz-SignedHeaders", valid_604599
  var valid_604600 = header.getOrDefault("X-Amz-Credential")
  valid_604600 = validateParameter(valid_604600, JString, required = false,
                                 default = nil)
  if valid_604600 != nil:
    section.add "X-Amz-Credential", valid_604600
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
  var valid_604601 = formData.getOrDefault("OptionsToRemove")
  valid_604601 = validateParameter(valid_604601, JArray, required = false,
                                 default = nil)
  if valid_604601 != nil:
    section.add "OptionsToRemove", valid_604601
  var valid_604602 = formData.getOrDefault("OptionSettings")
  valid_604602 = validateParameter(valid_604602, JArray, required = false,
                                 default = nil)
  if valid_604602 != nil:
    section.add "OptionSettings", valid_604602
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_604603 = formData.getOrDefault("ApplicationName")
  valid_604603 = validateParameter(valid_604603, JString, required = true,
                                 default = nil)
  if valid_604603 != nil:
    section.add "ApplicationName", valid_604603
  var valid_604604 = formData.getOrDefault("TemplateName")
  valid_604604 = validateParameter(valid_604604, JString, required = true,
                                 default = nil)
  if valid_604604 != nil:
    section.add "TemplateName", valid_604604
  var valid_604605 = formData.getOrDefault("Description")
  valid_604605 = validateParameter(valid_604605, JString, required = false,
                                 default = nil)
  if valid_604605 != nil:
    section.add "Description", valid_604605
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604606: Call_PostUpdateConfigurationTemplate_604589;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Updates the specified configuration template to have the specified properties or configuration option values.</p> <note> <p>If a property (for example, <code>ApplicationName</code>) is not provided, its value remains unchanged. To clear such properties, specify an empty string.</p> </note> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> </ul>
  ## 
  let valid = call_604606.validator(path, query, header, formData, body)
  let scheme = call_604606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604606.url(scheme.get, call_604606.host, call_604606.base,
                         call_604606.route, valid.getOrDefault("path"))
  result = hook(call_604606, url, valid)

proc call*(call_604607: Call_PostUpdateConfigurationTemplate_604589;
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
  var query_604608 = newJObject()
  var formData_604609 = newJObject()
  if OptionsToRemove != nil:
    formData_604609.add "OptionsToRemove", OptionsToRemove
  if OptionSettings != nil:
    formData_604609.add "OptionSettings", OptionSettings
  add(query_604608, "Action", newJString(Action))
  add(formData_604609, "ApplicationName", newJString(ApplicationName))
  add(formData_604609, "TemplateName", newJString(TemplateName))
  add(query_604608, "Version", newJString(Version))
  add(formData_604609, "Description", newJString(Description))
  result = call_604607.call(nil, query_604608, nil, formData_604609, nil)

var postUpdateConfigurationTemplate* = Call_PostUpdateConfigurationTemplate_604589(
    name: "postUpdateConfigurationTemplate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateConfigurationTemplate",
    validator: validate_PostUpdateConfigurationTemplate_604590, base: "/",
    url: url_PostUpdateConfigurationTemplate_604591,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateConfigurationTemplate_604569 = ref object of OpenApiRestCall_602434
proc url_GetUpdateConfigurationTemplate_604571(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUpdateConfigurationTemplate_604570(path: JsonNode;
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
  var valid_604572 = query.getOrDefault("ApplicationName")
  valid_604572 = validateParameter(valid_604572, JString, required = true,
                                 default = nil)
  if valid_604572 != nil:
    section.add "ApplicationName", valid_604572
  var valid_604573 = query.getOrDefault("Description")
  valid_604573 = validateParameter(valid_604573, JString, required = false,
                                 default = nil)
  if valid_604573 != nil:
    section.add "Description", valid_604573
  var valid_604574 = query.getOrDefault("OptionsToRemove")
  valid_604574 = validateParameter(valid_604574, JArray, required = false,
                                 default = nil)
  if valid_604574 != nil:
    section.add "OptionsToRemove", valid_604574
  var valid_604575 = query.getOrDefault("Action")
  valid_604575 = validateParameter(valid_604575, JString, required = true, default = newJString(
      "UpdateConfigurationTemplate"))
  if valid_604575 != nil:
    section.add "Action", valid_604575
  var valid_604576 = query.getOrDefault("TemplateName")
  valid_604576 = validateParameter(valid_604576, JString, required = true,
                                 default = nil)
  if valid_604576 != nil:
    section.add "TemplateName", valid_604576
  var valid_604577 = query.getOrDefault("OptionSettings")
  valid_604577 = validateParameter(valid_604577, JArray, required = false,
                                 default = nil)
  if valid_604577 != nil:
    section.add "OptionSettings", valid_604577
  var valid_604578 = query.getOrDefault("Version")
  valid_604578 = validateParameter(valid_604578, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604578 != nil:
    section.add "Version", valid_604578
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
  var valid_604579 = header.getOrDefault("X-Amz-Date")
  valid_604579 = validateParameter(valid_604579, JString, required = false,
                                 default = nil)
  if valid_604579 != nil:
    section.add "X-Amz-Date", valid_604579
  var valid_604580 = header.getOrDefault("X-Amz-Security-Token")
  valid_604580 = validateParameter(valid_604580, JString, required = false,
                                 default = nil)
  if valid_604580 != nil:
    section.add "X-Amz-Security-Token", valid_604580
  var valid_604581 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604581 = validateParameter(valid_604581, JString, required = false,
                                 default = nil)
  if valid_604581 != nil:
    section.add "X-Amz-Content-Sha256", valid_604581
  var valid_604582 = header.getOrDefault("X-Amz-Algorithm")
  valid_604582 = validateParameter(valid_604582, JString, required = false,
                                 default = nil)
  if valid_604582 != nil:
    section.add "X-Amz-Algorithm", valid_604582
  var valid_604583 = header.getOrDefault("X-Amz-Signature")
  valid_604583 = validateParameter(valid_604583, JString, required = false,
                                 default = nil)
  if valid_604583 != nil:
    section.add "X-Amz-Signature", valid_604583
  var valid_604584 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604584 = validateParameter(valid_604584, JString, required = false,
                                 default = nil)
  if valid_604584 != nil:
    section.add "X-Amz-SignedHeaders", valid_604584
  var valid_604585 = header.getOrDefault("X-Amz-Credential")
  valid_604585 = validateParameter(valid_604585, JString, required = false,
                                 default = nil)
  if valid_604585 != nil:
    section.add "X-Amz-Credential", valid_604585
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604586: Call_GetUpdateConfigurationTemplate_604569; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified configuration template to have the specified properties or configuration option values.</p> <note> <p>If a property (for example, <code>ApplicationName</code>) is not provided, its value remains unchanged. To clear such properties, specify an empty string.</p> </note> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> </ul>
  ## 
  let valid = call_604586.validator(path, query, header, formData, body)
  let scheme = call_604586.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604586.url(scheme.get, call_604586.host, call_604586.base,
                         call_604586.route, valid.getOrDefault("path"))
  result = hook(call_604586, url, valid)

proc call*(call_604587: Call_GetUpdateConfigurationTemplate_604569;
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
  var query_604588 = newJObject()
  add(query_604588, "ApplicationName", newJString(ApplicationName))
  add(query_604588, "Description", newJString(Description))
  if OptionsToRemove != nil:
    query_604588.add "OptionsToRemove", OptionsToRemove
  add(query_604588, "Action", newJString(Action))
  add(query_604588, "TemplateName", newJString(TemplateName))
  if OptionSettings != nil:
    query_604588.add "OptionSettings", OptionSettings
  add(query_604588, "Version", newJString(Version))
  result = call_604587.call(nil, query_604588, nil, nil, nil)

var getUpdateConfigurationTemplate* = Call_GetUpdateConfigurationTemplate_604569(
    name: "getUpdateConfigurationTemplate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateConfigurationTemplate",
    validator: validate_GetUpdateConfigurationTemplate_604570, base: "/",
    url: url_GetUpdateConfigurationTemplate_604571,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateEnvironment_604639 = ref object of OpenApiRestCall_602434
proc url_PostUpdateEnvironment_604641(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostUpdateEnvironment_604640(path: JsonNode; query: JsonNode;
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
  var valid_604642 = query.getOrDefault("Action")
  valid_604642 = validateParameter(valid_604642, JString, required = true,
                                 default = newJString("UpdateEnvironment"))
  if valid_604642 != nil:
    section.add "Action", valid_604642
  var valid_604643 = query.getOrDefault("Version")
  valid_604643 = validateParameter(valid_604643, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604643 != nil:
    section.add "Version", valid_604643
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
  var valid_604644 = header.getOrDefault("X-Amz-Date")
  valid_604644 = validateParameter(valid_604644, JString, required = false,
                                 default = nil)
  if valid_604644 != nil:
    section.add "X-Amz-Date", valid_604644
  var valid_604645 = header.getOrDefault("X-Amz-Security-Token")
  valid_604645 = validateParameter(valid_604645, JString, required = false,
                                 default = nil)
  if valid_604645 != nil:
    section.add "X-Amz-Security-Token", valid_604645
  var valid_604646 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604646 = validateParameter(valid_604646, JString, required = false,
                                 default = nil)
  if valid_604646 != nil:
    section.add "X-Amz-Content-Sha256", valid_604646
  var valid_604647 = header.getOrDefault("X-Amz-Algorithm")
  valid_604647 = validateParameter(valid_604647, JString, required = false,
                                 default = nil)
  if valid_604647 != nil:
    section.add "X-Amz-Algorithm", valid_604647
  var valid_604648 = header.getOrDefault("X-Amz-Signature")
  valid_604648 = validateParameter(valid_604648, JString, required = false,
                                 default = nil)
  if valid_604648 != nil:
    section.add "X-Amz-Signature", valid_604648
  var valid_604649 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604649 = validateParameter(valid_604649, JString, required = false,
                                 default = nil)
  if valid_604649 != nil:
    section.add "X-Amz-SignedHeaders", valid_604649
  var valid_604650 = header.getOrDefault("X-Amz-Credential")
  valid_604650 = validateParameter(valid_604650, JString, required = false,
                                 default = nil)
  if valid_604650 != nil:
    section.add "X-Amz-Credential", valid_604650
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
  var valid_604651 = formData.getOrDefault("Tier.Name")
  valid_604651 = validateParameter(valid_604651, JString, required = false,
                                 default = nil)
  if valid_604651 != nil:
    section.add "Tier.Name", valid_604651
  var valid_604652 = formData.getOrDefault("OptionsToRemove")
  valid_604652 = validateParameter(valid_604652, JArray, required = false,
                                 default = nil)
  if valid_604652 != nil:
    section.add "OptionsToRemove", valid_604652
  var valid_604653 = formData.getOrDefault("VersionLabel")
  valid_604653 = validateParameter(valid_604653, JString, required = false,
                                 default = nil)
  if valid_604653 != nil:
    section.add "VersionLabel", valid_604653
  var valid_604654 = formData.getOrDefault("OptionSettings")
  valid_604654 = validateParameter(valid_604654, JArray, required = false,
                                 default = nil)
  if valid_604654 != nil:
    section.add "OptionSettings", valid_604654
  var valid_604655 = formData.getOrDefault("GroupName")
  valid_604655 = validateParameter(valid_604655, JString, required = false,
                                 default = nil)
  if valid_604655 != nil:
    section.add "GroupName", valid_604655
  var valid_604656 = formData.getOrDefault("SolutionStackName")
  valid_604656 = validateParameter(valid_604656, JString, required = false,
                                 default = nil)
  if valid_604656 != nil:
    section.add "SolutionStackName", valid_604656
  var valid_604657 = formData.getOrDefault("EnvironmentId")
  valid_604657 = validateParameter(valid_604657, JString, required = false,
                                 default = nil)
  if valid_604657 != nil:
    section.add "EnvironmentId", valid_604657
  var valid_604658 = formData.getOrDefault("EnvironmentName")
  valid_604658 = validateParameter(valid_604658, JString, required = false,
                                 default = nil)
  if valid_604658 != nil:
    section.add "EnvironmentName", valid_604658
  var valid_604659 = formData.getOrDefault("Tier.Type")
  valid_604659 = validateParameter(valid_604659, JString, required = false,
                                 default = nil)
  if valid_604659 != nil:
    section.add "Tier.Type", valid_604659
  var valid_604660 = formData.getOrDefault("ApplicationName")
  valid_604660 = validateParameter(valid_604660, JString, required = false,
                                 default = nil)
  if valid_604660 != nil:
    section.add "ApplicationName", valid_604660
  var valid_604661 = formData.getOrDefault("PlatformArn")
  valid_604661 = validateParameter(valid_604661, JString, required = false,
                                 default = nil)
  if valid_604661 != nil:
    section.add "PlatformArn", valid_604661
  var valid_604662 = formData.getOrDefault("TemplateName")
  valid_604662 = validateParameter(valid_604662, JString, required = false,
                                 default = nil)
  if valid_604662 != nil:
    section.add "TemplateName", valid_604662
  var valid_604663 = formData.getOrDefault("Description")
  valid_604663 = validateParameter(valid_604663, JString, required = false,
                                 default = nil)
  if valid_604663 != nil:
    section.add "Description", valid_604663
  var valid_604664 = formData.getOrDefault("Tier.Version")
  valid_604664 = validateParameter(valid_604664, JString, required = false,
                                 default = nil)
  if valid_604664 != nil:
    section.add "Tier.Version", valid_604664
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604665: Call_PostUpdateEnvironment_604639; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the environment description, deploys a new application version, updates the configuration settings to an entirely new configuration template, or updates select configuration option values in the running environment.</p> <p> Attempting to update both the release and configuration is not allowed and AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. </p> <p> When updating the configuration settings to a new template or individual settings, a draft configuration is created and <a>DescribeConfigurationSettings</a> for this environment returns two setting descriptions with different <code>DeploymentStatus</code> values. </p>
  ## 
  let valid = call_604665.validator(path, query, header, formData, body)
  let scheme = call_604665.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604665.url(scheme.get, call_604665.host, call_604665.base,
                         call_604665.route, valid.getOrDefault("path"))
  result = hook(call_604665, url, valid)

proc call*(call_604666: Call_PostUpdateEnvironment_604639; TierName: string = "";
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
  var query_604667 = newJObject()
  var formData_604668 = newJObject()
  add(formData_604668, "Tier.Name", newJString(TierName))
  if OptionsToRemove != nil:
    formData_604668.add "OptionsToRemove", OptionsToRemove
  add(formData_604668, "VersionLabel", newJString(VersionLabel))
  if OptionSettings != nil:
    formData_604668.add "OptionSettings", OptionSettings
  add(formData_604668, "GroupName", newJString(GroupName))
  add(formData_604668, "SolutionStackName", newJString(SolutionStackName))
  add(formData_604668, "EnvironmentId", newJString(EnvironmentId))
  add(formData_604668, "EnvironmentName", newJString(EnvironmentName))
  add(formData_604668, "Tier.Type", newJString(TierType))
  add(query_604667, "Action", newJString(Action))
  add(formData_604668, "ApplicationName", newJString(ApplicationName))
  add(formData_604668, "PlatformArn", newJString(PlatformArn))
  add(formData_604668, "TemplateName", newJString(TemplateName))
  add(query_604667, "Version", newJString(Version))
  add(formData_604668, "Description", newJString(Description))
  add(formData_604668, "Tier.Version", newJString(TierVersion))
  result = call_604666.call(nil, query_604667, nil, formData_604668, nil)

var postUpdateEnvironment* = Call_PostUpdateEnvironment_604639(
    name: "postUpdateEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateEnvironment",
    validator: validate_PostUpdateEnvironment_604640, base: "/",
    url: url_PostUpdateEnvironment_604641, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateEnvironment_604610 = ref object of OpenApiRestCall_602434
proc url_GetUpdateEnvironment_604612(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUpdateEnvironment_604611(path: JsonNode; query: JsonNode;
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
  var valid_604613 = query.getOrDefault("Tier.Name")
  valid_604613 = validateParameter(valid_604613, JString, required = false,
                                 default = nil)
  if valid_604613 != nil:
    section.add "Tier.Name", valid_604613
  var valid_604614 = query.getOrDefault("VersionLabel")
  valid_604614 = validateParameter(valid_604614, JString, required = false,
                                 default = nil)
  if valid_604614 != nil:
    section.add "VersionLabel", valid_604614
  var valid_604615 = query.getOrDefault("ApplicationName")
  valid_604615 = validateParameter(valid_604615, JString, required = false,
                                 default = nil)
  if valid_604615 != nil:
    section.add "ApplicationName", valid_604615
  var valid_604616 = query.getOrDefault("Description")
  valid_604616 = validateParameter(valid_604616, JString, required = false,
                                 default = nil)
  if valid_604616 != nil:
    section.add "Description", valid_604616
  var valid_604617 = query.getOrDefault("OptionsToRemove")
  valid_604617 = validateParameter(valid_604617, JArray, required = false,
                                 default = nil)
  if valid_604617 != nil:
    section.add "OptionsToRemove", valid_604617
  var valid_604618 = query.getOrDefault("PlatformArn")
  valid_604618 = validateParameter(valid_604618, JString, required = false,
                                 default = nil)
  if valid_604618 != nil:
    section.add "PlatformArn", valid_604618
  var valid_604619 = query.getOrDefault("EnvironmentName")
  valid_604619 = validateParameter(valid_604619, JString, required = false,
                                 default = nil)
  if valid_604619 != nil:
    section.add "EnvironmentName", valid_604619
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604620 = query.getOrDefault("Action")
  valid_604620 = validateParameter(valid_604620, JString, required = true,
                                 default = newJString("UpdateEnvironment"))
  if valid_604620 != nil:
    section.add "Action", valid_604620
  var valid_604621 = query.getOrDefault("EnvironmentId")
  valid_604621 = validateParameter(valid_604621, JString, required = false,
                                 default = nil)
  if valid_604621 != nil:
    section.add "EnvironmentId", valid_604621
  var valid_604622 = query.getOrDefault("Tier.Version")
  valid_604622 = validateParameter(valid_604622, JString, required = false,
                                 default = nil)
  if valid_604622 != nil:
    section.add "Tier.Version", valid_604622
  var valid_604623 = query.getOrDefault("SolutionStackName")
  valid_604623 = validateParameter(valid_604623, JString, required = false,
                                 default = nil)
  if valid_604623 != nil:
    section.add "SolutionStackName", valid_604623
  var valid_604624 = query.getOrDefault("TemplateName")
  valid_604624 = validateParameter(valid_604624, JString, required = false,
                                 default = nil)
  if valid_604624 != nil:
    section.add "TemplateName", valid_604624
  var valid_604625 = query.getOrDefault("GroupName")
  valid_604625 = validateParameter(valid_604625, JString, required = false,
                                 default = nil)
  if valid_604625 != nil:
    section.add "GroupName", valid_604625
  var valid_604626 = query.getOrDefault("OptionSettings")
  valid_604626 = validateParameter(valid_604626, JArray, required = false,
                                 default = nil)
  if valid_604626 != nil:
    section.add "OptionSettings", valid_604626
  var valid_604627 = query.getOrDefault("Tier.Type")
  valid_604627 = validateParameter(valid_604627, JString, required = false,
                                 default = nil)
  if valid_604627 != nil:
    section.add "Tier.Type", valid_604627
  var valid_604628 = query.getOrDefault("Version")
  valid_604628 = validateParameter(valid_604628, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604628 != nil:
    section.add "Version", valid_604628
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
  var valid_604629 = header.getOrDefault("X-Amz-Date")
  valid_604629 = validateParameter(valid_604629, JString, required = false,
                                 default = nil)
  if valid_604629 != nil:
    section.add "X-Amz-Date", valid_604629
  var valid_604630 = header.getOrDefault("X-Amz-Security-Token")
  valid_604630 = validateParameter(valid_604630, JString, required = false,
                                 default = nil)
  if valid_604630 != nil:
    section.add "X-Amz-Security-Token", valid_604630
  var valid_604631 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604631 = validateParameter(valid_604631, JString, required = false,
                                 default = nil)
  if valid_604631 != nil:
    section.add "X-Amz-Content-Sha256", valid_604631
  var valid_604632 = header.getOrDefault("X-Amz-Algorithm")
  valid_604632 = validateParameter(valid_604632, JString, required = false,
                                 default = nil)
  if valid_604632 != nil:
    section.add "X-Amz-Algorithm", valid_604632
  var valid_604633 = header.getOrDefault("X-Amz-Signature")
  valid_604633 = validateParameter(valid_604633, JString, required = false,
                                 default = nil)
  if valid_604633 != nil:
    section.add "X-Amz-Signature", valid_604633
  var valid_604634 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604634 = validateParameter(valid_604634, JString, required = false,
                                 default = nil)
  if valid_604634 != nil:
    section.add "X-Amz-SignedHeaders", valid_604634
  var valid_604635 = header.getOrDefault("X-Amz-Credential")
  valid_604635 = validateParameter(valid_604635, JString, required = false,
                                 default = nil)
  if valid_604635 != nil:
    section.add "X-Amz-Credential", valid_604635
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604636: Call_GetUpdateEnvironment_604610; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the environment description, deploys a new application version, updates the configuration settings to an entirely new configuration template, or updates select configuration option values in the running environment.</p> <p> Attempting to update both the release and configuration is not allowed and AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. </p> <p> When updating the configuration settings to a new template or individual settings, a draft configuration is created and <a>DescribeConfigurationSettings</a> for this environment returns two setting descriptions with different <code>DeploymentStatus</code> values. </p>
  ## 
  let valid = call_604636.validator(path, query, header, formData, body)
  let scheme = call_604636.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604636.url(scheme.get, call_604636.host, call_604636.base,
                         call_604636.route, valid.getOrDefault("path"))
  result = hook(call_604636, url, valid)

proc call*(call_604637: Call_GetUpdateEnvironment_604610; TierName: string = "";
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
  var query_604638 = newJObject()
  add(query_604638, "Tier.Name", newJString(TierName))
  add(query_604638, "VersionLabel", newJString(VersionLabel))
  add(query_604638, "ApplicationName", newJString(ApplicationName))
  add(query_604638, "Description", newJString(Description))
  if OptionsToRemove != nil:
    query_604638.add "OptionsToRemove", OptionsToRemove
  add(query_604638, "PlatformArn", newJString(PlatformArn))
  add(query_604638, "EnvironmentName", newJString(EnvironmentName))
  add(query_604638, "Action", newJString(Action))
  add(query_604638, "EnvironmentId", newJString(EnvironmentId))
  add(query_604638, "Tier.Version", newJString(TierVersion))
  add(query_604638, "SolutionStackName", newJString(SolutionStackName))
  add(query_604638, "TemplateName", newJString(TemplateName))
  add(query_604638, "GroupName", newJString(GroupName))
  if OptionSettings != nil:
    query_604638.add "OptionSettings", OptionSettings
  add(query_604638, "Tier.Type", newJString(TierType))
  add(query_604638, "Version", newJString(Version))
  result = call_604637.call(nil, query_604638, nil, nil, nil)

var getUpdateEnvironment* = Call_GetUpdateEnvironment_604610(
    name: "getUpdateEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateEnvironment",
    validator: validate_GetUpdateEnvironment_604611, base: "/",
    url: url_GetUpdateEnvironment_604612, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateTagsForResource_604687 = ref object of OpenApiRestCall_602434
proc url_PostUpdateTagsForResource_604689(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostUpdateTagsForResource_604688(path: JsonNode; query: JsonNode;
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
  var valid_604690 = query.getOrDefault("Action")
  valid_604690 = validateParameter(valid_604690, JString, required = true,
                                 default = newJString("UpdateTagsForResource"))
  if valid_604690 != nil:
    section.add "Action", valid_604690
  var valid_604691 = query.getOrDefault("Version")
  valid_604691 = validateParameter(valid_604691, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604691 != nil:
    section.add "Version", valid_604691
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
  var valid_604692 = header.getOrDefault("X-Amz-Date")
  valid_604692 = validateParameter(valid_604692, JString, required = false,
                                 default = nil)
  if valid_604692 != nil:
    section.add "X-Amz-Date", valid_604692
  var valid_604693 = header.getOrDefault("X-Amz-Security-Token")
  valid_604693 = validateParameter(valid_604693, JString, required = false,
                                 default = nil)
  if valid_604693 != nil:
    section.add "X-Amz-Security-Token", valid_604693
  var valid_604694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604694 = validateParameter(valid_604694, JString, required = false,
                                 default = nil)
  if valid_604694 != nil:
    section.add "X-Amz-Content-Sha256", valid_604694
  var valid_604695 = header.getOrDefault("X-Amz-Algorithm")
  valid_604695 = validateParameter(valid_604695, JString, required = false,
                                 default = nil)
  if valid_604695 != nil:
    section.add "X-Amz-Algorithm", valid_604695
  var valid_604696 = header.getOrDefault("X-Amz-Signature")
  valid_604696 = validateParameter(valid_604696, JString, required = false,
                                 default = nil)
  if valid_604696 != nil:
    section.add "X-Amz-Signature", valid_604696
  var valid_604697 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604697 = validateParameter(valid_604697, JString, required = false,
                                 default = nil)
  if valid_604697 != nil:
    section.add "X-Amz-SignedHeaders", valid_604697
  var valid_604698 = header.getOrDefault("X-Amz-Credential")
  valid_604698 = validateParameter(valid_604698, JString, required = false,
                                 default = nil)
  if valid_604698 != nil:
    section.add "X-Amz-Credential", valid_604698
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagsToAdd: JArray
  ##            : <p>A list of tags to add or update.</p> <p>If a key of an existing tag is added, the tag's value is updated.</p>
  ##   TagsToRemove: JArray
  ##               : <p>A list of tag keys to remove.</p> <p>If a tag key doesn't exist, it is silently ignored.</p>
  ##   ResourceArn: JString (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce to be updated.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  section = newJObject()
  var valid_604699 = formData.getOrDefault("TagsToAdd")
  valid_604699 = validateParameter(valid_604699, JArray, required = false,
                                 default = nil)
  if valid_604699 != nil:
    section.add "TagsToAdd", valid_604699
  var valid_604700 = formData.getOrDefault("TagsToRemove")
  valid_604700 = validateParameter(valid_604700, JArray, required = false,
                                 default = nil)
  if valid_604700 != nil:
    section.add "TagsToRemove", valid_604700
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArn` field"
  var valid_604701 = formData.getOrDefault("ResourceArn")
  valid_604701 = validateParameter(valid_604701, JString, required = true,
                                 default = nil)
  if valid_604701 != nil:
    section.add "ResourceArn", valid_604701
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604702: Call_PostUpdateTagsForResource_604687; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Update the list of tags applied to an AWS Elastic Beanstalk resource. Two lists can be passed: <code>TagsToAdd</code> for tags to add or update, and <code>TagsToRemove</code>.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p> <p>If you create a custom IAM user policy to control permission to this operation, specify one of the following two virtual actions (or both) instead of the API operation name:</p> <dl> <dt>elasticbeanstalk:AddTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tags to add in the <code>TagsToAdd</code> parameter.</p> </dd> <dt>elasticbeanstalk:RemoveTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tag keys to remove in the <code>TagsToRemove</code> parameter.</p> </dd> </dl> <p>For details about creating a custom user policy, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/AWSHowTo.iam.managed-policies.html#AWSHowTo.iam.policies">Creating a Custom User Policy</a>.</p>
  ## 
  let valid = call_604702.validator(path, query, header, formData, body)
  let scheme = call_604702.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604702.url(scheme.get, call_604702.host, call_604702.base,
                         call_604702.route, valid.getOrDefault("path"))
  result = hook(call_604702, url, valid)

proc call*(call_604703: Call_PostUpdateTagsForResource_604687; ResourceArn: string;
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
  var query_604704 = newJObject()
  var formData_604705 = newJObject()
  if TagsToAdd != nil:
    formData_604705.add "TagsToAdd", TagsToAdd
  if TagsToRemove != nil:
    formData_604705.add "TagsToRemove", TagsToRemove
  add(query_604704, "Action", newJString(Action))
  add(formData_604705, "ResourceArn", newJString(ResourceArn))
  add(query_604704, "Version", newJString(Version))
  result = call_604703.call(nil, query_604704, nil, formData_604705, nil)

var postUpdateTagsForResource* = Call_PostUpdateTagsForResource_604687(
    name: "postUpdateTagsForResource", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateTagsForResource",
    validator: validate_PostUpdateTagsForResource_604688, base: "/",
    url: url_PostUpdateTagsForResource_604689,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateTagsForResource_604669 = ref object of OpenApiRestCall_602434
proc url_GetUpdateTagsForResource_604671(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUpdateTagsForResource_604670(path: JsonNode; query: JsonNode;
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
  var valid_604672 = query.getOrDefault("ResourceArn")
  valid_604672 = validateParameter(valid_604672, JString, required = true,
                                 default = nil)
  if valid_604672 != nil:
    section.add "ResourceArn", valid_604672
  var valid_604673 = query.getOrDefault("Action")
  valid_604673 = validateParameter(valid_604673, JString, required = true,
                                 default = newJString("UpdateTagsForResource"))
  if valid_604673 != nil:
    section.add "Action", valid_604673
  var valid_604674 = query.getOrDefault("TagsToAdd")
  valid_604674 = validateParameter(valid_604674, JArray, required = false,
                                 default = nil)
  if valid_604674 != nil:
    section.add "TagsToAdd", valid_604674
  var valid_604675 = query.getOrDefault("Version")
  valid_604675 = validateParameter(valid_604675, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604675 != nil:
    section.add "Version", valid_604675
  var valid_604676 = query.getOrDefault("TagsToRemove")
  valid_604676 = validateParameter(valid_604676, JArray, required = false,
                                 default = nil)
  if valid_604676 != nil:
    section.add "TagsToRemove", valid_604676
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604684: Call_GetUpdateTagsForResource_604669; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Update the list of tags applied to an AWS Elastic Beanstalk resource. Two lists can be passed: <code>TagsToAdd</code> for tags to add or update, and <code>TagsToRemove</code>.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p> <p>If you create a custom IAM user policy to control permission to this operation, specify one of the following two virtual actions (or both) instead of the API operation name:</p> <dl> <dt>elasticbeanstalk:AddTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tags to add in the <code>TagsToAdd</code> parameter.</p> </dd> <dt>elasticbeanstalk:RemoveTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tag keys to remove in the <code>TagsToRemove</code> parameter.</p> </dd> </dl> <p>For details about creating a custom user policy, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/AWSHowTo.iam.managed-policies.html#AWSHowTo.iam.policies">Creating a Custom User Policy</a>.</p>
  ## 
  let valid = call_604684.validator(path, query, header, formData, body)
  let scheme = call_604684.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604684.url(scheme.get, call_604684.host, call_604684.base,
                         call_604684.route, valid.getOrDefault("path"))
  result = hook(call_604684, url, valid)

proc call*(call_604685: Call_GetUpdateTagsForResource_604669; ResourceArn: string;
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
  var query_604686 = newJObject()
  add(query_604686, "ResourceArn", newJString(ResourceArn))
  add(query_604686, "Action", newJString(Action))
  if TagsToAdd != nil:
    query_604686.add "TagsToAdd", TagsToAdd
  add(query_604686, "Version", newJString(Version))
  if TagsToRemove != nil:
    query_604686.add "TagsToRemove", TagsToRemove
  result = call_604685.call(nil, query_604686, nil, nil, nil)

var getUpdateTagsForResource* = Call_GetUpdateTagsForResource_604669(
    name: "getUpdateTagsForResource", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateTagsForResource",
    validator: validate_GetUpdateTagsForResource_604670, base: "/",
    url: url_GetUpdateTagsForResource_604671, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostValidateConfigurationSettings_604725 = ref object of OpenApiRestCall_602434
proc url_PostValidateConfigurationSettings_604727(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostValidateConfigurationSettings_604726(path: JsonNode;
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
  var valid_604728 = query.getOrDefault("Action")
  valid_604728 = validateParameter(valid_604728, JString, required = true, default = newJString(
      "ValidateConfigurationSettings"))
  if valid_604728 != nil:
    section.add "Action", valid_604728
  var valid_604729 = query.getOrDefault("Version")
  valid_604729 = validateParameter(valid_604729, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604729 != nil:
    section.add "Version", valid_604729
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
  var valid_604730 = header.getOrDefault("X-Amz-Date")
  valid_604730 = validateParameter(valid_604730, JString, required = false,
                                 default = nil)
  if valid_604730 != nil:
    section.add "X-Amz-Date", valid_604730
  var valid_604731 = header.getOrDefault("X-Amz-Security-Token")
  valid_604731 = validateParameter(valid_604731, JString, required = false,
                                 default = nil)
  if valid_604731 != nil:
    section.add "X-Amz-Security-Token", valid_604731
  var valid_604732 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604732 = validateParameter(valid_604732, JString, required = false,
                                 default = nil)
  if valid_604732 != nil:
    section.add "X-Amz-Content-Sha256", valid_604732
  var valid_604733 = header.getOrDefault("X-Amz-Algorithm")
  valid_604733 = validateParameter(valid_604733, JString, required = false,
                                 default = nil)
  if valid_604733 != nil:
    section.add "X-Amz-Algorithm", valid_604733
  var valid_604734 = header.getOrDefault("X-Amz-Signature")
  valid_604734 = validateParameter(valid_604734, JString, required = false,
                                 default = nil)
  if valid_604734 != nil:
    section.add "X-Amz-Signature", valid_604734
  var valid_604735 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604735 = validateParameter(valid_604735, JString, required = false,
                                 default = nil)
  if valid_604735 != nil:
    section.add "X-Amz-SignedHeaders", valid_604735
  var valid_604736 = header.getOrDefault("X-Amz-Credential")
  valid_604736 = validateParameter(valid_604736, JString, required = false,
                                 default = nil)
  if valid_604736 != nil:
    section.add "X-Amz-Credential", valid_604736
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
  var valid_604737 = formData.getOrDefault("OptionSettings")
  valid_604737 = validateParameter(valid_604737, JArray, required = true, default = nil)
  if valid_604737 != nil:
    section.add "OptionSettings", valid_604737
  var valid_604738 = formData.getOrDefault("EnvironmentName")
  valid_604738 = validateParameter(valid_604738, JString, required = false,
                                 default = nil)
  if valid_604738 != nil:
    section.add "EnvironmentName", valid_604738
  var valid_604739 = formData.getOrDefault("ApplicationName")
  valid_604739 = validateParameter(valid_604739, JString, required = true,
                                 default = nil)
  if valid_604739 != nil:
    section.add "ApplicationName", valid_604739
  var valid_604740 = formData.getOrDefault("TemplateName")
  valid_604740 = validateParameter(valid_604740, JString, required = false,
                                 default = nil)
  if valid_604740 != nil:
    section.add "TemplateName", valid_604740
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604741: Call_PostValidateConfigurationSettings_604725;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Takes a set of configuration settings and either a configuration template or environment, and determines whether those values are valid.</p> <p>This action returns a list of messages indicating any errors or warnings associated with the selection of option values.</p>
  ## 
  let valid = call_604741.validator(path, query, header, formData, body)
  let scheme = call_604741.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604741.url(scheme.get, call_604741.host, call_604741.base,
                         call_604741.route, valid.getOrDefault("path"))
  result = hook(call_604741, url, valid)

proc call*(call_604742: Call_PostValidateConfigurationSettings_604725;
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
  var query_604743 = newJObject()
  var formData_604744 = newJObject()
  if OptionSettings != nil:
    formData_604744.add "OptionSettings", OptionSettings
  add(formData_604744, "EnvironmentName", newJString(EnvironmentName))
  add(query_604743, "Action", newJString(Action))
  add(formData_604744, "ApplicationName", newJString(ApplicationName))
  add(formData_604744, "TemplateName", newJString(TemplateName))
  add(query_604743, "Version", newJString(Version))
  result = call_604742.call(nil, query_604743, nil, formData_604744, nil)

var postValidateConfigurationSettings* = Call_PostValidateConfigurationSettings_604725(
    name: "postValidateConfigurationSettings", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ValidateConfigurationSettings",
    validator: validate_PostValidateConfigurationSettings_604726, base: "/",
    url: url_PostValidateConfigurationSettings_604727,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetValidateConfigurationSettings_604706 = ref object of OpenApiRestCall_602434
proc url_GetValidateConfigurationSettings_604708(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetValidateConfigurationSettings_604707(path: JsonNode;
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
  var valid_604709 = query.getOrDefault("ApplicationName")
  valid_604709 = validateParameter(valid_604709, JString, required = true,
                                 default = nil)
  if valid_604709 != nil:
    section.add "ApplicationName", valid_604709
  var valid_604710 = query.getOrDefault("EnvironmentName")
  valid_604710 = validateParameter(valid_604710, JString, required = false,
                                 default = nil)
  if valid_604710 != nil:
    section.add "EnvironmentName", valid_604710
  var valid_604711 = query.getOrDefault("Action")
  valid_604711 = validateParameter(valid_604711, JString, required = true, default = newJString(
      "ValidateConfigurationSettings"))
  if valid_604711 != nil:
    section.add "Action", valid_604711
  var valid_604712 = query.getOrDefault("TemplateName")
  valid_604712 = validateParameter(valid_604712, JString, required = false,
                                 default = nil)
  if valid_604712 != nil:
    section.add "TemplateName", valid_604712
  var valid_604713 = query.getOrDefault("OptionSettings")
  valid_604713 = validateParameter(valid_604713, JArray, required = true, default = nil)
  if valid_604713 != nil:
    section.add "OptionSettings", valid_604713
  var valid_604714 = query.getOrDefault("Version")
  valid_604714 = validateParameter(valid_604714, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_604714 != nil:
    section.add "Version", valid_604714
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
  var valid_604715 = header.getOrDefault("X-Amz-Date")
  valid_604715 = validateParameter(valid_604715, JString, required = false,
                                 default = nil)
  if valid_604715 != nil:
    section.add "X-Amz-Date", valid_604715
  var valid_604716 = header.getOrDefault("X-Amz-Security-Token")
  valid_604716 = validateParameter(valid_604716, JString, required = false,
                                 default = nil)
  if valid_604716 != nil:
    section.add "X-Amz-Security-Token", valid_604716
  var valid_604717 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604717 = validateParameter(valid_604717, JString, required = false,
                                 default = nil)
  if valid_604717 != nil:
    section.add "X-Amz-Content-Sha256", valid_604717
  var valid_604718 = header.getOrDefault("X-Amz-Algorithm")
  valid_604718 = validateParameter(valid_604718, JString, required = false,
                                 default = nil)
  if valid_604718 != nil:
    section.add "X-Amz-Algorithm", valid_604718
  var valid_604719 = header.getOrDefault("X-Amz-Signature")
  valid_604719 = validateParameter(valid_604719, JString, required = false,
                                 default = nil)
  if valid_604719 != nil:
    section.add "X-Amz-Signature", valid_604719
  var valid_604720 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604720 = validateParameter(valid_604720, JString, required = false,
                                 default = nil)
  if valid_604720 != nil:
    section.add "X-Amz-SignedHeaders", valid_604720
  var valid_604721 = header.getOrDefault("X-Amz-Credential")
  valid_604721 = validateParameter(valid_604721, JString, required = false,
                                 default = nil)
  if valid_604721 != nil:
    section.add "X-Amz-Credential", valid_604721
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604722: Call_GetValidateConfigurationSettings_604706;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Takes a set of configuration settings and either a configuration template or environment, and determines whether those values are valid.</p> <p>This action returns a list of messages indicating any errors or warnings associated with the selection of option values.</p>
  ## 
  let valid = call_604722.validator(path, query, header, formData, body)
  let scheme = call_604722.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604722.url(scheme.get, call_604722.host, call_604722.base,
                         call_604722.route, valid.getOrDefault("path"))
  result = hook(call_604722, url, valid)

proc call*(call_604723: Call_GetValidateConfigurationSettings_604706;
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
  var query_604724 = newJObject()
  add(query_604724, "ApplicationName", newJString(ApplicationName))
  add(query_604724, "EnvironmentName", newJString(EnvironmentName))
  add(query_604724, "Action", newJString(Action))
  add(query_604724, "TemplateName", newJString(TemplateName))
  if OptionSettings != nil:
    query_604724.add "OptionSettings", OptionSettings
  add(query_604724, "Version", newJString(Version))
  result = call_604723.call(nil, query_604724, nil, nil, nil)

var getValidateConfigurationSettings* = Call_GetValidateConfigurationSettings_604706(
    name: "getValidateConfigurationSettings", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ValidateConfigurationSettings",
    validator: validate_GetValidateConfigurationSettings_604707, base: "/",
    url: url_GetValidateConfigurationSettings_604708,
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)

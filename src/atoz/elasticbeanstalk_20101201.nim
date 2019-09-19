
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

  OpenApiRestCall_600427 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600427](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600427): Option[Scheme] {.used.} =
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
  Call_PostAbortEnvironmentUpdate_601041 = ref object of OpenApiRestCall_600427
proc url_PostAbortEnvironmentUpdate_601043(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostAbortEnvironmentUpdate_601042(path: JsonNode; query: JsonNode;
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
  var valid_601044 = query.getOrDefault("Action")
  valid_601044 = validateParameter(valid_601044, JString, required = true,
                                 default = newJString("AbortEnvironmentUpdate"))
  if valid_601044 != nil:
    section.add "Action", valid_601044
  var valid_601045 = query.getOrDefault("Version")
  valid_601045 = validateParameter(valid_601045, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601045 != nil:
    section.add "Version", valid_601045
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601046 = header.getOrDefault("X-Amz-Date")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-Date", valid_601046
  var valid_601047 = header.getOrDefault("X-Amz-Security-Token")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-Security-Token", valid_601047
  var valid_601048 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601048 = validateParameter(valid_601048, JString, required = false,
                                 default = nil)
  if valid_601048 != nil:
    section.add "X-Amz-Content-Sha256", valid_601048
  var valid_601049 = header.getOrDefault("X-Amz-Algorithm")
  valid_601049 = validateParameter(valid_601049, JString, required = false,
                                 default = nil)
  if valid_601049 != nil:
    section.add "X-Amz-Algorithm", valid_601049
  var valid_601050 = header.getOrDefault("X-Amz-Signature")
  valid_601050 = validateParameter(valid_601050, JString, required = false,
                                 default = nil)
  if valid_601050 != nil:
    section.add "X-Amz-Signature", valid_601050
  var valid_601051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601051 = validateParameter(valid_601051, JString, required = false,
                                 default = nil)
  if valid_601051 != nil:
    section.add "X-Amz-SignedHeaders", valid_601051
  var valid_601052 = header.getOrDefault("X-Amz-Credential")
  valid_601052 = validateParameter(valid_601052, JString, required = false,
                                 default = nil)
  if valid_601052 != nil:
    section.add "X-Amz-Credential", valid_601052
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentId: JString
  ##                : This specifies the ID of the environment with the in-progress update that you want to cancel.
  ##   EnvironmentName: JString
  ##                  : This specifies the name of the environment with the in-progress update that you want to cancel.
  section = newJObject()
  var valid_601053 = formData.getOrDefault("EnvironmentId")
  valid_601053 = validateParameter(valid_601053, JString, required = false,
                                 default = nil)
  if valid_601053 != nil:
    section.add "EnvironmentId", valid_601053
  var valid_601054 = formData.getOrDefault("EnvironmentName")
  valid_601054 = validateParameter(valid_601054, JString, required = false,
                                 default = nil)
  if valid_601054 != nil:
    section.add "EnvironmentName", valid_601054
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601055: Call_PostAbortEnvironmentUpdate_601041; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels in-progress environment configuration update or application version deployment.
  ## 
  let valid = call_601055.validator(path, query, header, formData, body)
  let scheme = call_601055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601055.url(scheme.get, call_601055.host, call_601055.base,
                         call_601055.route, valid.getOrDefault("path"))
  result = hook(call_601055, url, valid)

proc call*(call_601056: Call_PostAbortEnvironmentUpdate_601041;
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
  var query_601057 = newJObject()
  var formData_601058 = newJObject()
  add(formData_601058, "EnvironmentId", newJString(EnvironmentId))
  add(formData_601058, "EnvironmentName", newJString(EnvironmentName))
  add(query_601057, "Action", newJString(Action))
  add(query_601057, "Version", newJString(Version))
  result = call_601056.call(nil, query_601057, nil, formData_601058, nil)

var postAbortEnvironmentUpdate* = Call_PostAbortEnvironmentUpdate_601041(
    name: "postAbortEnvironmentUpdate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=AbortEnvironmentUpdate",
    validator: validate_PostAbortEnvironmentUpdate_601042, base: "/",
    url: url_PostAbortEnvironmentUpdate_601043,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAbortEnvironmentUpdate_600769 = ref object of OpenApiRestCall_600427
proc url_GetAbortEnvironmentUpdate_600771(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAbortEnvironmentUpdate_600770(path: JsonNode; query: JsonNode;
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
  var valid_600883 = query.getOrDefault("EnvironmentName")
  valid_600883 = validateParameter(valid_600883, JString, required = false,
                                 default = nil)
  if valid_600883 != nil:
    section.add "EnvironmentName", valid_600883
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600897 = query.getOrDefault("Action")
  valid_600897 = validateParameter(valid_600897, JString, required = true,
                                 default = newJString("AbortEnvironmentUpdate"))
  if valid_600897 != nil:
    section.add "Action", valid_600897
  var valid_600898 = query.getOrDefault("EnvironmentId")
  valid_600898 = validateParameter(valid_600898, JString, required = false,
                                 default = nil)
  if valid_600898 != nil:
    section.add "EnvironmentId", valid_600898
  var valid_600899 = query.getOrDefault("Version")
  valid_600899 = validateParameter(valid_600899, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600899 != nil:
    section.add "Version", valid_600899
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600900 = header.getOrDefault("X-Amz-Date")
  valid_600900 = validateParameter(valid_600900, JString, required = false,
                                 default = nil)
  if valid_600900 != nil:
    section.add "X-Amz-Date", valid_600900
  var valid_600901 = header.getOrDefault("X-Amz-Security-Token")
  valid_600901 = validateParameter(valid_600901, JString, required = false,
                                 default = nil)
  if valid_600901 != nil:
    section.add "X-Amz-Security-Token", valid_600901
  var valid_600902 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600902 = validateParameter(valid_600902, JString, required = false,
                                 default = nil)
  if valid_600902 != nil:
    section.add "X-Amz-Content-Sha256", valid_600902
  var valid_600903 = header.getOrDefault("X-Amz-Algorithm")
  valid_600903 = validateParameter(valid_600903, JString, required = false,
                                 default = nil)
  if valid_600903 != nil:
    section.add "X-Amz-Algorithm", valid_600903
  var valid_600904 = header.getOrDefault("X-Amz-Signature")
  valid_600904 = validateParameter(valid_600904, JString, required = false,
                                 default = nil)
  if valid_600904 != nil:
    section.add "X-Amz-Signature", valid_600904
  var valid_600905 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600905 = validateParameter(valid_600905, JString, required = false,
                                 default = nil)
  if valid_600905 != nil:
    section.add "X-Amz-SignedHeaders", valid_600905
  var valid_600906 = header.getOrDefault("X-Amz-Credential")
  valid_600906 = validateParameter(valid_600906, JString, required = false,
                                 default = nil)
  if valid_600906 != nil:
    section.add "X-Amz-Credential", valid_600906
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600929: Call_GetAbortEnvironmentUpdate_600769; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels in-progress environment configuration update or application version deployment.
  ## 
  let valid = call_600929.validator(path, query, header, formData, body)
  let scheme = call_600929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600929.url(scheme.get, call_600929.host, call_600929.base,
                         call_600929.route, valid.getOrDefault("path"))
  result = hook(call_600929, url, valid)

proc call*(call_601000: Call_GetAbortEnvironmentUpdate_600769;
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
  var query_601001 = newJObject()
  add(query_601001, "EnvironmentName", newJString(EnvironmentName))
  add(query_601001, "Action", newJString(Action))
  add(query_601001, "EnvironmentId", newJString(EnvironmentId))
  add(query_601001, "Version", newJString(Version))
  result = call_601000.call(nil, query_601001, nil, nil, nil)

var getAbortEnvironmentUpdate* = Call_GetAbortEnvironmentUpdate_600769(
    name: "getAbortEnvironmentUpdate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=AbortEnvironmentUpdate",
    validator: validate_GetAbortEnvironmentUpdate_600770, base: "/",
    url: url_GetAbortEnvironmentUpdate_600771,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostApplyEnvironmentManagedAction_601077 = ref object of OpenApiRestCall_600427
proc url_PostApplyEnvironmentManagedAction_601079(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostApplyEnvironmentManagedAction_601078(path: JsonNode;
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
  var valid_601080 = query.getOrDefault("Action")
  valid_601080 = validateParameter(valid_601080, JString, required = true, default = newJString(
      "ApplyEnvironmentManagedAction"))
  if valid_601080 != nil:
    section.add "Action", valid_601080
  var valid_601081 = query.getOrDefault("Version")
  valid_601081 = validateParameter(valid_601081, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601081 != nil:
    section.add "Version", valid_601081
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601082 = header.getOrDefault("X-Amz-Date")
  valid_601082 = validateParameter(valid_601082, JString, required = false,
                                 default = nil)
  if valid_601082 != nil:
    section.add "X-Amz-Date", valid_601082
  var valid_601083 = header.getOrDefault("X-Amz-Security-Token")
  valid_601083 = validateParameter(valid_601083, JString, required = false,
                                 default = nil)
  if valid_601083 != nil:
    section.add "X-Amz-Security-Token", valid_601083
  var valid_601084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601084 = validateParameter(valid_601084, JString, required = false,
                                 default = nil)
  if valid_601084 != nil:
    section.add "X-Amz-Content-Sha256", valid_601084
  var valid_601085 = header.getOrDefault("X-Amz-Algorithm")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "X-Amz-Algorithm", valid_601085
  var valid_601086 = header.getOrDefault("X-Amz-Signature")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = nil)
  if valid_601086 != nil:
    section.add "X-Amz-Signature", valid_601086
  var valid_601087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601087 = validateParameter(valid_601087, JString, required = false,
                                 default = nil)
  if valid_601087 != nil:
    section.add "X-Amz-SignedHeaders", valid_601087
  var valid_601088 = header.getOrDefault("X-Amz-Credential")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "X-Amz-Credential", valid_601088
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentId: JString
  ##                : The environment ID of the target environment.
  ##   EnvironmentName: JString
  ##                  : The name of the target environment.
  ##   ActionId: JString (required)
  ##           : The action ID of the scheduled managed action to execute.
  section = newJObject()
  var valid_601089 = formData.getOrDefault("EnvironmentId")
  valid_601089 = validateParameter(valid_601089, JString, required = false,
                                 default = nil)
  if valid_601089 != nil:
    section.add "EnvironmentId", valid_601089
  var valid_601090 = formData.getOrDefault("EnvironmentName")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "EnvironmentName", valid_601090
  assert formData != nil,
        "formData argument is necessary due to required `ActionId` field"
  var valid_601091 = formData.getOrDefault("ActionId")
  valid_601091 = validateParameter(valid_601091, JString, required = true,
                                 default = nil)
  if valid_601091 != nil:
    section.add "ActionId", valid_601091
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601092: Call_PostApplyEnvironmentManagedAction_601077;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Applies a scheduled managed action immediately. A managed action can be applied only if its status is <code>Scheduled</code>. Get the status and action ID of a managed action with <a>DescribeEnvironmentManagedActions</a>.
  ## 
  let valid = call_601092.validator(path, query, header, formData, body)
  let scheme = call_601092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601092.url(scheme.get, call_601092.host, call_601092.base,
                         call_601092.route, valid.getOrDefault("path"))
  result = hook(call_601092, url, valid)

proc call*(call_601093: Call_PostApplyEnvironmentManagedAction_601077;
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
  var query_601094 = newJObject()
  var formData_601095 = newJObject()
  add(formData_601095, "EnvironmentId", newJString(EnvironmentId))
  add(formData_601095, "EnvironmentName", newJString(EnvironmentName))
  add(query_601094, "Action", newJString(Action))
  add(formData_601095, "ActionId", newJString(ActionId))
  add(query_601094, "Version", newJString(Version))
  result = call_601093.call(nil, query_601094, nil, formData_601095, nil)

var postApplyEnvironmentManagedAction* = Call_PostApplyEnvironmentManagedAction_601077(
    name: "postApplyEnvironmentManagedAction", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ApplyEnvironmentManagedAction",
    validator: validate_PostApplyEnvironmentManagedAction_601078, base: "/",
    url: url_PostApplyEnvironmentManagedAction_601079,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplyEnvironmentManagedAction_601059 = ref object of OpenApiRestCall_600427
proc url_GetApplyEnvironmentManagedAction_601061(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetApplyEnvironmentManagedAction_601060(path: JsonNode;
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
  var valid_601062 = query.getOrDefault("EnvironmentName")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "EnvironmentName", valid_601062
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601063 = query.getOrDefault("Action")
  valid_601063 = validateParameter(valid_601063, JString, required = true, default = newJString(
      "ApplyEnvironmentManagedAction"))
  if valid_601063 != nil:
    section.add "Action", valid_601063
  var valid_601064 = query.getOrDefault("EnvironmentId")
  valid_601064 = validateParameter(valid_601064, JString, required = false,
                                 default = nil)
  if valid_601064 != nil:
    section.add "EnvironmentId", valid_601064
  var valid_601065 = query.getOrDefault("ActionId")
  valid_601065 = validateParameter(valid_601065, JString, required = true,
                                 default = nil)
  if valid_601065 != nil:
    section.add "ActionId", valid_601065
  var valid_601066 = query.getOrDefault("Version")
  valid_601066 = validateParameter(valid_601066, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601066 != nil:
    section.add "Version", valid_601066
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601067 = header.getOrDefault("X-Amz-Date")
  valid_601067 = validateParameter(valid_601067, JString, required = false,
                                 default = nil)
  if valid_601067 != nil:
    section.add "X-Amz-Date", valid_601067
  var valid_601068 = header.getOrDefault("X-Amz-Security-Token")
  valid_601068 = validateParameter(valid_601068, JString, required = false,
                                 default = nil)
  if valid_601068 != nil:
    section.add "X-Amz-Security-Token", valid_601068
  var valid_601069 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601069 = validateParameter(valid_601069, JString, required = false,
                                 default = nil)
  if valid_601069 != nil:
    section.add "X-Amz-Content-Sha256", valid_601069
  var valid_601070 = header.getOrDefault("X-Amz-Algorithm")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "X-Amz-Algorithm", valid_601070
  var valid_601071 = header.getOrDefault("X-Amz-Signature")
  valid_601071 = validateParameter(valid_601071, JString, required = false,
                                 default = nil)
  if valid_601071 != nil:
    section.add "X-Amz-Signature", valid_601071
  var valid_601072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601072 = validateParameter(valid_601072, JString, required = false,
                                 default = nil)
  if valid_601072 != nil:
    section.add "X-Amz-SignedHeaders", valid_601072
  var valid_601073 = header.getOrDefault("X-Amz-Credential")
  valid_601073 = validateParameter(valid_601073, JString, required = false,
                                 default = nil)
  if valid_601073 != nil:
    section.add "X-Amz-Credential", valid_601073
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601074: Call_GetApplyEnvironmentManagedAction_601059;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Applies a scheduled managed action immediately. A managed action can be applied only if its status is <code>Scheduled</code>. Get the status and action ID of a managed action with <a>DescribeEnvironmentManagedActions</a>.
  ## 
  let valid = call_601074.validator(path, query, header, formData, body)
  let scheme = call_601074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601074.url(scheme.get, call_601074.host, call_601074.base,
                         call_601074.route, valid.getOrDefault("path"))
  result = hook(call_601074, url, valid)

proc call*(call_601075: Call_GetApplyEnvironmentManagedAction_601059;
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
  var query_601076 = newJObject()
  add(query_601076, "EnvironmentName", newJString(EnvironmentName))
  add(query_601076, "Action", newJString(Action))
  add(query_601076, "EnvironmentId", newJString(EnvironmentId))
  add(query_601076, "ActionId", newJString(ActionId))
  add(query_601076, "Version", newJString(Version))
  result = call_601075.call(nil, query_601076, nil, nil, nil)

var getApplyEnvironmentManagedAction* = Call_GetApplyEnvironmentManagedAction_601059(
    name: "getApplyEnvironmentManagedAction", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ApplyEnvironmentManagedAction",
    validator: validate_GetApplyEnvironmentManagedAction_601060, base: "/",
    url: url_GetApplyEnvironmentManagedAction_601061,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCheckDNSAvailability_601112 = ref object of OpenApiRestCall_600427
proc url_PostCheckDNSAvailability_601114(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCheckDNSAvailability_601113(path: JsonNode; query: JsonNode;
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
  var valid_601115 = query.getOrDefault("Action")
  valid_601115 = validateParameter(valid_601115, JString, required = true,
                                 default = newJString("CheckDNSAvailability"))
  if valid_601115 != nil:
    section.add "Action", valid_601115
  var valid_601116 = query.getOrDefault("Version")
  valid_601116 = validateParameter(valid_601116, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601116 != nil:
    section.add "Version", valid_601116
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601117 = header.getOrDefault("X-Amz-Date")
  valid_601117 = validateParameter(valid_601117, JString, required = false,
                                 default = nil)
  if valid_601117 != nil:
    section.add "X-Amz-Date", valid_601117
  var valid_601118 = header.getOrDefault("X-Amz-Security-Token")
  valid_601118 = validateParameter(valid_601118, JString, required = false,
                                 default = nil)
  if valid_601118 != nil:
    section.add "X-Amz-Security-Token", valid_601118
  var valid_601119 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601119 = validateParameter(valid_601119, JString, required = false,
                                 default = nil)
  if valid_601119 != nil:
    section.add "X-Amz-Content-Sha256", valid_601119
  var valid_601120 = header.getOrDefault("X-Amz-Algorithm")
  valid_601120 = validateParameter(valid_601120, JString, required = false,
                                 default = nil)
  if valid_601120 != nil:
    section.add "X-Amz-Algorithm", valid_601120
  var valid_601121 = header.getOrDefault("X-Amz-Signature")
  valid_601121 = validateParameter(valid_601121, JString, required = false,
                                 default = nil)
  if valid_601121 != nil:
    section.add "X-Amz-Signature", valid_601121
  var valid_601122 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601122 = validateParameter(valid_601122, JString, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "X-Amz-SignedHeaders", valid_601122
  var valid_601123 = header.getOrDefault("X-Amz-Credential")
  valid_601123 = validateParameter(valid_601123, JString, required = false,
                                 default = nil)
  if valid_601123 != nil:
    section.add "X-Amz-Credential", valid_601123
  result.add "header", section
  ## parameters in `formData` object:
  ##   CNAMEPrefix: JString (required)
  ##              : The prefix used when this CNAME is reserved.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `CNAMEPrefix` field"
  var valid_601124 = formData.getOrDefault("CNAMEPrefix")
  valid_601124 = validateParameter(valid_601124, JString, required = true,
                                 default = nil)
  if valid_601124 != nil:
    section.add "CNAMEPrefix", valid_601124
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601125: Call_PostCheckDNSAvailability_601112; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Checks if the specified CNAME is available.
  ## 
  let valid = call_601125.validator(path, query, header, formData, body)
  let scheme = call_601125.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601125.url(scheme.get, call_601125.host, call_601125.base,
                         call_601125.route, valid.getOrDefault("path"))
  result = hook(call_601125, url, valid)

proc call*(call_601126: Call_PostCheckDNSAvailability_601112; CNAMEPrefix: string;
          Action: string = "CheckDNSAvailability"; Version: string = "2010-12-01"): Recallable =
  ## postCheckDNSAvailability
  ## Checks if the specified CNAME is available.
  ##   CNAMEPrefix: string (required)
  ##              : The prefix used when this CNAME is reserved.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601127 = newJObject()
  var formData_601128 = newJObject()
  add(formData_601128, "CNAMEPrefix", newJString(CNAMEPrefix))
  add(query_601127, "Action", newJString(Action))
  add(query_601127, "Version", newJString(Version))
  result = call_601126.call(nil, query_601127, nil, formData_601128, nil)

var postCheckDNSAvailability* = Call_PostCheckDNSAvailability_601112(
    name: "postCheckDNSAvailability", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CheckDNSAvailability",
    validator: validate_PostCheckDNSAvailability_601113, base: "/",
    url: url_PostCheckDNSAvailability_601114, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCheckDNSAvailability_601096 = ref object of OpenApiRestCall_600427
proc url_GetCheckDNSAvailability_601098(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCheckDNSAvailability_601097(path: JsonNode; query: JsonNode;
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
  var valid_601099 = query.getOrDefault("Action")
  valid_601099 = validateParameter(valid_601099, JString, required = true,
                                 default = newJString("CheckDNSAvailability"))
  if valid_601099 != nil:
    section.add "Action", valid_601099
  var valid_601100 = query.getOrDefault("Version")
  valid_601100 = validateParameter(valid_601100, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601100 != nil:
    section.add "Version", valid_601100
  var valid_601101 = query.getOrDefault("CNAMEPrefix")
  valid_601101 = validateParameter(valid_601101, JString, required = true,
                                 default = nil)
  if valid_601101 != nil:
    section.add "CNAMEPrefix", valid_601101
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601102 = header.getOrDefault("X-Amz-Date")
  valid_601102 = validateParameter(valid_601102, JString, required = false,
                                 default = nil)
  if valid_601102 != nil:
    section.add "X-Amz-Date", valid_601102
  var valid_601103 = header.getOrDefault("X-Amz-Security-Token")
  valid_601103 = validateParameter(valid_601103, JString, required = false,
                                 default = nil)
  if valid_601103 != nil:
    section.add "X-Amz-Security-Token", valid_601103
  var valid_601104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601104 = validateParameter(valid_601104, JString, required = false,
                                 default = nil)
  if valid_601104 != nil:
    section.add "X-Amz-Content-Sha256", valid_601104
  var valid_601105 = header.getOrDefault("X-Amz-Algorithm")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "X-Amz-Algorithm", valid_601105
  var valid_601106 = header.getOrDefault("X-Amz-Signature")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "X-Amz-Signature", valid_601106
  var valid_601107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "X-Amz-SignedHeaders", valid_601107
  var valid_601108 = header.getOrDefault("X-Amz-Credential")
  valid_601108 = validateParameter(valid_601108, JString, required = false,
                                 default = nil)
  if valid_601108 != nil:
    section.add "X-Amz-Credential", valid_601108
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601109: Call_GetCheckDNSAvailability_601096; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Checks if the specified CNAME is available.
  ## 
  let valid = call_601109.validator(path, query, header, formData, body)
  let scheme = call_601109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601109.url(scheme.get, call_601109.host, call_601109.base,
                         call_601109.route, valid.getOrDefault("path"))
  result = hook(call_601109, url, valid)

proc call*(call_601110: Call_GetCheckDNSAvailability_601096; CNAMEPrefix: string;
          Action: string = "CheckDNSAvailability"; Version: string = "2010-12-01"): Recallable =
  ## getCheckDNSAvailability
  ## Checks if the specified CNAME is available.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   CNAMEPrefix: string (required)
  ##              : The prefix used when this CNAME is reserved.
  var query_601111 = newJObject()
  add(query_601111, "Action", newJString(Action))
  add(query_601111, "Version", newJString(Version))
  add(query_601111, "CNAMEPrefix", newJString(CNAMEPrefix))
  result = call_601110.call(nil, query_601111, nil, nil, nil)

var getCheckDNSAvailability* = Call_GetCheckDNSAvailability_601096(
    name: "getCheckDNSAvailability", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CheckDNSAvailability",
    validator: validate_GetCheckDNSAvailability_601097, base: "/",
    url: url_GetCheckDNSAvailability_601098, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostComposeEnvironments_601147 = ref object of OpenApiRestCall_600427
proc url_PostComposeEnvironments_601149(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostComposeEnvironments_601148(path: JsonNode; query: JsonNode;
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
  var valid_601150 = query.getOrDefault("Action")
  valid_601150 = validateParameter(valid_601150, JString, required = true,
                                 default = newJString("ComposeEnvironments"))
  if valid_601150 != nil:
    section.add "Action", valid_601150
  var valid_601151 = query.getOrDefault("Version")
  valid_601151 = validateParameter(valid_601151, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601151 != nil:
    section.add "Version", valid_601151
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601152 = header.getOrDefault("X-Amz-Date")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Date", valid_601152
  var valid_601153 = header.getOrDefault("X-Amz-Security-Token")
  valid_601153 = validateParameter(valid_601153, JString, required = false,
                                 default = nil)
  if valid_601153 != nil:
    section.add "X-Amz-Security-Token", valid_601153
  var valid_601154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601154 = validateParameter(valid_601154, JString, required = false,
                                 default = nil)
  if valid_601154 != nil:
    section.add "X-Amz-Content-Sha256", valid_601154
  var valid_601155 = header.getOrDefault("X-Amz-Algorithm")
  valid_601155 = validateParameter(valid_601155, JString, required = false,
                                 default = nil)
  if valid_601155 != nil:
    section.add "X-Amz-Algorithm", valid_601155
  var valid_601156 = header.getOrDefault("X-Amz-Signature")
  valid_601156 = validateParameter(valid_601156, JString, required = false,
                                 default = nil)
  if valid_601156 != nil:
    section.add "X-Amz-Signature", valid_601156
  var valid_601157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601157 = validateParameter(valid_601157, JString, required = false,
                                 default = nil)
  if valid_601157 != nil:
    section.add "X-Amz-SignedHeaders", valid_601157
  var valid_601158 = header.getOrDefault("X-Amz-Credential")
  valid_601158 = validateParameter(valid_601158, JString, required = false,
                                 default = nil)
  if valid_601158 != nil:
    section.add "X-Amz-Credential", valid_601158
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
  var valid_601159 = formData.getOrDefault("GroupName")
  valid_601159 = validateParameter(valid_601159, JString, required = false,
                                 default = nil)
  if valid_601159 != nil:
    section.add "GroupName", valid_601159
  var valid_601160 = formData.getOrDefault("ApplicationName")
  valid_601160 = validateParameter(valid_601160, JString, required = false,
                                 default = nil)
  if valid_601160 != nil:
    section.add "ApplicationName", valid_601160
  var valid_601161 = formData.getOrDefault("VersionLabels")
  valid_601161 = validateParameter(valid_601161, JArray, required = false,
                                 default = nil)
  if valid_601161 != nil:
    section.add "VersionLabels", valid_601161
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601162: Call_PostComposeEnvironments_601147; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create or update a group of environments that each run a separate component of a single application. Takes a list of version labels that specify application source bundles for each of the environments to create or update. The name of each environment and other required information must be included in the source bundles in an environment manifest named <code>env.yaml</code>. See <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-mgmt-compose.html">Compose Environments</a> for details.
  ## 
  let valid = call_601162.validator(path, query, header, formData, body)
  let scheme = call_601162.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601162.url(scheme.get, call_601162.host, call_601162.base,
                         call_601162.route, valid.getOrDefault("path"))
  result = hook(call_601162, url, valid)

proc call*(call_601163: Call_PostComposeEnvironments_601147;
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
  var query_601164 = newJObject()
  var formData_601165 = newJObject()
  add(formData_601165, "GroupName", newJString(GroupName))
  add(query_601164, "Action", newJString(Action))
  add(formData_601165, "ApplicationName", newJString(ApplicationName))
  add(query_601164, "Version", newJString(Version))
  if VersionLabels != nil:
    formData_601165.add "VersionLabels", VersionLabels
  result = call_601163.call(nil, query_601164, nil, formData_601165, nil)

var postComposeEnvironments* = Call_PostComposeEnvironments_601147(
    name: "postComposeEnvironments", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ComposeEnvironments",
    validator: validate_PostComposeEnvironments_601148, base: "/",
    url: url_PostComposeEnvironments_601149, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetComposeEnvironments_601129 = ref object of OpenApiRestCall_600427
proc url_GetComposeEnvironments_601131(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetComposeEnvironments_601130(path: JsonNode; query: JsonNode;
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
  var valid_601132 = query.getOrDefault("ApplicationName")
  valid_601132 = validateParameter(valid_601132, JString, required = false,
                                 default = nil)
  if valid_601132 != nil:
    section.add "ApplicationName", valid_601132
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601133 = query.getOrDefault("Action")
  valid_601133 = validateParameter(valid_601133, JString, required = true,
                                 default = newJString("ComposeEnvironments"))
  if valid_601133 != nil:
    section.add "Action", valid_601133
  var valid_601134 = query.getOrDefault("GroupName")
  valid_601134 = validateParameter(valid_601134, JString, required = false,
                                 default = nil)
  if valid_601134 != nil:
    section.add "GroupName", valid_601134
  var valid_601135 = query.getOrDefault("VersionLabels")
  valid_601135 = validateParameter(valid_601135, JArray, required = false,
                                 default = nil)
  if valid_601135 != nil:
    section.add "VersionLabels", valid_601135
  var valid_601136 = query.getOrDefault("Version")
  valid_601136 = validateParameter(valid_601136, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601136 != nil:
    section.add "Version", valid_601136
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601137 = header.getOrDefault("X-Amz-Date")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "X-Amz-Date", valid_601137
  var valid_601138 = header.getOrDefault("X-Amz-Security-Token")
  valid_601138 = validateParameter(valid_601138, JString, required = false,
                                 default = nil)
  if valid_601138 != nil:
    section.add "X-Amz-Security-Token", valid_601138
  var valid_601139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601139 = validateParameter(valid_601139, JString, required = false,
                                 default = nil)
  if valid_601139 != nil:
    section.add "X-Amz-Content-Sha256", valid_601139
  var valid_601140 = header.getOrDefault("X-Amz-Algorithm")
  valid_601140 = validateParameter(valid_601140, JString, required = false,
                                 default = nil)
  if valid_601140 != nil:
    section.add "X-Amz-Algorithm", valid_601140
  var valid_601141 = header.getOrDefault("X-Amz-Signature")
  valid_601141 = validateParameter(valid_601141, JString, required = false,
                                 default = nil)
  if valid_601141 != nil:
    section.add "X-Amz-Signature", valid_601141
  var valid_601142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601142 = validateParameter(valid_601142, JString, required = false,
                                 default = nil)
  if valid_601142 != nil:
    section.add "X-Amz-SignedHeaders", valid_601142
  var valid_601143 = header.getOrDefault("X-Amz-Credential")
  valid_601143 = validateParameter(valid_601143, JString, required = false,
                                 default = nil)
  if valid_601143 != nil:
    section.add "X-Amz-Credential", valid_601143
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601144: Call_GetComposeEnvironments_601129; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create or update a group of environments that each run a separate component of a single application. Takes a list of version labels that specify application source bundles for each of the environments to create or update. The name of each environment and other required information must be included in the source bundles in an environment manifest named <code>env.yaml</code>. See <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-mgmt-compose.html">Compose Environments</a> for details.
  ## 
  let valid = call_601144.validator(path, query, header, formData, body)
  let scheme = call_601144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601144.url(scheme.get, call_601144.host, call_601144.base,
                         call_601144.route, valid.getOrDefault("path"))
  result = hook(call_601144, url, valid)

proc call*(call_601145: Call_GetComposeEnvironments_601129;
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
  var query_601146 = newJObject()
  add(query_601146, "ApplicationName", newJString(ApplicationName))
  add(query_601146, "Action", newJString(Action))
  add(query_601146, "GroupName", newJString(GroupName))
  if VersionLabels != nil:
    query_601146.add "VersionLabels", VersionLabels
  add(query_601146, "Version", newJString(Version))
  result = call_601145.call(nil, query_601146, nil, nil, nil)

var getComposeEnvironments* = Call_GetComposeEnvironments_601129(
    name: "getComposeEnvironments", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ComposeEnvironments",
    validator: validate_GetComposeEnvironments_601130, base: "/",
    url: url_GetComposeEnvironments_601131, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateApplication_601186 = ref object of OpenApiRestCall_600427
proc url_PostCreateApplication_601188(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateApplication_601187(path: JsonNode; query: JsonNode;
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
  var valid_601189 = query.getOrDefault("Action")
  valid_601189 = validateParameter(valid_601189, JString, required = true,
                                 default = newJString("CreateApplication"))
  if valid_601189 != nil:
    section.add "Action", valid_601189
  var valid_601190 = query.getOrDefault("Version")
  valid_601190 = validateParameter(valid_601190, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601190 != nil:
    section.add "Version", valid_601190
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601191 = header.getOrDefault("X-Amz-Date")
  valid_601191 = validateParameter(valid_601191, JString, required = false,
                                 default = nil)
  if valid_601191 != nil:
    section.add "X-Amz-Date", valid_601191
  var valid_601192 = header.getOrDefault("X-Amz-Security-Token")
  valid_601192 = validateParameter(valid_601192, JString, required = false,
                                 default = nil)
  if valid_601192 != nil:
    section.add "X-Amz-Security-Token", valid_601192
  var valid_601193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601193 = validateParameter(valid_601193, JString, required = false,
                                 default = nil)
  if valid_601193 != nil:
    section.add "X-Amz-Content-Sha256", valid_601193
  var valid_601194 = header.getOrDefault("X-Amz-Algorithm")
  valid_601194 = validateParameter(valid_601194, JString, required = false,
                                 default = nil)
  if valid_601194 != nil:
    section.add "X-Amz-Algorithm", valid_601194
  var valid_601195 = header.getOrDefault("X-Amz-Signature")
  valid_601195 = validateParameter(valid_601195, JString, required = false,
                                 default = nil)
  if valid_601195 != nil:
    section.add "X-Amz-Signature", valid_601195
  var valid_601196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601196 = validateParameter(valid_601196, JString, required = false,
                                 default = nil)
  if valid_601196 != nil:
    section.add "X-Amz-SignedHeaders", valid_601196
  var valid_601197 = header.getOrDefault("X-Amz-Credential")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "X-Amz-Credential", valid_601197
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
  var valid_601198 = formData.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_601198 = validateParameter(valid_601198, JString, required = false,
                                 default = nil)
  if valid_601198 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_601198
  var valid_601199 = formData.getOrDefault("Tags")
  valid_601199 = validateParameter(valid_601199, JArray, required = false,
                                 default = nil)
  if valid_601199 != nil:
    section.add "Tags", valid_601199
  var valid_601200 = formData.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_601200 = validateParameter(valid_601200, JString, required = false,
                                 default = nil)
  if valid_601200 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_601200
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_601201 = formData.getOrDefault("ApplicationName")
  valid_601201 = validateParameter(valid_601201, JString, required = true,
                                 default = nil)
  if valid_601201 != nil:
    section.add "ApplicationName", valid_601201
  var valid_601202 = formData.getOrDefault("Description")
  valid_601202 = validateParameter(valid_601202, JString, required = false,
                                 default = nil)
  if valid_601202 != nil:
    section.add "Description", valid_601202
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601203: Call_PostCreateApplication_601186; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates an application that has one configuration template named <code>default</code> and no application versions. 
  ## 
  let valid = call_601203.validator(path, query, header, formData, body)
  let scheme = call_601203.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601203.url(scheme.get, call_601203.host, call_601203.base,
                         call_601203.route, valid.getOrDefault("path"))
  result = hook(call_601203, url, valid)

proc call*(call_601204: Call_PostCreateApplication_601186; ApplicationName: string;
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
  var query_601205 = newJObject()
  var formData_601206 = newJObject()
  add(formData_601206, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  if Tags != nil:
    formData_601206.add "Tags", Tags
  add(formData_601206, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  add(query_601205, "Action", newJString(Action))
  add(formData_601206, "ApplicationName", newJString(ApplicationName))
  add(query_601205, "Version", newJString(Version))
  add(formData_601206, "Description", newJString(Description))
  result = call_601204.call(nil, query_601205, nil, formData_601206, nil)

var postCreateApplication* = Call_PostCreateApplication_601186(
    name: "postCreateApplication", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateApplication",
    validator: validate_PostCreateApplication_601187, base: "/",
    url: url_PostCreateApplication_601188, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateApplication_601166 = ref object of OpenApiRestCall_600427
proc url_GetCreateApplication_601168(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateApplication_601167(path: JsonNode; query: JsonNode;
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
  var valid_601169 = query.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_601169 = validateParameter(valid_601169, JString, required = false,
                                 default = nil)
  if valid_601169 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_601169
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_601170 = query.getOrDefault("ApplicationName")
  valid_601170 = validateParameter(valid_601170, JString, required = true,
                                 default = nil)
  if valid_601170 != nil:
    section.add "ApplicationName", valid_601170
  var valid_601171 = query.getOrDefault("Description")
  valid_601171 = validateParameter(valid_601171, JString, required = false,
                                 default = nil)
  if valid_601171 != nil:
    section.add "Description", valid_601171
  var valid_601172 = query.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_601172 = validateParameter(valid_601172, JString, required = false,
                                 default = nil)
  if valid_601172 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_601172
  var valid_601173 = query.getOrDefault("Tags")
  valid_601173 = validateParameter(valid_601173, JArray, required = false,
                                 default = nil)
  if valid_601173 != nil:
    section.add "Tags", valid_601173
  var valid_601174 = query.getOrDefault("Action")
  valid_601174 = validateParameter(valid_601174, JString, required = true,
                                 default = newJString("CreateApplication"))
  if valid_601174 != nil:
    section.add "Action", valid_601174
  var valid_601175 = query.getOrDefault("Version")
  valid_601175 = validateParameter(valid_601175, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601175 != nil:
    section.add "Version", valid_601175
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601176 = header.getOrDefault("X-Amz-Date")
  valid_601176 = validateParameter(valid_601176, JString, required = false,
                                 default = nil)
  if valid_601176 != nil:
    section.add "X-Amz-Date", valid_601176
  var valid_601177 = header.getOrDefault("X-Amz-Security-Token")
  valid_601177 = validateParameter(valid_601177, JString, required = false,
                                 default = nil)
  if valid_601177 != nil:
    section.add "X-Amz-Security-Token", valid_601177
  var valid_601178 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601178 = validateParameter(valid_601178, JString, required = false,
                                 default = nil)
  if valid_601178 != nil:
    section.add "X-Amz-Content-Sha256", valid_601178
  var valid_601179 = header.getOrDefault("X-Amz-Algorithm")
  valid_601179 = validateParameter(valid_601179, JString, required = false,
                                 default = nil)
  if valid_601179 != nil:
    section.add "X-Amz-Algorithm", valid_601179
  var valid_601180 = header.getOrDefault("X-Amz-Signature")
  valid_601180 = validateParameter(valid_601180, JString, required = false,
                                 default = nil)
  if valid_601180 != nil:
    section.add "X-Amz-Signature", valid_601180
  var valid_601181 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601181 = validateParameter(valid_601181, JString, required = false,
                                 default = nil)
  if valid_601181 != nil:
    section.add "X-Amz-SignedHeaders", valid_601181
  var valid_601182 = header.getOrDefault("X-Amz-Credential")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Credential", valid_601182
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601183: Call_GetCreateApplication_601166; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates an application that has one configuration template named <code>default</code> and no application versions. 
  ## 
  let valid = call_601183.validator(path, query, header, formData, body)
  let scheme = call_601183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601183.url(scheme.get, call_601183.host, call_601183.base,
                         call_601183.route, valid.getOrDefault("path"))
  result = hook(call_601183, url, valid)

proc call*(call_601184: Call_GetCreateApplication_601166; ApplicationName: string;
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
  var query_601185 = newJObject()
  add(query_601185, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  add(query_601185, "ApplicationName", newJString(ApplicationName))
  add(query_601185, "Description", newJString(Description))
  add(query_601185, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  if Tags != nil:
    query_601185.add "Tags", Tags
  add(query_601185, "Action", newJString(Action))
  add(query_601185, "Version", newJString(Version))
  result = call_601184.call(nil, query_601185, nil, nil, nil)

var getCreateApplication* = Call_GetCreateApplication_601166(
    name: "getCreateApplication", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateApplication",
    validator: validate_GetCreateApplication_601167, base: "/",
    url: url_GetCreateApplication_601168, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateApplicationVersion_601238 = ref object of OpenApiRestCall_600427
proc url_PostCreateApplicationVersion_601240(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateApplicationVersion_601239(path: JsonNode; query: JsonNode;
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
  var valid_601241 = query.getOrDefault("Action")
  valid_601241 = validateParameter(valid_601241, JString, required = true, default = newJString(
      "CreateApplicationVersion"))
  if valid_601241 != nil:
    section.add "Action", valid_601241
  var valid_601242 = query.getOrDefault("Version")
  valid_601242 = validateParameter(valid_601242, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601242 != nil:
    section.add "Version", valid_601242
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601243 = header.getOrDefault("X-Amz-Date")
  valid_601243 = validateParameter(valid_601243, JString, required = false,
                                 default = nil)
  if valid_601243 != nil:
    section.add "X-Amz-Date", valid_601243
  var valid_601244 = header.getOrDefault("X-Amz-Security-Token")
  valid_601244 = validateParameter(valid_601244, JString, required = false,
                                 default = nil)
  if valid_601244 != nil:
    section.add "X-Amz-Security-Token", valid_601244
  var valid_601245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601245 = validateParameter(valid_601245, JString, required = false,
                                 default = nil)
  if valid_601245 != nil:
    section.add "X-Amz-Content-Sha256", valid_601245
  var valid_601246 = header.getOrDefault("X-Amz-Algorithm")
  valid_601246 = validateParameter(valid_601246, JString, required = false,
                                 default = nil)
  if valid_601246 != nil:
    section.add "X-Amz-Algorithm", valid_601246
  var valid_601247 = header.getOrDefault("X-Amz-Signature")
  valid_601247 = validateParameter(valid_601247, JString, required = false,
                                 default = nil)
  if valid_601247 != nil:
    section.add "X-Amz-Signature", valid_601247
  var valid_601248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601248 = validateParameter(valid_601248, JString, required = false,
                                 default = nil)
  if valid_601248 != nil:
    section.add "X-Amz-SignedHeaders", valid_601248
  var valid_601249 = header.getOrDefault("X-Amz-Credential")
  valid_601249 = validateParameter(valid_601249, JString, required = false,
                                 default = nil)
  if valid_601249 != nil:
    section.add "X-Amz-Credential", valid_601249
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
  var valid_601250 = formData.getOrDefault("SourceBundle.S3Key")
  valid_601250 = validateParameter(valid_601250, JString, required = false,
                                 default = nil)
  if valid_601250 != nil:
    section.add "SourceBundle.S3Key", valid_601250
  assert formData != nil,
        "formData argument is necessary due to required `VersionLabel` field"
  var valid_601251 = formData.getOrDefault("VersionLabel")
  valid_601251 = validateParameter(valid_601251, JString, required = true,
                                 default = nil)
  if valid_601251 != nil:
    section.add "VersionLabel", valid_601251
  var valid_601252 = formData.getOrDefault("SourceBundle.S3Bucket")
  valid_601252 = validateParameter(valid_601252, JString, required = false,
                                 default = nil)
  if valid_601252 != nil:
    section.add "SourceBundle.S3Bucket", valid_601252
  var valid_601253 = formData.getOrDefault("BuildConfiguration.ComputeType")
  valid_601253 = validateParameter(valid_601253, JString, required = false,
                                 default = nil)
  if valid_601253 != nil:
    section.add "BuildConfiguration.ComputeType", valid_601253
  var valid_601254 = formData.getOrDefault("SourceBuildInformation.SourceType")
  valid_601254 = validateParameter(valid_601254, JString, required = false,
                                 default = nil)
  if valid_601254 != nil:
    section.add "SourceBuildInformation.SourceType", valid_601254
  var valid_601255 = formData.getOrDefault("Tags")
  valid_601255 = validateParameter(valid_601255, JArray, required = false,
                                 default = nil)
  if valid_601255 != nil:
    section.add "Tags", valid_601255
  var valid_601256 = formData.getOrDefault("AutoCreateApplication")
  valid_601256 = validateParameter(valid_601256, JBool, required = false, default = nil)
  if valid_601256 != nil:
    section.add "AutoCreateApplication", valid_601256
  var valid_601257 = formData.getOrDefault("SourceBuildInformation.SourceLocation")
  valid_601257 = validateParameter(valid_601257, JString, required = false,
                                 default = nil)
  if valid_601257 != nil:
    section.add "SourceBuildInformation.SourceLocation", valid_601257
  var valid_601258 = formData.getOrDefault("BuildConfiguration.CodeBuildServiceRole")
  valid_601258 = validateParameter(valid_601258, JString, required = false,
                                 default = nil)
  if valid_601258 != nil:
    section.add "BuildConfiguration.CodeBuildServiceRole", valid_601258
  var valid_601259 = formData.getOrDefault("ApplicationName")
  valid_601259 = validateParameter(valid_601259, JString, required = true,
                                 default = nil)
  if valid_601259 != nil:
    section.add "ApplicationName", valid_601259
  var valid_601260 = formData.getOrDefault("BuildConfiguration.ArtifactName")
  valid_601260 = validateParameter(valid_601260, JString, required = false,
                                 default = nil)
  if valid_601260 != nil:
    section.add "BuildConfiguration.ArtifactName", valid_601260
  var valid_601261 = formData.getOrDefault("BuildConfiguration.TimeoutInMinutes")
  valid_601261 = validateParameter(valid_601261, JString, required = false,
                                 default = nil)
  if valid_601261 != nil:
    section.add "BuildConfiguration.TimeoutInMinutes", valid_601261
  var valid_601262 = formData.getOrDefault("SourceBuildInformation.SourceRepository")
  valid_601262 = validateParameter(valid_601262, JString, required = false,
                                 default = nil)
  if valid_601262 != nil:
    section.add "SourceBuildInformation.SourceRepository", valid_601262
  var valid_601263 = formData.getOrDefault("Description")
  valid_601263 = validateParameter(valid_601263, JString, required = false,
                                 default = nil)
  if valid_601263 != nil:
    section.add "Description", valid_601263
  var valid_601264 = formData.getOrDefault("BuildConfiguration.Image")
  valid_601264 = validateParameter(valid_601264, JString, required = false,
                                 default = nil)
  if valid_601264 != nil:
    section.add "BuildConfiguration.Image", valid_601264
  var valid_601265 = formData.getOrDefault("Process")
  valid_601265 = validateParameter(valid_601265, JBool, required = false, default = nil)
  if valid_601265 != nil:
    section.add "Process", valid_601265
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601266: Call_PostCreateApplicationVersion_601238; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an application version for the specified application. You can create an application version from a source bundle in Amazon S3, a commit in AWS CodeCommit, or the output of an AWS CodeBuild build as follows:</p> <p>Specify a commit in an AWS CodeCommit repository with <code>SourceBuildInformation</code>.</p> <p>Specify a build in an AWS CodeBuild with <code>SourceBuildInformation</code> and <code>BuildConfiguration</code>.</p> <p>Specify a source bundle in S3 with <code>SourceBundle</code> </p> <p>Omit both <code>SourceBuildInformation</code> and <code>SourceBundle</code> to use the default sample application.</p> <note> <p>Once you create an application version with a specified Amazon S3 bucket and key location, you cannot change that Amazon S3 location. If you change the Amazon S3 location, you receive an exception when you attempt to launch an environment from the application version.</p> </note>
  ## 
  let valid = call_601266.validator(path, query, header, formData, body)
  let scheme = call_601266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601266.url(scheme.get, call_601266.host, call_601266.base,
                         call_601266.route, valid.getOrDefault("path"))
  result = hook(call_601266, url, valid)

proc call*(call_601267: Call_PostCreateApplicationVersion_601238;
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
  var query_601268 = newJObject()
  var formData_601269 = newJObject()
  add(formData_601269, "SourceBundle.S3Key", newJString(SourceBundleS3Key))
  add(formData_601269, "VersionLabel", newJString(VersionLabel))
  add(formData_601269, "SourceBundle.S3Bucket", newJString(SourceBundleS3Bucket))
  add(formData_601269, "BuildConfiguration.ComputeType",
      newJString(BuildConfigurationComputeType))
  add(formData_601269, "SourceBuildInformation.SourceType",
      newJString(SourceBuildInformationSourceType))
  if Tags != nil:
    formData_601269.add "Tags", Tags
  add(formData_601269, "AutoCreateApplication", newJBool(AutoCreateApplication))
  add(formData_601269, "SourceBuildInformation.SourceLocation",
      newJString(SourceBuildInformationSourceLocation))
  add(query_601268, "Action", newJString(Action))
  add(formData_601269, "BuildConfiguration.CodeBuildServiceRole",
      newJString(BuildConfigurationCodeBuildServiceRole))
  add(formData_601269, "ApplicationName", newJString(ApplicationName))
  add(formData_601269, "BuildConfiguration.ArtifactName",
      newJString(BuildConfigurationArtifactName))
  add(formData_601269, "BuildConfiguration.TimeoutInMinutes",
      newJString(BuildConfigurationTimeoutInMinutes))
  add(formData_601269, "SourceBuildInformation.SourceRepository",
      newJString(SourceBuildInformationSourceRepository))
  add(formData_601269, "Description", newJString(Description))
  add(formData_601269, "BuildConfiguration.Image",
      newJString(BuildConfigurationImage))
  add(formData_601269, "Process", newJBool(Process))
  add(query_601268, "Version", newJString(Version))
  result = call_601267.call(nil, query_601268, nil, formData_601269, nil)

var postCreateApplicationVersion* = Call_PostCreateApplicationVersion_601238(
    name: "postCreateApplicationVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateApplicationVersion",
    validator: validate_PostCreateApplicationVersion_601239, base: "/",
    url: url_PostCreateApplicationVersion_601240,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateApplicationVersion_601207 = ref object of OpenApiRestCall_600427
proc url_GetCreateApplicationVersion_601209(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateApplicationVersion_601208(path: JsonNode; query: JsonNode;
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
  var valid_601210 = query.getOrDefault("BuildConfiguration.TimeoutInMinutes")
  valid_601210 = validateParameter(valid_601210, JString, required = false,
                                 default = nil)
  if valid_601210 != nil:
    section.add "BuildConfiguration.TimeoutInMinutes", valid_601210
  var valid_601211 = query.getOrDefault("SourceBundle.S3Bucket")
  valid_601211 = validateParameter(valid_601211, JString, required = false,
                                 default = nil)
  if valid_601211 != nil:
    section.add "SourceBundle.S3Bucket", valid_601211
  var valid_601212 = query.getOrDefault("BuildConfiguration.ComputeType")
  valid_601212 = validateParameter(valid_601212, JString, required = false,
                                 default = nil)
  if valid_601212 != nil:
    section.add "BuildConfiguration.ComputeType", valid_601212
  assert query != nil,
        "query argument is necessary due to required `VersionLabel` field"
  var valid_601213 = query.getOrDefault("VersionLabel")
  valid_601213 = validateParameter(valid_601213, JString, required = true,
                                 default = nil)
  if valid_601213 != nil:
    section.add "VersionLabel", valid_601213
  var valid_601214 = query.getOrDefault("BuildConfiguration.ArtifactName")
  valid_601214 = validateParameter(valid_601214, JString, required = false,
                                 default = nil)
  if valid_601214 != nil:
    section.add "BuildConfiguration.ArtifactName", valid_601214
  var valid_601215 = query.getOrDefault("ApplicationName")
  valid_601215 = validateParameter(valid_601215, JString, required = true,
                                 default = nil)
  if valid_601215 != nil:
    section.add "ApplicationName", valid_601215
  var valid_601216 = query.getOrDefault("Description")
  valid_601216 = validateParameter(valid_601216, JString, required = false,
                                 default = nil)
  if valid_601216 != nil:
    section.add "Description", valid_601216
  var valid_601217 = query.getOrDefault("BuildConfiguration.Image")
  valid_601217 = validateParameter(valid_601217, JString, required = false,
                                 default = nil)
  if valid_601217 != nil:
    section.add "BuildConfiguration.Image", valid_601217
  var valid_601218 = query.getOrDefault("SourceBuildInformation.SourceLocation")
  valid_601218 = validateParameter(valid_601218, JString, required = false,
                                 default = nil)
  if valid_601218 != nil:
    section.add "SourceBuildInformation.SourceLocation", valid_601218
  var valid_601219 = query.getOrDefault("SourceBundle.S3Key")
  valid_601219 = validateParameter(valid_601219, JString, required = false,
                                 default = nil)
  if valid_601219 != nil:
    section.add "SourceBundle.S3Key", valid_601219
  var valid_601220 = query.getOrDefault("Tags")
  valid_601220 = validateParameter(valid_601220, JArray, required = false,
                                 default = nil)
  if valid_601220 != nil:
    section.add "Tags", valid_601220
  var valid_601221 = query.getOrDefault("AutoCreateApplication")
  valid_601221 = validateParameter(valid_601221, JBool, required = false, default = nil)
  if valid_601221 != nil:
    section.add "AutoCreateApplication", valid_601221
  var valid_601222 = query.getOrDefault("Action")
  valid_601222 = validateParameter(valid_601222, JString, required = true, default = newJString(
      "CreateApplicationVersion"))
  if valid_601222 != nil:
    section.add "Action", valid_601222
  var valid_601223 = query.getOrDefault("SourceBuildInformation.SourceType")
  valid_601223 = validateParameter(valid_601223, JString, required = false,
                                 default = nil)
  if valid_601223 != nil:
    section.add "SourceBuildInformation.SourceType", valid_601223
  var valid_601224 = query.getOrDefault("BuildConfiguration.CodeBuildServiceRole")
  valid_601224 = validateParameter(valid_601224, JString, required = false,
                                 default = nil)
  if valid_601224 != nil:
    section.add "BuildConfiguration.CodeBuildServiceRole", valid_601224
  var valid_601225 = query.getOrDefault("Process")
  valid_601225 = validateParameter(valid_601225, JBool, required = false, default = nil)
  if valid_601225 != nil:
    section.add "Process", valid_601225
  var valid_601226 = query.getOrDefault("SourceBuildInformation.SourceRepository")
  valid_601226 = validateParameter(valid_601226, JString, required = false,
                                 default = nil)
  if valid_601226 != nil:
    section.add "SourceBuildInformation.SourceRepository", valid_601226
  var valid_601227 = query.getOrDefault("Version")
  valid_601227 = validateParameter(valid_601227, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601227 != nil:
    section.add "Version", valid_601227
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601228 = header.getOrDefault("X-Amz-Date")
  valid_601228 = validateParameter(valid_601228, JString, required = false,
                                 default = nil)
  if valid_601228 != nil:
    section.add "X-Amz-Date", valid_601228
  var valid_601229 = header.getOrDefault("X-Amz-Security-Token")
  valid_601229 = validateParameter(valid_601229, JString, required = false,
                                 default = nil)
  if valid_601229 != nil:
    section.add "X-Amz-Security-Token", valid_601229
  var valid_601230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601230 = validateParameter(valid_601230, JString, required = false,
                                 default = nil)
  if valid_601230 != nil:
    section.add "X-Amz-Content-Sha256", valid_601230
  var valid_601231 = header.getOrDefault("X-Amz-Algorithm")
  valid_601231 = validateParameter(valid_601231, JString, required = false,
                                 default = nil)
  if valid_601231 != nil:
    section.add "X-Amz-Algorithm", valid_601231
  var valid_601232 = header.getOrDefault("X-Amz-Signature")
  valid_601232 = validateParameter(valid_601232, JString, required = false,
                                 default = nil)
  if valid_601232 != nil:
    section.add "X-Amz-Signature", valid_601232
  var valid_601233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601233 = validateParameter(valid_601233, JString, required = false,
                                 default = nil)
  if valid_601233 != nil:
    section.add "X-Amz-SignedHeaders", valid_601233
  var valid_601234 = header.getOrDefault("X-Amz-Credential")
  valid_601234 = validateParameter(valid_601234, JString, required = false,
                                 default = nil)
  if valid_601234 != nil:
    section.add "X-Amz-Credential", valid_601234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601235: Call_GetCreateApplicationVersion_601207; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an application version for the specified application. You can create an application version from a source bundle in Amazon S3, a commit in AWS CodeCommit, or the output of an AWS CodeBuild build as follows:</p> <p>Specify a commit in an AWS CodeCommit repository with <code>SourceBuildInformation</code>.</p> <p>Specify a build in an AWS CodeBuild with <code>SourceBuildInformation</code> and <code>BuildConfiguration</code>.</p> <p>Specify a source bundle in S3 with <code>SourceBundle</code> </p> <p>Omit both <code>SourceBuildInformation</code> and <code>SourceBundle</code> to use the default sample application.</p> <note> <p>Once you create an application version with a specified Amazon S3 bucket and key location, you cannot change that Amazon S3 location. If you change the Amazon S3 location, you receive an exception when you attempt to launch an environment from the application version.</p> </note>
  ## 
  let valid = call_601235.validator(path, query, header, formData, body)
  let scheme = call_601235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601235.url(scheme.get, call_601235.host, call_601235.base,
                         call_601235.route, valid.getOrDefault("path"))
  result = hook(call_601235, url, valid)

proc call*(call_601236: Call_GetCreateApplicationVersion_601207;
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
  var query_601237 = newJObject()
  add(query_601237, "BuildConfiguration.TimeoutInMinutes",
      newJString(BuildConfigurationTimeoutInMinutes))
  add(query_601237, "SourceBundle.S3Bucket", newJString(SourceBundleS3Bucket))
  add(query_601237, "BuildConfiguration.ComputeType",
      newJString(BuildConfigurationComputeType))
  add(query_601237, "VersionLabel", newJString(VersionLabel))
  add(query_601237, "BuildConfiguration.ArtifactName",
      newJString(BuildConfigurationArtifactName))
  add(query_601237, "ApplicationName", newJString(ApplicationName))
  add(query_601237, "Description", newJString(Description))
  add(query_601237, "BuildConfiguration.Image",
      newJString(BuildConfigurationImage))
  add(query_601237, "SourceBuildInformation.SourceLocation",
      newJString(SourceBuildInformationSourceLocation))
  add(query_601237, "SourceBundle.S3Key", newJString(SourceBundleS3Key))
  if Tags != nil:
    query_601237.add "Tags", Tags
  add(query_601237, "AutoCreateApplication", newJBool(AutoCreateApplication))
  add(query_601237, "Action", newJString(Action))
  add(query_601237, "SourceBuildInformation.SourceType",
      newJString(SourceBuildInformationSourceType))
  add(query_601237, "BuildConfiguration.CodeBuildServiceRole",
      newJString(BuildConfigurationCodeBuildServiceRole))
  add(query_601237, "Process", newJBool(Process))
  add(query_601237, "SourceBuildInformation.SourceRepository",
      newJString(SourceBuildInformationSourceRepository))
  add(query_601237, "Version", newJString(Version))
  result = call_601236.call(nil, query_601237, nil, nil, nil)

var getCreateApplicationVersion* = Call_GetCreateApplicationVersion_601207(
    name: "getCreateApplicationVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateApplicationVersion",
    validator: validate_GetCreateApplicationVersion_601208, base: "/",
    url: url_GetCreateApplicationVersion_601209,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateConfigurationTemplate_601295 = ref object of OpenApiRestCall_600427
proc url_PostCreateConfigurationTemplate_601297(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateConfigurationTemplate_601296(path: JsonNode;
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
  var valid_601298 = query.getOrDefault("Action")
  valid_601298 = validateParameter(valid_601298, JString, required = true, default = newJString(
      "CreateConfigurationTemplate"))
  if valid_601298 != nil:
    section.add "Action", valid_601298
  var valid_601299 = query.getOrDefault("Version")
  valid_601299 = validateParameter(valid_601299, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601299 != nil:
    section.add "Version", valid_601299
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601300 = header.getOrDefault("X-Amz-Date")
  valid_601300 = validateParameter(valid_601300, JString, required = false,
                                 default = nil)
  if valid_601300 != nil:
    section.add "X-Amz-Date", valid_601300
  var valid_601301 = header.getOrDefault("X-Amz-Security-Token")
  valid_601301 = validateParameter(valid_601301, JString, required = false,
                                 default = nil)
  if valid_601301 != nil:
    section.add "X-Amz-Security-Token", valid_601301
  var valid_601302 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601302 = validateParameter(valid_601302, JString, required = false,
                                 default = nil)
  if valid_601302 != nil:
    section.add "X-Amz-Content-Sha256", valid_601302
  var valid_601303 = header.getOrDefault("X-Amz-Algorithm")
  valid_601303 = validateParameter(valid_601303, JString, required = false,
                                 default = nil)
  if valid_601303 != nil:
    section.add "X-Amz-Algorithm", valid_601303
  var valid_601304 = header.getOrDefault("X-Amz-Signature")
  valid_601304 = validateParameter(valid_601304, JString, required = false,
                                 default = nil)
  if valid_601304 != nil:
    section.add "X-Amz-Signature", valid_601304
  var valid_601305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601305 = validateParameter(valid_601305, JString, required = false,
                                 default = nil)
  if valid_601305 != nil:
    section.add "X-Amz-SignedHeaders", valid_601305
  var valid_601306 = header.getOrDefault("X-Amz-Credential")
  valid_601306 = validateParameter(valid_601306, JString, required = false,
                                 default = nil)
  if valid_601306 != nil:
    section.add "X-Amz-Credential", valid_601306
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
  var valid_601307 = formData.getOrDefault("OptionSettings")
  valid_601307 = validateParameter(valid_601307, JArray, required = false,
                                 default = nil)
  if valid_601307 != nil:
    section.add "OptionSettings", valid_601307
  var valid_601308 = formData.getOrDefault("Tags")
  valid_601308 = validateParameter(valid_601308, JArray, required = false,
                                 default = nil)
  if valid_601308 != nil:
    section.add "Tags", valid_601308
  var valid_601309 = formData.getOrDefault("SolutionStackName")
  valid_601309 = validateParameter(valid_601309, JString, required = false,
                                 default = nil)
  if valid_601309 != nil:
    section.add "SolutionStackName", valid_601309
  var valid_601310 = formData.getOrDefault("SourceConfiguration.ApplicationName")
  valid_601310 = validateParameter(valid_601310, JString, required = false,
                                 default = nil)
  if valid_601310 != nil:
    section.add "SourceConfiguration.ApplicationName", valid_601310
  var valid_601311 = formData.getOrDefault("EnvironmentId")
  valid_601311 = validateParameter(valid_601311, JString, required = false,
                                 default = nil)
  if valid_601311 != nil:
    section.add "EnvironmentId", valid_601311
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_601312 = formData.getOrDefault("ApplicationName")
  valid_601312 = validateParameter(valid_601312, JString, required = true,
                                 default = nil)
  if valid_601312 != nil:
    section.add "ApplicationName", valid_601312
  var valid_601313 = formData.getOrDefault("PlatformArn")
  valid_601313 = validateParameter(valid_601313, JString, required = false,
                                 default = nil)
  if valid_601313 != nil:
    section.add "PlatformArn", valid_601313
  var valid_601314 = formData.getOrDefault("TemplateName")
  valid_601314 = validateParameter(valid_601314, JString, required = true,
                                 default = nil)
  if valid_601314 != nil:
    section.add "TemplateName", valid_601314
  var valid_601315 = formData.getOrDefault("Description")
  valid_601315 = validateParameter(valid_601315, JString, required = false,
                                 default = nil)
  if valid_601315 != nil:
    section.add "Description", valid_601315
  var valid_601316 = formData.getOrDefault("SourceConfiguration.TemplateName")
  valid_601316 = validateParameter(valid_601316, JString, required = false,
                                 default = nil)
  if valid_601316 != nil:
    section.add "SourceConfiguration.TemplateName", valid_601316
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601317: Call_PostCreateConfigurationTemplate_601295;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a configuration template. Templates are associated with a specific application and are used to deploy different versions of the application with the same configuration settings.</p> <p>Templates aren't associated with any environment. The <code>EnvironmentName</code> response element is always <code>null</code>.</p> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> <li> <p> <a>DescribeConfigurationSettings</a> </p> </li> <li> <p> <a>ListAvailableSolutionStacks</a> </p> </li> </ul>
  ## 
  let valid = call_601317.validator(path, query, header, formData, body)
  let scheme = call_601317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601317.url(scheme.get, call_601317.host, call_601317.base,
                         call_601317.route, valid.getOrDefault("path"))
  result = hook(call_601317, url, valid)

proc call*(call_601318: Call_PostCreateConfigurationTemplate_601295;
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
  var query_601319 = newJObject()
  var formData_601320 = newJObject()
  if OptionSettings != nil:
    formData_601320.add "OptionSettings", OptionSettings
  if Tags != nil:
    formData_601320.add "Tags", Tags
  add(formData_601320, "SolutionStackName", newJString(SolutionStackName))
  add(formData_601320, "SourceConfiguration.ApplicationName",
      newJString(SourceConfigurationApplicationName))
  add(formData_601320, "EnvironmentId", newJString(EnvironmentId))
  add(query_601319, "Action", newJString(Action))
  add(formData_601320, "ApplicationName", newJString(ApplicationName))
  add(formData_601320, "PlatformArn", newJString(PlatformArn))
  add(formData_601320, "TemplateName", newJString(TemplateName))
  add(query_601319, "Version", newJString(Version))
  add(formData_601320, "Description", newJString(Description))
  add(formData_601320, "SourceConfiguration.TemplateName",
      newJString(SourceConfigurationTemplateName))
  result = call_601318.call(nil, query_601319, nil, formData_601320, nil)

var postCreateConfigurationTemplate* = Call_PostCreateConfigurationTemplate_601295(
    name: "postCreateConfigurationTemplate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateConfigurationTemplate",
    validator: validate_PostCreateConfigurationTemplate_601296, base: "/",
    url: url_PostCreateConfigurationTemplate_601297,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateConfigurationTemplate_601270 = ref object of OpenApiRestCall_600427
proc url_GetCreateConfigurationTemplate_601272(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateConfigurationTemplate_601271(path: JsonNode;
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
  var valid_601273 = query.getOrDefault("SourceConfiguration.ApplicationName")
  valid_601273 = validateParameter(valid_601273, JString, required = false,
                                 default = nil)
  if valid_601273 != nil:
    section.add "SourceConfiguration.ApplicationName", valid_601273
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_601274 = query.getOrDefault("ApplicationName")
  valid_601274 = validateParameter(valid_601274, JString, required = true,
                                 default = nil)
  if valid_601274 != nil:
    section.add "ApplicationName", valid_601274
  var valid_601275 = query.getOrDefault("Description")
  valid_601275 = validateParameter(valid_601275, JString, required = false,
                                 default = nil)
  if valid_601275 != nil:
    section.add "Description", valid_601275
  var valid_601276 = query.getOrDefault("PlatformArn")
  valid_601276 = validateParameter(valid_601276, JString, required = false,
                                 default = nil)
  if valid_601276 != nil:
    section.add "PlatformArn", valid_601276
  var valid_601277 = query.getOrDefault("Tags")
  valid_601277 = validateParameter(valid_601277, JArray, required = false,
                                 default = nil)
  if valid_601277 != nil:
    section.add "Tags", valid_601277
  var valid_601278 = query.getOrDefault("Action")
  valid_601278 = validateParameter(valid_601278, JString, required = true, default = newJString(
      "CreateConfigurationTemplate"))
  if valid_601278 != nil:
    section.add "Action", valid_601278
  var valid_601279 = query.getOrDefault("SolutionStackName")
  valid_601279 = validateParameter(valid_601279, JString, required = false,
                                 default = nil)
  if valid_601279 != nil:
    section.add "SolutionStackName", valid_601279
  var valid_601280 = query.getOrDefault("EnvironmentId")
  valid_601280 = validateParameter(valid_601280, JString, required = false,
                                 default = nil)
  if valid_601280 != nil:
    section.add "EnvironmentId", valid_601280
  var valid_601281 = query.getOrDefault("TemplateName")
  valid_601281 = validateParameter(valid_601281, JString, required = true,
                                 default = nil)
  if valid_601281 != nil:
    section.add "TemplateName", valid_601281
  var valid_601282 = query.getOrDefault("OptionSettings")
  valid_601282 = validateParameter(valid_601282, JArray, required = false,
                                 default = nil)
  if valid_601282 != nil:
    section.add "OptionSettings", valid_601282
  var valid_601283 = query.getOrDefault("Version")
  valid_601283 = validateParameter(valid_601283, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601283 != nil:
    section.add "Version", valid_601283
  var valid_601284 = query.getOrDefault("SourceConfiguration.TemplateName")
  valid_601284 = validateParameter(valid_601284, JString, required = false,
                                 default = nil)
  if valid_601284 != nil:
    section.add "SourceConfiguration.TemplateName", valid_601284
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601285 = header.getOrDefault("X-Amz-Date")
  valid_601285 = validateParameter(valid_601285, JString, required = false,
                                 default = nil)
  if valid_601285 != nil:
    section.add "X-Amz-Date", valid_601285
  var valid_601286 = header.getOrDefault("X-Amz-Security-Token")
  valid_601286 = validateParameter(valid_601286, JString, required = false,
                                 default = nil)
  if valid_601286 != nil:
    section.add "X-Amz-Security-Token", valid_601286
  var valid_601287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601287 = validateParameter(valid_601287, JString, required = false,
                                 default = nil)
  if valid_601287 != nil:
    section.add "X-Amz-Content-Sha256", valid_601287
  var valid_601288 = header.getOrDefault("X-Amz-Algorithm")
  valid_601288 = validateParameter(valid_601288, JString, required = false,
                                 default = nil)
  if valid_601288 != nil:
    section.add "X-Amz-Algorithm", valid_601288
  var valid_601289 = header.getOrDefault("X-Amz-Signature")
  valid_601289 = validateParameter(valid_601289, JString, required = false,
                                 default = nil)
  if valid_601289 != nil:
    section.add "X-Amz-Signature", valid_601289
  var valid_601290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601290 = validateParameter(valid_601290, JString, required = false,
                                 default = nil)
  if valid_601290 != nil:
    section.add "X-Amz-SignedHeaders", valid_601290
  var valid_601291 = header.getOrDefault("X-Amz-Credential")
  valid_601291 = validateParameter(valid_601291, JString, required = false,
                                 default = nil)
  if valid_601291 != nil:
    section.add "X-Amz-Credential", valid_601291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601292: Call_GetCreateConfigurationTemplate_601270; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a configuration template. Templates are associated with a specific application and are used to deploy different versions of the application with the same configuration settings.</p> <p>Templates aren't associated with any environment. The <code>EnvironmentName</code> response element is always <code>null</code>.</p> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> <li> <p> <a>DescribeConfigurationSettings</a> </p> </li> <li> <p> <a>ListAvailableSolutionStacks</a> </p> </li> </ul>
  ## 
  let valid = call_601292.validator(path, query, header, formData, body)
  let scheme = call_601292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601292.url(scheme.get, call_601292.host, call_601292.base,
                         call_601292.route, valid.getOrDefault("path"))
  result = hook(call_601292, url, valid)

proc call*(call_601293: Call_GetCreateConfigurationTemplate_601270;
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
  var query_601294 = newJObject()
  add(query_601294, "SourceConfiguration.ApplicationName",
      newJString(SourceConfigurationApplicationName))
  add(query_601294, "ApplicationName", newJString(ApplicationName))
  add(query_601294, "Description", newJString(Description))
  add(query_601294, "PlatformArn", newJString(PlatformArn))
  if Tags != nil:
    query_601294.add "Tags", Tags
  add(query_601294, "Action", newJString(Action))
  add(query_601294, "SolutionStackName", newJString(SolutionStackName))
  add(query_601294, "EnvironmentId", newJString(EnvironmentId))
  add(query_601294, "TemplateName", newJString(TemplateName))
  if OptionSettings != nil:
    query_601294.add "OptionSettings", OptionSettings
  add(query_601294, "Version", newJString(Version))
  add(query_601294, "SourceConfiguration.TemplateName",
      newJString(SourceConfigurationTemplateName))
  result = call_601293.call(nil, query_601294, nil, nil, nil)

var getCreateConfigurationTemplate* = Call_GetCreateConfigurationTemplate_601270(
    name: "getCreateConfigurationTemplate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateConfigurationTemplate",
    validator: validate_GetCreateConfigurationTemplate_601271, base: "/",
    url: url_GetCreateConfigurationTemplate_601272,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEnvironment_601351 = ref object of OpenApiRestCall_600427
proc url_PostCreateEnvironment_601353(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateEnvironment_601352(path: JsonNode; query: JsonNode;
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
  var valid_601354 = query.getOrDefault("Action")
  valid_601354 = validateParameter(valid_601354, JString, required = true,
                                 default = newJString("CreateEnvironment"))
  if valid_601354 != nil:
    section.add "Action", valid_601354
  var valid_601355 = query.getOrDefault("Version")
  valid_601355 = validateParameter(valid_601355, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601355 != nil:
    section.add "Version", valid_601355
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601356 = header.getOrDefault("X-Amz-Date")
  valid_601356 = validateParameter(valid_601356, JString, required = false,
                                 default = nil)
  if valid_601356 != nil:
    section.add "X-Amz-Date", valid_601356
  var valid_601357 = header.getOrDefault("X-Amz-Security-Token")
  valid_601357 = validateParameter(valid_601357, JString, required = false,
                                 default = nil)
  if valid_601357 != nil:
    section.add "X-Amz-Security-Token", valid_601357
  var valid_601358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601358 = validateParameter(valid_601358, JString, required = false,
                                 default = nil)
  if valid_601358 != nil:
    section.add "X-Amz-Content-Sha256", valid_601358
  var valid_601359 = header.getOrDefault("X-Amz-Algorithm")
  valid_601359 = validateParameter(valid_601359, JString, required = false,
                                 default = nil)
  if valid_601359 != nil:
    section.add "X-Amz-Algorithm", valid_601359
  var valid_601360 = header.getOrDefault("X-Amz-Signature")
  valid_601360 = validateParameter(valid_601360, JString, required = false,
                                 default = nil)
  if valid_601360 != nil:
    section.add "X-Amz-Signature", valid_601360
  var valid_601361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601361 = validateParameter(valid_601361, JString, required = false,
                                 default = nil)
  if valid_601361 != nil:
    section.add "X-Amz-SignedHeaders", valid_601361
  var valid_601362 = header.getOrDefault("X-Amz-Credential")
  valid_601362 = validateParameter(valid_601362, JString, required = false,
                                 default = nil)
  if valid_601362 != nil:
    section.add "X-Amz-Credential", valid_601362
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
  var valid_601363 = formData.getOrDefault("Tier.Name")
  valid_601363 = validateParameter(valid_601363, JString, required = false,
                                 default = nil)
  if valid_601363 != nil:
    section.add "Tier.Name", valid_601363
  var valid_601364 = formData.getOrDefault("OptionsToRemove")
  valid_601364 = validateParameter(valid_601364, JArray, required = false,
                                 default = nil)
  if valid_601364 != nil:
    section.add "OptionsToRemove", valid_601364
  var valid_601365 = formData.getOrDefault("VersionLabel")
  valid_601365 = validateParameter(valid_601365, JString, required = false,
                                 default = nil)
  if valid_601365 != nil:
    section.add "VersionLabel", valid_601365
  var valid_601366 = formData.getOrDefault("OptionSettings")
  valid_601366 = validateParameter(valid_601366, JArray, required = false,
                                 default = nil)
  if valid_601366 != nil:
    section.add "OptionSettings", valid_601366
  var valid_601367 = formData.getOrDefault("GroupName")
  valid_601367 = validateParameter(valid_601367, JString, required = false,
                                 default = nil)
  if valid_601367 != nil:
    section.add "GroupName", valid_601367
  var valid_601368 = formData.getOrDefault("Tags")
  valid_601368 = validateParameter(valid_601368, JArray, required = false,
                                 default = nil)
  if valid_601368 != nil:
    section.add "Tags", valid_601368
  var valid_601369 = formData.getOrDefault("CNAMEPrefix")
  valid_601369 = validateParameter(valid_601369, JString, required = false,
                                 default = nil)
  if valid_601369 != nil:
    section.add "CNAMEPrefix", valid_601369
  var valid_601370 = formData.getOrDefault("SolutionStackName")
  valid_601370 = validateParameter(valid_601370, JString, required = false,
                                 default = nil)
  if valid_601370 != nil:
    section.add "SolutionStackName", valid_601370
  var valid_601371 = formData.getOrDefault("EnvironmentName")
  valid_601371 = validateParameter(valid_601371, JString, required = false,
                                 default = nil)
  if valid_601371 != nil:
    section.add "EnvironmentName", valid_601371
  var valid_601372 = formData.getOrDefault("Tier.Type")
  valid_601372 = validateParameter(valid_601372, JString, required = false,
                                 default = nil)
  if valid_601372 != nil:
    section.add "Tier.Type", valid_601372
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_601373 = formData.getOrDefault("ApplicationName")
  valid_601373 = validateParameter(valid_601373, JString, required = true,
                                 default = nil)
  if valid_601373 != nil:
    section.add "ApplicationName", valid_601373
  var valid_601374 = formData.getOrDefault("PlatformArn")
  valid_601374 = validateParameter(valid_601374, JString, required = false,
                                 default = nil)
  if valid_601374 != nil:
    section.add "PlatformArn", valid_601374
  var valid_601375 = formData.getOrDefault("TemplateName")
  valid_601375 = validateParameter(valid_601375, JString, required = false,
                                 default = nil)
  if valid_601375 != nil:
    section.add "TemplateName", valid_601375
  var valid_601376 = formData.getOrDefault("Description")
  valid_601376 = validateParameter(valid_601376, JString, required = false,
                                 default = nil)
  if valid_601376 != nil:
    section.add "Description", valid_601376
  var valid_601377 = formData.getOrDefault("Tier.Version")
  valid_601377 = validateParameter(valid_601377, JString, required = false,
                                 default = nil)
  if valid_601377 != nil:
    section.add "Tier.Version", valid_601377
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601378: Call_PostCreateEnvironment_601351; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Launches an environment for the specified application using the specified configuration.
  ## 
  let valid = call_601378.validator(path, query, header, formData, body)
  let scheme = call_601378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601378.url(scheme.get, call_601378.host, call_601378.base,
                         call_601378.route, valid.getOrDefault("path"))
  result = hook(call_601378, url, valid)

proc call*(call_601379: Call_PostCreateEnvironment_601351; ApplicationName: string;
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
  var query_601380 = newJObject()
  var formData_601381 = newJObject()
  add(formData_601381, "Tier.Name", newJString(TierName))
  if OptionsToRemove != nil:
    formData_601381.add "OptionsToRemove", OptionsToRemove
  add(formData_601381, "VersionLabel", newJString(VersionLabel))
  if OptionSettings != nil:
    formData_601381.add "OptionSettings", OptionSettings
  add(formData_601381, "GroupName", newJString(GroupName))
  if Tags != nil:
    formData_601381.add "Tags", Tags
  add(formData_601381, "CNAMEPrefix", newJString(CNAMEPrefix))
  add(formData_601381, "SolutionStackName", newJString(SolutionStackName))
  add(formData_601381, "EnvironmentName", newJString(EnvironmentName))
  add(formData_601381, "Tier.Type", newJString(TierType))
  add(query_601380, "Action", newJString(Action))
  add(formData_601381, "ApplicationName", newJString(ApplicationName))
  add(formData_601381, "PlatformArn", newJString(PlatformArn))
  add(formData_601381, "TemplateName", newJString(TemplateName))
  add(query_601380, "Version", newJString(Version))
  add(formData_601381, "Description", newJString(Description))
  add(formData_601381, "Tier.Version", newJString(TierVersion))
  result = call_601379.call(nil, query_601380, nil, formData_601381, nil)

var postCreateEnvironment* = Call_PostCreateEnvironment_601351(
    name: "postCreateEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateEnvironment",
    validator: validate_PostCreateEnvironment_601352, base: "/",
    url: url_PostCreateEnvironment_601353, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEnvironment_601321 = ref object of OpenApiRestCall_600427
proc url_GetCreateEnvironment_601323(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateEnvironment_601322(path: JsonNode; query: JsonNode;
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
  var valid_601324 = query.getOrDefault("Tier.Name")
  valid_601324 = validateParameter(valid_601324, JString, required = false,
                                 default = nil)
  if valid_601324 != nil:
    section.add "Tier.Name", valid_601324
  var valid_601325 = query.getOrDefault("VersionLabel")
  valid_601325 = validateParameter(valid_601325, JString, required = false,
                                 default = nil)
  if valid_601325 != nil:
    section.add "VersionLabel", valid_601325
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_601326 = query.getOrDefault("ApplicationName")
  valid_601326 = validateParameter(valid_601326, JString, required = true,
                                 default = nil)
  if valid_601326 != nil:
    section.add "ApplicationName", valid_601326
  var valid_601327 = query.getOrDefault("Description")
  valid_601327 = validateParameter(valid_601327, JString, required = false,
                                 default = nil)
  if valid_601327 != nil:
    section.add "Description", valid_601327
  var valid_601328 = query.getOrDefault("OptionsToRemove")
  valid_601328 = validateParameter(valid_601328, JArray, required = false,
                                 default = nil)
  if valid_601328 != nil:
    section.add "OptionsToRemove", valid_601328
  var valid_601329 = query.getOrDefault("PlatformArn")
  valid_601329 = validateParameter(valid_601329, JString, required = false,
                                 default = nil)
  if valid_601329 != nil:
    section.add "PlatformArn", valid_601329
  var valid_601330 = query.getOrDefault("Tags")
  valid_601330 = validateParameter(valid_601330, JArray, required = false,
                                 default = nil)
  if valid_601330 != nil:
    section.add "Tags", valid_601330
  var valid_601331 = query.getOrDefault("EnvironmentName")
  valid_601331 = validateParameter(valid_601331, JString, required = false,
                                 default = nil)
  if valid_601331 != nil:
    section.add "EnvironmentName", valid_601331
  var valid_601332 = query.getOrDefault("Action")
  valid_601332 = validateParameter(valid_601332, JString, required = true,
                                 default = newJString("CreateEnvironment"))
  if valid_601332 != nil:
    section.add "Action", valid_601332
  var valid_601333 = query.getOrDefault("SolutionStackName")
  valid_601333 = validateParameter(valid_601333, JString, required = false,
                                 default = nil)
  if valid_601333 != nil:
    section.add "SolutionStackName", valid_601333
  var valid_601334 = query.getOrDefault("Tier.Version")
  valid_601334 = validateParameter(valid_601334, JString, required = false,
                                 default = nil)
  if valid_601334 != nil:
    section.add "Tier.Version", valid_601334
  var valid_601335 = query.getOrDefault("TemplateName")
  valid_601335 = validateParameter(valid_601335, JString, required = false,
                                 default = nil)
  if valid_601335 != nil:
    section.add "TemplateName", valid_601335
  var valid_601336 = query.getOrDefault("GroupName")
  valid_601336 = validateParameter(valid_601336, JString, required = false,
                                 default = nil)
  if valid_601336 != nil:
    section.add "GroupName", valid_601336
  var valid_601337 = query.getOrDefault("OptionSettings")
  valid_601337 = validateParameter(valid_601337, JArray, required = false,
                                 default = nil)
  if valid_601337 != nil:
    section.add "OptionSettings", valid_601337
  var valid_601338 = query.getOrDefault("Tier.Type")
  valid_601338 = validateParameter(valid_601338, JString, required = false,
                                 default = nil)
  if valid_601338 != nil:
    section.add "Tier.Type", valid_601338
  var valid_601339 = query.getOrDefault("Version")
  valid_601339 = validateParameter(valid_601339, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601339 != nil:
    section.add "Version", valid_601339
  var valid_601340 = query.getOrDefault("CNAMEPrefix")
  valid_601340 = validateParameter(valid_601340, JString, required = false,
                                 default = nil)
  if valid_601340 != nil:
    section.add "CNAMEPrefix", valid_601340
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601341 = header.getOrDefault("X-Amz-Date")
  valid_601341 = validateParameter(valid_601341, JString, required = false,
                                 default = nil)
  if valid_601341 != nil:
    section.add "X-Amz-Date", valid_601341
  var valid_601342 = header.getOrDefault("X-Amz-Security-Token")
  valid_601342 = validateParameter(valid_601342, JString, required = false,
                                 default = nil)
  if valid_601342 != nil:
    section.add "X-Amz-Security-Token", valid_601342
  var valid_601343 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601343 = validateParameter(valid_601343, JString, required = false,
                                 default = nil)
  if valid_601343 != nil:
    section.add "X-Amz-Content-Sha256", valid_601343
  var valid_601344 = header.getOrDefault("X-Amz-Algorithm")
  valid_601344 = validateParameter(valid_601344, JString, required = false,
                                 default = nil)
  if valid_601344 != nil:
    section.add "X-Amz-Algorithm", valid_601344
  var valid_601345 = header.getOrDefault("X-Amz-Signature")
  valid_601345 = validateParameter(valid_601345, JString, required = false,
                                 default = nil)
  if valid_601345 != nil:
    section.add "X-Amz-Signature", valid_601345
  var valid_601346 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601346 = validateParameter(valid_601346, JString, required = false,
                                 default = nil)
  if valid_601346 != nil:
    section.add "X-Amz-SignedHeaders", valid_601346
  var valid_601347 = header.getOrDefault("X-Amz-Credential")
  valid_601347 = validateParameter(valid_601347, JString, required = false,
                                 default = nil)
  if valid_601347 != nil:
    section.add "X-Amz-Credential", valid_601347
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601348: Call_GetCreateEnvironment_601321; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Launches an environment for the specified application using the specified configuration.
  ## 
  let valid = call_601348.validator(path, query, header, formData, body)
  let scheme = call_601348.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601348.url(scheme.get, call_601348.host, call_601348.base,
                         call_601348.route, valid.getOrDefault("path"))
  result = hook(call_601348, url, valid)

proc call*(call_601349: Call_GetCreateEnvironment_601321; ApplicationName: string;
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
  var query_601350 = newJObject()
  add(query_601350, "Tier.Name", newJString(TierName))
  add(query_601350, "VersionLabel", newJString(VersionLabel))
  add(query_601350, "ApplicationName", newJString(ApplicationName))
  add(query_601350, "Description", newJString(Description))
  if OptionsToRemove != nil:
    query_601350.add "OptionsToRemove", OptionsToRemove
  add(query_601350, "PlatformArn", newJString(PlatformArn))
  if Tags != nil:
    query_601350.add "Tags", Tags
  add(query_601350, "EnvironmentName", newJString(EnvironmentName))
  add(query_601350, "Action", newJString(Action))
  add(query_601350, "SolutionStackName", newJString(SolutionStackName))
  add(query_601350, "Tier.Version", newJString(TierVersion))
  add(query_601350, "TemplateName", newJString(TemplateName))
  add(query_601350, "GroupName", newJString(GroupName))
  if OptionSettings != nil:
    query_601350.add "OptionSettings", OptionSettings
  add(query_601350, "Tier.Type", newJString(TierType))
  add(query_601350, "Version", newJString(Version))
  add(query_601350, "CNAMEPrefix", newJString(CNAMEPrefix))
  result = call_601349.call(nil, query_601350, nil, nil, nil)

var getCreateEnvironment* = Call_GetCreateEnvironment_601321(
    name: "getCreateEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateEnvironment",
    validator: validate_GetCreateEnvironment_601322, base: "/",
    url: url_GetCreateEnvironment_601323, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreatePlatformVersion_601404 = ref object of OpenApiRestCall_600427
proc url_PostCreatePlatformVersion_601406(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreatePlatformVersion_601405(path: JsonNode; query: JsonNode;
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
  var valid_601407 = query.getOrDefault("Action")
  valid_601407 = validateParameter(valid_601407, JString, required = true,
                                 default = newJString("CreatePlatformVersion"))
  if valid_601407 != nil:
    section.add "Action", valid_601407
  var valid_601408 = query.getOrDefault("Version")
  valid_601408 = validateParameter(valid_601408, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601408 != nil:
    section.add "Version", valid_601408
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601409 = header.getOrDefault("X-Amz-Date")
  valid_601409 = validateParameter(valid_601409, JString, required = false,
                                 default = nil)
  if valid_601409 != nil:
    section.add "X-Amz-Date", valid_601409
  var valid_601410 = header.getOrDefault("X-Amz-Security-Token")
  valid_601410 = validateParameter(valid_601410, JString, required = false,
                                 default = nil)
  if valid_601410 != nil:
    section.add "X-Amz-Security-Token", valid_601410
  var valid_601411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601411 = validateParameter(valid_601411, JString, required = false,
                                 default = nil)
  if valid_601411 != nil:
    section.add "X-Amz-Content-Sha256", valid_601411
  var valid_601412 = header.getOrDefault("X-Amz-Algorithm")
  valid_601412 = validateParameter(valid_601412, JString, required = false,
                                 default = nil)
  if valid_601412 != nil:
    section.add "X-Amz-Algorithm", valid_601412
  var valid_601413 = header.getOrDefault("X-Amz-Signature")
  valid_601413 = validateParameter(valid_601413, JString, required = false,
                                 default = nil)
  if valid_601413 != nil:
    section.add "X-Amz-Signature", valid_601413
  var valid_601414 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601414 = validateParameter(valid_601414, JString, required = false,
                                 default = nil)
  if valid_601414 != nil:
    section.add "X-Amz-SignedHeaders", valid_601414
  var valid_601415 = header.getOrDefault("X-Amz-Credential")
  valid_601415 = validateParameter(valid_601415, JString, required = false,
                                 default = nil)
  if valid_601415 != nil:
    section.add "X-Amz-Credential", valid_601415
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
  var valid_601416 = formData.getOrDefault("PlatformName")
  valid_601416 = validateParameter(valid_601416, JString, required = true,
                                 default = nil)
  if valid_601416 != nil:
    section.add "PlatformName", valid_601416
  var valid_601417 = formData.getOrDefault("PlatformDefinitionBundle.S3Key")
  valid_601417 = validateParameter(valid_601417, JString, required = false,
                                 default = nil)
  if valid_601417 != nil:
    section.add "PlatformDefinitionBundle.S3Key", valid_601417
  var valid_601418 = formData.getOrDefault("OptionSettings")
  valid_601418 = validateParameter(valid_601418, JArray, required = false,
                                 default = nil)
  if valid_601418 != nil:
    section.add "OptionSettings", valid_601418
  var valid_601419 = formData.getOrDefault("Tags")
  valid_601419 = validateParameter(valid_601419, JArray, required = false,
                                 default = nil)
  if valid_601419 != nil:
    section.add "Tags", valid_601419
  var valid_601420 = formData.getOrDefault("EnvironmentName")
  valid_601420 = validateParameter(valid_601420, JString, required = false,
                                 default = nil)
  if valid_601420 != nil:
    section.add "EnvironmentName", valid_601420
  var valid_601421 = formData.getOrDefault("PlatformDefinitionBundle.S3Bucket")
  valid_601421 = validateParameter(valid_601421, JString, required = false,
                                 default = nil)
  if valid_601421 != nil:
    section.add "PlatformDefinitionBundle.S3Bucket", valid_601421
  var valid_601422 = formData.getOrDefault("PlatformVersion")
  valid_601422 = validateParameter(valid_601422, JString, required = true,
                                 default = nil)
  if valid_601422 != nil:
    section.add "PlatformVersion", valid_601422
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601423: Call_PostCreatePlatformVersion_601404; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new version of your custom platform.
  ## 
  let valid = call_601423.validator(path, query, header, formData, body)
  let scheme = call_601423.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601423.url(scheme.get, call_601423.host, call_601423.base,
                         call_601423.route, valid.getOrDefault("path"))
  result = hook(call_601423, url, valid)

proc call*(call_601424: Call_PostCreatePlatformVersion_601404;
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
  var query_601425 = newJObject()
  var formData_601426 = newJObject()
  add(formData_601426, "PlatformName", newJString(PlatformName))
  add(formData_601426, "PlatformDefinitionBundle.S3Key",
      newJString(PlatformDefinitionBundleS3Key))
  if OptionSettings != nil:
    formData_601426.add "OptionSettings", OptionSettings
  if Tags != nil:
    formData_601426.add "Tags", Tags
  add(formData_601426, "EnvironmentName", newJString(EnvironmentName))
  add(formData_601426, "PlatformDefinitionBundle.S3Bucket",
      newJString(PlatformDefinitionBundleS3Bucket))
  add(query_601425, "Action", newJString(Action))
  add(formData_601426, "PlatformVersion", newJString(PlatformVersion))
  add(query_601425, "Version", newJString(Version))
  result = call_601424.call(nil, query_601425, nil, formData_601426, nil)

var postCreatePlatformVersion* = Call_PostCreatePlatformVersion_601404(
    name: "postCreatePlatformVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreatePlatformVersion",
    validator: validate_PostCreatePlatformVersion_601405, base: "/",
    url: url_PostCreatePlatformVersion_601406,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreatePlatformVersion_601382 = ref object of OpenApiRestCall_600427
proc url_GetCreatePlatformVersion_601384(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreatePlatformVersion_601383(path: JsonNode; query: JsonNode;
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
  var valid_601385 = query.getOrDefault("Tags")
  valid_601385 = validateParameter(valid_601385, JArray, required = false,
                                 default = nil)
  if valid_601385 != nil:
    section.add "Tags", valid_601385
  var valid_601386 = query.getOrDefault("EnvironmentName")
  valid_601386 = validateParameter(valid_601386, JString, required = false,
                                 default = nil)
  if valid_601386 != nil:
    section.add "EnvironmentName", valid_601386
  var valid_601387 = query.getOrDefault("PlatformDefinitionBundle.S3Key")
  valid_601387 = validateParameter(valid_601387, JString, required = false,
                                 default = nil)
  if valid_601387 != nil:
    section.add "PlatformDefinitionBundle.S3Key", valid_601387
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601388 = query.getOrDefault("Action")
  valid_601388 = validateParameter(valid_601388, JString, required = true,
                                 default = newJString("CreatePlatformVersion"))
  if valid_601388 != nil:
    section.add "Action", valid_601388
  var valid_601389 = query.getOrDefault("OptionSettings")
  valid_601389 = validateParameter(valid_601389, JArray, required = false,
                                 default = nil)
  if valid_601389 != nil:
    section.add "OptionSettings", valid_601389
  var valid_601390 = query.getOrDefault("PlatformName")
  valid_601390 = validateParameter(valid_601390, JString, required = true,
                                 default = nil)
  if valid_601390 != nil:
    section.add "PlatformName", valid_601390
  var valid_601391 = query.getOrDefault("Version")
  valid_601391 = validateParameter(valid_601391, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601391 != nil:
    section.add "Version", valid_601391
  var valid_601392 = query.getOrDefault("PlatformDefinitionBundle.S3Bucket")
  valid_601392 = validateParameter(valid_601392, JString, required = false,
                                 default = nil)
  if valid_601392 != nil:
    section.add "PlatformDefinitionBundle.S3Bucket", valid_601392
  var valid_601393 = query.getOrDefault("PlatformVersion")
  valid_601393 = validateParameter(valid_601393, JString, required = true,
                                 default = nil)
  if valid_601393 != nil:
    section.add "PlatformVersion", valid_601393
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601394 = header.getOrDefault("X-Amz-Date")
  valid_601394 = validateParameter(valid_601394, JString, required = false,
                                 default = nil)
  if valid_601394 != nil:
    section.add "X-Amz-Date", valid_601394
  var valid_601395 = header.getOrDefault("X-Amz-Security-Token")
  valid_601395 = validateParameter(valid_601395, JString, required = false,
                                 default = nil)
  if valid_601395 != nil:
    section.add "X-Amz-Security-Token", valid_601395
  var valid_601396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601396 = validateParameter(valid_601396, JString, required = false,
                                 default = nil)
  if valid_601396 != nil:
    section.add "X-Amz-Content-Sha256", valid_601396
  var valid_601397 = header.getOrDefault("X-Amz-Algorithm")
  valid_601397 = validateParameter(valid_601397, JString, required = false,
                                 default = nil)
  if valid_601397 != nil:
    section.add "X-Amz-Algorithm", valid_601397
  var valid_601398 = header.getOrDefault("X-Amz-Signature")
  valid_601398 = validateParameter(valid_601398, JString, required = false,
                                 default = nil)
  if valid_601398 != nil:
    section.add "X-Amz-Signature", valid_601398
  var valid_601399 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601399 = validateParameter(valid_601399, JString, required = false,
                                 default = nil)
  if valid_601399 != nil:
    section.add "X-Amz-SignedHeaders", valid_601399
  var valid_601400 = header.getOrDefault("X-Amz-Credential")
  valid_601400 = validateParameter(valid_601400, JString, required = false,
                                 default = nil)
  if valid_601400 != nil:
    section.add "X-Amz-Credential", valid_601400
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601401: Call_GetCreatePlatformVersion_601382; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new version of your custom platform.
  ## 
  let valid = call_601401.validator(path, query, header, formData, body)
  let scheme = call_601401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601401.url(scheme.get, call_601401.host, call_601401.base,
                         call_601401.route, valid.getOrDefault("path"))
  result = hook(call_601401, url, valid)

proc call*(call_601402: Call_GetCreatePlatformVersion_601382; PlatformName: string;
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
  var query_601403 = newJObject()
  if Tags != nil:
    query_601403.add "Tags", Tags
  add(query_601403, "EnvironmentName", newJString(EnvironmentName))
  add(query_601403, "PlatformDefinitionBundle.S3Key",
      newJString(PlatformDefinitionBundleS3Key))
  add(query_601403, "Action", newJString(Action))
  if OptionSettings != nil:
    query_601403.add "OptionSettings", OptionSettings
  add(query_601403, "PlatformName", newJString(PlatformName))
  add(query_601403, "Version", newJString(Version))
  add(query_601403, "PlatformDefinitionBundle.S3Bucket",
      newJString(PlatformDefinitionBundleS3Bucket))
  add(query_601403, "PlatformVersion", newJString(PlatformVersion))
  result = call_601402.call(nil, query_601403, nil, nil, nil)

var getCreatePlatformVersion* = Call_GetCreatePlatformVersion_601382(
    name: "getCreatePlatformVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreatePlatformVersion",
    validator: validate_GetCreatePlatformVersion_601383, base: "/",
    url: url_GetCreatePlatformVersion_601384, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateStorageLocation_601442 = ref object of OpenApiRestCall_600427
proc url_PostCreateStorageLocation_601444(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateStorageLocation_601443(path: JsonNode; query: JsonNode;
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
  var valid_601445 = query.getOrDefault("Action")
  valid_601445 = validateParameter(valid_601445, JString, required = true,
                                 default = newJString("CreateStorageLocation"))
  if valid_601445 != nil:
    section.add "Action", valid_601445
  var valid_601446 = query.getOrDefault("Version")
  valid_601446 = validateParameter(valid_601446, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601446 != nil:
    section.add "Version", valid_601446
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601447 = header.getOrDefault("X-Amz-Date")
  valid_601447 = validateParameter(valid_601447, JString, required = false,
                                 default = nil)
  if valid_601447 != nil:
    section.add "X-Amz-Date", valid_601447
  var valid_601448 = header.getOrDefault("X-Amz-Security-Token")
  valid_601448 = validateParameter(valid_601448, JString, required = false,
                                 default = nil)
  if valid_601448 != nil:
    section.add "X-Amz-Security-Token", valid_601448
  var valid_601449 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601449 = validateParameter(valid_601449, JString, required = false,
                                 default = nil)
  if valid_601449 != nil:
    section.add "X-Amz-Content-Sha256", valid_601449
  var valid_601450 = header.getOrDefault("X-Amz-Algorithm")
  valid_601450 = validateParameter(valid_601450, JString, required = false,
                                 default = nil)
  if valid_601450 != nil:
    section.add "X-Amz-Algorithm", valid_601450
  var valid_601451 = header.getOrDefault("X-Amz-Signature")
  valid_601451 = validateParameter(valid_601451, JString, required = false,
                                 default = nil)
  if valid_601451 != nil:
    section.add "X-Amz-Signature", valid_601451
  var valid_601452 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601452 = validateParameter(valid_601452, JString, required = false,
                                 default = nil)
  if valid_601452 != nil:
    section.add "X-Amz-SignedHeaders", valid_601452
  var valid_601453 = header.getOrDefault("X-Amz-Credential")
  valid_601453 = validateParameter(valid_601453, JString, required = false,
                                 default = nil)
  if valid_601453 != nil:
    section.add "X-Amz-Credential", valid_601453
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601454: Call_PostCreateStorageLocation_601442; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ## 
  let valid = call_601454.validator(path, query, header, formData, body)
  let scheme = call_601454.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601454.url(scheme.get, call_601454.host, call_601454.base,
                         call_601454.route, valid.getOrDefault("path"))
  result = hook(call_601454, url, valid)

proc call*(call_601455: Call_PostCreateStorageLocation_601442;
          Action: string = "CreateStorageLocation"; Version: string = "2010-12-01"): Recallable =
  ## postCreateStorageLocation
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601456 = newJObject()
  add(query_601456, "Action", newJString(Action))
  add(query_601456, "Version", newJString(Version))
  result = call_601455.call(nil, query_601456, nil, nil, nil)

var postCreateStorageLocation* = Call_PostCreateStorageLocation_601442(
    name: "postCreateStorageLocation", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateStorageLocation",
    validator: validate_PostCreateStorageLocation_601443, base: "/",
    url: url_PostCreateStorageLocation_601444,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateStorageLocation_601427 = ref object of OpenApiRestCall_600427
proc url_GetCreateStorageLocation_601429(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateStorageLocation_601428(path: JsonNode; query: JsonNode;
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
  var valid_601430 = query.getOrDefault("Action")
  valid_601430 = validateParameter(valid_601430, JString, required = true,
                                 default = newJString("CreateStorageLocation"))
  if valid_601430 != nil:
    section.add "Action", valid_601430
  var valid_601431 = query.getOrDefault("Version")
  valid_601431 = validateParameter(valid_601431, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601431 != nil:
    section.add "Version", valid_601431
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601432 = header.getOrDefault("X-Amz-Date")
  valid_601432 = validateParameter(valid_601432, JString, required = false,
                                 default = nil)
  if valid_601432 != nil:
    section.add "X-Amz-Date", valid_601432
  var valid_601433 = header.getOrDefault("X-Amz-Security-Token")
  valid_601433 = validateParameter(valid_601433, JString, required = false,
                                 default = nil)
  if valid_601433 != nil:
    section.add "X-Amz-Security-Token", valid_601433
  var valid_601434 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601434 = validateParameter(valid_601434, JString, required = false,
                                 default = nil)
  if valid_601434 != nil:
    section.add "X-Amz-Content-Sha256", valid_601434
  var valid_601435 = header.getOrDefault("X-Amz-Algorithm")
  valid_601435 = validateParameter(valid_601435, JString, required = false,
                                 default = nil)
  if valid_601435 != nil:
    section.add "X-Amz-Algorithm", valid_601435
  var valid_601436 = header.getOrDefault("X-Amz-Signature")
  valid_601436 = validateParameter(valid_601436, JString, required = false,
                                 default = nil)
  if valid_601436 != nil:
    section.add "X-Amz-Signature", valid_601436
  var valid_601437 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601437 = validateParameter(valid_601437, JString, required = false,
                                 default = nil)
  if valid_601437 != nil:
    section.add "X-Amz-SignedHeaders", valid_601437
  var valid_601438 = header.getOrDefault("X-Amz-Credential")
  valid_601438 = validateParameter(valid_601438, JString, required = false,
                                 default = nil)
  if valid_601438 != nil:
    section.add "X-Amz-Credential", valid_601438
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601439: Call_GetCreateStorageLocation_601427; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ## 
  let valid = call_601439.validator(path, query, header, formData, body)
  let scheme = call_601439.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601439.url(scheme.get, call_601439.host, call_601439.base,
                         call_601439.route, valid.getOrDefault("path"))
  result = hook(call_601439, url, valid)

proc call*(call_601440: Call_GetCreateStorageLocation_601427;
          Action: string = "CreateStorageLocation"; Version: string = "2010-12-01"): Recallable =
  ## getCreateStorageLocation
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601441 = newJObject()
  add(query_601441, "Action", newJString(Action))
  add(query_601441, "Version", newJString(Version))
  result = call_601440.call(nil, query_601441, nil, nil, nil)

var getCreateStorageLocation* = Call_GetCreateStorageLocation_601427(
    name: "getCreateStorageLocation", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateStorageLocation",
    validator: validate_GetCreateStorageLocation_601428, base: "/",
    url: url_GetCreateStorageLocation_601429, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteApplication_601474 = ref object of OpenApiRestCall_600427
proc url_PostDeleteApplication_601476(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteApplication_601475(path: JsonNode; query: JsonNode;
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
  var valid_601477 = query.getOrDefault("Action")
  valid_601477 = validateParameter(valid_601477, JString, required = true,
                                 default = newJString("DeleteApplication"))
  if valid_601477 != nil:
    section.add "Action", valid_601477
  var valid_601478 = query.getOrDefault("Version")
  valid_601478 = validateParameter(valid_601478, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601478 != nil:
    section.add "Version", valid_601478
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601479 = header.getOrDefault("X-Amz-Date")
  valid_601479 = validateParameter(valid_601479, JString, required = false,
                                 default = nil)
  if valid_601479 != nil:
    section.add "X-Amz-Date", valid_601479
  var valid_601480 = header.getOrDefault("X-Amz-Security-Token")
  valid_601480 = validateParameter(valid_601480, JString, required = false,
                                 default = nil)
  if valid_601480 != nil:
    section.add "X-Amz-Security-Token", valid_601480
  var valid_601481 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601481 = validateParameter(valid_601481, JString, required = false,
                                 default = nil)
  if valid_601481 != nil:
    section.add "X-Amz-Content-Sha256", valid_601481
  var valid_601482 = header.getOrDefault("X-Amz-Algorithm")
  valid_601482 = validateParameter(valid_601482, JString, required = false,
                                 default = nil)
  if valid_601482 != nil:
    section.add "X-Amz-Algorithm", valid_601482
  var valid_601483 = header.getOrDefault("X-Amz-Signature")
  valid_601483 = validateParameter(valid_601483, JString, required = false,
                                 default = nil)
  if valid_601483 != nil:
    section.add "X-Amz-Signature", valid_601483
  var valid_601484 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601484 = validateParameter(valid_601484, JString, required = false,
                                 default = nil)
  if valid_601484 != nil:
    section.add "X-Amz-SignedHeaders", valid_601484
  var valid_601485 = header.getOrDefault("X-Amz-Credential")
  valid_601485 = validateParameter(valid_601485, JString, required = false,
                                 default = nil)
  if valid_601485 != nil:
    section.add "X-Amz-Credential", valid_601485
  result.add "header", section
  ## parameters in `formData` object:
  ##   TerminateEnvByForce: JBool
  ##                      : When set to true, running environments will be terminated before deleting the application.
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to delete.
  section = newJObject()
  var valid_601486 = formData.getOrDefault("TerminateEnvByForce")
  valid_601486 = validateParameter(valid_601486, JBool, required = false, default = nil)
  if valid_601486 != nil:
    section.add "TerminateEnvByForce", valid_601486
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_601487 = formData.getOrDefault("ApplicationName")
  valid_601487 = validateParameter(valid_601487, JString, required = true,
                                 default = nil)
  if valid_601487 != nil:
    section.add "ApplicationName", valid_601487
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601488: Call_PostDeleteApplication_601474; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified application along with all associated versions and configurations. The application versions will not be deleted from your Amazon S3 bucket.</p> <note> <p>You cannot delete an application that has a running environment.</p> </note>
  ## 
  let valid = call_601488.validator(path, query, header, formData, body)
  let scheme = call_601488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601488.url(scheme.get, call_601488.host, call_601488.base,
                         call_601488.route, valid.getOrDefault("path"))
  result = hook(call_601488, url, valid)

proc call*(call_601489: Call_PostDeleteApplication_601474; ApplicationName: string;
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
  var query_601490 = newJObject()
  var formData_601491 = newJObject()
  add(formData_601491, "TerminateEnvByForce", newJBool(TerminateEnvByForce))
  add(query_601490, "Action", newJString(Action))
  add(formData_601491, "ApplicationName", newJString(ApplicationName))
  add(query_601490, "Version", newJString(Version))
  result = call_601489.call(nil, query_601490, nil, formData_601491, nil)

var postDeleteApplication* = Call_PostDeleteApplication_601474(
    name: "postDeleteApplication", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=DeleteApplication",
    validator: validate_PostDeleteApplication_601475, base: "/",
    url: url_PostDeleteApplication_601476, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteApplication_601457 = ref object of OpenApiRestCall_600427
proc url_GetDeleteApplication_601459(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteApplication_601458(path: JsonNode; query: JsonNode;
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
  var valid_601460 = query.getOrDefault("TerminateEnvByForce")
  valid_601460 = validateParameter(valid_601460, JBool, required = false, default = nil)
  if valid_601460 != nil:
    section.add "TerminateEnvByForce", valid_601460
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_601461 = query.getOrDefault("ApplicationName")
  valid_601461 = validateParameter(valid_601461, JString, required = true,
                                 default = nil)
  if valid_601461 != nil:
    section.add "ApplicationName", valid_601461
  var valid_601462 = query.getOrDefault("Action")
  valid_601462 = validateParameter(valid_601462, JString, required = true,
                                 default = newJString("DeleteApplication"))
  if valid_601462 != nil:
    section.add "Action", valid_601462
  var valid_601463 = query.getOrDefault("Version")
  valid_601463 = validateParameter(valid_601463, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601463 != nil:
    section.add "Version", valid_601463
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601464 = header.getOrDefault("X-Amz-Date")
  valid_601464 = validateParameter(valid_601464, JString, required = false,
                                 default = nil)
  if valid_601464 != nil:
    section.add "X-Amz-Date", valid_601464
  var valid_601465 = header.getOrDefault("X-Amz-Security-Token")
  valid_601465 = validateParameter(valid_601465, JString, required = false,
                                 default = nil)
  if valid_601465 != nil:
    section.add "X-Amz-Security-Token", valid_601465
  var valid_601466 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601466 = validateParameter(valid_601466, JString, required = false,
                                 default = nil)
  if valid_601466 != nil:
    section.add "X-Amz-Content-Sha256", valid_601466
  var valid_601467 = header.getOrDefault("X-Amz-Algorithm")
  valid_601467 = validateParameter(valid_601467, JString, required = false,
                                 default = nil)
  if valid_601467 != nil:
    section.add "X-Amz-Algorithm", valid_601467
  var valid_601468 = header.getOrDefault("X-Amz-Signature")
  valid_601468 = validateParameter(valid_601468, JString, required = false,
                                 default = nil)
  if valid_601468 != nil:
    section.add "X-Amz-Signature", valid_601468
  var valid_601469 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601469 = validateParameter(valid_601469, JString, required = false,
                                 default = nil)
  if valid_601469 != nil:
    section.add "X-Amz-SignedHeaders", valid_601469
  var valid_601470 = header.getOrDefault("X-Amz-Credential")
  valid_601470 = validateParameter(valid_601470, JString, required = false,
                                 default = nil)
  if valid_601470 != nil:
    section.add "X-Amz-Credential", valid_601470
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601471: Call_GetDeleteApplication_601457; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified application along with all associated versions and configurations. The application versions will not be deleted from your Amazon S3 bucket.</p> <note> <p>You cannot delete an application that has a running environment.</p> </note>
  ## 
  let valid = call_601471.validator(path, query, header, formData, body)
  let scheme = call_601471.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601471.url(scheme.get, call_601471.host, call_601471.base,
                         call_601471.route, valid.getOrDefault("path"))
  result = hook(call_601471, url, valid)

proc call*(call_601472: Call_GetDeleteApplication_601457; ApplicationName: string;
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
  var query_601473 = newJObject()
  add(query_601473, "TerminateEnvByForce", newJBool(TerminateEnvByForce))
  add(query_601473, "ApplicationName", newJString(ApplicationName))
  add(query_601473, "Action", newJString(Action))
  add(query_601473, "Version", newJString(Version))
  result = call_601472.call(nil, query_601473, nil, nil, nil)

var getDeleteApplication* = Call_GetDeleteApplication_601457(
    name: "getDeleteApplication", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=DeleteApplication",
    validator: validate_GetDeleteApplication_601458, base: "/",
    url: url_GetDeleteApplication_601459, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteApplicationVersion_601510 = ref object of OpenApiRestCall_600427
proc url_PostDeleteApplicationVersion_601512(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteApplicationVersion_601511(path: JsonNode; query: JsonNode;
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
  var valid_601513 = query.getOrDefault("Action")
  valid_601513 = validateParameter(valid_601513, JString, required = true, default = newJString(
      "DeleteApplicationVersion"))
  if valid_601513 != nil:
    section.add "Action", valid_601513
  var valid_601514 = query.getOrDefault("Version")
  valid_601514 = validateParameter(valid_601514, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601514 != nil:
    section.add "Version", valid_601514
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601515 = header.getOrDefault("X-Amz-Date")
  valid_601515 = validateParameter(valid_601515, JString, required = false,
                                 default = nil)
  if valid_601515 != nil:
    section.add "X-Amz-Date", valid_601515
  var valid_601516 = header.getOrDefault("X-Amz-Security-Token")
  valid_601516 = validateParameter(valid_601516, JString, required = false,
                                 default = nil)
  if valid_601516 != nil:
    section.add "X-Amz-Security-Token", valid_601516
  var valid_601517 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601517 = validateParameter(valid_601517, JString, required = false,
                                 default = nil)
  if valid_601517 != nil:
    section.add "X-Amz-Content-Sha256", valid_601517
  var valid_601518 = header.getOrDefault("X-Amz-Algorithm")
  valid_601518 = validateParameter(valid_601518, JString, required = false,
                                 default = nil)
  if valid_601518 != nil:
    section.add "X-Amz-Algorithm", valid_601518
  var valid_601519 = header.getOrDefault("X-Amz-Signature")
  valid_601519 = validateParameter(valid_601519, JString, required = false,
                                 default = nil)
  if valid_601519 != nil:
    section.add "X-Amz-Signature", valid_601519
  var valid_601520 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601520 = validateParameter(valid_601520, JString, required = false,
                                 default = nil)
  if valid_601520 != nil:
    section.add "X-Amz-SignedHeaders", valid_601520
  var valid_601521 = header.getOrDefault("X-Amz-Credential")
  valid_601521 = validateParameter(valid_601521, JString, required = false,
                                 default = nil)
  if valid_601521 != nil:
    section.add "X-Amz-Credential", valid_601521
  result.add "header", section
  ## parameters in `formData` object:
  ##   DeleteSourceBundle: JBool
  ##                     : Set to <code>true</code> to delete the source bundle from your storage bucket. Otherwise, the application version is deleted only from Elastic Beanstalk and the source bundle remains in Amazon S3.
  ##   VersionLabel: JString (required)
  ##               : The label of the version to delete.
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to which the version belongs.
  section = newJObject()
  var valid_601522 = formData.getOrDefault("DeleteSourceBundle")
  valid_601522 = validateParameter(valid_601522, JBool, required = false, default = nil)
  if valid_601522 != nil:
    section.add "DeleteSourceBundle", valid_601522
  assert formData != nil,
        "formData argument is necessary due to required `VersionLabel` field"
  var valid_601523 = formData.getOrDefault("VersionLabel")
  valid_601523 = validateParameter(valid_601523, JString, required = true,
                                 default = nil)
  if valid_601523 != nil:
    section.add "VersionLabel", valid_601523
  var valid_601524 = formData.getOrDefault("ApplicationName")
  valid_601524 = validateParameter(valid_601524, JString, required = true,
                                 default = nil)
  if valid_601524 != nil:
    section.add "ApplicationName", valid_601524
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601525: Call_PostDeleteApplicationVersion_601510; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified version from the specified application.</p> <note> <p>You cannot delete an application version that is associated with a running environment.</p> </note>
  ## 
  let valid = call_601525.validator(path, query, header, formData, body)
  let scheme = call_601525.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601525.url(scheme.get, call_601525.host, call_601525.base,
                         call_601525.route, valid.getOrDefault("path"))
  result = hook(call_601525, url, valid)

proc call*(call_601526: Call_PostDeleteApplicationVersion_601510;
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
  var query_601527 = newJObject()
  var formData_601528 = newJObject()
  add(formData_601528, "DeleteSourceBundle", newJBool(DeleteSourceBundle))
  add(formData_601528, "VersionLabel", newJString(VersionLabel))
  add(query_601527, "Action", newJString(Action))
  add(formData_601528, "ApplicationName", newJString(ApplicationName))
  add(query_601527, "Version", newJString(Version))
  result = call_601526.call(nil, query_601527, nil, formData_601528, nil)

var postDeleteApplicationVersion* = Call_PostDeleteApplicationVersion_601510(
    name: "postDeleteApplicationVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteApplicationVersion",
    validator: validate_PostDeleteApplicationVersion_601511, base: "/",
    url: url_PostDeleteApplicationVersion_601512,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteApplicationVersion_601492 = ref object of OpenApiRestCall_600427
proc url_GetDeleteApplicationVersion_601494(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteApplicationVersion_601493(path: JsonNode; query: JsonNode;
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
  var valid_601495 = query.getOrDefault("VersionLabel")
  valid_601495 = validateParameter(valid_601495, JString, required = true,
                                 default = nil)
  if valid_601495 != nil:
    section.add "VersionLabel", valid_601495
  var valid_601496 = query.getOrDefault("ApplicationName")
  valid_601496 = validateParameter(valid_601496, JString, required = true,
                                 default = nil)
  if valid_601496 != nil:
    section.add "ApplicationName", valid_601496
  var valid_601497 = query.getOrDefault("Action")
  valid_601497 = validateParameter(valid_601497, JString, required = true, default = newJString(
      "DeleteApplicationVersion"))
  if valid_601497 != nil:
    section.add "Action", valid_601497
  var valid_601498 = query.getOrDefault("DeleteSourceBundle")
  valid_601498 = validateParameter(valid_601498, JBool, required = false, default = nil)
  if valid_601498 != nil:
    section.add "DeleteSourceBundle", valid_601498
  var valid_601499 = query.getOrDefault("Version")
  valid_601499 = validateParameter(valid_601499, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601499 != nil:
    section.add "Version", valid_601499
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601500 = header.getOrDefault("X-Amz-Date")
  valid_601500 = validateParameter(valid_601500, JString, required = false,
                                 default = nil)
  if valid_601500 != nil:
    section.add "X-Amz-Date", valid_601500
  var valid_601501 = header.getOrDefault("X-Amz-Security-Token")
  valid_601501 = validateParameter(valid_601501, JString, required = false,
                                 default = nil)
  if valid_601501 != nil:
    section.add "X-Amz-Security-Token", valid_601501
  var valid_601502 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601502 = validateParameter(valid_601502, JString, required = false,
                                 default = nil)
  if valid_601502 != nil:
    section.add "X-Amz-Content-Sha256", valid_601502
  var valid_601503 = header.getOrDefault("X-Amz-Algorithm")
  valid_601503 = validateParameter(valid_601503, JString, required = false,
                                 default = nil)
  if valid_601503 != nil:
    section.add "X-Amz-Algorithm", valid_601503
  var valid_601504 = header.getOrDefault("X-Amz-Signature")
  valid_601504 = validateParameter(valid_601504, JString, required = false,
                                 default = nil)
  if valid_601504 != nil:
    section.add "X-Amz-Signature", valid_601504
  var valid_601505 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601505 = validateParameter(valid_601505, JString, required = false,
                                 default = nil)
  if valid_601505 != nil:
    section.add "X-Amz-SignedHeaders", valid_601505
  var valid_601506 = header.getOrDefault("X-Amz-Credential")
  valid_601506 = validateParameter(valid_601506, JString, required = false,
                                 default = nil)
  if valid_601506 != nil:
    section.add "X-Amz-Credential", valid_601506
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601507: Call_GetDeleteApplicationVersion_601492; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified version from the specified application.</p> <note> <p>You cannot delete an application version that is associated with a running environment.</p> </note>
  ## 
  let valid = call_601507.validator(path, query, header, formData, body)
  let scheme = call_601507.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601507.url(scheme.get, call_601507.host, call_601507.base,
                         call_601507.route, valid.getOrDefault("path"))
  result = hook(call_601507, url, valid)

proc call*(call_601508: Call_GetDeleteApplicationVersion_601492;
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
  var query_601509 = newJObject()
  add(query_601509, "VersionLabel", newJString(VersionLabel))
  add(query_601509, "ApplicationName", newJString(ApplicationName))
  add(query_601509, "Action", newJString(Action))
  add(query_601509, "DeleteSourceBundle", newJBool(DeleteSourceBundle))
  add(query_601509, "Version", newJString(Version))
  result = call_601508.call(nil, query_601509, nil, nil, nil)

var getDeleteApplicationVersion* = Call_GetDeleteApplicationVersion_601492(
    name: "getDeleteApplicationVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteApplicationVersion",
    validator: validate_GetDeleteApplicationVersion_601493, base: "/",
    url: url_GetDeleteApplicationVersion_601494,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteConfigurationTemplate_601546 = ref object of OpenApiRestCall_600427
proc url_PostDeleteConfigurationTemplate_601548(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteConfigurationTemplate_601547(path: JsonNode;
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
  var valid_601549 = query.getOrDefault("Action")
  valid_601549 = validateParameter(valid_601549, JString, required = true, default = newJString(
      "DeleteConfigurationTemplate"))
  if valid_601549 != nil:
    section.add "Action", valid_601549
  var valid_601550 = query.getOrDefault("Version")
  valid_601550 = validateParameter(valid_601550, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601550 != nil:
    section.add "Version", valid_601550
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601551 = header.getOrDefault("X-Amz-Date")
  valid_601551 = validateParameter(valid_601551, JString, required = false,
                                 default = nil)
  if valid_601551 != nil:
    section.add "X-Amz-Date", valid_601551
  var valid_601552 = header.getOrDefault("X-Amz-Security-Token")
  valid_601552 = validateParameter(valid_601552, JString, required = false,
                                 default = nil)
  if valid_601552 != nil:
    section.add "X-Amz-Security-Token", valid_601552
  var valid_601553 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601553 = validateParameter(valid_601553, JString, required = false,
                                 default = nil)
  if valid_601553 != nil:
    section.add "X-Amz-Content-Sha256", valid_601553
  var valid_601554 = header.getOrDefault("X-Amz-Algorithm")
  valid_601554 = validateParameter(valid_601554, JString, required = false,
                                 default = nil)
  if valid_601554 != nil:
    section.add "X-Amz-Algorithm", valid_601554
  var valid_601555 = header.getOrDefault("X-Amz-Signature")
  valid_601555 = validateParameter(valid_601555, JString, required = false,
                                 default = nil)
  if valid_601555 != nil:
    section.add "X-Amz-Signature", valid_601555
  var valid_601556 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601556 = validateParameter(valid_601556, JString, required = false,
                                 default = nil)
  if valid_601556 != nil:
    section.add "X-Amz-SignedHeaders", valid_601556
  var valid_601557 = header.getOrDefault("X-Amz-Credential")
  valid_601557 = validateParameter(valid_601557, JString, required = false,
                                 default = nil)
  if valid_601557 != nil:
    section.add "X-Amz-Credential", valid_601557
  result.add "header", section
  ## parameters in `formData` object:
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to delete the configuration template from.
  ##   TemplateName: JString (required)
  ##               : The name of the configuration template to delete.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_601558 = formData.getOrDefault("ApplicationName")
  valid_601558 = validateParameter(valid_601558, JString, required = true,
                                 default = nil)
  if valid_601558 != nil:
    section.add "ApplicationName", valid_601558
  var valid_601559 = formData.getOrDefault("TemplateName")
  valid_601559 = validateParameter(valid_601559, JString, required = true,
                                 default = nil)
  if valid_601559 != nil:
    section.add "TemplateName", valid_601559
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601560: Call_PostDeleteConfigurationTemplate_601546;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes the specified configuration template.</p> <note> <p>When you launch an environment using a configuration template, the environment gets a copy of the template. You can delete or modify the environment's copy of the template without affecting the running environment.</p> </note>
  ## 
  let valid = call_601560.validator(path, query, header, formData, body)
  let scheme = call_601560.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601560.url(scheme.get, call_601560.host, call_601560.base,
                         call_601560.route, valid.getOrDefault("path"))
  result = hook(call_601560, url, valid)

proc call*(call_601561: Call_PostDeleteConfigurationTemplate_601546;
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
  var query_601562 = newJObject()
  var formData_601563 = newJObject()
  add(query_601562, "Action", newJString(Action))
  add(formData_601563, "ApplicationName", newJString(ApplicationName))
  add(formData_601563, "TemplateName", newJString(TemplateName))
  add(query_601562, "Version", newJString(Version))
  result = call_601561.call(nil, query_601562, nil, formData_601563, nil)

var postDeleteConfigurationTemplate* = Call_PostDeleteConfigurationTemplate_601546(
    name: "postDeleteConfigurationTemplate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteConfigurationTemplate",
    validator: validate_PostDeleteConfigurationTemplate_601547, base: "/",
    url: url_PostDeleteConfigurationTemplate_601548,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteConfigurationTemplate_601529 = ref object of OpenApiRestCall_600427
proc url_GetDeleteConfigurationTemplate_601531(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteConfigurationTemplate_601530(path: JsonNode;
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
  var valid_601532 = query.getOrDefault("ApplicationName")
  valid_601532 = validateParameter(valid_601532, JString, required = true,
                                 default = nil)
  if valid_601532 != nil:
    section.add "ApplicationName", valid_601532
  var valid_601533 = query.getOrDefault("Action")
  valid_601533 = validateParameter(valid_601533, JString, required = true, default = newJString(
      "DeleteConfigurationTemplate"))
  if valid_601533 != nil:
    section.add "Action", valid_601533
  var valid_601534 = query.getOrDefault("TemplateName")
  valid_601534 = validateParameter(valid_601534, JString, required = true,
                                 default = nil)
  if valid_601534 != nil:
    section.add "TemplateName", valid_601534
  var valid_601535 = query.getOrDefault("Version")
  valid_601535 = validateParameter(valid_601535, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601535 != nil:
    section.add "Version", valid_601535
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601536 = header.getOrDefault("X-Amz-Date")
  valid_601536 = validateParameter(valid_601536, JString, required = false,
                                 default = nil)
  if valid_601536 != nil:
    section.add "X-Amz-Date", valid_601536
  var valid_601537 = header.getOrDefault("X-Amz-Security-Token")
  valid_601537 = validateParameter(valid_601537, JString, required = false,
                                 default = nil)
  if valid_601537 != nil:
    section.add "X-Amz-Security-Token", valid_601537
  var valid_601538 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601538 = validateParameter(valid_601538, JString, required = false,
                                 default = nil)
  if valid_601538 != nil:
    section.add "X-Amz-Content-Sha256", valid_601538
  var valid_601539 = header.getOrDefault("X-Amz-Algorithm")
  valid_601539 = validateParameter(valid_601539, JString, required = false,
                                 default = nil)
  if valid_601539 != nil:
    section.add "X-Amz-Algorithm", valid_601539
  var valid_601540 = header.getOrDefault("X-Amz-Signature")
  valid_601540 = validateParameter(valid_601540, JString, required = false,
                                 default = nil)
  if valid_601540 != nil:
    section.add "X-Amz-Signature", valid_601540
  var valid_601541 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601541 = validateParameter(valid_601541, JString, required = false,
                                 default = nil)
  if valid_601541 != nil:
    section.add "X-Amz-SignedHeaders", valid_601541
  var valid_601542 = header.getOrDefault("X-Amz-Credential")
  valid_601542 = validateParameter(valid_601542, JString, required = false,
                                 default = nil)
  if valid_601542 != nil:
    section.add "X-Amz-Credential", valid_601542
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601543: Call_GetDeleteConfigurationTemplate_601529; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified configuration template.</p> <note> <p>When you launch an environment using a configuration template, the environment gets a copy of the template. You can delete or modify the environment's copy of the template without affecting the running environment.</p> </note>
  ## 
  let valid = call_601543.validator(path, query, header, formData, body)
  let scheme = call_601543.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601543.url(scheme.get, call_601543.host, call_601543.base,
                         call_601543.route, valid.getOrDefault("path"))
  result = hook(call_601543, url, valid)

proc call*(call_601544: Call_GetDeleteConfigurationTemplate_601529;
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
  var query_601545 = newJObject()
  add(query_601545, "ApplicationName", newJString(ApplicationName))
  add(query_601545, "Action", newJString(Action))
  add(query_601545, "TemplateName", newJString(TemplateName))
  add(query_601545, "Version", newJString(Version))
  result = call_601544.call(nil, query_601545, nil, nil, nil)

var getDeleteConfigurationTemplate* = Call_GetDeleteConfigurationTemplate_601529(
    name: "getDeleteConfigurationTemplate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteConfigurationTemplate",
    validator: validate_GetDeleteConfigurationTemplate_601530, base: "/",
    url: url_GetDeleteConfigurationTemplate_601531,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEnvironmentConfiguration_601581 = ref object of OpenApiRestCall_600427
proc url_PostDeleteEnvironmentConfiguration_601583(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteEnvironmentConfiguration_601582(path: JsonNode;
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
  var valid_601584 = query.getOrDefault("Action")
  valid_601584 = validateParameter(valid_601584, JString, required = true, default = newJString(
      "DeleteEnvironmentConfiguration"))
  if valid_601584 != nil:
    section.add "Action", valid_601584
  var valid_601585 = query.getOrDefault("Version")
  valid_601585 = validateParameter(valid_601585, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601585 != nil:
    section.add "Version", valid_601585
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601586 = header.getOrDefault("X-Amz-Date")
  valid_601586 = validateParameter(valid_601586, JString, required = false,
                                 default = nil)
  if valid_601586 != nil:
    section.add "X-Amz-Date", valid_601586
  var valid_601587 = header.getOrDefault("X-Amz-Security-Token")
  valid_601587 = validateParameter(valid_601587, JString, required = false,
                                 default = nil)
  if valid_601587 != nil:
    section.add "X-Amz-Security-Token", valid_601587
  var valid_601588 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601588 = validateParameter(valid_601588, JString, required = false,
                                 default = nil)
  if valid_601588 != nil:
    section.add "X-Amz-Content-Sha256", valid_601588
  var valid_601589 = header.getOrDefault("X-Amz-Algorithm")
  valid_601589 = validateParameter(valid_601589, JString, required = false,
                                 default = nil)
  if valid_601589 != nil:
    section.add "X-Amz-Algorithm", valid_601589
  var valid_601590 = header.getOrDefault("X-Amz-Signature")
  valid_601590 = validateParameter(valid_601590, JString, required = false,
                                 default = nil)
  if valid_601590 != nil:
    section.add "X-Amz-Signature", valid_601590
  var valid_601591 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601591 = validateParameter(valid_601591, JString, required = false,
                                 default = nil)
  if valid_601591 != nil:
    section.add "X-Amz-SignedHeaders", valid_601591
  var valid_601592 = header.getOrDefault("X-Amz-Credential")
  valid_601592 = validateParameter(valid_601592, JString, required = false,
                                 default = nil)
  if valid_601592 != nil:
    section.add "X-Amz-Credential", valid_601592
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString (required)
  ##                  : The name of the environment to delete the draft configuration from.
  ##   ApplicationName: JString (required)
  ##                  : The name of the application the environment is associated with.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `EnvironmentName` field"
  var valid_601593 = formData.getOrDefault("EnvironmentName")
  valid_601593 = validateParameter(valid_601593, JString, required = true,
                                 default = nil)
  if valid_601593 != nil:
    section.add "EnvironmentName", valid_601593
  var valid_601594 = formData.getOrDefault("ApplicationName")
  valid_601594 = validateParameter(valid_601594, JString, required = true,
                                 default = nil)
  if valid_601594 != nil:
    section.add "ApplicationName", valid_601594
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601595: Call_PostDeleteEnvironmentConfiguration_601581;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes the draft configuration associated with the running environment.</p> <p>Updating a running environment with any configuration changes creates a draft configuration set. You can get the draft configuration using <a>DescribeConfigurationSettings</a> while the update is in progress or if the update fails. The <code>DeploymentStatus</code> for the draft configuration indicates whether the deployment is in process or has failed. The draft configuration remains in existence until it is deleted with this action.</p>
  ## 
  let valid = call_601595.validator(path, query, header, formData, body)
  let scheme = call_601595.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601595.url(scheme.get, call_601595.host, call_601595.base,
                         call_601595.route, valid.getOrDefault("path"))
  result = hook(call_601595, url, valid)

proc call*(call_601596: Call_PostDeleteEnvironmentConfiguration_601581;
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
  var query_601597 = newJObject()
  var formData_601598 = newJObject()
  add(formData_601598, "EnvironmentName", newJString(EnvironmentName))
  add(query_601597, "Action", newJString(Action))
  add(formData_601598, "ApplicationName", newJString(ApplicationName))
  add(query_601597, "Version", newJString(Version))
  result = call_601596.call(nil, query_601597, nil, formData_601598, nil)

var postDeleteEnvironmentConfiguration* = Call_PostDeleteEnvironmentConfiguration_601581(
    name: "postDeleteEnvironmentConfiguration", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteEnvironmentConfiguration",
    validator: validate_PostDeleteEnvironmentConfiguration_601582, base: "/",
    url: url_PostDeleteEnvironmentConfiguration_601583,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEnvironmentConfiguration_601564 = ref object of OpenApiRestCall_600427
proc url_GetDeleteEnvironmentConfiguration_601566(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteEnvironmentConfiguration_601565(path: JsonNode;
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
  var valid_601567 = query.getOrDefault("ApplicationName")
  valid_601567 = validateParameter(valid_601567, JString, required = true,
                                 default = nil)
  if valid_601567 != nil:
    section.add "ApplicationName", valid_601567
  var valid_601568 = query.getOrDefault("EnvironmentName")
  valid_601568 = validateParameter(valid_601568, JString, required = true,
                                 default = nil)
  if valid_601568 != nil:
    section.add "EnvironmentName", valid_601568
  var valid_601569 = query.getOrDefault("Action")
  valid_601569 = validateParameter(valid_601569, JString, required = true, default = newJString(
      "DeleteEnvironmentConfiguration"))
  if valid_601569 != nil:
    section.add "Action", valid_601569
  var valid_601570 = query.getOrDefault("Version")
  valid_601570 = validateParameter(valid_601570, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601570 != nil:
    section.add "Version", valid_601570
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601571 = header.getOrDefault("X-Amz-Date")
  valid_601571 = validateParameter(valid_601571, JString, required = false,
                                 default = nil)
  if valid_601571 != nil:
    section.add "X-Amz-Date", valid_601571
  var valid_601572 = header.getOrDefault("X-Amz-Security-Token")
  valid_601572 = validateParameter(valid_601572, JString, required = false,
                                 default = nil)
  if valid_601572 != nil:
    section.add "X-Amz-Security-Token", valid_601572
  var valid_601573 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601573 = validateParameter(valid_601573, JString, required = false,
                                 default = nil)
  if valid_601573 != nil:
    section.add "X-Amz-Content-Sha256", valid_601573
  var valid_601574 = header.getOrDefault("X-Amz-Algorithm")
  valid_601574 = validateParameter(valid_601574, JString, required = false,
                                 default = nil)
  if valid_601574 != nil:
    section.add "X-Amz-Algorithm", valid_601574
  var valid_601575 = header.getOrDefault("X-Amz-Signature")
  valid_601575 = validateParameter(valid_601575, JString, required = false,
                                 default = nil)
  if valid_601575 != nil:
    section.add "X-Amz-Signature", valid_601575
  var valid_601576 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601576 = validateParameter(valid_601576, JString, required = false,
                                 default = nil)
  if valid_601576 != nil:
    section.add "X-Amz-SignedHeaders", valid_601576
  var valid_601577 = header.getOrDefault("X-Amz-Credential")
  valid_601577 = validateParameter(valid_601577, JString, required = false,
                                 default = nil)
  if valid_601577 != nil:
    section.add "X-Amz-Credential", valid_601577
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601578: Call_GetDeleteEnvironmentConfiguration_601564;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes the draft configuration associated with the running environment.</p> <p>Updating a running environment with any configuration changes creates a draft configuration set. You can get the draft configuration using <a>DescribeConfigurationSettings</a> while the update is in progress or if the update fails. The <code>DeploymentStatus</code> for the draft configuration indicates whether the deployment is in process or has failed. The draft configuration remains in existence until it is deleted with this action.</p>
  ## 
  let valid = call_601578.validator(path, query, header, formData, body)
  let scheme = call_601578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601578.url(scheme.get, call_601578.host, call_601578.base,
                         call_601578.route, valid.getOrDefault("path"))
  result = hook(call_601578, url, valid)

proc call*(call_601579: Call_GetDeleteEnvironmentConfiguration_601564;
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
  var query_601580 = newJObject()
  add(query_601580, "ApplicationName", newJString(ApplicationName))
  add(query_601580, "EnvironmentName", newJString(EnvironmentName))
  add(query_601580, "Action", newJString(Action))
  add(query_601580, "Version", newJString(Version))
  result = call_601579.call(nil, query_601580, nil, nil, nil)

var getDeleteEnvironmentConfiguration* = Call_GetDeleteEnvironmentConfiguration_601564(
    name: "getDeleteEnvironmentConfiguration", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteEnvironmentConfiguration",
    validator: validate_GetDeleteEnvironmentConfiguration_601565, base: "/",
    url: url_GetDeleteEnvironmentConfiguration_601566,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeletePlatformVersion_601615 = ref object of OpenApiRestCall_600427
proc url_PostDeletePlatformVersion_601617(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeletePlatformVersion_601616(path: JsonNode; query: JsonNode;
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
  var valid_601618 = query.getOrDefault("Action")
  valid_601618 = validateParameter(valid_601618, JString, required = true,
                                 default = newJString("DeletePlatformVersion"))
  if valid_601618 != nil:
    section.add "Action", valid_601618
  var valid_601619 = query.getOrDefault("Version")
  valid_601619 = validateParameter(valid_601619, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601619 != nil:
    section.add "Version", valid_601619
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601620 = header.getOrDefault("X-Amz-Date")
  valid_601620 = validateParameter(valid_601620, JString, required = false,
                                 default = nil)
  if valid_601620 != nil:
    section.add "X-Amz-Date", valid_601620
  var valid_601621 = header.getOrDefault("X-Amz-Security-Token")
  valid_601621 = validateParameter(valid_601621, JString, required = false,
                                 default = nil)
  if valid_601621 != nil:
    section.add "X-Amz-Security-Token", valid_601621
  var valid_601622 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601622 = validateParameter(valid_601622, JString, required = false,
                                 default = nil)
  if valid_601622 != nil:
    section.add "X-Amz-Content-Sha256", valid_601622
  var valid_601623 = header.getOrDefault("X-Amz-Algorithm")
  valid_601623 = validateParameter(valid_601623, JString, required = false,
                                 default = nil)
  if valid_601623 != nil:
    section.add "X-Amz-Algorithm", valid_601623
  var valid_601624 = header.getOrDefault("X-Amz-Signature")
  valid_601624 = validateParameter(valid_601624, JString, required = false,
                                 default = nil)
  if valid_601624 != nil:
    section.add "X-Amz-Signature", valid_601624
  var valid_601625 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601625 = validateParameter(valid_601625, JString, required = false,
                                 default = nil)
  if valid_601625 != nil:
    section.add "X-Amz-SignedHeaders", valid_601625
  var valid_601626 = header.getOrDefault("X-Amz-Credential")
  valid_601626 = validateParameter(valid_601626, JString, required = false,
                                 default = nil)
  if valid_601626 != nil:
    section.add "X-Amz-Credential", valid_601626
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformArn: JString
  ##              : The ARN of the version of the custom platform.
  section = newJObject()
  var valid_601627 = formData.getOrDefault("PlatformArn")
  valid_601627 = validateParameter(valid_601627, JString, required = false,
                                 default = nil)
  if valid_601627 != nil:
    section.add "PlatformArn", valid_601627
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601628: Call_PostDeletePlatformVersion_601615; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified version of a custom platform.
  ## 
  let valid = call_601628.validator(path, query, header, formData, body)
  let scheme = call_601628.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601628.url(scheme.get, call_601628.host, call_601628.base,
                         call_601628.route, valid.getOrDefault("path"))
  result = hook(call_601628, url, valid)

proc call*(call_601629: Call_PostDeletePlatformVersion_601615;
          Action: string = "DeletePlatformVersion"; PlatformArn: string = "";
          Version: string = "2010-12-01"): Recallable =
  ## postDeletePlatformVersion
  ## Deletes the specified version of a custom platform.
  ##   Action: string (required)
  ##   PlatformArn: string
  ##              : The ARN of the version of the custom platform.
  ##   Version: string (required)
  var query_601630 = newJObject()
  var formData_601631 = newJObject()
  add(query_601630, "Action", newJString(Action))
  add(formData_601631, "PlatformArn", newJString(PlatformArn))
  add(query_601630, "Version", newJString(Version))
  result = call_601629.call(nil, query_601630, nil, formData_601631, nil)

var postDeletePlatformVersion* = Call_PostDeletePlatformVersion_601615(
    name: "postDeletePlatformVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeletePlatformVersion",
    validator: validate_PostDeletePlatformVersion_601616, base: "/",
    url: url_PostDeletePlatformVersion_601617,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeletePlatformVersion_601599 = ref object of OpenApiRestCall_600427
proc url_GetDeletePlatformVersion_601601(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeletePlatformVersion_601600(path: JsonNode; query: JsonNode;
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
  var valid_601602 = query.getOrDefault("PlatformArn")
  valid_601602 = validateParameter(valid_601602, JString, required = false,
                                 default = nil)
  if valid_601602 != nil:
    section.add "PlatformArn", valid_601602
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601603 = query.getOrDefault("Action")
  valid_601603 = validateParameter(valid_601603, JString, required = true,
                                 default = newJString("DeletePlatformVersion"))
  if valid_601603 != nil:
    section.add "Action", valid_601603
  var valid_601604 = query.getOrDefault("Version")
  valid_601604 = validateParameter(valid_601604, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601604 != nil:
    section.add "Version", valid_601604
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601605 = header.getOrDefault("X-Amz-Date")
  valid_601605 = validateParameter(valid_601605, JString, required = false,
                                 default = nil)
  if valid_601605 != nil:
    section.add "X-Amz-Date", valid_601605
  var valid_601606 = header.getOrDefault("X-Amz-Security-Token")
  valid_601606 = validateParameter(valid_601606, JString, required = false,
                                 default = nil)
  if valid_601606 != nil:
    section.add "X-Amz-Security-Token", valid_601606
  var valid_601607 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601607 = validateParameter(valid_601607, JString, required = false,
                                 default = nil)
  if valid_601607 != nil:
    section.add "X-Amz-Content-Sha256", valid_601607
  var valid_601608 = header.getOrDefault("X-Amz-Algorithm")
  valid_601608 = validateParameter(valid_601608, JString, required = false,
                                 default = nil)
  if valid_601608 != nil:
    section.add "X-Amz-Algorithm", valid_601608
  var valid_601609 = header.getOrDefault("X-Amz-Signature")
  valid_601609 = validateParameter(valid_601609, JString, required = false,
                                 default = nil)
  if valid_601609 != nil:
    section.add "X-Amz-Signature", valid_601609
  var valid_601610 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601610 = validateParameter(valid_601610, JString, required = false,
                                 default = nil)
  if valid_601610 != nil:
    section.add "X-Amz-SignedHeaders", valid_601610
  var valid_601611 = header.getOrDefault("X-Amz-Credential")
  valid_601611 = validateParameter(valid_601611, JString, required = false,
                                 default = nil)
  if valid_601611 != nil:
    section.add "X-Amz-Credential", valid_601611
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601612: Call_GetDeletePlatformVersion_601599; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified version of a custom platform.
  ## 
  let valid = call_601612.validator(path, query, header, formData, body)
  let scheme = call_601612.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601612.url(scheme.get, call_601612.host, call_601612.base,
                         call_601612.route, valid.getOrDefault("path"))
  result = hook(call_601612, url, valid)

proc call*(call_601613: Call_GetDeletePlatformVersion_601599;
          PlatformArn: string = ""; Action: string = "DeletePlatformVersion";
          Version: string = "2010-12-01"): Recallable =
  ## getDeletePlatformVersion
  ## Deletes the specified version of a custom platform.
  ##   PlatformArn: string
  ##              : The ARN of the version of the custom platform.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601614 = newJObject()
  add(query_601614, "PlatformArn", newJString(PlatformArn))
  add(query_601614, "Action", newJString(Action))
  add(query_601614, "Version", newJString(Version))
  result = call_601613.call(nil, query_601614, nil, nil, nil)

var getDeletePlatformVersion* = Call_GetDeletePlatformVersion_601599(
    name: "getDeletePlatformVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeletePlatformVersion",
    validator: validate_GetDeletePlatformVersion_601600, base: "/",
    url: url_GetDeletePlatformVersion_601601, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAccountAttributes_601647 = ref object of OpenApiRestCall_600427
proc url_PostDescribeAccountAttributes_601649(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeAccountAttributes_601648(path: JsonNode; query: JsonNode;
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
  var valid_601650 = query.getOrDefault("Action")
  valid_601650 = validateParameter(valid_601650, JString, required = true, default = newJString(
      "DescribeAccountAttributes"))
  if valid_601650 != nil:
    section.add "Action", valid_601650
  var valid_601651 = query.getOrDefault("Version")
  valid_601651 = validateParameter(valid_601651, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601651 != nil:
    section.add "Version", valid_601651
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601652 = header.getOrDefault("X-Amz-Date")
  valid_601652 = validateParameter(valid_601652, JString, required = false,
                                 default = nil)
  if valid_601652 != nil:
    section.add "X-Amz-Date", valid_601652
  var valid_601653 = header.getOrDefault("X-Amz-Security-Token")
  valid_601653 = validateParameter(valid_601653, JString, required = false,
                                 default = nil)
  if valid_601653 != nil:
    section.add "X-Amz-Security-Token", valid_601653
  var valid_601654 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601654 = validateParameter(valid_601654, JString, required = false,
                                 default = nil)
  if valid_601654 != nil:
    section.add "X-Amz-Content-Sha256", valid_601654
  var valid_601655 = header.getOrDefault("X-Amz-Algorithm")
  valid_601655 = validateParameter(valid_601655, JString, required = false,
                                 default = nil)
  if valid_601655 != nil:
    section.add "X-Amz-Algorithm", valid_601655
  var valid_601656 = header.getOrDefault("X-Amz-Signature")
  valid_601656 = validateParameter(valid_601656, JString, required = false,
                                 default = nil)
  if valid_601656 != nil:
    section.add "X-Amz-Signature", valid_601656
  var valid_601657 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601657 = validateParameter(valid_601657, JString, required = false,
                                 default = nil)
  if valid_601657 != nil:
    section.add "X-Amz-SignedHeaders", valid_601657
  var valid_601658 = header.getOrDefault("X-Amz-Credential")
  valid_601658 = validateParameter(valid_601658, JString, required = false,
                                 default = nil)
  if valid_601658 != nil:
    section.add "X-Amz-Credential", valid_601658
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601659: Call_PostDescribeAccountAttributes_601647; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ## 
  let valid = call_601659.validator(path, query, header, formData, body)
  let scheme = call_601659.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601659.url(scheme.get, call_601659.host, call_601659.base,
                         call_601659.route, valid.getOrDefault("path"))
  result = hook(call_601659, url, valid)

proc call*(call_601660: Call_PostDescribeAccountAttributes_601647;
          Action: string = "DescribeAccountAttributes";
          Version: string = "2010-12-01"): Recallable =
  ## postDescribeAccountAttributes
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601661 = newJObject()
  add(query_601661, "Action", newJString(Action))
  add(query_601661, "Version", newJString(Version))
  result = call_601660.call(nil, query_601661, nil, nil, nil)

var postDescribeAccountAttributes* = Call_PostDescribeAccountAttributes_601647(
    name: "postDescribeAccountAttributes", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeAccountAttributes",
    validator: validate_PostDescribeAccountAttributes_601648, base: "/",
    url: url_PostDescribeAccountAttributes_601649,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAccountAttributes_601632 = ref object of OpenApiRestCall_600427
proc url_GetDescribeAccountAttributes_601634(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeAccountAttributes_601633(path: JsonNode; query: JsonNode;
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
  var valid_601635 = query.getOrDefault("Action")
  valid_601635 = validateParameter(valid_601635, JString, required = true, default = newJString(
      "DescribeAccountAttributes"))
  if valid_601635 != nil:
    section.add "Action", valid_601635
  var valid_601636 = query.getOrDefault("Version")
  valid_601636 = validateParameter(valid_601636, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601636 != nil:
    section.add "Version", valid_601636
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601637 = header.getOrDefault("X-Amz-Date")
  valid_601637 = validateParameter(valid_601637, JString, required = false,
                                 default = nil)
  if valid_601637 != nil:
    section.add "X-Amz-Date", valid_601637
  var valid_601638 = header.getOrDefault("X-Amz-Security-Token")
  valid_601638 = validateParameter(valid_601638, JString, required = false,
                                 default = nil)
  if valid_601638 != nil:
    section.add "X-Amz-Security-Token", valid_601638
  var valid_601639 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601639 = validateParameter(valid_601639, JString, required = false,
                                 default = nil)
  if valid_601639 != nil:
    section.add "X-Amz-Content-Sha256", valid_601639
  var valid_601640 = header.getOrDefault("X-Amz-Algorithm")
  valid_601640 = validateParameter(valid_601640, JString, required = false,
                                 default = nil)
  if valid_601640 != nil:
    section.add "X-Amz-Algorithm", valid_601640
  var valid_601641 = header.getOrDefault("X-Amz-Signature")
  valid_601641 = validateParameter(valid_601641, JString, required = false,
                                 default = nil)
  if valid_601641 != nil:
    section.add "X-Amz-Signature", valid_601641
  var valid_601642 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601642 = validateParameter(valid_601642, JString, required = false,
                                 default = nil)
  if valid_601642 != nil:
    section.add "X-Amz-SignedHeaders", valid_601642
  var valid_601643 = header.getOrDefault("X-Amz-Credential")
  valid_601643 = validateParameter(valid_601643, JString, required = false,
                                 default = nil)
  if valid_601643 != nil:
    section.add "X-Amz-Credential", valid_601643
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601644: Call_GetDescribeAccountAttributes_601632; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ## 
  let valid = call_601644.validator(path, query, header, formData, body)
  let scheme = call_601644.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601644.url(scheme.get, call_601644.host, call_601644.base,
                         call_601644.route, valid.getOrDefault("path"))
  result = hook(call_601644, url, valid)

proc call*(call_601645: Call_GetDescribeAccountAttributes_601632;
          Action: string = "DescribeAccountAttributes";
          Version: string = "2010-12-01"): Recallable =
  ## getDescribeAccountAttributes
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601646 = newJObject()
  add(query_601646, "Action", newJString(Action))
  add(query_601646, "Version", newJString(Version))
  result = call_601645.call(nil, query_601646, nil, nil, nil)

var getDescribeAccountAttributes* = Call_GetDescribeAccountAttributes_601632(
    name: "getDescribeAccountAttributes", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeAccountAttributes",
    validator: validate_GetDescribeAccountAttributes_601633, base: "/",
    url: url_GetDescribeAccountAttributes_601634,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeApplicationVersions_601681 = ref object of OpenApiRestCall_600427
proc url_PostDescribeApplicationVersions_601683(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeApplicationVersions_601682(path: JsonNode;
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
  var valid_601684 = query.getOrDefault("Action")
  valid_601684 = validateParameter(valid_601684, JString, required = true, default = newJString(
      "DescribeApplicationVersions"))
  if valid_601684 != nil:
    section.add "Action", valid_601684
  var valid_601685 = query.getOrDefault("Version")
  valid_601685 = validateParameter(valid_601685, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601685 != nil:
    section.add "Version", valid_601685
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601686 = header.getOrDefault("X-Amz-Date")
  valid_601686 = validateParameter(valid_601686, JString, required = false,
                                 default = nil)
  if valid_601686 != nil:
    section.add "X-Amz-Date", valid_601686
  var valid_601687 = header.getOrDefault("X-Amz-Security-Token")
  valid_601687 = validateParameter(valid_601687, JString, required = false,
                                 default = nil)
  if valid_601687 != nil:
    section.add "X-Amz-Security-Token", valid_601687
  var valid_601688 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601688 = validateParameter(valid_601688, JString, required = false,
                                 default = nil)
  if valid_601688 != nil:
    section.add "X-Amz-Content-Sha256", valid_601688
  var valid_601689 = header.getOrDefault("X-Amz-Algorithm")
  valid_601689 = validateParameter(valid_601689, JString, required = false,
                                 default = nil)
  if valid_601689 != nil:
    section.add "X-Amz-Algorithm", valid_601689
  var valid_601690 = header.getOrDefault("X-Amz-Signature")
  valid_601690 = validateParameter(valid_601690, JString, required = false,
                                 default = nil)
  if valid_601690 != nil:
    section.add "X-Amz-Signature", valid_601690
  var valid_601691 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601691 = validateParameter(valid_601691, JString, required = false,
                                 default = nil)
  if valid_601691 != nil:
    section.add "X-Amz-SignedHeaders", valid_601691
  var valid_601692 = header.getOrDefault("X-Amz-Credential")
  valid_601692 = validateParameter(valid_601692, JString, required = false,
                                 default = nil)
  if valid_601692 != nil:
    section.add "X-Amz-Credential", valid_601692
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
  var valid_601693 = formData.getOrDefault("NextToken")
  valid_601693 = validateParameter(valid_601693, JString, required = false,
                                 default = nil)
  if valid_601693 != nil:
    section.add "NextToken", valid_601693
  var valid_601694 = formData.getOrDefault("ApplicationName")
  valid_601694 = validateParameter(valid_601694, JString, required = false,
                                 default = nil)
  if valid_601694 != nil:
    section.add "ApplicationName", valid_601694
  var valid_601695 = formData.getOrDefault("MaxRecords")
  valid_601695 = validateParameter(valid_601695, JInt, required = false, default = nil)
  if valid_601695 != nil:
    section.add "MaxRecords", valid_601695
  var valid_601696 = formData.getOrDefault("VersionLabels")
  valid_601696 = validateParameter(valid_601696, JArray, required = false,
                                 default = nil)
  if valid_601696 != nil:
    section.add "VersionLabels", valid_601696
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601697: Call_PostDescribeApplicationVersions_601681;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieve a list of application versions.
  ## 
  let valid = call_601697.validator(path, query, header, formData, body)
  let scheme = call_601697.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601697.url(scheme.get, call_601697.host, call_601697.base,
                         call_601697.route, valid.getOrDefault("path"))
  result = hook(call_601697, url, valid)

proc call*(call_601698: Call_PostDescribeApplicationVersions_601681;
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
  var query_601699 = newJObject()
  var formData_601700 = newJObject()
  add(formData_601700, "NextToken", newJString(NextToken))
  add(query_601699, "Action", newJString(Action))
  add(formData_601700, "ApplicationName", newJString(ApplicationName))
  add(formData_601700, "MaxRecords", newJInt(MaxRecords))
  add(query_601699, "Version", newJString(Version))
  if VersionLabels != nil:
    formData_601700.add "VersionLabels", VersionLabels
  result = call_601698.call(nil, query_601699, nil, formData_601700, nil)

var postDescribeApplicationVersions* = Call_PostDescribeApplicationVersions_601681(
    name: "postDescribeApplicationVersions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplicationVersions",
    validator: validate_PostDescribeApplicationVersions_601682, base: "/",
    url: url_PostDescribeApplicationVersions_601683,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeApplicationVersions_601662 = ref object of OpenApiRestCall_600427
proc url_GetDescribeApplicationVersions_601664(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeApplicationVersions_601663(path: JsonNode;
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
  var valid_601665 = query.getOrDefault("MaxRecords")
  valid_601665 = validateParameter(valid_601665, JInt, required = false, default = nil)
  if valid_601665 != nil:
    section.add "MaxRecords", valid_601665
  var valid_601666 = query.getOrDefault("ApplicationName")
  valid_601666 = validateParameter(valid_601666, JString, required = false,
                                 default = nil)
  if valid_601666 != nil:
    section.add "ApplicationName", valid_601666
  var valid_601667 = query.getOrDefault("NextToken")
  valid_601667 = validateParameter(valid_601667, JString, required = false,
                                 default = nil)
  if valid_601667 != nil:
    section.add "NextToken", valid_601667
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601668 = query.getOrDefault("Action")
  valid_601668 = validateParameter(valid_601668, JString, required = true, default = newJString(
      "DescribeApplicationVersions"))
  if valid_601668 != nil:
    section.add "Action", valid_601668
  var valid_601669 = query.getOrDefault("VersionLabels")
  valid_601669 = validateParameter(valid_601669, JArray, required = false,
                                 default = nil)
  if valid_601669 != nil:
    section.add "VersionLabels", valid_601669
  var valid_601670 = query.getOrDefault("Version")
  valid_601670 = validateParameter(valid_601670, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601670 != nil:
    section.add "Version", valid_601670
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601671 = header.getOrDefault("X-Amz-Date")
  valid_601671 = validateParameter(valid_601671, JString, required = false,
                                 default = nil)
  if valid_601671 != nil:
    section.add "X-Amz-Date", valid_601671
  var valid_601672 = header.getOrDefault("X-Amz-Security-Token")
  valid_601672 = validateParameter(valid_601672, JString, required = false,
                                 default = nil)
  if valid_601672 != nil:
    section.add "X-Amz-Security-Token", valid_601672
  var valid_601673 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601673 = validateParameter(valid_601673, JString, required = false,
                                 default = nil)
  if valid_601673 != nil:
    section.add "X-Amz-Content-Sha256", valid_601673
  var valid_601674 = header.getOrDefault("X-Amz-Algorithm")
  valid_601674 = validateParameter(valid_601674, JString, required = false,
                                 default = nil)
  if valid_601674 != nil:
    section.add "X-Amz-Algorithm", valid_601674
  var valid_601675 = header.getOrDefault("X-Amz-Signature")
  valid_601675 = validateParameter(valid_601675, JString, required = false,
                                 default = nil)
  if valid_601675 != nil:
    section.add "X-Amz-Signature", valid_601675
  var valid_601676 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601676 = validateParameter(valid_601676, JString, required = false,
                                 default = nil)
  if valid_601676 != nil:
    section.add "X-Amz-SignedHeaders", valid_601676
  var valid_601677 = header.getOrDefault("X-Amz-Credential")
  valid_601677 = validateParameter(valid_601677, JString, required = false,
                                 default = nil)
  if valid_601677 != nil:
    section.add "X-Amz-Credential", valid_601677
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601678: Call_GetDescribeApplicationVersions_601662; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a list of application versions.
  ## 
  let valid = call_601678.validator(path, query, header, formData, body)
  let scheme = call_601678.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601678.url(scheme.get, call_601678.host, call_601678.base,
                         call_601678.route, valid.getOrDefault("path"))
  result = hook(call_601678, url, valid)

proc call*(call_601679: Call_GetDescribeApplicationVersions_601662;
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
  var query_601680 = newJObject()
  add(query_601680, "MaxRecords", newJInt(MaxRecords))
  add(query_601680, "ApplicationName", newJString(ApplicationName))
  add(query_601680, "NextToken", newJString(NextToken))
  add(query_601680, "Action", newJString(Action))
  if VersionLabels != nil:
    query_601680.add "VersionLabels", VersionLabels
  add(query_601680, "Version", newJString(Version))
  result = call_601679.call(nil, query_601680, nil, nil, nil)

var getDescribeApplicationVersions* = Call_GetDescribeApplicationVersions_601662(
    name: "getDescribeApplicationVersions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplicationVersions",
    validator: validate_GetDescribeApplicationVersions_601663, base: "/",
    url: url_GetDescribeApplicationVersions_601664,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeApplications_601717 = ref object of OpenApiRestCall_600427
proc url_PostDescribeApplications_601719(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeApplications_601718(path: JsonNode; query: JsonNode;
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
  var valid_601720 = query.getOrDefault("Action")
  valid_601720 = validateParameter(valid_601720, JString, required = true,
                                 default = newJString("DescribeApplications"))
  if valid_601720 != nil:
    section.add "Action", valid_601720
  var valid_601721 = query.getOrDefault("Version")
  valid_601721 = validateParameter(valid_601721, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601721 != nil:
    section.add "Version", valid_601721
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601722 = header.getOrDefault("X-Amz-Date")
  valid_601722 = validateParameter(valid_601722, JString, required = false,
                                 default = nil)
  if valid_601722 != nil:
    section.add "X-Amz-Date", valid_601722
  var valid_601723 = header.getOrDefault("X-Amz-Security-Token")
  valid_601723 = validateParameter(valid_601723, JString, required = false,
                                 default = nil)
  if valid_601723 != nil:
    section.add "X-Amz-Security-Token", valid_601723
  var valid_601724 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601724 = validateParameter(valid_601724, JString, required = false,
                                 default = nil)
  if valid_601724 != nil:
    section.add "X-Amz-Content-Sha256", valid_601724
  var valid_601725 = header.getOrDefault("X-Amz-Algorithm")
  valid_601725 = validateParameter(valid_601725, JString, required = false,
                                 default = nil)
  if valid_601725 != nil:
    section.add "X-Amz-Algorithm", valid_601725
  var valid_601726 = header.getOrDefault("X-Amz-Signature")
  valid_601726 = validateParameter(valid_601726, JString, required = false,
                                 default = nil)
  if valid_601726 != nil:
    section.add "X-Amz-Signature", valid_601726
  var valid_601727 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601727 = validateParameter(valid_601727, JString, required = false,
                                 default = nil)
  if valid_601727 != nil:
    section.add "X-Amz-SignedHeaders", valid_601727
  var valid_601728 = header.getOrDefault("X-Amz-Credential")
  valid_601728 = validateParameter(valid_601728, JString, required = false,
                                 default = nil)
  if valid_601728 != nil:
    section.add "X-Amz-Credential", valid_601728
  result.add "header", section
  ## parameters in `formData` object:
  ##   ApplicationNames: JArray
  ##                   : If specified, AWS Elastic Beanstalk restricts the returned descriptions to only include those with the specified names.
  section = newJObject()
  var valid_601729 = formData.getOrDefault("ApplicationNames")
  valid_601729 = validateParameter(valid_601729, JArray, required = false,
                                 default = nil)
  if valid_601729 != nil:
    section.add "ApplicationNames", valid_601729
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601730: Call_PostDescribeApplications_601717; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the descriptions of existing applications.
  ## 
  let valid = call_601730.validator(path, query, header, formData, body)
  let scheme = call_601730.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601730.url(scheme.get, call_601730.host, call_601730.base,
                         call_601730.route, valid.getOrDefault("path"))
  result = hook(call_601730, url, valid)

proc call*(call_601731: Call_PostDescribeApplications_601717;
          ApplicationNames: JsonNode = nil; Action: string = "DescribeApplications";
          Version: string = "2010-12-01"): Recallable =
  ## postDescribeApplications
  ## Returns the descriptions of existing applications.
  ##   ApplicationNames: JArray
  ##                   : If specified, AWS Elastic Beanstalk restricts the returned descriptions to only include those with the specified names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601732 = newJObject()
  var formData_601733 = newJObject()
  if ApplicationNames != nil:
    formData_601733.add "ApplicationNames", ApplicationNames
  add(query_601732, "Action", newJString(Action))
  add(query_601732, "Version", newJString(Version))
  result = call_601731.call(nil, query_601732, nil, formData_601733, nil)

var postDescribeApplications* = Call_PostDescribeApplications_601717(
    name: "postDescribeApplications", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplications",
    validator: validate_PostDescribeApplications_601718, base: "/",
    url: url_PostDescribeApplications_601719, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeApplications_601701 = ref object of OpenApiRestCall_600427
proc url_GetDescribeApplications_601703(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeApplications_601702(path: JsonNode; query: JsonNode;
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
  var valid_601704 = query.getOrDefault("ApplicationNames")
  valid_601704 = validateParameter(valid_601704, JArray, required = false,
                                 default = nil)
  if valid_601704 != nil:
    section.add "ApplicationNames", valid_601704
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601705 = query.getOrDefault("Action")
  valid_601705 = validateParameter(valid_601705, JString, required = true,
                                 default = newJString("DescribeApplications"))
  if valid_601705 != nil:
    section.add "Action", valid_601705
  var valid_601706 = query.getOrDefault("Version")
  valid_601706 = validateParameter(valid_601706, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601706 != nil:
    section.add "Version", valid_601706
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601707 = header.getOrDefault("X-Amz-Date")
  valid_601707 = validateParameter(valid_601707, JString, required = false,
                                 default = nil)
  if valid_601707 != nil:
    section.add "X-Amz-Date", valid_601707
  var valid_601708 = header.getOrDefault("X-Amz-Security-Token")
  valid_601708 = validateParameter(valid_601708, JString, required = false,
                                 default = nil)
  if valid_601708 != nil:
    section.add "X-Amz-Security-Token", valid_601708
  var valid_601709 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601709 = validateParameter(valid_601709, JString, required = false,
                                 default = nil)
  if valid_601709 != nil:
    section.add "X-Amz-Content-Sha256", valid_601709
  var valid_601710 = header.getOrDefault("X-Amz-Algorithm")
  valid_601710 = validateParameter(valid_601710, JString, required = false,
                                 default = nil)
  if valid_601710 != nil:
    section.add "X-Amz-Algorithm", valid_601710
  var valid_601711 = header.getOrDefault("X-Amz-Signature")
  valid_601711 = validateParameter(valid_601711, JString, required = false,
                                 default = nil)
  if valid_601711 != nil:
    section.add "X-Amz-Signature", valid_601711
  var valid_601712 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601712 = validateParameter(valid_601712, JString, required = false,
                                 default = nil)
  if valid_601712 != nil:
    section.add "X-Amz-SignedHeaders", valid_601712
  var valid_601713 = header.getOrDefault("X-Amz-Credential")
  valid_601713 = validateParameter(valid_601713, JString, required = false,
                                 default = nil)
  if valid_601713 != nil:
    section.add "X-Amz-Credential", valid_601713
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601714: Call_GetDescribeApplications_601701; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the descriptions of existing applications.
  ## 
  let valid = call_601714.validator(path, query, header, formData, body)
  let scheme = call_601714.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601714.url(scheme.get, call_601714.host, call_601714.base,
                         call_601714.route, valid.getOrDefault("path"))
  result = hook(call_601714, url, valid)

proc call*(call_601715: Call_GetDescribeApplications_601701;
          ApplicationNames: JsonNode = nil; Action: string = "DescribeApplications";
          Version: string = "2010-12-01"): Recallable =
  ## getDescribeApplications
  ## Returns the descriptions of existing applications.
  ##   ApplicationNames: JArray
  ##                   : If specified, AWS Elastic Beanstalk restricts the returned descriptions to only include those with the specified names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601716 = newJObject()
  if ApplicationNames != nil:
    query_601716.add "ApplicationNames", ApplicationNames
  add(query_601716, "Action", newJString(Action))
  add(query_601716, "Version", newJString(Version))
  result = call_601715.call(nil, query_601716, nil, nil, nil)

var getDescribeApplications* = Call_GetDescribeApplications_601701(
    name: "getDescribeApplications", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplications",
    validator: validate_GetDescribeApplications_601702, base: "/",
    url: url_GetDescribeApplications_601703, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeConfigurationOptions_601755 = ref object of OpenApiRestCall_600427
proc url_PostDescribeConfigurationOptions_601757(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeConfigurationOptions_601756(path: JsonNode;
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
  var valid_601758 = query.getOrDefault("Action")
  valid_601758 = validateParameter(valid_601758, JString, required = true, default = newJString(
      "DescribeConfigurationOptions"))
  if valid_601758 != nil:
    section.add "Action", valid_601758
  var valid_601759 = query.getOrDefault("Version")
  valid_601759 = validateParameter(valid_601759, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601759 != nil:
    section.add "Version", valid_601759
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601760 = header.getOrDefault("X-Amz-Date")
  valid_601760 = validateParameter(valid_601760, JString, required = false,
                                 default = nil)
  if valid_601760 != nil:
    section.add "X-Amz-Date", valid_601760
  var valid_601761 = header.getOrDefault("X-Amz-Security-Token")
  valid_601761 = validateParameter(valid_601761, JString, required = false,
                                 default = nil)
  if valid_601761 != nil:
    section.add "X-Amz-Security-Token", valid_601761
  var valid_601762 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601762 = validateParameter(valid_601762, JString, required = false,
                                 default = nil)
  if valid_601762 != nil:
    section.add "X-Amz-Content-Sha256", valid_601762
  var valid_601763 = header.getOrDefault("X-Amz-Algorithm")
  valid_601763 = validateParameter(valid_601763, JString, required = false,
                                 default = nil)
  if valid_601763 != nil:
    section.add "X-Amz-Algorithm", valid_601763
  var valid_601764 = header.getOrDefault("X-Amz-Signature")
  valid_601764 = validateParameter(valid_601764, JString, required = false,
                                 default = nil)
  if valid_601764 != nil:
    section.add "X-Amz-Signature", valid_601764
  var valid_601765 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601765 = validateParameter(valid_601765, JString, required = false,
                                 default = nil)
  if valid_601765 != nil:
    section.add "X-Amz-SignedHeaders", valid_601765
  var valid_601766 = header.getOrDefault("X-Amz-Credential")
  valid_601766 = validateParameter(valid_601766, JString, required = false,
                                 default = nil)
  if valid_601766 != nil:
    section.add "X-Amz-Credential", valid_601766
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
  var valid_601767 = formData.getOrDefault("Options")
  valid_601767 = validateParameter(valid_601767, JArray, required = false,
                                 default = nil)
  if valid_601767 != nil:
    section.add "Options", valid_601767
  var valid_601768 = formData.getOrDefault("SolutionStackName")
  valid_601768 = validateParameter(valid_601768, JString, required = false,
                                 default = nil)
  if valid_601768 != nil:
    section.add "SolutionStackName", valid_601768
  var valid_601769 = formData.getOrDefault("EnvironmentName")
  valid_601769 = validateParameter(valid_601769, JString, required = false,
                                 default = nil)
  if valid_601769 != nil:
    section.add "EnvironmentName", valid_601769
  var valid_601770 = formData.getOrDefault("ApplicationName")
  valid_601770 = validateParameter(valid_601770, JString, required = false,
                                 default = nil)
  if valid_601770 != nil:
    section.add "ApplicationName", valid_601770
  var valid_601771 = formData.getOrDefault("PlatformArn")
  valid_601771 = validateParameter(valid_601771, JString, required = false,
                                 default = nil)
  if valid_601771 != nil:
    section.add "PlatformArn", valid_601771
  var valid_601772 = formData.getOrDefault("TemplateName")
  valid_601772 = validateParameter(valid_601772, JString, required = false,
                                 default = nil)
  if valid_601772 != nil:
    section.add "TemplateName", valid_601772
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601773: Call_PostDescribeConfigurationOptions_601755;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the configuration options that are used in a particular configuration template or environment, or that a specified solution stack defines. The description includes the values the options, their default values, and an indication of the required action on a running environment if an option value is changed.
  ## 
  let valid = call_601773.validator(path, query, header, formData, body)
  let scheme = call_601773.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601773.url(scheme.get, call_601773.host, call_601773.base,
                         call_601773.route, valid.getOrDefault("path"))
  result = hook(call_601773, url, valid)

proc call*(call_601774: Call_PostDescribeConfigurationOptions_601755;
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
  var query_601775 = newJObject()
  var formData_601776 = newJObject()
  if Options != nil:
    formData_601776.add "Options", Options
  add(formData_601776, "SolutionStackName", newJString(SolutionStackName))
  add(formData_601776, "EnvironmentName", newJString(EnvironmentName))
  add(query_601775, "Action", newJString(Action))
  add(formData_601776, "ApplicationName", newJString(ApplicationName))
  add(formData_601776, "PlatformArn", newJString(PlatformArn))
  add(formData_601776, "TemplateName", newJString(TemplateName))
  add(query_601775, "Version", newJString(Version))
  result = call_601774.call(nil, query_601775, nil, formData_601776, nil)

var postDescribeConfigurationOptions* = Call_PostDescribeConfigurationOptions_601755(
    name: "postDescribeConfigurationOptions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationOptions",
    validator: validate_PostDescribeConfigurationOptions_601756, base: "/",
    url: url_PostDescribeConfigurationOptions_601757,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeConfigurationOptions_601734 = ref object of OpenApiRestCall_600427
proc url_GetDescribeConfigurationOptions_601736(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeConfigurationOptions_601735(path: JsonNode;
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
  var valid_601737 = query.getOrDefault("Options")
  valid_601737 = validateParameter(valid_601737, JArray, required = false,
                                 default = nil)
  if valid_601737 != nil:
    section.add "Options", valid_601737
  var valid_601738 = query.getOrDefault("ApplicationName")
  valid_601738 = validateParameter(valid_601738, JString, required = false,
                                 default = nil)
  if valid_601738 != nil:
    section.add "ApplicationName", valid_601738
  var valid_601739 = query.getOrDefault("PlatformArn")
  valid_601739 = validateParameter(valid_601739, JString, required = false,
                                 default = nil)
  if valid_601739 != nil:
    section.add "PlatformArn", valid_601739
  var valid_601740 = query.getOrDefault("EnvironmentName")
  valid_601740 = validateParameter(valid_601740, JString, required = false,
                                 default = nil)
  if valid_601740 != nil:
    section.add "EnvironmentName", valid_601740
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601741 = query.getOrDefault("Action")
  valid_601741 = validateParameter(valid_601741, JString, required = true, default = newJString(
      "DescribeConfigurationOptions"))
  if valid_601741 != nil:
    section.add "Action", valid_601741
  var valid_601742 = query.getOrDefault("SolutionStackName")
  valid_601742 = validateParameter(valid_601742, JString, required = false,
                                 default = nil)
  if valid_601742 != nil:
    section.add "SolutionStackName", valid_601742
  var valid_601743 = query.getOrDefault("TemplateName")
  valid_601743 = validateParameter(valid_601743, JString, required = false,
                                 default = nil)
  if valid_601743 != nil:
    section.add "TemplateName", valid_601743
  var valid_601744 = query.getOrDefault("Version")
  valid_601744 = validateParameter(valid_601744, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601744 != nil:
    section.add "Version", valid_601744
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601745 = header.getOrDefault("X-Amz-Date")
  valid_601745 = validateParameter(valid_601745, JString, required = false,
                                 default = nil)
  if valid_601745 != nil:
    section.add "X-Amz-Date", valid_601745
  var valid_601746 = header.getOrDefault("X-Amz-Security-Token")
  valid_601746 = validateParameter(valid_601746, JString, required = false,
                                 default = nil)
  if valid_601746 != nil:
    section.add "X-Amz-Security-Token", valid_601746
  var valid_601747 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601747 = validateParameter(valid_601747, JString, required = false,
                                 default = nil)
  if valid_601747 != nil:
    section.add "X-Amz-Content-Sha256", valid_601747
  var valid_601748 = header.getOrDefault("X-Amz-Algorithm")
  valid_601748 = validateParameter(valid_601748, JString, required = false,
                                 default = nil)
  if valid_601748 != nil:
    section.add "X-Amz-Algorithm", valid_601748
  var valid_601749 = header.getOrDefault("X-Amz-Signature")
  valid_601749 = validateParameter(valid_601749, JString, required = false,
                                 default = nil)
  if valid_601749 != nil:
    section.add "X-Amz-Signature", valid_601749
  var valid_601750 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601750 = validateParameter(valid_601750, JString, required = false,
                                 default = nil)
  if valid_601750 != nil:
    section.add "X-Amz-SignedHeaders", valid_601750
  var valid_601751 = header.getOrDefault("X-Amz-Credential")
  valid_601751 = validateParameter(valid_601751, JString, required = false,
                                 default = nil)
  if valid_601751 != nil:
    section.add "X-Amz-Credential", valid_601751
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601752: Call_GetDescribeConfigurationOptions_601734;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the configuration options that are used in a particular configuration template or environment, or that a specified solution stack defines. The description includes the values the options, their default values, and an indication of the required action on a running environment if an option value is changed.
  ## 
  let valid = call_601752.validator(path, query, header, formData, body)
  let scheme = call_601752.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601752.url(scheme.get, call_601752.host, call_601752.base,
                         call_601752.route, valid.getOrDefault("path"))
  result = hook(call_601752, url, valid)

proc call*(call_601753: Call_GetDescribeConfigurationOptions_601734;
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
  var query_601754 = newJObject()
  if Options != nil:
    query_601754.add "Options", Options
  add(query_601754, "ApplicationName", newJString(ApplicationName))
  add(query_601754, "PlatformArn", newJString(PlatformArn))
  add(query_601754, "EnvironmentName", newJString(EnvironmentName))
  add(query_601754, "Action", newJString(Action))
  add(query_601754, "SolutionStackName", newJString(SolutionStackName))
  add(query_601754, "TemplateName", newJString(TemplateName))
  add(query_601754, "Version", newJString(Version))
  result = call_601753.call(nil, query_601754, nil, nil, nil)

var getDescribeConfigurationOptions* = Call_GetDescribeConfigurationOptions_601734(
    name: "getDescribeConfigurationOptions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationOptions",
    validator: validate_GetDescribeConfigurationOptions_601735, base: "/",
    url: url_GetDescribeConfigurationOptions_601736,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeConfigurationSettings_601795 = ref object of OpenApiRestCall_600427
proc url_PostDescribeConfigurationSettings_601797(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeConfigurationSettings_601796(path: JsonNode;
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
  var valid_601798 = query.getOrDefault("Action")
  valid_601798 = validateParameter(valid_601798, JString, required = true, default = newJString(
      "DescribeConfigurationSettings"))
  if valid_601798 != nil:
    section.add "Action", valid_601798
  var valid_601799 = query.getOrDefault("Version")
  valid_601799 = validateParameter(valid_601799, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601799 != nil:
    section.add "Version", valid_601799
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601800 = header.getOrDefault("X-Amz-Date")
  valid_601800 = validateParameter(valid_601800, JString, required = false,
                                 default = nil)
  if valid_601800 != nil:
    section.add "X-Amz-Date", valid_601800
  var valid_601801 = header.getOrDefault("X-Amz-Security-Token")
  valid_601801 = validateParameter(valid_601801, JString, required = false,
                                 default = nil)
  if valid_601801 != nil:
    section.add "X-Amz-Security-Token", valid_601801
  var valid_601802 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601802 = validateParameter(valid_601802, JString, required = false,
                                 default = nil)
  if valid_601802 != nil:
    section.add "X-Amz-Content-Sha256", valid_601802
  var valid_601803 = header.getOrDefault("X-Amz-Algorithm")
  valid_601803 = validateParameter(valid_601803, JString, required = false,
                                 default = nil)
  if valid_601803 != nil:
    section.add "X-Amz-Algorithm", valid_601803
  var valid_601804 = header.getOrDefault("X-Amz-Signature")
  valid_601804 = validateParameter(valid_601804, JString, required = false,
                                 default = nil)
  if valid_601804 != nil:
    section.add "X-Amz-Signature", valid_601804
  var valid_601805 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601805 = validateParameter(valid_601805, JString, required = false,
                                 default = nil)
  if valid_601805 != nil:
    section.add "X-Amz-SignedHeaders", valid_601805
  var valid_601806 = header.getOrDefault("X-Amz-Credential")
  valid_601806 = validateParameter(valid_601806, JString, required = false,
                                 default = nil)
  if valid_601806 != nil:
    section.add "X-Amz-Credential", valid_601806
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to describe.</p> <p> Condition: You must specify either this or a TemplateName, but not both. If you specify both, AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   ApplicationName: JString (required)
  ##                  : The application for the environment or configuration template.
  ##   TemplateName: JString
  ##               : <p>The name of the configuration template to describe.</p> <p> Conditional: You must specify either this parameter or an EnvironmentName, but not both. If you specify both, AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. If you do not specify either, AWS Elastic Beanstalk returns a <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_601807 = formData.getOrDefault("EnvironmentName")
  valid_601807 = validateParameter(valid_601807, JString, required = false,
                                 default = nil)
  if valid_601807 != nil:
    section.add "EnvironmentName", valid_601807
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_601808 = formData.getOrDefault("ApplicationName")
  valid_601808 = validateParameter(valid_601808, JString, required = true,
                                 default = nil)
  if valid_601808 != nil:
    section.add "ApplicationName", valid_601808
  var valid_601809 = formData.getOrDefault("TemplateName")
  valid_601809 = validateParameter(valid_601809, JString, required = false,
                                 default = nil)
  if valid_601809 != nil:
    section.add "TemplateName", valid_601809
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601810: Call_PostDescribeConfigurationSettings_601795;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a description of the settings for the specified configuration set, that is, either a configuration template or the configuration set associated with a running environment.</p> <p>When describing the settings for the configuration set associated with a running environment, it is possible to receive two sets of setting descriptions. One is the deployed configuration set, and the other is a draft configuration of an environment that is either in the process of deployment or that failed to deploy.</p> <p>Related Topics</p> <ul> <li> <p> <a>DeleteEnvironmentConfiguration</a> </p> </li> </ul>
  ## 
  let valid = call_601810.validator(path, query, header, formData, body)
  let scheme = call_601810.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601810.url(scheme.get, call_601810.host, call_601810.base,
                         call_601810.route, valid.getOrDefault("path"))
  result = hook(call_601810, url, valid)

proc call*(call_601811: Call_PostDescribeConfigurationSettings_601795;
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
  var query_601812 = newJObject()
  var formData_601813 = newJObject()
  add(formData_601813, "EnvironmentName", newJString(EnvironmentName))
  add(query_601812, "Action", newJString(Action))
  add(formData_601813, "ApplicationName", newJString(ApplicationName))
  add(formData_601813, "TemplateName", newJString(TemplateName))
  add(query_601812, "Version", newJString(Version))
  result = call_601811.call(nil, query_601812, nil, formData_601813, nil)

var postDescribeConfigurationSettings* = Call_PostDescribeConfigurationSettings_601795(
    name: "postDescribeConfigurationSettings", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationSettings",
    validator: validate_PostDescribeConfigurationSettings_601796, base: "/",
    url: url_PostDescribeConfigurationSettings_601797,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeConfigurationSettings_601777 = ref object of OpenApiRestCall_600427
proc url_GetDescribeConfigurationSettings_601779(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeConfigurationSettings_601778(path: JsonNode;
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
  var valid_601780 = query.getOrDefault("ApplicationName")
  valid_601780 = validateParameter(valid_601780, JString, required = true,
                                 default = nil)
  if valid_601780 != nil:
    section.add "ApplicationName", valid_601780
  var valid_601781 = query.getOrDefault("EnvironmentName")
  valid_601781 = validateParameter(valid_601781, JString, required = false,
                                 default = nil)
  if valid_601781 != nil:
    section.add "EnvironmentName", valid_601781
  var valid_601782 = query.getOrDefault("Action")
  valid_601782 = validateParameter(valid_601782, JString, required = true, default = newJString(
      "DescribeConfigurationSettings"))
  if valid_601782 != nil:
    section.add "Action", valid_601782
  var valid_601783 = query.getOrDefault("TemplateName")
  valid_601783 = validateParameter(valid_601783, JString, required = false,
                                 default = nil)
  if valid_601783 != nil:
    section.add "TemplateName", valid_601783
  var valid_601784 = query.getOrDefault("Version")
  valid_601784 = validateParameter(valid_601784, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601784 != nil:
    section.add "Version", valid_601784
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601785 = header.getOrDefault("X-Amz-Date")
  valid_601785 = validateParameter(valid_601785, JString, required = false,
                                 default = nil)
  if valid_601785 != nil:
    section.add "X-Amz-Date", valid_601785
  var valid_601786 = header.getOrDefault("X-Amz-Security-Token")
  valid_601786 = validateParameter(valid_601786, JString, required = false,
                                 default = nil)
  if valid_601786 != nil:
    section.add "X-Amz-Security-Token", valid_601786
  var valid_601787 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601787 = validateParameter(valid_601787, JString, required = false,
                                 default = nil)
  if valid_601787 != nil:
    section.add "X-Amz-Content-Sha256", valid_601787
  var valid_601788 = header.getOrDefault("X-Amz-Algorithm")
  valid_601788 = validateParameter(valid_601788, JString, required = false,
                                 default = nil)
  if valid_601788 != nil:
    section.add "X-Amz-Algorithm", valid_601788
  var valid_601789 = header.getOrDefault("X-Amz-Signature")
  valid_601789 = validateParameter(valid_601789, JString, required = false,
                                 default = nil)
  if valid_601789 != nil:
    section.add "X-Amz-Signature", valid_601789
  var valid_601790 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601790 = validateParameter(valid_601790, JString, required = false,
                                 default = nil)
  if valid_601790 != nil:
    section.add "X-Amz-SignedHeaders", valid_601790
  var valid_601791 = header.getOrDefault("X-Amz-Credential")
  valid_601791 = validateParameter(valid_601791, JString, required = false,
                                 default = nil)
  if valid_601791 != nil:
    section.add "X-Amz-Credential", valid_601791
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601792: Call_GetDescribeConfigurationSettings_601777;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a description of the settings for the specified configuration set, that is, either a configuration template or the configuration set associated with a running environment.</p> <p>When describing the settings for the configuration set associated with a running environment, it is possible to receive two sets of setting descriptions. One is the deployed configuration set, and the other is a draft configuration of an environment that is either in the process of deployment or that failed to deploy.</p> <p>Related Topics</p> <ul> <li> <p> <a>DeleteEnvironmentConfiguration</a> </p> </li> </ul>
  ## 
  let valid = call_601792.validator(path, query, header, formData, body)
  let scheme = call_601792.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601792.url(scheme.get, call_601792.host, call_601792.base,
                         call_601792.route, valid.getOrDefault("path"))
  result = hook(call_601792, url, valid)

proc call*(call_601793: Call_GetDescribeConfigurationSettings_601777;
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
  var query_601794 = newJObject()
  add(query_601794, "ApplicationName", newJString(ApplicationName))
  add(query_601794, "EnvironmentName", newJString(EnvironmentName))
  add(query_601794, "Action", newJString(Action))
  add(query_601794, "TemplateName", newJString(TemplateName))
  add(query_601794, "Version", newJString(Version))
  result = call_601793.call(nil, query_601794, nil, nil, nil)

var getDescribeConfigurationSettings* = Call_GetDescribeConfigurationSettings_601777(
    name: "getDescribeConfigurationSettings", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationSettings",
    validator: validate_GetDescribeConfigurationSettings_601778, base: "/",
    url: url_GetDescribeConfigurationSettings_601779,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentHealth_601832 = ref object of OpenApiRestCall_600427
proc url_PostDescribeEnvironmentHealth_601834(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEnvironmentHealth_601833(path: JsonNode; query: JsonNode;
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
  var valid_601835 = query.getOrDefault("Action")
  valid_601835 = validateParameter(valid_601835, JString, required = true, default = newJString(
      "DescribeEnvironmentHealth"))
  if valid_601835 != nil:
    section.add "Action", valid_601835
  var valid_601836 = query.getOrDefault("Version")
  valid_601836 = validateParameter(valid_601836, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601836 != nil:
    section.add "Version", valid_601836
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601837 = header.getOrDefault("X-Amz-Date")
  valid_601837 = validateParameter(valid_601837, JString, required = false,
                                 default = nil)
  if valid_601837 != nil:
    section.add "X-Amz-Date", valid_601837
  var valid_601838 = header.getOrDefault("X-Amz-Security-Token")
  valid_601838 = validateParameter(valid_601838, JString, required = false,
                                 default = nil)
  if valid_601838 != nil:
    section.add "X-Amz-Security-Token", valid_601838
  var valid_601839 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601839 = validateParameter(valid_601839, JString, required = false,
                                 default = nil)
  if valid_601839 != nil:
    section.add "X-Amz-Content-Sha256", valid_601839
  var valid_601840 = header.getOrDefault("X-Amz-Algorithm")
  valid_601840 = validateParameter(valid_601840, JString, required = false,
                                 default = nil)
  if valid_601840 != nil:
    section.add "X-Amz-Algorithm", valid_601840
  var valid_601841 = header.getOrDefault("X-Amz-Signature")
  valid_601841 = validateParameter(valid_601841, JString, required = false,
                                 default = nil)
  if valid_601841 != nil:
    section.add "X-Amz-Signature", valid_601841
  var valid_601842 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601842 = validateParameter(valid_601842, JString, required = false,
                                 default = nil)
  if valid_601842 != nil:
    section.add "X-Amz-SignedHeaders", valid_601842
  var valid_601843 = header.getOrDefault("X-Amz-Credential")
  valid_601843 = validateParameter(valid_601843, JString, required = false,
                                 default = nil)
  if valid_601843 != nil:
    section.add "X-Amz-Credential", valid_601843
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentId: JString
  ##                : <p>Specify the environment by ID.</p> <p>You must specify either this or an EnvironmentName, or both.</p>
  ##   EnvironmentName: JString
  ##                  : <p>Specify the environment by name.</p> <p>You must specify either this or an EnvironmentName, or both.</p>
  ##   AttributeNames: JArray
  ##                 : Specify the response elements to return. To retrieve all attributes, set to <code>All</code>. If no attribute names are specified, returns the name of the environment.
  section = newJObject()
  var valid_601844 = formData.getOrDefault("EnvironmentId")
  valid_601844 = validateParameter(valid_601844, JString, required = false,
                                 default = nil)
  if valid_601844 != nil:
    section.add "EnvironmentId", valid_601844
  var valid_601845 = formData.getOrDefault("EnvironmentName")
  valid_601845 = validateParameter(valid_601845, JString, required = false,
                                 default = nil)
  if valid_601845 != nil:
    section.add "EnvironmentName", valid_601845
  var valid_601846 = formData.getOrDefault("AttributeNames")
  valid_601846 = validateParameter(valid_601846, JArray, required = false,
                                 default = nil)
  if valid_601846 != nil:
    section.add "AttributeNames", valid_601846
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601847: Call_PostDescribeEnvironmentHealth_601832; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the overall health of the specified environment. The <b>DescribeEnvironmentHealth</b> operation is only available with AWS Elastic Beanstalk Enhanced Health.
  ## 
  let valid = call_601847.validator(path, query, header, formData, body)
  let scheme = call_601847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601847.url(scheme.get, call_601847.host, call_601847.base,
                         call_601847.route, valid.getOrDefault("path"))
  result = hook(call_601847, url, valid)

proc call*(call_601848: Call_PostDescribeEnvironmentHealth_601832;
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
  var query_601849 = newJObject()
  var formData_601850 = newJObject()
  add(formData_601850, "EnvironmentId", newJString(EnvironmentId))
  add(formData_601850, "EnvironmentName", newJString(EnvironmentName))
  add(query_601849, "Action", newJString(Action))
  if AttributeNames != nil:
    formData_601850.add "AttributeNames", AttributeNames
  add(query_601849, "Version", newJString(Version))
  result = call_601848.call(nil, query_601849, nil, formData_601850, nil)

var postDescribeEnvironmentHealth* = Call_PostDescribeEnvironmentHealth_601832(
    name: "postDescribeEnvironmentHealth", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentHealth",
    validator: validate_PostDescribeEnvironmentHealth_601833, base: "/",
    url: url_PostDescribeEnvironmentHealth_601834,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentHealth_601814 = ref object of OpenApiRestCall_600427
proc url_GetDescribeEnvironmentHealth_601816(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEnvironmentHealth_601815(path: JsonNode; query: JsonNode;
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
  var valid_601817 = query.getOrDefault("AttributeNames")
  valid_601817 = validateParameter(valid_601817, JArray, required = false,
                                 default = nil)
  if valid_601817 != nil:
    section.add "AttributeNames", valid_601817
  var valid_601818 = query.getOrDefault("EnvironmentName")
  valid_601818 = validateParameter(valid_601818, JString, required = false,
                                 default = nil)
  if valid_601818 != nil:
    section.add "EnvironmentName", valid_601818
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601819 = query.getOrDefault("Action")
  valid_601819 = validateParameter(valid_601819, JString, required = true, default = newJString(
      "DescribeEnvironmentHealth"))
  if valid_601819 != nil:
    section.add "Action", valid_601819
  var valid_601820 = query.getOrDefault("EnvironmentId")
  valid_601820 = validateParameter(valid_601820, JString, required = false,
                                 default = nil)
  if valid_601820 != nil:
    section.add "EnvironmentId", valid_601820
  var valid_601821 = query.getOrDefault("Version")
  valid_601821 = validateParameter(valid_601821, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601821 != nil:
    section.add "Version", valid_601821
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601822 = header.getOrDefault("X-Amz-Date")
  valid_601822 = validateParameter(valid_601822, JString, required = false,
                                 default = nil)
  if valid_601822 != nil:
    section.add "X-Amz-Date", valid_601822
  var valid_601823 = header.getOrDefault("X-Amz-Security-Token")
  valid_601823 = validateParameter(valid_601823, JString, required = false,
                                 default = nil)
  if valid_601823 != nil:
    section.add "X-Amz-Security-Token", valid_601823
  var valid_601824 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601824 = validateParameter(valid_601824, JString, required = false,
                                 default = nil)
  if valid_601824 != nil:
    section.add "X-Amz-Content-Sha256", valid_601824
  var valid_601825 = header.getOrDefault("X-Amz-Algorithm")
  valid_601825 = validateParameter(valid_601825, JString, required = false,
                                 default = nil)
  if valid_601825 != nil:
    section.add "X-Amz-Algorithm", valid_601825
  var valid_601826 = header.getOrDefault("X-Amz-Signature")
  valid_601826 = validateParameter(valid_601826, JString, required = false,
                                 default = nil)
  if valid_601826 != nil:
    section.add "X-Amz-Signature", valid_601826
  var valid_601827 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601827 = validateParameter(valid_601827, JString, required = false,
                                 default = nil)
  if valid_601827 != nil:
    section.add "X-Amz-SignedHeaders", valid_601827
  var valid_601828 = header.getOrDefault("X-Amz-Credential")
  valid_601828 = validateParameter(valid_601828, JString, required = false,
                                 default = nil)
  if valid_601828 != nil:
    section.add "X-Amz-Credential", valid_601828
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601829: Call_GetDescribeEnvironmentHealth_601814; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the overall health of the specified environment. The <b>DescribeEnvironmentHealth</b> operation is only available with AWS Elastic Beanstalk Enhanced Health.
  ## 
  let valid = call_601829.validator(path, query, header, formData, body)
  let scheme = call_601829.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601829.url(scheme.get, call_601829.host, call_601829.base,
                         call_601829.route, valid.getOrDefault("path"))
  result = hook(call_601829, url, valid)

proc call*(call_601830: Call_GetDescribeEnvironmentHealth_601814;
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
  var query_601831 = newJObject()
  if AttributeNames != nil:
    query_601831.add "AttributeNames", AttributeNames
  add(query_601831, "EnvironmentName", newJString(EnvironmentName))
  add(query_601831, "Action", newJString(Action))
  add(query_601831, "EnvironmentId", newJString(EnvironmentId))
  add(query_601831, "Version", newJString(Version))
  result = call_601830.call(nil, query_601831, nil, nil, nil)

var getDescribeEnvironmentHealth* = Call_GetDescribeEnvironmentHealth_601814(
    name: "getDescribeEnvironmentHealth", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentHealth",
    validator: validate_GetDescribeEnvironmentHealth_601815, base: "/",
    url: url_GetDescribeEnvironmentHealth_601816,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentManagedActionHistory_601870 = ref object of OpenApiRestCall_600427
proc url_PostDescribeEnvironmentManagedActionHistory_601872(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEnvironmentManagedActionHistory_601871(path: JsonNode;
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
  var valid_601873 = query.getOrDefault("Action")
  valid_601873 = validateParameter(valid_601873, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActionHistory"))
  if valid_601873 != nil:
    section.add "Action", valid_601873
  var valid_601874 = query.getOrDefault("Version")
  valid_601874 = validateParameter(valid_601874, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601874 != nil:
    section.add "Version", valid_601874
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601875 = header.getOrDefault("X-Amz-Date")
  valid_601875 = validateParameter(valid_601875, JString, required = false,
                                 default = nil)
  if valid_601875 != nil:
    section.add "X-Amz-Date", valid_601875
  var valid_601876 = header.getOrDefault("X-Amz-Security-Token")
  valid_601876 = validateParameter(valid_601876, JString, required = false,
                                 default = nil)
  if valid_601876 != nil:
    section.add "X-Amz-Security-Token", valid_601876
  var valid_601877 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601877 = validateParameter(valid_601877, JString, required = false,
                                 default = nil)
  if valid_601877 != nil:
    section.add "X-Amz-Content-Sha256", valid_601877
  var valid_601878 = header.getOrDefault("X-Amz-Algorithm")
  valid_601878 = validateParameter(valid_601878, JString, required = false,
                                 default = nil)
  if valid_601878 != nil:
    section.add "X-Amz-Algorithm", valid_601878
  var valid_601879 = header.getOrDefault("X-Amz-Signature")
  valid_601879 = validateParameter(valid_601879, JString, required = false,
                                 default = nil)
  if valid_601879 != nil:
    section.add "X-Amz-Signature", valid_601879
  var valid_601880 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601880 = validateParameter(valid_601880, JString, required = false,
                                 default = nil)
  if valid_601880 != nil:
    section.add "X-Amz-SignedHeaders", valid_601880
  var valid_601881 = header.getOrDefault("X-Amz-Credential")
  valid_601881 = validateParameter(valid_601881, JString, required = false,
                                 default = nil)
  if valid_601881 != nil:
    section.add "X-Amz-Credential", valid_601881
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
  var valid_601882 = formData.getOrDefault("NextToken")
  valid_601882 = validateParameter(valid_601882, JString, required = false,
                                 default = nil)
  if valid_601882 != nil:
    section.add "NextToken", valid_601882
  var valid_601883 = formData.getOrDefault("EnvironmentId")
  valid_601883 = validateParameter(valid_601883, JString, required = false,
                                 default = nil)
  if valid_601883 != nil:
    section.add "EnvironmentId", valid_601883
  var valid_601884 = formData.getOrDefault("EnvironmentName")
  valid_601884 = validateParameter(valid_601884, JString, required = false,
                                 default = nil)
  if valid_601884 != nil:
    section.add "EnvironmentName", valid_601884
  var valid_601885 = formData.getOrDefault("MaxItems")
  valid_601885 = validateParameter(valid_601885, JInt, required = false, default = nil)
  if valid_601885 != nil:
    section.add "MaxItems", valid_601885
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601886: Call_PostDescribeEnvironmentManagedActionHistory_601870;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists an environment's completed and failed managed actions.
  ## 
  let valid = call_601886.validator(path, query, header, formData, body)
  let scheme = call_601886.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601886.url(scheme.get, call_601886.host, call_601886.base,
                         call_601886.route, valid.getOrDefault("path"))
  result = hook(call_601886, url, valid)

proc call*(call_601887: Call_PostDescribeEnvironmentManagedActionHistory_601870;
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
  var query_601888 = newJObject()
  var formData_601889 = newJObject()
  add(formData_601889, "NextToken", newJString(NextToken))
  add(formData_601889, "EnvironmentId", newJString(EnvironmentId))
  add(formData_601889, "EnvironmentName", newJString(EnvironmentName))
  add(query_601888, "Action", newJString(Action))
  add(formData_601889, "MaxItems", newJInt(MaxItems))
  add(query_601888, "Version", newJString(Version))
  result = call_601887.call(nil, query_601888, nil, formData_601889, nil)

var postDescribeEnvironmentManagedActionHistory* = Call_PostDescribeEnvironmentManagedActionHistory_601870(
    name: "postDescribeEnvironmentManagedActionHistory",
    meth: HttpMethod.HttpPost, host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActionHistory",
    validator: validate_PostDescribeEnvironmentManagedActionHistory_601871,
    base: "/", url: url_PostDescribeEnvironmentManagedActionHistory_601872,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentManagedActionHistory_601851 = ref object of OpenApiRestCall_600427
proc url_GetDescribeEnvironmentManagedActionHistory_601853(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEnvironmentManagedActionHistory_601852(path: JsonNode;
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
  var valid_601854 = query.getOrDefault("NextToken")
  valid_601854 = validateParameter(valid_601854, JString, required = false,
                                 default = nil)
  if valid_601854 != nil:
    section.add "NextToken", valid_601854
  var valid_601855 = query.getOrDefault("EnvironmentName")
  valid_601855 = validateParameter(valid_601855, JString, required = false,
                                 default = nil)
  if valid_601855 != nil:
    section.add "EnvironmentName", valid_601855
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601856 = query.getOrDefault("Action")
  valid_601856 = validateParameter(valid_601856, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActionHistory"))
  if valid_601856 != nil:
    section.add "Action", valid_601856
  var valid_601857 = query.getOrDefault("EnvironmentId")
  valid_601857 = validateParameter(valid_601857, JString, required = false,
                                 default = nil)
  if valid_601857 != nil:
    section.add "EnvironmentId", valid_601857
  var valid_601858 = query.getOrDefault("MaxItems")
  valid_601858 = validateParameter(valid_601858, JInt, required = false, default = nil)
  if valid_601858 != nil:
    section.add "MaxItems", valid_601858
  var valid_601859 = query.getOrDefault("Version")
  valid_601859 = validateParameter(valid_601859, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601859 != nil:
    section.add "Version", valid_601859
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601860 = header.getOrDefault("X-Amz-Date")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "X-Amz-Date", valid_601860
  var valid_601861 = header.getOrDefault("X-Amz-Security-Token")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-Security-Token", valid_601861
  var valid_601862 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601862 = validateParameter(valid_601862, JString, required = false,
                                 default = nil)
  if valid_601862 != nil:
    section.add "X-Amz-Content-Sha256", valid_601862
  var valid_601863 = header.getOrDefault("X-Amz-Algorithm")
  valid_601863 = validateParameter(valid_601863, JString, required = false,
                                 default = nil)
  if valid_601863 != nil:
    section.add "X-Amz-Algorithm", valid_601863
  var valid_601864 = header.getOrDefault("X-Amz-Signature")
  valid_601864 = validateParameter(valid_601864, JString, required = false,
                                 default = nil)
  if valid_601864 != nil:
    section.add "X-Amz-Signature", valid_601864
  var valid_601865 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601865 = validateParameter(valid_601865, JString, required = false,
                                 default = nil)
  if valid_601865 != nil:
    section.add "X-Amz-SignedHeaders", valid_601865
  var valid_601866 = header.getOrDefault("X-Amz-Credential")
  valid_601866 = validateParameter(valid_601866, JString, required = false,
                                 default = nil)
  if valid_601866 != nil:
    section.add "X-Amz-Credential", valid_601866
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601867: Call_GetDescribeEnvironmentManagedActionHistory_601851;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists an environment's completed and failed managed actions.
  ## 
  let valid = call_601867.validator(path, query, header, formData, body)
  let scheme = call_601867.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601867.url(scheme.get, call_601867.host, call_601867.base,
                         call_601867.route, valid.getOrDefault("path"))
  result = hook(call_601867, url, valid)

proc call*(call_601868: Call_GetDescribeEnvironmentManagedActionHistory_601851;
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
  var query_601869 = newJObject()
  add(query_601869, "NextToken", newJString(NextToken))
  add(query_601869, "EnvironmentName", newJString(EnvironmentName))
  add(query_601869, "Action", newJString(Action))
  add(query_601869, "EnvironmentId", newJString(EnvironmentId))
  add(query_601869, "MaxItems", newJInt(MaxItems))
  add(query_601869, "Version", newJString(Version))
  result = call_601868.call(nil, query_601869, nil, nil, nil)

var getDescribeEnvironmentManagedActionHistory* = Call_GetDescribeEnvironmentManagedActionHistory_601851(
    name: "getDescribeEnvironmentManagedActionHistory", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActionHistory",
    validator: validate_GetDescribeEnvironmentManagedActionHistory_601852,
    base: "/", url: url_GetDescribeEnvironmentManagedActionHistory_601853,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentManagedActions_601908 = ref object of OpenApiRestCall_600427
proc url_PostDescribeEnvironmentManagedActions_601910(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEnvironmentManagedActions_601909(path: JsonNode;
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
  var valid_601911 = query.getOrDefault("Action")
  valid_601911 = validateParameter(valid_601911, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActions"))
  if valid_601911 != nil:
    section.add "Action", valid_601911
  var valid_601912 = query.getOrDefault("Version")
  valid_601912 = validateParameter(valid_601912, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601912 != nil:
    section.add "Version", valid_601912
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601913 = header.getOrDefault("X-Amz-Date")
  valid_601913 = validateParameter(valid_601913, JString, required = false,
                                 default = nil)
  if valid_601913 != nil:
    section.add "X-Amz-Date", valid_601913
  var valid_601914 = header.getOrDefault("X-Amz-Security-Token")
  valid_601914 = validateParameter(valid_601914, JString, required = false,
                                 default = nil)
  if valid_601914 != nil:
    section.add "X-Amz-Security-Token", valid_601914
  var valid_601915 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601915 = validateParameter(valid_601915, JString, required = false,
                                 default = nil)
  if valid_601915 != nil:
    section.add "X-Amz-Content-Sha256", valid_601915
  var valid_601916 = header.getOrDefault("X-Amz-Algorithm")
  valid_601916 = validateParameter(valid_601916, JString, required = false,
                                 default = nil)
  if valid_601916 != nil:
    section.add "X-Amz-Algorithm", valid_601916
  var valid_601917 = header.getOrDefault("X-Amz-Signature")
  valid_601917 = validateParameter(valid_601917, JString, required = false,
                                 default = nil)
  if valid_601917 != nil:
    section.add "X-Amz-Signature", valid_601917
  var valid_601918 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601918 = validateParameter(valid_601918, JString, required = false,
                                 default = nil)
  if valid_601918 != nil:
    section.add "X-Amz-SignedHeaders", valid_601918
  var valid_601919 = header.getOrDefault("X-Amz-Credential")
  valid_601919 = validateParameter(valid_601919, JString, required = false,
                                 default = nil)
  if valid_601919 != nil:
    section.add "X-Amz-Credential", valid_601919
  result.add "header", section
  ## parameters in `formData` object:
  ##   Status: JString
  ##         : To show only actions with a particular status, specify a status.
  ##   EnvironmentId: JString
  ##                : The environment ID of the target environment.
  ##   EnvironmentName: JString
  ##                  : The name of the target environment.
  section = newJObject()
  var valid_601920 = formData.getOrDefault("Status")
  valid_601920 = validateParameter(valid_601920, JString, required = false,
                                 default = newJString("Scheduled"))
  if valid_601920 != nil:
    section.add "Status", valid_601920
  var valid_601921 = formData.getOrDefault("EnvironmentId")
  valid_601921 = validateParameter(valid_601921, JString, required = false,
                                 default = nil)
  if valid_601921 != nil:
    section.add "EnvironmentId", valid_601921
  var valid_601922 = formData.getOrDefault("EnvironmentName")
  valid_601922 = validateParameter(valid_601922, JString, required = false,
                                 default = nil)
  if valid_601922 != nil:
    section.add "EnvironmentName", valid_601922
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601923: Call_PostDescribeEnvironmentManagedActions_601908;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists an environment's upcoming and in-progress managed actions.
  ## 
  let valid = call_601923.validator(path, query, header, formData, body)
  let scheme = call_601923.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601923.url(scheme.get, call_601923.host, call_601923.base,
                         call_601923.route, valid.getOrDefault("path"))
  result = hook(call_601923, url, valid)

proc call*(call_601924: Call_PostDescribeEnvironmentManagedActions_601908;
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
  var query_601925 = newJObject()
  var formData_601926 = newJObject()
  add(formData_601926, "Status", newJString(Status))
  add(formData_601926, "EnvironmentId", newJString(EnvironmentId))
  add(formData_601926, "EnvironmentName", newJString(EnvironmentName))
  add(query_601925, "Action", newJString(Action))
  add(query_601925, "Version", newJString(Version))
  result = call_601924.call(nil, query_601925, nil, formData_601926, nil)

var postDescribeEnvironmentManagedActions* = Call_PostDescribeEnvironmentManagedActions_601908(
    name: "postDescribeEnvironmentManagedActions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActions",
    validator: validate_PostDescribeEnvironmentManagedActions_601909, base: "/",
    url: url_PostDescribeEnvironmentManagedActions_601910,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentManagedActions_601890 = ref object of OpenApiRestCall_600427
proc url_GetDescribeEnvironmentManagedActions_601892(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEnvironmentManagedActions_601891(path: JsonNode;
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
  var valid_601893 = query.getOrDefault("Status")
  valid_601893 = validateParameter(valid_601893, JString, required = false,
                                 default = newJString("Scheduled"))
  if valid_601893 != nil:
    section.add "Status", valid_601893
  var valid_601894 = query.getOrDefault("EnvironmentName")
  valid_601894 = validateParameter(valid_601894, JString, required = false,
                                 default = nil)
  if valid_601894 != nil:
    section.add "EnvironmentName", valid_601894
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601895 = query.getOrDefault("Action")
  valid_601895 = validateParameter(valid_601895, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActions"))
  if valid_601895 != nil:
    section.add "Action", valid_601895
  var valid_601896 = query.getOrDefault("EnvironmentId")
  valid_601896 = validateParameter(valid_601896, JString, required = false,
                                 default = nil)
  if valid_601896 != nil:
    section.add "EnvironmentId", valid_601896
  var valid_601897 = query.getOrDefault("Version")
  valid_601897 = validateParameter(valid_601897, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601897 != nil:
    section.add "Version", valid_601897
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601898 = header.getOrDefault("X-Amz-Date")
  valid_601898 = validateParameter(valid_601898, JString, required = false,
                                 default = nil)
  if valid_601898 != nil:
    section.add "X-Amz-Date", valid_601898
  var valid_601899 = header.getOrDefault("X-Amz-Security-Token")
  valid_601899 = validateParameter(valid_601899, JString, required = false,
                                 default = nil)
  if valid_601899 != nil:
    section.add "X-Amz-Security-Token", valid_601899
  var valid_601900 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601900 = validateParameter(valid_601900, JString, required = false,
                                 default = nil)
  if valid_601900 != nil:
    section.add "X-Amz-Content-Sha256", valid_601900
  var valid_601901 = header.getOrDefault("X-Amz-Algorithm")
  valid_601901 = validateParameter(valid_601901, JString, required = false,
                                 default = nil)
  if valid_601901 != nil:
    section.add "X-Amz-Algorithm", valid_601901
  var valid_601902 = header.getOrDefault("X-Amz-Signature")
  valid_601902 = validateParameter(valid_601902, JString, required = false,
                                 default = nil)
  if valid_601902 != nil:
    section.add "X-Amz-Signature", valid_601902
  var valid_601903 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601903 = validateParameter(valid_601903, JString, required = false,
                                 default = nil)
  if valid_601903 != nil:
    section.add "X-Amz-SignedHeaders", valid_601903
  var valid_601904 = header.getOrDefault("X-Amz-Credential")
  valid_601904 = validateParameter(valid_601904, JString, required = false,
                                 default = nil)
  if valid_601904 != nil:
    section.add "X-Amz-Credential", valid_601904
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601905: Call_GetDescribeEnvironmentManagedActions_601890;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists an environment's upcoming and in-progress managed actions.
  ## 
  let valid = call_601905.validator(path, query, header, formData, body)
  let scheme = call_601905.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601905.url(scheme.get, call_601905.host, call_601905.base,
                         call_601905.route, valid.getOrDefault("path"))
  result = hook(call_601905, url, valid)

proc call*(call_601906: Call_GetDescribeEnvironmentManagedActions_601890;
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
  var query_601907 = newJObject()
  add(query_601907, "Status", newJString(Status))
  add(query_601907, "EnvironmentName", newJString(EnvironmentName))
  add(query_601907, "Action", newJString(Action))
  add(query_601907, "EnvironmentId", newJString(EnvironmentId))
  add(query_601907, "Version", newJString(Version))
  result = call_601906.call(nil, query_601907, nil, nil, nil)

var getDescribeEnvironmentManagedActions* = Call_GetDescribeEnvironmentManagedActions_601890(
    name: "getDescribeEnvironmentManagedActions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActions",
    validator: validate_GetDescribeEnvironmentManagedActions_601891, base: "/",
    url: url_GetDescribeEnvironmentManagedActions_601892,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentResources_601944 = ref object of OpenApiRestCall_600427
proc url_PostDescribeEnvironmentResources_601946(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEnvironmentResources_601945(path: JsonNode;
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
  var valid_601947 = query.getOrDefault("Action")
  valid_601947 = validateParameter(valid_601947, JString, required = true, default = newJString(
      "DescribeEnvironmentResources"))
  if valid_601947 != nil:
    section.add "Action", valid_601947
  var valid_601948 = query.getOrDefault("Version")
  valid_601948 = validateParameter(valid_601948, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601948 != nil:
    section.add "Version", valid_601948
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601949 = header.getOrDefault("X-Amz-Date")
  valid_601949 = validateParameter(valid_601949, JString, required = false,
                                 default = nil)
  if valid_601949 != nil:
    section.add "X-Amz-Date", valid_601949
  var valid_601950 = header.getOrDefault("X-Amz-Security-Token")
  valid_601950 = validateParameter(valid_601950, JString, required = false,
                                 default = nil)
  if valid_601950 != nil:
    section.add "X-Amz-Security-Token", valid_601950
  var valid_601951 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601951 = validateParameter(valid_601951, JString, required = false,
                                 default = nil)
  if valid_601951 != nil:
    section.add "X-Amz-Content-Sha256", valid_601951
  var valid_601952 = header.getOrDefault("X-Amz-Algorithm")
  valid_601952 = validateParameter(valid_601952, JString, required = false,
                                 default = nil)
  if valid_601952 != nil:
    section.add "X-Amz-Algorithm", valid_601952
  var valid_601953 = header.getOrDefault("X-Amz-Signature")
  valid_601953 = validateParameter(valid_601953, JString, required = false,
                                 default = nil)
  if valid_601953 != nil:
    section.add "X-Amz-Signature", valid_601953
  var valid_601954 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601954 = validateParameter(valid_601954, JString, required = false,
                                 default = nil)
  if valid_601954 != nil:
    section.add "X-Amz-SignedHeaders", valid_601954
  var valid_601955 = header.getOrDefault("X-Amz-Credential")
  valid_601955 = validateParameter(valid_601955, JString, required = false,
                                 default = nil)
  if valid_601955 != nil:
    section.add "X-Amz-Credential", valid_601955
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to retrieve AWS resource usage data.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to retrieve AWS resource usage data.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_601956 = formData.getOrDefault("EnvironmentId")
  valid_601956 = validateParameter(valid_601956, JString, required = false,
                                 default = nil)
  if valid_601956 != nil:
    section.add "EnvironmentId", valid_601956
  var valid_601957 = formData.getOrDefault("EnvironmentName")
  valid_601957 = validateParameter(valid_601957, JString, required = false,
                                 default = nil)
  if valid_601957 != nil:
    section.add "EnvironmentName", valid_601957
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601958: Call_PostDescribeEnvironmentResources_601944;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns AWS resources for this environment.
  ## 
  let valid = call_601958.validator(path, query, header, formData, body)
  let scheme = call_601958.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601958.url(scheme.get, call_601958.host, call_601958.base,
                         call_601958.route, valid.getOrDefault("path"))
  result = hook(call_601958, url, valid)

proc call*(call_601959: Call_PostDescribeEnvironmentResources_601944;
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
  var query_601960 = newJObject()
  var formData_601961 = newJObject()
  add(formData_601961, "EnvironmentId", newJString(EnvironmentId))
  add(formData_601961, "EnvironmentName", newJString(EnvironmentName))
  add(query_601960, "Action", newJString(Action))
  add(query_601960, "Version", newJString(Version))
  result = call_601959.call(nil, query_601960, nil, formData_601961, nil)

var postDescribeEnvironmentResources* = Call_PostDescribeEnvironmentResources_601944(
    name: "postDescribeEnvironmentResources", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentResources",
    validator: validate_PostDescribeEnvironmentResources_601945, base: "/",
    url: url_PostDescribeEnvironmentResources_601946,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentResources_601927 = ref object of OpenApiRestCall_600427
proc url_GetDescribeEnvironmentResources_601929(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEnvironmentResources_601928(path: JsonNode;
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
  var valid_601930 = query.getOrDefault("EnvironmentName")
  valid_601930 = validateParameter(valid_601930, JString, required = false,
                                 default = nil)
  if valid_601930 != nil:
    section.add "EnvironmentName", valid_601930
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601931 = query.getOrDefault("Action")
  valid_601931 = validateParameter(valid_601931, JString, required = true, default = newJString(
      "DescribeEnvironmentResources"))
  if valid_601931 != nil:
    section.add "Action", valid_601931
  var valid_601932 = query.getOrDefault("EnvironmentId")
  valid_601932 = validateParameter(valid_601932, JString, required = false,
                                 default = nil)
  if valid_601932 != nil:
    section.add "EnvironmentId", valid_601932
  var valid_601933 = query.getOrDefault("Version")
  valid_601933 = validateParameter(valid_601933, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601933 != nil:
    section.add "Version", valid_601933
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601934 = header.getOrDefault("X-Amz-Date")
  valid_601934 = validateParameter(valid_601934, JString, required = false,
                                 default = nil)
  if valid_601934 != nil:
    section.add "X-Amz-Date", valid_601934
  var valid_601935 = header.getOrDefault("X-Amz-Security-Token")
  valid_601935 = validateParameter(valid_601935, JString, required = false,
                                 default = nil)
  if valid_601935 != nil:
    section.add "X-Amz-Security-Token", valid_601935
  var valid_601936 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601936 = validateParameter(valid_601936, JString, required = false,
                                 default = nil)
  if valid_601936 != nil:
    section.add "X-Amz-Content-Sha256", valid_601936
  var valid_601937 = header.getOrDefault("X-Amz-Algorithm")
  valid_601937 = validateParameter(valid_601937, JString, required = false,
                                 default = nil)
  if valid_601937 != nil:
    section.add "X-Amz-Algorithm", valid_601937
  var valid_601938 = header.getOrDefault("X-Amz-Signature")
  valid_601938 = validateParameter(valid_601938, JString, required = false,
                                 default = nil)
  if valid_601938 != nil:
    section.add "X-Amz-Signature", valid_601938
  var valid_601939 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601939 = validateParameter(valid_601939, JString, required = false,
                                 default = nil)
  if valid_601939 != nil:
    section.add "X-Amz-SignedHeaders", valid_601939
  var valid_601940 = header.getOrDefault("X-Amz-Credential")
  valid_601940 = validateParameter(valid_601940, JString, required = false,
                                 default = nil)
  if valid_601940 != nil:
    section.add "X-Amz-Credential", valid_601940
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601941: Call_GetDescribeEnvironmentResources_601927;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns AWS resources for this environment.
  ## 
  let valid = call_601941.validator(path, query, header, formData, body)
  let scheme = call_601941.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601941.url(scheme.get, call_601941.host, call_601941.base,
                         call_601941.route, valid.getOrDefault("path"))
  result = hook(call_601941, url, valid)

proc call*(call_601942: Call_GetDescribeEnvironmentResources_601927;
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
  var query_601943 = newJObject()
  add(query_601943, "EnvironmentName", newJString(EnvironmentName))
  add(query_601943, "Action", newJString(Action))
  add(query_601943, "EnvironmentId", newJString(EnvironmentId))
  add(query_601943, "Version", newJString(Version))
  result = call_601942.call(nil, query_601943, nil, nil, nil)

var getDescribeEnvironmentResources* = Call_GetDescribeEnvironmentResources_601927(
    name: "getDescribeEnvironmentResources", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentResources",
    validator: validate_GetDescribeEnvironmentResources_601928, base: "/",
    url: url_GetDescribeEnvironmentResources_601929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironments_601985 = ref object of OpenApiRestCall_600427
proc url_PostDescribeEnvironments_601987(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEnvironments_601986(path: JsonNode; query: JsonNode;
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
  var valid_601988 = query.getOrDefault("Action")
  valid_601988 = validateParameter(valid_601988, JString, required = true,
                                 default = newJString("DescribeEnvironments"))
  if valid_601988 != nil:
    section.add "Action", valid_601988
  var valid_601989 = query.getOrDefault("Version")
  valid_601989 = validateParameter(valid_601989, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601989 != nil:
    section.add "Version", valid_601989
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601990 = header.getOrDefault("X-Amz-Date")
  valid_601990 = validateParameter(valid_601990, JString, required = false,
                                 default = nil)
  if valid_601990 != nil:
    section.add "X-Amz-Date", valid_601990
  var valid_601991 = header.getOrDefault("X-Amz-Security-Token")
  valid_601991 = validateParameter(valid_601991, JString, required = false,
                                 default = nil)
  if valid_601991 != nil:
    section.add "X-Amz-Security-Token", valid_601991
  var valid_601992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601992 = validateParameter(valid_601992, JString, required = false,
                                 default = nil)
  if valid_601992 != nil:
    section.add "X-Amz-Content-Sha256", valid_601992
  var valid_601993 = header.getOrDefault("X-Amz-Algorithm")
  valid_601993 = validateParameter(valid_601993, JString, required = false,
                                 default = nil)
  if valid_601993 != nil:
    section.add "X-Amz-Algorithm", valid_601993
  var valid_601994 = header.getOrDefault("X-Amz-Signature")
  valid_601994 = validateParameter(valid_601994, JString, required = false,
                                 default = nil)
  if valid_601994 != nil:
    section.add "X-Amz-Signature", valid_601994
  var valid_601995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601995 = validateParameter(valid_601995, JString, required = false,
                                 default = nil)
  if valid_601995 != nil:
    section.add "X-Amz-SignedHeaders", valid_601995
  var valid_601996 = header.getOrDefault("X-Amz-Credential")
  valid_601996 = validateParameter(valid_601996, JString, required = false,
                                 default = nil)
  if valid_601996 != nil:
    section.add "X-Amz-Credential", valid_601996
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
  var valid_601997 = formData.getOrDefault("NextToken")
  valid_601997 = validateParameter(valid_601997, JString, required = false,
                                 default = nil)
  if valid_601997 != nil:
    section.add "NextToken", valid_601997
  var valid_601998 = formData.getOrDefault("VersionLabel")
  valid_601998 = validateParameter(valid_601998, JString, required = false,
                                 default = nil)
  if valid_601998 != nil:
    section.add "VersionLabel", valid_601998
  var valid_601999 = formData.getOrDefault("EnvironmentNames")
  valid_601999 = validateParameter(valid_601999, JArray, required = false,
                                 default = nil)
  if valid_601999 != nil:
    section.add "EnvironmentNames", valid_601999
  var valid_602000 = formData.getOrDefault("IncludedDeletedBackTo")
  valid_602000 = validateParameter(valid_602000, JString, required = false,
                                 default = nil)
  if valid_602000 != nil:
    section.add "IncludedDeletedBackTo", valid_602000
  var valid_602001 = formData.getOrDefault("ApplicationName")
  valid_602001 = validateParameter(valid_602001, JString, required = false,
                                 default = nil)
  if valid_602001 != nil:
    section.add "ApplicationName", valid_602001
  var valid_602002 = formData.getOrDefault("EnvironmentIds")
  valid_602002 = validateParameter(valid_602002, JArray, required = false,
                                 default = nil)
  if valid_602002 != nil:
    section.add "EnvironmentIds", valid_602002
  var valid_602003 = formData.getOrDefault("IncludeDeleted")
  valid_602003 = validateParameter(valid_602003, JBool, required = false, default = nil)
  if valid_602003 != nil:
    section.add "IncludeDeleted", valid_602003
  var valid_602004 = formData.getOrDefault("MaxRecords")
  valid_602004 = validateParameter(valid_602004, JInt, required = false, default = nil)
  if valid_602004 != nil:
    section.add "MaxRecords", valid_602004
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602005: Call_PostDescribeEnvironments_601985; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns descriptions for existing environments.
  ## 
  let valid = call_602005.validator(path, query, header, formData, body)
  let scheme = call_602005.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602005.url(scheme.get, call_602005.host, call_602005.base,
                         call_602005.route, valid.getOrDefault("path"))
  result = hook(call_602005, url, valid)

proc call*(call_602006: Call_PostDescribeEnvironments_601985;
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
  var query_602007 = newJObject()
  var formData_602008 = newJObject()
  add(formData_602008, "NextToken", newJString(NextToken))
  add(formData_602008, "VersionLabel", newJString(VersionLabel))
  if EnvironmentNames != nil:
    formData_602008.add "EnvironmentNames", EnvironmentNames
  add(formData_602008, "IncludedDeletedBackTo", newJString(IncludedDeletedBackTo))
  add(query_602007, "Action", newJString(Action))
  add(formData_602008, "ApplicationName", newJString(ApplicationName))
  if EnvironmentIds != nil:
    formData_602008.add "EnvironmentIds", EnvironmentIds
  add(formData_602008, "IncludeDeleted", newJBool(IncludeDeleted))
  add(formData_602008, "MaxRecords", newJInt(MaxRecords))
  add(query_602007, "Version", newJString(Version))
  result = call_602006.call(nil, query_602007, nil, formData_602008, nil)

var postDescribeEnvironments* = Call_PostDescribeEnvironments_601985(
    name: "postDescribeEnvironments", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironments",
    validator: validate_PostDescribeEnvironments_601986, base: "/",
    url: url_PostDescribeEnvironments_601987, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironments_601962 = ref object of OpenApiRestCall_600427
proc url_GetDescribeEnvironments_601964(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEnvironments_601963(path: JsonNode; query: JsonNode;
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
  var valid_601965 = query.getOrDefault("VersionLabel")
  valid_601965 = validateParameter(valid_601965, JString, required = false,
                                 default = nil)
  if valid_601965 != nil:
    section.add "VersionLabel", valid_601965
  var valid_601966 = query.getOrDefault("MaxRecords")
  valid_601966 = validateParameter(valid_601966, JInt, required = false, default = nil)
  if valid_601966 != nil:
    section.add "MaxRecords", valid_601966
  var valid_601967 = query.getOrDefault("ApplicationName")
  valid_601967 = validateParameter(valid_601967, JString, required = false,
                                 default = nil)
  if valid_601967 != nil:
    section.add "ApplicationName", valid_601967
  var valid_601968 = query.getOrDefault("IncludeDeleted")
  valid_601968 = validateParameter(valid_601968, JBool, required = false, default = nil)
  if valid_601968 != nil:
    section.add "IncludeDeleted", valid_601968
  var valid_601969 = query.getOrDefault("NextToken")
  valid_601969 = validateParameter(valid_601969, JString, required = false,
                                 default = nil)
  if valid_601969 != nil:
    section.add "NextToken", valid_601969
  var valid_601970 = query.getOrDefault("EnvironmentIds")
  valid_601970 = validateParameter(valid_601970, JArray, required = false,
                                 default = nil)
  if valid_601970 != nil:
    section.add "EnvironmentIds", valid_601970
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601971 = query.getOrDefault("Action")
  valid_601971 = validateParameter(valid_601971, JString, required = true,
                                 default = newJString("DescribeEnvironments"))
  if valid_601971 != nil:
    section.add "Action", valid_601971
  var valid_601972 = query.getOrDefault("IncludedDeletedBackTo")
  valid_601972 = validateParameter(valid_601972, JString, required = false,
                                 default = nil)
  if valid_601972 != nil:
    section.add "IncludedDeletedBackTo", valid_601972
  var valid_601973 = query.getOrDefault("EnvironmentNames")
  valid_601973 = validateParameter(valid_601973, JArray, required = false,
                                 default = nil)
  if valid_601973 != nil:
    section.add "EnvironmentNames", valid_601973
  var valid_601974 = query.getOrDefault("Version")
  valid_601974 = validateParameter(valid_601974, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601974 != nil:
    section.add "Version", valid_601974
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601975 = header.getOrDefault("X-Amz-Date")
  valid_601975 = validateParameter(valid_601975, JString, required = false,
                                 default = nil)
  if valid_601975 != nil:
    section.add "X-Amz-Date", valid_601975
  var valid_601976 = header.getOrDefault("X-Amz-Security-Token")
  valid_601976 = validateParameter(valid_601976, JString, required = false,
                                 default = nil)
  if valid_601976 != nil:
    section.add "X-Amz-Security-Token", valid_601976
  var valid_601977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601977 = validateParameter(valid_601977, JString, required = false,
                                 default = nil)
  if valid_601977 != nil:
    section.add "X-Amz-Content-Sha256", valid_601977
  var valid_601978 = header.getOrDefault("X-Amz-Algorithm")
  valid_601978 = validateParameter(valid_601978, JString, required = false,
                                 default = nil)
  if valid_601978 != nil:
    section.add "X-Amz-Algorithm", valid_601978
  var valid_601979 = header.getOrDefault("X-Amz-Signature")
  valid_601979 = validateParameter(valid_601979, JString, required = false,
                                 default = nil)
  if valid_601979 != nil:
    section.add "X-Amz-Signature", valid_601979
  var valid_601980 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601980 = validateParameter(valid_601980, JString, required = false,
                                 default = nil)
  if valid_601980 != nil:
    section.add "X-Amz-SignedHeaders", valid_601980
  var valid_601981 = header.getOrDefault("X-Amz-Credential")
  valid_601981 = validateParameter(valid_601981, JString, required = false,
                                 default = nil)
  if valid_601981 != nil:
    section.add "X-Amz-Credential", valid_601981
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601982: Call_GetDescribeEnvironments_601962; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns descriptions for existing environments.
  ## 
  let valid = call_601982.validator(path, query, header, formData, body)
  let scheme = call_601982.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601982.url(scheme.get, call_601982.host, call_601982.base,
                         call_601982.route, valid.getOrDefault("path"))
  result = hook(call_601982, url, valid)

proc call*(call_601983: Call_GetDescribeEnvironments_601962;
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
  var query_601984 = newJObject()
  add(query_601984, "VersionLabel", newJString(VersionLabel))
  add(query_601984, "MaxRecords", newJInt(MaxRecords))
  add(query_601984, "ApplicationName", newJString(ApplicationName))
  add(query_601984, "IncludeDeleted", newJBool(IncludeDeleted))
  add(query_601984, "NextToken", newJString(NextToken))
  if EnvironmentIds != nil:
    query_601984.add "EnvironmentIds", EnvironmentIds
  add(query_601984, "Action", newJString(Action))
  add(query_601984, "IncludedDeletedBackTo", newJString(IncludedDeletedBackTo))
  if EnvironmentNames != nil:
    query_601984.add "EnvironmentNames", EnvironmentNames
  add(query_601984, "Version", newJString(Version))
  result = call_601983.call(nil, query_601984, nil, nil, nil)

var getDescribeEnvironments* = Call_GetDescribeEnvironments_601962(
    name: "getDescribeEnvironments", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironments",
    validator: validate_GetDescribeEnvironments_601963, base: "/",
    url: url_GetDescribeEnvironments_601964, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_602036 = ref object of OpenApiRestCall_600427
proc url_PostDescribeEvents_602038(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEvents_602037(path: JsonNode; query: JsonNode;
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
  var valid_602039 = query.getOrDefault("Action")
  valid_602039 = validateParameter(valid_602039, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_602039 != nil:
    section.add "Action", valid_602039
  var valid_602040 = query.getOrDefault("Version")
  valid_602040 = validateParameter(valid_602040, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602040 != nil:
    section.add "Version", valid_602040
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602041 = header.getOrDefault("X-Amz-Date")
  valid_602041 = validateParameter(valid_602041, JString, required = false,
                                 default = nil)
  if valid_602041 != nil:
    section.add "X-Amz-Date", valid_602041
  var valid_602042 = header.getOrDefault("X-Amz-Security-Token")
  valid_602042 = validateParameter(valid_602042, JString, required = false,
                                 default = nil)
  if valid_602042 != nil:
    section.add "X-Amz-Security-Token", valid_602042
  var valid_602043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602043 = validateParameter(valid_602043, JString, required = false,
                                 default = nil)
  if valid_602043 != nil:
    section.add "X-Amz-Content-Sha256", valid_602043
  var valid_602044 = header.getOrDefault("X-Amz-Algorithm")
  valid_602044 = validateParameter(valid_602044, JString, required = false,
                                 default = nil)
  if valid_602044 != nil:
    section.add "X-Amz-Algorithm", valid_602044
  var valid_602045 = header.getOrDefault("X-Amz-Signature")
  valid_602045 = validateParameter(valid_602045, JString, required = false,
                                 default = nil)
  if valid_602045 != nil:
    section.add "X-Amz-Signature", valid_602045
  var valid_602046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602046 = validateParameter(valid_602046, JString, required = false,
                                 default = nil)
  if valid_602046 != nil:
    section.add "X-Amz-SignedHeaders", valid_602046
  var valid_602047 = header.getOrDefault("X-Amz-Credential")
  valid_602047 = validateParameter(valid_602047, JString, required = false,
                                 default = nil)
  if valid_602047 != nil:
    section.add "X-Amz-Credential", valid_602047
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
  var valid_602048 = formData.getOrDefault("NextToken")
  valid_602048 = validateParameter(valid_602048, JString, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "NextToken", valid_602048
  var valid_602049 = formData.getOrDefault("VersionLabel")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "VersionLabel", valid_602049
  var valid_602050 = formData.getOrDefault("Severity")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = newJString("TRACE"))
  if valid_602050 != nil:
    section.add "Severity", valid_602050
  var valid_602051 = formData.getOrDefault("EnvironmentId")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "EnvironmentId", valid_602051
  var valid_602052 = formData.getOrDefault("EnvironmentName")
  valid_602052 = validateParameter(valid_602052, JString, required = false,
                                 default = nil)
  if valid_602052 != nil:
    section.add "EnvironmentName", valid_602052
  var valid_602053 = formData.getOrDefault("StartTime")
  valid_602053 = validateParameter(valid_602053, JString, required = false,
                                 default = nil)
  if valid_602053 != nil:
    section.add "StartTime", valid_602053
  var valid_602054 = formData.getOrDefault("ApplicationName")
  valid_602054 = validateParameter(valid_602054, JString, required = false,
                                 default = nil)
  if valid_602054 != nil:
    section.add "ApplicationName", valid_602054
  var valid_602055 = formData.getOrDefault("EndTime")
  valid_602055 = validateParameter(valid_602055, JString, required = false,
                                 default = nil)
  if valid_602055 != nil:
    section.add "EndTime", valid_602055
  var valid_602056 = formData.getOrDefault("PlatformArn")
  valid_602056 = validateParameter(valid_602056, JString, required = false,
                                 default = nil)
  if valid_602056 != nil:
    section.add "PlatformArn", valid_602056
  var valid_602057 = formData.getOrDefault("MaxRecords")
  valid_602057 = validateParameter(valid_602057, JInt, required = false, default = nil)
  if valid_602057 != nil:
    section.add "MaxRecords", valid_602057
  var valid_602058 = formData.getOrDefault("RequestId")
  valid_602058 = validateParameter(valid_602058, JString, required = false,
                                 default = nil)
  if valid_602058 != nil:
    section.add "RequestId", valid_602058
  var valid_602059 = formData.getOrDefault("TemplateName")
  valid_602059 = validateParameter(valid_602059, JString, required = false,
                                 default = nil)
  if valid_602059 != nil:
    section.add "TemplateName", valid_602059
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602060: Call_PostDescribeEvents_602036; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns list of event descriptions matching criteria up to the last 6 weeks.</p> <note> <p>This action returns the most recent 1,000 events from the specified <code>NextToken</code>.</p> </note>
  ## 
  let valid = call_602060.validator(path, query, header, formData, body)
  let scheme = call_602060.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602060.url(scheme.get, call_602060.host, call_602060.base,
                         call_602060.route, valid.getOrDefault("path"))
  result = hook(call_602060, url, valid)

proc call*(call_602061: Call_PostDescribeEvents_602036; NextToken: string = "";
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
  var query_602062 = newJObject()
  var formData_602063 = newJObject()
  add(formData_602063, "NextToken", newJString(NextToken))
  add(formData_602063, "VersionLabel", newJString(VersionLabel))
  add(formData_602063, "Severity", newJString(Severity))
  add(formData_602063, "EnvironmentId", newJString(EnvironmentId))
  add(formData_602063, "EnvironmentName", newJString(EnvironmentName))
  add(formData_602063, "StartTime", newJString(StartTime))
  add(query_602062, "Action", newJString(Action))
  add(formData_602063, "ApplicationName", newJString(ApplicationName))
  add(formData_602063, "EndTime", newJString(EndTime))
  add(formData_602063, "PlatformArn", newJString(PlatformArn))
  add(formData_602063, "MaxRecords", newJInt(MaxRecords))
  add(formData_602063, "RequestId", newJString(RequestId))
  add(formData_602063, "TemplateName", newJString(TemplateName))
  add(query_602062, "Version", newJString(Version))
  result = call_602061.call(nil, query_602062, nil, formData_602063, nil)

var postDescribeEvents* = Call_PostDescribeEvents_602036(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_602037, base: "/",
    url: url_PostDescribeEvents_602038, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_602009 = ref object of OpenApiRestCall_600427
proc url_GetDescribeEvents_602011(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEvents_602010(path: JsonNode; query: JsonNode;
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
  var valid_602012 = query.getOrDefault("VersionLabel")
  valid_602012 = validateParameter(valid_602012, JString, required = false,
                                 default = nil)
  if valid_602012 != nil:
    section.add "VersionLabel", valid_602012
  var valid_602013 = query.getOrDefault("MaxRecords")
  valid_602013 = validateParameter(valid_602013, JInt, required = false, default = nil)
  if valid_602013 != nil:
    section.add "MaxRecords", valid_602013
  var valid_602014 = query.getOrDefault("ApplicationName")
  valid_602014 = validateParameter(valid_602014, JString, required = false,
                                 default = nil)
  if valid_602014 != nil:
    section.add "ApplicationName", valid_602014
  var valid_602015 = query.getOrDefault("StartTime")
  valid_602015 = validateParameter(valid_602015, JString, required = false,
                                 default = nil)
  if valid_602015 != nil:
    section.add "StartTime", valid_602015
  var valid_602016 = query.getOrDefault("PlatformArn")
  valid_602016 = validateParameter(valid_602016, JString, required = false,
                                 default = nil)
  if valid_602016 != nil:
    section.add "PlatformArn", valid_602016
  var valid_602017 = query.getOrDefault("NextToken")
  valid_602017 = validateParameter(valid_602017, JString, required = false,
                                 default = nil)
  if valid_602017 != nil:
    section.add "NextToken", valid_602017
  var valid_602018 = query.getOrDefault("EnvironmentName")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "EnvironmentName", valid_602018
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602019 = query.getOrDefault("Action")
  valid_602019 = validateParameter(valid_602019, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_602019 != nil:
    section.add "Action", valid_602019
  var valid_602020 = query.getOrDefault("EnvironmentId")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "EnvironmentId", valid_602020
  var valid_602021 = query.getOrDefault("TemplateName")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "TemplateName", valid_602021
  var valid_602022 = query.getOrDefault("Severity")
  valid_602022 = validateParameter(valid_602022, JString, required = false,
                                 default = newJString("TRACE"))
  if valid_602022 != nil:
    section.add "Severity", valid_602022
  var valid_602023 = query.getOrDefault("RequestId")
  valid_602023 = validateParameter(valid_602023, JString, required = false,
                                 default = nil)
  if valid_602023 != nil:
    section.add "RequestId", valid_602023
  var valid_602024 = query.getOrDefault("EndTime")
  valid_602024 = validateParameter(valid_602024, JString, required = false,
                                 default = nil)
  if valid_602024 != nil:
    section.add "EndTime", valid_602024
  var valid_602025 = query.getOrDefault("Version")
  valid_602025 = validateParameter(valid_602025, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602025 != nil:
    section.add "Version", valid_602025
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602026 = header.getOrDefault("X-Amz-Date")
  valid_602026 = validateParameter(valid_602026, JString, required = false,
                                 default = nil)
  if valid_602026 != nil:
    section.add "X-Amz-Date", valid_602026
  var valid_602027 = header.getOrDefault("X-Amz-Security-Token")
  valid_602027 = validateParameter(valid_602027, JString, required = false,
                                 default = nil)
  if valid_602027 != nil:
    section.add "X-Amz-Security-Token", valid_602027
  var valid_602028 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602028 = validateParameter(valid_602028, JString, required = false,
                                 default = nil)
  if valid_602028 != nil:
    section.add "X-Amz-Content-Sha256", valid_602028
  var valid_602029 = header.getOrDefault("X-Amz-Algorithm")
  valid_602029 = validateParameter(valid_602029, JString, required = false,
                                 default = nil)
  if valid_602029 != nil:
    section.add "X-Amz-Algorithm", valid_602029
  var valid_602030 = header.getOrDefault("X-Amz-Signature")
  valid_602030 = validateParameter(valid_602030, JString, required = false,
                                 default = nil)
  if valid_602030 != nil:
    section.add "X-Amz-Signature", valid_602030
  var valid_602031 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602031 = validateParameter(valid_602031, JString, required = false,
                                 default = nil)
  if valid_602031 != nil:
    section.add "X-Amz-SignedHeaders", valid_602031
  var valid_602032 = header.getOrDefault("X-Amz-Credential")
  valid_602032 = validateParameter(valid_602032, JString, required = false,
                                 default = nil)
  if valid_602032 != nil:
    section.add "X-Amz-Credential", valid_602032
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602033: Call_GetDescribeEvents_602009; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns list of event descriptions matching criteria up to the last 6 weeks.</p> <note> <p>This action returns the most recent 1,000 events from the specified <code>NextToken</code>.</p> </note>
  ## 
  let valid = call_602033.validator(path, query, header, formData, body)
  let scheme = call_602033.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602033.url(scheme.get, call_602033.host, call_602033.base,
                         call_602033.route, valid.getOrDefault("path"))
  result = hook(call_602033, url, valid)

proc call*(call_602034: Call_GetDescribeEvents_602009; VersionLabel: string = "";
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
  var query_602035 = newJObject()
  add(query_602035, "VersionLabel", newJString(VersionLabel))
  add(query_602035, "MaxRecords", newJInt(MaxRecords))
  add(query_602035, "ApplicationName", newJString(ApplicationName))
  add(query_602035, "StartTime", newJString(StartTime))
  add(query_602035, "PlatformArn", newJString(PlatformArn))
  add(query_602035, "NextToken", newJString(NextToken))
  add(query_602035, "EnvironmentName", newJString(EnvironmentName))
  add(query_602035, "Action", newJString(Action))
  add(query_602035, "EnvironmentId", newJString(EnvironmentId))
  add(query_602035, "TemplateName", newJString(TemplateName))
  add(query_602035, "Severity", newJString(Severity))
  add(query_602035, "RequestId", newJString(RequestId))
  add(query_602035, "EndTime", newJString(EndTime))
  add(query_602035, "Version", newJString(Version))
  result = call_602034.call(nil, query_602035, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_602009(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_602010,
    base: "/", url: url_GetDescribeEvents_602011,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeInstancesHealth_602083 = ref object of OpenApiRestCall_600427
proc url_PostDescribeInstancesHealth_602085(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeInstancesHealth_602084(path: JsonNode; query: JsonNode;
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
  var valid_602086 = query.getOrDefault("Action")
  valid_602086 = validateParameter(valid_602086, JString, required = true, default = newJString(
      "DescribeInstancesHealth"))
  if valid_602086 != nil:
    section.add "Action", valid_602086
  var valid_602087 = query.getOrDefault("Version")
  valid_602087 = validateParameter(valid_602087, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602087 != nil:
    section.add "Version", valid_602087
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602088 = header.getOrDefault("X-Amz-Date")
  valid_602088 = validateParameter(valid_602088, JString, required = false,
                                 default = nil)
  if valid_602088 != nil:
    section.add "X-Amz-Date", valid_602088
  var valid_602089 = header.getOrDefault("X-Amz-Security-Token")
  valid_602089 = validateParameter(valid_602089, JString, required = false,
                                 default = nil)
  if valid_602089 != nil:
    section.add "X-Amz-Security-Token", valid_602089
  var valid_602090 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602090 = validateParameter(valid_602090, JString, required = false,
                                 default = nil)
  if valid_602090 != nil:
    section.add "X-Amz-Content-Sha256", valid_602090
  var valid_602091 = header.getOrDefault("X-Amz-Algorithm")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "X-Amz-Algorithm", valid_602091
  var valid_602092 = header.getOrDefault("X-Amz-Signature")
  valid_602092 = validateParameter(valid_602092, JString, required = false,
                                 default = nil)
  if valid_602092 != nil:
    section.add "X-Amz-Signature", valid_602092
  var valid_602093 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602093 = validateParameter(valid_602093, JString, required = false,
                                 default = nil)
  if valid_602093 != nil:
    section.add "X-Amz-SignedHeaders", valid_602093
  var valid_602094 = header.getOrDefault("X-Amz-Credential")
  valid_602094 = validateParameter(valid_602094, JString, required = false,
                                 default = nil)
  if valid_602094 != nil:
    section.add "X-Amz-Credential", valid_602094
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
  var valid_602095 = formData.getOrDefault("NextToken")
  valid_602095 = validateParameter(valid_602095, JString, required = false,
                                 default = nil)
  if valid_602095 != nil:
    section.add "NextToken", valid_602095
  var valid_602096 = formData.getOrDefault("EnvironmentId")
  valid_602096 = validateParameter(valid_602096, JString, required = false,
                                 default = nil)
  if valid_602096 != nil:
    section.add "EnvironmentId", valid_602096
  var valid_602097 = formData.getOrDefault("EnvironmentName")
  valid_602097 = validateParameter(valid_602097, JString, required = false,
                                 default = nil)
  if valid_602097 != nil:
    section.add "EnvironmentName", valid_602097
  var valid_602098 = formData.getOrDefault("AttributeNames")
  valid_602098 = validateParameter(valid_602098, JArray, required = false,
                                 default = nil)
  if valid_602098 != nil:
    section.add "AttributeNames", valid_602098
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602099: Call_PostDescribeInstancesHealth_602083; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves detailed information about the health of instances in your AWS Elastic Beanstalk. This operation requires <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/health-enhanced.html">enhanced health reporting</a>.
  ## 
  let valid = call_602099.validator(path, query, header, formData, body)
  let scheme = call_602099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602099.url(scheme.get, call_602099.host, call_602099.base,
                         call_602099.route, valid.getOrDefault("path"))
  result = hook(call_602099, url, valid)

proc call*(call_602100: Call_PostDescribeInstancesHealth_602083;
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
  var query_602101 = newJObject()
  var formData_602102 = newJObject()
  add(formData_602102, "NextToken", newJString(NextToken))
  add(formData_602102, "EnvironmentId", newJString(EnvironmentId))
  add(formData_602102, "EnvironmentName", newJString(EnvironmentName))
  add(query_602101, "Action", newJString(Action))
  if AttributeNames != nil:
    formData_602102.add "AttributeNames", AttributeNames
  add(query_602101, "Version", newJString(Version))
  result = call_602100.call(nil, query_602101, nil, formData_602102, nil)

var postDescribeInstancesHealth* = Call_PostDescribeInstancesHealth_602083(
    name: "postDescribeInstancesHealth", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeInstancesHealth",
    validator: validate_PostDescribeInstancesHealth_602084, base: "/",
    url: url_PostDescribeInstancesHealth_602085,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeInstancesHealth_602064 = ref object of OpenApiRestCall_600427
proc url_GetDescribeInstancesHealth_602066(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeInstancesHealth_602065(path: JsonNode; query: JsonNode;
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
  var valid_602067 = query.getOrDefault("AttributeNames")
  valid_602067 = validateParameter(valid_602067, JArray, required = false,
                                 default = nil)
  if valid_602067 != nil:
    section.add "AttributeNames", valid_602067
  var valid_602068 = query.getOrDefault("NextToken")
  valid_602068 = validateParameter(valid_602068, JString, required = false,
                                 default = nil)
  if valid_602068 != nil:
    section.add "NextToken", valid_602068
  var valid_602069 = query.getOrDefault("EnvironmentName")
  valid_602069 = validateParameter(valid_602069, JString, required = false,
                                 default = nil)
  if valid_602069 != nil:
    section.add "EnvironmentName", valid_602069
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602070 = query.getOrDefault("Action")
  valid_602070 = validateParameter(valid_602070, JString, required = true, default = newJString(
      "DescribeInstancesHealth"))
  if valid_602070 != nil:
    section.add "Action", valid_602070
  var valid_602071 = query.getOrDefault("EnvironmentId")
  valid_602071 = validateParameter(valid_602071, JString, required = false,
                                 default = nil)
  if valid_602071 != nil:
    section.add "EnvironmentId", valid_602071
  var valid_602072 = query.getOrDefault("Version")
  valid_602072 = validateParameter(valid_602072, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602072 != nil:
    section.add "Version", valid_602072
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602073 = header.getOrDefault("X-Amz-Date")
  valid_602073 = validateParameter(valid_602073, JString, required = false,
                                 default = nil)
  if valid_602073 != nil:
    section.add "X-Amz-Date", valid_602073
  var valid_602074 = header.getOrDefault("X-Amz-Security-Token")
  valid_602074 = validateParameter(valid_602074, JString, required = false,
                                 default = nil)
  if valid_602074 != nil:
    section.add "X-Amz-Security-Token", valid_602074
  var valid_602075 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602075 = validateParameter(valid_602075, JString, required = false,
                                 default = nil)
  if valid_602075 != nil:
    section.add "X-Amz-Content-Sha256", valid_602075
  var valid_602076 = header.getOrDefault("X-Amz-Algorithm")
  valid_602076 = validateParameter(valid_602076, JString, required = false,
                                 default = nil)
  if valid_602076 != nil:
    section.add "X-Amz-Algorithm", valid_602076
  var valid_602077 = header.getOrDefault("X-Amz-Signature")
  valid_602077 = validateParameter(valid_602077, JString, required = false,
                                 default = nil)
  if valid_602077 != nil:
    section.add "X-Amz-Signature", valid_602077
  var valid_602078 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602078 = validateParameter(valid_602078, JString, required = false,
                                 default = nil)
  if valid_602078 != nil:
    section.add "X-Amz-SignedHeaders", valid_602078
  var valid_602079 = header.getOrDefault("X-Amz-Credential")
  valid_602079 = validateParameter(valid_602079, JString, required = false,
                                 default = nil)
  if valid_602079 != nil:
    section.add "X-Amz-Credential", valid_602079
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602080: Call_GetDescribeInstancesHealth_602064; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves detailed information about the health of instances in your AWS Elastic Beanstalk. This operation requires <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/health-enhanced.html">enhanced health reporting</a>.
  ## 
  let valid = call_602080.validator(path, query, header, formData, body)
  let scheme = call_602080.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602080.url(scheme.get, call_602080.host, call_602080.base,
                         call_602080.route, valid.getOrDefault("path"))
  result = hook(call_602080, url, valid)

proc call*(call_602081: Call_GetDescribeInstancesHealth_602064;
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
  var query_602082 = newJObject()
  if AttributeNames != nil:
    query_602082.add "AttributeNames", AttributeNames
  add(query_602082, "NextToken", newJString(NextToken))
  add(query_602082, "EnvironmentName", newJString(EnvironmentName))
  add(query_602082, "Action", newJString(Action))
  add(query_602082, "EnvironmentId", newJString(EnvironmentId))
  add(query_602082, "Version", newJString(Version))
  result = call_602081.call(nil, query_602082, nil, nil, nil)

var getDescribeInstancesHealth* = Call_GetDescribeInstancesHealth_602064(
    name: "getDescribeInstancesHealth", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeInstancesHealth",
    validator: validate_GetDescribeInstancesHealth_602065, base: "/",
    url: url_GetDescribeInstancesHealth_602066,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribePlatformVersion_602119 = ref object of OpenApiRestCall_600427
proc url_PostDescribePlatformVersion_602121(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribePlatformVersion_602120(path: JsonNode; query: JsonNode;
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
  var valid_602122 = query.getOrDefault("Action")
  valid_602122 = validateParameter(valid_602122, JString, required = true, default = newJString(
      "DescribePlatformVersion"))
  if valid_602122 != nil:
    section.add "Action", valid_602122
  var valid_602123 = query.getOrDefault("Version")
  valid_602123 = validateParameter(valid_602123, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602123 != nil:
    section.add "Version", valid_602123
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602124 = header.getOrDefault("X-Amz-Date")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "X-Amz-Date", valid_602124
  var valid_602125 = header.getOrDefault("X-Amz-Security-Token")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = nil)
  if valid_602125 != nil:
    section.add "X-Amz-Security-Token", valid_602125
  var valid_602126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602126 = validateParameter(valid_602126, JString, required = false,
                                 default = nil)
  if valid_602126 != nil:
    section.add "X-Amz-Content-Sha256", valid_602126
  var valid_602127 = header.getOrDefault("X-Amz-Algorithm")
  valid_602127 = validateParameter(valid_602127, JString, required = false,
                                 default = nil)
  if valid_602127 != nil:
    section.add "X-Amz-Algorithm", valid_602127
  var valid_602128 = header.getOrDefault("X-Amz-Signature")
  valid_602128 = validateParameter(valid_602128, JString, required = false,
                                 default = nil)
  if valid_602128 != nil:
    section.add "X-Amz-Signature", valid_602128
  var valid_602129 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602129 = validateParameter(valid_602129, JString, required = false,
                                 default = nil)
  if valid_602129 != nil:
    section.add "X-Amz-SignedHeaders", valid_602129
  var valid_602130 = header.getOrDefault("X-Amz-Credential")
  valid_602130 = validateParameter(valid_602130, JString, required = false,
                                 default = nil)
  if valid_602130 != nil:
    section.add "X-Amz-Credential", valid_602130
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformArn: JString
  ##              : The ARN of the version of the platform.
  section = newJObject()
  var valid_602131 = formData.getOrDefault("PlatformArn")
  valid_602131 = validateParameter(valid_602131, JString, required = false,
                                 default = nil)
  if valid_602131 != nil:
    section.add "PlatformArn", valid_602131
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602132: Call_PostDescribePlatformVersion_602119; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the version of the platform.
  ## 
  let valid = call_602132.validator(path, query, header, formData, body)
  let scheme = call_602132.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602132.url(scheme.get, call_602132.host, call_602132.base,
                         call_602132.route, valid.getOrDefault("path"))
  result = hook(call_602132, url, valid)

proc call*(call_602133: Call_PostDescribePlatformVersion_602119;
          Action: string = "DescribePlatformVersion"; PlatformArn: string = "";
          Version: string = "2010-12-01"): Recallable =
  ## postDescribePlatformVersion
  ## Describes the version of the platform.
  ##   Action: string (required)
  ##   PlatformArn: string
  ##              : The ARN of the version of the platform.
  ##   Version: string (required)
  var query_602134 = newJObject()
  var formData_602135 = newJObject()
  add(query_602134, "Action", newJString(Action))
  add(formData_602135, "PlatformArn", newJString(PlatformArn))
  add(query_602134, "Version", newJString(Version))
  result = call_602133.call(nil, query_602134, nil, formData_602135, nil)

var postDescribePlatformVersion* = Call_PostDescribePlatformVersion_602119(
    name: "postDescribePlatformVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribePlatformVersion",
    validator: validate_PostDescribePlatformVersion_602120, base: "/",
    url: url_PostDescribePlatformVersion_602121,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribePlatformVersion_602103 = ref object of OpenApiRestCall_600427
proc url_GetDescribePlatformVersion_602105(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribePlatformVersion_602104(path: JsonNode; query: JsonNode;
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
  var valid_602106 = query.getOrDefault("PlatformArn")
  valid_602106 = validateParameter(valid_602106, JString, required = false,
                                 default = nil)
  if valid_602106 != nil:
    section.add "PlatformArn", valid_602106
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602107 = query.getOrDefault("Action")
  valid_602107 = validateParameter(valid_602107, JString, required = true, default = newJString(
      "DescribePlatformVersion"))
  if valid_602107 != nil:
    section.add "Action", valid_602107
  var valid_602108 = query.getOrDefault("Version")
  valid_602108 = validateParameter(valid_602108, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602108 != nil:
    section.add "Version", valid_602108
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602109 = header.getOrDefault("X-Amz-Date")
  valid_602109 = validateParameter(valid_602109, JString, required = false,
                                 default = nil)
  if valid_602109 != nil:
    section.add "X-Amz-Date", valid_602109
  var valid_602110 = header.getOrDefault("X-Amz-Security-Token")
  valid_602110 = validateParameter(valid_602110, JString, required = false,
                                 default = nil)
  if valid_602110 != nil:
    section.add "X-Amz-Security-Token", valid_602110
  var valid_602111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602111 = validateParameter(valid_602111, JString, required = false,
                                 default = nil)
  if valid_602111 != nil:
    section.add "X-Amz-Content-Sha256", valid_602111
  var valid_602112 = header.getOrDefault("X-Amz-Algorithm")
  valid_602112 = validateParameter(valid_602112, JString, required = false,
                                 default = nil)
  if valid_602112 != nil:
    section.add "X-Amz-Algorithm", valid_602112
  var valid_602113 = header.getOrDefault("X-Amz-Signature")
  valid_602113 = validateParameter(valid_602113, JString, required = false,
                                 default = nil)
  if valid_602113 != nil:
    section.add "X-Amz-Signature", valid_602113
  var valid_602114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602114 = validateParameter(valid_602114, JString, required = false,
                                 default = nil)
  if valid_602114 != nil:
    section.add "X-Amz-SignedHeaders", valid_602114
  var valid_602115 = header.getOrDefault("X-Amz-Credential")
  valid_602115 = validateParameter(valid_602115, JString, required = false,
                                 default = nil)
  if valid_602115 != nil:
    section.add "X-Amz-Credential", valid_602115
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602116: Call_GetDescribePlatformVersion_602103; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the version of the platform.
  ## 
  let valid = call_602116.validator(path, query, header, formData, body)
  let scheme = call_602116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602116.url(scheme.get, call_602116.host, call_602116.base,
                         call_602116.route, valid.getOrDefault("path"))
  result = hook(call_602116, url, valid)

proc call*(call_602117: Call_GetDescribePlatformVersion_602103;
          PlatformArn: string = ""; Action: string = "DescribePlatformVersion";
          Version: string = "2010-12-01"): Recallable =
  ## getDescribePlatformVersion
  ## Describes the version of the platform.
  ##   PlatformArn: string
  ##              : The ARN of the version of the platform.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602118 = newJObject()
  add(query_602118, "PlatformArn", newJString(PlatformArn))
  add(query_602118, "Action", newJString(Action))
  add(query_602118, "Version", newJString(Version))
  result = call_602117.call(nil, query_602118, nil, nil, nil)

var getDescribePlatformVersion* = Call_GetDescribePlatformVersion_602103(
    name: "getDescribePlatformVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribePlatformVersion",
    validator: validate_GetDescribePlatformVersion_602104, base: "/",
    url: url_GetDescribePlatformVersion_602105,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListAvailableSolutionStacks_602151 = ref object of OpenApiRestCall_600427
proc url_PostListAvailableSolutionStacks_602153(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListAvailableSolutionStacks_602152(path: JsonNode;
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
  var valid_602154 = query.getOrDefault("Action")
  valid_602154 = validateParameter(valid_602154, JString, required = true, default = newJString(
      "ListAvailableSolutionStacks"))
  if valid_602154 != nil:
    section.add "Action", valid_602154
  var valid_602155 = query.getOrDefault("Version")
  valid_602155 = validateParameter(valid_602155, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602155 != nil:
    section.add "Version", valid_602155
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602156 = header.getOrDefault("X-Amz-Date")
  valid_602156 = validateParameter(valid_602156, JString, required = false,
                                 default = nil)
  if valid_602156 != nil:
    section.add "X-Amz-Date", valid_602156
  var valid_602157 = header.getOrDefault("X-Amz-Security-Token")
  valid_602157 = validateParameter(valid_602157, JString, required = false,
                                 default = nil)
  if valid_602157 != nil:
    section.add "X-Amz-Security-Token", valid_602157
  var valid_602158 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602158 = validateParameter(valid_602158, JString, required = false,
                                 default = nil)
  if valid_602158 != nil:
    section.add "X-Amz-Content-Sha256", valid_602158
  var valid_602159 = header.getOrDefault("X-Amz-Algorithm")
  valid_602159 = validateParameter(valid_602159, JString, required = false,
                                 default = nil)
  if valid_602159 != nil:
    section.add "X-Amz-Algorithm", valid_602159
  var valid_602160 = header.getOrDefault("X-Amz-Signature")
  valid_602160 = validateParameter(valid_602160, JString, required = false,
                                 default = nil)
  if valid_602160 != nil:
    section.add "X-Amz-Signature", valid_602160
  var valid_602161 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602161 = validateParameter(valid_602161, JString, required = false,
                                 default = nil)
  if valid_602161 != nil:
    section.add "X-Amz-SignedHeaders", valid_602161
  var valid_602162 = header.getOrDefault("X-Amz-Credential")
  valid_602162 = validateParameter(valid_602162, JString, required = false,
                                 default = nil)
  if valid_602162 != nil:
    section.add "X-Amz-Credential", valid_602162
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602163: Call_PostListAvailableSolutionStacks_602151;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ## 
  let valid = call_602163.validator(path, query, header, formData, body)
  let scheme = call_602163.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602163.url(scheme.get, call_602163.host, call_602163.base,
                         call_602163.route, valid.getOrDefault("path"))
  result = hook(call_602163, url, valid)

proc call*(call_602164: Call_PostListAvailableSolutionStacks_602151;
          Action: string = "ListAvailableSolutionStacks";
          Version: string = "2010-12-01"): Recallable =
  ## postListAvailableSolutionStacks
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602165 = newJObject()
  add(query_602165, "Action", newJString(Action))
  add(query_602165, "Version", newJString(Version))
  result = call_602164.call(nil, query_602165, nil, nil, nil)

var postListAvailableSolutionStacks* = Call_PostListAvailableSolutionStacks_602151(
    name: "postListAvailableSolutionStacks", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListAvailableSolutionStacks",
    validator: validate_PostListAvailableSolutionStacks_602152, base: "/",
    url: url_PostListAvailableSolutionStacks_602153,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListAvailableSolutionStacks_602136 = ref object of OpenApiRestCall_600427
proc url_GetListAvailableSolutionStacks_602138(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListAvailableSolutionStacks_602137(path: JsonNode;
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
  var valid_602139 = query.getOrDefault("Action")
  valid_602139 = validateParameter(valid_602139, JString, required = true, default = newJString(
      "ListAvailableSolutionStacks"))
  if valid_602139 != nil:
    section.add "Action", valid_602139
  var valid_602140 = query.getOrDefault("Version")
  valid_602140 = validateParameter(valid_602140, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602140 != nil:
    section.add "Version", valid_602140
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602141 = header.getOrDefault("X-Amz-Date")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "X-Amz-Date", valid_602141
  var valid_602142 = header.getOrDefault("X-Amz-Security-Token")
  valid_602142 = validateParameter(valid_602142, JString, required = false,
                                 default = nil)
  if valid_602142 != nil:
    section.add "X-Amz-Security-Token", valid_602142
  var valid_602143 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602143 = validateParameter(valid_602143, JString, required = false,
                                 default = nil)
  if valid_602143 != nil:
    section.add "X-Amz-Content-Sha256", valid_602143
  var valid_602144 = header.getOrDefault("X-Amz-Algorithm")
  valid_602144 = validateParameter(valid_602144, JString, required = false,
                                 default = nil)
  if valid_602144 != nil:
    section.add "X-Amz-Algorithm", valid_602144
  var valid_602145 = header.getOrDefault("X-Amz-Signature")
  valid_602145 = validateParameter(valid_602145, JString, required = false,
                                 default = nil)
  if valid_602145 != nil:
    section.add "X-Amz-Signature", valid_602145
  var valid_602146 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602146 = validateParameter(valid_602146, JString, required = false,
                                 default = nil)
  if valid_602146 != nil:
    section.add "X-Amz-SignedHeaders", valid_602146
  var valid_602147 = header.getOrDefault("X-Amz-Credential")
  valid_602147 = validateParameter(valid_602147, JString, required = false,
                                 default = nil)
  if valid_602147 != nil:
    section.add "X-Amz-Credential", valid_602147
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602148: Call_GetListAvailableSolutionStacks_602136; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ## 
  let valid = call_602148.validator(path, query, header, formData, body)
  let scheme = call_602148.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602148.url(scheme.get, call_602148.host, call_602148.base,
                         call_602148.route, valid.getOrDefault("path"))
  result = hook(call_602148, url, valid)

proc call*(call_602149: Call_GetListAvailableSolutionStacks_602136;
          Action: string = "ListAvailableSolutionStacks";
          Version: string = "2010-12-01"): Recallable =
  ## getListAvailableSolutionStacks
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602150 = newJObject()
  add(query_602150, "Action", newJString(Action))
  add(query_602150, "Version", newJString(Version))
  result = call_602149.call(nil, query_602150, nil, nil, nil)

var getListAvailableSolutionStacks* = Call_GetListAvailableSolutionStacks_602136(
    name: "getListAvailableSolutionStacks", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListAvailableSolutionStacks",
    validator: validate_GetListAvailableSolutionStacks_602137, base: "/",
    url: url_GetListAvailableSolutionStacks_602138,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListPlatformVersions_602184 = ref object of OpenApiRestCall_600427
proc url_PostListPlatformVersions_602186(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListPlatformVersions_602185(path: JsonNode; query: JsonNode;
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
  var valid_602187 = query.getOrDefault("Action")
  valid_602187 = validateParameter(valid_602187, JString, required = true,
                                 default = newJString("ListPlatformVersions"))
  if valid_602187 != nil:
    section.add "Action", valid_602187
  var valid_602188 = query.getOrDefault("Version")
  valid_602188 = validateParameter(valid_602188, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602188 != nil:
    section.add "Version", valid_602188
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602189 = header.getOrDefault("X-Amz-Date")
  valid_602189 = validateParameter(valid_602189, JString, required = false,
                                 default = nil)
  if valid_602189 != nil:
    section.add "X-Amz-Date", valid_602189
  var valid_602190 = header.getOrDefault("X-Amz-Security-Token")
  valid_602190 = validateParameter(valid_602190, JString, required = false,
                                 default = nil)
  if valid_602190 != nil:
    section.add "X-Amz-Security-Token", valid_602190
  var valid_602191 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602191 = validateParameter(valid_602191, JString, required = false,
                                 default = nil)
  if valid_602191 != nil:
    section.add "X-Amz-Content-Sha256", valid_602191
  var valid_602192 = header.getOrDefault("X-Amz-Algorithm")
  valid_602192 = validateParameter(valid_602192, JString, required = false,
                                 default = nil)
  if valid_602192 != nil:
    section.add "X-Amz-Algorithm", valid_602192
  var valid_602193 = header.getOrDefault("X-Amz-Signature")
  valid_602193 = validateParameter(valid_602193, JString, required = false,
                                 default = nil)
  if valid_602193 != nil:
    section.add "X-Amz-Signature", valid_602193
  var valid_602194 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602194 = validateParameter(valid_602194, JString, required = false,
                                 default = nil)
  if valid_602194 != nil:
    section.add "X-Amz-SignedHeaders", valid_602194
  var valid_602195 = header.getOrDefault("X-Amz-Credential")
  valid_602195 = validateParameter(valid_602195, JString, required = false,
                                 default = nil)
  if valid_602195 != nil:
    section.add "X-Amz-Credential", valid_602195
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : The starting index into the remaining list of platforms. Use the <code>NextToken</code> value from a previous <code>ListPlatformVersion</code> call.
  ##   Filters: JArray
  ##          : List only the platforms where the platform member value relates to one of the supplied values.
  ##   MaxRecords: JInt
  ##             : The maximum number of platform values returned in one call.
  section = newJObject()
  var valid_602196 = formData.getOrDefault("NextToken")
  valid_602196 = validateParameter(valid_602196, JString, required = false,
                                 default = nil)
  if valid_602196 != nil:
    section.add "NextToken", valid_602196
  var valid_602197 = formData.getOrDefault("Filters")
  valid_602197 = validateParameter(valid_602197, JArray, required = false,
                                 default = nil)
  if valid_602197 != nil:
    section.add "Filters", valid_602197
  var valid_602198 = formData.getOrDefault("MaxRecords")
  valid_602198 = validateParameter(valid_602198, JInt, required = false, default = nil)
  if valid_602198 != nil:
    section.add "MaxRecords", valid_602198
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602199: Call_PostListPlatformVersions_602184; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the available platforms.
  ## 
  let valid = call_602199.validator(path, query, header, formData, body)
  let scheme = call_602199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602199.url(scheme.get, call_602199.host, call_602199.base,
                         call_602199.route, valid.getOrDefault("path"))
  result = hook(call_602199, url, valid)

proc call*(call_602200: Call_PostListPlatformVersions_602184;
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
  var query_602201 = newJObject()
  var formData_602202 = newJObject()
  add(formData_602202, "NextToken", newJString(NextToken))
  add(query_602201, "Action", newJString(Action))
  if Filters != nil:
    formData_602202.add "Filters", Filters
  add(formData_602202, "MaxRecords", newJInt(MaxRecords))
  add(query_602201, "Version", newJString(Version))
  result = call_602200.call(nil, query_602201, nil, formData_602202, nil)

var postListPlatformVersions* = Call_PostListPlatformVersions_602184(
    name: "postListPlatformVersions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListPlatformVersions",
    validator: validate_PostListPlatformVersions_602185, base: "/",
    url: url_PostListPlatformVersions_602186, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListPlatformVersions_602166 = ref object of OpenApiRestCall_600427
proc url_GetListPlatformVersions_602168(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListPlatformVersions_602167(path: JsonNode; query: JsonNode;
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
  var valid_602169 = query.getOrDefault("MaxRecords")
  valid_602169 = validateParameter(valid_602169, JInt, required = false, default = nil)
  if valid_602169 != nil:
    section.add "MaxRecords", valid_602169
  var valid_602170 = query.getOrDefault("Filters")
  valid_602170 = validateParameter(valid_602170, JArray, required = false,
                                 default = nil)
  if valid_602170 != nil:
    section.add "Filters", valid_602170
  var valid_602171 = query.getOrDefault("NextToken")
  valid_602171 = validateParameter(valid_602171, JString, required = false,
                                 default = nil)
  if valid_602171 != nil:
    section.add "NextToken", valid_602171
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602172 = query.getOrDefault("Action")
  valid_602172 = validateParameter(valid_602172, JString, required = true,
                                 default = newJString("ListPlatformVersions"))
  if valid_602172 != nil:
    section.add "Action", valid_602172
  var valid_602173 = query.getOrDefault("Version")
  valid_602173 = validateParameter(valid_602173, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602173 != nil:
    section.add "Version", valid_602173
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602174 = header.getOrDefault("X-Amz-Date")
  valid_602174 = validateParameter(valid_602174, JString, required = false,
                                 default = nil)
  if valid_602174 != nil:
    section.add "X-Amz-Date", valid_602174
  var valid_602175 = header.getOrDefault("X-Amz-Security-Token")
  valid_602175 = validateParameter(valid_602175, JString, required = false,
                                 default = nil)
  if valid_602175 != nil:
    section.add "X-Amz-Security-Token", valid_602175
  var valid_602176 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602176 = validateParameter(valid_602176, JString, required = false,
                                 default = nil)
  if valid_602176 != nil:
    section.add "X-Amz-Content-Sha256", valid_602176
  var valid_602177 = header.getOrDefault("X-Amz-Algorithm")
  valid_602177 = validateParameter(valid_602177, JString, required = false,
                                 default = nil)
  if valid_602177 != nil:
    section.add "X-Amz-Algorithm", valid_602177
  var valid_602178 = header.getOrDefault("X-Amz-Signature")
  valid_602178 = validateParameter(valid_602178, JString, required = false,
                                 default = nil)
  if valid_602178 != nil:
    section.add "X-Amz-Signature", valid_602178
  var valid_602179 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602179 = validateParameter(valid_602179, JString, required = false,
                                 default = nil)
  if valid_602179 != nil:
    section.add "X-Amz-SignedHeaders", valid_602179
  var valid_602180 = header.getOrDefault("X-Amz-Credential")
  valid_602180 = validateParameter(valid_602180, JString, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "X-Amz-Credential", valid_602180
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602181: Call_GetListPlatformVersions_602166; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the available platforms.
  ## 
  let valid = call_602181.validator(path, query, header, formData, body)
  let scheme = call_602181.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602181.url(scheme.get, call_602181.host, call_602181.base,
                         call_602181.route, valid.getOrDefault("path"))
  result = hook(call_602181, url, valid)

proc call*(call_602182: Call_GetListPlatformVersions_602166; MaxRecords: int = 0;
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
  var query_602183 = newJObject()
  add(query_602183, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_602183.add "Filters", Filters
  add(query_602183, "NextToken", newJString(NextToken))
  add(query_602183, "Action", newJString(Action))
  add(query_602183, "Version", newJString(Version))
  result = call_602182.call(nil, query_602183, nil, nil, nil)

var getListPlatformVersions* = Call_GetListPlatformVersions_602166(
    name: "getListPlatformVersions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListPlatformVersions",
    validator: validate_GetListPlatformVersions_602167, base: "/",
    url: url_GetListPlatformVersions_602168, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_602219 = ref object of OpenApiRestCall_600427
proc url_PostListTagsForResource_602221(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListTagsForResource_602220(path: JsonNode; query: JsonNode;
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
  var valid_602222 = query.getOrDefault("Action")
  valid_602222 = validateParameter(valid_602222, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_602222 != nil:
    section.add "Action", valid_602222
  var valid_602223 = query.getOrDefault("Version")
  valid_602223 = validateParameter(valid_602223, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602223 != nil:
    section.add "Version", valid_602223
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602224 = header.getOrDefault("X-Amz-Date")
  valid_602224 = validateParameter(valid_602224, JString, required = false,
                                 default = nil)
  if valid_602224 != nil:
    section.add "X-Amz-Date", valid_602224
  var valid_602225 = header.getOrDefault("X-Amz-Security-Token")
  valid_602225 = validateParameter(valid_602225, JString, required = false,
                                 default = nil)
  if valid_602225 != nil:
    section.add "X-Amz-Security-Token", valid_602225
  var valid_602226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602226 = validateParameter(valid_602226, JString, required = false,
                                 default = nil)
  if valid_602226 != nil:
    section.add "X-Amz-Content-Sha256", valid_602226
  var valid_602227 = header.getOrDefault("X-Amz-Algorithm")
  valid_602227 = validateParameter(valid_602227, JString, required = false,
                                 default = nil)
  if valid_602227 != nil:
    section.add "X-Amz-Algorithm", valid_602227
  var valid_602228 = header.getOrDefault("X-Amz-Signature")
  valid_602228 = validateParameter(valid_602228, JString, required = false,
                                 default = nil)
  if valid_602228 != nil:
    section.add "X-Amz-Signature", valid_602228
  var valid_602229 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602229 = validateParameter(valid_602229, JString, required = false,
                                 default = nil)
  if valid_602229 != nil:
    section.add "X-Amz-SignedHeaders", valid_602229
  var valid_602230 = header.getOrDefault("X-Amz-Credential")
  valid_602230 = validateParameter(valid_602230, JString, required = false,
                                 default = nil)
  if valid_602230 != nil:
    section.add "X-Amz-Credential", valid_602230
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArn: JString (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce for which a tag list is requested.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArn` field"
  var valid_602231 = formData.getOrDefault("ResourceArn")
  valid_602231 = validateParameter(valid_602231, JString, required = true,
                                 default = nil)
  if valid_602231 != nil:
    section.add "ResourceArn", valid_602231
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602232: Call_PostListTagsForResource_602219; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ## 
  let valid = call_602232.validator(path, query, header, formData, body)
  let scheme = call_602232.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602232.url(scheme.get, call_602232.host, call_602232.base,
                         call_602232.route, valid.getOrDefault("path"))
  result = hook(call_602232, url, valid)

proc call*(call_602233: Call_PostListTagsForResource_602219; ResourceArn: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-12-01"): Recallable =
  ## postListTagsForResource
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ##   Action: string (required)
  ##   ResourceArn: string (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce for which a tag list is requested.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  ##   Version: string (required)
  var query_602234 = newJObject()
  var formData_602235 = newJObject()
  add(query_602234, "Action", newJString(Action))
  add(formData_602235, "ResourceArn", newJString(ResourceArn))
  add(query_602234, "Version", newJString(Version))
  result = call_602233.call(nil, query_602234, nil, formData_602235, nil)

var postListTagsForResource* = Call_PostListTagsForResource_602219(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_602220, base: "/",
    url: url_PostListTagsForResource_602221, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_602203 = ref object of OpenApiRestCall_600427
proc url_GetListTagsForResource_602205(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListTagsForResource_602204(path: JsonNode; query: JsonNode;
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
  var valid_602206 = query.getOrDefault("ResourceArn")
  valid_602206 = validateParameter(valid_602206, JString, required = true,
                                 default = nil)
  if valid_602206 != nil:
    section.add "ResourceArn", valid_602206
  var valid_602207 = query.getOrDefault("Action")
  valid_602207 = validateParameter(valid_602207, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_602207 != nil:
    section.add "Action", valid_602207
  var valid_602208 = query.getOrDefault("Version")
  valid_602208 = validateParameter(valid_602208, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602208 != nil:
    section.add "Version", valid_602208
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602209 = header.getOrDefault("X-Amz-Date")
  valid_602209 = validateParameter(valid_602209, JString, required = false,
                                 default = nil)
  if valid_602209 != nil:
    section.add "X-Amz-Date", valid_602209
  var valid_602210 = header.getOrDefault("X-Amz-Security-Token")
  valid_602210 = validateParameter(valid_602210, JString, required = false,
                                 default = nil)
  if valid_602210 != nil:
    section.add "X-Amz-Security-Token", valid_602210
  var valid_602211 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602211 = validateParameter(valid_602211, JString, required = false,
                                 default = nil)
  if valid_602211 != nil:
    section.add "X-Amz-Content-Sha256", valid_602211
  var valid_602212 = header.getOrDefault("X-Amz-Algorithm")
  valid_602212 = validateParameter(valid_602212, JString, required = false,
                                 default = nil)
  if valid_602212 != nil:
    section.add "X-Amz-Algorithm", valid_602212
  var valid_602213 = header.getOrDefault("X-Amz-Signature")
  valid_602213 = validateParameter(valid_602213, JString, required = false,
                                 default = nil)
  if valid_602213 != nil:
    section.add "X-Amz-Signature", valid_602213
  var valid_602214 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602214 = validateParameter(valid_602214, JString, required = false,
                                 default = nil)
  if valid_602214 != nil:
    section.add "X-Amz-SignedHeaders", valid_602214
  var valid_602215 = header.getOrDefault("X-Amz-Credential")
  valid_602215 = validateParameter(valid_602215, JString, required = false,
                                 default = nil)
  if valid_602215 != nil:
    section.add "X-Amz-Credential", valid_602215
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602216: Call_GetListTagsForResource_602203; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ## 
  let valid = call_602216.validator(path, query, header, formData, body)
  let scheme = call_602216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602216.url(scheme.get, call_602216.host, call_602216.base,
                         call_602216.route, valid.getOrDefault("path"))
  result = hook(call_602216, url, valid)

proc call*(call_602217: Call_GetListTagsForResource_602203; ResourceArn: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-12-01"): Recallable =
  ## getListTagsForResource
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ##   ResourceArn: string (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce for which a tag list is requested.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602218 = newJObject()
  add(query_602218, "ResourceArn", newJString(ResourceArn))
  add(query_602218, "Action", newJString(Action))
  add(query_602218, "Version", newJString(Version))
  result = call_602217.call(nil, query_602218, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_602203(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_602204, base: "/",
    url: url_GetListTagsForResource_602205, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebuildEnvironment_602253 = ref object of OpenApiRestCall_600427
proc url_PostRebuildEnvironment_602255(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRebuildEnvironment_602254(path: JsonNode; query: JsonNode;
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
  var valid_602256 = query.getOrDefault("Action")
  valid_602256 = validateParameter(valid_602256, JString, required = true,
                                 default = newJString("RebuildEnvironment"))
  if valid_602256 != nil:
    section.add "Action", valid_602256
  var valid_602257 = query.getOrDefault("Version")
  valid_602257 = validateParameter(valid_602257, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602257 != nil:
    section.add "Version", valid_602257
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602258 = header.getOrDefault("X-Amz-Date")
  valid_602258 = validateParameter(valid_602258, JString, required = false,
                                 default = nil)
  if valid_602258 != nil:
    section.add "X-Amz-Date", valid_602258
  var valid_602259 = header.getOrDefault("X-Amz-Security-Token")
  valid_602259 = validateParameter(valid_602259, JString, required = false,
                                 default = nil)
  if valid_602259 != nil:
    section.add "X-Amz-Security-Token", valid_602259
  var valid_602260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602260 = validateParameter(valid_602260, JString, required = false,
                                 default = nil)
  if valid_602260 != nil:
    section.add "X-Amz-Content-Sha256", valid_602260
  var valid_602261 = header.getOrDefault("X-Amz-Algorithm")
  valid_602261 = validateParameter(valid_602261, JString, required = false,
                                 default = nil)
  if valid_602261 != nil:
    section.add "X-Amz-Algorithm", valid_602261
  var valid_602262 = header.getOrDefault("X-Amz-Signature")
  valid_602262 = validateParameter(valid_602262, JString, required = false,
                                 default = nil)
  if valid_602262 != nil:
    section.add "X-Amz-Signature", valid_602262
  var valid_602263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602263 = validateParameter(valid_602263, JString, required = false,
                                 default = nil)
  if valid_602263 != nil:
    section.add "X-Amz-SignedHeaders", valid_602263
  var valid_602264 = header.getOrDefault("X-Amz-Credential")
  valid_602264 = validateParameter(valid_602264, JString, required = false,
                                 default = nil)
  if valid_602264 != nil:
    section.add "X-Amz-Credential", valid_602264
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to rebuild.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to rebuild.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_602265 = formData.getOrDefault("EnvironmentId")
  valid_602265 = validateParameter(valid_602265, JString, required = false,
                                 default = nil)
  if valid_602265 != nil:
    section.add "EnvironmentId", valid_602265
  var valid_602266 = formData.getOrDefault("EnvironmentName")
  valid_602266 = validateParameter(valid_602266, JString, required = false,
                                 default = nil)
  if valid_602266 != nil:
    section.add "EnvironmentName", valid_602266
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602267: Call_PostRebuildEnvironment_602253; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes and recreates all of the AWS resources (for example: the Auto Scaling group, load balancer, etc.) for a specified environment and forces a restart.
  ## 
  let valid = call_602267.validator(path, query, header, formData, body)
  let scheme = call_602267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602267.url(scheme.get, call_602267.host, call_602267.base,
                         call_602267.route, valid.getOrDefault("path"))
  result = hook(call_602267, url, valid)

proc call*(call_602268: Call_PostRebuildEnvironment_602253;
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
  var query_602269 = newJObject()
  var formData_602270 = newJObject()
  add(formData_602270, "EnvironmentId", newJString(EnvironmentId))
  add(formData_602270, "EnvironmentName", newJString(EnvironmentName))
  add(query_602269, "Action", newJString(Action))
  add(query_602269, "Version", newJString(Version))
  result = call_602268.call(nil, query_602269, nil, formData_602270, nil)

var postRebuildEnvironment* = Call_PostRebuildEnvironment_602253(
    name: "postRebuildEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RebuildEnvironment",
    validator: validate_PostRebuildEnvironment_602254, base: "/",
    url: url_PostRebuildEnvironment_602255, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebuildEnvironment_602236 = ref object of OpenApiRestCall_600427
proc url_GetRebuildEnvironment_602238(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRebuildEnvironment_602237(path: JsonNode; query: JsonNode;
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
  var valid_602239 = query.getOrDefault("EnvironmentName")
  valid_602239 = validateParameter(valid_602239, JString, required = false,
                                 default = nil)
  if valid_602239 != nil:
    section.add "EnvironmentName", valid_602239
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602240 = query.getOrDefault("Action")
  valid_602240 = validateParameter(valid_602240, JString, required = true,
                                 default = newJString("RebuildEnvironment"))
  if valid_602240 != nil:
    section.add "Action", valid_602240
  var valid_602241 = query.getOrDefault("EnvironmentId")
  valid_602241 = validateParameter(valid_602241, JString, required = false,
                                 default = nil)
  if valid_602241 != nil:
    section.add "EnvironmentId", valid_602241
  var valid_602242 = query.getOrDefault("Version")
  valid_602242 = validateParameter(valid_602242, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602242 != nil:
    section.add "Version", valid_602242
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602243 = header.getOrDefault("X-Amz-Date")
  valid_602243 = validateParameter(valid_602243, JString, required = false,
                                 default = nil)
  if valid_602243 != nil:
    section.add "X-Amz-Date", valid_602243
  var valid_602244 = header.getOrDefault("X-Amz-Security-Token")
  valid_602244 = validateParameter(valid_602244, JString, required = false,
                                 default = nil)
  if valid_602244 != nil:
    section.add "X-Amz-Security-Token", valid_602244
  var valid_602245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602245 = validateParameter(valid_602245, JString, required = false,
                                 default = nil)
  if valid_602245 != nil:
    section.add "X-Amz-Content-Sha256", valid_602245
  var valid_602246 = header.getOrDefault("X-Amz-Algorithm")
  valid_602246 = validateParameter(valid_602246, JString, required = false,
                                 default = nil)
  if valid_602246 != nil:
    section.add "X-Amz-Algorithm", valid_602246
  var valid_602247 = header.getOrDefault("X-Amz-Signature")
  valid_602247 = validateParameter(valid_602247, JString, required = false,
                                 default = nil)
  if valid_602247 != nil:
    section.add "X-Amz-Signature", valid_602247
  var valid_602248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602248 = validateParameter(valid_602248, JString, required = false,
                                 default = nil)
  if valid_602248 != nil:
    section.add "X-Amz-SignedHeaders", valid_602248
  var valid_602249 = header.getOrDefault("X-Amz-Credential")
  valid_602249 = validateParameter(valid_602249, JString, required = false,
                                 default = nil)
  if valid_602249 != nil:
    section.add "X-Amz-Credential", valid_602249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602250: Call_GetRebuildEnvironment_602236; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes and recreates all of the AWS resources (for example: the Auto Scaling group, load balancer, etc.) for a specified environment and forces a restart.
  ## 
  let valid = call_602250.validator(path, query, header, formData, body)
  let scheme = call_602250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602250.url(scheme.get, call_602250.host, call_602250.base,
                         call_602250.route, valid.getOrDefault("path"))
  result = hook(call_602250, url, valid)

proc call*(call_602251: Call_GetRebuildEnvironment_602236;
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
  var query_602252 = newJObject()
  add(query_602252, "EnvironmentName", newJString(EnvironmentName))
  add(query_602252, "Action", newJString(Action))
  add(query_602252, "EnvironmentId", newJString(EnvironmentId))
  add(query_602252, "Version", newJString(Version))
  result = call_602251.call(nil, query_602252, nil, nil, nil)

var getRebuildEnvironment* = Call_GetRebuildEnvironment_602236(
    name: "getRebuildEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RebuildEnvironment",
    validator: validate_GetRebuildEnvironment_602237, base: "/",
    url: url_GetRebuildEnvironment_602238, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRequestEnvironmentInfo_602289 = ref object of OpenApiRestCall_600427
proc url_PostRequestEnvironmentInfo_602291(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRequestEnvironmentInfo_602290(path: JsonNode; query: JsonNode;
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
  var valid_602292 = query.getOrDefault("Action")
  valid_602292 = validateParameter(valid_602292, JString, required = true,
                                 default = newJString("RequestEnvironmentInfo"))
  if valid_602292 != nil:
    section.add "Action", valid_602292
  var valid_602293 = query.getOrDefault("Version")
  valid_602293 = validateParameter(valid_602293, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602293 != nil:
    section.add "Version", valid_602293
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602294 = header.getOrDefault("X-Amz-Date")
  valid_602294 = validateParameter(valid_602294, JString, required = false,
                                 default = nil)
  if valid_602294 != nil:
    section.add "X-Amz-Date", valid_602294
  var valid_602295 = header.getOrDefault("X-Amz-Security-Token")
  valid_602295 = validateParameter(valid_602295, JString, required = false,
                                 default = nil)
  if valid_602295 != nil:
    section.add "X-Amz-Security-Token", valid_602295
  var valid_602296 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602296 = validateParameter(valid_602296, JString, required = false,
                                 default = nil)
  if valid_602296 != nil:
    section.add "X-Amz-Content-Sha256", valid_602296
  var valid_602297 = header.getOrDefault("X-Amz-Algorithm")
  valid_602297 = validateParameter(valid_602297, JString, required = false,
                                 default = nil)
  if valid_602297 != nil:
    section.add "X-Amz-Algorithm", valid_602297
  var valid_602298 = header.getOrDefault("X-Amz-Signature")
  valid_602298 = validateParameter(valid_602298, JString, required = false,
                                 default = nil)
  if valid_602298 != nil:
    section.add "X-Amz-Signature", valid_602298
  var valid_602299 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602299 = validateParameter(valid_602299, JString, required = false,
                                 default = nil)
  if valid_602299 != nil:
    section.add "X-Amz-SignedHeaders", valid_602299
  var valid_602300 = header.getOrDefault("X-Amz-Credential")
  valid_602300 = validateParameter(valid_602300, JString, required = false,
                                 default = nil)
  if valid_602300 != nil:
    section.add "X-Amz-Credential", valid_602300
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
  var valid_602301 = formData.getOrDefault("InfoType")
  valid_602301 = validateParameter(valid_602301, JString, required = true,
                                 default = newJString("tail"))
  if valid_602301 != nil:
    section.add "InfoType", valid_602301
  var valid_602302 = formData.getOrDefault("EnvironmentId")
  valid_602302 = validateParameter(valid_602302, JString, required = false,
                                 default = nil)
  if valid_602302 != nil:
    section.add "EnvironmentId", valid_602302
  var valid_602303 = formData.getOrDefault("EnvironmentName")
  valid_602303 = validateParameter(valid_602303, JString, required = false,
                                 default = nil)
  if valid_602303 != nil:
    section.add "EnvironmentName", valid_602303
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602304: Call_PostRequestEnvironmentInfo_602289; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a request to compile the specified type of information of the deployed environment.</p> <p> Setting the <code>InfoType</code> to <code>tail</code> compiles the last lines from the application server log files of every Amazon EC2 instance in your environment. </p> <p> Setting the <code>InfoType</code> to <code>bundle</code> compresses the application server log files for every Amazon EC2 instance into a <code>.zip</code> file. Legacy and .NET containers do not support bundle logs. </p> <p> Use <a>RetrieveEnvironmentInfo</a> to obtain the set of logs. </p> <p>Related Topics</p> <ul> <li> <p> <a>RetrieveEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_602304.validator(path, query, header, formData, body)
  let scheme = call_602304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602304.url(scheme.get, call_602304.host, call_602304.base,
                         call_602304.route, valid.getOrDefault("path"))
  result = hook(call_602304, url, valid)

proc call*(call_602305: Call_PostRequestEnvironmentInfo_602289;
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
  var query_602306 = newJObject()
  var formData_602307 = newJObject()
  add(formData_602307, "InfoType", newJString(InfoType))
  add(formData_602307, "EnvironmentId", newJString(EnvironmentId))
  add(formData_602307, "EnvironmentName", newJString(EnvironmentName))
  add(query_602306, "Action", newJString(Action))
  add(query_602306, "Version", newJString(Version))
  result = call_602305.call(nil, query_602306, nil, formData_602307, nil)

var postRequestEnvironmentInfo* = Call_PostRequestEnvironmentInfo_602289(
    name: "postRequestEnvironmentInfo", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RequestEnvironmentInfo",
    validator: validate_PostRequestEnvironmentInfo_602290, base: "/",
    url: url_PostRequestEnvironmentInfo_602291,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRequestEnvironmentInfo_602271 = ref object of OpenApiRestCall_600427
proc url_GetRequestEnvironmentInfo_602273(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRequestEnvironmentInfo_602272(path: JsonNode; query: JsonNode;
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
  var valid_602274 = query.getOrDefault("InfoType")
  valid_602274 = validateParameter(valid_602274, JString, required = true,
                                 default = newJString("tail"))
  if valid_602274 != nil:
    section.add "InfoType", valid_602274
  var valid_602275 = query.getOrDefault("EnvironmentName")
  valid_602275 = validateParameter(valid_602275, JString, required = false,
                                 default = nil)
  if valid_602275 != nil:
    section.add "EnvironmentName", valid_602275
  var valid_602276 = query.getOrDefault("Action")
  valid_602276 = validateParameter(valid_602276, JString, required = true,
                                 default = newJString("RequestEnvironmentInfo"))
  if valid_602276 != nil:
    section.add "Action", valid_602276
  var valid_602277 = query.getOrDefault("EnvironmentId")
  valid_602277 = validateParameter(valid_602277, JString, required = false,
                                 default = nil)
  if valid_602277 != nil:
    section.add "EnvironmentId", valid_602277
  var valid_602278 = query.getOrDefault("Version")
  valid_602278 = validateParameter(valid_602278, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602278 != nil:
    section.add "Version", valid_602278
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602279 = header.getOrDefault("X-Amz-Date")
  valid_602279 = validateParameter(valid_602279, JString, required = false,
                                 default = nil)
  if valid_602279 != nil:
    section.add "X-Amz-Date", valid_602279
  var valid_602280 = header.getOrDefault("X-Amz-Security-Token")
  valid_602280 = validateParameter(valid_602280, JString, required = false,
                                 default = nil)
  if valid_602280 != nil:
    section.add "X-Amz-Security-Token", valid_602280
  var valid_602281 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602281 = validateParameter(valid_602281, JString, required = false,
                                 default = nil)
  if valid_602281 != nil:
    section.add "X-Amz-Content-Sha256", valid_602281
  var valid_602282 = header.getOrDefault("X-Amz-Algorithm")
  valid_602282 = validateParameter(valid_602282, JString, required = false,
                                 default = nil)
  if valid_602282 != nil:
    section.add "X-Amz-Algorithm", valid_602282
  var valid_602283 = header.getOrDefault("X-Amz-Signature")
  valid_602283 = validateParameter(valid_602283, JString, required = false,
                                 default = nil)
  if valid_602283 != nil:
    section.add "X-Amz-Signature", valid_602283
  var valid_602284 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602284 = validateParameter(valid_602284, JString, required = false,
                                 default = nil)
  if valid_602284 != nil:
    section.add "X-Amz-SignedHeaders", valid_602284
  var valid_602285 = header.getOrDefault("X-Amz-Credential")
  valid_602285 = validateParameter(valid_602285, JString, required = false,
                                 default = nil)
  if valid_602285 != nil:
    section.add "X-Amz-Credential", valid_602285
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602286: Call_GetRequestEnvironmentInfo_602271; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a request to compile the specified type of information of the deployed environment.</p> <p> Setting the <code>InfoType</code> to <code>tail</code> compiles the last lines from the application server log files of every Amazon EC2 instance in your environment. </p> <p> Setting the <code>InfoType</code> to <code>bundle</code> compresses the application server log files for every Amazon EC2 instance into a <code>.zip</code> file. Legacy and .NET containers do not support bundle logs. </p> <p> Use <a>RetrieveEnvironmentInfo</a> to obtain the set of logs. </p> <p>Related Topics</p> <ul> <li> <p> <a>RetrieveEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_602286.validator(path, query, header, formData, body)
  let scheme = call_602286.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602286.url(scheme.get, call_602286.host, call_602286.base,
                         call_602286.route, valid.getOrDefault("path"))
  result = hook(call_602286, url, valid)

proc call*(call_602287: Call_GetRequestEnvironmentInfo_602271;
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
  var query_602288 = newJObject()
  add(query_602288, "InfoType", newJString(InfoType))
  add(query_602288, "EnvironmentName", newJString(EnvironmentName))
  add(query_602288, "Action", newJString(Action))
  add(query_602288, "EnvironmentId", newJString(EnvironmentId))
  add(query_602288, "Version", newJString(Version))
  result = call_602287.call(nil, query_602288, nil, nil, nil)

var getRequestEnvironmentInfo* = Call_GetRequestEnvironmentInfo_602271(
    name: "getRequestEnvironmentInfo", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RequestEnvironmentInfo",
    validator: validate_GetRequestEnvironmentInfo_602272, base: "/",
    url: url_GetRequestEnvironmentInfo_602273,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestartAppServer_602325 = ref object of OpenApiRestCall_600427
proc url_PostRestartAppServer_602327(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRestartAppServer_602326(path: JsonNode; query: JsonNode;
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
  var valid_602328 = query.getOrDefault("Action")
  valid_602328 = validateParameter(valid_602328, JString, required = true,
                                 default = newJString("RestartAppServer"))
  if valid_602328 != nil:
    section.add "Action", valid_602328
  var valid_602329 = query.getOrDefault("Version")
  valid_602329 = validateParameter(valid_602329, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602329 != nil:
    section.add "Version", valid_602329
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602330 = header.getOrDefault("X-Amz-Date")
  valid_602330 = validateParameter(valid_602330, JString, required = false,
                                 default = nil)
  if valid_602330 != nil:
    section.add "X-Amz-Date", valid_602330
  var valid_602331 = header.getOrDefault("X-Amz-Security-Token")
  valid_602331 = validateParameter(valid_602331, JString, required = false,
                                 default = nil)
  if valid_602331 != nil:
    section.add "X-Amz-Security-Token", valid_602331
  var valid_602332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602332 = validateParameter(valid_602332, JString, required = false,
                                 default = nil)
  if valid_602332 != nil:
    section.add "X-Amz-Content-Sha256", valid_602332
  var valid_602333 = header.getOrDefault("X-Amz-Algorithm")
  valid_602333 = validateParameter(valid_602333, JString, required = false,
                                 default = nil)
  if valid_602333 != nil:
    section.add "X-Amz-Algorithm", valid_602333
  var valid_602334 = header.getOrDefault("X-Amz-Signature")
  valid_602334 = validateParameter(valid_602334, JString, required = false,
                                 default = nil)
  if valid_602334 != nil:
    section.add "X-Amz-Signature", valid_602334
  var valid_602335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602335 = validateParameter(valid_602335, JString, required = false,
                                 default = nil)
  if valid_602335 != nil:
    section.add "X-Amz-SignedHeaders", valid_602335
  var valid_602336 = header.getOrDefault("X-Amz-Credential")
  valid_602336 = validateParameter(valid_602336, JString, required = false,
                                 default = nil)
  if valid_602336 != nil:
    section.add "X-Amz-Credential", valid_602336
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to restart the server for.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to restart the server for.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_602337 = formData.getOrDefault("EnvironmentId")
  valid_602337 = validateParameter(valid_602337, JString, required = false,
                                 default = nil)
  if valid_602337 != nil:
    section.add "EnvironmentId", valid_602337
  var valid_602338 = formData.getOrDefault("EnvironmentName")
  valid_602338 = validateParameter(valid_602338, JString, required = false,
                                 default = nil)
  if valid_602338 != nil:
    section.add "EnvironmentName", valid_602338
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602339: Call_PostRestartAppServer_602325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Causes the environment to restart the application container server running on each Amazon EC2 instance.
  ## 
  let valid = call_602339.validator(path, query, header, formData, body)
  let scheme = call_602339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602339.url(scheme.get, call_602339.host, call_602339.base,
                         call_602339.route, valid.getOrDefault("path"))
  result = hook(call_602339, url, valid)

proc call*(call_602340: Call_PostRestartAppServer_602325;
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
  var query_602341 = newJObject()
  var formData_602342 = newJObject()
  add(formData_602342, "EnvironmentId", newJString(EnvironmentId))
  add(formData_602342, "EnvironmentName", newJString(EnvironmentName))
  add(query_602341, "Action", newJString(Action))
  add(query_602341, "Version", newJString(Version))
  result = call_602340.call(nil, query_602341, nil, formData_602342, nil)

var postRestartAppServer* = Call_PostRestartAppServer_602325(
    name: "postRestartAppServer", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RestartAppServer",
    validator: validate_PostRestartAppServer_602326, base: "/",
    url: url_PostRestartAppServer_602327, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestartAppServer_602308 = ref object of OpenApiRestCall_600427
proc url_GetRestartAppServer_602310(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRestartAppServer_602309(path: JsonNode; query: JsonNode;
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
  var valid_602311 = query.getOrDefault("EnvironmentName")
  valid_602311 = validateParameter(valid_602311, JString, required = false,
                                 default = nil)
  if valid_602311 != nil:
    section.add "EnvironmentName", valid_602311
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602312 = query.getOrDefault("Action")
  valid_602312 = validateParameter(valid_602312, JString, required = true,
                                 default = newJString("RestartAppServer"))
  if valid_602312 != nil:
    section.add "Action", valid_602312
  var valid_602313 = query.getOrDefault("EnvironmentId")
  valid_602313 = validateParameter(valid_602313, JString, required = false,
                                 default = nil)
  if valid_602313 != nil:
    section.add "EnvironmentId", valid_602313
  var valid_602314 = query.getOrDefault("Version")
  valid_602314 = validateParameter(valid_602314, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602314 != nil:
    section.add "Version", valid_602314
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602315 = header.getOrDefault("X-Amz-Date")
  valid_602315 = validateParameter(valid_602315, JString, required = false,
                                 default = nil)
  if valid_602315 != nil:
    section.add "X-Amz-Date", valid_602315
  var valid_602316 = header.getOrDefault("X-Amz-Security-Token")
  valid_602316 = validateParameter(valid_602316, JString, required = false,
                                 default = nil)
  if valid_602316 != nil:
    section.add "X-Amz-Security-Token", valid_602316
  var valid_602317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602317 = validateParameter(valid_602317, JString, required = false,
                                 default = nil)
  if valid_602317 != nil:
    section.add "X-Amz-Content-Sha256", valid_602317
  var valid_602318 = header.getOrDefault("X-Amz-Algorithm")
  valid_602318 = validateParameter(valid_602318, JString, required = false,
                                 default = nil)
  if valid_602318 != nil:
    section.add "X-Amz-Algorithm", valid_602318
  var valid_602319 = header.getOrDefault("X-Amz-Signature")
  valid_602319 = validateParameter(valid_602319, JString, required = false,
                                 default = nil)
  if valid_602319 != nil:
    section.add "X-Amz-Signature", valid_602319
  var valid_602320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602320 = validateParameter(valid_602320, JString, required = false,
                                 default = nil)
  if valid_602320 != nil:
    section.add "X-Amz-SignedHeaders", valid_602320
  var valid_602321 = header.getOrDefault("X-Amz-Credential")
  valid_602321 = validateParameter(valid_602321, JString, required = false,
                                 default = nil)
  if valid_602321 != nil:
    section.add "X-Amz-Credential", valid_602321
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602322: Call_GetRestartAppServer_602308; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Causes the environment to restart the application container server running on each Amazon EC2 instance.
  ## 
  let valid = call_602322.validator(path, query, header, formData, body)
  let scheme = call_602322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602322.url(scheme.get, call_602322.host, call_602322.base,
                         call_602322.route, valid.getOrDefault("path"))
  result = hook(call_602322, url, valid)

proc call*(call_602323: Call_GetRestartAppServer_602308;
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
  var query_602324 = newJObject()
  add(query_602324, "EnvironmentName", newJString(EnvironmentName))
  add(query_602324, "Action", newJString(Action))
  add(query_602324, "EnvironmentId", newJString(EnvironmentId))
  add(query_602324, "Version", newJString(Version))
  result = call_602323.call(nil, query_602324, nil, nil, nil)

var getRestartAppServer* = Call_GetRestartAppServer_602308(
    name: "getRestartAppServer", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RestartAppServer",
    validator: validate_GetRestartAppServer_602309, base: "/",
    url: url_GetRestartAppServer_602310, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRetrieveEnvironmentInfo_602361 = ref object of OpenApiRestCall_600427
proc url_PostRetrieveEnvironmentInfo_602363(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRetrieveEnvironmentInfo_602362(path: JsonNode; query: JsonNode;
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
  var valid_602364 = query.getOrDefault("Action")
  valid_602364 = validateParameter(valid_602364, JString, required = true, default = newJString(
      "RetrieveEnvironmentInfo"))
  if valid_602364 != nil:
    section.add "Action", valid_602364
  var valid_602365 = query.getOrDefault("Version")
  valid_602365 = validateParameter(valid_602365, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602365 != nil:
    section.add "Version", valid_602365
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602366 = header.getOrDefault("X-Amz-Date")
  valid_602366 = validateParameter(valid_602366, JString, required = false,
                                 default = nil)
  if valid_602366 != nil:
    section.add "X-Amz-Date", valid_602366
  var valid_602367 = header.getOrDefault("X-Amz-Security-Token")
  valid_602367 = validateParameter(valid_602367, JString, required = false,
                                 default = nil)
  if valid_602367 != nil:
    section.add "X-Amz-Security-Token", valid_602367
  var valid_602368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602368 = validateParameter(valid_602368, JString, required = false,
                                 default = nil)
  if valid_602368 != nil:
    section.add "X-Amz-Content-Sha256", valid_602368
  var valid_602369 = header.getOrDefault("X-Amz-Algorithm")
  valid_602369 = validateParameter(valid_602369, JString, required = false,
                                 default = nil)
  if valid_602369 != nil:
    section.add "X-Amz-Algorithm", valid_602369
  var valid_602370 = header.getOrDefault("X-Amz-Signature")
  valid_602370 = validateParameter(valid_602370, JString, required = false,
                                 default = nil)
  if valid_602370 != nil:
    section.add "X-Amz-Signature", valid_602370
  var valid_602371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602371 = validateParameter(valid_602371, JString, required = false,
                                 default = nil)
  if valid_602371 != nil:
    section.add "X-Amz-SignedHeaders", valid_602371
  var valid_602372 = header.getOrDefault("X-Amz-Credential")
  valid_602372 = validateParameter(valid_602372, JString, required = false,
                                 default = nil)
  if valid_602372 != nil:
    section.add "X-Amz-Credential", valid_602372
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
  var valid_602373 = formData.getOrDefault("InfoType")
  valid_602373 = validateParameter(valid_602373, JString, required = true,
                                 default = newJString("tail"))
  if valid_602373 != nil:
    section.add "InfoType", valid_602373
  var valid_602374 = formData.getOrDefault("EnvironmentId")
  valid_602374 = validateParameter(valid_602374, JString, required = false,
                                 default = nil)
  if valid_602374 != nil:
    section.add "EnvironmentId", valid_602374
  var valid_602375 = formData.getOrDefault("EnvironmentName")
  valid_602375 = validateParameter(valid_602375, JString, required = false,
                                 default = nil)
  if valid_602375 != nil:
    section.add "EnvironmentName", valid_602375
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602376: Call_PostRetrieveEnvironmentInfo_602361; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the compiled information from a <a>RequestEnvironmentInfo</a> request.</p> <p>Related Topics</p> <ul> <li> <p> <a>RequestEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_602376.validator(path, query, header, formData, body)
  let scheme = call_602376.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602376.url(scheme.get, call_602376.host, call_602376.base,
                         call_602376.route, valid.getOrDefault("path"))
  result = hook(call_602376, url, valid)

proc call*(call_602377: Call_PostRetrieveEnvironmentInfo_602361;
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
  var query_602378 = newJObject()
  var formData_602379 = newJObject()
  add(formData_602379, "InfoType", newJString(InfoType))
  add(formData_602379, "EnvironmentId", newJString(EnvironmentId))
  add(formData_602379, "EnvironmentName", newJString(EnvironmentName))
  add(query_602378, "Action", newJString(Action))
  add(query_602378, "Version", newJString(Version))
  result = call_602377.call(nil, query_602378, nil, formData_602379, nil)

var postRetrieveEnvironmentInfo* = Call_PostRetrieveEnvironmentInfo_602361(
    name: "postRetrieveEnvironmentInfo", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RetrieveEnvironmentInfo",
    validator: validate_PostRetrieveEnvironmentInfo_602362, base: "/",
    url: url_PostRetrieveEnvironmentInfo_602363,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRetrieveEnvironmentInfo_602343 = ref object of OpenApiRestCall_600427
proc url_GetRetrieveEnvironmentInfo_602345(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRetrieveEnvironmentInfo_602344(path: JsonNode; query: JsonNode;
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
  var valid_602346 = query.getOrDefault("InfoType")
  valid_602346 = validateParameter(valid_602346, JString, required = true,
                                 default = newJString("tail"))
  if valid_602346 != nil:
    section.add "InfoType", valid_602346
  var valid_602347 = query.getOrDefault("EnvironmentName")
  valid_602347 = validateParameter(valid_602347, JString, required = false,
                                 default = nil)
  if valid_602347 != nil:
    section.add "EnvironmentName", valid_602347
  var valid_602348 = query.getOrDefault("Action")
  valid_602348 = validateParameter(valid_602348, JString, required = true, default = newJString(
      "RetrieveEnvironmentInfo"))
  if valid_602348 != nil:
    section.add "Action", valid_602348
  var valid_602349 = query.getOrDefault("EnvironmentId")
  valid_602349 = validateParameter(valid_602349, JString, required = false,
                                 default = nil)
  if valid_602349 != nil:
    section.add "EnvironmentId", valid_602349
  var valid_602350 = query.getOrDefault("Version")
  valid_602350 = validateParameter(valid_602350, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602350 != nil:
    section.add "Version", valid_602350
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602351 = header.getOrDefault("X-Amz-Date")
  valid_602351 = validateParameter(valid_602351, JString, required = false,
                                 default = nil)
  if valid_602351 != nil:
    section.add "X-Amz-Date", valid_602351
  var valid_602352 = header.getOrDefault("X-Amz-Security-Token")
  valid_602352 = validateParameter(valid_602352, JString, required = false,
                                 default = nil)
  if valid_602352 != nil:
    section.add "X-Amz-Security-Token", valid_602352
  var valid_602353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602353 = validateParameter(valid_602353, JString, required = false,
                                 default = nil)
  if valid_602353 != nil:
    section.add "X-Amz-Content-Sha256", valid_602353
  var valid_602354 = header.getOrDefault("X-Amz-Algorithm")
  valid_602354 = validateParameter(valid_602354, JString, required = false,
                                 default = nil)
  if valid_602354 != nil:
    section.add "X-Amz-Algorithm", valid_602354
  var valid_602355 = header.getOrDefault("X-Amz-Signature")
  valid_602355 = validateParameter(valid_602355, JString, required = false,
                                 default = nil)
  if valid_602355 != nil:
    section.add "X-Amz-Signature", valid_602355
  var valid_602356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602356 = validateParameter(valid_602356, JString, required = false,
                                 default = nil)
  if valid_602356 != nil:
    section.add "X-Amz-SignedHeaders", valid_602356
  var valid_602357 = header.getOrDefault("X-Amz-Credential")
  valid_602357 = validateParameter(valid_602357, JString, required = false,
                                 default = nil)
  if valid_602357 != nil:
    section.add "X-Amz-Credential", valid_602357
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602358: Call_GetRetrieveEnvironmentInfo_602343; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the compiled information from a <a>RequestEnvironmentInfo</a> request.</p> <p>Related Topics</p> <ul> <li> <p> <a>RequestEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_602358.validator(path, query, header, formData, body)
  let scheme = call_602358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602358.url(scheme.get, call_602358.host, call_602358.base,
                         call_602358.route, valid.getOrDefault("path"))
  result = hook(call_602358, url, valid)

proc call*(call_602359: Call_GetRetrieveEnvironmentInfo_602343;
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
  var query_602360 = newJObject()
  add(query_602360, "InfoType", newJString(InfoType))
  add(query_602360, "EnvironmentName", newJString(EnvironmentName))
  add(query_602360, "Action", newJString(Action))
  add(query_602360, "EnvironmentId", newJString(EnvironmentId))
  add(query_602360, "Version", newJString(Version))
  result = call_602359.call(nil, query_602360, nil, nil, nil)

var getRetrieveEnvironmentInfo* = Call_GetRetrieveEnvironmentInfo_602343(
    name: "getRetrieveEnvironmentInfo", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RetrieveEnvironmentInfo",
    validator: validate_GetRetrieveEnvironmentInfo_602344, base: "/",
    url: url_GetRetrieveEnvironmentInfo_602345,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSwapEnvironmentCNAMEs_602399 = ref object of OpenApiRestCall_600427
proc url_PostSwapEnvironmentCNAMEs_602401(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostSwapEnvironmentCNAMEs_602400(path: JsonNode; query: JsonNode;
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
  var valid_602402 = query.getOrDefault("Action")
  valid_602402 = validateParameter(valid_602402, JString, required = true,
                                 default = newJString("SwapEnvironmentCNAMEs"))
  if valid_602402 != nil:
    section.add "Action", valid_602402
  var valid_602403 = query.getOrDefault("Version")
  valid_602403 = validateParameter(valid_602403, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602403 != nil:
    section.add "Version", valid_602403
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602404 = header.getOrDefault("X-Amz-Date")
  valid_602404 = validateParameter(valid_602404, JString, required = false,
                                 default = nil)
  if valid_602404 != nil:
    section.add "X-Amz-Date", valid_602404
  var valid_602405 = header.getOrDefault("X-Amz-Security-Token")
  valid_602405 = validateParameter(valid_602405, JString, required = false,
                                 default = nil)
  if valid_602405 != nil:
    section.add "X-Amz-Security-Token", valid_602405
  var valid_602406 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602406 = validateParameter(valid_602406, JString, required = false,
                                 default = nil)
  if valid_602406 != nil:
    section.add "X-Amz-Content-Sha256", valid_602406
  var valid_602407 = header.getOrDefault("X-Amz-Algorithm")
  valid_602407 = validateParameter(valid_602407, JString, required = false,
                                 default = nil)
  if valid_602407 != nil:
    section.add "X-Amz-Algorithm", valid_602407
  var valid_602408 = header.getOrDefault("X-Amz-Signature")
  valid_602408 = validateParameter(valid_602408, JString, required = false,
                                 default = nil)
  if valid_602408 != nil:
    section.add "X-Amz-Signature", valid_602408
  var valid_602409 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602409 = validateParameter(valid_602409, JString, required = false,
                                 default = nil)
  if valid_602409 != nil:
    section.add "X-Amz-SignedHeaders", valid_602409
  var valid_602410 = header.getOrDefault("X-Amz-Credential")
  valid_602410 = validateParameter(valid_602410, JString, required = false,
                                 default = nil)
  if valid_602410 != nil:
    section.add "X-Amz-Credential", valid_602410
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
  var valid_602411 = formData.getOrDefault("SourceEnvironmentName")
  valid_602411 = validateParameter(valid_602411, JString, required = false,
                                 default = nil)
  if valid_602411 != nil:
    section.add "SourceEnvironmentName", valid_602411
  var valid_602412 = formData.getOrDefault("SourceEnvironmentId")
  valid_602412 = validateParameter(valid_602412, JString, required = false,
                                 default = nil)
  if valid_602412 != nil:
    section.add "SourceEnvironmentId", valid_602412
  var valid_602413 = formData.getOrDefault("DestinationEnvironmentId")
  valid_602413 = validateParameter(valid_602413, JString, required = false,
                                 default = nil)
  if valid_602413 != nil:
    section.add "DestinationEnvironmentId", valid_602413
  var valid_602414 = formData.getOrDefault("DestinationEnvironmentName")
  valid_602414 = validateParameter(valid_602414, JString, required = false,
                                 default = nil)
  if valid_602414 != nil:
    section.add "DestinationEnvironmentName", valid_602414
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602415: Call_PostSwapEnvironmentCNAMEs_602399; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Swaps the CNAMEs of two environments.
  ## 
  let valid = call_602415.validator(path, query, header, formData, body)
  let scheme = call_602415.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602415.url(scheme.get, call_602415.host, call_602415.base,
                         call_602415.route, valid.getOrDefault("path"))
  result = hook(call_602415, url, valid)

proc call*(call_602416: Call_PostSwapEnvironmentCNAMEs_602399;
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
  var query_602417 = newJObject()
  var formData_602418 = newJObject()
  add(formData_602418, "SourceEnvironmentName", newJString(SourceEnvironmentName))
  add(formData_602418, "SourceEnvironmentId", newJString(SourceEnvironmentId))
  add(formData_602418, "DestinationEnvironmentId",
      newJString(DestinationEnvironmentId))
  add(formData_602418, "DestinationEnvironmentName",
      newJString(DestinationEnvironmentName))
  add(query_602417, "Action", newJString(Action))
  add(query_602417, "Version", newJString(Version))
  result = call_602416.call(nil, query_602417, nil, formData_602418, nil)

var postSwapEnvironmentCNAMEs* = Call_PostSwapEnvironmentCNAMEs_602399(
    name: "postSwapEnvironmentCNAMEs", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=SwapEnvironmentCNAMEs",
    validator: validate_PostSwapEnvironmentCNAMEs_602400, base: "/",
    url: url_PostSwapEnvironmentCNAMEs_602401,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSwapEnvironmentCNAMEs_602380 = ref object of OpenApiRestCall_600427
proc url_GetSwapEnvironmentCNAMEs_602382(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSwapEnvironmentCNAMEs_602381(path: JsonNode; query: JsonNode;
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
  var valid_602383 = query.getOrDefault("SourceEnvironmentId")
  valid_602383 = validateParameter(valid_602383, JString, required = false,
                                 default = nil)
  if valid_602383 != nil:
    section.add "SourceEnvironmentId", valid_602383
  var valid_602384 = query.getOrDefault("DestinationEnvironmentName")
  valid_602384 = validateParameter(valid_602384, JString, required = false,
                                 default = nil)
  if valid_602384 != nil:
    section.add "DestinationEnvironmentName", valid_602384
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602385 = query.getOrDefault("Action")
  valid_602385 = validateParameter(valid_602385, JString, required = true,
                                 default = newJString("SwapEnvironmentCNAMEs"))
  if valid_602385 != nil:
    section.add "Action", valid_602385
  var valid_602386 = query.getOrDefault("SourceEnvironmentName")
  valid_602386 = validateParameter(valid_602386, JString, required = false,
                                 default = nil)
  if valid_602386 != nil:
    section.add "SourceEnvironmentName", valid_602386
  var valid_602387 = query.getOrDefault("DestinationEnvironmentId")
  valid_602387 = validateParameter(valid_602387, JString, required = false,
                                 default = nil)
  if valid_602387 != nil:
    section.add "DestinationEnvironmentId", valid_602387
  var valid_602388 = query.getOrDefault("Version")
  valid_602388 = validateParameter(valid_602388, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602388 != nil:
    section.add "Version", valid_602388
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602389 = header.getOrDefault("X-Amz-Date")
  valid_602389 = validateParameter(valid_602389, JString, required = false,
                                 default = nil)
  if valid_602389 != nil:
    section.add "X-Amz-Date", valid_602389
  var valid_602390 = header.getOrDefault("X-Amz-Security-Token")
  valid_602390 = validateParameter(valid_602390, JString, required = false,
                                 default = nil)
  if valid_602390 != nil:
    section.add "X-Amz-Security-Token", valid_602390
  var valid_602391 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602391 = validateParameter(valid_602391, JString, required = false,
                                 default = nil)
  if valid_602391 != nil:
    section.add "X-Amz-Content-Sha256", valid_602391
  var valid_602392 = header.getOrDefault("X-Amz-Algorithm")
  valid_602392 = validateParameter(valid_602392, JString, required = false,
                                 default = nil)
  if valid_602392 != nil:
    section.add "X-Amz-Algorithm", valid_602392
  var valid_602393 = header.getOrDefault("X-Amz-Signature")
  valid_602393 = validateParameter(valid_602393, JString, required = false,
                                 default = nil)
  if valid_602393 != nil:
    section.add "X-Amz-Signature", valid_602393
  var valid_602394 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602394 = validateParameter(valid_602394, JString, required = false,
                                 default = nil)
  if valid_602394 != nil:
    section.add "X-Amz-SignedHeaders", valid_602394
  var valid_602395 = header.getOrDefault("X-Amz-Credential")
  valid_602395 = validateParameter(valid_602395, JString, required = false,
                                 default = nil)
  if valid_602395 != nil:
    section.add "X-Amz-Credential", valid_602395
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602396: Call_GetSwapEnvironmentCNAMEs_602380; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Swaps the CNAMEs of two environments.
  ## 
  let valid = call_602396.validator(path, query, header, formData, body)
  let scheme = call_602396.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602396.url(scheme.get, call_602396.host, call_602396.base,
                         call_602396.route, valid.getOrDefault("path"))
  result = hook(call_602396, url, valid)

proc call*(call_602397: Call_GetSwapEnvironmentCNAMEs_602380;
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
  var query_602398 = newJObject()
  add(query_602398, "SourceEnvironmentId", newJString(SourceEnvironmentId))
  add(query_602398, "DestinationEnvironmentName",
      newJString(DestinationEnvironmentName))
  add(query_602398, "Action", newJString(Action))
  add(query_602398, "SourceEnvironmentName", newJString(SourceEnvironmentName))
  add(query_602398, "DestinationEnvironmentId",
      newJString(DestinationEnvironmentId))
  add(query_602398, "Version", newJString(Version))
  result = call_602397.call(nil, query_602398, nil, nil, nil)

var getSwapEnvironmentCNAMEs* = Call_GetSwapEnvironmentCNAMEs_602380(
    name: "getSwapEnvironmentCNAMEs", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=SwapEnvironmentCNAMEs",
    validator: validate_GetSwapEnvironmentCNAMEs_602381, base: "/",
    url: url_GetSwapEnvironmentCNAMEs_602382, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostTerminateEnvironment_602438 = ref object of OpenApiRestCall_600427
proc url_PostTerminateEnvironment_602440(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostTerminateEnvironment_602439(path: JsonNode; query: JsonNode;
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
  var valid_602441 = query.getOrDefault("Action")
  valid_602441 = validateParameter(valid_602441, JString, required = true,
                                 default = newJString("TerminateEnvironment"))
  if valid_602441 != nil:
    section.add "Action", valid_602441
  var valid_602442 = query.getOrDefault("Version")
  valid_602442 = validateParameter(valid_602442, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602442 != nil:
    section.add "Version", valid_602442
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602443 = header.getOrDefault("X-Amz-Date")
  valid_602443 = validateParameter(valid_602443, JString, required = false,
                                 default = nil)
  if valid_602443 != nil:
    section.add "X-Amz-Date", valid_602443
  var valid_602444 = header.getOrDefault("X-Amz-Security-Token")
  valid_602444 = validateParameter(valid_602444, JString, required = false,
                                 default = nil)
  if valid_602444 != nil:
    section.add "X-Amz-Security-Token", valid_602444
  var valid_602445 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602445 = validateParameter(valid_602445, JString, required = false,
                                 default = nil)
  if valid_602445 != nil:
    section.add "X-Amz-Content-Sha256", valid_602445
  var valid_602446 = header.getOrDefault("X-Amz-Algorithm")
  valid_602446 = validateParameter(valid_602446, JString, required = false,
                                 default = nil)
  if valid_602446 != nil:
    section.add "X-Amz-Algorithm", valid_602446
  var valid_602447 = header.getOrDefault("X-Amz-Signature")
  valid_602447 = validateParameter(valid_602447, JString, required = false,
                                 default = nil)
  if valid_602447 != nil:
    section.add "X-Amz-Signature", valid_602447
  var valid_602448 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602448 = validateParameter(valid_602448, JString, required = false,
                                 default = nil)
  if valid_602448 != nil:
    section.add "X-Amz-SignedHeaders", valid_602448
  var valid_602449 = header.getOrDefault("X-Amz-Credential")
  valid_602449 = validateParameter(valid_602449, JString, required = false,
                                 default = nil)
  if valid_602449 != nil:
    section.add "X-Amz-Credential", valid_602449
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
  var valid_602450 = formData.getOrDefault("ForceTerminate")
  valid_602450 = validateParameter(valid_602450, JBool, required = false, default = nil)
  if valid_602450 != nil:
    section.add "ForceTerminate", valid_602450
  var valid_602451 = formData.getOrDefault("TerminateResources")
  valid_602451 = validateParameter(valid_602451, JBool, required = false, default = nil)
  if valid_602451 != nil:
    section.add "TerminateResources", valid_602451
  var valid_602452 = formData.getOrDefault("EnvironmentId")
  valid_602452 = validateParameter(valid_602452, JString, required = false,
                                 default = nil)
  if valid_602452 != nil:
    section.add "EnvironmentId", valid_602452
  var valid_602453 = formData.getOrDefault("EnvironmentName")
  valid_602453 = validateParameter(valid_602453, JString, required = false,
                                 default = nil)
  if valid_602453 != nil:
    section.add "EnvironmentName", valid_602453
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602454: Call_PostTerminateEnvironment_602438; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Terminates the specified environment.
  ## 
  let valid = call_602454.validator(path, query, header, formData, body)
  let scheme = call_602454.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602454.url(scheme.get, call_602454.host, call_602454.base,
                         call_602454.route, valid.getOrDefault("path"))
  result = hook(call_602454, url, valid)

proc call*(call_602455: Call_PostTerminateEnvironment_602438;
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
  var query_602456 = newJObject()
  var formData_602457 = newJObject()
  add(formData_602457, "ForceTerminate", newJBool(ForceTerminate))
  add(formData_602457, "TerminateResources", newJBool(TerminateResources))
  add(formData_602457, "EnvironmentId", newJString(EnvironmentId))
  add(formData_602457, "EnvironmentName", newJString(EnvironmentName))
  add(query_602456, "Action", newJString(Action))
  add(query_602456, "Version", newJString(Version))
  result = call_602455.call(nil, query_602456, nil, formData_602457, nil)

var postTerminateEnvironment* = Call_PostTerminateEnvironment_602438(
    name: "postTerminateEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=TerminateEnvironment",
    validator: validate_PostTerminateEnvironment_602439, base: "/",
    url: url_PostTerminateEnvironment_602440, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTerminateEnvironment_602419 = ref object of OpenApiRestCall_600427
proc url_GetTerminateEnvironment_602421(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetTerminateEnvironment_602420(path: JsonNode; query: JsonNode;
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
  var valid_602422 = query.getOrDefault("EnvironmentName")
  valid_602422 = validateParameter(valid_602422, JString, required = false,
                                 default = nil)
  if valid_602422 != nil:
    section.add "EnvironmentName", valid_602422
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602423 = query.getOrDefault("Action")
  valid_602423 = validateParameter(valid_602423, JString, required = true,
                                 default = newJString("TerminateEnvironment"))
  if valid_602423 != nil:
    section.add "Action", valid_602423
  var valid_602424 = query.getOrDefault("EnvironmentId")
  valid_602424 = validateParameter(valid_602424, JString, required = false,
                                 default = nil)
  if valid_602424 != nil:
    section.add "EnvironmentId", valid_602424
  var valid_602425 = query.getOrDefault("ForceTerminate")
  valid_602425 = validateParameter(valid_602425, JBool, required = false, default = nil)
  if valid_602425 != nil:
    section.add "ForceTerminate", valid_602425
  var valid_602426 = query.getOrDefault("TerminateResources")
  valid_602426 = validateParameter(valid_602426, JBool, required = false, default = nil)
  if valid_602426 != nil:
    section.add "TerminateResources", valid_602426
  var valid_602427 = query.getOrDefault("Version")
  valid_602427 = validateParameter(valid_602427, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602427 != nil:
    section.add "Version", valid_602427
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602428 = header.getOrDefault("X-Amz-Date")
  valid_602428 = validateParameter(valid_602428, JString, required = false,
                                 default = nil)
  if valid_602428 != nil:
    section.add "X-Amz-Date", valid_602428
  var valid_602429 = header.getOrDefault("X-Amz-Security-Token")
  valid_602429 = validateParameter(valid_602429, JString, required = false,
                                 default = nil)
  if valid_602429 != nil:
    section.add "X-Amz-Security-Token", valid_602429
  var valid_602430 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602430 = validateParameter(valid_602430, JString, required = false,
                                 default = nil)
  if valid_602430 != nil:
    section.add "X-Amz-Content-Sha256", valid_602430
  var valid_602431 = header.getOrDefault("X-Amz-Algorithm")
  valid_602431 = validateParameter(valid_602431, JString, required = false,
                                 default = nil)
  if valid_602431 != nil:
    section.add "X-Amz-Algorithm", valid_602431
  var valid_602432 = header.getOrDefault("X-Amz-Signature")
  valid_602432 = validateParameter(valid_602432, JString, required = false,
                                 default = nil)
  if valid_602432 != nil:
    section.add "X-Amz-Signature", valid_602432
  var valid_602433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602433 = validateParameter(valid_602433, JString, required = false,
                                 default = nil)
  if valid_602433 != nil:
    section.add "X-Amz-SignedHeaders", valid_602433
  var valid_602434 = header.getOrDefault("X-Amz-Credential")
  valid_602434 = validateParameter(valid_602434, JString, required = false,
                                 default = nil)
  if valid_602434 != nil:
    section.add "X-Amz-Credential", valid_602434
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602435: Call_GetTerminateEnvironment_602419; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Terminates the specified environment.
  ## 
  let valid = call_602435.validator(path, query, header, formData, body)
  let scheme = call_602435.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602435.url(scheme.get, call_602435.host, call_602435.base,
                         call_602435.route, valid.getOrDefault("path"))
  result = hook(call_602435, url, valid)

proc call*(call_602436: Call_GetTerminateEnvironment_602419;
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
  var query_602437 = newJObject()
  add(query_602437, "EnvironmentName", newJString(EnvironmentName))
  add(query_602437, "Action", newJString(Action))
  add(query_602437, "EnvironmentId", newJString(EnvironmentId))
  add(query_602437, "ForceTerminate", newJBool(ForceTerminate))
  add(query_602437, "TerminateResources", newJBool(TerminateResources))
  add(query_602437, "Version", newJString(Version))
  result = call_602436.call(nil, query_602437, nil, nil, nil)

var getTerminateEnvironment* = Call_GetTerminateEnvironment_602419(
    name: "getTerminateEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=TerminateEnvironment",
    validator: validate_GetTerminateEnvironment_602420, base: "/",
    url: url_GetTerminateEnvironment_602421, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateApplication_602475 = ref object of OpenApiRestCall_600427
proc url_PostUpdateApplication_602477(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostUpdateApplication_602476(path: JsonNode; query: JsonNode;
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
  var valid_602478 = query.getOrDefault("Action")
  valid_602478 = validateParameter(valid_602478, JString, required = true,
                                 default = newJString("UpdateApplication"))
  if valid_602478 != nil:
    section.add "Action", valid_602478
  var valid_602479 = query.getOrDefault("Version")
  valid_602479 = validateParameter(valid_602479, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602479 != nil:
    section.add "Version", valid_602479
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602480 = header.getOrDefault("X-Amz-Date")
  valid_602480 = validateParameter(valid_602480, JString, required = false,
                                 default = nil)
  if valid_602480 != nil:
    section.add "X-Amz-Date", valid_602480
  var valid_602481 = header.getOrDefault("X-Amz-Security-Token")
  valid_602481 = validateParameter(valid_602481, JString, required = false,
                                 default = nil)
  if valid_602481 != nil:
    section.add "X-Amz-Security-Token", valid_602481
  var valid_602482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602482 = validateParameter(valid_602482, JString, required = false,
                                 default = nil)
  if valid_602482 != nil:
    section.add "X-Amz-Content-Sha256", valid_602482
  var valid_602483 = header.getOrDefault("X-Amz-Algorithm")
  valid_602483 = validateParameter(valid_602483, JString, required = false,
                                 default = nil)
  if valid_602483 != nil:
    section.add "X-Amz-Algorithm", valid_602483
  var valid_602484 = header.getOrDefault("X-Amz-Signature")
  valid_602484 = validateParameter(valid_602484, JString, required = false,
                                 default = nil)
  if valid_602484 != nil:
    section.add "X-Amz-Signature", valid_602484
  var valid_602485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602485 = validateParameter(valid_602485, JString, required = false,
                                 default = nil)
  if valid_602485 != nil:
    section.add "X-Amz-SignedHeaders", valid_602485
  var valid_602486 = header.getOrDefault("X-Amz-Credential")
  valid_602486 = validateParameter(valid_602486, JString, required = false,
                                 default = nil)
  if valid_602486 != nil:
    section.add "X-Amz-Credential", valid_602486
  result.add "header", section
  ## parameters in `formData` object:
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to update. If no such application is found, <code>UpdateApplication</code> returns an <code>InvalidParameterValue</code> error. 
  ##   Description: JString
  ##              : <p>A new description for the application.</p> <p>Default: If not specified, AWS Elastic Beanstalk does not update the description.</p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_602487 = formData.getOrDefault("ApplicationName")
  valid_602487 = validateParameter(valid_602487, JString, required = true,
                                 default = nil)
  if valid_602487 != nil:
    section.add "ApplicationName", valid_602487
  var valid_602488 = formData.getOrDefault("Description")
  valid_602488 = validateParameter(valid_602488, JString, required = false,
                                 default = nil)
  if valid_602488 != nil:
    section.add "Description", valid_602488
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602489: Call_PostUpdateApplication_602475; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified application to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear these properties, specify an empty string.</p> </note>
  ## 
  let valid = call_602489.validator(path, query, header, formData, body)
  let scheme = call_602489.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602489.url(scheme.get, call_602489.host, call_602489.base,
                         call_602489.route, valid.getOrDefault("path"))
  result = hook(call_602489, url, valid)

proc call*(call_602490: Call_PostUpdateApplication_602475; ApplicationName: string;
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
  var query_602491 = newJObject()
  var formData_602492 = newJObject()
  add(query_602491, "Action", newJString(Action))
  add(formData_602492, "ApplicationName", newJString(ApplicationName))
  add(query_602491, "Version", newJString(Version))
  add(formData_602492, "Description", newJString(Description))
  result = call_602490.call(nil, query_602491, nil, formData_602492, nil)

var postUpdateApplication* = Call_PostUpdateApplication_602475(
    name: "postUpdateApplication", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateApplication",
    validator: validate_PostUpdateApplication_602476, base: "/",
    url: url_PostUpdateApplication_602477, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateApplication_602458 = ref object of OpenApiRestCall_600427
proc url_GetUpdateApplication_602460(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUpdateApplication_602459(path: JsonNode; query: JsonNode;
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
  var valid_602461 = query.getOrDefault("ApplicationName")
  valid_602461 = validateParameter(valid_602461, JString, required = true,
                                 default = nil)
  if valid_602461 != nil:
    section.add "ApplicationName", valid_602461
  var valid_602462 = query.getOrDefault("Description")
  valid_602462 = validateParameter(valid_602462, JString, required = false,
                                 default = nil)
  if valid_602462 != nil:
    section.add "Description", valid_602462
  var valid_602463 = query.getOrDefault("Action")
  valid_602463 = validateParameter(valid_602463, JString, required = true,
                                 default = newJString("UpdateApplication"))
  if valid_602463 != nil:
    section.add "Action", valid_602463
  var valid_602464 = query.getOrDefault("Version")
  valid_602464 = validateParameter(valid_602464, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602464 != nil:
    section.add "Version", valid_602464
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602465 = header.getOrDefault("X-Amz-Date")
  valid_602465 = validateParameter(valid_602465, JString, required = false,
                                 default = nil)
  if valid_602465 != nil:
    section.add "X-Amz-Date", valid_602465
  var valid_602466 = header.getOrDefault("X-Amz-Security-Token")
  valid_602466 = validateParameter(valid_602466, JString, required = false,
                                 default = nil)
  if valid_602466 != nil:
    section.add "X-Amz-Security-Token", valid_602466
  var valid_602467 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602467 = validateParameter(valid_602467, JString, required = false,
                                 default = nil)
  if valid_602467 != nil:
    section.add "X-Amz-Content-Sha256", valid_602467
  var valid_602468 = header.getOrDefault("X-Amz-Algorithm")
  valid_602468 = validateParameter(valid_602468, JString, required = false,
                                 default = nil)
  if valid_602468 != nil:
    section.add "X-Amz-Algorithm", valid_602468
  var valid_602469 = header.getOrDefault("X-Amz-Signature")
  valid_602469 = validateParameter(valid_602469, JString, required = false,
                                 default = nil)
  if valid_602469 != nil:
    section.add "X-Amz-Signature", valid_602469
  var valid_602470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602470 = validateParameter(valid_602470, JString, required = false,
                                 default = nil)
  if valid_602470 != nil:
    section.add "X-Amz-SignedHeaders", valid_602470
  var valid_602471 = header.getOrDefault("X-Amz-Credential")
  valid_602471 = validateParameter(valid_602471, JString, required = false,
                                 default = nil)
  if valid_602471 != nil:
    section.add "X-Amz-Credential", valid_602471
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602472: Call_GetUpdateApplication_602458; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified application to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear these properties, specify an empty string.</p> </note>
  ## 
  let valid = call_602472.validator(path, query, header, formData, body)
  let scheme = call_602472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602472.url(scheme.get, call_602472.host, call_602472.base,
                         call_602472.route, valid.getOrDefault("path"))
  result = hook(call_602472, url, valid)

proc call*(call_602473: Call_GetUpdateApplication_602458; ApplicationName: string;
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
  var query_602474 = newJObject()
  add(query_602474, "ApplicationName", newJString(ApplicationName))
  add(query_602474, "Description", newJString(Description))
  add(query_602474, "Action", newJString(Action))
  add(query_602474, "Version", newJString(Version))
  result = call_602473.call(nil, query_602474, nil, nil, nil)

var getUpdateApplication* = Call_GetUpdateApplication_602458(
    name: "getUpdateApplication", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateApplication",
    validator: validate_GetUpdateApplication_602459, base: "/",
    url: url_GetUpdateApplication_602460, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateApplicationResourceLifecycle_602511 = ref object of OpenApiRestCall_600427
proc url_PostUpdateApplicationResourceLifecycle_602513(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostUpdateApplicationResourceLifecycle_602512(path: JsonNode;
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
  var valid_602514 = query.getOrDefault("Action")
  valid_602514 = validateParameter(valid_602514, JString, required = true, default = newJString(
      "UpdateApplicationResourceLifecycle"))
  if valid_602514 != nil:
    section.add "Action", valid_602514
  var valid_602515 = query.getOrDefault("Version")
  valid_602515 = validateParameter(valid_602515, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602515 != nil:
    section.add "Version", valid_602515
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602516 = header.getOrDefault("X-Amz-Date")
  valid_602516 = validateParameter(valid_602516, JString, required = false,
                                 default = nil)
  if valid_602516 != nil:
    section.add "X-Amz-Date", valid_602516
  var valid_602517 = header.getOrDefault("X-Amz-Security-Token")
  valid_602517 = validateParameter(valid_602517, JString, required = false,
                                 default = nil)
  if valid_602517 != nil:
    section.add "X-Amz-Security-Token", valid_602517
  var valid_602518 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602518 = validateParameter(valid_602518, JString, required = false,
                                 default = nil)
  if valid_602518 != nil:
    section.add "X-Amz-Content-Sha256", valid_602518
  var valid_602519 = header.getOrDefault("X-Amz-Algorithm")
  valid_602519 = validateParameter(valid_602519, JString, required = false,
                                 default = nil)
  if valid_602519 != nil:
    section.add "X-Amz-Algorithm", valid_602519
  var valid_602520 = header.getOrDefault("X-Amz-Signature")
  valid_602520 = validateParameter(valid_602520, JString, required = false,
                                 default = nil)
  if valid_602520 != nil:
    section.add "X-Amz-Signature", valid_602520
  var valid_602521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602521 = validateParameter(valid_602521, JString, required = false,
                                 default = nil)
  if valid_602521 != nil:
    section.add "X-Amz-SignedHeaders", valid_602521
  var valid_602522 = header.getOrDefault("X-Amz-Credential")
  valid_602522 = validateParameter(valid_602522, JString, required = false,
                                 default = nil)
  if valid_602522 != nil:
    section.add "X-Amz-Credential", valid_602522
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
  var valid_602523 = formData.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_602523 = validateParameter(valid_602523, JString, required = false,
                                 default = nil)
  if valid_602523 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_602523
  var valid_602524 = formData.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_602524 = validateParameter(valid_602524, JString, required = false,
                                 default = nil)
  if valid_602524 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_602524
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_602525 = formData.getOrDefault("ApplicationName")
  valid_602525 = validateParameter(valid_602525, JString, required = true,
                                 default = nil)
  if valid_602525 != nil:
    section.add "ApplicationName", valid_602525
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602526: Call_PostUpdateApplicationResourceLifecycle_602511;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Modifies lifecycle settings for an application.
  ## 
  let valid = call_602526.validator(path, query, header, formData, body)
  let scheme = call_602526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602526.url(scheme.get, call_602526.host, call_602526.base,
                         call_602526.route, valid.getOrDefault("path"))
  result = hook(call_602526, url, valid)

proc call*(call_602527: Call_PostUpdateApplicationResourceLifecycle_602511;
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
  var query_602528 = newJObject()
  var formData_602529 = newJObject()
  add(formData_602529, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  add(formData_602529, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  add(query_602528, "Action", newJString(Action))
  add(formData_602529, "ApplicationName", newJString(ApplicationName))
  add(query_602528, "Version", newJString(Version))
  result = call_602527.call(nil, query_602528, nil, formData_602529, nil)

var postUpdateApplicationResourceLifecycle* = Call_PostUpdateApplicationResourceLifecycle_602511(
    name: "postUpdateApplicationResourceLifecycle", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationResourceLifecycle",
    validator: validate_PostUpdateApplicationResourceLifecycle_602512, base: "/",
    url: url_PostUpdateApplicationResourceLifecycle_602513,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateApplicationResourceLifecycle_602493 = ref object of OpenApiRestCall_600427
proc url_GetUpdateApplicationResourceLifecycle_602495(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUpdateApplicationResourceLifecycle_602494(path: JsonNode;
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
  var valid_602496 = query.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_602496 = validateParameter(valid_602496, JString, required = false,
                                 default = nil)
  if valid_602496 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_602496
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_602497 = query.getOrDefault("ApplicationName")
  valid_602497 = validateParameter(valid_602497, JString, required = true,
                                 default = nil)
  if valid_602497 != nil:
    section.add "ApplicationName", valid_602497
  var valid_602498 = query.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_602498 = validateParameter(valid_602498, JString, required = false,
                                 default = nil)
  if valid_602498 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_602498
  var valid_602499 = query.getOrDefault("Action")
  valid_602499 = validateParameter(valid_602499, JString, required = true, default = newJString(
      "UpdateApplicationResourceLifecycle"))
  if valid_602499 != nil:
    section.add "Action", valid_602499
  var valid_602500 = query.getOrDefault("Version")
  valid_602500 = validateParameter(valid_602500, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602500 != nil:
    section.add "Version", valid_602500
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602501 = header.getOrDefault("X-Amz-Date")
  valid_602501 = validateParameter(valid_602501, JString, required = false,
                                 default = nil)
  if valid_602501 != nil:
    section.add "X-Amz-Date", valid_602501
  var valid_602502 = header.getOrDefault("X-Amz-Security-Token")
  valid_602502 = validateParameter(valid_602502, JString, required = false,
                                 default = nil)
  if valid_602502 != nil:
    section.add "X-Amz-Security-Token", valid_602502
  var valid_602503 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602503 = validateParameter(valid_602503, JString, required = false,
                                 default = nil)
  if valid_602503 != nil:
    section.add "X-Amz-Content-Sha256", valid_602503
  var valid_602504 = header.getOrDefault("X-Amz-Algorithm")
  valid_602504 = validateParameter(valid_602504, JString, required = false,
                                 default = nil)
  if valid_602504 != nil:
    section.add "X-Amz-Algorithm", valid_602504
  var valid_602505 = header.getOrDefault("X-Amz-Signature")
  valid_602505 = validateParameter(valid_602505, JString, required = false,
                                 default = nil)
  if valid_602505 != nil:
    section.add "X-Amz-Signature", valid_602505
  var valid_602506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602506 = validateParameter(valid_602506, JString, required = false,
                                 default = nil)
  if valid_602506 != nil:
    section.add "X-Amz-SignedHeaders", valid_602506
  var valid_602507 = header.getOrDefault("X-Amz-Credential")
  valid_602507 = validateParameter(valid_602507, JString, required = false,
                                 default = nil)
  if valid_602507 != nil:
    section.add "X-Amz-Credential", valid_602507
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602508: Call_GetUpdateApplicationResourceLifecycle_602493;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Modifies lifecycle settings for an application.
  ## 
  let valid = call_602508.validator(path, query, header, formData, body)
  let scheme = call_602508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602508.url(scheme.get, call_602508.host, call_602508.base,
                         call_602508.route, valid.getOrDefault("path"))
  result = hook(call_602508, url, valid)

proc call*(call_602509: Call_GetUpdateApplicationResourceLifecycle_602493;
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
  var query_602510 = newJObject()
  add(query_602510, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  add(query_602510, "ApplicationName", newJString(ApplicationName))
  add(query_602510, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  add(query_602510, "Action", newJString(Action))
  add(query_602510, "Version", newJString(Version))
  result = call_602509.call(nil, query_602510, nil, nil, nil)

var getUpdateApplicationResourceLifecycle* = Call_GetUpdateApplicationResourceLifecycle_602493(
    name: "getUpdateApplicationResourceLifecycle", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationResourceLifecycle",
    validator: validate_GetUpdateApplicationResourceLifecycle_602494, base: "/",
    url: url_GetUpdateApplicationResourceLifecycle_602495,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateApplicationVersion_602548 = ref object of OpenApiRestCall_600427
proc url_PostUpdateApplicationVersion_602550(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostUpdateApplicationVersion_602549(path: JsonNode; query: JsonNode;
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
  var valid_602551 = query.getOrDefault("Action")
  valid_602551 = validateParameter(valid_602551, JString, required = true, default = newJString(
      "UpdateApplicationVersion"))
  if valid_602551 != nil:
    section.add "Action", valid_602551
  var valid_602552 = query.getOrDefault("Version")
  valid_602552 = validateParameter(valid_602552, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602552 != nil:
    section.add "Version", valid_602552
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602553 = header.getOrDefault("X-Amz-Date")
  valid_602553 = validateParameter(valid_602553, JString, required = false,
                                 default = nil)
  if valid_602553 != nil:
    section.add "X-Amz-Date", valid_602553
  var valid_602554 = header.getOrDefault("X-Amz-Security-Token")
  valid_602554 = validateParameter(valid_602554, JString, required = false,
                                 default = nil)
  if valid_602554 != nil:
    section.add "X-Amz-Security-Token", valid_602554
  var valid_602555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602555 = validateParameter(valid_602555, JString, required = false,
                                 default = nil)
  if valid_602555 != nil:
    section.add "X-Amz-Content-Sha256", valid_602555
  var valid_602556 = header.getOrDefault("X-Amz-Algorithm")
  valid_602556 = validateParameter(valid_602556, JString, required = false,
                                 default = nil)
  if valid_602556 != nil:
    section.add "X-Amz-Algorithm", valid_602556
  var valid_602557 = header.getOrDefault("X-Amz-Signature")
  valid_602557 = validateParameter(valid_602557, JString, required = false,
                                 default = nil)
  if valid_602557 != nil:
    section.add "X-Amz-Signature", valid_602557
  var valid_602558 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602558 = validateParameter(valid_602558, JString, required = false,
                                 default = nil)
  if valid_602558 != nil:
    section.add "X-Amz-SignedHeaders", valid_602558
  var valid_602559 = header.getOrDefault("X-Amz-Credential")
  valid_602559 = validateParameter(valid_602559, JString, required = false,
                                 default = nil)
  if valid_602559 != nil:
    section.add "X-Amz-Credential", valid_602559
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
  var valid_602560 = formData.getOrDefault("VersionLabel")
  valid_602560 = validateParameter(valid_602560, JString, required = true,
                                 default = nil)
  if valid_602560 != nil:
    section.add "VersionLabel", valid_602560
  var valid_602561 = formData.getOrDefault("ApplicationName")
  valid_602561 = validateParameter(valid_602561, JString, required = true,
                                 default = nil)
  if valid_602561 != nil:
    section.add "ApplicationName", valid_602561
  var valid_602562 = formData.getOrDefault("Description")
  valid_602562 = validateParameter(valid_602562, JString, required = false,
                                 default = nil)
  if valid_602562 != nil:
    section.add "Description", valid_602562
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602563: Call_PostUpdateApplicationVersion_602548; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified application version to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear properties, specify an empty string.</p> </note>
  ## 
  let valid = call_602563.validator(path, query, header, formData, body)
  let scheme = call_602563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602563.url(scheme.get, call_602563.host, call_602563.base,
                         call_602563.route, valid.getOrDefault("path"))
  result = hook(call_602563, url, valid)

proc call*(call_602564: Call_PostUpdateApplicationVersion_602548;
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
  var query_602565 = newJObject()
  var formData_602566 = newJObject()
  add(formData_602566, "VersionLabel", newJString(VersionLabel))
  add(query_602565, "Action", newJString(Action))
  add(formData_602566, "ApplicationName", newJString(ApplicationName))
  add(query_602565, "Version", newJString(Version))
  add(formData_602566, "Description", newJString(Description))
  result = call_602564.call(nil, query_602565, nil, formData_602566, nil)

var postUpdateApplicationVersion* = Call_PostUpdateApplicationVersion_602548(
    name: "postUpdateApplicationVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationVersion",
    validator: validate_PostUpdateApplicationVersion_602549, base: "/",
    url: url_PostUpdateApplicationVersion_602550,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateApplicationVersion_602530 = ref object of OpenApiRestCall_600427
proc url_GetUpdateApplicationVersion_602532(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUpdateApplicationVersion_602531(path: JsonNode; query: JsonNode;
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
  var valid_602533 = query.getOrDefault("VersionLabel")
  valid_602533 = validateParameter(valid_602533, JString, required = true,
                                 default = nil)
  if valid_602533 != nil:
    section.add "VersionLabel", valid_602533
  var valid_602534 = query.getOrDefault("ApplicationName")
  valid_602534 = validateParameter(valid_602534, JString, required = true,
                                 default = nil)
  if valid_602534 != nil:
    section.add "ApplicationName", valid_602534
  var valid_602535 = query.getOrDefault("Description")
  valid_602535 = validateParameter(valid_602535, JString, required = false,
                                 default = nil)
  if valid_602535 != nil:
    section.add "Description", valid_602535
  var valid_602536 = query.getOrDefault("Action")
  valid_602536 = validateParameter(valid_602536, JString, required = true, default = newJString(
      "UpdateApplicationVersion"))
  if valid_602536 != nil:
    section.add "Action", valid_602536
  var valid_602537 = query.getOrDefault("Version")
  valid_602537 = validateParameter(valid_602537, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602537 != nil:
    section.add "Version", valid_602537
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602538 = header.getOrDefault("X-Amz-Date")
  valid_602538 = validateParameter(valid_602538, JString, required = false,
                                 default = nil)
  if valid_602538 != nil:
    section.add "X-Amz-Date", valid_602538
  var valid_602539 = header.getOrDefault("X-Amz-Security-Token")
  valid_602539 = validateParameter(valid_602539, JString, required = false,
                                 default = nil)
  if valid_602539 != nil:
    section.add "X-Amz-Security-Token", valid_602539
  var valid_602540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602540 = validateParameter(valid_602540, JString, required = false,
                                 default = nil)
  if valid_602540 != nil:
    section.add "X-Amz-Content-Sha256", valid_602540
  var valid_602541 = header.getOrDefault("X-Amz-Algorithm")
  valid_602541 = validateParameter(valid_602541, JString, required = false,
                                 default = nil)
  if valid_602541 != nil:
    section.add "X-Amz-Algorithm", valid_602541
  var valid_602542 = header.getOrDefault("X-Amz-Signature")
  valid_602542 = validateParameter(valid_602542, JString, required = false,
                                 default = nil)
  if valid_602542 != nil:
    section.add "X-Amz-Signature", valid_602542
  var valid_602543 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602543 = validateParameter(valid_602543, JString, required = false,
                                 default = nil)
  if valid_602543 != nil:
    section.add "X-Amz-SignedHeaders", valid_602543
  var valid_602544 = header.getOrDefault("X-Amz-Credential")
  valid_602544 = validateParameter(valid_602544, JString, required = false,
                                 default = nil)
  if valid_602544 != nil:
    section.add "X-Amz-Credential", valid_602544
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602545: Call_GetUpdateApplicationVersion_602530; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified application version to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear properties, specify an empty string.</p> </note>
  ## 
  let valid = call_602545.validator(path, query, header, formData, body)
  let scheme = call_602545.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602545.url(scheme.get, call_602545.host, call_602545.base,
                         call_602545.route, valid.getOrDefault("path"))
  result = hook(call_602545, url, valid)

proc call*(call_602546: Call_GetUpdateApplicationVersion_602530;
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
  var query_602547 = newJObject()
  add(query_602547, "VersionLabel", newJString(VersionLabel))
  add(query_602547, "ApplicationName", newJString(ApplicationName))
  add(query_602547, "Description", newJString(Description))
  add(query_602547, "Action", newJString(Action))
  add(query_602547, "Version", newJString(Version))
  result = call_602546.call(nil, query_602547, nil, nil, nil)

var getUpdateApplicationVersion* = Call_GetUpdateApplicationVersion_602530(
    name: "getUpdateApplicationVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationVersion",
    validator: validate_GetUpdateApplicationVersion_602531, base: "/",
    url: url_GetUpdateApplicationVersion_602532,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateConfigurationTemplate_602587 = ref object of OpenApiRestCall_600427
proc url_PostUpdateConfigurationTemplate_602589(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostUpdateConfigurationTemplate_602588(path: JsonNode;
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
  var valid_602590 = query.getOrDefault("Action")
  valid_602590 = validateParameter(valid_602590, JString, required = true, default = newJString(
      "UpdateConfigurationTemplate"))
  if valid_602590 != nil:
    section.add "Action", valid_602590
  var valid_602591 = query.getOrDefault("Version")
  valid_602591 = validateParameter(valid_602591, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602591 != nil:
    section.add "Version", valid_602591
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602592 = header.getOrDefault("X-Amz-Date")
  valid_602592 = validateParameter(valid_602592, JString, required = false,
                                 default = nil)
  if valid_602592 != nil:
    section.add "X-Amz-Date", valid_602592
  var valid_602593 = header.getOrDefault("X-Amz-Security-Token")
  valid_602593 = validateParameter(valid_602593, JString, required = false,
                                 default = nil)
  if valid_602593 != nil:
    section.add "X-Amz-Security-Token", valid_602593
  var valid_602594 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602594 = validateParameter(valid_602594, JString, required = false,
                                 default = nil)
  if valid_602594 != nil:
    section.add "X-Amz-Content-Sha256", valid_602594
  var valid_602595 = header.getOrDefault("X-Amz-Algorithm")
  valid_602595 = validateParameter(valid_602595, JString, required = false,
                                 default = nil)
  if valid_602595 != nil:
    section.add "X-Amz-Algorithm", valid_602595
  var valid_602596 = header.getOrDefault("X-Amz-Signature")
  valid_602596 = validateParameter(valid_602596, JString, required = false,
                                 default = nil)
  if valid_602596 != nil:
    section.add "X-Amz-Signature", valid_602596
  var valid_602597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602597 = validateParameter(valid_602597, JString, required = false,
                                 default = nil)
  if valid_602597 != nil:
    section.add "X-Amz-SignedHeaders", valid_602597
  var valid_602598 = header.getOrDefault("X-Amz-Credential")
  valid_602598 = validateParameter(valid_602598, JString, required = false,
                                 default = nil)
  if valid_602598 != nil:
    section.add "X-Amz-Credential", valid_602598
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
  var valid_602599 = formData.getOrDefault("OptionsToRemove")
  valid_602599 = validateParameter(valid_602599, JArray, required = false,
                                 default = nil)
  if valid_602599 != nil:
    section.add "OptionsToRemove", valid_602599
  var valid_602600 = formData.getOrDefault("OptionSettings")
  valid_602600 = validateParameter(valid_602600, JArray, required = false,
                                 default = nil)
  if valid_602600 != nil:
    section.add "OptionSettings", valid_602600
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_602601 = formData.getOrDefault("ApplicationName")
  valid_602601 = validateParameter(valid_602601, JString, required = true,
                                 default = nil)
  if valid_602601 != nil:
    section.add "ApplicationName", valid_602601
  var valid_602602 = formData.getOrDefault("TemplateName")
  valid_602602 = validateParameter(valid_602602, JString, required = true,
                                 default = nil)
  if valid_602602 != nil:
    section.add "TemplateName", valid_602602
  var valid_602603 = formData.getOrDefault("Description")
  valid_602603 = validateParameter(valid_602603, JString, required = false,
                                 default = nil)
  if valid_602603 != nil:
    section.add "Description", valid_602603
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602604: Call_PostUpdateConfigurationTemplate_602587;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Updates the specified configuration template to have the specified properties or configuration option values.</p> <note> <p>If a property (for example, <code>ApplicationName</code>) is not provided, its value remains unchanged. To clear such properties, specify an empty string.</p> </note> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> </ul>
  ## 
  let valid = call_602604.validator(path, query, header, formData, body)
  let scheme = call_602604.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602604.url(scheme.get, call_602604.host, call_602604.base,
                         call_602604.route, valid.getOrDefault("path"))
  result = hook(call_602604, url, valid)

proc call*(call_602605: Call_PostUpdateConfigurationTemplate_602587;
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
  var query_602606 = newJObject()
  var formData_602607 = newJObject()
  if OptionsToRemove != nil:
    formData_602607.add "OptionsToRemove", OptionsToRemove
  if OptionSettings != nil:
    formData_602607.add "OptionSettings", OptionSettings
  add(query_602606, "Action", newJString(Action))
  add(formData_602607, "ApplicationName", newJString(ApplicationName))
  add(formData_602607, "TemplateName", newJString(TemplateName))
  add(query_602606, "Version", newJString(Version))
  add(formData_602607, "Description", newJString(Description))
  result = call_602605.call(nil, query_602606, nil, formData_602607, nil)

var postUpdateConfigurationTemplate* = Call_PostUpdateConfigurationTemplate_602587(
    name: "postUpdateConfigurationTemplate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateConfigurationTemplate",
    validator: validate_PostUpdateConfigurationTemplate_602588, base: "/",
    url: url_PostUpdateConfigurationTemplate_602589,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateConfigurationTemplate_602567 = ref object of OpenApiRestCall_600427
proc url_GetUpdateConfigurationTemplate_602569(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUpdateConfigurationTemplate_602568(path: JsonNode;
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
  var valid_602570 = query.getOrDefault("ApplicationName")
  valid_602570 = validateParameter(valid_602570, JString, required = true,
                                 default = nil)
  if valid_602570 != nil:
    section.add "ApplicationName", valid_602570
  var valid_602571 = query.getOrDefault("Description")
  valid_602571 = validateParameter(valid_602571, JString, required = false,
                                 default = nil)
  if valid_602571 != nil:
    section.add "Description", valid_602571
  var valid_602572 = query.getOrDefault("OptionsToRemove")
  valid_602572 = validateParameter(valid_602572, JArray, required = false,
                                 default = nil)
  if valid_602572 != nil:
    section.add "OptionsToRemove", valid_602572
  var valid_602573 = query.getOrDefault("Action")
  valid_602573 = validateParameter(valid_602573, JString, required = true, default = newJString(
      "UpdateConfigurationTemplate"))
  if valid_602573 != nil:
    section.add "Action", valid_602573
  var valid_602574 = query.getOrDefault("TemplateName")
  valid_602574 = validateParameter(valid_602574, JString, required = true,
                                 default = nil)
  if valid_602574 != nil:
    section.add "TemplateName", valid_602574
  var valid_602575 = query.getOrDefault("OptionSettings")
  valid_602575 = validateParameter(valid_602575, JArray, required = false,
                                 default = nil)
  if valid_602575 != nil:
    section.add "OptionSettings", valid_602575
  var valid_602576 = query.getOrDefault("Version")
  valid_602576 = validateParameter(valid_602576, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602576 != nil:
    section.add "Version", valid_602576
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602577 = header.getOrDefault("X-Amz-Date")
  valid_602577 = validateParameter(valid_602577, JString, required = false,
                                 default = nil)
  if valid_602577 != nil:
    section.add "X-Amz-Date", valid_602577
  var valid_602578 = header.getOrDefault("X-Amz-Security-Token")
  valid_602578 = validateParameter(valid_602578, JString, required = false,
                                 default = nil)
  if valid_602578 != nil:
    section.add "X-Amz-Security-Token", valid_602578
  var valid_602579 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602579 = validateParameter(valid_602579, JString, required = false,
                                 default = nil)
  if valid_602579 != nil:
    section.add "X-Amz-Content-Sha256", valid_602579
  var valid_602580 = header.getOrDefault("X-Amz-Algorithm")
  valid_602580 = validateParameter(valid_602580, JString, required = false,
                                 default = nil)
  if valid_602580 != nil:
    section.add "X-Amz-Algorithm", valid_602580
  var valid_602581 = header.getOrDefault("X-Amz-Signature")
  valid_602581 = validateParameter(valid_602581, JString, required = false,
                                 default = nil)
  if valid_602581 != nil:
    section.add "X-Amz-Signature", valid_602581
  var valid_602582 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602582 = validateParameter(valid_602582, JString, required = false,
                                 default = nil)
  if valid_602582 != nil:
    section.add "X-Amz-SignedHeaders", valid_602582
  var valid_602583 = header.getOrDefault("X-Amz-Credential")
  valid_602583 = validateParameter(valid_602583, JString, required = false,
                                 default = nil)
  if valid_602583 != nil:
    section.add "X-Amz-Credential", valid_602583
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602584: Call_GetUpdateConfigurationTemplate_602567; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified configuration template to have the specified properties or configuration option values.</p> <note> <p>If a property (for example, <code>ApplicationName</code>) is not provided, its value remains unchanged. To clear such properties, specify an empty string.</p> </note> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> </ul>
  ## 
  let valid = call_602584.validator(path, query, header, formData, body)
  let scheme = call_602584.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602584.url(scheme.get, call_602584.host, call_602584.base,
                         call_602584.route, valid.getOrDefault("path"))
  result = hook(call_602584, url, valid)

proc call*(call_602585: Call_GetUpdateConfigurationTemplate_602567;
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
  var query_602586 = newJObject()
  add(query_602586, "ApplicationName", newJString(ApplicationName))
  add(query_602586, "Description", newJString(Description))
  if OptionsToRemove != nil:
    query_602586.add "OptionsToRemove", OptionsToRemove
  add(query_602586, "Action", newJString(Action))
  add(query_602586, "TemplateName", newJString(TemplateName))
  if OptionSettings != nil:
    query_602586.add "OptionSettings", OptionSettings
  add(query_602586, "Version", newJString(Version))
  result = call_602585.call(nil, query_602586, nil, nil, nil)

var getUpdateConfigurationTemplate* = Call_GetUpdateConfigurationTemplate_602567(
    name: "getUpdateConfigurationTemplate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateConfigurationTemplate",
    validator: validate_GetUpdateConfigurationTemplate_602568, base: "/",
    url: url_GetUpdateConfigurationTemplate_602569,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateEnvironment_602637 = ref object of OpenApiRestCall_600427
proc url_PostUpdateEnvironment_602639(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostUpdateEnvironment_602638(path: JsonNode; query: JsonNode;
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
  var valid_602640 = query.getOrDefault("Action")
  valid_602640 = validateParameter(valid_602640, JString, required = true,
                                 default = newJString("UpdateEnvironment"))
  if valid_602640 != nil:
    section.add "Action", valid_602640
  var valid_602641 = query.getOrDefault("Version")
  valid_602641 = validateParameter(valid_602641, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602641 != nil:
    section.add "Version", valid_602641
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602642 = header.getOrDefault("X-Amz-Date")
  valid_602642 = validateParameter(valid_602642, JString, required = false,
                                 default = nil)
  if valid_602642 != nil:
    section.add "X-Amz-Date", valid_602642
  var valid_602643 = header.getOrDefault("X-Amz-Security-Token")
  valid_602643 = validateParameter(valid_602643, JString, required = false,
                                 default = nil)
  if valid_602643 != nil:
    section.add "X-Amz-Security-Token", valid_602643
  var valid_602644 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602644 = validateParameter(valid_602644, JString, required = false,
                                 default = nil)
  if valid_602644 != nil:
    section.add "X-Amz-Content-Sha256", valid_602644
  var valid_602645 = header.getOrDefault("X-Amz-Algorithm")
  valid_602645 = validateParameter(valid_602645, JString, required = false,
                                 default = nil)
  if valid_602645 != nil:
    section.add "X-Amz-Algorithm", valid_602645
  var valid_602646 = header.getOrDefault("X-Amz-Signature")
  valid_602646 = validateParameter(valid_602646, JString, required = false,
                                 default = nil)
  if valid_602646 != nil:
    section.add "X-Amz-Signature", valid_602646
  var valid_602647 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602647 = validateParameter(valid_602647, JString, required = false,
                                 default = nil)
  if valid_602647 != nil:
    section.add "X-Amz-SignedHeaders", valid_602647
  var valid_602648 = header.getOrDefault("X-Amz-Credential")
  valid_602648 = validateParameter(valid_602648, JString, required = false,
                                 default = nil)
  if valid_602648 != nil:
    section.add "X-Amz-Credential", valid_602648
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
  var valid_602649 = formData.getOrDefault("Tier.Name")
  valid_602649 = validateParameter(valid_602649, JString, required = false,
                                 default = nil)
  if valid_602649 != nil:
    section.add "Tier.Name", valid_602649
  var valid_602650 = formData.getOrDefault("OptionsToRemove")
  valid_602650 = validateParameter(valid_602650, JArray, required = false,
                                 default = nil)
  if valid_602650 != nil:
    section.add "OptionsToRemove", valid_602650
  var valid_602651 = formData.getOrDefault("VersionLabel")
  valid_602651 = validateParameter(valid_602651, JString, required = false,
                                 default = nil)
  if valid_602651 != nil:
    section.add "VersionLabel", valid_602651
  var valid_602652 = formData.getOrDefault("OptionSettings")
  valid_602652 = validateParameter(valid_602652, JArray, required = false,
                                 default = nil)
  if valid_602652 != nil:
    section.add "OptionSettings", valid_602652
  var valid_602653 = formData.getOrDefault("GroupName")
  valid_602653 = validateParameter(valid_602653, JString, required = false,
                                 default = nil)
  if valid_602653 != nil:
    section.add "GroupName", valid_602653
  var valid_602654 = formData.getOrDefault("SolutionStackName")
  valid_602654 = validateParameter(valid_602654, JString, required = false,
                                 default = nil)
  if valid_602654 != nil:
    section.add "SolutionStackName", valid_602654
  var valid_602655 = formData.getOrDefault("EnvironmentId")
  valid_602655 = validateParameter(valid_602655, JString, required = false,
                                 default = nil)
  if valid_602655 != nil:
    section.add "EnvironmentId", valid_602655
  var valid_602656 = formData.getOrDefault("EnvironmentName")
  valid_602656 = validateParameter(valid_602656, JString, required = false,
                                 default = nil)
  if valid_602656 != nil:
    section.add "EnvironmentName", valid_602656
  var valid_602657 = formData.getOrDefault("Tier.Type")
  valid_602657 = validateParameter(valid_602657, JString, required = false,
                                 default = nil)
  if valid_602657 != nil:
    section.add "Tier.Type", valid_602657
  var valid_602658 = formData.getOrDefault("ApplicationName")
  valid_602658 = validateParameter(valid_602658, JString, required = false,
                                 default = nil)
  if valid_602658 != nil:
    section.add "ApplicationName", valid_602658
  var valid_602659 = formData.getOrDefault("PlatformArn")
  valid_602659 = validateParameter(valid_602659, JString, required = false,
                                 default = nil)
  if valid_602659 != nil:
    section.add "PlatformArn", valid_602659
  var valid_602660 = formData.getOrDefault("TemplateName")
  valid_602660 = validateParameter(valid_602660, JString, required = false,
                                 default = nil)
  if valid_602660 != nil:
    section.add "TemplateName", valid_602660
  var valid_602661 = formData.getOrDefault("Description")
  valid_602661 = validateParameter(valid_602661, JString, required = false,
                                 default = nil)
  if valid_602661 != nil:
    section.add "Description", valid_602661
  var valid_602662 = formData.getOrDefault("Tier.Version")
  valid_602662 = validateParameter(valid_602662, JString, required = false,
                                 default = nil)
  if valid_602662 != nil:
    section.add "Tier.Version", valid_602662
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602663: Call_PostUpdateEnvironment_602637; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the environment description, deploys a new application version, updates the configuration settings to an entirely new configuration template, or updates select configuration option values in the running environment.</p> <p> Attempting to update both the release and configuration is not allowed and AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. </p> <p> When updating the configuration settings to a new template or individual settings, a draft configuration is created and <a>DescribeConfigurationSettings</a> for this environment returns two setting descriptions with different <code>DeploymentStatus</code> values. </p>
  ## 
  let valid = call_602663.validator(path, query, header, formData, body)
  let scheme = call_602663.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602663.url(scheme.get, call_602663.host, call_602663.base,
                         call_602663.route, valid.getOrDefault("path"))
  result = hook(call_602663, url, valid)

proc call*(call_602664: Call_PostUpdateEnvironment_602637; TierName: string = "";
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
  var query_602665 = newJObject()
  var formData_602666 = newJObject()
  add(formData_602666, "Tier.Name", newJString(TierName))
  if OptionsToRemove != nil:
    formData_602666.add "OptionsToRemove", OptionsToRemove
  add(formData_602666, "VersionLabel", newJString(VersionLabel))
  if OptionSettings != nil:
    formData_602666.add "OptionSettings", OptionSettings
  add(formData_602666, "GroupName", newJString(GroupName))
  add(formData_602666, "SolutionStackName", newJString(SolutionStackName))
  add(formData_602666, "EnvironmentId", newJString(EnvironmentId))
  add(formData_602666, "EnvironmentName", newJString(EnvironmentName))
  add(formData_602666, "Tier.Type", newJString(TierType))
  add(query_602665, "Action", newJString(Action))
  add(formData_602666, "ApplicationName", newJString(ApplicationName))
  add(formData_602666, "PlatformArn", newJString(PlatformArn))
  add(formData_602666, "TemplateName", newJString(TemplateName))
  add(query_602665, "Version", newJString(Version))
  add(formData_602666, "Description", newJString(Description))
  add(formData_602666, "Tier.Version", newJString(TierVersion))
  result = call_602664.call(nil, query_602665, nil, formData_602666, nil)

var postUpdateEnvironment* = Call_PostUpdateEnvironment_602637(
    name: "postUpdateEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateEnvironment",
    validator: validate_PostUpdateEnvironment_602638, base: "/",
    url: url_PostUpdateEnvironment_602639, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateEnvironment_602608 = ref object of OpenApiRestCall_600427
proc url_GetUpdateEnvironment_602610(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUpdateEnvironment_602609(path: JsonNode; query: JsonNode;
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
  var valid_602611 = query.getOrDefault("Tier.Name")
  valid_602611 = validateParameter(valid_602611, JString, required = false,
                                 default = nil)
  if valid_602611 != nil:
    section.add "Tier.Name", valid_602611
  var valid_602612 = query.getOrDefault("VersionLabel")
  valid_602612 = validateParameter(valid_602612, JString, required = false,
                                 default = nil)
  if valid_602612 != nil:
    section.add "VersionLabel", valid_602612
  var valid_602613 = query.getOrDefault("ApplicationName")
  valid_602613 = validateParameter(valid_602613, JString, required = false,
                                 default = nil)
  if valid_602613 != nil:
    section.add "ApplicationName", valid_602613
  var valid_602614 = query.getOrDefault("Description")
  valid_602614 = validateParameter(valid_602614, JString, required = false,
                                 default = nil)
  if valid_602614 != nil:
    section.add "Description", valid_602614
  var valid_602615 = query.getOrDefault("OptionsToRemove")
  valid_602615 = validateParameter(valid_602615, JArray, required = false,
                                 default = nil)
  if valid_602615 != nil:
    section.add "OptionsToRemove", valid_602615
  var valid_602616 = query.getOrDefault("PlatformArn")
  valid_602616 = validateParameter(valid_602616, JString, required = false,
                                 default = nil)
  if valid_602616 != nil:
    section.add "PlatformArn", valid_602616
  var valid_602617 = query.getOrDefault("EnvironmentName")
  valid_602617 = validateParameter(valid_602617, JString, required = false,
                                 default = nil)
  if valid_602617 != nil:
    section.add "EnvironmentName", valid_602617
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602618 = query.getOrDefault("Action")
  valid_602618 = validateParameter(valid_602618, JString, required = true,
                                 default = newJString("UpdateEnvironment"))
  if valid_602618 != nil:
    section.add "Action", valid_602618
  var valid_602619 = query.getOrDefault("EnvironmentId")
  valid_602619 = validateParameter(valid_602619, JString, required = false,
                                 default = nil)
  if valid_602619 != nil:
    section.add "EnvironmentId", valid_602619
  var valid_602620 = query.getOrDefault("Tier.Version")
  valid_602620 = validateParameter(valid_602620, JString, required = false,
                                 default = nil)
  if valid_602620 != nil:
    section.add "Tier.Version", valid_602620
  var valid_602621 = query.getOrDefault("SolutionStackName")
  valid_602621 = validateParameter(valid_602621, JString, required = false,
                                 default = nil)
  if valid_602621 != nil:
    section.add "SolutionStackName", valid_602621
  var valid_602622 = query.getOrDefault("TemplateName")
  valid_602622 = validateParameter(valid_602622, JString, required = false,
                                 default = nil)
  if valid_602622 != nil:
    section.add "TemplateName", valid_602622
  var valid_602623 = query.getOrDefault("GroupName")
  valid_602623 = validateParameter(valid_602623, JString, required = false,
                                 default = nil)
  if valid_602623 != nil:
    section.add "GroupName", valid_602623
  var valid_602624 = query.getOrDefault("OptionSettings")
  valid_602624 = validateParameter(valid_602624, JArray, required = false,
                                 default = nil)
  if valid_602624 != nil:
    section.add "OptionSettings", valid_602624
  var valid_602625 = query.getOrDefault("Tier.Type")
  valid_602625 = validateParameter(valid_602625, JString, required = false,
                                 default = nil)
  if valid_602625 != nil:
    section.add "Tier.Type", valid_602625
  var valid_602626 = query.getOrDefault("Version")
  valid_602626 = validateParameter(valid_602626, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602626 != nil:
    section.add "Version", valid_602626
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602627 = header.getOrDefault("X-Amz-Date")
  valid_602627 = validateParameter(valid_602627, JString, required = false,
                                 default = nil)
  if valid_602627 != nil:
    section.add "X-Amz-Date", valid_602627
  var valid_602628 = header.getOrDefault("X-Amz-Security-Token")
  valid_602628 = validateParameter(valid_602628, JString, required = false,
                                 default = nil)
  if valid_602628 != nil:
    section.add "X-Amz-Security-Token", valid_602628
  var valid_602629 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602629 = validateParameter(valid_602629, JString, required = false,
                                 default = nil)
  if valid_602629 != nil:
    section.add "X-Amz-Content-Sha256", valid_602629
  var valid_602630 = header.getOrDefault("X-Amz-Algorithm")
  valid_602630 = validateParameter(valid_602630, JString, required = false,
                                 default = nil)
  if valid_602630 != nil:
    section.add "X-Amz-Algorithm", valid_602630
  var valid_602631 = header.getOrDefault("X-Amz-Signature")
  valid_602631 = validateParameter(valid_602631, JString, required = false,
                                 default = nil)
  if valid_602631 != nil:
    section.add "X-Amz-Signature", valid_602631
  var valid_602632 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602632 = validateParameter(valid_602632, JString, required = false,
                                 default = nil)
  if valid_602632 != nil:
    section.add "X-Amz-SignedHeaders", valid_602632
  var valid_602633 = header.getOrDefault("X-Amz-Credential")
  valid_602633 = validateParameter(valid_602633, JString, required = false,
                                 default = nil)
  if valid_602633 != nil:
    section.add "X-Amz-Credential", valid_602633
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602634: Call_GetUpdateEnvironment_602608; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the environment description, deploys a new application version, updates the configuration settings to an entirely new configuration template, or updates select configuration option values in the running environment.</p> <p> Attempting to update both the release and configuration is not allowed and AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. </p> <p> When updating the configuration settings to a new template or individual settings, a draft configuration is created and <a>DescribeConfigurationSettings</a> for this environment returns two setting descriptions with different <code>DeploymentStatus</code> values. </p>
  ## 
  let valid = call_602634.validator(path, query, header, formData, body)
  let scheme = call_602634.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602634.url(scheme.get, call_602634.host, call_602634.base,
                         call_602634.route, valid.getOrDefault("path"))
  result = hook(call_602634, url, valid)

proc call*(call_602635: Call_GetUpdateEnvironment_602608; TierName: string = "";
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
  var query_602636 = newJObject()
  add(query_602636, "Tier.Name", newJString(TierName))
  add(query_602636, "VersionLabel", newJString(VersionLabel))
  add(query_602636, "ApplicationName", newJString(ApplicationName))
  add(query_602636, "Description", newJString(Description))
  if OptionsToRemove != nil:
    query_602636.add "OptionsToRemove", OptionsToRemove
  add(query_602636, "PlatformArn", newJString(PlatformArn))
  add(query_602636, "EnvironmentName", newJString(EnvironmentName))
  add(query_602636, "Action", newJString(Action))
  add(query_602636, "EnvironmentId", newJString(EnvironmentId))
  add(query_602636, "Tier.Version", newJString(TierVersion))
  add(query_602636, "SolutionStackName", newJString(SolutionStackName))
  add(query_602636, "TemplateName", newJString(TemplateName))
  add(query_602636, "GroupName", newJString(GroupName))
  if OptionSettings != nil:
    query_602636.add "OptionSettings", OptionSettings
  add(query_602636, "Tier.Type", newJString(TierType))
  add(query_602636, "Version", newJString(Version))
  result = call_602635.call(nil, query_602636, nil, nil, nil)

var getUpdateEnvironment* = Call_GetUpdateEnvironment_602608(
    name: "getUpdateEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateEnvironment",
    validator: validate_GetUpdateEnvironment_602609, base: "/",
    url: url_GetUpdateEnvironment_602610, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateTagsForResource_602685 = ref object of OpenApiRestCall_600427
proc url_PostUpdateTagsForResource_602687(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostUpdateTagsForResource_602686(path: JsonNode; query: JsonNode;
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
  var valid_602688 = query.getOrDefault("Action")
  valid_602688 = validateParameter(valid_602688, JString, required = true,
                                 default = newJString("UpdateTagsForResource"))
  if valid_602688 != nil:
    section.add "Action", valid_602688
  var valid_602689 = query.getOrDefault("Version")
  valid_602689 = validateParameter(valid_602689, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602689 != nil:
    section.add "Version", valid_602689
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602690 = header.getOrDefault("X-Amz-Date")
  valid_602690 = validateParameter(valid_602690, JString, required = false,
                                 default = nil)
  if valid_602690 != nil:
    section.add "X-Amz-Date", valid_602690
  var valid_602691 = header.getOrDefault("X-Amz-Security-Token")
  valid_602691 = validateParameter(valid_602691, JString, required = false,
                                 default = nil)
  if valid_602691 != nil:
    section.add "X-Amz-Security-Token", valid_602691
  var valid_602692 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602692 = validateParameter(valid_602692, JString, required = false,
                                 default = nil)
  if valid_602692 != nil:
    section.add "X-Amz-Content-Sha256", valid_602692
  var valid_602693 = header.getOrDefault("X-Amz-Algorithm")
  valid_602693 = validateParameter(valid_602693, JString, required = false,
                                 default = nil)
  if valid_602693 != nil:
    section.add "X-Amz-Algorithm", valid_602693
  var valid_602694 = header.getOrDefault("X-Amz-Signature")
  valid_602694 = validateParameter(valid_602694, JString, required = false,
                                 default = nil)
  if valid_602694 != nil:
    section.add "X-Amz-Signature", valid_602694
  var valid_602695 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602695 = validateParameter(valid_602695, JString, required = false,
                                 default = nil)
  if valid_602695 != nil:
    section.add "X-Amz-SignedHeaders", valid_602695
  var valid_602696 = header.getOrDefault("X-Amz-Credential")
  valid_602696 = validateParameter(valid_602696, JString, required = false,
                                 default = nil)
  if valid_602696 != nil:
    section.add "X-Amz-Credential", valid_602696
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagsToAdd: JArray
  ##            : <p>A list of tags to add or update.</p> <p>If a key of an existing tag is added, the tag's value is updated.</p>
  ##   TagsToRemove: JArray
  ##               : <p>A list of tag keys to remove.</p> <p>If a tag key doesn't exist, it is silently ignored.</p>
  ##   ResourceArn: JString (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce to be updated.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  section = newJObject()
  var valid_602697 = formData.getOrDefault("TagsToAdd")
  valid_602697 = validateParameter(valid_602697, JArray, required = false,
                                 default = nil)
  if valid_602697 != nil:
    section.add "TagsToAdd", valid_602697
  var valid_602698 = formData.getOrDefault("TagsToRemove")
  valid_602698 = validateParameter(valid_602698, JArray, required = false,
                                 default = nil)
  if valid_602698 != nil:
    section.add "TagsToRemove", valid_602698
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArn` field"
  var valid_602699 = formData.getOrDefault("ResourceArn")
  valid_602699 = validateParameter(valid_602699, JString, required = true,
                                 default = nil)
  if valid_602699 != nil:
    section.add "ResourceArn", valid_602699
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602700: Call_PostUpdateTagsForResource_602685; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Update the list of tags applied to an AWS Elastic Beanstalk resource. Two lists can be passed: <code>TagsToAdd</code> for tags to add or update, and <code>TagsToRemove</code>.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p> <p>If you create a custom IAM user policy to control permission to this operation, specify one of the following two virtual actions (or both) instead of the API operation name:</p> <dl> <dt>elasticbeanstalk:AddTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tags to add in the <code>TagsToAdd</code> parameter.</p> </dd> <dt>elasticbeanstalk:RemoveTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tag keys to remove in the <code>TagsToRemove</code> parameter.</p> </dd> </dl> <p>For details about creating a custom user policy, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/AWSHowTo.iam.managed-policies.html#AWSHowTo.iam.policies">Creating a Custom User Policy</a>.</p>
  ## 
  let valid = call_602700.validator(path, query, header, formData, body)
  let scheme = call_602700.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602700.url(scheme.get, call_602700.host, call_602700.base,
                         call_602700.route, valid.getOrDefault("path"))
  result = hook(call_602700, url, valid)

proc call*(call_602701: Call_PostUpdateTagsForResource_602685; ResourceArn: string;
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
  var query_602702 = newJObject()
  var formData_602703 = newJObject()
  if TagsToAdd != nil:
    formData_602703.add "TagsToAdd", TagsToAdd
  if TagsToRemove != nil:
    formData_602703.add "TagsToRemove", TagsToRemove
  add(query_602702, "Action", newJString(Action))
  add(formData_602703, "ResourceArn", newJString(ResourceArn))
  add(query_602702, "Version", newJString(Version))
  result = call_602701.call(nil, query_602702, nil, formData_602703, nil)

var postUpdateTagsForResource* = Call_PostUpdateTagsForResource_602685(
    name: "postUpdateTagsForResource", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateTagsForResource",
    validator: validate_PostUpdateTagsForResource_602686, base: "/",
    url: url_PostUpdateTagsForResource_602687,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateTagsForResource_602667 = ref object of OpenApiRestCall_600427
proc url_GetUpdateTagsForResource_602669(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUpdateTagsForResource_602668(path: JsonNode; query: JsonNode;
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
  var valid_602670 = query.getOrDefault("ResourceArn")
  valid_602670 = validateParameter(valid_602670, JString, required = true,
                                 default = nil)
  if valid_602670 != nil:
    section.add "ResourceArn", valid_602670
  var valid_602671 = query.getOrDefault("Action")
  valid_602671 = validateParameter(valid_602671, JString, required = true,
                                 default = newJString("UpdateTagsForResource"))
  if valid_602671 != nil:
    section.add "Action", valid_602671
  var valid_602672 = query.getOrDefault("TagsToAdd")
  valid_602672 = validateParameter(valid_602672, JArray, required = false,
                                 default = nil)
  if valid_602672 != nil:
    section.add "TagsToAdd", valid_602672
  var valid_602673 = query.getOrDefault("Version")
  valid_602673 = validateParameter(valid_602673, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602673 != nil:
    section.add "Version", valid_602673
  var valid_602674 = query.getOrDefault("TagsToRemove")
  valid_602674 = validateParameter(valid_602674, JArray, required = false,
                                 default = nil)
  if valid_602674 != nil:
    section.add "TagsToRemove", valid_602674
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602675 = header.getOrDefault("X-Amz-Date")
  valid_602675 = validateParameter(valid_602675, JString, required = false,
                                 default = nil)
  if valid_602675 != nil:
    section.add "X-Amz-Date", valid_602675
  var valid_602676 = header.getOrDefault("X-Amz-Security-Token")
  valid_602676 = validateParameter(valid_602676, JString, required = false,
                                 default = nil)
  if valid_602676 != nil:
    section.add "X-Amz-Security-Token", valid_602676
  var valid_602677 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602677 = validateParameter(valid_602677, JString, required = false,
                                 default = nil)
  if valid_602677 != nil:
    section.add "X-Amz-Content-Sha256", valid_602677
  var valid_602678 = header.getOrDefault("X-Amz-Algorithm")
  valid_602678 = validateParameter(valid_602678, JString, required = false,
                                 default = nil)
  if valid_602678 != nil:
    section.add "X-Amz-Algorithm", valid_602678
  var valid_602679 = header.getOrDefault("X-Amz-Signature")
  valid_602679 = validateParameter(valid_602679, JString, required = false,
                                 default = nil)
  if valid_602679 != nil:
    section.add "X-Amz-Signature", valid_602679
  var valid_602680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602680 = validateParameter(valid_602680, JString, required = false,
                                 default = nil)
  if valid_602680 != nil:
    section.add "X-Amz-SignedHeaders", valid_602680
  var valid_602681 = header.getOrDefault("X-Amz-Credential")
  valid_602681 = validateParameter(valid_602681, JString, required = false,
                                 default = nil)
  if valid_602681 != nil:
    section.add "X-Amz-Credential", valid_602681
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602682: Call_GetUpdateTagsForResource_602667; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Update the list of tags applied to an AWS Elastic Beanstalk resource. Two lists can be passed: <code>TagsToAdd</code> for tags to add or update, and <code>TagsToRemove</code>.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p> <p>If you create a custom IAM user policy to control permission to this operation, specify one of the following two virtual actions (or both) instead of the API operation name:</p> <dl> <dt>elasticbeanstalk:AddTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tags to add in the <code>TagsToAdd</code> parameter.</p> </dd> <dt>elasticbeanstalk:RemoveTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tag keys to remove in the <code>TagsToRemove</code> parameter.</p> </dd> </dl> <p>For details about creating a custom user policy, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/AWSHowTo.iam.managed-policies.html#AWSHowTo.iam.policies">Creating a Custom User Policy</a>.</p>
  ## 
  let valid = call_602682.validator(path, query, header, formData, body)
  let scheme = call_602682.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602682.url(scheme.get, call_602682.host, call_602682.base,
                         call_602682.route, valid.getOrDefault("path"))
  result = hook(call_602682, url, valid)

proc call*(call_602683: Call_GetUpdateTagsForResource_602667; ResourceArn: string;
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
  var query_602684 = newJObject()
  add(query_602684, "ResourceArn", newJString(ResourceArn))
  add(query_602684, "Action", newJString(Action))
  if TagsToAdd != nil:
    query_602684.add "TagsToAdd", TagsToAdd
  add(query_602684, "Version", newJString(Version))
  if TagsToRemove != nil:
    query_602684.add "TagsToRemove", TagsToRemove
  result = call_602683.call(nil, query_602684, nil, nil, nil)

var getUpdateTagsForResource* = Call_GetUpdateTagsForResource_602667(
    name: "getUpdateTagsForResource", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateTagsForResource",
    validator: validate_GetUpdateTagsForResource_602668, base: "/",
    url: url_GetUpdateTagsForResource_602669, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostValidateConfigurationSettings_602723 = ref object of OpenApiRestCall_600427
proc url_PostValidateConfigurationSettings_602725(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostValidateConfigurationSettings_602724(path: JsonNode;
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
  var valid_602726 = query.getOrDefault("Action")
  valid_602726 = validateParameter(valid_602726, JString, required = true, default = newJString(
      "ValidateConfigurationSettings"))
  if valid_602726 != nil:
    section.add "Action", valid_602726
  var valid_602727 = query.getOrDefault("Version")
  valid_602727 = validateParameter(valid_602727, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602727 != nil:
    section.add "Version", valid_602727
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602728 = header.getOrDefault("X-Amz-Date")
  valid_602728 = validateParameter(valid_602728, JString, required = false,
                                 default = nil)
  if valid_602728 != nil:
    section.add "X-Amz-Date", valid_602728
  var valid_602729 = header.getOrDefault("X-Amz-Security-Token")
  valid_602729 = validateParameter(valid_602729, JString, required = false,
                                 default = nil)
  if valid_602729 != nil:
    section.add "X-Amz-Security-Token", valid_602729
  var valid_602730 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602730 = validateParameter(valid_602730, JString, required = false,
                                 default = nil)
  if valid_602730 != nil:
    section.add "X-Amz-Content-Sha256", valid_602730
  var valid_602731 = header.getOrDefault("X-Amz-Algorithm")
  valid_602731 = validateParameter(valid_602731, JString, required = false,
                                 default = nil)
  if valid_602731 != nil:
    section.add "X-Amz-Algorithm", valid_602731
  var valid_602732 = header.getOrDefault("X-Amz-Signature")
  valid_602732 = validateParameter(valid_602732, JString, required = false,
                                 default = nil)
  if valid_602732 != nil:
    section.add "X-Amz-Signature", valid_602732
  var valid_602733 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602733 = validateParameter(valid_602733, JString, required = false,
                                 default = nil)
  if valid_602733 != nil:
    section.add "X-Amz-SignedHeaders", valid_602733
  var valid_602734 = header.getOrDefault("X-Amz-Credential")
  valid_602734 = validateParameter(valid_602734, JString, required = false,
                                 default = nil)
  if valid_602734 != nil:
    section.add "X-Amz-Credential", valid_602734
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
  var valid_602735 = formData.getOrDefault("OptionSettings")
  valid_602735 = validateParameter(valid_602735, JArray, required = true, default = nil)
  if valid_602735 != nil:
    section.add "OptionSettings", valid_602735
  var valid_602736 = formData.getOrDefault("EnvironmentName")
  valid_602736 = validateParameter(valid_602736, JString, required = false,
                                 default = nil)
  if valid_602736 != nil:
    section.add "EnvironmentName", valid_602736
  var valid_602737 = formData.getOrDefault("ApplicationName")
  valid_602737 = validateParameter(valid_602737, JString, required = true,
                                 default = nil)
  if valid_602737 != nil:
    section.add "ApplicationName", valid_602737
  var valid_602738 = formData.getOrDefault("TemplateName")
  valid_602738 = validateParameter(valid_602738, JString, required = false,
                                 default = nil)
  if valid_602738 != nil:
    section.add "TemplateName", valid_602738
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602739: Call_PostValidateConfigurationSettings_602723;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Takes a set of configuration settings and either a configuration template or environment, and determines whether those values are valid.</p> <p>This action returns a list of messages indicating any errors or warnings associated with the selection of option values.</p>
  ## 
  let valid = call_602739.validator(path, query, header, formData, body)
  let scheme = call_602739.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602739.url(scheme.get, call_602739.host, call_602739.base,
                         call_602739.route, valid.getOrDefault("path"))
  result = hook(call_602739, url, valid)

proc call*(call_602740: Call_PostValidateConfigurationSettings_602723;
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
  var query_602741 = newJObject()
  var formData_602742 = newJObject()
  if OptionSettings != nil:
    formData_602742.add "OptionSettings", OptionSettings
  add(formData_602742, "EnvironmentName", newJString(EnvironmentName))
  add(query_602741, "Action", newJString(Action))
  add(formData_602742, "ApplicationName", newJString(ApplicationName))
  add(formData_602742, "TemplateName", newJString(TemplateName))
  add(query_602741, "Version", newJString(Version))
  result = call_602740.call(nil, query_602741, nil, formData_602742, nil)

var postValidateConfigurationSettings* = Call_PostValidateConfigurationSettings_602723(
    name: "postValidateConfigurationSettings", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ValidateConfigurationSettings",
    validator: validate_PostValidateConfigurationSettings_602724, base: "/",
    url: url_PostValidateConfigurationSettings_602725,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetValidateConfigurationSettings_602704 = ref object of OpenApiRestCall_600427
proc url_GetValidateConfigurationSettings_602706(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetValidateConfigurationSettings_602705(path: JsonNode;
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
  var valid_602707 = query.getOrDefault("ApplicationName")
  valid_602707 = validateParameter(valid_602707, JString, required = true,
                                 default = nil)
  if valid_602707 != nil:
    section.add "ApplicationName", valid_602707
  var valid_602708 = query.getOrDefault("EnvironmentName")
  valid_602708 = validateParameter(valid_602708, JString, required = false,
                                 default = nil)
  if valid_602708 != nil:
    section.add "EnvironmentName", valid_602708
  var valid_602709 = query.getOrDefault("Action")
  valid_602709 = validateParameter(valid_602709, JString, required = true, default = newJString(
      "ValidateConfigurationSettings"))
  if valid_602709 != nil:
    section.add "Action", valid_602709
  var valid_602710 = query.getOrDefault("TemplateName")
  valid_602710 = validateParameter(valid_602710, JString, required = false,
                                 default = nil)
  if valid_602710 != nil:
    section.add "TemplateName", valid_602710
  var valid_602711 = query.getOrDefault("OptionSettings")
  valid_602711 = validateParameter(valid_602711, JArray, required = true, default = nil)
  if valid_602711 != nil:
    section.add "OptionSettings", valid_602711
  var valid_602712 = query.getOrDefault("Version")
  valid_602712 = validateParameter(valid_602712, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602712 != nil:
    section.add "Version", valid_602712
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602713 = header.getOrDefault("X-Amz-Date")
  valid_602713 = validateParameter(valid_602713, JString, required = false,
                                 default = nil)
  if valid_602713 != nil:
    section.add "X-Amz-Date", valid_602713
  var valid_602714 = header.getOrDefault("X-Amz-Security-Token")
  valid_602714 = validateParameter(valid_602714, JString, required = false,
                                 default = nil)
  if valid_602714 != nil:
    section.add "X-Amz-Security-Token", valid_602714
  var valid_602715 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602715 = validateParameter(valid_602715, JString, required = false,
                                 default = nil)
  if valid_602715 != nil:
    section.add "X-Amz-Content-Sha256", valid_602715
  var valid_602716 = header.getOrDefault("X-Amz-Algorithm")
  valid_602716 = validateParameter(valid_602716, JString, required = false,
                                 default = nil)
  if valid_602716 != nil:
    section.add "X-Amz-Algorithm", valid_602716
  var valid_602717 = header.getOrDefault("X-Amz-Signature")
  valid_602717 = validateParameter(valid_602717, JString, required = false,
                                 default = nil)
  if valid_602717 != nil:
    section.add "X-Amz-Signature", valid_602717
  var valid_602718 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602718 = validateParameter(valid_602718, JString, required = false,
                                 default = nil)
  if valid_602718 != nil:
    section.add "X-Amz-SignedHeaders", valid_602718
  var valid_602719 = header.getOrDefault("X-Amz-Credential")
  valid_602719 = validateParameter(valid_602719, JString, required = false,
                                 default = nil)
  if valid_602719 != nil:
    section.add "X-Amz-Credential", valid_602719
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602720: Call_GetValidateConfigurationSettings_602704;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Takes a set of configuration settings and either a configuration template or environment, and determines whether those values are valid.</p> <p>This action returns a list of messages indicating any errors or warnings associated with the selection of option values.</p>
  ## 
  let valid = call_602720.validator(path, query, header, formData, body)
  let scheme = call_602720.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602720.url(scheme.get, call_602720.host, call_602720.base,
                         call_602720.route, valid.getOrDefault("path"))
  result = hook(call_602720, url, valid)

proc call*(call_602721: Call_GetValidateConfigurationSettings_602704;
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
  var query_602722 = newJObject()
  add(query_602722, "ApplicationName", newJString(ApplicationName))
  add(query_602722, "EnvironmentName", newJString(EnvironmentName))
  add(query_602722, "Action", newJString(Action))
  add(query_602722, "TemplateName", newJString(TemplateName))
  if OptionSettings != nil:
    query_602722.add "OptionSettings", OptionSettings
  add(query_602722, "Version", newJString(Version))
  result = call_602721.call(nil, query_602722, nil, nil, nil)

var getValidateConfigurationSettings* = Call_GetValidateConfigurationSettings_602704(
    name: "getValidateConfigurationSettings", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ValidateConfigurationSettings",
    validator: validate_GetValidateConfigurationSettings_602705, base: "/",
    url: url_GetValidateConfigurationSettings_602706,
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


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

  OpenApiRestCall_772598 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_772598](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_772598): Option[Scheme] {.used.} =
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
  Call_PostAbortEnvironmentUpdate_773206 = ref object of OpenApiRestCall_772598
proc url_PostAbortEnvironmentUpdate_773208(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostAbortEnvironmentUpdate_773207(path: JsonNode; query: JsonNode;
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
  var valid_773209 = query.getOrDefault("Action")
  valid_773209 = validateParameter(valid_773209, JString, required = true,
                                 default = newJString("AbortEnvironmentUpdate"))
  if valid_773209 != nil:
    section.add "Action", valid_773209
  var valid_773210 = query.getOrDefault("Version")
  valid_773210 = validateParameter(valid_773210, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_773210 != nil:
    section.add "Version", valid_773210
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773211 = header.getOrDefault("X-Amz-Date")
  valid_773211 = validateParameter(valid_773211, JString, required = false,
                                 default = nil)
  if valid_773211 != nil:
    section.add "X-Amz-Date", valid_773211
  var valid_773212 = header.getOrDefault("X-Amz-Security-Token")
  valid_773212 = validateParameter(valid_773212, JString, required = false,
                                 default = nil)
  if valid_773212 != nil:
    section.add "X-Amz-Security-Token", valid_773212
  var valid_773213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773213 = validateParameter(valid_773213, JString, required = false,
                                 default = nil)
  if valid_773213 != nil:
    section.add "X-Amz-Content-Sha256", valid_773213
  var valid_773214 = header.getOrDefault("X-Amz-Algorithm")
  valid_773214 = validateParameter(valid_773214, JString, required = false,
                                 default = nil)
  if valid_773214 != nil:
    section.add "X-Amz-Algorithm", valid_773214
  var valid_773215 = header.getOrDefault("X-Amz-Signature")
  valid_773215 = validateParameter(valid_773215, JString, required = false,
                                 default = nil)
  if valid_773215 != nil:
    section.add "X-Amz-Signature", valid_773215
  var valid_773216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773216 = validateParameter(valid_773216, JString, required = false,
                                 default = nil)
  if valid_773216 != nil:
    section.add "X-Amz-SignedHeaders", valid_773216
  var valid_773217 = header.getOrDefault("X-Amz-Credential")
  valid_773217 = validateParameter(valid_773217, JString, required = false,
                                 default = nil)
  if valid_773217 != nil:
    section.add "X-Amz-Credential", valid_773217
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentId: JString
  ##                : This specifies the ID of the environment with the in-progress update that you want to cancel.
  ##   EnvironmentName: JString
  ##                  : This specifies the name of the environment with the in-progress update that you want to cancel.
  section = newJObject()
  var valid_773218 = formData.getOrDefault("EnvironmentId")
  valid_773218 = validateParameter(valid_773218, JString, required = false,
                                 default = nil)
  if valid_773218 != nil:
    section.add "EnvironmentId", valid_773218
  var valid_773219 = formData.getOrDefault("EnvironmentName")
  valid_773219 = validateParameter(valid_773219, JString, required = false,
                                 default = nil)
  if valid_773219 != nil:
    section.add "EnvironmentName", valid_773219
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773220: Call_PostAbortEnvironmentUpdate_773206; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels in-progress environment configuration update or application version deployment.
  ## 
  let valid = call_773220.validator(path, query, header, formData, body)
  let scheme = call_773220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773220.url(scheme.get, call_773220.host, call_773220.base,
                         call_773220.route, valid.getOrDefault("path"))
  result = hook(call_773220, url, valid)

proc call*(call_773221: Call_PostAbortEnvironmentUpdate_773206;
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
  var query_773222 = newJObject()
  var formData_773223 = newJObject()
  add(formData_773223, "EnvironmentId", newJString(EnvironmentId))
  add(formData_773223, "EnvironmentName", newJString(EnvironmentName))
  add(query_773222, "Action", newJString(Action))
  add(query_773222, "Version", newJString(Version))
  result = call_773221.call(nil, query_773222, nil, formData_773223, nil)

var postAbortEnvironmentUpdate* = Call_PostAbortEnvironmentUpdate_773206(
    name: "postAbortEnvironmentUpdate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=AbortEnvironmentUpdate",
    validator: validate_PostAbortEnvironmentUpdate_773207, base: "/",
    url: url_PostAbortEnvironmentUpdate_773208,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAbortEnvironmentUpdate_772934 = ref object of OpenApiRestCall_772598
proc url_GetAbortEnvironmentUpdate_772936(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAbortEnvironmentUpdate_772935(path: JsonNode; query: JsonNode;
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
  var valid_773048 = query.getOrDefault("EnvironmentName")
  valid_773048 = validateParameter(valid_773048, JString, required = false,
                                 default = nil)
  if valid_773048 != nil:
    section.add "EnvironmentName", valid_773048
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773062 = query.getOrDefault("Action")
  valid_773062 = validateParameter(valid_773062, JString, required = true,
                                 default = newJString("AbortEnvironmentUpdate"))
  if valid_773062 != nil:
    section.add "Action", valid_773062
  var valid_773063 = query.getOrDefault("EnvironmentId")
  valid_773063 = validateParameter(valid_773063, JString, required = false,
                                 default = nil)
  if valid_773063 != nil:
    section.add "EnvironmentId", valid_773063
  var valid_773064 = query.getOrDefault("Version")
  valid_773064 = validateParameter(valid_773064, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_773064 != nil:
    section.add "Version", valid_773064
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773065 = header.getOrDefault("X-Amz-Date")
  valid_773065 = validateParameter(valid_773065, JString, required = false,
                                 default = nil)
  if valid_773065 != nil:
    section.add "X-Amz-Date", valid_773065
  var valid_773066 = header.getOrDefault("X-Amz-Security-Token")
  valid_773066 = validateParameter(valid_773066, JString, required = false,
                                 default = nil)
  if valid_773066 != nil:
    section.add "X-Amz-Security-Token", valid_773066
  var valid_773067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773067 = validateParameter(valid_773067, JString, required = false,
                                 default = nil)
  if valid_773067 != nil:
    section.add "X-Amz-Content-Sha256", valid_773067
  var valid_773068 = header.getOrDefault("X-Amz-Algorithm")
  valid_773068 = validateParameter(valid_773068, JString, required = false,
                                 default = nil)
  if valid_773068 != nil:
    section.add "X-Amz-Algorithm", valid_773068
  var valid_773069 = header.getOrDefault("X-Amz-Signature")
  valid_773069 = validateParameter(valid_773069, JString, required = false,
                                 default = nil)
  if valid_773069 != nil:
    section.add "X-Amz-Signature", valid_773069
  var valid_773070 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773070 = validateParameter(valid_773070, JString, required = false,
                                 default = nil)
  if valid_773070 != nil:
    section.add "X-Amz-SignedHeaders", valid_773070
  var valid_773071 = header.getOrDefault("X-Amz-Credential")
  valid_773071 = validateParameter(valid_773071, JString, required = false,
                                 default = nil)
  if valid_773071 != nil:
    section.add "X-Amz-Credential", valid_773071
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773094: Call_GetAbortEnvironmentUpdate_772934; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels in-progress environment configuration update or application version deployment.
  ## 
  let valid = call_773094.validator(path, query, header, formData, body)
  let scheme = call_773094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773094.url(scheme.get, call_773094.host, call_773094.base,
                         call_773094.route, valid.getOrDefault("path"))
  result = hook(call_773094, url, valid)

proc call*(call_773165: Call_GetAbortEnvironmentUpdate_772934;
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
  var query_773166 = newJObject()
  add(query_773166, "EnvironmentName", newJString(EnvironmentName))
  add(query_773166, "Action", newJString(Action))
  add(query_773166, "EnvironmentId", newJString(EnvironmentId))
  add(query_773166, "Version", newJString(Version))
  result = call_773165.call(nil, query_773166, nil, nil, nil)

var getAbortEnvironmentUpdate* = Call_GetAbortEnvironmentUpdate_772934(
    name: "getAbortEnvironmentUpdate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=AbortEnvironmentUpdate",
    validator: validate_GetAbortEnvironmentUpdate_772935, base: "/",
    url: url_GetAbortEnvironmentUpdate_772936,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostApplyEnvironmentManagedAction_773242 = ref object of OpenApiRestCall_772598
proc url_PostApplyEnvironmentManagedAction_773244(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostApplyEnvironmentManagedAction_773243(path: JsonNode;
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
  var valid_773245 = query.getOrDefault("Action")
  valid_773245 = validateParameter(valid_773245, JString, required = true, default = newJString(
      "ApplyEnvironmentManagedAction"))
  if valid_773245 != nil:
    section.add "Action", valid_773245
  var valid_773246 = query.getOrDefault("Version")
  valid_773246 = validateParameter(valid_773246, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_773246 != nil:
    section.add "Version", valid_773246
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773247 = header.getOrDefault("X-Amz-Date")
  valid_773247 = validateParameter(valid_773247, JString, required = false,
                                 default = nil)
  if valid_773247 != nil:
    section.add "X-Amz-Date", valid_773247
  var valid_773248 = header.getOrDefault("X-Amz-Security-Token")
  valid_773248 = validateParameter(valid_773248, JString, required = false,
                                 default = nil)
  if valid_773248 != nil:
    section.add "X-Amz-Security-Token", valid_773248
  var valid_773249 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773249 = validateParameter(valid_773249, JString, required = false,
                                 default = nil)
  if valid_773249 != nil:
    section.add "X-Amz-Content-Sha256", valid_773249
  var valid_773250 = header.getOrDefault("X-Amz-Algorithm")
  valid_773250 = validateParameter(valid_773250, JString, required = false,
                                 default = nil)
  if valid_773250 != nil:
    section.add "X-Amz-Algorithm", valid_773250
  var valid_773251 = header.getOrDefault("X-Amz-Signature")
  valid_773251 = validateParameter(valid_773251, JString, required = false,
                                 default = nil)
  if valid_773251 != nil:
    section.add "X-Amz-Signature", valid_773251
  var valid_773252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773252 = validateParameter(valid_773252, JString, required = false,
                                 default = nil)
  if valid_773252 != nil:
    section.add "X-Amz-SignedHeaders", valid_773252
  var valid_773253 = header.getOrDefault("X-Amz-Credential")
  valid_773253 = validateParameter(valid_773253, JString, required = false,
                                 default = nil)
  if valid_773253 != nil:
    section.add "X-Amz-Credential", valid_773253
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentId: JString
  ##                : The environment ID of the target environment.
  ##   EnvironmentName: JString
  ##                  : The name of the target environment.
  ##   ActionId: JString (required)
  ##           : The action ID of the scheduled managed action to execute.
  section = newJObject()
  var valid_773254 = formData.getOrDefault("EnvironmentId")
  valid_773254 = validateParameter(valid_773254, JString, required = false,
                                 default = nil)
  if valid_773254 != nil:
    section.add "EnvironmentId", valid_773254
  var valid_773255 = formData.getOrDefault("EnvironmentName")
  valid_773255 = validateParameter(valid_773255, JString, required = false,
                                 default = nil)
  if valid_773255 != nil:
    section.add "EnvironmentName", valid_773255
  assert formData != nil,
        "formData argument is necessary due to required `ActionId` field"
  var valid_773256 = formData.getOrDefault("ActionId")
  valid_773256 = validateParameter(valid_773256, JString, required = true,
                                 default = nil)
  if valid_773256 != nil:
    section.add "ActionId", valid_773256
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773257: Call_PostApplyEnvironmentManagedAction_773242;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Applies a scheduled managed action immediately. A managed action can be applied only if its status is <code>Scheduled</code>. Get the status and action ID of a managed action with <a>DescribeEnvironmentManagedActions</a>.
  ## 
  let valid = call_773257.validator(path, query, header, formData, body)
  let scheme = call_773257.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773257.url(scheme.get, call_773257.host, call_773257.base,
                         call_773257.route, valid.getOrDefault("path"))
  result = hook(call_773257, url, valid)

proc call*(call_773258: Call_PostApplyEnvironmentManagedAction_773242;
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
  var query_773259 = newJObject()
  var formData_773260 = newJObject()
  add(formData_773260, "EnvironmentId", newJString(EnvironmentId))
  add(formData_773260, "EnvironmentName", newJString(EnvironmentName))
  add(query_773259, "Action", newJString(Action))
  add(formData_773260, "ActionId", newJString(ActionId))
  add(query_773259, "Version", newJString(Version))
  result = call_773258.call(nil, query_773259, nil, formData_773260, nil)

var postApplyEnvironmentManagedAction* = Call_PostApplyEnvironmentManagedAction_773242(
    name: "postApplyEnvironmentManagedAction", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ApplyEnvironmentManagedAction",
    validator: validate_PostApplyEnvironmentManagedAction_773243, base: "/",
    url: url_PostApplyEnvironmentManagedAction_773244,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplyEnvironmentManagedAction_773224 = ref object of OpenApiRestCall_772598
proc url_GetApplyEnvironmentManagedAction_773226(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetApplyEnvironmentManagedAction_773225(path: JsonNode;
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
  var valid_773227 = query.getOrDefault("EnvironmentName")
  valid_773227 = validateParameter(valid_773227, JString, required = false,
                                 default = nil)
  if valid_773227 != nil:
    section.add "EnvironmentName", valid_773227
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773228 = query.getOrDefault("Action")
  valid_773228 = validateParameter(valid_773228, JString, required = true, default = newJString(
      "ApplyEnvironmentManagedAction"))
  if valid_773228 != nil:
    section.add "Action", valid_773228
  var valid_773229 = query.getOrDefault("EnvironmentId")
  valid_773229 = validateParameter(valid_773229, JString, required = false,
                                 default = nil)
  if valid_773229 != nil:
    section.add "EnvironmentId", valid_773229
  var valid_773230 = query.getOrDefault("ActionId")
  valid_773230 = validateParameter(valid_773230, JString, required = true,
                                 default = nil)
  if valid_773230 != nil:
    section.add "ActionId", valid_773230
  var valid_773231 = query.getOrDefault("Version")
  valid_773231 = validateParameter(valid_773231, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_773231 != nil:
    section.add "Version", valid_773231
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773232 = header.getOrDefault("X-Amz-Date")
  valid_773232 = validateParameter(valid_773232, JString, required = false,
                                 default = nil)
  if valid_773232 != nil:
    section.add "X-Amz-Date", valid_773232
  var valid_773233 = header.getOrDefault("X-Amz-Security-Token")
  valid_773233 = validateParameter(valid_773233, JString, required = false,
                                 default = nil)
  if valid_773233 != nil:
    section.add "X-Amz-Security-Token", valid_773233
  var valid_773234 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773234 = validateParameter(valid_773234, JString, required = false,
                                 default = nil)
  if valid_773234 != nil:
    section.add "X-Amz-Content-Sha256", valid_773234
  var valid_773235 = header.getOrDefault("X-Amz-Algorithm")
  valid_773235 = validateParameter(valid_773235, JString, required = false,
                                 default = nil)
  if valid_773235 != nil:
    section.add "X-Amz-Algorithm", valid_773235
  var valid_773236 = header.getOrDefault("X-Amz-Signature")
  valid_773236 = validateParameter(valid_773236, JString, required = false,
                                 default = nil)
  if valid_773236 != nil:
    section.add "X-Amz-Signature", valid_773236
  var valid_773237 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773237 = validateParameter(valid_773237, JString, required = false,
                                 default = nil)
  if valid_773237 != nil:
    section.add "X-Amz-SignedHeaders", valid_773237
  var valid_773238 = header.getOrDefault("X-Amz-Credential")
  valid_773238 = validateParameter(valid_773238, JString, required = false,
                                 default = nil)
  if valid_773238 != nil:
    section.add "X-Amz-Credential", valid_773238
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773239: Call_GetApplyEnvironmentManagedAction_773224;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Applies a scheduled managed action immediately. A managed action can be applied only if its status is <code>Scheduled</code>. Get the status and action ID of a managed action with <a>DescribeEnvironmentManagedActions</a>.
  ## 
  let valid = call_773239.validator(path, query, header, formData, body)
  let scheme = call_773239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773239.url(scheme.get, call_773239.host, call_773239.base,
                         call_773239.route, valid.getOrDefault("path"))
  result = hook(call_773239, url, valid)

proc call*(call_773240: Call_GetApplyEnvironmentManagedAction_773224;
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
  var query_773241 = newJObject()
  add(query_773241, "EnvironmentName", newJString(EnvironmentName))
  add(query_773241, "Action", newJString(Action))
  add(query_773241, "EnvironmentId", newJString(EnvironmentId))
  add(query_773241, "ActionId", newJString(ActionId))
  add(query_773241, "Version", newJString(Version))
  result = call_773240.call(nil, query_773241, nil, nil, nil)

var getApplyEnvironmentManagedAction* = Call_GetApplyEnvironmentManagedAction_773224(
    name: "getApplyEnvironmentManagedAction", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ApplyEnvironmentManagedAction",
    validator: validate_GetApplyEnvironmentManagedAction_773225, base: "/",
    url: url_GetApplyEnvironmentManagedAction_773226,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCheckDNSAvailability_773277 = ref object of OpenApiRestCall_772598
proc url_PostCheckDNSAvailability_773279(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCheckDNSAvailability_773278(path: JsonNode; query: JsonNode;
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
  var valid_773280 = query.getOrDefault("Action")
  valid_773280 = validateParameter(valid_773280, JString, required = true,
                                 default = newJString("CheckDNSAvailability"))
  if valid_773280 != nil:
    section.add "Action", valid_773280
  var valid_773281 = query.getOrDefault("Version")
  valid_773281 = validateParameter(valid_773281, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_773281 != nil:
    section.add "Version", valid_773281
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773282 = header.getOrDefault("X-Amz-Date")
  valid_773282 = validateParameter(valid_773282, JString, required = false,
                                 default = nil)
  if valid_773282 != nil:
    section.add "X-Amz-Date", valid_773282
  var valid_773283 = header.getOrDefault("X-Amz-Security-Token")
  valid_773283 = validateParameter(valid_773283, JString, required = false,
                                 default = nil)
  if valid_773283 != nil:
    section.add "X-Amz-Security-Token", valid_773283
  var valid_773284 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773284 = validateParameter(valid_773284, JString, required = false,
                                 default = nil)
  if valid_773284 != nil:
    section.add "X-Amz-Content-Sha256", valid_773284
  var valid_773285 = header.getOrDefault("X-Amz-Algorithm")
  valid_773285 = validateParameter(valid_773285, JString, required = false,
                                 default = nil)
  if valid_773285 != nil:
    section.add "X-Amz-Algorithm", valid_773285
  var valid_773286 = header.getOrDefault("X-Amz-Signature")
  valid_773286 = validateParameter(valid_773286, JString, required = false,
                                 default = nil)
  if valid_773286 != nil:
    section.add "X-Amz-Signature", valid_773286
  var valid_773287 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773287 = validateParameter(valid_773287, JString, required = false,
                                 default = nil)
  if valid_773287 != nil:
    section.add "X-Amz-SignedHeaders", valid_773287
  var valid_773288 = header.getOrDefault("X-Amz-Credential")
  valid_773288 = validateParameter(valid_773288, JString, required = false,
                                 default = nil)
  if valid_773288 != nil:
    section.add "X-Amz-Credential", valid_773288
  result.add "header", section
  ## parameters in `formData` object:
  ##   CNAMEPrefix: JString (required)
  ##              : The prefix used when this CNAME is reserved.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `CNAMEPrefix` field"
  var valid_773289 = formData.getOrDefault("CNAMEPrefix")
  valid_773289 = validateParameter(valid_773289, JString, required = true,
                                 default = nil)
  if valid_773289 != nil:
    section.add "CNAMEPrefix", valid_773289
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773290: Call_PostCheckDNSAvailability_773277; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Checks if the specified CNAME is available.
  ## 
  let valid = call_773290.validator(path, query, header, formData, body)
  let scheme = call_773290.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773290.url(scheme.get, call_773290.host, call_773290.base,
                         call_773290.route, valid.getOrDefault("path"))
  result = hook(call_773290, url, valid)

proc call*(call_773291: Call_PostCheckDNSAvailability_773277; CNAMEPrefix: string;
          Action: string = "CheckDNSAvailability"; Version: string = "2010-12-01"): Recallable =
  ## postCheckDNSAvailability
  ## Checks if the specified CNAME is available.
  ##   CNAMEPrefix: string (required)
  ##              : The prefix used when this CNAME is reserved.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773292 = newJObject()
  var formData_773293 = newJObject()
  add(formData_773293, "CNAMEPrefix", newJString(CNAMEPrefix))
  add(query_773292, "Action", newJString(Action))
  add(query_773292, "Version", newJString(Version))
  result = call_773291.call(nil, query_773292, nil, formData_773293, nil)

var postCheckDNSAvailability* = Call_PostCheckDNSAvailability_773277(
    name: "postCheckDNSAvailability", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CheckDNSAvailability",
    validator: validate_PostCheckDNSAvailability_773278, base: "/",
    url: url_PostCheckDNSAvailability_773279, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCheckDNSAvailability_773261 = ref object of OpenApiRestCall_772598
proc url_GetCheckDNSAvailability_773263(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCheckDNSAvailability_773262(path: JsonNode; query: JsonNode;
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
  var valid_773264 = query.getOrDefault("Action")
  valid_773264 = validateParameter(valid_773264, JString, required = true,
                                 default = newJString("CheckDNSAvailability"))
  if valid_773264 != nil:
    section.add "Action", valid_773264
  var valid_773265 = query.getOrDefault("Version")
  valid_773265 = validateParameter(valid_773265, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_773265 != nil:
    section.add "Version", valid_773265
  var valid_773266 = query.getOrDefault("CNAMEPrefix")
  valid_773266 = validateParameter(valid_773266, JString, required = true,
                                 default = nil)
  if valid_773266 != nil:
    section.add "CNAMEPrefix", valid_773266
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773267 = header.getOrDefault("X-Amz-Date")
  valid_773267 = validateParameter(valid_773267, JString, required = false,
                                 default = nil)
  if valid_773267 != nil:
    section.add "X-Amz-Date", valid_773267
  var valid_773268 = header.getOrDefault("X-Amz-Security-Token")
  valid_773268 = validateParameter(valid_773268, JString, required = false,
                                 default = nil)
  if valid_773268 != nil:
    section.add "X-Amz-Security-Token", valid_773268
  var valid_773269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773269 = validateParameter(valid_773269, JString, required = false,
                                 default = nil)
  if valid_773269 != nil:
    section.add "X-Amz-Content-Sha256", valid_773269
  var valid_773270 = header.getOrDefault("X-Amz-Algorithm")
  valid_773270 = validateParameter(valid_773270, JString, required = false,
                                 default = nil)
  if valid_773270 != nil:
    section.add "X-Amz-Algorithm", valid_773270
  var valid_773271 = header.getOrDefault("X-Amz-Signature")
  valid_773271 = validateParameter(valid_773271, JString, required = false,
                                 default = nil)
  if valid_773271 != nil:
    section.add "X-Amz-Signature", valid_773271
  var valid_773272 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773272 = validateParameter(valid_773272, JString, required = false,
                                 default = nil)
  if valid_773272 != nil:
    section.add "X-Amz-SignedHeaders", valid_773272
  var valid_773273 = header.getOrDefault("X-Amz-Credential")
  valid_773273 = validateParameter(valid_773273, JString, required = false,
                                 default = nil)
  if valid_773273 != nil:
    section.add "X-Amz-Credential", valid_773273
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773274: Call_GetCheckDNSAvailability_773261; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Checks if the specified CNAME is available.
  ## 
  let valid = call_773274.validator(path, query, header, formData, body)
  let scheme = call_773274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773274.url(scheme.get, call_773274.host, call_773274.base,
                         call_773274.route, valid.getOrDefault("path"))
  result = hook(call_773274, url, valid)

proc call*(call_773275: Call_GetCheckDNSAvailability_773261; CNAMEPrefix: string;
          Action: string = "CheckDNSAvailability"; Version: string = "2010-12-01"): Recallable =
  ## getCheckDNSAvailability
  ## Checks if the specified CNAME is available.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   CNAMEPrefix: string (required)
  ##              : The prefix used when this CNAME is reserved.
  var query_773276 = newJObject()
  add(query_773276, "Action", newJString(Action))
  add(query_773276, "Version", newJString(Version))
  add(query_773276, "CNAMEPrefix", newJString(CNAMEPrefix))
  result = call_773275.call(nil, query_773276, nil, nil, nil)

var getCheckDNSAvailability* = Call_GetCheckDNSAvailability_773261(
    name: "getCheckDNSAvailability", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CheckDNSAvailability",
    validator: validate_GetCheckDNSAvailability_773262, base: "/",
    url: url_GetCheckDNSAvailability_773263, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostComposeEnvironments_773312 = ref object of OpenApiRestCall_772598
proc url_PostComposeEnvironments_773314(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostComposeEnvironments_773313(path: JsonNode; query: JsonNode;
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
  var valid_773315 = query.getOrDefault("Action")
  valid_773315 = validateParameter(valid_773315, JString, required = true,
                                 default = newJString("ComposeEnvironments"))
  if valid_773315 != nil:
    section.add "Action", valid_773315
  var valid_773316 = query.getOrDefault("Version")
  valid_773316 = validateParameter(valid_773316, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_773316 != nil:
    section.add "Version", valid_773316
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773317 = header.getOrDefault("X-Amz-Date")
  valid_773317 = validateParameter(valid_773317, JString, required = false,
                                 default = nil)
  if valid_773317 != nil:
    section.add "X-Amz-Date", valid_773317
  var valid_773318 = header.getOrDefault("X-Amz-Security-Token")
  valid_773318 = validateParameter(valid_773318, JString, required = false,
                                 default = nil)
  if valid_773318 != nil:
    section.add "X-Amz-Security-Token", valid_773318
  var valid_773319 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773319 = validateParameter(valid_773319, JString, required = false,
                                 default = nil)
  if valid_773319 != nil:
    section.add "X-Amz-Content-Sha256", valid_773319
  var valid_773320 = header.getOrDefault("X-Amz-Algorithm")
  valid_773320 = validateParameter(valid_773320, JString, required = false,
                                 default = nil)
  if valid_773320 != nil:
    section.add "X-Amz-Algorithm", valid_773320
  var valid_773321 = header.getOrDefault("X-Amz-Signature")
  valid_773321 = validateParameter(valid_773321, JString, required = false,
                                 default = nil)
  if valid_773321 != nil:
    section.add "X-Amz-Signature", valid_773321
  var valid_773322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773322 = validateParameter(valid_773322, JString, required = false,
                                 default = nil)
  if valid_773322 != nil:
    section.add "X-Amz-SignedHeaders", valid_773322
  var valid_773323 = header.getOrDefault("X-Amz-Credential")
  valid_773323 = validateParameter(valid_773323, JString, required = false,
                                 default = nil)
  if valid_773323 != nil:
    section.add "X-Amz-Credential", valid_773323
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
  var valid_773324 = formData.getOrDefault("GroupName")
  valid_773324 = validateParameter(valid_773324, JString, required = false,
                                 default = nil)
  if valid_773324 != nil:
    section.add "GroupName", valid_773324
  var valid_773325 = formData.getOrDefault("ApplicationName")
  valid_773325 = validateParameter(valid_773325, JString, required = false,
                                 default = nil)
  if valid_773325 != nil:
    section.add "ApplicationName", valid_773325
  var valid_773326 = formData.getOrDefault("VersionLabels")
  valid_773326 = validateParameter(valid_773326, JArray, required = false,
                                 default = nil)
  if valid_773326 != nil:
    section.add "VersionLabels", valid_773326
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773327: Call_PostComposeEnvironments_773312; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create or update a group of environments that each run a separate component of a single application. Takes a list of version labels that specify application source bundles for each of the environments to create or update. The name of each environment and other required information must be included in the source bundles in an environment manifest named <code>env.yaml</code>. See <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-mgmt-compose.html">Compose Environments</a> for details.
  ## 
  let valid = call_773327.validator(path, query, header, formData, body)
  let scheme = call_773327.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773327.url(scheme.get, call_773327.host, call_773327.base,
                         call_773327.route, valid.getOrDefault("path"))
  result = hook(call_773327, url, valid)

proc call*(call_773328: Call_PostComposeEnvironments_773312;
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
  var query_773329 = newJObject()
  var formData_773330 = newJObject()
  add(formData_773330, "GroupName", newJString(GroupName))
  add(query_773329, "Action", newJString(Action))
  add(formData_773330, "ApplicationName", newJString(ApplicationName))
  add(query_773329, "Version", newJString(Version))
  if VersionLabels != nil:
    formData_773330.add "VersionLabels", VersionLabels
  result = call_773328.call(nil, query_773329, nil, formData_773330, nil)

var postComposeEnvironments* = Call_PostComposeEnvironments_773312(
    name: "postComposeEnvironments", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ComposeEnvironments",
    validator: validate_PostComposeEnvironments_773313, base: "/",
    url: url_PostComposeEnvironments_773314, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetComposeEnvironments_773294 = ref object of OpenApiRestCall_772598
proc url_GetComposeEnvironments_773296(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetComposeEnvironments_773295(path: JsonNode; query: JsonNode;
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
  var valid_773297 = query.getOrDefault("ApplicationName")
  valid_773297 = validateParameter(valid_773297, JString, required = false,
                                 default = nil)
  if valid_773297 != nil:
    section.add "ApplicationName", valid_773297
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773298 = query.getOrDefault("Action")
  valid_773298 = validateParameter(valid_773298, JString, required = true,
                                 default = newJString("ComposeEnvironments"))
  if valid_773298 != nil:
    section.add "Action", valid_773298
  var valid_773299 = query.getOrDefault("GroupName")
  valid_773299 = validateParameter(valid_773299, JString, required = false,
                                 default = nil)
  if valid_773299 != nil:
    section.add "GroupName", valid_773299
  var valid_773300 = query.getOrDefault("VersionLabels")
  valid_773300 = validateParameter(valid_773300, JArray, required = false,
                                 default = nil)
  if valid_773300 != nil:
    section.add "VersionLabels", valid_773300
  var valid_773301 = query.getOrDefault("Version")
  valid_773301 = validateParameter(valid_773301, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_773301 != nil:
    section.add "Version", valid_773301
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773302 = header.getOrDefault("X-Amz-Date")
  valid_773302 = validateParameter(valid_773302, JString, required = false,
                                 default = nil)
  if valid_773302 != nil:
    section.add "X-Amz-Date", valid_773302
  var valid_773303 = header.getOrDefault("X-Amz-Security-Token")
  valid_773303 = validateParameter(valid_773303, JString, required = false,
                                 default = nil)
  if valid_773303 != nil:
    section.add "X-Amz-Security-Token", valid_773303
  var valid_773304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773304 = validateParameter(valid_773304, JString, required = false,
                                 default = nil)
  if valid_773304 != nil:
    section.add "X-Amz-Content-Sha256", valid_773304
  var valid_773305 = header.getOrDefault("X-Amz-Algorithm")
  valid_773305 = validateParameter(valid_773305, JString, required = false,
                                 default = nil)
  if valid_773305 != nil:
    section.add "X-Amz-Algorithm", valid_773305
  var valid_773306 = header.getOrDefault("X-Amz-Signature")
  valid_773306 = validateParameter(valid_773306, JString, required = false,
                                 default = nil)
  if valid_773306 != nil:
    section.add "X-Amz-Signature", valid_773306
  var valid_773307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773307 = validateParameter(valid_773307, JString, required = false,
                                 default = nil)
  if valid_773307 != nil:
    section.add "X-Amz-SignedHeaders", valid_773307
  var valid_773308 = header.getOrDefault("X-Amz-Credential")
  valid_773308 = validateParameter(valid_773308, JString, required = false,
                                 default = nil)
  if valid_773308 != nil:
    section.add "X-Amz-Credential", valid_773308
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773309: Call_GetComposeEnvironments_773294; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create or update a group of environments that each run a separate component of a single application. Takes a list of version labels that specify application source bundles for each of the environments to create or update. The name of each environment and other required information must be included in the source bundles in an environment manifest named <code>env.yaml</code>. See <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-mgmt-compose.html">Compose Environments</a> for details.
  ## 
  let valid = call_773309.validator(path, query, header, formData, body)
  let scheme = call_773309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773309.url(scheme.get, call_773309.host, call_773309.base,
                         call_773309.route, valid.getOrDefault("path"))
  result = hook(call_773309, url, valid)

proc call*(call_773310: Call_GetComposeEnvironments_773294;
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
  var query_773311 = newJObject()
  add(query_773311, "ApplicationName", newJString(ApplicationName))
  add(query_773311, "Action", newJString(Action))
  add(query_773311, "GroupName", newJString(GroupName))
  if VersionLabels != nil:
    query_773311.add "VersionLabels", VersionLabels
  add(query_773311, "Version", newJString(Version))
  result = call_773310.call(nil, query_773311, nil, nil, nil)

var getComposeEnvironments* = Call_GetComposeEnvironments_773294(
    name: "getComposeEnvironments", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ComposeEnvironments",
    validator: validate_GetComposeEnvironments_773295, base: "/",
    url: url_GetComposeEnvironments_773296, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateApplication_773351 = ref object of OpenApiRestCall_772598
proc url_PostCreateApplication_773353(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateApplication_773352(path: JsonNode; query: JsonNode;
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
  var valid_773354 = query.getOrDefault("Action")
  valid_773354 = validateParameter(valid_773354, JString, required = true,
                                 default = newJString("CreateApplication"))
  if valid_773354 != nil:
    section.add "Action", valid_773354
  var valid_773355 = query.getOrDefault("Version")
  valid_773355 = validateParameter(valid_773355, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_773355 != nil:
    section.add "Version", valid_773355
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773356 = header.getOrDefault("X-Amz-Date")
  valid_773356 = validateParameter(valid_773356, JString, required = false,
                                 default = nil)
  if valid_773356 != nil:
    section.add "X-Amz-Date", valid_773356
  var valid_773357 = header.getOrDefault("X-Amz-Security-Token")
  valid_773357 = validateParameter(valid_773357, JString, required = false,
                                 default = nil)
  if valid_773357 != nil:
    section.add "X-Amz-Security-Token", valid_773357
  var valid_773358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773358 = validateParameter(valid_773358, JString, required = false,
                                 default = nil)
  if valid_773358 != nil:
    section.add "X-Amz-Content-Sha256", valid_773358
  var valid_773359 = header.getOrDefault("X-Amz-Algorithm")
  valid_773359 = validateParameter(valid_773359, JString, required = false,
                                 default = nil)
  if valid_773359 != nil:
    section.add "X-Amz-Algorithm", valid_773359
  var valid_773360 = header.getOrDefault("X-Amz-Signature")
  valid_773360 = validateParameter(valid_773360, JString, required = false,
                                 default = nil)
  if valid_773360 != nil:
    section.add "X-Amz-Signature", valid_773360
  var valid_773361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773361 = validateParameter(valid_773361, JString, required = false,
                                 default = nil)
  if valid_773361 != nil:
    section.add "X-Amz-SignedHeaders", valid_773361
  var valid_773362 = header.getOrDefault("X-Amz-Credential")
  valid_773362 = validateParameter(valid_773362, JString, required = false,
                                 default = nil)
  if valid_773362 != nil:
    section.add "X-Amz-Credential", valid_773362
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
  var valid_773363 = formData.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_773363 = validateParameter(valid_773363, JString, required = false,
                                 default = nil)
  if valid_773363 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_773363
  var valid_773364 = formData.getOrDefault("Tags")
  valid_773364 = validateParameter(valid_773364, JArray, required = false,
                                 default = nil)
  if valid_773364 != nil:
    section.add "Tags", valid_773364
  var valid_773365 = formData.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_773365 = validateParameter(valid_773365, JString, required = false,
                                 default = nil)
  if valid_773365 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_773365
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_773366 = formData.getOrDefault("ApplicationName")
  valid_773366 = validateParameter(valid_773366, JString, required = true,
                                 default = nil)
  if valid_773366 != nil:
    section.add "ApplicationName", valid_773366
  var valid_773367 = formData.getOrDefault("Description")
  valid_773367 = validateParameter(valid_773367, JString, required = false,
                                 default = nil)
  if valid_773367 != nil:
    section.add "Description", valid_773367
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773368: Call_PostCreateApplication_773351; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates an application that has one configuration template named <code>default</code> and no application versions. 
  ## 
  let valid = call_773368.validator(path, query, header, formData, body)
  let scheme = call_773368.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773368.url(scheme.get, call_773368.host, call_773368.base,
                         call_773368.route, valid.getOrDefault("path"))
  result = hook(call_773368, url, valid)

proc call*(call_773369: Call_PostCreateApplication_773351; ApplicationName: string;
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
  var query_773370 = newJObject()
  var formData_773371 = newJObject()
  add(formData_773371, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  if Tags != nil:
    formData_773371.add "Tags", Tags
  add(formData_773371, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  add(query_773370, "Action", newJString(Action))
  add(formData_773371, "ApplicationName", newJString(ApplicationName))
  add(query_773370, "Version", newJString(Version))
  add(formData_773371, "Description", newJString(Description))
  result = call_773369.call(nil, query_773370, nil, formData_773371, nil)

var postCreateApplication* = Call_PostCreateApplication_773351(
    name: "postCreateApplication", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateApplication",
    validator: validate_PostCreateApplication_773352, base: "/",
    url: url_PostCreateApplication_773353, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateApplication_773331 = ref object of OpenApiRestCall_772598
proc url_GetCreateApplication_773333(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateApplication_773332(path: JsonNode; query: JsonNode;
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
  var valid_773334 = query.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_773334 = validateParameter(valid_773334, JString, required = false,
                                 default = nil)
  if valid_773334 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_773334
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_773335 = query.getOrDefault("ApplicationName")
  valid_773335 = validateParameter(valid_773335, JString, required = true,
                                 default = nil)
  if valid_773335 != nil:
    section.add "ApplicationName", valid_773335
  var valid_773336 = query.getOrDefault("Description")
  valid_773336 = validateParameter(valid_773336, JString, required = false,
                                 default = nil)
  if valid_773336 != nil:
    section.add "Description", valid_773336
  var valid_773337 = query.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_773337 = validateParameter(valid_773337, JString, required = false,
                                 default = nil)
  if valid_773337 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_773337
  var valid_773338 = query.getOrDefault("Tags")
  valid_773338 = validateParameter(valid_773338, JArray, required = false,
                                 default = nil)
  if valid_773338 != nil:
    section.add "Tags", valid_773338
  var valid_773339 = query.getOrDefault("Action")
  valid_773339 = validateParameter(valid_773339, JString, required = true,
                                 default = newJString("CreateApplication"))
  if valid_773339 != nil:
    section.add "Action", valid_773339
  var valid_773340 = query.getOrDefault("Version")
  valid_773340 = validateParameter(valid_773340, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_773340 != nil:
    section.add "Version", valid_773340
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773341 = header.getOrDefault("X-Amz-Date")
  valid_773341 = validateParameter(valid_773341, JString, required = false,
                                 default = nil)
  if valid_773341 != nil:
    section.add "X-Amz-Date", valid_773341
  var valid_773342 = header.getOrDefault("X-Amz-Security-Token")
  valid_773342 = validateParameter(valid_773342, JString, required = false,
                                 default = nil)
  if valid_773342 != nil:
    section.add "X-Amz-Security-Token", valid_773342
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
  if body != nil:
    result.add "body", body

proc call*(call_773348: Call_GetCreateApplication_773331; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates an application that has one configuration template named <code>default</code> and no application versions. 
  ## 
  let valid = call_773348.validator(path, query, header, formData, body)
  let scheme = call_773348.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773348.url(scheme.get, call_773348.host, call_773348.base,
                         call_773348.route, valid.getOrDefault("path"))
  result = hook(call_773348, url, valid)

proc call*(call_773349: Call_GetCreateApplication_773331; ApplicationName: string;
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
  var query_773350 = newJObject()
  add(query_773350, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  add(query_773350, "ApplicationName", newJString(ApplicationName))
  add(query_773350, "Description", newJString(Description))
  add(query_773350, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  if Tags != nil:
    query_773350.add "Tags", Tags
  add(query_773350, "Action", newJString(Action))
  add(query_773350, "Version", newJString(Version))
  result = call_773349.call(nil, query_773350, nil, nil, nil)

var getCreateApplication* = Call_GetCreateApplication_773331(
    name: "getCreateApplication", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateApplication",
    validator: validate_GetCreateApplication_773332, base: "/",
    url: url_GetCreateApplication_773333, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateApplicationVersion_773403 = ref object of OpenApiRestCall_772598
proc url_PostCreateApplicationVersion_773405(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateApplicationVersion_773404(path: JsonNode; query: JsonNode;
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
  var valid_773406 = query.getOrDefault("Action")
  valid_773406 = validateParameter(valid_773406, JString, required = true, default = newJString(
      "CreateApplicationVersion"))
  if valid_773406 != nil:
    section.add "Action", valid_773406
  var valid_773407 = query.getOrDefault("Version")
  valid_773407 = validateParameter(valid_773407, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_773407 != nil:
    section.add "Version", valid_773407
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773408 = header.getOrDefault("X-Amz-Date")
  valid_773408 = validateParameter(valid_773408, JString, required = false,
                                 default = nil)
  if valid_773408 != nil:
    section.add "X-Amz-Date", valid_773408
  var valid_773409 = header.getOrDefault("X-Amz-Security-Token")
  valid_773409 = validateParameter(valid_773409, JString, required = false,
                                 default = nil)
  if valid_773409 != nil:
    section.add "X-Amz-Security-Token", valid_773409
  var valid_773410 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773410 = validateParameter(valid_773410, JString, required = false,
                                 default = nil)
  if valid_773410 != nil:
    section.add "X-Amz-Content-Sha256", valid_773410
  var valid_773411 = header.getOrDefault("X-Amz-Algorithm")
  valid_773411 = validateParameter(valid_773411, JString, required = false,
                                 default = nil)
  if valid_773411 != nil:
    section.add "X-Amz-Algorithm", valid_773411
  var valid_773412 = header.getOrDefault("X-Amz-Signature")
  valid_773412 = validateParameter(valid_773412, JString, required = false,
                                 default = nil)
  if valid_773412 != nil:
    section.add "X-Amz-Signature", valid_773412
  var valid_773413 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773413 = validateParameter(valid_773413, JString, required = false,
                                 default = nil)
  if valid_773413 != nil:
    section.add "X-Amz-SignedHeaders", valid_773413
  var valid_773414 = header.getOrDefault("X-Amz-Credential")
  valid_773414 = validateParameter(valid_773414, JString, required = false,
                                 default = nil)
  if valid_773414 != nil:
    section.add "X-Amz-Credential", valid_773414
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
  var valid_773415 = formData.getOrDefault("SourceBundle.S3Key")
  valid_773415 = validateParameter(valid_773415, JString, required = false,
                                 default = nil)
  if valid_773415 != nil:
    section.add "SourceBundle.S3Key", valid_773415
  assert formData != nil,
        "formData argument is necessary due to required `VersionLabel` field"
  var valid_773416 = formData.getOrDefault("VersionLabel")
  valid_773416 = validateParameter(valid_773416, JString, required = true,
                                 default = nil)
  if valid_773416 != nil:
    section.add "VersionLabel", valid_773416
  var valid_773417 = formData.getOrDefault("SourceBundle.S3Bucket")
  valid_773417 = validateParameter(valid_773417, JString, required = false,
                                 default = nil)
  if valid_773417 != nil:
    section.add "SourceBundle.S3Bucket", valid_773417
  var valid_773418 = formData.getOrDefault("BuildConfiguration.ComputeType")
  valid_773418 = validateParameter(valid_773418, JString, required = false,
                                 default = nil)
  if valid_773418 != nil:
    section.add "BuildConfiguration.ComputeType", valid_773418
  var valid_773419 = formData.getOrDefault("SourceBuildInformation.SourceType")
  valid_773419 = validateParameter(valid_773419, JString, required = false,
                                 default = nil)
  if valid_773419 != nil:
    section.add "SourceBuildInformation.SourceType", valid_773419
  var valid_773420 = formData.getOrDefault("Tags")
  valid_773420 = validateParameter(valid_773420, JArray, required = false,
                                 default = nil)
  if valid_773420 != nil:
    section.add "Tags", valid_773420
  var valid_773421 = formData.getOrDefault("AutoCreateApplication")
  valid_773421 = validateParameter(valid_773421, JBool, required = false, default = nil)
  if valid_773421 != nil:
    section.add "AutoCreateApplication", valid_773421
  var valid_773422 = formData.getOrDefault("SourceBuildInformation.SourceLocation")
  valid_773422 = validateParameter(valid_773422, JString, required = false,
                                 default = nil)
  if valid_773422 != nil:
    section.add "SourceBuildInformation.SourceLocation", valid_773422
  var valid_773423 = formData.getOrDefault("BuildConfiguration.CodeBuildServiceRole")
  valid_773423 = validateParameter(valid_773423, JString, required = false,
                                 default = nil)
  if valid_773423 != nil:
    section.add "BuildConfiguration.CodeBuildServiceRole", valid_773423
  var valid_773424 = formData.getOrDefault("ApplicationName")
  valid_773424 = validateParameter(valid_773424, JString, required = true,
                                 default = nil)
  if valid_773424 != nil:
    section.add "ApplicationName", valid_773424
  var valid_773425 = formData.getOrDefault("BuildConfiguration.ArtifactName")
  valid_773425 = validateParameter(valid_773425, JString, required = false,
                                 default = nil)
  if valid_773425 != nil:
    section.add "BuildConfiguration.ArtifactName", valid_773425
  var valid_773426 = formData.getOrDefault("BuildConfiguration.TimeoutInMinutes")
  valid_773426 = validateParameter(valid_773426, JString, required = false,
                                 default = nil)
  if valid_773426 != nil:
    section.add "BuildConfiguration.TimeoutInMinutes", valid_773426
  var valid_773427 = formData.getOrDefault("SourceBuildInformation.SourceRepository")
  valid_773427 = validateParameter(valid_773427, JString, required = false,
                                 default = nil)
  if valid_773427 != nil:
    section.add "SourceBuildInformation.SourceRepository", valid_773427
  var valid_773428 = formData.getOrDefault("Description")
  valid_773428 = validateParameter(valid_773428, JString, required = false,
                                 default = nil)
  if valid_773428 != nil:
    section.add "Description", valid_773428
  var valid_773429 = formData.getOrDefault("BuildConfiguration.Image")
  valid_773429 = validateParameter(valid_773429, JString, required = false,
                                 default = nil)
  if valid_773429 != nil:
    section.add "BuildConfiguration.Image", valid_773429
  var valid_773430 = formData.getOrDefault("Process")
  valid_773430 = validateParameter(valid_773430, JBool, required = false, default = nil)
  if valid_773430 != nil:
    section.add "Process", valid_773430
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773431: Call_PostCreateApplicationVersion_773403; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an application version for the specified application. You can create an application version from a source bundle in Amazon S3, a commit in AWS CodeCommit, or the output of an AWS CodeBuild build as follows:</p> <p>Specify a commit in an AWS CodeCommit repository with <code>SourceBuildInformation</code>.</p> <p>Specify a build in an AWS CodeBuild with <code>SourceBuildInformation</code> and <code>BuildConfiguration</code>.</p> <p>Specify a source bundle in S3 with <code>SourceBundle</code> </p> <p>Omit both <code>SourceBuildInformation</code> and <code>SourceBundle</code> to use the default sample application.</p> <note> <p>Once you create an application version with a specified Amazon S3 bucket and key location, you cannot change that Amazon S3 location. If you change the Amazon S3 location, you receive an exception when you attempt to launch an environment from the application version.</p> </note>
  ## 
  let valid = call_773431.validator(path, query, header, formData, body)
  let scheme = call_773431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773431.url(scheme.get, call_773431.host, call_773431.base,
                         call_773431.route, valid.getOrDefault("path"))
  result = hook(call_773431, url, valid)

proc call*(call_773432: Call_PostCreateApplicationVersion_773403;
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
  var query_773433 = newJObject()
  var formData_773434 = newJObject()
  add(formData_773434, "SourceBundle.S3Key", newJString(SourceBundleS3Key))
  add(formData_773434, "VersionLabel", newJString(VersionLabel))
  add(formData_773434, "SourceBundle.S3Bucket", newJString(SourceBundleS3Bucket))
  add(formData_773434, "BuildConfiguration.ComputeType",
      newJString(BuildConfigurationComputeType))
  add(formData_773434, "SourceBuildInformation.SourceType",
      newJString(SourceBuildInformationSourceType))
  if Tags != nil:
    formData_773434.add "Tags", Tags
  add(formData_773434, "AutoCreateApplication", newJBool(AutoCreateApplication))
  add(formData_773434, "SourceBuildInformation.SourceLocation",
      newJString(SourceBuildInformationSourceLocation))
  add(query_773433, "Action", newJString(Action))
  add(formData_773434, "BuildConfiguration.CodeBuildServiceRole",
      newJString(BuildConfigurationCodeBuildServiceRole))
  add(formData_773434, "ApplicationName", newJString(ApplicationName))
  add(formData_773434, "BuildConfiguration.ArtifactName",
      newJString(BuildConfigurationArtifactName))
  add(formData_773434, "BuildConfiguration.TimeoutInMinutes",
      newJString(BuildConfigurationTimeoutInMinutes))
  add(formData_773434, "SourceBuildInformation.SourceRepository",
      newJString(SourceBuildInformationSourceRepository))
  add(formData_773434, "Description", newJString(Description))
  add(formData_773434, "BuildConfiguration.Image",
      newJString(BuildConfigurationImage))
  add(formData_773434, "Process", newJBool(Process))
  add(query_773433, "Version", newJString(Version))
  result = call_773432.call(nil, query_773433, nil, formData_773434, nil)

var postCreateApplicationVersion* = Call_PostCreateApplicationVersion_773403(
    name: "postCreateApplicationVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateApplicationVersion",
    validator: validate_PostCreateApplicationVersion_773404, base: "/",
    url: url_PostCreateApplicationVersion_773405,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateApplicationVersion_773372 = ref object of OpenApiRestCall_772598
proc url_GetCreateApplicationVersion_773374(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateApplicationVersion_773373(path: JsonNode; query: JsonNode;
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
  var valid_773375 = query.getOrDefault("BuildConfiguration.TimeoutInMinutes")
  valid_773375 = validateParameter(valid_773375, JString, required = false,
                                 default = nil)
  if valid_773375 != nil:
    section.add "BuildConfiguration.TimeoutInMinutes", valid_773375
  var valid_773376 = query.getOrDefault("SourceBundle.S3Bucket")
  valid_773376 = validateParameter(valid_773376, JString, required = false,
                                 default = nil)
  if valid_773376 != nil:
    section.add "SourceBundle.S3Bucket", valid_773376
  var valid_773377 = query.getOrDefault("BuildConfiguration.ComputeType")
  valid_773377 = validateParameter(valid_773377, JString, required = false,
                                 default = nil)
  if valid_773377 != nil:
    section.add "BuildConfiguration.ComputeType", valid_773377
  assert query != nil,
        "query argument is necessary due to required `VersionLabel` field"
  var valid_773378 = query.getOrDefault("VersionLabel")
  valid_773378 = validateParameter(valid_773378, JString, required = true,
                                 default = nil)
  if valid_773378 != nil:
    section.add "VersionLabel", valid_773378
  var valid_773379 = query.getOrDefault("BuildConfiguration.ArtifactName")
  valid_773379 = validateParameter(valid_773379, JString, required = false,
                                 default = nil)
  if valid_773379 != nil:
    section.add "BuildConfiguration.ArtifactName", valid_773379
  var valid_773380 = query.getOrDefault("ApplicationName")
  valid_773380 = validateParameter(valid_773380, JString, required = true,
                                 default = nil)
  if valid_773380 != nil:
    section.add "ApplicationName", valid_773380
  var valid_773381 = query.getOrDefault("Description")
  valid_773381 = validateParameter(valid_773381, JString, required = false,
                                 default = nil)
  if valid_773381 != nil:
    section.add "Description", valid_773381
  var valid_773382 = query.getOrDefault("BuildConfiguration.Image")
  valid_773382 = validateParameter(valid_773382, JString, required = false,
                                 default = nil)
  if valid_773382 != nil:
    section.add "BuildConfiguration.Image", valid_773382
  var valid_773383 = query.getOrDefault("SourceBuildInformation.SourceLocation")
  valid_773383 = validateParameter(valid_773383, JString, required = false,
                                 default = nil)
  if valid_773383 != nil:
    section.add "SourceBuildInformation.SourceLocation", valid_773383
  var valid_773384 = query.getOrDefault("SourceBundle.S3Key")
  valid_773384 = validateParameter(valid_773384, JString, required = false,
                                 default = nil)
  if valid_773384 != nil:
    section.add "SourceBundle.S3Key", valid_773384
  var valid_773385 = query.getOrDefault("Tags")
  valid_773385 = validateParameter(valid_773385, JArray, required = false,
                                 default = nil)
  if valid_773385 != nil:
    section.add "Tags", valid_773385
  var valid_773386 = query.getOrDefault("AutoCreateApplication")
  valid_773386 = validateParameter(valid_773386, JBool, required = false, default = nil)
  if valid_773386 != nil:
    section.add "AutoCreateApplication", valid_773386
  var valid_773387 = query.getOrDefault("Action")
  valid_773387 = validateParameter(valid_773387, JString, required = true, default = newJString(
      "CreateApplicationVersion"))
  if valid_773387 != nil:
    section.add "Action", valid_773387
  var valid_773388 = query.getOrDefault("SourceBuildInformation.SourceType")
  valid_773388 = validateParameter(valid_773388, JString, required = false,
                                 default = nil)
  if valid_773388 != nil:
    section.add "SourceBuildInformation.SourceType", valid_773388
  var valid_773389 = query.getOrDefault("BuildConfiguration.CodeBuildServiceRole")
  valid_773389 = validateParameter(valid_773389, JString, required = false,
                                 default = nil)
  if valid_773389 != nil:
    section.add "BuildConfiguration.CodeBuildServiceRole", valid_773389
  var valid_773390 = query.getOrDefault("Process")
  valid_773390 = validateParameter(valid_773390, JBool, required = false, default = nil)
  if valid_773390 != nil:
    section.add "Process", valid_773390
  var valid_773391 = query.getOrDefault("SourceBuildInformation.SourceRepository")
  valid_773391 = validateParameter(valid_773391, JString, required = false,
                                 default = nil)
  if valid_773391 != nil:
    section.add "SourceBuildInformation.SourceRepository", valid_773391
  var valid_773392 = query.getOrDefault("Version")
  valid_773392 = validateParameter(valid_773392, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_773392 != nil:
    section.add "Version", valid_773392
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773393 = header.getOrDefault("X-Amz-Date")
  valid_773393 = validateParameter(valid_773393, JString, required = false,
                                 default = nil)
  if valid_773393 != nil:
    section.add "X-Amz-Date", valid_773393
  var valid_773394 = header.getOrDefault("X-Amz-Security-Token")
  valid_773394 = validateParameter(valid_773394, JString, required = false,
                                 default = nil)
  if valid_773394 != nil:
    section.add "X-Amz-Security-Token", valid_773394
  var valid_773395 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773395 = validateParameter(valid_773395, JString, required = false,
                                 default = nil)
  if valid_773395 != nil:
    section.add "X-Amz-Content-Sha256", valid_773395
  var valid_773396 = header.getOrDefault("X-Amz-Algorithm")
  valid_773396 = validateParameter(valid_773396, JString, required = false,
                                 default = nil)
  if valid_773396 != nil:
    section.add "X-Amz-Algorithm", valid_773396
  var valid_773397 = header.getOrDefault("X-Amz-Signature")
  valid_773397 = validateParameter(valid_773397, JString, required = false,
                                 default = nil)
  if valid_773397 != nil:
    section.add "X-Amz-Signature", valid_773397
  var valid_773398 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773398 = validateParameter(valid_773398, JString, required = false,
                                 default = nil)
  if valid_773398 != nil:
    section.add "X-Amz-SignedHeaders", valid_773398
  var valid_773399 = header.getOrDefault("X-Amz-Credential")
  valid_773399 = validateParameter(valid_773399, JString, required = false,
                                 default = nil)
  if valid_773399 != nil:
    section.add "X-Amz-Credential", valid_773399
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773400: Call_GetCreateApplicationVersion_773372; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an application version for the specified application. You can create an application version from a source bundle in Amazon S3, a commit in AWS CodeCommit, or the output of an AWS CodeBuild build as follows:</p> <p>Specify a commit in an AWS CodeCommit repository with <code>SourceBuildInformation</code>.</p> <p>Specify a build in an AWS CodeBuild with <code>SourceBuildInformation</code> and <code>BuildConfiguration</code>.</p> <p>Specify a source bundle in S3 with <code>SourceBundle</code> </p> <p>Omit both <code>SourceBuildInformation</code> and <code>SourceBundle</code> to use the default sample application.</p> <note> <p>Once you create an application version with a specified Amazon S3 bucket and key location, you cannot change that Amazon S3 location. If you change the Amazon S3 location, you receive an exception when you attempt to launch an environment from the application version.</p> </note>
  ## 
  let valid = call_773400.validator(path, query, header, formData, body)
  let scheme = call_773400.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773400.url(scheme.get, call_773400.host, call_773400.base,
                         call_773400.route, valid.getOrDefault("path"))
  result = hook(call_773400, url, valid)

proc call*(call_773401: Call_GetCreateApplicationVersion_773372;
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
  var query_773402 = newJObject()
  add(query_773402, "BuildConfiguration.TimeoutInMinutes",
      newJString(BuildConfigurationTimeoutInMinutes))
  add(query_773402, "SourceBundle.S3Bucket", newJString(SourceBundleS3Bucket))
  add(query_773402, "BuildConfiguration.ComputeType",
      newJString(BuildConfigurationComputeType))
  add(query_773402, "VersionLabel", newJString(VersionLabel))
  add(query_773402, "BuildConfiguration.ArtifactName",
      newJString(BuildConfigurationArtifactName))
  add(query_773402, "ApplicationName", newJString(ApplicationName))
  add(query_773402, "Description", newJString(Description))
  add(query_773402, "BuildConfiguration.Image",
      newJString(BuildConfigurationImage))
  add(query_773402, "SourceBuildInformation.SourceLocation",
      newJString(SourceBuildInformationSourceLocation))
  add(query_773402, "SourceBundle.S3Key", newJString(SourceBundleS3Key))
  if Tags != nil:
    query_773402.add "Tags", Tags
  add(query_773402, "AutoCreateApplication", newJBool(AutoCreateApplication))
  add(query_773402, "Action", newJString(Action))
  add(query_773402, "SourceBuildInformation.SourceType",
      newJString(SourceBuildInformationSourceType))
  add(query_773402, "BuildConfiguration.CodeBuildServiceRole",
      newJString(BuildConfigurationCodeBuildServiceRole))
  add(query_773402, "Process", newJBool(Process))
  add(query_773402, "SourceBuildInformation.SourceRepository",
      newJString(SourceBuildInformationSourceRepository))
  add(query_773402, "Version", newJString(Version))
  result = call_773401.call(nil, query_773402, nil, nil, nil)

var getCreateApplicationVersion* = Call_GetCreateApplicationVersion_773372(
    name: "getCreateApplicationVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateApplicationVersion",
    validator: validate_GetCreateApplicationVersion_773373, base: "/",
    url: url_GetCreateApplicationVersion_773374,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateConfigurationTemplate_773460 = ref object of OpenApiRestCall_772598
proc url_PostCreateConfigurationTemplate_773462(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateConfigurationTemplate_773461(path: JsonNode;
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
  var valid_773463 = query.getOrDefault("Action")
  valid_773463 = validateParameter(valid_773463, JString, required = true, default = newJString(
      "CreateConfigurationTemplate"))
  if valid_773463 != nil:
    section.add "Action", valid_773463
  var valid_773464 = query.getOrDefault("Version")
  valid_773464 = validateParameter(valid_773464, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_773464 != nil:
    section.add "Version", valid_773464
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773465 = header.getOrDefault("X-Amz-Date")
  valid_773465 = validateParameter(valid_773465, JString, required = false,
                                 default = nil)
  if valid_773465 != nil:
    section.add "X-Amz-Date", valid_773465
  var valid_773466 = header.getOrDefault("X-Amz-Security-Token")
  valid_773466 = validateParameter(valid_773466, JString, required = false,
                                 default = nil)
  if valid_773466 != nil:
    section.add "X-Amz-Security-Token", valid_773466
  var valid_773467 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773467 = validateParameter(valid_773467, JString, required = false,
                                 default = nil)
  if valid_773467 != nil:
    section.add "X-Amz-Content-Sha256", valid_773467
  var valid_773468 = header.getOrDefault("X-Amz-Algorithm")
  valid_773468 = validateParameter(valid_773468, JString, required = false,
                                 default = nil)
  if valid_773468 != nil:
    section.add "X-Amz-Algorithm", valid_773468
  var valid_773469 = header.getOrDefault("X-Amz-Signature")
  valid_773469 = validateParameter(valid_773469, JString, required = false,
                                 default = nil)
  if valid_773469 != nil:
    section.add "X-Amz-Signature", valid_773469
  var valid_773470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773470 = validateParameter(valid_773470, JString, required = false,
                                 default = nil)
  if valid_773470 != nil:
    section.add "X-Amz-SignedHeaders", valid_773470
  var valid_773471 = header.getOrDefault("X-Amz-Credential")
  valid_773471 = validateParameter(valid_773471, JString, required = false,
                                 default = nil)
  if valid_773471 != nil:
    section.add "X-Amz-Credential", valid_773471
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
  var valid_773472 = formData.getOrDefault("OptionSettings")
  valid_773472 = validateParameter(valid_773472, JArray, required = false,
                                 default = nil)
  if valid_773472 != nil:
    section.add "OptionSettings", valid_773472
  var valid_773473 = formData.getOrDefault("Tags")
  valid_773473 = validateParameter(valid_773473, JArray, required = false,
                                 default = nil)
  if valid_773473 != nil:
    section.add "Tags", valid_773473
  var valid_773474 = formData.getOrDefault("SolutionStackName")
  valid_773474 = validateParameter(valid_773474, JString, required = false,
                                 default = nil)
  if valid_773474 != nil:
    section.add "SolutionStackName", valid_773474
  var valid_773475 = formData.getOrDefault("SourceConfiguration.ApplicationName")
  valid_773475 = validateParameter(valid_773475, JString, required = false,
                                 default = nil)
  if valid_773475 != nil:
    section.add "SourceConfiguration.ApplicationName", valid_773475
  var valid_773476 = formData.getOrDefault("EnvironmentId")
  valid_773476 = validateParameter(valid_773476, JString, required = false,
                                 default = nil)
  if valid_773476 != nil:
    section.add "EnvironmentId", valid_773476
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_773477 = formData.getOrDefault("ApplicationName")
  valid_773477 = validateParameter(valid_773477, JString, required = true,
                                 default = nil)
  if valid_773477 != nil:
    section.add "ApplicationName", valid_773477
  var valid_773478 = formData.getOrDefault("PlatformArn")
  valid_773478 = validateParameter(valid_773478, JString, required = false,
                                 default = nil)
  if valid_773478 != nil:
    section.add "PlatformArn", valid_773478
  var valid_773479 = formData.getOrDefault("TemplateName")
  valid_773479 = validateParameter(valid_773479, JString, required = true,
                                 default = nil)
  if valid_773479 != nil:
    section.add "TemplateName", valid_773479
  var valid_773480 = formData.getOrDefault("Description")
  valid_773480 = validateParameter(valid_773480, JString, required = false,
                                 default = nil)
  if valid_773480 != nil:
    section.add "Description", valid_773480
  var valid_773481 = formData.getOrDefault("SourceConfiguration.TemplateName")
  valid_773481 = validateParameter(valid_773481, JString, required = false,
                                 default = nil)
  if valid_773481 != nil:
    section.add "SourceConfiguration.TemplateName", valid_773481
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773482: Call_PostCreateConfigurationTemplate_773460;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a configuration template. Templates are associated with a specific application and are used to deploy different versions of the application with the same configuration settings.</p> <p>Templates aren't associated with any environment. The <code>EnvironmentName</code> response element is always <code>null</code>.</p> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> <li> <p> <a>DescribeConfigurationSettings</a> </p> </li> <li> <p> <a>ListAvailableSolutionStacks</a> </p> </li> </ul>
  ## 
  let valid = call_773482.validator(path, query, header, formData, body)
  let scheme = call_773482.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773482.url(scheme.get, call_773482.host, call_773482.base,
                         call_773482.route, valid.getOrDefault("path"))
  result = hook(call_773482, url, valid)

proc call*(call_773483: Call_PostCreateConfigurationTemplate_773460;
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
  var query_773484 = newJObject()
  var formData_773485 = newJObject()
  if OptionSettings != nil:
    formData_773485.add "OptionSettings", OptionSettings
  if Tags != nil:
    formData_773485.add "Tags", Tags
  add(formData_773485, "SolutionStackName", newJString(SolutionStackName))
  add(formData_773485, "SourceConfiguration.ApplicationName",
      newJString(SourceConfigurationApplicationName))
  add(formData_773485, "EnvironmentId", newJString(EnvironmentId))
  add(query_773484, "Action", newJString(Action))
  add(formData_773485, "ApplicationName", newJString(ApplicationName))
  add(formData_773485, "PlatformArn", newJString(PlatformArn))
  add(formData_773485, "TemplateName", newJString(TemplateName))
  add(query_773484, "Version", newJString(Version))
  add(formData_773485, "Description", newJString(Description))
  add(formData_773485, "SourceConfiguration.TemplateName",
      newJString(SourceConfigurationTemplateName))
  result = call_773483.call(nil, query_773484, nil, formData_773485, nil)

var postCreateConfigurationTemplate* = Call_PostCreateConfigurationTemplate_773460(
    name: "postCreateConfigurationTemplate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateConfigurationTemplate",
    validator: validate_PostCreateConfigurationTemplate_773461, base: "/",
    url: url_PostCreateConfigurationTemplate_773462,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateConfigurationTemplate_773435 = ref object of OpenApiRestCall_772598
proc url_GetCreateConfigurationTemplate_773437(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateConfigurationTemplate_773436(path: JsonNode;
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
  var valid_773438 = query.getOrDefault("SourceConfiguration.ApplicationName")
  valid_773438 = validateParameter(valid_773438, JString, required = false,
                                 default = nil)
  if valid_773438 != nil:
    section.add "SourceConfiguration.ApplicationName", valid_773438
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_773439 = query.getOrDefault("ApplicationName")
  valid_773439 = validateParameter(valid_773439, JString, required = true,
                                 default = nil)
  if valid_773439 != nil:
    section.add "ApplicationName", valid_773439
  var valid_773440 = query.getOrDefault("Description")
  valid_773440 = validateParameter(valid_773440, JString, required = false,
                                 default = nil)
  if valid_773440 != nil:
    section.add "Description", valid_773440
  var valid_773441 = query.getOrDefault("PlatformArn")
  valid_773441 = validateParameter(valid_773441, JString, required = false,
                                 default = nil)
  if valid_773441 != nil:
    section.add "PlatformArn", valid_773441
  var valid_773442 = query.getOrDefault("Tags")
  valid_773442 = validateParameter(valid_773442, JArray, required = false,
                                 default = nil)
  if valid_773442 != nil:
    section.add "Tags", valid_773442
  var valid_773443 = query.getOrDefault("Action")
  valid_773443 = validateParameter(valid_773443, JString, required = true, default = newJString(
      "CreateConfigurationTemplate"))
  if valid_773443 != nil:
    section.add "Action", valid_773443
  var valid_773444 = query.getOrDefault("SolutionStackName")
  valid_773444 = validateParameter(valid_773444, JString, required = false,
                                 default = nil)
  if valid_773444 != nil:
    section.add "SolutionStackName", valid_773444
  var valid_773445 = query.getOrDefault("EnvironmentId")
  valid_773445 = validateParameter(valid_773445, JString, required = false,
                                 default = nil)
  if valid_773445 != nil:
    section.add "EnvironmentId", valid_773445
  var valid_773446 = query.getOrDefault("TemplateName")
  valid_773446 = validateParameter(valid_773446, JString, required = true,
                                 default = nil)
  if valid_773446 != nil:
    section.add "TemplateName", valid_773446
  var valid_773447 = query.getOrDefault("OptionSettings")
  valid_773447 = validateParameter(valid_773447, JArray, required = false,
                                 default = nil)
  if valid_773447 != nil:
    section.add "OptionSettings", valid_773447
  var valid_773448 = query.getOrDefault("Version")
  valid_773448 = validateParameter(valid_773448, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_773448 != nil:
    section.add "Version", valid_773448
  var valid_773449 = query.getOrDefault("SourceConfiguration.TemplateName")
  valid_773449 = validateParameter(valid_773449, JString, required = false,
                                 default = nil)
  if valid_773449 != nil:
    section.add "SourceConfiguration.TemplateName", valid_773449
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773450 = header.getOrDefault("X-Amz-Date")
  valid_773450 = validateParameter(valid_773450, JString, required = false,
                                 default = nil)
  if valid_773450 != nil:
    section.add "X-Amz-Date", valid_773450
  var valid_773451 = header.getOrDefault("X-Amz-Security-Token")
  valid_773451 = validateParameter(valid_773451, JString, required = false,
                                 default = nil)
  if valid_773451 != nil:
    section.add "X-Amz-Security-Token", valid_773451
  var valid_773452 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773452 = validateParameter(valid_773452, JString, required = false,
                                 default = nil)
  if valid_773452 != nil:
    section.add "X-Amz-Content-Sha256", valid_773452
  var valid_773453 = header.getOrDefault("X-Amz-Algorithm")
  valid_773453 = validateParameter(valid_773453, JString, required = false,
                                 default = nil)
  if valid_773453 != nil:
    section.add "X-Amz-Algorithm", valid_773453
  var valid_773454 = header.getOrDefault("X-Amz-Signature")
  valid_773454 = validateParameter(valid_773454, JString, required = false,
                                 default = nil)
  if valid_773454 != nil:
    section.add "X-Amz-Signature", valid_773454
  var valid_773455 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773455 = validateParameter(valid_773455, JString, required = false,
                                 default = nil)
  if valid_773455 != nil:
    section.add "X-Amz-SignedHeaders", valid_773455
  var valid_773456 = header.getOrDefault("X-Amz-Credential")
  valid_773456 = validateParameter(valid_773456, JString, required = false,
                                 default = nil)
  if valid_773456 != nil:
    section.add "X-Amz-Credential", valid_773456
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773457: Call_GetCreateConfigurationTemplate_773435; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a configuration template. Templates are associated with a specific application and are used to deploy different versions of the application with the same configuration settings.</p> <p>Templates aren't associated with any environment. The <code>EnvironmentName</code> response element is always <code>null</code>.</p> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> <li> <p> <a>DescribeConfigurationSettings</a> </p> </li> <li> <p> <a>ListAvailableSolutionStacks</a> </p> </li> </ul>
  ## 
  let valid = call_773457.validator(path, query, header, formData, body)
  let scheme = call_773457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773457.url(scheme.get, call_773457.host, call_773457.base,
                         call_773457.route, valid.getOrDefault("path"))
  result = hook(call_773457, url, valid)

proc call*(call_773458: Call_GetCreateConfigurationTemplate_773435;
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
  var query_773459 = newJObject()
  add(query_773459, "SourceConfiguration.ApplicationName",
      newJString(SourceConfigurationApplicationName))
  add(query_773459, "ApplicationName", newJString(ApplicationName))
  add(query_773459, "Description", newJString(Description))
  add(query_773459, "PlatformArn", newJString(PlatformArn))
  if Tags != nil:
    query_773459.add "Tags", Tags
  add(query_773459, "Action", newJString(Action))
  add(query_773459, "SolutionStackName", newJString(SolutionStackName))
  add(query_773459, "EnvironmentId", newJString(EnvironmentId))
  add(query_773459, "TemplateName", newJString(TemplateName))
  if OptionSettings != nil:
    query_773459.add "OptionSettings", OptionSettings
  add(query_773459, "Version", newJString(Version))
  add(query_773459, "SourceConfiguration.TemplateName",
      newJString(SourceConfigurationTemplateName))
  result = call_773458.call(nil, query_773459, nil, nil, nil)

var getCreateConfigurationTemplate* = Call_GetCreateConfigurationTemplate_773435(
    name: "getCreateConfigurationTemplate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateConfigurationTemplate",
    validator: validate_GetCreateConfigurationTemplate_773436, base: "/",
    url: url_GetCreateConfigurationTemplate_773437,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEnvironment_773516 = ref object of OpenApiRestCall_772598
proc url_PostCreateEnvironment_773518(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateEnvironment_773517(path: JsonNode; query: JsonNode;
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
  var valid_773519 = query.getOrDefault("Action")
  valid_773519 = validateParameter(valid_773519, JString, required = true,
                                 default = newJString("CreateEnvironment"))
  if valid_773519 != nil:
    section.add "Action", valid_773519
  var valid_773520 = query.getOrDefault("Version")
  valid_773520 = validateParameter(valid_773520, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_773520 != nil:
    section.add "Version", valid_773520
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773521 = header.getOrDefault("X-Amz-Date")
  valid_773521 = validateParameter(valid_773521, JString, required = false,
                                 default = nil)
  if valid_773521 != nil:
    section.add "X-Amz-Date", valid_773521
  var valid_773522 = header.getOrDefault("X-Amz-Security-Token")
  valid_773522 = validateParameter(valid_773522, JString, required = false,
                                 default = nil)
  if valid_773522 != nil:
    section.add "X-Amz-Security-Token", valid_773522
  var valid_773523 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773523 = validateParameter(valid_773523, JString, required = false,
                                 default = nil)
  if valid_773523 != nil:
    section.add "X-Amz-Content-Sha256", valid_773523
  var valid_773524 = header.getOrDefault("X-Amz-Algorithm")
  valid_773524 = validateParameter(valid_773524, JString, required = false,
                                 default = nil)
  if valid_773524 != nil:
    section.add "X-Amz-Algorithm", valid_773524
  var valid_773525 = header.getOrDefault("X-Amz-Signature")
  valid_773525 = validateParameter(valid_773525, JString, required = false,
                                 default = nil)
  if valid_773525 != nil:
    section.add "X-Amz-Signature", valid_773525
  var valid_773526 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773526 = validateParameter(valid_773526, JString, required = false,
                                 default = nil)
  if valid_773526 != nil:
    section.add "X-Amz-SignedHeaders", valid_773526
  var valid_773527 = header.getOrDefault("X-Amz-Credential")
  valid_773527 = validateParameter(valid_773527, JString, required = false,
                                 default = nil)
  if valid_773527 != nil:
    section.add "X-Amz-Credential", valid_773527
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
  var valid_773528 = formData.getOrDefault("Tier.Name")
  valid_773528 = validateParameter(valid_773528, JString, required = false,
                                 default = nil)
  if valid_773528 != nil:
    section.add "Tier.Name", valid_773528
  var valid_773529 = formData.getOrDefault("OptionsToRemove")
  valid_773529 = validateParameter(valid_773529, JArray, required = false,
                                 default = nil)
  if valid_773529 != nil:
    section.add "OptionsToRemove", valid_773529
  var valid_773530 = formData.getOrDefault("VersionLabel")
  valid_773530 = validateParameter(valid_773530, JString, required = false,
                                 default = nil)
  if valid_773530 != nil:
    section.add "VersionLabel", valid_773530
  var valid_773531 = formData.getOrDefault("OptionSettings")
  valid_773531 = validateParameter(valid_773531, JArray, required = false,
                                 default = nil)
  if valid_773531 != nil:
    section.add "OptionSettings", valid_773531
  var valid_773532 = formData.getOrDefault("GroupName")
  valid_773532 = validateParameter(valid_773532, JString, required = false,
                                 default = nil)
  if valid_773532 != nil:
    section.add "GroupName", valid_773532
  var valid_773533 = formData.getOrDefault("Tags")
  valid_773533 = validateParameter(valid_773533, JArray, required = false,
                                 default = nil)
  if valid_773533 != nil:
    section.add "Tags", valid_773533
  var valid_773534 = formData.getOrDefault("CNAMEPrefix")
  valid_773534 = validateParameter(valid_773534, JString, required = false,
                                 default = nil)
  if valid_773534 != nil:
    section.add "CNAMEPrefix", valid_773534
  var valid_773535 = formData.getOrDefault("SolutionStackName")
  valid_773535 = validateParameter(valid_773535, JString, required = false,
                                 default = nil)
  if valid_773535 != nil:
    section.add "SolutionStackName", valid_773535
  var valid_773536 = formData.getOrDefault("EnvironmentName")
  valid_773536 = validateParameter(valid_773536, JString, required = false,
                                 default = nil)
  if valid_773536 != nil:
    section.add "EnvironmentName", valid_773536
  var valid_773537 = formData.getOrDefault("Tier.Type")
  valid_773537 = validateParameter(valid_773537, JString, required = false,
                                 default = nil)
  if valid_773537 != nil:
    section.add "Tier.Type", valid_773537
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_773538 = formData.getOrDefault("ApplicationName")
  valid_773538 = validateParameter(valid_773538, JString, required = true,
                                 default = nil)
  if valid_773538 != nil:
    section.add "ApplicationName", valid_773538
  var valid_773539 = formData.getOrDefault("PlatformArn")
  valid_773539 = validateParameter(valid_773539, JString, required = false,
                                 default = nil)
  if valid_773539 != nil:
    section.add "PlatformArn", valid_773539
  var valid_773540 = formData.getOrDefault("TemplateName")
  valid_773540 = validateParameter(valid_773540, JString, required = false,
                                 default = nil)
  if valid_773540 != nil:
    section.add "TemplateName", valid_773540
  var valid_773541 = formData.getOrDefault("Description")
  valid_773541 = validateParameter(valid_773541, JString, required = false,
                                 default = nil)
  if valid_773541 != nil:
    section.add "Description", valid_773541
  var valid_773542 = formData.getOrDefault("Tier.Version")
  valid_773542 = validateParameter(valid_773542, JString, required = false,
                                 default = nil)
  if valid_773542 != nil:
    section.add "Tier.Version", valid_773542
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773543: Call_PostCreateEnvironment_773516; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Launches an environment for the specified application using the specified configuration.
  ## 
  let valid = call_773543.validator(path, query, header, formData, body)
  let scheme = call_773543.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773543.url(scheme.get, call_773543.host, call_773543.base,
                         call_773543.route, valid.getOrDefault("path"))
  result = hook(call_773543, url, valid)

proc call*(call_773544: Call_PostCreateEnvironment_773516; ApplicationName: string;
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
  var query_773545 = newJObject()
  var formData_773546 = newJObject()
  add(formData_773546, "Tier.Name", newJString(TierName))
  if OptionsToRemove != nil:
    formData_773546.add "OptionsToRemove", OptionsToRemove
  add(formData_773546, "VersionLabel", newJString(VersionLabel))
  if OptionSettings != nil:
    formData_773546.add "OptionSettings", OptionSettings
  add(formData_773546, "GroupName", newJString(GroupName))
  if Tags != nil:
    formData_773546.add "Tags", Tags
  add(formData_773546, "CNAMEPrefix", newJString(CNAMEPrefix))
  add(formData_773546, "SolutionStackName", newJString(SolutionStackName))
  add(formData_773546, "EnvironmentName", newJString(EnvironmentName))
  add(formData_773546, "Tier.Type", newJString(TierType))
  add(query_773545, "Action", newJString(Action))
  add(formData_773546, "ApplicationName", newJString(ApplicationName))
  add(formData_773546, "PlatformArn", newJString(PlatformArn))
  add(formData_773546, "TemplateName", newJString(TemplateName))
  add(query_773545, "Version", newJString(Version))
  add(formData_773546, "Description", newJString(Description))
  add(formData_773546, "Tier.Version", newJString(TierVersion))
  result = call_773544.call(nil, query_773545, nil, formData_773546, nil)

var postCreateEnvironment* = Call_PostCreateEnvironment_773516(
    name: "postCreateEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateEnvironment",
    validator: validate_PostCreateEnvironment_773517, base: "/",
    url: url_PostCreateEnvironment_773518, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEnvironment_773486 = ref object of OpenApiRestCall_772598
proc url_GetCreateEnvironment_773488(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateEnvironment_773487(path: JsonNode; query: JsonNode;
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
  var valid_773489 = query.getOrDefault("Tier.Name")
  valid_773489 = validateParameter(valid_773489, JString, required = false,
                                 default = nil)
  if valid_773489 != nil:
    section.add "Tier.Name", valid_773489
  var valid_773490 = query.getOrDefault("VersionLabel")
  valid_773490 = validateParameter(valid_773490, JString, required = false,
                                 default = nil)
  if valid_773490 != nil:
    section.add "VersionLabel", valid_773490
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_773491 = query.getOrDefault("ApplicationName")
  valid_773491 = validateParameter(valid_773491, JString, required = true,
                                 default = nil)
  if valid_773491 != nil:
    section.add "ApplicationName", valid_773491
  var valid_773492 = query.getOrDefault("Description")
  valid_773492 = validateParameter(valid_773492, JString, required = false,
                                 default = nil)
  if valid_773492 != nil:
    section.add "Description", valid_773492
  var valid_773493 = query.getOrDefault("OptionsToRemove")
  valid_773493 = validateParameter(valid_773493, JArray, required = false,
                                 default = nil)
  if valid_773493 != nil:
    section.add "OptionsToRemove", valid_773493
  var valid_773494 = query.getOrDefault("PlatformArn")
  valid_773494 = validateParameter(valid_773494, JString, required = false,
                                 default = nil)
  if valid_773494 != nil:
    section.add "PlatformArn", valid_773494
  var valid_773495 = query.getOrDefault("Tags")
  valid_773495 = validateParameter(valid_773495, JArray, required = false,
                                 default = nil)
  if valid_773495 != nil:
    section.add "Tags", valid_773495
  var valid_773496 = query.getOrDefault("EnvironmentName")
  valid_773496 = validateParameter(valid_773496, JString, required = false,
                                 default = nil)
  if valid_773496 != nil:
    section.add "EnvironmentName", valid_773496
  var valid_773497 = query.getOrDefault("Action")
  valid_773497 = validateParameter(valid_773497, JString, required = true,
                                 default = newJString("CreateEnvironment"))
  if valid_773497 != nil:
    section.add "Action", valid_773497
  var valid_773498 = query.getOrDefault("SolutionStackName")
  valid_773498 = validateParameter(valid_773498, JString, required = false,
                                 default = nil)
  if valid_773498 != nil:
    section.add "SolutionStackName", valid_773498
  var valid_773499 = query.getOrDefault("Tier.Version")
  valid_773499 = validateParameter(valid_773499, JString, required = false,
                                 default = nil)
  if valid_773499 != nil:
    section.add "Tier.Version", valid_773499
  var valid_773500 = query.getOrDefault("TemplateName")
  valid_773500 = validateParameter(valid_773500, JString, required = false,
                                 default = nil)
  if valid_773500 != nil:
    section.add "TemplateName", valid_773500
  var valid_773501 = query.getOrDefault("GroupName")
  valid_773501 = validateParameter(valid_773501, JString, required = false,
                                 default = nil)
  if valid_773501 != nil:
    section.add "GroupName", valid_773501
  var valid_773502 = query.getOrDefault("OptionSettings")
  valid_773502 = validateParameter(valid_773502, JArray, required = false,
                                 default = nil)
  if valid_773502 != nil:
    section.add "OptionSettings", valid_773502
  var valid_773503 = query.getOrDefault("Tier.Type")
  valid_773503 = validateParameter(valid_773503, JString, required = false,
                                 default = nil)
  if valid_773503 != nil:
    section.add "Tier.Type", valid_773503
  var valid_773504 = query.getOrDefault("Version")
  valid_773504 = validateParameter(valid_773504, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_773504 != nil:
    section.add "Version", valid_773504
  var valid_773505 = query.getOrDefault("CNAMEPrefix")
  valid_773505 = validateParameter(valid_773505, JString, required = false,
                                 default = nil)
  if valid_773505 != nil:
    section.add "CNAMEPrefix", valid_773505
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773506 = header.getOrDefault("X-Amz-Date")
  valid_773506 = validateParameter(valid_773506, JString, required = false,
                                 default = nil)
  if valid_773506 != nil:
    section.add "X-Amz-Date", valid_773506
  var valid_773507 = header.getOrDefault("X-Amz-Security-Token")
  valid_773507 = validateParameter(valid_773507, JString, required = false,
                                 default = nil)
  if valid_773507 != nil:
    section.add "X-Amz-Security-Token", valid_773507
  var valid_773508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773508 = validateParameter(valid_773508, JString, required = false,
                                 default = nil)
  if valid_773508 != nil:
    section.add "X-Amz-Content-Sha256", valid_773508
  var valid_773509 = header.getOrDefault("X-Amz-Algorithm")
  valid_773509 = validateParameter(valid_773509, JString, required = false,
                                 default = nil)
  if valid_773509 != nil:
    section.add "X-Amz-Algorithm", valid_773509
  var valid_773510 = header.getOrDefault("X-Amz-Signature")
  valid_773510 = validateParameter(valid_773510, JString, required = false,
                                 default = nil)
  if valid_773510 != nil:
    section.add "X-Amz-Signature", valid_773510
  var valid_773511 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773511 = validateParameter(valid_773511, JString, required = false,
                                 default = nil)
  if valid_773511 != nil:
    section.add "X-Amz-SignedHeaders", valid_773511
  var valid_773512 = header.getOrDefault("X-Amz-Credential")
  valid_773512 = validateParameter(valid_773512, JString, required = false,
                                 default = nil)
  if valid_773512 != nil:
    section.add "X-Amz-Credential", valid_773512
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773513: Call_GetCreateEnvironment_773486; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Launches an environment for the specified application using the specified configuration.
  ## 
  let valid = call_773513.validator(path, query, header, formData, body)
  let scheme = call_773513.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773513.url(scheme.get, call_773513.host, call_773513.base,
                         call_773513.route, valid.getOrDefault("path"))
  result = hook(call_773513, url, valid)

proc call*(call_773514: Call_GetCreateEnvironment_773486; ApplicationName: string;
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
  var query_773515 = newJObject()
  add(query_773515, "Tier.Name", newJString(TierName))
  add(query_773515, "VersionLabel", newJString(VersionLabel))
  add(query_773515, "ApplicationName", newJString(ApplicationName))
  add(query_773515, "Description", newJString(Description))
  if OptionsToRemove != nil:
    query_773515.add "OptionsToRemove", OptionsToRemove
  add(query_773515, "PlatformArn", newJString(PlatformArn))
  if Tags != nil:
    query_773515.add "Tags", Tags
  add(query_773515, "EnvironmentName", newJString(EnvironmentName))
  add(query_773515, "Action", newJString(Action))
  add(query_773515, "SolutionStackName", newJString(SolutionStackName))
  add(query_773515, "Tier.Version", newJString(TierVersion))
  add(query_773515, "TemplateName", newJString(TemplateName))
  add(query_773515, "GroupName", newJString(GroupName))
  if OptionSettings != nil:
    query_773515.add "OptionSettings", OptionSettings
  add(query_773515, "Tier.Type", newJString(TierType))
  add(query_773515, "Version", newJString(Version))
  add(query_773515, "CNAMEPrefix", newJString(CNAMEPrefix))
  result = call_773514.call(nil, query_773515, nil, nil, nil)

var getCreateEnvironment* = Call_GetCreateEnvironment_773486(
    name: "getCreateEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateEnvironment",
    validator: validate_GetCreateEnvironment_773487, base: "/",
    url: url_GetCreateEnvironment_773488, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreatePlatformVersion_773569 = ref object of OpenApiRestCall_772598
proc url_PostCreatePlatformVersion_773571(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreatePlatformVersion_773570(path: JsonNode; query: JsonNode;
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
  var valid_773572 = query.getOrDefault("Action")
  valid_773572 = validateParameter(valid_773572, JString, required = true,
                                 default = newJString("CreatePlatformVersion"))
  if valid_773572 != nil:
    section.add "Action", valid_773572
  var valid_773573 = query.getOrDefault("Version")
  valid_773573 = validateParameter(valid_773573, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_773573 != nil:
    section.add "Version", valid_773573
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773574 = header.getOrDefault("X-Amz-Date")
  valid_773574 = validateParameter(valid_773574, JString, required = false,
                                 default = nil)
  if valid_773574 != nil:
    section.add "X-Amz-Date", valid_773574
  var valid_773575 = header.getOrDefault("X-Amz-Security-Token")
  valid_773575 = validateParameter(valid_773575, JString, required = false,
                                 default = nil)
  if valid_773575 != nil:
    section.add "X-Amz-Security-Token", valid_773575
  var valid_773576 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773576 = validateParameter(valid_773576, JString, required = false,
                                 default = nil)
  if valid_773576 != nil:
    section.add "X-Amz-Content-Sha256", valid_773576
  var valid_773577 = header.getOrDefault("X-Amz-Algorithm")
  valid_773577 = validateParameter(valid_773577, JString, required = false,
                                 default = nil)
  if valid_773577 != nil:
    section.add "X-Amz-Algorithm", valid_773577
  var valid_773578 = header.getOrDefault("X-Amz-Signature")
  valid_773578 = validateParameter(valid_773578, JString, required = false,
                                 default = nil)
  if valid_773578 != nil:
    section.add "X-Amz-Signature", valid_773578
  var valid_773579 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773579 = validateParameter(valid_773579, JString, required = false,
                                 default = nil)
  if valid_773579 != nil:
    section.add "X-Amz-SignedHeaders", valid_773579
  var valid_773580 = header.getOrDefault("X-Amz-Credential")
  valid_773580 = validateParameter(valid_773580, JString, required = false,
                                 default = nil)
  if valid_773580 != nil:
    section.add "X-Amz-Credential", valid_773580
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
  var valid_773581 = formData.getOrDefault("PlatformName")
  valid_773581 = validateParameter(valid_773581, JString, required = true,
                                 default = nil)
  if valid_773581 != nil:
    section.add "PlatformName", valid_773581
  var valid_773582 = formData.getOrDefault("PlatformDefinitionBundle.S3Key")
  valid_773582 = validateParameter(valid_773582, JString, required = false,
                                 default = nil)
  if valid_773582 != nil:
    section.add "PlatformDefinitionBundle.S3Key", valid_773582
  var valid_773583 = formData.getOrDefault("OptionSettings")
  valid_773583 = validateParameter(valid_773583, JArray, required = false,
                                 default = nil)
  if valid_773583 != nil:
    section.add "OptionSettings", valid_773583
  var valid_773584 = formData.getOrDefault("Tags")
  valid_773584 = validateParameter(valid_773584, JArray, required = false,
                                 default = nil)
  if valid_773584 != nil:
    section.add "Tags", valid_773584
  var valid_773585 = formData.getOrDefault("EnvironmentName")
  valid_773585 = validateParameter(valid_773585, JString, required = false,
                                 default = nil)
  if valid_773585 != nil:
    section.add "EnvironmentName", valid_773585
  var valid_773586 = formData.getOrDefault("PlatformDefinitionBundle.S3Bucket")
  valid_773586 = validateParameter(valid_773586, JString, required = false,
                                 default = nil)
  if valid_773586 != nil:
    section.add "PlatformDefinitionBundle.S3Bucket", valid_773586
  var valid_773587 = formData.getOrDefault("PlatformVersion")
  valid_773587 = validateParameter(valid_773587, JString, required = true,
                                 default = nil)
  if valid_773587 != nil:
    section.add "PlatformVersion", valid_773587
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773588: Call_PostCreatePlatformVersion_773569; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new version of your custom platform.
  ## 
  let valid = call_773588.validator(path, query, header, formData, body)
  let scheme = call_773588.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773588.url(scheme.get, call_773588.host, call_773588.base,
                         call_773588.route, valid.getOrDefault("path"))
  result = hook(call_773588, url, valid)

proc call*(call_773589: Call_PostCreatePlatformVersion_773569;
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
  var query_773590 = newJObject()
  var formData_773591 = newJObject()
  add(formData_773591, "PlatformName", newJString(PlatformName))
  add(formData_773591, "PlatformDefinitionBundle.S3Key",
      newJString(PlatformDefinitionBundleS3Key))
  if OptionSettings != nil:
    formData_773591.add "OptionSettings", OptionSettings
  if Tags != nil:
    formData_773591.add "Tags", Tags
  add(formData_773591, "EnvironmentName", newJString(EnvironmentName))
  add(formData_773591, "PlatformDefinitionBundle.S3Bucket",
      newJString(PlatformDefinitionBundleS3Bucket))
  add(query_773590, "Action", newJString(Action))
  add(formData_773591, "PlatformVersion", newJString(PlatformVersion))
  add(query_773590, "Version", newJString(Version))
  result = call_773589.call(nil, query_773590, nil, formData_773591, nil)

var postCreatePlatformVersion* = Call_PostCreatePlatformVersion_773569(
    name: "postCreatePlatformVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreatePlatformVersion",
    validator: validate_PostCreatePlatformVersion_773570, base: "/",
    url: url_PostCreatePlatformVersion_773571,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreatePlatformVersion_773547 = ref object of OpenApiRestCall_772598
proc url_GetCreatePlatformVersion_773549(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreatePlatformVersion_773548(path: JsonNode; query: JsonNode;
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
  var valid_773550 = query.getOrDefault("Tags")
  valid_773550 = validateParameter(valid_773550, JArray, required = false,
                                 default = nil)
  if valid_773550 != nil:
    section.add "Tags", valid_773550
  var valid_773551 = query.getOrDefault("EnvironmentName")
  valid_773551 = validateParameter(valid_773551, JString, required = false,
                                 default = nil)
  if valid_773551 != nil:
    section.add "EnvironmentName", valid_773551
  var valid_773552 = query.getOrDefault("PlatformDefinitionBundle.S3Key")
  valid_773552 = validateParameter(valid_773552, JString, required = false,
                                 default = nil)
  if valid_773552 != nil:
    section.add "PlatformDefinitionBundle.S3Key", valid_773552
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773553 = query.getOrDefault("Action")
  valid_773553 = validateParameter(valid_773553, JString, required = true,
                                 default = newJString("CreatePlatformVersion"))
  if valid_773553 != nil:
    section.add "Action", valid_773553
  var valid_773554 = query.getOrDefault("OptionSettings")
  valid_773554 = validateParameter(valid_773554, JArray, required = false,
                                 default = nil)
  if valid_773554 != nil:
    section.add "OptionSettings", valid_773554
  var valid_773555 = query.getOrDefault("PlatformName")
  valid_773555 = validateParameter(valid_773555, JString, required = true,
                                 default = nil)
  if valid_773555 != nil:
    section.add "PlatformName", valid_773555
  var valid_773556 = query.getOrDefault("Version")
  valid_773556 = validateParameter(valid_773556, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_773556 != nil:
    section.add "Version", valid_773556
  var valid_773557 = query.getOrDefault("PlatformDefinitionBundle.S3Bucket")
  valid_773557 = validateParameter(valid_773557, JString, required = false,
                                 default = nil)
  if valid_773557 != nil:
    section.add "PlatformDefinitionBundle.S3Bucket", valid_773557
  var valid_773558 = query.getOrDefault("PlatformVersion")
  valid_773558 = validateParameter(valid_773558, JString, required = true,
                                 default = nil)
  if valid_773558 != nil:
    section.add "PlatformVersion", valid_773558
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773559 = header.getOrDefault("X-Amz-Date")
  valid_773559 = validateParameter(valid_773559, JString, required = false,
                                 default = nil)
  if valid_773559 != nil:
    section.add "X-Amz-Date", valid_773559
  var valid_773560 = header.getOrDefault("X-Amz-Security-Token")
  valid_773560 = validateParameter(valid_773560, JString, required = false,
                                 default = nil)
  if valid_773560 != nil:
    section.add "X-Amz-Security-Token", valid_773560
  var valid_773561 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773561 = validateParameter(valid_773561, JString, required = false,
                                 default = nil)
  if valid_773561 != nil:
    section.add "X-Amz-Content-Sha256", valid_773561
  var valid_773562 = header.getOrDefault("X-Amz-Algorithm")
  valid_773562 = validateParameter(valid_773562, JString, required = false,
                                 default = nil)
  if valid_773562 != nil:
    section.add "X-Amz-Algorithm", valid_773562
  var valid_773563 = header.getOrDefault("X-Amz-Signature")
  valid_773563 = validateParameter(valid_773563, JString, required = false,
                                 default = nil)
  if valid_773563 != nil:
    section.add "X-Amz-Signature", valid_773563
  var valid_773564 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773564 = validateParameter(valid_773564, JString, required = false,
                                 default = nil)
  if valid_773564 != nil:
    section.add "X-Amz-SignedHeaders", valid_773564
  var valid_773565 = header.getOrDefault("X-Amz-Credential")
  valid_773565 = validateParameter(valid_773565, JString, required = false,
                                 default = nil)
  if valid_773565 != nil:
    section.add "X-Amz-Credential", valid_773565
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773566: Call_GetCreatePlatformVersion_773547; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new version of your custom platform.
  ## 
  let valid = call_773566.validator(path, query, header, formData, body)
  let scheme = call_773566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773566.url(scheme.get, call_773566.host, call_773566.base,
                         call_773566.route, valid.getOrDefault("path"))
  result = hook(call_773566, url, valid)

proc call*(call_773567: Call_GetCreatePlatformVersion_773547; PlatformName: string;
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
  var query_773568 = newJObject()
  if Tags != nil:
    query_773568.add "Tags", Tags
  add(query_773568, "EnvironmentName", newJString(EnvironmentName))
  add(query_773568, "PlatformDefinitionBundle.S3Key",
      newJString(PlatformDefinitionBundleS3Key))
  add(query_773568, "Action", newJString(Action))
  if OptionSettings != nil:
    query_773568.add "OptionSettings", OptionSettings
  add(query_773568, "PlatformName", newJString(PlatformName))
  add(query_773568, "Version", newJString(Version))
  add(query_773568, "PlatformDefinitionBundle.S3Bucket",
      newJString(PlatformDefinitionBundleS3Bucket))
  add(query_773568, "PlatformVersion", newJString(PlatformVersion))
  result = call_773567.call(nil, query_773568, nil, nil, nil)

var getCreatePlatformVersion* = Call_GetCreatePlatformVersion_773547(
    name: "getCreatePlatformVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreatePlatformVersion",
    validator: validate_GetCreatePlatformVersion_773548, base: "/",
    url: url_GetCreatePlatformVersion_773549, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateStorageLocation_773607 = ref object of OpenApiRestCall_772598
proc url_PostCreateStorageLocation_773609(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateStorageLocation_773608(path: JsonNode; query: JsonNode;
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
  var valid_773610 = query.getOrDefault("Action")
  valid_773610 = validateParameter(valid_773610, JString, required = true,
                                 default = newJString("CreateStorageLocation"))
  if valid_773610 != nil:
    section.add "Action", valid_773610
  var valid_773611 = query.getOrDefault("Version")
  valid_773611 = validateParameter(valid_773611, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_773611 != nil:
    section.add "Version", valid_773611
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773612 = header.getOrDefault("X-Amz-Date")
  valid_773612 = validateParameter(valid_773612, JString, required = false,
                                 default = nil)
  if valid_773612 != nil:
    section.add "X-Amz-Date", valid_773612
  var valid_773613 = header.getOrDefault("X-Amz-Security-Token")
  valid_773613 = validateParameter(valid_773613, JString, required = false,
                                 default = nil)
  if valid_773613 != nil:
    section.add "X-Amz-Security-Token", valid_773613
  var valid_773614 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773614 = validateParameter(valid_773614, JString, required = false,
                                 default = nil)
  if valid_773614 != nil:
    section.add "X-Amz-Content-Sha256", valid_773614
  var valid_773615 = header.getOrDefault("X-Amz-Algorithm")
  valid_773615 = validateParameter(valid_773615, JString, required = false,
                                 default = nil)
  if valid_773615 != nil:
    section.add "X-Amz-Algorithm", valid_773615
  var valid_773616 = header.getOrDefault("X-Amz-Signature")
  valid_773616 = validateParameter(valid_773616, JString, required = false,
                                 default = nil)
  if valid_773616 != nil:
    section.add "X-Amz-Signature", valid_773616
  var valid_773617 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773617 = validateParameter(valid_773617, JString, required = false,
                                 default = nil)
  if valid_773617 != nil:
    section.add "X-Amz-SignedHeaders", valid_773617
  var valid_773618 = header.getOrDefault("X-Amz-Credential")
  valid_773618 = validateParameter(valid_773618, JString, required = false,
                                 default = nil)
  if valid_773618 != nil:
    section.add "X-Amz-Credential", valid_773618
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773619: Call_PostCreateStorageLocation_773607; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ## 
  let valid = call_773619.validator(path, query, header, formData, body)
  let scheme = call_773619.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773619.url(scheme.get, call_773619.host, call_773619.base,
                         call_773619.route, valid.getOrDefault("path"))
  result = hook(call_773619, url, valid)

proc call*(call_773620: Call_PostCreateStorageLocation_773607;
          Action: string = "CreateStorageLocation"; Version: string = "2010-12-01"): Recallable =
  ## postCreateStorageLocation
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773621 = newJObject()
  add(query_773621, "Action", newJString(Action))
  add(query_773621, "Version", newJString(Version))
  result = call_773620.call(nil, query_773621, nil, nil, nil)

var postCreateStorageLocation* = Call_PostCreateStorageLocation_773607(
    name: "postCreateStorageLocation", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateStorageLocation",
    validator: validate_PostCreateStorageLocation_773608, base: "/",
    url: url_PostCreateStorageLocation_773609,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateStorageLocation_773592 = ref object of OpenApiRestCall_772598
proc url_GetCreateStorageLocation_773594(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateStorageLocation_773593(path: JsonNode; query: JsonNode;
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
  var valid_773595 = query.getOrDefault("Action")
  valid_773595 = validateParameter(valid_773595, JString, required = true,
                                 default = newJString("CreateStorageLocation"))
  if valid_773595 != nil:
    section.add "Action", valid_773595
  var valid_773596 = query.getOrDefault("Version")
  valid_773596 = validateParameter(valid_773596, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_773596 != nil:
    section.add "Version", valid_773596
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773597 = header.getOrDefault("X-Amz-Date")
  valid_773597 = validateParameter(valid_773597, JString, required = false,
                                 default = nil)
  if valid_773597 != nil:
    section.add "X-Amz-Date", valid_773597
  var valid_773598 = header.getOrDefault("X-Amz-Security-Token")
  valid_773598 = validateParameter(valid_773598, JString, required = false,
                                 default = nil)
  if valid_773598 != nil:
    section.add "X-Amz-Security-Token", valid_773598
  var valid_773599 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773599 = validateParameter(valid_773599, JString, required = false,
                                 default = nil)
  if valid_773599 != nil:
    section.add "X-Amz-Content-Sha256", valid_773599
  var valid_773600 = header.getOrDefault("X-Amz-Algorithm")
  valid_773600 = validateParameter(valid_773600, JString, required = false,
                                 default = nil)
  if valid_773600 != nil:
    section.add "X-Amz-Algorithm", valid_773600
  var valid_773601 = header.getOrDefault("X-Amz-Signature")
  valid_773601 = validateParameter(valid_773601, JString, required = false,
                                 default = nil)
  if valid_773601 != nil:
    section.add "X-Amz-Signature", valid_773601
  var valid_773602 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773602 = validateParameter(valid_773602, JString, required = false,
                                 default = nil)
  if valid_773602 != nil:
    section.add "X-Amz-SignedHeaders", valid_773602
  var valid_773603 = header.getOrDefault("X-Amz-Credential")
  valid_773603 = validateParameter(valid_773603, JString, required = false,
                                 default = nil)
  if valid_773603 != nil:
    section.add "X-Amz-Credential", valid_773603
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773604: Call_GetCreateStorageLocation_773592; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ## 
  let valid = call_773604.validator(path, query, header, formData, body)
  let scheme = call_773604.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773604.url(scheme.get, call_773604.host, call_773604.base,
                         call_773604.route, valid.getOrDefault("path"))
  result = hook(call_773604, url, valid)

proc call*(call_773605: Call_GetCreateStorageLocation_773592;
          Action: string = "CreateStorageLocation"; Version: string = "2010-12-01"): Recallable =
  ## getCreateStorageLocation
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773606 = newJObject()
  add(query_773606, "Action", newJString(Action))
  add(query_773606, "Version", newJString(Version))
  result = call_773605.call(nil, query_773606, nil, nil, nil)

var getCreateStorageLocation* = Call_GetCreateStorageLocation_773592(
    name: "getCreateStorageLocation", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateStorageLocation",
    validator: validate_GetCreateStorageLocation_773593, base: "/",
    url: url_GetCreateStorageLocation_773594, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteApplication_773639 = ref object of OpenApiRestCall_772598
proc url_PostDeleteApplication_773641(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteApplication_773640(path: JsonNode; query: JsonNode;
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
  var valid_773642 = query.getOrDefault("Action")
  valid_773642 = validateParameter(valid_773642, JString, required = true,
                                 default = newJString("DeleteApplication"))
  if valid_773642 != nil:
    section.add "Action", valid_773642
  var valid_773643 = query.getOrDefault("Version")
  valid_773643 = validateParameter(valid_773643, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_773643 != nil:
    section.add "Version", valid_773643
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773644 = header.getOrDefault("X-Amz-Date")
  valid_773644 = validateParameter(valid_773644, JString, required = false,
                                 default = nil)
  if valid_773644 != nil:
    section.add "X-Amz-Date", valid_773644
  var valid_773645 = header.getOrDefault("X-Amz-Security-Token")
  valid_773645 = validateParameter(valid_773645, JString, required = false,
                                 default = nil)
  if valid_773645 != nil:
    section.add "X-Amz-Security-Token", valid_773645
  var valid_773646 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773646 = validateParameter(valid_773646, JString, required = false,
                                 default = nil)
  if valid_773646 != nil:
    section.add "X-Amz-Content-Sha256", valid_773646
  var valid_773647 = header.getOrDefault("X-Amz-Algorithm")
  valid_773647 = validateParameter(valid_773647, JString, required = false,
                                 default = nil)
  if valid_773647 != nil:
    section.add "X-Amz-Algorithm", valid_773647
  var valid_773648 = header.getOrDefault("X-Amz-Signature")
  valid_773648 = validateParameter(valid_773648, JString, required = false,
                                 default = nil)
  if valid_773648 != nil:
    section.add "X-Amz-Signature", valid_773648
  var valid_773649 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773649 = validateParameter(valid_773649, JString, required = false,
                                 default = nil)
  if valid_773649 != nil:
    section.add "X-Amz-SignedHeaders", valid_773649
  var valid_773650 = header.getOrDefault("X-Amz-Credential")
  valid_773650 = validateParameter(valid_773650, JString, required = false,
                                 default = nil)
  if valid_773650 != nil:
    section.add "X-Amz-Credential", valid_773650
  result.add "header", section
  ## parameters in `formData` object:
  ##   TerminateEnvByForce: JBool
  ##                      : When set to true, running environments will be terminated before deleting the application.
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to delete.
  section = newJObject()
  var valid_773651 = formData.getOrDefault("TerminateEnvByForce")
  valid_773651 = validateParameter(valid_773651, JBool, required = false, default = nil)
  if valid_773651 != nil:
    section.add "TerminateEnvByForce", valid_773651
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_773652 = formData.getOrDefault("ApplicationName")
  valid_773652 = validateParameter(valid_773652, JString, required = true,
                                 default = nil)
  if valid_773652 != nil:
    section.add "ApplicationName", valid_773652
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773653: Call_PostDeleteApplication_773639; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified application along with all associated versions and configurations. The application versions will not be deleted from your Amazon S3 bucket.</p> <note> <p>You cannot delete an application that has a running environment.</p> </note>
  ## 
  let valid = call_773653.validator(path, query, header, formData, body)
  let scheme = call_773653.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773653.url(scheme.get, call_773653.host, call_773653.base,
                         call_773653.route, valid.getOrDefault("path"))
  result = hook(call_773653, url, valid)

proc call*(call_773654: Call_PostDeleteApplication_773639; ApplicationName: string;
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
  var query_773655 = newJObject()
  var formData_773656 = newJObject()
  add(formData_773656, "TerminateEnvByForce", newJBool(TerminateEnvByForce))
  add(query_773655, "Action", newJString(Action))
  add(formData_773656, "ApplicationName", newJString(ApplicationName))
  add(query_773655, "Version", newJString(Version))
  result = call_773654.call(nil, query_773655, nil, formData_773656, nil)

var postDeleteApplication* = Call_PostDeleteApplication_773639(
    name: "postDeleteApplication", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=DeleteApplication",
    validator: validate_PostDeleteApplication_773640, base: "/",
    url: url_PostDeleteApplication_773641, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteApplication_773622 = ref object of OpenApiRestCall_772598
proc url_GetDeleteApplication_773624(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteApplication_773623(path: JsonNode; query: JsonNode;
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
  var valid_773625 = query.getOrDefault("TerminateEnvByForce")
  valid_773625 = validateParameter(valid_773625, JBool, required = false, default = nil)
  if valid_773625 != nil:
    section.add "TerminateEnvByForce", valid_773625
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_773626 = query.getOrDefault("ApplicationName")
  valid_773626 = validateParameter(valid_773626, JString, required = true,
                                 default = nil)
  if valid_773626 != nil:
    section.add "ApplicationName", valid_773626
  var valid_773627 = query.getOrDefault("Action")
  valid_773627 = validateParameter(valid_773627, JString, required = true,
                                 default = newJString("DeleteApplication"))
  if valid_773627 != nil:
    section.add "Action", valid_773627
  var valid_773628 = query.getOrDefault("Version")
  valid_773628 = validateParameter(valid_773628, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_773628 != nil:
    section.add "Version", valid_773628
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773629 = header.getOrDefault("X-Amz-Date")
  valid_773629 = validateParameter(valid_773629, JString, required = false,
                                 default = nil)
  if valid_773629 != nil:
    section.add "X-Amz-Date", valid_773629
  var valid_773630 = header.getOrDefault("X-Amz-Security-Token")
  valid_773630 = validateParameter(valid_773630, JString, required = false,
                                 default = nil)
  if valid_773630 != nil:
    section.add "X-Amz-Security-Token", valid_773630
  var valid_773631 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773631 = validateParameter(valid_773631, JString, required = false,
                                 default = nil)
  if valid_773631 != nil:
    section.add "X-Amz-Content-Sha256", valid_773631
  var valid_773632 = header.getOrDefault("X-Amz-Algorithm")
  valid_773632 = validateParameter(valid_773632, JString, required = false,
                                 default = nil)
  if valid_773632 != nil:
    section.add "X-Amz-Algorithm", valid_773632
  var valid_773633 = header.getOrDefault("X-Amz-Signature")
  valid_773633 = validateParameter(valid_773633, JString, required = false,
                                 default = nil)
  if valid_773633 != nil:
    section.add "X-Amz-Signature", valid_773633
  var valid_773634 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773634 = validateParameter(valid_773634, JString, required = false,
                                 default = nil)
  if valid_773634 != nil:
    section.add "X-Amz-SignedHeaders", valid_773634
  var valid_773635 = header.getOrDefault("X-Amz-Credential")
  valid_773635 = validateParameter(valid_773635, JString, required = false,
                                 default = nil)
  if valid_773635 != nil:
    section.add "X-Amz-Credential", valid_773635
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773636: Call_GetDeleteApplication_773622; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified application along with all associated versions and configurations. The application versions will not be deleted from your Amazon S3 bucket.</p> <note> <p>You cannot delete an application that has a running environment.</p> </note>
  ## 
  let valid = call_773636.validator(path, query, header, formData, body)
  let scheme = call_773636.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773636.url(scheme.get, call_773636.host, call_773636.base,
                         call_773636.route, valid.getOrDefault("path"))
  result = hook(call_773636, url, valid)

proc call*(call_773637: Call_GetDeleteApplication_773622; ApplicationName: string;
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
  var query_773638 = newJObject()
  add(query_773638, "TerminateEnvByForce", newJBool(TerminateEnvByForce))
  add(query_773638, "ApplicationName", newJString(ApplicationName))
  add(query_773638, "Action", newJString(Action))
  add(query_773638, "Version", newJString(Version))
  result = call_773637.call(nil, query_773638, nil, nil, nil)

var getDeleteApplication* = Call_GetDeleteApplication_773622(
    name: "getDeleteApplication", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=DeleteApplication",
    validator: validate_GetDeleteApplication_773623, base: "/",
    url: url_GetDeleteApplication_773624, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteApplicationVersion_773675 = ref object of OpenApiRestCall_772598
proc url_PostDeleteApplicationVersion_773677(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteApplicationVersion_773676(path: JsonNode; query: JsonNode;
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
  var valid_773678 = query.getOrDefault("Action")
  valid_773678 = validateParameter(valid_773678, JString, required = true, default = newJString(
      "DeleteApplicationVersion"))
  if valid_773678 != nil:
    section.add "Action", valid_773678
  var valid_773679 = query.getOrDefault("Version")
  valid_773679 = validateParameter(valid_773679, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_773679 != nil:
    section.add "Version", valid_773679
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773680 = header.getOrDefault("X-Amz-Date")
  valid_773680 = validateParameter(valid_773680, JString, required = false,
                                 default = nil)
  if valid_773680 != nil:
    section.add "X-Amz-Date", valid_773680
  var valid_773681 = header.getOrDefault("X-Amz-Security-Token")
  valid_773681 = validateParameter(valid_773681, JString, required = false,
                                 default = nil)
  if valid_773681 != nil:
    section.add "X-Amz-Security-Token", valid_773681
  var valid_773682 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773682 = validateParameter(valid_773682, JString, required = false,
                                 default = nil)
  if valid_773682 != nil:
    section.add "X-Amz-Content-Sha256", valid_773682
  var valid_773683 = header.getOrDefault("X-Amz-Algorithm")
  valid_773683 = validateParameter(valid_773683, JString, required = false,
                                 default = nil)
  if valid_773683 != nil:
    section.add "X-Amz-Algorithm", valid_773683
  var valid_773684 = header.getOrDefault("X-Amz-Signature")
  valid_773684 = validateParameter(valid_773684, JString, required = false,
                                 default = nil)
  if valid_773684 != nil:
    section.add "X-Amz-Signature", valid_773684
  var valid_773685 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773685 = validateParameter(valid_773685, JString, required = false,
                                 default = nil)
  if valid_773685 != nil:
    section.add "X-Amz-SignedHeaders", valid_773685
  var valid_773686 = header.getOrDefault("X-Amz-Credential")
  valid_773686 = validateParameter(valid_773686, JString, required = false,
                                 default = nil)
  if valid_773686 != nil:
    section.add "X-Amz-Credential", valid_773686
  result.add "header", section
  ## parameters in `formData` object:
  ##   DeleteSourceBundle: JBool
  ##                     : Set to <code>true</code> to delete the source bundle from your storage bucket. Otherwise, the application version is deleted only from Elastic Beanstalk and the source bundle remains in Amazon S3.
  ##   VersionLabel: JString (required)
  ##               : The label of the version to delete.
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to which the version belongs.
  section = newJObject()
  var valid_773687 = formData.getOrDefault("DeleteSourceBundle")
  valid_773687 = validateParameter(valid_773687, JBool, required = false, default = nil)
  if valid_773687 != nil:
    section.add "DeleteSourceBundle", valid_773687
  assert formData != nil,
        "formData argument is necessary due to required `VersionLabel` field"
  var valid_773688 = formData.getOrDefault("VersionLabel")
  valid_773688 = validateParameter(valid_773688, JString, required = true,
                                 default = nil)
  if valid_773688 != nil:
    section.add "VersionLabel", valid_773688
  var valid_773689 = formData.getOrDefault("ApplicationName")
  valid_773689 = validateParameter(valid_773689, JString, required = true,
                                 default = nil)
  if valid_773689 != nil:
    section.add "ApplicationName", valid_773689
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773690: Call_PostDeleteApplicationVersion_773675; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified version from the specified application.</p> <note> <p>You cannot delete an application version that is associated with a running environment.</p> </note>
  ## 
  let valid = call_773690.validator(path, query, header, formData, body)
  let scheme = call_773690.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773690.url(scheme.get, call_773690.host, call_773690.base,
                         call_773690.route, valid.getOrDefault("path"))
  result = hook(call_773690, url, valid)

proc call*(call_773691: Call_PostDeleteApplicationVersion_773675;
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
  var query_773692 = newJObject()
  var formData_773693 = newJObject()
  add(formData_773693, "DeleteSourceBundle", newJBool(DeleteSourceBundle))
  add(formData_773693, "VersionLabel", newJString(VersionLabel))
  add(query_773692, "Action", newJString(Action))
  add(formData_773693, "ApplicationName", newJString(ApplicationName))
  add(query_773692, "Version", newJString(Version))
  result = call_773691.call(nil, query_773692, nil, formData_773693, nil)

var postDeleteApplicationVersion* = Call_PostDeleteApplicationVersion_773675(
    name: "postDeleteApplicationVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteApplicationVersion",
    validator: validate_PostDeleteApplicationVersion_773676, base: "/",
    url: url_PostDeleteApplicationVersion_773677,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteApplicationVersion_773657 = ref object of OpenApiRestCall_772598
proc url_GetDeleteApplicationVersion_773659(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteApplicationVersion_773658(path: JsonNode; query: JsonNode;
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
  var valid_773660 = query.getOrDefault("VersionLabel")
  valid_773660 = validateParameter(valid_773660, JString, required = true,
                                 default = nil)
  if valid_773660 != nil:
    section.add "VersionLabel", valid_773660
  var valid_773661 = query.getOrDefault("ApplicationName")
  valid_773661 = validateParameter(valid_773661, JString, required = true,
                                 default = nil)
  if valid_773661 != nil:
    section.add "ApplicationName", valid_773661
  var valid_773662 = query.getOrDefault("Action")
  valid_773662 = validateParameter(valid_773662, JString, required = true, default = newJString(
      "DeleteApplicationVersion"))
  if valid_773662 != nil:
    section.add "Action", valid_773662
  var valid_773663 = query.getOrDefault("DeleteSourceBundle")
  valid_773663 = validateParameter(valid_773663, JBool, required = false, default = nil)
  if valid_773663 != nil:
    section.add "DeleteSourceBundle", valid_773663
  var valid_773664 = query.getOrDefault("Version")
  valid_773664 = validateParameter(valid_773664, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_773664 != nil:
    section.add "Version", valid_773664
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773665 = header.getOrDefault("X-Amz-Date")
  valid_773665 = validateParameter(valid_773665, JString, required = false,
                                 default = nil)
  if valid_773665 != nil:
    section.add "X-Amz-Date", valid_773665
  var valid_773666 = header.getOrDefault("X-Amz-Security-Token")
  valid_773666 = validateParameter(valid_773666, JString, required = false,
                                 default = nil)
  if valid_773666 != nil:
    section.add "X-Amz-Security-Token", valid_773666
  var valid_773667 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773667 = validateParameter(valid_773667, JString, required = false,
                                 default = nil)
  if valid_773667 != nil:
    section.add "X-Amz-Content-Sha256", valid_773667
  var valid_773668 = header.getOrDefault("X-Amz-Algorithm")
  valid_773668 = validateParameter(valid_773668, JString, required = false,
                                 default = nil)
  if valid_773668 != nil:
    section.add "X-Amz-Algorithm", valid_773668
  var valid_773669 = header.getOrDefault("X-Amz-Signature")
  valid_773669 = validateParameter(valid_773669, JString, required = false,
                                 default = nil)
  if valid_773669 != nil:
    section.add "X-Amz-Signature", valid_773669
  var valid_773670 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773670 = validateParameter(valid_773670, JString, required = false,
                                 default = nil)
  if valid_773670 != nil:
    section.add "X-Amz-SignedHeaders", valid_773670
  var valid_773671 = header.getOrDefault("X-Amz-Credential")
  valid_773671 = validateParameter(valid_773671, JString, required = false,
                                 default = nil)
  if valid_773671 != nil:
    section.add "X-Amz-Credential", valid_773671
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773672: Call_GetDeleteApplicationVersion_773657; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified version from the specified application.</p> <note> <p>You cannot delete an application version that is associated with a running environment.</p> </note>
  ## 
  let valid = call_773672.validator(path, query, header, formData, body)
  let scheme = call_773672.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773672.url(scheme.get, call_773672.host, call_773672.base,
                         call_773672.route, valid.getOrDefault("path"))
  result = hook(call_773672, url, valid)

proc call*(call_773673: Call_GetDeleteApplicationVersion_773657;
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
  var query_773674 = newJObject()
  add(query_773674, "VersionLabel", newJString(VersionLabel))
  add(query_773674, "ApplicationName", newJString(ApplicationName))
  add(query_773674, "Action", newJString(Action))
  add(query_773674, "DeleteSourceBundle", newJBool(DeleteSourceBundle))
  add(query_773674, "Version", newJString(Version))
  result = call_773673.call(nil, query_773674, nil, nil, nil)

var getDeleteApplicationVersion* = Call_GetDeleteApplicationVersion_773657(
    name: "getDeleteApplicationVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteApplicationVersion",
    validator: validate_GetDeleteApplicationVersion_773658, base: "/",
    url: url_GetDeleteApplicationVersion_773659,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteConfigurationTemplate_773711 = ref object of OpenApiRestCall_772598
proc url_PostDeleteConfigurationTemplate_773713(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteConfigurationTemplate_773712(path: JsonNode;
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
  var valid_773714 = query.getOrDefault("Action")
  valid_773714 = validateParameter(valid_773714, JString, required = true, default = newJString(
      "DeleteConfigurationTemplate"))
  if valid_773714 != nil:
    section.add "Action", valid_773714
  var valid_773715 = query.getOrDefault("Version")
  valid_773715 = validateParameter(valid_773715, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_773715 != nil:
    section.add "Version", valid_773715
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773716 = header.getOrDefault("X-Amz-Date")
  valid_773716 = validateParameter(valid_773716, JString, required = false,
                                 default = nil)
  if valid_773716 != nil:
    section.add "X-Amz-Date", valid_773716
  var valid_773717 = header.getOrDefault("X-Amz-Security-Token")
  valid_773717 = validateParameter(valid_773717, JString, required = false,
                                 default = nil)
  if valid_773717 != nil:
    section.add "X-Amz-Security-Token", valid_773717
  var valid_773718 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773718 = validateParameter(valid_773718, JString, required = false,
                                 default = nil)
  if valid_773718 != nil:
    section.add "X-Amz-Content-Sha256", valid_773718
  var valid_773719 = header.getOrDefault("X-Amz-Algorithm")
  valid_773719 = validateParameter(valid_773719, JString, required = false,
                                 default = nil)
  if valid_773719 != nil:
    section.add "X-Amz-Algorithm", valid_773719
  var valid_773720 = header.getOrDefault("X-Amz-Signature")
  valid_773720 = validateParameter(valid_773720, JString, required = false,
                                 default = nil)
  if valid_773720 != nil:
    section.add "X-Amz-Signature", valid_773720
  var valid_773721 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773721 = validateParameter(valid_773721, JString, required = false,
                                 default = nil)
  if valid_773721 != nil:
    section.add "X-Amz-SignedHeaders", valid_773721
  var valid_773722 = header.getOrDefault("X-Amz-Credential")
  valid_773722 = validateParameter(valid_773722, JString, required = false,
                                 default = nil)
  if valid_773722 != nil:
    section.add "X-Amz-Credential", valid_773722
  result.add "header", section
  ## parameters in `formData` object:
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to delete the configuration template from.
  ##   TemplateName: JString (required)
  ##               : The name of the configuration template to delete.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_773723 = formData.getOrDefault("ApplicationName")
  valid_773723 = validateParameter(valid_773723, JString, required = true,
                                 default = nil)
  if valid_773723 != nil:
    section.add "ApplicationName", valid_773723
  var valid_773724 = formData.getOrDefault("TemplateName")
  valid_773724 = validateParameter(valid_773724, JString, required = true,
                                 default = nil)
  if valid_773724 != nil:
    section.add "TemplateName", valid_773724
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773725: Call_PostDeleteConfigurationTemplate_773711;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes the specified configuration template.</p> <note> <p>When you launch an environment using a configuration template, the environment gets a copy of the template. You can delete or modify the environment's copy of the template without affecting the running environment.</p> </note>
  ## 
  let valid = call_773725.validator(path, query, header, formData, body)
  let scheme = call_773725.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773725.url(scheme.get, call_773725.host, call_773725.base,
                         call_773725.route, valid.getOrDefault("path"))
  result = hook(call_773725, url, valid)

proc call*(call_773726: Call_PostDeleteConfigurationTemplate_773711;
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
  var query_773727 = newJObject()
  var formData_773728 = newJObject()
  add(query_773727, "Action", newJString(Action))
  add(formData_773728, "ApplicationName", newJString(ApplicationName))
  add(formData_773728, "TemplateName", newJString(TemplateName))
  add(query_773727, "Version", newJString(Version))
  result = call_773726.call(nil, query_773727, nil, formData_773728, nil)

var postDeleteConfigurationTemplate* = Call_PostDeleteConfigurationTemplate_773711(
    name: "postDeleteConfigurationTemplate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteConfigurationTemplate",
    validator: validate_PostDeleteConfigurationTemplate_773712, base: "/",
    url: url_PostDeleteConfigurationTemplate_773713,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteConfigurationTemplate_773694 = ref object of OpenApiRestCall_772598
proc url_GetDeleteConfigurationTemplate_773696(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteConfigurationTemplate_773695(path: JsonNode;
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
  var valid_773697 = query.getOrDefault("ApplicationName")
  valid_773697 = validateParameter(valid_773697, JString, required = true,
                                 default = nil)
  if valid_773697 != nil:
    section.add "ApplicationName", valid_773697
  var valid_773698 = query.getOrDefault("Action")
  valid_773698 = validateParameter(valid_773698, JString, required = true, default = newJString(
      "DeleteConfigurationTemplate"))
  if valid_773698 != nil:
    section.add "Action", valid_773698
  var valid_773699 = query.getOrDefault("TemplateName")
  valid_773699 = validateParameter(valid_773699, JString, required = true,
                                 default = nil)
  if valid_773699 != nil:
    section.add "TemplateName", valid_773699
  var valid_773700 = query.getOrDefault("Version")
  valid_773700 = validateParameter(valid_773700, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_773700 != nil:
    section.add "Version", valid_773700
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773701 = header.getOrDefault("X-Amz-Date")
  valid_773701 = validateParameter(valid_773701, JString, required = false,
                                 default = nil)
  if valid_773701 != nil:
    section.add "X-Amz-Date", valid_773701
  var valid_773702 = header.getOrDefault("X-Amz-Security-Token")
  valid_773702 = validateParameter(valid_773702, JString, required = false,
                                 default = nil)
  if valid_773702 != nil:
    section.add "X-Amz-Security-Token", valid_773702
  var valid_773703 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773703 = validateParameter(valid_773703, JString, required = false,
                                 default = nil)
  if valid_773703 != nil:
    section.add "X-Amz-Content-Sha256", valid_773703
  var valid_773704 = header.getOrDefault("X-Amz-Algorithm")
  valid_773704 = validateParameter(valid_773704, JString, required = false,
                                 default = nil)
  if valid_773704 != nil:
    section.add "X-Amz-Algorithm", valid_773704
  var valid_773705 = header.getOrDefault("X-Amz-Signature")
  valid_773705 = validateParameter(valid_773705, JString, required = false,
                                 default = nil)
  if valid_773705 != nil:
    section.add "X-Amz-Signature", valid_773705
  var valid_773706 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773706 = validateParameter(valid_773706, JString, required = false,
                                 default = nil)
  if valid_773706 != nil:
    section.add "X-Amz-SignedHeaders", valid_773706
  var valid_773707 = header.getOrDefault("X-Amz-Credential")
  valid_773707 = validateParameter(valid_773707, JString, required = false,
                                 default = nil)
  if valid_773707 != nil:
    section.add "X-Amz-Credential", valid_773707
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773708: Call_GetDeleteConfigurationTemplate_773694; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified configuration template.</p> <note> <p>When you launch an environment using a configuration template, the environment gets a copy of the template. You can delete or modify the environment's copy of the template without affecting the running environment.</p> </note>
  ## 
  let valid = call_773708.validator(path, query, header, formData, body)
  let scheme = call_773708.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773708.url(scheme.get, call_773708.host, call_773708.base,
                         call_773708.route, valid.getOrDefault("path"))
  result = hook(call_773708, url, valid)

proc call*(call_773709: Call_GetDeleteConfigurationTemplate_773694;
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
  var query_773710 = newJObject()
  add(query_773710, "ApplicationName", newJString(ApplicationName))
  add(query_773710, "Action", newJString(Action))
  add(query_773710, "TemplateName", newJString(TemplateName))
  add(query_773710, "Version", newJString(Version))
  result = call_773709.call(nil, query_773710, nil, nil, nil)

var getDeleteConfigurationTemplate* = Call_GetDeleteConfigurationTemplate_773694(
    name: "getDeleteConfigurationTemplate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteConfigurationTemplate",
    validator: validate_GetDeleteConfigurationTemplate_773695, base: "/",
    url: url_GetDeleteConfigurationTemplate_773696,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEnvironmentConfiguration_773746 = ref object of OpenApiRestCall_772598
proc url_PostDeleteEnvironmentConfiguration_773748(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteEnvironmentConfiguration_773747(path: JsonNode;
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
  var valid_773749 = query.getOrDefault("Action")
  valid_773749 = validateParameter(valid_773749, JString, required = true, default = newJString(
      "DeleteEnvironmentConfiguration"))
  if valid_773749 != nil:
    section.add "Action", valid_773749
  var valid_773750 = query.getOrDefault("Version")
  valid_773750 = validateParameter(valid_773750, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_773750 != nil:
    section.add "Version", valid_773750
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773751 = header.getOrDefault("X-Amz-Date")
  valid_773751 = validateParameter(valid_773751, JString, required = false,
                                 default = nil)
  if valid_773751 != nil:
    section.add "X-Amz-Date", valid_773751
  var valid_773752 = header.getOrDefault("X-Amz-Security-Token")
  valid_773752 = validateParameter(valid_773752, JString, required = false,
                                 default = nil)
  if valid_773752 != nil:
    section.add "X-Amz-Security-Token", valid_773752
  var valid_773753 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773753 = validateParameter(valid_773753, JString, required = false,
                                 default = nil)
  if valid_773753 != nil:
    section.add "X-Amz-Content-Sha256", valid_773753
  var valid_773754 = header.getOrDefault("X-Amz-Algorithm")
  valid_773754 = validateParameter(valid_773754, JString, required = false,
                                 default = nil)
  if valid_773754 != nil:
    section.add "X-Amz-Algorithm", valid_773754
  var valid_773755 = header.getOrDefault("X-Amz-Signature")
  valid_773755 = validateParameter(valid_773755, JString, required = false,
                                 default = nil)
  if valid_773755 != nil:
    section.add "X-Amz-Signature", valid_773755
  var valid_773756 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773756 = validateParameter(valid_773756, JString, required = false,
                                 default = nil)
  if valid_773756 != nil:
    section.add "X-Amz-SignedHeaders", valid_773756
  var valid_773757 = header.getOrDefault("X-Amz-Credential")
  valid_773757 = validateParameter(valid_773757, JString, required = false,
                                 default = nil)
  if valid_773757 != nil:
    section.add "X-Amz-Credential", valid_773757
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString (required)
  ##                  : The name of the environment to delete the draft configuration from.
  ##   ApplicationName: JString (required)
  ##                  : The name of the application the environment is associated with.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `EnvironmentName` field"
  var valid_773758 = formData.getOrDefault("EnvironmentName")
  valid_773758 = validateParameter(valid_773758, JString, required = true,
                                 default = nil)
  if valid_773758 != nil:
    section.add "EnvironmentName", valid_773758
  var valid_773759 = formData.getOrDefault("ApplicationName")
  valid_773759 = validateParameter(valid_773759, JString, required = true,
                                 default = nil)
  if valid_773759 != nil:
    section.add "ApplicationName", valid_773759
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773760: Call_PostDeleteEnvironmentConfiguration_773746;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes the draft configuration associated with the running environment.</p> <p>Updating a running environment with any configuration changes creates a draft configuration set. You can get the draft configuration using <a>DescribeConfigurationSettings</a> while the update is in progress or if the update fails. The <code>DeploymentStatus</code> for the draft configuration indicates whether the deployment is in process or has failed. The draft configuration remains in existence until it is deleted with this action.</p>
  ## 
  let valid = call_773760.validator(path, query, header, formData, body)
  let scheme = call_773760.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773760.url(scheme.get, call_773760.host, call_773760.base,
                         call_773760.route, valid.getOrDefault("path"))
  result = hook(call_773760, url, valid)

proc call*(call_773761: Call_PostDeleteEnvironmentConfiguration_773746;
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
  var query_773762 = newJObject()
  var formData_773763 = newJObject()
  add(formData_773763, "EnvironmentName", newJString(EnvironmentName))
  add(query_773762, "Action", newJString(Action))
  add(formData_773763, "ApplicationName", newJString(ApplicationName))
  add(query_773762, "Version", newJString(Version))
  result = call_773761.call(nil, query_773762, nil, formData_773763, nil)

var postDeleteEnvironmentConfiguration* = Call_PostDeleteEnvironmentConfiguration_773746(
    name: "postDeleteEnvironmentConfiguration", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteEnvironmentConfiguration",
    validator: validate_PostDeleteEnvironmentConfiguration_773747, base: "/",
    url: url_PostDeleteEnvironmentConfiguration_773748,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEnvironmentConfiguration_773729 = ref object of OpenApiRestCall_772598
proc url_GetDeleteEnvironmentConfiguration_773731(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteEnvironmentConfiguration_773730(path: JsonNode;
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
  var valid_773732 = query.getOrDefault("ApplicationName")
  valid_773732 = validateParameter(valid_773732, JString, required = true,
                                 default = nil)
  if valid_773732 != nil:
    section.add "ApplicationName", valid_773732
  var valid_773733 = query.getOrDefault("EnvironmentName")
  valid_773733 = validateParameter(valid_773733, JString, required = true,
                                 default = nil)
  if valid_773733 != nil:
    section.add "EnvironmentName", valid_773733
  var valid_773734 = query.getOrDefault("Action")
  valid_773734 = validateParameter(valid_773734, JString, required = true, default = newJString(
      "DeleteEnvironmentConfiguration"))
  if valid_773734 != nil:
    section.add "Action", valid_773734
  var valid_773735 = query.getOrDefault("Version")
  valid_773735 = validateParameter(valid_773735, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_773735 != nil:
    section.add "Version", valid_773735
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773736 = header.getOrDefault("X-Amz-Date")
  valid_773736 = validateParameter(valid_773736, JString, required = false,
                                 default = nil)
  if valid_773736 != nil:
    section.add "X-Amz-Date", valid_773736
  var valid_773737 = header.getOrDefault("X-Amz-Security-Token")
  valid_773737 = validateParameter(valid_773737, JString, required = false,
                                 default = nil)
  if valid_773737 != nil:
    section.add "X-Amz-Security-Token", valid_773737
  var valid_773738 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773738 = validateParameter(valid_773738, JString, required = false,
                                 default = nil)
  if valid_773738 != nil:
    section.add "X-Amz-Content-Sha256", valid_773738
  var valid_773739 = header.getOrDefault("X-Amz-Algorithm")
  valid_773739 = validateParameter(valid_773739, JString, required = false,
                                 default = nil)
  if valid_773739 != nil:
    section.add "X-Amz-Algorithm", valid_773739
  var valid_773740 = header.getOrDefault("X-Amz-Signature")
  valid_773740 = validateParameter(valid_773740, JString, required = false,
                                 default = nil)
  if valid_773740 != nil:
    section.add "X-Amz-Signature", valid_773740
  var valid_773741 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773741 = validateParameter(valid_773741, JString, required = false,
                                 default = nil)
  if valid_773741 != nil:
    section.add "X-Amz-SignedHeaders", valid_773741
  var valid_773742 = header.getOrDefault("X-Amz-Credential")
  valid_773742 = validateParameter(valid_773742, JString, required = false,
                                 default = nil)
  if valid_773742 != nil:
    section.add "X-Amz-Credential", valid_773742
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773743: Call_GetDeleteEnvironmentConfiguration_773729;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes the draft configuration associated with the running environment.</p> <p>Updating a running environment with any configuration changes creates a draft configuration set. You can get the draft configuration using <a>DescribeConfigurationSettings</a> while the update is in progress or if the update fails. The <code>DeploymentStatus</code> for the draft configuration indicates whether the deployment is in process or has failed. The draft configuration remains in existence until it is deleted with this action.</p>
  ## 
  let valid = call_773743.validator(path, query, header, formData, body)
  let scheme = call_773743.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773743.url(scheme.get, call_773743.host, call_773743.base,
                         call_773743.route, valid.getOrDefault("path"))
  result = hook(call_773743, url, valid)

proc call*(call_773744: Call_GetDeleteEnvironmentConfiguration_773729;
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
  var query_773745 = newJObject()
  add(query_773745, "ApplicationName", newJString(ApplicationName))
  add(query_773745, "EnvironmentName", newJString(EnvironmentName))
  add(query_773745, "Action", newJString(Action))
  add(query_773745, "Version", newJString(Version))
  result = call_773744.call(nil, query_773745, nil, nil, nil)

var getDeleteEnvironmentConfiguration* = Call_GetDeleteEnvironmentConfiguration_773729(
    name: "getDeleteEnvironmentConfiguration", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteEnvironmentConfiguration",
    validator: validate_GetDeleteEnvironmentConfiguration_773730, base: "/",
    url: url_GetDeleteEnvironmentConfiguration_773731,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeletePlatformVersion_773780 = ref object of OpenApiRestCall_772598
proc url_PostDeletePlatformVersion_773782(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeletePlatformVersion_773781(path: JsonNode; query: JsonNode;
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
  var valid_773783 = query.getOrDefault("Action")
  valid_773783 = validateParameter(valid_773783, JString, required = true,
                                 default = newJString("DeletePlatformVersion"))
  if valid_773783 != nil:
    section.add "Action", valid_773783
  var valid_773784 = query.getOrDefault("Version")
  valid_773784 = validateParameter(valid_773784, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_773784 != nil:
    section.add "Version", valid_773784
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773785 = header.getOrDefault("X-Amz-Date")
  valid_773785 = validateParameter(valid_773785, JString, required = false,
                                 default = nil)
  if valid_773785 != nil:
    section.add "X-Amz-Date", valid_773785
  var valid_773786 = header.getOrDefault("X-Amz-Security-Token")
  valid_773786 = validateParameter(valid_773786, JString, required = false,
                                 default = nil)
  if valid_773786 != nil:
    section.add "X-Amz-Security-Token", valid_773786
  var valid_773787 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773787 = validateParameter(valid_773787, JString, required = false,
                                 default = nil)
  if valid_773787 != nil:
    section.add "X-Amz-Content-Sha256", valid_773787
  var valid_773788 = header.getOrDefault("X-Amz-Algorithm")
  valid_773788 = validateParameter(valid_773788, JString, required = false,
                                 default = nil)
  if valid_773788 != nil:
    section.add "X-Amz-Algorithm", valid_773788
  var valid_773789 = header.getOrDefault("X-Amz-Signature")
  valid_773789 = validateParameter(valid_773789, JString, required = false,
                                 default = nil)
  if valid_773789 != nil:
    section.add "X-Amz-Signature", valid_773789
  var valid_773790 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773790 = validateParameter(valid_773790, JString, required = false,
                                 default = nil)
  if valid_773790 != nil:
    section.add "X-Amz-SignedHeaders", valid_773790
  var valid_773791 = header.getOrDefault("X-Amz-Credential")
  valid_773791 = validateParameter(valid_773791, JString, required = false,
                                 default = nil)
  if valid_773791 != nil:
    section.add "X-Amz-Credential", valid_773791
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformArn: JString
  ##              : The ARN of the version of the custom platform.
  section = newJObject()
  var valid_773792 = formData.getOrDefault("PlatformArn")
  valid_773792 = validateParameter(valid_773792, JString, required = false,
                                 default = nil)
  if valid_773792 != nil:
    section.add "PlatformArn", valid_773792
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773793: Call_PostDeletePlatformVersion_773780; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified version of a custom platform.
  ## 
  let valid = call_773793.validator(path, query, header, formData, body)
  let scheme = call_773793.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773793.url(scheme.get, call_773793.host, call_773793.base,
                         call_773793.route, valid.getOrDefault("path"))
  result = hook(call_773793, url, valid)

proc call*(call_773794: Call_PostDeletePlatformVersion_773780;
          Action: string = "DeletePlatformVersion"; PlatformArn: string = "";
          Version: string = "2010-12-01"): Recallable =
  ## postDeletePlatformVersion
  ## Deletes the specified version of a custom platform.
  ##   Action: string (required)
  ##   PlatformArn: string
  ##              : The ARN of the version of the custom platform.
  ##   Version: string (required)
  var query_773795 = newJObject()
  var formData_773796 = newJObject()
  add(query_773795, "Action", newJString(Action))
  add(formData_773796, "PlatformArn", newJString(PlatformArn))
  add(query_773795, "Version", newJString(Version))
  result = call_773794.call(nil, query_773795, nil, formData_773796, nil)

var postDeletePlatformVersion* = Call_PostDeletePlatformVersion_773780(
    name: "postDeletePlatformVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeletePlatformVersion",
    validator: validate_PostDeletePlatformVersion_773781, base: "/",
    url: url_PostDeletePlatformVersion_773782,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeletePlatformVersion_773764 = ref object of OpenApiRestCall_772598
proc url_GetDeletePlatformVersion_773766(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeletePlatformVersion_773765(path: JsonNode; query: JsonNode;
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
  var valid_773767 = query.getOrDefault("PlatformArn")
  valid_773767 = validateParameter(valid_773767, JString, required = false,
                                 default = nil)
  if valid_773767 != nil:
    section.add "PlatformArn", valid_773767
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773768 = query.getOrDefault("Action")
  valid_773768 = validateParameter(valid_773768, JString, required = true,
                                 default = newJString("DeletePlatformVersion"))
  if valid_773768 != nil:
    section.add "Action", valid_773768
  var valid_773769 = query.getOrDefault("Version")
  valid_773769 = validateParameter(valid_773769, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_773769 != nil:
    section.add "Version", valid_773769
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773770 = header.getOrDefault("X-Amz-Date")
  valid_773770 = validateParameter(valid_773770, JString, required = false,
                                 default = nil)
  if valid_773770 != nil:
    section.add "X-Amz-Date", valid_773770
  var valid_773771 = header.getOrDefault("X-Amz-Security-Token")
  valid_773771 = validateParameter(valid_773771, JString, required = false,
                                 default = nil)
  if valid_773771 != nil:
    section.add "X-Amz-Security-Token", valid_773771
  var valid_773772 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773772 = validateParameter(valid_773772, JString, required = false,
                                 default = nil)
  if valid_773772 != nil:
    section.add "X-Amz-Content-Sha256", valid_773772
  var valid_773773 = header.getOrDefault("X-Amz-Algorithm")
  valid_773773 = validateParameter(valid_773773, JString, required = false,
                                 default = nil)
  if valid_773773 != nil:
    section.add "X-Amz-Algorithm", valid_773773
  var valid_773774 = header.getOrDefault("X-Amz-Signature")
  valid_773774 = validateParameter(valid_773774, JString, required = false,
                                 default = nil)
  if valid_773774 != nil:
    section.add "X-Amz-Signature", valid_773774
  var valid_773775 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773775 = validateParameter(valid_773775, JString, required = false,
                                 default = nil)
  if valid_773775 != nil:
    section.add "X-Amz-SignedHeaders", valid_773775
  var valid_773776 = header.getOrDefault("X-Amz-Credential")
  valid_773776 = validateParameter(valid_773776, JString, required = false,
                                 default = nil)
  if valid_773776 != nil:
    section.add "X-Amz-Credential", valid_773776
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773777: Call_GetDeletePlatformVersion_773764; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified version of a custom platform.
  ## 
  let valid = call_773777.validator(path, query, header, formData, body)
  let scheme = call_773777.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773777.url(scheme.get, call_773777.host, call_773777.base,
                         call_773777.route, valid.getOrDefault("path"))
  result = hook(call_773777, url, valid)

proc call*(call_773778: Call_GetDeletePlatformVersion_773764;
          PlatformArn: string = ""; Action: string = "DeletePlatformVersion";
          Version: string = "2010-12-01"): Recallable =
  ## getDeletePlatformVersion
  ## Deletes the specified version of a custom platform.
  ##   PlatformArn: string
  ##              : The ARN of the version of the custom platform.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773779 = newJObject()
  add(query_773779, "PlatformArn", newJString(PlatformArn))
  add(query_773779, "Action", newJString(Action))
  add(query_773779, "Version", newJString(Version))
  result = call_773778.call(nil, query_773779, nil, nil, nil)

var getDeletePlatformVersion* = Call_GetDeletePlatformVersion_773764(
    name: "getDeletePlatformVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeletePlatformVersion",
    validator: validate_GetDeletePlatformVersion_773765, base: "/",
    url: url_GetDeletePlatformVersion_773766, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAccountAttributes_773812 = ref object of OpenApiRestCall_772598
proc url_PostDescribeAccountAttributes_773814(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeAccountAttributes_773813(path: JsonNode; query: JsonNode;
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
  var valid_773815 = query.getOrDefault("Action")
  valid_773815 = validateParameter(valid_773815, JString, required = true, default = newJString(
      "DescribeAccountAttributes"))
  if valid_773815 != nil:
    section.add "Action", valid_773815
  var valid_773816 = query.getOrDefault("Version")
  valid_773816 = validateParameter(valid_773816, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_773816 != nil:
    section.add "Version", valid_773816
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773817 = header.getOrDefault("X-Amz-Date")
  valid_773817 = validateParameter(valid_773817, JString, required = false,
                                 default = nil)
  if valid_773817 != nil:
    section.add "X-Amz-Date", valid_773817
  var valid_773818 = header.getOrDefault("X-Amz-Security-Token")
  valid_773818 = validateParameter(valid_773818, JString, required = false,
                                 default = nil)
  if valid_773818 != nil:
    section.add "X-Amz-Security-Token", valid_773818
  var valid_773819 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773819 = validateParameter(valid_773819, JString, required = false,
                                 default = nil)
  if valid_773819 != nil:
    section.add "X-Amz-Content-Sha256", valid_773819
  var valid_773820 = header.getOrDefault("X-Amz-Algorithm")
  valid_773820 = validateParameter(valid_773820, JString, required = false,
                                 default = nil)
  if valid_773820 != nil:
    section.add "X-Amz-Algorithm", valid_773820
  var valid_773821 = header.getOrDefault("X-Amz-Signature")
  valid_773821 = validateParameter(valid_773821, JString, required = false,
                                 default = nil)
  if valid_773821 != nil:
    section.add "X-Amz-Signature", valid_773821
  var valid_773822 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773822 = validateParameter(valid_773822, JString, required = false,
                                 default = nil)
  if valid_773822 != nil:
    section.add "X-Amz-SignedHeaders", valid_773822
  var valid_773823 = header.getOrDefault("X-Amz-Credential")
  valid_773823 = validateParameter(valid_773823, JString, required = false,
                                 default = nil)
  if valid_773823 != nil:
    section.add "X-Amz-Credential", valid_773823
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773824: Call_PostDescribeAccountAttributes_773812; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ## 
  let valid = call_773824.validator(path, query, header, formData, body)
  let scheme = call_773824.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773824.url(scheme.get, call_773824.host, call_773824.base,
                         call_773824.route, valid.getOrDefault("path"))
  result = hook(call_773824, url, valid)

proc call*(call_773825: Call_PostDescribeAccountAttributes_773812;
          Action: string = "DescribeAccountAttributes";
          Version: string = "2010-12-01"): Recallable =
  ## postDescribeAccountAttributes
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773826 = newJObject()
  add(query_773826, "Action", newJString(Action))
  add(query_773826, "Version", newJString(Version))
  result = call_773825.call(nil, query_773826, nil, nil, nil)

var postDescribeAccountAttributes* = Call_PostDescribeAccountAttributes_773812(
    name: "postDescribeAccountAttributes", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeAccountAttributes",
    validator: validate_PostDescribeAccountAttributes_773813, base: "/",
    url: url_PostDescribeAccountAttributes_773814,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAccountAttributes_773797 = ref object of OpenApiRestCall_772598
proc url_GetDescribeAccountAttributes_773799(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeAccountAttributes_773798(path: JsonNode; query: JsonNode;
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
  var valid_773800 = query.getOrDefault("Action")
  valid_773800 = validateParameter(valid_773800, JString, required = true, default = newJString(
      "DescribeAccountAttributes"))
  if valid_773800 != nil:
    section.add "Action", valid_773800
  var valid_773801 = query.getOrDefault("Version")
  valid_773801 = validateParameter(valid_773801, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_773801 != nil:
    section.add "Version", valid_773801
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773802 = header.getOrDefault("X-Amz-Date")
  valid_773802 = validateParameter(valid_773802, JString, required = false,
                                 default = nil)
  if valid_773802 != nil:
    section.add "X-Amz-Date", valid_773802
  var valid_773803 = header.getOrDefault("X-Amz-Security-Token")
  valid_773803 = validateParameter(valid_773803, JString, required = false,
                                 default = nil)
  if valid_773803 != nil:
    section.add "X-Amz-Security-Token", valid_773803
  var valid_773804 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773804 = validateParameter(valid_773804, JString, required = false,
                                 default = nil)
  if valid_773804 != nil:
    section.add "X-Amz-Content-Sha256", valid_773804
  var valid_773805 = header.getOrDefault("X-Amz-Algorithm")
  valid_773805 = validateParameter(valid_773805, JString, required = false,
                                 default = nil)
  if valid_773805 != nil:
    section.add "X-Amz-Algorithm", valid_773805
  var valid_773806 = header.getOrDefault("X-Amz-Signature")
  valid_773806 = validateParameter(valid_773806, JString, required = false,
                                 default = nil)
  if valid_773806 != nil:
    section.add "X-Amz-Signature", valid_773806
  var valid_773807 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773807 = validateParameter(valid_773807, JString, required = false,
                                 default = nil)
  if valid_773807 != nil:
    section.add "X-Amz-SignedHeaders", valid_773807
  var valid_773808 = header.getOrDefault("X-Amz-Credential")
  valid_773808 = validateParameter(valid_773808, JString, required = false,
                                 default = nil)
  if valid_773808 != nil:
    section.add "X-Amz-Credential", valid_773808
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773809: Call_GetDescribeAccountAttributes_773797; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ## 
  let valid = call_773809.validator(path, query, header, formData, body)
  let scheme = call_773809.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773809.url(scheme.get, call_773809.host, call_773809.base,
                         call_773809.route, valid.getOrDefault("path"))
  result = hook(call_773809, url, valid)

proc call*(call_773810: Call_GetDescribeAccountAttributes_773797;
          Action: string = "DescribeAccountAttributes";
          Version: string = "2010-12-01"): Recallable =
  ## getDescribeAccountAttributes
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773811 = newJObject()
  add(query_773811, "Action", newJString(Action))
  add(query_773811, "Version", newJString(Version))
  result = call_773810.call(nil, query_773811, nil, nil, nil)

var getDescribeAccountAttributes* = Call_GetDescribeAccountAttributes_773797(
    name: "getDescribeAccountAttributes", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeAccountAttributes",
    validator: validate_GetDescribeAccountAttributes_773798, base: "/",
    url: url_GetDescribeAccountAttributes_773799,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeApplicationVersions_773846 = ref object of OpenApiRestCall_772598
proc url_PostDescribeApplicationVersions_773848(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeApplicationVersions_773847(path: JsonNode;
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
  var valid_773849 = query.getOrDefault("Action")
  valid_773849 = validateParameter(valid_773849, JString, required = true, default = newJString(
      "DescribeApplicationVersions"))
  if valid_773849 != nil:
    section.add "Action", valid_773849
  var valid_773850 = query.getOrDefault("Version")
  valid_773850 = validateParameter(valid_773850, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_773850 != nil:
    section.add "Version", valid_773850
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773851 = header.getOrDefault("X-Amz-Date")
  valid_773851 = validateParameter(valid_773851, JString, required = false,
                                 default = nil)
  if valid_773851 != nil:
    section.add "X-Amz-Date", valid_773851
  var valid_773852 = header.getOrDefault("X-Amz-Security-Token")
  valid_773852 = validateParameter(valid_773852, JString, required = false,
                                 default = nil)
  if valid_773852 != nil:
    section.add "X-Amz-Security-Token", valid_773852
  var valid_773853 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773853 = validateParameter(valid_773853, JString, required = false,
                                 default = nil)
  if valid_773853 != nil:
    section.add "X-Amz-Content-Sha256", valid_773853
  var valid_773854 = header.getOrDefault("X-Amz-Algorithm")
  valid_773854 = validateParameter(valid_773854, JString, required = false,
                                 default = nil)
  if valid_773854 != nil:
    section.add "X-Amz-Algorithm", valid_773854
  var valid_773855 = header.getOrDefault("X-Amz-Signature")
  valid_773855 = validateParameter(valid_773855, JString, required = false,
                                 default = nil)
  if valid_773855 != nil:
    section.add "X-Amz-Signature", valid_773855
  var valid_773856 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773856 = validateParameter(valid_773856, JString, required = false,
                                 default = nil)
  if valid_773856 != nil:
    section.add "X-Amz-SignedHeaders", valid_773856
  var valid_773857 = header.getOrDefault("X-Amz-Credential")
  valid_773857 = validateParameter(valid_773857, JString, required = false,
                                 default = nil)
  if valid_773857 != nil:
    section.add "X-Amz-Credential", valid_773857
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
  var valid_773858 = formData.getOrDefault("NextToken")
  valid_773858 = validateParameter(valid_773858, JString, required = false,
                                 default = nil)
  if valid_773858 != nil:
    section.add "NextToken", valid_773858
  var valid_773859 = formData.getOrDefault("ApplicationName")
  valid_773859 = validateParameter(valid_773859, JString, required = false,
                                 default = nil)
  if valid_773859 != nil:
    section.add "ApplicationName", valid_773859
  var valid_773860 = formData.getOrDefault("MaxRecords")
  valid_773860 = validateParameter(valid_773860, JInt, required = false, default = nil)
  if valid_773860 != nil:
    section.add "MaxRecords", valid_773860
  var valid_773861 = formData.getOrDefault("VersionLabels")
  valid_773861 = validateParameter(valid_773861, JArray, required = false,
                                 default = nil)
  if valid_773861 != nil:
    section.add "VersionLabels", valid_773861
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773862: Call_PostDescribeApplicationVersions_773846;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieve a list of application versions.
  ## 
  let valid = call_773862.validator(path, query, header, formData, body)
  let scheme = call_773862.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773862.url(scheme.get, call_773862.host, call_773862.base,
                         call_773862.route, valid.getOrDefault("path"))
  result = hook(call_773862, url, valid)

proc call*(call_773863: Call_PostDescribeApplicationVersions_773846;
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
  var query_773864 = newJObject()
  var formData_773865 = newJObject()
  add(formData_773865, "NextToken", newJString(NextToken))
  add(query_773864, "Action", newJString(Action))
  add(formData_773865, "ApplicationName", newJString(ApplicationName))
  add(formData_773865, "MaxRecords", newJInt(MaxRecords))
  add(query_773864, "Version", newJString(Version))
  if VersionLabels != nil:
    formData_773865.add "VersionLabels", VersionLabels
  result = call_773863.call(nil, query_773864, nil, formData_773865, nil)

var postDescribeApplicationVersions* = Call_PostDescribeApplicationVersions_773846(
    name: "postDescribeApplicationVersions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplicationVersions",
    validator: validate_PostDescribeApplicationVersions_773847, base: "/",
    url: url_PostDescribeApplicationVersions_773848,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeApplicationVersions_773827 = ref object of OpenApiRestCall_772598
proc url_GetDescribeApplicationVersions_773829(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeApplicationVersions_773828(path: JsonNode;
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
  var valid_773830 = query.getOrDefault("MaxRecords")
  valid_773830 = validateParameter(valid_773830, JInt, required = false, default = nil)
  if valid_773830 != nil:
    section.add "MaxRecords", valid_773830
  var valid_773831 = query.getOrDefault("ApplicationName")
  valid_773831 = validateParameter(valid_773831, JString, required = false,
                                 default = nil)
  if valid_773831 != nil:
    section.add "ApplicationName", valid_773831
  var valid_773832 = query.getOrDefault("NextToken")
  valid_773832 = validateParameter(valid_773832, JString, required = false,
                                 default = nil)
  if valid_773832 != nil:
    section.add "NextToken", valid_773832
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773833 = query.getOrDefault("Action")
  valid_773833 = validateParameter(valid_773833, JString, required = true, default = newJString(
      "DescribeApplicationVersions"))
  if valid_773833 != nil:
    section.add "Action", valid_773833
  var valid_773834 = query.getOrDefault("VersionLabels")
  valid_773834 = validateParameter(valid_773834, JArray, required = false,
                                 default = nil)
  if valid_773834 != nil:
    section.add "VersionLabels", valid_773834
  var valid_773835 = query.getOrDefault("Version")
  valid_773835 = validateParameter(valid_773835, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_773835 != nil:
    section.add "Version", valid_773835
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773836 = header.getOrDefault("X-Amz-Date")
  valid_773836 = validateParameter(valid_773836, JString, required = false,
                                 default = nil)
  if valid_773836 != nil:
    section.add "X-Amz-Date", valid_773836
  var valid_773837 = header.getOrDefault("X-Amz-Security-Token")
  valid_773837 = validateParameter(valid_773837, JString, required = false,
                                 default = nil)
  if valid_773837 != nil:
    section.add "X-Amz-Security-Token", valid_773837
  var valid_773838 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773838 = validateParameter(valid_773838, JString, required = false,
                                 default = nil)
  if valid_773838 != nil:
    section.add "X-Amz-Content-Sha256", valid_773838
  var valid_773839 = header.getOrDefault("X-Amz-Algorithm")
  valid_773839 = validateParameter(valid_773839, JString, required = false,
                                 default = nil)
  if valid_773839 != nil:
    section.add "X-Amz-Algorithm", valid_773839
  var valid_773840 = header.getOrDefault("X-Amz-Signature")
  valid_773840 = validateParameter(valid_773840, JString, required = false,
                                 default = nil)
  if valid_773840 != nil:
    section.add "X-Amz-Signature", valid_773840
  var valid_773841 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773841 = validateParameter(valid_773841, JString, required = false,
                                 default = nil)
  if valid_773841 != nil:
    section.add "X-Amz-SignedHeaders", valid_773841
  var valid_773842 = header.getOrDefault("X-Amz-Credential")
  valid_773842 = validateParameter(valid_773842, JString, required = false,
                                 default = nil)
  if valid_773842 != nil:
    section.add "X-Amz-Credential", valid_773842
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773843: Call_GetDescribeApplicationVersions_773827; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a list of application versions.
  ## 
  let valid = call_773843.validator(path, query, header, formData, body)
  let scheme = call_773843.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773843.url(scheme.get, call_773843.host, call_773843.base,
                         call_773843.route, valid.getOrDefault("path"))
  result = hook(call_773843, url, valid)

proc call*(call_773844: Call_GetDescribeApplicationVersions_773827;
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
  var query_773845 = newJObject()
  add(query_773845, "MaxRecords", newJInt(MaxRecords))
  add(query_773845, "ApplicationName", newJString(ApplicationName))
  add(query_773845, "NextToken", newJString(NextToken))
  add(query_773845, "Action", newJString(Action))
  if VersionLabels != nil:
    query_773845.add "VersionLabels", VersionLabels
  add(query_773845, "Version", newJString(Version))
  result = call_773844.call(nil, query_773845, nil, nil, nil)

var getDescribeApplicationVersions* = Call_GetDescribeApplicationVersions_773827(
    name: "getDescribeApplicationVersions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplicationVersions",
    validator: validate_GetDescribeApplicationVersions_773828, base: "/",
    url: url_GetDescribeApplicationVersions_773829,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeApplications_773882 = ref object of OpenApiRestCall_772598
proc url_PostDescribeApplications_773884(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeApplications_773883(path: JsonNode; query: JsonNode;
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
  var valid_773885 = query.getOrDefault("Action")
  valid_773885 = validateParameter(valid_773885, JString, required = true,
                                 default = newJString("DescribeApplications"))
  if valid_773885 != nil:
    section.add "Action", valid_773885
  var valid_773886 = query.getOrDefault("Version")
  valid_773886 = validateParameter(valid_773886, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_773886 != nil:
    section.add "Version", valid_773886
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773887 = header.getOrDefault("X-Amz-Date")
  valid_773887 = validateParameter(valid_773887, JString, required = false,
                                 default = nil)
  if valid_773887 != nil:
    section.add "X-Amz-Date", valid_773887
  var valid_773888 = header.getOrDefault("X-Amz-Security-Token")
  valid_773888 = validateParameter(valid_773888, JString, required = false,
                                 default = nil)
  if valid_773888 != nil:
    section.add "X-Amz-Security-Token", valid_773888
  var valid_773889 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773889 = validateParameter(valid_773889, JString, required = false,
                                 default = nil)
  if valid_773889 != nil:
    section.add "X-Amz-Content-Sha256", valid_773889
  var valid_773890 = header.getOrDefault("X-Amz-Algorithm")
  valid_773890 = validateParameter(valid_773890, JString, required = false,
                                 default = nil)
  if valid_773890 != nil:
    section.add "X-Amz-Algorithm", valid_773890
  var valid_773891 = header.getOrDefault("X-Amz-Signature")
  valid_773891 = validateParameter(valid_773891, JString, required = false,
                                 default = nil)
  if valid_773891 != nil:
    section.add "X-Amz-Signature", valid_773891
  var valid_773892 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773892 = validateParameter(valid_773892, JString, required = false,
                                 default = nil)
  if valid_773892 != nil:
    section.add "X-Amz-SignedHeaders", valid_773892
  var valid_773893 = header.getOrDefault("X-Amz-Credential")
  valid_773893 = validateParameter(valid_773893, JString, required = false,
                                 default = nil)
  if valid_773893 != nil:
    section.add "X-Amz-Credential", valid_773893
  result.add "header", section
  ## parameters in `formData` object:
  ##   ApplicationNames: JArray
  ##                   : If specified, AWS Elastic Beanstalk restricts the returned descriptions to only include those with the specified names.
  section = newJObject()
  var valid_773894 = formData.getOrDefault("ApplicationNames")
  valid_773894 = validateParameter(valid_773894, JArray, required = false,
                                 default = nil)
  if valid_773894 != nil:
    section.add "ApplicationNames", valid_773894
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773895: Call_PostDescribeApplications_773882; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the descriptions of existing applications.
  ## 
  let valid = call_773895.validator(path, query, header, formData, body)
  let scheme = call_773895.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773895.url(scheme.get, call_773895.host, call_773895.base,
                         call_773895.route, valid.getOrDefault("path"))
  result = hook(call_773895, url, valid)

proc call*(call_773896: Call_PostDescribeApplications_773882;
          ApplicationNames: JsonNode = nil; Action: string = "DescribeApplications";
          Version: string = "2010-12-01"): Recallable =
  ## postDescribeApplications
  ## Returns the descriptions of existing applications.
  ##   ApplicationNames: JArray
  ##                   : If specified, AWS Elastic Beanstalk restricts the returned descriptions to only include those with the specified names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773897 = newJObject()
  var formData_773898 = newJObject()
  if ApplicationNames != nil:
    formData_773898.add "ApplicationNames", ApplicationNames
  add(query_773897, "Action", newJString(Action))
  add(query_773897, "Version", newJString(Version))
  result = call_773896.call(nil, query_773897, nil, formData_773898, nil)

var postDescribeApplications* = Call_PostDescribeApplications_773882(
    name: "postDescribeApplications", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplications",
    validator: validate_PostDescribeApplications_773883, base: "/",
    url: url_PostDescribeApplications_773884, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeApplications_773866 = ref object of OpenApiRestCall_772598
proc url_GetDescribeApplications_773868(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeApplications_773867(path: JsonNode; query: JsonNode;
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
  var valid_773869 = query.getOrDefault("ApplicationNames")
  valid_773869 = validateParameter(valid_773869, JArray, required = false,
                                 default = nil)
  if valid_773869 != nil:
    section.add "ApplicationNames", valid_773869
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773870 = query.getOrDefault("Action")
  valid_773870 = validateParameter(valid_773870, JString, required = true,
                                 default = newJString("DescribeApplications"))
  if valid_773870 != nil:
    section.add "Action", valid_773870
  var valid_773871 = query.getOrDefault("Version")
  valid_773871 = validateParameter(valid_773871, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_773871 != nil:
    section.add "Version", valid_773871
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773872 = header.getOrDefault("X-Amz-Date")
  valid_773872 = validateParameter(valid_773872, JString, required = false,
                                 default = nil)
  if valid_773872 != nil:
    section.add "X-Amz-Date", valid_773872
  var valid_773873 = header.getOrDefault("X-Amz-Security-Token")
  valid_773873 = validateParameter(valid_773873, JString, required = false,
                                 default = nil)
  if valid_773873 != nil:
    section.add "X-Amz-Security-Token", valid_773873
  var valid_773874 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773874 = validateParameter(valid_773874, JString, required = false,
                                 default = nil)
  if valid_773874 != nil:
    section.add "X-Amz-Content-Sha256", valid_773874
  var valid_773875 = header.getOrDefault("X-Amz-Algorithm")
  valid_773875 = validateParameter(valid_773875, JString, required = false,
                                 default = nil)
  if valid_773875 != nil:
    section.add "X-Amz-Algorithm", valid_773875
  var valid_773876 = header.getOrDefault("X-Amz-Signature")
  valid_773876 = validateParameter(valid_773876, JString, required = false,
                                 default = nil)
  if valid_773876 != nil:
    section.add "X-Amz-Signature", valid_773876
  var valid_773877 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773877 = validateParameter(valid_773877, JString, required = false,
                                 default = nil)
  if valid_773877 != nil:
    section.add "X-Amz-SignedHeaders", valid_773877
  var valid_773878 = header.getOrDefault("X-Amz-Credential")
  valid_773878 = validateParameter(valid_773878, JString, required = false,
                                 default = nil)
  if valid_773878 != nil:
    section.add "X-Amz-Credential", valid_773878
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773879: Call_GetDescribeApplications_773866; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the descriptions of existing applications.
  ## 
  let valid = call_773879.validator(path, query, header, formData, body)
  let scheme = call_773879.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773879.url(scheme.get, call_773879.host, call_773879.base,
                         call_773879.route, valid.getOrDefault("path"))
  result = hook(call_773879, url, valid)

proc call*(call_773880: Call_GetDescribeApplications_773866;
          ApplicationNames: JsonNode = nil; Action: string = "DescribeApplications";
          Version: string = "2010-12-01"): Recallable =
  ## getDescribeApplications
  ## Returns the descriptions of existing applications.
  ##   ApplicationNames: JArray
  ##                   : If specified, AWS Elastic Beanstalk restricts the returned descriptions to only include those with the specified names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773881 = newJObject()
  if ApplicationNames != nil:
    query_773881.add "ApplicationNames", ApplicationNames
  add(query_773881, "Action", newJString(Action))
  add(query_773881, "Version", newJString(Version))
  result = call_773880.call(nil, query_773881, nil, nil, nil)

var getDescribeApplications* = Call_GetDescribeApplications_773866(
    name: "getDescribeApplications", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplications",
    validator: validate_GetDescribeApplications_773867, base: "/",
    url: url_GetDescribeApplications_773868, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeConfigurationOptions_773920 = ref object of OpenApiRestCall_772598
proc url_PostDescribeConfigurationOptions_773922(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeConfigurationOptions_773921(path: JsonNode;
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
  var valid_773923 = query.getOrDefault("Action")
  valid_773923 = validateParameter(valid_773923, JString, required = true, default = newJString(
      "DescribeConfigurationOptions"))
  if valid_773923 != nil:
    section.add "Action", valid_773923
  var valid_773924 = query.getOrDefault("Version")
  valid_773924 = validateParameter(valid_773924, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_773924 != nil:
    section.add "Version", valid_773924
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773925 = header.getOrDefault("X-Amz-Date")
  valid_773925 = validateParameter(valid_773925, JString, required = false,
                                 default = nil)
  if valid_773925 != nil:
    section.add "X-Amz-Date", valid_773925
  var valid_773926 = header.getOrDefault("X-Amz-Security-Token")
  valid_773926 = validateParameter(valid_773926, JString, required = false,
                                 default = nil)
  if valid_773926 != nil:
    section.add "X-Amz-Security-Token", valid_773926
  var valid_773927 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773927 = validateParameter(valid_773927, JString, required = false,
                                 default = nil)
  if valid_773927 != nil:
    section.add "X-Amz-Content-Sha256", valid_773927
  var valid_773928 = header.getOrDefault("X-Amz-Algorithm")
  valid_773928 = validateParameter(valid_773928, JString, required = false,
                                 default = nil)
  if valid_773928 != nil:
    section.add "X-Amz-Algorithm", valid_773928
  var valid_773929 = header.getOrDefault("X-Amz-Signature")
  valid_773929 = validateParameter(valid_773929, JString, required = false,
                                 default = nil)
  if valid_773929 != nil:
    section.add "X-Amz-Signature", valid_773929
  var valid_773930 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773930 = validateParameter(valid_773930, JString, required = false,
                                 default = nil)
  if valid_773930 != nil:
    section.add "X-Amz-SignedHeaders", valid_773930
  var valid_773931 = header.getOrDefault("X-Amz-Credential")
  valid_773931 = validateParameter(valid_773931, JString, required = false,
                                 default = nil)
  if valid_773931 != nil:
    section.add "X-Amz-Credential", valid_773931
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
  var valid_773932 = formData.getOrDefault("Options")
  valid_773932 = validateParameter(valid_773932, JArray, required = false,
                                 default = nil)
  if valid_773932 != nil:
    section.add "Options", valid_773932
  var valid_773933 = formData.getOrDefault("SolutionStackName")
  valid_773933 = validateParameter(valid_773933, JString, required = false,
                                 default = nil)
  if valid_773933 != nil:
    section.add "SolutionStackName", valid_773933
  var valid_773934 = formData.getOrDefault("EnvironmentName")
  valid_773934 = validateParameter(valid_773934, JString, required = false,
                                 default = nil)
  if valid_773934 != nil:
    section.add "EnvironmentName", valid_773934
  var valid_773935 = formData.getOrDefault("ApplicationName")
  valid_773935 = validateParameter(valid_773935, JString, required = false,
                                 default = nil)
  if valid_773935 != nil:
    section.add "ApplicationName", valid_773935
  var valid_773936 = formData.getOrDefault("PlatformArn")
  valid_773936 = validateParameter(valid_773936, JString, required = false,
                                 default = nil)
  if valid_773936 != nil:
    section.add "PlatformArn", valid_773936
  var valid_773937 = formData.getOrDefault("TemplateName")
  valid_773937 = validateParameter(valid_773937, JString, required = false,
                                 default = nil)
  if valid_773937 != nil:
    section.add "TemplateName", valid_773937
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773938: Call_PostDescribeConfigurationOptions_773920;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the configuration options that are used in a particular configuration template or environment, or that a specified solution stack defines. The description includes the values the options, their default values, and an indication of the required action on a running environment if an option value is changed.
  ## 
  let valid = call_773938.validator(path, query, header, formData, body)
  let scheme = call_773938.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773938.url(scheme.get, call_773938.host, call_773938.base,
                         call_773938.route, valid.getOrDefault("path"))
  result = hook(call_773938, url, valid)

proc call*(call_773939: Call_PostDescribeConfigurationOptions_773920;
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
  var query_773940 = newJObject()
  var formData_773941 = newJObject()
  if Options != nil:
    formData_773941.add "Options", Options
  add(formData_773941, "SolutionStackName", newJString(SolutionStackName))
  add(formData_773941, "EnvironmentName", newJString(EnvironmentName))
  add(query_773940, "Action", newJString(Action))
  add(formData_773941, "ApplicationName", newJString(ApplicationName))
  add(formData_773941, "PlatformArn", newJString(PlatformArn))
  add(formData_773941, "TemplateName", newJString(TemplateName))
  add(query_773940, "Version", newJString(Version))
  result = call_773939.call(nil, query_773940, nil, formData_773941, nil)

var postDescribeConfigurationOptions* = Call_PostDescribeConfigurationOptions_773920(
    name: "postDescribeConfigurationOptions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationOptions",
    validator: validate_PostDescribeConfigurationOptions_773921, base: "/",
    url: url_PostDescribeConfigurationOptions_773922,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeConfigurationOptions_773899 = ref object of OpenApiRestCall_772598
proc url_GetDescribeConfigurationOptions_773901(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeConfigurationOptions_773900(path: JsonNode;
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
  var valid_773902 = query.getOrDefault("Options")
  valid_773902 = validateParameter(valid_773902, JArray, required = false,
                                 default = nil)
  if valid_773902 != nil:
    section.add "Options", valid_773902
  var valid_773903 = query.getOrDefault("ApplicationName")
  valid_773903 = validateParameter(valid_773903, JString, required = false,
                                 default = nil)
  if valid_773903 != nil:
    section.add "ApplicationName", valid_773903
  var valid_773904 = query.getOrDefault("PlatformArn")
  valid_773904 = validateParameter(valid_773904, JString, required = false,
                                 default = nil)
  if valid_773904 != nil:
    section.add "PlatformArn", valid_773904
  var valid_773905 = query.getOrDefault("EnvironmentName")
  valid_773905 = validateParameter(valid_773905, JString, required = false,
                                 default = nil)
  if valid_773905 != nil:
    section.add "EnvironmentName", valid_773905
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773906 = query.getOrDefault("Action")
  valid_773906 = validateParameter(valid_773906, JString, required = true, default = newJString(
      "DescribeConfigurationOptions"))
  if valid_773906 != nil:
    section.add "Action", valid_773906
  var valid_773907 = query.getOrDefault("SolutionStackName")
  valid_773907 = validateParameter(valid_773907, JString, required = false,
                                 default = nil)
  if valid_773907 != nil:
    section.add "SolutionStackName", valid_773907
  var valid_773908 = query.getOrDefault("TemplateName")
  valid_773908 = validateParameter(valid_773908, JString, required = false,
                                 default = nil)
  if valid_773908 != nil:
    section.add "TemplateName", valid_773908
  var valid_773909 = query.getOrDefault("Version")
  valid_773909 = validateParameter(valid_773909, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_773909 != nil:
    section.add "Version", valid_773909
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773910 = header.getOrDefault("X-Amz-Date")
  valid_773910 = validateParameter(valid_773910, JString, required = false,
                                 default = nil)
  if valid_773910 != nil:
    section.add "X-Amz-Date", valid_773910
  var valid_773911 = header.getOrDefault("X-Amz-Security-Token")
  valid_773911 = validateParameter(valid_773911, JString, required = false,
                                 default = nil)
  if valid_773911 != nil:
    section.add "X-Amz-Security-Token", valid_773911
  var valid_773912 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773912 = validateParameter(valid_773912, JString, required = false,
                                 default = nil)
  if valid_773912 != nil:
    section.add "X-Amz-Content-Sha256", valid_773912
  var valid_773913 = header.getOrDefault("X-Amz-Algorithm")
  valid_773913 = validateParameter(valid_773913, JString, required = false,
                                 default = nil)
  if valid_773913 != nil:
    section.add "X-Amz-Algorithm", valid_773913
  var valid_773914 = header.getOrDefault("X-Amz-Signature")
  valid_773914 = validateParameter(valid_773914, JString, required = false,
                                 default = nil)
  if valid_773914 != nil:
    section.add "X-Amz-Signature", valid_773914
  var valid_773915 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773915 = validateParameter(valid_773915, JString, required = false,
                                 default = nil)
  if valid_773915 != nil:
    section.add "X-Amz-SignedHeaders", valid_773915
  var valid_773916 = header.getOrDefault("X-Amz-Credential")
  valid_773916 = validateParameter(valid_773916, JString, required = false,
                                 default = nil)
  if valid_773916 != nil:
    section.add "X-Amz-Credential", valid_773916
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773917: Call_GetDescribeConfigurationOptions_773899;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the configuration options that are used in a particular configuration template or environment, or that a specified solution stack defines. The description includes the values the options, their default values, and an indication of the required action on a running environment if an option value is changed.
  ## 
  let valid = call_773917.validator(path, query, header, formData, body)
  let scheme = call_773917.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773917.url(scheme.get, call_773917.host, call_773917.base,
                         call_773917.route, valid.getOrDefault("path"))
  result = hook(call_773917, url, valid)

proc call*(call_773918: Call_GetDescribeConfigurationOptions_773899;
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
  var query_773919 = newJObject()
  if Options != nil:
    query_773919.add "Options", Options
  add(query_773919, "ApplicationName", newJString(ApplicationName))
  add(query_773919, "PlatformArn", newJString(PlatformArn))
  add(query_773919, "EnvironmentName", newJString(EnvironmentName))
  add(query_773919, "Action", newJString(Action))
  add(query_773919, "SolutionStackName", newJString(SolutionStackName))
  add(query_773919, "TemplateName", newJString(TemplateName))
  add(query_773919, "Version", newJString(Version))
  result = call_773918.call(nil, query_773919, nil, nil, nil)

var getDescribeConfigurationOptions* = Call_GetDescribeConfigurationOptions_773899(
    name: "getDescribeConfigurationOptions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationOptions",
    validator: validate_GetDescribeConfigurationOptions_773900, base: "/",
    url: url_GetDescribeConfigurationOptions_773901,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeConfigurationSettings_773960 = ref object of OpenApiRestCall_772598
proc url_PostDescribeConfigurationSettings_773962(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeConfigurationSettings_773961(path: JsonNode;
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
  var valid_773963 = query.getOrDefault("Action")
  valid_773963 = validateParameter(valid_773963, JString, required = true, default = newJString(
      "DescribeConfigurationSettings"))
  if valid_773963 != nil:
    section.add "Action", valid_773963
  var valid_773964 = query.getOrDefault("Version")
  valid_773964 = validateParameter(valid_773964, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_773964 != nil:
    section.add "Version", valid_773964
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773965 = header.getOrDefault("X-Amz-Date")
  valid_773965 = validateParameter(valid_773965, JString, required = false,
                                 default = nil)
  if valid_773965 != nil:
    section.add "X-Amz-Date", valid_773965
  var valid_773966 = header.getOrDefault("X-Amz-Security-Token")
  valid_773966 = validateParameter(valid_773966, JString, required = false,
                                 default = nil)
  if valid_773966 != nil:
    section.add "X-Amz-Security-Token", valid_773966
  var valid_773967 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773967 = validateParameter(valid_773967, JString, required = false,
                                 default = nil)
  if valid_773967 != nil:
    section.add "X-Amz-Content-Sha256", valid_773967
  var valid_773968 = header.getOrDefault("X-Amz-Algorithm")
  valid_773968 = validateParameter(valid_773968, JString, required = false,
                                 default = nil)
  if valid_773968 != nil:
    section.add "X-Amz-Algorithm", valid_773968
  var valid_773969 = header.getOrDefault("X-Amz-Signature")
  valid_773969 = validateParameter(valid_773969, JString, required = false,
                                 default = nil)
  if valid_773969 != nil:
    section.add "X-Amz-Signature", valid_773969
  var valid_773970 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773970 = validateParameter(valid_773970, JString, required = false,
                                 default = nil)
  if valid_773970 != nil:
    section.add "X-Amz-SignedHeaders", valid_773970
  var valid_773971 = header.getOrDefault("X-Amz-Credential")
  valid_773971 = validateParameter(valid_773971, JString, required = false,
                                 default = nil)
  if valid_773971 != nil:
    section.add "X-Amz-Credential", valid_773971
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to describe.</p> <p> Condition: You must specify either this or a TemplateName, but not both. If you specify both, AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   ApplicationName: JString (required)
  ##                  : The application for the environment or configuration template.
  ##   TemplateName: JString
  ##               : <p>The name of the configuration template to describe.</p> <p> Conditional: You must specify either this parameter or an EnvironmentName, but not both. If you specify both, AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. If you do not specify either, AWS Elastic Beanstalk returns a <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_773972 = formData.getOrDefault("EnvironmentName")
  valid_773972 = validateParameter(valid_773972, JString, required = false,
                                 default = nil)
  if valid_773972 != nil:
    section.add "EnvironmentName", valid_773972
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_773973 = formData.getOrDefault("ApplicationName")
  valid_773973 = validateParameter(valid_773973, JString, required = true,
                                 default = nil)
  if valid_773973 != nil:
    section.add "ApplicationName", valid_773973
  var valid_773974 = formData.getOrDefault("TemplateName")
  valid_773974 = validateParameter(valid_773974, JString, required = false,
                                 default = nil)
  if valid_773974 != nil:
    section.add "TemplateName", valid_773974
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773975: Call_PostDescribeConfigurationSettings_773960;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a description of the settings for the specified configuration set, that is, either a configuration template or the configuration set associated with a running environment.</p> <p>When describing the settings for the configuration set associated with a running environment, it is possible to receive two sets of setting descriptions. One is the deployed configuration set, and the other is a draft configuration of an environment that is either in the process of deployment or that failed to deploy.</p> <p>Related Topics</p> <ul> <li> <p> <a>DeleteEnvironmentConfiguration</a> </p> </li> </ul>
  ## 
  let valid = call_773975.validator(path, query, header, formData, body)
  let scheme = call_773975.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773975.url(scheme.get, call_773975.host, call_773975.base,
                         call_773975.route, valid.getOrDefault("path"))
  result = hook(call_773975, url, valid)

proc call*(call_773976: Call_PostDescribeConfigurationSettings_773960;
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
  var query_773977 = newJObject()
  var formData_773978 = newJObject()
  add(formData_773978, "EnvironmentName", newJString(EnvironmentName))
  add(query_773977, "Action", newJString(Action))
  add(formData_773978, "ApplicationName", newJString(ApplicationName))
  add(formData_773978, "TemplateName", newJString(TemplateName))
  add(query_773977, "Version", newJString(Version))
  result = call_773976.call(nil, query_773977, nil, formData_773978, nil)

var postDescribeConfigurationSettings* = Call_PostDescribeConfigurationSettings_773960(
    name: "postDescribeConfigurationSettings", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationSettings",
    validator: validate_PostDescribeConfigurationSettings_773961, base: "/",
    url: url_PostDescribeConfigurationSettings_773962,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeConfigurationSettings_773942 = ref object of OpenApiRestCall_772598
proc url_GetDescribeConfigurationSettings_773944(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeConfigurationSettings_773943(path: JsonNode;
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
  var valid_773945 = query.getOrDefault("ApplicationName")
  valid_773945 = validateParameter(valid_773945, JString, required = true,
                                 default = nil)
  if valid_773945 != nil:
    section.add "ApplicationName", valid_773945
  var valid_773946 = query.getOrDefault("EnvironmentName")
  valid_773946 = validateParameter(valid_773946, JString, required = false,
                                 default = nil)
  if valid_773946 != nil:
    section.add "EnvironmentName", valid_773946
  var valid_773947 = query.getOrDefault("Action")
  valid_773947 = validateParameter(valid_773947, JString, required = true, default = newJString(
      "DescribeConfigurationSettings"))
  if valid_773947 != nil:
    section.add "Action", valid_773947
  var valid_773948 = query.getOrDefault("TemplateName")
  valid_773948 = validateParameter(valid_773948, JString, required = false,
                                 default = nil)
  if valid_773948 != nil:
    section.add "TemplateName", valid_773948
  var valid_773949 = query.getOrDefault("Version")
  valid_773949 = validateParameter(valid_773949, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_773949 != nil:
    section.add "Version", valid_773949
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773950 = header.getOrDefault("X-Amz-Date")
  valid_773950 = validateParameter(valid_773950, JString, required = false,
                                 default = nil)
  if valid_773950 != nil:
    section.add "X-Amz-Date", valid_773950
  var valid_773951 = header.getOrDefault("X-Amz-Security-Token")
  valid_773951 = validateParameter(valid_773951, JString, required = false,
                                 default = nil)
  if valid_773951 != nil:
    section.add "X-Amz-Security-Token", valid_773951
  var valid_773952 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773952 = validateParameter(valid_773952, JString, required = false,
                                 default = nil)
  if valid_773952 != nil:
    section.add "X-Amz-Content-Sha256", valid_773952
  var valid_773953 = header.getOrDefault("X-Amz-Algorithm")
  valid_773953 = validateParameter(valid_773953, JString, required = false,
                                 default = nil)
  if valid_773953 != nil:
    section.add "X-Amz-Algorithm", valid_773953
  var valid_773954 = header.getOrDefault("X-Amz-Signature")
  valid_773954 = validateParameter(valid_773954, JString, required = false,
                                 default = nil)
  if valid_773954 != nil:
    section.add "X-Amz-Signature", valid_773954
  var valid_773955 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773955 = validateParameter(valid_773955, JString, required = false,
                                 default = nil)
  if valid_773955 != nil:
    section.add "X-Amz-SignedHeaders", valid_773955
  var valid_773956 = header.getOrDefault("X-Amz-Credential")
  valid_773956 = validateParameter(valid_773956, JString, required = false,
                                 default = nil)
  if valid_773956 != nil:
    section.add "X-Amz-Credential", valid_773956
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773957: Call_GetDescribeConfigurationSettings_773942;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a description of the settings for the specified configuration set, that is, either a configuration template or the configuration set associated with a running environment.</p> <p>When describing the settings for the configuration set associated with a running environment, it is possible to receive two sets of setting descriptions. One is the deployed configuration set, and the other is a draft configuration of an environment that is either in the process of deployment or that failed to deploy.</p> <p>Related Topics</p> <ul> <li> <p> <a>DeleteEnvironmentConfiguration</a> </p> </li> </ul>
  ## 
  let valid = call_773957.validator(path, query, header, formData, body)
  let scheme = call_773957.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773957.url(scheme.get, call_773957.host, call_773957.base,
                         call_773957.route, valid.getOrDefault("path"))
  result = hook(call_773957, url, valid)

proc call*(call_773958: Call_GetDescribeConfigurationSettings_773942;
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
  var query_773959 = newJObject()
  add(query_773959, "ApplicationName", newJString(ApplicationName))
  add(query_773959, "EnvironmentName", newJString(EnvironmentName))
  add(query_773959, "Action", newJString(Action))
  add(query_773959, "TemplateName", newJString(TemplateName))
  add(query_773959, "Version", newJString(Version))
  result = call_773958.call(nil, query_773959, nil, nil, nil)

var getDescribeConfigurationSettings* = Call_GetDescribeConfigurationSettings_773942(
    name: "getDescribeConfigurationSettings", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationSettings",
    validator: validate_GetDescribeConfigurationSettings_773943, base: "/",
    url: url_GetDescribeConfigurationSettings_773944,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentHealth_773997 = ref object of OpenApiRestCall_772598
proc url_PostDescribeEnvironmentHealth_773999(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEnvironmentHealth_773998(path: JsonNode; query: JsonNode;
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
  var valid_774000 = query.getOrDefault("Action")
  valid_774000 = validateParameter(valid_774000, JString, required = true, default = newJString(
      "DescribeEnvironmentHealth"))
  if valid_774000 != nil:
    section.add "Action", valid_774000
  var valid_774001 = query.getOrDefault("Version")
  valid_774001 = validateParameter(valid_774001, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_774001 != nil:
    section.add "Version", valid_774001
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774002 = header.getOrDefault("X-Amz-Date")
  valid_774002 = validateParameter(valid_774002, JString, required = false,
                                 default = nil)
  if valid_774002 != nil:
    section.add "X-Amz-Date", valid_774002
  var valid_774003 = header.getOrDefault("X-Amz-Security-Token")
  valid_774003 = validateParameter(valid_774003, JString, required = false,
                                 default = nil)
  if valid_774003 != nil:
    section.add "X-Amz-Security-Token", valid_774003
  var valid_774004 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774004 = validateParameter(valid_774004, JString, required = false,
                                 default = nil)
  if valid_774004 != nil:
    section.add "X-Amz-Content-Sha256", valid_774004
  var valid_774005 = header.getOrDefault("X-Amz-Algorithm")
  valid_774005 = validateParameter(valid_774005, JString, required = false,
                                 default = nil)
  if valid_774005 != nil:
    section.add "X-Amz-Algorithm", valid_774005
  var valid_774006 = header.getOrDefault("X-Amz-Signature")
  valid_774006 = validateParameter(valid_774006, JString, required = false,
                                 default = nil)
  if valid_774006 != nil:
    section.add "X-Amz-Signature", valid_774006
  var valid_774007 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774007 = validateParameter(valid_774007, JString, required = false,
                                 default = nil)
  if valid_774007 != nil:
    section.add "X-Amz-SignedHeaders", valid_774007
  var valid_774008 = header.getOrDefault("X-Amz-Credential")
  valid_774008 = validateParameter(valid_774008, JString, required = false,
                                 default = nil)
  if valid_774008 != nil:
    section.add "X-Amz-Credential", valid_774008
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentId: JString
  ##                : <p>Specify the environment by ID.</p> <p>You must specify either this or an EnvironmentName, or both.</p>
  ##   EnvironmentName: JString
  ##                  : <p>Specify the environment by name.</p> <p>You must specify either this or an EnvironmentName, or both.</p>
  ##   AttributeNames: JArray
  ##                 : Specify the response elements to return. To retrieve all attributes, set to <code>All</code>. If no attribute names are specified, returns the name of the environment.
  section = newJObject()
  var valid_774009 = formData.getOrDefault("EnvironmentId")
  valid_774009 = validateParameter(valid_774009, JString, required = false,
                                 default = nil)
  if valid_774009 != nil:
    section.add "EnvironmentId", valid_774009
  var valid_774010 = formData.getOrDefault("EnvironmentName")
  valid_774010 = validateParameter(valid_774010, JString, required = false,
                                 default = nil)
  if valid_774010 != nil:
    section.add "EnvironmentName", valid_774010
  var valid_774011 = formData.getOrDefault("AttributeNames")
  valid_774011 = validateParameter(valid_774011, JArray, required = false,
                                 default = nil)
  if valid_774011 != nil:
    section.add "AttributeNames", valid_774011
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774012: Call_PostDescribeEnvironmentHealth_773997; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the overall health of the specified environment. The <b>DescribeEnvironmentHealth</b> operation is only available with AWS Elastic Beanstalk Enhanced Health.
  ## 
  let valid = call_774012.validator(path, query, header, formData, body)
  let scheme = call_774012.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774012.url(scheme.get, call_774012.host, call_774012.base,
                         call_774012.route, valid.getOrDefault("path"))
  result = hook(call_774012, url, valid)

proc call*(call_774013: Call_PostDescribeEnvironmentHealth_773997;
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
  var query_774014 = newJObject()
  var formData_774015 = newJObject()
  add(formData_774015, "EnvironmentId", newJString(EnvironmentId))
  add(formData_774015, "EnvironmentName", newJString(EnvironmentName))
  add(query_774014, "Action", newJString(Action))
  if AttributeNames != nil:
    formData_774015.add "AttributeNames", AttributeNames
  add(query_774014, "Version", newJString(Version))
  result = call_774013.call(nil, query_774014, nil, formData_774015, nil)

var postDescribeEnvironmentHealth* = Call_PostDescribeEnvironmentHealth_773997(
    name: "postDescribeEnvironmentHealth", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentHealth",
    validator: validate_PostDescribeEnvironmentHealth_773998, base: "/",
    url: url_PostDescribeEnvironmentHealth_773999,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentHealth_773979 = ref object of OpenApiRestCall_772598
proc url_GetDescribeEnvironmentHealth_773981(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEnvironmentHealth_773980(path: JsonNode; query: JsonNode;
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
  var valid_773982 = query.getOrDefault("AttributeNames")
  valid_773982 = validateParameter(valid_773982, JArray, required = false,
                                 default = nil)
  if valid_773982 != nil:
    section.add "AttributeNames", valid_773982
  var valid_773983 = query.getOrDefault("EnvironmentName")
  valid_773983 = validateParameter(valid_773983, JString, required = false,
                                 default = nil)
  if valid_773983 != nil:
    section.add "EnvironmentName", valid_773983
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773984 = query.getOrDefault("Action")
  valid_773984 = validateParameter(valid_773984, JString, required = true, default = newJString(
      "DescribeEnvironmentHealth"))
  if valid_773984 != nil:
    section.add "Action", valid_773984
  var valid_773985 = query.getOrDefault("EnvironmentId")
  valid_773985 = validateParameter(valid_773985, JString, required = false,
                                 default = nil)
  if valid_773985 != nil:
    section.add "EnvironmentId", valid_773985
  var valid_773986 = query.getOrDefault("Version")
  valid_773986 = validateParameter(valid_773986, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_773986 != nil:
    section.add "Version", valid_773986
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773987 = header.getOrDefault("X-Amz-Date")
  valid_773987 = validateParameter(valid_773987, JString, required = false,
                                 default = nil)
  if valid_773987 != nil:
    section.add "X-Amz-Date", valid_773987
  var valid_773988 = header.getOrDefault("X-Amz-Security-Token")
  valid_773988 = validateParameter(valid_773988, JString, required = false,
                                 default = nil)
  if valid_773988 != nil:
    section.add "X-Amz-Security-Token", valid_773988
  var valid_773989 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773989 = validateParameter(valid_773989, JString, required = false,
                                 default = nil)
  if valid_773989 != nil:
    section.add "X-Amz-Content-Sha256", valid_773989
  var valid_773990 = header.getOrDefault("X-Amz-Algorithm")
  valid_773990 = validateParameter(valid_773990, JString, required = false,
                                 default = nil)
  if valid_773990 != nil:
    section.add "X-Amz-Algorithm", valid_773990
  var valid_773991 = header.getOrDefault("X-Amz-Signature")
  valid_773991 = validateParameter(valid_773991, JString, required = false,
                                 default = nil)
  if valid_773991 != nil:
    section.add "X-Amz-Signature", valid_773991
  var valid_773992 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773992 = validateParameter(valid_773992, JString, required = false,
                                 default = nil)
  if valid_773992 != nil:
    section.add "X-Amz-SignedHeaders", valid_773992
  var valid_773993 = header.getOrDefault("X-Amz-Credential")
  valid_773993 = validateParameter(valid_773993, JString, required = false,
                                 default = nil)
  if valid_773993 != nil:
    section.add "X-Amz-Credential", valid_773993
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773994: Call_GetDescribeEnvironmentHealth_773979; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the overall health of the specified environment. The <b>DescribeEnvironmentHealth</b> operation is only available with AWS Elastic Beanstalk Enhanced Health.
  ## 
  let valid = call_773994.validator(path, query, header, formData, body)
  let scheme = call_773994.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773994.url(scheme.get, call_773994.host, call_773994.base,
                         call_773994.route, valid.getOrDefault("path"))
  result = hook(call_773994, url, valid)

proc call*(call_773995: Call_GetDescribeEnvironmentHealth_773979;
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
  var query_773996 = newJObject()
  if AttributeNames != nil:
    query_773996.add "AttributeNames", AttributeNames
  add(query_773996, "EnvironmentName", newJString(EnvironmentName))
  add(query_773996, "Action", newJString(Action))
  add(query_773996, "EnvironmentId", newJString(EnvironmentId))
  add(query_773996, "Version", newJString(Version))
  result = call_773995.call(nil, query_773996, nil, nil, nil)

var getDescribeEnvironmentHealth* = Call_GetDescribeEnvironmentHealth_773979(
    name: "getDescribeEnvironmentHealth", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentHealth",
    validator: validate_GetDescribeEnvironmentHealth_773980, base: "/",
    url: url_GetDescribeEnvironmentHealth_773981,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentManagedActionHistory_774035 = ref object of OpenApiRestCall_772598
proc url_PostDescribeEnvironmentManagedActionHistory_774037(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEnvironmentManagedActionHistory_774036(path: JsonNode;
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
  var valid_774038 = query.getOrDefault("Action")
  valid_774038 = validateParameter(valid_774038, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActionHistory"))
  if valid_774038 != nil:
    section.add "Action", valid_774038
  var valid_774039 = query.getOrDefault("Version")
  valid_774039 = validateParameter(valid_774039, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_774039 != nil:
    section.add "Version", valid_774039
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774040 = header.getOrDefault("X-Amz-Date")
  valid_774040 = validateParameter(valid_774040, JString, required = false,
                                 default = nil)
  if valid_774040 != nil:
    section.add "X-Amz-Date", valid_774040
  var valid_774041 = header.getOrDefault("X-Amz-Security-Token")
  valid_774041 = validateParameter(valid_774041, JString, required = false,
                                 default = nil)
  if valid_774041 != nil:
    section.add "X-Amz-Security-Token", valid_774041
  var valid_774042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774042 = validateParameter(valid_774042, JString, required = false,
                                 default = nil)
  if valid_774042 != nil:
    section.add "X-Amz-Content-Sha256", valid_774042
  var valid_774043 = header.getOrDefault("X-Amz-Algorithm")
  valid_774043 = validateParameter(valid_774043, JString, required = false,
                                 default = nil)
  if valid_774043 != nil:
    section.add "X-Amz-Algorithm", valid_774043
  var valid_774044 = header.getOrDefault("X-Amz-Signature")
  valid_774044 = validateParameter(valid_774044, JString, required = false,
                                 default = nil)
  if valid_774044 != nil:
    section.add "X-Amz-Signature", valid_774044
  var valid_774045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774045 = validateParameter(valid_774045, JString, required = false,
                                 default = nil)
  if valid_774045 != nil:
    section.add "X-Amz-SignedHeaders", valid_774045
  var valid_774046 = header.getOrDefault("X-Amz-Credential")
  valid_774046 = validateParameter(valid_774046, JString, required = false,
                                 default = nil)
  if valid_774046 != nil:
    section.add "X-Amz-Credential", valid_774046
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
  var valid_774047 = formData.getOrDefault("NextToken")
  valid_774047 = validateParameter(valid_774047, JString, required = false,
                                 default = nil)
  if valid_774047 != nil:
    section.add "NextToken", valid_774047
  var valid_774048 = formData.getOrDefault("EnvironmentId")
  valid_774048 = validateParameter(valid_774048, JString, required = false,
                                 default = nil)
  if valid_774048 != nil:
    section.add "EnvironmentId", valid_774048
  var valid_774049 = formData.getOrDefault("EnvironmentName")
  valid_774049 = validateParameter(valid_774049, JString, required = false,
                                 default = nil)
  if valid_774049 != nil:
    section.add "EnvironmentName", valid_774049
  var valid_774050 = formData.getOrDefault("MaxItems")
  valid_774050 = validateParameter(valid_774050, JInt, required = false, default = nil)
  if valid_774050 != nil:
    section.add "MaxItems", valid_774050
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774051: Call_PostDescribeEnvironmentManagedActionHistory_774035;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists an environment's completed and failed managed actions.
  ## 
  let valid = call_774051.validator(path, query, header, formData, body)
  let scheme = call_774051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774051.url(scheme.get, call_774051.host, call_774051.base,
                         call_774051.route, valid.getOrDefault("path"))
  result = hook(call_774051, url, valid)

proc call*(call_774052: Call_PostDescribeEnvironmentManagedActionHistory_774035;
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
  var query_774053 = newJObject()
  var formData_774054 = newJObject()
  add(formData_774054, "NextToken", newJString(NextToken))
  add(formData_774054, "EnvironmentId", newJString(EnvironmentId))
  add(formData_774054, "EnvironmentName", newJString(EnvironmentName))
  add(query_774053, "Action", newJString(Action))
  add(formData_774054, "MaxItems", newJInt(MaxItems))
  add(query_774053, "Version", newJString(Version))
  result = call_774052.call(nil, query_774053, nil, formData_774054, nil)

var postDescribeEnvironmentManagedActionHistory* = Call_PostDescribeEnvironmentManagedActionHistory_774035(
    name: "postDescribeEnvironmentManagedActionHistory",
    meth: HttpMethod.HttpPost, host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActionHistory",
    validator: validate_PostDescribeEnvironmentManagedActionHistory_774036,
    base: "/", url: url_PostDescribeEnvironmentManagedActionHistory_774037,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentManagedActionHistory_774016 = ref object of OpenApiRestCall_772598
proc url_GetDescribeEnvironmentManagedActionHistory_774018(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEnvironmentManagedActionHistory_774017(path: JsonNode;
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
  var valid_774019 = query.getOrDefault("NextToken")
  valid_774019 = validateParameter(valid_774019, JString, required = false,
                                 default = nil)
  if valid_774019 != nil:
    section.add "NextToken", valid_774019
  var valid_774020 = query.getOrDefault("EnvironmentName")
  valid_774020 = validateParameter(valid_774020, JString, required = false,
                                 default = nil)
  if valid_774020 != nil:
    section.add "EnvironmentName", valid_774020
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774021 = query.getOrDefault("Action")
  valid_774021 = validateParameter(valid_774021, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActionHistory"))
  if valid_774021 != nil:
    section.add "Action", valid_774021
  var valid_774022 = query.getOrDefault("EnvironmentId")
  valid_774022 = validateParameter(valid_774022, JString, required = false,
                                 default = nil)
  if valid_774022 != nil:
    section.add "EnvironmentId", valid_774022
  var valid_774023 = query.getOrDefault("MaxItems")
  valid_774023 = validateParameter(valid_774023, JInt, required = false, default = nil)
  if valid_774023 != nil:
    section.add "MaxItems", valid_774023
  var valid_774024 = query.getOrDefault("Version")
  valid_774024 = validateParameter(valid_774024, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_774024 != nil:
    section.add "Version", valid_774024
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774025 = header.getOrDefault("X-Amz-Date")
  valid_774025 = validateParameter(valid_774025, JString, required = false,
                                 default = nil)
  if valid_774025 != nil:
    section.add "X-Amz-Date", valid_774025
  var valid_774026 = header.getOrDefault("X-Amz-Security-Token")
  valid_774026 = validateParameter(valid_774026, JString, required = false,
                                 default = nil)
  if valid_774026 != nil:
    section.add "X-Amz-Security-Token", valid_774026
  var valid_774027 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774027 = validateParameter(valid_774027, JString, required = false,
                                 default = nil)
  if valid_774027 != nil:
    section.add "X-Amz-Content-Sha256", valid_774027
  var valid_774028 = header.getOrDefault("X-Amz-Algorithm")
  valid_774028 = validateParameter(valid_774028, JString, required = false,
                                 default = nil)
  if valid_774028 != nil:
    section.add "X-Amz-Algorithm", valid_774028
  var valid_774029 = header.getOrDefault("X-Amz-Signature")
  valid_774029 = validateParameter(valid_774029, JString, required = false,
                                 default = nil)
  if valid_774029 != nil:
    section.add "X-Amz-Signature", valid_774029
  var valid_774030 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774030 = validateParameter(valid_774030, JString, required = false,
                                 default = nil)
  if valid_774030 != nil:
    section.add "X-Amz-SignedHeaders", valid_774030
  var valid_774031 = header.getOrDefault("X-Amz-Credential")
  valid_774031 = validateParameter(valid_774031, JString, required = false,
                                 default = nil)
  if valid_774031 != nil:
    section.add "X-Amz-Credential", valid_774031
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774032: Call_GetDescribeEnvironmentManagedActionHistory_774016;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists an environment's completed and failed managed actions.
  ## 
  let valid = call_774032.validator(path, query, header, formData, body)
  let scheme = call_774032.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774032.url(scheme.get, call_774032.host, call_774032.base,
                         call_774032.route, valid.getOrDefault("path"))
  result = hook(call_774032, url, valid)

proc call*(call_774033: Call_GetDescribeEnvironmentManagedActionHistory_774016;
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
  var query_774034 = newJObject()
  add(query_774034, "NextToken", newJString(NextToken))
  add(query_774034, "EnvironmentName", newJString(EnvironmentName))
  add(query_774034, "Action", newJString(Action))
  add(query_774034, "EnvironmentId", newJString(EnvironmentId))
  add(query_774034, "MaxItems", newJInt(MaxItems))
  add(query_774034, "Version", newJString(Version))
  result = call_774033.call(nil, query_774034, nil, nil, nil)

var getDescribeEnvironmentManagedActionHistory* = Call_GetDescribeEnvironmentManagedActionHistory_774016(
    name: "getDescribeEnvironmentManagedActionHistory", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActionHistory",
    validator: validate_GetDescribeEnvironmentManagedActionHistory_774017,
    base: "/", url: url_GetDescribeEnvironmentManagedActionHistory_774018,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentManagedActions_774073 = ref object of OpenApiRestCall_772598
proc url_PostDescribeEnvironmentManagedActions_774075(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEnvironmentManagedActions_774074(path: JsonNode;
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
  var valid_774076 = query.getOrDefault("Action")
  valid_774076 = validateParameter(valid_774076, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActions"))
  if valid_774076 != nil:
    section.add "Action", valid_774076
  var valid_774077 = query.getOrDefault("Version")
  valid_774077 = validateParameter(valid_774077, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_774077 != nil:
    section.add "Version", valid_774077
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774078 = header.getOrDefault("X-Amz-Date")
  valid_774078 = validateParameter(valid_774078, JString, required = false,
                                 default = nil)
  if valid_774078 != nil:
    section.add "X-Amz-Date", valid_774078
  var valid_774079 = header.getOrDefault("X-Amz-Security-Token")
  valid_774079 = validateParameter(valid_774079, JString, required = false,
                                 default = nil)
  if valid_774079 != nil:
    section.add "X-Amz-Security-Token", valid_774079
  var valid_774080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774080 = validateParameter(valid_774080, JString, required = false,
                                 default = nil)
  if valid_774080 != nil:
    section.add "X-Amz-Content-Sha256", valid_774080
  var valid_774081 = header.getOrDefault("X-Amz-Algorithm")
  valid_774081 = validateParameter(valid_774081, JString, required = false,
                                 default = nil)
  if valid_774081 != nil:
    section.add "X-Amz-Algorithm", valid_774081
  var valid_774082 = header.getOrDefault("X-Amz-Signature")
  valid_774082 = validateParameter(valid_774082, JString, required = false,
                                 default = nil)
  if valid_774082 != nil:
    section.add "X-Amz-Signature", valid_774082
  var valid_774083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774083 = validateParameter(valid_774083, JString, required = false,
                                 default = nil)
  if valid_774083 != nil:
    section.add "X-Amz-SignedHeaders", valid_774083
  var valid_774084 = header.getOrDefault("X-Amz-Credential")
  valid_774084 = validateParameter(valid_774084, JString, required = false,
                                 default = nil)
  if valid_774084 != nil:
    section.add "X-Amz-Credential", valid_774084
  result.add "header", section
  ## parameters in `formData` object:
  ##   Status: JString
  ##         : To show only actions with a particular status, specify a status.
  ##   EnvironmentId: JString
  ##                : The environment ID of the target environment.
  ##   EnvironmentName: JString
  ##                  : The name of the target environment.
  section = newJObject()
  var valid_774085 = formData.getOrDefault("Status")
  valid_774085 = validateParameter(valid_774085, JString, required = false,
                                 default = newJString("Scheduled"))
  if valid_774085 != nil:
    section.add "Status", valid_774085
  var valid_774086 = formData.getOrDefault("EnvironmentId")
  valid_774086 = validateParameter(valid_774086, JString, required = false,
                                 default = nil)
  if valid_774086 != nil:
    section.add "EnvironmentId", valid_774086
  var valid_774087 = formData.getOrDefault("EnvironmentName")
  valid_774087 = validateParameter(valid_774087, JString, required = false,
                                 default = nil)
  if valid_774087 != nil:
    section.add "EnvironmentName", valid_774087
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774088: Call_PostDescribeEnvironmentManagedActions_774073;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists an environment's upcoming and in-progress managed actions.
  ## 
  let valid = call_774088.validator(path, query, header, formData, body)
  let scheme = call_774088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774088.url(scheme.get, call_774088.host, call_774088.base,
                         call_774088.route, valid.getOrDefault("path"))
  result = hook(call_774088, url, valid)

proc call*(call_774089: Call_PostDescribeEnvironmentManagedActions_774073;
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
  var query_774090 = newJObject()
  var formData_774091 = newJObject()
  add(formData_774091, "Status", newJString(Status))
  add(formData_774091, "EnvironmentId", newJString(EnvironmentId))
  add(formData_774091, "EnvironmentName", newJString(EnvironmentName))
  add(query_774090, "Action", newJString(Action))
  add(query_774090, "Version", newJString(Version))
  result = call_774089.call(nil, query_774090, nil, formData_774091, nil)

var postDescribeEnvironmentManagedActions* = Call_PostDescribeEnvironmentManagedActions_774073(
    name: "postDescribeEnvironmentManagedActions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActions",
    validator: validate_PostDescribeEnvironmentManagedActions_774074, base: "/",
    url: url_PostDescribeEnvironmentManagedActions_774075,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentManagedActions_774055 = ref object of OpenApiRestCall_772598
proc url_GetDescribeEnvironmentManagedActions_774057(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEnvironmentManagedActions_774056(path: JsonNode;
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
  var valid_774058 = query.getOrDefault("Status")
  valid_774058 = validateParameter(valid_774058, JString, required = false,
                                 default = newJString("Scheduled"))
  if valid_774058 != nil:
    section.add "Status", valid_774058
  var valid_774059 = query.getOrDefault("EnvironmentName")
  valid_774059 = validateParameter(valid_774059, JString, required = false,
                                 default = nil)
  if valid_774059 != nil:
    section.add "EnvironmentName", valid_774059
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774060 = query.getOrDefault("Action")
  valid_774060 = validateParameter(valid_774060, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActions"))
  if valid_774060 != nil:
    section.add "Action", valid_774060
  var valid_774061 = query.getOrDefault("EnvironmentId")
  valid_774061 = validateParameter(valid_774061, JString, required = false,
                                 default = nil)
  if valid_774061 != nil:
    section.add "EnvironmentId", valid_774061
  var valid_774062 = query.getOrDefault("Version")
  valid_774062 = validateParameter(valid_774062, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_774062 != nil:
    section.add "Version", valid_774062
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774063 = header.getOrDefault("X-Amz-Date")
  valid_774063 = validateParameter(valid_774063, JString, required = false,
                                 default = nil)
  if valid_774063 != nil:
    section.add "X-Amz-Date", valid_774063
  var valid_774064 = header.getOrDefault("X-Amz-Security-Token")
  valid_774064 = validateParameter(valid_774064, JString, required = false,
                                 default = nil)
  if valid_774064 != nil:
    section.add "X-Amz-Security-Token", valid_774064
  var valid_774065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774065 = validateParameter(valid_774065, JString, required = false,
                                 default = nil)
  if valid_774065 != nil:
    section.add "X-Amz-Content-Sha256", valid_774065
  var valid_774066 = header.getOrDefault("X-Amz-Algorithm")
  valid_774066 = validateParameter(valid_774066, JString, required = false,
                                 default = nil)
  if valid_774066 != nil:
    section.add "X-Amz-Algorithm", valid_774066
  var valid_774067 = header.getOrDefault("X-Amz-Signature")
  valid_774067 = validateParameter(valid_774067, JString, required = false,
                                 default = nil)
  if valid_774067 != nil:
    section.add "X-Amz-Signature", valid_774067
  var valid_774068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774068 = validateParameter(valid_774068, JString, required = false,
                                 default = nil)
  if valid_774068 != nil:
    section.add "X-Amz-SignedHeaders", valid_774068
  var valid_774069 = header.getOrDefault("X-Amz-Credential")
  valid_774069 = validateParameter(valid_774069, JString, required = false,
                                 default = nil)
  if valid_774069 != nil:
    section.add "X-Amz-Credential", valid_774069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774070: Call_GetDescribeEnvironmentManagedActions_774055;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists an environment's upcoming and in-progress managed actions.
  ## 
  let valid = call_774070.validator(path, query, header, formData, body)
  let scheme = call_774070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774070.url(scheme.get, call_774070.host, call_774070.base,
                         call_774070.route, valid.getOrDefault("path"))
  result = hook(call_774070, url, valid)

proc call*(call_774071: Call_GetDescribeEnvironmentManagedActions_774055;
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
  var query_774072 = newJObject()
  add(query_774072, "Status", newJString(Status))
  add(query_774072, "EnvironmentName", newJString(EnvironmentName))
  add(query_774072, "Action", newJString(Action))
  add(query_774072, "EnvironmentId", newJString(EnvironmentId))
  add(query_774072, "Version", newJString(Version))
  result = call_774071.call(nil, query_774072, nil, nil, nil)

var getDescribeEnvironmentManagedActions* = Call_GetDescribeEnvironmentManagedActions_774055(
    name: "getDescribeEnvironmentManagedActions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActions",
    validator: validate_GetDescribeEnvironmentManagedActions_774056, base: "/",
    url: url_GetDescribeEnvironmentManagedActions_774057,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentResources_774109 = ref object of OpenApiRestCall_772598
proc url_PostDescribeEnvironmentResources_774111(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEnvironmentResources_774110(path: JsonNode;
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
  var valid_774112 = query.getOrDefault("Action")
  valid_774112 = validateParameter(valid_774112, JString, required = true, default = newJString(
      "DescribeEnvironmentResources"))
  if valid_774112 != nil:
    section.add "Action", valid_774112
  var valid_774113 = query.getOrDefault("Version")
  valid_774113 = validateParameter(valid_774113, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_774113 != nil:
    section.add "Version", valid_774113
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774114 = header.getOrDefault("X-Amz-Date")
  valid_774114 = validateParameter(valid_774114, JString, required = false,
                                 default = nil)
  if valid_774114 != nil:
    section.add "X-Amz-Date", valid_774114
  var valid_774115 = header.getOrDefault("X-Amz-Security-Token")
  valid_774115 = validateParameter(valid_774115, JString, required = false,
                                 default = nil)
  if valid_774115 != nil:
    section.add "X-Amz-Security-Token", valid_774115
  var valid_774116 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774116 = validateParameter(valid_774116, JString, required = false,
                                 default = nil)
  if valid_774116 != nil:
    section.add "X-Amz-Content-Sha256", valid_774116
  var valid_774117 = header.getOrDefault("X-Amz-Algorithm")
  valid_774117 = validateParameter(valid_774117, JString, required = false,
                                 default = nil)
  if valid_774117 != nil:
    section.add "X-Amz-Algorithm", valid_774117
  var valid_774118 = header.getOrDefault("X-Amz-Signature")
  valid_774118 = validateParameter(valid_774118, JString, required = false,
                                 default = nil)
  if valid_774118 != nil:
    section.add "X-Amz-Signature", valid_774118
  var valid_774119 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774119 = validateParameter(valid_774119, JString, required = false,
                                 default = nil)
  if valid_774119 != nil:
    section.add "X-Amz-SignedHeaders", valid_774119
  var valid_774120 = header.getOrDefault("X-Amz-Credential")
  valid_774120 = validateParameter(valid_774120, JString, required = false,
                                 default = nil)
  if valid_774120 != nil:
    section.add "X-Amz-Credential", valid_774120
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to retrieve AWS resource usage data.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to retrieve AWS resource usage data.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_774121 = formData.getOrDefault("EnvironmentId")
  valid_774121 = validateParameter(valid_774121, JString, required = false,
                                 default = nil)
  if valid_774121 != nil:
    section.add "EnvironmentId", valid_774121
  var valid_774122 = formData.getOrDefault("EnvironmentName")
  valid_774122 = validateParameter(valid_774122, JString, required = false,
                                 default = nil)
  if valid_774122 != nil:
    section.add "EnvironmentName", valid_774122
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774123: Call_PostDescribeEnvironmentResources_774109;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns AWS resources for this environment.
  ## 
  let valid = call_774123.validator(path, query, header, formData, body)
  let scheme = call_774123.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774123.url(scheme.get, call_774123.host, call_774123.base,
                         call_774123.route, valid.getOrDefault("path"))
  result = hook(call_774123, url, valid)

proc call*(call_774124: Call_PostDescribeEnvironmentResources_774109;
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
  var query_774125 = newJObject()
  var formData_774126 = newJObject()
  add(formData_774126, "EnvironmentId", newJString(EnvironmentId))
  add(formData_774126, "EnvironmentName", newJString(EnvironmentName))
  add(query_774125, "Action", newJString(Action))
  add(query_774125, "Version", newJString(Version))
  result = call_774124.call(nil, query_774125, nil, formData_774126, nil)

var postDescribeEnvironmentResources* = Call_PostDescribeEnvironmentResources_774109(
    name: "postDescribeEnvironmentResources", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentResources",
    validator: validate_PostDescribeEnvironmentResources_774110, base: "/",
    url: url_PostDescribeEnvironmentResources_774111,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentResources_774092 = ref object of OpenApiRestCall_772598
proc url_GetDescribeEnvironmentResources_774094(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEnvironmentResources_774093(path: JsonNode;
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
  var valid_774095 = query.getOrDefault("EnvironmentName")
  valid_774095 = validateParameter(valid_774095, JString, required = false,
                                 default = nil)
  if valid_774095 != nil:
    section.add "EnvironmentName", valid_774095
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774096 = query.getOrDefault("Action")
  valid_774096 = validateParameter(valid_774096, JString, required = true, default = newJString(
      "DescribeEnvironmentResources"))
  if valid_774096 != nil:
    section.add "Action", valid_774096
  var valid_774097 = query.getOrDefault("EnvironmentId")
  valid_774097 = validateParameter(valid_774097, JString, required = false,
                                 default = nil)
  if valid_774097 != nil:
    section.add "EnvironmentId", valid_774097
  var valid_774098 = query.getOrDefault("Version")
  valid_774098 = validateParameter(valid_774098, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_774098 != nil:
    section.add "Version", valid_774098
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774099 = header.getOrDefault("X-Amz-Date")
  valid_774099 = validateParameter(valid_774099, JString, required = false,
                                 default = nil)
  if valid_774099 != nil:
    section.add "X-Amz-Date", valid_774099
  var valid_774100 = header.getOrDefault("X-Amz-Security-Token")
  valid_774100 = validateParameter(valid_774100, JString, required = false,
                                 default = nil)
  if valid_774100 != nil:
    section.add "X-Amz-Security-Token", valid_774100
  var valid_774101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774101 = validateParameter(valid_774101, JString, required = false,
                                 default = nil)
  if valid_774101 != nil:
    section.add "X-Amz-Content-Sha256", valid_774101
  var valid_774102 = header.getOrDefault("X-Amz-Algorithm")
  valid_774102 = validateParameter(valid_774102, JString, required = false,
                                 default = nil)
  if valid_774102 != nil:
    section.add "X-Amz-Algorithm", valid_774102
  var valid_774103 = header.getOrDefault("X-Amz-Signature")
  valid_774103 = validateParameter(valid_774103, JString, required = false,
                                 default = nil)
  if valid_774103 != nil:
    section.add "X-Amz-Signature", valid_774103
  var valid_774104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774104 = validateParameter(valid_774104, JString, required = false,
                                 default = nil)
  if valid_774104 != nil:
    section.add "X-Amz-SignedHeaders", valid_774104
  var valid_774105 = header.getOrDefault("X-Amz-Credential")
  valid_774105 = validateParameter(valid_774105, JString, required = false,
                                 default = nil)
  if valid_774105 != nil:
    section.add "X-Amz-Credential", valid_774105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774106: Call_GetDescribeEnvironmentResources_774092;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns AWS resources for this environment.
  ## 
  let valid = call_774106.validator(path, query, header, formData, body)
  let scheme = call_774106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774106.url(scheme.get, call_774106.host, call_774106.base,
                         call_774106.route, valid.getOrDefault("path"))
  result = hook(call_774106, url, valid)

proc call*(call_774107: Call_GetDescribeEnvironmentResources_774092;
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
  var query_774108 = newJObject()
  add(query_774108, "EnvironmentName", newJString(EnvironmentName))
  add(query_774108, "Action", newJString(Action))
  add(query_774108, "EnvironmentId", newJString(EnvironmentId))
  add(query_774108, "Version", newJString(Version))
  result = call_774107.call(nil, query_774108, nil, nil, nil)

var getDescribeEnvironmentResources* = Call_GetDescribeEnvironmentResources_774092(
    name: "getDescribeEnvironmentResources", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentResources",
    validator: validate_GetDescribeEnvironmentResources_774093, base: "/",
    url: url_GetDescribeEnvironmentResources_774094,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironments_774150 = ref object of OpenApiRestCall_772598
proc url_PostDescribeEnvironments_774152(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEnvironments_774151(path: JsonNode; query: JsonNode;
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
  var valid_774153 = query.getOrDefault("Action")
  valid_774153 = validateParameter(valid_774153, JString, required = true,
                                 default = newJString("DescribeEnvironments"))
  if valid_774153 != nil:
    section.add "Action", valid_774153
  var valid_774154 = query.getOrDefault("Version")
  valid_774154 = validateParameter(valid_774154, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_774154 != nil:
    section.add "Version", valid_774154
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774155 = header.getOrDefault("X-Amz-Date")
  valid_774155 = validateParameter(valid_774155, JString, required = false,
                                 default = nil)
  if valid_774155 != nil:
    section.add "X-Amz-Date", valid_774155
  var valid_774156 = header.getOrDefault("X-Amz-Security-Token")
  valid_774156 = validateParameter(valid_774156, JString, required = false,
                                 default = nil)
  if valid_774156 != nil:
    section.add "X-Amz-Security-Token", valid_774156
  var valid_774157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774157 = validateParameter(valid_774157, JString, required = false,
                                 default = nil)
  if valid_774157 != nil:
    section.add "X-Amz-Content-Sha256", valid_774157
  var valid_774158 = header.getOrDefault("X-Amz-Algorithm")
  valid_774158 = validateParameter(valid_774158, JString, required = false,
                                 default = nil)
  if valid_774158 != nil:
    section.add "X-Amz-Algorithm", valid_774158
  var valid_774159 = header.getOrDefault("X-Amz-Signature")
  valid_774159 = validateParameter(valid_774159, JString, required = false,
                                 default = nil)
  if valid_774159 != nil:
    section.add "X-Amz-Signature", valid_774159
  var valid_774160 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774160 = validateParameter(valid_774160, JString, required = false,
                                 default = nil)
  if valid_774160 != nil:
    section.add "X-Amz-SignedHeaders", valid_774160
  var valid_774161 = header.getOrDefault("X-Amz-Credential")
  valid_774161 = validateParameter(valid_774161, JString, required = false,
                                 default = nil)
  if valid_774161 != nil:
    section.add "X-Amz-Credential", valid_774161
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
  var valid_774162 = formData.getOrDefault("NextToken")
  valid_774162 = validateParameter(valid_774162, JString, required = false,
                                 default = nil)
  if valid_774162 != nil:
    section.add "NextToken", valid_774162
  var valid_774163 = formData.getOrDefault("VersionLabel")
  valid_774163 = validateParameter(valid_774163, JString, required = false,
                                 default = nil)
  if valid_774163 != nil:
    section.add "VersionLabel", valid_774163
  var valid_774164 = formData.getOrDefault("EnvironmentNames")
  valid_774164 = validateParameter(valid_774164, JArray, required = false,
                                 default = nil)
  if valid_774164 != nil:
    section.add "EnvironmentNames", valid_774164
  var valid_774165 = formData.getOrDefault("IncludedDeletedBackTo")
  valid_774165 = validateParameter(valid_774165, JString, required = false,
                                 default = nil)
  if valid_774165 != nil:
    section.add "IncludedDeletedBackTo", valid_774165
  var valid_774166 = formData.getOrDefault("ApplicationName")
  valid_774166 = validateParameter(valid_774166, JString, required = false,
                                 default = nil)
  if valid_774166 != nil:
    section.add "ApplicationName", valid_774166
  var valid_774167 = formData.getOrDefault("EnvironmentIds")
  valid_774167 = validateParameter(valid_774167, JArray, required = false,
                                 default = nil)
  if valid_774167 != nil:
    section.add "EnvironmentIds", valid_774167
  var valid_774168 = formData.getOrDefault("IncludeDeleted")
  valid_774168 = validateParameter(valid_774168, JBool, required = false, default = nil)
  if valid_774168 != nil:
    section.add "IncludeDeleted", valid_774168
  var valid_774169 = formData.getOrDefault("MaxRecords")
  valid_774169 = validateParameter(valid_774169, JInt, required = false, default = nil)
  if valid_774169 != nil:
    section.add "MaxRecords", valid_774169
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774170: Call_PostDescribeEnvironments_774150; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns descriptions for existing environments.
  ## 
  let valid = call_774170.validator(path, query, header, formData, body)
  let scheme = call_774170.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774170.url(scheme.get, call_774170.host, call_774170.base,
                         call_774170.route, valid.getOrDefault("path"))
  result = hook(call_774170, url, valid)

proc call*(call_774171: Call_PostDescribeEnvironments_774150;
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
  var query_774172 = newJObject()
  var formData_774173 = newJObject()
  add(formData_774173, "NextToken", newJString(NextToken))
  add(formData_774173, "VersionLabel", newJString(VersionLabel))
  if EnvironmentNames != nil:
    formData_774173.add "EnvironmentNames", EnvironmentNames
  add(formData_774173, "IncludedDeletedBackTo", newJString(IncludedDeletedBackTo))
  add(query_774172, "Action", newJString(Action))
  add(formData_774173, "ApplicationName", newJString(ApplicationName))
  if EnvironmentIds != nil:
    formData_774173.add "EnvironmentIds", EnvironmentIds
  add(formData_774173, "IncludeDeleted", newJBool(IncludeDeleted))
  add(formData_774173, "MaxRecords", newJInt(MaxRecords))
  add(query_774172, "Version", newJString(Version))
  result = call_774171.call(nil, query_774172, nil, formData_774173, nil)

var postDescribeEnvironments* = Call_PostDescribeEnvironments_774150(
    name: "postDescribeEnvironments", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironments",
    validator: validate_PostDescribeEnvironments_774151, base: "/",
    url: url_PostDescribeEnvironments_774152, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironments_774127 = ref object of OpenApiRestCall_772598
proc url_GetDescribeEnvironments_774129(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEnvironments_774128(path: JsonNode; query: JsonNode;
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
  var valid_774130 = query.getOrDefault("VersionLabel")
  valid_774130 = validateParameter(valid_774130, JString, required = false,
                                 default = nil)
  if valid_774130 != nil:
    section.add "VersionLabel", valid_774130
  var valid_774131 = query.getOrDefault("MaxRecords")
  valid_774131 = validateParameter(valid_774131, JInt, required = false, default = nil)
  if valid_774131 != nil:
    section.add "MaxRecords", valid_774131
  var valid_774132 = query.getOrDefault("ApplicationName")
  valid_774132 = validateParameter(valid_774132, JString, required = false,
                                 default = nil)
  if valid_774132 != nil:
    section.add "ApplicationName", valid_774132
  var valid_774133 = query.getOrDefault("IncludeDeleted")
  valid_774133 = validateParameter(valid_774133, JBool, required = false, default = nil)
  if valid_774133 != nil:
    section.add "IncludeDeleted", valid_774133
  var valid_774134 = query.getOrDefault("NextToken")
  valid_774134 = validateParameter(valid_774134, JString, required = false,
                                 default = nil)
  if valid_774134 != nil:
    section.add "NextToken", valid_774134
  var valid_774135 = query.getOrDefault("EnvironmentIds")
  valid_774135 = validateParameter(valid_774135, JArray, required = false,
                                 default = nil)
  if valid_774135 != nil:
    section.add "EnvironmentIds", valid_774135
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774136 = query.getOrDefault("Action")
  valid_774136 = validateParameter(valid_774136, JString, required = true,
                                 default = newJString("DescribeEnvironments"))
  if valid_774136 != nil:
    section.add "Action", valid_774136
  var valid_774137 = query.getOrDefault("IncludedDeletedBackTo")
  valid_774137 = validateParameter(valid_774137, JString, required = false,
                                 default = nil)
  if valid_774137 != nil:
    section.add "IncludedDeletedBackTo", valid_774137
  var valid_774138 = query.getOrDefault("EnvironmentNames")
  valid_774138 = validateParameter(valid_774138, JArray, required = false,
                                 default = nil)
  if valid_774138 != nil:
    section.add "EnvironmentNames", valid_774138
  var valid_774139 = query.getOrDefault("Version")
  valid_774139 = validateParameter(valid_774139, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_774139 != nil:
    section.add "Version", valid_774139
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774140 = header.getOrDefault("X-Amz-Date")
  valid_774140 = validateParameter(valid_774140, JString, required = false,
                                 default = nil)
  if valid_774140 != nil:
    section.add "X-Amz-Date", valid_774140
  var valid_774141 = header.getOrDefault("X-Amz-Security-Token")
  valid_774141 = validateParameter(valid_774141, JString, required = false,
                                 default = nil)
  if valid_774141 != nil:
    section.add "X-Amz-Security-Token", valid_774141
  var valid_774142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774142 = validateParameter(valid_774142, JString, required = false,
                                 default = nil)
  if valid_774142 != nil:
    section.add "X-Amz-Content-Sha256", valid_774142
  var valid_774143 = header.getOrDefault("X-Amz-Algorithm")
  valid_774143 = validateParameter(valid_774143, JString, required = false,
                                 default = nil)
  if valid_774143 != nil:
    section.add "X-Amz-Algorithm", valid_774143
  var valid_774144 = header.getOrDefault("X-Amz-Signature")
  valid_774144 = validateParameter(valid_774144, JString, required = false,
                                 default = nil)
  if valid_774144 != nil:
    section.add "X-Amz-Signature", valid_774144
  var valid_774145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774145 = validateParameter(valid_774145, JString, required = false,
                                 default = nil)
  if valid_774145 != nil:
    section.add "X-Amz-SignedHeaders", valid_774145
  var valid_774146 = header.getOrDefault("X-Amz-Credential")
  valid_774146 = validateParameter(valid_774146, JString, required = false,
                                 default = nil)
  if valid_774146 != nil:
    section.add "X-Amz-Credential", valid_774146
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774147: Call_GetDescribeEnvironments_774127; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns descriptions for existing environments.
  ## 
  let valid = call_774147.validator(path, query, header, formData, body)
  let scheme = call_774147.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774147.url(scheme.get, call_774147.host, call_774147.base,
                         call_774147.route, valid.getOrDefault("path"))
  result = hook(call_774147, url, valid)

proc call*(call_774148: Call_GetDescribeEnvironments_774127;
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
  var query_774149 = newJObject()
  add(query_774149, "VersionLabel", newJString(VersionLabel))
  add(query_774149, "MaxRecords", newJInt(MaxRecords))
  add(query_774149, "ApplicationName", newJString(ApplicationName))
  add(query_774149, "IncludeDeleted", newJBool(IncludeDeleted))
  add(query_774149, "NextToken", newJString(NextToken))
  if EnvironmentIds != nil:
    query_774149.add "EnvironmentIds", EnvironmentIds
  add(query_774149, "Action", newJString(Action))
  add(query_774149, "IncludedDeletedBackTo", newJString(IncludedDeletedBackTo))
  if EnvironmentNames != nil:
    query_774149.add "EnvironmentNames", EnvironmentNames
  add(query_774149, "Version", newJString(Version))
  result = call_774148.call(nil, query_774149, nil, nil, nil)

var getDescribeEnvironments* = Call_GetDescribeEnvironments_774127(
    name: "getDescribeEnvironments", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironments",
    validator: validate_GetDescribeEnvironments_774128, base: "/",
    url: url_GetDescribeEnvironments_774129, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_774201 = ref object of OpenApiRestCall_772598
proc url_PostDescribeEvents_774203(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEvents_774202(path: JsonNode; query: JsonNode;
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
  var valid_774204 = query.getOrDefault("Action")
  valid_774204 = validateParameter(valid_774204, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_774204 != nil:
    section.add "Action", valid_774204
  var valid_774205 = query.getOrDefault("Version")
  valid_774205 = validateParameter(valid_774205, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_774205 != nil:
    section.add "Version", valid_774205
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774206 = header.getOrDefault("X-Amz-Date")
  valid_774206 = validateParameter(valid_774206, JString, required = false,
                                 default = nil)
  if valid_774206 != nil:
    section.add "X-Amz-Date", valid_774206
  var valid_774207 = header.getOrDefault("X-Amz-Security-Token")
  valid_774207 = validateParameter(valid_774207, JString, required = false,
                                 default = nil)
  if valid_774207 != nil:
    section.add "X-Amz-Security-Token", valid_774207
  var valid_774208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774208 = validateParameter(valid_774208, JString, required = false,
                                 default = nil)
  if valid_774208 != nil:
    section.add "X-Amz-Content-Sha256", valid_774208
  var valid_774209 = header.getOrDefault("X-Amz-Algorithm")
  valid_774209 = validateParameter(valid_774209, JString, required = false,
                                 default = nil)
  if valid_774209 != nil:
    section.add "X-Amz-Algorithm", valid_774209
  var valid_774210 = header.getOrDefault("X-Amz-Signature")
  valid_774210 = validateParameter(valid_774210, JString, required = false,
                                 default = nil)
  if valid_774210 != nil:
    section.add "X-Amz-Signature", valid_774210
  var valid_774211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774211 = validateParameter(valid_774211, JString, required = false,
                                 default = nil)
  if valid_774211 != nil:
    section.add "X-Amz-SignedHeaders", valid_774211
  var valid_774212 = header.getOrDefault("X-Amz-Credential")
  valid_774212 = validateParameter(valid_774212, JString, required = false,
                                 default = nil)
  if valid_774212 != nil:
    section.add "X-Amz-Credential", valid_774212
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
  var valid_774213 = formData.getOrDefault("NextToken")
  valid_774213 = validateParameter(valid_774213, JString, required = false,
                                 default = nil)
  if valid_774213 != nil:
    section.add "NextToken", valid_774213
  var valid_774214 = formData.getOrDefault("VersionLabel")
  valid_774214 = validateParameter(valid_774214, JString, required = false,
                                 default = nil)
  if valid_774214 != nil:
    section.add "VersionLabel", valid_774214
  var valid_774215 = formData.getOrDefault("Severity")
  valid_774215 = validateParameter(valid_774215, JString, required = false,
                                 default = newJString("TRACE"))
  if valid_774215 != nil:
    section.add "Severity", valid_774215
  var valid_774216 = formData.getOrDefault("EnvironmentId")
  valid_774216 = validateParameter(valid_774216, JString, required = false,
                                 default = nil)
  if valid_774216 != nil:
    section.add "EnvironmentId", valid_774216
  var valid_774217 = formData.getOrDefault("EnvironmentName")
  valid_774217 = validateParameter(valid_774217, JString, required = false,
                                 default = nil)
  if valid_774217 != nil:
    section.add "EnvironmentName", valid_774217
  var valid_774218 = formData.getOrDefault("StartTime")
  valid_774218 = validateParameter(valid_774218, JString, required = false,
                                 default = nil)
  if valid_774218 != nil:
    section.add "StartTime", valid_774218
  var valid_774219 = formData.getOrDefault("ApplicationName")
  valid_774219 = validateParameter(valid_774219, JString, required = false,
                                 default = nil)
  if valid_774219 != nil:
    section.add "ApplicationName", valid_774219
  var valid_774220 = formData.getOrDefault("EndTime")
  valid_774220 = validateParameter(valid_774220, JString, required = false,
                                 default = nil)
  if valid_774220 != nil:
    section.add "EndTime", valid_774220
  var valid_774221 = formData.getOrDefault("PlatformArn")
  valid_774221 = validateParameter(valid_774221, JString, required = false,
                                 default = nil)
  if valid_774221 != nil:
    section.add "PlatformArn", valid_774221
  var valid_774222 = formData.getOrDefault("MaxRecords")
  valid_774222 = validateParameter(valid_774222, JInt, required = false, default = nil)
  if valid_774222 != nil:
    section.add "MaxRecords", valid_774222
  var valid_774223 = formData.getOrDefault("RequestId")
  valid_774223 = validateParameter(valid_774223, JString, required = false,
                                 default = nil)
  if valid_774223 != nil:
    section.add "RequestId", valid_774223
  var valid_774224 = formData.getOrDefault("TemplateName")
  valid_774224 = validateParameter(valid_774224, JString, required = false,
                                 default = nil)
  if valid_774224 != nil:
    section.add "TemplateName", valid_774224
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774225: Call_PostDescribeEvents_774201; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns list of event descriptions matching criteria up to the last 6 weeks.</p> <note> <p>This action returns the most recent 1,000 events from the specified <code>NextToken</code>.</p> </note>
  ## 
  let valid = call_774225.validator(path, query, header, formData, body)
  let scheme = call_774225.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774225.url(scheme.get, call_774225.host, call_774225.base,
                         call_774225.route, valid.getOrDefault("path"))
  result = hook(call_774225, url, valid)

proc call*(call_774226: Call_PostDescribeEvents_774201; NextToken: string = "";
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
  var query_774227 = newJObject()
  var formData_774228 = newJObject()
  add(formData_774228, "NextToken", newJString(NextToken))
  add(formData_774228, "VersionLabel", newJString(VersionLabel))
  add(formData_774228, "Severity", newJString(Severity))
  add(formData_774228, "EnvironmentId", newJString(EnvironmentId))
  add(formData_774228, "EnvironmentName", newJString(EnvironmentName))
  add(formData_774228, "StartTime", newJString(StartTime))
  add(query_774227, "Action", newJString(Action))
  add(formData_774228, "ApplicationName", newJString(ApplicationName))
  add(formData_774228, "EndTime", newJString(EndTime))
  add(formData_774228, "PlatformArn", newJString(PlatformArn))
  add(formData_774228, "MaxRecords", newJInt(MaxRecords))
  add(formData_774228, "RequestId", newJString(RequestId))
  add(formData_774228, "TemplateName", newJString(TemplateName))
  add(query_774227, "Version", newJString(Version))
  result = call_774226.call(nil, query_774227, nil, formData_774228, nil)

var postDescribeEvents* = Call_PostDescribeEvents_774201(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_774202, base: "/",
    url: url_PostDescribeEvents_774203, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_774174 = ref object of OpenApiRestCall_772598
proc url_GetDescribeEvents_774176(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEvents_774175(path: JsonNode; query: JsonNode;
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
  var valid_774177 = query.getOrDefault("VersionLabel")
  valid_774177 = validateParameter(valid_774177, JString, required = false,
                                 default = nil)
  if valid_774177 != nil:
    section.add "VersionLabel", valid_774177
  var valid_774178 = query.getOrDefault("MaxRecords")
  valid_774178 = validateParameter(valid_774178, JInt, required = false, default = nil)
  if valid_774178 != nil:
    section.add "MaxRecords", valid_774178
  var valid_774179 = query.getOrDefault("ApplicationName")
  valid_774179 = validateParameter(valid_774179, JString, required = false,
                                 default = nil)
  if valid_774179 != nil:
    section.add "ApplicationName", valid_774179
  var valid_774180 = query.getOrDefault("StartTime")
  valid_774180 = validateParameter(valid_774180, JString, required = false,
                                 default = nil)
  if valid_774180 != nil:
    section.add "StartTime", valid_774180
  var valid_774181 = query.getOrDefault("PlatformArn")
  valid_774181 = validateParameter(valid_774181, JString, required = false,
                                 default = nil)
  if valid_774181 != nil:
    section.add "PlatformArn", valid_774181
  var valid_774182 = query.getOrDefault("NextToken")
  valid_774182 = validateParameter(valid_774182, JString, required = false,
                                 default = nil)
  if valid_774182 != nil:
    section.add "NextToken", valid_774182
  var valid_774183 = query.getOrDefault("EnvironmentName")
  valid_774183 = validateParameter(valid_774183, JString, required = false,
                                 default = nil)
  if valid_774183 != nil:
    section.add "EnvironmentName", valid_774183
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774184 = query.getOrDefault("Action")
  valid_774184 = validateParameter(valid_774184, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_774184 != nil:
    section.add "Action", valid_774184
  var valid_774185 = query.getOrDefault("EnvironmentId")
  valid_774185 = validateParameter(valid_774185, JString, required = false,
                                 default = nil)
  if valid_774185 != nil:
    section.add "EnvironmentId", valid_774185
  var valid_774186 = query.getOrDefault("TemplateName")
  valid_774186 = validateParameter(valid_774186, JString, required = false,
                                 default = nil)
  if valid_774186 != nil:
    section.add "TemplateName", valid_774186
  var valid_774187 = query.getOrDefault("Severity")
  valid_774187 = validateParameter(valid_774187, JString, required = false,
                                 default = newJString("TRACE"))
  if valid_774187 != nil:
    section.add "Severity", valid_774187
  var valid_774188 = query.getOrDefault("RequestId")
  valid_774188 = validateParameter(valid_774188, JString, required = false,
                                 default = nil)
  if valid_774188 != nil:
    section.add "RequestId", valid_774188
  var valid_774189 = query.getOrDefault("EndTime")
  valid_774189 = validateParameter(valid_774189, JString, required = false,
                                 default = nil)
  if valid_774189 != nil:
    section.add "EndTime", valid_774189
  var valid_774190 = query.getOrDefault("Version")
  valid_774190 = validateParameter(valid_774190, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_774190 != nil:
    section.add "Version", valid_774190
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774191 = header.getOrDefault("X-Amz-Date")
  valid_774191 = validateParameter(valid_774191, JString, required = false,
                                 default = nil)
  if valid_774191 != nil:
    section.add "X-Amz-Date", valid_774191
  var valid_774192 = header.getOrDefault("X-Amz-Security-Token")
  valid_774192 = validateParameter(valid_774192, JString, required = false,
                                 default = nil)
  if valid_774192 != nil:
    section.add "X-Amz-Security-Token", valid_774192
  var valid_774193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774193 = validateParameter(valid_774193, JString, required = false,
                                 default = nil)
  if valid_774193 != nil:
    section.add "X-Amz-Content-Sha256", valid_774193
  var valid_774194 = header.getOrDefault("X-Amz-Algorithm")
  valid_774194 = validateParameter(valid_774194, JString, required = false,
                                 default = nil)
  if valid_774194 != nil:
    section.add "X-Amz-Algorithm", valid_774194
  var valid_774195 = header.getOrDefault("X-Amz-Signature")
  valid_774195 = validateParameter(valid_774195, JString, required = false,
                                 default = nil)
  if valid_774195 != nil:
    section.add "X-Amz-Signature", valid_774195
  var valid_774196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774196 = validateParameter(valid_774196, JString, required = false,
                                 default = nil)
  if valid_774196 != nil:
    section.add "X-Amz-SignedHeaders", valid_774196
  var valid_774197 = header.getOrDefault("X-Amz-Credential")
  valid_774197 = validateParameter(valid_774197, JString, required = false,
                                 default = nil)
  if valid_774197 != nil:
    section.add "X-Amz-Credential", valid_774197
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774198: Call_GetDescribeEvents_774174; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns list of event descriptions matching criteria up to the last 6 weeks.</p> <note> <p>This action returns the most recent 1,000 events from the specified <code>NextToken</code>.</p> </note>
  ## 
  let valid = call_774198.validator(path, query, header, formData, body)
  let scheme = call_774198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774198.url(scheme.get, call_774198.host, call_774198.base,
                         call_774198.route, valid.getOrDefault("path"))
  result = hook(call_774198, url, valid)

proc call*(call_774199: Call_GetDescribeEvents_774174; VersionLabel: string = "";
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
  var query_774200 = newJObject()
  add(query_774200, "VersionLabel", newJString(VersionLabel))
  add(query_774200, "MaxRecords", newJInt(MaxRecords))
  add(query_774200, "ApplicationName", newJString(ApplicationName))
  add(query_774200, "StartTime", newJString(StartTime))
  add(query_774200, "PlatformArn", newJString(PlatformArn))
  add(query_774200, "NextToken", newJString(NextToken))
  add(query_774200, "EnvironmentName", newJString(EnvironmentName))
  add(query_774200, "Action", newJString(Action))
  add(query_774200, "EnvironmentId", newJString(EnvironmentId))
  add(query_774200, "TemplateName", newJString(TemplateName))
  add(query_774200, "Severity", newJString(Severity))
  add(query_774200, "RequestId", newJString(RequestId))
  add(query_774200, "EndTime", newJString(EndTime))
  add(query_774200, "Version", newJString(Version))
  result = call_774199.call(nil, query_774200, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_774174(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_774175,
    base: "/", url: url_GetDescribeEvents_774176,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeInstancesHealth_774248 = ref object of OpenApiRestCall_772598
proc url_PostDescribeInstancesHealth_774250(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeInstancesHealth_774249(path: JsonNode; query: JsonNode;
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
  var valid_774251 = query.getOrDefault("Action")
  valid_774251 = validateParameter(valid_774251, JString, required = true, default = newJString(
      "DescribeInstancesHealth"))
  if valid_774251 != nil:
    section.add "Action", valid_774251
  var valid_774252 = query.getOrDefault("Version")
  valid_774252 = validateParameter(valid_774252, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_774252 != nil:
    section.add "Version", valid_774252
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774253 = header.getOrDefault("X-Amz-Date")
  valid_774253 = validateParameter(valid_774253, JString, required = false,
                                 default = nil)
  if valid_774253 != nil:
    section.add "X-Amz-Date", valid_774253
  var valid_774254 = header.getOrDefault("X-Amz-Security-Token")
  valid_774254 = validateParameter(valid_774254, JString, required = false,
                                 default = nil)
  if valid_774254 != nil:
    section.add "X-Amz-Security-Token", valid_774254
  var valid_774255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774255 = validateParameter(valid_774255, JString, required = false,
                                 default = nil)
  if valid_774255 != nil:
    section.add "X-Amz-Content-Sha256", valid_774255
  var valid_774256 = header.getOrDefault("X-Amz-Algorithm")
  valid_774256 = validateParameter(valid_774256, JString, required = false,
                                 default = nil)
  if valid_774256 != nil:
    section.add "X-Amz-Algorithm", valid_774256
  var valid_774257 = header.getOrDefault("X-Amz-Signature")
  valid_774257 = validateParameter(valid_774257, JString, required = false,
                                 default = nil)
  if valid_774257 != nil:
    section.add "X-Amz-Signature", valid_774257
  var valid_774258 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774258 = validateParameter(valid_774258, JString, required = false,
                                 default = nil)
  if valid_774258 != nil:
    section.add "X-Amz-SignedHeaders", valid_774258
  var valid_774259 = header.getOrDefault("X-Amz-Credential")
  valid_774259 = validateParameter(valid_774259, JString, required = false,
                                 default = nil)
  if valid_774259 != nil:
    section.add "X-Amz-Credential", valid_774259
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
  var valid_774260 = formData.getOrDefault("NextToken")
  valid_774260 = validateParameter(valid_774260, JString, required = false,
                                 default = nil)
  if valid_774260 != nil:
    section.add "NextToken", valid_774260
  var valid_774261 = formData.getOrDefault("EnvironmentId")
  valid_774261 = validateParameter(valid_774261, JString, required = false,
                                 default = nil)
  if valid_774261 != nil:
    section.add "EnvironmentId", valid_774261
  var valid_774262 = formData.getOrDefault("EnvironmentName")
  valid_774262 = validateParameter(valid_774262, JString, required = false,
                                 default = nil)
  if valid_774262 != nil:
    section.add "EnvironmentName", valid_774262
  var valid_774263 = formData.getOrDefault("AttributeNames")
  valid_774263 = validateParameter(valid_774263, JArray, required = false,
                                 default = nil)
  if valid_774263 != nil:
    section.add "AttributeNames", valid_774263
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774264: Call_PostDescribeInstancesHealth_774248; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves detailed information about the health of instances in your AWS Elastic Beanstalk. This operation requires <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/health-enhanced.html">enhanced health reporting</a>.
  ## 
  let valid = call_774264.validator(path, query, header, formData, body)
  let scheme = call_774264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774264.url(scheme.get, call_774264.host, call_774264.base,
                         call_774264.route, valid.getOrDefault("path"))
  result = hook(call_774264, url, valid)

proc call*(call_774265: Call_PostDescribeInstancesHealth_774248;
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
  var query_774266 = newJObject()
  var formData_774267 = newJObject()
  add(formData_774267, "NextToken", newJString(NextToken))
  add(formData_774267, "EnvironmentId", newJString(EnvironmentId))
  add(formData_774267, "EnvironmentName", newJString(EnvironmentName))
  add(query_774266, "Action", newJString(Action))
  if AttributeNames != nil:
    formData_774267.add "AttributeNames", AttributeNames
  add(query_774266, "Version", newJString(Version))
  result = call_774265.call(nil, query_774266, nil, formData_774267, nil)

var postDescribeInstancesHealth* = Call_PostDescribeInstancesHealth_774248(
    name: "postDescribeInstancesHealth", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeInstancesHealth",
    validator: validate_PostDescribeInstancesHealth_774249, base: "/",
    url: url_PostDescribeInstancesHealth_774250,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeInstancesHealth_774229 = ref object of OpenApiRestCall_772598
proc url_GetDescribeInstancesHealth_774231(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeInstancesHealth_774230(path: JsonNode; query: JsonNode;
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
  var valid_774232 = query.getOrDefault("AttributeNames")
  valid_774232 = validateParameter(valid_774232, JArray, required = false,
                                 default = nil)
  if valid_774232 != nil:
    section.add "AttributeNames", valid_774232
  var valid_774233 = query.getOrDefault("NextToken")
  valid_774233 = validateParameter(valid_774233, JString, required = false,
                                 default = nil)
  if valid_774233 != nil:
    section.add "NextToken", valid_774233
  var valid_774234 = query.getOrDefault("EnvironmentName")
  valid_774234 = validateParameter(valid_774234, JString, required = false,
                                 default = nil)
  if valid_774234 != nil:
    section.add "EnvironmentName", valid_774234
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774235 = query.getOrDefault("Action")
  valid_774235 = validateParameter(valid_774235, JString, required = true, default = newJString(
      "DescribeInstancesHealth"))
  if valid_774235 != nil:
    section.add "Action", valid_774235
  var valid_774236 = query.getOrDefault("EnvironmentId")
  valid_774236 = validateParameter(valid_774236, JString, required = false,
                                 default = nil)
  if valid_774236 != nil:
    section.add "EnvironmentId", valid_774236
  var valid_774237 = query.getOrDefault("Version")
  valid_774237 = validateParameter(valid_774237, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_774237 != nil:
    section.add "Version", valid_774237
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774238 = header.getOrDefault("X-Amz-Date")
  valid_774238 = validateParameter(valid_774238, JString, required = false,
                                 default = nil)
  if valid_774238 != nil:
    section.add "X-Amz-Date", valid_774238
  var valid_774239 = header.getOrDefault("X-Amz-Security-Token")
  valid_774239 = validateParameter(valid_774239, JString, required = false,
                                 default = nil)
  if valid_774239 != nil:
    section.add "X-Amz-Security-Token", valid_774239
  var valid_774240 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774240 = validateParameter(valid_774240, JString, required = false,
                                 default = nil)
  if valid_774240 != nil:
    section.add "X-Amz-Content-Sha256", valid_774240
  var valid_774241 = header.getOrDefault("X-Amz-Algorithm")
  valid_774241 = validateParameter(valid_774241, JString, required = false,
                                 default = nil)
  if valid_774241 != nil:
    section.add "X-Amz-Algorithm", valid_774241
  var valid_774242 = header.getOrDefault("X-Amz-Signature")
  valid_774242 = validateParameter(valid_774242, JString, required = false,
                                 default = nil)
  if valid_774242 != nil:
    section.add "X-Amz-Signature", valid_774242
  var valid_774243 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774243 = validateParameter(valid_774243, JString, required = false,
                                 default = nil)
  if valid_774243 != nil:
    section.add "X-Amz-SignedHeaders", valid_774243
  var valid_774244 = header.getOrDefault("X-Amz-Credential")
  valid_774244 = validateParameter(valid_774244, JString, required = false,
                                 default = nil)
  if valid_774244 != nil:
    section.add "X-Amz-Credential", valid_774244
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774245: Call_GetDescribeInstancesHealth_774229; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves detailed information about the health of instances in your AWS Elastic Beanstalk. This operation requires <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/health-enhanced.html">enhanced health reporting</a>.
  ## 
  let valid = call_774245.validator(path, query, header, formData, body)
  let scheme = call_774245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774245.url(scheme.get, call_774245.host, call_774245.base,
                         call_774245.route, valid.getOrDefault("path"))
  result = hook(call_774245, url, valid)

proc call*(call_774246: Call_GetDescribeInstancesHealth_774229;
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
  var query_774247 = newJObject()
  if AttributeNames != nil:
    query_774247.add "AttributeNames", AttributeNames
  add(query_774247, "NextToken", newJString(NextToken))
  add(query_774247, "EnvironmentName", newJString(EnvironmentName))
  add(query_774247, "Action", newJString(Action))
  add(query_774247, "EnvironmentId", newJString(EnvironmentId))
  add(query_774247, "Version", newJString(Version))
  result = call_774246.call(nil, query_774247, nil, nil, nil)

var getDescribeInstancesHealth* = Call_GetDescribeInstancesHealth_774229(
    name: "getDescribeInstancesHealth", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeInstancesHealth",
    validator: validate_GetDescribeInstancesHealth_774230, base: "/",
    url: url_GetDescribeInstancesHealth_774231,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribePlatformVersion_774284 = ref object of OpenApiRestCall_772598
proc url_PostDescribePlatformVersion_774286(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribePlatformVersion_774285(path: JsonNode; query: JsonNode;
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
  var valid_774287 = query.getOrDefault("Action")
  valid_774287 = validateParameter(valid_774287, JString, required = true, default = newJString(
      "DescribePlatformVersion"))
  if valid_774287 != nil:
    section.add "Action", valid_774287
  var valid_774288 = query.getOrDefault("Version")
  valid_774288 = validateParameter(valid_774288, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_774288 != nil:
    section.add "Version", valid_774288
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774289 = header.getOrDefault("X-Amz-Date")
  valid_774289 = validateParameter(valid_774289, JString, required = false,
                                 default = nil)
  if valid_774289 != nil:
    section.add "X-Amz-Date", valid_774289
  var valid_774290 = header.getOrDefault("X-Amz-Security-Token")
  valid_774290 = validateParameter(valid_774290, JString, required = false,
                                 default = nil)
  if valid_774290 != nil:
    section.add "X-Amz-Security-Token", valid_774290
  var valid_774291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774291 = validateParameter(valid_774291, JString, required = false,
                                 default = nil)
  if valid_774291 != nil:
    section.add "X-Amz-Content-Sha256", valid_774291
  var valid_774292 = header.getOrDefault("X-Amz-Algorithm")
  valid_774292 = validateParameter(valid_774292, JString, required = false,
                                 default = nil)
  if valid_774292 != nil:
    section.add "X-Amz-Algorithm", valid_774292
  var valid_774293 = header.getOrDefault("X-Amz-Signature")
  valid_774293 = validateParameter(valid_774293, JString, required = false,
                                 default = nil)
  if valid_774293 != nil:
    section.add "X-Amz-Signature", valid_774293
  var valid_774294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774294 = validateParameter(valid_774294, JString, required = false,
                                 default = nil)
  if valid_774294 != nil:
    section.add "X-Amz-SignedHeaders", valid_774294
  var valid_774295 = header.getOrDefault("X-Amz-Credential")
  valid_774295 = validateParameter(valid_774295, JString, required = false,
                                 default = nil)
  if valid_774295 != nil:
    section.add "X-Amz-Credential", valid_774295
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformArn: JString
  ##              : The ARN of the version of the platform.
  section = newJObject()
  var valid_774296 = formData.getOrDefault("PlatformArn")
  valid_774296 = validateParameter(valid_774296, JString, required = false,
                                 default = nil)
  if valid_774296 != nil:
    section.add "PlatformArn", valid_774296
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774297: Call_PostDescribePlatformVersion_774284; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the version of the platform.
  ## 
  let valid = call_774297.validator(path, query, header, formData, body)
  let scheme = call_774297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774297.url(scheme.get, call_774297.host, call_774297.base,
                         call_774297.route, valid.getOrDefault("path"))
  result = hook(call_774297, url, valid)

proc call*(call_774298: Call_PostDescribePlatformVersion_774284;
          Action: string = "DescribePlatformVersion"; PlatformArn: string = "";
          Version: string = "2010-12-01"): Recallable =
  ## postDescribePlatformVersion
  ## Describes the version of the platform.
  ##   Action: string (required)
  ##   PlatformArn: string
  ##              : The ARN of the version of the platform.
  ##   Version: string (required)
  var query_774299 = newJObject()
  var formData_774300 = newJObject()
  add(query_774299, "Action", newJString(Action))
  add(formData_774300, "PlatformArn", newJString(PlatformArn))
  add(query_774299, "Version", newJString(Version))
  result = call_774298.call(nil, query_774299, nil, formData_774300, nil)

var postDescribePlatformVersion* = Call_PostDescribePlatformVersion_774284(
    name: "postDescribePlatformVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribePlatformVersion",
    validator: validate_PostDescribePlatformVersion_774285, base: "/",
    url: url_PostDescribePlatformVersion_774286,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribePlatformVersion_774268 = ref object of OpenApiRestCall_772598
proc url_GetDescribePlatformVersion_774270(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribePlatformVersion_774269(path: JsonNode; query: JsonNode;
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
  var valid_774271 = query.getOrDefault("PlatformArn")
  valid_774271 = validateParameter(valid_774271, JString, required = false,
                                 default = nil)
  if valid_774271 != nil:
    section.add "PlatformArn", valid_774271
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774272 = query.getOrDefault("Action")
  valid_774272 = validateParameter(valid_774272, JString, required = true, default = newJString(
      "DescribePlatformVersion"))
  if valid_774272 != nil:
    section.add "Action", valid_774272
  var valid_774273 = query.getOrDefault("Version")
  valid_774273 = validateParameter(valid_774273, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_774273 != nil:
    section.add "Version", valid_774273
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774274 = header.getOrDefault("X-Amz-Date")
  valid_774274 = validateParameter(valid_774274, JString, required = false,
                                 default = nil)
  if valid_774274 != nil:
    section.add "X-Amz-Date", valid_774274
  var valid_774275 = header.getOrDefault("X-Amz-Security-Token")
  valid_774275 = validateParameter(valid_774275, JString, required = false,
                                 default = nil)
  if valid_774275 != nil:
    section.add "X-Amz-Security-Token", valid_774275
  var valid_774276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774276 = validateParameter(valid_774276, JString, required = false,
                                 default = nil)
  if valid_774276 != nil:
    section.add "X-Amz-Content-Sha256", valid_774276
  var valid_774277 = header.getOrDefault("X-Amz-Algorithm")
  valid_774277 = validateParameter(valid_774277, JString, required = false,
                                 default = nil)
  if valid_774277 != nil:
    section.add "X-Amz-Algorithm", valid_774277
  var valid_774278 = header.getOrDefault("X-Amz-Signature")
  valid_774278 = validateParameter(valid_774278, JString, required = false,
                                 default = nil)
  if valid_774278 != nil:
    section.add "X-Amz-Signature", valid_774278
  var valid_774279 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774279 = validateParameter(valid_774279, JString, required = false,
                                 default = nil)
  if valid_774279 != nil:
    section.add "X-Amz-SignedHeaders", valid_774279
  var valid_774280 = header.getOrDefault("X-Amz-Credential")
  valid_774280 = validateParameter(valid_774280, JString, required = false,
                                 default = nil)
  if valid_774280 != nil:
    section.add "X-Amz-Credential", valid_774280
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774281: Call_GetDescribePlatformVersion_774268; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the version of the platform.
  ## 
  let valid = call_774281.validator(path, query, header, formData, body)
  let scheme = call_774281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774281.url(scheme.get, call_774281.host, call_774281.base,
                         call_774281.route, valid.getOrDefault("path"))
  result = hook(call_774281, url, valid)

proc call*(call_774282: Call_GetDescribePlatformVersion_774268;
          PlatformArn: string = ""; Action: string = "DescribePlatformVersion";
          Version: string = "2010-12-01"): Recallable =
  ## getDescribePlatformVersion
  ## Describes the version of the platform.
  ##   PlatformArn: string
  ##              : The ARN of the version of the platform.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_774283 = newJObject()
  add(query_774283, "PlatformArn", newJString(PlatformArn))
  add(query_774283, "Action", newJString(Action))
  add(query_774283, "Version", newJString(Version))
  result = call_774282.call(nil, query_774283, nil, nil, nil)

var getDescribePlatformVersion* = Call_GetDescribePlatformVersion_774268(
    name: "getDescribePlatformVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribePlatformVersion",
    validator: validate_GetDescribePlatformVersion_774269, base: "/",
    url: url_GetDescribePlatformVersion_774270,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListAvailableSolutionStacks_774316 = ref object of OpenApiRestCall_772598
proc url_PostListAvailableSolutionStacks_774318(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListAvailableSolutionStacks_774317(path: JsonNode;
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
  var valid_774319 = query.getOrDefault("Action")
  valid_774319 = validateParameter(valid_774319, JString, required = true, default = newJString(
      "ListAvailableSolutionStacks"))
  if valid_774319 != nil:
    section.add "Action", valid_774319
  var valid_774320 = query.getOrDefault("Version")
  valid_774320 = validateParameter(valid_774320, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_774320 != nil:
    section.add "Version", valid_774320
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774321 = header.getOrDefault("X-Amz-Date")
  valid_774321 = validateParameter(valid_774321, JString, required = false,
                                 default = nil)
  if valid_774321 != nil:
    section.add "X-Amz-Date", valid_774321
  var valid_774322 = header.getOrDefault("X-Amz-Security-Token")
  valid_774322 = validateParameter(valid_774322, JString, required = false,
                                 default = nil)
  if valid_774322 != nil:
    section.add "X-Amz-Security-Token", valid_774322
  var valid_774323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774323 = validateParameter(valid_774323, JString, required = false,
                                 default = nil)
  if valid_774323 != nil:
    section.add "X-Amz-Content-Sha256", valid_774323
  var valid_774324 = header.getOrDefault("X-Amz-Algorithm")
  valid_774324 = validateParameter(valid_774324, JString, required = false,
                                 default = nil)
  if valid_774324 != nil:
    section.add "X-Amz-Algorithm", valid_774324
  var valid_774325 = header.getOrDefault("X-Amz-Signature")
  valid_774325 = validateParameter(valid_774325, JString, required = false,
                                 default = nil)
  if valid_774325 != nil:
    section.add "X-Amz-Signature", valid_774325
  var valid_774326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774326 = validateParameter(valid_774326, JString, required = false,
                                 default = nil)
  if valid_774326 != nil:
    section.add "X-Amz-SignedHeaders", valid_774326
  var valid_774327 = header.getOrDefault("X-Amz-Credential")
  valid_774327 = validateParameter(valid_774327, JString, required = false,
                                 default = nil)
  if valid_774327 != nil:
    section.add "X-Amz-Credential", valid_774327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774328: Call_PostListAvailableSolutionStacks_774316;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ## 
  let valid = call_774328.validator(path, query, header, formData, body)
  let scheme = call_774328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774328.url(scheme.get, call_774328.host, call_774328.base,
                         call_774328.route, valid.getOrDefault("path"))
  result = hook(call_774328, url, valid)

proc call*(call_774329: Call_PostListAvailableSolutionStacks_774316;
          Action: string = "ListAvailableSolutionStacks";
          Version: string = "2010-12-01"): Recallable =
  ## postListAvailableSolutionStacks
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_774330 = newJObject()
  add(query_774330, "Action", newJString(Action))
  add(query_774330, "Version", newJString(Version))
  result = call_774329.call(nil, query_774330, nil, nil, nil)

var postListAvailableSolutionStacks* = Call_PostListAvailableSolutionStacks_774316(
    name: "postListAvailableSolutionStacks", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListAvailableSolutionStacks",
    validator: validate_PostListAvailableSolutionStacks_774317, base: "/",
    url: url_PostListAvailableSolutionStacks_774318,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListAvailableSolutionStacks_774301 = ref object of OpenApiRestCall_772598
proc url_GetListAvailableSolutionStacks_774303(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListAvailableSolutionStacks_774302(path: JsonNode;
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
  var valid_774304 = query.getOrDefault("Action")
  valid_774304 = validateParameter(valid_774304, JString, required = true, default = newJString(
      "ListAvailableSolutionStacks"))
  if valid_774304 != nil:
    section.add "Action", valid_774304
  var valid_774305 = query.getOrDefault("Version")
  valid_774305 = validateParameter(valid_774305, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_774305 != nil:
    section.add "Version", valid_774305
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774306 = header.getOrDefault("X-Amz-Date")
  valid_774306 = validateParameter(valid_774306, JString, required = false,
                                 default = nil)
  if valid_774306 != nil:
    section.add "X-Amz-Date", valid_774306
  var valid_774307 = header.getOrDefault("X-Amz-Security-Token")
  valid_774307 = validateParameter(valid_774307, JString, required = false,
                                 default = nil)
  if valid_774307 != nil:
    section.add "X-Amz-Security-Token", valid_774307
  var valid_774308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774308 = validateParameter(valid_774308, JString, required = false,
                                 default = nil)
  if valid_774308 != nil:
    section.add "X-Amz-Content-Sha256", valid_774308
  var valid_774309 = header.getOrDefault("X-Amz-Algorithm")
  valid_774309 = validateParameter(valid_774309, JString, required = false,
                                 default = nil)
  if valid_774309 != nil:
    section.add "X-Amz-Algorithm", valid_774309
  var valid_774310 = header.getOrDefault("X-Amz-Signature")
  valid_774310 = validateParameter(valid_774310, JString, required = false,
                                 default = nil)
  if valid_774310 != nil:
    section.add "X-Amz-Signature", valid_774310
  var valid_774311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774311 = validateParameter(valid_774311, JString, required = false,
                                 default = nil)
  if valid_774311 != nil:
    section.add "X-Amz-SignedHeaders", valid_774311
  var valid_774312 = header.getOrDefault("X-Amz-Credential")
  valid_774312 = validateParameter(valid_774312, JString, required = false,
                                 default = nil)
  if valid_774312 != nil:
    section.add "X-Amz-Credential", valid_774312
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774313: Call_GetListAvailableSolutionStacks_774301; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ## 
  let valid = call_774313.validator(path, query, header, formData, body)
  let scheme = call_774313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774313.url(scheme.get, call_774313.host, call_774313.base,
                         call_774313.route, valid.getOrDefault("path"))
  result = hook(call_774313, url, valid)

proc call*(call_774314: Call_GetListAvailableSolutionStacks_774301;
          Action: string = "ListAvailableSolutionStacks";
          Version: string = "2010-12-01"): Recallable =
  ## getListAvailableSolutionStacks
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_774315 = newJObject()
  add(query_774315, "Action", newJString(Action))
  add(query_774315, "Version", newJString(Version))
  result = call_774314.call(nil, query_774315, nil, nil, nil)

var getListAvailableSolutionStacks* = Call_GetListAvailableSolutionStacks_774301(
    name: "getListAvailableSolutionStacks", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListAvailableSolutionStacks",
    validator: validate_GetListAvailableSolutionStacks_774302, base: "/",
    url: url_GetListAvailableSolutionStacks_774303,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListPlatformVersions_774349 = ref object of OpenApiRestCall_772598
proc url_PostListPlatformVersions_774351(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListPlatformVersions_774350(path: JsonNode; query: JsonNode;
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
  var valid_774352 = query.getOrDefault("Action")
  valid_774352 = validateParameter(valid_774352, JString, required = true,
                                 default = newJString("ListPlatformVersions"))
  if valid_774352 != nil:
    section.add "Action", valid_774352
  var valid_774353 = query.getOrDefault("Version")
  valid_774353 = validateParameter(valid_774353, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_774353 != nil:
    section.add "Version", valid_774353
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774354 = header.getOrDefault("X-Amz-Date")
  valid_774354 = validateParameter(valid_774354, JString, required = false,
                                 default = nil)
  if valid_774354 != nil:
    section.add "X-Amz-Date", valid_774354
  var valid_774355 = header.getOrDefault("X-Amz-Security-Token")
  valid_774355 = validateParameter(valid_774355, JString, required = false,
                                 default = nil)
  if valid_774355 != nil:
    section.add "X-Amz-Security-Token", valid_774355
  var valid_774356 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774356 = validateParameter(valid_774356, JString, required = false,
                                 default = nil)
  if valid_774356 != nil:
    section.add "X-Amz-Content-Sha256", valid_774356
  var valid_774357 = header.getOrDefault("X-Amz-Algorithm")
  valid_774357 = validateParameter(valid_774357, JString, required = false,
                                 default = nil)
  if valid_774357 != nil:
    section.add "X-Amz-Algorithm", valid_774357
  var valid_774358 = header.getOrDefault("X-Amz-Signature")
  valid_774358 = validateParameter(valid_774358, JString, required = false,
                                 default = nil)
  if valid_774358 != nil:
    section.add "X-Amz-Signature", valid_774358
  var valid_774359 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774359 = validateParameter(valid_774359, JString, required = false,
                                 default = nil)
  if valid_774359 != nil:
    section.add "X-Amz-SignedHeaders", valid_774359
  var valid_774360 = header.getOrDefault("X-Amz-Credential")
  valid_774360 = validateParameter(valid_774360, JString, required = false,
                                 default = nil)
  if valid_774360 != nil:
    section.add "X-Amz-Credential", valid_774360
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : The starting index into the remaining list of platforms. Use the <code>NextToken</code> value from a previous <code>ListPlatformVersion</code> call.
  ##   Filters: JArray
  ##          : List only the platforms where the platform member value relates to one of the supplied values.
  ##   MaxRecords: JInt
  ##             : The maximum number of platform values returned in one call.
  section = newJObject()
  var valid_774361 = formData.getOrDefault("NextToken")
  valid_774361 = validateParameter(valid_774361, JString, required = false,
                                 default = nil)
  if valid_774361 != nil:
    section.add "NextToken", valid_774361
  var valid_774362 = formData.getOrDefault("Filters")
  valid_774362 = validateParameter(valid_774362, JArray, required = false,
                                 default = nil)
  if valid_774362 != nil:
    section.add "Filters", valid_774362
  var valid_774363 = formData.getOrDefault("MaxRecords")
  valid_774363 = validateParameter(valid_774363, JInt, required = false, default = nil)
  if valid_774363 != nil:
    section.add "MaxRecords", valid_774363
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774364: Call_PostListPlatformVersions_774349; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the available platforms.
  ## 
  let valid = call_774364.validator(path, query, header, formData, body)
  let scheme = call_774364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774364.url(scheme.get, call_774364.host, call_774364.base,
                         call_774364.route, valid.getOrDefault("path"))
  result = hook(call_774364, url, valid)

proc call*(call_774365: Call_PostListPlatformVersions_774349;
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
  var query_774366 = newJObject()
  var formData_774367 = newJObject()
  add(formData_774367, "NextToken", newJString(NextToken))
  add(query_774366, "Action", newJString(Action))
  if Filters != nil:
    formData_774367.add "Filters", Filters
  add(formData_774367, "MaxRecords", newJInt(MaxRecords))
  add(query_774366, "Version", newJString(Version))
  result = call_774365.call(nil, query_774366, nil, formData_774367, nil)

var postListPlatformVersions* = Call_PostListPlatformVersions_774349(
    name: "postListPlatformVersions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListPlatformVersions",
    validator: validate_PostListPlatformVersions_774350, base: "/",
    url: url_PostListPlatformVersions_774351, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListPlatformVersions_774331 = ref object of OpenApiRestCall_772598
proc url_GetListPlatformVersions_774333(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListPlatformVersions_774332(path: JsonNode; query: JsonNode;
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
  var valid_774334 = query.getOrDefault("MaxRecords")
  valid_774334 = validateParameter(valid_774334, JInt, required = false, default = nil)
  if valid_774334 != nil:
    section.add "MaxRecords", valid_774334
  var valid_774335 = query.getOrDefault("Filters")
  valid_774335 = validateParameter(valid_774335, JArray, required = false,
                                 default = nil)
  if valid_774335 != nil:
    section.add "Filters", valid_774335
  var valid_774336 = query.getOrDefault("NextToken")
  valid_774336 = validateParameter(valid_774336, JString, required = false,
                                 default = nil)
  if valid_774336 != nil:
    section.add "NextToken", valid_774336
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774337 = query.getOrDefault("Action")
  valid_774337 = validateParameter(valid_774337, JString, required = true,
                                 default = newJString("ListPlatformVersions"))
  if valid_774337 != nil:
    section.add "Action", valid_774337
  var valid_774338 = query.getOrDefault("Version")
  valid_774338 = validateParameter(valid_774338, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_774338 != nil:
    section.add "Version", valid_774338
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774339 = header.getOrDefault("X-Amz-Date")
  valid_774339 = validateParameter(valid_774339, JString, required = false,
                                 default = nil)
  if valid_774339 != nil:
    section.add "X-Amz-Date", valid_774339
  var valid_774340 = header.getOrDefault("X-Amz-Security-Token")
  valid_774340 = validateParameter(valid_774340, JString, required = false,
                                 default = nil)
  if valid_774340 != nil:
    section.add "X-Amz-Security-Token", valid_774340
  var valid_774341 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774341 = validateParameter(valid_774341, JString, required = false,
                                 default = nil)
  if valid_774341 != nil:
    section.add "X-Amz-Content-Sha256", valid_774341
  var valid_774342 = header.getOrDefault("X-Amz-Algorithm")
  valid_774342 = validateParameter(valid_774342, JString, required = false,
                                 default = nil)
  if valid_774342 != nil:
    section.add "X-Amz-Algorithm", valid_774342
  var valid_774343 = header.getOrDefault("X-Amz-Signature")
  valid_774343 = validateParameter(valid_774343, JString, required = false,
                                 default = nil)
  if valid_774343 != nil:
    section.add "X-Amz-Signature", valid_774343
  var valid_774344 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774344 = validateParameter(valid_774344, JString, required = false,
                                 default = nil)
  if valid_774344 != nil:
    section.add "X-Amz-SignedHeaders", valid_774344
  var valid_774345 = header.getOrDefault("X-Amz-Credential")
  valid_774345 = validateParameter(valid_774345, JString, required = false,
                                 default = nil)
  if valid_774345 != nil:
    section.add "X-Amz-Credential", valid_774345
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774346: Call_GetListPlatformVersions_774331; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the available platforms.
  ## 
  let valid = call_774346.validator(path, query, header, formData, body)
  let scheme = call_774346.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774346.url(scheme.get, call_774346.host, call_774346.base,
                         call_774346.route, valid.getOrDefault("path"))
  result = hook(call_774346, url, valid)

proc call*(call_774347: Call_GetListPlatformVersions_774331; MaxRecords: int = 0;
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
  var query_774348 = newJObject()
  add(query_774348, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_774348.add "Filters", Filters
  add(query_774348, "NextToken", newJString(NextToken))
  add(query_774348, "Action", newJString(Action))
  add(query_774348, "Version", newJString(Version))
  result = call_774347.call(nil, query_774348, nil, nil, nil)

var getListPlatformVersions* = Call_GetListPlatformVersions_774331(
    name: "getListPlatformVersions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListPlatformVersions",
    validator: validate_GetListPlatformVersions_774332, base: "/",
    url: url_GetListPlatformVersions_774333, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_774384 = ref object of OpenApiRestCall_772598
proc url_PostListTagsForResource_774386(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListTagsForResource_774385(path: JsonNode; query: JsonNode;
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
  var valid_774387 = query.getOrDefault("Action")
  valid_774387 = validateParameter(valid_774387, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_774387 != nil:
    section.add "Action", valid_774387
  var valid_774388 = query.getOrDefault("Version")
  valid_774388 = validateParameter(valid_774388, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_774388 != nil:
    section.add "Version", valid_774388
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774389 = header.getOrDefault("X-Amz-Date")
  valid_774389 = validateParameter(valid_774389, JString, required = false,
                                 default = nil)
  if valid_774389 != nil:
    section.add "X-Amz-Date", valid_774389
  var valid_774390 = header.getOrDefault("X-Amz-Security-Token")
  valid_774390 = validateParameter(valid_774390, JString, required = false,
                                 default = nil)
  if valid_774390 != nil:
    section.add "X-Amz-Security-Token", valid_774390
  var valid_774391 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774391 = validateParameter(valid_774391, JString, required = false,
                                 default = nil)
  if valid_774391 != nil:
    section.add "X-Amz-Content-Sha256", valid_774391
  var valid_774392 = header.getOrDefault("X-Amz-Algorithm")
  valid_774392 = validateParameter(valid_774392, JString, required = false,
                                 default = nil)
  if valid_774392 != nil:
    section.add "X-Amz-Algorithm", valid_774392
  var valid_774393 = header.getOrDefault("X-Amz-Signature")
  valid_774393 = validateParameter(valid_774393, JString, required = false,
                                 default = nil)
  if valid_774393 != nil:
    section.add "X-Amz-Signature", valid_774393
  var valid_774394 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774394 = validateParameter(valid_774394, JString, required = false,
                                 default = nil)
  if valid_774394 != nil:
    section.add "X-Amz-SignedHeaders", valid_774394
  var valid_774395 = header.getOrDefault("X-Amz-Credential")
  valid_774395 = validateParameter(valid_774395, JString, required = false,
                                 default = nil)
  if valid_774395 != nil:
    section.add "X-Amz-Credential", valid_774395
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArn: JString (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce for which a tag list is requested.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArn` field"
  var valid_774396 = formData.getOrDefault("ResourceArn")
  valid_774396 = validateParameter(valid_774396, JString, required = true,
                                 default = nil)
  if valid_774396 != nil:
    section.add "ResourceArn", valid_774396
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774397: Call_PostListTagsForResource_774384; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ## 
  let valid = call_774397.validator(path, query, header, formData, body)
  let scheme = call_774397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774397.url(scheme.get, call_774397.host, call_774397.base,
                         call_774397.route, valid.getOrDefault("path"))
  result = hook(call_774397, url, valid)

proc call*(call_774398: Call_PostListTagsForResource_774384; ResourceArn: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-12-01"): Recallable =
  ## postListTagsForResource
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ##   Action: string (required)
  ##   ResourceArn: string (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce for which a tag list is requested.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  ##   Version: string (required)
  var query_774399 = newJObject()
  var formData_774400 = newJObject()
  add(query_774399, "Action", newJString(Action))
  add(formData_774400, "ResourceArn", newJString(ResourceArn))
  add(query_774399, "Version", newJString(Version))
  result = call_774398.call(nil, query_774399, nil, formData_774400, nil)

var postListTagsForResource* = Call_PostListTagsForResource_774384(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_774385, base: "/",
    url: url_PostListTagsForResource_774386, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_774368 = ref object of OpenApiRestCall_772598
proc url_GetListTagsForResource_774370(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListTagsForResource_774369(path: JsonNode; query: JsonNode;
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
  var valid_774371 = query.getOrDefault("ResourceArn")
  valid_774371 = validateParameter(valid_774371, JString, required = true,
                                 default = nil)
  if valid_774371 != nil:
    section.add "ResourceArn", valid_774371
  var valid_774372 = query.getOrDefault("Action")
  valid_774372 = validateParameter(valid_774372, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_774372 != nil:
    section.add "Action", valid_774372
  var valid_774373 = query.getOrDefault("Version")
  valid_774373 = validateParameter(valid_774373, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_774373 != nil:
    section.add "Version", valid_774373
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774374 = header.getOrDefault("X-Amz-Date")
  valid_774374 = validateParameter(valid_774374, JString, required = false,
                                 default = nil)
  if valid_774374 != nil:
    section.add "X-Amz-Date", valid_774374
  var valid_774375 = header.getOrDefault("X-Amz-Security-Token")
  valid_774375 = validateParameter(valid_774375, JString, required = false,
                                 default = nil)
  if valid_774375 != nil:
    section.add "X-Amz-Security-Token", valid_774375
  var valid_774376 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774376 = validateParameter(valid_774376, JString, required = false,
                                 default = nil)
  if valid_774376 != nil:
    section.add "X-Amz-Content-Sha256", valid_774376
  var valid_774377 = header.getOrDefault("X-Amz-Algorithm")
  valid_774377 = validateParameter(valid_774377, JString, required = false,
                                 default = nil)
  if valid_774377 != nil:
    section.add "X-Amz-Algorithm", valid_774377
  var valid_774378 = header.getOrDefault("X-Amz-Signature")
  valid_774378 = validateParameter(valid_774378, JString, required = false,
                                 default = nil)
  if valid_774378 != nil:
    section.add "X-Amz-Signature", valid_774378
  var valid_774379 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774379 = validateParameter(valid_774379, JString, required = false,
                                 default = nil)
  if valid_774379 != nil:
    section.add "X-Amz-SignedHeaders", valid_774379
  var valid_774380 = header.getOrDefault("X-Amz-Credential")
  valid_774380 = validateParameter(valid_774380, JString, required = false,
                                 default = nil)
  if valid_774380 != nil:
    section.add "X-Amz-Credential", valid_774380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774381: Call_GetListTagsForResource_774368; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ## 
  let valid = call_774381.validator(path, query, header, formData, body)
  let scheme = call_774381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774381.url(scheme.get, call_774381.host, call_774381.base,
                         call_774381.route, valid.getOrDefault("path"))
  result = hook(call_774381, url, valid)

proc call*(call_774382: Call_GetListTagsForResource_774368; ResourceArn: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-12-01"): Recallable =
  ## getListTagsForResource
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ##   ResourceArn: string (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce for which a tag list is requested.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_774383 = newJObject()
  add(query_774383, "ResourceArn", newJString(ResourceArn))
  add(query_774383, "Action", newJString(Action))
  add(query_774383, "Version", newJString(Version))
  result = call_774382.call(nil, query_774383, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_774368(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_774369, base: "/",
    url: url_GetListTagsForResource_774370, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebuildEnvironment_774418 = ref object of OpenApiRestCall_772598
proc url_PostRebuildEnvironment_774420(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRebuildEnvironment_774419(path: JsonNode; query: JsonNode;
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
  var valid_774421 = query.getOrDefault("Action")
  valid_774421 = validateParameter(valid_774421, JString, required = true,
                                 default = newJString("RebuildEnvironment"))
  if valid_774421 != nil:
    section.add "Action", valid_774421
  var valid_774422 = query.getOrDefault("Version")
  valid_774422 = validateParameter(valid_774422, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_774422 != nil:
    section.add "Version", valid_774422
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774423 = header.getOrDefault("X-Amz-Date")
  valid_774423 = validateParameter(valid_774423, JString, required = false,
                                 default = nil)
  if valid_774423 != nil:
    section.add "X-Amz-Date", valid_774423
  var valid_774424 = header.getOrDefault("X-Amz-Security-Token")
  valid_774424 = validateParameter(valid_774424, JString, required = false,
                                 default = nil)
  if valid_774424 != nil:
    section.add "X-Amz-Security-Token", valid_774424
  var valid_774425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774425 = validateParameter(valid_774425, JString, required = false,
                                 default = nil)
  if valid_774425 != nil:
    section.add "X-Amz-Content-Sha256", valid_774425
  var valid_774426 = header.getOrDefault("X-Amz-Algorithm")
  valid_774426 = validateParameter(valid_774426, JString, required = false,
                                 default = nil)
  if valid_774426 != nil:
    section.add "X-Amz-Algorithm", valid_774426
  var valid_774427 = header.getOrDefault("X-Amz-Signature")
  valid_774427 = validateParameter(valid_774427, JString, required = false,
                                 default = nil)
  if valid_774427 != nil:
    section.add "X-Amz-Signature", valid_774427
  var valid_774428 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774428 = validateParameter(valid_774428, JString, required = false,
                                 default = nil)
  if valid_774428 != nil:
    section.add "X-Amz-SignedHeaders", valid_774428
  var valid_774429 = header.getOrDefault("X-Amz-Credential")
  valid_774429 = validateParameter(valid_774429, JString, required = false,
                                 default = nil)
  if valid_774429 != nil:
    section.add "X-Amz-Credential", valid_774429
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to rebuild.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to rebuild.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_774430 = formData.getOrDefault("EnvironmentId")
  valid_774430 = validateParameter(valid_774430, JString, required = false,
                                 default = nil)
  if valid_774430 != nil:
    section.add "EnvironmentId", valid_774430
  var valid_774431 = formData.getOrDefault("EnvironmentName")
  valid_774431 = validateParameter(valid_774431, JString, required = false,
                                 default = nil)
  if valid_774431 != nil:
    section.add "EnvironmentName", valid_774431
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774432: Call_PostRebuildEnvironment_774418; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes and recreates all of the AWS resources (for example: the Auto Scaling group, load balancer, etc.) for a specified environment and forces a restart.
  ## 
  let valid = call_774432.validator(path, query, header, formData, body)
  let scheme = call_774432.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774432.url(scheme.get, call_774432.host, call_774432.base,
                         call_774432.route, valid.getOrDefault("path"))
  result = hook(call_774432, url, valid)

proc call*(call_774433: Call_PostRebuildEnvironment_774418;
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
  var query_774434 = newJObject()
  var formData_774435 = newJObject()
  add(formData_774435, "EnvironmentId", newJString(EnvironmentId))
  add(formData_774435, "EnvironmentName", newJString(EnvironmentName))
  add(query_774434, "Action", newJString(Action))
  add(query_774434, "Version", newJString(Version))
  result = call_774433.call(nil, query_774434, nil, formData_774435, nil)

var postRebuildEnvironment* = Call_PostRebuildEnvironment_774418(
    name: "postRebuildEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RebuildEnvironment",
    validator: validate_PostRebuildEnvironment_774419, base: "/",
    url: url_PostRebuildEnvironment_774420, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebuildEnvironment_774401 = ref object of OpenApiRestCall_772598
proc url_GetRebuildEnvironment_774403(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRebuildEnvironment_774402(path: JsonNode; query: JsonNode;
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
  var valid_774404 = query.getOrDefault("EnvironmentName")
  valid_774404 = validateParameter(valid_774404, JString, required = false,
                                 default = nil)
  if valid_774404 != nil:
    section.add "EnvironmentName", valid_774404
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774405 = query.getOrDefault("Action")
  valid_774405 = validateParameter(valid_774405, JString, required = true,
                                 default = newJString("RebuildEnvironment"))
  if valid_774405 != nil:
    section.add "Action", valid_774405
  var valid_774406 = query.getOrDefault("EnvironmentId")
  valid_774406 = validateParameter(valid_774406, JString, required = false,
                                 default = nil)
  if valid_774406 != nil:
    section.add "EnvironmentId", valid_774406
  var valid_774407 = query.getOrDefault("Version")
  valid_774407 = validateParameter(valid_774407, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_774407 != nil:
    section.add "Version", valid_774407
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774408 = header.getOrDefault("X-Amz-Date")
  valid_774408 = validateParameter(valid_774408, JString, required = false,
                                 default = nil)
  if valid_774408 != nil:
    section.add "X-Amz-Date", valid_774408
  var valid_774409 = header.getOrDefault("X-Amz-Security-Token")
  valid_774409 = validateParameter(valid_774409, JString, required = false,
                                 default = nil)
  if valid_774409 != nil:
    section.add "X-Amz-Security-Token", valid_774409
  var valid_774410 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774410 = validateParameter(valid_774410, JString, required = false,
                                 default = nil)
  if valid_774410 != nil:
    section.add "X-Amz-Content-Sha256", valid_774410
  var valid_774411 = header.getOrDefault("X-Amz-Algorithm")
  valid_774411 = validateParameter(valid_774411, JString, required = false,
                                 default = nil)
  if valid_774411 != nil:
    section.add "X-Amz-Algorithm", valid_774411
  var valid_774412 = header.getOrDefault("X-Amz-Signature")
  valid_774412 = validateParameter(valid_774412, JString, required = false,
                                 default = nil)
  if valid_774412 != nil:
    section.add "X-Amz-Signature", valid_774412
  var valid_774413 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774413 = validateParameter(valid_774413, JString, required = false,
                                 default = nil)
  if valid_774413 != nil:
    section.add "X-Amz-SignedHeaders", valid_774413
  var valid_774414 = header.getOrDefault("X-Amz-Credential")
  valid_774414 = validateParameter(valid_774414, JString, required = false,
                                 default = nil)
  if valid_774414 != nil:
    section.add "X-Amz-Credential", valid_774414
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774415: Call_GetRebuildEnvironment_774401; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes and recreates all of the AWS resources (for example: the Auto Scaling group, load balancer, etc.) for a specified environment and forces a restart.
  ## 
  let valid = call_774415.validator(path, query, header, formData, body)
  let scheme = call_774415.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774415.url(scheme.get, call_774415.host, call_774415.base,
                         call_774415.route, valid.getOrDefault("path"))
  result = hook(call_774415, url, valid)

proc call*(call_774416: Call_GetRebuildEnvironment_774401;
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
  var query_774417 = newJObject()
  add(query_774417, "EnvironmentName", newJString(EnvironmentName))
  add(query_774417, "Action", newJString(Action))
  add(query_774417, "EnvironmentId", newJString(EnvironmentId))
  add(query_774417, "Version", newJString(Version))
  result = call_774416.call(nil, query_774417, nil, nil, nil)

var getRebuildEnvironment* = Call_GetRebuildEnvironment_774401(
    name: "getRebuildEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RebuildEnvironment",
    validator: validate_GetRebuildEnvironment_774402, base: "/",
    url: url_GetRebuildEnvironment_774403, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRequestEnvironmentInfo_774454 = ref object of OpenApiRestCall_772598
proc url_PostRequestEnvironmentInfo_774456(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRequestEnvironmentInfo_774455(path: JsonNode; query: JsonNode;
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
  var valid_774457 = query.getOrDefault("Action")
  valid_774457 = validateParameter(valid_774457, JString, required = true,
                                 default = newJString("RequestEnvironmentInfo"))
  if valid_774457 != nil:
    section.add "Action", valid_774457
  var valid_774458 = query.getOrDefault("Version")
  valid_774458 = validateParameter(valid_774458, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_774458 != nil:
    section.add "Version", valid_774458
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774459 = header.getOrDefault("X-Amz-Date")
  valid_774459 = validateParameter(valid_774459, JString, required = false,
                                 default = nil)
  if valid_774459 != nil:
    section.add "X-Amz-Date", valid_774459
  var valid_774460 = header.getOrDefault("X-Amz-Security-Token")
  valid_774460 = validateParameter(valid_774460, JString, required = false,
                                 default = nil)
  if valid_774460 != nil:
    section.add "X-Amz-Security-Token", valid_774460
  var valid_774461 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774461 = validateParameter(valid_774461, JString, required = false,
                                 default = nil)
  if valid_774461 != nil:
    section.add "X-Amz-Content-Sha256", valid_774461
  var valid_774462 = header.getOrDefault("X-Amz-Algorithm")
  valid_774462 = validateParameter(valid_774462, JString, required = false,
                                 default = nil)
  if valid_774462 != nil:
    section.add "X-Amz-Algorithm", valid_774462
  var valid_774463 = header.getOrDefault("X-Amz-Signature")
  valid_774463 = validateParameter(valid_774463, JString, required = false,
                                 default = nil)
  if valid_774463 != nil:
    section.add "X-Amz-Signature", valid_774463
  var valid_774464 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774464 = validateParameter(valid_774464, JString, required = false,
                                 default = nil)
  if valid_774464 != nil:
    section.add "X-Amz-SignedHeaders", valid_774464
  var valid_774465 = header.getOrDefault("X-Amz-Credential")
  valid_774465 = validateParameter(valid_774465, JString, required = false,
                                 default = nil)
  if valid_774465 != nil:
    section.add "X-Amz-Credential", valid_774465
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
  var valid_774466 = formData.getOrDefault("InfoType")
  valid_774466 = validateParameter(valid_774466, JString, required = true,
                                 default = newJString("tail"))
  if valid_774466 != nil:
    section.add "InfoType", valid_774466
  var valid_774467 = formData.getOrDefault("EnvironmentId")
  valid_774467 = validateParameter(valid_774467, JString, required = false,
                                 default = nil)
  if valid_774467 != nil:
    section.add "EnvironmentId", valid_774467
  var valid_774468 = formData.getOrDefault("EnvironmentName")
  valid_774468 = validateParameter(valid_774468, JString, required = false,
                                 default = nil)
  if valid_774468 != nil:
    section.add "EnvironmentName", valid_774468
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774469: Call_PostRequestEnvironmentInfo_774454; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a request to compile the specified type of information of the deployed environment.</p> <p> Setting the <code>InfoType</code> to <code>tail</code> compiles the last lines from the application server log files of every Amazon EC2 instance in your environment. </p> <p> Setting the <code>InfoType</code> to <code>bundle</code> compresses the application server log files for every Amazon EC2 instance into a <code>.zip</code> file. Legacy and .NET containers do not support bundle logs. </p> <p> Use <a>RetrieveEnvironmentInfo</a> to obtain the set of logs. </p> <p>Related Topics</p> <ul> <li> <p> <a>RetrieveEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_774469.validator(path, query, header, formData, body)
  let scheme = call_774469.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774469.url(scheme.get, call_774469.host, call_774469.base,
                         call_774469.route, valid.getOrDefault("path"))
  result = hook(call_774469, url, valid)

proc call*(call_774470: Call_PostRequestEnvironmentInfo_774454;
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
  var query_774471 = newJObject()
  var formData_774472 = newJObject()
  add(formData_774472, "InfoType", newJString(InfoType))
  add(formData_774472, "EnvironmentId", newJString(EnvironmentId))
  add(formData_774472, "EnvironmentName", newJString(EnvironmentName))
  add(query_774471, "Action", newJString(Action))
  add(query_774471, "Version", newJString(Version))
  result = call_774470.call(nil, query_774471, nil, formData_774472, nil)

var postRequestEnvironmentInfo* = Call_PostRequestEnvironmentInfo_774454(
    name: "postRequestEnvironmentInfo", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RequestEnvironmentInfo",
    validator: validate_PostRequestEnvironmentInfo_774455, base: "/",
    url: url_PostRequestEnvironmentInfo_774456,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRequestEnvironmentInfo_774436 = ref object of OpenApiRestCall_772598
proc url_GetRequestEnvironmentInfo_774438(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRequestEnvironmentInfo_774437(path: JsonNode; query: JsonNode;
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
  var valid_774439 = query.getOrDefault("InfoType")
  valid_774439 = validateParameter(valid_774439, JString, required = true,
                                 default = newJString("tail"))
  if valid_774439 != nil:
    section.add "InfoType", valid_774439
  var valid_774440 = query.getOrDefault("EnvironmentName")
  valid_774440 = validateParameter(valid_774440, JString, required = false,
                                 default = nil)
  if valid_774440 != nil:
    section.add "EnvironmentName", valid_774440
  var valid_774441 = query.getOrDefault("Action")
  valid_774441 = validateParameter(valid_774441, JString, required = true,
                                 default = newJString("RequestEnvironmentInfo"))
  if valid_774441 != nil:
    section.add "Action", valid_774441
  var valid_774442 = query.getOrDefault("EnvironmentId")
  valid_774442 = validateParameter(valid_774442, JString, required = false,
                                 default = nil)
  if valid_774442 != nil:
    section.add "EnvironmentId", valid_774442
  var valid_774443 = query.getOrDefault("Version")
  valid_774443 = validateParameter(valid_774443, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_774443 != nil:
    section.add "Version", valid_774443
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774444 = header.getOrDefault("X-Amz-Date")
  valid_774444 = validateParameter(valid_774444, JString, required = false,
                                 default = nil)
  if valid_774444 != nil:
    section.add "X-Amz-Date", valid_774444
  var valid_774445 = header.getOrDefault("X-Amz-Security-Token")
  valid_774445 = validateParameter(valid_774445, JString, required = false,
                                 default = nil)
  if valid_774445 != nil:
    section.add "X-Amz-Security-Token", valid_774445
  var valid_774446 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774446 = validateParameter(valid_774446, JString, required = false,
                                 default = nil)
  if valid_774446 != nil:
    section.add "X-Amz-Content-Sha256", valid_774446
  var valid_774447 = header.getOrDefault("X-Amz-Algorithm")
  valid_774447 = validateParameter(valid_774447, JString, required = false,
                                 default = nil)
  if valid_774447 != nil:
    section.add "X-Amz-Algorithm", valid_774447
  var valid_774448 = header.getOrDefault("X-Amz-Signature")
  valid_774448 = validateParameter(valid_774448, JString, required = false,
                                 default = nil)
  if valid_774448 != nil:
    section.add "X-Amz-Signature", valid_774448
  var valid_774449 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774449 = validateParameter(valid_774449, JString, required = false,
                                 default = nil)
  if valid_774449 != nil:
    section.add "X-Amz-SignedHeaders", valid_774449
  var valid_774450 = header.getOrDefault("X-Amz-Credential")
  valid_774450 = validateParameter(valid_774450, JString, required = false,
                                 default = nil)
  if valid_774450 != nil:
    section.add "X-Amz-Credential", valid_774450
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774451: Call_GetRequestEnvironmentInfo_774436; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a request to compile the specified type of information of the deployed environment.</p> <p> Setting the <code>InfoType</code> to <code>tail</code> compiles the last lines from the application server log files of every Amazon EC2 instance in your environment. </p> <p> Setting the <code>InfoType</code> to <code>bundle</code> compresses the application server log files for every Amazon EC2 instance into a <code>.zip</code> file. Legacy and .NET containers do not support bundle logs. </p> <p> Use <a>RetrieveEnvironmentInfo</a> to obtain the set of logs. </p> <p>Related Topics</p> <ul> <li> <p> <a>RetrieveEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_774451.validator(path, query, header, formData, body)
  let scheme = call_774451.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774451.url(scheme.get, call_774451.host, call_774451.base,
                         call_774451.route, valid.getOrDefault("path"))
  result = hook(call_774451, url, valid)

proc call*(call_774452: Call_GetRequestEnvironmentInfo_774436;
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
  var query_774453 = newJObject()
  add(query_774453, "InfoType", newJString(InfoType))
  add(query_774453, "EnvironmentName", newJString(EnvironmentName))
  add(query_774453, "Action", newJString(Action))
  add(query_774453, "EnvironmentId", newJString(EnvironmentId))
  add(query_774453, "Version", newJString(Version))
  result = call_774452.call(nil, query_774453, nil, nil, nil)

var getRequestEnvironmentInfo* = Call_GetRequestEnvironmentInfo_774436(
    name: "getRequestEnvironmentInfo", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RequestEnvironmentInfo",
    validator: validate_GetRequestEnvironmentInfo_774437, base: "/",
    url: url_GetRequestEnvironmentInfo_774438,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestartAppServer_774490 = ref object of OpenApiRestCall_772598
proc url_PostRestartAppServer_774492(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRestartAppServer_774491(path: JsonNode; query: JsonNode;
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
  var valid_774493 = query.getOrDefault("Action")
  valid_774493 = validateParameter(valid_774493, JString, required = true,
                                 default = newJString("RestartAppServer"))
  if valid_774493 != nil:
    section.add "Action", valid_774493
  var valid_774494 = query.getOrDefault("Version")
  valid_774494 = validateParameter(valid_774494, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_774494 != nil:
    section.add "Version", valid_774494
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774495 = header.getOrDefault("X-Amz-Date")
  valid_774495 = validateParameter(valid_774495, JString, required = false,
                                 default = nil)
  if valid_774495 != nil:
    section.add "X-Amz-Date", valid_774495
  var valid_774496 = header.getOrDefault("X-Amz-Security-Token")
  valid_774496 = validateParameter(valid_774496, JString, required = false,
                                 default = nil)
  if valid_774496 != nil:
    section.add "X-Amz-Security-Token", valid_774496
  var valid_774497 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774497 = validateParameter(valid_774497, JString, required = false,
                                 default = nil)
  if valid_774497 != nil:
    section.add "X-Amz-Content-Sha256", valid_774497
  var valid_774498 = header.getOrDefault("X-Amz-Algorithm")
  valid_774498 = validateParameter(valid_774498, JString, required = false,
                                 default = nil)
  if valid_774498 != nil:
    section.add "X-Amz-Algorithm", valid_774498
  var valid_774499 = header.getOrDefault("X-Amz-Signature")
  valid_774499 = validateParameter(valid_774499, JString, required = false,
                                 default = nil)
  if valid_774499 != nil:
    section.add "X-Amz-Signature", valid_774499
  var valid_774500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774500 = validateParameter(valid_774500, JString, required = false,
                                 default = nil)
  if valid_774500 != nil:
    section.add "X-Amz-SignedHeaders", valid_774500
  var valid_774501 = header.getOrDefault("X-Amz-Credential")
  valid_774501 = validateParameter(valid_774501, JString, required = false,
                                 default = nil)
  if valid_774501 != nil:
    section.add "X-Amz-Credential", valid_774501
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to restart the server for.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to restart the server for.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_774502 = formData.getOrDefault("EnvironmentId")
  valid_774502 = validateParameter(valid_774502, JString, required = false,
                                 default = nil)
  if valid_774502 != nil:
    section.add "EnvironmentId", valid_774502
  var valid_774503 = formData.getOrDefault("EnvironmentName")
  valid_774503 = validateParameter(valid_774503, JString, required = false,
                                 default = nil)
  if valid_774503 != nil:
    section.add "EnvironmentName", valid_774503
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774504: Call_PostRestartAppServer_774490; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Causes the environment to restart the application container server running on each Amazon EC2 instance.
  ## 
  let valid = call_774504.validator(path, query, header, formData, body)
  let scheme = call_774504.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774504.url(scheme.get, call_774504.host, call_774504.base,
                         call_774504.route, valid.getOrDefault("path"))
  result = hook(call_774504, url, valid)

proc call*(call_774505: Call_PostRestartAppServer_774490;
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
  var query_774506 = newJObject()
  var formData_774507 = newJObject()
  add(formData_774507, "EnvironmentId", newJString(EnvironmentId))
  add(formData_774507, "EnvironmentName", newJString(EnvironmentName))
  add(query_774506, "Action", newJString(Action))
  add(query_774506, "Version", newJString(Version))
  result = call_774505.call(nil, query_774506, nil, formData_774507, nil)

var postRestartAppServer* = Call_PostRestartAppServer_774490(
    name: "postRestartAppServer", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RestartAppServer",
    validator: validate_PostRestartAppServer_774491, base: "/",
    url: url_PostRestartAppServer_774492, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestartAppServer_774473 = ref object of OpenApiRestCall_772598
proc url_GetRestartAppServer_774475(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRestartAppServer_774474(path: JsonNode; query: JsonNode;
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
  var valid_774476 = query.getOrDefault("EnvironmentName")
  valid_774476 = validateParameter(valid_774476, JString, required = false,
                                 default = nil)
  if valid_774476 != nil:
    section.add "EnvironmentName", valid_774476
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774477 = query.getOrDefault("Action")
  valid_774477 = validateParameter(valid_774477, JString, required = true,
                                 default = newJString("RestartAppServer"))
  if valid_774477 != nil:
    section.add "Action", valid_774477
  var valid_774478 = query.getOrDefault("EnvironmentId")
  valid_774478 = validateParameter(valid_774478, JString, required = false,
                                 default = nil)
  if valid_774478 != nil:
    section.add "EnvironmentId", valid_774478
  var valid_774479 = query.getOrDefault("Version")
  valid_774479 = validateParameter(valid_774479, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_774479 != nil:
    section.add "Version", valid_774479
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774480 = header.getOrDefault("X-Amz-Date")
  valid_774480 = validateParameter(valid_774480, JString, required = false,
                                 default = nil)
  if valid_774480 != nil:
    section.add "X-Amz-Date", valid_774480
  var valid_774481 = header.getOrDefault("X-Amz-Security-Token")
  valid_774481 = validateParameter(valid_774481, JString, required = false,
                                 default = nil)
  if valid_774481 != nil:
    section.add "X-Amz-Security-Token", valid_774481
  var valid_774482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774482 = validateParameter(valid_774482, JString, required = false,
                                 default = nil)
  if valid_774482 != nil:
    section.add "X-Amz-Content-Sha256", valid_774482
  var valid_774483 = header.getOrDefault("X-Amz-Algorithm")
  valid_774483 = validateParameter(valid_774483, JString, required = false,
                                 default = nil)
  if valid_774483 != nil:
    section.add "X-Amz-Algorithm", valid_774483
  var valid_774484 = header.getOrDefault("X-Amz-Signature")
  valid_774484 = validateParameter(valid_774484, JString, required = false,
                                 default = nil)
  if valid_774484 != nil:
    section.add "X-Amz-Signature", valid_774484
  var valid_774485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774485 = validateParameter(valid_774485, JString, required = false,
                                 default = nil)
  if valid_774485 != nil:
    section.add "X-Amz-SignedHeaders", valid_774485
  var valid_774486 = header.getOrDefault("X-Amz-Credential")
  valid_774486 = validateParameter(valid_774486, JString, required = false,
                                 default = nil)
  if valid_774486 != nil:
    section.add "X-Amz-Credential", valid_774486
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774487: Call_GetRestartAppServer_774473; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Causes the environment to restart the application container server running on each Amazon EC2 instance.
  ## 
  let valid = call_774487.validator(path, query, header, formData, body)
  let scheme = call_774487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774487.url(scheme.get, call_774487.host, call_774487.base,
                         call_774487.route, valid.getOrDefault("path"))
  result = hook(call_774487, url, valid)

proc call*(call_774488: Call_GetRestartAppServer_774473;
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
  var query_774489 = newJObject()
  add(query_774489, "EnvironmentName", newJString(EnvironmentName))
  add(query_774489, "Action", newJString(Action))
  add(query_774489, "EnvironmentId", newJString(EnvironmentId))
  add(query_774489, "Version", newJString(Version))
  result = call_774488.call(nil, query_774489, nil, nil, nil)

var getRestartAppServer* = Call_GetRestartAppServer_774473(
    name: "getRestartAppServer", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RestartAppServer",
    validator: validate_GetRestartAppServer_774474, base: "/",
    url: url_GetRestartAppServer_774475, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRetrieveEnvironmentInfo_774526 = ref object of OpenApiRestCall_772598
proc url_PostRetrieveEnvironmentInfo_774528(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRetrieveEnvironmentInfo_774527(path: JsonNode; query: JsonNode;
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
  var valid_774529 = query.getOrDefault("Action")
  valid_774529 = validateParameter(valid_774529, JString, required = true, default = newJString(
      "RetrieveEnvironmentInfo"))
  if valid_774529 != nil:
    section.add "Action", valid_774529
  var valid_774530 = query.getOrDefault("Version")
  valid_774530 = validateParameter(valid_774530, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_774530 != nil:
    section.add "Version", valid_774530
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774531 = header.getOrDefault("X-Amz-Date")
  valid_774531 = validateParameter(valid_774531, JString, required = false,
                                 default = nil)
  if valid_774531 != nil:
    section.add "X-Amz-Date", valid_774531
  var valid_774532 = header.getOrDefault("X-Amz-Security-Token")
  valid_774532 = validateParameter(valid_774532, JString, required = false,
                                 default = nil)
  if valid_774532 != nil:
    section.add "X-Amz-Security-Token", valid_774532
  var valid_774533 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774533 = validateParameter(valid_774533, JString, required = false,
                                 default = nil)
  if valid_774533 != nil:
    section.add "X-Amz-Content-Sha256", valid_774533
  var valid_774534 = header.getOrDefault("X-Amz-Algorithm")
  valid_774534 = validateParameter(valid_774534, JString, required = false,
                                 default = nil)
  if valid_774534 != nil:
    section.add "X-Amz-Algorithm", valid_774534
  var valid_774535 = header.getOrDefault("X-Amz-Signature")
  valid_774535 = validateParameter(valid_774535, JString, required = false,
                                 default = nil)
  if valid_774535 != nil:
    section.add "X-Amz-Signature", valid_774535
  var valid_774536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774536 = validateParameter(valid_774536, JString, required = false,
                                 default = nil)
  if valid_774536 != nil:
    section.add "X-Amz-SignedHeaders", valid_774536
  var valid_774537 = header.getOrDefault("X-Amz-Credential")
  valid_774537 = validateParameter(valid_774537, JString, required = false,
                                 default = nil)
  if valid_774537 != nil:
    section.add "X-Amz-Credential", valid_774537
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
  var valid_774538 = formData.getOrDefault("InfoType")
  valid_774538 = validateParameter(valid_774538, JString, required = true,
                                 default = newJString("tail"))
  if valid_774538 != nil:
    section.add "InfoType", valid_774538
  var valid_774539 = formData.getOrDefault("EnvironmentId")
  valid_774539 = validateParameter(valid_774539, JString, required = false,
                                 default = nil)
  if valid_774539 != nil:
    section.add "EnvironmentId", valid_774539
  var valid_774540 = formData.getOrDefault("EnvironmentName")
  valid_774540 = validateParameter(valid_774540, JString, required = false,
                                 default = nil)
  if valid_774540 != nil:
    section.add "EnvironmentName", valid_774540
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774541: Call_PostRetrieveEnvironmentInfo_774526; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the compiled information from a <a>RequestEnvironmentInfo</a> request.</p> <p>Related Topics</p> <ul> <li> <p> <a>RequestEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_774541.validator(path, query, header, formData, body)
  let scheme = call_774541.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774541.url(scheme.get, call_774541.host, call_774541.base,
                         call_774541.route, valid.getOrDefault("path"))
  result = hook(call_774541, url, valid)

proc call*(call_774542: Call_PostRetrieveEnvironmentInfo_774526;
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
  var query_774543 = newJObject()
  var formData_774544 = newJObject()
  add(formData_774544, "InfoType", newJString(InfoType))
  add(formData_774544, "EnvironmentId", newJString(EnvironmentId))
  add(formData_774544, "EnvironmentName", newJString(EnvironmentName))
  add(query_774543, "Action", newJString(Action))
  add(query_774543, "Version", newJString(Version))
  result = call_774542.call(nil, query_774543, nil, formData_774544, nil)

var postRetrieveEnvironmentInfo* = Call_PostRetrieveEnvironmentInfo_774526(
    name: "postRetrieveEnvironmentInfo", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RetrieveEnvironmentInfo",
    validator: validate_PostRetrieveEnvironmentInfo_774527, base: "/",
    url: url_PostRetrieveEnvironmentInfo_774528,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRetrieveEnvironmentInfo_774508 = ref object of OpenApiRestCall_772598
proc url_GetRetrieveEnvironmentInfo_774510(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRetrieveEnvironmentInfo_774509(path: JsonNode; query: JsonNode;
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
  var valid_774511 = query.getOrDefault("InfoType")
  valid_774511 = validateParameter(valid_774511, JString, required = true,
                                 default = newJString("tail"))
  if valid_774511 != nil:
    section.add "InfoType", valid_774511
  var valid_774512 = query.getOrDefault("EnvironmentName")
  valid_774512 = validateParameter(valid_774512, JString, required = false,
                                 default = nil)
  if valid_774512 != nil:
    section.add "EnvironmentName", valid_774512
  var valid_774513 = query.getOrDefault("Action")
  valid_774513 = validateParameter(valid_774513, JString, required = true, default = newJString(
      "RetrieveEnvironmentInfo"))
  if valid_774513 != nil:
    section.add "Action", valid_774513
  var valid_774514 = query.getOrDefault("EnvironmentId")
  valid_774514 = validateParameter(valid_774514, JString, required = false,
                                 default = nil)
  if valid_774514 != nil:
    section.add "EnvironmentId", valid_774514
  var valid_774515 = query.getOrDefault("Version")
  valid_774515 = validateParameter(valid_774515, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_774515 != nil:
    section.add "Version", valid_774515
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774516 = header.getOrDefault("X-Amz-Date")
  valid_774516 = validateParameter(valid_774516, JString, required = false,
                                 default = nil)
  if valid_774516 != nil:
    section.add "X-Amz-Date", valid_774516
  var valid_774517 = header.getOrDefault("X-Amz-Security-Token")
  valid_774517 = validateParameter(valid_774517, JString, required = false,
                                 default = nil)
  if valid_774517 != nil:
    section.add "X-Amz-Security-Token", valid_774517
  var valid_774518 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774518 = validateParameter(valid_774518, JString, required = false,
                                 default = nil)
  if valid_774518 != nil:
    section.add "X-Amz-Content-Sha256", valid_774518
  var valid_774519 = header.getOrDefault("X-Amz-Algorithm")
  valid_774519 = validateParameter(valid_774519, JString, required = false,
                                 default = nil)
  if valid_774519 != nil:
    section.add "X-Amz-Algorithm", valid_774519
  var valid_774520 = header.getOrDefault("X-Amz-Signature")
  valid_774520 = validateParameter(valid_774520, JString, required = false,
                                 default = nil)
  if valid_774520 != nil:
    section.add "X-Amz-Signature", valid_774520
  var valid_774521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774521 = validateParameter(valid_774521, JString, required = false,
                                 default = nil)
  if valid_774521 != nil:
    section.add "X-Amz-SignedHeaders", valid_774521
  var valid_774522 = header.getOrDefault("X-Amz-Credential")
  valid_774522 = validateParameter(valid_774522, JString, required = false,
                                 default = nil)
  if valid_774522 != nil:
    section.add "X-Amz-Credential", valid_774522
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774523: Call_GetRetrieveEnvironmentInfo_774508; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the compiled information from a <a>RequestEnvironmentInfo</a> request.</p> <p>Related Topics</p> <ul> <li> <p> <a>RequestEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_774523.validator(path, query, header, formData, body)
  let scheme = call_774523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774523.url(scheme.get, call_774523.host, call_774523.base,
                         call_774523.route, valid.getOrDefault("path"))
  result = hook(call_774523, url, valid)

proc call*(call_774524: Call_GetRetrieveEnvironmentInfo_774508;
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
  var query_774525 = newJObject()
  add(query_774525, "InfoType", newJString(InfoType))
  add(query_774525, "EnvironmentName", newJString(EnvironmentName))
  add(query_774525, "Action", newJString(Action))
  add(query_774525, "EnvironmentId", newJString(EnvironmentId))
  add(query_774525, "Version", newJString(Version))
  result = call_774524.call(nil, query_774525, nil, nil, nil)

var getRetrieveEnvironmentInfo* = Call_GetRetrieveEnvironmentInfo_774508(
    name: "getRetrieveEnvironmentInfo", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RetrieveEnvironmentInfo",
    validator: validate_GetRetrieveEnvironmentInfo_774509, base: "/",
    url: url_GetRetrieveEnvironmentInfo_774510,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSwapEnvironmentCNAMEs_774564 = ref object of OpenApiRestCall_772598
proc url_PostSwapEnvironmentCNAMEs_774566(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostSwapEnvironmentCNAMEs_774565(path: JsonNode; query: JsonNode;
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
  var valid_774567 = query.getOrDefault("Action")
  valid_774567 = validateParameter(valid_774567, JString, required = true,
                                 default = newJString("SwapEnvironmentCNAMEs"))
  if valid_774567 != nil:
    section.add "Action", valid_774567
  var valid_774568 = query.getOrDefault("Version")
  valid_774568 = validateParameter(valid_774568, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_774568 != nil:
    section.add "Version", valid_774568
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774569 = header.getOrDefault("X-Amz-Date")
  valid_774569 = validateParameter(valid_774569, JString, required = false,
                                 default = nil)
  if valid_774569 != nil:
    section.add "X-Amz-Date", valid_774569
  var valid_774570 = header.getOrDefault("X-Amz-Security-Token")
  valid_774570 = validateParameter(valid_774570, JString, required = false,
                                 default = nil)
  if valid_774570 != nil:
    section.add "X-Amz-Security-Token", valid_774570
  var valid_774571 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774571 = validateParameter(valid_774571, JString, required = false,
                                 default = nil)
  if valid_774571 != nil:
    section.add "X-Amz-Content-Sha256", valid_774571
  var valid_774572 = header.getOrDefault("X-Amz-Algorithm")
  valid_774572 = validateParameter(valid_774572, JString, required = false,
                                 default = nil)
  if valid_774572 != nil:
    section.add "X-Amz-Algorithm", valid_774572
  var valid_774573 = header.getOrDefault("X-Amz-Signature")
  valid_774573 = validateParameter(valid_774573, JString, required = false,
                                 default = nil)
  if valid_774573 != nil:
    section.add "X-Amz-Signature", valid_774573
  var valid_774574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774574 = validateParameter(valid_774574, JString, required = false,
                                 default = nil)
  if valid_774574 != nil:
    section.add "X-Amz-SignedHeaders", valid_774574
  var valid_774575 = header.getOrDefault("X-Amz-Credential")
  valid_774575 = validateParameter(valid_774575, JString, required = false,
                                 default = nil)
  if valid_774575 != nil:
    section.add "X-Amz-Credential", valid_774575
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
  var valid_774576 = formData.getOrDefault("SourceEnvironmentName")
  valid_774576 = validateParameter(valid_774576, JString, required = false,
                                 default = nil)
  if valid_774576 != nil:
    section.add "SourceEnvironmentName", valid_774576
  var valid_774577 = formData.getOrDefault("SourceEnvironmentId")
  valid_774577 = validateParameter(valid_774577, JString, required = false,
                                 default = nil)
  if valid_774577 != nil:
    section.add "SourceEnvironmentId", valid_774577
  var valid_774578 = formData.getOrDefault("DestinationEnvironmentId")
  valid_774578 = validateParameter(valid_774578, JString, required = false,
                                 default = nil)
  if valid_774578 != nil:
    section.add "DestinationEnvironmentId", valid_774578
  var valid_774579 = formData.getOrDefault("DestinationEnvironmentName")
  valid_774579 = validateParameter(valid_774579, JString, required = false,
                                 default = nil)
  if valid_774579 != nil:
    section.add "DestinationEnvironmentName", valid_774579
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774580: Call_PostSwapEnvironmentCNAMEs_774564; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Swaps the CNAMEs of two environments.
  ## 
  let valid = call_774580.validator(path, query, header, formData, body)
  let scheme = call_774580.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774580.url(scheme.get, call_774580.host, call_774580.base,
                         call_774580.route, valid.getOrDefault("path"))
  result = hook(call_774580, url, valid)

proc call*(call_774581: Call_PostSwapEnvironmentCNAMEs_774564;
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
  var query_774582 = newJObject()
  var formData_774583 = newJObject()
  add(formData_774583, "SourceEnvironmentName", newJString(SourceEnvironmentName))
  add(formData_774583, "SourceEnvironmentId", newJString(SourceEnvironmentId))
  add(formData_774583, "DestinationEnvironmentId",
      newJString(DestinationEnvironmentId))
  add(formData_774583, "DestinationEnvironmentName",
      newJString(DestinationEnvironmentName))
  add(query_774582, "Action", newJString(Action))
  add(query_774582, "Version", newJString(Version))
  result = call_774581.call(nil, query_774582, nil, formData_774583, nil)

var postSwapEnvironmentCNAMEs* = Call_PostSwapEnvironmentCNAMEs_774564(
    name: "postSwapEnvironmentCNAMEs", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=SwapEnvironmentCNAMEs",
    validator: validate_PostSwapEnvironmentCNAMEs_774565, base: "/",
    url: url_PostSwapEnvironmentCNAMEs_774566,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSwapEnvironmentCNAMEs_774545 = ref object of OpenApiRestCall_772598
proc url_GetSwapEnvironmentCNAMEs_774547(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetSwapEnvironmentCNAMEs_774546(path: JsonNode; query: JsonNode;
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
  var valid_774548 = query.getOrDefault("SourceEnvironmentId")
  valid_774548 = validateParameter(valid_774548, JString, required = false,
                                 default = nil)
  if valid_774548 != nil:
    section.add "SourceEnvironmentId", valid_774548
  var valid_774549 = query.getOrDefault("DestinationEnvironmentName")
  valid_774549 = validateParameter(valid_774549, JString, required = false,
                                 default = nil)
  if valid_774549 != nil:
    section.add "DestinationEnvironmentName", valid_774549
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774550 = query.getOrDefault("Action")
  valid_774550 = validateParameter(valid_774550, JString, required = true,
                                 default = newJString("SwapEnvironmentCNAMEs"))
  if valid_774550 != nil:
    section.add "Action", valid_774550
  var valid_774551 = query.getOrDefault("SourceEnvironmentName")
  valid_774551 = validateParameter(valid_774551, JString, required = false,
                                 default = nil)
  if valid_774551 != nil:
    section.add "SourceEnvironmentName", valid_774551
  var valid_774552 = query.getOrDefault("DestinationEnvironmentId")
  valid_774552 = validateParameter(valid_774552, JString, required = false,
                                 default = nil)
  if valid_774552 != nil:
    section.add "DestinationEnvironmentId", valid_774552
  var valid_774553 = query.getOrDefault("Version")
  valid_774553 = validateParameter(valid_774553, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_774553 != nil:
    section.add "Version", valid_774553
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774554 = header.getOrDefault("X-Amz-Date")
  valid_774554 = validateParameter(valid_774554, JString, required = false,
                                 default = nil)
  if valid_774554 != nil:
    section.add "X-Amz-Date", valid_774554
  var valid_774555 = header.getOrDefault("X-Amz-Security-Token")
  valid_774555 = validateParameter(valid_774555, JString, required = false,
                                 default = nil)
  if valid_774555 != nil:
    section.add "X-Amz-Security-Token", valid_774555
  var valid_774556 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774556 = validateParameter(valid_774556, JString, required = false,
                                 default = nil)
  if valid_774556 != nil:
    section.add "X-Amz-Content-Sha256", valid_774556
  var valid_774557 = header.getOrDefault("X-Amz-Algorithm")
  valid_774557 = validateParameter(valid_774557, JString, required = false,
                                 default = nil)
  if valid_774557 != nil:
    section.add "X-Amz-Algorithm", valid_774557
  var valid_774558 = header.getOrDefault("X-Amz-Signature")
  valid_774558 = validateParameter(valid_774558, JString, required = false,
                                 default = nil)
  if valid_774558 != nil:
    section.add "X-Amz-Signature", valid_774558
  var valid_774559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774559 = validateParameter(valid_774559, JString, required = false,
                                 default = nil)
  if valid_774559 != nil:
    section.add "X-Amz-SignedHeaders", valid_774559
  var valid_774560 = header.getOrDefault("X-Amz-Credential")
  valid_774560 = validateParameter(valid_774560, JString, required = false,
                                 default = nil)
  if valid_774560 != nil:
    section.add "X-Amz-Credential", valid_774560
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774561: Call_GetSwapEnvironmentCNAMEs_774545; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Swaps the CNAMEs of two environments.
  ## 
  let valid = call_774561.validator(path, query, header, formData, body)
  let scheme = call_774561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774561.url(scheme.get, call_774561.host, call_774561.base,
                         call_774561.route, valid.getOrDefault("path"))
  result = hook(call_774561, url, valid)

proc call*(call_774562: Call_GetSwapEnvironmentCNAMEs_774545;
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
  var query_774563 = newJObject()
  add(query_774563, "SourceEnvironmentId", newJString(SourceEnvironmentId))
  add(query_774563, "DestinationEnvironmentName",
      newJString(DestinationEnvironmentName))
  add(query_774563, "Action", newJString(Action))
  add(query_774563, "SourceEnvironmentName", newJString(SourceEnvironmentName))
  add(query_774563, "DestinationEnvironmentId",
      newJString(DestinationEnvironmentId))
  add(query_774563, "Version", newJString(Version))
  result = call_774562.call(nil, query_774563, nil, nil, nil)

var getSwapEnvironmentCNAMEs* = Call_GetSwapEnvironmentCNAMEs_774545(
    name: "getSwapEnvironmentCNAMEs", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=SwapEnvironmentCNAMEs",
    validator: validate_GetSwapEnvironmentCNAMEs_774546, base: "/",
    url: url_GetSwapEnvironmentCNAMEs_774547, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostTerminateEnvironment_774603 = ref object of OpenApiRestCall_772598
proc url_PostTerminateEnvironment_774605(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostTerminateEnvironment_774604(path: JsonNode; query: JsonNode;
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
  var valid_774606 = query.getOrDefault("Action")
  valid_774606 = validateParameter(valid_774606, JString, required = true,
                                 default = newJString("TerminateEnvironment"))
  if valid_774606 != nil:
    section.add "Action", valid_774606
  var valid_774607 = query.getOrDefault("Version")
  valid_774607 = validateParameter(valid_774607, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_774607 != nil:
    section.add "Version", valid_774607
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774608 = header.getOrDefault("X-Amz-Date")
  valid_774608 = validateParameter(valid_774608, JString, required = false,
                                 default = nil)
  if valid_774608 != nil:
    section.add "X-Amz-Date", valid_774608
  var valid_774609 = header.getOrDefault("X-Amz-Security-Token")
  valid_774609 = validateParameter(valid_774609, JString, required = false,
                                 default = nil)
  if valid_774609 != nil:
    section.add "X-Amz-Security-Token", valid_774609
  var valid_774610 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774610 = validateParameter(valid_774610, JString, required = false,
                                 default = nil)
  if valid_774610 != nil:
    section.add "X-Amz-Content-Sha256", valid_774610
  var valid_774611 = header.getOrDefault("X-Amz-Algorithm")
  valid_774611 = validateParameter(valid_774611, JString, required = false,
                                 default = nil)
  if valid_774611 != nil:
    section.add "X-Amz-Algorithm", valid_774611
  var valid_774612 = header.getOrDefault("X-Amz-Signature")
  valid_774612 = validateParameter(valid_774612, JString, required = false,
                                 default = nil)
  if valid_774612 != nil:
    section.add "X-Amz-Signature", valid_774612
  var valid_774613 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774613 = validateParameter(valid_774613, JString, required = false,
                                 default = nil)
  if valid_774613 != nil:
    section.add "X-Amz-SignedHeaders", valid_774613
  var valid_774614 = header.getOrDefault("X-Amz-Credential")
  valid_774614 = validateParameter(valid_774614, JString, required = false,
                                 default = nil)
  if valid_774614 != nil:
    section.add "X-Amz-Credential", valid_774614
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
  var valid_774615 = formData.getOrDefault("ForceTerminate")
  valid_774615 = validateParameter(valid_774615, JBool, required = false, default = nil)
  if valid_774615 != nil:
    section.add "ForceTerminate", valid_774615
  var valid_774616 = formData.getOrDefault("TerminateResources")
  valid_774616 = validateParameter(valid_774616, JBool, required = false, default = nil)
  if valid_774616 != nil:
    section.add "TerminateResources", valid_774616
  var valid_774617 = formData.getOrDefault("EnvironmentId")
  valid_774617 = validateParameter(valid_774617, JString, required = false,
                                 default = nil)
  if valid_774617 != nil:
    section.add "EnvironmentId", valid_774617
  var valid_774618 = formData.getOrDefault("EnvironmentName")
  valid_774618 = validateParameter(valid_774618, JString, required = false,
                                 default = nil)
  if valid_774618 != nil:
    section.add "EnvironmentName", valid_774618
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774619: Call_PostTerminateEnvironment_774603; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Terminates the specified environment.
  ## 
  let valid = call_774619.validator(path, query, header, formData, body)
  let scheme = call_774619.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774619.url(scheme.get, call_774619.host, call_774619.base,
                         call_774619.route, valid.getOrDefault("path"))
  result = hook(call_774619, url, valid)

proc call*(call_774620: Call_PostTerminateEnvironment_774603;
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
  var query_774621 = newJObject()
  var formData_774622 = newJObject()
  add(formData_774622, "ForceTerminate", newJBool(ForceTerminate))
  add(formData_774622, "TerminateResources", newJBool(TerminateResources))
  add(formData_774622, "EnvironmentId", newJString(EnvironmentId))
  add(formData_774622, "EnvironmentName", newJString(EnvironmentName))
  add(query_774621, "Action", newJString(Action))
  add(query_774621, "Version", newJString(Version))
  result = call_774620.call(nil, query_774621, nil, formData_774622, nil)

var postTerminateEnvironment* = Call_PostTerminateEnvironment_774603(
    name: "postTerminateEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=TerminateEnvironment",
    validator: validate_PostTerminateEnvironment_774604, base: "/",
    url: url_PostTerminateEnvironment_774605, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTerminateEnvironment_774584 = ref object of OpenApiRestCall_772598
proc url_GetTerminateEnvironment_774586(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetTerminateEnvironment_774585(path: JsonNode; query: JsonNode;
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
  var valid_774587 = query.getOrDefault("EnvironmentName")
  valid_774587 = validateParameter(valid_774587, JString, required = false,
                                 default = nil)
  if valid_774587 != nil:
    section.add "EnvironmentName", valid_774587
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774588 = query.getOrDefault("Action")
  valid_774588 = validateParameter(valid_774588, JString, required = true,
                                 default = newJString("TerminateEnvironment"))
  if valid_774588 != nil:
    section.add "Action", valid_774588
  var valid_774589 = query.getOrDefault("EnvironmentId")
  valid_774589 = validateParameter(valid_774589, JString, required = false,
                                 default = nil)
  if valid_774589 != nil:
    section.add "EnvironmentId", valid_774589
  var valid_774590 = query.getOrDefault("ForceTerminate")
  valid_774590 = validateParameter(valid_774590, JBool, required = false, default = nil)
  if valid_774590 != nil:
    section.add "ForceTerminate", valid_774590
  var valid_774591 = query.getOrDefault("TerminateResources")
  valid_774591 = validateParameter(valid_774591, JBool, required = false, default = nil)
  if valid_774591 != nil:
    section.add "TerminateResources", valid_774591
  var valid_774592 = query.getOrDefault("Version")
  valid_774592 = validateParameter(valid_774592, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_774592 != nil:
    section.add "Version", valid_774592
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774593 = header.getOrDefault("X-Amz-Date")
  valid_774593 = validateParameter(valid_774593, JString, required = false,
                                 default = nil)
  if valid_774593 != nil:
    section.add "X-Amz-Date", valid_774593
  var valid_774594 = header.getOrDefault("X-Amz-Security-Token")
  valid_774594 = validateParameter(valid_774594, JString, required = false,
                                 default = nil)
  if valid_774594 != nil:
    section.add "X-Amz-Security-Token", valid_774594
  var valid_774595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774595 = validateParameter(valid_774595, JString, required = false,
                                 default = nil)
  if valid_774595 != nil:
    section.add "X-Amz-Content-Sha256", valid_774595
  var valid_774596 = header.getOrDefault("X-Amz-Algorithm")
  valid_774596 = validateParameter(valid_774596, JString, required = false,
                                 default = nil)
  if valid_774596 != nil:
    section.add "X-Amz-Algorithm", valid_774596
  var valid_774597 = header.getOrDefault("X-Amz-Signature")
  valid_774597 = validateParameter(valid_774597, JString, required = false,
                                 default = nil)
  if valid_774597 != nil:
    section.add "X-Amz-Signature", valid_774597
  var valid_774598 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774598 = validateParameter(valid_774598, JString, required = false,
                                 default = nil)
  if valid_774598 != nil:
    section.add "X-Amz-SignedHeaders", valid_774598
  var valid_774599 = header.getOrDefault("X-Amz-Credential")
  valid_774599 = validateParameter(valid_774599, JString, required = false,
                                 default = nil)
  if valid_774599 != nil:
    section.add "X-Amz-Credential", valid_774599
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774600: Call_GetTerminateEnvironment_774584; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Terminates the specified environment.
  ## 
  let valid = call_774600.validator(path, query, header, formData, body)
  let scheme = call_774600.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774600.url(scheme.get, call_774600.host, call_774600.base,
                         call_774600.route, valid.getOrDefault("path"))
  result = hook(call_774600, url, valid)

proc call*(call_774601: Call_GetTerminateEnvironment_774584;
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
  var query_774602 = newJObject()
  add(query_774602, "EnvironmentName", newJString(EnvironmentName))
  add(query_774602, "Action", newJString(Action))
  add(query_774602, "EnvironmentId", newJString(EnvironmentId))
  add(query_774602, "ForceTerminate", newJBool(ForceTerminate))
  add(query_774602, "TerminateResources", newJBool(TerminateResources))
  add(query_774602, "Version", newJString(Version))
  result = call_774601.call(nil, query_774602, nil, nil, nil)

var getTerminateEnvironment* = Call_GetTerminateEnvironment_774584(
    name: "getTerminateEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=TerminateEnvironment",
    validator: validate_GetTerminateEnvironment_774585, base: "/",
    url: url_GetTerminateEnvironment_774586, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateApplication_774640 = ref object of OpenApiRestCall_772598
proc url_PostUpdateApplication_774642(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostUpdateApplication_774641(path: JsonNode; query: JsonNode;
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
  var valid_774643 = query.getOrDefault("Action")
  valid_774643 = validateParameter(valid_774643, JString, required = true,
                                 default = newJString("UpdateApplication"))
  if valid_774643 != nil:
    section.add "Action", valid_774643
  var valid_774644 = query.getOrDefault("Version")
  valid_774644 = validateParameter(valid_774644, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_774644 != nil:
    section.add "Version", valid_774644
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774645 = header.getOrDefault("X-Amz-Date")
  valid_774645 = validateParameter(valid_774645, JString, required = false,
                                 default = nil)
  if valid_774645 != nil:
    section.add "X-Amz-Date", valid_774645
  var valid_774646 = header.getOrDefault("X-Amz-Security-Token")
  valid_774646 = validateParameter(valid_774646, JString, required = false,
                                 default = nil)
  if valid_774646 != nil:
    section.add "X-Amz-Security-Token", valid_774646
  var valid_774647 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774647 = validateParameter(valid_774647, JString, required = false,
                                 default = nil)
  if valid_774647 != nil:
    section.add "X-Amz-Content-Sha256", valid_774647
  var valid_774648 = header.getOrDefault("X-Amz-Algorithm")
  valid_774648 = validateParameter(valid_774648, JString, required = false,
                                 default = nil)
  if valid_774648 != nil:
    section.add "X-Amz-Algorithm", valid_774648
  var valid_774649 = header.getOrDefault("X-Amz-Signature")
  valid_774649 = validateParameter(valid_774649, JString, required = false,
                                 default = nil)
  if valid_774649 != nil:
    section.add "X-Amz-Signature", valid_774649
  var valid_774650 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774650 = validateParameter(valid_774650, JString, required = false,
                                 default = nil)
  if valid_774650 != nil:
    section.add "X-Amz-SignedHeaders", valid_774650
  var valid_774651 = header.getOrDefault("X-Amz-Credential")
  valid_774651 = validateParameter(valid_774651, JString, required = false,
                                 default = nil)
  if valid_774651 != nil:
    section.add "X-Amz-Credential", valid_774651
  result.add "header", section
  ## parameters in `formData` object:
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to update. If no such application is found, <code>UpdateApplication</code> returns an <code>InvalidParameterValue</code> error. 
  ##   Description: JString
  ##              : <p>A new description for the application.</p> <p>Default: If not specified, AWS Elastic Beanstalk does not update the description.</p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_774652 = formData.getOrDefault("ApplicationName")
  valid_774652 = validateParameter(valid_774652, JString, required = true,
                                 default = nil)
  if valid_774652 != nil:
    section.add "ApplicationName", valid_774652
  var valid_774653 = formData.getOrDefault("Description")
  valid_774653 = validateParameter(valid_774653, JString, required = false,
                                 default = nil)
  if valid_774653 != nil:
    section.add "Description", valid_774653
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774654: Call_PostUpdateApplication_774640; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified application to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear these properties, specify an empty string.</p> </note>
  ## 
  let valid = call_774654.validator(path, query, header, formData, body)
  let scheme = call_774654.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774654.url(scheme.get, call_774654.host, call_774654.base,
                         call_774654.route, valid.getOrDefault("path"))
  result = hook(call_774654, url, valid)

proc call*(call_774655: Call_PostUpdateApplication_774640; ApplicationName: string;
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
  var query_774656 = newJObject()
  var formData_774657 = newJObject()
  add(query_774656, "Action", newJString(Action))
  add(formData_774657, "ApplicationName", newJString(ApplicationName))
  add(query_774656, "Version", newJString(Version))
  add(formData_774657, "Description", newJString(Description))
  result = call_774655.call(nil, query_774656, nil, formData_774657, nil)

var postUpdateApplication* = Call_PostUpdateApplication_774640(
    name: "postUpdateApplication", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateApplication",
    validator: validate_PostUpdateApplication_774641, base: "/",
    url: url_PostUpdateApplication_774642, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateApplication_774623 = ref object of OpenApiRestCall_772598
proc url_GetUpdateApplication_774625(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUpdateApplication_774624(path: JsonNode; query: JsonNode;
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
  var valid_774626 = query.getOrDefault("ApplicationName")
  valid_774626 = validateParameter(valid_774626, JString, required = true,
                                 default = nil)
  if valid_774626 != nil:
    section.add "ApplicationName", valid_774626
  var valid_774627 = query.getOrDefault("Description")
  valid_774627 = validateParameter(valid_774627, JString, required = false,
                                 default = nil)
  if valid_774627 != nil:
    section.add "Description", valid_774627
  var valid_774628 = query.getOrDefault("Action")
  valid_774628 = validateParameter(valid_774628, JString, required = true,
                                 default = newJString("UpdateApplication"))
  if valid_774628 != nil:
    section.add "Action", valid_774628
  var valid_774629 = query.getOrDefault("Version")
  valid_774629 = validateParameter(valid_774629, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_774629 != nil:
    section.add "Version", valid_774629
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774630 = header.getOrDefault("X-Amz-Date")
  valid_774630 = validateParameter(valid_774630, JString, required = false,
                                 default = nil)
  if valid_774630 != nil:
    section.add "X-Amz-Date", valid_774630
  var valid_774631 = header.getOrDefault("X-Amz-Security-Token")
  valid_774631 = validateParameter(valid_774631, JString, required = false,
                                 default = nil)
  if valid_774631 != nil:
    section.add "X-Amz-Security-Token", valid_774631
  var valid_774632 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774632 = validateParameter(valid_774632, JString, required = false,
                                 default = nil)
  if valid_774632 != nil:
    section.add "X-Amz-Content-Sha256", valid_774632
  var valid_774633 = header.getOrDefault("X-Amz-Algorithm")
  valid_774633 = validateParameter(valid_774633, JString, required = false,
                                 default = nil)
  if valid_774633 != nil:
    section.add "X-Amz-Algorithm", valid_774633
  var valid_774634 = header.getOrDefault("X-Amz-Signature")
  valid_774634 = validateParameter(valid_774634, JString, required = false,
                                 default = nil)
  if valid_774634 != nil:
    section.add "X-Amz-Signature", valid_774634
  var valid_774635 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774635 = validateParameter(valid_774635, JString, required = false,
                                 default = nil)
  if valid_774635 != nil:
    section.add "X-Amz-SignedHeaders", valid_774635
  var valid_774636 = header.getOrDefault("X-Amz-Credential")
  valid_774636 = validateParameter(valid_774636, JString, required = false,
                                 default = nil)
  if valid_774636 != nil:
    section.add "X-Amz-Credential", valid_774636
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774637: Call_GetUpdateApplication_774623; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified application to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear these properties, specify an empty string.</p> </note>
  ## 
  let valid = call_774637.validator(path, query, header, formData, body)
  let scheme = call_774637.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774637.url(scheme.get, call_774637.host, call_774637.base,
                         call_774637.route, valid.getOrDefault("path"))
  result = hook(call_774637, url, valid)

proc call*(call_774638: Call_GetUpdateApplication_774623; ApplicationName: string;
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
  var query_774639 = newJObject()
  add(query_774639, "ApplicationName", newJString(ApplicationName))
  add(query_774639, "Description", newJString(Description))
  add(query_774639, "Action", newJString(Action))
  add(query_774639, "Version", newJString(Version))
  result = call_774638.call(nil, query_774639, nil, nil, nil)

var getUpdateApplication* = Call_GetUpdateApplication_774623(
    name: "getUpdateApplication", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateApplication",
    validator: validate_GetUpdateApplication_774624, base: "/",
    url: url_GetUpdateApplication_774625, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateApplicationResourceLifecycle_774676 = ref object of OpenApiRestCall_772598
proc url_PostUpdateApplicationResourceLifecycle_774678(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostUpdateApplicationResourceLifecycle_774677(path: JsonNode;
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
  var valid_774679 = query.getOrDefault("Action")
  valid_774679 = validateParameter(valid_774679, JString, required = true, default = newJString(
      "UpdateApplicationResourceLifecycle"))
  if valid_774679 != nil:
    section.add "Action", valid_774679
  var valid_774680 = query.getOrDefault("Version")
  valid_774680 = validateParameter(valid_774680, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_774680 != nil:
    section.add "Version", valid_774680
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774681 = header.getOrDefault("X-Amz-Date")
  valid_774681 = validateParameter(valid_774681, JString, required = false,
                                 default = nil)
  if valid_774681 != nil:
    section.add "X-Amz-Date", valid_774681
  var valid_774682 = header.getOrDefault("X-Amz-Security-Token")
  valid_774682 = validateParameter(valid_774682, JString, required = false,
                                 default = nil)
  if valid_774682 != nil:
    section.add "X-Amz-Security-Token", valid_774682
  var valid_774683 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774683 = validateParameter(valid_774683, JString, required = false,
                                 default = nil)
  if valid_774683 != nil:
    section.add "X-Amz-Content-Sha256", valid_774683
  var valid_774684 = header.getOrDefault("X-Amz-Algorithm")
  valid_774684 = validateParameter(valid_774684, JString, required = false,
                                 default = nil)
  if valid_774684 != nil:
    section.add "X-Amz-Algorithm", valid_774684
  var valid_774685 = header.getOrDefault("X-Amz-Signature")
  valid_774685 = validateParameter(valid_774685, JString, required = false,
                                 default = nil)
  if valid_774685 != nil:
    section.add "X-Amz-Signature", valid_774685
  var valid_774686 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774686 = validateParameter(valid_774686, JString, required = false,
                                 default = nil)
  if valid_774686 != nil:
    section.add "X-Amz-SignedHeaders", valid_774686
  var valid_774687 = header.getOrDefault("X-Amz-Credential")
  valid_774687 = validateParameter(valid_774687, JString, required = false,
                                 default = nil)
  if valid_774687 != nil:
    section.add "X-Amz-Credential", valid_774687
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
  var valid_774688 = formData.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_774688 = validateParameter(valid_774688, JString, required = false,
                                 default = nil)
  if valid_774688 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_774688
  var valid_774689 = formData.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_774689 = validateParameter(valid_774689, JString, required = false,
                                 default = nil)
  if valid_774689 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_774689
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_774690 = formData.getOrDefault("ApplicationName")
  valid_774690 = validateParameter(valid_774690, JString, required = true,
                                 default = nil)
  if valid_774690 != nil:
    section.add "ApplicationName", valid_774690
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774691: Call_PostUpdateApplicationResourceLifecycle_774676;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Modifies lifecycle settings for an application.
  ## 
  let valid = call_774691.validator(path, query, header, formData, body)
  let scheme = call_774691.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774691.url(scheme.get, call_774691.host, call_774691.base,
                         call_774691.route, valid.getOrDefault("path"))
  result = hook(call_774691, url, valid)

proc call*(call_774692: Call_PostUpdateApplicationResourceLifecycle_774676;
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
  var query_774693 = newJObject()
  var formData_774694 = newJObject()
  add(formData_774694, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  add(formData_774694, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  add(query_774693, "Action", newJString(Action))
  add(formData_774694, "ApplicationName", newJString(ApplicationName))
  add(query_774693, "Version", newJString(Version))
  result = call_774692.call(nil, query_774693, nil, formData_774694, nil)

var postUpdateApplicationResourceLifecycle* = Call_PostUpdateApplicationResourceLifecycle_774676(
    name: "postUpdateApplicationResourceLifecycle", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationResourceLifecycle",
    validator: validate_PostUpdateApplicationResourceLifecycle_774677, base: "/",
    url: url_PostUpdateApplicationResourceLifecycle_774678,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateApplicationResourceLifecycle_774658 = ref object of OpenApiRestCall_772598
proc url_GetUpdateApplicationResourceLifecycle_774660(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUpdateApplicationResourceLifecycle_774659(path: JsonNode;
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
  var valid_774661 = query.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_774661 = validateParameter(valid_774661, JString, required = false,
                                 default = nil)
  if valid_774661 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_774661
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_774662 = query.getOrDefault("ApplicationName")
  valid_774662 = validateParameter(valid_774662, JString, required = true,
                                 default = nil)
  if valid_774662 != nil:
    section.add "ApplicationName", valid_774662
  var valid_774663 = query.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_774663 = validateParameter(valid_774663, JString, required = false,
                                 default = nil)
  if valid_774663 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_774663
  var valid_774664 = query.getOrDefault("Action")
  valid_774664 = validateParameter(valid_774664, JString, required = true, default = newJString(
      "UpdateApplicationResourceLifecycle"))
  if valid_774664 != nil:
    section.add "Action", valid_774664
  var valid_774665 = query.getOrDefault("Version")
  valid_774665 = validateParameter(valid_774665, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_774665 != nil:
    section.add "Version", valid_774665
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774666 = header.getOrDefault("X-Amz-Date")
  valid_774666 = validateParameter(valid_774666, JString, required = false,
                                 default = nil)
  if valid_774666 != nil:
    section.add "X-Amz-Date", valid_774666
  var valid_774667 = header.getOrDefault("X-Amz-Security-Token")
  valid_774667 = validateParameter(valid_774667, JString, required = false,
                                 default = nil)
  if valid_774667 != nil:
    section.add "X-Amz-Security-Token", valid_774667
  var valid_774668 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774668 = validateParameter(valid_774668, JString, required = false,
                                 default = nil)
  if valid_774668 != nil:
    section.add "X-Amz-Content-Sha256", valid_774668
  var valid_774669 = header.getOrDefault("X-Amz-Algorithm")
  valid_774669 = validateParameter(valid_774669, JString, required = false,
                                 default = nil)
  if valid_774669 != nil:
    section.add "X-Amz-Algorithm", valid_774669
  var valid_774670 = header.getOrDefault("X-Amz-Signature")
  valid_774670 = validateParameter(valid_774670, JString, required = false,
                                 default = nil)
  if valid_774670 != nil:
    section.add "X-Amz-Signature", valid_774670
  var valid_774671 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774671 = validateParameter(valid_774671, JString, required = false,
                                 default = nil)
  if valid_774671 != nil:
    section.add "X-Amz-SignedHeaders", valid_774671
  var valid_774672 = header.getOrDefault("X-Amz-Credential")
  valid_774672 = validateParameter(valid_774672, JString, required = false,
                                 default = nil)
  if valid_774672 != nil:
    section.add "X-Amz-Credential", valid_774672
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774673: Call_GetUpdateApplicationResourceLifecycle_774658;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Modifies lifecycle settings for an application.
  ## 
  let valid = call_774673.validator(path, query, header, formData, body)
  let scheme = call_774673.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774673.url(scheme.get, call_774673.host, call_774673.base,
                         call_774673.route, valid.getOrDefault("path"))
  result = hook(call_774673, url, valid)

proc call*(call_774674: Call_GetUpdateApplicationResourceLifecycle_774658;
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
  var query_774675 = newJObject()
  add(query_774675, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  add(query_774675, "ApplicationName", newJString(ApplicationName))
  add(query_774675, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  add(query_774675, "Action", newJString(Action))
  add(query_774675, "Version", newJString(Version))
  result = call_774674.call(nil, query_774675, nil, nil, nil)

var getUpdateApplicationResourceLifecycle* = Call_GetUpdateApplicationResourceLifecycle_774658(
    name: "getUpdateApplicationResourceLifecycle", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationResourceLifecycle",
    validator: validate_GetUpdateApplicationResourceLifecycle_774659, base: "/",
    url: url_GetUpdateApplicationResourceLifecycle_774660,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateApplicationVersion_774713 = ref object of OpenApiRestCall_772598
proc url_PostUpdateApplicationVersion_774715(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostUpdateApplicationVersion_774714(path: JsonNode; query: JsonNode;
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
  var valid_774716 = query.getOrDefault("Action")
  valid_774716 = validateParameter(valid_774716, JString, required = true, default = newJString(
      "UpdateApplicationVersion"))
  if valid_774716 != nil:
    section.add "Action", valid_774716
  var valid_774717 = query.getOrDefault("Version")
  valid_774717 = validateParameter(valid_774717, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_774717 != nil:
    section.add "Version", valid_774717
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774718 = header.getOrDefault("X-Amz-Date")
  valid_774718 = validateParameter(valid_774718, JString, required = false,
                                 default = nil)
  if valid_774718 != nil:
    section.add "X-Amz-Date", valid_774718
  var valid_774719 = header.getOrDefault("X-Amz-Security-Token")
  valid_774719 = validateParameter(valid_774719, JString, required = false,
                                 default = nil)
  if valid_774719 != nil:
    section.add "X-Amz-Security-Token", valid_774719
  var valid_774720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774720 = validateParameter(valid_774720, JString, required = false,
                                 default = nil)
  if valid_774720 != nil:
    section.add "X-Amz-Content-Sha256", valid_774720
  var valid_774721 = header.getOrDefault("X-Amz-Algorithm")
  valid_774721 = validateParameter(valid_774721, JString, required = false,
                                 default = nil)
  if valid_774721 != nil:
    section.add "X-Amz-Algorithm", valid_774721
  var valid_774722 = header.getOrDefault("X-Amz-Signature")
  valid_774722 = validateParameter(valid_774722, JString, required = false,
                                 default = nil)
  if valid_774722 != nil:
    section.add "X-Amz-Signature", valid_774722
  var valid_774723 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774723 = validateParameter(valid_774723, JString, required = false,
                                 default = nil)
  if valid_774723 != nil:
    section.add "X-Amz-SignedHeaders", valid_774723
  var valid_774724 = header.getOrDefault("X-Amz-Credential")
  valid_774724 = validateParameter(valid_774724, JString, required = false,
                                 default = nil)
  if valid_774724 != nil:
    section.add "X-Amz-Credential", valid_774724
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
  var valid_774725 = formData.getOrDefault("VersionLabel")
  valid_774725 = validateParameter(valid_774725, JString, required = true,
                                 default = nil)
  if valid_774725 != nil:
    section.add "VersionLabel", valid_774725
  var valid_774726 = formData.getOrDefault("ApplicationName")
  valid_774726 = validateParameter(valid_774726, JString, required = true,
                                 default = nil)
  if valid_774726 != nil:
    section.add "ApplicationName", valid_774726
  var valid_774727 = formData.getOrDefault("Description")
  valid_774727 = validateParameter(valid_774727, JString, required = false,
                                 default = nil)
  if valid_774727 != nil:
    section.add "Description", valid_774727
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774728: Call_PostUpdateApplicationVersion_774713; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified application version to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear properties, specify an empty string.</p> </note>
  ## 
  let valid = call_774728.validator(path, query, header, formData, body)
  let scheme = call_774728.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774728.url(scheme.get, call_774728.host, call_774728.base,
                         call_774728.route, valid.getOrDefault("path"))
  result = hook(call_774728, url, valid)

proc call*(call_774729: Call_PostUpdateApplicationVersion_774713;
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
  var query_774730 = newJObject()
  var formData_774731 = newJObject()
  add(formData_774731, "VersionLabel", newJString(VersionLabel))
  add(query_774730, "Action", newJString(Action))
  add(formData_774731, "ApplicationName", newJString(ApplicationName))
  add(query_774730, "Version", newJString(Version))
  add(formData_774731, "Description", newJString(Description))
  result = call_774729.call(nil, query_774730, nil, formData_774731, nil)

var postUpdateApplicationVersion* = Call_PostUpdateApplicationVersion_774713(
    name: "postUpdateApplicationVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationVersion",
    validator: validate_PostUpdateApplicationVersion_774714, base: "/",
    url: url_PostUpdateApplicationVersion_774715,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateApplicationVersion_774695 = ref object of OpenApiRestCall_772598
proc url_GetUpdateApplicationVersion_774697(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUpdateApplicationVersion_774696(path: JsonNode; query: JsonNode;
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
  var valid_774698 = query.getOrDefault("VersionLabel")
  valid_774698 = validateParameter(valid_774698, JString, required = true,
                                 default = nil)
  if valid_774698 != nil:
    section.add "VersionLabel", valid_774698
  var valid_774699 = query.getOrDefault("ApplicationName")
  valid_774699 = validateParameter(valid_774699, JString, required = true,
                                 default = nil)
  if valid_774699 != nil:
    section.add "ApplicationName", valid_774699
  var valid_774700 = query.getOrDefault("Description")
  valid_774700 = validateParameter(valid_774700, JString, required = false,
                                 default = nil)
  if valid_774700 != nil:
    section.add "Description", valid_774700
  var valid_774701 = query.getOrDefault("Action")
  valid_774701 = validateParameter(valid_774701, JString, required = true, default = newJString(
      "UpdateApplicationVersion"))
  if valid_774701 != nil:
    section.add "Action", valid_774701
  var valid_774702 = query.getOrDefault("Version")
  valid_774702 = validateParameter(valid_774702, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_774702 != nil:
    section.add "Version", valid_774702
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774703 = header.getOrDefault("X-Amz-Date")
  valid_774703 = validateParameter(valid_774703, JString, required = false,
                                 default = nil)
  if valid_774703 != nil:
    section.add "X-Amz-Date", valid_774703
  var valid_774704 = header.getOrDefault("X-Amz-Security-Token")
  valid_774704 = validateParameter(valid_774704, JString, required = false,
                                 default = nil)
  if valid_774704 != nil:
    section.add "X-Amz-Security-Token", valid_774704
  var valid_774705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774705 = validateParameter(valid_774705, JString, required = false,
                                 default = nil)
  if valid_774705 != nil:
    section.add "X-Amz-Content-Sha256", valid_774705
  var valid_774706 = header.getOrDefault("X-Amz-Algorithm")
  valid_774706 = validateParameter(valid_774706, JString, required = false,
                                 default = nil)
  if valid_774706 != nil:
    section.add "X-Amz-Algorithm", valid_774706
  var valid_774707 = header.getOrDefault("X-Amz-Signature")
  valid_774707 = validateParameter(valid_774707, JString, required = false,
                                 default = nil)
  if valid_774707 != nil:
    section.add "X-Amz-Signature", valid_774707
  var valid_774708 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774708 = validateParameter(valid_774708, JString, required = false,
                                 default = nil)
  if valid_774708 != nil:
    section.add "X-Amz-SignedHeaders", valid_774708
  var valid_774709 = header.getOrDefault("X-Amz-Credential")
  valid_774709 = validateParameter(valid_774709, JString, required = false,
                                 default = nil)
  if valid_774709 != nil:
    section.add "X-Amz-Credential", valid_774709
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774710: Call_GetUpdateApplicationVersion_774695; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified application version to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear properties, specify an empty string.</p> </note>
  ## 
  let valid = call_774710.validator(path, query, header, formData, body)
  let scheme = call_774710.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774710.url(scheme.get, call_774710.host, call_774710.base,
                         call_774710.route, valid.getOrDefault("path"))
  result = hook(call_774710, url, valid)

proc call*(call_774711: Call_GetUpdateApplicationVersion_774695;
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
  var query_774712 = newJObject()
  add(query_774712, "VersionLabel", newJString(VersionLabel))
  add(query_774712, "ApplicationName", newJString(ApplicationName))
  add(query_774712, "Description", newJString(Description))
  add(query_774712, "Action", newJString(Action))
  add(query_774712, "Version", newJString(Version))
  result = call_774711.call(nil, query_774712, nil, nil, nil)

var getUpdateApplicationVersion* = Call_GetUpdateApplicationVersion_774695(
    name: "getUpdateApplicationVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationVersion",
    validator: validate_GetUpdateApplicationVersion_774696, base: "/",
    url: url_GetUpdateApplicationVersion_774697,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateConfigurationTemplate_774752 = ref object of OpenApiRestCall_772598
proc url_PostUpdateConfigurationTemplate_774754(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostUpdateConfigurationTemplate_774753(path: JsonNode;
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
  var valid_774755 = query.getOrDefault("Action")
  valid_774755 = validateParameter(valid_774755, JString, required = true, default = newJString(
      "UpdateConfigurationTemplate"))
  if valid_774755 != nil:
    section.add "Action", valid_774755
  var valid_774756 = query.getOrDefault("Version")
  valid_774756 = validateParameter(valid_774756, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_774756 != nil:
    section.add "Version", valid_774756
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774757 = header.getOrDefault("X-Amz-Date")
  valid_774757 = validateParameter(valid_774757, JString, required = false,
                                 default = nil)
  if valid_774757 != nil:
    section.add "X-Amz-Date", valid_774757
  var valid_774758 = header.getOrDefault("X-Amz-Security-Token")
  valid_774758 = validateParameter(valid_774758, JString, required = false,
                                 default = nil)
  if valid_774758 != nil:
    section.add "X-Amz-Security-Token", valid_774758
  var valid_774759 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774759 = validateParameter(valid_774759, JString, required = false,
                                 default = nil)
  if valid_774759 != nil:
    section.add "X-Amz-Content-Sha256", valid_774759
  var valid_774760 = header.getOrDefault("X-Amz-Algorithm")
  valid_774760 = validateParameter(valid_774760, JString, required = false,
                                 default = nil)
  if valid_774760 != nil:
    section.add "X-Amz-Algorithm", valid_774760
  var valid_774761 = header.getOrDefault("X-Amz-Signature")
  valid_774761 = validateParameter(valid_774761, JString, required = false,
                                 default = nil)
  if valid_774761 != nil:
    section.add "X-Amz-Signature", valid_774761
  var valid_774762 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774762 = validateParameter(valid_774762, JString, required = false,
                                 default = nil)
  if valid_774762 != nil:
    section.add "X-Amz-SignedHeaders", valid_774762
  var valid_774763 = header.getOrDefault("X-Amz-Credential")
  valid_774763 = validateParameter(valid_774763, JString, required = false,
                                 default = nil)
  if valid_774763 != nil:
    section.add "X-Amz-Credential", valid_774763
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
  var valid_774764 = formData.getOrDefault("OptionsToRemove")
  valid_774764 = validateParameter(valid_774764, JArray, required = false,
                                 default = nil)
  if valid_774764 != nil:
    section.add "OptionsToRemove", valid_774764
  var valid_774765 = formData.getOrDefault("OptionSettings")
  valid_774765 = validateParameter(valid_774765, JArray, required = false,
                                 default = nil)
  if valid_774765 != nil:
    section.add "OptionSettings", valid_774765
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_774766 = formData.getOrDefault("ApplicationName")
  valid_774766 = validateParameter(valid_774766, JString, required = true,
                                 default = nil)
  if valid_774766 != nil:
    section.add "ApplicationName", valid_774766
  var valid_774767 = formData.getOrDefault("TemplateName")
  valid_774767 = validateParameter(valid_774767, JString, required = true,
                                 default = nil)
  if valid_774767 != nil:
    section.add "TemplateName", valid_774767
  var valid_774768 = formData.getOrDefault("Description")
  valid_774768 = validateParameter(valid_774768, JString, required = false,
                                 default = nil)
  if valid_774768 != nil:
    section.add "Description", valid_774768
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774769: Call_PostUpdateConfigurationTemplate_774752;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Updates the specified configuration template to have the specified properties or configuration option values.</p> <note> <p>If a property (for example, <code>ApplicationName</code>) is not provided, its value remains unchanged. To clear such properties, specify an empty string.</p> </note> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> </ul>
  ## 
  let valid = call_774769.validator(path, query, header, formData, body)
  let scheme = call_774769.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774769.url(scheme.get, call_774769.host, call_774769.base,
                         call_774769.route, valid.getOrDefault("path"))
  result = hook(call_774769, url, valid)

proc call*(call_774770: Call_PostUpdateConfigurationTemplate_774752;
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
  var query_774771 = newJObject()
  var formData_774772 = newJObject()
  if OptionsToRemove != nil:
    formData_774772.add "OptionsToRemove", OptionsToRemove
  if OptionSettings != nil:
    formData_774772.add "OptionSettings", OptionSettings
  add(query_774771, "Action", newJString(Action))
  add(formData_774772, "ApplicationName", newJString(ApplicationName))
  add(formData_774772, "TemplateName", newJString(TemplateName))
  add(query_774771, "Version", newJString(Version))
  add(formData_774772, "Description", newJString(Description))
  result = call_774770.call(nil, query_774771, nil, formData_774772, nil)

var postUpdateConfigurationTemplate* = Call_PostUpdateConfigurationTemplate_774752(
    name: "postUpdateConfigurationTemplate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateConfigurationTemplate",
    validator: validate_PostUpdateConfigurationTemplate_774753, base: "/",
    url: url_PostUpdateConfigurationTemplate_774754,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateConfigurationTemplate_774732 = ref object of OpenApiRestCall_772598
proc url_GetUpdateConfigurationTemplate_774734(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUpdateConfigurationTemplate_774733(path: JsonNode;
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
  var valid_774735 = query.getOrDefault("ApplicationName")
  valid_774735 = validateParameter(valid_774735, JString, required = true,
                                 default = nil)
  if valid_774735 != nil:
    section.add "ApplicationName", valid_774735
  var valid_774736 = query.getOrDefault("Description")
  valid_774736 = validateParameter(valid_774736, JString, required = false,
                                 default = nil)
  if valid_774736 != nil:
    section.add "Description", valid_774736
  var valid_774737 = query.getOrDefault("OptionsToRemove")
  valid_774737 = validateParameter(valid_774737, JArray, required = false,
                                 default = nil)
  if valid_774737 != nil:
    section.add "OptionsToRemove", valid_774737
  var valid_774738 = query.getOrDefault("Action")
  valid_774738 = validateParameter(valid_774738, JString, required = true, default = newJString(
      "UpdateConfigurationTemplate"))
  if valid_774738 != nil:
    section.add "Action", valid_774738
  var valid_774739 = query.getOrDefault("TemplateName")
  valid_774739 = validateParameter(valid_774739, JString, required = true,
                                 default = nil)
  if valid_774739 != nil:
    section.add "TemplateName", valid_774739
  var valid_774740 = query.getOrDefault("OptionSettings")
  valid_774740 = validateParameter(valid_774740, JArray, required = false,
                                 default = nil)
  if valid_774740 != nil:
    section.add "OptionSettings", valid_774740
  var valid_774741 = query.getOrDefault("Version")
  valid_774741 = validateParameter(valid_774741, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_774741 != nil:
    section.add "Version", valid_774741
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774742 = header.getOrDefault("X-Amz-Date")
  valid_774742 = validateParameter(valid_774742, JString, required = false,
                                 default = nil)
  if valid_774742 != nil:
    section.add "X-Amz-Date", valid_774742
  var valid_774743 = header.getOrDefault("X-Amz-Security-Token")
  valid_774743 = validateParameter(valid_774743, JString, required = false,
                                 default = nil)
  if valid_774743 != nil:
    section.add "X-Amz-Security-Token", valid_774743
  var valid_774744 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774744 = validateParameter(valid_774744, JString, required = false,
                                 default = nil)
  if valid_774744 != nil:
    section.add "X-Amz-Content-Sha256", valid_774744
  var valid_774745 = header.getOrDefault("X-Amz-Algorithm")
  valid_774745 = validateParameter(valid_774745, JString, required = false,
                                 default = nil)
  if valid_774745 != nil:
    section.add "X-Amz-Algorithm", valid_774745
  var valid_774746 = header.getOrDefault("X-Amz-Signature")
  valid_774746 = validateParameter(valid_774746, JString, required = false,
                                 default = nil)
  if valid_774746 != nil:
    section.add "X-Amz-Signature", valid_774746
  var valid_774747 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774747 = validateParameter(valid_774747, JString, required = false,
                                 default = nil)
  if valid_774747 != nil:
    section.add "X-Amz-SignedHeaders", valid_774747
  var valid_774748 = header.getOrDefault("X-Amz-Credential")
  valid_774748 = validateParameter(valid_774748, JString, required = false,
                                 default = nil)
  if valid_774748 != nil:
    section.add "X-Amz-Credential", valid_774748
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774749: Call_GetUpdateConfigurationTemplate_774732; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified configuration template to have the specified properties or configuration option values.</p> <note> <p>If a property (for example, <code>ApplicationName</code>) is not provided, its value remains unchanged. To clear such properties, specify an empty string.</p> </note> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> </ul>
  ## 
  let valid = call_774749.validator(path, query, header, formData, body)
  let scheme = call_774749.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774749.url(scheme.get, call_774749.host, call_774749.base,
                         call_774749.route, valid.getOrDefault("path"))
  result = hook(call_774749, url, valid)

proc call*(call_774750: Call_GetUpdateConfigurationTemplate_774732;
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
  var query_774751 = newJObject()
  add(query_774751, "ApplicationName", newJString(ApplicationName))
  add(query_774751, "Description", newJString(Description))
  if OptionsToRemove != nil:
    query_774751.add "OptionsToRemove", OptionsToRemove
  add(query_774751, "Action", newJString(Action))
  add(query_774751, "TemplateName", newJString(TemplateName))
  if OptionSettings != nil:
    query_774751.add "OptionSettings", OptionSettings
  add(query_774751, "Version", newJString(Version))
  result = call_774750.call(nil, query_774751, nil, nil, nil)

var getUpdateConfigurationTemplate* = Call_GetUpdateConfigurationTemplate_774732(
    name: "getUpdateConfigurationTemplate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateConfigurationTemplate",
    validator: validate_GetUpdateConfigurationTemplate_774733, base: "/",
    url: url_GetUpdateConfigurationTemplate_774734,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateEnvironment_774802 = ref object of OpenApiRestCall_772598
proc url_PostUpdateEnvironment_774804(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostUpdateEnvironment_774803(path: JsonNode; query: JsonNode;
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
  var valid_774805 = query.getOrDefault("Action")
  valid_774805 = validateParameter(valid_774805, JString, required = true,
                                 default = newJString("UpdateEnvironment"))
  if valid_774805 != nil:
    section.add "Action", valid_774805
  var valid_774806 = query.getOrDefault("Version")
  valid_774806 = validateParameter(valid_774806, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_774806 != nil:
    section.add "Version", valid_774806
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774807 = header.getOrDefault("X-Amz-Date")
  valid_774807 = validateParameter(valid_774807, JString, required = false,
                                 default = nil)
  if valid_774807 != nil:
    section.add "X-Amz-Date", valid_774807
  var valid_774808 = header.getOrDefault("X-Amz-Security-Token")
  valid_774808 = validateParameter(valid_774808, JString, required = false,
                                 default = nil)
  if valid_774808 != nil:
    section.add "X-Amz-Security-Token", valid_774808
  var valid_774809 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774809 = validateParameter(valid_774809, JString, required = false,
                                 default = nil)
  if valid_774809 != nil:
    section.add "X-Amz-Content-Sha256", valid_774809
  var valid_774810 = header.getOrDefault("X-Amz-Algorithm")
  valid_774810 = validateParameter(valid_774810, JString, required = false,
                                 default = nil)
  if valid_774810 != nil:
    section.add "X-Amz-Algorithm", valid_774810
  var valid_774811 = header.getOrDefault("X-Amz-Signature")
  valid_774811 = validateParameter(valid_774811, JString, required = false,
                                 default = nil)
  if valid_774811 != nil:
    section.add "X-Amz-Signature", valid_774811
  var valid_774812 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774812 = validateParameter(valid_774812, JString, required = false,
                                 default = nil)
  if valid_774812 != nil:
    section.add "X-Amz-SignedHeaders", valid_774812
  var valid_774813 = header.getOrDefault("X-Amz-Credential")
  valid_774813 = validateParameter(valid_774813, JString, required = false,
                                 default = nil)
  if valid_774813 != nil:
    section.add "X-Amz-Credential", valid_774813
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
  var valid_774814 = formData.getOrDefault("Tier.Name")
  valid_774814 = validateParameter(valid_774814, JString, required = false,
                                 default = nil)
  if valid_774814 != nil:
    section.add "Tier.Name", valid_774814
  var valid_774815 = formData.getOrDefault("OptionsToRemove")
  valid_774815 = validateParameter(valid_774815, JArray, required = false,
                                 default = nil)
  if valid_774815 != nil:
    section.add "OptionsToRemove", valid_774815
  var valid_774816 = formData.getOrDefault("VersionLabel")
  valid_774816 = validateParameter(valid_774816, JString, required = false,
                                 default = nil)
  if valid_774816 != nil:
    section.add "VersionLabel", valid_774816
  var valid_774817 = formData.getOrDefault("OptionSettings")
  valid_774817 = validateParameter(valid_774817, JArray, required = false,
                                 default = nil)
  if valid_774817 != nil:
    section.add "OptionSettings", valid_774817
  var valid_774818 = formData.getOrDefault("GroupName")
  valid_774818 = validateParameter(valid_774818, JString, required = false,
                                 default = nil)
  if valid_774818 != nil:
    section.add "GroupName", valid_774818
  var valid_774819 = formData.getOrDefault("SolutionStackName")
  valid_774819 = validateParameter(valid_774819, JString, required = false,
                                 default = nil)
  if valid_774819 != nil:
    section.add "SolutionStackName", valid_774819
  var valid_774820 = formData.getOrDefault("EnvironmentId")
  valid_774820 = validateParameter(valid_774820, JString, required = false,
                                 default = nil)
  if valid_774820 != nil:
    section.add "EnvironmentId", valid_774820
  var valid_774821 = formData.getOrDefault("EnvironmentName")
  valid_774821 = validateParameter(valid_774821, JString, required = false,
                                 default = nil)
  if valid_774821 != nil:
    section.add "EnvironmentName", valid_774821
  var valid_774822 = formData.getOrDefault("Tier.Type")
  valid_774822 = validateParameter(valid_774822, JString, required = false,
                                 default = nil)
  if valid_774822 != nil:
    section.add "Tier.Type", valid_774822
  var valid_774823 = formData.getOrDefault("ApplicationName")
  valid_774823 = validateParameter(valid_774823, JString, required = false,
                                 default = nil)
  if valid_774823 != nil:
    section.add "ApplicationName", valid_774823
  var valid_774824 = formData.getOrDefault("PlatformArn")
  valid_774824 = validateParameter(valid_774824, JString, required = false,
                                 default = nil)
  if valid_774824 != nil:
    section.add "PlatformArn", valid_774824
  var valid_774825 = formData.getOrDefault("TemplateName")
  valid_774825 = validateParameter(valid_774825, JString, required = false,
                                 default = nil)
  if valid_774825 != nil:
    section.add "TemplateName", valid_774825
  var valid_774826 = formData.getOrDefault("Description")
  valid_774826 = validateParameter(valid_774826, JString, required = false,
                                 default = nil)
  if valid_774826 != nil:
    section.add "Description", valid_774826
  var valid_774827 = formData.getOrDefault("Tier.Version")
  valid_774827 = validateParameter(valid_774827, JString, required = false,
                                 default = nil)
  if valid_774827 != nil:
    section.add "Tier.Version", valid_774827
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774828: Call_PostUpdateEnvironment_774802; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the environment description, deploys a new application version, updates the configuration settings to an entirely new configuration template, or updates select configuration option values in the running environment.</p> <p> Attempting to update both the release and configuration is not allowed and AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. </p> <p> When updating the configuration settings to a new template or individual settings, a draft configuration is created and <a>DescribeConfigurationSettings</a> for this environment returns two setting descriptions with different <code>DeploymentStatus</code> values. </p>
  ## 
  let valid = call_774828.validator(path, query, header, formData, body)
  let scheme = call_774828.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774828.url(scheme.get, call_774828.host, call_774828.base,
                         call_774828.route, valid.getOrDefault("path"))
  result = hook(call_774828, url, valid)

proc call*(call_774829: Call_PostUpdateEnvironment_774802; TierName: string = "";
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
  var query_774830 = newJObject()
  var formData_774831 = newJObject()
  add(formData_774831, "Tier.Name", newJString(TierName))
  if OptionsToRemove != nil:
    formData_774831.add "OptionsToRemove", OptionsToRemove
  add(formData_774831, "VersionLabel", newJString(VersionLabel))
  if OptionSettings != nil:
    formData_774831.add "OptionSettings", OptionSettings
  add(formData_774831, "GroupName", newJString(GroupName))
  add(formData_774831, "SolutionStackName", newJString(SolutionStackName))
  add(formData_774831, "EnvironmentId", newJString(EnvironmentId))
  add(formData_774831, "EnvironmentName", newJString(EnvironmentName))
  add(formData_774831, "Tier.Type", newJString(TierType))
  add(query_774830, "Action", newJString(Action))
  add(formData_774831, "ApplicationName", newJString(ApplicationName))
  add(formData_774831, "PlatformArn", newJString(PlatformArn))
  add(formData_774831, "TemplateName", newJString(TemplateName))
  add(query_774830, "Version", newJString(Version))
  add(formData_774831, "Description", newJString(Description))
  add(formData_774831, "Tier.Version", newJString(TierVersion))
  result = call_774829.call(nil, query_774830, nil, formData_774831, nil)

var postUpdateEnvironment* = Call_PostUpdateEnvironment_774802(
    name: "postUpdateEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateEnvironment",
    validator: validate_PostUpdateEnvironment_774803, base: "/",
    url: url_PostUpdateEnvironment_774804, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateEnvironment_774773 = ref object of OpenApiRestCall_772598
proc url_GetUpdateEnvironment_774775(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUpdateEnvironment_774774(path: JsonNode; query: JsonNode;
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
  var valid_774776 = query.getOrDefault("Tier.Name")
  valid_774776 = validateParameter(valid_774776, JString, required = false,
                                 default = nil)
  if valid_774776 != nil:
    section.add "Tier.Name", valid_774776
  var valid_774777 = query.getOrDefault("VersionLabel")
  valid_774777 = validateParameter(valid_774777, JString, required = false,
                                 default = nil)
  if valid_774777 != nil:
    section.add "VersionLabel", valid_774777
  var valid_774778 = query.getOrDefault("ApplicationName")
  valid_774778 = validateParameter(valid_774778, JString, required = false,
                                 default = nil)
  if valid_774778 != nil:
    section.add "ApplicationName", valid_774778
  var valid_774779 = query.getOrDefault("Description")
  valid_774779 = validateParameter(valid_774779, JString, required = false,
                                 default = nil)
  if valid_774779 != nil:
    section.add "Description", valid_774779
  var valid_774780 = query.getOrDefault("OptionsToRemove")
  valid_774780 = validateParameter(valid_774780, JArray, required = false,
                                 default = nil)
  if valid_774780 != nil:
    section.add "OptionsToRemove", valid_774780
  var valid_774781 = query.getOrDefault("PlatformArn")
  valid_774781 = validateParameter(valid_774781, JString, required = false,
                                 default = nil)
  if valid_774781 != nil:
    section.add "PlatformArn", valid_774781
  var valid_774782 = query.getOrDefault("EnvironmentName")
  valid_774782 = validateParameter(valid_774782, JString, required = false,
                                 default = nil)
  if valid_774782 != nil:
    section.add "EnvironmentName", valid_774782
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_774783 = query.getOrDefault("Action")
  valid_774783 = validateParameter(valid_774783, JString, required = true,
                                 default = newJString("UpdateEnvironment"))
  if valid_774783 != nil:
    section.add "Action", valid_774783
  var valid_774784 = query.getOrDefault("EnvironmentId")
  valid_774784 = validateParameter(valid_774784, JString, required = false,
                                 default = nil)
  if valid_774784 != nil:
    section.add "EnvironmentId", valid_774784
  var valid_774785 = query.getOrDefault("Tier.Version")
  valid_774785 = validateParameter(valid_774785, JString, required = false,
                                 default = nil)
  if valid_774785 != nil:
    section.add "Tier.Version", valid_774785
  var valid_774786 = query.getOrDefault("SolutionStackName")
  valid_774786 = validateParameter(valid_774786, JString, required = false,
                                 default = nil)
  if valid_774786 != nil:
    section.add "SolutionStackName", valid_774786
  var valid_774787 = query.getOrDefault("TemplateName")
  valid_774787 = validateParameter(valid_774787, JString, required = false,
                                 default = nil)
  if valid_774787 != nil:
    section.add "TemplateName", valid_774787
  var valid_774788 = query.getOrDefault("GroupName")
  valid_774788 = validateParameter(valid_774788, JString, required = false,
                                 default = nil)
  if valid_774788 != nil:
    section.add "GroupName", valid_774788
  var valid_774789 = query.getOrDefault("OptionSettings")
  valid_774789 = validateParameter(valid_774789, JArray, required = false,
                                 default = nil)
  if valid_774789 != nil:
    section.add "OptionSettings", valid_774789
  var valid_774790 = query.getOrDefault("Tier.Type")
  valid_774790 = validateParameter(valid_774790, JString, required = false,
                                 default = nil)
  if valid_774790 != nil:
    section.add "Tier.Type", valid_774790
  var valid_774791 = query.getOrDefault("Version")
  valid_774791 = validateParameter(valid_774791, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_774791 != nil:
    section.add "Version", valid_774791
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774792 = header.getOrDefault("X-Amz-Date")
  valid_774792 = validateParameter(valid_774792, JString, required = false,
                                 default = nil)
  if valid_774792 != nil:
    section.add "X-Amz-Date", valid_774792
  var valid_774793 = header.getOrDefault("X-Amz-Security-Token")
  valid_774793 = validateParameter(valid_774793, JString, required = false,
                                 default = nil)
  if valid_774793 != nil:
    section.add "X-Amz-Security-Token", valid_774793
  var valid_774794 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774794 = validateParameter(valid_774794, JString, required = false,
                                 default = nil)
  if valid_774794 != nil:
    section.add "X-Amz-Content-Sha256", valid_774794
  var valid_774795 = header.getOrDefault("X-Amz-Algorithm")
  valid_774795 = validateParameter(valid_774795, JString, required = false,
                                 default = nil)
  if valid_774795 != nil:
    section.add "X-Amz-Algorithm", valid_774795
  var valid_774796 = header.getOrDefault("X-Amz-Signature")
  valid_774796 = validateParameter(valid_774796, JString, required = false,
                                 default = nil)
  if valid_774796 != nil:
    section.add "X-Amz-Signature", valid_774796
  var valid_774797 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774797 = validateParameter(valid_774797, JString, required = false,
                                 default = nil)
  if valid_774797 != nil:
    section.add "X-Amz-SignedHeaders", valid_774797
  var valid_774798 = header.getOrDefault("X-Amz-Credential")
  valid_774798 = validateParameter(valid_774798, JString, required = false,
                                 default = nil)
  if valid_774798 != nil:
    section.add "X-Amz-Credential", valid_774798
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774799: Call_GetUpdateEnvironment_774773; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the environment description, deploys a new application version, updates the configuration settings to an entirely new configuration template, or updates select configuration option values in the running environment.</p> <p> Attempting to update both the release and configuration is not allowed and AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. </p> <p> When updating the configuration settings to a new template or individual settings, a draft configuration is created and <a>DescribeConfigurationSettings</a> for this environment returns two setting descriptions with different <code>DeploymentStatus</code> values. </p>
  ## 
  let valid = call_774799.validator(path, query, header, formData, body)
  let scheme = call_774799.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774799.url(scheme.get, call_774799.host, call_774799.base,
                         call_774799.route, valid.getOrDefault("path"))
  result = hook(call_774799, url, valid)

proc call*(call_774800: Call_GetUpdateEnvironment_774773; TierName: string = "";
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
  var query_774801 = newJObject()
  add(query_774801, "Tier.Name", newJString(TierName))
  add(query_774801, "VersionLabel", newJString(VersionLabel))
  add(query_774801, "ApplicationName", newJString(ApplicationName))
  add(query_774801, "Description", newJString(Description))
  if OptionsToRemove != nil:
    query_774801.add "OptionsToRemove", OptionsToRemove
  add(query_774801, "PlatformArn", newJString(PlatformArn))
  add(query_774801, "EnvironmentName", newJString(EnvironmentName))
  add(query_774801, "Action", newJString(Action))
  add(query_774801, "EnvironmentId", newJString(EnvironmentId))
  add(query_774801, "Tier.Version", newJString(TierVersion))
  add(query_774801, "SolutionStackName", newJString(SolutionStackName))
  add(query_774801, "TemplateName", newJString(TemplateName))
  add(query_774801, "GroupName", newJString(GroupName))
  if OptionSettings != nil:
    query_774801.add "OptionSettings", OptionSettings
  add(query_774801, "Tier.Type", newJString(TierType))
  add(query_774801, "Version", newJString(Version))
  result = call_774800.call(nil, query_774801, nil, nil, nil)

var getUpdateEnvironment* = Call_GetUpdateEnvironment_774773(
    name: "getUpdateEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateEnvironment",
    validator: validate_GetUpdateEnvironment_774774, base: "/",
    url: url_GetUpdateEnvironment_774775, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateTagsForResource_774850 = ref object of OpenApiRestCall_772598
proc url_PostUpdateTagsForResource_774852(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostUpdateTagsForResource_774851(path: JsonNode; query: JsonNode;
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
  var valid_774853 = query.getOrDefault("Action")
  valid_774853 = validateParameter(valid_774853, JString, required = true,
                                 default = newJString("UpdateTagsForResource"))
  if valid_774853 != nil:
    section.add "Action", valid_774853
  var valid_774854 = query.getOrDefault("Version")
  valid_774854 = validateParameter(valid_774854, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_774854 != nil:
    section.add "Version", valid_774854
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774855 = header.getOrDefault("X-Amz-Date")
  valid_774855 = validateParameter(valid_774855, JString, required = false,
                                 default = nil)
  if valid_774855 != nil:
    section.add "X-Amz-Date", valid_774855
  var valid_774856 = header.getOrDefault("X-Amz-Security-Token")
  valid_774856 = validateParameter(valid_774856, JString, required = false,
                                 default = nil)
  if valid_774856 != nil:
    section.add "X-Amz-Security-Token", valid_774856
  var valid_774857 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774857 = validateParameter(valid_774857, JString, required = false,
                                 default = nil)
  if valid_774857 != nil:
    section.add "X-Amz-Content-Sha256", valid_774857
  var valid_774858 = header.getOrDefault("X-Amz-Algorithm")
  valid_774858 = validateParameter(valid_774858, JString, required = false,
                                 default = nil)
  if valid_774858 != nil:
    section.add "X-Amz-Algorithm", valid_774858
  var valid_774859 = header.getOrDefault("X-Amz-Signature")
  valid_774859 = validateParameter(valid_774859, JString, required = false,
                                 default = nil)
  if valid_774859 != nil:
    section.add "X-Amz-Signature", valid_774859
  var valid_774860 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774860 = validateParameter(valid_774860, JString, required = false,
                                 default = nil)
  if valid_774860 != nil:
    section.add "X-Amz-SignedHeaders", valid_774860
  var valid_774861 = header.getOrDefault("X-Amz-Credential")
  valid_774861 = validateParameter(valid_774861, JString, required = false,
                                 default = nil)
  if valid_774861 != nil:
    section.add "X-Amz-Credential", valid_774861
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagsToAdd: JArray
  ##            : <p>A list of tags to add or update.</p> <p>If a key of an existing tag is added, the tag's value is updated.</p>
  ##   TagsToRemove: JArray
  ##               : <p>A list of tag keys to remove.</p> <p>If a tag key doesn't exist, it is silently ignored.</p>
  ##   ResourceArn: JString (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce to be updated.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  section = newJObject()
  var valid_774862 = formData.getOrDefault("TagsToAdd")
  valid_774862 = validateParameter(valid_774862, JArray, required = false,
                                 default = nil)
  if valid_774862 != nil:
    section.add "TagsToAdd", valid_774862
  var valid_774863 = formData.getOrDefault("TagsToRemove")
  valid_774863 = validateParameter(valid_774863, JArray, required = false,
                                 default = nil)
  if valid_774863 != nil:
    section.add "TagsToRemove", valid_774863
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArn` field"
  var valid_774864 = formData.getOrDefault("ResourceArn")
  valid_774864 = validateParameter(valid_774864, JString, required = true,
                                 default = nil)
  if valid_774864 != nil:
    section.add "ResourceArn", valid_774864
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774865: Call_PostUpdateTagsForResource_774850; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Update the list of tags applied to an AWS Elastic Beanstalk resource. Two lists can be passed: <code>TagsToAdd</code> for tags to add or update, and <code>TagsToRemove</code>.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p> <p>If you create a custom IAM user policy to control permission to this operation, specify one of the following two virtual actions (or both) instead of the API operation name:</p> <dl> <dt>elasticbeanstalk:AddTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tags to add in the <code>TagsToAdd</code> parameter.</p> </dd> <dt>elasticbeanstalk:RemoveTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tag keys to remove in the <code>TagsToRemove</code> parameter.</p> </dd> </dl> <p>For details about creating a custom user policy, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/AWSHowTo.iam.managed-policies.html#AWSHowTo.iam.policies">Creating a Custom User Policy</a>.</p>
  ## 
  let valid = call_774865.validator(path, query, header, formData, body)
  let scheme = call_774865.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774865.url(scheme.get, call_774865.host, call_774865.base,
                         call_774865.route, valid.getOrDefault("path"))
  result = hook(call_774865, url, valid)

proc call*(call_774866: Call_PostUpdateTagsForResource_774850; ResourceArn: string;
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
  var query_774867 = newJObject()
  var formData_774868 = newJObject()
  if TagsToAdd != nil:
    formData_774868.add "TagsToAdd", TagsToAdd
  if TagsToRemove != nil:
    formData_774868.add "TagsToRemove", TagsToRemove
  add(query_774867, "Action", newJString(Action))
  add(formData_774868, "ResourceArn", newJString(ResourceArn))
  add(query_774867, "Version", newJString(Version))
  result = call_774866.call(nil, query_774867, nil, formData_774868, nil)

var postUpdateTagsForResource* = Call_PostUpdateTagsForResource_774850(
    name: "postUpdateTagsForResource", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateTagsForResource",
    validator: validate_PostUpdateTagsForResource_774851, base: "/",
    url: url_PostUpdateTagsForResource_774852,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateTagsForResource_774832 = ref object of OpenApiRestCall_772598
proc url_GetUpdateTagsForResource_774834(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUpdateTagsForResource_774833(path: JsonNode; query: JsonNode;
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
  var valid_774835 = query.getOrDefault("ResourceArn")
  valid_774835 = validateParameter(valid_774835, JString, required = true,
                                 default = nil)
  if valid_774835 != nil:
    section.add "ResourceArn", valid_774835
  var valid_774836 = query.getOrDefault("Action")
  valid_774836 = validateParameter(valid_774836, JString, required = true,
                                 default = newJString("UpdateTagsForResource"))
  if valid_774836 != nil:
    section.add "Action", valid_774836
  var valid_774837 = query.getOrDefault("TagsToAdd")
  valid_774837 = validateParameter(valid_774837, JArray, required = false,
                                 default = nil)
  if valid_774837 != nil:
    section.add "TagsToAdd", valid_774837
  var valid_774838 = query.getOrDefault("Version")
  valid_774838 = validateParameter(valid_774838, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_774838 != nil:
    section.add "Version", valid_774838
  var valid_774839 = query.getOrDefault("TagsToRemove")
  valid_774839 = validateParameter(valid_774839, JArray, required = false,
                                 default = nil)
  if valid_774839 != nil:
    section.add "TagsToRemove", valid_774839
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774840 = header.getOrDefault("X-Amz-Date")
  valid_774840 = validateParameter(valid_774840, JString, required = false,
                                 default = nil)
  if valid_774840 != nil:
    section.add "X-Amz-Date", valid_774840
  var valid_774841 = header.getOrDefault("X-Amz-Security-Token")
  valid_774841 = validateParameter(valid_774841, JString, required = false,
                                 default = nil)
  if valid_774841 != nil:
    section.add "X-Amz-Security-Token", valid_774841
  var valid_774842 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774842 = validateParameter(valid_774842, JString, required = false,
                                 default = nil)
  if valid_774842 != nil:
    section.add "X-Amz-Content-Sha256", valid_774842
  var valid_774843 = header.getOrDefault("X-Amz-Algorithm")
  valid_774843 = validateParameter(valid_774843, JString, required = false,
                                 default = nil)
  if valid_774843 != nil:
    section.add "X-Amz-Algorithm", valid_774843
  var valid_774844 = header.getOrDefault("X-Amz-Signature")
  valid_774844 = validateParameter(valid_774844, JString, required = false,
                                 default = nil)
  if valid_774844 != nil:
    section.add "X-Amz-Signature", valid_774844
  var valid_774845 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774845 = validateParameter(valid_774845, JString, required = false,
                                 default = nil)
  if valid_774845 != nil:
    section.add "X-Amz-SignedHeaders", valid_774845
  var valid_774846 = header.getOrDefault("X-Amz-Credential")
  valid_774846 = validateParameter(valid_774846, JString, required = false,
                                 default = nil)
  if valid_774846 != nil:
    section.add "X-Amz-Credential", valid_774846
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774847: Call_GetUpdateTagsForResource_774832; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Update the list of tags applied to an AWS Elastic Beanstalk resource. Two lists can be passed: <code>TagsToAdd</code> for tags to add or update, and <code>TagsToRemove</code>.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p> <p>If you create a custom IAM user policy to control permission to this operation, specify one of the following two virtual actions (or both) instead of the API operation name:</p> <dl> <dt>elasticbeanstalk:AddTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tags to add in the <code>TagsToAdd</code> parameter.</p> </dd> <dt>elasticbeanstalk:RemoveTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tag keys to remove in the <code>TagsToRemove</code> parameter.</p> </dd> </dl> <p>For details about creating a custom user policy, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/AWSHowTo.iam.managed-policies.html#AWSHowTo.iam.policies">Creating a Custom User Policy</a>.</p>
  ## 
  let valid = call_774847.validator(path, query, header, formData, body)
  let scheme = call_774847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774847.url(scheme.get, call_774847.host, call_774847.base,
                         call_774847.route, valid.getOrDefault("path"))
  result = hook(call_774847, url, valid)

proc call*(call_774848: Call_GetUpdateTagsForResource_774832; ResourceArn: string;
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
  var query_774849 = newJObject()
  add(query_774849, "ResourceArn", newJString(ResourceArn))
  add(query_774849, "Action", newJString(Action))
  if TagsToAdd != nil:
    query_774849.add "TagsToAdd", TagsToAdd
  add(query_774849, "Version", newJString(Version))
  if TagsToRemove != nil:
    query_774849.add "TagsToRemove", TagsToRemove
  result = call_774848.call(nil, query_774849, nil, nil, nil)

var getUpdateTagsForResource* = Call_GetUpdateTagsForResource_774832(
    name: "getUpdateTagsForResource", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateTagsForResource",
    validator: validate_GetUpdateTagsForResource_774833, base: "/",
    url: url_GetUpdateTagsForResource_774834, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostValidateConfigurationSettings_774888 = ref object of OpenApiRestCall_772598
proc url_PostValidateConfigurationSettings_774890(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostValidateConfigurationSettings_774889(path: JsonNode;
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
  var valid_774891 = query.getOrDefault("Action")
  valid_774891 = validateParameter(valid_774891, JString, required = true, default = newJString(
      "ValidateConfigurationSettings"))
  if valid_774891 != nil:
    section.add "Action", valid_774891
  var valid_774892 = query.getOrDefault("Version")
  valid_774892 = validateParameter(valid_774892, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_774892 != nil:
    section.add "Version", valid_774892
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774893 = header.getOrDefault("X-Amz-Date")
  valid_774893 = validateParameter(valid_774893, JString, required = false,
                                 default = nil)
  if valid_774893 != nil:
    section.add "X-Amz-Date", valid_774893
  var valid_774894 = header.getOrDefault("X-Amz-Security-Token")
  valid_774894 = validateParameter(valid_774894, JString, required = false,
                                 default = nil)
  if valid_774894 != nil:
    section.add "X-Amz-Security-Token", valid_774894
  var valid_774895 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774895 = validateParameter(valid_774895, JString, required = false,
                                 default = nil)
  if valid_774895 != nil:
    section.add "X-Amz-Content-Sha256", valid_774895
  var valid_774896 = header.getOrDefault("X-Amz-Algorithm")
  valid_774896 = validateParameter(valid_774896, JString, required = false,
                                 default = nil)
  if valid_774896 != nil:
    section.add "X-Amz-Algorithm", valid_774896
  var valid_774897 = header.getOrDefault("X-Amz-Signature")
  valid_774897 = validateParameter(valid_774897, JString, required = false,
                                 default = nil)
  if valid_774897 != nil:
    section.add "X-Amz-Signature", valid_774897
  var valid_774898 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774898 = validateParameter(valid_774898, JString, required = false,
                                 default = nil)
  if valid_774898 != nil:
    section.add "X-Amz-SignedHeaders", valid_774898
  var valid_774899 = header.getOrDefault("X-Amz-Credential")
  valid_774899 = validateParameter(valid_774899, JString, required = false,
                                 default = nil)
  if valid_774899 != nil:
    section.add "X-Amz-Credential", valid_774899
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
  var valid_774900 = formData.getOrDefault("OptionSettings")
  valid_774900 = validateParameter(valid_774900, JArray, required = true, default = nil)
  if valid_774900 != nil:
    section.add "OptionSettings", valid_774900
  var valid_774901 = formData.getOrDefault("EnvironmentName")
  valid_774901 = validateParameter(valid_774901, JString, required = false,
                                 default = nil)
  if valid_774901 != nil:
    section.add "EnvironmentName", valid_774901
  var valid_774902 = formData.getOrDefault("ApplicationName")
  valid_774902 = validateParameter(valid_774902, JString, required = true,
                                 default = nil)
  if valid_774902 != nil:
    section.add "ApplicationName", valid_774902
  var valid_774903 = formData.getOrDefault("TemplateName")
  valid_774903 = validateParameter(valid_774903, JString, required = false,
                                 default = nil)
  if valid_774903 != nil:
    section.add "TemplateName", valid_774903
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774904: Call_PostValidateConfigurationSettings_774888;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Takes a set of configuration settings and either a configuration template or environment, and determines whether those values are valid.</p> <p>This action returns a list of messages indicating any errors or warnings associated with the selection of option values.</p>
  ## 
  let valid = call_774904.validator(path, query, header, formData, body)
  let scheme = call_774904.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774904.url(scheme.get, call_774904.host, call_774904.base,
                         call_774904.route, valid.getOrDefault("path"))
  result = hook(call_774904, url, valid)

proc call*(call_774905: Call_PostValidateConfigurationSettings_774888;
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
  var query_774906 = newJObject()
  var formData_774907 = newJObject()
  if OptionSettings != nil:
    formData_774907.add "OptionSettings", OptionSettings
  add(formData_774907, "EnvironmentName", newJString(EnvironmentName))
  add(query_774906, "Action", newJString(Action))
  add(formData_774907, "ApplicationName", newJString(ApplicationName))
  add(formData_774907, "TemplateName", newJString(TemplateName))
  add(query_774906, "Version", newJString(Version))
  result = call_774905.call(nil, query_774906, nil, formData_774907, nil)

var postValidateConfigurationSettings* = Call_PostValidateConfigurationSettings_774888(
    name: "postValidateConfigurationSettings", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ValidateConfigurationSettings",
    validator: validate_PostValidateConfigurationSettings_774889, base: "/",
    url: url_PostValidateConfigurationSettings_774890,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetValidateConfigurationSettings_774869 = ref object of OpenApiRestCall_772598
proc url_GetValidateConfigurationSettings_774871(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetValidateConfigurationSettings_774870(path: JsonNode;
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
  var valid_774872 = query.getOrDefault("ApplicationName")
  valid_774872 = validateParameter(valid_774872, JString, required = true,
                                 default = nil)
  if valid_774872 != nil:
    section.add "ApplicationName", valid_774872
  var valid_774873 = query.getOrDefault("EnvironmentName")
  valid_774873 = validateParameter(valid_774873, JString, required = false,
                                 default = nil)
  if valid_774873 != nil:
    section.add "EnvironmentName", valid_774873
  var valid_774874 = query.getOrDefault("Action")
  valid_774874 = validateParameter(valid_774874, JString, required = true, default = newJString(
      "ValidateConfigurationSettings"))
  if valid_774874 != nil:
    section.add "Action", valid_774874
  var valid_774875 = query.getOrDefault("TemplateName")
  valid_774875 = validateParameter(valid_774875, JString, required = false,
                                 default = nil)
  if valid_774875 != nil:
    section.add "TemplateName", valid_774875
  var valid_774876 = query.getOrDefault("OptionSettings")
  valid_774876 = validateParameter(valid_774876, JArray, required = true, default = nil)
  if valid_774876 != nil:
    section.add "OptionSettings", valid_774876
  var valid_774877 = query.getOrDefault("Version")
  valid_774877 = validateParameter(valid_774877, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_774877 != nil:
    section.add "Version", valid_774877
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_774878 = header.getOrDefault("X-Amz-Date")
  valid_774878 = validateParameter(valid_774878, JString, required = false,
                                 default = nil)
  if valid_774878 != nil:
    section.add "X-Amz-Date", valid_774878
  var valid_774879 = header.getOrDefault("X-Amz-Security-Token")
  valid_774879 = validateParameter(valid_774879, JString, required = false,
                                 default = nil)
  if valid_774879 != nil:
    section.add "X-Amz-Security-Token", valid_774879
  var valid_774880 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_774880 = validateParameter(valid_774880, JString, required = false,
                                 default = nil)
  if valid_774880 != nil:
    section.add "X-Amz-Content-Sha256", valid_774880
  var valid_774881 = header.getOrDefault("X-Amz-Algorithm")
  valid_774881 = validateParameter(valid_774881, JString, required = false,
                                 default = nil)
  if valid_774881 != nil:
    section.add "X-Amz-Algorithm", valid_774881
  var valid_774882 = header.getOrDefault("X-Amz-Signature")
  valid_774882 = validateParameter(valid_774882, JString, required = false,
                                 default = nil)
  if valid_774882 != nil:
    section.add "X-Amz-Signature", valid_774882
  var valid_774883 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_774883 = validateParameter(valid_774883, JString, required = false,
                                 default = nil)
  if valid_774883 != nil:
    section.add "X-Amz-SignedHeaders", valid_774883
  var valid_774884 = header.getOrDefault("X-Amz-Credential")
  valid_774884 = validateParameter(valid_774884, JString, required = false,
                                 default = nil)
  if valid_774884 != nil:
    section.add "X-Amz-Credential", valid_774884
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_774885: Call_GetValidateConfigurationSettings_774869;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Takes a set of configuration settings and either a configuration template or environment, and determines whether those values are valid.</p> <p>This action returns a list of messages indicating any errors or warnings associated with the selection of option values.</p>
  ## 
  let valid = call_774885.validator(path, query, header, formData, body)
  let scheme = call_774885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_774885.url(scheme.get, call_774885.host, call_774885.base,
                         call_774885.route, valid.getOrDefault("path"))
  result = hook(call_774885, url, valid)

proc call*(call_774886: Call_GetValidateConfigurationSettings_774869;
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
  var query_774887 = newJObject()
  add(query_774887, "ApplicationName", newJString(ApplicationName))
  add(query_774887, "EnvironmentName", newJString(EnvironmentName))
  add(query_774887, "Action", newJString(Action))
  add(query_774887, "TemplateName", newJString(TemplateName))
  if OptionSettings != nil:
    query_774887.add "OptionSettings", OptionSettings
  add(query_774887, "Version", newJString(Version))
  result = call_774886.call(nil, query_774887, nil, nil, nil)

var getValidateConfigurationSettings* = Call_GetValidateConfigurationSettings_774869(
    name: "getValidateConfigurationSettings", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ValidateConfigurationSettings",
    validator: validate_GetValidateConfigurationSettings_774870, base: "/",
    url: url_GetValidateConfigurationSettings_774871,
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

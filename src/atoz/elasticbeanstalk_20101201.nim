
import
  json, options, hashes, uri, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_600438 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600438](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600438): Option[Scheme] {.used.} =
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
proc queryString(query: JsonNode): string =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostAbortEnvironmentUpdate_601047 = ref object of OpenApiRestCall_600438
proc url_PostAbortEnvironmentUpdate_601049(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostAbortEnvironmentUpdate_601048(path: JsonNode; query: JsonNode;
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
  var valid_601050 = query.getOrDefault("Action")
  valid_601050 = validateParameter(valid_601050, JString, required = true,
                                 default = newJString("AbortEnvironmentUpdate"))
  if valid_601050 != nil:
    section.add "Action", valid_601050
  var valid_601051 = query.getOrDefault("Version")
  valid_601051 = validateParameter(valid_601051, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601051 != nil:
    section.add "Version", valid_601051
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601052 = header.getOrDefault("X-Amz-Date")
  valid_601052 = validateParameter(valid_601052, JString, required = false,
                                 default = nil)
  if valid_601052 != nil:
    section.add "X-Amz-Date", valid_601052
  var valid_601053 = header.getOrDefault("X-Amz-Security-Token")
  valid_601053 = validateParameter(valid_601053, JString, required = false,
                                 default = nil)
  if valid_601053 != nil:
    section.add "X-Amz-Security-Token", valid_601053
  var valid_601054 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601054 = validateParameter(valid_601054, JString, required = false,
                                 default = nil)
  if valid_601054 != nil:
    section.add "X-Amz-Content-Sha256", valid_601054
  var valid_601055 = header.getOrDefault("X-Amz-Algorithm")
  valid_601055 = validateParameter(valid_601055, JString, required = false,
                                 default = nil)
  if valid_601055 != nil:
    section.add "X-Amz-Algorithm", valid_601055
  var valid_601056 = header.getOrDefault("X-Amz-Signature")
  valid_601056 = validateParameter(valid_601056, JString, required = false,
                                 default = nil)
  if valid_601056 != nil:
    section.add "X-Amz-Signature", valid_601056
  var valid_601057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601057 = validateParameter(valid_601057, JString, required = false,
                                 default = nil)
  if valid_601057 != nil:
    section.add "X-Amz-SignedHeaders", valid_601057
  var valid_601058 = header.getOrDefault("X-Amz-Credential")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "X-Amz-Credential", valid_601058
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentId: JString
  ##                : This specifies the ID of the environment with the in-progress update that you want to cancel.
  ##   EnvironmentName: JString
  ##                  : This specifies the name of the environment with the in-progress update that you want to cancel.
  section = newJObject()
  var valid_601059 = formData.getOrDefault("EnvironmentId")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "EnvironmentId", valid_601059
  var valid_601060 = formData.getOrDefault("EnvironmentName")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "EnvironmentName", valid_601060
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601061: Call_PostAbortEnvironmentUpdate_601047; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels in-progress environment configuration update or application version deployment.
  ## 
  let valid = call_601061.validator(path, query, header, formData, body)
  let scheme = call_601061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601061.url(scheme.get, call_601061.host, call_601061.base,
                         call_601061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601061, url, valid)

proc call*(call_601062: Call_PostAbortEnvironmentUpdate_601047;
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
  var query_601063 = newJObject()
  var formData_601064 = newJObject()
  add(formData_601064, "EnvironmentId", newJString(EnvironmentId))
  add(formData_601064, "EnvironmentName", newJString(EnvironmentName))
  add(query_601063, "Action", newJString(Action))
  add(query_601063, "Version", newJString(Version))
  result = call_601062.call(nil, query_601063, nil, formData_601064, nil)

var postAbortEnvironmentUpdate* = Call_PostAbortEnvironmentUpdate_601047(
    name: "postAbortEnvironmentUpdate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=AbortEnvironmentUpdate",
    validator: validate_PostAbortEnvironmentUpdate_601048, base: "/",
    url: url_PostAbortEnvironmentUpdate_601049,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAbortEnvironmentUpdate_600775 = ref object of OpenApiRestCall_600438
proc url_GetAbortEnvironmentUpdate_600777(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAbortEnvironmentUpdate_600776(path: JsonNode; query: JsonNode;
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
  var valid_600889 = query.getOrDefault("EnvironmentName")
  valid_600889 = validateParameter(valid_600889, JString, required = false,
                                 default = nil)
  if valid_600889 != nil:
    section.add "EnvironmentName", valid_600889
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600903 = query.getOrDefault("Action")
  valid_600903 = validateParameter(valid_600903, JString, required = true,
                                 default = newJString("AbortEnvironmentUpdate"))
  if valid_600903 != nil:
    section.add "Action", valid_600903
  var valid_600904 = query.getOrDefault("EnvironmentId")
  valid_600904 = validateParameter(valid_600904, JString, required = false,
                                 default = nil)
  if valid_600904 != nil:
    section.add "EnvironmentId", valid_600904
  var valid_600905 = query.getOrDefault("Version")
  valid_600905 = validateParameter(valid_600905, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600905 != nil:
    section.add "Version", valid_600905
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600906 = header.getOrDefault("X-Amz-Date")
  valid_600906 = validateParameter(valid_600906, JString, required = false,
                                 default = nil)
  if valid_600906 != nil:
    section.add "X-Amz-Date", valid_600906
  var valid_600907 = header.getOrDefault("X-Amz-Security-Token")
  valid_600907 = validateParameter(valid_600907, JString, required = false,
                                 default = nil)
  if valid_600907 != nil:
    section.add "X-Amz-Security-Token", valid_600907
  var valid_600908 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600908 = validateParameter(valid_600908, JString, required = false,
                                 default = nil)
  if valid_600908 != nil:
    section.add "X-Amz-Content-Sha256", valid_600908
  var valid_600909 = header.getOrDefault("X-Amz-Algorithm")
  valid_600909 = validateParameter(valid_600909, JString, required = false,
                                 default = nil)
  if valid_600909 != nil:
    section.add "X-Amz-Algorithm", valid_600909
  var valid_600910 = header.getOrDefault("X-Amz-Signature")
  valid_600910 = validateParameter(valid_600910, JString, required = false,
                                 default = nil)
  if valid_600910 != nil:
    section.add "X-Amz-Signature", valid_600910
  var valid_600911 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600911 = validateParameter(valid_600911, JString, required = false,
                                 default = nil)
  if valid_600911 != nil:
    section.add "X-Amz-SignedHeaders", valid_600911
  var valid_600912 = header.getOrDefault("X-Amz-Credential")
  valid_600912 = validateParameter(valid_600912, JString, required = false,
                                 default = nil)
  if valid_600912 != nil:
    section.add "X-Amz-Credential", valid_600912
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600935: Call_GetAbortEnvironmentUpdate_600775; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels in-progress environment configuration update or application version deployment.
  ## 
  let valid = call_600935.validator(path, query, header, formData, body)
  let scheme = call_600935.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600935.url(scheme.get, call_600935.host, call_600935.base,
                         call_600935.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_600935, url, valid)

proc call*(call_601006: Call_GetAbortEnvironmentUpdate_600775;
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
  var query_601007 = newJObject()
  add(query_601007, "EnvironmentName", newJString(EnvironmentName))
  add(query_601007, "Action", newJString(Action))
  add(query_601007, "EnvironmentId", newJString(EnvironmentId))
  add(query_601007, "Version", newJString(Version))
  result = call_601006.call(nil, query_601007, nil, nil, nil)

var getAbortEnvironmentUpdate* = Call_GetAbortEnvironmentUpdate_600775(
    name: "getAbortEnvironmentUpdate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=AbortEnvironmentUpdate",
    validator: validate_GetAbortEnvironmentUpdate_600776, base: "/",
    url: url_GetAbortEnvironmentUpdate_600777,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostApplyEnvironmentManagedAction_601083 = ref object of OpenApiRestCall_600438
proc url_PostApplyEnvironmentManagedAction_601085(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostApplyEnvironmentManagedAction_601084(path: JsonNode;
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
  var valid_601086 = query.getOrDefault("Action")
  valid_601086 = validateParameter(valid_601086, JString, required = true, default = newJString(
      "ApplyEnvironmentManagedAction"))
  if valid_601086 != nil:
    section.add "Action", valid_601086
  var valid_601087 = query.getOrDefault("Version")
  valid_601087 = validateParameter(valid_601087, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601087 != nil:
    section.add "Version", valid_601087
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601088 = header.getOrDefault("X-Amz-Date")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "X-Amz-Date", valid_601088
  var valid_601089 = header.getOrDefault("X-Amz-Security-Token")
  valid_601089 = validateParameter(valid_601089, JString, required = false,
                                 default = nil)
  if valid_601089 != nil:
    section.add "X-Amz-Security-Token", valid_601089
  var valid_601090 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "X-Amz-Content-Sha256", valid_601090
  var valid_601091 = header.getOrDefault("X-Amz-Algorithm")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-Algorithm", valid_601091
  var valid_601092 = header.getOrDefault("X-Amz-Signature")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "X-Amz-Signature", valid_601092
  var valid_601093 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601093 = validateParameter(valid_601093, JString, required = false,
                                 default = nil)
  if valid_601093 != nil:
    section.add "X-Amz-SignedHeaders", valid_601093
  var valid_601094 = header.getOrDefault("X-Amz-Credential")
  valid_601094 = validateParameter(valid_601094, JString, required = false,
                                 default = nil)
  if valid_601094 != nil:
    section.add "X-Amz-Credential", valid_601094
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentId: JString
  ##                : The environment ID of the target environment.
  ##   EnvironmentName: JString
  ##                  : The name of the target environment.
  ##   ActionId: JString (required)
  ##           : The action ID of the scheduled managed action to execute.
  section = newJObject()
  var valid_601095 = formData.getOrDefault("EnvironmentId")
  valid_601095 = validateParameter(valid_601095, JString, required = false,
                                 default = nil)
  if valid_601095 != nil:
    section.add "EnvironmentId", valid_601095
  var valid_601096 = formData.getOrDefault("EnvironmentName")
  valid_601096 = validateParameter(valid_601096, JString, required = false,
                                 default = nil)
  if valid_601096 != nil:
    section.add "EnvironmentName", valid_601096
  assert formData != nil,
        "formData argument is necessary due to required `ActionId` field"
  var valid_601097 = formData.getOrDefault("ActionId")
  valid_601097 = validateParameter(valid_601097, JString, required = true,
                                 default = nil)
  if valid_601097 != nil:
    section.add "ActionId", valid_601097
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601098: Call_PostApplyEnvironmentManagedAction_601083;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Applies a scheduled managed action immediately. A managed action can be applied only if its status is <code>Scheduled</code>. Get the status and action ID of a managed action with <a>DescribeEnvironmentManagedActions</a>.
  ## 
  let valid = call_601098.validator(path, query, header, formData, body)
  let scheme = call_601098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601098.url(scheme.get, call_601098.host, call_601098.base,
                         call_601098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601098, url, valid)

proc call*(call_601099: Call_PostApplyEnvironmentManagedAction_601083;
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
  var query_601100 = newJObject()
  var formData_601101 = newJObject()
  add(formData_601101, "EnvironmentId", newJString(EnvironmentId))
  add(formData_601101, "EnvironmentName", newJString(EnvironmentName))
  add(query_601100, "Action", newJString(Action))
  add(formData_601101, "ActionId", newJString(ActionId))
  add(query_601100, "Version", newJString(Version))
  result = call_601099.call(nil, query_601100, nil, formData_601101, nil)

var postApplyEnvironmentManagedAction* = Call_PostApplyEnvironmentManagedAction_601083(
    name: "postApplyEnvironmentManagedAction", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ApplyEnvironmentManagedAction",
    validator: validate_PostApplyEnvironmentManagedAction_601084, base: "/",
    url: url_PostApplyEnvironmentManagedAction_601085,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplyEnvironmentManagedAction_601065 = ref object of OpenApiRestCall_600438
proc url_GetApplyEnvironmentManagedAction_601067(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetApplyEnvironmentManagedAction_601066(path: JsonNode;
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
  var valid_601068 = query.getOrDefault("EnvironmentName")
  valid_601068 = validateParameter(valid_601068, JString, required = false,
                                 default = nil)
  if valid_601068 != nil:
    section.add "EnvironmentName", valid_601068
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601069 = query.getOrDefault("Action")
  valid_601069 = validateParameter(valid_601069, JString, required = true, default = newJString(
      "ApplyEnvironmentManagedAction"))
  if valid_601069 != nil:
    section.add "Action", valid_601069
  var valid_601070 = query.getOrDefault("EnvironmentId")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "EnvironmentId", valid_601070
  var valid_601071 = query.getOrDefault("ActionId")
  valid_601071 = validateParameter(valid_601071, JString, required = true,
                                 default = nil)
  if valid_601071 != nil:
    section.add "ActionId", valid_601071
  var valid_601072 = query.getOrDefault("Version")
  valid_601072 = validateParameter(valid_601072, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601072 != nil:
    section.add "Version", valid_601072
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601073 = header.getOrDefault("X-Amz-Date")
  valid_601073 = validateParameter(valid_601073, JString, required = false,
                                 default = nil)
  if valid_601073 != nil:
    section.add "X-Amz-Date", valid_601073
  var valid_601074 = header.getOrDefault("X-Amz-Security-Token")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "X-Amz-Security-Token", valid_601074
  var valid_601075 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601075 = validateParameter(valid_601075, JString, required = false,
                                 default = nil)
  if valid_601075 != nil:
    section.add "X-Amz-Content-Sha256", valid_601075
  var valid_601076 = header.getOrDefault("X-Amz-Algorithm")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "X-Amz-Algorithm", valid_601076
  var valid_601077 = header.getOrDefault("X-Amz-Signature")
  valid_601077 = validateParameter(valid_601077, JString, required = false,
                                 default = nil)
  if valid_601077 != nil:
    section.add "X-Amz-Signature", valid_601077
  var valid_601078 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601078 = validateParameter(valid_601078, JString, required = false,
                                 default = nil)
  if valid_601078 != nil:
    section.add "X-Amz-SignedHeaders", valid_601078
  var valid_601079 = header.getOrDefault("X-Amz-Credential")
  valid_601079 = validateParameter(valid_601079, JString, required = false,
                                 default = nil)
  if valid_601079 != nil:
    section.add "X-Amz-Credential", valid_601079
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601080: Call_GetApplyEnvironmentManagedAction_601065;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Applies a scheduled managed action immediately. A managed action can be applied only if its status is <code>Scheduled</code>. Get the status and action ID of a managed action with <a>DescribeEnvironmentManagedActions</a>.
  ## 
  let valid = call_601080.validator(path, query, header, formData, body)
  let scheme = call_601080.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601080.url(scheme.get, call_601080.host, call_601080.base,
                         call_601080.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601080, url, valid)

proc call*(call_601081: Call_GetApplyEnvironmentManagedAction_601065;
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
  var query_601082 = newJObject()
  add(query_601082, "EnvironmentName", newJString(EnvironmentName))
  add(query_601082, "Action", newJString(Action))
  add(query_601082, "EnvironmentId", newJString(EnvironmentId))
  add(query_601082, "ActionId", newJString(ActionId))
  add(query_601082, "Version", newJString(Version))
  result = call_601081.call(nil, query_601082, nil, nil, nil)

var getApplyEnvironmentManagedAction* = Call_GetApplyEnvironmentManagedAction_601065(
    name: "getApplyEnvironmentManagedAction", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ApplyEnvironmentManagedAction",
    validator: validate_GetApplyEnvironmentManagedAction_601066, base: "/",
    url: url_GetApplyEnvironmentManagedAction_601067,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCheckDNSAvailability_601118 = ref object of OpenApiRestCall_600438
proc url_PostCheckDNSAvailability_601120(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCheckDNSAvailability_601119(path: JsonNode; query: JsonNode;
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
  var valid_601121 = query.getOrDefault("Action")
  valid_601121 = validateParameter(valid_601121, JString, required = true,
                                 default = newJString("CheckDNSAvailability"))
  if valid_601121 != nil:
    section.add "Action", valid_601121
  var valid_601122 = query.getOrDefault("Version")
  valid_601122 = validateParameter(valid_601122, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601122 != nil:
    section.add "Version", valid_601122
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601123 = header.getOrDefault("X-Amz-Date")
  valid_601123 = validateParameter(valid_601123, JString, required = false,
                                 default = nil)
  if valid_601123 != nil:
    section.add "X-Amz-Date", valid_601123
  var valid_601124 = header.getOrDefault("X-Amz-Security-Token")
  valid_601124 = validateParameter(valid_601124, JString, required = false,
                                 default = nil)
  if valid_601124 != nil:
    section.add "X-Amz-Security-Token", valid_601124
  var valid_601125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601125 = validateParameter(valid_601125, JString, required = false,
                                 default = nil)
  if valid_601125 != nil:
    section.add "X-Amz-Content-Sha256", valid_601125
  var valid_601126 = header.getOrDefault("X-Amz-Algorithm")
  valid_601126 = validateParameter(valid_601126, JString, required = false,
                                 default = nil)
  if valid_601126 != nil:
    section.add "X-Amz-Algorithm", valid_601126
  var valid_601127 = header.getOrDefault("X-Amz-Signature")
  valid_601127 = validateParameter(valid_601127, JString, required = false,
                                 default = nil)
  if valid_601127 != nil:
    section.add "X-Amz-Signature", valid_601127
  var valid_601128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601128 = validateParameter(valid_601128, JString, required = false,
                                 default = nil)
  if valid_601128 != nil:
    section.add "X-Amz-SignedHeaders", valid_601128
  var valid_601129 = header.getOrDefault("X-Amz-Credential")
  valid_601129 = validateParameter(valid_601129, JString, required = false,
                                 default = nil)
  if valid_601129 != nil:
    section.add "X-Amz-Credential", valid_601129
  result.add "header", section
  ## parameters in `formData` object:
  ##   CNAMEPrefix: JString (required)
  ##              : The prefix used when this CNAME is reserved.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `CNAMEPrefix` field"
  var valid_601130 = formData.getOrDefault("CNAMEPrefix")
  valid_601130 = validateParameter(valid_601130, JString, required = true,
                                 default = nil)
  if valid_601130 != nil:
    section.add "CNAMEPrefix", valid_601130
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601131: Call_PostCheckDNSAvailability_601118; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Checks if the specified CNAME is available.
  ## 
  let valid = call_601131.validator(path, query, header, formData, body)
  let scheme = call_601131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601131.url(scheme.get, call_601131.host, call_601131.base,
                         call_601131.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601131, url, valid)

proc call*(call_601132: Call_PostCheckDNSAvailability_601118; CNAMEPrefix: string;
          Action: string = "CheckDNSAvailability"; Version: string = "2010-12-01"): Recallable =
  ## postCheckDNSAvailability
  ## Checks if the specified CNAME is available.
  ##   CNAMEPrefix: string (required)
  ##              : The prefix used when this CNAME is reserved.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601133 = newJObject()
  var formData_601134 = newJObject()
  add(formData_601134, "CNAMEPrefix", newJString(CNAMEPrefix))
  add(query_601133, "Action", newJString(Action))
  add(query_601133, "Version", newJString(Version))
  result = call_601132.call(nil, query_601133, nil, formData_601134, nil)

var postCheckDNSAvailability* = Call_PostCheckDNSAvailability_601118(
    name: "postCheckDNSAvailability", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CheckDNSAvailability",
    validator: validate_PostCheckDNSAvailability_601119, base: "/",
    url: url_PostCheckDNSAvailability_601120, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCheckDNSAvailability_601102 = ref object of OpenApiRestCall_600438
proc url_GetCheckDNSAvailability_601104(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCheckDNSAvailability_601103(path: JsonNode; query: JsonNode;
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
  var valid_601105 = query.getOrDefault("Action")
  valid_601105 = validateParameter(valid_601105, JString, required = true,
                                 default = newJString("CheckDNSAvailability"))
  if valid_601105 != nil:
    section.add "Action", valid_601105
  var valid_601106 = query.getOrDefault("Version")
  valid_601106 = validateParameter(valid_601106, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601106 != nil:
    section.add "Version", valid_601106
  var valid_601107 = query.getOrDefault("CNAMEPrefix")
  valid_601107 = validateParameter(valid_601107, JString, required = true,
                                 default = nil)
  if valid_601107 != nil:
    section.add "CNAMEPrefix", valid_601107
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601108 = header.getOrDefault("X-Amz-Date")
  valid_601108 = validateParameter(valid_601108, JString, required = false,
                                 default = nil)
  if valid_601108 != nil:
    section.add "X-Amz-Date", valid_601108
  var valid_601109 = header.getOrDefault("X-Amz-Security-Token")
  valid_601109 = validateParameter(valid_601109, JString, required = false,
                                 default = nil)
  if valid_601109 != nil:
    section.add "X-Amz-Security-Token", valid_601109
  var valid_601110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601110 = validateParameter(valid_601110, JString, required = false,
                                 default = nil)
  if valid_601110 != nil:
    section.add "X-Amz-Content-Sha256", valid_601110
  var valid_601111 = header.getOrDefault("X-Amz-Algorithm")
  valid_601111 = validateParameter(valid_601111, JString, required = false,
                                 default = nil)
  if valid_601111 != nil:
    section.add "X-Amz-Algorithm", valid_601111
  var valid_601112 = header.getOrDefault("X-Amz-Signature")
  valid_601112 = validateParameter(valid_601112, JString, required = false,
                                 default = nil)
  if valid_601112 != nil:
    section.add "X-Amz-Signature", valid_601112
  var valid_601113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601113 = validateParameter(valid_601113, JString, required = false,
                                 default = nil)
  if valid_601113 != nil:
    section.add "X-Amz-SignedHeaders", valid_601113
  var valid_601114 = header.getOrDefault("X-Amz-Credential")
  valid_601114 = validateParameter(valid_601114, JString, required = false,
                                 default = nil)
  if valid_601114 != nil:
    section.add "X-Amz-Credential", valid_601114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601115: Call_GetCheckDNSAvailability_601102; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Checks if the specified CNAME is available.
  ## 
  let valid = call_601115.validator(path, query, header, formData, body)
  let scheme = call_601115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601115.url(scheme.get, call_601115.host, call_601115.base,
                         call_601115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601115, url, valid)

proc call*(call_601116: Call_GetCheckDNSAvailability_601102; CNAMEPrefix: string;
          Action: string = "CheckDNSAvailability"; Version: string = "2010-12-01"): Recallable =
  ## getCheckDNSAvailability
  ## Checks if the specified CNAME is available.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   CNAMEPrefix: string (required)
  ##              : The prefix used when this CNAME is reserved.
  var query_601117 = newJObject()
  add(query_601117, "Action", newJString(Action))
  add(query_601117, "Version", newJString(Version))
  add(query_601117, "CNAMEPrefix", newJString(CNAMEPrefix))
  result = call_601116.call(nil, query_601117, nil, nil, nil)

var getCheckDNSAvailability* = Call_GetCheckDNSAvailability_601102(
    name: "getCheckDNSAvailability", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CheckDNSAvailability",
    validator: validate_GetCheckDNSAvailability_601103, base: "/",
    url: url_GetCheckDNSAvailability_601104, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostComposeEnvironments_601153 = ref object of OpenApiRestCall_600438
proc url_PostComposeEnvironments_601155(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostComposeEnvironments_601154(path: JsonNode; query: JsonNode;
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
  var valid_601156 = query.getOrDefault("Action")
  valid_601156 = validateParameter(valid_601156, JString, required = true,
                                 default = newJString("ComposeEnvironments"))
  if valid_601156 != nil:
    section.add "Action", valid_601156
  var valid_601157 = query.getOrDefault("Version")
  valid_601157 = validateParameter(valid_601157, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601157 != nil:
    section.add "Version", valid_601157
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601158 = header.getOrDefault("X-Amz-Date")
  valid_601158 = validateParameter(valid_601158, JString, required = false,
                                 default = nil)
  if valid_601158 != nil:
    section.add "X-Amz-Date", valid_601158
  var valid_601159 = header.getOrDefault("X-Amz-Security-Token")
  valid_601159 = validateParameter(valid_601159, JString, required = false,
                                 default = nil)
  if valid_601159 != nil:
    section.add "X-Amz-Security-Token", valid_601159
  var valid_601160 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601160 = validateParameter(valid_601160, JString, required = false,
                                 default = nil)
  if valid_601160 != nil:
    section.add "X-Amz-Content-Sha256", valid_601160
  var valid_601161 = header.getOrDefault("X-Amz-Algorithm")
  valid_601161 = validateParameter(valid_601161, JString, required = false,
                                 default = nil)
  if valid_601161 != nil:
    section.add "X-Amz-Algorithm", valid_601161
  var valid_601162 = header.getOrDefault("X-Amz-Signature")
  valid_601162 = validateParameter(valid_601162, JString, required = false,
                                 default = nil)
  if valid_601162 != nil:
    section.add "X-Amz-Signature", valid_601162
  var valid_601163 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601163 = validateParameter(valid_601163, JString, required = false,
                                 default = nil)
  if valid_601163 != nil:
    section.add "X-Amz-SignedHeaders", valid_601163
  var valid_601164 = header.getOrDefault("X-Amz-Credential")
  valid_601164 = validateParameter(valid_601164, JString, required = false,
                                 default = nil)
  if valid_601164 != nil:
    section.add "X-Amz-Credential", valid_601164
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
  var valid_601165 = formData.getOrDefault("GroupName")
  valid_601165 = validateParameter(valid_601165, JString, required = false,
                                 default = nil)
  if valid_601165 != nil:
    section.add "GroupName", valid_601165
  var valid_601166 = formData.getOrDefault("ApplicationName")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "ApplicationName", valid_601166
  var valid_601167 = formData.getOrDefault("VersionLabels")
  valid_601167 = validateParameter(valid_601167, JArray, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "VersionLabels", valid_601167
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601168: Call_PostComposeEnvironments_601153; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create or update a group of environments that each run a separate component of a single application. Takes a list of version labels that specify application source bundles for each of the environments to create or update. The name of each environment and other required information must be included in the source bundles in an environment manifest named <code>env.yaml</code>. See <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-mgmt-compose.html">Compose Environments</a> for details.
  ## 
  let valid = call_601168.validator(path, query, header, formData, body)
  let scheme = call_601168.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601168.url(scheme.get, call_601168.host, call_601168.base,
                         call_601168.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601168, url, valid)

proc call*(call_601169: Call_PostComposeEnvironments_601153;
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
  var query_601170 = newJObject()
  var formData_601171 = newJObject()
  add(formData_601171, "GroupName", newJString(GroupName))
  add(query_601170, "Action", newJString(Action))
  add(formData_601171, "ApplicationName", newJString(ApplicationName))
  add(query_601170, "Version", newJString(Version))
  if VersionLabels != nil:
    formData_601171.add "VersionLabels", VersionLabels
  result = call_601169.call(nil, query_601170, nil, formData_601171, nil)

var postComposeEnvironments* = Call_PostComposeEnvironments_601153(
    name: "postComposeEnvironments", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ComposeEnvironments",
    validator: validate_PostComposeEnvironments_601154, base: "/",
    url: url_PostComposeEnvironments_601155, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetComposeEnvironments_601135 = ref object of OpenApiRestCall_600438
proc url_GetComposeEnvironments_601137(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetComposeEnvironments_601136(path: JsonNode; query: JsonNode;
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
  var valid_601138 = query.getOrDefault("ApplicationName")
  valid_601138 = validateParameter(valid_601138, JString, required = false,
                                 default = nil)
  if valid_601138 != nil:
    section.add "ApplicationName", valid_601138
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601139 = query.getOrDefault("Action")
  valid_601139 = validateParameter(valid_601139, JString, required = true,
                                 default = newJString("ComposeEnvironments"))
  if valid_601139 != nil:
    section.add "Action", valid_601139
  var valid_601140 = query.getOrDefault("GroupName")
  valid_601140 = validateParameter(valid_601140, JString, required = false,
                                 default = nil)
  if valid_601140 != nil:
    section.add "GroupName", valid_601140
  var valid_601141 = query.getOrDefault("VersionLabels")
  valid_601141 = validateParameter(valid_601141, JArray, required = false,
                                 default = nil)
  if valid_601141 != nil:
    section.add "VersionLabels", valid_601141
  var valid_601142 = query.getOrDefault("Version")
  valid_601142 = validateParameter(valid_601142, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601142 != nil:
    section.add "Version", valid_601142
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601143 = header.getOrDefault("X-Amz-Date")
  valid_601143 = validateParameter(valid_601143, JString, required = false,
                                 default = nil)
  if valid_601143 != nil:
    section.add "X-Amz-Date", valid_601143
  var valid_601144 = header.getOrDefault("X-Amz-Security-Token")
  valid_601144 = validateParameter(valid_601144, JString, required = false,
                                 default = nil)
  if valid_601144 != nil:
    section.add "X-Amz-Security-Token", valid_601144
  var valid_601145 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601145 = validateParameter(valid_601145, JString, required = false,
                                 default = nil)
  if valid_601145 != nil:
    section.add "X-Amz-Content-Sha256", valid_601145
  var valid_601146 = header.getOrDefault("X-Amz-Algorithm")
  valid_601146 = validateParameter(valid_601146, JString, required = false,
                                 default = nil)
  if valid_601146 != nil:
    section.add "X-Amz-Algorithm", valid_601146
  var valid_601147 = header.getOrDefault("X-Amz-Signature")
  valid_601147 = validateParameter(valid_601147, JString, required = false,
                                 default = nil)
  if valid_601147 != nil:
    section.add "X-Amz-Signature", valid_601147
  var valid_601148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601148 = validateParameter(valid_601148, JString, required = false,
                                 default = nil)
  if valid_601148 != nil:
    section.add "X-Amz-SignedHeaders", valid_601148
  var valid_601149 = header.getOrDefault("X-Amz-Credential")
  valid_601149 = validateParameter(valid_601149, JString, required = false,
                                 default = nil)
  if valid_601149 != nil:
    section.add "X-Amz-Credential", valid_601149
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601150: Call_GetComposeEnvironments_601135; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create or update a group of environments that each run a separate component of a single application. Takes a list of version labels that specify application source bundles for each of the environments to create or update. The name of each environment and other required information must be included in the source bundles in an environment manifest named <code>env.yaml</code>. See <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-mgmt-compose.html">Compose Environments</a> for details.
  ## 
  let valid = call_601150.validator(path, query, header, formData, body)
  let scheme = call_601150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601150.url(scheme.get, call_601150.host, call_601150.base,
                         call_601150.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601150, url, valid)

proc call*(call_601151: Call_GetComposeEnvironments_601135;
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
  var query_601152 = newJObject()
  add(query_601152, "ApplicationName", newJString(ApplicationName))
  add(query_601152, "Action", newJString(Action))
  add(query_601152, "GroupName", newJString(GroupName))
  if VersionLabels != nil:
    query_601152.add "VersionLabels", VersionLabels
  add(query_601152, "Version", newJString(Version))
  result = call_601151.call(nil, query_601152, nil, nil, nil)

var getComposeEnvironments* = Call_GetComposeEnvironments_601135(
    name: "getComposeEnvironments", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ComposeEnvironments",
    validator: validate_GetComposeEnvironments_601136, base: "/",
    url: url_GetComposeEnvironments_601137, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateApplication_601192 = ref object of OpenApiRestCall_600438
proc url_PostCreateApplication_601194(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateApplication_601193(path: JsonNode; query: JsonNode;
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
  var valid_601195 = query.getOrDefault("Action")
  valid_601195 = validateParameter(valid_601195, JString, required = true,
                                 default = newJString("CreateApplication"))
  if valid_601195 != nil:
    section.add "Action", valid_601195
  var valid_601196 = query.getOrDefault("Version")
  valid_601196 = validateParameter(valid_601196, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601196 != nil:
    section.add "Version", valid_601196
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601197 = header.getOrDefault("X-Amz-Date")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "X-Amz-Date", valid_601197
  var valid_601198 = header.getOrDefault("X-Amz-Security-Token")
  valid_601198 = validateParameter(valid_601198, JString, required = false,
                                 default = nil)
  if valid_601198 != nil:
    section.add "X-Amz-Security-Token", valid_601198
  var valid_601199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601199 = validateParameter(valid_601199, JString, required = false,
                                 default = nil)
  if valid_601199 != nil:
    section.add "X-Amz-Content-Sha256", valid_601199
  var valid_601200 = header.getOrDefault("X-Amz-Algorithm")
  valid_601200 = validateParameter(valid_601200, JString, required = false,
                                 default = nil)
  if valid_601200 != nil:
    section.add "X-Amz-Algorithm", valid_601200
  var valid_601201 = header.getOrDefault("X-Amz-Signature")
  valid_601201 = validateParameter(valid_601201, JString, required = false,
                                 default = nil)
  if valid_601201 != nil:
    section.add "X-Amz-Signature", valid_601201
  var valid_601202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601202 = validateParameter(valid_601202, JString, required = false,
                                 default = nil)
  if valid_601202 != nil:
    section.add "X-Amz-SignedHeaders", valid_601202
  var valid_601203 = header.getOrDefault("X-Amz-Credential")
  valid_601203 = validateParameter(valid_601203, JString, required = false,
                                 default = nil)
  if valid_601203 != nil:
    section.add "X-Amz-Credential", valid_601203
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
  var valid_601204 = formData.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_601204 = validateParameter(valid_601204, JString, required = false,
                                 default = nil)
  if valid_601204 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_601204
  var valid_601205 = formData.getOrDefault("Tags")
  valid_601205 = validateParameter(valid_601205, JArray, required = false,
                                 default = nil)
  if valid_601205 != nil:
    section.add "Tags", valid_601205
  var valid_601206 = formData.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_601206 = validateParameter(valid_601206, JString, required = false,
                                 default = nil)
  if valid_601206 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_601206
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_601207 = formData.getOrDefault("ApplicationName")
  valid_601207 = validateParameter(valid_601207, JString, required = true,
                                 default = nil)
  if valid_601207 != nil:
    section.add "ApplicationName", valid_601207
  var valid_601208 = formData.getOrDefault("Description")
  valid_601208 = validateParameter(valid_601208, JString, required = false,
                                 default = nil)
  if valid_601208 != nil:
    section.add "Description", valid_601208
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601209: Call_PostCreateApplication_601192; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates an application that has one configuration template named <code>default</code> and no application versions. 
  ## 
  let valid = call_601209.validator(path, query, header, formData, body)
  let scheme = call_601209.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601209.url(scheme.get, call_601209.host, call_601209.base,
                         call_601209.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601209, url, valid)

proc call*(call_601210: Call_PostCreateApplication_601192; ApplicationName: string;
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
  var query_601211 = newJObject()
  var formData_601212 = newJObject()
  add(formData_601212, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  if Tags != nil:
    formData_601212.add "Tags", Tags
  add(formData_601212, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  add(query_601211, "Action", newJString(Action))
  add(formData_601212, "ApplicationName", newJString(ApplicationName))
  add(query_601211, "Version", newJString(Version))
  add(formData_601212, "Description", newJString(Description))
  result = call_601210.call(nil, query_601211, nil, formData_601212, nil)

var postCreateApplication* = Call_PostCreateApplication_601192(
    name: "postCreateApplication", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateApplication",
    validator: validate_PostCreateApplication_601193, base: "/",
    url: url_PostCreateApplication_601194, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateApplication_601172 = ref object of OpenApiRestCall_600438
proc url_GetCreateApplication_601174(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateApplication_601173(path: JsonNode; query: JsonNode;
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
  var valid_601175 = query.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_601175 = validateParameter(valid_601175, JString, required = false,
                                 default = nil)
  if valid_601175 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_601175
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_601176 = query.getOrDefault("ApplicationName")
  valid_601176 = validateParameter(valid_601176, JString, required = true,
                                 default = nil)
  if valid_601176 != nil:
    section.add "ApplicationName", valid_601176
  var valid_601177 = query.getOrDefault("Description")
  valid_601177 = validateParameter(valid_601177, JString, required = false,
                                 default = nil)
  if valid_601177 != nil:
    section.add "Description", valid_601177
  var valid_601178 = query.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_601178 = validateParameter(valid_601178, JString, required = false,
                                 default = nil)
  if valid_601178 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_601178
  var valid_601179 = query.getOrDefault("Tags")
  valid_601179 = validateParameter(valid_601179, JArray, required = false,
                                 default = nil)
  if valid_601179 != nil:
    section.add "Tags", valid_601179
  var valid_601180 = query.getOrDefault("Action")
  valid_601180 = validateParameter(valid_601180, JString, required = true,
                                 default = newJString("CreateApplication"))
  if valid_601180 != nil:
    section.add "Action", valid_601180
  var valid_601181 = query.getOrDefault("Version")
  valid_601181 = validateParameter(valid_601181, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601181 != nil:
    section.add "Version", valid_601181
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601182 = header.getOrDefault("X-Amz-Date")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Date", valid_601182
  var valid_601183 = header.getOrDefault("X-Amz-Security-Token")
  valid_601183 = validateParameter(valid_601183, JString, required = false,
                                 default = nil)
  if valid_601183 != nil:
    section.add "X-Amz-Security-Token", valid_601183
  var valid_601184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601184 = validateParameter(valid_601184, JString, required = false,
                                 default = nil)
  if valid_601184 != nil:
    section.add "X-Amz-Content-Sha256", valid_601184
  var valid_601185 = header.getOrDefault("X-Amz-Algorithm")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "X-Amz-Algorithm", valid_601185
  var valid_601186 = header.getOrDefault("X-Amz-Signature")
  valid_601186 = validateParameter(valid_601186, JString, required = false,
                                 default = nil)
  if valid_601186 != nil:
    section.add "X-Amz-Signature", valid_601186
  var valid_601187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601187 = validateParameter(valid_601187, JString, required = false,
                                 default = nil)
  if valid_601187 != nil:
    section.add "X-Amz-SignedHeaders", valid_601187
  var valid_601188 = header.getOrDefault("X-Amz-Credential")
  valid_601188 = validateParameter(valid_601188, JString, required = false,
                                 default = nil)
  if valid_601188 != nil:
    section.add "X-Amz-Credential", valid_601188
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601189: Call_GetCreateApplication_601172; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates an application that has one configuration template named <code>default</code> and no application versions. 
  ## 
  let valid = call_601189.validator(path, query, header, formData, body)
  let scheme = call_601189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601189.url(scheme.get, call_601189.host, call_601189.base,
                         call_601189.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601189, url, valid)

proc call*(call_601190: Call_GetCreateApplication_601172; ApplicationName: string;
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
  var query_601191 = newJObject()
  add(query_601191, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  add(query_601191, "ApplicationName", newJString(ApplicationName))
  add(query_601191, "Description", newJString(Description))
  add(query_601191, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  if Tags != nil:
    query_601191.add "Tags", Tags
  add(query_601191, "Action", newJString(Action))
  add(query_601191, "Version", newJString(Version))
  result = call_601190.call(nil, query_601191, nil, nil, nil)

var getCreateApplication* = Call_GetCreateApplication_601172(
    name: "getCreateApplication", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateApplication",
    validator: validate_GetCreateApplication_601173, base: "/",
    url: url_GetCreateApplication_601174, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateApplicationVersion_601244 = ref object of OpenApiRestCall_600438
proc url_PostCreateApplicationVersion_601246(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateApplicationVersion_601245(path: JsonNode; query: JsonNode;
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
  var valid_601247 = query.getOrDefault("Action")
  valid_601247 = validateParameter(valid_601247, JString, required = true, default = newJString(
      "CreateApplicationVersion"))
  if valid_601247 != nil:
    section.add "Action", valid_601247
  var valid_601248 = query.getOrDefault("Version")
  valid_601248 = validateParameter(valid_601248, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601248 != nil:
    section.add "Version", valid_601248
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601249 = header.getOrDefault("X-Amz-Date")
  valid_601249 = validateParameter(valid_601249, JString, required = false,
                                 default = nil)
  if valid_601249 != nil:
    section.add "X-Amz-Date", valid_601249
  var valid_601250 = header.getOrDefault("X-Amz-Security-Token")
  valid_601250 = validateParameter(valid_601250, JString, required = false,
                                 default = nil)
  if valid_601250 != nil:
    section.add "X-Amz-Security-Token", valid_601250
  var valid_601251 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601251 = validateParameter(valid_601251, JString, required = false,
                                 default = nil)
  if valid_601251 != nil:
    section.add "X-Amz-Content-Sha256", valid_601251
  var valid_601252 = header.getOrDefault("X-Amz-Algorithm")
  valid_601252 = validateParameter(valid_601252, JString, required = false,
                                 default = nil)
  if valid_601252 != nil:
    section.add "X-Amz-Algorithm", valid_601252
  var valid_601253 = header.getOrDefault("X-Amz-Signature")
  valid_601253 = validateParameter(valid_601253, JString, required = false,
                                 default = nil)
  if valid_601253 != nil:
    section.add "X-Amz-Signature", valid_601253
  var valid_601254 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601254 = validateParameter(valid_601254, JString, required = false,
                                 default = nil)
  if valid_601254 != nil:
    section.add "X-Amz-SignedHeaders", valid_601254
  var valid_601255 = header.getOrDefault("X-Amz-Credential")
  valid_601255 = validateParameter(valid_601255, JString, required = false,
                                 default = nil)
  if valid_601255 != nil:
    section.add "X-Amz-Credential", valid_601255
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
  var valid_601256 = formData.getOrDefault("SourceBundle.S3Key")
  valid_601256 = validateParameter(valid_601256, JString, required = false,
                                 default = nil)
  if valid_601256 != nil:
    section.add "SourceBundle.S3Key", valid_601256
  assert formData != nil,
        "formData argument is necessary due to required `VersionLabel` field"
  var valid_601257 = formData.getOrDefault("VersionLabel")
  valid_601257 = validateParameter(valid_601257, JString, required = true,
                                 default = nil)
  if valid_601257 != nil:
    section.add "VersionLabel", valid_601257
  var valid_601258 = formData.getOrDefault("SourceBundle.S3Bucket")
  valid_601258 = validateParameter(valid_601258, JString, required = false,
                                 default = nil)
  if valid_601258 != nil:
    section.add "SourceBundle.S3Bucket", valid_601258
  var valid_601259 = formData.getOrDefault("BuildConfiguration.ComputeType")
  valid_601259 = validateParameter(valid_601259, JString, required = false,
                                 default = nil)
  if valid_601259 != nil:
    section.add "BuildConfiguration.ComputeType", valid_601259
  var valid_601260 = formData.getOrDefault("SourceBuildInformation.SourceType")
  valid_601260 = validateParameter(valid_601260, JString, required = false,
                                 default = nil)
  if valid_601260 != nil:
    section.add "SourceBuildInformation.SourceType", valid_601260
  var valid_601261 = formData.getOrDefault("Tags")
  valid_601261 = validateParameter(valid_601261, JArray, required = false,
                                 default = nil)
  if valid_601261 != nil:
    section.add "Tags", valid_601261
  var valid_601262 = formData.getOrDefault("AutoCreateApplication")
  valid_601262 = validateParameter(valid_601262, JBool, required = false, default = nil)
  if valid_601262 != nil:
    section.add "AutoCreateApplication", valid_601262
  var valid_601263 = formData.getOrDefault("SourceBuildInformation.SourceLocation")
  valid_601263 = validateParameter(valid_601263, JString, required = false,
                                 default = nil)
  if valid_601263 != nil:
    section.add "SourceBuildInformation.SourceLocation", valid_601263
  var valid_601264 = formData.getOrDefault("BuildConfiguration.CodeBuildServiceRole")
  valid_601264 = validateParameter(valid_601264, JString, required = false,
                                 default = nil)
  if valid_601264 != nil:
    section.add "BuildConfiguration.CodeBuildServiceRole", valid_601264
  var valid_601265 = formData.getOrDefault("ApplicationName")
  valid_601265 = validateParameter(valid_601265, JString, required = true,
                                 default = nil)
  if valid_601265 != nil:
    section.add "ApplicationName", valid_601265
  var valid_601266 = formData.getOrDefault("BuildConfiguration.ArtifactName")
  valid_601266 = validateParameter(valid_601266, JString, required = false,
                                 default = nil)
  if valid_601266 != nil:
    section.add "BuildConfiguration.ArtifactName", valid_601266
  var valid_601267 = formData.getOrDefault("BuildConfiguration.TimeoutInMinutes")
  valid_601267 = validateParameter(valid_601267, JString, required = false,
                                 default = nil)
  if valid_601267 != nil:
    section.add "BuildConfiguration.TimeoutInMinutes", valid_601267
  var valid_601268 = formData.getOrDefault("SourceBuildInformation.SourceRepository")
  valid_601268 = validateParameter(valid_601268, JString, required = false,
                                 default = nil)
  if valid_601268 != nil:
    section.add "SourceBuildInformation.SourceRepository", valid_601268
  var valid_601269 = formData.getOrDefault("Description")
  valid_601269 = validateParameter(valid_601269, JString, required = false,
                                 default = nil)
  if valid_601269 != nil:
    section.add "Description", valid_601269
  var valid_601270 = formData.getOrDefault("BuildConfiguration.Image")
  valid_601270 = validateParameter(valid_601270, JString, required = false,
                                 default = nil)
  if valid_601270 != nil:
    section.add "BuildConfiguration.Image", valid_601270
  var valid_601271 = formData.getOrDefault("Process")
  valid_601271 = validateParameter(valid_601271, JBool, required = false, default = nil)
  if valid_601271 != nil:
    section.add "Process", valid_601271
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601272: Call_PostCreateApplicationVersion_601244; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an application version for the specified application. You can create an application version from a source bundle in Amazon S3, a commit in AWS CodeCommit, or the output of an AWS CodeBuild build as follows:</p> <p>Specify a commit in an AWS CodeCommit repository with <code>SourceBuildInformation</code>.</p> <p>Specify a build in an AWS CodeBuild with <code>SourceBuildInformation</code> and <code>BuildConfiguration</code>.</p> <p>Specify a source bundle in S3 with <code>SourceBundle</code> </p> <p>Omit both <code>SourceBuildInformation</code> and <code>SourceBundle</code> to use the default sample application.</p> <note> <p>Once you create an application version with a specified Amazon S3 bucket and key location, you cannot change that Amazon S3 location. If you change the Amazon S3 location, you receive an exception when you attempt to launch an environment from the application version.</p> </note>
  ## 
  let valid = call_601272.validator(path, query, header, formData, body)
  let scheme = call_601272.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601272.url(scheme.get, call_601272.host, call_601272.base,
                         call_601272.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601272, url, valid)

proc call*(call_601273: Call_PostCreateApplicationVersion_601244;
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
  var query_601274 = newJObject()
  var formData_601275 = newJObject()
  add(formData_601275, "SourceBundle.S3Key", newJString(SourceBundleS3Key))
  add(formData_601275, "VersionLabel", newJString(VersionLabel))
  add(formData_601275, "SourceBundle.S3Bucket", newJString(SourceBundleS3Bucket))
  add(formData_601275, "BuildConfiguration.ComputeType",
      newJString(BuildConfigurationComputeType))
  add(formData_601275, "SourceBuildInformation.SourceType",
      newJString(SourceBuildInformationSourceType))
  if Tags != nil:
    formData_601275.add "Tags", Tags
  add(formData_601275, "AutoCreateApplication", newJBool(AutoCreateApplication))
  add(formData_601275, "SourceBuildInformation.SourceLocation",
      newJString(SourceBuildInformationSourceLocation))
  add(query_601274, "Action", newJString(Action))
  add(formData_601275, "BuildConfiguration.CodeBuildServiceRole",
      newJString(BuildConfigurationCodeBuildServiceRole))
  add(formData_601275, "ApplicationName", newJString(ApplicationName))
  add(formData_601275, "BuildConfiguration.ArtifactName",
      newJString(BuildConfigurationArtifactName))
  add(formData_601275, "BuildConfiguration.TimeoutInMinutes",
      newJString(BuildConfigurationTimeoutInMinutes))
  add(formData_601275, "SourceBuildInformation.SourceRepository",
      newJString(SourceBuildInformationSourceRepository))
  add(formData_601275, "Description", newJString(Description))
  add(formData_601275, "BuildConfiguration.Image",
      newJString(BuildConfigurationImage))
  add(formData_601275, "Process", newJBool(Process))
  add(query_601274, "Version", newJString(Version))
  result = call_601273.call(nil, query_601274, nil, formData_601275, nil)

var postCreateApplicationVersion* = Call_PostCreateApplicationVersion_601244(
    name: "postCreateApplicationVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateApplicationVersion",
    validator: validate_PostCreateApplicationVersion_601245, base: "/",
    url: url_PostCreateApplicationVersion_601246,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateApplicationVersion_601213 = ref object of OpenApiRestCall_600438
proc url_GetCreateApplicationVersion_601215(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateApplicationVersion_601214(path: JsonNode; query: JsonNode;
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
  var valid_601216 = query.getOrDefault("BuildConfiguration.TimeoutInMinutes")
  valid_601216 = validateParameter(valid_601216, JString, required = false,
                                 default = nil)
  if valid_601216 != nil:
    section.add "BuildConfiguration.TimeoutInMinutes", valid_601216
  var valid_601217 = query.getOrDefault("SourceBundle.S3Bucket")
  valid_601217 = validateParameter(valid_601217, JString, required = false,
                                 default = nil)
  if valid_601217 != nil:
    section.add "SourceBundle.S3Bucket", valid_601217
  var valid_601218 = query.getOrDefault("BuildConfiguration.ComputeType")
  valid_601218 = validateParameter(valid_601218, JString, required = false,
                                 default = nil)
  if valid_601218 != nil:
    section.add "BuildConfiguration.ComputeType", valid_601218
  assert query != nil,
        "query argument is necessary due to required `VersionLabel` field"
  var valid_601219 = query.getOrDefault("VersionLabel")
  valid_601219 = validateParameter(valid_601219, JString, required = true,
                                 default = nil)
  if valid_601219 != nil:
    section.add "VersionLabel", valid_601219
  var valid_601220 = query.getOrDefault("BuildConfiguration.ArtifactName")
  valid_601220 = validateParameter(valid_601220, JString, required = false,
                                 default = nil)
  if valid_601220 != nil:
    section.add "BuildConfiguration.ArtifactName", valid_601220
  var valid_601221 = query.getOrDefault("ApplicationName")
  valid_601221 = validateParameter(valid_601221, JString, required = true,
                                 default = nil)
  if valid_601221 != nil:
    section.add "ApplicationName", valid_601221
  var valid_601222 = query.getOrDefault("Description")
  valid_601222 = validateParameter(valid_601222, JString, required = false,
                                 default = nil)
  if valid_601222 != nil:
    section.add "Description", valid_601222
  var valid_601223 = query.getOrDefault("BuildConfiguration.Image")
  valid_601223 = validateParameter(valid_601223, JString, required = false,
                                 default = nil)
  if valid_601223 != nil:
    section.add "BuildConfiguration.Image", valid_601223
  var valid_601224 = query.getOrDefault("SourceBuildInformation.SourceLocation")
  valid_601224 = validateParameter(valid_601224, JString, required = false,
                                 default = nil)
  if valid_601224 != nil:
    section.add "SourceBuildInformation.SourceLocation", valid_601224
  var valid_601225 = query.getOrDefault("SourceBundle.S3Key")
  valid_601225 = validateParameter(valid_601225, JString, required = false,
                                 default = nil)
  if valid_601225 != nil:
    section.add "SourceBundle.S3Key", valid_601225
  var valid_601226 = query.getOrDefault("Tags")
  valid_601226 = validateParameter(valid_601226, JArray, required = false,
                                 default = nil)
  if valid_601226 != nil:
    section.add "Tags", valid_601226
  var valid_601227 = query.getOrDefault("AutoCreateApplication")
  valid_601227 = validateParameter(valid_601227, JBool, required = false, default = nil)
  if valid_601227 != nil:
    section.add "AutoCreateApplication", valid_601227
  var valid_601228 = query.getOrDefault("Action")
  valid_601228 = validateParameter(valid_601228, JString, required = true, default = newJString(
      "CreateApplicationVersion"))
  if valid_601228 != nil:
    section.add "Action", valid_601228
  var valid_601229 = query.getOrDefault("SourceBuildInformation.SourceType")
  valid_601229 = validateParameter(valid_601229, JString, required = false,
                                 default = nil)
  if valid_601229 != nil:
    section.add "SourceBuildInformation.SourceType", valid_601229
  var valid_601230 = query.getOrDefault("BuildConfiguration.CodeBuildServiceRole")
  valid_601230 = validateParameter(valid_601230, JString, required = false,
                                 default = nil)
  if valid_601230 != nil:
    section.add "BuildConfiguration.CodeBuildServiceRole", valid_601230
  var valid_601231 = query.getOrDefault("Process")
  valid_601231 = validateParameter(valid_601231, JBool, required = false, default = nil)
  if valid_601231 != nil:
    section.add "Process", valid_601231
  var valid_601232 = query.getOrDefault("SourceBuildInformation.SourceRepository")
  valid_601232 = validateParameter(valid_601232, JString, required = false,
                                 default = nil)
  if valid_601232 != nil:
    section.add "SourceBuildInformation.SourceRepository", valid_601232
  var valid_601233 = query.getOrDefault("Version")
  valid_601233 = validateParameter(valid_601233, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601233 != nil:
    section.add "Version", valid_601233
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601234 = header.getOrDefault("X-Amz-Date")
  valid_601234 = validateParameter(valid_601234, JString, required = false,
                                 default = nil)
  if valid_601234 != nil:
    section.add "X-Amz-Date", valid_601234
  var valid_601235 = header.getOrDefault("X-Amz-Security-Token")
  valid_601235 = validateParameter(valid_601235, JString, required = false,
                                 default = nil)
  if valid_601235 != nil:
    section.add "X-Amz-Security-Token", valid_601235
  var valid_601236 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601236 = validateParameter(valid_601236, JString, required = false,
                                 default = nil)
  if valid_601236 != nil:
    section.add "X-Amz-Content-Sha256", valid_601236
  var valid_601237 = header.getOrDefault("X-Amz-Algorithm")
  valid_601237 = validateParameter(valid_601237, JString, required = false,
                                 default = nil)
  if valid_601237 != nil:
    section.add "X-Amz-Algorithm", valid_601237
  var valid_601238 = header.getOrDefault("X-Amz-Signature")
  valid_601238 = validateParameter(valid_601238, JString, required = false,
                                 default = nil)
  if valid_601238 != nil:
    section.add "X-Amz-Signature", valid_601238
  var valid_601239 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601239 = validateParameter(valid_601239, JString, required = false,
                                 default = nil)
  if valid_601239 != nil:
    section.add "X-Amz-SignedHeaders", valid_601239
  var valid_601240 = header.getOrDefault("X-Amz-Credential")
  valid_601240 = validateParameter(valid_601240, JString, required = false,
                                 default = nil)
  if valid_601240 != nil:
    section.add "X-Amz-Credential", valid_601240
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601241: Call_GetCreateApplicationVersion_601213; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an application version for the specified application. You can create an application version from a source bundle in Amazon S3, a commit in AWS CodeCommit, or the output of an AWS CodeBuild build as follows:</p> <p>Specify a commit in an AWS CodeCommit repository with <code>SourceBuildInformation</code>.</p> <p>Specify a build in an AWS CodeBuild with <code>SourceBuildInformation</code> and <code>BuildConfiguration</code>.</p> <p>Specify a source bundle in S3 with <code>SourceBundle</code> </p> <p>Omit both <code>SourceBuildInformation</code> and <code>SourceBundle</code> to use the default sample application.</p> <note> <p>Once you create an application version with a specified Amazon S3 bucket and key location, you cannot change that Amazon S3 location. If you change the Amazon S3 location, you receive an exception when you attempt to launch an environment from the application version.</p> </note>
  ## 
  let valid = call_601241.validator(path, query, header, formData, body)
  let scheme = call_601241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601241.url(scheme.get, call_601241.host, call_601241.base,
                         call_601241.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601241, url, valid)

proc call*(call_601242: Call_GetCreateApplicationVersion_601213;
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
  var query_601243 = newJObject()
  add(query_601243, "BuildConfiguration.TimeoutInMinutes",
      newJString(BuildConfigurationTimeoutInMinutes))
  add(query_601243, "SourceBundle.S3Bucket", newJString(SourceBundleS3Bucket))
  add(query_601243, "BuildConfiguration.ComputeType",
      newJString(BuildConfigurationComputeType))
  add(query_601243, "VersionLabel", newJString(VersionLabel))
  add(query_601243, "BuildConfiguration.ArtifactName",
      newJString(BuildConfigurationArtifactName))
  add(query_601243, "ApplicationName", newJString(ApplicationName))
  add(query_601243, "Description", newJString(Description))
  add(query_601243, "BuildConfiguration.Image",
      newJString(BuildConfigurationImage))
  add(query_601243, "SourceBuildInformation.SourceLocation",
      newJString(SourceBuildInformationSourceLocation))
  add(query_601243, "SourceBundle.S3Key", newJString(SourceBundleS3Key))
  if Tags != nil:
    query_601243.add "Tags", Tags
  add(query_601243, "AutoCreateApplication", newJBool(AutoCreateApplication))
  add(query_601243, "Action", newJString(Action))
  add(query_601243, "SourceBuildInformation.SourceType",
      newJString(SourceBuildInformationSourceType))
  add(query_601243, "BuildConfiguration.CodeBuildServiceRole",
      newJString(BuildConfigurationCodeBuildServiceRole))
  add(query_601243, "Process", newJBool(Process))
  add(query_601243, "SourceBuildInformation.SourceRepository",
      newJString(SourceBuildInformationSourceRepository))
  add(query_601243, "Version", newJString(Version))
  result = call_601242.call(nil, query_601243, nil, nil, nil)

var getCreateApplicationVersion* = Call_GetCreateApplicationVersion_601213(
    name: "getCreateApplicationVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateApplicationVersion",
    validator: validate_GetCreateApplicationVersion_601214, base: "/",
    url: url_GetCreateApplicationVersion_601215,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateConfigurationTemplate_601301 = ref object of OpenApiRestCall_600438
proc url_PostCreateConfigurationTemplate_601303(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateConfigurationTemplate_601302(path: JsonNode;
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
  var valid_601304 = query.getOrDefault("Action")
  valid_601304 = validateParameter(valid_601304, JString, required = true, default = newJString(
      "CreateConfigurationTemplate"))
  if valid_601304 != nil:
    section.add "Action", valid_601304
  var valid_601305 = query.getOrDefault("Version")
  valid_601305 = validateParameter(valid_601305, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601305 != nil:
    section.add "Version", valid_601305
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601306 = header.getOrDefault("X-Amz-Date")
  valid_601306 = validateParameter(valid_601306, JString, required = false,
                                 default = nil)
  if valid_601306 != nil:
    section.add "X-Amz-Date", valid_601306
  var valid_601307 = header.getOrDefault("X-Amz-Security-Token")
  valid_601307 = validateParameter(valid_601307, JString, required = false,
                                 default = nil)
  if valid_601307 != nil:
    section.add "X-Amz-Security-Token", valid_601307
  var valid_601308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601308 = validateParameter(valid_601308, JString, required = false,
                                 default = nil)
  if valid_601308 != nil:
    section.add "X-Amz-Content-Sha256", valid_601308
  var valid_601309 = header.getOrDefault("X-Amz-Algorithm")
  valid_601309 = validateParameter(valid_601309, JString, required = false,
                                 default = nil)
  if valid_601309 != nil:
    section.add "X-Amz-Algorithm", valid_601309
  var valid_601310 = header.getOrDefault("X-Amz-Signature")
  valid_601310 = validateParameter(valid_601310, JString, required = false,
                                 default = nil)
  if valid_601310 != nil:
    section.add "X-Amz-Signature", valid_601310
  var valid_601311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601311 = validateParameter(valid_601311, JString, required = false,
                                 default = nil)
  if valid_601311 != nil:
    section.add "X-Amz-SignedHeaders", valid_601311
  var valid_601312 = header.getOrDefault("X-Amz-Credential")
  valid_601312 = validateParameter(valid_601312, JString, required = false,
                                 default = nil)
  if valid_601312 != nil:
    section.add "X-Amz-Credential", valid_601312
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
  var valid_601313 = formData.getOrDefault("OptionSettings")
  valid_601313 = validateParameter(valid_601313, JArray, required = false,
                                 default = nil)
  if valid_601313 != nil:
    section.add "OptionSettings", valid_601313
  var valid_601314 = formData.getOrDefault("Tags")
  valid_601314 = validateParameter(valid_601314, JArray, required = false,
                                 default = nil)
  if valid_601314 != nil:
    section.add "Tags", valid_601314
  var valid_601315 = formData.getOrDefault("SolutionStackName")
  valid_601315 = validateParameter(valid_601315, JString, required = false,
                                 default = nil)
  if valid_601315 != nil:
    section.add "SolutionStackName", valid_601315
  var valid_601316 = formData.getOrDefault("SourceConfiguration.ApplicationName")
  valid_601316 = validateParameter(valid_601316, JString, required = false,
                                 default = nil)
  if valid_601316 != nil:
    section.add "SourceConfiguration.ApplicationName", valid_601316
  var valid_601317 = formData.getOrDefault("EnvironmentId")
  valid_601317 = validateParameter(valid_601317, JString, required = false,
                                 default = nil)
  if valid_601317 != nil:
    section.add "EnvironmentId", valid_601317
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_601318 = formData.getOrDefault("ApplicationName")
  valid_601318 = validateParameter(valid_601318, JString, required = true,
                                 default = nil)
  if valid_601318 != nil:
    section.add "ApplicationName", valid_601318
  var valid_601319 = formData.getOrDefault("PlatformArn")
  valid_601319 = validateParameter(valid_601319, JString, required = false,
                                 default = nil)
  if valid_601319 != nil:
    section.add "PlatformArn", valid_601319
  var valid_601320 = formData.getOrDefault("TemplateName")
  valid_601320 = validateParameter(valid_601320, JString, required = true,
                                 default = nil)
  if valid_601320 != nil:
    section.add "TemplateName", valid_601320
  var valid_601321 = formData.getOrDefault("Description")
  valid_601321 = validateParameter(valid_601321, JString, required = false,
                                 default = nil)
  if valid_601321 != nil:
    section.add "Description", valid_601321
  var valid_601322 = formData.getOrDefault("SourceConfiguration.TemplateName")
  valid_601322 = validateParameter(valid_601322, JString, required = false,
                                 default = nil)
  if valid_601322 != nil:
    section.add "SourceConfiguration.TemplateName", valid_601322
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601323: Call_PostCreateConfigurationTemplate_601301;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a configuration template. Templates are associated with a specific application and are used to deploy different versions of the application with the same configuration settings.</p> <p>Templates aren't associated with any environment. The <code>EnvironmentName</code> response element is always <code>null</code>.</p> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> <li> <p> <a>DescribeConfigurationSettings</a> </p> </li> <li> <p> <a>ListAvailableSolutionStacks</a> </p> </li> </ul>
  ## 
  let valid = call_601323.validator(path, query, header, formData, body)
  let scheme = call_601323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601323.url(scheme.get, call_601323.host, call_601323.base,
                         call_601323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601323, url, valid)

proc call*(call_601324: Call_PostCreateConfigurationTemplate_601301;
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
  var query_601325 = newJObject()
  var formData_601326 = newJObject()
  if OptionSettings != nil:
    formData_601326.add "OptionSettings", OptionSettings
  if Tags != nil:
    formData_601326.add "Tags", Tags
  add(formData_601326, "SolutionStackName", newJString(SolutionStackName))
  add(formData_601326, "SourceConfiguration.ApplicationName",
      newJString(SourceConfigurationApplicationName))
  add(formData_601326, "EnvironmentId", newJString(EnvironmentId))
  add(query_601325, "Action", newJString(Action))
  add(formData_601326, "ApplicationName", newJString(ApplicationName))
  add(formData_601326, "PlatformArn", newJString(PlatformArn))
  add(formData_601326, "TemplateName", newJString(TemplateName))
  add(query_601325, "Version", newJString(Version))
  add(formData_601326, "Description", newJString(Description))
  add(formData_601326, "SourceConfiguration.TemplateName",
      newJString(SourceConfigurationTemplateName))
  result = call_601324.call(nil, query_601325, nil, formData_601326, nil)

var postCreateConfigurationTemplate* = Call_PostCreateConfigurationTemplate_601301(
    name: "postCreateConfigurationTemplate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateConfigurationTemplate",
    validator: validate_PostCreateConfigurationTemplate_601302, base: "/",
    url: url_PostCreateConfigurationTemplate_601303,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateConfigurationTemplate_601276 = ref object of OpenApiRestCall_600438
proc url_GetCreateConfigurationTemplate_601278(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateConfigurationTemplate_601277(path: JsonNode;
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
  var valid_601279 = query.getOrDefault("SourceConfiguration.ApplicationName")
  valid_601279 = validateParameter(valid_601279, JString, required = false,
                                 default = nil)
  if valid_601279 != nil:
    section.add "SourceConfiguration.ApplicationName", valid_601279
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_601280 = query.getOrDefault("ApplicationName")
  valid_601280 = validateParameter(valid_601280, JString, required = true,
                                 default = nil)
  if valid_601280 != nil:
    section.add "ApplicationName", valid_601280
  var valid_601281 = query.getOrDefault("Description")
  valid_601281 = validateParameter(valid_601281, JString, required = false,
                                 default = nil)
  if valid_601281 != nil:
    section.add "Description", valid_601281
  var valid_601282 = query.getOrDefault("PlatformArn")
  valid_601282 = validateParameter(valid_601282, JString, required = false,
                                 default = nil)
  if valid_601282 != nil:
    section.add "PlatformArn", valid_601282
  var valid_601283 = query.getOrDefault("Tags")
  valid_601283 = validateParameter(valid_601283, JArray, required = false,
                                 default = nil)
  if valid_601283 != nil:
    section.add "Tags", valid_601283
  var valid_601284 = query.getOrDefault("Action")
  valid_601284 = validateParameter(valid_601284, JString, required = true, default = newJString(
      "CreateConfigurationTemplate"))
  if valid_601284 != nil:
    section.add "Action", valid_601284
  var valid_601285 = query.getOrDefault("SolutionStackName")
  valid_601285 = validateParameter(valid_601285, JString, required = false,
                                 default = nil)
  if valid_601285 != nil:
    section.add "SolutionStackName", valid_601285
  var valid_601286 = query.getOrDefault("EnvironmentId")
  valid_601286 = validateParameter(valid_601286, JString, required = false,
                                 default = nil)
  if valid_601286 != nil:
    section.add "EnvironmentId", valid_601286
  var valid_601287 = query.getOrDefault("TemplateName")
  valid_601287 = validateParameter(valid_601287, JString, required = true,
                                 default = nil)
  if valid_601287 != nil:
    section.add "TemplateName", valid_601287
  var valid_601288 = query.getOrDefault("OptionSettings")
  valid_601288 = validateParameter(valid_601288, JArray, required = false,
                                 default = nil)
  if valid_601288 != nil:
    section.add "OptionSettings", valid_601288
  var valid_601289 = query.getOrDefault("Version")
  valid_601289 = validateParameter(valid_601289, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601289 != nil:
    section.add "Version", valid_601289
  var valid_601290 = query.getOrDefault("SourceConfiguration.TemplateName")
  valid_601290 = validateParameter(valid_601290, JString, required = false,
                                 default = nil)
  if valid_601290 != nil:
    section.add "SourceConfiguration.TemplateName", valid_601290
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601291 = header.getOrDefault("X-Amz-Date")
  valid_601291 = validateParameter(valid_601291, JString, required = false,
                                 default = nil)
  if valid_601291 != nil:
    section.add "X-Amz-Date", valid_601291
  var valid_601292 = header.getOrDefault("X-Amz-Security-Token")
  valid_601292 = validateParameter(valid_601292, JString, required = false,
                                 default = nil)
  if valid_601292 != nil:
    section.add "X-Amz-Security-Token", valid_601292
  var valid_601293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601293 = validateParameter(valid_601293, JString, required = false,
                                 default = nil)
  if valid_601293 != nil:
    section.add "X-Amz-Content-Sha256", valid_601293
  var valid_601294 = header.getOrDefault("X-Amz-Algorithm")
  valid_601294 = validateParameter(valid_601294, JString, required = false,
                                 default = nil)
  if valid_601294 != nil:
    section.add "X-Amz-Algorithm", valid_601294
  var valid_601295 = header.getOrDefault("X-Amz-Signature")
  valid_601295 = validateParameter(valid_601295, JString, required = false,
                                 default = nil)
  if valid_601295 != nil:
    section.add "X-Amz-Signature", valid_601295
  var valid_601296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601296 = validateParameter(valid_601296, JString, required = false,
                                 default = nil)
  if valid_601296 != nil:
    section.add "X-Amz-SignedHeaders", valid_601296
  var valid_601297 = header.getOrDefault("X-Amz-Credential")
  valid_601297 = validateParameter(valid_601297, JString, required = false,
                                 default = nil)
  if valid_601297 != nil:
    section.add "X-Amz-Credential", valid_601297
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601298: Call_GetCreateConfigurationTemplate_601276; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a configuration template. Templates are associated with a specific application and are used to deploy different versions of the application with the same configuration settings.</p> <p>Templates aren't associated with any environment. The <code>EnvironmentName</code> response element is always <code>null</code>.</p> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> <li> <p> <a>DescribeConfigurationSettings</a> </p> </li> <li> <p> <a>ListAvailableSolutionStacks</a> </p> </li> </ul>
  ## 
  let valid = call_601298.validator(path, query, header, formData, body)
  let scheme = call_601298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601298.url(scheme.get, call_601298.host, call_601298.base,
                         call_601298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601298, url, valid)

proc call*(call_601299: Call_GetCreateConfigurationTemplate_601276;
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
  var query_601300 = newJObject()
  add(query_601300, "SourceConfiguration.ApplicationName",
      newJString(SourceConfigurationApplicationName))
  add(query_601300, "ApplicationName", newJString(ApplicationName))
  add(query_601300, "Description", newJString(Description))
  add(query_601300, "PlatformArn", newJString(PlatformArn))
  if Tags != nil:
    query_601300.add "Tags", Tags
  add(query_601300, "Action", newJString(Action))
  add(query_601300, "SolutionStackName", newJString(SolutionStackName))
  add(query_601300, "EnvironmentId", newJString(EnvironmentId))
  add(query_601300, "TemplateName", newJString(TemplateName))
  if OptionSettings != nil:
    query_601300.add "OptionSettings", OptionSettings
  add(query_601300, "Version", newJString(Version))
  add(query_601300, "SourceConfiguration.TemplateName",
      newJString(SourceConfigurationTemplateName))
  result = call_601299.call(nil, query_601300, nil, nil, nil)

var getCreateConfigurationTemplate* = Call_GetCreateConfigurationTemplate_601276(
    name: "getCreateConfigurationTemplate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateConfigurationTemplate",
    validator: validate_GetCreateConfigurationTemplate_601277, base: "/",
    url: url_GetCreateConfigurationTemplate_601278,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEnvironment_601357 = ref object of OpenApiRestCall_600438
proc url_PostCreateEnvironment_601359(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateEnvironment_601358(path: JsonNode; query: JsonNode;
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
  var valid_601360 = query.getOrDefault("Action")
  valid_601360 = validateParameter(valid_601360, JString, required = true,
                                 default = newJString("CreateEnvironment"))
  if valid_601360 != nil:
    section.add "Action", valid_601360
  var valid_601361 = query.getOrDefault("Version")
  valid_601361 = validateParameter(valid_601361, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601361 != nil:
    section.add "Version", valid_601361
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601362 = header.getOrDefault("X-Amz-Date")
  valid_601362 = validateParameter(valid_601362, JString, required = false,
                                 default = nil)
  if valid_601362 != nil:
    section.add "X-Amz-Date", valid_601362
  var valid_601363 = header.getOrDefault("X-Amz-Security-Token")
  valid_601363 = validateParameter(valid_601363, JString, required = false,
                                 default = nil)
  if valid_601363 != nil:
    section.add "X-Amz-Security-Token", valid_601363
  var valid_601364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601364 = validateParameter(valid_601364, JString, required = false,
                                 default = nil)
  if valid_601364 != nil:
    section.add "X-Amz-Content-Sha256", valid_601364
  var valid_601365 = header.getOrDefault("X-Amz-Algorithm")
  valid_601365 = validateParameter(valid_601365, JString, required = false,
                                 default = nil)
  if valid_601365 != nil:
    section.add "X-Amz-Algorithm", valid_601365
  var valid_601366 = header.getOrDefault("X-Amz-Signature")
  valid_601366 = validateParameter(valid_601366, JString, required = false,
                                 default = nil)
  if valid_601366 != nil:
    section.add "X-Amz-Signature", valid_601366
  var valid_601367 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601367 = validateParameter(valid_601367, JString, required = false,
                                 default = nil)
  if valid_601367 != nil:
    section.add "X-Amz-SignedHeaders", valid_601367
  var valid_601368 = header.getOrDefault("X-Amz-Credential")
  valid_601368 = validateParameter(valid_601368, JString, required = false,
                                 default = nil)
  if valid_601368 != nil:
    section.add "X-Amz-Credential", valid_601368
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
  var valid_601369 = formData.getOrDefault("Tier.Name")
  valid_601369 = validateParameter(valid_601369, JString, required = false,
                                 default = nil)
  if valid_601369 != nil:
    section.add "Tier.Name", valid_601369
  var valid_601370 = formData.getOrDefault("OptionsToRemove")
  valid_601370 = validateParameter(valid_601370, JArray, required = false,
                                 default = nil)
  if valid_601370 != nil:
    section.add "OptionsToRemove", valid_601370
  var valid_601371 = formData.getOrDefault("VersionLabel")
  valid_601371 = validateParameter(valid_601371, JString, required = false,
                                 default = nil)
  if valid_601371 != nil:
    section.add "VersionLabel", valid_601371
  var valid_601372 = formData.getOrDefault("OptionSettings")
  valid_601372 = validateParameter(valid_601372, JArray, required = false,
                                 default = nil)
  if valid_601372 != nil:
    section.add "OptionSettings", valid_601372
  var valid_601373 = formData.getOrDefault("GroupName")
  valid_601373 = validateParameter(valid_601373, JString, required = false,
                                 default = nil)
  if valid_601373 != nil:
    section.add "GroupName", valid_601373
  var valid_601374 = formData.getOrDefault("Tags")
  valid_601374 = validateParameter(valid_601374, JArray, required = false,
                                 default = nil)
  if valid_601374 != nil:
    section.add "Tags", valid_601374
  var valid_601375 = formData.getOrDefault("CNAMEPrefix")
  valid_601375 = validateParameter(valid_601375, JString, required = false,
                                 default = nil)
  if valid_601375 != nil:
    section.add "CNAMEPrefix", valid_601375
  var valid_601376 = formData.getOrDefault("SolutionStackName")
  valid_601376 = validateParameter(valid_601376, JString, required = false,
                                 default = nil)
  if valid_601376 != nil:
    section.add "SolutionStackName", valid_601376
  var valid_601377 = formData.getOrDefault("EnvironmentName")
  valid_601377 = validateParameter(valid_601377, JString, required = false,
                                 default = nil)
  if valid_601377 != nil:
    section.add "EnvironmentName", valid_601377
  var valid_601378 = formData.getOrDefault("Tier.Type")
  valid_601378 = validateParameter(valid_601378, JString, required = false,
                                 default = nil)
  if valid_601378 != nil:
    section.add "Tier.Type", valid_601378
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_601379 = formData.getOrDefault("ApplicationName")
  valid_601379 = validateParameter(valid_601379, JString, required = true,
                                 default = nil)
  if valid_601379 != nil:
    section.add "ApplicationName", valid_601379
  var valid_601380 = formData.getOrDefault("PlatformArn")
  valid_601380 = validateParameter(valid_601380, JString, required = false,
                                 default = nil)
  if valid_601380 != nil:
    section.add "PlatformArn", valid_601380
  var valid_601381 = formData.getOrDefault("TemplateName")
  valid_601381 = validateParameter(valid_601381, JString, required = false,
                                 default = nil)
  if valid_601381 != nil:
    section.add "TemplateName", valid_601381
  var valid_601382 = formData.getOrDefault("Description")
  valid_601382 = validateParameter(valid_601382, JString, required = false,
                                 default = nil)
  if valid_601382 != nil:
    section.add "Description", valid_601382
  var valid_601383 = formData.getOrDefault("Tier.Version")
  valid_601383 = validateParameter(valid_601383, JString, required = false,
                                 default = nil)
  if valid_601383 != nil:
    section.add "Tier.Version", valid_601383
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601384: Call_PostCreateEnvironment_601357; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Launches an environment for the specified application using the specified configuration.
  ## 
  let valid = call_601384.validator(path, query, header, formData, body)
  let scheme = call_601384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601384.url(scheme.get, call_601384.host, call_601384.base,
                         call_601384.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601384, url, valid)

proc call*(call_601385: Call_PostCreateEnvironment_601357; ApplicationName: string;
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
  var query_601386 = newJObject()
  var formData_601387 = newJObject()
  add(formData_601387, "Tier.Name", newJString(TierName))
  if OptionsToRemove != nil:
    formData_601387.add "OptionsToRemove", OptionsToRemove
  add(formData_601387, "VersionLabel", newJString(VersionLabel))
  if OptionSettings != nil:
    formData_601387.add "OptionSettings", OptionSettings
  add(formData_601387, "GroupName", newJString(GroupName))
  if Tags != nil:
    formData_601387.add "Tags", Tags
  add(formData_601387, "CNAMEPrefix", newJString(CNAMEPrefix))
  add(formData_601387, "SolutionStackName", newJString(SolutionStackName))
  add(formData_601387, "EnvironmentName", newJString(EnvironmentName))
  add(formData_601387, "Tier.Type", newJString(TierType))
  add(query_601386, "Action", newJString(Action))
  add(formData_601387, "ApplicationName", newJString(ApplicationName))
  add(formData_601387, "PlatformArn", newJString(PlatformArn))
  add(formData_601387, "TemplateName", newJString(TemplateName))
  add(query_601386, "Version", newJString(Version))
  add(formData_601387, "Description", newJString(Description))
  add(formData_601387, "Tier.Version", newJString(TierVersion))
  result = call_601385.call(nil, query_601386, nil, formData_601387, nil)

var postCreateEnvironment* = Call_PostCreateEnvironment_601357(
    name: "postCreateEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateEnvironment",
    validator: validate_PostCreateEnvironment_601358, base: "/",
    url: url_PostCreateEnvironment_601359, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEnvironment_601327 = ref object of OpenApiRestCall_600438
proc url_GetCreateEnvironment_601329(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateEnvironment_601328(path: JsonNode; query: JsonNode;
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
  var valid_601330 = query.getOrDefault("Tier.Name")
  valid_601330 = validateParameter(valid_601330, JString, required = false,
                                 default = nil)
  if valid_601330 != nil:
    section.add "Tier.Name", valid_601330
  var valid_601331 = query.getOrDefault("VersionLabel")
  valid_601331 = validateParameter(valid_601331, JString, required = false,
                                 default = nil)
  if valid_601331 != nil:
    section.add "VersionLabel", valid_601331
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_601332 = query.getOrDefault("ApplicationName")
  valid_601332 = validateParameter(valid_601332, JString, required = true,
                                 default = nil)
  if valid_601332 != nil:
    section.add "ApplicationName", valid_601332
  var valid_601333 = query.getOrDefault("Description")
  valid_601333 = validateParameter(valid_601333, JString, required = false,
                                 default = nil)
  if valid_601333 != nil:
    section.add "Description", valid_601333
  var valid_601334 = query.getOrDefault("OptionsToRemove")
  valid_601334 = validateParameter(valid_601334, JArray, required = false,
                                 default = nil)
  if valid_601334 != nil:
    section.add "OptionsToRemove", valid_601334
  var valid_601335 = query.getOrDefault("PlatformArn")
  valid_601335 = validateParameter(valid_601335, JString, required = false,
                                 default = nil)
  if valid_601335 != nil:
    section.add "PlatformArn", valid_601335
  var valid_601336 = query.getOrDefault("Tags")
  valid_601336 = validateParameter(valid_601336, JArray, required = false,
                                 default = nil)
  if valid_601336 != nil:
    section.add "Tags", valid_601336
  var valid_601337 = query.getOrDefault("EnvironmentName")
  valid_601337 = validateParameter(valid_601337, JString, required = false,
                                 default = nil)
  if valid_601337 != nil:
    section.add "EnvironmentName", valid_601337
  var valid_601338 = query.getOrDefault("Action")
  valid_601338 = validateParameter(valid_601338, JString, required = true,
                                 default = newJString("CreateEnvironment"))
  if valid_601338 != nil:
    section.add "Action", valid_601338
  var valid_601339 = query.getOrDefault("SolutionStackName")
  valid_601339 = validateParameter(valid_601339, JString, required = false,
                                 default = nil)
  if valid_601339 != nil:
    section.add "SolutionStackName", valid_601339
  var valid_601340 = query.getOrDefault("Tier.Version")
  valid_601340 = validateParameter(valid_601340, JString, required = false,
                                 default = nil)
  if valid_601340 != nil:
    section.add "Tier.Version", valid_601340
  var valid_601341 = query.getOrDefault("TemplateName")
  valid_601341 = validateParameter(valid_601341, JString, required = false,
                                 default = nil)
  if valid_601341 != nil:
    section.add "TemplateName", valid_601341
  var valid_601342 = query.getOrDefault("GroupName")
  valid_601342 = validateParameter(valid_601342, JString, required = false,
                                 default = nil)
  if valid_601342 != nil:
    section.add "GroupName", valid_601342
  var valid_601343 = query.getOrDefault("OptionSettings")
  valid_601343 = validateParameter(valid_601343, JArray, required = false,
                                 default = nil)
  if valid_601343 != nil:
    section.add "OptionSettings", valid_601343
  var valid_601344 = query.getOrDefault("Tier.Type")
  valid_601344 = validateParameter(valid_601344, JString, required = false,
                                 default = nil)
  if valid_601344 != nil:
    section.add "Tier.Type", valid_601344
  var valid_601345 = query.getOrDefault("Version")
  valid_601345 = validateParameter(valid_601345, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601345 != nil:
    section.add "Version", valid_601345
  var valid_601346 = query.getOrDefault("CNAMEPrefix")
  valid_601346 = validateParameter(valid_601346, JString, required = false,
                                 default = nil)
  if valid_601346 != nil:
    section.add "CNAMEPrefix", valid_601346
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601347 = header.getOrDefault("X-Amz-Date")
  valid_601347 = validateParameter(valid_601347, JString, required = false,
                                 default = nil)
  if valid_601347 != nil:
    section.add "X-Amz-Date", valid_601347
  var valid_601348 = header.getOrDefault("X-Amz-Security-Token")
  valid_601348 = validateParameter(valid_601348, JString, required = false,
                                 default = nil)
  if valid_601348 != nil:
    section.add "X-Amz-Security-Token", valid_601348
  var valid_601349 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601349 = validateParameter(valid_601349, JString, required = false,
                                 default = nil)
  if valid_601349 != nil:
    section.add "X-Amz-Content-Sha256", valid_601349
  var valid_601350 = header.getOrDefault("X-Amz-Algorithm")
  valid_601350 = validateParameter(valid_601350, JString, required = false,
                                 default = nil)
  if valid_601350 != nil:
    section.add "X-Amz-Algorithm", valid_601350
  var valid_601351 = header.getOrDefault("X-Amz-Signature")
  valid_601351 = validateParameter(valid_601351, JString, required = false,
                                 default = nil)
  if valid_601351 != nil:
    section.add "X-Amz-Signature", valid_601351
  var valid_601352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601352 = validateParameter(valid_601352, JString, required = false,
                                 default = nil)
  if valid_601352 != nil:
    section.add "X-Amz-SignedHeaders", valid_601352
  var valid_601353 = header.getOrDefault("X-Amz-Credential")
  valid_601353 = validateParameter(valid_601353, JString, required = false,
                                 default = nil)
  if valid_601353 != nil:
    section.add "X-Amz-Credential", valid_601353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601354: Call_GetCreateEnvironment_601327; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Launches an environment for the specified application using the specified configuration.
  ## 
  let valid = call_601354.validator(path, query, header, formData, body)
  let scheme = call_601354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601354.url(scheme.get, call_601354.host, call_601354.base,
                         call_601354.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601354, url, valid)

proc call*(call_601355: Call_GetCreateEnvironment_601327; ApplicationName: string;
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
  var query_601356 = newJObject()
  add(query_601356, "Tier.Name", newJString(TierName))
  add(query_601356, "VersionLabel", newJString(VersionLabel))
  add(query_601356, "ApplicationName", newJString(ApplicationName))
  add(query_601356, "Description", newJString(Description))
  if OptionsToRemove != nil:
    query_601356.add "OptionsToRemove", OptionsToRemove
  add(query_601356, "PlatformArn", newJString(PlatformArn))
  if Tags != nil:
    query_601356.add "Tags", Tags
  add(query_601356, "EnvironmentName", newJString(EnvironmentName))
  add(query_601356, "Action", newJString(Action))
  add(query_601356, "SolutionStackName", newJString(SolutionStackName))
  add(query_601356, "Tier.Version", newJString(TierVersion))
  add(query_601356, "TemplateName", newJString(TemplateName))
  add(query_601356, "GroupName", newJString(GroupName))
  if OptionSettings != nil:
    query_601356.add "OptionSettings", OptionSettings
  add(query_601356, "Tier.Type", newJString(TierType))
  add(query_601356, "Version", newJString(Version))
  add(query_601356, "CNAMEPrefix", newJString(CNAMEPrefix))
  result = call_601355.call(nil, query_601356, nil, nil, nil)

var getCreateEnvironment* = Call_GetCreateEnvironment_601327(
    name: "getCreateEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateEnvironment",
    validator: validate_GetCreateEnvironment_601328, base: "/",
    url: url_GetCreateEnvironment_601329, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreatePlatformVersion_601410 = ref object of OpenApiRestCall_600438
proc url_PostCreatePlatformVersion_601412(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreatePlatformVersion_601411(path: JsonNode; query: JsonNode;
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
  var valid_601413 = query.getOrDefault("Action")
  valid_601413 = validateParameter(valid_601413, JString, required = true,
                                 default = newJString("CreatePlatformVersion"))
  if valid_601413 != nil:
    section.add "Action", valid_601413
  var valid_601414 = query.getOrDefault("Version")
  valid_601414 = validateParameter(valid_601414, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601414 != nil:
    section.add "Version", valid_601414
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601415 = header.getOrDefault("X-Amz-Date")
  valid_601415 = validateParameter(valid_601415, JString, required = false,
                                 default = nil)
  if valid_601415 != nil:
    section.add "X-Amz-Date", valid_601415
  var valid_601416 = header.getOrDefault("X-Amz-Security-Token")
  valid_601416 = validateParameter(valid_601416, JString, required = false,
                                 default = nil)
  if valid_601416 != nil:
    section.add "X-Amz-Security-Token", valid_601416
  var valid_601417 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601417 = validateParameter(valid_601417, JString, required = false,
                                 default = nil)
  if valid_601417 != nil:
    section.add "X-Amz-Content-Sha256", valid_601417
  var valid_601418 = header.getOrDefault("X-Amz-Algorithm")
  valid_601418 = validateParameter(valid_601418, JString, required = false,
                                 default = nil)
  if valid_601418 != nil:
    section.add "X-Amz-Algorithm", valid_601418
  var valid_601419 = header.getOrDefault("X-Amz-Signature")
  valid_601419 = validateParameter(valid_601419, JString, required = false,
                                 default = nil)
  if valid_601419 != nil:
    section.add "X-Amz-Signature", valid_601419
  var valid_601420 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601420 = validateParameter(valid_601420, JString, required = false,
                                 default = nil)
  if valid_601420 != nil:
    section.add "X-Amz-SignedHeaders", valid_601420
  var valid_601421 = header.getOrDefault("X-Amz-Credential")
  valid_601421 = validateParameter(valid_601421, JString, required = false,
                                 default = nil)
  if valid_601421 != nil:
    section.add "X-Amz-Credential", valid_601421
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
  var valid_601422 = formData.getOrDefault("PlatformName")
  valid_601422 = validateParameter(valid_601422, JString, required = true,
                                 default = nil)
  if valid_601422 != nil:
    section.add "PlatformName", valid_601422
  var valid_601423 = formData.getOrDefault("PlatformDefinitionBundle.S3Key")
  valid_601423 = validateParameter(valid_601423, JString, required = false,
                                 default = nil)
  if valid_601423 != nil:
    section.add "PlatformDefinitionBundle.S3Key", valid_601423
  var valid_601424 = formData.getOrDefault("OptionSettings")
  valid_601424 = validateParameter(valid_601424, JArray, required = false,
                                 default = nil)
  if valid_601424 != nil:
    section.add "OptionSettings", valid_601424
  var valid_601425 = formData.getOrDefault("Tags")
  valid_601425 = validateParameter(valid_601425, JArray, required = false,
                                 default = nil)
  if valid_601425 != nil:
    section.add "Tags", valid_601425
  var valid_601426 = formData.getOrDefault("EnvironmentName")
  valid_601426 = validateParameter(valid_601426, JString, required = false,
                                 default = nil)
  if valid_601426 != nil:
    section.add "EnvironmentName", valid_601426
  var valid_601427 = formData.getOrDefault("PlatformDefinitionBundle.S3Bucket")
  valid_601427 = validateParameter(valid_601427, JString, required = false,
                                 default = nil)
  if valid_601427 != nil:
    section.add "PlatformDefinitionBundle.S3Bucket", valid_601427
  var valid_601428 = formData.getOrDefault("PlatformVersion")
  valid_601428 = validateParameter(valid_601428, JString, required = true,
                                 default = nil)
  if valid_601428 != nil:
    section.add "PlatformVersion", valid_601428
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601429: Call_PostCreatePlatformVersion_601410; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new version of your custom platform.
  ## 
  let valid = call_601429.validator(path, query, header, formData, body)
  let scheme = call_601429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601429.url(scheme.get, call_601429.host, call_601429.base,
                         call_601429.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601429, url, valid)

proc call*(call_601430: Call_PostCreatePlatformVersion_601410;
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
  var query_601431 = newJObject()
  var formData_601432 = newJObject()
  add(formData_601432, "PlatformName", newJString(PlatformName))
  add(formData_601432, "PlatformDefinitionBundle.S3Key",
      newJString(PlatformDefinitionBundleS3Key))
  if OptionSettings != nil:
    formData_601432.add "OptionSettings", OptionSettings
  if Tags != nil:
    formData_601432.add "Tags", Tags
  add(formData_601432, "EnvironmentName", newJString(EnvironmentName))
  add(formData_601432, "PlatformDefinitionBundle.S3Bucket",
      newJString(PlatformDefinitionBundleS3Bucket))
  add(query_601431, "Action", newJString(Action))
  add(formData_601432, "PlatformVersion", newJString(PlatformVersion))
  add(query_601431, "Version", newJString(Version))
  result = call_601430.call(nil, query_601431, nil, formData_601432, nil)

var postCreatePlatformVersion* = Call_PostCreatePlatformVersion_601410(
    name: "postCreatePlatformVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreatePlatformVersion",
    validator: validate_PostCreatePlatformVersion_601411, base: "/",
    url: url_PostCreatePlatformVersion_601412,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreatePlatformVersion_601388 = ref object of OpenApiRestCall_600438
proc url_GetCreatePlatformVersion_601390(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreatePlatformVersion_601389(path: JsonNode; query: JsonNode;
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
  var valid_601391 = query.getOrDefault("Tags")
  valid_601391 = validateParameter(valid_601391, JArray, required = false,
                                 default = nil)
  if valid_601391 != nil:
    section.add "Tags", valid_601391
  var valid_601392 = query.getOrDefault("EnvironmentName")
  valid_601392 = validateParameter(valid_601392, JString, required = false,
                                 default = nil)
  if valid_601392 != nil:
    section.add "EnvironmentName", valid_601392
  var valid_601393 = query.getOrDefault("PlatformDefinitionBundle.S3Key")
  valid_601393 = validateParameter(valid_601393, JString, required = false,
                                 default = nil)
  if valid_601393 != nil:
    section.add "PlatformDefinitionBundle.S3Key", valid_601393
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601394 = query.getOrDefault("Action")
  valid_601394 = validateParameter(valid_601394, JString, required = true,
                                 default = newJString("CreatePlatformVersion"))
  if valid_601394 != nil:
    section.add "Action", valid_601394
  var valid_601395 = query.getOrDefault("OptionSettings")
  valid_601395 = validateParameter(valid_601395, JArray, required = false,
                                 default = nil)
  if valid_601395 != nil:
    section.add "OptionSettings", valid_601395
  var valid_601396 = query.getOrDefault("PlatformName")
  valid_601396 = validateParameter(valid_601396, JString, required = true,
                                 default = nil)
  if valid_601396 != nil:
    section.add "PlatformName", valid_601396
  var valid_601397 = query.getOrDefault("Version")
  valid_601397 = validateParameter(valid_601397, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601397 != nil:
    section.add "Version", valid_601397
  var valid_601398 = query.getOrDefault("PlatformDefinitionBundle.S3Bucket")
  valid_601398 = validateParameter(valid_601398, JString, required = false,
                                 default = nil)
  if valid_601398 != nil:
    section.add "PlatformDefinitionBundle.S3Bucket", valid_601398
  var valid_601399 = query.getOrDefault("PlatformVersion")
  valid_601399 = validateParameter(valid_601399, JString, required = true,
                                 default = nil)
  if valid_601399 != nil:
    section.add "PlatformVersion", valid_601399
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601400 = header.getOrDefault("X-Amz-Date")
  valid_601400 = validateParameter(valid_601400, JString, required = false,
                                 default = nil)
  if valid_601400 != nil:
    section.add "X-Amz-Date", valid_601400
  var valid_601401 = header.getOrDefault("X-Amz-Security-Token")
  valid_601401 = validateParameter(valid_601401, JString, required = false,
                                 default = nil)
  if valid_601401 != nil:
    section.add "X-Amz-Security-Token", valid_601401
  var valid_601402 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601402 = validateParameter(valid_601402, JString, required = false,
                                 default = nil)
  if valid_601402 != nil:
    section.add "X-Amz-Content-Sha256", valid_601402
  var valid_601403 = header.getOrDefault("X-Amz-Algorithm")
  valid_601403 = validateParameter(valid_601403, JString, required = false,
                                 default = nil)
  if valid_601403 != nil:
    section.add "X-Amz-Algorithm", valid_601403
  var valid_601404 = header.getOrDefault("X-Amz-Signature")
  valid_601404 = validateParameter(valid_601404, JString, required = false,
                                 default = nil)
  if valid_601404 != nil:
    section.add "X-Amz-Signature", valid_601404
  var valid_601405 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601405 = validateParameter(valid_601405, JString, required = false,
                                 default = nil)
  if valid_601405 != nil:
    section.add "X-Amz-SignedHeaders", valid_601405
  var valid_601406 = header.getOrDefault("X-Amz-Credential")
  valid_601406 = validateParameter(valid_601406, JString, required = false,
                                 default = nil)
  if valid_601406 != nil:
    section.add "X-Amz-Credential", valid_601406
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601407: Call_GetCreatePlatformVersion_601388; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new version of your custom platform.
  ## 
  let valid = call_601407.validator(path, query, header, formData, body)
  let scheme = call_601407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601407.url(scheme.get, call_601407.host, call_601407.base,
                         call_601407.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601407, url, valid)

proc call*(call_601408: Call_GetCreatePlatformVersion_601388; PlatformName: string;
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
  var query_601409 = newJObject()
  if Tags != nil:
    query_601409.add "Tags", Tags
  add(query_601409, "EnvironmentName", newJString(EnvironmentName))
  add(query_601409, "PlatformDefinitionBundle.S3Key",
      newJString(PlatformDefinitionBundleS3Key))
  add(query_601409, "Action", newJString(Action))
  if OptionSettings != nil:
    query_601409.add "OptionSettings", OptionSettings
  add(query_601409, "PlatformName", newJString(PlatformName))
  add(query_601409, "Version", newJString(Version))
  add(query_601409, "PlatformDefinitionBundle.S3Bucket",
      newJString(PlatformDefinitionBundleS3Bucket))
  add(query_601409, "PlatformVersion", newJString(PlatformVersion))
  result = call_601408.call(nil, query_601409, nil, nil, nil)

var getCreatePlatformVersion* = Call_GetCreatePlatformVersion_601388(
    name: "getCreatePlatformVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreatePlatformVersion",
    validator: validate_GetCreatePlatformVersion_601389, base: "/",
    url: url_GetCreatePlatformVersion_601390, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateStorageLocation_601448 = ref object of OpenApiRestCall_600438
proc url_PostCreateStorageLocation_601450(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateStorageLocation_601449(path: JsonNode; query: JsonNode;
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
  var valid_601451 = query.getOrDefault("Action")
  valid_601451 = validateParameter(valid_601451, JString, required = true,
                                 default = newJString("CreateStorageLocation"))
  if valid_601451 != nil:
    section.add "Action", valid_601451
  var valid_601452 = query.getOrDefault("Version")
  valid_601452 = validateParameter(valid_601452, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601452 != nil:
    section.add "Version", valid_601452
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601453 = header.getOrDefault("X-Amz-Date")
  valid_601453 = validateParameter(valid_601453, JString, required = false,
                                 default = nil)
  if valid_601453 != nil:
    section.add "X-Amz-Date", valid_601453
  var valid_601454 = header.getOrDefault("X-Amz-Security-Token")
  valid_601454 = validateParameter(valid_601454, JString, required = false,
                                 default = nil)
  if valid_601454 != nil:
    section.add "X-Amz-Security-Token", valid_601454
  var valid_601455 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601455 = validateParameter(valid_601455, JString, required = false,
                                 default = nil)
  if valid_601455 != nil:
    section.add "X-Amz-Content-Sha256", valid_601455
  var valid_601456 = header.getOrDefault("X-Amz-Algorithm")
  valid_601456 = validateParameter(valid_601456, JString, required = false,
                                 default = nil)
  if valid_601456 != nil:
    section.add "X-Amz-Algorithm", valid_601456
  var valid_601457 = header.getOrDefault("X-Amz-Signature")
  valid_601457 = validateParameter(valid_601457, JString, required = false,
                                 default = nil)
  if valid_601457 != nil:
    section.add "X-Amz-Signature", valid_601457
  var valid_601458 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601458 = validateParameter(valid_601458, JString, required = false,
                                 default = nil)
  if valid_601458 != nil:
    section.add "X-Amz-SignedHeaders", valid_601458
  var valid_601459 = header.getOrDefault("X-Amz-Credential")
  valid_601459 = validateParameter(valid_601459, JString, required = false,
                                 default = nil)
  if valid_601459 != nil:
    section.add "X-Amz-Credential", valid_601459
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601460: Call_PostCreateStorageLocation_601448; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ## 
  let valid = call_601460.validator(path, query, header, formData, body)
  let scheme = call_601460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601460.url(scheme.get, call_601460.host, call_601460.base,
                         call_601460.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601460, url, valid)

proc call*(call_601461: Call_PostCreateStorageLocation_601448;
          Action: string = "CreateStorageLocation"; Version: string = "2010-12-01"): Recallable =
  ## postCreateStorageLocation
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601462 = newJObject()
  add(query_601462, "Action", newJString(Action))
  add(query_601462, "Version", newJString(Version))
  result = call_601461.call(nil, query_601462, nil, nil, nil)

var postCreateStorageLocation* = Call_PostCreateStorageLocation_601448(
    name: "postCreateStorageLocation", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateStorageLocation",
    validator: validate_PostCreateStorageLocation_601449, base: "/",
    url: url_PostCreateStorageLocation_601450,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateStorageLocation_601433 = ref object of OpenApiRestCall_600438
proc url_GetCreateStorageLocation_601435(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateStorageLocation_601434(path: JsonNode; query: JsonNode;
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
  var valid_601436 = query.getOrDefault("Action")
  valid_601436 = validateParameter(valid_601436, JString, required = true,
                                 default = newJString("CreateStorageLocation"))
  if valid_601436 != nil:
    section.add "Action", valid_601436
  var valid_601437 = query.getOrDefault("Version")
  valid_601437 = validateParameter(valid_601437, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601437 != nil:
    section.add "Version", valid_601437
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601438 = header.getOrDefault("X-Amz-Date")
  valid_601438 = validateParameter(valid_601438, JString, required = false,
                                 default = nil)
  if valid_601438 != nil:
    section.add "X-Amz-Date", valid_601438
  var valid_601439 = header.getOrDefault("X-Amz-Security-Token")
  valid_601439 = validateParameter(valid_601439, JString, required = false,
                                 default = nil)
  if valid_601439 != nil:
    section.add "X-Amz-Security-Token", valid_601439
  var valid_601440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601440 = validateParameter(valid_601440, JString, required = false,
                                 default = nil)
  if valid_601440 != nil:
    section.add "X-Amz-Content-Sha256", valid_601440
  var valid_601441 = header.getOrDefault("X-Amz-Algorithm")
  valid_601441 = validateParameter(valid_601441, JString, required = false,
                                 default = nil)
  if valid_601441 != nil:
    section.add "X-Amz-Algorithm", valid_601441
  var valid_601442 = header.getOrDefault("X-Amz-Signature")
  valid_601442 = validateParameter(valid_601442, JString, required = false,
                                 default = nil)
  if valid_601442 != nil:
    section.add "X-Amz-Signature", valid_601442
  var valid_601443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601443 = validateParameter(valid_601443, JString, required = false,
                                 default = nil)
  if valid_601443 != nil:
    section.add "X-Amz-SignedHeaders", valid_601443
  var valid_601444 = header.getOrDefault("X-Amz-Credential")
  valid_601444 = validateParameter(valid_601444, JString, required = false,
                                 default = nil)
  if valid_601444 != nil:
    section.add "X-Amz-Credential", valid_601444
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601445: Call_GetCreateStorageLocation_601433; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ## 
  let valid = call_601445.validator(path, query, header, formData, body)
  let scheme = call_601445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601445.url(scheme.get, call_601445.host, call_601445.base,
                         call_601445.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601445, url, valid)

proc call*(call_601446: Call_GetCreateStorageLocation_601433;
          Action: string = "CreateStorageLocation"; Version: string = "2010-12-01"): Recallable =
  ## getCreateStorageLocation
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601447 = newJObject()
  add(query_601447, "Action", newJString(Action))
  add(query_601447, "Version", newJString(Version))
  result = call_601446.call(nil, query_601447, nil, nil, nil)

var getCreateStorageLocation* = Call_GetCreateStorageLocation_601433(
    name: "getCreateStorageLocation", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateStorageLocation",
    validator: validate_GetCreateStorageLocation_601434, base: "/",
    url: url_GetCreateStorageLocation_601435, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteApplication_601480 = ref object of OpenApiRestCall_600438
proc url_PostDeleteApplication_601482(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteApplication_601481(path: JsonNode; query: JsonNode;
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
  var valid_601483 = query.getOrDefault("Action")
  valid_601483 = validateParameter(valid_601483, JString, required = true,
                                 default = newJString("DeleteApplication"))
  if valid_601483 != nil:
    section.add "Action", valid_601483
  var valid_601484 = query.getOrDefault("Version")
  valid_601484 = validateParameter(valid_601484, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601484 != nil:
    section.add "Version", valid_601484
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601485 = header.getOrDefault("X-Amz-Date")
  valid_601485 = validateParameter(valid_601485, JString, required = false,
                                 default = nil)
  if valid_601485 != nil:
    section.add "X-Amz-Date", valid_601485
  var valid_601486 = header.getOrDefault("X-Amz-Security-Token")
  valid_601486 = validateParameter(valid_601486, JString, required = false,
                                 default = nil)
  if valid_601486 != nil:
    section.add "X-Amz-Security-Token", valid_601486
  var valid_601487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601487 = validateParameter(valid_601487, JString, required = false,
                                 default = nil)
  if valid_601487 != nil:
    section.add "X-Amz-Content-Sha256", valid_601487
  var valid_601488 = header.getOrDefault("X-Amz-Algorithm")
  valid_601488 = validateParameter(valid_601488, JString, required = false,
                                 default = nil)
  if valid_601488 != nil:
    section.add "X-Amz-Algorithm", valid_601488
  var valid_601489 = header.getOrDefault("X-Amz-Signature")
  valid_601489 = validateParameter(valid_601489, JString, required = false,
                                 default = nil)
  if valid_601489 != nil:
    section.add "X-Amz-Signature", valid_601489
  var valid_601490 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601490 = validateParameter(valid_601490, JString, required = false,
                                 default = nil)
  if valid_601490 != nil:
    section.add "X-Amz-SignedHeaders", valid_601490
  var valid_601491 = header.getOrDefault("X-Amz-Credential")
  valid_601491 = validateParameter(valid_601491, JString, required = false,
                                 default = nil)
  if valid_601491 != nil:
    section.add "X-Amz-Credential", valid_601491
  result.add "header", section
  ## parameters in `formData` object:
  ##   TerminateEnvByForce: JBool
  ##                      : When set to true, running environments will be terminated before deleting the application.
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to delete.
  section = newJObject()
  var valid_601492 = formData.getOrDefault("TerminateEnvByForce")
  valid_601492 = validateParameter(valid_601492, JBool, required = false, default = nil)
  if valid_601492 != nil:
    section.add "TerminateEnvByForce", valid_601492
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_601493 = formData.getOrDefault("ApplicationName")
  valid_601493 = validateParameter(valid_601493, JString, required = true,
                                 default = nil)
  if valid_601493 != nil:
    section.add "ApplicationName", valid_601493
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601494: Call_PostDeleteApplication_601480; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified application along with all associated versions and configurations. The application versions will not be deleted from your Amazon S3 bucket.</p> <note> <p>You cannot delete an application that has a running environment.</p> </note>
  ## 
  let valid = call_601494.validator(path, query, header, formData, body)
  let scheme = call_601494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601494.url(scheme.get, call_601494.host, call_601494.base,
                         call_601494.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601494, url, valid)

proc call*(call_601495: Call_PostDeleteApplication_601480; ApplicationName: string;
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
  var query_601496 = newJObject()
  var formData_601497 = newJObject()
  add(formData_601497, "TerminateEnvByForce", newJBool(TerminateEnvByForce))
  add(query_601496, "Action", newJString(Action))
  add(formData_601497, "ApplicationName", newJString(ApplicationName))
  add(query_601496, "Version", newJString(Version))
  result = call_601495.call(nil, query_601496, nil, formData_601497, nil)

var postDeleteApplication* = Call_PostDeleteApplication_601480(
    name: "postDeleteApplication", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=DeleteApplication",
    validator: validate_PostDeleteApplication_601481, base: "/",
    url: url_PostDeleteApplication_601482, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteApplication_601463 = ref object of OpenApiRestCall_600438
proc url_GetDeleteApplication_601465(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteApplication_601464(path: JsonNode; query: JsonNode;
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
  var valid_601466 = query.getOrDefault("TerminateEnvByForce")
  valid_601466 = validateParameter(valid_601466, JBool, required = false, default = nil)
  if valid_601466 != nil:
    section.add "TerminateEnvByForce", valid_601466
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_601467 = query.getOrDefault("ApplicationName")
  valid_601467 = validateParameter(valid_601467, JString, required = true,
                                 default = nil)
  if valid_601467 != nil:
    section.add "ApplicationName", valid_601467
  var valid_601468 = query.getOrDefault("Action")
  valid_601468 = validateParameter(valid_601468, JString, required = true,
                                 default = newJString("DeleteApplication"))
  if valid_601468 != nil:
    section.add "Action", valid_601468
  var valid_601469 = query.getOrDefault("Version")
  valid_601469 = validateParameter(valid_601469, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601469 != nil:
    section.add "Version", valid_601469
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601470 = header.getOrDefault("X-Amz-Date")
  valid_601470 = validateParameter(valid_601470, JString, required = false,
                                 default = nil)
  if valid_601470 != nil:
    section.add "X-Amz-Date", valid_601470
  var valid_601471 = header.getOrDefault("X-Amz-Security-Token")
  valid_601471 = validateParameter(valid_601471, JString, required = false,
                                 default = nil)
  if valid_601471 != nil:
    section.add "X-Amz-Security-Token", valid_601471
  var valid_601472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601472 = validateParameter(valid_601472, JString, required = false,
                                 default = nil)
  if valid_601472 != nil:
    section.add "X-Amz-Content-Sha256", valid_601472
  var valid_601473 = header.getOrDefault("X-Amz-Algorithm")
  valid_601473 = validateParameter(valid_601473, JString, required = false,
                                 default = nil)
  if valid_601473 != nil:
    section.add "X-Amz-Algorithm", valid_601473
  var valid_601474 = header.getOrDefault("X-Amz-Signature")
  valid_601474 = validateParameter(valid_601474, JString, required = false,
                                 default = nil)
  if valid_601474 != nil:
    section.add "X-Amz-Signature", valid_601474
  var valid_601475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601475 = validateParameter(valid_601475, JString, required = false,
                                 default = nil)
  if valid_601475 != nil:
    section.add "X-Amz-SignedHeaders", valid_601475
  var valid_601476 = header.getOrDefault("X-Amz-Credential")
  valid_601476 = validateParameter(valid_601476, JString, required = false,
                                 default = nil)
  if valid_601476 != nil:
    section.add "X-Amz-Credential", valid_601476
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601477: Call_GetDeleteApplication_601463; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified application along with all associated versions and configurations. The application versions will not be deleted from your Amazon S3 bucket.</p> <note> <p>You cannot delete an application that has a running environment.</p> </note>
  ## 
  let valid = call_601477.validator(path, query, header, formData, body)
  let scheme = call_601477.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601477.url(scheme.get, call_601477.host, call_601477.base,
                         call_601477.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601477, url, valid)

proc call*(call_601478: Call_GetDeleteApplication_601463; ApplicationName: string;
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
  var query_601479 = newJObject()
  add(query_601479, "TerminateEnvByForce", newJBool(TerminateEnvByForce))
  add(query_601479, "ApplicationName", newJString(ApplicationName))
  add(query_601479, "Action", newJString(Action))
  add(query_601479, "Version", newJString(Version))
  result = call_601478.call(nil, query_601479, nil, nil, nil)

var getDeleteApplication* = Call_GetDeleteApplication_601463(
    name: "getDeleteApplication", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=DeleteApplication",
    validator: validate_GetDeleteApplication_601464, base: "/",
    url: url_GetDeleteApplication_601465, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteApplicationVersion_601516 = ref object of OpenApiRestCall_600438
proc url_PostDeleteApplicationVersion_601518(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteApplicationVersion_601517(path: JsonNode; query: JsonNode;
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
  var valid_601519 = query.getOrDefault("Action")
  valid_601519 = validateParameter(valid_601519, JString, required = true, default = newJString(
      "DeleteApplicationVersion"))
  if valid_601519 != nil:
    section.add "Action", valid_601519
  var valid_601520 = query.getOrDefault("Version")
  valid_601520 = validateParameter(valid_601520, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601520 != nil:
    section.add "Version", valid_601520
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601521 = header.getOrDefault("X-Amz-Date")
  valid_601521 = validateParameter(valid_601521, JString, required = false,
                                 default = nil)
  if valid_601521 != nil:
    section.add "X-Amz-Date", valid_601521
  var valid_601522 = header.getOrDefault("X-Amz-Security-Token")
  valid_601522 = validateParameter(valid_601522, JString, required = false,
                                 default = nil)
  if valid_601522 != nil:
    section.add "X-Amz-Security-Token", valid_601522
  var valid_601523 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601523 = validateParameter(valid_601523, JString, required = false,
                                 default = nil)
  if valid_601523 != nil:
    section.add "X-Amz-Content-Sha256", valid_601523
  var valid_601524 = header.getOrDefault("X-Amz-Algorithm")
  valid_601524 = validateParameter(valid_601524, JString, required = false,
                                 default = nil)
  if valid_601524 != nil:
    section.add "X-Amz-Algorithm", valid_601524
  var valid_601525 = header.getOrDefault("X-Amz-Signature")
  valid_601525 = validateParameter(valid_601525, JString, required = false,
                                 default = nil)
  if valid_601525 != nil:
    section.add "X-Amz-Signature", valid_601525
  var valid_601526 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601526 = validateParameter(valid_601526, JString, required = false,
                                 default = nil)
  if valid_601526 != nil:
    section.add "X-Amz-SignedHeaders", valid_601526
  var valid_601527 = header.getOrDefault("X-Amz-Credential")
  valid_601527 = validateParameter(valid_601527, JString, required = false,
                                 default = nil)
  if valid_601527 != nil:
    section.add "X-Amz-Credential", valid_601527
  result.add "header", section
  ## parameters in `formData` object:
  ##   DeleteSourceBundle: JBool
  ##                     : Set to <code>true</code> to delete the source bundle from your storage bucket. Otherwise, the application version is deleted only from Elastic Beanstalk and the source bundle remains in Amazon S3.
  ##   VersionLabel: JString (required)
  ##               : The label of the version to delete.
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to which the version belongs.
  section = newJObject()
  var valid_601528 = formData.getOrDefault("DeleteSourceBundle")
  valid_601528 = validateParameter(valid_601528, JBool, required = false, default = nil)
  if valid_601528 != nil:
    section.add "DeleteSourceBundle", valid_601528
  assert formData != nil,
        "formData argument is necessary due to required `VersionLabel` field"
  var valid_601529 = formData.getOrDefault("VersionLabel")
  valid_601529 = validateParameter(valid_601529, JString, required = true,
                                 default = nil)
  if valid_601529 != nil:
    section.add "VersionLabel", valid_601529
  var valid_601530 = formData.getOrDefault("ApplicationName")
  valid_601530 = validateParameter(valid_601530, JString, required = true,
                                 default = nil)
  if valid_601530 != nil:
    section.add "ApplicationName", valid_601530
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601531: Call_PostDeleteApplicationVersion_601516; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified version from the specified application.</p> <note> <p>You cannot delete an application version that is associated with a running environment.</p> </note>
  ## 
  let valid = call_601531.validator(path, query, header, formData, body)
  let scheme = call_601531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601531.url(scheme.get, call_601531.host, call_601531.base,
                         call_601531.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601531, url, valid)

proc call*(call_601532: Call_PostDeleteApplicationVersion_601516;
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
  var query_601533 = newJObject()
  var formData_601534 = newJObject()
  add(formData_601534, "DeleteSourceBundle", newJBool(DeleteSourceBundle))
  add(formData_601534, "VersionLabel", newJString(VersionLabel))
  add(query_601533, "Action", newJString(Action))
  add(formData_601534, "ApplicationName", newJString(ApplicationName))
  add(query_601533, "Version", newJString(Version))
  result = call_601532.call(nil, query_601533, nil, formData_601534, nil)

var postDeleteApplicationVersion* = Call_PostDeleteApplicationVersion_601516(
    name: "postDeleteApplicationVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteApplicationVersion",
    validator: validate_PostDeleteApplicationVersion_601517, base: "/",
    url: url_PostDeleteApplicationVersion_601518,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteApplicationVersion_601498 = ref object of OpenApiRestCall_600438
proc url_GetDeleteApplicationVersion_601500(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteApplicationVersion_601499(path: JsonNode; query: JsonNode;
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
  var valid_601501 = query.getOrDefault("VersionLabel")
  valid_601501 = validateParameter(valid_601501, JString, required = true,
                                 default = nil)
  if valid_601501 != nil:
    section.add "VersionLabel", valid_601501
  var valid_601502 = query.getOrDefault("ApplicationName")
  valid_601502 = validateParameter(valid_601502, JString, required = true,
                                 default = nil)
  if valid_601502 != nil:
    section.add "ApplicationName", valid_601502
  var valid_601503 = query.getOrDefault("Action")
  valid_601503 = validateParameter(valid_601503, JString, required = true, default = newJString(
      "DeleteApplicationVersion"))
  if valid_601503 != nil:
    section.add "Action", valid_601503
  var valid_601504 = query.getOrDefault("DeleteSourceBundle")
  valid_601504 = validateParameter(valid_601504, JBool, required = false, default = nil)
  if valid_601504 != nil:
    section.add "DeleteSourceBundle", valid_601504
  var valid_601505 = query.getOrDefault("Version")
  valid_601505 = validateParameter(valid_601505, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601505 != nil:
    section.add "Version", valid_601505
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601506 = header.getOrDefault("X-Amz-Date")
  valid_601506 = validateParameter(valid_601506, JString, required = false,
                                 default = nil)
  if valid_601506 != nil:
    section.add "X-Amz-Date", valid_601506
  var valid_601507 = header.getOrDefault("X-Amz-Security-Token")
  valid_601507 = validateParameter(valid_601507, JString, required = false,
                                 default = nil)
  if valid_601507 != nil:
    section.add "X-Amz-Security-Token", valid_601507
  var valid_601508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601508 = validateParameter(valid_601508, JString, required = false,
                                 default = nil)
  if valid_601508 != nil:
    section.add "X-Amz-Content-Sha256", valid_601508
  var valid_601509 = header.getOrDefault("X-Amz-Algorithm")
  valid_601509 = validateParameter(valid_601509, JString, required = false,
                                 default = nil)
  if valid_601509 != nil:
    section.add "X-Amz-Algorithm", valid_601509
  var valid_601510 = header.getOrDefault("X-Amz-Signature")
  valid_601510 = validateParameter(valid_601510, JString, required = false,
                                 default = nil)
  if valid_601510 != nil:
    section.add "X-Amz-Signature", valid_601510
  var valid_601511 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601511 = validateParameter(valid_601511, JString, required = false,
                                 default = nil)
  if valid_601511 != nil:
    section.add "X-Amz-SignedHeaders", valid_601511
  var valid_601512 = header.getOrDefault("X-Amz-Credential")
  valid_601512 = validateParameter(valid_601512, JString, required = false,
                                 default = nil)
  if valid_601512 != nil:
    section.add "X-Amz-Credential", valid_601512
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601513: Call_GetDeleteApplicationVersion_601498; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified version from the specified application.</p> <note> <p>You cannot delete an application version that is associated with a running environment.</p> </note>
  ## 
  let valid = call_601513.validator(path, query, header, formData, body)
  let scheme = call_601513.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601513.url(scheme.get, call_601513.host, call_601513.base,
                         call_601513.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601513, url, valid)

proc call*(call_601514: Call_GetDeleteApplicationVersion_601498;
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
  var query_601515 = newJObject()
  add(query_601515, "VersionLabel", newJString(VersionLabel))
  add(query_601515, "ApplicationName", newJString(ApplicationName))
  add(query_601515, "Action", newJString(Action))
  add(query_601515, "DeleteSourceBundle", newJBool(DeleteSourceBundle))
  add(query_601515, "Version", newJString(Version))
  result = call_601514.call(nil, query_601515, nil, nil, nil)

var getDeleteApplicationVersion* = Call_GetDeleteApplicationVersion_601498(
    name: "getDeleteApplicationVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteApplicationVersion",
    validator: validate_GetDeleteApplicationVersion_601499, base: "/",
    url: url_GetDeleteApplicationVersion_601500,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteConfigurationTemplate_601552 = ref object of OpenApiRestCall_600438
proc url_PostDeleteConfigurationTemplate_601554(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteConfigurationTemplate_601553(path: JsonNode;
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
  var valid_601555 = query.getOrDefault("Action")
  valid_601555 = validateParameter(valid_601555, JString, required = true, default = newJString(
      "DeleteConfigurationTemplate"))
  if valid_601555 != nil:
    section.add "Action", valid_601555
  var valid_601556 = query.getOrDefault("Version")
  valid_601556 = validateParameter(valid_601556, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601556 != nil:
    section.add "Version", valid_601556
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601557 = header.getOrDefault("X-Amz-Date")
  valid_601557 = validateParameter(valid_601557, JString, required = false,
                                 default = nil)
  if valid_601557 != nil:
    section.add "X-Amz-Date", valid_601557
  var valid_601558 = header.getOrDefault("X-Amz-Security-Token")
  valid_601558 = validateParameter(valid_601558, JString, required = false,
                                 default = nil)
  if valid_601558 != nil:
    section.add "X-Amz-Security-Token", valid_601558
  var valid_601559 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601559 = validateParameter(valid_601559, JString, required = false,
                                 default = nil)
  if valid_601559 != nil:
    section.add "X-Amz-Content-Sha256", valid_601559
  var valid_601560 = header.getOrDefault("X-Amz-Algorithm")
  valid_601560 = validateParameter(valid_601560, JString, required = false,
                                 default = nil)
  if valid_601560 != nil:
    section.add "X-Amz-Algorithm", valid_601560
  var valid_601561 = header.getOrDefault("X-Amz-Signature")
  valid_601561 = validateParameter(valid_601561, JString, required = false,
                                 default = nil)
  if valid_601561 != nil:
    section.add "X-Amz-Signature", valid_601561
  var valid_601562 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601562 = validateParameter(valid_601562, JString, required = false,
                                 default = nil)
  if valid_601562 != nil:
    section.add "X-Amz-SignedHeaders", valid_601562
  var valid_601563 = header.getOrDefault("X-Amz-Credential")
  valid_601563 = validateParameter(valid_601563, JString, required = false,
                                 default = nil)
  if valid_601563 != nil:
    section.add "X-Amz-Credential", valid_601563
  result.add "header", section
  ## parameters in `formData` object:
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to delete the configuration template from.
  ##   TemplateName: JString (required)
  ##               : The name of the configuration template to delete.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_601564 = formData.getOrDefault("ApplicationName")
  valid_601564 = validateParameter(valid_601564, JString, required = true,
                                 default = nil)
  if valid_601564 != nil:
    section.add "ApplicationName", valid_601564
  var valid_601565 = formData.getOrDefault("TemplateName")
  valid_601565 = validateParameter(valid_601565, JString, required = true,
                                 default = nil)
  if valid_601565 != nil:
    section.add "TemplateName", valid_601565
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601566: Call_PostDeleteConfigurationTemplate_601552;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes the specified configuration template.</p> <note> <p>When you launch an environment using a configuration template, the environment gets a copy of the template. You can delete or modify the environment's copy of the template without affecting the running environment.</p> </note>
  ## 
  let valid = call_601566.validator(path, query, header, formData, body)
  let scheme = call_601566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601566.url(scheme.get, call_601566.host, call_601566.base,
                         call_601566.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601566, url, valid)

proc call*(call_601567: Call_PostDeleteConfigurationTemplate_601552;
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
  var query_601568 = newJObject()
  var formData_601569 = newJObject()
  add(query_601568, "Action", newJString(Action))
  add(formData_601569, "ApplicationName", newJString(ApplicationName))
  add(formData_601569, "TemplateName", newJString(TemplateName))
  add(query_601568, "Version", newJString(Version))
  result = call_601567.call(nil, query_601568, nil, formData_601569, nil)

var postDeleteConfigurationTemplate* = Call_PostDeleteConfigurationTemplate_601552(
    name: "postDeleteConfigurationTemplate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteConfigurationTemplate",
    validator: validate_PostDeleteConfigurationTemplate_601553, base: "/",
    url: url_PostDeleteConfigurationTemplate_601554,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteConfigurationTemplate_601535 = ref object of OpenApiRestCall_600438
proc url_GetDeleteConfigurationTemplate_601537(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteConfigurationTemplate_601536(path: JsonNode;
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
  var valid_601538 = query.getOrDefault("ApplicationName")
  valid_601538 = validateParameter(valid_601538, JString, required = true,
                                 default = nil)
  if valid_601538 != nil:
    section.add "ApplicationName", valid_601538
  var valid_601539 = query.getOrDefault("Action")
  valid_601539 = validateParameter(valid_601539, JString, required = true, default = newJString(
      "DeleteConfigurationTemplate"))
  if valid_601539 != nil:
    section.add "Action", valid_601539
  var valid_601540 = query.getOrDefault("TemplateName")
  valid_601540 = validateParameter(valid_601540, JString, required = true,
                                 default = nil)
  if valid_601540 != nil:
    section.add "TemplateName", valid_601540
  var valid_601541 = query.getOrDefault("Version")
  valid_601541 = validateParameter(valid_601541, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601541 != nil:
    section.add "Version", valid_601541
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601542 = header.getOrDefault("X-Amz-Date")
  valid_601542 = validateParameter(valid_601542, JString, required = false,
                                 default = nil)
  if valid_601542 != nil:
    section.add "X-Amz-Date", valid_601542
  var valid_601543 = header.getOrDefault("X-Amz-Security-Token")
  valid_601543 = validateParameter(valid_601543, JString, required = false,
                                 default = nil)
  if valid_601543 != nil:
    section.add "X-Amz-Security-Token", valid_601543
  var valid_601544 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601544 = validateParameter(valid_601544, JString, required = false,
                                 default = nil)
  if valid_601544 != nil:
    section.add "X-Amz-Content-Sha256", valid_601544
  var valid_601545 = header.getOrDefault("X-Amz-Algorithm")
  valid_601545 = validateParameter(valid_601545, JString, required = false,
                                 default = nil)
  if valid_601545 != nil:
    section.add "X-Amz-Algorithm", valid_601545
  var valid_601546 = header.getOrDefault("X-Amz-Signature")
  valid_601546 = validateParameter(valid_601546, JString, required = false,
                                 default = nil)
  if valid_601546 != nil:
    section.add "X-Amz-Signature", valid_601546
  var valid_601547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601547 = validateParameter(valid_601547, JString, required = false,
                                 default = nil)
  if valid_601547 != nil:
    section.add "X-Amz-SignedHeaders", valid_601547
  var valid_601548 = header.getOrDefault("X-Amz-Credential")
  valid_601548 = validateParameter(valid_601548, JString, required = false,
                                 default = nil)
  if valid_601548 != nil:
    section.add "X-Amz-Credential", valid_601548
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601549: Call_GetDeleteConfigurationTemplate_601535; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified configuration template.</p> <note> <p>When you launch an environment using a configuration template, the environment gets a copy of the template. You can delete or modify the environment's copy of the template without affecting the running environment.</p> </note>
  ## 
  let valid = call_601549.validator(path, query, header, formData, body)
  let scheme = call_601549.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601549.url(scheme.get, call_601549.host, call_601549.base,
                         call_601549.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601549, url, valid)

proc call*(call_601550: Call_GetDeleteConfigurationTemplate_601535;
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
  var query_601551 = newJObject()
  add(query_601551, "ApplicationName", newJString(ApplicationName))
  add(query_601551, "Action", newJString(Action))
  add(query_601551, "TemplateName", newJString(TemplateName))
  add(query_601551, "Version", newJString(Version))
  result = call_601550.call(nil, query_601551, nil, nil, nil)

var getDeleteConfigurationTemplate* = Call_GetDeleteConfigurationTemplate_601535(
    name: "getDeleteConfigurationTemplate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteConfigurationTemplate",
    validator: validate_GetDeleteConfigurationTemplate_601536, base: "/",
    url: url_GetDeleteConfigurationTemplate_601537,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEnvironmentConfiguration_601587 = ref object of OpenApiRestCall_600438
proc url_PostDeleteEnvironmentConfiguration_601589(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteEnvironmentConfiguration_601588(path: JsonNode;
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
  var valid_601590 = query.getOrDefault("Action")
  valid_601590 = validateParameter(valid_601590, JString, required = true, default = newJString(
      "DeleteEnvironmentConfiguration"))
  if valid_601590 != nil:
    section.add "Action", valid_601590
  var valid_601591 = query.getOrDefault("Version")
  valid_601591 = validateParameter(valid_601591, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601591 != nil:
    section.add "Version", valid_601591
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601592 = header.getOrDefault("X-Amz-Date")
  valid_601592 = validateParameter(valid_601592, JString, required = false,
                                 default = nil)
  if valid_601592 != nil:
    section.add "X-Amz-Date", valid_601592
  var valid_601593 = header.getOrDefault("X-Amz-Security-Token")
  valid_601593 = validateParameter(valid_601593, JString, required = false,
                                 default = nil)
  if valid_601593 != nil:
    section.add "X-Amz-Security-Token", valid_601593
  var valid_601594 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601594 = validateParameter(valid_601594, JString, required = false,
                                 default = nil)
  if valid_601594 != nil:
    section.add "X-Amz-Content-Sha256", valid_601594
  var valid_601595 = header.getOrDefault("X-Amz-Algorithm")
  valid_601595 = validateParameter(valid_601595, JString, required = false,
                                 default = nil)
  if valid_601595 != nil:
    section.add "X-Amz-Algorithm", valid_601595
  var valid_601596 = header.getOrDefault("X-Amz-Signature")
  valid_601596 = validateParameter(valid_601596, JString, required = false,
                                 default = nil)
  if valid_601596 != nil:
    section.add "X-Amz-Signature", valid_601596
  var valid_601597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601597 = validateParameter(valid_601597, JString, required = false,
                                 default = nil)
  if valid_601597 != nil:
    section.add "X-Amz-SignedHeaders", valid_601597
  var valid_601598 = header.getOrDefault("X-Amz-Credential")
  valid_601598 = validateParameter(valid_601598, JString, required = false,
                                 default = nil)
  if valid_601598 != nil:
    section.add "X-Amz-Credential", valid_601598
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString (required)
  ##                  : The name of the environment to delete the draft configuration from.
  ##   ApplicationName: JString (required)
  ##                  : The name of the application the environment is associated with.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `EnvironmentName` field"
  var valid_601599 = formData.getOrDefault("EnvironmentName")
  valid_601599 = validateParameter(valid_601599, JString, required = true,
                                 default = nil)
  if valid_601599 != nil:
    section.add "EnvironmentName", valid_601599
  var valid_601600 = formData.getOrDefault("ApplicationName")
  valid_601600 = validateParameter(valid_601600, JString, required = true,
                                 default = nil)
  if valid_601600 != nil:
    section.add "ApplicationName", valid_601600
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601601: Call_PostDeleteEnvironmentConfiguration_601587;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes the draft configuration associated with the running environment.</p> <p>Updating a running environment with any configuration changes creates a draft configuration set. You can get the draft configuration using <a>DescribeConfigurationSettings</a> while the update is in progress or if the update fails. The <code>DeploymentStatus</code> for the draft configuration indicates whether the deployment is in process or has failed. The draft configuration remains in existence until it is deleted with this action.</p>
  ## 
  let valid = call_601601.validator(path, query, header, formData, body)
  let scheme = call_601601.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601601.url(scheme.get, call_601601.host, call_601601.base,
                         call_601601.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601601, url, valid)

proc call*(call_601602: Call_PostDeleteEnvironmentConfiguration_601587;
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
  var query_601603 = newJObject()
  var formData_601604 = newJObject()
  add(formData_601604, "EnvironmentName", newJString(EnvironmentName))
  add(query_601603, "Action", newJString(Action))
  add(formData_601604, "ApplicationName", newJString(ApplicationName))
  add(query_601603, "Version", newJString(Version))
  result = call_601602.call(nil, query_601603, nil, formData_601604, nil)

var postDeleteEnvironmentConfiguration* = Call_PostDeleteEnvironmentConfiguration_601587(
    name: "postDeleteEnvironmentConfiguration", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteEnvironmentConfiguration",
    validator: validate_PostDeleteEnvironmentConfiguration_601588, base: "/",
    url: url_PostDeleteEnvironmentConfiguration_601589,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEnvironmentConfiguration_601570 = ref object of OpenApiRestCall_600438
proc url_GetDeleteEnvironmentConfiguration_601572(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteEnvironmentConfiguration_601571(path: JsonNode;
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
  var valid_601573 = query.getOrDefault("ApplicationName")
  valid_601573 = validateParameter(valid_601573, JString, required = true,
                                 default = nil)
  if valid_601573 != nil:
    section.add "ApplicationName", valid_601573
  var valid_601574 = query.getOrDefault("EnvironmentName")
  valid_601574 = validateParameter(valid_601574, JString, required = true,
                                 default = nil)
  if valid_601574 != nil:
    section.add "EnvironmentName", valid_601574
  var valid_601575 = query.getOrDefault("Action")
  valid_601575 = validateParameter(valid_601575, JString, required = true, default = newJString(
      "DeleteEnvironmentConfiguration"))
  if valid_601575 != nil:
    section.add "Action", valid_601575
  var valid_601576 = query.getOrDefault("Version")
  valid_601576 = validateParameter(valid_601576, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601576 != nil:
    section.add "Version", valid_601576
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601577 = header.getOrDefault("X-Amz-Date")
  valid_601577 = validateParameter(valid_601577, JString, required = false,
                                 default = nil)
  if valid_601577 != nil:
    section.add "X-Amz-Date", valid_601577
  var valid_601578 = header.getOrDefault("X-Amz-Security-Token")
  valid_601578 = validateParameter(valid_601578, JString, required = false,
                                 default = nil)
  if valid_601578 != nil:
    section.add "X-Amz-Security-Token", valid_601578
  var valid_601579 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601579 = validateParameter(valid_601579, JString, required = false,
                                 default = nil)
  if valid_601579 != nil:
    section.add "X-Amz-Content-Sha256", valid_601579
  var valid_601580 = header.getOrDefault("X-Amz-Algorithm")
  valid_601580 = validateParameter(valid_601580, JString, required = false,
                                 default = nil)
  if valid_601580 != nil:
    section.add "X-Amz-Algorithm", valid_601580
  var valid_601581 = header.getOrDefault("X-Amz-Signature")
  valid_601581 = validateParameter(valid_601581, JString, required = false,
                                 default = nil)
  if valid_601581 != nil:
    section.add "X-Amz-Signature", valid_601581
  var valid_601582 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601582 = validateParameter(valid_601582, JString, required = false,
                                 default = nil)
  if valid_601582 != nil:
    section.add "X-Amz-SignedHeaders", valid_601582
  var valid_601583 = header.getOrDefault("X-Amz-Credential")
  valid_601583 = validateParameter(valid_601583, JString, required = false,
                                 default = nil)
  if valid_601583 != nil:
    section.add "X-Amz-Credential", valid_601583
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601584: Call_GetDeleteEnvironmentConfiguration_601570;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes the draft configuration associated with the running environment.</p> <p>Updating a running environment with any configuration changes creates a draft configuration set. You can get the draft configuration using <a>DescribeConfigurationSettings</a> while the update is in progress or if the update fails. The <code>DeploymentStatus</code> for the draft configuration indicates whether the deployment is in process or has failed. The draft configuration remains in existence until it is deleted with this action.</p>
  ## 
  let valid = call_601584.validator(path, query, header, formData, body)
  let scheme = call_601584.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601584.url(scheme.get, call_601584.host, call_601584.base,
                         call_601584.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601584, url, valid)

proc call*(call_601585: Call_GetDeleteEnvironmentConfiguration_601570;
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
  var query_601586 = newJObject()
  add(query_601586, "ApplicationName", newJString(ApplicationName))
  add(query_601586, "EnvironmentName", newJString(EnvironmentName))
  add(query_601586, "Action", newJString(Action))
  add(query_601586, "Version", newJString(Version))
  result = call_601585.call(nil, query_601586, nil, nil, nil)

var getDeleteEnvironmentConfiguration* = Call_GetDeleteEnvironmentConfiguration_601570(
    name: "getDeleteEnvironmentConfiguration", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteEnvironmentConfiguration",
    validator: validate_GetDeleteEnvironmentConfiguration_601571, base: "/",
    url: url_GetDeleteEnvironmentConfiguration_601572,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeletePlatformVersion_601621 = ref object of OpenApiRestCall_600438
proc url_PostDeletePlatformVersion_601623(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeletePlatformVersion_601622(path: JsonNode; query: JsonNode;
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
  var valid_601624 = query.getOrDefault("Action")
  valid_601624 = validateParameter(valid_601624, JString, required = true,
                                 default = newJString("DeletePlatformVersion"))
  if valid_601624 != nil:
    section.add "Action", valid_601624
  var valid_601625 = query.getOrDefault("Version")
  valid_601625 = validateParameter(valid_601625, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601625 != nil:
    section.add "Version", valid_601625
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601626 = header.getOrDefault("X-Amz-Date")
  valid_601626 = validateParameter(valid_601626, JString, required = false,
                                 default = nil)
  if valid_601626 != nil:
    section.add "X-Amz-Date", valid_601626
  var valid_601627 = header.getOrDefault("X-Amz-Security-Token")
  valid_601627 = validateParameter(valid_601627, JString, required = false,
                                 default = nil)
  if valid_601627 != nil:
    section.add "X-Amz-Security-Token", valid_601627
  var valid_601628 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601628 = validateParameter(valid_601628, JString, required = false,
                                 default = nil)
  if valid_601628 != nil:
    section.add "X-Amz-Content-Sha256", valid_601628
  var valid_601629 = header.getOrDefault("X-Amz-Algorithm")
  valid_601629 = validateParameter(valid_601629, JString, required = false,
                                 default = nil)
  if valid_601629 != nil:
    section.add "X-Amz-Algorithm", valid_601629
  var valid_601630 = header.getOrDefault("X-Amz-Signature")
  valid_601630 = validateParameter(valid_601630, JString, required = false,
                                 default = nil)
  if valid_601630 != nil:
    section.add "X-Amz-Signature", valid_601630
  var valid_601631 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601631 = validateParameter(valid_601631, JString, required = false,
                                 default = nil)
  if valid_601631 != nil:
    section.add "X-Amz-SignedHeaders", valid_601631
  var valid_601632 = header.getOrDefault("X-Amz-Credential")
  valid_601632 = validateParameter(valid_601632, JString, required = false,
                                 default = nil)
  if valid_601632 != nil:
    section.add "X-Amz-Credential", valid_601632
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformArn: JString
  ##              : The ARN of the version of the custom platform.
  section = newJObject()
  var valid_601633 = formData.getOrDefault("PlatformArn")
  valid_601633 = validateParameter(valid_601633, JString, required = false,
                                 default = nil)
  if valid_601633 != nil:
    section.add "PlatformArn", valid_601633
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601634: Call_PostDeletePlatformVersion_601621; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified version of a custom platform.
  ## 
  let valid = call_601634.validator(path, query, header, formData, body)
  let scheme = call_601634.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601634.url(scheme.get, call_601634.host, call_601634.base,
                         call_601634.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601634, url, valid)

proc call*(call_601635: Call_PostDeletePlatformVersion_601621;
          Action: string = "DeletePlatformVersion"; PlatformArn: string = "";
          Version: string = "2010-12-01"): Recallable =
  ## postDeletePlatformVersion
  ## Deletes the specified version of a custom platform.
  ##   Action: string (required)
  ##   PlatformArn: string
  ##              : The ARN of the version of the custom platform.
  ##   Version: string (required)
  var query_601636 = newJObject()
  var formData_601637 = newJObject()
  add(query_601636, "Action", newJString(Action))
  add(formData_601637, "PlatformArn", newJString(PlatformArn))
  add(query_601636, "Version", newJString(Version))
  result = call_601635.call(nil, query_601636, nil, formData_601637, nil)

var postDeletePlatformVersion* = Call_PostDeletePlatformVersion_601621(
    name: "postDeletePlatformVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeletePlatformVersion",
    validator: validate_PostDeletePlatformVersion_601622, base: "/",
    url: url_PostDeletePlatformVersion_601623,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeletePlatformVersion_601605 = ref object of OpenApiRestCall_600438
proc url_GetDeletePlatformVersion_601607(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeletePlatformVersion_601606(path: JsonNode; query: JsonNode;
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
  var valid_601608 = query.getOrDefault("PlatformArn")
  valid_601608 = validateParameter(valid_601608, JString, required = false,
                                 default = nil)
  if valid_601608 != nil:
    section.add "PlatformArn", valid_601608
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601609 = query.getOrDefault("Action")
  valid_601609 = validateParameter(valid_601609, JString, required = true,
                                 default = newJString("DeletePlatformVersion"))
  if valid_601609 != nil:
    section.add "Action", valid_601609
  var valid_601610 = query.getOrDefault("Version")
  valid_601610 = validateParameter(valid_601610, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601610 != nil:
    section.add "Version", valid_601610
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601611 = header.getOrDefault("X-Amz-Date")
  valid_601611 = validateParameter(valid_601611, JString, required = false,
                                 default = nil)
  if valid_601611 != nil:
    section.add "X-Amz-Date", valid_601611
  var valid_601612 = header.getOrDefault("X-Amz-Security-Token")
  valid_601612 = validateParameter(valid_601612, JString, required = false,
                                 default = nil)
  if valid_601612 != nil:
    section.add "X-Amz-Security-Token", valid_601612
  var valid_601613 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601613 = validateParameter(valid_601613, JString, required = false,
                                 default = nil)
  if valid_601613 != nil:
    section.add "X-Amz-Content-Sha256", valid_601613
  var valid_601614 = header.getOrDefault("X-Amz-Algorithm")
  valid_601614 = validateParameter(valid_601614, JString, required = false,
                                 default = nil)
  if valid_601614 != nil:
    section.add "X-Amz-Algorithm", valid_601614
  var valid_601615 = header.getOrDefault("X-Amz-Signature")
  valid_601615 = validateParameter(valid_601615, JString, required = false,
                                 default = nil)
  if valid_601615 != nil:
    section.add "X-Amz-Signature", valid_601615
  var valid_601616 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601616 = validateParameter(valid_601616, JString, required = false,
                                 default = nil)
  if valid_601616 != nil:
    section.add "X-Amz-SignedHeaders", valid_601616
  var valid_601617 = header.getOrDefault("X-Amz-Credential")
  valid_601617 = validateParameter(valid_601617, JString, required = false,
                                 default = nil)
  if valid_601617 != nil:
    section.add "X-Amz-Credential", valid_601617
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601618: Call_GetDeletePlatformVersion_601605; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified version of a custom platform.
  ## 
  let valid = call_601618.validator(path, query, header, formData, body)
  let scheme = call_601618.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601618.url(scheme.get, call_601618.host, call_601618.base,
                         call_601618.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601618, url, valid)

proc call*(call_601619: Call_GetDeletePlatformVersion_601605;
          PlatformArn: string = ""; Action: string = "DeletePlatformVersion";
          Version: string = "2010-12-01"): Recallable =
  ## getDeletePlatformVersion
  ## Deletes the specified version of a custom platform.
  ##   PlatformArn: string
  ##              : The ARN of the version of the custom platform.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601620 = newJObject()
  add(query_601620, "PlatformArn", newJString(PlatformArn))
  add(query_601620, "Action", newJString(Action))
  add(query_601620, "Version", newJString(Version))
  result = call_601619.call(nil, query_601620, nil, nil, nil)

var getDeletePlatformVersion* = Call_GetDeletePlatformVersion_601605(
    name: "getDeletePlatformVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeletePlatformVersion",
    validator: validate_GetDeletePlatformVersion_601606, base: "/",
    url: url_GetDeletePlatformVersion_601607, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAccountAttributes_601653 = ref object of OpenApiRestCall_600438
proc url_PostDescribeAccountAttributes_601655(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeAccountAttributes_601654(path: JsonNode; query: JsonNode;
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
  var valid_601656 = query.getOrDefault("Action")
  valid_601656 = validateParameter(valid_601656, JString, required = true, default = newJString(
      "DescribeAccountAttributes"))
  if valid_601656 != nil:
    section.add "Action", valid_601656
  var valid_601657 = query.getOrDefault("Version")
  valid_601657 = validateParameter(valid_601657, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601657 != nil:
    section.add "Version", valid_601657
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601658 = header.getOrDefault("X-Amz-Date")
  valid_601658 = validateParameter(valid_601658, JString, required = false,
                                 default = nil)
  if valid_601658 != nil:
    section.add "X-Amz-Date", valid_601658
  var valid_601659 = header.getOrDefault("X-Amz-Security-Token")
  valid_601659 = validateParameter(valid_601659, JString, required = false,
                                 default = nil)
  if valid_601659 != nil:
    section.add "X-Amz-Security-Token", valid_601659
  var valid_601660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601660 = validateParameter(valid_601660, JString, required = false,
                                 default = nil)
  if valid_601660 != nil:
    section.add "X-Amz-Content-Sha256", valid_601660
  var valid_601661 = header.getOrDefault("X-Amz-Algorithm")
  valid_601661 = validateParameter(valid_601661, JString, required = false,
                                 default = nil)
  if valid_601661 != nil:
    section.add "X-Amz-Algorithm", valid_601661
  var valid_601662 = header.getOrDefault("X-Amz-Signature")
  valid_601662 = validateParameter(valid_601662, JString, required = false,
                                 default = nil)
  if valid_601662 != nil:
    section.add "X-Amz-Signature", valid_601662
  var valid_601663 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601663 = validateParameter(valid_601663, JString, required = false,
                                 default = nil)
  if valid_601663 != nil:
    section.add "X-Amz-SignedHeaders", valid_601663
  var valid_601664 = header.getOrDefault("X-Amz-Credential")
  valid_601664 = validateParameter(valid_601664, JString, required = false,
                                 default = nil)
  if valid_601664 != nil:
    section.add "X-Amz-Credential", valid_601664
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601665: Call_PostDescribeAccountAttributes_601653; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ## 
  let valid = call_601665.validator(path, query, header, formData, body)
  let scheme = call_601665.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601665.url(scheme.get, call_601665.host, call_601665.base,
                         call_601665.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601665, url, valid)

proc call*(call_601666: Call_PostDescribeAccountAttributes_601653;
          Action: string = "DescribeAccountAttributes";
          Version: string = "2010-12-01"): Recallable =
  ## postDescribeAccountAttributes
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601667 = newJObject()
  add(query_601667, "Action", newJString(Action))
  add(query_601667, "Version", newJString(Version))
  result = call_601666.call(nil, query_601667, nil, nil, nil)

var postDescribeAccountAttributes* = Call_PostDescribeAccountAttributes_601653(
    name: "postDescribeAccountAttributes", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeAccountAttributes",
    validator: validate_PostDescribeAccountAttributes_601654, base: "/",
    url: url_PostDescribeAccountAttributes_601655,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAccountAttributes_601638 = ref object of OpenApiRestCall_600438
proc url_GetDescribeAccountAttributes_601640(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeAccountAttributes_601639(path: JsonNode; query: JsonNode;
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
  var valid_601641 = query.getOrDefault("Action")
  valid_601641 = validateParameter(valid_601641, JString, required = true, default = newJString(
      "DescribeAccountAttributes"))
  if valid_601641 != nil:
    section.add "Action", valid_601641
  var valid_601642 = query.getOrDefault("Version")
  valid_601642 = validateParameter(valid_601642, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601642 != nil:
    section.add "Version", valid_601642
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601643 = header.getOrDefault("X-Amz-Date")
  valid_601643 = validateParameter(valid_601643, JString, required = false,
                                 default = nil)
  if valid_601643 != nil:
    section.add "X-Amz-Date", valid_601643
  var valid_601644 = header.getOrDefault("X-Amz-Security-Token")
  valid_601644 = validateParameter(valid_601644, JString, required = false,
                                 default = nil)
  if valid_601644 != nil:
    section.add "X-Amz-Security-Token", valid_601644
  var valid_601645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601645 = validateParameter(valid_601645, JString, required = false,
                                 default = nil)
  if valid_601645 != nil:
    section.add "X-Amz-Content-Sha256", valid_601645
  var valid_601646 = header.getOrDefault("X-Amz-Algorithm")
  valid_601646 = validateParameter(valid_601646, JString, required = false,
                                 default = nil)
  if valid_601646 != nil:
    section.add "X-Amz-Algorithm", valid_601646
  var valid_601647 = header.getOrDefault("X-Amz-Signature")
  valid_601647 = validateParameter(valid_601647, JString, required = false,
                                 default = nil)
  if valid_601647 != nil:
    section.add "X-Amz-Signature", valid_601647
  var valid_601648 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601648 = validateParameter(valid_601648, JString, required = false,
                                 default = nil)
  if valid_601648 != nil:
    section.add "X-Amz-SignedHeaders", valid_601648
  var valid_601649 = header.getOrDefault("X-Amz-Credential")
  valid_601649 = validateParameter(valid_601649, JString, required = false,
                                 default = nil)
  if valid_601649 != nil:
    section.add "X-Amz-Credential", valid_601649
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601650: Call_GetDescribeAccountAttributes_601638; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ## 
  let valid = call_601650.validator(path, query, header, formData, body)
  let scheme = call_601650.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601650.url(scheme.get, call_601650.host, call_601650.base,
                         call_601650.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601650, url, valid)

proc call*(call_601651: Call_GetDescribeAccountAttributes_601638;
          Action: string = "DescribeAccountAttributes";
          Version: string = "2010-12-01"): Recallable =
  ## getDescribeAccountAttributes
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601652 = newJObject()
  add(query_601652, "Action", newJString(Action))
  add(query_601652, "Version", newJString(Version))
  result = call_601651.call(nil, query_601652, nil, nil, nil)

var getDescribeAccountAttributes* = Call_GetDescribeAccountAttributes_601638(
    name: "getDescribeAccountAttributes", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeAccountAttributes",
    validator: validate_GetDescribeAccountAttributes_601639, base: "/",
    url: url_GetDescribeAccountAttributes_601640,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeApplicationVersions_601687 = ref object of OpenApiRestCall_600438
proc url_PostDescribeApplicationVersions_601689(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeApplicationVersions_601688(path: JsonNode;
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
  var valid_601690 = query.getOrDefault("Action")
  valid_601690 = validateParameter(valid_601690, JString, required = true, default = newJString(
      "DescribeApplicationVersions"))
  if valid_601690 != nil:
    section.add "Action", valid_601690
  var valid_601691 = query.getOrDefault("Version")
  valid_601691 = validateParameter(valid_601691, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601691 != nil:
    section.add "Version", valid_601691
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601692 = header.getOrDefault("X-Amz-Date")
  valid_601692 = validateParameter(valid_601692, JString, required = false,
                                 default = nil)
  if valid_601692 != nil:
    section.add "X-Amz-Date", valid_601692
  var valid_601693 = header.getOrDefault("X-Amz-Security-Token")
  valid_601693 = validateParameter(valid_601693, JString, required = false,
                                 default = nil)
  if valid_601693 != nil:
    section.add "X-Amz-Security-Token", valid_601693
  var valid_601694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601694 = validateParameter(valid_601694, JString, required = false,
                                 default = nil)
  if valid_601694 != nil:
    section.add "X-Amz-Content-Sha256", valid_601694
  var valid_601695 = header.getOrDefault("X-Amz-Algorithm")
  valid_601695 = validateParameter(valid_601695, JString, required = false,
                                 default = nil)
  if valid_601695 != nil:
    section.add "X-Amz-Algorithm", valid_601695
  var valid_601696 = header.getOrDefault("X-Amz-Signature")
  valid_601696 = validateParameter(valid_601696, JString, required = false,
                                 default = nil)
  if valid_601696 != nil:
    section.add "X-Amz-Signature", valid_601696
  var valid_601697 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601697 = validateParameter(valid_601697, JString, required = false,
                                 default = nil)
  if valid_601697 != nil:
    section.add "X-Amz-SignedHeaders", valid_601697
  var valid_601698 = header.getOrDefault("X-Amz-Credential")
  valid_601698 = validateParameter(valid_601698, JString, required = false,
                                 default = nil)
  if valid_601698 != nil:
    section.add "X-Amz-Credential", valid_601698
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
  var valid_601699 = formData.getOrDefault("NextToken")
  valid_601699 = validateParameter(valid_601699, JString, required = false,
                                 default = nil)
  if valid_601699 != nil:
    section.add "NextToken", valid_601699
  var valid_601700 = formData.getOrDefault("ApplicationName")
  valid_601700 = validateParameter(valid_601700, JString, required = false,
                                 default = nil)
  if valid_601700 != nil:
    section.add "ApplicationName", valid_601700
  var valid_601701 = formData.getOrDefault("MaxRecords")
  valid_601701 = validateParameter(valid_601701, JInt, required = false, default = nil)
  if valid_601701 != nil:
    section.add "MaxRecords", valid_601701
  var valid_601702 = formData.getOrDefault("VersionLabels")
  valid_601702 = validateParameter(valid_601702, JArray, required = false,
                                 default = nil)
  if valid_601702 != nil:
    section.add "VersionLabels", valid_601702
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601703: Call_PostDescribeApplicationVersions_601687;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieve a list of application versions.
  ## 
  let valid = call_601703.validator(path, query, header, formData, body)
  let scheme = call_601703.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601703.url(scheme.get, call_601703.host, call_601703.base,
                         call_601703.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601703, url, valid)

proc call*(call_601704: Call_PostDescribeApplicationVersions_601687;
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
  var query_601705 = newJObject()
  var formData_601706 = newJObject()
  add(formData_601706, "NextToken", newJString(NextToken))
  add(query_601705, "Action", newJString(Action))
  add(formData_601706, "ApplicationName", newJString(ApplicationName))
  add(formData_601706, "MaxRecords", newJInt(MaxRecords))
  add(query_601705, "Version", newJString(Version))
  if VersionLabels != nil:
    formData_601706.add "VersionLabels", VersionLabels
  result = call_601704.call(nil, query_601705, nil, formData_601706, nil)

var postDescribeApplicationVersions* = Call_PostDescribeApplicationVersions_601687(
    name: "postDescribeApplicationVersions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplicationVersions",
    validator: validate_PostDescribeApplicationVersions_601688, base: "/",
    url: url_PostDescribeApplicationVersions_601689,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeApplicationVersions_601668 = ref object of OpenApiRestCall_600438
proc url_GetDescribeApplicationVersions_601670(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeApplicationVersions_601669(path: JsonNode;
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
  var valid_601671 = query.getOrDefault("MaxRecords")
  valid_601671 = validateParameter(valid_601671, JInt, required = false, default = nil)
  if valid_601671 != nil:
    section.add "MaxRecords", valid_601671
  var valid_601672 = query.getOrDefault("ApplicationName")
  valid_601672 = validateParameter(valid_601672, JString, required = false,
                                 default = nil)
  if valid_601672 != nil:
    section.add "ApplicationName", valid_601672
  var valid_601673 = query.getOrDefault("NextToken")
  valid_601673 = validateParameter(valid_601673, JString, required = false,
                                 default = nil)
  if valid_601673 != nil:
    section.add "NextToken", valid_601673
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601674 = query.getOrDefault("Action")
  valid_601674 = validateParameter(valid_601674, JString, required = true, default = newJString(
      "DescribeApplicationVersions"))
  if valid_601674 != nil:
    section.add "Action", valid_601674
  var valid_601675 = query.getOrDefault("VersionLabels")
  valid_601675 = validateParameter(valid_601675, JArray, required = false,
                                 default = nil)
  if valid_601675 != nil:
    section.add "VersionLabels", valid_601675
  var valid_601676 = query.getOrDefault("Version")
  valid_601676 = validateParameter(valid_601676, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601676 != nil:
    section.add "Version", valid_601676
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601677 = header.getOrDefault("X-Amz-Date")
  valid_601677 = validateParameter(valid_601677, JString, required = false,
                                 default = nil)
  if valid_601677 != nil:
    section.add "X-Amz-Date", valid_601677
  var valid_601678 = header.getOrDefault("X-Amz-Security-Token")
  valid_601678 = validateParameter(valid_601678, JString, required = false,
                                 default = nil)
  if valid_601678 != nil:
    section.add "X-Amz-Security-Token", valid_601678
  var valid_601679 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601679 = validateParameter(valid_601679, JString, required = false,
                                 default = nil)
  if valid_601679 != nil:
    section.add "X-Amz-Content-Sha256", valid_601679
  var valid_601680 = header.getOrDefault("X-Amz-Algorithm")
  valid_601680 = validateParameter(valid_601680, JString, required = false,
                                 default = nil)
  if valid_601680 != nil:
    section.add "X-Amz-Algorithm", valid_601680
  var valid_601681 = header.getOrDefault("X-Amz-Signature")
  valid_601681 = validateParameter(valid_601681, JString, required = false,
                                 default = nil)
  if valid_601681 != nil:
    section.add "X-Amz-Signature", valid_601681
  var valid_601682 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601682 = validateParameter(valid_601682, JString, required = false,
                                 default = nil)
  if valid_601682 != nil:
    section.add "X-Amz-SignedHeaders", valid_601682
  var valid_601683 = header.getOrDefault("X-Amz-Credential")
  valid_601683 = validateParameter(valid_601683, JString, required = false,
                                 default = nil)
  if valid_601683 != nil:
    section.add "X-Amz-Credential", valid_601683
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601684: Call_GetDescribeApplicationVersions_601668; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a list of application versions.
  ## 
  let valid = call_601684.validator(path, query, header, formData, body)
  let scheme = call_601684.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601684.url(scheme.get, call_601684.host, call_601684.base,
                         call_601684.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601684, url, valid)

proc call*(call_601685: Call_GetDescribeApplicationVersions_601668;
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
  var query_601686 = newJObject()
  add(query_601686, "MaxRecords", newJInt(MaxRecords))
  add(query_601686, "ApplicationName", newJString(ApplicationName))
  add(query_601686, "NextToken", newJString(NextToken))
  add(query_601686, "Action", newJString(Action))
  if VersionLabels != nil:
    query_601686.add "VersionLabels", VersionLabels
  add(query_601686, "Version", newJString(Version))
  result = call_601685.call(nil, query_601686, nil, nil, nil)

var getDescribeApplicationVersions* = Call_GetDescribeApplicationVersions_601668(
    name: "getDescribeApplicationVersions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplicationVersions",
    validator: validate_GetDescribeApplicationVersions_601669, base: "/",
    url: url_GetDescribeApplicationVersions_601670,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeApplications_601723 = ref object of OpenApiRestCall_600438
proc url_PostDescribeApplications_601725(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeApplications_601724(path: JsonNode; query: JsonNode;
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
  var valid_601726 = query.getOrDefault("Action")
  valid_601726 = validateParameter(valid_601726, JString, required = true,
                                 default = newJString("DescribeApplications"))
  if valid_601726 != nil:
    section.add "Action", valid_601726
  var valid_601727 = query.getOrDefault("Version")
  valid_601727 = validateParameter(valid_601727, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601727 != nil:
    section.add "Version", valid_601727
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601728 = header.getOrDefault("X-Amz-Date")
  valid_601728 = validateParameter(valid_601728, JString, required = false,
                                 default = nil)
  if valid_601728 != nil:
    section.add "X-Amz-Date", valid_601728
  var valid_601729 = header.getOrDefault("X-Amz-Security-Token")
  valid_601729 = validateParameter(valid_601729, JString, required = false,
                                 default = nil)
  if valid_601729 != nil:
    section.add "X-Amz-Security-Token", valid_601729
  var valid_601730 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601730 = validateParameter(valid_601730, JString, required = false,
                                 default = nil)
  if valid_601730 != nil:
    section.add "X-Amz-Content-Sha256", valid_601730
  var valid_601731 = header.getOrDefault("X-Amz-Algorithm")
  valid_601731 = validateParameter(valid_601731, JString, required = false,
                                 default = nil)
  if valid_601731 != nil:
    section.add "X-Amz-Algorithm", valid_601731
  var valid_601732 = header.getOrDefault("X-Amz-Signature")
  valid_601732 = validateParameter(valid_601732, JString, required = false,
                                 default = nil)
  if valid_601732 != nil:
    section.add "X-Amz-Signature", valid_601732
  var valid_601733 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601733 = validateParameter(valid_601733, JString, required = false,
                                 default = nil)
  if valid_601733 != nil:
    section.add "X-Amz-SignedHeaders", valid_601733
  var valid_601734 = header.getOrDefault("X-Amz-Credential")
  valid_601734 = validateParameter(valid_601734, JString, required = false,
                                 default = nil)
  if valid_601734 != nil:
    section.add "X-Amz-Credential", valid_601734
  result.add "header", section
  ## parameters in `formData` object:
  ##   ApplicationNames: JArray
  ##                   : If specified, AWS Elastic Beanstalk restricts the returned descriptions to only include those with the specified names.
  section = newJObject()
  var valid_601735 = formData.getOrDefault("ApplicationNames")
  valid_601735 = validateParameter(valid_601735, JArray, required = false,
                                 default = nil)
  if valid_601735 != nil:
    section.add "ApplicationNames", valid_601735
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601736: Call_PostDescribeApplications_601723; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the descriptions of existing applications.
  ## 
  let valid = call_601736.validator(path, query, header, formData, body)
  let scheme = call_601736.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601736.url(scheme.get, call_601736.host, call_601736.base,
                         call_601736.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601736, url, valid)

proc call*(call_601737: Call_PostDescribeApplications_601723;
          ApplicationNames: JsonNode = nil; Action: string = "DescribeApplications";
          Version: string = "2010-12-01"): Recallable =
  ## postDescribeApplications
  ## Returns the descriptions of existing applications.
  ##   ApplicationNames: JArray
  ##                   : If specified, AWS Elastic Beanstalk restricts the returned descriptions to only include those with the specified names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601738 = newJObject()
  var formData_601739 = newJObject()
  if ApplicationNames != nil:
    formData_601739.add "ApplicationNames", ApplicationNames
  add(query_601738, "Action", newJString(Action))
  add(query_601738, "Version", newJString(Version))
  result = call_601737.call(nil, query_601738, nil, formData_601739, nil)

var postDescribeApplications* = Call_PostDescribeApplications_601723(
    name: "postDescribeApplications", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplications",
    validator: validate_PostDescribeApplications_601724, base: "/",
    url: url_PostDescribeApplications_601725, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeApplications_601707 = ref object of OpenApiRestCall_600438
proc url_GetDescribeApplications_601709(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeApplications_601708(path: JsonNode; query: JsonNode;
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
  var valid_601710 = query.getOrDefault("ApplicationNames")
  valid_601710 = validateParameter(valid_601710, JArray, required = false,
                                 default = nil)
  if valid_601710 != nil:
    section.add "ApplicationNames", valid_601710
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601711 = query.getOrDefault("Action")
  valid_601711 = validateParameter(valid_601711, JString, required = true,
                                 default = newJString("DescribeApplications"))
  if valid_601711 != nil:
    section.add "Action", valid_601711
  var valid_601712 = query.getOrDefault("Version")
  valid_601712 = validateParameter(valid_601712, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601712 != nil:
    section.add "Version", valid_601712
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601713 = header.getOrDefault("X-Amz-Date")
  valid_601713 = validateParameter(valid_601713, JString, required = false,
                                 default = nil)
  if valid_601713 != nil:
    section.add "X-Amz-Date", valid_601713
  var valid_601714 = header.getOrDefault("X-Amz-Security-Token")
  valid_601714 = validateParameter(valid_601714, JString, required = false,
                                 default = nil)
  if valid_601714 != nil:
    section.add "X-Amz-Security-Token", valid_601714
  var valid_601715 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601715 = validateParameter(valid_601715, JString, required = false,
                                 default = nil)
  if valid_601715 != nil:
    section.add "X-Amz-Content-Sha256", valid_601715
  var valid_601716 = header.getOrDefault("X-Amz-Algorithm")
  valid_601716 = validateParameter(valid_601716, JString, required = false,
                                 default = nil)
  if valid_601716 != nil:
    section.add "X-Amz-Algorithm", valid_601716
  var valid_601717 = header.getOrDefault("X-Amz-Signature")
  valid_601717 = validateParameter(valid_601717, JString, required = false,
                                 default = nil)
  if valid_601717 != nil:
    section.add "X-Amz-Signature", valid_601717
  var valid_601718 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601718 = validateParameter(valid_601718, JString, required = false,
                                 default = nil)
  if valid_601718 != nil:
    section.add "X-Amz-SignedHeaders", valid_601718
  var valid_601719 = header.getOrDefault("X-Amz-Credential")
  valid_601719 = validateParameter(valid_601719, JString, required = false,
                                 default = nil)
  if valid_601719 != nil:
    section.add "X-Amz-Credential", valid_601719
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601720: Call_GetDescribeApplications_601707; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the descriptions of existing applications.
  ## 
  let valid = call_601720.validator(path, query, header, formData, body)
  let scheme = call_601720.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601720.url(scheme.get, call_601720.host, call_601720.base,
                         call_601720.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601720, url, valid)

proc call*(call_601721: Call_GetDescribeApplications_601707;
          ApplicationNames: JsonNode = nil; Action: string = "DescribeApplications";
          Version: string = "2010-12-01"): Recallable =
  ## getDescribeApplications
  ## Returns the descriptions of existing applications.
  ##   ApplicationNames: JArray
  ##                   : If specified, AWS Elastic Beanstalk restricts the returned descriptions to only include those with the specified names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601722 = newJObject()
  if ApplicationNames != nil:
    query_601722.add "ApplicationNames", ApplicationNames
  add(query_601722, "Action", newJString(Action))
  add(query_601722, "Version", newJString(Version))
  result = call_601721.call(nil, query_601722, nil, nil, nil)

var getDescribeApplications* = Call_GetDescribeApplications_601707(
    name: "getDescribeApplications", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplications",
    validator: validate_GetDescribeApplications_601708, base: "/",
    url: url_GetDescribeApplications_601709, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeConfigurationOptions_601761 = ref object of OpenApiRestCall_600438
proc url_PostDescribeConfigurationOptions_601763(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeConfigurationOptions_601762(path: JsonNode;
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
  var valid_601764 = query.getOrDefault("Action")
  valid_601764 = validateParameter(valid_601764, JString, required = true, default = newJString(
      "DescribeConfigurationOptions"))
  if valid_601764 != nil:
    section.add "Action", valid_601764
  var valid_601765 = query.getOrDefault("Version")
  valid_601765 = validateParameter(valid_601765, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601765 != nil:
    section.add "Version", valid_601765
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601766 = header.getOrDefault("X-Amz-Date")
  valid_601766 = validateParameter(valid_601766, JString, required = false,
                                 default = nil)
  if valid_601766 != nil:
    section.add "X-Amz-Date", valid_601766
  var valid_601767 = header.getOrDefault("X-Amz-Security-Token")
  valid_601767 = validateParameter(valid_601767, JString, required = false,
                                 default = nil)
  if valid_601767 != nil:
    section.add "X-Amz-Security-Token", valid_601767
  var valid_601768 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601768 = validateParameter(valid_601768, JString, required = false,
                                 default = nil)
  if valid_601768 != nil:
    section.add "X-Amz-Content-Sha256", valid_601768
  var valid_601769 = header.getOrDefault("X-Amz-Algorithm")
  valid_601769 = validateParameter(valid_601769, JString, required = false,
                                 default = nil)
  if valid_601769 != nil:
    section.add "X-Amz-Algorithm", valid_601769
  var valid_601770 = header.getOrDefault("X-Amz-Signature")
  valid_601770 = validateParameter(valid_601770, JString, required = false,
                                 default = nil)
  if valid_601770 != nil:
    section.add "X-Amz-Signature", valid_601770
  var valid_601771 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601771 = validateParameter(valid_601771, JString, required = false,
                                 default = nil)
  if valid_601771 != nil:
    section.add "X-Amz-SignedHeaders", valid_601771
  var valid_601772 = header.getOrDefault("X-Amz-Credential")
  valid_601772 = validateParameter(valid_601772, JString, required = false,
                                 default = nil)
  if valid_601772 != nil:
    section.add "X-Amz-Credential", valid_601772
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
  var valid_601773 = formData.getOrDefault("Options")
  valid_601773 = validateParameter(valid_601773, JArray, required = false,
                                 default = nil)
  if valid_601773 != nil:
    section.add "Options", valid_601773
  var valid_601774 = formData.getOrDefault("SolutionStackName")
  valid_601774 = validateParameter(valid_601774, JString, required = false,
                                 default = nil)
  if valid_601774 != nil:
    section.add "SolutionStackName", valid_601774
  var valid_601775 = formData.getOrDefault("EnvironmentName")
  valid_601775 = validateParameter(valid_601775, JString, required = false,
                                 default = nil)
  if valid_601775 != nil:
    section.add "EnvironmentName", valid_601775
  var valid_601776 = formData.getOrDefault("ApplicationName")
  valid_601776 = validateParameter(valid_601776, JString, required = false,
                                 default = nil)
  if valid_601776 != nil:
    section.add "ApplicationName", valid_601776
  var valid_601777 = formData.getOrDefault("PlatformArn")
  valid_601777 = validateParameter(valid_601777, JString, required = false,
                                 default = nil)
  if valid_601777 != nil:
    section.add "PlatformArn", valid_601777
  var valid_601778 = formData.getOrDefault("TemplateName")
  valid_601778 = validateParameter(valid_601778, JString, required = false,
                                 default = nil)
  if valid_601778 != nil:
    section.add "TemplateName", valid_601778
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601779: Call_PostDescribeConfigurationOptions_601761;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the configuration options that are used in a particular configuration template or environment, or that a specified solution stack defines. The description includes the values the options, their default values, and an indication of the required action on a running environment if an option value is changed.
  ## 
  let valid = call_601779.validator(path, query, header, formData, body)
  let scheme = call_601779.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601779.url(scheme.get, call_601779.host, call_601779.base,
                         call_601779.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601779, url, valid)

proc call*(call_601780: Call_PostDescribeConfigurationOptions_601761;
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
  var query_601781 = newJObject()
  var formData_601782 = newJObject()
  if Options != nil:
    formData_601782.add "Options", Options
  add(formData_601782, "SolutionStackName", newJString(SolutionStackName))
  add(formData_601782, "EnvironmentName", newJString(EnvironmentName))
  add(query_601781, "Action", newJString(Action))
  add(formData_601782, "ApplicationName", newJString(ApplicationName))
  add(formData_601782, "PlatformArn", newJString(PlatformArn))
  add(formData_601782, "TemplateName", newJString(TemplateName))
  add(query_601781, "Version", newJString(Version))
  result = call_601780.call(nil, query_601781, nil, formData_601782, nil)

var postDescribeConfigurationOptions* = Call_PostDescribeConfigurationOptions_601761(
    name: "postDescribeConfigurationOptions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationOptions",
    validator: validate_PostDescribeConfigurationOptions_601762, base: "/",
    url: url_PostDescribeConfigurationOptions_601763,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeConfigurationOptions_601740 = ref object of OpenApiRestCall_600438
proc url_GetDescribeConfigurationOptions_601742(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeConfigurationOptions_601741(path: JsonNode;
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
  var valid_601743 = query.getOrDefault("Options")
  valid_601743 = validateParameter(valid_601743, JArray, required = false,
                                 default = nil)
  if valid_601743 != nil:
    section.add "Options", valid_601743
  var valid_601744 = query.getOrDefault("ApplicationName")
  valid_601744 = validateParameter(valid_601744, JString, required = false,
                                 default = nil)
  if valid_601744 != nil:
    section.add "ApplicationName", valid_601744
  var valid_601745 = query.getOrDefault("PlatformArn")
  valid_601745 = validateParameter(valid_601745, JString, required = false,
                                 default = nil)
  if valid_601745 != nil:
    section.add "PlatformArn", valid_601745
  var valid_601746 = query.getOrDefault("EnvironmentName")
  valid_601746 = validateParameter(valid_601746, JString, required = false,
                                 default = nil)
  if valid_601746 != nil:
    section.add "EnvironmentName", valid_601746
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601747 = query.getOrDefault("Action")
  valid_601747 = validateParameter(valid_601747, JString, required = true, default = newJString(
      "DescribeConfigurationOptions"))
  if valid_601747 != nil:
    section.add "Action", valid_601747
  var valid_601748 = query.getOrDefault("SolutionStackName")
  valid_601748 = validateParameter(valid_601748, JString, required = false,
                                 default = nil)
  if valid_601748 != nil:
    section.add "SolutionStackName", valid_601748
  var valid_601749 = query.getOrDefault("TemplateName")
  valid_601749 = validateParameter(valid_601749, JString, required = false,
                                 default = nil)
  if valid_601749 != nil:
    section.add "TemplateName", valid_601749
  var valid_601750 = query.getOrDefault("Version")
  valid_601750 = validateParameter(valid_601750, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601750 != nil:
    section.add "Version", valid_601750
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601751 = header.getOrDefault("X-Amz-Date")
  valid_601751 = validateParameter(valid_601751, JString, required = false,
                                 default = nil)
  if valid_601751 != nil:
    section.add "X-Amz-Date", valid_601751
  var valid_601752 = header.getOrDefault("X-Amz-Security-Token")
  valid_601752 = validateParameter(valid_601752, JString, required = false,
                                 default = nil)
  if valid_601752 != nil:
    section.add "X-Amz-Security-Token", valid_601752
  var valid_601753 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601753 = validateParameter(valid_601753, JString, required = false,
                                 default = nil)
  if valid_601753 != nil:
    section.add "X-Amz-Content-Sha256", valid_601753
  var valid_601754 = header.getOrDefault("X-Amz-Algorithm")
  valid_601754 = validateParameter(valid_601754, JString, required = false,
                                 default = nil)
  if valid_601754 != nil:
    section.add "X-Amz-Algorithm", valid_601754
  var valid_601755 = header.getOrDefault("X-Amz-Signature")
  valid_601755 = validateParameter(valid_601755, JString, required = false,
                                 default = nil)
  if valid_601755 != nil:
    section.add "X-Amz-Signature", valid_601755
  var valid_601756 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601756 = validateParameter(valid_601756, JString, required = false,
                                 default = nil)
  if valid_601756 != nil:
    section.add "X-Amz-SignedHeaders", valid_601756
  var valid_601757 = header.getOrDefault("X-Amz-Credential")
  valid_601757 = validateParameter(valid_601757, JString, required = false,
                                 default = nil)
  if valid_601757 != nil:
    section.add "X-Amz-Credential", valid_601757
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601758: Call_GetDescribeConfigurationOptions_601740;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the configuration options that are used in a particular configuration template or environment, or that a specified solution stack defines. The description includes the values the options, their default values, and an indication of the required action on a running environment if an option value is changed.
  ## 
  let valid = call_601758.validator(path, query, header, formData, body)
  let scheme = call_601758.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601758.url(scheme.get, call_601758.host, call_601758.base,
                         call_601758.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601758, url, valid)

proc call*(call_601759: Call_GetDescribeConfigurationOptions_601740;
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
  var query_601760 = newJObject()
  if Options != nil:
    query_601760.add "Options", Options
  add(query_601760, "ApplicationName", newJString(ApplicationName))
  add(query_601760, "PlatformArn", newJString(PlatformArn))
  add(query_601760, "EnvironmentName", newJString(EnvironmentName))
  add(query_601760, "Action", newJString(Action))
  add(query_601760, "SolutionStackName", newJString(SolutionStackName))
  add(query_601760, "TemplateName", newJString(TemplateName))
  add(query_601760, "Version", newJString(Version))
  result = call_601759.call(nil, query_601760, nil, nil, nil)

var getDescribeConfigurationOptions* = Call_GetDescribeConfigurationOptions_601740(
    name: "getDescribeConfigurationOptions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationOptions",
    validator: validate_GetDescribeConfigurationOptions_601741, base: "/",
    url: url_GetDescribeConfigurationOptions_601742,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeConfigurationSettings_601801 = ref object of OpenApiRestCall_600438
proc url_PostDescribeConfigurationSettings_601803(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeConfigurationSettings_601802(path: JsonNode;
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
  var valid_601804 = query.getOrDefault("Action")
  valid_601804 = validateParameter(valid_601804, JString, required = true, default = newJString(
      "DescribeConfigurationSettings"))
  if valid_601804 != nil:
    section.add "Action", valid_601804
  var valid_601805 = query.getOrDefault("Version")
  valid_601805 = validateParameter(valid_601805, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601805 != nil:
    section.add "Version", valid_601805
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601806 = header.getOrDefault("X-Amz-Date")
  valid_601806 = validateParameter(valid_601806, JString, required = false,
                                 default = nil)
  if valid_601806 != nil:
    section.add "X-Amz-Date", valid_601806
  var valid_601807 = header.getOrDefault("X-Amz-Security-Token")
  valid_601807 = validateParameter(valid_601807, JString, required = false,
                                 default = nil)
  if valid_601807 != nil:
    section.add "X-Amz-Security-Token", valid_601807
  var valid_601808 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601808 = validateParameter(valid_601808, JString, required = false,
                                 default = nil)
  if valid_601808 != nil:
    section.add "X-Amz-Content-Sha256", valid_601808
  var valid_601809 = header.getOrDefault("X-Amz-Algorithm")
  valid_601809 = validateParameter(valid_601809, JString, required = false,
                                 default = nil)
  if valid_601809 != nil:
    section.add "X-Amz-Algorithm", valid_601809
  var valid_601810 = header.getOrDefault("X-Amz-Signature")
  valid_601810 = validateParameter(valid_601810, JString, required = false,
                                 default = nil)
  if valid_601810 != nil:
    section.add "X-Amz-Signature", valid_601810
  var valid_601811 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601811 = validateParameter(valid_601811, JString, required = false,
                                 default = nil)
  if valid_601811 != nil:
    section.add "X-Amz-SignedHeaders", valid_601811
  var valid_601812 = header.getOrDefault("X-Amz-Credential")
  valid_601812 = validateParameter(valid_601812, JString, required = false,
                                 default = nil)
  if valid_601812 != nil:
    section.add "X-Amz-Credential", valid_601812
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to describe.</p> <p> Condition: You must specify either this or a TemplateName, but not both. If you specify both, AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   ApplicationName: JString (required)
  ##                  : The application for the environment or configuration template.
  ##   TemplateName: JString
  ##               : <p>The name of the configuration template to describe.</p> <p> Conditional: You must specify either this parameter or an EnvironmentName, but not both. If you specify both, AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. If you do not specify either, AWS Elastic Beanstalk returns a <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_601813 = formData.getOrDefault("EnvironmentName")
  valid_601813 = validateParameter(valid_601813, JString, required = false,
                                 default = nil)
  if valid_601813 != nil:
    section.add "EnvironmentName", valid_601813
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_601814 = formData.getOrDefault("ApplicationName")
  valid_601814 = validateParameter(valid_601814, JString, required = true,
                                 default = nil)
  if valid_601814 != nil:
    section.add "ApplicationName", valid_601814
  var valid_601815 = formData.getOrDefault("TemplateName")
  valid_601815 = validateParameter(valid_601815, JString, required = false,
                                 default = nil)
  if valid_601815 != nil:
    section.add "TemplateName", valid_601815
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601816: Call_PostDescribeConfigurationSettings_601801;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a description of the settings for the specified configuration set, that is, either a configuration template or the configuration set associated with a running environment.</p> <p>When describing the settings for the configuration set associated with a running environment, it is possible to receive two sets of setting descriptions. One is the deployed configuration set, and the other is a draft configuration of an environment that is either in the process of deployment or that failed to deploy.</p> <p>Related Topics</p> <ul> <li> <p> <a>DeleteEnvironmentConfiguration</a> </p> </li> </ul>
  ## 
  let valid = call_601816.validator(path, query, header, formData, body)
  let scheme = call_601816.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601816.url(scheme.get, call_601816.host, call_601816.base,
                         call_601816.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601816, url, valid)

proc call*(call_601817: Call_PostDescribeConfigurationSettings_601801;
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
  var query_601818 = newJObject()
  var formData_601819 = newJObject()
  add(formData_601819, "EnvironmentName", newJString(EnvironmentName))
  add(query_601818, "Action", newJString(Action))
  add(formData_601819, "ApplicationName", newJString(ApplicationName))
  add(formData_601819, "TemplateName", newJString(TemplateName))
  add(query_601818, "Version", newJString(Version))
  result = call_601817.call(nil, query_601818, nil, formData_601819, nil)

var postDescribeConfigurationSettings* = Call_PostDescribeConfigurationSettings_601801(
    name: "postDescribeConfigurationSettings", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationSettings",
    validator: validate_PostDescribeConfigurationSettings_601802, base: "/",
    url: url_PostDescribeConfigurationSettings_601803,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeConfigurationSettings_601783 = ref object of OpenApiRestCall_600438
proc url_GetDescribeConfigurationSettings_601785(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeConfigurationSettings_601784(path: JsonNode;
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
  var valid_601786 = query.getOrDefault("ApplicationName")
  valid_601786 = validateParameter(valid_601786, JString, required = true,
                                 default = nil)
  if valid_601786 != nil:
    section.add "ApplicationName", valid_601786
  var valid_601787 = query.getOrDefault("EnvironmentName")
  valid_601787 = validateParameter(valid_601787, JString, required = false,
                                 default = nil)
  if valid_601787 != nil:
    section.add "EnvironmentName", valid_601787
  var valid_601788 = query.getOrDefault("Action")
  valid_601788 = validateParameter(valid_601788, JString, required = true, default = newJString(
      "DescribeConfigurationSettings"))
  if valid_601788 != nil:
    section.add "Action", valid_601788
  var valid_601789 = query.getOrDefault("TemplateName")
  valid_601789 = validateParameter(valid_601789, JString, required = false,
                                 default = nil)
  if valid_601789 != nil:
    section.add "TemplateName", valid_601789
  var valid_601790 = query.getOrDefault("Version")
  valid_601790 = validateParameter(valid_601790, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601790 != nil:
    section.add "Version", valid_601790
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601791 = header.getOrDefault("X-Amz-Date")
  valid_601791 = validateParameter(valid_601791, JString, required = false,
                                 default = nil)
  if valid_601791 != nil:
    section.add "X-Amz-Date", valid_601791
  var valid_601792 = header.getOrDefault("X-Amz-Security-Token")
  valid_601792 = validateParameter(valid_601792, JString, required = false,
                                 default = nil)
  if valid_601792 != nil:
    section.add "X-Amz-Security-Token", valid_601792
  var valid_601793 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601793 = validateParameter(valid_601793, JString, required = false,
                                 default = nil)
  if valid_601793 != nil:
    section.add "X-Amz-Content-Sha256", valid_601793
  var valid_601794 = header.getOrDefault("X-Amz-Algorithm")
  valid_601794 = validateParameter(valid_601794, JString, required = false,
                                 default = nil)
  if valid_601794 != nil:
    section.add "X-Amz-Algorithm", valid_601794
  var valid_601795 = header.getOrDefault("X-Amz-Signature")
  valid_601795 = validateParameter(valid_601795, JString, required = false,
                                 default = nil)
  if valid_601795 != nil:
    section.add "X-Amz-Signature", valid_601795
  var valid_601796 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601796 = validateParameter(valid_601796, JString, required = false,
                                 default = nil)
  if valid_601796 != nil:
    section.add "X-Amz-SignedHeaders", valid_601796
  var valid_601797 = header.getOrDefault("X-Amz-Credential")
  valid_601797 = validateParameter(valid_601797, JString, required = false,
                                 default = nil)
  if valid_601797 != nil:
    section.add "X-Amz-Credential", valid_601797
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601798: Call_GetDescribeConfigurationSettings_601783;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a description of the settings for the specified configuration set, that is, either a configuration template or the configuration set associated with a running environment.</p> <p>When describing the settings for the configuration set associated with a running environment, it is possible to receive two sets of setting descriptions. One is the deployed configuration set, and the other is a draft configuration of an environment that is either in the process of deployment or that failed to deploy.</p> <p>Related Topics</p> <ul> <li> <p> <a>DeleteEnvironmentConfiguration</a> </p> </li> </ul>
  ## 
  let valid = call_601798.validator(path, query, header, formData, body)
  let scheme = call_601798.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601798.url(scheme.get, call_601798.host, call_601798.base,
                         call_601798.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601798, url, valid)

proc call*(call_601799: Call_GetDescribeConfigurationSettings_601783;
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
  var query_601800 = newJObject()
  add(query_601800, "ApplicationName", newJString(ApplicationName))
  add(query_601800, "EnvironmentName", newJString(EnvironmentName))
  add(query_601800, "Action", newJString(Action))
  add(query_601800, "TemplateName", newJString(TemplateName))
  add(query_601800, "Version", newJString(Version))
  result = call_601799.call(nil, query_601800, nil, nil, nil)

var getDescribeConfigurationSettings* = Call_GetDescribeConfigurationSettings_601783(
    name: "getDescribeConfigurationSettings", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationSettings",
    validator: validate_GetDescribeConfigurationSettings_601784, base: "/",
    url: url_GetDescribeConfigurationSettings_601785,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentHealth_601838 = ref object of OpenApiRestCall_600438
proc url_PostDescribeEnvironmentHealth_601840(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEnvironmentHealth_601839(path: JsonNode; query: JsonNode;
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
  var valid_601841 = query.getOrDefault("Action")
  valid_601841 = validateParameter(valid_601841, JString, required = true, default = newJString(
      "DescribeEnvironmentHealth"))
  if valid_601841 != nil:
    section.add "Action", valid_601841
  var valid_601842 = query.getOrDefault("Version")
  valid_601842 = validateParameter(valid_601842, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601842 != nil:
    section.add "Version", valid_601842
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601843 = header.getOrDefault("X-Amz-Date")
  valid_601843 = validateParameter(valid_601843, JString, required = false,
                                 default = nil)
  if valid_601843 != nil:
    section.add "X-Amz-Date", valid_601843
  var valid_601844 = header.getOrDefault("X-Amz-Security-Token")
  valid_601844 = validateParameter(valid_601844, JString, required = false,
                                 default = nil)
  if valid_601844 != nil:
    section.add "X-Amz-Security-Token", valid_601844
  var valid_601845 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601845 = validateParameter(valid_601845, JString, required = false,
                                 default = nil)
  if valid_601845 != nil:
    section.add "X-Amz-Content-Sha256", valid_601845
  var valid_601846 = header.getOrDefault("X-Amz-Algorithm")
  valid_601846 = validateParameter(valid_601846, JString, required = false,
                                 default = nil)
  if valid_601846 != nil:
    section.add "X-Amz-Algorithm", valid_601846
  var valid_601847 = header.getOrDefault("X-Amz-Signature")
  valid_601847 = validateParameter(valid_601847, JString, required = false,
                                 default = nil)
  if valid_601847 != nil:
    section.add "X-Amz-Signature", valid_601847
  var valid_601848 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601848 = validateParameter(valid_601848, JString, required = false,
                                 default = nil)
  if valid_601848 != nil:
    section.add "X-Amz-SignedHeaders", valid_601848
  var valid_601849 = header.getOrDefault("X-Amz-Credential")
  valid_601849 = validateParameter(valid_601849, JString, required = false,
                                 default = nil)
  if valid_601849 != nil:
    section.add "X-Amz-Credential", valid_601849
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentId: JString
  ##                : <p>Specify the environment by ID.</p> <p>You must specify either this or an EnvironmentName, or both.</p>
  ##   EnvironmentName: JString
  ##                  : <p>Specify the environment by name.</p> <p>You must specify either this or an EnvironmentName, or both.</p>
  ##   AttributeNames: JArray
  ##                 : Specify the response elements to return. To retrieve all attributes, set to <code>All</code>. If no attribute names are specified, returns the name of the environment.
  section = newJObject()
  var valid_601850 = formData.getOrDefault("EnvironmentId")
  valid_601850 = validateParameter(valid_601850, JString, required = false,
                                 default = nil)
  if valid_601850 != nil:
    section.add "EnvironmentId", valid_601850
  var valid_601851 = formData.getOrDefault("EnvironmentName")
  valid_601851 = validateParameter(valid_601851, JString, required = false,
                                 default = nil)
  if valid_601851 != nil:
    section.add "EnvironmentName", valid_601851
  var valid_601852 = formData.getOrDefault("AttributeNames")
  valid_601852 = validateParameter(valid_601852, JArray, required = false,
                                 default = nil)
  if valid_601852 != nil:
    section.add "AttributeNames", valid_601852
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601853: Call_PostDescribeEnvironmentHealth_601838; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the overall health of the specified environment. The <b>DescribeEnvironmentHealth</b> operation is only available with AWS Elastic Beanstalk Enhanced Health.
  ## 
  let valid = call_601853.validator(path, query, header, formData, body)
  let scheme = call_601853.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601853.url(scheme.get, call_601853.host, call_601853.base,
                         call_601853.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601853, url, valid)

proc call*(call_601854: Call_PostDescribeEnvironmentHealth_601838;
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
  var query_601855 = newJObject()
  var formData_601856 = newJObject()
  add(formData_601856, "EnvironmentId", newJString(EnvironmentId))
  add(formData_601856, "EnvironmentName", newJString(EnvironmentName))
  add(query_601855, "Action", newJString(Action))
  if AttributeNames != nil:
    formData_601856.add "AttributeNames", AttributeNames
  add(query_601855, "Version", newJString(Version))
  result = call_601854.call(nil, query_601855, nil, formData_601856, nil)

var postDescribeEnvironmentHealth* = Call_PostDescribeEnvironmentHealth_601838(
    name: "postDescribeEnvironmentHealth", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentHealth",
    validator: validate_PostDescribeEnvironmentHealth_601839, base: "/",
    url: url_PostDescribeEnvironmentHealth_601840,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentHealth_601820 = ref object of OpenApiRestCall_600438
proc url_GetDescribeEnvironmentHealth_601822(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEnvironmentHealth_601821(path: JsonNode; query: JsonNode;
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
  var valid_601823 = query.getOrDefault("AttributeNames")
  valid_601823 = validateParameter(valid_601823, JArray, required = false,
                                 default = nil)
  if valid_601823 != nil:
    section.add "AttributeNames", valid_601823
  var valid_601824 = query.getOrDefault("EnvironmentName")
  valid_601824 = validateParameter(valid_601824, JString, required = false,
                                 default = nil)
  if valid_601824 != nil:
    section.add "EnvironmentName", valid_601824
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601825 = query.getOrDefault("Action")
  valid_601825 = validateParameter(valid_601825, JString, required = true, default = newJString(
      "DescribeEnvironmentHealth"))
  if valid_601825 != nil:
    section.add "Action", valid_601825
  var valid_601826 = query.getOrDefault("EnvironmentId")
  valid_601826 = validateParameter(valid_601826, JString, required = false,
                                 default = nil)
  if valid_601826 != nil:
    section.add "EnvironmentId", valid_601826
  var valid_601827 = query.getOrDefault("Version")
  valid_601827 = validateParameter(valid_601827, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601827 != nil:
    section.add "Version", valid_601827
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601828 = header.getOrDefault("X-Amz-Date")
  valid_601828 = validateParameter(valid_601828, JString, required = false,
                                 default = nil)
  if valid_601828 != nil:
    section.add "X-Amz-Date", valid_601828
  var valid_601829 = header.getOrDefault("X-Amz-Security-Token")
  valid_601829 = validateParameter(valid_601829, JString, required = false,
                                 default = nil)
  if valid_601829 != nil:
    section.add "X-Amz-Security-Token", valid_601829
  var valid_601830 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601830 = validateParameter(valid_601830, JString, required = false,
                                 default = nil)
  if valid_601830 != nil:
    section.add "X-Amz-Content-Sha256", valid_601830
  var valid_601831 = header.getOrDefault("X-Amz-Algorithm")
  valid_601831 = validateParameter(valid_601831, JString, required = false,
                                 default = nil)
  if valid_601831 != nil:
    section.add "X-Amz-Algorithm", valid_601831
  var valid_601832 = header.getOrDefault("X-Amz-Signature")
  valid_601832 = validateParameter(valid_601832, JString, required = false,
                                 default = nil)
  if valid_601832 != nil:
    section.add "X-Amz-Signature", valid_601832
  var valid_601833 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601833 = validateParameter(valid_601833, JString, required = false,
                                 default = nil)
  if valid_601833 != nil:
    section.add "X-Amz-SignedHeaders", valid_601833
  var valid_601834 = header.getOrDefault("X-Amz-Credential")
  valid_601834 = validateParameter(valid_601834, JString, required = false,
                                 default = nil)
  if valid_601834 != nil:
    section.add "X-Amz-Credential", valid_601834
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601835: Call_GetDescribeEnvironmentHealth_601820; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the overall health of the specified environment. The <b>DescribeEnvironmentHealth</b> operation is only available with AWS Elastic Beanstalk Enhanced Health.
  ## 
  let valid = call_601835.validator(path, query, header, formData, body)
  let scheme = call_601835.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601835.url(scheme.get, call_601835.host, call_601835.base,
                         call_601835.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601835, url, valid)

proc call*(call_601836: Call_GetDescribeEnvironmentHealth_601820;
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
  var query_601837 = newJObject()
  if AttributeNames != nil:
    query_601837.add "AttributeNames", AttributeNames
  add(query_601837, "EnvironmentName", newJString(EnvironmentName))
  add(query_601837, "Action", newJString(Action))
  add(query_601837, "EnvironmentId", newJString(EnvironmentId))
  add(query_601837, "Version", newJString(Version))
  result = call_601836.call(nil, query_601837, nil, nil, nil)

var getDescribeEnvironmentHealth* = Call_GetDescribeEnvironmentHealth_601820(
    name: "getDescribeEnvironmentHealth", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentHealth",
    validator: validate_GetDescribeEnvironmentHealth_601821, base: "/",
    url: url_GetDescribeEnvironmentHealth_601822,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentManagedActionHistory_601876 = ref object of OpenApiRestCall_600438
proc url_PostDescribeEnvironmentManagedActionHistory_601878(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEnvironmentManagedActionHistory_601877(path: JsonNode;
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
  var valid_601879 = query.getOrDefault("Action")
  valid_601879 = validateParameter(valid_601879, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActionHistory"))
  if valid_601879 != nil:
    section.add "Action", valid_601879
  var valid_601880 = query.getOrDefault("Version")
  valid_601880 = validateParameter(valid_601880, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601880 != nil:
    section.add "Version", valid_601880
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601881 = header.getOrDefault("X-Amz-Date")
  valid_601881 = validateParameter(valid_601881, JString, required = false,
                                 default = nil)
  if valid_601881 != nil:
    section.add "X-Amz-Date", valid_601881
  var valid_601882 = header.getOrDefault("X-Amz-Security-Token")
  valid_601882 = validateParameter(valid_601882, JString, required = false,
                                 default = nil)
  if valid_601882 != nil:
    section.add "X-Amz-Security-Token", valid_601882
  var valid_601883 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601883 = validateParameter(valid_601883, JString, required = false,
                                 default = nil)
  if valid_601883 != nil:
    section.add "X-Amz-Content-Sha256", valid_601883
  var valid_601884 = header.getOrDefault("X-Amz-Algorithm")
  valid_601884 = validateParameter(valid_601884, JString, required = false,
                                 default = nil)
  if valid_601884 != nil:
    section.add "X-Amz-Algorithm", valid_601884
  var valid_601885 = header.getOrDefault("X-Amz-Signature")
  valid_601885 = validateParameter(valid_601885, JString, required = false,
                                 default = nil)
  if valid_601885 != nil:
    section.add "X-Amz-Signature", valid_601885
  var valid_601886 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601886 = validateParameter(valid_601886, JString, required = false,
                                 default = nil)
  if valid_601886 != nil:
    section.add "X-Amz-SignedHeaders", valid_601886
  var valid_601887 = header.getOrDefault("X-Amz-Credential")
  valid_601887 = validateParameter(valid_601887, JString, required = false,
                                 default = nil)
  if valid_601887 != nil:
    section.add "X-Amz-Credential", valid_601887
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
  var valid_601888 = formData.getOrDefault("NextToken")
  valid_601888 = validateParameter(valid_601888, JString, required = false,
                                 default = nil)
  if valid_601888 != nil:
    section.add "NextToken", valid_601888
  var valid_601889 = formData.getOrDefault("EnvironmentId")
  valid_601889 = validateParameter(valid_601889, JString, required = false,
                                 default = nil)
  if valid_601889 != nil:
    section.add "EnvironmentId", valid_601889
  var valid_601890 = formData.getOrDefault("EnvironmentName")
  valid_601890 = validateParameter(valid_601890, JString, required = false,
                                 default = nil)
  if valid_601890 != nil:
    section.add "EnvironmentName", valid_601890
  var valid_601891 = formData.getOrDefault("MaxItems")
  valid_601891 = validateParameter(valid_601891, JInt, required = false, default = nil)
  if valid_601891 != nil:
    section.add "MaxItems", valid_601891
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601892: Call_PostDescribeEnvironmentManagedActionHistory_601876;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists an environment's completed and failed managed actions.
  ## 
  let valid = call_601892.validator(path, query, header, formData, body)
  let scheme = call_601892.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601892.url(scheme.get, call_601892.host, call_601892.base,
                         call_601892.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601892, url, valid)

proc call*(call_601893: Call_PostDescribeEnvironmentManagedActionHistory_601876;
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
  var query_601894 = newJObject()
  var formData_601895 = newJObject()
  add(formData_601895, "NextToken", newJString(NextToken))
  add(formData_601895, "EnvironmentId", newJString(EnvironmentId))
  add(formData_601895, "EnvironmentName", newJString(EnvironmentName))
  add(query_601894, "Action", newJString(Action))
  add(formData_601895, "MaxItems", newJInt(MaxItems))
  add(query_601894, "Version", newJString(Version))
  result = call_601893.call(nil, query_601894, nil, formData_601895, nil)

var postDescribeEnvironmentManagedActionHistory* = Call_PostDescribeEnvironmentManagedActionHistory_601876(
    name: "postDescribeEnvironmentManagedActionHistory",
    meth: HttpMethod.HttpPost, host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActionHistory",
    validator: validate_PostDescribeEnvironmentManagedActionHistory_601877,
    base: "/", url: url_PostDescribeEnvironmentManagedActionHistory_601878,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentManagedActionHistory_601857 = ref object of OpenApiRestCall_600438
proc url_GetDescribeEnvironmentManagedActionHistory_601859(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEnvironmentManagedActionHistory_601858(path: JsonNode;
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
  var valid_601860 = query.getOrDefault("NextToken")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "NextToken", valid_601860
  var valid_601861 = query.getOrDefault("EnvironmentName")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "EnvironmentName", valid_601861
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601862 = query.getOrDefault("Action")
  valid_601862 = validateParameter(valid_601862, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActionHistory"))
  if valid_601862 != nil:
    section.add "Action", valid_601862
  var valid_601863 = query.getOrDefault("EnvironmentId")
  valid_601863 = validateParameter(valid_601863, JString, required = false,
                                 default = nil)
  if valid_601863 != nil:
    section.add "EnvironmentId", valid_601863
  var valid_601864 = query.getOrDefault("MaxItems")
  valid_601864 = validateParameter(valid_601864, JInt, required = false, default = nil)
  if valid_601864 != nil:
    section.add "MaxItems", valid_601864
  var valid_601865 = query.getOrDefault("Version")
  valid_601865 = validateParameter(valid_601865, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601865 != nil:
    section.add "Version", valid_601865
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601866 = header.getOrDefault("X-Amz-Date")
  valid_601866 = validateParameter(valid_601866, JString, required = false,
                                 default = nil)
  if valid_601866 != nil:
    section.add "X-Amz-Date", valid_601866
  var valid_601867 = header.getOrDefault("X-Amz-Security-Token")
  valid_601867 = validateParameter(valid_601867, JString, required = false,
                                 default = nil)
  if valid_601867 != nil:
    section.add "X-Amz-Security-Token", valid_601867
  var valid_601868 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601868 = validateParameter(valid_601868, JString, required = false,
                                 default = nil)
  if valid_601868 != nil:
    section.add "X-Amz-Content-Sha256", valid_601868
  var valid_601869 = header.getOrDefault("X-Amz-Algorithm")
  valid_601869 = validateParameter(valid_601869, JString, required = false,
                                 default = nil)
  if valid_601869 != nil:
    section.add "X-Amz-Algorithm", valid_601869
  var valid_601870 = header.getOrDefault("X-Amz-Signature")
  valid_601870 = validateParameter(valid_601870, JString, required = false,
                                 default = nil)
  if valid_601870 != nil:
    section.add "X-Amz-Signature", valid_601870
  var valid_601871 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601871 = validateParameter(valid_601871, JString, required = false,
                                 default = nil)
  if valid_601871 != nil:
    section.add "X-Amz-SignedHeaders", valid_601871
  var valid_601872 = header.getOrDefault("X-Amz-Credential")
  valid_601872 = validateParameter(valid_601872, JString, required = false,
                                 default = nil)
  if valid_601872 != nil:
    section.add "X-Amz-Credential", valid_601872
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601873: Call_GetDescribeEnvironmentManagedActionHistory_601857;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists an environment's completed and failed managed actions.
  ## 
  let valid = call_601873.validator(path, query, header, formData, body)
  let scheme = call_601873.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601873.url(scheme.get, call_601873.host, call_601873.base,
                         call_601873.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601873, url, valid)

proc call*(call_601874: Call_GetDescribeEnvironmentManagedActionHistory_601857;
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
  var query_601875 = newJObject()
  add(query_601875, "NextToken", newJString(NextToken))
  add(query_601875, "EnvironmentName", newJString(EnvironmentName))
  add(query_601875, "Action", newJString(Action))
  add(query_601875, "EnvironmentId", newJString(EnvironmentId))
  add(query_601875, "MaxItems", newJInt(MaxItems))
  add(query_601875, "Version", newJString(Version))
  result = call_601874.call(nil, query_601875, nil, nil, nil)

var getDescribeEnvironmentManagedActionHistory* = Call_GetDescribeEnvironmentManagedActionHistory_601857(
    name: "getDescribeEnvironmentManagedActionHistory", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActionHistory",
    validator: validate_GetDescribeEnvironmentManagedActionHistory_601858,
    base: "/", url: url_GetDescribeEnvironmentManagedActionHistory_601859,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentManagedActions_601914 = ref object of OpenApiRestCall_600438
proc url_PostDescribeEnvironmentManagedActions_601916(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEnvironmentManagedActions_601915(path: JsonNode;
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
  var valid_601917 = query.getOrDefault("Action")
  valid_601917 = validateParameter(valid_601917, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActions"))
  if valid_601917 != nil:
    section.add "Action", valid_601917
  var valid_601918 = query.getOrDefault("Version")
  valid_601918 = validateParameter(valid_601918, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601918 != nil:
    section.add "Version", valid_601918
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601919 = header.getOrDefault("X-Amz-Date")
  valid_601919 = validateParameter(valid_601919, JString, required = false,
                                 default = nil)
  if valid_601919 != nil:
    section.add "X-Amz-Date", valid_601919
  var valid_601920 = header.getOrDefault("X-Amz-Security-Token")
  valid_601920 = validateParameter(valid_601920, JString, required = false,
                                 default = nil)
  if valid_601920 != nil:
    section.add "X-Amz-Security-Token", valid_601920
  var valid_601921 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601921 = validateParameter(valid_601921, JString, required = false,
                                 default = nil)
  if valid_601921 != nil:
    section.add "X-Amz-Content-Sha256", valid_601921
  var valid_601922 = header.getOrDefault("X-Amz-Algorithm")
  valid_601922 = validateParameter(valid_601922, JString, required = false,
                                 default = nil)
  if valid_601922 != nil:
    section.add "X-Amz-Algorithm", valid_601922
  var valid_601923 = header.getOrDefault("X-Amz-Signature")
  valid_601923 = validateParameter(valid_601923, JString, required = false,
                                 default = nil)
  if valid_601923 != nil:
    section.add "X-Amz-Signature", valid_601923
  var valid_601924 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601924 = validateParameter(valid_601924, JString, required = false,
                                 default = nil)
  if valid_601924 != nil:
    section.add "X-Amz-SignedHeaders", valid_601924
  var valid_601925 = header.getOrDefault("X-Amz-Credential")
  valid_601925 = validateParameter(valid_601925, JString, required = false,
                                 default = nil)
  if valid_601925 != nil:
    section.add "X-Amz-Credential", valid_601925
  result.add "header", section
  ## parameters in `formData` object:
  ##   Status: JString
  ##         : To show only actions with a particular status, specify a status.
  ##   EnvironmentId: JString
  ##                : The environment ID of the target environment.
  ##   EnvironmentName: JString
  ##                  : The name of the target environment.
  section = newJObject()
  var valid_601926 = formData.getOrDefault("Status")
  valid_601926 = validateParameter(valid_601926, JString, required = false,
                                 default = newJString("Scheduled"))
  if valid_601926 != nil:
    section.add "Status", valid_601926
  var valid_601927 = formData.getOrDefault("EnvironmentId")
  valid_601927 = validateParameter(valid_601927, JString, required = false,
                                 default = nil)
  if valid_601927 != nil:
    section.add "EnvironmentId", valid_601927
  var valid_601928 = formData.getOrDefault("EnvironmentName")
  valid_601928 = validateParameter(valid_601928, JString, required = false,
                                 default = nil)
  if valid_601928 != nil:
    section.add "EnvironmentName", valid_601928
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601929: Call_PostDescribeEnvironmentManagedActions_601914;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists an environment's upcoming and in-progress managed actions.
  ## 
  let valid = call_601929.validator(path, query, header, formData, body)
  let scheme = call_601929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601929.url(scheme.get, call_601929.host, call_601929.base,
                         call_601929.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601929, url, valid)

proc call*(call_601930: Call_PostDescribeEnvironmentManagedActions_601914;
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
  var query_601931 = newJObject()
  var formData_601932 = newJObject()
  add(formData_601932, "Status", newJString(Status))
  add(formData_601932, "EnvironmentId", newJString(EnvironmentId))
  add(formData_601932, "EnvironmentName", newJString(EnvironmentName))
  add(query_601931, "Action", newJString(Action))
  add(query_601931, "Version", newJString(Version))
  result = call_601930.call(nil, query_601931, nil, formData_601932, nil)

var postDescribeEnvironmentManagedActions* = Call_PostDescribeEnvironmentManagedActions_601914(
    name: "postDescribeEnvironmentManagedActions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActions",
    validator: validate_PostDescribeEnvironmentManagedActions_601915, base: "/",
    url: url_PostDescribeEnvironmentManagedActions_601916,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentManagedActions_601896 = ref object of OpenApiRestCall_600438
proc url_GetDescribeEnvironmentManagedActions_601898(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEnvironmentManagedActions_601897(path: JsonNode;
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
  var valid_601899 = query.getOrDefault("Status")
  valid_601899 = validateParameter(valid_601899, JString, required = false,
                                 default = newJString("Scheduled"))
  if valid_601899 != nil:
    section.add "Status", valid_601899
  var valid_601900 = query.getOrDefault("EnvironmentName")
  valid_601900 = validateParameter(valid_601900, JString, required = false,
                                 default = nil)
  if valid_601900 != nil:
    section.add "EnvironmentName", valid_601900
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601901 = query.getOrDefault("Action")
  valid_601901 = validateParameter(valid_601901, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActions"))
  if valid_601901 != nil:
    section.add "Action", valid_601901
  var valid_601902 = query.getOrDefault("EnvironmentId")
  valid_601902 = validateParameter(valid_601902, JString, required = false,
                                 default = nil)
  if valid_601902 != nil:
    section.add "EnvironmentId", valid_601902
  var valid_601903 = query.getOrDefault("Version")
  valid_601903 = validateParameter(valid_601903, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601903 != nil:
    section.add "Version", valid_601903
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601904 = header.getOrDefault("X-Amz-Date")
  valid_601904 = validateParameter(valid_601904, JString, required = false,
                                 default = nil)
  if valid_601904 != nil:
    section.add "X-Amz-Date", valid_601904
  var valid_601905 = header.getOrDefault("X-Amz-Security-Token")
  valid_601905 = validateParameter(valid_601905, JString, required = false,
                                 default = nil)
  if valid_601905 != nil:
    section.add "X-Amz-Security-Token", valid_601905
  var valid_601906 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601906 = validateParameter(valid_601906, JString, required = false,
                                 default = nil)
  if valid_601906 != nil:
    section.add "X-Amz-Content-Sha256", valid_601906
  var valid_601907 = header.getOrDefault("X-Amz-Algorithm")
  valid_601907 = validateParameter(valid_601907, JString, required = false,
                                 default = nil)
  if valid_601907 != nil:
    section.add "X-Amz-Algorithm", valid_601907
  var valid_601908 = header.getOrDefault("X-Amz-Signature")
  valid_601908 = validateParameter(valid_601908, JString, required = false,
                                 default = nil)
  if valid_601908 != nil:
    section.add "X-Amz-Signature", valid_601908
  var valid_601909 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601909 = validateParameter(valid_601909, JString, required = false,
                                 default = nil)
  if valid_601909 != nil:
    section.add "X-Amz-SignedHeaders", valid_601909
  var valid_601910 = header.getOrDefault("X-Amz-Credential")
  valid_601910 = validateParameter(valid_601910, JString, required = false,
                                 default = nil)
  if valid_601910 != nil:
    section.add "X-Amz-Credential", valid_601910
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601911: Call_GetDescribeEnvironmentManagedActions_601896;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists an environment's upcoming and in-progress managed actions.
  ## 
  let valid = call_601911.validator(path, query, header, formData, body)
  let scheme = call_601911.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601911.url(scheme.get, call_601911.host, call_601911.base,
                         call_601911.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601911, url, valid)

proc call*(call_601912: Call_GetDescribeEnvironmentManagedActions_601896;
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
  var query_601913 = newJObject()
  add(query_601913, "Status", newJString(Status))
  add(query_601913, "EnvironmentName", newJString(EnvironmentName))
  add(query_601913, "Action", newJString(Action))
  add(query_601913, "EnvironmentId", newJString(EnvironmentId))
  add(query_601913, "Version", newJString(Version))
  result = call_601912.call(nil, query_601913, nil, nil, nil)

var getDescribeEnvironmentManagedActions* = Call_GetDescribeEnvironmentManagedActions_601896(
    name: "getDescribeEnvironmentManagedActions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActions",
    validator: validate_GetDescribeEnvironmentManagedActions_601897, base: "/",
    url: url_GetDescribeEnvironmentManagedActions_601898,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentResources_601950 = ref object of OpenApiRestCall_600438
proc url_PostDescribeEnvironmentResources_601952(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEnvironmentResources_601951(path: JsonNode;
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
  var valid_601953 = query.getOrDefault("Action")
  valid_601953 = validateParameter(valid_601953, JString, required = true, default = newJString(
      "DescribeEnvironmentResources"))
  if valid_601953 != nil:
    section.add "Action", valid_601953
  var valid_601954 = query.getOrDefault("Version")
  valid_601954 = validateParameter(valid_601954, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601954 != nil:
    section.add "Version", valid_601954
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601955 = header.getOrDefault("X-Amz-Date")
  valid_601955 = validateParameter(valid_601955, JString, required = false,
                                 default = nil)
  if valid_601955 != nil:
    section.add "X-Amz-Date", valid_601955
  var valid_601956 = header.getOrDefault("X-Amz-Security-Token")
  valid_601956 = validateParameter(valid_601956, JString, required = false,
                                 default = nil)
  if valid_601956 != nil:
    section.add "X-Amz-Security-Token", valid_601956
  var valid_601957 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601957 = validateParameter(valid_601957, JString, required = false,
                                 default = nil)
  if valid_601957 != nil:
    section.add "X-Amz-Content-Sha256", valid_601957
  var valid_601958 = header.getOrDefault("X-Amz-Algorithm")
  valid_601958 = validateParameter(valid_601958, JString, required = false,
                                 default = nil)
  if valid_601958 != nil:
    section.add "X-Amz-Algorithm", valid_601958
  var valid_601959 = header.getOrDefault("X-Amz-Signature")
  valid_601959 = validateParameter(valid_601959, JString, required = false,
                                 default = nil)
  if valid_601959 != nil:
    section.add "X-Amz-Signature", valid_601959
  var valid_601960 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601960 = validateParameter(valid_601960, JString, required = false,
                                 default = nil)
  if valid_601960 != nil:
    section.add "X-Amz-SignedHeaders", valid_601960
  var valid_601961 = header.getOrDefault("X-Amz-Credential")
  valid_601961 = validateParameter(valid_601961, JString, required = false,
                                 default = nil)
  if valid_601961 != nil:
    section.add "X-Amz-Credential", valid_601961
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to retrieve AWS resource usage data.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to retrieve AWS resource usage data.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_601962 = formData.getOrDefault("EnvironmentId")
  valid_601962 = validateParameter(valid_601962, JString, required = false,
                                 default = nil)
  if valid_601962 != nil:
    section.add "EnvironmentId", valid_601962
  var valid_601963 = formData.getOrDefault("EnvironmentName")
  valid_601963 = validateParameter(valid_601963, JString, required = false,
                                 default = nil)
  if valid_601963 != nil:
    section.add "EnvironmentName", valid_601963
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601964: Call_PostDescribeEnvironmentResources_601950;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns AWS resources for this environment.
  ## 
  let valid = call_601964.validator(path, query, header, formData, body)
  let scheme = call_601964.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601964.url(scheme.get, call_601964.host, call_601964.base,
                         call_601964.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601964, url, valid)

proc call*(call_601965: Call_PostDescribeEnvironmentResources_601950;
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
  var query_601966 = newJObject()
  var formData_601967 = newJObject()
  add(formData_601967, "EnvironmentId", newJString(EnvironmentId))
  add(formData_601967, "EnvironmentName", newJString(EnvironmentName))
  add(query_601966, "Action", newJString(Action))
  add(query_601966, "Version", newJString(Version))
  result = call_601965.call(nil, query_601966, nil, formData_601967, nil)

var postDescribeEnvironmentResources* = Call_PostDescribeEnvironmentResources_601950(
    name: "postDescribeEnvironmentResources", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentResources",
    validator: validate_PostDescribeEnvironmentResources_601951, base: "/",
    url: url_PostDescribeEnvironmentResources_601952,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentResources_601933 = ref object of OpenApiRestCall_600438
proc url_GetDescribeEnvironmentResources_601935(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEnvironmentResources_601934(path: JsonNode;
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
  var valid_601936 = query.getOrDefault("EnvironmentName")
  valid_601936 = validateParameter(valid_601936, JString, required = false,
                                 default = nil)
  if valid_601936 != nil:
    section.add "EnvironmentName", valid_601936
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601937 = query.getOrDefault("Action")
  valid_601937 = validateParameter(valid_601937, JString, required = true, default = newJString(
      "DescribeEnvironmentResources"))
  if valid_601937 != nil:
    section.add "Action", valid_601937
  var valid_601938 = query.getOrDefault("EnvironmentId")
  valid_601938 = validateParameter(valid_601938, JString, required = false,
                                 default = nil)
  if valid_601938 != nil:
    section.add "EnvironmentId", valid_601938
  var valid_601939 = query.getOrDefault("Version")
  valid_601939 = validateParameter(valid_601939, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601939 != nil:
    section.add "Version", valid_601939
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601940 = header.getOrDefault("X-Amz-Date")
  valid_601940 = validateParameter(valid_601940, JString, required = false,
                                 default = nil)
  if valid_601940 != nil:
    section.add "X-Amz-Date", valid_601940
  var valid_601941 = header.getOrDefault("X-Amz-Security-Token")
  valid_601941 = validateParameter(valid_601941, JString, required = false,
                                 default = nil)
  if valid_601941 != nil:
    section.add "X-Amz-Security-Token", valid_601941
  var valid_601942 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601942 = validateParameter(valid_601942, JString, required = false,
                                 default = nil)
  if valid_601942 != nil:
    section.add "X-Amz-Content-Sha256", valid_601942
  var valid_601943 = header.getOrDefault("X-Amz-Algorithm")
  valid_601943 = validateParameter(valid_601943, JString, required = false,
                                 default = nil)
  if valid_601943 != nil:
    section.add "X-Amz-Algorithm", valid_601943
  var valid_601944 = header.getOrDefault("X-Amz-Signature")
  valid_601944 = validateParameter(valid_601944, JString, required = false,
                                 default = nil)
  if valid_601944 != nil:
    section.add "X-Amz-Signature", valid_601944
  var valid_601945 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601945 = validateParameter(valid_601945, JString, required = false,
                                 default = nil)
  if valid_601945 != nil:
    section.add "X-Amz-SignedHeaders", valid_601945
  var valid_601946 = header.getOrDefault("X-Amz-Credential")
  valid_601946 = validateParameter(valid_601946, JString, required = false,
                                 default = nil)
  if valid_601946 != nil:
    section.add "X-Amz-Credential", valid_601946
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601947: Call_GetDescribeEnvironmentResources_601933;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns AWS resources for this environment.
  ## 
  let valid = call_601947.validator(path, query, header, formData, body)
  let scheme = call_601947.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601947.url(scheme.get, call_601947.host, call_601947.base,
                         call_601947.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601947, url, valid)

proc call*(call_601948: Call_GetDescribeEnvironmentResources_601933;
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
  var query_601949 = newJObject()
  add(query_601949, "EnvironmentName", newJString(EnvironmentName))
  add(query_601949, "Action", newJString(Action))
  add(query_601949, "EnvironmentId", newJString(EnvironmentId))
  add(query_601949, "Version", newJString(Version))
  result = call_601948.call(nil, query_601949, nil, nil, nil)

var getDescribeEnvironmentResources* = Call_GetDescribeEnvironmentResources_601933(
    name: "getDescribeEnvironmentResources", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentResources",
    validator: validate_GetDescribeEnvironmentResources_601934, base: "/",
    url: url_GetDescribeEnvironmentResources_601935,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironments_601991 = ref object of OpenApiRestCall_600438
proc url_PostDescribeEnvironments_601993(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEnvironments_601992(path: JsonNode; query: JsonNode;
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
  var valid_601994 = query.getOrDefault("Action")
  valid_601994 = validateParameter(valid_601994, JString, required = true,
                                 default = newJString("DescribeEnvironments"))
  if valid_601994 != nil:
    section.add "Action", valid_601994
  var valid_601995 = query.getOrDefault("Version")
  valid_601995 = validateParameter(valid_601995, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601995 != nil:
    section.add "Version", valid_601995
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601996 = header.getOrDefault("X-Amz-Date")
  valid_601996 = validateParameter(valid_601996, JString, required = false,
                                 default = nil)
  if valid_601996 != nil:
    section.add "X-Amz-Date", valid_601996
  var valid_601997 = header.getOrDefault("X-Amz-Security-Token")
  valid_601997 = validateParameter(valid_601997, JString, required = false,
                                 default = nil)
  if valid_601997 != nil:
    section.add "X-Amz-Security-Token", valid_601997
  var valid_601998 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601998 = validateParameter(valid_601998, JString, required = false,
                                 default = nil)
  if valid_601998 != nil:
    section.add "X-Amz-Content-Sha256", valid_601998
  var valid_601999 = header.getOrDefault("X-Amz-Algorithm")
  valid_601999 = validateParameter(valid_601999, JString, required = false,
                                 default = nil)
  if valid_601999 != nil:
    section.add "X-Amz-Algorithm", valid_601999
  var valid_602000 = header.getOrDefault("X-Amz-Signature")
  valid_602000 = validateParameter(valid_602000, JString, required = false,
                                 default = nil)
  if valid_602000 != nil:
    section.add "X-Amz-Signature", valid_602000
  var valid_602001 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602001 = validateParameter(valid_602001, JString, required = false,
                                 default = nil)
  if valid_602001 != nil:
    section.add "X-Amz-SignedHeaders", valid_602001
  var valid_602002 = header.getOrDefault("X-Amz-Credential")
  valid_602002 = validateParameter(valid_602002, JString, required = false,
                                 default = nil)
  if valid_602002 != nil:
    section.add "X-Amz-Credential", valid_602002
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
  var valid_602003 = formData.getOrDefault("NextToken")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "NextToken", valid_602003
  var valid_602004 = formData.getOrDefault("VersionLabel")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "VersionLabel", valid_602004
  var valid_602005 = formData.getOrDefault("EnvironmentNames")
  valid_602005 = validateParameter(valid_602005, JArray, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "EnvironmentNames", valid_602005
  var valid_602006 = formData.getOrDefault("IncludedDeletedBackTo")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "IncludedDeletedBackTo", valid_602006
  var valid_602007 = formData.getOrDefault("ApplicationName")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "ApplicationName", valid_602007
  var valid_602008 = formData.getOrDefault("EnvironmentIds")
  valid_602008 = validateParameter(valid_602008, JArray, required = false,
                                 default = nil)
  if valid_602008 != nil:
    section.add "EnvironmentIds", valid_602008
  var valid_602009 = formData.getOrDefault("IncludeDeleted")
  valid_602009 = validateParameter(valid_602009, JBool, required = false, default = nil)
  if valid_602009 != nil:
    section.add "IncludeDeleted", valid_602009
  var valid_602010 = formData.getOrDefault("MaxRecords")
  valid_602010 = validateParameter(valid_602010, JInt, required = false, default = nil)
  if valid_602010 != nil:
    section.add "MaxRecords", valid_602010
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602011: Call_PostDescribeEnvironments_601991; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns descriptions for existing environments.
  ## 
  let valid = call_602011.validator(path, query, header, formData, body)
  let scheme = call_602011.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602011.url(scheme.get, call_602011.host, call_602011.base,
                         call_602011.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602011, url, valid)

proc call*(call_602012: Call_PostDescribeEnvironments_601991;
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
  var query_602013 = newJObject()
  var formData_602014 = newJObject()
  add(formData_602014, "NextToken", newJString(NextToken))
  add(formData_602014, "VersionLabel", newJString(VersionLabel))
  if EnvironmentNames != nil:
    formData_602014.add "EnvironmentNames", EnvironmentNames
  add(formData_602014, "IncludedDeletedBackTo", newJString(IncludedDeletedBackTo))
  add(query_602013, "Action", newJString(Action))
  add(formData_602014, "ApplicationName", newJString(ApplicationName))
  if EnvironmentIds != nil:
    formData_602014.add "EnvironmentIds", EnvironmentIds
  add(formData_602014, "IncludeDeleted", newJBool(IncludeDeleted))
  add(formData_602014, "MaxRecords", newJInt(MaxRecords))
  add(query_602013, "Version", newJString(Version))
  result = call_602012.call(nil, query_602013, nil, formData_602014, nil)

var postDescribeEnvironments* = Call_PostDescribeEnvironments_601991(
    name: "postDescribeEnvironments", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironments",
    validator: validate_PostDescribeEnvironments_601992, base: "/",
    url: url_PostDescribeEnvironments_601993, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironments_601968 = ref object of OpenApiRestCall_600438
proc url_GetDescribeEnvironments_601970(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEnvironments_601969(path: JsonNode; query: JsonNode;
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
  var valid_601971 = query.getOrDefault("VersionLabel")
  valid_601971 = validateParameter(valid_601971, JString, required = false,
                                 default = nil)
  if valid_601971 != nil:
    section.add "VersionLabel", valid_601971
  var valid_601972 = query.getOrDefault("MaxRecords")
  valid_601972 = validateParameter(valid_601972, JInt, required = false, default = nil)
  if valid_601972 != nil:
    section.add "MaxRecords", valid_601972
  var valid_601973 = query.getOrDefault("ApplicationName")
  valid_601973 = validateParameter(valid_601973, JString, required = false,
                                 default = nil)
  if valid_601973 != nil:
    section.add "ApplicationName", valid_601973
  var valid_601974 = query.getOrDefault("IncludeDeleted")
  valid_601974 = validateParameter(valid_601974, JBool, required = false, default = nil)
  if valid_601974 != nil:
    section.add "IncludeDeleted", valid_601974
  var valid_601975 = query.getOrDefault("NextToken")
  valid_601975 = validateParameter(valid_601975, JString, required = false,
                                 default = nil)
  if valid_601975 != nil:
    section.add "NextToken", valid_601975
  var valid_601976 = query.getOrDefault("EnvironmentIds")
  valid_601976 = validateParameter(valid_601976, JArray, required = false,
                                 default = nil)
  if valid_601976 != nil:
    section.add "EnvironmentIds", valid_601976
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601977 = query.getOrDefault("Action")
  valid_601977 = validateParameter(valid_601977, JString, required = true,
                                 default = newJString("DescribeEnvironments"))
  if valid_601977 != nil:
    section.add "Action", valid_601977
  var valid_601978 = query.getOrDefault("IncludedDeletedBackTo")
  valid_601978 = validateParameter(valid_601978, JString, required = false,
                                 default = nil)
  if valid_601978 != nil:
    section.add "IncludedDeletedBackTo", valid_601978
  var valid_601979 = query.getOrDefault("EnvironmentNames")
  valid_601979 = validateParameter(valid_601979, JArray, required = false,
                                 default = nil)
  if valid_601979 != nil:
    section.add "EnvironmentNames", valid_601979
  var valid_601980 = query.getOrDefault("Version")
  valid_601980 = validateParameter(valid_601980, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601980 != nil:
    section.add "Version", valid_601980
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601981 = header.getOrDefault("X-Amz-Date")
  valid_601981 = validateParameter(valid_601981, JString, required = false,
                                 default = nil)
  if valid_601981 != nil:
    section.add "X-Amz-Date", valid_601981
  var valid_601982 = header.getOrDefault("X-Amz-Security-Token")
  valid_601982 = validateParameter(valid_601982, JString, required = false,
                                 default = nil)
  if valid_601982 != nil:
    section.add "X-Amz-Security-Token", valid_601982
  var valid_601983 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601983 = validateParameter(valid_601983, JString, required = false,
                                 default = nil)
  if valid_601983 != nil:
    section.add "X-Amz-Content-Sha256", valid_601983
  var valid_601984 = header.getOrDefault("X-Amz-Algorithm")
  valid_601984 = validateParameter(valid_601984, JString, required = false,
                                 default = nil)
  if valid_601984 != nil:
    section.add "X-Amz-Algorithm", valid_601984
  var valid_601985 = header.getOrDefault("X-Amz-Signature")
  valid_601985 = validateParameter(valid_601985, JString, required = false,
                                 default = nil)
  if valid_601985 != nil:
    section.add "X-Amz-Signature", valid_601985
  var valid_601986 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601986 = validateParameter(valid_601986, JString, required = false,
                                 default = nil)
  if valid_601986 != nil:
    section.add "X-Amz-SignedHeaders", valid_601986
  var valid_601987 = header.getOrDefault("X-Amz-Credential")
  valid_601987 = validateParameter(valid_601987, JString, required = false,
                                 default = nil)
  if valid_601987 != nil:
    section.add "X-Amz-Credential", valid_601987
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601988: Call_GetDescribeEnvironments_601968; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns descriptions for existing environments.
  ## 
  let valid = call_601988.validator(path, query, header, formData, body)
  let scheme = call_601988.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601988.url(scheme.get, call_601988.host, call_601988.base,
                         call_601988.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_601988, url, valid)

proc call*(call_601989: Call_GetDescribeEnvironments_601968;
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
  var query_601990 = newJObject()
  add(query_601990, "VersionLabel", newJString(VersionLabel))
  add(query_601990, "MaxRecords", newJInt(MaxRecords))
  add(query_601990, "ApplicationName", newJString(ApplicationName))
  add(query_601990, "IncludeDeleted", newJBool(IncludeDeleted))
  add(query_601990, "NextToken", newJString(NextToken))
  if EnvironmentIds != nil:
    query_601990.add "EnvironmentIds", EnvironmentIds
  add(query_601990, "Action", newJString(Action))
  add(query_601990, "IncludedDeletedBackTo", newJString(IncludedDeletedBackTo))
  if EnvironmentNames != nil:
    query_601990.add "EnvironmentNames", EnvironmentNames
  add(query_601990, "Version", newJString(Version))
  result = call_601989.call(nil, query_601990, nil, nil, nil)

var getDescribeEnvironments* = Call_GetDescribeEnvironments_601968(
    name: "getDescribeEnvironments", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironments",
    validator: validate_GetDescribeEnvironments_601969, base: "/",
    url: url_GetDescribeEnvironments_601970, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_602042 = ref object of OpenApiRestCall_600438
proc url_PostDescribeEvents_602044(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEvents_602043(path: JsonNode; query: JsonNode;
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
  var valid_602045 = query.getOrDefault("Action")
  valid_602045 = validateParameter(valid_602045, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_602045 != nil:
    section.add "Action", valid_602045
  var valid_602046 = query.getOrDefault("Version")
  valid_602046 = validateParameter(valid_602046, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602046 != nil:
    section.add "Version", valid_602046
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602047 = header.getOrDefault("X-Amz-Date")
  valid_602047 = validateParameter(valid_602047, JString, required = false,
                                 default = nil)
  if valid_602047 != nil:
    section.add "X-Amz-Date", valid_602047
  var valid_602048 = header.getOrDefault("X-Amz-Security-Token")
  valid_602048 = validateParameter(valid_602048, JString, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "X-Amz-Security-Token", valid_602048
  var valid_602049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "X-Amz-Content-Sha256", valid_602049
  var valid_602050 = header.getOrDefault("X-Amz-Algorithm")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "X-Amz-Algorithm", valid_602050
  var valid_602051 = header.getOrDefault("X-Amz-Signature")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "X-Amz-Signature", valid_602051
  var valid_602052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602052 = validateParameter(valid_602052, JString, required = false,
                                 default = nil)
  if valid_602052 != nil:
    section.add "X-Amz-SignedHeaders", valid_602052
  var valid_602053 = header.getOrDefault("X-Amz-Credential")
  valid_602053 = validateParameter(valid_602053, JString, required = false,
                                 default = nil)
  if valid_602053 != nil:
    section.add "X-Amz-Credential", valid_602053
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
  var valid_602054 = formData.getOrDefault("NextToken")
  valid_602054 = validateParameter(valid_602054, JString, required = false,
                                 default = nil)
  if valid_602054 != nil:
    section.add "NextToken", valid_602054
  var valid_602055 = formData.getOrDefault("VersionLabel")
  valid_602055 = validateParameter(valid_602055, JString, required = false,
                                 default = nil)
  if valid_602055 != nil:
    section.add "VersionLabel", valid_602055
  var valid_602056 = formData.getOrDefault("Severity")
  valid_602056 = validateParameter(valid_602056, JString, required = false,
                                 default = newJString("TRACE"))
  if valid_602056 != nil:
    section.add "Severity", valid_602056
  var valid_602057 = formData.getOrDefault("EnvironmentId")
  valid_602057 = validateParameter(valid_602057, JString, required = false,
                                 default = nil)
  if valid_602057 != nil:
    section.add "EnvironmentId", valid_602057
  var valid_602058 = formData.getOrDefault("EnvironmentName")
  valid_602058 = validateParameter(valid_602058, JString, required = false,
                                 default = nil)
  if valid_602058 != nil:
    section.add "EnvironmentName", valid_602058
  var valid_602059 = formData.getOrDefault("StartTime")
  valid_602059 = validateParameter(valid_602059, JString, required = false,
                                 default = nil)
  if valid_602059 != nil:
    section.add "StartTime", valid_602059
  var valid_602060 = formData.getOrDefault("ApplicationName")
  valid_602060 = validateParameter(valid_602060, JString, required = false,
                                 default = nil)
  if valid_602060 != nil:
    section.add "ApplicationName", valid_602060
  var valid_602061 = formData.getOrDefault("EndTime")
  valid_602061 = validateParameter(valid_602061, JString, required = false,
                                 default = nil)
  if valid_602061 != nil:
    section.add "EndTime", valid_602061
  var valid_602062 = formData.getOrDefault("PlatformArn")
  valid_602062 = validateParameter(valid_602062, JString, required = false,
                                 default = nil)
  if valid_602062 != nil:
    section.add "PlatformArn", valid_602062
  var valid_602063 = formData.getOrDefault("MaxRecords")
  valid_602063 = validateParameter(valid_602063, JInt, required = false, default = nil)
  if valid_602063 != nil:
    section.add "MaxRecords", valid_602063
  var valid_602064 = formData.getOrDefault("RequestId")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "RequestId", valid_602064
  var valid_602065 = formData.getOrDefault("TemplateName")
  valid_602065 = validateParameter(valid_602065, JString, required = false,
                                 default = nil)
  if valid_602065 != nil:
    section.add "TemplateName", valid_602065
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602066: Call_PostDescribeEvents_602042; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns list of event descriptions matching criteria up to the last 6 weeks.</p> <note> <p>This action returns the most recent 1,000 events from the specified <code>NextToken</code>.</p> </note>
  ## 
  let valid = call_602066.validator(path, query, header, formData, body)
  let scheme = call_602066.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602066.url(scheme.get, call_602066.host, call_602066.base,
                         call_602066.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602066, url, valid)

proc call*(call_602067: Call_PostDescribeEvents_602042; NextToken: string = "";
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
  var query_602068 = newJObject()
  var formData_602069 = newJObject()
  add(formData_602069, "NextToken", newJString(NextToken))
  add(formData_602069, "VersionLabel", newJString(VersionLabel))
  add(formData_602069, "Severity", newJString(Severity))
  add(formData_602069, "EnvironmentId", newJString(EnvironmentId))
  add(formData_602069, "EnvironmentName", newJString(EnvironmentName))
  add(formData_602069, "StartTime", newJString(StartTime))
  add(query_602068, "Action", newJString(Action))
  add(formData_602069, "ApplicationName", newJString(ApplicationName))
  add(formData_602069, "EndTime", newJString(EndTime))
  add(formData_602069, "PlatformArn", newJString(PlatformArn))
  add(formData_602069, "MaxRecords", newJInt(MaxRecords))
  add(formData_602069, "RequestId", newJString(RequestId))
  add(formData_602069, "TemplateName", newJString(TemplateName))
  add(query_602068, "Version", newJString(Version))
  result = call_602067.call(nil, query_602068, nil, formData_602069, nil)

var postDescribeEvents* = Call_PostDescribeEvents_602042(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_602043, base: "/",
    url: url_PostDescribeEvents_602044, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_602015 = ref object of OpenApiRestCall_600438
proc url_GetDescribeEvents_602017(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEvents_602016(path: JsonNode; query: JsonNode;
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
  var valid_602018 = query.getOrDefault("VersionLabel")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "VersionLabel", valid_602018
  var valid_602019 = query.getOrDefault("MaxRecords")
  valid_602019 = validateParameter(valid_602019, JInt, required = false, default = nil)
  if valid_602019 != nil:
    section.add "MaxRecords", valid_602019
  var valid_602020 = query.getOrDefault("ApplicationName")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "ApplicationName", valid_602020
  var valid_602021 = query.getOrDefault("StartTime")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "StartTime", valid_602021
  var valid_602022 = query.getOrDefault("PlatformArn")
  valid_602022 = validateParameter(valid_602022, JString, required = false,
                                 default = nil)
  if valid_602022 != nil:
    section.add "PlatformArn", valid_602022
  var valid_602023 = query.getOrDefault("NextToken")
  valid_602023 = validateParameter(valid_602023, JString, required = false,
                                 default = nil)
  if valid_602023 != nil:
    section.add "NextToken", valid_602023
  var valid_602024 = query.getOrDefault("EnvironmentName")
  valid_602024 = validateParameter(valid_602024, JString, required = false,
                                 default = nil)
  if valid_602024 != nil:
    section.add "EnvironmentName", valid_602024
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602025 = query.getOrDefault("Action")
  valid_602025 = validateParameter(valid_602025, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_602025 != nil:
    section.add "Action", valid_602025
  var valid_602026 = query.getOrDefault("EnvironmentId")
  valid_602026 = validateParameter(valid_602026, JString, required = false,
                                 default = nil)
  if valid_602026 != nil:
    section.add "EnvironmentId", valid_602026
  var valid_602027 = query.getOrDefault("TemplateName")
  valid_602027 = validateParameter(valid_602027, JString, required = false,
                                 default = nil)
  if valid_602027 != nil:
    section.add "TemplateName", valid_602027
  var valid_602028 = query.getOrDefault("Severity")
  valid_602028 = validateParameter(valid_602028, JString, required = false,
                                 default = newJString("TRACE"))
  if valid_602028 != nil:
    section.add "Severity", valid_602028
  var valid_602029 = query.getOrDefault("RequestId")
  valid_602029 = validateParameter(valid_602029, JString, required = false,
                                 default = nil)
  if valid_602029 != nil:
    section.add "RequestId", valid_602029
  var valid_602030 = query.getOrDefault("EndTime")
  valid_602030 = validateParameter(valid_602030, JString, required = false,
                                 default = nil)
  if valid_602030 != nil:
    section.add "EndTime", valid_602030
  var valid_602031 = query.getOrDefault("Version")
  valid_602031 = validateParameter(valid_602031, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602031 != nil:
    section.add "Version", valid_602031
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602032 = header.getOrDefault("X-Amz-Date")
  valid_602032 = validateParameter(valid_602032, JString, required = false,
                                 default = nil)
  if valid_602032 != nil:
    section.add "X-Amz-Date", valid_602032
  var valid_602033 = header.getOrDefault("X-Amz-Security-Token")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "X-Amz-Security-Token", valid_602033
  var valid_602034 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602034 = validateParameter(valid_602034, JString, required = false,
                                 default = nil)
  if valid_602034 != nil:
    section.add "X-Amz-Content-Sha256", valid_602034
  var valid_602035 = header.getOrDefault("X-Amz-Algorithm")
  valid_602035 = validateParameter(valid_602035, JString, required = false,
                                 default = nil)
  if valid_602035 != nil:
    section.add "X-Amz-Algorithm", valid_602035
  var valid_602036 = header.getOrDefault("X-Amz-Signature")
  valid_602036 = validateParameter(valid_602036, JString, required = false,
                                 default = nil)
  if valid_602036 != nil:
    section.add "X-Amz-Signature", valid_602036
  var valid_602037 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602037 = validateParameter(valid_602037, JString, required = false,
                                 default = nil)
  if valid_602037 != nil:
    section.add "X-Amz-SignedHeaders", valid_602037
  var valid_602038 = header.getOrDefault("X-Amz-Credential")
  valid_602038 = validateParameter(valid_602038, JString, required = false,
                                 default = nil)
  if valid_602038 != nil:
    section.add "X-Amz-Credential", valid_602038
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602039: Call_GetDescribeEvents_602015; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns list of event descriptions matching criteria up to the last 6 weeks.</p> <note> <p>This action returns the most recent 1,000 events from the specified <code>NextToken</code>.</p> </note>
  ## 
  let valid = call_602039.validator(path, query, header, formData, body)
  let scheme = call_602039.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602039.url(scheme.get, call_602039.host, call_602039.base,
                         call_602039.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602039, url, valid)

proc call*(call_602040: Call_GetDescribeEvents_602015; VersionLabel: string = "";
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
  var query_602041 = newJObject()
  add(query_602041, "VersionLabel", newJString(VersionLabel))
  add(query_602041, "MaxRecords", newJInt(MaxRecords))
  add(query_602041, "ApplicationName", newJString(ApplicationName))
  add(query_602041, "StartTime", newJString(StartTime))
  add(query_602041, "PlatformArn", newJString(PlatformArn))
  add(query_602041, "NextToken", newJString(NextToken))
  add(query_602041, "EnvironmentName", newJString(EnvironmentName))
  add(query_602041, "Action", newJString(Action))
  add(query_602041, "EnvironmentId", newJString(EnvironmentId))
  add(query_602041, "TemplateName", newJString(TemplateName))
  add(query_602041, "Severity", newJString(Severity))
  add(query_602041, "RequestId", newJString(RequestId))
  add(query_602041, "EndTime", newJString(EndTime))
  add(query_602041, "Version", newJString(Version))
  result = call_602040.call(nil, query_602041, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_602015(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_602016,
    base: "/", url: url_GetDescribeEvents_602017,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeInstancesHealth_602089 = ref object of OpenApiRestCall_600438
proc url_PostDescribeInstancesHealth_602091(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeInstancesHealth_602090(path: JsonNode; query: JsonNode;
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
  var valid_602092 = query.getOrDefault("Action")
  valid_602092 = validateParameter(valid_602092, JString, required = true, default = newJString(
      "DescribeInstancesHealth"))
  if valid_602092 != nil:
    section.add "Action", valid_602092
  var valid_602093 = query.getOrDefault("Version")
  valid_602093 = validateParameter(valid_602093, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602093 != nil:
    section.add "Version", valid_602093
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602094 = header.getOrDefault("X-Amz-Date")
  valid_602094 = validateParameter(valid_602094, JString, required = false,
                                 default = nil)
  if valid_602094 != nil:
    section.add "X-Amz-Date", valid_602094
  var valid_602095 = header.getOrDefault("X-Amz-Security-Token")
  valid_602095 = validateParameter(valid_602095, JString, required = false,
                                 default = nil)
  if valid_602095 != nil:
    section.add "X-Amz-Security-Token", valid_602095
  var valid_602096 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602096 = validateParameter(valid_602096, JString, required = false,
                                 default = nil)
  if valid_602096 != nil:
    section.add "X-Amz-Content-Sha256", valid_602096
  var valid_602097 = header.getOrDefault("X-Amz-Algorithm")
  valid_602097 = validateParameter(valid_602097, JString, required = false,
                                 default = nil)
  if valid_602097 != nil:
    section.add "X-Amz-Algorithm", valid_602097
  var valid_602098 = header.getOrDefault("X-Amz-Signature")
  valid_602098 = validateParameter(valid_602098, JString, required = false,
                                 default = nil)
  if valid_602098 != nil:
    section.add "X-Amz-Signature", valid_602098
  var valid_602099 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602099 = validateParameter(valid_602099, JString, required = false,
                                 default = nil)
  if valid_602099 != nil:
    section.add "X-Amz-SignedHeaders", valid_602099
  var valid_602100 = header.getOrDefault("X-Amz-Credential")
  valid_602100 = validateParameter(valid_602100, JString, required = false,
                                 default = nil)
  if valid_602100 != nil:
    section.add "X-Amz-Credential", valid_602100
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
  var valid_602101 = formData.getOrDefault("NextToken")
  valid_602101 = validateParameter(valid_602101, JString, required = false,
                                 default = nil)
  if valid_602101 != nil:
    section.add "NextToken", valid_602101
  var valid_602102 = formData.getOrDefault("EnvironmentId")
  valid_602102 = validateParameter(valid_602102, JString, required = false,
                                 default = nil)
  if valid_602102 != nil:
    section.add "EnvironmentId", valid_602102
  var valid_602103 = formData.getOrDefault("EnvironmentName")
  valid_602103 = validateParameter(valid_602103, JString, required = false,
                                 default = nil)
  if valid_602103 != nil:
    section.add "EnvironmentName", valid_602103
  var valid_602104 = formData.getOrDefault("AttributeNames")
  valid_602104 = validateParameter(valid_602104, JArray, required = false,
                                 default = nil)
  if valid_602104 != nil:
    section.add "AttributeNames", valid_602104
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602105: Call_PostDescribeInstancesHealth_602089; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves detailed information about the health of instances in your AWS Elastic Beanstalk. This operation requires <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/health-enhanced.html">enhanced health reporting</a>.
  ## 
  let valid = call_602105.validator(path, query, header, formData, body)
  let scheme = call_602105.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602105.url(scheme.get, call_602105.host, call_602105.base,
                         call_602105.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602105, url, valid)

proc call*(call_602106: Call_PostDescribeInstancesHealth_602089;
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
  var query_602107 = newJObject()
  var formData_602108 = newJObject()
  add(formData_602108, "NextToken", newJString(NextToken))
  add(formData_602108, "EnvironmentId", newJString(EnvironmentId))
  add(formData_602108, "EnvironmentName", newJString(EnvironmentName))
  add(query_602107, "Action", newJString(Action))
  if AttributeNames != nil:
    formData_602108.add "AttributeNames", AttributeNames
  add(query_602107, "Version", newJString(Version))
  result = call_602106.call(nil, query_602107, nil, formData_602108, nil)

var postDescribeInstancesHealth* = Call_PostDescribeInstancesHealth_602089(
    name: "postDescribeInstancesHealth", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeInstancesHealth",
    validator: validate_PostDescribeInstancesHealth_602090, base: "/",
    url: url_PostDescribeInstancesHealth_602091,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeInstancesHealth_602070 = ref object of OpenApiRestCall_600438
proc url_GetDescribeInstancesHealth_602072(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeInstancesHealth_602071(path: JsonNode; query: JsonNode;
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
  var valid_602073 = query.getOrDefault("AttributeNames")
  valid_602073 = validateParameter(valid_602073, JArray, required = false,
                                 default = nil)
  if valid_602073 != nil:
    section.add "AttributeNames", valid_602073
  var valid_602074 = query.getOrDefault("NextToken")
  valid_602074 = validateParameter(valid_602074, JString, required = false,
                                 default = nil)
  if valid_602074 != nil:
    section.add "NextToken", valid_602074
  var valid_602075 = query.getOrDefault("EnvironmentName")
  valid_602075 = validateParameter(valid_602075, JString, required = false,
                                 default = nil)
  if valid_602075 != nil:
    section.add "EnvironmentName", valid_602075
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602076 = query.getOrDefault("Action")
  valid_602076 = validateParameter(valid_602076, JString, required = true, default = newJString(
      "DescribeInstancesHealth"))
  if valid_602076 != nil:
    section.add "Action", valid_602076
  var valid_602077 = query.getOrDefault("EnvironmentId")
  valid_602077 = validateParameter(valid_602077, JString, required = false,
                                 default = nil)
  if valid_602077 != nil:
    section.add "EnvironmentId", valid_602077
  var valid_602078 = query.getOrDefault("Version")
  valid_602078 = validateParameter(valid_602078, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602078 != nil:
    section.add "Version", valid_602078
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602079 = header.getOrDefault("X-Amz-Date")
  valid_602079 = validateParameter(valid_602079, JString, required = false,
                                 default = nil)
  if valid_602079 != nil:
    section.add "X-Amz-Date", valid_602079
  var valid_602080 = header.getOrDefault("X-Amz-Security-Token")
  valid_602080 = validateParameter(valid_602080, JString, required = false,
                                 default = nil)
  if valid_602080 != nil:
    section.add "X-Amz-Security-Token", valid_602080
  var valid_602081 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602081 = validateParameter(valid_602081, JString, required = false,
                                 default = nil)
  if valid_602081 != nil:
    section.add "X-Amz-Content-Sha256", valid_602081
  var valid_602082 = header.getOrDefault("X-Amz-Algorithm")
  valid_602082 = validateParameter(valid_602082, JString, required = false,
                                 default = nil)
  if valid_602082 != nil:
    section.add "X-Amz-Algorithm", valid_602082
  var valid_602083 = header.getOrDefault("X-Amz-Signature")
  valid_602083 = validateParameter(valid_602083, JString, required = false,
                                 default = nil)
  if valid_602083 != nil:
    section.add "X-Amz-Signature", valid_602083
  var valid_602084 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602084 = validateParameter(valid_602084, JString, required = false,
                                 default = nil)
  if valid_602084 != nil:
    section.add "X-Amz-SignedHeaders", valid_602084
  var valid_602085 = header.getOrDefault("X-Amz-Credential")
  valid_602085 = validateParameter(valid_602085, JString, required = false,
                                 default = nil)
  if valid_602085 != nil:
    section.add "X-Amz-Credential", valid_602085
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602086: Call_GetDescribeInstancesHealth_602070; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves detailed information about the health of instances in your AWS Elastic Beanstalk. This operation requires <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/health-enhanced.html">enhanced health reporting</a>.
  ## 
  let valid = call_602086.validator(path, query, header, formData, body)
  let scheme = call_602086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602086.url(scheme.get, call_602086.host, call_602086.base,
                         call_602086.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602086, url, valid)

proc call*(call_602087: Call_GetDescribeInstancesHealth_602070;
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
  var query_602088 = newJObject()
  if AttributeNames != nil:
    query_602088.add "AttributeNames", AttributeNames
  add(query_602088, "NextToken", newJString(NextToken))
  add(query_602088, "EnvironmentName", newJString(EnvironmentName))
  add(query_602088, "Action", newJString(Action))
  add(query_602088, "EnvironmentId", newJString(EnvironmentId))
  add(query_602088, "Version", newJString(Version))
  result = call_602087.call(nil, query_602088, nil, nil, nil)

var getDescribeInstancesHealth* = Call_GetDescribeInstancesHealth_602070(
    name: "getDescribeInstancesHealth", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeInstancesHealth",
    validator: validate_GetDescribeInstancesHealth_602071, base: "/",
    url: url_GetDescribeInstancesHealth_602072,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribePlatformVersion_602125 = ref object of OpenApiRestCall_600438
proc url_PostDescribePlatformVersion_602127(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribePlatformVersion_602126(path: JsonNode; query: JsonNode;
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
  var valid_602128 = query.getOrDefault("Action")
  valid_602128 = validateParameter(valid_602128, JString, required = true, default = newJString(
      "DescribePlatformVersion"))
  if valid_602128 != nil:
    section.add "Action", valid_602128
  var valid_602129 = query.getOrDefault("Version")
  valid_602129 = validateParameter(valid_602129, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602129 != nil:
    section.add "Version", valid_602129
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602130 = header.getOrDefault("X-Amz-Date")
  valid_602130 = validateParameter(valid_602130, JString, required = false,
                                 default = nil)
  if valid_602130 != nil:
    section.add "X-Amz-Date", valid_602130
  var valid_602131 = header.getOrDefault("X-Amz-Security-Token")
  valid_602131 = validateParameter(valid_602131, JString, required = false,
                                 default = nil)
  if valid_602131 != nil:
    section.add "X-Amz-Security-Token", valid_602131
  var valid_602132 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602132 = validateParameter(valid_602132, JString, required = false,
                                 default = nil)
  if valid_602132 != nil:
    section.add "X-Amz-Content-Sha256", valid_602132
  var valid_602133 = header.getOrDefault("X-Amz-Algorithm")
  valid_602133 = validateParameter(valid_602133, JString, required = false,
                                 default = nil)
  if valid_602133 != nil:
    section.add "X-Amz-Algorithm", valid_602133
  var valid_602134 = header.getOrDefault("X-Amz-Signature")
  valid_602134 = validateParameter(valid_602134, JString, required = false,
                                 default = nil)
  if valid_602134 != nil:
    section.add "X-Amz-Signature", valid_602134
  var valid_602135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602135 = validateParameter(valid_602135, JString, required = false,
                                 default = nil)
  if valid_602135 != nil:
    section.add "X-Amz-SignedHeaders", valid_602135
  var valid_602136 = header.getOrDefault("X-Amz-Credential")
  valid_602136 = validateParameter(valid_602136, JString, required = false,
                                 default = nil)
  if valid_602136 != nil:
    section.add "X-Amz-Credential", valid_602136
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformArn: JString
  ##              : The ARN of the version of the platform.
  section = newJObject()
  var valid_602137 = formData.getOrDefault("PlatformArn")
  valid_602137 = validateParameter(valid_602137, JString, required = false,
                                 default = nil)
  if valid_602137 != nil:
    section.add "PlatformArn", valid_602137
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602138: Call_PostDescribePlatformVersion_602125; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the version of the platform.
  ## 
  let valid = call_602138.validator(path, query, header, formData, body)
  let scheme = call_602138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602138.url(scheme.get, call_602138.host, call_602138.base,
                         call_602138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602138, url, valid)

proc call*(call_602139: Call_PostDescribePlatformVersion_602125;
          Action: string = "DescribePlatformVersion"; PlatformArn: string = "";
          Version: string = "2010-12-01"): Recallable =
  ## postDescribePlatformVersion
  ## Describes the version of the platform.
  ##   Action: string (required)
  ##   PlatformArn: string
  ##              : The ARN of the version of the platform.
  ##   Version: string (required)
  var query_602140 = newJObject()
  var formData_602141 = newJObject()
  add(query_602140, "Action", newJString(Action))
  add(formData_602141, "PlatformArn", newJString(PlatformArn))
  add(query_602140, "Version", newJString(Version))
  result = call_602139.call(nil, query_602140, nil, formData_602141, nil)

var postDescribePlatformVersion* = Call_PostDescribePlatformVersion_602125(
    name: "postDescribePlatformVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribePlatformVersion",
    validator: validate_PostDescribePlatformVersion_602126, base: "/",
    url: url_PostDescribePlatformVersion_602127,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribePlatformVersion_602109 = ref object of OpenApiRestCall_600438
proc url_GetDescribePlatformVersion_602111(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribePlatformVersion_602110(path: JsonNode; query: JsonNode;
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
  var valid_602112 = query.getOrDefault("PlatformArn")
  valid_602112 = validateParameter(valid_602112, JString, required = false,
                                 default = nil)
  if valid_602112 != nil:
    section.add "PlatformArn", valid_602112
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602113 = query.getOrDefault("Action")
  valid_602113 = validateParameter(valid_602113, JString, required = true, default = newJString(
      "DescribePlatformVersion"))
  if valid_602113 != nil:
    section.add "Action", valid_602113
  var valid_602114 = query.getOrDefault("Version")
  valid_602114 = validateParameter(valid_602114, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602114 != nil:
    section.add "Version", valid_602114
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602115 = header.getOrDefault("X-Amz-Date")
  valid_602115 = validateParameter(valid_602115, JString, required = false,
                                 default = nil)
  if valid_602115 != nil:
    section.add "X-Amz-Date", valid_602115
  var valid_602116 = header.getOrDefault("X-Amz-Security-Token")
  valid_602116 = validateParameter(valid_602116, JString, required = false,
                                 default = nil)
  if valid_602116 != nil:
    section.add "X-Amz-Security-Token", valid_602116
  var valid_602117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602117 = validateParameter(valid_602117, JString, required = false,
                                 default = nil)
  if valid_602117 != nil:
    section.add "X-Amz-Content-Sha256", valid_602117
  var valid_602118 = header.getOrDefault("X-Amz-Algorithm")
  valid_602118 = validateParameter(valid_602118, JString, required = false,
                                 default = nil)
  if valid_602118 != nil:
    section.add "X-Amz-Algorithm", valid_602118
  var valid_602119 = header.getOrDefault("X-Amz-Signature")
  valid_602119 = validateParameter(valid_602119, JString, required = false,
                                 default = nil)
  if valid_602119 != nil:
    section.add "X-Amz-Signature", valid_602119
  var valid_602120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602120 = validateParameter(valid_602120, JString, required = false,
                                 default = nil)
  if valid_602120 != nil:
    section.add "X-Amz-SignedHeaders", valid_602120
  var valid_602121 = header.getOrDefault("X-Amz-Credential")
  valid_602121 = validateParameter(valid_602121, JString, required = false,
                                 default = nil)
  if valid_602121 != nil:
    section.add "X-Amz-Credential", valid_602121
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602122: Call_GetDescribePlatformVersion_602109; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the version of the platform.
  ## 
  let valid = call_602122.validator(path, query, header, formData, body)
  let scheme = call_602122.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602122.url(scheme.get, call_602122.host, call_602122.base,
                         call_602122.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602122, url, valid)

proc call*(call_602123: Call_GetDescribePlatformVersion_602109;
          PlatformArn: string = ""; Action: string = "DescribePlatformVersion";
          Version: string = "2010-12-01"): Recallable =
  ## getDescribePlatformVersion
  ## Describes the version of the platform.
  ##   PlatformArn: string
  ##              : The ARN of the version of the platform.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602124 = newJObject()
  add(query_602124, "PlatformArn", newJString(PlatformArn))
  add(query_602124, "Action", newJString(Action))
  add(query_602124, "Version", newJString(Version))
  result = call_602123.call(nil, query_602124, nil, nil, nil)

var getDescribePlatformVersion* = Call_GetDescribePlatformVersion_602109(
    name: "getDescribePlatformVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribePlatformVersion",
    validator: validate_GetDescribePlatformVersion_602110, base: "/",
    url: url_GetDescribePlatformVersion_602111,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListAvailableSolutionStacks_602157 = ref object of OpenApiRestCall_600438
proc url_PostListAvailableSolutionStacks_602159(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListAvailableSolutionStacks_602158(path: JsonNode;
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
  var valid_602160 = query.getOrDefault("Action")
  valid_602160 = validateParameter(valid_602160, JString, required = true, default = newJString(
      "ListAvailableSolutionStacks"))
  if valid_602160 != nil:
    section.add "Action", valid_602160
  var valid_602161 = query.getOrDefault("Version")
  valid_602161 = validateParameter(valid_602161, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602161 != nil:
    section.add "Version", valid_602161
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602162 = header.getOrDefault("X-Amz-Date")
  valid_602162 = validateParameter(valid_602162, JString, required = false,
                                 default = nil)
  if valid_602162 != nil:
    section.add "X-Amz-Date", valid_602162
  var valid_602163 = header.getOrDefault("X-Amz-Security-Token")
  valid_602163 = validateParameter(valid_602163, JString, required = false,
                                 default = nil)
  if valid_602163 != nil:
    section.add "X-Amz-Security-Token", valid_602163
  var valid_602164 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602164 = validateParameter(valid_602164, JString, required = false,
                                 default = nil)
  if valid_602164 != nil:
    section.add "X-Amz-Content-Sha256", valid_602164
  var valid_602165 = header.getOrDefault("X-Amz-Algorithm")
  valid_602165 = validateParameter(valid_602165, JString, required = false,
                                 default = nil)
  if valid_602165 != nil:
    section.add "X-Amz-Algorithm", valid_602165
  var valid_602166 = header.getOrDefault("X-Amz-Signature")
  valid_602166 = validateParameter(valid_602166, JString, required = false,
                                 default = nil)
  if valid_602166 != nil:
    section.add "X-Amz-Signature", valid_602166
  var valid_602167 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602167 = validateParameter(valid_602167, JString, required = false,
                                 default = nil)
  if valid_602167 != nil:
    section.add "X-Amz-SignedHeaders", valid_602167
  var valid_602168 = header.getOrDefault("X-Amz-Credential")
  valid_602168 = validateParameter(valid_602168, JString, required = false,
                                 default = nil)
  if valid_602168 != nil:
    section.add "X-Amz-Credential", valid_602168
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602169: Call_PostListAvailableSolutionStacks_602157;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ## 
  let valid = call_602169.validator(path, query, header, formData, body)
  let scheme = call_602169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602169.url(scheme.get, call_602169.host, call_602169.base,
                         call_602169.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602169, url, valid)

proc call*(call_602170: Call_PostListAvailableSolutionStacks_602157;
          Action: string = "ListAvailableSolutionStacks";
          Version: string = "2010-12-01"): Recallable =
  ## postListAvailableSolutionStacks
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602171 = newJObject()
  add(query_602171, "Action", newJString(Action))
  add(query_602171, "Version", newJString(Version))
  result = call_602170.call(nil, query_602171, nil, nil, nil)

var postListAvailableSolutionStacks* = Call_PostListAvailableSolutionStacks_602157(
    name: "postListAvailableSolutionStacks", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListAvailableSolutionStacks",
    validator: validate_PostListAvailableSolutionStacks_602158, base: "/",
    url: url_PostListAvailableSolutionStacks_602159,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListAvailableSolutionStacks_602142 = ref object of OpenApiRestCall_600438
proc url_GetListAvailableSolutionStacks_602144(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListAvailableSolutionStacks_602143(path: JsonNode;
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
  var valid_602145 = query.getOrDefault("Action")
  valid_602145 = validateParameter(valid_602145, JString, required = true, default = newJString(
      "ListAvailableSolutionStacks"))
  if valid_602145 != nil:
    section.add "Action", valid_602145
  var valid_602146 = query.getOrDefault("Version")
  valid_602146 = validateParameter(valid_602146, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602146 != nil:
    section.add "Version", valid_602146
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602147 = header.getOrDefault("X-Amz-Date")
  valid_602147 = validateParameter(valid_602147, JString, required = false,
                                 default = nil)
  if valid_602147 != nil:
    section.add "X-Amz-Date", valid_602147
  var valid_602148 = header.getOrDefault("X-Amz-Security-Token")
  valid_602148 = validateParameter(valid_602148, JString, required = false,
                                 default = nil)
  if valid_602148 != nil:
    section.add "X-Amz-Security-Token", valid_602148
  var valid_602149 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602149 = validateParameter(valid_602149, JString, required = false,
                                 default = nil)
  if valid_602149 != nil:
    section.add "X-Amz-Content-Sha256", valid_602149
  var valid_602150 = header.getOrDefault("X-Amz-Algorithm")
  valid_602150 = validateParameter(valid_602150, JString, required = false,
                                 default = nil)
  if valid_602150 != nil:
    section.add "X-Amz-Algorithm", valid_602150
  var valid_602151 = header.getOrDefault("X-Amz-Signature")
  valid_602151 = validateParameter(valid_602151, JString, required = false,
                                 default = nil)
  if valid_602151 != nil:
    section.add "X-Amz-Signature", valid_602151
  var valid_602152 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602152 = validateParameter(valid_602152, JString, required = false,
                                 default = nil)
  if valid_602152 != nil:
    section.add "X-Amz-SignedHeaders", valid_602152
  var valid_602153 = header.getOrDefault("X-Amz-Credential")
  valid_602153 = validateParameter(valid_602153, JString, required = false,
                                 default = nil)
  if valid_602153 != nil:
    section.add "X-Amz-Credential", valid_602153
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602154: Call_GetListAvailableSolutionStacks_602142; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ## 
  let valid = call_602154.validator(path, query, header, formData, body)
  let scheme = call_602154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602154.url(scheme.get, call_602154.host, call_602154.base,
                         call_602154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602154, url, valid)

proc call*(call_602155: Call_GetListAvailableSolutionStacks_602142;
          Action: string = "ListAvailableSolutionStacks";
          Version: string = "2010-12-01"): Recallable =
  ## getListAvailableSolutionStacks
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602156 = newJObject()
  add(query_602156, "Action", newJString(Action))
  add(query_602156, "Version", newJString(Version))
  result = call_602155.call(nil, query_602156, nil, nil, nil)

var getListAvailableSolutionStacks* = Call_GetListAvailableSolutionStacks_602142(
    name: "getListAvailableSolutionStacks", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListAvailableSolutionStacks",
    validator: validate_GetListAvailableSolutionStacks_602143, base: "/",
    url: url_GetListAvailableSolutionStacks_602144,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListPlatformVersions_602190 = ref object of OpenApiRestCall_600438
proc url_PostListPlatformVersions_602192(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListPlatformVersions_602191(path: JsonNode; query: JsonNode;
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
  var valid_602193 = query.getOrDefault("Action")
  valid_602193 = validateParameter(valid_602193, JString, required = true,
                                 default = newJString("ListPlatformVersions"))
  if valid_602193 != nil:
    section.add "Action", valid_602193
  var valid_602194 = query.getOrDefault("Version")
  valid_602194 = validateParameter(valid_602194, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602194 != nil:
    section.add "Version", valid_602194
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602195 = header.getOrDefault("X-Amz-Date")
  valid_602195 = validateParameter(valid_602195, JString, required = false,
                                 default = nil)
  if valid_602195 != nil:
    section.add "X-Amz-Date", valid_602195
  var valid_602196 = header.getOrDefault("X-Amz-Security-Token")
  valid_602196 = validateParameter(valid_602196, JString, required = false,
                                 default = nil)
  if valid_602196 != nil:
    section.add "X-Amz-Security-Token", valid_602196
  var valid_602197 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602197 = validateParameter(valid_602197, JString, required = false,
                                 default = nil)
  if valid_602197 != nil:
    section.add "X-Amz-Content-Sha256", valid_602197
  var valid_602198 = header.getOrDefault("X-Amz-Algorithm")
  valid_602198 = validateParameter(valid_602198, JString, required = false,
                                 default = nil)
  if valid_602198 != nil:
    section.add "X-Amz-Algorithm", valid_602198
  var valid_602199 = header.getOrDefault("X-Amz-Signature")
  valid_602199 = validateParameter(valid_602199, JString, required = false,
                                 default = nil)
  if valid_602199 != nil:
    section.add "X-Amz-Signature", valid_602199
  var valid_602200 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602200 = validateParameter(valid_602200, JString, required = false,
                                 default = nil)
  if valid_602200 != nil:
    section.add "X-Amz-SignedHeaders", valid_602200
  var valid_602201 = header.getOrDefault("X-Amz-Credential")
  valid_602201 = validateParameter(valid_602201, JString, required = false,
                                 default = nil)
  if valid_602201 != nil:
    section.add "X-Amz-Credential", valid_602201
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : The starting index into the remaining list of platforms. Use the <code>NextToken</code> value from a previous <code>ListPlatformVersion</code> call.
  ##   Filters: JArray
  ##          : List only the platforms where the platform member value relates to one of the supplied values.
  ##   MaxRecords: JInt
  ##             : The maximum number of platform values returned in one call.
  section = newJObject()
  var valid_602202 = formData.getOrDefault("NextToken")
  valid_602202 = validateParameter(valid_602202, JString, required = false,
                                 default = nil)
  if valid_602202 != nil:
    section.add "NextToken", valid_602202
  var valid_602203 = formData.getOrDefault("Filters")
  valid_602203 = validateParameter(valid_602203, JArray, required = false,
                                 default = nil)
  if valid_602203 != nil:
    section.add "Filters", valid_602203
  var valid_602204 = formData.getOrDefault("MaxRecords")
  valid_602204 = validateParameter(valid_602204, JInt, required = false, default = nil)
  if valid_602204 != nil:
    section.add "MaxRecords", valid_602204
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602205: Call_PostListPlatformVersions_602190; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the available platforms.
  ## 
  let valid = call_602205.validator(path, query, header, formData, body)
  let scheme = call_602205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602205.url(scheme.get, call_602205.host, call_602205.base,
                         call_602205.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602205, url, valid)

proc call*(call_602206: Call_PostListPlatformVersions_602190;
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
  var query_602207 = newJObject()
  var formData_602208 = newJObject()
  add(formData_602208, "NextToken", newJString(NextToken))
  add(query_602207, "Action", newJString(Action))
  if Filters != nil:
    formData_602208.add "Filters", Filters
  add(formData_602208, "MaxRecords", newJInt(MaxRecords))
  add(query_602207, "Version", newJString(Version))
  result = call_602206.call(nil, query_602207, nil, formData_602208, nil)

var postListPlatformVersions* = Call_PostListPlatformVersions_602190(
    name: "postListPlatformVersions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListPlatformVersions",
    validator: validate_PostListPlatformVersions_602191, base: "/",
    url: url_PostListPlatformVersions_602192, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListPlatformVersions_602172 = ref object of OpenApiRestCall_600438
proc url_GetListPlatformVersions_602174(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListPlatformVersions_602173(path: JsonNode; query: JsonNode;
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
  var valid_602175 = query.getOrDefault("MaxRecords")
  valid_602175 = validateParameter(valid_602175, JInt, required = false, default = nil)
  if valid_602175 != nil:
    section.add "MaxRecords", valid_602175
  var valid_602176 = query.getOrDefault("Filters")
  valid_602176 = validateParameter(valid_602176, JArray, required = false,
                                 default = nil)
  if valid_602176 != nil:
    section.add "Filters", valid_602176
  var valid_602177 = query.getOrDefault("NextToken")
  valid_602177 = validateParameter(valid_602177, JString, required = false,
                                 default = nil)
  if valid_602177 != nil:
    section.add "NextToken", valid_602177
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602178 = query.getOrDefault("Action")
  valid_602178 = validateParameter(valid_602178, JString, required = true,
                                 default = newJString("ListPlatformVersions"))
  if valid_602178 != nil:
    section.add "Action", valid_602178
  var valid_602179 = query.getOrDefault("Version")
  valid_602179 = validateParameter(valid_602179, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602179 != nil:
    section.add "Version", valid_602179
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602180 = header.getOrDefault("X-Amz-Date")
  valid_602180 = validateParameter(valid_602180, JString, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "X-Amz-Date", valid_602180
  var valid_602181 = header.getOrDefault("X-Amz-Security-Token")
  valid_602181 = validateParameter(valid_602181, JString, required = false,
                                 default = nil)
  if valid_602181 != nil:
    section.add "X-Amz-Security-Token", valid_602181
  var valid_602182 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602182 = validateParameter(valid_602182, JString, required = false,
                                 default = nil)
  if valid_602182 != nil:
    section.add "X-Amz-Content-Sha256", valid_602182
  var valid_602183 = header.getOrDefault("X-Amz-Algorithm")
  valid_602183 = validateParameter(valid_602183, JString, required = false,
                                 default = nil)
  if valid_602183 != nil:
    section.add "X-Amz-Algorithm", valid_602183
  var valid_602184 = header.getOrDefault("X-Amz-Signature")
  valid_602184 = validateParameter(valid_602184, JString, required = false,
                                 default = nil)
  if valid_602184 != nil:
    section.add "X-Amz-Signature", valid_602184
  var valid_602185 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602185 = validateParameter(valid_602185, JString, required = false,
                                 default = nil)
  if valid_602185 != nil:
    section.add "X-Amz-SignedHeaders", valid_602185
  var valid_602186 = header.getOrDefault("X-Amz-Credential")
  valid_602186 = validateParameter(valid_602186, JString, required = false,
                                 default = nil)
  if valid_602186 != nil:
    section.add "X-Amz-Credential", valid_602186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602187: Call_GetListPlatformVersions_602172; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the available platforms.
  ## 
  let valid = call_602187.validator(path, query, header, formData, body)
  let scheme = call_602187.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602187.url(scheme.get, call_602187.host, call_602187.base,
                         call_602187.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602187, url, valid)

proc call*(call_602188: Call_GetListPlatformVersions_602172; MaxRecords: int = 0;
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
  var query_602189 = newJObject()
  add(query_602189, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_602189.add "Filters", Filters
  add(query_602189, "NextToken", newJString(NextToken))
  add(query_602189, "Action", newJString(Action))
  add(query_602189, "Version", newJString(Version))
  result = call_602188.call(nil, query_602189, nil, nil, nil)

var getListPlatformVersions* = Call_GetListPlatformVersions_602172(
    name: "getListPlatformVersions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListPlatformVersions",
    validator: validate_GetListPlatformVersions_602173, base: "/",
    url: url_GetListPlatformVersions_602174, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_602225 = ref object of OpenApiRestCall_600438
proc url_PostListTagsForResource_602227(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListTagsForResource_602226(path: JsonNode; query: JsonNode;
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
  var valid_602228 = query.getOrDefault("Action")
  valid_602228 = validateParameter(valid_602228, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_602228 != nil:
    section.add "Action", valid_602228
  var valid_602229 = query.getOrDefault("Version")
  valid_602229 = validateParameter(valid_602229, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602229 != nil:
    section.add "Version", valid_602229
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602230 = header.getOrDefault("X-Amz-Date")
  valid_602230 = validateParameter(valid_602230, JString, required = false,
                                 default = nil)
  if valid_602230 != nil:
    section.add "X-Amz-Date", valid_602230
  var valid_602231 = header.getOrDefault("X-Amz-Security-Token")
  valid_602231 = validateParameter(valid_602231, JString, required = false,
                                 default = nil)
  if valid_602231 != nil:
    section.add "X-Amz-Security-Token", valid_602231
  var valid_602232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602232 = validateParameter(valid_602232, JString, required = false,
                                 default = nil)
  if valid_602232 != nil:
    section.add "X-Amz-Content-Sha256", valid_602232
  var valid_602233 = header.getOrDefault("X-Amz-Algorithm")
  valid_602233 = validateParameter(valid_602233, JString, required = false,
                                 default = nil)
  if valid_602233 != nil:
    section.add "X-Amz-Algorithm", valid_602233
  var valid_602234 = header.getOrDefault("X-Amz-Signature")
  valid_602234 = validateParameter(valid_602234, JString, required = false,
                                 default = nil)
  if valid_602234 != nil:
    section.add "X-Amz-Signature", valid_602234
  var valid_602235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602235 = validateParameter(valid_602235, JString, required = false,
                                 default = nil)
  if valid_602235 != nil:
    section.add "X-Amz-SignedHeaders", valid_602235
  var valid_602236 = header.getOrDefault("X-Amz-Credential")
  valid_602236 = validateParameter(valid_602236, JString, required = false,
                                 default = nil)
  if valid_602236 != nil:
    section.add "X-Amz-Credential", valid_602236
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArn: JString (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce for which a tag list is requested.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArn` field"
  var valid_602237 = formData.getOrDefault("ResourceArn")
  valid_602237 = validateParameter(valid_602237, JString, required = true,
                                 default = nil)
  if valid_602237 != nil:
    section.add "ResourceArn", valid_602237
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602238: Call_PostListTagsForResource_602225; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ## 
  let valid = call_602238.validator(path, query, header, formData, body)
  let scheme = call_602238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602238.url(scheme.get, call_602238.host, call_602238.base,
                         call_602238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602238, url, valid)

proc call*(call_602239: Call_PostListTagsForResource_602225; ResourceArn: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-12-01"): Recallable =
  ## postListTagsForResource
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ##   Action: string (required)
  ##   ResourceArn: string (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce for which a tag list is requested.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  ##   Version: string (required)
  var query_602240 = newJObject()
  var formData_602241 = newJObject()
  add(query_602240, "Action", newJString(Action))
  add(formData_602241, "ResourceArn", newJString(ResourceArn))
  add(query_602240, "Version", newJString(Version))
  result = call_602239.call(nil, query_602240, nil, formData_602241, nil)

var postListTagsForResource* = Call_PostListTagsForResource_602225(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_602226, base: "/",
    url: url_PostListTagsForResource_602227, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_602209 = ref object of OpenApiRestCall_600438
proc url_GetListTagsForResource_602211(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListTagsForResource_602210(path: JsonNode; query: JsonNode;
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
  var valid_602212 = query.getOrDefault("ResourceArn")
  valid_602212 = validateParameter(valid_602212, JString, required = true,
                                 default = nil)
  if valid_602212 != nil:
    section.add "ResourceArn", valid_602212
  var valid_602213 = query.getOrDefault("Action")
  valid_602213 = validateParameter(valid_602213, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_602213 != nil:
    section.add "Action", valid_602213
  var valid_602214 = query.getOrDefault("Version")
  valid_602214 = validateParameter(valid_602214, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602214 != nil:
    section.add "Version", valid_602214
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602215 = header.getOrDefault("X-Amz-Date")
  valid_602215 = validateParameter(valid_602215, JString, required = false,
                                 default = nil)
  if valid_602215 != nil:
    section.add "X-Amz-Date", valid_602215
  var valid_602216 = header.getOrDefault("X-Amz-Security-Token")
  valid_602216 = validateParameter(valid_602216, JString, required = false,
                                 default = nil)
  if valid_602216 != nil:
    section.add "X-Amz-Security-Token", valid_602216
  var valid_602217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602217 = validateParameter(valid_602217, JString, required = false,
                                 default = nil)
  if valid_602217 != nil:
    section.add "X-Amz-Content-Sha256", valid_602217
  var valid_602218 = header.getOrDefault("X-Amz-Algorithm")
  valid_602218 = validateParameter(valid_602218, JString, required = false,
                                 default = nil)
  if valid_602218 != nil:
    section.add "X-Amz-Algorithm", valid_602218
  var valid_602219 = header.getOrDefault("X-Amz-Signature")
  valid_602219 = validateParameter(valid_602219, JString, required = false,
                                 default = nil)
  if valid_602219 != nil:
    section.add "X-Amz-Signature", valid_602219
  var valid_602220 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602220 = validateParameter(valid_602220, JString, required = false,
                                 default = nil)
  if valid_602220 != nil:
    section.add "X-Amz-SignedHeaders", valid_602220
  var valid_602221 = header.getOrDefault("X-Amz-Credential")
  valid_602221 = validateParameter(valid_602221, JString, required = false,
                                 default = nil)
  if valid_602221 != nil:
    section.add "X-Amz-Credential", valid_602221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602222: Call_GetListTagsForResource_602209; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ## 
  let valid = call_602222.validator(path, query, header, formData, body)
  let scheme = call_602222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602222.url(scheme.get, call_602222.host, call_602222.base,
                         call_602222.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602222, url, valid)

proc call*(call_602223: Call_GetListTagsForResource_602209; ResourceArn: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-12-01"): Recallable =
  ## getListTagsForResource
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ##   ResourceArn: string (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce for which a tag list is requested.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602224 = newJObject()
  add(query_602224, "ResourceArn", newJString(ResourceArn))
  add(query_602224, "Action", newJString(Action))
  add(query_602224, "Version", newJString(Version))
  result = call_602223.call(nil, query_602224, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_602209(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_602210, base: "/",
    url: url_GetListTagsForResource_602211, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebuildEnvironment_602259 = ref object of OpenApiRestCall_600438
proc url_PostRebuildEnvironment_602261(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRebuildEnvironment_602260(path: JsonNode; query: JsonNode;
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
  var valid_602262 = query.getOrDefault("Action")
  valid_602262 = validateParameter(valid_602262, JString, required = true,
                                 default = newJString("RebuildEnvironment"))
  if valid_602262 != nil:
    section.add "Action", valid_602262
  var valid_602263 = query.getOrDefault("Version")
  valid_602263 = validateParameter(valid_602263, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602263 != nil:
    section.add "Version", valid_602263
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602264 = header.getOrDefault("X-Amz-Date")
  valid_602264 = validateParameter(valid_602264, JString, required = false,
                                 default = nil)
  if valid_602264 != nil:
    section.add "X-Amz-Date", valid_602264
  var valid_602265 = header.getOrDefault("X-Amz-Security-Token")
  valid_602265 = validateParameter(valid_602265, JString, required = false,
                                 default = nil)
  if valid_602265 != nil:
    section.add "X-Amz-Security-Token", valid_602265
  var valid_602266 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602266 = validateParameter(valid_602266, JString, required = false,
                                 default = nil)
  if valid_602266 != nil:
    section.add "X-Amz-Content-Sha256", valid_602266
  var valid_602267 = header.getOrDefault("X-Amz-Algorithm")
  valid_602267 = validateParameter(valid_602267, JString, required = false,
                                 default = nil)
  if valid_602267 != nil:
    section.add "X-Amz-Algorithm", valid_602267
  var valid_602268 = header.getOrDefault("X-Amz-Signature")
  valid_602268 = validateParameter(valid_602268, JString, required = false,
                                 default = nil)
  if valid_602268 != nil:
    section.add "X-Amz-Signature", valid_602268
  var valid_602269 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602269 = validateParameter(valid_602269, JString, required = false,
                                 default = nil)
  if valid_602269 != nil:
    section.add "X-Amz-SignedHeaders", valid_602269
  var valid_602270 = header.getOrDefault("X-Amz-Credential")
  valid_602270 = validateParameter(valid_602270, JString, required = false,
                                 default = nil)
  if valid_602270 != nil:
    section.add "X-Amz-Credential", valid_602270
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to rebuild.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to rebuild.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_602271 = formData.getOrDefault("EnvironmentId")
  valid_602271 = validateParameter(valid_602271, JString, required = false,
                                 default = nil)
  if valid_602271 != nil:
    section.add "EnvironmentId", valid_602271
  var valid_602272 = formData.getOrDefault("EnvironmentName")
  valid_602272 = validateParameter(valid_602272, JString, required = false,
                                 default = nil)
  if valid_602272 != nil:
    section.add "EnvironmentName", valid_602272
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602273: Call_PostRebuildEnvironment_602259; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes and recreates all of the AWS resources (for example: the Auto Scaling group, load balancer, etc.) for a specified environment and forces a restart.
  ## 
  let valid = call_602273.validator(path, query, header, formData, body)
  let scheme = call_602273.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602273.url(scheme.get, call_602273.host, call_602273.base,
                         call_602273.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602273, url, valid)

proc call*(call_602274: Call_PostRebuildEnvironment_602259;
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
  var query_602275 = newJObject()
  var formData_602276 = newJObject()
  add(formData_602276, "EnvironmentId", newJString(EnvironmentId))
  add(formData_602276, "EnvironmentName", newJString(EnvironmentName))
  add(query_602275, "Action", newJString(Action))
  add(query_602275, "Version", newJString(Version))
  result = call_602274.call(nil, query_602275, nil, formData_602276, nil)

var postRebuildEnvironment* = Call_PostRebuildEnvironment_602259(
    name: "postRebuildEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RebuildEnvironment",
    validator: validate_PostRebuildEnvironment_602260, base: "/",
    url: url_PostRebuildEnvironment_602261, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebuildEnvironment_602242 = ref object of OpenApiRestCall_600438
proc url_GetRebuildEnvironment_602244(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRebuildEnvironment_602243(path: JsonNode; query: JsonNode;
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
  var valid_602245 = query.getOrDefault("EnvironmentName")
  valid_602245 = validateParameter(valid_602245, JString, required = false,
                                 default = nil)
  if valid_602245 != nil:
    section.add "EnvironmentName", valid_602245
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602246 = query.getOrDefault("Action")
  valid_602246 = validateParameter(valid_602246, JString, required = true,
                                 default = newJString("RebuildEnvironment"))
  if valid_602246 != nil:
    section.add "Action", valid_602246
  var valid_602247 = query.getOrDefault("EnvironmentId")
  valid_602247 = validateParameter(valid_602247, JString, required = false,
                                 default = nil)
  if valid_602247 != nil:
    section.add "EnvironmentId", valid_602247
  var valid_602248 = query.getOrDefault("Version")
  valid_602248 = validateParameter(valid_602248, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602248 != nil:
    section.add "Version", valid_602248
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602249 = header.getOrDefault("X-Amz-Date")
  valid_602249 = validateParameter(valid_602249, JString, required = false,
                                 default = nil)
  if valid_602249 != nil:
    section.add "X-Amz-Date", valid_602249
  var valid_602250 = header.getOrDefault("X-Amz-Security-Token")
  valid_602250 = validateParameter(valid_602250, JString, required = false,
                                 default = nil)
  if valid_602250 != nil:
    section.add "X-Amz-Security-Token", valid_602250
  var valid_602251 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602251 = validateParameter(valid_602251, JString, required = false,
                                 default = nil)
  if valid_602251 != nil:
    section.add "X-Amz-Content-Sha256", valid_602251
  var valid_602252 = header.getOrDefault("X-Amz-Algorithm")
  valid_602252 = validateParameter(valid_602252, JString, required = false,
                                 default = nil)
  if valid_602252 != nil:
    section.add "X-Amz-Algorithm", valid_602252
  var valid_602253 = header.getOrDefault("X-Amz-Signature")
  valid_602253 = validateParameter(valid_602253, JString, required = false,
                                 default = nil)
  if valid_602253 != nil:
    section.add "X-Amz-Signature", valid_602253
  var valid_602254 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602254 = validateParameter(valid_602254, JString, required = false,
                                 default = nil)
  if valid_602254 != nil:
    section.add "X-Amz-SignedHeaders", valid_602254
  var valid_602255 = header.getOrDefault("X-Amz-Credential")
  valid_602255 = validateParameter(valid_602255, JString, required = false,
                                 default = nil)
  if valid_602255 != nil:
    section.add "X-Amz-Credential", valid_602255
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602256: Call_GetRebuildEnvironment_602242; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes and recreates all of the AWS resources (for example: the Auto Scaling group, load balancer, etc.) for a specified environment and forces a restart.
  ## 
  let valid = call_602256.validator(path, query, header, formData, body)
  let scheme = call_602256.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602256.url(scheme.get, call_602256.host, call_602256.base,
                         call_602256.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602256, url, valid)

proc call*(call_602257: Call_GetRebuildEnvironment_602242;
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
  var query_602258 = newJObject()
  add(query_602258, "EnvironmentName", newJString(EnvironmentName))
  add(query_602258, "Action", newJString(Action))
  add(query_602258, "EnvironmentId", newJString(EnvironmentId))
  add(query_602258, "Version", newJString(Version))
  result = call_602257.call(nil, query_602258, nil, nil, nil)

var getRebuildEnvironment* = Call_GetRebuildEnvironment_602242(
    name: "getRebuildEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RebuildEnvironment",
    validator: validate_GetRebuildEnvironment_602243, base: "/",
    url: url_GetRebuildEnvironment_602244, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRequestEnvironmentInfo_602295 = ref object of OpenApiRestCall_600438
proc url_PostRequestEnvironmentInfo_602297(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRequestEnvironmentInfo_602296(path: JsonNode; query: JsonNode;
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
  var valid_602298 = query.getOrDefault("Action")
  valid_602298 = validateParameter(valid_602298, JString, required = true,
                                 default = newJString("RequestEnvironmentInfo"))
  if valid_602298 != nil:
    section.add "Action", valid_602298
  var valid_602299 = query.getOrDefault("Version")
  valid_602299 = validateParameter(valid_602299, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602299 != nil:
    section.add "Version", valid_602299
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602300 = header.getOrDefault("X-Amz-Date")
  valid_602300 = validateParameter(valid_602300, JString, required = false,
                                 default = nil)
  if valid_602300 != nil:
    section.add "X-Amz-Date", valid_602300
  var valid_602301 = header.getOrDefault("X-Amz-Security-Token")
  valid_602301 = validateParameter(valid_602301, JString, required = false,
                                 default = nil)
  if valid_602301 != nil:
    section.add "X-Amz-Security-Token", valid_602301
  var valid_602302 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602302 = validateParameter(valid_602302, JString, required = false,
                                 default = nil)
  if valid_602302 != nil:
    section.add "X-Amz-Content-Sha256", valid_602302
  var valid_602303 = header.getOrDefault("X-Amz-Algorithm")
  valid_602303 = validateParameter(valid_602303, JString, required = false,
                                 default = nil)
  if valid_602303 != nil:
    section.add "X-Amz-Algorithm", valid_602303
  var valid_602304 = header.getOrDefault("X-Amz-Signature")
  valid_602304 = validateParameter(valid_602304, JString, required = false,
                                 default = nil)
  if valid_602304 != nil:
    section.add "X-Amz-Signature", valid_602304
  var valid_602305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602305 = validateParameter(valid_602305, JString, required = false,
                                 default = nil)
  if valid_602305 != nil:
    section.add "X-Amz-SignedHeaders", valid_602305
  var valid_602306 = header.getOrDefault("X-Amz-Credential")
  valid_602306 = validateParameter(valid_602306, JString, required = false,
                                 default = nil)
  if valid_602306 != nil:
    section.add "X-Amz-Credential", valid_602306
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
  var valid_602307 = formData.getOrDefault("InfoType")
  valid_602307 = validateParameter(valid_602307, JString, required = true,
                                 default = newJString("tail"))
  if valid_602307 != nil:
    section.add "InfoType", valid_602307
  var valid_602308 = formData.getOrDefault("EnvironmentId")
  valid_602308 = validateParameter(valid_602308, JString, required = false,
                                 default = nil)
  if valid_602308 != nil:
    section.add "EnvironmentId", valid_602308
  var valid_602309 = formData.getOrDefault("EnvironmentName")
  valid_602309 = validateParameter(valid_602309, JString, required = false,
                                 default = nil)
  if valid_602309 != nil:
    section.add "EnvironmentName", valid_602309
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602310: Call_PostRequestEnvironmentInfo_602295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a request to compile the specified type of information of the deployed environment.</p> <p> Setting the <code>InfoType</code> to <code>tail</code> compiles the last lines from the application server log files of every Amazon EC2 instance in your environment. </p> <p> Setting the <code>InfoType</code> to <code>bundle</code> compresses the application server log files for every Amazon EC2 instance into a <code>.zip</code> file. Legacy and .NET containers do not support bundle logs. </p> <p> Use <a>RetrieveEnvironmentInfo</a> to obtain the set of logs. </p> <p>Related Topics</p> <ul> <li> <p> <a>RetrieveEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_602310.validator(path, query, header, formData, body)
  let scheme = call_602310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602310.url(scheme.get, call_602310.host, call_602310.base,
                         call_602310.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602310, url, valid)

proc call*(call_602311: Call_PostRequestEnvironmentInfo_602295;
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
  var query_602312 = newJObject()
  var formData_602313 = newJObject()
  add(formData_602313, "InfoType", newJString(InfoType))
  add(formData_602313, "EnvironmentId", newJString(EnvironmentId))
  add(formData_602313, "EnvironmentName", newJString(EnvironmentName))
  add(query_602312, "Action", newJString(Action))
  add(query_602312, "Version", newJString(Version))
  result = call_602311.call(nil, query_602312, nil, formData_602313, nil)

var postRequestEnvironmentInfo* = Call_PostRequestEnvironmentInfo_602295(
    name: "postRequestEnvironmentInfo", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RequestEnvironmentInfo",
    validator: validate_PostRequestEnvironmentInfo_602296, base: "/",
    url: url_PostRequestEnvironmentInfo_602297,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRequestEnvironmentInfo_602277 = ref object of OpenApiRestCall_600438
proc url_GetRequestEnvironmentInfo_602279(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRequestEnvironmentInfo_602278(path: JsonNode; query: JsonNode;
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
  var valid_602280 = query.getOrDefault("InfoType")
  valid_602280 = validateParameter(valid_602280, JString, required = true,
                                 default = newJString("tail"))
  if valid_602280 != nil:
    section.add "InfoType", valid_602280
  var valid_602281 = query.getOrDefault("EnvironmentName")
  valid_602281 = validateParameter(valid_602281, JString, required = false,
                                 default = nil)
  if valid_602281 != nil:
    section.add "EnvironmentName", valid_602281
  var valid_602282 = query.getOrDefault("Action")
  valid_602282 = validateParameter(valid_602282, JString, required = true,
                                 default = newJString("RequestEnvironmentInfo"))
  if valid_602282 != nil:
    section.add "Action", valid_602282
  var valid_602283 = query.getOrDefault("EnvironmentId")
  valid_602283 = validateParameter(valid_602283, JString, required = false,
                                 default = nil)
  if valid_602283 != nil:
    section.add "EnvironmentId", valid_602283
  var valid_602284 = query.getOrDefault("Version")
  valid_602284 = validateParameter(valid_602284, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602284 != nil:
    section.add "Version", valid_602284
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602285 = header.getOrDefault("X-Amz-Date")
  valid_602285 = validateParameter(valid_602285, JString, required = false,
                                 default = nil)
  if valid_602285 != nil:
    section.add "X-Amz-Date", valid_602285
  var valid_602286 = header.getOrDefault("X-Amz-Security-Token")
  valid_602286 = validateParameter(valid_602286, JString, required = false,
                                 default = nil)
  if valid_602286 != nil:
    section.add "X-Amz-Security-Token", valid_602286
  var valid_602287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602287 = validateParameter(valid_602287, JString, required = false,
                                 default = nil)
  if valid_602287 != nil:
    section.add "X-Amz-Content-Sha256", valid_602287
  var valid_602288 = header.getOrDefault("X-Amz-Algorithm")
  valid_602288 = validateParameter(valid_602288, JString, required = false,
                                 default = nil)
  if valid_602288 != nil:
    section.add "X-Amz-Algorithm", valid_602288
  var valid_602289 = header.getOrDefault("X-Amz-Signature")
  valid_602289 = validateParameter(valid_602289, JString, required = false,
                                 default = nil)
  if valid_602289 != nil:
    section.add "X-Amz-Signature", valid_602289
  var valid_602290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602290 = validateParameter(valid_602290, JString, required = false,
                                 default = nil)
  if valid_602290 != nil:
    section.add "X-Amz-SignedHeaders", valid_602290
  var valid_602291 = header.getOrDefault("X-Amz-Credential")
  valid_602291 = validateParameter(valid_602291, JString, required = false,
                                 default = nil)
  if valid_602291 != nil:
    section.add "X-Amz-Credential", valid_602291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602292: Call_GetRequestEnvironmentInfo_602277; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a request to compile the specified type of information of the deployed environment.</p> <p> Setting the <code>InfoType</code> to <code>tail</code> compiles the last lines from the application server log files of every Amazon EC2 instance in your environment. </p> <p> Setting the <code>InfoType</code> to <code>bundle</code> compresses the application server log files for every Amazon EC2 instance into a <code>.zip</code> file. Legacy and .NET containers do not support bundle logs. </p> <p> Use <a>RetrieveEnvironmentInfo</a> to obtain the set of logs. </p> <p>Related Topics</p> <ul> <li> <p> <a>RetrieveEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_602292.validator(path, query, header, formData, body)
  let scheme = call_602292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602292.url(scheme.get, call_602292.host, call_602292.base,
                         call_602292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602292, url, valid)

proc call*(call_602293: Call_GetRequestEnvironmentInfo_602277;
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
  var query_602294 = newJObject()
  add(query_602294, "InfoType", newJString(InfoType))
  add(query_602294, "EnvironmentName", newJString(EnvironmentName))
  add(query_602294, "Action", newJString(Action))
  add(query_602294, "EnvironmentId", newJString(EnvironmentId))
  add(query_602294, "Version", newJString(Version))
  result = call_602293.call(nil, query_602294, nil, nil, nil)

var getRequestEnvironmentInfo* = Call_GetRequestEnvironmentInfo_602277(
    name: "getRequestEnvironmentInfo", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RequestEnvironmentInfo",
    validator: validate_GetRequestEnvironmentInfo_602278, base: "/",
    url: url_GetRequestEnvironmentInfo_602279,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestartAppServer_602331 = ref object of OpenApiRestCall_600438
proc url_PostRestartAppServer_602333(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRestartAppServer_602332(path: JsonNode; query: JsonNode;
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
  var valid_602334 = query.getOrDefault("Action")
  valid_602334 = validateParameter(valid_602334, JString, required = true,
                                 default = newJString("RestartAppServer"))
  if valid_602334 != nil:
    section.add "Action", valid_602334
  var valid_602335 = query.getOrDefault("Version")
  valid_602335 = validateParameter(valid_602335, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602335 != nil:
    section.add "Version", valid_602335
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602336 = header.getOrDefault("X-Amz-Date")
  valid_602336 = validateParameter(valid_602336, JString, required = false,
                                 default = nil)
  if valid_602336 != nil:
    section.add "X-Amz-Date", valid_602336
  var valid_602337 = header.getOrDefault("X-Amz-Security-Token")
  valid_602337 = validateParameter(valid_602337, JString, required = false,
                                 default = nil)
  if valid_602337 != nil:
    section.add "X-Amz-Security-Token", valid_602337
  var valid_602338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602338 = validateParameter(valid_602338, JString, required = false,
                                 default = nil)
  if valid_602338 != nil:
    section.add "X-Amz-Content-Sha256", valid_602338
  var valid_602339 = header.getOrDefault("X-Amz-Algorithm")
  valid_602339 = validateParameter(valid_602339, JString, required = false,
                                 default = nil)
  if valid_602339 != nil:
    section.add "X-Amz-Algorithm", valid_602339
  var valid_602340 = header.getOrDefault("X-Amz-Signature")
  valid_602340 = validateParameter(valid_602340, JString, required = false,
                                 default = nil)
  if valid_602340 != nil:
    section.add "X-Amz-Signature", valid_602340
  var valid_602341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602341 = validateParameter(valid_602341, JString, required = false,
                                 default = nil)
  if valid_602341 != nil:
    section.add "X-Amz-SignedHeaders", valid_602341
  var valid_602342 = header.getOrDefault("X-Amz-Credential")
  valid_602342 = validateParameter(valid_602342, JString, required = false,
                                 default = nil)
  if valid_602342 != nil:
    section.add "X-Amz-Credential", valid_602342
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to restart the server for.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to restart the server for.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_602343 = formData.getOrDefault("EnvironmentId")
  valid_602343 = validateParameter(valid_602343, JString, required = false,
                                 default = nil)
  if valid_602343 != nil:
    section.add "EnvironmentId", valid_602343
  var valid_602344 = formData.getOrDefault("EnvironmentName")
  valid_602344 = validateParameter(valid_602344, JString, required = false,
                                 default = nil)
  if valid_602344 != nil:
    section.add "EnvironmentName", valid_602344
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602345: Call_PostRestartAppServer_602331; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Causes the environment to restart the application container server running on each Amazon EC2 instance.
  ## 
  let valid = call_602345.validator(path, query, header, formData, body)
  let scheme = call_602345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602345.url(scheme.get, call_602345.host, call_602345.base,
                         call_602345.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602345, url, valid)

proc call*(call_602346: Call_PostRestartAppServer_602331;
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
  var query_602347 = newJObject()
  var formData_602348 = newJObject()
  add(formData_602348, "EnvironmentId", newJString(EnvironmentId))
  add(formData_602348, "EnvironmentName", newJString(EnvironmentName))
  add(query_602347, "Action", newJString(Action))
  add(query_602347, "Version", newJString(Version))
  result = call_602346.call(nil, query_602347, nil, formData_602348, nil)

var postRestartAppServer* = Call_PostRestartAppServer_602331(
    name: "postRestartAppServer", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RestartAppServer",
    validator: validate_PostRestartAppServer_602332, base: "/",
    url: url_PostRestartAppServer_602333, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestartAppServer_602314 = ref object of OpenApiRestCall_600438
proc url_GetRestartAppServer_602316(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRestartAppServer_602315(path: JsonNode; query: JsonNode;
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
  var valid_602317 = query.getOrDefault("EnvironmentName")
  valid_602317 = validateParameter(valid_602317, JString, required = false,
                                 default = nil)
  if valid_602317 != nil:
    section.add "EnvironmentName", valid_602317
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602318 = query.getOrDefault("Action")
  valid_602318 = validateParameter(valid_602318, JString, required = true,
                                 default = newJString("RestartAppServer"))
  if valid_602318 != nil:
    section.add "Action", valid_602318
  var valid_602319 = query.getOrDefault("EnvironmentId")
  valid_602319 = validateParameter(valid_602319, JString, required = false,
                                 default = nil)
  if valid_602319 != nil:
    section.add "EnvironmentId", valid_602319
  var valid_602320 = query.getOrDefault("Version")
  valid_602320 = validateParameter(valid_602320, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602320 != nil:
    section.add "Version", valid_602320
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602321 = header.getOrDefault("X-Amz-Date")
  valid_602321 = validateParameter(valid_602321, JString, required = false,
                                 default = nil)
  if valid_602321 != nil:
    section.add "X-Amz-Date", valid_602321
  var valid_602322 = header.getOrDefault("X-Amz-Security-Token")
  valid_602322 = validateParameter(valid_602322, JString, required = false,
                                 default = nil)
  if valid_602322 != nil:
    section.add "X-Amz-Security-Token", valid_602322
  var valid_602323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602323 = validateParameter(valid_602323, JString, required = false,
                                 default = nil)
  if valid_602323 != nil:
    section.add "X-Amz-Content-Sha256", valid_602323
  var valid_602324 = header.getOrDefault("X-Amz-Algorithm")
  valid_602324 = validateParameter(valid_602324, JString, required = false,
                                 default = nil)
  if valid_602324 != nil:
    section.add "X-Amz-Algorithm", valid_602324
  var valid_602325 = header.getOrDefault("X-Amz-Signature")
  valid_602325 = validateParameter(valid_602325, JString, required = false,
                                 default = nil)
  if valid_602325 != nil:
    section.add "X-Amz-Signature", valid_602325
  var valid_602326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602326 = validateParameter(valid_602326, JString, required = false,
                                 default = nil)
  if valid_602326 != nil:
    section.add "X-Amz-SignedHeaders", valid_602326
  var valid_602327 = header.getOrDefault("X-Amz-Credential")
  valid_602327 = validateParameter(valid_602327, JString, required = false,
                                 default = nil)
  if valid_602327 != nil:
    section.add "X-Amz-Credential", valid_602327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602328: Call_GetRestartAppServer_602314; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Causes the environment to restart the application container server running on each Amazon EC2 instance.
  ## 
  let valid = call_602328.validator(path, query, header, formData, body)
  let scheme = call_602328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602328.url(scheme.get, call_602328.host, call_602328.base,
                         call_602328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602328, url, valid)

proc call*(call_602329: Call_GetRestartAppServer_602314;
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
  var query_602330 = newJObject()
  add(query_602330, "EnvironmentName", newJString(EnvironmentName))
  add(query_602330, "Action", newJString(Action))
  add(query_602330, "EnvironmentId", newJString(EnvironmentId))
  add(query_602330, "Version", newJString(Version))
  result = call_602329.call(nil, query_602330, nil, nil, nil)

var getRestartAppServer* = Call_GetRestartAppServer_602314(
    name: "getRestartAppServer", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RestartAppServer",
    validator: validate_GetRestartAppServer_602315, base: "/",
    url: url_GetRestartAppServer_602316, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRetrieveEnvironmentInfo_602367 = ref object of OpenApiRestCall_600438
proc url_PostRetrieveEnvironmentInfo_602369(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRetrieveEnvironmentInfo_602368(path: JsonNode; query: JsonNode;
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
  var valid_602370 = query.getOrDefault("Action")
  valid_602370 = validateParameter(valid_602370, JString, required = true, default = newJString(
      "RetrieveEnvironmentInfo"))
  if valid_602370 != nil:
    section.add "Action", valid_602370
  var valid_602371 = query.getOrDefault("Version")
  valid_602371 = validateParameter(valid_602371, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602371 != nil:
    section.add "Version", valid_602371
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602372 = header.getOrDefault("X-Amz-Date")
  valid_602372 = validateParameter(valid_602372, JString, required = false,
                                 default = nil)
  if valid_602372 != nil:
    section.add "X-Amz-Date", valid_602372
  var valid_602373 = header.getOrDefault("X-Amz-Security-Token")
  valid_602373 = validateParameter(valid_602373, JString, required = false,
                                 default = nil)
  if valid_602373 != nil:
    section.add "X-Amz-Security-Token", valid_602373
  var valid_602374 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602374 = validateParameter(valid_602374, JString, required = false,
                                 default = nil)
  if valid_602374 != nil:
    section.add "X-Amz-Content-Sha256", valid_602374
  var valid_602375 = header.getOrDefault("X-Amz-Algorithm")
  valid_602375 = validateParameter(valid_602375, JString, required = false,
                                 default = nil)
  if valid_602375 != nil:
    section.add "X-Amz-Algorithm", valid_602375
  var valid_602376 = header.getOrDefault("X-Amz-Signature")
  valid_602376 = validateParameter(valid_602376, JString, required = false,
                                 default = nil)
  if valid_602376 != nil:
    section.add "X-Amz-Signature", valid_602376
  var valid_602377 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602377 = validateParameter(valid_602377, JString, required = false,
                                 default = nil)
  if valid_602377 != nil:
    section.add "X-Amz-SignedHeaders", valid_602377
  var valid_602378 = header.getOrDefault("X-Amz-Credential")
  valid_602378 = validateParameter(valid_602378, JString, required = false,
                                 default = nil)
  if valid_602378 != nil:
    section.add "X-Amz-Credential", valid_602378
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
  var valid_602379 = formData.getOrDefault("InfoType")
  valid_602379 = validateParameter(valid_602379, JString, required = true,
                                 default = newJString("tail"))
  if valid_602379 != nil:
    section.add "InfoType", valid_602379
  var valid_602380 = formData.getOrDefault("EnvironmentId")
  valid_602380 = validateParameter(valid_602380, JString, required = false,
                                 default = nil)
  if valid_602380 != nil:
    section.add "EnvironmentId", valid_602380
  var valid_602381 = formData.getOrDefault("EnvironmentName")
  valid_602381 = validateParameter(valid_602381, JString, required = false,
                                 default = nil)
  if valid_602381 != nil:
    section.add "EnvironmentName", valid_602381
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602382: Call_PostRetrieveEnvironmentInfo_602367; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the compiled information from a <a>RequestEnvironmentInfo</a> request.</p> <p>Related Topics</p> <ul> <li> <p> <a>RequestEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_602382.validator(path, query, header, formData, body)
  let scheme = call_602382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602382.url(scheme.get, call_602382.host, call_602382.base,
                         call_602382.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602382, url, valid)

proc call*(call_602383: Call_PostRetrieveEnvironmentInfo_602367;
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
  var query_602384 = newJObject()
  var formData_602385 = newJObject()
  add(formData_602385, "InfoType", newJString(InfoType))
  add(formData_602385, "EnvironmentId", newJString(EnvironmentId))
  add(formData_602385, "EnvironmentName", newJString(EnvironmentName))
  add(query_602384, "Action", newJString(Action))
  add(query_602384, "Version", newJString(Version))
  result = call_602383.call(nil, query_602384, nil, formData_602385, nil)

var postRetrieveEnvironmentInfo* = Call_PostRetrieveEnvironmentInfo_602367(
    name: "postRetrieveEnvironmentInfo", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RetrieveEnvironmentInfo",
    validator: validate_PostRetrieveEnvironmentInfo_602368, base: "/",
    url: url_PostRetrieveEnvironmentInfo_602369,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRetrieveEnvironmentInfo_602349 = ref object of OpenApiRestCall_600438
proc url_GetRetrieveEnvironmentInfo_602351(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRetrieveEnvironmentInfo_602350(path: JsonNode; query: JsonNode;
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
  var valid_602352 = query.getOrDefault("InfoType")
  valid_602352 = validateParameter(valid_602352, JString, required = true,
                                 default = newJString("tail"))
  if valid_602352 != nil:
    section.add "InfoType", valid_602352
  var valid_602353 = query.getOrDefault("EnvironmentName")
  valid_602353 = validateParameter(valid_602353, JString, required = false,
                                 default = nil)
  if valid_602353 != nil:
    section.add "EnvironmentName", valid_602353
  var valid_602354 = query.getOrDefault("Action")
  valid_602354 = validateParameter(valid_602354, JString, required = true, default = newJString(
      "RetrieveEnvironmentInfo"))
  if valid_602354 != nil:
    section.add "Action", valid_602354
  var valid_602355 = query.getOrDefault("EnvironmentId")
  valid_602355 = validateParameter(valid_602355, JString, required = false,
                                 default = nil)
  if valid_602355 != nil:
    section.add "EnvironmentId", valid_602355
  var valid_602356 = query.getOrDefault("Version")
  valid_602356 = validateParameter(valid_602356, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602356 != nil:
    section.add "Version", valid_602356
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602357 = header.getOrDefault("X-Amz-Date")
  valid_602357 = validateParameter(valid_602357, JString, required = false,
                                 default = nil)
  if valid_602357 != nil:
    section.add "X-Amz-Date", valid_602357
  var valid_602358 = header.getOrDefault("X-Amz-Security-Token")
  valid_602358 = validateParameter(valid_602358, JString, required = false,
                                 default = nil)
  if valid_602358 != nil:
    section.add "X-Amz-Security-Token", valid_602358
  var valid_602359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602359 = validateParameter(valid_602359, JString, required = false,
                                 default = nil)
  if valid_602359 != nil:
    section.add "X-Amz-Content-Sha256", valid_602359
  var valid_602360 = header.getOrDefault("X-Amz-Algorithm")
  valid_602360 = validateParameter(valid_602360, JString, required = false,
                                 default = nil)
  if valid_602360 != nil:
    section.add "X-Amz-Algorithm", valid_602360
  var valid_602361 = header.getOrDefault("X-Amz-Signature")
  valid_602361 = validateParameter(valid_602361, JString, required = false,
                                 default = nil)
  if valid_602361 != nil:
    section.add "X-Amz-Signature", valid_602361
  var valid_602362 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602362 = validateParameter(valid_602362, JString, required = false,
                                 default = nil)
  if valid_602362 != nil:
    section.add "X-Amz-SignedHeaders", valid_602362
  var valid_602363 = header.getOrDefault("X-Amz-Credential")
  valid_602363 = validateParameter(valid_602363, JString, required = false,
                                 default = nil)
  if valid_602363 != nil:
    section.add "X-Amz-Credential", valid_602363
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602364: Call_GetRetrieveEnvironmentInfo_602349; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the compiled information from a <a>RequestEnvironmentInfo</a> request.</p> <p>Related Topics</p> <ul> <li> <p> <a>RequestEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_602364.validator(path, query, header, formData, body)
  let scheme = call_602364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602364.url(scheme.get, call_602364.host, call_602364.base,
                         call_602364.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602364, url, valid)

proc call*(call_602365: Call_GetRetrieveEnvironmentInfo_602349;
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
  var query_602366 = newJObject()
  add(query_602366, "InfoType", newJString(InfoType))
  add(query_602366, "EnvironmentName", newJString(EnvironmentName))
  add(query_602366, "Action", newJString(Action))
  add(query_602366, "EnvironmentId", newJString(EnvironmentId))
  add(query_602366, "Version", newJString(Version))
  result = call_602365.call(nil, query_602366, nil, nil, nil)

var getRetrieveEnvironmentInfo* = Call_GetRetrieveEnvironmentInfo_602349(
    name: "getRetrieveEnvironmentInfo", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RetrieveEnvironmentInfo",
    validator: validate_GetRetrieveEnvironmentInfo_602350, base: "/",
    url: url_GetRetrieveEnvironmentInfo_602351,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSwapEnvironmentCNAMEs_602405 = ref object of OpenApiRestCall_600438
proc url_PostSwapEnvironmentCNAMEs_602407(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSwapEnvironmentCNAMEs_602406(path: JsonNode; query: JsonNode;
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
  var valid_602408 = query.getOrDefault("Action")
  valid_602408 = validateParameter(valid_602408, JString, required = true,
                                 default = newJString("SwapEnvironmentCNAMEs"))
  if valid_602408 != nil:
    section.add "Action", valid_602408
  var valid_602409 = query.getOrDefault("Version")
  valid_602409 = validateParameter(valid_602409, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602409 != nil:
    section.add "Version", valid_602409
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602410 = header.getOrDefault("X-Amz-Date")
  valid_602410 = validateParameter(valid_602410, JString, required = false,
                                 default = nil)
  if valid_602410 != nil:
    section.add "X-Amz-Date", valid_602410
  var valid_602411 = header.getOrDefault("X-Amz-Security-Token")
  valid_602411 = validateParameter(valid_602411, JString, required = false,
                                 default = nil)
  if valid_602411 != nil:
    section.add "X-Amz-Security-Token", valid_602411
  var valid_602412 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602412 = validateParameter(valid_602412, JString, required = false,
                                 default = nil)
  if valid_602412 != nil:
    section.add "X-Amz-Content-Sha256", valid_602412
  var valid_602413 = header.getOrDefault("X-Amz-Algorithm")
  valid_602413 = validateParameter(valid_602413, JString, required = false,
                                 default = nil)
  if valid_602413 != nil:
    section.add "X-Amz-Algorithm", valid_602413
  var valid_602414 = header.getOrDefault("X-Amz-Signature")
  valid_602414 = validateParameter(valid_602414, JString, required = false,
                                 default = nil)
  if valid_602414 != nil:
    section.add "X-Amz-Signature", valid_602414
  var valid_602415 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602415 = validateParameter(valid_602415, JString, required = false,
                                 default = nil)
  if valid_602415 != nil:
    section.add "X-Amz-SignedHeaders", valid_602415
  var valid_602416 = header.getOrDefault("X-Amz-Credential")
  valid_602416 = validateParameter(valid_602416, JString, required = false,
                                 default = nil)
  if valid_602416 != nil:
    section.add "X-Amz-Credential", valid_602416
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
  var valid_602417 = formData.getOrDefault("SourceEnvironmentName")
  valid_602417 = validateParameter(valid_602417, JString, required = false,
                                 default = nil)
  if valid_602417 != nil:
    section.add "SourceEnvironmentName", valid_602417
  var valid_602418 = formData.getOrDefault("SourceEnvironmentId")
  valid_602418 = validateParameter(valid_602418, JString, required = false,
                                 default = nil)
  if valid_602418 != nil:
    section.add "SourceEnvironmentId", valid_602418
  var valid_602419 = formData.getOrDefault("DestinationEnvironmentId")
  valid_602419 = validateParameter(valid_602419, JString, required = false,
                                 default = nil)
  if valid_602419 != nil:
    section.add "DestinationEnvironmentId", valid_602419
  var valid_602420 = formData.getOrDefault("DestinationEnvironmentName")
  valid_602420 = validateParameter(valid_602420, JString, required = false,
                                 default = nil)
  if valid_602420 != nil:
    section.add "DestinationEnvironmentName", valid_602420
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602421: Call_PostSwapEnvironmentCNAMEs_602405; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Swaps the CNAMEs of two environments.
  ## 
  let valid = call_602421.validator(path, query, header, formData, body)
  let scheme = call_602421.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602421.url(scheme.get, call_602421.host, call_602421.base,
                         call_602421.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602421, url, valid)

proc call*(call_602422: Call_PostSwapEnvironmentCNAMEs_602405;
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
  var query_602423 = newJObject()
  var formData_602424 = newJObject()
  add(formData_602424, "SourceEnvironmentName", newJString(SourceEnvironmentName))
  add(formData_602424, "SourceEnvironmentId", newJString(SourceEnvironmentId))
  add(formData_602424, "DestinationEnvironmentId",
      newJString(DestinationEnvironmentId))
  add(formData_602424, "DestinationEnvironmentName",
      newJString(DestinationEnvironmentName))
  add(query_602423, "Action", newJString(Action))
  add(query_602423, "Version", newJString(Version))
  result = call_602422.call(nil, query_602423, nil, formData_602424, nil)

var postSwapEnvironmentCNAMEs* = Call_PostSwapEnvironmentCNAMEs_602405(
    name: "postSwapEnvironmentCNAMEs", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=SwapEnvironmentCNAMEs",
    validator: validate_PostSwapEnvironmentCNAMEs_602406, base: "/",
    url: url_PostSwapEnvironmentCNAMEs_602407,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSwapEnvironmentCNAMEs_602386 = ref object of OpenApiRestCall_600438
proc url_GetSwapEnvironmentCNAMEs_602388(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSwapEnvironmentCNAMEs_602387(path: JsonNode; query: JsonNode;
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
  var valid_602389 = query.getOrDefault("SourceEnvironmentId")
  valid_602389 = validateParameter(valid_602389, JString, required = false,
                                 default = nil)
  if valid_602389 != nil:
    section.add "SourceEnvironmentId", valid_602389
  var valid_602390 = query.getOrDefault("DestinationEnvironmentName")
  valid_602390 = validateParameter(valid_602390, JString, required = false,
                                 default = nil)
  if valid_602390 != nil:
    section.add "DestinationEnvironmentName", valid_602390
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602391 = query.getOrDefault("Action")
  valid_602391 = validateParameter(valid_602391, JString, required = true,
                                 default = newJString("SwapEnvironmentCNAMEs"))
  if valid_602391 != nil:
    section.add "Action", valid_602391
  var valid_602392 = query.getOrDefault("SourceEnvironmentName")
  valid_602392 = validateParameter(valid_602392, JString, required = false,
                                 default = nil)
  if valid_602392 != nil:
    section.add "SourceEnvironmentName", valid_602392
  var valid_602393 = query.getOrDefault("DestinationEnvironmentId")
  valid_602393 = validateParameter(valid_602393, JString, required = false,
                                 default = nil)
  if valid_602393 != nil:
    section.add "DestinationEnvironmentId", valid_602393
  var valid_602394 = query.getOrDefault("Version")
  valid_602394 = validateParameter(valid_602394, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602394 != nil:
    section.add "Version", valid_602394
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602395 = header.getOrDefault("X-Amz-Date")
  valid_602395 = validateParameter(valid_602395, JString, required = false,
                                 default = nil)
  if valid_602395 != nil:
    section.add "X-Amz-Date", valid_602395
  var valid_602396 = header.getOrDefault("X-Amz-Security-Token")
  valid_602396 = validateParameter(valid_602396, JString, required = false,
                                 default = nil)
  if valid_602396 != nil:
    section.add "X-Amz-Security-Token", valid_602396
  var valid_602397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602397 = validateParameter(valid_602397, JString, required = false,
                                 default = nil)
  if valid_602397 != nil:
    section.add "X-Amz-Content-Sha256", valid_602397
  var valid_602398 = header.getOrDefault("X-Amz-Algorithm")
  valid_602398 = validateParameter(valid_602398, JString, required = false,
                                 default = nil)
  if valid_602398 != nil:
    section.add "X-Amz-Algorithm", valid_602398
  var valid_602399 = header.getOrDefault("X-Amz-Signature")
  valid_602399 = validateParameter(valid_602399, JString, required = false,
                                 default = nil)
  if valid_602399 != nil:
    section.add "X-Amz-Signature", valid_602399
  var valid_602400 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602400 = validateParameter(valid_602400, JString, required = false,
                                 default = nil)
  if valid_602400 != nil:
    section.add "X-Amz-SignedHeaders", valid_602400
  var valid_602401 = header.getOrDefault("X-Amz-Credential")
  valid_602401 = validateParameter(valid_602401, JString, required = false,
                                 default = nil)
  if valid_602401 != nil:
    section.add "X-Amz-Credential", valid_602401
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602402: Call_GetSwapEnvironmentCNAMEs_602386; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Swaps the CNAMEs of two environments.
  ## 
  let valid = call_602402.validator(path, query, header, formData, body)
  let scheme = call_602402.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602402.url(scheme.get, call_602402.host, call_602402.base,
                         call_602402.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602402, url, valid)

proc call*(call_602403: Call_GetSwapEnvironmentCNAMEs_602386;
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
  var query_602404 = newJObject()
  add(query_602404, "SourceEnvironmentId", newJString(SourceEnvironmentId))
  add(query_602404, "DestinationEnvironmentName",
      newJString(DestinationEnvironmentName))
  add(query_602404, "Action", newJString(Action))
  add(query_602404, "SourceEnvironmentName", newJString(SourceEnvironmentName))
  add(query_602404, "DestinationEnvironmentId",
      newJString(DestinationEnvironmentId))
  add(query_602404, "Version", newJString(Version))
  result = call_602403.call(nil, query_602404, nil, nil, nil)

var getSwapEnvironmentCNAMEs* = Call_GetSwapEnvironmentCNAMEs_602386(
    name: "getSwapEnvironmentCNAMEs", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=SwapEnvironmentCNAMEs",
    validator: validate_GetSwapEnvironmentCNAMEs_602387, base: "/",
    url: url_GetSwapEnvironmentCNAMEs_602388, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostTerminateEnvironment_602444 = ref object of OpenApiRestCall_600438
proc url_PostTerminateEnvironment_602446(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostTerminateEnvironment_602445(path: JsonNode; query: JsonNode;
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
  var valid_602447 = query.getOrDefault("Action")
  valid_602447 = validateParameter(valid_602447, JString, required = true,
                                 default = newJString("TerminateEnvironment"))
  if valid_602447 != nil:
    section.add "Action", valid_602447
  var valid_602448 = query.getOrDefault("Version")
  valid_602448 = validateParameter(valid_602448, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602448 != nil:
    section.add "Version", valid_602448
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602449 = header.getOrDefault("X-Amz-Date")
  valid_602449 = validateParameter(valid_602449, JString, required = false,
                                 default = nil)
  if valid_602449 != nil:
    section.add "X-Amz-Date", valid_602449
  var valid_602450 = header.getOrDefault("X-Amz-Security-Token")
  valid_602450 = validateParameter(valid_602450, JString, required = false,
                                 default = nil)
  if valid_602450 != nil:
    section.add "X-Amz-Security-Token", valid_602450
  var valid_602451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602451 = validateParameter(valid_602451, JString, required = false,
                                 default = nil)
  if valid_602451 != nil:
    section.add "X-Amz-Content-Sha256", valid_602451
  var valid_602452 = header.getOrDefault("X-Amz-Algorithm")
  valid_602452 = validateParameter(valid_602452, JString, required = false,
                                 default = nil)
  if valid_602452 != nil:
    section.add "X-Amz-Algorithm", valid_602452
  var valid_602453 = header.getOrDefault("X-Amz-Signature")
  valid_602453 = validateParameter(valid_602453, JString, required = false,
                                 default = nil)
  if valid_602453 != nil:
    section.add "X-Amz-Signature", valid_602453
  var valid_602454 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602454 = validateParameter(valid_602454, JString, required = false,
                                 default = nil)
  if valid_602454 != nil:
    section.add "X-Amz-SignedHeaders", valid_602454
  var valid_602455 = header.getOrDefault("X-Amz-Credential")
  valid_602455 = validateParameter(valid_602455, JString, required = false,
                                 default = nil)
  if valid_602455 != nil:
    section.add "X-Amz-Credential", valid_602455
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
  var valid_602456 = formData.getOrDefault("ForceTerminate")
  valid_602456 = validateParameter(valid_602456, JBool, required = false, default = nil)
  if valid_602456 != nil:
    section.add "ForceTerminate", valid_602456
  var valid_602457 = formData.getOrDefault("TerminateResources")
  valid_602457 = validateParameter(valid_602457, JBool, required = false, default = nil)
  if valid_602457 != nil:
    section.add "TerminateResources", valid_602457
  var valid_602458 = formData.getOrDefault("EnvironmentId")
  valid_602458 = validateParameter(valid_602458, JString, required = false,
                                 default = nil)
  if valid_602458 != nil:
    section.add "EnvironmentId", valid_602458
  var valid_602459 = formData.getOrDefault("EnvironmentName")
  valid_602459 = validateParameter(valid_602459, JString, required = false,
                                 default = nil)
  if valid_602459 != nil:
    section.add "EnvironmentName", valid_602459
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602460: Call_PostTerminateEnvironment_602444; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Terminates the specified environment.
  ## 
  let valid = call_602460.validator(path, query, header, formData, body)
  let scheme = call_602460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602460.url(scheme.get, call_602460.host, call_602460.base,
                         call_602460.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602460, url, valid)

proc call*(call_602461: Call_PostTerminateEnvironment_602444;
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
  var query_602462 = newJObject()
  var formData_602463 = newJObject()
  add(formData_602463, "ForceTerminate", newJBool(ForceTerminate))
  add(formData_602463, "TerminateResources", newJBool(TerminateResources))
  add(formData_602463, "EnvironmentId", newJString(EnvironmentId))
  add(formData_602463, "EnvironmentName", newJString(EnvironmentName))
  add(query_602462, "Action", newJString(Action))
  add(query_602462, "Version", newJString(Version))
  result = call_602461.call(nil, query_602462, nil, formData_602463, nil)

var postTerminateEnvironment* = Call_PostTerminateEnvironment_602444(
    name: "postTerminateEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=TerminateEnvironment",
    validator: validate_PostTerminateEnvironment_602445, base: "/",
    url: url_PostTerminateEnvironment_602446, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTerminateEnvironment_602425 = ref object of OpenApiRestCall_600438
proc url_GetTerminateEnvironment_602427(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetTerminateEnvironment_602426(path: JsonNode; query: JsonNode;
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
  var valid_602428 = query.getOrDefault("EnvironmentName")
  valid_602428 = validateParameter(valid_602428, JString, required = false,
                                 default = nil)
  if valid_602428 != nil:
    section.add "EnvironmentName", valid_602428
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602429 = query.getOrDefault("Action")
  valid_602429 = validateParameter(valid_602429, JString, required = true,
                                 default = newJString("TerminateEnvironment"))
  if valid_602429 != nil:
    section.add "Action", valid_602429
  var valid_602430 = query.getOrDefault("EnvironmentId")
  valid_602430 = validateParameter(valid_602430, JString, required = false,
                                 default = nil)
  if valid_602430 != nil:
    section.add "EnvironmentId", valid_602430
  var valid_602431 = query.getOrDefault("ForceTerminate")
  valid_602431 = validateParameter(valid_602431, JBool, required = false, default = nil)
  if valid_602431 != nil:
    section.add "ForceTerminate", valid_602431
  var valid_602432 = query.getOrDefault("TerminateResources")
  valid_602432 = validateParameter(valid_602432, JBool, required = false, default = nil)
  if valid_602432 != nil:
    section.add "TerminateResources", valid_602432
  var valid_602433 = query.getOrDefault("Version")
  valid_602433 = validateParameter(valid_602433, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602433 != nil:
    section.add "Version", valid_602433
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602434 = header.getOrDefault("X-Amz-Date")
  valid_602434 = validateParameter(valid_602434, JString, required = false,
                                 default = nil)
  if valid_602434 != nil:
    section.add "X-Amz-Date", valid_602434
  var valid_602435 = header.getOrDefault("X-Amz-Security-Token")
  valid_602435 = validateParameter(valid_602435, JString, required = false,
                                 default = nil)
  if valid_602435 != nil:
    section.add "X-Amz-Security-Token", valid_602435
  var valid_602436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602436 = validateParameter(valid_602436, JString, required = false,
                                 default = nil)
  if valid_602436 != nil:
    section.add "X-Amz-Content-Sha256", valid_602436
  var valid_602437 = header.getOrDefault("X-Amz-Algorithm")
  valid_602437 = validateParameter(valid_602437, JString, required = false,
                                 default = nil)
  if valid_602437 != nil:
    section.add "X-Amz-Algorithm", valid_602437
  var valid_602438 = header.getOrDefault("X-Amz-Signature")
  valid_602438 = validateParameter(valid_602438, JString, required = false,
                                 default = nil)
  if valid_602438 != nil:
    section.add "X-Amz-Signature", valid_602438
  var valid_602439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602439 = validateParameter(valid_602439, JString, required = false,
                                 default = nil)
  if valid_602439 != nil:
    section.add "X-Amz-SignedHeaders", valid_602439
  var valid_602440 = header.getOrDefault("X-Amz-Credential")
  valid_602440 = validateParameter(valid_602440, JString, required = false,
                                 default = nil)
  if valid_602440 != nil:
    section.add "X-Amz-Credential", valid_602440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602441: Call_GetTerminateEnvironment_602425; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Terminates the specified environment.
  ## 
  let valid = call_602441.validator(path, query, header, formData, body)
  let scheme = call_602441.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602441.url(scheme.get, call_602441.host, call_602441.base,
                         call_602441.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602441, url, valid)

proc call*(call_602442: Call_GetTerminateEnvironment_602425;
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
  var query_602443 = newJObject()
  add(query_602443, "EnvironmentName", newJString(EnvironmentName))
  add(query_602443, "Action", newJString(Action))
  add(query_602443, "EnvironmentId", newJString(EnvironmentId))
  add(query_602443, "ForceTerminate", newJBool(ForceTerminate))
  add(query_602443, "TerminateResources", newJBool(TerminateResources))
  add(query_602443, "Version", newJString(Version))
  result = call_602442.call(nil, query_602443, nil, nil, nil)

var getTerminateEnvironment* = Call_GetTerminateEnvironment_602425(
    name: "getTerminateEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=TerminateEnvironment",
    validator: validate_GetTerminateEnvironment_602426, base: "/",
    url: url_GetTerminateEnvironment_602427, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateApplication_602481 = ref object of OpenApiRestCall_600438
proc url_PostUpdateApplication_602483(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateApplication_602482(path: JsonNode; query: JsonNode;
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
  var valid_602484 = query.getOrDefault("Action")
  valid_602484 = validateParameter(valid_602484, JString, required = true,
                                 default = newJString("UpdateApplication"))
  if valid_602484 != nil:
    section.add "Action", valid_602484
  var valid_602485 = query.getOrDefault("Version")
  valid_602485 = validateParameter(valid_602485, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602485 != nil:
    section.add "Version", valid_602485
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602486 = header.getOrDefault("X-Amz-Date")
  valid_602486 = validateParameter(valid_602486, JString, required = false,
                                 default = nil)
  if valid_602486 != nil:
    section.add "X-Amz-Date", valid_602486
  var valid_602487 = header.getOrDefault("X-Amz-Security-Token")
  valid_602487 = validateParameter(valid_602487, JString, required = false,
                                 default = nil)
  if valid_602487 != nil:
    section.add "X-Amz-Security-Token", valid_602487
  var valid_602488 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602488 = validateParameter(valid_602488, JString, required = false,
                                 default = nil)
  if valid_602488 != nil:
    section.add "X-Amz-Content-Sha256", valid_602488
  var valid_602489 = header.getOrDefault("X-Amz-Algorithm")
  valid_602489 = validateParameter(valid_602489, JString, required = false,
                                 default = nil)
  if valid_602489 != nil:
    section.add "X-Amz-Algorithm", valid_602489
  var valid_602490 = header.getOrDefault("X-Amz-Signature")
  valid_602490 = validateParameter(valid_602490, JString, required = false,
                                 default = nil)
  if valid_602490 != nil:
    section.add "X-Amz-Signature", valid_602490
  var valid_602491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602491 = validateParameter(valid_602491, JString, required = false,
                                 default = nil)
  if valid_602491 != nil:
    section.add "X-Amz-SignedHeaders", valid_602491
  var valid_602492 = header.getOrDefault("X-Amz-Credential")
  valid_602492 = validateParameter(valid_602492, JString, required = false,
                                 default = nil)
  if valid_602492 != nil:
    section.add "X-Amz-Credential", valid_602492
  result.add "header", section
  ## parameters in `formData` object:
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to update. If no such application is found, <code>UpdateApplication</code> returns an <code>InvalidParameterValue</code> error. 
  ##   Description: JString
  ##              : <p>A new description for the application.</p> <p>Default: If not specified, AWS Elastic Beanstalk does not update the description.</p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_602493 = formData.getOrDefault("ApplicationName")
  valid_602493 = validateParameter(valid_602493, JString, required = true,
                                 default = nil)
  if valid_602493 != nil:
    section.add "ApplicationName", valid_602493
  var valid_602494 = formData.getOrDefault("Description")
  valid_602494 = validateParameter(valid_602494, JString, required = false,
                                 default = nil)
  if valid_602494 != nil:
    section.add "Description", valid_602494
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602495: Call_PostUpdateApplication_602481; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified application to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear these properties, specify an empty string.</p> </note>
  ## 
  let valid = call_602495.validator(path, query, header, formData, body)
  let scheme = call_602495.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602495.url(scheme.get, call_602495.host, call_602495.base,
                         call_602495.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602495, url, valid)

proc call*(call_602496: Call_PostUpdateApplication_602481; ApplicationName: string;
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
  var query_602497 = newJObject()
  var formData_602498 = newJObject()
  add(query_602497, "Action", newJString(Action))
  add(formData_602498, "ApplicationName", newJString(ApplicationName))
  add(query_602497, "Version", newJString(Version))
  add(formData_602498, "Description", newJString(Description))
  result = call_602496.call(nil, query_602497, nil, formData_602498, nil)

var postUpdateApplication* = Call_PostUpdateApplication_602481(
    name: "postUpdateApplication", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateApplication",
    validator: validate_PostUpdateApplication_602482, base: "/",
    url: url_PostUpdateApplication_602483, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateApplication_602464 = ref object of OpenApiRestCall_600438
proc url_GetUpdateApplication_602466(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateApplication_602465(path: JsonNode; query: JsonNode;
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
  var valid_602467 = query.getOrDefault("ApplicationName")
  valid_602467 = validateParameter(valid_602467, JString, required = true,
                                 default = nil)
  if valid_602467 != nil:
    section.add "ApplicationName", valid_602467
  var valid_602468 = query.getOrDefault("Description")
  valid_602468 = validateParameter(valid_602468, JString, required = false,
                                 default = nil)
  if valid_602468 != nil:
    section.add "Description", valid_602468
  var valid_602469 = query.getOrDefault("Action")
  valid_602469 = validateParameter(valid_602469, JString, required = true,
                                 default = newJString("UpdateApplication"))
  if valid_602469 != nil:
    section.add "Action", valid_602469
  var valid_602470 = query.getOrDefault("Version")
  valid_602470 = validateParameter(valid_602470, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602470 != nil:
    section.add "Version", valid_602470
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602471 = header.getOrDefault("X-Amz-Date")
  valid_602471 = validateParameter(valid_602471, JString, required = false,
                                 default = nil)
  if valid_602471 != nil:
    section.add "X-Amz-Date", valid_602471
  var valid_602472 = header.getOrDefault("X-Amz-Security-Token")
  valid_602472 = validateParameter(valid_602472, JString, required = false,
                                 default = nil)
  if valid_602472 != nil:
    section.add "X-Amz-Security-Token", valid_602472
  var valid_602473 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602473 = validateParameter(valid_602473, JString, required = false,
                                 default = nil)
  if valid_602473 != nil:
    section.add "X-Amz-Content-Sha256", valid_602473
  var valid_602474 = header.getOrDefault("X-Amz-Algorithm")
  valid_602474 = validateParameter(valid_602474, JString, required = false,
                                 default = nil)
  if valid_602474 != nil:
    section.add "X-Amz-Algorithm", valid_602474
  var valid_602475 = header.getOrDefault("X-Amz-Signature")
  valid_602475 = validateParameter(valid_602475, JString, required = false,
                                 default = nil)
  if valid_602475 != nil:
    section.add "X-Amz-Signature", valid_602475
  var valid_602476 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602476 = validateParameter(valid_602476, JString, required = false,
                                 default = nil)
  if valid_602476 != nil:
    section.add "X-Amz-SignedHeaders", valid_602476
  var valid_602477 = header.getOrDefault("X-Amz-Credential")
  valid_602477 = validateParameter(valid_602477, JString, required = false,
                                 default = nil)
  if valid_602477 != nil:
    section.add "X-Amz-Credential", valid_602477
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602478: Call_GetUpdateApplication_602464; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified application to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear these properties, specify an empty string.</p> </note>
  ## 
  let valid = call_602478.validator(path, query, header, formData, body)
  let scheme = call_602478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602478.url(scheme.get, call_602478.host, call_602478.base,
                         call_602478.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602478, url, valid)

proc call*(call_602479: Call_GetUpdateApplication_602464; ApplicationName: string;
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
  var query_602480 = newJObject()
  add(query_602480, "ApplicationName", newJString(ApplicationName))
  add(query_602480, "Description", newJString(Description))
  add(query_602480, "Action", newJString(Action))
  add(query_602480, "Version", newJString(Version))
  result = call_602479.call(nil, query_602480, nil, nil, nil)

var getUpdateApplication* = Call_GetUpdateApplication_602464(
    name: "getUpdateApplication", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateApplication",
    validator: validate_GetUpdateApplication_602465, base: "/",
    url: url_GetUpdateApplication_602466, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateApplicationResourceLifecycle_602517 = ref object of OpenApiRestCall_600438
proc url_PostUpdateApplicationResourceLifecycle_602519(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateApplicationResourceLifecycle_602518(path: JsonNode;
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
  var valid_602520 = query.getOrDefault("Action")
  valid_602520 = validateParameter(valid_602520, JString, required = true, default = newJString(
      "UpdateApplicationResourceLifecycle"))
  if valid_602520 != nil:
    section.add "Action", valid_602520
  var valid_602521 = query.getOrDefault("Version")
  valid_602521 = validateParameter(valid_602521, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602521 != nil:
    section.add "Version", valid_602521
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602522 = header.getOrDefault("X-Amz-Date")
  valid_602522 = validateParameter(valid_602522, JString, required = false,
                                 default = nil)
  if valid_602522 != nil:
    section.add "X-Amz-Date", valid_602522
  var valid_602523 = header.getOrDefault("X-Amz-Security-Token")
  valid_602523 = validateParameter(valid_602523, JString, required = false,
                                 default = nil)
  if valid_602523 != nil:
    section.add "X-Amz-Security-Token", valid_602523
  var valid_602524 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602524 = validateParameter(valid_602524, JString, required = false,
                                 default = nil)
  if valid_602524 != nil:
    section.add "X-Amz-Content-Sha256", valid_602524
  var valid_602525 = header.getOrDefault("X-Amz-Algorithm")
  valid_602525 = validateParameter(valid_602525, JString, required = false,
                                 default = nil)
  if valid_602525 != nil:
    section.add "X-Amz-Algorithm", valid_602525
  var valid_602526 = header.getOrDefault("X-Amz-Signature")
  valid_602526 = validateParameter(valid_602526, JString, required = false,
                                 default = nil)
  if valid_602526 != nil:
    section.add "X-Amz-Signature", valid_602526
  var valid_602527 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602527 = validateParameter(valid_602527, JString, required = false,
                                 default = nil)
  if valid_602527 != nil:
    section.add "X-Amz-SignedHeaders", valid_602527
  var valid_602528 = header.getOrDefault("X-Amz-Credential")
  valid_602528 = validateParameter(valid_602528, JString, required = false,
                                 default = nil)
  if valid_602528 != nil:
    section.add "X-Amz-Credential", valid_602528
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
  var valid_602529 = formData.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_602529 = validateParameter(valid_602529, JString, required = false,
                                 default = nil)
  if valid_602529 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_602529
  var valid_602530 = formData.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_602530 = validateParameter(valid_602530, JString, required = false,
                                 default = nil)
  if valid_602530 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_602530
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_602531 = formData.getOrDefault("ApplicationName")
  valid_602531 = validateParameter(valid_602531, JString, required = true,
                                 default = nil)
  if valid_602531 != nil:
    section.add "ApplicationName", valid_602531
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602532: Call_PostUpdateApplicationResourceLifecycle_602517;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Modifies lifecycle settings for an application.
  ## 
  let valid = call_602532.validator(path, query, header, formData, body)
  let scheme = call_602532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602532.url(scheme.get, call_602532.host, call_602532.base,
                         call_602532.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602532, url, valid)

proc call*(call_602533: Call_PostUpdateApplicationResourceLifecycle_602517;
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
  var query_602534 = newJObject()
  var formData_602535 = newJObject()
  add(formData_602535, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  add(formData_602535, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  add(query_602534, "Action", newJString(Action))
  add(formData_602535, "ApplicationName", newJString(ApplicationName))
  add(query_602534, "Version", newJString(Version))
  result = call_602533.call(nil, query_602534, nil, formData_602535, nil)

var postUpdateApplicationResourceLifecycle* = Call_PostUpdateApplicationResourceLifecycle_602517(
    name: "postUpdateApplicationResourceLifecycle", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationResourceLifecycle",
    validator: validate_PostUpdateApplicationResourceLifecycle_602518, base: "/",
    url: url_PostUpdateApplicationResourceLifecycle_602519,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateApplicationResourceLifecycle_602499 = ref object of OpenApiRestCall_600438
proc url_GetUpdateApplicationResourceLifecycle_602501(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateApplicationResourceLifecycle_602500(path: JsonNode;
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
  var valid_602502 = query.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_602502 = validateParameter(valid_602502, JString, required = false,
                                 default = nil)
  if valid_602502 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_602502
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_602503 = query.getOrDefault("ApplicationName")
  valid_602503 = validateParameter(valid_602503, JString, required = true,
                                 default = nil)
  if valid_602503 != nil:
    section.add "ApplicationName", valid_602503
  var valid_602504 = query.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_602504 = validateParameter(valid_602504, JString, required = false,
                                 default = nil)
  if valid_602504 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_602504
  var valid_602505 = query.getOrDefault("Action")
  valid_602505 = validateParameter(valid_602505, JString, required = true, default = newJString(
      "UpdateApplicationResourceLifecycle"))
  if valid_602505 != nil:
    section.add "Action", valid_602505
  var valid_602506 = query.getOrDefault("Version")
  valid_602506 = validateParameter(valid_602506, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602506 != nil:
    section.add "Version", valid_602506
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602507 = header.getOrDefault("X-Amz-Date")
  valid_602507 = validateParameter(valid_602507, JString, required = false,
                                 default = nil)
  if valid_602507 != nil:
    section.add "X-Amz-Date", valid_602507
  var valid_602508 = header.getOrDefault("X-Amz-Security-Token")
  valid_602508 = validateParameter(valid_602508, JString, required = false,
                                 default = nil)
  if valid_602508 != nil:
    section.add "X-Amz-Security-Token", valid_602508
  var valid_602509 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602509 = validateParameter(valid_602509, JString, required = false,
                                 default = nil)
  if valid_602509 != nil:
    section.add "X-Amz-Content-Sha256", valid_602509
  var valid_602510 = header.getOrDefault("X-Amz-Algorithm")
  valid_602510 = validateParameter(valid_602510, JString, required = false,
                                 default = nil)
  if valid_602510 != nil:
    section.add "X-Amz-Algorithm", valid_602510
  var valid_602511 = header.getOrDefault("X-Amz-Signature")
  valid_602511 = validateParameter(valid_602511, JString, required = false,
                                 default = nil)
  if valid_602511 != nil:
    section.add "X-Amz-Signature", valid_602511
  var valid_602512 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602512 = validateParameter(valid_602512, JString, required = false,
                                 default = nil)
  if valid_602512 != nil:
    section.add "X-Amz-SignedHeaders", valid_602512
  var valid_602513 = header.getOrDefault("X-Amz-Credential")
  valid_602513 = validateParameter(valid_602513, JString, required = false,
                                 default = nil)
  if valid_602513 != nil:
    section.add "X-Amz-Credential", valid_602513
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602514: Call_GetUpdateApplicationResourceLifecycle_602499;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Modifies lifecycle settings for an application.
  ## 
  let valid = call_602514.validator(path, query, header, formData, body)
  let scheme = call_602514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602514.url(scheme.get, call_602514.host, call_602514.base,
                         call_602514.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602514, url, valid)

proc call*(call_602515: Call_GetUpdateApplicationResourceLifecycle_602499;
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
  var query_602516 = newJObject()
  add(query_602516, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  add(query_602516, "ApplicationName", newJString(ApplicationName))
  add(query_602516, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  add(query_602516, "Action", newJString(Action))
  add(query_602516, "Version", newJString(Version))
  result = call_602515.call(nil, query_602516, nil, nil, nil)

var getUpdateApplicationResourceLifecycle* = Call_GetUpdateApplicationResourceLifecycle_602499(
    name: "getUpdateApplicationResourceLifecycle", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationResourceLifecycle",
    validator: validate_GetUpdateApplicationResourceLifecycle_602500, base: "/",
    url: url_GetUpdateApplicationResourceLifecycle_602501,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateApplicationVersion_602554 = ref object of OpenApiRestCall_600438
proc url_PostUpdateApplicationVersion_602556(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateApplicationVersion_602555(path: JsonNode; query: JsonNode;
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
  var valid_602557 = query.getOrDefault("Action")
  valid_602557 = validateParameter(valid_602557, JString, required = true, default = newJString(
      "UpdateApplicationVersion"))
  if valid_602557 != nil:
    section.add "Action", valid_602557
  var valid_602558 = query.getOrDefault("Version")
  valid_602558 = validateParameter(valid_602558, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602558 != nil:
    section.add "Version", valid_602558
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602559 = header.getOrDefault("X-Amz-Date")
  valid_602559 = validateParameter(valid_602559, JString, required = false,
                                 default = nil)
  if valid_602559 != nil:
    section.add "X-Amz-Date", valid_602559
  var valid_602560 = header.getOrDefault("X-Amz-Security-Token")
  valid_602560 = validateParameter(valid_602560, JString, required = false,
                                 default = nil)
  if valid_602560 != nil:
    section.add "X-Amz-Security-Token", valid_602560
  var valid_602561 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602561 = validateParameter(valid_602561, JString, required = false,
                                 default = nil)
  if valid_602561 != nil:
    section.add "X-Amz-Content-Sha256", valid_602561
  var valid_602562 = header.getOrDefault("X-Amz-Algorithm")
  valid_602562 = validateParameter(valid_602562, JString, required = false,
                                 default = nil)
  if valid_602562 != nil:
    section.add "X-Amz-Algorithm", valid_602562
  var valid_602563 = header.getOrDefault("X-Amz-Signature")
  valid_602563 = validateParameter(valid_602563, JString, required = false,
                                 default = nil)
  if valid_602563 != nil:
    section.add "X-Amz-Signature", valid_602563
  var valid_602564 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602564 = validateParameter(valid_602564, JString, required = false,
                                 default = nil)
  if valid_602564 != nil:
    section.add "X-Amz-SignedHeaders", valid_602564
  var valid_602565 = header.getOrDefault("X-Amz-Credential")
  valid_602565 = validateParameter(valid_602565, JString, required = false,
                                 default = nil)
  if valid_602565 != nil:
    section.add "X-Amz-Credential", valid_602565
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
  var valid_602566 = formData.getOrDefault("VersionLabel")
  valid_602566 = validateParameter(valid_602566, JString, required = true,
                                 default = nil)
  if valid_602566 != nil:
    section.add "VersionLabel", valid_602566
  var valid_602567 = formData.getOrDefault("ApplicationName")
  valid_602567 = validateParameter(valid_602567, JString, required = true,
                                 default = nil)
  if valid_602567 != nil:
    section.add "ApplicationName", valid_602567
  var valid_602568 = formData.getOrDefault("Description")
  valid_602568 = validateParameter(valid_602568, JString, required = false,
                                 default = nil)
  if valid_602568 != nil:
    section.add "Description", valid_602568
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602569: Call_PostUpdateApplicationVersion_602554; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified application version to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear properties, specify an empty string.</p> </note>
  ## 
  let valid = call_602569.validator(path, query, header, formData, body)
  let scheme = call_602569.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602569.url(scheme.get, call_602569.host, call_602569.base,
                         call_602569.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602569, url, valid)

proc call*(call_602570: Call_PostUpdateApplicationVersion_602554;
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
  var query_602571 = newJObject()
  var formData_602572 = newJObject()
  add(formData_602572, "VersionLabel", newJString(VersionLabel))
  add(query_602571, "Action", newJString(Action))
  add(formData_602572, "ApplicationName", newJString(ApplicationName))
  add(query_602571, "Version", newJString(Version))
  add(formData_602572, "Description", newJString(Description))
  result = call_602570.call(nil, query_602571, nil, formData_602572, nil)

var postUpdateApplicationVersion* = Call_PostUpdateApplicationVersion_602554(
    name: "postUpdateApplicationVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationVersion",
    validator: validate_PostUpdateApplicationVersion_602555, base: "/",
    url: url_PostUpdateApplicationVersion_602556,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateApplicationVersion_602536 = ref object of OpenApiRestCall_600438
proc url_GetUpdateApplicationVersion_602538(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateApplicationVersion_602537(path: JsonNode; query: JsonNode;
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
  var valid_602539 = query.getOrDefault("VersionLabel")
  valid_602539 = validateParameter(valid_602539, JString, required = true,
                                 default = nil)
  if valid_602539 != nil:
    section.add "VersionLabel", valid_602539
  var valid_602540 = query.getOrDefault("ApplicationName")
  valid_602540 = validateParameter(valid_602540, JString, required = true,
                                 default = nil)
  if valid_602540 != nil:
    section.add "ApplicationName", valid_602540
  var valid_602541 = query.getOrDefault("Description")
  valid_602541 = validateParameter(valid_602541, JString, required = false,
                                 default = nil)
  if valid_602541 != nil:
    section.add "Description", valid_602541
  var valid_602542 = query.getOrDefault("Action")
  valid_602542 = validateParameter(valid_602542, JString, required = true, default = newJString(
      "UpdateApplicationVersion"))
  if valid_602542 != nil:
    section.add "Action", valid_602542
  var valid_602543 = query.getOrDefault("Version")
  valid_602543 = validateParameter(valid_602543, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602543 != nil:
    section.add "Version", valid_602543
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602544 = header.getOrDefault("X-Amz-Date")
  valid_602544 = validateParameter(valid_602544, JString, required = false,
                                 default = nil)
  if valid_602544 != nil:
    section.add "X-Amz-Date", valid_602544
  var valid_602545 = header.getOrDefault("X-Amz-Security-Token")
  valid_602545 = validateParameter(valid_602545, JString, required = false,
                                 default = nil)
  if valid_602545 != nil:
    section.add "X-Amz-Security-Token", valid_602545
  var valid_602546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602546 = validateParameter(valid_602546, JString, required = false,
                                 default = nil)
  if valid_602546 != nil:
    section.add "X-Amz-Content-Sha256", valid_602546
  var valid_602547 = header.getOrDefault("X-Amz-Algorithm")
  valid_602547 = validateParameter(valid_602547, JString, required = false,
                                 default = nil)
  if valid_602547 != nil:
    section.add "X-Amz-Algorithm", valid_602547
  var valid_602548 = header.getOrDefault("X-Amz-Signature")
  valid_602548 = validateParameter(valid_602548, JString, required = false,
                                 default = nil)
  if valid_602548 != nil:
    section.add "X-Amz-Signature", valid_602548
  var valid_602549 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602549 = validateParameter(valid_602549, JString, required = false,
                                 default = nil)
  if valid_602549 != nil:
    section.add "X-Amz-SignedHeaders", valid_602549
  var valid_602550 = header.getOrDefault("X-Amz-Credential")
  valid_602550 = validateParameter(valid_602550, JString, required = false,
                                 default = nil)
  if valid_602550 != nil:
    section.add "X-Amz-Credential", valid_602550
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602551: Call_GetUpdateApplicationVersion_602536; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified application version to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear properties, specify an empty string.</p> </note>
  ## 
  let valid = call_602551.validator(path, query, header, formData, body)
  let scheme = call_602551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602551.url(scheme.get, call_602551.host, call_602551.base,
                         call_602551.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602551, url, valid)

proc call*(call_602552: Call_GetUpdateApplicationVersion_602536;
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
  var query_602553 = newJObject()
  add(query_602553, "VersionLabel", newJString(VersionLabel))
  add(query_602553, "ApplicationName", newJString(ApplicationName))
  add(query_602553, "Description", newJString(Description))
  add(query_602553, "Action", newJString(Action))
  add(query_602553, "Version", newJString(Version))
  result = call_602552.call(nil, query_602553, nil, nil, nil)

var getUpdateApplicationVersion* = Call_GetUpdateApplicationVersion_602536(
    name: "getUpdateApplicationVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationVersion",
    validator: validate_GetUpdateApplicationVersion_602537, base: "/",
    url: url_GetUpdateApplicationVersion_602538,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateConfigurationTemplate_602593 = ref object of OpenApiRestCall_600438
proc url_PostUpdateConfigurationTemplate_602595(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateConfigurationTemplate_602594(path: JsonNode;
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
  var valid_602596 = query.getOrDefault("Action")
  valid_602596 = validateParameter(valid_602596, JString, required = true, default = newJString(
      "UpdateConfigurationTemplate"))
  if valid_602596 != nil:
    section.add "Action", valid_602596
  var valid_602597 = query.getOrDefault("Version")
  valid_602597 = validateParameter(valid_602597, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602597 != nil:
    section.add "Version", valid_602597
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602598 = header.getOrDefault("X-Amz-Date")
  valid_602598 = validateParameter(valid_602598, JString, required = false,
                                 default = nil)
  if valid_602598 != nil:
    section.add "X-Amz-Date", valid_602598
  var valid_602599 = header.getOrDefault("X-Amz-Security-Token")
  valid_602599 = validateParameter(valid_602599, JString, required = false,
                                 default = nil)
  if valid_602599 != nil:
    section.add "X-Amz-Security-Token", valid_602599
  var valid_602600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602600 = validateParameter(valid_602600, JString, required = false,
                                 default = nil)
  if valid_602600 != nil:
    section.add "X-Amz-Content-Sha256", valid_602600
  var valid_602601 = header.getOrDefault("X-Amz-Algorithm")
  valid_602601 = validateParameter(valid_602601, JString, required = false,
                                 default = nil)
  if valid_602601 != nil:
    section.add "X-Amz-Algorithm", valid_602601
  var valid_602602 = header.getOrDefault("X-Amz-Signature")
  valid_602602 = validateParameter(valid_602602, JString, required = false,
                                 default = nil)
  if valid_602602 != nil:
    section.add "X-Amz-Signature", valid_602602
  var valid_602603 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602603 = validateParameter(valid_602603, JString, required = false,
                                 default = nil)
  if valid_602603 != nil:
    section.add "X-Amz-SignedHeaders", valid_602603
  var valid_602604 = header.getOrDefault("X-Amz-Credential")
  valid_602604 = validateParameter(valid_602604, JString, required = false,
                                 default = nil)
  if valid_602604 != nil:
    section.add "X-Amz-Credential", valid_602604
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
  var valid_602605 = formData.getOrDefault("OptionsToRemove")
  valid_602605 = validateParameter(valid_602605, JArray, required = false,
                                 default = nil)
  if valid_602605 != nil:
    section.add "OptionsToRemove", valid_602605
  var valid_602606 = formData.getOrDefault("OptionSettings")
  valid_602606 = validateParameter(valid_602606, JArray, required = false,
                                 default = nil)
  if valid_602606 != nil:
    section.add "OptionSettings", valid_602606
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_602607 = formData.getOrDefault("ApplicationName")
  valid_602607 = validateParameter(valid_602607, JString, required = true,
                                 default = nil)
  if valid_602607 != nil:
    section.add "ApplicationName", valid_602607
  var valid_602608 = formData.getOrDefault("TemplateName")
  valid_602608 = validateParameter(valid_602608, JString, required = true,
                                 default = nil)
  if valid_602608 != nil:
    section.add "TemplateName", valid_602608
  var valid_602609 = formData.getOrDefault("Description")
  valid_602609 = validateParameter(valid_602609, JString, required = false,
                                 default = nil)
  if valid_602609 != nil:
    section.add "Description", valid_602609
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602610: Call_PostUpdateConfigurationTemplate_602593;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Updates the specified configuration template to have the specified properties or configuration option values.</p> <note> <p>If a property (for example, <code>ApplicationName</code>) is not provided, its value remains unchanged. To clear such properties, specify an empty string.</p> </note> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> </ul>
  ## 
  let valid = call_602610.validator(path, query, header, formData, body)
  let scheme = call_602610.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602610.url(scheme.get, call_602610.host, call_602610.base,
                         call_602610.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602610, url, valid)

proc call*(call_602611: Call_PostUpdateConfigurationTemplate_602593;
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
  var query_602612 = newJObject()
  var formData_602613 = newJObject()
  if OptionsToRemove != nil:
    formData_602613.add "OptionsToRemove", OptionsToRemove
  if OptionSettings != nil:
    formData_602613.add "OptionSettings", OptionSettings
  add(query_602612, "Action", newJString(Action))
  add(formData_602613, "ApplicationName", newJString(ApplicationName))
  add(formData_602613, "TemplateName", newJString(TemplateName))
  add(query_602612, "Version", newJString(Version))
  add(formData_602613, "Description", newJString(Description))
  result = call_602611.call(nil, query_602612, nil, formData_602613, nil)

var postUpdateConfigurationTemplate* = Call_PostUpdateConfigurationTemplate_602593(
    name: "postUpdateConfigurationTemplate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateConfigurationTemplate",
    validator: validate_PostUpdateConfigurationTemplate_602594, base: "/",
    url: url_PostUpdateConfigurationTemplate_602595,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateConfigurationTemplate_602573 = ref object of OpenApiRestCall_600438
proc url_GetUpdateConfigurationTemplate_602575(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateConfigurationTemplate_602574(path: JsonNode;
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
  var valid_602576 = query.getOrDefault("ApplicationName")
  valid_602576 = validateParameter(valid_602576, JString, required = true,
                                 default = nil)
  if valid_602576 != nil:
    section.add "ApplicationName", valid_602576
  var valid_602577 = query.getOrDefault("Description")
  valid_602577 = validateParameter(valid_602577, JString, required = false,
                                 default = nil)
  if valid_602577 != nil:
    section.add "Description", valid_602577
  var valid_602578 = query.getOrDefault("OptionsToRemove")
  valid_602578 = validateParameter(valid_602578, JArray, required = false,
                                 default = nil)
  if valid_602578 != nil:
    section.add "OptionsToRemove", valid_602578
  var valid_602579 = query.getOrDefault("Action")
  valid_602579 = validateParameter(valid_602579, JString, required = true, default = newJString(
      "UpdateConfigurationTemplate"))
  if valid_602579 != nil:
    section.add "Action", valid_602579
  var valid_602580 = query.getOrDefault("TemplateName")
  valid_602580 = validateParameter(valid_602580, JString, required = true,
                                 default = nil)
  if valid_602580 != nil:
    section.add "TemplateName", valid_602580
  var valid_602581 = query.getOrDefault("OptionSettings")
  valid_602581 = validateParameter(valid_602581, JArray, required = false,
                                 default = nil)
  if valid_602581 != nil:
    section.add "OptionSettings", valid_602581
  var valid_602582 = query.getOrDefault("Version")
  valid_602582 = validateParameter(valid_602582, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602582 != nil:
    section.add "Version", valid_602582
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602583 = header.getOrDefault("X-Amz-Date")
  valid_602583 = validateParameter(valid_602583, JString, required = false,
                                 default = nil)
  if valid_602583 != nil:
    section.add "X-Amz-Date", valid_602583
  var valid_602584 = header.getOrDefault("X-Amz-Security-Token")
  valid_602584 = validateParameter(valid_602584, JString, required = false,
                                 default = nil)
  if valid_602584 != nil:
    section.add "X-Amz-Security-Token", valid_602584
  var valid_602585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602585 = validateParameter(valid_602585, JString, required = false,
                                 default = nil)
  if valid_602585 != nil:
    section.add "X-Amz-Content-Sha256", valid_602585
  var valid_602586 = header.getOrDefault("X-Amz-Algorithm")
  valid_602586 = validateParameter(valid_602586, JString, required = false,
                                 default = nil)
  if valid_602586 != nil:
    section.add "X-Amz-Algorithm", valid_602586
  var valid_602587 = header.getOrDefault("X-Amz-Signature")
  valid_602587 = validateParameter(valid_602587, JString, required = false,
                                 default = nil)
  if valid_602587 != nil:
    section.add "X-Amz-Signature", valid_602587
  var valid_602588 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602588 = validateParameter(valid_602588, JString, required = false,
                                 default = nil)
  if valid_602588 != nil:
    section.add "X-Amz-SignedHeaders", valid_602588
  var valid_602589 = header.getOrDefault("X-Amz-Credential")
  valid_602589 = validateParameter(valid_602589, JString, required = false,
                                 default = nil)
  if valid_602589 != nil:
    section.add "X-Amz-Credential", valid_602589
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602590: Call_GetUpdateConfigurationTemplate_602573; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified configuration template to have the specified properties or configuration option values.</p> <note> <p>If a property (for example, <code>ApplicationName</code>) is not provided, its value remains unchanged. To clear such properties, specify an empty string.</p> </note> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> </ul>
  ## 
  let valid = call_602590.validator(path, query, header, formData, body)
  let scheme = call_602590.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602590.url(scheme.get, call_602590.host, call_602590.base,
                         call_602590.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602590, url, valid)

proc call*(call_602591: Call_GetUpdateConfigurationTemplate_602573;
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
  var query_602592 = newJObject()
  add(query_602592, "ApplicationName", newJString(ApplicationName))
  add(query_602592, "Description", newJString(Description))
  if OptionsToRemove != nil:
    query_602592.add "OptionsToRemove", OptionsToRemove
  add(query_602592, "Action", newJString(Action))
  add(query_602592, "TemplateName", newJString(TemplateName))
  if OptionSettings != nil:
    query_602592.add "OptionSettings", OptionSettings
  add(query_602592, "Version", newJString(Version))
  result = call_602591.call(nil, query_602592, nil, nil, nil)

var getUpdateConfigurationTemplate* = Call_GetUpdateConfigurationTemplate_602573(
    name: "getUpdateConfigurationTemplate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateConfigurationTemplate",
    validator: validate_GetUpdateConfigurationTemplate_602574, base: "/",
    url: url_GetUpdateConfigurationTemplate_602575,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateEnvironment_602643 = ref object of OpenApiRestCall_600438
proc url_PostUpdateEnvironment_602645(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateEnvironment_602644(path: JsonNode; query: JsonNode;
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
  var valid_602646 = query.getOrDefault("Action")
  valid_602646 = validateParameter(valid_602646, JString, required = true,
                                 default = newJString("UpdateEnvironment"))
  if valid_602646 != nil:
    section.add "Action", valid_602646
  var valid_602647 = query.getOrDefault("Version")
  valid_602647 = validateParameter(valid_602647, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602647 != nil:
    section.add "Version", valid_602647
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602648 = header.getOrDefault("X-Amz-Date")
  valid_602648 = validateParameter(valid_602648, JString, required = false,
                                 default = nil)
  if valid_602648 != nil:
    section.add "X-Amz-Date", valid_602648
  var valid_602649 = header.getOrDefault("X-Amz-Security-Token")
  valid_602649 = validateParameter(valid_602649, JString, required = false,
                                 default = nil)
  if valid_602649 != nil:
    section.add "X-Amz-Security-Token", valid_602649
  var valid_602650 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602650 = validateParameter(valid_602650, JString, required = false,
                                 default = nil)
  if valid_602650 != nil:
    section.add "X-Amz-Content-Sha256", valid_602650
  var valid_602651 = header.getOrDefault("X-Amz-Algorithm")
  valid_602651 = validateParameter(valid_602651, JString, required = false,
                                 default = nil)
  if valid_602651 != nil:
    section.add "X-Amz-Algorithm", valid_602651
  var valid_602652 = header.getOrDefault("X-Amz-Signature")
  valid_602652 = validateParameter(valid_602652, JString, required = false,
                                 default = nil)
  if valid_602652 != nil:
    section.add "X-Amz-Signature", valid_602652
  var valid_602653 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602653 = validateParameter(valid_602653, JString, required = false,
                                 default = nil)
  if valid_602653 != nil:
    section.add "X-Amz-SignedHeaders", valid_602653
  var valid_602654 = header.getOrDefault("X-Amz-Credential")
  valid_602654 = validateParameter(valid_602654, JString, required = false,
                                 default = nil)
  if valid_602654 != nil:
    section.add "X-Amz-Credential", valid_602654
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
  var valid_602655 = formData.getOrDefault("Tier.Name")
  valid_602655 = validateParameter(valid_602655, JString, required = false,
                                 default = nil)
  if valid_602655 != nil:
    section.add "Tier.Name", valid_602655
  var valid_602656 = formData.getOrDefault("OptionsToRemove")
  valid_602656 = validateParameter(valid_602656, JArray, required = false,
                                 default = nil)
  if valid_602656 != nil:
    section.add "OptionsToRemove", valid_602656
  var valid_602657 = formData.getOrDefault("VersionLabel")
  valid_602657 = validateParameter(valid_602657, JString, required = false,
                                 default = nil)
  if valid_602657 != nil:
    section.add "VersionLabel", valid_602657
  var valid_602658 = formData.getOrDefault("OptionSettings")
  valid_602658 = validateParameter(valid_602658, JArray, required = false,
                                 default = nil)
  if valid_602658 != nil:
    section.add "OptionSettings", valid_602658
  var valid_602659 = formData.getOrDefault("GroupName")
  valid_602659 = validateParameter(valid_602659, JString, required = false,
                                 default = nil)
  if valid_602659 != nil:
    section.add "GroupName", valid_602659
  var valid_602660 = formData.getOrDefault("SolutionStackName")
  valid_602660 = validateParameter(valid_602660, JString, required = false,
                                 default = nil)
  if valid_602660 != nil:
    section.add "SolutionStackName", valid_602660
  var valid_602661 = formData.getOrDefault("EnvironmentId")
  valid_602661 = validateParameter(valid_602661, JString, required = false,
                                 default = nil)
  if valid_602661 != nil:
    section.add "EnvironmentId", valid_602661
  var valid_602662 = formData.getOrDefault("EnvironmentName")
  valid_602662 = validateParameter(valid_602662, JString, required = false,
                                 default = nil)
  if valid_602662 != nil:
    section.add "EnvironmentName", valid_602662
  var valid_602663 = formData.getOrDefault("Tier.Type")
  valid_602663 = validateParameter(valid_602663, JString, required = false,
                                 default = nil)
  if valid_602663 != nil:
    section.add "Tier.Type", valid_602663
  var valid_602664 = formData.getOrDefault("ApplicationName")
  valid_602664 = validateParameter(valid_602664, JString, required = false,
                                 default = nil)
  if valid_602664 != nil:
    section.add "ApplicationName", valid_602664
  var valid_602665 = formData.getOrDefault("PlatformArn")
  valid_602665 = validateParameter(valid_602665, JString, required = false,
                                 default = nil)
  if valid_602665 != nil:
    section.add "PlatformArn", valid_602665
  var valid_602666 = formData.getOrDefault("TemplateName")
  valid_602666 = validateParameter(valid_602666, JString, required = false,
                                 default = nil)
  if valid_602666 != nil:
    section.add "TemplateName", valid_602666
  var valid_602667 = formData.getOrDefault("Description")
  valid_602667 = validateParameter(valid_602667, JString, required = false,
                                 default = nil)
  if valid_602667 != nil:
    section.add "Description", valid_602667
  var valid_602668 = formData.getOrDefault("Tier.Version")
  valid_602668 = validateParameter(valid_602668, JString, required = false,
                                 default = nil)
  if valid_602668 != nil:
    section.add "Tier.Version", valid_602668
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602669: Call_PostUpdateEnvironment_602643; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the environment description, deploys a new application version, updates the configuration settings to an entirely new configuration template, or updates select configuration option values in the running environment.</p> <p> Attempting to update both the release and configuration is not allowed and AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. </p> <p> When updating the configuration settings to a new template or individual settings, a draft configuration is created and <a>DescribeConfigurationSettings</a> for this environment returns two setting descriptions with different <code>DeploymentStatus</code> values. </p>
  ## 
  let valid = call_602669.validator(path, query, header, formData, body)
  let scheme = call_602669.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602669.url(scheme.get, call_602669.host, call_602669.base,
                         call_602669.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602669, url, valid)

proc call*(call_602670: Call_PostUpdateEnvironment_602643; TierName: string = "";
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
  var query_602671 = newJObject()
  var formData_602672 = newJObject()
  add(formData_602672, "Tier.Name", newJString(TierName))
  if OptionsToRemove != nil:
    formData_602672.add "OptionsToRemove", OptionsToRemove
  add(formData_602672, "VersionLabel", newJString(VersionLabel))
  if OptionSettings != nil:
    formData_602672.add "OptionSettings", OptionSettings
  add(formData_602672, "GroupName", newJString(GroupName))
  add(formData_602672, "SolutionStackName", newJString(SolutionStackName))
  add(formData_602672, "EnvironmentId", newJString(EnvironmentId))
  add(formData_602672, "EnvironmentName", newJString(EnvironmentName))
  add(formData_602672, "Tier.Type", newJString(TierType))
  add(query_602671, "Action", newJString(Action))
  add(formData_602672, "ApplicationName", newJString(ApplicationName))
  add(formData_602672, "PlatformArn", newJString(PlatformArn))
  add(formData_602672, "TemplateName", newJString(TemplateName))
  add(query_602671, "Version", newJString(Version))
  add(formData_602672, "Description", newJString(Description))
  add(formData_602672, "Tier.Version", newJString(TierVersion))
  result = call_602670.call(nil, query_602671, nil, formData_602672, nil)

var postUpdateEnvironment* = Call_PostUpdateEnvironment_602643(
    name: "postUpdateEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateEnvironment",
    validator: validate_PostUpdateEnvironment_602644, base: "/",
    url: url_PostUpdateEnvironment_602645, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateEnvironment_602614 = ref object of OpenApiRestCall_600438
proc url_GetUpdateEnvironment_602616(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateEnvironment_602615(path: JsonNode; query: JsonNode;
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
  var valid_602617 = query.getOrDefault("Tier.Name")
  valid_602617 = validateParameter(valid_602617, JString, required = false,
                                 default = nil)
  if valid_602617 != nil:
    section.add "Tier.Name", valid_602617
  var valid_602618 = query.getOrDefault("VersionLabel")
  valid_602618 = validateParameter(valid_602618, JString, required = false,
                                 default = nil)
  if valid_602618 != nil:
    section.add "VersionLabel", valid_602618
  var valid_602619 = query.getOrDefault("ApplicationName")
  valid_602619 = validateParameter(valid_602619, JString, required = false,
                                 default = nil)
  if valid_602619 != nil:
    section.add "ApplicationName", valid_602619
  var valid_602620 = query.getOrDefault("Description")
  valid_602620 = validateParameter(valid_602620, JString, required = false,
                                 default = nil)
  if valid_602620 != nil:
    section.add "Description", valid_602620
  var valid_602621 = query.getOrDefault("OptionsToRemove")
  valid_602621 = validateParameter(valid_602621, JArray, required = false,
                                 default = nil)
  if valid_602621 != nil:
    section.add "OptionsToRemove", valid_602621
  var valid_602622 = query.getOrDefault("PlatformArn")
  valid_602622 = validateParameter(valid_602622, JString, required = false,
                                 default = nil)
  if valid_602622 != nil:
    section.add "PlatformArn", valid_602622
  var valid_602623 = query.getOrDefault("EnvironmentName")
  valid_602623 = validateParameter(valid_602623, JString, required = false,
                                 default = nil)
  if valid_602623 != nil:
    section.add "EnvironmentName", valid_602623
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602624 = query.getOrDefault("Action")
  valid_602624 = validateParameter(valid_602624, JString, required = true,
                                 default = newJString("UpdateEnvironment"))
  if valid_602624 != nil:
    section.add "Action", valid_602624
  var valid_602625 = query.getOrDefault("EnvironmentId")
  valid_602625 = validateParameter(valid_602625, JString, required = false,
                                 default = nil)
  if valid_602625 != nil:
    section.add "EnvironmentId", valid_602625
  var valid_602626 = query.getOrDefault("Tier.Version")
  valid_602626 = validateParameter(valid_602626, JString, required = false,
                                 default = nil)
  if valid_602626 != nil:
    section.add "Tier.Version", valid_602626
  var valid_602627 = query.getOrDefault("SolutionStackName")
  valid_602627 = validateParameter(valid_602627, JString, required = false,
                                 default = nil)
  if valid_602627 != nil:
    section.add "SolutionStackName", valid_602627
  var valid_602628 = query.getOrDefault("TemplateName")
  valid_602628 = validateParameter(valid_602628, JString, required = false,
                                 default = nil)
  if valid_602628 != nil:
    section.add "TemplateName", valid_602628
  var valid_602629 = query.getOrDefault("GroupName")
  valid_602629 = validateParameter(valid_602629, JString, required = false,
                                 default = nil)
  if valid_602629 != nil:
    section.add "GroupName", valid_602629
  var valid_602630 = query.getOrDefault("OptionSettings")
  valid_602630 = validateParameter(valid_602630, JArray, required = false,
                                 default = nil)
  if valid_602630 != nil:
    section.add "OptionSettings", valid_602630
  var valid_602631 = query.getOrDefault("Tier.Type")
  valid_602631 = validateParameter(valid_602631, JString, required = false,
                                 default = nil)
  if valid_602631 != nil:
    section.add "Tier.Type", valid_602631
  var valid_602632 = query.getOrDefault("Version")
  valid_602632 = validateParameter(valid_602632, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602632 != nil:
    section.add "Version", valid_602632
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602633 = header.getOrDefault("X-Amz-Date")
  valid_602633 = validateParameter(valid_602633, JString, required = false,
                                 default = nil)
  if valid_602633 != nil:
    section.add "X-Amz-Date", valid_602633
  var valid_602634 = header.getOrDefault("X-Amz-Security-Token")
  valid_602634 = validateParameter(valid_602634, JString, required = false,
                                 default = nil)
  if valid_602634 != nil:
    section.add "X-Amz-Security-Token", valid_602634
  var valid_602635 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602635 = validateParameter(valid_602635, JString, required = false,
                                 default = nil)
  if valid_602635 != nil:
    section.add "X-Amz-Content-Sha256", valid_602635
  var valid_602636 = header.getOrDefault("X-Amz-Algorithm")
  valid_602636 = validateParameter(valid_602636, JString, required = false,
                                 default = nil)
  if valid_602636 != nil:
    section.add "X-Amz-Algorithm", valid_602636
  var valid_602637 = header.getOrDefault("X-Amz-Signature")
  valid_602637 = validateParameter(valid_602637, JString, required = false,
                                 default = nil)
  if valid_602637 != nil:
    section.add "X-Amz-Signature", valid_602637
  var valid_602638 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602638 = validateParameter(valid_602638, JString, required = false,
                                 default = nil)
  if valid_602638 != nil:
    section.add "X-Amz-SignedHeaders", valid_602638
  var valid_602639 = header.getOrDefault("X-Amz-Credential")
  valid_602639 = validateParameter(valid_602639, JString, required = false,
                                 default = nil)
  if valid_602639 != nil:
    section.add "X-Amz-Credential", valid_602639
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602640: Call_GetUpdateEnvironment_602614; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the environment description, deploys a new application version, updates the configuration settings to an entirely new configuration template, or updates select configuration option values in the running environment.</p> <p> Attempting to update both the release and configuration is not allowed and AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. </p> <p> When updating the configuration settings to a new template or individual settings, a draft configuration is created and <a>DescribeConfigurationSettings</a> for this environment returns two setting descriptions with different <code>DeploymentStatus</code> values. </p>
  ## 
  let valid = call_602640.validator(path, query, header, formData, body)
  let scheme = call_602640.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602640.url(scheme.get, call_602640.host, call_602640.base,
                         call_602640.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602640, url, valid)

proc call*(call_602641: Call_GetUpdateEnvironment_602614; TierName: string = "";
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
  var query_602642 = newJObject()
  add(query_602642, "Tier.Name", newJString(TierName))
  add(query_602642, "VersionLabel", newJString(VersionLabel))
  add(query_602642, "ApplicationName", newJString(ApplicationName))
  add(query_602642, "Description", newJString(Description))
  if OptionsToRemove != nil:
    query_602642.add "OptionsToRemove", OptionsToRemove
  add(query_602642, "PlatformArn", newJString(PlatformArn))
  add(query_602642, "EnvironmentName", newJString(EnvironmentName))
  add(query_602642, "Action", newJString(Action))
  add(query_602642, "EnvironmentId", newJString(EnvironmentId))
  add(query_602642, "Tier.Version", newJString(TierVersion))
  add(query_602642, "SolutionStackName", newJString(SolutionStackName))
  add(query_602642, "TemplateName", newJString(TemplateName))
  add(query_602642, "GroupName", newJString(GroupName))
  if OptionSettings != nil:
    query_602642.add "OptionSettings", OptionSettings
  add(query_602642, "Tier.Type", newJString(TierType))
  add(query_602642, "Version", newJString(Version))
  result = call_602641.call(nil, query_602642, nil, nil, nil)

var getUpdateEnvironment* = Call_GetUpdateEnvironment_602614(
    name: "getUpdateEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateEnvironment",
    validator: validate_GetUpdateEnvironment_602615, base: "/",
    url: url_GetUpdateEnvironment_602616, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateTagsForResource_602691 = ref object of OpenApiRestCall_600438
proc url_PostUpdateTagsForResource_602693(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateTagsForResource_602692(path: JsonNode; query: JsonNode;
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
  var valid_602694 = query.getOrDefault("Action")
  valid_602694 = validateParameter(valid_602694, JString, required = true,
                                 default = newJString("UpdateTagsForResource"))
  if valid_602694 != nil:
    section.add "Action", valid_602694
  var valid_602695 = query.getOrDefault("Version")
  valid_602695 = validateParameter(valid_602695, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602695 != nil:
    section.add "Version", valid_602695
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602696 = header.getOrDefault("X-Amz-Date")
  valid_602696 = validateParameter(valid_602696, JString, required = false,
                                 default = nil)
  if valid_602696 != nil:
    section.add "X-Amz-Date", valid_602696
  var valid_602697 = header.getOrDefault("X-Amz-Security-Token")
  valid_602697 = validateParameter(valid_602697, JString, required = false,
                                 default = nil)
  if valid_602697 != nil:
    section.add "X-Amz-Security-Token", valid_602697
  var valid_602698 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602698 = validateParameter(valid_602698, JString, required = false,
                                 default = nil)
  if valid_602698 != nil:
    section.add "X-Amz-Content-Sha256", valid_602698
  var valid_602699 = header.getOrDefault("X-Amz-Algorithm")
  valid_602699 = validateParameter(valid_602699, JString, required = false,
                                 default = nil)
  if valid_602699 != nil:
    section.add "X-Amz-Algorithm", valid_602699
  var valid_602700 = header.getOrDefault("X-Amz-Signature")
  valid_602700 = validateParameter(valid_602700, JString, required = false,
                                 default = nil)
  if valid_602700 != nil:
    section.add "X-Amz-Signature", valid_602700
  var valid_602701 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602701 = validateParameter(valid_602701, JString, required = false,
                                 default = nil)
  if valid_602701 != nil:
    section.add "X-Amz-SignedHeaders", valid_602701
  var valid_602702 = header.getOrDefault("X-Amz-Credential")
  valid_602702 = validateParameter(valid_602702, JString, required = false,
                                 default = nil)
  if valid_602702 != nil:
    section.add "X-Amz-Credential", valid_602702
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagsToAdd: JArray
  ##            : <p>A list of tags to add or update.</p> <p>If a key of an existing tag is added, the tag's value is updated.</p>
  ##   TagsToRemove: JArray
  ##               : <p>A list of tag keys to remove.</p> <p>If a tag key doesn't exist, it is silently ignored.</p>
  ##   ResourceArn: JString (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce to be updated.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  section = newJObject()
  var valid_602703 = formData.getOrDefault("TagsToAdd")
  valid_602703 = validateParameter(valid_602703, JArray, required = false,
                                 default = nil)
  if valid_602703 != nil:
    section.add "TagsToAdd", valid_602703
  var valid_602704 = formData.getOrDefault("TagsToRemove")
  valid_602704 = validateParameter(valid_602704, JArray, required = false,
                                 default = nil)
  if valid_602704 != nil:
    section.add "TagsToRemove", valid_602704
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArn` field"
  var valid_602705 = formData.getOrDefault("ResourceArn")
  valid_602705 = validateParameter(valid_602705, JString, required = true,
                                 default = nil)
  if valid_602705 != nil:
    section.add "ResourceArn", valid_602705
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602706: Call_PostUpdateTagsForResource_602691; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Update the list of tags applied to an AWS Elastic Beanstalk resource. Two lists can be passed: <code>TagsToAdd</code> for tags to add or update, and <code>TagsToRemove</code>.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p> <p>If you create a custom IAM user policy to control permission to this operation, specify one of the following two virtual actions (or both) instead of the API operation name:</p> <dl> <dt>elasticbeanstalk:AddTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tags to add in the <code>TagsToAdd</code> parameter.</p> </dd> <dt>elasticbeanstalk:RemoveTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tag keys to remove in the <code>TagsToRemove</code> parameter.</p> </dd> </dl> <p>For details about creating a custom user policy, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/AWSHowTo.iam.managed-policies.html#AWSHowTo.iam.policies">Creating a Custom User Policy</a>.</p>
  ## 
  let valid = call_602706.validator(path, query, header, formData, body)
  let scheme = call_602706.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602706.url(scheme.get, call_602706.host, call_602706.base,
                         call_602706.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602706, url, valid)

proc call*(call_602707: Call_PostUpdateTagsForResource_602691; ResourceArn: string;
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
  var query_602708 = newJObject()
  var formData_602709 = newJObject()
  if TagsToAdd != nil:
    formData_602709.add "TagsToAdd", TagsToAdd
  if TagsToRemove != nil:
    formData_602709.add "TagsToRemove", TagsToRemove
  add(query_602708, "Action", newJString(Action))
  add(formData_602709, "ResourceArn", newJString(ResourceArn))
  add(query_602708, "Version", newJString(Version))
  result = call_602707.call(nil, query_602708, nil, formData_602709, nil)

var postUpdateTagsForResource* = Call_PostUpdateTagsForResource_602691(
    name: "postUpdateTagsForResource", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateTagsForResource",
    validator: validate_PostUpdateTagsForResource_602692, base: "/",
    url: url_PostUpdateTagsForResource_602693,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateTagsForResource_602673 = ref object of OpenApiRestCall_600438
proc url_GetUpdateTagsForResource_602675(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateTagsForResource_602674(path: JsonNode; query: JsonNode;
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
  var valid_602676 = query.getOrDefault("ResourceArn")
  valid_602676 = validateParameter(valid_602676, JString, required = true,
                                 default = nil)
  if valid_602676 != nil:
    section.add "ResourceArn", valid_602676
  var valid_602677 = query.getOrDefault("Action")
  valid_602677 = validateParameter(valid_602677, JString, required = true,
                                 default = newJString("UpdateTagsForResource"))
  if valid_602677 != nil:
    section.add "Action", valid_602677
  var valid_602678 = query.getOrDefault("TagsToAdd")
  valid_602678 = validateParameter(valid_602678, JArray, required = false,
                                 default = nil)
  if valid_602678 != nil:
    section.add "TagsToAdd", valid_602678
  var valid_602679 = query.getOrDefault("Version")
  valid_602679 = validateParameter(valid_602679, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602679 != nil:
    section.add "Version", valid_602679
  var valid_602680 = query.getOrDefault("TagsToRemove")
  valid_602680 = validateParameter(valid_602680, JArray, required = false,
                                 default = nil)
  if valid_602680 != nil:
    section.add "TagsToRemove", valid_602680
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602681 = header.getOrDefault("X-Amz-Date")
  valid_602681 = validateParameter(valid_602681, JString, required = false,
                                 default = nil)
  if valid_602681 != nil:
    section.add "X-Amz-Date", valid_602681
  var valid_602682 = header.getOrDefault("X-Amz-Security-Token")
  valid_602682 = validateParameter(valid_602682, JString, required = false,
                                 default = nil)
  if valid_602682 != nil:
    section.add "X-Amz-Security-Token", valid_602682
  var valid_602683 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602683 = validateParameter(valid_602683, JString, required = false,
                                 default = nil)
  if valid_602683 != nil:
    section.add "X-Amz-Content-Sha256", valid_602683
  var valid_602684 = header.getOrDefault("X-Amz-Algorithm")
  valid_602684 = validateParameter(valid_602684, JString, required = false,
                                 default = nil)
  if valid_602684 != nil:
    section.add "X-Amz-Algorithm", valid_602684
  var valid_602685 = header.getOrDefault("X-Amz-Signature")
  valid_602685 = validateParameter(valid_602685, JString, required = false,
                                 default = nil)
  if valid_602685 != nil:
    section.add "X-Amz-Signature", valid_602685
  var valid_602686 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602686 = validateParameter(valid_602686, JString, required = false,
                                 default = nil)
  if valid_602686 != nil:
    section.add "X-Amz-SignedHeaders", valid_602686
  var valid_602687 = header.getOrDefault("X-Amz-Credential")
  valid_602687 = validateParameter(valid_602687, JString, required = false,
                                 default = nil)
  if valid_602687 != nil:
    section.add "X-Amz-Credential", valid_602687
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602688: Call_GetUpdateTagsForResource_602673; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Update the list of tags applied to an AWS Elastic Beanstalk resource. Two lists can be passed: <code>TagsToAdd</code> for tags to add or update, and <code>TagsToRemove</code>.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p> <p>If you create a custom IAM user policy to control permission to this operation, specify one of the following two virtual actions (or both) instead of the API operation name:</p> <dl> <dt>elasticbeanstalk:AddTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tags to add in the <code>TagsToAdd</code> parameter.</p> </dd> <dt>elasticbeanstalk:RemoveTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tag keys to remove in the <code>TagsToRemove</code> parameter.</p> </dd> </dl> <p>For details about creating a custom user policy, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/AWSHowTo.iam.managed-policies.html#AWSHowTo.iam.policies">Creating a Custom User Policy</a>.</p>
  ## 
  let valid = call_602688.validator(path, query, header, formData, body)
  let scheme = call_602688.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602688.url(scheme.get, call_602688.host, call_602688.base,
                         call_602688.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602688, url, valid)

proc call*(call_602689: Call_GetUpdateTagsForResource_602673; ResourceArn: string;
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
  var query_602690 = newJObject()
  add(query_602690, "ResourceArn", newJString(ResourceArn))
  add(query_602690, "Action", newJString(Action))
  if TagsToAdd != nil:
    query_602690.add "TagsToAdd", TagsToAdd
  add(query_602690, "Version", newJString(Version))
  if TagsToRemove != nil:
    query_602690.add "TagsToRemove", TagsToRemove
  result = call_602689.call(nil, query_602690, nil, nil, nil)

var getUpdateTagsForResource* = Call_GetUpdateTagsForResource_602673(
    name: "getUpdateTagsForResource", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateTagsForResource",
    validator: validate_GetUpdateTagsForResource_602674, base: "/",
    url: url_GetUpdateTagsForResource_602675, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostValidateConfigurationSettings_602729 = ref object of OpenApiRestCall_600438
proc url_PostValidateConfigurationSettings_602731(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostValidateConfigurationSettings_602730(path: JsonNode;
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
  var valid_602732 = query.getOrDefault("Action")
  valid_602732 = validateParameter(valid_602732, JString, required = true, default = newJString(
      "ValidateConfigurationSettings"))
  if valid_602732 != nil:
    section.add "Action", valid_602732
  var valid_602733 = query.getOrDefault("Version")
  valid_602733 = validateParameter(valid_602733, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602733 != nil:
    section.add "Version", valid_602733
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602734 = header.getOrDefault("X-Amz-Date")
  valid_602734 = validateParameter(valid_602734, JString, required = false,
                                 default = nil)
  if valid_602734 != nil:
    section.add "X-Amz-Date", valid_602734
  var valid_602735 = header.getOrDefault("X-Amz-Security-Token")
  valid_602735 = validateParameter(valid_602735, JString, required = false,
                                 default = nil)
  if valid_602735 != nil:
    section.add "X-Amz-Security-Token", valid_602735
  var valid_602736 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602736 = validateParameter(valid_602736, JString, required = false,
                                 default = nil)
  if valid_602736 != nil:
    section.add "X-Amz-Content-Sha256", valid_602736
  var valid_602737 = header.getOrDefault("X-Amz-Algorithm")
  valid_602737 = validateParameter(valid_602737, JString, required = false,
                                 default = nil)
  if valid_602737 != nil:
    section.add "X-Amz-Algorithm", valid_602737
  var valid_602738 = header.getOrDefault("X-Amz-Signature")
  valid_602738 = validateParameter(valid_602738, JString, required = false,
                                 default = nil)
  if valid_602738 != nil:
    section.add "X-Amz-Signature", valid_602738
  var valid_602739 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602739 = validateParameter(valid_602739, JString, required = false,
                                 default = nil)
  if valid_602739 != nil:
    section.add "X-Amz-SignedHeaders", valid_602739
  var valid_602740 = header.getOrDefault("X-Amz-Credential")
  valid_602740 = validateParameter(valid_602740, JString, required = false,
                                 default = nil)
  if valid_602740 != nil:
    section.add "X-Amz-Credential", valid_602740
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
  var valid_602741 = formData.getOrDefault("OptionSettings")
  valid_602741 = validateParameter(valid_602741, JArray, required = true, default = nil)
  if valid_602741 != nil:
    section.add "OptionSettings", valid_602741
  var valid_602742 = formData.getOrDefault("EnvironmentName")
  valid_602742 = validateParameter(valid_602742, JString, required = false,
                                 default = nil)
  if valid_602742 != nil:
    section.add "EnvironmentName", valid_602742
  var valid_602743 = formData.getOrDefault("ApplicationName")
  valid_602743 = validateParameter(valid_602743, JString, required = true,
                                 default = nil)
  if valid_602743 != nil:
    section.add "ApplicationName", valid_602743
  var valid_602744 = formData.getOrDefault("TemplateName")
  valid_602744 = validateParameter(valid_602744, JString, required = false,
                                 default = nil)
  if valid_602744 != nil:
    section.add "TemplateName", valid_602744
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602745: Call_PostValidateConfigurationSettings_602729;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Takes a set of configuration settings and either a configuration template or environment, and determines whether those values are valid.</p> <p>This action returns a list of messages indicating any errors or warnings associated with the selection of option values.</p>
  ## 
  let valid = call_602745.validator(path, query, header, formData, body)
  let scheme = call_602745.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602745.url(scheme.get, call_602745.host, call_602745.base,
                         call_602745.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602745, url, valid)

proc call*(call_602746: Call_PostValidateConfigurationSettings_602729;
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
  var query_602747 = newJObject()
  var formData_602748 = newJObject()
  if OptionSettings != nil:
    formData_602748.add "OptionSettings", OptionSettings
  add(formData_602748, "EnvironmentName", newJString(EnvironmentName))
  add(query_602747, "Action", newJString(Action))
  add(formData_602748, "ApplicationName", newJString(ApplicationName))
  add(formData_602748, "TemplateName", newJString(TemplateName))
  add(query_602747, "Version", newJString(Version))
  result = call_602746.call(nil, query_602747, nil, formData_602748, nil)

var postValidateConfigurationSettings* = Call_PostValidateConfigurationSettings_602729(
    name: "postValidateConfigurationSettings", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ValidateConfigurationSettings",
    validator: validate_PostValidateConfigurationSettings_602730, base: "/",
    url: url_PostValidateConfigurationSettings_602731,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetValidateConfigurationSettings_602710 = ref object of OpenApiRestCall_600438
proc url_GetValidateConfigurationSettings_602712(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetValidateConfigurationSettings_602711(path: JsonNode;
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
  var valid_602713 = query.getOrDefault("ApplicationName")
  valid_602713 = validateParameter(valid_602713, JString, required = true,
                                 default = nil)
  if valid_602713 != nil:
    section.add "ApplicationName", valid_602713
  var valid_602714 = query.getOrDefault("EnvironmentName")
  valid_602714 = validateParameter(valid_602714, JString, required = false,
                                 default = nil)
  if valid_602714 != nil:
    section.add "EnvironmentName", valid_602714
  var valid_602715 = query.getOrDefault("Action")
  valid_602715 = validateParameter(valid_602715, JString, required = true, default = newJString(
      "ValidateConfigurationSettings"))
  if valid_602715 != nil:
    section.add "Action", valid_602715
  var valid_602716 = query.getOrDefault("TemplateName")
  valid_602716 = validateParameter(valid_602716, JString, required = false,
                                 default = nil)
  if valid_602716 != nil:
    section.add "TemplateName", valid_602716
  var valid_602717 = query.getOrDefault("OptionSettings")
  valid_602717 = validateParameter(valid_602717, JArray, required = true, default = nil)
  if valid_602717 != nil:
    section.add "OptionSettings", valid_602717
  var valid_602718 = query.getOrDefault("Version")
  valid_602718 = validateParameter(valid_602718, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602718 != nil:
    section.add "Version", valid_602718
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602719 = header.getOrDefault("X-Amz-Date")
  valid_602719 = validateParameter(valid_602719, JString, required = false,
                                 default = nil)
  if valid_602719 != nil:
    section.add "X-Amz-Date", valid_602719
  var valid_602720 = header.getOrDefault("X-Amz-Security-Token")
  valid_602720 = validateParameter(valid_602720, JString, required = false,
                                 default = nil)
  if valid_602720 != nil:
    section.add "X-Amz-Security-Token", valid_602720
  var valid_602721 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602721 = validateParameter(valid_602721, JString, required = false,
                                 default = nil)
  if valid_602721 != nil:
    section.add "X-Amz-Content-Sha256", valid_602721
  var valid_602722 = header.getOrDefault("X-Amz-Algorithm")
  valid_602722 = validateParameter(valid_602722, JString, required = false,
                                 default = nil)
  if valid_602722 != nil:
    section.add "X-Amz-Algorithm", valid_602722
  var valid_602723 = header.getOrDefault("X-Amz-Signature")
  valid_602723 = validateParameter(valid_602723, JString, required = false,
                                 default = nil)
  if valid_602723 != nil:
    section.add "X-Amz-Signature", valid_602723
  var valid_602724 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602724 = validateParameter(valid_602724, JString, required = false,
                                 default = nil)
  if valid_602724 != nil:
    section.add "X-Amz-SignedHeaders", valid_602724
  var valid_602725 = header.getOrDefault("X-Amz-Credential")
  valid_602725 = validateParameter(valid_602725, JString, required = false,
                                 default = nil)
  if valid_602725 != nil:
    section.add "X-Amz-Credential", valid_602725
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602726: Call_GetValidateConfigurationSettings_602710;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Takes a set of configuration settings and either a configuration template or environment, and determines whether those values are valid.</p> <p>This action returns a list of messages indicating any errors or warnings associated with the selection of option values.</p>
  ## 
  let valid = call_602726.validator(path, query, header, formData, body)
  let scheme = call_602726.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602726.url(scheme.get, call_602726.host, call_602726.base,
                         call_602726.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602726, url, valid)

proc call*(call_602727: Call_GetValidateConfigurationSettings_602710;
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
  var query_602728 = newJObject()
  add(query_602728, "ApplicationName", newJString(ApplicationName))
  add(query_602728, "EnvironmentName", newJString(EnvironmentName))
  add(query_602728, "Action", newJString(Action))
  add(query_602728, "TemplateName", newJString(TemplateName))
  if OptionSettings != nil:
    query_602728.add "OptionSettings", OptionSettings
  add(query_602728, "Version", newJString(Version))
  result = call_602727.call(nil, query_602728, nil, nil, nil)

var getValidateConfigurationSettings* = Call_GetValidateConfigurationSettings_602710(
    name: "getValidateConfigurationSettings", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ValidateConfigurationSettings",
    validator: validate_GetValidateConfigurationSettings_602711, base: "/",
    url: url_GetValidateConfigurationSettings_602712,
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

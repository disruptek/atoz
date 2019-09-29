
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

  OpenApiRestCall_593438 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593438](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593438): Option[Scheme] {.used.} =
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
  Call_PostAbortEnvironmentUpdate_594047 = ref object of OpenApiRestCall_593438
proc url_PostAbortEnvironmentUpdate_594049(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostAbortEnvironmentUpdate_594048(path: JsonNode; query: JsonNode;
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
  var valid_594050 = query.getOrDefault("Action")
  valid_594050 = validateParameter(valid_594050, JString, required = true,
                                 default = newJString("AbortEnvironmentUpdate"))
  if valid_594050 != nil:
    section.add "Action", valid_594050
  var valid_594051 = query.getOrDefault("Version")
  valid_594051 = validateParameter(valid_594051, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594051 != nil:
    section.add "Version", valid_594051
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594052 = header.getOrDefault("X-Amz-Date")
  valid_594052 = validateParameter(valid_594052, JString, required = false,
                                 default = nil)
  if valid_594052 != nil:
    section.add "X-Amz-Date", valid_594052
  var valid_594053 = header.getOrDefault("X-Amz-Security-Token")
  valid_594053 = validateParameter(valid_594053, JString, required = false,
                                 default = nil)
  if valid_594053 != nil:
    section.add "X-Amz-Security-Token", valid_594053
  var valid_594054 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594054 = validateParameter(valid_594054, JString, required = false,
                                 default = nil)
  if valid_594054 != nil:
    section.add "X-Amz-Content-Sha256", valid_594054
  var valid_594055 = header.getOrDefault("X-Amz-Algorithm")
  valid_594055 = validateParameter(valid_594055, JString, required = false,
                                 default = nil)
  if valid_594055 != nil:
    section.add "X-Amz-Algorithm", valid_594055
  var valid_594056 = header.getOrDefault("X-Amz-Signature")
  valid_594056 = validateParameter(valid_594056, JString, required = false,
                                 default = nil)
  if valid_594056 != nil:
    section.add "X-Amz-Signature", valid_594056
  var valid_594057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594057 = validateParameter(valid_594057, JString, required = false,
                                 default = nil)
  if valid_594057 != nil:
    section.add "X-Amz-SignedHeaders", valid_594057
  var valid_594058 = header.getOrDefault("X-Amz-Credential")
  valid_594058 = validateParameter(valid_594058, JString, required = false,
                                 default = nil)
  if valid_594058 != nil:
    section.add "X-Amz-Credential", valid_594058
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentId: JString
  ##                : This specifies the ID of the environment with the in-progress update that you want to cancel.
  ##   EnvironmentName: JString
  ##                  : This specifies the name of the environment with the in-progress update that you want to cancel.
  section = newJObject()
  var valid_594059 = formData.getOrDefault("EnvironmentId")
  valid_594059 = validateParameter(valid_594059, JString, required = false,
                                 default = nil)
  if valid_594059 != nil:
    section.add "EnvironmentId", valid_594059
  var valid_594060 = formData.getOrDefault("EnvironmentName")
  valid_594060 = validateParameter(valid_594060, JString, required = false,
                                 default = nil)
  if valid_594060 != nil:
    section.add "EnvironmentName", valid_594060
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594061: Call_PostAbortEnvironmentUpdate_594047; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels in-progress environment configuration update or application version deployment.
  ## 
  let valid = call_594061.validator(path, query, header, formData, body)
  let scheme = call_594061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594061.url(scheme.get, call_594061.host, call_594061.base,
                         call_594061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594061, url, valid)

proc call*(call_594062: Call_PostAbortEnvironmentUpdate_594047;
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
  var query_594063 = newJObject()
  var formData_594064 = newJObject()
  add(formData_594064, "EnvironmentId", newJString(EnvironmentId))
  add(formData_594064, "EnvironmentName", newJString(EnvironmentName))
  add(query_594063, "Action", newJString(Action))
  add(query_594063, "Version", newJString(Version))
  result = call_594062.call(nil, query_594063, nil, formData_594064, nil)

var postAbortEnvironmentUpdate* = Call_PostAbortEnvironmentUpdate_594047(
    name: "postAbortEnvironmentUpdate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=AbortEnvironmentUpdate",
    validator: validate_PostAbortEnvironmentUpdate_594048, base: "/",
    url: url_PostAbortEnvironmentUpdate_594049,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAbortEnvironmentUpdate_593775 = ref object of OpenApiRestCall_593438
proc url_GetAbortEnvironmentUpdate_593777(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAbortEnvironmentUpdate_593776(path: JsonNode; query: JsonNode;
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
  var valid_593889 = query.getOrDefault("EnvironmentName")
  valid_593889 = validateParameter(valid_593889, JString, required = false,
                                 default = nil)
  if valid_593889 != nil:
    section.add "EnvironmentName", valid_593889
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593903 = query.getOrDefault("Action")
  valid_593903 = validateParameter(valid_593903, JString, required = true,
                                 default = newJString("AbortEnvironmentUpdate"))
  if valid_593903 != nil:
    section.add "Action", valid_593903
  var valid_593904 = query.getOrDefault("EnvironmentId")
  valid_593904 = validateParameter(valid_593904, JString, required = false,
                                 default = nil)
  if valid_593904 != nil:
    section.add "EnvironmentId", valid_593904
  var valid_593905 = query.getOrDefault("Version")
  valid_593905 = validateParameter(valid_593905, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593905 != nil:
    section.add "Version", valid_593905
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_593906 = header.getOrDefault("X-Amz-Date")
  valid_593906 = validateParameter(valid_593906, JString, required = false,
                                 default = nil)
  if valid_593906 != nil:
    section.add "X-Amz-Date", valid_593906
  var valid_593907 = header.getOrDefault("X-Amz-Security-Token")
  valid_593907 = validateParameter(valid_593907, JString, required = false,
                                 default = nil)
  if valid_593907 != nil:
    section.add "X-Amz-Security-Token", valid_593907
  var valid_593908 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593908 = validateParameter(valid_593908, JString, required = false,
                                 default = nil)
  if valid_593908 != nil:
    section.add "X-Amz-Content-Sha256", valid_593908
  var valid_593909 = header.getOrDefault("X-Amz-Algorithm")
  valid_593909 = validateParameter(valid_593909, JString, required = false,
                                 default = nil)
  if valid_593909 != nil:
    section.add "X-Amz-Algorithm", valid_593909
  var valid_593910 = header.getOrDefault("X-Amz-Signature")
  valid_593910 = validateParameter(valid_593910, JString, required = false,
                                 default = nil)
  if valid_593910 != nil:
    section.add "X-Amz-Signature", valid_593910
  var valid_593911 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593911 = validateParameter(valid_593911, JString, required = false,
                                 default = nil)
  if valid_593911 != nil:
    section.add "X-Amz-SignedHeaders", valid_593911
  var valid_593912 = header.getOrDefault("X-Amz-Credential")
  valid_593912 = validateParameter(valid_593912, JString, required = false,
                                 default = nil)
  if valid_593912 != nil:
    section.add "X-Amz-Credential", valid_593912
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593935: Call_GetAbortEnvironmentUpdate_593775; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels in-progress environment configuration update or application version deployment.
  ## 
  let valid = call_593935.validator(path, query, header, formData, body)
  let scheme = call_593935.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593935.url(scheme.get, call_593935.host, call_593935.base,
                         call_593935.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593935, url, valid)

proc call*(call_594006: Call_GetAbortEnvironmentUpdate_593775;
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
  var query_594007 = newJObject()
  add(query_594007, "EnvironmentName", newJString(EnvironmentName))
  add(query_594007, "Action", newJString(Action))
  add(query_594007, "EnvironmentId", newJString(EnvironmentId))
  add(query_594007, "Version", newJString(Version))
  result = call_594006.call(nil, query_594007, nil, nil, nil)

var getAbortEnvironmentUpdate* = Call_GetAbortEnvironmentUpdate_593775(
    name: "getAbortEnvironmentUpdate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=AbortEnvironmentUpdate",
    validator: validate_GetAbortEnvironmentUpdate_593776, base: "/",
    url: url_GetAbortEnvironmentUpdate_593777,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostApplyEnvironmentManagedAction_594083 = ref object of OpenApiRestCall_593438
proc url_PostApplyEnvironmentManagedAction_594085(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostApplyEnvironmentManagedAction_594084(path: JsonNode;
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
  var valid_594086 = query.getOrDefault("Action")
  valid_594086 = validateParameter(valid_594086, JString, required = true, default = newJString(
      "ApplyEnvironmentManagedAction"))
  if valid_594086 != nil:
    section.add "Action", valid_594086
  var valid_594087 = query.getOrDefault("Version")
  valid_594087 = validateParameter(valid_594087, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594087 != nil:
    section.add "Version", valid_594087
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594088 = header.getOrDefault("X-Amz-Date")
  valid_594088 = validateParameter(valid_594088, JString, required = false,
                                 default = nil)
  if valid_594088 != nil:
    section.add "X-Amz-Date", valid_594088
  var valid_594089 = header.getOrDefault("X-Amz-Security-Token")
  valid_594089 = validateParameter(valid_594089, JString, required = false,
                                 default = nil)
  if valid_594089 != nil:
    section.add "X-Amz-Security-Token", valid_594089
  var valid_594090 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594090 = validateParameter(valid_594090, JString, required = false,
                                 default = nil)
  if valid_594090 != nil:
    section.add "X-Amz-Content-Sha256", valid_594090
  var valid_594091 = header.getOrDefault("X-Amz-Algorithm")
  valid_594091 = validateParameter(valid_594091, JString, required = false,
                                 default = nil)
  if valid_594091 != nil:
    section.add "X-Amz-Algorithm", valid_594091
  var valid_594092 = header.getOrDefault("X-Amz-Signature")
  valid_594092 = validateParameter(valid_594092, JString, required = false,
                                 default = nil)
  if valid_594092 != nil:
    section.add "X-Amz-Signature", valid_594092
  var valid_594093 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594093 = validateParameter(valid_594093, JString, required = false,
                                 default = nil)
  if valid_594093 != nil:
    section.add "X-Amz-SignedHeaders", valid_594093
  var valid_594094 = header.getOrDefault("X-Amz-Credential")
  valid_594094 = validateParameter(valid_594094, JString, required = false,
                                 default = nil)
  if valid_594094 != nil:
    section.add "X-Amz-Credential", valid_594094
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentId: JString
  ##                : The environment ID of the target environment.
  ##   EnvironmentName: JString
  ##                  : The name of the target environment.
  ##   ActionId: JString (required)
  ##           : The action ID of the scheduled managed action to execute.
  section = newJObject()
  var valid_594095 = formData.getOrDefault("EnvironmentId")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = nil)
  if valid_594095 != nil:
    section.add "EnvironmentId", valid_594095
  var valid_594096 = formData.getOrDefault("EnvironmentName")
  valid_594096 = validateParameter(valid_594096, JString, required = false,
                                 default = nil)
  if valid_594096 != nil:
    section.add "EnvironmentName", valid_594096
  assert formData != nil,
        "formData argument is necessary due to required `ActionId` field"
  var valid_594097 = formData.getOrDefault("ActionId")
  valid_594097 = validateParameter(valid_594097, JString, required = true,
                                 default = nil)
  if valid_594097 != nil:
    section.add "ActionId", valid_594097
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594098: Call_PostApplyEnvironmentManagedAction_594083;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Applies a scheduled managed action immediately. A managed action can be applied only if its status is <code>Scheduled</code>. Get the status and action ID of a managed action with <a>DescribeEnvironmentManagedActions</a>.
  ## 
  let valid = call_594098.validator(path, query, header, formData, body)
  let scheme = call_594098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594098.url(scheme.get, call_594098.host, call_594098.base,
                         call_594098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594098, url, valid)

proc call*(call_594099: Call_PostApplyEnvironmentManagedAction_594083;
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
  var query_594100 = newJObject()
  var formData_594101 = newJObject()
  add(formData_594101, "EnvironmentId", newJString(EnvironmentId))
  add(formData_594101, "EnvironmentName", newJString(EnvironmentName))
  add(query_594100, "Action", newJString(Action))
  add(formData_594101, "ActionId", newJString(ActionId))
  add(query_594100, "Version", newJString(Version))
  result = call_594099.call(nil, query_594100, nil, formData_594101, nil)

var postApplyEnvironmentManagedAction* = Call_PostApplyEnvironmentManagedAction_594083(
    name: "postApplyEnvironmentManagedAction", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ApplyEnvironmentManagedAction",
    validator: validate_PostApplyEnvironmentManagedAction_594084, base: "/",
    url: url_PostApplyEnvironmentManagedAction_594085,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplyEnvironmentManagedAction_594065 = ref object of OpenApiRestCall_593438
proc url_GetApplyEnvironmentManagedAction_594067(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetApplyEnvironmentManagedAction_594066(path: JsonNode;
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
  var valid_594068 = query.getOrDefault("EnvironmentName")
  valid_594068 = validateParameter(valid_594068, JString, required = false,
                                 default = nil)
  if valid_594068 != nil:
    section.add "EnvironmentName", valid_594068
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594069 = query.getOrDefault("Action")
  valid_594069 = validateParameter(valid_594069, JString, required = true, default = newJString(
      "ApplyEnvironmentManagedAction"))
  if valid_594069 != nil:
    section.add "Action", valid_594069
  var valid_594070 = query.getOrDefault("EnvironmentId")
  valid_594070 = validateParameter(valid_594070, JString, required = false,
                                 default = nil)
  if valid_594070 != nil:
    section.add "EnvironmentId", valid_594070
  var valid_594071 = query.getOrDefault("ActionId")
  valid_594071 = validateParameter(valid_594071, JString, required = true,
                                 default = nil)
  if valid_594071 != nil:
    section.add "ActionId", valid_594071
  var valid_594072 = query.getOrDefault("Version")
  valid_594072 = validateParameter(valid_594072, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594072 != nil:
    section.add "Version", valid_594072
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594073 = header.getOrDefault("X-Amz-Date")
  valid_594073 = validateParameter(valid_594073, JString, required = false,
                                 default = nil)
  if valid_594073 != nil:
    section.add "X-Amz-Date", valid_594073
  var valid_594074 = header.getOrDefault("X-Amz-Security-Token")
  valid_594074 = validateParameter(valid_594074, JString, required = false,
                                 default = nil)
  if valid_594074 != nil:
    section.add "X-Amz-Security-Token", valid_594074
  var valid_594075 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594075 = validateParameter(valid_594075, JString, required = false,
                                 default = nil)
  if valid_594075 != nil:
    section.add "X-Amz-Content-Sha256", valid_594075
  var valid_594076 = header.getOrDefault("X-Amz-Algorithm")
  valid_594076 = validateParameter(valid_594076, JString, required = false,
                                 default = nil)
  if valid_594076 != nil:
    section.add "X-Amz-Algorithm", valid_594076
  var valid_594077 = header.getOrDefault("X-Amz-Signature")
  valid_594077 = validateParameter(valid_594077, JString, required = false,
                                 default = nil)
  if valid_594077 != nil:
    section.add "X-Amz-Signature", valid_594077
  var valid_594078 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594078 = validateParameter(valid_594078, JString, required = false,
                                 default = nil)
  if valid_594078 != nil:
    section.add "X-Amz-SignedHeaders", valid_594078
  var valid_594079 = header.getOrDefault("X-Amz-Credential")
  valid_594079 = validateParameter(valid_594079, JString, required = false,
                                 default = nil)
  if valid_594079 != nil:
    section.add "X-Amz-Credential", valid_594079
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594080: Call_GetApplyEnvironmentManagedAction_594065;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Applies a scheduled managed action immediately. A managed action can be applied only if its status is <code>Scheduled</code>. Get the status and action ID of a managed action with <a>DescribeEnvironmentManagedActions</a>.
  ## 
  let valid = call_594080.validator(path, query, header, formData, body)
  let scheme = call_594080.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594080.url(scheme.get, call_594080.host, call_594080.base,
                         call_594080.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594080, url, valid)

proc call*(call_594081: Call_GetApplyEnvironmentManagedAction_594065;
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
  var query_594082 = newJObject()
  add(query_594082, "EnvironmentName", newJString(EnvironmentName))
  add(query_594082, "Action", newJString(Action))
  add(query_594082, "EnvironmentId", newJString(EnvironmentId))
  add(query_594082, "ActionId", newJString(ActionId))
  add(query_594082, "Version", newJString(Version))
  result = call_594081.call(nil, query_594082, nil, nil, nil)

var getApplyEnvironmentManagedAction* = Call_GetApplyEnvironmentManagedAction_594065(
    name: "getApplyEnvironmentManagedAction", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ApplyEnvironmentManagedAction",
    validator: validate_GetApplyEnvironmentManagedAction_594066, base: "/",
    url: url_GetApplyEnvironmentManagedAction_594067,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCheckDNSAvailability_594118 = ref object of OpenApiRestCall_593438
proc url_PostCheckDNSAvailability_594120(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCheckDNSAvailability_594119(path: JsonNode; query: JsonNode;
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
  var valid_594121 = query.getOrDefault("Action")
  valid_594121 = validateParameter(valid_594121, JString, required = true,
                                 default = newJString("CheckDNSAvailability"))
  if valid_594121 != nil:
    section.add "Action", valid_594121
  var valid_594122 = query.getOrDefault("Version")
  valid_594122 = validateParameter(valid_594122, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594122 != nil:
    section.add "Version", valid_594122
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594123 = header.getOrDefault("X-Amz-Date")
  valid_594123 = validateParameter(valid_594123, JString, required = false,
                                 default = nil)
  if valid_594123 != nil:
    section.add "X-Amz-Date", valid_594123
  var valid_594124 = header.getOrDefault("X-Amz-Security-Token")
  valid_594124 = validateParameter(valid_594124, JString, required = false,
                                 default = nil)
  if valid_594124 != nil:
    section.add "X-Amz-Security-Token", valid_594124
  var valid_594125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594125 = validateParameter(valid_594125, JString, required = false,
                                 default = nil)
  if valid_594125 != nil:
    section.add "X-Amz-Content-Sha256", valid_594125
  var valid_594126 = header.getOrDefault("X-Amz-Algorithm")
  valid_594126 = validateParameter(valid_594126, JString, required = false,
                                 default = nil)
  if valid_594126 != nil:
    section.add "X-Amz-Algorithm", valid_594126
  var valid_594127 = header.getOrDefault("X-Amz-Signature")
  valid_594127 = validateParameter(valid_594127, JString, required = false,
                                 default = nil)
  if valid_594127 != nil:
    section.add "X-Amz-Signature", valid_594127
  var valid_594128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594128 = validateParameter(valid_594128, JString, required = false,
                                 default = nil)
  if valid_594128 != nil:
    section.add "X-Amz-SignedHeaders", valid_594128
  var valid_594129 = header.getOrDefault("X-Amz-Credential")
  valid_594129 = validateParameter(valid_594129, JString, required = false,
                                 default = nil)
  if valid_594129 != nil:
    section.add "X-Amz-Credential", valid_594129
  result.add "header", section
  ## parameters in `formData` object:
  ##   CNAMEPrefix: JString (required)
  ##              : The prefix used when this CNAME is reserved.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `CNAMEPrefix` field"
  var valid_594130 = formData.getOrDefault("CNAMEPrefix")
  valid_594130 = validateParameter(valid_594130, JString, required = true,
                                 default = nil)
  if valid_594130 != nil:
    section.add "CNAMEPrefix", valid_594130
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594131: Call_PostCheckDNSAvailability_594118; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Checks if the specified CNAME is available.
  ## 
  let valid = call_594131.validator(path, query, header, formData, body)
  let scheme = call_594131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594131.url(scheme.get, call_594131.host, call_594131.base,
                         call_594131.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594131, url, valid)

proc call*(call_594132: Call_PostCheckDNSAvailability_594118; CNAMEPrefix: string;
          Action: string = "CheckDNSAvailability"; Version: string = "2010-12-01"): Recallable =
  ## postCheckDNSAvailability
  ## Checks if the specified CNAME is available.
  ##   CNAMEPrefix: string (required)
  ##              : The prefix used when this CNAME is reserved.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594133 = newJObject()
  var formData_594134 = newJObject()
  add(formData_594134, "CNAMEPrefix", newJString(CNAMEPrefix))
  add(query_594133, "Action", newJString(Action))
  add(query_594133, "Version", newJString(Version))
  result = call_594132.call(nil, query_594133, nil, formData_594134, nil)

var postCheckDNSAvailability* = Call_PostCheckDNSAvailability_594118(
    name: "postCheckDNSAvailability", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CheckDNSAvailability",
    validator: validate_PostCheckDNSAvailability_594119, base: "/",
    url: url_PostCheckDNSAvailability_594120, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCheckDNSAvailability_594102 = ref object of OpenApiRestCall_593438
proc url_GetCheckDNSAvailability_594104(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCheckDNSAvailability_594103(path: JsonNode; query: JsonNode;
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
  var valid_594105 = query.getOrDefault("Action")
  valid_594105 = validateParameter(valid_594105, JString, required = true,
                                 default = newJString("CheckDNSAvailability"))
  if valid_594105 != nil:
    section.add "Action", valid_594105
  var valid_594106 = query.getOrDefault("Version")
  valid_594106 = validateParameter(valid_594106, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594106 != nil:
    section.add "Version", valid_594106
  var valid_594107 = query.getOrDefault("CNAMEPrefix")
  valid_594107 = validateParameter(valid_594107, JString, required = true,
                                 default = nil)
  if valid_594107 != nil:
    section.add "CNAMEPrefix", valid_594107
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594108 = header.getOrDefault("X-Amz-Date")
  valid_594108 = validateParameter(valid_594108, JString, required = false,
                                 default = nil)
  if valid_594108 != nil:
    section.add "X-Amz-Date", valid_594108
  var valid_594109 = header.getOrDefault("X-Amz-Security-Token")
  valid_594109 = validateParameter(valid_594109, JString, required = false,
                                 default = nil)
  if valid_594109 != nil:
    section.add "X-Amz-Security-Token", valid_594109
  var valid_594110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594110 = validateParameter(valid_594110, JString, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "X-Amz-Content-Sha256", valid_594110
  var valid_594111 = header.getOrDefault("X-Amz-Algorithm")
  valid_594111 = validateParameter(valid_594111, JString, required = false,
                                 default = nil)
  if valid_594111 != nil:
    section.add "X-Amz-Algorithm", valid_594111
  var valid_594112 = header.getOrDefault("X-Amz-Signature")
  valid_594112 = validateParameter(valid_594112, JString, required = false,
                                 default = nil)
  if valid_594112 != nil:
    section.add "X-Amz-Signature", valid_594112
  var valid_594113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594113 = validateParameter(valid_594113, JString, required = false,
                                 default = nil)
  if valid_594113 != nil:
    section.add "X-Amz-SignedHeaders", valid_594113
  var valid_594114 = header.getOrDefault("X-Amz-Credential")
  valid_594114 = validateParameter(valid_594114, JString, required = false,
                                 default = nil)
  if valid_594114 != nil:
    section.add "X-Amz-Credential", valid_594114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594115: Call_GetCheckDNSAvailability_594102; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Checks if the specified CNAME is available.
  ## 
  let valid = call_594115.validator(path, query, header, formData, body)
  let scheme = call_594115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594115.url(scheme.get, call_594115.host, call_594115.base,
                         call_594115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594115, url, valid)

proc call*(call_594116: Call_GetCheckDNSAvailability_594102; CNAMEPrefix: string;
          Action: string = "CheckDNSAvailability"; Version: string = "2010-12-01"): Recallable =
  ## getCheckDNSAvailability
  ## Checks if the specified CNAME is available.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   CNAMEPrefix: string (required)
  ##              : The prefix used when this CNAME is reserved.
  var query_594117 = newJObject()
  add(query_594117, "Action", newJString(Action))
  add(query_594117, "Version", newJString(Version))
  add(query_594117, "CNAMEPrefix", newJString(CNAMEPrefix))
  result = call_594116.call(nil, query_594117, nil, nil, nil)

var getCheckDNSAvailability* = Call_GetCheckDNSAvailability_594102(
    name: "getCheckDNSAvailability", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CheckDNSAvailability",
    validator: validate_GetCheckDNSAvailability_594103, base: "/",
    url: url_GetCheckDNSAvailability_594104, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostComposeEnvironments_594153 = ref object of OpenApiRestCall_593438
proc url_PostComposeEnvironments_594155(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostComposeEnvironments_594154(path: JsonNode; query: JsonNode;
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
  var valid_594156 = query.getOrDefault("Action")
  valid_594156 = validateParameter(valid_594156, JString, required = true,
                                 default = newJString("ComposeEnvironments"))
  if valid_594156 != nil:
    section.add "Action", valid_594156
  var valid_594157 = query.getOrDefault("Version")
  valid_594157 = validateParameter(valid_594157, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594157 != nil:
    section.add "Version", valid_594157
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594158 = header.getOrDefault("X-Amz-Date")
  valid_594158 = validateParameter(valid_594158, JString, required = false,
                                 default = nil)
  if valid_594158 != nil:
    section.add "X-Amz-Date", valid_594158
  var valid_594159 = header.getOrDefault("X-Amz-Security-Token")
  valid_594159 = validateParameter(valid_594159, JString, required = false,
                                 default = nil)
  if valid_594159 != nil:
    section.add "X-Amz-Security-Token", valid_594159
  var valid_594160 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594160 = validateParameter(valid_594160, JString, required = false,
                                 default = nil)
  if valid_594160 != nil:
    section.add "X-Amz-Content-Sha256", valid_594160
  var valid_594161 = header.getOrDefault("X-Amz-Algorithm")
  valid_594161 = validateParameter(valid_594161, JString, required = false,
                                 default = nil)
  if valid_594161 != nil:
    section.add "X-Amz-Algorithm", valid_594161
  var valid_594162 = header.getOrDefault("X-Amz-Signature")
  valid_594162 = validateParameter(valid_594162, JString, required = false,
                                 default = nil)
  if valid_594162 != nil:
    section.add "X-Amz-Signature", valid_594162
  var valid_594163 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594163 = validateParameter(valid_594163, JString, required = false,
                                 default = nil)
  if valid_594163 != nil:
    section.add "X-Amz-SignedHeaders", valid_594163
  var valid_594164 = header.getOrDefault("X-Amz-Credential")
  valid_594164 = validateParameter(valid_594164, JString, required = false,
                                 default = nil)
  if valid_594164 != nil:
    section.add "X-Amz-Credential", valid_594164
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
  var valid_594165 = formData.getOrDefault("GroupName")
  valid_594165 = validateParameter(valid_594165, JString, required = false,
                                 default = nil)
  if valid_594165 != nil:
    section.add "GroupName", valid_594165
  var valid_594166 = formData.getOrDefault("ApplicationName")
  valid_594166 = validateParameter(valid_594166, JString, required = false,
                                 default = nil)
  if valid_594166 != nil:
    section.add "ApplicationName", valid_594166
  var valid_594167 = formData.getOrDefault("VersionLabels")
  valid_594167 = validateParameter(valid_594167, JArray, required = false,
                                 default = nil)
  if valid_594167 != nil:
    section.add "VersionLabels", valid_594167
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594168: Call_PostComposeEnvironments_594153; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create or update a group of environments that each run a separate component of a single application. Takes a list of version labels that specify application source bundles for each of the environments to create or update. The name of each environment and other required information must be included in the source bundles in an environment manifest named <code>env.yaml</code>. See <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-mgmt-compose.html">Compose Environments</a> for details.
  ## 
  let valid = call_594168.validator(path, query, header, formData, body)
  let scheme = call_594168.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594168.url(scheme.get, call_594168.host, call_594168.base,
                         call_594168.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594168, url, valid)

proc call*(call_594169: Call_PostComposeEnvironments_594153;
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
  var query_594170 = newJObject()
  var formData_594171 = newJObject()
  add(formData_594171, "GroupName", newJString(GroupName))
  add(query_594170, "Action", newJString(Action))
  add(formData_594171, "ApplicationName", newJString(ApplicationName))
  add(query_594170, "Version", newJString(Version))
  if VersionLabels != nil:
    formData_594171.add "VersionLabels", VersionLabels
  result = call_594169.call(nil, query_594170, nil, formData_594171, nil)

var postComposeEnvironments* = Call_PostComposeEnvironments_594153(
    name: "postComposeEnvironments", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ComposeEnvironments",
    validator: validate_PostComposeEnvironments_594154, base: "/",
    url: url_PostComposeEnvironments_594155, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetComposeEnvironments_594135 = ref object of OpenApiRestCall_593438
proc url_GetComposeEnvironments_594137(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetComposeEnvironments_594136(path: JsonNode; query: JsonNode;
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
  var valid_594138 = query.getOrDefault("ApplicationName")
  valid_594138 = validateParameter(valid_594138, JString, required = false,
                                 default = nil)
  if valid_594138 != nil:
    section.add "ApplicationName", valid_594138
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594139 = query.getOrDefault("Action")
  valid_594139 = validateParameter(valid_594139, JString, required = true,
                                 default = newJString("ComposeEnvironments"))
  if valid_594139 != nil:
    section.add "Action", valid_594139
  var valid_594140 = query.getOrDefault("GroupName")
  valid_594140 = validateParameter(valid_594140, JString, required = false,
                                 default = nil)
  if valid_594140 != nil:
    section.add "GroupName", valid_594140
  var valid_594141 = query.getOrDefault("VersionLabels")
  valid_594141 = validateParameter(valid_594141, JArray, required = false,
                                 default = nil)
  if valid_594141 != nil:
    section.add "VersionLabels", valid_594141
  var valid_594142 = query.getOrDefault("Version")
  valid_594142 = validateParameter(valid_594142, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594142 != nil:
    section.add "Version", valid_594142
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594143 = header.getOrDefault("X-Amz-Date")
  valid_594143 = validateParameter(valid_594143, JString, required = false,
                                 default = nil)
  if valid_594143 != nil:
    section.add "X-Amz-Date", valid_594143
  var valid_594144 = header.getOrDefault("X-Amz-Security-Token")
  valid_594144 = validateParameter(valid_594144, JString, required = false,
                                 default = nil)
  if valid_594144 != nil:
    section.add "X-Amz-Security-Token", valid_594144
  var valid_594145 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594145 = validateParameter(valid_594145, JString, required = false,
                                 default = nil)
  if valid_594145 != nil:
    section.add "X-Amz-Content-Sha256", valid_594145
  var valid_594146 = header.getOrDefault("X-Amz-Algorithm")
  valid_594146 = validateParameter(valid_594146, JString, required = false,
                                 default = nil)
  if valid_594146 != nil:
    section.add "X-Amz-Algorithm", valid_594146
  var valid_594147 = header.getOrDefault("X-Amz-Signature")
  valid_594147 = validateParameter(valid_594147, JString, required = false,
                                 default = nil)
  if valid_594147 != nil:
    section.add "X-Amz-Signature", valid_594147
  var valid_594148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594148 = validateParameter(valid_594148, JString, required = false,
                                 default = nil)
  if valid_594148 != nil:
    section.add "X-Amz-SignedHeaders", valid_594148
  var valid_594149 = header.getOrDefault("X-Amz-Credential")
  valid_594149 = validateParameter(valid_594149, JString, required = false,
                                 default = nil)
  if valid_594149 != nil:
    section.add "X-Amz-Credential", valid_594149
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594150: Call_GetComposeEnvironments_594135; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create or update a group of environments that each run a separate component of a single application. Takes a list of version labels that specify application source bundles for each of the environments to create or update. The name of each environment and other required information must be included in the source bundles in an environment manifest named <code>env.yaml</code>. See <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-mgmt-compose.html">Compose Environments</a> for details.
  ## 
  let valid = call_594150.validator(path, query, header, formData, body)
  let scheme = call_594150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594150.url(scheme.get, call_594150.host, call_594150.base,
                         call_594150.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594150, url, valid)

proc call*(call_594151: Call_GetComposeEnvironments_594135;
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
  var query_594152 = newJObject()
  add(query_594152, "ApplicationName", newJString(ApplicationName))
  add(query_594152, "Action", newJString(Action))
  add(query_594152, "GroupName", newJString(GroupName))
  if VersionLabels != nil:
    query_594152.add "VersionLabels", VersionLabels
  add(query_594152, "Version", newJString(Version))
  result = call_594151.call(nil, query_594152, nil, nil, nil)

var getComposeEnvironments* = Call_GetComposeEnvironments_594135(
    name: "getComposeEnvironments", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ComposeEnvironments",
    validator: validate_GetComposeEnvironments_594136, base: "/",
    url: url_GetComposeEnvironments_594137, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateApplication_594192 = ref object of OpenApiRestCall_593438
proc url_PostCreateApplication_594194(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateApplication_594193(path: JsonNode; query: JsonNode;
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
  var valid_594195 = query.getOrDefault("Action")
  valid_594195 = validateParameter(valid_594195, JString, required = true,
                                 default = newJString("CreateApplication"))
  if valid_594195 != nil:
    section.add "Action", valid_594195
  var valid_594196 = query.getOrDefault("Version")
  valid_594196 = validateParameter(valid_594196, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594196 != nil:
    section.add "Version", valid_594196
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594197 = header.getOrDefault("X-Amz-Date")
  valid_594197 = validateParameter(valid_594197, JString, required = false,
                                 default = nil)
  if valid_594197 != nil:
    section.add "X-Amz-Date", valid_594197
  var valid_594198 = header.getOrDefault("X-Amz-Security-Token")
  valid_594198 = validateParameter(valid_594198, JString, required = false,
                                 default = nil)
  if valid_594198 != nil:
    section.add "X-Amz-Security-Token", valid_594198
  var valid_594199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594199 = validateParameter(valid_594199, JString, required = false,
                                 default = nil)
  if valid_594199 != nil:
    section.add "X-Amz-Content-Sha256", valid_594199
  var valid_594200 = header.getOrDefault("X-Amz-Algorithm")
  valid_594200 = validateParameter(valid_594200, JString, required = false,
                                 default = nil)
  if valid_594200 != nil:
    section.add "X-Amz-Algorithm", valid_594200
  var valid_594201 = header.getOrDefault("X-Amz-Signature")
  valid_594201 = validateParameter(valid_594201, JString, required = false,
                                 default = nil)
  if valid_594201 != nil:
    section.add "X-Amz-Signature", valid_594201
  var valid_594202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594202 = validateParameter(valid_594202, JString, required = false,
                                 default = nil)
  if valid_594202 != nil:
    section.add "X-Amz-SignedHeaders", valid_594202
  var valid_594203 = header.getOrDefault("X-Amz-Credential")
  valid_594203 = validateParameter(valid_594203, JString, required = false,
                                 default = nil)
  if valid_594203 != nil:
    section.add "X-Amz-Credential", valid_594203
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
  var valid_594204 = formData.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_594204 = validateParameter(valid_594204, JString, required = false,
                                 default = nil)
  if valid_594204 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_594204
  var valid_594205 = formData.getOrDefault("Tags")
  valid_594205 = validateParameter(valid_594205, JArray, required = false,
                                 default = nil)
  if valid_594205 != nil:
    section.add "Tags", valid_594205
  var valid_594206 = formData.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_594206 = validateParameter(valid_594206, JString, required = false,
                                 default = nil)
  if valid_594206 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_594206
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_594207 = formData.getOrDefault("ApplicationName")
  valid_594207 = validateParameter(valid_594207, JString, required = true,
                                 default = nil)
  if valid_594207 != nil:
    section.add "ApplicationName", valid_594207
  var valid_594208 = formData.getOrDefault("Description")
  valid_594208 = validateParameter(valid_594208, JString, required = false,
                                 default = nil)
  if valid_594208 != nil:
    section.add "Description", valid_594208
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594209: Call_PostCreateApplication_594192; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates an application that has one configuration template named <code>default</code> and no application versions. 
  ## 
  let valid = call_594209.validator(path, query, header, formData, body)
  let scheme = call_594209.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594209.url(scheme.get, call_594209.host, call_594209.base,
                         call_594209.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594209, url, valid)

proc call*(call_594210: Call_PostCreateApplication_594192; ApplicationName: string;
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
  var query_594211 = newJObject()
  var formData_594212 = newJObject()
  add(formData_594212, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  if Tags != nil:
    formData_594212.add "Tags", Tags
  add(formData_594212, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  add(query_594211, "Action", newJString(Action))
  add(formData_594212, "ApplicationName", newJString(ApplicationName))
  add(query_594211, "Version", newJString(Version))
  add(formData_594212, "Description", newJString(Description))
  result = call_594210.call(nil, query_594211, nil, formData_594212, nil)

var postCreateApplication* = Call_PostCreateApplication_594192(
    name: "postCreateApplication", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateApplication",
    validator: validate_PostCreateApplication_594193, base: "/",
    url: url_PostCreateApplication_594194, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateApplication_594172 = ref object of OpenApiRestCall_593438
proc url_GetCreateApplication_594174(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateApplication_594173(path: JsonNode; query: JsonNode;
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
  var valid_594175 = query.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_594175 = validateParameter(valid_594175, JString, required = false,
                                 default = nil)
  if valid_594175 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_594175
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_594176 = query.getOrDefault("ApplicationName")
  valid_594176 = validateParameter(valid_594176, JString, required = true,
                                 default = nil)
  if valid_594176 != nil:
    section.add "ApplicationName", valid_594176
  var valid_594177 = query.getOrDefault("Description")
  valid_594177 = validateParameter(valid_594177, JString, required = false,
                                 default = nil)
  if valid_594177 != nil:
    section.add "Description", valid_594177
  var valid_594178 = query.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_594178 = validateParameter(valid_594178, JString, required = false,
                                 default = nil)
  if valid_594178 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_594178
  var valid_594179 = query.getOrDefault("Tags")
  valid_594179 = validateParameter(valid_594179, JArray, required = false,
                                 default = nil)
  if valid_594179 != nil:
    section.add "Tags", valid_594179
  var valid_594180 = query.getOrDefault("Action")
  valid_594180 = validateParameter(valid_594180, JString, required = true,
                                 default = newJString("CreateApplication"))
  if valid_594180 != nil:
    section.add "Action", valid_594180
  var valid_594181 = query.getOrDefault("Version")
  valid_594181 = validateParameter(valid_594181, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594181 != nil:
    section.add "Version", valid_594181
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594182 = header.getOrDefault("X-Amz-Date")
  valid_594182 = validateParameter(valid_594182, JString, required = false,
                                 default = nil)
  if valid_594182 != nil:
    section.add "X-Amz-Date", valid_594182
  var valid_594183 = header.getOrDefault("X-Amz-Security-Token")
  valid_594183 = validateParameter(valid_594183, JString, required = false,
                                 default = nil)
  if valid_594183 != nil:
    section.add "X-Amz-Security-Token", valid_594183
  var valid_594184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594184 = validateParameter(valid_594184, JString, required = false,
                                 default = nil)
  if valid_594184 != nil:
    section.add "X-Amz-Content-Sha256", valid_594184
  var valid_594185 = header.getOrDefault("X-Amz-Algorithm")
  valid_594185 = validateParameter(valid_594185, JString, required = false,
                                 default = nil)
  if valid_594185 != nil:
    section.add "X-Amz-Algorithm", valid_594185
  var valid_594186 = header.getOrDefault("X-Amz-Signature")
  valid_594186 = validateParameter(valid_594186, JString, required = false,
                                 default = nil)
  if valid_594186 != nil:
    section.add "X-Amz-Signature", valid_594186
  var valid_594187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594187 = validateParameter(valid_594187, JString, required = false,
                                 default = nil)
  if valid_594187 != nil:
    section.add "X-Amz-SignedHeaders", valid_594187
  var valid_594188 = header.getOrDefault("X-Amz-Credential")
  valid_594188 = validateParameter(valid_594188, JString, required = false,
                                 default = nil)
  if valid_594188 != nil:
    section.add "X-Amz-Credential", valid_594188
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594189: Call_GetCreateApplication_594172; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates an application that has one configuration template named <code>default</code> and no application versions. 
  ## 
  let valid = call_594189.validator(path, query, header, formData, body)
  let scheme = call_594189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594189.url(scheme.get, call_594189.host, call_594189.base,
                         call_594189.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594189, url, valid)

proc call*(call_594190: Call_GetCreateApplication_594172; ApplicationName: string;
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
  var query_594191 = newJObject()
  add(query_594191, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  add(query_594191, "ApplicationName", newJString(ApplicationName))
  add(query_594191, "Description", newJString(Description))
  add(query_594191, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  if Tags != nil:
    query_594191.add "Tags", Tags
  add(query_594191, "Action", newJString(Action))
  add(query_594191, "Version", newJString(Version))
  result = call_594190.call(nil, query_594191, nil, nil, nil)

var getCreateApplication* = Call_GetCreateApplication_594172(
    name: "getCreateApplication", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateApplication",
    validator: validate_GetCreateApplication_594173, base: "/",
    url: url_GetCreateApplication_594174, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateApplicationVersion_594244 = ref object of OpenApiRestCall_593438
proc url_PostCreateApplicationVersion_594246(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateApplicationVersion_594245(path: JsonNode; query: JsonNode;
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
  var valid_594247 = query.getOrDefault("Action")
  valid_594247 = validateParameter(valid_594247, JString, required = true, default = newJString(
      "CreateApplicationVersion"))
  if valid_594247 != nil:
    section.add "Action", valid_594247
  var valid_594248 = query.getOrDefault("Version")
  valid_594248 = validateParameter(valid_594248, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594248 != nil:
    section.add "Version", valid_594248
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594249 = header.getOrDefault("X-Amz-Date")
  valid_594249 = validateParameter(valid_594249, JString, required = false,
                                 default = nil)
  if valid_594249 != nil:
    section.add "X-Amz-Date", valid_594249
  var valid_594250 = header.getOrDefault("X-Amz-Security-Token")
  valid_594250 = validateParameter(valid_594250, JString, required = false,
                                 default = nil)
  if valid_594250 != nil:
    section.add "X-Amz-Security-Token", valid_594250
  var valid_594251 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594251 = validateParameter(valid_594251, JString, required = false,
                                 default = nil)
  if valid_594251 != nil:
    section.add "X-Amz-Content-Sha256", valid_594251
  var valid_594252 = header.getOrDefault("X-Amz-Algorithm")
  valid_594252 = validateParameter(valid_594252, JString, required = false,
                                 default = nil)
  if valid_594252 != nil:
    section.add "X-Amz-Algorithm", valid_594252
  var valid_594253 = header.getOrDefault("X-Amz-Signature")
  valid_594253 = validateParameter(valid_594253, JString, required = false,
                                 default = nil)
  if valid_594253 != nil:
    section.add "X-Amz-Signature", valid_594253
  var valid_594254 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594254 = validateParameter(valid_594254, JString, required = false,
                                 default = nil)
  if valid_594254 != nil:
    section.add "X-Amz-SignedHeaders", valid_594254
  var valid_594255 = header.getOrDefault("X-Amz-Credential")
  valid_594255 = validateParameter(valid_594255, JString, required = false,
                                 default = nil)
  if valid_594255 != nil:
    section.add "X-Amz-Credential", valid_594255
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
  var valid_594256 = formData.getOrDefault("SourceBundle.S3Key")
  valid_594256 = validateParameter(valid_594256, JString, required = false,
                                 default = nil)
  if valid_594256 != nil:
    section.add "SourceBundle.S3Key", valid_594256
  assert formData != nil,
        "formData argument is necessary due to required `VersionLabel` field"
  var valid_594257 = formData.getOrDefault("VersionLabel")
  valid_594257 = validateParameter(valid_594257, JString, required = true,
                                 default = nil)
  if valid_594257 != nil:
    section.add "VersionLabel", valid_594257
  var valid_594258 = formData.getOrDefault("SourceBundle.S3Bucket")
  valid_594258 = validateParameter(valid_594258, JString, required = false,
                                 default = nil)
  if valid_594258 != nil:
    section.add "SourceBundle.S3Bucket", valid_594258
  var valid_594259 = formData.getOrDefault("BuildConfiguration.ComputeType")
  valid_594259 = validateParameter(valid_594259, JString, required = false,
                                 default = nil)
  if valid_594259 != nil:
    section.add "BuildConfiguration.ComputeType", valid_594259
  var valid_594260 = formData.getOrDefault("SourceBuildInformation.SourceType")
  valid_594260 = validateParameter(valid_594260, JString, required = false,
                                 default = nil)
  if valid_594260 != nil:
    section.add "SourceBuildInformation.SourceType", valid_594260
  var valid_594261 = formData.getOrDefault("Tags")
  valid_594261 = validateParameter(valid_594261, JArray, required = false,
                                 default = nil)
  if valid_594261 != nil:
    section.add "Tags", valid_594261
  var valid_594262 = formData.getOrDefault("AutoCreateApplication")
  valid_594262 = validateParameter(valid_594262, JBool, required = false, default = nil)
  if valid_594262 != nil:
    section.add "AutoCreateApplication", valid_594262
  var valid_594263 = formData.getOrDefault("SourceBuildInformation.SourceLocation")
  valid_594263 = validateParameter(valid_594263, JString, required = false,
                                 default = nil)
  if valid_594263 != nil:
    section.add "SourceBuildInformation.SourceLocation", valid_594263
  var valid_594264 = formData.getOrDefault("BuildConfiguration.CodeBuildServiceRole")
  valid_594264 = validateParameter(valid_594264, JString, required = false,
                                 default = nil)
  if valid_594264 != nil:
    section.add "BuildConfiguration.CodeBuildServiceRole", valid_594264
  var valid_594265 = formData.getOrDefault("ApplicationName")
  valid_594265 = validateParameter(valid_594265, JString, required = true,
                                 default = nil)
  if valid_594265 != nil:
    section.add "ApplicationName", valid_594265
  var valid_594266 = formData.getOrDefault("BuildConfiguration.ArtifactName")
  valid_594266 = validateParameter(valid_594266, JString, required = false,
                                 default = nil)
  if valid_594266 != nil:
    section.add "BuildConfiguration.ArtifactName", valid_594266
  var valid_594267 = formData.getOrDefault("BuildConfiguration.TimeoutInMinutes")
  valid_594267 = validateParameter(valid_594267, JString, required = false,
                                 default = nil)
  if valid_594267 != nil:
    section.add "BuildConfiguration.TimeoutInMinutes", valid_594267
  var valid_594268 = formData.getOrDefault("SourceBuildInformation.SourceRepository")
  valid_594268 = validateParameter(valid_594268, JString, required = false,
                                 default = nil)
  if valid_594268 != nil:
    section.add "SourceBuildInformation.SourceRepository", valid_594268
  var valid_594269 = formData.getOrDefault("Description")
  valid_594269 = validateParameter(valid_594269, JString, required = false,
                                 default = nil)
  if valid_594269 != nil:
    section.add "Description", valid_594269
  var valid_594270 = formData.getOrDefault("BuildConfiguration.Image")
  valid_594270 = validateParameter(valid_594270, JString, required = false,
                                 default = nil)
  if valid_594270 != nil:
    section.add "BuildConfiguration.Image", valid_594270
  var valid_594271 = formData.getOrDefault("Process")
  valid_594271 = validateParameter(valid_594271, JBool, required = false, default = nil)
  if valid_594271 != nil:
    section.add "Process", valid_594271
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594272: Call_PostCreateApplicationVersion_594244; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an application version for the specified application. You can create an application version from a source bundle in Amazon S3, a commit in AWS CodeCommit, or the output of an AWS CodeBuild build as follows:</p> <p>Specify a commit in an AWS CodeCommit repository with <code>SourceBuildInformation</code>.</p> <p>Specify a build in an AWS CodeBuild with <code>SourceBuildInformation</code> and <code>BuildConfiguration</code>.</p> <p>Specify a source bundle in S3 with <code>SourceBundle</code> </p> <p>Omit both <code>SourceBuildInformation</code> and <code>SourceBundle</code> to use the default sample application.</p> <note> <p>Once you create an application version with a specified Amazon S3 bucket and key location, you cannot change that Amazon S3 location. If you change the Amazon S3 location, you receive an exception when you attempt to launch an environment from the application version.</p> </note>
  ## 
  let valid = call_594272.validator(path, query, header, formData, body)
  let scheme = call_594272.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594272.url(scheme.get, call_594272.host, call_594272.base,
                         call_594272.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594272, url, valid)

proc call*(call_594273: Call_PostCreateApplicationVersion_594244;
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
  var query_594274 = newJObject()
  var formData_594275 = newJObject()
  add(formData_594275, "SourceBundle.S3Key", newJString(SourceBundleS3Key))
  add(formData_594275, "VersionLabel", newJString(VersionLabel))
  add(formData_594275, "SourceBundle.S3Bucket", newJString(SourceBundleS3Bucket))
  add(formData_594275, "BuildConfiguration.ComputeType",
      newJString(BuildConfigurationComputeType))
  add(formData_594275, "SourceBuildInformation.SourceType",
      newJString(SourceBuildInformationSourceType))
  if Tags != nil:
    formData_594275.add "Tags", Tags
  add(formData_594275, "AutoCreateApplication", newJBool(AutoCreateApplication))
  add(formData_594275, "SourceBuildInformation.SourceLocation",
      newJString(SourceBuildInformationSourceLocation))
  add(query_594274, "Action", newJString(Action))
  add(formData_594275, "BuildConfiguration.CodeBuildServiceRole",
      newJString(BuildConfigurationCodeBuildServiceRole))
  add(formData_594275, "ApplicationName", newJString(ApplicationName))
  add(formData_594275, "BuildConfiguration.ArtifactName",
      newJString(BuildConfigurationArtifactName))
  add(formData_594275, "BuildConfiguration.TimeoutInMinutes",
      newJString(BuildConfigurationTimeoutInMinutes))
  add(formData_594275, "SourceBuildInformation.SourceRepository",
      newJString(SourceBuildInformationSourceRepository))
  add(formData_594275, "Description", newJString(Description))
  add(formData_594275, "BuildConfiguration.Image",
      newJString(BuildConfigurationImage))
  add(formData_594275, "Process", newJBool(Process))
  add(query_594274, "Version", newJString(Version))
  result = call_594273.call(nil, query_594274, nil, formData_594275, nil)

var postCreateApplicationVersion* = Call_PostCreateApplicationVersion_594244(
    name: "postCreateApplicationVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateApplicationVersion",
    validator: validate_PostCreateApplicationVersion_594245, base: "/",
    url: url_PostCreateApplicationVersion_594246,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateApplicationVersion_594213 = ref object of OpenApiRestCall_593438
proc url_GetCreateApplicationVersion_594215(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateApplicationVersion_594214(path: JsonNode; query: JsonNode;
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
  var valid_594216 = query.getOrDefault("BuildConfiguration.TimeoutInMinutes")
  valid_594216 = validateParameter(valid_594216, JString, required = false,
                                 default = nil)
  if valid_594216 != nil:
    section.add "BuildConfiguration.TimeoutInMinutes", valid_594216
  var valid_594217 = query.getOrDefault("SourceBundle.S3Bucket")
  valid_594217 = validateParameter(valid_594217, JString, required = false,
                                 default = nil)
  if valid_594217 != nil:
    section.add "SourceBundle.S3Bucket", valid_594217
  var valid_594218 = query.getOrDefault("BuildConfiguration.ComputeType")
  valid_594218 = validateParameter(valid_594218, JString, required = false,
                                 default = nil)
  if valid_594218 != nil:
    section.add "BuildConfiguration.ComputeType", valid_594218
  assert query != nil,
        "query argument is necessary due to required `VersionLabel` field"
  var valid_594219 = query.getOrDefault("VersionLabel")
  valid_594219 = validateParameter(valid_594219, JString, required = true,
                                 default = nil)
  if valid_594219 != nil:
    section.add "VersionLabel", valid_594219
  var valid_594220 = query.getOrDefault("BuildConfiguration.ArtifactName")
  valid_594220 = validateParameter(valid_594220, JString, required = false,
                                 default = nil)
  if valid_594220 != nil:
    section.add "BuildConfiguration.ArtifactName", valid_594220
  var valid_594221 = query.getOrDefault("ApplicationName")
  valid_594221 = validateParameter(valid_594221, JString, required = true,
                                 default = nil)
  if valid_594221 != nil:
    section.add "ApplicationName", valid_594221
  var valid_594222 = query.getOrDefault("Description")
  valid_594222 = validateParameter(valid_594222, JString, required = false,
                                 default = nil)
  if valid_594222 != nil:
    section.add "Description", valid_594222
  var valid_594223 = query.getOrDefault("BuildConfiguration.Image")
  valid_594223 = validateParameter(valid_594223, JString, required = false,
                                 default = nil)
  if valid_594223 != nil:
    section.add "BuildConfiguration.Image", valid_594223
  var valid_594224 = query.getOrDefault("SourceBuildInformation.SourceLocation")
  valid_594224 = validateParameter(valid_594224, JString, required = false,
                                 default = nil)
  if valid_594224 != nil:
    section.add "SourceBuildInformation.SourceLocation", valid_594224
  var valid_594225 = query.getOrDefault("SourceBundle.S3Key")
  valid_594225 = validateParameter(valid_594225, JString, required = false,
                                 default = nil)
  if valid_594225 != nil:
    section.add "SourceBundle.S3Key", valid_594225
  var valid_594226 = query.getOrDefault("Tags")
  valid_594226 = validateParameter(valid_594226, JArray, required = false,
                                 default = nil)
  if valid_594226 != nil:
    section.add "Tags", valid_594226
  var valid_594227 = query.getOrDefault("AutoCreateApplication")
  valid_594227 = validateParameter(valid_594227, JBool, required = false, default = nil)
  if valid_594227 != nil:
    section.add "AutoCreateApplication", valid_594227
  var valid_594228 = query.getOrDefault("Action")
  valid_594228 = validateParameter(valid_594228, JString, required = true, default = newJString(
      "CreateApplicationVersion"))
  if valid_594228 != nil:
    section.add "Action", valid_594228
  var valid_594229 = query.getOrDefault("SourceBuildInformation.SourceType")
  valid_594229 = validateParameter(valid_594229, JString, required = false,
                                 default = nil)
  if valid_594229 != nil:
    section.add "SourceBuildInformation.SourceType", valid_594229
  var valid_594230 = query.getOrDefault("BuildConfiguration.CodeBuildServiceRole")
  valid_594230 = validateParameter(valid_594230, JString, required = false,
                                 default = nil)
  if valid_594230 != nil:
    section.add "BuildConfiguration.CodeBuildServiceRole", valid_594230
  var valid_594231 = query.getOrDefault("Process")
  valid_594231 = validateParameter(valid_594231, JBool, required = false, default = nil)
  if valid_594231 != nil:
    section.add "Process", valid_594231
  var valid_594232 = query.getOrDefault("SourceBuildInformation.SourceRepository")
  valid_594232 = validateParameter(valid_594232, JString, required = false,
                                 default = nil)
  if valid_594232 != nil:
    section.add "SourceBuildInformation.SourceRepository", valid_594232
  var valid_594233 = query.getOrDefault("Version")
  valid_594233 = validateParameter(valid_594233, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594233 != nil:
    section.add "Version", valid_594233
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594234 = header.getOrDefault("X-Amz-Date")
  valid_594234 = validateParameter(valid_594234, JString, required = false,
                                 default = nil)
  if valid_594234 != nil:
    section.add "X-Amz-Date", valid_594234
  var valid_594235 = header.getOrDefault("X-Amz-Security-Token")
  valid_594235 = validateParameter(valid_594235, JString, required = false,
                                 default = nil)
  if valid_594235 != nil:
    section.add "X-Amz-Security-Token", valid_594235
  var valid_594236 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594236 = validateParameter(valid_594236, JString, required = false,
                                 default = nil)
  if valid_594236 != nil:
    section.add "X-Amz-Content-Sha256", valid_594236
  var valid_594237 = header.getOrDefault("X-Amz-Algorithm")
  valid_594237 = validateParameter(valid_594237, JString, required = false,
                                 default = nil)
  if valid_594237 != nil:
    section.add "X-Amz-Algorithm", valid_594237
  var valid_594238 = header.getOrDefault("X-Amz-Signature")
  valid_594238 = validateParameter(valid_594238, JString, required = false,
                                 default = nil)
  if valid_594238 != nil:
    section.add "X-Amz-Signature", valid_594238
  var valid_594239 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594239 = validateParameter(valid_594239, JString, required = false,
                                 default = nil)
  if valid_594239 != nil:
    section.add "X-Amz-SignedHeaders", valid_594239
  var valid_594240 = header.getOrDefault("X-Amz-Credential")
  valid_594240 = validateParameter(valid_594240, JString, required = false,
                                 default = nil)
  if valid_594240 != nil:
    section.add "X-Amz-Credential", valid_594240
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594241: Call_GetCreateApplicationVersion_594213; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an application version for the specified application. You can create an application version from a source bundle in Amazon S3, a commit in AWS CodeCommit, or the output of an AWS CodeBuild build as follows:</p> <p>Specify a commit in an AWS CodeCommit repository with <code>SourceBuildInformation</code>.</p> <p>Specify a build in an AWS CodeBuild with <code>SourceBuildInformation</code> and <code>BuildConfiguration</code>.</p> <p>Specify a source bundle in S3 with <code>SourceBundle</code> </p> <p>Omit both <code>SourceBuildInformation</code> and <code>SourceBundle</code> to use the default sample application.</p> <note> <p>Once you create an application version with a specified Amazon S3 bucket and key location, you cannot change that Amazon S3 location. If you change the Amazon S3 location, you receive an exception when you attempt to launch an environment from the application version.</p> </note>
  ## 
  let valid = call_594241.validator(path, query, header, formData, body)
  let scheme = call_594241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594241.url(scheme.get, call_594241.host, call_594241.base,
                         call_594241.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594241, url, valid)

proc call*(call_594242: Call_GetCreateApplicationVersion_594213;
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
  var query_594243 = newJObject()
  add(query_594243, "BuildConfiguration.TimeoutInMinutes",
      newJString(BuildConfigurationTimeoutInMinutes))
  add(query_594243, "SourceBundle.S3Bucket", newJString(SourceBundleS3Bucket))
  add(query_594243, "BuildConfiguration.ComputeType",
      newJString(BuildConfigurationComputeType))
  add(query_594243, "VersionLabel", newJString(VersionLabel))
  add(query_594243, "BuildConfiguration.ArtifactName",
      newJString(BuildConfigurationArtifactName))
  add(query_594243, "ApplicationName", newJString(ApplicationName))
  add(query_594243, "Description", newJString(Description))
  add(query_594243, "BuildConfiguration.Image",
      newJString(BuildConfigurationImage))
  add(query_594243, "SourceBuildInformation.SourceLocation",
      newJString(SourceBuildInformationSourceLocation))
  add(query_594243, "SourceBundle.S3Key", newJString(SourceBundleS3Key))
  if Tags != nil:
    query_594243.add "Tags", Tags
  add(query_594243, "AutoCreateApplication", newJBool(AutoCreateApplication))
  add(query_594243, "Action", newJString(Action))
  add(query_594243, "SourceBuildInformation.SourceType",
      newJString(SourceBuildInformationSourceType))
  add(query_594243, "BuildConfiguration.CodeBuildServiceRole",
      newJString(BuildConfigurationCodeBuildServiceRole))
  add(query_594243, "Process", newJBool(Process))
  add(query_594243, "SourceBuildInformation.SourceRepository",
      newJString(SourceBuildInformationSourceRepository))
  add(query_594243, "Version", newJString(Version))
  result = call_594242.call(nil, query_594243, nil, nil, nil)

var getCreateApplicationVersion* = Call_GetCreateApplicationVersion_594213(
    name: "getCreateApplicationVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateApplicationVersion",
    validator: validate_GetCreateApplicationVersion_594214, base: "/",
    url: url_GetCreateApplicationVersion_594215,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateConfigurationTemplate_594301 = ref object of OpenApiRestCall_593438
proc url_PostCreateConfigurationTemplate_594303(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateConfigurationTemplate_594302(path: JsonNode;
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
  var valid_594304 = query.getOrDefault("Action")
  valid_594304 = validateParameter(valid_594304, JString, required = true, default = newJString(
      "CreateConfigurationTemplate"))
  if valid_594304 != nil:
    section.add "Action", valid_594304
  var valid_594305 = query.getOrDefault("Version")
  valid_594305 = validateParameter(valid_594305, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594305 != nil:
    section.add "Version", valid_594305
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594306 = header.getOrDefault("X-Amz-Date")
  valid_594306 = validateParameter(valid_594306, JString, required = false,
                                 default = nil)
  if valid_594306 != nil:
    section.add "X-Amz-Date", valid_594306
  var valid_594307 = header.getOrDefault("X-Amz-Security-Token")
  valid_594307 = validateParameter(valid_594307, JString, required = false,
                                 default = nil)
  if valid_594307 != nil:
    section.add "X-Amz-Security-Token", valid_594307
  var valid_594308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594308 = validateParameter(valid_594308, JString, required = false,
                                 default = nil)
  if valid_594308 != nil:
    section.add "X-Amz-Content-Sha256", valid_594308
  var valid_594309 = header.getOrDefault("X-Amz-Algorithm")
  valid_594309 = validateParameter(valid_594309, JString, required = false,
                                 default = nil)
  if valid_594309 != nil:
    section.add "X-Amz-Algorithm", valid_594309
  var valid_594310 = header.getOrDefault("X-Amz-Signature")
  valid_594310 = validateParameter(valid_594310, JString, required = false,
                                 default = nil)
  if valid_594310 != nil:
    section.add "X-Amz-Signature", valid_594310
  var valid_594311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594311 = validateParameter(valid_594311, JString, required = false,
                                 default = nil)
  if valid_594311 != nil:
    section.add "X-Amz-SignedHeaders", valid_594311
  var valid_594312 = header.getOrDefault("X-Amz-Credential")
  valid_594312 = validateParameter(valid_594312, JString, required = false,
                                 default = nil)
  if valid_594312 != nil:
    section.add "X-Amz-Credential", valid_594312
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
  var valid_594313 = formData.getOrDefault("OptionSettings")
  valid_594313 = validateParameter(valid_594313, JArray, required = false,
                                 default = nil)
  if valid_594313 != nil:
    section.add "OptionSettings", valid_594313
  var valid_594314 = formData.getOrDefault("Tags")
  valid_594314 = validateParameter(valid_594314, JArray, required = false,
                                 default = nil)
  if valid_594314 != nil:
    section.add "Tags", valid_594314
  var valid_594315 = formData.getOrDefault("SolutionStackName")
  valid_594315 = validateParameter(valid_594315, JString, required = false,
                                 default = nil)
  if valid_594315 != nil:
    section.add "SolutionStackName", valid_594315
  var valid_594316 = formData.getOrDefault("SourceConfiguration.ApplicationName")
  valid_594316 = validateParameter(valid_594316, JString, required = false,
                                 default = nil)
  if valid_594316 != nil:
    section.add "SourceConfiguration.ApplicationName", valid_594316
  var valid_594317 = formData.getOrDefault("EnvironmentId")
  valid_594317 = validateParameter(valid_594317, JString, required = false,
                                 default = nil)
  if valid_594317 != nil:
    section.add "EnvironmentId", valid_594317
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_594318 = formData.getOrDefault("ApplicationName")
  valid_594318 = validateParameter(valid_594318, JString, required = true,
                                 default = nil)
  if valid_594318 != nil:
    section.add "ApplicationName", valid_594318
  var valid_594319 = formData.getOrDefault("PlatformArn")
  valid_594319 = validateParameter(valid_594319, JString, required = false,
                                 default = nil)
  if valid_594319 != nil:
    section.add "PlatformArn", valid_594319
  var valid_594320 = formData.getOrDefault("TemplateName")
  valid_594320 = validateParameter(valid_594320, JString, required = true,
                                 default = nil)
  if valid_594320 != nil:
    section.add "TemplateName", valid_594320
  var valid_594321 = formData.getOrDefault("Description")
  valid_594321 = validateParameter(valid_594321, JString, required = false,
                                 default = nil)
  if valid_594321 != nil:
    section.add "Description", valid_594321
  var valid_594322 = formData.getOrDefault("SourceConfiguration.TemplateName")
  valid_594322 = validateParameter(valid_594322, JString, required = false,
                                 default = nil)
  if valid_594322 != nil:
    section.add "SourceConfiguration.TemplateName", valid_594322
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594323: Call_PostCreateConfigurationTemplate_594301;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a configuration template. Templates are associated with a specific application and are used to deploy different versions of the application with the same configuration settings.</p> <p>Templates aren't associated with any environment. The <code>EnvironmentName</code> response element is always <code>null</code>.</p> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> <li> <p> <a>DescribeConfigurationSettings</a> </p> </li> <li> <p> <a>ListAvailableSolutionStacks</a> </p> </li> </ul>
  ## 
  let valid = call_594323.validator(path, query, header, formData, body)
  let scheme = call_594323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594323.url(scheme.get, call_594323.host, call_594323.base,
                         call_594323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594323, url, valid)

proc call*(call_594324: Call_PostCreateConfigurationTemplate_594301;
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
  var query_594325 = newJObject()
  var formData_594326 = newJObject()
  if OptionSettings != nil:
    formData_594326.add "OptionSettings", OptionSettings
  if Tags != nil:
    formData_594326.add "Tags", Tags
  add(formData_594326, "SolutionStackName", newJString(SolutionStackName))
  add(formData_594326, "SourceConfiguration.ApplicationName",
      newJString(SourceConfigurationApplicationName))
  add(formData_594326, "EnvironmentId", newJString(EnvironmentId))
  add(query_594325, "Action", newJString(Action))
  add(formData_594326, "ApplicationName", newJString(ApplicationName))
  add(formData_594326, "PlatformArn", newJString(PlatformArn))
  add(formData_594326, "TemplateName", newJString(TemplateName))
  add(query_594325, "Version", newJString(Version))
  add(formData_594326, "Description", newJString(Description))
  add(formData_594326, "SourceConfiguration.TemplateName",
      newJString(SourceConfigurationTemplateName))
  result = call_594324.call(nil, query_594325, nil, formData_594326, nil)

var postCreateConfigurationTemplate* = Call_PostCreateConfigurationTemplate_594301(
    name: "postCreateConfigurationTemplate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateConfigurationTemplate",
    validator: validate_PostCreateConfigurationTemplate_594302, base: "/",
    url: url_PostCreateConfigurationTemplate_594303,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateConfigurationTemplate_594276 = ref object of OpenApiRestCall_593438
proc url_GetCreateConfigurationTemplate_594278(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateConfigurationTemplate_594277(path: JsonNode;
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
  var valid_594279 = query.getOrDefault("SourceConfiguration.ApplicationName")
  valid_594279 = validateParameter(valid_594279, JString, required = false,
                                 default = nil)
  if valid_594279 != nil:
    section.add "SourceConfiguration.ApplicationName", valid_594279
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_594280 = query.getOrDefault("ApplicationName")
  valid_594280 = validateParameter(valid_594280, JString, required = true,
                                 default = nil)
  if valid_594280 != nil:
    section.add "ApplicationName", valid_594280
  var valid_594281 = query.getOrDefault("Description")
  valid_594281 = validateParameter(valid_594281, JString, required = false,
                                 default = nil)
  if valid_594281 != nil:
    section.add "Description", valid_594281
  var valid_594282 = query.getOrDefault("PlatformArn")
  valid_594282 = validateParameter(valid_594282, JString, required = false,
                                 default = nil)
  if valid_594282 != nil:
    section.add "PlatformArn", valid_594282
  var valid_594283 = query.getOrDefault("Tags")
  valid_594283 = validateParameter(valid_594283, JArray, required = false,
                                 default = nil)
  if valid_594283 != nil:
    section.add "Tags", valid_594283
  var valid_594284 = query.getOrDefault("Action")
  valid_594284 = validateParameter(valid_594284, JString, required = true, default = newJString(
      "CreateConfigurationTemplate"))
  if valid_594284 != nil:
    section.add "Action", valid_594284
  var valid_594285 = query.getOrDefault("SolutionStackName")
  valid_594285 = validateParameter(valid_594285, JString, required = false,
                                 default = nil)
  if valid_594285 != nil:
    section.add "SolutionStackName", valid_594285
  var valid_594286 = query.getOrDefault("EnvironmentId")
  valid_594286 = validateParameter(valid_594286, JString, required = false,
                                 default = nil)
  if valid_594286 != nil:
    section.add "EnvironmentId", valid_594286
  var valid_594287 = query.getOrDefault("TemplateName")
  valid_594287 = validateParameter(valid_594287, JString, required = true,
                                 default = nil)
  if valid_594287 != nil:
    section.add "TemplateName", valid_594287
  var valid_594288 = query.getOrDefault("OptionSettings")
  valid_594288 = validateParameter(valid_594288, JArray, required = false,
                                 default = nil)
  if valid_594288 != nil:
    section.add "OptionSettings", valid_594288
  var valid_594289 = query.getOrDefault("Version")
  valid_594289 = validateParameter(valid_594289, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594289 != nil:
    section.add "Version", valid_594289
  var valid_594290 = query.getOrDefault("SourceConfiguration.TemplateName")
  valid_594290 = validateParameter(valid_594290, JString, required = false,
                                 default = nil)
  if valid_594290 != nil:
    section.add "SourceConfiguration.TemplateName", valid_594290
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594291 = header.getOrDefault("X-Amz-Date")
  valid_594291 = validateParameter(valid_594291, JString, required = false,
                                 default = nil)
  if valid_594291 != nil:
    section.add "X-Amz-Date", valid_594291
  var valid_594292 = header.getOrDefault("X-Amz-Security-Token")
  valid_594292 = validateParameter(valid_594292, JString, required = false,
                                 default = nil)
  if valid_594292 != nil:
    section.add "X-Amz-Security-Token", valid_594292
  var valid_594293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594293 = validateParameter(valid_594293, JString, required = false,
                                 default = nil)
  if valid_594293 != nil:
    section.add "X-Amz-Content-Sha256", valid_594293
  var valid_594294 = header.getOrDefault("X-Amz-Algorithm")
  valid_594294 = validateParameter(valid_594294, JString, required = false,
                                 default = nil)
  if valid_594294 != nil:
    section.add "X-Amz-Algorithm", valid_594294
  var valid_594295 = header.getOrDefault("X-Amz-Signature")
  valid_594295 = validateParameter(valid_594295, JString, required = false,
                                 default = nil)
  if valid_594295 != nil:
    section.add "X-Amz-Signature", valid_594295
  var valid_594296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594296 = validateParameter(valid_594296, JString, required = false,
                                 default = nil)
  if valid_594296 != nil:
    section.add "X-Amz-SignedHeaders", valid_594296
  var valid_594297 = header.getOrDefault("X-Amz-Credential")
  valid_594297 = validateParameter(valid_594297, JString, required = false,
                                 default = nil)
  if valid_594297 != nil:
    section.add "X-Amz-Credential", valid_594297
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594298: Call_GetCreateConfigurationTemplate_594276; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a configuration template. Templates are associated with a specific application and are used to deploy different versions of the application with the same configuration settings.</p> <p>Templates aren't associated with any environment. The <code>EnvironmentName</code> response element is always <code>null</code>.</p> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> <li> <p> <a>DescribeConfigurationSettings</a> </p> </li> <li> <p> <a>ListAvailableSolutionStacks</a> </p> </li> </ul>
  ## 
  let valid = call_594298.validator(path, query, header, formData, body)
  let scheme = call_594298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594298.url(scheme.get, call_594298.host, call_594298.base,
                         call_594298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594298, url, valid)

proc call*(call_594299: Call_GetCreateConfigurationTemplate_594276;
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
  var query_594300 = newJObject()
  add(query_594300, "SourceConfiguration.ApplicationName",
      newJString(SourceConfigurationApplicationName))
  add(query_594300, "ApplicationName", newJString(ApplicationName))
  add(query_594300, "Description", newJString(Description))
  add(query_594300, "PlatformArn", newJString(PlatformArn))
  if Tags != nil:
    query_594300.add "Tags", Tags
  add(query_594300, "Action", newJString(Action))
  add(query_594300, "SolutionStackName", newJString(SolutionStackName))
  add(query_594300, "EnvironmentId", newJString(EnvironmentId))
  add(query_594300, "TemplateName", newJString(TemplateName))
  if OptionSettings != nil:
    query_594300.add "OptionSettings", OptionSettings
  add(query_594300, "Version", newJString(Version))
  add(query_594300, "SourceConfiguration.TemplateName",
      newJString(SourceConfigurationTemplateName))
  result = call_594299.call(nil, query_594300, nil, nil, nil)

var getCreateConfigurationTemplate* = Call_GetCreateConfigurationTemplate_594276(
    name: "getCreateConfigurationTemplate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateConfigurationTemplate",
    validator: validate_GetCreateConfigurationTemplate_594277, base: "/",
    url: url_GetCreateConfigurationTemplate_594278,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEnvironment_594357 = ref object of OpenApiRestCall_593438
proc url_PostCreateEnvironment_594359(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateEnvironment_594358(path: JsonNode; query: JsonNode;
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
  var valid_594360 = query.getOrDefault("Action")
  valid_594360 = validateParameter(valid_594360, JString, required = true,
                                 default = newJString("CreateEnvironment"))
  if valid_594360 != nil:
    section.add "Action", valid_594360
  var valid_594361 = query.getOrDefault("Version")
  valid_594361 = validateParameter(valid_594361, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594361 != nil:
    section.add "Version", valid_594361
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594362 = header.getOrDefault("X-Amz-Date")
  valid_594362 = validateParameter(valid_594362, JString, required = false,
                                 default = nil)
  if valid_594362 != nil:
    section.add "X-Amz-Date", valid_594362
  var valid_594363 = header.getOrDefault("X-Amz-Security-Token")
  valid_594363 = validateParameter(valid_594363, JString, required = false,
                                 default = nil)
  if valid_594363 != nil:
    section.add "X-Amz-Security-Token", valid_594363
  var valid_594364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594364 = validateParameter(valid_594364, JString, required = false,
                                 default = nil)
  if valid_594364 != nil:
    section.add "X-Amz-Content-Sha256", valid_594364
  var valid_594365 = header.getOrDefault("X-Amz-Algorithm")
  valid_594365 = validateParameter(valid_594365, JString, required = false,
                                 default = nil)
  if valid_594365 != nil:
    section.add "X-Amz-Algorithm", valid_594365
  var valid_594366 = header.getOrDefault("X-Amz-Signature")
  valid_594366 = validateParameter(valid_594366, JString, required = false,
                                 default = nil)
  if valid_594366 != nil:
    section.add "X-Amz-Signature", valid_594366
  var valid_594367 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594367 = validateParameter(valid_594367, JString, required = false,
                                 default = nil)
  if valid_594367 != nil:
    section.add "X-Amz-SignedHeaders", valid_594367
  var valid_594368 = header.getOrDefault("X-Amz-Credential")
  valid_594368 = validateParameter(valid_594368, JString, required = false,
                                 default = nil)
  if valid_594368 != nil:
    section.add "X-Amz-Credential", valid_594368
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
  var valid_594369 = formData.getOrDefault("Tier.Name")
  valid_594369 = validateParameter(valid_594369, JString, required = false,
                                 default = nil)
  if valid_594369 != nil:
    section.add "Tier.Name", valid_594369
  var valid_594370 = formData.getOrDefault("OptionsToRemove")
  valid_594370 = validateParameter(valid_594370, JArray, required = false,
                                 default = nil)
  if valid_594370 != nil:
    section.add "OptionsToRemove", valid_594370
  var valid_594371 = formData.getOrDefault("VersionLabel")
  valid_594371 = validateParameter(valid_594371, JString, required = false,
                                 default = nil)
  if valid_594371 != nil:
    section.add "VersionLabel", valid_594371
  var valid_594372 = formData.getOrDefault("OptionSettings")
  valid_594372 = validateParameter(valid_594372, JArray, required = false,
                                 default = nil)
  if valid_594372 != nil:
    section.add "OptionSettings", valid_594372
  var valid_594373 = formData.getOrDefault("GroupName")
  valid_594373 = validateParameter(valid_594373, JString, required = false,
                                 default = nil)
  if valid_594373 != nil:
    section.add "GroupName", valid_594373
  var valid_594374 = formData.getOrDefault("Tags")
  valid_594374 = validateParameter(valid_594374, JArray, required = false,
                                 default = nil)
  if valid_594374 != nil:
    section.add "Tags", valid_594374
  var valid_594375 = formData.getOrDefault("CNAMEPrefix")
  valid_594375 = validateParameter(valid_594375, JString, required = false,
                                 default = nil)
  if valid_594375 != nil:
    section.add "CNAMEPrefix", valid_594375
  var valid_594376 = formData.getOrDefault("SolutionStackName")
  valid_594376 = validateParameter(valid_594376, JString, required = false,
                                 default = nil)
  if valid_594376 != nil:
    section.add "SolutionStackName", valid_594376
  var valid_594377 = formData.getOrDefault("EnvironmentName")
  valid_594377 = validateParameter(valid_594377, JString, required = false,
                                 default = nil)
  if valid_594377 != nil:
    section.add "EnvironmentName", valid_594377
  var valid_594378 = formData.getOrDefault("Tier.Type")
  valid_594378 = validateParameter(valid_594378, JString, required = false,
                                 default = nil)
  if valid_594378 != nil:
    section.add "Tier.Type", valid_594378
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_594379 = formData.getOrDefault("ApplicationName")
  valid_594379 = validateParameter(valid_594379, JString, required = true,
                                 default = nil)
  if valid_594379 != nil:
    section.add "ApplicationName", valid_594379
  var valid_594380 = formData.getOrDefault("PlatformArn")
  valid_594380 = validateParameter(valid_594380, JString, required = false,
                                 default = nil)
  if valid_594380 != nil:
    section.add "PlatformArn", valid_594380
  var valid_594381 = formData.getOrDefault("TemplateName")
  valid_594381 = validateParameter(valid_594381, JString, required = false,
                                 default = nil)
  if valid_594381 != nil:
    section.add "TemplateName", valid_594381
  var valid_594382 = formData.getOrDefault("Description")
  valid_594382 = validateParameter(valid_594382, JString, required = false,
                                 default = nil)
  if valid_594382 != nil:
    section.add "Description", valid_594382
  var valid_594383 = formData.getOrDefault("Tier.Version")
  valid_594383 = validateParameter(valid_594383, JString, required = false,
                                 default = nil)
  if valid_594383 != nil:
    section.add "Tier.Version", valid_594383
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594384: Call_PostCreateEnvironment_594357; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Launches an environment for the specified application using the specified configuration.
  ## 
  let valid = call_594384.validator(path, query, header, formData, body)
  let scheme = call_594384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594384.url(scheme.get, call_594384.host, call_594384.base,
                         call_594384.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594384, url, valid)

proc call*(call_594385: Call_PostCreateEnvironment_594357; ApplicationName: string;
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
  var query_594386 = newJObject()
  var formData_594387 = newJObject()
  add(formData_594387, "Tier.Name", newJString(TierName))
  if OptionsToRemove != nil:
    formData_594387.add "OptionsToRemove", OptionsToRemove
  add(formData_594387, "VersionLabel", newJString(VersionLabel))
  if OptionSettings != nil:
    formData_594387.add "OptionSettings", OptionSettings
  add(formData_594387, "GroupName", newJString(GroupName))
  if Tags != nil:
    formData_594387.add "Tags", Tags
  add(formData_594387, "CNAMEPrefix", newJString(CNAMEPrefix))
  add(formData_594387, "SolutionStackName", newJString(SolutionStackName))
  add(formData_594387, "EnvironmentName", newJString(EnvironmentName))
  add(formData_594387, "Tier.Type", newJString(TierType))
  add(query_594386, "Action", newJString(Action))
  add(formData_594387, "ApplicationName", newJString(ApplicationName))
  add(formData_594387, "PlatformArn", newJString(PlatformArn))
  add(formData_594387, "TemplateName", newJString(TemplateName))
  add(query_594386, "Version", newJString(Version))
  add(formData_594387, "Description", newJString(Description))
  add(formData_594387, "Tier.Version", newJString(TierVersion))
  result = call_594385.call(nil, query_594386, nil, formData_594387, nil)

var postCreateEnvironment* = Call_PostCreateEnvironment_594357(
    name: "postCreateEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateEnvironment",
    validator: validate_PostCreateEnvironment_594358, base: "/",
    url: url_PostCreateEnvironment_594359, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEnvironment_594327 = ref object of OpenApiRestCall_593438
proc url_GetCreateEnvironment_594329(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateEnvironment_594328(path: JsonNode; query: JsonNode;
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
  var valid_594330 = query.getOrDefault("Tier.Name")
  valid_594330 = validateParameter(valid_594330, JString, required = false,
                                 default = nil)
  if valid_594330 != nil:
    section.add "Tier.Name", valid_594330
  var valid_594331 = query.getOrDefault("VersionLabel")
  valid_594331 = validateParameter(valid_594331, JString, required = false,
                                 default = nil)
  if valid_594331 != nil:
    section.add "VersionLabel", valid_594331
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_594332 = query.getOrDefault("ApplicationName")
  valid_594332 = validateParameter(valid_594332, JString, required = true,
                                 default = nil)
  if valid_594332 != nil:
    section.add "ApplicationName", valid_594332
  var valid_594333 = query.getOrDefault("Description")
  valid_594333 = validateParameter(valid_594333, JString, required = false,
                                 default = nil)
  if valid_594333 != nil:
    section.add "Description", valid_594333
  var valid_594334 = query.getOrDefault("OptionsToRemove")
  valid_594334 = validateParameter(valid_594334, JArray, required = false,
                                 default = nil)
  if valid_594334 != nil:
    section.add "OptionsToRemove", valid_594334
  var valid_594335 = query.getOrDefault("PlatformArn")
  valid_594335 = validateParameter(valid_594335, JString, required = false,
                                 default = nil)
  if valid_594335 != nil:
    section.add "PlatformArn", valid_594335
  var valid_594336 = query.getOrDefault("Tags")
  valid_594336 = validateParameter(valid_594336, JArray, required = false,
                                 default = nil)
  if valid_594336 != nil:
    section.add "Tags", valid_594336
  var valid_594337 = query.getOrDefault("EnvironmentName")
  valid_594337 = validateParameter(valid_594337, JString, required = false,
                                 default = nil)
  if valid_594337 != nil:
    section.add "EnvironmentName", valid_594337
  var valid_594338 = query.getOrDefault("Action")
  valid_594338 = validateParameter(valid_594338, JString, required = true,
                                 default = newJString("CreateEnvironment"))
  if valid_594338 != nil:
    section.add "Action", valid_594338
  var valid_594339 = query.getOrDefault("SolutionStackName")
  valid_594339 = validateParameter(valid_594339, JString, required = false,
                                 default = nil)
  if valid_594339 != nil:
    section.add "SolutionStackName", valid_594339
  var valid_594340 = query.getOrDefault("Tier.Version")
  valid_594340 = validateParameter(valid_594340, JString, required = false,
                                 default = nil)
  if valid_594340 != nil:
    section.add "Tier.Version", valid_594340
  var valid_594341 = query.getOrDefault("TemplateName")
  valid_594341 = validateParameter(valid_594341, JString, required = false,
                                 default = nil)
  if valid_594341 != nil:
    section.add "TemplateName", valid_594341
  var valid_594342 = query.getOrDefault("GroupName")
  valid_594342 = validateParameter(valid_594342, JString, required = false,
                                 default = nil)
  if valid_594342 != nil:
    section.add "GroupName", valid_594342
  var valid_594343 = query.getOrDefault("OptionSettings")
  valid_594343 = validateParameter(valid_594343, JArray, required = false,
                                 default = nil)
  if valid_594343 != nil:
    section.add "OptionSettings", valid_594343
  var valid_594344 = query.getOrDefault("Tier.Type")
  valid_594344 = validateParameter(valid_594344, JString, required = false,
                                 default = nil)
  if valid_594344 != nil:
    section.add "Tier.Type", valid_594344
  var valid_594345 = query.getOrDefault("Version")
  valid_594345 = validateParameter(valid_594345, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594345 != nil:
    section.add "Version", valid_594345
  var valid_594346 = query.getOrDefault("CNAMEPrefix")
  valid_594346 = validateParameter(valid_594346, JString, required = false,
                                 default = nil)
  if valid_594346 != nil:
    section.add "CNAMEPrefix", valid_594346
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594347 = header.getOrDefault("X-Amz-Date")
  valid_594347 = validateParameter(valid_594347, JString, required = false,
                                 default = nil)
  if valid_594347 != nil:
    section.add "X-Amz-Date", valid_594347
  var valid_594348 = header.getOrDefault("X-Amz-Security-Token")
  valid_594348 = validateParameter(valid_594348, JString, required = false,
                                 default = nil)
  if valid_594348 != nil:
    section.add "X-Amz-Security-Token", valid_594348
  var valid_594349 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594349 = validateParameter(valid_594349, JString, required = false,
                                 default = nil)
  if valid_594349 != nil:
    section.add "X-Amz-Content-Sha256", valid_594349
  var valid_594350 = header.getOrDefault("X-Amz-Algorithm")
  valid_594350 = validateParameter(valid_594350, JString, required = false,
                                 default = nil)
  if valid_594350 != nil:
    section.add "X-Amz-Algorithm", valid_594350
  var valid_594351 = header.getOrDefault("X-Amz-Signature")
  valid_594351 = validateParameter(valid_594351, JString, required = false,
                                 default = nil)
  if valid_594351 != nil:
    section.add "X-Amz-Signature", valid_594351
  var valid_594352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594352 = validateParameter(valid_594352, JString, required = false,
                                 default = nil)
  if valid_594352 != nil:
    section.add "X-Amz-SignedHeaders", valid_594352
  var valid_594353 = header.getOrDefault("X-Amz-Credential")
  valid_594353 = validateParameter(valid_594353, JString, required = false,
                                 default = nil)
  if valid_594353 != nil:
    section.add "X-Amz-Credential", valid_594353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594354: Call_GetCreateEnvironment_594327; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Launches an environment for the specified application using the specified configuration.
  ## 
  let valid = call_594354.validator(path, query, header, formData, body)
  let scheme = call_594354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594354.url(scheme.get, call_594354.host, call_594354.base,
                         call_594354.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594354, url, valid)

proc call*(call_594355: Call_GetCreateEnvironment_594327; ApplicationName: string;
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
  var query_594356 = newJObject()
  add(query_594356, "Tier.Name", newJString(TierName))
  add(query_594356, "VersionLabel", newJString(VersionLabel))
  add(query_594356, "ApplicationName", newJString(ApplicationName))
  add(query_594356, "Description", newJString(Description))
  if OptionsToRemove != nil:
    query_594356.add "OptionsToRemove", OptionsToRemove
  add(query_594356, "PlatformArn", newJString(PlatformArn))
  if Tags != nil:
    query_594356.add "Tags", Tags
  add(query_594356, "EnvironmentName", newJString(EnvironmentName))
  add(query_594356, "Action", newJString(Action))
  add(query_594356, "SolutionStackName", newJString(SolutionStackName))
  add(query_594356, "Tier.Version", newJString(TierVersion))
  add(query_594356, "TemplateName", newJString(TemplateName))
  add(query_594356, "GroupName", newJString(GroupName))
  if OptionSettings != nil:
    query_594356.add "OptionSettings", OptionSettings
  add(query_594356, "Tier.Type", newJString(TierType))
  add(query_594356, "Version", newJString(Version))
  add(query_594356, "CNAMEPrefix", newJString(CNAMEPrefix))
  result = call_594355.call(nil, query_594356, nil, nil, nil)

var getCreateEnvironment* = Call_GetCreateEnvironment_594327(
    name: "getCreateEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateEnvironment",
    validator: validate_GetCreateEnvironment_594328, base: "/",
    url: url_GetCreateEnvironment_594329, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreatePlatformVersion_594410 = ref object of OpenApiRestCall_593438
proc url_PostCreatePlatformVersion_594412(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreatePlatformVersion_594411(path: JsonNode; query: JsonNode;
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
  var valid_594413 = query.getOrDefault("Action")
  valid_594413 = validateParameter(valid_594413, JString, required = true,
                                 default = newJString("CreatePlatformVersion"))
  if valid_594413 != nil:
    section.add "Action", valid_594413
  var valid_594414 = query.getOrDefault("Version")
  valid_594414 = validateParameter(valid_594414, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594414 != nil:
    section.add "Version", valid_594414
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594415 = header.getOrDefault("X-Amz-Date")
  valid_594415 = validateParameter(valid_594415, JString, required = false,
                                 default = nil)
  if valid_594415 != nil:
    section.add "X-Amz-Date", valid_594415
  var valid_594416 = header.getOrDefault("X-Amz-Security-Token")
  valid_594416 = validateParameter(valid_594416, JString, required = false,
                                 default = nil)
  if valid_594416 != nil:
    section.add "X-Amz-Security-Token", valid_594416
  var valid_594417 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594417 = validateParameter(valid_594417, JString, required = false,
                                 default = nil)
  if valid_594417 != nil:
    section.add "X-Amz-Content-Sha256", valid_594417
  var valid_594418 = header.getOrDefault("X-Amz-Algorithm")
  valid_594418 = validateParameter(valid_594418, JString, required = false,
                                 default = nil)
  if valid_594418 != nil:
    section.add "X-Amz-Algorithm", valid_594418
  var valid_594419 = header.getOrDefault("X-Amz-Signature")
  valid_594419 = validateParameter(valid_594419, JString, required = false,
                                 default = nil)
  if valid_594419 != nil:
    section.add "X-Amz-Signature", valid_594419
  var valid_594420 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594420 = validateParameter(valid_594420, JString, required = false,
                                 default = nil)
  if valid_594420 != nil:
    section.add "X-Amz-SignedHeaders", valid_594420
  var valid_594421 = header.getOrDefault("X-Amz-Credential")
  valid_594421 = validateParameter(valid_594421, JString, required = false,
                                 default = nil)
  if valid_594421 != nil:
    section.add "X-Amz-Credential", valid_594421
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
  var valid_594422 = formData.getOrDefault("PlatformName")
  valid_594422 = validateParameter(valid_594422, JString, required = true,
                                 default = nil)
  if valid_594422 != nil:
    section.add "PlatformName", valid_594422
  var valid_594423 = formData.getOrDefault("PlatformDefinitionBundle.S3Key")
  valid_594423 = validateParameter(valid_594423, JString, required = false,
                                 default = nil)
  if valid_594423 != nil:
    section.add "PlatformDefinitionBundle.S3Key", valid_594423
  var valid_594424 = formData.getOrDefault("OptionSettings")
  valid_594424 = validateParameter(valid_594424, JArray, required = false,
                                 default = nil)
  if valid_594424 != nil:
    section.add "OptionSettings", valid_594424
  var valid_594425 = formData.getOrDefault("Tags")
  valid_594425 = validateParameter(valid_594425, JArray, required = false,
                                 default = nil)
  if valid_594425 != nil:
    section.add "Tags", valid_594425
  var valid_594426 = formData.getOrDefault("EnvironmentName")
  valid_594426 = validateParameter(valid_594426, JString, required = false,
                                 default = nil)
  if valid_594426 != nil:
    section.add "EnvironmentName", valid_594426
  var valid_594427 = formData.getOrDefault("PlatformDefinitionBundle.S3Bucket")
  valid_594427 = validateParameter(valid_594427, JString, required = false,
                                 default = nil)
  if valid_594427 != nil:
    section.add "PlatformDefinitionBundle.S3Bucket", valid_594427
  var valid_594428 = formData.getOrDefault("PlatformVersion")
  valid_594428 = validateParameter(valid_594428, JString, required = true,
                                 default = nil)
  if valid_594428 != nil:
    section.add "PlatformVersion", valid_594428
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594429: Call_PostCreatePlatformVersion_594410; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new version of your custom platform.
  ## 
  let valid = call_594429.validator(path, query, header, formData, body)
  let scheme = call_594429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594429.url(scheme.get, call_594429.host, call_594429.base,
                         call_594429.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594429, url, valid)

proc call*(call_594430: Call_PostCreatePlatformVersion_594410;
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
  var query_594431 = newJObject()
  var formData_594432 = newJObject()
  add(formData_594432, "PlatformName", newJString(PlatformName))
  add(formData_594432, "PlatformDefinitionBundle.S3Key",
      newJString(PlatformDefinitionBundleS3Key))
  if OptionSettings != nil:
    formData_594432.add "OptionSettings", OptionSettings
  if Tags != nil:
    formData_594432.add "Tags", Tags
  add(formData_594432, "EnvironmentName", newJString(EnvironmentName))
  add(formData_594432, "PlatformDefinitionBundle.S3Bucket",
      newJString(PlatformDefinitionBundleS3Bucket))
  add(query_594431, "Action", newJString(Action))
  add(formData_594432, "PlatformVersion", newJString(PlatformVersion))
  add(query_594431, "Version", newJString(Version))
  result = call_594430.call(nil, query_594431, nil, formData_594432, nil)

var postCreatePlatformVersion* = Call_PostCreatePlatformVersion_594410(
    name: "postCreatePlatformVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreatePlatformVersion",
    validator: validate_PostCreatePlatformVersion_594411, base: "/",
    url: url_PostCreatePlatformVersion_594412,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreatePlatformVersion_594388 = ref object of OpenApiRestCall_593438
proc url_GetCreatePlatformVersion_594390(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreatePlatformVersion_594389(path: JsonNode; query: JsonNode;
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
  var valid_594391 = query.getOrDefault("Tags")
  valid_594391 = validateParameter(valid_594391, JArray, required = false,
                                 default = nil)
  if valid_594391 != nil:
    section.add "Tags", valid_594391
  var valid_594392 = query.getOrDefault("EnvironmentName")
  valid_594392 = validateParameter(valid_594392, JString, required = false,
                                 default = nil)
  if valid_594392 != nil:
    section.add "EnvironmentName", valid_594392
  var valid_594393 = query.getOrDefault("PlatformDefinitionBundle.S3Key")
  valid_594393 = validateParameter(valid_594393, JString, required = false,
                                 default = nil)
  if valid_594393 != nil:
    section.add "PlatformDefinitionBundle.S3Key", valid_594393
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594394 = query.getOrDefault("Action")
  valid_594394 = validateParameter(valid_594394, JString, required = true,
                                 default = newJString("CreatePlatformVersion"))
  if valid_594394 != nil:
    section.add "Action", valid_594394
  var valid_594395 = query.getOrDefault("OptionSettings")
  valid_594395 = validateParameter(valid_594395, JArray, required = false,
                                 default = nil)
  if valid_594395 != nil:
    section.add "OptionSettings", valid_594395
  var valid_594396 = query.getOrDefault("PlatformName")
  valid_594396 = validateParameter(valid_594396, JString, required = true,
                                 default = nil)
  if valid_594396 != nil:
    section.add "PlatformName", valid_594396
  var valid_594397 = query.getOrDefault("Version")
  valid_594397 = validateParameter(valid_594397, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594397 != nil:
    section.add "Version", valid_594397
  var valid_594398 = query.getOrDefault("PlatformDefinitionBundle.S3Bucket")
  valid_594398 = validateParameter(valid_594398, JString, required = false,
                                 default = nil)
  if valid_594398 != nil:
    section.add "PlatformDefinitionBundle.S3Bucket", valid_594398
  var valid_594399 = query.getOrDefault("PlatformVersion")
  valid_594399 = validateParameter(valid_594399, JString, required = true,
                                 default = nil)
  if valid_594399 != nil:
    section.add "PlatformVersion", valid_594399
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594400 = header.getOrDefault("X-Amz-Date")
  valid_594400 = validateParameter(valid_594400, JString, required = false,
                                 default = nil)
  if valid_594400 != nil:
    section.add "X-Amz-Date", valid_594400
  var valid_594401 = header.getOrDefault("X-Amz-Security-Token")
  valid_594401 = validateParameter(valid_594401, JString, required = false,
                                 default = nil)
  if valid_594401 != nil:
    section.add "X-Amz-Security-Token", valid_594401
  var valid_594402 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594402 = validateParameter(valid_594402, JString, required = false,
                                 default = nil)
  if valid_594402 != nil:
    section.add "X-Amz-Content-Sha256", valid_594402
  var valid_594403 = header.getOrDefault("X-Amz-Algorithm")
  valid_594403 = validateParameter(valid_594403, JString, required = false,
                                 default = nil)
  if valid_594403 != nil:
    section.add "X-Amz-Algorithm", valid_594403
  var valid_594404 = header.getOrDefault("X-Amz-Signature")
  valid_594404 = validateParameter(valid_594404, JString, required = false,
                                 default = nil)
  if valid_594404 != nil:
    section.add "X-Amz-Signature", valid_594404
  var valid_594405 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594405 = validateParameter(valid_594405, JString, required = false,
                                 default = nil)
  if valid_594405 != nil:
    section.add "X-Amz-SignedHeaders", valid_594405
  var valid_594406 = header.getOrDefault("X-Amz-Credential")
  valid_594406 = validateParameter(valid_594406, JString, required = false,
                                 default = nil)
  if valid_594406 != nil:
    section.add "X-Amz-Credential", valid_594406
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594407: Call_GetCreatePlatformVersion_594388; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new version of your custom platform.
  ## 
  let valid = call_594407.validator(path, query, header, formData, body)
  let scheme = call_594407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594407.url(scheme.get, call_594407.host, call_594407.base,
                         call_594407.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594407, url, valid)

proc call*(call_594408: Call_GetCreatePlatformVersion_594388; PlatformName: string;
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
  var query_594409 = newJObject()
  if Tags != nil:
    query_594409.add "Tags", Tags
  add(query_594409, "EnvironmentName", newJString(EnvironmentName))
  add(query_594409, "PlatformDefinitionBundle.S3Key",
      newJString(PlatformDefinitionBundleS3Key))
  add(query_594409, "Action", newJString(Action))
  if OptionSettings != nil:
    query_594409.add "OptionSettings", OptionSettings
  add(query_594409, "PlatformName", newJString(PlatformName))
  add(query_594409, "Version", newJString(Version))
  add(query_594409, "PlatformDefinitionBundle.S3Bucket",
      newJString(PlatformDefinitionBundleS3Bucket))
  add(query_594409, "PlatformVersion", newJString(PlatformVersion))
  result = call_594408.call(nil, query_594409, nil, nil, nil)

var getCreatePlatformVersion* = Call_GetCreatePlatformVersion_594388(
    name: "getCreatePlatformVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreatePlatformVersion",
    validator: validate_GetCreatePlatformVersion_594389, base: "/",
    url: url_GetCreatePlatformVersion_594390, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateStorageLocation_594448 = ref object of OpenApiRestCall_593438
proc url_PostCreateStorageLocation_594450(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateStorageLocation_594449(path: JsonNode; query: JsonNode;
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
  var valid_594451 = query.getOrDefault("Action")
  valid_594451 = validateParameter(valid_594451, JString, required = true,
                                 default = newJString("CreateStorageLocation"))
  if valid_594451 != nil:
    section.add "Action", valid_594451
  var valid_594452 = query.getOrDefault("Version")
  valid_594452 = validateParameter(valid_594452, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594452 != nil:
    section.add "Version", valid_594452
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594453 = header.getOrDefault("X-Amz-Date")
  valid_594453 = validateParameter(valid_594453, JString, required = false,
                                 default = nil)
  if valid_594453 != nil:
    section.add "X-Amz-Date", valid_594453
  var valid_594454 = header.getOrDefault("X-Amz-Security-Token")
  valid_594454 = validateParameter(valid_594454, JString, required = false,
                                 default = nil)
  if valid_594454 != nil:
    section.add "X-Amz-Security-Token", valid_594454
  var valid_594455 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594455 = validateParameter(valid_594455, JString, required = false,
                                 default = nil)
  if valid_594455 != nil:
    section.add "X-Amz-Content-Sha256", valid_594455
  var valid_594456 = header.getOrDefault("X-Amz-Algorithm")
  valid_594456 = validateParameter(valid_594456, JString, required = false,
                                 default = nil)
  if valid_594456 != nil:
    section.add "X-Amz-Algorithm", valid_594456
  var valid_594457 = header.getOrDefault("X-Amz-Signature")
  valid_594457 = validateParameter(valid_594457, JString, required = false,
                                 default = nil)
  if valid_594457 != nil:
    section.add "X-Amz-Signature", valid_594457
  var valid_594458 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594458 = validateParameter(valid_594458, JString, required = false,
                                 default = nil)
  if valid_594458 != nil:
    section.add "X-Amz-SignedHeaders", valid_594458
  var valid_594459 = header.getOrDefault("X-Amz-Credential")
  valid_594459 = validateParameter(valid_594459, JString, required = false,
                                 default = nil)
  if valid_594459 != nil:
    section.add "X-Amz-Credential", valid_594459
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594460: Call_PostCreateStorageLocation_594448; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ## 
  let valid = call_594460.validator(path, query, header, formData, body)
  let scheme = call_594460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594460.url(scheme.get, call_594460.host, call_594460.base,
                         call_594460.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594460, url, valid)

proc call*(call_594461: Call_PostCreateStorageLocation_594448;
          Action: string = "CreateStorageLocation"; Version: string = "2010-12-01"): Recallable =
  ## postCreateStorageLocation
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594462 = newJObject()
  add(query_594462, "Action", newJString(Action))
  add(query_594462, "Version", newJString(Version))
  result = call_594461.call(nil, query_594462, nil, nil, nil)

var postCreateStorageLocation* = Call_PostCreateStorageLocation_594448(
    name: "postCreateStorageLocation", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateStorageLocation",
    validator: validate_PostCreateStorageLocation_594449, base: "/",
    url: url_PostCreateStorageLocation_594450,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateStorageLocation_594433 = ref object of OpenApiRestCall_593438
proc url_GetCreateStorageLocation_594435(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateStorageLocation_594434(path: JsonNode; query: JsonNode;
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
  var valid_594436 = query.getOrDefault("Action")
  valid_594436 = validateParameter(valid_594436, JString, required = true,
                                 default = newJString("CreateStorageLocation"))
  if valid_594436 != nil:
    section.add "Action", valid_594436
  var valid_594437 = query.getOrDefault("Version")
  valid_594437 = validateParameter(valid_594437, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594437 != nil:
    section.add "Version", valid_594437
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594438 = header.getOrDefault("X-Amz-Date")
  valid_594438 = validateParameter(valid_594438, JString, required = false,
                                 default = nil)
  if valid_594438 != nil:
    section.add "X-Amz-Date", valid_594438
  var valid_594439 = header.getOrDefault("X-Amz-Security-Token")
  valid_594439 = validateParameter(valid_594439, JString, required = false,
                                 default = nil)
  if valid_594439 != nil:
    section.add "X-Amz-Security-Token", valid_594439
  var valid_594440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594440 = validateParameter(valid_594440, JString, required = false,
                                 default = nil)
  if valid_594440 != nil:
    section.add "X-Amz-Content-Sha256", valid_594440
  var valid_594441 = header.getOrDefault("X-Amz-Algorithm")
  valid_594441 = validateParameter(valid_594441, JString, required = false,
                                 default = nil)
  if valid_594441 != nil:
    section.add "X-Amz-Algorithm", valid_594441
  var valid_594442 = header.getOrDefault("X-Amz-Signature")
  valid_594442 = validateParameter(valid_594442, JString, required = false,
                                 default = nil)
  if valid_594442 != nil:
    section.add "X-Amz-Signature", valid_594442
  var valid_594443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594443 = validateParameter(valid_594443, JString, required = false,
                                 default = nil)
  if valid_594443 != nil:
    section.add "X-Amz-SignedHeaders", valid_594443
  var valid_594444 = header.getOrDefault("X-Amz-Credential")
  valid_594444 = validateParameter(valid_594444, JString, required = false,
                                 default = nil)
  if valid_594444 != nil:
    section.add "X-Amz-Credential", valid_594444
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594445: Call_GetCreateStorageLocation_594433; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ## 
  let valid = call_594445.validator(path, query, header, formData, body)
  let scheme = call_594445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594445.url(scheme.get, call_594445.host, call_594445.base,
                         call_594445.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594445, url, valid)

proc call*(call_594446: Call_GetCreateStorageLocation_594433;
          Action: string = "CreateStorageLocation"; Version: string = "2010-12-01"): Recallable =
  ## getCreateStorageLocation
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594447 = newJObject()
  add(query_594447, "Action", newJString(Action))
  add(query_594447, "Version", newJString(Version))
  result = call_594446.call(nil, query_594447, nil, nil, nil)

var getCreateStorageLocation* = Call_GetCreateStorageLocation_594433(
    name: "getCreateStorageLocation", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateStorageLocation",
    validator: validate_GetCreateStorageLocation_594434, base: "/",
    url: url_GetCreateStorageLocation_594435, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteApplication_594480 = ref object of OpenApiRestCall_593438
proc url_PostDeleteApplication_594482(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteApplication_594481(path: JsonNode; query: JsonNode;
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
  var valid_594483 = query.getOrDefault("Action")
  valid_594483 = validateParameter(valid_594483, JString, required = true,
                                 default = newJString("DeleteApplication"))
  if valid_594483 != nil:
    section.add "Action", valid_594483
  var valid_594484 = query.getOrDefault("Version")
  valid_594484 = validateParameter(valid_594484, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594484 != nil:
    section.add "Version", valid_594484
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594485 = header.getOrDefault("X-Amz-Date")
  valid_594485 = validateParameter(valid_594485, JString, required = false,
                                 default = nil)
  if valid_594485 != nil:
    section.add "X-Amz-Date", valid_594485
  var valid_594486 = header.getOrDefault("X-Amz-Security-Token")
  valid_594486 = validateParameter(valid_594486, JString, required = false,
                                 default = nil)
  if valid_594486 != nil:
    section.add "X-Amz-Security-Token", valid_594486
  var valid_594487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594487 = validateParameter(valid_594487, JString, required = false,
                                 default = nil)
  if valid_594487 != nil:
    section.add "X-Amz-Content-Sha256", valid_594487
  var valid_594488 = header.getOrDefault("X-Amz-Algorithm")
  valid_594488 = validateParameter(valid_594488, JString, required = false,
                                 default = nil)
  if valid_594488 != nil:
    section.add "X-Amz-Algorithm", valid_594488
  var valid_594489 = header.getOrDefault("X-Amz-Signature")
  valid_594489 = validateParameter(valid_594489, JString, required = false,
                                 default = nil)
  if valid_594489 != nil:
    section.add "X-Amz-Signature", valid_594489
  var valid_594490 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594490 = validateParameter(valid_594490, JString, required = false,
                                 default = nil)
  if valid_594490 != nil:
    section.add "X-Amz-SignedHeaders", valid_594490
  var valid_594491 = header.getOrDefault("X-Amz-Credential")
  valid_594491 = validateParameter(valid_594491, JString, required = false,
                                 default = nil)
  if valid_594491 != nil:
    section.add "X-Amz-Credential", valid_594491
  result.add "header", section
  ## parameters in `formData` object:
  ##   TerminateEnvByForce: JBool
  ##                      : When set to true, running environments will be terminated before deleting the application.
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to delete.
  section = newJObject()
  var valid_594492 = formData.getOrDefault("TerminateEnvByForce")
  valid_594492 = validateParameter(valid_594492, JBool, required = false, default = nil)
  if valid_594492 != nil:
    section.add "TerminateEnvByForce", valid_594492
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_594493 = formData.getOrDefault("ApplicationName")
  valid_594493 = validateParameter(valid_594493, JString, required = true,
                                 default = nil)
  if valid_594493 != nil:
    section.add "ApplicationName", valid_594493
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594494: Call_PostDeleteApplication_594480; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified application along with all associated versions and configurations. The application versions will not be deleted from your Amazon S3 bucket.</p> <note> <p>You cannot delete an application that has a running environment.</p> </note>
  ## 
  let valid = call_594494.validator(path, query, header, formData, body)
  let scheme = call_594494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594494.url(scheme.get, call_594494.host, call_594494.base,
                         call_594494.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594494, url, valid)

proc call*(call_594495: Call_PostDeleteApplication_594480; ApplicationName: string;
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
  var query_594496 = newJObject()
  var formData_594497 = newJObject()
  add(formData_594497, "TerminateEnvByForce", newJBool(TerminateEnvByForce))
  add(query_594496, "Action", newJString(Action))
  add(formData_594497, "ApplicationName", newJString(ApplicationName))
  add(query_594496, "Version", newJString(Version))
  result = call_594495.call(nil, query_594496, nil, formData_594497, nil)

var postDeleteApplication* = Call_PostDeleteApplication_594480(
    name: "postDeleteApplication", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=DeleteApplication",
    validator: validate_PostDeleteApplication_594481, base: "/",
    url: url_PostDeleteApplication_594482, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteApplication_594463 = ref object of OpenApiRestCall_593438
proc url_GetDeleteApplication_594465(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteApplication_594464(path: JsonNode; query: JsonNode;
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
  var valid_594466 = query.getOrDefault("TerminateEnvByForce")
  valid_594466 = validateParameter(valid_594466, JBool, required = false, default = nil)
  if valid_594466 != nil:
    section.add "TerminateEnvByForce", valid_594466
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_594467 = query.getOrDefault("ApplicationName")
  valid_594467 = validateParameter(valid_594467, JString, required = true,
                                 default = nil)
  if valid_594467 != nil:
    section.add "ApplicationName", valid_594467
  var valid_594468 = query.getOrDefault("Action")
  valid_594468 = validateParameter(valid_594468, JString, required = true,
                                 default = newJString("DeleteApplication"))
  if valid_594468 != nil:
    section.add "Action", valid_594468
  var valid_594469 = query.getOrDefault("Version")
  valid_594469 = validateParameter(valid_594469, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594469 != nil:
    section.add "Version", valid_594469
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594470 = header.getOrDefault("X-Amz-Date")
  valid_594470 = validateParameter(valid_594470, JString, required = false,
                                 default = nil)
  if valid_594470 != nil:
    section.add "X-Amz-Date", valid_594470
  var valid_594471 = header.getOrDefault("X-Amz-Security-Token")
  valid_594471 = validateParameter(valid_594471, JString, required = false,
                                 default = nil)
  if valid_594471 != nil:
    section.add "X-Amz-Security-Token", valid_594471
  var valid_594472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594472 = validateParameter(valid_594472, JString, required = false,
                                 default = nil)
  if valid_594472 != nil:
    section.add "X-Amz-Content-Sha256", valid_594472
  var valid_594473 = header.getOrDefault("X-Amz-Algorithm")
  valid_594473 = validateParameter(valid_594473, JString, required = false,
                                 default = nil)
  if valid_594473 != nil:
    section.add "X-Amz-Algorithm", valid_594473
  var valid_594474 = header.getOrDefault("X-Amz-Signature")
  valid_594474 = validateParameter(valid_594474, JString, required = false,
                                 default = nil)
  if valid_594474 != nil:
    section.add "X-Amz-Signature", valid_594474
  var valid_594475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594475 = validateParameter(valid_594475, JString, required = false,
                                 default = nil)
  if valid_594475 != nil:
    section.add "X-Amz-SignedHeaders", valid_594475
  var valid_594476 = header.getOrDefault("X-Amz-Credential")
  valid_594476 = validateParameter(valid_594476, JString, required = false,
                                 default = nil)
  if valid_594476 != nil:
    section.add "X-Amz-Credential", valid_594476
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594477: Call_GetDeleteApplication_594463; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified application along with all associated versions and configurations. The application versions will not be deleted from your Amazon S3 bucket.</p> <note> <p>You cannot delete an application that has a running environment.</p> </note>
  ## 
  let valid = call_594477.validator(path, query, header, formData, body)
  let scheme = call_594477.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594477.url(scheme.get, call_594477.host, call_594477.base,
                         call_594477.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594477, url, valid)

proc call*(call_594478: Call_GetDeleteApplication_594463; ApplicationName: string;
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
  var query_594479 = newJObject()
  add(query_594479, "TerminateEnvByForce", newJBool(TerminateEnvByForce))
  add(query_594479, "ApplicationName", newJString(ApplicationName))
  add(query_594479, "Action", newJString(Action))
  add(query_594479, "Version", newJString(Version))
  result = call_594478.call(nil, query_594479, nil, nil, nil)

var getDeleteApplication* = Call_GetDeleteApplication_594463(
    name: "getDeleteApplication", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=DeleteApplication",
    validator: validate_GetDeleteApplication_594464, base: "/",
    url: url_GetDeleteApplication_594465, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteApplicationVersion_594516 = ref object of OpenApiRestCall_593438
proc url_PostDeleteApplicationVersion_594518(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteApplicationVersion_594517(path: JsonNode; query: JsonNode;
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
  var valid_594519 = query.getOrDefault("Action")
  valid_594519 = validateParameter(valid_594519, JString, required = true, default = newJString(
      "DeleteApplicationVersion"))
  if valid_594519 != nil:
    section.add "Action", valid_594519
  var valid_594520 = query.getOrDefault("Version")
  valid_594520 = validateParameter(valid_594520, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594520 != nil:
    section.add "Version", valid_594520
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594521 = header.getOrDefault("X-Amz-Date")
  valid_594521 = validateParameter(valid_594521, JString, required = false,
                                 default = nil)
  if valid_594521 != nil:
    section.add "X-Amz-Date", valid_594521
  var valid_594522 = header.getOrDefault("X-Amz-Security-Token")
  valid_594522 = validateParameter(valid_594522, JString, required = false,
                                 default = nil)
  if valid_594522 != nil:
    section.add "X-Amz-Security-Token", valid_594522
  var valid_594523 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594523 = validateParameter(valid_594523, JString, required = false,
                                 default = nil)
  if valid_594523 != nil:
    section.add "X-Amz-Content-Sha256", valid_594523
  var valid_594524 = header.getOrDefault("X-Amz-Algorithm")
  valid_594524 = validateParameter(valid_594524, JString, required = false,
                                 default = nil)
  if valid_594524 != nil:
    section.add "X-Amz-Algorithm", valid_594524
  var valid_594525 = header.getOrDefault("X-Amz-Signature")
  valid_594525 = validateParameter(valid_594525, JString, required = false,
                                 default = nil)
  if valid_594525 != nil:
    section.add "X-Amz-Signature", valid_594525
  var valid_594526 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594526 = validateParameter(valid_594526, JString, required = false,
                                 default = nil)
  if valid_594526 != nil:
    section.add "X-Amz-SignedHeaders", valid_594526
  var valid_594527 = header.getOrDefault("X-Amz-Credential")
  valid_594527 = validateParameter(valid_594527, JString, required = false,
                                 default = nil)
  if valid_594527 != nil:
    section.add "X-Amz-Credential", valid_594527
  result.add "header", section
  ## parameters in `formData` object:
  ##   DeleteSourceBundle: JBool
  ##                     : Set to <code>true</code> to delete the source bundle from your storage bucket. Otherwise, the application version is deleted only from Elastic Beanstalk and the source bundle remains in Amazon S3.
  ##   VersionLabel: JString (required)
  ##               : The label of the version to delete.
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to which the version belongs.
  section = newJObject()
  var valid_594528 = formData.getOrDefault("DeleteSourceBundle")
  valid_594528 = validateParameter(valid_594528, JBool, required = false, default = nil)
  if valid_594528 != nil:
    section.add "DeleteSourceBundle", valid_594528
  assert formData != nil,
        "formData argument is necessary due to required `VersionLabel` field"
  var valid_594529 = formData.getOrDefault("VersionLabel")
  valid_594529 = validateParameter(valid_594529, JString, required = true,
                                 default = nil)
  if valid_594529 != nil:
    section.add "VersionLabel", valid_594529
  var valid_594530 = formData.getOrDefault("ApplicationName")
  valid_594530 = validateParameter(valid_594530, JString, required = true,
                                 default = nil)
  if valid_594530 != nil:
    section.add "ApplicationName", valid_594530
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594531: Call_PostDeleteApplicationVersion_594516; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified version from the specified application.</p> <note> <p>You cannot delete an application version that is associated with a running environment.</p> </note>
  ## 
  let valid = call_594531.validator(path, query, header, formData, body)
  let scheme = call_594531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594531.url(scheme.get, call_594531.host, call_594531.base,
                         call_594531.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594531, url, valid)

proc call*(call_594532: Call_PostDeleteApplicationVersion_594516;
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
  var query_594533 = newJObject()
  var formData_594534 = newJObject()
  add(formData_594534, "DeleteSourceBundle", newJBool(DeleteSourceBundle))
  add(formData_594534, "VersionLabel", newJString(VersionLabel))
  add(query_594533, "Action", newJString(Action))
  add(formData_594534, "ApplicationName", newJString(ApplicationName))
  add(query_594533, "Version", newJString(Version))
  result = call_594532.call(nil, query_594533, nil, formData_594534, nil)

var postDeleteApplicationVersion* = Call_PostDeleteApplicationVersion_594516(
    name: "postDeleteApplicationVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteApplicationVersion",
    validator: validate_PostDeleteApplicationVersion_594517, base: "/",
    url: url_PostDeleteApplicationVersion_594518,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteApplicationVersion_594498 = ref object of OpenApiRestCall_593438
proc url_GetDeleteApplicationVersion_594500(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteApplicationVersion_594499(path: JsonNode; query: JsonNode;
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
  var valid_594501 = query.getOrDefault("VersionLabel")
  valid_594501 = validateParameter(valid_594501, JString, required = true,
                                 default = nil)
  if valid_594501 != nil:
    section.add "VersionLabel", valid_594501
  var valid_594502 = query.getOrDefault("ApplicationName")
  valid_594502 = validateParameter(valid_594502, JString, required = true,
                                 default = nil)
  if valid_594502 != nil:
    section.add "ApplicationName", valid_594502
  var valid_594503 = query.getOrDefault("Action")
  valid_594503 = validateParameter(valid_594503, JString, required = true, default = newJString(
      "DeleteApplicationVersion"))
  if valid_594503 != nil:
    section.add "Action", valid_594503
  var valid_594504 = query.getOrDefault("DeleteSourceBundle")
  valid_594504 = validateParameter(valid_594504, JBool, required = false, default = nil)
  if valid_594504 != nil:
    section.add "DeleteSourceBundle", valid_594504
  var valid_594505 = query.getOrDefault("Version")
  valid_594505 = validateParameter(valid_594505, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594505 != nil:
    section.add "Version", valid_594505
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594506 = header.getOrDefault("X-Amz-Date")
  valid_594506 = validateParameter(valid_594506, JString, required = false,
                                 default = nil)
  if valid_594506 != nil:
    section.add "X-Amz-Date", valid_594506
  var valid_594507 = header.getOrDefault("X-Amz-Security-Token")
  valid_594507 = validateParameter(valid_594507, JString, required = false,
                                 default = nil)
  if valid_594507 != nil:
    section.add "X-Amz-Security-Token", valid_594507
  var valid_594508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594508 = validateParameter(valid_594508, JString, required = false,
                                 default = nil)
  if valid_594508 != nil:
    section.add "X-Amz-Content-Sha256", valid_594508
  var valid_594509 = header.getOrDefault("X-Amz-Algorithm")
  valid_594509 = validateParameter(valid_594509, JString, required = false,
                                 default = nil)
  if valid_594509 != nil:
    section.add "X-Amz-Algorithm", valid_594509
  var valid_594510 = header.getOrDefault("X-Amz-Signature")
  valid_594510 = validateParameter(valid_594510, JString, required = false,
                                 default = nil)
  if valid_594510 != nil:
    section.add "X-Amz-Signature", valid_594510
  var valid_594511 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594511 = validateParameter(valid_594511, JString, required = false,
                                 default = nil)
  if valid_594511 != nil:
    section.add "X-Amz-SignedHeaders", valid_594511
  var valid_594512 = header.getOrDefault("X-Amz-Credential")
  valid_594512 = validateParameter(valid_594512, JString, required = false,
                                 default = nil)
  if valid_594512 != nil:
    section.add "X-Amz-Credential", valid_594512
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594513: Call_GetDeleteApplicationVersion_594498; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified version from the specified application.</p> <note> <p>You cannot delete an application version that is associated with a running environment.</p> </note>
  ## 
  let valid = call_594513.validator(path, query, header, formData, body)
  let scheme = call_594513.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594513.url(scheme.get, call_594513.host, call_594513.base,
                         call_594513.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594513, url, valid)

proc call*(call_594514: Call_GetDeleteApplicationVersion_594498;
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
  var query_594515 = newJObject()
  add(query_594515, "VersionLabel", newJString(VersionLabel))
  add(query_594515, "ApplicationName", newJString(ApplicationName))
  add(query_594515, "Action", newJString(Action))
  add(query_594515, "DeleteSourceBundle", newJBool(DeleteSourceBundle))
  add(query_594515, "Version", newJString(Version))
  result = call_594514.call(nil, query_594515, nil, nil, nil)

var getDeleteApplicationVersion* = Call_GetDeleteApplicationVersion_594498(
    name: "getDeleteApplicationVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteApplicationVersion",
    validator: validate_GetDeleteApplicationVersion_594499, base: "/",
    url: url_GetDeleteApplicationVersion_594500,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteConfigurationTemplate_594552 = ref object of OpenApiRestCall_593438
proc url_PostDeleteConfigurationTemplate_594554(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteConfigurationTemplate_594553(path: JsonNode;
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
  var valid_594555 = query.getOrDefault("Action")
  valid_594555 = validateParameter(valid_594555, JString, required = true, default = newJString(
      "DeleteConfigurationTemplate"))
  if valid_594555 != nil:
    section.add "Action", valid_594555
  var valid_594556 = query.getOrDefault("Version")
  valid_594556 = validateParameter(valid_594556, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594556 != nil:
    section.add "Version", valid_594556
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594557 = header.getOrDefault("X-Amz-Date")
  valid_594557 = validateParameter(valid_594557, JString, required = false,
                                 default = nil)
  if valid_594557 != nil:
    section.add "X-Amz-Date", valid_594557
  var valid_594558 = header.getOrDefault("X-Amz-Security-Token")
  valid_594558 = validateParameter(valid_594558, JString, required = false,
                                 default = nil)
  if valid_594558 != nil:
    section.add "X-Amz-Security-Token", valid_594558
  var valid_594559 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594559 = validateParameter(valid_594559, JString, required = false,
                                 default = nil)
  if valid_594559 != nil:
    section.add "X-Amz-Content-Sha256", valid_594559
  var valid_594560 = header.getOrDefault("X-Amz-Algorithm")
  valid_594560 = validateParameter(valid_594560, JString, required = false,
                                 default = nil)
  if valid_594560 != nil:
    section.add "X-Amz-Algorithm", valid_594560
  var valid_594561 = header.getOrDefault("X-Amz-Signature")
  valid_594561 = validateParameter(valid_594561, JString, required = false,
                                 default = nil)
  if valid_594561 != nil:
    section.add "X-Amz-Signature", valid_594561
  var valid_594562 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594562 = validateParameter(valid_594562, JString, required = false,
                                 default = nil)
  if valid_594562 != nil:
    section.add "X-Amz-SignedHeaders", valid_594562
  var valid_594563 = header.getOrDefault("X-Amz-Credential")
  valid_594563 = validateParameter(valid_594563, JString, required = false,
                                 default = nil)
  if valid_594563 != nil:
    section.add "X-Amz-Credential", valid_594563
  result.add "header", section
  ## parameters in `formData` object:
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to delete the configuration template from.
  ##   TemplateName: JString (required)
  ##               : The name of the configuration template to delete.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_594564 = formData.getOrDefault("ApplicationName")
  valid_594564 = validateParameter(valid_594564, JString, required = true,
                                 default = nil)
  if valid_594564 != nil:
    section.add "ApplicationName", valid_594564
  var valid_594565 = formData.getOrDefault("TemplateName")
  valid_594565 = validateParameter(valid_594565, JString, required = true,
                                 default = nil)
  if valid_594565 != nil:
    section.add "TemplateName", valid_594565
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594566: Call_PostDeleteConfigurationTemplate_594552;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes the specified configuration template.</p> <note> <p>When you launch an environment using a configuration template, the environment gets a copy of the template. You can delete or modify the environment's copy of the template without affecting the running environment.</p> </note>
  ## 
  let valid = call_594566.validator(path, query, header, formData, body)
  let scheme = call_594566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594566.url(scheme.get, call_594566.host, call_594566.base,
                         call_594566.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594566, url, valid)

proc call*(call_594567: Call_PostDeleteConfigurationTemplate_594552;
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
  var query_594568 = newJObject()
  var formData_594569 = newJObject()
  add(query_594568, "Action", newJString(Action))
  add(formData_594569, "ApplicationName", newJString(ApplicationName))
  add(formData_594569, "TemplateName", newJString(TemplateName))
  add(query_594568, "Version", newJString(Version))
  result = call_594567.call(nil, query_594568, nil, formData_594569, nil)

var postDeleteConfigurationTemplate* = Call_PostDeleteConfigurationTemplate_594552(
    name: "postDeleteConfigurationTemplate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteConfigurationTemplate",
    validator: validate_PostDeleteConfigurationTemplate_594553, base: "/",
    url: url_PostDeleteConfigurationTemplate_594554,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteConfigurationTemplate_594535 = ref object of OpenApiRestCall_593438
proc url_GetDeleteConfigurationTemplate_594537(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteConfigurationTemplate_594536(path: JsonNode;
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
  var valid_594538 = query.getOrDefault("ApplicationName")
  valid_594538 = validateParameter(valid_594538, JString, required = true,
                                 default = nil)
  if valid_594538 != nil:
    section.add "ApplicationName", valid_594538
  var valid_594539 = query.getOrDefault("Action")
  valid_594539 = validateParameter(valid_594539, JString, required = true, default = newJString(
      "DeleteConfigurationTemplate"))
  if valid_594539 != nil:
    section.add "Action", valid_594539
  var valid_594540 = query.getOrDefault("TemplateName")
  valid_594540 = validateParameter(valid_594540, JString, required = true,
                                 default = nil)
  if valid_594540 != nil:
    section.add "TemplateName", valid_594540
  var valid_594541 = query.getOrDefault("Version")
  valid_594541 = validateParameter(valid_594541, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594541 != nil:
    section.add "Version", valid_594541
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594542 = header.getOrDefault("X-Amz-Date")
  valid_594542 = validateParameter(valid_594542, JString, required = false,
                                 default = nil)
  if valid_594542 != nil:
    section.add "X-Amz-Date", valid_594542
  var valid_594543 = header.getOrDefault("X-Amz-Security-Token")
  valid_594543 = validateParameter(valid_594543, JString, required = false,
                                 default = nil)
  if valid_594543 != nil:
    section.add "X-Amz-Security-Token", valid_594543
  var valid_594544 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594544 = validateParameter(valid_594544, JString, required = false,
                                 default = nil)
  if valid_594544 != nil:
    section.add "X-Amz-Content-Sha256", valid_594544
  var valid_594545 = header.getOrDefault("X-Amz-Algorithm")
  valid_594545 = validateParameter(valid_594545, JString, required = false,
                                 default = nil)
  if valid_594545 != nil:
    section.add "X-Amz-Algorithm", valid_594545
  var valid_594546 = header.getOrDefault("X-Amz-Signature")
  valid_594546 = validateParameter(valid_594546, JString, required = false,
                                 default = nil)
  if valid_594546 != nil:
    section.add "X-Amz-Signature", valid_594546
  var valid_594547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594547 = validateParameter(valid_594547, JString, required = false,
                                 default = nil)
  if valid_594547 != nil:
    section.add "X-Amz-SignedHeaders", valid_594547
  var valid_594548 = header.getOrDefault("X-Amz-Credential")
  valid_594548 = validateParameter(valid_594548, JString, required = false,
                                 default = nil)
  if valid_594548 != nil:
    section.add "X-Amz-Credential", valid_594548
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594549: Call_GetDeleteConfigurationTemplate_594535; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified configuration template.</p> <note> <p>When you launch an environment using a configuration template, the environment gets a copy of the template. You can delete or modify the environment's copy of the template without affecting the running environment.</p> </note>
  ## 
  let valid = call_594549.validator(path, query, header, formData, body)
  let scheme = call_594549.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594549.url(scheme.get, call_594549.host, call_594549.base,
                         call_594549.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594549, url, valid)

proc call*(call_594550: Call_GetDeleteConfigurationTemplate_594535;
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
  var query_594551 = newJObject()
  add(query_594551, "ApplicationName", newJString(ApplicationName))
  add(query_594551, "Action", newJString(Action))
  add(query_594551, "TemplateName", newJString(TemplateName))
  add(query_594551, "Version", newJString(Version))
  result = call_594550.call(nil, query_594551, nil, nil, nil)

var getDeleteConfigurationTemplate* = Call_GetDeleteConfigurationTemplate_594535(
    name: "getDeleteConfigurationTemplate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteConfigurationTemplate",
    validator: validate_GetDeleteConfigurationTemplate_594536, base: "/",
    url: url_GetDeleteConfigurationTemplate_594537,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEnvironmentConfiguration_594587 = ref object of OpenApiRestCall_593438
proc url_PostDeleteEnvironmentConfiguration_594589(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteEnvironmentConfiguration_594588(path: JsonNode;
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
  var valid_594590 = query.getOrDefault("Action")
  valid_594590 = validateParameter(valid_594590, JString, required = true, default = newJString(
      "DeleteEnvironmentConfiguration"))
  if valid_594590 != nil:
    section.add "Action", valid_594590
  var valid_594591 = query.getOrDefault("Version")
  valid_594591 = validateParameter(valid_594591, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594591 != nil:
    section.add "Version", valid_594591
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594592 = header.getOrDefault("X-Amz-Date")
  valid_594592 = validateParameter(valid_594592, JString, required = false,
                                 default = nil)
  if valid_594592 != nil:
    section.add "X-Amz-Date", valid_594592
  var valid_594593 = header.getOrDefault("X-Amz-Security-Token")
  valid_594593 = validateParameter(valid_594593, JString, required = false,
                                 default = nil)
  if valid_594593 != nil:
    section.add "X-Amz-Security-Token", valid_594593
  var valid_594594 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594594 = validateParameter(valid_594594, JString, required = false,
                                 default = nil)
  if valid_594594 != nil:
    section.add "X-Amz-Content-Sha256", valid_594594
  var valid_594595 = header.getOrDefault("X-Amz-Algorithm")
  valid_594595 = validateParameter(valid_594595, JString, required = false,
                                 default = nil)
  if valid_594595 != nil:
    section.add "X-Amz-Algorithm", valid_594595
  var valid_594596 = header.getOrDefault("X-Amz-Signature")
  valid_594596 = validateParameter(valid_594596, JString, required = false,
                                 default = nil)
  if valid_594596 != nil:
    section.add "X-Amz-Signature", valid_594596
  var valid_594597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594597 = validateParameter(valid_594597, JString, required = false,
                                 default = nil)
  if valid_594597 != nil:
    section.add "X-Amz-SignedHeaders", valid_594597
  var valid_594598 = header.getOrDefault("X-Amz-Credential")
  valid_594598 = validateParameter(valid_594598, JString, required = false,
                                 default = nil)
  if valid_594598 != nil:
    section.add "X-Amz-Credential", valid_594598
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString (required)
  ##                  : The name of the environment to delete the draft configuration from.
  ##   ApplicationName: JString (required)
  ##                  : The name of the application the environment is associated with.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `EnvironmentName` field"
  var valid_594599 = formData.getOrDefault("EnvironmentName")
  valid_594599 = validateParameter(valid_594599, JString, required = true,
                                 default = nil)
  if valid_594599 != nil:
    section.add "EnvironmentName", valid_594599
  var valid_594600 = formData.getOrDefault("ApplicationName")
  valid_594600 = validateParameter(valid_594600, JString, required = true,
                                 default = nil)
  if valid_594600 != nil:
    section.add "ApplicationName", valid_594600
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594601: Call_PostDeleteEnvironmentConfiguration_594587;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes the draft configuration associated with the running environment.</p> <p>Updating a running environment with any configuration changes creates a draft configuration set. You can get the draft configuration using <a>DescribeConfigurationSettings</a> while the update is in progress or if the update fails. The <code>DeploymentStatus</code> for the draft configuration indicates whether the deployment is in process or has failed. The draft configuration remains in existence until it is deleted with this action.</p>
  ## 
  let valid = call_594601.validator(path, query, header, formData, body)
  let scheme = call_594601.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594601.url(scheme.get, call_594601.host, call_594601.base,
                         call_594601.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594601, url, valid)

proc call*(call_594602: Call_PostDeleteEnvironmentConfiguration_594587;
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
  var query_594603 = newJObject()
  var formData_594604 = newJObject()
  add(formData_594604, "EnvironmentName", newJString(EnvironmentName))
  add(query_594603, "Action", newJString(Action))
  add(formData_594604, "ApplicationName", newJString(ApplicationName))
  add(query_594603, "Version", newJString(Version))
  result = call_594602.call(nil, query_594603, nil, formData_594604, nil)

var postDeleteEnvironmentConfiguration* = Call_PostDeleteEnvironmentConfiguration_594587(
    name: "postDeleteEnvironmentConfiguration", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteEnvironmentConfiguration",
    validator: validate_PostDeleteEnvironmentConfiguration_594588, base: "/",
    url: url_PostDeleteEnvironmentConfiguration_594589,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEnvironmentConfiguration_594570 = ref object of OpenApiRestCall_593438
proc url_GetDeleteEnvironmentConfiguration_594572(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteEnvironmentConfiguration_594571(path: JsonNode;
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
  var valid_594573 = query.getOrDefault("ApplicationName")
  valid_594573 = validateParameter(valid_594573, JString, required = true,
                                 default = nil)
  if valid_594573 != nil:
    section.add "ApplicationName", valid_594573
  var valid_594574 = query.getOrDefault("EnvironmentName")
  valid_594574 = validateParameter(valid_594574, JString, required = true,
                                 default = nil)
  if valid_594574 != nil:
    section.add "EnvironmentName", valid_594574
  var valid_594575 = query.getOrDefault("Action")
  valid_594575 = validateParameter(valid_594575, JString, required = true, default = newJString(
      "DeleteEnvironmentConfiguration"))
  if valid_594575 != nil:
    section.add "Action", valid_594575
  var valid_594576 = query.getOrDefault("Version")
  valid_594576 = validateParameter(valid_594576, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594576 != nil:
    section.add "Version", valid_594576
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594577 = header.getOrDefault("X-Amz-Date")
  valid_594577 = validateParameter(valid_594577, JString, required = false,
                                 default = nil)
  if valid_594577 != nil:
    section.add "X-Amz-Date", valid_594577
  var valid_594578 = header.getOrDefault("X-Amz-Security-Token")
  valid_594578 = validateParameter(valid_594578, JString, required = false,
                                 default = nil)
  if valid_594578 != nil:
    section.add "X-Amz-Security-Token", valid_594578
  var valid_594579 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594579 = validateParameter(valid_594579, JString, required = false,
                                 default = nil)
  if valid_594579 != nil:
    section.add "X-Amz-Content-Sha256", valid_594579
  var valid_594580 = header.getOrDefault("X-Amz-Algorithm")
  valid_594580 = validateParameter(valid_594580, JString, required = false,
                                 default = nil)
  if valid_594580 != nil:
    section.add "X-Amz-Algorithm", valid_594580
  var valid_594581 = header.getOrDefault("X-Amz-Signature")
  valid_594581 = validateParameter(valid_594581, JString, required = false,
                                 default = nil)
  if valid_594581 != nil:
    section.add "X-Amz-Signature", valid_594581
  var valid_594582 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594582 = validateParameter(valid_594582, JString, required = false,
                                 default = nil)
  if valid_594582 != nil:
    section.add "X-Amz-SignedHeaders", valid_594582
  var valid_594583 = header.getOrDefault("X-Amz-Credential")
  valid_594583 = validateParameter(valid_594583, JString, required = false,
                                 default = nil)
  if valid_594583 != nil:
    section.add "X-Amz-Credential", valid_594583
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594584: Call_GetDeleteEnvironmentConfiguration_594570;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes the draft configuration associated with the running environment.</p> <p>Updating a running environment with any configuration changes creates a draft configuration set. You can get the draft configuration using <a>DescribeConfigurationSettings</a> while the update is in progress or if the update fails. The <code>DeploymentStatus</code> for the draft configuration indicates whether the deployment is in process or has failed. The draft configuration remains in existence until it is deleted with this action.</p>
  ## 
  let valid = call_594584.validator(path, query, header, formData, body)
  let scheme = call_594584.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594584.url(scheme.get, call_594584.host, call_594584.base,
                         call_594584.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594584, url, valid)

proc call*(call_594585: Call_GetDeleteEnvironmentConfiguration_594570;
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
  var query_594586 = newJObject()
  add(query_594586, "ApplicationName", newJString(ApplicationName))
  add(query_594586, "EnvironmentName", newJString(EnvironmentName))
  add(query_594586, "Action", newJString(Action))
  add(query_594586, "Version", newJString(Version))
  result = call_594585.call(nil, query_594586, nil, nil, nil)

var getDeleteEnvironmentConfiguration* = Call_GetDeleteEnvironmentConfiguration_594570(
    name: "getDeleteEnvironmentConfiguration", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteEnvironmentConfiguration",
    validator: validate_GetDeleteEnvironmentConfiguration_594571, base: "/",
    url: url_GetDeleteEnvironmentConfiguration_594572,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeletePlatformVersion_594621 = ref object of OpenApiRestCall_593438
proc url_PostDeletePlatformVersion_594623(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeletePlatformVersion_594622(path: JsonNode; query: JsonNode;
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
  var valid_594624 = query.getOrDefault("Action")
  valid_594624 = validateParameter(valid_594624, JString, required = true,
                                 default = newJString("DeletePlatformVersion"))
  if valid_594624 != nil:
    section.add "Action", valid_594624
  var valid_594625 = query.getOrDefault("Version")
  valid_594625 = validateParameter(valid_594625, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594625 != nil:
    section.add "Version", valid_594625
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594626 = header.getOrDefault("X-Amz-Date")
  valid_594626 = validateParameter(valid_594626, JString, required = false,
                                 default = nil)
  if valid_594626 != nil:
    section.add "X-Amz-Date", valid_594626
  var valid_594627 = header.getOrDefault("X-Amz-Security-Token")
  valid_594627 = validateParameter(valid_594627, JString, required = false,
                                 default = nil)
  if valid_594627 != nil:
    section.add "X-Amz-Security-Token", valid_594627
  var valid_594628 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594628 = validateParameter(valid_594628, JString, required = false,
                                 default = nil)
  if valid_594628 != nil:
    section.add "X-Amz-Content-Sha256", valid_594628
  var valid_594629 = header.getOrDefault("X-Amz-Algorithm")
  valid_594629 = validateParameter(valid_594629, JString, required = false,
                                 default = nil)
  if valid_594629 != nil:
    section.add "X-Amz-Algorithm", valid_594629
  var valid_594630 = header.getOrDefault("X-Amz-Signature")
  valid_594630 = validateParameter(valid_594630, JString, required = false,
                                 default = nil)
  if valid_594630 != nil:
    section.add "X-Amz-Signature", valid_594630
  var valid_594631 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594631 = validateParameter(valid_594631, JString, required = false,
                                 default = nil)
  if valid_594631 != nil:
    section.add "X-Amz-SignedHeaders", valid_594631
  var valid_594632 = header.getOrDefault("X-Amz-Credential")
  valid_594632 = validateParameter(valid_594632, JString, required = false,
                                 default = nil)
  if valid_594632 != nil:
    section.add "X-Amz-Credential", valid_594632
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformArn: JString
  ##              : The ARN of the version of the custom platform.
  section = newJObject()
  var valid_594633 = formData.getOrDefault("PlatformArn")
  valid_594633 = validateParameter(valid_594633, JString, required = false,
                                 default = nil)
  if valid_594633 != nil:
    section.add "PlatformArn", valid_594633
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594634: Call_PostDeletePlatformVersion_594621; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified version of a custom platform.
  ## 
  let valid = call_594634.validator(path, query, header, formData, body)
  let scheme = call_594634.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594634.url(scheme.get, call_594634.host, call_594634.base,
                         call_594634.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594634, url, valid)

proc call*(call_594635: Call_PostDeletePlatformVersion_594621;
          Action: string = "DeletePlatformVersion"; PlatformArn: string = "";
          Version: string = "2010-12-01"): Recallable =
  ## postDeletePlatformVersion
  ## Deletes the specified version of a custom platform.
  ##   Action: string (required)
  ##   PlatformArn: string
  ##              : The ARN of the version of the custom platform.
  ##   Version: string (required)
  var query_594636 = newJObject()
  var formData_594637 = newJObject()
  add(query_594636, "Action", newJString(Action))
  add(formData_594637, "PlatformArn", newJString(PlatformArn))
  add(query_594636, "Version", newJString(Version))
  result = call_594635.call(nil, query_594636, nil, formData_594637, nil)

var postDeletePlatformVersion* = Call_PostDeletePlatformVersion_594621(
    name: "postDeletePlatformVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeletePlatformVersion",
    validator: validate_PostDeletePlatformVersion_594622, base: "/",
    url: url_PostDeletePlatformVersion_594623,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeletePlatformVersion_594605 = ref object of OpenApiRestCall_593438
proc url_GetDeletePlatformVersion_594607(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeletePlatformVersion_594606(path: JsonNode; query: JsonNode;
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
  var valid_594608 = query.getOrDefault("PlatformArn")
  valid_594608 = validateParameter(valid_594608, JString, required = false,
                                 default = nil)
  if valid_594608 != nil:
    section.add "PlatformArn", valid_594608
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594609 = query.getOrDefault("Action")
  valid_594609 = validateParameter(valid_594609, JString, required = true,
                                 default = newJString("DeletePlatformVersion"))
  if valid_594609 != nil:
    section.add "Action", valid_594609
  var valid_594610 = query.getOrDefault("Version")
  valid_594610 = validateParameter(valid_594610, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594610 != nil:
    section.add "Version", valid_594610
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594611 = header.getOrDefault("X-Amz-Date")
  valid_594611 = validateParameter(valid_594611, JString, required = false,
                                 default = nil)
  if valid_594611 != nil:
    section.add "X-Amz-Date", valid_594611
  var valid_594612 = header.getOrDefault("X-Amz-Security-Token")
  valid_594612 = validateParameter(valid_594612, JString, required = false,
                                 default = nil)
  if valid_594612 != nil:
    section.add "X-Amz-Security-Token", valid_594612
  var valid_594613 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594613 = validateParameter(valid_594613, JString, required = false,
                                 default = nil)
  if valid_594613 != nil:
    section.add "X-Amz-Content-Sha256", valid_594613
  var valid_594614 = header.getOrDefault("X-Amz-Algorithm")
  valid_594614 = validateParameter(valid_594614, JString, required = false,
                                 default = nil)
  if valid_594614 != nil:
    section.add "X-Amz-Algorithm", valid_594614
  var valid_594615 = header.getOrDefault("X-Amz-Signature")
  valid_594615 = validateParameter(valid_594615, JString, required = false,
                                 default = nil)
  if valid_594615 != nil:
    section.add "X-Amz-Signature", valid_594615
  var valid_594616 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594616 = validateParameter(valid_594616, JString, required = false,
                                 default = nil)
  if valid_594616 != nil:
    section.add "X-Amz-SignedHeaders", valid_594616
  var valid_594617 = header.getOrDefault("X-Amz-Credential")
  valid_594617 = validateParameter(valid_594617, JString, required = false,
                                 default = nil)
  if valid_594617 != nil:
    section.add "X-Amz-Credential", valid_594617
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594618: Call_GetDeletePlatformVersion_594605; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified version of a custom platform.
  ## 
  let valid = call_594618.validator(path, query, header, formData, body)
  let scheme = call_594618.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594618.url(scheme.get, call_594618.host, call_594618.base,
                         call_594618.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594618, url, valid)

proc call*(call_594619: Call_GetDeletePlatformVersion_594605;
          PlatformArn: string = ""; Action: string = "DeletePlatformVersion";
          Version: string = "2010-12-01"): Recallable =
  ## getDeletePlatformVersion
  ## Deletes the specified version of a custom platform.
  ##   PlatformArn: string
  ##              : The ARN of the version of the custom platform.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594620 = newJObject()
  add(query_594620, "PlatformArn", newJString(PlatformArn))
  add(query_594620, "Action", newJString(Action))
  add(query_594620, "Version", newJString(Version))
  result = call_594619.call(nil, query_594620, nil, nil, nil)

var getDeletePlatformVersion* = Call_GetDeletePlatformVersion_594605(
    name: "getDeletePlatformVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeletePlatformVersion",
    validator: validate_GetDeletePlatformVersion_594606, base: "/",
    url: url_GetDeletePlatformVersion_594607, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAccountAttributes_594653 = ref object of OpenApiRestCall_593438
proc url_PostDescribeAccountAttributes_594655(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeAccountAttributes_594654(path: JsonNode; query: JsonNode;
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
  var valid_594656 = query.getOrDefault("Action")
  valid_594656 = validateParameter(valid_594656, JString, required = true, default = newJString(
      "DescribeAccountAttributes"))
  if valid_594656 != nil:
    section.add "Action", valid_594656
  var valid_594657 = query.getOrDefault("Version")
  valid_594657 = validateParameter(valid_594657, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594657 != nil:
    section.add "Version", valid_594657
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594658 = header.getOrDefault("X-Amz-Date")
  valid_594658 = validateParameter(valid_594658, JString, required = false,
                                 default = nil)
  if valid_594658 != nil:
    section.add "X-Amz-Date", valid_594658
  var valid_594659 = header.getOrDefault("X-Amz-Security-Token")
  valid_594659 = validateParameter(valid_594659, JString, required = false,
                                 default = nil)
  if valid_594659 != nil:
    section.add "X-Amz-Security-Token", valid_594659
  var valid_594660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594660 = validateParameter(valid_594660, JString, required = false,
                                 default = nil)
  if valid_594660 != nil:
    section.add "X-Amz-Content-Sha256", valid_594660
  var valid_594661 = header.getOrDefault("X-Amz-Algorithm")
  valid_594661 = validateParameter(valid_594661, JString, required = false,
                                 default = nil)
  if valid_594661 != nil:
    section.add "X-Amz-Algorithm", valid_594661
  var valid_594662 = header.getOrDefault("X-Amz-Signature")
  valid_594662 = validateParameter(valid_594662, JString, required = false,
                                 default = nil)
  if valid_594662 != nil:
    section.add "X-Amz-Signature", valid_594662
  var valid_594663 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594663 = validateParameter(valid_594663, JString, required = false,
                                 default = nil)
  if valid_594663 != nil:
    section.add "X-Amz-SignedHeaders", valid_594663
  var valid_594664 = header.getOrDefault("X-Amz-Credential")
  valid_594664 = validateParameter(valid_594664, JString, required = false,
                                 default = nil)
  if valid_594664 != nil:
    section.add "X-Amz-Credential", valid_594664
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594665: Call_PostDescribeAccountAttributes_594653; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ## 
  let valid = call_594665.validator(path, query, header, formData, body)
  let scheme = call_594665.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594665.url(scheme.get, call_594665.host, call_594665.base,
                         call_594665.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594665, url, valid)

proc call*(call_594666: Call_PostDescribeAccountAttributes_594653;
          Action: string = "DescribeAccountAttributes";
          Version: string = "2010-12-01"): Recallable =
  ## postDescribeAccountAttributes
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594667 = newJObject()
  add(query_594667, "Action", newJString(Action))
  add(query_594667, "Version", newJString(Version))
  result = call_594666.call(nil, query_594667, nil, nil, nil)

var postDescribeAccountAttributes* = Call_PostDescribeAccountAttributes_594653(
    name: "postDescribeAccountAttributes", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeAccountAttributes",
    validator: validate_PostDescribeAccountAttributes_594654, base: "/",
    url: url_PostDescribeAccountAttributes_594655,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAccountAttributes_594638 = ref object of OpenApiRestCall_593438
proc url_GetDescribeAccountAttributes_594640(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeAccountAttributes_594639(path: JsonNode; query: JsonNode;
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
  var valid_594641 = query.getOrDefault("Action")
  valid_594641 = validateParameter(valid_594641, JString, required = true, default = newJString(
      "DescribeAccountAttributes"))
  if valid_594641 != nil:
    section.add "Action", valid_594641
  var valid_594642 = query.getOrDefault("Version")
  valid_594642 = validateParameter(valid_594642, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594642 != nil:
    section.add "Version", valid_594642
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594643 = header.getOrDefault("X-Amz-Date")
  valid_594643 = validateParameter(valid_594643, JString, required = false,
                                 default = nil)
  if valid_594643 != nil:
    section.add "X-Amz-Date", valid_594643
  var valid_594644 = header.getOrDefault("X-Amz-Security-Token")
  valid_594644 = validateParameter(valid_594644, JString, required = false,
                                 default = nil)
  if valid_594644 != nil:
    section.add "X-Amz-Security-Token", valid_594644
  var valid_594645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594645 = validateParameter(valid_594645, JString, required = false,
                                 default = nil)
  if valid_594645 != nil:
    section.add "X-Amz-Content-Sha256", valid_594645
  var valid_594646 = header.getOrDefault("X-Amz-Algorithm")
  valid_594646 = validateParameter(valid_594646, JString, required = false,
                                 default = nil)
  if valid_594646 != nil:
    section.add "X-Amz-Algorithm", valid_594646
  var valid_594647 = header.getOrDefault("X-Amz-Signature")
  valid_594647 = validateParameter(valid_594647, JString, required = false,
                                 default = nil)
  if valid_594647 != nil:
    section.add "X-Amz-Signature", valid_594647
  var valid_594648 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594648 = validateParameter(valid_594648, JString, required = false,
                                 default = nil)
  if valid_594648 != nil:
    section.add "X-Amz-SignedHeaders", valid_594648
  var valid_594649 = header.getOrDefault("X-Amz-Credential")
  valid_594649 = validateParameter(valid_594649, JString, required = false,
                                 default = nil)
  if valid_594649 != nil:
    section.add "X-Amz-Credential", valid_594649
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594650: Call_GetDescribeAccountAttributes_594638; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ## 
  let valid = call_594650.validator(path, query, header, formData, body)
  let scheme = call_594650.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594650.url(scheme.get, call_594650.host, call_594650.base,
                         call_594650.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594650, url, valid)

proc call*(call_594651: Call_GetDescribeAccountAttributes_594638;
          Action: string = "DescribeAccountAttributes";
          Version: string = "2010-12-01"): Recallable =
  ## getDescribeAccountAttributes
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594652 = newJObject()
  add(query_594652, "Action", newJString(Action))
  add(query_594652, "Version", newJString(Version))
  result = call_594651.call(nil, query_594652, nil, nil, nil)

var getDescribeAccountAttributes* = Call_GetDescribeAccountAttributes_594638(
    name: "getDescribeAccountAttributes", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeAccountAttributes",
    validator: validate_GetDescribeAccountAttributes_594639, base: "/",
    url: url_GetDescribeAccountAttributes_594640,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeApplicationVersions_594687 = ref object of OpenApiRestCall_593438
proc url_PostDescribeApplicationVersions_594689(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeApplicationVersions_594688(path: JsonNode;
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
  var valid_594690 = query.getOrDefault("Action")
  valid_594690 = validateParameter(valid_594690, JString, required = true, default = newJString(
      "DescribeApplicationVersions"))
  if valid_594690 != nil:
    section.add "Action", valid_594690
  var valid_594691 = query.getOrDefault("Version")
  valid_594691 = validateParameter(valid_594691, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594691 != nil:
    section.add "Version", valid_594691
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594692 = header.getOrDefault("X-Amz-Date")
  valid_594692 = validateParameter(valid_594692, JString, required = false,
                                 default = nil)
  if valid_594692 != nil:
    section.add "X-Amz-Date", valid_594692
  var valid_594693 = header.getOrDefault("X-Amz-Security-Token")
  valid_594693 = validateParameter(valid_594693, JString, required = false,
                                 default = nil)
  if valid_594693 != nil:
    section.add "X-Amz-Security-Token", valid_594693
  var valid_594694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594694 = validateParameter(valid_594694, JString, required = false,
                                 default = nil)
  if valid_594694 != nil:
    section.add "X-Amz-Content-Sha256", valid_594694
  var valid_594695 = header.getOrDefault("X-Amz-Algorithm")
  valid_594695 = validateParameter(valid_594695, JString, required = false,
                                 default = nil)
  if valid_594695 != nil:
    section.add "X-Amz-Algorithm", valid_594695
  var valid_594696 = header.getOrDefault("X-Amz-Signature")
  valid_594696 = validateParameter(valid_594696, JString, required = false,
                                 default = nil)
  if valid_594696 != nil:
    section.add "X-Amz-Signature", valid_594696
  var valid_594697 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594697 = validateParameter(valid_594697, JString, required = false,
                                 default = nil)
  if valid_594697 != nil:
    section.add "X-Amz-SignedHeaders", valid_594697
  var valid_594698 = header.getOrDefault("X-Amz-Credential")
  valid_594698 = validateParameter(valid_594698, JString, required = false,
                                 default = nil)
  if valid_594698 != nil:
    section.add "X-Amz-Credential", valid_594698
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
  var valid_594699 = formData.getOrDefault("NextToken")
  valid_594699 = validateParameter(valid_594699, JString, required = false,
                                 default = nil)
  if valid_594699 != nil:
    section.add "NextToken", valid_594699
  var valid_594700 = formData.getOrDefault("ApplicationName")
  valid_594700 = validateParameter(valid_594700, JString, required = false,
                                 default = nil)
  if valid_594700 != nil:
    section.add "ApplicationName", valid_594700
  var valid_594701 = formData.getOrDefault("MaxRecords")
  valid_594701 = validateParameter(valid_594701, JInt, required = false, default = nil)
  if valid_594701 != nil:
    section.add "MaxRecords", valid_594701
  var valid_594702 = formData.getOrDefault("VersionLabels")
  valid_594702 = validateParameter(valid_594702, JArray, required = false,
                                 default = nil)
  if valid_594702 != nil:
    section.add "VersionLabels", valid_594702
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594703: Call_PostDescribeApplicationVersions_594687;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieve a list of application versions.
  ## 
  let valid = call_594703.validator(path, query, header, formData, body)
  let scheme = call_594703.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594703.url(scheme.get, call_594703.host, call_594703.base,
                         call_594703.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594703, url, valid)

proc call*(call_594704: Call_PostDescribeApplicationVersions_594687;
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
  var query_594705 = newJObject()
  var formData_594706 = newJObject()
  add(formData_594706, "NextToken", newJString(NextToken))
  add(query_594705, "Action", newJString(Action))
  add(formData_594706, "ApplicationName", newJString(ApplicationName))
  add(formData_594706, "MaxRecords", newJInt(MaxRecords))
  add(query_594705, "Version", newJString(Version))
  if VersionLabels != nil:
    formData_594706.add "VersionLabels", VersionLabels
  result = call_594704.call(nil, query_594705, nil, formData_594706, nil)

var postDescribeApplicationVersions* = Call_PostDescribeApplicationVersions_594687(
    name: "postDescribeApplicationVersions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplicationVersions",
    validator: validate_PostDescribeApplicationVersions_594688, base: "/",
    url: url_PostDescribeApplicationVersions_594689,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeApplicationVersions_594668 = ref object of OpenApiRestCall_593438
proc url_GetDescribeApplicationVersions_594670(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeApplicationVersions_594669(path: JsonNode;
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
  var valid_594671 = query.getOrDefault("MaxRecords")
  valid_594671 = validateParameter(valid_594671, JInt, required = false, default = nil)
  if valid_594671 != nil:
    section.add "MaxRecords", valid_594671
  var valid_594672 = query.getOrDefault("ApplicationName")
  valid_594672 = validateParameter(valid_594672, JString, required = false,
                                 default = nil)
  if valid_594672 != nil:
    section.add "ApplicationName", valid_594672
  var valid_594673 = query.getOrDefault("NextToken")
  valid_594673 = validateParameter(valid_594673, JString, required = false,
                                 default = nil)
  if valid_594673 != nil:
    section.add "NextToken", valid_594673
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594674 = query.getOrDefault("Action")
  valid_594674 = validateParameter(valid_594674, JString, required = true, default = newJString(
      "DescribeApplicationVersions"))
  if valid_594674 != nil:
    section.add "Action", valid_594674
  var valid_594675 = query.getOrDefault("VersionLabels")
  valid_594675 = validateParameter(valid_594675, JArray, required = false,
                                 default = nil)
  if valid_594675 != nil:
    section.add "VersionLabels", valid_594675
  var valid_594676 = query.getOrDefault("Version")
  valid_594676 = validateParameter(valid_594676, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594676 != nil:
    section.add "Version", valid_594676
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594677 = header.getOrDefault("X-Amz-Date")
  valid_594677 = validateParameter(valid_594677, JString, required = false,
                                 default = nil)
  if valid_594677 != nil:
    section.add "X-Amz-Date", valid_594677
  var valid_594678 = header.getOrDefault("X-Amz-Security-Token")
  valid_594678 = validateParameter(valid_594678, JString, required = false,
                                 default = nil)
  if valid_594678 != nil:
    section.add "X-Amz-Security-Token", valid_594678
  var valid_594679 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594679 = validateParameter(valid_594679, JString, required = false,
                                 default = nil)
  if valid_594679 != nil:
    section.add "X-Amz-Content-Sha256", valid_594679
  var valid_594680 = header.getOrDefault("X-Amz-Algorithm")
  valid_594680 = validateParameter(valid_594680, JString, required = false,
                                 default = nil)
  if valid_594680 != nil:
    section.add "X-Amz-Algorithm", valid_594680
  var valid_594681 = header.getOrDefault("X-Amz-Signature")
  valid_594681 = validateParameter(valid_594681, JString, required = false,
                                 default = nil)
  if valid_594681 != nil:
    section.add "X-Amz-Signature", valid_594681
  var valid_594682 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594682 = validateParameter(valid_594682, JString, required = false,
                                 default = nil)
  if valid_594682 != nil:
    section.add "X-Amz-SignedHeaders", valid_594682
  var valid_594683 = header.getOrDefault("X-Amz-Credential")
  valid_594683 = validateParameter(valid_594683, JString, required = false,
                                 default = nil)
  if valid_594683 != nil:
    section.add "X-Amz-Credential", valid_594683
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594684: Call_GetDescribeApplicationVersions_594668; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a list of application versions.
  ## 
  let valid = call_594684.validator(path, query, header, formData, body)
  let scheme = call_594684.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594684.url(scheme.get, call_594684.host, call_594684.base,
                         call_594684.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594684, url, valid)

proc call*(call_594685: Call_GetDescribeApplicationVersions_594668;
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
  var query_594686 = newJObject()
  add(query_594686, "MaxRecords", newJInt(MaxRecords))
  add(query_594686, "ApplicationName", newJString(ApplicationName))
  add(query_594686, "NextToken", newJString(NextToken))
  add(query_594686, "Action", newJString(Action))
  if VersionLabels != nil:
    query_594686.add "VersionLabels", VersionLabels
  add(query_594686, "Version", newJString(Version))
  result = call_594685.call(nil, query_594686, nil, nil, nil)

var getDescribeApplicationVersions* = Call_GetDescribeApplicationVersions_594668(
    name: "getDescribeApplicationVersions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplicationVersions",
    validator: validate_GetDescribeApplicationVersions_594669, base: "/",
    url: url_GetDescribeApplicationVersions_594670,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeApplications_594723 = ref object of OpenApiRestCall_593438
proc url_PostDescribeApplications_594725(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeApplications_594724(path: JsonNode; query: JsonNode;
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
  var valid_594726 = query.getOrDefault("Action")
  valid_594726 = validateParameter(valid_594726, JString, required = true,
                                 default = newJString("DescribeApplications"))
  if valid_594726 != nil:
    section.add "Action", valid_594726
  var valid_594727 = query.getOrDefault("Version")
  valid_594727 = validateParameter(valid_594727, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594727 != nil:
    section.add "Version", valid_594727
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594728 = header.getOrDefault("X-Amz-Date")
  valid_594728 = validateParameter(valid_594728, JString, required = false,
                                 default = nil)
  if valid_594728 != nil:
    section.add "X-Amz-Date", valid_594728
  var valid_594729 = header.getOrDefault("X-Amz-Security-Token")
  valid_594729 = validateParameter(valid_594729, JString, required = false,
                                 default = nil)
  if valid_594729 != nil:
    section.add "X-Amz-Security-Token", valid_594729
  var valid_594730 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594730 = validateParameter(valid_594730, JString, required = false,
                                 default = nil)
  if valid_594730 != nil:
    section.add "X-Amz-Content-Sha256", valid_594730
  var valid_594731 = header.getOrDefault("X-Amz-Algorithm")
  valid_594731 = validateParameter(valid_594731, JString, required = false,
                                 default = nil)
  if valid_594731 != nil:
    section.add "X-Amz-Algorithm", valid_594731
  var valid_594732 = header.getOrDefault("X-Amz-Signature")
  valid_594732 = validateParameter(valid_594732, JString, required = false,
                                 default = nil)
  if valid_594732 != nil:
    section.add "X-Amz-Signature", valid_594732
  var valid_594733 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594733 = validateParameter(valid_594733, JString, required = false,
                                 default = nil)
  if valid_594733 != nil:
    section.add "X-Amz-SignedHeaders", valid_594733
  var valid_594734 = header.getOrDefault("X-Amz-Credential")
  valid_594734 = validateParameter(valid_594734, JString, required = false,
                                 default = nil)
  if valid_594734 != nil:
    section.add "X-Amz-Credential", valid_594734
  result.add "header", section
  ## parameters in `formData` object:
  ##   ApplicationNames: JArray
  ##                   : If specified, AWS Elastic Beanstalk restricts the returned descriptions to only include those with the specified names.
  section = newJObject()
  var valid_594735 = formData.getOrDefault("ApplicationNames")
  valid_594735 = validateParameter(valid_594735, JArray, required = false,
                                 default = nil)
  if valid_594735 != nil:
    section.add "ApplicationNames", valid_594735
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594736: Call_PostDescribeApplications_594723; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the descriptions of existing applications.
  ## 
  let valid = call_594736.validator(path, query, header, formData, body)
  let scheme = call_594736.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594736.url(scheme.get, call_594736.host, call_594736.base,
                         call_594736.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594736, url, valid)

proc call*(call_594737: Call_PostDescribeApplications_594723;
          ApplicationNames: JsonNode = nil; Action: string = "DescribeApplications";
          Version: string = "2010-12-01"): Recallable =
  ## postDescribeApplications
  ## Returns the descriptions of existing applications.
  ##   ApplicationNames: JArray
  ##                   : If specified, AWS Elastic Beanstalk restricts the returned descriptions to only include those with the specified names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594738 = newJObject()
  var formData_594739 = newJObject()
  if ApplicationNames != nil:
    formData_594739.add "ApplicationNames", ApplicationNames
  add(query_594738, "Action", newJString(Action))
  add(query_594738, "Version", newJString(Version))
  result = call_594737.call(nil, query_594738, nil, formData_594739, nil)

var postDescribeApplications* = Call_PostDescribeApplications_594723(
    name: "postDescribeApplications", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplications",
    validator: validate_PostDescribeApplications_594724, base: "/",
    url: url_PostDescribeApplications_594725, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeApplications_594707 = ref object of OpenApiRestCall_593438
proc url_GetDescribeApplications_594709(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeApplications_594708(path: JsonNode; query: JsonNode;
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
  var valid_594710 = query.getOrDefault("ApplicationNames")
  valid_594710 = validateParameter(valid_594710, JArray, required = false,
                                 default = nil)
  if valid_594710 != nil:
    section.add "ApplicationNames", valid_594710
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594711 = query.getOrDefault("Action")
  valid_594711 = validateParameter(valid_594711, JString, required = true,
                                 default = newJString("DescribeApplications"))
  if valid_594711 != nil:
    section.add "Action", valid_594711
  var valid_594712 = query.getOrDefault("Version")
  valid_594712 = validateParameter(valid_594712, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594712 != nil:
    section.add "Version", valid_594712
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594713 = header.getOrDefault("X-Amz-Date")
  valid_594713 = validateParameter(valid_594713, JString, required = false,
                                 default = nil)
  if valid_594713 != nil:
    section.add "X-Amz-Date", valid_594713
  var valid_594714 = header.getOrDefault("X-Amz-Security-Token")
  valid_594714 = validateParameter(valid_594714, JString, required = false,
                                 default = nil)
  if valid_594714 != nil:
    section.add "X-Amz-Security-Token", valid_594714
  var valid_594715 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594715 = validateParameter(valid_594715, JString, required = false,
                                 default = nil)
  if valid_594715 != nil:
    section.add "X-Amz-Content-Sha256", valid_594715
  var valid_594716 = header.getOrDefault("X-Amz-Algorithm")
  valid_594716 = validateParameter(valid_594716, JString, required = false,
                                 default = nil)
  if valid_594716 != nil:
    section.add "X-Amz-Algorithm", valid_594716
  var valid_594717 = header.getOrDefault("X-Amz-Signature")
  valid_594717 = validateParameter(valid_594717, JString, required = false,
                                 default = nil)
  if valid_594717 != nil:
    section.add "X-Amz-Signature", valid_594717
  var valid_594718 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594718 = validateParameter(valid_594718, JString, required = false,
                                 default = nil)
  if valid_594718 != nil:
    section.add "X-Amz-SignedHeaders", valid_594718
  var valid_594719 = header.getOrDefault("X-Amz-Credential")
  valid_594719 = validateParameter(valid_594719, JString, required = false,
                                 default = nil)
  if valid_594719 != nil:
    section.add "X-Amz-Credential", valid_594719
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594720: Call_GetDescribeApplications_594707; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the descriptions of existing applications.
  ## 
  let valid = call_594720.validator(path, query, header, formData, body)
  let scheme = call_594720.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594720.url(scheme.get, call_594720.host, call_594720.base,
                         call_594720.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594720, url, valid)

proc call*(call_594721: Call_GetDescribeApplications_594707;
          ApplicationNames: JsonNode = nil; Action: string = "DescribeApplications";
          Version: string = "2010-12-01"): Recallable =
  ## getDescribeApplications
  ## Returns the descriptions of existing applications.
  ##   ApplicationNames: JArray
  ##                   : If specified, AWS Elastic Beanstalk restricts the returned descriptions to only include those with the specified names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594722 = newJObject()
  if ApplicationNames != nil:
    query_594722.add "ApplicationNames", ApplicationNames
  add(query_594722, "Action", newJString(Action))
  add(query_594722, "Version", newJString(Version))
  result = call_594721.call(nil, query_594722, nil, nil, nil)

var getDescribeApplications* = Call_GetDescribeApplications_594707(
    name: "getDescribeApplications", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplications",
    validator: validate_GetDescribeApplications_594708, base: "/",
    url: url_GetDescribeApplications_594709, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeConfigurationOptions_594761 = ref object of OpenApiRestCall_593438
proc url_PostDescribeConfigurationOptions_594763(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeConfigurationOptions_594762(path: JsonNode;
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
  var valid_594764 = query.getOrDefault("Action")
  valid_594764 = validateParameter(valid_594764, JString, required = true, default = newJString(
      "DescribeConfigurationOptions"))
  if valid_594764 != nil:
    section.add "Action", valid_594764
  var valid_594765 = query.getOrDefault("Version")
  valid_594765 = validateParameter(valid_594765, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594765 != nil:
    section.add "Version", valid_594765
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594766 = header.getOrDefault("X-Amz-Date")
  valid_594766 = validateParameter(valid_594766, JString, required = false,
                                 default = nil)
  if valid_594766 != nil:
    section.add "X-Amz-Date", valid_594766
  var valid_594767 = header.getOrDefault("X-Amz-Security-Token")
  valid_594767 = validateParameter(valid_594767, JString, required = false,
                                 default = nil)
  if valid_594767 != nil:
    section.add "X-Amz-Security-Token", valid_594767
  var valid_594768 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594768 = validateParameter(valid_594768, JString, required = false,
                                 default = nil)
  if valid_594768 != nil:
    section.add "X-Amz-Content-Sha256", valid_594768
  var valid_594769 = header.getOrDefault("X-Amz-Algorithm")
  valid_594769 = validateParameter(valid_594769, JString, required = false,
                                 default = nil)
  if valid_594769 != nil:
    section.add "X-Amz-Algorithm", valid_594769
  var valid_594770 = header.getOrDefault("X-Amz-Signature")
  valid_594770 = validateParameter(valid_594770, JString, required = false,
                                 default = nil)
  if valid_594770 != nil:
    section.add "X-Amz-Signature", valid_594770
  var valid_594771 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594771 = validateParameter(valid_594771, JString, required = false,
                                 default = nil)
  if valid_594771 != nil:
    section.add "X-Amz-SignedHeaders", valid_594771
  var valid_594772 = header.getOrDefault("X-Amz-Credential")
  valid_594772 = validateParameter(valid_594772, JString, required = false,
                                 default = nil)
  if valid_594772 != nil:
    section.add "X-Amz-Credential", valid_594772
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
  var valid_594773 = formData.getOrDefault("Options")
  valid_594773 = validateParameter(valid_594773, JArray, required = false,
                                 default = nil)
  if valid_594773 != nil:
    section.add "Options", valid_594773
  var valid_594774 = formData.getOrDefault("SolutionStackName")
  valid_594774 = validateParameter(valid_594774, JString, required = false,
                                 default = nil)
  if valid_594774 != nil:
    section.add "SolutionStackName", valid_594774
  var valid_594775 = formData.getOrDefault("EnvironmentName")
  valid_594775 = validateParameter(valid_594775, JString, required = false,
                                 default = nil)
  if valid_594775 != nil:
    section.add "EnvironmentName", valid_594775
  var valid_594776 = formData.getOrDefault("ApplicationName")
  valid_594776 = validateParameter(valid_594776, JString, required = false,
                                 default = nil)
  if valid_594776 != nil:
    section.add "ApplicationName", valid_594776
  var valid_594777 = formData.getOrDefault("PlatformArn")
  valid_594777 = validateParameter(valid_594777, JString, required = false,
                                 default = nil)
  if valid_594777 != nil:
    section.add "PlatformArn", valid_594777
  var valid_594778 = formData.getOrDefault("TemplateName")
  valid_594778 = validateParameter(valid_594778, JString, required = false,
                                 default = nil)
  if valid_594778 != nil:
    section.add "TemplateName", valid_594778
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594779: Call_PostDescribeConfigurationOptions_594761;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the configuration options that are used in a particular configuration template or environment, or that a specified solution stack defines. The description includes the values the options, their default values, and an indication of the required action on a running environment if an option value is changed.
  ## 
  let valid = call_594779.validator(path, query, header, formData, body)
  let scheme = call_594779.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594779.url(scheme.get, call_594779.host, call_594779.base,
                         call_594779.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594779, url, valid)

proc call*(call_594780: Call_PostDescribeConfigurationOptions_594761;
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
  var query_594781 = newJObject()
  var formData_594782 = newJObject()
  if Options != nil:
    formData_594782.add "Options", Options
  add(formData_594782, "SolutionStackName", newJString(SolutionStackName))
  add(formData_594782, "EnvironmentName", newJString(EnvironmentName))
  add(query_594781, "Action", newJString(Action))
  add(formData_594782, "ApplicationName", newJString(ApplicationName))
  add(formData_594782, "PlatformArn", newJString(PlatformArn))
  add(formData_594782, "TemplateName", newJString(TemplateName))
  add(query_594781, "Version", newJString(Version))
  result = call_594780.call(nil, query_594781, nil, formData_594782, nil)

var postDescribeConfigurationOptions* = Call_PostDescribeConfigurationOptions_594761(
    name: "postDescribeConfigurationOptions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationOptions",
    validator: validate_PostDescribeConfigurationOptions_594762, base: "/",
    url: url_PostDescribeConfigurationOptions_594763,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeConfigurationOptions_594740 = ref object of OpenApiRestCall_593438
proc url_GetDescribeConfigurationOptions_594742(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeConfigurationOptions_594741(path: JsonNode;
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
  var valid_594743 = query.getOrDefault("Options")
  valid_594743 = validateParameter(valid_594743, JArray, required = false,
                                 default = nil)
  if valid_594743 != nil:
    section.add "Options", valid_594743
  var valid_594744 = query.getOrDefault("ApplicationName")
  valid_594744 = validateParameter(valid_594744, JString, required = false,
                                 default = nil)
  if valid_594744 != nil:
    section.add "ApplicationName", valid_594744
  var valid_594745 = query.getOrDefault("PlatformArn")
  valid_594745 = validateParameter(valid_594745, JString, required = false,
                                 default = nil)
  if valid_594745 != nil:
    section.add "PlatformArn", valid_594745
  var valid_594746 = query.getOrDefault("EnvironmentName")
  valid_594746 = validateParameter(valid_594746, JString, required = false,
                                 default = nil)
  if valid_594746 != nil:
    section.add "EnvironmentName", valid_594746
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594747 = query.getOrDefault("Action")
  valid_594747 = validateParameter(valid_594747, JString, required = true, default = newJString(
      "DescribeConfigurationOptions"))
  if valid_594747 != nil:
    section.add "Action", valid_594747
  var valid_594748 = query.getOrDefault("SolutionStackName")
  valid_594748 = validateParameter(valid_594748, JString, required = false,
                                 default = nil)
  if valid_594748 != nil:
    section.add "SolutionStackName", valid_594748
  var valid_594749 = query.getOrDefault("TemplateName")
  valid_594749 = validateParameter(valid_594749, JString, required = false,
                                 default = nil)
  if valid_594749 != nil:
    section.add "TemplateName", valid_594749
  var valid_594750 = query.getOrDefault("Version")
  valid_594750 = validateParameter(valid_594750, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594750 != nil:
    section.add "Version", valid_594750
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594751 = header.getOrDefault("X-Amz-Date")
  valid_594751 = validateParameter(valid_594751, JString, required = false,
                                 default = nil)
  if valid_594751 != nil:
    section.add "X-Amz-Date", valid_594751
  var valid_594752 = header.getOrDefault("X-Amz-Security-Token")
  valid_594752 = validateParameter(valid_594752, JString, required = false,
                                 default = nil)
  if valid_594752 != nil:
    section.add "X-Amz-Security-Token", valid_594752
  var valid_594753 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594753 = validateParameter(valid_594753, JString, required = false,
                                 default = nil)
  if valid_594753 != nil:
    section.add "X-Amz-Content-Sha256", valid_594753
  var valid_594754 = header.getOrDefault("X-Amz-Algorithm")
  valid_594754 = validateParameter(valid_594754, JString, required = false,
                                 default = nil)
  if valid_594754 != nil:
    section.add "X-Amz-Algorithm", valid_594754
  var valid_594755 = header.getOrDefault("X-Amz-Signature")
  valid_594755 = validateParameter(valid_594755, JString, required = false,
                                 default = nil)
  if valid_594755 != nil:
    section.add "X-Amz-Signature", valid_594755
  var valid_594756 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594756 = validateParameter(valid_594756, JString, required = false,
                                 default = nil)
  if valid_594756 != nil:
    section.add "X-Amz-SignedHeaders", valid_594756
  var valid_594757 = header.getOrDefault("X-Amz-Credential")
  valid_594757 = validateParameter(valid_594757, JString, required = false,
                                 default = nil)
  if valid_594757 != nil:
    section.add "X-Amz-Credential", valid_594757
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594758: Call_GetDescribeConfigurationOptions_594740;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the configuration options that are used in a particular configuration template or environment, or that a specified solution stack defines. The description includes the values the options, their default values, and an indication of the required action on a running environment if an option value is changed.
  ## 
  let valid = call_594758.validator(path, query, header, formData, body)
  let scheme = call_594758.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594758.url(scheme.get, call_594758.host, call_594758.base,
                         call_594758.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594758, url, valid)

proc call*(call_594759: Call_GetDescribeConfigurationOptions_594740;
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
  var query_594760 = newJObject()
  if Options != nil:
    query_594760.add "Options", Options
  add(query_594760, "ApplicationName", newJString(ApplicationName))
  add(query_594760, "PlatformArn", newJString(PlatformArn))
  add(query_594760, "EnvironmentName", newJString(EnvironmentName))
  add(query_594760, "Action", newJString(Action))
  add(query_594760, "SolutionStackName", newJString(SolutionStackName))
  add(query_594760, "TemplateName", newJString(TemplateName))
  add(query_594760, "Version", newJString(Version))
  result = call_594759.call(nil, query_594760, nil, nil, nil)

var getDescribeConfigurationOptions* = Call_GetDescribeConfigurationOptions_594740(
    name: "getDescribeConfigurationOptions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationOptions",
    validator: validate_GetDescribeConfigurationOptions_594741, base: "/",
    url: url_GetDescribeConfigurationOptions_594742,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeConfigurationSettings_594801 = ref object of OpenApiRestCall_593438
proc url_PostDescribeConfigurationSettings_594803(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeConfigurationSettings_594802(path: JsonNode;
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
  var valid_594804 = query.getOrDefault("Action")
  valid_594804 = validateParameter(valid_594804, JString, required = true, default = newJString(
      "DescribeConfigurationSettings"))
  if valid_594804 != nil:
    section.add "Action", valid_594804
  var valid_594805 = query.getOrDefault("Version")
  valid_594805 = validateParameter(valid_594805, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594805 != nil:
    section.add "Version", valid_594805
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594806 = header.getOrDefault("X-Amz-Date")
  valid_594806 = validateParameter(valid_594806, JString, required = false,
                                 default = nil)
  if valid_594806 != nil:
    section.add "X-Amz-Date", valid_594806
  var valid_594807 = header.getOrDefault("X-Amz-Security-Token")
  valid_594807 = validateParameter(valid_594807, JString, required = false,
                                 default = nil)
  if valid_594807 != nil:
    section.add "X-Amz-Security-Token", valid_594807
  var valid_594808 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594808 = validateParameter(valid_594808, JString, required = false,
                                 default = nil)
  if valid_594808 != nil:
    section.add "X-Amz-Content-Sha256", valid_594808
  var valid_594809 = header.getOrDefault("X-Amz-Algorithm")
  valid_594809 = validateParameter(valid_594809, JString, required = false,
                                 default = nil)
  if valid_594809 != nil:
    section.add "X-Amz-Algorithm", valid_594809
  var valid_594810 = header.getOrDefault("X-Amz-Signature")
  valid_594810 = validateParameter(valid_594810, JString, required = false,
                                 default = nil)
  if valid_594810 != nil:
    section.add "X-Amz-Signature", valid_594810
  var valid_594811 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594811 = validateParameter(valid_594811, JString, required = false,
                                 default = nil)
  if valid_594811 != nil:
    section.add "X-Amz-SignedHeaders", valid_594811
  var valid_594812 = header.getOrDefault("X-Amz-Credential")
  valid_594812 = validateParameter(valid_594812, JString, required = false,
                                 default = nil)
  if valid_594812 != nil:
    section.add "X-Amz-Credential", valid_594812
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to describe.</p> <p> Condition: You must specify either this or a TemplateName, but not both. If you specify both, AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   ApplicationName: JString (required)
  ##                  : The application for the environment or configuration template.
  ##   TemplateName: JString
  ##               : <p>The name of the configuration template to describe.</p> <p> Conditional: You must specify either this parameter or an EnvironmentName, but not both. If you specify both, AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. If you do not specify either, AWS Elastic Beanstalk returns a <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_594813 = formData.getOrDefault("EnvironmentName")
  valid_594813 = validateParameter(valid_594813, JString, required = false,
                                 default = nil)
  if valid_594813 != nil:
    section.add "EnvironmentName", valid_594813
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_594814 = formData.getOrDefault("ApplicationName")
  valid_594814 = validateParameter(valid_594814, JString, required = true,
                                 default = nil)
  if valid_594814 != nil:
    section.add "ApplicationName", valid_594814
  var valid_594815 = formData.getOrDefault("TemplateName")
  valid_594815 = validateParameter(valid_594815, JString, required = false,
                                 default = nil)
  if valid_594815 != nil:
    section.add "TemplateName", valid_594815
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594816: Call_PostDescribeConfigurationSettings_594801;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a description of the settings for the specified configuration set, that is, either a configuration template or the configuration set associated with a running environment.</p> <p>When describing the settings for the configuration set associated with a running environment, it is possible to receive two sets of setting descriptions. One is the deployed configuration set, and the other is a draft configuration of an environment that is either in the process of deployment or that failed to deploy.</p> <p>Related Topics</p> <ul> <li> <p> <a>DeleteEnvironmentConfiguration</a> </p> </li> </ul>
  ## 
  let valid = call_594816.validator(path, query, header, formData, body)
  let scheme = call_594816.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594816.url(scheme.get, call_594816.host, call_594816.base,
                         call_594816.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594816, url, valid)

proc call*(call_594817: Call_PostDescribeConfigurationSettings_594801;
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
  var query_594818 = newJObject()
  var formData_594819 = newJObject()
  add(formData_594819, "EnvironmentName", newJString(EnvironmentName))
  add(query_594818, "Action", newJString(Action))
  add(formData_594819, "ApplicationName", newJString(ApplicationName))
  add(formData_594819, "TemplateName", newJString(TemplateName))
  add(query_594818, "Version", newJString(Version))
  result = call_594817.call(nil, query_594818, nil, formData_594819, nil)

var postDescribeConfigurationSettings* = Call_PostDescribeConfigurationSettings_594801(
    name: "postDescribeConfigurationSettings", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationSettings",
    validator: validate_PostDescribeConfigurationSettings_594802, base: "/",
    url: url_PostDescribeConfigurationSettings_594803,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeConfigurationSettings_594783 = ref object of OpenApiRestCall_593438
proc url_GetDescribeConfigurationSettings_594785(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeConfigurationSettings_594784(path: JsonNode;
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
  var valid_594786 = query.getOrDefault("ApplicationName")
  valid_594786 = validateParameter(valid_594786, JString, required = true,
                                 default = nil)
  if valid_594786 != nil:
    section.add "ApplicationName", valid_594786
  var valid_594787 = query.getOrDefault("EnvironmentName")
  valid_594787 = validateParameter(valid_594787, JString, required = false,
                                 default = nil)
  if valid_594787 != nil:
    section.add "EnvironmentName", valid_594787
  var valid_594788 = query.getOrDefault("Action")
  valid_594788 = validateParameter(valid_594788, JString, required = true, default = newJString(
      "DescribeConfigurationSettings"))
  if valid_594788 != nil:
    section.add "Action", valid_594788
  var valid_594789 = query.getOrDefault("TemplateName")
  valid_594789 = validateParameter(valid_594789, JString, required = false,
                                 default = nil)
  if valid_594789 != nil:
    section.add "TemplateName", valid_594789
  var valid_594790 = query.getOrDefault("Version")
  valid_594790 = validateParameter(valid_594790, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594790 != nil:
    section.add "Version", valid_594790
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594791 = header.getOrDefault("X-Amz-Date")
  valid_594791 = validateParameter(valid_594791, JString, required = false,
                                 default = nil)
  if valid_594791 != nil:
    section.add "X-Amz-Date", valid_594791
  var valid_594792 = header.getOrDefault("X-Amz-Security-Token")
  valid_594792 = validateParameter(valid_594792, JString, required = false,
                                 default = nil)
  if valid_594792 != nil:
    section.add "X-Amz-Security-Token", valid_594792
  var valid_594793 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594793 = validateParameter(valid_594793, JString, required = false,
                                 default = nil)
  if valid_594793 != nil:
    section.add "X-Amz-Content-Sha256", valid_594793
  var valid_594794 = header.getOrDefault("X-Amz-Algorithm")
  valid_594794 = validateParameter(valid_594794, JString, required = false,
                                 default = nil)
  if valid_594794 != nil:
    section.add "X-Amz-Algorithm", valid_594794
  var valid_594795 = header.getOrDefault("X-Amz-Signature")
  valid_594795 = validateParameter(valid_594795, JString, required = false,
                                 default = nil)
  if valid_594795 != nil:
    section.add "X-Amz-Signature", valid_594795
  var valid_594796 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594796 = validateParameter(valid_594796, JString, required = false,
                                 default = nil)
  if valid_594796 != nil:
    section.add "X-Amz-SignedHeaders", valid_594796
  var valid_594797 = header.getOrDefault("X-Amz-Credential")
  valid_594797 = validateParameter(valid_594797, JString, required = false,
                                 default = nil)
  if valid_594797 != nil:
    section.add "X-Amz-Credential", valid_594797
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594798: Call_GetDescribeConfigurationSettings_594783;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a description of the settings for the specified configuration set, that is, either a configuration template or the configuration set associated with a running environment.</p> <p>When describing the settings for the configuration set associated with a running environment, it is possible to receive two sets of setting descriptions. One is the deployed configuration set, and the other is a draft configuration of an environment that is either in the process of deployment or that failed to deploy.</p> <p>Related Topics</p> <ul> <li> <p> <a>DeleteEnvironmentConfiguration</a> </p> </li> </ul>
  ## 
  let valid = call_594798.validator(path, query, header, formData, body)
  let scheme = call_594798.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594798.url(scheme.get, call_594798.host, call_594798.base,
                         call_594798.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594798, url, valid)

proc call*(call_594799: Call_GetDescribeConfigurationSettings_594783;
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
  var query_594800 = newJObject()
  add(query_594800, "ApplicationName", newJString(ApplicationName))
  add(query_594800, "EnvironmentName", newJString(EnvironmentName))
  add(query_594800, "Action", newJString(Action))
  add(query_594800, "TemplateName", newJString(TemplateName))
  add(query_594800, "Version", newJString(Version))
  result = call_594799.call(nil, query_594800, nil, nil, nil)

var getDescribeConfigurationSettings* = Call_GetDescribeConfigurationSettings_594783(
    name: "getDescribeConfigurationSettings", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationSettings",
    validator: validate_GetDescribeConfigurationSettings_594784, base: "/",
    url: url_GetDescribeConfigurationSettings_594785,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentHealth_594838 = ref object of OpenApiRestCall_593438
proc url_PostDescribeEnvironmentHealth_594840(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEnvironmentHealth_594839(path: JsonNode; query: JsonNode;
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
  var valid_594841 = query.getOrDefault("Action")
  valid_594841 = validateParameter(valid_594841, JString, required = true, default = newJString(
      "DescribeEnvironmentHealth"))
  if valid_594841 != nil:
    section.add "Action", valid_594841
  var valid_594842 = query.getOrDefault("Version")
  valid_594842 = validateParameter(valid_594842, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594842 != nil:
    section.add "Version", valid_594842
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594843 = header.getOrDefault("X-Amz-Date")
  valid_594843 = validateParameter(valid_594843, JString, required = false,
                                 default = nil)
  if valid_594843 != nil:
    section.add "X-Amz-Date", valid_594843
  var valid_594844 = header.getOrDefault("X-Amz-Security-Token")
  valid_594844 = validateParameter(valid_594844, JString, required = false,
                                 default = nil)
  if valid_594844 != nil:
    section.add "X-Amz-Security-Token", valid_594844
  var valid_594845 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594845 = validateParameter(valid_594845, JString, required = false,
                                 default = nil)
  if valid_594845 != nil:
    section.add "X-Amz-Content-Sha256", valid_594845
  var valid_594846 = header.getOrDefault("X-Amz-Algorithm")
  valid_594846 = validateParameter(valid_594846, JString, required = false,
                                 default = nil)
  if valid_594846 != nil:
    section.add "X-Amz-Algorithm", valid_594846
  var valid_594847 = header.getOrDefault("X-Amz-Signature")
  valid_594847 = validateParameter(valid_594847, JString, required = false,
                                 default = nil)
  if valid_594847 != nil:
    section.add "X-Amz-Signature", valid_594847
  var valid_594848 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594848 = validateParameter(valid_594848, JString, required = false,
                                 default = nil)
  if valid_594848 != nil:
    section.add "X-Amz-SignedHeaders", valid_594848
  var valid_594849 = header.getOrDefault("X-Amz-Credential")
  valid_594849 = validateParameter(valid_594849, JString, required = false,
                                 default = nil)
  if valid_594849 != nil:
    section.add "X-Amz-Credential", valid_594849
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentId: JString
  ##                : <p>Specify the environment by ID.</p> <p>You must specify either this or an EnvironmentName, or both.</p>
  ##   EnvironmentName: JString
  ##                  : <p>Specify the environment by name.</p> <p>You must specify either this or an EnvironmentName, or both.</p>
  ##   AttributeNames: JArray
  ##                 : Specify the response elements to return. To retrieve all attributes, set to <code>All</code>. If no attribute names are specified, returns the name of the environment.
  section = newJObject()
  var valid_594850 = formData.getOrDefault("EnvironmentId")
  valid_594850 = validateParameter(valid_594850, JString, required = false,
                                 default = nil)
  if valid_594850 != nil:
    section.add "EnvironmentId", valid_594850
  var valid_594851 = formData.getOrDefault("EnvironmentName")
  valid_594851 = validateParameter(valid_594851, JString, required = false,
                                 default = nil)
  if valid_594851 != nil:
    section.add "EnvironmentName", valid_594851
  var valid_594852 = formData.getOrDefault("AttributeNames")
  valid_594852 = validateParameter(valid_594852, JArray, required = false,
                                 default = nil)
  if valid_594852 != nil:
    section.add "AttributeNames", valid_594852
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594853: Call_PostDescribeEnvironmentHealth_594838; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the overall health of the specified environment. The <b>DescribeEnvironmentHealth</b> operation is only available with AWS Elastic Beanstalk Enhanced Health.
  ## 
  let valid = call_594853.validator(path, query, header, formData, body)
  let scheme = call_594853.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594853.url(scheme.get, call_594853.host, call_594853.base,
                         call_594853.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594853, url, valid)

proc call*(call_594854: Call_PostDescribeEnvironmentHealth_594838;
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
  var query_594855 = newJObject()
  var formData_594856 = newJObject()
  add(formData_594856, "EnvironmentId", newJString(EnvironmentId))
  add(formData_594856, "EnvironmentName", newJString(EnvironmentName))
  add(query_594855, "Action", newJString(Action))
  if AttributeNames != nil:
    formData_594856.add "AttributeNames", AttributeNames
  add(query_594855, "Version", newJString(Version))
  result = call_594854.call(nil, query_594855, nil, formData_594856, nil)

var postDescribeEnvironmentHealth* = Call_PostDescribeEnvironmentHealth_594838(
    name: "postDescribeEnvironmentHealth", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentHealth",
    validator: validate_PostDescribeEnvironmentHealth_594839, base: "/",
    url: url_PostDescribeEnvironmentHealth_594840,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentHealth_594820 = ref object of OpenApiRestCall_593438
proc url_GetDescribeEnvironmentHealth_594822(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEnvironmentHealth_594821(path: JsonNode; query: JsonNode;
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
  var valid_594823 = query.getOrDefault("AttributeNames")
  valid_594823 = validateParameter(valid_594823, JArray, required = false,
                                 default = nil)
  if valid_594823 != nil:
    section.add "AttributeNames", valid_594823
  var valid_594824 = query.getOrDefault("EnvironmentName")
  valid_594824 = validateParameter(valid_594824, JString, required = false,
                                 default = nil)
  if valid_594824 != nil:
    section.add "EnvironmentName", valid_594824
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594825 = query.getOrDefault("Action")
  valid_594825 = validateParameter(valid_594825, JString, required = true, default = newJString(
      "DescribeEnvironmentHealth"))
  if valid_594825 != nil:
    section.add "Action", valid_594825
  var valid_594826 = query.getOrDefault("EnvironmentId")
  valid_594826 = validateParameter(valid_594826, JString, required = false,
                                 default = nil)
  if valid_594826 != nil:
    section.add "EnvironmentId", valid_594826
  var valid_594827 = query.getOrDefault("Version")
  valid_594827 = validateParameter(valid_594827, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594827 != nil:
    section.add "Version", valid_594827
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594828 = header.getOrDefault("X-Amz-Date")
  valid_594828 = validateParameter(valid_594828, JString, required = false,
                                 default = nil)
  if valid_594828 != nil:
    section.add "X-Amz-Date", valid_594828
  var valid_594829 = header.getOrDefault("X-Amz-Security-Token")
  valid_594829 = validateParameter(valid_594829, JString, required = false,
                                 default = nil)
  if valid_594829 != nil:
    section.add "X-Amz-Security-Token", valid_594829
  var valid_594830 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594830 = validateParameter(valid_594830, JString, required = false,
                                 default = nil)
  if valid_594830 != nil:
    section.add "X-Amz-Content-Sha256", valid_594830
  var valid_594831 = header.getOrDefault("X-Amz-Algorithm")
  valid_594831 = validateParameter(valid_594831, JString, required = false,
                                 default = nil)
  if valid_594831 != nil:
    section.add "X-Amz-Algorithm", valid_594831
  var valid_594832 = header.getOrDefault("X-Amz-Signature")
  valid_594832 = validateParameter(valid_594832, JString, required = false,
                                 default = nil)
  if valid_594832 != nil:
    section.add "X-Amz-Signature", valid_594832
  var valid_594833 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594833 = validateParameter(valid_594833, JString, required = false,
                                 default = nil)
  if valid_594833 != nil:
    section.add "X-Amz-SignedHeaders", valid_594833
  var valid_594834 = header.getOrDefault("X-Amz-Credential")
  valid_594834 = validateParameter(valid_594834, JString, required = false,
                                 default = nil)
  if valid_594834 != nil:
    section.add "X-Amz-Credential", valid_594834
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594835: Call_GetDescribeEnvironmentHealth_594820; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the overall health of the specified environment. The <b>DescribeEnvironmentHealth</b> operation is only available with AWS Elastic Beanstalk Enhanced Health.
  ## 
  let valid = call_594835.validator(path, query, header, formData, body)
  let scheme = call_594835.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594835.url(scheme.get, call_594835.host, call_594835.base,
                         call_594835.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594835, url, valid)

proc call*(call_594836: Call_GetDescribeEnvironmentHealth_594820;
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
  var query_594837 = newJObject()
  if AttributeNames != nil:
    query_594837.add "AttributeNames", AttributeNames
  add(query_594837, "EnvironmentName", newJString(EnvironmentName))
  add(query_594837, "Action", newJString(Action))
  add(query_594837, "EnvironmentId", newJString(EnvironmentId))
  add(query_594837, "Version", newJString(Version))
  result = call_594836.call(nil, query_594837, nil, nil, nil)

var getDescribeEnvironmentHealth* = Call_GetDescribeEnvironmentHealth_594820(
    name: "getDescribeEnvironmentHealth", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentHealth",
    validator: validate_GetDescribeEnvironmentHealth_594821, base: "/",
    url: url_GetDescribeEnvironmentHealth_594822,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentManagedActionHistory_594876 = ref object of OpenApiRestCall_593438
proc url_PostDescribeEnvironmentManagedActionHistory_594878(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEnvironmentManagedActionHistory_594877(path: JsonNode;
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
  var valid_594879 = query.getOrDefault("Action")
  valid_594879 = validateParameter(valid_594879, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActionHistory"))
  if valid_594879 != nil:
    section.add "Action", valid_594879
  var valid_594880 = query.getOrDefault("Version")
  valid_594880 = validateParameter(valid_594880, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594880 != nil:
    section.add "Version", valid_594880
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594881 = header.getOrDefault("X-Amz-Date")
  valid_594881 = validateParameter(valid_594881, JString, required = false,
                                 default = nil)
  if valid_594881 != nil:
    section.add "X-Amz-Date", valid_594881
  var valid_594882 = header.getOrDefault("X-Amz-Security-Token")
  valid_594882 = validateParameter(valid_594882, JString, required = false,
                                 default = nil)
  if valid_594882 != nil:
    section.add "X-Amz-Security-Token", valid_594882
  var valid_594883 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594883 = validateParameter(valid_594883, JString, required = false,
                                 default = nil)
  if valid_594883 != nil:
    section.add "X-Amz-Content-Sha256", valid_594883
  var valid_594884 = header.getOrDefault("X-Amz-Algorithm")
  valid_594884 = validateParameter(valid_594884, JString, required = false,
                                 default = nil)
  if valid_594884 != nil:
    section.add "X-Amz-Algorithm", valid_594884
  var valid_594885 = header.getOrDefault("X-Amz-Signature")
  valid_594885 = validateParameter(valid_594885, JString, required = false,
                                 default = nil)
  if valid_594885 != nil:
    section.add "X-Amz-Signature", valid_594885
  var valid_594886 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594886 = validateParameter(valid_594886, JString, required = false,
                                 default = nil)
  if valid_594886 != nil:
    section.add "X-Amz-SignedHeaders", valid_594886
  var valid_594887 = header.getOrDefault("X-Amz-Credential")
  valid_594887 = validateParameter(valid_594887, JString, required = false,
                                 default = nil)
  if valid_594887 != nil:
    section.add "X-Amz-Credential", valid_594887
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
  var valid_594888 = formData.getOrDefault("NextToken")
  valid_594888 = validateParameter(valid_594888, JString, required = false,
                                 default = nil)
  if valid_594888 != nil:
    section.add "NextToken", valid_594888
  var valid_594889 = formData.getOrDefault("EnvironmentId")
  valid_594889 = validateParameter(valid_594889, JString, required = false,
                                 default = nil)
  if valid_594889 != nil:
    section.add "EnvironmentId", valid_594889
  var valid_594890 = formData.getOrDefault("EnvironmentName")
  valid_594890 = validateParameter(valid_594890, JString, required = false,
                                 default = nil)
  if valid_594890 != nil:
    section.add "EnvironmentName", valid_594890
  var valid_594891 = formData.getOrDefault("MaxItems")
  valid_594891 = validateParameter(valid_594891, JInt, required = false, default = nil)
  if valid_594891 != nil:
    section.add "MaxItems", valid_594891
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594892: Call_PostDescribeEnvironmentManagedActionHistory_594876;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists an environment's completed and failed managed actions.
  ## 
  let valid = call_594892.validator(path, query, header, formData, body)
  let scheme = call_594892.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594892.url(scheme.get, call_594892.host, call_594892.base,
                         call_594892.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594892, url, valid)

proc call*(call_594893: Call_PostDescribeEnvironmentManagedActionHistory_594876;
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
  var query_594894 = newJObject()
  var formData_594895 = newJObject()
  add(formData_594895, "NextToken", newJString(NextToken))
  add(formData_594895, "EnvironmentId", newJString(EnvironmentId))
  add(formData_594895, "EnvironmentName", newJString(EnvironmentName))
  add(query_594894, "Action", newJString(Action))
  add(formData_594895, "MaxItems", newJInt(MaxItems))
  add(query_594894, "Version", newJString(Version))
  result = call_594893.call(nil, query_594894, nil, formData_594895, nil)

var postDescribeEnvironmentManagedActionHistory* = Call_PostDescribeEnvironmentManagedActionHistory_594876(
    name: "postDescribeEnvironmentManagedActionHistory",
    meth: HttpMethod.HttpPost, host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActionHistory",
    validator: validate_PostDescribeEnvironmentManagedActionHistory_594877,
    base: "/", url: url_PostDescribeEnvironmentManagedActionHistory_594878,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentManagedActionHistory_594857 = ref object of OpenApiRestCall_593438
proc url_GetDescribeEnvironmentManagedActionHistory_594859(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEnvironmentManagedActionHistory_594858(path: JsonNode;
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
  var valid_594860 = query.getOrDefault("NextToken")
  valid_594860 = validateParameter(valid_594860, JString, required = false,
                                 default = nil)
  if valid_594860 != nil:
    section.add "NextToken", valid_594860
  var valid_594861 = query.getOrDefault("EnvironmentName")
  valid_594861 = validateParameter(valid_594861, JString, required = false,
                                 default = nil)
  if valid_594861 != nil:
    section.add "EnvironmentName", valid_594861
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594862 = query.getOrDefault("Action")
  valid_594862 = validateParameter(valid_594862, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActionHistory"))
  if valid_594862 != nil:
    section.add "Action", valid_594862
  var valid_594863 = query.getOrDefault("EnvironmentId")
  valid_594863 = validateParameter(valid_594863, JString, required = false,
                                 default = nil)
  if valid_594863 != nil:
    section.add "EnvironmentId", valid_594863
  var valid_594864 = query.getOrDefault("MaxItems")
  valid_594864 = validateParameter(valid_594864, JInt, required = false, default = nil)
  if valid_594864 != nil:
    section.add "MaxItems", valid_594864
  var valid_594865 = query.getOrDefault("Version")
  valid_594865 = validateParameter(valid_594865, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594865 != nil:
    section.add "Version", valid_594865
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594866 = header.getOrDefault("X-Amz-Date")
  valid_594866 = validateParameter(valid_594866, JString, required = false,
                                 default = nil)
  if valid_594866 != nil:
    section.add "X-Amz-Date", valid_594866
  var valid_594867 = header.getOrDefault("X-Amz-Security-Token")
  valid_594867 = validateParameter(valid_594867, JString, required = false,
                                 default = nil)
  if valid_594867 != nil:
    section.add "X-Amz-Security-Token", valid_594867
  var valid_594868 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594868 = validateParameter(valid_594868, JString, required = false,
                                 default = nil)
  if valid_594868 != nil:
    section.add "X-Amz-Content-Sha256", valid_594868
  var valid_594869 = header.getOrDefault("X-Amz-Algorithm")
  valid_594869 = validateParameter(valid_594869, JString, required = false,
                                 default = nil)
  if valid_594869 != nil:
    section.add "X-Amz-Algorithm", valid_594869
  var valid_594870 = header.getOrDefault("X-Amz-Signature")
  valid_594870 = validateParameter(valid_594870, JString, required = false,
                                 default = nil)
  if valid_594870 != nil:
    section.add "X-Amz-Signature", valid_594870
  var valid_594871 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594871 = validateParameter(valid_594871, JString, required = false,
                                 default = nil)
  if valid_594871 != nil:
    section.add "X-Amz-SignedHeaders", valid_594871
  var valid_594872 = header.getOrDefault("X-Amz-Credential")
  valid_594872 = validateParameter(valid_594872, JString, required = false,
                                 default = nil)
  if valid_594872 != nil:
    section.add "X-Amz-Credential", valid_594872
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594873: Call_GetDescribeEnvironmentManagedActionHistory_594857;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists an environment's completed and failed managed actions.
  ## 
  let valid = call_594873.validator(path, query, header, formData, body)
  let scheme = call_594873.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594873.url(scheme.get, call_594873.host, call_594873.base,
                         call_594873.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594873, url, valid)

proc call*(call_594874: Call_GetDescribeEnvironmentManagedActionHistory_594857;
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
  var query_594875 = newJObject()
  add(query_594875, "NextToken", newJString(NextToken))
  add(query_594875, "EnvironmentName", newJString(EnvironmentName))
  add(query_594875, "Action", newJString(Action))
  add(query_594875, "EnvironmentId", newJString(EnvironmentId))
  add(query_594875, "MaxItems", newJInt(MaxItems))
  add(query_594875, "Version", newJString(Version))
  result = call_594874.call(nil, query_594875, nil, nil, nil)

var getDescribeEnvironmentManagedActionHistory* = Call_GetDescribeEnvironmentManagedActionHistory_594857(
    name: "getDescribeEnvironmentManagedActionHistory", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActionHistory",
    validator: validate_GetDescribeEnvironmentManagedActionHistory_594858,
    base: "/", url: url_GetDescribeEnvironmentManagedActionHistory_594859,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentManagedActions_594914 = ref object of OpenApiRestCall_593438
proc url_PostDescribeEnvironmentManagedActions_594916(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEnvironmentManagedActions_594915(path: JsonNode;
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
  var valid_594917 = query.getOrDefault("Action")
  valid_594917 = validateParameter(valid_594917, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActions"))
  if valid_594917 != nil:
    section.add "Action", valid_594917
  var valid_594918 = query.getOrDefault("Version")
  valid_594918 = validateParameter(valid_594918, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594918 != nil:
    section.add "Version", valid_594918
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594919 = header.getOrDefault("X-Amz-Date")
  valid_594919 = validateParameter(valid_594919, JString, required = false,
                                 default = nil)
  if valid_594919 != nil:
    section.add "X-Amz-Date", valid_594919
  var valid_594920 = header.getOrDefault("X-Amz-Security-Token")
  valid_594920 = validateParameter(valid_594920, JString, required = false,
                                 default = nil)
  if valid_594920 != nil:
    section.add "X-Amz-Security-Token", valid_594920
  var valid_594921 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594921 = validateParameter(valid_594921, JString, required = false,
                                 default = nil)
  if valid_594921 != nil:
    section.add "X-Amz-Content-Sha256", valid_594921
  var valid_594922 = header.getOrDefault("X-Amz-Algorithm")
  valid_594922 = validateParameter(valid_594922, JString, required = false,
                                 default = nil)
  if valid_594922 != nil:
    section.add "X-Amz-Algorithm", valid_594922
  var valid_594923 = header.getOrDefault("X-Amz-Signature")
  valid_594923 = validateParameter(valid_594923, JString, required = false,
                                 default = nil)
  if valid_594923 != nil:
    section.add "X-Amz-Signature", valid_594923
  var valid_594924 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594924 = validateParameter(valid_594924, JString, required = false,
                                 default = nil)
  if valid_594924 != nil:
    section.add "X-Amz-SignedHeaders", valid_594924
  var valid_594925 = header.getOrDefault("X-Amz-Credential")
  valid_594925 = validateParameter(valid_594925, JString, required = false,
                                 default = nil)
  if valid_594925 != nil:
    section.add "X-Amz-Credential", valid_594925
  result.add "header", section
  ## parameters in `formData` object:
  ##   Status: JString
  ##         : To show only actions with a particular status, specify a status.
  ##   EnvironmentId: JString
  ##                : The environment ID of the target environment.
  ##   EnvironmentName: JString
  ##                  : The name of the target environment.
  section = newJObject()
  var valid_594926 = formData.getOrDefault("Status")
  valid_594926 = validateParameter(valid_594926, JString, required = false,
                                 default = newJString("Scheduled"))
  if valid_594926 != nil:
    section.add "Status", valid_594926
  var valid_594927 = formData.getOrDefault("EnvironmentId")
  valid_594927 = validateParameter(valid_594927, JString, required = false,
                                 default = nil)
  if valid_594927 != nil:
    section.add "EnvironmentId", valid_594927
  var valid_594928 = formData.getOrDefault("EnvironmentName")
  valid_594928 = validateParameter(valid_594928, JString, required = false,
                                 default = nil)
  if valid_594928 != nil:
    section.add "EnvironmentName", valid_594928
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594929: Call_PostDescribeEnvironmentManagedActions_594914;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists an environment's upcoming and in-progress managed actions.
  ## 
  let valid = call_594929.validator(path, query, header, formData, body)
  let scheme = call_594929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594929.url(scheme.get, call_594929.host, call_594929.base,
                         call_594929.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594929, url, valid)

proc call*(call_594930: Call_PostDescribeEnvironmentManagedActions_594914;
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
  var query_594931 = newJObject()
  var formData_594932 = newJObject()
  add(formData_594932, "Status", newJString(Status))
  add(formData_594932, "EnvironmentId", newJString(EnvironmentId))
  add(formData_594932, "EnvironmentName", newJString(EnvironmentName))
  add(query_594931, "Action", newJString(Action))
  add(query_594931, "Version", newJString(Version))
  result = call_594930.call(nil, query_594931, nil, formData_594932, nil)

var postDescribeEnvironmentManagedActions* = Call_PostDescribeEnvironmentManagedActions_594914(
    name: "postDescribeEnvironmentManagedActions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActions",
    validator: validate_PostDescribeEnvironmentManagedActions_594915, base: "/",
    url: url_PostDescribeEnvironmentManagedActions_594916,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentManagedActions_594896 = ref object of OpenApiRestCall_593438
proc url_GetDescribeEnvironmentManagedActions_594898(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEnvironmentManagedActions_594897(path: JsonNode;
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
  var valid_594899 = query.getOrDefault("Status")
  valid_594899 = validateParameter(valid_594899, JString, required = false,
                                 default = newJString("Scheduled"))
  if valid_594899 != nil:
    section.add "Status", valid_594899
  var valid_594900 = query.getOrDefault("EnvironmentName")
  valid_594900 = validateParameter(valid_594900, JString, required = false,
                                 default = nil)
  if valid_594900 != nil:
    section.add "EnvironmentName", valid_594900
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594901 = query.getOrDefault("Action")
  valid_594901 = validateParameter(valid_594901, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActions"))
  if valid_594901 != nil:
    section.add "Action", valid_594901
  var valid_594902 = query.getOrDefault("EnvironmentId")
  valid_594902 = validateParameter(valid_594902, JString, required = false,
                                 default = nil)
  if valid_594902 != nil:
    section.add "EnvironmentId", valid_594902
  var valid_594903 = query.getOrDefault("Version")
  valid_594903 = validateParameter(valid_594903, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594903 != nil:
    section.add "Version", valid_594903
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594904 = header.getOrDefault("X-Amz-Date")
  valid_594904 = validateParameter(valid_594904, JString, required = false,
                                 default = nil)
  if valid_594904 != nil:
    section.add "X-Amz-Date", valid_594904
  var valid_594905 = header.getOrDefault("X-Amz-Security-Token")
  valid_594905 = validateParameter(valid_594905, JString, required = false,
                                 default = nil)
  if valid_594905 != nil:
    section.add "X-Amz-Security-Token", valid_594905
  var valid_594906 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594906 = validateParameter(valid_594906, JString, required = false,
                                 default = nil)
  if valid_594906 != nil:
    section.add "X-Amz-Content-Sha256", valid_594906
  var valid_594907 = header.getOrDefault("X-Amz-Algorithm")
  valid_594907 = validateParameter(valid_594907, JString, required = false,
                                 default = nil)
  if valid_594907 != nil:
    section.add "X-Amz-Algorithm", valid_594907
  var valid_594908 = header.getOrDefault("X-Amz-Signature")
  valid_594908 = validateParameter(valid_594908, JString, required = false,
                                 default = nil)
  if valid_594908 != nil:
    section.add "X-Amz-Signature", valid_594908
  var valid_594909 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594909 = validateParameter(valid_594909, JString, required = false,
                                 default = nil)
  if valid_594909 != nil:
    section.add "X-Amz-SignedHeaders", valid_594909
  var valid_594910 = header.getOrDefault("X-Amz-Credential")
  valid_594910 = validateParameter(valid_594910, JString, required = false,
                                 default = nil)
  if valid_594910 != nil:
    section.add "X-Amz-Credential", valid_594910
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594911: Call_GetDescribeEnvironmentManagedActions_594896;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists an environment's upcoming and in-progress managed actions.
  ## 
  let valid = call_594911.validator(path, query, header, formData, body)
  let scheme = call_594911.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594911.url(scheme.get, call_594911.host, call_594911.base,
                         call_594911.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594911, url, valid)

proc call*(call_594912: Call_GetDescribeEnvironmentManagedActions_594896;
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
  var query_594913 = newJObject()
  add(query_594913, "Status", newJString(Status))
  add(query_594913, "EnvironmentName", newJString(EnvironmentName))
  add(query_594913, "Action", newJString(Action))
  add(query_594913, "EnvironmentId", newJString(EnvironmentId))
  add(query_594913, "Version", newJString(Version))
  result = call_594912.call(nil, query_594913, nil, nil, nil)

var getDescribeEnvironmentManagedActions* = Call_GetDescribeEnvironmentManagedActions_594896(
    name: "getDescribeEnvironmentManagedActions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActions",
    validator: validate_GetDescribeEnvironmentManagedActions_594897, base: "/",
    url: url_GetDescribeEnvironmentManagedActions_594898,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentResources_594950 = ref object of OpenApiRestCall_593438
proc url_PostDescribeEnvironmentResources_594952(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEnvironmentResources_594951(path: JsonNode;
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
  var valid_594953 = query.getOrDefault("Action")
  valid_594953 = validateParameter(valid_594953, JString, required = true, default = newJString(
      "DescribeEnvironmentResources"))
  if valid_594953 != nil:
    section.add "Action", valid_594953
  var valid_594954 = query.getOrDefault("Version")
  valid_594954 = validateParameter(valid_594954, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594954 != nil:
    section.add "Version", valid_594954
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594955 = header.getOrDefault("X-Amz-Date")
  valid_594955 = validateParameter(valid_594955, JString, required = false,
                                 default = nil)
  if valid_594955 != nil:
    section.add "X-Amz-Date", valid_594955
  var valid_594956 = header.getOrDefault("X-Amz-Security-Token")
  valid_594956 = validateParameter(valid_594956, JString, required = false,
                                 default = nil)
  if valid_594956 != nil:
    section.add "X-Amz-Security-Token", valid_594956
  var valid_594957 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594957 = validateParameter(valid_594957, JString, required = false,
                                 default = nil)
  if valid_594957 != nil:
    section.add "X-Amz-Content-Sha256", valid_594957
  var valid_594958 = header.getOrDefault("X-Amz-Algorithm")
  valid_594958 = validateParameter(valid_594958, JString, required = false,
                                 default = nil)
  if valid_594958 != nil:
    section.add "X-Amz-Algorithm", valid_594958
  var valid_594959 = header.getOrDefault("X-Amz-Signature")
  valid_594959 = validateParameter(valid_594959, JString, required = false,
                                 default = nil)
  if valid_594959 != nil:
    section.add "X-Amz-Signature", valid_594959
  var valid_594960 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594960 = validateParameter(valid_594960, JString, required = false,
                                 default = nil)
  if valid_594960 != nil:
    section.add "X-Amz-SignedHeaders", valid_594960
  var valid_594961 = header.getOrDefault("X-Amz-Credential")
  valid_594961 = validateParameter(valid_594961, JString, required = false,
                                 default = nil)
  if valid_594961 != nil:
    section.add "X-Amz-Credential", valid_594961
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to retrieve AWS resource usage data.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to retrieve AWS resource usage data.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_594962 = formData.getOrDefault("EnvironmentId")
  valid_594962 = validateParameter(valid_594962, JString, required = false,
                                 default = nil)
  if valid_594962 != nil:
    section.add "EnvironmentId", valid_594962
  var valid_594963 = formData.getOrDefault("EnvironmentName")
  valid_594963 = validateParameter(valid_594963, JString, required = false,
                                 default = nil)
  if valid_594963 != nil:
    section.add "EnvironmentName", valid_594963
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594964: Call_PostDescribeEnvironmentResources_594950;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns AWS resources for this environment.
  ## 
  let valid = call_594964.validator(path, query, header, formData, body)
  let scheme = call_594964.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594964.url(scheme.get, call_594964.host, call_594964.base,
                         call_594964.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594964, url, valid)

proc call*(call_594965: Call_PostDescribeEnvironmentResources_594950;
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
  var query_594966 = newJObject()
  var formData_594967 = newJObject()
  add(formData_594967, "EnvironmentId", newJString(EnvironmentId))
  add(formData_594967, "EnvironmentName", newJString(EnvironmentName))
  add(query_594966, "Action", newJString(Action))
  add(query_594966, "Version", newJString(Version))
  result = call_594965.call(nil, query_594966, nil, formData_594967, nil)

var postDescribeEnvironmentResources* = Call_PostDescribeEnvironmentResources_594950(
    name: "postDescribeEnvironmentResources", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentResources",
    validator: validate_PostDescribeEnvironmentResources_594951, base: "/",
    url: url_PostDescribeEnvironmentResources_594952,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentResources_594933 = ref object of OpenApiRestCall_593438
proc url_GetDescribeEnvironmentResources_594935(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEnvironmentResources_594934(path: JsonNode;
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
  var valid_594936 = query.getOrDefault("EnvironmentName")
  valid_594936 = validateParameter(valid_594936, JString, required = false,
                                 default = nil)
  if valid_594936 != nil:
    section.add "EnvironmentName", valid_594936
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594937 = query.getOrDefault("Action")
  valid_594937 = validateParameter(valid_594937, JString, required = true, default = newJString(
      "DescribeEnvironmentResources"))
  if valid_594937 != nil:
    section.add "Action", valid_594937
  var valid_594938 = query.getOrDefault("EnvironmentId")
  valid_594938 = validateParameter(valid_594938, JString, required = false,
                                 default = nil)
  if valid_594938 != nil:
    section.add "EnvironmentId", valid_594938
  var valid_594939 = query.getOrDefault("Version")
  valid_594939 = validateParameter(valid_594939, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594939 != nil:
    section.add "Version", valid_594939
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594940 = header.getOrDefault("X-Amz-Date")
  valid_594940 = validateParameter(valid_594940, JString, required = false,
                                 default = nil)
  if valid_594940 != nil:
    section.add "X-Amz-Date", valid_594940
  var valid_594941 = header.getOrDefault("X-Amz-Security-Token")
  valid_594941 = validateParameter(valid_594941, JString, required = false,
                                 default = nil)
  if valid_594941 != nil:
    section.add "X-Amz-Security-Token", valid_594941
  var valid_594942 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594942 = validateParameter(valid_594942, JString, required = false,
                                 default = nil)
  if valid_594942 != nil:
    section.add "X-Amz-Content-Sha256", valid_594942
  var valid_594943 = header.getOrDefault("X-Amz-Algorithm")
  valid_594943 = validateParameter(valid_594943, JString, required = false,
                                 default = nil)
  if valid_594943 != nil:
    section.add "X-Amz-Algorithm", valid_594943
  var valid_594944 = header.getOrDefault("X-Amz-Signature")
  valid_594944 = validateParameter(valid_594944, JString, required = false,
                                 default = nil)
  if valid_594944 != nil:
    section.add "X-Amz-Signature", valid_594944
  var valid_594945 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594945 = validateParameter(valid_594945, JString, required = false,
                                 default = nil)
  if valid_594945 != nil:
    section.add "X-Amz-SignedHeaders", valid_594945
  var valid_594946 = header.getOrDefault("X-Amz-Credential")
  valid_594946 = validateParameter(valid_594946, JString, required = false,
                                 default = nil)
  if valid_594946 != nil:
    section.add "X-Amz-Credential", valid_594946
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594947: Call_GetDescribeEnvironmentResources_594933;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns AWS resources for this environment.
  ## 
  let valid = call_594947.validator(path, query, header, formData, body)
  let scheme = call_594947.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594947.url(scheme.get, call_594947.host, call_594947.base,
                         call_594947.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594947, url, valid)

proc call*(call_594948: Call_GetDescribeEnvironmentResources_594933;
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
  var query_594949 = newJObject()
  add(query_594949, "EnvironmentName", newJString(EnvironmentName))
  add(query_594949, "Action", newJString(Action))
  add(query_594949, "EnvironmentId", newJString(EnvironmentId))
  add(query_594949, "Version", newJString(Version))
  result = call_594948.call(nil, query_594949, nil, nil, nil)

var getDescribeEnvironmentResources* = Call_GetDescribeEnvironmentResources_594933(
    name: "getDescribeEnvironmentResources", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentResources",
    validator: validate_GetDescribeEnvironmentResources_594934, base: "/",
    url: url_GetDescribeEnvironmentResources_594935,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironments_594991 = ref object of OpenApiRestCall_593438
proc url_PostDescribeEnvironments_594993(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEnvironments_594992(path: JsonNode; query: JsonNode;
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
  var valid_594994 = query.getOrDefault("Action")
  valid_594994 = validateParameter(valid_594994, JString, required = true,
                                 default = newJString("DescribeEnvironments"))
  if valid_594994 != nil:
    section.add "Action", valid_594994
  var valid_594995 = query.getOrDefault("Version")
  valid_594995 = validateParameter(valid_594995, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594995 != nil:
    section.add "Version", valid_594995
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594996 = header.getOrDefault("X-Amz-Date")
  valid_594996 = validateParameter(valid_594996, JString, required = false,
                                 default = nil)
  if valid_594996 != nil:
    section.add "X-Amz-Date", valid_594996
  var valid_594997 = header.getOrDefault("X-Amz-Security-Token")
  valid_594997 = validateParameter(valid_594997, JString, required = false,
                                 default = nil)
  if valid_594997 != nil:
    section.add "X-Amz-Security-Token", valid_594997
  var valid_594998 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594998 = validateParameter(valid_594998, JString, required = false,
                                 default = nil)
  if valid_594998 != nil:
    section.add "X-Amz-Content-Sha256", valid_594998
  var valid_594999 = header.getOrDefault("X-Amz-Algorithm")
  valid_594999 = validateParameter(valid_594999, JString, required = false,
                                 default = nil)
  if valid_594999 != nil:
    section.add "X-Amz-Algorithm", valid_594999
  var valid_595000 = header.getOrDefault("X-Amz-Signature")
  valid_595000 = validateParameter(valid_595000, JString, required = false,
                                 default = nil)
  if valid_595000 != nil:
    section.add "X-Amz-Signature", valid_595000
  var valid_595001 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595001 = validateParameter(valid_595001, JString, required = false,
                                 default = nil)
  if valid_595001 != nil:
    section.add "X-Amz-SignedHeaders", valid_595001
  var valid_595002 = header.getOrDefault("X-Amz-Credential")
  valid_595002 = validateParameter(valid_595002, JString, required = false,
                                 default = nil)
  if valid_595002 != nil:
    section.add "X-Amz-Credential", valid_595002
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
  var valid_595003 = formData.getOrDefault("NextToken")
  valid_595003 = validateParameter(valid_595003, JString, required = false,
                                 default = nil)
  if valid_595003 != nil:
    section.add "NextToken", valid_595003
  var valid_595004 = formData.getOrDefault("VersionLabel")
  valid_595004 = validateParameter(valid_595004, JString, required = false,
                                 default = nil)
  if valid_595004 != nil:
    section.add "VersionLabel", valid_595004
  var valid_595005 = formData.getOrDefault("EnvironmentNames")
  valid_595005 = validateParameter(valid_595005, JArray, required = false,
                                 default = nil)
  if valid_595005 != nil:
    section.add "EnvironmentNames", valid_595005
  var valid_595006 = formData.getOrDefault("IncludedDeletedBackTo")
  valid_595006 = validateParameter(valid_595006, JString, required = false,
                                 default = nil)
  if valid_595006 != nil:
    section.add "IncludedDeletedBackTo", valid_595006
  var valid_595007 = formData.getOrDefault("ApplicationName")
  valid_595007 = validateParameter(valid_595007, JString, required = false,
                                 default = nil)
  if valid_595007 != nil:
    section.add "ApplicationName", valid_595007
  var valid_595008 = formData.getOrDefault("EnvironmentIds")
  valid_595008 = validateParameter(valid_595008, JArray, required = false,
                                 default = nil)
  if valid_595008 != nil:
    section.add "EnvironmentIds", valid_595008
  var valid_595009 = formData.getOrDefault("IncludeDeleted")
  valid_595009 = validateParameter(valid_595009, JBool, required = false, default = nil)
  if valid_595009 != nil:
    section.add "IncludeDeleted", valid_595009
  var valid_595010 = formData.getOrDefault("MaxRecords")
  valid_595010 = validateParameter(valid_595010, JInt, required = false, default = nil)
  if valid_595010 != nil:
    section.add "MaxRecords", valid_595010
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595011: Call_PostDescribeEnvironments_594991; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns descriptions for existing environments.
  ## 
  let valid = call_595011.validator(path, query, header, formData, body)
  let scheme = call_595011.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595011.url(scheme.get, call_595011.host, call_595011.base,
                         call_595011.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595011, url, valid)

proc call*(call_595012: Call_PostDescribeEnvironments_594991;
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
  var query_595013 = newJObject()
  var formData_595014 = newJObject()
  add(formData_595014, "NextToken", newJString(NextToken))
  add(formData_595014, "VersionLabel", newJString(VersionLabel))
  if EnvironmentNames != nil:
    formData_595014.add "EnvironmentNames", EnvironmentNames
  add(formData_595014, "IncludedDeletedBackTo", newJString(IncludedDeletedBackTo))
  add(query_595013, "Action", newJString(Action))
  add(formData_595014, "ApplicationName", newJString(ApplicationName))
  if EnvironmentIds != nil:
    formData_595014.add "EnvironmentIds", EnvironmentIds
  add(formData_595014, "IncludeDeleted", newJBool(IncludeDeleted))
  add(formData_595014, "MaxRecords", newJInt(MaxRecords))
  add(query_595013, "Version", newJString(Version))
  result = call_595012.call(nil, query_595013, nil, formData_595014, nil)

var postDescribeEnvironments* = Call_PostDescribeEnvironments_594991(
    name: "postDescribeEnvironments", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironments",
    validator: validate_PostDescribeEnvironments_594992, base: "/",
    url: url_PostDescribeEnvironments_594993, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironments_594968 = ref object of OpenApiRestCall_593438
proc url_GetDescribeEnvironments_594970(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEnvironments_594969(path: JsonNode; query: JsonNode;
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
  var valid_594971 = query.getOrDefault("VersionLabel")
  valid_594971 = validateParameter(valid_594971, JString, required = false,
                                 default = nil)
  if valid_594971 != nil:
    section.add "VersionLabel", valid_594971
  var valid_594972 = query.getOrDefault("MaxRecords")
  valid_594972 = validateParameter(valid_594972, JInt, required = false, default = nil)
  if valid_594972 != nil:
    section.add "MaxRecords", valid_594972
  var valid_594973 = query.getOrDefault("ApplicationName")
  valid_594973 = validateParameter(valid_594973, JString, required = false,
                                 default = nil)
  if valid_594973 != nil:
    section.add "ApplicationName", valid_594973
  var valid_594974 = query.getOrDefault("IncludeDeleted")
  valid_594974 = validateParameter(valid_594974, JBool, required = false, default = nil)
  if valid_594974 != nil:
    section.add "IncludeDeleted", valid_594974
  var valid_594975 = query.getOrDefault("NextToken")
  valid_594975 = validateParameter(valid_594975, JString, required = false,
                                 default = nil)
  if valid_594975 != nil:
    section.add "NextToken", valid_594975
  var valid_594976 = query.getOrDefault("EnvironmentIds")
  valid_594976 = validateParameter(valid_594976, JArray, required = false,
                                 default = nil)
  if valid_594976 != nil:
    section.add "EnvironmentIds", valid_594976
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594977 = query.getOrDefault("Action")
  valid_594977 = validateParameter(valid_594977, JString, required = true,
                                 default = newJString("DescribeEnvironments"))
  if valid_594977 != nil:
    section.add "Action", valid_594977
  var valid_594978 = query.getOrDefault("IncludedDeletedBackTo")
  valid_594978 = validateParameter(valid_594978, JString, required = false,
                                 default = nil)
  if valid_594978 != nil:
    section.add "IncludedDeletedBackTo", valid_594978
  var valid_594979 = query.getOrDefault("EnvironmentNames")
  valid_594979 = validateParameter(valid_594979, JArray, required = false,
                                 default = nil)
  if valid_594979 != nil:
    section.add "EnvironmentNames", valid_594979
  var valid_594980 = query.getOrDefault("Version")
  valid_594980 = validateParameter(valid_594980, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594980 != nil:
    section.add "Version", valid_594980
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594981 = header.getOrDefault("X-Amz-Date")
  valid_594981 = validateParameter(valid_594981, JString, required = false,
                                 default = nil)
  if valid_594981 != nil:
    section.add "X-Amz-Date", valid_594981
  var valid_594982 = header.getOrDefault("X-Amz-Security-Token")
  valid_594982 = validateParameter(valid_594982, JString, required = false,
                                 default = nil)
  if valid_594982 != nil:
    section.add "X-Amz-Security-Token", valid_594982
  var valid_594983 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594983 = validateParameter(valid_594983, JString, required = false,
                                 default = nil)
  if valid_594983 != nil:
    section.add "X-Amz-Content-Sha256", valid_594983
  var valid_594984 = header.getOrDefault("X-Amz-Algorithm")
  valid_594984 = validateParameter(valid_594984, JString, required = false,
                                 default = nil)
  if valid_594984 != nil:
    section.add "X-Amz-Algorithm", valid_594984
  var valid_594985 = header.getOrDefault("X-Amz-Signature")
  valid_594985 = validateParameter(valid_594985, JString, required = false,
                                 default = nil)
  if valid_594985 != nil:
    section.add "X-Amz-Signature", valid_594985
  var valid_594986 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594986 = validateParameter(valid_594986, JString, required = false,
                                 default = nil)
  if valid_594986 != nil:
    section.add "X-Amz-SignedHeaders", valid_594986
  var valid_594987 = header.getOrDefault("X-Amz-Credential")
  valid_594987 = validateParameter(valid_594987, JString, required = false,
                                 default = nil)
  if valid_594987 != nil:
    section.add "X-Amz-Credential", valid_594987
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594988: Call_GetDescribeEnvironments_594968; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns descriptions for existing environments.
  ## 
  let valid = call_594988.validator(path, query, header, formData, body)
  let scheme = call_594988.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594988.url(scheme.get, call_594988.host, call_594988.base,
                         call_594988.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594988, url, valid)

proc call*(call_594989: Call_GetDescribeEnvironments_594968;
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
  var query_594990 = newJObject()
  add(query_594990, "VersionLabel", newJString(VersionLabel))
  add(query_594990, "MaxRecords", newJInt(MaxRecords))
  add(query_594990, "ApplicationName", newJString(ApplicationName))
  add(query_594990, "IncludeDeleted", newJBool(IncludeDeleted))
  add(query_594990, "NextToken", newJString(NextToken))
  if EnvironmentIds != nil:
    query_594990.add "EnvironmentIds", EnvironmentIds
  add(query_594990, "Action", newJString(Action))
  add(query_594990, "IncludedDeletedBackTo", newJString(IncludedDeletedBackTo))
  if EnvironmentNames != nil:
    query_594990.add "EnvironmentNames", EnvironmentNames
  add(query_594990, "Version", newJString(Version))
  result = call_594989.call(nil, query_594990, nil, nil, nil)

var getDescribeEnvironments* = Call_GetDescribeEnvironments_594968(
    name: "getDescribeEnvironments", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironments",
    validator: validate_GetDescribeEnvironments_594969, base: "/",
    url: url_GetDescribeEnvironments_594970, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_595042 = ref object of OpenApiRestCall_593438
proc url_PostDescribeEvents_595044(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEvents_595043(path: JsonNode; query: JsonNode;
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
  var valid_595045 = query.getOrDefault("Action")
  valid_595045 = validateParameter(valid_595045, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_595045 != nil:
    section.add "Action", valid_595045
  var valid_595046 = query.getOrDefault("Version")
  valid_595046 = validateParameter(valid_595046, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_595046 != nil:
    section.add "Version", valid_595046
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595047 = header.getOrDefault("X-Amz-Date")
  valid_595047 = validateParameter(valid_595047, JString, required = false,
                                 default = nil)
  if valid_595047 != nil:
    section.add "X-Amz-Date", valid_595047
  var valid_595048 = header.getOrDefault("X-Amz-Security-Token")
  valid_595048 = validateParameter(valid_595048, JString, required = false,
                                 default = nil)
  if valid_595048 != nil:
    section.add "X-Amz-Security-Token", valid_595048
  var valid_595049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595049 = validateParameter(valid_595049, JString, required = false,
                                 default = nil)
  if valid_595049 != nil:
    section.add "X-Amz-Content-Sha256", valid_595049
  var valid_595050 = header.getOrDefault("X-Amz-Algorithm")
  valid_595050 = validateParameter(valid_595050, JString, required = false,
                                 default = nil)
  if valid_595050 != nil:
    section.add "X-Amz-Algorithm", valid_595050
  var valid_595051 = header.getOrDefault("X-Amz-Signature")
  valid_595051 = validateParameter(valid_595051, JString, required = false,
                                 default = nil)
  if valid_595051 != nil:
    section.add "X-Amz-Signature", valid_595051
  var valid_595052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595052 = validateParameter(valid_595052, JString, required = false,
                                 default = nil)
  if valid_595052 != nil:
    section.add "X-Amz-SignedHeaders", valid_595052
  var valid_595053 = header.getOrDefault("X-Amz-Credential")
  valid_595053 = validateParameter(valid_595053, JString, required = false,
                                 default = nil)
  if valid_595053 != nil:
    section.add "X-Amz-Credential", valid_595053
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
  var valid_595054 = formData.getOrDefault("NextToken")
  valid_595054 = validateParameter(valid_595054, JString, required = false,
                                 default = nil)
  if valid_595054 != nil:
    section.add "NextToken", valid_595054
  var valid_595055 = formData.getOrDefault("VersionLabel")
  valid_595055 = validateParameter(valid_595055, JString, required = false,
                                 default = nil)
  if valid_595055 != nil:
    section.add "VersionLabel", valid_595055
  var valid_595056 = formData.getOrDefault("Severity")
  valid_595056 = validateParameter(valid_595056, JString, required = false,
                                 default = newJString("TRACE"))
  if valid_595056 != nil:
    section.add "Severity", valid_595056
  var valid_595057 = formData.getOrDefault("EnvironmentId")
  valid_595057 = validateParameter(valid_595057, JString, required = false,
                                 default = nil)
  if valid_595057 != nil:
    section.add "EnvironmentId", valid_595057
  var valid_595058 = formData.getOrDefault("EnvironmentName")
  valid_595058 = validateParameter(valid_595058, JString, required = false,
                                 default = nil)
  if valid_595058 != nil:
    section.add "EnvironmentName", valid_595058
  var valid_595059 = formData.getOrDefault("StartTime")
  valid_595059 = validateParameter(valid_595059, JString, required = false,
                                 default = nil)
  if valid_595059 != nil:
    section.add "StartTime", valid_595059
  var valid_595060 = formData.getOrDefault("ApplicationName")
  valid_595060 = validateParameter(valid_595060, JString, required = false,
                                 default = nil)
  if valid_595060 != nil:
    section.add "ApplicationName", valid_595060
  var valid_595061 = formData.getOrDefault("EndTime")
  valid_595061 = validateParameter(valid_595061, JString, required = false,
                                 default = nil)
  if valid_595061 != nil:
    section.add "EndTime", valid_595061
  var valid_595062 = formData.getOrDefault("PlatformArn")
  valid_595062 = validateParameter(valid_595062, JString, required = false,
                                 default = nil)
  if valid_595062 != nil:
    section.add "PlatformArn", valid_595062
  var valid_595063 = formData.getOrDefault("MaxRecords")
  valid_595063 = validateParameter(valid_595063, JInt, required = false, default = nil)
  if valid_595063 != nil:
    section.add "MaxRecords", valid_595063
  var valid_595064 = formData.getOrDefault("RequestId")
  valid_595064 = validateParameter(valid_595064, JString, required = false,
                                 default = nil)
  if valid_595064 != nil:
    section.add "RequestId", valid_595064
  var valid_595065 = formData.getOrDefault("TemplateName")
  valid_595065 = validateParameter(valid_595065, JString, required = false,
                                 default = nil)
  if valid_595065 != nil:
    section.add "TemplateName", valid_595065
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595066: Call_PostDescribeEvents_595042; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns list of event descriptions matching criteria up to the last 6 weeks.</p> <note> <p>This action returns the most recent 1,000 events from the specified <code>NextToken</code>.</p> </note>
  ## 
  let valid = call_595066.validator(path, query, header, formData, body)
  let scheme = call_595066.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595066.url(scheme.get, call_595066.host, call_595066.base,
                         call_595066.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595066, url, valid)

proc call*(call_595067: Call_PostDescribeEvents_595042; NextToken: string = "";
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
  var query_595068 = newJObject()
  var formData_595069 = newJObject()
  add(formData_595069, "NextToken", newJString(NextToken))
  add(formData_595069, "VersionLabel", newJString(VersionLabel))
  add(formData_595069, "Severity", newJString(Severity))
  add(formData_595069, "EnvironmentId", newJString(EnvironmentId))
  add(formData_595069, "EnvironmentName", newJString(EnvironmentName))
  add(formData_595069, "StartTime", newJString(StartTime))
  add(query_595068, "Action", newJString(Action))
  add(formData_595069, "ApplicationName", newJString(ApplicationName))
  add(formData_595069, "EndTime", newJString(EndTime))
  add(formData_595069, "PlatformArn", newJString(PlatformArn))
  add(formData_595069, "MaxRecords", newJInt(MaxRecords))
  add(formData_595069, "RequestId", newJString(RequestId))
  add(formData_595069, "TemplateName", newJString(TemplateName))
  add(query_595068, "Version", newJString(Version))
  result = call_595067.call(nil, query_595068, nil, formData_595069, nil)

var postDescribeEvents* = Call_PostDescribeEvents_595042(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_595043, base: "/",
    url: url_PostDescribeEvents_595044, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_595015 = ref object of OpenApiRestCall_593438
proc url_GetDescribeEvents_595017(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEvents_595016(path: JsonNode; query: JsonNode;
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
  var valid_595018 = query.getOrDefault("VersionLabel")
  valid_595018 = validateParameter(valid_595018, JString, required = false,
                                 default = nil)
  if valid_595018 != nil:
    section.add "VersionLabel", valid_595018
  var valid_595019 = query.getOrDefault("MaxRecords")
  valid_595019 = validateParameter(valid_595019, JInt, required = false, default = nil)
  if valid_595019 != nil:
    section.add "MaxRecords", valid_595019
  var valid_595020 = query.getOrDefault("ApplicationName")
  valid_595020 = validateParameter(valid_595020, JString, required = false,
                                 default = nil)
  if valid_595020 != nil:
    section.add "ApplicationName", valid_595020
  var valid_595021 = query.getOrDefault("StartTime")
  valid_595021 = validateParameter(valid_595021, JString, required = false,
                                 default = nil)
  if valid_595021 != nil:
    section.add "StartTime", valid_595021
  var valid_595022 = query.getOrDefault("PlatformArn")
  valid_595022 = validateParameter(valid_595022, JString, required = false,
                                 default = nil)
  if valid_595022 != nil:
    section.add "PlatformArn", valid_595022
  var valid_595023 = query.getOrDefault("NextToken")
  valid_595023 = validateParameter(valid_595023, JString, required = false,
                                 default = nil)
  if valid_595023 != nil:
    section.add "NextToken", valid_595023
  var valid_595024 = query.getOrDefault("EnvironmentName")
  valid_595024 = validateParameter(valid_595024, JString, required = false,
                                 default = nil)
  if valid_595024 != nil:
    section.add "EnvironmentName", valid_595024
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595025 = query.getOrDefault("Action")
  valid_595025 = validateParameter(valid_595025, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_595025 != nil:
    section.add "Action", valid_595025
  var valid_595026 = query.getOrDefault("EnvironmentId")
  valid_595026 = validateParameter(valid_595026, JString, required = false,
                                 default = nil)
  if valid_595026 != nil:
    section.add "EnvironmentId", valid_595026
  var valid_595027 = query.getOrDefault("TemplateName")
  valid_595027 = validateParameter(valid_595027, JString, required = false,
                                 default = nil)
  if valid_595027 != nil:
    section.add "TemplateName", valid_595027
  var valid_595028 = query.getOrDefault("Severity")
  valid_595028 = validateParameter(valid_595028, JString, required = false,
                                 default = newJString("TRACE"))
  if valid_595028 != nil:
    section.add "Severity", valid_595028
  var valid_595029 = query.getOrDefault("RequestId")
  valid_595029 = validateParameter(valid_595029, JString, required = false,
                                 default = nil)
  if valid_595029 != nil:
    section.add "RequestId", valid_595029
  var valid_595030 = query.getOrDefault("EndTime")
  valid_595030 = validateParameter(valid_595030, JString, required = false,
                                 default = nil)
  if valid_595030 != nil:
    section.add "EndTime", valid_595030
  var valid_595031 = query.getOrDefault("Version")
  valid_595031 = validateParameter(valid_595031, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_595031 != nil:
    section.add "Version", valid_595031
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595032 = header.getOrDefault("X-Amz-Date")
  valid_595032 = validateParameter(valid_595032, JString, required = false,
                                 default = nil)
  if valid_595032 != nil:
    section.add "X-Amz-Date", valid_595032
  var valid_595033 = header.getOrDefault("X-Amz-Security-Token")
  valid_595033 = validateParameter(valid_595033, JString, required = false,
                                 default = nil)
  if valid_595033 != nil:
    section.add "X-Amz-Security-Token", valid_595033
  var valid_595034 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595034 = validateParameter(valid_595034, JString, required = false,
                                 default = nil)
  if valid_595034 != nil:
    section.add "X-Amz-Content-Sha256", valid_595034
  var valid_595035 = header.getOrDefault("X-Amz-Algorithm")
  valid_595035 = validateParameter(valid_595035, JString, required = false,
                                 default = nil)
  if valid_595035 != nil:
    section.add "X-Amz-Algorithm", valid_595035
  var valid_595036 = header.getOrDefault("X-Amz-Signature")
  valid_595036 = validateParameter(valid_595036, JString, required = false,
                                 default = nil)
  if valid_595036 != nil:
    section.add "X-Amz-Signature", valid_595036
  var valid_595037 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595037 = validateParameter(valid_595037, JString, required = false,
                                 default = nil)
  if valid_595037 != nil:
    section.add "X-Amz-SignedHeaders", valid_595037
  var valid_595038 = header.getOrDefault("X-Amz-Credential")
  valid_595038 = validateParameter(valid_595038, JString, required = false,
                                 default = nil)
  if valid_595038 != nil:
    section.add "X-Amz-Credential", valid_595038
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595039: Call_GetDescribeEvents_595015; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns list of event descriptions matching criteria up to the last 6 weeks.</p> <note> <p>This action returns the most recent 1,000 events from the specified <code>NextToken</code>.</p> </note>
  ## 
  let valid = call_595039.validator(path, query, header, formData, body)
  let scheme = call_595039.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595039.url(scheme.get, call_595039.host, call_595039.base,
                         call_595039.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595039, url, valid)

proc call*(call_595040: Call_GetDescribeEvents_595015; VersionLabel: string = "";
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
  var query_595041 = newJObject()
  add(query_595041, "VersionLabel", newJString(VersionLabel))
  add(query_595041, "MaxRecords", newJInt(MaxRecords))
  add(query_595041, "ApplicationName", newJString(ApplicationName))
  add(query_595041, "StartTime", newJString(StartTime))
  add(query_595041, "PlatformArn", newJString(PlatformArn))
  add(query_595041, "NextToken", newJString(NextToken))
  add(query_595041, "EnvironmentName", newJString(EnvironmentName))
  add(query_595041, "Action", newJString(Action))
  add(query_595041, "EnvironmentId", newJString(EnvironmentId))
  add(query_595041, "TemplateName", newJString(TemplateName))
  add(query_595041, "Severity", newJString(Severity))
  add(query_595041, "RequestId", newJString(RequestId))
  add(query_595041, "EndTime", newJString(EndTime))
  add(query_595041, "Version", newJString(Version))
  result = call_595040.call(nil, query_595041, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_595015(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_595016,
    base: "/", url: url_GetDescribeEvents_595017,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeInstancesHealth_595089 = ref object of OpenApiRestCall_593438
proc url_PostDescribeInstancesHealth_595091(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeInstancesHealth_595090(path: JsonNode; query: JsonNode;
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
  var valid_595092 = query.getOrDefault("Action")
  valid_595092 = validateParameter(valid_595092, JString, required = true, default = newJString(
      "DescribeInstancesHealth"))
  if valid_595092 != nil:
    section.add "Action", valid_595092
  var valid_595093 = query.getOrDefault("Version")
  valid_595093 = validateParameter(valid_595093, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_595093 != nil:
    section.add "Version", valid_595093
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595094 = header.getOrDefault("X-Amz-Date")
  valid_595094 = validateParameter(valid_595094, JString, required = false,
                                 default = nil)
  if valid_595094 != nil:
    section.add "X-Amz-Date", valid_595094
  var valid_595095 = header.getOrDefault("X-Amz-Security-Token")
  valid_595095 = validateParameter(valid_595095, JString, required = false,
                                 default = nil)
  if valid_595095 != nil:
    section.add "X-Amz-Security-Token", valid_595095
  var valid_595096 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595096 = validateParameter(valid_595096, JString, required = false,
                                 default = nil)
  if valid_595096 != nil:
    section.add "X-Amz-Content-Sha256", valid_595096
  var valid_595097 = header.getOrDefault("X-Amz-Algorithm")
  valid_595097 = validateParameter(valid_595097, JString, required = false,
                                 default = nil)
  if valid_595097 != nil:
    section.add "X-Amz-Algorithm", valid_595097
  var valid_595098 = header.getOrDefault("X-Amz-Signature")
  valid_595098 = validateParameter(valid_595098, JString, required = false,
                                 default = nil)
  if valid_595098 != nil:
    section.add "X-Amz-Signature", valid_595098
  var valid_595099 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595099 = validateParameter(valid_595099, JString, required = false,
                                 default = nil)
  if valid_595099 != nil:
    section.add "X-Amz-SignedHeaders", valid_595099
  var valid_595100 = header.getOrDefault("X-Amz-Credential")
  valid_595100 = validateParameter(valid_595100, JString, required = false,
                                 default = nil)
  if valid_595100 != nil:
    section.add "X-Amz-Credential", valid_595100
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
  var valid_595101 = formData.getOrDefault("NextToken")
  valid_595101 = validateParameter(valid_595101, JString, required = false,
                                 default = nil)
  if valid_595101 != nil:
    section.add "NextToken", valid_595101
  var valid_595102 = formData.getOrDefault("EnvironmentId")
  valid_595102 = validateParameter(valid_595102, JString, required = false,
                                 default = nil)
  if valid_595102 != nil:
    section.add "EnvironmentId", valid_595102
  var valid_595103 = formData.getOrDefault("EnvironmentName")
  valid_595103 = validateParameter(valid_595103, JString, required = false,
                                 default = nil)
  if valid_595103 != nil:
    section.add "EnvironmentName", valid_595103
  var valid_595104 = formData.getOrDefault("AttributeNames")
  valid_595104 = validateParameter(valid_595104, JArray, required = false,
                                 default = nil)
  if valid_595104 != nil:
    section.add "AttributeNames", valid_595104
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595105: Call_PostDescribeInstancesHealth_595089; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves detailed information about the health of instances in your AWS Elastic Beanstalk. This operation requires <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/health-enhanced.html">enhanced health reporting</a>.
  ## 
  let valid = call_595105.validator(path, query, header, formData, body)
  let scheme = call_595105.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595105.url(scheme.get, call_595105.host, call_595105.base,
                         call_595105.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595105, url, valid)

proc call*(call_595106: Call_PostDescribeInstancesHealth_595089;
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
  var query_595107 = newJObject()
  var formData_595108 = newJObject()
  add(formData_595108, "NextToken", newJString(NextToken))
  add(formData_595108, "EnvironmentId", newJString(EnvironmentId))
  add(formData_595108, "EnvironmentName", newJString(EnvironmentName))
  add(query_595107, "Action", newJString(Action))
  if AttributeNames != nil:
    formData_595108.add "AttributeNames", AttributeNames
  add(query_595107, "Version", newJString(Version))
  result = call_595106.call(nil, query_595107, nil, formData_595108, nil)

var postDescribeInstancesHealth* = Call_PostDescribeInstancesHealth_595089(
    name: "postDescribeInstancesHealth", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeInstancesHealth",
    validator: validate_PostDescribeInstancesHealth_595090, base: "/",
    url: url_PostDescribeInstancesHealth_595091,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeInstancesHealth_595070 = ref object of OpenApiRestCall_593438
proc url_GetDescribeInstancesHealth_595072(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeInstancesHealth_595071(path: JsonNode; query: JsonNode;
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
  var valid_595073 = query.getOrDefault("AttributeNames")
  valid_595073 = validateParameter(valid_595073, JArray, required = false,
                                 default = nil)
  if valid_595073 != nil:
    section.add "AttributeNames", valid_595073
  var valid_595074 = query.getOrDefault("NextToken")
  valid_595074 = validateParameter(valid_595074, JString, required = false,
                                 default = nil)
  if valid_595074 != nil:
    section.add "NextToken", valid_595074
  var valid_595075 = query.getOrDefault("EnvironmentName")
  valid_595075 = validateParameter(valid_595075, JString, required = false,
                                 default = nil)
  if valid_595075 != nil:
    section.add "EnvironmentName", valid_595075
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595076 = query.getOrDefault("Action")
  valid_595076 = validateParameter(valid_595076, JString, required = true, default = newJString(
      "DescribeInstancesHealth"))
  if valid_595076 != nil:
    section.add "Action", valid_595076
  var valid_595077 = query.getOrDefault("EnvironmentId")
  valid_595077 = validateParameter(valid_595077, JString, required = false,
                                 default = nil)
  if valid_595077 != nil:
    section.add "EnvironmentId", valid_595077
  var valid_595078 = query.getOrDefault("Version")
  valid_595078 = validateParameter(valid_595078, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_595078 != nil:
    section.add "Version", valid_595078
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595079 = header.getOrDefault("X-Amz-Date")
  valid_595079 = validateParameter(valid_595079, JString, required = false,
                                 default = nil)
  if valid_595079 != nil:
    section.add "X-Amz-Date", valid_595079
  var valid_595080 = header.getOrDefault("X-Amz-Security-Token")
  valid_595080 = validateParameter(valid_595080, JString, required = false,
                                 default = nil)
  if valid_595080 != nil:
    section.add "X-Amz-Security-Token", valid_595080
  var valid_595081 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595081 = validateParameter(valid_595081, JString, required = false,
                                 default = nil)
  if valid_595081 != nil:
    section.add "X-Amz-Content-Sha256", valid_595081
  var valid_595082 = header.getOrDefault("X-Amz-Algorithm")
  valid_595082 = validateParameter(valid_595082, JString, required = false,
                                 default = nil)
  if valid_595082 != nil:
    section.add "X-Amz-Algorithm", valid_595082
  var valid_595083 = header.getOrDefault("X-Amz-Signature")
  valid_595083 = validateParameter(valid_595083, JString, required = false,
                                 default = nil)
  if valid_595083 != nil:
    section.add "X-Amz-Signature", valid_595083
  var valid_595084 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595084 = validateParameter(valid_595084, JString, required = false,
                                 default = nil)
  if valid_595084 != nil:
    section.add "X-Amz-SignedHeaders", valid_595084
  var valid_595085 = header.getOrDefault("X-Amz-Credential")
  valid_595085 = validateParameter(valid_595085, JString, required = false,
                                 default = nil)
  if valid_595085 != nil:
    section.add "X-Amz-Credential", valid_595085
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595086: Call_GetDescribeInstancesHealth_595070; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves detailed information about the health of instances in your AWS Elastic Beanstalk. This operation requires <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/health-enhanced.html">enhanced health reporting</a>.
  ## 
  let valid = call_595086.validator(path, query, header, formData, body)
  let scheme = call_595086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595086.url(scheme.get, call_595086.host, call_595086.base,
                         call_595086.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595086, url, valid)

proc call*(call_595087: Call_GetDescribeInstancesHealth_595070;
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
  var query_595088 = newJObject()
  if AttributeNames != nil:
    query_595088.add "AttributeNames", AttributeNames
  add(query_595088, "NextToken", newJString(NextToken))
  add(query_595088, "EnvironmentName", newJString(EnvironmentName))
  add(query_595088, "Action", newJString(Action))
  add(query_595088, "EnvironmentId", newJString(EnvironmentId))
  add(query_595088, "Version", newJString(Version))
  result = call_595087.call(nil, query_595088, nil, nil, nil)

var getDescribeInstancesHealth* = Call_GetDescribeInstancesHealth_595070(
    name: "getDescribeInstancesHealth", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeInstancesHealth",
    validator: validate_GetDescribeInstancesHealth_595071, base: "/",
    url: url_GetDescribeInstancesHealth_595072,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribePlatformVersion_595125 = ref object of OpenApiRestCall_593438
proc url_PostDescribePlatformVersion_595127(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribePlatformVersion_595126(path: JsonNode; query: JsonNode;
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
  var valid_595128 = query.getOrDefault("Action")
  valid_595128 = validateParameter(valid_595128, JString, required = true, default = newJString(
      "DescribePlatformVersion"))
  if valid_595128 != nil:
    section.add "Action", valid_595128
  var valid_595129 = query.getOrDefault("Version")
  valid_595129 = validateParameter(valid_595129, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_595129 != nil:
    section.add "Version", valid_595129
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595130 = header.getOrDefault("X-Amz-Date")
  valid_595130 = validateParameter(valid_595130, JString, required = false,
                                 default = nil)
  if valid_595130 != nil:
    section.add "X-Amz-Date", valid_595130
  var valid_595131 = header.getOrDefault("X-Amz-Security-Token")
  valid_595131 = validateParameter(valid_595131, JString, required = false,
                                 default = nil)
  if valid_595131 != nil:
    section.add "X-Amz-Security-Token", valid_595131
  var valid_595132 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595132 = validateParameter(valid_595132, JString, required = false,
                                 default = nil)
  if valid_595132 != nil:
    section.add "X-Amz-Content-Sha256", valid_595132
  var valid_595133 = header.getOrDefault("X-Amz-Algorithm")
  valid_595133 = validateParameter(valid_595133, JString, required = false,
                                 default = nil)
  if valid_595133 != nil:
    section.add "X-Amz-Algorithm", valid_595133
  var valid_595134 = header.getOrDefault("X-Amz-Signature")
  valid_595134 = validateParameter(valid_595134, JString, required = false,
                                 default = nil)
  if valid_595134 != nil:
    section.add "X-Amz-Signature", valid_595134
  var valid_595135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595135 = validateParameter(valid_595135, JString, required = false,
                                 default = nil)
  if valid_595135 != nil:
    section.add "X-Amz-SignedHeaders", valid_595135
  var valid_595136 = header.getOrDefault("X-Amz-Credential")
  valid_595136 = validateParameter(valid_595136, JString, required = false,
                                 default = nil)
  if valid_595136 != nil:
    section.add "X-Amz-Credential", valid_595136
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformArn: JString
  ##              : The ARN of the version of the platform.
  section = newJObject()
  var valid_595137 = formData.getOrDefault("PlatformArn")
  valid_595137 = validateParameter(valid_595137, JString, required = false,
                                 default = nil)
  if valid_595137 != nil:
    section.add "PlatformArn", valid_595137
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595138: Call_PostDescribePlatformVersion_595125; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the version of the platform.
  ## 
  let valid = call_595138.validator(path, query, header, formData, body)
  let scheme = call_595138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595138.url(scheme.get, call_595138.host, call_595138.base,
                         call_595138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595138, url, valid)

proc call*(call_595139: Call_PostDescribePlatformVersion_595125;
          Action: string = "DescribePlatformVersion"; PlatformArn: string = "";
          Version: string = "2010-12-01"): Recallable =
  ## postDescribePlatformVersion
  ## Describes the version of the platform.
  ##   Action: string (required)
  ##   PlatformArn: string
  ##              : The ARN of the version of the platform.
  ##   Version: string (required)
  var query_595140 = newJObject()
  var formData_595141 = newJObject()
  add(query_595140, "Action", newJString(Action))
  add(formData_595141, "PlatformArn", newJString(PlatformArn))
  add(query_595140, "Version", newJString(Version))
  result = call_595139.call(nil, query_595140, nil, formData_595141, nil)

var postDescribePlatformVersion* = Call_PostDescribePlatformVersion_595125(
    name: "postDescribePlatformVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribePlatformVersion",
    validator: validate_PostDescribePlatformVersion_595126, base: "/",
    url: url_PostDescribePlatformVersion_595127,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribePlatformVersion_595109 = ref object of OpenApiRestCall_593438
proc url_GetDescribePlatformVersion_595111(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribePlatformVersion_595110(path: JsonNode; query: JsonNode;
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
  var valid_595112 = query.getOrDefault("PlatformArn")
  valid_595112 = validateParameter(valid_595112, JString, required = false,
                                 default = nil)
  if valid_595112 != nil:
    section.add "PlatformArn", valid_595112
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595113 = query.getOrDefault("Action")
  valid_595113 = validateParameter(valid_595113, JString, required = true, default = newJString(
      "DescribePlatformVersion"))
  if valid_595113 != nil:
    section.add "Action", valid_595113
  var valid_595114 = query.getOrDefault("Version")
  valid_595114 = validateParameter(valid_595114, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_595114 != nil:
    section.add "Version", valid_595114
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595115 = header.getOrDefault("X-Amz-Date")
  valid_595115 = validateParameter(valid_595115, JString, required = false,
                                 default = nil)
  if valid_595115 != nil:
    section.add "X-Amz-Date", valid_595115
  var valid_595116 = header.getOrDefault("X-Amz-Security-Token")
  valid_595116 = validateParameter(valid_595116, JString, required = false,
                                 default = nil)
  if valid_595116 != nil:
    section.add "X-Amz-Security-Token", valid_595116
  var valid_595117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595117 = validateParameter(valid_595117, JString, required = false,
                                 default = nil)
  if valid_595117 != nil:
    section.add "X-Amz-Content-Sha256", valid_595117
  var valid_595118 = header.getOrDefault("X-Amz-Algorithm")
  valid_595118 = validateParameter(valid_595118, JString, required = false,
                                 default = nil)
  if valid_595118 != nil:
    section.add "X-Amz-Algorithm", valid_595118
  var valid_595119 = header.getOrDefault("X-Amz-Signature")
  valid_595119 = validateParameter(valid_595119, JString, required = false,
                                 default = nil)
  if valid_595119 != nil:
    section.add "X-Amz-Signature", valid_595119
  var valid_595120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595120 = validateParameter(valid_595120, JString, required = false,
                                 default = nil)
  if valid_595120 != nil:
    section.add "X-Amz-SignedHeaders", valid_595120
  var valid_595121 = header.getOrDefault("X-Amz-Credential")
  valid_595121 = validateParameter(valid_595121, JString, required = false,
                                 default = nil)
  if valid_595121 != nil:
    section.add "X-Amz-Credential", valid_595121
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595122: Call_GetDescribePlatformVersion_595109; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the version of the platform.
  ## 
  let valid = call_595122.validator(path, query, header, formData, body)
  let scheme = call_595122.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595122.url(scheme.get, call_595122.host, call_595122.base,
                         call_595122.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595122, url, valid)

proc call*(call_595123: Call_GetDescribePlatformVersion_595109;
          PlatformArn: string = ""; Action: string = "DescribePlatformVersion";
          Version: string = "2010-12-01"): Recallable =
  ## getDescribePlatformVersion
  ## Describes the version of the platform.
  ##   PlatformArn: string
  ##              : The ARN of the version of the platform.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_595124 = newJObject()
  add(query_595124, "PlatformArn", newJString(PlatformArn))
  add(query_595124, "Action", newJString(Action))
  add(query_595124, "Version", newJString(Version))
  result = call_595123.call(nil, query_595124, nil, nil, nil)

var getDescribePlatformVersion* = Call_GetDescribePlatformVersion_595109(
    name: "getDescribePlatformVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribePlatformVersion",
    validator: validate_GetDescribePlatformVersion_595110, base: "/",
    url: url_GetDescribePlatformVersion_595111,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListAvailableSolutionStacks_595157 = ref object of OpenApiRestCall_593438
proc url_PostListAvailableSolutionStacks_595159(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListAvailableSolutionStacks_595158(path: JsonNode;
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
  var valid_595160 = query.getOrDefault("Action")
  valid_595160 = validateParameter(valid_595160, JString, required = true, default = newJString(
      "ListAvailableSolutionStacks"))
  if valid_595160 != nil:
    section.add "Action", valid_595160
  var valid_595161 = query.getOrDefault("Version")
  valid_595161 = validateParameter(valid_595161, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_595161 != nil:
    section.add "Version", valid_595161
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595162 = header.getOrDefault("X-Amz-Date")
  valid_595162 = validateParameter(valid_595162, JString, required = false,
                                 default = nil)
  if valid_595162 != nil:
    section.add "X-Amz-Date", valid_595162
  var valid_595163 = header.getOrDefault("X-Amz-Security-Token")
  valid_595163 = validateParameter(valid_595163, JString, required = false,
                                 default = nil)
  if valid_595163 != nil:
    section.add "X-Amz-Security-Token", valid_595163
  var valid_595164 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595164 = validateParameter(valid_595164, JString, required = false,
                                 default = nil)
  if valid_595164 != nil:
    section.add "X-Amz-Content-Sha256", valid_595164
  var valid_595165 = header.getOrDefault("X-Amz-Algorithm")
  valid_595165 = validateParameter(valid_595165, JString, required = false,
                                 default = nil)
  if valid_595165 != nil:
    section.add "X-Amz-Algorithm", valid_595165
  var valid_595166 = header.getOrDefault("X-Amz-Signature")
  valid_595166 = validateParameter(valid_595166, JString, required = false,
                                 default = nil)
  if valid_595166 != nil:
    section.add "X-Amz-Signature", valid_595166
  var valid_595167 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595167 = validateParameter(valid_595167, JString, required = false,
                                 default = nil)
  if valid_595167 != nil:
    section.add "X-Amz-SignedHeaders", valid_595167
  var valid_595168 = header.getOrDefault("X-Amz-Credential")
  valid_595168 = validateParameter(valid_595168, JString, required = false,
                                 default = nil)
  if valid_595168 != nil:
    section.add "X-Amz-Credential", valid_595168
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595169: Call_PostListAvailableSolutionStacks_595157;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ## 
  let valid = call_595169.validator(path, query, header, formData, body)
  let scheme = call_595169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595169.url(scheme.get, call_595169.host, call_595169.base,
                         call_595169.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595169, url, valid)

proc call*(call_595170: Call_PostListAvailableSolutionStacks_595157;
          Action: string = "ListAvailableSolutionStacks";
          Version: string = "2010-12-01"): Recallable =
  ## postListAvailableSolutionStacks
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_595171 = newJObject()
  add(query_595171, "Action", newJString(Action))
  add(query_595171, "Version", newJString(Version))
  result = call_595170.call(nil, query_595171, nil, nil, nil)

var postListAvailableSolutionStacks* = Call_PostListAvailableSolutionStacks_595157(
    name: "postListAvailableSolutionStacks", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListAvailableSolutionStacks",
    validator: validate_PostListAvailableSolutionStacks_595158, base: "/",
    url: url_PostListAvailableSolutionStacks_595159,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListAvailableSolutionStacks_595142 = ref object of OpenApiRestCall_593438
proc url_GetListAvailableSolutionStacks_595144(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListAvailableSolutionStacks_595143(path: JsonNode;
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
  var valid_595145 = query.getOrDefault("Action")
  valid_595145 = validateParameter(valid_595145, JString, required = true, default = newJString(
      "ListAvailableSolutionStacks"))
  if valid_595145 != nil:
    section.add "Action", valid_595145
  var valid_595146 = query.getOrDefault("Version")
  valid_595146 = validateParameter(valid_595146, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_595146 != nil:
    section.add "Version", valid_595146
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595147 = header.getOrDefault("X-Amz-Date")
  valid_595147 = validateParameter(valid_595147, JString, required = false,
                                 default = nil)
  if valid_595147 != nil:
    section.add "X-Amz-Date", valid_595147
  var valid_595148 = header.getOrDefault("X-Amz-Security-Token")
  valid_595148 = validateParameter(valid_595148, JString, required = false,
                                 default = nil)
  if valid_595148 != nil:
    section.add "X-Amz-Security-Token", valid_595148
  var valid_595149 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595149 = validateParameter(valid_595149, JString, required = false,
                                 default = nil)
  if valid_595149 != nil:
    section.add "X-Amz-Content-Sha256", valid_595149
  var valid_595150 = header.getOrDefault("X-Amz-Algorithm")
  valid_595150 = validateParameter(valid_595150, JString, required = false,
                                 default = nil)
  if valid_595150 != nil:
    section.add "X-Amz-Algorithm", valid_595150
  var valid_595151 = header.getOrDefault("X-Amz-Signature")
  valid_595151 = validateParameter(valid_595151, JString, required = false,
                                 default = nil)
  if valid_595151 != nil:
    section.add "X-Amz-Signature", valid_595151
  var valid_595152 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595152 = validateParameter(valid_595152, JString, required = false,
                                 default = nil)
  if valid_595152 != nil:
    section.add "X-Amz-SignedHeaders", valid_595152
  var valid_595153 = header.getOrDefault("X-Amz-Credential")
  valid_595153 = validateParameter(valid_595153, JString, required = false,
                                 default = nil)
  if valid_595153 != nil:
    section.add "X-Amz-Credential", valid_595153
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595154: Call_GetListAvailableSolutionStacks_595142; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ## 
  let valid = call_595154.validator(path, query, header, formData, body)
  let scheme = call_595154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595154.url(scheme.get, call_595154.host, call_595154.base,
                         call_595154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595154, url, valid)

proc call*(call_595155: Call_GetListAvailableSolutionStacks_595142;
          Action: string = "ListAvailableSolutionStacks";
          Version: string = "2010-12-01"): Recallable =
  ## getListAvailableSolutionStacks
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_595156 = newJObject()
  add(query_595156, "Action", newJString(Action))
  add(query_595156, "Version", newJString(Version))
  result = call_595155.call(nil, query_595156, nil, nil, nil)

var getListAvailableSolutionStacks* = Call_GetListAvailableSolutionStacks_595142(
    name: "getListAvailableSolutionStacks", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListAvailableSolutionStacks",
    validator: validate_GetListAvailableSolutionStacks_595143, base: "/",
    url: url_GetListAvailableSolutionStacks_595144,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListPlatformVersions_595190 = ref object of OpenApiRestCall_593438
proc url_PostListPlatformVersions_595192(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListPlatformVersions_595191(path: JsonNode; query: JsonNode;
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
  var valid_595193 = query.getOrDefault("Action")
  valid_595193 = validateParameter(valid_595193, JString, required = true,
                                 default = newJString("ListPlatformVersions"))
  if valid_595193 != nil:
    section.add "Action", valid_595193
  var valid_595194 = query.getOrDefault("Version")
  valid_595194 = validateParameter(valid_595194, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_595194 != nil:
    section.add "Version", valid_595194
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595195 = header.getOrDefault("X-Amz-Date")
  valid_595195 = validateParameter(valid_595195, JString, required = false,
                                 default = nil)
  if valid_595195 != nil:
    section.add "X-Amz-Date", valid_595195
  var valid_595196 = header.getOrDefault("X-Amz-Security-Token")
  valid_595196 = validateParameter(valid_595196, JString, required = false,
                                 default = nil)
  if valid_595196 != nil:
    section.add "X-Amz-Security-Token", valid_595196
  var valid_595197 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595197 = validateParameter(valid_595197, JString, required = false,
                                 default = nil)
  if valid_595197 != nil:
    section.add "X-Amz-Content-Sha256", valid_595197
  var valid_595198 = header.getOrDefault("X-Amz-Algorithm")
  valid_595198 = validateParameter(valid_595198, JString, required = false,
                                 default = nil)
  if valid_595198 != nil:
    section.add "X-Amz-Algorithm", valid_595198
  var valid_595199 = header.getOrDefault("X-Amz-Signature")
  valid_595199 = validateParameter(valid_595199, JString, required = false,
                                 default = nil)
  if valid_595199 != nil:
    section.add "X-Amz-Signature", valid_595199
  var valid_595200 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595200 = validateParameter(valid_595200, JString, required = false,
                                 default = nil)
  if valid_595200 != nil:
    section.add "X-Amz-SignedHeaders", valid_595200
  var valid_595201 = header.getOrDefault("X-Amz-Credential")
  valid_595201 = validateParameter(valid_595201, JString, required = false,
                                 default = nil)
  if valid_595201 != nil:
    section.add "X-Amz-Credential", valid_595201
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : The starting index into the remaining list of platforms. Use the <code>NextToken</code> value from a previous <code>ListPlatformVersion</code> call.
  ##   Filters: JArray
  ##          : List only the platforms where the platform member value relates to one of the supplied values.
  ##   MaxRecords: JInt
  ##             : The maximum number of platform values returned in one call.
  section = newJObject()
  var valid_595202 = formData.getOrDefault("NextToken")
  valid_595202 = validateParameter(valid_595202, JString, required = false,
                                 default = nil)
  if valid_595202 != nil:
    section.add "NextToken", valid_595202
  var valid_595203 = formData.getOrDefault("Filters")
  valid_595203 = validateParameter(valid_595203, JArray, required = false,
                                 default = nil)
  if valid_595203 != nil:
    section.add "Filters", valid_595203
  var valid_595204 = formData.getOrDefault("MaxRecords")
  valid_595204 = validateParameter(valid_595204, JInt, required = false, default = nil)
  if valid_595204 != nil:
    section.add "MaxRecords", valid_595204
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595205: Call_PostListPlatformVersions_595190; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the available platforms.
  ## 
  let valid = call_595205.validator(path, query, header, formData, body)
  let scheme = call_595205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595205.url(scheme.get, call_595205.host, call_595205.base,
                         call_595205.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595205, url, valid)

proc call*(call_595206: Call_PostListPlatformVersions_595190;
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
  var query_595207 = newJObject()
  var formData_595208 = newJObject()
  add(formData_595208, "NextToken", newJString(NextToken))
  add(query_595207, "Action", newJString(Action))
  if Filters != nil:
    formData_595208.add "Filters", Filters
  add(formData_595208, "MaxRecords", newJInt(MaxRecords))
  add(query_595207, "Version", newJString(Version))
  result = call_595206.call(nil, query_595207, nil, formData_595208, nil)

var postListPlatformVersions* = Call_PostListPlatformVersions_595190(
    name: "postListPlatformVersions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListPlatformVersions",
    validator: validate_PostListPlatformVersions_595191, base: "/",
    url: url_PostListPlatformVersions_595192, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListPlatformVersions_595172 = ref object of OpenApiRestCall_593438
proc url_GetListPlatformVersions_595174(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListPlatformVersions_595173(path: JsonNode; query: JsonNode;
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
  var valid_595175 = query.getOrDefault("MaxRecords")
  valid_595175 = validateParameter(valid_595175, JInt, required = false, default = nil)
  if valid_595175 != nil:
    section.add "MaxRecords", valid_595175
  var valid_595176 = query.getOrDefault("Filters")
  valid_595176 = validateParameter(valid_595176, JArray, required = false,
                                 default = nil)
  if valid_595176 != nil:
    section.add "Filters", valid_595176
  var valid_595177 = query.getOrDefault("NextToken")
  valid_595177 = validateParameter(valid_595177, JString, required = false,
                                 default = nil)
  if valid_595177 != nil:
    section.add "NextToken", valid_595177
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595178 = query.getOrDefault("Action")
  valid_595178 = validateParameter(valid_595178, JString, required = true,
                                 default = newJString("ListPlatformVersions"))
  if valid_595178 != nil:
    section.add "Action", valid_595178
  var valid_595179 = query.getOrDefault("Version")
  valid_595179 = validateParameter(valid_595179, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_595179 != nil:
    section.add "Version", valid_595179
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595180 = header.getOrDefault("X-Amz-Date")
  valid_595180 = validateParameter(valid_595180, JString, required = false,
                                 default = nil)
  if valid_595180 != nil:
    section.add "X-Amz-Date", valid_595180
  var valid_595181 = header.getOrDefault("X-Amz-Security-Token")
  valid_595181 = validateParameter(valid_595181, JString, required = false,
                                 default = nil)
  if valid_595181 != nil:
    section.add "X-Amz-Security-Token", valid_595181
  var valid_595182 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595182 = validateParameter(valid_595182, JString, required = false,
                                 default = nil)
  if valid_595182 != nil:
    section.add "X-Amz-Content-Sha256", valid_595182
  var valid_595183 = header.getOrDefault("X-Amz-Algorithm")
  valid_595183 = validateParameter(valid_595183, JString, required = false,
                                 default = nil)
  if valid_595183 != nil:
    section.add "X-Amz-Algorithm", valid_595183
  var valid_595184 = header.getOrDefault("X-Amz-Signature")
  valid_595184 = validateParameter(valid_595184, JString, required = false,
                                 default = nil)
  if valid_595184 != nil:
    section.add "X-Amz-Signature", valid_595184
  var valid_595185 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595185 = validateParameter(valid_595185, JString, required = false,
                                 default = nil)
  if valid_595185 != nil:
    section.add "X-Amz-SignedHeaders", valid_595185
  var valid_595186 = header.getOrDefault("X-Amz-Credential")
  valid_595186 = validateParameter(valid_595186, JString, required = false,
                                 default = nil)
  if valid_595186 != nil:
    section.add "X-Amz-Credential", valid_595186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595187: Call_GetListPlatformVersions_595172; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the available platforms.
  ## 
  let valid = call_595187.validator(path, query, header, formData, body)
  let scheme = call_595187.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595187.url(scheme.get, call_595187.host, call_595187.base,
                         call_595187.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595187, url, valid)

proc call*(call_595188: Call_GetListPlatformVersions_595172; MaxRecords: int = 0;
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
  var query_595189 = newJObject()
  add(query_595189, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_595189.add "Filters", Filters
  add(query_595189, "NextToken", newJString(NextToken))
  add(query_595189, "Action", newJString(Action))
  add(query_595189, "Version", newJString(Version))
  result = call_595188.call(nil, query_595189, nil, nil, nil)

var getListPlatformVersions* = Call_GetListPlatformVersions_595172(
    name: "getListPlatformVersions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListPlatformVersions",
    validator: validate_GetListPlatformVersions_595173, base: "/",
    url: url_GetListPlatformVersions_595174, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_595225 = ref object of OpenApiRestCall_593438
proc url_PostListTagsForResource_595227(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListTagsForResource_595226(path: JsonNode; query: JsonNode;
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
  var valid_595228 = query.getOrDefault("Action")
  valid_595228 = validateParameter(valid_595228, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_595228 != nil:
    section.add "Action", valid_595228
  var valid_595229 = query.getOrDefault("Version")
  valid_595229 = validateParameter(valid_595229, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_595229 != nil:
    section.add "Version", valid_595229
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595230 = header.getOrDefault("X-Amz-Date")
  valid_595230 = validateParameter(valid_595230, JString, required = false,
                                 default = nil)
  if valid_595230 != nil:
    section.add "X-Amz-Date", valid_595230
  var valid_595231 = header.getOrDefault("X-Amz-Security-Token")
  valid_595231 = validateParameter(valid_595231, JString, required = false,
                                 default = nil)
  if valid_595231 != nil:
    section.add "X-Amz-Security-Token", valid_595231
  var valid_595232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595232 = validateParameter(valid_595232, JString, required = false,
                                 default = nil)
  if valid_595232 != nil:
    section.add "X-Amz-Content-Sha256", valid_595232
  var valid_595233 = header.getOrDefault("X-Amz-Algorithm")
  valid_595233 = validateParameter(valid_595233, JString, required = false,
                                 default = nil)
  if valid_595233 != nil:
    section.add "X-Amz-Algorithm", valid_595233
  var valid_595234 = header.getOrDefault("X-Amz-Signature")
  valid_595234 = validateParameter(valid_595234, JString, required = false,
                                 default = nil)
  if valid_595234 != nil:
    section.add "X-Amz-Signature", valid_595234
  var valid_595235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595235 = validateParameter(valid_595235, JString, required = false,
                                 default = nil)
  if valid_595235 != nil:
    section.add "X-Amz-SignedHeaders", valid_595235
  var valid_595236 = header.getOrDefault("X-Amz-Credential")
  valid_595236 = validateParameter(valid_595236, JString, required = false,
                                 default = nil)
  if valid_595236 != nil:
    section.add "X-Amz-Credential", valid_595236
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArn: JString (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce for which a tag list is requested.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArn` field"
  var valid_595237 = formData.getOrDefault("ResourceArn")
  valid_595237 = validateParameter(valid_595237, JString, required = true,
                                 default = nil)
  if valid_595237 != nil:
    section.add "ResourceArn", valid_595237
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595238: Call_PostListTagsForResource_595225; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ## 
  let valid = call_595238.validator(path, query, header, formData, body)
  let scheme = call_595238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595238.url(scheme.get, call_595238.host, call_595238.base,
                         call_595238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595238, url, valid)

proc call*(call_595239: Call_PostListTagsForResource_595225; ResourceArn: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-12-01"): Recallable =
  ## postListTagsForResource
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ##   Action: string (required)
  ##   ResourceArn: string (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce for which a tag list is requested.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  ##   Version: string (required)
  var query_595240 = newJObject()
  var formData_595241 = newJObject()
  add(query_595240, "Action", newJString(Action))
  add(formData_595241, "ResourceArn", newJString(ResourceArn))
  add(query_595240, "Version", newJString(Version))
  result = call_595239.call(nil, query_595240, nil, formData_595241, nil)

var postListTagsForResource* = Call_PostListTagsForResource_595225(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_595226, base: "/",
    url: url_PostListTagsForResource_595227, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_595209 = ref object of OpenApiRestCall_593438
proc url_GetListTagsForResource_595211(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListTagsForResource_595210(path: JsonNode; query: JsonNode;
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
  var valid_595212 = query.getOrDefault("ResourceArn")
  valid_595212 = validateParameter(valid_595212, JString, required = true,
                                 default = nil)
  if valid_595212 != nil:
    section.add "ResourceArn", valid_595212
  var valid_595213 = query.getOrDefault("Action")
  valid_595213 = validateParameter(valid_595213, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_595213 != nil:
    section.add "Action", valid_595213
  var valid_595214 = query.getOrDefault("Version")
  valid_595214 = validateParameter(valid_595214, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_595214 != nil:
    section.add "Version", valid_595214
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595215 = header.getOrDefault("X-Amz-Date")
  valid_595215 = validateParameter(valid_595215, JString, required = false,
                                 default = nil)
  if valid_595215 != nil:
    section.add "X-Amz-Date", valid_595215
  var valid_595216 = header.getOrDefault("X-Amz-Security-Token")
  valid_595216 = validateParameter(valid_595216, JString, required = false,
                                 default = nil)
  if valid_595216 != nil:
    section.add "X-Amz-Security-Token", valid_595216
  var valid_595217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595217 = validateParameter(valid_595217, JString, required = false,
                                 default = nil)
  if valid_595217 != nil:
    section.add "X-Amz-Content-Sha256", valid_595217
  var valid_595218 = header.getOrDefault("X-Amz-Algorithm")
  valid_595218 = validateParameter(valid_595218, JString, required = false,
                                 default = nil)
  if valid_595218 != nil:
    section.add "X-Amz-Algorithm", valid_595218
  var valid_595219 = header.getOrDefault("X-Amz-Signature")
  valid_595219 = validateParameter(valid_595219, JString, required = false,
                                 default = nil)
  if valid_595219 != nil:
    section.add "X-Amz-Signature", valid_595219
  var valid_595220 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595220 = validateParameter(valid_595220, JString, required = false,
                                 default = nil)
  if valid_595220 != nil:
    section.add "X-Amz-SignedHeaders", valid_595220
  var valid_595221 = header.getOrDefault("X-Amz-Credential")
  valid_595221 = validateParameter(valid_595221, JString, required = false,
                                 default = nil)
  if valid_595221 != nil:
    section.add "X-Amz-Credential", valid_595221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595222: Call_GetListTagsForResource_595209; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ## 
  let valid = call_595222.validator(path, query, header, formData, body)
  let scheme = call_595222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595222.url(scheme.get, call_595222.host, call_595222.base,
                         call_595222.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595222, url, valid)

proc call*(call_595223: Call_GetListTagsForResource_595209; ResourceArn: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-12-01"): Recallable =
  ## getListTagsForResource
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ##   ResourceArn: string (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce for which a tag list is requested.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_595224 = newJObject()
  add(query_595224, "ResourceArn", newJString(ResourceArn))
  add(query_595224, "Action", newJString(Action))
  add(query_595224, "Version", newJString(Version))
  result = call_595223.call(nil, query_595224, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_595209(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_595210, base: "/",
    url: url_GetListTagsForResource_595211, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebuildEnvironment_595259 = ref object of OpenApiRestCall_593438
proc url_PostRebuildEnvironment_595261(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRebuildEnvironment_595260(path: JsonNode; query: JsonNode;
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
  var valid_595262 = query.getOrDefault("Action")
  valid_595262 = validateParameter(valid_595262, JString, required = true,
                                 default = newJString("RebuildEnvironment"))
  if valid_595262 != nil:
    section.add "Action", valid_595262
  var valid_595263 = query.getOrDefault("Version")
  valid_595263 = validateParameter(valid_595263, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_595263 != nil:
    section.add "Version", valid_595263
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595264 = header.getOrDefault("X-Amz-Date")
  valid_595264 = validateParameter(valid_595264, JString, required = false,
                                 default = nil)
  if valid_595264 != nil:
    section.add "X-Amz-Date", valid_595264
  var valid_595265 = header.getOrDefault("X-Amz-Security-Token")
  valid_595265 = validateParameter(valid_595265, JString, required = false,
                                 default = nil)
  if valid_595265 != nil:
    section.add "X-Amz-Security-Token", valid_595265
  var valid_595266 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595266 = validateParameter(valid_595266, JString, required = false,
                                 default = nil)
  if valid_595266 != nil:
    section.add "X-Amz-Content-Sha256", valid_595266
  var valid_595267 = header.getOrDefault("X-Amz-Algorithm")
  valid_595267 = validateParameter(valid_595267, JString, required = false,
                                 default = nil)
  if valid_595267 != nil:
    section.add "X-Amz-Algorithm", valid_595267
  var valid_595268 = header.getOrDefault("X-Amz-Signature")
  valid_595268 = validateParameter(valid_595268, JString, required = false,
                                 default = nil)
  if valid_595268 != nil:
    section.add "X-Amz-Signature", valid_595268
  var valid_595269 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595269 = validateParameter(valid_595269, JString, required = false,
                                 default = nil)
  if valid_595269 != nil:
    section.add "X-Amz-SignedHeaders", valid_595269
  var valid_595270 = header.getOrDefault("X-Amz-Credential")
  valid_595270 = validateParameter(valid_595270, JString, required = false,
                                 default = nil)
  if valid_595270 != nil:
    section.add "X-Amz-Credential", valid_595270
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to rebuild.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to rebuild.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_595271 = formData.getOrDefault("EnvironmentId")
  valid_595271 = validateParameter(valid_595271, JString, required = false,
                                 default = nil)
  if valid_595271 != nil:
    section.add "EnvironmentId", valid_595271
  var valid_595272 = formData.getOrDefault("EnvironmentName")
  valid_595272 = validateParameter(valid_595272, JString, required = false,
                                 default = nil)
  if valid_595272 != nil:
    section.add "EnvironmentName", valid_595272
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595273: Call_PostRebuildEnvironment_595259; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes and recreates all of the AWS resources (for example: the Auto Scaling group, load balancer, etc.) for a specified environment and forces a restart.
  ## 
  let valid = call_595273.validator(path, query, header, formData, body)
  let scheme = call_595273.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595273.url(scheme.get, call_595273.host, call_595273.base,
                         call_595273.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595273, url, valid)

proc call*(call_595274: Call_PostRebuildEnvironment_595259;
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
  var query_595275 = newJObject()
  var formData_595276 = newJObject()
  add(formData_595276, "EnvironmentId", newJString(EnvironmentId))
  add(formData_595276, "EnvironmentName", newJString(EnvironmentName))
  add(query_595275, "Action", newJString(Action))
  add(query_595275, "Version", newJString(Version))
  result = call_595274.call(nil, query_595275, nil, formData_595276, nil)

var postRebuildEnvironment* = Call_PostRebuildEnvironment_595259(
    name: "postRebuildEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RebuildEnvironment",
    validator: validate_PostRebuildEnvironment_595260, base: "/",
    url: url_PostRebuildEnvironment_595261, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebuildEnvironment_595242 = ref object of OpenApiRestCall_593438
proc url_GetRebuildEnvironment_595244(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRebuildEnvironment_595243(path: JsonNode; query: JsonNode;
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
  var valid_595245 = query.getOrDefault("EnvironmentName")
  valid_595245 = validateParameter(valid_595245, JString, required = false,
                                 default = nil)
  if valid_595245 != nil:
    section.add "EnvironmentName", valid_595245
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595246 = query.getOrDefault("Action")
  valid_595246 = validateParameter(valid_595246, JString, required = true,
                                 default = newJString("RebuildEnvironment"))
  if valid_595246 != nil:
    section.add "Action", valid_595246
  var valid_595247 = query.getOrDefault("EnvironmentId")
  valid_595247 = validateParameter(valid_595247, JString, required = false,
                                 default = nil)
  if valid_595247 != nil:
    section.add "EnvironmentId", valid_595247
  var valid_595248 = query.getOrDefault("Version")
  valid_595248 = validateParameter(valid_595248, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_595248 != nil:
    section.add "Version", valid_595248
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595249 = header.getOrDefault("X-Amz-Date")
  valid_595249 = validateParameter(valid_595249, JString, required = false,
                                 default = nil)
  if valid_595249 != nil:
    section.add "X-Amz-Date", valid_595249
  var valid_595250 = header.getOrDefault("X-Amz-Security-Token")
  valid_595250 = validateParameter(valid_595250, JString, required = false,
                                 default = nil)
  if valid_595250 != nil:
    section.add "X-Amz-Security-Token", valid_595250
  var valid_595251 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595251 = validateParameter(valid_595251, JString, required = false,
                                 default = nil)
  if valid_595251 != nil:
    section.add "X-Amz-Content-Sha256", valid_595251
  var valid_595252 = header.getOrDefault("X-Amz-Algorithm")
  valid_595252 = validateParameter(valid_595252, JString, required = false,
                                 default = nil)
  if valid_595252 != nil:
    section.add "X-Amz-Algorithm", valid_595252
  var valid_595253 = header.getOrDefault("X-Amz-Signature")
  valid_595253 = validateParameter(valid_595253, JString, required = false,
                                 default = nil)
  if valid_595253 != nil:
    section.add "X-Amz-Signature", valid_595253
  var valid_595254 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595254 = validateParameter(valid_595254, JString, required = false,
                                 default = nil)
  if valid_595254 != nil:
    section.add "X-Amz-SignedHeaders", valid_595254
  var valid_595255 = header.getOrDefault("X-Amz-Credential")
  valid_595255 = validateParameter(valid_595255, JString, required = false,
                                 default = nil)
  if valid_595255 != nil:
    section.add "X-Amz-Credential", valid_595255
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595256: Call_GetRebuildEnvironment_595242; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes and recreates all of the AWS resources (for example: the Auto Scaling group, load balancer, etc.) for a specified environment and forces a restart.
  ## 
  let valid = call_595256.validator(path, query, header, formData, body)
  let scheme = call_595256.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595256.url(scheme.get, call_595256.host, call_595256.base,
                         call_595256.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595256, url, valid)

proc call*(call_595257: Call_GetRebuildEnvironment_595242;
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
  var query_595258 = newJObject()
  add(query_595258, "EnvironmentName", newJString(EnvironmentName))
  add(query_595258, "Action", newJString(Action))
  add(query_595258, "EnvironmentId", newJString(EnvironmentId))
  add(query_595258, "Version", newJString(Version))
  result = call_595257.call(nil, query_595258, nil, nil, nil)

var getRebuildEnvironment* = Call_GetRebuildEnvironment_595242(
    name: "getRebuildEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RebuildEnvironment",
    validator: validate_GetRebuildEnvironment_595243, base: "/",
    url: url_GetRebuildEnvironment_595244, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRequestEnvironmentInfo_595295 = ref object of OpenApiRestCall_593438
proc url_PostRequestEnvironmentInfo_595297(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRequestEnvironmentInfo_595296(path: JsonNode; query: JsonNode;
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
  var valid_595298 = query.getOrDefault("Action")
  valid_595298 = validateParameter(valid_595298, JString, required = true,
                                 default = newJString("RequestEnvironmentInfo"))
  if valid_595298 != nil:
    section.add "Action", valid_595298
  var valid_595299 = query.getOrDefault("Version")
  valid_595299 = validateParameter(valid_595299, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_595299 != nil:
    section.add "Version", valid_595299
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595300 = header.getOrDefault("X-Amz-Date")
  valid_595300 = validateParameter(valid_595300, JString, required = false,
                                 default = nil)
  if valid_595300 != nil:
    section.add "X-Amz-Date", valid_595300
  var valid_595301 = header.getOrDefault("X-Amz-Security-Token")
  valid_595301 = validateParameter(valid_595301, JString, required = false,
                                 default = nil)
  if valid_595301 != nil:
    section.add "X-Amz-Security-Token", valid_595301
  var valid_595302 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595302 = validateParameter(valid_595302, JString, required = false,
                                 default = nil)
  if valid_595302 != nil:
    section.add "X-Amz-Content-Sha256", valid_595302
  var valid_595303 = header.getOrDefault("X-Amz-Algorithm")
  valid_595303 = validateParameter(valid_595303, JString, required = false,
                                 default = nil)
  if valid_595303 != nil:
    section.add "X-Amz-Algorithm", valid_595303
  var valid_595304 = header.getOrDefault("X-Amz-Signature")
  valid_595304 = validateParameter(valid_595304, JString, required = false,
                                 default = nil)
  if valid_595304 != nil:
    section.add "X-Amz-Signature", valid_595304
  var valid_595305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595305 = validateParameter(valid_595305, JString, required = false,
                                 default = nil)
  if valid_595305 != nil:
    section.add "X-Amz-SignedHeaders", valid_595305
  var valid_595306 = header.getOrDefault("X-Amz-Credential")
  valid_595306 = validateParameter(valid_595306, JString, required = false,
                                 default = nil)
  if valid_595306 != nil:
    section.add "X-Amz-Credential", valid_595306
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
  var valid_595307 = formData.getOrDefault("InfoType")
  valid_595307 = validateParameter(valid_595307, JString, required = true,
                                 default = newJString("tail"))
  if valid_595307 != nil:
    section.add "InfoType", valid_595307
  var valid_595308 = formData.getOrDefault("EnvironmentId")
  valid_595308 = validateParameter(valid_595308, JString, required = false,
                                 default = nil)
  if valid_595308 != nil:
    section.add "EnvironmentId", valid_595308
  var valid_595309 = formData.getOrDefault("EnvironmentName")
  valid_595309 = validateParameter(valid_595309, JString, required = false,
                                 default = nil)
  if valid_595309 != nil:
    section.add "EnvironmentName", valid_595309
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595310: Call_PostRequestEnvironmentInfo_595295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a request to compile the specified type of information of the deployed environment.</p> <p> Setting the <code>InfoType</code> to <code>tail</code> compiles the last lines from the application server log files of every Amazon EC2 instance in your environment. </p> <p> Setting the <code>InfoType</code> to <code>bundle</code> compresses the application server log files for every Amazon EC2 instance into a <code>.zip</code> file. Legacy and .NET containers do not support bundle logs. </p> <p> Use <a>RetrieveEnvironmentInfo</a> to obtain the set of logs. </p> <p>Related Topics</p> <ul> <li> <p> <a>RetrieveEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_595310.validator(path, query, header, formData, body)
  let scheme = call_595310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595310.url(scheme.get, call_595310.host, call_595310.base,
                         call_595310.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595310, url, valid)

proc call*(call_595311: Call_PostRequestEnvironmentInfo_595295;
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
  var query_595312 = newJObject()
  var formData_595313 = newJObject()
  add(formData_595313, "InfoType", newJString(InfoType))
  add(formData_595313, "EnvironmentId", newJString(EnvironmentId))
  add(formData_595313, "EnvironmentName", newJString(EnvironmentName))
  add(query_595312, "Action", newJString(Action))
  add(query_595312, "Version", newJString(Version))
  result = call_595311.call(nil, query_595312, nil, formData_595313, nil)

var postRequestEnvironmentInfo* = Call_PostRequestEnvironmentInfo_595295(
    name: "postRequestEnvironmentInfo", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RequestEnvironmentInfo",
    validator: validate_PostRequestEnvironmentInfo_595296, base: "/",
    url: url_PostRequestEnvironmentInfo_595297,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRequestEnvironmentInfo_595277 = ref object of OpenApiRestCall_593438
proc url_GetRequestEnvironmentInfo_595279(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRequestEnvironmentInfo_595278(path: JsonNode; query: JsonNode;
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
  var valid_595280 = query.getOrDefault("InfoType")
  valid_595280 = validateParameter(valid_595280, JString, required = true,
                                 default = newJString("tail"))
  if valid_595280 != nil:
    section.add "InfoType", valid_595280
  var valid_595281 = query.getOrDefault("EnvironmentName")
  valid_595281 = validateParameter(valid_595281, JString, required = false,
                                 default = nil)
  if valid_595281 != nil:
    section.add "EnvironmentName", valid_595281
  var valid_595282 = query.getOrDefault("Action")
  valid_595282 = validateParameter(valid_595282, JString, required = true,
                                 default = newJString("RequestEnvironmentInfo"))
  if valid_595282 != nil:
    section.add "Action", valid_595282
  var valid_595283 = query.getOrDefault("EnvironmentId")
  valid_595283 = validateParameter(valid_595283, JString, required = false,
                                 default = nil)
  if valid_595283 != nil:
    section.add "EnvironmentId", valid_595283
  var valid_595284 = query.getOrDefault("Version")
  valid_595284 = validateParameter(valid_595284, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_595284 != nil:
    section.add "Version", valid_595284
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595285 = header.getOrDefault("X-Amz-Date")
  valid_595285 = validateParameter(valid_595285, JString, required = false,
                                 default = nil)
  if valid_595285 != nil:
    section.add "X-Amz-Date", valid_595285
  var valid_595286 = header.getOrDefault("X-Amz-Security-Token")
  valid_595286 = validateParameter(valid_595286, JString, required = false,
                                 default = nil)
  if valid_595286 != nil:
    section.add "X-Amz-Security-Token", valid_595286
  var valid_595287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595287 = validateParameter(valid_595287, JString, required = false,
                                 default = nil)
  if valid_595287 != nil:
    section.add "X-Amz-Content-Sha256", valid_595287
  var valid_595288 = header.getOrDefault("X-Amz-Algorithm")
  valid_595288 = validateParameter(valid_595288, JString, required = false,
                                 default = nil)
  if valid_595288 != nil:
    section.add "X-Amz-Algorithm", valid_595288
  var valid_595289 = header.getOrDefault("X-Amz-Signature")
  valid_595289 = validateParameter(valid_595289, JString, required = false,
                                 default = nil)
  if valid_595289 != nil:
    section.add "X-Amz-Signature", valid_595289
  var valid_595290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595290 = validateParameter(valid_595290, JString, required = false,
                                 default = nil)
  if valid_595290 != nil:
    section.add "X-Amz-SignedHeaders", valid_595290
  var valid_595291 = header.getOrDefault("X-Amz-Credential")
  valid_595291 = validateParameter(valid_595291, JString, required = false,
                                 default = nil)
  if valid_595291 != nil:
    section.add "X-Amz-Credential", valid_595291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595292: Call_GetRequestEnvironmentInfo_595277; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a request to compile the specified type of information of the deployed environment.</p> <p> Setting the <code>InfoType</code> to <code>tail</code> compiles the last lines from the application server log files of every Amazon EC2 instance in your environment. </p> <p> Setting the <code>InfoType</code> to <code>bundle</code> compresses the application server log files for every Amazon EC2 instance into a <code>.zip</code> file. Legacy and .NET containers do not support bundle logs. </p> <p> Use <a>RetrieveEnvironmentInfo</a> to obtain the set of logs. </p> <p>Related Topics</p> <ul> <li> <p> <a>RetrieveEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_595292.validator(path, query, header, formData, body)
  let scheme = call_595292.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595292.url(scheme.get, call_595292.host, call_595292.base,
                         call_595292.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595292, url, valid)

proc call*(call_595293: Call_GetRequestEnvironmentInfo_595277;
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
  var query_595294 = newJObject()
  add(query_595294, "InfoType", newJString(InfoType))
  add(query_595294, "EnvironmentName", newJString(EnvironmentName))
  add(query_595294, "Action", newJString(Action))
  add(query_595294, "EnvironmentId", newJString(EnvironmentId))
  add(query_595294, "Version", newJString(Version))
  result = call_595293.call(nil, query_595294, nil, nil, nil)

var getRequestEnvironmentInfo* = Call_GetRequestEnvironmentInfo_595277(
    name: "getRequestEnvironmentInfo", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RequestEnvironmentInfo",
    validator: validate_GetRequestEnvironmentInfo_595278, base: "/",
    url: url_GetRequestEnvironmentInfo_595279,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestartAppServer_595331 = ref object of OpenApiRestCall_593438
proc url_PostRestartAppServer_595333(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRestartAppServer_595332(path: JsonNode; query: JsonNode;
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
  var valid_595334 = query.getOrDefault("Action")
  valid_595334 = validateParameter(valid_595334, JString, required = true,
                                 default = newJString("RestartAppServer"))
  if valid_595334 != nil:
    section.add "Action", valid_595334
  var valid_595335 = query.getOrDefault("Version")
  valid_595335 = validateParameter(valid_595335, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_595335 != nil:
    section.add "Version", valid_595335
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595336 = header.getOrDefault("X-Amz-Date")
  valid_595336 = validateParameter(valid_595336, JString, required = false,
                                 default = nil)
  if valid_595336 != nil:
    section.add "X-Amz-Date", valid_595336
  var valid_595337 = header.getOrDefault("X-Amz-Security-Token")
  valid_595337 = validateParameter(valid_595337, JString, required = false,
                                 default = nil)
  if valid_595337 != nil:
    section.add "X-Amz-Security-Token", valid_595337
  var valid_595338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595338 = validateParameter(valid_595338, JString, required = false,
                                 default = nil)
  if valid_595338 != nil:
    section.add "X-Amz-Content-Sha256", valid_595338
  var valid_595339 = header.getOrDefault("X-Amz-Algorithm")
  valid_595339 = validateParameter(valid_595339, JString, required = false,
                                 default = nil)
  if valid_595339 != nil:
    section.add "X-Amz-Algorithm", valid_595339
  var valid_595340 = header.getOrDefault("X-Amz-Signature")
  valid_595340 = validateParameter(valid_595340, JString, required = false,
                                 default = nil)
  if valid_595340 != nil:
    section.add "X-Amz-Signature", valid_595340
  var valid_595341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595341 = validateParameter(valid_595341, JString, required = false,
                                 default = nil)
  if valid_595341 != nil:
    section.add "X-Amz-SignedHeaders", valid_595341
  var valid_595342 = header.getOrDefault("X-Amz-Credential")
  valid_595342 = validateParameter(valid_595342, JString, required = false,
                                 default = nil)
  if valid_595342 != nil:
    section.add "X-Amz-Credential", valid_595342
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to restart the server for.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to restart the server for.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_595343 = formData.getOrDefault("EnvironmentId")
  valid_595343 = validateParameter(valid_595343, JString, required = false,
                                 default = nil)
  if valid_595343 != nil:
    section.add "EnvironmentId", valid_595343
  var valid_595344 = formData.getOrDefault("EnvironmentName")
  valid_595344 = validateParameter(valid_595344, JString, required = false,
                                 default = nil)
  if valid_595344 != nil:
    section.add "EnvironmentName", valid_595344
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595345: Call_PostRestartAppServer_595331; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Causes the environment to restart the application container server running on each Amazon EC2 instance.
  ## 
  let valid = call_595345.validator(path, query, header, formData, body)
  let scheme = call_595345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595345.url(scheme.get, call_595345.host, call_595345.base,
                         call_595345.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595345, url, valid)

proc call*(call_595346: Call_PostRestartAppServer_595331;
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
  var query_595347 = newJObject()
  var formData_595348 = newJObject()
  add(formData_595348, "EnvironmentId", newJString(EnvironmentId))
  add(formData_595348, "EnvironmentName", newJString(EnvironmentName))
  add(query_595347, "Action", newJString(Action))
  add(query_595347, "Version", newJString(Version))
  result = call_595346.call(nil, query_595347, nil, formData_595348, nil)

var postRestartAppServer* = Call_PostRestartAppServer_595331(
    name: "postRestartAppServer", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RestartAppServer",
    validator: validate_PostRestartAppServer_595332, base: "/",
    url: url_PostRestartAppServer_595333, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestartAppServer_595314 = ref object of OpenApiRestCall_593438
proc url_GetRestartAppServer_595316(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRestartAppServer_595315(path: JsonNode; query: JsonNode;
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
  var valid_595317 = query.getOrDefault("EnvironmentName")
  valid_595317 = validateParameter(valid_595317, JString, required = false,
                                 default = nil)
  if valid_595317 != nil:
    section.add "EnvironmentName", valid_595317
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595318 = query.getOrDefault("Action")
  valid_595318 = validateParameter(valid_595318, JString, required = true,
                                 default = newJString("RestartAppServer"))
  if valid_595318 != nil:
    section.add "Action", valid_595318
  var valid_595319 = query.getOrDefault("EnvironmentId")
  valid_595319 = validateParameter(valid_595319, JString, required = false,
                                 default = nil)
  if valid_595319 != nil:
    section.add "EnvironmentId", valid_595319
  var valid_595320 = query.getOrDefault("Version")
  valid_595320 = validateParameter(valid_595320, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_595320 != nil:
    section.add "Version", valid_595320
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595321 = header.getOrDefault("X-Amz-Date")
  valid_595321 = validateParameter(valid_595321, JString, required = false,
                                 default = nil)
  if valid_595321 != nil:
    section.add "X-Amz-Date", valid_595321
  var valid_595322 = header.getOrDefault("X-Amz-Security-Token")
  valid_595322 = validateParameter(valid_595322, JString, required = false,
                                 default = nil)
  if valid_595322 != nil:
    section.add "X-Amz-Security-Token", valid_595322
  var valid_595323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595323 = validateParameter(valid_595323, JString, required = false,
                                 default = nil)
  if valid_595323 != nil:
    section.add "X-Amz-Content-Sha256", valid_595323
  var valid_595324 = header.getOrDefault("X-Amz-Algorithm")
  valid_595324 = validateParameter(valid_595324, JString, required = false,
                                 default = nil)
  if valid_595324 != nil:
    section.add "X-Amz-Algorithm", valid_595324
  var valid_595325 = header.getOrDefault("X-Amz-Signature")
  valid_595325 = validateParameter(valid_595325, JString, required = false,
                                 default = nil)
  if valid_595325 != nil:
    section.add "X-Amz-Signature", valid_595325
  var valid_595326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595326 = validateParameter(valid_595326, JString, required = false,
                                 default = nil)
  if valid_595326 != nil:
    section.add "X-Amz-SignedHeaders", valid_595326
  var valid_595327 = header.getOrDefault("X-Amz-Credential")
  valid_595327 = validateParameter(valid_595327, JString, required = false,
                                 default = nil)
  if valid_595327 != nil:
    section.add "X-Amz-Credential", valid_595327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595328: Call_GetRestartAppServer_595314; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Causes the environment to restart the application container server running on each Amazon EC2 instance.
  ## 
  let valid = call_595328.validator(path, query, header, formData, body)
  let scheme = call_595328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595328.url(scheme.get, call_595328.host, call_595328.base,
                         call_595328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595328, url, valid)

proc call*(call_595329: Call_GetRestartAppServer_595314;
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
  var query_595330 = newJObject()
  add(query_595330, "EnvironmentName", newJString(EnvironmentName))
  add(query_595330, "Action", newJString(Action))
  add(query_595330, "EnvironmentId", newJString(EnvironmentId))
  add(query_595330, "Version", newJString(Version))
  result = call_595329.call(nil, query_595330, nil, nil, nil)

var getRestartAppServer* = Call_GetRestartAppServer_595314(
    name: "getRestartAppServer", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RestartAppServer",
    validator: validate_GetRestartAppServer_595315, base: "/",
    url: url_GetRestartAppServer_595316, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRetrieveEnvironmentInfo_595367 = ref object of OpenApiRestCall_593438
proc url_PostRetrieveEnvironmentInfo_595369(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRetrieveEnvironmentInfo_595368(path: JsonNode; query: JsonNode;
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
  var valid_595370 = query.getOrDefault("Action")
  valid_595370 = validateParameter(valid_595370, JString, required = true, default = newJString(
      "RetrieveEnvironmentInfo"))
  if valid_595370 != nil:
    section.add "Action", valid_595370
  var valid_595371 = query.getOrDefault("Version")
  valid_595371 = validateParameter(valid_595371, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_595371 != nil:
    section.add "Version", valid_595371
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595372 = header.getOrDefault("X-Amz-Date")
  valid_595372 = validateParameter(valid_595372, JString, required = false,
                                 default = nil)
  if valid_595372 != nil:
    section.add "X-Amz-Date", valid_595372
  var valid_595373 = header.getOrDefault("X-Amz-Security-Token")
  valid_595373 = validateParameter(valid_595373, JString, required = false,
                                 default = nil)
  if valid_595373 != nil:
    section.add "X-Amz-Security-Token", valid_595373
  var valid_595374 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595374 = validateParameter(valid_595374, JString, required = false,
                                 default = nil)
  if valid_595374 != nil:
    section.add "X-Amz-Content-Sha256", valid_595374
  var valid_595375 = header.getOrDefault("X-Amz-Algorithm")
  valid_595375 = validateParameter(valid_595375, JString, required = false,
                                 default = nil)
  if valid_595375 != nil:
    section.add "X-Amz-Algorithm", valid_595375
  var valid_595376 = header.getOrDefault("X-Amz-Signature")
  valid_595376 = validateParameter(valid_595376, JString, required = false,
                                 default = nil)
  if valid_595376 != nil:
    section.add "X-Amz-Signature", valid_595376
  var valid_595377 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595377 = validateParameter(valid_595377, JString, required = false,
                                 default = nil)
  if valid_595377 != nil:
    section.add "X-Amz-SignedHeaders", valid_595377
  var valid_595378 = header.getOrDefault("X-Amz-Credential")
  valid_595378 = validateParameter(valid_595378, JString, required = false,
                                 default = nil)
  if valid_595378 != nil:
    section.add "X-Amz-Credential", valid_595378
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
  var valid_595379 = formData.getOrDefault("InfoType")
  valid_595379 = validateParameter(valid_595379, JString, required = true,
                                 default = newJString("tail"))
  if valid_595379 != nil:
    section.add "InfoType", valid_595379
  var valid_595380 = formData.getOrDefault("EnvironmentId")
  valid_595380 = validateParameter(valid_595380, JString, required = false,
                                 default = nil)
  if valid_595380 != nil:
    section.add "EnvironmentId", valid_595380
  var valid_595381 = formData.getOrDefault("EnvironmentName")
  valid_595381 = validateParameter(valid_595381, JString, required = false,
                                 default = nil)
  if valid_595381 != nil:
    section.add "EnvironmentName", valid_595381
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595382: Call_PostRetrieveEnvironmentInfo_595367; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the compiled information from a <a>RequestEnvironmentInfo</a> request.</p> <p>Related Topics</p> <ul> <li> <p> <a>RequestEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_595382.validator(path, query, header, formData, body)
  let scheme = call_595382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595382.url(scheme.get, call_595382.host, call_595382.base,
                         call_595382.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595382, url, valid)

proc call*(call_595383: Call_PostRetrieveEnvironmentInfo_595367;
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
  var query_595384 = newJObject()
  var formData_595385 = newJObject()
  add(formData_595385, "InfoType", newJString(InfoType))
  add(formData_595385, "EnvironmentId", newJString(EnvironmentId))
  add(formData_595385, "EnvironmentName", newJString(EnvironmentName))
  add(query_595384, "Action", newJString(Action))
  add(query_595384, "Version", newJString(Version))
  result = call_595383.call(nil, query_595384, nil, formData_595385, nil)

var postRetrieveEnvironmentInfo* = Call_PostRetrieveEnvironmentInfo_595367(
    name: "postRetrieveEnvironmentInfo", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RetrieveEnvironmentInfo",
    validator: validate_PostRetrieveEnvironmentInfo_595368, base: "/",
    url: url_PostRetrieveEnvironmentInfo_595369,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRetrieveEnvironmentInfo_595349 = ref object of OpenApiRestCall_593438
proc url_GetRetrieveEnvironmentInfo_595351(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRetrieveEnvironmentInfo_595350(path: JsonNode; query: JsonNode;
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
  var valid_595352 = query.getOrDefault("InfoType")
  valid_595352 = validateParameter(valid_595352, JString, required = true,
                                 default = newJString("tail"))
  if valid_595352 != nil:
    section.add "InfoType", valid_595352
  var valid_595353 = query.getOrDefault("EnvironmentName")
  valid_595353 = validateParameter(valid_595353, JString, required = false,
                                 default = nil)
  if valid_595353 != nil:
    section.add "EnvironmentName", valid_595353
  var valid_595354 = query.getOrDefault("Action")
  valid_595354 = validateParameter(valid_595354, JString, required = true, default = newJString(
      "RetrieveEnvironmentInfo"))
  if valid_595354 != nil:
    section.add "Action", valid_595354
  var valid_595355 = query.getOrDefault("EnvironmentId")
  valid_595355 = validateParameter(valid_595355, JString, required = false,
                                 default = nil)
  if valid_595355 != nil:
    section.add "EnvironmentId", valid_595355
  var valid_595356 = query.getOrDefault("Version")
  valid_595356 = validateParameter(valid_595356, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_595356 != nil:
    section.add "Version", valid_595356
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595357 = header.getOrDefault("X-Amz-Date")
  valid_595357 = validateParameter(valid_595357, JString, required = false,
                                 default = nil)
  if valid_595357 != nil:
    section.add "X-Amz-Date", valid_595357
  var valid_595358 = header.getOrDefault("X-Amz-Security-Token")
  valid_595358 = validateParameter(valid_595358, JString, required = false,
                                 default = nil)
  if valid_595358 != nil:
    section.add "X-Amz-Security-Token", valid_595358
  var valid_595359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595359 = validateParameter(valid_595359, JString, required = false,
                                 default = nil)
  if valid_595359 != nil:
    section.add "X-Amz-Content-Sha256", valid_595359
  var valid_595360 = header.getOrDefault("X-Amz-Algorithm")
  valid_595360 = validateParameter(valid_595360, JString, required = false,
                                 default = nil)
  if valid_595360 != nil:
    section.add "X-Amz-Algorithm", valid_595360
  var valid_595361 = header.getOrDefault("X-Amz-Signature")
  valid_595361 = validateParameter(valid_595361, JString, required = false,
                                 default = nil)
  if valid_595361 != nil:
    section.add "X-Amz-Signature", valid_595361
  var valid_595362 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595362 = validateParameter(valid_595362, JString, required = false,
                                 default = nil)
  if valid_595362 != nil:
    section.add "X-Amz-SignedHeaders", valid_595362
  var valid_595363 = header.getOrDefault("X-Amz-Credential")
  valid_595363 = validateParameter(valid_595363, JString, required = false,
                                 default = nil)
  if valid_595363 != nil:
    section.add "X-Amz-Credential", valid_595363
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595364: Call_GetRetrieveEnvironmentInfo_595349; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the compiled information from a <a>RequestEnvironmentInfo</a> request.</p> <p>Related Topics</p> <ul> <li> <p> <a>RequestEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_595364.validator(path, query, header, formData, body)
  let scheme = call_595364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595364.url(scheme.get, call_595364.host, call_595364.base,
                         call_595364.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595364, url, valid)

proc call*(call_595365: Call_GetRetrieveEnvironmentInfo_595349;
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
  var query_595366 = newJObject()
  add(query_595366, "InfoType", newJString(InfoType))
  add(query_595366, "EnvironmentName", newJString(EnvironmentName))
  add(query_595366, "Action", newJString(Action))
  add(query_595366, "EnvironmentId", newJString(EnvironmentId))
  add(query_595366, "Version", newJString(Version))
  result = call_595365.call(nil, query_595366, nil, nil, nil)

var getRetrieveEnvironmentInfo* = Call_GetRetrieveEnvironmentInfo_595349(
    name: "getRetrieveEnvironmentInfo", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RetrieveEnvironmentInfo",
    validator: validate_GetRetrieveEnvironmentInfo_595350, base: "/",
    url: url_GetRetrieveEnvironmentInfo_595351,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSwapEnvironmentCNAMEs_595405 = ref object of OpenApiRestCall_593438
proc url_PostSwapEnvironmentCNAMEs_595407(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSwapEnvironmentCNAMEs_595406(path: JsonNode; query: JsonNode;
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
  var valid_595408 = query.getOrDefault("Action")
  valid_595408 = validateParameter(valid_595408, JString, required = true,
                                 default = newJString("SwapEnvironmentCNAMEs"))
  if valid_595408 != nil:
    section.add "Action", valid_595408
  var valid_595409 = query.getOrDefault("Version")
  valid_595409 = validateParameter(valid_595409, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_595409 != nil:
    section.add "Version", valid_595409
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595410 = header.getOrDefault("X-Amz-Date")
  valid_595410 = validateParameter(valid_595410, JString, required = false,
                                 default = nil)
  if valid_595410 != nil:
    section.add "X-Amz-Date", valid_595410
  var valid_595411 = header.getOrDefault("X-Amz-Security-Token")
  valid_595411 = validateParameter(valid_595411, JString, required = false,
                                 default = nil)
  if valid_595411 != nil:
    section.add "X-Amz-Security-Token", valid_595411
  var valid_595412 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595412 = validateParameter(valid_595412, JString, required = false,
                                 default = nil)
  if valid_595412 != nil:
    section.add "X-Amz-Content-Sha256", valid_595412
  var valid_595413 = header.getOrDefault("X-Amz-Algorithm")
  valid_595413 = validateParameter(valid_595413, JString, required = false,
                                 default = nil)
  if valid_595413 != nil:
    section.add "X-Amz-Algorithm", valid_595413
  var valid_595414 = header.getOrDefault("X-Amz-Signature")
  valid_595414 = validateParameter(valid_595414, JString, required = false,
                                 default = nil)
  if valid_595414 != nil:
    section.add "X-Amz-Signature", valid_595414
  var valid_595415 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595415 = validateParameter(valid_595415, JString, required = false,
                                 default = nil)
  if valid_595415 != nil:
    section.add "X-Amz-SignedHeaders", valid_595415
  var valid_595416 = header.getOrDefault("X-Amz-Credential")
  valid_595416 = validateParameter(valid_595416, JString, required = false,
                                 default = nil)
  if valid_595416 != nil:
    section.add "X-Amz-Credential", valid_595416
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
  var valid_595417 = formData.getOrDefault("SourceEnvironmentName")
  valid_595417 = validateParameter(valid_595417, JString, required = false,
                                 default = nil)
  if valid_595417 != nil:
    section.add "SourceEnvironmentName", valid_595417
  var valid_595418 = formData.getOrDefault("SourceEnvironmentId")
  valid_595418 = validateParameter(valid_595418, JString, required = false,
                                 default = nil)
  if valid_595418 != nil:
    section.add "SourceEnvironmentId", valid_595418
  var valid_595419 = formData.getOrDefault("DestinationEnvironmentId")
  valid_595419 = validateParameter(valid_595419, JString, required = false,
                                 default = nil)
  if valid_595419 != nil:
    section.add "DestinationEnvironmentId", valid_595419
  var valid_595420 = formData.getOrDefault("DestinationEnvironmentName")
  valid_595420 = validateParameter(valid_595420, JString, required = false,
                                 default = nil)
  if valid_595420 != nil:
    section.add "DestinationEnvironmentName", valid_595420
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595421: Call_PostSwapEnvironmentCNAMEs_595405; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Swaps the CNAMEs of two environments.
  ## 
  let valid = call_595421.validator(path, query, header, formData, body)
  let scheme = call_595421.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595421.url(scheme.get, call_595421.host, call_595421.base,
                         call_595421.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595421, url, valid)

proc call*(call_595422: Call_PostSwapEnvironmentCNAMEs_595405;
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
  var query_595423 = newJObject()
  var formData_595424 = newJObject()
  add(formData_595424, "SourceEnvironmentName", newJString(SourceEnvironmentName))
  add(formData_595424, "SourceEnvironmentId", newJString(SourceEnvironmentId))
  add(formData_595424, "DestinationEnvironmentId",
      newJString(DestinationEnvironmentId))
  add(formData_595424, "DestinationEnvironmentName",
      newJString(DestinationEnvironmentName))
  add(query_595423, "Action", newJString(Action))
  add(query_595423, "Version", newJString(Version))
  result = call_595422.call(nil, query_595423, nil, formData_595424, nil)

var postSwapEnvironmentCNAMEs* = Call_PostSwapEnvironmentCNAMEs_595405(
    name: "postSwapEnvironmentCNAMEs", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=SwapEnvironmentCNAMEs",
    validator: validate_PostSwapEnvironmentCNAMEs_595406, base: "/",
    url: url_PostSwapEnvironmentCNAMEs_595407,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSwapEnvironmentCNAMEs_595386 = ref object of OpenApiRestCall_593438
proc url_GetSwapEnvironmentCNAMEs_595388(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSwapEnvironmentCNAMEs_595387(path: JsonNode; query: JsonNode;
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
  var valid_595389 = query.getOrDefault("SourceEnvironmentId")
  valid_595389 = validateParameter(valid_595389, JString, required = false,
                                 default = nil)
  if valid_595389 != nil:
    section.add "SourceEnvironmentId", valid_595389
  var valid_595390 = query.getOrDefault("DestinationEnvironmentName")
  valid_595390 = validateParameter(valid_595390, JString, required = false,
                                 default = nil)
  if valid_595390 != nil:
    section.add "DestinationEnvironmentName", valid_595390
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595391 = query.getOrDefault("Action")
  valid_595391 = validateParameter(valid_595391, JString, required = true,
                                 default = newJString("SwapEnvironmentCNAMEs"))
  if valid_595391 != nil:
    section.add "Action", valid_595391
  var valid_595392 = query.getOrDefault("SourceEnvironmentName")
  valid_595392 = validateParameter(valid_595392, JString, required = false,
                                 default = nil)
  if valid_595392 != nil:
    section.add "SourceEnvironmentName", valid_595392
  var valid_595393 = query.getOrDefault("DestinationEnvironmentId")
  valid_595393 = validateParameter(valid_595393, JString, required = false,
                                 default = nil)
  if valid_595393 != nil:
    section.add "DestinationEnvironmentId", valid_595393
  var valid_595394 = query.getOrDefault("Version")
  valid_595394 = validateParameter(valid_595394, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_595394 != nil:
    section.add "Version", valid_595394
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595395 = header.getOrDefault("X-Amz-Date")
  valid_595395 = validateParameter(valid_595395, JString, required = false,
                                 default = nil)
  if valid_595395 != nil:
    section.add "X-Amz-Date", valid_595395
  var valid_595396 = header.getOrDefault("X-Amz-Security-Token")
  valid_595396 = validateParameter(valid_595396, JString, required = false,
                                 default = nil)
  if valid_595396 != nil:
    section.add "X-Amz-Security-Token", valid_595396
  var valid_595397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595397 = validateParameter(valid_595397, JString, required = false,
                                 default = nil)
  if valid_595397 != nil:
    section.add "X-Amz-Content-Sha256", valid_595397
  var valid_595398 = header.getOrDefault("X-Amz-Algorithm")
  valid_595398 = validateParameter(valid_595398, JString, required = false,
                                 default = nil)
  if valid_595398 != nil:
    section.add "X-Amz-Algorithm", valid_595398
  var valid_595399 = header.getOrDefault("X-Amz-Signature")
  valid_595399 = validateParameter(valid_595399, JString, required = false,
                                 default = nil)
  if valid_595399 != nil:
    section.add "X-Amz-Signature", valid_595399
  var valid_595400 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595400 = validateParameter(valid_595400, JString, required = false,
                                 default = nil)
  if valid_595400 != nil:
    section.add "X-Amz-SignedHeaders", valid_595400
  var valid_595401 = header.getOrDefault("X-Amz-Credential")
  valid_595401 = validateParameter(valid_595401, JString, required = false,
                                 default = nil)
  if valid_595401 != nil:
    section.add "X-Amz-Credential", valid_595401
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595402: Call_GetSwapEnvironmentCNAMEs_595386; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Swaps the CNAMEs of two environments.
  ## 
  let valid = call_595402.validator(path, query, header, formData, body)
  let scheme = call_595402.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595402.url(scheme.get, call_595402.host, call_595402.base,
                         call_595402.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595402, url, valid)

proc call*(call_595403: Call_GetSwapEnvironmentCNAMEs_595386;
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
  var query_595404 = newJObject()
  add(query_595404, "SourceEnvironmentId", newJString(SourceEnvironmentId))
  add(query_595404, "DestinationEnvironmentName",
      newJString(DestinationEnvironmentName))
  add(query_595404, "Action", newJString(Action))
  add(query_595404, "SourceEnvironmentName", newJString(SourceEnvironmentName))
  add(query_595404, "DestinationEnvironmentId",
      newJString(DestinationEnvironmentId))
  add(query_595404, "Version", newJString(Version))
  result = call_595403.call(nil, query_595404, nil, nil, nil)

var getSwapEnvironmentCNAMEs* = Call_GetSwapEnvironmentCNAMEs_595386(
    name: "getSwapEnvironmentCNAMEs", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=SwapEnvironmentCNAMEs",
    validator: validate_GetSwapEnvironmentCNAMEs_595387, base: "/",
    url: url_GetSwapEnvironmentCNAMEs_595388, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostTerminateEnvironment_595444 = ref object of OpenApiRestCall_593438
proc url_PostTerminateEnvironment_595446(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostTerminateEnvironment_595445(path: JsonNode; query: JsonNode;
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
  var valid_595447 = query.getOrDefault("Action")
  valid_595447 = validateParameter(valid_595447, JString, required = true,
                                 default = newJString("TerminateEnvironment"))
  if valid_595447 != nil:
    section.add "Action", valid_595447
  var valid_595448 = query.getOrDefault("Version")
  valid_595448 = validateParameter(valid_595448, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_595448 != nil:
    section.add "Version", valid_595448
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595449 = header.getOrDefault("X-Amz-Date")
  valid_595449 = validateParameter(valid_595449, JString, required = false,
                                 default = nil)
  if valid_595449 != nil:
    section.add "X-Amz-Date", valid_595449
  var valid_595450 = header.getOrDefault("X-Amz-Security-Token")
  valid_595450 = validateParameter(valid_595450, JString, required = false,
                                 default = nil)
  if valid_595450 != nil:
    section.add "X-Amz-Security-Token", valid_595450
  var valid_595451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595451 = validateParameter(valid_595451, JString, required = false,
                                 default = nil)
  if valid_595451 != nil:
    section.add "X-Amz-Content-Sha256", valid_595451
  var valid_595452 = header.getOrDefault("X-Amz-Algorithm")
  valid_595452 = validateParameter(valid_595452, JString, required = false,
                                 default = nil)
  if valid_595452 != nil:
    section.add "X-Amz-Algorithm", valid_595452
  var valid_595453 = header.getOrDefault("X-Amz-Signature")
  valid_595453 = validateParameter(valid_595453, JString, required = false,
                                 default = nil)
  if valid_595453 != nil:
    section.add "X-Amz-Signature", valid_595453
  var valid_595454 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595454 = validateParameter(valid_595454, JString, required = false,
                                 default = nil)
  if valid_595454 != nil:
    section.add "X-Amz-SignedHeaders", valid_595454
  var valid_595455 = header.getOrDefault("X-Amz-Credential")
  valid_595455 = validateParameter(valid_595455, JString, required = false,
                                 default = nil)
  if valid_595455 != nil:
    section.add "X-Amz-Credential", valid_595455
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
  var valid_595456 = formData.getOrDefault("ForceTerminate")
  valid_595456 = validateParameter(valid_595456, JBool, required = false, default = nil)
  if valid_595456 != nil:
    section.add "ForceTerminate", valid_595456
  var valid_595457 = formData.getOrDefault("TerminateResources")
  valid_595457 = validateParameter(valid_595457, JBool, required = false, default = nil)
  if valid_595457 != nil:
    section.add "TerminateResources", valid_595457
  var valid_595458 = formData.getOrDefault("EnvironmentId")
  valid_595458 = validateParameter(valid_595458, JString, required = false,
                                 default = nil)
  if valid_595458 != nil:
    section.add "EnvironmentId", valid_595458
  var valid_595459 = formData.getOrDefault("EnvironmentName")
  valid_595459 = validateParameter(valid_595459, JString, required = false,
                                 default = nil)
  if valid_595459 != nil:
    section.add "EnvironmentName", valid_595459
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595460: Call_PostTerminateEnvironment_595444; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Terminates the specified environment.
  ## 
  let valid = call_595460.validator(path, query, header, formData, body)
  let scheme = call_595460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595460.url(scheme.get, call_595460.host, call_595460.base,
                         call_595460.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595460, url, valid)

proc call*(call_595461: Call_PostTerminateEnvironment_595444;
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
  var query_595462 = newJObject()
  var formData_595463 = newJObject()
  add(formData_595463, "ForceTerminate", newJBool(ForceTerminate))
  add(formData_595463, "TerminateResources", newJBool(TerminateResources))
  add(formData_595463, "EnvironmentId", newJString(EnvironmentId))
  add(formData_595463, "EnvironmentName", newJString(EnvironmentName))
  add(query_595462, "Action", newJString(Action))
  add(query_595462, "Version", newJString(Version))
  result = call_595461.call(nil, query_595462, nil, formData_595463, nil)

var postTerminateEnvironment* = Call_PostTerminateEnvironment_595444(
    name: "postTerminateEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=TerminateEnvironment",
    validator: validate_PostTerminateEnvironment_595445, base: "/",
    url: url_PostTerminateEnvironment_595446, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTerminateEnvironment_595425 = ref object of OpenApiRestCall_593438
proc url_GetTerminateEnvironment_595427(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetTerminateEnvironment_595426(path: JsonNode; query: JsonNode;
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
  var valid_595428 = query.getOrDefault("EnvironmentName")
  valid_595428 = validateParameter(valid_595428, JString, required = false,
                                 default = nil)
  if valid_595428 != nil:
    section.add "EnvironmentName", valid_595428
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595429 = query.getOrDefault("Action")
  valid_595429 = validateParameter(valid_595429, JString, required = true,
                                 default = newJString("TerminateEnvironment"))
  if valid_595429 != nil:
    section.add "Action", valid_595429
  var valid_595430 = query.getOrDefault("EnvironmentId")
  valid_595430 = validateParameter(valid_595430, JString, required = false,
                                 default = nil)
  if valid_595430 != nil:
    section.add "EnvironmentId", valid_595430
  var valid_595431 = query.getOrDefault("ForceTerminate")
  valid_595431 = validateParameter(valid_595431, JBool, required = false, default = nil)
  if valid_595431 != nil:
    section.add "ForceTerminate", valid_595431
  var valid_595432 = query.getOrDefault("TerminateResources")
  valid_595432 = validateParameter(valid_595432, JBool, required = false, default = nil)
  if valid_595432 != nil:
    section.add "TerminateResources", valid_595432
  var valid_595433 = query.getOrDefault("Version")
  valid_595433 = validateParameter(valid_595433, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_595433 != nil:
    section.add "Version", valid_595433
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595434 = header.getOrDefault("X-Amz-Date")
  valid_595434 = validateParameter(valid_595434, JString, required = false,
                                 default = nil)
  if valid_595434 != nil:
    section.add "X-Amz-Date", valid_595434
  var valid_595435 = header.getOrDefault("X-Amz-Security-Token")
  valid_595435 = validateParameter(valid_595435, JString, required = false,
                                 default = nil)
  if valid_595435 != nil:
    section.add "X-Amz-Security-Token", valid_595435
  var valid_595436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595436 = validateParameter(valid_595436, JString, required = false,
                                 default = nil)
  if valid_595436 != nil:
    section.add "X-Amz-Content-Sha256", valid_595436
  var valid_595437 = header.getOrDefault("X-Amz-Algorithm")
  valid_595437 = validateParameter(valid_595437, JString, required = false,
                                 default = nil)
  if valid_595437 != nil:
    section.add "X-Amz-Algorithm", valid_595437
  var valid_595438 = header.getOrDefault("X-Amz-Signature")
  valid_595438 = validateParameter(valid_595438, JString, required = false,
                                 default = nil)
  if valid_595438 != nil:
    section.add "X-Amz-Signature", valid_595438
  var valid_595439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595439 = validateParameter(valid_595439, JString, required = false,
                                 default = nil)
  if valid_595439 != nil:
    section.add "X-Amz-SignedHeaders", valid_595439
  var valid_595440 = header.getOrDefault("X-Amz-Credential")
  valid_595440 = validateParameter(valid_595440, JString, required = false,
                                 default = nil)
  if valid_595440 != nil:
    section.add "X-Amz-Credential", valid_595440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595441: Call_GetTerminateEnvironment_595425; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Terminates the specified environment.
  ## 
  let valid = call_595441.validator(path, query, header, formData, body)
  let scheme = call_595441.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595441.url(scheme.get, call_595441.host, call_595441.base,
                         call_595441.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595441, url, valid)

proc call*(call_595442: Call_GetTerminateEnvironment_595425;
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
  var query_595443 = newJObject()
  add(query_595443, "EnvironmentName", newJString(EnvironmentName))
  add(query_595443, "Action", newJString(Action))
  add(query_595443, "EnvironmentId", newJString(EnvironmentId))
  add(query_595443, "ForceTerminate", newJBool(ForceTerminate))
  add(query_595443, "TerminateResources", newJBool(TerminateResources))
  add(query_595443, "Version", newJString(Version))
  result = call_595442.call(nil, query_595443, nil, nil, nil)

var getTerminateEnvironment* = Call_GetTerminateEnvironment_595425(
    name: "getTerminateEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=TerminateEnvironment",
    validator: validate_GetTerminateEnvironment_595426, base: "/",
    url: url_GetTerminateEnvironment_595427, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateApplication_595481 = ref object of OpenApiRestCall_593438
proc url_PostUpdateApplication_595483(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateApplication_595482(path: JsonNode; query: JsonNode;
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
  var valid_595484 = query.getOrDefault("Action")
  valid_595484 = validateParameter(valid_595484, JString, required = true,
                                 default = newJString("UpdateApplication"))
  if valid_595484 != nil:
    section.add "Action", valid_595484
  var valid_595485 = query.getOrDefault("Version")
  valid_595485 = validateParameter(valid_595485, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_595485 != nil:
    section.add "Version", valid_595485
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595486 = header.getOrDefault("X-Amz-Date")
  valid_595486 = validateParameter(valid_595486, JString, required = false,
                                 default = nil)
  if valid_595486 != nil:
    section.add "X-Amz-Date", valid_595486
  var valid_595487 = header.getOrDefault("X-Amz-Security-Token")
  valid_595487 = validateParameter(valid_595487, JString, required = false,
                                 default = nil)
  if valid_595487 != nil:
    section.add "X-Amz-Security-Token", valid_595487
  var valid_595488 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595488 = validateParameter(valid_595488, JString, required = false,
                                 default = nil)
  if valid_595488 != nil:
    section.add "X-Amz-Content-Sha256", valid_595488
  var valid_595489 = header.getOrDefault("X-Amz-Algorithm")
  valid_595489 = validateParameter(valid_595489, JString, required = false,
                                 default = nil)
  if valid_595489 != nil:
    section.add "X-Amz-Algorithm", valid_595489
  var valid_595490 = header.getOrDefault("X-Amz-Signature")
  valid_595490 = validateParameter(valid_595490, JString, required = false,
                                 default = nil)
  if valid_595490 != nil:
    section.add "X-Amz-Signature", valid_595490
  var valid_595491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595491 = validateParameter(valid_595491, JString, required = false,
                                 default = nil)
  if valid_595491 != nil:
    section.add "X-Amz-SignedHeaders", valid_595491
  var valid_595492 = header.getOrDefault("X-Amz-Credential")
  valid_595492 = validateParameter(valid_595492, JString, required = false,
                                 default = nil)
  if valid_595492 != nil:
    section.add "X-Amz-Credential", valid_595492
  result.add "header", section
  ## parameters in `formData` object:
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to update. If no such application is found, <code>UpdateApplication</code> returns an <code>InvalidParameterValue</code> error. 
  ##   Description: JString
  ##              : <p>A new description for the application.</p> <p>Default: If not specified, AWS Elastic Beanstalk does not update the description.</p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_595493 = formData.getOrDefault("ApplicationName")
  valid_595493 = validateParameter(valid_595493, JString, required = true,
                                 default = nil)
  if valid_595493 != nil:
    section.add "ApplicationName", valid_595493
  var valid_595494 = formData.getOrDefault("Description")
  valid_595494 = validateParameter(valid_595494, JString, required = false,
                                 default = nil)
  if valid_595494 != nil:
    section.add "Description", valid_595494
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595495: Call_PostUpdateApplication_595481; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified application to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear these properties, specify an empty string.</p> </note>
  ## 
  let valid = call_595495.validator(path, query, header, formData, body)
  let scheme = call_595495.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595495.url(scheme.get, call_595495.host, call_595495.base,
                         call_595495.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595495, url, valid)

proc call*(call_595496: Call_PostUpdateApplication_595481; ApplicationName: string;
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
  var query_595497 = newJObject()
  var formData_595498 = newJObject()
  add(query_595497, "Action", newJString(Action))
  add(formData_595498, "ApplicationName", newJString(ApplicationName))
  add(query_595497, "Version", newJString(Version))
  add(formData_595498, "Description", newJString(Description))
  result = call_595496.call(nil, query_595497, nil, formData_595498, nil)

var postUpdateApplication* = Call_PostUpdateApplication_595481(
    name: "postUpdateApplication", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateApplication",
    validator: validate_PostUpdateApplication_595482, base: "/",
    url: url_PostUpdateApplication_595483, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateApplication_595464 = ref object of OpenApiRestCall_593438
proc url_GetUpdateApplication_595466(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateApplication_595465(path: JsonNode; query: JsonNode;
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
  var valid_595467 = query.getOrDefault("ApplicationName")
  valid_595467 = validateParameter(valid_595467, JString, required = true,
                                 default = nil)
  if valid_595467 != nil:
    section.add "ApplicationName", valid_595467
  var valid_595468 = query.getOrDefault("Description")
  valid_595468 = validateParameter(valid_595468, JString, required = false,
                                 default = nil)
  if valid_595468 != nil:
    section.add "Description", valid_595468
  var valid_595469 = query.getOrDefault("Action")
  valid_595469 = validateParameter(valid_595469, JString, required = true,
                                 default = newJString("UpdateApplication"))
  if valid_595469 != nil:
    section.add "Action", valid_595469
  var valid_595470 = query.getOrDefault("Version")
  valid_595470 = validateParameter(valid_595470, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_595470 != nil:
    section.add "Version", valid_595470
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595471 = header.getOrDefault("X-Amz-Date")
  valid_595471 = validateParameter(valid_595471, JString, required = false,
                                 default = nil)
  if valid_595471 != nil:
    section.add "X-Amz-Date", valid_595471
  var valid_595472 = header.getOrDefault("X-Amz-Security-Token")
  valid_595472 = validateParameter(valid_595472, JString, required = false,
                                 default = nil)
  if valid_595472 != nil:
    section.add "X-Amz-Security-Token", valid_595472
  var valid_595473 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595473 = validateParameter(valid_595473, JString, required = false,
                                 default = nil)
  if valid_595473 != nil:
    section.add "X-Amz-Content-Sha256", valid_595473
  var valid_595474 = header.getOrDefault("X-Amz-Algorithm")
  valid_595474 = validateParameter(valid_595474, JString, required = false,
                                 default = nil)
  if valid_595474 != nil:
    section.add "X-Amz-Algorithm", valid_595474
  var valid_595475 = header.getOrDefault("X-Amz-Signature")
  valid_595475 = validateParameter(valid_595475, JString, required = false,
                                 default = nil)
  if valid_595475 != nil:
    section.add "X-Amz-Signature", valid_595475
  var valid_595476 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595476 = validateParameter(valid_595476, JString, required = false,
                                 default = nil)
  if valid_595476 != nil:
    section.add "X-Amz-SignedHeaders", valid_595476
  var valid_595477 = header.getOrDefault("X-Amz-Credential")
  valid_595477 = validateParameter(valid_595477, JString, required = false,
                                 default = nil)
  if valid_595477 != nil:
    section.add "X-Amz-Credential", valid_595477
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595478: Call_GetUpdateApplication_595464; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified application to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear these properties, specify an empty string.</p> </note>
  ## 
  let valid = call_595478.validator(path, query, header, formData, body)
  let scheme = call_595478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595478.url(scheme.get, call_595478.host, call_595478.base,
                         call_595478.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595478, url, valid)

proc call*(call_595479: Call_GetUpdateApplication_595464; ApplicationName: string;
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
  var query_595480 = newJObject()
  add(query_595480, "ApplicationName", newJString(ApplicationName))
  add(query_595480, "Description", newJString(Description))
  add(query_595480, "Action", newJString(Action))
  add(query_595480, "Version", newJString(Version))
  result = call_595479.call(nil, query_595480, nil, nil, nil)

var getUpdateApplication* = Call_GetUpdateApplication_595464(
    name: "getUpdateApplication", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateApplication",
    validator: validate_GetUpdateApplication_595465, base: "/",
    url: url_GetUpdateApplication_595466, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateApplicationResourceLifecycle_595517 = ref object of OpenApiRestCall_593438
proc url_PostUpdateApplicationResourceLifecycle_595519(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateApplicationResourceLifecycle_595518(path: JsonNode;
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
  var valid_595520 = query.getOrDefault("Action")
  valid_595520 = validateParameter(valid_595520, JString, required = true, default = newJString(
      "UpdateApplicationResourceLifecycle"))
  if valid_595520 != nil:
    section.add "Action", valid_595520
  var valid_595521 = query.getOrDefault("Version")
  valid_595521 = validateParameter(valid_595521, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_595521 != nil:
    section.add "Version", valid_595521
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595522 = header.getOrDefault("X-Amz-Date")
  valid_595522 = validateParameter(valid_595522, JString, required = false,
                                 default = nil)
  if valid_595522 != nil:
    section.add "X-Amz-Date", valid_595522
  var valid_595523 = header.getOrDefault("X-Amz-Security-Token")
  valid_595523 = validateParameter(valid_595523, JString, required = false,
                                 default = nil)
  if valid_595523 != nil:
    section.add "X-Amz-Security-Token", valid_595523
  var valid_595524 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595524 = validateParameter(valid_595524, JString, required = false,
                                 default = nil)
  if valid_595524 != nil:
    section.add "X-Amz-Content-Sha256", valid_595524
  var valid_595525 = header.getOrDefault("X-Amz-Algorithm")
  valid_595525 = validateParameter(valid_595525, JString, required = false,
                                 default = nil)
  if valid_595525 != nil:
    section.add "X-Amz-Algorithm", valid_595525
  var valid_595526 = header.getOrDefault("X-Amz-Signature")
  valid_595526 = validateParameter(valid_595526, JString, required = false,
                                 default = nil)
  if valid_595526 != nil:
    section.add "X-Amz-Signature", valid_595526
  var valid_595527 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595527 = validateParameter(valid_595527, JString, required = false,
                                 default = nil)
  if valid_595527 != nil:
    section.add "X-Amz-SignedHeaders", valid_595527
  var valid_595528 = header.getOrDefault("X-Amz-Credential")
  valid_595528 = validateParameter(valid_595528, JString, required = false,
                                 default = nil)
  if valid_595528 != nil:
    section.add "X-Amz-Credential", valid_595528
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
  var valid_595529 = formData.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_595529 = validateParameter(valid_595529, JString, required = false,
                                 default = nil)
  if valid_595529 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_595529
  var valid_595530 = formData.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_595530 = validateParameter(valid_595530, JString, required = false,
                                 default = nil)
  if valid_595530 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_595530
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_595531 = formData.getOrDefault("ApplicationName")
  valid_595531 = validateParameter(valid_595531, JString, required = true,
                                 default = nil)
  if valid_595531 != nil:
    section.add "ApplicationName", valid_595531
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595532: Call_PostUpdateApplicationResourceLifecycle_595517;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Modifies lifecycle settings for an application.
  ## 
  let valid = call_595532.validator(path, query, header, formData, body)
  let scheme = call_595532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595532.url(scheme.get, call_595532.host, call_595532.base,
                         call_595532.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595532, url, valid)

proc call*(call_595533: Call_PostUpdateApplicationResourceLifecycle_595517;
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
  var query_595534 = newJObject()
  var formData_595535 = newJObject()
  add(formData_595535, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  add(formData_595535, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  add(query_595534, "Action", newJString(Action))
  add(formData_595535, "ApplicationName", newJString(ApplicationName))
  add(query_595534, "Version", newJString(Version))
  result = call_595533.call(nil, query_595534, nil, formData_595535, nil)

var postUpdateApplicationResourceLifecycle* = Call_PostUpdateApplicationResourceLifecycle_595517(
    name: "postUpdateApplicationResourceLifecycle", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationResourceLifecycle",
    validator: validate_PostUpdateApplicationResourceLifecycle_595518, base: "/",
    url: url_PostUpdateApplicationResourceLifecycle_595519,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateApplicationResourceLifecycle_595499 = ref object of OpenApiRestCall_593438
proc url_GetUpdateApplicationResourceLifecycle_595501(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateApplicationResourceLifecycle_595500(path: JsonNode;
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
  var valid_595502 = query.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_595502 = validateParameter(valid_595502, JString, required = false,
                                 default = nil)
  if valid_595502 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_595502
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_595503 = query.getOrDefault("ApplicationName")
  valid_595503 = validateParameter(valid_595503, JString, required = true,
                                 default = nil)
  if valid_595503 != nil:
    section.add "ApplicationName", valid_595503
  var valid_595504 = query.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_595504 = validateParameter(valid_595504, JString, required = false,
                                 default = nil)
  if valid_595504 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_595504
  var valid_595505 = query.getOrDefault("Action")
  valid_595505 = validateParameter(valid_595505, JString, required = true, default = newJString(
      "UpdateApplicationResourceLifecycle"))
  if valid_595505 != nil:
    section.add "Action", valid_595505
  var valid_595506 = query.getOrDefault("Version")
  valid_595506 = validateParameter(valid_595506, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_595506 != nil:
    section.add "Version", valid_595506
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595507 = header.getOrDefault("X-Amz-Date")
  valid_595507 = validateParameter(valid_595507, JString, required = false,
                                 default = nil)
  if valid_595507 != nil:
    section.add "X-Amz-Date", valid_595507
  var valid_595508 = header.getOrDefault("X-Amz-Security-Token")
  valid_595508 = validateParameter(valid_595508, JString, required = false,
                                 default = nil)
  if valid_595508 != nil:
    section.add "X-Amz-Security-Token", valid_595508
  var valid_595509 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595509 = validateParameter(valid_595509, JString, required = false,
                                 default = nil)
  if valid_595509 != nil:
    section.add "X-Amz-Content-Sha256", valid_595509
  var valid_595510 = header.getOrDefault("X-Amz-Algorithm")
  valid_595510 = validateParameter(valid_595510, JString, required = false,
                                 default = nil)
  if valid_595510 != nil:
    section.add "X-Amz-Algorithm", valid_595510
  var valid_595511 = header.getOrDefault("X-Amz-Signature")
  valid_595511 = validateParameter(valid_595511, JString, required = false,
                                 default = nil)
  if valid_595511 != nil:
    section.add "X-Amz-Signature", valid_595511
  var valid_595512 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595512 = validateParameter(valid_595512, JString, required = false,
                                 default = nil)
  if valid_595512 != nil:
    section.add "X-Amz-SignedHeaders", valid_595512
  var valid_595513 = header.getOrDefault("X-Amz-Credential")
  valid_595513 = validateParameter(valid_595513, JString, required = false,
                                 default = nil)
  if valid_595513 != nil:
    section.add "X-Amz-Credential", valid_595513
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595514: Call_GetUpdateApplicationResourceLifecycle_595499;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Modifies lifecycle settings for an application.
  ## 
  let valid = call_595514.validator(path, query, header, formData, body)
  let scheme = call_595514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595514.url(scheme.get, call_595514.host, call_595514.base,
                         call_595514.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595514, url, valid)

proc call*(call_595515: Call_GetUpdateApplicationResourceLifecycle_595499;
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
  var query_595516 = newJObject()
  add(query_595516, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  add(query_595516, "ApplicationName", newJString(ApplicationName))
  add(query_595516, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  add(query_595516, "Action", newJString(Action))
  add(query_595516, "Version", newJString(Version))
  result = call_595515.call(nil, query_595516, nil, nil, nil)

var getUpdateApplicationResourceLifecycle* = Call_GetUpdateApplicationResourceLifecycle_595499(
    name: "getUpdateApplicationResourceLifecycle", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationResourceLifecycle",
    validator: validate_GetUpdateApplicationResourceLifecycle_595500, base: "/",
    url: url_GetUpdateApplicationResourceLifecycle_595501,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateApplicationVersion_595554 = ref object of OpenApiRestCall_593438
proc url_PostUpdateApplicationVersion_595556(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateApplicationVersion_595555(path: JsonNode; query: JsonNode;
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
  var valid_595557 = query.getOrDefault("Action")
  valid_595557 = validateParameter(valid_595557, JString, required = true, default = newJString(
      "UpdateApplicationVersion"))
  if valid_595557 != nil:
    section.add "Action", valid_595557
  var valid_595558 = query.getOrDefault("Version")
  valid_595558 = validateParameter(valid_595558, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_595558 != nil:
    section.add "Version", valid_595558
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595559 = header.getOrDefault("X-Amz-Date")
  valid_595559 = validateParameter(valid_595559, JString, required = false,
                                 default = nil)
  if valid_595559 != nil:
    section.add "X-Amz-Date", valid_595559
  var valid_595560 = header.getOrDefault("X-Amz-Security-Token")
  valid_595560 = validateParameter(valid_595560, JString, required = false,
                                 default = nil)
  if valid_595560 != nil:
    section.add "X-Amz-Security-Token", valid_595560
  var valid_595561 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595561 = validateParameter(valid_595561, JString, required = false,
                                 default = nil)
  if valid_595561 != nil:
    section.add "X-Amz-Content-Sha256", valid_595561
  var valid_595562 = header.getOrDefault("X-Amz-Algorithm")
  valid_595562 = validateParameter(valid_595562, JString, required = false,
                                 default = nil)
  if valid_595562 != nil:
    section.add "X-Amz-Algorithm", valid_595562
  var valid_595563 = header.getOrDefault("X-Amz-Signature")
  valid_595563 = validateParameter(valid_595563, JString, required = false,
                                 default = nil)
  if valid_595563 != nil:
    section.add "X-Amz-Signature", valid_595563
  var valid_595564 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595564 = validateParameter(valid_595564, JString, required = false,
                                 default = nil)
  if valid_595564 != nil:
    section.add "X-Amz-SignedHeaders", valid_595564
  var valid_595565 = header.getOrDefault("X-Amz-Credential")
  valid_595565 = validateParameter(valid_595565, JString, required = false,
                                 default = nil)
  if valid_595565 != nil:
    section.add "X-Amz-Credential", valid_595565
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
  var valid_595566 = formData.getOrDefault("VersionLabel")
  valid_595566 = validateParameter(valid_595566, JString, required = true,
                                 default = nil)
  if valid_595566 != nil:
    section.add "VersionLabel", valid_595566
  var valid_595567 = formData.getOrDefault("ApplicationName")
  valid_595567 = validateParameter(valid_595567, JString, required = true,
                                 default = nil)
  if valid_595567 != nil:
    section.add "ApplicationName", valid_595567
  var valid_595568 = formData.getOrDefault("Description")
  valid_595568 = validateParameter(valid_595568, JString, required = false,
                                 default = nil)
  if valid_595568 != nil:
    section.add "Description", valid_595568
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595569: Call_PostUpdateApplicationVersion_595554; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified application version to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear properties, specify an empty string.</p> </note>
  ## 
  let valid = call_595569.validator(path, query, header, formData, body)
  let scheme = call_595569.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595569.url(scheme.get, call_595569.host, call_595569.base,
                         call_595569.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595569, url, valid)

proc call*(call_595570: Call_PostUpdateApplicationVersion_595554;
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
  var query_595571 = newJObject()
  var formData_595572 = newJObject()
  add(formData_595572, "VersionLabel", newJString(VersionLabel))
  add(query_595571, "Action", newJString(Action))
  add(formData_595572, "ApplicationName", newJString(ApplicationName))
  add(query_595571, "Version", newJString(Version))
  add(formData_595572, "Description", newJString(Description))
  result = call_595570.call(nil, query_595571, nil, formData_595572, nil)

var postUpdateApplicationVersion* = Call_PostUpdateApplicationVersion_595554(
    name: "postUpdateApplicationVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationVersion",
    validator: validate_PostUpdateApplicationVersion_595555, base: "/",
    url: url_PostUpdateApplicationVersion_595556,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateApplicationVersion_595536 = ref object of OpenApiRestCall_593438
proc url_GetUpdateApplicationVersion_595538(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateApplicationVersion_595537(path: JsonNode; query: JsonNode;
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
  var valid_595539 = query.getOrDefault("VersionLabel")
  valid_595539 = validateParameter(valid_595539, JString, required = true,
                                 default = nil)
  if valid_595539 != nil:
    section.add "VersionLabel", valid_595539
  var valid_595540 = query.getOrDefault("ApplicationName")
  valid_595540 = validateParameter(valid_595540, JString, required = true,
                                 default = nil)
  if valid_595540 != nil:
    section.add "ApplicationName", valid_595540
  var valid_595541 = query.getOrDefault("Description")
  valid_595541 = validateParameter(valid_595541, JString, required = false,
                                 default = nil)
  if valid_595541 != nil:
    section.add "Description", valid_595541
  var valid_595542 = query.getOrDefault("Action")
  valid_595542 = validateParameter(valid_595542, JString, required = true, default = newJString(
      "UpdateApplicationVersion"))
  if valid_595542 != nil:
    section.add "Action", valid_595542
  var valid_595543 = query.getOrDefault("Version")
  valid_595543 = validateParameter(valid_595543, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_595543 != nil:
    section.add "Version", valid_595543
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595544 = header.getOrDefault("X-Amz-Date")
  valid_595544 = validateParameter(valid_595544, JString, required = false,
                                 default = nil)
  if valid_595544 != nil:
    section.add "X-Amz-Date", valid_595544
  var valid_595545 = header.getOrDefault("X-Amz-Security-Token")
  valid_595545 = validateParameter(valid_595545, JString, required = false,
                                 default = nil)
  if valid_595545 != nil:
    section.add "X-Amz-Security-Token", valid_595545
  var valid_595546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595546 = validateParameter(valid_595546, JString, required = false,
                                 default = nil)
  if valid_595546 != nil:
    section.add "X-Amz-Content-Sha256", valid_595546
  var valid_595547 = header.getOrDefault("X-Amz-Algorithm")
  valid_595547 = validateParameter(valid_595547, JString, required = false,
                                 default = nil)
  if valid_595547 != nil:
    section.add "X-Amz-Algorithm", valid_595547
  var valid_595548 = header.getOrDefault("X-Amz-Signature")
  valid_595548 = validateParameter(valid_595548, JString, required = false,
                                 default = nil)
  if valid_595548 != nil:
    section.add "X-Amz-Signature", valid_595548
  var valid_595549 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595549 = validateParameter(valid_595549, JString, required = false,
                                 default = nil)
  if valid_595549 != nil:
    section.add "X-Amz-SignedHeaders", valid_595549
  var valid_595550 = header.getOrDefault("X-Amz-Credential")
  valid_595550 = validateParameter(valid_595550, JString, required = false,
                                 default = nil)
  if valid_595550 != nil:
    section.add "X-Amz-Credential", valid_595550
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595551: Call_GetUpdateApplicationVersion_595536; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified application version to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear properties, specify an empty string.</p> </note>
  ## 
  let valid = call_595551.validator(path, query, header, formData, body)
  let scheme = call_595551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595551.url(scheme.get, call_595551.host, call_595551.base,
                         call_595551.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595551, url, valid)

proc call*(call_595552: Call_GetUpdateApplicationVersion_595536;
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
  var query_595553 = newJObject()
  add(query_595553, "VersionLabel", newJString(VersionLabel))
  add(query_595553, "ApplicationName", newJString(ApplicationName))
  add(query_595553, "Description", newJString(Description))
  add(query_595553, "Action", newJString(Action))
  add(query_595553, "Version", newJString(Version))
  result = call_595552.call(nil, query_595553, nil, nil, nil)

var getUpdateApplicationVersion* = Call_GetUpdateApplicationVersion_595536(
    name: "getUpdateApplicationVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationVersion",
    validator: validate_GetUpdateApplicationVersion_595537, base: "/",
    url: url_GetUpdateApplicationVersion_595538,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateConfigurationTemplate_595593 = ref object of OpenApiRestCall_593438
proc url_PostUpdateConfigurationTemplate_595595(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateConfigurationTemplate_595594(path: JsonNode;
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
  var valid_595596 = query.getOrDefault("Action")
  valid_595596 = validateParameter(valid_595596, JString, required = true, default = newJString(
      "UpdateConfigurationTemplate"))
  if valid_595596 != nil:
    section.add "Action", valid_595596
  var valid_595597 = query.getOrDefault("Version")
  valid_595597 = validateParameter(valid_595597, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_595597 != nil:
    section.add "Version", valid_595597
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595598 = header.getOrDefault("X-Amz-Date")
  valid_595598 = validateParameter(valid_595598, JString, required = false,
                                 default = nil)
  if valid_595598 != nil:
    section.add "X-Amz-Date", valid_595598
  var valid_595599 = header.getOrDefault("X-Amz-Security-Token")
  valid_595599 = validateParameter(valid_595599, JString, required = false,
                                 default = nil)
  if valid_595599 != nil:
    section.add "X-Amz-Security-Token", valid_595599
  var valid_595600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595600 = validateParameter(valid_595600, JString, required = false,
                                 default = nil)
  if valid_595600 != nil:
    section.add "X-Amz-Content-Sha256", valid_595600
  var valid_595601 = header.getOrDefault("X-Amz-Algorithm")
  valid_595601 = validateParameter(valid_595601, JString, required = false,
                                 default = nil)
  if valid_595601 != nil:
    section.add "X-Amz-Algorithm", valid_595601
  var valid_595602 = header.getOrDefault("X-Amz-Signature")
  valid_595602 = validateParameter(valid_595602, JString, required = false,
                                 default = nil)
  if valid_595602 != nil:
    section.add "X-Amz-Signature", valid_595602
  var valid_595603 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595603 = validateParameter(valid_595603, JString, required = false,
                                 default = nil)
  if valid_595603 != nil:
    section.add "X-Amz-SignedHeaders", valid_595603
  var valid_595604 = header.getOrDefault("X-Amz-Credential")
  valid_595604 = validateParameter(valid_595604, JString, required = false,
                                 default = nil)
  if valid_595604 != nil:
    section.add "X-Amz-Credential", valid_595604
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
  var valid_595605 = formData.getOrDefault("OptionsToRemove")
  valid_595605 = validateParameter(valid_595605, JArray, required = false,
                                 default = nil)
  if valid_595605 != nil:
    section.add "OptionsToRemove", valid_595605
  var valid_595606 = formData.getOrDefault("OptionSettings")
  valid_595606 = validateParameter(valid_595606, JArray, required = false,
                                 default = nil)
  if valid_595606 != nil:
    section.add "OptionSettings", valid_595606
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_595607 = formData.getOrDefault("ApplicationName")
  valid_595607 = validateParameter(valid_595607, JString, required = true,
                                 default = nil)
  if valid_595607 != nil:
    section.add "ApplicationName", valid_595607
  var valid_595608 = formData.getOrDefault("TemplateName")
  valid_595608 = validateParameter(valid_595608, JString, required = true,
                                 default = nil)
  if valid_595608 != nil:
    section.add "TemplateName", valid_595608
  var valid_595609 = formData.getOrDefault("Description")
  valid_595609 = validateParameter(valid_595609, JString, required = false,
                                 default = nil)
  if valid_595609 != nil:
    section.add "Description", valid_595609
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595610: Call_PostUpdateConfigurationTemplate_595593;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Updates the specified configuration template to have the specified properties or configuration option values.</p> <note> <p>If a property (for example, <code>ApplicationName</code>) is not provided, its value remains unchanged. To clear such properties, specify an empty string.</p> </note> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> </ul>
  ## 
  let valid = call_595610.validator(path, query, header, formData, body)
  let scheme = call_595610.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595610.url(scheme.get, call_595610.host, call_595610.base,
                         call_595610.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595610, url, valid)

proc call*(call_595611: Call_PostUpdateConfigurationTemplate_595593;
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
  var query_595612 = newJObject()
  var formData_595613 = newJObject()
  if OptionsToRemove != nil:
    formData_595613.add "OptionsToRemove", OptionsToRemove
  if OptionSettings != nil:
    formData_595613.add "OptionSettings", OptionSettings
  add(query_595612, "Action", newJString(Action))
  add(formData_595613, "ApplicationName", newJString(ApplicationName))
  add(formData_595613, "TemplateName", newJString(TemplateName))
  add(query_595612, "Version", newJString(Version))
  add(formData_595613, "Description", newJString(Description))
  result = call_595611.call(nil, query_595612, nil, formData_595613, nil)

var postUpdateConfigurationTemplate* = Call_PostUpdateConfigurationTemplate_595593(
    name: "postUpdateConfigurationTemplate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateConfigurationTemplate",
    validator: validate_PostUpdateConfigurationTemplate_595594, base: "/",
    url: url_PostUpdateConfigurationTemplate_595595,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateConfigurationTemplate_595573 = ref object of OpenApiRestCall_593438
proc url_GetUpdateConfigurationTemplate_595575(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateConfigurationTemplate_595574(path: JsonNode;
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
  var valid_595576 = query.getOrDefault("ApplicationName")
  valid_595576 = validateParameter(valid_595576, JString, required = true,
                                 default = nil)
  if valid_595576 != nil:
    section.add "ApplicationName", valid_595576
  var valid_595577 = query.getOrDefault("Description")
  valid_595577 = validateParameter(valid_595577, JString, required = false,
                                 default = nil)
  if valid_595577 != nil:
    section.add "Description", valid_595577
  var valid_595578 = query.getOrDefault("OptionsToRemove")
  valid_595578 = validateParameter(valid_595578, JArray, required = false,
                                 default = nil)
  if valid_595578 != nil:
    section.add "OptionsToRemove", valid_595578
  var valid_595579 = query.getOrDefault("Action")
  valid_595579 = validateParameter(valid_595579, JString, required = true, default = newJString(
      "UpdateConfigurationTemplate"))
  if valid_595579 != nil:
    section.add "Action", valid_595579
  var valid_595580 = query.getOrDefault("TemplateName")
  valid_595580 = validateParameter(valid_595580, JString, required = true,
                                 default = nil)
  if valid_595580 != nil:
    section.add "TemplateName", valid_595580
  var valid_595581 = query.getOrDefault("OptionSettings")
  valid_595581 = validateParameter(valid_595581, JArray, required = false,
                                 default = nil)
  if valid_595581 != nil:
    section.add "OptionSettings", valid_595581
  var valid_595582 = query.getOrDefault("Version")
  valid_595582 = validateParameter(valid_595582, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_595582 != nil:
    section.add "Version", valid_595582
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595583 = header.getOrDefault("X-Amz-Date")
  valid_595583 = validateParameter(valid_595583, JString, required = false,
                                 default = nil)
  if valid_595583 != nil:
    section.add "X-Amz-Date", valid_595583
  var valid_595584 = header.getOrDefault("X-Amz-Security-Token")
  valid_595584 = validateParameter(valid_595584, JString, required = false,
                                 default = nil)
  if valid_595584 != nil:
    section.add "X-Amz-Security-Token", valid_595584
  var valid_595585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595585 = validateParameter(valid_595585, JString, required = false,
                                 default = nil)
  if valid_595585 != nil:
    section.add "X-Amz-Content-Sha256", valid_595585
  var valid_595586 = header.getOrDefault("X-Amz-Algorithm")
  valid_595586 = validateParameter(valid_595586, JString, required = false,
                                 default = nil)
  if valid_595586 != nil:
    section.add "X-Amz-Algorithm", valid_595586
  var valid_595587 = header.getOrDefault("X-Amz-Signature")
  valid_595587 = validateParameter(valid_595587, JString, required = false,
                                 default = nil)
  if valid_595587 != nil:
    section.add "X-Amz-Signature", valid_595587
  var valid_595588 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595588 = validateParameter(valid_595588, JString, required = false,
                                 default = nil)
  if valid_595588 != nil:
    section.add "X-Amz-SignedHeaders", valid_595588
  var valid_595589 = header.getOrDefault("X-Amz-Credential")
  valid_595589 = validateParameter(valid_595589, JString, required = false,
                                 default = nil)
  if valid_595589 != nil:
    section.add "X-Amz-Credential", valid_595589
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595590: Call_GetUpdateConfigurationTemplate_595573; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified configuration template to have the specified properties or configuration option values.</p> <note> <p>If a property (for example, <code>ApplicationName</code>) is not provided, its value remains unchanged. To clear such properties, specify an empty string.</p> </note> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> </ul>
  ## 
  let valid = call_595590.validator(path, query, header, formData, body)
  let scheme = call_595590.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595590.url(scheme.get, call_595590.host, call_595590.base,
                         call_595590.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595590, url, valid)

proc call*(call_595591: Call_GetUpdateConfigurationTemplate_595573;
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
  var query_595592 = newJObject()
  add(query_595592, "ApplicationName", newJString(ApplicationName))
  add(query_595592, "Description", newJString(Description))
  if OptionsToRemove != nil:
    query_595592.add "OptionsToRemove", OptionsToRemove
  add(query_595592, "Action", newJString(Action))
  add(query_595592, "TemplateName", newJString(TemplateName))
  if OptionSettings != nil:
    query_595592.add "OptionSettings", OptionSettings
  add(query_595592, "Version", newJString(Version))
  result = call_595591.call(nil, query_595592, nil, nil, nil)

var getUpdateConfigurationTemplate* = Call_GetUpdateConfigurationTemplate_595573(
    name: "getUpdateConfigurationTemplate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateConfigurationTemplate",
    validator: validate_GetUpdateConfigurationTemplate_595574, base: "/",
    url: url_GetUpdateConfigurationTemplate_595575,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateEnvironment_595643 = ref object of OpenApiRestCall_593438
proc url_PostUpdateEnvironment_595645(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateEnvironment_595644(path: JsonNode; query: JsonNode;
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
  var valid_595646 = query.getOrDefault("Action")
  valid_595646 = validateParameter(valid_595646, JString, required = true,
                                 default = newJString("UpdateEnvironment"))
  if valid_595646 != nil:
    section.add "Action", valid_595646
  var valid_595647 = query.getOrDefault("Version")
  valid_595647 = validateParameter(valid_595647, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_595647 != nil:
    section.add "Version", valid_595647
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595648 = header.getOrDefault("X-Amz-Date")
  valid_595648 = validateParameter(valid_595648, JString, required = false,
                                 default = nil)
  if valid_595648 != nil:
    section.add "X-Amz-Date", valid_595648
  var valid_595649 = header.getOrDefault("X-Amz-Security-Token")
  valid_595649 = validateParameter(valid_595649, JString, required = false,
                                 default = nil)
  if valid_595649 != nil:
    section.add "X-Amz-Security-Token", valid_595649
  var valid_595650 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595650 = validateParameter(valid_595650, JString, required = false,
                                 default = nil)
  if valid_595650 != nil:
    section.add "X-Amz-Content-Sha256", valid_595650
  var valid_595651 = header.getOrDefault("X-Amz-Algorithm")
  valid_595651 = validateParameter(valid_595651, JString, required = false,
                                 default = nil)
  if valid_595651 != nil:
    section.add "X-Amz-Algorithm", valid_595651
  var valid_595652 = header.getOrDefault("X-Amz-Signature")
  valid_595652 = validateParameter(valid_595652, JString, required = false,
                                 default = nil)
  if valid_595652 != nil:
    section.add "X-Amz-Signature", valid_595652
  var valid_595653 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595653 = validateParameter(valid_595653, JString, required = false,
                                 default = nil)
  if valid_595653 != nil:
    section.add "X-Amz-SignedHeaders", valid_595653
  var valid_595654 = header.getOrDefault("X-Amz-Credential")
  valid_595654 = validateParameter(valid_595654, JString, required = false,
                                 default = nil)
  if valid_595654 != nil:
    section.add "X-Amz-Credential", valid_595654
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
  var valid_595655 = formData.getOrDefault("Tier.Name")
  valid_595655 = validateParameter(valid_595655, JString, required = false,
                                 default = nil)
  if valid_595655 != nil:
    section.add "Tier.Name", valid_595655
  var valid_595656 = formData.getOrDefault("OptionsToRemove")
  valid_595656 = validateParameter(valid_595656, JArray, required = false,
                                 default = nil)
  if valid_595656 != nil:
    section.add "OptionsToRemove", valid_595656
  var valid_595657 = formData.getOrDefault("VersionLabel")
  valid_595657 = validateParameter(valid_595657, JString, required = false,
                                 default = nil)
  if valid_595657 != nil:
    section.add "VersionLabel", valid_595657
  var valid_595658 = formData.getOrDefault("OptionSettings")
  valid_595658 = validateParameter(valid_595658, JArray, required = false,
                                 default = nil)
  if valid_595658 != nil:
    section.add "OptionSettings", valid_595658
  var valid_595659 = formData.getOrDefault("GroupName")
  valid_595659 = validateParameter(valid_595659, JString, required = false,
                                 default = nil)
  if valid_595659 != nil:
    section.add "GroupName", valid_595659
  var valid_595660 = formData.getOrDefault("SolutionStackName")
  valid_595660 = validateParameter(valid_595660, JString, required = false,
                                 default = nil)
  if valid_595660 != nil:
    section.add "SolutionStackName", valid_595660
  var valid_595661 = formData.getOrDefault("EnvironmentId")
  valid_595661 = validateParameter(valid_595661, JString, required = false,
                                 default = nil)
  if valid_595661 != nil:
    section.add "EnvironmentId", valid_595661
  var valid_595662 = formData.getOrDefault("EnvironmentName")
  valid_595662 = validateParameter(valid_595662, JString, required = false,
                                 default = nil)
  if valid_595662 != nil:
    section.add "EnvironmentName", valid_595662
  var valid_595663 = formData.getOrDefault("Tier.Type")
  valid_595663 = validateParameter(valid_595663, JString, required = false,
                                 default = nil)
  if valid_595663 != nil:
    section.add "Tier.Type", valid_595663
  var valid_595664 = formData.getOrDefault("ApplicationName")
  valid_595664 = validateParameter(valid_595664, JString, required = false,
                                 default = nil)
  if valid_595664 != nil:
    section.add "ApplicationName", valid_595664
  var valid_595665 = formData.getOrDefault("PlatformArn")
  valid_595665 = validateParameter(valid_595665, JString, required = false,
                                 default = nil)
  if valid_595665 != nil:
    section.add "PlatformArn", valid_595665
  var valid_595666 = formData.getOrDefault("TemplateName")
  valid_595666 = validateParameter(valid_595666, JString, required = false,
                                 default = nil)
  if valid_595666 != nil:
    section.add "TemplateName", valid_595666
  var valid_595667 = formData.getOrDefault("Description")
  valid_595667 = validateParameter(valid_595667, JString, required = false,
                                 default = nil)
  if valid_595667 != nil:
    section.add "Description", valid_595667
  var valid_595668 = formData.getOrDefault("Tier.Version")
  valid_595668 = validateParameter(valid_595668, JString, required = false,
                                 default = nil)
  if valid_595668 != nil:
    section.add "Tier.Version", valid_595668
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595669: Call_PostUpdateEnvironment_595643; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the environment description, deploys a new application version, updates the configuration settings to an entirely new configuration template, or updates select configuration option values in the running environment.</p> <p> Attempting to update both the release and configuration is not allowed and AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. </p> <p> When updating the configuration settings to a new template or individual settings, a draft configuration is created and <a>DescribeConfigurationSettings</a> for this environment returns two setting descriptions with different <code>DeploymentStatus</code> values. </p>
  ## 
  let valid = call_595669.validator(path, query, header, formData, body)
  let scheme = call_595669.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595669.url(scheme.get, call_595669.host, call_595669.base,
                         call_595669.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595669, url, valid)

proc call*(call_595670: Call_PostUpdateEnvironment_595643; TierName: string = "";
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
  var query_595671 = newJObject()
  var formData_595672 = newJObject()
  add(formData_595672, "Tier.Name", newJString(TierName))
  if OptionsToRemove != nil:
    formData_595672.add "OptionsToRemove", OptionsToRemove
  add(formData_595672, "VersionLabel", newJString(VersionLabel))
  if OptionSettings != nil:
    formData_595672.add "OptionSettings", OptionSettings
  add(formData_595672, "GroupName", newJString(GroupName))
  add(formData_595672, "SolutionStackName", newJString(SolutionStackName))
  add(formData_595672, "EnvironmentId", newJString(EnvironmentId))
  add(formData_595672, "EnvironmentName", newJString(EnvironmentName))
  add(formData_595672, "Tier.Type", newJString(TierType))
  add(query_595671, "Action", newJString(Action))
  add(formData_595672, "ApplicationName", newJString(ApplicationName))
  add(formData_595672, "PlatformArn", newJString(PlatformArn))
  add(formData_595672, "TemplateName", newJString(TemplateName))
  add(query_595671, "Version", newJString(Version))
  add(formData_595672, "Description", newJString(Description))
  add(formData_595672, "Tier.Version", newJString(TierVersion))
  result = call_595670.call(nil, query_595671, nil, formData_595672, nil)

var postUpdateEnvironment* = Call_PostUpdateEnvironment_595643(
    name: "postUpdateEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateEnvironment",
    validator: validate_PostUpdateEnvironment_595644, base: "/",
    url: url_PostUpdateEnvironment_595645, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateEnvironment_595614 = ref object of OpenApiRestCall_593438
proc url_GetUpdateEnvironment_595616(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateEnvironment_595615(path: JsonNode; query: JsonNode;
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
  var valid_595617 = query.getOrDefault("Tier.Name")
  valid_595617 = validateParameter(valid_595617, JString, required = false,
                                 default = nil)
  if valid_595617 != nil:
    section.add "Tier.Name", valid_595617
  var valid_595618 = query.getOrDefault("VersionLabel")
  valid_595618 = validateParameter(valid_595618, JString, required = false,
                                 default = nil)
  if valid_595618 != nil:
    section.add "VersionLabel", valid_595618
  var valid_595619 = query.getOrDefault("ApplicationName")
  valid_595619 = validateParameter(valid_595619, JString, required = false,
                                 default = nil)
  if valid_595619 != nil:
    section.add "ApplicationName", valid_595619
  var valid_595620 = query.getOrDefault("Description")
  valid_595620 = validateParameter(valid_595620, JString, required = false,
                                 default = nil)
  if valid_595620 != nil:
    section.add "Description", valid_595620
  var valid_595621 = query.getOrDefault("OptionsToRemove")
  valid_595621 = validateParameter(valid_595621, JArray, required = false,
                                 default = nil)
  if valid_595621 != nil:
    section.add "OptionsToRemove", valid_595621
  var valid_595622 = query.getOrDefault("PlatformArn")
  valid_595622 = validateParameter(valid_595622, JString, required = false,
                                 default = nil)
  if valid_595622 != nil:
    section.add "PlatformArn", valid_595622
  var valid_595623 = query.getOrDefault("EnvironmentName")
  valid_595623 = validateParameter(valid_595623, JString, required = false,
                                 default = nil)
  if valid_595623 != nil:
    section.add "EnvironmentName", valid_595623
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_595624 = query.getOrDefault("Action")
  valid_595624 = validateParameter(valid_595624, JString, required = true,
                                 default = newJString("UpdateEnvironment"))
  if valid_595624 != nil:
    section.add "Action", valid_595624
  var valid_595625 = query.getOrDefault("EnvironmentId")
  valid_595625 = validateParameter(valid_595625, JString, required = false,
                                 default = nil)
  if valid_595625 != nil:
    section.add "EnvironmentId", valid_595625
  var valid_595626 = query.getOrDefault("Tier.Version")
  valid_595626 = validateParameter(valid_595626, JString, required = false,
                                 default = nil)
  if valid_595626 != nil:
    section.add "Tier.Version", valid_595626
  var valid_595627 = query.getOrDefault("SolutionStackName")
  valid_595627 = validateParameter(valid_595627, JString, required = false,
                                 default = nil)
  if valid_595627 != nil:
    section.add "SolutionStackName", valid_595627
  var valid_595628 = query.getOrDefault("TemplateName")
  valid_595628 = validateParameter(valid_595628, JString, required = false,
                                 default = nil)
  if valid_595628 != nil:
    section.add "TemplateName", valid_595628
  var valid_595629 = query.getOrDefault("GroupName")
  valid_595629 = validateParameter(valid_595629, JString, required = false,
                                 default = nil)
  if valid_595629 != nil:
    section.add "GroupName", valid_595629
  var valid_595630 = query.getOrDefault("OptionSettings")
  valid_595630 = validateParameter(valid_595630, JArray, required = false,
                                 default = nil)
  if valid_595630 != nil:
    section.add "OptionSettings", valid_595630
  var valid_595631 = query.getOrDefault("Tier.Type")
  valid_595631 = validateParameter(valid_595631, JString, required = false,
                                 default = nil)
  if valid_595631 != nil:
    section.add "Tier.Type", valid_595631
  var valid_595632 = query.getOrDefault("Version")
  valid_595632 = validateParameter(valid_595632, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_595632 != nil:
    section.add "Version", valid_595632
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595633 = header.getOrDefault("X-Amz-Date")
  valid_595633 = validateParameter(valid_595633, JString, required = false,
                                 default = nil)
  if valid_595633 != nil:
    section.add "X-Amz-Date", valid_595633
  var valid_595634 = header.getOrDefault("X-Amz-Security-Token")
  valid_595634 = validateParameter(valid_595634, JString, required = false,
                                 default = nil)
  if valid_595634 != nil:
    section.add "X-Amz-Security-Token", valid_595634
  var valid_595635 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595635 = validateParameter(valid_595635, JString, required = false,
                                 default = nil)
  if valid_595635 != nil:
    section.add "X-Amz-Content-Sha256", valid_595635
  var valid_595636 = header.getOrDefault("X-Amz-Algorithm")
  valid_595636 = validateParameter(valid_595636, JString, required = false,
                                 default = nil)
  if valid_595636 != nil:
    section.add "X-Amz-Algorithm", valid_595636
  var valid_595637 = header.getOrDefault("X-Amz-Signature")
  valid_595637 = validateParameter(valid_595637, JString, required = false,
                                 default = nil)
  if valid_595637 != nil:
    section.add "X-Amz-Signature", valid_595637
  var valid_595638 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595638 = validateParameter(valid_595638, JString, required = false,
                                 default = nil)
  if valid_595638 != nil:
    section.add "X-Amz-SignedHeaders", valid_595638
  var valid_595639 = header.getOrDefault("X-Amz-Credential")
  valid_595639 = validateParameter(valid_595639, JString, required = false,
                                 default = nil)
  if valid_595639 != nil:
    section.add "X-Amz-Credential", valid_595639
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595640: Call_GetUpdateEnvironment_595614; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the environment description, deploys a new application version, updates the configuration settings to an entirely new configuration template, or updates select configuration option values in the running environment.</p> <p> Attempting to update both the release and configuration is not allowed and AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. </p> <p> When updating the configuration settings to a new template or individual settings, a draft configuration is created and <a>DescribeConfigurationSettings</a> for this environment returns two setting descriptions with different <code>DeploymentStatus</code> values. </p>
  ## 
  let valid = call_595640.validator(path, query, header, formData, body)
  let scheme = call_595640.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595640.url(scheme.get, call_595640.host, call_595640.base,
                         call_595640.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595640, url, valid)

proc call*(call_595641: Call_GetUpdateEnvironment_595614; TierName: string = "";
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
  var query_595642 = newJObject()
  add(query_595642, "Tier.Name", newJString(TierName))
  add(query_595642, "VersionLabel", newJString(VersionLabel))
  add(query_595642, "ApplicationName", newJString(ApplicationName))
  add(query_595642, "Description", newJString(Description))
  if OptionsToRemove != nil:
    query_595642.add "OptionsToRemove", OptionsToRemove
  add(query_595642, "PlatformArn", newJString(PlatformArn))
  add(query_595642, "EnvironmentName", newJString(EnvironmentName))
  add(query_595642, "Action", newJString(Action))
  add(query_595642, "EnvironmentId", newJString(EnvironmentId))
  add(query_595642, "Tier.Version", newJString(TierVersion))
  add(query_595642, "SolutionStackName", newJString(SolutionStackName))
  add(query_595642, "TemplateName", newJString(TemplateName))
  add(query_595642, "GroupName", newJString(GroupName))
  if OptionSettings != nil:
    query_595642.add "OptionSettings", OptionSettings
  add(query_595642, "Tier.Type", newJString(TierType))
  add(query_595642, "Version", newJString(Version))
  result = call_595641.call(nil, query_595642, nil, nil, nil)

var getUpdateEnvironment* = Call_GetUpdateEnvironment_595614(
    name: "getUpdateEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateEnvironment",
    validator: validate_GetUpdateEnvironment_595615, base: "/",
    url: url_GetUpdateEnvironment_595616, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateTagsForResource_595691 = ref object of OpenApiRestCall_593438
proc url_PostUpdateTagsForResource_595693(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateTagsForResource_595692(path: JsonNode; query: JsonNode;
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
  var valid_595694 = query.getOrDefault("Action")
  valid_595694 = validateParameter(valid_595694, JString, required = true,
                                 default = newJString("UpdateTagsForResource"))
  if valid_595694 != nil:
    section.add "Action", valid_595694
  var valid_595695 = query.getOrDefault("Version")
  valid_595695 = validateParameter(valid_595695, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_595695 != nil:
    section.add "Version", valid_595695
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595696 = header.getOrDefault("X-Amz-Date")
  valid_595696 = validateParameter(valid_595696, JString, required = false,
                                 default = nil)
  if valid_595696 != nil:
    section.add "X-Amz-Date", valid_595696
  var valid_595697 = header.getOrDefault("X-Amz-Security-Token")
  valid_595697 = validateParameter(valid_595697, JString, required = false,
                                 default = nil)
  if valid_595697 != nil:
    section.add "X-Amz-Security-Token", valid_595697
  var valid_595698 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595698 = validateParameter(valid_595698, JString, required = false,
                                 default = nil)
  if valid_595698 != nil:
    section.add "X-Amz-Content-Sha256", valid_595698
  var valid_595699 = header.getOrDefault("X-Amz-Algorithm")
  valid_595699 = validateParameter(valid_595699, JString, required = false,
                                 default = nil)
  if valid_595699 != nil:
    section.add "X-Amz-Algorithm", valid_595699
  var valid_595700 = header.getOrDefault("X-Amz-Signature")
  valid_595700 = validateParameter(valid_595700, JString, required = false,
                                 default = nil)
  if valid_595700 != nil:
    section.add "X-Amz-Signature", valid_595700
  var valid_595701 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595701 = validateParameter(valid_595701, JString, required = false,
                                 default = nil)
  if valid_595701 != nil:
    section.add "X-Amz-SignedHeaders", valid_595701
  var valid_595702 = header.getOrDefault("X-Amz-Credential")
  valid_595702 = validateParameter(valid_595702, JString, required = false,
                                 default = nil)
  if valid_595702 != nil:
    section.add "X-Amz-Credential", valid_595702
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagsToAdd: JArray
  ##            : <p>A list of tags to add or update.</p> <p>If a key of an existing tag is added, the tag's value is updated.</p>
  ##   TagsToRemove: JArray
  ##               : <p>A list of tag keys to remove.</p> <p>If a tag key doesn't exist, it is silently ignored.</p>
  ##   ResourceArn: JString (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce to be updated.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  section = newJObject()
  var valid_595703 = formData.getOrDefault("TagsToAdd")
  valid_595703 = validateParameter(valid_595703, JArray, required = false,
                                 default = nil)
  if valid_595703 != nil:
    section.add "TagsToAdd", valid_595703
  var valid_595704 = formData.getOrDefault("TagsToRemove")
  valid_595704 = validateParameter(valid_595704, JArray, required = false,
                                 default = nil)
  if valid_595704 != nil:
    section.add "TagsToRemove", valid_595704
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArn` field"
  var valid_595705 = formData.getOrDefault("ResourceArn")
  valid_595705 = validateParameter(valid_595705, JString, required = true,
                                 default = nil)
  if valid_595705 != nil:
    section.add "ResourceArn", valid_595705
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595706: Call_PostUpdateTagsForResource_595691; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Update the list of tags applied to an AWS Elastic Beanstalk resource. Two lists can be passed: <code>TagsToAdd</code> for tags to add or update, and <code>TagsToRemove</code>.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p> <p>If you create a custom IAM user policy to control permission to this operation, specify one of the following two virtual actions (or both) instead of the API operation name:</p> <dl> <dt>elasticbeanstalk:AddTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tags to add in the <code>TagsToAdd</code> parameter.</p> </dd> <dt>elasticbeanstalk:RemoveTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tag keys to remove in the <code>TagsToRemove</code> parameter.</p> </dd> </dl> <p>For details about creating a custom user policy, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/AWSHowTo.iam.managed-policies.html#AWSHowTo.iam.policies">Creating a Custom User Policy</a>.</p>
  ## 
  let valid = call_595706.validator(path, query, header, formData, body)
  let scheme = call_595706.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595706.url(scheme.get, call_595706.host, call_595706.base,
                         call_595706.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595706, url, valid)

proc call*(call_595707: Call_PostUpdateTagsForResource_595691; ResourceArn: string;
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
  var query_595708 = newJObject()
  var formData_595709 = newJObject()
  if TagsToAdd != nil:
    formData_595709.add "TagsToAdd", TagsToAdd
  if TagsToRemove != nil:
    formData_595709.add "TagsToRemove", TagsToRemove
  add(query_595708, "Action", newJString(Action))
  add(formData_595709, "ResourceArn", newJString(ResourceArn))
  add(query_595708, "Version", newJString(Version))
  result = call_595707.call(nil, query_595708, nil, formData_595709, nil)

var postUpdateTagsForResource* = Call_PostUpdateTagsForResource_595691(
    name: "postUpdateTagsForResource", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateTagsForResource",
    validator: validate_PostUpdateTagsForResource_595692, base: "/",
    url: url_PostUpdateTagsForResource_595693,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateTagsForResource_595673 = ref object of OpenApiRestCall_593438
proc url_GetUpdateTagsForResource_595675(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateTagsForResource_595674(path: JsonNode; query: JsonNode;
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
  var valid_595676 = query.getOrDefault("ResourceArn")
  valid_595676 = validateParameter(valid_595676, JString, required = true,
                                 default = nil)
  if valid_595676 != nil:
    section.add "ResourceArn", valid_595676
  var valid_595677 = query.getOrDefault("Action")
  valid_595677 = validateParameter(valid_595677, JString, required = true,
                                 default = newJString("UpdateTagsForResource"))
  if valid_595677 != nil:
    section.add "Action", valid_595677
  var valid_595678 = query.getOrDefault("TagsToAdd")
  valid_595678 = validateParameter(valid_595678, JArray, required = false,
                                 default = nil)
  if valid_595678 != nil:
    section.add "TagsToAdd", valid_595678
  var valid_595679 = query.getOrDefault("Version")
  valid_595679 = validateParameter(valid_595679, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_595679 != nil:
    section.add "Version", valid_595679
  var valid_595680 = query.getOrDefault("TagsToRemove")
  valid_595680 = validateParameter(valid_595680, JArray, required = false,
                                 default = nil)
  if valid_595680 != nil:
    section.add "TagsToRemove", valid_595680
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595681 = header.getOrDefault("X-Amz-Date")
  valid_595681 = validateParameter(valid_595681, JString, required = false,
                                 default = nil)
  if valid_595681 != nil:
    section.add "X-Amz-Date", valid_595681
  var valid_595682 = header.getOrDefault("X-Amz-Security-Token")
  valid_595682 = validateParameter(valid_595682, JString, required = false,
                                 default = nil)
  if valid_595682 != nil:
    section.add "X-Amz-Security-Token", valid_595682
  var valid_595683 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595683 = validateParameter(valid_595683, JString, required = false,
                                 default = nil)
  if valid_595683 != nil:
    section.add "X-Amz-Content-Sha256", valid_595683
  var valid_595684 = header.getOrDefault("X-Amz-Algorithm")
  valid_595684 = validateParameter(valid_595684, JString, required = false,
                                 default = nil)
  if valid_595684 != nil:
    section.add "X-Amz-Algorithm", valid_595684
  var valid_595685 = header.getOrDefault("X-Amz-Signature")
  valid_595685 = validateParameter(valid_595685, JString, required = false,
                                 default = nil)
  if valid_595685 != nil:
    section.add "X-Amz-Signature", valid_595685
  var valid_595686 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595686 = validateParameter(valid_595686, JString, required = false,
                                 default = nil)
  if valid_595686 != nil:
    section.add "X-Amz-SignedHeaders", valid_595686
  var valid_595687 = header.getOrDefault("X-Amz-Credential")
  valid_595687 = validateParameter(valid_595687, JString, required = false,
                                 default = nil)
  if valid_595687 != nil:
    section.add "X-Amz-Credential", valid_595687
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595688: Call_GetUpdateTagsForResource_595673; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Update the list of tags applied to an AWS Elastic Beanstalk resource. Two lists can be passed: <code>TagsToAdd</code> for tags to add or update, and <code>TagsToRemove</code>.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p> <p>If you create a custom IAM user policy to control permission to this operation, specify one of the following two virtual actions (or both) instead of the API operation name:</p> <dl> <dt>elasticbeanstalk:AddTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tags to add in the <code>TagsToAdd</code> parameter.</p> </dd> <dt>elasticbeanstalk:RemoveTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tag keys to remove in the <code>TagsToRemove</code> parameter.</p> </dd> </dl> <p>For details about creating a custom user policy, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/AWSHowTo.iam.managed-policies.html#AWSHowTo.iam.policies">Creating a Custom User Policy</a>.</p>
  ## 
  let valid = call_595688.validator(path, query, header, formData, body)
  let scheme = call_595688.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595688.url(scheme.get, call_595688.host, call_595688.base,
                         call_595688.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595688, url, valid)

proc call*(call_595689: Call_GetUpdateTagsForResource_595673; ResourceArn: string;
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
  var query_595690 = newJObject()
  add(query_595690, "ResourceArn", newJString(ResourceArn))
  add(query_595690, "Action", newJString(Action))
  if TagsToAdd != nil:
    query_595690.add "TagsToAdd", TagsToAdd
  add(query_595690, "Version", newJString(Version))
  if TagsToRemove != nil:
    query_595690.add "TagsToRemove", TagsToRemove
  result = call_595689.call(nil, query_595690, nil, nil, nil)

var getUpdateTagsForResource* = Call_GetUpdateTagsForResource_595673(
    name: "getUpdateTagsForResource", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateTagsForResource",
    validator: validate_GetUpdateTagsForResource_595674, base: "/",
    url: url_GetUpdateTagsForResource_595675, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostValidateConfigurationSettings_595729 = ref object of OpenApiRestCall_593438
proc url_PostValidateConfigurationSettings_595731(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostValidateConfigurationSettings_595730(path: JsonNode;
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
  var valid_595732 = query.getOrDefault("Action")
  valid_595732 = validateParameter(valid_595732, JString, required = true, default = newJString(
      "ValidateConfigurationSettings"))
  if valid_595732 != nil:
    section.add "Action", valid_595732
  var valid_595733 = query.getOrDefault("Version")
  valid_595733 = validateParameter(valid_595733, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_595733 != nil:
    section.add "Version", valid_595733
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595734 = header.getOrDefault("X-Amz-Date")
  valid_595734 = validateParameter(valid_595734, JString, required = false,
                                 default = nil)
  if valid_595734 != nil:
    section.add "X-Amz-Date", valid_595734
  var valid_595735 = header.getOrDefault("X-Amz-Security-Token")
  valid_595735 = validateParameter(valid_595735, JString, required = false,
                                 default = nil)
  if valid_595735 != nil:
    section.add "X-Amz-Security-Token", valid_595735
  var valid_595736 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595736 = validateParameter(valid_595736, JString, required = false,
                                 default = nil)
  if valid_595736 != nil:
    section.add "X-Amz-Content-Sha256", valid_595736
  var valid_595737 = header.getOrDefault("X-Amz-Algorithm")
  valid_595737 = validateParameter(valid_595737, JString, required = false,
                                 default = nil)
  if valid_595737 != nil:
    section.add "X-Amz-Algorithm", valid_595737
  var valid_595738 = header.getOrDefault("X-Amz-Signature")
  valid_595738 = validateParameter(valid_595738, JString, required = false,
                                 default = nil)
  if valid_595738 != nil:
    section.add "X-Amz-Signature", valid_595738
  var valid_595739 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595739 = validateParameter(valid_595739, JString, required = false,
                                 default = nil)
  if valid_595739 != nil:
    section.add "X-Amz-SignedHeaders", valid_595739
  var valid_595740 = header.getOrDefault("X-Amz-Credential")
  valid_595740 = validateParameter(valid_595740, JString, required = false,
                                 default = nil)
  if valid_595740 != nil:
    section.add "X-Amz-Credential", valid_595740
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
  var valid_595741 = formData.getOrDefault("OptionSettings")
  valid_595741 = validateParameter(valid_595741, JArray, required = true, default = nil)
  if valid_595741 != nil:
    section.add "OptionSettings", valid_595741
  var valid_595742 = formData.getOrDefault("EnvironmentName")
  valid_595742 = validateParameter(valid_595742, JString, required = false,
                                 default = nil)
  if valid_595742 != nil:
    section.add "EnvironmentName", valid_595742
  var valid_595743 = formData.getOrDefault("ApplicationName")
  valid_595743 = validateParameter(valid_595743, JString, required = true,
                                 default = nil)
  if valid_595743 != nil:
    section.add "ApplicationName", valid_595743
  var valid_595744 = formData.getOrDefault("TemplateName")
  valid_595744 = validateParameter(valid_595744, JString, required = false,
                                 default = nil)
  if valid_595744 != nil:
    section.add "TemplateName", valid_595744
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595745: Call_PostValidateConfigurationSettings_595729;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Takes a set of configuration settings and either a configuration template or environment, and determines whether those values are valid.</p> <p>This action returns a list of messages indicating any errors or warnings associated with the selection of option values.</p>
  ## 
  let valid = call_595745.validator(path, query, header, formData, body)
  let scheme = call_595745.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595745.url(scheme.get, call_595745.host, call_595745.base,
                         call_595745.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595745, url, valid)

proc call*(call_595746: Call_PostValidateConfigurationSettings_595729;
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
  var query_595747 = newJObject()
  var formData_595748 = newJObject()
  if OptionSettings != nil:
    formData_595748.add "OptionSettings", OptionSettings
  add(formData_595748, "EnvironmentName", newJString(EnvironmentName))
  add(query_595747, "Action", newJString(Action))
  add(formData_595748, "ApplicationName", newJString(ApplicationName))
  add(formData_595748, "TemplateName", newJString(TemplateName))
  add(query_595747, "Version", newJString(Version))
  result = call_595746.call(nil, query_595747, nil, formData_595748, nil)

var postValidateConfigurationSettings* = Call_PostValidateConfigurationSettings_595729(
    name: "postValidateConfigurationSettings", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ValidateConfigurationSettings",
    validator: validate_PostValidateConfigurationSettings_595730, base: "/",
    url: url_PostValidateConfigurationSettings_595731,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetValidateConfigurationSettings_595710 = ref object of OpenApiRestCall_593438
proc url_GetValidateConfigurationSettings_595712(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetValidateConfigurationSettings_595711(path: JsonNode;
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
  var valid_595713 = query.getOrDefault("ApplicationName")
  valid_595713 = validateParameter(valid_595713, JString, required = true,
                                 default = nil)
  if valid_595713 != nil:
    section.add "ApplicationName", valid_595713
  var valid_595714 = query.getOrDefault("EnvironmentName")
  valid_595714 = validateParameter(valid_595714, JString, required = false,
                                 default = nil)
  if valid_595714 != nil:
    section.add "EnvironmentName", valid_595714
  var valid_595715 = query.getOrDefault("Action")
  valid_595715 = validateParameter(valid_595715, JString, required = true, default = newJString(
      "ValidateConfigurationSettings"))
  if valid_595715 != nil:
    section.add "Action", valid_595715
  var valid_595716 = query.getOrDefault("TemplateName")
  valid_595716 = validateParameter(valid_595716, JString, required = false,
                                 default = nil)
  if valid_595716 != nil:
    section.add "TemplateName", valid_595716
  var valid_595717 = query.getOrDefault("OptionSettings")
  valid_595717 = validateParameter(valid_595717, JArray, required = true, default = nil)
  if valid_595717 != nil:
    section.add "OptionSettings", valid_595717
  var valid_595718 = query.getOrDefault("Version")
  valid_595718 = validateParameter(valid_595718, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_595718 != nil:
    section.add "Version", valid_595718
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_595719 = header.getOrDefault("X-Amz-Date")
  valid_595719 = validateParameter(valid_595719, JString, required = false,
                                 default = nil)
  if valid_595719 != nil:
    section.add "X-Amz-Date", valid_595719
  var valid_595720 = header.getOrDefault("X-Amz-Security-Token")
  valid_595720 = validateParameter(valid_595720, JString, required = false,
                                 default = nil)
  if valid_595720 != nil:
    section.add "X-Amz-Security-Token", valid_595720
  var valid_595721 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_595721 = validateParameter(valid_595721, JString, required = false,
                                 default = nil)
  if valid_595721 != nil:
    section.add "X-Amz-Content-Sha256", valid_595721
  var valid_595722 = header.getOrDefault("X-Amz-Algorithm")
  valid_595722 = validateParameter(valid_595722, JString, required = false,
                                 default = nil)
  if valid_595722 != nil:
    section.add "X-Amz-Algorithm", valid_595722
  var valid_595723 = header.getOrDefault("X-Amz-Signature")
  valid_595723 = validateParameter(valid_595723, JString, required = false,
                                 default = nil)
  if valid_595723 != nil:
    section.add "X-Amz-Signature", valid_595723
  var valid_595724 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_595724 = validateParameter(valid_595724, JString, required = false,
                                 default = nil)
  if valid_595724 != nil:
    section.add "X-Amz-SignedHeaders", valid_595724
  var valid_595725 = header.getOrDefault("X-Amz-Credential")
  valid_595725 = validateParameter(valid_595725, JString, required = false,
                                 default = nil)
  if valid_595725 != nil:
    section.add "X-Amz-Credential", valid_595725
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_595726: Call_GetValidateConfigurationSettings_595710;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Takes a set of configuration settings and either a configuration template or environment, and determines whether those values are valid.</p> <p>This action returns a list of messages indicating any errors or warnings associated with the selection of option values.</p>
  ## 
  let valid = call_595726.validator(path, query, header, formData, body)
  let scheme = call_595726.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_595726.url(scheme.get, call_595726.host, call_595726.base,
                         call_595726.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_595726, url, valid)

proc call*(call_595727: Call_GetValidateConfigurationSettings_595710;
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
  var query_595728 = newJObject()
  add(query_595728, "ApplicationName", newJString(ApplicationName))
  add(query_595728, "EnvironmentName", newJString(EnvironmentName))
  add(query_595728, "Action", newJString(Action))
  add(query_595728, "TemplateName", newJString(TemplateName))
  if OptionSettings != nil:
    query_595728.add "OptionSettings", OptionSettings
  add(query_595728, "Version", newJString(Version))
  result = call_595727.call(nil, query_595728, nil, nil, nil)

var getValidateConfigurationSettings* = Call_GetValidateConfigurationSettings_595710(
    name: "getValidateConfigurationSettings", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ValidateConfigurationSettings",
    validator: validate_GetValidateConfigurationSettings_595711, base: "/",
    url: url_GetValidateConfigurationSettings_595712,
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


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

  OpenApiRestCall_599369 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599369](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599369): Option[Scheme] {.used.} =
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
  Call_PostAbortEnvironmentUpdate_599978 = ref object of OpenApiRestCall_599369
proc url_PostAbortEnvironmentUpdate_599980(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostAbortEnvironmentUpdate_599979(path: JsonNode; query: JsonNode;
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
  var valid_599981 = query.getOrDefault("Action")
  valid_599981 = validateParameter(valid_599981, JString, required = true,
                                 default = newJString("AbortEnvironmentUpdate"))
  if valid_599981 != nil:
    section.add "Action", valid_599981
  var valid_599982 = query.getOrDefault("Version")
  valid_599982 = validateParameter(valid_599982, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_599982 != nil:
    section.add "Version", valid_599982
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599983 = header.getOrDefault("X-Amz-Date")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-Date", valid_599983
  var valid_599984 = header.getOrDefault("X-Amz-Security-Token")
  valid_599984 = validateParameter(valid_599984, JString, required = false,
                                 default = nil)
  if valid_599984 != nil:
    section.add "X-Amz-Security-Token", valid_599984
  var valid_599985 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599985 = validateParameter(valid_599985, JString, required = false,
                                 default = nil)
  if valid_599985 != nil:
    section.add "X-Amz-Content-Sha256", valid_599985
  var valid_599986 = header.getOrDefault("X-Amz-Algorithm")
  valid_599986 = validateParameter(valid_599986, JString, required = false,
                                 default = nil)
  if valid_599986 != nil:
    section.add "X-Amz-Algorithm", valid_599986
  var valid_599987 = header.getOrDefault("X-Amz-Signature")
  valid_599987 = validateParameter(valid_599987, JString, required = false,
                                 default = nil)
  if valid_599987 != nil:
    section.add "X-Amz-Signature", valid_599987
  var valid_599988 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599988 = validateParameter(valid_599988, JString, required = false,
                                 default = nil)
  if valid_599988 != nil:
    section.add "X-Amz-SignedHeaders", valid_599988
  var valid_599989 = header.getOrDefault("X-Amz-Credential")
  valid_599989 = validateParameter(valid_599989, JString, required = false,
                                 default = nil)
  if valid_599989 != nil:
    section.add "X-Amz-Credential", valid_599989
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentId: JString
  ##                : This specifies the ID of the environment with the in-progress update that you want to cancel.
  ##   EnvironmentName: JString
  ##                  : This specifies the name of the environment with the in-progress update that you want to cancel.
  section = newJObject()
  var valid_599990 = formData.getOrDefault("EnvironmentId")
  valid_599990 = validateParameter(valid_599990, JString, required = false,
                                 default = nil)
  if valid_599990 != nil:
    section.add "EnvironmentId", valid_599990
  var valid_599991 = formData.getOrDefault("EnvironmentName")
  valid_599991 = validateParameter(valid_599991, JString, required = false,
                                 default = nil)
  if valid_599991 != nil:
    section.add "EnvironmentName", valid_599991
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599992: Call_PostAbortEnvironmentUpdate_599978; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels in-progress environment configuration update or application version deployment.
  ## 
  let valid = call_599992.validator(path, query, header, formData, body)
  let scheme = call_599992.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599992.url(scheme.get, call_599992.host, call_599992.base,
                         call_599992.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599992, url, valid)

proc call*(call_599993: Call_PostAbortEnvironmentUpdate_599978;
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
  var query_599994 = newJObject()
  var formData_599995 = newJObject()
  add(formData_599995, "EnvironmentId", newJString(EnvironmentId))
  add(formData_599995, "EnvironmentName", newJString(EnvironmentName))
  add(query_599994, "Action", newJString(Action))
  add(query_599994, "Version", newJString(Version))
  result = call_599993.call(nil, query_599994, nil, formData_599995, nil)

var postAbortEnvironmentUpdate* = Call_PostAbortEnvironmentUpdate_599978(
    name: "postAbortEnvironmentUpdate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=AbortEnvironmentUpdate",
    validator: validate_PostAbortEnvironmentUpdate_599979, base: "/",
    url: url_PostAbortEnvironmentUpdate_599980,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAbortEnvironmentUpdate_599706 = ref object of OpenApiRestCall_599369
proc url_GetAbortEnvironmentUpdate_599708(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAbortEnvironmentUpdate_599707(path: JsonNode; query: JsonNode;
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
  var valid_599820 = query.getOrDefault("EnvironmentName")
  valid_599820 = validateParameter(valid_599820, JString, required = false,
                                 default = nil)
  if valid_599820 != nil:
    section.add "EnvironmentName", valid_599820
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_599834 = query.getOrDefault("Action")
  valid_599834 = validateParameter(valid_599834, JString, required = true,
                                 default = newJString("AbortEnvironmentUpdate"))
  if valid_599834 != nil:
    section.add "Action", valid_599834
  var valid_599835 = query.getOrDefault("EnvironmentId")
  valid_599835 = validateParameter(valid_599835, JString, required = false,
                                 default = nil)
  if valid_599835 != nil:
    section.add "EnvironmentId", valid_599835
  var valid_599836 = query.getOrDefault("Version")
  valid_599836 = validateParameter(valid_599836, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_599836 != nil:
    section.add "Version", valid_599836
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599837 = header.getOrDefault("X-Amz-Date")
  valid_599837 = validateParameter(valid_599837, JString, required = false,
                                 default = nil)
  if valid_599837 != nil:
    section.add "X-Amz-Date", valid_599837
  var valid_599838 = header.getOrDefault("X-Amz-Security-Token")
  valid_599838 = validateParameter(valid_599838, JString, required = false,
                                 default = nil)
  if valid_599838 != nil:
    section.add "X-Amz-Security-Token", valid_599838
  var valid_599839 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599839 = validateParameter(valid_599839, JString, required = false,
                                 default = nil)
  if valid_599839 != nil:
    section.add "X-Amz-Content-Sha256", valid_599839
  var valid_599840 = header.getOrDefault("X-Amz-Algorithm")
  valid_599840 = validateParameter(valid_599840, JString, required = false,
                                 default = nil)
  if valid_599840 != nil:
    section.add "X-Amz-Algorithm", valid_599840
  var valid_599841 = header.getOrDefault("X-Amz-Signature")
  valid_599841 = validateParameter(valid_599841, JString, required = false,
                                 default = nil)
  if valid_599841 != nil:
    section.add "X-Amz-Signature", valid_599841
  var valid_599842 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599842 = validateParameter(valid_599842, JString, required = false,
                                 default = nil)
  if valid_599842 != nil:
    section.add "X-Amz-SignedHeaders", valid_599842
  var valid_599843 = header.getOrDefault("X-Amz-Credential")
  valid_599843 = validateParameter(valid_599843, JString, required = false,
                                 default = nil)
  if valid_599843 != nil:
    section.add "X-Amz-Credential", valid_599843
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599866: Call_GetAbortEnvironmentUpdate_599706; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels in-progress environment configuration update or application version deployment.
  ## 
  let valid = call_599866.validator(path, query, header, formData, body)
  let scheme = call_599866.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599866.url(scheme.get, call_599866.host, call_599866.base,
                         call_599866.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599866, url, valid)

proc call*(call_599937: Call_GetAbortEnvironmentUpdate_599706;
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
  var query_599938 = newJObject()
  add(query_599938, "EnvironmentName", newJString(EnvironmentName))
  add(query_599938, "Action", newJString(Action))
  add(query_599938, "EnvironmentId", newJString(EnvironmentId))
  add(query_599938, "Version", newJString(Version))
  result = call_599937.call(nil, query_599938, nil, nil, nil)

var getAbortEnvironmentUpdate* = Call_GetAbortEnvironmentUpdate_599706(
    name: "getAbortEnvironmentUpdate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=AbortEnvironmentUpdate",
    validator: validate_GetAbortEnvironmentUpdate_599707, base: "/",
    url: url_GetAbortEnvironmentUpdate_599708,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostApplyEnvironmentManagedAction_600014 = ref object of OpenApiRestCall_599369
proc url_PostApplyEnvironmentManagedAction_600016(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostApplyEnvironmentManagedAction_600015(path: JsonNode;
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
  var valid_600017 = query.getOrDefault("Action")
  valid_600017 = validateParameter(valid_600017, JString, required = true, default = newJString(
      "ApplyEnvironmentManagedAction"))
  if valid_600017 != nil:
    section.add "Action", valid_600017
  var valid_600018 = query.getOrDefault("Version")
  valid_600018 = validateParameter(valid_600018, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600018 != nil:
    section.add "Version", valid_600018
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600019 = header.getOrDefault("X-Amz-Date")
  valid_600019 = validateParameter(valid_600019, JString, required = false,
                                 default = nil)
  if valid_600019 != nil:
    section.add "X-Amz-Date", valid_600019
  var valid_600020 = header.getOrDefault("X-Amz-Security-Token")
  valid_600020 = validateParameter(valid_600020, JString, required = false,
                                 default = nil)
  if valid_600020 != nil:
    section.add "X-Amz-Security-Token", valid_600020
  var valid_600021 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600021 = validateParameter(valid_600021, JString, required = false,
                                 default = nil)
  if valid_600021 != nil:
    section.add "X-Amz-Content-Sha256", valid_600021
  var valid_600022 = header.getOrDefault("X-Amz-Algorithm")
  valid_600022 = validateParameter(valid_600022, JString, required = false,
                                 default = nil)
  if valid_600022 != nil:
    section.add "X-Amz-Algorithm", valid_600022
  var valid_600023 = header.getOrDefault("X-Amz-Signature")
  valid_600023 = validateParameter(valid_600023, JString, required = false,
                                 default = nil)
  if valid_600023 != nil:
    section.add "X-Amz-Signature", valid_600023
  var valid_600024 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600024 = validateParameter(valid_600024, JString, required = false,
                                 default = nil)
  if valid_600024 != nil:
    section.add "X-Amz-SignedHeaders", valid_600024
  var valid_600025 = header.getOrDefault("X-Amz-Credential")
  valid_600025 = validateParameter(valid_600025, JString, required = false,
                                 default = nil)
  if valid_600025 != nil:
    section.add "X-Amz-Credential", valid_600025
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentId: JString
  ##                : The environment ID of the target environment.
  ##   EnvironmentName: JString
  ##                  : The name of the target environment.
  ##   ActionId: JString (required)
  ##           : The action ID of the scheduled managed action to execute.
  section = newJObject()
  var valid_600026 = formData.getOrDefault("EnvironmentId")
  valid_600026 = validateParameter(valid_600026, JString, required = false,
                                 default = nil)
  if valid_600026 != nil:
    section.add "EnvironmentId", valid_600026
  var valid_600027 = formData.getOrDefault("EnvironmentName")
  valid_600027 = validateParameter(valid_600027, JString, required = false,
                                 default = nil)
  if valid_600027 != nil:
    section.add "EnvironmentName", valid_600027
  assert formData != nil,
        "formData argument is necessary due to required `ActionId` field"
  var valid_600028 = formData.getOrDefault("ActionId")
  valid_600028 = validateParameter(valid_600028, JString, required = true,
                                 default = nil)
  if valid_600028 != nil:
    section.add "ActionId", valid_600028
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600029: Call_PostApplyEnvironmentManagedAction_600014;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Applies a scheduled managed action immediately. A managed action can be applied only if its status is <code>Scheduled</code>. Get the status and action ID of a managed action with <a>DescribeEnvironmentManagedActions</a>.
  ## 
  let valid = call_600029.validator(path, query, header, formData, body)
  let scheme = call_600029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600029.url(scheme.get, call_600029.host, call_600029.base,
                         call_600029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600029, url, valid)

proc call*(call_600030: Call_PostApplyEnvironmentManagedAction_600014;
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
  var query_600031 = newJObject()
  var formData_600032 = newJObject()
  add(formData_600032, "EnvironmentId", newJString(EnvironmentId))
  add(formData_600032, "EnvironmentName", newJString(EnvironmentName))
  add(query_600031, "Action", newJString(Action))
  add(formData_600032, "ActionId", newJString(ActionId))
  add(query_600031, "Version", newJString(Version))
  result = call_600030.call(nil, query_600031, nil, formData_600032, nil)

var postApplyEnvironmentManagedAction* = Call_PostApplyEnvironmentManagedAction_600014(
    name: "postApplyEnvironmentManagedAction", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ApplyEnvironmentManagedAction",
    validator: validate_PostApplyEnvironmentManagedAction_600015, base: "/",
    url: url_PostApplyEnvironmentManagedAction_600016,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplyEnvironmentManagedAction_599996 = ref object of OpenApiRestCall_599369
proc url_GetApplyEnvironmentManagedAction_599998(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetApplyEnvironmentManagedAction_599997(path: JsonNode;
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
  var valid_599999 = query.getOrDefault("EnvironmentName")
  valid_599999 = validateParameter(valid_599999, JString, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "EnvironmentName", valid_599999
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600000 = query.getOrDefault("Action")
  valid_600000 = validateParameter(valid_600000, JString, required = true, default = newJString(
      "ApplyEnvironmentManagedAction"))
  if valid_600000 != nil:
    section.add "Action", valid_600000
  var valid_600001 = query.getOrDefault("EnvironmentId")
  valid_600001 = validateParameter(valid_600001, JString, required = false,
                                 default = nil)
  if valid_600001 != nil:
    section.add "EnvironmentId", valid_600001
  var valid_600002 = query.getOrDefault("ActionId")
  valid_600002 = validateParameter(valid_600002, JString, required = true,
                                 default = nil)
  if valid_600002 != nil:
    section.add "ActionId", valid_600002
  var valid_600003 = query.getOrDefault("Version")
  valid_600003 = validateParameter(valid_600003, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600003 != nil:
    section.add "Version", valid_600003
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600004 = header.getOrDefault("X-Amz-Date")
  valid_600004 = validateParameter(valid_600004, JString, required = false,
                                 default = nil)
  if valid_600004 != nil:
    section.add "X-Amz-Date", valid_600004
  var valid_600005 = header.getOrDefault("X-Amz-Security-Token")
  valid_600005 = validateParameter(valid_600005, JString, required = false,
                                 default = nil)
  if valid_600005 != nil:
    section.add "X-Amz-Security-Token", valid_600005
  var valid_600006 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600006 = validateParameter(valid_600006, JString, required = false,
                                 default = nil)
  if valid_600006 != nil:
    section.add "X-Amz-Content-Sha256", valid_600006
  var valid_600007 = header.getOrDefault("X-Amz-Algorithm")
  valid_600007 = validateParameter(valid_600007, JString, required = false,
                                 default = nil)
  if valid_600007 != nil:
    section.add "X-Amz-Algorithm", valid_600007
  var valid_600008 = header.getOrDefault("X-Amz-Signature")
  valid_600008 = validateParameter(valid_600008, JString, required = false,
                                 default = nil)
  if valid_600008 != nil:
    section.add "X-Amz-Signature", valid_600008
  var valid_600009 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600009 = validateParameter(valid_600009, JString, required = false,
                                 default = nil)
  if valid_600009 != nil:
    section.add "X-Amz-SignedHeaders", valid_600009
  var valid_600010 = header.getOrDefault("X-Amz-Credential")
  valid_600010 = validateParameter(valid_600010, JString, required = false,
                                 default = nil)
  if valid_600010 != nil:
    section.add "X-Amz-Credential", valid_600010
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600011: Call_GetApplyEnvironmentManagedAction_599996;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Applies a scheduled managed action immediately. A managed action can be applied only if its status is <code>Scheduled</code>. Get the status and action ID of a managed action with <a>DescribeEnvironmentManagedActions</a>.
  ## 
  let valid = call_600011.validator(path, query, header, formData, body)
  let scheme = call_600011.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600011.url(scheme.get, call_600011.host, call_600011.base,
                         call_600011.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600011, url, valid)

proc call*(call_600012: Call_GetApplyEnvironmentManagedAction_599996;
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
  var query_600013 = newJObject()
  add(query_600013, "EnvironmentName", newJString(EnvironmentName))
  add(query_600013, "Action", newJString(Action))
  add(query_600013, "EnvironmentId", newJString(EnvironmentId))
  add(query_600013, "ActionId", newJString(ActionId))
  add(query_600013, "Version", newJString(Version))
  result = call_600012.call(nil, query_600013, nil, nil, nil)

var getApplyEnvironmentManagedAction* = Call_GetApplyEnvironmentManagedAction_599996(
    name: "getApplyEnvironmentManagedAction", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ApplyEnvironmentManagedAction",
    validator: validate_GetApplyEnvironmentManagedAction_599997, base: "/",
    url: url_GetApplyEnvironmentManagedAction_599998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCheckDNSAvailability_600049 = ref object of OpenApiRestCall_599369
proc url_PostCheckDNSAvailability_600051(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCheckDNSAvailability_600050(path: JsonNode; query: JsonNode;
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
  var valid_600052 = query.getOrDefault("Action")
  valid_600052 = validateParameter(valid_600052, JString, required = true,
                                 default = newJString("CheckDNSAvailability"))
  if valid_600052 != nil:
    section.add "Action", valid_600052
  var valid_600053 = query.getOrDefault("Version")
  valid_600053 = validateParameter(valid_600053, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600053 != nil:
    section.add "Version", valid_600053
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600054 = header.getOrDefault("X-Amz-Date")
  valid_600054 = validateParameter(valid_600054, JString, required = false,
                                 default = nil)
  if valid_600054 != nil:
    section.add "X-Amz-Date", valid_600054
  var valid_600055 = header.getOrDefault("X-Amz-Security-Token")
  valid_600055 = validateParameter(valid_600055, JString, required = false,
                                 default = nil)
  if valid_600055 != nil:
    section.add "X-Amz-Security-Token", valid_600055
  var valid_600056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600056 = validateParameter(valid_600056, JString, required = false,
                                 default = nil)
  if valid_600056 != nil:
    section.add "X-Amz-Content-Sha256", valid_600056
  var valid_600057 = header.getOrDefault("X-Amz-Algorithm")
  valid_600057 = validateParameter(valid_600057, JString, required = false,
                                 default = nil)
  if valid_600057 != nil:
    section.add "X-Amz-Algorithm", valid_600057
  var valid_600058 = header.getOrDefault("X-Amz-Signature")
  valid_600058 = validateParameter(valid_600058, JString, required = false,
                                 default = nil)
  if valid_600058 != nil:
    section.add "X-Amz-Signature", valid_600058
  var valid_600059 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600059 = validateParameter(valid_600059, JString, required = false,
                                 default = nil)
  if valid_600059 != nil:
    section.add "X-Amz-SignedHeaders", valid_600059
  var valid_600060 = header.getOrDefault("X-Amz-Credential")
  valid_600060 = validateParameter(valid_600060, JString, required = false,
                                 default = nil)
  if valid_600060 != nil:
    section.add "X-Amz-Credential", valid_600060
  result.add "header", section
  ## parameters in `formData` object:
  ##   CNAMEPrefix: JString (required)
  ##              : The prefix used when this CNAME is reserved.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `CNAMEPrefix` field"
  var valid_600061 = formData.getOrDefault("CNAMEPrefix")
  valid_600061 = validateParameter(valid_600061, JString, required = true,
                                 default = nil)
  if valid_600061 != nil:
    section.add "CNAMEPrefix", valid_600061
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600062: Call_PostCheckDNSAvailability_600049; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Checks if the specified CNAME is available.
  ## 
  let valid = call_600062.validator(path, query, header, formData, body)
  let scheme = call_600062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600062.url(scheme.get, call_600062.host, call_600062.base,
                         call_600062.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600062, url, valid)

proc call*(call_600063: Call_PostCheckDNSAvailability_600049; CNAMEPrefix: string;
          Action: string = "CheckDNSAvailability"; Version: string = "2010-12-01"): Recallable =
  ## postCheckDNSAvailability
  ## Checks if the specified CNAME is available.
  ##   CNAMEPrefix: string (required)
  ##              : The prefix used when this CNAME is reserved.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600064 = newJObject()
  var formData_600065 = newJObject()
  add(formData_600065, "CNAMEPrefix", newJString(CNAMEPrefix))
  add(query_600064, "Action", newJString(Action))
  add(query_600064, "Version", newJString(Version))
  result = call_600063.call(nil, query_600064, nil, formData_600065, nil)

var postCheckDNSAvailability* = Call_PostCheckDNSAvailability_600049(
    name: "postCheckDNSAvailability", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CheckDNSAvailability",
    validator: validate_PostCheckDNSAvailability_600050, base: "/",
    url: url_PostCheckDNSAvailability_600051, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCheckDNSAvailability_600033 = ref object of OpenApiRestCall_599369
proc url_GetCheckDNSAvailability_600035(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCheckDNSAvailability_600034(path: JsonNode; query: JsonNode;
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
  var valid_600036 = query.getOrDefault("Action")
  valid_600036 = validateParameter(valid_600036, JString, required = true,
                                 default = newJString("CheckDNSAvailability"))
  if valid_600036 != nil:
    section.add "Action", valid_600036
  var valid_600037 = query.getOrDefault("Version")
  valid_600037 = validateParameter(valid_600037, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600037 != nil:
    section.add "Version", valid_600037
  var valid_600038 = query.getOrDefault("CNAMEPrefix")
  valid_600038 = validateParameter(valid_600038, JString, required = true,
                                 default = nil)
  if valid_600038 != nil:
    section.add "CNAMEPrefix", valid_600038
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600039 = header.getOrDefault("X-Amz-Date")
  valid_600039 = validateParameter(valid_600039, JString, required = false,
                                 default = nil)
  if valid_600039 != nil:
    section.add "X-Amz-Date", valid_600039
  var valid_600040 = header.getOrDefault("X-Amz-Security-Token")
  valid_600040 = validateParameter(valid_600040, JString, required = false,
                                 default = nil)
  if valid_600040 != nil:
    section.add "X-Amz-Security-Token", valid_600040
  var valid_600041 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600041 = validateParameter(valid_600041, JString, required = false,
                                 default = nil)
  if valid_600041 != nil:
    section.add "X-Amz-Content-Sha256", valid_600041
  var valid_600042 = header.getOrDefault("X-Amz-Algorithm")
  valid_600042 = validateParameter(valid_600042, JString, required = false,
                                 default = nil)
  if valid_600042 != nil:
    section.add "X-Amz-Algorithm", valid_600042
  var valid_600043 = header.getOrDefault("X-Amz-Signature")
  valid_600043 = validateParameter(valid_600043, JString, required = false,
                                 default = nil)
  if valid_600043 != nil:
    section.add "X-Amz-Signature", valid_600043
  var valid_600044 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600044 = validateParameter(valid_600044, JString, required = false,
                                 default = nil)
  if valid_600044 != nil:
    section.add "X-Amz-SignedHeaders", valid_600044
  var valid_600045 = header.getOrDefault("X-Amz-Credential")
  valid_600045 = validateParameter(valid_600045, JString, required = false,
                                 default = nil)
  if valid_600045 != nil:
    section.add "X-Amz-Credential", valid_600045
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600046: Call_GetCheckDNSAvailability_600033; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Checks if the specified CNAME is available.
  ## 
  let valid = call_600046.validator(path, query, header, formData, body)
  let scheme = call_600046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600046.url(scheme.get, call_600046.host, call_600046.base,
                         call_600046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600046, url, valid)

proc call*(call_600047: Call_GetCheckDNSAvailability_600033; CNAMEPrefix: string;
          Action: string = "CheckDNSAvailability"; Version: string = "2010-12-01"): Recallable =
  ## getCheckDNSAvailability
  ## Checks if the specified CNAME is available.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   CNAMEPrefix: string (required)
  ##              : The prefix used when this CNAME is reserved.
  var query_600048 = newJObject()
  add(query_600048, "Action", newJString(Action))
  add(query_600048, "Version", newJString(Version))
  add(query_600048, "CNAMEPrefix", newJString(CNAMEPrefix))
  result = call_600047.call(nil, query_600048, nil, nil, nil)

var getCheckDNSAvailability* = Call_GetCheckDNSAvailability_600033(
    name: "getCheckDNSAvailability", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CheckDNSAvailability",
    validator: validate_GetCheckDNSAvailability_600034, base: "/",
    url: url_GetCheckDNSAvailability_600035, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostComposeEnvironments_600084 = ref object of OpenApiRestCall_599369
proc url_PostComposeEnvironments_600086(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostComposeEnvironments_600085(path: JsonNode; query: JsonNode;
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
  var valid_600087 = query.getOrDefault("Action")
  valid_600087 = validateParameter(valid_600087, JString, required = true,
                                 default = newJString("ComposeEnvironments"))
  if valid_600087 != nil:
    section.add "Action", valid_600087
  var valid_600088 = query.getOrDefault("Version")
  valid_600088 = validateParameter(valid_600088, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600088 != nil:
    section.add "Version", valid_600088
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600089 = header.getOrDefault("X-Amz-Date")
  valid_600089 = validateParameter(valid_600089, JString, required = false,
                                 default = nil)
  if valid_600089 != nil:
    section.add "X-Amz-Date", valid_600089
  var valid_600090 = header.getOrDefault("X-Amz-Security-Token")
  valid_600090 = validateParameter(valid_600090, JString, required = false,
                                 default = nil)
  if valid_600090 != nil:
    section.add "X-Amz-Security-Token", valid_600090
  var valid_600091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600091 = validateParameter(valid_600091, JString, required = false,
                                 default = nil)
  if valid_600091 != nil:
    section.add "X-Amz-Content-Sha256", valid_600091
  var valid_600092 = header.getOrDefault("X-Amz-Algorithm")
  valid_600092 = validateParameter(valid_600092, JString, required = false,
                                 default = nil)
  if valid_600092 != nil:
    section.add "X-Amz-Algorithm", valid_600092
  var valid_600093 = header.getOrDefault("X-Amz-Signature")
  valid_600093 = validateParameter(valid_600093, JString, required = false,
                                 default = nil)
  if valid_600093 != nil:
    section.add "X-Amz-Signature", valid_600093
  var valid_600094 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600094 = validateParameter(valid_600094, JString, required = false,
                                 default = nil)
  if valid_600094 != nil:
    section.add "X-Amz-SignedHeaders", valid_600094
  var valid_600095 = header.getOrDefault("X-Amz-Credential")
  valid_600095 = validateParameter(valid_600095, JString, required = false,
                                 default = nil)
  if valid_600095 != nil:
    section.add "X-Amz-Credential", valid_600095
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
  var valid_600096 = formData.getOrDefault("GroupName")
  valid_600096 = validateParameter(valid_600096, JString, required = false,
                                 default = nil)
  if valid_600096 != nil:
    section.add "GroupName", valid_600096
  var valid_600097 = formData.getOrDefault("ApplicationName")
  valid_600097 = validateParameter(valid_600097, JString, required = false,
                                 default = nil)
  if valid_600097 != nil:
    section.add "ApplicationName", valid_600097
  var valid_600098 = formData.getOrDefault("VersionLabels")
  valid_600098 = validateParameter(valid_600098, JArray, required = false,
                                 default = nil)
  if valid_600098 != nil:
    section.add "VersionLabels", valid_600098
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600099: Call_PostComposeEnvironments_600084; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create or update a group of environments that each run a separate component of a single application. Takes a list of version labels that specify application source bundles for each of the environments to create or update. The name of each environment and other required information must be included in the source bundles in an environment manifest named <code>env.yaml</code>. See <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-mgmt-compose.html">Compose Environments</a> for details.
  ## 
  let valid = call_600099.validator(path, query, header, formData, body)
  let scheme = call_600099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600099.url(scheme.get, call_600099.host, call_600099.base,
                         call_600099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600099, url, valid)

proc call*(call_600100: Call_PostComposeEnvironments_600084;
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
  var query_600101 = newJObject()
  var formData_600102 = newJObject()
  add(formData_600102, "GroupName", newJString(GroupName))
  add(query_600101, "Action", newJString(Action))
  add(formData_600102, "ApplicationName", newJString(ApplicationName))
  add(query_600101, "Version", newJString(Version))
  if VersionLabels != nil:
    formData_600102.add "VersionLabels", VersionLabels
  result = call_600100.call(nil, query_600101, nil, formData_600102, nil)

var postComposeEnvironments* = Call_PostComposeEnvironments_600084(
    name: "postComposeEnvironments", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ComposeEnvironments",
    validator: validate_PostComposeEnvironments_600085, base: "/",
    url: url_PostComposeEnvironments_600086, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetComposeEnvironments_600066 = ref object of OpenApiRestCall_599369
proc url_GetComposeEnvironments_600068(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetComposeEnvironments_600067(path: JsonNode; query: JsonNode;
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
  var valid_600069 = query.getOrDefault("ApplicationName")
  valid_600069 = validateParameter(valid_600069, JString, required = false,
                                 default = nil)
  if valid_600069 != nil:
    section.add "ApplicationName", valid_600069
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600070 = query.getOrDefault("Action")
  valid_600070 = validateParameter(valid_600070, JString, required = true,
                                 default = newJString("ComposeEnvironments"))
  if valid_600070 != nil:
    section.add "Action", valid_600070
  var valid_600071 = query.getOrDefault("GroupName")
  valid_600071 = validateParameter(valid_600071, JString, required = false,
                                 default = nil)
  if valid_600071 != nil:
    section.add "GroupName", valid_600071
  var valid_600072 = query.getOrDefault("VersionLabels")
  valid_600072 = validateParameter(valid_600072, JArray, required = false,
                                 default = nil)
  if valid_600072 != nil:
    section.add "VersionLabels", valid_600072
  var valid_600073 = query.getOrDefault("Version")
  valid_600073 = validateParameter(valid_600073, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600073 != nil:
    section.add "Version", valid_600073
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600074 = header.getOrDefault("X-Amz-Date")
  valid_600074 = validateParameter(valid_600074, JString, required = false,
                                 default = nil)
  if valid_600074 != nil:
    section.add "X-Amz-Date", valid_600074
  var valid_600075 = header.getOrDefault("X-Amz-Security-Token")
  valid_600075 = validateParameter(valid_600075, JString, required = false,
                                 default = nil)
  if valid_600075 != nil:
    section.add "X-Amz-Security-Token", valid_600075
  var valid_600076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600076 = validateParameter(valid_600076, JString, required = false,
                                 default = nil)
  if valid_600076 != nil:
    section.add "X-Amz-Content-Sha256", valid_600076
  var valid_600077 = header.getOrDefault("X-Amz-Algorithm")
  valid_600077 = validateParameter(valid_600077, JString, required = false,
                                 default = nil)
  if valid_600077 != nil:
    section.add "X-Amz-Algorithm", valid_600077
  var valid_600078 = header.getOrDefault("X-Amz-Signature")
  valid_600078 = validateParameter(valid_600078, JString, required = false,
                                 default = nil)
  if valid_600078 != nil:
    section.add "X-Amz-Signature", valid_600078
  var valid_600079 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600079 = validateParameter(valid_600079, JString, required = false,
                                 default = nil)
  if valid_600079 != nil:
    section.add "X-Amz-SignedHeaders", valid_600079
  var valid_600080 = header.getOrDefault("X-Amz-Credential")
  valid_600080 = validateParameter(valid_600080, JString, required = false,
                                 default = nil)
  if valid_600080 != nil:
    section.add "X-Amz-Credential", valid_600080
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600081: Call_GetComposeEnvironments_600066; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create or update a group of environments that each run a separate component of a single application. Takes a list of version labels that specify application source bundles for each of the environments to create or update. The name of each environment and other required information must be included in the source bundles in an environment manifest named <code>env.yaml</code>. See <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-mgmt-compose.html">Compose Environments</a> for details.
  ## 
  let valid = call_600081.validator(path, query, header, formData, body)
  let scheme = call_600081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600081.url(scheme.get, call_600081.host, call_600081.base,
                         call_600081.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600081, url, valid)

proc call*(call_600082: Call_GetComposeEnvironments_600066;
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
  var query_600083 = newJObject()
  add(query_600083, "ApplicationName", newJString(ApplicationName))
  add(query_600083, "Action", newJString(Action))
  add(query_600083, "GroupName", newJString(GroupName))
  if VersionLabels != nil:
    query_600083.add "VersionLabels", VersionLabels
  add(query_600083, "Version", newJString(Version))
  result = call_600082.call(nil, query_600083, nil, nil, nil)

var getComposeEnvironments* = Call_GetComposeEnvironments_600066(
    name: "getComposeEnvironments", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ComposeEnvironments",
    validator: validate_GetComposeEnvironments_600067, base: "/",
    url: url_GetComposeEnvironments_600068, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateApplication_600123 = ref object of OpenApiRestCall_599369
proc url_PostCreateApplication_600125(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateApplication_600124(path: JsonNode; query: JsonNode;
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
  var valid_600126 = query.getOrDefault("Action")
  valid_600126 = validateParameter(valid_600126, JString, required = true,
                                 default = newJString("CreateApplication"))
  if valid_600126 != nil:
    section.add "Action", valid_600126
  var valid_600127 = query.getOrDefault("Version")
  valid_600127 = validateParameter(valid_600127, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600127 != nil:
    section.add "Version", valid_600127
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600128 = header.getOrDefault("X-Amz-Date")
  valid_600128 = validateParameter(valid_600128, JString, required = false,
                                 default = nil)
  if valid_600128 != nil:
    section.add "X-Amz-Date", valid_600128
  var valid_600129 = header.getOrDefault("X-Amz-Security-Token")
  valid_600129 = validateParameter(valid_600129, JString, required = false,
                                 default = nil)
  if valid_600129 != nil:
    section.add "X-Amz-Security-Token", valid_600129
  var valid_600130 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600130 = validateParameter(valid_600130, JString, required = false,
                                 default = nil)
  if valid_600130 != nil:
    section.add "X-Amz-Content-Sha256", valid_600130
  var valid_600131 = header.getOrDefault("X-Amz-Algorithm")
  valid_600131 = validateParameter(valid_600131, JString, required = false,
                                 default = nil)
  if valid_600131 != nil:
    section.add "X-Amz-Algorithm", valid_600131
  var valid_600132 = header.getOrDefault("X-Amz-Signature")
  valid_600132 = validateParameter(valid_600132, JString, required = false,
                                 default = nil)
  if valid_600132 != nil:
    section.add "X-Amz-Signature", valid_600132
  var valid_600133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600133 = validateParameter(valid_600133, JString, required = false,
                                 default = nil)
  if valid_600133 != nil:
    section.add "X-Amz-SignedHeaders", valid_600133
  var valid_600134 = header.getOrDefault("X-Amz-Credential")
  valid_600134 = validateParameter(valid_600134, JString, required = false,
                                 default = nil)
  if valid_600134 != nil:
    section.add "X-Amz-Credential", valid_600134
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
  var valid_600135 = formData.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_600135 = validateParameter(valid_600135, JString, required = false,
                                 default = nil)
  if valid_600135 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_600135
  var valid_600136 = formData.getOrDefault("Tags")
  valid_600136 = validateParameter(valid_600136, JArray, required = false,
                                 default = nil)
  if valid_600136 != nil:
    section.add "Tags", valid_600136
  var valid_600137 = formData.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_600137 = validateParameter(valid_600137, JString, required = false,
                                 default = nil)
  if valid_600137 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_600137
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_600138 = formData.getOrDefault("ApplicationName")
  valid_600138 = validateParameter(valid_600138, JString, required = true,
                                 default = nil)
  if valid_600138 != nil:
    section.add "ApplicationName", valid_600138
  var valid_600139 = formData.getOrDefault("Description")
  valid_600139 = validateParameter(valid_600139, JString, required = false,
                                 default = nil)
  if valid_600139 != nil:
    section.add "Description", valid_600139
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600140: Call_PostCreateApplication_600123; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates an application that has one configuration template named <code>default</code> and no application versions. 
  ## 
  let valid = call_600140.validator(path, query, header, formData, body)
  let scheme = call_600140.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600140.url(scheme.get, call_600140.host, call_600140.base,
                         call_600140.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600140, url, valid)

proc call*(call_600141: Call_PostCreateApplication_600123; ApplicationName: string;
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
  var query_600142 = newJObject()
  var formData_600143 = newJObject()
  add(formData_600143, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  if Tags != nil:
    formData_600143.add "Tags", Tags
  add(formData_600143, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  add(query_600142, "Action", newJString(Action))
  add(formData_600143, "ApplicationName", newJString(ApplicationName))
  add(query_600142, "Version", newJString(Version))
  add(formData_600143, "Description", newJString(Description))
  result = call_600141.call(nil, query_600142, nil, formData_600143, nil)

var postCreateApplication* = Call_PostCreateApplication_600123(
    name: "postCreateApplication", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateApplication",
    validator: validate_PostCreateApplication_600124, base: "/",
    url: url_PostCreateApplication_600125, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateApplication_600103 = ref object of OpenApiRestCall_599369
proc url_GetCreateApplication_600105(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateApplication_600104(path: JsonNode; query: JsonNode;
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
  var valid_600106 = query.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_600106 = validateParameter(valid_600106, JString, required = false,
                                 default = nil)
  if valid_600106 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_600106
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_600107 = query.getOrDefault("ApplicationName")
  valid_600107 = validateParameter(valid_600107, JString, required = true,
                                 default = nil)
  if valid_600107 != nil:
    section.add "ApplicationName", valid_600107
  var valid_600108 = query.getOrDefault("Description")
  valid_600108 = validateParameter(valid_600108, JString, required = false,
                                 default = nil)
  if valid_600108 != nil:
    section.add "Description", valid_600108
  var valid_600109 = query.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_600109 = validateParameter(valid_600109, JString, required = false,
                                 default = nil)
  if valid_600109 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_600109
  var valid_600110 = query.getOrDefault("Tags")
  valid_600110 = validateParameter(valid_600110, JArray, required = false,
                                 default = nil)
  if valid_600110 != nil:
    section.add "Tags", valid_600110
  var valid_600111 = query.getOrDefault("Action")
  valid_600111 = validateParameter(valid_600111, JString, required = true,
                                 default = newJString("CreateApplication"))
  if valid_600111 != nil:
    section.add "Action", valid_600111
  var valid_600112 = query.getOrDefault("Version")
  valid_600112 = validateParameter(valid_600112, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600112 != nil:
    section.add "Version", valid_600112
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600113 = header.getOrDefault("X-Amz-Date")
  valid_600113 = validateParameter(valid_600113, JString, required = false,
                                 default = nil)
  if valid_600113 != nil:
    section.add "X-Amz-Date", valid_600113
  var valid_600114 = header.getOrDefault("X-Amz-Security-Token")
  valid_600114 = validateParameter(valid_600114, JString, required = false,
                                 default = nil)
  if valid_600114 != nil:
    section.add "X-Amz-Security-Token", valid_600114
  var valid_600115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600115 = validateParameter(valid_600115, JString, required = false,
                                 default = nil)
  if valid_600115 != nil:
    section.add "X-Amz-Content-Sha256", valid_600115
  var valid_600116 = header.getOrDefault("X-Amz-Algorithm")
  valid_600116 = validateParameter(valid_600116, JString, required = false,
                                 default = nil)
  if valid_600116 != nil:
    section.add "X-Amz-Algorithm", valid_600116
  var valid_600117 = header.getOrDefault("X-Amz-Signature")
  valid_600117 = validateParameter(valid_600117, JString, required = false,
                                 default = nil)
  if valid_600117 != nil:
    section.add "X-Amz-Signature", valid_600117
  var valid_600118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600118 = validateParameter(valid_600118, JString, required = false,
                                 default = nil)
  if valid_600118 != nil:
    section.add "X-Amz-SignedHeaders", valid_600118
  var valid_600119 = header.getOrDefault("X-Amz-Credential")
  valid_600119 = validateParameter(valid_600119, JString, required = false,
                                 default = nil)
  if valid_600119 != nil:
    section.add "X-Amz-Credential", valid_600119
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600120: Call_GetCreateApplication_600103; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates an application that has one configuration template named <code>default</code> and no application versions. 
  ## 
  let valid = call_600120.validator(path, query, header, formData, body)
  let scheme = call_600120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600120.url(scheme.get, call_600120.host, call_600120.base,
                         call_600120.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600120, url, valid)

proc call*(call_600121: Call_GetCreateApplication_600103; ApplicationName: string;
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
  var query_600122 = newJObject()
  add(query_600122, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  add(query_600122, "ApplicationName", newJString(ApplicationName))
  add(query_600122, "Description", newJString(Description))
  add(query_600122, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  if Tags != nil:
    query_600122.add "Tags", Tags
  add(query_600122, "Action", newJString(Action))
  add(query_600122, "Version", newJString(Version))
  result = call_600121.call(nil, query_600122, nil, nil, nil)

var getCreateApplication* = Call_GetCreateApplication_600103(
    name: "getCreateApplication", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateApplication",
    validator: validate_GetCreateApplication_600104, base: "/",
    url: url_GetCreateApplication_600105, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateApplicationVersion_600175 = ref object of OpenApiRestCall_599369
proc url_PostCreateApplicationVersion_600177(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateApplicationVersion_600176(path: JsonNode; query: JsonNode;
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
  var valid_600178 = query.getOrDefault("Action")
  valid_600178 = validateParameter(valid_600178, JString, required = true, default = newJString(
      "CreateApplicationVersion"))
  if valid_600178 != nil:
    section.add "Action", valid_600178
  var valid_600179 = query.getOrDefault("Version")
  valid_600179 = validateParameter(valid_600179, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600179 != nil:
    section.add "Version", valid_600179
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600180 = header.getOrDefault("X-Amz-Date")
  valid_600180 = validateParameter(valid_600180, JString, required = false,
                                 default = nil)
  if valid_600180 != nil:
    section.add "X-Amz-Date", valid_600180
  var valid_600181 = header.getOrDefault("X-Amz-Security-Token")
  valid_600181 = validateParameter(valid_600181, JString, required = false,
                                 default = nil)
  if valid_600181 != nil:
    section.add "X-Amz-Security-Token", valid_600181
  var valid_600182 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600182 = validateParameter(valid_600182, JString, required = false,
                                 default = nil)
  if valid_600182 != nil:
    section.add "X-Amz-Content-Sha256", valid_600182
  var valid_600183 = header.getOrDefault("X-Amz-Algorithm")
  valid_600183 = validateParameter(valid_600183, JString, required = false,
                                 default = nil)
  if valid_600183 != nil:
    section.add "X-Amz-Algorithm", valid_600183
  var valid_600184 = header.getOrDefault("X-Amz-Signature")
  valid_600184 = validateParameter(valid_600184, JString, required = false,
                                 default = nil)
  if valid_600184 != nil:
    section.add "X-Amz-Signature", valid_600184
  var valid_600185 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600185 = validateParameter(valid_600185, JString, required = false,
                                 default = nil)
  if valid_600185 != nil:
    section.add "X-Amz-SignedHeaders", valid_600185
  var valid_600186 = header.getOrDefault("X-Amz-Credential")
  valid_600186 = validateParameter(valid_600186, JString, required = false,
                                 default = nil)
  if valid_600186 != nil:
    section.add "X-Amz-Credential", valid_600186
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
  var valid_600187 = formData.getOrDefault("SourceBundle.S3Key")
  valid_600187 = validateParameter(valid_600187, JString, required = false,
                                 default = nil)
  if valid_600187 != nil:
    section.add "SourceBundle.S3Key", valid_600187
  assert formData != nil,
        "formData argument is necessary due to required `VersionLabel` field"
  var valid_600188 = formData.getOrDefault("VersionLabel")
  valid_600188 = validateParameter(valid_600188, JString, required = true,
                                 default = nil)
  if valid_600188 != nil:
    section.add "VersionLabel", valid_600188
  var valid_600189 = formData.getOrDefault("SourceBundle.S3Bucket")
  valid_600189 = validateParameter(valid_600189, JString, required = false,
                                 default = nil)
  if valid_600189 != nil:
    section.add "SourceBundle.S3Bucket", valid_600189
  var valid_600190 = formData.getOrDefault("BuildConfiguration.ComputeType")
  valid_600190 = validateParameter(valid_600190, JString, required = false,
                                 default = nil)
  if valid_600190 != nil:
    section.add "BuildConfiguration.ComputeType", valid_600190
  var valid_600191 = formData.getOrDefault("SourceBuildInformation.SourceType")
  valid_600191 = validateParameter(valid_600191, JString, required = false,
                                 default = nil)
  if valid_600191 != nil:
    section.add "SourceBuildInformation.SourceType", valid_600191
  var valid_600192 = formData.getOrDefault("Tags")
  valid_600192 = validateParameter(valid_600192, JArray, required = false,
                                 default = nil)
  if valid_600192 != nil:
    section.add "Tags", valid_600192
  var valid_600193 = formData.getOrDefault("AutoCreateApplication")
  valid_600193 = validateParameter(valid_600193, JBool, required = false, default = nil)
  if valid_600193 != nil:
    section.add "AutoCreateApplication", valid_600193
  var valid_600194 = formData.getOrDefault("SourceBuildInformation.SourceLocation")
  valid_600194 = validateParameter(valid_600194, JString, required = false,
                                 default = nil)
  if valid_600194 != nil:
    section.add "SourceBuildInformation.SourceLocation", valid_600194
  var valid_600195 = formData.getOrDefault("BuildConfiguration.CodeBuildServiceRole")
  valid_600195 = validateParameter(valid_600195, JString, required = false,
                                 default = nil)
  if valid_600195 != nil:
    section.add "BuildConfiguration.CodeBuildServiceRole", valid_600195
  var valid_600196 = formData.getOrDefault("ApplicationName")
  valid_600196 = validateParameter(valid_600196, JString, required = true,
                                 default = nil)
  if valid_600196 != nil:
    section.add "ApplicationName", valid_600196
  var valid_600197 = formData.getOrDefault("BuildConfiguration.ArtifactName")
  valid_600197 = validateParameter(valid_600197, JString, required = false,
                                 default = nil)
  if valid_600197 != nil:
    section.add "BuildConfiguration.ArtifactName", valid_600197
  var valid_600198 = formData.getOrDefault("BuildConfiguration.TimeoutInMinutes")
  valid_600198 = validateParameter(valid_600198, JString, required = false,
                                 default = nil)
  if valid_600198 != nil:
    section.add "BuildConfiguration.TimeoutInMinutes", valid_600198
  var valid_600199 = formData.getOrDefault("SourceBuildInformation.SourceRepository")
  valid_600199 = validateParameter(valid_600199, JString, required = false,
                                 default = nil)
  if valid_600199 != nil:
    section.add "SourceBuildInformation.SourceRepository", valid_600199
  var valid_600200 = formData.getOrDefault("Description")
  valid_600200 = validateParameter(valid_600200, JString, required = false,
                                 default = nil)
  if valid_600200 != nil:
    section.add "Description", valid_600200
  var valid_600201 = formData.getOrDefault("BuildConfiguration.Image")
  valid_600201 = validateParameter(valid_600201, JString, required = false,
                                 default = nil)
  if valid_600201 != nil:
    section.add "BuildConfiguration.Image", valid_600201
  var valid_600202 = formData.getOrDefault("Process")
  valid_600202 = validateParameter(valid_600202, JBool, required = false, default = nil)
  if valid_600202 != nil:
    section.add "Process", valid_600202
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600203: Call_PostCreateApplicationVersion_600175; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an application version for the specified application. You can create an application version from a source bundle in Amazon S3, a commit in AWS CodeCommit, or the output of an AWS CodeBuild build as follows:</p> <p>Specify a commit in an AWS CodeCommit repository with <code>SourceBuildInformation</code>.</p> <p>Specify a build in an AWS CodeBuild with <code>SourceBuildInformation</code> and <code>BuildConfiguration</code>.</p> <p>Specify a source bundle in S3 with <code>SourceBundle</code> </p> <p>Omit both <code>SourceBuildInformation</code> and <code>SourceBundle</code> to use the default sample application.</p> <note> <p>Once you create an application version with a specified Amazon S3 bucket and key location, you cannot change that Amazon S3 location. If you change the Amazon S3 location, you receive an exception when you attempt to launch an environment from the application version.</p> </note>
  ## 
  let valid = call_600203.validator(path, query, header, formData, body)
  let scheme = call_600203.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600203.url(scheme.get, call_600203.host, call_600203.base,
                         call_600203.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600203, url, valid)

proc call*(call_600204: Call_PostCreateApplicationVersion_600175;
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
  var query_600205 = newJObject()
  var formData_600206 = newJObject()
  add(formData_600206, "SourceBundle.S3Key", newJString(SourceBundleS3Key))
  add(formData_600206, "VersionLabel", newJString(VersionLabel))
  add(formData_600206, "SourceBundle.S3Bucket", newJString(SourceBundleS3Bucket))
  add(formData_600206, "BuildConfiguration.ComputeType",
      newJString(BuildConfigurationComputeType))
  add(formData_600206, "SourceBuildInformation.SourceType",
      newJString(SourceBuildInformationSourceType))
  if Tags != nil:
    formData_600206.add "Tags", Tags
  add(formData_600206, "AutoCreateApplication", newJBool(AutoCreateApplication))
  add(formData_600206, "SourceBuildInformation.SourceLocation",
      newJString(SourceBuildInformationSourceLocation))
  add(query_600205, "Action", newJString(Action))
  add(formData_600206, "BuildConfiguration.CodeBuildServiceRole",
      newJString(BuildConfigurationCodeBuildServiceRole))
  add(formData_600206, "ApplicationName", newJString(ApplicationName))
  add(formData_600206, "BuildConfiguration.ArtifactName",
      newJString(BuildConfigurationArtifactName))
  add(formData_600206, "BuildConfiguration.TimeoutInMinutes",
      newJString(BuildConfigurationTimeoutInMinutes))
  add(formData_600206, "SourceBuildInformation.SourceRepository",
      newJString(SourceBuildInformationSourceRepository))
  add(formData_600206, "Description", newJString(Description))
  add(formData_600206, "BuildConfiguration.Image",
      newJString(BuildConfigurationImage))
  add(formData_600206, "Process", newJBool(Process))
  add(query_600205, "Version", newJString(Version))
  result = call_600204.call(nil, query_600205, nil, formData_600206, nil)

var postCreateApplicationVersion* = Call_PostCreateApplicationVersion_600175(
    name: "postCreateApplicationVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateApplicationVersion",
    validator: validate_PostCreateApplicationVersion_600176, base: "/",
    url: url_PostCreateApplicationVersion_600177,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateApplicationVersion_600144 = ref object of OpenApiRestCall_599369
proc url_GetCreateApplicationVersion_600146(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateApplicationVersion_600145(path: JsonNode; query: JsonNode;
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
  var valid_600147 = query.getOrDefault("BuildConfiguration.TimeoutInMinutes")
  valid_600147 = validateParameter(valid_600147, JString, required = false,
                                 default = nil)
  if valid_600147 != nil:
    section.add "BuildConfiguration.TimeoutInMinutes", valid_600147
  var valid_600148 = query.getOrDefault("SourceBundle.S3Bucket")
  valid_600148 = validateParameter(valid_600148, JString, required = false,
                                 default = nil)
  if valid_600148 != nil:
    section.add "SourceBundle.S3Bucket", valid_600148
  var valid_600149 = query.getOrDefault("BuildConfiguration.ComputeType")
  valid_600149 = validateParameter(valid_600149, JString, required = false,
                                 default = nil)
  if valid_600149 != nil:
    section.add "BuildConfiguration.ComputeType", valid_600149
  assert query != nil,
        "query argument is necessary due to required `VersionLabel` field"
  var valid_600150 = query.getOrDefault("VersionLabel")
  valid_600150 = validateParameter(valid_600150, JString, required = true,
                                 default = nil)
  if valid_600150 != nil:
    section.add "VersionLabel", valid_600150
  var valid_600151 = query.getOrDefault("BuildConfiguration.ArtifactName")
  valid_600151 = validateParameter(valid_600151, JString, required = false,
                                 default = nil)
  if valid_600151 != nil:
    section.add "BuildConfiguration.ArtifactName", valid_600151
  var valid_600152 = query.getOrDefault("ApplicationName")
  valid_600152 = validateParameter(valid_600152, JString, required = true,
                                 default = nil)
  if valid_600152 != nil:
    section.add "ApplicationName", valid_600152
  var valid_600153 = query.getOrDefault("Description")
  valid_600153 = validateParameter(valid_600153, JString, required = false,
                                 default = nil)
  if valid_600153 != nil:
    section.add "Description", valid_600153
  var valid_600154 = query.getOrDefault("BuildConfiguration.Image")
  valid_600154 = validateParameter(valid_600154, JString, required = false,
                                 default = nil)
  if valid_600154 != nil:
    section.add "BuildConfiguration.Image", valid_600154
  var valid_600155 = query.getOrDefault("SourceBuildInformation.SourceLocation")
  valid_600155 = validateParameter(valid_600155, JString, required = false,
                                 default = nil)
  if valid_600155 != nil:
    section.add "SourceBuildInformation.SourceLocation", valid_600155
  var valid_600156 = query.getOrDefault("SourceBundle.S3Key")
  valid_600156 = validateParameter(valid_600156, JString, required = false,
                                 default = nil)
  if valid_600156 != nil:
    section.add "SourceBundle.S3Key", valid_600156
  var valid_600157 = query.getOrDefault("Tags")
  valid_600157 = validateParameter(valid_600157, JArray, required = false,
                                 default = nil)
  if valid_600157 != nil:
    section.add "Tags", valid_600157
  var valid_600158 = query.getOrDefault("AutoCreateApplication")
  valid_600158 = validateParameter(valid_600158, JBool, required = false, default = nil)
  if valid_600158 != nil:
    section.add "AutoCreateApplication", valid_600158
  var valid_600159 = query.getOrDefault("Action")
  valid_600159 = validateParameter(valid_600159, JString, required = true, default = newJString(
      "CreateApplicationVersion"))
  if valid_600159 != nil:
    section.add "Action", valid_600159
  var valid_600160 = query.getOrDefault("SourceBuildInformation.SourceType")
  valid_600160 = validateParameter(valid_600160, JString, required = false,
                                 default = nil)
  if valid_600160 != nil:
    section.add "SourceBuildInformation.SourceType", valid_600160
  var valid_600161 = query.getOrDefault("BuildConfiguration.CodeBuildServiceRole")
  valid_600161 = validateParameter(valid_600161, JString, required = false,
                                 default = nil)
  if valid_600161 != nil:
    section.add "BuildConfiguration.CodeBuildServiceRole", valid_600161
  var valid_600162 = query.getOrDefault("Process")
  valid_600162 = validateParameter(valid_600162, JBool, required = false, default = nil)
  if valid_600162 != nil:
    section.add "Process", valid_600162
  var valid_600163 = query.getOrDefault("SourceBuildInformation.SourceRepository")
  valid_600163 = validateParameter(valid_600163, JString, required = false,
                                 default = nil)
  if valid_600163 != nil:
    section.add "SourceBuildInformation.SourceRepository", valid_600163
  var valid_600164 = query.getOrDefault("Version")
  valid_600164 = validateParameter(valid_600164, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600164 != nil:
    section.add "Version", valid_600164
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600165 = header.getOrDefault("X-Amz-Date")
  valid_600165 = validateParameter(valid_600165, JString, required = false,
                                 default = nil)
  if valid_600165 != nil:
    section.add "X-Amz-Date", valid_600165
  var valid_600166 = header.getOrDefault("X-Amz-Security-Token")
  valid_600166 = validateParameter(valid_600166, JString, required = false,
                                 default = nil)
  if valid_600166 != nil:
    section.add "X-Amz-Security-Token", valid_600166
  var valid_600167 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600167 = validateParameter(valid_600167, JString, required = false,
                                 default = nil)
  if valid_600167 != nil:
    section.add "X-Amz-Content-Sha256", valid_600167
  var valid_600168 = header.getOrDefault("X-Amz-Algorithm")
  valid_600168 = validateParameter(valid_600168, JString, required = false,
                                 default = nil)
  if valid_600168 != nil:
    section.add "X-Amz-Algorithm", valid_600168
  var valid_600169 = header.getOrDefault("X-Amz-Signature")
  valid_600169 = validateParameter(valid_600169, JString, required = false,
                                 default = nil)
  if valid_600169 != nil:
    section.add "X-Amz-Signature", valid_600169
  var valid_600170 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600170 = validateParameter(valid_600170, JString, required = false,
                                 default = nil)
  if valid_600170 != nil:
    section.add "X-Amz-SignedHeaders", valid_600170
  var valid_600171 = header.getOrDefault("X-Amz-Credential")
  valid_600171 = validateParameter(valid_600171, JString, required = false,
                                 default = nil)
  if valid_600171 != nil:
    section.add "X-Amz-Credential", valid_600171
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600172: Call_GetCreateApplicationVersion_600144; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an application version for the specified application. You can create an application version from a source bundle in Amazon S3, a commit in AWS CodeCommit, or the output of an AWS CodeBuild build as follows:</p> <p>Specify a commit in an AWS CodeCommit repository with <code>SourceBuildInformation</code>.</p> <p>Specify a build in an AWS CodeBuild with <code>SourceBuildInformation</code> and <code>BuildConfiguration</code>.</p> <p>Specify a source bundle in S3 with <code>SourceBundle</code> </p> <p>Omit both <code>SourceBuildInformation</code> and <code>SourceBundle</code> to use the default sample application.</p> <note> <p>Once you create an application version with a specified Amazon S3 bucket and key location, you cannot change that Amazon S3 location. If you change the Amazon S3 location, you receive an exception when you attempt to launch an environment from the application version.</p> </note>
  ## 
  let valid = call_600172.validator(path, query, header, formData, body)
  let scheme = call_600172.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600172.url(scheme.get, call_600172.host, call_600172.base,
                         call_600172.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600172, url, valid)

proc call*(call_600173: Call_GetCreateApplicationVersion_600144;
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
  var query_600174 = newJObject()
  add(query_600174, "BuildConfiguration.TimeoutInMinutes",
      newJString(BuildConfigurationTimeoutInMinutes))
  add(query_600174, "SourceBundle.S3Bucket", newJString(SourceBundleS3Bucket))
  add(query_600174, "BuildConfiguration.ComputeType",
      newJString(BuildConfigurationComputeType))
  add(query_600174, "VersionLabel", newJString(VersionLabel))
  add(query_600174, "BuildConfiguration.ArtifactName",
      newJString(BuildConfigurationArtifactName))
  add(query_600174, "ApplicationName", newJString(ApplicationName))
  add(query_600174, "Description", newJString(Description))
  add(query_600174, "BuildConfiguration.Image",
      newJString(BuildConfigurationImage))
  add(query_600174, "SourceBuildInformation.SourceLocation",
      newJString(SourceBuildInformationSourceLocation))
  add(query_600174, "SourceBundle.S3Key", newJString(SourceBundleS3Key))
  if Tags != nil:
    query_600174.add "Tags", Tags
  add(query_600174, "AutoCreateApplication", newJBool(AutoCreateApplication))
  add(query_600174, "Action", newJString(Action))
  add(query_600174, "SourceBuildInformation.SourceType",
      newJString(SourceBuildInformationSourceType))
  add(query_600174, "BuildConfiguration.CodeBuildServiceRole",
      newJString(BuildConfigurationCodeBuildServiceRole))
  add(query_600174, "Process", newJBool(Process))
  add(query_600174, "SourceBuildInformation.SourceRepository",
      newJString(SourceBuildInformationSourceRepository))
  add(query_600174, "Version", newJString(Version))
  result = call_600173.call(nil, query_600174, nil, nil, nil)

var getCreateApplicationVersion* = Call_GetCreateApplicationVersion_600144(
    name: "getCreateApplicationVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateApplicationVersion",
    validator: validate_GetCreateApplicationVersion_600145, base: "/",
    url: url_GetCreateApplicationVersion_600146,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateConfigurationTemplate_600232 = ref object of OpenApiRestCall_599369
proc url_PostCreateConfigurationTemplate_600234(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateConfigurationTemplate_600233(path: JsonNode;
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
  var valid_600235 = query.getOrDefault("Action")
  valid_600235 = validateParameter(valid_600235, JString, required = true, default = newJString(
      "CreateConfigurationTemplate"))
  if valid_600235 != nil:
    section.add "Action", valid_600235
  var valid_600236 = query.getOrDefault("Version")
  valid_600236 = validateParameter(valid_600236, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600236 != nil:
    section.add "Version", valid_600236
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600237 = header.getOrDefault("X-Amz-Date")
  valid_600237 = validateParameter(valid_600237, JString, required = false,
                                 default = nil)
  if valid_600237 != nil:
    section.add "X-Amz-Date", valid_600237
  var valid_600238 = header.getOrDefault("X-Amz-Security-Token")
  valid_600238 = validateParameter(valid_600238, JString, required = false,
                                 default = nil)
  if valid_600238 != nil:
    section.add "X-Amz-Security-Token", valid_600238
  var valid_600239 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600239 = validateParameter(valid_600239, JString, required = false,
                                 default = nil)
  if valid_600239 != nil:
    section.add "X-Amz-Content-Sha256", valid_600239
  var valid_600240 = header.getOrDefault("X-Amz-Algorithm")
  valid_600240 = validateParameter(valid_600240, JString, required = false,
                                 default = nil)
  if valid_600240 != nil:
    section.add "X-Amz-Algorithm", valid_600240
  var valid_600241 = header.getOrDefault("X-Amz-Signature")
  valid_600241 = validateParameter(valid_600241, JString, required = false,
                                 default = nil)
  if valid_600241 != nil:
    section.add "X-Amz-Signature", valid_600241
  var valid_600242 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600242 = validateParameter(valid_600242, JString, required = false,
                                 default = nil)
  if valid_600242 != nil:
    section.add "X-Amz-SignedHeaders", valid_600242
  var valid_600243 = header.getOrDefault("X-Amz-Credential")
  valid_600243 = validateParameter(valid_600243, JString, required = false,
                                 default = nil)
  if valid_600243 != nil:
    section.add "X-Amz-Credential", valid_600243
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
  var valid_600244 = formData.getOrDefault("OptionSettings")
  valid_600244 = validateParameter(valid_600244, JArray, required = false,
                                 default = nil)
  if valid_600244 != nil:
    section.add "OptionSettings", valid_600244
  var valid_600245 = formData.getOrDefault("Tags")
  valid_600245 = validateParameter(valid_600245, JArray, required = false,
                                 default = nil)
  if valid_600245 != nil:
    section.add "Tags", valid_600245
  var valid_600246 = formData.getOrDefault("SolutionStackName")
  valid_600246 = validateParameter(valid_600246, JString, required = false,
                                 default = nil)
  if valid_600246 != nil:
    section.add "SolutionStackName", valid_600246
  var valid_600247 = formData.getOrDefault("SourceConfiguration.ApplicationName")
  valid_600247 = validateParameter(valid_600247, JString, required = false,
                                 default = nil)
  if valid_600247 != nil:
    section.add "SourceConfiguration.ApplicationName", valid_600247
  var valid_600248 = formData.getOrDefault("EnvironmentId")
  valid_600248 = validateParameter(valid_600248, JString, required = false,
                                 default = nil)
  if valid_600248 != nil:
    section.add "EnvironmentId", valid_600248
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_600249 = formData.getOrDefault("ApplicationName")
  valid_600249 = validateParameter(valid_600249, JString, required = true,
                                 default = nil)
  if valid_600249 != nil:
    section.add "ApplicationName", valid_600249
  var valid_600250 = formData.getOrDefault("PlatformArn")
  valid_600250 = validateParameter(valid_600250, JString, required = false,
                                 default = nil)
  if valid_600250 != nil:
    section.add "PlatformArn", valid_600250
  var valid_600251 = formData.getOrDefault("TemplateName")
  valid_600251 = validateParameter(valid_600251, JString, required = true,
                                 default = nil)
  if valid_600251 != nil:
    section.add "TemplateName", valid_600251
  var valid_600252 = formData.getOrDefault("Description")
  valid_600252 = validateParameter(valid_600252, JString, required = false,
                                 default = nil)
  if valid_600252 != nil:
    section.add "Description", valid_600252
  var valid_600253 = formData.getOrDefault("SourceConfiguration.TemplateName")
  valid_600253 = validateParameter(valid_600253, JString, required = false,
                                 default = nil)
  if valid_600253 != nil:
    section.add "SourceConfiguration.TemplateName", valid_600253
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600254: Call_PostCreateConfigurationTemplate_600232;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a configuration template. Templates are associated with a specific application and are used to deploy different versions of the application with the same configuration settings.</p> <p>Templates aren't associated with any environment. The <code>EnvironmentName</code> response element is always <code>null</code>.</p> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> <li> <p> <a>DescribeConfigurationSettings</a> </p> </li> <li> <p> <a>ListAvailableSolutionStacks</a> </p> </li> </ul>
  ## 
  let valid = call_600254.validator(path, query, header, formData, body)
  let scheme = call_600254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600254.url(scheme.get, call_600254.host, call_600254.base,
                         call_600254.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600254, url, valid)

proc call*(call_600255: Call_PostCreateConfigurationTemplate_600232;
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
  var query_600256 = newJObject()
  var formData_600257 = newJObject()
  if OptionSettings != nil:
    formData_600257.add "OptionSettings", OptionSettings
  if Tags != nil:
    formData_600257.add "Tags", Tags
  add(formData_600257, "SolutionStackName", newJString(SolutionStackName))
  add(formData_600257, "SourceConfiguration.ApplicationName",
      newJString(SourceConfigurationApplicationName))
  add(formData_600257, "EnvironmentId", newJString(EnvironmentId))
  add(query_600256, "Action", newJString(Action))
  add(formData_600257, "ApplicationName", newJString(ApplicationName))
  add(formData_600257, "PlatformArn", newJString(PlatformArn))
  add(formData_600257, "TemplateName", newJString(TemplateName))
  add(query_600256, "Version", newJString(Version))
  add(formData_600257, "Description", newJString(Description))
  add(formData_600257, "SourceConfiguration.TemplateName",
      newJString(SourceConfigurationTemplateName))
  result = call_600255.call(nil, query_600256, nil, formData_600257, nil)

var postCreateConfigurationTemplate* = Call_PostCreateConfigurationTemplate_600232(
    name: "postCreateConfigurationTemplate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateConfigurationTemplate",
    validator: validate_PostCreateConfigurationTemplate_600233, base: "/",
    url: url_PostCreateConfigurationTemplate_600234,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateConfigurationTemplate_600207 = ref object of OpenApiRestCall_599369
proc url_GetCreateConfigurationTemplate_600209(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateConfigurationTemplate_600208(path: JsonNode;
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
  var valid_600210 = query.getOrDefault("SourceConfiguration.ApplicationName")
  valid_600210 = validateParameter(valid_600210, JString, required = false,
                                 default = nil)
  if valid_600210 != nil:
    section.add "SourceConfiguration.ApplicationName", valid_600210
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_600211 = query.getOrDefault("ApplicationName")
  valid_600211 = validateParameter(valid_600211, JString, required = true,
                                 default = nil)
  if valid_600211 != nil:
    section.add "ApplicationName", valid_600211
  var valid_600212 = query.getOrDefault("Description")
  valid_600212 = validateParameter(valid_600212, JString, required = false,
                                 default = nil)
  if valid_600212 != nil:
    section.add "Description", valid_600212
  var valid_600213 = query.getOrDefault("PlatformArn")
  valid_600213 = validateParameter(valid_600213, JString, required = false,
                                 default = nil)
  if valid_600213 != nil:
    section.add "PlatformArn", valid_600213
  var valid_600214 = query.getOrDefault("Tags")
  valid_600214 = validateParameter(valid_600214, JArray, required = false,
                                 default = nil)
  if valid_600214 != nil:
    section.add "Tags", valid_600214
  var valid_600215 = query.getOrDefault("Action")
  valid_600215 = validateParameter(valid_600215, JString, required = true, default = newJString(
      "CreateConfigurationTemplate"))
  if valid_600215 != nil:
    section.add "Action", valid_600215
  var valid_600216 = query.getOrDefault("SolutionStackName")
  valid_600216 = validateParameter(valid_600216, JString, required = false,
                                 default = nil)
  if valid_600216 != nil:
    section.add "SolutionStackName", valid_600216
  var valid_600217 = query.getOrDefault("EnvironmentId")
  valid_600217 = validateParameter(valid_600217, JString, required = false,
                                 default = nil)
  if valid_600217 != nil:
    section.add "EnvironmentId", valid_600217
  var valid_600218 = query.getOrDefault("TemplateName")
  valid_600218 = validateParameter(valid_600218, JString, required = true,
                                 default = nil)
  if valid_600218 != nil:
    section.add "TemplateName", valid_600218
  var valid_600219 = query.getOrDefault("OptionSettings")
  valid_600219 = validateParameter(valid_600219, JArray, required = false,
                                 default = nil)
  if valid_600219 != nil:
    section.add "OptionSettings", valid_600219
  var valid_600220 = query.getOrDefault("Version")
  valid_600220 = validateParameter(valid_600220, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600220 != nil:
    section.add "Version", valid_600220
  var valid_600221 = query.getOrDefault("SourceConfiguration.TemplateName")
  valid_600221 = validateParameter(valid_600221, JString, required = false,
                                 default = nil)
  if valid_600221 != nil:
    section.add "SourceConfiguration.TemplateName", valid_600221
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600222 = header.getOrDefault("X-Amz-Date")
  valid_600222 = validateParameter(valid_600222, JString, required = false,
                                 default = nil)
  if valid_600222 != nil:
    section.add "X-Amz-Date", valid_600222
  var valid_600223 = header.getOrDefault("X-Amz-Security-Token")
  valid_600223 = validateParameter(valid_600223, JString, required = false,
                                 default = nil)
  if valid_600223 != nil:
    section.add "X-Amz-Security-Token", valid_600223
  var valid_600224 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600224 = validateParameter(valid_600224, JString, required = false,
                                 default = nil)
  if valid_600224 != nil:
    section.add "X-Amz-Content-Sha256", valid_600224
  var valid_600225 = header.getOrDefault("X-Amz-Algorithm")
  valid_600225 = validateParameter(valid_600225, JString, required = false,
                                 default = nil)
  if valid_600225 != nil:
    section.add "X-Amz-Algorithm", valid_600225
  var valid_600226 = header.getOrDefault("X-Amz-Signature")
  valid_600226 = validateParameter(valid_600226, JString, required = false,
                                 default = nil)
  if valid_600226 != nil:
    section.add "X-Amz-Signature", valid_600226
  var valid_600227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600227 = validateParameter(valid_600227, JString, required = false,
                                 default = nil)
  if valid_600227 != nil:
    section.add "X-Amz-SignedHeaders", valid_600227
  var valid_600228 = header.getOrDefault("X-Amz-Credential")
  valid_600228 = validateParameter(valid_600228, JString, required = false,
                                 default = nil)
  if valid_600228 != nil:
    section.add "X-Amz-Credential", valid_600228
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600229: Call_GetCreateConfigurationTemplate_600207; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a configuration template. Templates are associated with a specific application and are used to deploy different versions of the application with the same configuration settings.</p> <p>Templates aren't associated with any environment. The <code>EnvironmentName</code> response element is always <code>null</code>.</p> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> <li> <p> <a>DescribeConfigurationSettings</a> </p> </li> <li> <p> <a>ListAvailableSolutionStacks</a> </p> </li> </ul>
  ## 
  let valid = call_600229.validator(path, query, header, formData, body)
  let scheme = call_600229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600229.url(scheme.get, call_600229.host, call_600229.base,
                         call_600229.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600229, url, valid)

proc call*(call_600230: Call_GetCreateConfigurationTemplate_600207;
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
  var query_600231 = newJObject()
  add(query_600231, "SourceConfiguration.ApplicationName",
      newJString(SourceConfigurationApplicationName))
  add(query_600231, "ApplicationName", newJString(ApplicationName))
  add(query_600231, "Description", newJString(Description))
  add(query_600231, "PlatformArn", newJString(PlatformArn))
  if Tags != nil:
    query_600231.add "Tags", Tags
  add(query_600231, "Action", newJString(Action))
  add(query_600231, "SolutionStackName", newJString(SolutionStackName))
  add(query_600231, "EnvironmentId", newJString(EnvironmentId))
  add(query_600231, "TemplateName", newJString(TemplateName))
  if OptionSettings != nil:
    query_600231.add "OptionSettings", OptionSettings
  add(query_600231, "Version", newJString(Version))
  add(query_600231, "SourceConfiguration.TemplateName",
      newJString(SourceConfigurationTemplateName))
  result = call_600230.call(nil, query_600231, nil, nil, nil)

var getCreateConfigurationTemplate* = Call_GetCreateConfigurationTemplate_600207(
    name: "getCreateConfigurationTemplate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateConfigurationTemplate",
    validator: validate_GetCreateConfigurationTemplate_600208, base: "/",
    url: url_GetCreateConfigurationTemplate_600209,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEnvironment_600288 = ref object of OpenApiRestCall_599369
proc url_PostCreateEnvironment_600290(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateEnvironment_600289(path: JsonNode; query: JsonNode;
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
  var valid_600291 = query.getOrDefault("Action")
  valid_600291 = validateParameter(valid_600291, JString, required = true,
                                 default = newJString("CreateEnvironment"))
  if valid_600291 != nil:
    section.add "Action", valid_600291
  var valid_600292 = query.getOrDefault("Version")
  valid_600292 = validateParameter(valid_600292, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600292 != nil:
    section.add "Version", valid_600292
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600293 = header.getOrDefault("X-Amz-Date")
  valid_600293 = validateParameter(valid_600293, JString, required = false,
                                 default = nil)
  if valid_600293 != nil:
    section.add "X-Amz-Date", valid_600293
  var valid_600294 = header.getOrDefault("X-Amz-Security-Token")
  valid_600294 = validateParameter(valid_600294, JString, required = false,
                                 default = nil)
  if valid_600294 != nil:
    section.add "X-Amz-Security-Token", valid_600294
  var valid_600295 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600295 = validateParameter(valid_600295, JString, required = false,
                                 default = nil)
  if valid_600295 != nil:
    section.add "X-Amz-Content-Sha256", valid_600295
  var valid_600296 = header.getOrDefault("X-Amz-Algorithm")
  valid_600296 = validateParameter(valid_600296, JString, required = false,
                                 default = nil)
  if valid_600296 != nil:
    section.add "X-Amz-Algorithm", valid_600296
  var valid_600297 = header.getOrDefault("X-Amz-Signature")
  valid_600297 = validateParameter(valid_600297, JString, required = false,
                                 default = nil)
  if valid_600297 != nil:
    section.add "X-Amz-Signature", valid_600297
  var valid_600298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600298 = validateParameter(valid_600298, JString, required = false,
                                 default = nil)
  if valid_600298 != nil:
    section.add "X-Amz-SignedHeaders", valid_600298
  var valid_600299 = header.getOrDefault("X-Amz-Credential")
  valid_600299 = validateParameter(valid_600299, JString, required = false,
                                 default = nil)
  if valid_600299 != nil:
    section.add "X-Amz-Credential", valid_600299
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
  var valid_600300 = formData.getOrDefault("Tier.Name")
  valid_600300 = validateParameter(valid_600300, JString, required = false,
                                 default = nil)
  if valid_600300 != nil:
    section.add "Tier.Name", valid_600300
  var valid_600301 = formData.getOrDefault("OptionsToRemove")
  valid_600301 = validateParameter(valid_600301, JArray, required = false,
                                 default = nil)
  if valid_600301 != nil:
    section.add "OptionsToRemove", valid_600301
  var valid_600302 = formData.getOrDefault("VersionLabel")
  valid_600302 = validateParameter(valid_600302, JString, required = false,
                                 default = nil)
  if valid_600302 != nil:
    section.add "VersionLabel", valid_600302
  var valid_600303 = formData.getOrDefault("OptionSettings")
  valid_600303 = validateParameter(valid_600303, JArray, required = false,
                                 default = nil)
  if valid_600303 != nil:
    section.add "OptionSettings", valid_600303
  var valid_600304 = formData.getOrDefault("GroupName")
  valid_600304 = validateParameter(valid_600304, JString, required = false,
                                 default = nil)
  if valid_600304 != nil:
    section.add "GroupName", valid_600304
  var valid_600305 = formData.getOrDefault("Tags")
  valid_600305 = validateParameter(valid_600305, JArray, required = false,
                                 default = nil)
  if valid_600305 != nil:
    section.add "Tags", valid_600305
  var valid_600306 = formData.getOrDefault("CNAMEPrefix")
  valid_600306 = validateParameter(valid_600306, JString, required = false,
                                 default = nil)
  if valid_600306 != nil:
    section.add "CNAMEPrefix", valid_600306
  var valid_600307 = formData.getOrDefault("SolutionStackName")
  valid_600307 = validateParameter(valid_600307, JString, required = false,
                                 default = nil)
  if valid_600307 != nil:
    section.add "SolutionStackName", valid_600307
  var valid_600308 = formData.getOrDefault("EnvironmentName")
  valid_600308 = validateParameter(valid_600308, JString, required = false,
                                 default = nil)
  if valid_600308 != nil:
    section.add "EnvironmentName", valid_600308
  var valid_600309 = formData.getOrDefault("Tier.Type")
  valid_600309 = validateParameter(valid_600309, JString, required = false,
                                 default = nil)
  if valid_600309 != nil:
    section.add "Tier.Type", valid_600309
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_600310 = formData.getOrDefault("ApplicationName")
  valid_600310 = validateParameter(valid_600310, JString, required = true,
                                 default = nil)
  if valid_600310 != nil:
    section.add "ApplicationName", valid_600310
  var valid_600311 = formData.getOrDefault("PlatformArn")
  valid_600311 = validateParameter(valid_600311, JString, required = false,
                                 default = nil)
  if valid_600311 != nil:
    section.add "PlatformArn", valid_600311
  var valid_600312 = formData.getOrDefault("TemplateName")
  valid_600312 = validateParameter(valid_600312, JString, required = false,
                                 default = nil)
  if valid_600312 != nil:
    section.add "TemplateName", valid_600312
  var valid_600313 = formData.getOrDefault("Description")
  valid_600313 = validateParameter(valid_600313, JString, required = false,
                                 default = nil)
  if valid_600313 != nil:
    section.add "Description", valid_600313
  var valid_600314 = formData.getOrDefault("Tier.Version")
  valid_600314 = validateParameter(valid_600314, JString, required = false,
                                 default = nil)
  if valid_600314 != nil:
    section.add "Tier.Version", valid_600314
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600315: Call_PostCreateEnvironment_600288; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Launches an environment for the specified application using the specified configuration.
  ## 
  let valid = call_600315.validator(path, query, header, formData, body)
  let scheme = call_600315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600315.url(scheme.get, call_600315.host, call_600315.base,
                         call_600315.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600315, url, valid)

proc call*(call_600316: Call_PostCreateEnvironment_600288; ApplicationName: string;
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
  var query_600317 = newJObject()
  var formData_600318 = newJObject()
  add(formData_600318, "Tier.Name", newJString(TierName))
  if OptionsToRemove != nil:
    formData_600318.add "OptionsToRemove", OptionsToRemove
  add(formData_600318, "VersionLabel", newJString(VersionLabel))
  if OptionSettings != nil:
    formData_600318.add "OptionSettings", OptionSettings
  add(formData_600318, "GroupName", newJString(GroupName))
  if Tags != nil:
    formData_600318.add "Tags", Tags
  add(formData_600318, "CNAMEPrefix", newJString(CNAMEPrefix))
  add(formData_600318, "SolutionStackName", newJString(SolutionStackName))
  add(formData_600318, "EnvironmentName", newJString(EnvironmentName))
  add(formData_600318, "Tier.Type", newJString(TierType))
  add(query_600317, "Action", newJString(Action))
  add(formData_600318, "ApplicationName", newJString(ApplicationName))
  add(formData_600318, "PlatformArn", newJString(PlatformArn))
  add(formData_600318, "TemplateName", newJString(TemplateName))
  add(query_600317, "Version", newJString(Version))
  add(formData_600318, "Description", newJString(Description))
  add(formData_600318, "Tier.Version", newJString(TierVersion))
  result = call_600316.call(nil, query_600317, nil, formData_600318, nil)

var postCreateEnvironment* = Call_PostCreateEnvironment_600288(
    name: "postCreateEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateEnvironment",
    validator: validate_PostCreateEnvironment_600289, base: "/",
    url: url_PostCreateEnvironment_600290, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEnvironment_600258 = ref object of OpenApiRestCall_599369
proc url_GetCreateEnvironment_600260(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateEnvironment_600259(path: JsonNode; query: JsonNode;
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
  var valid_600261 = query.getOrDefault("Tier.Name")
  valid_600261 = validateParameter(valid_600261, JString, required = false,
                                 default = nil)
  if valid_600261 != nil:
    section.add "Tier.Name", valid_600261
  var valid_600262 = query.getOrDefault("VersionLabel")
  valid_600262 = validateParameter(valid_600262, JString, required = false,
                                 default = nil)
  if valid_600262 != nil:
    section.add "VersionLabel", valid_600262
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_600263 = query.getOrDefault("ApplicationName")
  valid_600263 = validateParameter(valid_600263, JString, required = true,
                                 default = nil)
  if valid_600263 != nil:
    section.add "ApplicationName", valid_600263
  var valid_600264 = query.getOrDefault("Description")
  valid_600264 = validateParameter(valid_600264, JString, required = false,
                                 default = nil)
  if valid_600264 != nil:
    section.add "Description", valid_600264
  var valid_600265 = query.getOrDefault("OptionsToRemove")
  valid_600265 = validateParameter(valid_600265, JArray, required = false,
                                 default = nil)
  if valid_600265 != nil:
    section.add "OptionsToRemove", valid_600265
  var valid_600266 = query.getOrDefault("PlatformArn")
  valid_600266 = validateParameter(valid_600266, JString, required = false,
                                 default = nil)
  if valid_600266 != nil:
    section.add "PlatformArn", valid_600266
  var valid_600267 = query.getOrDefault("Tags")
  valid_600267 = validateParameter(valid_600267, JArray, required = false,
                                 default = nil)
  if valid_600267 != nil:
    section.add "Tags", valid_600267
  var valid_600268 = query.getOrDefault("EnvironmentName")
  valid_600268 = validateParameter(valid_600268, JString, required = false,
                                 default = nil)
  if valid_600268 != nil:
    section.add "EnvironmentName", valid_600268
  var valid_600269 = query.getOrDefault("Action")
  valid_600269 = validateParameter(valid_600269, JString, required = true,
                                 default = newJString("CreateEnvironment"))
  if valid_600269 != nil:
    section.add "Action", valid_600269
  var valid_600270 = query.getOrDefault("SolutionStackName")
  valid_600270 = validateParameter(valid_600270, JString, required = false,
                                 default = nil)
  if valid_600270 != nil:
    section.add "SolutionStackName", valid_600270
  var valid_600271 = query.getOrDefault("Tier.Version")
  valid_600271 = validateParameter(valid_600271, JString, required = false,
                                 default = nil)
  if valid_600271 != nil:
    section.add "Tier.Version", valid_600271
  var valid_600272 = query.getOrDefault("TemplateName")
  valid_600272 = validateParameter(valid_600272, JString, required = false,
                                 default = nil)
  if valid_600272 != nil:
    section.add "TemplateName", valid_600272
  var valid_600273 = query.getOrDefault("GroupName")
  valid_600273 = validateParameter(valid_600273, JString, required = false,
                                 default = nil)
  if valid_600273 != nil:
    section.add "GroupName", valid_600273
  var valid_600274 = query.getOrDefault("OptionSettings")
  valid_600274 = validateParameter(valid_600274, JArray, required = false,
                                 default = nil)
  if valid_600274 != nil:
    section.add "OptionSettings", valid_600274
  var valid_600275 = query.getOrDefault("Tier.Type")
  valid_600275 = validateParameter(valid_600275, JString, required = false,
                                 default = nil)
  if valid_600275 != nil:
    section.add "Tier.Type", valid_600275
  var valid_600276 = query.getOrDefault("Version")
  valid_600276 = validateParameter(valid_600276, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600276 != nil:
    section.add "Version", valid_600276
  var valid_600277 = query.getOrDefault("CNAMEPrefix")
  valid_600277 = validateParameter(valid_600277, JString, required = false,
                                 default = nil)
  if valid_600277 != nil:
    section.add "CNAMEPrefix", valid_600277
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600278 = header.getOrDefault("X-Amz-Date")
  valid_600278 = validateParameter(valid_600278, JString, required = false,
                                 default = nil)
  if valid_600278 != nil:
    section.add "X-Amz-Date", valid_600278
  var valid_600279 = header.getOrDefault("X-Amz-Security-Token")
  valid_600279 = validateParameter(valid_600279, JString, required = false,
                                 default = nil)
  if valid_600279 != nil:
    section.add "X-Amz-Security-Token", valid_600279
  var valid_600280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600280 = validateParameter(valid_600280, JString, required = false,
                                 default = nil)
  if valid_600280 != nil:
    section.add "X-Amz-Content-Sha256", valid_600280
  var valid_600281 = header.getOrDefault("X-Amz-Algorithm")
  valid_600281 = validateParameter(valid_600281, JString, required = false,
                                 default = nil)
  if valid_600281 != nil:
    section.add "X-Amz-Algorithm", valid_600281
  var valid_600282 = header.getOrDefault("X-Amz-Signature")
  valid_600282 = validateParameter(valid_600282, JString, required = false,
                                 default = nil)
  if valid_600282 != nil:
    section.add "X-Amz-Signature", valid_600282
  var valid_600283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600283 = validateParameter(valid_600283, JString, required = false,
                                 default = nil)
  if valid_600283 != nil:
    section.add "X-Amz-SignedHeaders", valid_600283
  var valid_600284 = header.getOrDefault("X-Amz-Credential")
  valid_600284 = validateParameter(valid_600284, JString, required = false,
                                 default = nil)
  if valid_600284 != nil:
    section.add "X-Amz-Credential", valid_600284
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600285: Call_GetCreateEnvironment_600258; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Launches an environment for the specified application using the specified configuration.
  ## 
  let valid = call_600285.validator(path, query, header, formData, body)
  let scheme = call_600285.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600285.url(scheme.get, call_600285.host, call_600285.base,
                         call_600285.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600285, url, valid)

proc call*(call_600286: Call_GetCreateEnvironment_600258; ApplicationName: string;
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
  var query_600287 = newJObject()
  add(query_600287, "Tier.Name", newJString(TierName))
  add(query_600287, "VersionLabel", newJString(VersionLabel))
  add(query_600287, "ApplicationName", newJString(ApplicationName))
  add(query_600287, "Description", newJString(Description))
  if OptionsToRemove != nil:
    query_600287.add "OptionsToRemove", OptionsToRemove
  add(query_600287, "PlatformArn", newJString(PlatformArn))
  if Tags != nil:
    query_600287.add "Tags", Tags
  add(query_600287, "EnvironmentName", newJString(EnvironmentName))
  add(query_600287, "Action", newJString(Action))
  add(query_600287, "SolutionStackName", newJString(SolutionStackName))
  add(query_600287, "Tier.Version", newJString(TierVersion))
  add(query_600287, "TemplateName", newJString(TemplateName))
  add(query_600287, "GroupName", newJString(GroupName))
  if OptionSettings != nil:
    query_600287.add "OptionSettings", OptionSettings
  add(query_600287, "Tier.Type", newJString(TierType))
  add(query_600287, "Version", newJString(Version))
  add(query_600287, "CNAMEPrefix", newJString(CNAMEPrefix))
  result = call_600286.call(nil, query_600287, nil, nil, nil)

var getCreateEnvironment* = Call_GetCreateEnvironment_600258(
    name: "getCreateEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateEnvironment",
    validator: validate_GetCreateEnvironment_600259, base: "/",
    url: url_GetCreateEnvironment_600260, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreatePlatformVersion_600341 = ref object of OpenApiRestCall_599369
proc url_PostCreatePlatformVersion_600343(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreatePlatformVersion_600342(path: JsonNode; query: JsonNode;
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
  var valid_600344 = query.getOrDefault("Action")
  valid_600344 = validateParameter(valid_600344, JString, required = true,
                                 default = newJString("CreatePlatformVersion"))
  if valid_600344 != nil:
    section.add "Action", valid_600344
  var valid_600345 = query.getOrDefault("Version")
  valid_600345 = validateParameter(valid_600345, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600345 != nil:
    section.add "Version", valid_600345
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600346 = header.getOrDefault("X-Amz-Date")
  valid_600346 = validateParameter(valid_600346, JString, required = false,
                                 default = nil)
  if valid_600346 != nil:
    section.add "X-Amz-Date", valid_600346
  var valid_600347 = header.getOrDefault("X-Amz-Security-Token")
  valid_600347 = validateParameter(valid_600347, JString, required = false,
                                 default = nil)
  if valid_600347 != nil:
    section.add "X-Amz-Security-Token", valid_600347
  var valid_600348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600348 = validateParameter(valid_600348, JString, required = false,
                                 default = nil)
  if valid_600348 != nil:
    section.add "X-Amz-Content-Sha256", valid_600348
  var valid_600349 = header.getOrDefault("X-Amz-Algorithm")
  valid_600349 = validateParameter(valid_600349, JString, required = false,
                                 default = nil)
  if valid_600349 != nil:
    section.add "X-Amz-Algorithm", valid_600349
  var valid_600350 = header.getOrDefault("X-Amz-Signature")
  valid_600350 = validateParameter(valid_600350, JString, required = false,
                                 default = nil)
  if valid_600350 != nil:
    section.add "X-Amz-Signature", valid_600350
  var valid_600351 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600351 = validateParameter(valid_600351, JString, required = false,
                                 default = nil)
  if valid_600351 != nil:
    section.add "X-Amz-SignedHeaders", valid_600351
  var valid_600352 = header.getOrDefault("X-Amz-Credential")
  valid_600352 = validateParameter(valid_600352, JString, required = false,
                                 default = nil)
  if valid_600352 != nil:
    section.add "X-Amz-Credential", valid_600352
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
  var valid_600353 = formData.getOrDefault("PlatformName")
  valid_600353 = validateParameter(valid_600353, JString, required = true,
                                 default = nil)
  if valid_600353 != nil:
    section.add "PlatformName", valid_600353
  var valid_600354 = formData.getOrDefault("PlatformDefinitionBundle.S3Key")
  valid_600354 = validateParameter(valid_600354, JString, required = false,
                                 default = nil)
  if valid_600354 != nil:
    section.add "PlatformDefinitionBundle.S3Key", valid_600354
  var valid_600355 = formData.getOrDefault("OptionSettings")
  valid_600355 = validateParameter(valid_600355, JArray, required = false,
                                 default = nil)
  if valid_600355 != nil:
    section.add "OptionSettings", valid_600355
  var valid_600356 = formData.getOrDefault("Tags")
  valid_600356 = validateParameter(valid_600356, JArray, required = false,
                                 default = nil)
  if valid_600356 != nil:
    section.add "Tags", valid_600356
  var valid_600357 = formData.getOrDefault("EnvironmentName")
  valid_600357 = validateParameter(valid_600357, JString, required = false,
                                 default = nil)
  if valid_600357 != nil:
    section.add "EnvironmentName", valid_600357
  var valid_600358 = formData.getOrDefault("PlatformDefinitionBundle.S3Bucket")
  valid_600358 = validateParameter(valid_600358, JString, required = false,
                                 default = nil)
  if valid_600358 != nil:
    section.add "PlatformDefinitionBundle.S3Bucket", valid_600358
  var valid_600359 = formData.getOrDefault("PlatformVersion")
  valid_600359 = validateParameter(valid_600359, JString, required = true,
                                 default = nil)
  if valid_600359 != nil:
    section.add "PlatformVersion", valid_600359
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600360: Call_PostCreatePlatformVersion_600341; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new version of your custom platform.
  ## 
  let valid = call_600360.validator(path, query, header, formData, body)
  let scheme = call_600360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600360.url(scheme.get, call_600360.host, call_600360.base,
                         call_600360.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600360, url, valid)

proc call*(call_600361: Call_PostCreatePlatformVersion_600341;
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
  var query_600362 = newJObject()
  var formData_600363 = newJObject()
  add(formData_600363, "PlatformName", newJString(PlatformName))
  add(formData_600363, "PlatformDefinitionBundle.S3Key",
      newJString(PlatformDefinitionBundleS3Key))
  if OptionSettings != nil:
    formData_600363.add "OptionSettings", OptionSettings
  if Tags != nil:
    formData_600363.add "Tags", Tags
  add(formData_600363, "EnvironmentName", newJString(EnvironmentName))
  add(formData_600363, "PlatformDefinitionBundle.S3Bucket",
      newJString(PlatformDefinitionBundleS3Bucket))
  add(query_600362, "Action", newJString(Action))
  add(formData_600363, "PlatformVersion", newJString(PlatformVersion))
  add(query_600362, "Version", newJString(Version))
  result = call_600361.call(nil, query_600362, nil, formData_600363, nil)

var postCreatePlatformVersion* = Call_PostCreatePlatformVersion_600341(
    name: "postCreatePlatformVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreatePlatformVersion",
    validator: validate_PostCreatePlatformVersion_600342, base: "/",
    url: url_PostCreatePlatformVersion_600343,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreatePlatformVersion_600319 = ref object of OpenApiRestCall_599369
proc url_GetCreatePlatformVersion_600321(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreatePlatformVersion_600320(path: JsonNode; query: JsonNode;
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
  var valid_600322 = query.getOrDefault("Tags")
  valid_600322 = validateParameter(valid_600322, JArray, required = false,
                                 default = nil)
  if valid_600322 != nil:
    section.add "Tags", valid_600322
  var valid_600323 = query.getOrDefault("EnvironmentName")
  valid_600323 = validateParameter(valid_600323, JString, required = false,
                                 default = nil)
  if valid_600323 != nil:
    section.add "EnvironmentName", valid_600323
  var valid_600324 = query.getOrDefault("PlatformDefinitionBundle.S3Key")
  valid_600324 = validateParameter(valid_600324, JString, required = false,
                                 default = nil)
  if valid_600324 != nil:
    section.add "PlatformDefinitionBundle.S3Key", valid_600324
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600325 = query.getOrDefault("Action")
  valid_600325 = validateParameter(valid_600325, JString, required = true,
                                 default = newJString("CreatePlatformVersion"))
  if valid_600325 != nil:
    section.add "Action", valid_600325
  var valid_600326 = query.getOrDefault("OptionSettings")
  valid_600326 = validateParameter(valid_600326, JArray, required = false,
                                 default = nil)
  if valid_600326 != nil:
    section.add "OptionSettings", valid_600326
  var valid_600327 = query.getOrDefault("PlatformName")
  valid_600327 = validateParameter(valid_600327, JString, required = true,
                                 default = nil)
  if valid_600327 != nil:
    section.add "PlatformName", valid_600327
  var valid_600328 = query.getOrDefault("Version")
  valid_600328 = validateParameter(valid_600328, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600328 != nil:
    section.add "Version", valid_600328
  var valid_600329 = query.getOrDefault("PlatformDefinitionBundle.S3Bucket")
  valid_600329 = validateParameter(valid_600329, JString, required = false,
                                 default = nil)
  if valid_600329 != nil:
    section.add "PlatformDefinitionBundle.S3Bucket", valid_600329
  var valid_600330 = query.getOrDefault("PlatformVersion")
  valid_600330 = validateParameter(valid_600330, JString, required = true,
                                 default = nil)
  if valid_600330 != nil:
    section.add "PlatformVersion", valid_600330
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600331 = header.getOrDefault("X-Amz-Date")
  valid_600331 = validateParameter(valid_600331, JString, required = false,
                                 default = nil)
  if valid_600331 != nil:
    section.add "X-Amz-Date", valid_600331
  var valid_600332 = header.getOrDefault("X-Amz-Security-Token")
  valid_600332 = validateParameter(valid_600332, JString, required = false,
                                 default = nil)
  if valid_600332 != nil:
    section.add "X-Amz-Security-Token", valid_600332
  var valid_600333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600333 = validateParameter(valid_600333, JString, required = false,
                                 default = nil)
  if valid_600333 != nil:
    section.add "X-Amz-Content-Sha256", valid_600333
  var valid_600334 = header.getOrDefault("X-Amz-Algorithm")
  valid_600334 = validateParameter(valid_600334, JString, required = false,
                                 default = nil)
  if valid_600334 != nil:
    section.add "X-Amz-Algorithm", valid_600334
  var valid_600335 = header.getOrDefault("X-Amz-Signature")
  valid_600335 = validateParameter(valid_600335, JString, required = false,
                                 default = nil)
  if valid_600335 != nil:
    section.add "X-Amz-Signature", valid_600335
  var valid_600336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600336 = validateParameter(valid_600336, JString, required = false,
                                 default = nil)
  if valid_600336 != nil:
    section.add "X-Amz-SignedHeaders", valid_600336
  var valid_600337 = header.getOrDefault("X-Amz-Credential")
  valid_600337 = validateParameter(valid_600337, JString, required = false,
                                 default = nil)
  if valid_600337 != nil:
    section.add "X-Amz-Credential", valid_600337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600338: Call_GetCreatePlatformVersion_600319; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new version of your custom platform.
  ## 
  let valid = call_600338.validator(path, query, header, formData, body)
  let scheme = call_600338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600338.url(scheme.get, call_600338.host, call_600338.base,
                         call_600338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600338, url, valid)

proc call*(call_600339: Call_GetCreatePlatformVersion_600319; PlatformName: string;
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
  var query_600340 = newJObject()
  if Tags != nil:
    query_600340.add "Tags", Tags
  add(query_600340, "EnvironmentName", newJString(EnvironmentName))
  add(query_600340, "PlatformDefinitionBundle.S3Key",
      newJString(PlatformDefinitionBundleS3Key))
  add(query_600340, "Action", newJString(Action))
  if OptionSettings != nil:
    query_600340.add "OptionSettings", OptionSettings
  add(query_600340, "PlatformName", newJString(PlatformName))
  add(query_600340, "Version", newJString(Version))
  add(query_600340, "PlatformDefinitionBundle.S3Bucket",
      newJString(PlatformDefinitionBundleS3Bucket))
  add(query_600340, "PlatformVersion", newJString(PlatformVersion))
  result = call_600339.call(nil, query_600340, nil, nil, nil)

var getCreatePlatformVersion* = Call_GetCreatePlatformVersion_600319(
    name: "getCreatePlatformVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreatePlatformVersion",
    validator: validate_GetCreatePlatformVersion_600320, base: "/",
    url: url_GetCreatePlatformVersion_600321, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateStorageLocation_600379 = ref object of OpenApiRestCall_599369
proc url_PostCreateStorageLocation_600381(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateStorageLocation_600380(path: JsonNode; query: JsonNode;
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
  var valid_600382 = query.getOrDefault("Action")
  valid_600382 = validateParameter(valid_600382, JString, required = true,
                                 default = newJString("CreateStorageLocation"))
  if valid_600382 != nil:
    section.add "Action", valid_600382
  var valid_600383 = query.getOrDefault("Version")
  valid_600383 = validateParameter(valid_600383, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600383 != nil:
    section.add "Version", valid_600383
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600384 = header.getOrDefault("X-Amz-Date")
  valid_600384 = validateParameter(valid_600384, JString, required = false,
                                 default = nil)
  if valid_600384 != nil:
    section.add "X-Amz-Date", valid_600384
  var valid_600385 = header.getOrDefault("X-Amz-Security-Token")
  valid_600385 = validateParameter(valid_600385, JString, required = false,
                                 default = nil)
  if valid_600385 != nil:
    section.add "X-Amz-Security-Token", valid_600385
  var valid_600386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600386 = validateParameter(valid_600386, JString, required = false,
                                 default = nil)
  if valid_600386 != nil:
    section.add "X-Amz-Content-Sha256", valid_600386
  var valid_600387 = header.getOrDefault("X-Amz-Algorithm")
  valid_600387 = validateParameter(valid_600387, JString, required = false,
                                 default = nil)
  if valid_600387 != nil:
    section.add "X-Amz-Algorithm", valid_600387
  var valid_600388 = header.getOrDefault("X-Amz-Signature")
  valid_600388 = validateParameter(valid_600388, JString, required = false,
                                 default = nil)
  if valid_600388 != nil:
    section.add "X-Amz-Signature", valid_600388
  var valid_600389 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600389 = validateParameter(valid_600389, JString, required = false,
                                 default = nil)
  if valid_600389 != nil:
    section.add "X-Amz-SignedHeaders", valid_600389
  var valid_600390 = header.getOrDefault("X-Amz-Credential")
  valid_600390 = validateParameter(valid_600390, JString, required = false,
                                 default = nil)
  if valid_600390 != nil:
    section.add "X-Amz-Credential", valid_600390
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600391: Call_PostCreateStorageLocation_600379; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ## 
  let valid = call_600391.validator(path, query, header, formData, body)
  let scheme = call_600391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600391.url(scheme.get, call_600391.host, call_600391.base,
                         call_600391.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600391, url, valid)

proc call*(call_600392: Call_PostCreateStorageLocation_600379;
          Action: string = "CreateStorageLocation"; Version: string = "2010-12-01"): Recallable =
  ## postCreateStorageLocation
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600393 = newJObject()
  add(query_600393, "Action", newJString(Action))
  add(query_600393, "Version", newJString(Version))
  result = call_600392.call(nil, query_600393, nil, nil, nil)

var postCreateStorageLocation* = Call_PostCreateStorageLocation_600379(
    name: "postCreateStorageLocation", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateStorageLocation",
    validator: validate_PostCreateStorageLocation_600380, base: "/",
    url: url_PostCreateStorageLocation_600381,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateStorageLocation_600364 = ref object of OpenApiRestCall_599369
proc url_GetCreateStorageLocation_600366(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateStorageLocation_600365(path: JsonNode; query: JsonNode;
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
  var valid_600367 = query.getOrDefault("Action")
  valid_600367 = validateParameter(valid_600367, JString, required = true,
                                 default = newJString("CreateStorageLocation"))
  if valid_600367 != nil:
    section.add "Action", valid_600367
  var valid_600368 = query.getOrDefault("Version")
  valid_600368 = validateParameter(valid_600368, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600368 != nil:
    section.add "Version", valid_600368
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600369 = header.getOrDefault("X-Amz-Date")
  valid_600369 = validateParameter(valid_600369, JString, required = false,
                                 default = nil)
  if valid_600369 != nil:
    section.add "X-Amz-Date", valid_600369
  var valid_600370 = header.getOrDefault("X-Amz-Security-Token")
  valid_600370 = validateParameter(valid_600370, JString, required = false,
                                 default = nil)
  if valid_600370 != nil:
    section.add "X-Amz-Security-Token", valid_600370
  var valid_600371 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600371 = validateParameter(valid_600371, JString, required = false,
                                 default = nil)
  if valid_600371 != nil:
    section.add "X-Amz-Content-Sha256", valid_600371
  var valid_600372 = header.getOrDefault("X-Amz-Algorithm")
  valid_600372 = validateParameter(valid_600372, JString, required = false,
                                 default = nil)
  if valid_600372 != nil:
    section.add "X-Amz-Algorithm", valid_600372
  var valid_600373 = header.getOrDefault("X-Amz-Signature")
  valid_600373 = validateParameter(valid_600373, JString, required = false,
                                 default = nil)
  if valid_600373 != nil:
    section.add "X-Amz-Signature", valid_600373
  var valid_600374 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600374 = validateParameter(valid_600374, JString, required = false,
                                 default = nil)
  if valid_600374 != nil:
    section.add "X-Amz-SignedHeaders", valid_600374
  var valid_600375 = header.getOrDefault("X-Amz-Credential")
  valid_600375 = validateParameter(valid_600375, JString, required = false,
                                 default = nil)
  if valid_600375 != nil:
    section.add "X-Amz-Credential", valid_600375
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600376: Call_GetCreateStorageLocation_600364; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ## 
  let valid = call_600376.validator(path, query, header, formData, body)
  let scheme = call_600376.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600376.url(scheme.get, call_600376.host, call_600376.base,
                         call_600376.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600376, url, valid)

proc call*(call_600377: Call_GetCreateStorageLocation_600364;
          Action: string = "CreateStorageLocation"; Version: string = "2010-12-01"): Recallable =
  ## getCreateStorageLocation
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600378 = newJObject()
  add(query_600378, "Action", newJString(Action))
  add(query_600378, "Version", newJString(Version))
  result = call_600377.call(nil, query_600378, nil, nil, nil)

var getCreateStorageLocation* = Call_GetCreateStorageLocation_600364(
    name: "getCreateStorageLocation", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateStorageLocation",
    validator: validate_GetCreateStorageLocation_600365, base: "/",
    url: url_GetCreateStorageLocation_600366, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteApplication_600411 = ref object of OpenApiRestCall_599369
proc url_PostDeleteApplication_600413(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteApplication_600412(path: JsonNode; query: JsonNode;
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
  var valid_600414 = query.getOrDefault("Action")
  valid_600414 = validateParameter(valid_600414, JString, required = true,
                                 default = newJString("DeleteApplication"))
  if valid_600414 != nil:
    section.add "Action", valid_600414
  var valid_600415 = query.getOrDefault("Version")
  valid_600415 = validateParameter(valid_600415, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600415 != nil:
    section.add "Version", valid_600415
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600416 = header.getOrDefault("X-Amz-Date")
  valid_600416 = validateParameter(valid_600416, JString, required = false,
                                 default = nil)
  if valid_600416 != nil:
    section.add "X-Amz-Date", valid_600416
  var valid_600417 = header.getOrDefault("X-Amz-Security-Token")
  valid_600417 = validateParameter(valid_600417, JString, required = false,
                                 default = nil)
  if valid_600417 != nil:
    section.add "X-Amz-Security-Token", valid_600417
  var valid_600418 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600418 = validateParameter(valid_600418, JString, required = false,
                                 default = nil)
  if valid_600418 != nil:
    section.add "X-Amz-Content-Sha256", valid_600418
  var valid_600419 = header.getOrDefault("X-Amz-Algorithm")
  valid_600419 = validateParameter(valid_600419, JString, required = false,
                                 default = nil)
  if valid_600419 != nil:
    section.add "X-Amz-Algorithm", valid_600419
  var valid_600420 = header.getOrDefault("X-Amz-Signature")
  valid_600420 = validateParameter(valid_600420, JString, required = false,
                                 default = nil)
  if valid_600420 != nil:
    section.add "X-Amz-Signature", valid_600420
  var valid_600421 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600421 = validateParameter(valid_600421, JString, required = false,
                                 default = nil)
  if valid_600421 != nil:
    section.add "X-Amz-SignedHeaders", valid_600421
  var valid_600422 = header.getOrDefault("X-Amz-Credential")
  valid_600422 = validateParameter(valid_600422, JString, required = false,
                                 default = nil)
  if valid_600422 != nil:
    section.add "X-Amz-Credential", valid_600422
  result.add "header", section
  ## parameters in `formData` object:
  ##   TerminateEnvByForce: JBool
  ##                      : When set to true, running environments will be terminated before deleting the application.
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to delete.
  section = newJObject()
  var valid_600423 = formData.getOrDefault("TerminateEnvByForce")
  valid_600423 = validateParameter(valid_600423, JBool, required = false, default = nil)
  if valid_600423 != nil:
    section.add "TerminateEnvByForce", valid_600423
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_600424 = formData.getOrDefault("ApplicationName")
  valid_600424 = validateParameter(valid_600424, JString, required = true,
                                 default = nil)
  if valid_600424 != nil:
    section.add "ApplicationName", valid_600424
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600425: Call_PostDeleteApplication_600411; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified application along with all associated versions and configurations. The application versions will not be deleted from your Amazon S3 bucket.</p> <note> <p>You cannot delete an application that has a running environment.</p> </note>
  ## 
  let valid = call_600425.validator(path, query, header, formData, body)
  let scheme = call_600425.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600425.url(scheme.get, call_600425.host, call_600425.base,
                         call_600425.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600425, url, valid)

proc call*(call_600426: Call_PostDeleteApplication_600411; ApplicationName: string;
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
  var query_600427 = newJObject()
  var formData_600428 = newJObject()
  add(formData_600428, "TerminateEnvByForce", newJBool(TerminateEnvByForce))
  add(query_600427, "Action", newJString(Action))
  add(formData_600428, "ApplicationName", newJString(ApplicationName))
  add(query_600427, "Version", newJString(Version))
  result = call_600426.call(nil, query_600427, nil, formData_600428, nil)

var postDeleteApplication* = Call_PostDeleteApplication_600411(
    name: "postDeleteApplication", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=DeleteApplication",
    validator: validate_PostDeleteApplication_600412, base: "/",
    url: url_PostDeleteApplication_600413, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteApplication_600394 = ref object of OpenApiRestCall_599369
proc url_GetDeleteApplication_600396(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteApplication_600395(path: JsonNode; query: JsonNode;
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
  var valid_600397 = query.getOrDefault("TerminateEnvByForce")
  valid_600397 = validateParameter(valid_600397, JBool, required = false, default = nil)
  if valid_600397 != nil:
    section.add "TerminateEnvByForce", valid_600397
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_600398 = query.getOrDefault("ApplicationName")
  valid_600398 = validateParameter(valid_600398, JString, required = true,
                                 default = nil)
  if valid_600398 != nil:
    section.add "ApplicationName", valid_600398
  var valid_600399 = query.getOrDefault("Action")
  valid_600399 = validateParameter(valid_600399, JString, required = true,
                                 default = newJString("DeleteApplication"))
  if valid_600399 != nil:
    section.add "Action", valid_600399
  var valid_600400 = query.getOrDefault("Version")
  valid_600400 = validateParameter(valid_600400, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600400 != nil:
    section.add "Version", valid_600400
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600401 = header.getOrDefault("X-Amz-Date")
  valid_600401 = validateParameter(valid_600401, JString, required = false,
                                 default = nil)
  if valid_600401 != nil:
    section.add "X-Amz-Date", valid_600401
  var valid_600402 = header.getOrDefault("X-Amz-Security-Token")
  valid_600402 = validateParameter(valid_600402, JString, required = false,
                                 default = nil)
  if valid_600402 != nil:
    section.add "X-Amz-Security-Token", valid_600402
  var valid_600403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600403 = validateParameter(valid_600403, JString, required = false,
                                 default = nil)
  if valid_600403 != nil:
    section.add "X-Amz-Content-Sha256", valid_600403
  var valid_600404 = header.getOrDefault("X-Amz-Algorithm")
  valid_600404 = validateParameter(valid_600404, JString, required = false,
                                 default = nil)
  if valid_600404 != nil:
    section.add "X-Amz-Algorithm", valid_600404
  var valid_600405 = header.getOrDefault("X-Amz-Signature")
  valid_600405 = validateParameter(valid_600405, JString, required = false,
                                 default = nil)
  if valid_600405 != nil:
    section.add "X-Amz-Signature", valid_600405
  var valid_600406 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600406 = validateParameter(valid_600406, JString, required = false,
                                 default = nil)
  if valid_600406 != nil:
    section.add "X-Amz-SignedHeaders", valid_600406
  var valid_600407 = header.getOrDefault("X-Amz-Credential")
  valid_600407 = validateParameter(valid_600407, JString, required = false,
                                 default = nil)
  if valid_600407 != nil:
    section.add "X-Amz-Credential", valid_600407
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600408: Call_GetDeleteApplication_600394; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified application along with all associated versions and configurations. The application versions will not be deleted from your Amazon S3 bucket.</p> <note> <p>You cannot delete an application that has a running environment.</p> </note>
  ## 
  let valid = call_600408.validator(path, query, header, formData, body)
  let scheme = call_600408.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600408.url(scheme.get, call_600408.host, call_600408.base,
                         call_600408.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600408, url, valid)

proc call*(call_600409: Call_GetDeleteApplication_600394; ApplicationName: string;
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
  var query_600410 = newJObject()
  add(query_600410, "TerminateEnvByForce", newJBool(TerminateEnvByForce))
  add(query_600410, "ApplicationName", newJString(ApplicationName))
  add(query_600410, "Action", newJString(Action))
  add(query_600410, "Version", newJString(Version))
  result = call_600409.call(nil, query_600410, nil, nil, nil)

var getDeleteApplication* = Call_GetDeleteApplication_600394(
    name: "getDeleteApplication", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=DeleteApplication",
    validator: validate_GetDeleteApplication_600395, base: "/",
    url: url_GetDeleteApplication_600396, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteApplicationVersion_600447 = ref object of OpenApiRestCall_599369
proc url_PostDeleteApplicationVersion_600449(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteApplicationVersion_600448(path: JsonNode; query: JsonNode;
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
  var valid_600450 = query.getOrDefault("Action")
  valid_600450 = validateParameter(valid_600450, JString, required = true, default = newJString(
      "DeleteApplicationVersion"))
  if valid_600450 != nil:
    section.add "Action", valid_600450
  var valid_600451 = query.getOrDefault("Version")
  valid_600451 = validateParameter(valid_600451, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600451 != nil:
    section.add "Version", valid_600451
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600452 = header.getOrDefault("X-Amz-Date")
  valid_600452 = validateParameter(valid_600452, JString, required = false,
                                 default = nil)
  if valid_600452 != nil:
    section.add "X-Amz-Date", valid_600452
  var valid_600453 = header.getOrDefault("X-Amz-Security-Token")
  valid_600453 = validateParameter(valid_600453, JString, required = false,
                                 default = nil)
  if valid_600453 != nil:
    section.add "X-Amz-Security-Token", valid_600453
  var valid_600454 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600454 = validateParameter(valid_600454, JString, required = false,
                                 default = nil)
  if valid_600454 != nil:
    section.add "X-Amz-Content-Sha256", valid_600454
  var valid_600455 = header.getOrDefault("X-Amz-Algorithm")
  valid_600455 = validateParameter(valid_600455, JString, required = false,
                                 default = nil)
  if valid_600455 != nil:
    section.add "X-Amz-Algorithm", valid_600455
  var valid_600456 = header.getOrDefault("X-Amz-Signature")
  valid_600456 = validateParameter(valid_600456, JString, required = false,
                                 default = nil)
  if valid_600456 != nil:
    section.add "X-Amz-Signature", valid_600456
  var valid_600457 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600457 = validateParameter(valid_600457, JString, required = false,
                                 default = nil)
  if valid_600457 != nil:
    section.add "X-Amz-SignedHeaders", valid_600457
  var valid_600458 = header.getOrDefault("X-Amz-Credential")
  valid_600458 = validateParameter(valid_600458, JString, required = false,
                                 default = nil)
  if valid_600458 != nil:
    section.add "X-Amz-Credential", valid_600458
  result.add "header", section
  ## parameters in `formData` object:
  ##   DeleteSourceBundle: JBool
  ##                     : Set to <code>true</code> to delete the source bundle from your storage bucket. Otherwise, the application version is deleted only from Elastic Beanstalk and the source bundle remains in Amazon S3.
  ##   VersionLabel: JString (required)
  ##               : The label of the version to delete.
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to which the version belongs.
  section = newJObject()
  var valid_600459 = formData.getOrDefault("DeleteSourceBundle")
  valid_600459 = validateParameter(valid_600459, JBool, required = false, default = nil)
  if valid_600459 != nil:
    section.add "DeleteSourceBundle", valid_600459
  assert formData != nil,
        "formData argument is necessary due to required `VersionLabel` field"
  var valid_600460 = formData.getOrDefault("VersionLabel")
  valid_600460 = validateParameter(valid_600460, JString, required = true,
                                 default = nil)
  if valid_600460 != nil:
    section.add "VersionLabel", valid_600460
  var valid_600461 = formData.getOrDefault("ApplicationName")
  valid_600461 = validateParameter(valid_600461, JString, required = true,
                                 default = nil)
  if valid_600461 != nil:
    section.add "ApplicationName", valid_600461
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600462: Call_PostDeleteApplicationVersion_600447; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified version from the specified application.</p> <note> <p>You cannot delete an application version that is associated with a running environment.</p> </note>
  ## 
  let valid = call_600462.validator(path, query, header, formData, body)
  let scheme = call_600462.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600462.url(scheme.get, call_600462.host, call_600462.base,
                         call_600462.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600462, url, valid)

proc call*(call_600463: Call_PostDeleteApplicationVersion_600447;
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
  var query_600464 = newJObject()
  var formData_600465 = newJObject()
  add(formData_600465, "DeleteSourceBundle", newJBool(DeleteSourceBundle))
  add(formData_600465, "VersionLabel", newJString(VersionLabel))
  add(query_600464, "Action", newJString(Action))
  add(formData_600465, "ApplicationName", newJString(ApplicationName))
  add(query_600464, "Version", newJString(Version))
  result = call_600463.call(nil, query_600464, nil, formData_600465, nil)

var postDeleteApplicationVersion* = Call_PostDeleteApplicationVersion_600447(
    name: "postDeleteApplicationVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteApplicationVersion",
    validator: validate_PostDeleteApplicationVersion_600448, base: "/",
    url: url_PostDeleteApplicationVersion_600449,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteApplicationVersion_600429 = ref object of OpenApiRestCall_599369
proc url_GetDeleteApplicationVersion_600431(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteApplicationVersion_600430(path: JsonNode; query: JsonNode;
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
  var valid_600432 = query.getOrDefault("VersionLabel")
  valid_600432 = validateParameter(valid_600432, JString, required = true,
                                 default = nil)
  if valid_600432 != nil:
    section.add "VersionLabel", valid_600432
  var valid_600433 = query.getOrDefault("ApplicationName")
  valid_600433 = validateParameter(valid_600433, JString, required = true,
                                 default = nil)
  if valid_600433 != nil:
    section.add "ApplicationName", valid_600433
  var valid_600434 = query.getOrDefault("Action")
  valid_600434 = validateParameter(valid_600434, JString, required = true, default = newJString(
      "DeleteApplicationVersion"))
  if valid_600434 != nil:
    section.add "Action", valid_600434
  var valid_600435 = query.getOrDefault("DeleteSourceBundle")
  valid_600435 = validateParameter(valid_600435, JBool, required = false, default = nil)
  if valid_600435 != nil:
    section.add "DeleteSourceBundle", valid_600435
  var valid_600436 = query.getOrDefault("Version")
  valid_600436 = validateParameter(valid_600436, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600436 != nil:
    section.add "Version", valid_600436
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600437 = header.getOrDefault("X-Amz-Date")
  valid_600437 = validateParameter(valid_600437, JString, required = false,
                                 default = nil)
  if valid_600437 != nil:
    section.add "X-Amz-Date", valid_600437
  var valid_600438 = header.getOrDefault("X-Amz-Security-Token")
  valid_600438 = validateParameter(valid_600438, JString, required = false,
                                 default = nil)
  if valid_600438 != nil:
    section.add "X-Amz-Security-Token", valid_600438
  var valid_600439 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600439 = validateParameter(valid_600439, JString, required = false,
                                 default = nil)
  if valid_600439 != nil:
    section.add "X-Amz-Content-Sha256", valid_600439
  var valid_600440 = header.getOrDefault("X-Amz-Algorithm")
  valid_600440 = validateParameter(valid_600440, JString, required = false,
                                 default = nil)
  if valid_600440 != nil:
    section.add "X-Amz-Algorithm", valid_600440
  var valid_600441 = header.getOrDefault("X-Amz-Signature")
  valid_600441 = validateParameter(valid_600441, JString, required = false,
                                 default = nil)
  if valid_600441 != nil:
    section.add "X-Amz-Signature", valid_600441
  var valid_600442 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600442 = validateParameter(valid_600442, JString, required = false,
                                 default = nil)
  if valid_600442 != nil:
    section.add "X-Amz-SignedHeaders", valid_600442
  var valid_600443 = header.getOrDefault("X-Amz-Credential")
  valid_600443 = validateParameter(valid_600443, JString, required = false,
                                 default = nil)
  if valid_600443 != nil:
    section.add "X-Amz-Credential", valid_600443
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600444: Call_GetDeleteApplicationVersion_600429; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified version from the specified application.</p> <note> <p>You cannot delete an application version that is associated with a running environment.</p> </note>
  ## 
  let valid = call_600444.validator(path, query, header, formData, body)
  let scheme = call_600444.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600444.url(scheme.get, call_600444.host, call_600444.base,
                         call_600444.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600444, url, valid)

proc call*(call_600445: Call_GetDeleteApplicationVersion_600429;
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
  var query_600446 = newJObject()
  add(query_600446, "VersionLabel", newJString(VersionLabel))
  add(query_600446, "ApplicationName", newJString(ApplicationName))
  add(query_600446, "Action", newJString(Action))
  add(query_600446, "DeleteSourceBundle", newJBool(DeleteSourceBundle))
  add(query_600446, "Version", newJString(Version))
  result = call_600445.call(nil, query_600446, nil, nil, nil)

var getDeleteApplicationVersion* = Call_GetDeleteApplicationVersion_600429(
    name: "getDeleteApplicationVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteApplicationVersion",
    validator: validate_GetDeleteApplicationVersion_600430, base: "/",
    url: url_GetDeleteApplicationVersion_600431,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteConfigurationTemplate_600483 = ref object of OpenApiRestCall_599369
proc url_PostDeleteConfigurationTemplate_600485(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteConfigurationTemplate_600484(path: JsonNode;
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
  var valid_600486 = query.getOrDefault("Action")
  valid_600486 = validateParameter(valid_600486, JString, required = true, default = newJString(
      "DeleteConfigurationTemplate"))
  if valid_600486 != nil:
    section.add "Action", valid_600486
  var valid_600487 = query.getOrDefault("Version")
  valid_600487 = validateParameter(valid_600487, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600487 != nil:
    section.add "Version", valid_600487
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600488 = header.getOrDefault("X-Amz-Date")
  valid_600488 = validateParameter(valid_600488, JString, required = false,
                                 default = nil)
  if valid_600488 != nil:
    section.add "X-Amz-Date", valid_600488
  var valid_600489 = header.getOrDefault("X-Amz-Security-Token")
  valid_600489 = validateParameter(valid_600489, JString, required = false,
                                 default = nil)
  if valid_600489 != nil:
    section.add "X-Amz-Security-Token", valid_600489
  var valid_600490 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600490 = validateParameter(valid_600490, JString, required = false,
                                 default = nil)
  if valid_600490 != nil:
    section.add "X-Amz-Content-Sha256", valid_600490
  var valid_600491 = header.getOrDefault("X-Amz-Algorithm")
  valid_600491 = validateParameter(valid_600491, JString, required = false,
                                 default = nil)
  if valid_600491 != nil:
    section.add "X-Amz-Algorithm", valid_600491
  var valid_600492 = header.getOrDefault("X-Amz-Signature")
  valid_600492 = validateParameter(valid_600492, JString, required = false,
                                 default = nil)
  if valid_600492 != nil:
    section.add "X-Amz-Signature", valid_600492
  var valid_600493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600493 = validateParameter(valid_600493, JString, required = false,
                                 default = nil)
  if valid_600493 != nil:
    section.add "X-Amz-SignedHeaders", valid_600493
  var valid_600494 = header.getOrDefault("X-Amz-Credential")
  valid_600494 = validateParameter(valid_600494, JString, required = false,
                                 default = nil)
  if valid_600494 != nil:
    section.add "X-Amz-Credential", valid_600494
  result.add "header", section
  ## parameters in `formData` object:
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to delete the configuration template from.
  ##   TemplateName: JString (required)
  ##               : The name of the configuration template to delete.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_600495 = formData.getOrDefault("ApplicationName")
  valid_600495 = validateParameter(valid_600495, JString, required = true,
                                 default = nil)
  if valid_600495 != nil:
    section.add "ApplicationName", valid_600495
  var valid_600496 = formData.getOrDefault("TemplateName")
  valid_600496 = validateParameter(valid_600496, JString, required = true,
                                 default = nil)
  if valid_600496 != nil:
    section.add "TemplateName", valid_600496
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600497: Call_PostDeleteConfigurationTemplate_600483;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes the specified configuration template.</p> <note> <p>When you launch an environment using a configuration template, the environment gets a copy of the template. You can delete or modify the environment's copy of the template without affecting the running environment.</p> </note>
  ## 
  let valid = call_600497.validator(path, query, header, formData, body)
  let scheme = call_600497.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600497.url(scheme.get, call_600497.host, call_600497.base,
                         call_600497.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600497, url, valid)

proc call*(call_600498: Call_PostDeleteConfigurationTemplate_600483;
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
  var query_600499 = newJObject()
  var formData_600500 = newJObject()
  add(query_600499, "Action", newJString(Action))
  add(formData_600500, "ApplicationName", newJString(ApplicationName))
  add(formData_600500, "TemplateName", newJString(TemplateName))
  add(query_600499, "Version", newJString(Version))
  result = call_600498.call(nil, query_600499, nil, formData_600500, nil)

var postDeleteConfigurationTemplate* = Call_PostDeleteConfigurationTemplate_600483(
    name: "postDeleteConfigurationTemplate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteConfigurationTemplate",
    validator: validate_PostDeleteConfigurationTemplate_600484, base: "/",
    url: url_PostDeleteConfigurationTemplate_600485,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteConfigurationTemplate_600466 = ref object of OpenApiRestCall_599369
proc url_GetDeleteConfigurationTemplate_600468(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteConfigurationTemplate_600467(path: JsonNode;
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
  var valid_600469 = query.getOrDefault("ApplicationName")
  valid_600469 = validateParameter(valid_600469, JString, required = true,
                                 default = nil)
  if valid_600469 != nil:
    section.add "ApplicationName", valid_600469
  var valid_600470 = query.getOrDefault("Action")
  valid_600470 = validateParameter(valid_600470, JString, required = true, default = newJString(
      "DeleteConfigurationTemplate"))
  if valid_600470 != nil:
    section.add "Action", valid_600470
  var valid_600471 = query.getOrDefault("TemplateName")
  valid_600471 = validateParameter(valid_600471, JString, required = true,
                                 default = nil)
  if valid_600471 != nil:
    section.add "TemplateName", valid_600471
  var valid_600472 = query.getOrDefault("Version")
  valid_600472 = validateParameter(valid_600472, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600472 != nil:
    section.add "Version", valid_600472
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600473 = header.getOrDefault("X-Amz-Date")
  valid_600473 = validateParameter(valid_600473, JString, required = false,
                                 default = nil)
  if valid_600473 != nil:
    section.add "X-Amz-Date", valid_600473
  var valid_600474 = header.getOrDefault("X-Amz-Security-Token")
  valid_600474 = validateParameter(valid_600474, JString, required = false,
                                 default = nil)
  if valid_600474 != nil:
    section.add "X-Amz-Security-Token", valid_600474
  var valid_600475 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600475 = validateParameter(valid_600475, JString, required = false,
                                 default = nil)
  if valid_600475 != nil:
    section.add "X-Amz-Content-Sha256", valid_600475
  var valid_600476 = header.getOrDefault("X-Amz-Algorithm")
  valid_600476 = validateParameter(valid_600476, JString, required = false,
                                 default = nil)
  if valid_600476 != nil:
    section.add "X-Amz-Algorithm", valid_600476
  var valid_600477 = header.getOrDefault("X-Amz-Signature")
  valid_600477 = validateParameter(valid_600477, JString, required = false,
                                 default = nil)
  if valid_600477 != nil:
    section.add "X-Amz-Signature", valid_600477
  var valid_600478 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600478 = validateParameter(valid_600478, JString, required = false,
                                 default = nil)
  if valid_600478 != nil:
    section.add "X-Amz-SignedHeaders", valid_600478
  var valid_600479 = header.getOrDefault("X-Amz-Credential")
  valid_600479 = validateParameter(valid_600479, JString, required = false,
                                 default = nil)
  if valid_600479 != nil:
    section.add "X-Amz-Credential", valid_600479
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600480: Call_GetDeleteConfigurationTemplate_600466; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified configuration template.</p> <note> <p>When you launch an environment using a configuration template, the environment gets a copy of the template. You can delete or modify the environment's copy of the template without affecting the running environment.</p> </note>
  ## 
  let valid = call_600480.validator(path, query, header, formData, body)
  let scheme = call_600480.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600480.url(scheme.get, call_600480.host, call_600480.base,
                         call_600480.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600480, url, valid)

proc call*(call_600481: Call_GetDeleteConfigurationTemplate_600466;
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
  var query_600482 = newJObject()
  add(query_600482, "ApplicationName", newJString(ApplicationName))
  add(query_600482, "Action", newJString(Action))
  add(query_600482, "TemplateName", newJString(TemplateName))
  add(query_600482, "Version", newJString(Version))
  result = call_600481.call(nil, query_600482, nil, nil, nil)

var getDeleteConfigurationTemplate* = Call_GetDeleteConfigurationTemplate_600466(
    name: "getDeleteConfigurationTemplate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteConfigurationTemplate",
    validator: validate_GetDeleteConfigurationTemplate_600467, base: "/",
    url: url_GetDeleteConfigurationTemplate_600468,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEnvironmentConfiguration_600518 = ref object of OpenApiRestCall_599369
proc url_PostDeleteEnvironmentConfiguration_600520(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteEnvironmentConfiguration_600519(path: JsonNode;
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
  var valid_600521 = query.getOrDefault("Action")
  valid_600521 = validateParameter(valid_600521, JString, required = true, default = newJString(
      "DeleteEnvironmentConfiguration"))
  if valid_600521 != nil:
    section.add "Action", valid_600521
  var valid_600522 = query.getOrDefault("Version")
  valid_600522 = validateParameter(valid_600522, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600522 != nil:
    section.add "Version", valid_600522
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600523 = header.getOrDefault("X-Amz-Date")
  valid_600523 = validateParameter(valid_600523, JString, required = false,
                                 default = nil)
  if valid_600523 != nil:
    section.add "X-Amz-Date", valid_600523
  var valid_600524 = header.getOrDefault("X-Amz-Security-Token")
  valid_600524 = validateParameter(valid_600524, JString, required = false,
                                 default = nil)
  if valid_600524 != nil:
    section.add "X-Amz-Security-Token", valid_600524
  var valid_600525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600525 = validateParameter(valid_600525, JString, required = false,
                                 default = nil)
  if valid_600525 != nil:
    section.add "X-Amz-Content-Sha256", valid_600525
  var valid_600526 = header.getOrDefault("X-Amz-Algorithm")
  valid_600526 = validateParameter(valid_600526, JString, required = false,
                                 default = nil)
  if valid_600526 != nil:
    section.add "X-Amz-Algorithm", valid_600526
  var valid_600527 = header.getOrDefault("X-Amz-Signature")
  valid_600527 = validateParameter(valid_600527, JString, required = false,
                                 default = nil)
  if valid_600527 != nil:
    section.add "X-Amz-Signature", valid_600527
  var valid_600528 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600528 = validateParameter(valid_600528, JString, required = false,
                                 default = nil)
  if valid_600528 != nil:
    section.add "X-Amz-SignedHeaders", valid_600528
  var valid_600529 = header.getOrDefault("X-Amz-Credential")
  valid_600529 = validateParameter(valid_600529, JString, required = false,
                                 default = nil)
  if valid_600529 != nil:
    section.add "X-Amz-Credential", valid_600529
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString (required)
  ##                  : The name of the environment to delete the draft configuration from.
  ##   ApplicationName: JString (required)
  ##                  : The name of the application the environment is associated with.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `EnvironmentName` field"
  var valid_600530 = formData.getOrDefault("EnvironmentName")
  valid_600530 = validateParameter(valid_600530, JString, required = true,
                                 default = nil)
  if valid_600530 != nil:
    section.add "EnvironmentName", valid_600530
  var valid_600531 = formData.getOrDefault("ApplicationName")
  valid_600531 = validateParameter(valid_600531, JString, required = true,
                                 default = nil)
  if valid_600531 != nil:
    section.add "ApplicationName", valid_600531
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600532: Call_PostDeleteEnvironmentConfiguration_600518;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes the draft configuration associated with the running environment.</p> <p>Updating a running environment with any configuration changes creates a draft configuration set. You can get the draft configuration using <a>DescribeConfigurationSettings</a> while the update is in progress or if the update fails. The <code>DeploymentStatus</code> for the draft configuration indicates whether the deployment is in process or has failed. The draft configuration remains in existence until it is deleted with this action.</p>
  ## 
  let valid = call_600532.validator(path, query, header, formData, body)
  let scheme = call_600532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600532.url(scheme.get, call_600532.host, call_600532.base,
                         call_600532.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600532, url, valid)

proc call*(call_600533: Call_PostDeleteEnvironmentConfiguration_600518;
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
  var query_600534 = newJObject()
  var formData_600535 = newJObject()
  add(formData_600535, "EnvironmentName", newJString(EnvironmentName))
  add(query_600534, "Action", newJString(Action))
  add(formData_600535, "ApplicationName", newJString(ApplicationName))
  add(query_600534, "Version", newJString(Version))
  result = call_600533.call(nil, query_600534, nil, formData_600535, nil)

var postDeleteEnvironmentConfiguration* = Call_PostDeleteEnvironmentConfiguration_600518(
    name: "postDeleteEnvironmentConfiguration", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteEnvironmentConfiguration",
    validator: validate_PostDeleteEnvironmentConfiguration_600519, base: "/",
    url: url_PostDeleteEnvironmentConfiguration_600520,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEnvironmentConfiguration_600501 = ref object of OpenApiRestCall_599369
proc url_GetDeleteEnvironmentConfiguration_600503(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteEnvironmentConfiguration_600502(path: JsonNode;
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
  var valid_600504 = query.getOrDefault("ApplicationName")
  valid_600504 = validateParameter(valid_600504, JString, required = true,
                                 default = nil)
  if valid_600504 != nil:
    section.add "ApplicationName", valid_600504
  var valid_600505 = query.getOrDefault("EnvironmentName")
  valid_600505 = validateParameter(valid_600505, JString, required = true,
                                 default = nil)
  if valid_600505 != nil:
    section.add "EnvironmentName", valid_600505
  var valid_600506 = query.getOrDefault("Action")
  valid_600506 = validateParameter(valid_600506, JString, required = true, default = newJString(
      "DeleteEnvironmentConfiguration"))
  if valid_600506 != nil:
    section.add "Action", valid_600506
  var valid_600507 = query.getOrDefault("Version")
  valid_600507 = validateParameter(valid_600507, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600507 != nil:
    section.add "Version", valid_600507
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600508 = header.getOrDefault("X-Amz-Date")
  valid_600508 = validateParameter(valid_600508, JString, required = false,
                                 default = nil)
  if valid_600508 != nil:
    section.add "X-Amz-Date", valid_600508
  var valid_600509 = header.getOrDefault("X-Amz-Security-Token")
  valid_600509 = validateParameter(valid_600509, JString, required = false,
                                 default = nil)
  if valid_600509 != nil:
    section.add "X-Amz-Security-Token", valid_600509
  var valid_600510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600510 = validateParameter(valid_600510, JString, required = false,
                                 default = nil)
  if valid_600510 != nil:
    section.add "X-Amz-Content-Sha256", valid_600510
  var valid_600511 = header.getOrDefault("X-Amz-Algorithm")
  valid_600511 = validateParameter(valid_600511, JString, required = false,
                                 default = nil)
  if valid_600511 != nil:
    section.add "X-Amz-Algorithm", valid_600511
  var valid_600512 = header.getOrDefault("X-Amz-Signature")
  valid_600512 = validateParameter(valid_600512, JString, required = false,
                                 default = nil)
  if valid_600512 != nil:
    section.add "X-Amz-Signature", valid_600512
  var valid_600513 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600513 = validateParameter(valid_600513, JString, required = false,
                                 default = nil)
  if valid_600513 != nil:
    section.add "X-Amz-SignedHeaders", valid_600513
  var valid_600514 = header.getOrDefault("X-Amz-Credential")
  valid_600514 = validateParameter(valid_600514, JString, required = false,
                                 default = nil)
  if valid_600514 != nil:
    section.add "X-Amz-Credential", valid_600514
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600515: Call_GetDeleteEnvironmentConfiguration_600501;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes the draft configuration associated with the running environment.</p> <p>Updating a running environment with any configuration changes creates a draft configuration set. You can get the draft configuration using <a>DescribeConfigurationSettings</a> while the update is in progress or if the update fails. The <code>DeploymentStatus</code> for the draft configuration indicates whether the deployment is in process or has failed. The draft configuration remains in existence until it is deleted with this action.</p>
  ## 
  let valid = call_600515.validator(path, query, header, formData, body)
  let scheme = call_600515.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600515.url(scheme.get, call_600515.host, call_600515.base,
                         call_600515.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600515, url, valid)

proc call*(call_600516: Call_GetDeleteEnvironmentConfiguration_600501;
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
  var query_600517 = newJObject()
  add(query_600517, "ApplicationName", newJString(ApplicationName))
  add(query_600517, "EnvironmentName", newJString(EnvironmentName))
  add(query_600517, "Action", newJString(Action))
  add(query_600517, "Version", newJString(Version))
  result = call_600516.call(nil, query_600517, nil, nil, nil)

var getDeleteEnvironmentConfiguration* = Call_GetDeleteEnvironmentConfiguration_600501(
    name: "getDeleteEnvironmentConfiguration", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteEnvironmentConfiguration",
    validator: validate_GetDeleteEnvironmentConfiguration_600502, base: "/",
    url: url_GetDeleteEnvironmentConfiguration_600503,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeletePlatformVersion_600552 = ref object of OpenApiRestCall_599369
proc url_PostDeletePlatformVersion_600554(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeletePlatformVersion_600553(path: JsonNode; query: JsonNode;
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
  var valid_600555 = query.getOrDefault("Action")
  valid_600555 = validateParameter(valid_600555, JString, required = true,
                                 default = newJString("DeletePlatformVersion"))
  if valid_600555 != nil:
    section.add "Action", valid_600555
  var valid_600556 = query.getOrDefault("Version")
  valid_600556 = validateParameter(valid_600556, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600556 != nil:
    section.add "Version", valid_600556
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600557 = header.getOrDefault("X-Amz-Date")
  valid_600557 = validateParameter(valid_600557, JString, required = false,
                                 default = nil)
  if valid_600557 != nil:
    section.add "X-Amz-Date", valid_600557
  var valid_600558 = header.getOrDefault("X-Amz-Security-Token")
  valid_600558 = validateParameter(valid_600558, JString, required = false,
                                 default = nil)
  if valid_600558 != nil:
    section.add "X-Amz-Security-Token", valid_600558
  var valid_600559 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600559 = validateParameter(valid_600559, JString, required = false,
                                 default = nil)
  if valid_600559 != nil:
    section.add "X-Amz-Content-Sha256", valid_600559
  var valid_600560 = header.getOrDefault("X-Amz-Algorithm")
  valid_600560 = validateParameter(valid_600560, JString, required = false,
                                 default = nil)
  if valid_600560 != nil:
    section.add "X-Amz-Algorithm", valid_600560
  var valid_600561 = header.getOrDefault("X-Amz-Signature")
  valid_600561 = validateParameter(valid_600561, JString, required = false,
                                 default = nil)
  if valid_600561 != nil:
    section.add "X-Amz-Signature", valid_600561
  var valid_600562 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600562 = validateParameter(valid_600562, JString, required = false,
                                 default = nil)
  if valid_600562 != nil:
    section.add "X-Amz-SignedHeaders", valid_600562
  var valid_600563 = header.getOrDefault("X-Amz-Credential")
  valid_600563 = validateParameter(valid_600563, JString, required = false,
                                 default = nil)
  if valid_600563 != nil:
    section.add "X-Amz-Credential", valid_600563
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformArn: JString
  ##              : The ARN of the version of the custom platform.
  section = newJObject()
  var valid_600564 = formData.getOrDefault("PlatformArn")
  valid_600564 = validateParameter(valid_600564, JString, required = false,
                                 default = nil)
  if valid_600564 != nil:
    section.add "PlatformArn", valid_600564
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600565: Call_PostDeletePlatformVersion_600552; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified version of a custom platform.
  ## 
  let valid = call_600565.validator(path, query, header, formData, body)
  let scheme = call_600565.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600565.url(scheme.get, call_600565.host, call_600565.base,
                         call_600565.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600565, url, valid)

proc call*(call_600566: Call_PostDeletePlatformVersion_600552;
          Action: string = "DeletePlatformVersion"; PlatformArn: string = "";
          Version: string = "2010-12-01"): Recallable =
  ## postDeletePlatformVersion
  ## Deletes the specified version of a custom platform.
  ##   Action: string (required)
  ##   PlatformArn: string
  ##              : The ARN of the version of the custom platform.
  ##   Version: string (required)
  var query_600567 = newJObject()
  var formData_600568 = newJObject()
  add(query_600567, "Action", newJString(Action))
  add(formData_600568, "PlatformArn", newJString(PlatformArn))
  add(query_600567, "Version", newJString(Version))
  result = call_600566.call(nil, query_600567, nil, formData_600568, nil)

var postDeletePlatformVersion* = Call_PostDeletePlatformVersion_600552(
    name: "postDeletePlatformVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeletePlatformVersion",
    validator: validate_PostDeletePlatformVersion_600553, base: "/",
    url: url_PostDeletePlatformVersion_600554,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeletePlatformVersion_600536 = ref object of OpenApiRestCall_599369
proc url_GetDeletePlatformVersion_600538(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeletePlatformVersion_600537(path: JsonNode; query: JsonNode;
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
  var valid_600539 = query.getOrDefault("PlatformArn")
  valid_600539 = validateParameter(valid_600539, JString, required = false,
                                 default = nil)
  if valid_600539 != nil:
    section.add "PlatformArn", valid_600539
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600540 = query.getOrDefault("Action")
  valid_600540 = validateParameter(valid_600540, JString, required = true,
                                 default = newJString("DeletePlatformVersion"))
  if valid_600540 != nil:
    section.add "Action", valid_600540
  var valid_600541 = query.getOrDefault("Version")
  valid_600541 = validateParameter(valid_600541, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600541 != nil:
    section.add "Version", valid_600541
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600542 = header.getOrDefault("X-Amz-Date")
  valid_600542 = validateParameter(valid_600542, JString, required = false,
                                 default = nil)
  if valid_600542 != nil:
    section.add "X-Amz-Date", valid_600542
  var valid_600543 = header.getOrDefault("X-Amz-Security-Token")
  valid_600543 = validateParameter(valid_600543, JString, required = false,
                                 default = nil)
  if valid_600543 != nil:
    section.add "X-Amz-Security-Token", valid_600543
  var valid_600544 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600544 = validateParameter(valid_600544, JString, required = false,
                                 default = nil)
  if valid_600544 != nil:
    section.add "X-Amz-Content-Sha256", valid_600544
  var valid_600545 = header.getOrDefault("X-Amz-Algorithm")
  valid_600545 = validateParameter(valid_600545, JString, required = false,
                                 default = nil)
  if valid_600545 != nil:
    section.add "X-Amz-Algorithm", valid_600545
  var valid_600546 = header.getOrDefault("X-Amz-Signature")
  valid_600546 = validateParameter(valid_600546, JString, required = false,
                                 default = nil)
  if valid_600546 != nil:
    section.add "X-Amz-Signature", valid_600546
  var valid_600547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600547 = validateParameter(valid_600547, JString, required = false,
                                 default = nil)
  if valid_600547 != nil:
    section.add "X-Amz-SignedHeaders", valid_600547
  var valid_600548 = header.getOrDefault("X-Amz-Credential")
  valid_600548 = validateParameter(valid_600548, JString, required = false,
                                 default = nil)
  if valid_600548 != nil:
    section.add "X-Amz-Credential", valid_600548
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600549: Call_GetDeletePlatformVersion_600536; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified version of a custom platform.
  ## 
  let valid = call_600549.validator(path, query, header, formData, body)
  let scheme = call_600549.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600549.url(scheme.get, call_600549.host, call_600549.base,
                         call_600549.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600549, url, valid)

proc call*(call_600550: Call_GetDeletePlatformVersion_600536;
          PlatformArn: string = ""; Action: string = "DeletePlatformVersion";
          Version: string = "2010-12-01"): Recallable =
  ## getDeletePlatformVersion
  ## Deletes the specified version of a custom platform.
  ##   PlatformArn: string
  ##              : The ARN of the version of the custom platform.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600551 = newJObject()
  add(query_600551, "PlatformArn", newJString(PlatformArn))
  add(query_600551, "Action", newJString(Action))
  add(query_600551, "Version", newJString(Version))
  result = call_600550.call(nil, query_600551, nil, nil, nil)

var getDeletePlatformVersion* = Call_GetDeletePlatformVersion_600536(
    name: "getDeletePlatformVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeletePlatformVersion",
    validator: validate_GetDeletePlatformVersion_600537, base: "/",
    url: url_GetDeletePlatformVersion_600538, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAccountAttributes_600584 = ref object of OpenApiRestCall_599369
proc url_PostDescribeAccountAttributes_600586(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeAccountAttributes_600585(path: JsonNode; query: JsonNode;
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
  var valid_600587 = query.getOrDefault("Action")
  valid_600587 = validateParameter(valid_600587, JString, required = true, default = newJString(
      "DescribeAccountAttributes"))
  if valid_600587 != nil:
    section.add "Action", valid_600587
  var valid_600588 = query.getOrDefault("Version")
  valid_600588 = validateParameter(valid_600588, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600588 != nil:
    section.add "Version", valid_600588
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600589 = header.getOrDefault("X-Amz-Date")
  valid_600589 = validateParameter(valid_600589, JString, required = false,
                                 default = nil)
  if valid_600589 != nil:
    section.add "X-Amz-Date", valid_600589
  var valid_600590 = header.getOrDefault("X-Amz-Security-Token")
  valid_600590 = validateParameter(valid_600590, JString, required = false,
                                 default = nil)
  if valid_600590 != nil:
    section.add "X-Amz-Security-Token", valid_600590
  var valid_600591 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600591 = validateParameter(valid_600591, JString, required = false,
                                 default = nil)
  if valid_600591 != nil:
    section.add "X-Amz-Content-Sha256", valid_600591
  var valid_600592 = header.getOrDefault("X-Amz-Algorithm")
  valid_600592 = validateParameter(valid_600592, JString, required = false,
                                 default = nil)
  if valid_600592 != nil:
    section.add "X-Amz-Algorithm", valid_600592
  var valid_600593 = header.getOrDefault("X-Amz-Signature")
  valid_600593 = validateParameter(valid_600593, JString, required = false,
                                 default = nil)
  if valid_600593 != nil:
    section.add "X-Amz-Signature", valid_600593
  var valid_600594 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600594 = validateParameter(valid_600594, JString, required = false,
                                 default = nil)
  if valid_600594 != nil:
    section.add "X-Amz-SignedHeaders", valid_600594
  var valid_600595 = header.getOrDefault("X-Amz-Credential")
  valid_600595 = validateParameter(valid_600595, JString, required = false,
                                 default = nil)
  if valid_600595 != nil:
    section.add "X-Amz-Credential", valid_600595
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600596: Call_PostDescribeAccountAttributes_600584; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ## 
  let valid = call_600596.validator(path, query, header, formData, body)
  let scheme = call_600596.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600596.url(scheme.get, call_600596.host, call_600596.base,
                         call_600596.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600596, url, valid)

proc call*(call_600597: Call_PostDescribeAccountAttributes_600584;
          Action: string = "DescribeAccountAttributes";
          Version: string = "2010-12-01"): Recallable =
  ## postDescribeAccountAttributes
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600598 = newJObject()
  add(query_600598, "Action", newJString(Action))
  add(query_600598, "Version", newJString(Version))
  result = call_600597.call(nil, query_600598, nil, nil, nil)

var postDescribeAccountAttributes* = Call_PostDescribeAccountAttributes_600584(
    name: "postDescribeAccountAttributes", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeAccountAttributes",
    validator: validate_PostDescribeAccountAttributes_600585, base: "/",
    url: url_PostDescribeAccountAttributes_600586,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAccountAttributes_600569 = ref object of OpenApiRestCall_599369
proc url_GetDescribeAccountAttributes_600571(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeAccountAttributes_600570(path: JsonNode; query: JsonNode;
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
  var valid_600572 = query.getOrDefault("Action")
  valid_600572 = validateParameter(valid_600572, JString, required = true, default = newJString(
      "DescribeAccountAttributes"))
  if valid_600572 != nil:
    section.add "Action", valid_600572
  var valid_600573 = query.getOrDefault("Version")
  valid_600573 = validateParameter(valid_600573, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600573 != nil:
    section.add "Version", valid_600573
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600574 = header.getOrDefault("X-Amz-Date")
  valid_600574 = validateParameter(valid_600574, JString, required = false,
                                 default = nil)
  if valid_600574 != nil:
    section.add "X-Amz-Date", valid_600574
  var valid_600575 = header.getOrDefault("X-Amz-Security-Token")
  valid_600575 = validateParameter(valid_600575, JString, required = false,
                                 default = nil)
  if valid_600575 != nil:
    section.add "X-Amz-Security-Token", valid_600575
  var valid_600576 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600576 = validateParameter(valid_600576, JString, required = false,
                                 default = nil)
  if valid_600576 != nil:
    section.add "X-Amz-Content-Sha256", valid_600576
  var valid_600577 = header.getOrDefault("X-Amz-Algorithm")
  valid_600577 = validateParameter(valid_600577, JString, required = false,
                                 default = nil)
  if valid_600577 != nil:
    section.add "X-Amz-Algorithm", valid_600577
  var valid_600578 = header.getOrDefault("X-Amz-Signature")
  valid_600578 = validateParameter(valid_600578, JString, required = false,
                                 default = nil)
  if valid_600578 != nil:
    section.add "X-Amz-Signature", valid_600578
  var valid_600579 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600579 = validateParameter(valid_600579, JString, required = false,
                                 default = nil)
  if valid_600579 != nil:
    section.add "X-Amz-SignedHeaders", valid_600579
  var valid_600580 = header.getOrDefault("X-Amz-Credential")
  valid_600580 = validateParameter(valid_600580, JString, required = false,
                                 default = nil)
  if valid_600580 != nil:
    section.add "X-Amz-Credential", valid_600580
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600581: Call_GetDescribeAccountAttributes_600569; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ## 
  let valid = call_600581.validator(path, query, header, formData, body)
  let scheme = call_600581.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600581.url(scheme.get, call_600581.host, call_600581.base,
                         call_600581.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600581, url, valid)

proc call*(call_600582: Call_GetDescribeAccountAttributes_600569;
          Action: string = "DescribeAccountAttributes";
          Version: string = "2010-12-01"): Recallable =
  ## getDescribeAccountAttributes
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600583 = newJObject()
  add(query_600583, "Action", newJString(Action))
  add(query_600583, "Version", newJString(Version))
  result = call_600582.call(nil, query_600583, nil, nil, nil)

var getDescribeAccountAttributes* = Call_GetDescribeAccountAttributes_600569(
    name: "getDescribeAccountAttributes", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeAccountAttributes",
    validator: validate_GetDescribeAccountAttributes_600570, base: "/",
    url: url_GetDescribeAccountAttributes_600571,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeApplicationVersions_600618 = ref object of OpenApiRestCall_599369
proc url_PostDescribeApplicationVersions_600620(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeApplicationVersions_600619(path: JsonNode;
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
  var valid_600621 = query.getOrDefault("Action")
  valid_600621 = validateParameter(valid_600621, JString, required = true, default = newJString(
      "DescribeApplicationVersions"))
  if valid_600621 != nil:
    section.add "Action", valid_600621
  var valid_600622 = query.getOrDefault("Version")
  valid_600622 = validateParameter(valid_600622, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600622 != nil:
    section.add "Version", valid_600622
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600623 = header.getOrDefault("X-Amz-Date")
  valid_600623 = validateParameter(valid_600623, JString, required = false,
                                 default = nil)
  if valid_600623 != nil:
    section.add "X-Amz-Date", valid_600623
  var valid_600624 = header.getOrDefault("X-Amz-Security-Token")
  valid_600624 = validateParameter(valid_600624, JString, required = false,
                                 default = nil)
  if valid_600624 != nil:
    section.add "X-Amz-Security-Token", valid_600624
  var valid_600625 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600625 = validateParameter(valid_600625, JString, required = false,
                                 default = nil)
  if valid_600625 != nil:
    section.add "X-Amz-Content-Sha256", valid_600625
  var valid_600626 = header.getOrDefault("X-Amz-Algorithm")
  valid_600626 = validateParameter(valid_600626, JString, required = false,
                                 default = nil)
  if valid_600626 != nil:
    section.add "X-Amz-Algorithm", valid_600626
  var valid_600627 = header.getOrDefault("X-Amz-Signature")
  valid_600627 = validateParameter(valid_600627, JString, required = false,
                                 default = nil)
  if valid_600627 != nil:
    section.add "X-Amz-Signature", valid_600627
  var valid_600628 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600628 = validateParameter(valid_600628, JString, required = false,
                                 default = nil)
  if valid_600628 != nil:
    section.add "X-Amz-SignedHeaders", valid_600628
  var valid_600629 = header.getOrDefault("X-Amz-Credential")
  valid_600629 = validateParameter(valid_600629, JString, required = false,
                                 default = nil)
  if valid_600629 != nil:
    section.add "X-Amz-Credential", valid_600629
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
  var valid_600630 = formData.getOrDefault("NextToken")
  valid_600630 = validateParameter(valid_600630, JString, required = false,
                                 default = nil)
  if valid_600630 != nil:
    section.add "NextToken", valid_600630
  var valid_600631 = formData.getOrDefault("ApplicationName")
  valid_600631 = validateParameter(valid_600631, JString, required = false,
                                 default = nil)
  if valid_600631 != nil:
    section.add "ApplicationName", valid_600631
  var valid_600632 = formData.getOrDefault("MaxRecords")
  valid_600632 = validateParameter(valid_600632, JInt, required = false, default = nil)
  if valid_600632 != nil:
    section.add "MaxRecords", valid_600632
  var valid_600633 = formData.getOrDefault("VersionLabels")
  valid_600633 = validateParameter(valid_600633, JArray, required = false,
                                 default = nil)
  if valid_600633 != nil:
    section.add "VersionLabels", valid_600633
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600634: Call_PostDescribeApplicationVersions_600618;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieve a list of application versions.
  ## 
  let valid = call_600634.validator(path, query, header, formData, body)
  let scheme = call_600634.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600634.url(scheme.get, call_600634.host, call_600634.base,
                         call_600634.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600634, url, valid)

proc call*(call_600635: Call_PostDescribeApplicationVersions_600618;
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
  var query_600636 = newJObject()
  var formData_600637 = newJObject()
  add(formData_600637, "NextToken", newJString(NextToken))
  add(query_600636, "Action", newJString(Action))
  add(formData_600637, "ApplicationName", newJString(ApplicationName))
  add(formData_600637, "MaxRecords", newJInt(MaxRecords))
  add(query_600636, "Version", newJString(Version))
  if VersionLabels != nil:
    formData_600637.add "VersionLabels", VersionLabels
  result = call_600635.call(nil, query_600636, nil, formData_600637, nil)

var postDescribeApplicationVersions* = Call_PostDescribeApplicationVersions_600618(
    name: "postDescribeApplicationVersions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplicationVersions",
    validator: validate_PostDescribeApplicationVersions_600619, base: "/",
    url: url_PostDescribeApplicationVersions_600620,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeApplicationVersions_600599 = ref object of OpenApiRestCall_599369
proc url_GetDescribeApplicationVersions_600601(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeApplicationVersions_600600(path: JsonNode;
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
  var valid_600602 = query.getOrDefault("MaxRecords")
  valid_600602 = validateParameter(valid_600602, JInt, required = false, default = nil)
  if valid_600602 != nil:
    section.add "MaxRecords", valid_600602
  var valid_600603 = query.getOrDefault("ApplicationName")
  valid_600603 = validateParameter(valid_600603, JString, required = false,
                                 default = nil)
  if valid_600603 != nil:
    section.add "ApplicationName", valid_600603
  var valid_600604 = query.getOrDefault("NextToken")
  valid_600604 = validateParameter(valid_600604, JString, required = false,
                                 default = nil)
  if valid_600604 != nil:
    section.add "NextToken", valid_600604
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600605 = query.getOrDefault("Action")
  valid_600605 = validateParameter(valid_600605, JString, required = true, default = newJString(
      "DescribeApplicationVersions"))
  if valid_600605 != nil:
    section.add "Action", valid_600605
  var valid_600606 = query.getOrDefault("VersionLabels")
  valid_600606 = validateParameter(valid_600606, JArray, required = false,
                                 default = nil)
  if valid_600606 != nil:
    section.add "VersionLabels", valid_600606
  var valid_600607 = query.getOrDefault("Version")
  valid_600607 = validateParameter(valid_600607, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600607 != nil:
    section.add "Version", valid_600607
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600608 = header.getOrDefault("X-Amz-Date")
  valid_600608 = validateParameter(valid_600608, JString, required = false,
                                 default = nil)
  if valid_600608 != nil:
    section.add "X-Amz-Date", valid_600608
  var valid_600609 = header.getOrDefault("X-Amz-Security-Token")
  valid_600609 = validateParameter(valid_600609, JString, required = false,
                                 default = nil)
  if valid_600609 != nil:
    section.add "X-Amz-Security-Token", valid_600609
  var valid_600610 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600610 = validateParameter(valid_600610, JString, required = false,
                                 default = nil)
  if valid_600610 != nil:
    section.add "X-Amz-Content-Sha256", valid_600610
  var valid_600611 = header.getOrDefault("X-Amz-Algorithm")
  valid_600611 = validateParameter(valid_600611, JString, required = false,
                                 default = nil)
  if valid_600611 != nil:
    section.add "X-Amz-Algorithm", valid_600611
  var valid_600612 = header.getOrDefault("X-Amz-Signature")
  valid_600612 = validateParameter(valid_600612, JString, required = false,
                                 default = nil)
  if valid_600612 != nil:
    section.add "X-Amz-Signature", valid_600612
  var valid_600613 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600613 = validateParameter(valid_600613, JString, required = false,
                                 default = nil)
  if valid_600613 != nil:
    section.add "X-Amz-SignedHeaders", valid_600613
  var valid_600614 = header.getOrDefault("X-Amz-Credential")
  valid_600614 = validateParameter(valid_600614, JString, required = false,
                                 default = nil)
  if valid_600614 != nil:
    section.add "X-Amz-Credential", valid_600614
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600615: Call_GetDescribeApplicationVersions_600599; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a list of application versions.
  ## 
  let valid = call_600615.validator(path, query, header, formData, body)
  let scheme = call_600615.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600615.url(scheme.get, call_600615.host, call_600615.base,
                         call_600615.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600615, url, valid)

proc call*(call_600616: Call_GetDescribeApplicationVersions_600599;
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
  var query_600617 = newJObject()
  add(query_600617, "MaxRecords", newJInt(MaxRecords))
  add(query_600617, "ApplicationName", newJString(ApplicationName))
  add(query_600617, "NextToken", newJString(NextToken))
  add(query_600617, "Action", newJString(Action))
  if VersionLabels != nil:
    query_600617.add "VersionLabels", VersionLabels
  add(query_600617, "Version", newJString(Version))
  result = call_600616.call(nil, query_600617, nil, nil, nil)

var getDescribeApplicationVersions* = Call_GetDescribeApplicationVersions_600599(
    name: "getDescribeApplicationVersions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplicationVersions",
    validator: validate_GetDescribeApplicationVersions_600600, base: "/",
    url: url_GetDescribeApplicationVersions_600601,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeApplications_600654 = ref object of OpenApiRestCall_599369
proc url_PostDescribeApplications_600656(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeApplications_600655(path: JsonNode; query: JsonNode;
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
  var valid_600657 = query.getOrDefault("Action")
  valid_600657 = validateParameter(valid_600657, JString, required = true,
                                 default = newJString("DescribeApplications"))
  if valid_600657 != nil:
    section.add "Action", valid_600657
  var valid_600658 = query.getOrDefault("Version")
  valid_600658 = validateParameter(valid_600658, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600658 != nil:
    section.add "Version", valid_600658
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600659 = header.getOrDefault("X-Amz-Date")
  valid_600659 = validateParameter(valid_600659, JString, required = false,
                                 default = nil)
  if valid_600659 != nil:
    section.add "X-Amz-Date", valid_600659
  var valid_600660 = header.getOrDefault("X-Amz-Security-Token")
  valid_600660 = validateParameter(valid_600660, JString, required = false,
                                 default = nil)
  if valid_600660 != nil:
    section.add "X-Amz-Security-Token", valid_600660
  var valid_600661 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600661 = validateParameter(valid_600661, JString, required = false,
                                 default = nil)
  if valid_600661 != nil:
    section.add "X-Amz-Content-Sha256", valid_600661
  var valid_600662 = header.getOrDefault("X-Amz-Algorithm")
  valid_600662 = validateParameter(valid_600662, JString, required = false,
                                 default = nil)
  if valid_600662 != nil:
    section.add "X-Amz-Algorithm", valid_600662
  var valid_600663 = header.getOrDefault("X-Amz-Signature")
  valid_600663 = validateParameter(valid_600663, JString, required = false,
                                 default = nil)
  if valid_600663 != nil:
    section.add "X-Amz-Signature", valid_600663
  var valid_600664 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600664 = validateParameter(valid_600664, JString, required = false,
                                 default = nil)
  if valid_600664 != nil:
    section.add "X-Amz-SignedHeaders", valid_600664
  var valid_600665 = header.getOrDefault("X-Amz-Credential")
  valid_600665 = validateParameter(valid_600665, JString, required = false,
                                 default = nil)
  if valid_600665 != nil:
    section.add "X-Amz-Credential", valid_600665
  result.add "header", section
  ## parameters in `formData` object:
  ##   ApplicationNames: JArray
  ##                   : If specified, AWS Elastic Beanstalk restricts the returned descriptions to only include those with the specified names.
  section = newJObject()
  var valid_600666 = formData.getOrDefault("ApplicationNames")
  valid_600666 = validateParameter(valid_600666, JArray, required = false,
                                 default = nil)
  if valid_600666 != nil:
    section.add "ApplicationNames", valid_600666
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600667: Call_PostDescribeApplications_600654; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the descriptions of existing applications.
  ## 
  let valid = call_600667.validator(path, query, header, formData, body)
  let scheme = call_600667.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600667.url(scheme.get, call_600667.host, call_600667.base,
                         call_600667.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600667, url, valid)

proc call*(call_600668: Call_PostDescribeApplications_600654;
          ApplicationNames: JsonNode = nil; Action: string = "DescribeApplications";
          Version: string = "2010-12-01"): Recallable =
  ## postDescribeApplications
  ## Returns the descriptions of existing applications.
  ##   ApplicationNames: JArray
  ##                   : If specified, AWS Elastic Beanstalk restricts the returned descriptions to only include those with the specified names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600669 = newJObject()
  var formData_600670 = newJObject()
  if ApplicationNames != nil:
    formData_600670.add "ApplicationNames", ApplicationNames
  add(query_600669, "Action", newJString(Action))
  add(query_600669, "Version", newJString(Version))
  result = call_600668.call(nil, query_600669, nil, formData_600670, nil)

var postDescribeApplications* = Call_PostDescribeApplications_600654(
    name: "postDescribeApplications", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplications",
    validator: validate_PostDescribeApplications_600655, base: "/",
    url: url_PostDescribeApplications_600656, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeApplications_600638 = ref object of OpenApiRestCall_599369
proc url_GetDescribeApplications_600640(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeApplications_600639(path: JsonNode; query: JsonNode;
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
  var valid_600641 = query.getOrDefault("ApplicationNames")
  valid_600641 = validateParameter(valid_600641, JArray, required = false,
                                 default = nil)
  if valid_600641 != nil:
    section.add "ApplicationNames", valid_600641
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600642 = query.getOrDefault("Action")
  valid_600642 = validateParameter(valid_600642, JString, required = true,
                                 default = newJString("DescribeApplications"))
  if valid_600642 != nil:
    section.add "Action", valid_600642
  var valid_600643 = query.getOrDefault("Version")
  valid_600643 = validateParameter(valid_600643, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600643 != nil:
    section.add "Version", valid_600643
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600644 = header.getOrDefault("X-Amz-Date")
  valid_600644 = validateParameter(valid_600644, JString, required = false,
                                 default = nil)
  if valid_600644 != nil:
    section.add "X-Amz-Date", valid_600644
  var valid_600645 = header.getOrDefault("X-Amz-Security-Token")
  valid_600645 = validateParameter(valid_600645, JString, required = false,
                                 default = nil)
  if valid_600645 != nil:
    section.add "X-Amz-Security-Token", valid_600645
  var valid_600646 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600646 = validateParameter(valid_600646, JString, required = false,
                                 default = nil)
  if valid_600646 != nil:
    section.add "X-Amz-Content-Sha256", valid_600646
  var valid_600647 = header.getOrDefault("X-Amz-Algorithm")
  valid_600647 = validateParameter(valid_600647, JString, required = false,
                                 default = nil)
  if valid_600647 != nil:
    section.add "X-Amz-Algorithm", valid_600647
  var valid_600648 = header.getOrDefault("X-Amz-Signature")
  valid_600648 = validateParameter(valid_600648, JString, required = false,
                                 default = nil)
  if valid_600648 != nil:
    section.add "X-Amz-Signature", valid_600648
  var valid_600649 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600649 = validateParameter(valid_600649, JString, required = false,
                                 default = nil)
  if valid_600649 != nil:
    section.add "X-Amz-SignedHeaders", valid_600649
  var valid_600650 = header.getOrDefault("X-Amz-Credential")
  valid_600650 = validateParameter(valid_600650, JString, required = false,
                                 default = nil)
  if valid_600650 != nil:
    section.add "X-Amz-Credential", valid_600650
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600651: Call_GetDescribeApplications_600638; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the descriptions of existing applications.
  ## 
  let valid = call_600651.validator(path, query, header, formData, body)
  let scheme = call_600651.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600651.url(scheme.get, call_600651.host, call_600651.base,
                         call_600651.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600651, url, valid)

proc call*(call_600652: Call_GetDescribeApplications_600638;
          ApplicationNames: JsonNode = nil; Action: string = "DescribeApplications";
          Version: string = "2010-12-01"): Recallable =
  ## getDescribeApplications
  ## Returns the descriptions of existing applications.
  ##   ApplicationNames: JArray
  ##                   : If specified, AWS Elastic Beanstalk restricts the returned descriptions to only include those with the specified names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600653 = newJObject()
  if ApplicationNames != nil:
    query_600653.add "ApplicationNames", ApplicationNames
  add(query_600653, "Action", newJString(Action))
  add(query_600653, "Version", newJString(Version))
  result = call_600652.call(nil, query_600653, nil, nil, nil)

var getDescribeApplications* = Call_GetDescribeApplications_600638(
    name: "getDescribeApplications", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplications",
    validator: validate_GetDescribeApplications_600639, base: "/",
    url: url_GetDescribeApplications_600640, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeConfigurationOptions_600692 = ref object of OpenApiRestCall_599369
proc url_PostDescribeConfigurationOptions_600694(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeConfigurationOptions_600693(path: JsonNode;
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
  var valid_600695 = query.getOrDefault("Action")
  valid_600695 = validateParameter(valid_600695, JString, required = true, default = newJString(
      "DescribeConfigurationOptions"))
  if valid_600695 != nil:
    section.add "Action", valid_600695
  var valid_600696 = query.getOrDefault("Version")
  valid_600696 = validateParameter(valid_600696, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600696 != nil:
    section.add "Version", valid_600696
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600697 = header.getOrDefault("X-Amz-Date")
  valid_600697 = validateParameter(valid_600697, JString, required = false,
                                 default = nil)
  if valid_600697 != nil:
    section.add "X-Amz-Date", valid_600697
  var valid_600698 = header.getOrDefault("X-Amz-Security-Token")
  valid_600698 = validateParameter(valid_600698, JString, required = false,
                                 default = nil)
  if valid_600698 != nil:
    section.add "X-Amz-Security-Token", valid_600698
  var valid_600699 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600699 = validateParameter(valid_600699, JString, required = false,
                                 default = nil)
  if valid_600699 != nil:
    section.add "X-Amz-Content-Sha256", valid_600699
  var valid_600700 = header.getOrDefault("X-Amz-Algorithm")
  valid_600700 = validateParameter(valid_600700, JString, required = false,
                                 default = nil)
  if valid_600700 != nil:
    section.add "X-Amz-Algorithm", valid_600700
  var valid_600701 = header.getOrDefault("X-Amz-Signature")
  valid_600701 = validateParameter(valid_600701, JString, required = false,
                                 default = nil)
  if valid_600701 != nil:
    section.add "X-Amz-Signature", valid_600701
  var valid_600702 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600702 = validateParameter(valid_600702, JString, required = false,
                                 default = nil)
  if valid_600702 != nil:
    section.add "X-Amz-SignedHeaders", valid_600702
  var valid_600703 = header.getOrDefault("X-Amz-Credential")
  valid_600703 = validateParameter(valid_600703, JString, required = false,
                                 default = nil)
  if valid_600703 != nil:
    section.add "X-Amz-Credential", valid_600703
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
  var valid_600704 = formData.getOrDefault("Options")
  valid_600704 = validateParameter(valid_600704, JArray, required = false,
                                 default = nil)
  if valid_600704 != nil:
    section.add "Options", valid_600704
  var valid_600705 = formData.getOrDefault("SolutionStackName")
  valid_600705 = validateParameter(valid_600705, JString, required = false,
                                 default = nil)
  if valid_600705 != nil:
    section.add "SolutionStackName", valid_600705
  var valid_600706 = formData.getOrDefault("EnvironmentName")
  valid_600706 = validateParameter(valid_600706, JString, required = false,
                                 default = nil)
  if valid_600706 != nil:
    section.add "EnvironmentName", valid_600706
  var valid_600707 = formData.getOrDefault("ApplicationName")
  valid_600707 = validateParameter(valid_600707, JString, required = false,
                                 default = nil)
  if valid_600707 != nil:
    section.add "ApplicationName", valid_600707
  var valid_600708 = formData.getOrDefault("PlatformArn")
  valid_600708 = validateParameter(valid_600708, JString, required = false,
                                 default = nil)
  if valid_600708 != nil:
    section.add "PlatformArn", valid_600708
  var valid_600709 = formData.getOrDefault("TemplateName")
  valid_600709 = validateParameter(valid_600709, JString, required = false,
                                 default = nil)
  if valid_600709 != nil:
    section.add "TemplateName", valid_600709
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600710: Call_PostDescribeConfigurationOptions_600692;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the configuration options that are used in a particular configuration template or environment, or that a specified solution stack defines. The description includes the values the options, their default values, and an indication of the required action on a running environment if an option value is changed.
  ## 
  let valid = call_600710.validator(path, query, header, formData, body)
  let scheme = call_600710.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600710.url(scheme.get, call_600710.host, call_600710.base,
                         call_600710.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600710, url, valid)

proc call*(call_600711: Call_PostDescribeConfigurationOptions_600692;
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
  var query_600712 = newJObject()
  var formData_600713 = newJObject()
  if Options != nil:
    formData_600713.add "Options", Options
  add(formData_600713, "SolutionStackName", newJString(SolutionStackName))
  add(formData_600713, "EnvironmentName", newJString(EnvironmentName))
  add(query_600712, "Action", newJString(Action))
  add(formData_600713, "ApplicationName", newJString(ApplicationName))
  add(formData_600713, "PlatformArn", newJString(PlatformArn))
  add(formData_600713, "TemplateName", newJString(TemplateName))
  add(query_600712, "Version", newJString(Version))
  result = call_600711.call(nil, query_600712, nil, formData_600713, nil)

var postDescribeConfigurationOptions* = Call_PostDescribeConfigurationOptions_600692(
    name: "postDescribeConfigurationOptions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationOptions",
    validator: validate_PostDescribeConfigurationOptions_600693, base: "/",
    url: url_PostDescribeConfigurationOptions_600694,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeConfigurationOptions_600671 = ref object of OpenApiRestCall_599369
proc url_GetDescribeConfigurationOptions_600673(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeConfigurationOptions_600672(path: JsonNode;
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
  var valid_600674 = query.getOrDefault("Options")
  valid_600674 = validateParameter(valid_600674, JArray, required = false,
                                 default = nil)
  if valid_600674 != nil:
    section.add "Options", valid_600674
  var valid_600675 = query.getOrDefault("ApplicationName")
  valid_600675 = validateParameter(valid_600675, JString, required = false,
                                 default = nil)
  if valid_600675 != nil:
    section.add "ApplicationName", valid_600675
  var valid_600676 = query.getOrDefault("PlatformArn")
  valid_600676 = validateParameter(valid_600676, JString, required = false,
                                 default = nil)
  if valid_600676 != nil:
    section.add "PlatformArn", valid_600676
  var valid_600677 = query.getOrDefault("EnvironmentName")
  valid_600677 = validateParameter(valid_600677, JString, required = false,
                                 default = nil)
  if valid_600677 != nil:
    section.add "EnvironmentName", valid_600677
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600678 = query.getOrDefault("Action")
  valid_600678 = validateParameter(valid_600678, JString, required = true, default = newJString(
      "DescribeConfigurationOptions"))
  if valid_600678 != nil:
    section.add "Action", valid_600678
  var valid_600679 = query.getOrDefault("SolutionStackName")
  valid_600679 = validateParameter(valid_600679, JString, required = false,
                                 default = nil)
  if valid_600679 != nil:
    section.add "SolutionStackName", valid_600679
  var valid_600680 = query.getOrDefault("TemplateName")
  valid_600680 = validateParameter(valid_600680, JString, required = false,
                                 default = nil)
  if valid_600680 != nil:
    section.add "TemplateName", valid_600680
  var valid_600681 = query.getOrDefault("Version")
  valid_600681 = validateParameter(valid_600681, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600681 != nil:
    section.add "Version", valid_600681
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600682 = header.getOrDefault("X-Amz-Date")
  valid_600682 = validateParameter(valid_600682, JString, required = false,
                                 default = nil)
  if valid_600682 != nil:
    section.add "X-Amz-Date", valid_600682
  var valid_600683 = header.getOrDefault("X-Amz-Security-Token")
  valid_600683 = validateParameter(valid_600683, JString, required = false,
                                 default = nil)
  if valid_600683 != nil:
    section.add "X-Amz-Security-Token", valid_600683
  var valid_600684 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600684 = validateParameter(valid_600684, JString, required = false,
                                 default = nil)
  if valid_600684 != nil:
    section.add "X-Amz-Content-Sha256", valid_600684
  var valid_600685 = header.getOrDefault("X-Amz-Algorithm")
  valid_600685 = validateParameter(valid_600685, JString, required = false,
                                 default = nil)
  if valid_600685 != nil:
    section.add "X-Amz-Algorithm", valid_600685
  var valid_600686 = header.getOrDefault("X-Amz-Signature")
  valid_600686 = validateParameter(valid_600686, JString, required = false,
                                 default = nil)
  if valid_600686 != nil:
    section.add "X-Amz-Signature", valid_600686
  var valid_600687 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600687 = validateParameter(valid_600687, JString, required = false,
                                 default = nil)
  if valid_600687 != nil:
    section.add "X-Amz-SignedHeaders", valid_600687
  var valid_600688 = header.getOrDefault("X-Amz-Credential")
  valid_600688 = validateParameter(valid_600688, JString, required = false,
                                 default = nil)
  if valid_600688 != nil:
    section.add "X-Amz-Credential", valid_600688
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600689: Call_GetDescribeConfigurationOptions_600671;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the configuration options that are used in a particular configuration template or environment, or that a specified solution stack defines. The description includes the values the options, their default values, and an indication of the required action on a running environment if an option value is changed.
  ## 
  let valid = call_600689.validator(path, query, header, formData, body)
  let scheme = call_600689.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600689.url(scheme.get, call_600689.host, call_600689.base,
                         call_600689.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600689, url, valid)

proc call*(call_600690: Call_GetDescribeConfigurationOptions_600671;
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
  var query_600691 = newJObject()
  if Options != nil:
    query_600691.add "Options", Options
  add(query_600691, "ApplicationName", newJString(ApplicationName))
  add(query_600691, "PlatformArn", newJString(PlatformArn))
  add(query_600691, "EnvironmentName", newJString(EnvironmentName))
  add(query_600691, "Action", newJString(Action))
  add(query_600691, "SolutionStackName", newJString(SolutionStackName))
  add(query_600691, "TemplateName", newJString(TemplateName))
  add(query_600691, "Version", newJString(Version))
  result = call_600690.call(nil, query_600691, nil, nil, nil)

var getDescribeConfigurationOptions* = Call_GetDescribeConfigurationOptions_600671(
    name: "getDescribeConfigurationOptions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationOptions",
    validator: validate_GetDescribeConfigurationOptions_600672, base: "/",
    url: url_GetDescribeConfigurationOptions_600673,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeConfigurationSettings_600732 = ref object of OpenApiRestCall_599369
proc url_PostDescribeConfigurationSettings_600734(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeConfigurationSettings_600733(path: JsonNode;
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
  var valid_600735 = query.getOrDefault("Action")
  valid_600735 = validateParameter(valid_600735, JString, required = true, default = newJString(
      "DescribeConfigurationSettings"))
  if valid_600735 != nil:
    section.add "Action", valid_600735
  var valid_600736 = query.getOrDefault("Version")
  valid_600736 = validateParameter(valid_600736, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600736 != nil:
    section.add "Version", valid_600736
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600737 = header.getOrDefault("X-Amz-Date")
  valid_600737 = validateParameter(valid_600737, JString, required = false,
                                 default = nil)
  if valid_600737 != nil:
    section.add "X-Amz-Date", valid_600737
  var valid_600738 = header.getOrDefault("X-Amz-Security-Token")
  valid_600738 = validateParameter(valid_600738, JString, required = false,
                                 default = nil)
  if valid_600738 != nil:
    section.add "X-Amz-Security-Token", valid_600738
  var valid_600739 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600739 = validateParameter(valid_600739, JString, required = false,
                                 default = nil)
  if valid_600739 != nil:
    section.add "X-Amz-Content-Sha256", valid_600739
  var valid_600740 = header.getOrDefault("X-Amz-Algorithm")
  valid_600740 = validateParameter(valid_600740, JString, required = false,
                                 default = nil)
  if valid_600740 != nil:
    section.add "X-Amz-Algorithm", valid_600740
  var valid_600741 = header.getOrDefault("X-Amz-Signature")
  valid_600741 = validateParameter(valid_600741, JString, required = false,
                                 default = nil)
  if valid_600741 != nil:
    section.add "X-Amz-Signature", valid_600741
  var valid_600742 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600742 = validateParameter(valid_600742, JString, required = false,
                                 default = nil)
  if valid_600742 != nil:
    section.add "X-Amz-SignedHeaders", valid_600742
  var valid_600743 = header.getOrDefault("X-Amz-Credential")
  valid_600743 = validateParameter(valid_600743, JString, required = false,
                                 default = nil)
  if valid_600743 != nil:
    section.add "X-Amz-Credential", valid_600743
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to describe.</p> <p> Condition: You must specify either this or a TemplateName, but not both. If you specify both, AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   ApplicationName: JString (required)
  ##                  : The application for the environment or configuration template.
  ##   TemplateName: JString
  ##               : <p>The name of the configuration template to describe.</p> <p> Conditional: You must specify either this parameter or an EnvironmentName, but not both. If you specify both, AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. If you do not specify either, AWS Elastic Beanstalk returns a <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_600744 = formData.getOrDefault("EnvironmentName")
  valid_600744 = validateParameter(valid_600744, JString, required = false,
                                 default = nil)
  if valid_600744 != nil:
    section.add "EnvironmentName", valid_600744
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_600745 = formData.getOrDefault("ApplicationName")
  valid_600745 = validateParameter(valid_600745, JString, required = true,
                                 default = nil)
  if valid_600745 != nil:
    section.add "ApplicationName", valid_600745
  var valid_600746 = formData.getOrDefault("TemplateName")
  valid_600746 = validateParameter(valid_600746, JString, required = false,
                                 default = nil)
  if valid_600746 != nil:
    section.add "TemplateName", valid_600746
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600747: Call_PostDescribeConfigurationSettings_600732;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a description of the settings for the specified configuration set, that is, either a configuration template or the configuration set associated with a running environment.</p> <p>When describing the settings for the configuration set associated with a running environment, it is possible to receive two sets of setting descriptions. One is the deployed configuration set, and the other is a draft configuration of an environment that is either in the process of deployment or that failed to deploy.</p> <p>Related Topics</p> <ul> <li> <p> <a>DeleteEnvironmentConfiguration</a> </p> </li> </ul>
  ## 
  let valid = call_600747.validator(path, query, header, formData, body)
  let scheme = call_600747.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600747.url(scheme.get, call_600747.host, call_600747.base,
                         call_600747.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600747, url, valid)

proc call*(call_600748: Call_PostDescribeConfigurationSettings_600732;
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
  var query_600749 = newJObject()
  var formData_600750 = newJObject()
  add(formData_600750, "EnvironmentName", newJString(EnvironmentName))
  add(query_600749, "Action", newJString(Action))
  add(formData_600750, "ApplicationName", newJString(ApplicationName))
  add(formData_600750, "TemplateName", newJString(TemplateName))
  add(query_600749, "Version", newJString(Version))
  result = call_600748.call(nil, query_600749, nil, formData_600750, nil)

var postDescribeConfigurationSettings* = Call_PostDescribeConfigurationSettings_600732(
    name: "postDescribeConfigurationSettings", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationSettings",
    validator: validate_PostDescribeConfigurationSettings_600733, base: "/",
    url: url_PostDescribeConfigurationSettings_600734,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeConfigurationSettings_600714 = ref object of OpenApiRestCall_599369
proc url_GetDescribeConfigurationSettings_600716(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeConfigurationSettings_600715(path: JsonNode;
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
  var valid_600717 = query.getOrDefault("ApplicationName")
  valid_600717 = validateParameter(valid_600717, JString, required = true,
                                 default = nil)
  if valid_600717 != nil:
    section.add "ApplicationName", valid_600717
  var valid_600718 = query.getOrDefault("EnvironmentName")
  valid_600718 = validateParameter(valid_600718, JString, required = false,
                                 default = nil)
  if valid_600718 != nil:
    section.add "EnvironmentName", valid_600718
  var valid_600719 = query.getOrDefault("Action")
  valid_600719 = validateParameter(valid_600719, JString, required = true, default = newJString(
      "DescribeConfigurationSettings"))
  if valid_600719 != nil:
    section.add "Action", valid_600719
  var valid_600720 = query.getOrDefault("TemplateName")
  valid_600720 = validateParameter(valid_600720, JString, required = false,
                                 default = nil)
  if valid_600720 != nil:
    section.add "TemplateName", valid_600720
  var valid_600721 = query.getOrDefault("Version")
  valid_600721 = validateParameter(valid_600721, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600721 != nil:
    section.add "Version", valid_600721
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600722 = header.getOrDefault("X-Amz-Date")
  valid_600722 = validateParameter(valid_600722, JString, required = false,
                                 default = nil)
  if valid_600722 != nil:
    section.add "X-Amz-Date", valid_600722
  var valid_600723 = header.getOrDefault("X-Amz-Security-Token")
  valid_600723 = validateParameter(valid_600723, JString, required = false,
                                 default = nil)
  if valid_600723 != nil:
    section.add "X-Amz-Security-Token", valid_600723
  var valid_600724 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600724 = validateParameter(valid_600724, JString, required = false,
                                 default = nil)
  if valid_600724 != nil:
    section.add "X-Amz-Content-Sha256", valid_600724
  var valid_600725 = header.getOrDefault("X-Amz-Algorithm")
  valid_600725 = validateParameter(valid_600725, JString, required = false,
                                 default = nil)
  if valid_600725 != nil:
    section.add "X-Amz-Algorithm", valid_600725
  var valid_600726 = header.getOrDefault("X-Amz-Signature")
  valid_600726 = validateParameter(valid_600726, JString, required = false,
                                 default = nil)
  if valid_600726 != nil:
    section.add "X-Amz-Signature", valid_600726
  var valid_600727 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600727 = validateParameter(valid_600727, JString, required = false,
                                 default = nil)
  if valid_600727 != nil:
    section.add "X-Amz-SignedHeaders", valid_600727
  var valid_600728 = header.getOrDefault("X-Amz-Credential")
  valid_600728 = validateParameter(valid_600728, JString, required = false,
                                 default = nil)
  if valid_600728 != nil:
    section.add "X-Amz-Credential", valid_600728
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600729: Call_GetDescribeConfigurationSettings_600714;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a description of the settings for the specified configuration set, that is, either a configuration template or the configuration set associated with a running environment.</p> <p>When describing the settings for the configuration set associated with a running environment, it is possible to receive two sets of setting descriptions. One is the deployed configuration set, and the other is a draft configuration of an environment that is either in the process of deployment or that failed to deploy.</p> <p>Related Topics</p> <ul> <li> <p> <a>DeleteEnvironmentConfiguration</a> </p> </li> </ul>
  ## 
  let valid = call_600729.validator(path, query, header, formData, body)
  let scheme = call_600729.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600729.url(scheme.get, call_600729.host, call_600729.base,
                         call_600729.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600729, url, valid)

proc call*(call_600730: Call_GetDescribeConfigurationSettings_600714;
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
  var query_600731 = newJObject()
  add(query_600731, "ApplicationName", newJString(ApplicationName))
  add(query_600731, "EnvironmentName", newJString(EnvironmentName))
  add(query_600731, "Action", newJString(Action))
  add(query_600731, "TemplateName", newJString(TemplateName))
  add(query_600731, "Version", newJString(Version))
  result = call_600730.call(nil, query_600731, nil, nil, nil)

var getDescribeConfigurationSettings* = Call_GetDescribeConfigurationSettings_600714(
    name: "getDescribeConfigurationSettings", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationSettings",
    validator: validate_GetDescribeConfigurationSettings_600715, base: "/",
    url: url_GetDescribeConfigurationSettings_600716,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentHealth_600769 = ref object of OpenApiRestCall_599369
proc url_PostDescribeEnvironmentHealth_600771(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEnvironmentHealth_600770(path: JsonNode; query: JsonNode;
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
  var valid_600772 = query.getOrDefault("Action")
  valid_600772 = validateParameter(valid_600772, JString, required = true, default = newJString(
      "DescribeEnvironmentHealth"))
  if valid_600772 != nil:
    section.add "Action", valid_600772
  var valid_600773 = query.getOrDefault("Version")
  valid_600773 = validateParameter(valid_600773, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600773 != nil:
    section.add "Version", valid_600773
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600774 = header.getOrDefault("X-Amz-Date")
  valid_600774 = validateParameter(valid_600774, JString, required = false,
                                 default = nil)
  if valid_600774 != nil:
    section.add "X-Amz-Date", valid_600774
  var valid_600775 = header.getOrDefault("X-Amz-Security-Token")
  valid_600775 = validateParameter(valid_600775, JString, required = false,
                                 default = nil)
  if valid_600775 != nil:
    section.add "X-Amz-Security-Token", valid_600775
  var valid_600776 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600776 = validateParameter(valid_600776, JString, required = false,
                                 default = nil)
  if valid_600776 != nil:
    section.add "X-Amz-Content-Sha256", valid_600776
  var valid_600777 = header.getOrDefault("X-Amz-Algorithm")
  valid_600777 = validateParameter(valid_600777, JString, required = false,
                                 default = nil)
  if valid_600777 != nil:
    section.add "X-Amz-Algorithm", valid_600777
  var valid_600778 = header.getOrDefault("X-Amz-Signature")
  valid_600778 = validateParameter(valid_600778, JString, required = false,
                                 default = nil)
  if valid_600778 != nil:
    section.add "X-Amz-Signature", valid_600778
  var valid_600779 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600779 = validateParameter(valid_600779, JString, required = false,
                                 default = nil)
  if valid_600779 != nil:
    section.add "X-Amz-SignedHeaders", valid_600779
  var valid_600780 = header.getOrDefault("X-Amz-Credential")
  valid_600780 = validateParameter(valid_600780, JString, required = false,
                                 default = nil)
  if valid_600780 != nil:
    section.add "X-Amz-Credential", valid_600780
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentId: JString
  ##                : <p>Specify the environment by ID.</p> <p>You must specify either this or an EnvironmentName, or both.</p>
  ##   EnvironmentName: JString
  ##                  : <p>Specify the environment by name.</p> <p>You must specify either this or an EnvironmentName, or both.</p>
  ##   AttributeNames: JArray
  ##                 : Specify the response elements to return. To retrieve all attributes, set to <code>All</code>. If no attribute names are specified, returns the name of the environment.
  section = newJObject()
  var valid_600781 = formData.getOrDefault("EnvironmentId")
  valid_600781 = validateParameter(valid_600781, JString, required = false,
                                 default = nil)
  if valid_600781 != nil:
    section.add "EnvironmentId", valid_600781
  var valid_600782 = formData.getOrDefault("EnvironmentName")
  valid_600782 = validateParameter(valid_600782, JString, required = false,
                                 default = nil)
  if valid_600782 != nil:
    section.add "EnvironmentName", valid_600782
  var valid_600783 = formData.getOrDefault("AttributeNames")
  valid_600783 = validateParameter(valid_600783, JArray, required = false,
                                 default = nil)
  if valid_600783 != nil:
    section.add "AttributeNames", valid_600783
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600784: Call_PostDescribeEnvironmentHealth_600769; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the overall health of the specified environment. The <b>DescribeEnvironmentHealth</b> operation is only available with AWS Elastic Beanstalk Enhanced Health.
  ## 
  let valid = call_600784.validator(path, query, header, formData, body)
  let scheme = call_600784.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600784.url(scheme.get, call_600784.host, call_600784.base,
                         call_600784.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600784, url, valid)

proc call*(call_600785: Call_PostDescribeEnvironmentHealth_600769;
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
  var query_600786 = newJObject()
  var formData_600787 = newJObject()
  add(formData_600787, "EnvironmentId", newJString(EnvironmentId))
  add(formData_600787, "EnvironmentName", newJString(EnvironmentName))
  add(query_600786, "Action", newJString(Action))
  if AttributeNames != nil:
    formData_600787.add "AttributeNames", AttributeNames
  add(query_600786, "Version", newJString(Version))
  result = call_600785.call(nil, query_600786, nil, formData_600787, nil)

var postDescribeEnvironmentHealth* = Call_PostDescribeEnvironmentHealth_600769(
    name: "postDescribeEnvironmentHealth", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentHealth",
    validator: validate_PostDescribeEnvironmentHealth_600770, base: "/",
    url: url_PostDescribeEnvironmentHealth_600771,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentHealth_600751 = ref object of OpenApiRestCall_599369
proc url_GetDescribeEnvironmentHealth_600753(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEnvironmentHealth_600752(path: JsonNode; query: JsonNode;
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
  var valid_600754 = query.getOrDefault("AttributeNames")
  valid_600754 = validateParameter(valid_600754, JArray, required = false,
                                 default = nil)
  if valid_600754 != nil:
    section.add "AttributeNames", valid_600754
  var valid_600755 = query.getOrDefault("EnvironmentName")
  valid_600755 = validateParameter(valid_600755, JString, required = false,
                                 default = nil)
  if valid_600755 != nil:
    section.add "EnvironmentName", valid_600755
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600756 = query.getOrDefault("Action")
  valid_600756 = validateParameter(valid_600756, JString, required = true, default = newJString(
      "DescribeEnvironmentHealth"))
  if valid_600756 != nil:
    section.add "Action", valid_600756
  var valid_600757 = query.getOrDefault("EnvironmentId")
  valid_600757 = validateParameter(valid_600757, JString, required = false,
                                 default = nil)
  if valid_600757 != nil:
    section.add "EnvironmentId", valid_600757
  var valid_600758 = query.getOrDefault("Version")
  valid_600758 = validateParameter(valid_600758, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600758 != nil:
    section.add "Version", valid_600758
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600759 = header.getOrDefault("X-Amz-Date")
  valid_600759 = validateParameter(valid_600759, JString, required = false,
                                 default = nil)
  if valid_600759 != nil:
    section.add "X-Amz-Date", valid_600759
  var valid_600760 = header.getOrDefault("X-Amz-Security-Token")
  valid_600760 = validateParameter(valid_600760, JString, required = false,
                                 default = nil)
  if valid_600760 != nil:
    section.add "X-Amz-Security-Token", valid_600760
  var valid_600761 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600761 = validateParameter(valid_600761, JString, required = false,
                                 default = nil)
  if valid_600761 != nil:
    section.add "X-Amz-Content-Sha256", valid_600761
  var valid_600762 = header.getOrDefault("X-Amz-Algorithm")
  valid_600762 = validateParameter(valid_600762, JString, required = false,
                                 default = nil)
  if valid_600762 != nil:
    section.add "X-Amz-Algorithm", valid_600762
  var valid_600763 = header.getOrDefault("X-Amz-Signature")
  valid_600763 = validateParameter(valid_600763, JString, required = false,
                                 default = nil)
  if valid_600763 != nil:
    section.add "X-Amz-Signature", valid_600763
  var valid_600764 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600764 = validateParameter(valid_600764, JString, required = false,
                                 default = nil)
  if valid_600764 != nil:
    section.add "X-Amz-SignedHeaders", valid_600764
  var valid_600765 = header.getOrDefault("X-Amz-Credential")
  valid_600765 = validateParameter(valid_600765, JString, required = false,
                                 default = nil)
  if valid_600765 != nil:
    section.add "X-Amz-Credential", valid_600765
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600766: Call_GetDescribeEnvironmentHealth_600751; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the overall health of the specified environment. The <b>DescribeEnvironmentHealth</b> operation is only available with AWS Elastic Beanstalk Enhanced Health.
  ## 
  let valid = call_600766.validator(path, query, header, formData, body)
  let scheme = call_600766.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600766.url(scheme.get, call_600766.host, call_600766.base,
                         call_600766.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600766, url, valid)

proc call*(call_600767: Call_GetDescribeEnvironmentHealth_600751;
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
  var query_600768 = newJObject()
  if AttributeNames != nil:
    query_600768.add "AttributeNames", AttributeNames
  add(query_600768, "EnvironmentName", newJString(EnvironmentName))
  add(query_600768, "Action", newJString(Action))
  add(query_600768, "EnvironmentId", newJString(EnvironmentId))
  add(query_600768, "Version", newJString(Version))
  result = call_600767.call(nil, query_600768, nil, nil, nil)

var getDescribeEnvironmentHealth* = Call_GetDescribeEnvironmentHealth_600751(
    name: "getDescribeEnvironmentHealth", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentHealth",
    validator: validate_GetDescribeEnvironmentHealth_600752, base: "/",
    url: url_GetDescribeEnvironmentHealth_600753,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentManagedActionHistory_600807 = ref object of OpenApiRestCall_599369
proc url_PostDescribeEnvironmentManagedActionHistory_600809(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEnvironmentManagedActionHistory_600808(path: JsonNode;
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
  var valid_600810 = query.getOrDefault("Action")
  valid_600810 = validateParameter(valid_600810, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActionHistory"))
  if valid_600810 != nil:
    section.add "Action", valid_600810
  var valid_600811 = query.getOrDefault("Version")
  valid_600811 = validateParameter(valid_600811, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600811 != nil:
    section.add "Version", valid_600811
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600812 = header.getOrDefault("X-Amz-Date")
  valid_600812 = validateParameter(valid_600812, JString, required = false,
                                 default = nil)
  if valid_600812 != nil:
    section.add "X-Amz-Date", valid_600812
  var valid_600813 = header.getOrDefault("X-Amz-Security-Token")
  valid_600813 = validateParameter(valid_600813, JString, required = false,
                                 default = nil)
  if valid_600813 != nil:
    section.add "X-Amz-Security-Token", valid_600813
  var valid_600814 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600814 = validateParameter(valid_600814, JString, required = false,
                                 default = nil)
  if valid_600814 != nil:
    section.add "X-Amz-Content-Sha256", valid_600814
  var valid_600815 = header.getOrDefault("X-Amz-Algorithm")
  valid_600815 = validateParameter(valid_600815, JString, required = false,
                                 default = nil)
  if valid_600815 != nil:
    section.add "X-Amz-Algorithm", valid_600815
  var valid_600816 = header.getOrDefault("X-Amz-Signature")
  valid_600816 = validateParameter(valid_600816, JString, required = false,
                                 default = nil)
  if valid_600816 != nil:
    section.add "X-Amz-Signature", valid_600816
  var valid_600817 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600817 = validateParameter(valid_600817, JString, required = false,
                                 default = nil)
  if valid_600817 != nil:
    section.add "X-Amz-SignedHeaders", valid_600817
  var valid_600818 = header.getOrDefault("X-Amz-Credential")
  valid_600818 = validateParameter(valid_600818, JString, required = false,
                                 default = nil)
  if valid_600818 != nil:
    section.add "X-Amz-Credential", valid_600818
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
  var valid_600819 = formData.getOrDefault("NextToken")
  valid_600819 = validateParameter(valid_600819, JString, required = false,
                                 default = nil)
  if valid_600819 != nil:
    section.add "NextToken", valid_600819
  var valid_600820 = formData.getOrDefault("EnvironmentId")
  valid_600820 = validateParameter(valid_600820, JString, required = false,
                                 default = nil)
  if valid_600820 != nil:
    section.add "EnvironmentId", valid_600820
  var valid_600821 = formData.getOrDefault("EnvironmentName")
  valid_600821 = validateParameter(valid_600821, JString, required = false,
                                 default = nil)
  if valid_600821 != nil:
    section.add "EnvironmentName", valid_600821
  var valid_600822 = formData.getOrDefault("MaxItems")
  valid_600822 = validateParameter(valid_600822, JInt, required = false, default = nil)
  if valid_600822 != nil:
    section.add "MaxItems", valid_600822
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600823: Call_PostDescribeEnvironmentManagedActionHistory_600807;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists an environment's completed and failed managed actions.
  ## 
  let valid = call_600823.validator(path, query, header, formData, body)
  let scheme = call_600823.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600823.url(scheme.get, call_600823.host, call_600823.base,
                         call_600823.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600823, url, valid)

proc call*(call_600824: Call_PostDescribeEnvironmentManagedActionHistory_600807;
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
  var query_600825 = newJObject()
  var formData_600826 = newJObject()
  add(formData_600826, "NextToken", newJString(NextToken))
  add(formData_600826, "EnvironmentId", newJString(EnvironmentId))
  add(formData_600826, "EnvironmentName", newJString(EnvironmentName))
  add(query_600825, "Action", newJString(Action))
  add(formData_600826, "MaxItems", newJInt(MaxItems))
  add(query_600825, "Version", newJString(Version))
  result = call_600824.call(nil, query_600825, nil, formData_600826, nil)

var postDescribeEnvironmentManagedActionHistory* = Call_PostDescribeEnvironmentManagedActionHistory_600807(
    name: "postDescribeEnvironmentManagedActionHistory",
    meth: HttpMethod.HttpPost, host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActionHistory",
    validator: validate_PostDescribeEnvironmentManagedActionHistory_600808,
    base: "/", url: url_PostDescribeEnvironmentManagedActionHistory_600809,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentManagedActionHistory_600788 = ref object of OpenApiRestCall_599369
proc url_GetDescribeEnvironmentManagedActionHistory_600790(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEnvironmentManagedActionHistory_600789(path: JsonNode;
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
  var valid_600791 = query.getOrDefault("NextToken")
  valid_600791 = validateParameter(valid_600791, JString, required = false,
                                 default = nil)
  if valid_600791 != nil:
    section.add "NextToken", valid_600791
  var valid_600792 = query.getOrDefault("EnvironmentName")
  valid_600792 = validateParameter(valid_600792, JString, required = false,
                                 default = nil)
  if valid_600792 != nil:
    section.add "EnvironmentName", valid_600792
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600793 = query.getOrDefault("Action")
  valid_600793 = validateParameter(valid_600793, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActionHistory"))
  if valid_600793 != nil:
    section.add "Action", valid_600793
  var valid_600794 = query.getOrDefault("EnvironmentId")
  valid_600794 = validateParameter(valid_600794, JString, required = false,
                                 default = nil)
  if valid_600794 != nil:
    section.add "EnvironmentId", valid_600794
  var valid_600795 = query.getOrDefault("MaxItems")
  valid_600795 = validateParameter(valid_600795, JInt, required = false, default = nil)
  if valid_600795 != nil:
    section.add "MaxItems", valid_600795
  var valid_600796 = query.getOrDefault("Version")
  valid_600796 = validateParameter(valid_600796, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600796 != nil:
    section.add "Version", valid_600796
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600797 = header.getOrDefault("X-Amz-Date")
  valid_600797 = validateParameter(valid_600797, JString, required = false,
                                 default = nil)
  if valid_600797 != nil:
    section.add "X-Amz-Date", valid_600797
  var valid_600798 = header.getOrDefault("X-Amz-Security-Token")
  valid_600798 = validateParameter(valid_600798, JString, required = false,
                                 default = nil)
  if valid_600798 != nil:
    section.add "X-Amz-Security-Token", valid_600798
  var valid_600799 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600799 = validateParameter(valid_600799, JString, required = false,
                                 default = nil)
  if valid_600799 != nil:
    section.add "X-Amz-Content-Sha256", valid_600799
  var valid_600800 = header.getOrDefault("X-Amz-Algorithm")
  valid_600800 = validateParameter(valid_600800, JString, required = false,
                                 default = nil)
  if valid_600800 != nil:
    section.add "X-Amz-Algorithm", valid_600800
  var valid_600801 = header.getOrDefault("X-Amz-Signature")
  valid_600801 = validateParameter(valid_600801, JString, required = false,
                                 default = nil)
  if valid_600801 != nil:
    section.add "X-Amz-Signature", valid_600801
  var valid_600802 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600802 = validateParameter(valid_600802, JString, required = false,
                                 default = nil)
  if valid_600802 != nil:
    section.add "X-Amz-SignedHeaders", valid_600802
  var valid_600803 = header.getOrDefault("X-Amz-Credential")
  valid_600803 = validateParameter(valid_600803, JString, required = false,
                                 default = nil)
  if valid_600803 != nil:
    section.add "X-Amz-Credential", valid_600803
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600804: Call_GetDescribeEnvironmentManagedActionHistory_600788;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists an environment's completed and failed managed actions.
  ## 
  let valid = call_600804.validator(path, query, header, formData, body)
  let scheme = call_600804.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600804.url(scheme.get, call_600804.host, call_600804.base,
                         call_600804.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600804, url, valid)

proc call*(call_600805: Call_GetDescribeEnvironmentManagedActionHistory_600788;
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
  var query_600806 = newJObject()
  add(query_600806, "NextToken", newJString(NextToken))
  add(query_600806, "EnvironmentName", newJString(EnvironmentName))
  add(query_600806, "Action", newJString(Action))
  add(query_600806, "EnvironmentId", newJString(EnvironmentId))
  add(query_600806, "MaxItems", newJInt(MaxItems))
  add(query_600806, "Version", newJString(Version))
  result = call_600805.call(nil, query_600806, nil, nil, nil)

var getDescribeEnvironmentManagedActionHistory* = Call_GetDescribeEnvironmentManagedActionHistory_600788(
    name: "getDescribeEnvironmentManagedActionHistory", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActionHistory",
    validator: validate_GetDescribeEnvironmentManagedActionHistory_600789,
    base: "/", url: url_GetDescribeEnvironmentManagedActionHistory_600790,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentManagedActions_600845 = ref object of OpenApiRestCall_599369
proc url_PostDescribeEnvironmentManagedActions_600847(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEnvironmentManagedActions_600846(path: JsonNode;
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
  var valid_600848 = query.getOrDefault("Action")
  valid_600848 = validateParameter(valid_600848, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActions"))
  if valid_600848 != nil:
    section.add "Action", valid_600848
  var valid_600849 = query.getOrDefault("Version")
  valid_600849 = validateParameter(valid_600849, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600849 != nil:
    section.add "Version", valid_600849
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600850 = header.getOrDefault("X-Amz-Date")
  valid_600850 = validateParameter(valid_600850, JString, required = false,
                                 default = nil)
  if valid_600850 != nil:
    section.add "X-Amz-Date", valid_600850
  var valid_600851 = header.getOrDefault("X-Amz-Security-Token")
  valid_600851 = validateParameter(valid_600851, JString, required = false,
                                 default = nil)
  if valid_600851 != nil:
    section.add "X-Amz-Security-Token", valid_600851
  var valid_600852 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600852 = validateParameter(valid_600852, JString, required = false,
                                 default = nil)
  if valid_600852 != nil:
    section.add "X-Amz-Content-Sha256", valid_600852
  var valid_600853 = header.getOrDefault("X-Amz-Algorithm")
  valid_600853 = validateParameter(valid_600853, JString, required = false,
                                 default = nil)
  if valid_600853 != nil:
    section.add "X-Amz-Algorithm", valid_600853
  var valid_600854 = header.getOrDefault("X-Amz-Signature")
  valid_600854 = validateParameter(valid_600854, JString, required = false,
                                 default = nil)
  if valid_600854 != nil:
    section.add "X-Amz-Signature", valid_600854
  var valid_600855 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600855 = validateParameter(valid_600855, JString, required = false,
                                 default = nil)
  if valid_600855 != nil:
    section.add "X-Amz-SignedHeaders", valid_600855
  var valid_600856 = header.getOrDefault("X-Amz-Credential")
  valid_600856 = validateParameter(valid_600856, JString, required = false,
                                 default = nil)
  if valid_600856 != nil:
    section.add "X-Amz-Credential", valid_600856
  result.add "header", section
  ## parameters in `formData` object:
  ##   Status: JString
  ##         : To show only actions with a particular status, specify a status.
  ##   EnvironmentId: JString
  ##                : The environment ID of the target environment.
  ##   EnvironmentName: JString
  ##                  : The name of the target environment.
  section = newJObject()
  var valid_600857 = formData.getOrDefault("Status")
  valid_600857 = validateParameter(valid_600857, JString, required = false,
                                 default = newJString("Scheduled"))
  if valid_600857 != nil:
    section.add "Status", valid_600857
  var valid_600858 = formData.getOrDefault("EnvironmentId")
  valid_600858 = validateParameter(valid_600858, JString, required = false,
                                 default = nil)
  if valid_600858 != nil:
    section.add "EnvironmentId", valid_600858
  var valid_600859 = formData.getOrDefault("EnvironmentName")
  valid_600859 = validateParameter(valid_600859, JString, required = false,
                                 default = nil)
  if valid_600859 != nil:
    section.add "EnvironmentName", valid_600859
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600860: Call_PostDescribeEnvironmentManagedActions_600845;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists an environment's upcoming and in-progress managed actions.
  ## 
  let valid = call_600860.validator(path, query, header, formData, body)
  let scheme = call_600860.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600860.url(scheme.get, call_600860.host, call_600860.base,
                         call_600860.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600860, url, valid)

proc call*(call_600861: Call_PostDescribeEnvironmentManagedActions_600845;
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
  var query_600862 = newJObject()
  var formData_600863 = newJObject()
  add(formData_600863, "Status", newJString(Status))
  add(formData_600863, "EnvironmentId", newJString(EnvironmentId))
  add(formData_600863, "EnvironmentName", newJString(EnvironmentName))
  add(query_600862, "Action", newJString(Action))
  add(query_600862, "Version", newJString(Version))
  result = call_600861.call(nil, query_600862, nil, formData_600863, nil)

var postDescribeEnvironmentManagedActions* = Call_PostDescribeEnvironmentManagedActions_600845(
    name: "postDescribeEnvironmentManagedActions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActions",
    validator: validate_PostDescribeEnvironmentManagedActions_600846, base: "/",
    url: url_PostDescribeEnvironmentManagedActions_600847,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentManagedActions_600827 = ref object of OpenApiRestCall_599369
proc url_GetDescribeEnvironmentManagedActions_600829(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEnvironmentManagedActions_600828(path: JsonNode;
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
  var valid_600830 = query.getOrDefault("Status")
  valid_600830 = validateParameter(valid_600830, JString, required = false,
                                 default = newJString("Scheduled"))
  if valid_600830 != nil:
    section.add "Status", valid_600830
  var valid_600831 = query.getOrDefault("EnvironmentName")
  valid_600831 = validateParameter(valid_600831, JString, required = false,
                                 default = nil)
  if valid_600831 != nil:
    section.add "EnvironmentName", valid_600831
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600832 = query.getOrDefault("Action")
  valid_600832 = validateParameter(valid_600832, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActions"))
  if valid_600832 != nil:
    section.add "Action", valid_600832
  var valid_600833 = query.getOrDefault("EnvironmentId")
  valid_600833 = validateParameter(valid_600833, JString, required = false,
                                 default = nil)
  if valid_600833 != nil:
    section.add "EnvironmentId", valid_600833
  var valid_600834 = query.getOrDefault("Version")
  valid_600834 = validateParameter(valid_600834, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600834 != nil:
    section.add "Version", valid_600834
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600835 = header.getOrDefault("X-Amz-Date")
  valid_600835 = validateParameter(valid_600835, JString, required = false,
                                 default = nil)
  if valid_600835 != nil:
    section.add "X-Amz-Date", valid_600835
  var valid_600836 = header.getOrDefault("X-Amz-Security-Token")
  valid_600836 = validateParameter(valid_600836, JString, required = false,
                                 default = nil)
  if valid_600836 != nil:
    section.add "X-Amz-Security-Token", valid_600836
  var valid_600837 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600837 = validateParameter(valid_600837, JString, required = false,
                                 default = nil)
  if valid_600837 != nil:
    section.add "X-Amz-Content-Sha256", valid_600837
  var valid_600838 = header.getOrDefault("X-Amz-Algorithm")
  valid_600838 = validateParameter(valid_600838, JString, required = false,
                                 default = nil)
  if valid_600838 != nil:
    section.add "X-Amz-Algorithm", valid_600838
  var valid_600839 = header.getOrDefault("X-Amz-Signature")
  valid_600839 = validateParameter(valid_600839, JString, required = false,
                                 default = nil)
  if valid_600839 != nil:
    section.add "X-Amz-Signature", valid_600839
  var valid_600840 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600840 = validateParameter(valid_600840, JString, required = false,
                                 default = nil)
  if valid_600840 != nil:
    section.add "X-Amz-SignedHeaders", valid_600840
  var valid_600841 = header.getOrDefault("X-Amz-Credential")
  valid_600841 = validateParameter(valid_600841, JString, required = false,
                                 default = nil)
  if valid_600841 != nil:
    section.add "X-Amz-Credential", valid_600841
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600842: Call_GetDescribeEnvironmentManagedActions_600827;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists an environment's upcoming and in-progress managed actions.
  ## 
  let valid = call_600842.validator(path, query, header, formData, body)
  let scheme = call_600842.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600842.url(scheme.get, call_600842.host, call_600842.base,
                         call_600842.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600842, url, valid)

proc call*(call_600843: Call_GetDescribeEnvironmentManagedActions_600827;
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
  var query_600844 = newJObject()
  add(query_600844, "Status", newJString(Status))
  add(query_600844, "EnvironmentName", newJString(EnvironmentName))
  add(query_600844, "Action", newJString(Action))
  add(query_600844, "EnvironmentId", newJString(EnvironmentId))
  add(query_600844, "Version", newJString(Version))
  result = call_600843.call(nil, query_600844, nil, nil, nil)

var getDescribeEnvironmentManagedActions* = Call_GetDescribeEnvironmentManagedActions_600827(
    name: "getDescribeEnvironmentManagedActions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActions",
    validator: validate_GetDescribeEnvironmentManagedActions_600828, base: "/",
    url: url_GetDescribeEnvironmentManagedActions_600829,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentResources_600881 = ref object of OpenApiRestCall_599369
proc url_PostDescribeEnvironmentResources_600883(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEnvironmentResources_600882(path: JsonNode;
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
  var valid_600884 = query.getOrDefault("Action")
  valid_600884 = validateParameter(valid_600884, JString, required = true, default = newJString(
      "DescribeEnvironmentResources"))
  if valid_600884 != nil:
    section.add "Action", valid_600884
  var valid_600885 = query.getOrDefault("Version")
  valid_600885 = validateParameter(valid_600885, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600885 != nil:
    section.add "Version", valid_600885
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600886 = header.getOrDefault("X-Amz-Date")
  valid_600886 = validateParameter(valid_600886, JString, required = false,
                                 default = nil)
  if valid_600886 != nil:
    section.add "X-Amz-Date", valid_600886
  var valid_600887 = header.getOrDefault("X-Amz-Security-Token")
  valid_600887 = validateParameter(valid_600887, JString, required = false,
                                 default = nil)
  if valid_600887 != nil:
    section.add "X-Amz-Security-Token", valid_600887
  var valid_600888 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600888 = validateParameter(valid_600888, JString, required = false,
                                 default = nil)
  if valid_600888 != nil:
    section.add "X-Amz-Content-Sha256", valid_600888
  var valid_600889 = header.getOrDefault("X-Amz-Algorithm")
  valid_600889 = validateParameter(valid_600889, JString, required = false,
                                 default = nil)
  if valid_600889 != nil:
    section.add "X-Amz-Algorithm", valid_600889
  var valid_600890 = header.getOrDefault("X-Amz-Signature")
  valid_600890 = validateParameter(valid_600890, JString, required = false,
                                 default = nil)
  if valid_600890 != nil:
    section.add "X-Amz-Signature", valid_600890
  var valid_600891 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600891 = validateParameter(valid_600891, JString, required = false,
                                 default = nil)
  if valid_600891 != nil:
    section.add "X-Amz-SignedHeaders", valid_600891
  var valid_600892 = header.getOrDefault("X-Amz-Credential")
  valid_600892 = validateParameter(valid_600892, JString, required = false,
                                 default = nil)
  if valid_600892 != nil:
    section.add "X-Amz-Credential", valid_600892
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to retrieve AWS resource usage data.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to retrieve AWS resource usage data.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_600893 = formData.getOrDefault("EnvironmentId")
  valid_600893 = validateParameter(valid_600893, JString, required = false,
                                 default = nil)
  if valid_600893 != nil:
    section.add "EnvironmentId", valid_600893
  var valid_600894 = formData.getOrDefault("EnvironmentName")
  valid_600894 = validateParameter(valid_600894, JString, required = false,
                                 default = nil)
  if valid_600894 != nil:
    section.add "EnvironmentName", valid_600894
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600895: Call_PostDescribeEnvironmentResources_600881;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns AWS resources for this environment.
  ## 
  let valid = call_600895.validator(path, query, header, formData, body)
  let scheme = call_600895.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600895.url(scheme.get, call_600895.host, call_600895.base,
                         call_600895.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600895, url, valid)

proc call*(call_600896: Call_PostDescribeEnvironmentResources_600881;
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
  var query_600897 = newJObject()
  var formData_600898 = newJObject()
  add(formData_600898, "EnvironmentId", newJString(EnvironmentId))
  add(formData_600898, "EnvironmentName", newJString(EnvironmentName))
  add(query_600897, "Action", newJString(Action))
  add(query_600897, "Version", newJString(Version))
  result = call_600896.call(nil, query_600897, nil, formData_600898, nil)

var postDescribeEnvironmentResources* = Call_PostDescribeEnvironmentResources_600881(
    name: "postDescribeEnvironmentResources", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentResources",
    validator: validate_PostDescribeEnvironmentResources_600882, base: "/",
    url: url_PostDescribeEnvironmentResources_600883,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentResources_600864 = ref object of OpenApiRestCall_599369
proc url_GetDescribeEnvironmentResources_600866(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEnvironmentResources_600865(path: JsonNode;
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
  var valid_600867 = query.getOrDefault("EnvironmentName")
  valid_600867 = validateParameter(valid_600867, JString, required = false,
                                 default = nil)
  if valid_600867 != nil:
    section.add "EnvironmentName", valid_600867
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600868 = query.getOrDefault("Action")
  valid_600868 = validateParameter(valid_600868, JString, required = true, default = newJString(
      "DescribeEnvironmentResources"))
  if valid_600868 != nil:
    section.add "Action", valid_600868
  var valid_600869 = query.getOrDefault("EnvironmentId")
  valid_600869 = validateParameter(valid_600869, JString, required = false,
                                 default = nil)
  if valid_600869 != nil:
    section.add "EnvironmentId", valid_600869
  var valid_600870 = query.getOrDefault("Version")
  valid_600870 = validateParameter(valid_600870, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600870 != nil:
    section.add "Version", valid_600870
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600871 = header.getOrDefault("X-Amz-Date")
  valid_600871 = validateParameter(valid_600871, JString, required = false,
                                 default = nil)
  if valid_600871 != nil:
    section.add "X-Amz-Date", valid_600871
  var valid_600872 = header.getOrDefault("X-Amz-Security-Token")
  valid_600872 = validateParameter(valid_600872, JString, required = false,
                                 default = nil)
  if valid_600872 != nil:
    section.add "X-Amz-Security-Token", valid_600872
  var valid_600873 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600873 = validateParameter(valid_600873, JString, required = false,
                                 default = nil)
  if valid_600873 != nil:
    section.add "X-Amz-Content-Sha256", valid_600873
  var valid_600874 = header.getOrDefault("X-Amz-Algorithm")
  valid_600874 = validateParameter(valid_600874, JString, required = false,
                                 default = nil)
  if valid_600874 != nil:
    section.add "X-Amz-Algorithm", valid_600874
  var valid_600875 = header.getOrDefault("X-Amz-Signature")
  valid_600875 = validateParameter(valid_600875, JString, required = false,
                                 default = nil)
  if valid_600875 != nil:
    section.add "X-Amz-Signature", valid_600875
  var valid_600876 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600876 = validateParameter(valid_600876, JString, required = false,
                                 default = nil)
  if valid_600876 != nil:
    section.add "X-Amz-SignedHeaders", valid_600876
  var valid_600877 = header.getOrDefault("X-Amz-Credential")
  valid_600877 = validateParameter(valid_600877, JString, required = false,
                                 default = nil)
  if valid_600877 != nil:
    section.add "X-Amz-Credential", valid_600877
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600878: Call_GetDescribeEnvironmentResources_600864;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns AWS resources for this environment.
  ## 
  let valid = call_600878.validator(path, query, header, formData, body)
  let scheme = call_600878.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600878.url(scheme.get, call_600878.host, call_600878.base,
                         call_600878.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600878, url, valid)

proc call*(call_600879: Call_GetDescribeEnvironmentResources_600864;
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
  var query_600880 = newJObject()
  add(query_600880, "EnvironmentName", newJString(EnvironmentName))
  add(query_600880, "Action", newJString(Action))
  add(query_600880, "EnvironmentId", newJString(EnvironmentId))
  add(query_600880, "Version", newJString(Version))
  result = call_600879.call(nil, query_600880, nil, nil, nil)

var getDescribeEnvironmentResources* = Call_GetDescribeEnvironmentResources_600864(
    name: "getDescribeEnvironmentResources", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentResources",
    validator: validate_GetDescribeEnvironmentResources_600865, base: "/",
    url: url_GetDescribeEnvironmentResources_600866,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironments_600922 = ref object of OpenApiRestCall_599369
proc url_PostDescribeEnvironments_600924(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEnvironments_600923(path: JsonNode; query: JsonNode;
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
  var valid_600925 = query.getOrDefault("Action")
  valid_600925 = validateParameter(valid_600925, JString, required = true,
                                 default = newJString("DescribeEnvironments"))
  if valid_600925 != nil:
    section.add "Action", valid_600925
  var valid_600926 = query.getOrDefault("Version")
  valid_600926 = validateParameter(valid_600926, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600926 != nil:
    section.add "Version", valid_600926
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600927 = header.getOrDefault("X-Amz-Date")
  valid_600927 = validateParameter(valid_600927, JString, required = false,
                                 default = nil)
  if valid_600927 != nil:
    section.add "X-Amz-Date", valid_600927
  var valid_600928 = header.getOrDefault("X-Amz-Security-Token")
  valid_600928 = validateParameter(valid_600928, JString, required = false,
                                 default = nil)
  if valid_600928 != nil:
    section.add "X-Amz-Security-Token", valid_600928
  var valid_600929 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600929 = validateParameter(valid_600929, JString, required = false,
                                 default = nil)
  if valid_600929 != nil:
    section.add "X-Amz-Content-Sha256", valid_600929
  var valid_600930 = header.getOrDefault("X-Amz-Algorithm")
  valid_600930 = validateParameter(valid_600930, JString, required = false,
                                 default = nil)
  if valid_600930 != nil:
    section.add "X-Amz-Algorithm", valid_600930
  var valid_600931 = header.getOrDefault("X-Amz-Signature")
  valid_600931 = validateParameter(valid_600931, JString, required = false,
                                 default = nil)
  if valid_600931 != nil:
    section.add "X-Amz-Signature", valid_600931
  var valid_600932 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600932 = validateParameter(valid_600932, JString, required = false,
                                 default = nil)
  if valid_600932 != nil:
    section.add "X-Amz-SignedHeaders", valid_600932
  var valid_600933 = header.getOrDefault("X-Amz-Credential")
  valid_600933 = validateParameter(valid_600933, JString, required = false,
                                 default = nil)
  if valid_600933 != nil:
    section.add "X-Amz-Credential", valid_600933
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
  var valid_600934 = formData.getOrDefault("NextToken")
  valid_600934 = validateParameter(valid_600934, JString, required = false,
                                 default = nil)
  if valid_600934 != nil:
    section.add "NextToken", valid_600934
  var valid_600935 = formData.getOrDefault("VersionLabel")
  valid_600935 = validateParameter(valid_600935, JString, required = false,
                                 default = nil)
  if valid_600935 != nil:
    section.add "VersionLabel", valid_600935
  var valid_600936 = formData.getOrDefault("EnvironmentNames")
  valid_600936 = validateParameter(valid_600936, JArray, required = false,
                                 default = nil)
  if valid_600936 != nil:
    section.add "EnvironmentNames", valid_600936
  var valid_600937 = formData.getOrDefault("IncludedDeletedBackTo")
  valid_600937 = validateParameter(valid_600937, JString, required = false,
                                 default = nil)
  if valid_600937 != nil:
    section.add "IncludedDeletedBackTo", valid_600937
  var valid_600938 = formData.getOrDefault("ApplicationName")
  valid_600938 = validateParameter(valid_600938, JString, required = false,
                                 default = nil)
  if valid_600938 != nil:
    section.add "ApplicationName", valid_600938
  var valid_600939 = formData.getOrDefault("EnvironmentIds")
  valid_600939 = validateParameter(valid_600939, JArray, required = false,
                                 default = nil)
  if valid_600939 != nil:
    section.add "EnvironmentIds", valid_600939
  var valid_600940 = formData.getOrDefault("IncludeDeleted")
  valid_600940 = validateParameter(valid_600940, JBool, required = false, default = nil)
  if valid_600940 != nil:
    section.add "IncludeDeleted", valid_600940
  var valid_600941 = formData.getOrDefault("MaxRecords")
  valid_600941 = validateParameter(valid_600941, JInt, required = false, default = nil)
  if valid_600941 != nil:
    section.add "MaxRecords", valid_600941
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600942: Call_PostDescribeEnvironments_600922; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns descriptions for existing environments.
  ## 
  let valid = call_600942.validator(path, query, header, formData, body)
  let scheme = call_600942.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600942.url(scheme.get, call_600942.host, call_600942.base,
                         call_600942.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600942, url, valid)

proc call*(call_600943: Call_PostDescribeEnvironments_600922;
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
  var query_600944 = newJObject()
  var formData_600945 = newJObject()
  add(formData_600945, "NextToken", newJString(NextToken))
  add(formData_600945, "VersionLabel", newJString(VersionLabel))
  if EnvironmentNames != nil:
    formData_600945.add "EnvironmentNames", EnvironmentNames
  add(formData_600945, "IncludedDeletedBackTo", newJString(IncludedDeletedBackTo))
  add(query_600944, "Action", newJString(Action))
  add(formData_600945, "ApplicationName", newJString(ApplicationName))
  if EnvironmentIds != nil:
    formData_600945.add "EnvironmentIds", EnvironmentIds
  add(formData_600945, "IncludeDeleted", newJBool(IncludeDeleted))
  add(formData_600945, "MaxRecords", newJInt(MaxRecords))
  add(query_600944, "Version", newJString(Version))
  result = call_600943.call(nil, query_600944, nil, formData_600945, nil)

var postDescribeEnvironments* = Call_PostDescribeEnvironments_600922(
    name: "postDescribeEnvironments", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironments",
    validator: validate_PostDescribeEnvironments_600923, base: "/",
    url: url_PostDescribeEnvironments_600924, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironments_600899 = ref object of OpenApiRestCall_599369
proc url_GetDescribeEnvironments_600901(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEnvironments_600900(path: JsonNode; query: JsonNode;
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
  var valid_600902 = query.getOrDefault("VersionLabel")
  valid_600902 = validateParameter(valid_600902, JString, required = false,
                                 default = nil)
  if valid_600902 != nil:
    section.add "VersionLabel", valid_600902
  var valid_600903 = query.getOrDefault("MaxRecords")
  valid_600903 = validateParameter(valid_600903, JInt, required = false, default = nil)
  if valid_600903 != nil:
    section.add "MaxRecords", valid_600903
  var valid_600904 = query.getOrDefault("ApplicationName")
  valid_600904 = validateParameter(valid_600904, JString, required = false,
                                 default = nil)
  if valid_600904 != nil:
    section.add "ApplicationName", valid_600904
  var valid_600905 = query.getOrDefault("IncludeDeleted")
  valid_600905 = validateParameter(valid_600905, JBool, required = false, default = nil)
  if valid_600905 != nil:
    section.add "IncludeDeleted", valid_600905
  var valid_600906 = query.getOrDefault("NextToken")
  valid_600906 = validateParameter(valid_600906, JString, required = false,
                                 default = nil)
  if valid_600906 != nil:
    section.add "NextToken", valid_600906
  var valid_600907 = query.getOrDefault("EnvironmentIds")
  valid_600907 = validateParameter(valid_600907, JArray, required = false,
                                 default = nil)
  if valid_600907 != nil:
    section.add "EnvironmentIds", valid_600907
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600908 = query.getOrDefault("Action")
  valid_600908 = validateParameter(valid_600908, JString, required = true,
                                 default = newJString("DescribeEnvironments"))
  if valid_600908 != nil:
    section.add "Action", valid_600908
  var valid_600909 = query.getOrDefault("IncludedDeletedBackTo")
  valid_600909 = validateParameter(valid_600909, JString, required = false,
                                 default = nil)
  if valid_600909 != nil:
    section.add "IncludedDeletedBackTo", valid_600909
  var valid_600910 = query.getOrDefault("EnvironmentNames")
  valid_600910 = validateParameter(valid_600910, JArray, required = false,
                                 default = nil)
  if valid_600910 != nil:
    section.add "EnvironmentNames", valid_600910
  var valid_600911 = query.getOrDefault("Version")
  valid_600911 = validateParameter(valid_600911, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600911 != nil:
    section.add "Version", valid_600911
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600912 = header.getOrDefault("X-Amz-Date")
  valid_600912 = validateParameter(valid_600912, JString, required = false,
                                 default = nil)
  if valid_600912 != nil:
    section.add "X-Amz-Date", valid_600912
  var valid_600913 = header.getOrDefault("X-Amz-Security-Token")
  valid_600913 = validateParameter(valid_600913, JString, required = false,
                                 default = nil)
  if valid_600913 != nil:
    section.add "X-Amz-Security-Token", valid_600913
  var valid_600914 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600914 = validateParameter(valid_600914, JString, required = false,
                                 default = nil)
  if valid_600914 != nil:
    section.add "X-Amz-Content-Sha256", valid_600914
  var valid_600915 = header.getOrDefault("X-Amz-Algorithm")
  valid_600915 = validateParameter(valid_600915, JString, required = false,
                                 default = nil)
  if valid_600915 != nil:
    section.add "X-Amz-Algorithm", valid_600915
  var valid_600916 = header.getOrDefault("X-Amz-Signature")
  valid_600916 = validateParameter(valid_600916, JString, required = false,
                                 default = nil)
  if valid_600916 != nil:
    section.add "X-Amz-Signature", valid_600916
  var valid_600917 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600917 = validateParameter(valid_600917, JString, required = false,
                                 default = nil)
  if valid_600917 != nil:
    section.add "X-Amz-SignedHeaders", valid_600917
  var valid_600918 = header.getOrDefault("X-Amz-Credential")
  valid_600918 = validateParameter(valid_600918, JString, required = false,
                                 default = nil)
  if valid_600918 != nil:
    section.add "X-Amz-Credential", valid_600918
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600919: Call_GetDescribeEnvironments_600899; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns descriptions for existing environments.
  ## 
  let valid = call_600919.validator(path, query, header, formData, body)
  let scheme = call_600919.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600919.url(scheme.get, call_600919.host, call_600919.base,
                         call_600919.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600919, url, valid)

proc call*(call_600920: Call_GetDescribeEnvironments_600899;
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
  var query_600921 = newJObject()
  add(query_600921, "VersionLabel", newJString(VersionLabel))
  add(query_600921, "MaxRecords", newJInt(MaxRecords))
  add(query_600921, "ApplicationName", newJString(ApplicationName))
  add(query_600921, "IncludeDeleted", newJBool(IncludeDeleted))
  add(query_600921, "NextToken", newJString(NextToken))
  if EnvironmentIds != nil:
    query_600921.add "EnvironmentIds", EnvironmentIds
  add(query_600921, "Action", newJString(Action))
  add(query_600921, "IncludedDeletedBackTo", newJString(IncludedDeletedBackTo))
  if EnvironmentNames != nil:
    query_600921.add "EnvironmentNames", EnvironmentNames
  add(query_600921, "Version", newJString(Version))
  result = call_600920.call(nil, query_600921, nil, nil, nil)

var getDescribeEnvironments* = Call_GetDescribeEnvironments_600899(
    name: "getDescribeEnvironments", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironments",
    validator: validate_GetDescribeEnvironments_600900, base: "/",
    url: url_GetDescribeEnvironments_600901, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_600973 = ref object of OpenApiRestCall_599369
proc url_PostDescribeEvents_600975(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEvents_600974(path: JsonNode; query: JsonNode;
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
  var valid_600976 = query.getOrDefault("Action")
  valid_600976 = validateParameter(valid_600976, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_600976 != nil:
    section.add "Action", valid_600976
  var valid_600977 = query.getOrDefault("Version")
  valid_600977 = validateParameter(valid_600977, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600977 != nil:
    section.add "Version", valid_600977
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600978 = header.getOrDefault("X-Amz-Date")
  valid_600978 = validateParameter(valid_600978, JString, required = false,
                                 default = nil)
  if valid_600978 != nil:
    section.add "X-Amz-Date", valid_600978
  var valid_600979 = header.getOrDefault("X-Amz-Security-Token")
  valid_600979 = validateParameter(valid_600979, JString, required = false,
                                 default = nil)
  if valid_600979 != nil:
    section.add "X-Amz-Security-Token", valid_600979
  var valid_600980 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600980 = validateParameter(valid_600980, JString, required = false,
                                 default = nil)
  if valid_600980 != nil:
    section.add "X-Amz-Content-Sha256", valid_600980
  var valid_600981 = header.getOrDefault("X-Amz-Algorithm")
  valid_600981 = validateParameter(valid_600981, JString, required = false,
                                 default = nil)
  if valid_600981 != nil:
    section.add "X-Amz-Algorithm", valid_600981
  var valid_600982 = header.getOrDefault("X-Amz-Signature")
  valid_600982 = validateParameter(valid_600982, JString, required = false,
                                 default = nil)
  if valid_600982 != nil:
    section.add "X-Amz-Signature", valid_600982
  var valid_600983 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600983 = validateParameter(valid_600983, JString, required = false,
                                 default = nil)
  if valid_600983 != nil:
    section.add "X-Amz-SignedHeaders", valid_600983
  var valid_600984 = header.getOrDefault("X-Amz-Credential")
  valid_600984 = validateParameter(valid_600984, JString, required = false,
                                 default = nil)
  if valid_600984 != nil:
    section.add "X-Amz-Credential", valid_600984
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
  var valid_600985 = formData.getOrDefault("NextToken")
  valid_600985 = validateParameter(valid_600985, JString, required = false,
                                 default = nil)
  if valid_600985 != nil:
    section.add "NextToken", valid_600985
  var valid_600986 = formData.getOrDefault("VersionLabel")
  valid_600986 = validateParameter(valid_600986, JString, required = false,
                                 default = nil)
  if valid_600986 != nil:
    section.add "VersionLabel", valid_600986
  var valid_600987 = formData.getOrDefault("Severity")
  valid_600987 = validateParameter(valid_600987, JString, required = false,
                                 default = newJString("TRACE"))
  if valid_600987 != nil:
    section.add "Severity", valid_600987
  var valid_600988 = formData.getOrDefault("EnvironmentId")
  valid_600988 = validateParameter(valid_600988, JString, required = false,
                                 default = nil)
  if valid_600988 != nil:
    section.add "EnvironmentId", valid_600988
  var valid_600989 = formData.getOrDefault("EnvironmentName")
  valid_600989 = validateParameter(valid_600989, JString, required = false,
                                 default = nil)
  if valid_600989 != nil:
    section.add "EnvironmentName", valid_600989
  var valid_600990 = formData.getOrDefault("StartTime")
  valid_600990 = validateParameter(valid_600990, JString, required = false,
                                 default = nil)
  if valid_600990 != nil:
    section.add "StartTime", valid_600990
  var valid_600991 = formData.getOrDefault("ApplicationName")
  valid_600991 = validateParameter(valid_600991, JString, required = false,
                                 default = nil)
  if valid_600991 != nil:
    section.add "ApplicationName", valid_600991
  var valid_600992 = formData.getOrDefault("EndTime")
  valid_600992 = validateParameter(valid_600992, JString, required = false,
                                 default = nil)
  if valid_600992 != nil:
    section.add "EndTime", valid_600992
  var valid_600993 = formData.getOrDefault("PlatformArn")
  valid_600993 = validateParameter(valid_600993, JString, required = false,
                                 default = nil)
  if valid_600993 != nil:
    section.add "PlatformArn", valid_600993
  var valid_600994 = formData.getOrDefault("MaxRecords")
  valid_600994 = validateParameter(valid_600994, JInt, required = false, default = nil)
  if valid_600994 != nil:
    section.add "MaxRecords", valid_600994
  var valid_600995 = formData.getOrDefault("RequestId")
  valid_600995 = validateParameter(valid_600995, JString, required = false,
                                 default = nil)
  if valid_600995 != nil:
    section.add "RequestId", valid_600995
  var valid_600996 = formData.getOrDefault("TemplateName")
  valid_600996 = validateParameter(valid_600996, JString, required = false,
                                 default = nil)
  if valid_600996 != nil:
    section.add "TemplateName", valid_600996
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600997: Call_PostDescribeEvents_600973; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns list of event descriptions matching criteria up to the last 6 weeks.</p> <note> <p>This action returns the most recent 1,000 events from the specified <code>NextToken</code>.</p> </note>
  ## 
  let valid = call_600997.validator(path, query, header, formData, body)
  let scheme = call_600997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600997.url(scheme.get, call_600997.host, call_600997.base,
                         call_600997.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600997, url, valid)

proc call*(call_600998: Call_PostDescribeEvents_600973; NextToken: string = "";
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
  var query_600999 = newJObject()
  var formData_601000 = newJObject()
  add(formData_601000, "NextToken", newJString(NextToken))
  add(formData_601000, "VersionLabel", newJString(VersionLabel))
  add(formData_601000, "Severity", newJString(Severity))
  add(formData_601000, "EnvironmentId", newJString(EnvironmentId))
  add(formData_601000, "EnvironmentName", newJString(EnvironmentName))
  add(formData_601000, "StartTime", newJString(StartTime))
  add(query_600999, "Action", newJString(Action))
  add(formData_601000, "ApplicationName", newJString(ApplicationName))
  add(formData_601000, "EndTime", newJString(EndTime))
  add(formData_601000, "PlatformArn", newJString(PlatformArn))
  add(formData_601000, "MaxRecords", newJInt(MaxRecords))
  add(formData_601000, "RequestId", newJString(RequestId))
  add(formData_601000, "TemplateName", newJString(TemplateName))
  add(query_600999, "Version", newJString(Version))
  result = call_600998.call(nil, query_600999, nil, formData_601000, nil)

var postDescribeEvents* = Call_PostDescribeEvents_600973(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_600974, base: "/",
    url: url_PostDescribeEvents_600975, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_600946 = ref object of OpenApiRestCall_599369
proc url_GetDescribeEvents_600948(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEvents_600947(path: JsonNode; query: JsonNode;
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
  var valid_600949 = query.getOrDefault("VersionLabel")
  valid_600949 = validateParameter(valid_600949, JString, required = false,
                                 default = nil)
  if valid_600949 != nil:
    section.add "VersionLabel", valid_600949
  var valid_600950 = query.getOrDefault("MaxRecords")
  valid_600950 = validateParameter(valid_600950, JInt, required = false, default = nil)
  if valid_600950 != nil:
    section.add "MaxRecords", valid_600950
  var valid_600951 = query.getOrDefault("ApplicationName")
  valid_600951 = validateParameter(valid_600951, JString, required = false,
                                 default = nil)
  if valid_600951 != nil:
    section.add "ApplicationName", valid_600951
  var valid_600952 = query.getOrDefault("StartTime")
  valid_600952 = validateParameter(valid_600952, JString, required = false,
                                 default = nil)
  if valid_600952 != nil:
    section.add "StartTime", valid_600952
  var valid_600953 = query.getOrDefault("PlatformArn")
  valid_600953 = validateParameter(valid_600953, JString, required = false,
                                 default = nil)
  if valid_600953 != nil:
    section.add "PlatformArn", valid_600953
  var valid_600954 = query.getOrDefault("NextToken")
  valid_600954 = validateParameter(valid_600954, JString, required = false,
                                 default = nil)
  if valid_600954 != nil:
    section.add "NextToken", valid_600954
  var valid_600955 = query.getOrDefault("EnvironmentName")
  valid_600955 = validateParameter(valid_600955, JString, required = false,
                                 default = nil)
  if valid_600955 != nil:
    section.add "EnvironmentName", valid_600955
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600956 = query.getOrDefault("Action")
  valid_600956 = validateParameter(valid_600956, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_600956 != nil:
    section.add "Action", valid_600956
  var valid_600957 = query.getOrDefault("EnvironmentId")
  valid_600957 = validateParameter(valid_600957, JString, required = false,
                                 default = nil)
  if valid_600957 != nil:
    section.add "EnvironmentId", valid_600957
  var valid_600958 = query.getOrDefault("TemplateName")
  valid_600958 = validateParameter(valid_600958, JString, required = false,
                                 default = nil)
  if valid_600958 != nil:
    section.add "TemplateName", valid_600958
  var valid_600959 = query.getOrDefault("Severity")
  valid_600959 = validateParameter(valid_600959, JString, required = false,
                                 default = newJString("TRACE"))
  if valid_600959 != nil:
    section.add "Severity", valid_600959
  var valid_600960 = query.getOrDefault("RequestId")
  valid_600960 = validateParameter(valid_600960, JString, required = false,
                                 default = nil)
  if valid_600960 != nil:
    section.add "RequestId", valid_600960
  var valid_600961 = query.getOrDefault("EndTime")
  valid_600961 = validateParameter(valid_600961, JString, required = false,
                                 default = nil)
  if valid_600961 != nil:
    section.add "EndTime", valid_600961
  var valid_600962 = query.getOrDefault("Version")
  valid_600962 = validateParameter(valid_600962, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_600962 != nil:
    section.add "Version", valid_600962
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600963 = header.getOrDefault("X-Amz-Date")
  valid_600963 = validateParameter(valid_600963, JString, required = false,
                                 default = nil)
  if valid_600963 != nil:
    section.add "X-Amz-Date", valid_600963
  var valid_600964 = header.getOrDefault("X-Amz-Security-Token")
  valid_600964 = validateParameter(valid_600964, JString, required = false,
                                 default = nil)
  if valid_600964 != nil:
    section.add "X-Amz-Security-Token", valid_600964
  var valid_600965 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600965 = validateParameter(valid_600965, JString, required = false,
                                 default = nil)
  if valid_600965 != nil:
    section.add "X-Amz-Content-Sha256", valid_600965
  var valid_600966 = header.getOrDefault("X-Amz-Algorithm")
  valid_600966 = validateParameter(valid_600966, JString, required = false,
                                 default = nil)
  if valid_600966 != nil:
    section.add "X-Amz-Algorithm", valid_600966
  var valid_600967 = header.getOrDefault("X-Amz-Signature")
  valid_600967 = validateParameter(valid_600967, JString, required = false,
                                 default = nil)
  if valid_600967 != nil:
    section.add "X-Amz-Signature", valid_600967
  var valid_600968 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600968 = validateParameter(valid_600968, JString, required = false,
                                 default = nil)
  if valid_600968 != nil:
    section.add "X-Amz-SignedHeaders", valid_600968
  var valid_600969 = header.getOrDefault("X-Amz-Credential")
  valid_600969 = validateParameter(valid_600969, JString, required = false,
                                 default = nil)
  if valid_600969 != nil:
    section.add "X-Amz-Credential", valid_600969
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600970: Call_GetDescribeEvents_600946; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns list of event descriptions matching criteria up to the last 6 weeks.</p> <note> <p>This action returns the most recent 1,000 events from the specified <code>NextToken</code>.</p> </note>
  ## 
  let valid = call_600970.validator(path, query, header, formData, body)
  let scheme = call_600970.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600970.url(scheme.get, call_600970.host, call_600970.base,
                         call_600970.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600970, url, valid)

proc call*(call_600971: Call_GetDescribeEvents_600946; VersionLabel: string = "";
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
  var query_600972 = newJObject()
  add(query_600972, "VersionLabel", newJString(VersionLabel))
  add(query_600972, "MaxRecords", newJInt(MaxRecords))
  add(query_600972, "ApplicationName", newJString(ApplicationName))
  add(query_600972, "StartTime", newJString(StartTime))
  add(query_600972, "PlatformArn", newJString(PlatformArn))
  add(query_600972, "NextToken", newJString(NextToken))
  add(query_600972, "EnvironmentName", newJString(EnvironmentName))
  add(query_600972, "Action", newJString(Action))
  add(query_600972, "EnvironmentId", newJString(EnvironmentId))
  add(query_600972, "TemplateName", newJString(TemplateName))
  add(query_600972, "Severity", newJString(Severity))
  add(query_600972, "RequestId", newJString(RequestId))
  add(query_600972, "EndTime", newJString(EndTime))
  add(query_600972, "Version", newJString(Version))
  result = call_600971.call(nil, query_600972, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_600946(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_600947,
    base: "/", url: url_GetDescribeEvents_600948,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeInstancesHealth_601020 = ref object of OpenApiRestCall_599369
proc url_PostDescribeInstancesHealth_601022(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeInstancesHealth_601021(path: JsonNode; query: JsonNode;
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
  var valid_601023 = query.getOrDefault("Action")
  valid_601023 = validateParameter(valid_601023, JString, required = true, default = newJString(
      "DescribeInstancesHealth"))
  if valid_601023 != nil:
    section.add "Action", valid_601023
  var valid_601024 = query.getOrDefault("Version")
  valid_601024 = validateParameter(valid_601024, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601024 != nil:
    section.add "Version", valid_601024
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601025 = header.getOrDefault("X-Amz-Date")
  valid_601025 = validateParameter(valid_601025, JString, required = false,
                                 default = nil)
  if valid_601025 != nil:
    section.add "X-Amz-Date", valid_601025
  var valid_601026 = header.getOrDefault("X-Amz-Security-Token")
  valid_601026 = validateParameter(valid_601026, JString, required = false,
                                 default = nil)
  if valid_601026 != nil:
    section.add "X-Amz-Security-Token", valid_601026
  var valid_601027 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601027 = validateParameter(valid_601027, JString, required = false,
                                 default = nil)
  if valid_601027 != nil:
    section.add "X-Amz-Content-Sha256", valid_601027
  var valid_601028 = header.getOrDefault("X-Amz-Algorithm")
  valid_601028 = validateParameter(valid_601028, JString, required = false,
                                 default = nil)
  if valid_601028 != nil:
    section.add "X-Amz-Algorithm", valid_601028
  var valid_601029 = header.getOrDefault("X-Amz-Signature")
  valid_601029 = validateParameter(valid_601029, JString, required = false,
                                 default = nil)
  if valid_601029 != nil:
    section.add "X-Amz-Signature", valid_601029
  var valid_601030 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601030 = validateParameter(valid_601030, JString, required = false,
                                 default = nil)
  if valid_601030 != nil:
    section.add "X-Amz-SignedHeaders", valid_601030
  var valid_601031 = header.getOrDefault("X-Amz-Credential")
  valid_601031 = validateParameter(valid_601031, JString, required = false,
                                 default = nil)
  if valid_601031 != nil:
    section.add "X-Amz-Credential", valid_601031
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
  var valid_601032 = formData.getOrDefault("NextToken")
  valid_601032 = validateParameter(valid_601032, JString, required = false,
                                 default = nil)
  if valid_601032 != nil:
    section.add "NextToken", valid_601032
  var valid_601033 = formData.getOrDefault("EnvironmentId")
  valid_601033 = validateParameter(valid_601033, JString, required = false,
                                 default = nil)
  if valid_601033 != nil:
    section.add "EnvironmentId", valid_601033
  var valid_601034 = formData.getOrDefault("EnvironmentName")
  valid_601034 = validateParameter(valid_601034, JString, required = false,
                                 default = nil)
  if valid_601034 != nil:
    section.add "EnvironmentName", valid_601034
  var valid_601035 = formData.getOrDefault("AttributeNames")
  valid_601035 = validateParameter(valid_601035, JArray, required = false,
                                 default = nil)
  if valid_601035 != nil:
    section.add "AttributeNames", valid_601035
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601036: Call_PostDescribeInstancesHealth_601020; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves detailed information about the health of instances in your AWS Elastic Beanstalk. This operation requires <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/health-enhanced.html">enhanced health reporting</a>.
  ## 
  let valid = call_601036.validator(path, query, header, formData, body)
  let scheme = call_601036.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601036.url(scheme.get, call_601036.host, call_601036.base,
                         call_601036.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601036, url, valid)

proc call*(call_601037: Call_PostDescribeInstancesHealth_601020;
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
  var query_601038 = newJObject()
  var formData_601039 = newJObject()
  add(formData_601039, "NextToken", newJString(NextToken))
  add(formData_601039, "EnvironmentId", newJString(EnvironmentId))
  add(formData_601039, "EnvironmentName", newJString(EnvironmentName))
  add(query_601038, "Action", newJString(Action))
  if AttributeNames != nil:
    formData_601039.add "AttributeNames", AttributeNames
  add(query_601038, "Version", newJString(Version))
  result = call_601037.call(nil, query_601038, nil, formData_601039, nil)

var postDescribeInstancesHealth* = Call_PostDescribeInstancesHealth_601020(
    name: "postDescribeInstancesHealth", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeInstancesHealth",
    validator: validate_PostDescribeInstancesHealth_601021, base: "/",
    url: url_PostDescribeInstancesHealth_601022,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeInstancesHealth_601001 = ref object of OpenApiRestCall_599369
proc url_GetDescribeInstancesHealth_601003(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeInstancesHealth_601002(path: JsonNode; query: JsonNode;
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
  var valid_601004 = query.getOrDefault("AttributeNames")
  valid_601004 = validateParameter(valid_601004, JArray, required = false,
                                 default = nil)
  if valid_601004 != nil:
    section.add "AttributeNames", valid_601004
  var valid_601005 = query.getOrDefault("NextToken")
  valid_601005 = validateParameter(valid_601005, JString, required = false,
                                 default = nil)
  if valid_601005 != nil:
    section.add "NextToken", valid_601005
  var valid_601006 = query.getOrDefault("EnvironmentName")
  valid_601006 = validateParameter(valid_601006, JString, required = false,
                                 default = nil)
  if valid_601006 != nil:
    section.add "EnvironmentName", valid_601006
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601007 = query.getOrDefault("Action")
  valid_601007 = validateParameter(valid_601007, JString, required = true, default = newJString(
      "DescribeInstancesHealth"))
  if valid_601007 != nil:
    section.add "Action", valid_601007
  var valid_601008 = query.getOrDefault("EnvironmentId")
  valid_601008 = validateParameter(valid_601008, JString, required = false,
                                 default = nil)
  if valid_601008 != nil:
    section.add "EnvironmentId", valid_601008
  var valid_601009 = query.getOrDefault("Version")
  valid_601009 = validateParameter(valid_601009, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601009 != nil:
    section.add "Version", valid_601009
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601010 = header.getOrDefault("X-Amz-Date")
  valid_601010 = validateParameter(valid_601010, JString, required = false,
                                 default = nil)
  if valid_601010 != nil:
    section.add "X-Amz-Date", valid_601010
  var valid_601011 = header.getOrDefault("X-Amz-Security-Token")
  valid_601011 = validateParameter(valid_601011, JString, required = false,
                                 default = nil)
  if valid_601011 != nil:
    section.add "X-Amz-Security-Token", valid_601011
  var valid_601012 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601012 = validateParameter(valid_601012, JString, required = false,
                                 default = nil)
  if valid_601012 != nil:
    section.add "X-Amz-Content-Sha256", valid_601012
  var valid_601013 = header.getOrDefault("X-Amz-Algorithm")
  valid_601013 = validateParameter(valid_601013, JString, required = false,
                                 default = nil)
  if valid_601013 != nil:
    section.add "X-Amz-Algorithm", valid_601013
  var valid_601014 = header.getOrDefault("X-Amz-Signature")
  valid_601014 = validateParameter(valid_601014, JString, required = false,
                                 default = nil)
  if valid_601014 != nil:
    section.add "X-Amz-Signature", valid_601014
  var valid_601015 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601015 = validateParameter(valid_601015, JString, required = false,
                                 default = nil)
  if valid_601015 != nil:
    section.add "X-Amz-SignedHeaders", valid_601015
  var valid_601016 = header.getOrDefault("X-Amz-Credential")
  valid_601016 = validateParameter(valid_601016, JString, required = false,
                                 default = nil)
  if valid_601016 != nil:
    section.add "X-Amz-Credential", valid_601016
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601017: Call_GetDescribeInstancesHealth_601001; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves detailed information about the health of instances in your AWS Elastic Beanstalk. This operation requires <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/health-enhanced.html">enhanced health reporting</a>.
  ## 
  let valid = call_601017.validator(path, query, header, formData, body)
  let scheme = call_601017.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601017.url(scheme.get, call_601017.host, call_601017.base,
                         call_601017.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601017, url, valid)

proc call*(call_601018: Call_GetDescribeInstancesHealth_601001;
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
  var query_601019 = newJObject()
  if AttributeNames != nil:
    query_601019.add "AttributeNames", AttributeNames
  add(query_601019, "NextToken", newJString(NextToken))
  add(query_601019, "EnvironmentName", newJString(EnvironmentName))
  add(query_601019, "Action", newJString(Action))
  add(query_601019, "EnvironmentId", newJString(EnvironmentId))
  add(query_601019, "Version", newJString(Version))
  result = call_601018.call(nil, query_601019, nil, nil, nil)

var getDescribeInstancesHealth* = Call_GetDescribeInstancesHealth_601001(
    name: "getDescribeInstancesHealth", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeInstancesHealth",
    validator: validate_GetDescribeInstancesHealth_601002, base: "/",
    url: url_GetDescribeInstancesHealth_601003,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribePlatformVersion_601056 = ref object of OpenApiRestCall_599369
proc url_PostDescribePlatformVersion_601058(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribePlatformVersion_601057(path: JsonNode; query: JsonNode;
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
  var valid_601059 = query.getOrDefault("Action")
  valid_601059 = validateParameter(valid_601059, JString, required = true, default = newJString(
      "DescribePlatformVersion"))
  if valid_601059 != nil:
    section.add "Action", valid_601059
  var valid_601060 = query.getOrDefault("Version")
  valid_601060 = validateParameter(valid_601060, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601060 != nil:
    section.add "Version", valid_601060
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601061 = header.getOrDefault("X-Amz-Date")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-Date", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-Security-Token")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-Security-Token", valid_601062
  var valid_601063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601063 = validateParameter(valid_601063, JString, required = false,
                                 default = nil)
  if valid_601063 != nil:
    section.add "X-Amz-Content-Sha256", valid_601063
  var valid_601064 = header.getOrDefault("X-Amz-Algorithm")
  valid_601064 = validateParameter(valid_601064, JString, required = false,
                                 default = nil)
  if valid_601064 != nil:
    section.add "X-Amz-Algorithm", valid_601064
  var valid_601065 = header.getOrDefault("X-Amz-Signature")
  valid_601065 = validateParameter(valid_601065, JString, required = false,
                                 default = nil)
  if valid_601065 != nil:
    section.add "X-Amz-Signature", valid_601065
  var valid_601066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601066 = validateParameter(valid_601066, JString, required = false,
                                 default = nil)
  if valid_601066 != nil:
    section.add "X-Amz-SignedHeaders", valid_601066
  var valid_601067 = header.getOrDefault("X-Amz-Credential")
  valid_601067 = validateParameter(valid_601067, JString, required = false,
                                 default = nil)
  if valid_601067 != nil:
    section.add "X-Amz-Credential", valid_601067
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformArn: JString
  ##              : The ARN of the version of the platform.
  section = newJObject()
  var valid_601068 = formData.getOrDefault("PlatformArn")
  valid_601068 = validateParameter(valid_601068, JString, required = false,
                                 default = nil)
  if valid_601068 != nil:
    section.add "PlatformArn", valid_601068
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601069: Call_PostDescribePlatformVersion_601056; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the version of the platform.
  ## 
  let valid = call_601069.validator(path, query, header, formData, body)
  let scheme = call_601069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601069.url(scheme.get, call_601069.host, call_601069.base,
                         call_601069.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601069, url, valid)

proc call*(call_601070: Call_PostDescribePlatformVersion_601056;
          Action: string = "DescribePlatformVersion"; PlatformArn: string = "";
          Version: string = "2010-12-01"): Recallable =
  ## postDescribePlatformVersion
  ## Describes the version of the platform.
  ##   Action: string (required)
  ##   PlatformArn: string
  ##              : The ARN of the version of the platform.
  ##   Version: string (required)
  var query_601071 = newJObject()
  var formData_601072 = newJObject()
  add(query_601071, "Action", newJString(Action))
  add(formData_601072, "PlatformArn", newJString(PlatformArn))
  add(query_601071, "Version", newJString(Version))
  result = call_601070.call(nil, query_601071, nil, formData_601072, nil)

var postDescribePlatformVersion* = Call_PostDescribePlatformVersion_601056(
    name: "postDescribePlatformVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribePlatformVersion",
    validator: validate_PostDescribePlatformVersion_601057, base: "/",
    url: url_PostDescribePlatformVersion_601058,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribePlatformVersion_601040 = ref object of OpenApiRestCall_599369
proc url_GetDescribePlatformVersion_601042(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribePlatformVersion_601041(path: JsonNode; query: JsonNode;
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
  var valid_601043 = query.getOrDefault("PlatformArn")
  valid_601043 = validateParameter(valid_601043, JString, required = false,
                                 default = nil)
  if valid_601043 != nil:
    section.add "PlatformArn", valid_601043
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601044 = query.getOrDefault("Action")
  valid_601044 = validateParameter(valid_601044, JString, required = true, default = newJString(
      "DescribePlatformVersion"))
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601053: Call_GetDescribePlatformVersion_601040; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the version of the platform.
  ## 
  let valid = call_601053.validator(path, query, header, formData, body)
  let scheme = call_601053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601053.url(scheme.get, call_601053.host, call_601053.base,
                         call_601053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601053, url, valid)

proc call*(call_601054: Call_GetDescribePlatformVersion_601040;
          PlatformArn: string = ""; Action: string = "DescribePlatformVersion";
          Version: string = "2010-12-01"): Recallable =
  ## getDescribePlatformVersion
  ## Describes the version of the platform.
  ##   PlatformArn: string
  ##              : The ARN of the version of the platform.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601055 = newJObject()
  add(query_601055, "PlatformArn", newJString(PlatformArn))
  add(query_601055, "Action", newJString(Action))
  add(query_601055, "Version", newJString(Version))
  result = call_601054.call(nil, query_601055, nil, nil, nil)

var getDescribePlatformVersion* = Call_GetDescribePlatformVersion_601040(
    name: "getDescribePlatformVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribePlatformVersion",
    validator: validate_GetDescribePlatformVersion_601041, base: "/",
    url: url_GetDescribePlatformVersion_601042,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListAvailableSolutionStacks_601088 = ref object of OpenApiRestCall_599369
proc url_PostListAvailableSolutionStacks_601090(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListAvailableSolutionStacks_601089(path: JsonNode;
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
  var valid_601091 = query.getOrDefault("Action")
  valid_601091 = validateParameter(valid_601091, JString, required = true, default = newJString(
      "ListAvailableSolutionStacks"))
  if valid_601091 != nil:
    section.add "Action", valid_601091
  var valid_601092 = query.getOrDefault("Version")
  valid_601092 = validateParameter(valid_601092, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601092 != nil:
    section.add "Version", valid_601092
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601093 = header.getOrDefault("X-Amz-Date")
  valid_601093 = validateParameter(valid_601093, JString, required = false,
                                 default = nil)
  if valid_601093 != nil:
    section.add "X-Amz-Date", valid_601093
  var valid_601094 = header.getOrDefault("X-Amz-Security-Token")
  valid_601094 = validateParameter(valid_601094, JString, required = false,
                                 default = nil)
  if valid_601094 != nil:
    section.add "X-Amz-Security-Token", valid_601094
  var valid_601095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601095 = validateParameter(valid_601095, JString, required = false,
                                 default = nil)
  if valid_601095 != nil:
    section.add "X-Amz-Content-Sha256", valid_601095
  var valid_601096 = header.getOrDefault("X-Amz-Algorithm")
  valid_601096 = validateParameter(valid_601096, JString, required = false,
                                 default = nil)
  if valid_601096 != nil:
    section.add "X-Amz-Algorithm", valid_601096
  var valid_601097 = header.getOrDefault("X-Amz-Signature")
  valid_601097 = validateParameter(valid_601097, JString, required = false,
                                 default = nil)
  if valid_601097 != nil:
    section.add "X-Amz-Signature", valid_601097
  var valid_601098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601098 = validateParameter(valid_601098, JString, required = false,
                                 default = nil)
  if valid_601098 != nil:
    section.add "X-Amz-SignedHeaders", valid_601098
  var valid_601099 = header.getOrDefault("X-Amz-Credential")
  valid_601099 = validateParameter(valid_601099, JString, required = false,
                                 default = nil)
  if valid_601099 != nil:
    section.add "X-Amz-Credential", valid_601099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601100: Call_PostListAvailableSolutionStacks_601088;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ## 
  let valid = call_601100.validator(path, query, header, formData, body)
  let scheme = call_601100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601100.url(scheme.get, call_601100.host, call_601100.base,
                         call_601100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601100, url, valid)

proc call*(call_601101: Call_PostListAvailableSolutionStacks_601088;
          Action: string = "ListAvailableSolutionStacks";
          Version: string = "2010-12-01"): Recallable =
  ## postListAvailableSolutionStacks
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601102 = newJObject()
  add(query_601102, "Action", newJString(Action))
  add(query_601102, "Version", newJString(Version))
  result = call_601101.call(nil, query_601102, nil, nil, nil)

var postListAvailableSolutionStacks* = Call_PostListAvailableSolutionStacks_601088(
    name: "postListAvailableSolutionStacks", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListAvailableSolutionStacks",
    validator: validate_PostListAvailableSolutionStacks_601089, base: "/",
    url: url_PostListAvailableSolutionStacks_601090,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListAvailableSolutionStacks_601073 = ref object of OpenApiRestCall_599369
proc url_GetListAvailableSolutionStacks_601075(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListAvailableSolutionStacks_601074(path: JsonNode;
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
  var valid_601076 = query.getOrDefault("Action")
  valid_601076 = validateParameter(valid_601076, JString, required = true, default = newJString(
      "ListAvailableSolutionStacks"))
  if valid_601076 != nil:
    section.add "Action", valid_601076
  var valid_601077 = query.getOrDefault("Version")
  valid_601077 = validateParameter(valid_601077, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601077 != nil:
    section.add "Version", valid_601077
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601078 = header.getOrDefault("X-Amz-Date")
  valid_601078 = validateParameter(valid_601078, JString, required = false,
                                 default = nil)
  if valid_601078 != nil:
    section.add "X-Amz-Date", valid_601078
  var valid_601079 = header.getOrDefault("X-Amz-Security-Token")
  valid_601079 = validateParameter(valid_601079, JString, required = false,
                                 default = nil)
  if valid_601079 != nil:
    section.add "X-Amz-Security-Token", valid_601079
  var valid_601080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601080 = validateParameter(valid_601080, JString, required = false,
                                 default = nil)
  if valid_601080 != nil:
    section.add "X-Amz-Content-Sha256", valid_601080
  var valid_601081 = header.getOrDefault("X-Amz-Algorithm")
  valid_601081 = validateParameter(valid_601081, JString, required = false,
                                 default = nil)
  if valid_601081 != nil:
    section.add "X-Amz-Algorithm", valid_601081
  var valid_601082 = header.getOrDefault("X-Amz-Signature")
  valid_601082 = validateParameter(valid_601082, JString, required = false,
                                 default = nil)
  if valid_601082 != nil:
    section.add "X-Amz-Signature", valid_601082
  var valid_601083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601083 = validateParameter(valid_601083, JString, required = false,
                                 default = nil)
  if valid_601083 != nil:
    section.add "X-Amz-SignedHeaders", valid_601083
  var valid_601084 = header.getOrDefault("X-Amz-Credential")
  valid_601084 = validateParameter(valid_601084, JString, required = false,
                                 default = nil)
  if valid_601084 != nil:
    section.add "X-Amz-Credential", valid_601084
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601085: Call_GetListAvailableSolutionStacks_601073; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ## 
  let valid = call_601085.validator(path, query, header, formData, body)
  let scheme = call_601085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601085.url(scheme.get, call_601085.host, call_601085.base,
                         call_601085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601085, url, valid)

proc call*(call_601086: Call_GetListAvailableSolutionStacks_601073;
          Action: string = "ListAvailableSolutionStacks";
          Version: string = "2010-12-01"): Recallable =
  ## getListAvailableSolutionStacks
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601087 = newJObject()
  add(query_601087, "Action", newJString(Action))
  add(query_601087, "Version", newJString(Version))
  result = call_601086.call(nil, query_601087, nil, nil, nil)

var getListAvailableSolutionStacks* = Call_GetListAvailableSolutionStacks_601073(
    name: "getListAvailableSolutionStacks", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListAvailableSolutionStacks",
    validator: validate_GetListAvailableSolutionStacks_601074, base: "/",
    url: url_GetListAvailableSolutionStacks_601075,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListPlatformVersions_601121 = ref object of OpenApiRestCall_599369
proc url_PostListPlatformVersions_601123(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListPlatformVersions_601122(path: JsonNode; query: JsonNode;
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
  var valid_601124 = query.getOrDefault("Action")
  valid_601124 = validateParameter(valid_601124, JString, required = true,
                                 default = newJString("ListPlatformVersions"))
  if valid_601124 != nil:
    section.add "Action", valid_601124
  var valid_601125 = query.getOrDefault("Version")
  valid_601125 = validateParameter(valid_601125, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601125 != nil:
    section.add "Version", valid_601125
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601126 = header.getOrDefault("X-Amz-Date")
  valid_601126 = validateParameter(valid_601126, JString, required = false,
                                 default = nil)
  if valid_601126 != nil:
    section.add "X-Amz-Date", valid_601126
  var valid_601127 = header.getOrDefault("X-Amz-Security-Token")
  valid_601127 = validateParameter(valid_601127, JString, required = false,
                                 default = nil)
  if valid_601127 != nil:
    section.add "X-Amz-Security-Token", valid_601127
  var valid_601128 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601128 = validateParameter(valid_601128, JString, required = false,
                                 default = nil)
  if valid_601128 != nil:
    section.add "X-Amz-Content-Sha256", valid_601128
  var valid_601129 = header.getOrDefault("X-Amz-Algorithm")
  valid_601129 = validateParameter(valid_601129, JString, required = false,
                                 default = nil)
  if valid_601129 != nil:
    section.add "X-Amz-Algorithm", valid_601129
  var valid_601130 = header.getOrDefault("X-Amz-Signature")
  valid_601130 = validateParameter(valid_601130, JString, required = false,
                                 default = nil)
  if valid_601130 != nil:
    section.add "X-Amz-Signature", valid_601130
  var valid_601131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601131 = validateParameter(valid_601131, JString, required = false,
                                 default = nil)
  if valid_601131 != nil:
    section.add "X-Amz-SignedHeaders", valid_601131
  var valid_601132 = header.getOrDefault("X-Amz-Credential")
  valid_601132 = validateParameter(valid_601132, JString, required = false,
                                 default = nil)
  if valid_601132 != nil:
    section.add "X-Amz-Credential", valid_601132
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : The starting index into the remaining list of platforms. Use the <code>NextToken</code> value from a previous <code>ListPlatformVersion</code> call.
  ##   Filters: JArray
  ##          : List only the platforms where the platform member value relates to one of the supplied values.
  ##   MaxRecords: JInt
  ##             : The maximum number of platform values returned in one call.
  section = newJObject()
  var valid_601133 = formData.getOrDefault("NextToken")
  valid_601133 = validateParameter(valid_601133, JString, required = false,
                                 default = nil)
  if valid_601133 != nil:
    section.add "NextToken", valid_601133
  var valid_601134 = formData.getOrDefault("Filters")
  valid_601134 = validateParameter(valid_601134, JArray, required = false,
                                 default = nil)
  if valid_601134 != nil:
    section.add "Filters", valid_601134
  var valid_601135 = formData.getOrDefault("MaxRecords")
  valid_601135 = validateParameter(valid_601135, JInt, required = false, default = nil)
  if valid_601135 != nil:
    section.add "MaxRecords", valid_601135
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601136: Call_PostListPlatformVersions_601121; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the available platforms.
  ## 
  let valid = call_601136.validator(path, query, header, formData, body)
  let scheme = call_601136.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601136.url(scheme.get, call_601136.host, call_601136.base,
                         call_601136.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601136, url, valid)

proc call*(call_601137: Call_PostListPlatformVersions_601121;
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
  var query_601138 = newJObject()
  var formData_601139 = newJObject()
  add(formData_601139, "NextToken", newJString(NextToken))
  add(query_601138, "Action", newJString(Action))
  if Filters != nil:
    formData_601139.add "Filters", Filters
  add(formData_601139, "MaxRecords", newJInt(MaxRecords))
  add(query_601138, "Version", newJString(Version))
  result = call_601137.call(nil, query_601138, nil, formData_601139, nil)

var postListPlatformVersions* = Call_PostListPlatformVersions_601121(
    name: "postListPlatformVersions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListPlatformVersions",
    validator: validate_PostListPlatformVersions_601122, base: "/",
    url: url_PostListPlatformVersions_601123, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListPlatformVersions_601103 = ref object of OpenApiRestCall_599369
proc url_GetListPlatformVersions_601105(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListPlatformVersions_601104(path: JsonNode; query: JsonNode;
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
  var valid_601106 = query.getOrDefault("MaxRecords")
  valid_601106 = validateParameter(valid_601106, JInt, required = false, default = nil)
  if valid_601106 != nil:
    section.add "MaxRecords", valid_601106
  var valid_601107 = query.getOrDefault("Filters")
  valid_601107 = validateParameter(valid_601107, JArray, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "Filters", valid_601107
  var valid_601108 = query.getOrDefault("NextToken")
  valid_601108 = validateParameter(valid_601108, JString, required = false,
                                 default = nil)
  if valid_601108 != nil:
    section.add "NextToken", valid_601108
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601109 = query.getOrDefault("Action")
  valid_601109 = validateParameter(valid_601109, JString, required = true,
                                 default = newJString("ListPlatformVersions"))
  if valid_601109 != nil:
    section.add "Action", valid_601109
  var valid_601110 = query.getOrDefault("Version")
  valid_601110 = validateParameter(valid_601110, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601110 != nil:
    section.add "Version", valid_601110
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601111 = header.getOrDefault("X-Amz-Date")
  valid_601111 = validateParameter(valid_601111, JString, required = false,
                                 default = nil)
  if valid_601111 != nil:
    section.add "X-Amz-Date", valid_601111
  var valid_601112 = header.getOrDefault("X-Amz-Security-Token")
  valid_601112 = validateParameter(valid_601112, JString, required = false,
                                 default = nil)
  if valid_601112 != nil:
    section.add "X-Amz-Security-Token", valid_601112
  var valid_601113 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601113 = validateParameter(valid_601113, JString, required = false,
                                 default = nil)
  if valid_601113 != nil:
    section.add "X-Amz-Content-Sha256", valid_601113
  var valid_601114 = header.getOrDefault("X-Amz-Algorithm")
  valid_601114 = validateParameter(valid_601114, JString, required = false,
                                 default = nil)
  if valid_601114 != nil:
    section.add "X-Amz-Algorithm", valid_601114
  var valid_601115 = header.getOrDefault("X-Amz-Signature")
  valid_601115 = validateParameter(valid_601115, JString, required = false,
                                 default = nil)
  if valid_601115 != nil:
    section.add "X-Amz-Signature", valid_601115
  var valid_601116 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601116 = validateParameter(valid_601116, JString, required = false,
                                 default = nil)
  if valid_601116 != nil:
    section.add "X-Amz-SignedHeaders", valid_601116
  var valid_601117 = header.getOrDefault("X-Amz-Credential")
  valid_601117 = validateParameter(valid_601117, JString, required = false,
                                 default = nil)
  if valid_601117 != nil:
    section.add "X-Amz-Credential", valid_601117
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601118: Call_GetListPlatformVersions_601103; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the available platforms.
  ## 
  let valid = call_601118.validator(path, query, header, formData, body)
  let scheme = call_601118.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601118.url(scheme.get, call_601118.host, call_601118.base,
                         call_601118.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601118, url, valid)

proc call*(call_601119: Call_GetListPlatformVersions_601103; MaxRecords: int = 0;
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
  var query_601120 = newJObject()
  add(query_601120, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_601120.add "Filters", Filters
  add(query_601120, "NextToken", newJString(NextToken))
  add(query_601120, "Action", newJString(Action))
  add(query_601120, "Version", newJString(Version))
  result = call_601119.call(nil, query_601120, nil, nil, nil)

var getListPlatformVersions* = Call_GetListPlatformVersions_601103(
    name: "getListPlatformVersions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListPlatformVersions",
    validator: validate_GetListPlatformVersions_601104, base: "/",
    url: url_GetListPlatformVersions_601105, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_601156 = ref object of OpenApiRestCall_599369
proc url_PostListTagsForResource_601158(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListTagsForResource_601157(path: JsonNode; query: JsonNode;
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
  var valid_601159 = query.getOrDefault("Action")
  valid_601159 = validateParameter(valid_601159, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_601159 != nil:
    section.add "Action", valid_601159
  var valid_601160 = query.getOrDefault("Version")
  valid_601160 = validateParameter(valid_601160, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601160 != nil:
    section.add "Version", valid_601160
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601161 = header.getOrDefault("X-Amz-Date")
  valid_601161 = validateParameter(valid_601161, JString, required = false,
                                 default = nil)
  if valid_601161 != nil:
    section.add "X-Amz-Date", valid_601161
  var valid_601162 = header.getOrDefault("X-Amz-Security-Token")
  valid_601162 = validateParameter(valid_601162, JString, required = false,
                                 default = nil)
  if valid_601162 != nil:
    section.add "X-Amz-Security-Token", valid_601162
  var valid_601163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601163 = validateParameter(valid_601163, JString, required = false,
                                 default = nil)
  if valid_601163 != nil:
    section.add "X-Amz-Content-Sha256", valid_601163
  var valid_601164 = header.getOrDefault("X-Amz-Algorithm")
  valid_601164 = validateParameter(valid_601164, JString, required = false,
                                 default = nil)
  if valid_601164 != nil:
    section.add "X-Amz-Algorithm", valid_601164
  var valid_601165 = header.getOrDefault("X-Amz-Signature")
  valid_601165 = validateParameter(valid_601165, JString, required = false,
                                 default = nil)
  if valid_601165 != nil:
    section.add "X-Amz-Signature", valid_601165
  var valid_601166 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "X-Amz-SignedHeaders", valid_601166
  var valid_601167 = header.getOrDefault("X-Amz-Credential")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "X-Amz-Credential", valid_601167
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArn: JString (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce for which a tag list is requested.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArn` field"
  var valid_601168 = formData.getOrDefault("ResourceArn")
  valid_601168 = validateParameter(valid_601168, JString, required = true,
                                 default = nil)
  if valid_601168 != nil:
    section.add "ResourceArn", valid_601168
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601169: Call_PostListTagsForResource_601156; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ## 
  let valid = call_601169.validator(path, query, header, formData, body)
  let scheme = call_601169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601169.url(scheme.get, call_601169.host, call_601169.base,
                         call_601169.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601169, url, valid)

proc call*(call_601170: Call_PostListTagsForResource_601156; ResourceArn: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-12-01"): Recallable =
  ## postListTagsForResource
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ##   Action: string (required)
  ##   ResourceArn: string (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce for which a tag list is requested.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  ##   Version: string (required)
  var query_601171 = newJObject()
  var formData_601172 = newJObject()
  add(query_601171, "Action", newJString(Action))
  add(formData_601172, "ResourceArn", newJString(ResourceArn))
  add(query_601171, "Version", newJString(Version))
  result = call_601170.call(nil, query_601171, nil, formData_601172, nil)

var postListTagsForResource* = Call_PostListTagsForResource_601156(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_601157, base: "/",
    url: url_PostListTagsForResource_601158, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_601140 = ref object of OpenApiRestCall_599369
proc url_GetListTagsForResource_601142(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListTagsForResource_601141(path: JsonNode; query: JsonNode;
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
  var valid_601143 = query.getOrDefault("ResourceArn")
  valid_601143 = validateParameter(valid_601143, JString, required = true,
                                 default = nil)
  if valid_601143 != nil:
    section.add "ResourceArn", valid_601143
  var valid_601144 = query.getOrDefault("Action")
  valid_601144 = validateParameter(valid_601144, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_601144 != nil:
    section.add "Action", valid_601144
  var valid_601145 = query.getOrDefault("Version")
  valid_601145 = validateParameter(valid_601145, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601145 != nil:
    section.add "Version", valid_601145
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601146 = header.getOrDefault("X-Amz-Date")
  valid_601146 = validateParameter(valid_601146, JString, required = false,
                                 default = nil)
  if valid_601146 != nil:
    section.add "X-Amz-Date", valid_601146
  var valid_601147 = header.getOrDefault("X-Amz-Security-Token")
  valid_601147 = validateParameter(valid_601147, JString, required = false,
                                 default = nil)
  if valid_601147 != nil:
    section.add "X-Amz-Security-Token", valid_601147
  var valid_601148 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601148 = validateParameter(valid_601148, JString, required = false,
                                 default = nil)
  if valid_601148 != nil:
    section.add "X-Amz-Content-Sha256", valid_601148
  var valid_601149 = header.getOrDefault("X-Amz-Algorithm")
  valid_601149 = validateParameter(valid_601149, JString, required = false,
                                 default = nil)
  if valid_601149 != nil:
    section.add "X-Amz-Algorithm", valid_601149
  var valid_601150 = header.getOrDefault("X-Amz-Signature")
  valid_601150 = validateParameter(valid_601150, JString, required = false,
                                 default = nil)
  if valid_601150 != nil:
    section.add "X-Amz-Signature", valid_601150
  var valid_601151 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "X-Amz-SignedHeaders", valid_601151
  var valid_601152 = header.getOrDefault("X-Amz-Credential")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Credential", valid_601152
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601153: Call_GetListTagsForResource_601140; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ## 
  let valid = call_601153.validator(path, query, header, formData, body)
  let scheme = call_601153.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601153.url(scheme.get, call_601153.host, call_601153.base,
                         call_601153.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601153, url, valid)

proc call*(call_601154: Call_GetListTagsForResource_601140; ResourceArn: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-12-01"): Recallable =
  ## getListTagsForResource
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ##   ResourceArn: string (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce for which a tag list is requested.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601155 = newJObject()
  add(query_601155, "ResourceArn", newJString(ResourceArn))
  add(query_601155, "Action", newJString(Action))
  add(query_601155, "Version", newJString(Version))
  result = call_601154.call(nil, query_601155, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_601140(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_601141, base: "/",
    url: url_GetListTagsForResource_601142, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebuildEnvironment_601190 = ref object of OpenApiRestCall_599369
proc url_PostRebuildEnvironment_601192(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRebuildEnvironment_601191(path: JsonNode; query: JsonNode;
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
  var valid_601193 = query.getOrDefault("Action")
  valid_601193 = validateParameter(valid_601193, JString, required = true,
                                 default = newJString("RebuildEnvironment"))
  if valid_601193 != nil:
    section.add "Action", valid_601193
  var valid_601194 = query.getOrDefault("Version")
  valid_601194 = validateParameter(valid_601194, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601194 != nil:
    section.add "Version", valid_601194
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601195 = header.getOrDefault("X-Amz-Date")
  valid_601195 = validateParameter(valid_601195, JString, required = false,
                                 default = nil)
  if valid_601195 != nil:
    section.add "X-Amz-Date", valid_601195
  var valid_601196 = header.getOrDefault("X-Amz-Security-Token")
  valid_601196 = validateParameter(valid_601196, JString, required = false,
                                 default = nil)
  if valid_601196 != nil:
    section.add "X-Amz-Security-Token", valid_601196
  var valid_601197 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "X-Amz-Content-Sha256", valid_601197
  var valid_601198 = header.getOrDefault("X-Amz-Algorithm")
  valid_601198 = validateParameter(valid_601198, JString, required = false,
                                 default = nil)
  if valid_601198 != nil:
    section.add "X-Amz-Algorithm", valid_601198
  var valid_601199 = header.getOrDefault("X-Amz-Signature")
  valid_601199 = validateParameter(valid_601199, JString, required = false,
                                 default = nil)
  if valid_601199 != nil:
    section.add "X-Amz-Signature", valid_601199
  var valid_601200 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601200 = validateParameter(valid_601200, JString, required = false,
                                 default = nil)
  if valid_601200 != nil:
    section.add "X-Amz-SignedHeaders", valid_601200
  var valid_601201 = header.getOrDefault("X-Amz-Credential")
  valid_601201 = validateParameter(valid_601201, JString, required = false,
                                 default = nil)
  if valid_601201 != nil:
    section.add "X-Amz-Credential", valid_601201
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to rebuild.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to rebuild.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_601202 = formData.getOrDefault("EnvironmentId")
  valid_601202 = validateParameter(valid_601202, JString, required = false,
                                 default = nil)
  if valid_601202 != nil:
    section.add "EnvironmentId", valid_601202
  var valid_601203 = formData.getOrDefault("EnvironmentName")
  valid_601203 = validateParameter(valid_601203, JString, required = false,
                                 default = nil)
  if valid_601203 != nil:
    section.add "EnvironmentName", valid_601203
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601204: Call_PostRebuildEnvironment_601190; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes and recreates all of the AWS resources (for example: the Auto Scaling group, load balancer, etc.) for a specified environment and forces a restart.
  ## 
  let valid = call_601204.validator(path, query, header, formData, body)
  let scheme = call_601204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601204.url(scheme.get, call_601204.host, call_601204.base,
                         call_601204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601204, url, valid)

proc call*(call_601205: Call_PostRebuildEnvironment_601190;
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
  var query_601206 = newJObject()
  var formData_601207 = newJObject()
  add(formData_601207, "EnvironmentId", newJString(EnvironmentId))
  add(formData_601207, "EnvironmentName", newJString(EnvironmentName))
  add(query_601206, "Action", newJString(Action))
  add(query_601206, "Version", newJString(Version))
  result = call_601205.call(nil, query_601206, nil, formData_601207, nil)

var postRebuildEnvironment* = Call_PostRebuildEnvironment_601190(
    name: "postRebuildEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RebuildEnvironment",
    validator: validate_PostRebuildEnvironment_601191, base: "/",
    url: url_PostRebuildEnvironment_601192, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebuildEnvironment_601173 = ref object of OpenApiRestCall_599369
proc url_GetRebuildEnvironment_601175(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRebuildEnvironment_601174(path: JsonNode; query: JsonNode;
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
  var valid_601176 = query.getOrDefault("EnvironmentName")
  valid_601176 = validateParameter(valid_601176, JString, required = false,
                                 default = nil)
  if valid_601176 != nil:
    section.add "EnvironmentName", valid_601176
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601177 = query.getOrDefault("Action")
  valid_601177 = validateParameter(valid_601177, JString, required = true,
                                 default = newJString("RebuildEnvironment"))
  if valid_601177 != nil:
    section.add "Action", valid_601177
  var valid_601178 = query.getOrDefault("EnvironmentId")
  valid_601178 = validateParameter(valid_601178, JString, required = false,
                                 default = nil)
  if valid_601178 != nil:
    section.add "EnvironmentId", valid_601178
  var valid_601179 = query.getOrDefault("Version")
  valid_601179 = validateParameter(valid_601179, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601179 != nil:
    section.add "Version", valid_601179
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601180 = header.getOrDefault("X-Amz-Date")
  valid_601180 = validateParameter(valid_601180, JString, required = false,
                                 default = nil)
  if valid_601180 != nil:
    section.add "X-Amz-Date", valid_601180
  var valid_601181 = header.getOrDefault("X-Amz-Security-Token")
  valid_601181 = validateParameter(valid_601181, JString, required = false,
                                 default = nil)
  if valid_601181 != nil:
    section.add "X-Amz-Security-Token", valid_601181
  var valid_601182 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Content-Sha256", valid_601182
  var valid_601183 = header.getOrDefault("X-Amz-Algorithm")
  valid_601183 = validateParameter(valid_601183, JString, required = false,
                                 default = nil)
  if valid_601183 != nil:
    section.add "X-Amz-Algorithm", valid_601183
  var valid_601184 = header.getOrDefault("X-Amz-Signature")
  valid_601184 = validateParameter(valid_601184, JString, required = false,
                                 default = nil)
  if valid_601184 != nil:
    section.add "X-Amz-Signature", valid_601184
  var valid_601185 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "X-Amz-SignedHeaders", valid_601185
  var valid_601186 = header.getOrDefault("X-Amz-Credential")
  valid_601186 = validateParameter(valid_601186, JString, required = false,
                                 default = nil)
  if valid_601186 != nil:
    section.add "X-Amz-Credential", valid_601186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601187: Call_GetRebuildEnvironment_601173; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes and recreates all of the AWS resources (for example: the Auto Scaling group, load balancer, etc.) for a specified environment and forces a restart.
  ## 
  let valid = call_601187.validator(path, query, header, formData, body)
  let scheme = call_601187.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601187.url(scheme.get, call_601187.host, call_601187.base,
                         call_601187.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601187, url, valid)

proc call*(call_601188: Call_GetRebuildEnvironment_601173;
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
  var query_601189 = newJObject()
  add(query_601189, "EnvironmentName", newJString(EnvironmentName))
  add(query_601189, "Action", newJString(Action))
  add(query_601189, "EnvironmentId", newJString(EnvironmentId))
  add(query_601189, "Version", newJString(Version))
  result = call_601188.call(nil, query_601189, nil, nil, nil)

var getRebuildEnvironment* = Call_GetRebuildEnvironment_601173(
    name: "getRebuildEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RebuildEnvironment",
    validator: validate_GetRebuildEnvironment_601174, base: "/",
    url: url_GetRebuildEnvironment_601175, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRequestEnvironmentInfo_601226 = ref object of OpenApiRestCall_599369
proc url_PostRequestEnvironmentInfo_601228(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRequestEnvironmentInfo_601227(path: JsonNode; query: JsonNode;
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
  var valid_601229 = query.getOrDefault("Action")
  valid_601229 = validateParameter(valid_601229, JString, required = true,
                                 default = newJString("RequestEnvironmentInfo"))
  if valid_601229 != nil:
    section.add "Action", valid_601229
  var valid_601230 = query.getOrDefault("Version")
  valid_601230 = validateParameter(valid_601230, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601230 != nil:
    section.add "Version", valid_601230
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601231 = header.getOrDefault("X-Amz-Date")
  valid_601231 = validateParameter(valid_601231, JString, required = false,
                                 default = nil)
  if valid_601231 != nil:
    section.add "X-Amz-Date", valid_601231
  var valid_601232 = header.getOrDefault("X-Amz-Security-Token")
  valid_601232 = validateParameter(valid_601232, JString, required = false,
                                 default = nil)
  if valid_601232 != nil:
    section.add "X-Amz-Security-Token", valid_601232
  var valid_601233 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601233 = validateParameter(valid_601233, JString, required = false,
                                 default = nil)
  if valid_601233 != nil:
    section.add "X-Amz-Content-Sha256", valid_601233
  var valid_601234 = header.getOrDefault("X-Amz-Algorithm")
  valid_601234 = validateParameter(valid_601234, JString, required = false,
                                 default = nil)
  if valid_601234 != nil:
    section.add "X-Amz-Algorithm", valid_601234
  var valid_601235 = header.getOrDefault("X-Amz-Signature")
  valid_601235 = validateParameter(valid_601235, JString, required = false,
                                 default = nil)
  if valid_601235 != nil:
    section.add "X-Amz-Signature", valid_601235
  var valid_601236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601236 = validateParameter(valid_601236, JString, required = false,
                                 default = nil)
  if valid_601236 != nil:
    section.add "X-Amz-SignedHeaders", valid_601236
  var valid_601237 = header.getOrDefault("X-Amz-Credential")
  valid_601237 = validateParameter(valid_601237, JString, required = false,
                                 default = nil)
  if valid_601237 != nil:
    section.add "X-Amz-Credential", valid_601237
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
  var valid_601238 = formData.getOrDefault("InfoType")
  valid_601238 = validateParameter(valid_601238, JString, required = true,
                                 default = newJString("tail"))
  if valid_601238 != nil:
    section.add "InfoType", valid_601238
  var valid_601239 = formData.getOrDefault("EnvironmentId")
  valid_601239 = validateParameter(valid_601239, JString, required = false,
                                 default = nil)
  if valid_601239 != nil:
    section.add "EnvironmentId", valid_601239
  var valid_601240 = formData.getOrDefault("EnvironmentName")
  valid_601240 = validateParameter(valid_601240, JString, required = false,
                                 default = nil)
  if valid_601240 != nil:
    section.add "EnvironmentName", valid_601240
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601241: Call_PostRequestEnvironmentInfo_601226; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a request to compile the specified type of information of the deployed environment.</p> <p> Setting the <code>InfoType</code> to <code>tail</code> compiles the last lines from the application server log files of every Amazon EC2 instance in your environment. </p> <p> Setting the <code>InfoType</code> to <code>bundle</code> compresses the application server log files for every Amazon EC2 instance into a <code>.zip</code> file. Legacy and .NET containers do not support bundle logs. </p> <p> Use <a>RetrieveEnvironmentInfo</a> to obtain the set of logs. </p> <p>Related Topics</p> <ul> <li> <p> <a>RetrieveEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_601241.validator(path, query, header, formData, body)
  let scheme = call_601241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601241.url(scheme.get, call_601241.host, call_601241.base,
                         call_601241.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601241, url, valid)

proc call*(call_601242: Call_PostRequestEnvironmentInfo_601226;
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
  var query_601243 = newJObject()
  var formData_601244 = newJObject()
  add(formData_601244, "InfoType", newJString(InfoType))
  add(formData_601244, "EnvironmentId", newJString(EnvironmentId))
  add(formData_601244, "EnvironmentName", newJString(EnvironmentName))
  add(query_601243, "Action", newJString(Action))
  add(query_601243, "Version", newJString(Version))
  result = call_601242.call(nil, query_601243, nil, formData_601244, nil)

var postRequestEnvironmentInfo* = Call_PostRequestEnvironmentInfo_601226(
    name: "postRequestEnvironmentInfo", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RequestEnvironmentInfo",
    validator: validate_PostRequestEnvironmentInfo_601227, base: "/",
    url: url_PostRequestEnvironmentInfo_601228,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRequestEnvironmentInfo_601208 = ref object of OpenApiRestCall_599369
proc url_GetRequestEnvironmentInfo_601210(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRequestEnvironmentInfo_601209(path: JsonNode; query: JsonNode;
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
  var valid_601211 = query.getOrDefault("InfoType")
  valid_601211 = validateParameter(valid_601211, JString, required = true,
                                 default = newJString("tail"))
  if valid_601211 != nil:
    section.add "InfoType", valid_601211
  var valid_601212 = query.getOrDefault("EnvironmentName")
  valid_601212 = validateParameter(valid_601212, JString, required = false,
                                 default = nil)
  if valid_601212 != nil:
    section.add "EnvironmentName", valid_601212
  var valid_601213 = query.getOrDefault("Action")
  valid_601213 = validateParameter(valid_601213, JString, required = true,
                                 default = newJString("RequestEnvironmentInfo"))
  if valid_601213 != nil:
    section.add "Action", valid_601213
  var valid_601214 = query.getOrDefault("EnvironmentId")
  valid_601214 = validateParameter(valid_601214, JString, required = false,
                                 default = nil)
  if valid_601214 != nil:
    section.add "EnvironmentId", valid_601214
  var valid_601215 = query.getOrDefault("Version")
  valid_601215 = validateParameter(valid_601215, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601215 != nil:
    section.add "Version", valid_601215
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601216 = header.getOrDefault("X-Amz-Date")
  valid_601216 = validateParameter(valid_601216, JString, required = false,
                                 default = nil)
  if valid_601216 != nil:
    section.add "X-Amz-Date", valid_601216
  var valid_601217 = header.getOrDefault("X-Amz-Security-Token")
  valid_601217 = validateParameter(valid_601217, JString, required = false,
                                 default = nil)
  if valid_601217 != nil:
    section.add "X-Amz-Security-Token", valid_601217
  var valid_601218 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601218 = validateParameter(valid_601218, JString, required = false,
                                 default = nil)
  if valid_601218 != nil:
    section.add "X-Amz-Content-Sha256", valid_601218
  var valid_601219 = header.getOrDefault("X-Amz-Algorithm")
  valid_601219 = validateParameter(valid_601219, JString, required = false,
                                 default = nil)
  if valid_601219 != nil:
    section.add "X-Amz-Algorithm", valid_601219
  var valid_601220 = header.getOrDefault("X-Amz-Signature")
  valid_601220 = validateParameter(valid_601220, JString, required = false,
                                 default = nil)
  if valid_601220 != nil:
    section.add "X-Amz-Signature", valid_601220
  var valid_601221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601221 = validateParameter(valid_601221, JString, required = false,
                                 default = nil)
  if valid_601221 != nil:
    section.add "X-Amz-SignedHeaders", valid_601221
  var valid_601222 = header.getOrDefault("X-Amz-Credential")
  valid_601222 = validateParameter(valid_601222, JString, required = false,
                                 default = nil)
  if valid_601222 != nil:
    section.add "X-Amz-Credential", valid_601222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601223: Call_GetRequestEnvironmentInfo_601208; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a request to compile the specified type of information of the deployed environment.</p> <p> Setting the <code>InfoType</code> to <code>tail</code> compiles the last lines from the application server log files of every Amazon EC2 instance in your environment. </p> <p> Setting the <code>InfoType</code> to <code>bundle</code> compresses the application server log files for every Amazon EC2 instance into a <code>.zip</code> file. Legacy and .NET containers do not support bundle logs. </p> <p> Use <a>RetrieveEnvironmentInfo</a> to obtain the set of logs. </p> <p>Related Topics</p> <ul> <li> <p> <a>RetrieveEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_601223.validator(path, query, header, formData, body)
  let scheme = call_601223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601223.url(scheme.get, call_601223.host, call_601223.base,
                         call_601223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601223, url, valid)

proc call*(call_601224: Call_GetRequestEnvironmentInfo_601208;
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
  var query_601225 = newJObject()
  add(query_601225, "InfoType", newJString(InfoType))
  add(query_601225, "EnvironmentName", newJString(EnvironmentName))
  add(query_601225, "Action", newJString(Action))
  add(query_601225, "EnvironmentId", newJString(EnvironmentId))
  add(query_601225, "Version", newJString(Version))
  result = call_601224.call(nil, query_601225, nil, nil, nil)

var getRequestEnvironmentInfo* = Call_GetRequestEnvironmentInfo_601208(
    name: "getRequestEnvironmentInfo", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RequestEnvironmentInfo",
    validator: validate_GetRequestEnvironmentInfo_601209, base: "/",
    url: url_GetRequestEnvironmentInfo_601210,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestartAppServer_601262 = ref object of OpenApiRestCall_599369
proc url_PostRestartAppServer_601264(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRestartAppServer_601263(path: JsonNode; query: JsonNode;
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
  var valid_601265 = query.getOrDefault("Action")
  valid_601265 = validateParameter(valid_601265, JString, required = true,
                                 default = newJString("RestartAppServer"))
  if valid_601265 != nil:
    section.add "Action", valid_601265
  var valid_601266 = query.getOrDefault("Version")
  valid_601266 = validateParameter(valid_601266, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601266 != nil:
    section.add "Version", valid_601266
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601267 = header.getOrDefault("X-Amz-Date")
  valid_601267 = validateParameter(valid_601267, JString, required = false,
                                 default = nil)
  if valid_601267 != nil:
    section.add "X-Amz-Date", valid_601267
  var valid_601268 = header.getOrDefault("X-Amz-Security-Token")
  valid_601268 = validateParameter(valid_601268, JString, required = false,
                                 default = nil)
  if valid_601268 != nil:
    section.add "X-Amz-Security-Token", valid_601268
  var valid_601269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601269 = validateParameter(valid_601269, JString, required = false,
                                 default = nil)
  if valid_601269 != nil:
    section.add "X-Amz-Content-Sha256", valid_601269
  var valid_601270 = header.getOrDefault("X-Amz-Algorithm")
  valid_601270 = validateParameter(valid_601270, JString, required = false,
                                 default = nil)
  if valid_601270 != nil:
    section.add "X-Amz-Algorithm", valid_601270
  var valid_601271 = header.getOrDefault("X-Amz-Signature")
  valid_601271 = validateParameter(valid_601271, JString, required = false,
                                 default = nil)
  if valid_601271 != nil:
    section.add "X-Amz-Signature", valid_601271
  var valid_601272 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601272 = validateParameter(valid_601272, JString, required = false,
                                 default = nil)
  if valid_601272 != nil:
    section.add "X-Amz-SignedHeaders", valid_601272
  var valid_601273 = header.getOrDefault("X-Amz-Credential")
  valid_601273 = validateParameter(valid_601273, JString, required = false,
                                 default = nil)
  if valid_601273 != nil:
    section.add "X-Amz-Credential", valid_601273
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to restart the server for.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to restart the server for.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_601274 = formData.getOrDefault("EnvironmentId")
  valid_601274 = validateParameter(valid_601274, JString, required = false,
                                 default = nil)
  if valid_601274 != nil:
    section.add "EnvironmentId", valid_601274
  var valid_601275 = formData.getOrDefault("EnvironmentName")
  valid_601275 = validateParameter(valid_601275, JString, required = false,
                                 default = nil)
  if valid_601275 != nil:
    section.add "EnvironmentName", valid_601275
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601276: Call_PostRestartAppServer_601262; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Causes the environment to restart the application container server running on each Amazon EC2 instance.
  ## 
  let valid = call_601276.validator(path, query, header, formData, body)
  let scheme = call_601276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601276.url(scheme.get, call_601276.host, call_601276.base,
                         call_601276.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601276, url, valid)

proc call*(call_601277: Call_PostRestartAppServer_601262;
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
  var query_601278 = newJObject()
  var formData_601279 = newJObject()
  add(formData_601279, "EnvironmentId", newJString(EnvironmentId))
  add(formData_601279, "EnvironmentName", newJString(EnvironmentName))
  add(query_601278, "Action", newJString(Action))
  add(query_601278, "Version", newJString(Version))
  result = call_601277.call(nil, query_601278, nil, formData_601279, nil)

var postRestartAppServer* = Call_PostRestartAppServer_601262(
    name: "postRestartAppServer", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RestartAppServer",
    validator: validate_PostRestartAppServer_601263, base: "/",
    url: url_PostRestartAppServer_601264, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestartAppServer_601245 = ref object of OpenApiRestCall_599369
proc url_GetRestartAppServer_601247(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRestartAppServer_601246(path: JsonNode; query: JsonNode;
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
  var valid_601248 = query.getOrDefault("EnvironmentName")
  valid_601248 = validateParameter(valid_601248, JString, required = false,
                                 default = nil)
  if valid_601248 != nil:
    section.add "EnvironmentName", valid_601248
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601249 = query.getOrDefault("Action")
  valid_601249 = validateParameter(valid_601249, JString, required = true,
                                 default = newJString("RestartAppServer"))
  if valid_601249 != nil:
    section.add "Action", valid_601249
  var valid_601250 = query.getOrDefault("EnvironmentId")
  valid_601250 = validateParameter(valid_601250, JString, required = false,
                                 default = nil)
  if valid_601250 != nil:
    section.add "EnvironmentId", valid_601250
  var valid_601251 = query.getOrDefault("Version")
  valid_601251 = validateParameter(valid_601251, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601251 != nil:
    section.add "Version", valid_601251
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601252 = header.getOrDefault("X-Amz-Date")
  valid_601252 = validateParameter(valid_601252, JString, required = false,
                                 default = nil)
  if valid_601252 != nil:
    section.add "X-Amz-Date", valid_601252
  var valid_601253 = header.getOrDefault("X-Amz-Security-Token")
  valid_601253 = validateParameter(valid_601253, JString, required = false,
                                 default = nil)
  if valid_601253 != nil:
    section.add "X-Amz-Security-Token", valid_601253
  var valid_601254 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601254 = validateParameter(valid_601254, JString, required = false,
                                 default = nil)
  if valid_601254 != nil:
    section.add "X-Amz-Content-Sha256", valid_601254
  var valid_601255 = header.getOrDefault("X-Amz-Algorithm")
  valid_601255 = validateParameter(valid_601255, JString, required = false,
                                 default = nil)
  if valid_601255 != nil:
    section.add "X-Amz-Algorithm", valid_601255
  var valid_601256 = header.getOrDefault("X-Amz-Signature")
  valid_601256 = validateParameter(valid_601256, JString, required = false,
                                 default = nil)
  if valid_601256 != nil:
    section.add "X-Amz-Signature", valid_601256
  var valid_601257 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601257 = validateParameter(valid_601257, JString, required = false,
                                 default = nil)
  if valid_601257 != nil:
    section.add "X-Amz-SignedHeaders", valid_601257
  var valid_601258 = header.getOrDefault("X-Amz-Credential")
  valid_601258 = validateParameter(valid_601258, JString, required = false,
                                 default = nil)
  if valid_601258 != nil:
    section.add "X-Amz-Credential", valid_601258
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601259: Call_GetRestartAppServer_601245; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Causes the environment to restart the application container server running on each Amazon EC2 instance.
  ## 
  let valid = call_601259.validator(path, query, header, formData, body)
  let scheme = call_601259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601259.url(scheme.get, call_601259.host, call_601259.base,
                         call_601259.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601259, url, valid)

proc call*(call_601260: Call_GetRestartAppServer_601245;
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
  var query_601261 = newJObject()
  add(query_601261, "EnvironmentName", newJString(EnvironmentName))
  add(query_601261, "Action", newJString(Action))
  add(query_601261, "EnvironmentId", newJString(EnvironmentId))
  add(query_601261, "Version", newJString(Version))
  result = call_601260.call(nil, query_601261, nil, nil, nil)

var getRestartAppServer* = Call_GetRestartAppServer_601245(
    name: "getRestartAppServer", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RestartAppServer",
    validator: validate_GetRestartAppServer_601246, base: "/",
    url: url_GetRestartAppServer_601247, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRetrieveEnvironmentInfo_601298 = ref object of OpenApiRestCall_599369
proc url_PostRetrieveEnvironmentInfo_601300(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRetrieveEnvironmentInfo_601299(path: JsonNode; query: JsonNode;
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
  var valid_601301 = query.getOrDefault("Action")
  valid_601301 = validateParameter(valid_601301, JString, required = true, default = newJString(
      "RetrieveEnvironmentInfo"))
  if valid_601301 != nil:
    section.add "Action", valid_601301
  var valid_601302 = query.getOrDefault("Version")
  valid_601302 = validateParameter(valid_601302, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601302 != nil:
    section.add "Version", valid_601302
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601303 = header.getOrDefault("X-Amz-Date")
  valid_601303 = validateParameter(valid_601303, JString, required = false,
                                 default = nil)
  if valid_601303 != nil:
    section.add "X-Amz-Date", valid_601303
  var valid_601304 = header.getOrDefault("X-Amz-Security-Token")
  valid_601304 = validateParameter(valid_601304, JString, required = false,
                                 default = nil)
  if valid_601304 != nil:
    section.add "X-Amz-Security-Token", valid_601304
  var valid_601305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601305 = validateParameter(valid_601305, JString, required = false,
                                 default = nil)
  if valid_601305 != nil:
    section.add "X-Amz-Content-Sha256", valid_601305
  var valid_601306 = header.getOrDefault("X-Amz-Algorithm")
  valid_601306 = validateParameter(valid_601306, JString, required = false,
                                 default = nil)
  if valid_601306 != nil:
    section.add "X-Amz-Algorithm", valid_601306
  var valid_601307 = header.getOrDefault("X-Amz-Signature")
  valid_601307 = validateParameter(valid_601307, JString, required = false,
                                 default = nil)
  if valid_601307 != nil:
    section.add "X-Amz-Signature", valid_601307
  var valid_601308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601308 = validateParameter(valid_601308, JString, required = false,
                                 default = nil)
  if valid_601308 != nil:
    section.add "X-Amz-SignedHeaders", valid_601308
  var valid_601309 = header.getOrDefault("X-Amz-Credential")
  valid_601309 = validateParameter(valid_601309, JString, required = false,
                                 default = nil)
  if valid_601309 != nil:
    section.add "X-Amz-Credential", valid_601309
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
  var valid_601310 = formData.getOrDefault("InfoType")
  valid_601310 = validateParameter(valid_601310, JString, required = true,
                                 default = newJString("tail"))
  if valid_601310 != nil:
    section.add "InfoType", valid_601310
  var valid_601311 = formData.getOrDefault("EnvironmentId")
  valid_601311 = validateParameter(valid_601311, JString, required = false,
                                 default = nil)
  if valid_601311 != nil:
    section.add "EnvironmentId", valid_601311
  var valid_601312 = formData.getOrDefault("EnvironmentName")
  valid_601312 = validateParameter(valid_601312, JString, required = false,
                                 default = nil)
  if valid_601312 != nil:
    section.add "EnvironmentName", valid_601312
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601313: Call_PostRetrieveEnvironmentInfo_601298; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the compiled information from a <a>RequestEnvironmentInfo</a> request.</p> <p>Related Topics</p> <ul> <li> <p> <a>RequestEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_601313.validator(path, query, header, formData, body)
  let scheme = call_601313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601313.url(scheme.get, call_601313.host, call_601313.base,
                         call_601313.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601313, url, valid)

proc call*(call_601314: Call_PostRetrieveEnvironmentInfo_601298;
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
  var query_601315 = newJObject()
  var formData_601316 = newJObject()
  add(formData_601316, "InfoType", newJString(InfoType))
  add(formData_601316, "EnvironmentId", newJString(EnvironmentId))
  add(formData_601316, "EnvironmentName", newJString(EnvironmentName))
  add(query_601315, "Action", newJString(Action))
  add(query_601315, "Version", newJString(Version))
  result = call_601314.call(nil, query_601315, nil, formData_601316, nil)

var postRetrieveEnvironmentInfo* = Call_PostRetrieveEnvironmentInfo_601298(
    name: "postRetrieveEnvironmentInfo", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RetrieveEnvironmentInfo",
    validator: validate_PostRetrieveEnvironmentInfo_601299, base: "/",
    url: url_PostRetrieveEnvironmentInfo_601300,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRetrieveEnvironmentInfo_601280 = ref object of OpenApiRestCall_599369
proc url_GetRetrieveEnvironmentInfo_601282(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRetrieveEnvironmentInfo_601281(path: JsonNode; query: JsonNode;
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
  var valid_601283 = query.getOrDefault("InfoType")
  valid_601283 = validateParameter(valid_601283, JString, required = true,
                                 default = newJString("tail"))
  if valid_601283 != nil:
    section.add "InfoType", valid_601283
  var valid_601284 = query.getOrDefault("EnvironmentName")
  valid_601284 = validateParameter(valid_601284, JString, required = false,
                                 default = nil)
  if valid_601284 != nil:
    section.add "EnvironmentName", valid_601284
  var valid_601285 = query.getOrDefault("Action")
  valid_601285 = validateParameter(valid_601285, JString, required = true, default = newJString(
      "RetrieveEnvironmentInfo"))
  if valid_601285 != nil:
    section.add "Action", valid_601285
  var valid_601286 = query.getOrDefault("EnvironmentId")
  valid_601286 = validateParameter(valid_601286, JString, required = false,
                                 default = nil)
  if valid_601286 != nil:
    section.add "EnvironmentId", valid_601286
  var valid_601287 = query.getOrDefault("Version")
  valid_601287 = validateParameter(valid_601287, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601287 != nil:
    section.add "Version", valid_601287
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601288 = header.getOrDefault("X-Amz-Date")
  valid_601288 = validateParameter(valid_601288, JString, required = false,
                                 default = nil)
  if valid_601288 != nil:
    section.add "X-Amz-Date", valid_601288
  var valid_601289 = header.getOrDefault("X-Amz-Security-Token")
  valid_601289 = validateParameter(valid_601289, JString, required = false,
                                 default = nil)
  if valid_601289 != nil:
    section.add "X-Amz-Security-Token", valid_601289
  var valid_601290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601290 = validateParameter(valid_601290, JString, required = false,
                                 default = nil)
  if valid_601290 != nil:
    section.add "X-Amz-Content-Sha256", valid_601290
  var valid_601291 = header.getOrDefault("X-Amz-Algorithm")
  valid_601291 = validateParameter(valid_601291, JString, required = false,
                                 default = nil)
  if valid_601291 != nil:
    section.add "X-Amz-Algorithm", valid_601291
  var valid_601292 = header.getOrDefault("X-Amz-Signature")
  valid_601292 = validateParameter(valid_601292, JString, required = false,
                                 default = nil)
  if valid_601292 != nil:
    section.add "X-Amz-Signature", valid_601292
  var valid_601293 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601293 = validateParameter(valid_601293, JString, required = false,
                                 default = nil)
  if valid_601293 != nil:
    section.add "X-Amz-SignedHeaders", valid_601293
  var valid_601294 = header.getOrDefault("X-Amz-Credential")
  valid_601294 = validateParameter(valid_601294, JString, required = false,
                                 default = nil)
  if valid_601294 != nil:
    section.add "X-Amz-Credential", valid_601294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601295: Call_GetRetrieveEnvironmentInfo_601280; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the compiled information from a <a>RequestEnvironmentInfo</a> request.</p> <p>Related Topics</p> <ul> <li> <p> <a>RequestEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_601295.validator(path, query, header, formData, body)
  let scheme = call_601295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601295.url(scheme.get, call_601295.host, call_601295.base,
                         call_601295.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601295, url, valid)

proc call*(call_601296: Call_GetRetrieveEnvironmentInfo_601280;
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
  var query_601297 = newJObject()
  add(query_601297, "InfoType", newJString(InfoType))
  add(query_601297, "EnvironmentName", newJString(EnvironmentName))
  add(query_601297, "Action", newJString(Action))
  add(query_601297, "EnvironmentId", newJString(EnvironmentId))
  add(query_601297, "Version", newJString(Version))
  result = call_601296.call(nil, query_601297, nil, nil, nil)

var getRetrieveEnvironmentInfo* = Call_GetRetrieveEnvironmentInfo_601280(
    name: "getRetrieveEnvironmentInfo", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RetrieveEnvironmentInfo",
    validator: validate_GetRetrieveEnvironmentInfo_601281, base: "/",
    url: url_GetRetrieveEnvironmentInfo_601282,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSwapEnvironmentCNAMEs_601336 = ref object of OpenApiRestCall_599369
proc url_PostSwapEnvironmentCNAMEs_601338(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostSwapEnvironmentCNAMEs_601337(path: JsonNode; query: JsonNode;
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
  var valid_601339 = query.getOrDefault("Action")
  valid_601339 = validateParameter(valid_601339, JString, required = true,
                                 default = newJString("SwapEnvironmentCNAMEs"))
  if valid_601339 != nil:
    section.add "Action", valid_601339
  var valid_601340 = query.getOrDefault("Version")
  valid_601340 = validateParameter(valid_601340, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601340 != nil:
    section.add "Version", valid_601340
  result.add "query", section
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
  var valid_601348 = formData.getOrDefault("SourceEnvironmentName")
  valid_601348 = validateParameter(valid_601348, JString, required = false,
                                 default = nil)
  if valid_601348 != nil:
    section.add "SourceEnvironmentName", valid_601348
  var valid_601349 = formData.getOrDefault("SourceEnvironmentId")
  valid_601349 = validateParameter(valid_601349, JString, required = false,
                                 default = nil)
  if valid_601349 != nil:
    section.add "SourceEnvironmentId", valid_601349
  var valid_601350 = formData.getOrDefault("DestinationEnvironmentId")
  valid_601350 = validateParameter(valid_601350, JString, required = false,
                                 default = nil)
  if valid_601350 != nil:
    section.add "DestinationEnvironmentId", valid_601350
  var valid_601351 = formData.getOrDefault("DestinationEnvironmentName")
  valid_601351 = validateParameter(valid_601351, JString, required = false,
                                 default = nil)
  if valid_601351 != nil:
    section.add "DestinationEnvironmentName", valid_601351
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601352: Call_PostSwapEnvironmentCNAMEs_601336; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Swaps the CNAMEs of two environments.
  ## 
  let valid = call_601352.validator(path, query, header, formData, body)
  let scheme = call_601352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601352.url(scheme.get, call_601352.host, call_601352.base,
                         call_601352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601352, url, valid)

proc call*(call_601353: Call_PostSwapEnvironmentCNAMEs_601336;
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
  var query_601354 = newJObject()
  var formData_601355 = newJObject()
  add(formData_601355, "SourceEnvironmentName", newJString(SourceEnvironmentName))
  add(formData_601355, "SourceEnvironmentId", newJString(SourceEnvironmentId))
  add(formData_601355, "DestinationEnvironmentId",
      newJString(DestinationEnvironmentId))
  add(formData_601355, "DestinationEnvironmentName",
      newJString(DestinationEnvironmentName))
  add(query_601354, "Action", newJString(Action))
  add(query_601354, "Version", newJString(Version))
  result = call_601353.call(nil, query_601354, nil, formData_601355, nil)

var postSwapEnvironmentCNAMEs* = Call_PostSwapEnvironmentCNAMEs_601336(
    name: "postSwapEnvironmentCNAMEs", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=SwapEnvironmentCNAMEs",
    validator: validate_PostSwapEnvironmentCNAMEs_601337, base: "/",
    url: url_PostSwapEnvironmentCNAMEs_601338,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSwapEnvironmentCNAMEs_601317 = ref object of OpenApiRestCall_599369
proc url_GetSwapEnvironmentCNAMEs_601319(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSwapEnvironmentCNAMEs_601318(path: JsonNode; query: JsonNode;
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
  var valid_601320 = query.getOrDefault("SourceEnvironmentId")
  valid_601320 = validateParameter(valid_601320, JString, required = false,
                                 default = nil)
  if valid_601320 != nil:
    section.add "SourceEnvironmentId", valid_601320
  var valid_601321 = query.getOrDefault("DestinationEnvironmentName")
  valid_601321 = validateParameter(valid_601321, JString, required = false,
                                 default = nil)
  if valid_601321 != nil:
    section.add "DestinationEnvironmentName", valid_601321
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601322 = query.getOrDefault("Action")
  valid_601322 = validateParameter(valid_601322, JString, required = true,
                                 default = newJString("SwapEnvironmentCNAMEs"))
  if valid_601322 != nil:
    section.add "Action", valid_601322
  var valid_601323 = query.getOrDefault("SourceEnvironmentName")
  valid_601323 = validateParameter(valid_601323, JString, required = false,
                                 default = nil)
  if valid_601323 != nil:
    section.add "SourceEnvironmentName", valid_601323
  var valid_601324 = query.getOrDefault("DestinationEnvironmentId")
  valid_601324 = validateParameter(valid_601324, JString, required = false,
                                 default = nil)
  if valid_601324 != nil:
    section.add "DestinationEnvironmentId", valid_601324
  var valid_601325 = query.getOrDefault("Version")
  valid_601325 = validateParameter(valid_601325, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601325 != nil:
    section.add "Version", valid_601325
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601326 = header.getOrDefault("X-Amz-Date")
  valid_601326 = validateParameter(valid_601326, JString, required = false,
                                 default = nil)
  if valid_601326 != nil:
    section.add "X-Amz-Date", valid_601326
  var valid_601327 = header.getOrDefault("X-Amz-Security-Token")
  valid_601327 = validateParameter(valid_601327, JString, required = false,
                                 default = nil)
  if valid_601327 != nil:
    section.add "X-Amz-Security-Token", valid_601327
  var valid_601328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601328 = validateParameter(valid_601328, JString, required = false,
                                 default = nil)
  if valid_601328 != nil:
    section.add "X-Amz-Content-Sha256", valid_601328
  var valid_601329 = header.getOrDefault("X-Amz-Algorithm")
  valid_601329 = validateParameter(valid_601329, JString, required = false,
                                 default = nil)
  if valid_601329 != nil:
    section.add "X-Amz-Algorithm", valid_601329
  var valid_601330 = header.getOrDefault("X-Amz-Signature")
  valid_601330 = validateParameter(valid_601330, JString, required = false,
                                 default = nil)
  if valid_601330 != nil:
    section.add "X-Amz-Signature", valid_601330
  var valid_601331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601331 = validateParameter(valid_601331, JString, required = false,
                                 default = nil)
  if valid_601331 != nil:
    section.add "X-Amz-SignedHeaders", valid_601331
  var valid_601332 = header.getOrDefault("X-Amz-Credential")
  valid_601332 = validateParameter(valid_601332, JString, required = false,
                                 default = nil)
  if valid_601332 != nil:
    section.add "X-Amz-Credential", valid_601332
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601333: Call_GetSwapEnvironmentCNAMEs_601317; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Swaps the CNAMEs of two environments.
  ## 
  let valid = call_601333.validator(path, query, header, formData, body)
  let scheme = call_601333.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601333.url(scheme.get, call_601333.host, call_601333.base,
                         call_601333.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601333, url, valid)

proc call*(call_601334: Call_GetSwapEnvironmentCNAMEs_601317;
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
  var query_601335 = newJObject()
  add(query_601335, "SourceEnvironmentId", newJString(SourceEnvironmentId))
  add(query_601335, "DestinationEnvironmentName",
      newJString(DestinationEnvironmentName))
  add(query_601335, "Action", newJString(Action))
  add(query_601335, "SourceEnvironmentName", newJString(SourceEnvironmentName))
  add(query_601335, "DestinationEnvironmentId",
      newJString(DestinationEnvironmentId))
  add(query_601335, "Version", newJString(Version))
  result = call_601334.call(nil, query_601335, nil, nil, nil)

var getSwapEnvironmentCNAMEs* = Call_GetSwapEnvironmentCNAMEs_601317(
    name: "getSwapEnvironmentCNAMEs", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=SwapEnvironmentCNAMEs",
    validator: validate_GetSwapEnvironmentCNAMEs_601318, base: "/",
    url: url_GetSwapEnvironmentCNAMEs_601319, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostTerminateEnvironment_601375 = ref object of OpenApiRestCall_599369
proc url_PostTerminateEnvironment_601377(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostTerminateEnvironment_601376(path: JsonNode; query: JsonNode;
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
  var valid_601378 = query.getOrDefault("Action")
  valid_601378 = validateParameter(valid_601378, JString, required = true,
                                 default = newJString("TerminateEnvironment"))
  if valid_601378 != nil:
    section.add "Action", valid_601378
  var valid_601379 = query.getOrDefault("Version")
  valid_601379 = validateParameter(valid_601379, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601379 != nil:
    section.add "Version", valid_601379
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601380 = header.getOrDefault("X-Amz-Date")
  valid_601380 = validateParameter(valid_601380, JString, required = false,
                                 default = nil)
  if valid_601380 != nil:
    section.add "X-Amz-Date", valid_601380
  var valid_601381 = header.getOrDefault("X-Amz-Security-Token")
  valid_601381 = validateParameter(valid_601381, JString, required = false,
                                 default = nil)
  if valid_601381 != nil:
    section.add "X-Amz-Security-Token", valid_601381
  var valid_601382 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601382 = validateParameter(valid_601382, JString, required = false,
                                 default = nil)
  if valid_601382 != nil:
    section.add "X-Amz-Content-Sha256", valid_601382
  var valid_601383 = header.getOrDefault("X-Amz-Algorithm")
  valid_601383 = validateParameter(valid_601383, JString, required = false,
                                 default = nil)
  if valid_601383 != nil:
    section.add "X-Amz-Algorithm", valid_601383
  var valid_601384 = header.getOrDefault("X-Amz-Signature")
  valid_601384 = validateParameter(valid_601384, JString, required = false,
                                 default = nil)
  if valid_601384 != nil:
    section.add "X-Amz-Signature", valid_601384
  var valid_601385 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601385 = validateParameter(valid_601385, JString, required = false,
                                 default = nil)
  if valid_601385 != nil:
    section.add "X-Amz-SignedHeaders", valid_601385
  var valid_601386 = header.getOrDefault("X-Amz-Credential")
  valid_601386 = validateParameter(valid_601386, JString, required = false,
                                 default = nil)
  if valid_601386 != nil:
    section.add "X-Amz-Credential", valid_601386
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
  var valid_601387 = formData.getOrDefault("ForceTerminate")
  valid_601387 = validateParameter(valid_601387, JBool, required = false, default = nil)
  if valid_601387 != nil:
    section.add "ForceTerminate", valid_601387
  var valid_601388 = formData.getOrDefault("TerminateResources")
  valid_601388 = validateParameter(valid_601388, JBool, required = false, default = nil)
  if valid_601388 != nil:
    section.add "TerminateResources", valid_601388
  var valid_601389 = formData.getOrDefault("EnvironmentId")
  valid_601389 = validateParameter(valid_601389, JString, required = false,
                                 default = nil)
  if valid_601389 != nil:
    section.add "EnvironmentId", valid_601389
  var valid_601390 = formData.getOrDefault("EnvironmentName")
  valid_601390 = validateParameter(valid_601390, JString, required = false,
                                 default = nil)
  if valid_601390 != nil:
    section.add "EnvironmentName", valid_601390
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601391: Call_PostTerminateEnvironment_601375; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Terminates the specified environment.
  ## 
  let valid = call_601391.validator(path, query, header, formData, body)
  let scheme = call_601391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601391.url(scheme.get, call_601391.host, call_601391.base,
                         call_601391.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601391, url, valid)

proc call*(call_601392: Call_PostTerminateEnvironment_601375;
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
  var query_601393 = newJObject()
  var formData_601394 = newJObject()
  add(formData_601394, "ForceTerminate", newJBool(ForceTerminate))
  add(formData_601394, "TerminateResources", newJBool(TerminateResources))
  add(formData_601394, "EnvironmentId", newJString(EnvironmentId))
  add(formData_601394, "EnvironmentName", newJString(EnvironmentName))
  add(query_601393, "Action", newJString(Action))
  add(query_601393, "Version", newJString(Version))
  result = call_601392.call(nil, query_601393, nil, formData_601394, nil)

var postTerminateEnvironment* = Call_PostTerminateEnvironment_601375(
    name: "postTerminateEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=TerminateEnvironment",
    validator: validate_PostTerminateEnvironment_601376, base: "/",
    url: url_PostTerminateEnvironment_601377, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTerminateEnvironment_601356 = ref object of OpenApiRestCall_599369
proc url_GetTerminateEnvironment_601358(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTerminateEnvironment_601357(path: JsonNode; query: JsonNode;
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
  var valid_601359 = query.getOrDefault("EnvironmentName")
  valid_601359 = validateParameter(valid_601359, JString, required = false,
                                 default = nil)
  if valid_601359 != nil:
    section.add "EnvironmentName", valid_601359
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601360 = query.getOrDefault("Action")
  valid_601360 = validateParameter(valid_601360, JString, required = true,
                                 default = newJString("TerminateEnvironment"))
  if valid_601360 != nil:
    section.add "Action", valid_601360
  var valid_601361 = query.getOrDefault("EnvironmentId")
  valid_601361 = validateParameter(valid_601361, JString, required = false,
                                 default = nil)
  if valid_601361 != nil:
    section.add "EnvironmentId", valid_601361
  var valid_601362 = query.getOrDefault("ForceTerminate")
  valid_601362 = validateParameter(valid_601362, JBool, required = false, default = nil)
  if valid_601362 != nil:
    section.add "ForceTerminate", valid_601362
  var valid_601363 = query.getOrDefault("TerminateResources")
  valid_601363 = validateParameter(valid_601363, JBool, required = false, default = nil)
  if valid_601363 != nil:
    section.add "TerminateResources", valid_601363
  var valid_601364 = query.getOrDefault("Version")
  valid_601364 = validateParameter(valid_601364, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601364 != nil:
    section.add "Version", valid_601364
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601365 = header.getOrDefault("X-Amz-Date")
  valid_601365 = validateParameter(valid_601365, JString, required = false,
                                 default = nil)
  if valid_601365 != nil:
    section.add "X-Amz-Date", valid_601365
  var valid_601366 = header.getOrDefault("X-Amz-Security-Token")
  valid_601366 = validateParameter(valid_601366, JString, required = false,
                                 default = nil)
  if valid_601366 != nil:
    section.add "X-Amz-Security-Token", valid_601366
  var valid_601367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601367 = validateParameter(valid_601367, JString, required = false,
                                 default = nil)
  if valid_601367 != nil:
    section.add "X-Amz-Content-Sha256", valid_601367
  var valid_601368 = header.getOrDefault("X-Amz-Algorithm")
  valid_601368 = validateParameter(valid_601368, JString, required = false,
                                 default = nil)
  if valid_601368 != nil:
    section.add "X-Amz-Algorithm", valid_601368
  var valid_601369 = header.getOrDefault("X-Amz-Signature")
  valid_601369 = validateParameter(valid_601369, JString, required = false,
                                 default = nil)
  if valid_601369 != nil:
    section.add "X-Amz-Signature", valid_601369
  var valid_601370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601370 = validateParameter(valid_601370, JString, required = false,
                                 default = nil)
  if valid_601370 != nil:
    section.add "X-Amz-SignedHeaders", valid_601370
  var valid_601371 = header.getOrDefault("X-Amz-Credential")
  valid_601371 = validateParameter(valid_601371, JString, required = false,
                                 default = nil)
  if valid_601371 != nil:
    section.add "X-Amz-Credential", valid_601371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601372: Call_GetTerminateEnvironment_601356; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Terminates the specified environment.
  ## 
  let valid = call_601372.validator(path, query, header, formData, body)
  let scheme = call_601372.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601372.url(scheme.get, call_601372.host, call_601372.base,
                         call_601372.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601372, url, valid)

proc call*(call_601373: Call_GetTerminateEnvironment_601356;
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
  var query_601374 = newJObject()
  add(query_601374, "EnvironmentName", newJString(EnvironmentName))
  add(query_601374, "Action", newJString(Action))
  add(query_601374, "EnvironmentId", newJString(EnvironmentId))
  add(query_601374, "ForceTerminate", newJBool(ForceTerminate))
  add(query_601374, "TerminateResources", newJBool(TerminateResources))
  add(query_601374, "Version", newJString(Version))
  result = call_601373.call(nil, query_601374, nil, nil, nil)

var getTerminateEnvironment* = Call_GetTerminateEnvironment_601356(
    name: "getTerminateEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=TerminateEnvironment",
    validator: validate_GetTerminateEnvironment_601357, base: "/",
    url: url_GetTerminateEnvironment_601358, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateApplication_601412 = ref object of OpenApiRestCall_599369
proc url_PostUpdateApplication_601414(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateApplication_601413(path: JsonNode; query: JsonNode;
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
  var valid_601415 = query.getOrDefault("Action")
  valid_601415 = validateParameter(valid_601415, JString, required = true,
                                 default = newJString("UpdateApplication"))
  if valid_601415 != nil:
    section.add "Action", valid_601415
  var valid_601416 = query.getOrDefault("Version")
  valid_601416 = validateParameter(valid_601416, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601416 != nil:
    section.add "Version", valid_601416
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601417 = header.getOrDefault("X-Amz-Date")
  valid_601417 = validateParameter(valid_601417, JString, required = false,
                                 default = nil)
  if valid_601417 != nil:
    section.add "X-Amz-Date", valid_601417
  var valid_601418 = header.getOrDefault("X-Amz-Security-Token")
  valid_601418 = validateParameter(valid_601418, JString, required = false,
                                 default = nil)
  if valid_601418 != nil:
    section.add "X-Amz-Security-Token", valid_601418
  var valid_601419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601419 = validateParameter(valid_601419, JString, required = false,
                                 default = nil)
  if valid_601419 != nil:
    section.add "X-Amz-Content-Sha256", valid_601419
  var valid_601420 = header.getOrDefault("X-Amz-Algorithm")
  valid_601420 = validateParameter(valid_601420, JString, required = false,
                                 default = nil)
  if valid_601420 != nil:
    section.add "X-Amz-Algorithm", valid_601420
  var valid_601421 = header.getOrDefault("X-Amz-Signature")
  valid_601421 = validateParameter(valid_601421, JString, required = false,
                                 default = nil)
  if valid_601421 != nil:
    section.add "X-Amz-Signature", valid_601421
  var valid_601422 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601422 = validateParameter(valid_601422, JString, required = false,
                                 default = nil)
  if valid_601422 != nil:
    section.add "X-Amz-SignedHeaders", valid_601422
  var valid_601423 = header.getOrDefault("X-Amz-Credential")
  valid_601423 = validateParameter(valid_601423, JString, required = false,
                                 default = nil)
  if valid_601423 != nil:
    section.add "X-Amz-Credential", valid_601423
  result.add "header", section
  ## parameters in `formData` object:
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to update. If no such application is found, <code>UpdateApplication</code> returns an <code>InvalidParameterValue</code> error. 
  ##   Description: JString
  ##              : <p>A new description for the application.</p> <p>Default: If not specified, AWS Elastic Beanstalk does not update the description.</p>
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_601424 = formData.getOrDefault("ApplicationName")
  valid_601424 = validateParameter(valid_601424, JString, required = true,
                                 default = nil)
  if valid_601424 != nil:
    section.add "ApplicationName", valid_601424
  var valid_601425 = formData.getOrDefault("Description")
  valid_601425 = validateParameter(valid_601425, JString, required = false,
                                 default = nil)
  if valid_601425 != nil:
    section.add "Description", valid_601425
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601426: Call_PostUpdateApplication_601412; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified application to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear these properties, specify an empty string.</p> </note>
  ## 
  let valid = call_601426.validator(path, query, header, formData, body)
  let scheme = call_601426.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601426.url(scheme.get, call_601426.host, call_601426.base,
                         call_601426.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601426, url, valid)

proc call*(call_601427: Call_PostUpdateApplication_601412; ApplicationName: string;
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
  var query_601428 = newJObject()
  var formData_601429 = newJObject()
  add(query_601428, "Action", newJString(Action))
  add(formData_601429, "ApplicationName", newJString(ApplicationName))
  add(query_601428, "Version", newJString(Version))
  add(formData_601429, "Description", newJString(Description))
  result = call_601427.call(nil, query_601428, nil, formData_601429, nil)

var postUpdateApplication* = Call_PostUpdateApplication_601412(
    name: "postUpdateApplication", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateApplication",
    validator: validate_PostUpdateApplication_601413, base: "/",
    url: url_PostUpdateApplication_601414, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateApplication_601395 = ref object of OpenApiRestCall_599369
proc url_GetUpdateApplication_601397(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateApplication_601396(path: JsonNode; query: JsonNode;
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
  var valid_601398 = query.getOrDefault("ApplicationName")
  valid_601398 = validateParameter(valid_601398, JString, required = true,
                                 default = nil)
  if valid_601398 != nil:
    section.add "ApplicationName", valid_601398
  var valid_601399 = query.getOrDefault("Description")
  valid_601399 = validateParameter(valid_601399, JString, required = false,
                                 default = nil)
  if valid_601399 != nil:
    section.add "Description", valid_601399
  var valid_601400 = query.getOrDefault("Action")
  valid_601400 = validateParameter(valid_601400, JString, required = true,
                                 default = newJString("UpdateApplication"))
  if valid_601400 != nil:
    section.add "Action", valid_601400
  var valid_601401 = query.getOrDefault("Version")
  valid_601401 = validateParameter(valid_601401, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601401 != nil:
    section.add "Version", valid_601401
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601402 = header.getOrDefault("X-Amz-Date")
  valid_601402 = validateParameter(valid_601402, JString, required = false,
                                 default = nil)
  if valid_601402 != nil:
    section.add "X-Amz-Date", valid_601402
  var valid_601403 = header.getOrDefault("X-Amz-Security-Token")
  valid_601403 = validateParameter(valid_601403, JString, required = false,
                                 default = nil)
  if valid_601403 != nil:
    section.add "X-Amz-Security-Token", valid_601403
  var valid_601404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601404 = validateParameter(valid_601404, JString, required = false,
                                 default = nil)
  if valid_601404 != nil:
    section.add "X-Amz-Content-Sha256", valid_601404
  var valid_601405 = header.getOrDefault("X-Amz-Algorithm")
  valid_601405 = validateParameter(valid_601405, JString, required = false,
                                 default = nil)
  if valid_601405 != nil:
    section.add "X-Amz-Algorithm", valid_601405
  var valid_601406 = header.getOrDefault("X-Amz-Signature")
  valid_601406 = validateParameter(valid_601406, JString, required = false,
                                 default = nil)
  if valid_601406 != nil:
    section.add "X-Amz-Signature", valid_601406
  var valid_601407 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601407 = validateParameter(valid_601407, JString, required = false,
                                 default = nil)
  if valid_601407 != nil:
    section.add "X-Amz-SignedHeaders", valid_601407
  var valid_601408 = header.getOrDefault("X-Amz-Credential")
  valid_601408 = validateParameter(valid_601408, JString, required = false,
                                 default = nil)
  if valid_601408 != nil:
    section.add "X-Amz-Credential", valid_601408
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601409: Call_GetUpdateApplication_601395; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified application to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear these properties, specify an empty string.</p> </note>
  ## 
  let valid = call_601409.validator(path, query, header, formData, body)
  let scheme = call_601409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601409.url(scheme.get, call_601409.host, call_601409.base,
                         call_601409.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601409, url, valid)

proc call*(call_601410: Call_GetUpdateApplication_601395; ApplicationName: string;
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
  var query_601411 = newJObject()
  add(query_601411, "ApplicationName", newJString(ApplicationName))
  add(query_601411, "Description", newJString(Description))
  add(query_601411, "Action", newJString(Action))
  add(query_601411, "Version", newJString(Version))
  result = call_601410.call(nil, query_601411, nil, nil, nil)

var getUpdateApplication* = Call_GetUpdateApplication_601395(
    name: "getUpdateApplication", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateApplication",
    validator: validate_GetUpdateApplication_601396, base: "/",
    url: url_GetUpdateApplication_601397, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateApplicationResourceLifecycle_601448 = ref object of OpenApiRestCall_599369
proc url_PostUpdateApplicationResourceLifecycle_601450(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateApplicationResourceLifecycle_601449(path: JsonNode;
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
  var valid_601451 = query.getOrDefault("Action")
  valid_601451 = validateParameter(valid_601451, JString, required = true, default = newJString(
      "UpdateApplicationResourceLifecycle"))
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
  var valid_601460 = formData.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_601460 = validateParameter(valid_601460, JString, required = false,
                                 default = nil)
  if valid_601460 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_601460
  var valid_601461 = formData.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_601461 = validateParameter(valid_601461, JString, required = false,
                                 default = nil)
  if valid_601461 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_601461
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_601462 = formData.getOrDefault("ApplicationName")
  valid_601462 = validateParameter(valid_601462, JString, required = true,
                                 default = nil)
  if valid_601462 != nil:
    section.add "ApplicationName", valid_601462
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601463: Call_PostUpdateApplicationResourceLifecycle_601448;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Modifies lifecycle settings for an application.
  ## 
  let valid = call_601463.validator(path, query, header, formData, body)
  let scheme = call_601463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601463.url(scheme.get, call_601463.host, call_601463.base,
                         call_601463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601463, url, valid)

proc call*(call_601464: Call_PostUpdateApplicationResourceLifecycle_601448;
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
  var query_601465 = newJObject()
  var formData_601466 = newJObject()
  add(formData_601466, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  add(formData_601466, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  add(query_601465, "Action", newJString(Action))
  add(formData_601466, "ApplicationName", newJString(ApplicationName))
  add(query_601465, "Version", newJString(Version))
  result = call_601464.call(nil, query_601465, nil, formData_601466, nil)

var postUpdateApplicationResourceLifecycle* = Call_PostUpdateApplicationResourceLifecycle_601448(
    name: "postUpdateApplicationResourceLifecycle", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationResourceLifecycle",
    validator: validate_PostUpdateApplicationResourceLifecycle_601449, base: "/",
    url: url_PostUpdateApplicationResourceLifecycle_601450,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateApplicationResourceLifecycle_601430 = ref object of OpenApiRestCall_599369
proc url_GetUpdateApplicationResourceLifecycle_601432(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateApplicationResourceLifecycle_601431(path: JsonNode;
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
  var valid_601433 = query.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_601433 = validateParameter(valid_601433, JString, required = false,
                                 default = nil)
  if valid_601433 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_601433
  assert query != nil,
        "query argument is necessary due to required `ApplicationName` field"
  var valid_601434 = query.getOrDefault("ApplicationName")
  valid_601434 = validateParameter(valid_601434, JString, required = true,
                                 default = nil)
  if valid_601434 != nil:
    section.add "ApplicationName", valid_601434
  var valid_601435 = query.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_601435 = validateParameter(valid_601435, JString, required = false,
                                 default = nil)
  if valid_601435 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_601435
  var valid_601436 = query.getOrDefault("Action")
  valid_601436 = validateParameter(valid_601436, JString, required = true, default = newJString(
      "UpdateApplicationResourceLifecycle"))
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

proc call*(call_601445: Call_GetUpdateApplicationResourceLifecycle_601430;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Modifies lifecycle settings for an application.
  ## 
  let valid = call_601445.validator(path, query, header, formData, body)
  let scheme = call_601445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601445.url(scheme.get, call_601445.host, call_601445.base,
                         call_601445.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601445, url, valid)

proc call*(call_601446: Call_GetUpdateApplicationResourceLifecycle_601430;
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
  var query_601447 = newJObject()
  add(query_601447, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  add(query_601447, "ApplicationName", newJString(ApplicationName))
  add(query_601447, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  add(query_601447, "Action", newJString(Action))
  add(query_601447, "Version", newJString(Version))
  result = call_601446.call(nil, query_601447, nil, nil, nil)

var getUpdateApplicationResourceLifecycle* = Call_GetUpdateApplicationResourceLifecycle_601430(
    name: "getUpdateApplicationResourceLifecycle", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationResourceLifecycle",
    validator: validate_GetUpdateApplicationResourceLifecycle_601431, base: "/",
    url: url_GetUpdateApplicationResourceLifecycle_601432,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateApplicationVersion_601485 = ref object of OpenApiRestCall_599369
proc url_PostUpdateApplicationVersion_601487(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateApplicationVersion_601486(path: JsonNode; query: JsonNode;
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
  var valid_601488 = query.getOrDefault("Action")
  valid_601488 = validateParameter(valid_601488, JString, required = true, default = newJString(
      "UpdateApplicationVersion"))
  if valid_601488 != nil:
    section.add "Action", valid_601488
  var valid_601489 = query.getOrDefault("Version")
  valid_601489 = validateParameter(valid_601489, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601489 != nil:
    section.add "Version", valid_601489
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601490 = header.getOrDefault("X-Amz-Date")
  valid_601490 = validateParameter(valid_601490, JString, required = false,
                                 default = nil)
  if valid_601490 != nil:
    section.add "X-Amz-Date", valid_601490
  var valid_601491 = header.getOrDefault("X-Amz-Security-Token")
  valid_601491 = validateParameter(valid_601491, JString, required = false,
                                 default = nil)
  if valid_601491 != nil:
    section.add "X-Amz-Security-Token", valid_601491
  var valid_601492 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601492 = validateParameter(valid_601492, JString, required = false,
                                 default = nil)
  if valid_601492 != nil:
    section.add "X-Amz-Content-Sha256", valid_601492
  var valid_601493 = header.getOrDefault("X-Amz-Algorithm")
  valid_601493 = validateParameter(valid_601493, JString, required = false,
                                 default = nil)
  if valid_601493 != nil:
    section.add "X-Amz-Algorithm", valid_601493
  var valid_601494 = header.getOrDefault("X-Amz-Signature")
  valid_601494 = validateParameter(valid_601494, JString, required = false,
                                 default = nil)
  if valid_601494 != nil:
    section.add "X-Amz-Signature", valid_601494
  var valid_601495 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601495 = validateParameter(valid_601495, JString, required = false,
                                 default = nil)
  if valid_601495 != nil:
    section.add "X-Amz-SignedHeaders", valid_601495
  var valid_601496 = header.getOrDefault("X-Amz-Credential")
  valid_601496 = validateParameter(valid_601496, JString, required = false,
                                 default = nil)
  if valid_601496 != nil:
    section.add "X-Amz-Credential", valid_601496
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
  var valid_601497 = formData.getOrDefault("VersionLabel")
  valid_601497 = validateParameter(valid_601497, JString, required = true,
                                 default = nil)
  if valid_601497 != nil:
    section.add "VersionLabel", valid_601497
  var valid_601498 = formData.getOrDefault("ApplicationName")
  valid_601498 = validateParameter(valid_601498, JString, required = true,
                                 default = nil)
  if valid_601498 != nil:
    section.add "ApplicationName", valid_601498
  var valid_601499 = formData.getOrDefault("Description")
  valid_601499 = validateParameter(valid_601499, JString, required = false,
                                 default = nil)
  if valid_601499 != nil:
    section.add "Description", valid_601499
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601500: Call_PostUpdateApplicationVersion_601485; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified application version to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear properties, specify an empty string.</p> </note>
  ## 
  let valid = call_601500.validator(path, query, header, formData, body)
  let scheme = call_601500.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601500.url(scheme.get, call_601500.host, call_601500.base,
                         call_601500.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601500, url, valid)

proc call*(call_601501: Call_PostUpdateApplicationVersion_601485;
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
  var query_601502 = newJObject()
  var formData_601503 = newJObject()
  add(formData_601503, "VersionLabel", newJString(VersionLabel))
  add(query_601502, "Action", newJString(Action))
  add(formData_601503, "ApplicationName", newJString(ApplicationName))
  add(query_601502, "Version", newJString(Version))
  add(formData_601503, "Description", newJString(Description))
  result = call_601501.call(nil, query_601502, nil, formData_601503, nil)

var postUpdateApplicationVersion* = Call_PostUpdateApplicationVersion_601485(
    name: "postUpdateApplicationVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationVersion",
    validator: validate_PostUpdateApplicationVersion_601486, base: "/",
    url: url_PostUpdateApplicationVersion_601487,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateApplicationVersion_601467 = ref object of OpenApiRestCall_599369
proc url_GetUpdateApplicationVersion_601469(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateApplicationVersion_601468(path: JsonNode; query: JsonNode;
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
  var valid_601470 = query.getOrDefault("VersionLabel")
  valid_601470 = validateParameter(valid_601470, JString, required = true,
                                 default = nil)
  if valid_601470 != nil:
    section.add "VersionLabel", valid_601470
  var valid_601471 = query.getOrDefault("ApplicationName")
  valid_601471 = validateParameter(valid_601471, JString, required = true,
                                 default = nil)
  if valid_601471 != nil:
    section.add "ApplicationName", valid_601471
  var valid_601472 = query.getOrDefault("Description")
  valid_601472 = validateParameter(valid_601472, JString, required = false,
                                 default = nil)
  if valid_601472 != nil:
    section.add "Description", valid_601472
  var valid_601473 = query.getOrDefault("Action")
  valid_601473 = validateParameter(valid_601473, JString, required = true, default = newJString(
      "UpdateApplicationVersion"))
  if valid_601473 != nil:
    section.add "Action", valid_601473
  var valid_601474 = query.getOrDefault("Version")
  valid_601474 = validateParameter(valid_601474, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601474 != nil:
    section.add "Version", valid_601474
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601475 = header.getOrDefault("X-Amz-Date")
  valid_601475 = validateParameter(valid_601475, JString, required = false,
                                 default = nil)
  if valid_601475 != nil:
    section.add "X-Amz-Date", valid_601475
  var valid_601476 = header.getOrDefault("X-Amz-Security-Token")
  valid_601476 = validateParameter(valid_601476, JString, required = false,
                                 default = nil)
  if valid_601476 != nil:
    section.add "X-Amz-Security-Token", valid_601476
  var valid_601477 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601477 = validateParameter(valid_601477, JString, required = false,
                                 default = nil)
  if valid_601477 != nil:
    section.add "X-Amz-Content-Sha256", valid_601477
  var valid_601478 = header.getOrDefault("X-Amz-Algorithm")
  valid_601478 = validateParameter(valid_601478, JString, required = false,
                                 default = nil)
  if valid_601478 != nil:
    section.add "X-Amz-Algorithm", valid_601478
  var valid_601479 = header.getOrDefault("X-Amz-Signature")
  valid_601479 = validateParameter(valid_601479, JString, required = false,
                                 default = nil)
  if valid_601479 != nil:
    section.add "X-Amz-Signature", valid_601479
  var valid_601480 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601480 = validateParameter(valid_601480, JString, required = false,
                                 default = nil)
  if valid_601480 != nil:
    section.add "X-Amz-SignedHeaders", valid_601480
  var valid_601481 = header.getOrDefault("X-Amz-Credential")
  valid_601481 = validateParameter(valid_601481, JString, required = false,
                                 default = nil)
  if valid_601481 != nil:
    section.add "X-Amz-Credential", valid_601481
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601482: Call_GetUpdateApplicationVersion_601467; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified application version to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear properties, specify an empty string.</p> </note>
  ## 
  let valid = call_601482.validator(path, query, header, formData, body)
  let scheme = call_601482.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601482.url(scheme.get, call_601482.host, call_601482.base,
                         call_601482.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601482, url, valid)

proc call*(call_601483: Call_GetUpdateApplicationVersion_601467;
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
  var query_601484 = newJObject()
  add(query_601484, "VersionLabel", newJString(VersionLabel))
  add(query_601484, "ApplicationName", newJString(ApplicationName))
  add(query_601484, "Description", newJString(Description))
  add(query_601484, "Action", newJString(Action))
  add(query_601484, "Version", newJString(Version))
  result = call_601483.call(nil, query_601484, nil, nil, nil)

var getUpdateApplicationVersion* = Call_GetUpdateApplicationVersion_601467(
    name: "getUpdateApplicationVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationVersion",
    validator: validate_GetUpdateApplicationVersion_601468, base: "/",
    url: url_GetUpdateApplicationVersion_601469,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateConfigurationTemplate_601524 = ref object of OpenApiRestCall_599369
proc url_PostUpdateConfigurationTemplate_601526(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateConfigurationTemplate_601525(path: JsonNode;
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
  var valid_601527 = query.getOrDefault("Action")
  valid_601527 = validateParameter(valid_601527, JString, required = true, default = newJString(
      "UpdateConfigurationTemplate"))
  if valid_601527 != nil:
    section.add "Action", valid_601527
  var valid_601528 = query.getOrDefault("Version")
  valid_601528 = validateParameter(valid_601528, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601528 != nil:
    section.add "Version", valid_601528
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601529 = header.getOrDefault("X-Amz-Date")
  valid_601529 = validateParameter(valid_601529, JString, required = false,
                                 default = nil)
  if valid_601529 != nil:
    section.add "X-Amz-Date", valid_601529
  var valid_601530 = header.getOrDefault("X-Amz-Security-Token")
  valid_601530 = validateParameter(valid_601530, JString, required = false,
                                 default = nil)
  if valid_601530 != nil:
    section.add "X-Amz-Security-Token", valid_601530
  var valid_601531 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601531 = validateParameter(valid_601531, JString, required = false,
                                 default = nil)
  if valid_601531 != nil:
    section.add "X-Amz-Content-Sha256", valid_601531
  var valid_601532 = header.getOrDefault("X-Amz-Algorithm")
  valid_601532 = validateParameter(valid_601532, JString, required = false,
                                 default = nil)
  if valid_601532 != nil:
    section.add "X-Amz-Algorithm", valid_601532
  var valid_601533 = header.getOrDefault("X-Amz-Signature")
  valid_601533 = validateParameter(valid_601533, JString, required = false,
                                 default = nil)
  if valid_601533 != nil:
    section.add "X-Amz-Signature", valid_601533
  var valid_601534 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601534 = validateParameter(valid_601534, JString, required = false,
                                 default = nil)
  if valid_601534 != nil:
    section.add "X-Amz-SignedHeaders", valid_601534
  var valid_601535 = header.getOrDefault("X-Amz-Credential")
  valid_601535 = validateParameter(valid_601535, JString, required = false,
                                 default = nil)
  if valid_601535 != nil:
    section.add "X-Amz-Credential", valid_601535
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
  var valid_601536 = formData.getOrDefault("OptionsToRemove")
  valid_601536 = validateParameter(valid_601536, JArray, required = false,
                                 default = nil)
  if valid_601536 != nil:
    section.add "OptionsToRemove", valid_601536
  var valid_601537 = formData.getOrDefault("OptionSettings")
  valid_601537 = validateParameter(valid_601537, JArray, required = false,
                                 default = nil)
  if valid_601537 != nil:
    section.add "OptionSettings", valid_601537
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_601538 = formData.getOrDefault("ApplicationName")
  valid_601538 = validateParameter(valid_601538, JString, required = true,
                                 default = nil)
  if valid_601538 != nil:
    section.add "ApplicationName", valid_601538
  var valid_601539 = formData.getOrDefault("TemplateName")
  valid_601539 = validateParameter(valid_601539, JString, required = true,
                                 default = nil)
  if valid_601539 != nil:
    section.add "TemplateName", valid_601539
  var valid_601540 = formData.getOrDefault("Description")
  valid_601540 = validateParameter(valid_601540, JString, required = false,
                                 default = nil)
  if valid_601540 != nil:
    section.add "Description", valid_601540
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601541: Call_PostUpdateConfigurationTemplate_601524;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Updates the specified configuration template to have the specified properties or configuration option values.</p> <note> <p>If a property (for example, <code>ApplicationName</code>) is not provided, its value remains unchanged. To clear such properties, specify an empty string.</p> </note> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> </ul>
  ## 
  let valid = call_601541.validator(path, query, header, formData, body)
  let scheme = call_601541.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601541.url(scheme.get, call_601541.host, call_601541.base,
                         call_601541.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601541, url, valid)

proc call*(call_601542: Call_PostUpdateConfigurationTemplate_601524;
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
  var query_601543 = newJObject()
  var formData_601544 = newJObject()
  if OptionsToRemove != nil:
    formData_601544.add "OptionsToRemove", OptionsToRemove
  if OptionSettings != nil:
    formData_601544.add "OptionSettings", OptionSettings
  add(query_601543, "Action", newJString(Action))
  add(formData_601544, "ApplicationName", newJString(ApplicationName))
  add(formData_601544, "TemplateName", newJString(TemplateName))
  add(query_601543, "Version", newJString(Version))
  add(formData_601544, "Description", newJString(Description))
  result = call_601542.call(nil, query_601543, nil, formData_601544, nil)

var postUpdateConfigurationTemplate* = Call_PostUpdateConfigurationTemplate_601524(
    name: "postUpdateConfigurationTemplate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateConfigurationTemplate",
    validator: validate_PostUpdateConfigurationTemplate_601525, base: "/",
    url: url_PostUpdateConfigurationTemplate_601526,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateConfigurationTemplate_601504 = ref object of OpenApiRestCall_599369
proc url_GetUpdateConfigurationTemplate_601506(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateConfigurationTemplate_601505(path: JsonNode;
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
  var valid_601507 = query.getOrDefault("ApplicationName")
  valid_601507 = validateParameter(valid_601507, JString, required = true,
                                 default = nil)
  if valid_601507 != nil:
    section.add "ApplicationName", valid_601507
  var valid_601508 = query.getOrDefault("Description")
  valid_601508 = validateParameter(valid_601508, JString, required = false,
                                 default = nil)
  if valid_601508 != nil:
    section.add "Description", valid_601508
  var valid_601509 = query.getOrDefault("OptionsToRemove")
  valid_601509 = validateParameter(valid_601509, JArray, required = false,
                                 default = nil)
  if valid_601509 != nil:
    section.add "OptionsToRemove", valid_601509
  var valid_601510 = query.getOrDefault("Action")
  valid_601510 = validateParameter(valid_601510, JString, required = true, default = newJString(
      "UpdateConfigurationTemplate"))
  if valid_601510 != nil:
    section.add "Action", valid_601510
  var valid_601511 = query.getOrDefault("TemplateName")
  valid_601511 = validateParameter(valid_601511, JString, required = true,
                                 default = nil)
  if valid_601511 != nil:
    section.add "TemplateName", valid_601511
  var valid_601512 = query.getOrDefault("OptionSettings")
  valid_601512 = validateParameter(valid_601512, JArray, required = false,
                                 default = nil)
  if valid_601512 != nil:
    section.add "OptionSettings", valid_601512
  var valid_601513 = query.getOrDefault("Version")
  valid_601513 = validateParameter(valid_601513, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601513 != nil:
    section.add "Version", valid_601513
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601514 = header.getOrDefault("X-Amz-Date")
  valid_601514 = validateParameter(valid_601514, JString, required = false,
                                 default = nil)
  if valid_601514 != nil:
    section.add "X-Amz-Date", valid_601514
  var valid_601515 = header.getOrDefault("X-Amz-Security-Token")
  valid_601515 = validateParameter(valid_601515, JString, required = false,
                                 default = nil)
  if valid_601515 != nil:
    section.add "X-Amz-Security-Token", valid_601515
  var valid_601516 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601516 = validateParameter(valid_601516, JString, required = false,
                                 default = nil)
  if valid_601516 != nil:
    section.add "X-Amz-Content-Sha256", valid_601516
  var valid_601517 = header.getOrDefault("X-Amz-Algorithm")
  valid_601517 = validateParameter(valid_601517, JString, required = false,
                                 default = nil)
  if valid_601517 != nil:
    section.add "X-Amz-Algorithm", valid_601517
  var valid_601518 = header.getOrDefault("X-Amz-Signature")
  valid_601518 = validateParameter(valid_601518, JString, required = false,
                                 default = nil)
  if valid_601518 != nil:
    section.add "X-Amz-Signature", valid_601518
  var valid_601519 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601519 = validateParameter(valid_601519, JString, required = false,
                                 default = nil)
  if valid_601519 != nil:
    section.add "X-Amz-SignedHeaders", valid_601519
  var valid_601520 = header.getOrDefault("X-Amz-Credential")
  valid_601520 = validateParameter(valid_601520, JString, required = false,
                                 default = nil)
  if valid_601520 != nil:
    section.add "X-Amz-Credential", valid_601520
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601521: Call_GetUpdateConfigurationTemplate_601504; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified configuration template to have the specified properties or configuration option values.</p> <note> <p>If a property (for example, <code>ApplicationName</code>) is not provided, its value remains unchanged. To clear such properties, specify an empty string.</p> </note> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> </ul>
  ## 
  let valid = call_601521.validator(path, query, header, formData, body)
  let scheme = call_601521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601521.url(scheme.get, call_601521.host, call_601521.base,
                         call_601521.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601521, url, valid)

proc call*(call_601522: Call_GetUpdateConfigurationTemplate_601504;
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
  var query_601523 = newJObject()
  add(query_601523, "ApplicationName", newJString(ApplicationName))
  add(query_601523, "Description", newJString(Description))
  if OptionsToRemove != nil:
    query_601523.add "OptionsToRemove", OptionsToRemove
  add(query_601523, "Action", newJString(Action))
  add(query_601523, "TemplateName", newJString(TemplateName))
  if OptionSettings != nil:
    query_601523.add "OptionSettings", OptionSettings
  add(query_601523, "Version", newJString(Version))
  result = call_601522.call(nil, query_601523, nil, nil, nil)

var getUpdateConfigurationTemplate* = Call_GetUpdateConfigurationTemplate_601504(
    name: "getUpdateConfigurationTemplate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateConfigurationTemplate",
    validator: validate_GetUpdateConfigurationTemplate_601505, base: "/",
    url: url_GetUpdateConfigurationTemplate_601506,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateEnvironment_601574 = ref object of OpenApiRestCall_599369
proc url_PostUpdateEnvironment_601576(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateEnvironment_601575(path: JsonNode; query: JsonNode;
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
  var valid_601577 = query.getOrDefault("Action")
  valid_601577 = validateParameter(valid_601577, JString, required = true,
                                 default = newJString("UpdateEnvironment"))
  if valid_601577 != nil:
    section.add "Action", valid_601577
  var valid_601578 = query.getOrDefault("Version")
  valid_601578 = validateParameter(valid_601578, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601578 != nil:
    section.add "Version", valid_601578
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601579 = header.getOrDefault("X-Amz-Date")
  valid_601579 = validateParameter(valid_601579, JString, required = false,
                                 default = nil)
  if valid_601579 != nil:
    section.add "X-Amz-Date", valid_601579
  var valid_601580 = header.getOrDefault("X-Amz-Security-Token")
  valid_601580 = validateParameter(valid_601580, JString, required = false,
                                 default = nil)
  if valid_601580 != nil:
    section.add "X-Amz-Security-Token", valid_601580
  var valid_601581 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601581 = validateParameter(valid_601581, JString, required = false,
                                 default = nil)
  if valid_601581 != nil:
    section.add "X-Amz-Content-Sha256", valid_601581
  var valid_601582 = header.getOrDefault("X-Amz-Algorithm")
  valid_601582 = validateParameter(valid_601582, JString, required = false,
                                 default = nil)
  if valid_601582 != nil:
    section.add "X-Amz-Algorithm", valid_601582
  var valid_601583 = header.getOrDefault("X-Amz-Signature")
  valid_601583 = validateParameter(valid_601583, JString, required = false,
                                 default = nil)
  if valid_601583 != nil:
    section.add "X-Amz-Signature", valid_601583
  var valid_601584 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601584 = validateParameter(valid_601584, JString, required = false,
                                 default = nil)
  if valid_601584 != nil:
    section.add "X-Amz-SignedHeaders", valid_601584
  var valid_601585 = header.getOrDefault("X-Amz-Credential")
  valid_601585 = validateParameter(valid_601585, JString, required = false,
                                 default = nil)
  if valid_601585 != nil:
    section.add "X-Amz-Credential", valid_601585
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
  var valid_601586 = formData.getOrDefault("Tier.Name")
  valid_601586 = validateParameter(valid_601586, JString, required = false,
                                 default = nil)
  if valid_601586 != nil:
    section.add "Tier.Name", valid_601586
  var valid_601587 = formData.getOrDefault("OptionsToRemove")
  valid_601587 = validateParameter(valid_601587, JArray, required = false,
                                 default = nil)
  if valid_601587 != nil:
    section.add "OptionsToRemove", valid_601587
  var valid_601588 = formData.getOrDefault("VersionLabel")
  valid_601588 = validateParameter(valid_601588, JString, required = false,
                                 default = nil)
  if valid_601588 != nil:
    section.add "VersionLabel", valid_601588
  var valid_601589 = formData.getOrDefault("OptionSettings")
  valid_601589 = validateParameter(valid_601589, JArray, required = false,
                                 default = nil)
  if valid_601589 != nil:
    section.add "OptionSettings", valid_601589
  var valid_601590 = formData.getOrDefault("GroupName")
  valid_601590 = validateParameter(valid_601590, JString, required = false,
                                 default = nil)
  if valid_601590 != nil:
    section.add "GroupName", valid_601590
  var valid_601591 = formData.getOrDefault("SolutionStackName")
  valid_601591 = validateParameter(valid_601591, JString, required = false,
                                 default = nil)
  if valid_601591 != nil:
    section.add "SolutionStackName", valid_601591
  var valid_601592 = formData.getOrDefault("EnvironmentId")
  valid_601592 = validateParameter(valid_601592, JString, required = false,
                                 default = nil)
  if valid_601592 != nil:
    section.add "EnvironmentId", valid_601592
  var valid_601593 = formData.getOrDefault("EnvironmentName")
  valid_601593 = validateParameter(valid_601593, JString, required = false,
                                 default = nil)
  if valid_601593 != nil:
    section.add "EnvironmentName", valid_601593
  var valid_601594 = formData.getOrDefault("Tier.Type")
  valid_601594 = validateParameter(valid_601594, JString, required = false,
                                 default = nil)
  if valid_601594 != nil:
    section.add "Tier.Type", valid_601594
  var valid_601595 = formData.getOrDefault("ApplicationName")
  valid_601595 = validateParameter(valid_601595, JString, required = false,
                                 default = nil)
  if valid_601595 != nil:
    section.add "ApplicationName", valid_601595
  var valid_601596 = formData.getOrDefault("PlatformArn")
  valid_601596 = validateParameter(valid_601596, JString, required = false,
                                 default = nil)
  if valid_601596 != nil:
    section.add "PlatformArn", valid_601596
  var valid_601597 = formData.getOrDefault("TemplateName")
  valid_601597 = validateParameter(valid_601597, JString, required = false,
                                 default = nil)
  if valid_601597 != nil:
    section.add "TemplateName", valid_601597
  var valid_601598 = formData.getOrDefault("Description")
  valid_601598 = validateParameter(valid_601598, JString, required = false,
                                 default = nil)
  if valid_601598 != nil:
    section.add "Description", valid_601598
  var valid_601599 = formData.getOrDefault("Tier.Version")
  valid_601599 = validateParameter(valid_601599, JString, required = false,
                                 default = nil)
  if valid_601599 != nil:
    section.add "Tier.Version", valid_601599
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601600: Call_PostUpdateEnvironment_601574; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the environment description, deploys a new application version, updates the configuration settings to an entirely new configuration template, or updates select configuration option values in the running environment.</p> <p> Attempting to update both the release and configuration is not allowed and AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. </p> <p> When updating the configuration settings to a new template or individual settings, a draft configuration is created and <a>DescribeConfigurationSettings</a> for this environment returns two setting descriptions with different <code>DeploymentStatus</code> values. </p>
  ## 
  let valid = call_601600.validator(path, query, header, formData, body)
  let scheme = call_601600.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601600.url(scheme.get, call_601600.host, call_601600.base,
                         call_601600.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601600, url, valid)

proc call*(call_601601: Call_PostUpdateEnvironment_601574; TierName: string = "";
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
  var query_601602 = newJObject()
  var formData_601603 = newJObject()
  add(formData_601603, "Tier.Name", newJString(TierName))
  if OptionsToRemove != nil:
    formData_601603.add "OptionsToRemove", OptionsToRemove
  add(formData_601603, "VersionLabel", newJString(VersionLabel))
  if OptionSettings != nil:
    formData_601603.add "OptionSettings", OptionSettings
  add(formData_601603, "GroupName", newJString(GroupName))
  add(formData_601603, "SolutionStackName", newJString(SolutionStackName))
  add(formData_601603, "EnvironmentId", newJString(EnvironmentId))
  add(formData_601603, "EnvironmentName", newJString(EnvironmentName))
  add(formData_601603, "Tier.Type", newJString(TierType))
  add(query_601602, "Action", newJString(Action))
  add(formData_601603, "ApplicationName", newJString(ApplicationName))
  add(formData_601603, "PlatformArn", newJString(PlatformArn))
  add(formData_601603, "TemplateName", newJString(TemplateName))
  add(query_601602, "Version", newJString(Version))
  add(formData_601603, "Description", newJString(Description))
  add(formData_601603, "Tier.Version", newJString(TierVersion))
  result = call_601601.call(nil, query_601602, nil, formData_601603, nil)

var postUpdateEnvironment* = Call_PostUpdateEnvironment_601574(
    name: "postUpdateEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateEnvironment",
    validator: validate_PostUpdateEnvironment_601575, base: "/",
    url: url_PostUpdateEnvironment_601576, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateEnvironment_601545 = ref object of OpenApiRestCall_599369
proc url_GetUpdateEnvironment_601547(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateEnvironment_601546(path: JsonNode; query: JsonNode;
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
  var valid_601548 = query.getOrDefault("Tier.Name")
  valid_601548 = validateParameter(valid_601548, JString, required = false,
                                 default = nil)
  if valid_601548 != nil:
    section.add "Tier.Name", valid_601548
  var valid_601549 = query.getOrDefault("VersionLabel")
  valid_601549 = validateParameter(valid_601549, JString, required = false,
                                 default = nil)
  if valid_601549 != nil:
    section.add "VersionLabel", valid_601549
  var valid_601550 = query.getOrDefault("ApplicationName")
  valid_601550 = validateParameter(valid_601550, JString, required = false,
                                 default = nil)
  if valid_601550 != nil:
    section.add "ApplicationName", valid_601550
  var valid_601551 = query.getOrDefault("Description")
  valid_601551 = validateParameter(valid_601551, JString, required = false,
                                 default = nil)
  if valid_601551 != nil:
    section.add "Description", valid_601551
  var valid_601552 = query.getOrDefault("OptionsToRemove")
  valid_601552 = validateParameter(valid_601552, JArray, required = false,
                                 default = nil)
  if valid_601552 != nil:
    section.add "OptionsToRemove", valid_601552
  var valid_601553 = query.getOrDefault("PlatformArn")
  valid_601553 = validateParameter(valid_601553, JString, required = false,
                                 default = nil)
  if valid_601553 != nil:
    section.add "PlatformArn", valid_601553
  var valid_601554 = query.getOrDefault("EnvironmentName")
  valid_601554 = validateParameter(valid_601554, JString, required = false,
                                 default = nil)
  if valid_601554 != nil:
    section.add "EnvironmentName", valid_601554
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601555 = query.getOrDefault("Action")
  valid_601555 = validateParameter(valid_601555, JString, required = true,
                                 default = newJString("UpdateEnvironment"))
  if valid_601555 != nil:
    section.add "Action", valid_601555
  var valid_601556 = query.getOrDefault("EnvironmentId")
  valid_601556 = validateParameter(valid_601556, JString, required = false,
                                 default = nil)
  if valid_601556 != nil:
    section.add "EnvironmentId", valid_601556
  var valid_601557 = query.getOrDefault("Tier.Version")
  valid_601557 = validateParameter(valid_601557, JString, required = false,
                                 default = nil)
  if valid_601557 != nil:
    section.add "Tier.Version", valid_601557
  var valid_601558 = query.getOrDefault("SolutionStackName")
  valid_601558 = validateParameter(valid_601558, JString, required = false,
                                 default = nil)
  if valid_601558 != nil:
    section.add "SolutionStackName", valid_601558
  var valid_601559 = query.getOrDefault("TemplateName")
  valid_601559 = validateParameter(valid_601559, JString, required = false,
                                 default = nil)
  if valid_601559 != nil:
    section.add "TemplateName", valid_601559
  var valid_601560 = query.getOrDefault("GroupName")
  valid_601560 = validateParameter(valid_601560, JString, required = false,
                                 default = nil)
  if valid_601560 != nil:
    section.add "GroupName", valid_601560
  var valid_601561 = query.getOrDefault("OptionSettings")
  valid_601561 = validateParameter(valid_601561, JArray, required = false,
                                 default = nil)
  if valid_601561 != nil:
    section.add "OptionSettings", valid_601561
  var valid_601562 = query.getOrDefault("Tier.Type")
  valid_601562 = validateParameter(valid_601562, JString, required = false,
                                 default = nil)
  if valid_601562 != nil:
    section.add "Tier.Type", valid_601562
  var valid_601563 = query.getOrDefault("Version")
  valid_601563 = validateParameter(valid_601563, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601563 != nil:
    section.add "Version", valid_601563
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601564 = header.getOrDefault("X-Amz-Date")
  valid_601564 = validateParameter(valid_601564, JString, required = false,
                                 default = nil)
  if valid_601564 != nil:
    section.add "X-Amz-Date", valid_601564
  var valid_601565 = header.getOrDefault("X-Amz-Security-Token")
  valid_601565 = validateParameter(valid_601565, JString, required = false,
                                 default = nil)
  if valid_601565 != nil:
    section.add "X-Amz-Security-Token", valid_601565
  var valid_601566 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601566 = validateParameter(valid_601566, JString, required = false,
                                 default = nil)
  if valid_601566 != nil:
    section.add "X-Amz-Content-Sha256", valid_601566
  var valid_601567 = header.getOrDefault("X-Amz-Algorithm")
  valid_601567 = validateParameter(valid_601567, JString, required = false,
                                 default = nil)
  if valid_601567 != nil:
    section.add "X-Amz-Algorithm", valid_601567
  var valid_601568 = header.getOrDefault("X-Amz-Signature")
  valid_601568 = validateParameter(valid_601568, JString, required = false,
                                 default = nil)
  if valid_601568 != nil:
    section.add "X-Amz-Signature", valid_601568
  var valid_601569 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601569 = validateParameter(valid_601569, JString, required = false,
                                 default = nil)
  if valid_601569 != nil:
    section.add "X-Amz-SignedHeaders", valid_601569
  var valid_601570 = header.getOrDefault("X-Amz-Credential")
  valid_601570 = validateParameter(valid_601570, JString, required = false,
                                 default = nil)
  if valid_601570 != nil:
    section.add "X-Amz-Credential", valid_601570
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601571: Call_GetUpdateEnvironment_601545; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the environment description, deploys a new application version, updates the configuration settings to an entirely new configuration template, or updates select configuration option values in the running environment.</p> <p> Attempting to update both the release and configuration is not allowed and AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. </p> <p> When updating the configuration settings to a new template or individual settings, a draft configuration is created and <a>DescribeConfigurationSettings</a> for this environment returns two setting descriptions with different <code>DeploymentStatus</code> values. </p>
  ## 
  let valid = call_601571.validator(path, query, header, formData, body)
  let scheme = call_601571.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601571.url(scheme.get, call_601571.host, call_601571.base,
                         call_601571.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601571, url, valid)

proc call*(call_601572: Call_GetUpdateEnvironment_601545; TierName: string = "";
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
  var query_601573 = newJObject()
  add(query_601573, "Tier.Name", newJString(TierName))
  add(query_601573, "VersionLabel", newJString(VersionLabel))
  add(query_601573, "ApplicationName", newJString(ApplicationName))
  add(query_601573, "Description", newJString(Description))
  if OptionsToRemove != nil:
    query_601573.add "OptionsToRemove", OptionsToRemove
  add(query_601573, "PlatformArn", newJString(PlatformArn))
  add(query_601573, "EnvironmentName", newJString(EnvironmentName))
  add(query_601573, "Action", newJString(Action))
  add(query_601573, "EnvironmentId", newJString(EnvironmentId))
  add(query_601573, "Tier.Version", newJString(TierVersion))
  add(query_601573, "SolutionStackName", newJString(SolutionStackName))
  add(query_601573, "TemplateName", newJString(TemplateName))
  add(query_601573, "GroupName", newJString(GroupName))
  if OptionSettings != nil:
    query_601573.add "OptionSettings", OptionSettings
  add(query_601573, "Tier.Type", newJString(TierType))
  add(query_601573, "Version", newJString(Version))
  result = call_601572.call(nil, query_601573, nil, nil, nil)

var getUpdateEnvironment* = Call_GetUpdateEnvironment_601545(
    name: "getUpdateEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateEnvironment",
    validator: validate_GetUpdateEnvironment_601546, base: "/",
    url: url_GetUpdateEnvironment_601547, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateTagsForResource_601622 = ref object of OpenApiRestCall_599369
proc url_PostUpdateTagsForResource_601624(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateTagsForResource_601623(path: JsonNode; query: JsonNode;
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
  var valid_601625 = query.getOrDefault("Action")
  valid_601625 = validateParameter(valid_601625, JString, required = true,
                                 default = newJString("UpdateTagsForResource"))
  if valid_601625 != nil:
    section.add "Action", valid_601625
  var valid_601626 = query.getOrDefault("Version")
  valid_601626 = validateParameter(valid_601626, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601626 != nil:
    section.add "Version", valid_601626
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601627 = header.getOrDefault("X-Amz-Date")
  valid_601627 = validateParameter(valid_601627, JString, required = false,
                                 default = nil)
  if valid_601627 != nil:
    section.add "X-Amz-Date", valid_601627
  var valid_601628 = header.getOrDefault("X-Amz-Security-Token")
  valid_601628 = validateParameter(valid_601628, JString, required = false,
                                 default = nil)
  if valid_601628 != nil:
    section.add "X-Amz-Security-Token", valid_601628
  var valid_601629 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601629 = validateParameter(valid_601629, JString, required = false,
                                 default = nil)
  if valid_601629 != nil:
    section.add "X-Amz-Content-Sha256", valid_601629
  var valid_601630 = header.getOrDefault("X-Amz-Algorithm")
  valid_601630 = validateParameter(valid_601630, JString, required = false,
                                 default = nil)
  if valid_601630 != nil:
    section.add "X-Amz-Algorithm", valid_601630
  var valid_601631 = header.getOrDefault("X-Amz-Signature")
  valid_601631 = validateParameter(valid_601631, JString, required = false,
                                 default = nil)
  if valid_601631 != nil:
    section.add "X-Amz-Signature", valid_601631
  var valid_601632 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601632 = validateParameter(valid_601632, JString, required = false,
                                 default = nil)
  if valid_601632 != nil:
    section.add "X-Amz-SignedHeaders", valid_601632
  var valid_601633 = header.getOrDefault("X-Amz-Credential")
  valid_601633 = validateParameter(valid_601633, JString, required = false,
                                 default = nil)
  if valid_601633 != nil:
    section.add "X-Amz-Credential", valid_601633
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagsToAdd: JArray
  ##            : <p>A list of tags to add or update.</p> <p>If a key of an existing tag is added, the tag's value is updated.</p>
  ##   TagsToRemove: JArray
  ##               : <p>A list of tag keys to remove.</p> <p>If a tag key doesn't exist, it is silently ignored.</p>
  ##   ResourceArn: JString (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce to be updated.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  section = newJObject()
  var valid_601634 = formData.getOrDefault("TagsToAdd")
  valid_601634 = validateParameter(valid_601634, JArray, required = false,
                                 default = nil)
  if valid_601634 != nil:
    section.add "TagsToAdd", valid_601634
  var valid_601635 = formData.getOrDefault("TagsToRemove")
  valid_601635 = validateParameter(valid_601635, JArray, required = false,
                                 default = nil)
  if valid_601635 != nil:
    section.add "TagsToRemove", valid_601635
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArn` field"
  var valid_601636 = formData.getOrDefault("ResourceArn")
  valid_601636 = validateParameter(valid_601636, JString, required = true,
                                 default = nil)
  if valid_601636 != nil:
    section.add "ResourceArn", valid_601636
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601637: Call_PostUpdateTagsForResource_601622; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Update the list of tags applied to an AWS Elastic Beanstalk resource. Two lists can be passed: <code>TagsToAdd</code> for tags to add or update, and <code>TagsToRemove</code>.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p> <p>If you create a custom IAM user policy to control permission to this operation, specify one of the following two virtual actions (or both) instead of the API operation name:</p> <dl> <dt>elasticbeanstalk:AddTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tags to add in the <code>TagsToAdd</code> parameter.</p> </dd> <dt>elasticbeanstalk:RemoveTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tag keys to remove in the <code>TagsToRemove</code> parameter.</p> </dd> </dl> <p>For details about creating a custom user policy, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/AWSHowTo.iam.managed-policies.html#AWSHowTo.iam.policies">Creating a Custom User Policy</a>.</p>
  ## 
  let valid = call_601637.validator(path, query, header, formData, body)
  let scheme = call_601637.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601637.url(scheme.get, call_601637.host, call_601637.base,
                         call_601637.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601637, url, valid)

proc call*(call_601638: Call_PostUpdateTagsForResource_601622; ResourceArn: string;
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
  var query_601639 = newJObject()
  var formData_601640 = newJObject()
  if TagsToAdd != nil:
    formData_601640.add "TagsToAdd", TagsToAdd
  if TagsToRemove != nil:
    formData_601640.add "TagsToRemove", TagsToRemove
  add(query_601639, "Action", newJString(Action))
  add(formData_601640, "ResourceArn", newJString(ResourceArn))
  add(query_601639, "Version", newJString(Version))
  result = call_601638.call(nil, query_601639, nil, formData_601640, nil)

var postUpdateTagsForResource* = Call_PostUpdateTagsForResource_601622(
    name: "postUpdateTagsForResource", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateTagsForResource",
    validator: validate_PostUpdateTagsForResource_601623, base: "/",
    url: url_PostUpdateTagsForResource_601624,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateTagsForResource_601604 = ref object of OpenApiRestCall_599369
proc url_GetUpdateTagsForResource_601606(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateTagsForResource_601605(path: JsonNode; query: JsonNode;
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
  var valid_601607 = query.getOrDefault("ResourceArn")
  valid_601607 = validateParameter(valid_601607, JString, required = true,
                                 default = nil)
  if valid_601607 != nil:
    section.add "ResourceArn", valid_601607
  var valid_601608 = query.getOrDefault("Action")
  valid_601608 = validateParameter(valid_601608, JString, required = true,
                                 default = newJString("UpdateTagsForResource"))
  if valid_601608 != nil:
    section.add "Action", valid_601608
  var valid_601609 = query.getOrDefault("TagsToAdd")
  valid_601609 = validateParameter(valid_601609, JArray, required = false,
                                 default = nil)
  if valid_601609 != nil:
    section.add "TagsToAdd", valid_601609
  var valid_601610 = query.getOrDefault("Version")
  valid_601610 = validateParameter(valid_601610, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601610 != nil:
    section.add "Version", valid_601610
  var valid_601611 = query.getOrDefault("TagsToRemove")
  valid_601611 = validateParameter(valid_601611, JArray, required = false,
                                 default = nil)
  if valid_601611 != nil:
    section.add "TagsToRemove", valid_601611
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601612 = header.getOrDefault("X-Amz-Date")
  valid_601612 = validateParameter(valid_601612, JString, required = false,
                                 default = nil)
  if valid_601612 != nil:
    section.add "X-Amz-Date", valid_601612
  var valid_601613 = header.getOrDefault("X-Amz-Security-Token")
  valid_601613 = validateParameter(valid_601613, JString, required = false,
                                 default = nil)
  if valid_601613 != nil:
    section.add "X-Amz-Security-Token", valid_601613
  var valid_601614 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601614 = validateParameter(valid_601614, JString, required = false,
                                 default = nil)
  if valid_601614 != nil:
    section.add "X-Amz-Content-Sha256", valid_601614
  var valid_601615 = header.getOrDefault("X-Amz-Algorithm")
  valid_601615 = validateParameter(valid_601615, JString, required = false,
                                 default = nil)
  if valid_601615 != nil:
    section.add "X-Amz-Algorithm", valid_601615
  var valid_601616 = header.getOrDefault("X-Amz-Signature")
  valid_601616 = validateParameter(valid_601616, JString, required = false,
                                 default = nil)
  if valid_601616 != nil:
    section.add "X-Amz-Signature", valid_601616
  var valid_601617 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601617 = validateParameter(valid_601617, JString, required = false,
                                 default = nil)
  if valid_601617 != nil:
    section.add "X-Amz-SignedHeaders", valid_601617
  var valid_601618 = header.getOrDefault("X-Amz-Credential")
  valid_601618 = validateParameter(valid_601618, JString, required = false,
                                 default = nil)
  if valid_601618 != nil:
    section.add "X-Amz-Credential", valid_601618
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601619: Call_GetUpdateTagsForResource_601604; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Update the list of tags applied to an AWS Elastic Beanstalk resource. Two lists can be passed: <code>TagsToAdd</code> for tags to add or update, and <code>TagsToRemove</code>.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p> <p>If you create a custom IAM user policy to control permission to this operation, specify one of the following two virtual actions (or both) instead of the API operation name:</p> <dl> <dt>elasticbeanstalk:AddTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tags to add in the <code>TagsToAdd</code> parameter.</p> </dd> <dt>elasticbeanstalk:RemoveTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tag keys to remove in the <code>TagsToRemove</code> parameter.</p> </dd> </dl> <p>For details about creating a custom user policy, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/AWSHowTo.iam.managed-policies.html#AWSHowTo.iam.policies">Creating a Custom User Policy</a>.</p>
  ## 
  let valid = call_601619.validator(path, query, header, formData, body)
  let scheme = call_601619.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601619.url(scheme.get, call_601619.host, call_601619.base,
                         call_601619.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601619, url, valid)

proc call*(call_601620: Call_GetUpdateTagsForResource_601604; ResourceArn: string;
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
  var query_601621 = newJObject()
  add(query_601621, "ResourceArn", newJString(ResourceArn))
  add(query_601621, "Action", newJString(Action))
  if TagsToAdd != nil:
    query_601621.add "TagsToAdd", TagsToAdd
  add(query_601621, "Version", newJString(Version))
  if TagsToRemove != nil:
    query_601621.add "TagsToRemove", TagsToRemove
  result = call_601620.call(nil, query_601621, nil, nil, nil)

var getUpdateTagsForResource* = Call_GetUpdateTagsForResource_601604(
    name: "getUpdateTagsForResource", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateTagsForResource",
    validator: validate_GetUpdateTagsForResource_601605, base: "/",
    url: url_GetUpdateTagsForResource_601606, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostValidateConfigurationSettings_601660 = ref object of OpenApiRestCall_599369
proc url_PostValidateConfigurationSettings_601662(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostValidateConfigurationSettings_601661(path: JsonNode;
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
  var valid_601663 = query.getOrDefault("Action")
  valid_601663 = validateParameter(valid_601663, JString, required = true, default = newJString(
      "ValidateConfigurationSettings"))
  if valid_601663 != nil:
    section.add "Action", valid_601663
  var valid_601664 = query.getOrDefault("Version")
  valid_601664 = validateParameter(valid_601664, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601664 != nil:
    section.add "Version", valid_601664
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601665 = header.getOrDefault("X-Amz-Date")
  valid_601665 = validateParameter(valid_601665, JString, required = false,
                                 default = nil)
  if valid_601665 != nil:
    section.add "X-Amz-Date", valid_601665
  var valid_601666 = header.getOrDefault("X-Amz-Security-Token")
  valid_601666 = validateParameter(valid_601666, JString, required = false,
                                 default = nil)
  if valid_601666 != nil:
    section.add "X-Amz-Security-Token", valid_601666
  var valid_601667 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601667 = validateParameter(valid_601667, JString, required = false,
                                 default = nil)
  if valid_601667 != nil:
    section.add "X-Amz-Content-Sha256", valid_601667
  var valid_601668 = header.getOrDefault("X-Amz-Algorithm")
  valid_601668 = validateParameter(valid_601668, JString, required = false,
                                 default = nil)
  if valid_601668 != nil:
    section.add "X-Amz-Algorithm", valid_601668
  var valid_601669 = header.getOrDefault("X-Amz-Signature")
  valid_601669 = validateParameter(valid_601669, JString, required = false,
                                 default = nil)
  if valid_601669 != nil:
    section.add "X-Amz-Signature", valid_601669
  var valid_601670 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601670 = validateParameter(valid_601670, JString, required = false,
                                 default = nil)
  if valid_601670 != nil:
    section.add "X-Amz-SignedHeaders", valid_601670
  var valid_601671 = header.getOrDefault("X-Amz-Credential")
  valid_601671 = validateParameter(valid_601671, JString, required = false,
                                 default = nil)
  if valid_601671 != nil:
    section.add "X-Amz-Credential", valid_601671
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
  var valid_601672 = formData.getOrDefault("OptionSettings")
  valid_601672 = validateParameter(valid_601672, JArray, required = true, default = nil)
  if valid_601672 != nil:
    section.add "OptionSettings", valid_601672
  var valid_601673 = formData.getOrDefault("EnvironmentName")
  valid_601673 = validateParameter(valid_601673, JString, required = false,
                                 default = nil)
  if valid_601673 != nil:
    section.add "EnvironmentName", valid_601673
  var valid_601674 = formData.getOrDefault("ApplicationName")
  valid_601674 = validateParameter(valid_601674, JString, required = true,
                                 default = nil)
  if valid_601674 != nil:
    section.add "ApplicationName", valid_601674
  var valid_601675 = formData.getOrDefault("TemplateName")
  valid_601675 = validateParameter(valid_601675, JString, required = false,
                                 default = nil)
  if valid_601675 != nil:
    section.add "TemplateName", valid_601675
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601676: Call_PostValidateConfigurationSettings_601660;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Takes a set of configuration settings and either a configuration template or environment, and determines whether those values are valid.</p> <p>This action returns a list of messages indicating any errors or warnings associated with the selection of option values.</p>
  ## 
  let valid = call_601676.validator(path, query, header, formData, body)
  let scheme = call_601676.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601676.url(scheme.get, call_601676.host, call_601676.base,
                         call_601676.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601676, url, valid)

proc call*(call_601677: Call_PostValidateConfigurationSettings_601660;
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
  var query_601678 = newJObject()
  var formData_601679 = newJObject()
  if OptionSettings != nil:
    formData_601679.add "OptionSettings", OptionSettings
  add(formData_601679, "EnvironmentName", newJString(EnvironmentName))
  add(query_601678, "Action", newJString(Action))
  add(formData_601679, "ApplicationName", newJString(ApplicationName))
  add(formData_601679, "TemplateName", newJString(TemplateName))
  add(query_601678, "Version", newJString(Version))
  result = call_601677.call(nil, query_601678, nil, formData_601679, nil)

var postValidateConfigurationSettings* = Call_PostValidateConfigurationSettings_601660(
    name: "postValidateConfigurationSettings", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ValidateConfigurationSettings",
    validator: validate_PostValidateConfigurationSettings_601661, base: "/",
    url: url_PostValidateConfigurationSettings_601662,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetValidateConfigurationSettings_601641 = ref object of OpenApiRestCall_599369
proc url_GetValidateConfigurationSettings_601643(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetValidateConfigurationSettings_601642(path: JsonNode;
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
  var valid_601644 = query.getOrDefault("ApplicationName")
  valid_601644 = validateParameter(valid_601644, JString, required = true,
                                 default = nil)
  if valid_601644 != nil:
    section.add "ApplicationName", valid_601644
  var valid_601645 = query.getOrDefault("EnvironmentName")
  valid_601645 = validateParameter(valid_601645, JString, required = false,
                                 default = nil)
  if valid_601645 != nil:
    section.add "EnvironmentName", valid_601645
  var valid_601646 = query.getOrDefault("Action")
  valid_601646 = validateParameter(valid_601646, JString, required = true, default = newJString(
      "ValidateConfigurationSettings"))
  if valid_601646 != nil:
    section.add "Action", valid_601646
  var valid_601647 = query.getOrDefault("TemplateName")
  valid_601647 = validateParameter(valid_601647, JString, required = false,
                                 default = nil)
  if valid_601647 != nil:
    section.add "TemplateName", valid_601647
  var valid_601648 = query.getOrDefault("OptionSettings")
  valid_601648 = validateParameter(valid_601648, JArray, required = true, default = nil)
  if valid_601648 != nil:
    section.add "OptionSettings", valid_601648
  var valid_601649 = query.getOrDefault("Version")
  valid_601649 = validateParameter(valid_601649, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601649 != nil:
    section.add "Version", valid_601649
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601650 = header.getOrDefault("X-Amz-Date")
  valid_601650 = validateParameter(valid_601650, JString, required = false,
                                 default = nil)
  if valid_601650 != nil:
    section.add "X-Amz-Date", valid_601650
  var valid_601651 = header.getOrDefault("X-Amz-Security-Token")
  valid_601651 = validateParameter(valid_601651, JString, required = false,
                                 default = nil)
  if valid_601651 != nil:
    section.add "X-Amz-Security-Token", valid_601651
  var valid_601652 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601652 = validateParameter(valid_601652, JString, required = false,
                                 default = nil)
  if valid_601652 != nil:
    section.add "X-Amz-Content-Sha256", valid_601652
  var valid_601653 = header.getOrDefault("X-Amz-Algorithm")
  valid_601653 = validateParameter(valid_601653, JString, required = false,
                                 default = nil)
  if valid_601653 != nil:
    section.add "X-Amz-Algorithm", valid_601653
  var valid_601654 = header.getOrDefault("X-Amz-Signature")
  valid_601654 = validateParameter(valid_601654, JString, required = false,
                                 default = nil)
  if valid_601654 != nil:
    section.add "X-Amz-Signature", valid_601654
  var valid_601655 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601655 = validateParameter(valid_601655, JString, required = false,
                                 default = nil)
  if valid_601655 != nil:
    section.add "X-Amz-SignedHeaders", valid_601655
  var valid_601656 = header.getOrDefault("X-Amz-Credential")
  valid_601656 = validateParameter(valid_601656, JString, required = false,
                                 default = nil)
  if valid_601656 != nil:
    section.add "X-Amz-Credential", valid_601656
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601657: Call_GetValidateConfigurationSettings_601641;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Takes a set of configuration settings and either a configuration template or environment, and determines whether those values are valid.</p> <p>This action returns a list of messages indicating any errors or warnings associated with the selection of option values.</p>
  ## 
  let valid = call_601657.validator(path, query, header, formData, body)
  let scheme = call_601657.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601657.url(scheme.get, call_601657.host, call_601657.base,
                         call_601657.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601657, url, valid)

proc call*(call_601658: Call_GetValidateConfigurationSettings_601641;
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
  var query_601659 = newJObject()
  add(query_601659, "ApplicationName", newJString(ApplicationName))
  add(query_601659, "EnvironmentName", newJString(EnvironmentName))
  add(query_601659, "Action", newJString(Action))
  add(query_601659, "TemplateName", newJString(TemplateName))
  if OptionSettings != nil:
    query_601659.add "OptionSettings", OptionSettings
  add(query_601659, "Version", newJString(Version))
  result = call_601658.call(nil, query_601659, nil, nil, nil)

var getValidateConfigurationSettings* = Call_GetValidateConfigurationSettings_601641(
    name: "getValidateConfigurationSettings", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ValidateConfigurationSettings",
    validator: validate_GetValidateConfigurationSettings_601642, base: "/",
    url: url_GetValidateConfigurationSettings_601643,
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
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)

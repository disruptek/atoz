
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

  OpenApiRestCall_592365 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592365](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592365): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostAbortEnvironmentUpdate_592976 = ref object of OpenApiRestCall_592365
proc url_PostAbortEnvironmentUpdate_592978(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostAbortEnvironmentUpdate_592977(path: JsonNode; query: JsonNode;
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
  var valid_592979 = query.getOrDefault("Action")
  valid_592979 = validateParameter(valid_592979, JString, required = true,
                                 default = newJString("AbortEnvironmentUpdate"))
  if valid_592979 != nil:
    section.add "Action", valid_592979
  var valid_592980 = query.getOrDefault("Version")
  valid_592980 = validateParameter(valid_592980, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_592980 != nil:
    section.add "Version", valid_592980
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
  var valid_592981 = header.getOrDefault("X-Amz-Signature")
  valid_592981 = validateParameter(valid_592981, JString, required = false,
                                 default = nil)
  if valid_592981 != nil:
    section.add "X-Amz-Signature", valid_592981
  var valid_592982 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592982 = validateParameter(valid_592982, JString, required = false,
                                 default = nil)
  if valid_592982 != nil:
    section.add "X-Amz-Content-Sha256", valid_592982
  var valid_592983 = header.getOrDefault("X-Amz-Date")
  valid_592983 = validateParameter(valid_592983, JString, required = false,
                                 default = nil)
  if valid_592983 != nil:
    section.add "X-Amz-Date", valid_592983
  var valid_592984 = header.getOrDefault("X-Amz-Credential")
  valid_592984 = validateParameter(valid_592984, JString, required = false,
                                 default = nil)
  if valid_592984 != nil:
    section.add "X-Amz-Credential", valid_592984
  var valid_592985 = header.getOrDefault("X-Amz-Security-Token")
  valid_592985 = validateParameter(valid_592985, JString, required = false,
                                 default = nil)
  if valid_592985 != nil:
    section.add "X-Amz-Security-Token", valid_592985
  var valid_592986 = header.getOrDefault("X-Amz-Algorithm")
  valid_592986 = validateParameter(valid_592986, JString, required = false,
                                 default = nil)
  if valid_592986 != nil:
    section.add "X-Amz-Algorithm", valid_592986
  var valid_592987 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592987 = validateParameter(valid_592987, JString, required = false,
                                 default = nil)
  if valid_592987 != nil:
    section.add "X-Amz-SignedHeaders", valid_592987
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString
  ##                  : This specifies the name of the environment with the in-progress update that you want to cancel.
  ##   EnvironmentId: JString
  ##                : This specifies the ID of the environment with the in-progress update that you want to cancel.
  section = newJObject()
  var valid_592988 = formData.getOrDefault("EnvironmentName")
  valid_592988 = validateParameter(valid_592988, JString, required = false,
                                 default = nil)
  if valid_592988 != nil:
    section.add "EnvironmentName", valid_592988
  var valid_592989 = formData.getOrDefault("EnvironmentId")
  valid_592989 = validateParameter(valid_592989, JString, required = false,
                                 default = nil)
  if valid_592989 != nil:
    section.add "EnvironmentId", valid_592989
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592990: Call_PostAbortEnvironmentUpdate_592976; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels in-progress environment configuration update or application version deployment.
  ## 
  let valid = call_592990.validator(path, query, header, formData, body)
  let scheme = call_592990.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592990.url(scheme.get, call_592990.host, call_592990.base,
                         call_592990.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592990, url, valid)

proc call*(call_592991: Call_PostAbortEnvironmentUpdate_592976;
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
  var query_592992 = newJObject()
  var formData_592993 = newJObject()
  add(formData_592993, "EnvironmentName", newJString(EnvironmentName))
  add(query_592992, "Action", newJString(Action))
  add(formData_592993, "EnvironmentId", newJString(EnvironmentId))
  add(query_592992, "Version", newJString(Version))
  result = call_592991.call(nil, query_592992, nil, formData_592993, nil)

var postAbortEnvironmentUpdate* = Call_PostAbortEnvironmentUpdate_592976(
    name: "postAbortEnvironmentUpdate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=AbortEnvironmentUpdate",
    validator: validate_PostAbortEnvironmentUpdate_592977, base: "/",
    url: url_PostAbortEnvironmentUpdate_592978,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAbortEnvironmentUpdate_592704 = ref object of OpenApiRestCall_592365
proc url_GetAbortEnvironmentUpdate_592706(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAbortEnvironmentUpdate_592705(path: JsonNode; query: JsonNode;
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
  var valid_592818 = query.getOrDefault("EnvironmentName")
  valid_592818 = validateParameter(valid_592818, JString, required = false,
                                 default = nil)
  if valid_592818 != nil:
    section.add "EnvironmentName", valid_592818
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_592832 = query.getOrDefault("Action")
  valid_592832 = validateParameter(valid_592832, JString, required = true,
                                 default = newJString("AbortEnvironmentUpdate"))
  if valid_592832 != nil:
    section.add "Action", valid_592832
  var valid_592833 = query.getOrDefault("Version")
  valid_592833 = validateParameter(valid_592833, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_592833 != nil:
    section.add "Version", valid_592833
  var valid_592834 = query.getOrDefault("EnvironmentId")
  valid_592834 = validateParameter(valid_592834, JString, required = false,
                                 default = nil)
  if valid_592834 != nil:
    section.add "EnvironmentId", valid_592834
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
  var valid_592835 = header.getOrDefault("X-Amz-Signature")
  valid_592835 = validateParameter(valid_592835, JString, required = false,
                                 default = nil)
  if valid_592835 != nil:
    section.add "X-Amz-Signature", valid_592835
  var valid_592836 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592836 = validateParameter(valid_592836, JString, required = false,
                                 default = nil)
  if valid_592836 != nil:
    section.add "X-Amz-Content-Sha256", valid_592836
  var valid_592837 = header.getOrDefault("X-Amz-Date")
  valid_592837 = validateParameter(valid_592837, JString, required = false,
                                 default = nil)
  if valid_592837 != nil:
    section.add "X-Amz-Date", valid_592837
  var valid_592838 = header.getOrDefault("X-Amz-Credential")
  valid_592838 = validateParameter(valid_592838, JString, required = false,
                                 default = nil)
  if valid_592838 != nil:
    section.add "X-Amz-Credential", valid_592838
  var valid_592839 = header.getOrDefault("X-Amz-Security-Token")
  valid_592839 = validateParameter(valid_592839, JString, required = false,
                                 default = nil)
  if valid_592839 != nil:
    section.add "X-Amz-Security-Token", valid_592839
  var valid_592840 = header.getOrDefault("X-Amz-Algorithm")
  valid_592840 = validateParameter(valid_592840, JString, required = false,
                                 default = nil)
  if valid_592840 != nil:
    section.add "X-Amz-Algorithm", valid_592840
  var valid_592841 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592841 = validateParameter(valid_592841, JString, required = false,
                                 default = nil)
  if valid_592841 != nil:
    section.add "X-Amz-SignedHeaders", valid_592841
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592864: Call_GetAbortEnvironmentUpdate_592704; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels in-progress environment configuration update or application version deployment.
  ## 
  let valid = call_592864.validator(path, query, header, formData, body)
  let scheme = call_592864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592864.url(scheme.get, call_592864.host, call_592864.base,
                         call_592864.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592864, url, valid)

proc call*(call_592935: Call_GetAbortEnvironmentUpdate_592704;
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
  var query_592936 = newJObject()
  add(query_592936, "EnvironmentName", newJString(EnvironmentName))
  add(query_592936, "Action", newJString(Action))
  add(query_592936, "Version", newJString(Version))
  add(query_592936, "EnvironmentId", newJString(EnvironmentId))
  result = call_592935.call(nil, query_592936, nil, nil, nil)

var getAbortEnvironmentUpdate* = Call_GetAbortEnvironmentUpdate_592704(
    name: "getAbortEnvironmentUpdate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=AbortEnvironmentUpdate",
    validator: validate_GetAbortEnvironmentUpdate_592705, base: "/",
    url: url_GetAbortEnvironmentUpdate_592706,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostApplyEnvironmentManagedAction_593012 = ref object of OpenApiRestCall_592365
proc url_PostApplyEnvironmentManagedAction_593014(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostApplyEnvironmentManagedAction_593013(path: JsonNode;
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
  var valid_593015 = query.getOrDefault("Action")
  valid_593015 = validateParameter(valid_593015, JString, required = true, default = newJString(
      "ApplyEnvironmentManagedAction"))
  if valid_593015 != nil:
    section.add "Action", valid_593015
  var valid_593016 = query.getOrDefault("Version")
  valid_593016 = validateParameter(valid_593016, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593016 != nil:
    section.add "Version", valid_593016
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
  var valid_593017 = header.getOrDefault("X-Amz-Signature")
  valid_593017 = validateParameter(valid_593017, JString, required = false,
                                 default = nil)
  if valid_593017 != nil:
    section.add "X-Amz-Signature", valid_593017
  var valid_593018 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593018 = validateParameter(valid_593018, JString, required = false,
                                 default = nil)
  if valid_593018 != nil:
    section.add "X-Amz-Content-Sha256", valid_593018
  var valid_593019 = header.getOrDefault("X-Amz-Date")
  valid_593019 = validateParameter(valid_593019, JString, required = false,
                                 default = nil)
  if valid_593019 != nil:
    section.add "X-Amz-Date", valid_593019
  var valid_593020 = header.getOrDefault("X-Amz-Credential")
  valid_593020 = validateParameter(valid_593020, JString, required = false,
                                 default = nil)
  if valid_593020 != nil:
    section.add "X-Amz-Credential", valid_593020
  var valid_593021 = header.getOrDefault("X-Amz-Security-Token")
  valid_593021 = validateParameter(valid_593021, JString, required = false,
                                 default = nil)
  if valid_593021 != nil:
    section.add "X-Amz-Security-Token", valid_593021
  var valid_593022 = header.getOrDefault("X-Amz-Algorithm")
  valid_593022 = validateParameter(valid_593022, JString, required = false,
                                 default = nil)
  if valid_593022 != nil:
    section.add "X-Amz-Algorithm", valid_593022
  var valid_593023 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593023 = validateParameter(valid_593023, JString, required = false,
                                 default = nil)
  if valid_593023 != nil:
    section.add "X-Amz-SignedHeaders", valid_593023
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
  var valid_593024 = formData.getOrDefault("ActionId")
  valid_593024 = validateParameter(valid_593024, JString, required = true,
                                 default = nil)
  if valid_593024 != nil:
    section.add "ActionId", valid_593024
  var valid_593025 = formData.getOrDefault("EnvironmentName")
  valid_593025 = validateParameter(valid_593025, JString, required = false,
                                 default = nil)
  if valid_593025 != nil:
    section.add "EnvironmentName", valid_593025
  var valid_593026 = formData.getOrDefault("EnvironmentId")
  valid_593026 = validateParameter(valid_593026, JString, required = false,
                                 default = nil)
  if valid_593026 != nil:
    section.add "EnvironmentId", valid_593026
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593027: Call_PostApplyEnvironmentManagedAction_593012;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Applies a scheduled managed action immediately. A managed action can be applied only if its status is <code>Scheduled</code>. Get the status and action ID of a managed action with <a>DescribeEnvironmentManagedActions</a>.
  ## 
  let valid = call_593027.validator(path, query, header, formData, body)
  let scheme = call_593027.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593027.url(scheme.get, call_593027.host, call_593027.base,
                         call_593027.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593027, url, valid)

proc call*(call_593028: Call_PostApplyEnvironmentManagedAction_593012;
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
  var query_593029 = newJObject()
  var formData_593030 = newJObject()
  add(formData_593030, "ActionId", newJString(ActionId))
  add(formData_593030, "EnvironmentName", newJString(EnvironmentName))
  add(query_593029, "Action", newJString(Action))
  add(formData_593030, "EnvironmentId", newJString(EnvironmentId))
  add(query_593029, "Version", newJString(Version))
  result = call_593028.call(nil, query_593029, nil, formData_593030, nil)

var postApplyEnvironmentManagedAction* = Call_PostApplyEnvironmentManagedAction_593012(
    name: "postApplyEnvironmentManagedAction", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ApplyEnvironmentManagedAction",
    validator: validate_PostApplyEnvironmentManagedAction_593013, base: "/",
    url: url_PostApplyEnvironmentManagedAction_593014,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplyEnvironmentManagedAction_592994 = ref object of OpenApiRestCall_592365
proc url_GetApplyEnvironmentManagedAction_592996(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetApplyEnvironmentManagedAction_592995(path: JsonNode;
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
  var valid_592997 = query.getOrDefault("ActionId")
  valid_592997 = validateParameter(valid_592997, JString, required = true,
                                 default = nil)
  if valid_592997 != nil:
    section.add "ActionId", valid_592997
  var valid_592998 = query.getOrDefault("EnvironmentName")
  valid_592998 = validateParameter(valid_592998, JString, required = false,
                                 default = nil)
  if valid_592998 != nil:
    section.add "EnvironmentName", valid_592998
  var valid_592999 = query.getOrDefault("Action")
  valid_592999 = validateParameter(valid_592999, JString, required = true, default = newJString(
      "ApplyEnvironmentManagedAction"))
  if valid_592999 != nil:
    section.add "Action", valid_592999
  var valid_593000 = query.getOrDefault("Version")
  valid_593000 = validateParameter(valid_593000, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593000 != nil:
    section.add "Version", valid_593000
  var valid_593001 = query.getOrDefault("EnvironmentId")
  valid_593001 = validateParameter(valid_593001, JString, required = false,
                                 default = nil)
  if valid_593001 != nil:
    section.add "EnvironmentId", valid_593001
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
  var valid_593002 = header.getOrDefault("X-Amz-Signature")
  valid_593002 = validateParameter(valid_593002, JString, required = false,
                                 default = nil)
  if valid_593002 != nil:
    section.add "X-Amz-Signature", valid_593002
  var valid_593003 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593003 = validateParameter(valid_593003, JString, required = false,
                                 default = nil)
  if valid_593003 != nil:
    section.add "X-Amz-Content-Sha256", valid_593003
  var valid_593004 = header.getOrDefault("X-Amz-Date")
  valid_593004 = validateParameter(valid_593004, JString, required = false,
                                 default = nil)
  if valid_593004 != nil:
    section.add "X-Amz-Date", valid_593004
  var valid_593005 = header.getOrDefault("X-Amz-Credential")
  valid_593005 = validateParameter(valid_593005, JString, required = false,
                                 default = nil)
  if valid_593005 != nil:
    section.add "X-Amz-Credential", valid_593005
  var valid_593006 = header.getOrDefault("X-Amz-Security-Token")
  valid_593006 = validateParameter(valid_593006, JString, required = false,
                                 default = nil)
  if valid_593006 != nil:
    section.add "X-Amz-Security-Token", valid_593006
  var valid_593007 = header.getOrDefault("X-Amz-Algorithm")
  valid_593007 = validateParameter(valid_593007, JString, required = false,
                                 default = nil)
  if valid_593007 != nil:
    section.add "X-Amz-Algorithm", valid_593007
  var valid_593008 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593008 = validateParameter(valid_593008, JString, required = false,
                                 default = nil)
  if valid_593008 != nil:
    section.add "X-Amz-SignedHeaders", valid_593008
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593009: Call_GetApplyEnvironmentManagedAction_592994;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Applies a scheduled managed action immediately. A managed action can be applied only if its status is <code>Scheduled</code>. Get the status and action ID of a managed action with <a>DescribeEnvironmentManagedActions</a>.
  ## 
  let valid = call_593009.validator(path, query, header, formData, body)
  let scheme = call_593009.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593009.url(scheme.get, call_593009.host, call_593009.base,
                         call_593009.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593009, url, valid)

proc call*(call_593010: Call_GetApplyEnvironmentManagedAction_592994;
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
  var query_593011 = newJObject()
  add(query_593011, "ActionId", newJString(ActionId))
  add(query_593011, "EnvironmentName", newJString(EnvironmentName))
  add(query_593011, "Action", newJString(Action))
  add(query_593011, "Version", newJString(Version))
  add(query_593011, "EnvironmentId", newJString(EnvironmentId))
  result = call_593010.call(nil, query_593011, nil, nil, nil)

var getApplyEnvironmentManagedAction* = Call_GetApplyEnvironmentManagedAction_592994(
    name: "getApplyEnvironmentManagedAction", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ApplyEnvironmentManagedAction",
    validator: validate_GetApplyEnvironmentManagedAction_592995, base: "/",
    url: url_GetApplyEnvironmentManagedAction_592996,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCheckDNSAvailability_593047 = ref object of OpenApiRestCall_592365
proc url_PostCheckDNSAvailability_593049(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCheckDNSAvailability_593048(path: JsonNode; query: JsonNode;
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
  var valid_593050 = query.getOrDefault("Action")
  valid_593050 = validateParameter(valid_593050, JString, required = true,
                                 default = newJString("CheckDNSAvailability"))
  if valid_593050 != nil:
    section.add "Action", valid_593050
  var valid_593051 = query.getOrDefault("Version")
  valid_593051 = validateParameter(valid_593051, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593051 != nil:
    section.add "Version", valid_593051
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
  var valid_593052 = header.getOrDefault("X-Amz-Signature")
  valid_593052 = validateParameter(valid_593052, JString, required = false,
                                 default = nil)
  if valid_593052 != nil:
    section.add "X-Amz-Signature", valid_593052
  var valid_593053 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593053 = validateParameter(valid_593053, JString, required = false,
                                 default = nil)
  if valid_593053 != nil:
    section.add "X-Amz-Content-Sha256", valid_593053
  var valid_593054 = header.getOrDefault("X-Amz-Date")
  valid_593054 = validateParameter(valid_593054, JString, required = false,
                                 default = nil)
  if valid_593054 != nil:
    section.add "X-Amz-Date", valid_593054
  var valid_593055 = header.getOrDefault("X-Amz-Credential")
  valid_593055 = validateParameter(valid_593055, JString, required = false,
                                 default = nil)
  if valid_593055 != nil:
    section.add "X-Amz-Credential", valid_593055
  var valid_593056 = header.getOrDefault("X-Amz-Security-Token")
  valid_593056 = validateParameter(valid_593056, JString, required = false,
                                 default = nil)
  if valid_593056 != nil:
    section.add "X-Amz-Security-Token", valid_593056
  var valid_593057 = header.getOrDefault("X-Amz-Algorithm")
  valid_593057 = validateParameter(valid_593057, JString, required = false,
                                 default = nil)
  if valid_593057 != nil:
    section.add "X-Amz-Algorithm", valid_593057
  var valid_593058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593058 = validateParameter(valid_593058, JString, required = false,
                                 default = nil)
  if valid_593058 != nil:
    section.add "X-Amz-SignedHeaders", valid_593058
  result.add "header", section
  ## parameters in `formData` object:
  ##   CNAMEPrefix: JString (required)
  ##              : The prefix used when this CNAME is reserved.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `CNAMEPrefix` field"
  var valid_593059 = formData.getOrDefault("CNAMEPrefix")
  valid_593059 = validateParameter(valid_593059, JString, required = true,
                                 default = nil)
  if valid_593059 != nil:
    section.add "CNAMEPrefix", valid_593059
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593060: Call_PostCheckDNSAvailability_593047; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Checks if the specified CNAME is available.
  ## 
  let valid = call_593060.validator(path, query, header, formData, body)
  let scheme = call_593060.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593060.url(scheme.get, call_593060.host, call_593060.base,
                         call_593060.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593060, url, valid)

proc call*(call_593061: Call_PostCheckDNSAvailability_593047; CNAMEPrefix: string;
          Action: string = "CheckDNSAvailability"; Version: string = "2010-12-01"): Recallable =
  ## postCheckDNSAvailability
  ## Checks if the specified CNAME is available.
  ##   CNAMEPrefix: string (required)
  ##              : The prefix used when this CNAME is reserved.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593062 = newJObject()
  var formData_593063 = newJObject()
  add(formData_593063, "CNAMEPrefix", newJString(CNAMEPrefix))
  add(query_593062, "Action", newJString(Action))
  add(query_593062, "Version", newJString(Version))
  result = call_593061.call(nil, query_593062, nil, formData_593063, nil)

var postCheckDNSAvailability* = Call_PostCheckDNSAvailability_593047(
    name: "postCheckDNSAvailability", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CheckDNSAvailability",
    validator: validate_PostCheckDNSAvailability_593048, base: "/",
    url: url_PostCheckDNSAvailability_593049, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCheckDNSAvailability_593031 = ref object of OpenApiRestCall_592365
proc url_GetCheckDNSAvailability_593033(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCheckDNSAvailability_593032(path: JsonNode; query: JsonNode;
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
  var valid_593034 = query.getOrDefault("CNAMEPrefix")
  valid_593034 = validateParameter(valid_593034, JString, required = true,
                                 default = nil)
  if valid_593034 != nil:
    section.add "CNAMEPrefix", valid_593034
  var valid_593035 = query.getOrDefault("Action")
  valid_593035 = validateParameter(valid_593035, JString, required = true,
                                 default = newJString("CheckDNSAvailability"))
  if valid_593035 != nil:
    section.add "Action", valid_593035
  var valid_593036 = query.getOrDefault("Version")
  valid_593036 = validateParameter(valid_593036, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593036 != nil:
    section.add "Version", valid_593036
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
  var valid_593037 = header.getOrDefault("X-Amz-Signature")
  valid_593037 = validateParameter(valid_593037, JString, required = false,
                                 default = nil)
  if valid_593037 != nil:
    section.add "X-Amz-Signature", valid_593037
  var valid_593038 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593038 = validateParameter(valid_593038, JString, required = false,
                                 default = nil)
  if valid_593038 != nil:
    section.add "X-Amz-Content-Sha256", valid_593038
  var valid_593039 = header.getOrDefault("X-Amz-Date")
  valid_593039 = validateParameter(valid_593039, JString, required = false,
                                 default = nil)
  if valid_593039 != nil:
    section.add "X-Amz-Date", valid_593039
  var valid_593040 = header.getOrDefault("X-Amz-Credential")
  valid_593040 = validateParameter(valid_593040, JString, required = false,
                                 default = nil)
  if valid_593040 != nil:
    section.add "X-Amz-Credential", valid_593040
  var valid_593041 = header.getOrDefault("X-Amz-Security-Token")
  valid_593041 = validateParameter(valid_593041, JString, required = false,
                                 default = nil)
  if valid_593041 != nil:
    section.add "X-Amz-Security-Token", valid_593041
  var valid_593042 = header.getOrDefault("X-Amz-Algorithm")
  valid_593042 = validateParameter(valid_593042, JString, required = false,
                                 default = nil)
  if valid_593042 != nil:
    section.add "X-Amz-Algorithm", valid_593042
  var valid_593043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593043 = validateParameter(valid_593043, JString, required = false,
                                 default = nil)
  if valid_593043 != nil:
    section.add "X-Amz-SignedHeaders", valid_593043
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593044: Call_GetCheckDNSAvailability_593031; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Checks if the specified CNAME is available.
  ## 
  let valid = call_593044.validator(path, query, header, formData, body)
  let scheme = call_593044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593044.url(scheme.get, call_593044.host, call_593044.base,
                         call_593044.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593044, url, valid)

proc call*(call_593045: Call_GetCheckDNSAvailability_593031; CNAMEPrefix: string;
          Action: string = "CheckDNSAvailability"; Version: string = "2010-12-01"): Recallable =
  ## getCheckDNSAvailability
  ## Checks if the specified CNAME is available.
  ##   CNAMEPrefix: string (required)
  ##              : The prefix used when this CNAME is reserved.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593046 = newJObject()
  add(query_593046, "CNAMEPrefix", newJString(CNAMEPrefix))
  add(query_593046, "Action", newJString(Action))
  add(query_593046, "Version", newJString(Version))
  result = call_593045.call(nil, query_593046, nil, nil, nil)

var getCheckDNSAvailability* = Call_GetCheckDNSAvailability_593031(
    name: "getCheckDNSAvailability", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CheckDNSAvailability",
    validator: validate_GetCheckDNSAvailability_593032, base: "/",
    url: url_GetCheckDNSAvailability_593033, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostComposeEnvironments_593082 = ref object of OpenApiRestCall_592365
proc url_PostComposeEnvironments_593084(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostComposeEnvironments_593083(path: JsonNode; query: JsonNode;
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
  var valid_593085 = query.getOrDefault("Action")
  valid_593085 = validateParameter(valid_593085, JString, required = true,
                                 default = newJString("ComposeEnvironments"))
  if valid_593085 != nil:
    section.add "Action", valid_593085
  var valid_593086 = query.getOrDefault("Version")
  valid_593086 = validateParameter(valid_593086, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593086 != nil:
    section.add "Version", valid_593086
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
  var valid_593087 = header.getOrDefault("X-Amz-Signature")
  valid_593087 = validateParameter(valid_593087, JString, required = false,
                                 default = nil)
  if valid_593087 != nil:
    section.add "X-Amz-Signature", valid_593087
  var valid_593088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593088 = validateParameter(valid_593088, JString, required = false,
                                 default = nil)
  if valid_593088 != nil:
    section.add "X-Amz-Content-Sha256", valid_593088
  var valid_593089 = header.getOrDefault("X-Amz-Date")
  valid_593089 = validateParameter(valid_593089, JString, required = false,
                                 default = nil)
  if valid_593089 != nil:
    section.add "X-Amz-Date", valid_593089
  var valid_593090 = header.getOrDefault("X-Amz-Credential")
  valid_593090 = validateParameter(valid_593090, JString, required = false,
                                 default = nil)
  if valid_593090 != nil:
    section.add "X-Amz-Credential", valid_593090
  var valid_593091 = header.getOrDefault("X-Amz-Security-Token")
  valid_593091 = validateParameter(valid_593091, JString, required = false,
                                 default = nil)
  if valid_593091 != nil:
    section.add "X-Amz-Security-Token", valid_593091
  var valid_593092 = header.getOrDefault("X-Amz-Algorithm")
  valid_593092 = validateParameter(valid_593092, JString, required = false,
                                 default = nil)
  if valid_593092 != nil:
    section.add "X-Amz-Algorithm", valid_593092
  var valid_593093 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593093 = validateParameter(valid_593093, JString, required = false,
                                 default = nil)
  if valid_593093 != nil:
    section.add "X-Amz-SignedHeaders", valid_593093
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
  var valid_593094 = formData.getOrDefault("GroupName")
  valid_593094 = validateParameter(valid_593094, JString, required = false,
                                 default = nil)
  if valid_593094 != nil:
    section.add "GroupName", valid_593094
  var valid_593095 = formData.getOrDefault("ApplicationName")
  valid_593095 = validateParameter(valid_593095, JString, required = false,
                                 default = nil)
  if valid_593095 != nil:
    section.add "ApplicationName", valid_593095
  var valid_593096 = formData.getOrDefault("VersionLabels")
  valid_593096 = validateParameter(valid_593096, JArray, required = false,
                                 default = nil)
  if valid_593096 != nil:
    section.add "VersionLabels", valid_593096
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593097: Call_PostComposeEnvironments_593082; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create or update a group of environments that each run a separate component of a single application. Takes a list of version labels that specify application source bundles for each of the environments to create or update. The name of each environment and other required information must be included in the source bundles in an environment manifest named <code>env.yaml</code>. See <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-mgmt-compose.html">Compose Environments</a> for details.
  ## 
  let valid = call_593097.validator(path, query, header, formData, body)
  let scheme = call_593097.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593097.url(scheme.get, call_593097.host, call_593097.base,
                         call_593097.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593097, url, valid)

proc call*(call_593098: Call_PostComposeEnvironments_593082;
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
  var query_593099 = newJObject()
  var formData_593100 = newJObject()
  add(formData_593100, "GroupName", newJString(GroupName))
  add(formData_593100, "ApplicationName", newJString(ApplicationName))
  if VersionLabels != nil:
    formData_593100.add "VersionLabels", VersionLabels
  add(query_593099, "Action", newJString(Action))
  add(query_593099, "Version", newJString(Version))
  result = call_593098.call(nil, query_593099, nil, formData_593100, nil)

var postComposeEnvironments* = Call_PostComposeEnvironments_593082(
    name: "postComposeEnvironments", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ComposeEnvironments",
    validator: validate_PostComposeEnvironments_593083, base: "/",
    url: url_PostComposeEnvironments_593084, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetComposeEnvironments_593064 = ref object of OpenApiRestCall_592365
proc url_GetComposeEnvironments_593066(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetComposeEnvironments_593065(path: JsonNode; query: JsonNode;
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
  var valid_593067 = query.getOrDefault("ApplicationName")
  valid_593067 = validateParameter(valid_593067, JString, required = false,
                                 default = nil)
  if valid_593067 != nil:
    section.add "ApplicationName", valid_593067
  var valid_593068 = query.getOrDefault("GroupName")
  valid_593068 = validateParameter(valid_593068, JString, required = false,
                                 default = nil)
  if valid_593068 != nil:
    section.add "GroupName", valid_593068
  var valid_593069 = query.getOrDefault("VersionLabels")
  valid_593069 = validateParameter(valid_593069, JArray, required = false,
                                 default = nil)
  if valid_593069 != nil:
    section.add "VersionLabels", valid_593069
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593070 = query.getOrDefault("Action")
  valid_593070 = validateParameter(valid_593070, JString, required = true,
                                 default = newJString("ComposeEnvironments"))
  if valid_593070 != nil:
    section.add "Action", valid_593070
  var valid_593071 = query.getOrDefault("Version")
  valid_593071 = validateParameter(valid_593071, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593071 != nil:
    section.add "Version", valid_593071
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
  var valid_593072 = header.getOrDefault("X-Amz-Signature")
  valid_593072 = validateParameter(valid_593072, JString, required = false,
                                 default = nil)
  if valid_593072 != nil:
    section.add "X-Amz-Signature", valid_593072
  var valid_593073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593073 = validateParameter(valid_593073, JString, required = false,
                                 default = nil)
  if valid_593073 != nil:
    section.add "X-Amz-Content-Sha256", valid_593073
  var valid_593074 = header.getOrDefault("X-Amz-Date")
  valid_593074 = validateParameter(valid_593074, JString, required = false,
                                 default = nil)
  if valid_593074 != nil:
    section.add "X-Amz-Date", valid_593074
  var valid_593075 = header.getOrDefault("X-Amz-Credential")
  valid_593075 = validateParameter(valid_593075, JString, required = false,
                                 default = nil)
  if valid_593075 != nil:
    section.add "X-Amz-Credential", valid_593075
  var valid_593076 = header.getOrDefault("X-Amz-Security-Token")
  valid_593076 = validateParameter(valid_593076, JString, required = false,
                                 default = nil)
  if valid_593076 != nil:
    section.add "X-Amz-Security-Token", valid_593076
  var valid_593077 = header.getOrDefault("X-Amz-Algorithm")
  valid_593077 = validateParameter(valid_593077, JString, required = false,
                                 default = nil)
  if valid_593077 != nil:
    section.add "X-Amz-Algorithm", valid_593077
  var valid_593078 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593078 = validateParameter(valid_593078, JString, required = false,
                                 default = nil)
  if valid_593078 != nil:
    section.add "X-Amz-SignedHeaders", valid_593078
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593079: Call_GetComposeEnvironments_593064; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create or update a group of environments that each run a separate component of a single application. Takes a list of version labels that specify application source bundles for each of the environments to create or update. The name of each environment and other required information must be included in the source bundles in an environment manifest named <code>env.yaml</code>. See <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-mgmt-compose.html">Compose Environments</a> for details.
  ## 
  let valid = call_593079.validator(path, query, header, formData, body)
  let scheme = call_593079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593079.url(scheme.get, call_593079.host, call_593079.base,
                         call_593079.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593079, url, valid)

proc call*(call_593080: Call_GetComposeEnvironments_593064;
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
  var query_593081 = newJObject()
  add(query_593081, "ApplicationName", newJString(ApplicationName))
  add(query_593081, "GroupName", newJString(GroupName))
  if VersionLabels != nil:
    query_593081.add "VersionLabels", VersionLabels
  add(query_593081, "Action", newJString(Action))
  add(query_593081, "Version", newJString(Version))
  result = call_593080.call(nil, query_593081, nil, nil, nil)

var getComposeEnvironments* = Call_GetComposeEnvironments_593064(
    name: "getComposeEnvironments", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ComposeEnvironments",
    validator: validate_GetComposeEnvironments_593065, base: "/",
    url: url_GetComposeEnvironments_593066, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateApplication_593121 = ref object of OpenApiRestCall_592365
proc url_PostCreateApplication_593123(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateApplication_593122(path: JsonNode; query: JsonNode;
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
  var valid_593124 = query.getOrDefault("Action")
  valid_593124 = validateParameter(valid_593124, JString, required = true,
                                 default = newJString("CreateApplication"))
  if valid_593124 != nil:
    section.add "Action", valid_593124
  var valid_593125 = query.getOrDefault("Version")
  valid_593125 = validateParameter(valid_593125, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593125 != nil:
    section.add "Version", valid_593125
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
  var valid_593126 = header.getOrDefault("X-Amz-Signature")
  valid_593126 = validateParameter(valid_593126, JString, required = false,
                                 default = nil)
  if valid_593126 != nil:
    section.add "X-Amz-Signature", valid_593126
  var valid_593127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593127 = validateParameter(valid_593127, JString, required = false,
                                 default = nil)
  if valid_593127 != nil:
    section.add "X-Amz-Content-Sha256", valid_593127
  var valid_593128 = header.getOrDefault("X-Amz-Date")
  valid_593128 = validateParameter(valid_593128, JString, required = false,
                                 default = nil)
  if valid_593128 != nil:
    section.add "X-Amz-Date", valid_593128
  var valid_593129 = header.getOrDefault("X-Amz-Credential")
  valid_593129 = validateParameter(valid_593129, JString, required = false,
                                 default = nil)
  if valid_593129 != nil:
    section.add "X-Amz-Credential", valid_593129
  var valid_593130 = header.getOrDefault("X-Amz-Security-Token")
  valid_593130 = validateParameter(valid_593130, JString, required = false,
                                 default = nil)
  if valid_593130 != nil:
    section.add "X-Amz-Security-Token", valid_593130
  var valid_593131 = header.getOrDefault("X-Amz-Algorithm")
  valid_593131 = validateParameter(valid_593131, JString, required = false,
                                 default = nil)
  if valid_593131 != nil:
    section.add "X-Amz-Algorithm", valid_593131
  var valid_593132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593132 = validateParameter(valid_593132, JString, required = false,
                                 default = nil)
  if valid_593132 != nil:
    section.add "X-Amz-SignedHeaders", valid_593132
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
  var valid_593133 = formData.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_593133 = validateParameter(valid_593133, JString, required = false,
                                 default = nil)
  if valid_593133 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_593133
  var valid_593134 = formData.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_593134 = validateParameter(valid_593134, JString, required = false,
                                 default = nil)
  if valid_593134 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_593134
  var valid_593135 = formData.getOrDefault("Description")
  valid_593135 = validateParameter(valid_593135, JString, required = false,
                                 default = nil)
  if valid_593135 != nil:
    section.add "Description", valid_593135
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_593136 = formData.getOrDefault("ApplicationName")
  valid_593136 = validateParameter(valid_593136, JString, required = true,
                                 default = nil)
  if valid_593136 != nil:
    section.add "ApplicationName", valid_593136
  var valid_593137 = formData.getOrDefault("Tags")
  valid_593137 = validateParameter(valid_593137, JArray, required = false,
                                 default = nil)
  if valid_593137 != nil:
    section.add "Tags", valid_593137
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593138: Call_PostCreateApplication_593121; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates an application that has one configuration template named <code>default</code> and no application versions. 
  ## 
  let valid = call_593138.validator(path, query, header, formData, body)
  let scheme = call_593138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593138.url(scheme.get, call_593138.host, call_593138.base,
                         call_593138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593138, url, valid)

proc call*(call_593139: Call_PostCreateApplication_593121; ApplicationName: string;
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
  var query_593140 = newJObject()
  var formData_593141 = newJObject()
  add(formData_593141, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  add(formData_593141, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  add(formData_593141, "Description", newJString(Description))
  add(formData_593141, "ApplicationName", newJString(ApplicationName))
  add(query_593140, "Action", newJString(Action))
  if Tags != nil:
    formData_593141.add "Tags", Tags
  add(query_593140, "Version", newJString(Version))
  result = call_593139.call(nil, query_593140, nil, formData_593141, nil)

var postCreateApplication* = Call_PostCreateApplication_593121(
    name: "postCreateApplication", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateApplication",
    validator: validate_PostCreateApplication_593122, base: "/",
    url: url_PostCreateApplication_593123, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateApplication_593101 = ref object of OpenApiRestCall_592365
proc url_GetCreateApplication_593103(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateApplication_593102(path: JsonNode; query: JsonNode;
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
  var valid_593104 = query.getOrDefault("ApplicationName")
  valid_593104 = validateParameter(valid_593104, JString, required = true,
                                 default = nil)
  if valid_593104 != nil:
    section.add "ApplicationName", valid_593104
  var valid_593105 = query.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_593105 = validateParameter(valid_593105, JString, required = false,
                                 default = nil)
  if valid_593105 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_593105
  var valid_593106 = query.getOrDefault("Tags")
  valid_593106 = validateParameter(valid_593106, JArray, required = false,
                                 default = nil)
  if valid_593106 != nil:
    section.add "Tags", valid_593106
  var valid_593107 = query.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_593107 = validateParameter(valid_593107, JString, required = false,
                                 default = nil)
  if valid_593107 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_593107
  var valid_593108 = query.getOrDefault("Action")
  valid_593108 = validateParameter(valid_593108, JString, required = true,
                                 default = newJString("CreateApplication"))
  if valid_593108 != nil:
    section.add "Action", valid_593108
  var valid_593109 = query.getOrDefault("Description")
  valid_593109 = validateParameter(valid_593109, JString, required = false,
                                 default = nil)
  if valid_593109 != nil:
    section.add "Description", valid_593109
  var valid_593110 = query.getOrDefault("Version")
  valid_593110 = validateParameter(valid_593110, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593110 != nil:
    section.add "Version", valid_593110
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
  var valid_593111 = header.getOrDefault("X-Amz-Signature")
  valid_593111 = validateParameter(valid_593111, JString, required = false,
                                 default = nil)
  if valid_593111 != nil:
    section.add "X-Amz-Signature", valid_593111
  var valid_593112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593112 = validateParameter(valid_593112, JString, required = false,
                                 default = nil)
  if valid_593112 != nil:
    section.add "X-Amz-Content-Sha256", valid_593112
  var valid_593113 = header.getOrDefault("X-Amz-Date")
  valid_593113 = validateParameter(valid_593113, JString, required = false,
                                 default = nil)
  if valid_593113 != nil:
    section.add "X-Amz-Date", valid_593113
  var valid_593114 = header.getOrDefault("X-Amz-Credential")
  valid_593114 = validateParameter(valid_593114, JString, required = false,
                                 default = nil)
  if valid_593114 != nil:
    section.add "X-Amz-Credential", valid_593114
  var valid_593115 = header.getOrDefault("X-Amz-Security-Token")
  valid_593115 = validateParameter(valid_593115, JString, required = false,
                                 default = nil)
  if valid_593115 != nil:
    section.add "X-Amz-Security-Token", valid_593115
  var valid_593116 = header.getOrDefault("X-Amz-Algorithm")
  valid_593116 = validateParameter(valid_593116, JString, required = false,
                                 default = nil)
  if valid_593116 != nil:
    section.add "X-Amz-Algorithm", valid_593116
  var valid_593117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593117 = validateParameter(valid_593117, JString, required = false,
                                 default = nil)
  if valid_593117 != nil:
    section.add "X-Amz-SignedHeaders", valid_593117
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593118: Call_GetCreateApplication_593101; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates an application that has one configuration template named <code>default</code> and no application versions. 
  ## 
  let valid = call_593118.validator(path, query, header, formData, body)
  let scheme = call_593118.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593118.url(scheme.get, call_593118.host, call_593118.base,
                         call_593118.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593118, url, valid)

proc call*(call_593119: Call_GetCreateApplication_593101; ApplicationName: string;
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
  var query_593120 = newJObject()
  add(query_593120, "ApplicationName", newJString(ApplicationName))
  add(query_593120, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  if Tags != nil:
    query_593120.add "Tags", Tags
  add(query_593120, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  add(query_593120, "Action", newJString(Action))
  add(query_593120, "Description", newJString(Description))
  add(query_593120, "Version", newJString(Version))
  result = call_593119.call(nil, query_593120, nil, nil, nil)

var getCreateApplication* = Call_GetCreateApplication_593101(
    name: "getCreateApplication", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateApplication",
    validator: validate_GetCreateApplication_593102, base: "/",
    url: url_GetCreateApplication_593103, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateApplicationVersion_593173 = ref object of OpenApiRestCall_592365
proc url_PostCreateApplicationVersion_593175(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateApplicationVersion_593174(path: JsonNode; query: JsonNode;
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
  var valid_593176 = query.getOrDefault("Action")
  valid_593176 = validateParameter(valid_593176, JString, required = true, default = newJString(
      "CreateApplicationVersion"))
  if valid_593176 != nil:
    section.add "Action", valid_593176
  var valid_593177 = query.getOrDefault("Version")
  valid_593177 = validateParameter(valid_593177, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593177 != nil:
    section.add "Version", valid_593177
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
  var valid_593178 = header.getOrDefault("X-Amz-Signature")
  valid_593178 = validateParameter(valid_593178, JString, required = false,
                                 default = nil)
  if valid_593178 != nil:
    section.add "X-Amz-Signature", valid_593178
  var valid_593179 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593179 = validateParameter(valid_593179, JString, required = false,
                                 default = nil)
  if valid_593179 != nil:
    section.add "X-Amz-Content-Sha256", valid_593179
  var valid_593180 = header.getOrDefault("X-Amz-Date")
  valid_593180 = validateParameter(valid_593180, JString, required = false,
                                 default = nil)
  if valid_593180 != nil:
    section.add "X-Amz-Date", valid_593180
  var valid_593181 = header.getOrDefault("X-Amz-Credential")
  valid_593181 = validateParameter(valid_593181, JString, required = false,
                                 default = nil)
  if valid_593181 != nil:
    section.add "X-Amz-Credential", valid_593181
  var valid_593182 = header.getOrDefault("X-Amz-Security-Token")
  valid_593182 = validateParameter(valid_593182, JString, required = false,
                                 default = nil)
  if valid_593182 != nil:
    section.add "X-Amz-Security-Token", valid_593182
  var valid_593183 = header.getOrDefault("X-Amz-Algorithm")
  valid_593183 = validateParameter(valid_593183, JString, required = false,
                                 default = nil)
  if valid_593183 != nil:
    section.add "X-Amz-Algorithm", valid_593183
  var valid_593184 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593184 = validateParameter(valid_593184, JString, required = false,
                                 default = nil)
  if valid_593184 != nil:
    section.add "X-Amz-SignedHeaders", valid_593184
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
  var valid_593185 = formData.getOrDefault("BuildConfiguration.ComputeType")
  valid_593185 = validateParameter(valid_593185, JString, required = false,
                                 default = nil)
  if valid_593185 != nil:
    section.add "BuildConfiguration.ComputeType", valid_593185
  var valid_593186 = formData.getOrDefault("SourceBundle.S3Key")
  valid_593186 = validateParameter(valid_593186, JString, required = false,
                                 default = nil)
  if valid_593186 != nil:
    section.add "SourceBundle.S3Key", valid_593186
  var valid_593187 = formData.getOrDefault("Process")
  valid_593187 = validateParameter(valid_593187, JBool, required = false, default = nil)
  if valid_593187 != nil:
    section.add "Process", valid_593187
  var valid_593188 = formData.getOrDefault("SourceBuildInformation.SourceType")
  valid_593188 = validateParameter(valid_593188, JString, required = false,
                                 default = nil)
  if valid_593188 != nil:
    section.add "SourceBuildInformation.SourceType", valid_593188
  var valid_593189 = formData.getOrDefault("BuildConfiguration.ArtifactName")
  valid_593189 = validateParameter(valid_593189, JString, required = false,
                                 default = nil)
  if valid_593189 != nil:
    section.add "BuildConfiguration.ArtifactName", valid_593189
  var valid_593190 = formData.getOrDefault("Description")
  valid_593190 = validateParameter(valid_593190, JString, required = false,
                                 default = nil)
  if valid_593190 != nil:
    section.add "Description", valid_593190
  assert formData != nil,
        "formData argument is necessary due to required `VersionLabel` field"
  var valid_593191 = formData.getOrDefault("VersionLabel")
  valid_593191 = validateParameter(valid_593191, JString, required = true,
                                 default = nil)
  if valid_593191 != nil:
    section.add "VersionLabel", valid_593191
  var valid_593192 = formData.getOrDefault("SourceBuildInformation.SourceRepository")
  valid_593192 = validateParameter(valid_593192, JString, required = false,
                                 default = nil)
  if valid_593192 != nil:
    section.add "SourceBuildInformation.SourceRepository", valid_593192
  var valid_593193 = formData.getOrDefault("AutoCreateApplication")
  valid_593193 = validateParameter(valid_593193, JBool, required = false, default = nil)
  if valid_593193 != nil:
    section.add "AutoCreateApplication", valid_593193
  var valid_593194 = formData.getOrDefault("SourceBuildInformation.SourceLocation")
  valid_593194 = validateParameter(valid_593194, JString, required = false,
                                 default = nil)
  if valid_593194 != nil:
    section.add "SourceBuildInformation.SourceLocation", valid_593194
  var valid_593195 = formData.getOrDefault("ApplicationName")
  valid_593195 = validateParameter(valid_593195, JString, required = true,
                                 default = nil)
  if valid_593195 != nil:
    section.add "ApplicationName", valid_593195
  var valid_593196 = formData.getOrDefault("BuildConfiguration.Image")
  valid_593196 = validateParameter(valid_593196, JString, required = false,
                                 default = nil)
  if valid_593196 != nil:
    section.add "BuildConfiguration.Image", valid_593196
  var valid_593197 = formData.getOrDefault("BuildConfiguration.TimeoutInMinutes")
  valid_593197 = validateParameter(valid_593197, JString, required = false,
                                 default = nil)
  if valid_593197 != nil:
    section.add "BuildConfiguration.TimeoutInMinutes", valid_593197
  var valid_593198 = formData.getOrDefault("Tags")
  valid_593198 = validateParameter(valid_593198, JArray, required = false,
                                 default = nil)
  if valid_593198 != nil:
    section.add "Tags", valid_593198
  var valid_593199 = formData.getOrDefault("SourceBundle.S3Bucket")
  valid_593199 = validateParameter(valid_593199, JString, required = false,
                                 default = nil)
  if valid_593199 != nil:
    section.add "SourceBundle.S3Bucket", valid_593199
  var valid_593200 = formData.getOrDefault("BuildConfiguration.CodeBuildServiceRole")
  valid_593200 = validateParameter(valid_593200, JString, required = false,
                                 default = nil)
  if valid_593200 != nil:
    section.add "BuildConfiguration.CodeBuildServiceRole", valid_593200
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593201: Call_PostCreateApplicationVersion_593173; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an application version for the specified application. You can create an application version from a source bundle in Amazon S3, a commit in AWS CodeCommit, or the output of an AWS CodeBuild build as follows:</p> <p>Specify a commit in an AWS CodeCommit repository with <code>SourceBuildInformation</code>.</p> <p>Specify a build in an AWS CodeBuild with <code>SourceBuildInformation</code> and <code>BuildConfiguration</code>.</p> <p>Specify a source bundle in S3 with <code>SourceBundle</code> </p> <p>Omit both <code>SourceBuildInformation</code> and <code>SourceBundle</code> to use the default sample application.</p> <note> <p>Once you create an application version with a specified Amazon S3 bucket and key location, you cannot change that Amazon S3 location. If you change the Amazon S3 location, you receive an exception when you attempt to launch an environment from the application version.</p> </note>
  ## 
  let valid = call_593201.validator(path, query, header, formData, body)
  let scheme = call_593201.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593201.url(scheme.get, call_593201.host, call_593201.base,
                         call_593201.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593201, url, valid)

proc call*(call_593202: Call_PostCreateApplicationVersion_593173;
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
  var query_593203 = newJObject()
  var formData_593204 = newJObject()
  add(formData_593204, "BuildConfiguration.ComputeType",
      newJString(BuildConfigurationComputeType))
  add(formData_593204, "SourceBundle.S3Key", newJString(SourceBundleS3Key))
  add(formData_593204, "Process", newJBool(Process))
  add(formData_593204, "SourceBuildInformation.SourceType",
      newJString(SourceBuildInformationSourceType))
  add(formData_593204, "BuildConfiguration.ArtifactName",
      newJString(BuildConfigurationArtifactName))
  add(formData_593204, "Description", newJString(Description))
  add(formData_593204, "VersionLabel", newJString(VersionLabel))
  add(formData_593204, "SourceBuildInformation.SourceRepository",
      newJString(SourceBuildInformationSourceRepository))
  add(formData_593204, "AutoCreateApplication", newJBool(AutoCreateApplication))
  add(formData_593204, "SourceBuildInformation.SourceLocation",
      newJString(SourceBuildInformationSourceLocation))
  add(formData_593204, "ApplicationName", newJString(ApplicationName))
  add(query_593203, "Action", newJString(Action))
  add(formData_593204, "BuildConfiguration.Image",
      newJString(BuildConfigurationImage))
  add(formData_593204, "BuildConfiguration.TimeoutInMinutes",
      newJString(BuildConfigurationTimeoutInMinutes))
  if Tags != nil:
    formData_593204.add "Tags", Tags
  add(formData_593204, "SourceBundle.S3Bucket", newJString(SourceBundleS3Bucket))
  add(query_593203, "Version", newJString(Version))
  add(formData_593204, "BuildConfiguration.CodeBuildServiceRole",
      newJString(BuildConfigurationCodeBuildServiceRole))
  result = call_593202.call(nil, query_593203, nil, formData_593204, nil)

var postCreateApplicationVersion* = Call_PostCreateApplicationVersion_593173(
    name: "postCreateApplicationVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateApplicationVersion",
    validator: validate_PostCreateApplicationVersion_593174, base: "/",
    url: url_PostCreateApplicationVersion_593175,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateApplicationVersion_593142 = ref object of OpenApiRestCall_592365
proc url_GetCreateApplicationVersion_593144(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateApplicationVersion_593143(path: JsonNode; query: JsonNode;
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
  var valid_593145 = query.getOrDefault("ApplicationName")
  valid_593145 = validateParameter(valid_593145, JString, required = true,
                                 default = nil)
  if valid_593145 != nil:
    section.add "ApplicationName", valid_593145
  var valid_593146 = query.getOrDefault("BuildConfiguration.TimeoutInMinutes")
  valid_593146 = validateParameter(valid_593146, JString, required = false,
                                 default = nil)
  if valid_593146 != nil:
    section.add "BuildConfiguration.TimeoutInMinutes", valid_593146
  var valid_593147 = query.getOrDefault("Process")
  valid_593147 = validateParameter(valid_593147, JBool, required = false, default = nil)
  if valid_593147 != nil:
    section.add "Process", valid_593147
  var valid_593148 = query.getOrDefault("SourceBuildInformation.SourceLocation")
  valid_593148 = validateParameter(valid_593148, JString, required = false,
                                 default = nil)
  if valid_593148 != nil:
    section.add "SourceBuildInformation.SourceLocation", valid_593148
  var valid_593149 = query.getOrDefault("VersionLabel")
  valid_593149 = validateParameter(valid_593149, JString, required = true,
                                 default = nil)
  if valid_593149 != nil:
    section.add "VersionLabel", valid_593149
  var valid_593150 = query.getOrDefault("Tags")
  valid_593150 = validateParameter(valid_593150, JArray, required = false,
                                 default = nil)
  if valid_593150 != nil:
    section.add "Tags", valid_593150
  var valid_593151 = query.getOrDefault("AutoCreateApplication")
  valid_593151 = validateParameter(valid_593151, JBool, required = false, default = nil)
  if valid_593151 != nil:
    section.add "AutoCreateApplication", valid_593151
  var valid_593152 = query.getOrDefault("BuildConfiguration.Image")
  valid_593152 = validateParameter(valid_593152, JString, required = false,
                                 default = nil)
  if valid_593152 != nil:
    section.add "BuildConfiguration.Image", valid_593152
  var valid_593153 = query.getOrDefault("Action")
  valid_593153 = validateParameter(valid_593153, JString, required = true, default = newJString(
      "CreateApplicationVersion"))
  if valid_593153 != nil:
    section.add "Action", valid_593153
  var valid_593154 = query.getOrDefault("Description")
  valid_593154 = validateParameter(valid_593154, JString, required = false,
                                 default = nil)
  if valid_593154 != nil:
    section.add "Description", valid_593154
  var valid_593155 = query.getOrDefault("SourceBundle.S3Bucket")
  valid_593155 = validateParameter(valid_593155, JString, required = false,
                                 default = nil)
  if valid_593155 != nil:
    section.add "SourceBundle.S3Bucket", valid_593155
  var valid_593156 = query.getOrDefault("SourceBuildInformation.SourceRepository")
  valid_593156 = validateParameter(valid_593156, JString, required = false,
                                 default = nil)
  if valid_593156 != nil:
    section.add "SourceBuildInformation.SourceRepository", valid_593156
  var valid_593157 = query.getOrDefault("BuildConfiguration.ComputeType")
  valid_593157 = validateParameter(valid_593157, JString, required = false,
                                 default = nil)
  if valid_593157 != nil:
    section.add "BuildConfiguration.ComputeType", valid_593157
  var valid_593158 = query.getOrDefault("SourceBuildInformation.SourceType")
  valid_593158 = validateParameter(valid_593158, JString, required = false,
                                 default = nil)
  if valid_593158 != nil:
    section.add "SourceBuildInformation.SourceType", valid_593158
  var valid_593159 = query.getOrDefault("BuildConfiguration.ArtifactName")
  valid_593159 = validateParameter(valid_593159, JString, required = false,
                                 default = nil)
  if valid_593159 != nil:
    section.add "BuildConfiguration.ArtifactName", valid_593159
  var valid_593160 = query.getOrDefault("Version")
  valid_593160 = validateParameter(valid_593160, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593160 != nil:
    section.add "Version", valid_593160
  var valid_593161 = query.getOrDefault("SourceBundle.S3Key")
  valid_593161 = validateParameter(valid_593161, JString, required = false,
                                 default = nil)
  if valid_593161 != nil:
    section.add "SourceBundle.S3Key", valid_593161
  var valid_593162 = query.getOrDefault("BuildConfiguration.CodeBuildServiceRole")
  valid_593162 = validateParameter(valid_593162, JString, required = false,
                                 default = nil)
  if valid_593162 != nil:
    section.add "BuildConfiguration.CodeBuildServiceRole", valid_593162
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
  var valid_593163 = header.getOrDefault("X-Amz-Signature")
  valid_593163 = validateParameter(valid_593163, JString, required = false,
                                 default = nil)
  if valid_593163 != nil:
    section.add "X-Amz-Signature", valid_593163
  var valid_593164 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593164 = validateParameter(valid_593164, JString, required = false,
                                 default = nil)
  if valid_593164 != nil:
    section.add "X-Amz-Content-Sha256", valid_593164
  var valid_593165 = header.getOrDefault("X-Amz-Date")
  valid_593165 = validateParameter(valid_593165, JString, required = false,
                                 default = nil)
  if valid_593165 != nil:
    section.add "X-Amz-Date", valid_593165
  var valid_593166 = header.getOrDefault("X-Amz-Credential")
  valid_593166 = validateParameter(valid_593166, JString, required = false,
                                 default = nil)
  if valid_593166 != nil:
    section.add "X-Amz-Credential", valid_593166
  var valid_593167 = header.getOrDefault("X-Amz-Security-Token")
  valid_593167 = validateParameter(valid_593167, JString, required = false,
                                 default = nil)
  if valid_593167 != nil:
    section.add "X-Amz-Security-Token", valid_593167
  var valid_593168 = header.getOrDefault("X-Amz-Algorithm")
  valid_593168 = validateParameter(valid_593168, JString, required = false,
                                 default = nil)
  if valid_593168 != nil:
    section.add "X-Amz-Algorithm", valid_593168
  var valid_593169 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593169 = validateParameter(valid_593169, JString, required = false,
                                 default = nil)
  if valid_593169 != nil:
    section.add "X-Amz-SignedHeaders", valid_593169
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593170: Call_GetCreateApplicationVersion_593142; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an application version for the specified application. You can create an application version from a source bundle in Amazon S3, a commit in AWS CodeCommit, or the output of an AWS CodeBuild build as follows:</p> <p>Specify a commit in an AWS CodeCommit repository with <code>SourceBuildInformation</code>.</p> <p>Specify a build in an AWS CodeBuild with <code>SourceBuildInformation</code> and <code>BuildConfiguration</code>.</p> <p>Specify a source bundle in S3 with <code>SourceBundle</code> </p> <p>Omit both <code>SourceBuildInformation</code> and <code>SourceBundle</code> to use the default sample application.</p> <note> <p>Once you create an application version with a specified Amazon S3 bucket and key location, you cannot change that Amazon S3 location. If you change the Amazon S3 location, you receive an exception when you attempt to launch an environment from the application version.</p> </note>
  ## 
  let valid = call_593170.validator(path, query, header, formData, body)
  let scheme = call_593170.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593170.url(scheme.get, call_593170.host, call_593170.base,
                         call_593170.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593170, url, valid)

proc call*(call_593171: Call_GetCreateApplicationVersion_593142;
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
  var query_593172 = newJObject()
  add(query_593172, "ApplicationName", newJString(ApplicationName))
  add(query_593172, "BuildConfiguration.TimeoutInMinutes",
      newJString(BuildConfigurationTimeoutInMinutes))
  add(query_593172, "Process", newJBool(Process))
  add(query_593172, "SourceBuildInformation.SourceLocation",
      newJString(SourceBuildInformationSourceLocation))
  add(query_593172, "VersionLabel", newJString(VersionLabel))
  if Tags != nil:
    query_593172.add "Tags", Tags
  add(query_593172, "AutoCreateApplication", newJBool(AutoCreateApplication))
  add(query_593172, "BuildConfiguration.Image",
      newJString(BuildConfigurationImage))
  add(query_593172, "Action", newJString(Action))
  add(query_593172, "Description", newJString(Description))
  add(query_593172, "SourceBundle.S3Bucket", newJString(SourceBundleS3Bucket))
  add(query_593172, "SourceBuildInformation.SourceRepository",
      newJString(SourceBuildInformationSourceRepository))
  add(query_593172, "BuildConfiguration.ComputeType",
      newJString(BuildConfigurationComputeType))
  add(query_593172, "SourceBuildInformation.SourceType",
      newJString(SourceBuildInformationSourceType))
  add(query_593172, "BuildConfiguration.ArtifactName",
      newJString(BuildConfigurationArtifactName))
  add(query_593172, "Version", newJString(Version))
  add(query_593172, "SourceBundle.S3Key", newJString(SourceBundleS3Key))
  add(query_593172, "BuildConfiguration.CodeBuildServiceRole",
      newJString(BuildConfigurationCodeBuildServiceRole))
  result = call_593171.call(nil, query_593172, nil, nil, nil)

var getCreateApplicationVersion* = Call_GetCreateApplicationVersion_593142(
    name: "getCreateApplicationVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateApplicationVersion",
    validator: validate_GetCreateApplicationVersion_593143, base: "/",
    url: url_GetCreateApplicationVersion_593144,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateConfigurationTemplate_593230 = ref object of OpenApiRestCall_592365
proc url_PostCreateConfigurationTemplate_593232(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateConfigurationTemplate_593231(path: JsonNode;
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
  var valid_593233 = query.getOrDefault("Action")
  valid_593233 = validateParameter(valid_593233, JString, required = true, default = newJString(
      "CreateConfigurationTemplate"))
  if valid_593233 != nil:
    section.add "Action", valid_593233
  var valid_593234 = query.getOrDefault("Version")
  valid_593234 = validateParameter(valid_593234, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593234 != nil:
    section.add "Version", valid_593234
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
  var valid_593235 = header.getOrDefault("X-Amz-Signature")
  valid_593235 = validateParameter(valid_593235, JString, required = false,
                                 default = nil)
  if valid_593235 != nil:
    section.add "X-Amz-Signature", valid_593235
  var valid_593236 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593236 = validateParameter(valid_593236, JString, required = false,
                                 default = nil)
  if valid_593236 != nil:
    section.add "X-Amz-Content-Sha256", valid_593236
  var valid_593237 = header.getOrDefault("X-Amz-Date")
  valid_593237 = validateParameter(valid_593237, JString, required = false,
                                 default = nil)
  if valid_593237 != nil:
    section.add "X-Amz-Date", valid_593237
  var valid_593238 = header.getOrDefault("X-Amz-Credential")
  valid_593238 = validateParameter(valid_593238, JString, required = false,
                                 default = nil)
  if valid_593238 != nil:
    section.add "X-Amz-Credential", valid_593238
  var valid_593239 = header.getOrDefault("X-Amz-Security-Token")
  valid_593239 = validateParameter(valid_593239, JString, required = false,
                                 default = nil)
  if valid_593239 != nil:
    section.add "X-Amz-Security-Token", valid_593239
  var valid_593240 = header.getOrDefault("X-Amz-Algorithm")
  valid_593240 = validateParameter(valid_593240, JString, required = false,
                                 default = nil)
  if valid_593240 != nil:
    section.add "X-Amz-Algorithm", valid_593240
  var valid_593241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593241 = validateParameter(valid_593241, JString, required = false,
                                 default = nil)
  if valid_593241 != nil:
    section.add "X-Amz-SignedHeaders", valid_593241
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
  var valid_593242 = formData.getOrDefault("Description")
  valid_593242 = validateParameter(valid_593242, JString, required = false,
                                 default = nil)
  if valid_593242 != nil:
    section.add "Description", valid_593242
  assert formData != nil,
        "formData argument is necessary due to required `TemplateName` field"
  var valid_593243 = formData.getOrDefault("TemplateName")
  valid_593243 = validateParameter(valid_593243, JString, required = true,
                                 default = nil)
  if valid_593243 != nil:
    section.add "TemplateName", valid_593243
  var valid_593244 = formData.getOrDefault("SourceConfiguration.ApplicationName")
  valid_593244 = validateParameter(valid_593244, JString, required = false,
                                 default = nil)
  if valid_593244 != nil:
    section.add "SourceConfiguration.ApplicationName", valid_593244
  var valid_593245 = formData.getOrDefault("SourceConfiguration.TemplateName")
  valid_593245 = validateParameter(valid_593245, JString, required = false,
                                 default = nil)
  if valid_593245 != nil:
    section.add "SourceConfiguration.TemplateName", valid_593245
  var valid_593246 = formData.getOrDefault("OptionSettings")
  valid_593246 = validateParameter(valid_593246, JArray, required = false,
                                 default = nil)
  if valid_593246 != nil:
    section.add "OptionSettings", valid_593246
  var valid_593247 = formData.getOrDefault("ApplicationName")
  valid_593247 = validateParameter(valid_593247, JString, required = true,
                                 default = nil)
  if valid_593247 != nil:
    section.add "ApplicationName", valid_593247
  var valid_593248 = formData.getOrDefault("Tags")
  valid_593248 = validateParameter(valid_593248, JArray, required = false,
                                 default = nil)
  if valid_593248 != nil:
    section.add "Tags", valid_593248
  var valid_593249 = formData.getOrDefault("SolutionStackName")
  valid_593249 = validateParameter(valid_593249, JString, required = false,
                                 default = nil)
  if valid_593249 != nil:
    section.add "SolutionStackName", valid_593249
  var valid_593250 = formData.getOrDefault("EnvironmentId")
  valid_593250 = validateParameter(valid_593250, JString, required = false,
                                 default = nil)
  if valid_593250 != nil:
    section.add "EnvironmentId", valid_593250
  var valid_593251 = formData.getOrDefault("PlatformArn")
  valid_593251 = validateParameter(valid_593251, JString, required = false,
                                 default = nil)
  if valid_593251 != nil:
    section.add "PlatformArn", valid_593251
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593252: Call_PostCreateConfigurationTemplate_593230;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a configuration template. Templates are associated with a specific application and are used to deploy different versions of the application with the same configuration settings.</p> <p>Templates aren't associated with any environment. The <code>EnvironmentName</code> response element is always <code>null</code>.</p> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> <li> <p> <a>DescribeConfigurationSettings</a> </p> </li> <li> <p> <a>ListAvailableSolutionStacks</a> </p> </li> </ul>
  ## 
  let valid = call_593252.validator(path, query, header, formData, body)
  let scheme = call_593252.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593252.url(scheme.get, call_593252.host, call_593252.base,
                         call_593252.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593252, url, valid)

proc call*(call_593253: Call_PostCreateConfigurationTemplate_593230;
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
  var query_593254 = newJObject()
  var formData_593255 = newJObject()
  add(formData_593255, "Description", newJString(Description))
  add(formData_593255, "TemplateName", newJString(TemplateName))
  add(formData_593255, "SourceConfiguration.ApplicationName",
      newJString(SourceConfigurationApplicationName))
  add(formData_593255, "SourceConfiguration.TemplateName",
      newJString(SourceConfigurationTemplateName))
  if OptionSettings != nil:
    formData_593255.add "OptionSettings", OptionSettings
  add(formData_593255, "ApplicationName", newJString(ApplicationName))
  add(query_593254, "Action", newJString(Action))
  if Tags != nil:
    formData_593255.add "Tags", Tags
  add(formData_593255, "SolutionStackName", newJString(SolutionStackName))
  add(formData_593255, "EnvironmentId", newJString(EnvironmentId))
  add(query_593254, "Version", newJString(Version))
  add(formData_593255, "PlatformArn", newJString(PlatformArn))
  result = call_593253.call(nil, query_593254, nil, formData_593255, nil)

var postCreateConfigurationTemplate* = Call_PostCreateConfigurationTemplate_593230(
    name: "postCreateConfigurationTemplate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateConfigurationTemplate",
    validator: validate_PostCreateConfigurationTemplate_593231, base: "/",
    url: url_PostCreateConfigurationTemplate_593232,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateConfigurationTemplate_593205 = ref object of OpenApiRestCall_592365
proc url_GetCreateConfigurationTemplate_593207(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateConfigurationTemplate_593206(path: JsonNode;
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
  var valid_593208 = query.getOrDefault("ApplicationName")
  valid_593208 = validateParameter(valid_593208, JString, required = true,
                                 default = nil)
  if valid_593208 != nil:
    section.add "ApplicationName", valid_593208
  var valid_593209 = query.getOrDefault("Tags")
  valid_593209 = validateParameter(valid_593209, JArray, required = false,
                                 default = nil)
  if valid_593209 != nil:
    section.add "Tags", valid_593209
  var valid_593210 = query.getOrDefault("OptionSettings")
  valid_593210 = validateParameter(valid_593210, JArray, required = false,
                                 default = nil)
  if valid_593210 != nil:
    section.add "OptionSettings", valid_593210
  var valid_593211 = query.getOrDefault("SourceConfiguration.TemplateName")
  valid_593211 = validateParameter(valid_593211, JString, required = false,
                                 default = nil)
  if valid_593211 != nil:
    section.add "SourceConfiguration.TemplateName", valid_593211
  var valid_593212 = query.getOrDefault("SolutionStackName")
  valid_593212 = validateParameter(valid_593212, JString, required = false,
                                 default = nil)
  if valid_593212 != nil:
    section.add "SolutionStackName", valid_593212
  var valid_593213 = query.getOrDefault("Action")
  valid_593213 = validateParameter(valid_593213, JString, required = true, default = newJString(
      "CreateConfigurationTemplate"))
  if valid_593213 != nil:
    section.add "Action", valid_593213
  var valid_593214 = query.getOrDefault("Description")
  valid_593214 = validateParameter(valid_593214, JString, required = false,
                                 default = nil)
  if valid_593214 != nil:
    section.add "Description", valid_593214
  var valid_593215 = query.getOrDefault("PlatformArn")
  valid_593215 = validateParameter(valid_593215, JString, required = false,
                                 default = nil)
  if valid_593215 != nil:
    section.add "PlatformArn", valid_593215
  var valid_593216 = query.getOrDefault("Version")
  valid_593216 = validateParameter(valid_593216, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593216 != nil:
    section.add "Version", valid_593216
  var valid_593217 = query.getOrDefault("TemplateName")
  valid_593217 = validateParameter(valid_593217, JString, required = true,
                                 default = nil)
  if valid_593217 != nil:
    section.add "TemplateName", valid_593217
  var valid_593218 = query.getOrDefault("SourceConfiguration.ApplicationName")
  valid_593218 = validateParameter(valid_593218, JString, required = false,
                                 default = nil)
  if valid_593218 != nil:
    section.add "SourceConfiguration.ApplicationName", valid_593218
  var valid_593219 = query.getOrDefault("EnvironmentId")
  valid_593219 = validateParameter(valid_593219, JString, required = false,
                                 default = nil)
  if valid_593219 != nil:
    section.add "EnvironmentId", valid_593219
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
  var valid_593220 = header.getOrDefault("X-Amz-Signature")
  valid_593220 = validateParameter(valid_593220, JString, required = false,
                                 default = nil)
  if valid_593220 != nil:
    section.add "X-Amz-Signature", valid_593220
  var valid_593221 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593221 = validateParameter(valid_593221, JString, required = false,
                                 default = nil)
  if valid_593221 != nil:
    section.add "X-Amz-Content-Sha256", valid_593221
  var valid_593222 = header.getOrDefault("X-Amz-Date")
  valid_593222 = validateParameter(valid_593222, JString, required = false,
                                 default = nil)
  if valid_593222 != nil:
    section.add "X-Amz-Date", valid_593222
  var valid_593223 = header.getOrDefault("X-Amz-Credential")
  valid_593223 = validateParameter(valid_593223, JString, required = false,
                                 default = nil)
  if valid_593223 != nil:
    section.add "X-Amz-Credential", valid_593223
  var valid_593224 = header.getOrDefault("X-Amz-Security-Token")
  valid_593224 = validateParameter(valid_593224, JString, required = false,
                                 default = nil)
  if valid_593224 != nil:
    section.add "X-Amz-Security-Token", valid_593224
  var valid_593225 = header.getOrDefault("X-Amz-Algorithm")
  valid_593225 = validateParameter(valid_593225, JString, required = false,
                                 default = nil)
  if valid_593225 != nil:
    section.add "X-Amz-Algorithm", valid_593225
  var valid_593226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593226 = validateParameter(valid_593226, JString, required = false,
                                 default = nil)
  if valid_593226 != nil:
    section.add "X-Amz-SignedHeaders", valid_593226
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593227: Call_GetCreateConfigurationTemplate_593205; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a configuration template. Templates are associated with a specific application and are used to deploy different versions of the application with the same configuration settings.</p> <p>Templates aren't associated with any environment. The <code>EnvironmentName</code> response element is always <code>null</code>.</p> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> <li> <p> <a>DescribeConfigurationSettings</a> </p> </li> <li> <p> <a>ListAvailableSolutionStacks</a> </p> </li> </ul>
  ## 
  let valid = call_593227.validator(path, query, header, formData, body)
  let scheme = call_593227.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593227.url(scheme.get, call_593227.host, call_593227.base,
                         call_593227.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593227, url, valid)

proc call*(call_593228: Call_GetCreateConfigurationTemplate_593205;
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
  var query_593229 = newJObject()
  add(query_593229, "ApplicationName", newJString(ApplicationName))
  if Tags != nil:
    query_593229.add "Tags", Tags
  if OptionSettings != nil:
    query_593229.add "OptionSettings", OptionSettings
  add(query_593229, "SourceConfiguration.TemplateName",
      newJString(SourceConfigurationTemplateName))
  add(query_593229, "SolutionStackName", newJString(SolutionStackName))
  add(query_593229, "Action", newJString(Action))
  add(query_593229, "Description", newJString(Description))
  add(query_593229, "PlatformArn", newJString(PlatformArn))
  add(query_593229, "Version", newJString(Version))
  add(query_593229, "TemplateName", newJString(TemplateName))
  add(query_593229, "SourceConfiguration.ApplicationName",
      newJString(SourceConfigurationApplicationName))
  add(query_593229, "EnvironmentId", newJString(EnvironmentId))
  result = call_593228.call(nil, query_593229, nil, nil, nil)

var getCreateConfigurationTemplate* = Call_GetCreateConfigurationTemplate_593205(
    name: "getCreateConfigurationTemplate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateConfigurationTemplate",
    validator: validate_GetCreateConfigurationTemplate_593206, base: "/",
    url: url_GetCreateConfigurationTemplate_593207,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEnvironment_593286 = ref object of OpenApiRestCall_592365
proc url_PostCreateEnvironment_593288(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateEnvironment_593287(path: JsonNode; query: JsonNode;
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
  var valid_593289 = query.getOrDefault("Action")
  valid_593289 = validateParameter(valid_593289, JString, required = true,
                                 default = newJString("CreateEnvironment"))
  if valid_593289 != nil:
    section.add "Action", valid_593289
  var valid_593290 = query.getOrDefault("Version")
  valid_593290 = validateParameter(valid_593290, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593290 != nil:
    section.add "Version", valid_593290
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
  var valid_593291 = header.getOrDefault("X-Amz-Signature")
  valid_593291 = validateParameter(valid_593291, JString, required = false,
                                 default = nil)
  if valid_593291 != nil:
    section.add "X-Amz-Signature", valid_593291
  var valid_593292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593292 = validateParameter(valid_593292, JString, required = false,
                                 default = nil)
  if valid_593292 != nil:
    section.add "X-Amz-Content-Sha256", valid_593292
  var valid_593293 = header.getOrDefault("X-Amz-Date")
  valid_593293 = validateParameter(valid_593293, JString, required = false,
                                 default = nil)
  if valid_593293 != nil:
    section.add "X-Amz-Date", valid_593293
  var valid_593294 = header.getOrDefault("X-Amz-Credential")
  valid_593294 = validateParameter(valid_593294, JString, required = false,
                                 default = nil)
  if valid_593294 != nil:
    section.add "X-Amz-Credential", valid_593294
  var valid_593295 = header.getOrDefault("X-Amz-Security-Token")
  valid_593295 = validateParameter(valid_593295, JString, required = false,
                                 default = nil)
  if valid_593295 != nil:
    section.add "X-Amz-Security-Token", valid_593295
  var valid_593296 = header.getOrDefault("X-Amz-Algorithm")
  valid_593296 = validateParameter(valid_593296, JString, required = false,
                                 default = nil)
  if valid_593296 != nil:
    section.add "X-Amz-Algorithm", valid_593296
  var valid_593297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593297 = validateParameter(valid_593297, JString, required = false,
                                 default = nil)
  if valid_593297 != nil:
    section.add "X-Amz-SignedHeaders", valid_593297
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
  var valid_593298 = formData.getOrDefault("Description")
  valid_593298 = validateParameter(valid_593298, JString, required = false,
                                 default = nil)
  if valid_593298 != nil:
    section.add "Description", valid_593298
  var valid_593299 = formData.getOrDefault("Tier.Type")
  valid_593299 = validateParameter(valid_593299, JString, required = false,
                                 default = nil)
  if valid_593299 != nil:
    section.add "Tier.Type", valid_593299
  var valid_593300 = formData.getOrDefault("EnvironmentName")
  valid_593300 = validateParameter(valid_593300, JString, required = false,
                                 default = nil)
  if valid_593300 != nil:
    section.add "EnvironmentName", valid_593300
  var valid_593301 = formData.getOrDefault("CNAMEPrefix")
  valid_593301 = validateParameter(valid_593301, JString, required = false,
                                 default = nil)
  if valid_593301 != nil:
    section.add "CNAMEPrefix", valid_593301
  var valid_593302 = formData.getOrDefault("VersionLabel")
  valid_593302 = validateParameter(valid_593302, JString, required = false,
                                 default = nil)
  if valid_593302 != nil:
    section.add "VersionLabel", valid_593302
  var valid_593303 = formData.getOrDefault("TemplateName")
  valid_593303 = validateParameter(valid_593303, JString, required = false,
                                 default = nil)
  if valid_593303 != nil:
    section.add "TemplateName", valid_593303
  var valid_593304 = formData.getOrDefault("OptionsToRemove")
  valid_593304 = validateParameter(valid_593304, JArray, required = false,
                                 default = nil)
  if valid_593304 != nil:
    section.add "OptionsToRemove", valid_593304
  var valid_593305 = formData.getOrDefault("OptionSettings")
  valid_593305 = validateParameter(valid_593305, JArray, required = false,
                                 default = nil)
  if valid_593305 != nil:
    section.add "OptionSettings", valid_593305
  var valid_593306 = formData.getOrDefault("GroupName")
  valid_593306 = validateParameter(valid_593306, JString, required = false,
                                 default = nil)
  if valid_593306 != nil:
    section.add "GroupName", valid_593306
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_593307 = formData.getOrDefault("ApplicationName")
  valid_593307 = validateParameter(valid_593307, JString, required = true,
                                 default = nil)
  if valid_593307 != nil:
    section.add "ApplicationName", valid_593307
  var valid_593308 = formData.getOrDefault("Tier.Name")
  valid_593308 = validateParameter(valid_593308, JString, required = false,
                                 default = nil)
  if valid_593308 != nil:
    section.add "Tier.Name", valid_593308
  var valid_593309 = formData.getOrDefault("Tier.Version")
  valid_593309 = validateParameter(valid_593309, JString, required = false,
                                 default = nil)
  if valid_593309 != nil:
    section.add "Tier.Version", valid_593309
  var valid_593310 = formData.getOrDefault("Tags")
  valid_593310 = validateParameter(valid_593310, JArray, required = false,
                                 default = nil)
  if valid_593310 != nil:
    section.add "Tags", valid_593310
  var valid_593311 = formData.getOrDefault("SolutionStackName")
  valid_593311 = validateParameter(valid_593311, JString, required = false,
                                 default = nil)
  if valid_593311 != nil:
    section.add "SolutionStackName", valid_593311
  var valid_593312 = formData.getOrDefault("PlatformArn")
  valid_593312 = validateParameter(valid_593312, JString, required = false,
                                 default = nil)
  if valid_593312 != nil:
    section.add "PlatformArn", valid_593312
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593313: Call_PostCreateEnvironment_593286; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Launches an environment for the specified application using the specified configuration.
  ## 
  let valid = call_593313.validator(path, query, header, formData, body)
  let scheme = call_593313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593313.url(scheme.get, call_593313.host, call_593313.base,
                         call_593313.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593313, url, valid)

proc call*(call_593314: Call_PostCreateEnvironment_593286; ApplicationName: string;
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
  var query_593315 = newJObject()
  var formData_593316 = newJObject()
  add(formData_593316, "Description", newJString(Description))
  add(formData_593316, "Tier.Type", newJString(TierType))
  add(formData_593316, "EnvironmentName", newJString(EnvironmentName))
  add(formData_593316, "CNAMEPrefix", newJString(CNAMEPrefix))
  add(formData_593316, "VersionLabel", newJString(VersionLabel))
  add(formData_593316, "TemplateName", newJString(TemplateName))
  if OptionsToRemove != nil:
    formData_593316.add "OptionsToRemove", OptionsToRemove
  if OptionSettings != nil:
    formData_593316.add "OptionSettings", OptionSettings
  add(formData_593316, "GroupName", newJString(GroupName))
  add(formData_593316, "ApplicationName", newJString(ApplicationName))
  add(formData_593316, "Tier.Name", newJString(TierName))
  add(formData_593316, "Tier.Version", newJString(TierVersion))
  add(query_593315, "Action", newJString(Action))
  if Tags != nil:
    formData_593316.add "Tags", Tags
  add(formData_593316, "SolutionStackName", newJString(SolutionStackName))
  add(query_593315, "Version", newJString(Version))
  add(formData_593316, "PlatformArn", newJString(PlatformArn))
  result = call_593314.call(nil, query_593315, nil, formData_593316, nil)

var postCreateEnvironment* = Call_PostCreateEnvironment_593286(
    name: "postCreateEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateEnvironment",
    validator: validate_PostCreateEnvironment_593287, base: "/",
    url: url_PostCreateEnvironment_593288, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEnvironment_593256 = ref object of OpenApiRestCall_592365
proc url_GetCreateEnvironment_593258(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateEnvironment_593257(path: JsonNode; query: JsonNode;
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
  var valid_593259 = query.getOrDefault("ApplicationName")
  valid_593259 = validateParameter(valid_593259, JString, required = true,
                                 default = nil)
  if valid_593259 != nil:
    section.add "ApplicationName", valid_593259
  var valid_593260 = query.getOrDefault("CNAMEPrefix")
  valid_593260 = validateParameter(valid_593260, JString, required = false,
                                 default = nil)
  if valid_593260 != nil:
    section.add "CNAMEPrefix", valid_593260
  var valid_593261 = query.getOrDefault("GroupName")
  valid_593261 = validateParameter(valid_593261, JString, required = false,
                                 default = nil)
  if valid_593261 != nil:
    section.add "GroupName", valid_593261
  var valid_593262 = query.getOrDefault("Tags")
  valid_593262 = validateParameter(valid_593262, JArray, required = false,
                                 default = nil)
  if valid_593262 != nil:
    section.add "Tags", valid_593262
  var valid_593263 = query.getOrDefault("VersionLabel")
  valid_593263 = validateParameter(valid_593263, JString, required = false,
                                 default = nil)
  if valid_593263 != nil:
    section.add "VersionLabel", valid_593263
  var valid_593264 = query.getOrDefault("OptionSettings")
  valid_593264 = validateParameter(valid_593264, JArray, required = false,
                                 default = nil)
  if valid_593264 != nil:
    section.add "OptionSettings", valid_593264
  var valid_593265 = query.getOrDefault("SolutionStackName")
  valid_593265 = validateParameter(valid_593265, JString, required = false,
                                 default = nil)
  if valid_593265 != nil:
    section.add "SolutionStackName", valid_593265
  var valid_593266 = query.getOrDefault("Tier.Name")
  valid_593266 = validateParameter(valid_593266, JString, required = false,
                                 default = nil)
  if valid_593266 != nil:
    section.add "Tier.Name", valid_593266
  var valid_593267 = query.getOrDefault("EnvironmentName")
  valid_593267 = validateParameter(valid_593267, JString, required = false,
                                 default = nil)
  if valid_593267 != nil:
    section.add "EnvironmentName", valid_593267
  var valid_593268 = query.getOrDefault("Action")
  valid_593268 = validateParameter(valid_593268, JString, required = true,
                                 default = newJString("CreateEnvironment"))
  if valid_593268 != nil:
    section.add "Action", valid_593268
  var valid_593269 = query.getOrDefault("Description")
  valid_593269 = validateParameter(valid_593269, JString, required = false,
                                 default = nil)
  if valid_593269 != nil:
    section.add "Description", valid_593269
  var valid_593270 = query.getOrDefault("PlatformArn")
  valid_593270 = validateParameter(valid_593270, JString, required = false,
                                 default = nil)
  if valid_593270 != nil:
    section.add "PlatformArn", valid_593270
  var valid_593271 = query.getOrDefault("OptionsToRemove")
  valid_593271 = validateParameter(valid_593271, JArray, required = false,
                                 default = nil)
  if valid_593271 != nil:
    section.add "OptionsToRemove", valid_593271
  var valid_593272 = query.getOrDefault("Version")
  valid_593272 = validateParameter(valid_593272, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593272 != nil:
    section.add "Version", valid_593272
  var valid_593273 = query.getOrDefault("TemplateName")
  valid_593273 = validateParameter(valid_593273, JString, required = false,
                                 default = nil)
  if valid_593273 != nil:
    section.add "TemplateName", valid_593273
  var valid_593274 = query.getOrDefault("Tier.Version")
  valid_593274 = validateParameter(valid_593274, JString, required = false,
                                 default = nil)
  if valid_593274 != nil:
    section.add "Tier.Version", valid_593274
  var valid_593275 = query.getOrDefault("Tier.Type")
  valid_593275 = validateParameter(valid_593275, JString, required = false,
                                 default = nil)
  if valid_593275 != nil:
    section.add "Tier.Type", valid_593275
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
  var valid_593276 = header.getOrDefault("X-Amz-Signature")
  valid_593276 = validateParameter(valid_593276, JString, required = false,
                                 default = nil)
  if valid_593276 != nil:
    section.add "X-Amz-Signature", valid_593276
  var valid_593277 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593277 = validateParameter(valid_593277, JString, required = false,
                                 default = nil)
  if valid_593277 != nil:
    section.add "X-Amz-Content-Sha256", valid_593277
  var valid_593278 = header.getOrDefault("X-Amz-Date")
  valid_593278 = validateParameter(valid_593278, JString, required = false,
                                 default = nil)
  if valid_593278 != nil:
    section.add "X-Amz-Date", valid_593278
  var valid_593279 = header.getOrDefault("X-Amz-Credential")
  valid_593279 = validateParameter(valid_593279, JString, required = false,
                                 default = nil)
  if valid_593279 != nil:
    section.add "X-Amz-Credential", valid_593279
  var valid_593280 = header.getOrDefault("X-Amz-Security-Token")
  valid_593280 = validateParameter(valid_593280, JString, required = false,
                                 default = nil)
  if valid_593280 != nil:
    section.add "X-Amz-Security-Token", valid_593280
  var valid_593281 = header.getOrDefault("X-Amz-Algorithm")
  valid_593281 = validateParameter(valid_593281, JString, required = false,
                                 default = nil)
  if valid_593281 != nil:
    section.add "X-Amz-Algorithm", valid_593281
  var valid_593282 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593282 = validateParameter(valid_593282, JString, required = false,
                                 default = nil)
  if valid_593282 != nil:
    section.add "X-Amz-SignedHeaders", valid_593282
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593283: Call_GetCreateEnvironment_593256; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Launches an environment for the specified application using the specified configuration.
  ## 
  let valid = call_593283.validator(path, query, header, formData, body)
  let scheme = call_593283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593283.url(scheme.get, call_593283.host, call_593283.base,
                         call_593283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593283, url, valid)

proc call*(call_593284: Call_GetCreateEnvironment_593256; ApplicationName: string;
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
  var query_593285 = newJObject()
  add(query_593285, "ApplicationName", newJString(ApplicationName))
  add(query_593285, "CNAMEPrefix", newJString(CNAMEPrefix))
  add(query_593285, "GroupName", newJString(GroupName))
  if Tags != nil:
    query_593285.add "Tags", Tags
  add(query_593285, "VersionLabel", newJString(VersionLabel))
  if OptionSettings != nil:
    query_593285.add "OptionSettings", OptionSettings
  add(query_593285, "SolutionStackName", newJString(SolutionStackName))
  add(query_593285, "Tier.Name", newJString(TierName))
  add(query_593285, "EnvironmentName", newJString(EnvironmentName))
  add(query_593285, "Action", newJString(Action))
  add(query_593285, "Description", newJString(Description))
  add(query_593285, "PlatformArn", newJString(PlatformArn))
  if OptionsToRemove != nil:
    query_593285.add "OptionsToRemove", OptionsToRemove
  add(query_593285, "Version", newJString(Version))
  add(query_593285, "TemplateName", newJString(TemplateName))
  add(query_593285, "Tier.Version", newJString(TierVersion))
  add(query_593285, "Tier.Type", newJString(TierType))
  result = call_593284.call(nil, query_593285, nil, nil, nil)

var getCreateEnvironment* = Call_GetCreateEnvironment_593256(
    name: "getCreateEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateEnvironment",
    validator: validate_GetCreateEnvironment_593257, base: "/",
    url: url_GetCreateEnvironment_593258, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreatePlatformVersion_593339 = ref object of OpenApiRestCall_592365
proc url_PostCreatePlatformVersion_593341(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreatePlatformVersion_593340(path: JsonNode; query: JsonNode;
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
  var valid_593342 = query.getOrDefault("Action")
  valid_593342 = validateParameter(valid_593342, JString, required = true,
                                 default = newJString("CreatePlatformVersion"))
  if valid_593342 != nil:
    section.add "Action", valid_593342
  var valid_593343 = query.getOrDefault("Version")
  valid_593343 = validateParameter(valid_593343, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593343 != nil:
    section.add "Version", valid_593343
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
  var valid_593344 = header.getOrDefault("X-Amz-Signature")
  valid_593344 = validateParameter(valid_593344, JString, required = false,
                                 default = nil)
  if valid_593344 != nil:
    section.add "X-Amz-Signature", valid_593344
  var valid_593345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593345 = validateParameter(valid_593345, JString, required = false,
                                 default = nil)
  if valid_593345 != nil:
    section.add "X-Amz-Content-Sha256", valid_593345
  var valid_593346 = header.getOrDefault("X-Amz-Date")
  valid_593346 = validateParameter(valid_593346, JString, required = false,
                                 default = nil)
  if valid_593346 != nil:
    section.add "X-Amz-Date", valid_593346
  var valid_593347 = header.getOrDefault("X-Amz-Credential")
  valid_593347 = validateParameter(valid_593347, JString, required = false,
                                 default = nil)
  if valid_593347 != nil:
    section.add "X-Amz-Credential", valid_593347
  var valid_593348 = header.getOrDefault("X-Amz-Security-Token")
  valid_593348 = validateParameter(valid_593348, JString, required = false,
                                 default = nil)
  if valid_593348 != nil:
    section.add "X-Amz-Security-Token", valid_593348
  var valid_593349 = header.getOrDefault("X-Amz-Algorithm")
  valid_593349 = validateParameter(valid_593349, JString, required = false,
                                 default = nil)
  if valid_593349 != nil:
    section.add "X-Amz-Algorithm", valid_593349
  var valid_593350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593350 = validateParameter(valid_593350, JString, required = false,
                                 default = nil)
  if valid_593350 != nil:
    section.add "X-Amz-SignedHeaders", valid_593350
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
  var valid_593351 = formData.getOrDefault("EnvironmentName")
  valid_593351 = validateParameter(valid_593351, JString, required = false,
                                 default = nil)
  if valid_593351 != nil:
    section.add "EnvironmentName", valid_593351
  var valid_593352 = formData.getOrDefault("PlatformDefinitionBundle.S3Key")
  valid_593352 = validateParameter(valid_593352, JString, required = false,
                                 default = nil)
  if valid_593352 != nil:
    section.add "PlatformDefinitionBundle.S3Key", valid_593352
  assert formData != nil, "formData argument is necessary due to required `PlatformVersion` field"
  var valid_593353 = formData.getOrDefault("PlatformVersion")
  valid_593353 = validateParameter(valid_593353, JString, required = true,
                                 default = nil)
  if valid_593353 != nil:
    section.add "PlatformVersion", valid_593353
  var valid_593354 = formData.getOrDefault("OptionSettings")
  valid_593354 = validateParameter(valid_593354, JArray, required = false,
                                 default = nil)
  if valid_593354 != nil:
    section.add "OptionSettings", valid_593354
  var valid_593355 = formData.getOrDefault("Tags")
  valid_593355 = validateParameter(valid_593355, JArray, required = false,
                                 default = nil)
  if valid_593355 != nil:
    section.add "Tags", valid_593355
  var valid_593356 = formData.getOrDefault("PlatformDefinitionBundle.S3Bucket")
  valid_593356 = validateParameter(valid_593356, JString, required = false,
                                 default = nil)
  if valid_593356 != nil:
    section.add "PlatformDefinitionBundle.S3Bucket", valid_593356
  var valid_593357 = formData.getOrDefault("PlatformName")
  valid_593357 = validateParameter(valid_593357, JString, required = true,
                                 default = nil)
  if valid_593357 != nil:
    section.add "PlatformName", valid_593357
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593358: Call_PostCreatePlatformVersion_593339; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new version of your custom platform.
  ## 
  let valid = call_593358.validator(path, query, header, formData, body)
  let scheme = call_593358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593358.url(scheme.get, call_593358.host, call_593358.base,
                         call_593358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593358, url, valid)

proc call*(call_593359: Call_PostCreatePlatformVersion_593339;
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
  var query_593360 = newJObject()
  var formData_593361 = newJObject()
  add(formData_593361, "EnvironmentName", newJString(EnvironmentName))
  add(formData_593361, "PlatformDefinitionBundle.S3Key",
      newJString(PlatformDefinitionBundleS3Key))
  add(formData_593361, "PlatformVersion", newJString(PlatformVersion))
  if OptionSettings != nil:
    formData_593361.add "OptionSettings", OptionSettings
  add(query_593360, "Action", newJString(Action))
  if Tags != nil:
    formData_593361.add "Tags", Tags
  add(formData_593361, "PlatformDefinitionBundle.S3Bucket",
      newJString(PlatformDefinitionBundleS3Bucket))
  add(query_593360, "Version", newJString(Version))
  add(formData_593361, "PlatformName", newJString(PlatformName))
  result = call_593359.call(nil, query_593360, nil, formData_593361, nil)

var postCreatePlatformVersion* = Call_PostCreatePlatformVersion_593339(
    name: "postCreatePlatformVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreatePlatformVersion",
    validator: validate_PostCreatePlatformVersion_593340, base: "/",
    url: url_PostCreatePlatformVersion_593341,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreatePlatformVersion_593317 = ref object of OpenApiRestCall_592365
proc url_GetCreatePlatformVersion_593319(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreatePlatformVersion_593318(path: JsonNode; query: JsonNode;
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
  var valid_593320 = query.getOrDefault("PlatformName")
  valid_593320 = validateParameter(valid_593320, JString, required = true,
                                 default = nil)
  if valid_593320 != nil:
    section.add "PlatformName", valid_593320
  var valid_593321 = query.getOrDefault("PlatformVersion")
  valid_593321 = validateParameter(valid_593321, JString, required = true,
                                 default = nil)
  if valid_593321 != nil:
    section.add "PlatformVersion", valid_593321
  var valid_593322 = query.getOrDefault("Tags")
  valid_593322 = validateParameter(valid_593322, JArray, required = false,
                                 default = nil)
  if valid_593322 != nil:
    section.add "Tags", valid_593322
  var valid_593323 = query.getOrDefault("OptionSettings")
  valid_593323 = validateParameter(valid_593323, JArray, required = false,
                                 default = nil)
  if valid_593323 != nil:
    section.add "OptionSettings", valid_593323
  var valid_593324 = query.getOrDefault("PlatformDefinitionBundle.S3Bucket")
  valid_593324 = validateParameter(valid_593324, JString, required = false,
                                 default = nil)
  if valid_593324 != nil:
    section.add "PlatformDefinitionBundle.S3Bucket", valid_593324
  var valid_593325 = query.getOrDefault("EnvironmentName")
  valid_593325 = validateParameter(valid_593325, JString, required = false,
                                 default = nil)
  if valid_593325 != nil:
    section.add "EnvironmentName", valid_593325
  var valid_593326 = query.getOrDefault("Action")
  valid_593326 = validateParameter(valid_593326, JString, required = true,
                                 default = newJString("CreatePlatformVersion"))
  if valid_593326 != nil:
    section.add "Action", valid_593326
  var valid_593327 = query.getOrDefault("PlatformDefinitionBundle.S3Key")
  valid_593327 = validateParameter(valid_593327, JString, required = false,
                                 default = nil)
  if valid_593327 != nil:
    section.add "PlatformDefinitionBundle.S3Key", valid_593327
  var valid_593328 = query.getOrDefault("Version")
  valid_593328 = validateParameter(valid_593328, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593328 != nil:
    section.add "Version", valid_593328
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
  var valid_593329 = header.getOrDefault("X-Amz-Signature")
  valid_593329 = validateParameter(valid_593329, JString, required = false,
                                 default = nil)
  if valid_593329 != nil:
    section.add "X-Amz-Signature", valid_593329
  var valid_593330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593330 = validateParameter(valid_593330, JString, required = false,
                                 default = nil)
  if valid_593330 != nil:
    section.add "X-Amz-Content-Sha256", valid_593330
  var valid_593331 = header.getOrDefault("X-Amz-Date")
  valid_593331 = validateParameter(valid_593331, JString, required = false,
                                 default = nil)
  if valid_593331 != nil:
    section.add "X-Amz-Date", valid_593331
  var valid_593332 = header.getOrDefault("X-Amz-Credential")
  valid_593332 = validateParameter(valid_593332, JString, required = false,
                                 default = nil)
  if valid_593332 != nil:
    section.add "X-Amz-Credential", valid_593332
  var valid_593333 = header.getOrDefault("X-Amz-Security-Token")
  valid_593333 = validateParameter(valid_593333, JString, required = false,
                                 default = nil)
  if valid_593333 != nil:
    section.add "X-Amz-Security-Token", valid_593333
  var valid_593334 = header.getOrDefault("X-Amz-Algorithm")
  valid_593334 = validateParameter(valid_593334, JString, required = false,
                                 default = nil)
  if valid_593334 != nil:
    section.add "X-Amz-Algorithm", valid_593334
  var valid_593335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593335 = validateParameter(valid_593335, JString, required = false,
                                 default = nil)
  if valid_593335 != nil:
    section.add "X-Amz-SignedHeaders", valid_593335
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593336: Call_GetCreatePlatformVersion_593317; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new version of your custom platform.
  ## 
  let valid = call_593336.validator(path, query, header, formData, body)
  let scheme = call_593336.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593336.url(scheme.get, call_593336.host, call_593336.base,
                         call_593336.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593336, url, valid)

proc call*(call_593337: Call_GetCreatePlatformVersion_593317; PlatformName: string;
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
  var query_593338 = newJObject()
  add(query_593338, "PlatformName", newJString(PlatformName))
  add(query_593338, "PlatformVersion", newJString(PlatformVersion))
  if Tags != nil:
    query_593338.add "Tags", Tags
  if OptionSettings != nil:
    query_593338.add "OptionSettings", OptionSettings
  add(query_593338, "PlatformDefinitionBundle.S3Bucket",
      newJString(PlatformDefinitionBundleS3Bucket))
  add(query_593338, "EnvironmentName", newJString(EnvironmentName))
  add(query_593338, "Action", newJString(Action))
  add(query_593338, "PlatformDefinitionBundle.S3Key",
      newJString(PlatformDefinitionBundleS3Key))
  add(query_593338, "Version", newJString(Version))
  result = call_593337.call(nil, query_593338, nil, nil, nil)

var getCreatePlatformVersion* = Call_GetCreatePlatformVersion_593317(
    name: "getCreatePlatformVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreatePlatformVersion",
    validator: validate_GetCreatePlatformVersion_593318, base: "/",
    url: url_GetCreatePlatformVersion_593319, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateStorageLocation_593377 = ref object of OpenApiRestCall_592365
proc url_PostCreateStorageLocation_593379(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateStorageLocation_593378(path: JsonNode; query: JsonNode;
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
  var valid_593380 = query.getOrDefault("Action")
  valid_593380 = validateParameter(valid_593380, JString, required = true,
                                 default = newJString("CreateStorageLocation"))
  if valid_593380 != nil:
    section.add "Action", valid_593380
  var valid_593381 = query.getOrDefault("Version")
  valid_593381 = validateParameter(valid_593381, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593381 != nil:
    section.add "Version", valid_593381
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
  var valid_593382 = header.getOrDefault("X-Amz-Signature")
  valid_593382 = validateParameter(valid_593382, JString, required = false,
                                 default = nil)
  if valid_593382 != nil:
    section.add "X-Amz-Signature", valid_593382
  var valid_593383 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593383 = validateParameter(valid_593383, JString, required = false,
                                 default = nil)
  if valid_593383 != nil:
    section.add "X-Amz-Content-Sha256", valid_593383
  var valid_593384 = header.getOrDefault("X-Amz-Date")
  valid_593384 = validateParameter(valid_593384, JString, required = false,
                                 default = nil)
  if valid_593384 != nil:
    section.add "X-Amz-Date", valid_593384
  var valid_593385 = header.getOrDefault("X-Amz-Credential")
  valid_593385 = validateParameter(valid_593385, JString, required = false,
                                 default = nil)
  if valid_593385 != nil:
    section.add "X-Amz-Credential", valid_593385
  var valid_593386 = header.getOrDefault("X-Amz-Security-Token")
  valid_593386 = validateParameter(valid_593386, JString, required = false,
                                 default = nil)
  if valid_593386 != nil:
    section.add "X-Amz-Security-Token", valid_593386
  var valid_593387 = header.getOrDefault("X-Amz-Algorithm")
  valid_593387 = validateParameter(valid_593387, JString, required = false,
                                 default = nil)
  if valid_593387 != nil:
    section.add "X-Amz-Algorithm", valid_593387
  var valid_593388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593388 = validateParameter(valid_593388, JString, required = false,
                                 default = nil)
  if valid_593388 != nil:
    section.add "X-Amz-SignedHeaders", valid_593388
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593389: Call_PostCreateStorageLocation_593377; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ## 
  let valid = call_593389.validator(path, query, header, formData, body)
  let scheme = call_593389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593389.url(scheme.get, call_593389.host, call_593389.base,
                         call_593389.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593389, url, valid)

proc call*(call_593390: Call_PostCreateStorageLocation_593377;
          Action: string = "CreateStorageLocation"; Version: string = "2010-12-01"): Recallable =
  ## postCreateStorageLocation
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593391 = newJObject()
  add(query_593391, "Action", newJString(Action))
  add(query_593391, "Version", newJString(Version))
  result = call_593390.call(nil, query_593391, nil, nil, nil)

var postCreateStorageLocation* = Call_PostCreateStorageLocation_593377(
    name: "postCreateStorageLocation", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateStorageLocation",
    validator: validate_PostCreateStorageLocation_593378, base: "/",
    url: url_PostCreateStorageLocation_593379,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateStorageLocation_593362 = ref object of OpenApiRestCall_592365
proc url_GetCreateStorageLocation_593364(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateStorageLocation_593363(path: JsonNode; query: JsonNode;
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
  var valid_593365 = query.getOrDefault("Action")
  valid_593365 = validateParameter(valid_593365, JString, required = true,
                                 default = newJString("CreateStorageLocation"))
  if valid_593365 != nil:
    section.add "Action", valid_593365
  var valid_593366 = query.getOrDefault("Version")
  valid_593366 = validateParameter(valid_593366, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593366 != nil:
    section.add "Version", valid_593366
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
  var valid_593367 = header.getOrDefault("X-Amz-Signature")
  valid_593367 = validateParameter(valid_593367, JString, required = false,
                                 default = nil)
  if valid_593367 != nil:
    section.add "X-Amz-Signature", valid_593367
  var valid_593368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593368 = validateParameter(valid_593368, JString, required = false,
                                 default = nil)
  if valid_593368 != nil:
    section.add "X-Amz-Content-Sha256", valid_593368
  var valid_593369 = header.getOrDefault("X-Amz-Date")
  valid_593369 = validateParameter(valid_593369, JString, required = false,
                                 default = nil)
  if valid_593369 != nil:
    section.add "X-Amz-Date", valid_593369
  var valid_593370 = header.getOrDefault("X-Amz-Credential")
  valid_593370 = validateParameter(valid_593370, JString, required = false,
                                 default = nil)
  if valid_593370 != nil:
    section.add "X-Amz-Credential", valid_593370
  var valid_593371 = header.getOrDefault("X-Amz-Security-Token")
  valid_593371 = validateParameter(valid_593371, JString, required = false,
                                 default = nil)
  if valid_593371 != nil:
    section.add "X-Amz-Security-Token", valid_593371
  var valid_593372 = header.getOrDefault("X-Amz-Algorithm")
  valid_593372 = validateParameter(valid_593372, JString, required = false,
                                 default = nil)
  if valid_593372 != nil:
    section.add "X-Amz-Algorithm", valid_593372
  var valid_593373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593373 = validateParameter(valid_593373, JString, required = false,
                                 default = nil)
  if valid_593373 != nil:
    section.add "X-Amz-SignedHeaders", valid_593373
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593374: Call_GetCreateStorageLocation_593362; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ## 
  let valid = call_593374.validator(path, query, header, formData, body)
  let scheme = call_593374.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593374.url(scheme.get, call_593374.host, call_593374.base,
                         call_593374.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593374, url, valid)

proc call*(call_593375: Call_GetCreateStorageLocation_593362;
          Action: string = "CreateStorageLocation"; Version: string = "2010-12-01"): Recallable =
  ## getCreateStorageLocation
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593376 = newJObject()
  add(query_593376, "Action", newJString(Action))
  add(query_593376, "Version", newJString(Version))
  result = call_593375.call(nil, query_593376, nil, nil, nil)

var getCreateStorageLocation* = Call_GetCreateStorageLocation_593362(
    name: "getCreateStorageLocation", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateStorageLocation",
    validator: validate_GetCreateStorageLocation_593363, base: "/",
    url: url_GetCreateStorageLocation_593364, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteApplication_593409 = ref object of OpenApiRestCall_592365
proc url_PostDeleteApplication_593411(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteApplication_593410(path: JsonNode; query: JsonNode;
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
  var valid_593412 = query.getOrDefault("Action")
  valid_593412 = validateParameter(valid_593412, JString, required = true,
                                 default = newJString("DeleteApplication"))
  if valid_593412 != nil:
    section.add "Action", valid_593412
  var valid_593413 = query.getOrDefault("Version")
  valid_593413 = validateParameter(valid_593413, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593413 != nil:
    section.add "Version", valid_593413
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
  var valid_593414 = header.getOrDefault("X-Amz-Signature")
  valid_593414 = validateParameter(valid_593414, JString, required = false,
                                 default = nil)
  if valid_593414 != nil:
    section.add "X-Amz-Signature", valid_593414
  var valid_593415 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593415 = validateParameter(valid_593415, JString, required = false,
                                 default = nil)
  if valid_593415 != nil:
    section.add "X-Amz-Content-Sha256", valid_593415
  var valid_593416 = header.getOrDefault("X-Amz-Date")
  valid_593416 = validateParameter(valid_593416, JString, required = false,
                                 default = nil)
  if valid_593416 != nil:
    section.add "X-Amz-Date", valid_593416
  var valid_593417 = header.getOrDefault("X-Amz-Credential")
  valid_593417 = validateParameter(valid_593417, JString, required = false,
                                 default = nil)
  if valid_593417 != nil:
    section.add "X-Amz-Credential", valid_593417
  var valid_593418 = header.getOrDefault("X-Amz-Security-Token")
  valid_593418 = validateParameter(valid_593418, JString, required = false,
                                 default = nil)
  if valid_593418 != nil:
    section.add "X-Amz-Security-Token", valid_593418
  var valid_593419 = header.getOrDefault("X-Amz-Algorithm")
  valid_593419 = validateParameter(valid_593419, JString, required = false,
                                 default = nil)
  if valid_593419 != nil:
    section.add "X-Amz-Algorithm", valid_593419
  var valid_593420 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593420 = validateParameter(valid_593420, JString, required = false,
                                 default = nil)
  if valid_593420 != nil:
    section.add "X-Amz-SignedHeaders", valid_593420
  result.add "header", section
  ## parameters in `formData` object:
  ##   TerminateEnvByForce: JBool
  ##                      : When set to true, running environments will be terminated before deleting the application.
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to delete.
  section = newJObject()
  var valid_593421 = formData.getOrDefault("TerminateEnvByForce")
  valid_593421 = validateParameter(valid_593421, JBool, required = false, default = nil)
  if valid_593421 != nil:
    section.add "TerminateEnvByForce", valid_593421
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_593422 = formData.getOrDefault("ApplicationName")
  valid_593422 = validateParameter(valid_593422, JString, required = true,
                                 default = nil)
  if valid_593422 != nil:
    section.add "ApplicationName", valid_593422
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593423: Call_PostDeleteApplication_593409; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified application along with all associated versions and configurations. The application versions will not be deleted from your Amazon S3 bucket.</p> <note> <p>You cannot delete an application that has a running environment.</p> </note>
  ## 
  let valid = call_593423.validator(path, query, header, formData, body)
  let scheme = call_593423.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593423.url(scheme.get, call_593423.host, call_593423.base,
                         call_593423.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593423, url, valid)

proc call*(call_593424: Call_PostDeleteApplication_593409; ApplicationName: string;
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
  var query_593425 = newJObject()
  var formData_593426 = newJObject()
  add(formData_593426, "TerminateEnvByForce", newJBool(TerminateEnvByForce))
  add(formData_593426, "ApplicationName", newJString(ApplicationName))
  add(query_593425, "Action", newJString(Action))
  add(query_593425, "Version", newJString(Version))
  result = call_593424.call(nil, query_593425, nil, formData_593426, nil)

var postDeleteApplication* = Call_PostDeleteApplication_593409(
    name: "postDeleteApplication", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=DeleteApplication",
    validator: validate_PostDeleteApplication_593410, base: "/",
    url: url_PostDeleteApplication_593411, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteApplication_593392 = ref object of OpenApiRestCall_592365
proc url_GetDeleteApplication_593394(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteApplication_593393(path: JsonNode; query: JsonNode;
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
  var valid_593395 = query.getOrDefault("ApplicationName")
  valid_593395 = validateParameter(valid_593395, JString, required = true,
                                 default = nil)
  if valid_593395 != nil:
    section.add "ApplicationName", valid_593395
  var valid_593396 = query.getOrDefault("Action")
  valid_593396 = validateParameter(valid_593396, JString, required = true,
                                 default = newJString("DeleteApplication"))
  if valid_593396 != nil:
    section.add "Action", valid_593396
  var valid_593397 = query.getOrDefault("TerminateEnvByForce")
  valid_593397 = validateParameter(valid_593397, JBool, required = false, default = nil)
  if valid_593397 != nil:
    section.add "TerminateEnvByForce", valid_593397
  var valid_593398 = query.getOrDefault("Version")
  valid_593398 = validateParameter(valid_593398, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593398 != nil:
    section.add "Version", valid_593398
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
  var valid_593399 = header.getOrDefault("X-Amz-Signature")
  valid_593399 = validateParameter(valid_593399, JString, required = false,
                                 default = nil)
  if valid_593399 != nil:
    section.add "X-Amz-Signature", valid_593399
  var valid_593400 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593400 = validateParameter(valid_593400, JString, required = false,
                                 default = nil)
  if valid_593400 != nil:
    section.add "X-Amz-Content-Sha256", valid_593400
  var valid_593401 = header.getOrDefault("X-Amz-Date")
  valid_593401 = validateParameter(valid_593401, JString, required = false,
                                 default = nil)
  if valid_593401 != nil:
    section.add "X-Amz-Date", valid_593401
  var valid_593402 = header.getOrDefault("X-Amz-Credential")
  valid_593402 = validateParameter(valid_593402, JString, required = false,
                                 default = nil)
  if valid_593402 != nil:
    section.add "X-Amz-Credential", valid_593402
  var valid_593403 = header.getOrDefault("X-Amz-Security-Token")
  valid_593403 = validateParameter(valid_593403, JString, required = false,
                                 default = nil)
  if valid_593403 != nil:
    section.add "X-Amz-Security-Token", valid_593403
  var valid_593404 = header.getOrDefault("X-Amz-Algorithm")
  valid_593404 = validateParameter(valid_593404, JString, required = false,
                                 default = nil)
  if valid_593404 != nil:
    section.add "X-Amz-Algorithm", valid_593404
  var valid_593405 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593405 = validateParameter(valid_593405, JString, required = false,
                                 default = nil)
  if valid_593405 != nil:
    section.add "X-Amz-SignedHeaders", valid_593405
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593406: Call_GetDeleteApplication_593392; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified application along with all associated versions and configurations. The application versions will not be deleted from your Amazon S3 bucket.</p> <note> <p>You cannot delete an application that has a running environment.</p> </note>
  ## 
  let valid = call_593406.validator(path, query, header, formData, body)
  let scheme = call_593406.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593406.url(scheme.get, call_593406.host, call_593406.base,
                         call_593406.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593406, url, valid)

proc call*(call_593407: Call_GetDeleteApplication_593392; ApplicationName: string;
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
  var query_593408 = newJObject()
  add(query_593408, "ApplicationName", newJString(ApplicationName))
  add(query_593408, "Action", newJString(Action))
  add(query_593408, "TerminateEnvByForce", newJBool(TerminateEnvByForce))
  add(query_593408, "Version", newJString(Version))
  result = call_593407.call(nil, query_593408, nil, nil, nil)

var getDeleteApplication* = Call_GetDeleteApplication_593392(
    name: "getDeleteApplication", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=DeleteApplication",
    validator: validate_GetDeleteApplication_593393, base: "/",
    url: url_GetDeleteApplication_593394, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteApplicationVersion_593445 = ref object of OpenApiRestCall_592365
proc url_PostDeleteApplicationVersion_593447(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteApplicationVersion_593446(path: JsonNode; query: JsonNode;
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
  var valid_593448 = query.getOrDefault("Action")
  valid_593448 = validateParameter(valid_593448, JString, required = true, default = newJString(
      "DeleteApplicationVersion"))
  if valid_593448 != nil:
    section.add "Action", valid_593448
  var valid_593449 = query.getOrDefault("Version")
  valid_593449 = validateParameter(valid_593449, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593449 != nil:
    section.add "Version", valid_593449
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
  var valid_593450 = header.getOrDefault("X-Amz-Signature")
  valid_593450 = validateParameter(valid_593450, JString, required = false,
                                 default = nil)
  if valid_593450 != nil:
    section.add "X-Amz-Signature", valid_593450
  var valid_593451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593451 = validateParameter(valid_593451, JString, required = false,
                                 default = nil)
  if valid_593451 != nil:
    section.add "X-Amz-Content-Sha256", valid_593451
  var valid_593452 = header.getOrDefault("X-Amz-Date")
  valid_593452 = validateParameter(valid_593452, JString, required = false,
                                 default = nil)
  if valid_593452 != nil:
    section.add "X-Amz-Date", valid_593452
  var valid_593453 = header.getOrDefault("X-Amz-Credential")
  valid_593453 = validateParameter(valid_593453, JString, required = false,
                                 default = nil)
  if valid_593453 != nil:
    section.add "X-Amz-Credential", valid_593453
  var valid_593454 = header.getOrDefault("X-Amz-Security-Token")
  valid_593454 = validateParameter(valid_593454, JString, required = false,
                                 default = nil)
  if valid_593454 != nil:
    section.add "X-Amz-Security-Token", valid_593454
  var valid_593455 = header.getOrDefault("X-Amz-Algorithm")
  valid_593455 = validateParameter(valid_593455, JString, required = false,
                                 default = nil)
  if valid_593455 != nil:
    section.add "X-Amz-Algorithm", valid_593455
  var valid_593456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593456 = validateParameter(valid_593456, JString, required = false,
                                 default = nil)
  if valid_593456 != nil:
    section.add "X-Amz-SignedHeaders", valid_593456
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
  var valid_593457 = formData.getOrDefault("VersionLabel")
  valid_593457 = validateParameter(valid_593457, JString, required = true,
                                 default = nil)
  if valid_593457 != nil:
    section.add "VersionLabel", valid_593457
  var valid_593458 = formData.getOrDefault("DeleteSourceBundle")
  valid_593458 = validateParameter(valid_593458, JBool, required = false, default = nil)
  if valid_593458 != nil:
    section.add "DeleteSourceBundle", valid_593458
  var valid_593459 = formData.getOrDefault("ApplicationName")
  valid_593459 = validateParameter(valid_593459, JString, required = true,
                                 default = nil)
  if valid_593459 != nil:
    section.add "ApplicationName", valid_593459
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593460: Call_PostDeleteApplicationVersion_593445; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified version from the specified application.</p> <note> <p>You cannot delete an application version that is associated with a running environment.</p> </note>
  ## 
  let valid = call_593460.validator(path, query, header, formData, body)
  let scheme = call_593460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593460.url(scheme.get, call_593460.host, call_593460.base,
                         call_593460.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593460, url, valid)

proc call*(call_593461: Call_PostDeleteApplicationVersion_593445;
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
  var query_593462 = newJObject()
  var formData_593463 = newJObject()
  add(formData_593463, "VersionLabel", newJString(VersionLabel))
  add(formData_593463, "DeleteSourceBundle", newJBool(DeleteSourceBundle))
  add(formData_593463, "ApplicationName", newJString(ApplicationName))
  add(query_593462, "Action", newJString(Action))
  add(query_593462, "Version", newJString(Version))
  result = call_593461.call(nil, query_593462, nil, formData_593463, nil)

var postDeleteApplicationVersion* = Call_PostDeleteApplicationVersion_593445(
    name: "postDeleteApplicationVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteApplicationVersion",
    validator: validate_PostDeleteApplicationVersion_593446, base: "/",
    url: url_PostDeleteApplicationVersion_593447,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteApplicationVersion_593427 = ref object of OpenApiRestCall_592365
proc url_GetDeleteApplicationVersion_593429(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteApplicationVersion_593428(path: JsonNode; query: JsonNode;
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
  var valid_593430 = query.getOrDefault("ApplicationName")
  valid_593430 = validateParameter(valid_593430, JString, required = true,
                                 default = nil)
  if valid_593430 != nil:
    section.add "ApplicationName", valid_593430
  var valid_593431 = query.getOrDefault("VersionLabel")
  valid_593431 = validateParameter(valid_593431, JString, required = true,
                                 default = nil)
  if valid_593431 != nil:
    section.add "VersionLabel", valid_593431
  var valid_593432 = query.getOrDefault("Action")
  valid_593432 = validateParameter(valid_593432, JString, required = true, default = newJString(
      "DeleteApplicationVersion"))
  if valid_593432 != nil:
    section.add "Action", valid_593432
  var valid_593433 = query.getOrDefault("Version")
  valid_593433 = validateParameter(valid_593433, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593433 != nil:
    section.add "Version", valid_593433
  var valid_593434 = query.getOrDefault("DeleteSourceBundle")
  valid_593434 = validateParameter(valid_593434, JBool, required = false, default = nil)
  if valid_593434 != nil:
    section.add "DeleteSourceBundle", valid_593434
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
  var valid_593435 = header.getOrDefault("X-Amz-Signature")
  valid_593435 = validateParameter(valid_593435, JString, required = false,
                                 default = nil)
  if valid_593435 != nil:
    section.add "X-Amz-Signature", valid_593435
  var valid_593436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593436 = validateParameter(valid_593436, JString, required = false,
                                 default = nil)
  if valid_593436 != nil:
    section.add "X-Amz-Content-Sha256", valid_593436
  var valid_593437 = header.getOrDefault("X-Amz-Date")
  valid_593437 = validateParameter(valid_593437, JString, required = false,
                                 default = nil)
  if valid_593437 != nil:
    section.add "X-Amz-Date", valid_593437
  var valid_593438 = header.getOrDefault("X-Amz-Credential")
  valid_593438 = validateParameter(valid_593438, JString, required = false,
                                 default = nil)
  if valid_593438 != nil:
    section.add "X-Amz-Credential", valid_593438
  var valid_593439 = header.getOrDefault("X-Amz-Security-Token")
  valid_593439 = validateParameter(valid_593439, JString, required = false,
                                 default = nil)
  if valid_593439 != nil:
    section.add "X-Amz-Security-Token", valid_593439
  var valid_593440 = header.getOrDefault("X-Amz-Algorithm")
  valid_593440 = validateParameter(valid_593440, JString, required = false,
                                 default = nil)
  if valid_593440 != nil:
    section.add "X-Amz-Algorithm", valid_593440
  var valid_593441 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593441 = validateParameter(valid_593441, JString, required = false,
                                 default = nil)
  if valid_593441 != nil:
    section.add "X-Amz-SignedHeaders", valid_593441
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593442: Call_GetDeleteApplicationVersion_593427; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified version from the specified application.</p> <note> <p>You cannot delete an application version that is associated with a running environment.</p> </note>
  ## 
  let valid = call_593442.validator(path, query, header, formData, body)
  let scheme = call_593442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593442.url(scheme.get, call_593442.host, call_593442.base,
                         call_593442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593442, url, valid)

proc call*(call_593443: Call_GetDeleteApplicationVersion_593427;
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
  var query_593444 = newJObject()
  add(query_593444, "ApplicationName", newJString(ApplicationName))
  add(query_593444, "VersionLabel", newJString(VersionLabel))
  add(query_593444, "Action", newJString(Action))
  add(query_593444, "Version", newJString(Version))
  add(query_593444, "DeleteSourceBundle", newJBool(DeleteSourceBundle))
  result = call_593443.call(nil, query_593444, nil, nil, nil)

var getDeleteApplicationVersion* = Call_GetDeleteApplicationVersion_593427(
    name: "getDeleteApplicationVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteApplicationVersion",
    validator: validate_GetDeleteApplicationVersion_593428, base: "/",
    url: url_GetDeleteApplicationVersion_593429,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteConfigurationTemplate_593481 = ref object of OpenApiRestCall_592365
proc url_PostDeleteConfigurationTemplate_593483(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteConfigurationTemplate_593482(path: JsonNode;
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
  var valid_593484 = query.getOrDefault("Action")
  valid_593484 = validateParameter(valid_593484, JString, required = true, default = newJString(
      "DeleteConfigurationTemplate"))
  if valid_593484 != nil:
    section.add "Action", valid_593484
  var valid_593485 = query.getOrDefault("Version")
  valid_593485 = validateParameter(valid_593485, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593485 != nil:
    section.add "Version", valid_593485
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
  var valid_593486 = header.getOrDefault("X-Amz-Signature")
  valid_593486 = validateParameter(valid_593486, JString, required = false,
                                 default = nil)
  if valid_593486 != nil:
    section.add "X-Amz-Signature", valid_593486
  var valid_593487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593487 = validateParameter(valid_593487, JString, required = false,
                                 default = nil)
  if valid_593487 != nil:
    section.add "X-Amz-Content-Sha256", valid_593487
  var valid_593488 = header.getOrDefault("X-Amz-Date")
  valid_593488 = validateParameter(valid_593488, JString, required = false,
                                 default = nil)
  if valid_593488 != nil:
    section.add "X-Amz-Date", valid_593488
  var valid_593489 = header.getOrDefault("X-Amz-Credential")
  valid_593489 = validateParameter(valid_593489, JString, required = false,
                                 default = nil)
  if valid_593489 != nil:
    section.add "X-Amz-Credential", valid_593489
  var valid_593490 = header.getOrDefault("X-Amz-Security-Token")
  valid_593490 = validateParameter(valid_593490, JString, required = false,
                                 default = nil)
  if valid_593490 != nil:
    section.add "X-Amz-Security-Token", valid_593490
  var valid_593491 = header.getOrDefault("X-Amz-Algorithm")
  valid_593491 = validateParameter(valid_593491, JString, required = false,
                                 default = nil)
  if valid_593491 != nil:
    section.add "X-Amz-Algorithm", valid_593491
  var valid_593492 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593492 = validateParameter(valid_593492, JString, required = false,
                                 default = nil)
  if valid_593492 != nil:
    section.add "X-Amz-SignedHeaders", valid_593492
  result.add "header", section
  ## parameters in `formData` object:
  ##   TemplateName: JString (required)
  ##               : The name of the configuration template to delete.
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to delete the configuration template from.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TemplateName` field"
  var valid_593493 = formData.getOrDefault("TemplateName")
  valid_593493 = validateParameter(valid_593493, JString, required = true,
                                 default = nil)
  if valid_593493 != nil:
    section.add "TemplateName", valid_593493
  var valid_593494 = formData.getOrDefault("ApplicationName")
  valid_593494 = validateParameter(valid_593494, JString, required = true,
                                 default = nil)
  if valid_593494 != nil:
    section.add "ApplicationName", valid_593494
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593495: Call_PostDeleteConfigurationTemplate_593481;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes the specified configuration template.</p> <note> <p>When you launch an environment using a configuration template, the environment gets a copy of the template. You can delete or modify the environment's copy of the template without affecting the running environment.</p> </note>
  ## 
  let valid = call_593495.validator(path, query, header, formData, body)
  let scheme = call_593495.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593495.url(scheme.get, call_593495.host, call_593495.base,
                         call_593495.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593495, url, valid)

proc call*(call_593496: Call_PostDeleteConfigurationTemplate_593481;
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
  var query_593497 = newJObject()
  var formData_593498 = newJObject()
  add(formData_593498, "TemplateName", newJString(TemplateName))
  add(formData_593498, "ApplicationName", newJString(ApplicationName))
  add(query_593497, "Action", newJString(Action))
  add(query_593497, "Version", newJString(Version))
  result = call_593496.call(nil, query_593497, nil, formData_593498, nil)

var postDeleteConfigurationTemplate* = Call_PostDeleteConfigurationTemplate_593481(
    name: "postDeleteConfigurationTemplate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteConfigurationTemplate",
    validator: validate_PostDeleteConfigurationTemplate_593482, base: "/",
    url: url_PostDeleteConfigurationTemplate_593483,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteConfigurationTemplate_593464 = ref object of OpenApiRestCall_592365
proc url_GetDeleteConfigurationTemplate_593466(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteConfigurationTemplate_593465(path: JsonNode;
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
  var valid_593467 = query.getOrDefault("ApplicationName")
  valid_593467 = validateParameter(valid_593467, JString, required = true,
                                 default = nil)
  if valid_593467 != nil:
    section.add "ApplicationName", valid_593467
  var valid_593468 = query.getOrDefault("Action")
  valid_593468 = validateParameter(valid_593468, JString, required = true, default = newJString(
      "DeleteConfigurationTemplate"))
  if valid_593468 != nil:
    section.add "Action", valid_593468
  var valid_593469 = query.getOrDefault("Version")
  valid_593469 = validateParameter(valid_593469, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593469 != nil:
    section.add "Version", valid_593469
  var valid_593470 = query.getOrDefault("TemplateName")
  valid_593470 = validateParameter(valid_593470, JString, required = true,
                                 default = nil)
  if valid_593470 != nil:
    section.add "TemplateName", valid_593470
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
  var valid_593471 = header.getOrDefault("X-Amz-Signature")
  valid_593471 = validateParameter(valid_593471, JString, required = false,
                                 default = nil)
  if valid_593471 != nil:
    section.add "X-Amz-Signature", valid_593471
  var valid_593472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593472 = validateParameter(valid_593472, JString, required = false,
                                 default = nil)
  if valid_593472 != nil:
    section.add "X-Amz-Content-Sha256", valid_593472
  var valid_593473 = header.getOrDefault("X-Amz-Date")
  valid_593473 = validateParameter(valid_593473, JString, required = false,
                                 default = nil)
  if valid_593473 != nil:
    section.add "X-Amz-Date", valid_593473
  var valid_593474 = header.getOrDefault("X-Amz-Credential")
  valid_593474 = validateParameter(valid_593474, JString, required = false,
                                 default = nil)
  if valid_593474 != nil:
    section.add "X-Amz-Credential", valid_593474
  var valid_593475 = header.getOrDefault("X-Amz-Security-Token")
  valid_593475 = validateParameter(valid_593475, JString, required = false,
                                 default = nil)
  if valid_593475 != nil:
    section.add "X-Amz-Security-Token", valid_593475
  var valid_593476 = header.getOrDefault("X-Amz-Algorithm")
  valid_593476 = validateParameter(valid_593476, JString, required = false,
                                 default = nil)
  if valid_593476 != nil:
    section.add "X-Amz-Algorithm", valid_593476
  var valid_593477 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593477 = validateParameter(valid_593477, JString, required = false,
                                 default = nil)
  if valid_593477 != nil:
    section.add "X-Amz-SignedHeaders", valid_593477
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593478: Call_GetDeleteConfigurationTemplate_593464; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified configuration template.</p> <note> <p>When you launch an environment using a configuration template, the environment gets a copy of the template. You can delete or modify the environment's copy of the template without affecting the running environment.</p> </note>
  ## 
  let valid = call_593478.validator(path, query, header, formData, body)
  let scheme = call_593478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593478.url(scheme.get, call_593478.host, call_593478.base,
                         call_593478.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593478, url, valid)

proc call*(call_593479: Call_GetDeleteConfigurationTemplate_593464;
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
  var query_593480 = newJObject()
  add(query_593480, "ApplicationName", newJString(ApplicationName))
  add(query_593480, "Action", newJString(Action))
  add(query_593480, "Version", newJString(Version))
  add(query_593480, "TemplateName", newJString(TemplateName))
  result = call_593479.call(nil, query_593480, nil, nil, nil)

var getDeleteConfigurationTemplate* = Call_GetDeleteConfigurationTemplate_593464(
    name: "getDeleteConfigurationTemplate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteConfigurationTemplate",
    validator: validate_GetDeleteConfigurationTemplate_593465, base: "/",
    url: url_GetDeleteConfigurationTemplate_593466,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEnvironmentConfiguration_593516 = ref object of OpenApiRestCall_592365
proc url_PostDeleteEnvironmentConfiguration_593518(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteEnvironmentConfiguration_593517(path: JsonNode;
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
  var valid_593519 = query.getOrDefault("Action")
  valid_593519 = validateParameter(valid_593519, JString, required = true, default = newJString(
      "DeleteEnvironmentConfiguration"))
  if valid_593519 != nil:
    section.add "Action", valid_593519
  var valid_593520 = query.getOrDefault("Version")
  valid_593520 = validateParameter(valid_593520, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593520 != nil:
    section.add "Version", valid_593520
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
  var valid_593521 = header.getOrDefault("X-Amz-Signature")
  valid_593521 = validateParameter(valid_593521, JString, required = false,
                                 default = nil)
  if valid_593521 != nil:
    section.add "X-Amz-Signature", valid_593521
  var valid_593522 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593522 = validateParameter(valid_593522, JString, required = false,
                                 default = nil)
  if valid_593522 != nil:
    section.add "X-Amz-Content-Sha256", valid_593522
  var valid_593523 = header.getOrDefault("X-Amz-Date")
  valid_593523 = validateParameter(valid_593523, JString, required = false,
                                 default = nil)
  if valid_593523 != nil:
    section.add "X-Amz-Date", valid_593523
  var valid_593524 = header.getOrDefault("X-Amz-Credential")
  valid_593524 = validateParameter(valid_593524, JString, required = false,
                                 default = nil)
  if valid_593524 != nil:
    section.add "X-Amz-Credential", valid_593524
  var valid_593525 = header.getOrDefault("X-Amz-Security-Token")
  valid_593525 = validateParameter(valid_593525, JString, required = false,
                                 default = nil)
  if valid_593525 != nil:
    section.add "X-Amz-Security-Token", valid_593525
  var valid_593526 = header.getOrDefault("X-Amz-Algorithm")
  valid_593526 = validateParameter(valid_593526, JString, required = false,
                                 default = nil)
  if valid_593526 != nil:
    section.add "X-Amz-Algorithm", valid_593526
  var valid_593527 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593527 = validateParameter(valid_593527, JString, required = false,
                                 default = nil)
  if valid_593527 != nil:
    section.add "X-Amz-SignedHeaders", valid_593527
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString (required)
  ##                  : The name of the environment to delete the draft configuration from.
  ##   ApplicationName: JString (required)
  ##                  : The name of the application the environment is associated with.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `EnvironmentName` field"
  var valid_593528 = formData.getOrDefault("EnvironmentName")
  valid_593528 = validateParameter(valid_593528, JString, required = true,
                                 default = nil)
  if valid_593528 != nil:
    section.add "EnvironmentName", valid_593528
  var valid_593529 = formData.getOrDefault("ApplicationName")
  valid_593529 = validateParameter(valid_593529, JString, required = true,
                                 default = nil)
  if valid_593529 != nil:
    section.add "ApplicationName", valid_593529
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593530: Call_PostDeleteEnvironmentConfiguration_593516;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes the draft configuration associated with the running environment.</p> <p>Updating a running environment with any configuration changes creates a draft configuration set. You can get the draft configuration using <a>DescribeConfigurationSettings</a> while the update is in progress or if the update fails. The <code>DeploymentStatus</code> for the draft configuration indicates whether the deployment is in process or has failed. The draft configuration remains in existence until it is deleted with this action.</p>
  ## 
  let valid = call_593530.validator(path, query, header, formData, body)
  let scheme = call_593530.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593530.url(scheme.get, call_593530.host, call_593530.base,
                         call_593530.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593530, url, valid)

proc call*(call_593531: Call_PostDeleteEnvironmentConfiguration_593516;
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
  var query_593532 = newJObject()
  var formData_593533 = newJObject()
  add(formData_593533, "EnvironmentName", newJString(EnvironmentName))
  add(formData_593533, "ApplicationName", newJString(ApplicationName))
  add(query_593532, "Action", newJString(Action))
  add(query_593532, "Version", newJString(Version))
  result = call_593531.call(nil, query_593532, nil, formData_593533, nil)

var postDeleteEnvironmentConfiguration* = Call_PostDeleteEnvironmentConfiguration_593516(
    name: "postDeleteEnvironmentConfiguration", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteEnvironmentConfiguration",
    validator: validate_PostDeleteEnvironmentConfiguration_593517, base: "/",
    url: url_PostDeleteEnvironmentConfiguration_593518,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEnvironmentConfiguration_593499 = ref object of OpenApiRestCall_592365
proc url_GetDeleteEnvironmentConfiguration_593501(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteEnvironmentConfiguration_593500(path: JsonNode;
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
  var valid_593502 = query.getOrDefault("ApplicationName")
  valid_593502 = validateParameter(valid_593502, JString, required = true,
                                 default = nil)
  if valid_593502 != nil:
    section.add "ApplicationName", valid_593502
  var valid_593503 = query.getOrDefault("EnvironmentName")
  valid_593503 = validateParameter(valid_593503, JString, required = true,
                                 default = nil)
  if valid_593503 != nil:
    section.add "EnvironmentName", valid_593503
  var valid_593504 = query.getOrDefault("Action")
  valid_593504 = validateParameter(valid_593504, JString, required = true, default = newJString(
      "DeleteEnvironmentConfiguration"))
  if valid_593504 != nil:
    section.add "Action", valid_593504
  var valid_593505 = query.getOrDefault("Version")
  valid_593505 = validateParameter(valid_593505, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593505 != nil:
    section.add "Version", valid_593505
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
  var valid_593506 = header.getOrDefault("X-Amz-Signature")
  valid_593506 = validateParameter(valid_593506, JString, required = false,
                                 default = nil)
  if valid_593506 != nil:
    section.add "X-Amz-Signature", valid_593506
  var valid_593507 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593507 = validateParameter(valid_593507, JString, required = false,
                                 default = nil)
  if valid_593507 != nil:
    section.add "X-Amz-Content-Sha256", valid_593507
  var valid_593508 = header.getOrDefault("X-Amz-Date")
  valid_593508 = validateParameter(valid_593508, JString, required = false,
                                 default = nil)
  if valid_593508 != nil:
    section.add "X-Amz-Date", valid_593508
  var valid_593509 = header.getOrDefault("X-Amz-Credential")
  valid_593509 = validateParameter(valid_593509, JString, required = false,
                                 default = nil)
  if valid_593509 != nil:
    section.add "X-Amz-Credential", valid_593509
  var valid_593510 = header.getOrDefault("X-Amz-Security-Token")
  valid_593510 = validateParameter(valid_593510, JString, required = false,
                                 default = nil)
  if valid_593510 != nil:
    section.add "X-Amz-Security-Token", valid_593510
  var valid_593511 = header.getOrDefault("X-Amz-Algorithm")
  valid_593511 = validateParameter(valid_593511, JString, required = false,
                                 default = nil)
  if valid_593511 != nil:
    section.add "X-Amz-Algorithm", valid_593511
  var valid_593512 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593512 = validateParameter(valid_593512, JString, required = false,
                                 default = nil)
  if valid_593512 != nil:
    section.add "X-Amz-SignedHeaders", valid_593512
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593513: Call_GetDeleteEnvironmentConfiguration_593499;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes the draft configuration associated with the running environment.</p> <p>Updating a running environment with any configuration changes creates a draft configuration set. You can get the draft configuration using <a>DescribeConfigurationSettings</a> while the update is in progress or if the update fails. The <code>DeploymentStatus</code> for the draft configuration indicates whether the deployment is in process or has failed. The draft configuration remains in existence until it is deleted with this action.</p>
  ## 
  let valid = call_593513.validator(path, query, header, formData, body)
  let scheme = call_593513.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593513.url(scheme.get, call_593513.host, call_593513.base,
                         call_593513.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593513, url, valid)

proc call*(call_593514: Call_GetDeleteEnvironmentConfiguration_593499;
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
  var query_593515 = newJObject()
  add(query_593515, "ApplicationName", newJString(ApplicationName))
  add(query_593515, "EnvironmentName", newJString(EnvironmentName))
  add(query_593515, "Action", newJString(Action))
  add(query_593515, "Version", newJString(Version))
  result = call_593514.call(nil, query_593515, nil, nil, nil)

var getDeleteEnvironmentConfiguration* = Call_GetDeleteEnvironmentConfiguration_593499(
    name: "getDeleteEnvironmentConfiguration", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteEnvironmentConfiguration",
    validator: validate_GetDeleteEnvironmentConfiguration_593500, base: "/",
    url: url_GetDeleteEnvironmentConfiguration_593501,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeletePlatformVersion_593550 = ref object of OpenApiRestCall_592365
proc url_PostDeletePlatformVersion_593552(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeletePlatformVersion_593551(path: JsonNode; query: JsonNode;
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
  var valid_593553 = query.getOrDefault("Action")
  valid_593553 = validateParameter(valid_593553, JString, required = true,
                                 default = newJString("DeletePlatformVersion"))
  if valid_593553 != nil:
    section.add "Action", valid_593553
  var valid_593554 = query.getOrDefault("Version")
  valid_593554 = validateParameter(valid_593554, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593554 != nil:
    section.add "Version", valid_593554
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
  var valid_593555 = header.getOrDefault("X-Amz-Signature")
  valid_593555 = validateParameter(valid_593555, JString, required = false,
                                 default = nil)
  if valid_593555 != nil:
    section.add "X-Amz-Signature", valid_593555
  var valid_593556 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593556 = validateParameter(valid_593556, JString, required = false,
                                 default = nil)
  if valid_593556 != nil:
    section.add "X-Amz-Content-Sha256", valid_593556
  var valid_593557 = header.getOrDefault("X-Amz-Date")
  valid_593557 = validateParameter(valid_593557, JString, required = false,
                                 default = nil)
  if valid_593557 != nil:
    section.add "X-Amz-Date", valid_593557
  var valid_593558 = header.getOrDefault("X-Amz-Credential")
  valid_593558 = validateParameter(valid_593558, JString, required = false,
                                 default = nil)
  if valid_593558 != nil:
    section.add "X-Amz-Credential", valid_593558
  var valid_593559 = header.getOrDefault("X-Amz-Security-Token")
  valid_593559 = validateParameter(valid_593559, JString, required = false,
                                 default = nil)
  if valid_593559 != nil:
    section.add "X-Amz-Security-Token", valid_593559
  var valid_593560 = header.getOrDefault("X-Amz-Algorithm")
  valid_593560 = validateParameter(valid_593560, JString, required = false,
                                 default = nil)
  if valid_593560 != nil:
    section.add "X-Amz-Algorithm", valid_593560
  var valid_593561 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593561 = validateParameter(valid_593561, JString, required = false,
                                 default = nil)
  if valid_593561 != nil:
    section.add "X-Amz-SignedHeaders", valid_593561
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformArn: JString
  ##              : The ARN of the version of the custom platform.
  section = newJObject()
  var valid_593562 = formData.getOrDefault("PlatformArn")
  valid_593562 = validateParameter(valid_593562, JString, required = false,
                                 default = nil)
  if valid_593562 != nil:
    section.add "PlatformArn", valid_593562
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593563: Call_PostDeletePlatformVersion_593550; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified version of a custom platform.
  ## 
  let valid = call_593563.validator(path, query, header, formData, body)
  let scheme = call_593563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593563.url(scheme.get, call_593563.host, call_593563.base,
                         call_593563.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593563, url, valid)

proc call*(call_593564: Call_PostDeletePlatformVersion_593550;
          Action: string = "DeletePlatformVersion"; Version: string = "2010-12-01";
          PlatformArn: string = ""): Recallable =
  ## postDeletePlatformVersion
  ## Deletes the specified version of a custom platform.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PlatformArn: string
  ##              : The ARN of the version of the custom platform.
  var query_593565 = newJObject()
  var formData_593566 = newJObject()
  add(query_593565, "Action", newJString(Action))
  add(query_593565, "Version", newJString(Version))
  add(formData_593566, "PlatformArn", newJString(PlatformArn))
  result = call_593564.call(nil, query_593565, nil, formData_593566, nil)

var postDeletePlatformVersion* = Call_PostDeletePlatformVersion_593550(
    name: "postDeletePlatformVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeletePlatformVersion",
    validator: validate_PostDeletePlatformVersion_593551, base: "/",
    url: url_PostDeletePlatformVersion_593552,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeletePlatformVersion_593534 = ref object of OpenApiRestCall_592365
proc url_GetDeletePlatformVersion_593536(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeletePlatformVersion_593535(path: JsonNode; query: JsonNode;
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
  var valid_593537 = query.getOrDefault("Action")
  valid_593537 = validateParameter(valid_593537, JString, required = true,
                                 default = newJString("DeletePlatformVersion"))
  if valid_593537 != nil:
    section.add "Action", valid_593537
  var valid_593538 = query.getOrDefault("PlatformArn")
  valid_593538 = validateParameter(valid_593538, JString, required = false,
                                 default = nil)
  if valid_593538 != nil:
    section.add "PlatformArn", valid_593538
  var valid_593539 = query.getOrDefault("Version")
  valid_593539 = validateParameter(valid_593539, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593539 != nil:
    section.add "Version", valid_593539
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
  var valid_593540 = header.getOrDefault("X-Amz-Signature")
  valid_593540 = validateParameter(valid_593540, JString, required = false,
                                 default = nil)
  if valid_593540 != nil:
    section.add "X-Amz-Signature", valid_593540
  var valid_593541 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593541 = validateParameter(valid_593541, JString, required = false,
                                 default = nil)
  if valid_593541 != nil:
    section.add "X-Amz-Content-Sha256", valid_593541
  var valid_593542 = header.getOrDefault("X-Amz-Date")
  valid_593542 = validateParameter(valid_593542, JString, required = false,
                                 default = nil)
  if valid_593542 != nil:
    section.add "X-Amz-Date", valid_593542
  var valid_593543 = header.getOrDefault("X-Amz-Credential")
  valid_593543 = validateParameter(valid_593543, JString, required = false,
                                 default = nil)
  if valid_593543 != nil:
    section.add "X-Amz-Credential", valid_593543
  var valid_593544 = header.getOrDefault("X-Amz-Security-Token")
  valid_593544 = validateParameter(valid_593544, JString, required = false,
                                 default = nil)
  if valid_593544 != nil:
    section.add "X-Amz-Security-Token", valid_593544
  var valid_593545 = header.getOrDefault("X-Amz-Algorithm")
  valid_593545 = validateParameter(valid_593545, JString, required = false,
                                 default = nil)
  if valid_593545 != nil:
    section.add "X-Amz-Algorithm", valid_593545
  var valid_593546 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593546 = validateParameter(valid_593546, JString, required = false,
                                 default = nil)
  if valid_593546 != nil:
    section.add "X-Amz-SignedHeaders", valid_593546
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593547: Call_GetDeletePlatformVersion_593534; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified version of a custom platform.
  ## 
  let valid = call_593547.validator(path, query, header, formData, body)
  let scheme = call_593547.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593547.url(scheme.get, call_593547.host, call_593547.base,
                         call_593547.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593547, url, valid)

proc call*(call_593548: Call_GetDeletePlatformVersion_593534;
          Action: string = "DeletePlatformVersion"; PlatformArn: string = "";
          Version: string = "2010-12-01"): Recallable =
  ## getDeletePlatformVersion
  ## Deletes the specified version of a custom platform.
  ##   Action: string (required)
  ##   PlatformArn: string
  ##              : The ARN of the version of the custom platform.
  ##   Version: string (required)
  var query_593549 = newJObject()
  add(query_593549, "Action", newJString(Action))
  add(query_593549, "PlatformArn", newJString(PlatformArn))
  add(query_593549, "Version", newJString(Version))
  result = call_593548.call(nil, query_593549, nil, nil, nil)

var getDeletePlatformVersion* = Call_GetDeletePlatformVersion_593534(
    name: "getDeletePlatformVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeletePlatformVersion",
    validator: validate_GetDeletePlatformVersion_593535, base: "/",
    url: url_GetDeletePlatformVersion_593536, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAccountAttributes_593582 = ref object of OpenApiRestCall_592365
proc url_PostDescribeAccountAttributes_593584(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeAccountAttributes_593583(path: JsonNode; query: JsonNode;
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
  var valid_593585 = query.getOrDefault("Action")
  valid_593585 = validateParameter(valid_593585, JString, required = true, default = newJString(
      "DescribeAccountAttributes"))
  if valid_593585 != nil:
    section.add "Action", valid_593585
  var valid_593586 = query.getOrDefault("Version")
  valid_593586 = validateParameter(valid_593586, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593586 != nil:
    section.add "Version", valid_593586
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
  var valid_593587 = header.getOrDefault("X-Amz-Signature")
  valid_593587 = validateParameter(valid_593587, JString, required = false,
                                 default = nil)
  if valid_593587 != nil:
    section.add "X-Amz-Signature", valid_593587
  var valid_593588 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593588 = validateParameter(valid_593588, JString, required = false,
                                 default = nil)
  if valid_593588 != nil:
    section.add "X-Amz-Content-Sha256", valid_593588
  var valid_593589 = header.getOrDefault("X-Amz-Date")
  valid_593589 = validateParameter(valid_593589, JString, required = false,
                                 default = nil)
  if valid_593589 != nil:
    section.add "X-Amz-Date", valid_593589
  var valid_593590 = header.getOrDefault("X-Amz-Credential")
  valid_593590 = validateParameter(valid_593590, JString, required = false,
                                 default = nil)
  if valid_593590 != nil:
    section.add "X-Amz-Credential", valid_593590
  var valid_593591 = header.getOrDefault("X-Amz-Security-Token")
  valid_593591 = validateParameter(valid_593591, JString, required = false,
                                 default = nil)
  if valid_593591 != nil:
    section.add "X-Amz-Security-Token", valid_593591
  var valid_593592 = header.getOrDefault("X-Amz-Algorithm")
  valid_593592 = validateParameter(valid_593592, JString, required = false,
                                 default = nil)
  if valid_593592 != nil:
    section.add "X-Amz-Algorithm", valid_593592
  var valid_593593 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593593 = validateParameter(valid_593593, JString, required = false,
                                 default = nil)
  if valid_593593 != nil:
    section.add "X-Amz-SignedHeaders", valid_593593
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593594: Call_PostDescribeAccountAttributes_593582; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ## 
  let valid = call_593594.validator(path, query, header, formData, body)
  let scheme = call_593594.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593594.url(scheme.get, call_593594.host, call_593594.base,
                         call_593594.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593594, url, valid)

proc call*(call_593595: Call_PostDescribeAccountAttributes_593582;
          Action: string = "DescribeAccountAttributes";
          Version: string = "2010-12-01"): Recallable =
  ## postDescribeAccountAttributes
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593596 = newJObject()
  add(query_593596, "Action", newJString(Action))
  add(query_593596, "Version", newJString(Version))
  result = call_593595.call(nil, query_593596, nil, nil, nil)

var postDescribeAccountAttributes* = Call_PostDescribeAccountAttributes_593582(
    name: "postDescribeAccountAttributes", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeAccountAttributes",
    validator: validate_PostDescribeAccountAttributes_593583, base: "/",
    url: url_PostDescribeAccountAttributes_593584,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAccountAttributes_593567 = ref object of OpenApiRestCall_592365
proc url_GetDescribeAccountAttributes_593569(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeAccountAttributes_593568(path: JsonNode; query: JsonNode;
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
  var valid_593570 = query.getOrDefault("Action")
  valid_593570 = validateParameter(valid_593570, JString, required = true, default = newJString(
      "DescribeAccountAttributes"))
  if valid_593570 != nil:
    section.add "Action", valid_593570
  var valid_593571 = query.getOrDefault("Version")
  valid_593571 = validateParameter(valid_593571, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593571 != nil:
    section.add "Version", valid_593571
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
  var valid_593572 = header.getOrDefault("X-Amz-Signature")
  valid_593572 = validateParameter(valid_593572, JString, required = false,
                                 default = nil)
  if valid_593572 != nil:
    section.add "X-Amz-Signature", valid_593572
  var valid_593573 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593573 = validateParameter(valid_593573, JString, required = false,
                                 default = nil)
  if valid_593573 != nil:
    section.add "X-Amz-Content-Sha256", valid_593573
  var valid_593574 = header.getOrDefault("X-Amz-Date")
  valid_593574 = validateParameter(valid_593574, JString, required = false,
                                 default = nil)
  if valid_593574 != nil:
    section.add "X-Amz-Date", valid_593574
  var valid_593575 = header.getOrDefault("X-Amz-Credential")
  valid_593575 = validateParameter(valid_593575, JString, required = false,
                                 default = nil)
  if valid_593575 != nil:
    section.add "X-Amz-Credential", valid_593575
  var valid_593576 = header.getOrDefault("X-Amz-Security-Token")
  valid_593576 = validateParameter(valid_593576, JString, required = false,
                                 default = nil)
  if valid_593576 != nil:
    section.add "X-Amz-Security-Token", valid_593576
  var valid_593577 = header.getOrDefault("X-Amz-Algorithm")
  valid_593577 = validateParameter(valid_593577, JString, required = false,
                                 default = nil)
  if valid_593577 != nil:
    section.add "X-Amz-Algorithm", valid_593577
  var valid_593578 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593578 = validateParameter(valid_593578, JString, required = false,
                                 default = nil)
  if valid_593578 != nil:
    section.add "X-Amz-SignedHeaders", valid_593578
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593579: Call_GetDescribeAccountAttributes_593567; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ## 
  let valid = call_593579.validator(path, query, header, formData, body)
  let scheme = call_593579.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593579.url(scheme.get, call_593579.host, call_593579.base,
                         call_593579.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593579, url, valid)

proc call*(call_593580: Call_GetDescribeAccountAttributes_593567;
          Action: string = "DescribeAccountAttributes";
          Version: string = "2010-12-01"): Recallable =
  ## getDescribeAccountAttributes
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593581 = newJObject()
  add(query_593581, "Action", newJString(Action))
  add(query_593581, "Version", newJString(Version))
  result = call_593580.call(nil, query_593581, nil, nil, nil)

var getDescribeAccountAttributes* = Call_GetDescribeAccountAttributes_593567(
    name: "getDescribeAccountAttributes", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeAccountAttributes",
    validator: validate_GetDescribeAccountAttributes_593568, base: "/",
    url: url_GetDescribeAccountAttributes_593569,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeApplicationVersions_593616 = ref object of OpenApiRestCall_592365
proc url_PostDescribeApplicationVersions_593618(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeApplicationVersions_593617(path: JsonNode;
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
  var valid_593619 = query.getOrDefault("Action")
  valid_593619 = validateParameter(valid_593619, JString, required = true, default = newJString(
      "DescribeApplicationVersions"))
  if valid_593619 != nil:
    section.add "Action", valid_593619
  var valid_593620 = query.getOrDefault("Version")
  valid_593620 = validateParameter(valid_593620, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593620 != nil:
    section.add "Version", valid_593620
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
  var valid_593621 = header.getOrDefault("X-Amz-Signature")
  valid_593621 = validateParameter(valid_593621, JString, required = false,
                                 default = nil)
  if valid_593621 != nil:
    section.add "X-Amz-Signature", valid_593621
  var valid_593622 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593622 = validateParameter(valid_593622, JString, required = false,
                                 default = nil)
  if valid_593622 != nil:
    section.add "X-Amz-Content-Sha256", valid_593622
  var valid_593623 = header.getOrDefault("X-Amz-Date")
  valid_593623 = validateParameter(valid_593623, JString, required = false,
                                 default = nil)
  if valid_593623 != nil:
    section.add "X-Amz-Date", valid_593623
  var valid_593624 = header.getOrDefault("X-Amz-Credential")
  valid_593624 = validateParameter(valid_593624, JString, required = false,
                                 default = nil)
  if valid_593624 != nil:
    section.add "X-Amz-Credential", valid_593624
  var valid_593625 = header.getOrDefault("X-Amz-Security-Token")
  valid_593625 = validateParameter(valid_593625, JString, required = false,
                                 default = nil)
  if valid_593625 != nil:
    section.add "X-Amz-Security-Token", valid_593625
  var valid_593626 = header.getOrDefault("X-Amz-Algorithm")
  valid_593626 = validateParameter(valid_593626, JString, required = false,
                                 default = nil)
  if valid_593626 != nil:
    section.add "X-Amz-Algorithm", valid_593626
  var valid_593627 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593627 = validateParameter(valid_593627, JString, required = false,
                                 default = nil)
  if valid_593627 != nil:
    section.add "X-Amz-SignedHeaders", valid_593627
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
  var valid_593628 = formData.getOrDefault("NextToken")
  valid_593628 = validateParameter(valid_593628, JString, required = false,
                                 default = nil)
  if valid_593628 != nil:
    section.add "NextToken", valid_593628
  var valid_593629 = formData.getOrDefault("MaxRecords")
  valid_593629 = validateParameter(valid_593629, JInt, required = false, default = nil)
  if valid_593629 != nil:
    section.add "MaxRecords", valid_593629
  var valid_593630 = formData.getOrDefault("VersionLabels")
  valid_593630 = validateParameter(valid_593630, JArray, required = false,
                                 default = nil)
  if valid_593630 != nil:
    section.add "VersionLabels", valid_593630
  var valid_593631 = formData.getOrDefault("ApplicationName")
  valid_593631 = validateParameter(valid_593631, JString, required = false,
                                 default = nil)
  if valid_593631 != nil:
    section.add "ApplicationName", valid_593631
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593632: Call_PostDescribeApplicationVersions_593616;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieve a list of application versions.
  ## 
  let valid = call_593632.validator(path, query, header, formData, body)
  let scheme = call_593632.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593632.url(scheme.get, call_593632.host, call_593632.base,
                         call_593632.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593632, url, valid)

proc call*(call_593633: Call_PostDescribeApplicationVersions_593616;
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
  var query_593634 = newJObject()
  var formData_593635 = newJObject()
  add(formData_593635, "NextToken", newJString(NextToken))
  add(formData_593635, "MaxRecords", newJInt(MaxRecords))
  if VersionLabels != nil:
    formData_593635.add "VersionLabels", VersionLabels
  add(formData_593635, "ApplicationName", newJString(ApplicationName))
  add(query_593634, "Action", newJString(Action))
  add(query_593634, "Version", newJString(Version))
  result = call_593633.call(nil, query_593634, nil, formData_593635, nil)

var postDescribeApplicationVersions* = Call_PostDescribeApplicationVersions_593616(
    name: "postDescribeApplicationVersions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplicationVersions",
    validator: validate_PostDescribeApplicationVersions_593617, base: "/",
    url: url_PostDescribeApplicationVersions_593618,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeApplicationVersions_593597 = ref object of OpenApiRestCall_592365
proc url_GetDescribeApplicationVersions_593599(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeApplicationVersions_593598(path: JsonNode;
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
  var valid_593600 = query.getOrDefault("ApplicationName")
  valid_593600 = validateParameter(valid_593600, JString, required = false,
                                 default = nil)
  if valid_593600 != nil:
    section.add "ApplicationName", valid_593600
  var valid_593601 = query.getOrDefault("NextToken")
  valid_593601 = validateParameter(valid_593601, JString, required = false,
                                 default = nil)
  if valid_593601 != nil:
    section.add "NextToken", valid_593601
  var valid_593602 = query.getOrDefault("VersionLabels")
  valid_593602 = validateParameter(valid_593602, JArray, required = false,
                                 default = nil)
  if valid_593602 != nil:
    section.add "VersionLabels", valid_593602
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593603 = query.getOrDefault("Action")
  valid_593603 = validateParameter(valid_593603, JString, required = true, default = newJString(
      "DescribeApplicationVersions"))
  if valid_593603 != nil:
    section.add "Action", valid_593603
  var valid_593604 = query.getOrDefault("Version")
  valid_593604 = validateParameter(valid_593604, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593604 != nil:
    section.add "Version", valid_593604
  var valid_593605 = query.getOrDefault("MaxRecords")
  valid_593605 = validateParameter(valid_593605, JInt, required = false, default = nil)
  if valid_593605 != nil:
    section.add "MaxRecords", valid_593605
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
  var valid_593606 = header.getOrDefault("X-Amz-Signature")
  valid_593606 = validateParameter(valid_593606, JString, required = false,
                                 default = nil)
  if valid_593606 != nil:
    section.add "X-Amz-Signature", valid_593606
  var valid_593607 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593607 = validateParameter(valid_593607, JString, required = false,
                                 default = nil)
  if valid_593607 != nil:
    section.add "X-Amz-Content-Sha256", valid_593607
  var valid_593608 = header.getOrDefault("X-Amz-Date")
  valid_593608 = validateParameter(valid_593608, JString, required = false,
                                 default = nil)
  if valid_593608 != nil:
    section.add "X-Amz-Date", valid_593608
  var valid_593609 = header.getOrDefault("X-Amz-Credential")
  valid_593609 = validateParameter(valid_593609, JString, required = false,
                                 default = nil)
  if valid_593609 != nil:
    section.add "X-Amz-Credential", valid_593609
  var valid_593610 = header.getOrDefault("X-Amz-Security-Token")
  valid_593610 = validateParameter(valid_593610, JString, required = false,
                                 default = nil)
  if valid_593610 != nil:
    section.add "X-Amz-Security-Token", valid_593610
  var valid_593611 = header.getOrDefault("X-Amz-Algorithm")
  valid_593611 = validateParameter(valid_593611, JString, required = false,
                                 default = nil)
  if valid_593611 != nil:
    section.add "X-Amz-Algorithm", valid_593611
  var valid_593612 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593612 = validateParameter(valid_593612, JString, required = false,
                                 default = nil)
  if valid_593612 != nil:
    section.add "X-Amz-SignedHeaders", valid_593612
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593613: Call_GetDescribeApplicationVersions_593597; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a list of application versions.
  ## 
  let valid = call_593613.validator(path, query, header, formData, body)
  let scheme = call_593613.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593613.url(scheme.get, call_593613.host, call_593613.base,
                         call_593613.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593613, url, valid)

proc call*(call_593614: Call_GetDescribeApplicationVersions_593597;
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
  var query_593615 = newJObject()
  add(query_593615, "ApplicationName", newJString(ApplicationName))
  add(query_593615, "NextToken", newJString(NextToken))
  if VersionLabels != nil:
    query_593615.add "VersionLabels", VersionLabels
  add(query_593615, "Action", newJString(Action))
  add(query_593615, "Version", newJString(Version))
  add(query_593615, "MaxRecords", newJInt(MaxRecords))
  result = call_593614.call(nil, query_593615, nil, nil, nil)

var getDescribeApplicationVersions* = Call_GetDescribeApplicationVersions_593597(
    name: "getDescribeApplicationVersions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplicationVersions",
    validator: validate_GetDescribeApplicationVersions_593598, base: "/",
    url: url_GetDescribeApplicationVersions_593599,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeApplications_593652 = ref object of OpenApiRestCall_592365
proc url_PostDescribeApplications_593654(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeApplications_593653(path: JsonNode; query: JsonNode;
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
  var valid_593655 = query.getOrDefault("Action")
  valid_593655 = validateParameter(valid_593655, JString, required = true,
                                 default = newJString("DescribeApplications"))
  if valid_593655 != nil:
    section.add "Action", valid_593655
  var valid_593656 = query.getOrDefault("Version")
  valid_593656 = validateParameter(valid_593656, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593656 != nil:
    section.add "Version", valid_593656
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
  var valid_593657 = header.getOrDefault("X-Amz-Signature")
  valid_593657 = validateParameter(valid_593657, JString, required = false,
                                 default = nil)
  if valid_593657 != nil:
    section.add "X-Amz-Signature", valid_593657
  var valid_593658 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593658 = validateParameter(valid_593658, JString, required = false,
                                 default = nil)
  if valid_593658 != nil:
    section.add "X-Amz-Content-Sha256", valid_593658
  var valid_593659 = header.getOrDefault("X-Amz-Date")
  valid_593659 = validateParameter(valid_593659, JString, required = false,
                                 default = nil)
  if valid_593659 != nil:
    section.add "X-Amz-Date", valid_593659
  var valid_593660 = header.getOrDefault("X-Amz-Credential")
  valid_593660 = validateParameter(valid_593660, JString, required = false,
                                 default = nil)
  if valid_593660 != nil:
    section.add "X-Amz-Credential", valid_593660
  var valid_593661 = header.getOrDefault("X-Amz-Security-Token")
  valid_593661 = validateParameter(valid_593661, JString, required = false,
                                 default = nil)
  if valid_593661 != nil:
    section.add "X-Amz-Security-Token", valid_593661
  var valid_593662 = header.getOrDefault("X-Amz-Algorithm")
  valid_593662 = validateParameter(valid_593662, JString, required = false,
                                 default = nil)
  if valid_593662 != nil:
    section.add "X-Amz-Algorithm", valid_593662
  var valid_593663 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593663 = validateParameter(valid_593663, JString, required = false,
                                 default = nil)
  if valid_593663 != nil:
    section.add "X-Amz-SignedHeaders", valid_593663
  result.add "header", section
  ## parameters in `formData` object:
  ##   ApplicationNames: JArray
  ##                   : If specified, AWS Elastic Beanstalk restricts the returned descriptions to only include those with the specified names.
  section = newJObject()
  var valid_593664 = formData.getOrDefault("ApplicationNames")
  valid_593664 = validateParameter(valid_593664, JArray, required = false,
                                 default = nil)
  if valid_593664 != nil:
    section.add "ApplicationNames", valid_593664
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593665: Call_PostDescribeApplications_593652; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the descriptions of existing applications.
  ## 
  let valid = call_593665.validator(path, query, header, formData, body)
  let scheme = call_593665.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593665.url(scheme.get, call_593665.host, call_593665.base,
                         call_593665.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593665, url, valid)

proc call*(call_593666: Call_PostDescribeApplications_593652;
          ApplicationNames: JsonNode = nil; Action: string = "DescribeApplications";
          Version: string = "2010-12-01"): Recallable =
  ## postDescribeApplications
  ## Returns the descriptions of existing applications.
  ##   ApplicationNames: JArray
  ##                   : If specified, AWS Elastic Beanstalk restricts the returned descriptions to only include those with the specified names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593667 = newJObject()
  var formData_593668 = newJObject()
  if ApplicationNames != nil:
    formData_593668.add "ApplicationNames", ApplicationNames
  add(query_593667, "Action", newJString(Action))
  add(query_593667, "Version", newJString(Version))
  result = call_593666.call(nil, query_593667, nil, formData_593668, nil)

var postDescribeApplications* = Call_PostDescribeApplications_593652(
    name: "postDescribeApplications", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplications",
    validator: validate_PostDescribeApplications_593653, base: "/",
    url: url_PostDescribeApplications_593654, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeApplications_593636 = ref object of OpenApiRestCall_592365
proc url_GetDescribeApplications_593638(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeApplications_593637(path: JsonNode; query: JsonNode;
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
  var valid_593639 = query.getOrDefault("ApplicationNames")
  valid_593639 = validateParameter(valid_593639, JArray, required = false,
                                 default = nil)
  if valid_593639 != nil:
    section.add "ApplicationNames", valid_593639
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593640 = query.getOrDefault("Action")
  valid_593640 = validateParameter(valid_593640, JString, required = true,
                                 default = newJString("DescribeApplications"))
  if valid_593640 != nil:
    section.add "Action", valid_593640
  var valid_593641 = query.getOrDefault("Version")
  valid_593641 = validateParameter(valid_593641, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593641 != nil:
    section.add "Version", valid_593641
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
  var valid_593642 = header.getOrDefault("X-Amz-Signature")
  valid_593642 = validateParameter(valid_593642, JString, required = false,
                                 default = nil)
  if valid_593642 != nil:
    section.add "X-Amz-Signature", valid_593642
  var valid_593643 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593643 = validateParameter(valid_593643, JString, required = false,
                                 default = nil)
  if valid_593643 != nil:
    section.add "X-Amz-Content-Sha256", valid_593643
  var valid_593644 = header.getOrDefault("X-Amz-Date")
  valid_593644 = validateParameter(valid_593644, JString, required = false,
                                 default = nil)
  if valid_593644 != nil:
    section.add "X-Amz-Date", valid_593644
  var valid_593645 = header.getOrDefault("X-Amz-Credential")
  valid_593645 = validateParameter(valid_593645, JString, required = false,
                                 default = nil)
  if valid_593645 != nil:
    section.add "X-Amz-Credential", valid_593645
  var valid_593646 = header.getOrDefault("X-Amz-Security-Token")
  valid_593646 = validateParameter(valid_593646, JString, required = false,
                                 default = nil)
  if valid_593646 != nil:
    section.add "X-Amz-Security-Token", valid_593646
  var valid_593647 = header.getOrDefault("X-Amz-Algorithm")
  valid_593647 = validateParameter(valid_593647, JString, required = false,
                                 default = nil)
  if valid_593647 != nil:
    section.add "X-Amz-Algorithm", valid_593647
  var valid_593648 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593648 = validateParameter(valid_593648, JString, required = false,
                                 default = nil)
  if valid_593648 != nil:
    section.add "X-Amz-SignedHeaders", valid_593648
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593649: Call_GetDescribeApplications_593636; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the descriptions of existing applications.
  ## 
  let valid = call_593649.validator(path, query, header, formData, body)
  let scheme = call_593649.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593649.url(scheme.get, call_593649.host, call_593649.base,
                         call_593649.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593649, url, valid)

proc call*(call_593650: Call_GetDescribeApplications_593636;
          ApplicationNames: JsonNode = nil; Action: string = "DescribeApplications";
          Version: string = "2010-12-01"): Recallable =
  ## getDescribeApplications
  ## Returns the descriptions of existing applications.
  ##   ApplicationNames: JArray
  ##                   : If specified, AWS Elastic Beanstalk restricts the returned descriptions to only include those with the specified names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_593651 = newJObject()
  if ApplicationNames != nil:
    query_593651.add "ApplicationNames", ApplicationNames
  add(query_593651, "Action", newJString(Action))
  add(query_593651, "Version", newJString(Version))
  result = call_593650.call(nil, query_593651, nil, nil, nil)

var getDescribeApplications* = Call_GetDescribeApplications_593636(
    name: "getDescribeApplications", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplications",
    validator: validate_GetDescribeApplications_593637, base: "/",
    url: url_GetDescribeApplications_593638, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeConfigurationOptions_593690 = ref object of OpenApiRestCall_592365
proc url_PostDescribeConfigurationOptions_593692(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeConfigurationOptions_593691(path: JsonNode;
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
  var valid_593693 = query.getOrDefault("Action")
  valid_593693 = validateParameter(valid_593693, JString, required = true, default = newJString(
      "DescribeConfigurationOptions"))
  if valid_593693 != nil:
    section.add "Action", valid_593693
  var valid_593694 = query.getOrDefault("Version")
  valid_593694 = validateParameter(valid_593694, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593694 != nil:
    section.add "Version", valid_593694
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
  var valid_593695 = header.getOrDefault("X-Amz-Signature")
  valid_593695 = validateParameter(valid_593695, JString, required = false,
                                 default = nil)
  if valid_593695 != nil:
    section.add "X-Amz-Signature", valid_593695
  var valid_593696 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593696 = validateParameter(valid_593696, JString, required = false,
                                 default = nil)
  if valid_593696 != nil:
    section.add "X-Amz-Content-Sha256", valid_593696
  var valid_593697 = header.getOrDefault("X-Amz-Date")
  valid_593697 = validateParameter(valid_593697, JString, required = false,
                                 default = nil)
  if valid_593697 != nil:
    section.add "X-Amz-Date", valid_593697
  var valid_593698 = header.getOrDefault("X-Amz-Credential")
  valid_593698 = validateParameter(valid_593698, JString, required = false,
                                 default = nil)
  if valid_593698 != nil:
    section.add "X-Amz-Credential", valid_593698
  var valid_593699 = header.getOrDefault("X-Amz-Security-Token")
  valid_593699 = validateParameter(valid_593699, JString, required = false,
                                 default = nil)
  if valid_593699 != nil:
    section.add "X-Amz-Security-Token", valid_593699
  var valid_593700 = header.getOrDefault("X-Amz-Algorithm")
  valid_593700 = validateParameter(valid_593700, JString, required = false,
                                 default = nil)
  if valid_593700 != nil:
    section.add "X-Amz-Algorithm", valid_593700
  var valid_593701 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593701 = validateParameter(valid_593701, JString, required = false,
                                 default = nil)
  if valid_593701 != nil:
    section.add "X-Amz-SignedHeaders", valid_593701
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
  var valid_593702 = formData.getOrDefault("EnvironmentName")
  valid_593702 = validateParameter(valid_593702, JString, required = false,
                                 default = nil)
  if valid_593702 != nil:
    section.add "EnvironmentName", valid_593702
  var valid_593703 = formData.getOrDefault("TemplateName")
  valid_593703 = validateParameter(valid_593703, JString, required = false,
                                 default = nil)
  if valid_593703 != nil:
    section.add "TemplateName", valid_593703
  var valid_593704 = formData.getOrDefault("Options")
  valid_593704 = validateParameter(valid_593704, JArray, required = false,
                                 default = nil)
  if valid_593704 != nil:
    section.add "Options", valid_593704
  var valid_593705 = formData.getOrDefault("ApplicationName")
  valid_593705 = validateParameter(valid_593705, JString, required = false,
                                 default = nil)
  if valid_593705 != nil:
    section.add "ApplicationName", valid_593705
  var valid_593706 = formData.getOrDefault("SolutionStackName")
  valid_593706 = validateParameter(valid_593706, JString, required = false,
                                 default = nil)
  if valid_593706 != nil:
    section.add "SolutionStackName", valid_593706
  var valid_593707 = formData.getOrDefault("PlatformArn")
  valid_593707 = validateParameter(valid_593707, JString, required = false,
                                 default = nil)
  if valid_593707 != nil:
    section.add "PlatformArn", valid_593707
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593708: Call_PostDescribeConfigurationOptions_593690;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the configuration options that are used in a particular configuration template or environment, or that a specified solution stack defines. The description includes the values the options, their default values, and an indication of the required action on a running environment if an option value is changed.
  ## 
  let valid = call_593708.validator(path, query, header, formData, body)
  let scheme = call_593708.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593708.url(scheme.get, call_593708.host, call_593708.base,
                         call_593708.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593708, url, valid)

proc call*(call_593709: Call_PostDescribeConfigurationOptions_593690;
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
  var query_593710 = newJObject()
  var formData_593711 = newJObject()
  add(formData_593711, "EnvironmentName", newJString(EnvironmentName))
  add(formData_593711, "TemplateName", newJString(TemplateName))
  if Options != nil:
    formData_593711.add "Options", Options
  add(formData_593711, "ApplicationName", newJString(ApplicationName))
  add(query_593710, "Action", newJString(Action))
  add(formData_593711, "SolutionStackName", newJString(SolutionStackName))
  add(query_593710, "Version", newJString(Version))
  add(formData_593711, "PlatformArn", newJString(PlatformArn))
  result = call_593709.call(nil, query_593710, nil, formData_593711, nil)

var postDescribeConfigurationOptions* = Call_PostDescribeConfigurationOptions_593690(
    name: "postDescribeConfigurationOptions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationOptions",
    validator: validate_PostDescribeConfigurationOptions_593691, base: "/",
    url: url_PostDescribeConfigurationOptions_593692,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeConfigurationOptions_593669 = ref object of OpenApiRestCall_592365
proc url_GetDescribeConfigurationOptions_593671(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeConfigurationOptions_593670(path: JsonNode;
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
  var valid_593672 = query.getOrDefault("ApplicationName")
  valid_593672 = validateParameter(valid_593672, JString, required = false,
                                 default = nil)
  if valid_593672 != nil:
    section.add "ApplicationName", valid_593672
  var valid_593673 = query.getOrDefault("Options")
  valid_593673 = validateParameter(valid_593673, JArray, required = false,
                                 default = nil)
  if valid_593673 != nil:
    section.add "Options", valid_593673
  var valid_593674 = query.getOrDefault("SolutionStackName")
  valid_593674 = validateParameter(valid_593674, JString, required = false,
                                 default = nil)
  if valid_593674 != nil:
    section.add "SolutionStackName", valid_593674
  var valid_593675 = query.getOrDefault("EnvironmentName")
  valid_593675 = validateParameter(valid_593675, JString, required = false,
                                 default = nil)
  if valid_593675 != nil:
    section.add "EnvironmentName", valid_593675
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593676 = query.getOrDefault("Action")
  valid_593676 = validateParameter(valid_593676, JString, required = true, default = newJString(
      "DescribeConfigurationOptions"))
  if valid_593676 != nil:
    section.add "Action", valid_593676
  var valid_593677 = query.getOrDefault("PlatformArn")
  valid_593677 = validateParameter(valid_593677, JString, required = false,
                                 default = nil)
  if valid_593677 != nil:
    section.add "PlatformArn", valid_593677
  var valid_593678 = query.getOrDefault("Version")
  valid_593678 = validateParameter(valid_593678, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593678 != nil:
    section.add "Version", valid_593678
  var valid_593679 = query.getOrDefault("TemplateName")
  valid_593679 = validateParameter(valid_593679, JString, required = false,
                                 default = nil)
  if valid_593679 != nil:
    section.add "TemplateName", valid_593679
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
  var valid_593680 = header.getOrDefault("X-Amz-Signature")
  valid_593680 = validateParameter(valid_593680, JString, required = false,
                                 default = nil)
  if valid_593680 != nil:
    section.add "X-Amz-Signature", valid_593680
  var valid_593681 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593681 = validateParameter(valid_593681, JString, required = false,
                                 default = nil)
  if valid_593681 != nil:
    section.add "X-Amz-Content-Sha256", valid_593681
  var valid_593682 = header.getOrDefault("X-Amz-Date")
  valid_593682 = validateParameter(valid_593682, JString, required = false,
                                 default = nil)
  if valid_593682 != nil:
    section.add "X-Amz-Date", valid_593682
  var valid_593683 = header.getOrDefault("X-Amz-Credential")
  valid_593683 = validateParameter(valid_593683, JString, required = false,
                                 default = nil)
  if valid_593683 != nil:
    section.add "X-Amz-Credential", valid_593683
  var valid_593684 = header.getOrDefault("X-Amz-Security-Token")
  valid_593684 = validateParameter(valid_593684, JString, required = false,
                                 default = nil)
  if valid_593684 != nil:
    section.add "X-Amz-Security-Token", valid_593684
  var valid_593685 = header.getOrDefault("X-Amz-Algorithm")
  valid_593685 = validateParameter(valid_593685, JString, required = false,
                                 default = nil)
  if valid_593685 != nil:
    section.add "X-Amz-Algorithm", valid_593685
  var valid_593686 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593686 = validateParameter(valid_593686, JString, required = false,
                                 default = nil)
  if valid_593686 != nil:
    section.add "X-Amz-SignedHeaders", valid_593686
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593687: Call_GetDescribeConfigurationOptions_593669;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the configuration options that are used in a particular configuration template or environment, or that a specified solution stack defines. The description includes the values the options, their default values, and an indication of the required action on a running environment if an option value is changed.
  ## 
  let valid = call_593687.validator(path, query, header, formData, body)
  let scheme = call_593687.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593687.url(scheme.get, call_593687.host, call_593687.base,
                         call_593687.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593687, url, valid)

proc call*(call_593688: Call_GetDescribeConfigurationOptions_593669;
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
  var query_593689 = newJObject()
  add(query_593689, "ApplicationName", newJString(ApplicationName))
  if Options != nil:
    query_593689.add "Options", Options
  add(query_593689, "SolutionStackName", newJString(SolutionStackName))
  add(query_593689, "EnvironmentName", newJString(EnvironmentName))
  add(query_593689, "Action", newJString(Action))
  add(query_593689, "PlatformArn", newJString(PlatformArn))
  add(query_593689, "Version", newJString(Version))
  add(query_593689, "TemplateName", newJString(TemplateName))
  result = call_593688.call(nil, query_593689, nil, nil, nil)

var getDescribeConfigurationOptions* = Call_GetDescribeConfigurationOptions_593669(
    name: "getDescribeConfigurationOptions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationOptions",
    validator: validate_GetDescribeConfigurationOptions_593670, base: "/",
    url: url_GetDescribeConfigurationOptions_593671,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeConfigurationSettings_593730 = ref object of OpenApiRestCall_592365
proc url_PostDescribeConfigurationSettings_593732(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeConfigurationSettings_593731(path: JsonNode;
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
  var valid_593733 = query.getOrDefault("Action")
  valid_593733 = validateParameter(valid_593733, JString, required = true, default = newJString(
      "DescribeConfigurationSettings"))
  if valid_593733 != nil:
    section.add "Action", valid_593733
  var valid_593734 = query.getOrDefault("Version")
  valid_593734 = validateParameter(valid_593734, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593734 != nil:
    section.add "Version", valid_593734
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
  var valid_593735 = header.getOrDefault("X-Amz-Signature")
  valid_593735 = validateParameter(valid_593735, JString, required = false,
                                 default = nil)
  if valid_593735 != nil:
    section.add "X-Amz-Signature", valid_593735
  var valid_593736 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593736 = validateParameter(valid_593736, JString, required = false,
                                 default = nil)
  if valid_593736 != nil:
    section.add "X-Amz-Content-Sha256", valid_593736
  var valid_593737 = header.getOrDefault("X-Amz-Date")
  valid_593737 = validateParameter(valid_593737, JString, required = false,
                                 default = nil)
  if valid_593737 != nil:
    section.add "X-Amz-Date", valid_593737
  var valid_593738 = header.getOrDefault("X-Amz-Credential")
  valid_593738 = validateParameter(valid_593738, JString, required = false,
                                 default = nil)
  if valid_593738 != nil:
    section.add "X-Amz-Credential", valid_593738
  var valid_593739 = header.getOrDefault("X-Amz-Security-Token")
  valid_593739 = validateParameter(valid_593739, JString, required = false,
                                 default = nil)
  if valid_593739 != nil:
    section.add "X-Amz-Security-Token", valid_593739
  var valid_593740 = header.getOrDefault("X-Amz-Algorithm")
  valid_593740 = validateParameter(valid_593740, JString, required = false,
                                 default = nil)
  if valid_593740 != nil:
    section.add "X-Amz-Algorithm", valid_593740
  var valid_593741 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593741 = validateParameter(valid_593741, JString, required = false,
                                 default = nil)
  if valid_593741 != nil:
    section.add "X-Amz-SignedHeaders", valid_593741
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to describe.</p> <p> Condition: You must specify either this or a TemplateName, but not both. If you specify both, AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   TemplateName: JString
  ##               : <p>The name of the configuration template to describe.</p> <p> Conditional: You must specify either this parameter or an EnvironmentName, but not both. If you specify both, AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. If you do not specify either, AWS Elastic Beanstalk returns a <code>MissingRequiredParameter</code> error. </p>
  ##   ApplicationName: JString (required)
  ##                  : The application for the environment or configuration template.
  section = newJObject()
  var valid_593742 = formData.getOrDefault("EnvironmentName")
  valid_593742 = validateParameter(valid_593742, JString, required = false,
                                 default = nil)
  if valid_593742 != nil:
    section.add "EnvironmentName", valid_593742
  var valid_593743 = formData.getOrDefault("TemplateName")
  valid_593743 = validateParameter(valid_593743, JString, required = false,
                                 default = nil)
  if valid_593743 != nil:
    section.add "TemplateName", valid_593743
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_593744 = formData.getOrDefault("ApplicationName")
  valid_593744 = validateParameter(valid_593744, JString, required = true,
                                 default = nil)
  if valid_593744 != nil:
    section.add "ApplicationName", valid_593744
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593745: Call_PostDescribeConfigurationSettings_593730;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a description of the settings for the specified configuration set, that is, either a configuration template or the configuration set associated with a running environment.</p> <p>When describing the settings for the configuration set associated with a running environment, it is possible to receive two sets of setting descriptions. One is the deployed configuration set, and the other is a draft configuration of an environment that is either in the process of deployment or that failed to deploy.</p> <p>Related Topics</p> <ul> <li> <p> <a>DeleteEnvironmentConfiguration</a> </p> </li> </ul>
  ## 
  let valid = call_593745.validator(path, query, header, formData, body)
  let scheme = call_593745.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593745.url(scheme.get, call_593745.host, call_593745.base,
                         call_593745.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593745, url, valid)

proc call*(call_593746: Call_PostDescribeConfigurationSettings_593730;
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
  var query_593747 = newJObject()
  var formData_593748 = newJObject()
  add(formData_593748, "EnvironmentName", newJString(EnvironmentName))
  add(formData_593748, "TemplateName", newJString(TemplateName))
  add(formData_593748, "ApplicationName", newJString(ApplicationName))
  add(query_593747, "Action", newJString(Action))
  add(query_593747, "Version", newJString(Version))
  result = call_593746.call(nil, query_593747, nil, formData_593748, nil)

var postDescribeConfigurationSettings* = Call_PostDescribeConfigurationSettings_593730(
    name: "postDescribeConfigurationSettings", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationSettings",
    validator: validate_PostDescribeConfigurationSettings_593731, base: "/",
    url: url_PostDescribeConfigurationSettings_593732,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeConfigurationSettings_593712 = ref object of OpenApiRestCall_592365
proc url_GetDescribeConfigurationSettings_593714(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeConfigurationSettings_593713(path: JsonNode;
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
  var valid_593715 = query.getOrDefault("ApplicationName")
  valid_593715 = validateParameter(valid_593715, JString, required = true,
                                 default = nil)
  if valid_593715 != nil:
    section.add "ApplicationName", valid_593715
  var valid_593716 = query.getOrDefault("EnvironmentName")
  valid_593716 = validateParameter(valid_593716, JString, required = false,
                                 default = nil)
  if valid_593716 != nil:
    section.add "EnvironmentName", valid_593716
  var valid_593717 = query.getOrDefault("Action")
  valid_593717 = validateParameter(valid_593717, JString, required = true, default = newJString(
      "DescribeConfigurationSettings"))
  if valid_593717 != nil:
    section.add "Action", valid_593717
  var valid_593718 = query.getOrDefault("Version")
  valid_593718 = validateParameter(valid_593718, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593718 != nil:
    section.add "Version", valid_593718
  var valid_593719 = query.getOrDefault("TemplateName")
  valid_593719 = validateParameter(valid_593719, JString, required = false,
                                 default = nil)
  if valid_593719 != nil:
    section.add "TemplateName", valid_593719
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
  var valid_593720 = header.getOrDefault("X-Amz-Signature")
  valid_593720 = validateParameter(valid_593720, JString, required = false,
                                 default = nil)
  if valid_593720 != nil:
    section.add "X-Amz-Signature", valid_593720
  var valid_593721 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593721 = validateParameter(valid_593721, JString, required = false,
                                 default = nil)
  if valid_593721 != nil:
    section.add "X-Amz-Content-Sha256", valid_593721
  var valid_593722 = header.getOrDefault("X-Amz-Date")
  valid_593722 = validateParameter(valid_593722, JString, required = false,
                                 default = nil)
  if valid_593722 != nil:
    section.add "X-Amz-Date", valid_593722
  var valid_593723 = header.getOrDefault("X-Amz-Credential")
  valid_593723 = validateParameter(valid_593723, JString, required = false,
                                 default = nil)
  if valid_593723 != nil:
    section.add "X-Amz-Credential", valid_593723
  var valid_593724 = header.getOrDefault("X-Amz-Security-Token")
  valid_593724 = validateParameter(valid_593724, JString, required = false,
                                 default = nil)
  if valid_593724 != nil:
    section.add "X-Amz-Security-Token", valid_593724
  var valid_593725 = header.getOrDefault("X-Amz-Algorithm")
  valid_593725 = validateParameter(valid_593725, JString, required = false,
                                 default = nil)
  if valid_593725 != nil:
    section.add "X-Amz-Algorithm", valid_593725
  var valid_593726 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593726 = validateParameter(valid_593726, JString, required = false,
                                 default = nil)
  if valid_593726 != nil:
    section.add "X-Amz-SignedHeaders", valid_593726
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593727: Call_GetDescribeConfigurationSettings_593712;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a description of the settings for the specified configuration set, that is, either a configuration template or the configuration set associated with a running environment.</p> <p>When describing the settings for the configuration set associated with a running environment, it is possible to receive two sets of setting descriptions. One is the deployed configuration set, and the other is a draft configuration of an environment that is either in the process of deployment or that failed to deploy.</p> <p>Related Topics</p> <ul> <li> <p> <a>DeleteEnvironmentConfiguration</a> </p> </li> </ul>
  ## 
  let valid = call_593727.validator(path, query, header, formData, body)
  let scheme = call_593727.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593727.url(scheme.get, call_593727.host, call_593727.base,
                         call_593727.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593727, url, valid)

proc call*(call_593728: Call_GetDescribeConfigurationSettings_593712;
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
  var query_593729 = newJObject()
  add(query_593729, "ApplicationName", newJString(ApplicationName))
  add(query_593729, "EnvironmentName", newJString(EnvironmentName))
  add(query_593729, "Action", newJString(Action))
  add(query_593729, "Version", newJString(Version))
  add(query_593729, "TemplateName", newJString(TemplateName))
  result = call_593728.call(nil, query_593729, nil, nil, nil)

var getDescribeConfigurationSettings* = Call_GetDescribeConfigurationSettings_593712(
    name: "getDescribeConfigurationSettings", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationSettings",
    validator: validate_GetDescribeConfigurationSettings_593713, base: "/",
    url: url_GetDescribeConfigurationSettings_593714,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentHealth_593767 = ref object of OpenApiRestCall_592365
proc url_PostDescribeEnvironmentHealth_593769(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEnvironmentHealth_593768(path: JsonNode; query: JsonNode;
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
  var valid_593770 = query.getOrDefault("Action")
  valid_593770 = validateParameter(valid_593770, JString, required = true, default = newJString(
      "DescribeEnvironmentHealth"))
  if valid_593770 != nil:
    section.add "Action", valid_593770
  var valid_593771 = query.getOrDefault("Version")
  valid_593771 = validateParameter(valid_593771, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593771 != nil:
    section.add "Version", valid_593771
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
  var valid_593772 = header.getOrDefault("X-Amz-Signature")
  valid_593772 = validateParameter(valid_593772, JString, required = false,
                                 default = nil)
  if valid_593772 != nil:
    section.add "X-Amz-Signature", valid_593772
  var valid_593773 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593773 = validateParameter(valid_593773, JString, required = false,
                                 default = nil)
  if valid_593773 != nil:
    section.add "X-Amz-Content-Sha256", valid_593773
  var valid_593774 = header.getOrDefault("X-Amz-Date")
  valid_593774 = validateParameter(valid_593774, JString, required = false,
                                 default = nil)
  if valid_593774 != nil:
    section.add "X-Amz-Date", valid_593774
  var valid_593775 = header.getOrDefault("X-Amz-Credential")
  valid_593775 = validateParameter(valid_593775, JString, required = false,
                                 default = nil)
  if valid_593775 != nil:
    section.add "X-Amz-Credential", valid_593775
  var valid_593776 = header.getOrDefault("X-Amz-Security-Token")
  valid_593776 = validateParameter(valid_593776, JString, required = false,
                                 default = nil)
  if valid_593776 != nil:
    section.add "X-Amz-Security-Token", valid_593776
  var valid_593777 = header.getOrDefault("X-Amz-Algorithm")
  valid_593777 = validateParameter(valid_593777, JString, required = false,
                                 default = nil)
  if valid_593777 != nil:
    section.add "X-Amz-Algorithm", valid_593777
  var valid_593778 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593778 = validateParameter(valid_593778, JString, required = false,
                                 default = nil)
  if valid_593778 != nil:
    section.add "X-Amz-SignedHeaders", valid_593778
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString
  ##                  : <p>Specify the environment by name.</p> <p>You must specify either this or an EnvironmentName, or both.</p>
  ##   AttributeNames: JArray
  ##                 : Specify the response elements to return. To retrieve all attributes, set to <code>All</code>. If no attribute names are specified, returns the name of the environment.
  ##   EnvironmentId: JString
  ##                : <p>Specify the environment by ID.</p> <p>You must specify either this or an EnvironmentName, or both.</p>
  section = newJObject()
  var valid_593779 = formData.getOrDefault("EnvironmentName")
  valid_593779 = validateParameter(valid_593779, JString, required = false,
                                 default = nil)
  if valid_593779 != nil:
    section.add "EnvironmentName", valid_593779
  var valid_593780 = formData.getOrDefault("AttributeNames")
  valid_593780 = validateParameter(valid_593780, JArray, required = false,
                                 default = nil)
  if valid_593780 != nil:
    section.add "AttributeNames", valid_593780
  var valid_593781 = formData.getOrDefault("EnvironmentId")
  valid_593781 = validateParameter(valid_593781, JString, required = false,
                                 default = nil)
  if valid_593781 != nil:
    section.add "EnvironmentId", valid_593781
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593782: Call_PostDescribeEnvironmentHealth_593767; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the overall health of the specified environment. The <b>DescribeEnvironmentHealth</b> operation is only available with AWS Elastic Beanstalk Enhanced Health.
  ## 
  let valid = call_593782.validator(path, query, header, formData, body)
  let scheme = call_593782.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593782.url(scheme.get, call_593782.host, call_593782.base,
                         call_593782.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593782, url, valid)

proc call*(call_593783: Call_PostDescribeEnvironmentHealth_593767;
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
  var query_593784 = newJObject()
  var formData_593785 = newJObject()
  add(formData_593785, "EnvironmentName", newJString(EnvironmentName))
  if AttributeNames != nil:
    formData_593785.add "AttributeNames", AttributeNames
  add(query_593784, "Action", newJString(Action))
  add(formData_593785, "EnvironmentId", newJString(EnvironmentId))
  add(query_593784, "Version", newJString(Version))
  result = call_593783.call(nil, query_593784, nil, formData_593785, nil)

var postDescribeEnvironmentHealth* = Call_PostDescribeEnvironmentHealth_593767(
    name: "postDescribeEnvironmentHealth", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentHealth",
    validator: validate_PostDescribeEnvironmentHealth_593768, base: "/",
    url: url_PostDescribeEnvironmentHealth_593769,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentHealth_593749 = ref object of OpenApiRestCall_592365
proc url_GetDescribeEnvironmentHealth_593751(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEnvironmentHealth_593750(path: JsonNode; query: JsonNode;
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
  var valid_593752 = query.getOrDefault("AttributeNames")
  valid_593752 = validateParameter(valid_593752, JArray, required = false,
                                 default = nil)
  if valid_593752 != nil:
    section.add "AttributeNames", valid_593752
  var valid_593753 = query.getOrDefault("EnvironmentName")
  valid_593753 = validateParameter(valid_593753, JString, required = false,
                                 default = nil)
  if valid_593753 != nil:
    section.add "EnvironmentName", valid_593753
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593754 = query.getOrDefault("Action")
  valid_593754 = validateParameter(valid_593754, JString, required = true, default = newJString(
      "DescribeEnvironmentHealth"))
  if valid_593754 != nil:
    section.add "Action", valid_593754
  var valid_593755 = query.getOrDefault("Version")
  valid_593755 = validateParameter(valid_593755, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593755 != nil:
    section.add "Version", valid_593755
  var valid_593756 = query.getOrDefault("EnvironmentId")
  valid_593756 = validateParameter(valid_593756, JString, required = false,
                                 default = nil)
  if valid_593756 != nil:
    section.add "EnvironmentId", valid_593756
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
  var valid_593757 = header.getOrDefault("X-Amz-Signature")
  valid_593757 = validateParameter(valid_593757, JString, required = false,
                                 default = nil)
  if valid_593757 != nil:
    section.add "X-Amz-Signature", valid_593757
  var valid_593758 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593758 = validateParameter(valid_593758, JString, required = false,
                                 default = nil)
  if valid_593758 != nil:
    section.add "X-Amz-Content-Sha256", valid_593758
  var valid_593759 = header.getOrDefault("X-Amz-Date")
  valid_593759 = validateParameter(valid_593759, JString, required = false,
                                 default = nil)
  if valid_593759 != nil:
    section.add "X-Amz-Date", valid_593759
  var valid_593760 = header.getOrDefault("X-Amz-Credential")
  valid_593760 = validateParameter(valid_593760, JString, required = false,
                                 default = nil)
  if valid_593760 != nil:
    section.add "X-Amz-Credential", valid_593760
  var valid_593761 = header.getOrDefault("X-Amz-Security-Token")
  valid_593761 = validateParameter(valid_593761, JString, required = false,
                                 default = nil)
  if valid_593761 != nil:
    section.add "X-Amz-Security-Token", valid_593761
  var valid_593762 = header.getOrDefault("X-Amz-Algorithm")
  valid_593762 = validateParameter(valid_593762, JString, required = false,
                                 default = nil)
  if valid_593762 != nil:
    section.add "X-Amz-Algorithm", valid_593762
  var valid_593763 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593763 = validateParameter(valid_593763, JString, required = false,
                                 default = nil)
  if valid_593763 != nil:
    section.add "X-Amz-SignedHeaders", valid_593763
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593764: Call_GetDescribeEnvironmentHealth_593749; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the overall health of the specified environment. The <b>DescribeEnvironmentHealth</b> operation is only available with AWS Elastic Beanstalk Enhanced Health.
  ## 
  let valid = call_593764.validator(path, query, header, formData, body)
  let scheme = call_593764.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593764.url(scheme.get, call_593764.host, call_593764.base,
                         call_593764.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593764, url, valid)

proc call*(call_593765: Call_GetDescribeEnvironmentHealth_593749;
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
  var query_593766 = newJObject()
  if AttributeNames != nil:
    query_593766.add "AttributeNames", AttributeNames
  add(query_593766, "EnvironmentName", newJString(EnvironmentName))
  add(query_593766, "Action", newJString(Action))
  add(query_593766, "Version", newJString(Version))
  add(query_593766, "EnvironmentId", newJString(EnvironmentId))
  result = call_593765.call(nil, query_593766, nil, nil, nil)

var getDescribeEnvironmentHealth* = Call_GetDescribeEnvironmentHealth_593749(
    name: "getDescribeEnvironmentHealth", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentHealth",
    validator: validate_GetDescribeEnvironmentHealth_593750, base: "/",
    url: url_GetDescribeEnvironmentHealth_593751,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentManagedActionHistory_593805 = ref object of OpenApiRestCall_592365
proc url_PostDescribeEnvironmentManagedActionHistory_593807(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEnvironmentManagedActionHistory_593806(path: JsonNode;
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
  var valid_593808 = query.getOrDefault("Action")
  valid_593808 = validateParameter(valid_593808, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActionHistory"))
  if valid_593808 != nil:
    section.add "Action", valid_593808
  var valid_593809 = query.getOrDefault("Version")
  valid_593809 = validateParameter(valid_593809, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593809 != nil:
    section.add "Version", valid_593809
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
  var valid_593810 = header.getOrDefault("X-Amz-Signature")
  valid_593810 = validateParameter(valid_593810, JString, required = false,
                                 default = nil)
  if valid_593810 != nil:
    section.add "X-Amz-Signature", valid_593810
  var valid_593811 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593811 = validateParameter(valid_593811, JString, required = false,
                                 default = nil)
  if valid_593811 != nil:
    section.add "X-Amz-Content-Sha256", valid_593811
  var valid_593812 = header.getOrDefault("X-Amz-Date")
  valid_593812 = validateParameter(valid_593812, JString, required = false,
                                 default = nil)
  if valid_593812 != nil:
    section.add "X-Amz-Date", valid_593812
  var valid_593813 = header.getOrDefault("X-Amz-Credential")
  valid_593813 = validateParameter(valid_593813, JString, required = false,
                                 default = nil)
  if valid_593813 != nil:
    section.add "X-Amz-Credential", valid_593813
  var valid_593814 = header.getOrDefault("X-Amz-Security-Token")
  valid_593814 = validateParameter(valid_593814, JString, required = false,
                                 default = nil)
  if valid_593814 != nil:
    section.add "X-Amz-Security-Token", valid_593814
  var valid_593815 = header.getOrDefault("X-Amz-Algorithm")
  valid_593815 = validateParameter(valid_593815, JString, required = false,
                                 default = nil)
  if valid_593815 != nil:
    section.add "X-Amz-Algorithm", valid_593815
  var valid_593816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593816 = validateParameter(valid_593816, JString, required = false,
                                 default = nil)
  if valid_593816 != nil:
    section.add "X-Amz-SignedHeaders", valid_593816
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
  var valid_593817 = formData.getOrDefault("NextToken")
  valid_593817 = validateParameter(valid_593817, JString, required = false,
                                 default = nil)
  if valid_593817 != nil:
    section.add "NextToken", valid_593817
  var valid_593818 = formData.getOrDefault("EnvironmentName")
  valid_593818 = validateParameter(valid_593818, JString, required = false,
                                 default = nil)
  if valid_593818 != nil:
    section.add "EnvironmentName", valid_593818
  var valid_593819 = formData.getOrDefault("MaxItems")
  valid_593819 = validateParameter(valid_593819, JInt, required = false, default = nil)
  if valid_593819 != nil:
    section.add "MaxItems", valid_593819
  var valid_593820 = formData.getOrDefault("EnvironmentId")
  valid_593820 = validateParameter(valid_593820, JString, required = false,
                                 default = nil)
  if valid_593820 != nil:
    section.add "EnvironmentId", valid_593820
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593821: Call_PostDescribeEnvironmentManagedActionHistory_593805;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists an environment's completed and failed managed actions.
  ## 
  let valid = call_593821.validator(path, query, header, formData, body)
  let scheme = call_593821.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593821.url(scheme.get, call_593821.host, call_593821.base,
                         call_593821.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593821, url, valid)

proc call*(call_593822: Call_PostDescribeEnvironmentManagedActionHistory_593805;
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
  var query_593823 = newJObject()
  var formData_593824 = newJObject()
  add(formData_593824, "NextToken", newJString(NextToken))
  add(formData_593824, "EnvironmentName", newJString(EnvironmentName))
  add(query_593823, "Action", newJString(Action))
  add(formData_593824, "MaxItems", newJInt(MaxItems))
  add(formData_593824, "EnvironmentId", newJString(EnvironmentId))
  add(query_593823, "Version", newJString(Version))
  result = call_593822.call(nil, query_593823, nil, formData_593824, nil)

var postDescribeEnvironmentManagedActionHistory* = Call_PostDescribeEnvironmentManagedActionHistory_593805(
    name: "postDescribeEnvironmentManagedActionHistory",
    meth: HttpMethod.HttpPost, host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActionHistory",
    validator: validate_PostDescribeEnvironmentManagedActionHistory_593806,
    base: "/", url: url_PostDescribeEnvironmentManagedActionHistory_593807,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentManagedActionHistory_593786 = ref object of OpenApiRestCall_592365
proc url_GetDescribeEnvironmentManagedActionHistory_593788(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEnvironmentManagedActionHistory_593787(path: JsonNode;
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
  var valid_593789 = query.getOrDefault("MaxItems")
  valid_593789 = validateParameter(valid_593789, JInt, required = false, default = nil)
  if valid_593789 != nil:
    section.add "MaxItems", valid_593789
  var valid_593790 = query.getOrDefault("NextToken")
  valid_593790 = validateParameter(valid_593790, JString, required = false,
                                 default = nil)
  if valid_593790 != nil:
    section.add "NextToken", valid_593790
  var valid_593791 = query.getOrDefault("EnvironmentName")
  valid_593791 = validateParameter(valid_593791, JString, required = false,
                                 default = nil)
  if valid_593791 != nil:
    section.add "EnvironmentName", valid_593791
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593792 = query.getOrDefault("Action")
  valid_593792 = validateParameter(valid_593792, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActionHistory"))
  if valid_593792 != nil:
    section.add "Action", valid_593792
  var valid_593793 = query.getOrDefault("Version")
  valid_593793 = validateParameter(valid_593793, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593793 != nil:
    section.add "Version", valid_593793
  var valid_593794 = query.getOrDefault("EnvironmentId")
  valid_593794 = validateParameter(valid_593794, JString, required = false,
                                 default = nil)
  if valid_593794 != nil:
    section.add "EnvironmentId", valid_593794
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
  var valid_593795 = header.getOrDefault("X-Amz-Signature")
  valid_593795 = validateParameter(valid_593795, JString, required = false,
                                 default = nil)
  if valid_593795 != nil:
    section.add "X-Amz-Signature", valid_593795
  var valid_593796 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593796 = validateParameter(valid_593796, JString, required = false,
                                 default = nil)
  if valid_593796 != nil:
    section.add "X-Amz-Content-Sha256", valid_593796
  var valid_593797 = header.getOrDefault("X-Amz-Date")
  valid_593797 = validateParameter(valid_593797, JString, required = false,
                                 default = nil)
  if valid_593797 != nil:
    section.add "X-Amz-Date", valid_593797
  var valid_593798 = header.getOrDefault("X-Amz-Credential")
  valid_593798 = validateParameter(valid_593798, JString, required = false,
                                 default = nil)
  if valid_593798 != nil:
    section.add "X-Amz-Credential", valid_593798
  var valid_593799 = header.getOrDefault("X-Amz-Security-Token")
  valid_593799 = validateParameter(valid_593799, JString, required = false,
                                 default = nil)
  if valid_593799 != nil:
    section.add "X-Amz-Security-Token", valid_593799
  var valid_593800 = header.getOrDefault("X-Amz-Algorithm")
  valid_593800 = validateParameter(valid_593800, JString, required = false,
                                 default = nil)
  if valid_593800 != nil:
    section.add "X-Amz-Algorithm", valid_593800
  var valid_593801 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593801 = validateParameter(valid_593801, JString, required = false,
                                 default = nil)
  if valid_593801 != nil:
    section.add "X-Amz-SignedHeaders", valid_593801
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593802: Call_GetDescribeEnvironmentManagedActionHistory_593786;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists an environment's completed and failed managed actions.
  ## 
  let valid = call_593802.validator(path, query, header, formData, body)
  let scheme = call_593802.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593802.url(scheme.get, call_593802.host, call_593802.base,
                         call_593802.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593802, url, valid)

proc call*(call_593803: Call_GetDescribeEnvironmentManagedActionHistory_593786;
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
  var query_593804 = newJObject()
  add(query_593804, "MaxItems", newJInt(MaxItems))
  add(query_593804, "NextToken", newJString(NextToken))
  add(query_593804, "EnvironmentName", newJString(EnvironmentName))
  add(query_593804, "Action", newJString(Action))
  add(query_593804, "Version", newJString(Version))
  add(query_593804, "EnvironmentId", newJString(EnvironmentId))
  result = call_593803.call(nil, query_593804, nil, nil, nil)

var getDescribeEnvironmentManagedActionHistory* = Call_GetDescribeEnvironmentManagedActionHistory_593786(
    name: "getDescribeEnvironmentManagedActionHistory", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActionHistory",
    validator: validate_GetDescribeEnvironmentManagedActionHistory_593787,
    base: "/", url: url_GetDescribeEnvironmentManagedActionHistory_593788,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentManagedActions_593843 = ref object of OpenApiRestCall_592365
proc url_PostDescribeEnvironmentManagedActions_593845(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEnvironmentManagedActions_593844(path: JsonNode;
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
  var valid_593846 = query.getOrDefault("Action")
  valid_593846 = validateParameter(valid_593846, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActions"))
  if valid_593846 != nil:
    section.add "Action", valid_593846
  var valid_593847 = query.getOrDefault("Version")
  valid_593847 = validateParameter(valid_593847, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593847 != nil:
    section.add "Version", valid_593847
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
  var valid_593848 = header.getOrDefault("X-Amz-Signature")
  valid_593848 = validateParameter(valid_593848, JString, required = false,
                                 default = nil)
  if valid_593848 != nil:
    section.add "X-Amz-Signature", valid_593848
  var valid_593849 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593849 = validateParameter(valid_593849, JString, required = false,
                                 default = nil)
  if valid_593849 != nil:
    section.add "X-Amz-Content-Sha256", valid_593849
  var valid_593850 = header.getOrDefault("X-Amz-Date")
  valid_593850 = validateParameter(valid_593850, JString, required = false,
                                 default = nil)
  if valid_593850 != nil:
    section.add "X-Amz-Date", valid_593850
  var valid_593851 = header.getOrDefault("X-Amz-Credential")
  valid_593851 = validateParameter(valid_593851, JString, required = false,
                                 default = nil)
  if valid_593851 != nil:
    section.add "X-Amz-Credential", valid_593851
  var valid_593852 = header.getOrDefault("X-Amz-Security-Token")
  valid_593852 = validateParameter(valid_593852, JString, required = false,
                                 default = nil)
  if valid_593852 != nil:
    section.add "X-Amz-Security-Token", valid_593852
  var valid_593853 = header.getOrDefault("X-Amz-Algorithm")
  valid_593853 = validateParameter(valid_593853, JString, required = false,
                                 default = nil)
  if valid_593853 != nil:
    section.add "X-Amz-Algorithm", valid_593853
  var valid_593854 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593854 = validateParameter(valid_593854, JString, required = false,
                                 default = nil)
  if valid_593854 != nil:
    section.add "X-Amz-SignedHeaders", valid_593854
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString
  ##                  : The name of the target environment.
  ##   Status: JString
  ##         : To show only actions with a particular status, specify a status.
  ##   EnvironmentId: JString
  ##                : The environment ID of the target environment.
  section = newJObject()
  var valid_593855 = formData.getOrDefault("EnvironmentName")
  valid_593855 = validateParameter(valid_593855, JString, required = false,
                                 default = nil)
  if valid_593855 != nil:
    section.add "EnvironmentName", valid_593855
  var valid_593856 = formData.getOrDefault("Status")
  valid_593856 = validateParameter(valid_593856, JString, required = false,
                                 default = newJString("Scheduled"))
  if valid_593856 != nil:
    section.add "Status", valid_593856
  var valid_593857 = formData.getOrDefault("EnvironmentId")
  valid_593857 = validateParameter(valid_593857, JString, required = false,
                                 default = nil)
  if valid_593857 != nil:
    section.add "EnvironmentId", valid_593857
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593858: Call_PostDescribeEnvironmentManagedActions_593843;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists an environment's upcoming and in-progress managed actions.
  ## 
  let valid = call_593858.validator(path, query, header, formData, body)
  let scheme = call_593858.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593858.url(scheme.get, call_593858.host, call_593858.base,
                         call_593858.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593858, url, valid)

proc call*(call_593859: Call_PostDescribeEnvironmentManagedActions_593843;
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
  var query_593860 = newJObject()
  var formData_593861 = newJObject()
  add(formData_593861, "EnvironmentName", newJString(EnvironmentName))
  add(query_593860, "Action", newJString(Action))
  add(formData_593861, "Status", newJString(Status))
  add(formData_593861, "EnvironmentId", newJString(EnvironmentId))
  add(query_593860, "Version", newJString(Version))
  result = call_593859.call(nil, query_593860, nil, formData_593861, nil)

var postDescribeEnvironmentManagedActions* = Call_PostDescribeEnvironmentManagedActions_593843(
    name: "postDescribeEnvironmentManagedActions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActions",
    validator: validate_PostDescribeEnvironmentManagedActions_593844, base: "/",
    url: url_PostDescribeEnvironmentManagedActions_593845,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentManagedActions_593825 = ref object of OpenApiRestCall_592365
proc url_GetDescribeEnvironmentManagedActions_593827(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEnvironmentManagedActions_593826(path: JsonNode;
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
  var valid_593828 = query.getOrDefault("Status")
  valid_593828 = validateParameter(valid_593828, JString, required = false,
                                 default = newJString("Scheduled"))
  if valid_593828 != nil:
    section.add "Status", valid_593828
  var valid_593829 = query.getOrDefault("EnvironmentName")
  valid_593829 = validateParameter(valid_593829, JString, required = false,
                                 default = nil)
  if valid_593829 != nil:
    section.add "EnvironmentName", valid_593829
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593830 = query.getOrDefault("Action")
  valid_593830 = validateParameter(valid_593830, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActions"))
  if valid_593830 != nil:
    section.add "Action", valid_593830
  var valid_593831 = query.getOrDefault("Version")
  valid_593831 = validateParameter(valid_593831, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593831 != nil:
    section.add "Version", valid_593831
  var valid_593832 = query.getOrDefault("EnvironmentId")
  valid_593832 = validateParameter(valid_593832, JString, required = false,
                                 default = nil)
  if valid_593832 != nil:
    section.add "EnvironmentId", valid_593832
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
  var valid_593833 = header.getOrDefault("X-Amz-Signature")
  valid_593833 = validateParameter(valid_593833, JString, required = false,
                                 default = nil)
  if valid_593833 != nil:
    section.add "X-Amz-Signature", valid_593833
  var valid_593834 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593834 = validateParameter(valid_593834, JString, required = false,
                                 default = nil)
  if valid_593834 != nil:
    section.add "X-Amz-Content-Sha256", valid_593834
  var valid_593835 = header.getOrDefault("X-Amz-Date")
  valid_593835 = validateParameter(valid_593835, JString, required = false,
                                 default = nil)
  if valid_593835 != nil:
    section.add "X-Amz-Date", valid_593835
  var valid_593836 = header.getOrDefault("X-Amz-Credential")
  valid_593836 = validateParameter(valid_593836, JString, required = false,
                                 default = nil)
  if valid_593836 != nil:
    section.add "X-Amz-Credential", valid_593836
  var valid_593837 = header.getOrDefault("X-Amz-Security-Token")
  valid_593837 = validateParameter(valid_593837, JString, required = false,
                                 default = nil)
  if valid_593837 != nil:
    section.add "X-Amz-Security-Token", valid_593837
  var valid_593838 = header.getOrDefault("X-Amz-Algorithm")
  valid_593838 = validateParameter(valid_593838, JString, required = false,
                                 default = nil)
  if valid_593838 != nil:
    section.add "X-Amz-Algorithm", valid_593838
  var valid_593839 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593839 = validateParameter(valid_593839, JString, required = false,
                                 default = nil)
  if valid_593839 != nil:
    section.add "X-Amz-SignedHeaders", valid_593839
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593840: Call_GetDescribeEnvironmentManagedActions_593825;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists an environment's upcoming and in-progress managed actions.
  ## 
  let valid = call_593840.validator(path, query, header, formData, body)
  let scheme = call_593840.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593840.url(scheme.get, call_593840.host, call_593840.base,
                         call_593840.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593840, url, valid)

proc call*(call_593841: Call_GetDescribeEnvironmentManagedActions_593825;
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
  var query_593842 = newJObject()
  add(query_593842, "Status", newJString(Status))
  add(query_593842, "EnvironmentName", newJString(EnvironmentName))
  add(query_593842, "Action", newJString(Action))
  add(query_593842, "Version", newJString(Version))
  add(query_593842, "EnvironmentId", newJString(EnvironmentId))
  result = call_593841.call(nil, query_593842, nil, nil, nil)

var getDescribeEnvironmentManagedActions* = Call_GetDescribeEnvironmentManagedActions_593825(
    name: "getDescribeEnvironmentManagedActions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActions",
    validator: validate_GetDescribeEnvironmentManagedActions_593826, base: "/",
    url: url_GetDescribeEnvironmentManagedActions_593827,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentResources_593879 = ref object of OpenApiRestCall_592365
proc url_PostDescribeEnvironmentResources_593881(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEnvironmentResources_593880(path: JsonNode;
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
  var valid_593882 = query.getOrDefault("Action")
  valid_593882 = validateParameter(valid_593882, JString, required = true, default = newJString(
      "DescribeEnvironmentResources"))
  if valid_593882 != nil:
    section.add "Action", valid_593882
  var valid_593883 = query.getOrDefault("Version")
  valid_593883 = validateParameter(valid_593883, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593883 != nil:
    section.add "Version", valid_593883
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
  var valid_593884 = header.getOrDefault("X-Amz-Signature")
  valid_593884 = validateParameter(valid_593884, JString, required = false,
                                 default = nil)
  if valid_593884 != nil:
    section.add "X-Amz-Signature", valid_593884
  var valid_593885 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593885 = validateParameter(valid_593885, JString, required = false,
                                 default = nil)
  if valid_593885 != nil:
    section.add "X-Amz-Content-Sha256", valid_593885
  var valid_593886 = header.getOrDefault("X-Amz-Date")
  valid_593886 = validateParameter(valid_593886, JString, required = false,
                                 default = nil)
  if valid_593886 != nil:
    section.add "X-Amz-Date", valid_593886
  var valid_593887 = header.getOrDefault("X-Amz-Credential")
  valid_593887 = validateParameter(valid_593887, JString, required = false,
                                 default = nil)
  if valid_593887 != nil:
    section.add "X-Amz-Credential", valid_593887
  var valid_593888 = header.getOrDefault("X-Amz-Security-Token")
  valid_593888 = validateParameter(valid_593888, JString, required = false,
                                 default = nil)
  if valid_593888 != nil:
    section.add "X-Amz-Security-Token", valid_593888
  var valid_593889 = header.getOrDefault("X-Amz-Algorithm")
  valid_593889 = validateParameter(valid_593889, JString, required = false,
                                 default = nil)
  if valid_593889 != nil:
    section.add "X-Amz-Algorithm", valid_593889
  var valid_593890 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593890 = validateParameter(valid_593890, JString, required = false,
                                 default = nil)
  if valid_593890 != nil:
    section.add "X-Amz-SignedHeaders", valid_593890
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to retrieve AWS resource usage data.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to retrieve AWS resource usage data.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_593891 = formData.getOrDefault("EnvironmentName")
  valid_593891 = validateParameter(valid_593891, JString, required = false,
                                 default = nil)
  if valid_593891 != nil:
    section.add "EnvironmentName", valid_593891
  var valid_593892 = formData.getOrDefault("EnvironmentId")
  valid_593892 = validateParameter(valid_593892, JString, required = false,
                                 default = nil)
  if valid_593892 != nil:
    section.add "EnvironmentId", valid_593892
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593893: Call_PostDescribeEnvironmentResources_593879;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns AWS resources for this environment.
  ## 
  let valid = call_593893.validator(path, query, header, formData, body)
  let scheme = call_593893.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593893.url(scheme.get, call_593893.host, call_593893.base,
                         call_593893.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593893, url, valid)

proc call*(call_593894: Call_PostDescribeEnvironmentResources_593879;
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
  var query_593895 = newJObject()
  var formData_593896 = newJObject()
  add(formData_593896, "EnvironmentName", newJString(EnvironmentName))
  add(query_593895, "Action", newJString(Action))
  add(formData_593896, "EnvironmentId", newJString(EnvironmentId))
  add(query_593895, "Version", newJString(Version))
  result = call_593894.call(nil, query_593895, nil, formData_593896, nil)

var postDescribeEnvironmentResources* = Call_PostDescribeEnvironmentResources_593879(
    name: "postDescribeEnvironmentResources", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentResources",
    validator: validate_PostDescribeEnvironmentResources_593880, base: "/",
    url: url_PostDescribeEnvironmentResources_593881,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentResources_593862 = ref object of OpenApiRestCall_592365
proc url_GetDescribeEnvironmentResources_593864(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEnvironmentResources_593863(path: JsonNode;
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
  var valid_593865 = query.getOrDefault("EnvironmentName")
  valid_593865 = validateParameter(valid_593865, JString, required = false,
                                 default = nil)
  if valid_593865 != nil:
    section.add "EnvironmentName", valid_593865
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593866 = query.getOrDefault("Action")
  valid_593866 = validateParameter(valid_593866, JString, required = true, default = newJString(
      "DescribeEnvironmentResources"))
  if valid_593866 != nil:
    section.add "Action", valid_593866
  var valid_593867 = query.getOrDefault("Version")
  valid_593867 = validateParameter(valid_593867, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593867 != nil:
    section.add "Version", valid_593867
  var valid_593868 = query.getOrDefault("EnvironmentId")
  valid_593868 = validateParameter(valid_593868, JString, required = false,
                                 default = nil)
  if valid_593868 != nil:
    section.add "EnvironmentId", valid_593868
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
  var valid_593869 = header.getOrDefault("X-Amz-Signature")
  valid_593869 = validateParameter(valid_593869, JString, required = false,
                                 default = nil)
  if valid_593869 != nil:
    section.add "X-Amz-Signature", valid_593869
  var valid_593870 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593870 = validateParameter(valid_593870, JString, required = false,
                                 default = nil)
  if valid_593870 != nil:
    section.add "X-Amz-Content-Sha256", valid_593870
  var valid_593871 = header.getOrDefault("X-Amz-Date")
  valid_593871 = validateParameter(valid_593871, JString, required = false,
                                 default = nil)
  if valid_593871 != nil:
    section.add "X-Amz-Date", valid_593871
  var valid_593872 = header.getOrDefault("X-Amz-Credential")
  valid_593872 = validateParameter(valid_593872, JString, required = false,
                                 default = nil)
  if valid_593872 != nil:
    section.add "X-Amz-Credential", valid_593872
  var valid_593873 = header.getOrDefault("X-Amz-Security-Token")
  valid_593873 = validateParameter(valid_593873, JString, required = false,
                                 default = nil)
  if valid_593873 != nil:
    section.add "X-Amz-Security-Token", valid_593873
  var valid_593874 = header.getOrDefault("X-Amz-Algorithm")
  valid_593874 = validateParameter(valid_593874, JString, required = false,
                                 default = nil)
  if valid_593874 != nil:
    section.add "X-Amz-Algorithm", valid_593874
  var valid_593875 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593875 = validateParameter(valid_593875, JString, required = false,
                                 default = nil)
  if valid_593875 != nil:
    section.add "X-Amz-SignedHeaders", valid_593875
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593876: Call_GetDescribeEnvironmentResources_593862;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns AWS resources for this environment.
  ## 
  let valid = call_593876.validator(path, query, header, formData, body)
  let scheme = call_593876.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593876.url(scheme.get, call_593876.host, call_593876.base,
                         call_593876.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593876, url, valid)

proc call*(call_593877: Call_GetDescribeEnvironmentResources_593862;
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
  var query_593878 = newJObject()
  add(query_593878, "EnvironmentName", newJString(EnvironmentName))
  add(query_593878, "Action", newJString(Action))
  add(query_593878, "Version", newJString(Version))
  add(query_593878, "EnvironmentId", newJString(EnvironmentId))
  result = call_593877.call(nil, query_593878, nil, nil, nil)

var getDescribeEnvironmentResources* = Call_GetDescribeEnvironmentResources_593862(
    name: "getDescribeEnvironmentResources", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentResources",
    validator: validate_GetDescribeEnvironmentResources_593863, base: "/",
    url: url_GetDescribeEnvironmentResources_593864,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironments_593920 = ref object of OpenApiRestCall_592365
proc url_PostDescribeEnvironments_593922(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEnvironments_593921(path: JsonNode; query: JsonNode;
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
  var valid_593923 = query.getOrDefault("Action")
  valid_593923 = validateParameter(valid_593923, JString, required = true,
                                 default = newJString("DescribeEnvironments"))
  if valid_593923 != nil:
    section.add "Action", valid_593923
  var valid_593924 = query.getOrDefault("Version")
  valid_593924 = validateParameter(valid_593924, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593924 != nil:
    section.add "Version", valid_593924
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
  var valid_593925 = header.getOrDefault("X-Amz-Signature")
  valid_593925 = validateParameter(valid_593925, JString, required = false,
                                 default = nil)
  if valid_593925 != nil:
    section.add "X-Amz-Signature", valid_593925
  var valid_593926 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593926 = validateParameter(valid_593926, JString, required = false,
                                 default = nil)
  if valid_593926 != nil:
    section.add "X-Amz-Content-Sha256", valid_593926
  var valid_593927 = header.getOrDefault("X-Amz-Date")
  valid_593927 = validateParameter(valid_593927, JString, required = false,
                                 default = nil)
  if valid_593927 != nil:
    section.add "X-Amz-Date", valid_593927
  var valid_593928 = header.getOrDefault("X-Amz-Credential")
  valid_593928 = validateParameter(valid_593928, JString, required = false,
                                 default = nil)
  if valid_593928 != nil:
    section.add "X-Amz-Credential", valid_593928
  var valid_593929 = header.getOrDefault("X-Amz-Security-Token")
  valid_593929 = validateParameter(valid_593929, JString, required = false,
                                 default = nil)
  if valid_593929 != nil:
    section.add "X-Amz-Security-Token", valid_593929
  var valid_593930 = header.getOrDefault("X-Amz-Algorithm")
  valid_593930 = validateParameter(valid_593930, JString, required = false,
                                 default = nil)
  if valid_593930 != nil:
    section.add "X-Amz-Algorithm", valid_593930
  var valid_593931 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593931 = validateParameter(valid_593931, JString, required = false,
                                 default = nil)
  if valid_593931 != nil:
    section.add "X-Amz-SignedHeaders", valid_593931
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
  var valid_593932 = formData.getOrDefault("EnvironmentNames")
  valid_593932 = validateParameter(valid_593932, JArray, required = false,
                                 default = nil)
  if valid_593932 != nil:
    section.add "EnvironmentNames", valid_593932
  var valid_593933 = formData.getOrDefault("MaxRecords")
  valid_593933 = validateParameter(valid_593933, JInt, required = false, default = nil)
  if valid_593933 != nil:
    section.add "MaxRecords", valid_593933
  var valid_593934 = formData.getOrDefault("VersionLabel")
  valid_593934 = validateParameter(valid_593934, JString, required = false,
                                 default = nil)
  if valid_593934 != nil:
    section.add "VersionLabel", valid_593934
  var valid_593935 = formData.getOrDefault("NextToken")
  valid_593935 = validateParameter(valid_593935, JString, required = false,
                                 default = nil)
  if valid_593935 != nil:
    section.add "NextToken", valid_593935
  var valid_593936 = formData.getOrDefault("ApplicationName")
  valid_593936 = validateParameter(valid_593936, JString, required = false,
                                 default = nil)
  if valid_593936 != nil:
    section.add "ApplicationName", valid_593936
  var valid_593937 = formData.getOrDefault("IncludedDeletedBackTo")
  valid_593937 = validateParameter(valid_593937, JString, required = false,
                                 default = nil)
  if valid_593937 != nil:
    section.add "IncludedDeletedBackTo", valid_593937
  var valid_593938 = formData.getOrDefault("EnvironmentIds")
  valid_593938 = validateParameter(valid_593938, JArray, required = false,
                                 default = nil)
  if valid_593938 != nil:
    section.add "EnvironmentIds", valid_593938
  var valid_593939 = formData.getOrDefault("IncludeDeleted")
  valid_593939 = validateParameter(valid_593939, JBool, required = false, default = nil)
  if valid_593939 != nil:
    section.add "IncludeDeleted", valid_593939
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593940: Call_PostDescribeEnvironments_593920; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns descriptions for existing environments.
  ## 
  let valid = call_593940.validator(path, query, header, formData, body)
  let scheme = call_593940.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593940.url(scheme.get, call_593940.host, call_593940.base,
                         call_593940.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593940, url, valid)

proc call*(call_593941: Call_PostDescribeEnvironments_593920;
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
  var query_593942 = newJObject()
  var formData_593943 = newJObject()
  if EnvironmentNames != nil:
    formData_593943.add "EnvironmentNames", EnvironmentNames
  add(formData_593943, "MaxRecords", newJInt(MaxRecords))
  add(formData_593943, "VersionLabel", newJString(VersionLabel))
  add(formData_593943, "NextToken", newJString(NextToken))
  add(formData_593943, "ApplicationName", newJString(ApplicationName))
  add(query_593942, "Action", newJString(Action))
  add(query_593942, "Version", newJString(Version))
  add(formData_593943, "IncludedDeletedBackTo", newJString(IncludedDeletedBackTo))
  if EnvironmentIds != nil:
    formData_593943.add "EnvironmentIds", EnvironmentIds
  add(formData_593943, "IncludeDeleted", newJBool(IncludeDeleted))
  result = call_593941.call(nil, query_593942, nil, formData_593943, nil)

var postDescribeEnvironments* = Call_PostDescribeEnvironments_593920(
    name: "postDescribeEnvironments", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironments",
    validator: validate_PostDescribeEnvironments_593921, base: "/",
    url: url_PostDescribeEnvironments_593922, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironments_593897 = ref object of OpenApiRestCall_592365
proc url_GetDescribeEnvironments_593899(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEnvironments_593898(path: JsonNode; query: JsonNode;
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
  var valid_593900 = query.getOrDefault("ApplicationName")
  valid_593900 = validateParameter(valid_593900, JString, required = false,
                                 default = nil)
  if valid_593900 != nil:
    section.add "ApplicationName", valid_593900
  var valid_593901 = query.getOrDefault("VersionLabel")
  valid_593901 = validateParameter(valid_593901, JString, required = false,
                                 default = nil)
  if valid_593901 != nil:
    section.add "VersionLabel", valid_593901
  var valid_593902 = query.getOrDefault("IncludeDeleted")
  valid_593902 = validateParameter(valid_593902, JBool, required = false, default = nil)
  if valid_593902 != nil:
    section.add "IncludeDeleted", valid_593902
  var valid_593903 = query.getOrDefault("NextToken")
  valid_593903 = validateParameter(valid_593903, JString, required = false,
                                 default = nil)
  if valid_593903 != nil:
    section.add "NextToken", valid_593903
  var valid_593904 = query.getOrDefault("EnvironmentNames")
  valid_593904 = validateParameter(valid_593904, JArray, required = false,
                                 default = nil)
  if valid_593904 != nil:
    section.add "EnvironmentNames", valid_593904
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593905 = query.getOrDefault("Action")
  valid_593905 = validateParameter(valid_593905, JString, required = true,
                                 default = newJString("DescribeEnvironments"))
  if valid_593905 != nil:
    section.add "Action", valid_593905
  var valid_593906 = query.getOrDefault("EnvironmentIds")
  valid_593906 = validateParameter(valid_593906, JArray, required = false,
                                 default = nil)
  if valid_593906 != nil:
    section.add "EnvironmentIds", valid_593906
  var valid_593907 = query.getOrDefault("IncludedDeletedBackTo")
  valid_593907 = validateParameter(valid_593907, JString, required = false,
                                 default = nil)
  if valid_593907 != nil:
    section.add "IncludedDeletedBackTo", valid_593907
  var valid_593908 = query.getOrDefault("Version")
  valid_593908 = validateParameter(valid_593908, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593908 != nil:
    section.add "Version", valid_593908
  var valid_593909 = query.getOrDefault("MaxRecords")
  valid_593909 = validateParameter(valid_593909, JInt, required = false, default = nil)
  if valid_593909 != nil:
    section.add "MaxRecords", valid_593909
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
  var valid_593910 = header.getOrDefault("X-Amz-Signature")
  valid_593910 = validateParameter(valid_593910, JString, required = false,
                                 default = nil)
  if valid_593910 != nil:
    section.add "X-Amz-Signature", valid_593910
  var valid_593911 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593911 = validateParameter(valid_593911, JString, required = false,
                                 default = nil)
  if valid_593911 != nil:
    section.add "X-Amz-Content-Sha256", valid_593911
  var valid_593912 = header.getOrDefault("X-Amz-Date")
  valid_593912 = validateParameter(valid_593912, JString, required = false,
                                 default = nil)
  if valid_593912 != nil:
    section.add "X-Amz-Date", valid_593912
  var valid_593913 = header.getOrDefault("X-Amz-Credential")
  valid_593913 = validateParameter(valid_593913, JString, required = false,
                                 default = nil)
  if valid_593913 != nil:
    section.add "X-Amz-Credential", valid_593913
  var valid_593914 = header.getOrDefault("X-Amz-Security-Token")
  valid_593914 = validateParameter(valid_593914, JString, required = false,
                                 default = nil)
  if valid_593914 != nil:
    section.add "X-Amz-Security-Token", valid_593914
  var valid_593915 = header.getOrDefault("X-Amz-Algorithm")
  valid_593915 = validateParameter(valid_593915, JString, required = false,
                                 default = nil)
  if valid_593915 != nil:
    section.add "X-Amz-Algorithm", valid_593915
  var valid_593916 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593916 = validateParameter(valid_593916, JString, required = false,
                                 default = nil)
  if valid_593916 != nil:
    section.add "X-Amz-SignedHeaders", valid_593916
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593917: Call_GetDescribeEnvironments_593897; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns descriptions for existing environments.
  ## 
  let valid = call_593917.validator(path, query, header, formData, body)
  let scheme = call_593917.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593917.url(scheme.get, call_593917.host, call_593917.base,
                         call_593917.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593917, url, valid)

proc call*(call_593918: Call_GetDescribeEnvironments_593897;
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
  var query_593919 = newJObject()
  add(query_593919, "ApplicationName", newJString(ApplicationName))
  add(query_593919, "VersionLabel", newJString(VersionLabel))
  add(query_593919, "IncludeDeleted", newJBool(IncludeDeleted))
  add(query_593919, "NextToken", newJString(NextToken))
  if EnvironmentNames != nil:
    query_593919.add "EnvironmentNames", EnvironmentNames
  add(query_593919, "Action", newJString(Action))
  if EnvironmentIds != nil:
    query_593919.add "EnvironmentIds", EnvironmentIds
  add(query_593919, "IncludedDeletedBackTo", newJString(IncludedDeletedBackTo))
  add(query_593919, "Version", newJString(Version))
  add(query_593919, "MaxRecords", newJInt(MaxRecords))
  result = call_593918.call(nil, query_593919, nil, nil, nil)

var getDescribeEnvironments* = Call_GetDescribeEnvironments_593897(
    name: "getDescribeEnvironments", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironments",
    validator: validate_GetDescribeEnvironments_593898, base: "/",
    url: url_GetDescribeEnvironments_593899, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_593971 = ref object of OpenApiRestCall_592365
proc url_PostDescribeEvents_593973(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEvents_593972(path: JsonNode; query: JsonNode;
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
  var valid_593974 = query.getOrDefault("Action")
  valid_593974 = validateParameter(valid_593974, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_593974 != nil:
    section.add "Action", valid_593974
  var valid_593975 = query.getOrDefault("Version")
  valid_593975 = validateParameter(valid_593975, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593975 != nil:
    section.add "Version", valid_593975
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
  var valid_593976 = header.getOrDefault("X-Amz-Signature")
  valid_593976 = validateParameter(valid_593976, JString, required = false,
                                 default = nil)
  if valid_593976 != nil:
    section.add "X-Amz-Signature", valid_593976
  var valid_593977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593977 = validateParameter(valid_593977, JString, required = false,
                                 default = nil)
  if valid_593977 != nil:
    section.add "X-Amz-Content-Sha256", valid_593977
  var valid_593978 = header.getOrDefault("X-Amz-Date")
  valid_593978 = validateParameter(valid_593978, JString, required = false,
                                 default = nil)
  if valid_593978 != nil:
    section.add "X-Amz-Date", valid_593978
  var valid_593979 = header.getOrDefault("X-Amz-Credential")
  valid_593979 = validateParameter(valid_593979, JString, required = false,
                                 default = nil)
  if valid_593979 != nil:
    section.add "X-Amz-Credential", valid_593979
  var valid_593980 = header.getOrDefault("X-Amz-Security-Token")
  valid_593980 = validateParameter(valid_593980, JString, required = false,
                                 default = nil)
  if valid_593980 != nil:
    section.add "X-Amz-Security-Token", valid_593980
  var valid_593981 = header.getOrDefault("X-Amz-Algorithm")
  valid_593981 = validateParameter(valid_593981, JString, required = false,
                                 default = nil)
  if valid_593981 != nil:
    section.add "X-Amz-Algorithm", valid_593981
  var valid_593982 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593982 = validateParameter(valid_593982, JString, required = false,
                                 default = nil)
  if valid_593982 != nil:
    section.add "X-Amz-SignedHeaders", valid_593982
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
  var valid_593983 = formData.getOrDefault("NextToken")
  valid_593983 = validateParameter(valid_593983, JString, required = false,
                                 default = nil)
  if valid_593983 != nil:
    section.add "NextToken", valid_593983
  var valid_593984 = formData.getOrDefault("MaxRecords")
  valid_593984 = validateParameter(valid_593984, JInt, required = false, default = nil)
  if valid_593984 != nil:
    section.add "MaxRecords", valid_593984
  var valid_593985 = formData.getOrDefault("VersionLabel")
  valid_593985 = validateParameter(valid_593985, JString, required = false,
                                 default = nil)
  if valid_593985 != nil:
    section.add "VersionLabel", valid_593985
  var valid_593986 = formData.getOrDefault("EnvironmentName")
  valid_593986 = validateParameter(valid_593986, JString, required = false,
                                 default = nil)
  if valid_593986 != nil:
    section.add "EnvironmentName", valid_593986
  var valid_593987 = formData.getOrDefault("TemplateName")
  valid_593987 = validateParameter(valid_593987, JString, required = false,
                                 default = nil)
  if valid_593987 != nil:
    section.add "TemplateName", valid_593987
  var valid_593988 = formData.getOrDefault("ApplicationName")
  valid_593988 = validateParameter(valid_593988, JString, required = false,
                                 default = nil)
  if valid_593988 != nil:
    section.add "ApplicationName", valid_593988
  var valid_593989 = formData.getOrDefault("EndTime")
  valid_593989 = validateParameter(valid_593989, JString, required = false,
                                 default = nil)
  if valid_593989 != nil:
    section.add "EndTime", valid_593989
  var valid_593990 = formData.getOrDefault("StartTime")
  valid_593990 = validateParameter(valid_593990, JString, required = false,
                                 default = nil)
  if valid_593990 != nil:
    section.add "StartTime", valid_593990
  var valid_593991 = formData.getOrDefault("Severity")
  valid_593991 = validateParameter(valid_593991, JString, required = false,
                                 default = newJString("TRACE"))
  if valid_593991 != nil:
    section.add "Severity", valid_593991
  var valid_593992 = formData.getOrDefault("RequestId")
  valid_593992 = validateParameter(valid_593992, JString, required = false,
                                 default = nil)
  if valid_593992 != nil:
    section.add "RequestId", valid_593992
  var valid_593993 = formData.getOrDefault("EnvironmentId")
  valid_593993 = validateParameter(valid_593993, JString, required = false,
                                 default = nil)
  if valid_593993 != nil:
    section.add "EnvironmentId", valid_593993
  var valid_593994 = formData.getOrDefault("PlatformArn")
  valid_593994 = validateParameter(valid_593994, JString, required = false,
                                 default = nil)
  if valid_593994 != nil:
    section.add "PlatformArn", valid_593994
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593995: Call_PostDescribeEvents_593971; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns list of event descriptions matching criteria up to the last 6 weeks.</p> <note> <p>This action returns the most recent 1,000 events from the specified <code>NextToken</code>.</p> </note>
  ## 
  let valid = call_593995.validator(path, query, header, formData, body)
  let scheme = call_593995.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593995.url(scheme.get, call_593995.host, call_593995.base,
                         call_593995.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593995, url, valid)

proc call*(call_593996: Call_PostDescribeEvents_593971; NextToken: string = "";
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
  var query_593997 = newJObject()
  var formData_593998 = newJObject()
  add(formData_593998, "NextToken", newJString(NextToken))
  add(formData_593998, "MaxRecords", newJInt(MaxRecords))
  add(formData_593998, "VersionLabel", newJString(VersionLabel))
  add(formData_593998, "EnvironmentName", newJString(EnvironmentName))
  add(formData_593998, "TemplateName", newJString(TemplateName))
  add(formData_593998, "ApplicationName", newJString(ApplicationName))
  add(formData_593998, "EndTime", newJString(EndTime))
  add(formData_593998, "StartTime", newJString(StartTime))
  add(formData_593998, "Severity", newJString(Severity))
  add(query_593997, "Action", newJString(Action))
  add(formData_593998, "RequestId", newJString(RequestId))
  add(formData_593998, "EnvironmentId", newJString(EnvironmentId))
  add(query_593997, "Version", newJString(Version))
  add(formData_593998, "PlatformArn", newJString(PlatformArn))
  result = call_593996.call(nil, query_593997, nil, formData_593998, nil)

var postDescribeEvents* = Call_PostDescribeEvents_593971(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_593972, base: "/",
    url: url_PostDescribeEvents_593973, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_593944 = ref object of OpenApiRestCall_592365
proc url_GetDescribeEvents_593946(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEvents_593945(path: JsonNode; query: JsonNode;
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
  var valid_593947 = query.getOrDefault("RequestId")
  valid_593947 = validateParameter(valid_593947, JString, required = false,
                                 default = nil)
  if valid_593947 != nil:
    section.add "RequestId", valid_593947
  var valid_593948 = query.getOrDefault("ApplicationName")
  valid_593948 = validateParameter(valid_593948, JString, required = false,
                                 default = nil)
  if valid_593948 != nil:
    section.add "ApplicationName", valid_593948
  var valid_593949 = query.getOrDefault("VersionLabel")
  valid_593949 = validateParameter(valid_593949, JString, required = false,
                                 default = nil)
  if valid_593949 != nil:
    section.add "VersionLabel", valid_593949
  var valid_593950 = query.getOrDefault("NextToken")
  valid_593950 = validateParameter(valid_593950, JString, required = false,
                                 default = nil)
  if valid_593950 != nil:
    section.add "NextToken", valid_593950
  var valid_593951 = query.getOrDefault("Severity")
  valid_593951 = validateParameter(valid_593951, JString, required = false,
                                 default = newJString("TRACE"))
  if valid_593951 != nil:
    section.add "Severity", valid_593951
  var valid_593952 = query.getOrDefault("EnvironmentName")
  valid_593952 = validateParameter(valid_593952, JString, required = false,
                                 default = nil)
  if valid_593952 != nil:
    section.add "EnvironmentName", valid_593952
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_593953 = query.getOrDefault("Action")
  valid_593953 = validateParameter(valid_593953, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_593953 != nil:
    section.add "Action", valid_593953
  var valid_593954 = query.getOrDefault("StartTime")
  valid_593954 = validateParameter(valid_593954, JString, required = false,
                                 default = nil)
  if valid_593954 != nil:
    section.add "StartTime", valid_593954
  var valid_593955 = query.getOrDefault("PlatformArn")
  valid_593955 = validateParameter(valid_593955, JString, required = false,
                                 default = nil)
  if valid_593955 != nil:
    section.add "PlatformArn", valid_593955
  var valid_593956 = query.getOrDefault("EndTime")
  valid_593956 = validateParameter(valid_593956, JString, required = false,
                                 default = nil)
  if valid_593956 != nil:
    section.add "EndTime", valid_593956
  var valid_593957 = query.getOrDefault("Version")
  valid_593957 = validateParameter(valid_593957, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_593957 != nil:
    section.add "Version", valid_593957
  var valid_593958 = query.getOrDefault("TemplateName")
  valid_593958 = validateParameter(valid_593958, JString, required = false,
                                 default = nil)
  if valid_593958 != nil:
    section.add "TemplateName", valid_593958
  var valid_593959 = query.getOrDefault("MaxRecords")
  valid_593959 = validateParameter(valid_593959, JInt, required = false, default = nil)
  if valid_593959 != nil:
    section.add "MaxRecords", valid_593959
  var valid_593960 = query.getOrDefault("EnvironmentId")
  valid_593960 = validateParameter(valid_593960, JString, required = false,
                                 default = nil)
  if valid_593960 != nil:
    section.add "EnvironmentId", valid_593960
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
  var valid_593961 = header.getOrDefault("X-Amz-Signature")
  valid_593961 = validateParameter(valid_593961, JString, required = false,
                                 default = nil)
  if valid_593961 != nil:
    section.add "X-Amz-Signature", valid_593961
  var valid_593962 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593962 = validateParameter(valid_593962, JString, required = false,
                                 default = nil)
  if valid_593962 != nil:
    section.add "X-Amz-Content-Sha256", valid_593962
  var valid_593963 = header.getOrDefault("X-Amz-Date")
  valid_593963 = validateParameter(valid_593963, JString, required = false,
                                 default = nil)
  if valid_593963 != nil:
    section.add "X-Amz-Date", valid_593963
  var valid_593964 = header.getOrDefault("X-Amz-Credential")
  valid_593964 = validateParameter(valid_593964, JString, required = false,
                                 default = nil)
  if valid_593964 != nil:
    section.add "X-Amz-Credential", valid_593964
  var valid_593965 = header.getOrDefault("X-Amz-Security-Token")
  valid_593965 = validateParameter(valid_593965, JString, required = false,
                                 default = nil)
  if valid_593965 != nil:
    section.add "X-Amz-Security-Token", valid_593965
  var valid_593966 = header.getOrDefault("X-Amz-Algorithm")
  valid_593966 = validateParameter(valid_593966, JString, required = false,
                                 default = nil)
  if valid_593966 != nil:
    section.add "X-Amz-Algorithm", valid_593966
  var valid_593967 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593967 = validateParameter(valid_593967, JString, required = false,
                                 default = nil)
  if valid_593967 != nil:
    section.add "X-Amz-SignedHeaders", valid_593967
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593968: Call_GetDescribeEvents_593944; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns list of event descriptions matching criteria up to the last 6 weeks.</p> <note> <p>This action returns the most recent 1,000 events from the specified <code>NextToken</code>.</p> </note>
  ## 
  let valid = call_593968.validator(path, query, header, formData, body)
  let scheme = call_593968.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593968.url(scheme.get, call_593968.host, call_593968.base,
                         call_593968.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593968, url, valid)

proc call*(call_593969: Call_GetDescribeEvents_593944; RequestId: string = "";
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
  var query_593970 = newJObject()
  add(query_593970, "RequestId", newJString(RequestId))
  add(query_593970, "ApplicationName", newJString(ApplicationName))
  add(query_593970, "VersionLabel", newJString(VersionLabel))
  add(query_593970, "NextToken", newJString(NextToken))
  add(query_593970, "Severity", newJString(Severity))
  add(query_593970, "EnvironmentName", newJString(EnvironmentName))
  add(query_593970, "Action", newJString(Action))
  add(query_593970, "StartTime", newJString(StartTime))
  add(query_593970, "PlatformArn", newJString(PlatformArn))
  add(query_593970, "EndTime", newJString(EndTime))
  add(query_593970, "Version", newJString(Version))
  add(query_593970, "TemplateName", newJString(TemplateName))
  add(query_593970, "MaxRecords", newJInt(MaxRecords))
  add(query_593970, "EnvironmentId", newJString(EnvironmentId))
  result = call_593969.call(nil, query_593970, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_593944(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_593945,
    base: "/", url: url_GetDescribeEvents_593946,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeInstancesHealth_594018 = ref object of OpenApiRestCall_592365
proc url_PostDescribeInstancesHealth_594020(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeInstancesHealth_594019(path: JsonNode; query: JsonNode;
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
  var valid_594021 = query.getOrDefault("Action")
  valid_594021 = validateParameter(valid_594021, JString, required = true, default = newJString(
      "DescribeInstancesHealth"))
  if valid_594021 != nil:
    section.add "Action", valid_594021
  var valid_594022 = query.getOrDefault("Version")
  valid_594022 = validateParameter(valid_594022, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594022 != nil:
    section.add "Version", valid_594022
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
  var valid_594023 = header.getOrDefault("X-Amz-Signature")
  valid_594023 = validateParameter(valid_594023, JString, required = false,
                                 default = nil)
  if valid_594023 != nil:
    section.add "X-Amz-Signature", valid_594023
  var valid_594024 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594024 = validateParameter(valid_594024, JString, required = false,
                                 default = nil)
  if valid_594024 != nil:
    section.add "X-Amz-Content-Sha256", valid_594024
  var valid_594025 = header.getOrDefault("X-Amz-Date")
  valid_594025 = validateParameter(valid_594025, JString, required = false,
                                 default = nil)
  if valid_594025 != nil:
    section.add "X-Amz-Date", valid_594025
  var valid_594026 = header.getOrDefault("X-Amz-Credential")
  valid_594026 = validateParameter(valid_594026, JString, required = false,
                                 default = nil)
  if valid_594026 != nil:
    section.add "X-Amz-Credential", valid_594026
  var valid_594027 = header.getOrDefault("X-Amz-Security-Token")
  valid_594027 = validateParameter(valid_594027, JString, required = false,
                                 default = nil)
  if valid_594027 != nil:
    section.add "X-Amz-Security-Token", valid_594027
  var valid_594028 = header.getOrDefault("X-Amz-Algorithm")
  valid_594028 = validateParameter(valid_594028, JString, required = false,
                                 default = nil)
  if valid_594028 != nil:
    section.add "X-Amz-Algorithm", valid_594028
  var valid_594029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594029 = validateParameter(valid_594029, JString, required = false,
                                 default = nil)
  if valid_594029 != nil:
    section.add "X-Amz-SignedHeaders", valid_594029
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
  var valid_594030 = formData.getOrDefault("NextToken")
  valid_594030 = validateParameter(valid_594030, JString, required = false,
                                 default = nil)
  if valid_594030 != nil:
    section.add "NextToken", valid_594030
  var valid_594031 = formData.getOrDefault("EnvironmentName")
  valid_594031 = validateParameter(valid_594031, JString, required = false,
                                 default = nil)
  if valid_594031 != nil:
    section.add "EnvironmentName", valid_594031
  var valid_594032 = formData.getOrDefault("AttributeNames")
  valid_594032 = validateParameter(valid_594032, JArray, required = false,
                                 default = nil)
  if valid_594032 != nil:
    section.add "AttributeNames", valid_594032
  var valid_594033 = formData.getOrDefault("EnvironmentId")
  valid_594033 = validateParameter(valid_594033, JString, required = false,
                                 default = nil)
  if valid_594033 != nil:
    section.add "EnvironmentId", valid_594033
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594034: Call_PostDescribeInstancesHealth_594018; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves detailed information about the health of instances in your AWS Elastic Beanstalk. This operation requires <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/health-enhanced.html">enhanced health reporting</a>.
  ## 
  let valid = call_594034.validator(path, query, header, formData, body)
  let scheme = call_594034.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594034.url(scheme.get, call_594034.host, call_594034.base,
                         call_594034.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594034, url, valid)

proc call*(call_594035: Call_PostDescribeInstancesHealth_594018;
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
  var query_594036 = newJObject()
  var formData_594037 = newJObject()
  add(formData_594037, "NextToken", newJString(NextToken))
  add(formData_594037, "EnvironmentName", newJString(EnvironmentName))
  if AttributeNames != nil:
    formData_594037.add "AttributeNames", AttributeNames
  add(query_594036, "Action", newJString(Action))
  add(formData_594037, "EnvironmentId", newJString(EnvironmentId))
  add(query_594036, "Version", newJString(Version))
  result = call_594035.call(nil, query_594036, nil, formData_594037, nil)

var postDescribeInstancesHealth* = Call_PostDescribeInstancesHealth_594018(
    name: "postDescribeInstancesHealth", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeInstancesHealth",
    validator: validate_PostDescribeInstancesHealth_594019, base: "/",
    url: url_PostDescribeInstancesHealth_594020,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeInstancesHealth_593999 = ref object of OpenApiRestCall_592365
proc url_GetDescribeInstancesHealth_594001(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeInstancesHealth_594000(path: JsonNode; query: JsonNode;
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
  var valid_594002 = query.getOrDefault("AttributeNames")
  valid_594002 = validateParameter(valid_594002, JArray, required = false,
                                 default = nil)
  if valid_594002 != nil:
    section.add "AttributeNames", valid_594002
  var valid_594003 = query.getOrDefault("NextToken")
  valid_594003 = validateParameter(valid_594003, JString, required = false,
                                 default = nil)
  if valid_594003 != nil:
    section.add "NextToken", valid_594003
  var valid_594004 = query.getOrDefault("EnvironmentName")
  valid_594004 = validateParameter(valid_594004, JString, required = false,
                                 default = nil)
  if valid_594004 != nil:
    section.add "EnvironmentName", valid_594004
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594005 = query.getOrDefault("Action")
  valid_594005 = validateParameter(valid_594005, JString, required = true, default = newJString(
      "DescribeInstancesHealth"))
  if valid_594005 != nil:
    section.add "Action", valid_594005
  var valid_594006 = query.getOrDefault("Version")
  valid_594006 = validateParameter(valid_594006, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594006 != nil:
    section.add "Version", valid_594006
  var valid_594007 = query.getOrDefault("EnvironmentId")
  valid_594007 = validateParameter(valid_594007, JString, required = false,
                                 default = nil)
  if valid_594007 != nil:
    section.add "EnvironmentId", valid_594007
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
  var valid_594008 = header.getOrDefault("X-Amz-Signature")
  valid_594008 = validateParameter(valid_594008, JString, required = false,
                                 default = nil)
  if valid_594008 != nil:
    section.add "X-Amz-Signature", valid_594008
  var valid_594009 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594009 = validateParameter(valid_594009, JString, required = false,
                                 default = nil)
  if valid_594009 != nil:
    section.add "X-Amz-Content-Sha256", valid_594009
  var valid_594010 = header.getOrDefault("X-Amz-Date")
  valid_594010 = validateParameter(valid_594010, JString, required = false,
                                 default = nil)
  if valid_594010 != nil:
    section.add "X-Amz-Date", valid_594010
  var valid_594011 = header.getOrDefault("X-Amz-Credential")
  valid_594011 = validateParameter(valid_594011, JString, required = false,
                                 default = nil)
  if valid_594011 != nil:
    section.add "X-Amz-Credential", valid_594011
  var valid_594012 = header.getOrDefault("X-Amz-Security-Token")
  valid_594012 = validateParameter(valid_594012, JString, required = false,
                                 default = nil)
  if valid_594012 != nil:
    section.add "X-Amz-Security-Token", valid_594012
  var valid_594013 = header.getOrDefault("X-Amz-Algorithm")
  valid_594013 = validateParameter(valid_594013, JString, required = false,
                                 default = nil)
  if valid_594013 != nil:
    section.add "X-Amz-Algorithm", valid_594013
  var valid_594014 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594014 = validateParameter(valid_594014, JString, required = false,
                                 default = nil)
  if valid_594014 != nil:
    section.add "X-Amz-SignedHeaders", valid_594014
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594015: Call_GetDescribeInstancesHealth_593999; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves detailed information about the health of instances in your AWS Elastic Beanstalk. This operation requires <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/health-enhanced.html">enhanced health reporting</a>.
  ## 
  let valid = call_594015.validator(path, query, header, formData, body)
  let scheme = call_594015.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594015.url(scheme.get, call_594015.host, call_594015.base,
                         call_594015.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594015, url, valid)

proc call*(call_594016: Call_GetDescribeInstancesHealth_593999;
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
  var query_594017 = newJObject()
  if AttributeNames != nil:
    query_594017.add "AttributeNames", AttributeNames
  add(query_594017, "NextToken", newJString(NextToken))
  add(query_594017, "EnvironmentName", newJString(EnvironmentName))
  add(query_594017, "Action", newJString(Action))
  add(query_594017, "Version", newJString(Version))
  add(query_594017, "EnvironmentId", newJString(EnvironmentId))
  result = call_594016.call(nil, query_594017, nil, nil, nil)

var getDescribeInstancesHealth* = Call_GetDescribeInstancesHealth_593999(
    name: "getDescribeInstancesHealth", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeInstancesHealth",
    validator: validate_GetDescribeInstancesHealth_594000, base: "/",
    url: url_GetDescribeInstancesHealth_594001,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribePlatformVersion_594054 = ref object of OpenApiRestCall_592365
proc url_PostDescribePlatformVersion_594056(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribePlatformVersion_594055(path: JsonNode; query: JsonNode;
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
  var valid_594057 = query.getOrDefault("Action")
  valid_594057 = validateParameter(valid_594057, JString, required = true, default = newJString(
      "DescribePlatformVersion"))
  if valid_594057 != nil:
    section.add "Action", valid_594057
  var valid_594058 = query.getOrDefault("Version")
  valid_594058 = validateParameter(valid_594058, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594058 != nil:
    section.add "Version", valid_594058
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
  var valid_594059 = header.getOrDefault("X-Amz-Signature")
  valid_594059 = validateParameter(valid_594059, JString, required = false,
                                 default = nil)
  if valid_594059 != nil:
    section.add "X-Amz-Signature", valid_594059
  var valid_594060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594060 = validateParameter(valid_594060, JString, required = false,
                                 default = nil)
  if valid_594060 != nil:
    section.add "X-Amz-Content-Sha256", valid_594060
  var valid_594061 = header.getOrDefault("X-Amz-Date")
  valid_594061 = validateParameter(valid_594061, JString, required = false,
                                 default = nil)
  if valid_594061 != nil:
    section.add "X-Amz-Date", valid_594061
  var valid_594062 = header.getOrDefault("X-Amz-Credential")
  valid_594062 = validateParameter(valid_594062, JString, required = false,
                                 default = nil)
  if valid_594062 != nil:
    section.add "X-Amz-Credential", valid_594062
  var valid_594063 = header.getOrDefault("X-Amz-Security-Token")
  valid_594063 = validateParameter(valid_594063, JString, required = false,
                                 default = nil)
  if valid_594063 != nil:
    section.add "X-Amz-Security-Token", valid_594063
  var valid_594064 = header.getOrDefault("X-Amz-Algorithm")
  valid_594064 = validateParameter(valid_594064, JString, required = false,
                                 default = nil)
  if valid_594064 != nil:
    section.add "X-Amz-Algorithm", valid_594064
  var valid_594065 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594065 = validateParameter(valid_594065, JString, required = false,
                                 default = nil)
  if valid_594065 != nil:
    section.add "X-Amz-SignedHeaders", valid_594065
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformArn: JString
  ##              : The ARN of the version of the platform.
  section = newJObject()
  var valid_594066 = formData.getOrDefault("PlatformArn")
  valid_594066 = validateParameter(valid_594066, JString, required = false,
                                 default = nil)
  if valid_594066 != nil:
    section.add "PlatformArn", valid_594066
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594067: Call_PostDescribePlatformVersion_594054; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the version of the platform.
  ## 
  let valid = call_594067.validator(path, query, header, formData, body)
  let scheme = call_594067.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594067.url(scheme.get, call_594067.host, call_594067.base,
                         call_594067.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594067, url, valid)

proc call*(call_594068: Call_PostDescribePlatformVersion_594054;
          Action: string = "DescribePlatformVersion";
          Version: string = "2010-12-01"; PlatformArn: string = ""): Recallable =
  ## postDescribePlatformVersion
  ## Describes the version of the platform.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PlatformArn: string
  ##              : The ARN of the version of the platform.
  var query_594069 = newJObject()
  var formData_594070 = newJObject()
  add(query_594069, "Action", newJString(Action))
  add(query_594069, "Version", newJString(Version))
  add(formData_594070, "PlatformArn", newJString(PlatformArn))
  result = call_594068.call(nil, query_594069, nil, formData_594070, nil)

var postDescribePlatformVersion* = Call_PostDescribePlatformVersion_594054(
    name: "postDescribePlatformVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribePlatformVersion",
    validator: validate_PostDescribePlatformVersion_594055, base: "/",
    url: url_PostDescribePlatformVersion_594056,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribePlatformVersion_594038 = ref object of OpenApiRestCall_592365
proc url_GetDescribePlatformVersion_594040(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribePlatformVersion_594039(path: JsonNode; query: JsonNode;
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
  var valid_594041 = query.getOrDefault("Action")
  valid_594041 = validateParameter(valid_594041, JString, required = true, default = newJString(
      "DescribePlatformVersion"))
  if valid_594041 != nil:
    section.add "Action", valid_594041
  var valid_594042 = query.getOrDefault("PlatformArn")
  valid_594042 = validateParameter(valid_594042, JString, required = false,
                                 default = nil)
  if valid_594042 != nil:
    section.add "PlatformArn", valid_594042
  var valid_594043 = query.getOrDefault("Version")
  valid_594043 = validateParameter(valid_594043, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594043 != nil:
    section.add "Version", valid_594043
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
  var valid_594044 = header.getOrDefault("X-Amz-Signature")
  valid_594044 = validateParameter(valid_594044, JString, required = false,
                                 default = nil)
  if valid_594044 != nil:
    section.add "X-Amz-Signature", valid_594044
  var valid_594045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594045 = validateParameter(valid_594045, JString, required = false,
                                 default = nil)
  if valid_594045 != nil:
    section.add "X-Amz-Content-Sha256", valid_594045
  var valid_594046 = header.getOrDefault("X-Amz-Date")
  valid_594046 = validateParameter(valid_594046, JString, required = false,
                                 default = nil)
  if valid_594046 != nil:
    section.add "X-Amz-Date", valid_594046
  var valid_594047 = header.getOrDefault("X-Amz-Credential")
  valid_594047 = validateParameter(valid_594047, JString, required = false,
                                 default = nil)
  if valid_594047 != nil:
    section.add "X-Amz-Credential", valid_594047
  var valid_594048 = header.getOrDefault("X-Amz-Security-Token")
  valid_594048 = validateParameter(valid_594048, JString, required = false,
                                 default = nil)
  if valid_594048 != nil:
    section.add "X-Amz-Security-Token", valid_594048
  var valid_594049 = header.getOrDefault("X-Amz-Algorithm")
  valid_594049 = validateParameter(valid_594049, JString, required = false,
                                 default = nil)
  if valid_594049 != nil:
    section.add "X-Amz-Algorithm", valid_594049
  var valid_594050 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594050 = validateParameter(valid_594050, JString, required = false,
                                 default = nil)
  if valid_594050 != nil:
    section.add "X-Amz-SignedHeaders", valid_594050
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594051: Call_GetDescribePlatformVersion_594038; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the version of the platform.
  ## 
  let valid = call_594051.validator(path, query, header, formData, body)
  let scheme = call_594051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594051.url(scheme.get, call_594051.host, call_594051.base,
                         call_594051.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594051, url, valid)

proc call*(call_594052: Call_GetDescribePlatformVersion_594038;
          Action: string = "DescribePlatformVersion"; PlatformArn: string = "";
          Version: string = "2010-12-01"): Recallable =
  ## getDescribePlatformVersion
  ## Describes the version of the platform.
  ##   Action: string (required)
  ##   PlatformArn: string
  ##              : The ARN of the version of the platform.
  ##   Version: string (required)
  var query_594053 = newJObject()
  add(query_594053, "Action", newJString(Action))
  add(query_594053, "PlatformArn", newJString(PlatformArn))
  add(query_594053, "Version", newJString(Version))
  result = call_594052.call(nil, query_594053, nil, nil, nil)

var getDescribePlatformVersion* = Call_GetDescribePlatformVersion_594038(
    name: "getDescribePlatformVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribePlatformVersion",
    validator: validate_GetDescribePlatformVersion_594039, base: "/",
    url: url_GetDescribePlatformVersion_594040,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListAvailableSolutionStacks_594086 = ref object of OpenApiRestCall_592365
proc url_PostListAvailableSolutionStacks_594088(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListAvailableSolutionStacks_594087(path: JsonNode;
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
  var valid_594089 = query.getOrDefault("Action")
  valid_594089 = validateParameter(valid_594089, JString, required = true, default = newJString(
      "ListAvailableSolutionStacks"))
  if valid_594089 != nil:
    section.add "Action", valid_594089
  var valid_594090 = query.getOrDefault("Version")
  valid_594090 = validateParameter(valid_594090, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594090 != nil:
    section.add "Version", valid_594090
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
  var valid_594091 = header.getOrDefault("X-Amz-Signature")
  valid_594091 = validateParameter(valid_594091, JString, required = false,
                                 default = nil)
  if valid_594091 != nil:
    section.add "X-Amz-Signature", valid_594091
  var valid_594092 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594092 = validateParameter(valid_594092, JString, required = false,
                                 default = nil)
  if valid_594092 != nil:
    section.add "X-Amz-Content-Sha256", valid_594092
  var valid_594093 = header.getOrDefault("X-Amz-Date")
  valid_594093 = validateParameter(valid_594093, JString, required = false,
                                 default = nil)
  if valid_594093 != nil:
    section.add "X-Amz-Date", valid_594093
  var valid_594094 = header.getOrDefault("X-Amz-Credential")
  valid_594094 = validateParameter(valid_594094, JString, required = false,
                                 default = nil)
  if valid_594094 != nil:
    section.add "X-Amz-Credential", valid_594094
  var valid_594095 = header.getOrDefault("X-Amz-Security-Token")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = nil)
  if valid_594095 != nil:
    section.add "X-Amz-Security-Token", valid_594095
  var valid_594096 = header.getOrDefault("X-Amz-Algorithm")
  valid_594096 = validateParameter(valid_594096, JString, required = false,
                                 default = nil)
  if valid_594096 != nil:
    section.add "X-Amz-Algorithm", valid_594096
  var valid_594097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594097 = validateParameter(valid_594097, JString, required = false,
                                 default = nil)
  if valid_594097 != nil:
    section.add "X-Amz-SignedHeaders", valid_594097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594098: Call_PostListAvailableSolutionStacks_594086;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ## 
  let valid = call_594098.validator(path, query, header, formData, body)
  let scheme = call_594098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594098.url(scheme.get, call_594098.host, call_594098.base,
                         call_594098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594098, url, valid)

proc call*(call_594099: Call_PostListAvailableSolutionStacks_594086;
          Action: string = "ListAvailableSolutionStacks";
          Version: string = "2010-12-01"): Recallable =
  ## postListAvailableSolutionStacks
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594100 = newJObject()
  add(query_594100, "Action", newJString(Action))
  add(query_594100, "Version", newJString(Version))
  result = call_594099.call(nil, query_594100, nil, nil, nil)

var postListAvailableSolutionStacks* = Call_PostListAvailableSolutionStacks_594086(
    name: "postListAvailableSolutionStacks", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListAvailableSolutionStacks",
    validator: validate_PostListAvailableSolutionStacks_594087, base: "/",
    url: url_PostListAvailableSolutionStacks_594088,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListAvailableSolutionStacks_594071 = ref object of OpenApiRestCall_592365
proc url_GetListAvailableSolutionStacks_594073(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListAvailableSolutionStacks_594072(path: JsonNode;
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
  var valid_594074 = query.getOrDefault("Action")
  valid_594074 = validateParameter(valid_594074, JString, required = true, default = newJString(
      "ListAvailableSolutionStacks"))
  if valid_594074 != nil:
    section.add "Action", valid_594074
  var valid_594075 = query.getOrDefault("Version")
  valid_594075 = validateParameter(valid_594075, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594075 != nil:
    section.add "Version", valid_594075
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
  var valid_594076 = header.getOrDefault("X-Amz-Signature")
  valid_594076 = validateParameter(valid_594076, JString, required = false,
                                 default = nil)
  if valid_594076 != nil:
    section.add "X-Amz-Signature", valid_594076
  var valid_594077 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594077 = validateParameter(valid_594077, JString, required = false,
                                 default = nil)
  if valid_594077 != nil:
    section.add "X-Amz-Content-Sha256", valid_594077
  var valid_594078 = header.getOrDefault("X-Amz-Date")
  valid_594078 = validateParameter(valid_594078, JString, required = false,
                                 default = nil)
  if valid_594078 != nil:
    section.add "X-Amz-Date", valid_594078
  var valid_594079 = header.getOrDefault("X-Amz-Credential")
  valid_594079 = validateParameter(valid_594079, JString, required = false,
                                 default = nil)
  if valid_594079 != nil:
    section.add "X-Amz-Credential", valid_594079
  var valid_594080 = header.getOrDefault("X-Amz-Security-Token")
  valid_594080 = validateParameter(valid_594080, JString, required = false,
                                 default = nil)
  if valid_594080 != nil:
    section.add "X-Amz-Security-Token", valid_594080
  var valid_594081 = header.getOrDefault("X-Amz-Algorithm")
  valid_594081 = validateParameter(valid_594081, JString, required = false,
                                 default = nil)
  if valid_594081 != nil:
    section.add "X-Amz-Algorithm", valid_594081
  var valid_594082 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594082 = validateParameter(valid_594082, JString, required = false,
                                 default = nil)
  if valid_594082 != nil:
    section.add "X-Amz-SignedHeaders", valid_594082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594083: Call_GetListAvailableSolutionStacks_594071; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ## 
  let valid = call_594083.validator(path, query, header, formData, body)
  let scheme = call_594083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594083.url(scheme.get, call_594083.host, call_594083.base,
                         call_594083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594083, url, valid)

proc call*(call_594084: Call_GetListAvailableSolutionStacks_594071;
          Action: string = "ListAvailableSolutionStacks";
          Version: string = "2010-12-01"): Recallable =
  ## getListAvailableSolutionStacks
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594085 = newJObject()
  add(query_594085, "Action", newJString(Action))
  add(query_594085, "Version", newJString(Version))
  result = call_594084.call(nil, query_594085, nil, nil, nil)

var getListAvailableSolutionStacks* = Call_GetListAvailableSolutionStacks_594071(
    name: "getListAvailableSolutionStacks", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListAvailableSolutionStacks",
    validator: validate_GetListAvailableSolutionStacks_594072, base: "/",
    url: url_GetListAvailableSolutionStacks_594073,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListPlatformVersions_594119 = ref object of OpenApiRestCall_592365
proc url_PostListPlatformVersions_594121(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListPlatformVersions_594120(path: JsonNode; query: JsonNode;
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
  var valid_594122 = query.getOrDefault("Action")
  valid_594122 = validateParameter(valid_594122, JString, required = true,
                                 default = newJString("ListPlatformVersions"))
  if valid_594122 != nil:
    section.add "Action", valid_594122
  var valid_594123 = query.getOrDefault("Version")
  valid_594123 = validateParameter(valid_594123, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594123 != nil:
    section.add "Version", valid_594123
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
  var valid_594124 = header.getOrDefault("X-Amz-Signature")
  valid_594124 = validateParameter(valid_594124, JString, required = false,
                                 default = nil)
  if valid_594124 != nil:
    section.add "X-Amz-Signature", valid_594124
  var valid_594125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594125 = validateParameter(valid_594125, JString, required = false,
                                 default = nil)
  if valid_594125 != nil:
    section.add "X-Amz-Content-Sha256", valid_594125
  var valid_594126 = header.getOrDefault("X-Amz-Date")
  valid_594126 = validateParameter(valid_594126, JString, required = false,
                                 default = nil)
  if valid_594126 != nil:
    section.add "X-Amz-Date", valid_594126
  var valid_594127 = header.getOrDefault("X-Amz-Credential")
  valid_594127 = validateParameter(valid_594127, JString, required = false,
                                 default = nil)
  if valid_594127 != nil:
    section.add "X-Amz-Credential", valid_594127
  var valid_594128 = header.getOrDefault("X-Amz-Security-Token")
  valid_594128 = validateParameter(valid_594128, JString, required = false,
                                 default = nil)
  if valid_594128 != nil:
    section.add "X-Amz-Security-Token", valid_594128
  var valid_594129 = header.getOrDefault("X-Amz-Algorithm")
  valid_594129 = validateParameter(valid_594129, JString, required = false,
                                 default = nil)
  if valid_594129 != nil:
    section.add "X-Amz-Algorithm", valid_594129
  var valid_594130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594130 = validateParameter(valid_594130, JString, required = false,
                                 default = nil)
  if valid_594130 != nil:
    section.add "X-Amz-SignedHeaders", valid_594130
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : The starting index into the remaining list of platforms. Use the <code>NextToken</code> value from a previous <code>ListPlatformVersion</code> call.
  ##   MaxRecords: JInt
  ##             : The maximum number of platform values returned in one call.
  ##   Filters: JArray
  ##          : List only the platforms where the platform member value relates to one of the supplied values.
  section = newJObject()
  var valid_594131 = formData.getOrDefault("NextToken")
  valid_594131 = validateParameter(valid_594131, JString, required = false,
                                 default = nil)
  if valid_594131 != nil:
    section.add "NextToken", valid_594131
  var valid_594132 = formData.getOrDefault("MaxRecords")
  valid_594132 = validateParameter(valid_594132, JInt, required = false, default = nil)
  if valid_594132 != nil:
    section.add "MaxRecords", valid_594132
  var valid_594133 = formData.getOrDefault("Filters")
  valid_594133 = validateParameter(valid_594133, JArray, required = false,
                                 default = nil)
  if valid_594133 != nil:
    section.add "Filters", valid_594133
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594134: Call_PostListPlatformVersions_594119; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the available platforms.
  ## 
  let valid = call_594134.validator(path, query, header, formData, body)
  let scheme = call_594134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594134.url(scheme.get, call_594134.host, call_594134.base,
                         call_594134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594134, url, valid)

proc call*(call_594135: Call_PostListPlatformVersions_594119;
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
  var query_594136 = newJObject()
  var formData_594137 = newJObject()
  add(formData_594137, "NextToken", newJString(NextToken))
  add(formData_594137, "MaxRecords", newJInt(MaxRecords))
  add(query_594136, "Action", newJString(Action))
  if Filters != nil:
    formData_594137.add "Filters", Filters
  add(query_594136, "Version", newJString(Version))
  result = call_594135.call(nil, query_594136, nil, formData_594137, nil)

var postListPlatformVersions* = Call_PostListPlatformVersions_594119(
    name: "postListPlatformVersions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListPlatformVersions",
    validator: validate_PostListPlatformVersions_594120, base: "/",
    url: url_PostListPlatformVersions_594121, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListPlatformVersions_594101 = ref object of OpenApiRestCall_592365
proc url_GetListPlatformVersions_594103(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListPlatformVersions_594102(path: JsonNode; query: JsonNode;
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
  var valid_594104 = query.getOrDefault("NextToken")
  valid_594104 = validateParameter(valid_594104, JString, required = false,
                                 default = nil)
  if valid_594104 != nil:
    section.add "NextToken", valid_594104
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594105 = query.getOrDefault("Action")
  valid_594105 = validateParameter(valid_594105, JString, required = true,
                                 default = newJString("ListPlatformVersions"))
  if valid_594105 != nil:
    section.add "Action", valid_594105
  var valid_594106 = query.getOrDefault("Version")
  valid_594106 = validateParameter(valid_594106, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594106 != nil:
    section.add "Version", valid_594106
  var valid_594107 = query.getOrDefault("Filters")
  valid_594107 = validateParameter(valid_594107, JArray, required = false,
                                 default = nil)
  if valid_594107 != nil:
    section.add "Filters", valid_594107
  var valid_594108 = query.getOrDefault("MaxRecords")
  valid_594108 = validateParameter(valid_594108, JInt, required = false, default = nil)
  if valid_594108 != nil:
    section.add "MaxRecords", valid_594108
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
  var valid_594109 = header.getOrDefault("X-Amz-Signature")
  valid_594109 = validateParameter(valid_594109, JString, required = false,
                                 default = nil)
  if valid_594109 != nil:
    section.add "X-Amz-Signature", valid_594109
  var valid_594110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594110 = validateParameter(valid_594110, JString, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "X-Amz-Content-Sha256", valid_594110
  var valid_594111 = header.getOrDefault("X-Amz-Date")
  valid_594111 = validateParameter(valid_594111, JString, required = false,
                                 default = nil)
  if valid_594111 != nil:
    section.add "X-Amz-Date", valid_594111
  var valid_594112 = header.getOrDefault("X-Amz-Credential")
  valid_594112 = validateParameter(valid_594112, JString, required = false,
                                 default = nil)
  if valid_594112 != nil:
    section.add "X-Amz-Credential", valid_594112
  var valid_594113 = header.getOrDefault("X-Amz-Security-Token")
  valid_594113 = validateParameter(valid_594113, JString, required = false,
                                 default = nil)
  if valid_594113 != nil:
    section.add "X-Amz-Security-Token", valid_594113
  var valid_594114 = header.getOrDefault("X-Amz-Algorithm")
  valid_594114 = validateParameter(valid_594114, JString, required = false,
                                 default = nil)
  if valid_594114 != nil:
    section.add "X-Amz-Algorithm", valid_594114
  var valid_594115 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594115 = validateParameter(valid_594115, JString, required = false,
                                 default = nil)
  if valid_594115 != nil:
    section.add "X-Amz-SignedHeaders", valid_594115
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594116: Call_GetListPlatformVersions_594101; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the available platforms.
  ## 
  let valid = call_594116.validator(path, query, header, formData, body)
  let scheme = call_594116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594116.url(scheme.get, call_594116.host, call_594116.base,
                         call_594116.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594116, url, valid)

proc call*(call_594117: Call_GetListPlatformVersions_594101;
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
  var query_594118 = newJObject()
  add(query_594118, "NextToken", newJString(NextToken))
  add(query_594118, "Action", newJString(Action))
  add(query_594118, "Version", newJString(Version))
  if Filters != nil:
    query_594118.add "Filters", Filters
  add(query_594118, "MaxRecords", newJInt(MaxRecords))
  result = call_594117.call(nil, query_594118, nil, nil, nil)

var getListPlatformVersions* = Call_GetListPlatformVersions_594101(
    name: "getListPlatformVersions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListPlatformVersions",
    validator: validate_GetListPlatformVersions_594102, base: "/",
    url: url_GetListPlatformVersions_594103, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_594154 = ref object of OpenApiRestCall_592365
proc url_PostListTagsForResource_594156(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListTagsForResource_594155(path: JsonNode; query: JsonNode;
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
  var valid_594157 = query.getOrDefault("Action")
  valid_594157 = validateParameter(valid_594157, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_594157 != nil:
    section.add "Action", valid_594157
  var valid_594158 = query.getOrDefault("Version")
  valid_594158 = validateParameter(valid_594158, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594158 != nil:
    section.add "Version", valid_594158
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
  var valid_594159 = header.getOrDefault("X-Amz-Signature")
  valid_594159 = validateParameter(valid_594159, JString, required = false,
                                 default = nil)
  if valid_594159 != nil:
    section.add "X-Amz-Signature", valid_594159
  var valid_594160 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594160 = validateParameter(valid_594160, JString, required = false,
                                 default = nil)
  if valid_594160 != nil:
    section.add "X-Amz-Content-Sha256", valid_594160
  var valid_594161 = header.getOrDefault("X-Amz-Date")
  valid_594161 = validateParameter(valid_594161, JString, required = false,
                                 default = nil)
  if valid_594161 != nil:
    section.add "X-Amz-Date", valid_594161
  var valid_594162 = header.getOrDefault("X-Amz-Credential")
  valid_594162 = validateParameter(valid_594162, JString, required = false,
                                 default = nil)
  if valid_594162 != nil:
    section.add "X-Amz-Credential", valid_594162
  var valid_594163 = header.getOrDefault("X-Amz-Security-Token")
  valid_594163 = validateParameter(valid_594163, JString, required = false,
                                 default = nil)
  if valid_594163 != nil:
    section.add "X-Amz-Security-Token", valid_594163
  var valid_594164 = header.getOrDefault("X-Amz-Algorithm")
  valid_594164 = validateParameter(valid_594164, JString, required = false,
                                 default = nil)
  if valid_594164 != nil:
    section.add "X-Amz-Algorithm", valid_594164
  var valid_594165 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594165 = validateParameter(valid_594165, JString, required = false,
                                 default = nil)
  if valid_594165 != nil:
    section.add "X-Amz-SignedHeaders", valid_594165
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArn: JString (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce for which a tag list is requested.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArn` field"
  var valid_594166 = formData.getOrDefault("ResourceArn")
  valid_594166 = validateParameter(valid_594166, JString, required = true,
                                 default = nil)
  if valid_594166 != nil:
    section.add "ResourceArn", valid_594166
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594167: Call_PostListTagsForResource_594154; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ## 
  let valid = call_594167.validator(path, query, header, formData, body)
  let scheme = call_594167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594167.url(scheme.get, call_594167.host, call_594167.base,
                         call_594167.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594167, url, valid)

proc call*(call_594168: Call_PostListTagsForResource_594154; ResourceArn: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-12-01"): Recallable =
  ## postListTagsForResource
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ##   ResourceArn: string (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce for which a tag list is requested.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594169 = newJObject()
  var formData_594170 = newJObject()
  add(formData_594170, "ResourceArn", newJString(ResourceArn))
  add(query_594169, "Action", newJString(Action))
  add(query_594169, "Version", newJString(Version))
  result = call_594168.call(nil, query_594169, nil, formData_594170, nil)

var postListTagsForResource* = Call_PostListTagsForResource_594154(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_594155, base: "/",
    url: url_PostListTagsForResource_594156, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_594138 = ref object of OpenApiRestCall_592365
proc url_GetListTagsForResource_594140(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListTagsForResource_594139(path: JsonNode; query: JsonNode;
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
  var valid_594141 = query.getOrDefault("ResourceArn")
  valid_594141 = validateParameter(valid_594141, JString, required = true,
                                 default = nil)
  if valid_594141 != nil:
    section.add "ResourceArn", valid_594141
  var valid_594142 = query.getOrDefault("Action")
  valid_594142 = validateParameter(valid_594142, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_594142 != nil:
    section.add "Action", valid_594142
  var valid_594143 = query.getOrDefault("Version")
  valid_594143 = validateParameter(valid_594143, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594143 != nil:
    section.add "Version", valid_594143
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
  var valid_594144 = header.getOrDefault("X-Amz-Signature")
  valid_594144 = validateParameter(valid_594144, JString, required = false,
                                 default = nil)
  if valid_594144 != nil:
    section.add "X-Amz-Signature", valid_594144
  var valid_594145 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594145 = validateParameter(valid_594145, JString, required = false,
                                 default = nil)
  if valid_594145 != nil:
    section.add "X-Amz-Content-Sha256", valid_594145
  var valid_594146 = header.getOrDefault("X-Amz-Date")
  valid_594146 = validateParameter(valid_594146, JString, required = false,
                                 default = nil)
  if valid_594146 != nil:
    section.add "X-Amz-Date", valid_594146
  var valid_594147 = header.getOrDefault("X-Amz-Credential")
  valid_594147 = validateParameter(valid_594147, JString, required = false,
                                 default = nil)
  if valid_594147 != nil:
    section.add "X-Amz-Credential", valid_594147
  var valid_594148 = header.getOrDefault("X-Amz-Security-Token")
  valid_594148 = validateParameter(valid_594148, JString, required = false,
                                 default = nil)
  if valid_594148 != nil:
    section.add "X-Amz-Security-Token", valid_594148
  var valid_594149 = header.getOrDefault("X-Amz-Algorithm")
  valid_594149 = validateParameter(valid_594149, JString, required = false,
                                 default = nil)
  if valid_594149 != nil:
    section.add "X-Amz-Algorithm", valid_594149
  var valid_594150 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594150 = validateParameter(valid_594150, JString, required = false,
                                 default = nil)
  if valid_594150 != nil:
    section.add "X-Amz-SignedHeaders", valid_594150
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594151: Call_GetListTagsForResource_594138; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ## 
  let valid = call_594151.validator(path, query, header, formData, body)
  let scheme = call_594151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594151.url(scheme.get, call_594151.host, call_594151.base,
                         call_594151.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594151, url, valid)

proc call*(call_594152: Call_GetListTagsForResource_594138; ResourceArn: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-12-01"): Recallable =
  ## getListTagsForResource
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ##   ResourceArn: string (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce for which a tag list is requested.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_594153 = newJObject()
  add(query_594153, "ResourceArn", newJString(ResourceArn))
  add(query_594153, "Action", newJString(Action))
  add(query_594153, "Version", newJString(Version))
  result = call_594152.call(nil, query_594153, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_594138(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_594139, base: "/",
    url: url_GetListTagsForResource_594140, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebuildEnvironment_594188 = ref object of OpenApiRestCall_592365
proc url_PostRebuildEnvironment_594190(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRebuildEnvironment_594189(path: JsonNode; query: JsonNode;
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
  var valid_594191 = query.getOrDefault("Action")
  valid_594191 = validateParameter(valid_594191, JString, required = true,
                                 default = newJString("RebuildEnvironment"))
  if valid_594191 != nil:
    section.add "Action", valid_594191
  var valid_594192 = query.getOrDefault("Version")
  valid_594192 = validateParameter(valid_594192, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594192 != nil:
    section.add "Version", valid_594192
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
  var valid_594193 = header.getOrDefault("X-Amz-Signature")
  valid_594193 = validateParameter(valid_594193, JString, required = false,
                                 default = nil)
  if valid_594193 != nil:
    section.add "X-Amz-Signature", valid_594193
  var valid_594194 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594194 = validateParameter(valid_594194, JString, required = false,
                                 default = nil)
  if valid_594194 != nil:
    section.add "X-Amz-Content-Sha256", valid_594194
  var valid_594195 = header.getOrDefault("X-Amz-Date")
  valid_594195 = validateParameter(valid_594195, JString, required = false,
                                 default = nil)
  if valid_594195 != nil:
    section.add "X-Amz-Date", valid_594195
  var valid_594196 = header.getOrDefault("X-Amz-Credential")
  valid_594196 = validateParameter(valid_594196, JString, required = false,
                                 default = nil)
  if valid_594196 != nil:
    section.add "X-Amz-Credential", valid_594196
  var valid_594197 = header.getOrDefault("X-Amz-Security-Token")
  valid_594197 = validateParameter(valid_594197, JString, required = false,
                                 default = nil)
  if valid_594197 != nil:
    section.add "X-Amz-Security-Token", valid_594197
  var valid_594198 = header.getOrDefault("X-Amz-Algorithm")
  valid_594198 = validateParameter(valid_594198, JString, required = false,
                                 default = nil)
  if valid_594198 != nil:
    section.add "X-Amz-Algorithm", valid_594198
  var valid_594199 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594199 = validateParameter(valid_594199, JString, required = false,
                                 default = nil)
  if valid_594199 != nil:
    section.add "X-Amz-SignedHeaders", valid_594199
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to rebuild.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to rebuild.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_594200 = formData.getOrDefault("EnvironmentName")
  valid_594200 = validateParameter(valid_594200, JString, required = false,
                                 default = nil)
  if valid_594200 != nil:
    section.add "EnvironmentName", valid_594200
  var valid_594201 = formData.getOrDefault("EnvironmentId")
  valid_594201 = validateParameter(valid_594201, JString, required = false,
                                 default = nil)
  if valid_594201 != nil:
    section.add "EnvironmentId", valid_594201
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594202: Call_PostRebuildEnvironment_594188; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes and recreates all of the AWS resources (for example: the Auto Scaling group, load balancer, etc.) for a specified environment and forces a restart.
  ## 
  let valid = call_594202.validator(path, query, header, formData, body)
  let scheme = call_594202.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594202.url(scheme.get, call_594202.host, call_594202.base,
                         call_594202.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594202, url, valid)

proc call*(call_594203: Call_PostRebuildEnvironment_594188;
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
  var query_594204 = newJObject()
  var formData_594205 = newJObject()
  add(formData_594205, "EnvironmentName", newJString(EnvironmentName))
  add(query_594204, "Action", newJString(Action))
  add(formData_594205, "EnvironmentId", newJString(EnvironmentId))
  add(query_594204, "Version", newJString(Version))
  result = call_594203.call(nil, query_594204, nil, formData_594205, nil)

var postRebuildEnvironment* = Call_PostRebuildEnvironment_594188(
    name: "postRebuildEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RebuildEnvironment",
    validator: validate_PostRebuildEnvironment_594189, base: "/",
    url: url_PostRebuildEnvironment_594190, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebuildEnvironment_594171 = ref object of OpenApiRestCall_592365
proc url_GetRebuildEnvironment_594173(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRebuildEnvironment_594172(path: JsonNode; query: JsonNode;
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
  var valid_594174 = query.getOrDefault("EnvironmentName")
  valid_594174 = validateParameter(valid_594174, JString, required = false,
                                 default = nil)
  if valid_594174 != nil:
    section.add "EnvironmentName", valid_594174
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594175 = query.getOrDefault("Action")
  valid_594175 = validateParameter(valid_594175, JString, required = true,
                                 default = newJString("RebuildEnvironment"))
  if valid_594175 != nil:
    section.add "Action", valid_594175
  var valid_594176 = query.getOrDefault("Version")
  valid_594176 = validateParameter(valid_594176, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594176 != nil:
    section.add "Version", valid_594176
  var valid_594177 = query.getOrDefault("EnvironmentId")
  valid_594177 = validateParameter(valid_594177, JString, required = false,
                                 default = nil)
  if valid_594177 != nil:
    section.add "EnvironmentId", valid_594177
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
  var valid_594178 = header.getOrDefault("X-Amz-Signature")
  valid_594178 = validateParameter(valid_594178, JString, required = false,
                                 default = nil)
  if valid_594178 != nil:
    section.add "X-Amz-Signature", valid_594178
  var valid_594179 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594179 = validateParameter(valid_594179, JString, required = false,
                                 default = nil)
  if valid_594179 != nil:
    section.add "X-Amz-Content-Sha256", valid_594179
  var valid_594180 = header.getOrDefault("X-Amz-Date")
  valid_594180 = validateParameter(valid_594180, JString, required = false,
                                 default = nil)
  if valid_594180 != nil:
    section.add "X-Amz-Date", valid_594180
  var valid_594181 = header.getOrDefault("X-Amz-Credential")
  valid_594181 = validateParameter(valid_594181, JString, required = false,
                                 default = nil)
  if valid_594181 != nil:
    section.add "X-Amz-Credential", valid_594181
  var valid_594182 = header.getOrDefault("X-Amz-Security-Token")
  valid_594182 = validateParameter(valid_594182, JString, required = false,
                                 default = nil)
  if valid_594182 != nil:
    section.add "X-Amz-Security-Token", valid_594182
  var valid_594183 = header.getOrDefault("X-Amz-Algorithm")
  valid_594183 = validateParameter(valid_594183, JString, required = false,
                                 default = nil)
  if valid_594183 != nil:
    section.add "X-Amz-Algorithm", valid_594183
  var valid_594184 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594184 = validateParameter(valid_594184, JString, required = false,
                                 default = nil)
  if valid_594184 != nil:
    section.add "X-Amz-SignedHeaders", valid_594184
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594185: Call_GetRebuildEnvironment_594171; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes and recreates all of the AWS resources (for example: the Auto Scaling group, load balancer, etc.) for a specified environment and forces a restart.
  ## 
  let valid = call_594185.validator(path, query, header, formData, body)
  let scheme = call_594185.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594185.url(scheme.get, call_594185.host, call_594185.base,
                         call_594185.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594185, url, valid)

proc call*(call_594186: Call_GetRebuildEnvironment_594171;
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
  var query_594187 = newJObject()
  add(query_594187, "EnvironmentName", newJString(EnvironmentName))
  add(query_594187, "Action", newJString(Action))
  add(query_594187, "Version", newJString(Version))
  add(query_594187, "EnvironmentId", newJString(EnvironmentId))
  result = call_594186.call(nil, query_594187, nil, nil, nil)

var getRebuildEnvironment* = Call_GetRebuildEnvironment_594171(
    name: "getRebuildEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RebuildEnvironment",
    validator: validate_GetRebuildEnvironment_594172, base: "/",
    url: url_GetRebuildEnvironment_594173, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRequestEnvironmentInfo_594224 = ref object of OpenApiRestCall_592365
proc url_PostRequestEnvironmentInfo_594226(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRequestEnvironmentInfo_594225(path: JsonNode; query: JsonNode;
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
  var valid_594227 = query.getOrDefault("Action")
  valid_594227 = validateParameter(valid_594227, JString, required = true,
                                 default = newJString("RequestEnvironmentInfo"))
  if valid_594227 != nil:
    section.add "Action", valid_594227
  var valid_594228 = query.getOrDefault("Version")
  valid_594228 = validateParameter(valid_594228, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594228 != nil:
    section.add "Version", valid_594228
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
  var valid_594229 = header.getOrDefault("X-Amz-Signature")
  valid_594229 = validateParameter(valid_594229, JString, required = false,
                                 default = nil)
  if valid_594229 != nil:
    section.add "X-Amz-Signature", valid_594229
  var valid_594230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594230 = validateParameter(valid_594230, JString, required = false,
                                 default = nil)
  if valid_594230 != nil:
    section.add "X-Amz-Content-Sha256", valid_594230
  var valid_594231 = header.getOrDefault("X-Amz-Date")
  valid_594231 = validateParameter(valid_594231, JString, required = false,
                                 default = nil)
  if valid_594231 != nil:
    section.add "X-Amz-Date", valid_594231
  var valid_594232 = header.getOrDefault("X-Amz-Credential")
  valid_594232 = validateParameter(valid_594232, JString, required = false,
                                 default = nil)
  if valid_594232 != nil:
    section.add "X-Amz-Credential", valid_594232
  var valid_594233 = header.getOrDefault("X-Amz-Security-Token")
  valid_594233 = validateParameter(valid_594233, JString, required = false,
                                 default = nil)
  if valid_594233 != nil:
    section.add "X-Amz-Security-Token", valid_594233
  var valid_594234 = header.getOrDefault("X-Amz-Algorithm")
  valid_594234 = validateParameter(valid_594234, JString, required = false,
                                 default = nil)
  if valid_594234 != nil:
    section.add "X-Amz-Algorithm", valid_594234
  var valid_594235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594235 = validateParameter(valid_594235, JString, required = false,
                                 default = nil)
  if valid_594235 != nil:
    section.add "X-Amz-SignedHeaders", valid_594235
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
  var valid_594236 = formData.getOrDefault("InfoType")
  valid_594236 = validateParameter(valid_594236, JString, required = true,
                                 default = newJString("tail"))
  if valid_594236 != nil:
    section.add "InfoType", valid_594236
  var valid_594237 = formData.getOrDefault("EnvironmentName")
  valid_594237 = validateParameter(valid_594237, JString, required = false,
                                 default = nil)
  if valid_594237 != nil:
    section.add "EnvironmentName", valid_594237
  var valid_594238 = formData.getOrDefault("EnvironmentId")
  valid_594238 = validateParameter(valid_594238, JString, required = false,
                                 default = nil)
  if valid_594238 != nil:
    section.add "EnvironmentId", valid_594238
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594239: Call_PostRequestEnvironmentInfo_594224; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a request to compile the specified type of information of the deployed environment.</p> <p> Setting the <code>InfoType</code> to <code>tail</code> compiles the last lines from the application server log files of every Amazon EC2 instance in your environment. </p> <p> Setting the <code>InfoType</code> to <code>bundle</code> compresses the application server log files for every Amazon EC2 instance into a <code>.zip</code> file. Legacy and .NET containers do not support bundle logs. </p> <p> Use <a>RetrieveEnvironmentInfo</a> to obtain the set of logs. </p> <p>Related Topics</p> <ul> <li> <p> <a>RetrieveEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_594239.validator(path, query, header, formData, body)
  let scheme = call_594239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594239.url(scheme.get, call_594239.host, call_594239.base,
                         call_594239.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594239, url, valid)

proc call*(call_594240: Call_PostRequestEnvironmentInfo_594224;
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
  var query_594241 = newJObject()
  var formData_594242 = newJObject()
  add(formData_594242, "InfoType", newJString(InfoType))
  add(formData_594242, "EnvironmentName", newJString(EnvironmentName))
  add(query_594241, "Action", newJString(Action))
  add(formData_594242, "EnvironmentId", newJString(EnvironmentId))
  add(query_594241, "Version", newJString(Version))
  result = call_594240.call(nil, query_594241, nil, formData_594242, nil)

var postRequestEnvironmentInfo* = Call_PostRequestEnvironmentInfo_594224(
    name: "postRequestEnvironmentInfo", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RequestEnvironmentInfo",
    validator: validate_PostRequestEnvironmentInfo_594225, base: "/",
    url: url_PostRequestEnvironmentInfo_594226,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRequestEnvironmentInfo_594206 = ref object of OpenApiRestCall_592365
proc url_GetRequestEnvironmentInfo_594208(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRequestEnvironmentInfo_594207(path: JsonNode; query: JsonNode;
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
  var valid_594209 = query.getOrDefault("InfoType")
  valid_594209 = validateParameter(valid_594209, JString, required = true,
                                 default = newJString("tail"))
  if valid_594209 != nil:
    section.add "InfoType", valid_594209
  var valid_594210 = query.getOrDefault("EnvironmentName")
  valid_594210 = validateParameter(valid_594210, JString, required = false,
                                 default = nil)
  if valid_594210 != nil:
    section.add "EnvironmentName", valid_594210
  var valid_594211 = query.getOrDefault("Action")
  valid_594211 = validateParameter(valid_594211, JString, required = true,
                                 default = newJString("RequestEnvironmentInfo"))
  if valid_594211 != nil:
    section.add "Action", valid_594211
  var valid_594212 = query.getOrDefault("Version")
  valid_594212 = validateParameter(valid_594212, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594212 != nil:
    section.add "Version", valid_594212
  var valid_594213 = query.getOrDefault("EnvironmentId")
  valid_594213 = validateParameter(valid_594213, JString, required = false,
                                 default = nil)
  if valid_594213 != nil:
    section.add "EnvironmentId", valid_594213
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
  var valid_594214 = header.getOrDefault("X-Amz-Signature")
  valid_594214 = validateParameter(valid_594214, JString, required = false,
                                 default = nil)
  if valid_594214 != nil:
    section.add "X-Amz-Signature", valid_594214
  var valid_594215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594215 = validateParameter(valid_594215, JString, required = false,
                                 default = nil)
  if valid_594215 != nil:
    section.add "X-Amz-Content-Sha256", valid_594215
  var valid_594216 = header.getOrDefault("X-Amz-Date")
  valid_594216 = validateParameter(valid_594216, JString, required = false,
                                 default = nil)
  if valid_594216 != nil:
    section.add "X-Amz-Date", valid_594216
  var valid_594217 = header.getOrDefault("X-Amz-Credential")
  valid_594217 = validateParameter(valid_594217, JString, required = false,
                                 default = nil)
  if valid_594217 != nil:
    section.add "X-Amz-Credential", valid_594217
  var valid_594218 = header.getOrDefault("X-Amz-Security-Token")
  valid_594218 = validateParameter(valid_594218, JString, required = false,
                                 default = nil)
  if valid_594218 != nil:
    section.add "X-Amz-Security-Token", valid_594218
  var valid_594219 = header.getOrDefault("X-Amz-Algorithm")
  valid_594219 = validateParameter(valid_594219, JString, required = false,
                                 default = nil)
  if valid_594219 != nil:
    section.add "X-Amz-Algorithm", valid_594219
  var valid_594220 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594220 = validateParameter(valid_594220, JString, required = false,
                                 default = nil)
  if valid_594220 != nil:
    section.add "X-Amz-SignedHeaders", valid_594220
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594221: Call_GetRequestEnvironmentInfo_594206; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a request to compile the specified type of information of the deployed environment.</p> <p> Setting the <code>InfoType</code> to <code>tail</code> compiles the last lines from the application server log files of every Amazon EC2 instance in your environment. </p> <p> Setting the <code>InfoType</code> to <code>bundle</code> compresses the application server log files for every Amazon EC2 instance into a <code>.zip</code> file. Legacy and .NET containers do not support bundle logs. </p> <p> Use <a>RetrieveEnvironmentInfo</a> to obtain the set of logs. </p> <p>Related Topics</p> <ul> <li> <p> <a>RetrieveEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_594221.validator(path, query, header, formData, body)
  let scheme = call_594221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594221.url(scheme.get, call_594221.host, call_594221.base,
                         call_594221.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594221, url, valid)

proc call*(call_594222: Call_GetRequestEnvironmentInfo_594206;
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
  var query_594223 = newJObject()
  add(query_594223, "InfoType", newJString(InfoType))
  add(query_594223, "EnvironmentName", newJString(EnvironmentName))
  add(query_594223, "Action", newJString(Action))
  add(query_594223, "Version", newJString(Version))
  add(query_594223, "EnvironmentId", newJString(EnvironmentId))
  result = call_594222.call(nil, query_594223, nil, nil, nil)

var getRequestEnvironmentInfo* = Call_GetRequestEnvironmentInfo_594206(
    name: "getRequestEnvironmentInfo", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RequestEnvironmentInfo",
    validator: validate_GetRequestEnvironmentInfo_594207, base: "/",
    url: url_GetRequestEnvironmentInfo_594208,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestartAppServer_594260 = ref object of OpenApiRestCall_592365
proc url_PostRestartAppServer_594262(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRestartAppServer_594261(path: JsonNode; query: JsonNode;
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
  var valid_594263 = query.getOrDefault("Action")
  valid_594263 = validateParameter(valid_594263, JString, required = true,
                                 default = newJString("RestartAppServer"))
  if valid_594263 != nil:
    section.add "Action", valid_594263
  var valid_594264 = query.getOrDefault("Version")
  valid_594264 = validateParameter(valid_594264, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594264 != nil:
    section.add "Version", valid_594264
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
  var valid_594265 = header.getOrDefault("X-Amz-Signature")
  valid_594265 = validateParameter(valid_594265, JString, required = false,
                                 default = nil)
  if valid_594265 != nil:
    section.add "X-Amz-Signature", valid_594265
  var valid_594266 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594266 = validateParameter(valid_594266, JString, required = false,
                                 default = nil)
  if valid_594266 != nil:
    section.add "X-Amz-Content-Sha256", valid_594266
  var valid_594267 = header.getOrDefault("X-Amz-Date")
  valid_594267 = validateParameter(valid_594267, JString, required = false,
                                 default = nil)
  if valid_594267 != nil:
    section.add "X-Amz-Date", valid_594267
  var valid_594268 = header.getOrDefault("X-Amz-Credential")
  valid_594268 = validateParameter(valid_594268, JString, required = false,
                                 default = nil)
  if valid_594268 != nil:
    section.add "X-Amz-Credential", valid_594268
  var valid_594269 = header.getOrDefault("X-Amz-Security-Token")
  valid_594269 = validateParameter(valid_594269, JString, required = false,
                                 default = nil)
  if valid_594269 != nil:
    section.add "X-Amz-Security-Token", valid_594269
  var valid_594270 = header.getOrDefault("X-Amz-Algorithm")
  valid_594270 = validateParameter(valid_594270, JString, required = false,
                                 default = nil)
  if valid_594270 != nil:
    section.add "X-Amz-Algorithm", valid_594270
  var valid_594271 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594271 = validateParameter(valid_594271, JString, required = false,
                                 default = nil)
  if valid_594271 != nil:
    section.add "X-Amz-SignedHeaders", valid_594271
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to restart the server for.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to restart the server for.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_594272 = formData.getOrDefault("EnvironmentName")
  valid_594272 = validateParameter(valid_594272, JString, required = false,
                                 default = nil)
  if valid_594272 != nil:
    section.add "EnvironmentName", valid_594272
  var valid_594273 = formData.getOrDefault("EnvironmentId")
  valid_594273 = validateParameter(valid_594273, JString, required = false,
                                 default = nil)
  if valid_594273 != nil:
    section.add "EnvironmentId", valid_594273
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594274: Call_PostRestartAppServer_594260; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Causes the environment to restart the application container server running on each Amazon EC2 instance.
  ## 
  let valid = call_594274.validator(path, query, header, formData, body)
  let scheme = call_594274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594274.url(scheme.get, call_594274.host, call_594274.base,
                         call_594274.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594274, url, valid)

proc call*(call_594275: Call_PostRestartAppServer_594260;
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
  var query_594276 = newJObject()
  var formData_594277 = newJObject()
  add(formData_594277, "EnvironmentName", newJString(EnvironmentName))
  add(query_594276, "Action", newJString(Action))
  add(formData_594277, "EnvironmentId", newJString(EnvironmentId))
  add(query_594276, "Version", newJString(Version))
  result = call_594275.call(nil, query_594276, nil, formData_594277, nil)

var postRestartAppServer* = Call_PostRestartAppServer_594260(
    name: "postRestartAppServer", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RestartAppServer",
    validator: validate_PostRestartAppServer_594261, base: "/",
    url: url_PostRestartAppServer_594262, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestartAppServer_594243 = ref object of OpenApiRestCall_592365
proc url_GetRestartAppServer_594245(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRestartAppServer_594244(path: JsonNode; query: JsonNode;
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
  var valid_594246 = query.getOrDefault("EnvironmentName")
  valid_594246 = validateParameter(valid_594246, JString, required = false,
                                 default = nil)
  if valid_594246 != nil:
    section.add "EnvironmentName", valid_594246
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594247 = query.getOrDefault("Action")
  valid_594247 = validateParameter(valid_594247, JString, required = true,
                                 default = newJString("RestartAppServer"))
  if valid_594247 != nil:
    section.add "Action", valid_594247
  var valid_594248 = query.getOrDefault("Version")
  valid_594248 = validateParameter(valid_594248, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594248 != nil:
    section.add "Version", valid_594248
  var valid_594249 = query.getOrDefault("EnvironmentId")
  valid_594249 = validateParameter(valid_594249, JString, required = false,
                                 default = nil)
  if valid_594249 != nil:
    section.add "EnvironmentId", valid_594249
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
  var valid_594250 = header.getOrDefault("X-Amz-Signature")
  valid_594250 = validateParameter(valid_594250, JString, required = false,
                                 default = nil)
  if valid_594250 != nil:
    section.add "X-Amz-Signature", valid_594250
  var valid_594251 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594251 = validateParameter(valid_594251, JString, required = false,
                                 default = nil)
  if valid_594251 != nil:
    section.add "X-Amz-Content-Sha256", valid_594251
  var valid_594252 = header.getOrDefault("X-Amz-Date")
  valid_594252 = validateParameter(valid_594252, JString, required = false,
                                 default = nil)
  if valid_594252 != nil:
    section.add "X-Amz-Date", valid_594252
  var valid_594253 = header.getOrDefault("X-Amz-Credential")
  valid_594253 = validateParameter(valid_594253, JString, required = false,
                                 default = nil)
  if valid_594253 != nil:
    section.add "X-Amz-Credential", valid_594253
  var valid_594254 = header.getOrDefault("X-Amz-Security-Token")
  valid_594254 = validateParameter(valid_594254, JString, required = false,
                                 default = nil)
  if valid_594254 != nil:
    section.add "X-Amz-Security-Token", valid_594254
  var valid_594255 = header.getOrDefault("X-Amz-Algorithm")
  valid_594255 = validateParameter(valid_594255, JString, required = false,
                                 default = nil)
  if valid_594255 != nil:
    section.add "X-Amz-Algorithm", valid_594255
  var valid_594256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594256 = validateParameter(valid_594256, JString, required = false,
                                 default = nil)
  if valid_594256 != nil:
    section.add "X-Amz-SignedHeaders", valid_594256
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594257: Call_GetRestartAppServer_594243; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Causes the environment to restart the application container server running on each Amazon EC2 instance.
  ## 
  let valid = call_594257.validator(path, query, header, formData, body)
  let scheme = call_594257.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594257.url(scheme.get, call_594257.host, call_594257.base,
                         call_594257.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594257, url, valid)

proc call*(call_594258: Call_GetRestartAppServer_594243;
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
  var query_594259 = newJObject()
  add(query_594259, "EnvironmentName", newJString(EnvironmentName))
  add(query_594259, "Action", newJString(Action))
  add(query_594259, "Version", newJString(Version))
  add(query_594259, "EnvironmentId", newJString(EnvironmentId))
  result = call_594258.call(nil, query_594259, nil, nil, nil)

var getRestartAppServer* = Call_GetRestartAppServer_594243(
    name: "getRestartAppServer", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RestartAppServer",
    validator: validate_GetRestartAppServer_594244, base: "/",
    url: url_GetRestartAppServer_594245, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRetrieveEnvironmentInfo_594296 = ref object of OpenApiRestCall_592365
proc url_PostRetrieveEnvironmentInfo_594298(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRetrieveEnvironmentInfo_594297(path: JsonNode; query: JsonNode;
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
  var valid_594299 = query.getOrDefault("Action")
  valid_594299 = validateParameter(valid_594299, JString, required = true, default = newJString(
      "RetrieveEnvironmentInfo"))
  if valid_594299 != nil:
    section.add "Action", valid_594299
  var valid_594300 = query.getOrDefault("Version")
  valid_594300 = validateParameter(valid_594300, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594300 != nil:
    section.add "Version", valid_594300
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
  var valid_594301 = header.getOrDefault("X-Amz-Signature")
  valid_594301 = validateParameter(valid_594301, JString, required = false,
                                 default = nil)
  if valid_594301 != nil:
    section.add "X-Amz-Signature", valid_594301
  var valid_594302 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594302 = validateParameter(valid_594302, JString, required = false,
                                 default = nil)
  if valid_594302 != nil:
    section.add "X-Amz-Content-Sha256", valid_594302
  var valid_594303 = header.getOrDefault("X-Amz-Date")
  valid_594303 = validateParameter(valid_594303, JString, required = false,
                                 default = nil)
  if valid_594303 != nil:
    section.add "X-Amz-Date", valid_594303
  var valid_594304 = header.getOrDefault("X-Amz-Credential")
  valid_594304 = validateParameter(valid_594304, JString, required = false,
                                 default = nil)
  if valid_594304 != nil:
    section.add "X-Amz-Credential", valid_594304
  var valid_594305 = header.getOrDefault("X-Amz-Security-Token")
  valid_594305 = validateParameter(valid_594305, JString, required = false,
                                 default = nil)
  if valid_594305 != nil:
    section.add "X-Amz-Security-Token", valid_594305
  var valid_594306 = header.getOrDefault("X-Amz-Algorithm")
  valid_594306 = validateParameter(valid_594306, JString, required = false,
                                 default = nil)
  if valid_594306 != nil:
    section.add "X-Amz-Algorithm", valid_594306
  var valid_594307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594307 = validateParameter(valid_594307, JString, required = false,
                                 default = nil)
  if valid_594307 != nil:
    section.add "X-Amz-SignedHeaders", valid_594307
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
  var valid_594308 = formData.getOrDefault("InfoType")
  valid_594308 = validateParameter(valid_594308, JString, required = true,
                                 default = newJString("tail"))
  if valid_594308 != nil:
    section.add "InfoType", valid_594308
  var valid_594309 = formData.getOrDefault("EnvironmentName")
  valid_594309 = validateParameter(valid_594309, JString, required = false,
                                 default = nil)
  if valid_594309 != nil:
    section.add "EnvironmentName", valid_594309
  var valid_594310 = formData.getOrDefault("EnvironmentId")
  valid_594310 = validateParameter(valid_594310, JString, required = false,
                                 default = nil)
  if valid_594310 != nil:
    section.add "EnvironmentId", valid_594310
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594311: Call_PostRetrieveEnvironmentInfo_594296; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the compiled information from a <a>RequestEnvironmentInfo</a> request.</p> <p>Related Topics</p> <ul> <li> <p> <a>RequestEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_594311.validator(path, query, header, formData, body)
  let scheme = call_594311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594311.url(scheme.get, call_594311.host, call_594311.base,
                         call_594311.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594311, url, valid)

proc call*(call_594312: Call_PostRetrieveEnvironmentInfo_594296;
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
  var query_594313 = newJObject()
  var formData_594314 = newJObject()
  add(formData_594314, "InfoType", newJString(InfoType))
  add(formData_594314, "EnvironmentName", newJString(EnvironmentName))
  add(query_594313, "Action", newJString(Action))
  add(formData_594314, "EnvironmentId", newJString(EnvironmentId))
  add(query_594313, "Version", newJString(Version))
  result = call_594312.call(nil, query_594313, nil, formData_594314, nil)

var postRetrieveEnvironmentInfo* = Call_PostRetrieveEnvironmentInfo_594296(
    name: "postRetrieveEnvironmentInfo", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RetrieveEnvironmentInfo",
    validator: validate_PostRetrieveEnvironmentInfo_594297, base: "/",
    url: url_PostRetrieveEnvironmentInfo_594298,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRetrieveEnvironmentInfo_594278 = ref object of OpenApiRestCall_592365
proc url_GetRetrieveEnvironmentInfo_594280(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRetrieveEnvironmentInfo_594279(path: JsonNode; query: JsonNode;
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
  var valid_594281 = query.getOrDefault("InfoType")
  valid_594281 = validateParameter(valid_594281, JString, required = true,
                                 default = newJString("tail"))
  if valid_594281 != nil:
    section.add "InfoType", valid_594281
  var valid_594282 = query.getOrDefault("EnvironmentName")
  valid_594282 = validateParameter(valid_594282, JString, required = false,
                                 default = nil)
  if valid_594282 != nil:
    section.add "EnvironmentName", valid_594282
  var valid_594283 = query.getOrDefault("Action")
  valid_594283 = validateParameter(valid_594283, JString, required = true, default = newJString(
      "RetrieveEnvironmentInfo"))
  if valid_594283 != nil:
    section.add "Action", valid_594283
  var valid_594284 = query.getOrDefault("Version")
  valid_594284 = validateParameter(valid_594284, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594284 != nil:
    section.add "Version", valid_594284
  var valid_594285 = query.getOrDefault("EnvironmentId")
  valid_594285 = validateParameter(valid_594285, JString, required = false,
                                 default = nil)
  if valid_594285 != nil:
    section.add "EnvironmentId", valid_594285
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
  var valid_594286 = header.getOrDefault("X-Amz-Signature")
  valid_594286 = validateParameter(valid_594286, JString, required = false,
                                 default = nil)
  if valid_594286 != nil:
    section.add "X-Amz-Signature", valid_594286
  var valid_594287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594287 = validateParameter(valid_594287, JString, required = false,
                                 default = nil)
  if valid_594287 != nil:
    section.add "X-Amz-Content-Sha256", valid_594287
  var valid_594288 = header.getOrDefault("X-Amz-Date")
  valid_594288 = validateParameter(valid_594288, JString, required = false,
                                 default = nil)
  if valid_594288 != nil:
    section.add "X-Amz-Date", valid_594288
  var valid_594289 = header.getOrDefault("X-Amz-Credential")
  valid_594289 = validateParameter(valid_594289, JString, required = false,
                                 default = nil)
  if valid_594289 != nil:
    section.add "X-Amz-Credential", valid_594289
  var valid_594290 = header.getOrDefault("X-Amz-Security-Token")
  valid_594290 = validateParameter(valid_594290, JString, required = false,
                                 default = nil)
  if valid_594290 != nil:
    section.add "X-Amz-Security-Token", valid_594290
  var valid_594291 = header.getOrDefault("X-Amz-Algorithm")
  valid_594291 = validateParameter(valid_594291, JString, required = false,
                                 default = nil)
  if valid_594291 != nil:
    section.add "X-Amz-Algorithm", valid_594291
  var valid_594292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594292 = validateParameter(valid_594292, JString, required = false,
                                 default = nil)
  if valid_594292 != nil:
    section.add "X-Amz-SignedHeaders", valid_594292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594293: Call_GetRetrieveEnvironmentInfo_594278; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the compiled information from a <a>RequestEnvironmentInfo</a> request.</p> <p>Related Topics</p> <ul> <li> <p> <a>RequestEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_594293.validator(path, query, header, formData, body)
  let scheme = call_594293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594293.url(scheme.get, call_594293.host, call_594293.base,
                         call_594293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594293, url, valid)

proc call*(call_594294: Call_GetRetrieveEnvironmentInfo_594278;
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
  var query_594295 = newJObject()
  add(query_594295, "InfoType", newJString(InfoType))
  add(query_594295, "EnvironmentName", newJString(EnvironmentName))
  add(query_594295, "Action", newJString(Action))
  add(query_594295, "Version", newJString(Version))
  add(query_594295, "EnvironmentId", newJString(EnvironmentId))
  result = call_594294.call(nil, query_594295, nil, nil, nil)

var getRetrieveEnvironmentInfo* = Call_GetRetrieveEnvironmentInfo_594278(
    name: "getRetrieveEnvironmentInfo", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RetrieveEnvironmentInfo",
    validator: validate_GetRetrieveEnvironmentInfo_594279, base: "/",
    url: url_GetRetrieveEnvironmentInfo_594280,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSwapEnvironmentCNAMEs_594334 = ref object of OpenApiRestCall_592365
proc url_PostSwapEnvironmentCNAMEs_594336(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostSwapEnvironmentCNAMEs_594335(path: JsonNode; query: JsonNode;
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
  var valid_594337 = query.getOrDefault("Action")
  valid_594337 = validateParameter(valid_594337, JString, required = true,
                                 default = newJString("SwapEnvironmentCNAMEs"))
  if valid_594337 != nil:
    section.add "Action", valid_594337
  var valid_594338 = query.getOrDefault("Version")
  valid_594338 = validateParameter(valid_594338, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594338 != nil:
    section.add "Version", valid_594338
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
  var valid_594339 = header.getOrDefault("X-Amz-Signature")
  valid_594339 = validateParameter(valid_594339, JString, required = false,
                                 default = nil)
  if valid_594339 != nil:
    section.add "X-Amz-Signature", valid_594339
  var valid_594340 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594340 = validateParameter(valid_594340, JString, required = false,
                                 default = nil)
  if valid_594340 != nil:
    section.add "X-Amz-Content-Sha256", valid_594340
  var valid_594341 = header.getOrDefault("X-Amz-Date")
  valid_594341 = validateParameter(valid_594341, JString, required = false,
                                 default = nil)
  if valid_594341 != nil:
    section.add "X-Amz-Date", valid_594341
  var valid_594342 = header.getOrDefault("X-Amz-Credential")
  valid_594342 = validateParameter(valid_594342, JString, required = false,
                                 default = nil)
  if valid_594342 != nil:
    section.add "X-Amz-Credential", valid_594342
  var valid_594343 = header.getOrDefault("X-Amz-Security-Token")
  valid_594343 = validateParameter(valid_594343, JString, required = false,
                                 default = nil)
  if valid_594343 != nil:
    section.add "X-Amz-Security-Token", valid_594343
  var valid_594344 = header.getOrDefault("X-Amz-Algorithm")
  valid_594344 = validateParameter(valid_594344, JString, required = false,
                                 default = nil)
  if valid_594344 != nil:
    section.add "X-Amz-Algorithm", valid_594344
  var valid_594345 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594345 = validateParameter(valid_594345, JString, required = false,
                                 default = nil)
  if valid_594345 != nil:
    section.add "X-Amz-SignedHeaders", valid_594345
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
  var valid_594346 = formData.getOrDefault("DestinationEnvironmentName")
  valid_594346 = validateParameter(valid_594346, JString, required = false,
                                 default = nil)
  if valid_594346 != nil:
    section.add "DestinationEnvironmentName", valid_594346
  var valid_594347 = formData.getOrDefault("DestinationEnvironmentId")
  valid_594347 = validateParameter(valid_594347, JString, required = false,
                                 default = nil)
  if valid_594347 != nil:
    section.add "DestinationEnvironmentId", valid_594347
  var valid_594348 = formData.getOrDefault("SourceEnvironmentId")
  valid_594348 = validateParameter(valid_594348, JString, required = false,
                                 default = nil)
  if valid_594348 != nil:
    section.add "SourceEnvironmentId", valid_594348
  var valid_594349 = formData.getOrDefault("SourceEnvironmentName")
  valid_594349 = validateParameter(valid_594349, JString, required = false,
                                 default = nil)
  if valid_594349 != nil:
    section.add "SourceEnvironmentName", valid_594349
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594350: Call_PostSwapEnvironmentCNAMEs_594334; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Swaps the CNAMEs of two environments.
  ## 
  let valid = call_594350.validator(path, query, header, formData, body)
  let scheme = call_594350.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594350.url(scheme.get, call_594350.host, call_594350.base,
                         call_594350.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594350, url, valid)

proc call*(call_594351: Call_PostSwapEnvironmentCNAMEs_594334;
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
  var query_594352 = newJObject()
  var formData_594353 = newJObject()
  add(formData_594353, "DestinationEnvironmentName",
      newJString(DestinationEnvironmentName))
  add(formData_594353, "DestinationEnvironmentId",
      newJString(DestinationEnvironmentId))
  add(formData_594353, "SourceEnvironmentId", newJString(SourceEnvironmentId))
  add(formData_594353, "SourceEnvironmentName", newJString(SourceEnvironmentName))
  add(query_594352, "Action", newJString(Action))
  add(query_594352, "Version", newJString(Version))
  result = call_594351.call(nil, query_594352, nil, formData_594353, nil)

var postSwapEnvironmentCNAMEs* = Call_PostSwapEnvironmentCNAMEs_594334(
    name: "postSwapEnvironmentCNAMEs", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=SwapEnvironmentCNAMEs",
    validator: validate_PostSwapEnvironmentCNAMEs_594335, base: "/",
    url: url_PostSwapEnvironmentCNAMEs_594336,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSwapEnvironmentCNAMEs_594315 = ref object of OpenApiRestCall_592365
proc url_GetSwapEnvironmentCNAMEs_594317(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSwapEnvironmentCNAMEs_594316(path: JsonNode; query: JsonNode;
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
  var valid_594318 = query.getOrDefault("SourceEnvironmentId")
  valid_594318 = validateParameter(valid_594318, JString, required = false,
                                 default = nil)
  if valid_594318 != nil:
    section.add "SourceEnvironmentId", valid_594318
  var valid_594319 = query.getOrDefault("SourceEnvironmentName")
  valid_594319 = validateParameter(valid_594319, JString, required = false,
                                 default = nil)
  if valid_594319 != nil:
    section.add "SourceEnvironmentName", valid_594319
  var valid_594320 = query.getOrDefault("DestinationEnvironmentName")
  valid_594320 = validateParameter(valid_594320, JString, required = false,
                                 default = nil)
  if valid_594320 != nil:
    section.add "DestinationEnvironmentName", valid_594320
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594321 = query.getOrDefault("Action")
  valid_594321 = validateParameter(valid_594321, JString, required = true,
                                 default = newJString("SwapEnvironmentCNAMEs"))
  if valid_594321 != nil:
    section.add "Action", valid_594321
  var valid_594322 = query.getOrDefault("DestinationEnvironmentId")
  valid_594322 = validateParameter(valid_594322, JString, required = false,
                                 default = nil)
  if valid_594322 != nil:
    section.add "DestinationEnvironmentId", valid_594322
  var valid_594323 = query.getOrDefault("Version")
  valid_594323 = validateParameter(valid_594323, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594323 != nil:
    section.add "Version", valid_594323
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
  var valid_594324 = header.getOrDefault("X-Amz-Signature")
  valid_594324 = validateParameter(valid_594324, JString, required = false,
                                 default = nil)
  if valid_594324 != nil:
    section.add "X-Amz-Signature", valid_594324
  var valid_594325 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594325 = validateParameter(valid_594325, JString, required = false,
                                 default = nil)
  if valid_594325 != nil:
    section.add "X-Amz-Content-Sha256", valid_594325
  var valid_594326 = header.getOrDefault("X-Amz-Date")
  valid_594326 = validateParameter(valid_594326, JString, required = false,
                                 default = nil)
  if valid_594326 != nil:
    section.add "X-Amz-Date", valid_594326
  var valid_594327 = header.getOrDefault("X-Amz-Credential")
  valid_594327 = validateParameter(valid_594327, JString, required = false,
                                 default = nil)
  if valid_594327 != nil:
    section.add "X-Amz-Credential", valid_594327
  var valid_594328 = header.getOrDefault("X-Amz-Security-Token")
  valid_594328 = validateParameter(valid_594328, JString, required = false,
                                 default = nil)
  if valid_594328 != nil:
    section.add "X-Amz-Security-Token", valid_594328
  var valid_594329 = header.getOrDefault("X-Amz-Algorithm")
  valid_594329 = validateParameter(valid_594329, JString, required = false,
                                 default = nil)
  if valid_594329 != nil:
    section.add "X-Amz-Algorithm", valid_594329
  var valid_594330 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594330 = validateParameter(valid_594330, JString, required = false,
                                 default = nil)
  if valid_594330 != nil:
    section.add "X-Amz-SignedHeaders", valid_594330
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594331: Call_GetSwapEnvironmentCNAMEs_594315; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Swaps the CNAMEs of two environments.
  ## 
  let valid = call_594331.validator(path, query, header, formData, body)
  let scheme = call_594331.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594331.url(scheme.get, call_594331.host, call_594331.base,
                         call_594331.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594331, url, valid)

proc call*(call_594332: Call_GetSwapEnvironmentCNAMEs_594315;
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
  var query_594333 = newJObject()
  add(query_594333, "SourceEnvironmentId", newJString(SourceEnvironmentId))
  add(query_594333, "SourceEnvironmentName", newJString(SourceEnvironmentName))
  add(query_594333, "DestinationEnvironmentName",
      newJString(DestinationEnvironmentName))
  add(query_594333, "Action", newJString(Action))
  add(query_594333, "DestinationEnvironmentId",
      newJString(DestinationEnvironmentId))
  add(query_594333, "Version", newJString(Version))
  result = call_594332.call(nil, query_594333, nil, nil, nil)

var getSwapEnvironmentCNAMEs* = Call_GetSwapEnvironmentCNAMEs_594315(
    name: "getSwapEnvironmentCNAMEs", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=SwapEnvironmentCNAMEs",
    validator: validate_GetSwapEnvironmentCNAMEs_594316, base: "/",
    url: url_GetSwapEnvironmentCNAMEs_594317, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostTerminateEnvironment_594373 = ref object of OpenApiRestCall_592365
proc url_PostTerminateEnvironment_594375(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostTerminateEnvironment_594374(path: JsonNode; query: JsonNode;
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
  var valid_594376 = query.getOrDefault("Action")
  valid_594376 = validateParameter(valid_594376, JString, required = true,
                                 default = newJString("TerminateEnvironment"))
  if valid_594376 != nil:
    section.add "Action", valid_594376
  var valid_594377 = query.getOrDefault("Version")
  valid_594377 = validateParameter(valid_594377, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594377 != nil:
    section.add "Version", valid_594377
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
  var valid_594378 = header.getOrDefault("X-Amz-Signature")
  valid_594378 = validateParameter(valid_594378, JString, required = false,
                                 default = nil)
  if valid_594378 != nil:
    section.add "X-Amz-Signature", valid_594378
  var valid_594379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594379 = validateParameter(valid_594379, JString, required = false,
                                 default = nil)
  if valid_594379 != nil:
    section.add "X-Amz-Content-Sha256", valid_594379
  var valid_594380 = header.getOrDefault("X-Amz-Date")
  valid_594380 = validateParameter(valid_594380, JString, required = false,
                                 default = nil)
  if valid_594380 != nil:
    section.add "X-Amz-Date", valid_594380
  var valid_594381 = header.getOrDefault("X-Amz-Credential")
  valid_594381 = validateParameter(valid_594381, JString, required = false,
                                 default = nil)
  if valid_594381 != nil:
    section.add "X-Amz-Credential", valid_594381
  var valid_594382 = header.getOrDefault("X-Amz-Security-Token")
  valid_594382 = validateParameter(valid_594382, JString, required = false,
                                 default = nil)
  if valid_594382 != nil:
    section.add "X-Amz-Security-Token", valid_594382
  var valid_594383 = header.getOrDefault("X-Amz-Algorithm")
  valid_594383 = validateParameter(valid_594383, JString, required = false,
                                 default = nil)
  if valid_594383 != nil:
    section.add "X-Amz-Algorithm", valid_594383
  var valid_594384 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594384 = validateParameter(valid_594384, JString, required = false,
                                 default = nil)
  if valid_594384 != nil:
    section.add "X-Amz-SignedHeaders", valid_594384
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
  var valid_594385 = formData.getOrDefault("EnvironmentName")
  valid_594385 = validateParameter(valid_594385, JString, required = false,
                                 default = nil)
  if valid_594385 != nil:
    section.add "EnvironmentName", valid_594385
  var valid_594386 = formData.getOrDefault("TerminateResources")
  valid_594386 = validateParameter(valid_594386, JBool, required = false, default = nil)
  if valid_594386 != nil:
    section.add "TerminateResources", valid_594386
  var valid_594387 = formData.getOrDefault("ForceTerminate")
  valid_594387 = validateParameter(valid_594387, JBool, required = false, default = nil)
  if valid_594387 != nil:
    section.add "ForceTerminate", valid_594387
  var valid_594388 = formData.getOrDefault("EnvironmentId")
  valid_594388 = validateParameter(valid_594388, JString, required = false,
                                 default = nil)
  if valid_594388 != nil:
    section.add "EnvironmentId", valid_594388
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594389: Call_PostTerminateEnvironment_594373; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Terminates the specified environment.
  ## 
  let valid = call_594389.validator(path, query, header, formData, body)
  let scheme = call_594389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594389.url(scheme.get, call_594389.host, call_594389.base,
                         call_594389.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594389, url, valid)

proc call*(call_594390: Call_PostTerminateEnvironment_594373;
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
  var query_594391 = newJObject()
  var formData_594392 = newJObject()
  add(formData_594392, "EnvironmentName", newJString(EnvironmentName))
  add(formData_594392, "TerminateResources", newJBool(TerminateResources))
  add(query_594391, "Action", newJString(Action))
  add(formData_594392, "ForceTerminate", newJBool(ForceTerminate))
  add(formData_594392, "EnvironmentId", newJString(EnvironmentId))
  add(query_594391, "Version", newJString(Version))
  result = call_594390.call(nil, query_594391, nil, formData_594392, nil)

var postTerminateEnvironment* = Call_PostTerminateEnvironment_594373(
    name: "postTerminateEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=TerminateEnvironment",
    validator: validate_PostTerminateEnvironment_594374, base: "/",
    url: url_PostTerminateEnvironment_594375, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTerminateEnvironment_594354 = ref object of OpenApiRestCall_592365
proc url_GetTerminateEnvironment_594356(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetTerminateEnvironment_594355(path: JsonNode; query: JsonNode;
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
  var valid_594357 = query.getOrDefault("ForceTerminate")
  valid_594357 = validateParameter(valid_594357, JBool, required = false, default = nil)
  if valid_594357 != nil:
    section.add "ForceTerminate", valid_594357
  var valid_594358 = query.getOrDefault("TerminateResources")
  valid_594358 = validateParameter(valid_594358, JBool, required = false, default = nil)
  if valid_594358 != nil:
    section.add "TerminateResources", valid_594358
  var valid_594359 = query.getOrDefault("EnvironmentName")
  valid_594359 = validateParameter(valid_594359, JString, required = false,
                                 default = nil)
  if valid_594359 != nil:
    section.add "EnvironmentName", valid_594359
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594360 = query.getOrDefault("Action")
  valid_594360 = validateParameter(valid_594360, JString, required = true,
                                 default = newJString("TerminateEnvironment"))
  if valid_594360 != nil:
    section.add "Action", valid_594360
  var valid_594361 = query.getOrDefault("Version")
  valid_594361 = validateParameter(valid_594361, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594361 != nil:
    section.add "Version", valid_594361
  var valid_594362 = query.getOrDefault("EnvironmentId")
  valid_594362 = validateParameter(valid_594362, JString, required = false,
                                 default = nil)
  if valid_594362 != nil:
    section.add "EnvironmentId", valid_594362
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
  var valid_594363 = header.getOrDefault("X-Amz-Signature")
  valid_594363 = validateParameter(valid_594363, JString, required = false,
                                 default = nil)
  if valid_594363 != nil:
    section.add "X-Amz-Signature", valid_594363
  var valid_594364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594364 = validateParameter(valid_594364, JString, required = false,
                                 default = nil)
  if valid_594364 != nil:
    section.add "X-Amz-Content-Sha256", valid_594364
  var valid_594365 = header.getOrDefault("X-Amz-Date")
  valid_594365 = validateParameter(valid_594365, JString, required = false,
                                 default = nil)
  if valid_594365 != nil:
    section.add "X-Amz-Date", valid_594365
  var valid_594366 = header.getOrDefault("X-Amz-Credential")
  valid_594366 = validateParameter(valid_594366, JString, required = false,
                                 default = nil)
  if valid_594366 != nil:
    section.add "X-Amz-Credential", valid_594366
  var valid_594367 = header.getOrDefault("X-Amz-Security-Token")
  valid_594367 = validateParameter(valid_594367, JString, required = false,
                                 default = nil)
  if valid_594367 != nil:
    section.add "X-Amz-Security-Token", valid_594367
  var valid_594368 = header.getOrDefault("X-Amz-Algorithm")
  valid_594368 = validateParameter(valid_594368, JString, required = false,
                                 default = nil)
  if valid_594368 != nil:
    section.add "X-Amz-Algorithm", valid_594368
  var valid_594369 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594369 = validateParameter(valid_594369, JString, required = false,
                                 default = nil)
  if valid_594369 != nil:
    section.add "X-Amz-SignedHeaders", valid_594369
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594370: Call_GetTerminateEnvironment_594354; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Terminates the specified environment.
  ## 
  let valid = call_594370.validator(path, query, header, formData, body)
  let scheme = call_594370.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594370.url(scheme.get, call_594370.host, call_594370.base,
                         call_594370.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594370, url, valid)

proc call*(call_594371: Call_GetTerminateEnvironment_594354;
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
  var query_594372 = newJObject()
  add(query_594372, "ForceTerminate", newJBool(ForceTerminate))
  add(query_594372, "TerminateResources", newJBool(TerminateResources))
  add(query_594372, "EnvironmentName", newJString(EnvironmentName))
  add(query_594372, "Action", newJString(Action))
  add(query_594372, "Version", newJString(Version))
  add(query_594372, "EnvironmentId", newJString(EnvironmentId))
  result = call_594371.call(nil, query_594372, nil, nil, nil)

var getTerminateEnvironment* = Call_GetTerminateEnvironment_594354(
    name: "getTerminateEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=TerminateEnvironment",
    validator: validate_GetTerminateEnvironment_594355, base: "/",
    url: url_GetTerminateEnvironment_594356, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateApplication_594410 = ref object of OpenApiRestCall_592365
proc url_PostUpdateApplication_594412(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateApplication_594411(path: JsonNode; query: JsonNode;
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
  var valid_594413 = query.getOrDefault("Action")
  valid_594413 = validateParameter(valid_594413, JString, required = true,
                                 default = newJString("UpdateApplication"))
  if valid_594413 != nil:
    section.add "Action", valid_594413
  var valid_594414 = query.getOrDefault("Version")
  valid_594414 = validateParameter(valid_594414, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594414 != nil:
    section.add "Version", valid_594414
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
  var valid_594415 = header.getOrDefault("X-Amz-Signature")
  valid_594415 = validateParameter(valid_594415, JString, required = false,
                                 default = nil)
  if valid_594415 != nil:
    section.add "X-Amz-Signature", valid_594415
  var valid_594416 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594416 = validateParameter(valid_594416, JString, required = false,
                                 default = nil)
  if valid_594416 != nil:
    section.add "X-Amz-Content-Sha256", valid_594416
  var valid_594417 = header.getOrDefault("X-Amz-Date")
  valid_594417 = validateParameter(valid_594417, JString, required = false,
                                 default = nil)
  if valid_594417 != nil:
    section.add "X-Amz-Date", valid_594417
  var valid_594418 = header.getOrDefault("X-Amz-Credential")
  valid_594418 = validateParameter(valid_594418, JString, required = false,
                                 default = nil)
  if valid_594418 != nil:
    section.add "X-Amz-Credential", valid_594418
  var valid_594419 = header.getOrDefault("X-Amz-Security-Token")
  valid_594419 = validateParameter(valid_594419, JString, required = false,
                                 default = nil)
  if valid_594419 != nil:
    section.add "X-Amz-Security-Token", valid_594419
  var valid_594420 = header.getOrDefault("X-Amz-Algorithm")
  valid_594420 = validateParameter(valid_594420, JString, required = false,
                                 default = nil)
  if valid_594420 != nil:
    section.add "X-Amz-Algorithm", valid_594420
  var valid_594421 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594421 = validateParameter(valid_594421, JString, required = false,
                                 default = nil)
  if valid_594421 != nil:
    section.add "X-Amz-SignedHeaders", valid_594421
  result.add "header", section
  ## parameters in `formData` object:
  ##   Description: JString
  ##              : <p>A new description for the application.</p> <p>Default: If not specified, AWS Elastic Beanstalk does not update the description.</p>
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to update. If no such application is found, <code>UpdateApplication</code> returns an <code>InvalidParameterValue</code> error. 
  section = newJObject()
  var valid_594422 = formData.getOrDefault("Description")
  valid_594422 = validateParameter(valid_594422, JString, required = false,
                                 default = nil)
  if valid_594422 != nil:
    section.add "Description", valid_594422
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_594423 = formData.getOrDefault("ApplicationName")
  valid_594423 = validateParameter(valid_594423, JString, required = true,
                                 default = nil)
  if valid_594423 != nil:
    section.add "ApplicationName", valid_594423
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594424: Call_PostUpdateApplication_594410; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified application to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear these properties, specify an empty string.</p> </note>
  ## 
  let valid = call_594424.validator(path, query, header, formData, body)
  let scheme = call_594424.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594424.url(scheme.get, call_594424.host, call_594424.base,
                         call_594424.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594424, url, valid)

proc call*(call_594425: Call_PostUpdateApplication_594410; ApplicationName: string;
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
  var query_594426 = newJObject()
  var formData_594427 = newJObject()
  add(formData_594427, "Description", newJString(Description))
  add(formData_594427, "ApplicationName", newJString(ApplicationName))
  add(query_594426, "Action", newJString(Action))
  add(query_594426, "Version", newJString(Version))
  result = call_594425.call(nil, query_594426, nil, formData_594427, nil)

var postUpdateApplication* = Call_PostUpdateApplication_594410(
    name: "postUpdateApplication", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateApplication",
    validator: validate_PostUpdateApplication_594411, base: "/",
    url: url_PostUpdateApplication_594412, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateApplication_594393 = ref object of OpenApiRestCall_592365
proc url_GetUpdateApplication_594395(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateApplication_594394(path: JsonNode; query: JsonNode;
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
  var valid_594396 = query.getOrDefault("ApplicationName")
  valid_594396 = validateParameter(valid_594396, JString, required = true,
                                 default = nil)
  if valid_594396 != nil:
    section.add "ApplicationName", valid_594396
  var valid_594397 = query.getOrDefault("Action")
  valid_594397 = validateParameter(valid_594397, JString, required = true,
                                 default = newJString("UpdateApplication"))
  if valid_594397 != nil:
    section.add "Action", valid_594397
  var valid_594398 = query.getOrDefault("Description")
  valid_594398 = validateParameter(valid_594398, JString, required = false,
                                 default = nil)
  if valid_594398 != nil:
    section.add "Description", valid_594398
  var valid_594399 = query.getOrDefault("Version")
  valid_594399 = validateParameter(valid_594399, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594399 != nil:
    section.add "Version", valid_594399
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
  var valid_594400 = header.getOrDefault("X-Amz-Signature")
  valid_594400 = validateParameter(valid_594400, JString, required = false,
                                 default = nil)
  if valid_594400 != nil:
    section.add "X-Amz-Signature", valid_594400
  var valid_594401 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594401 = validateParameter(valid_594401, JString, required = false,
                                 default = nil)
  if valid_594401 != nil:
    section.add "X-Amz-Content-Sha256", valid_594401
  var valid_594402 = header.getOrDefault("X-Amz-Date")
  valid_594402 = validateParameter(valid_594402, JString, required = false,
                                 default = nil)
  if valid_594402 != nil:
    section.add "X-Amz-Date", valid_594402
  var valid_594403 = header.getOrDefault("X-Amz-Credential")
  valid_594403 = validateParameter(valid_594403, JString, required = false,
                                 default = nil)
  if valid_594403 != nil:
    section.add "X-Amz-Credential", valid_594403
  var valid_594404 = header.getOrDefault("X-Amz-Security-Token")
  valid_594404 = validateParameter(valid_594404, JString, required = false,
                                 default = nil)
  if valid_594404 != nil:
    section.add "X-Amz-Security-Token", valid_594404
  var valid_594405 = header.getOrDefault("X-Amz-Algorithm")
  valid_594405 = validateParameter(valid_594405, JString, required = false,
                                 default = nil)
  if valid_594405 != nil:
    section.add "X-Amz-Algorithm", valid_594405
  var valid_594406 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594406 = validateParameter(valid_594406, JString, required = false,
                                 default = nil)
  if valid_594406 != nil:
    section.add "X-Amz-SignedHeaders", valid_594406
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594407: Call_GetUpdateApplication_594393; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified application to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear these properties, specify an empty string.</p> </note>
  ## 
  let valid = call_594407.validator(path, query, header, formData, body)
  let scheme = call_594407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594407.url(scheme.get, call_594407.host, call_594407.base,
                         call_594407.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594407, url, valid)

proc call*(call_594408: Call_GetUpdateApplication_594393; ApplicationName: string;
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
  var query_594409 = newJObject()
  add(query_594409, "ApplicationName", newJString(ApplicationName))
  add(query_594409, "Action", newJString(Action))
  add(query_594409, "Description", newJString(Description))
  add(query_594409, "Version", newJString(Version))
  result = call_594408.call(nil, query_594409, nil, nil, nil)

var getUpdateApplication* = Call_GetUpdateApplication_594393(
    name: "getUpdateApplication", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateApplication",
    validator: validate_GetUpdateApplication_594394, base: "/",
    url: url_GetUpdateApplication_594395, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateApplicationResourceLifecycle_594446 = ref object of OpenApiRestCall_592365
proc url_PostUpdateApplicationResourceLifecycle_594448(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateApplicationResourceLifecycle_594447(path: JsonNode;
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
  var valid_594449 = query.getOrDefault("Action")
  valid_594449 = validateParameter(valid_594449, JString, required = true, default = newJString(
      "UpdateApplicationResourceLifecycle"))
  if valid_594449 != nil:
    section.add "Action", valid_594449
  var valid_594450 = query.getOrDefault("Version")
  valid_594450 = validateParameter(valid_594450, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594450 != nil:
    section.add "Version", valid_594450
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
  var valid_594451 = header.getOrDefault("X-Amz-Signature")
  valid_594451 = validateParameter(valid_594451, JString, required = false,
                                 default = nil)
  if valid_594451 != nil:
    section.add "X-Amz-Signature", valid_594451
  var valid_594452 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594452 = validateParameter(valid_594452, JString, required = false,
                                 default = nil)
  if valid_594452 != nil:
    section.add "X-Amz-Content-Sha256", valid_594452
  var valid_594453 = header.getOrDefault("X-Amz-Date")
  valid_594453 = validateParameter(valid_594453, JString, required = false,
                                 default = nil)
  if valid_594453 != nil:
    section.add "X-Amz-Date", valid_594453
  var valid_594454 = header.getOrDefault("X-Amz-Credential")
  valid_594454 = validateParameter(valid_594454, JString, required = false,
                                 default = nil)
  if valid_594454 != nil:
    section.add "X-Amz-Credential", valid_594454
  var valid_594455 = header.getOrDefault("X-Amz-Security-Token")
  valid_594455 = validateParameter(valid_594455, JString, required = false,
                                 default = nil)
  if valid_594455 != nil:
    section.add "X-Amz-Security-Token", valid_594455
  var valid_594456 = header.getOrDefault("X-Amz-Algorithm")
  valid_594456 = validateParameter(valid_594456, JString, required = false,
                                 default = nil)
  if valid_594456 != nil:
    section.add "X-Amz-Algorithm", valid_594456
  var valid_594457 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594457 = validateParameter(valid_594457, JString, required = false,
                                 default = nil)
  if valid_594457 != nil:
    section.add "X-Amz-SignedHeaders", valid_594457
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
  var valid_594458 = formData.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_594458 = validateParameter(valid_594458, JString, required = false,
                                 default = nil)
  if valid_594458 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_594458
  var valid_594459 = formData.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_594459 = validateParameter(valid_594459, JString, required = false,
                                 default = nil)
  if valid_594459 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_594459
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_594460 = formData.getOrDefault("ApplicationName")
  valid_594460 = validateParameter(valid_594460, JString, required = true,
                                 default = nil)
  if valid_594460 != nil:
    section.add "ApplicationName", valid_594460
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594461: Call_PostUpdateApplicationResourceLifecycle_594446;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Modifies lifecycle settings for an application.
  ## 
  let valid = call_594461.validator(path, query, header, formData, body)
  let scheme = call_594461.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594461.url(scheme.get, call_594461.host, call_594461.base,
                         call_594461.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594461, url, valid)

proc call*(call_594462: Call_PostUpdateApplicationResourceLifecycle_594446;
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
  var query_594463 = newJObject()
  var formData_594464 = newJObject()
  add(formData_594464, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  add(formData_594464, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  add(formData_594464, "ApplicationName", newJString(ApplicationName))
  add(query_594463, "Action", newJString(Action))
  add(query_594463, "Version", newJString(Version))
  result = call_594462.call(nil, query_594463, nil, formData_594464, nil)

var postUpdateApplicationResourceLifecycle* = Call_PostUpdateApplicationResourceLifecycle_594446(
    name: "postUpdateApplicationResourceLifecycle", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationResourceLifecycle",
    validator: validate_PostUpdateApplicationResourceLifecycle_594447, base: "/",
    url: url_PostUpdateApplicationResourceLifecycle_594448,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateApplicationResourceLifecycle_594428 = ref object of OpenApiRestCall_592365
proc url_GetUpdateApplicationResourceLifecycle_594430(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateApplicationResourceLifecycle_594429(path: JsonNode;
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
  var valid_594431 = query.getOrDefault("ApplicationName")
  valid_594431 = validateParameter(valid_594431, JString, required = true,
                                 default = nil)
  if valid_594431 != nil:
    section.add "ApplicationName", valid_594431
  var valid_594432 = query.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_594432 = validateParameter(valid_594432, JString, required = false,
                                 default = nil)
  if valid_594432 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_594432
  var valid_594433 = query.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_594433 = validateParameter(valid_594433, JString, required = false,
                                 default = nil)
  if valid_594433 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_594433
  var valid_594434 = query.getOrDefault("Action")
  valid_594434 = validateParameter(valid_594434, JString, required = true, default = newJString(
      "UpdateApplicationResourceLifecycle"))
  if valid_594434 != nil:
    section.add "Action", valid_594434
  var valid_594435 = query.getOrDefault("Version")
  valid_594435 = validateParameter(valid_594435, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594435 != nil:
    section.add "Version", valid_594435
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
  var valid_594436 = header.getOrDefault("X-Amz-Signature")
  valid_594436 = validateParameter(valid_594436, JString, required = false,
                                 default = nil)
  if valid_594436 != nil:
    section.add "X-Amz-Signature", valid_594436
  var valid_594437 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594437 = validateParameter(valid_594437, JString, required = false,
                                 default = nil)
  if valid_594437 != nil:
    section.add "X-Amz-Content-Sha256", valid_594437
  var valid_594438 = header.getOrDefault("X-Amz-Date")
  valid_594438 = validateParameter(valid_594438, JString, required = false,
                                 default = nil)
  if valid_594438 != nil:
    section.add "X-Amz-Date", valid_594438
  var valid_594439 = header.getOrDefault("X-Amz-Credential")
  valid_594439 = validateParameter(valid_594439, JString, required = false,
                                 default = nil)
  if valid_594439 != nil:
    section.add "X-Amz-Credential", valid_594439
  var valid_594440 = header.getOrDefault("X-Amz-Security-Token")
  valid_594440 = validateParameter(valid_594440, JString, required = false,
                                 default = nil)
  if valid_594440 != nil:
    section.add "X-Amz-Security-Token", valid_594440
  var valid_594441 = header.getOrDefault("X-Amz-Algorithm")
  valid_594441 = validateParameter(valid_594441, JString, required = false,
                                 default = nil)
  if valid_594441 != nil:
    section.add "X-Amz-Algorithm", valid_594441
  var valid_594442 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594442 = validateParameter(valid_594442, JString, required = false,
                                 default = nil)
  if valid_594442 != nil:
    section.add "X-Amz-SignedHeaders", valid_594442
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594443: Call_GetUpdateApplicationResourceLifecycle_594428;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Modifies lifecycle settings for an application.
  ## 
  let valid = call_594443.validator(path, query, header, formData, body)
  let scheme = call_594443.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594443.url(scheme.get, call_594443.host, call_594443.base,
                         call_594443.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594443, url, valid)

proc call*(call_594444: Call_GetUpdateApplicationResourceLifecycle_594428;
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
  var query_594445 = newJObject()
  add(query_594445, "ApplicationName", newJString(ApplicationName))
  add(query_594445, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  add(query_594445, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  add(query_594445, "Action", newJString(Action))
  add(query_594445, "Version", newJString(Version))
  result = call_594444.call(nil, query_594445, nil, nil, nil)

var getUpdateApplicationResourceLifecycle* = Call_GetUpdateApplicationResourceLifecycle_594428(
    name: "getUpdateApplicationResourceLifecycle", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationResourceLifecycle",
    validator: validate_GetUpdateApplicationResourceLifecycle_594429, base: "/",
    url: url_GetUpdateApplicationResourceLifecycle_594430,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateApplicationVersion_594483 = ref object of OpenApiRestCall_592365
proc url_PostUpdateApplicationVersion_594485(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateApplicationVersion_594484(path: JsonNode; query: JsonNode;
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
  var valid_594486 = query.getOrDefault("Action")
  valid_594486 = validateParameter(valid_594486, JString, required = true, default = newJString(
      "UpdateApplicationVersion"))
  if valid_594486 != nil:
    section.add "Action", valid_594486
  var valid_594487 = query.getOrDefault("Version")
  valid_594487 = validateParameter(valid_594487, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594487 != nil:
    section.add "Version", valid_594487
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
  var valid_594488 = header.getOrDefault("X-Amz-Signature")
  valid_594488 = validateParameter(valid_594488, JString, required = false,
                                 default = nil)
  if valid_594488 != nil:
    section.add "X-Amz-Signature", valid_594488
  var valid_594489 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594489 = validateParameter(valid_594489, JString, required = false,
                                 default = nil)
  if valid_594489 != nil:
    section.add "X-Amz-Content-Sha256", valid_594489
  var valid_594490 = header.getOrDefault("X-Amz-Date")
  valid_594490 = validateParameter(valid_594490, JString, required = false,
                                 default = nil)
  if valid_594490 != nil:
    section.add "X-Amz-Date", valid_594490
  var valid_594491 = header.getOrDefault("X-Amz-Credential")
  valid_594491 = validateParameter(valid_594491, JString, required = false,
                                 default = nil)
  if valid_594491 != nil:
    section.add "X-Amz-Credential", valid_594491
  var valid_594492 = header.getOrDefault("X-Amz-Security-Token")
  valid_594492 = validateParameter(valid_594492, JString, required = false,
                                 default = nil)
  if valid_594492 != nil:
    section.add "X-Amz-Security-Token", valid_594492
  var valid_594493 = header.getOrDefault("X-Amz-Algorithm")
  valid_594493 = validateParameter(valid_594493, JString, required = false,
                                 default = nil)
  if valid_594493 != nil:
    section.add "X-Amz-Algorithm", valid_594493
  var valid_594494 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594494 = validateParameter(valid_594494, JString, required = false,
                                 default = nil)
  if valid_594494 != nil:
    section.add "X-Amz-SignedHeaders", valid_594494
  result.add "header", section
  ## parameters in `formData` object:
  ##   Description: JString
  ##              : A new description for this version.
  ##   VersionLabel: JString (required)
  ##               : <p>The name of the version to update.</p> <p>If no application version is found with this label, <code>UpdateApplication</code> returns an <code>InvalidParameterValue</code> error. </p>
  ##   ApplicationName: JString (required)
  ##                  : <p>The name of the application associated with this version.</p> <p> If no application is found with this name, <code>UpdateApplication</code> returns an <code>InvalidParameterValue</code> error.</p>
  section = newJObject()
  var valid_594495 = formData.getOrDefault("Description")
  valid_594495 = validateParameter(valid_594495, JString, required = false,
                                 default = nil)
  if valid_594495 != nil:
    section.add "Description", valid_594495
  assert formData != nil,
        "formData argument is necessary due to required `VersionLabel` field"
  var valid_594496 = formData.getOrDefault("VersionLabel")
  valid_594496 = validateParameter(valid_594496, JString, required = true,
                                 default = nil)
  if valid_594496 != nil:
    section.add "VersionLabel", valid_594496
  var valid_594497 = formData.getOrDefault("ApplicationName")
  valid_594497 = validateParameter(valid_594497, JString, required = true,
                                 default = nil)
  if valid_594497 != nil:
    section.add "ApplicationName", valid_594497
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594498: Call_PostUpdateApplicationVersion_594483; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified application version to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear properties, specify an empty string.</p> </note>
  ## 
  let valid = call_594498.validator(path, query, header, formData, body)
  let scheme = call_594498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594498.url(scheme.get, call_594498.host, call_594498.base,
                         call_594498.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594498, url, valid)

proc call*(call_594499: Call_PostUpdateApplicationVersion_594483;
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
  var query_594500 = newJObject()
  var formData_594501 = newJObject()
  add(formData_594501, "Description", newJString(Description))
  add(formData_594501, "VersionLabel", newJString(VersionLabel))
  add(formData_594501, "ApplicationName", newJString(ApplicationName))
  add(query_594500, "Action", newJString(Action))
  add(query_594500, "Version", newJString(Version))
  result = call_594499.call(nil, query_594500, nil, formData_594501, nil)

var postUpdateApplicationVersion* = Call_PostUpdateApplicationVersion_594483(
    name: "postUpdateApplicationVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationVersion",
    validator: validate_PostUpdateApplicationVersion_594484, base: "/",
    url: url_PostUpdateApplicationVersion_594485,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateApplicationVersion_594465 = ref object of OpenApiRestCall_592365
proc url_GetUpdateApplicationVersion_594467(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateApplicationVersion_594466(path: JsonNode; query: JsonNode;
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
  var valid_594468 = query.getOrDefault("ApplicationName")
  valid_594468 = validateParameter(valid_594468, JString, required = true,
                                 default = nil)
  if valid_594468 != nil:
    section.add "ApplicationName", valid_594468
  var valid_594469 = query.getOrDefault("VersionLabel")
  valid_594469 = validateParameter(valid_594469, JString, required = true,
                                 default = nil)
  if valid_594469 != nil:
    section.add "VersionLabel", valid_594469
  var valid_594470 = query.getOrDefault("Action")
  valid_594470 = validateParameter(valid_594470, JString, required = true, default = newJString(
      "UpdateApplicationVersion"))
  if valid_594470 != nil:
    section.add "Action", valid_594470
  var valid_594471 = query.getOrDefault("Description")
  valid_594471 = validateParameter(valid_594471, JString, required = false,
                                 default = nil)
  if valid_594471 != nil:
    section.add "Description", valid_594471
  var valid_594472 = query.getOrDefault("Version")
  valid_594472 = validateParameter(valid_594472, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594472 != nil:
    section.add "Version", valid_594472
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
  var valid_594473 = header.getOrDefault("X-Amz-Signature")
  valid_594473 = validateParameter(valid_594473, JString, required = false,
                                 default = nil)
  if valid_594473 != nil:
    section.add "X-Amz-Signature", valid_594473
  var valid_594474 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594474 = validateParameter(valid_594474, JString, required = false,
                                 default = nil)
  if valid_594474 != nil:
    section.add "X-Amz-Content-Sha256", valid_594474
  var valid_594475 = header.getOrDefault("X-Amz-Date")
  valid_594475 = validateParameter(valid_594475, JString, required = false,
                                 default = nil)
  if valid_594475 != nil:
    section.add "X-Amz-Date", valid_594475
  var valid_594476 = header.getOrDefault("X-Amz-Credential")
  valid_594476 = validateParameter(valid_594476, JString, required = false,
                                 default = nil)
  if valid_594476 != nil:
    section.add "X-Amz-Credential", valid_594476
  var valid_594477 = header.getOrDefault("X-Amz-Security-Token")
  valid_594477 = validateParameter(valid_594477, JString, required = false,
                                 default = nil)
  if valid_594477 != nil:
    section.add "X-Amz-Security-Token", valid_594477
  var valid_594478 = header.getOrDefault("X-Amz-Algorithm")
  valid_594478 = validateParameter(valid_594478, JString, required = false,
                                 default = nil)
  if valid_594478 != nil:
    section.add "X-Amz-Algorithm", valid_594478
  var valid_594479 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594479 = validateParameter(valid_594479, JString, required = false,
                                 default = nil)
  if valid_594479 != nil:
    section.add "X-Amz-SignedHeaders", valid_594479
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594480: Call_GetUpdateApplicationVersion_594465; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified application version to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear properties, specify an empty string.</p> </note>
  ## 
  let valid = call_594480.validator(path, query, header, formData, body)
  let scheme = call_594480.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594480.url(scheme.get, call_594480.host, call_594480.base,
                         call_594480.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594480, url, valid)

proc call*(call_594481: Call_GetUpdateApplicationVersion_594465;
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
  var query_594482 = newJObject()
  add(query_594482, "ApplicationName", newJString(ApplicationName))
  add(query_594482, "VersionLabel", newJString(VersionLabel))
  add(query_594482, "Action", newJString(Action))
  add(query_594482, "Description", newJString(Description))
  add(query_594482, "Version", newJString(Version))
  result = call_594481.call(nil, query_594482, nil, nil, nil)

var getUpdateApplicationVersion* = Call_GetUpdateApplicationVersion_594465(
    name: "getUpdateApplicationVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationVersion",
    validator: validate_GetUpdateApplicationVersion_594466, base: "/",
    url: url_GetUpdateApplicationVersion_594467,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateConfigurationTemplate_594522 = ref object of OpenApiRestCall_592365
proc url_PostUpdateConfigurationTemplate_594524(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateConfigurationTemplate_594523(path: JsonNode;
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
  var valid_594525 = query.getOrDefault("Action")
  valid_594525 = validateParameter(valid_594525, JString, required = true, default = newJString(
      "UpdateConfigurationTemplate"))
  if valid_594525 != nil:
    section.add "Action", valid_594525
  var valid_594526 = query.getOrDefault("Version")
  valid_594526 = validateParameter(valid_594526, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594526 != nil:
    section.add "Version", valid_594526
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
  var valid_594527 = header.getOrDefault("X-Amz-Signature")
  valid_594527 = validateParameter(valid_594527, JString, required = false,
                                 default = nil)
  if valid_594527 != nil:
    section.add "X-Amz-Signature", valid_594527
  var valid_594528 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594528 = validateParameter(valid_594528, JString, required = false,
                                 default = nil)
  if valid_594528 != nil:
    section.add "X-Amz-Content-Sha256", valid_594528
  var valid_594529 = header.getOrDefault("X-Amz-Date")
  valid_594529 = validateParameter(valid_594529, JString, required = false,
                                 default = nil)
  if valid_594529 != nil:
    section.add "X-Amz-Date", valid_594529
  var valid_594530 = header.getOrDefault("X-Amz-Credential")
  valid_594530 = validateParameter(valid_594530, JString, required = false,
                                 default = nil)
  if valid_594530 != nil:
    section.add "X-Amz-Credential", valid_594530
  var valid_594531 = header.getOrDefault("X-Amz-Security-Token")
  valid_594531 = validateParameter(valid_594531, JString, required = false,
                                 default = nil)
  if valid_594531 != nil:
    section.add "X-Amz-Security-Token", valid_594531
  var valid_594532 = header.getOrDefault("X-Amz-Algorithm")
  valid_594532 = validateParameter(valid_594532, JString, required = false,
                                 default = nil)
  if valid_594532 != nil:
    section.add "X-Amz-Algorithm", valid_594532
  var valid_594533 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594533 = validateParameter(valid_594533, JString, required = false,
                                 default = nil)
  if valid_594533 != nil:
    section.add "X-Amz-SignedHeaders", valid_594533
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
  var valid_594534 = formData.getOrDefault("Description")
  valid_594534 = validateParameter(valid_594534, JString, required = false,
                                 default = nil)
  if valid_594534 != nil:
    section.add "Description", valid_594534
  assert formData != nil,
        "formData argument is necessary due to required `TemplateName` field"
  var valid_594535 = formData.getOrDefault("TemplateName")
  valid_594535 = validateParameter(valid_594535, JString, required = true,
                                 default = nil)
  if valid_594535 != nil:
    section.add "TemplateName", valid_594535
  var valid_594536 = formData.getOrDefault("OptionsToRemove")
  valid_594536 = validateParameter(valid_594536, JArray, required = false,
                                 default = nil)
  if valid_594536 != nil:
    section.add "OptionsToRemove", valid_594536
  var valid_594537 = formData.getOrDefault("OptionSettings")
  valid_594537 = validateParameter(valid_594537, JArray, required = false,
                                 default = nil)
  if valid_594537 != nil:
    section.add "OptionSettings", valid_594537
  var valid_594538 = formData.getOrDefault("ApplicationName")
  valid_594538 = validateParameter(valid_594538, JString, required = true,
                                 default = nil)
  if valid_594538 != nil:
    section.add "ApplicationName", valid_594538
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594539: Call_PostUpdateConfigurationTemplate_594522;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Updates the specified configuration template to have the specified properties or configuration option values.</p> <note> <p>If a property (for example, <code>ApplicationName</code>) is not provided, its value remains unchanged. To clear such properties, specify an empty string.</p> </note> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> </ul>
  ## 
  let valid = call_594539.validator(path, query, header, formData, body)
  let scheme = call_594539.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594539.url(scheme.get, call_594539.host, call_594539.base,
                         call_594539.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594539, url, valid)

proc call*(call_594540: Call_PostUpdateConfigurationTemplate_594522;
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
  var query_594541 = newJObject()
  var formData_594542 = newJObject()
  add(formData_594542, "Description", newJString(Description))
  add(formData_594542, "TemplateName", newJString(TemplateName))
  if OptionsToRemove != nil:
    formData_594542.add "OptionsToRemove", OptionsToRemove
  if OptionSettings != nil:
    formData_594542.add "OptionSettings", OptionSettings
  add(formData_594542, "ApplicationName", newJString(ApplicationName))
  add(query_594541, "Action", newJString(Action))
  add(query_594541, "Version", newJString(Version))
  result = call_594540.call(nil, query_594541, nil, formData_594542, nil)

var postUpdateConfigurationTemplate* = Call_PostUpdateConfigurationTemplate_594522(
    name: "postUpdateConfigurationTemplate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateConfigurationTemplate",
    validator: validate_PostUpdateConfigurationTemplate_594523, base: "/",
    url: url_PostUpdateConfigurationTemplate_594524,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateConfigurationTemplate_594502 = ref object of OpenApiRestCall_592365
proc url_GetUpdateConfigurationTemplate_594504(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateConfigurationTemplate_594503(path: JsonNode;
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
  var valid_594505 = query.getOrDefault("ApplicationName")
  valid_594505 = validateParameter(valid_594505, JString, required = true,
                                 default = nil)
  if valid_594505 != nil:
    section.add "ApplicationName", valid_594505
  var valid_594506 = query.getOrDefault("OptionSettings")
  valid_594506 = validateParameter(valid_594506, JArray, required = false,
                                 default = nil)
  if valid_594506 != nil:
    section.add "OptionSettings", valid_594506
  var valid_594507 = query.getOrDefault("Action")
  valid_594507 = validateParameter(valid_594507, JString, required = true, default = newJString(
      "UpdateConfigurationTemplate"))
  if valid_594507 != nil:
    section.add "Action", valid_594507
  var valid_594508 = query.getOrDefault("Description")
  valid_594508 = validateParameter(valid_594508, JString, required = false,
                                 default = nil)
  if valid_594508 != nil:
    section.add "Description", valid_594508
  var valid_594509 = query.getOrDefault("OptionsToRemove")
  valid_594509 = validateParameter(valid_594509, JArray, required = false,
                                 default = nil)
  if valid_594509 != nil:
    section.add "OptionsToRemove", valid_594509
  var valid_594510 = query.getOrDefault("Version")
  valid_594510 = validateParameter(valid_594510, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594510 != nil:
    section.add "Version", valid_594510
  var valid_594511 = query.getOrDefault("TemplateName")
  valid_594511 = validateParameter(valid_594511, JString, required = true,
                                 default = nil)
  if valid_594511 != nil:
    section.add "TemplateName", valid_594511
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
  var valid_594512 = header.getOrDefault("X-Amz-Signature")
  valid_594512 = validateParameter(valid_594512, JString, required = false,
                                 default = nil)
  if valid_594512 != nil:
    section.add "X-Amz-Signature", valid_594512
  var valid_594513 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594513 = validateParameter(valid_594513, JString, required = false,
                                 default = nil)
  if valid_594513 != nil:
    section.add "X-Amz-Content-Sha256", valid_594513
  var valid_594514 = header.getOrDefault("X-Amz-Date")
  valid_594514 = validateParameter(valid_594514, JString, required = false,
                                 default = nil)
  if valid_594514 != nil:
    section.add "X-Amz-Date", valid_594514
  var valid_594515 = header.getOrDefault("X-Amz-Credential")
  valid_594515 = validateParameter(valid_594515, JString, required = false,
                                 default = nil)
  if valid_594515 != nil:
    section.add "X-Amz-Credential", valid_594515
  var valid_594516 = header.getOrDefault("X-Amz-Security-Token")
  valid_594516 = validateParameter(valid_594516, JString, required = false,
                                 default = nil)
  if valid_594516 != nil:
    section.add "X-Amz-Security-Token", valid_594516
  var valid_594517 = header.getOrDefault("X-Amz-Algorithm")
  valid_594517 = validateParameter(valid_594517, JString, required = false,
                                 default = nil)
  if valid_594517 != nil:
    section.add "X-Amz-Algorithm", valid_594517
  var valid_594518 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594518 = validateParameter(valid_594518, JString, required = false,
                                 default = nil)
  if valid_594518 != nil:
    section.add "X-Amz-SignedHeaders", valid_594518
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594519: Call_GetUpdateConfigurationTemplate_594502; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified configuration template to have the specified properties or configuration option values.</p> <note> <p>If a property (for example, <code>ApplicationName</code>) is not provided, its value remains unchanged. To clear such properties, specify an empty string.</p> </note> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> </ul>
  ## 
  let valid = call_594519.validator(path, query, header, formData, body)
  let scheme = call_594519.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594519.url(scheme.get, call_594519.host, call_594519.base,
                         call_594519.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594519, url, valid)

proc call*(call_594520: Call_GetUpdateConfigurationTemplate_594502;
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
  var query_594521 = newJObject()
  add(query_594521, "ApplicationName", newJString(ApplicationName))
  if OptionSettings != nil:
    query_594521.add "OptionSettings", OptionSettings
  add(query_594521, "Action", newJString(Action))
  add(query_594521, "Description", newJString(Description))
  if OptionsToRemove != nil:
    query_594521.add "OptionsToRemove", OptionsToRemove
  add(query_594521, "Version", newJString(Version))
  add(query_594521, "TemplateName", newJString(TemplateName))
  result = call_594520.call(nil, query_594521, nil, nil, nil)

var getUpdateConfigurationTemplate* = Call_GetUpdateConfigurationTemplate_594502(
    name: "getUpdateConfigurationTemplate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateConfigurationTemplate",
    validator: validate_GetUpdateConfigurationTemplate_594503, base: "/",
    url: url_GetUpdateConfigurationTemplate_594504,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateEnvironment_594572 = ref object of OpenApiRestCall_592365
proc url_PostUpdateEnvironment_594574(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateEnvironment_594573(path: JsonNode; query: JsonNode;
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
  var valid_594575 = query.getOrDefault("Action")
  valid_594575 = validateParameter(valid_594575, JString, required = true,
                                 default = newJString("UpdateEnvironment"))
  if valid_594575 != nil:
    section.add "Action", valid_594575
  var valid_594576 = query.getOrDefault("Version")
  valid_594576 = validateParameter(valid_594576, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594576 != nil:
    section.add "Version", valid_594576
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
  var valid_594577 = header.getOrDefault("X-Amz-Signature")
  valid_594577 = validateParameter(valid_594577, JString, required = false,
                                 default = nil)
  if valid_594577 != nil:
    section.add "X-Amz-Signature", valid_594577
  var valid_594578 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594578 = validateParameter(valid_594578, JString, required = false,
                                 default = nil)
  if valid_594578 != nil:
    section.add "X-Amz-Content-Sha256", valid_594578
  var valid_594579 = header.getOrDefault("X-Amz-Date")
  valid_594579 = validateParameter(valid_594579, JString, required = false,
                                 default = nil)
  if valid_594579 != nil:
    section.add "X-Amz-Date", valid_594579
  var valid_594580 = header.getOrDefault("X-Amz-Credential")
  valid_594580 = validateParameter(valid_594580, JString, required = false,
                                 default = nil)
  if valid_594580 != nil:
    section.add "X-Amz-Credential", valid_594580
  var valid_594581 = header.getOrDefault("X-Amz-Security-Token")
  valid_594581 = validateParameter(valid_594581, JString, required = false,
                                 default = nil)
  if valid_594581 != nil:
    section.add "X-Amz-Security-Token", valid_594581
  var valid_594582 = header.getOrDefault("X-Amz-Algorithm")
  valid_594582 = validateParameter(valid_594582, JString, required = false,
                                 default = nil)
  if valid_594582 != nil:
    section.add "X-Amz-Algorithm", valid_594582
  var valid_594583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594583 = validateParameter(valid_594583, JString, required = false,
                                 default = nil)
  if valid_594583 != nil:
    section.add "X-Amz-SignedHeaders", valid_594583
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
  var valid_594584 = formData.getOrDefault("Description")
  valid_594584 = validateParameter(valid_594584, JString, required = false,
                                 default = nil)
  if valid_594584 != nil:
    section.add "Description", valid_594584
  var valid_594585 = formData.getOrDefault("Tier.Type")
  valid_594585 = validateParameter(valid_594585, JString, required = false,
                                 default = nil)
  if valid_594585 != nil:
    section.add "Tier.Type", valid_594585
  var valid_594586 = formData.getOrDefault("EnvironmentName")
  valid_594586 = validateParameter(valid_594586, JString, required = false,
                                 default = nil)
  if valid_594586 != nil:
    section.add "EnvironmentName", valid_594586
  var valid_594587 = formData.getOrDefault("VersionLabel")
  valid_594587 = validateParameter(valid_594587, JString, required = false,
                                 default = nil)
  if valid_594587 != nil:
    section.add "VersionLabel", valid_594587
  var valid_594588 = formData.getOrDefault("TemplateName")
  valid_594588 = validateParameter(valid_594588, JString, required = false,
                                 default = nil)
  if valid_594588 != nil:
    section.add "TemplateName", valid_594588
  var valid_594589 = formData.getOrDefault("OptionsToRemove")
  valid_594589 = validateParameter(valid_594589, JArray, required = false,
                                 default = nil)
  if valid_594589 != nil:
    section.add "OptionsToRemove", valid_594589
  var valid_594590 = formData.getOrDefault("OptionSettings")
  valid_594590 = validateParameter(valid_594590, JArray, required = false,
                                 default = nil)
  if valid_594590 != nil:
    section.add "OptionSettings", valid_594590
  var valid_594591 = formData.getOrDefault("GroupName")
  valid_594591 = validateParameter(valid_594591, JString, required = false,
                                 default = nil)
  if valid_594591 != nil:
    section.add "GroupName", valid_594591
  var valid_594592 = formData.getOrDefault("ApplicationName")
  valid_594592 = validateParameter(valid_594592, JString, required = false,
                                 default = nil)
  if valid_594592 != nil:
    section.add "ApplicationName", valid_594592
  var valid_594593 = formData.getOrDefault("Tier.Name")
  valid_594593 = validateParameter(valid_594593, JString, required = false,
                                 default = nil)
  if valid_594593 != nil:
    section.add "Tier.Name", valid_594593
  var valid_594594 = formData.getOrDefault("Tier.Version")
  valid_594594 = validateParameter(valid_594594, JString, required = false,
                                 default = nil)
  if valid_594594 != nil:
    section.add "Tier.Version", valid_594594
  var valid_594595 = formData.getOrDefault("EnvironmentId")
  valid_594595 = validateParameter(valid_594595, JString, required = false,
                                 default = nil)
  if valid_594595 != nil:
    section.add "EnvironmentId", valid_594595
  var valid_594596 = formData.getOrDefault("SolutionStackName")
  valid_594596 = validateParameter(valid_594596, JString, required = false,
                                 default = nil)
  if valid_594596 != nil:
    section.add "SolutionStackName", valid_594596
  var valid_594597 = formData.getOrDefault("PlatformArn")
  valid_594597 = validateParameter(valid_594597, JString, required = false,
                                 default = nil)
  if valid_594597 != nil:
    section.add "PlatformArn", valid_594597
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594598: Call_PostUpdateEnvironment_594572; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the environment description, deploys a new application version, updates the configuration settings to an entirely new configuration template, or updates select configuration option values in the running environment.</p> <p> Attempting to update both the release and configuration is not allowed and AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. </p> <p> When updating the configuration settings to a new template or individual settings, a draft configuration is created and <a>DescribeConfigurationSettings</a> for this environment returns two setting descriptions with different <code>DeploymentStatus</code> values. </p>
  ## 
  let valid = call_594598.validator(path, query, header, formData, body)
  let scheme = call_594598.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594598.url(scheme.get, call_594598.host, call_594598.base,
                         call_594598.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594598, url, valid)

proc call*(call_594599: Call_PostUpdateEnvironment_594572;
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
  var query_594600 = newJObject()
  var formData_594601 = newJObject()
  add(formData_594601, "Description", newJString(Description))
  add(formData_594601, "Tier.Type", newJString(TierType))
  add(formData_594601, "EnvironmentName", newJString(EnvironmentName))
  add(formData_594601, "VersionLabel", newJString(VersionLabel))
  add(formData_594601, "TemplateName", newJString(TemplateName))
  if OptionsToRemove != nil:
    formData_594601.add "OptionsToRemove", OptionsToRemove
  if OptionSettings != nil:
    formData_594601.add "OptionSettings", OptionSettings
  add(formData_594601, "GroupName", newJString(GroupName))
  add(formData_594601, "ApplicationName", newJString(ApplicationName))
  add(formData_594601, "Tier.Name", newJString(TierName))
  add(formData_594601, "Tier.Version", newJString(TierVersion))
  add(query_594600, "Action", newJString(Action))
  add(formData_594601, "EnvironmentId", newJString(EnvironmentId))
  add(formData_594601, "SolutionStackName", newJString(SolutionStackName))
  add(query_594600, "Version", newJString(Version))
  add(formData_594601, "PlatformArn", newJString(PlatformArn))
  result = call_594599.call(nil, query_594600, nil, formData_594601, nil)

var postUpdateEnvironment* = Call_PostUpdateEnvironment_594572(
    name: "postUpdateEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateEnvironment",
    validator: validate_PostUpdateEnvironment_594573, base: "/",
    url: url_PostUpdateEnvironment_594574, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateEnvironment_594543 = ref object of OpenApiRestCall_592365
proc url_GetUpdateEnvironment_594545(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateEnvironment_594544(path: JsonNode; query: JsonNode;
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
  var valid_594546 = query.getOrDefault("ApplicationName")
  valid_594546 = validateParameter(valid_594546, JString, required = false,
                                 default = nil)
  if valid_594546 != nil:
    section.add "ApplicationName", valid_594546
  var valid_594547 = query.getOrDefault("GroupName")
  valid_594547 = validateParameter(valid_594547, JString, required = false,
                                 default = nil)
  if valid_594547 != nil:
    section.add "GroupName", valid_594547
  var valid_594548 = query.getOrDefault("VersionLabel")
  valid_594548 = validateParameter(valid_594548, JString, required = false,
                                 default = nil)
  if valid_594548 != nil:
    section.add "VersionLabel", valid_594548
  var valid_594549 = query.getOrDefault("OptionSettings")
  valid_594549 = validateParameter(valid_594549, JArray, required = false,
                                 default = nil)
  if valid_594549 != nil:
    section.add "OptionSettings", valid_594549
  var valid_594550 = query.getOrDefault("SolutionStackName")
  valid_594550 = validateParameter(valid_594550, JString, required = false,
                                 default = nil)
  if valid_594550 != nil:
    section.add "SolutionStackName", valid_594550
  var valid_594551 = query.getOrDefault("Tier.Name")
  valid_594551 = validateParameter(valid_594551, JString, required = false,
                                 default = nil)
  if valid_594551 != nil:
    section.add "Tier.Name", valid_594551
  var valid_594552 = query.getOrDefault("EnvironmentName")
  valid_594552 = validateParameter(valid_594552, JString, required = false,
                                 default = nil)
  if valid_594552 != nil:
    section.add "EnvironmentName", valid_594552
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_594553 = query.getOrDefault("Action")
  valid_594553 = validateParameter(valid_594553, JString, required = true,
                                 default = newJString("UpdateEnvironment"))
  if valid_594553 != nil:
    section.add "Action", valid_594553
  var valid_594554 = query.getOrDefault("Description")
  valid_594554 = validateParameter(valid_594554, JString, required = false,
                                 default = nil)
  if valid_594554 != nil:
    section.add "Description", valid_594554
  var valid_594555 = query.getOrDefault("PlatformArn")
  valid_594555 = validateParameter(valid_594555, JString, required = false,
                                 default = nil)
  if valid_594555 != nil:
    section.add "PlatformArn", valid_594555
  var valid_594556 = query.getOrDefault("OptionsToRemove")
  valid_594556 = validateParameter(valid_594556, JArray, required = false,
                                 default = nil)
  if valid_594556 != nil:
    section.add "OptionsToRemove", valid_594556
  var valid_594557 = query.getOrDefault("Version")
  valid_594557 = validateParameter(valid_594557, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594557 != nil:
    section.add "Version", valid_594557
  var valid_594558 = query.getOrDefault("TemplateName")
  valid_594558 = validateParameter(valid_594558, JString, required = false,
                                 default = nil)
  if valid_594558 != nil:
    section.add "TemplateName", valid_594558
  var valid_594559 = query.getOrDefault("Tier.Version")
  valid_594559 = validateParameter(valid_594559, JString, required = false,
                                 default = nil)
  if valid_594559 != nil:
    section.add "Tier.Version", valid_594559
  var valid_594560 = query.getOrDefault("EnvironmentId")
  valid_594560 = validateParameter(valid_594560, JString, required = false,
                                 default = nil)
  if valid_594560 != nil:
    section.add "EnvironmentId", valid_594560
  var valid_594561 = query.getOrDefault("Tier.Type")
  valid_594561 = validateParameter(valid_594561, JString, required = false,
                                 default = nil)
  if valid_594561 != nil:
    section.add "Tier.Type", valid_594561
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
  var valid_594562 = header.getOrDefault("X-Amz-Signature")
  valid_594562 = validateParameter(valid_594562, JString, required = false,
                                 default = nil)
  if valid_594562 != nil:
    section.add "X-Amz-Signature", valid_594562
  var valid_594563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594563 = validateParameter(valid_594563, JString, required = false,
                                 default = nil)
  if valid_594563 != nil:
    section.add "X-Amz-Content-Sha256", valid_594563
  var valid_594564 = header.getOrDefault("X-Amz-Date")
  valid_594564 = validateParameter(valid_594564, JString, required = false,
                                 default = nil)
  if valid_594564 != nil:
    section.add "X-Amz-Date", valid_594564
  var valid_594565 = header.getOrDefault("X-Amz-Credential")
  valid_594565 = validateParameter(valid_594565, JString, required = false,
                                 default = nil)
  if valid_594565 != nil:
    section.add "X-Amz-Credential", valid_594565
  var valid_594566 = header.getOrDefault("X-Amz-Security-Token")
  valid_594566 = validateParameter(valid_594566, JString, required = false,
                                 default = nil)
  if valid_594566 != nil:
    section.add "X-Amz-Security-Token", valid_594566
  var valid_594567 = header.getOrDefault("X-Amz-Algorithm")
  valid_594567 = validateParameter(valid_594567, JString, required = false,
                                 default = nil)
  if valid_594567 != nil:
    section.add "X-Amz-Algorithm", valid_594567
  var valid_594568 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594568 = validateParameter(valid_594568, JString, required = false,
                                 default = nil)
  if valid_594568 != nil:
    section.add "X-Amz-SignedHeaders", valid_594568
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594569: Call_GetUpdateEnvironment_594543; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the environment description, deploys a new application version, updates the configuration settings to an entirely new configuration template, or updates select configuration option values in the running environment.</p> <p> Attempting to update both the release and configuration is not allowed and AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. </p> <p> When updating the configuration settings to a new template or individual settings, a draft configuration is created and <a>DescribeConfigurationSettings</a> for this environment returns two setting descriptions with different <code>DeploymentStatus</code> values. </p>
  ## 
  let valid = call_594569.validator(path, query, header, formData, body)
  let scheme = call_594569.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594569.url(scheme.get, call_594569.host, call_594569.base,
                         call_594569.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594569, url, valid)

proc call*(call_594570: Call_GetUpdateEnvironment_594543;
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
  var query_594571 = newJObject()
  add(query_594571, "ApplicationName", newJString(ApplicationName))
  add(query_594571, "GroupName", newJString(GroupName))
  add(query_594571, "VersionLabel", newJString(VersionLabel))
  if OptionSettings != nil:
    query_594571.add "OptionSettings", OptionSettings
  add(query_594571, "SolutionStackName", newJString(SolutionStackName))
  add(query_594571, "Tier.Name", newJString(TierName))
  add(query_594571, "EnvironmentName", newJString(EnvironmentName))
  add(query_594571, "Action", newJString(Action))
  add(query_594571, "Description", newJString(Description))
  add(query_594571, "PlatformArn", newJString(PlatformArn))
  if OptionsToRemove != nil:
    query_594571.add "OptionsToRemove", OptionsToRemove
  add(query_594571, "Version", newJString(Version))
  add(query_594571, "TemplateName", newJString(TemplateName))
  add(query_594571, "Tier.Version", newJString(TierVersion))
  add(query_594571, "EnvironmentId", newJString(EnvironmentId))
  add(query_594571, "Tier.Type", newJString(TierType))
  result = call_594570.call(nil, query_594571, nil, nil, nil)

var getUpdateEnvironment* = Call_GetUpdateEnvironment_594543(
    name: "getUpdateEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateEnvironment",
    validator: validate_GetUpdateEnvironment_594544, base: "/",
    url: url_GetUpdateEnvironment_594545, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateTagsForResource_594620 = ref object of OpenApiRestCall_592365
proc url_PostUpdateTagsForResource_594622(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostUpdateTagsForResource_594621(path: JsonNode; query: JsonNode;
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
  var valid_594623 = query.getOrDefault("Action")
  valid_594623 = validateParameter(valid_594623, JString, required = true,
                                 default = newJString("UpdateTagsForResource"))
  if valid_594623 != nil:
    section.add "Action", valid_594623
  var valid_594624 = query.getOrDefault("Version")
  valid_594624 = validateParameter(valid_594624, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594624 != nil:
    section.add "Version", valid_594624
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
  var valid_594625 = header.getOrDefault("X-Amz-Signature")
  valid_594625 = validateParameter(valid_594625, JString, required = false,
                                 default = nil)
  if valid_594625 != nil:
    section.add "X-Amz-Signature", valid_594625
  var valid_594626 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594626 = validateParameter(valid_594626, JString, required = false,
                                 default = nil)
  if valid_594626 != nil:
    section.add "X-Amz-Content-Sha256", valid_594626
  var valid_594627 = header.getOrDefault("X-Amz-Date")
  valid_594627 = validateParameter(valid_594627, JString, required = false,
                                 default = nil)
  if valid_594627 != nil:
    section.add "X-Amz-Date", valid_594627
  var valid_594628 = header.getOrDefault("X-Amz-Credential")
  valid_594628 = validateParameter(valid_594628, JString, required = false,
                                 default = nil)
  if valid_594628 != nil:
    section.add "X-Amz-Credential", valid_594628
  var valid_594629 = header.getOrDefault("X-Amz-Security-Token")
  valid_594629 = validateParameter(valid_594629, JString, required = false,
                                 default = nil)
  if valid_594629 != nil:
    section.add "X-Amz-Security-Token", valid_594629
  var valid_594630 = header.getOrDefault("X-Amz-Algorithm")
  valid_594630 = validateParameter(valid_594630, JString, required = false,
                                 default = nil)
  if valid_594630 != nil:
    section.add "X-Amz-Algorithm", valid_594630
  var valid_594631 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594631 = validateParameter(valid_594631, JString, required = false,
                                 default = nil)
  if valid_594631 != nil:
    section.add "X-Amz-SignedHeaders", valid_594631
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
  var valid_594632 = formData.getOrDefault("ResourceArn")
  valid_594632 = validateParameter(valid_594632, JString, required = true,
                                 default = nil)
  if valid_594632 != nil:
    section.add "ResourceArn", valid_594632
  var valid_594633 = formData.getOrDefault("TagsToAdd")
  valid_594633 = validateParameter(valid_594633, JArray, required = false,
                                 default = nil)
  if valid_594633 != nil:
    section.add "TagsToAdd", valid_594633
  var valid_594634 = formData.getOrDefault("TagsToRemove")
  valid_594634 = validateParameter(valid_594634, JArray, required = false,
                                 default = nil)
  if valid_594634 != nil:
    section.add "TagsToRemove", valid_594634
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594635: Call_PostUpdateTagsForResource_594620; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Update the list of tags applied to an AWS Elastic Beanstalk resource. Two lists can be passed: <code>TagsToAdd</code> for tags to add or update, and <code>TagsToRemove</code>.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p> <p>If you create a custom IAM user policy to control permission to this operation, specify one of the following two virtual actions (or both) instead of the API operation name:</p> <dl> <dt>elasticbeanstalk:AddTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tags to add in the <code>TagsToAdd</code> parameter.</p> </dd> <dt>elasticbeanstalk:RemoveTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tag keys to remove in the <code>TagsToRemove</code> parameter.</p> </dd> </dl> <p>For details about creating a custom user policy, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/AWSHowTo.iam.managed-policies.html#AWSHowTo.iam.policies">Creating a Custom User Policy</a>.</p>
  ## 
  let valid = call_594635.validator(path, query, header, formData, body)
  let scheme = call_594635.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594635.url(scheme.get, call_594635.host, call_594635.base,
                         call_594635.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594635, url, valid)

proc call*(call_594636: Call_PostUpdateTagsForResource_594620; ResourceArn: string;
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
  var query_594637 = newJObject()
  var formData_594638 = newJObject()
  add(formData_594638, "ResourceArn", newJString(ResourceArn))
  add(query_594637, "Action", newJString(Action))
  if TagsToAdd != nil:
    formData_594638.add "TagsToAdd", TagsToAdd
  if TagsToRemove != nil:
    formData_594638.add "TagsToRemove", TagsToRemove
  add(query_594637, "Version", newJString(Version))
  result = call_594636.call(nil, query_594637, nil, formData_594638, nil)

var postUpdateTagsForResource* = Call_PostUpdateTagsForResource_594620(
    name: "postUpdateTagsForResource", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateTagsForResource",
    validator: validate_PostUpdateTagsForResource_594621, base: "/",
    url: url_PostUpdateTagsForResource_594622,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateTagsForResource_594602 = ref object of OpenApiRestCall_592365
proc url_GetUpdateTagsForResource_594604(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetUpdateTagsForResource_594603(path: JsonNode; query: JsonNode;
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
  var valid_594605 = query.getOrDefault("TagsToAdd")
  valid_594605 = validateParameter(valid_594605, JArray, required = false,
                                 default = nil)
  if valid_594605 != nil:
    section.add "TagsToAdd", valid_594605
  var valid_594606 = query.getOrDefault("TagsToRemove")
  valid_594606 = validateParameter(valid_594606, JArray, required = false,
                                 default = nil)
  if valid_594606 != nil:
    section.add "TagsToRemove", valid_594606
  assert query != nil,
        "query argument is necessary due to required `ResourceArn` field"
  var valid_594607 = query.getOrDefault("ResourceArn")
  valid_594607 = validateParameter(valid_594607, JString, required = true,
                                 default = nil)
  if valid_594607 != nil:
    section.add "ResourceArn", valid_594607
  var valid_594608 = query.getOrDefault("Action")
  valid_594608 = validateParameter(valid_594608, JString, required = true,
                                 default = newJString("UpdateTagsForResource"))
  if valid_594608 != nil:
    section.add "Action", valid_594608
  var valid_594609 = query.getOrDefault("Version")
  valid_594609 = validateParameter(valid_594609, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594609 != nil:
    section.add "Version", valid_594609
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
  var valid_594610 = header.getOrDefault("X-Amz-Signature")
  valid_594610 = validateParameter(valid_594610, JString, required = false,
                                 default = nil)
  if valid_594610 != nil:
    section.add "X-Amz-Signature", valid_594610
  var valid_594611 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594611 = validateParameter(valid_594611, JString, required = false,
                                 default = nil)
  if valid_594611 != nil:
    section.add "X-Amz-Content-Sha256", valid_594611
  var valid_594612 = header.getOrDefault("X-Amz-Date")
  valid_594612 = validateParameter(valid_594612, JString, required = false,
                                 default = nil)
  if valid_594612 != nil:
    section.add "X-Amz-Date", valid_594612
  var valid_594613 = header.getOrDefault("X-Amz-Credential")
  valid_594613 = validateParameter(valid_594613, JString, required = false,
                                 default = nil)
  if valid_594613 != nil:
    section.add "X-Amz-Credential", valid_594613
  var valid_594614 = header.getOrDefault("X-Amz-Security-Token")
  valid_594614 = validateParameter(valid_594614, JString, required = false,
                                 default = nil)
  if valid_594614 != nil:
    section.add "X-Amz-Security-Token", valid_594614
  var valid_594615 = header.getOrDefault("X-Amz-Algorithm")
  valid_594615 = validateParameter(valid_594615, JString, required = false,
                                 default = nil)
  if valid_594615 != nil:
    section.add "X-Amz-Algorithm", valid_594615
  var valid_594616 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594616 = validateParameter(valid_594616, JString, required = false,
                                 default = nil)
  if valid_594616 != nil:
    section.add "X-Amz-SignedHeaders", valid_594616
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594617: Call_GetUpdateTagsForResource_594602; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Update the list of tags applied to an AWS Elastic Beanstalk resource. Two lists can be passed: <code>TagsToAdd</code> for tags to add or update, and <code>TagsToRemove</code>.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p> <p>If you create a custom IAM user policy to control permission to this operation, specify one of the following two virtual actions (or both) instead of the API operation name:</p> <dl> <dt>elasticbeanstalk:AddTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tags to add in the <code>TagsToAdd</code> parameter.</p> </dd> <dt>elasticbeanstalk:RemoveTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tag keys to remove in the <code>TagsToRemove</code> parameter.</p> </dd> </dl> <p>For details about creating a custom user policy, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/AWSHowTo.iam.managed-policies.html#AWSHowTo.iam.policies">Creating a Custom User Policy</a>.</p>
  ## 
  let valid = call_594617.validator(path, query, header, formData, body)
  let scheme = call_594617.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594617.url(scheme.get, call_594617.host, call_594617.base,
                         call_594617.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594617, url, valid)

proc call*(call_594618: Call_GetUpdateTagsForResource_594602; ResourceArn: string;
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
  var query_594619 = newJObject()
  if TagsToAdd != nil:
    query_594619.add "TagsToAdd", TagsToAdd
  if TagsToRemove != nil:
    query_594619.add "TagsToRemove", TagsToRemove
  add(query_594619, "ResourceArn", newJString(ResourceArn))
  add(query_594619, "Action", newJString(Action))
  add(query_594619, "Version", newJString(Version))
  result = call_594618.call(nil, query_594619, nil, nil, nil)

var getUpdateTagsForResource* = Call_GetUpdateTagsForResource_594602(
    name: "getUpdateTagsForResource", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateTagsForResource",
    validator: validate_GetUpdateTagsForResource_594603, base: "/",
    url: url_GetUpdateTagsForResource_594604, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostValidateConfigurationSettings_594658 = ref object of OpenApiRestCall_592365
proc url_PostValidateConfigurationSettings_594660(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostValidateConfigurationSettings_594659(path: JsonNode;
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
  var valid_594661 = query.getOrDefault("Action")
  valid_594661 = validateParameter(valid_594661, JString, required = true, default = newJString(
      "ValidateConfigurationSettings"))
  if valid_594661 != nil:
    section.add "Action", valid_594661
  var valid_594662 = query.getOrDefault("Version")
  valid_594662 = validateParameter(valid_594662, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594662 != nil:
    section.add "Version", valid_594662
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
  var valid_594663 = header.getOrDefault("X-Amz-Signature")
  valid_594663 = validateParameter(valid_594663, JString, required = false,
                                 default = nil)
  if valid_594663 != nil:
    section.add "X-Amz-Signature", valid_594663
  var valid_594664 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594664 = validateParameter(valid_594664, JString, required = false,
                                 default = nil)
  if valid_594664 != nil:
    section.add "X-Amz-Content-Sha256", valid_594664
  var valid_594665 = header.getOrDefault("X-Amz-Date")
  valid_594665 = validateParameter(valid_594665, JString, required = false,
                                 default = nil)
  if valid_594665 != nil:
    section.add "X-Amz-Date", valid_594665
  var valid_594666 = header.getOrDefault("X-Amz-Credential")
  valid_594666 = validateParameter(valid_594666, JString, required = false,
                                 default = nil)
  if valid_594666 != nil:
    section.add "X-Amz-Credential", valid_594666
  var valid_594667 = header.getOrDefault("X-Amz-Security-Token")
  valid_594667 = validateParameter(valid_594667, JString, required = false,
                                 default = nil)
  if valid_594667 != nil:
    section.add "X-Amz-Security-Token", valid_594667
  var valid_594668 = header.getOrDefault("X-Amz-Algorithm")
  valid_594668 = validateParameter(valid_594668, JString, required = false,
                                 default = nil)
  if valid_594668 != nil:
    section.add "X-Amz-Algorithm", valid_594668
  var valid_594669 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594669 = validateParameter(valid_594669, JString, required = false,
                                 default = nil)
  if valid_594669 != nil:
    section.add "X-Amz-SignedHeaders", valid_594669
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
  var valid_594670 = formData.getOrDefault("EnvironmentName")
  valid_594670 = validateParameter(valid_594670, JString, required = false,
                                 default = nil)
  if valid_594670 != nil:
    section.add "EnvironmentName", valid_594670
  var valid_594671 = formData.getOrDefault("TemplateName")
  valid_594671 = validateParameter(valid_594671, JString, required = false,
                                 default = nil)
  if valid_594671 != nil:
    section.add "TemplateName", valid_594671
  assert formData != nil,
        "formData argument is necessary due to required `OptionSettings` field"
  var valid_594672 = formData.getOrDefault("OptionSettings")
  valid_594672 = validateParameter(valid_594672, JArray, required = true, default = nil)
  if valid_594672 != nil:
    section.add "OptionSettings", valid_594672
  var valid_594673 = formData.getOrDefault("ApplicationName")
  valid_594673 = validateParameter(valid_594673, JString, required = true,
                                 default = nil)
  if valid_594673 != nil:
    section.add "ApplicationName", valid_594673
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594674: Call_PostValidateConfigurationSettings_594658;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Takes a set of configuration settings and either a configuration template or environment, and determines whether those values are valid.</p> <p>This action returns a list of messages indicating any errors or warnings associated with the selection of option values.</p>
  ## 
  let valid = call_594674.validator(path, query, header, formData, body)
  let scheme = call_594674.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594674.url(scheme.get, call_594674.host, call_594674.base,
                         call_594674.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594674, url, valid)

proc call*(call_594675: Call_PostValidateConfigurationSettings_594658;
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
  var query_594676 = newJObject()
  var formData_594677 = newJObject()
  add(formData_594677, "EnvironmentName", newJString(EnvironmentName))
  add(formData_594677, "TemplateName", newJString(TemplateName))
  if OptionSettings != nil:
    formData_594677.add "OptionSettings", OptionSettings
  add(formData_594677, "ApplicationName", newJString(ApplicationName))
  add(query_594676, "Action", newJString(Action))
  add(query_594676, "Version", newJString(Version))
  result = call_594675.call(nil, query_594676, nil, formData_594677, nil)

var postValidateConfigurationSettings* = Call_PostValidateConfigurationSettings_594658(
    name: "postValidateConfigurationSettings", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ValidateConfigurationSettings",
    validator: validate_PostValidateConfigurationSettings_594659, base: "/",
    url: url_PostValidateConfigurationSettings_594660,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetValidateConfigurationSettings_594639 = ref object of OpenApiRestCall_592365
proc url_GetValidateConfigurationSettings_594641(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetValidateConfigurationSettings_594640(path: JsonNode;
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
  var valid_594642 = query.getOrDefault("ApplicationName")
  valid_594642 = validateParameter(valid_594642, JString, required = true,
                                 default = nil)
  if valid_594642 != nil:
    section.add "ApplicationName", valid_594642
  var valid_594643 = query.getOrDefault("OptionSettings")
  valid_594643 = validateParameter(valid_594643, JArray, required = true, default = nil)
  if valid_594643 != nil:
    section.add "OptionSettings", valid_594643
  var valid_594644 = query.getOrDefault("EnvironmentName")
  valid_594644 = validateParameter(valid_594644, JString, required = false,
                                 default = nil)
  if valid_594644 != nil:
    section.add "EnvironmentName", valid_594644
  var valid_594645 = query.getOrDefault("Action")
  valid_594645 = validateParameter(valid_594645, JString, required = true, default = newJString(
      "ValidateConfigurationSettings"))
  if valid_594645 != nil:
    section.add "Action", valid_594645
  var valid_594646 = query.getOrDefault("Version")
  valid_594646 = validateParameter(valid_594646, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_594646 != nil:
    section.add "Version", valid_594646
  var valid_594647 = query.getOrDefault("TemplateName")
  valid_594647 = validateParameter(valid_594647, JString, required = false,
                                 default = nil)
  if valid_594647 != nil:
    section.add "TemplateName", valid_594647
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
  var valid_594648 = header.getOrDefault("X-Amz-Signature")
  valid_594648 = validateParameter(valid_594648, JString, required = false,
                                 default = nil)
  if valid_594648 != nil:
    section.add "X-Amz-Signature", valid_594648
  var valid_594649 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594649 = validateParameter(valid_594649, JString, required = false,
                                 default = nil)
  if valid_594649 != nil:
    section.add "X-Amz-Content-Sha256", valid_594649
  var valid_594650 = header.getOrDefault("X-Amz-Date")
  valid_594650 = validateParameter(valid_594650, JString, required = false,
                                 default = nil)
  if valid_594650 != nil:
    section.add "X-Amz-Date", valid_594650
  var valid_594651 = header.getOrDefault("X-Amz-Credential")
  valid_594651 = validateParameter(valid_594651, JString, required = false,
                                 default = nil)
  if valid_594651 != nil:
    section.add "X-Amz-Credential", valid_594651
  var valid_594652 = header.getOrDefault("X-Amz-Security-Token")
  valid_594652 = validateParameter(valid_594652, JString, required = false,
                                 default = nil)
  if valid_594652 != nil:
    section.add "X-Amz-Security-Token", valid_594652
  var valid_594653 = header.getOrDefault("X-Amz-Algorithm")
  valid_594653 = validateParameter(valid_594653, JString, required = false,
                                 default = nil)
  if valid_594653 != nil:
    section.add "X-Amz-Algorithm", valid_594653
  var valid_594654 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594654 = validateParameter(valid_594654, JString, required = false,
                                 default = nil)
  if valid_594654 != nil:
    section.add "X-Amz-SignedHeaders", valid_594654
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594655: Call_GetValidateConfigurationSettings_594639;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Takes a set of configuration settings and either a configuration template or environment, and determines whether those values are valid.</p> <p>This action returns a list of messages indicating any errors or warnings associated with the selection of option values.</p>
  ## 
  let valid = call_594655.validator(path, query, header, formData, body)
  let scheme = call_594655.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594655.url(scheme.get, call_594655.host, call_594655.base,
                         call_594655.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594655, url, valid)

proc call*(call_594656: Call_GetValidateConfigurationSettings_594639;
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
  var query_594657 = newJObject()
  add(query_594657, "ApplicationName", newJString(ApplicationName))
  if OptionSettings != nil:
    query_594657.add "OptionSettings", OptionSettings
  add(query_594657, "EnvironmentName", newJString(EnvironmentName))
  add(query_594657, "Action", newJString(Action))
  add(query_594657, "Version", newJString(Version))
  add(query_594657, "TemplateName", newJString(TemplateName))
  result = call_594656.call(nil, query_594657, nil, nil, nil)

var getValidateConfigurationSettings* = Call_GetValidateConfigurationSettings_594639(
    name: "getValidateConfigurationSettings", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ValidateConfigurationSettings",
    validator: validate_GetValidateConfigurationSettings_594640, base: "/",
    url: url_GetValidateConfigurationSettings_594641,
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

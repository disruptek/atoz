
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

  OpenApiRestCall_601390 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601390](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601390): Option[Scheme] {.used.} =
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
  Call_PostAbortEnvironmentUpdate_602000 = ref object of OpenApiRestCall_601390
proc url_PostAbortEnvironmentUpdate_602002(protocol: Scheme; host: string;
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

proc validate_PostAbortEnvironmentUpdate_602001(path: JsonNode; query: JsonNode;
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
  var valid_602003 = query.getOrDefault("Action")
  valid_602003 = validateParameter(valid_602003, JString, required = true,
                                 default = newJString("AbortEnvironmentUpdate"))
  if valid_602003 != nil:
    section.add "Action", valid_602003
  var valid_602004 = query.getOrDefault("Version")
  valid_602004 = validateParameter(valid_602004, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602004 != nil:
    section.add "Version", valid_602004
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
  var valid_602005 = header.getOrDefault("X-Amz-Signature")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Signature", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-Content-Sha256", valid_602006
  var valid_602007 = header.getOrDefault("X-Amz-Date")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "X-Amz-Date", valid_602007
  var valid_602008 = header.getOrDefault("X-Amz-Credential")
  valid_602008 = validateParameter(valid_602008, JString, required = false,
                                 default = nil)
  if valid_602008 != nil:
    section.add "X-Amz-Credential", valid_602008
  var valid_602009 = header.getOrDefault("X-Amz-Security-Token")
  valid_602009 = validateParameter(valid_602009, JString, required = false,
                                 default = nil)
  if valid_602009 != nil:
    section.add "X-Amz-Security-Token", valid_602009
  var valid_602010 = header.getOrDefault("X-Amz-Algorithm")
  valid_602010 = validateParameter(valid_602010, JString, required = false,
                                 default = nil)
  if valid_602010 != nil:
    section.add "X-Amz-Algorithm", valid_602010
  var valid_602011 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602011 = validateParameter(valid_602011, JString, required = false,
                                 default = nil)
  if valid_602011 != nil:
    section.add "X-Amz-SignedHeaders", valid_602011
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString
  ##                  : This specifies the name of the environment with the in-progress update that you want to cancel.
  ##   EnvironmentId: JString
  ##                : This specifies the ID of the environment with the in-progress update that you want to cancel.
  section = newJObject()
  var valid_602012 = formData.getOrDefault("EnvironmentName")
  valid_602012 = validateParameter(valid_602012, JString, required = false,
                                 default = nil)
  if valid_602012 != nil:
    section.add "EnvironmentName", valid_602012
  var valid_602013 = formData.getOrDefault("EnvironmentId")
  valid_602013 = validateParameter(valid_602013, JString, required = false,
                                 default = nil)
  if valid_602013 != nil:
    section.add "EnvironmentId", valid_602013
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602014: Call_PostAbortEnvironmentUpdate_602000; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels in-progress environment configuration update or application version deployment.
  ## 
  let valid = call_602014.validator(path, query, header, formData, body)
  let scheme = call_602014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602014.url(scheme.get, call_602014.host, call_602014.base,
                         call_602014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602014, url, valid)

proc call*(call_602015: Call_PostAbortEnvironmentUpdate_602000;
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
  var query_602016 = newJObject()
  var formData_602017 = newJObject()
  add(formData_602017, "EnvironmentName", newJString(EnvironmentName))
  add(query_602016, "Action", newJString(Action))
  add(formData_602017, "EnvironmentId", newJString(EnvironmentId))
  add(query_602016, "Version", newJString(Version))
  result = call_602015.call(nil, query_602016, nil, formData_602017, nil)

var postAbortEnvironmentUpdate* = Call_PostAbortEnvironmentUpdate_602000(
    name: "postAbortEnvironmentUpdate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=AbortEnvironmentUpdate",
    validator: validate_PostAbortEnvironmentUpdate_602001, base: "/",
    url: url_PostAbortEnvironmentUpdate_602002,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAbortEnvironmentUpdate_601728 = ref object of OpenApiRestCall_601390
proc url_GetAbortEnvironmentUpdate_601730(protocol: Scheme; host: string;
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

proc validate_GetAbortEnvironmentUpdate_601729(path: JsonNode; query: JsonNode;
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
  var valid_601842 = query.getOrDefault("EnvironmentName")
  valid_601842 = validateParameter(valid_601842, JString, required = false,
                                 default = nil)
  if valid_601842 != nil:
    section.add "EnvironmentName", valid_601842
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601856 = query.getOrDefault("Action")
  valid_601856 = validateParameter(valid_601856, JString, required = true,
                                 default = newJString("AbortEnvironmentUpdate"))
  if valid_601856 != nil:
    section.add "Action", valid_601856
  var valid_601857 = query.getOrDefault("Version")
  valid_601857 = validateParameter(valid_601857, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_601857 != nil:
    section.add "Version", valid_601857
  var valid_601858 = query.getOrDefault("EnvironmentId")
  valid_601858 = validateParameter(valid_601858, JString, required = false,
                                 default = nil)
  if valid_601858 != nil:
    section.add "EnvironmentId", valid_601858
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
  var valid_601859 = header.getOrDefault("X-Amz-Signature")
  valid_601859 = validateParameter(valid_601859, JString, required = false,
                                 default = nil)
  if valid_601859 != nil:
    section.add "X-Amz-Signature", valid_601859
  var valid_601860 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "X-Amz-Content-Sha256", valid_601860
  var valid_601861 = header.getOrDefault("X-Amz-Date")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-Date", valid_601861
  var valid_601862 = header.getOrDefault("X-Amz-Credential")
  valid_601862 = validateParameter(valid_601862, JString, required = false,
                                 default = nil)
  if valid_601862 != nil:
    section.add "X-Amz-Credential", valid_601862
  var valid_601863 = header.getOrDefault("X-Amz-Security-Token")
  valid_601863 = validateParameter(valid_601863, JString, required = false,
                                 default = nil)
  if valid_601863 != nil:
    section.add "X-Amz-Security-Token", valid_601863
  var valid_601864 = header.getOrDefault("X-Amz-Algorithm")
  valid_601864 = validateParameter(valid_601864, JString, required = false,
                                 default = nil)
  if valid_601864 != nil:
    section.add "X-Amz-Algorithm", valid_601864
  var valid_601865 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601865 = validateParameter(valid_601865, JString, required = false,
                                 default = nil)
  if valid_601865 != nil:
    section.add "X-Amz-SignedHeaders", valid_601865
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601888: Call_GetAbortEnvironmentUpdate_601728; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels in-progress environment configuration update or application version deployment.
  ## 
  let valid = call_601888.validator(path, query, header, formData, body)
  let scheme = call_601888.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601888.url(scheme.get, call_601888.host, call_601888.base,
                         call_601888.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601888, url, valid)

proc call*(call_601959: Call_GetAbortEnvironmentUpdate_601728;
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
  var query_601960 = newJObject()
  add(query_601960, "EnvironmentName", newJString(EnvironmentName))
  add(query_601960, "Action", newJString(Action))
  add(query_601960, "Version", newJString(Version))
  add(query_601960, "EnvironmentId", newJString(EnvironmentId))
  result = call_601959.call(nil, query_601960, nil, nil, nil)

var getAbortEnvironmentUpdate* = Call_GetAbortEnvironmentUpdate_601728(
    name: "getAbortEnvironmentUpdate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=AbortEnvironmentUpdate",
    validator: validate_GetAbortEnvironmentUpdate_601729, base: "/",
    url: url_GetAbortEnvironmentUpdate_601730,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostApplyEnvironmentManagedAction_602036 = ref object of OpenApiRestCall_601390
proc url_PostApplyEnvironmentManagedAction_602038(protocol: Scheme; host: string;
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

proc validate_PostApplyEnvironmentManagedAction_602037(path: JsonNode;
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
  var valid_602039 = query.getOrDefault("Action")
  valid_602039 = validateParameter(valid_602039, JString, required = true, default = newJString(
      "ApplyEnvironmentManagedAction"))
  if valid_602039 != nil:
    section.add "Action", valid_602039
  var valid_602040 = query.getOrDefault("Version")
  valid_602040 = validateParameter(valid_602040, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602040 != nil:
    section.add "Version", valid_602040
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
  var valid_602041 = header.getOrDefault("X-Amz-Signature")
  valid_602041 = validateParameter(valid_602041, JString, required = false,
                                 default = nil)
  if valid_602041 != nil:
    section.add "X-Amz-Signature", valid_602041
  var valid_602042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602042 = validateParameter(valid_602042, JString, required = false,
                                 default = nil)
  if valid_602042 != nil:
    section.add "X-Amz-Content-Sha256", valid_602042
  var valid_602043 = header.getOrDefault("X-Amz-Date")
  valid_602043 = validateParameter(valid_602043, JString, required = false,
                                 default = nil)
  if valid_602043 != nil:
    section.add "X-Amz-Date", valid_602043
  var valid_602044 = header.getOrDefault("X-Amz-Credential")
  valid_602044 = validateParameter(valid_602044, JString, required = false,
                                 default = nil)
  if valid_602044 != nil:
    section.add "X-Amz-Credential", valid_602044
  var valid_602045 = header.getOrDefault("X-Amz-Security-Token")
  valid_602045 = validateParameter(valid_602045, JString, required = false,
                                 default = nil)
  if valid_602045 != nil:
    section.add "X-Amz-Security-Token", valid_602045
  var valid_602046 = header.getOrDefault("X-Amz-Algorithm")
  valid_602046 = validateParameter(valid_602046, JString, required = false,
                                 default = nil)
  if valid_602046 != nil:
    section.add "X-Amz-Algorithm", valid_602046
  var valid_602047 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602047 = validateParameter(valid_602047, JString, required = false,
                                 default = nil)
  if valid_602047 != nil:
    section.add "X-Amz-SignedHeaders", valid_602047
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
  var valid_602048 = formData.getOrDefault("ActionId")
  valid_602048 = validateParameter(valid_602048, JString, required = true,
                                 default = nil)
  if valid_602048 != nil:
    section.add "ActionId", valid_602048
  var valid_602049 = formData.getOrDefault("EnvironmentName")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "EnvironmentName", valid_602049
  var valid_602050 = formData.getOrDefault("EnvironmentId")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "EnvironmentId", valid_602050
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602051: Call_PostApplyEnvironmentManagedAction_602036;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Applies a scheduled managed action immediately. A managed action can be applied only if its status is <code>Scheduled</code>. Get the status and action ID of a managed action with <a>DescribeEnvironmentManagedActions</a>.
  ## 
  let valid = call_602051.validator(path, query, header, formData, body)
  let scheme = call_602051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602051.url(scheme.get, call_602051.host, call_602051.base,
                         call_602051.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602051, url, valid)

proc call*(call_602052: Call_PostApplyEnvironmentManagedAction_602036;
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
  var query_602053 = newJObject()
  var formData_602054 = newJObject()
  add(formData_602054, "ActionId", newJString(ActionId))
  add(formData_602054, "EnvironmentName", newJString(EnvironmentName))
  add(query_602053, "Action", newJString(Action))
  add(formData_602054, "EnvironmentId", newJString(EnvironmentId))
  add(query_602053, "Version", newJString(Version))
  result = call_602052.call(nil, query_602053, nil, formData_602054, nil)

var postApplyEnvironmentManagedAction* = Call_PostApplyEnvironmentManagedAction_602036(
    name: "postApplyEnvironmentManagedAction", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ApplyEnvironmentManagedAction",
    validator: validate_PostApplyEnvironmentManagedAction_602037, base: "/",
    url: url_PostApplyEnvironmentManagedAction_602038,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplyEnvironmentManagedAction_602018 = ref object of OpenApiRestCall_601390
proc url_GetApplyEnvironmentManagedAction_602020(protocol: Scheme; host: string;
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

proc validate_GetApplyEnvironmentManagedAction_602019(path: JsonNode;
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
  var valid_602021 = query.getOrDefault("ActionId")
  valid_602021 = validateParameter(valid_602021, JString, required = true,
                                 default = nil)
  if valid_602021 != nil:
    section.add "ActionId", valid_602021
  var valid_602022 = query.getOrDefault("EnvironmentName")
  valid_602022 = validateParameter(valid_602022, JString, required = false,
                                 default = nil)
  if valid_602022 != nil:
    section.add "EnvironmentName", valid_602022
  var valid_602023 = query.getOrDefault("Action")
  valid_602023 = validateParameter(valid_602023, JString, required = true, default = newJString(
      "ApplyEnvironmentManagedAction"))
  if valid_602023 != nil:
    section.add "Action", valid_602023
  var valid_602024 = query.getOrDefault("Version")
  valid_602024 = validateParameter(valid_602024, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602024 != nil:
    section.add "Version", valid_602024
  var valid_602025 = query.getOrDefault("EnvironmentId")
  valid_602025 = validateParameter(valid_602025, JString, required = false,
                                 default = nil)
  if valid_602025 != nil:
    section.add "EnvironmentId", valid_602025
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
  var valid_602026 = header.getOrDefault("X-Amz-Signature")
  valid_602026 = validateParameter(valid_602026, JString, required = false,
                                 default = nil)
  if valid_602026 != nil:
    section.add "X-Amz-Signature", valid_602026
  var valid_602027 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602027 = validateParameter(valid_602027, JString, required = false,
                                 default = nil)
  if valid_602027 != nil:
    section.add "X-Amz-Content-Sha256", valid_602027
  var valid_602028 = header.getOrDefault("X-Amz-Date")
  valid_602028 = validateParameter(valid_602028, JString, required = false,
                                 default = nil)
  if valid_602028 != nil:
    section.add "X-Amz-Date", valid_602028
  var valid_602029 = header.getOrDefault("X-Amz-Credential")
  valid_602029 = validateParameter(valid_602029, JString, required = false,
                                 default = nil)
  if valid_602029 != nil:
    section.add "X-Amz-Credential", valid_602029
  var valid_602030 = header.getOrDefault("X-Amz-Security-Token")
  valid_602030 = validateParameter(valid_602030, JString, required = false,
                                 default = nil)
  if valid_602030 != nil:
    section.add "X-Amz-Security-Token", valid_602030
  var valid_602031 = header.getOrDefault("X-Amz-Algorithm")
  valid_602031 = validateParameter(valid_602031, JString, required = false,
                                 default = nil)
  if valid_602031 != nil:
    section.add "X-Amz-Algorithm", valid_602031
  var valid_602032 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602032 = validateParameter(valid_602032, JString, required = false,
                                 default = nil)
  if valid_602032 != nil:
    section.add "X-Amz-SignedHeaders", valid_602032
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602033: Call_GetApplyEnvironmentManagedAction_602018;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Applies a scheduled managed action immediately. A managed action can be applied only if its status is <code>Scheduled</code>. Get the status and action ID of a managed action with <a>DescribeEnvironmentManagedActions</a>.
  ## 
  let valid = call_602033.validator(path, query, header, formData, body)
  let scheme = call_602033.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602033.url(scheme.get, call_602033.host, call_602033.base,
                         call_602033.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602033, url, valid)

proc call*(call_602034: Call_GetApplyEnvironmentManagedAction_602018;
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
  var query_602035 = newJObject()
  add(query_602035, "ActionId", newJString(ActionId))
  add(query_602035, "EnvironmentName", newJString(EnvironmentName))
  add(query_602035, "Action", newJString(Action))
  add(query_602035, "Version", newJString(Version))
  add(query_602035, "EnvironmentId", newJString(EnvironmentId))
  result = call_602034.call(nil, query_602035, nil, nil, nil)

var getApplyEnvironmentManagedAction* = Call_GetApplyEnvironmentManagedAction_602018(
    name: "getApplyEnvironmentManagedAction", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ApplyEnvironmentManagedAction",
    validator: validate_GetApplyEnvironmentManagedAction_602019, base: "/",
    url: url_GetApplyEnvironmentManagedAction_602020,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCheckDNSAvailability_602071 = ref object of OpenApiRestCall_601390
proc url_PostCheckDNSAvailability_602073(protocol: Scheme; host: string;
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

proc validate_PostCheckDNSAvailability_602072(path: JsonNode; query: JsonNode;
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
  var valid_602074 = query.getOrDefault("Action")
  valid_602074 = validateParameter(valid_602074, JString, required = true,
                                 default = newJString("CheckDNSAvailability"))
  if valid_602074 != nil:
    section.add "Action", valid_602074
  var valid_602075 = query.getOrDefault("Version")
  valid_602075 = validateParameter(valid_602075, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602075 != nil:
    section.add "Version", valid_602075
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
  var valid_602076 = header.getOrDefault("X-Amz-Signature")
  valid_602076 = validateParameter(valid_602076, JString, required = false,
                                 default = nil)
  if valid_602076 != nil:
    section.add "X-Amz-Signature", valid_602076
  var valid_602077 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602077 = validateParameter(valid_602077, JString, required = false,
                                 default = nil)
  if valid_602077 != nil:
    section.add "X-Amz-Content-Sha256", valid_602077
  var valid_602078 = header.getOrDefault("X-Amz-Date")
  valid_602078 = validateParameter(valid_602078, JString, required = false,
                                 default = nil)
  if valid_602078 != nil:
    section.add "X-Amz-Date", valid_602078
  var valid_602079 = header.getOrDefault("X-Amz-Credential")
  valid_602079 = validateParameter(valid_602079, JString, required = false,
                                 default = nil)
  if valid_602079 != nil:
    section.add "X-Amz-Credential", valid_602079
  var valid_602080 = header.getOrDefault("X-Amz-Security-Token")
  valid_602080 = validateParameter(valid_602080, JString, required = false,
                                 default = nil)
  if valid_602080 != nil:
    section.add "X-Amz-Security-Token", valid_602080
  var valid_602081 = header.getOrDefault("X-Amz-Algorithm")
  valid_602081 = validateParameter(valid_602081, JString, required = false,
                                 default = nil)
  if valid_602081 != nil:
    section.add "X-Amz-Algorithm", valid_602081
  var valid_602082 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602082 = validateParameter(valid_602082, JString, required = false,
                                 default = nil)
  if valid_602082 != nil:
    section.add "X-Amz-SignedHeaders", valid_602082
  result.add "header", section
  ## parameters in `formData` object:
  ##   CNAMEPrefix: JString (required)
  ##              : The prefix used when this CNAME is reserved.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `CNAMEPrefix` field"
  var valid_602083 = formData.getOrDefault("CNAMEPrefix")
  valid_602083 = validateParameter(valid_602083, JString, required = true,
                                 default = nil)
  if valid_602083 != nil:
    section.add "CNAMEPrefix", valid_602083
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602084: Call_PostCheckDNSAvailability_602071; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Checks if the specified CNAME is available.
  ## 
  let valid = call_602084.validator(path, query, header, formData, body)
  let scheme = call_602084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602084.url(scheme.get, call_602084.host, call_602084.base,
                         call_602084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602084, url, valid)

proc call*(call_602085: Call_PostCheckDNSAvailability_602071; CNAMEPrefix: string;
          Action: string = "CheckDNSAvailability"; Version: string = "2010-12-01"): Recallable =
  ## postCheckDNSAvailability
  ## Checks if the specified CNAME is available.
  ##   CNAMEPrefix: string (required)
  ##              : The prefix used when this CNAME is reserved.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602086 = newJObject()
  var formData_602087 = newJObject()
  add(formData_602087, "CNAMEPrefix", newJString(CNAMEPrefix))
  add(query_602086, "Action", newJString(Action))
  add(query_602086, "Version", newJString(Version))
  result = call_602085.call(nil, query_602086, nil, formData_602087, nil)

var postCheckDNSAvailability* = Call_PostCheckDNSAvailability_602071(
    name: "postCheckDNSAvailability", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CheckDNSAvailability",
    validator: validate_PostCheckDNSAvailability_602072, base: "/",
    url: url_PostCheckDNSAvailability_602073, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCheckDNSAvailability_602055 = ref object of OpenApiRestCall_601390
proc url_GetCheckDNSAvailability_602057(protocol: Scheme; host: string; base: string;
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

proc validate_GetCheckDNSAvailability_602056(path: JsonNode; query: JsonNode;
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
  var valid_602058 = query.getOrDefault("CNAMEPrefix")
  valid_602058 = validateParameter(valid_602058, JString, required = true,
                                 default = nil)
  if valid_602058 != nil:
    section.add "CNAMEPrefix", valid_602058
  var valid_602059 = query.getOrDefault("Action")
  valid_602059 = validateParameter(valid_602059, JString, required = true,
                                 default = newJString("CheckDNSAvailability"))
  if valid_602059 != nil:
    section.add "Action", valid_602059
  var valid_602060 = query.getOrDefault("Version")
  valid_602060 = validateParameter(valid_602060, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602060 != nil:
    section.add "Version", valid_602060
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
  var valid_602061 = header.getOrDefault("X-Amz-Signature")
  valid_602061 = validateParameter(valid_602061, JString, required = false,
                                 default = nil)
  if valid_602061 != nil:
    section.add "X-Amz-Signature", valid_602061
  var valid_602062 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602062 = validateParameter(valid_602062, JString, required = false,
                                 default = nil)
  if valid_602062 != nil:
    section.add "X-Amz-Content-Sha256", valid_602062
  var valid_602063 = header.getOrDefault("X-Amz-Date")
  valid_602063 = validateParameter(valid_602063, JString, required = false,
                                 default = nil)
  if valid_602063 != nil:
    section.add "X-Amz-Date", valid_602063
  var valid_602064 = header.getOrDefault("X-Amz-Credential")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "X-Amz-Credential", valid_602064
  var valid_602065 = header.getOrDefault("X-Amz-Security-Token")
  valid_602065 = validateParameter(valid_602065, JString, required = false,
                                 default = nil)
  if valid_602065 != nil:
    section.add "X-Amz-Security-Token", valid_602065
  var valid_602066 = header.getOrDefault("X-Amz-Algorithm")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "X-Amz-Algorithm", valid_602066
  var valid_602067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602067 = validateParameter(valid_602067, JString, required = false,
                                 default = nil)
  if valid_602067 != nil:
    section.add "X-Amz-SignedHeaders", valid_602067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602068: Call_GetCheckDNSAvailability_602055; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Checks if the specified CNAME is available.
  ## 
  let valid = call_602068.validator(path, query, header, formData, body)
  let scheme = call_602068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602068.url(scheme.get, call_602068.host, call_602068.base,
                         call_602068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602068, url, valid)

proc call*(call_602069: Call_GetCheckDNSAvailability_602055; CNAMEPrefix: string;
          Action: string = "CheckDNSAvailability"; Version: string = "2010-12-01"): Recallable =
  ## getCheckDNSAvailability
  ## Checks if the specified CNAME is available.
  ##   CNAMEPrefix: string (required)
  ##              : The prefix used when this CNAME is reserved.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602070 = newJObject()
  add(query_602070, "CNAMEPrefix", newJString(CNAMEPrefix))
  add(query_602070, "Action", newJString(Action))
  add(query_602070, "Version", newJString(Version))
  result = call_602069.call(nil, query_602070, nil, nil, nil)

var getCheckDNSAvailability* = Call_GetCheckDNSAvailability_602055(
    name: "getCheckDNSAvailability", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CheckDNSAvailability",
    validator: validate_GetCheckDNSAvailability_602056, base: "/",
    url: url_GetCheckDNSAvailability_602057, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostComposeEnvironments_602106 = ref object of OpenApiRestCall_601390
proc url_PostComposeEnvironments_602108(protocol: Scheme; host: string; base: string;
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

proc validate_PostComposeEnvironments_602107(path: JsonNode; query: JsonNode;
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
  var valid_602109 = query.getOrDefault("Action")
  valid_602109 = validateParameter(valid_602109, JString, required = true,
                                 default = newJString("ComposeEnvironments"))
  if valid_602109 != nil:
    section.add "Action", valid_602109
  var valid_602110 = query.getOrDefault("Version")
  valid_602110 = validateParameter(valid_602110, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602110 != nil:
    section.add "Version", valid_602110
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
  var valid_602111 = header.getOrDefault("X-Amz-Signature")
  valid_602111 = validateParameter(valid_602111, JString, required = false,
                                 default = nil)
  if valid_602111 != nil:
    section.add "X-Amz-Signature", valid_602111
  var valid_602112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602112 = validateParameter(valid_602112, JString, required = false,
                                 default = nil)
  if valid_602112 != nil:
    section.add "X-Amz-Content-Sha256", valid_602112
  var valid_602113 = header.getOrDefault("X-Amz-Date")
  valid_602113 = validateParameter(valid_602113, JString, required = false,
                                 default = nil)
  if valid_602113 != nil:
    section.add "X-Amz-Date", valid_602113
  var valid_602114 = header.getOrDefault("X-Amz-Credential")
  valid_602114 = validateParameter(valid_602114, JString, required = false,
                                 default = nil)
  if valid_602114 != nil:
    section.add "X-Amz-Credential", valid_602114
  var valid_602115 = header.getOrDefault("X-Amz-Security-Token")
  valid_602115 = validateParameter(valid_602115, JString, required = false,
                                 default = nil)
  if valid_602115 != nil:
    section.add "X-Amz-Security-Token", valid_602115
  var valid_602116 = header.getOrDefault("X-Amz-Algorithm")
  valid_602116 = validateParameter(valid_602116, JString, required = false,
                                 default = nil)
  if valid_602116 != nil:
    section.add "X-Amz-Algorithm", valid_602116
  var valid_602117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602117 = validateParameter(valid_602117, JString, required = false,
                                 default = nil)
  if valid_602117 != nil:
    section.add "X-Amz-SignedHeaders", valid_602117
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
  var valid_602118 = formData.getOrDefault("GroupName")
  valid_602118 = validateParameter(valid_602118, JString, required = false,
                                 default = nil)
  if valid_602118 != nil:
    section.add "GroupName", valid_602118
  var valid_602119 = formData.getOrDefault("ApplicationName")
  valid_602119 = validateParameter(valid_602119, JString, required = false,
                                 default = nil)
  if valid_602119 != nil:
    section.add "ApplicationName", valid_602119
  var valid_602120 = formData.getOrDefault("VersionLabels")
  valid_602120 = validateParameter(valid_602120, JArray, required = false,
                                 default = nil)
  if valid_602120 != nil:
    section.add "VersionLabels", valid_602120
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602121: Call_PostComposeEnvironments_602106; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create or update a group of environments that each run a separate component of a single application. Takes a list of version labels that specify application source bundles for each of the environments to create or update. The name of each environment and other required information must be included in the source bundles in an environment manifest named <code>env.yaml</code>. See <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-mgmt-compose.html">Compose Environments</a> for details.
  ## 
  let valid = call_602121.validator(path, query, header, formData, body)
  let scheme = call_602121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602121.url(scheme.get, call_602121.host, call_602121.base,
                         call_602121.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602121, url, valid)

proc call*(call_602122: Call_PostComposeEnvironments_602106;
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
  var query_602123 = newJObject()
  var formData_602124 = newJObject()
  add(formData_602124, "GroupName", newJString(GroupName))
  add(formData_602124, "ApplicationName", newJString(ApplicationName))
  if VersionLabels != nil:
    formData_602124.add "VersionLabels", VersionLabels
  add(query_602123, "Action", newJString(Action))
  add(query_602123, "Version", newJString(Version))
  result = call_602122.call(nil, query_602123, nil, formData_602124, nil)

var postComposeEnvironments* = Call_PostComposeEnvironments_602106(
    name: "postComposeEnvironments", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ComposeEnvironments",
    validator: validate_PostComposeEnvironments_602107, base: "/",
    url: url_PostComposeEnvironments_602108, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetComposeEnvironments_602088 = ref object of OpenApiRestCall_601390
proc url_GetComposeEnvironments_602090(protocol: Scheme; host: string; base: string;
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

proc validate_GetComposeEnvironments_602089(path: JsonNode; query: JsonNode;
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
  var valid_602091 = query.getOrDefault("ApplicationName")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "ApplicationName", valid_602091
  var valid_602092 = query.getOrDefault("GroupName")
  valid_602092 = validateParameter(valid_602092, JString, required = false,
                                 default = nil)
  if valid_602092 != nil:
    section.add "GroupName", valid_602092
  var valid_602093 = query.getOrDefault("VersionLabels")
  valid_602093 = validateParameter(valid_602093, JArray, required = false,
                                 default = nil)
  if valid_602093 != nil:
    section.add "VersionLabels", valid_602093
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602094 = query.getOrDefault("Action")
  valid_602094 = validateParameter(valid_602094, JString, required = true,
                                 default = newJString("ComposeEnvironments"))
  if valid_602094 != nil:
    section.add "Action", valid_602094
  var valid_602095 = query.getOrDefault("Version")
  valid_602095 = validateParameter(valid_602095, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602095 != nil:
    section.add "Version", valid_602095
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
  var valid_602096 = header.getOrDefault("X-Amz-Signature")
  valid_602096 = validateParameter(valid_602096, JString, required = false,
                                 default = nil)
  if valid_602096 != nil:
    section.add "X-Amz-Signature", valid_602096
  var valid_602097 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602097 = validateParameter(valid_602097, JString, required = false,
                                 default = nil)
  if valid_602097 != nil:
    section.add "X-Amz-Content-Sha256", valid_602097
  var valid_602098 = header.getOrDefault("X-Amz-Date")
  valid_602098 = validateParameter(valid_602098, JString, required = false,
                                 default = nil)
  if valid_602098 != nil:
    section.add "X-Amz-Date", valid_602098
  var valid_602099 = header.getOrDefault("X-Amz-Credential")
  valid_602099 = validateParameter(valid_602099, JString, required = false,
                                 default = nil)
  if valid_602099 != nil:
    section.add "X-Amz-Credential", valid_602099
  var valid_602100 = header.getOrDefault("X-Amz-Security-Token")
  valid_602100 = validateParameter(valid_602100, JString, required = false,
                                 default = nil)
  if valid_602100 != nil:
    section.add "X-Amz-Security-Token", valid_602100
  var valid_602101 = header.getOrDefault("X-Amz-Algorithm")
  valid_602101 = validateParameter(valid_602101, JString, required = false,
                                 default = nil)
  if valid_602101 != nil:
    section.add "X-Amz-Algorithm", valid_602101
  var valid_602102 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602102 = validateParameter(valid_602102, JString, required = false,
                                 default = nil)
  if valid_602102 != nil:
    section.add "X-Amz-SignedHeaders", valid_602102
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602103: Call_GetComposeEnvironments_602088; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create or update a group of environments that each run a separate component of a single application. Takes a list of version labels that specify application source bundles for each of the environments to create or update. The name of each environment and other required information must be included in the source bundles in an environment manifest named <code>env.yaml</code>. See <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/environment-mgmt-compose.html">Compose Environments</a> for details.
  ## 
  let valid = call_602103.validator(path, query, header, formData, body)
  let scheme = call_602103.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602103.url(scheme.get, call_602103.host, call_602103.base,
                         call_602103.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602103, url, valid)

proc call*(call_602104: Call_GetComposeEnvironments_602088;
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
  var query_602105 = newJObject()
  add(query_602105, "ApplicationName", newJString(ApplicationName))
  add(query_602105, "GroupName", newJString(GroupName))
  if VersionLabels != nil:
    query_602105.add "VersionLabels", VersionLabels
  add(query_602105, "Action", newJString(Action))
  add(query_602105, "Version", newJString(Version))
  result = call_602104.call(nil, query_602105, nil, nil, nil)

var getComposeEnvironments* = Call_GetComposeEnvironments_602088(
    name: "getComposeEnvironments", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ComposeEnvironments",
    validator: validate_GetComposeEnvironments_602089, base: "/",
    url: url_GetComposeEnvironments_602090, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateApplication_602145 = ref object of OpenApiRestCall_601390
proc url_PostCreateApplication_602147(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateApplication_602146(path: JsonNode; query: JsonNode;
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
  var valid_602148 = query.getOrDefault("Action")
  valid_602148 = validateParameter(valid_602148, JString, required = true,
                                 default = newJString("CreateApplication"))
  if valid_602148 != nil:
    section.add "Action", valid_602148
  var valid_602149 = query.getOrDefault("Version")
  valid_602149 = validateParameter(valid_602149, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602149 != nil:
    section.add "Version", valid_602149
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
  var valid_602150 = header.getOrDefault("X-Amz-Signature")
  valid_602150 = validateParameter(valid_602150, JString, required = false,
                                 default = nil)
  if valid_602150 != nil:
    section.add "X-Amz-Signature", valid_602150
  var valid_602151 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602151 = validateParameter(valid_602151, JString, required = false,
                                 default = nil)
  if valid_602151 != nil:
    section.add "X-Amz-Content-Sha256", valid_602151
  var valid_602152 = header.getOrDefault("X-Amz-Date")
  valid_602152 = validateParameter(valid_602152, JString, required = false,
                                 default = nil)
  if valid_602152 != nil:
    section.add "X-Amz-Date", valid_602152
  var valid_602153 = header.getOrDefault("X-Amz-Credential")
  valid_602153 = validateParameter(valid_602153, JString, required = false,
                                 default = nil)
  if valid_602153 != nil:
    section.add "X-Amz-Credential", valid_602153
  var valid_602154 = header.getOrDefault("X-Amz-Security-Token")
  valid_602154 = validateParameter(valid_602154, JString, required = false,
                                 default = nil)
  if valid_602154 != nil:
    section.add "X-Amz-Security-Token", valid_602154
  var valid_602155 = header.getOrDefault("X-Amz-Algorithm")
  valid_602155 = validateParameter(valid_602155, JString, required = false,
                                 default = nil)
  if valid_602155 != nil:
    section.add "X-Amz-Algorithm", valid_602155
  var valid_602156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602156 = validateParameter(valid_602156, JString, required = false,
                                 default = nil)
  if valid_602156 != nil:
    section.add "X-Amz-SignedHeaders", valid_602156
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
  var valid_602157 = formData.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_602157 = validateParameter(valid_602157, JString, required = false,
                                 default = nil)
  if valid_602157 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_602157
  var valid_602158 = formData.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_602158 = validateParameter(valid_602158, JString, required = false,
                                 default = nil)
  if valid_602158 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_602158
  var valid_602159 = formData.getOrDefault("Description")
  valid_602159 = validateParameter(valid_602159, JString, required = false,
                                 default = nil)
  if valid_602159 != nil:
    section.add "Description", valid_602159
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_602160 = formData.getOrDefault("ApplicationName")
  valid_602160 = validateParameter(valid_602160, JString, required = true,
                                 default = nil)
  if valid_602160 != nil:
    section.add "ApplicationName", valid_602160
  var valid_602161 = formData.getOrDefault("Tags")
  valid_602161 = validateParameter(valid_602161, JArray, required = false,
                                 default = nil)
  if valid_602161 != nil:
    section.add "Tags", valid_602161
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602162: Call_PostCreateApplication_602145; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates an application that has one configuration template named <code>default</code> and no application versions. 
  ## 
  let valid = call_602162.validator(path, query, header, formData, body)
  let scheme = call_602162.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602162.url(scheme.get, call_602162.host, call_602162.base,
                         call_602162.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602162, url, valid)

proc call*(call_602163: Call_PostCreateApplication_602145; ApplicationName: string;
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
  var query_602164 = newJObject()
  var formData_602165 = newJObject()
  add(formData_602165, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  add(formData_602165, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  add(formData_602165, "Description", newJString(Description))
  add(formData_602165, "ApplicationName", newJString(ApplicationName))
  add(query_602164, "Action", newJString(Action))
  if Tags != nil:
    formData_602165.add "Tags", Tags
  add(query_602164, "Version", newJString(Version))
  result = call_602163.call(nil, query_602164, nil, formData_602165, nil)

var postCreateApplication* = Call_PostCreateApplication_602145(
    name: "postCreateApplication", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateApplication",
    validator: validate_PostCreateApplication_602146, base: "/",
    url: url_PostCreateApplication_602147, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateApplication_602125 = ref object of OpenApiRestCall_601390
proc url_GetCreateApplication_602127(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateApplication_602126(path: JsonNode; query: JsonNode;
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
  var valid_602128 = query.getOrDefault("ApplicationName")
  valid_602128 = validateParameter(valid_602128, JString, required = true,
                                 default = nil)
  if valid_602128 != nil:
    section.add "ApplicationName", valid_602128
  var valid_602129 = query.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_602129 = validateParameter(valid_602129, JString, required = false,
                                 default = nil)
  if valid_602129 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_602129
  var valid_602130 = query.getOrDefault("Tags")
  valid_602130 = validateParameter(valid_602130, JArray, required = false,
                                 default = nil)
  if valid_602130 != nil:
    section.add "Tags", valid_602130
  var valid_602131 = query.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_602131 = validateParameter(valid_602131, JString, required = false,
                                 default = nil)
  if valid_602131 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_602131
  var valid_602132 = query.getOrDefault("Action")
  valid_602132 = validateParameter(valid_602132, JString, required = true,
                                 default = newJString("CreateApplication"))
  if valid_602132 != nil:
    section.add "Action", valid_602132
  var valid_602133 = query.getOrDefault("Description")
  valid_602133 = validateParameter(valid_602133, JString, required = false,
                                 default = nil)
  if valid_602133 != nil:
    section.add "Description", valid_602133
  var valid_602134 = query.getOrDefault("Version")
  valid_602134 = validateParameter(valid_602134, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602134 != nil:
    section.add "Version", valid_602134
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
  var valid_602135 = header.getOrDefault("X-Amz-Signature")
  valid_602135 = validateParameter(valid_602135, JString, required = false,
                                 default = nil)
  if valid_602135 != nil:
    section.add "X-Amz-Signature", valid_602135
  var valid_602136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602136 = validateParameter(valid_602136, JString, required = false,
                                 default = nil)
  if valid_602136 != nil:
    section.add "X-Amz-Content-Sha256", valid_602136
  var valid_602137 = header.getOrDefault("X-Amz-Date")
  valid_602137 = validateParameter(valid_602137, JString, required = false,
                                 default = nil)
  if valid_602137 != nil:
    section.add "X-Amz-Date", valid_602137
  var valid_602138 = header.getOrDefault("X-Amz-Credential")
  valid_602138 = validateParameter(valid_602138, JString, required = false,
                                 default = nil)
  if valid_602138 != nil:
    section.add "X-Amz-Credential", valid_602138
  var valid_602139 = header.getOrDefault("X-Amz-Security-Token")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "X-Amz-Security-Token", valid_602139
  var valid_602140 = header.getOrDefault("X-Amz-Algorithm")
  valid_602140 = validateParameter(valid_602140, JString, required = false,
                                 default = nil)
  if valid_602140 != nil:
    section.add "X-Amz-Algorithm", valid_602140
  var valid_602141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "X-Amz-SignedHeaders", valid_602141
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602142: Call_GetCreateApplication_602125; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates an application that has one configuration template named <code>default</code> and no application versions. 
  ## 
  let valid = call_602142.validator(path, query, header, formData, body)
  let scheme = call_602142.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602142.url(scheme.get, call_602142.host, call_602142.base,
                         call_602142.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602142, url, valid)

proc call*(call_602143: Call_GetCreateApplication_602125; ApplicationName: string;
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
  var query_602144 = newJObject()
  add(query_602144, "ApplicationName", newJString(ApplicationName))
  add(query_602144, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  if Tags != nil:
    query_602144.add "Tags", Tags
  add(query_602144, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  add(query_602144, "Action", newJString(Action))
  add(query_602144, "Description", newJString(Description))
  add(query_602144, "Version", newJString(Version))
  result = call_602143.call(nil, query_602144, nil, nil, nil)

var getCreateApplication* = Call_GetCreateApplication_602125(
    name: "getCreateApplication", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateApplication",
    validator: validate_GetCreateApplication_602126, base: "/",
    url: url_GetCreateApplication_602127, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateApplicationVersion_602197 = ref object of OpenApiRestCall_601390
proc url_PostCreateApplicationVersion_602199(protocol: Scheme; host: string;
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

proc validate_PostCreateApplicationVersion_602198(path: JsonNode; query: JsonNode;
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
  var valid_602200 = query.getOrDefault("Action")
  valid_602200 = validateParameter(valid_602200, JString, required = true, default = newJString(
      "CreateApplicationVersion"))
  if valid_602200 != nil:
    section.add "Action", valid_602200
  var valid_602201 = query.getOrDefault("Version")
  valid_602201 = validateParameter(valid_602201, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602201 != nil:
    section.add "Version", valid_602201
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
  var valid_602202 = header.getOrDefault("X-Amz-Signature")
  valid_602202 = validateParameter(valid_602202, JString, required = false,
                                 default = nil)
  if valid_602202 != nil:
    section.add "X-Amz-Signature", valid_602202
  var valid_602203 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602203 = validateParameter(valid_602203, JString, required = false,
                                 default = nil)
  if valid_602203 != nil:
    section.add "X-Amz-Content-Sha256", valid_602203
  var valid_602204 = header.getOrDefault("X-Amz-Date")
  valid_602204 = validateParameter(valid_602204, JString, required = false,
                                 default = nil)
  if valid_602204 != nil:
    section.add "X-Amz-Date", valid_602204
  var valid_602205 = header.getOrDefault("X-Amz-Credential")
  valid_602205 = validateParameter(valid_602205, JString, required = false,
                                 default = nil)
  if valid_602205 != nil:
    section.add "X-Amz-Credential", valid_602205
  var valid_602206 = header.getOrDefault("X-Amz-Security-Token")
  valid_602206 = validateParameter(valid_602206, JString, required = false,
                                 default = nil)
  if valid_602206 != nil:
    section.add "X-Amz-Security-Token", valid_602206
  var valid_602207 = header.getOrDefault("X-Amz-Algorithm")
  valid_602207 = validateParameter(valid_602207, JString, required = false,
                                 default = nil)
  if valid_602207 != nil:
    section.add "X-Amz-Algorithm", valid_602207
  var valid_602208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602208 = validateParameter(valid_602208, JString, required = false,
                                 default = nil)
  if valid_602208 != nil:
    section.add "X-Amz-SignedHeaders", valid_602208
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
  var valid_602209 = formData.getOrDefault("BuildConfiguration.ComputeType")
  valid_602209 = validateParameter(valid_602209, JString, required = false,
                                 default = nil)
  if valid_602209 != nil:
    section.add "BuildConfiguration.ComputeType", valid_602209
  var valid_602210 = formData.getOrDefault("SourceBundle.S3Key")
  valid_602210 = validateParameter(valid_602210, JString, required = false,
                                 default = nil)
  if valid_602210 != nil:
    section.add "SourceBundle.S3Key", valid_602210
  var valid_602211 = formData.getOrDefault("Process")
  valid_602211 = validateParameter(valid_602211, JBool, required = false, default = nil)
  if valid_602211 != nil:
    section.add "Process", valid_602211
  var valid_602212 = formData.getOrDefault("SourceBuildInformation.SourceType")
  valid_602212 = validateParameter(valid_602212, JString, required = false,
                                 default = nil)
  if valid_602212 != nil:
    section.add "SourceBuildInformation.SourceType", valid_602212
  var valid_602213 = formData.getOrDefault("BuildConfiguration.ArtifactName")
  valid_602213 = validateParameter(valid_602213, JString, required = false,
                                 default = nil)
  if valid_602213 != nil:
    section.add "BuildConfiguration.ArtifactName", valid_602213
  var valid_602214 = formData.getOrDefault("Description")
  valid_602214 = validateParameter(valid_602214, JString, required = false,
                                 default = nil)
  if valid_602214 != nil:
    section.add "Description", valid_602214
  assert formData != nil,
        "formData argument is necessary due to required `VersionLabel` field"
  var valid_602215 = formData.getOrDefault("VersionLabel")
  valid_602215 = validateParameter(valid_602215, JString, required = true,
                                 default = nil)
  if valid_602215 != nil:
    section.add "VersionLabel", valid_602215
  var valid_602216 = formData.getOrDefault("SourceBuildInformation.SourceRepository")
  valid_602216 = validateParameter(valid_602216, JString, required = false,
                                 default = nil)
  if valid_602216 != nil:
    section.add "SourceBuildInformation.SourceRepository", valid_602216
  var valid_602217 = formData.getOrDefault("AutoCreateApplication")
  valid_602217 = validateParameter(valid_602217, JBool, required = false, default = nil)
  if valid_602217 != nil:
    section.add "AutoCreateApplication", valid_602217
  var valid_602218 = formData.getOrDefault("SourceBuildInformation.SourceLocation")
  valid_602218 = validateParameter(valid_602218, JString, required = false,
                                 default = nil)
  if valid_602218 != nil:
    section.add "SourceBuildInformation.SourceLocation", valid_602218
  var valid_602219 = formData.getOrDefault("ApplicationName")
  valid_602219 = validateParameter(valid_602219, JString, required = true,
                                 default = nil)
  if valid_602219 != nil:
    section.add "ApplicationName", valid_602219
  var valid_602220 = formData.getOrDefault("BuildConfiguration.Image")
  valid_602220 = validateParameter(valid_602220, JString, required = false,
                                 default = nil)
  if valid_602220 != nil:
    section.add "BuildConfiguration.Image", valid_602220
  var valid_602221 = formData.getOrDefault("BuildConfiguration.TimeoutInMinutes")
  valid_602221 = validateParameter(valid_602221, JString, required = false,
                                 default = nil)
  if valid_602221 != nil:
    section.add "BuildConfiguration.TimeoutInMinutes", valid_602221
  var valid_602222 = formData.getOrDefault("Tags")
  valid_602222 = validateParameter(valid_602222, JArray, required = false,
                                 default = nil)
  if valid_602222 != nil:
    section.add "Tags", valid_602222
  var valid_602223 = formData.getOrDefault("SourceBundle.S3Bucket")
  valid_602223 = validateParameter(valid_602223, JString, required = false,
                                 default = nil)
  if valid_602223 != nil:
    section.add "SourceBundle.S3Bucket", valid_602223
  var valid_602224 = formData.getOrDefault("BuildConfiguration.CodeBuildServiceRole")
  valid_602224 = validateParameter(valid_602224, JString, required = false,
                                 default = nil)
  if valid_602224 != nil:
    section.add "BuildConfiguration.CodeBuildServiceRole", valid_602224
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602225: Call_PostCreateApplicationVersion_602197; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an application version for the specified application. You can create an application version from a source bundle in Amazon S3, a commit in AWS CodeCommit, or the output of an AWS CodeBuild build as follows:</p> <p>Specify a commit in an AWS CodeCommit repository with <code>SourceBuildInformation</code>.</p> <p>Specify a build in an AWS CodeBuild with <code>SourceBuildInformation</code> and <code>BuildConfiguration</code>.</p> <p>Specify a source bundle in S3 with <code>SourceBundle</code> </p> <p>Omit both <code>SourceBuildInformation</code> and <code>SourceBundle</code> to use the default sample application.</p> <note> <p>Once you create an application version with a specified Amazon S3 bucket and key location, you cannot change that Amazon S3 location. If you change the Amazon S3 location, you receive an exception when you attempt to launch an environment from the application version.</p> </note>
  ## 
  let valid = call_602225.validator(path, query, header, formData, body)
  let scheme = call_602225.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602225.url(scheme.get, call_602225.host, call_602225.base,
                         call_602225.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602225, url, valid)

proc call*(call_602226: Call_PostCreateApplicationVersion_602197;
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
  var query_602227 = newJObject()
  var formData_602228 = newJObject()
  add(formData_602228, "BuildConfiguration.ComputeType",
      newJString(BuildConfigurationComputeType))
  add(formData_602228, "SourceBundle.S3Key", newJString(SourceBundleS3Key))
  add(formData_602228, "Process", newJBool(Process))
  add(formData_602228, "SourceBuildInformation.SourceType",
      newJString(SourceBuildInformationSourceType))
  add(formData_602228, "BuildConfiguration.ArtifactName",
      newJString(BuildConfigurationArtifactName))
  add(formData_602228, "Description", newJString(Description))
  add(formData_602228, "VersionLabel", newJString(VersionLabel))
  add(formData_602228, "SourceBuildInformation.SourceRepository",
      newJString(SourceBuildInformationSourceRepository))
  add(formData_602228, "AutoCreateApplication", newJBool(AutoCreateApplication))
  add(formData_602228, "SourceBuildInformation.SourceLocation",
      newJString(SourceBuildInformationSourceLocation))
  add(formData_602228, "ApplicationName", newJString(ApplicationName))
  add(query_602227, "Action", newJString(Action))
  add(formData_602228, "BuildConfiguration.Image",
      newJString(BuildConfigurationImage))
  add(formData_602228, "BuildConfiguration.TimeoutInMinutes",
      newJString(BuildConfigurationTimeoutInMinutes))
  if Tags != nil:
    formData_602228.add "Tags", Tags
  add(formData_602228, "SourceBundle.S3Bucket", newJString(SourceBundleS3Bucket))
  add(query_602227, "Version", newJString(Version))
  add(formData_602228, "BuildConfiguration.CodeBuildServiceRole",
      newJString(BuildConfigurationCodeBuildServiceRole))
  result = call_602226.call(nil, query_602227, nil, formData_602228, nil)

var postCreateApplicationVersion* = Call_PostCreateApplicationVersion_602197(
    name: "postCreateApplicationVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateApplicationVersion",
    validator: validate_PostCreateApplicationVersion_602198, base: "/",
    url: url_PostCreateApplicationVersion_602199,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateApplicationVersion_602166 = ref object of OpenApiRestCall_601390
proc url_GetCreateApplicationVersion_602168(protocol: Scheme; host: string;
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

proc validate_GetCreateApplicationVersion_602167(path: JsonNode; query: JsonNode;
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
  var valid_602169 = query.getOrDefault("ApplicationName")
  valid_602169 = validateParameter(valid_602169, JString, required = true,
                                 default = nil)
  if valid_602169 != nil:
    section.add "ApplicationName", valid_602169
  var valid_602170 = query.getOrDefault("BuildConfiguration.TimeoutInMinutes")
  valid_602170 = validateParameter(valid_602170, JString, required = false,
                                 default = nil)
  if valid_602170 != nil:
    section.add "BuildConfiguration.TimeoutInMinutes", valid_602170
  var valid_602171 = query.getOrDefault("Process")
  valid_602171 = validateParameter(valid_602171, JBool, required = false, default = nil)
  if valid_602171 != nil:
    section.add "Process", valid_602171
  var valid_602172 = query.getOrDefault("SourceBuildInformation.SourceLocation")
  valid_602172 = validateParameter(valid_602172, JString, required = false,
                                 default = nil)
  if valid_602172 != nil:
    section.add "SourceBuildInformation.SourceLocation", valid_602172
  var valid_602173 = query.getOrDefault("VersionLabel")
  valid_602173 = validateParameter(valid_602173, JString, required = true,
                                 default = nil)
  if valid_602173 != nil:
    section.add "VersionLabel", valid_602173
  var valid_602174 = query.getOrDefault("Tags")
  valid_602174 = validateParameter(valid_602174, JArray, required = false,
                                 default = nil)
  if valid_602174 != nil:
    section.add "Tags", valid_602174
  var valid_602175 = query.getOrDefault("AutoCreateApplication")
  valid_602175 = validateParameter(valid_602175, JBool, required = false, default = nil)
  if valid_602175 != nil:
    section.add "AutoCreateApplication", valid_602175
  var valid_602176 = query.getOrDefault("BuildConfiguration.Image")
  valid_602176 = validateParameter(valid_602176, JString, required = false,
                                 default = nil)
  if valid_602176 != nil:
    section.add "BuildConfiguration.Image", valid_602176
  var valid_602177 = query.getOrDefault("Action")
  valid_602177 = validateParameter(valid_602177, JString, required = true, default = newJString(
      "CreateApplicationVersion"))
  if valid_602177 != nil:
    section.add "Action", valid_602177
  var valid_602178 = query.getOrDefault("Description")
  valid_602178 = validateParameter(valid_602178, JString, required = false,
                                 default = nil)
  if valid_602178 != nil:
    section.add "Description", valid_602178
  var valid_602179 = query.getOrDefault("SourceBundle.S3Bucket")
  valid_602179 = validateParameter(valid_602179, JString, required = false,
                                 default = nil)
  if valid_602179 != nil:
    section.add "SourceBundle.S3Bucket", valid_602179
  var valid_602180 = query.getOrDefault("SourceBuildInformation.SourceRepository")
  valid_602180 = validateParameter(valid_602180, JString, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "SourceBuildInformation.SourceRepository", valid_602180
  var valid_602181 = query.getOrDefault("BuildConfiguration.ComputeType")
  valid_602181 = validateParameter(valid_602181, JString, required = false,
                                 default = nil)
  if valid_602181 != nil:
    section.add "BuildConfiguration.ComputeType", valid_602181
  var valid_602182 = query.getOrDefault("SourceBuildInformation.SourceType")
  valid_602182 = validateParameter(valid_602182, JString, required = false,
                                 default = nil)
  if valid_602182 != nil:
    section.add "SourceBuildInformation.SourceType", valid_602182
  var valid_602183 = query.getOrDefault("BuildConfiguration.ArtifactName")
  valid_602183 = validateParameter(valid_602183, JString, required = false,
                                 default = nil)
  if valid_602183 != nil:
    section.add "BuildConfiguration.ArtifactName", valid_602183
  var valid_602184 = query.getOrDefault("Version")
  valid_602184 = validateParameter(valid_602184, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602184 != nil:
    section.add "Version", valid_602184
  var valid_602185 = query.getOrDefault("SourceBundle.S3Key")
  valid_602185 = validateParameter(valid_602185, JString, required = false,
                                 default = nil)
  if valid_602185 != nil:
    section.add "SourceBundle.S3Key", valid_602185
  var valid_602186 = query.getOrDefault("BuildConfiguration.CodeBuildServiceRole")
  valid_602186 = validateParameter(valid_602186, JString, required = false,
                                 default = nil)
  if valid_602186 != nil:
    section.add "BuildConfiguration.CodeBuildServiceRole", valid_602186
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
  var valid_602187 = header.getOrDefault("X-Amz-Signature")
  valid_602187 = validateParameter(valid_602187, JString, required = false,
                                 default = nil)
  if valid_602187 != nil:
    section.add "X-Amz-Signature", valid_602187
  var valid_602188 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602188 = validateParameter(valid_602188, JString, required = false,
                                 default = nil)
  if valid_602188 != nil:
    section.add "X-Amz-Content-Sha256", valid_602188
  var valid_602189 = header.getOrDefault("X-Amz-Date")
  valid_602189 = validateParameter(valid_602189, JString, required = false,
                                 default = nil)
  if valid_602189 != nil:
    section.add "X-Amz-Date", valid_602189
  var valid_602190 = header.getOrDefault("X-Amz-Credential")
  valid_602190 = validateParameter(valid_602190, JString, required = false,
                                 default = nil)
  if valid_602190 != nil:
    section.add "X-Amz-Credential", valid_602190
  var valid_602191 = header.getOrDefault("X-Amz-Security-Token")
  valid_602191 = validateParameter(valid_602191, JString, required = false,
                                 default = nil)
  if valid_602191 != nil:
    section.add "X-Amz-Security-Token", valid_602191
  var valid_602192 = header.getOrDefault("X-Amz-Algorithm")
  valid_602192 = validateParameter(valid_602192, JString, required = false,
                                 default = nil)
  if valid_602192 != nil:
    section.add "X-Amz-Algorithm", valid_602192
  var valid_602193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602193 = validateParameter(valid_602193, JString, required = false,
                                 default = nil)
  if valid_602193 != nil:
    section.add "X-Amz-SignedHeaders", valid_602193
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602194: Call_GetCreateApplicationVersion_602166; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an application version for the specified application. You can create an application version from a source bundle in Amazon S3, a commit in AWS CodeCommit, or the output of an AWS CodeBuild build as follows:</p> <p>Specify a commit in an AWS CodeCommit repository with <code>SourceBuildInformation</code>.</p> <p>Specify a build in an AWS CodeBuild with <code>SourceBuildInformation</code> and <code>BuildConfiguration</code>.</p> <p>Specify a source bundle in S3 with <code>SourceBundle</code> </p> <p>Omit both <code>SourceBuildInformation</code> and <code>SourceBundle</code> to use the default sample application.</p> <note> <p>Once you create an application version with a specified Amazon S3 bucket and key location, you cannot change that Amazon S3 location. If you change the Amazon S3 location, you receive an exception when you attempt to launch an environment from the application version.</p> </note>
  ## 
  let valid = call_602194.validator(path, query, header, formData, body)
  let scheme = call_602194.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602194.url(scheme.get, call_602194.host, call_602194.base,
                         call_602194.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602194, url, valid)

proc call*(call_602195: Call_GetCreateApplicationVersion_602166;
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
  var query_602196 = newJObject()
  add(query_602196, "ApplicationName", newJString(ApplicationName))
  add(query_602196, "BuildConfiguration.TimeoutInMinutes",
      newJString(BuildConfigurationTimeoutInMinutes))
  add(query_602196, "Process", newJBool(Process))
  add(query_602196, "SourceBuildInformation.SourceLocation",
      newJString(SourceBuildInformationSourceLocation))
  add(query_602196, "VersionLabel", newJString(VersionLabel))
  if Tags != nil:
    query_602196.add "Tags", Tags
  add(query_602196, "AutoCreateApplication", newJBool(AutoCreateApplication))
  add(query_602196, "BuildConfiguration.Image",
      newJString(BuildConfigurationImage))
  add(query_602196, "Action", newJString(Action))
  add(query_602196, "Description", newJString(Description))
  add(query_602196, "SourceBundle.S3Bucket", newJString(SourceBundleS3Bucket))
  add(query_602196, "SourceBuildInformation.SourceRepository",
      newJString(SourceBuildInformationSourceRepository))
  add(query_602196, "BuildConfiguration.ComputeType",
      newJString(BuildConfigurationComputeType))
  add(query_602196, "SourceBuildInformation.SourceType",
      newJString(SourceBuildInformationSourceType))
  add(query_602196, "BuildConfiguration.ArtifactName",
      newJString(BuildConfigurationArtifactName))
  add(query_602196, "Version", newJString(Version))
  add(query_602196, "SourceBundle.S3Key", newJString(SourceBundleS3Key))
  add(query_602196, "BuildConfiguration.CodeBuildServiceRole",
      newJString(BuildConfigurationCodeBuildServiceRole))
  result = call_602195.call(nil, query_602196, nil, nil, nil)

var getCreateApplicationVersion* = Call_GetCreateApplicationVersion_602166(
    name: "getCreateApplicationVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateApplicationVersion",
    validator: validate_GetCreateApplicationVersion_602167, base: "/",
    url: url_GetCreateApplicationVersion_602168,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateConfigurationTemplate_602254 = ref object of OpenApiRestCall_601390
proc url_PostCreateConfigurationTemplate_602256(protocol: Scheme; host: string;
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

proc validate_PostCreateConfigurationTemplate_602255(path: JsonNode;
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
  var valid_602257 = query.getOrDefault("Action")
  valid_602257 = validateParameter(valid_602257, JString, required = true, default = newJString(
      "CreateConfigurationTemplate"))
  if valid_602257 != nil:
    section.add "Action", valid_602257
  var valid_602258 = query.getOrDefault("Version")
  valid_602258 = validateParameter(valid_602258, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602258 != nil:
    section.add "Version", valid_602258
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
  var valid_602259 = header.getOrDefault("X-Amz-Signature")
  valid_602259 = validateParameter(valid_602259, JString, required = false,
                                 default = nil)
  if valid_602259 != nil:
    section.add "X-Amz-Signature", valid_602259
  var valid_602260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602260 = validateParameter(valid_602260, JString, required = false,
                                 default = nil)
  if valid_602260 != nil:
    section.add "X-Amz-Content-Sha256", valid_602260
  var valid_602261 = header.getOrDefault("X-Amz-Date")
  valid_602261 = validateParameter(valid_602261, JString, required = false,
                                 default = nil)
  if valid_602261 != nil:
    section.add "X-Amz-Date", valid_602261
  var valid_602262 = header.getOrDefault("X-Amz-Credential")
  valid_602262 = validateParameter(valid_602262, JString, required = false,
                                 default = nil)
  if valid_602262 != nil:
    section.add "X-Amz-Credential", valid_602262
  var valid_602263 = header.getOrDefault("X-Amz-Security-Token")
  valid_602263 = validateParameter(valid_602263, JString, required = false,
                                 default = nil)
  if valid_602263 != nil:
    section.add "X-Amz-Security-Token", valid_602263
  var valid_602264 = header.getOrDefault("X-Amz-Algorithm")
  valid_602264 = validateParameter(valid_602264, JString, required = false,
                                 default = nil)
  if valid_602264 != nil:
    section.add "X-Amz-Algorithm", valid_602264
  var valid_602265 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602265 = validateParameter(valid_602265, JString, required = false,
                                 default = nil)
  if valid_602265 != nil:
    section.add "X-Amz-SignedHeaders", valid_602265
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
  var valid_602266 = formData.getOrDefault("Description")
  valid_602266 = validateParameter(valid_602266, JString, required = false,
                                 default = nil)
  if valid_602266 != nil:
    section.add "Description", valid_602266
  assert formData != nil,
        "formData argument is necessary due to required `TemplateName` field"
  var valid_602267 = formData.getOrDefault("TemplateName")
  valid_602267 = validateParameter(valid_602267, JString, required = true,
                                 default = nil)
  if valid_602267 != nil:
    section.add "TemplateName", valid_602267
  var valid_602268 = formData.getOrDefault("SourceConfiguration.ApplicationName")
  valid_602268 = validateParameter(valid_602268, JString, required = false,
                                 default = nil)
  if valid_602268 != nil:
    section.add "SourceConfiguration.ApplicationName", valid_602268
  var valid_602269 = formData.getOrDefault("SourceConfiguration.TemplateName")
  valid_602269 = validateParameter(valid_602269, JString, required = false,
                                 default = nil)
  if valid_602269 != nil:
    section.add "SourceConfiguration.TemplateName", valid_602269
  var valid_602270 = formData.getOrDefault("OptionSettings")
  valid_602270 = validateParameter(valid_602270, JArray, required = false,
                                 default = nil)
  if valid_602270 != nil:
    section.add "OptionSettings", valid_602270
  var valid_602271 = formData.getOrDefault("ApplicationName")
  valid_602271 = validateParameter(valid_602271, JString, required = true,
                                 default = nil)
  if valid_602271 != nil:
    section.add "ApplicationName", valid_602271
  var valid_602272 = formData.getOrDefault("Tags")
  valid_602272 = validateParameter(valid_602272, JArray, required = false,
                                 default = nil)
  if valid_602272 != nil:
    section.add "Tags", valid_602272
  var valid_602273 = formData.getOrDefault("SolutionStackName")
  valid_602273 = validateParameter(valid_602273, JString, required = false,
                                 default = nil)
  if valid_602273 != nil:
    section.add "SolutionStackName", valid_602273
  var valid_602274 = formData.getOrDefault("EnvironmentId")
  valid_602274 = validateParameter(valid_602274, JString, required = false,
                                 default = nil)
  if valid_602274 != nil:
    section.add "EnvironmentId", valid_602274
  var valid_602275 = formData.getOrDefault("PlatformArn")
  valid_602275 = validateParameter(valid_602275, JString, required = false,
                                 default = nil)
  if valid_602275 != nil:
    section.add "PlatformArn", valid_602275
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602276: Call_PostCreateConfigurationTemplate_602254;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Creates a configuration template. Templates are associated with a specific application and are used to deploy different versions of the application with the same configuration settings.</p> <p>Templates aren't associated with any environment. The <code>EnvironmentName</code> response element is always <code>null</code>.</p> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> <li> <p> <a>DescribeConfigurationSettings</a> </p> </li> <li> <p> <a>ListAvailableSolutionStacks</a> </p> </li> </ul>
  ## 
  let valid = call_602276.validator(path, query, header, formData, body)
  let scheme = call_602276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602276.url(scheme.get, call_602276.host, call_602276.base,
                         call_602276.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602276, url, valid)

proc call*(call_602277: Call_PostCreateConfigurationTemplate_602254;
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
  var query_602278 = newJObject()
  var formData_602279 = newJObject()
  add(formData_602279, "Description", newJString(Description))
  add(formData_602279, "TemplateName", newJString(TemplateName))
  add(formData_602279, "SourceConfiguration.ApplicationName",
      newJString(SourceConfigurationApplicationName))
  add(formData_602279, "SourceConfiguration.TemplateName",
      newJString(SourceConfigurationTemplateName))
  if OptionSettings != nil:
    formData_602279.add "OptionSettings", OptionSettings
  add(formData_602279, "ApplicationName", newJString(ApplicationName))
  add(query_602278, "Action", newJString(Action))
  if Tags != nil:
    formData_602279.add "Tags", Tags
  add(formData_602279, "SolutionStackName", newJString(SolutionStackName))
  add(formData_602279, "EnvironmentId", newJString(EnvironmentId))
  add(query_602278, "Version", newJString(Version))
  add(formData_602279, "PlatformArn", newJString(PlatformArn))
  result = call_602277.call(nil, query_602278, nil, formData_602279, nil)

var postCreateConfigurationTemplate* = Call_PostCreateConfigurationTemplate_602254(
    name: "postCreateConfigurationTemplate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateConfigurationTemplate",
    validator: validate_PostCreateConfigurationTemplate_602255, base: "/",
    url: url_PostCreateConfigurationTemplate_602256,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateConfigurationTemplate_602229 = ref object of OpenApiRestCall_601390
proc url_GetCreateConfigurationTemplate_602231(protocol: Scheme; host: string;
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

proc validate_GetCreateConfigurationTemplate_602230(path: JsonNode;
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
  var valid_602232 = query.getOrDefault("ApplicationName")
  valid_602232 = validateParameter(valid_602232, JString, required = true,
                                 default = nil)
  if valid_602232 != nil:
    section.add "ApplicationName", valid_602232
  var valid_602233 = query.getOrDefault("Tags")
  valid_602233 = validateParameter(valid_602233, JArray, required = false,
                                 default = nil)
  if valid_602233 != nil:
    section.add "Tags", valid_602233
  var valid_602234 = query.getOrDefault("OptionSettings")
  valid_602234 = validateParameter(valid_602234, JArray, required = false,
                                 default = nil)
  if valid_602234 != nil:
    section.add "OptionSettings", valid_602234
  var valid_602235 = query.getOrDefault("SourceConfiguration.TemplateName")
  valid_602235 = validateParameter(valid_602235, JString, required = false,
                                 default = nil)
  if valid_602235 != nil:
    section.add "SourceConfiguration.TemplateName", valid_602235
  var valid_602236 = query.getOrDefault("SolutionStackName")
  valid_602236 = validateParameter(valid_602236, JString, required = false,
                                 default = nil)
  if valid_602236 != nil:
    section.add "SolutionStackName", valid_602236
  var valid_602237 = query.getOrDefault("Action")
  valid_602237 = validateParameter(valid_602237, JString, required = true, default = newJString(
      "CreateConfigurationTemplate"))
  if valid_602237 != nil:
    section.add "Action", valid_602237
  var valid_602238 = query.getOrDefault("Description")
  valid_602238 = validateParameter(valid_602238, JString, required = false,
                                 default = nil)
  if valid_602238 != nil:
    section.add "Description", valid_602238
  var valid_602239 = query.getOrDefault("PlatformArn")
  valid_602239 = validateParameter(valid_602239, JString, required = false,
                                 default = nil)
  if valid_602239 != nil:
    section.add "PlatformArn", valid_602239
  var valid_602240 = query.getOrDefault("Version")
  valid_602240 = validateParameter(valid_602240, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602240 != nil:
    section.add "Version", valid_602240
  var valid_602241 = query.getOrDefault("TemplateName")
  valid_602241 = validateParameter(valid_602241, JString, required = true,
                                 default = nil)
  if valid_602241 != nil:
    section.add "TemplateName", valid_602241
  var valid_602242 = query.getOrDefault("SourceConfiguration.ApplicationName")
  valid_602242 = validateParameter(valid_602242, JString, required = false,
                                 default = nil)
  if valid_602242 != nil:
    section.add "SourceConfiguration.ApplicationName", valid_602242
  var valid_602243 = query.getOrDefault("EnvironmentId")
  valid_602243 = validateParameter(valid_602243, JString, required = false,
                                 default = nil)
  if valid_602243 != nil:
    section.add "EnvironmentId", valid_602243
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
  var valid_602244 = header.getOrDefault("X-Amz-Signature")
  valid_602244 = validateParameter(valid_602244, JString, required = false,
                                 default = nil)
  if valid_602244 != nil:
    section.add "X-Amz-Signature", valid_602244
  var valid_602245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602245 = validateParameter(valid_602245, JString, required = false,
                                 default = nil)
  if valid_602245 != nil:
    section.add "X-Amz-Content-Sha256", valid_602245
  var valid_602246 = header.getOrDefault("X-Amz-Date")
  valid_602246 = validateParameter(valid_602246, JString, required = false,
                                 default = nil)
  if valid_602246 != nil:
    section.add "X-Amz-Date", valid_602246
  var valid_602247 = header.getOrDefault("X-Amz-Credential")
  valid_602247 = validateParameter(valid_602247, JString, required = false,
                                 default = nil)
  if valid_602247 != nil:
    section.add "X-Amz-Credential", valid_602247
  var valid_602248 = header.getOrDefault("X-Amz-Security-Token")
  valid_602248 = validateParameter(valid_602248, JString, required = false,
                                 default = nil)
  if valid_602248 != nil:
    section.add "X-Amz-Security-Token", valid_602248
  var valid_602249 = header.getOrDefault("X-Amz-Algorithm")
  valid_602249 = validateParameter(valid_602249, JString, required = false,
                                 default = nil)
  if valid_602249 != nil:
    section.add "X-Amz-Algorithm", valid_602249
  var valid_602250 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602250 = validateParameter(valid_602250, JString, required = false,
                                 default = nil)
  if valid_602250 != nil:
    section.add "X-Amz-SignedHeaders", valid_602250
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602251: Call_GetCreateConfigurationTemplate_602229; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a configuration template. Templates are associated with a specific application and are used to deploy different versions of the application with the same configuration settings.</p> <p>Templates aren't associated with any environment. The <code>EnvironmentName</code> response element is always <code>null</code>.</p> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> <li> <p> <a>DescribeConfigurationSettings</a> </p> </li> <li> <p> <a>ListAvailableSolutionStacks</a> </p> </li> </ul>
  ## 
  let valid = call_602251.validator(path, query, header, formData, body)
  let scheme = call_602251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602251.url(scheme.get, call_602251.host, call_602251.base,
                         call_602251.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602251, url, valid)

proc call*(call_602252: Call_GetCreateConfigurationTemplate_602229;
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
  var query_602253 = newJObject()
  add(query_602253, "ApplicationName", newJString(ApplicationName))
  if Tags != nil:
    query_602253.add "Tags", Tags
  if OptionSettings != nil:
    query_602253.add "OptionSettings", OptionSettings
  add(query_602253, "SourceConfiguration.TemplateName",
      newJString(SourceConfigurationTemplateName))
  add(query_602253, "SolutionStackName", newJString(SolutionStackName))
  add(query_602253, "Action", newJString(Action))
  add(query_602253, "Description", newJString(Description))
  add(query_602253, "PlatformArn", newJString(PlatformArn))
  add(query_602253, "Version", newJString(Version))
  add(query_602253, "TemplateName", newJString(TemplateName))
  add(query_602253, "SourceConfiguration.ApplicationName",
      newJString(SourceConfigurationApplicationName))
  add(query_602253, "EnvironmentId", newJString(EnvironmentId))
  result = call_602252.call(nil, query_602253, nil, nil, nil)

var getCreateConfigurationTemplate* = Call_GetCreateConfigurationTemplate_602229(
    name: "getCreateConfigurationTemplate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateConfigurationTemplate",
    validator: validate_GetCreateConfigurationTemplate_602230, base: "/",
    url: url_GetCreateConfigurationTemplate_602231,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEnvironment_602310 = ref object of OpenApiRestCall_601390
proc url_PostCreateEnvironment_602312(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateEnvironment_602311(path: JsonNode; query: JsonNode;
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
  var valid_602313 = query.getOrDefault("Action")
  valid_602313 = validateParameter(valid_602313, JString, required = true,
                                 default = newJString("CreateEnvironment"))
  if valid_602313 != nil:
    section.add "Action", valid_602313
  var valid_602314 = query.getOrDefault("Version")
  valid_602314 = validateParameter(valid_602314, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602314 != nil:
    section.add "Version", valid_602314
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
  var valid_602315 = header.getOrDefault("X-Amz-Signature")
  valid_602315 = validateParameter(valid_602315, JString, required = false,
                                 default = nil)
  if valid_602315 != nil:
    section.add "X-Amz-Signature", valid_602315
  var valid_602316 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602316 = validateParameter(valid_602316, JString, required = false,
                                 default = nil)
  if valid_602316 != nil:
    section.add "X-Amz-Content-Sha256", valid_602316
  var valid_602317 = header.getOrDefault("X-Amz-Date")
  valid_602317 = validateParameter(valid_602317, JString, required = false,
                                 default = nil)
  if valid_602317 != nil:
    section.add "X-Amz-Date", valid_602317
  var valid_602318 = header.getOrDefault("X-Amz-Credential")
  valid_602318 = validateParameter(valid_602318, JString, required = false,
                                 default = nil)
  if valid_602318 != nil:
    section.add "X-Amz-Credential", valid_602318
  var valid_602319 = header.getOrDefault("X-Amz-Security-Token")
  valid_602319 = validateParameter(valid_602319, JString, required = false,
                                 default = nil)
  if valid_602319 != nil:
    section.add "X-Amz-Security-Token", valid_602319
  var valid_602320 = header.getOrDefault("X-Amz-Algorithm")
  valid_602320 = validateParameter(valid_602320, JString, required = false,
                                 default = nil)
  if valid_602320 != nil:
    section.add "X-Amz-Algorithm", valid_602320
  var valid_602321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602321 = validateParameter(valid_602321, JString, required = false,
                                 default = nil)
  if valid_602321 != nil:
    section.add "X-Amz-SignedHeaders", valid_602321
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
  var valid_602322 = formData.getOrDefault("Description")
  valid_602322 = validateParameter(valid_602322, JString, required = false,
                                 default = nil)
  if valid_602322 != nil:
    section.add "Description", valid_602322
  var valid_602323 = formData.getOrDefault("Tier.Type")
  valid_602323 = validateParameter(valid_602323, JString, required = false,
                                 default = nil)
  if valid_602323 != nil:
    section.add "Tier.Type", valid_602323
  var valid_602324 = formData.getOrDefault("EnvironmentName")
  valid_602324 = validateParameter(valid_602324, JString, required = false,
                                 default = nil)
  if valid_602324 != nil:
    section.add "EnvironmentName", valid_602324
  var valid_602325 = formData.getOrDefault("CNAMEPrefix")
  valid_602325 = validateParameter(valid_602325, JString, required = false,
                                 default = nil)
  if valid_602325 != nil:
    section.add "CNAMEPrefix", valid_602325
  var valid_602326 = formData.getOrDefault("VersionLabel")
  valid_602326 = validateParameter(valid_602326, JString, required = false,
                                 default = nil)
  if valid_602326 != nil:
    section.add "VersionLabel", valid_602326
  var valid_602327 = formData.getOrDefault("TemplateName")
  valid_602327 = validateParameter(valid_602327, JString, required = false,
                                 default = nil)
  if valid_602327 != nil:
    section.add "TemplateName", valid_602327
  var valid_602328 = formData.getOrDefault("OptionsToRemove")
  valid_602328 = validateParameter(valid_602328, JArray, required = false,
                                 default = nil)
  if valid_602328 != nil:
    section.add "OptionsToRemove", valid_602328
  var valid_602329 = formData.getOrDefault("OptionSettings")
  valid_602329 = validateParameter(valid_602329, JArray, required = false,
                                 default = nil)
  if valid_602329 != nil:
    section.add "OptionSettings", valid_602329
  var valid_602330 = formData.getOrDefault("GroupName")
  valid_602330 = validateParameter(valid_602330, JString, required = false,
                                 default = nil)
  if valid_602330 != nil:
    section.add "GroupName", valid_602330
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_602331 = formData.getOrDefault("ApplicationName")
  valid_602331 = validateParameter(valid_602331, JString, required = true,
                                 default = nil)
  if valid_602331 != nil:
    section.add "ApplicationName", valid_602331
  var valid_602332 = formData.getOrDefault("Tier.Name")
  valid_602332 = validateParameter(valid_602332, JString, required = false,
                                 default = nil)
  if valid_602332 != nil:
    section.add "Tier.Name", valid_602332
  var valid_602333 = formData.getOrDefault("Tier.Version")
  valid_602333 = validateParameter(valid_602333, JString, required = false,
                                 default = nil)
  if valid_602333 != nil:
    section.add "Tier.Version", valid_602333
  var valid_602334 = formData.getOrDefault("Tags")
  valid_602334 = validateParameter(valid_602334, JArray, required = false,
                                 default = nil)
  if valid_602334 != nil:
    section.add "Tags", valid_602334
  var valid_602335 = formData.getOrDefault("SolutionStackName")
  valid_602335 = validateParameter(valid_602335, JString, required = false,
                                 default = nil)
  if valid_602335 != nil:
    section.add "SolutionStackName", valid_602335
  var valid_602336 = formData.getOrDefault("PlatformArn")
  valid_602336 = validateParameter(valid_602336, JString, required = false,
                                 default = nil)
  if valid_602336 != nil:
    section.add "PlatformArn", valid_602336
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602337: Call_PostCreateEnvironment_602310; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Launches an environment for the specified application using the specified configuration.
  ## 
  let valid = call_602337.validator(path, query, header, formData, body)
  let scheme = call_602337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602337.url(scheme.get, call_602337.host, call_602337.base,
                         call_602337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602337, url, valid)

proc call*(call_602338: Call_PostCreateEnvironment_602310; ApplicationName: string;
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
  var query_602339 = newJObject()
  var formData_602340 = newJObject()
  add(formData_602340, "Description", newJString(Description))
  add(formData_602340, "Tier.Type", newJString(TierType))
  add(formData_602340, "EnvironmentName", newJString(EnvironmentName))
  add(formData_602340, "CNAMEPrefix", newJString(CNAMEPrefix))
  add(formData_602340, "VersionLabel", newJString(VersionLabel))
  add(formData_602340, "TemplateName", newJString(TemplateName))
  if OptionsToRemove != nil:
    formData_602340.add "OptionsToRemove", OptionsToRemove
  if OptionSettings != nil:
    formData_602340.add "OptionSettings", OptionSettings
  add(formData_602340, "GroupName", newJString(GroupName))
  add(formData_602340, "ApplicationName", newJString(ApplicationName))
  add(formData_602340, "Tier.Name", newJString(TierName))
  add(formData_602340, "Tier.Version", newJString(TierVersion))
  add(query_602339, "Action", newJString(Action))
  if Tags != nil:
    formData_602340.add "Tags", Tags
  add(formData_602340, "SolutionStackName", newJString(SolutionStackName))
  add(query_602339, "Version", newJString(Version))
  add(formData_602340, "PlatformArn", newJString(PlatformArn))
  result = call_602338.call(nil, query_602339, nil, formData_602340, nil)

var postCreateEnvironment* = Call_PostCreateEnvironment_602310(
    name: "postCreateEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateEnvironment",
    validator: validate_PostCreateEnvironment_602311, base: "/",
    url: url_PostCreateEnvironment_602312, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEnvironment_602280 = ref object of OpenApiRestCall_601390
proc url_GetCreateEnvironment_602282(protocol: Scheme; host: string; base: string;
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

proc validate_GetCreateEnvironment_602281(path: JsonNode; query: JsonNode;
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
  var valid_602283 = query.getOrDefault("ApplicationName")
  valid_602283 = validateParameter(valid_602283, JString, required = true,
                                 default = nil)
  if valid_602283 != nil:
    section.add "ApplicationName", valid_602283
  var valid_602284 = query.getOrDefault("CNAMEPrefix")
  valid_602284 = validateParameter(valid_602284, JString, required = false,
                                 default = nil)
  if valid_602284 != nil:
    section.add "CNAMEPrefix", valid_602284
  var valid_602285 = query.getOrDefault("GroupName")
  valid_602285 = validateParameter(valid_602285, JString, required = false,
                                 default = nil)
  if valid_602285 != nil:
    section.add "GroupName", valid_602285
  var valid_602286 = query.getOrDefault("Tags")
  valid_602286 = validateParameter(valid_602286, JArray, required = false,
                                 default = nil)
  if valid_602286 != nil:
    section.add "Tags", valid_602286
  var valid_602287 = query.getOrDefault("VersionLabel")
  valid_602287 = validateParameter(valid_602287, JString, required = false,
                                 default = nil)
  if valid_602287 != nil:
    section.add "VersionLabel", valid_602287
  var valid_602288 = query.getOrDefault("OptionSettings")
  valid_602288 = validateParameter(valid_602288, JArray, required = false,
                                 default = nil)
  if valid_602288 != nil:
    section.add "OptionSettings", valid_602288
  var valid_602289 = query.getOrDefault("SolutionStackName")
  valid_602289 = validateParameter(valid_602289, JString, required = false,
                                 default = nil)
  if valid_602289 != nil:
    section.add "SolutionStackName", valid_602289
  var valid_602290 = query.getOrDefault("Tier.Name")
  valid_602290 = validateParameter(valid_602290, JString, required = false,
                                 default = nil)
  if valid_602290 != nil:
    section.add "Tier.Name", valid_602290
  var valid_602291 = query.getOrDefault("EnvironmentName")
  valid_602291 = validateParameter(valid_602291, JString, required = false,
                                 default = nil)
  if valid_602291 != nil:
    section.add "EnvironmentName", valid_602291
  var valid_602292 = query.getOrDefault("Action")
  valid_602292 = validateParameter(valid_602292, JString, required = true,
                                 default = newJString("CreateEnvironment"))
  if valid_602292 != nil:
    section.add "Action", valid_602292
  var valid_602293 = query.getOrDefault("Description")
  valid_602293 = validateParameter(valid_602293, JString, required = false,
                                 default = nil)
  if valid_602293 != nil:
    section.add "Description", valid_602293
  var valid_602294 = query.getOrDefault("PlatformArn")
  valid_602294 = validateParameter(valid_602294, JString, required = false,
                                 default = nil)
  if valid_602294 != nil:
    section.add "PlatformArn", valid_602294
  var valid_602295 = query.getOrDefault("OptionsToRemove")
  valid_602295 = validateParameter(valid_602295, JArray, required = false,
                                 default = nil)
  if valid_602295 != nil:
    section.add "OptionsToRemove", valid_602295
  var valid_602296 = query.getOrDefault("Version")
  valid_602296 = validateParameter(valid_602296, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602296 != nil:
    section.add "Version", valid_602296
  var valid_602297 = query.getOrDefault("TemplateName")
  valid_602297 = validateParameter(valid_602297, JString, required = false,
                                 default = nil)
  if valid_602297 != nil:
    section.add "TemplateName", valid_602297
  var valid_602298 = query.getOrDefault("Tier.Version")
  valid_602298 = validateParameter(valid_602298, JString, required = false,
                                 default = nil)
  if valid_602298 != nil:
    section.add "Tier.Version", valid_602298
  var valid_602299 = query.getOrDefault("Tier.Type")
  valid_602299 = validateParameter(valid_602299, JString, required = false,
                                 default = nil)
  if valid_602299 != nil:
    section.add "Tier.Type", valid_602299
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
  var valid_602300 = header.getOrDefault("X-Amz-Signature")
  valid_602300 = validateParameter(valid_602300, JString, required = false,
                                 default = nil)
  if valid_602300 != nil:
    section.add "X-Amz-Signature", valid_602300
  var valid_602301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602301 = validateParameter(valid_602301, JString, required = false,
                                 default = nil)
  if valid_602301 != nil:
    section.add "X-Amz-Content-Sha256", valid_602301
  var valid_602302 = header.getOrDefault("X-Amz-Date")
  valid_602302 = validateParameter(valid_602302, JString, required = false,
                                 default = nil)
  if valid_602302 != nil:
    section.add "X-Amz-Date", valid_602302
  var valid_602303 = header.getOrDefault("X-Amz-Credential")
  valid_602303 = validateParameter(valid_602303, JString, required = false,
                                 default = nil)
  if valid_602303 != nil:
    section.add "X-Amz-Credential", valid_602303
  var valid_602304 = header.getOrDefault("X-Amz-Security-Token")
  valid_602304 = validateParameter(valid_602304, JString, required = false,
                                 default = nil)
  if valid_602304 != nil:
    section.add "X-Amz-Security-Token", valid_602304
  var valid_602305 = header.getOrDefault("X-Amz-Algorithm")
  valid_602305 = validateParameter(valid_602305, JString, required = false,
                                 default = nil)
  if valid_602305 != nil:
    section.add "X-Amz-Algorithm", valid_602305
  var valid_602306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602306 = validateParameter(valid_602306, JString, required = false,
                                 default = nil)
  if valid_602306 != nil:
    section.add "X-Amz-SignedHeaders", valid_602306
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602307: Call_GetCreateEnvironment_602280; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Launches an environment for the specified application using the specified configuration.
  ## 
  let valid = call_602307.validator(path, query, header, formData, body)
  let scheme = call_602307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602307.url(scheme.get, call_602307.host, call_602307.base,
                         call_602307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602307, url, valid)

proc call*(call_602308: Call_GetCreateEnvironment_602280; ApplicationName: string;
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
  var query_602309 = newJObject()
  add(query_602309, "ApplicationName", newJString(ApplicationName))
  add(query_602309, "CNAMEPrefix", newJString(CNAMEPrefix))
  add(query_602309, "GroupName", newJString(GroupName))
  if Tags != nil:
    query_602309.add "Tags", Tags
  add(query_602309, "VersionLabel", newJString(VersionLabel))
  if OptionSettings != nil:
    query_602309.add "OptionSettings", OptionSettings
  add(query_602309, "SolutionStackName", newJString(SolutionStackName))
  add(query_602309, "Tier.Name", newJString(TierName))
  add(query_602309, "EnvironmentName", newJString(EnvironmentName))
  add(query_602309, "Action", newJString(Action))
  add(query_602309, "Description", newJString(Description))
  add(query_602309, "PlatformArn", newJString(PlatformArn))
  if OptionsToRemove != nil:
    query_602309.add "OptionsToRemove", OptionsToRemove
  add(query_602309, "Version", newJString(Version))
  add(query_602309, "TemplateName", newJString(TemplateName))
  add(query_602309, "Tier.Version", newJString(TierVersion))
  add(query_602309, "Tier.Type", newJString(TierType))
  result = call_602308.call(nil, query_602309, nil, nil, nil)

var getCreateEnvironment* = Call_GetCreateEnvironment_602280(
    name: "getCreateEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=CreateEnvironment",
    validator: validate_GetCreateEnvironment_602281, base: "/",
    url: url_GetCreateEnvironment_602282, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreatePlatformVersion_602363 = ref object of OpenApiRestCall_601390
proc url_PostCreatePlatformVersion_602365(protocol: Scheme; host: string;
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

proc validate_PostCreatePlatformVersion_602364(path: JsonNode; query: JsonNode;
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
  var valid_602366 = query.getOrDefault("Action")
  valid_602366 = validateParameter(valid_602366, JString, required = true,
                                 default = newJString("CreatePlatformVersion"))
  if valid_602366 != nil:
    section.add "Action", valid_602366
  var valid_602367 = query.getOrDefault("Version")
  valid_602367 = validateParameter(valid_602367, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602367 != nil:
    section.add "Version", valid_602367
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
  var valid_602368 = header.getOrDefault("X-Amz-Signature")
  valid_602368 = validateParameter(valid_602368, JString, required = false,
                                 default = nil)
  if valid_602368 != nil:
    section.add "X-Amz-Signature", valid_602368
  var valid_602369 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602369 = validateParameter(valid_602369, JString, required = false,
                                 default = nil)
  if valid_602369 != nil:
    section.add "X-Amz-Content-Sha256", valid_602369
  var valid_602370 = header.getOrDefault("X-Amz-Date")
  valid_602370 = validateParameter(valid_602370, JString, required = false,
                                 default = nil)
  if valid_602370 != nil:
    section.add "X-Amz-Date", valid_602370
  var valid_602371 = header.getOrDefault("X-Amz-Credential")
  valid_602371 = validateParameter(valid_602371, JString, required = false,
                                 default = nil)
  if valid_602371 != nil:
    section.add "X-Amz-Credential", valid_602371
  var valid_602372 = header.getOrDefault("X-Amz-Security-Token")
  valid_602372 = validateParameter(valid_602372, JString, required = false,
                                 default = nil)
  if valid_602372 != nil:
    section.add "X-Amz-Security-Token", valid_602372
  var valid_602373 = header.getOrDefault("X-Amz-Algorithm")
  valid_602373 = validateParameter(valid_602373, JString, required = false,
                                 default = nil)
  if valid_602373 != nil:
    section.add "X-Amz-Algorithm", valid_602373
  var valid_602374 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602374 = validateParameter(valid_602374, JString, required = false,
                                 default = nil)
  if valid_602374 != nil:
    section.add "X-Amz-SignedHeaders", valid_602374
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
  var valid_602375 = formData.getOrDefault("EnvironmentName")
  valid_602375 = validateParameter(valid_602375, JString, required = false,
                                 default = nil)
  if valid_602375 != nil:
    section.add "EnvironmentName", valid_602375
  var valid_602376 = formData.getOrDefault("PlatformDefinitionBundle.S3Key")
  valid_602376 = validateParameter(valid_602376, JString, required = false,
                                 default = nil)
  if valid_602376 != nil:
    section.add "PlatformDefinitionBundle.S3Key", valid_602376
  assert formData != nil, "formData argument is necessary due to required `PlatformVersion` field"
  var valid_602377 = formData.getOrDefault("PlatformVersion")
  valid_602377 = validateParameter(valid_602377, JString, required = true,
                                 default = nil)
  if valid_602377 != nil:
    section.add "PlatformVersion", valid_602377
  var valid_602378 = formData.getOrDefault("OptionSettings")
  valid_602378 = validateParameter(valid_602378, JArray, required = false,
                                 default = nil)
  if valid_602378 != nil:
    section.add "OptionSettings", valid_602378
  var valid_602379 = formData.getOrDefault("Tags")
  valid_602379 = validateParameter(valid_602379, JArray, required = false,
                                 default = nil)
  if valid_602379 != nil:
    section.add "Tags", valid_602379
  var valid_602380 = formData.getOrDefault("PlatformDefinitionBundle.S3Bucket")
  valid_602380 = validateParameter(valid_602380, JString, required = false,
                                 default = nil)
  if valid_602380 != nil:
    section.add "PlatformDefinitionBundle.S3Bucket", valid_602380
  var valid_602381 = formData.getOrDefault("PlatformName")
  valid_602381 = validateParameter(valid_602381, JString, required = true,
                                 default = nil)
  if valid_602381 != nil:
    section.add "PlatformName", valid_602381
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602382: Call_PostCreatePlatformVersion_602363; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new version of your custom platform.
  ## 
  let valid = call_602382.validator(path, query, header, formData, body)
  let scheme = call_602382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602382.url(scheme.get, call_602382.host, call_602382.base,
                         call_602382.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602382, url, valid)

proc call*(call_602383: Call_PostCreatePlatformVersion_602363;
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
  var query_602384 = newJObject()
  var formData_602385 = newJObject()
  add(formData_602385, "EnvironmentName", newJString(EnvironmentName))
  add(formData_602385, "PlatformDefinitionBundle.S3Key",
      newJString(PlatformDefinitionBundleS3Key))
  add(formData_602385, "PlatformVersion", newJString(PlatformVersion))
  if OptionSettings != nil:
    formData_602385.add "OptionSettings", OptionSettings
  add(query_602384, "Action", newJString(Action))
  if Tags != nil:
    formData_602385.add "Tags", Tags
  add(formData_602385, "PlatformDefinitionBundle.S3Bucket",
      newJString(PlatformDefinitionBundleS3Bucket))
  add(query_602384, "Version", newJString(Version))
  add(formData_602385, "PlatformName", newJString(PlatformName))
  result = call_602383.call(nil, query_602384, nil, formData_602385, nil)

var postCreatePlatformVersion* = Call_PostCreatePlatformVersion_602363(
    name: "postCreatePlatformVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreatePlatformVersion",
    validator: validate_PostCreatePlatformVersion_602364, base: "/",
    url: url_PostCreatePlatformVersion_602365,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreatePlatformVersion_602341 = ref object of OpenApiRestCall_601390
proc url_GetCreatePlatformVersion_602343(protocol: Scheme; host: string;
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

proc validate_GetCreatePlatformVersion_602342(path: JsonNode; query: JsonNode;
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
  var valid_602344 = query.getOrDefault("PlatformName")
  valid_602344 = validateParameter(valid_602344, JString, required = true,
                                 default = nil)
  if valid_602344 != nil:
    section.add "PlatformName", valid_602344
  var valid_602345 = query.getOrDefault("PlatformVersion")
  valid_602345 = validateParameter(valid_602345, JString, required = true,
                                 default = nil)
  if valid_602345 != nil:
    section.add "PlatformVersion", valid_602345
  var valid_602346 = query.getOrDefault("Tags")
  valid_602346 = validateParameter(valid_602346, JArray, required = false,
                                 default = nil)
  if valid_602346 != nil:
    section.add "Tags", valid_602346
  var valid_602347 = query.getOrDefault("OptionSettings")
  valid_602347 = validateParameter(valid_602347, JArray, required = false,
                                 default = nil)
  if valid_602347 != nil:
    section.add "OptionSettings", valid_602347
  var valid_602348 = query.getOrDefault("PlatformDefinitionBundle.S3Bucket")
  valid_602348 = validateParameter(valid_602348, JString, required = false,
                                 default = nil)
  if valid_602348 != nil:
    section.add "PlatformDefinitionBundle.S3Bucket", valid_602348
  var valid_602349 = query.getOrDefault("EnvironmentName")
  valid_602349 = validateParameter(valid_602349, JString, required = false,
                                 default = nil)
  if valid_602349 != nil:
    section.add "EnvironmentName", valid_602349
  var valid_602350 = query.getOrDefault("Action")
  valid_602350 = validateParameter(valid_602350, JString, required = true,
                                 default = newJString("CreatePlatformVersion"))
  if valid_602350 != nil:
    section.add "Action", valid_602350
  var valid_602351 = query.getOrDefault("PlatformDefinitionBundle.S3Key")
  valid_602351 = validateParameter(valid_602351, JString, required = false,
                                 default = nil)
  if valid_602351 != nil:
    section.add "PlatformDefinitionBundle.S3Key", valid_602351
  var valid_602352 = query.getOrDefault("Version")
  valid_602352 = validateParameter(valid_602352, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602352 != nil:
    section.add "Version", valid_602352
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
  var valid_602353 = header.getOrDefault("X-Amz-Signature")
  valid_602353 = validateParameter(valid_602353, JString, required = false,
                                 default = nil)
  if valid_602353 != nil:
    section.add "X-Amz-Signature", valid_602353
  var valid_602354 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602354 = validateParameter(valid_602354, JString, required = false,
                                 default = nil)
  if valid_602354 != nil:
    section.add "X-Amz-Content-Sha256", valid_602354
  var valid_602355 = header.getOrDefault("X-Amz-Date")
  valid_602355 = validateParameter(valid_602355, JString, required = false,
                                 default = nil)
  if valid_602355 != nil:
    section.add "X-Amz-Date", valid_602355
  var valid_602356 = header.getOrDefault("X-Amz-Credential")
  valid_602356 = validateParameter(valid_602356, JString, required = false,
                                 default = nil)
  if valid_602356 != nil:
    section.add "X-Amz-Credential", valid_602356
  var valid_602357 = header.getOrDefault("X-Amz-Security-Token")
  valid_602357 = validateParameter(valid_602357, JString, required = false,
                                 default = nil)
  if valid_602357 != nil:
    section.add "X-Amz-Security-Token", valid_602357
  var valid_602358 = header.getOrDefault("X-Amz-Algorithm")
  valid_602358 = validateParameter(valid_602358, JString, required = false,
                                 default = nil)
  if valid_602358 != nil:
    section.add "X-Amz-Algorithm", valid_602358
  var valid_602359 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602359 = validateParameter(valid_602359, JString, required = false,
                                 default = nil)
  if valid_602359 != nil:
    section.add "X-Amz-SignedHeaders", valid_602359
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602360: Call_GetCreatePlatformVersion_602341; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new version of your custom platform.
  ## 
  let valid = call_602360.validator(path, query, header, formData, body)
  let scheme = call_602360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602360.url(scheme.get, call_602360.host, call_602360.base,
                         call_602360.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602360, url, valid)

proc call*(call_602361: Call_GetCreatePlatformVersion_602341; PlatformName: string;
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
  var query_602362 = newJObject()
  add(query_602362, "PlatformName", newJString(PlatformName))
  add(query_602362, "PlatformVersion", newJString(PlatformVersion))
  if Tags != nil:
    query_602362.add "Tags", Tags
  if OptionSettings != nil:
    query_602362.add "OptionSettings", OptionSettings
  add(query_602362, "PlatformDefinitionBundle.S3Bucket",
      newJString(PlatformDefinitionBundleS3Bucket))
  add(query_602362, "EnvironmentName", newJString(EnvironmentName))
  add(query_602362, "Action", newJString(Action))
  add(query_602362, "PlatformDefinitionBundle.S3Key",
      newJString(PlatformDefinitionBundleS3Key))
  add(query_602362, "Version", newJString(Version))
  result = call_602361.call(nil, query_602362, nil, nil, nil)

var getCreatePlatformVersion* = Call_GetCreatePlatformVersion_602341(
    name: "getCreatePlatformVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreatePlatformVersion",
    validator: validate_GetCreatePlatformVersion_602342, base: "/",
    url: url_GetCreatePlatformVersion_602343, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateStorageLocation_602401 = ref object of OpenApiRestCall_601390
proc url_PostCreateStorageLocation_602403(protocol: Scheme; host: string;
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

proc validate_PostCreateStorageLocation_602402(path: JsonNode; query: JsonNode;
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
  var valid_602404 = query.getOrDefault("Action")
  valid_602404 = validateParameter(valid_602404, JString, required = true,
                                 default = newJString("CreateStorageLocation"))
  if valid_602404 != nil:
    section.add "Action", valid_602404
  var valid_602405 = query.getOrDefault("Version")
  valid_602405 = validateParameter(valid_602405, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602405 != nil:
    section.add "Version", valid_602405
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
  var valid_602406 = header.getOrDefault("X-Amz-Signature")
  valid_602406 = validateParameter(valid_602406, JString, required = false,
                                 default = nil)
  if valid_602406 != nil:
    section.add "X-Amz-Signature", valid_602406
  var valid_602407 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602407 = validateParameter(valid_602407, JString, required = false,
                                 default = nil)
  if valid_602407 != nil:
    section.add "X-Amz-Content-Sha256", valid_602407
  var valid_602408 = header.getOrDefault("X-Amz-Date")
  valid_602408 = validateParameter(valid_602408, JString, required = false,
                                 default = nil)
  if valid_602408 != nil:
    section.add "X-Amz-Date", valid_602408
  var valid_602409 = header.getOrDefault("X-Amz-Credential")
  valid_602409 = validateParameter(valid_602409, JString, required = false,
                                 default = nil)
  if valid_602409 != nil:
    section.add "X-Amz-Credential", valid_602409
  var valid_602410 = header.getOrDefault("X-Amz-Security-Token")
  valid_602410 = validateParameter(valid_602410, JString, required = false,
                                 default = nil)
  if valid_602410 != nil:
    section.add "X-Amz-Security-Token", valid_602410
  var valid_602411 = header.getOrDefault("X-Amz-Algorithm")
  valid_602411 = validateParameter(valid_602411, JString, required = false,
                                 default = nil)
  if valid_602411 != nil:
    section.add "X-Amz-Algorithm", valid_602411
  var valid_602412 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602412 = validateParameter(valid_602412, JString, required = false,
                                 default = nil)
  if valid_602412 != nil:
    section.add "X-Amz-SignedHeaders", valid_602412
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602413: Call_PostCreateStorageLocation_602401; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ## 
  let valid = call_602413.validator(path, query, header, formData, body)
  let scheme = call_602413.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602413.url(scheme.get, call_602413.host, call_602413.base,
                         call_602413.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602413, url, valid)

proc call*(call_602414: Call_PostCreateStorageLocation_602401;
          Action: string = "CreateStorageLocation"; Version: string = "2010-12-01"): Recallable =
  ## postCreateStorageLocation
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602415 = newJObject()
  add(query_602415, "Action", newJString(Action))
  add(query_602415, "Version", newJString(Version))
  result = call_602414.call(nil, query_602415, nil, nil, nil)

var postCreateStorageLocation* = Call_PostCreateStorageLocation_602401(
    name: "postCreateStorageLocation", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateStorageLocation",
    validator: validate_PostCreateStorageLocation_602402, base: "/",
    url: url_PostCreateStorageLocation_602403,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateStorageLocation_602386 = ref object of OpenApiRestCall_601390
proc url_GetCreateStorageLocation_602388(protocol: Scheme; host: string;
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

proc validate_GetCreateStorageLocation_602387(path: JsonNode; query: JsonNode;
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
  var valid_602389 = query.getOrDefault("Action")
  valid_602389 = validateParameter(valid_602389, JString, required = true,
                                 default = newJString("CreateStorageLocation"))
  if valid_602389 != nil:
    section.add "Action", valid_602389
  var valid_602390 = query.getOrDefault("Version")
  valid_602390 = validateParameter(valid_602390, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602390 != nil:
    section.add "Version", valid_602390
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
  var valid_602391 = header.getOrDefault("X-Amz-Signature")
  valid_602391 = validateParameter(valid_602391, JString, required = false,
                                 default = nil)
  if valid_602391 != nil:
    section.add "X-Amz-Signature", valid_602391
  var valid_602392 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602392 = validateParameter(valid_602392, JString, required = false,
                                 default = nil)
  if valid_602392 != nil:
    section.add "X-Amz-Content-Sha256", valid_602392
  var valid_602393 = header.getOrDefault("X-Amz-Date")
  valid_602393 = validateParameter(valid_602393, JString, required = false,
                                 default = nil)
  if valid_602393 != nil:
    section.add "X-Amz-Date", valid_602393
  var valid_602394 = header.getOrDefault("X-Amz-Credential")
  valid_602394 = validateParameter(valid_602394, JString, required = false,
                                 default = nil)
  if valid_602394 != nil:
    section.add "X-Amz-Credential", valid_602394
  var valid_602395 = header.getOrDefault("X-Amz-Security-Token")
  valid_602395 = validateParameter(valid_602395, JString, required = false,
                                 default = nil)
  if valid_602395 != nil:
    section.add "X-Amz-Security-Token", valid_602395
  var valid_602396 = header.getOrDefault("X-Amz-Algorithm")
  valid_602396 = validateParameter(valid_602396, JString, required = false,
                                 default = nil)
  if valid_602396 != nil:
    section.add "X-Amz-Algorithm", valid_602396
  var valid_602397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602397 = validateParameter(valid_602397, JString, required = false,
                                 default = nil)
  if valid_602397 != nil:
    section.add "X-Amz-SignedHeaders", valid_602397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602398: Call_GetCreateStorageLocation_602386; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ## 
  let valid = call_602398.validator(path, query, header, formData, body)
  let scheme = call_602398.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602398.url(scheme.get, call_602398.host, call_602398.base,
                         call_602398.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602398, url, valid)

proc call*(call_602399: Call_GetCreateStorageLocation_602386;
          Action: string = "CreateStorageLocation"; Version: string = "2010-12-01"): Recallable =
  ## getCreateStorageLocation
  ## Creates a bucket in Amazon S3 to store application versions, logs, and other files used by Elastic Beanstalk environments. The Elastic Beanstalk console and EB CLI call this API the first time you create an environment in a region. If the storage location already exists, <code>CreateStorageLocation</code> still returns the bucket name but does not create a new bucket.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602400 = newJObject()
  add(query_602400, "Action", newJString(Action))
  add(query_602400, "Version", newJString(Version))
  result = call_602399.call(nil, query_602400, nil, nil, nil)

var getCreateStorageLocation* = Call_GetCreateStorageLocation_602386(
    name: "getCreateStorageLocation", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=CreateStorageLocation",
    validator: validate_GetCreateStorageLocation_602387, base: "/",
    url: url_GetCreateStorageLocation_602388, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteApplication_602433 = ref object of OpenApiRestCall_601390
proc url_PostDeleteApplication_602435(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteApplication_602434(path: JsonNode; query: JsonNode;
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
  var valid_602436 = query.getOrDefault("Action")
  valid_602436 = validateParameter(valid_602436, JString, required = true,
                                 default = newJString("DeleteApplication"))
  if valid_602436 != nil:
    section.add "Action", valid_602436
  var valid_602437 = query.getOrDefault("Version")
  valid_602437 = validateParameter(valid_602437, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602437 != nil:
    section.add "Version", valid_602437
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
  var valid_602438 = header.getOrDefault("X-Amz-Signature")
  valid_602438 = validateParameter(valid_602438, JString, required = false,
                                 default = nil)
  if valid_602438 != nil:
    section.add "X-Amz-Signature", valid_602438
  var valid_602439 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602439 = validateParameter(valid_602439, JString, required = false,
                                 default = nil)
  if valid_602439 != nil:
    section.add "X-Amz-Content-Sha256", valid_602439
  var valid_602440 = header.getOrDefault("X-Amz-Date")
  valid_602440 = validateParameter(valid_602440, JString, required = false,
                                 default = nil)
  if valid_602440 != nil:
    section.add "X-Amz-Date", valid_602440
  var valid_602441 = header.getOrDefault("X-Amz-Credential")
  valid_602441 = validateParameter(valid_602441, JString, required = false,
                                 default = nil)
  if valid_602441 != nil:
    section.add "X-Amz-Credential", valid_602441
  var valid_602442 = header.getOrDefault("X-Amz-Security-Token")
  valid_602442 = validateParameter(valid_602442, JString, required = false,
                                 default = nil)
  if valid_602442 != nil:
    section.add "X-Amz-Security-Token", valid_602442
  var valid_602443 = header.getOrDefault("X-Amz-Algorithm")
  valid_602443 = validateParameter(valid_602443, JString, required = false,
                                 default = nil)
  if valid_602443 != nil:
    section.add "X-Amz-Algorithm", valid_602443
  var valid_602444 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602444 = validateParameter(valid_602444, JString, required = false,
                                 default = nil)
  if valid_602444 != nil:
    section.add "X-Amz-SignedHeaders", valid_602444
  result.add "header", section
  ## parameters in `formData` object:
  ##   TerminateEnvByForce: JBool
  ##                      : When set to true, running environments will be terminated before deleting the application.
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to delete.
  section = newJObject()
  var valid_602445 = formData.getOrDefault("TerminateEnvByForce")
  valid_602445 = validateParameter(valid_602445, JBool, required = false, default = nil)
  if valid_602445 != nil:
    section.add "TerminateEnvByForce", valid_602445
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_602446 = formData.getOrDefault("ApplicationName")
  valid_602446 = validateParameter(valid_602446, JString, required = true,
                                 default = nil)
  if valid_602446 != nil:
    section.add "ApplicationName", valid_602446
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602447: Call_PostDeleteApplication_602433; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified application along with all associated versions and configurations. The application versions will not be deleted from your Amazon S3 bucket.</p> <note> <p>You cannot delete an application that has a running environment.</p> </note>
  ## 
  let valid = call_602447.validator(path, query, header, formData, body)
  let scheme = call_602447.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602447.url(scheme.get, call_602447.host, call_602447.base,
                         call_602447.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602447, url, valid)

proc call*(call_602448: Call_PostDeleteApplication_602433; ApplicationName: string;
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
  var query_602449 = newJObject()
  var formData_602450 = newJObject()
  add(formData_602450, "TerminateEnvByForce", newJBool(TerminateEnvByForce))
  add(formData_602450, "ApplicationName", newJString(ApplicationName))
  add(query_602449, "Action", newJString(Action))
  add(query_602449, "Version", newJString(Version))
  result = call_602448.call(nil, query_602449, nil, formData_602450, nil)

var postDeleteApplication* = Call_PostDeleteApplication_602433(
    name: "postDeleteApplication", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=DeleteApplication",
    validator: validate_PostDeleteApplication_602434, base: "/",
    url: url_PostDeleteApplication_602435, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteApplication_602416 = ref object of OpenApiRestCall_601390
proc url_GetDeleteApplication_602418(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteApplication_602417(path: JsonNode; query: JsonNode;
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
  var valid_602419 = query.getOrDefault("ApplicationName")
  valid_602419 = validateParameter(valid_602419, JString, required = true,
                                 default = nil)
  if valid_602419 != nil:
    section.add "ApplicationName", valid_602419
  var valid_602420 = query.getOrDefault("Action")
  valid_602420 = validateParameter(valid_602420, JString, required = true,
                                 default = newJString("DeleteApplication"))
  if valid_602420 != nil:
    section.add "Action", valid_602420
  var valid_602421 = query.getOrDefault("TerminateEnvByForce")
  valid_602421 = validateParameter(valid_602421, JBool, required = false, default = nil)
  if valid_602421 != nil:
    section.add "TerminateEnvByForce", valid_602421
  var valid_602422 = query.getOrDefault("Version")
  valid_602422 = validateParameter(valid_602422, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602422 != nil:
    section.add "Version", valid_602422
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
  var valid_602423 = header.getOrDefault("X-Amz-Signature")
  valid_602423 = validateParameter(valid_602423, JString, required = false,
                                 default = nil)
  if valid_602423 != nil:
    section.add "X-Amz-Signature", valid_602423
  var valid_602424 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602424 = validateParameter(valid_602424, JString, required = false,
                                 default = nil)
  if valid_602424 != nil:
    section.add "X-Amz-Content-Sha256", valid_602424
  var valid_602425 = header.getOrDefault("X-Amz-Date")
  valid_602425 = validateParameter(valid_602425, JString, required = false,
                                 default = nil)
  if valid_602425 != nil:
    section.add "X-Amz-Date", valid_602425
  var valid_602426 = header.getOrDefault("X-Amz-Credential")
  valid_602426 = validateParameter(valid_602426, JString, required = false,
                                 default = nil)
  if valid_602426 != nil:
    section.add "X-Amz-Credential", valid_602426
  var valid_602427 = header.getOrDefault("X-Amz-Security-Token")
  valid_602427 = validateParameter(valid_602427, JString, required = false,
                                 default = nil)
  if valid_602427 != nil:
    section.add "X-Amz-Security-Token", valid_602427
  var valid_602428 = header.getOrDefault("X-Amz-Algorithm")
  valid_602428 = validateParameter(valid_602428, JString, required = false,
                                 default = nil)
  if valid_602428 != nil:
    section.add "X-Amz-Algorithm", valid_602428
  var valid_602429 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602429 = validateParameter(valid_602429, JString, required = false,
                                 default = nil)
  if valid_602429 != nil:
    section.add "X-Amz-SignedHeaders", valid_602429
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602430: Call_GetDeleteApplication_602416; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified application along with all associated versions and configurations. The application versions will not be deleted from your Amazon S3 bucket.</p> <note> <p>You cannot delete an application that has a running environment.</p> </note>
  ## 
  let valid = call_602430.validator(path, query, header, formData, body)
  let scheme = call_602430.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602430.url(scheme.get, call_602430.host, call_602430.base,
                         call_602430.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602430, url, valid)

proc call*(call_602431: Call_GetDeleteApplication_602416; ApplicationName: string;
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
  var query_602432 = newJObject()
  add(query_602432, "ApplicationName", newJString(ApplicationName))
  add(query_602432, "Action", newJString(Action))
  add(query_602432, "TerminateEnvByForce", newJBool(TerminateEnvByForce))
  add(query_602432, "Version", newJString(Version))
  result = call_602431.call(nil, query_602432, nil, nil, nil)

var getDeleteApplication* = Call_GetDeleteApplication_602416(
    name: "getDeleteApplication", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=DeleteApplication",
    validator: validate_GetDeleteApplication_602417, base: "/",
    url: url_GetDeleteApplication_602418, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteApplicationVersion_602469 = ref object of OpenApiRestCall_601390
proc url_PostDeleteApplicationVersion_602471(protocol: Scheme; host: string;
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

proc validate_PostDeleteApplicationVersion_602470(path: JsonNode; query: JsonNode;
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
  var valid_602472 = query.getOrDefault("Action")
  valid_602472 = validateParameter(valid_602472, JString, required = true, default = newJString(
      "DeleteApplicationVersion"))
  if valid_602472 != nil:
    section.add "Action", valid_602472
  var valid_602473 = query.getOrDefault("Version")
  valid_602473 = validateParameter(valid_602473, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602473 != nil:
    section.add "Version", valid_602473
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
  var valid_602474 = header.getOrDefault("X-Amz-Signature")
  valid_602474 = validateParameter(valid_602474, JString, required = false,
                                 default = nil)
  if valid_602474 != nil:
    section.add "X-Amz-Signature", valid_602474
  var valid_602475 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602475 = validateParameter(valid_602475, JString, required = false,
                                 default = nil)
  if valid_602475 != nil:
    section.add "X-Amz-Content-Sha256", valid_602475
  var valid_602476 = header.getOrDefault("X-Amz-Date")
  valid_602476 = validateParameter(valid_602476, JString, required = false,
                                 default = nil)
  if valid_602476 != nil:
    section.add "X-Amz-Date", valid_602476
  var valid_602477 = header.getOrDefault("X-Amz-Credential")
  valid_602477 = validateParameter(valid_602477, JString, required = false,
                                 default = nil)
  if valid_602477 != nil:
    section.add "X-Amz-Credential", valid_602477
  var valid_602478 = header.getOrDefault("X-Amz-Security-Token")
  valid_602478 = validateParameter(valid_602478, JString, required = false,
                                 default = nil)
  if valid_602478 != nil:
    section.add "X-Amz-Security-Token", valid_602478
  var valid_602479 = header.getOrDefault("X-Amz-Algorithm")
  valid_602479 = validateParameter(valid_602479, JString, required = false,
                                 default = nil)
  if valid_602479 != nil:
    section.add "X-Amz-Algorithm", valid_602479
  var valid_602480 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602480 = validateParameter(valid_602480, JString, required = false,
                                 default = nil)
  if valid_602480 != nil:
    section.add "X-Amz-SignedHeaders", valid_602480
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
  var valid_602481 = formData.getOrDefault("VersionLabel")
  valid_602481 = validateParameter(valid_602481, JString, required = true,
                                 default = nil)
  if valid_602481 != nil:
    section.add "VersionLabel", valid_602481
  var valid_602482 = formData.getOrDefault("DeleteSourceBundle")
  valid_602482 = validateParameter(valid_602482, JBool, required = false, default = nil)
  if valid_602482 != nil:
    section.add "DeleteSourceBundle", valid_602482
  var valid_602483 = formData.getOrDefault("ApplicationName")
  valid_602483 = validateParameter(valid_602483, JString, required = true,
                                 default = nil)
  if valid_602483 != nil:
    section.add "ApplicationName", valid_602483
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602484: Call_PostDeleteApplicationVersion_602469; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified version from the specified application.</p> <note> <p>You cannot delete an application version that is associated with a running environment.</p> </note>
  ## 
  let valid = call_602484.validator(path, query, header, formData, body)
  let scheme = call_602484.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602484.url(scheme.get, call_602484.host, call_602484.base,
                         call_602484.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602484, url, valid)

proc call*(call_602485: Call_PostDeleteApplicationVersion_602469;
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
  var query_602486 = newJObject()
  var formData_602487 = newJObject()
  add(formData_602487, "VersionLabel", newJString(VersionLabel))
  add(formData_602487, "DeleteSourceBundle", newJBool(DeleteSourceBundle))
  add(formData_602487, "ApplicationName", newJString(ApplicationName))
  add(query_602486, "Action", newJString(Action))
  add(query_602486, "Version", newJString(Version))
  result = call_602485.call(nil, query_602486, nil, formData_602487, nil)

var postDeleteApplicationVersion* = Call_PostDeleteApplicationVersion_602469(
    name: "postDeleteApplicationVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteApplicationVersion",
    validator: validate_PostDeleteApplicationVersion_602470, base: "/",
    url: url_PostDeleteApplicationVersion_602471,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteApplicationVersion_602451 = ref object of OpenApiRestCall_601390
proc url_GetDeleteApplicationVersion_602453(protocol: Scheme; host: string;
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

proc validate_GetDeleteApplicationVersion_602452(path: JsonNode; query: JsonNode;
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
  var valid_602454 = query.getOrDefault("ApplicationName")
  valid_602454 = validateParameter(valid_602454, JString, required = true,
                                 default = nil)
  if valid_602454 != nil:
    section.add "ApplicationName", valid_602454
  var valid_602455 = query.getOrDefault("VersionLabel")
  valid_602455 = validateParameter(valid_602455, JString, required = true,
                                 default = nil)
  if valid_602455 != nil:
    section.add "VersionLabel", valid_602455
  var valid_602456 = query.getOrDefault("Action")
  valid_602456 = validateParameter(valid_602456, JString, required = true, default = newJString(
      "DeleteApplicationVersion"))
  if valid_602456 != nil:
    section.add "Action", valid_602456
  var valid_602457 = query.getOrDefault("Version")
  valid_602457 = validateParameter(valid_602457, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602457 != nil:
    section.add "Version", valid_602457
  var valid_602458 = query.getOrDefault("DeleteSourceBundle")
  valid_602458 = validateParameter(valid_602458, JBool, required = false, default = nil)
  if valid_602458 != nil:
    section.add "DeleteSourceBundle", valid_602458
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
  var valid_602459 = header.getOrDefault("X-Amz-Signature")
  valid_602459 = validateParameter(valid_602459, JString, required = false,
                                 default = nil)
  if valid_602459 != nil:
    section.add "X-Amz-Signature", valid_602459
  var valid_602460 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602460 = validateParameter(valid_602460, JString, required = false,
                                 default = nil)
  if valid_602460 != nil:
    section.add "X-Amz-Content-Sha256", valid_602460
  var valid_602461 = header.getOrDefault("X-Amz-Date")
  valid_602461 = validateParameter(valid_602461, JString, required = false,
                                 default = nil)
  if valid_602461 != nil:
    section.add "X-Amz-Date", valid_602461
  var valid_602462 = header.getOrDefault("X-Amz-Credential")
  valid_602462 = validateParameter(valid_602462, JString, required = false,
                                 default = nil)
  if valid_602462 != nil:
    section.add "X-Amz-Credential", valid_602462
  var valid_602463 = header.getOrDefault("X-Amz-Security-Token")
  valid_602463 = validateParameter(valid_602463, JString, required = false,
                                 default = nil)
  if valid_602463 != nil:
    section.add "X-Amz-Security-Token", valid_602463
  var valid_602464 = header.getOrDefault("X-Amz-Algorithm")
  valid_602464 = validateParameter(valid_602464, JString, required = false,
                                 default = nil)
  if valid_602464 != nil:
    section.add "X-Amz-Algorithm", valid_602464
  var valid_602465 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602465 = validateParameter(valid_602465, JString, required = false,
                                 default = nil)
  if valid_602465 != nil:
    section.add "X-Amz-SignedHeaders", valid_602465
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602466: Call_GetDeleteApplicationVersion_602451; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified version from the specified application.</p> <note> <p>You cannot delete an application version that is associated with a running environment.</p> </note>
  ## 
  let valid = call_602466.validator(path, query, header, formData, body)
  let scheme = call_602466.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602466.url(scheme.get, call_602466.host, call_602466.base,
                         call_602466.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602466, url, valid)

proc call*(call_602467: Call_GetDeleteApplicationVersion_602451;
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
  var query_602468 = newJObject()
  add(query_602468, "ApplicationName", newJString(ApplicationName))
  add(query_602468, "VersionLabel", newJString(VersionLabel))
  add(query_602468, "Action", newJString(Action))
  add(query_602468, "Version", newJString(Version))
  add(query_602468, "DeleteSourceBundle", newJBool(DeleteSourceBundle))
  result = call_602467.call(nil, query_602468, nil, nil, nil)

var getDeleteApplicationVersion* = Call_GetDeleteApplicationVersion_602451(
    name: "getDeleteApplicationVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteApplicationVersion",
    validator: validate_GetDeleteApplicationVersion_602452, base: "/",
    url: url_GetDeleteApplicationVersion_602453,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteConfigurationTemplate_602505 = ref object of OpenApiRestCall_601390
proc url_PostDeleteConfigurationTemplate_602507(protocol: Scheme; host: string;
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

proc validate_PostDeleteConfigurationTemplate_602506(path: JsonNode;
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
  var valid_602508 = query.getOrDefault("Action")
  valid_602508 = validateParameter(valid_602508, JString, required = true, default = newJString(
      "DeleteConfigurationTemplate"))
  if valid_602508 != nil:
    section.add "Action", valid_602508
  var valid_602509 = query.getOrDefault("Version")
  valid_602509 = validateParameter(valid_602509, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602509 != nil:
    section.add "Version", valid_602509
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
  var valid_602510 = header.getOrDefault("X-Amz-Signature")
  valid_602510 = validateParameter(valid_602510, JString, required = false,
                                 default = nil)
  if valid_602510 != nil:
    section.add "X-Amz-Signature", valid_602510
  var valid_602511 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602511 = validateParameter(valid_602511, JString, required = false,
                                 default = nil)
  if valid_602511 != nil:
    section.add "X-Amz-Content-Sha256", valid_602511
  var valid_602512 = header.getOrDefault("X-Amz-Date")
  valid_602512 = validateParameter(valid_602512, JString, required = false,
                                 default = nil)
  if valid_602512 != nil:
    section.add "X-Amz-Date", valid_602512
  var valid_602513 = header.getOrDefault("X-Amz-Credential")
  valid_602513 = validateParameter(valid_602513, JString, required = false,
                                 default = nil)
  if valid_602513 != nil:
    section.add "X-Amz-Credential", valid_602513
  var valid_602514 = header.getOrDefault("X-Amz-Security-Token")
  valid_602514 = validateParameter(valid_602514, JString, required = false,
                                 default = nil)
  if valid_602514 != nil:
    section.add "X-Amz-Security-Token", valid_602514
  var valid_602515 = header.getOrDefault("X-Amz-Algorithm")
  valid_602515 = validateParameter(valid_602515, JString, required = false,
                                 default = nil)
  if valid_602515 != nil:
    section.add "X-Amz-Algorithm", valid_602515
  var valid_602516 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602516 = validateParameter(valid_602516, JString, required = false,
                                 default = nil)
  if valid_602516 != nil:
    section.add "X-Amz-SignedHeaders", valid_602516
  result.add "header", section
  ## parameters in `formData` object:
  ##   TemplateName: JString (required)
  ##               : The name of the configuration template to delete.
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to delete the configuration template from.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TemplateName` field"
  var valid_602517 = formData.getOrDefault("TemplateName")
  valid_602517 = validateParameter(valid_602517, JString, required = true,
                                 default = nil)
  if valid_602517 != nil:
    section.add "TemplateName", valid_602517
  var valid_602518 = formData.getOrDefault("ApplicationName")
  valid_602518 = validateParameter(valid_602518, JString, required = true,
                                 default = nil)
  if valid_602518 != nil:
    section.add "ApplicationName", valid_602518
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602519: Call_PostDeleteConfigurationTemplate_602505;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes the specified configuration template.</p> <note> <p>When you launch an environment using a configuration template, the environment gets a copy of the template. You can delete or modify the environment's copy of the template without affecting the running environment.</p> </note>
  ## 
  let valid = call_602519.validator(path, query, header, formData, body)
  let scheme = call_602519.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602519.url(scheme.get, call_602519.host, call_602519.base,
                         call_602519.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602519, url, valid)

proc call*(call_602520: Call_PostDeleteConfigurationTemplate_602505;
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
  var query_602521 = newJObject()
  var formData_602522 = newJObject()
  add(formData_602522, "TemplateName", newJString(TemplateName))
  add(formData_602522, "ApplicationName", newJString(ApplicationName))
  add(query_602521, "Action", newJString(Action))
  add(query_602521, "Version", newJString(Version))
  result = call_602520.call(nil, query_602521, nil, formData_602522, nil)

var postDeleteConfigurationTemplate* = Call_PostDeleteConfigurationTemplate_602505(
    name: "postDeleteConfigurationTemplate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteConfigurationTemplate",
    validator: validate_PostDeleteConfigurationTemplate_602506, base: "/",
    url: url_PostDeleteConfigurationTemplate_602507,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteConfigurationTemplate_602488 = ref object of OpenApiRestCall_601390
proc url_GetDeleteConfigurationTemplate_602490(protocol: Scheme; host: string;
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

proc validate_GetDeleteConfigurationTemplate_602489(path: JsonNode;
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
  var valid_602491 = query.getOrDefault("ApplicationName")
  valid_602491 = validateParameter(valid_602491, JString, required = true,
                                 default = nil)
  if valid_602491 != nil:
    section.add "ApplicationName", valid_602491
  var valid_602492 = query.getOrDefault("Action")
  valid_602492 = validateParameter(valid_602492, JString, required = true, default = newJString(
      "DeleteConfigurationTemplate"))
  if valid_602492 != nil:
    section.add "Action", valid_602492
  var valid_602493 = query.getOrDefault("Version")
  valid_602493 = validateParameter(valid_602493, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602493 != nil:
    section.add "Version", valid_602493
  var valid_602494 = query.getOrDefault("TemplateName")
  valid_602494 = validateParameter(valid_602494, JString, required = true,
                                 default = nil)
  if valid_602494 != nil:
    section.add "TemplateName", valid_602494
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
  var valid_602495 = header.getOrDefault("X-Amz-Signature")
  valid_602495 = validateParameter(valid_602495, JString, required = false,
                                 default = nil)
  if valid_602495 != nil:
    section.add "X-Amz-Signature", valid_602495
  var valid_602496 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602496 = validateParameter(valid_602496, JString, required = false,
                                 default = nil)
  if valid_602496 != nil:
    section.add "X-Amz-Content-Sha256", valid_602496
  var valid_602497 = header.getOrDefault("X-Amz-Date")
  valid_602497 = validateParameter(valid_602497, JString, required = false,
                                 default = nil)
  if valid_602497 != nil:
    section.add "X-Amz-Date", valid_602497
  var valid_602498 = header.getOrDefault("X-Amz-Credential")
  valid_602498 = validateParameter(valid_602498, JString, required = false,
                                 default = nil)
  if valid_602498 != nil:
    section.add "X-Amz-Credential", valid_602498
  var valid_602499 = header.getOrDefault("X-Amz-Security-Token")
  valid_602499 = validateParameter(valid_602499, JString, required = false,
                                 default = nil)
  if valid_602499 != nil:
    section.add "X-Amz-Security-Token", valid_602499
  var valid_602500 = header.getOrDefault("X-Amz-Algorithm")
  valid_602500 = validateParameter(valid_602500, JString, required = false,
                                 default = nil)
  if valid_602500 != nil:
    section.add "X-Amz-Algorithm", valid_602500
  var valid_602501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602501 = validateParameter(valid_602501, JString, required = false,
                                 default = nil)
  if valid_602501 != nil:
    section.add "X-Amz-SignedHeaders", valid_602501
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602502: Call_GetDeleteConfigurationTemplate_602488; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified configuration template.</p> <note> <p>When you launch an environment using a configuration template, the environment gets a copy of the template. You can delete or modify the environment's copy of the template without affecting the running environment.</p> </note>
  ## 
  let valid = call_602502.validator(path, query, header, formData, body)
  let scheme = call_602502.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602502.url(scheme.get, call_602502.host, call_602502.base,
                         call_602502.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602502, url, valid)

proc call*(call_602503: Call_GetDeleteConfigurationTemplate_602488;
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
  var query_602504 = newJObject()
  add(query_602504, "ApplicationName", newJString(ApplicationName))
  add(query_602504, "Action", newJString(Action))
  add(query_602504, "Version", newJString(Version))
  add(query_602504, "TemplateName", newJString(TemplateName))
  result = call_602503.call(nil, query_602504, nil, nil, nil)

var getDeleteConfigurationTemplate* = Call_GetDeleteConfigurationTemplate_602488(
    name: "getDeleteConfigurationTemplate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteConfigurationTemplate",
    validator: validate_GetDeleteConfigurationTemplate_602489, base: "/",
    url: url_GetDeleteConfigurationTemplate_602490,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEnvironmentConfiguration_602540 = ref object of OpenApiRestCall_601390
proc url_PostDeleteEnvironmentConfiguration_602542(protocol: Scheme; host: string;
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

proc validate_PostDeleteEnvironmentConfiguration_602541(path: JsonNode;
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
  var valid_602543 = query.getOrDefault("Action")
  valid_602543 = validateParameter(valid_602543, JString, required = true, default = newJString(
      "DeleteEnvironmentConfiguration"))
  if valid_602543 != nil:
    section.add "Action", valid_602543
  var valid_602544 = query.getOrDefault("Version")
  valid_602544 = validateParameter(valid_602544, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602544 != nil:
    section.add "Version", valid_602544
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
  var valid_602545 = header.getOrDefault("X-Amz-Signature")
  valid_602545 = validateParameter(valid_602545, JString, required = false,
                                 default = nil)
  if valid_602545 != nil:
    section.add "X-Amz-Signature", valid_602545
  var valid_602546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602546 = validateParameter(valid_602546, JString, required = false,
                                 default = nil)
  if valid_602546 != nil:
    section.add "X-Amz-Content-Sha256", valid_602546
  var valid_602547 = header.getOrDefault("X-Amz-Date")
  valid_602547 = validateParameter(valid_602547, JString, required = false,
                                 default = nil)
  if valid_602547 != nil:
    section.add "X-Amz-Date", valid_602547
  var valid_602548 = header.getOrDefault("X-Amz-Credential")
  valid_602548 = validateParameter(valid_602548, JString, required = false,
                                 default = nil)
  if valid_602548 != nil:
    section.add "X-Amz-Credential", valid_602548
  var valid_602549 = header.getOrDefault("X-Amz-Security-Token")
  valid_602549 = validateParameter(valid_602549, JString, required = false,
                                 default = nil)
  if valid_602549 != nil:
    section.add "X-Amz-Security-Token", valid_602549
  var valid_602550 = header.getOrDefault("X-Amz-Algorithm")
  valid_602550 = validateParameter(valid_602550, JString, required = false,
                                 default = nil)
  if valid_602550 != nil:
    section.add "X-Amz-Algorithm", valid_602550
  var valid_602551 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602551 = validateParameter(valid_602551, JString, required = false,
                                 default = nil)
  if valid_602551 != nil:
    section.add "X-Amz-SignedHeaders", valid_602551
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString (required)
  ##                  : The name of the environment to delete the draft configuration from.
  ##   ApplicationName: JString (required)
  ##                  : The name of the application the environment is associated with.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `EnvironmentName` field"
  var valid_602552 = formData.getOrDefault("EnvironmentName")
  valid_602552 = validateParameter(valid_602552, JString, required = true,
                                 default = nil)
  if valid_602552 != nil:
    section.add "EnvironmentName", valid_602552
  var valid_602553 = formData.getOrDefault("ApplicationName")
  valid_602553 = validateParameter(valid_602553, JString, required = true,
                                 default = nil)
  if valid_602553 != nil:
    section.add "ApplicationName", valid_602553
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602554: Call_PostDeleteEnvironmentConfiguration_602540;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes the draft configuration associated with the running environment.</p> <p>Updating a running environment with any configuration changes creates a draft configuration set. You can get the draft configuration using <a>DescribeConfigurationSettings</a> while the update is in progress or if the update fails. The <code>DeploymentStatus</code> for the draft configuration indicates whether the deployment is in process or has failed. The draft configuration remains in existence until it is deleted with this action.</p>
  ## 
  let valid = call_602554.validator(path, query, header, formData, body)
  let scheme = call_602554.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602554.url(scheme.get, call_602554.host, call_602554.base,
                         call_602554.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602554, url, valid)

proc call*(call_602555: Call_PostDeleteEnvironmentConfiguration_602540;
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
  var query_602556 = newJObject()
  var formData_602557 = newJObject()
  add(formData_602557, "EnvironmentName", newJString(EnvironmentName))
  add(formData_602557, "ApplicationName", newJString(ApplicationName))
  add(query_602556, "Action", newJString(Action))
  add(query_602556, "Version", newJString(Version))
  result = call_602555.call(nil, query_602556, nil, formData_602557, nil)

var postDeleteEnvironmentConfiguration* = Call_PostDeleteEnvironmentConfiguration_602540(
    name: "postDeleteEnvironmentConfiguration", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteEnvironmentConfiguration",
    validator: validate_PostDeleteEnvironmentConfiguration_602541, base: "/",
    url: url_PostDeleteEnvironmentConfiguration_602542,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEnvironmentConfiguration_602523 = ref object of OpenApiRestCall_601390
proc url_GetDeleteEnvironmentConfiguration_602525(protocol: Scheme; host: string;
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

proc validate_GetDeleteEnvironmentConfiguration_602524(path: JsonNode;
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
  var valid_602526 = query.getOrDefault("ApplicationName")
  valid_602526 = validateParameter(valid_602526, JString, required = true,
                                 default = nil)
  if valid_602526 != nil:
    section.add "ApplicationName", valid_602526
  var valid_602527 = query.getOrDefault("EnvironmentName")
  valid_602527 = validateParameter(valid_602527, JString, required = true,
                                 default = nil)
  if valid_602527 != nil:
    section.add "EnvironmentName", valid_602527
  var valid_602528 = query.getOrDefault("Action")
  valid_602528 = validateParameter(valid_602528, JString, required = true, default = newJString(
      "DeleteEnvironmentConfiguration"))
  if valid_602528 != nil:
    section.add "Action", valid_602528
  var valid_602529 = query.getOrDefault("Version")
  valid_602529 = validateParameter(valid_602529, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602529 != nil:
    section.add "Version", valid_602529
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
  var valid_602530 = header.getOrDefault("X-Amz-Signature")
  valid_602530 = validateParameter(valid_602530, JString, required = false,
                                 default = nil)
  if valid_602530 != nil:
    section.add "X-Amz-Signature", valid_602530
  var valid_602531 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602531 = validateParameter(valid_602531, JString, required = false,
                                 default = nil)
  if valid_602531 != nil:
    section.add "X-Amz-Content-Sha256", valid_602531
  var valid_602532 = header.getOrDefault("X-Amz-Date")
  valid_602532 = validateParameter(valid_602532, JString, required = false,
                                 default = nil)
  if valid_602532 != nil:
    section.add "X-Amz-Date", valid_602532
  var valid_602533 = header.getOrDefault("X-Amz-Credential")
  valid_602533 = validateParameter(valid_602533, JString, required = false,
                                 default = nil)
  if valid_602533 != nil:
    section.add "X-Amz-Credential", valid_602533
  var valid_602534 = header.getOrDefault("X-Amz-Security-Token")
  valid_602534 = validateParameter(valid_602534, JString, required = false,
                                 default = nil)
  if valid_602534 != nil:
    section.add "X-Amz-Security-Token", valid_602534
  var valid_602535 = header.getOrDefault("X-Amz-Algorithm")
  valid_602535 = validateParameter(valid_602535, JString, required = false,
                                 default = nil)
  if valid_602535 != nil:
    section.add "X-Amz-Algorithm", valid_602535
  var valid_602536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602536 = validateParameter(valid_602536, JString, required = false,
                                 default = nil)
  if valid_602536 != nil:
    section.add "X-Amz-SignedHeaders", valid_602536
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602537: Call_GetDeleteEnvironmentConfiguration_602523;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes the draft configuration associated with the running environment.</p> <p>Updating a running environment with any configuration changes creates a draft configuration set. You can get the draft configuration using <a>DescribeConfigurationSettings</a> while the update is in progress or if the update fails. The <code>DeploymentStatus</code> for the draft configuration indicates whether the deployment is in process or has failed. The draft configuration remains in existence until it is deleted with this action.</p>
  ## 
  let valid = call_602537.validator(path, query, header, formData, body)
  let scheme = call_602537.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602537.url(scheme.get, call_602537.host, call_602537.base,
                         call_602537.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602537, url, valid)

proc call*(call_602538: Call_GetDeleteEnvironmentConfiguration_602523;
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
  var query_602539 = newJObject()
  add(query_602539, "ApplicationName", newJString(ApplicationName))
  add(query_602539, "EnvironmentName", newJString(EnvironmentName))
  add(query_602539, "Action", newJString(Action))
  add(query_602539, "Version", newJString(Version))
  result = call_602538.call(nil, query_602539, nil, nil, nil)

var getDeleteEnvironmentConfiguration* = Call_GetDeleteEnvironmentConfiguration_602523(
    name: "getDeleteEnvironmentConfiguration", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeleteEnvironmentConfiguration",
    validator: validate_GetDeleteEnvironmentConfiguration_602524, base: "/",
    url: url_GetDeleteEnvironmentConfiguration_602525,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeletePlatformVersion_602574 = ref object of OpenApiRestCall_601390
proc url_PostDeletePlatformVersion_602576(protocol: Scheme; host: string;
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

proc validate_PostDeletePlatformVersion_602575(path: JsonNode; query: JsonNode;
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
  var valid_602577 = query.getOrDefault("Action")
  valid_602577 = validateParameter(valid_602577, JString, required = true,
                                 default = newJString("DeletePlatformVersion"))
  if valid_602577 != nil:
    section.add "Action", valid_602577
  var valid_602578 = query.getOrDefault("Version")
  valid_602578 = validateParameter(valid_602578, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602578 != nil:
    section.add "Version", valid_602578
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
  var valid_602579 = header.getOrDefault("X-Amz-Signature")
  valid_602579 = validateParameter(valid_602579, JString, required = false,
                                 default = nil)
  if valid_602579 != nil:
    section.add "X-Amz-Signature", valid_602579
  var valid_602580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602580 = validateParameter(valid_602580, JString, required = false,
                                 default = nil)
  if valid_602580 != nil:
    section.add "X-Amz-Content-Sha256", valid_602580
  var valid_602581 = header.getOrDefault("X-Amz-Date")
  valid_602581 = validateParameter(valid_602581, JString, required = false,
                                 default = nil)
  if valid_602581 != nil:
    section.add "X-Amz-Date", valid_602581
  var valid_602582 = header.getOrDefault("X-Amz-Credential")
  valid_602582 = validateParameter(valid_602582, JString, required = false,
                                 default = nil)
  if valid_602582 != nil:
    section.add "X-Amz-Credential", valid_602582
  var valid_602583 = header.getOrDefault("X-Amz-Security-Token")
  valid_602583 = validateParameter(valid_602583, JString, required = false,
                                 default = nil)
  if valid_602583 != nil:
    section.add "X-Amz-Security-Token", valid_602583
  var valid_602584 = header.getOrDefault("X-Amz-Algorithm")
  valid_602584 = validateParameter(valid_602584, JString, required = false,
                                 default = nil)
  if valid_602584 != nil:
    section.add "X-Amz-Algorithm", valid_602584
  var valid_602585 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602585 = validateParameter(valid_602585, JString, required = false,
                                 default = nil)
  if valid_602585 != nil:
    section.add "X-Amz-SignedHeaders", valid_602585
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformArn: JString
  ##              : The ARN of the version of the custom platform.
  section = newJObject()
  var valid_602586 = formData.getOrDefault("PlatformArn")
  valid_602586 = validateParameter(valid_602586, JString, required = false,
                                 default = nil)
  if valid_602586 != nil:
    section.add "PlatformArn", valid_602586
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602587: Call_PostDeletePlatformVersion_602574; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified version of a custom platform.
  ## 
  let valid = call_602587.validator(path, query, header, formData, body)
  let scheme = call_602587.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602587.url(scheme.get, call_602587.host, call_602587.base,
                         call_602587.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602587, url, valid)

proc call*(call_602588: Call_PostDeletePlatformVersion_602574;
          Action: string = "DeletePlatformVersion"; Version: string = "2010-12-01";
          PlatformArn: string = ""): Recallable =
  ## postDeletePlatformVersion
  ## Deletes the specified version of a custom platform.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PlatformArn: string
  ##              : The ARN of the version of the custom platform.
  var query_602589 = newJObject()
  var formData_602590 = newJObject()
  add(query_602589, "Action", newJString(Action))
  add(query_602589, "Version", newJString(Version))
  add(formData_602590, "PlatformArn", newJString(PlatformArn))
  result = call_602588.call(nil, query_602589, nil, formData_602590, nil)

var postDeletePlatformVersion* = Call_PostDeletePlatformVersion_602574(
    name: "postDeletePlatformVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeletePlatformVersion",
    validator: validate_PostDeletePlatformVersion_602575, base: "/",
    url: url_PostDeletePlatformVersion_602576,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeletePlatformVersion_602558 = ref object of OpenApiRestCall_601390
proc url_GetDeletePlatformVersion_602560(protocol: Scheme; host: string;
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

proc validate_GetDeletePlatformVersion_602559(path: JsonNode; query: JsonNode;
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
  var valid_602561 = query.getOrDefault("Action")
  valid_602561 = validateParameter(valid_602561, JString, required = true,
                                 default = newJString("DeletePlatformVersion"))
  if valid_602561 != nil:
    section.add "Action", valid_602561
  var valid_602562 = query.getOrDefault("PlatformArn")
  valid_602562 = validateParameter(valid_602562, JString, required = false,
                                 default = nil)
  if valid_602562 != nil:
    section.add "PlatformArn", valid_602562
  var valid_602563 = query.getOrDefault("Version")
  valid_602563 = validateParameter(valid_602563, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602563 != nil:
    section.add "Version", valid_602563
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
  var valid_602564 = header.getOrDefault("X-Amz-Signature")
  valid_602564 = validateParameter(valid_602564, JString, required = false,
                                 default = nil)
  if valid_602564 != nil:
    section.add "X-Amz-Signature", valid_602564
  var valid_602565 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602565 = validateParameter(valid_602565, JString, required = false,
                                 default = nil)
  if valid_602565 != nil:
    section.add "X-Amz-Content-Sha256", valid_602565
  var valid_602566 = header.getOrDefault("X-Amz-Date")
  valid_602566 = validateParameter(valid_602566, JString, required = false,
                                 default = nil)
  if valid_602566 != nil:
    section.add "X-Amz-Date", valid_602566
  var valid_602567 = header.getOrDefault("X-Amz-Credential")
  valid_602567 = validateParameter(valid_602567, JString, required = false,
                                 default = nil)
  if valid_602567 != nil:
    section.add "X-Amz-Credential", valid_602567
  var valid_602568 = header.getOrDefault("X-Amz-Security-Token")
  valid_602568 = validateParameter(valid_602568, JString, required = false,
                                 default = nil)
  if valid_602568 != nil:
    section.add "X-Amz-Security-Token", valid_602568
  var valid_602569 = header.getOrDefault("X-Amz-Algorithm")
  valid_602569 = validateParameter(valid_602569, JString, required = false,
                                 default = nil)
  if valid_602569 != nil:
    section.add "X-Amz-Algorithm", valid_602569
  var valid_602570 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602570 = validateParameter(valid_602570, JString, required = false,
                                 default = nil)
  if valid_602570 != nil:
    section.add "X-Amz-SignedHeaders", valid_602570
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602571: Call_GetDeletePlatformVersion_602558; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified version of a custom platform.
  ## 
  let valid = call_602571.validator(path, query, header, formData, body)
  let scheme = call_602571.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602571.url(scheme.get, call_602571.host, call_602571.base,
                         call_602571.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602571, url, valid)

proc call*(call_602572: Call_GetDeletePlatformVersion_602558;
          Action: string = "DeletePlatformVersion"; PlatformArn: string = "";
          Version: string = "2010-12-01"): Recallable =
  ## getDeletePlatformVersion
  ## Deletes the specified version of a custom platform.
  ##   Action: string (required)
  ##   PlatformArn: string
  ##              : The ARN of the version of the custom platform.
  ##   Version: string (required)
  var query_602573 = newJObject()
  add(query_602573, "Action", newJString(Action))
  add(query_602573, "PlatformArn", newJString(PlatformArn))
  add(query_602573, "Version", newJString(Version))
  result = call_602572.call(nil, query_602573, nil, nil, nil)

var getDeletePlatformVersion* = Call_GetDeletePlatformVersion_602558(
    name: "getDeletePlatformVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DeletePlatformVersion",
    validator: validate_GetDeletePlatformVersion_602559, base: "/",
    url: url_GetDeletePlatformVersion_602560, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAccountAttributes_602606 = ref object of OpenApiRestCall_601390
proc url_PostDescribeAccountAttributes_602608(protocol: Scheme; host: string;
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

proc validate_PostDescribeAccountAttributes_602607(path: JsonNode; query: JsonNode;
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
  var valid_602609 = query.getOrDefault("Action")
  valid_602609 = validateParameter(valid_602609, JString, required = true, default = newJString(
      "DescribeAccountAttributes"))
  if valid_602609 != nil:
    section.add "Action", valid_602609
  var valid_602610 = query.getOrDefault("Version")
  valid_602610 = validateParameter(valid_602610, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602610 != nil:
    section.add "Version", valid_602610
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
  var valid_602611 = header.getOrDefault("X-Amz-Signature")
  valid_602611 = validateParameter(valid_602611, JString, required = false,
                                 default = nil)
  if valid_602611 != nil:
    section.add "X-Amz-Signature", valid_602611
  var valid_602612 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602612 = validateParameter(valid_602612, JString, required = false,
                                 default = nil)
  if valid_602612 != nil:
    section.add "X-Amz-Content-Sha256", valid_602612
  var valid_602613 = header.getOrDefault("X-Amz-Date")
  valid_602613 = validateParameter(valid_602613, JString, required = false,
                                 default = nil)
  if valid_602613 != nil:
    section.add "X-Amz-Date", valid_602613
  var valid_602614 = header.getOrDefault("X-Amz-Credential")
  valid_602614 = validateParameter(valid_602614, JString, required = false,
                                 default = nil)
  if valid_602614 != nil:
    section.add "X-Amz-Credential", valid_602614
  var valid_602615 = header.getOrDefault("X-Amz-Security-Token")
  valid_602615 = validateParameter(valid_602615, JString, required = false,
                                 default = nil)
  if valid_602615 != nil:
    section.add "X-Amz-Security-Token", valid_602615
  var valid_602616 = header.getOrDefault("X-Amz-Algorithm")
  valid_602616 = validateParameter(valid_602616, JString, required = false,
                                 default = nil)
  if valid_602616 != nil:
    section.add "X-Amz-Algorithm", valid_602616
  var valid_602617 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602617 = validateParameter(valid_602617, JString, required = false,
                                 default = nil)
  if valid_602617 != nil:
    section.add "X-Amz-SignedHeaders", valid_602617
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602618: Call_PostDescribeAccountAttributes_602606; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ## 
  let valid = call_602618.validator(path, query, header, formData, body)
  let scheme = call_602618.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602618.url(scheme.get, call_602618.host, call_602618.base,
                         call_602618.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602618, url, valid)

proc call*(call_602619: Call_PostDescribeAccountAttributes_602606;
          Action: string = "DescribeAccountAttributes";
          Version: string = "2010-12-01"): Recallable =
  ## postDescribeAccountAttributes
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602620 = newJObject()
  add(query_602620, "Action", newJString(Action))
  add(query_602620, "Version", newJString(Version))
  result = call_602619.call(nil, query_602620, nil, nil, nil)

var postDescribeAccountAttributes* = Call_PostDescribeAccountAttributes_602606(
    name: "postDescribeAccountAttributes", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeAccountAttributes",
    validator: validate_PostDescribeAccountAttributes_602607, base: "/",
    url: url_PostDescribeAccountAttributes_602608,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAccountAttributes_602591 = ref object of OpenApiRestCall_601390
proc url_GetDescribeAccountAttributes_602593(protocol: Scheme; host: string;
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

proc validate_GetDescribeAccountAttributes_602592(path: JsonNode; query: JsonNode;
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
  var valid_602594 = query.getOrDefault("Action")
  valid_602594 = validateParameter(valid_602594, JString, required = true, default = newJString(
      "DescribeAccountAttributes"))
  if valid_602594 != nil:
    section.add "Action", valid_602594
  var valid_602595 = query.getOrDefault("Version")
  valid_602595 = validateParameter(valid_602595, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602595 != nil:
    section.add "Version", valid_602595
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
  var valid_602596 = header.getOrDefault("X-Amz-Signature")
  valid_602596 = validateParameter(valid_602596, JString, required = false,
                                 default = nil)
  if valid_602596 != nil:
    section.add "X-Amz-Signature", valid_602596
  var valid_602597 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602597 = validateParameter(valid_602597, JString, required = false,
                                 default = nil)
  if valid_602597 != nil:
    section.add "X-Amz-Content-Sha256", valid_602597
  var valid_602598 = header.getOrDefault("X-Amz-Date")
  valid_602598 = validateParameter(valid_602598, JString, required = false,
                                 default = nil)
  if valid_602598 != nil:
    section.add "X-Amz-Date", valid_602598
  var valid_602599 = header.getOrDefault("X-Amz-Credential")
  valid_602599 = validateParameter(valid_602599, JString, required = false,
                                 default = nil)
  if valid_602599 != nil:
    section.add "X-Amz-Credential", valid_602599
  var valid_602600 = header.getOrDefault("X-Amz-Security-Token")
  valid_602600 = validateParameter(valid_602600, JString, required = false,
                                 default = nil)
  if valid_602600 != nil:
    section.add "X-Amz-Security-Token", valid_602600
  var valid_602601 = header.getOrDefault("X-Amz-Algorithm")
  valid_602601 = validateParameter(valid_602601, JString, required = false,
                                 default = nil)
  if valid_602601 != nil:
    section.add "X-Amz-Algorithm", valid_602601
  var valid_602602 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602602 = validateParameter(valid_602602, JString, required = false,
                                 default = nil)
  if valid_602602 != nil:
    section.add "X-Amz-SignedHeaders", valid_602602
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602603: Call_GetDescribeAccountAttributes_602591; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ## 
  let valid = call_602603.validator(path, query, header, formData, body)
  let scheme = call_602603.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602603.url(scheme.get, call_602603.host, call_602603.base,
                         call_602603.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602603, url, valid)

proc call*(call_602604: Call_GetDescribeAccountAttributes_602591;
          Action: string = "DescribeAccountAttributes";
          Version: string = "2010-12-01"): Recallable =
  ## getDescribeAccountAttributes
  ## <p>Returns attributes related to AWS Elastic Beanstalk that are associated with the calling AWS account.</p> <p>The result currently has one set of attributes—resource quotas.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602605 = newJObject()
  add(query_602605, "Action", newJString(Action))
  add(query_602605, "Version", newJString(Version))
  result = call_602604.call(nil, query_602605, nil, nil, nil)

var getDescribeAccountAttributes* = Call_GetDescribeAccountAttributes_602591(
    name: "getDescribeAccountAttributes", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeAccountAttributes",
    validator: validate_GetDescribeAccountAttributes_602592, base: "/",
    url: url_GetDescribeAccountAttributes_602593,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeApplicationVersions_602640 = ref object of OpenApiRestCall_601390
proc url_PostDescribeApplicationVersions_602642(protocol: Scheme; host: string;
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

proc validate_PostDescribeApplicationVersions_602641(path: JsonNode;
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
  var valid_602643 = query.getOrDefault("Action")
  valid_602643 = validateParameter(valid_602643, JString, required = true, default = newJString(
      "DescribeApplicationVersions"))
  if valid_602643 != nil:
    section.add "Action", valid_602643
  var valid_602644 = query.getOrDefault("Version")
  valid_602644 = validateParameter(valid_602644, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602644 != nil:
    section.add "Version", valid_602644
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
  var valid_602645 = header.getOrDefault("X-Amz-Signature")
  valid_602645 = validateParameter(valid_602645, JString, required = false,
                                 default = nil)
  if valid_602645 != nil:
    section.add "X-Amz-Signature", valid_602645
  var valid_602646 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602646 = validateParameter(valid_602646, JString, required = false,
                                 default = nil)
  if valid_602646 != nil:
    section.add "X-Amz-Content-Sha256", valid_602646
  var valid_602647 = header.getOrDefault("X-Amz-Date")
  valid_602647 = validateParameter(valid_602647, JString, required = false,
                                 default = nil)
  if valid_602647 != nil:
    section.add "X-Amz-Date", valid_602647
  var valid_602648 = header.getOrDefault("X-Amz-Credential")
  valid_602648 = validateParameter(valid_602648, JString, required = false,
                                 default = nil)
  if valid_602648 != nil:
    section.add "X-Amz-Credential", valid_602648
  var valid_602649 = header.getOrDefault("X-Amz-Security-Token")
  valid_602649 = validateParameter(valid_602649, JString, required = false,
                                 default = nil)
  if valid_602649 != nil:
    section.add "X-Amz-Security-Token", valid_602649
  var valid_602650 = header.getOrDefault("X-Amz-Algorithm")
  valid_602650 = validateParameter(valid_602650, JString, required = false,
                                 default = nil)
  if valid_602650 != nil:
    section.add "X-Amz-Algorithm", valid_602650
  var valid_602651 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602651 = validateParameter(valid_602651, JString, required = false,
                                 default = nil)
  if valid_602651 != nil:
    section.add "X-Amz-SignedHeaders", valid_602651
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
  var valid_602652 = formData.getOrDefault("NextToken")
  valid_602652 = validateParameter(valid_602652, JString, required = false,
                                 default = nil)
  if valid_602652 != nil:
    section.add "NextToken", valid_602652
  var valid_602653 = formData.getOrDefault("MaxRecords")
  valid_602653 = validateParameter(valid_602653, JInt, required = false, default = nil)
  if valid_602653 != nil:
    section.add "MaxRecords", valid_602653
  var valid_602654 = formData.getOrDefault("VersionLabels")
  valid_602654 = validateParameter(valid_602654, JArray, required = false,
                                 default = nil)
  if valid_602654 != nil:
    section.add "VersionLabels", valid_602654
  var valid_602655 = formData.getOrDefault("ApplicationName")
  valid_602655 = validateParameter(valid_602655, JString, required = false,
                                 default = nil)
  if valid_602655 != nil:
    section.add "ApplicationName", valid_602655
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602656: Call_PostDescribeApplicationVersions_602640;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieve a list of application versions.
  ## 
  let valid = call_602656.validator(path, query, header, formData, body)
  let scheme = call_602656.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602656.url(scheme.get, call_602656.host, call_602656.base,
                         call_602656.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602656, url, valid)

proc call*(call_602657: Call_PostDescribeApplicationVersions_602640;
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
  var query_602658 = newJObject()
  var formData_602659 = newJObject()
  add(formData_602659, "NextToken", newJString(NextToken))
  add(formData_602659, "MaxRecords", newJInt(MaxRecords))
  if VersionLabels != nil:
    formData_602659.add "VersionLabels", VersionLabels
  add(formData_602659, "ApplicationName", newJString(ApplicationName))
  add(query_602658, "Action", newJString(Action))
  add(query_602658, "Version", newJString(Version))
  result = call_602657.call(nil, query_602658, nil, formData_602659, nil)

var postDescribeApplicationVersions* = Call_PostDescribeApplicationVersions_602640(
    name: "postDescribeApplicationVersions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplicationVersions",
    validator: validate_PostDescribeApplicationVersions_602641, base: "/",
    url: url_PostDescribeApplicationVersions_602642,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeApplicationVersions_602621 = ref object of OpenApiRestCall_601390
proc url_GetDescribeApplicationVersions_602623(protocol: Scheme; host: string;
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

proc validate_GetDescribeApplicationVersions_602622(path: JsonNode;
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
  var valid_602624 = query.getOrDefault("ApplicationName")
  valid_602624 = validateParameter(valid_602624, JString, required = false,
                                 default = nil)
  if valid_602624 != nil:
    section.add "ApplicationName", valid_602624
  var valid_602625 = query.getOrDefault("NextToken")
  valid_602625 = validateParameter(valid_602625, JString, required = false,
                                 default = nil)
  if valid_602625 != nil:
    section.add "NextToken", valid_602625
  var valid_602626 = query.getOrDefault("VersionLabels")
  valid_602626 = validateParameter(valid_602626, JArray, required = false,
                                 default = nil)
  if valid_602626 != nil:
    section.add "VersionLabels", valid_602626
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602627 = query.getOrDefault("Action")
  valid_602627 = validateParameter(valid_602627, JString, required = true, default = newJString(
      "DescribeApplicationVersions"))
  if valid_602627 != nil:
    section.add "Action", valid_602627
  var valid_602628 = query.getOrDefault("Version")
  valid_602628 = validateParameter(valid_602628, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602628 != nil:
    section.add "Version", valid_602628
  var valid_602629 = query.getOrDefault("MaxRecords")
  valid_602629 = validateParameter(valid_602629, JInt, required = false, default = nil)
  if valid_602629 != nil:
    section.add "MaxRecords", valid_602629
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
  var valid_602630 = header.getOrDefault("X-Amz-Signature")
  valid_602630 = validateParameter(valid_602630, JString, required = false,
                                 default = nil)
  if valid_602630 != nil:
    section.add "X-Amz-Signature", valid_602630
  var valid_602631 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602631 = validateParameter(valid_602631, JString, required = false,
                                 default = nil)
  if valid_602631 != nil:
    section.add "X-Amz-Content-Sha256", valid_602631
  var valid_602632 = header.getOrDefault("X-Amz-Date")
  valid_602632 = validateParameter(valid_602632, JString, required = false,
                                 default = nil)
  if valid_602632 != nil:
    section.add "X-Amz-Date", valid_602632
  var valid_602633 = header.getOrDefault("X-Amz-Credential")
  valid_602633 = validateParameter(valid_602633, JString, required = false,
                                 default = nil)
  if valid_602633 != nil:
    section.add "X-Amz-Credential", valid_602633
  var valid_602634 = header.getOrDefault("X-Amz-Security-Token")
  valid_602634 = validateParameter(valid_602634, JString, required = false,
                                 default = nil)
  if valid_602634 != nil:
    section.add "X-Amz-Security-Token", valid_602634
  var valid_602635 = header.getOrDefault("X-Amz-Algorithm")
  valid_602635 = validateParameter(valid_602635, JString, required = false,
                                 default = nil)
  if valid_602635 != nil:
    section.add "X-Amz-Algorithm", valid_602635
  var valid_602636 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602636 = validateParameter(valid_602636, JString, required = false,
                                 default = nil)
  if valid_602636 != nil:
    section.add "X-Amz-SignedHeaders", valid_602636
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602637: Call_GetDescribeApplicationVersions_602621; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a list of application versions.
  ## 
  let valid = call_602637.validator(path, query, header, formData, body)
  let scheme = call_602637.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602637.url(scheme.get, call_602637.host, call_602637.base,
                         call_602637.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602637, url, valid)

proc call*(call_602638: Call_GetDescribeApplicationVersions_602621;
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
  var query_602639 = newJObject()
  add(query_602639, "ApplicationName", newJString(ApplicationName))
  add(query_602639, "NextToken", newJString(NextToken))
  if VersionLabels != nil:
    query_602639.add "VersionLabels", VersionLabels
  add(query_602639, "Action", newJString(Action))
  add(query_602639, "Version", newJString(Version))
  add(query_602639, "MaxRecords", newJInt(MaxRecords))
  result = call_602638.call(nil, query_602639, nil, nil, nil)

var getDescribeApplicationVersions* = Call_GetDescribeApplicationVersions_602621(
    name: "getDescribeApplicationVersions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplicationVersions",
    validator: validate_GetDescribeApplicationVersions_602622, base: "/",
    url: url_GetDescribeApplicationVersions_602623,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeApplications_602676 = ref object of OpenApiRestCall_601390
proc url_PostDescribeApplications_602678(protocol: Scheme; host: string;
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

proc validate_PostDescribeApplications_602677(path: JsonNode; query: JsonNode;
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
  var valid_602679 = query.getOrDefault("Action")
  valid_602679 = validateParameter(valid_602679, JString, required = true,
                                 default = newJString("DescribeApplications"))
  if valid_602679 != nil:
    section.add "Action", valid_602679
  var valid_602680 = query.getOrDefault("Version")
  valid_602680 = validateParameter(valid_602680, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602680 != nil:
    section.add "Version", valid_602680
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
  var valid_602681 = header.getOrDefault("X-Amz-Signature")
  valid_602681 = validateParameter(valid_602681, JString, required = false,
                                 default = nil)
  if valid_602681 != nil:
    section.add "X-Amz-Signature", valid_602681
  var valid_602682 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602682 = validateParameter(valid_602682, JString, required = false,
                                 default = nil)
  if valid_602682 != nil:
    section.add "X-Amz-Content-Sha256", valid_602682
  var valid_602683 = header.getOrDefault("X-Amz-Date")
  valid_602683 = validateParameter(valid_602683, JString, required = false,
                                 default = nil)
  if valid_602683 != nil:
    section.add "X-Amz-Date", valid_602683
  var valid_602684 = header.getOrDefault("X-Amz-Credential")
  valid_602684 = validateParameter(valid_602684, JString, required = false,
                                 default = nil)
  if valid_602684 != nil:
    section.add "X-Amz-Credential", valid_602684
  var valid_602685 = header.getOrDefault("X-Amz-Security-Token")
  valid_602685 = validateParameter(valid_602685, JString, required = false,
                                 default = nil)
  if valid_602685 != nil:
    section.add "X-Amz-Security-Token", valid_602685
  var valid_602686 = header.getOrDefault("X-Amz-Algorithm")
  valid_602686 = validateParameter(valid_602686, JString, required = false,
                                 default = nil)
  if valid_602686 != nil:
    section.add "X-Amz-Algorithm", valid_602686
  var valid_602687 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602687 = validateParameter(valid_602687, JString, required = false,
                                 default = nil)
  if valid_602687 != nil:
    section.add "X-Amz-SignedHeaders", valid_602687
  result.add "header", section
  ## parameters in `formData` object:
  ##   ApplicationNames: JArray
  ##                   : If specified, AWS Elastic Beanstalk restricts the returned descriptions to only include those with the specified names.
  section = newJObject()
  var valid_602688 = formData.getOrDefault("ApplicationNames")
  valid_602688 = validateParameter(valid_602688, JArray, required = false,
                                 default = nil)
  if valid_602688 != nil:
    section.add "ApplicationNames", valid_602688
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602689: Call_PostDescribeApplications_602676; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the descriptions of existing applications.
  ## 
  let valid = call_602689.validator(path, query, header, formData, body)
  let scheme = call_602689.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602689.url(scheme.get, call_602689.host, call_602689.base,
                         call_602689.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602689, url, valid)

proc call*(call_602690: Call_PostDescribeApplications_602676;
          ApplicationNames: JsonNode = nil; Action: string = "DescribeApplications";
          Version: string = "2010-12-01"): Recallable =
  ## postDescribeApplications
  ## Returns the descriptions of existing applications.
  ##   ApplicationNames: JArray
  ##                   : If specified, AWS Elastic Beanstalk restricts the returned descriptions to only include those with the specified names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602691 = newJObject()
  var formData_602692 = newJObject()
  if ApplicationNames != nil:
    formData_602692.add "ApplicationNames", ApplicationNames
  add(query_602691, "Action", newJString(Action))
  add(query_602691, "Version", newJString(Version))
  result = call_602690.call(nil, query_602691, nil, formData_602692, nil)

var postDescribeApplications* = Call_PostDescribeApplications_602676(
    name: "postDescribeApplications", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplications",
    validator: validate_PostDescribeApplications_602677, base: "/",
    url: url_PostDescribeApplications_602678, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeApplications_602660 = ref object of OpenApiRestCall_601390
proc url_GetDescribeApplications_602662(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeApplications_602661(path: JsonNode; query: JsonNode;
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
  var valid_602663 = query.getOrDefault("ApplicationNames")
  valid_602663 = validateParameter(valid_602663, JArray, required = false,
                                 default = nil)
  if valid_602663 != nil:
    section.add "ApplicationNames", valid_602663
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602664 = query.getOrDefault("Action")
  valid_602664 = validateParameter(valid_602664, JString, required = true,
                                 default = newJString("DescribeApplications"))
  if valid_602664 != nil:
    section.add "Action", valid_602664
  var valid_602665 = query.getOrDefault("Version")
  valid_602665 = validateParameter(valid_602665, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602665 != nil:
    section.add "Version", valid_602665
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
  var valid_602666 = header.getOrDefault("X-Amz-Signature")
  valid_602666 = validateParameter(valid_602666, JString, required = false,
                                 default = nil)
  if valid_602666 != nil:
    section.add "X-Amz-Signature", valid_602666
  var valid_602667 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602667 = validateParameter(valid_602667, JString, required = false,
                                 default = nil)
  if valid_602667 != nil:
    section.add "X-Amz-Content-Sha256", valid_602667
  var valid_602668 = header.getOrDefault("X-Amz-Date")
  valid_602668 = validateParameter(valid_602668, JString, required = false,
                                 default = nil)
  if valid_602668 != nil:
    section.add "X-Amz-Date", valid_602668
  var valid_602669 = header.getOrDefault("X-Amz-Credential")
  valid_602669 = validateParameter(valid_602669, JString, required = false,
                                 default = nil)
  if valid_602669 != nil:
    section.add "X-Amz-Credential", valid_602669
  var valid_602670 = header.getOrDefault("X-Amz-Security-Token")
  valid_602670 = validateParameter(valid_602670, JString, required = false,
                                 default = nil)
  if valid_602670 != nil:
    section.add "X-Amz-Security-Token", valid_602670
  var valid_602671 = header.getOrDefault("X-Amz-Algorithm")
  valid_602671 = validateParameter(valid_602671, JString, required = false,
                                 default = nil)
  if valid_602671 != nil:
    section.add "X-Amz-Algorithm", valid_602671
  var valid_602672 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602672 = validateParameter(valid_602672, JString, required = false,
                                 default = nil)
  if valid_602672 != nil:
    section.add "X-Amz-SignedHeaders", valid_602672
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602673: Call_GetDescribeApplications_602660; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the descriptions of existing applications.
  ## 
  let valid = call_602673.validator(path, query, header, formData, body)
  let scheme = call_602673.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602673.url(scheme.get, call_602673.host, call_602673.base,
                         call_602673.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602673, url, valid)

proc call*(call_602674: Call_GetDescribeApplications_602660;
          ApplicationNames: JsonNode = nil; Action: string = "DescribeApplications";
          Version: string = "2010-12-01"): Recallable =
  ## getDescribeApplications
  ## Returns the descriptions of existing applications.
  ##   ApplicationNames: JArray
  ##                   : If specified, AWS Elastic Beanstalk restricts the returned descriptions to only include those with the specified names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602675 = newJObject()
  if ApplicationNames != nil:
    query_602675.add "ApplicationNames", ApplicationNames
  add(query_602675, "Action", newJString(Action))
  add(query_602675, "Version", newJString(Version))
  result = call_602674.call(nil, query_602675, nil, nil, nil)

var getDescribeApplications* = Call_GetDescribeApplications_602660(
    name: "getDescribeApplications", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeApplications",
    validator: validate_GetDescribeApplications_602661, base: "/",
    url: url_GetDescribeApplications_602662, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeConfigurationOptions_602714 = ref object of OpenApiRestCall_601390
proc url_PostDescribeConfigurationOptions_602716(protocol: Scheme; host: string;
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

proc validate_PostDescribeConfigurationOptions_602715(path: JsonNode;
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
  var valid_602717 = query.getOrDefault("Action")
  valid_602717 = validateParameter(valid_602717, JString, required = true, default = newJString(
      "DescribeConfigurationOptions"))
  if valid_602717 != nil:
    section.add "Action", valid_602717
  var valid_602718 = query.getOrDefault("Version")
  valid_602718 = validateParameter(valid_602718, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602718 != nil:
    section.add "Version", valid_602718
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
  var valid_602719 = header.getOrDefault("X-Amz-Signature")
  valid_602719 = validateParameter(valid_602719, JString, required = false,
                                 default = nil)
  if valid_602719 != nil:
    section.add "X-Amz-Signature", valid_602719
  var valid_602720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602720 = validateParameter(valid_602720, JString, required = false,
                                 default = nil)
  if valid_602720 != nil:
    section.add "X-Amz-Content-Sha256", valid_602720
  var valid_602721 = header.getOrDefault("X-Amz-Date")
  valid_602721 = validateParameter(valid_602721, JString, required = false,
                                 default = nil)
  if valid_602721 != nil:
    section.add "X-Amz-Date", valid_602721
  var valid_602722 = header.getOrDefault("X-Amz-Credential")
  valid_602722 = validateParameter(valid_602722, JString, required = false,
                                 default = nil)
  if valid_602722 != nil:
    section.add "X-Amz-Credential", valid_602722
  var valid_602723 = header.getOrDefault("X-Amz-Security-Token")
  valid_602723 = validateParameter(valid_602723, JString, required = false,
                                 default = nil)
  if valid_602723 != nil:
    section.add "X-Amz-Security-Token", valid_602723
  var valid_602724 = header.getOrDefault("X-Amz-Algorithm")
  valid_602724 = validateParameter(valid_602724, JString, required = false,
                                 default = nil)
  if valid_602724 != nil:
    section.add "X-Amz-Algorithm", valid_602724
  var valid_602725 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602725 = validateParameter(valid_602725, JString, required = false,
                                 default = nil)
  if valid_602725 != nil:
    section.add "X-Amz-SignedHeaders", valid_602725
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
  var valid_602726 = formData.getOrDefault("EnvironmentName")
  valid_602726 = validateParameter(valid_602726, JString, required = false,
                                 default = nil)
  if valid_602726 != nil:
    section.add "EnvironmentName", valid_602726
  var valid_602727 = formData.getOrDefault("TemplateName")
  valid_602727 = validateParameter(valid_602727, JString, required = false,
                                 default = nil)
  if valid_602727 != nil:
    section.add "TemplateName", valid_602727
  var valid_602728 = formData.getOrDefault("Options")
  valid_602728 = validateParameter(valid_602728, JArray, required = false,
                                 default = nil)
  if valid_602728 != nil:
    section.add "Options", valid_602728
  var valid_602729 = formData.getOrDefault("ApplicationName")
  valid_602729 = validateParameter(valid_602729, JString, required = false,
                                 default = nil)
  if valid_602729 != nil:
    section.add "ApplicationName", valid_602729
  var valid_602730 = formData.getOrDefault("SolutionStackName")
  valid_602730 = validateParameter(valid_602730, JString, required = false,
                                 default = nil)
  if valid_602730 != nil:
    section.add "SolutionStackName", valid_602730
  var valid_602731 = formData.getOrDefault("PlatformArn")
  valid_602731 = validateParameter(valid_602731, JString, required = false,
                                 default = nil)
  if valid_602731 != nil:
    section.add "PlatformArn", valid_602731
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602732: Call_PostDescribeConfigurationOptions_602714;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the configuration options that are used in a particular configuration template or environment, or that a specified solution stack defines. The description includes the values the options, their default values, and an indication of the required action on a running environment if an option value is changed.
  ## 
  let valid = call_602732.validator(path, query, header, formData, body)
  let scheme = call_602732.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602732.url(scheme.get, call_602732.host, call_602732.base,
                         call_602732.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602732, url, valid)

proc call*(call_602733: Call_PostDescribeConfigurationOptions_602714;
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
  var query_602734 = newJObject()
  var formData_602735 = newJObject()
  add(formData_602735, "EnvironmentName", newJString(EnvironmentName))
  add(formData_602735, "TemplateName", newJString(TemplateName))
  if Options != nil:
    formData_602735.add "Options", Options
  add(formData_602735, "ApplicationName", newJString(ApplicationName))
  add(query_602734, "Action", newJString(Action))
  add(formData_602735, "SolutionStackName", newJString(SolutionStackName))
  add(query_602734, "Version", newJString(Version))
  add(formData_602735, "PlatformArn", newJString(PlatformArn))
  result = call_602733.call(nil, query_602734, nil, formData_602735, nil)

var postDescribeConfigurationOptions* = Call_PostDescribeConfigurationOptions_602714(
    name: "postDescribeConfigurationOptions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationOptions",
    validator: validate_PostDescribeConfigurationOptions_602715, base: "/",
    url: url_PostDescribeConfigurationOptions_602716,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeConfigurationOptions_602693 = ref object of OpenApiRestCall_601390
proc url_GetDescribeConfigurationOptions_602695(protocol: Scheme; host: string;
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

proc validate_GetDescribeConfigurationOptions_602694(path: JsonNode;
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
  var valid_602696 = query.getOrDefault("ApplicationName")
  valid_602696 = validateParameter(valid_602696, JString, required = false,
                                 default = nil)
  if valid_602696 != nil:
    section.add "ApplicationName", valid_602696
  var valid_602697 = query.getOrDefault("Options")
  valid_602697 = validateParameter(valid_602697, JArray, required = false,
                                 default = nil)
  if valid_602697 != nil:
    section.add "Options", valid_602697
  var valid_602698 = query.getOrDefault("SolutionStackName")
  valid_602698 = validateParameter(valid_602698, JString, required = false,
                                 default = nil)
  if valid_602698 != nil:
    section.add "SolutionStackName", valid_602698
  var valid_602699 = query.getOrDefault("EnvironmentName")
  valid_602699 = validateParameter(valid_602699, JString, required = false,
                                 default = nil)
  if valid_602699 != nil:
    section.add "EnvironmentName", valid_602699
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602700 = query.getOrDefault("Action")
  valid_602700 = validateParameter(valid_602700, JString, required = true, default = newJString(
      "DescribeConfigurationOptions"))
  if valid_602700 != nil:
    section.add "Action", valid_602700
  var valid_602701 = query.getOrDefault("PlatformArn")
  valid_602701 = validateParameter(valid_602701, JString, required = false,
                                 default = nil)
  if valid_602701 != nil:
    section.add "PlatformArn", valid_602701
  var valid_602702 = query.getOrDefault("Version")
  valid_602702 = validateParameter(valid_602702, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602702 != nil:
    section.add "Version", valid_602702
  var valid_602703 = query.getOrDefault("TemplateName")
  valid_602703 = validateParameter(valid_602703, JString, required = false,
                                 default = nil)
  if valid_602703 != nil:
    section.add "TemplateName", valid_602703
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
  var valid_602704 = header.getOrDefault("X-Amz-Signature")
  valid_602704 = validateParameter(valid_602704, JString, required = false,
                                 default = nil)
  if valid_602704 != nil:
    section.add "X-Amz-Signature", valid_602704
  var valid_602705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602705 = validateParameter(valid_602705, JString, required = false,
                                 default = nil)
  if valid_602705 != nil:
    section.add "X-Amz-Content-Sha256", valid_602705
  var valid_602706 = header.getOrDefault("X-Amz-Date")
  valid_602706 = validateParameter(valid_602706, JString, required = false,
                                 default = nil)
  if valid_602706 != nil:
    section.add "X-Amz-Date", valid_602706
  var valid_602707 = header.getOrDefault("X-Amz-Credential")
  valid_602707 = validateParameter(valid_602707, JString, required = false,
                                 default = nil)
  if valid_602707 != nil:
    section.add "X-Amz-Credential", valid_602707
  var valid_602708 = header.getOrDefault("X-Amz-Security-Token")
  valid_602708 = validateParameter(valid_602708, JString, required = false,
                                 default = nil)
  if valid_602708 != nil:
    section.add "X-Amz-Security-Token", valid_602708
  var valid_602709 = header.getOrDefault("X-Amz-Algorithm")
  valid_602709 = validateParameter(valid_602709, JString, required = false,
                                 default = nil)
  if valid_602709 != nil:
    section.add "X-Amz-Algorithm", valid_602709
  var valid_602710 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602710 = validateParameter(valid_602710, JString, required = false,
                                 default = nil)
  if valid_602710 != nil:
    section.add "X-Amz-SignedHeaders", valid_602710
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602711: Call_GetDescribeConfigurationOptions_602693;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Describes the configuration options that are used in a particular configuration template or environment, or that a specified solution stack defines. The description includes the values the options, their default values, and an indication of the required action on a running environment if an option value is changed.
  ## 
  let valid = call_602711.validator(path, query, header, formData, body)
  let scheme = call_602711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602711.url(scheme.get, call_602711.host, call_602711.base,
                         call_602711.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602711, url, valid)

proc call*(call_602712: Call_GetDescribeConfigurationOptions_602693;
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
  var query_602713 = newJObject()
  add(query_602713, "ApplicationName", newJString(ApplicationName))
  if Options != nil:
    query_602713.add "Options", Options
  add(query_602713, "SolutionStackName", newJString(SolutionStackName))
  add(query_602713, "EnvironmentName", newJString(EnvironmentName))
  add(query_602713, "Action", newJString(Action))
  add(query_602713, "PlatformArn", newJString(PlatformArn))
  add(query_602713, "Version", newJString(Version))
  add(query_602713, "TemplateName", newJString(TemplateName))
  result = call_602712.call(nil, query_602713, nil, nil, nil)

var getDescribeConfigurationOptions* = Call_GetDescribeConfigurationOptions_602693(
    name: "getDescribeConfigurationOptions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationOptions",
    validator: validate_GetDescribeConfigurationOptions_602694, base: "/",
    url: url_GetDescribeConfigurationOptions_602695,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeConfigurationSettings_602754 = ref object of OpenApiRestCall_601390
proc url_PostDescribeConfigurationSettings_602756(protocol: Scheme; host: string;
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

proc validate_PostDescribeConfigurationSettings_602755(path: JsonNode;
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
  var valid_602757 = query.getOrDefault("Action")
  valid_602757 = validateParameter(valid_602757, JString, required = true, default = newJString(
      "DescribeConfigurationSettings"))
  if valid_602757 != nil:
    section.add "Action", valid_602757
  var valid_602758 = query.getOrDefault("Version")
  valid_602758 = validateParameter(valid_602758, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602758 != nil:
    section.add "Version", valid_602758
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
  var valid_602759 = header.getOrDefault("X-Amz-Signature")
  valid_602759 = validateParameter(valid_602759, JString, required = false,
                                 default = nil)
  if valid_602759 != nil:
    section.add "X-Amz-Signature", valid_602759
  var valid_602760 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602760 = validateParameter(valid_602760, JString, required = false,
                                 default = nil)
  if valid_602760 != nil:
    section.add "X-Amz-Content-Sha256", valid_602760
  var valid_602761 = header.getOrDefault("X-Amz-Date")
  valid_602761 = validateParameter(valid_602761, JString, required = false,
                                 default = nil)
  if valid_602761 != nil:
    section.add "X-Amz-Date", valid_602761
  var valid_602762 = header.getOrDefault("X-Amz-Credential")
  valid_602762 = validateParameter(valid_602762, JString, required = false,
                                 default = nil)
  if valid_602762 != nil:
    section.add "X-Amz-Credential", valid_602762
  var valid_602763 = header.getOrDefault("X-Amz-Security-Token")
  valid_602763 = validateParameter(valid_602763, JString, required = false,
                                 default = nil)
  if valid_602763 != nil:
    section.add "X-Amz-Security-Token", valid_602763
  var valid_602764 = header.getOrDefault("X-Amz-Algorithm")
  valid_602764 = validateParameter(valid_602764, JString, required = false,
                                 default = nil)
  if valid_602764 != nil:
    section.add "X-Amz-Algorithm", valid_602764
  var valid_602765 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602765 = validateParameter(valid_602765, JString, required = false,
                                 default = nil)
  if valid_602765 != nil:
    section.add "X-Amz-SignedHeaders", valid_602765
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to describe.</p> <p> Condition: You must specify either this or a TemplateName, but not both. If you specify both, AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   TemplateName: JString
  ##               : <p>The name of the configuration template to describe.</p> <p> Conditional: You must specify either this parameter or an EnvironmentName, but not both. If you specify both, AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. If you do not specify either, AWS Elastic Beanstalk returns a <code>MissingRequiredParameter</code> error. </p>
  ##   ApplicationName: JString (required)
  ##                  : The application for the environment or configuration template.
  section = newJObject()
  var valid_602766 = formData.getOrDefault("EnvironmentName")
  valid_602766 = validateParameter(valid_602766, JString, required = false,
                                 default = nil)
  if valid_602766 != nil:
    section.add "EnvironmentName", valid_602766
  var valid_602767 = formData.getOrDefault("TemplateName")
  valid_602767 = validateParameter(valid_602767, JString, required = false,
                                 default = nil)
  if valid_602767 != nil:
    section.add "TemplateName", valid_602767
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_602768 = formData.getOrDefault("ApplicationName")
  valid_602768 = validateParameter(valid_602768, JString, required = true,
                                 default = nil)
  if valid_602768 != nil:
    section.add "ApplicationName", valid_602768
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602769: Call_PostDescribeConfigurationSettings_602754;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a description of the settings for the specified configuration set, that is, either a configuration template or the configuration set associated with a running environment.</p> <p>When describing the settings for the configuration set associated with a running environment, it is possible to receive two sets of setting descriptions. One is the deployed configuration set, and the other is a draft configuration of an environment that is either in the process of deployment or that failed to deploy.</p> <p>Related Topics</p> <ul> <li> <p> <a>DeleteEnvironmentConfiguration</a> </p> </li> </ul>
  ## 
  let valid = call_602769.validator(path, query, header, formData, body)
  let scheme = call_602769.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602769.url(scheme.get, call_602769.host, call_602769.base,
                         call_602769.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602769, url, valid)

proc call*(call_602770: Call_PostDescribeConfigurationSettings_602754;
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
  var query_602771 = newJObject()
  var formData_602772 = newJObject()
  add(formData_602772, "EnvironmentName", newJString(EnvironmentName))
  add(formData_602772, "TemplateName", newJString(TemplateName))
  add(formData_602772, "ApplicationName", newJString(ApplicationName))
  add(query_602771, "Action", newJString(Action))
  add(query_602771, "Version", newJString(Version))
  result = call_602770.call(nil, query_602771, nil, formData_602772, nil)

var postDescribeConfigurationSettings* = Call_PostDescribeConfigurationSettings_602754(
    name: "postDescribeConfigurationSettings", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationSettings",
    validator: validate_PostDescribeConfigurationSettings_602755, base: "/",
    url: url_PostDescribeConfigurationSettings_602756,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeConfigurationSettings_602736 = ref object of OpenApiRestCall_601390
proc url_GetDescribeConfigurationSettings_602738(protocol: Scheme; host: string;
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

proc validate_GetDescribeConfigurationSettings_602737(path: JsonNode;
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
  var valid_602739 = query.getOrDefault("ApplicationName")
  valid_602739 = validateParameter(valid_602739, JString, required = true,
                                 default = nil)
  if valid_602739 != nil:
    section.add "ApplicationName", valid_602739
  var valid_602740 = query.getOrDefault("EnvironmentName")
  valid_602740 = validateParameter(valid_602740, JString, required = false,
                                 default = nil)
  if valid_602740 != nil:
    section.add "EnvironmentName", valid_602740
  var valid_602741 = query.getOrDefault("Action")
  valid_602741 = validateParameter(valid_602741, JString, required = true, default = newJString(
      "DescribeConfigurationSettings"))
  if valid_602741 != nil:
    section.add "Action", valid_602741
  var valid_602742 = query.getOrDefault("Version")
  valid_602742 = validateParameter(valid_602742, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602742 != nil:
    section.add "Version", valid_602742
  var valid_602743 = query.getOrDefault("TemplateName")
  valid_602743 = validateParameter(valid_602743, JString, required = false,
                                 default = nil)
  if valid_602743 != nil:
    section.add "TemplateName", valid_602743
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
  var valid_602744 = header.getOrDefault("X-Amz-Signature")
  valid_602744 = validateParameter(valid_602744, JString, required = false,
                                 default = nil)
  if valid_602744 != nil:
    section.add "X-Amz-Signature", valid_602744
  var valid_602745 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602745 = validateParameter(valid_602745, JString, required = false,
                                 default = nil)
  if valid_602745 != nil:
    section.add "X-Amz-Content-Sha256", valid_602745
  var valid_602746 = header.getOrDefault("X-Amz-Date")
  valid_602746 = validateParameter(valid_602746, JString, required = false,
                                 default = nil)
  if valid_602746 != nil:
    section.add "X-Amz-Date", valid_602746
  var valid_602747 = header.getOrDefault("X-Amz-Credential")
  valid_602747 = validateParameter(valid_602747, JString, required = false,
                                 default = nil)
  if valid_602747 != nil:
    section.add "X-Amz-Credential", valid_602747
  var valid_602748 = header.getOrDefault("X-Amz-Security-Token")
  valid_602748 = validateParameter(valid_602748, JString, required = false,
                                 default = nil)
  if valid_602748 != nil:
    section.add "X-Amz-Security-Token", valid_602748
  var valid_602749 = header.getOrDefault("X-Amz-Algorithm")
  valid_602749 = validateParameter(valid_602749, JString, required = false,
                                 default = nil)
  if valid_602749 != nil:
    section.add "X-Amz-Algorithm", valid_602749
  var valid_602750 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602750 = validateParameter(valid_602750, JString, required = false,
                                 default = nil)
  if valid_602750 != nil:
    section.add "X-Amz-SignedHeaders", valid_602750
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602751: Call_GetDescribeConfigurationSettings_602736;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a description of the settings for the specified configuration set, that is, either a configuration template or the configuration set associated with a running environment.</p> <p>When describing the settings for the configuration set associated with a running environment, it is possible to receive two sets of setting descriptions. One is the deployed configuration set, and the other is a draft configuration of an environment that is either in the process of deployment or that failed to deploy.</p> <p>Related Topics</p> <ul> <li> <p> <a>DeleteEnvironmentConfiguration</a> </p> </li> </ul>
  ## 
  let valid = call_602751.validator(path, query, header, formData, body)
  let scheme = call_602751.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602751.url(scheme.get, call_602751.host, call_602751.base,
                         call_602751.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602751, url, valid)

proc call*(call_602752: Call_GetDescribeConfigurationSettings_602736;
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
  var query_602753 = newJObject()
  add(query_602753, "ApplicationName", newJString(ApplicationName))
  add(query_602753, "EnvironmentName", newJString(EnvironmentName))
  add(query_602753, "Action", newJString(Action))
  add(query_602753, "Version", newJString(Version))
  add(query_602753, "TemplateName", newJString(TemplateName))
  result = call_602752.call(nil, query_602753, nil, nil, nil)

var getDescribeConfigurationSettings* = Call_GetDescribeConfigurationSettings_602736(
    name: "getDescribeConfigurationSettings", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeConfigurationSettings",
    validator: validate_GetDescribeConfigurationSettings_602737, base: "/",
    url: url_GetDescribeConfigurationSettings_602738,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentHealth_602791 = ref object of OpenApiRestCall_601390
proc url_PostDescribeEnvironmentHealth_602793(protocol: Scheme; host: string;
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

proc validate_PostDescribeEnvironmentHealth_602792(path: JsonNode; query: JsonNode;
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
  var valid_602794 = query.getOrDefault("Action")
  valid_602794 = validateParameter(valid_602794, JString, required = true, default = newJString(
      "DescribeEnvironmentHealth"))
  if valid_602794 != nil:
    section.add "Action", valid_602794
  var valid_602795 = query.getOrDefault("Version")
  valid_602795 = validateParameter(valid_602795, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602795 != nil:
    section.add "Version", valid_602795
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
  var valid_602796 = header.getOrDefault("X-Amz-Signature")
  valid_602796 = validateParameter(valid_602796, JString, required = false,
                                 default = nil)
  if valid_602796 != nil:
    section.add "X-Amz-Signature", valid_602796
  var valid_602797 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602797 = validateParameter(valid_602797, JString, required = false,
                                 default = nil)
  if valid_602797 != nil:
    section.add "X-Amz-Content-Sha256", valid_602797
  var valid_602798 = header.getOrDefault("X-Amz-Date")
  valid_602798 = validateParameter(valid_602798, JString, required = false,
                                 default = nil)
  if valid_602798 != nil:
    section.add "X-Amz-Date", valid_602798
  var valid_602799 = header.getOrDefault("X-Amz-Credential")
  valid_602799 = validateParameter(valid_602799, JString, required = false,
                                 default = nil)
  if valid_602799 != nil:
    section.add "X-Amz-Credential", valid_602799
  var valid_602800 = header.getOrDefault("X-Amz-Security-Token")
  valid_602800 = validateParameter(valid_602800, JString, required = false,
                                 default = nil)
  if valid_602800 != nil:
    section.add "X-Amz-Security-Token", valid_602800
  var valid_602801 = header.getOrDefault("X-Amz-Algorithm")
  valid_602801 = validateParameter(valid_602801, JString, required = false,
                                 default = nil)
  if valid_602801 != nil:
    section.add "X-Amz-Algorithm", valid_602801
  var valid_602802 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602802 = validateParameter(valid_602802, JString, required = false,
                                 default = nil)
  if valid_602802 != nil:
    section.add "X-Amz-SignedHeaders", valid_602802
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString
  ##                  : <p>Specify the environment by name.</p> <p>You must specify either this or an EnvironmentName, or both.</p>
  ##   AttributeNames: JArray
  ##                 : Specify the response elements to return. To retrieve all attributes, set to <code>All</code>. If no attribute names are specified, returns the name of the environment.
  ##   EnvironmentId: JString
  ##                : <p>Specify the environment by ID.</p> <p>You must specify either this or an EnvironmentName, or both.</p>
  section = newJObject()
  var valid_602803 = formData.getOrDefault("EnvironmentName")
  valid_602803 = validateParameter(valid_602803, JString, required = false,
                                 default = nil)
  if valid_602803 != nil:
    section.add "EnvironmentName", valid_602803
  var valid_602804 = formData.getOrDefault("AttributeNames")
  valid_602804 = validateParameter(valid_602804, JArray, required = false,
                                 default = nil)
  if valid_602804 != nil:
    section.add "AttributeNames", valid_602804
  var valid_602805 = formData.getOrDefault("EnvironmentId")
  valid_602805 = validateParameter(valid_602805, JString, required = false,
                                 default = nil)
  if valid_602805 != nil:
    section.add "EnvironmentId", valid_602805
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602806: Call_PostDescribeEnvironmentHealth_602791; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the overall health of the specified environment. The <b>DescribeEnvironmentHealth</b> operation is only available with AWS Elastic Beanstalk Enhanced Health.
  ## 
  let valid = call_602806.validator(path, query, header, formData, body)
  let scheme = call_602806.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602806.url(scheme.get, call_602806.host, call_602806.base,
                         call_602806.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602806, url, valid)

proc call*(call_602807: Call_PostDescribeEnvironmentHealth_602791;
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
  var query_602808 = newJObject()
  var formData_602809 = newJObject()
  add(formData_602809, "EnvironmentName", newJString(EnvironmentName))
  if AttributeNames != nil:
    formData_602809.add "AttributeNames", AttributeNames
  add(query_602808, "Action", newJString(Action))
  add(formData_602809, "EnvironmentId", newJString(EnvironmentId))
  add(query_602808, "Version", newJString(Version))
  result = call_602807.call(nil, query_602808, nil, formData_602809, nil)

var postDescribeEnvironmentHealth* = Call_PostDescribeEnvironmentHealth_602791(
    name: "postDescribeEnvironmentHealth", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentHealth",
    validator: validate_PostDescribeEnvironmentHealth_602792, base: "/",
    url: url_PostDescribeEnvironmentHealth_602793,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentHealth_602773 = ref object of OpenApiRestCall_601390
proc url_GetDescribeEnvironmentHealth_602775(protocol: Scheme; host: string;
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

proc validate_GetDescribeEnvironmentHealth_602774(path: JsonNode; query: JsonNode;
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
  var valid_602776 = query.getOrDefault("AttributeNames")
  valid_602776 = validateParameter(valid_602776, JArray, required = false,
                                 default = nil)
  if valid_602776 != nil:
    section.add "AttributeNames", valid_602776
  var valid_602777 = query.getOrDefault("EnvironmentName")
  valid_602777 = validateParameter(valid_602777, JString, required = false,
                                 default = nil)
  if valid_602777 != nil:
    section.add "EnvironmentName", valid_602777
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602778 = query.getOrDefault("Action")
  valid_602778 = validateParameter(valid_602778, JString, required = true, default = newJString(
      "DescribeEnvironmentHealth"))
  if valid_602778 != nil:
    section.add "Action", valid_602778
  var valid_602779 = query.getOrDefault("Version")
  valid_602779 = validateParameter(valid_602779, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602779 != nil:
    section.add "Version", valid_602779
  var valid_602780 = query.getOrDefault("EnvironmentId")
  valid_602780 = validateParameter(valid_602780, JString, required = false,
                                 default = nil)
  if valid_602780 != nil:
    section.add "EnvironmentId", valid_602780
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
  var valid_602781 = header.getOrDefault("X-Amz-Signature")
  valid_602781 = validateParameter(valid_602781, JString, required = false,
                                 default = nil)
  if valid_602781 != nil:
    section.add "X-Amz-Signature", valid_602781
  var valid_602782 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602782 = validateParameter(valid_602782, JString, required = false,
                                 default = nil)
  if valid_602782 != nil:
    section.add "X-Amz-Content-Sha256", valid_602782
  var valid_602783 = header.getOrDefault("X-Amz-Date")
  valid_602783 = validateParameter(valid_602783, JString, required = false,
                                 default = nil)
  if valid_602783 != nil:
    section.add "X-Amz-Date", valid_602783
  var valid_602784 = header.getOrDefault("X-Amz-Credential")
  valid_602784 = validateParameter(valid_602784, JString, required = false,
                                 default = nil)
  if valid_602784 != nil:
    section.add "X-Amz-Credential", valid_602784
  var valid_602785 = header.getOrDefault("X-Amz-Security-Token")
  valid_602785 = validateParameter(valid_602785, JString, required = false,
                                 default = nil)
  if valid_602785 != nil:
    section.add "X-Amz-Security-Token", valid_602785
  var valid_602786 = header.getOrDefault("X-Amz-Algorithm")
  valid_602786 = validateParameter(valid_602786, JString, required = false,
                                 default = nil)
  if valid_602786 != nil:
    section.add "X-Amz-Algorithm", valid_602786
  var valid_602787 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602787 = validateParameter(valid_602787, JString, required = false,
                                 default = nil)
  if valid_602787 != nil:
    section.add "X-Amz-SignedHeaders", valid_602787
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602788: Call_GetDescribeEnvironmentHealth_602773; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the overall health of the specified environment. The <b>DescribeEnvironmentHealth</b> operation is only available with AWS Elastic Beanstalk Enhanced Health.
  ## 
  let valid = call_602788.validator(path, query, header, formData, body)
  let scheme = call_602788.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602788.url(scheme.get, call_602788.host, call_602788.base,
                         call_602788.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602788, url, valid)

proc call*(call_602789: Call_GetDescribeEnvironmentHealth_602773;
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
  var query_602790 = newJObject()
  if AttributeNames != nil:
    query_602790.add "AttributeNames", AttributeNames
  add(query_602790, "EnvironmentName", newJString(EnvironmentName))
  add(query_602790, "Action", newJString(Action))
  add(query_602790, "Version", newJString(Version))
  add(query_602790, "EnvironmentId", newJString(EnvironmentId))
  result = call_602789.call(nil, query_602790, nil, nil, nil)

var getDescribeEnvironmentHealth* = Call_GetDescribeEnvironmentHealth_602773(
    name: "getDescribeEnvironmentHealth", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentHealth",
    validator: validate_GetDescribeEnvironmentHealth_602774, base: "/",
    url: url_GetDescribeEnvironmentHealth_602775,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentManagedActionHistory_602829 = ref object of OpenApiRestCall_601390
proc url_PostDescribeEnvironmentManagedActionHistory_602831(protocol: Scheme;
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

proc validate_PostDescribeEnvironmentManagedActionHistory_602830(path: JsonNode;
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
  var valid_602832 = query.getOrDefault("Action")
  valid_602832 = validateParameter(valid_602832, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActionHistory"))
  if valid_602832 != nil:
    section.add "Action", valid_602832
  var valid_602833 = query.getOrDefault("Version")
  valid_602833 = validateParameter(valid_602833, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602833 != nil:
    section.add "Version", valid_602833
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
  var valid_602834 = header.getOrDefault("X-Amz-Signature")
  valid_602834 = validateParameter(valid_602834, JString, required = false,
                                 default = nil)
  if valid_602834 != nil:
    section.add "X-Amz-Signature", valid_602834
  var valid_602835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602835 = validateParameter(valid_602835, JString, required = false,
                                 default = nil)
  if valid_602835 != nil:
    section.add "X-Amz-Content-Sha256", valid_602835
  var valid_602836 = header.getOrDefault("X-Amz-Date")
  valid_602836 = validateParameter(valid_602836, JString, required = false,
                                 default = nil)
  if valid_602836 != nil:
    section.add "X-Amz-Date", valid_602836
  var valid_602837 = header.getOrDefault("X-Amz-Credential")
  valid_602837 = validateParameter(valid_602837, JString, required = false,
                                 default = nil)
  if valid_602837 != nil:
    section.add "X-Amz-Credential", valid_602837
  var valid_602838 = header.getOrDefault("X-Amz-Security-Token")
  valid_602838 = validateParameter(valid_602838, JString, required = false,
                                 default = nil)
  if valid_602838 != nil:
    section.add "X-Amz-Security-Token", valid_602838
  var valid_602839 = header.getOrDefault("X-Amz-Algorithm")
  valid_602839 = validateParameter(valid_602839, JString, required = false,
                                 default = nil)
  if valid_602839 != nil:
    section.add "X-Amz-Algorithm", valid_602839
  var valid_602840 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602840 = validateParameter(valid_602840, JString, required = false,
                                 default = nil)
  if valid_602840 != nil:
    section.add "X-Amz-SignedHeaders", valid_602840
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
  var valid_602841 = formData.getOrDefault("NextToken")
  valid_602841 = validateParameter(valid_602841, JString, required = false,
                                 default = nil)
  if valid_602841 != nil:
    section.add "NextToken", valid_602841
  var valid_602842 = formData.getOrDefault("EnvironmentName")
  valid_602842 = validateParameter(valid_602842, JString, required = false,
                                 default = nil)
  if valid_602842 != nil:
    section.add "EnvironmentName", valid_602842
  var valid_602843 = formData.getOrDefault("MaxItems")
  valid_602843 = validateParameter(valid_602843, JInt, required = false, default = nil)
  if valid_602843 != nil:
    section.add "MaxItems", valid_602843
  var valid_602844 = formData.getOrDefault("EnvironmentId")
  valid_602844 = validateParameter(valid_602844, JString, required = false,
                                 default = nil)
  if valid_602844 != nil:
    section.add "EnvironmentId", valid_602844
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602845: Call_PostDescribeEnvironmentManagedActionHistory_602829;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists an environment's completed and failed managed actions.
  ## 
  let valid = call_602845.validator(path, query, header, formData, body)
  let scheme = call_602845.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602845.url(scheme.get, call_602845.host, call_602845.base,
                         call_602845.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602845, url, valid)

proc call*(call_602846: Call_PostDescribeEnvironmentManagedActionHistory_602829;
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
  var query_602847 = newJObject()
  var formData_602848 = newJObject()
  add(formData_602848, "NextToken", newJString(NextToken))
  add(formData_602848, "EnvironmentName", newJString(EnvironmentName))
  add(query_602847, "Action", newJString(Action))
  add(formData_602848, "MaxItems", newJInt(MaxItems))
  add(formData_602848, "EnvironmentId", newJString(EnvironmentId))
  add(query_602847, "Version", newJString(Version))
  result = call_602846.call(nil, query_602847, nil, formData_602848, nil)

var postDescribeEnvironmentManagedActionHistory* = Call_PostDescribeEnvironmentManagedActionHistory_602829(
    name: "postDescribeEnvironmentManagedActionHistory",
    meth: HttpMethod.HttpPost, host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActionHistory",
    validator: validate_PostDescribeEnvironmentManagedActionHistory_602830,
    base: "/", url: url_PostDescribeEnvironmentManagedActionHistory_602831,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentManagedActionHistory_602810 = ref object of OpenApiRestCall_601390
proc url_GetDescribeEnvironmentManagedActionHistory_602812(protocol: Scheme;
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

proc validate_GetDescribeEnvironmentManagedActionHistory_602811(path: JsonNode;
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
  var valid_602813 = query.getOrDefault("MaxItems")
  valid_602813 = validateParameter(valid_602813, JInt, required = false, default = nil)
  if valid_602813 != nil:
    section.add "MaxItems", valid_602813
  var valid_602814 = query.getOrDefault("NextToken")
  valid_602814 = validateParameter(valid_602814, JString, required = false,
                                 default = nil)
  if valid_602814 != nil:
    section.add "NextToken", valid_602814
  var valid_602815 = query.getOrDefault("EnvironmentName")
  valid_602815 = validateParameter(valid_602815, JString, required = false,
                                 default = nil)
  if valid_602815 != nil:
    section.add "EnvironmentName", valid_602815
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602816 = query.getOrDefault("Action")
  valid_602816 = validateParameter(valid_602816, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActionHistory"))
  if valid_602816 != nil:
    section.add "Action", valid_602816
  var valid_602817 = query.getOrDefault("Version")
  valid_602817 = validateParameter(valid_602817, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602817 != nil:
    section.add "Version", valid_602817
  var valid_602818 = query.getOrDefault("EnvironmentId")
  valid_602818 = validateParameter(valid_602818, JString, required = false,
                                 default = nil)
  if valid_602818 != nil:
    section.add "EnvironmentId", valid_602818
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
  var valid_602819 = header.getOrDefault("X-Amz-Signature")
  valid_602819 = validateParameter(valid_602819, JString, required = false,
                                 default = nil)
  if valid_602819 != nil:
    section.add "X-Amz-Signature", valid_602819
  var valid_602820 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602820 = validateParameter(valid_602820, JString, required = false,
                                 default = nil)
  if valid_602820 != nil:
    section.add "X-Amz-Content-Sha256", valid_602820
  var valid_602821 = header.getOrDefault("X-Amz-Date")
  valid_602821 = validateParameter(valid_602821, JString, required = false,
                                 default = nil)
  if valid_602821 != nil:
    section.add "X-Amz-Date", valid_602821
  var valid_602822 = header.getOrDefault("X-Amz-Credential")
  valid_602822 = validateParameter(valid_602822, JString, required = false,
                                 default = nil)
  if valid_602822 != nil:
    section.add "X-Amz-Credential", valid_602822
  var valid_602823 = header.getOrDefault("X-Amz-Security-Token")
  valid_602823 = validateParameter(valid_602823, JString, required = false,
                                 default = nil)
  if valid_602823 != nil:
    section.add "X-Amz-Security-Token", valid_602823
  var valid_602824 = header.getOrDefault("X-Amz-Algorithm")
  valid_602824 = validateParameter(valid_602824, JString, required = false,
                                 default = nil)
  if valid_602824 != nil:
    section.add "X-Amz-Algorithm", valid_602824
  var valid_602825 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602825 = validateParameter(valid_602825, JString, required = false,
                                 default = nil)
  if valid_602825 != nil:
    section.add "X-Amz-SignedHeaders", valid_602825
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602826: Call_GetDescribeEnvironmentManagedActionHistory_602810;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists an environment's completed and failed managed actions.
  ## 
  let valid = call_602826.validator(path, query, header, formData, body)
  let scheme = call_602826.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602826.url(scheme.get, call_602826.host, call_602826.base,
                         call_602826.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602826, url, valid)

proc call*(call_602827: Call_GetDescribeEnvironmentManagedActionHistory_602810;
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
  var query_602828 = newJObject()
  add(query_602828, "MaxItems", newJInt(MaxItems))
  add(query_602828, "NextToken", newJString(NextToken))
  add(query_602828, "EnvironmentName", newJString(EnvironmentName))
  add(query_602828, "Action", newJString(Action))
  add(query_602828, "Version", newJString(Version))
  add(query_602828, "EnvironmentId", newJString(EnvironmentId))
  result = call_602827.call(nil, query_602828, nil, nil, nil)

var getDescribeEnvironmentManagedActionHistory* = Call_GetDescribeEnvironmentManagedActionHistory_602810(
    name: "getDescribeEnvironmentManagedActionHistory", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActionHistory",
    validator: validate_GetDescribeEnvironmentManagedActionHistory_602811,
    base: "/", url: url_GetDescribeEnvironmentManagedActionHistory_602812,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentManagedActions_602867 = ref object of OpenApiRestCall_601390
proc url_PostDescribeEnvironmentManagedActions_602869(protocol: Scheme;
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

proc validate_PostDescribeEnvironmentManagedActions_602868(path: JsonNode;
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
  var valid_602870 = query.getOrDefault("Action")
  valid_602870 = validateParameter(valid_602870, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActions"))
  if valid_602870 != nil:
    section.add "Action", valid_602870
  var valid_602871 = query.getOrDefault("Version")
  valid_602871 = validateParameter(valid_602871, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602871 != nil:
    section.add "Version", valid_602871
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
  var valid_602872 = header.getOrDefault("X-Amz-Signature")
  valid_602872 = validateParameter(valid_602872, JString, required = false,
                                 default = nil)
  if valid_602872 != nil:
    section.add "X-Amz-Signature", valid_602872
  var valid_602873 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602873 = validateParameter(valid_602873, JString, required = false,
                                 default = nil)
  if valid_602873 != nil:
    section.add "X-Amz-Content-Sha256", valid_602873
  var valid_602874 = header.getOrDefault("X-Amz-Date")
  valid_602874 = validateParameter(valid_602874, JString, required = false,
                                 default = nil)
  if valid_602874 != nil:
    section.add "X-Amz-Date", valid_602874
  var valid_602875 = header.getOrDefault("X-Amz-Credential")
  valid_602875 = validateParameter(valid_602875, JString, required = false,
                                 default = nil)
  if valid_602875 != nil:
    section.add "X-Amz-Credential", valid_602875
  var valid_602876 = header.getOrDefault("X-Amz-Security-Token")
  valid_602876 = validateParameter(valid_602876, JString, required = false,
                                 default = nil)
  if valid_602876 != nil:
    section.add "X-Amz-Security-Token", valid_602876
  var valid_602877 = header.getOrDefault("X-Amz-Algorithm")
  valid_602877 = validateParameter(valid_602877, JString, required = false,
                                 default = nil)
  if valid_602877 != nil:
    section.add "X-Amz-Algorithm", valid_602877
  var valid_602878 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602878 = validateParameter(valid_602878, JString, required = false,
                                 default = nil)
  if valid_602878 != nil:
    section.add "X-Amz-SignedHeaders", valid_602878
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString
  ##                  : The name of the target environment.
  ##   Status: JString
  ##         : To show only actions with a particular status, specify a status.
  ##   EnvironmentId: JString
  ##                : The environment ID of the target environment.
  section = newJObject()
  var valid_602879 = formData.getOrDefault("EnvironmentName")
  valid_602879 = validateParameter(valid_602879, JString, required = false,
                                 default = nil)
  if valid_602879 != nil:
    section.add "EnvironmentName", valid_602879
  var valid_602880 = formData.getOrDefault("Status")
  valid_602880 = validateParameter(valid_602880, JString, required = false,
                                 default = newJString("Scheduled"))
  if valid_602880 != nil:
    section.add "Status", valid_602880
  var valid_602881 = formData.getOrDefault("EnvironmentId")
  valid_602881 = validateParameter(valid_602881, JString, required = false,
                                 default = nil)
  if valid_602881 != nil:
    section.add "EnvironmentId", valid_602881
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602882: Call_PostDescribeEnvironmentManagedActions_602867;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists an environment's upcoming and in-progress managed actions.
  ## 
  let valid = call_602882.validator(path, query, header, formData, body)
  let scheme = call_602882.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602882.url(scheme.get, call_602882.host, call_602882.base,
                         call_602882.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602882, url, valid)

proc call*(call_602883: Call_PostDescribeEnvironmentManagedActions_602867;
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
  var query_602884 = newJObject()
  var formData_602885 = newJObject()
  add(formData_602885, "EnvironmentName", newJString(EnvironmentName))
  add(query_602884, "Action", newJString(Action))
  add(formData_602885, "Status", newJString(Status))
  add(formData_602885, "EnvironmentId", newJString(EnvironmentId))
  add(query_602884, "Version", newJString(Version))
  result = call_602883.call(nil, query_602884, nil, formData_602885, nil)

var postDescribeEnvironmentManagedActions* = Call_PostDescribeEnvironmentManagedActions_602867(
    name: "postDescribeEnvironmentManagedActions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActions",
    validator: validate_PostDescribeEnvironmentManagedActions_602868, base: "/",
    url: url_PostDescribeEnvironmentManagedActions_602869,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentManagedActions_602849 = ref object of OpenApiRestCall_601390
proc url_GetDescribeEnvironmentManagedActions_602851(protocol: Scheme;
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

proc validate_GetDescribeEnvironmentManagedActions_602850(path: JsonNode;
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
  var valid_602852 = query.getOrDefault("Status")
  valid_602852 = validateParameter(valid_602852, JString, required = false,
                                 default = newJString("Scheduled"))
  if valid_602852 != nil:
    section.add "Status", valid_602852
  var valid_602853 = query.getOrDefault("EnvironmentName")
  valid_602853 = validateParameter(valid_602853, JString, required = false,
                                 default = nil)
  if valid_602853 != nil:
    section.add "EnvironmentName", valid_602853
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602854 = query.getOrDefault("Action")
  valid_602854 = validateParameter(valid_602854, JString, required = true, default = newJString(
      "DescribeEnvironmentManagedActions"))
  if valid_602854 != nil:
    section.add "Action", valid_602854
  var valid_602855 = query.getOrDefault("Version")
  valid_602855 = validateParameter(valid_602855, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602855 != nil:
    section.add "Version", valid_602855
  var valid_602856 = query.getOrDefault("EnvironmentId")
  valid_602856 = validateParameter(valid_602856, JString, required = false,
                                 default = nil)
  if valid_602856 != nil:
    section.add "EnvironmentId", valid_602856
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
  var valid_602857 = header.getOrDefault("X-Amz-Signature")
  valid_602857 = validateParameter(valid_602857, JString, required = false,
                                 default = nil)
  if valid_602857 != nil:
    section.add "X-Amz-Signature", valid_602857
  var valid_602858 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602858 = validateParameter(valid_602858, JString, required = false,
                                 default = nil)
  if valid_602858 != nil:
    section.add "X-Amz-Content-Sha256", valid_602858
  var valid_602859 = header.getOrDefault("X-Amz-Date")
  valid_602859 = validateParameter(valid_602859, JString, required = false,
                                 default = nil)
  if valid_602859 != nil:
    section.add "X-Amz-Date", valid_602859
  var valid_602860 = header.getOrDefault("X-Amz-Credential")
  valid_602860 = validateParameter(valid_602860, JString, required = false,
                                 default = nil)
  if valid_602860 != nil:
    section.add "X-Amz-Credential", valid_602860
  var valid_602861 = header.getOrDefault("X-Amz-Security-Token")
  valid_602861 = validateParameter(valid_602861, JString, required = false,
                                 default = nil)
  if valid_602861 != nil:
    section.add "X-Amz-Security-Token", valid_602861
  var valid_602862 = header.getOrDefault("X-Amz-Algorithm")
  valid_602862 = validateParameter(valid_602862, JString, required = false,
                                 default = nil)
  if valid_602862 != nil:
    section.add "X-Amz-Algorithm", valid_602862
  var valid_602863 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602863 = validateParameter(valid_602863, JString, required = false,
                                 default = nil)
  if valid_602863 != nil:
    section.add "X-Amz-SignedHeaders", valid_602863
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602864: Call_GetDescribeEnvironmentManagedActions_602849;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists an environment's upcoming and in-progress managed actions.
  ## 
  let valid = call_602864.validator(path, query, header, formData, body)
  let scheme = call_602864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602864.url(scheme.get, call_602864.host, call_602864.base,
                         call_602864.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602864, url, valid)

proc call*(call_602865: Call_GetDescribeEnvironmentManagedActions_602849;
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
  var query_602866 = newJObject()
  add(query_602866, "Status", newJString(Status))
  add(query_602866, "EnvironmentName", newJString(EnvironmentName))
  add(query_602866, "Action", newJString(Action))
  add(query_602866, "Version", newJString(Version))
  add(query_602866, "EnvironmentId", newJString(EnvironmentId))
  result = call_602865.call(nil, query_602866, nil, nil, nil)

var getDescribeEnvironmentManagedActions* = Call_GetDescribeEnvironmentManagedActions_602849(
    name: "getDescribeEnvironmentManagedActions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentManagedActions",
    validator: validate_GetDescribeEnvironmentManagedActions_602850, base: "/",
    url: url_GetDescribeEnvironmentManagedActions_602851,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironmentResources_602903 = ref object of OpenApiRestCall_601390
proc url_PostDescribeEnvironmentResources_602905(protocol: Scheme; host: string;
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

proc validate_PostDescribeEnvironmentResources_602904(path: JsonNode;
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
  var valid_602906 = query.getOrDefault("Action")
  valid_602906 = validateParameter(valid_602906, JString, required = true, default = newJString(
      "DescribeEnvironmentResources"))
  if valid_602906 != nil:
    section.add "Action", valid_602906
  var valid_602907 = query.getOrDefault("Version")
  valid_602907 = validateParameter(valid_602907, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602907 != nil:
    section.add "Version", valid_602907
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
  var valid_602908 = header.getOrDefault("X-Amz-Signature")
  valid_602908 = validateParameter(valid_602908, JString, required = false,
                                 default = nil)
  if valid_602908 != nil:
    section.add "X-Amz-Signature", valid_602908
  var valid_602909 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602909 = validateParameter(valid_602909, JString, required = false,
                                 default = nil)
  if valid_602909 != nil:
    section.add "X-Amz-Content-Sha256", valid_602909
  var valid_602910 = header.getOrDefault("X-Amz-Date")
  valid_602910 = validateParameter(valid_602910, JString, required = false,
                                 default = nil)
  if valid_602910 != nil:
    section.add "X-Amz-Date", valid_602910
  var valid_602911 = header.getOrDefault("X-Amz-Credential")
  valid_602911 = validateParameter(valid_602911, JString, required = false,
                                 default = nil)
  if valid_602911 != nil:
    section.add "X-Amz-Credential", valid_602911
  var valid_602912 = header.getOrDefault("X-Amz-Security-Token")
  valid_602912 = validateParameter(valid_602912, JString, required = false,
                                 default = nil)
  if valid_602912 != nil:
    section.add "X-Amz-Security-Token", valid_602912
  var valid_602913 = header.getOrDefault("X-Amz-Algorithm")
  valid_602913 = validateParameter(valid_602913, JString, required = false,
                                 default = nil)
  if valid_602913 != nil:
    section.add "X-Amz-Algorithm", valid_602913
  var valid_602914 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602914 = validateParameter(valid_602914, JString, required = false,
                                 default = nil)
  if valid_602914 != nil:
    section.add "X-Amz-SignedHeaders", valid_602914
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to retrieve AWS resource usage data.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to retrieve AWS resource usage data.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_602915 = formData.getOrDefault("EnvironmentName")
  valid_602915 = validateParameter(valid_602915, JString, required = false,
                                 default = nil)
  if valid_602915 != nil:
    section.add "EnvironmentName", valid_602915
  var valid_602916 = formData.getOrDefault("EnvironmentId")
  valid_602916 = validateParameter(valid_602916, JString, required = false,
                                 default = nil)
  if valid_602916 != nil:
    section.add "EnvironmentId", valid_602916
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602917: Call_PostDescribeEnvironmentResources_602903;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns AWS resources for this environment.
  ## 
  let valid = call_602917.validator(path, query, header, formData, body)
  let scheme = call_602917.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602917.url(scheme.get, call_602917.host, call_602917.base,
                         call_602917.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602917, url, valid)

proc call*(call_602918: Call_PostDescribeEnvironmentResources_602903;
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
  var query_602919 = newJObject()
  var formData_602920 = newJObject()
  add(formData_602920, "EnvironmentName", newJString(EnvironmentName))
  add(query_602919, "Action", newJString(Action))
  add(formData_602920, "EnvironmentId", newJString(EnvironmentId))
  add(query_602919, "Version", newJString(Version))
  result = call_602918.call(nil, query_602919, nil, formData_602920, nil)

var postDescribeEnvironmentResources* = Call_PostDescribeEnvironmentResources_602903(
    name: "postDescribeEnvironmentResources", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentResources",
    validator: validate_PostDescribeEnvironmentResources_602904, base: "/",
    url: url_PostDescribeEnvironmentResources_602905,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironmentResources_602886 = ref object of OpenApiRestCall_601390
proc url_GetDescribeEnvironmentResources_602888(protocol: Scheme; host: string;
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

proc validate_GetDescribeEnvironmentResources_602887(path: JsonNode;
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
  var valid_602889 = query.getOrDefault("EnvironmentName")
  valid_602889 = validateParameter(valid_602889, JString, required = false,
                                 default = nil)
  if valid_602889 != nil:
    section.add "EnvironmentName", valid_602889
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602890 = query.getOrDefault("Action")
  valid_602890 = validateParameter(valid_602890, JString, required = true, default = newJString(
      "DescribeEnvironmentResources"))
  if valid_602890 != nil:
    section.add "Action", valid_602890
  var valid_602891 = query.getOrDefault("Version")
  valid_602891 = validateParameter(valid_602891, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602891 != nil:
    section.add "Version", valid_602891
  var valid_602892 = query.getOrDefault("EnvironmentId")
  valid_602892 = validateParameter(valid_602892, JString, required = false,
                                 default = nil)
  if valid_602892 != nil:
    section.add "EnvironmentId", valid_602892
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
  var valid_602893 = header.getOrDefault("X-Amz-Signature")
  valid_602893 = validateParameter(valid_602893, JString, required = false,
                                 default = nil)
  if valid_602893 != nil:
    section.add "X-Amz-Signature", valid_602893
  var valid_602894 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602894 = validateParameter(valid_602894, JString, required = false,
                                 default = nil)
  if valid_602894 != nil:
    section.add "X-Amz-Content-Sha256", valid_602894
  var valid_602895 = header.getOrDefault("X-Amz-Date")
  valid_602895 = validateParameter(valid_602895, JString, required = false,
                                 default = nil)
  if valid_602895 != nil:
    section.add "X-Amz-Date", valid_602895
  var valid_602896 = header.getOrDefault("X-Amz-Credential")
  valid_602896 = validateParameter(valid_602896, JString, required = false,
                                 default = nil)
  if valid_602896 != nil:
    section.add "X-Amz-Credential", valid_602896
  var valid_602897 = header.getOrDefault("X-Amz-Security-Token")
  valid_602897 = validateParameter(valid_602897, JString, required = false,
                                 default = nil)
  if valid_602897 != nil:
    section.add "X-Amz-Security-Token", valid_602897
  var valid_602898 = header.getOrDefault("X-Amz-Algorithm")
  valid_602898 = validateParameter(valid_602898, JString, required = false,
                                 default = nil)
  if valid_602898 != nil:
    section.add "X-Amz-Algorithm", valid_602898
  var valid_602899 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602899 = validateParameter(valid_602899, JString, required = false,
                                 default = nil)
  if valid_602899 != nil:
    section.add "X-Amz-SignedHeaders", valid_602899
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602900: Call_GetDescribeEnvironmentResources_602886;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns AWS resources for this environment.
  ## 
  let valid = call_602900.validator(path, query, header, formData, body)
  let scheme = call_602900.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602900.url(scheme.get, call_602900.host, call_602900.base,
                         call_602900.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602900, url, valid)

proc call*(call_602901: Call_GetDescribeEnvironmentResources_602886;
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
  var query_602902 = newJObject()
  add(query_602902, "EnvironmentName", newJString(EnvironmentName))
  add(query_602902, "Action", newJString(Action))
  add(query_602902, "Version", newJString(Version))
  add(query_602902, "EnvironmentId", newJString(EnvironmentId))
  result = call_602901.call(nil, query_602902, nil, nil, nil)

var getDescribeEnvironmentResources* = Call_GetDescribeEnvironmentResources_602886(
    name: "getDescribeEnvironmentResources", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironmentResources",
    validator: validate_GetDescribeEnvironmentResources_602887, base: "/",
    url: url_GetDescribeEnvironmentResources_602888,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEnvironments_602944 = ref object of OpenApiRestCall_601390
proc url_PostDescribeEnvironments_602946(protocol: Scheme; host: string;
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

proc validate_PostDescribeEnvironments_602945(path: JsonNode; query: JsonNode;
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
  var valid_602947 = query.getOrDefault("Action")
  valid_602947 = validateParameter(valid_602947, JString, required = true,
                                 default = newJString("DescribeEnvironments"))
  if valid_602947 != nil:
    section.add "Action", valid_602947
  var valid_602948 = query.getOrDefault("Version")
  valid_602948 = validateParameter(valid_602948, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602948 != nil:
    section.add "Version", valid_602948
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
  var valid_602949 = header.getOrDefault("X-Amz-Signature")
  valid_602949 = validateParameter(valid_602949, JString, required = false,
                                 default = nil)
  if valid_602949 != nil:
    section.add "X-Amz-Signature", valid_602949
  var valid_602950 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602950 = validateParameter(valid_602950, JString, required = false,
                                 default = nil)
  if valid_602950 != nil:
    section.add "X-Amz-Content-Sha256", valid_602950
  var valid_602951 = header.getOrDefault("X-Amz-Date")
  valid_602951 = validateParameter(valid_602951, JString, required = false,
                                 default = nil)
  if valid_602951 != nil:
    section.add "X-Amz-Date", valid_602951
  var valid_602952 = header.getOrDefault("X-Amz-Credential")
  valid_602952 = validateParameter(valid_602952, JString, required = false,
                                 default = nil)
  if valid_602952 != nil:
    section.add "X-Amz-Credential", valid_602952
  var valid_602953 = header.getOrDefault("X-Amz-Security-Token")
  valid_602953 = validateParameter(valid_602953, JString, required = false,
                                 default = nil)
  if valid_602953 != nil:
    section.add "X-Amz-Security-Token", valid_602953
  var valid_602954 = header.getOrDefault("X-Amz-Algorithm")
  valid_602954 = validateParameter(valid_602954, JString, required = false,
                                 default = nil)
  if valid_602954 != nil:
    section.add "X-Amz-Algorithm", valid_602954
  var valid_602955 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602955 = validateParameter(valid_602955, JString, required = false,
                                 default = nil)
  if valid_602955 != nil:
    section.add "X-Amz-SignedHeaders", valid_602955
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
  var valid_602956 = formData.getOrDefault("EnvironmentNames")
  valid_602956 = validateParameter(valid_602956, JArray, required = false,
                                 default = nil)
  if valid_602956 != nil:
    section.add "EnvironmentNames", valid_602956
  var valid_602957 = formData.getOrDefault("MaxRecords")
  valid_602957 = validateParameter(valid_602957, JInt, required = false, default = nil)
  if valid_602957 != nil:
    section.add "MaxRecords", valid_602957
  var valid_602958 = formData.getOrDefault("VersionLabel")
  valid_602958 = validateParameter(valid_602958, JString, required = false,
                                 default = nil)
  if valid_602958 != nil:
    section.add "VersionLabel", valid_602958
  var valid_602959 = formData.getOrDefault("NextToken")
  valid_602959 = validateParameter(valid_602959, JString, required = false,
                                 default = nil)
  if valid_602959 != nil:
    section.add "NextToken", valid_602959
  var valid_602960 = formData.getOrDefault("ApplicationName")
  valid_602960 = validateParameter(valid_602960, JString, required = false,
                                 default = nil)
  if valid_602960 != nil:
    section.add "ApplicationName", valid_602960
  var valid_602961 = formData.getOrDefault("IncludedDeletedBackTo")
  valid_602961 = validateParameter(valid_602961, JString, required = false,
                                 default = nil)
  if valid_602961 != nil:
    section.add "IncludedDeletedBackTo", valid_602961
  var valid_602962 = formData.getOrDefault("EnvironmentIds")
  valid_602962 = validateParameter(valid_602962, JArray, required = false,
                                 default = nil)
  if valid_602962 != nil:
    section.add "EnvironmentIds", valid_602962
  var valid_602963 = formData.getOrDefault("IncludeDeleted")
  valid_602963 = validateParameter(valid_602963, JBool, required = false, default = nil)
  if valid_602963 != nil:
    section.add "IncludeDeleted", valid_602963
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602964: Call_PostDescribeEnvironments_602944; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns descriptions for existing environments.
  ## 
  let valid = call_602964.validator(path, query, header, formData, body)
  let scheme = call_602964.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602964.url(scheme.get, call_602964.host, call_602964.base,
                         call_602964.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602964, url, valid)

proc call*(call_602965: Call_PostDescribeEnvironments_602944;
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
  var query_602966 = newJObject()
  var formData_602967 = newJObject()
  if EnvironmentNames != nil:
    formData_602967.add "EnvironmentNames", EnvironmentNames
  add(formData_602967, "MaxRecords", newJInt(MaxRecords))
  add(formData_602967, "VersionLabel", newJString(VersionLabel))
  add(formData_602967, "NextToken", newJString(NextToken))
  add(formData_602967, "ApplicationName", newJString(ApplicationName))
  add(query_602966, "Action", newJString(Action))
  add(query_602966, "Version", newJString(Version))
  add(formData_602967, "IncludedDeletedBackTo", newJString(IncludedDeletedBackTo))
  if EnvironmentIds != nil:
    formData_602967.add "EnvironmentIds", EnvironmentIds
  add(formData_602967, "IncludeDeleted", newJBool(IncludeDeleted))
  result = call_602965.call(nil, query_602966, nil, formData_602967, nil)

var postDescribeEnvironments* = Call_PostDescribeEnvironments_602944(
    name: "postDescribeEnvironments", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironments",
    validator: validate_PostDescribeEnvironments_602945, base: "/",
    url: url_PostDescribeEnvironments_602946, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEnvironments_602921 = ref object of OpenApiRestCall_601390
proc url_GetDescribeEnvironments_602923(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeEnvironments_602922(path: JsonNode; query: JsonNode;
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
  var valid_602924 = query.getOrDefault("ApplicationName")
  valid_602924 = validateParameter(valid_602924, JString, required = false,
                                 default = nil)
  if valid_602924 != nil:
    section.add "ApplicationName", valid_602924
  var valid_602925 = query.getOrDefault("VersionLabel")
  valid_602925 = validateParameter(valid_602925, JString, required = false,
                                 default = nil)
  if valid_602925 != nil:
    section.add "VersionLabel", valid_602925
  var valid_602926 = query.getOrDefault("IncludeDeleted")
  valid_602926 = validateParameter(valid_602926, JBool, required = false, default = nil)
  if valid_602926 != nil:
    section.add "IncludeDeleted", valid_602926
  var valid_602927 = query.getOrDefault("NextToken")
  valid_602927 = validateParameter(valid_602927, JString, required = false,
                                 default = nil)
  if valid_602927 != nil:
    section.add "NextToken", valid_602927
  var valid_602928 = query.getOrDefault("EnvironmentNames")
  valid_602928 = validateParameter(valid_602928, JArray, required = false,
                                 default = nil)
  if valid_602928 != nil:
    section.add "EnvironmentNames", valid_602928
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602929 = query.getOrDefault("Action")
  valid_602929 = validateParameter(valid_602929, JString, required = true,
                                 default = newJString("DescribeEnvironments"))
  if valid_602929 != nil:
    section.add "Action", valid_602929
  var valid_602930 = query.getOrDefault("EnvironmentIds")
  valid_602930 = validateParameter(valid_602930, JArray, required = false,
                                 default = nil)
  if valid_602930 != nil:
    section.add "EnvironmentIds", valid_602930
  var valid_602931 = query.getOrDefault("IncludedDeletedBackTo")
  valid_602931 = validateParameter(valid_602931, JString, required = false,
                                 default = nil)
  if valid_602931 != nil:
    section.add "IncludedDeletedBackTo", valid_602931
  var valid_602932 = query.getOrDefault("Version")
  valid_602932 = validateParameter(valid_602932, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602932 != nil:
    section.add "Version", valid_602932
  var valid_602933 = query.getOrDefault("MaxRecords")
  valid_602933 = validateParameter(valid_602933, JInt, required = false, default = nil)
  if valid_602933 != nil:
    section.add "MaxRecords", valid_602933
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
  var valid_602934 = header.getOrDefault("X-Amz-Signature")
  valid_602934 = validateParameter(valid_602934, JString, required = false,
                                 default = nil)
  if valid_602934 != nil:
    section.add "X-Amz-Signature", valid_602934
  var valid_602935 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602935 = validateParameter(valid_602935, JString, required = false,
                                 default = nil)
  if valid_602935 != nil:
    section.add "X-Amz-Content-Sha256", valid_602935
  var valid_602936 = header.getOrDefault("X-Amz-Date")
  valid_602936 = validateParameter(valid_602936, JString, required = false,
                                 default = nil)
  if valid_602936 != nil:
    section.add "X-Amz-Date", valid_602936
  var valid_602937 = header.getOrDefault("X-Amz-Credential")
  valid_602937 = validateParameter(valid_602937, JString, required = false,
                                 default = nil)
  if valid_602937 != nil:
    section.add "X-Amz-Credential", valid_602937
  var valid_602938 = header.getOrDefault("X-Amz-Security-Token")
  valid_602938 = validateParameter(valid_602938, JString, required = false,
                                 default = nil)
  if valid_602938 != nil:
    section.add "X-Amz-Security-Token", valid_602938
  var valid_602939 = header.getOrDefault("X-Amz-Algorithm")
  valid_602939 = validateParameter(valid_602939, JString, required = false,
                                 default = nil)
  if valid_602939 != nil:
    section.add "X-Amz-Algorithm", valid_602939
  var valid_602940 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602940 = validateParameter(valid_602940, JString, required = false,
                                 default = nil)
  if valid_602940 != nil:
    section.add "X-Amz-SignedHeaders", valid_602940
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602941: Call_GetDescribeEnvironments_602921; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns descriptions for existing environments.
  ## 
  let valid = call_602941.validator(path, query, header, formData, body)
  let scheme = call_602941.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602941.url(scheme.get, call_602941.host, call_602941.base,
                         call_602941.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602941, url, valid)

proc call*(call_602942: Call_GetDescribeEnvironments_602921;
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
  var query_602943 = newJObject()
  add(query_602943, "ApplicationName", newJString(ApplicationName))
  add(query_602943, "VersionLabel", newJString(VersionLabel))
  add(query_602943, "IncludeDeleted", newJBool(IncludeDeleted))
  add(query_602943, "NextToken", newJString(NextToken))
  if EnvironmentNames != nil:
    query_602943.add "EnvironmentNames", EnvironmentNames
  add(query_602943, "Action", newJString(Action))
  if EnvironmentIds != nil:
    query_602943.add "EnvironmentIds", EnvironmentIds
  add(query_602943, "IncludedDeletedBackTo", newJString(IncludedDeletedBackTo))
  add(query_602943, "Version", newJString(Version))
  add(query_602943, "MaxRecords", newJInt(MaxRecords))
  result = call_602942.call(nil, query_602943, nil, nil, nil)

var getDescribeEnvironments* = Call_GetDescribeEnvironments_602921(
    name: "getDescribeEnvironments", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEnvironments",
    validator: validate_GetDescribeEnvironments_602922, base: "/",
    url: url_GetDescribeEnvironments_602923, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_602995 = ref object of OpenApiRestCall_601390
proc url_PostDescribeEvents_602997(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeEvents_602996(path: JsonNode; query: JsonNode;
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
  var valid_602998 = query.getOrDefault("Action")
  valid_602998 = validateParameter(valid_602998, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_602998 != nil:
    section.add "Action", valid_602998
  var valid_602999 = query.getOrDefault("Version")
  valid_602999 = validateParameter(valid_602999, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602999 != nil:
    section.add "Version", valid_602999
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
  var valid_603000 = header.getOrDefault("X-Amz-Signature")
  valid_603000 = validateParameter(valid_603000, JString, required = false,
                                 default = nil)
  if valid_603000 != nil:
    section.add "X-Amz-Signature", valid_603000
  var valid_603001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603001 = validateParameter(valid_603001, JString, required = false,
                                 default = nil)
  if valid_603001 != nil:
    section.add "X-Amz-Content-Sha256", valid_603001
  var valid_603002 = header.getOrDefault("X-Amz-Date")
  valid_603002 = validateParameter(valid_603002, JString, required = false,
                                 default = nil)
  if valid_603002 != nil:
    section.add "X-Amz-Date", valid_603002
  var valid_603003 = header.getOrDefault("X-Amz-Credential")
  valid_603003 = validateParameter(valid_603003, JString, required = false,
                                 default = nil)
  if valid_603003 != nil:
    section.add "X-Amz-Credential", valid_603003
  var valid_603004 = header.getOrDefault("X-Amz-Security-Token")
  valid_603004 = validateParameter(valid_603004, JString, required = false,
                                 default = nil)
  if valid_603004 != nil:
    section.add "X-Amz-Security-Token", valid_603004
  var valid_603005 = header.getOrDefault("X-Amz-Algorithm")
  valid_603005 = validateParameter(valid_603005, JString, required = false,
                                 default = nil)
  if valid_603005 != nil:
    section.add "X-Amz-Algorithm", valid_603005
  var valid_603006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603006 = validateParameter(valid_603006, JString, required = false,
                                 default = nil)
  if valid_603006 != nil:
    section.add "X-Amz-SignedHeaders", valid_603006
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
  var valid_603007 = formData.getOrDefault("NextToken")
  valid_603007 = validateParameter(valid_603007, JString, required = false,
                                 default = nil)
  if valid_603007 != nil:
    section.add "NextToken", valid_603007
  var valid_603008 = formData.getOrDefault("MaxRecords")
  valid_603008 = validateParameter(valid_603008, JInt, required = false, default = nil)
  if valid_603008 != nil:
    section.add "MaxRecords", valid_603008
  var valid_603009 = formData.getOrDefault("VersionLabel")
  valid_603009 = validateParameter(valid_603009, JString, required = false,
                                 default = nil)
  if valid_603009 != nil:
    section.add "VersionLabel", valid_603009
  var valid_603010 = formData.getOrDefault("EnvironmentName")
  valid_603010 = validateParameter(valid_603010, JString, required = false,
                                 default = nil)
  if valid_603010 != nil:
    section.add "EnvironmentName", valid_603010
  var valid_603011 = formData.getOrDefault("TemplateName")
  valid_603011 = validateParameter(valid_603011, JString, required = false,
                                 default = nil)
  if valid_603011 != nil:
    section.add "TemplateName", valid_603011
  var valid_603012 = formData.getOrDefault("ApplicationName")
  valid_603012 = validateParameter(valid_603012, JString, required = false,
                                 default = nil)
  if valid_603012 != nil:
    section.add "ApplicationName", valid_603012
  var valid_603013 = formData.getOrDefault("EndTime")
  valid_603013 = validateParameter(valid_603013, JString, required = false,
                                 default = nil)
  if valid_603013 != nil:
    section.add "EndTime", valid_603013
  var valid_603014 = formData.getOrDefault("StartTime")
  valid_603014 = validateParameter(valid_603014, JString, required = false,
                                 default = nil)
  if valid_603014 != nil:
    section.add "StartTime", valid_603014
  var valid_603015 = formData.getOrDefault("Severity")
  valid_603015 = validateParameter(valid_603015, JString, required = false,
                                 default = newJString("TRACE"))
  if valid_603015 != nil:
    section.add "Severity", valid_603015
  var valid_603016 = formData.getOrDefault("RequestId")
  valid_603016 = validateParameter(valid_603016, JString, required = false,
                                 default = nil)
  if valid_603016 != nil:
    section.add "RequestId", valid_603016
  var valid_603017 = formData.getOrDefault("EnvironmentId")
  valid_603017 = validateParameter(valid_603017, JString, required = false,
                                 default = nil)
  if valid_603017 != nil:
    section.add "EnvironmentId", valid_603017
  var valid_603018 = formData.getOrDefault("PlatformArn")
  valid_603018 = validateParameter(valid_603018, JString, required = false,
                                 default = nil)
  if valid_603018 != nil:
    section.add "PlatformArn", valid_603018
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603019: Call_PostDescribeEvents_602995; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns list of event descriptions matching criteria up to the last 6 weeks.</p> <note> <p>This action returns the most recent 1,000 events from the specified <code>NextToken</code>.</p> </note>
  ## 
  let valid = call_603019.validator(path, query, header, formData, body)
  let scheme = call_603019.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603019.url(scheme.get, call_603019.host, call_603019.base,
                         call_603019.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603019, url, valid)

proc call*(call_603020: Call_PostDescribeEvents_602995; NextToken: string = "";
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
  var query_603021 = newJObject()
  var formData_603022 = newJObject()
  add(formData_603022, "NextToken", newJString(NextToken))
  add(formData_603022, "MaxRecords", newJInt(MaxRecords))
  add(formData_603022, "VersionLabel", newJString(VersionLabel))
  add(formData_603022, "EnvironmentName", newJString(EnvironmentName))
  add(formData_603022, "TemplateName", newJString(TemplateName))
  add(formData_603022, "ApplicationName", newJString(ApplicationName))
  add(formData_603022, "EndTime", newJString(EndTime))
  add(formData_603022, "StartTime", newJString(StartTime))
  add(formData_603022, "Severity", newJString(Severity))
  add(query_603021, "Action", newJString(Action))
  add(formData_603022, "RequestId", newJString(RequestId))
  add(formData_603022, "EnvironmentId", newJString(EnvironmentId))
  add(query_603021, "Version", newJString(Version))
  add(formData_603022, "PlatformArn", newJString(PlatformArn))
  result = call_603020.call(nil, query_603021, nil, formData_603022, nil)

var postDescribeEvents* = Call_PostDescribeEvents_602995(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_602996, base: "/",
    url: url_PostDescribeEvents_602997, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_602968 = ref object of OpenApiRestCall_601390
proc url_GetDescribeEvents_602970(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeEvents_602969(path: JsonNode; query: JsonNode;
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
  var valid_602971 = query.getOrDefault("RequestId")
  valid_602971 = validateParameter(valid_602971, JString, required = false,
                                 default = nil)
  if valid_602971 != nil:
    section.add "RequestId", valid_602971
  var valid_602972 = query.getOrDefault("ApplicationName")
  valid_602972 = validateParameter(valid_602972, JString, required = false,
                                 default = nil)
  if valid_602972 != nil:
    section.add "ApplicationName", valid_602972
  var valid_602973 = query.getOrDefault("VersionLabel")
  valid_602973 = validateParameter(valid_602973, JString, required = false,
                                 default = nil)
  if valid_602973 != nil:
    section.add "VersionLabel", valid_602973
  var valid_602974 = query.getOrDefault("NextToken")
  valid_602974 = validateParameter(valid_602974, JString, required = false,
                                 default = nil)
  if valid_602974 != nil:
    section.add "NextToken", valid_602974
  var valid_602975 = query.getOrDefault("Severity")
  valid_602975 = validateParameter(valid_602975, JString, required = false,
                                 default = newJString("TRACE"))
  if valid_602975 != nil:
    section.add "Severity", valid_602975
  var valid_602976 = query.getOrDefault("EnvironmentName")
  valid_602976 = validateParameter(valid_602976, JString, required = false,
                                 default = nil)
  if valid_602976 != nil:
    section.add "EnvironmentName", valid_602976
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602977 = query.getOrDefault("Action")
  valid_602977 = validateParameter(valid_602977, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_602977 != nil:
    section.add "Action", valid_602977
  var valid_602978 = query.getOrDefault("StartTime")
  valid_602978 = validateParameter(valid_602978, JString, required = false,
                                 default = nil)
  if valid_602978 != nil:
    section.add "StartTime", valid_602978
  var valid_602979 = query.getOrDefault("PlatformArn")
  valid_602979 = validateParameter(valid_602979, JString, required = false,
                                 default = nil)
  if valid_602979 != nil:
    section.add "PlatformArn", valid_602979
  var valid_602980 = query.getOrDefault("EndTime")
  valid_602980 = validateParameter(valid_602980, JString, required = false,
                                 default = nil)
  if valid_602980 != nil:
    section.add "EndTime", valid_602980
  var valid_602981 = query.getOrDefault("Version")
  valid_602981 = validateParameter(valid_602981, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_602981 != nil:
    section.add "Version", valid_602981
  var valid_602982 = query.getOrDefault("TemplateName")
  valid_602982 = validateParameter(valid_602982, JString, required = false,
                                 default = nil)
  if valid_602982 != nil:
    section.add "TemplateName", valid_602982
  var valid_602983 = query.getOrDefault("MaxRecords")
  valid_602983 = validateParameter(valid_602983, JInt, required = false, default = nil)
  if valid_602983 != nil:
    section.add "MaxRecords", valid_602983
  var valid_602984 = query.getOrDefault("EnvironmentId")
  valid_602984 = validateParameter(valid_602984, JString, required = false,
                                 default = nil)
  if valid_602984 != nil:
    section.add "EnvironmentId", valid_602984
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
  var valid_602985 = header.getOrDefault("X-Amz-Signature")
  valid_602985 = validateParameter(valid_602985, JString, required = false,
                                 default = nil)
  if valid_602985 != nil:
    section.add "X-Amz-Signature", valid_602985
  var valid_602986 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602986 = validateParameter(valid_602986, JString, required = false,
                                 default = nil)
  if valid_602986 != nil:
    section.add "X-Amz-Content-Sha256", valid_602986
  var valid_602987 = header.getOrDefault("X-Amz-Date")
  valid_602987 = validateParameter(valid_602987, JString, required = false,
                                 default = nil)
  if valid_602987 != nil:
    section.add "X-Amz-Date", valid_602987
  var valid_602988 = header.getOrDefault("X-Amz-Credential")
  valid_602988 = validateParameter(valid_602988, JString, required = false,
                                 default = nil)
  if valid_602988 != nil:
    section.add "X-Amz-Credential", valid_602988
  var valid_602989 = header.getOrDefault("X-Amz-Security-Token")
  valid_602989 = validateParameter(valid_602989, JString, required = false,
                                 default = nil)
  if valid_602989 != nil:
    section.add "X-Amz-Security-Token", valid_602989
  var valid_602990 = header.getOrDefault("X-Amz-Algorithm")
  valid_602990 = validateParameter(valid_602990, JString, required = false,
                                 default = nil)
  if valid_602990 != nil:
    section.add "X-Amz-Algorithm", valid_602990
  var valid_602991 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602991 = validateParameter(valid_602991, JString, required = false,
                                 default = nil)
  if valid_602991 != nil:
    section.add "X-Amz-SignedHeaders", valid_602991
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602992: Call_GetDescribeEvents_602968; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns list of event descriptions matching criteria up to the last 6 weeks.</p> <note> <p>This action returns the most recent 1,000 events from the specified <code>NextToken</code>.</p> </note>
  ## 
  let valid = call_602992.validator(path, query, header, formData, body)
  let scheme = call_602992.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602992.url(scheme.get, call_602992.host, call_602992.base,
                         call_602992.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602992, url, valid)

proc call*(call_602993: Call_GetDescribeEvents_602968; RequestId: string = "";
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
  var query_602994 = newJObject()
  add(query_602994, "RequestId", newJString(RequestId))
  add(query_602994, "ApplicationName", newJString(ApplicationName))
  add(query_602994, "VersionLabel", newJString(VersionLabel))
  add(query_602994, "NextToken", newJString(NextToken))
  add(query_602994, "Severity", newJString(Severity))
  add(query_602994, "EnvironmentName", newJString(EnvironmentName))
  add(query_602994, "Action", newJString(Action))
  add(query_602994, "StartTime", newJString(StartTime))
  add(query_602994, "PlatformArn", newJString(PlatformArn))
  add(query_602994, "EndTime", newJString(EndTime))
  add(query_602994, "Version", newJString(Version))
  add(query_602994, "TemplateName", newJString(TemplateName))
  add(query_602994, "MaxRecords", newJInt(MaxRecords))
  add(query_602994, "EnvironmentId", newJString(EnvironmentId))
  result = call_602993.call(nil, query_602994, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_602968(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_602969,
    base: "/", url: url_GetDescribeEvents_602970,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeInstancesHealth_603042 = ref object of OpenApiRestCall_601390
proc url_PostDescribeInstancesHealth_603044(protocol: Scheme; host: string;
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

proc validate_PostDescribeInstancesHealth_603043(path: JsonNode; query: JsonNode;
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
  var valid_603045 = query.getOrDefault("Action")
  valid_603045 = validateParameter(valid_603045, JString, required = true, default = newJString(
      "DescribeInstancesHealth"))
  if valid_603045 != nil:
    section.add "Action", valid_603045
  var valid_603046 = query.getOrDefault("Version")
  valid_603046 = validateParameter(valid_603046, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603046 != nil:
    section.add "Version", valid_603046
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
  var valid_603047 = header.getOrDefault("X-Amz-Signature")
  valid_603047 = validateParameter(valid_603047, JString, required = false,
                                 default = nil)
  if valid_603047 != nil:
    section.add "X-Amz-Signature", valid_603047
  var valid_603048 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603048 = validateParameter(valid_603048, JString, required = false,
                                 default = nil)
  if valid_603048 != nil:
    section.add "X-Amz-Content-Sha256", valid_603048
  var valid_603049 = header.getOrDefault("X-Amz-Date")
  valid_603049 = validateParameter(valid_603049, JString, required = false,
                                 default = nil)
  if valid_603049 != nil:
    section.add "X-Amz-Date", valid_603049
  var valid_603050 = header.getOrDefault("X-Amz-Credential")
  valid_603050 = validateParameter(valid_603050, JString, required = false,
                                 default = nil)
  if valid_603050 != nil:
    section.add "X-Amz-Credential", valid_603050
  var valid_603051 = header.getOrDefault("X-Amz-Security-Token")
  valid_603051 = validateParameter(valid_603051, JString, required = false,
                                 default = nil)
  if valid_603051 != nil:
    section.add "X-Amz-Security-Token", valid_603051
  var valid_603052 = header.getOrDefault("X-Amz-Algorithm")
  valid_603052 = validateParameter(valid_603052, JString, required = false,
                                 default = nil)
  if valid_603052 != nil:
    section.add "X-Amz-Algorithm", valid_603052
  var valid_603053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603053 = validateParameter(valid_603053, JString, required = false,
                                 default = nil)
  if valid_603053 != nil:
    section.add "X-Amz-SignedHeaders", valid_603053
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
  var valid_603054 = formData.getOrDefault("NextToken")
  valid_603054 = validateParameter(valid_603054, JString, required = false,
                                 default = nil)
  if valid_603054 != nil:
    section.add "NextToken", valid_603054
  var valid_603055 = formData.getOrDefault("EnvironmentName")
  valid_603055 = validateParameter(valid_603055, JString, required = false,
                                 default = nil)
  if valid_603055 != nil:
    section.add "EnvironmentName", valid_603055
  var valid_603056 = formData.getOrDefault("AttributeNames")
  valid_603056 = validateParameter(valid_603056, JArray, required = false,
                                 default = nil)
  if valid_603056 != nil:
    section.add "AttributeNames", valid_603056
  var valid_603057 = formData.getOrDefault("EnvironmentId")
  valid_603057 = validateParameter(valid_603057, JString, required = false,
                                 default = nil)
  if valid_603057 != nil:
    section.add "EnvironmentId", valid_603057
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603058: Call_PostDescribeInstancesHealth_603042; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves detailed information about the health of instances in your AWS Elastic Beanstalk. This operation requires <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/health-enhanced.html">enhanced health reporting</a>.
  ## 
  let valid = call_603058.validator(path, query, header, formData, body)
  let scheme = call_603058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603058.url(scheme.get, call_603058.host, call_603058.base,
                         call_603058.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603058, url, valid)

proc call*(call_603059: Call_PostDescribeInstancesHealth_603042;
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
  var query_603060 = newJObject()
  var formData_603061 = newJObject()
  add(formData_603061, "NextToken", newJString(NextToken))
  add(formData_603061, "EnvironmentName", newJString(EnvironmentName))
  if AttributeNames != nil:
    formData_603061.add "AttributeNames", AttributeNames
  add(query_603060, "Action", newJString(Action))
  add(formData_603061, "EnvironmentId", newJString(EnvironmentId))
  add(query_603060, "Version", newJString(Version))
  result = call_603059.call(nil, query_603060, nil, formData_603061, nil)

var postDescribeInstancesHealth* = Call_PostDescribeInstancesHealth_603042(
    name: "postDescribeInstancesHealth", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeInstancesHealth",
    validator: validate_PostDescribeInstancesHealth_603043, base: "/",
    url: url_PostDescribeInstancesHealth_603044,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeInstancesHealth_603023 = ref object of OpenApiRestCall_601390
proc url_GetDescribeInstancesHealth_603025(protocol: Scheme; host: string;
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

proc validate_GetDescribeInstancesHealth_603024(path: JsonNode; query: JsonNode;
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
  var valid_603026 = query.getOrDefault("AttributeNames")
  valid_603026 = validateParameter(valid_603026, JArray, required = false,
                                 default = nil)
  if valid_603026 != nil:
    section.add "AttributeNames", valid_603026
  var valid_603027 = query.getOrDefault("NextToken")
  valid_603027 = validateParameter(valid_603027, JString, required = false,
                                 default = nil)
  if valid_603027 != nil:
    section.add "NextToken", valid_603027
  var valid_603028 = query.getOrDefault("EnvironmentName")
  valid_603028 = validateParameter(valid_603028, JString, required = false,
                                 default = nil)
  if valid_603028 != nil:
    section.add "EnvironmentName", valid_603028
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603029 = query.getOrDefault("Action")
  valid_603029 = validateParameter(valid_603029, JString, required = true, default = newJString(
      "DescribeInstancesHealth"))
  if valid_603029 != nil:
    section.add "Action", valid_603029
  var valid_603030 = query.getOrDefault("Version")
  valid_603030 = validateParameter(valid_603030, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603030 != nil:
    section.add "Version", valid_603030
  var valid_603031 = query.getOrDefault("EnvironmentId")
  valid_603031 = validateParameter(valid_603031, JString, required = false,
                                 default = nil)
  if valid_603031 != nil:
    section.add "EnvironmentId", valid_603031
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
  var valid_603032 = header.getOrDefault("X-Amz-Signature")
  valid_603032 = validateParameter(valid_603032, JString, required = false,
                                 default = nil)
  if valid_603032 != nil:
    section.add "X-Amz-Signature", valid_603032
  var valid_603033 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603033 = validateParameter(valid_603033, JString, required = false,
                                 default = nil)
  if valid_603033 != nil:
    section.add "X-Amz-Content-Sha256", valid_603033
  var valid_603034 = header.getOrDefault("X-Amz-Date")
  valid_603034 = validateParameter(valid_603034, JString, required = false,
                                 default = nil)
  if valid_603034 != nil:
    section.add "X-Amz-Date", valid_603034
  var valid_603035 = header.getOrDefault("X-Amz-Credential")
  valid_603035 = validateParameter(valid_603035, JString, required = false,
                                 default = nil)
  if valid_603035 != nil:
    section.add "X-Amz-Credential", valid_603035
  var valid_603036 = header.getOrDefault("X-Amz-Security-Token")
  valid_603036 = validateParameter(valid_603036, JString, required = false,
                                 default = nil)
  if valid_603036 != nil:
    section.add "X-Amz-Security-Token", valid_603036
  var valid_603037 = header.getOrDefault("X-Amz-Algorithm")
  valid_603037 = validateParameter(valid_603037, JString, required = false,
                                 default = nil)
  if valid_603037 != nil:
    section.add "X-Amz-Algorithm", valid_603037
  var valid_603038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603038 = validateParameter(valid_603038, JString, required = false,
                                 default = nil)
  if valid_603038 != nil:
    section.add "X-Amz-SignedHeaders", valid_603038
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603039: Call_GetDescribeInstancesHealth_603023; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves detailed information about the health of instances in your AWS Elastic Beanstalk. This operation requires <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/health-enhanced.html">enhanced health reporting</a>.
  ## 
  let valid = call_603039.validator(path, query, header, formData, body)
  let scheme = call_603039.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603039.url(scheme.get, call_603039.host, call_603039.base,
                         call_603039.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603039, url, valid)

proc call*(call_603040: Call_GetDescribeInstancesHealth_603023;
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
  var query_603041 = newJObject()
  if AttributeNames != nil:
    query_603041.add "AttributeNames", AttributeNames
  add(query_603041, "NextToken", newJString(NextToken))
  add(query_603041, "EnvironmentName", newJString(EnvironmentName))
  add(query_603041, "Action", newJString(Action))
  add(query_603041, "Version", newJString(Version))
  add(query_603041, "EnvironmentId", newJString(EnvironmentId))
  result = call_603040.call(nil, query_603041, nil, nil, nil)

var getDescribeInstancesHealth* = Call_GetDescribeInstancesHealth_603023(
    name: "getDescribeInstancesHealth", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribeInstancesHealth",
    validator: validate_GetDescribeInstancesHealth_603024, base: "/",
    url: url_GetDescribeInstancesHealth_603025,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribePlatformVersion_603078 = ref object of OpenApiRestCall_601390
proc url_PostDescribePlatformVersion_603080(protocol: Scheme; host: string;
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

proc validate_PostDescribePlatformVersion_603079(path: JsonNode; query: JsonNode;
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
  var valid_603081 = query.getOrDefault("Action")
  valid_603081 = validateParameter(valid_603081, JString, required = true, default = newJString(
      "DescribePlatformVersion"))
  if valid_603081 != nil:
    section.add "Action", valid_603081
  var valid_603082 = query.getOrDefault("Version")
  valid_603082 = validateParameter(valid_603082, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603082 != nil:
    section.add "Version", valid_603082
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
  var valid_603083 = header.getOrDefault("X-Amz-Signature")
  valid_603083 = validateParameter(valid_603083, JString, required = false,
                                 default = nil)
  if valid_603083 != nil:
    section.add "X-Amz-Signature", valid_603083
  var valid_603084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603084 = validateParameter(valid_603084, JString, required = false,
                                 default = nil)
  if valid_603084 != nil:
    section.add "X-Amz-Content-Sha256", valid_603084
  var valid_603085 = header.getOrDefault("X-Amz-Date")
  valid_603085 = validateParameter(valid_603085, JString, required = false,
                                 default = nil)
  if valid_603085 != nil:
    section.add "X-Amz-Date", valid_603085
  var valid_603086 = header.getOrDefault("X-Amz-Credential")
  valid_603086 = validateParameter(valid_603086, JString, required = false,
                                 default = nil)
  if valid_603086 != nil:
    section.add "X-Amz-Credential", valid_603086
  var valid_603087 = header.getOrDefault("X-Amz-Security-Token")
  valid_603087 = validateParameter(valid_603087, JString, required = false,
                                 default = nil)
  if valid_603087 != nil:
    section.add "X-Amz-Security-Token", valid_603087
  var valid_603088 = header.getOrDefault("X-Amz-Algorithm")
  valid_603088 = validateParameter(valid_603088, JString, required = false,
                                 default = nil)
  if valid_603088 != nil:
    section.add "X-Amz-Algorithm", valid_603088
  var valid_603089 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603089 = validateParameter(valid_603089, JString, required = false,
                                 default = nil)
  if valid_603089 != nil:
    section.add "X-Amz-SignedHeaders", valid_603089
  result.add "header", section
  ## parameters in `formData` object:
  ##   PlatformArn: JString
  ##              : The ARN of the version of the platform.
  section = newJObject()
  var valid_603090 = formData.getOrDefault("PlatformArn")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "PlatformArn", valid_603090
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603091: Call_PostDescribePlatformVersion_603078; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the version of the platform.
  ## 
  let valid = call_603091.validator(path, query, header, formData, body)
  let scheme = call_603091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603091.url(scheme.get, call_603091.host, call_603091.base,
                         call_603091.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603091, url, valid)

proc call*(call_603092: Call_PostDescribePlatformVersion_603078;
          Action: string = "DescribePlatformVersion";
          Version: string = "2010-12-01"; PlatformArn: string = ""): Recallable =
  ## postDescribePlatformVersion
  ## Describes the version of the platform.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   PlatformArn: string
  ##              : The ARN of the version of the platform.
  var query_603093 = newJObject()
  var formData_603094 = newJObject()
  add(query_603093, "Action", newJString(Action))
  add(query_603093, "Version", newJString(Version))
  add(formData_603094, "PlatformArn", newJString(PlatformArn))
  result = call_603092.call(nil, query_603093, nil, formData_603094, nil)

var postDescribePlatformVersion* = Call_PostDescribePlatformVersion_603078(
    name: "postDescribePlatformVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribePlatformVersion",
    validator: validate_PostDescribePlatformVersion_603079, base: "/",
    url: url_PostDescribePlatformVersion_603080,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribePlatformVersion_603062 = ref object of OpenApiRestCall_601390
proc url_GetDescribePlatformVersion_603064(protocol: Scheme; host: string;
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

proc validate_GetDescribePlatformVersion_603063(path: JsonNode; query: JsonNode;
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
  var valid_603065 = query.getOrDefault("Action")
  valid_603065 = validateParameter(valid_603065, JString, required = true, default = newJString(
      "DescribePlatformVersion"))
  if valid_603065 != nil:
    section.add "Action", valid_603065
  var valid_603066 = query.getOrDefault("PlatformArn")
  valid_603066 = validateParameter(valid_603066, JString, required = false,
                                 default = nil)
  if valid_603066 != nil:
    section.add "PlatformArn", valid_603066
  var valid_603067 = query.getOrDefault("Version")
  valid_603067 = validateParameter(valid_603067, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603067 != nil:
    section.add "Version", valid_603067
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
  var valid_603068 = header.getOrDefault("X-Amz-Signature")
  valid_603068 = validateParameter(valid_603068, JString, required = false,
                                 default = nil)
  if valid_603068 != nil:
    section.add "X-Amz-Signature", valid_603068
  var valid_603069 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603069 = validateParameter(valid_603069, JString, required = false,
                                 default = nil)
  if valid_603069 != nil:
    section.add "X-Amz-Content-Sha256", valid_603069
  var valid_603070 = header.getOrDefault("X-Amz-Date")
  valid_603070 = validateParameter(valid_603070, JString, required = false,
                                 default = nil)
  if valid_603070 != nil:
    section.add "X-Amz-Date", valid_603070
  var valid_603071 = header.getOrDefault("X-Amz-Credential")
  valid_603071 = validateParameter(valid_603071, JString, required = false,
                                 default = nil)
  if valid_603071 != nil:
    section.add "X-Amz-Credential", valid_603071
  var valid_603072 = header.getOrDefault("X-Amz-Security-Token")
  valid_603072 = validateParameter(valid_603072, JString, required = false,
                                 default = nil)
  if valid_603072 != nil:
    section.add "X-Amz-Security-Token", valid_603072
  var valid_603073 = header.getOrDefault("X-Amz-Algorithm")
  valid_603073 = validateParameter(valid_603073, JString, required = false,
                                 default = nil)
  if valid_603073 != nil:
    section.add "X-Amz-Algorithm", valid_603073
  var valid_603074 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603074 = validateParameter(valid_603074, JString, required = false,
                                 default = nil)
  if valid_603074 != nil:
    section.add "X-Amz-SignedHeaders", valid_603074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603075: Call_GetDescribePlatformVersion_603062; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the version of the platform.
  ## 
  let valid = call_603075.validator(path, query, header, formData, body)
  let scheme = call_603075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603075.url(scheme.get, call_603075.host, call_603075.base,
                         call_603075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603075, url, valid)

proc call*(call_603076: Call_GetDescribePlatformVersion_603062;
          Action: string = "DescribePlatformVersion"; PlatformArn: string = "";
          Version: string = "2010-12-01"): Recallable =
  ## getDescribePlatformVersion
  ## Describes the version of the platform.
  ##   Action: string (required)
  ##   PlatformArn: string
  ##              : The ARN of the version of the platform.
  ##   Version: string (required)
  var query_603077 = newJObject()
  add(query_603077, "Action", newJString(Action))
  add(query_603077, "PlatformArn", newJString(PlatformArn))
  add(query_603077, "Version", newJString(Version))
  result = call_603076.call(nil, query_603077, nil, nil, nil)

var getDescribePlatformVersion* = Call_GetDescribePlatformVersion_603062(
    name: "getDescribePlatformVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=DescribePlatformVersion",
    validator: validate_GetDescribePlatformVersion_603063, base: "/",
    url: url_GetDescribePlatformVersion_603064,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListAvailableSolutionStacks_603110 = ref object of OpenApiRestCall_601390
proc url_PostListAvailableSolutionStacks_603112(protocol: Scheme; host: string;
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

proc validate_PostListAvailableSolutionStacks_603111(path: JsonNode;
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
  var valid_603113 = query.getOrDefault("Action")
  valid_603113 = validateParameter(valid_603113, JString, required = true, default = newJString(
      "ListAvailableSolutionStacks"))
  if valid_603113 != nil:
    section.add "Action", valid_603113
  var valid_603114 = query.getOrDefault("Version")
  valid_603114 = validateParameter(valid_603114, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603114 != nil:
    section.add "Version", valid_603114
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
  var valid_603115 = header.getOrDefault("X-Amz-Signature")
  valid_603115 = validateParameter(valid_603115, JString, required = false,
                                 default = nil)
  if valid_603115 != nil:
    section.add "X-Amz-Signature", valid_603115
  var valid_603116 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603116 = validateParameter(valid_603116, JString, required = false,
                                 default = nil)
  if valid_603116 != nil:
    section.add "X-Amz-Content-Sha256", valid_603116
  var valid_603117 = header.getOrDefault("X-Amz-Date")
  valid_603117 = validateParameter(valid_603117, JString, required = false,
                                 default = nil)
  if valid_603117 != nil:
    section.add "X-Amz-Date", valid_603117
  var valid_603118 = header.getOrDefault("X-Amz-Credential")
  valid_603118 = validateParameter(valid_603118, JString, required = false,
                                 default = nil)
  if valid_603118 != nil:
    section.add "X-Amz-Credential", valid_603118
  var valid_603119 = header.getOrDefault("X-Amz-Security-Token")
  valid_603119 = validateParameter(valid_603119, JString, required = false,
                                 default = nil)
  if valid_603119 != nil:
    section.add "X-Amz-Security-Token", valid_603119
  var valid_603120 = header.getOrDefault("X-Amz-Algorithm")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Algorithm", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-SignedHeaders", valid_603121
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603122: Call_PostListAvailableSolutionStacks_603110;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ## 
  let valid = call_603122.validator(path, query, header, formData, body)
  let scheme = call_603122.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603122.url(scheme.get, call_603122.host, call_603122.base,
                         call_603122.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603122, url, valid)

proc call*(call_603123: Call_PostListAvailableSolutionStacks_603110;
          Action: string = "ListAvailableSolutionStacks";
          Version: string = "2010-12-01"): Recallable =
  ## postListAvailableSolutionStacks
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603124 = newJObject()
  add(query_603124, "Action", newJString(Action))
  add(query_603124, "Version", newJString(Version))
  result = call_603123.call(nil, query_603124, nil, nil, nil)

var postListAvailableSolutionStacks* = Call_PostListAvailableSolutionStacks_603110(
    name: "postListAvailableSolutionStacks", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListAvailableSolutionStacks",
    validator: validate_PostListAvailableSolutionStacks_603111, base: "/",
    url: url_PostListAvailableSolutionStacks_603112,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListAvailableSolutionStacks_603095 = ref object of OpenApiRestCall_601390
proc url_GetListAvailableSolutionStacks_603097(protocol: Scheme; host: string;
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

proc validate_GetListAvailableSolutionStacks_603096(path: JsonNode;
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
  var valid_603098 = query.getOrDefault("Action")
  valid_603098 = validateParameter(valid_603098, JString, required = true, default = newJString(
      "ListAvailableSolutionStacks"))
  if valid_603098 != nil:
    section.add "Action", valid_603098
  var valid_603099 = query.getOrDefault("Version")
  valid_603099 = validateParameter(valid_603099, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603099 != nil:
    section.add "Version", valid_603099
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
  var valid_603100 = header.getOrDefault("X-Amz-Signature")
  valid_603100 = validateParameter(valid_603100, JString, required = false,
                                 default = nil)
  if valid_603100 != nil:
    section.add "X-Amz-Signature", valid_603100
  var valid_603101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603101 = validateParameter(valid_603101, JString, required = false,
                                 default = nil)
  if valid_603101 != nil:
    section.add "X-Amz-Content-Sha256", valid_603101
  var valid_603102 = header.getOrDefault("X-Amz-Date")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "X-Amz-Date", valid_603102
  var valid_603103 = header.getOrDefault("X-Amz-Credential")
  valid_603103 = validateParameter(valid_603103, JString, required = false,
                                 default = nil)
  if valid_603103 != nil:
    section.add "X-Amz-Credential", valid_603103
  var valid_603104 = header.getOrDefault("X-Amz-Security-Token")
  valid_603104 = validateParameter(valid_603104, JString, required = false,
                                 default = nil)
  if valid_603104 != nil:
    section.add "X-Amz-Security-Token", valid_603104
  var valid_603105 = header.getOrDefault("X-Amz-Algorithm")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Algorithm", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-SignedHeaders", valid_603106
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603107: Call_GetListAvailableSolutionStacks_603095; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ## 
  let valid = call_603107.validator(path, query, header, formData, body)
  let scheme = call_603107.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603107.url(scheme.get, call_603107.host, call_603107.base,
                         call_603107.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603107, url, valid)

proc call*(call_603108: Call_GetListAvailableSolutionStacks_603095;
          Action: string = "ListAvailableSolutionStacks";
          Version: string = "2010-12-01"): Recallable =
  ## getListAvailableSolutionStacks
  ## Returns a list of the available solution stack names, with the public version first and then in reverse chronological order.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603109 = newJObject()
  add(query_603109, "Action", newJString(Action))
  add(query_603109, "Version", newJString(Version))
  result = call_603108.call(nil, query_603109, nil, nil, nil)

var getListAvailableSolutionStacks* = Call_GetListAvailableSolutionStacks_603095(
    name: "getListAvailableSolutionStacks", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListAvailableSolutionStacks",
    validator: validate_GetListAvailableSolutionStacks_603096, base: "/",
    url: url_GetListAvailableSolutionStacks_603097,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListPlatformVersions_603143 = ref object of OpenApiRestCall_601390
proc url_PostListPlatformVersions_603145(protocol: Scheme; host: string;
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

proc validate_PostListPlatformVersions_603144(path: JsonNode; query: JsonNode;
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
  var valid_603146 = query.getOrDefault("Action")
  valid_603146 = validateParameter(valid_603146, JString, required = true,
                                 default = newJString("ListPlatformVersions"))
  if valid_603146 != nil:
    section.add "Action", valid_603146
  var valid_603147 = query.getOrDefault("Version")
  valid_603147 = validateParameter(valid_603147, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603147 != nil:
    section.add "Version", valid_603147
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
  var valid_603148 = header.getOrDefault("X-Amz-Signature")
  valid_603148 = validateParameter(valid_603148, JString, required = false,
                                 default = nil)
  if valid_603148 != nil:
    section.add "X-Amz-Signature", valid_603148
  var valid_603149 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603149 = validateParameter(valid_603149, JString, required = false,
                                 default = nil)
  if valid_603149 != nil:
    section.add "X-Amz-Content-Sha256", valid_603149
  var valid_603150 = header.getOrDefault("X-Amz-Date")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "X-Amz-Date", valid_603150
  var valid_603151 = header.getOrDefault("X-Amz-Credential")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-Credential", valid_603151
  var valid_603152 = header.getOrDefault("X-Amz-Security-Token")
  valid_603152 = validateParameter(valid_603152, JString, required = false,
                                 default = nil)
  if valid_603152 != nil:
    section.add "X-Amz-Security-Token", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-Algorithm")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-Algorithm", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-SignedHeaders", valid_603154
  result.add "header", section
  ## parameters in `formData` object:
  ##   NextToken: JString
  ##            : The starting index into the remaining list of platforms. Use the <code>NextToken</code> value from a previous <code>ListPlatformVersion</code> call.
  ##   MaxRecords: JInt
  ##             : The maximum number of platform values returned in one call.
  ##   Filters: JArray
  ##          : List only the platforms where the platform member value relates to one of the supplied values.
  section = newJObject()
  var valid_603155 = formData.getOrDefault("NextToken")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "NextToken", valid_603155
  var valid_603156 = formData.getOrDefault("MaxRecords")
  valid_603156 = validateParameter(valid_603156, JInt, required = false, default = nil)
  if valid_603156 != nil:
    section.add "MaxRecords", valid_603156
  var valid_603157 = formData.getOrDefault("Filters")
  valid_603157 = validateParameter(valid_603157, JArray, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "Filters", valid_603157
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603158: Call_PostListPlatformVersions_603143; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the available platforms.
  ## 
  let valid = call_603158.validator(path, query, header, formData, body)
  let scheme = call_603158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603158.url(scheme.get, call_603158.host, call_603158.base,
                         call_603158.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603158, url, valid)

proc call*(call_603159: Call_PostListPlatformVersions_603143;
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
  var query_603160 = newJObject()
  var formData_603161 = newJObject()
  add(formData_603161, "NextToken", newJString(NextToken))
  add(formData_603161, "MaxRecords", newJInt(MaxRecords))
  add(query_603160, "Action", newJString(Action))
  if Filters != nil:
    formData_603161.add "Filters", Filters
  add(query_603160, "Version", newJString(Version))
  result = call_603159.call(nil, query_603160, nil, formData_603161, nil)

var postListPlatformVersions* = Call_PostListPlatformVersions_603143(
    name: "postListPlatformVersions", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListPlatformVersions",
    validator: validate_PostListPlatformVersions_603144, base: "/",
    url: url_PostListPlatformVersions_603145, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListPlatformVersions_603125 = ref object of OpenApiRestCall_601390
proc url_GetListPlatformVersions_603127(protocol: Scheme; host: string; base: string;
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

proc validate_GetListPlatformVersions_603126(path: JsonNode; query: JsonNode;
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
  var valid_603128 = query.getOrDefault("NextToken")
  valid_603128 = validateParameter(valid_603128, JString, required = false,
                                 default = nil)
  if valid_603128 != nil:
    section.add "NextToken", valid_603128
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603129 = query.getOrDefault("Action")
  valid_603129 = validateParameter(valid_603129, JString, required = true,
                                 default = newJString("ListPlatformVersions"))
  if valid_603129 != nil:
    section.add "Action", valid_603129
  var valid_603130 = query.getOrDefault("Version")
  valid_603130 = validateParameter(valid_603130, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603130 != nil:
    section.add "Version", valid_603130
  var valid_603131 = query.getOrDefault("Filters")
  valid_603131 = validateParameter(valid_603131, JArray, required = false,
                                 default = nil)
  if valid_603131 != nil:
    section.add "Filters", valid_603131
  var valid_603132 = query.getOrDefault("MaxRecords")
  valid_603132 = validateParameter(valid_603132, JInt, required = false, default = nil)
  if valid_603132 != nil:
    section.add "MaxRecords", valid_603132
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
  var valid_603133 = header.getOrDefault("X-Amz-Signature")
  valid_603133 = validateParameter(valid_603133, JString, required = false,
                                 default = nil)
  if valid_603133 != nil:
    section.add "X-Amz-Signature", valid_603133
  var valid_603134 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603134 = validateParameter(valid_603134, JString, required = false,
                                 default = nil)
  if valid_603134 != nil:
    section.add "X-Amz-Content-Sha256", valid_603134
  var valid_603135 = header.getOrDefault("X-Amz-Date")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-Date", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-Credential")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Credential", valid_603136
  var valid_603137 = header.getOrDefault("X-Amz-Security-Token")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "X-Amz-Security-Token", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-Algorithm")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Algorithm", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-SignedHeaders", valid_603139
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603140: Call_GetListPlatformVersions_603125; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the available platforms.
  ## 
  let valid = call_603140.validator(path, query, header, formData, body)
  let scheme = call_603140.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603140.url(scheme.get, call_603140.host, call_603140.base,
                         call_603140.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603140, url, valid)

proc call*(call_603141: Call_GetListPlatformVersions_603125;
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
  var query_603142 = newJObject()
  add(query_603142, "NextToken", newJString(NextToken))
  add(query_603142, "Action", newJString(Action))
  add(query_603142, "Version", newJString(Version))
  if Filters != nil:
    query_603142.add "Filters", Filters
  add(query_603142, "MaxRecords", newJInt(MaxRecords))
  result = call_603141.call(nil, query_603142, nil, nil, nil)

var getListPlatformVersions* = Call_GetListPlatformVersions_603125(
    name: "getListPlatformVersions", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ListPlatformVersions",
    validator: validate_GetListPlatformVersions_603126, base: "/",
    url: url_GetListPlatformVersions_603127, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_603178 = ref object of OpenApiRestCall_601390
proc url_PostListTagsForResource_603180(protocol: Scheme; host: string; base: string;
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

proc validate_PostListTagsForResource_603179(path: JsonNode; query: JsonNode;
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
  var valid_603181 = query.getOrDefault("Action")
  valid_603181 = validateParameter(valid_603181, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_603181 != nil:
    section.add "Action", valid_603181
  var valid_603182 = query.getOrDefault("Version")
  valid_603182 = validateParameter(valid_603182, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603182 != nil:
    section.add "Version", valid_603182
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
  var valid_603183 = header.getOrDefault("X-Amz-Signature")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "X-Amz-Signature", valid_603183
  var valid_603184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "X-Amz-Content-Sha256", valid_603184
  var valid_603185 = header.getOrDefault("X-Amz-Date")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "X-Amz-Date", valid_603185
  var valid_603186 = header.getOrDefault("X-Amz-Credential")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "X-Amz-Credential", valid_603186
  var valid_603187 = header.getOrDefault("X-Amz-Security-Token")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "X-Amz-Security-Token", valid_603187
  var valid_603188 = header.getOrDefault("X-Amz-Algorithm")
  valid_603188 = validateParameter(valid_603188, JString, required = false,
                                 default = nil)
  if valid_603188 != nil:
    section.add "X-Amz-Algorithm", valid_603188
  var valid_603189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603189 = validateParameter(valid_603189, JString, required = false,
                                 default = nil)
  if valid_603189 != nil:
    section.add "X-Amz-SignedHeaders", valid_603189
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceArn: JString (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce for which a tag list is requested.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceArn` field"
  var valid_603190 = formData.getOrDefault("ResourceArn")
  valid_603190 = validateParameter(valid_603190, JString, required = true,
                                 default = nil)
  if valid_603190 != nil:
    section.add "ResourceArn", valid_603190
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603191: Call_PostListTagsForResource_603178; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ## 
  let valid = call_603191.validator(path, query, header, formData, body)
  let scheme = call_603191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603191.url(scheme.get, call_603191.host, call_603191.base,
                         call_603191.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603191, url, valid)

proc call*(call_603192: Call_PostListTagsForResource_603178; ResourceArn: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-12-01"): Recallable =
  ## postListTagsForResource
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ##   ResourceArn: string (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce for which a tag list is requested.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603193 = newJObject()
  var formData_603194 = newJObject()
  add(formData_603194, "ResourceArn", newJString(ResourceArn))
  add(query_603193, "Action", newJString(Action))
  add(query_603193, "Version", newJString(Version))
  result = call_603192.call(nil, query_603193, nil, formData_603194, nil)

var postListTagsForResource* = Call_PostListTagsForResource_603178(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_603179, base: "/",
    url: url_PostListTagsForResource_603180, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_603162 = ref object of OpenApiRestCall_601390
proc url_GetListTagsForResource_603164(protocol: Scheme; host: string; base: string;
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

proc validate_GetListTagsForResource_603163(path: JsonNode; query: JsonNode;
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
  var valid_603165 = query.getOrDefault("ResourceArn")
  valid_603165 = validateParameter(valid_603165, JString, required = true,
                                 default = nil)
  if valid_603165 != nil:
    section.add "ResourceArn", valid_603165
  var valid_603166 = query.getOrDefault("Action")
  valid_603166 = validateParameter(valid_603166, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_603166 != nil:
    section.add "Action", valid_603166
  var valid_603167 = query.getOrDefault("Version")
  valid_603167 = validateParameter(valid_603167, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603167 != nil:
    section.add "Version", valid_603167
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
  var valid_603168 = header.getOrDefault("X-Amz-Signature")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "X-Amz-Signature", valid_603168
  var valid_603169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "X-Amz-Content-Sha256", valid_603169
  var valid_603170 = header.getOrDefault("X-Amz-Date")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "X-Amz-Date", valid_603170
  var valid_603171 = header.getOrDefault("X-Amz-Credential")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "X-Amz-Credential", valid_603171
  var valid_603172 = header.getOrDefault("X-Amz-Security-Token")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "X-Amz-Security-Token", valid_603172
  var valid_603173 = header.getOrDefault("X-Amz-Algorithm")
  valid_603173 = validateParameter(valid_603173, JString, required = false,
                                 default = nil)
  if valid_603173 != nil:
    section.add "X-Amz-Algorithm", valid_603173
  var valid_603174 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603174 = validateParameter(valid_603174, JString, required = false,
                                 default = nil)
  if valid_603174 != nil:
    section.add "X-Amz-SignedHeaders", valid_603174
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603175: Call_GetListTagsForResource_603162; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ## 
  let valid = call_603175.validator(path, query, header, formData, body)
  let scheme = call_603175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603175.url(scheme.get, call_603175.host, call_603175.base,
                         call_603175.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603175, url, valid)

proc call*(call_603176: Call_GetListTagsForResource_603162; ResourceArn: string;
          Action: string = "ListTagsForResource"; Version: string = "2010-12-01"): Recallable =
  ## getListTagsForResource
  ## <p>Returns the tags applied to an AWS Elastic Beanstalk resource. The response contains a list of tag key-value pairs.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p>
  ##   ResourceArn: string (required)
  ##              : <p>The Amazon Resource Name (ARN) of the resouce for which a tag list is requested.</p> <p>Must be the ARN of an Elastic Beanstalk environment.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603177 = newJObject()
  add(query_603177, "ResourceArn", newJString(ResourceArn))
  add(query_603177, "Action", newJString(Action))
  add(query_603177, "Version", newJString(Version))
  result = call_603176.call(nil, query_603177, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_603162(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_603163, base: "/",
    url: url_GetListTagsForResource_603164, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebuildEnvironment_603212 = ref object of OpenApiRestCall_601390
proc url_PostRebuildEnvironment_603214(protocol: Scheme; host: string; base: string;
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

proc validate_PostRebuildEnvironment_603213(path: JsonNode; query: JsonNode;
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
  var valid_603215 = query.getOrDefault("Action")
  valid_603215 = validateParameter(valid_603215, JString, required = true,
                                 default = newJString("RebuildEnvironment"))
  if valid_603215 != nil:
    section.add "Action", valid_603215
  var valid_603216 = query.getOrDefault("Version")
  valid_603216 = validateParameter(valid_603216, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603216 != nil:
    section.add "Version", valid_603216
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
  var valid_603217 = header.getOrDefault("X-Amz-Signature")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "X-Amz-Signature", valid_603217
  var valid_603218 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603218 = validateParameter(valid_603218, JString, required = false,
                                 default = nil)
  if valid_603218 != nil:
    section.add "X-Amz-Content-Sha256", valid_603218
  var valid_603219 = header.getOrDefault("X-Amz-Date")
  valid_603219 = validateParameter(valid_603219, JString, required = false,
                                 default = nil)
  if valid_603219 != nil:
    section.add "X-Amz-Date", valid_603219
  var valid_603220 = header.getOrDefault("X-Amz-Credential")
  valid_603220 = validateParameter(valid_603220, JString, required = false,
                                 default = nil)
  if valid_603220 != nil:
    section.add "X-Amz-Credential", valid_603220
  var valid_603221 = header.getOrDefault("X-Amz-Security-Token")
  valid_603221 = validateParameter(valid_603221, JString, required = false,
                                 default = nil)
  if valid_603221 != nil:
    section.add "X-Amz-Security-Token", valid_603221
  var valid_603222 = header.getOrDefault("X-Amz-Algorithm")
  valid_603222 = validateParameter(valid_603222, JString, required = false,
                                 default = nil)
  if valid_603222 != nil:
    section.add "X-Amz-Algorithm", valid_603222
  var valid_603223 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603223 = validateParameter(valid_603223, JString, required = false,
                                 default = nil)
  if valid_603223 != nil:
    section.add "X-Amz-SignedHeaders", valid_603223
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to rebuild.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to rebuild.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_603224 = formData.getOrDefault("EnvironmentName")
  valid_603224 = validateParameter(valid_603224, JString, required = false,
                                 default = nil)
  if valid_603224 != nil:
    section.add "EnvironmentName", valid_603224
  var valid_603225 = formData.getOrDefault("EnvironmentId")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "EnvironmentId", valid_603225
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603226: Call_PostRebuildEnvironment_603212; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes and recreates all of the AWS resources (for example: the Auto Scaling group, load balancer, etc.) for a specified environment and forces a restart.
  ## 
  let valid = call_603226.validator(path, query, header, formData, body)
  let scheme = call_603226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603226.url(scheme.get, call_603226.host, call_603226.base,
                         call_603226.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603226, url, valid)

proc call*(call_603227: Call_PostRebuildEnvironment_603212;
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
  var query_603228 = newJObject()
  var formData_603229 = newJObject()
  add(formData_603229, "EnvironmentName", newJString(EnvironmentName))
  add(query_603228, "Action", newJString(Action))
  add(formData_603229, "EnvironmentId", newJString(EnvironmentId))
  add(query_603228, "Version", newJString(Version))
  result = call_603227.call(nil, query_603228, nil, formData_603229, nil)

var postRebuildEnvironment* = Call_PostRebuildEnvironment_603212(
    name: "postRebuildEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RebuildEnvironment",
    validator: validate_PostRebuildEnvironment_603213, base: "/",
    url: url_PostRebuildEnvironment_603214, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebuildEnvironment_603195 = ref object of OpenApiRestCall_601390
proc url_GetRebuildEnvironment_603197(protocol: Scheme; host: string; base: string;
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

proc validate_GetRebuildEnvironment_603196(path: JsonNode; query: JsonNode;
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
  var valid_603198 = query.getOrDefault("EnvironmentName")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "EnvironmentName", valid_603198
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603199 = query.getOrDefault("Action")
  valid_603199 = validateParameter(valid_603199, JString, required = true,
                                 default = newJString("RebuildEnvironment"))
  if valid_603199 != nil:
    section.add "Action", valid_603199
  var valid_603200 = query.getOrDefault("Version")
  valid_603200 = validateParameter(valid_603200, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603200 != nil:
    section.add "Version", valid_603200
  var valid_603201 = query.getOrDefault("EnvironmentId")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "EnvironmentId", valid_603201
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
  var valid_603202 = header.getOrDefault("X-Amz-Signature")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-Signature", valid_603202
  var valid_603203 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603203 = validateParameter(valid_603203, JString, required = false,
                                 default = nil)
  if valid_603203 != nil:
    section.add "X-Amz-Content-Sha256", valid_603203
  var valid_603204 = header.getOrDefault("X-Amz-Date")
  valid_603204 = validateParameter(valid_603204, JString, required = false,
                                 default = nil)
  if valid_603204 != nil:
    section.add "X-Amz-Date", valid_603204
  var valid_603205 = header.getOrDefault("X-Amz-Credential")
  valid_603205 = validateParameter(valid_603205, JString, required = false,
                                 default = nil)
  if valid_603205 != nil:
    section.add "X-Amz-Credential", valid_603205
  var valid_603206 = header.getOrDefault("X-Amz-Security-Token")
  valid_603206 = validateParameter(valid_603206, JString, required = false,
                                 default = nil)
  if valid_603206 != nil:
    section.add "X-Amz-Security-Token", valid_603206
  var valid_603207 = header.getOrDefault("X-Amz-Algorithm")
  valid_603207 = validateParameter(valid_603207, JString, required = false,
                                 default = nil)
  if valid_603207 != nil:
    section.add "X-Amz-Algorithm", valid_603207
  var valid_603208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603208 = validateParameter(valid_603208, JString, required = false,
                                 default = nil)
  if valid_603208 != nil:
    section.add "X-Amz-SignedHeaders", valid_603208
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603209: Call_GetRebuildEnvironment_603195; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes and recreates all of the AWS resources (for example: the Auto Scaling group, load balancer, etc.) for a specified environment and forces a restart.
  ## 
  let valid = call_603209.validator(path, query, header, formData, body)
  let scheme = call_603209.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603209.url(scheme.get, call_603209.host, call_603209.base,
                         call_603209.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603209, url, valid)

proc call*(call_603210: Call_GetRebuildEnvironment_603195;
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
  var query_603211 = newJObject()
  add(query_603211, "EnvironmentName", newJString(EnvironmentName))
  add(query_603211, "Action", newJString(Action))
  add(query_603211, "Version", newJString(Version))
  add(query_603211, "EnvironmentId", newJString(EnvironmentId))
  result = call_603210.call(nil, query_603211, nil, nil, nil)

var getRebuildEnvironment* = Call_GetRebuildEnvironment_603195(
    name: "getRebuildEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RebuildEnvironment",
    validator: validate_GetRebuildEnvironment_603196, base: "/",
    url: url_GetRebuildEnvironment_603197, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRequestEnvironmentInfo_603248 = ref object of OpenApiRestCall_601390
proc url_PostRequestEnvironmentInfo_603250(protocol: Scheme; host: string;
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

proc validate_PostRequestEnvironmentInfo_603249(path: JsonNode; query: JsonNode;
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
  var valid_603251 = query.getOrDefault("Action")
  valid_603251 = validateParameter(valid_603251, JString, required = true,
                                 default = newJString("RequestEnvironmentInfo"))
  if valid_603251 != nil:
    section.add "Action", valid_603251
  var valid_603252 = query.getOrDefault("Version")
  valid_603252 = validateParameter(valid_603252, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603252 != nil:
    section.add "Version", valid_603252
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
  var valid_603253 = header.getOrDefault("X-Amz-Signature")
  valid_603253 = validateParameter(valid_603253, JString, required = false,
                                 default = nil)
  if valid_603253 != nil:
    section.add "X-Amz-Signature", valid_603253
  var valid_603254 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603254 = validateParameter(valid_603254, JString, required = false,
                                 default = nil)
  if valid_603254 != nil:
    section.add "X-Amz-Content-Sha256", valid_603254
  var valid_603255 = header.getOrDefault("X-Amz-Date")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "X-Amz-Date", valid_603255
  var valid_603256 = header.getOrDefault("X-Amz-Credential")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = nil)
  if valid_603256 != nil:
    section.add "X-Amz-Credential", valid_603256
  var valid_603257 = header.getOrDefault("X-Amz-Security-Token")
  valid_603257 = validateParameter(valid_603257, JString, required = false,
                                 default = nil)
  if valid_603257 != nil:
    section.add "X-Amz-Security-Token", valid_603257
  var valid_603258 = header.getOrDefault("X-Amz-Algorithm")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "X-Amz-Algorithm", valid_603258
  var valid_603259 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-SignedHeaders", valid_603259
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
  var valid_603260 = formData.getOrDefault("InfoType")
  valid_603260 = validateParameter(valid_603260, JString, required = true,
                                 default = newJString("tail"))
  if valid_603260 != nil:
    section.add "InfoType", valid_603260
  var valid_603261 = formData.getOrDefault("EnvironmentName")
  valid_603261 = validateParameter(valid_603261, JString, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "EnvironmentName", valid_603261
  var valid_603262 = formData.getOrDefault("EnvironmentId")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "EnvironmentId", valid_603262
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603263: Call_PostRequestEnvironmentInfo_603248; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a request to compile the specified type of information of the deployed environment.</p> <p> Setting the <code>InfoType</code> to <code>tail</code> compiles the last lines from the application server log files of every Amazon EC2 instance in your environment. </p> <p> Setting the <code>InfoType</code> to <code>bundle</code> compresses the application server log files for every Amazon EC2 instance into a <code>.zip</code> file. Legacy and .NET containers do not support bundle logs. </p> <p> Use <a>RetrieveEnvironmentInfo</a> to obtain the set of logs. </p> <p>Related Topics</p> <ul> <li> <p> <a>RetrieveEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_603263.validator(path, query, header, formData, body)
  let scheme = call_603263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603263.url(scheme.get, call_603263.host, call_603263.base,
                         call_603263.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603263, url, valid)

proc call*(call_603264: Call_PostRequestEnvironmentInfo_603248;
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
  var query_603265 = newJObject()
  var formData_603266 = newJObject()
  add(formData_603266, "InfoType", newJString(InfoType))
  add(formData_603266, "EnvironmentName", newJString(EnvironmentName))
  add(query_603265, "Action", newJString(Action))
  add(formData_603266, "EnvironmentId", newJString(EnvironmentId))
  add(query_603265, "Version", newJString(Version))
  result = call_603264.call(nil, query_603265, nil, formData_603266, nil)

var postRequestEnvironmentInfo* = Call_PostRequestEnvironmentInfo_603248(
    name: "postRequestEnvironmentInfo", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RequestEnvironmentInfo",
    validator: validate_PostRequestEnvironmentInfo_603249, base: "/",
    url: url_PostRequestEnvironmentInfo_603250,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRequestEnvironmentInfo_603230 = ref object of OpenApiRestCall_601390
proc url_GetRequestEnvironmentInfo_603232(protocol: Scheme; host: string;
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

proc validate_GetRequestEnvironmentInfo_603231(path: JsonNode; query: JsonNode;
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
  var valid_603233 = query.getOrDefault("InfoType")
  valid_603233 = validateParameter(valid_603233, JString, required = true,
                                 default = newJString("tail"))
  if valid_603233 != nil:
    section.add "InfoType", valid_603233
  var valid_603234 = query.getOrDefault("EnvironmentName")
  valid_603234 = validateParameter(valid_603234, JString, required = false,
                                 default = nil)
  if valid_603234 != nil:
    section.add "EnvironmentName", valid_603234
  var valid_603235 = query.getOrDefault("Action")
  valid_603235 = validateParameter(valid_603235, JString, required = true,
                                 default = newJString("RequestEnvironmentInfo"))
  if valid_603235 != nil:
    section.add "Action", valid_603235
  var valid_603236 = query.getOrDefault("Version")
  valid_603236 = validateParameter(valid_603236, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603236 != nil:
    section.add "Version", valid_603236
  var valid_603237 = query.getOrDefault("EnvironmentId")
  valid_603237 = validateParameter(valid_603237, JString, required = false,
                                 default = nil)
  if valid_603237 != nil:
    section.add "EnvironmentId", valid_603237
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
  var valid_603238 = header.getOrDefault("X-Amz-Signature")
  valid_603238 = validateParameter(valid_603238, JString, required = false,
                                 default = nil)
  if valid_603238 != nil:
    section.add "X-Amz-Signature", valid_603238
  var valid_603239 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603239 = validateParameter(valid_603239, JString, required = false,
                                 default = nil)
  if valid_603239 != nil:
    section.add "X-Amz-Content-Sha256", valid_603239
  var valid_603240 = header.getOrDefault("X-Amz-Date")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-Date", valid_603240
  var valid_603241 = header.getOrDefault("X-Amz-Credential")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "X-Amz-Credential", valid_603241
  var valid_603242 = header.getOrDefault("X-Amz-Security-Token")
  valid_603242 = validateParameter(valid_603242, JString, required = false,
                                 default = nil)
  if valid_603242 != nil:
    section.add "X-Amz-Security-Token", valid_603242
  var valid_603243 = header.getOrDefault("X-Amz-Algorithm")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-Algorithm", valid_603243
  var valid_603244 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amz-SignedHeaders", valid_603244
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603245: Call_GetRequestEnvironmentInfo_603230; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Initiates a request to compile the specified type of information of the deployed environment.</p> <p> Setting the <code>InfoType</code> to <code>tail</code> compiles the last lines from the application server log files of every Amazon EC2 instance in your environment. </p> <p> Setting the <code>InfoType</code> to <code>bundle</code> compresses the application server log files for every Amazon EC2 instance into a <code>.zip</code> file. Legacy and .NET containers do not support bundle logs. </p> <p> Use <a>RetrieveEnvironmentInfo</a> to obtain the set of logs. </p> <p>Related Topics</p> <ul> <li> <p> <a>RetrieveEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_603245.validator(path, query, header, formData, body)
  let scheme = call_603245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603245.url(scheme.get, call_603245.host, call_603245.base,
                         call_603245.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603245, url, valid)

proc call*(call_603246: Call_GetRequestEnvironmentInfo_603230;
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
  var query_603247 = newJObject()
  add(query_603247, "InfoType", newJString(InfoType))
  add(query_603247, "EnvironmentName", newJString(EnvironmentName))
  add(query_603247, "Action", newJString(Action))
  add(query_603247, "Version", newJString(Version))
  add(query_603247, "EnvironmentId", newJString(EnvironmentId))
  result = call_603246.call(nil, query_603247, nil, nil, nil)

var getRequestEnvironmentInfo* = Call_GetRequestEnvironmentInfo_603230(
    name: "getRequestEnvironmentInfo", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RequestEnvironmentInfo",
    validator: validate_GetRequestEnvironmentInfo_603231, base: "/",
    url: url_GetRequestEnvironmentInfo_603232,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestartAppServer_603284 = ref object of OpenApiRestCall_601390
proc url_PostRestartAppServer_603286(protocol: Scheme; host: string; base: string;
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

proc validate_PostRestartAppServer_603285(path: JsonNode; query: JsonNode;
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
  var valid_603287 = query.getOrDefault("Action")
  valid_603287 = validateParameter(valid_603287, JString, required = true,
                                 default = newJString("RestartAppServer"))
  if valid_603287 != nil:
    section.add "Action", valid_603287
  var valid_603288 = query.getOrDefault("Version")
  valid_603288 = validateParameter(valid_603288, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603288 != nil:
    section.add "Version", valid_603288
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
  var valid_603289 = header.getOrDefault("X-Amz-Signature")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "X-Amz-Signature", valid_603289
  var valid_603290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603290 = validateParameter(valid_603290, JString, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "X-Amz-Content-Sha256", valid_603290
  var valid_603291 = header.getOrDefault("X-Amz-Date")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "X-Amz-Date", valid_603291
  var valid_603292 = header.getOrDefault("X-Amz-Credential")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "X-Amz-Credential", valid_603292
  var valid_603293 = header.getOrDefault("X-Amz-Security-Token")
  valid_603293 = validateParameter(valid_603293, JString, required = false,
                                 default = nil)
  if valid_603293 != nil:
    section.add "X-Amz-Security-Token", valid_603293
  var valid_603294 = header.getOrDefault("X-Amz-Algorithm")
  valid_603294 = validateParameter(valid_603294, JString, required = false,
                                 default = nil)
  if valid_603294 != nil:
    section.add "X-Amz-Algorithm", valid_603294
  var valid_603295 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603295 = validateParameter(valid_603295, JString, required = false,
                                 default = nil)
  if valid_603295 != nil:
    section.add "X-Amz-SignedHeaders", valid_603295
  result.add "header", section
  ## parameters in `formData` object:
  ##   EnvironmentName: JString
  ##                  : <p>The name of the environment to restart the server for.</p> <p> Condition: You must specify either this or an EnvironmentId, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  ##   EnvironmentId: JString
  ##                : <p>The ID of the environment to restart the server for.</p> <p> Condition: You must specify either this or an EnvironmentName, or both. If you do not specify either, AWS Elastic Beanstalk returns <code>MissingRequiredParameter</code> error. </p>
  section = newJObject()
  var valid_603296 = formData.getOrDefault("EnvironmentName")
  valid_603296 = validateParameter(valid_603296, JString, required = false,
                                 default = nil)
  if valid_603296 != nil:
    section.add "EnvironmentName", valid_603296
  var valid_603297 = formData.getOrDefault("EnvironmentId")
  valid_603297 = validateParameter(valid_603297, JString, required = false,
                                 default = nil)
  if valid_603297 != nil:
    section.add "EnvironmentId", valid_603297
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603298: Call_PostRestartAppServer_603284; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Causes the environment to restart the application container server running on each Amazon EC2 instance.
  ## 
  let valid = call_603298.validator(path, query, header, formData, body)
  let scheme = call_603298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603298.url(scheme.get, call_603298.host, call_603298.base,
                         call_603298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603298, url, valid)

proc call*(call_603299: Call_PostRestartAppServer_603284;
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
  var query_603300 = newJObject()
  var formData_603301 = newJObject()
  add(formData_603301, "EnvironmentName", newJString(EnvironmentName))
  add(query_603300, "Action", newJString(Action))
  add(formData_603301, "EnvironmentId", newJString(EnvironmentId))
  add(query_603300, "Version", newJString(Version))
  result = call_603299.call(nil, query_603300, nil, formData_603301, nil)

var postRestartAppServer* = Call_PostRestartAppServer_603284(
    name: "postRestartAppServer", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RestartAppServer",
    validator: validate_PostRestartAppServer_603285, base: "/",
    url: url_PostRestartAppServer_603286, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestartAppServer_603267 = ref object of OpenApiRestCall_601390
proc url_GetRestartAppServer_603269(protocol: Scheme; host: string; base: string;
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

proc validate_GetRestartAppServer_603268(path: JsonNode; query: JsonNode;
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
  var valid_603270 = query.getOrDefault("EnvironmentName")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "EnvironmentName", valid_603270
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603271 = query.getOrDefault("Action")
  valid_603271 = validateParameter(valid_603271, JString, required = true,
                                 default = newJString("RestartAppServer"))
  if valid_603271 != nil:
    section.add "Action", valid_603271
  var valid_603272 = query.getOrDefault("Version")
  valid_603272 = validateParameter(valid_603272, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603272 != nil:
    section.add "Version", valid_603272
  var valid_603273 = query.getOrDefault("EnvironmentId")
  valid_603273 = validateParameter(valid_603273, JString, required = false,
                                 default = nil)
  if valid_603273 != nil:
    section.add "EnvironmentId", valid_603273
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
  var valid_603274 = header.getOrDefault("X-Amz-Signature")
  valid_603274 = validateParameter(valid_603274, JString, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "X-Amz-Signature", valid_603274
  var valid_603275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603275 = validateParameter(valid_603275, JString, required = false,
                                 default = nil)
  if valid_603275 != nil:
    section.add "X-Amz-Content-Sha256", valid_603275
  var valid_603276 = header.getOrDefault("X-Amz-Date")
  valid_603276 = validateParameter(valid_603276, JString, required = false,
                                 default = nil)
  if valid_603276 != nil:
    section.add "X-Amz-Date", valid_603276
  var valid_603277 = header.getOrDefault("X-Amz-Credential")
  valid_603277 = validateParameter(valid_603277, JString, required = false,
                                 default = nil)
  if valid_603277 != nil:
    section.add "X-Amz-Credential", valid_603277
  var valid_603278 = header.getOrDefault("X-Amz-Security-Token")
  valid_603278 = validateParameter(valid_603278, JString, required = false,
                                 default = nil)
  if valid_603278 != nil:
    section.add "X-Amz-Security-Token", valid_603278
  var valid_603279 = header.getOrDefault("X-Amz-Algorithm")
  valid_603279 = validateParameter(valid_603279, JString, required = false,
                                 default = nil)
  if valid_603279 != nil:
    section.add "X-Amz-Algorithm", valid_603279
  var valid_603280 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603280 = validateParameter(valid_603280, JString, required = false,
                                 default = nil)
  if valid_603280 != nil:
    section.add "X-Amz-SignedHeaders", valid_603280
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603281: Call_GetRestartAppServer_603267; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Causes the environment to restart the application container server running on each Amazon EC2 instance.
  ## 
  let valid = call_603281.validator(path, query, header, formData, body)
  let scheme = call_603281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603281.url(scheme.get, call_603281.host, call_603281.base,
                         call_603281.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603281, url, valid)

proc call*(call_603282: Call_GetRestartAppServer_603267;
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
  var query_603283 = newJObject()
  add(query_603283, "EnvironmentName", newJString(EnvironmentName))
  add(query_603283, "Action", newJString(Action))
  add(query_603283, "Version", newJString(Version))
  add(query_603283, "EnvironmentId", newJString(EnvironmentId))
  result = call_603282.call(nil, query_603283, nil, nil, nil)

var getRestartAppServer* = Call_GetRestartAppServer_603267(
    name: "getRestartAppServer", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=RestartAppServer",
    validator: validate_GetRestartAppServer_603268, base: "/",
    url: url_GetRestartAppServer_603269, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRetrieveEnvironmentInfo_603320 = ref object of OpenApiRestCall_601390
proc url_PostRetrieveEnvironmentInfo_603322(protocol: Scheme; host: string;
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

proc validate_PostRetrieveEnvironmentInfo_603321(path: JsonNode; query: JsonNode;
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
  var valid_603323 = query.getOrDefault("Action")
  valid_603323 = validateParameter(valid_603323, JString, required = true, default = newJString(
      "RetrieveEnvironmentInfo"))
  if valid_603323 != nil:
    section.add "Action", valid_603323
  var valid_603324 = query.getOrDefault("Version")
  valid_603324 = validateParameter(valid_603324, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603324 != nil:
    section.add "Version", valid_603324
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
  var valid_603325 = header.getOrDefault("X-Amz-Signature")
  valid_603325 = validateParameter(valid_603325, JString, required = false,
                                 default = nil)
  if valid_603325 != nil:
    section.add "X-Amz-Signature", valid_603325
  var valid_603326 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603326 = validateParameter(valid_603326, JString, required = false,
                                 default = nil)
  if valid_603326 != nil:
    section.add "X-Amz-Content-Sha256", valid_603326
  var valid_603327 = header.getOrDefault("X-Amz-Date")
  valid_603327 = validateParameter(valid_603327, JString, required = false,
                                 default = nil)
  if valid_603327 != nil:
    section.add "X-Amz-Date", valid_603327
  var valid_603328 = header.getOrDefault("X-Amz-Credential")
  valid_603328 = validateParameter(valid_603328, JString, required = false,
                                 default = nil)
  if valid_603328 != nil:
    section.add "X-Amz-Credential", valid_603328
  var valid_603329 = header.getOrDefault("X-Amz-Security-Token")
  valid_603329 = validateParameter(valid_603329, JString, required = false,
                                 default = nil)
  if valid_603329 != nil:
    section.add "X-Amz-Security-Token", valid_603329
  var valid_603330 = header.getOrDefault("X-Amz-Algorithm")
  valid_603330 = validateParameter(valid_603330, JString, required = false,
                                 default = nil)
  if valid_603330 != nil:
    section.add "X-Amz-Algorithm", valid_603330
  var valid_603331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "X-Amz-SignedHeaders", valid_603331
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
  var valid_603332 = formData.getOrDefault("InfoType")
  valid_603332 = validateParameter(valid_603332, JString, required = true,
                                 default = newJString("tail"))
  if valid_603332 != nil:
    section.add "InfoType", valid_603332
  var valid_603333 = formData.getOrDefault("EnvironmentName")
  valid_603333 = validateParameter(valid_603333, JString, required = false,
                                 default = nil)
  if valid_603333 != nil:
    section.add "EnvironmentName", valid_603333
  var valid_603334 = formData.getOrDefault("EnvironmentId")
  valid_603334 = validateParameter(valid_603334, JString, required = false,
                                 default = nil)
  if valid_603334 != nil:
    section.add "EnvironmentId", valid_603334
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603335: Call_PostRetrieveEnvironmentInfo_603320; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the compiled information from a <a>RequestEnvironmentInfo</a> request.</p> <p>Related Topics</p> <ul> <li> <p> <a>RequestEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_603335.validator(path, query, header, formData, body)
  let scheme = call_603335.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603335.url(scheme.get, call_603335.host, call_603335.base,
                         call_603335.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603335, url, valid)

proc call*(call_603336: Call_PostRetrieveEnvironmentInfo_603320;
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
  var query_603337 = newJObject()
  var formData_603338 = newJObject()
  add(formData_603338, "InfoType", newJString(InfoType))
  add(formData_603338, "EnvironmentName", newJString(EnvironmentName))
  add(query_603337, "Action", newJString(Action))
  add(formData_603338, "EnvironmentId", newJString(EnvironmentId))
  add(query_603337, "Version", newJString(Version))
  result = call_603336.call(nil, query_603337, nil, formData_603338, nil)

var postRetrieveEnvironmentInfo* = Call_PostRetrieveEnvironmentInfo_603320(
    name: "postRetrieveEnvironmentInfo", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RetrieveEnvironmentInfo",
    validator: validate_PostRetrieveEnvironmentInfo_603321, base: "/",
    url: url_PostRetrieveEnvironmentInfo_603322,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRetrieveEnvironmentInfo_603302 = ref object of OpenApiRestCall_601390
proc url_GetRetrieveEnvironmentInfo_603304(protocol: Scheme; host: string;
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

proc validate_GetRetrieveEnvironmentInfo_603303(path: JsonNode; query: JsonNode;
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
  var valid_603305 = query.getOrDefault("InfoType")
  valid_603305 = validateParameter(valid_603305, JString, required = true,
                                 default = newJString("tail"))
  if valid_603305 != nil:
    section.add "InfoType", valid_603305
  var valid_603306 = query.getOrDefault("EnvironmentName")
  valid_603306 = validateParameter(valid_603306, JString, required = false,
                                 default = nil)
  if valid_603306 != nil:
    section.add "EnvironmentName", valid_603306
  var valid_603307 = query.getOrDefault("Action")
  valid_603307 = validateParameter(valid_603307, JString, required = true, default = newJString(
      "RetrieveEnvironmentInfo"))
  if valid_603307 != nil:
    section.add "Action", valid_603307
  var valid_603308 = query.getOrDefault("Version")
  valid_603308 = validateParameter(valid_603308, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603308 != nil:
    section.add "Version", valid_603308
  var valid_603309 = query.getOrDefault("EnvironmentId")
  valid_603309 = validateParameter(valid_603309, JString, required = false,
                                 default = nil)
  if valid_603309 != nil:
    section.add "EnvironmentId", valid_603309
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
  var valid_603310 = header.getOrDefault("X-Amz-Signature")
  valid_603310 = validateParameter(valid_603310, JString, required = false,
                                 default = nil)
  if valid_603310 != nil:
    section.add "X-Amz-Signature", valid_603310
  var valid_603311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603311 = validateParameter(valid_603311, JString, required = false,
                                 default = nil)
  if valid_603311 != nil:
    section.add "X-Amz-Content-Sha256", valid_603311
  var valid_603312 = header.getOrDefault("X-Amz-Date")
  valid_603312 = validateParameter(valid_603312, JString, required = false,
                                 default = nil)
  if valid_603312 != nil:
    section.add "X-Amz-Date", valid_603312
  var valid_603313 = header.getOrDefault("X-Amz-Credential")
  valid_603313 = validateParameter(valid_603313, JString, required = false,
                                 default = nil)
  if valid_603313 != nil:
    section.add "X-Amz-Credential", valid_603313
  var valid_603314 = header.getOrDefault("X-Amz-Security-Token")
  valid_603314 = validateParameter(valid_603314, JString, required = false,
                                 default = nil)
  if valid_603314 != nil:
    section.add "X-Amz-Security-Token", valid_603314
  var valid_603315 = header.getOrDefault("X-Amz-Algorithm")
  valid_603315 = validateParameter(valid_603315, JString, required = false,
                                 default = nil)
  if valid_603315 != nil:
    section.add "X-Amz-Algorithm", valid_603315
  var valid_603316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603316 = validateParameter(valid_603316, JString, required = false,
                                 default = nil)
  if valid_603316 != nil:
    section.add "X-Amz-SignedHeaders", valid_603316
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603317: Call_GetRetrieveEnvironmentInfo_603302; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the compiled information from a <a>RequestEnvironmentInfo</a> request.</p> <p>Related Topics</p> <ul> <li> <p> <a>RequestEnvironmentInfo</a> </p> </li> </ul>
  ## 
  let valid = call_603317.validator(path, query, header, formData, body)
  let scheme = call_603317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603317.url(scheme.get, call_603317.host, call_603317.base,
                         call_603317.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603317, url, valid)

proc call*(call_603318: Call_GetRetrieveEnvironmentInfo_603302;
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
  var query_603319 = newJObject()
  add(query_603319, "InfoType", newJString(InfoType))
  add(query_603319, "EnvironmentName", newJString(EnvironmentName))
  add(query_603319, "Action", newJString(Action))
  add(query_603319, "Version", newJString(Version))
  add(query_603319, "EnvironmentId", newJString(EnvironmentId))
  result = call_603318.call(nil, query_603319, nil, nil, nil)

var getRetrieveEnvironmentInfo* = Call_GetRetrieveEnvironmentInfo_603302(
    name: "getRetrieveEnvironmentInfo", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=RetrieveEnvironmentInfo",
    validator: validate_GetRetrieveEnvironmentInfo_603303, base: "/",
    url: url_GetRetrieveEnvironmentInfo_603304,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostSwapEnvironmentCNAMEs_603358 = ref object of OpenApiRestCall_601390
proc url_PostSwapEnvironmentCNAMEs_603360(protocol: Scheme; host: string;
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

proc validate_PostSwapEnvironmentCNAMEs_603359(path: JsonNode; query: JsonNode;
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
  var valid_603361 = query.getOrDefault("Action")
  valid_603361 = validateParameter(valid_603361, JString, required = true,
                                 default = newJString("SwapEnvironmentCNAMEs"))
  if valid_603361 != nil:
    section.add "Action", valid_603361
  var valid_603362 = query.getOrDefault("Version")
  valid_603362 = validateParameter(valid_603362, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603362 != nil:
    section.add "Version", valid_603362
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
  var valid_603363 = header.getOrDefault("X-Amz-Signature")
  valid_603363 = validateParameter(valid_603363, JString, required = false,
                                 default = nil)
  if valid_603363 != nil:
    section.add "X-Amz-Signature", valid_603363
  var valid_603364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603364 = validateParameter(valid_603364, JString, required = false,
                                 default = nil)
  if valid_603364 != nil:
    section.add "X-Amz-Content-Sha256", valid_603364
  var valid_603365 = header.getOrDefault("X-Amz-Date")
  valid_603365 = validateParameter(valid_603365, JString, required = false,
                                 default = nil)
  if valid_603365 != nil:
    section.add "X-Amz-Date", valid_603365
  var valid_603366 = header.getOrDefault("X-Amz-Credential")
  valid_603366 = validateParameter(valid_603366, JString, required = false,
                                 default = nil)
  if valid_603366 != nil:
    section.add "X-Amz-Credential", valid_603366
  var valid_603367 = header.getOrDefault("X-Amz-Security-Token")
  valid_603367 = validateParameter(valid_603367, JString, required = false,
                                 default = nil)
  if valid_603367 != nil:
    section.add "X-Amz-Security-Token", valid_603367
  var valid_603368 = header.getOrDefault("X-Amz-Algorithm")
  valid_603368 = validateParameter(valid_603368, JString, required = false,
                                 default = nil)
  if valid_603368 != nil:
    section.add "X-Amz-Algorithm", valid_603368
  var valid_603369 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603369 = validateParameter(valid_603369, JString, required = false,
                                 default = nil)
  if valid_603369 != nil:
    section.add "X-Amz-SignedHeaders", valid_603369
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
  var valid_603370 = formData.getOrDefault("DestinationEnvironmentName")
  valid_603370 = validateParameter(valid_603370, JString, required = false,
                                 default = nil)
  if valid_603370 != nil:
    section.add "DestinationEnvironmentName", valid_603370
  var valid_603371 = formData.getOrDefault("DestinationEnvironmentId")
  valid_603371 = validateParameter(valid_603371, JString, required = false,
                                 default = nil)
  if valid_603371 != nil:
    section.add "DestinationEnvironmentId", valid_603371
  var valid_603372 = formData.getOrDefault("SourceEnvironmentId")
  valid_603372 = validateParameter(valid_603372, JString, required = false,
                                 default = nil)
  if valid_603372 != nil:
    section.add "SourceEnvironmentId", valid_603372
  var valid_603373 = formData.getOrDefault("SourceEnvironmentName")
  valid_603373 = validateParameter(valid_603373, JString, required = false,
                                 default = nil)
  if valid_603373 != nil:
    section.add "SourceEnvironmentName", valid_603373
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603374: Call_PostSwapEnvironmentCNAMEs_603358; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Swaps the CNAMEs of two environments.
  ## 
  let valid = call_603374.validator(path, query, header, formData, body)
  let scheme = call_603374.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603374.url(scheme.get, call_603374.host, call_603374.base,
                         call_603374.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603374, url, valid)

proc call*(call_603375: Call_PostSwapEnvironmentCNAMEs_603358;
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
  var query_603376 = newJObject()
  var formData_603377 = newJObject()
  add(formData_603377, "DestinationEnvironmentName",
      newJString(DestinationEnvironmentName))
  add(formData_603377, "DestinationEnvironmentId",
      newJString(DestinationEnvironmentId))
  add(formData_603377, "SourceEnvironmentId", newJString(SourceEnvironmentId))
  add(formData_603377, "SourceEnvironmentName", newJString(SourceEnvironmentName))
  add(query_603376, "Action", newJString(Action))
  add(query_603376, "Version", newJString(Version))
  result = call_603375.call(nil, query_603376, nil, formData_603377, nil)

var postSwapEnvironmentCNAMEs* = Call_PostSwapEnvironmentCNAMEs_603358(
    name: "postSwapEnvironmentCNAMEs", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=SwapEnvironmentCNAMEs",
    validator: validate_PostSwapEnvironmentCNAMEs_603359, base: "/",
    url: url_PostSwapEnvironmentCNAMEs_603360,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSwapEnvironmentCNAMEs_603339 = ref object of OpenApiRestCall_601390
proc url_GetSwapEnvironmentCNAMEs_603341(protocol: Scheme; host: string;
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

proc validate_GetSwapEnvironmentCNAMEs_603340(path: JsonNode; query: JsonNode;
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
  var valid_603342 = query.getOrDefault("SourceEnvironmentId")
  valid_603342 = validateParameter(valid_603342, JString, required = false,
                                 default = nil)
  if valid_603342 != nil:
    section.add "SourceEnvironmentId", valid_603342
  var valid_603343 = query.getOrDefault("SourceEnvironmentName")
  valid_603343 = validateParameter(valid_603343, JString, required = false,
                                 default = nil)
  if valid_603343 != nil:
    section.add "SourceEnvironmentName", valid_603343
  var valid_603344 = query.getOrDefault("DestinationEnvironmentName")
  valid_603344 = validateParameter(valid_603344, JString, required = false,
                                 default = nil)
  if valid_603344 != nil:
    section.add "DestinationEnvironmentName", valid_603344
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603345 = query.getOrDefault("Action")
  valid_603345 = validateParameter(valid_603345, JString, required = true,
                                 default = newJString("SwapEnvironmentCNAMEs"))
  if valid_603345 != nil:
    section.add "Action", valid_603345
  var valid_603346 = query.getOrDefault("DestinationEnvironmentId")
  valid_603346 = validateParameter(valid_603346, JString, required = false,
                                 default = nil)
  if valid_603346 != nil:
    section.add "DestinationEnvironmentId", valid_603346
  var valid_603347 = query.getOrDefault("Version")
  valid_603347 = validateParameter(valid_603347, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603347 != nil:
    section.add "Version", valid_603347
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
  var valid_603348 = header.getOrDefault("X-Amz-Signature")
  valid_603348 = validateParameter(valid_603348, JString, required = false,
                                 default = nil)
  if valid_603348 != nil:
    section.add "X-Amz-Signature", valid_603348
  var valid_603349 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603349 = validateParameter(valid_603349, JString, required = false,
                                 default = nil)
  if valid_603349 != nil:
    section.add "X-Amz-Content-Sha256", valid_603349
  var valid_603350 = header.getOrDefault("X-Amz-Date")
  valid_603350 = validateParameter(valid_603350, JString, required = false,
                                 default = nil)
  if valid_603350 != nil:
    section.add "X-Amz-Date", valid_603350
  var valid_603351 = header.getOrDefault("X-Amz-Credential")
  valid_603351 = validateParameter(valid_603351, JString, required = false,
                                 default = nil)
  if valid_603351 != nil:
    section.add "X-Amz-Credential", valid_603351
  var valid_603352 = header.getOrDefault("X-Amz-Security-Token")
  valid_603352 = validateParameter(valid_603352, JString, required = false,
                                 default = nil)
  if valid_603352 != nil:
    section.add "X-Amz-Security-Token", valid_603352
  var valid_603353 = header.getOrDefault("X-Amz-Algorithm")
  valid_603353 = validateParameter(valid_603353, JString, required = false,
                                 default = nil)
  if valid_603353 != nil:
    section.add "X-Amz-Algorithm", valid_603353
  var valid_603354 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603354 = validateParameter(valid_603354, JString, required = false,
                                 default = nil)
  if valid_603354 != nil:
    section.add "X-Amz-SignedHeaders", valid_603354
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603355: Call_GetSwapEnvironmentCNAMEs_603339; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Swaps the CNAMEs of two environments.
  ## 
  let valid = call_603355.validator(path, query, header, formData, body)
  let scheme = call_603355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603355.url(scheme.get, call_603355.host, call_603355.base,
                         call_603355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603355, url, valid)

proc call*(call_603356: Call_GetSwapEnvironmentCNAMEs_603339;
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
  var query_603357 = newJObject()
  add(query_603357, "SourceEnvironmentId", newJString(SourceEnvironmentId))
  add(query_603357, "SourceEnvironmentName", newJString(SourceEnvironmentName))
  add(query_603357, "DestinationEnvironmentName",
      newJString(DestinationEnvironmentName))
  add(query_603357, "Action", newJString(Action))
  add(query_603357, "DestinationEnvironmentId",
      newJString(DestinationEnvironmentId))
  add(query_603357, "Version", newJString(Version))
  result = call_603356.call(nil, query_603357, nil, nil, nil)

var getSwapEnvironmentCNAMEs* = Call_GetSwapEnvironmentCNAMEs_603339(
    name: "getSwapEnvironmentCNAMEs", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=SwapEnvironmentCNAMEs",
    validator: validate_GetSwapEnvironmentCNAMEs_603340, base: "/",
    url: url_GetSwapEnvironmentCNAMEs_603341, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostTerminateEnvironment_603397 = ref object of OpenApiRestCall_601390
proc url_PostTerminateEnvironment_603399(protocol: Scheme; host: string;
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

proc validate_PostTerminateEnvironment_603398(path: JsonNode; query: JsonNode;
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
  var valid_603400 = query.getOrDefault("Action")
  valid_603400 = validateParameter(valid_603400, JString, required = true,
                                 default = newJString("TerminateEnvironment"))
  if valid_603400 != nil:
    section.add "Action", valid_603400
  var valid_603401 = query.getOrDefault("Version")
  valid_603401 = validateParameter(valid_603401, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603401 != nil:
    section.add "Version", valid_603401
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
  var valid_603402 = header.getOrDefault("X-Amz-Signature")
  valid_603402 = validateParameter(valid_603402, JString, required = false,
                                 default = nil)
  if valid_603402 != nil:
    section.add "X-Amz-Signature", valid_603402
  var valid_603403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603403 = validateParameter(valid_603403, JString, required = false,
                                 default = nil)
  if valid_603403 != nil:
    section.add "X-Amz-Content-Sha256", valid_603403
  var valid_603404 = header.getOrDefault("X-Amz-Date")
  valid_603404 = validateParameter(valid_603404, JString, required = false,
                                 default = nil)
  if valid_603404 != nil:
    section.add "X-Amz-Date", valid_603404
  var valid_603405 = header.getOrDefault("X-Amz-Credential")
  valid_603405 = validateParameter(valid_603405, JString, required = false,
                                 default = nil)
  if valid_603405 != nil:
    section.add "X-Amz-Credential", valid_603405
  var valid_603406 = header.getOrDefault("X-Amz-Security-Token")
  valid_603406 = validateParameter(valid_603406, JString, required = false,
                                 default = nil)
  if valid_603406 != nil:
    section.add "X-Amz-Security-Token", valid_603406
  var valid_603407 = header.getOrDefault("X-Amz-Algorithm")
  valid_603407 = validateParameter(valid_603407, JString, required = false,
                                 default = nil)
  if valid_603407 != nil:
    section.add "X-Amz-Algorithm", valid_603407
  var valid_603408 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603408 = validateParameter(valid_603408, JString, required = false,
                                 default = nil)
  if valid_603408 != nil:
    section.add "X-Amz-SignedHeaders", valid_603408
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
  var valid_603409 = formData.getOrDefault("EnvironmentName")
  valid_603409 = validateParameter(valid_603409, JString, required = false,
                                 default = nil)
  if valid_603409 != nil:
    section.add "EnvironmentName", valid_603409
  var valid_603410 = formData.getOrDefault("TerminateResources")
  valid_603410 = validateParameter(valid_603410, JBool, required = false, default = nil)
  if valid_603410 != nil:
    section.add "TerminateResources", valid_603410
  var valid_603411 = formData.getOrDefault("ForceTerminate")
  valid_603411 = validateParameter(valid_603411, JBool, required = false, default = nil)
  if valid_603411 != nil:
    section.add "ForceTerminate", valid_603411
  var valid_603412 = formData.getOrDefault("EnvironmentId")
  valid_603412 = validateParameter(valid_603412, JString, required = false,
                                 default = nil)
  if valid_603412 != nil:
    section.add "EnvironmentId", valid_603412
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603413: Call_PostTerminateEnvironment_603397; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Terminates the specified environment.
  ## 
  let valid = call_603413.validator(path, query, header, formData, body)
  let scheme = call_603413.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603413.url(scheme.get, call_603413.host, call_603413.base,
                         call_603413.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603413, url, valid)

proc call*(call_603414: Call_PostTerminateEnvironment_603397;
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
  var query_603415 = newJObject()
  var formData_603416 = newJObject()
  add(formData_603416, "EnvironmentName", newJString(EnvironmentName))
  add(formData_603416, "TerminateResources", newJBool(TerminateResources))
  add(query_603415, "Action", newJString(Action))
  add(formData_603416, "ForceTerminate", newJBool(ForceTerminate))
  add(formData_603416, "EnvironmentId", newJString(EnvironmentId))
  add(query_603415, "Version", newJString(Version))
  result = call_603414.call(nil, query_603415, nil, formData_603416, nil)

var postTerminateEnvironment* = Call_PostTerminateEnvironment_603397(
    name: "postTerminateEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=TerminateEnvironment",
    validator: validate_PostTerminateEnvironment_603398, base: "/",
    url: url_PostTerminateEnvironment_603399, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTerminateEnvironment_603378 = ref object of OpenApiRestCall_601390
proc url_GetTerminateEnvironment_603380(protocol: Scheme; host: string; base: string;
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

proc validate_GetTerminateEnvironment_603379(path: JsonNode; query: JsonNode;
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
  var valid_603381 = query.getOrDefault("ForceTerminate")
  valid_603381 = validateParameter(valid_603381, JBool, required = false, default = nil)
  if valid_603381 != nil:
    section.add "ForceTerminate", valid_603381
  var valid_603382 = query.getOrDefault("TerminateResources")
  valid_603382 = validateParameter(valid_603382, JBool, required = false, default = nil)
  if valid_603382 != nil:
    section.add "TerminateResources", valid_603382
  var valid_603383 = query.getOrDefault("EnvironmentName")
  valid_603383 = validateParameter(valid_603383, JString, required = false,
                                 default = nil)
  if valid_603383 != nil:
    section.add "EnvironmentName", valid_603383
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603384 = query.getOrDefault("Action")
  valid_603384 = validateParameter(valid_603384, JString, required = true,
                                 default = newJString("TerminateEnvironment"))
  if valid_603384 != nil:
    section.add "Action", valid_603384
  var valid_603385 = query.getOrDefault("Version")
  valid_603385 = validateParameter(valid_603385, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603385 != nil:
    section.add "Version", valid_603385
  var valid_603386 = query.getOrDefault("EnvironmentId")
  valid_603386 = validateParameter(valid_603386, JString, required = false,
                                 default = nil)
  if valid_603386 != nil:
    section.add "EnvironmentId", valid_603386
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
  var valid_603387 = header.getOrDefault("X-Amz-Signature")
  valid_603387 = validateParameter(valid_603387, JString, required = false,
                                 default = nil)
  if valid_603387 != nil:
    section.add "X-Amz-Signature", valid_603387
  var valid_603388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603388 = validateParameter(valid_603388, JString, required = false,
                                 default = nil)
  if valid_603388 != nil:
    section.add "X-Amz-Content-Sha256", valid_603388
  var valid_603389 = header.getOrDefault("X-Amz-Date")
  valid_603389 = validateParameter(valid_603389, JString, required = false,
                                 default = nil)
  if valid_603389 != nil:
    section.add "X-Amz-Date", valid_603389
  var valid_603390 = header.getOrDefault("X-Amz-Credential")
  valid_603390 = validateParameter(valid_603390, JString, required = false,
                                 default = nil)
  if valid_603390 != nil:
    section.add "X-Amz-Credential", valid_603390
  var valid_603391 = header.getOrDefault("X-Amz-Security-Token")
  valid_603391 = validateParameter(valid_603391, JString, required = false,
                                 default = nil)
  if valid_603391 != nil:
    section.add "X-Amz-Security-Token", valid_603391
  var valid_603392 = header.getOrDefault("X-Amz-Algorithm")
  valid_603392 = validateParameter(valid_603392, JString, required = false,
                                 default = nil)
  if valid_603392 != nil:
    section.add "X-Amz-Algorithm", valid_603392
  var valid_603393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603393 = validateParameter(valid_603393, JString, required = false,
                                 default = nil)
  if valid_603393 != nil:
    section.add "X-Amz-SignedHeaders", valid_603393
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603394: Call_GetTerminateEnvironment_603378; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Terminates the specified environment.
  ## 
  let valid = call_603394.validator(path, query, header, formData, body)
  let scheme = call_603394.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603394.url(scheme.get, call_603394.host, call_603394.base,
                         call_603394.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603394, url, valid)

proc call*(call_603395: Call_GetTerminateEnvironment_603378;
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
  var query_603396 = newJObject()
  add(query_603396, "ForceTerminate", newJBool(ForceTerminate))
  add(query_603396, "TerminateResources", newJBool(TerminateResources))
  add(query_603396, "EnvironmentName", newJString(EnvironmentName))
  add(query_603396, "Action", newJString(Action))
  add(query_603396, "Version", newJString(Version))
  add(query_603396, "EnvironmentId", newJString(EnvironmentId))
  result = call_603395.call(nil, query_603396, nil, nil, nil)

var getTerminateEnvironment* = Call_GetTerminateEnvironment_603378(
    name: "getTerminateEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=TerminateEnvironment",
    validator: validate_GetTerminateEnvironment_603379, base: "/",
    url: url_GetTerminateEnvironment_603380, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateApplication_603434 = ref object of OpenApiRestCall_601390
proc url_PostUpdateApplication_603436(protocol: Scheme; host: string; base: string;
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

proc validate_PostUpdateApplication_603435(path: JsonNode; query: JsonNode;
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
  var valid_603437 = query.getOrDefault("Action")
  valid_603437 = validateParameter(valid_603437, JString, required = true,
                                 default = newJString("UpdateApplication"))
  if valid_603437 != nil:
    section.add "Action", valid_603437
  var valid_603438 = query.getOrDefault("Version")
  valid_603438 = validateParameter(valid_603438, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603438 != nil:
    section.add "Version", valid_603438
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
  var valid_603439 = header.getOrDefault("X-Amz-Signature")
  valid_603439 = validateParameter(valid_603439, JString, required = false,
                                 default = nil)
  if valid_603439 != nil:
    section.add "X-Amz-Signature", valid_603439
  var valid_603440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603440 = validateParameter(valid_603440, JString, required = false,
                                 default = nil)
  if valid_603440 != nil:
    section.add "X-Amz-Content-Sha256", valid_603440
  var valid_603441 = header.getOrDefault("X-Amz-Date")
  valid_603441 = validateParameter(valid_603441, JString, required = false,
                                 default = nil)
  if valid_603441 != nil:
    section.add "X-Amz-Date", valid_603441
  var valid_603442 = header.getOrDefault("X-Amz-Credential")
  valid_603442 = validateParameter(valid_603442, JString, required = false,
                                 default = nil)
  if valid_603442 != nil:
    section.add "X-Amz-Credential", valid_603442
  var valid_603443 = header.getOrDefault("X-Amz-Security-Token")
  valid_603443 = validateParameter(valid_603443, JString, required = false,
                                 default = nil)
  if valid_603443 != nil:
    section.add "X-Amz-Security-Token", valid_603443
  var valid_603444 = header.getOrDefault("X-Amz-Algorithm")
  valid_603444 = validateParameter(valid_603444, JString, required = false,
                                 default = nil)
  if valid_603444 != nil:
    section.add "X-Amz-Algorithm", valid_603444
  var valid_603445 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603445 = validateParameter(valid_603445, JString, required = false,
                                 default = nil)
  if valid_603445 != nil:
    section.add "X-Amz-SignedHeaders", valid_603445
  result.add "header", section
  ## parameters in `formData` object:
  ##   Description: JString
  ##              : <p>A new description for the application.</p> <p>Default: If not specified, AWS Elastic Beanstalk does not update the description.</p>
  ##   ApplicationName: JString (required)
  ##                  : The name of the application to update. If no such application is found, <code>UpdateApplication</code> returns an <code>InvalidParameterValue</code> error. 
  section = newJObject()
  var valid_603446 = formData.getOrDefault("Description")
  valid_603446 = validateParameter(valid_603446, JString, required = false,
                                 default = nil)
  if valid_603446 != nil:
    section.add "Description", valid_603446
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_603447 = formData.getOrDefault("ApplicationName")
  valid_603447 = validateParameter(valid_603447, JString, required = true,
                                 default = nil)
  if valid_603447 != nil:
    section.add "ApplicationName", valid_603447
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603448: Call_PostUpdateApplication_603434; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified application to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear these properties, specify an empty string.</p> </note>
  ## 
  let valid = call_603448.validator(path, query, header, formData, body)
  let scheme = call_603448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603448.url(scheme.get, call_603448.host, call_603448.base,
                         call_603448.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603448, url, valid)

proc call*(call_603449: Call_PostUpdateApplication_603434; ApplicationName: string;
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
  var query_603450 = newJObject()
  var formData_603451 = newJObject()
  add(formData_603451, "Description", newJString(Description))
  add(formData_603451, "ApplicationName", newJString(ApplicationName))
  add(query_603450, "Action", newJString(Action))
  add(query_603450, "Version", newJString(Version))
  result = call_603449.call(nil, query_603450, nil, formData_603451, nil)

var postUpdateApplication* = Call_PostUpdateApplication_603434(
    name: "postUpdateApplication", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateApplication",
    validator: validate_PostUpdateApplication_603435, base: "/",
    url: url_PostUpdateApplication_603436, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateApplication_603417 = ref object of OpenApiRestCall_601390
proc url_GetUpdateApplication_603419(protocol: Scheme; host: string; base: string;
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

proc validate_GetUpdateApplication_603418(path: JsonNode; query: JsonNode;
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
  var valid_603420 = query.getOrDefault("ApplicationName")
  valid_603420 = validateParameter(valid_603420, JString, required = true,
                                 default = nil)
  if valid_603420 != nil:
    section.add "ApplicationName", valid_603420
  var valid_603421 = query.getOrDefault("Action")
  valid_603421 = validateParameter(valid_603421, JString, required = true,
                                 default = newJString("UpdateApplication"))
  if valid_603421 != nil:
    section.add "Action", valid_603421
  var valid_603422 = query.getOrDefault("Description")
  valid_603422 = validateParameter(valid_603422, JString, required = false,
                                 default = nil)
  if valid_603422 != nil:
    section.add "Description", valid_603422
  var valid_603423 = query.getOrDefault("Version")
  valid_603423 = validateParameter(valid_603423, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603423 != nil:
    section.add "Version", valid_603423
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
  var valid_603424 = header.getOrDefault("X-Amz-Signature")
  valid_603424 = validateParameter(valid_603424, JString, required = false,
                                 default = nil)
  if valid_603424 != nil:
    section.add "X-Amz-Signature", valid_603424
  var valid_603425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603425 = validateParameter(valid_603425, JString, required = false,
                                 default = nil)
  if valid_603425 != nil:
    section.add "X-Amz-Content-Sha256", valid_603425
  var valid_603426 = header.getOrDefault("X-Amz-Date")
  valid_603426 = validateParameter(valid_603426, JString, required = false,
                                 default = nil)
  if valid_603426 != nil:
    section.add "X-Amz-Date", valid_603426
  var valid_603427 = header.getOrDefault("X-Amz-Credential")
  valid_603427 = validateParameter(valid_603427, JString, required = false,
                                 default = nil)
  if valid_603427 != nil:
    section.add "X-Amz-Credential", valid_603427
  var valid_603428 = header.getOrDefault("X-Amz-Security-Token")
  valid_603428 = validateParameter(valid_603428, JString, required = false,
                                 default = nil)
  if valid_603428 != nil:
    section.add "X-Amz-Security-Token", valid_603428
  var valid_603429 = header.getOrDefault("X-Amz-Algorithm")
  valid_603429 = validateParameter(valid_603429, JString, required = false,
                                 default = nil)
  if valid_603429 != nil:
    section.add "X-Amz-Algorithm", valid_603429
  var valid_603430 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603430 = validateParameter(valid_603430, JString, required = false,
                                 default = nil)
  if valid_603430 != nil:
    section.add "X-Amz-SignedHeaders", valid_603430
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603431: Call_GetUpdateApplication_603417; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified application to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear these properties, specify an empty string.</p> </note>
  ## 
  let valid = call_603431.validator(path, query, header, formData, body)
  let scheme = call_603431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603431.url(scheme.get, call_603431.host, call_603431.base,
                         call_603431.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603431, url, valid)

proc call*(call_603432: Call_GetUpdateApplication_603417; ApplicationName: string;
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
  var query_603433 = newJObject()
  add(query_603433, "ApplicationName", newJString(ApplicationName))
  add(query_603433, "Action", newJString(Action))
  add(query_603433, "Description", newJString(Description))
  add(query_603433, "Version", newJString(Version))
  result = call_603432.call(nil, query_603433, nil, nil, nil)

var getUpdateApplication* = Call_GetUpdateApplication_603417(
    name: "getUpdateApplication", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateApplication",
    validator: validate_GetUpdateApplication_603418, base: "/",
    url: url_GetUpdateApplication_603419, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateApplicationResourceLifecycle_603470 = ref object of OpenApiRestCall_601390
proc url_PostUpdateApplicationResourceLifecycle_603472(protocol: Scheme;
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

proc validate_PostUpdateApplicationResourceLifecycle_603471(path: JsonNode;
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
  var valid_603473 = query.getOrDefault("Action")
  valid_603473 = validateParameter(valid_603473, JString, required = true, default = newJString(
      "UpdateApplicationResourceLifecycle"))
  if valid_603473 != nil:
    section.add "Action", valid_603473
  var valid_603474 = query.getOrDefault("Version")
  valid_603474 = validateParameter(valid_603474, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603474 != nil:
    section.add "Version", valid_603474
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
  var valid_603475 = header.getOrDefault("X-Amz-Signature")
  valid_603475 = validateParameter(valid_603475, JString, required = false,
                                 default = nil)
  if valid_603475 != nil:
    section.add "X-Amz-Signature", valid_603475
  var valid_603476 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603476 = validateParameter(valid_603476, JString, required = false,
                                 default = nil)
  if valid_603476 != nil:
    section.add "X-Amz-Content-Sha256", valid_603476
  var valid_603477 = header.getOrDefault("X-Amz-Date")
  valid_603477 = validateParameter(valid_603477, JString, required = false,
                                 default = nil)
  if valid_603477 != nil:
    section.add "X-Amz-Date", valid_603477
  var valid_603478 = header.getOrDefault("X-Amz-Credential")
  valid_603478 = validateParameter(valid_603478, JString, required = false,
                                 default = nil)
  if valid_603478 != nil:
    section.add "X-Amz-Credential", valid_603478
  var valid_603479 = header.getOrDefault("X-Amz-Security-Token")
  valid_603479 = validateParameter(valid_603479, JString, required = false,
                                 default = nil)
  if valid_603479 != nil:
    section.add "X-Amz-Security-Token", valid_603479
  var valid_603480 = header.getOrDefault("X-Amz-Algorithm")
  valid_603480 = validateParameter(valid_603480, JString, required = false,
                                 default = nil)
  if valid_603480 != nil:
    section.add "X-Amz-Algorithm", valid_603480
  var valid_603481 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603481 = validateParameter(valid_603481, JString, required = false,
                                 default = nil)
  if valid_603481 != nil:
    section.add "X-Amz-SignedHeaders", valid_603481
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
  var valid_603482 = formData.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_603482 = validateParameter(valid_603482, JString, required = false,
                                 default = nil)
  if valid_603482 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_603482
  var valid_603483 = formData.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_603483 = validateParameter(valid_603483, JString, required = false,
                                 default = nil)
  if valid_603483 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_603483
  assert formData != nil, "formData argument is necessary due to required `ApplicationName` field"
  var valid_603484 = formData.getOrDefault("ApplicationName")
  valid_603484 = validateParameter(valid_603484, JString, required = true,
                                 default = nil)
  if valid_603484 != nil:
    section.add "ApplicationName", valid_603484
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603485: Call_PostUpdateApplicationResourceLifecycle_603470;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Modifies lifecycle settings for an application.
  ## 
  let valid = call_603485.validator(path, query, header, formData, body)
  let scheme = call_603485.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603485.url(scheme.get, call_603485.host, call_603485.base,
                         call_603485.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603485, url, valid)

proc call*(call_603486: Call_PostUpdateApplicationResourceLifecycle_603470;
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
  var query_603487 = newJObject()
  var formData_603488 = newJObject()
  add(formData_603488, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  add(formData_603488, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  add(formData_603488, "ApplicationName", newJString(ApplicationName))
  add(query_603487, "Action", newJString(Action))
  add(query_603487, "Version", newJString(Version))
  result = call_603486.call(nil, query_603487, nil, formData_603488, nil)

var postUpdateApplicationResourceLifecycle* = Call_PostUpdateApplicationResourceLifecycle_603470(
    name: "postUpdateApplicationResourceLifecycle", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationResourceLifecycle",
    validator: validate_PostUpdateApplicationResourceLifecycle_603471, base: "/",
    url: url_PostUpdateApplicationResourceLifecycle_603472,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateApplicationResourceLifecycle_603452 = ref object of OpenApiRestCall_601390
proc url_GetUpdateApplicationResourceLifecycle_603454(protocol: Scheme;
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

proc validate_GetUpdateApplicationResourceLifecycle_603453(path: JsonNode;
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
  var valid_603455 = query.getOrDefault("ApplicationName")
  valid_603455 = validateParameter(valid_603455, JString, required = true,
                                 default = nil)
  if valid_603455 != nil:
    section.add "ApplicationName", valid_603455
  var valid_603456 = query.getOrDefault("ResourceLifecycleConfig.ServiceRole")
  valid_603456 = validateParameter(valid_603456, JString, required = false,
                                 default = nil)
  if valid_603456 != nil:
    section.add "ResourceLifecycleConfig.ServiceRole", valid_603456
  var valid_603457 = query.getOrDefault("ResourceLifecycleConfig.VersionLifecycleConfig")
  valid_603457 = validateParameter(valid_603457, JString, required = false,
                                 default = nil)
  if valid_603457 != nil:
    section.add "ResourceLifecycleConfig.VersionLifecycleConfig", valid_603457
  var valid_603458 = query.getOrDefault("Action")
  valid_603458 = validateParameter(valid_603458, JString, required = true, default = newJString(
      "UpdateApplicationResourceLifecycle"))
  if valid_603458 != nil:
    section.add "Action", valid_603458
  var valid_603459 = query.getOrDefault("Version")
  valid_603459 = validateParameter(valid_603459, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603459 != nil:
    section.add "Version", valid_603459
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
  var valid_603460 = header.getOrDefault("X-Amz-Signature")
  valid_603460 = validateParameter(valid_603460, JString, required = false,
                                 default = nil)
  if valid_603460 != nil:
    section.add "X-Amz-Signature", valid_603460
  var valid_603461 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603461 = validateParameter(valid_603461, JString, required = false,
                                 default = nil)
  if valid_603461 != nil:
    section.add "X-Amz-Content-Sha256", valid_603461
  var valid_603462 = header.getOrDefault("X-Amz-Date")
  valid_603462 = validateParameter(valid_603462, JString, required = false,
                                 default = nil)
  if valid_603462 != nil:
    section.add "X-Amz-Date", valid_603462
  var valid_603463 = header.getOrDefault("X-Amz-Credential")
  valid_603463 = validateParameter(valid_603463, JString, required = false,
                                 default = nil)
  if valid_603463 != nil:
    section.add "X-Amz-Credential", valid_603463
  var valid_603464 = header.getOrDefault("X-Amz-Security-Token")
  valid_603464 = validateParameter(valid_603464, JString, required = false,
                                 default = nil)
  if valid_603464 != nil:
    section.add "X-Amz-Security-Token", valid_603464
  var valid_603465 = header.getOrDefault("X-Amz-Algorithm")
  valid_603465 = validateParameter(valid_603465, JString, required = false,
                                 default = nil)
  if valid_603465 != nil:
    section.add "X-Amz-Algorithm", valid_603465
  var valid_603466 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603466 = validateParameter(valid_603466, JString, required = false,
                                 default = nil)
  if valid_603466 != nil:
    section.add "X-Amz-SignedHeaders", valid_603466
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603467: Call_GetUpdateApplicationResourceLifecycle_603452;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Modifies lifecycle settings for an application.
  ## 
  let valid = call_603467.validator(path, query, header, formData, body)
  let scheme = call_603467.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603467.url(scheme.get, call_603467.host, call_603467.base,
                         call_603467.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603467, url, valid)

proc call*(call_603468: Call_GetUpdateApplicationResourceLifecycle_603452;
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
  var query_603469 = newJObject()
  add(query_603469, "ApplicationName", newJString(ApplicationName))
  add(query_603469, "ResourceLifecycleConfig.ServiceRole",
      newJString(ResourceLifecycleConfigServiceRole))
  add(query_603469, "ResourceLifecycleConfig.VersionLifecycleConfig",
      newJString(ResourceLifecycleConfigVersionLifecycleConfig))
  add(query_603469, "Action", newJString(Action))
  add(query_603469, "Version", newJString(Version))
  result = call_603468.call(nil, query_603469, nil, nil, nil)

var getUpdateApplicationResourceLifecycle* = Call_GetUpdateApplicationResourceLifecycle_603452(
    name: "getUpdateApplicationResourceLifecycle", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationResourceLifecycle",
    validator: validate_GetUpdateApplicationResourceLifecycle_603453, base: "/",
    url: url_GetUpdateApplicationResourceLifecycle_603454,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateApplicationVersion_603507 = ref object of OpenApiRestCall_601390
proc url_PostUpdateApplicationVersion_603509(protocol: Scheme; host: string;
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

proc validate_PostUpdateApplicationVersion_603508(path: JsonNode; query: JsonNode;
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
  var valid_603510 = query.getOrDefault("Action")
  valid_603510 = validateParameter(valid_603510, JString, required = true, default = newJString(
      "UpdateApplicationVersion"))
  if valid_603510 != nil:
    section.add "Action", valid_603510
  var valid_603511 = query.getOrDefault("Version")
  valid_603511 = validateParameter(valid_603511, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603511 != nil:
    section.add "Version", valid_603511
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
  var valid_603512 = header.getOrDefault("X-Amz-Signature")
  valid_603512 = validateParameter(valid_603512, JString, required = false,
                                 default = nil)
  if valid_603512 != nil:
    section.add "X-Amz-Signature", valid_603512
  var valid_603513 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603513 = validateParameter(valid_603513, JString, required = false,
                                 default = nil)
  if valid_603513 != nil:
    section.add "X-Amz-Content-Sha256", valid_603513
  var valid_603514 = header.getOrDefault("X-Amz-Date")
  valid_603514 = validateParameter(valid_603514, JString, required = false,
                                 default = nil)
  if valid_603514 != nil:
    section.add "X-Amz-Date", valid_603514
  var valid_603515 = header.getOrDefault("X-Amz-Credential")
  valid_603515 = validateParameter(valid_603515, JString, required = false,
                                 default = nil)
  if valid_603515 != nil:
    section.add "X-Amz-Credential", valid_603515
  var valid_603516 = header.getOrDefault("X-Amz-Security-Token")
  valid_603516 = validateParameter(valid_603516, JString, required = false,
                                 default = nil)
  if valid_603516 != nil:
    section.add "X-Amz-Security-Token", valid_603516
  var valid_603517 = header.getOrDefault("X-Amz-Algorithm")
  valid_603517 = validateParameter(valid_603517, JString, required = false,
                                 default = nil)
  if valid_603517 != nil:
    section.add "X-Amz-Algorithm", valid_603517
  var valid_603518 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603518 = validateParameter(valid_603518, JString, required = false,
                                 default = nil)
  if valid_603518 != nil:
    section.add "X-Amz-SignedHeaders", valid_603518
  result.add "header", section
  ## parameters in `formData` object:
  ##   Description: JString
  ##              : A new description for this version.
  ##   VersionLabel: JString (required)
  ##               : <p>The name of the version to update.</p> <p>If no application version is found with this label, <code>UpdateApplication</code> returns an <code>InvalidParameterValue</code> error. </p>
  ##   ApplicationName: JString (required)
  ##                  : <p>The name of the application associated with this version.</p> <p> If no application is found with this name, <code>UpdateApplication</code> returns an <code>InvalidParameterValue</code> error.</p>
  section = newJObject()
  var valid_603519 = formData.getOrDefault("Description")
  valid_603519 = validateParameter(valid_603519, JString, required = false,
                                 default = nil)
  if valid_603519 != nil:
    section.add "Description", valid_603519
  assert formData != nil,
        "formData argument is necessary due to required `VersionLabel` field"
  var valid_603520 = formData.getOrDefault("VersionLabel")
  valid_603520 = validateParameter(valid_603520, JString, required = true,
                                 default = nil)
  if valid_603520 != nil:
    section.add "VersionLabel", valid_603520
  var valid_603521 = formData.getOrDefault("ApplicationName")
  valid_603521 = validateParameter(valid_603521, JString, required = true,
                                 default = nil)
  if valid_603521 != nil:
    section.add "ApplicationName", valid_603521
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603522: Call_PostUpdateApplicationVersion_603507; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified application version to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear properties, specify an empty string.</p> </note>
  ## 
  let valid = call_603522.validator(path, query, header, formData, body)
  let scheme = call_603522.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603522.url(scheme.get, call_603522.host, call_603522.base,
                         call_603522.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603522, url, valid)

proc call*(call_603523: Call_PostUpdateApplicationVersion_603507;
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
  var query_603524 = newJObject()
  var formData_603525 = newJObject()
  add(formData_603525, "Description", newJString(Description))
  add(formData_603525, "VersionLabel", newJString(VersionLabel))
  add(formData_603525, "ApplicationName", newJString(ApplicationName))
  add(query_603524, "Action", newJString(Action))
  add(query_603524, "Version", newJString(Version))
  result = call_603523.call(nil, query_603524, nil, formData_603525, nil)

var postUpdateApplicationVersion* = Call_PostUpdateApplicationVersion_603507(
    name: "postUpdateApplicationVersion", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationVersion",
    validator: validate_PostUpdateApplicationVersion_603508, base: "/",
    url: url_PostUpdateApplicationVersion_603509,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateApplicationVersion_603489 = ref object of OpenApiRestCall_601390
proc url_GetUpdateApplicationVersion_603491(protocol: Scheme; host: string;
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

proc validate_GetUpdateApplicationVersion_603490(path: JsonNode; query: JsonNode;
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
  var valid_603492 = query.getOrDefault("ApplicationName")
  valid_603492 = validateParameter(valid_603492, JString, required = true,
                                 default = nil)
  if valid_603492 != nil:
    section.add "ApplicationName", valid_603492
  var valid_603493 = query.getOrDefault("VersionLabel")
  valid_603493 = validateParameter(valid_603493, JString, required = true,
                                 default = nil)
  if valid_603493 != nil:
    section.add "VersionLabel", valid_603493
  var valid_603494 = query.getOrDefault("Action")
  valid_603494 = validateParameter(valid_603494, JString, required = true, default = newJString(
      "UpdateApplicationVersion"))
  if valid_603494 != nil:
    section.add "Action", valid_603494
  var valid_603495 = query.getOrDefault("Description")
  valid_603495 = validateParameter(valid_603495, JString, required = false,
                                 default = nil)
  if valid_603495 != nil:
    section.add "Description", valid_603495
  var valid_603496 = query.getOrDefault("Version")
  valid_603496 = validateParameter(valid_603496, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603496 != nil:
    section.add "Version", valid_603496
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
  var valid_603497 = header.getOrDefault("X-Amz-Signature")
  valid_603497 = validateParameter(valid_603497, JString, required = false,
                                 default = nil)
  if valid_603497 != nil:
    section.add "X-Amz-Signature", valid_603497
  var valid_603498 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603498 = validateParameter(valid_603498, JString, required = false,
                                 default = nil)
  if valid_603498 != nil:
    section.add "X-Amz-Content-Sha256", valid_603498
  var valid_603499 = header.getOrDefault("X-Amz-Date")
  valid_603499 = validateParameter(valid_603499, JString, required = false,
                                 default = nil)
  if valid_603499 != nil:
    section.add "X-Amz-Date", valid_603499
  var valid_603500 = header.getOrDefault("X-Amz-Credential")
  valid_603500 = validateParameter(valid_603500, JString, required = false,
                                 default = nil)
  if valid_603500 != nil:
    section.add "X-Amz-Credential", valid_603500
  var valid_603501 = header.getOrDefault("X-Amz-Security-Token")
  valid_603501 = validateParameter(valid_603501, JString, required = false,
                                 default = nil)
  if valid_603501 != nil:
    section.add "X-Amz-Security-Token", valid_603501
  var valid_603502 = header.getOrDefault("X-Amz-Algorithm")
  valid_603502 = validateParameter(valid_603502, JString, required = false,
                                 default = nil)
  if valid_603502 != nil:
    section.add "X-Amz-Algorithm", valid_603502
  var valid_603503 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603503 = validateParameter(valid_603503, JString, required = false,
                                 default = nil)
  if valid_603503 != nil:
    section.add "X-Amz-SignedHeaders", valid_603503
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603504: Call_GetUpdateApplicationVersion_603489; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified application version to have the specified properties.</p> <note> <p>If a property (for example, <code>description</code>) is not provided, the value remains unchanged. To clear properties, specify an empty string.</p> </note>
  ## 
  let valid = call_603504.validator(path, query, header, formData, body)
  let scheme = call_603504.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603504.url(scheme.get, call_603504.host, call_603504.base,
                         call_603504.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603504, url, valid)

proc call*(call_603505: Call_GetUpdateApplicationVersion_603489;
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
  var query_603506 = newJObject()
  add(query_603506, "ApplicationName", newJString(ApplicationName))
  add(query_603506, "VersionLabel", newJString(VersionLabel))
  add(query_603506, "Action", newJString(Action))
  add(query_603506, "Description", newJString(Description))
  add(query_603506, "Version", newJString(Version))
  result = call_603505.call(nil, query_603506, nil, nil, nil)

var getUpdateApplicationVersion* = Call_GetUpdateApplicationVersion_603489(
    name: "getUpdateApplicationVersion", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateApplicationVersion",
    validator: validate_GetUpdateApplicationVersion_603490, base: "/",
    url: url_GetUpdateApplicationVersion_603491,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateConfigurationTemplate_603546 = ref object of OpenApiRestCall_601390
proc url_PostUpdateConfigurationTemplate_603548(protocol: Scheme; host: string;
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

proc validate_PostUpdateConfigurationTemplate_603547(path: JsonNode;
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
  var valid_603549 = query.getOrDefault("Action")
  valid_603549 = validateParameter(valid_603549, JString, required = true, default = newJString(
      "UpdateConfigurationTemplate"))
  if valid_603549 != nil:
    section.add "Action", valid_603549
  var valid_603550 = query.getOrDefault("Version")
  valid_603550 = validateParameter(valid_603550, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603550 != nil:
    section.add "Version", valid_603550
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
  var valid_603551 = header.getOrDefault("X-Amz-Signature")
  valid_603551 = validateParameter(valid_603551, JString, required = false,
                                 default = nil)
  if valid_603551 != nil:
    section.add "X-Amz-Signature", valid_603551
  var valid_603552 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603552 = validateParameter(valid_603552, JString, required = false,
                                 default = nil)
  if valid_603552 != nil:
    section.add "X-Amz-Content-Sha256", valid_603552
  var valid_603553 = header.getOrDefault("X-Amz-Date")
  valid_603553 = validateParameter(valid_603553, JString, required = false,
                                 default = nil)
  if valid_603553 != nil:
    section.add "X-Amz-Date", valid_603553
  var valid_603554 = header.getOrDefault("X-Amz-Credential")
  valid_603554 = validateParameter(valid_603554, JString, required = false,
                                 default = nil)
  if valid_603554 != nil:
    section.add "X-Amz-Credential", valid_603554
  var valid_603555 = header.getOrDefault("X-Amz-Security-Token")
  valid_603555 = validateParameter(valid_603555, JString, required = false,
                                 default = nil)
  if valid_603555 != nil:
    section.add "X-Amz-Security-Token", valid_603555
  var valid_603556 = header.getOrDefault("X-Amz-Algorithm")
  valid_603556 = validateParameter(valid_603556, JString, required = false,
                                 default = nil)
  if valid_603556 != nil:
    section.add "X-Amz-Algorithm", valid_603556
  var valid_603557 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603557 = validateParameter(valid_603557, JString, required = false,
                                 default = nil)
  if valid_603557 != nil:
    section.add "X-Amz-SignedHeaders", valid_603557
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
  var valid_603558 = formData.getOrDefault("Description")
  valid_603558 = validateParameter(valid_603558, JString, required = false,
                                 default = nil)
  if valid_603558 != nil:
    section.add "Description", valid_603558
  assert formData != nil,
        "formData argument is necessary due to required `TemplateName` field"
  var valid_603559 = formData.getOrDefault("TemplateName")
  valid_603559 = validateParameter(valid_603559, JString, required = true,
                                 default = nil)
  if valid_603559 != nil:
    section.add "TemplateName", valid_603559
  var valid_603560 = formData.getOrDefault("OptionsToRemove")
  valid_603560 = validateParameter(valid_603560, JArray, required = false,
                                 default = nil)
  if valid_603560 != nil:
    section.add "OptionsToRemove", valid_603560
  var valid_603561 = formData.getOrDefault("OptionSettings")
  valid_603561 = validateParameter(valid_603561, JArray, required = false,
                                 default = nil)
  if valid_603561 != nil:
    section.add "OptionSettings", valid_603561
  var valid_603562 = formData.getOrDefault("ApplicationName")
  valid_603562 = validateParameter(valid_603562, JString, required = true,
                                 default = nil)
  if valid_603562 != nil:
    section.add "ApplicationName", valid_603562
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603563: Call_PostUpdateConfigurationTemplate_603546;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Updates the specified configuration template to have the specified properties or configuration option values.</p> <note> <p>If a property (for example, <code>ApplicationName</code>) is not provided, its value remains unchanged. To clear such properties, specify an empty string.</p> </note> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> </ul>
  ## 
  let valid = call_603563.validator(path, query, header, formData, body)
  let scheme = call_603563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603563.url(scheme.get, call_603563.host, call_603563.base,
                         call_603563.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603563, url, valid)

proc call*(call_603564: Call_PostUpdateConfigurationTemplate_603546;
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
  var query_603565 = newJObject()
  var formData_603566 = newJObject()
  add(formData_603566, "Description", newJString(Description))
  add(formData_603566, "TemplateName", newJString(TemplateName))
  if OptionsToRemove != nil:
    formData_603566.add "OptionsToRemove", OptionsToRemove
  if OptionSettings != nil:
    formData_603566.add "OptionSettings", OptionSettings
  add(formData_603566, "ApplicationName", newJString(ApplicationName))
  add(query_603565, "Action", newJString(Action))
  add(query_603565, "Version", newJString(Version))
  result = call_603564.call(nil, query_603565, nil, formData_603566, nil)

var postUpdateConfigurationTemplate* = Call_PostUpdateConfigurationTemplate_603546(
    name: "postUpdateConfigurationTemplate", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateConfigurationTemplate",
    validator: validate_PostUpdateConfigurationTemplate_603547, base: "/",
    url: url_PostUpdateConfigurationTemplate_603548,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateConfigurationTemplate_603526 = ref object of OpenApiRestCall_601390
proc url_GetUpdateConfigurationTemplate_603528(protocol: Scheme; host: string;
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

proc validate_GetUpdateConfigurationTemplate_603527(path: JsonNode;
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
  var valid_603529 = query.getOrDefault("ApplicationName")
  valid_603529 = validateParameter(valid_603529, JString, required = true,
                                 default = nil)
  if valid_603529 != nil:
    section.add "ApplicationName", valid_603529
  var valid_603530 = query.getOrDefault("OptionSettings")
  valid_603530 = validateParameter(valid_603530, JArray, required = false,
                                 default = nil)
  if valid_603530 != nil:
    section.add "OptionSettings", valid_603530
  var valid_603531 = query.getOrDefault("Action")
  valid_603531 = validateParameter(valid_603531, JString, required = true, default = newJString(
      "UpdateConfigurationTemplate"))
  if valid_603531 != nil:
    section.add "Action", valid_603531
  var valid_603532 = query.getOrDefault("Description")
  valid_603532 = validateParameter(valid_603532, JString, required = false,
                                 default = nil)
  if valid_603532 != nil:
    section.add "Description", valid_603532
  var valid_603533 = query.getOrDefault("OptionsToRemove")
  valid_603533 = validateParameter(valid_603533, JArray, required = false,
                                 default = nil)
  if valid_603533 != nil:
    section.add "OptionsToRemove", valid_603533
  var valid_603534 = query.getOrDefault("Version")
  valid_603534 = validateParameter(valid_603534, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603534 != nil:
    section.add "Version", valid_603534
  var valid_603535 = query.getOrDefault("TemplateName")
  valid_603535 = validateParameter(valid_603535, JString, required = true,
                                 default = nil)
  if valid_603535 != nil:
    section.add "TemplateName", valid_603535
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
  var valid_603536 = header.getOrDefault("X-Amz-Signature")
  valid_603536 = validateParameter(valid_603536, JString, required = false,
                                 default = nil)
  if valid_603536 != nil:
    section.add "X-Amz-Signature", valid_603536
  var valid_603537 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603537 = validateParameter(valid_603537, JString, required = false,
                                 default = nil)
  if valid_603537 != nil:
    section.add "X-Amz-Content-Sha256", valid_603537
  var valid_603538 = header.getOrDefault("X-Amz-Date")
  valid_603538 = validateParameter(valid_603538, JString, required = false,
                                 default = nil)
  if valid_603538 != nil:
    section.add "X-Amz-Date", valid_603538
  var valid_603539 = header.getOrDefault("X-Amz-Credential")
  valid_603539 = validateParameter(valid_603539, JString, required = false,
                                 default = nil)
  if valid_603539 != nil:
    section.add "X-Amz-Credential", valid_603539
  var valid_603540 = header.getOrDefault("X-Amz-Security-Token")
  valid_603540 = validateParameter(valid_603540, JString, required = false,
                                 default = nil)
  if valid_603540 != nil:
    section.add "X-Amz-Security-Token", valid_603540
  var valid_603541 = header.getOrDefault("X-Amz-Algorithm")
  valid_603541 = validateParameter(valid_603541, JString, required = false,
                                 default = nil)
  if valid_603541 != nil:
    section.add "X-Amz-Algorithm", valid_603541
  var valid_603542 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603542 = validateParameter(valid_603542, JString, required = false,
                                 default = nil)
  if valid_603542 != nil:
    section.add "X-Amz-SignedHeaders", valid_603542
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603543: Call_GetUpdateConfigurationTemplate_603526; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the specified configuration template to have the specified properties or configuration option values.</p> <note> <p>If a property (for example, <code>ApplicationName</code>) is not provided, its value remains unchanged. To clear such properties, specify an empty string.</p> </note> <p>Related Topics</p> <ul> <li> <p> <a>DescribeConfigurationOptions</a> </p> </li> </ul>
  ## 
  let valid = call_603543.validator(path, query, header, formData, body)
  let scheme = call_603543.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603543.url(scheme.get, call_603543.host, call_603543.base,
                         call_603543.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603543, url, valid)

proc call*(call_603544: Call_GetUpdateConfigurationTemplate_603526;
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
  var query_603545 = newJObject()
  add(query_603545, "ApplicationName", newJString(ApplicationName))
  if OptionSettings != nil:
    query_603545.add "OptionSettings", OptionSettings
  add(query_603545, "Action", newJString(Action))
  add(query_603545, "Description", newJString(Description))
  if OptionsToRemove != nil:
    query_603545.add "OptionsToRemove", OptionsToRemove
  add(query_603545, "Version", newJString(Version))
  add(query_603545, "TemplateName", newJString(TemplateName))
  result = call_603544.call(nil, query_603545, nil, nil, nil)

var getUpdateConfigurationTemplate* = Call_GetUpdateConfigurationTemplate_603526(
    name: "getUpdateConfigurationTemplate", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateConfigurationTemplate",
    validator: validate_GetUpdateConfigurationTemplate_603527, base: "/",
    url: url_GetUpdateConfigurationTemplate_603528,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateEnvironment_603596 = ref object of OpenApiRestCall_601390
proc url_PostUpdateEnvironment_603598(protocol: Scheme; host: string; base: string;
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

proc validate_PostUpdateEnvironment_603597(path: JsonNode; query: JsonNode;
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
  var valid_603599 = query.getOrDefault("Action")
  valid_603599 = validateParameter(valid_603599, JString, required = true,
                                 default = newJString("UpdateEnvironment"))
  if valid_603599 != nil:
    section.add "Action", valid_603599
  var valid_603600 = query.getOrDefault("Version")
  valid_603600 = validateParameter(valid_603600, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603600 != nil:
    section.add "Version", valid_603600
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
  var valid_603601 = header.getOrDefault("X-Amz-Signature")
  valid_603601 = validateParameter(valid_603601, JString, required = false,
                                 default = nil)
  if valid_603601 != nil:
    section.add "X-Amz-Signature", valid_603601
  var valid_603602 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603602 = validateParameter(valid_603602, JString, required = false,
                                 default = nil)
  if valid_603602 != nil:
    section.add "X-Amz-Content-Sha256", valid_603602
  var valid_603603 = header.getOrDefault("X-Amz-Date")
  valid_603603 = validateParameter(valid_603603, JString, required = false,
                                 default = nil)
  if valid_603603 != nil:
    section.add "X-Amz-Date", valid_603603
  var valid_603604 = header.getOrDefault("X-Amz-Credential")
  valid_603604 = validateParameter(valid_603604, JString, required = false,
                                 default = nil)
  if valid_603604 != nil:
    section.add "X-Amz-Credential", valid_603604
  var valid_603605 = header.getOrDefault("X-Amz-Security-Token")
  valid_603605 = validateParameter(valid_603605, JString, required = false,
                                 default = nil)
  if valid_603605 != nil:
    section.add "X-Amz-Security-Token", valid_603605
  var valid_603606 = header.getOrDefault("X-Amz-Algorithm")
  valid_603606 = validateParameter(valid_603606, JString, required = false,
                                 default = nil)
  if valid_603606 != nil:
    section.add "X-Amz-Algorithm", valid_603606
  var valid_603607 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603607 = validateParameter(valid_603607, JString, required = false,
                                 default = nil)
  if valid_603607 != nil:
    section.add "X-Amz-SignedHeaders", valid_603607
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
  var valid_603608 = formData.getOrDefault("Description")
  valid_603608 = validateParameter(valid_603608, JString, required = false,
                                 default = nil)
  if valid_603608 != nil:
    section.add "Description", valid_603608
  var valid_603609 = formData.getOrDefault("Tier.Type")
  valid_603609 = validateParameter(valid_603609, JString, required = false,
                                 default = nil)
  if valid_603609 != nil:
    section.add "Tier.Type", valid_603609
  var valid_603610 = formData.getOrDefault("EnvironmentName")
  valid_603610 = validateParameter(valid_603610, JString, required = false,
                                 default = nil)
  if valid_603610 != nil:
    section.add "EnvironmentName", valid_603610
  var valid_603611 = formData.getOrDefault("VersionLabel")
  valid_603611 = validateParameter(valid_603611, JString, required = false,
                                 default = nil)
  if valid_603611 != nil:
    section.add "VersionLabel", valid_603611
  var valid_603612 = formData.getOrDefault("TemplateName")
  valid_603612 = validateParameter(valid_603612, JString, required = false,
                                 default = nil)
  if valid_603612 != nil:
    section.add "TemplateName", valid_603612
  var valid_603613 = formData.getOrDefault("OptionsToRemove")
  valid_603613 = validateParameter(valid_603613, JArray, required = false,
                                 default = nil)
  if valid_603613 != nil:
    section.add "OptionsToRemove", valid_603613
  var valid_603614 = formData.getOrDefault("OptionSettings")
  valid_603614 = validateParameter(valid_603614, JArray, required = false,
                                 default = nil)
  if valid_603614 != nil:
    section.add "OptionSettings", valid_603614
  var valid_603615 = formData.getOrDefault("GroupName")
  valid_603615 = validateParameter(valid_603615, JString, required = false,
                                 default = nil)
  if valid_603615 != nil:
    section.add "GroupName", valid_603615
  var valid_603616 = formData.getOrDefault("ApplicationName")
  valid_603616 = validateParameter(valid_603616, JString, required = false,
                                 default = nil)
  if valid_603616 != nil:
    section.add "ApplicationName", valid_603616
  var valid_603617 = formData.getOrDefault("Tier.Name")
  valid_603617 = validateParameter(valid_603617, JString, required = false,
                                 default = nil)
  if valid_603617 != nil:
    section.add "Tier.Name", valid_603617
  var valid_603618 = formData.getOrDefault("Tier.Version")
  valid_603618 = validateParameter(valid_603618, JString, required = false,
                                 default = nil)
  if valid_603618 != nil:
    section.add "Tier.Version", valid_603618
  var valid_603619 = formData.getOrDefault("EnvironmentId")
  valid_603619 = validateParameter(valid_603619, JString, required = false,
                                 default = nil)
  if valid_603619 != nil:
    section.add "EnvironmentId", valid_603619
  var valid_603620 = formData.getOrDefault("SolutionStackName")
  valid_603620 = validateParameter(valid_603620, JString, required = false,
                                 default = nil)
  if valid_603620 != nil:
    section.add "SolutionStackName", valid_603620
  var valid_603621 = formData.getOrDefault("PlatformArn")
  valid_603621 = validateParameter(valid_603621, JString, required = false,
                                 default = nil)
  if valid_603621 != nil:
    section.add "PlatformArn", valid_603621
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603622: Call_PostUpdateEnvironment_603596; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the environment description, deploys a new application version, updates the configuration settings to an entirely new configuration template, or updates select configuration option values in the running environment.</p> <p> Attempting to update both the release and configuration is not allowed and AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. </p> <p> When updating the configuration settings to a new template or individual settings, a draft configuration is created and <a>DescribeConfigurationSettings</a> for this environment returns two setting descriptions with different <code>DeploymentStatus</code> values. </p>
  ## 
  let valid = call_603622.validator(path, query, header, formData, body)
  let scheme = call_603622.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603622.url(scheme.get, call_603622.host, call_603622.base,
                         call_603622.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603622, url, valid)

proc call*(call_603623: Call_PostUpdateEnvironment_603596;
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
  var query_603624 = newJObject()
  var formData_603625 = newJObject()
  add(formData_603625, "Description", newJString(Description))
  add(formData_603625, "Tier.Type", newJString(TierType))
  add(formData_603625, "EnvironmentName", newJString(EnvironmentName))
  add(formData_603625, "VersionLabel", newJString(VersionLabel))
  add(formData_603625, "TemplateName", newJString(TemplateName))
  if OptionsToRemove != nil:
    formData_603625.add "OptionsToRemove", OptionsToRemove
  if OptionSettings != nil:
    formData_603625.add "OptionSettings", OptionSettings
  add(formData_603625, "GroupName", newJString(GroupName))
  add(formData_603625, "ApplicationName", newJString(ApplicationName))
  add(formData_603625, "Tier.Name", newJString(TierName))
  add(formData_603625, "Tier.Version", newJString(TierVersion))
  add(query_603624, "Action", newJString(Action))
  add(formData_603625, "EnvironmentId", newJString(EnvironmentId))
  add(formData_603625, "SolutionStackName", newJString(SolutionStackName))
  add(query_603624, "Version", newJString(Version))
  add(formData_603625, "PlatformArn", newJString(PlatformArn))
  result = call_603623.call(nil, query_603624, nil, formData_603625, nil)

var postUpdateEnvironment* = Call_PostUpdateEnvironment_603596(
    name: "postUpdateEnvironment", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateEnvironment",
    validator: validate_PostUpdateEnvironment_603597, base: "/",
    url: url_PostUpdateEnvironment_603598, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateEnvironment_603567 = ref object of OpenApiRestCall_601390
proc url_GetUpdateEnvironment_603569(protocol: Scheme; host: string; base: string;
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

proc validate_GetUpdateEnvironment_603568(path: JsonNode; query: JsonNode;
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
  var valid_603570 = query.getOrDefault("ApplicationName")
  valid_603570 = validateParameter(valid_603570, JString, required = false,
                                 default = nil)
  if valid_603570 != nil:
    section.add "ApplicationName", valid_603570
  var valid_603571 = query.getOrDefault("GroupName")
  valid_603571 = validateParameter(valid_603571, JString, required = false,
                                 default = nil)
  if valid_603571 != nil:
    section.add "GroupName", valid_603571
  var valid_603572 = query.getOrDefault("VersionLabel")
  valid_603572 = validateParameter(valid_603572, JString, required = false,
                                 default = nil)
  if valid_603572 != nil:
    section.add "VersionLabel", valid_603572
  var valid_603573 = query.getOrDefault("OptionSettings")
  valid_603573 = validateParameter(valid_603573, JArray, required = false,
                                 default = nil)
  if valid_603573 != nil:
    section.add "OptionSettings", valid_603573
  var valid_603574 = query.getOrDefault("SolutionStackName")
  valid_603574 = validateParameter(valid_603574, JString, required = false,
                                 default = nil)
  if valid_603574 != nil:
    section.add "SolutionStackName", valid_603574
  var valid_603575 = query.getOrDefault("Tier.Name")
  valid_603575 = validateParameter(valid_603575, JString, required = false,
                                 default = nil)
  if valid_603575 != nil:
    section.add "Tier.Name", valid_603575
  var valid_603576 = query.getOrDefault("EnvironmentName")
  valid_603576 = validateParameter(valid_603576, JString, required = false,
                                 default = nil)
  if valid_603576 != nil:
    section.add "EnvironmentName", valid_603576
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603577 = query.getOrDefault("Action")
  valid_603577 = validateParameter(valid_603577, JString, required = true,
                                 default = newJString("UpdateEnvironment"))
  if valid_603577 != nil:
    section.add "Action", valid_603577
  var valid_603578 = query.getOrDefault("Description")
  valid_603578 = validateParameter(valid_603578, JString, required = false,
                                 default = nil)
  if valid_603578 != nil:
    section.add "Description", valid_603578
  var valid_603579 = query.getOrDefault("PlatformArn")
  valid_603579 = validateParameter(valid_603579, JString, required = false,
                                 default = nil)
  if valid_603579 != nil:
    section.add "PlatformArn", valid_603579
  var valid_603580 = query.getOrDefault("OptionsToRemove")
  valid_603580 = validateParameter(valid_603580, JArray, required = false,
                                 default = nil)
  if valid_603580 != nil:
    section.add "OptionsToRemove", valid_603580
  var valid_603581 = query.getOrDefault("Version")
  valid_603581 = validateParameter(valid_603581, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603581 != nil:
    section.add "Version", valid_603581
  var valid_603582 = query.getOrDefault("TemplateName")
  valid_603582 = validateParameter(valid_603582, JString, required = false,
                                 default = nil)
  if valid_603582 != nil:
    section.add "TemplateName", valid_603582
  var valid_603583 = query.getOrDefault("Tier.Version")
  valid_603583 = validateParameter(valid_603583, JString, required = false,
                                 default = nil)
  if valid_603583 != nil:
    section.add "Tier.Version", valid_603583
  var valid_603584 = query.getOrDefault("EnvironmentId")
  valid_603584 = validateParameter(valid_603584, JString, required = false,
                                 default = nil)
  if valid_603584 != nil:
    section.add "EnvironmentId", valid_603584
  var valid_603585 = query.getOrDefault("Tier.Type")
  valid_603585 = validateParameter(valid_603585, JString, required = false,
                                 default = nil)
  if valid_603585 != nil:
    section.add "Tier.Type", valid_603585
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
  var valid_603586 = header.getOrDefault("X-Amz-Signature")
  valid_603586 = validateParameter(valid_603586, JString, required = false,
                                 default = nil)
  if valid_603586 != nil:
    section.add "X-Amz-Signature", valid_603586
  var valid_603587 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603587 = validateParameter(valid_603587, JString, required = false,
                                 default = nil)
  if valid_603587 != nil:
    section.add "X-Amz-Content-Sha256", valid_603587
  var valid_603588 = header.getOrDefault("X-Amz-Date")
  valid_603588 = validateParameter(valid_603588, JString, required = false,
                                 default = nil)
  if valid_603588 != nil:
    section.add "X-Amz-Date", valid_603588
  var valid_603589 = header.getOrDefault("X-Amz-Credential")
  valid_603589 = validateParameter(valid_603589, JString, required = false,
                                 default = nil)
  if valid_603589 != nil:
    section.add "X-Amz-Credential", valid_603589
  var valid_603590 = header.getOrDefault("X-Amz-Security-Token")
  valid_603590 = validateParameter(valid_603590, JString, required = false,
                                 default = nil)
  if valid_603590 != nil:
    section.add "X-Amz-Security-Token", valid_603590
  var valid_603591 = header.getOrDefault("X-Amz-Algorithm")
  valid_603591 = validateParameter(valid_603591, JString, required = false,
                                 default = nil)
  if valid_603591 != nil:
    section.add "X-Amz-Algorithm", valid_603591
  var valid_603592 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603592 = validateParameter(valid_603592, JString, required = false,
                                 default = nil)
  if valid_603592 != nil:
    section.add "X-Amz-SignedHeaders", valid_603592
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603593: Call_GetUpdateEnvironment_603567; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the environment description, deploys a new application version, updates the configuration settings to an entirely new configuration template, or updates select configuration option values in the running environment.</p> <p> Attempting to update both the release and configuration is not allowed and AWS Elastic Beanstalk returns an <code>InvalidParameterCombination</code> error. </p> <p> When updating the configuration settings to a new template or individual settings, a draft configuration is created and <a>DescribeConfigurationSettings</a> for this environment returns two setting descriptions with different <code>DeploymentStatus</code> values. </p>
  ## 
  let valid = call_603593.validator(path, query, header, formData, body)
  let scheme = call_603593.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603593.url(scheme.get, call_603593.host, call_603593.base,
                         call_603593.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603593, url, valid)

proc call*(call_603594: Call_GetUpdateEnvironment_603567;
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
  var query_603595 = newJObject()
  add(query_603595, "ApplicationName", newJString(ApplicationName))
  add(query_603595, "GroupName", newJString(GroupName))
  add(query_603595, "VersionLabel", newJString(VersionLabel))
  if OptionSettings != nil:
    query_603595.add "OptionSettings", OptionSettings
  add(query_603595, "SolutionStackName", newJString(SolutionStackName))
  add(query_603595, "Tier.Name", newJString(TierName))
  add(query_603595, "EnvironmentName", newJString(EnvironmentName))
  add(query_603595, "Action", newJString(Action))
  add(query_603595, "Description", newJString(Description))
  add(query_603595, "PlatformArn", newJString(PlatformArn))
  if OptionsToRemove != nil:
    query_603595.add "OptionsToRemove", OptionsToRemove
  add(query_603595, "Version", newJString(Version))
  add(query_603595, "TemplateName", newJString(TemplateName))
  add(query_603595, "Tier.Version", newJString(TierVersion))
  add(query_603595, "EnvironmentId", newJString(EnvironmentId))
  add(query_603595, "Tier.Type", newJString(TierType))
  result = call_603594.call(nil, query_603595, nil, nil, nil)

var getUpdateEnvironment* = Call_GetUpdateEnvironment_603567(
    name: "getUpdateEnvironment", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com", route: "/#Action=UpdateEnvironment",
    validator: validate_GetUpdateEnvironment_603568, base: "/",
    url: url_GetUpdateEnvironment_603569, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateTagsForResource_603644 = ref object of OpenApiRestCall_601390
proc url_PostUpdateTagsForResource_603646(protocol: Scheme; host: string;
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

proc validate_PostUpdateTagsForResource_603645(path: JsonNode; query: JsonNode;
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
  var valid_603647 = query.getOrDefault("Action")
  valid_603647 = validateParameter(valid_603647, JString, required = true,
                                 default = newJString("UpdateTagsForResource"))
  if valid_603647 != nil:
    section.add "Action", valid_603647
  var valid_603648 = query.getOrDefault("Version")
  valid_603648 = validateParameter(valid_603648, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603648 != nil:
    section.add "Version", valid_603648
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
  var valid_603649 = header.getOrDefault("X-Amz-Signature")
  valid_603649 = validateParameter(valid_603649, JString, required = false,
                                 default = nil)
  if valid_603649 != nil:
    section.add "X-Amz-Signature", valid_603649
  var valid_603650 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603650 = validateParameter(valid_603650, JString, required = false,
                                 default = nil)
  if valid_603650 != nil:
    section.add "X-Amz-Content-Sha256", valid_603650
  var valid_603651 = header.getOrDefault("X-Amz-Date")
  valid_603651 = validateParameter(valid_603651, JString, required = false,
                                 default = nil)
  if valid_603651 != nil:
    section.add "X-Amz-Date", valid_603651
  var valid_603652 = header.getOrDefault("X-Amz-Credential")
  valid_603652 = validateParameter(valid_603652, JString, required = false,
                                 default = nil)
  if valid_603652 != nil:
    section.add "X-Amz-Credential", valid_603652
  var valid_603653 = header.getOrDefault("X-Amz-Security-Token")
  valid_603653 = validateParameter(valid_603653, JString, required = false,
                                 default = nil)
  if valid_603653 != nil:
    section.add "X-Amz-Security-Token", valid_603653
  var valid_603654 = header.getOrDefault("X-Amz-Algorithm")
  valid_603654 = validateParameter(valid_603654, JString, required = false,
                                 default = nil)
  if valid_603654 != nil:
    section.add "X-Amz-Algorithm", valid_603654
  var valid_603655 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603655 = validateParameter(valid_603655, JString, required = false,
                                 default = nil)
  if valid_603655 != nil:
    section.add "X-Amz-SignedHeaders", valid_603655
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
  var valid_603656 = formData.getOrDefault("ResourceArn")
  valid_603656 = validateParameter(valid_603656, JString, required = true,
                                 default = nil)
  if valid_603656 != nil:
    section.add "ResourceArn", valid_603656
  var valid_603657 = formData.getOrDefault("TagsToAdd")
  valid_603657 = validateParameter(valid_603657, JArray, required = false,
                                 default = nil)
  if valid_603657 != nil:
    section.add "TagsToAdd", valid_603657
  var valid_603658 = formData.getOrDefault("TagsToRemove")
  valid_603658 = validateParameter(valid_603658, JArray, required = false,
                                 default = nil)
  if valid_603658 != nil:
    section.add "TagsToRemove", valid_603658
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603659: Call_PostUpdateTagsForResource_603644; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Update the list of tags applied to an AWS Elastic Beanstalk resource. Two lists can be passed: <code>TagsToAdd</code> for tags to add or update, and <code>TagsToRemove</code>.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p> <p>If you create a custom IAM user policy to control permission to this operation, specify one of the following two virtual actions (or both) instead of the API operation name:</p> <dl> <dt>elasticbeanstalk:AddTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tags to add in the <code>TagsToAdd</code> parameter.</p> </dd> <dt>elasticbeanstalk:RemoveTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tag keys to remove in the <code>TagsToRemove</code> parameter.</p> </dd> </dl> <p>For details about creating a custom user policy, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/AWSHowTo.iam.managed-policies.html#AWSHowTo.iam.policies">Creating a Custom User Policy</a>.</p>
  ## 
  let valid = call_603659.validator(path, query, header, formData, body)
  let scheme = call_603659.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603659.url(scheme.get, call_603659.host, call_603659.base,
                         call_603659.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603659, url, valid)

proc call*(call_603660: Call_PostUpdateTagsForResource_603644; ResourceArn: string;
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
  var query_603661 = newJObject()
  var formData_603662 = newJObject()
  add(formData_603662, "ResourceArn", newJString(ResourceArn))
  add(query_603661, "Action", newJString(Action))
  if TagsToAdd != nil:
    formData_603662.add "TagsToAdd", TagsToAdd
  if TagsToRemove != nil:
    formData_603662.add "TagsToRemove", TagsToRemove
  add(query_603661, "Version", newJString(Version))
  result = call_603660.call(nil, query_603661, nil, formData_603662, nil)

var postUpdateTagsForResource* = Call_PostUpdateTagsForResource_603644(
    name: "postUpdateTagsForResource", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateTagsForResource",
    validator: validate_PostUpdateTagsForResource_603645, base: "/",
    url: url_PostUpdateTagsForResource_603646,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateTagsForResource_603626 = ref object of OpenApiRestCall_601390
proc url_GetUpdateTagsForResource_603628(protocol: Scheme; host: string;
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

proc validate_GetUpdateTagsForResource_603627(path: JsonNode; query: JsonNode;
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
  var valid_603629 = query.getOrDefault("TagsToAdd")
  valid_603629 = validateParameter(valid_603629, JArray, required = false,
                                 default = nil)
  if valid_603629 != nil:
    section.add "TagsToAdd", valid_603629
  var valid_603630 = query.getOrDefault("TagsToRemove")
  valid_603630 = validateParameter(valid_603630, JArray, required = false,
                                 default = nil)
  if valid_603630 != nil:
    section.add "TagsToRemove", valid_603630
  assert query != nil,
        "query argument is necessary due to required `ResourceArn` field"
  var valid_603631 = query.getOrDefault("ResourceArn")
  valid_603631 = validateParameter(valid_603631, JString, required = true,
                                 default = nil)
  if valid_603631 != nil:
    section.add "ResourceArn", valid_603631
  var valid_603632 = query.getOrDefault("Action")
  valid_603632 = validateParameter(valid_603632, JString, required = true,
                                 default = newJString("UpdateTagsForResource"))
  if valid_603632 != nil:
    section.add "Action", valid_603632
  var valid_603633 = query.getOrDefault("Version")
  valid_603633 = validateParameter(valid_603633, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603633 != nil:
    section.add "Version", valid_603633
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
  var valid_603634 = header.getOrDefault("X-Amz-Signature")
  valid_603634 = validateParameter(valid_603634, JString, required = false,
                                 default = nil)
  if valid_603634 != nil:
    section.add "X-Amz-Signature", valid_603634
  var valid_603635 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603635 = validateParameter(valid_603635, JString, required = false,
                                 default = nil)
  if valid_603635 != nil:
    section.add "X-Amz-Content-Sha256", valid_603635
  var valid_603636 = header.getOrDefault("X-Amz-Date")
  valid_603636 = validateParameter(valid_603636, JString, required = false,
                                 default = nil)
  if valid_603636 != nil:
    section.add "X-Amz-Date", valid_603636
  var valid_603637 = header.getOrDefault("X-Amz-Credential")
  valid_603637 = validateParameter(valid_603637, JString, required = false,
                                 default = nil)
  if valid_603637 != nil:
    section.add "X-Amz-Credential", valid_603637
  var valid_603638 = header.getOrDefault("X-Amz-Security-Token")
  valid_603638 = validateParameter(valid_603638, JString, required = false,
                                 default = nil)
  if valid_603638 != nil:
    section.add "X-Amz-Security-Token", valid_603638
  var valid_603639 = header.getOrDefault("X-Amz-Algorithm")
  valid_603639 = validateParameter(valid_603639, JString, required = false,
                                 default = nil)
  if valid_603639 != nil:
    section.add "X-Amz-Algorithm", valid_603639
  var valid_603640 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603640 = validateParameter(valid_603640, JString, required = false,
                                 default = nil)
  if valid_603640 != nil:
    section.add "X-Amz-SignedHeaders", valid_603640
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603641: Call_GetUpdateTagsForResource_603626; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Update the list of tags applied to an AWS Elastic Beanstalk resource. Two lists can be passed: <code>TagsToAdd</code> for tags to add or update, and <code>TagsToRemove</code>.</p> <p>Currently, Elastic Beanstalk only supports tagging of Elastic Beanstalk environments. For details about environment tagging, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.tagging.html">Tagging Resources in Your Elastic Beanstalk Environment</a>.</p> <p>If you create a custom IAM user policy to control permission to this operation, specify one of the following two virtual actions (or both) instead of the API operation name:</p> <dl> <dt>elasticbeanstalk:AddTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tags to add in the <code>TagsToAdd</code> parameter.</p> </dd> <dt>elasticbeanstalk:RemoveTags</dt> <dd> <p>Controls permission to call <code>UpdateTagsForResource</code> and pass a list of tag keys to remove in the <code>TagsToRemove</code> parameter.</p> </dd> </dl> <p>For details about creating a custom user policy, see <a href="https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/AWSHowTo.iam.managed-policies.html#AWSHowTo.iam.policies">Creating a Custom User Policy</a>.</p>
  ## 
  let valid = call_603641.validator(path, query, header, formData, body)
  let scheme = call_603641.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603641.url(scheme.get, call_603641.host, call_603641.base,
                         call_603641.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603641, url, valid)

proc call*(call_603642: Call_GetUpdateTagsForResource_603626; ResourceArn: string;
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
  var query_603643 = newJObject()
  if TagsToAdd != nil:
    query_603643.add "TagsToAdd", TagsToAdd
  if TagsToRemove != nil:
    query_603643.add "TagsToRemove", TagsToRemove
  add(query_603643, "ResourceArn", newJString(ResourceArn))
  add(query_603643, "Action", newJString(Action))
  add(query_603643, "Version", newJString(Version))
  result = call_603642.call(nil, query_603643, nil, nil, nil)

var getUpdateTagsForResource* = Call_GetUpdateTagsForResource_603626(
    name: "getUpdateTagsForResource", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=UpdateTagsForResource",
    validator: validate_GetUpdateTagsForResource_603627, base: "/",
    url: url_GetUpdateTagsForResource_603628, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostValidateConfigurationSettings_603682 = ref object of OpenApiRestCall_601390
proc url_PostValidateConfigurationSettings_603684(protocol: Scheme; host: string;
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

proc validate_PostValidateConfigurationSettings_603683(path: JsonNode;
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
  var valid_603685 = query.getOrDefault("Action")
  valid_603685 = validateParameter(valid_603685, JString, required = true, default = newJString(
      "ValidateConfigurationSettings"))
  if valid_603685 != nil:
    section.add "Action", valid_603685
  var valid_603686 = query.getOrDefault("Version")
  valid_603686 = validateParameter(valid_603686, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603686 != nil:
    section.add "Version", valid_603686
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
  var valid_603687 = header.getOrDefault("X-Amz-Signature")
  valid_603687 = validateParameter(valid_603687, JString, required = false,
                                 default = nil)
  if valid_603687 != nil:
    section.add "X-Amz-Signature", valid_603687
  var valid_603688 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603688 = validateParameter(valid_603688, JString, required = false,
                                 default = nil)
  if valid_603688 != nil:
    section.add "X-Amz-Content-Sha256", valid_603688
  var valid_603689 = header.getOrDefault("X-Amz-Date")
  valid_603689 = validateParameter(valid_603689, JString, required = false,
                                 default = nil)
  if valid_603689 != nil:
    section.add "X-Amz-Date", valid_603689
  var valid_603690 = header.getOrDefault("X-Amz-Credential")
  valid_603690 = validateParameter(valid_603690, JString, required = false,
                                 default = nil)
  if valid_603690 != nil:
    section.add "X-Amz-Credential", valid_603690
  var valid_603691 = header.getOrDefault("X-Amz-Security-Token")
  valid_603691 = validateParameter(valid_603691, JString, required = false,
                                 default = nil)
  if valid_603691 != nil:
    section.add "X-Amz-Security-Token", valid_603691
  var valid_603692 = header.getOrDefault("X-Amz-Algorithm")
  valid_603692 = validateParameter(valid_603692, JString, required = false,
                                 default = nil)
  if valid_603692 != nil:
    section.add "X-Amz-Algorithm", valid_603692
  var valid_603693 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603693 = validateParameter(valid_603693, JString, required = false,
                                 default = nil)
  if valid_603693 != nil:
    section.add "X-Amz-SignedHeaders", valid_603693
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
  var valid_603694 = formData.getOrDefault("EnvironmentName")
  valid_603694 = validateParameter(valid_603694, JString, required = false,
                                 default = nil)
  if valid_603694 != nil:
    section.add "EnvironmentName", valid_603694
  var valid_603695 = formData.getOrDefault("TemplateName")
  valid_603695 = validateParameter(valid_603695, JString, required = false,
                                 default = nil)
  if valid_603695 != nil:
    section.add "TemplateName", valid_603695
  assert formData != nil,
        "formData argument is necessary due to required `OptionSettings` field"
  var valid_603696 = formData.getOrDefault("OptionSettings")
  valid_603696 = validateParameter(valid_603696, JArray, required = true, default = nil)
  if valid_603696 != nil:
    section.add "OptionSettings", valid_603696
  var valid_603697 = formData.getOrDefault("ApplicationName")
  valid_603697 = validateParameter(valid_603697, JString, required = true,
                                 default = nil)
  if valid_603697 != nil:
    section.add "ApplicationName", valid_603697
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603698: Call_PostValidateConfigurationSettings_603682;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Takes a set of configuration settings and either a configuration template or environment, and determines whether those values are valid.</p> <p>This action returns a list of messages indicating any errors or warnings associated with the selection of option values.</p>
  ## 
  let valid = call_603698.validator(path, query, header, formData, body)
  let scheme = call_603698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603698.url(scheme.get, call_603698.host, call_603698.base,
                         call_603698.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603698, url, valid)

proc call*(call_603699: Call_PostValidateConfigurationSettings_603682;
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
  var query_603700 = newJObject()
  var formData_603701 = newJObject()
  add(formData_603701, "EnvironmentName", newJString(EnvironmentName))
  add(formData_603701, "TemplateName", newJString(TemplateName))
  if OptionSettings != nil:
    formData_603701.add "OptionSettings", OptionSettings
  add(formData_603701, "ApplicationName", newJString(ApplicationName))
  add(query_603700, "Action", newJString(Action))
  add(query_603700, "Version", newJString(Version))
  result = call_603699.call(nil, query_603700, nil, formData_603701, nil)

var postValidateConfigurationSettings* = Call_PostValidateConfigurationSettings_603682(
    name: "postValidateConfigurationSettings", meth: HttpMethod.HttpPost,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ValidateConfigurationSettings",
    validator: validate_PostValidateConfigurationSettings_603683, base: "/",
    url: url_PostValidateConfigurationSettings_603684,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetValidateConfigurationSettings_603663 = ref object of OpenApiRestCall_601390
proc url_GetValidateConfigurationSettings_603665(protocol: Scheme; host: string;
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

proc validate_GetValidateConfigurationSettings_603664(path: JsonNode;
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
  var valid_603666 = query.getOrDefault("ApplicationName")
  valid_603666 = validateParameter(valid_603666, JString, required = true,
                                 default = nil)
  if valid_603666 != nil:
    section.add "ApplicationName", valid_603666
  var valid_603667 = query.getOrDefault("OptionSettings")
  valid_603667 = validateParameter(valid_603667, JArray, required = true, default = nil)
  if valid_603667 != nil:
    section.add "OptionSettings", valid_603667
  var valid_603668 = query.getOrDefault("EnvironmentName")
  valid_603668 = validateParameter(valid_603668, JString, required = false,
                                 default = nil)
  if valid_603668 != nil:
    section.add "EnvironmentName", valid_603668
  var valid_603669 = query.getOrDefault("Action")
  valid_603669 = validateParameter(valid_603669, JString, required = true, default = newJString(
      "ValidateConfigurationSettings"))
  if valid_603669 != nil:
    section.add "Action", valid_603669
  var valid_603670 = query.getOrDefault("Version")
  valid_603670 = validateParameter(valid_603670, JString, required = true,
                                 default = newJString("2010-12-01"))
  if valid_603670 != nil:
    section.add "Version", valid_603670
  var valid_603671 = query.getOrDefault("TemplateName")
  valid_603671 = validateParameter(valid_603671, JString, required = false,
                                 default = nil)
  if valid_603671 != nil:
    section.add "TemplateName", valid_603671
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
  var valid_603672 = header.getOrDefault("X-Amz-Signature")
  valid_603672 = validateParameter(valid_603672, JString, required = false,
                                 default = nil)
  if valid_603672 != nil:
    section.add "X-Amz-Signature", valid_603672
  var valid_603673 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603673 = validateParameter(valid_603673, JString, required = false,
                                 default = nil)
  if valid_603673 != nil:
    section.add "X-Amz-Content-Sha256", valid_603673
  var valid_603674 = header.getOrDefault("X-Amz-Date")
  valid_603674 = validateParameter(valid_603674, JString, required = false,
                                 default = nil)
  if valid_603674 != nil:
    section.add "X-Amz-Date", valid_603674
  var valid_603675 = header.getOrDefault("X-Amz-Credential")
  valid_603675 = validateParameter(valid_603675, JString, required = false,
                                 default = nil)
  if valid_603675 != nil:
    section.add "X-Amz-Credential", valid_603675
  var valid_603676 = header.getOrDefault("X-Amz-Security-Token")
  valid_603676 = validateParameter(valid_603676, JString, required = false,
                                 default = nil)
  if valid_603676 != nil:
    section.add "X-Amz-Security-Token", valid_603676
  var valid_603677 = header.getOrDefault("X-Amz-Algorithm")
  valid_603677 = validateParameter(valid_603677, JString, required = false,
                                 default = nil)
  if valid_603677 != nil:
    section.add "X-Amz-Algorithm", valid_603677
  var valid_603678 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603678 = validateParameter(valid_603678, JString, required = false,
                                 default = nil)
  if valid_603678 != nil:
    section.add "X-Amz-SignedHeaders", valid_603678
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603679: Call_GetValidateConfigurationSettings_603663;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Takes a set of configuration settings and either a configuration template or environment, and determines whether those values are valid.</p> <p>This action returns a list of messages indicating any errors or warnings associated with the selection of option values.</p>
  ## 
  let valid = call_603679.validator(path, query, header, formData, body)
  let scheme = call_603679.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603679.url(scheme.get, call_603679.host, call_603679.base,
                         call_603679.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_603679, url, valid)

proc call*(call_603680: Call_GetValidateConfigurationSettings_603663;
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
  var query_603681 = newJObject()
  add(query_603681, "ApplicationName", newJString(ApplicationName))
  if OptionSettings != nil:
    query_603681.add "OptionSettings", OptionSettings
  add(query_603681, "EnvironmentName", newJString(EnvironmentName))
  add(query_603681, "Action", newJString(Action))
  add(query_603681, "Version", newJString(Version))
  add(query_603681, "TemplateName", newJString(TemplateName))
  result = call_603680.call(nil, query_603681, nil, nil, nil)

var getValidateConfigurationSettings* = Call_GetValidateConfigurationSettings_603663(
    name: "getValidateConfigurationSettings", meth: HttpMethod.HttpGet,
    host: "elasticbeanstalk.amazonaws.com",
    route: "/#Action=ValidateConfigurationSettings",
    validator: validate_GetValidateConfigurationSettings_603664, base: "/",
    url: url_GetValidateConfigurationSettings_603665,
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

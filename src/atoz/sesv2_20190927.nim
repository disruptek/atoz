
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Simple Email Service
## version: 2019-09-27
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon SES API v2</fullname> <p>Welcome to the Amazon SES API v2 Reference. This guide provides information about the Amazon SES API v2, including supported operations, data types, parameters, and schemas.</p> <p> <a href="https://aws.amazon.com/pinpoint">Amazon SES</a> is an AWS service that you can use to send email messages to your customers.</p> <p>If you're new to Amazon SES API v2, you might find it helpful to also review the <a href="https://docs.aws.amazon.com/ses/latest/DeveloperGuide/">Amazon Simple Email Service Developer Guide</a>. The <i>Amazon SES Developer Guide</i> provides information and code samples that demonstrate how to use Amazon SES API v2 features programmatically.</p> <p>The Amazon SES API v2 is available in several AWS Regions and it provides an endpoint for each of these Regions. For a list of all the Regions and endpoints where the API is currently available, see <a href="https://docs.aws.amazon.com/general/latest/gr/rande.html#ses_region">AWS Service Endpoints</a> in the <i>Amazon Web Services General Reference</i>. To learn more about AWS Regions, see <a href="https://docs.aws.amazon.com/general/latest/gr/rande-manage.html">Managing AWS Regions</a> in the <i>Amazon Web Services General Reference</i>.</p> <p>In each Region, AWS maintains multiple Availability Zones. These Availability Zones are physically isolated from each other, but are united by private, low-latency, high-throughput, and highly redundant network connections. These Availability Zones enable us to provide very high levels of availability and redundancy, while also minimizing latency. To learn more about the number of Availability Zones that are available in each Region, see <a href="http://aws.amazon.com/about-aws/global-infrastructure/">AWS Global Infrastructure</a>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/email/
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

  OpenApiRestCall_601389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601389): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "email.ap-northeast-1.amazonaws.com", "ap-southeast-1": "email.ap-southeast-1.amazonaws.com",
                           "us-west-2": "email.us-west-2.amazonaws.com",
                           "eu-west-2": "email.eu-west-2.amazonaws.com", "ap-northeast-3": "email.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "email.eu-central-1.amazonaws.com",
                           "us-east-2": "email.us-east-2.amazonaws.com",
                           "us-east-1": "email.us-east-1.amazonaws.com", "cn-northwest-1": "email.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "email.ap-south-1.amazonaws.com",
                           "eu-north-1": "email.eu-north-1.amazonaws.com", "ap-northeast-2": "email.ap-northeast-2.amazonaws.com",
                           "us-west-1": "email.us-west-1.amazonaws.com", "us-gov-east-1": "email.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "email.eu-west-3.amazonaws.com",
                           "cn-north-1": "email.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "email.sa-east-1.amazonaws.com",
                           "eu-west-1": "email.eu-west-1.amazonaws.com", "us-gov-west-1": "email.us-gov-west-1.amazonaws.com", "ap-southeast-2": "email.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "email.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "email.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "email.ap-southeast-1.amazonaws.com",
      "us-west-2": "email.us-west-2.amazonaws.com",
      "eu-west-2": "email.eu-west-2.amazonaws.com",
      "ap-northeast-3": "email.ap-northeast-3.amazonaws.com",
      "eu-central-1": "email.eu-central-1.amazonaws.com",
      "us-east-2": "email.us-east-2.amazonaws.com",
      "us-east-1": "email.us-east-1.amazonaws.com",
      "cn-northwest-1": "email.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "email.ap-south-1.amazonaws.com",
      "eu-north-1": "email.eu-north-1.amazonaws.com",
      "ap-northeast-2": "email.ap-northeast-2.amazonaws.com",
      "us-west-1": "email.us-west-1.amazonaws.com",
      "us-gov-east-1": "email.us-gov-east-1.amazonaws.com",
      "eu-west-3": "email.eu-west-3.amazonaws.com",
      "cn-north-1": "email.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "email.sa-east-1.amazonaws.com",
      "eu-west-1": "email.eu-west-1.amazonaws.com",
      "us-gov-west-1": "email.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "email.ap-southeast-2.amazonaws.com",
      "ca-central-1": "email.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "sesv2"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateConfigurationSet_601984 = ref object of OpenApiRestCall_601389
proc url_CreateConfigurationSet_601986(protocol: Scheme; host: string; base: string;
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

proc validate_CreateConfigurationSet_601985(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Create a configuration set. <i>Configuration sets</i> are groups of rules that you can apply to the emails that you send. You apply a configuration set to an email by specifying the name of the configuration set when you call the Amazon SES API v2. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_601987 = header.getOrDefault("X-Amz-Signature")
  valid_601987 = validateParameter(valid_601987, JString, required = false,
                                 default = nil)
  if valid_601987 != nil:
    section.add "X-Amz-Signature", valid_601987
  var valid_601988 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601988 = validateParameter(valid_601988, JString, required = false,
                                 default = nil)
  if valid_601988 != nil:
    section.add "X-Amz-Content-Sha256", valid_601988
  var valid_601989 = header.getOrDefault("X-Amz-Date")
  valid_601989 = validateParameter(valid_601989, JString, required = false,
                                 default = nil)
  if valid_601989 != nil:
    section.add "X-Amz-Date", valid_601989
  var valid_601990 = header.getOrDefault("X-Amz-Credential")
  valid_601990 = validateParameter(valid_601990, JString, required = false,
                                 default = nil)
  if valid_601990 != nil:
    section.add "X-Amz-Credential", valid_601990
  var valid_601991 = header.getOrDefault("X-Amz-Security-Token")
  valid_601991 = validateParameter(valid_601991, JString, required = false,
                                 default = nil)
  if valid_601991 != nil:
    section.add "X-Amz-Security-Token", valid_601991
  var valid_601992 = header.getOrDefault("X-Amz-Algorithm")
  valid_601992 = validateParameter(valid_601992, JString, required = false,
                                 default = nil)
  if valid_601992 != nil:
    section.add "X-Amz-Algorithm", valid_601992
  var valid_601993 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601993 = validateParameter(valid_601993, JString, required = false,
                                 default = nil)
  if valid_601993 != nil:
    section.add "X-Amz-SignedHeaders", valid_601993
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601995: Call_CreateConfigurationSet_601984; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a configuration set. <i>Configuration sets</i> are groups of rules that you can apply to the emails that you send. You apply a configuration set to an email by specifying the name of the configuration set when you call the Amazon SES API v2. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email. 
  ## 
  let valid = call_601995.validator(path, query, header, formData, body)
  let scheme = call_601995.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601995.url(scheme.get, call_601995.host, call_601995.base,
                         call_601995.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601995, url, valid)

proc call*(call_601996: Call_CreateConfigurationSet_601984; body: JsonNode): Recallable =
  ## createConfigurationSet
  ## Create a configuration set. <i>Configuration sets</i> are groups of rules that you can apply to the emails that you send. You apply a configuration set to an email by specifying the name of the configuration set when you call the Amazon SES API v2. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email. 
  ##   body: JObject (required)
  var body_601997 = newJObject()
  if body != nil:
    body_601997 = body
  result = call_601996.call(nil, nil, nil, nil, body_601997)

var createConfigurationSet* = Call_CreateConfigurationSet_601984(
    name: "createConfigurationSet", meth: HttpMethod.HttpPost,
    host: "email.amazonaws.com", route: "/v2/email/configuration-sets",
    validator: validate_CreateConfigurationSet_601985, base: "/",
    url: url_CreateConfigurationSet_601986, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurationSets_601727 = ref object of OpenApiRestCall_601389
proc url_ListConfigurationSets_601729(protocol: Scheme; host: string; base: string;
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

proc validate_ListConfigurationSets_601728(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>List all of the configuration sets associated with your account in the current region.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : A token returned from a previous call to <code>ListConfigurationSets</code> to indicate the position in the list of configuration sets.
  ##   PageSize: JInt
  ##           : The number of results to show in a single call to <code>ListConfigurationSets</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  section = newJObject()
  var valid_601841 = query.getOrDefault("NextToken")
  valid_601841 = validateParameter(valid_601841, JString, required = false,
                                 default = nil)
  if valid_601841 != nil:
    section.add "NextToken", valid_601841
  var valid_601842 = query.getOrDefault("PageSize")
  valid_601842 = validateParameter(valid_601842, JInt, required = false, default = nil)
  if valid_601842 != nil:
    section.add "PageSize", valid_601842
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_601843 = header.getOrDefault("X-Amz-Signature")
  valid_601843 = validateParameter(valid_601843, JString, required = false,
                                 default = nil)
  if valid_601843 != nil:
    section.add "X-Amz-Signature", valid_601843
  var valid_601844 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601844 = validateParameter(valid_601844, JString, required = false,
                                 default = nil)
  if valid_601844 != nil:
    section.add "X-Amz-Content-Sha256", valid_601844
  var valid_601845 = header.getOrDefault("X-Amz-Date")
  valid_601845 = validateParameter(valid_601845, JString, required = false,
                                 default = nil)
  if valid_601845 != nil:
    section.add "X-Amz-Date", valid_601845
  var valid_601846 = header.getOrDefault("X-Amz-Credential")
  valid_601846 = validateParameter(valid_601846, JString, required = false,
                                 default = nil)
  if valid_601846 != nil:
    section.add "X-Amz-Credential", valid_601846
  var valid_601847 = header.getOrDefault("X-Amz-Security-Token")
  valid_601847 = validateParameter(valid_601847, JString, required = false,
                                 default = nil)
  if valid_601847 != nil:
    section.add "X-Amz-Security-Token", valid_601847
  var valid_601848 = header.getOrDefault("X-Amz-Algorithm")
  valid_601848 = validateParameter(valid_601848, JString, required = false,
                                 default = nil)
  if valid_601848 != nil:
    section.add "X-Amz-Algorithm", valid_601848
  var valid_601849 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601849 = validateParameter(valid_601849, JString, required = false,
                                 default = nil)
  if valid_601849 != nil:
    section.add "X-Amz-SignedHeaders", valid_601849
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601872: Call_ListConfigurationSets_601727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>List all of the configuration sets associated with your account in the current region.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ## 
  let valid = call_601872.validator(path, query, header, formData, body)
  let scheme = call_601872.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601872.url(scheme.get, call_601872.host, call_601872.base,
                         call_601872.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601872, url, valid)

proc call*(call_601943: Call_ListConfigurationSets_601727; NextToken: string = "";
          PageSize: int = 0): Recallable =
  ## listConfigurationSets
  ## <p>List all of the configuration sets associated with your account in the current region.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   NextToken: string
  ##            : A token returned from a previous call to <code>ListConfigurationSets</code> to indicate the position in the list of configuration sets.
  ##   PageSize: int
  ##           : The number of results to show in a single call to <code>ListConfigurationSets</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  var query_601944 = newJObject()
  add(query_601944, "NextToken", newJString(NextToken))
  add(query_601944, "PageSize", newJInt(PageSize))
  result = call_601943.call(nil, query_601944, nil, nil, nil)

var listConfigurationSets* = Call_ListConfigurationSets_601727(
    name: "listConfigurationSets", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v2/email/configuration-sets",
    validator: validate_ListConfigurationSets_601728, base: "/",
    url: url_ListConfigurationSets_601729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConfigurationSetEventDestination_602026 = ref object of OpenApiRestCall_601389
proc url_CreateConfigurationSetEventDestination_602028(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
        "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/email/configuration-sets/"),
               (kind: VariableSegment, value: "ConfigurationSetName"),
               (kind: ConstantSegment, value: "/event-destinations")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateConfigurationSetEventDestination_602027(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Create an event destination. <i>Events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p> <p>A single configuration set can include more than one event destination.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : <p>The name of a configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_602029 = path.getOrDefault("ConfigurationSetName")
  valid_602029 = validateParameter(valid_602029, JString, required = true,
                                 default = nil)
  if valid_602029 != nil:
    section.add "ConfigurationSetName", valid_602029
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602030 = header.getOrDefault("X-Amz-Signature")
  valid_602030 = validateParameter(valid_602030, JString, required = false,
                                 default = nil)
  if valid_602030 != nil:
    section.add "X-Amz-Signature", valid_602030
  var valid_602031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602031 = validateParameter(valid_602031, JString, required = false,
                                 default = nil)
  if valid_602031 != nil:
    section.add "X-Amz-Content-Sha256", valid_602031
  var valid_602032 = header.getOrDefault("X-Amz-Date")
  valid_602032 = validateParameter(valid_602032, JString, required = false,
                                 default = nil)
  if valid_602032 != nil:
    section.add "X-Amz-Date", valid_602032
  var valid_602033 = header.getOrDefault("X-Amz-Credential")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "X-Amz-Credential", valid_602033
  var valid_602034 = header.getOrDefault("X-Amz-Security-Token")
  valid_602034 = validateParameter(valid_602034, JString, required = false,
                                 default = nil)
  if valid_602034 != nil:
    section.add "X-Amz-Security-Token", valid_602034
  var valid_602035 = header.getOrDefault("X-Amz-Algorithm")
  valid_602035 = validateParameter(valid_602035, JString, required = false,
                                 default = nil)
  if valid_602035 != nil:
    section.add "X-Amz-Algorithm", valid_602035
  var valid_602036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602036 = validateParameter(valid_602036, JString, required = false,
                                 default = nil)
  if valid_602036 != nil:
    section.add "X-Amz-SignedHeaders", valid_602036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602038: Call_CreateConfigurationSetEventDestination_602026;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Create an event destination. <i>Events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p> <p>A single configuration set can include more than one event destination.</p>
  ## 
  let valid = call_602038.validator(path, query, header, formData, body)
  let scheme = call_602038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602038.url(scheme.get, call_602038.host, call_602038.base,
                         call_602038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602038, url, valid)

proc call*(call_602039: Call_CreateConfigurationSetEventDestination_602026;
          ConfigurationSetName: string; body: JsonNode): Recallable =
  ## createConfigurationSetEventDestination
  ## <p>Create an event destination. <i>Events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p> <p>A single configuration set can include more than one event destination.</p>
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   body: JObject (required)
  var path_602040 = newJObject()
  var body_602041 = newJObject()
  add(path_602040, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_602041 = body
  result = call_602039.call(path_602040, nil, nil, nil, body_602041)

var createConfigurationSetEventDestination* = Call_CreateConfigurationSetEventDestination_602026(
    name: "createConfigurationSetEventDestination", meth: HttpMethod.HttpPost,
    host: "email.amazonaws.com", route: "/v2/email/configuration-sets/{ConfigurationSetName}/event-destinations",
    validator: validate_CreateConfigurationSetEventDestination_602027, base: "/",
    url: url_CreateConfigurationSetEventDestination_602028,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfigurationSetEventDestinations_601998 = ref object of OpenApiRestCall_601389
proc url_GetConfigurationSetEventDestinations_602000(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
        "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/email/configuration-sets/"),
               (kind: VariableSegment, value: "ConfigurationSetName"),
               (kind: ConstantSegment, value: "/event-destinations")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetConfigurationSetEventDestinations_601999(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieve a list of event destinations that are associated with a configuration set.</p> <p> <i>Events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : <p>The name of a configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_602015 = path.getOrDefault("ConfigurationSetName")
  valid_602015 = validateParameter(valid_602015, JString, required = true,
                                 default = nil)
  if valid_602015 != nil:
    section.add "ConfigurationSetName", valid_602015
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602016 = header.getOrDefault("X-Amz-Signature")
  valid_602016 = validateParameter(valid_602016, JString, required = false,
                                 default = nil)
  if valid_602016 != nil:
    section.add "X-Amz-Signature", valid_602016
  var valid_602017 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602017 = validateParameter(valid_602017, JString, required = false,
                                 default = nil)
  if valid_602017 != nil:
    section.add "X-Amz-Content-Sha256", valid_602017
  var valid_602018 = header.getOrDefault("X-Amz-Date")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "X-Amz-Date", valid_602018
  var valid_602019 = header.getOrDefault("X-Amz-Credential")
  valid_602019 = validateParameter(valid_602019, JString, required = false,
                                 default = nil)
  if valid_602019 != nil:
    section.add "X-Amz-Credential", valid_602019
  var valid_602020 = header.getOrDefault("X-Amz-Security-Token")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "X-Amz-Security-Token", valid_602020
  var valid_602021 = header.getOrDefault("X-Amz-Algorithm")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "X-Amz-Algorithm", valid_602021
  var valid_602022 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602022 = validateParameter(valid_602022, JString, required = false,
                                 default = nil)
  if valid_602022 != nil:
    section.add "X-Amz-SignedHeaders", valid_602022
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602023: Call_GetConfigurationSetEventDestinations_601998;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Retrieve a list of event destinations that are associated with a configuration set.</p> <p> <i>Events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ## 
  let valid = call_602023.validator(path, query, header, formData, body)
  let scheme = call_602023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602023.url(scheme.get, call_602023.host, call_602023.base,
                         call_602023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602023, url, valid)

proc call*(call_602024: Call_GetConfigurationSetEventDestinations_601998;
          ConfigurationSetName: string): Recallable =
  ## getConfigurationSetEventDestinations
  ## <p>Retrieve a list of event destinations that are associated with a configuration set.</p> <p> <i>Events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  var path_602025 = newJObject()
  add(path_602025, "ConfigurationSetName", newJString(ConfigurationSetName))
  result = call_602024.call(path_602025, nil, nil, nil, nil)

var getConfigurationSetEventDestinations* = Call_GetConfigurationSetEventDestinations_601998(
    name: "getConfigurationSetEventDestinations", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v2/email/configuration-sets/{ConfigurationSetName}/event-destinations",
    validator: validate_GetConfigurationSetEventDestinations_601999, base: "/",
    url: url_GetConfigurationSetEventDestinations_602000,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDedicatedIpPool_602057 = ref object of OpenApiRestCall_601389
proc url_CreateDedicatedIpPool_602059(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDedicatedIpPool_602058(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Create a new pool of dedicated IP addresses. A pool can include one or more dedicated IP addresses that are associated with your AWS account. You can associate a pool with a configuration set. When you send an email that uses that configuration set, the message is sent from one of the addresses in the associated pool.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602060 = header.getOrDefault("X-Amz-Signature")
  valid_602060 = validateParameter(valid_602060, JString, required = false,
                                 default = nil)
  if valid_602060 != nil:
    section.add "X-Amz-Signature", valid_602060
  var valid_602061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602061 = validateParameter(valid_602061, JString, required = false,
                                 default = nil)
  if valid_602061 != nil:
    section.add "X-Amz-Content-Sha256", valid_602061
  var valid_602062 = header.getOrDefault("X-Amz-Date")
  valid_602062 = validateParameter(valid_602062, JString, required = false,
                                 default = nil)
  if valid_602062 != nil:
    section.add "X-Amz-Date", valid_602062
  var valid_602063 = header.getOrDefault("X-Amz-Credential")
  valid_602063 = validateParameter(valid_602063, JString, required = false,
                                 default = nil)
  if valid_602063 != nil:
    section.add "X-Amz-Credential", valid_602063
  var valid_602064 = header.getOrDefault("X-Amz-Security-Token")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "X-Amz-Security-Token", valid_602064
  var valid_602065 = header.getOrDefault("X-Amz-Algorithm")
  valid_602065 = validateParameter(valid_602065, JString, required = false,
                                 default = nil)
  if valid_602065 != nil:
    section.add "X-Amz-Algorithm", valid_602065
  var valid_602066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "X-Amz-SignedHeaders", valid_602066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602068: Call_CreateDedicatedIpPool_602057; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new pool of dedicated IP addresses. A pool can include one or more dedicated IP addresses that are associated with your AWS account. You can associate a pool with a configuration set. When you send an email that uses that configuration set, the message is sent from one of the addresses in the associated pool.
  ## 
  let valid = call_602068.validator(path, query, header, formData, body)
  let scheme = call_602068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602068.url(scheme.get, call_602068.host, call_602068.base,
                         call_602068.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602068, url, valid)

proc call*(call_602069: Call_CreateDedicatedIpPool_602057; body: JsonNode): Recallable =
  ## createDedicatedIpPool
  ## Create a new pool of dedicated IP addresses. A pool can include one or more dedicated IP addresses that are associated with your AWS account. You can associate a pool with a configuration set. When you send an email that uses that configuration set, the message is sent from one of the addresses in the associated pool.
  ##   body: JObject (required)
  var body_602070 = newJObject()
  if body != nil:
    body_602070 = body
  result = call_602069.call(nil, nil, nil, nil, body_602070)

var createDedicatedIpPool* = Call_CreateDedicatedIpPool_602057(
    name: "createDedicatedIpPool", meth: HttpMethod.HttpPost,
    host: "email.amazonaws.com", route: "/v2/email/dedicated-ip-pools",
    validator: validate_CreateDedicatedIpPool_602058, base: "/",
    url: url_CreateDedicatedIpPool_602059, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDedicatedIpPools_602042 = ref object of OpenApiRestCall_601389
proc url_ListDedicatedIpPools_602044(protocol: Scheme; host: string; base: string;
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

proc validate_ListDedicatedIpPools_602043(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List all of the dedicated IP pools that exist in your AWS account in the current Region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : A token returned from a previous call to <code>ListDedicatedIpPools</code> to indicate the position in the list of dedicated IP pools.
  ##   PageSize: JInt
  ##           : The number of results to show in a single call to <code>ListDedicatedIpPools</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  section = newJObject()
  var valid_602045 = query.getOrDefault("NextToken")
  valid_602045 = validateParameter(valid_602045, JString, required = false,
                                 default = nil)
  if valid_602045 != nil:
    section.add "NextToken", valid_602045
  var valid_602046 = query.getOrDefault("PageSize")
  valid_602046 = validateParameter(valid_602046, JInt, required = false, default = nil)
  if valid_602046 != nil:
    section.add "PageSize", valid_602046
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602047 = header.getOrDefault("X-Amz-Signature")
  valid_602047 = validateParameter(valid_602047, JString, required = false,
                                 default = nil)
  if valid_602047 != nil:
    section.add "X-Amz-Signature", valid_602047
  var valid_602048 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602048 = validateParameter(valid_602048, JString, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "X-Amz-Content-Sha256", valid_602048
  var valid_602049 = header.getOrDefault("X-Amz-Date")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "X-Amz-Date", valid_602049
  var valid_602050 = header.getOrDefault("X-Amz-Credential")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "X-Amz-Credential", valid_602050
  var valid_602051 = header.getOrDefault("X-Amz-Security-Token")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "X-Amz-Security-Token", valid_602051
  var valid_602052 = header.getOrDefault("X-Amz-Algorithm")
  valid_602052 = validateParameter(valid_602052, JString, required = false,
                                 default = nil)
  if valid_602052 != nil:
    section.add "X-Amz-Algorithm", valid_602052
  var valid_602053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602053 = validateParameter(valid_602053, JString, required = false,
                                 default = nil)
  if valid_602053 != nil:
    section.add "X-Amz-SignedHeaders", valid_602053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602054: Call_ListDedicatedIpPools_602042; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all of the dedicated IP pools that exist in your AWS account in the current Region.
  ## 
  let valid = call_602054.validator(path, query, header, formData, body)
  let scheme = call_602054.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602054.url(scheme.get, call_602054.host, call_602054.base,
                         call_602054.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602054, url, valid)

proc call*(call_602055: Call_ListDedicatedIpPools_602042; NextToken: string = "";
          PageSize: int = 0): Recallable =
  ## listDedicatedIpPools
  ## List all of the dedicated IP pools that exist in your AWS account in the current Region.
  ##   NextToken: string
  ##            : A token returned from a previous call to <code>ListDedicatedIpPools</code> to indicate the position in the list of dedicated IP pools.
  ##   PageSize: int
  ##           : The number of results to show in a single call to <code>ListDedicatedIpPools</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  var query_602056 = newJObject()
  add(query_602056, "NextToken", newJString(NextToken))
  add(query_602056, "PageSize", newJInt(PageSize))
  result = call_602055.call(nil, query_602056, nil, nil, nil)

var listDedicatedIpPools* = Call_ListDedicatedIpPools_602042(
    name: "listDedicatedIpPools", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v2/email/dedicated-ip-pools",
    validator: validate_ListDedicatedIpPools_602043, base: "/",
    url: url_ListDedicatedIpPools_602044, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeliverabilityTestReport_602071 = ref object of OpenApiRestCall_601389
proc url_CreateDeliverabilityTestReport_602073(protocol: Scheme; host: string;
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

proc validate_CreateDeliverabilityTestReport_602072(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Create a new predictive inbox placement test. Predictive inbox placement tests can help you predict how your messages will be handled by various email providers around the world. When you perform a predictive inbox placement test, you provide a sample message that contains the content that you plan to send to your customers. Amazon SES then sends that message to special email addresses spread across several major email providers. After about 24 hours, the test is complete, and you can use the <code>GetDeliverabilityTestReport</code> operation to view the results of the test.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602074 = header.getOrDefault("X-Amz-Signature")
  valid_602074 = validateParameter(valid_602074, JString, required = false,
                                 default = nil)
  if valid_602074 != nil:
    section.add "X-Amz-Signature", valid_602074
  var valid_602075 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602075 = validateParameter(valid_602075, JString, required = false,
                                 default = nil)
  if valid_602075 != nil:
    section.add "X-Amz-Content-Sha256", valid_602075
  var valid_602076 = header.getOrDefault("X-Amz-Date")
  valid_602076 = validateParameter(valid_602076, JString, required = false,
                                 default = nil)
  if valid_602076 != nil:
    section.add "X-Amz-Date", valid_602076
  var valid_602077 = header.getOrDefault("X-Amz-Credential")
  valid_602077 = validateParameter(valid_602077, JString, required = false,
                                 default = nil)
  if valid_602077 != nil:
    section.add "X-Amz-Credential", valid_602077
  var valid_602078 = header.getOrDefault("X-Amz-Security-Token")
  valid_602078 = validateParameter(valid_602078, JString, required = false,
                                 default = nil)
  if valid_602078 != nil:
    section.add "X-Amz-Security-Token", valid_602078
  var valid_602079 = header.getOrDefault("X-Amz-Algorithm")
  valid_602079 = validateParameter(valid_602079, JString, required = false,
                                 default = nil)
  if valid_602079 != nil:
    section.add "X-Amz-Algorithm", valid_602079
  var valid_602080 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602080 = validateParameter(valid_602080, JString, required = false,
                                 default = nil)
  if valid_602080 != nil:
    section.add "X-Amz-SignedHeaders", valid_602080
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602082: Call_CreateDeliverabilityTestReport_602071; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new predictive inbox placement test. Predictive inbox placement tests can help you predict how your messages will be handled by various email providers around the world. When you perform a predictive inbox placement test, you provide a sample message that contains the content that you plan to send to your customers. Amazon SES then sends that message to special email addresses spread across several major email providers. After about 24 hours, the test is complete, and you can use the <code>GetDeliverabilityTestReport</code> operation to view the results of the test.
  ## 
  let valid = call_602082.validator(path, query, header, formData, body)
  let scheme = call_602082.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602082.url(scheme.get, call_602082.host, call_602082.base,
                         call_602082.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602082, url, valid)

proc call*(call_602083: Call_CreateDeliverabilityTestReport_602071; body: JsonNode): Recallable =
  ## createDeliverabilityTestReport
  ## Create a new predictive inbox placement test. Predictive inbox placement tests can help you predict how your messages will be handled by various email providers around the world. When you perform a predictive inbox placement test, you provide a sample message that contains the content that you plan to send to your customers. Amazon SES then sends that message to special email addresses spread across several major email providers. After about 24 hours, the test is complete, and you can use the <code>GetDeliverabilityTestReport</code> operation to view the results of the test.
  ##   body: JObject (required)
  var body_602084 = newJObject()
  if body != nil:
    body_602084 = body
  result = call_602083.call(nil, nil, nil, nil, body_602084)

var createDeliverabilityTestReport* = Call_CreateDeliverabilityTestReport_602071(
    name: "createDeliverabilityTestReport", meth: HttpMethod.HttpPost,
    host: "email.amazonaws.com", route: "/v2/email/deliverability-dashboard/test",
    validator: validate_CreateDeliverabilityTestReport_602072, base: "/",
    url: url_CreateDeliverabilityTestReport_602073,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEmailIdentity_602100 = ref object of OpenApiRestCall_601389
proc url_CreateEmailIdentity_602102(protocol: Scheme; host: string; base: string;
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

proc validate_CreateEmailIdentity_602101(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Starts the process of verifying an email identity. An <i>identity</i> is an email address or domain that you use when you send email. Before you can use an identity to send email, you first have to verify it. By verifying an identity, you demonstrate that you're the owner of the identity, and that you've given Amazon SES API v2 permission to send email from the identity.</p> <p>When you verify an email address, Amazon SES sends an email to the address. Your email address is verified as soon as you follow the link in the verification email. </p> <p>When you verify a domain without specifying the <code>DkimSigningAttributes</code> object, this operation provides a set of DKIM tokens. You can convert these tokens into CNAME records, which you then add to the DNS configuration for your domain. Your domain is verified when Amazon SES detects these records in the DNS configuration for your domain. This verification method is known as <a href="https://docs.aws.amazon.com/ses/latest/DeveloperGuide/easy-dkim.html">Easy DKIM</a>.</p> <p>Alternatively, you can perform the verification process by providing your own public-private key pair. This verification method is known as Bring Your Own DKIM (BYODKIM). To use BYODKIM, your call to the <code>CreateEmailIdentity</code> operation has to include the <code>DkimSigningAttributes</code> object. When you specify this object, you provide a selector (a component of the DNS record name that identifies the public key that you want to use for DKIM authentication) and a private key.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602103 = header.getOrDefault("X-Amz-Signature")
  valid_602103 = validateParameter(valid_602103, JString, required = false,
                                 default = nil)
  if valid_602103 != nil:
    section.add "X-Amz-Signature", valid_602103
  var valid_602104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602104 = validateParameter(valid_602104, JString, required = false,
                                 default = nil)
  if valid_602104 != nil:
    section.add "X-Amz-Content-Sha256", valid_602104
  var valid_602105 = header.getOrDefault("X-Amz-Date")
  valid_602105 = validateParameter(valid_602105, JString, required = false,
                                 default = nil)
  if valid_602105 != nil:
    section.add "X-Amz-Date", valid_602105
  var valid_602106 = header.getOrDefault("X-Amz-Credential")
  valid_602106 = validateParameter(valid_602106, JString, required = false,
                                 default = nil)
  if valid_602106 != nil:
    section.add "X-Amz-Credential", valid_602106
  var valid_602107 = header.getOrDefault("X-Amz-Security-Token")
  valid_602107 = validateParameter(valid_602107, JString, required = false,
                                 default = nil)
  if valid_602107 != nil:
    section.add "X-Amz-Security-Token", valid_602107
  var valid_602108 = header.getOrDefault("X-Amz-Algorithm")
  valid_602108 = validateParameter(valid_602108, JString, required = false,
                                 default = nil)
  if valid_602108 != nil:
    section.add "X-Amz-Algorithm", valid_602108
  var valid_602109 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602109 = validateParameter(valid_602109, JString, required = false,
                                 default = nil)
  if valid_602109 != nil:
    section.add "X-Amz-SignedHeaders", valid_602109
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602111: Call_CreateEmailIdentity_602100; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts the process of verifying an email identity. An <i>identity</i> is an email address or domain that you use when you send email. Before you can use an identity to send email, you first have to verify it. By verifying an identity, you demonstrate that you're the owner of the identity, and that you've given Amazon SES API v2 permission to send email from the identity.</p> <p>When you verify an email address, Amazon SES sends an email to the address. Your email address is verified as soon as you follow the link in the verification email. </p> <p>When you verify a domain without specifying the <code>DkimSigningAttributes</code> object, this operation provides a set of DKIM tokens. You can convert these tokens into CNAME records, which you then add to the DNS configuration for your domain. Your domain is verified when Amazon SES detects these records in the DNS configuration for your domain. This verification method is known as <a href="https://docs.aws.amazon.com/ses/latest/DeveloperGuide/easy-dkim.html">Easy DKIM</a>.</p> <p>Alternatively, you can perform the verification process by providing your own public-private key pair. This verification method is known as Bring Your Own DKIM (BYODKIM). To use BYODKIM, your call to the <code>CreateEmailIdentity</code> operation has to include the <code>DkimSigningAttributes</code> object. When you specify this object, you provide a selector (a component of the DNS record name that identifies the public key that you want to use for DKIM authentication) and a private key.</p>
  ## 
  let valid = call_602111.validator(path, query, header, formData, body)
  let scheme = call_602111.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602111.url(scheme.get, call_602111.host, call_602111.base,
                         call_602111.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602111, url, valid)

proc call*(call_602112: Call_CreateEmailIdentity_602100; body: JsonNode): Recallable =
  ## createEmailIdentity
  ## <p>Starts the process of verifying an email identity. An <i>identity</i> is an email address or domain that you use when you send email. Before you can use an identity to send email, you first have to verify it. By verifying an identity, you demonstrate that you're the owner of the identity, and that you've given Amazon SES API v2 permission to send email from the identity.</p> <p>When you verify an email address, Amazon SES sends an email to the address. Your email address is verified as soon as you follow the link in the verification email. </p> <p>When you verify a domain without specifying the <code>DkimSigningAttributes</code> object, this operation provides a set of DKIM tokens. You can convert these tokens into CNAME records, which you then add to the DNS configuration for your domain. Your domain is verified when Amazon SES detects these records in the DNS configuration for your domain. This verification method is known as <a href="https://docs.aws.amazon.com/ses/latest/DeveloperGuide/easy-dkim.html">Easy DKIM</a>.</p> <p>Alternatively, you can perform the verification process by providing your own public-private key pair. This verification method is known as Bring Your Own DKIM (BYODKIM). To use BYODKIM, your call to the <code>CreateEmailIdentity</code> operation has to include the <code>DkimSigningAttributes</code> object. When you specify this object, you provide a selector (a component of the DNS record name that identifies the public key that you want to use for DKIM authentication) and a private key.</p>
  ##   body: JObject (required)
  var body_602113 = newJObject()
  if body != nil:
    body_602113 = body
  result = call_602112.call(nil, nil, nil, nil, body_602113)

var createEmailIdentity* = Call_CreateEmailIdentity_602100(
    name: "createEmailIdentity", meth: HttpMethod.HttpPost,
    host: "email.amazonaws.com", route: "/v2/email/identities",
    validator: validate_CreateEmailIdentity_602101, base: "/",
    url: url_CreateEmailIdentity_602102, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEmailIdentities_602085 = ref object of OpenApiRestCall_601389
proc url_ListEmailIdentities_602087(protocol: Scheme; host: string; base: string;
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

proc validate_ListEmailIdentities_602086(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns a list of all of the email identities that are associated with your AWS account. An identity can be either an email address or a domain. This operation returns identities that are verified as well as those that aren't. This operation returns identities that are associated with Amazon SES and Amazon Pinpoint.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : A token returned from a previous call to <code>ListEmailIdentities</code> to indicate the position in the list of identities.
  ##   PageSize: JInt
  ##           : <p>The number of results to show in a single call to <code>ListEmailIdentities</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.</p> <p>The value you specify has to be at least 0, and can be no more than 1000.</p>
  section = newJObject()
  var valid_602088 = query.getOrDefault("NextToken")
  valid_602088 = validateParameter(valid_602088, JString, required = false,
                                 default = nil)
  if valid_602088 != nil:
    section.add "NextToken", valid_602088
  var valid_602089 = query.getOrDefault("PageSize")
  valid_602089 = validateParameter(valid_602089, JInt, required = false, default = nil)
  if valid_602089 != nil:
    section.add "PageSize", valid_602089
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602090 = header.getOrDefault("X-Amz-Signature")
  valid_602090 = validateParameter(valid_602090, JString, required = false,
                                 default = nil)
  if valid_602090 != nil:
    section.add "X-Amz-Signature", valid_602090
  var valid_602091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "X-Amz-Content-Sha256", valid_602091
  var valid_602092 = header.getOrDefault("X-Amz-Date")
  valid_602092 = validateParameter(valid_602092, JString, required = false,
                                 default = nil)
  if valid_602092 != nil:
    section.add "X-Amz-Date", valid_602092
  var valid_602093 = header.getOrDefault("X-Amz-Credential")
  valid_602093 = validateParameter(valid_602093, JString, required = false,
                                 default = nil)
  if valid_602093 != nil:
    section.add "X-Amz-Credential", valid_602093
  var valid_602094 = header.getOrDefault("X-Amz-Security-Token")
  valid_602094 = validateParameter(valid_602094, JString, required = false,
                                 default = nil)
  if valid_602094 != nil:
    section.add "X-Amz-Security-Token", valid_602094
  var valid_602095 = header.getOrDefault("X-Amz-Algorithm")
  valid_602095 = validateParameter(valid_602095, JString, required = false,
                                 default = nil)
  if valid_602095 != nil:
    section.add "X-Amz-Algorithm", valid_602095
  var valid_602096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602096 = validateParameter(valid_602096, JString, required = false,
                                 default = nil)
  if valid_602096 != nil:
    section.add "X-Amz-SignedHeaders", valid_602096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602097: Call_ListEmailIdentities_602085; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all of the email identities that are associated with your AWS account. An identity can be either an email address or a domain. This operation returns identities that are verified as well as those that aren't. This operation returns identities that are associated with Amazon SES and Amazon Pinpoint.
  ## 
  let valid = call_602097.validator(path, query, header, formData, body)
  let scheme = call_602097.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602097.url(scheme.get, call_602097.host, call_602097.base,
                         call_602097.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602097, url, valid)

proc call*(call_602098: Call_ListEmailIdentities_602085; NextToken: string = "";
          PageSize: int = 0): Recallable =
  ## listEmailIdentities
  ## Returns a list of all of the email identities that are associated with your AWS account. An identity can be either an email address or a domain. This operation returns identities that are verified as well as those that aren't. This operation returns identities that are associated with Amazon SES and Amazon Pinpoint.
  ##   NextToken: string
  ##            : A token returned from a previous call to <code>ListEmailIdentities</code> to indicate the position in the list of identities.
  ##   PageSize: int
  ##           : <p>The number of results to show in a single call to <code>ListEmailIdentities</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.</p> <p>The value you specify has to be at least 0, and can be no more than 1000.</p>
  var query_602099 = newJObject()
  add(query_602099, "NextToken", newJString(NextToken))
  add(query_602099, "PageSize", newJInt(PageSize))
  result = call_602098.call(nil, query_602099, nil, nil, nil)

var listEmailIdentities* = Call_ListEmailIdentities_602085(
    name: "listEmailIdentities", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v2/email/identities",
    validator: validate_ListEmailIdentities_602086, base: "/",
    url: url_ListEmailIdentities_602087, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfigurationSet_602114 = ref object of OpenApiRestCall_601389
proc url_GetConfigurationSet_602116(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
        "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/email/configuration-sets/"),
               (kind: VariableSegment, value: "ConfigurationSetName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetConfigurationSet_602115(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Get information about an existing configuration set, including the dedicated IP pool that it's associated with, whether or not it's enabled for sending email, and more.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : <p>The name of a configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_602117 = path.getOrDefault("ConfigurationSetName")
  valid_602117 = validateParameter(valid_602117, JString, required = true,
                                 default = nil)
  if valid_602117 != nil:
    section.add "ConfigurationSetName", valid_602117
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602118 = header.getOrDefault("X-Amz-Signature")
  valid_602118 = validateParameter(valid_602118, JString, required = false,
                                 default = nil)
  if valid_602118 != nil:
    section.add "X-Amz-Signature", valid_602118
  var valid_602119 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602119 = validateParameter(valid_602119, JString, required = false,
                                 default = nil)
  if valid_602119 != nil:
    section.add "X-Amz-Content-Sha256", valid_602119
  var valid_602120 = header.getOrDefault("X-Amz-Date")
  valid_602120 = validateParameter(valid_602120, JString, required = false,
                                 default = nil)
  if valid_602120 != nil:
    section.add "X-Amz-Date", valid_602120
  var valid_602121 = header.getOrDefault("X-Amz-Credential")
  valid_602121 = validateParameter(valid_602121, JString, required = false,
                                 default = nil)
  if valid_602121 != nil:
    section.add "X-Amz-Credential", valid_602121
  var valid_602122 = header.getOrDefault("X-Amz-Security-Token")
  valid_602122 = validateParameter(valid_602122, JString, required = false,
                                 default = nil)
  if valid_602122 != nil:
    section.add "X-Amz-Security-Token", valid_602122
  var valid_602123 = header.getOrDefault("X-Amz-Algorithm")
  valid_602123 = validateParameter(valid_602123, JString, required = false,
                                 default = nil)
  if valid_602123 != nil:
    section.add "X-Amz-Algorithm", valid_602123
  var valid_602124 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "X-Amz-SignedHeaders", valid_602124
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602125: Call_GetConfigurationSet_602114; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Get information about an existing configuration set, including the dedicated IP pool that it's associated with, whether or not it's enabled for sending email, and more.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ## 
  let valid = call_602125.validator(path, query, header, formData, body)
  let scheme = call_602125.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602125.url(scheme.get, call_602125.host, call_602125.base,
                         call_602125.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602125, url, valid)

proc call*(call_602126: Call_GetConfigurationSet_602114;
          ConfigurationSetName: string): Recallable =
  ## getConfigurationSet
  ## <p>Get information about an existing configuration set, including the dedicated IP pool that it's associated with, whether or not it's enabled for sending email, and more.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  var path_602127 = newJObject()
  add(path_602127, "ConfigurationSetName", newJString(ConfigurationSetName))
  result = call_602126.call(path_602127, nil, nil, nil, nil)

var getConfigurationSet* = Call_GetConfigurationSet_602114(
    name: "getConfigurationSet", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com",
    route: "/v2/email/configuration-sets/{ConfigurationSetName}",
    validator: validate_GetConfigurationSet_602115, base: "/",
    url: url_GetConfigurationSet_602116, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfigurationSet_602128 = ref object of OpenApiRestCall_601389
proc url_DeleteConfigurationSet_602130(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
        "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/email/configuration-sets/"),
               (kind: VariableSegment, value: "ConfigurationSetName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteConfigurationSet_602129(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Delete an existing configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : <p>The name of a configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_602131 = path.getOrDefault("ConfigurationSetName")
  valid_602131 = validateParameter(valid_602131, JString, required = true,
                                 default = nil)
  if valid_602131 != nil:
    section.add "ConfigurationSetName", valid_602131
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602132 = header.getOrDefault("X-Amz-Signature")
  valid_602132 = validateParameter(valid_602132, JString, required = false,
                                 default = nil)
  if valid_602132 != nil:
    section.add "X-Amz-Signature", valid_602132
  var valid_602133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602133 = validateParameter(valid_602133, JString, required = false,
                                 default = nil)
  if valid_602133 != nil:
    section.add "X-Amz-Content-Sha256", valid_602133
  var valid_602134 = header.getOrDefault("X-Amz-Date")
  valid_602134 = validateParameter(valid_602134, JString, required = false,
                                 default = nil)
  if valid_602134 != nil:
    section.add "X-Amz-Date", valid_602134
  var valid_602135 = header.getOrDefault("X-Amz-Credential")
  valid_602135 = validateParameter(valid_602135, JString, required = false,
                                 default = nil)
  if valid_602135 != nil:
    section.add "X-Amz-Credential", valid_602135
  var valid_602136 = header.getOrDefault("X-Amz-Security-Token")
  valid_602136 = validateParameter(valid_602136, JString, required = false,
                                 default = nil)
  if valid_602136 != nil:
    section.add "X-Amz-Security-Token", valid_602136
  var valid_602137 = header.getOrDefault("X-Amz-Algorithm")
  valid_602137 = validateParameter(valid_602137, JString, required = false,
                                 default = nil)
  if valid_602137 != nil:
    section.add "X-Amz-Algorithm", valid_602137
  var valid_602138 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602138 = validateParameter(valid_602138, JString, required = false,
                                 default = nil)
  if valid_602138 != nil:
    section.add "X-Amz-SignedHeaders", valid_602138
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602139: Call_DeleteConfigurationSet_602128; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Delete an existing configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ## 
  let valid = call_602139.validator(path, query, header, formData, body)
  let scheme = call_602139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602139.url(scheme.get, call_602139.host, call_602139.base,
                         call_602139.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602139, url, valid)

proc call*(call_602140: Call_DeleteConfigurationSet_602128;
          ConfigurationSetName: string): Recallable =
  ## deleteConfigurationSet
  ## <p>Delete an existing configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  var path_602141 = newJObject()
  add(path_602141, "ConfigurationSetName", newJString(ConfigurationSetName))
  result = call_602140.call(path_602141, nil, nil, nil, nil)

var deleteConfigurationSet* = Call_DeleteConfigurationSet_602128(
    name: "deleteConfigurationSet", meth: HttpMethod.HttpDelete,
    host: "email.amazonaws.com",
    route: "/v2/email/configuration-sets/{ConfigurationSetName}",
    validator: validate_DeleteConfigurationSet_602129, base: "/",
    url: url_DeleteConfigurationSet_602130, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConfigurationSetEventDestination_602142 = ref object of OpenApiRestCall_601389
proc url_UpdateConfigurationSetEventDestination_602144(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
        "`ConfigurationSetName` is a required path parameter"
  assert "EventDestinationName" in path,
        "`EventDestinationName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/email/configuration-sets/"),
               (kind: VariableSegment, value: "ConfigurationSetName"),
               (kind: ConstantSegment, value: "/event-destinations/"),
               (kind: VariableSegment, value: "EventDestinationName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateConfigurationSetEventDestination_602143(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Update the configuration of an event destination for a configuration set.</p> <p> <i>Events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : <p>The name of a configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   EventDestinationName: JString (required)
  ##                       : <p>The name of an event destination.</p> <p> <i>Events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_602145 = path.getOrDefault("ConfigurationSetName")
  valid_602145 = validateParameter(valid_602145, JString, required = true,
                                 default = nil)
  if valid_602145 != nil:
    section.add "ConfigurationSetName", valid_602145
  var valid_602146 = path.getOrDefault("EventDestinationName")
  valid_602146 = validateParameter(valid_602146, JString, required = true,
                                 default = nil)
  if valid_602146 != nil:
    section.add "EventDestinationName", valid_602146
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602147 = header.getOrDefault("X-Amz-Signature")
  valid_602147 = validateParameter(valid_602147, JString, required = false,
                                 default = nil)
  if valid_602147 != nil:
    section.add "X-Amz-Signature", valid_602147
  var valid_602148 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602148 = validateParameter(valid_602148, JString, required = false,
                                 default = nil)
  if valid_602148 != nil:
    section.add "X-Amz-Content-Sha256", valid_602148
  var valid_602149 = header.getOrDefault("X-Amz-Date")
  valid_602149 = validateParameter(valid_602149, JString, required = false,
                                 default = nil)
  if valid_602149 != nil:
    section.add "X-Amz-Date", valid_602149
  var valid_602150 = header.getOrDefault("X-Amz-Credential")
  valid_602150 = validateParameter(valid_602150, JString, required = false,
                                 default = nil)
  if valid_602150 != nil:
    section.add "X-Amz-Credential", valid_602150
  var valid_602151 = header.getOrDefault("X-Amz-Security-Token")
  valid_602151 = validateParameter(valid_602151, JString, required = false,
                                 default = nil)
  if valid_602151 != nil:
    section.add "X-Amz-Security-Token", valid_602151
  var valid_602152 = header.getOrDefault("X-Amz-Algorithm")
  valid_602152 = validateParameter(valid_602152, JString, required = false,
                                 default = nil)
  if valid_602152 != nil:
    section.add "X-Amz-Algorithm", valid_602152
  var valid_602153 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602153 = validateParameter(valid_602153, JString, required = false,
                                 default = nil)
  if valid_602153 != nil:
    section.add "X-Amz-SignedHeaders", valid_602153
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602155: Call_UpdateConfigurationSetEventDestination_602142;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Update the configuration of an event destination for a configuration set.</p> <p> <i>Events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ## 
  let valid = call_602155.validator(path, query, header, formData, body)
  let scheme = call_602155.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602155.url(scheme.get, call_602155.host, call_602155.base,
                         call_602155.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602155, url, valid)

proc call*(call_602156: Call_UpdateConfigurationSetEventDestination_602142;
          ConfigurationSetName: string; EventDestinationName: string; body: JsonNode): Recallable =
  ## updateConfigurationSetEventDestination
  ## <p>Update the configuration of an event destination for a configuration set.</p> <p> <i>Events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   EventDestinationName: string (required)
  ##                       : <p>The name of an event destination.</p> <p> <i>Events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ##   body: JObject (required)
  var path_602157 = newJObject()
  var body_602158 = newJObject()
  add(path_602157, "ConfigurationSetName", newJString(ConfigurationSetName))
  add(path_602157, "EventDestinationName", newJString(EventDestinationName))
  if body != nil:
    body_602158 = body
  result = call_602156.call(path_602157, nil, nil, nil, body_602158)

var updateConfigurationSetEventDestination* = Call_UpdateConfigurationSetEventDestination_602142(
    name: "updateConfigurationSetEventDestination", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v2/email/configuration-sets/{ConfigurationSetName}/event-destinations/{EventDestinationName}",
    validator: validate_UpdateConfigurationSetEventDestination_602143, base: "/",
    url: url_UpdateConfigurationSetEventDestination_602144,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfigurationSetEventDestination_602159 = ref object of OpenApiRestCall_601389
proc url_DeleteConfigurationSetEventDestination_602161(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
        "`ConfigurationSetName` is a required path parameter"
  assert "EventDestinationName" in path,
        "`EventDestinationName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/email/configuration-sets/"),
               (kind: VariableSegment, value: "ConfigurationSetName"),
               (kind: ConstantSegment, value: "/event-destinations/"),
               (kind: VariableSegment, value: "EventDestinationName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteConfigurationSetEventDestination_602160(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Delete an event destination.</p> <p> <i>Events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : <p>The name of a configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   EventDestinationName: JString (required)
  ##                       : <p>The name of an event destination.</p> <p> <i>Events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_602162 = path.getOrDefault("ConfigurationSetName")
  valid_602162 = validateParameter(valid_602162, JString, required = true,
                                 default = nil)
  if valid_602162 != nil:
    section.add "ConfigurationSetName", valid_602162
  var valid_602163 = path.getOrDefault("EventDestinationName")
  valid_602163 = validateParameter(valid_602163, JString, required = true,
                                 default = nil)
  if valid_602163 != nil:
    section.add "EventDestinationName", valid_602163
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602164 = header.getOrDefault("X-Amz-Signature")
  valid_602164 = validateParameter(valid_602164, JString, required = false,
                                 default = nil)
  if valid_602164 != nil:
    section.add "X-Amz-Signature", valid_602164
  var valid_602165 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602165 = validateParameter(valid_602165, JString, required = false,
                                 default = nil)
  if valid_602165 != nil:
    section.add "X-Amz-Content-Sha256", valid_602165
  var valid_602166 = header.getOrDefault("X-Amz-Date")
  valid_602166 = validateParameter(valid_602166, JString, required = false,
                                 default = nil)
  if valid_602166 != nil:
    section.add "X-Amz-Date", valid_602166
  var valid_602167 = header.getOrDefault("X-Amz-Credential")
  valid_602167 = validateParameter(valid_602167, JString, required = false,
                                 default = nil)
  if valid_602167 != nil:
    section.add "X-Amz-Credential", valid_602167
  var valid_602168 = header.getOrDefault("X-Amz-Security-Token")
  valid_602168 = validateParameter(valid_602168, JString, required = false,
                                 default = nil)
  if valid_602168 != nil:
    section.add "X-Amz-Security-Token", valid_602168
  var valid_602169 = header.getOrDefault("X-Amz-Algorithm")
  valid_602169 = validateParameter(valid_602169, JString, required = false,
                                 default = nil)
  if valid_602169 != nil:
    section.add "X-Amz-Algorithm", valid_602169
  var valid_602170 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602170 = validateParameter(valid_602170, JString, required = false,
                                 default = nil)
  if valid_602170 != nil:
    section.add "X-Amz-SignedHeaders", valid_602170
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602171: Call_DeleteConfigurationSetEventDestination_602159;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Delete an event destination.</p> <p> <i>Events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ## 
  let valid = call_602171.validator(path, query, header, formData, body)
  let scheme = call_602171.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602171.url(scheme.get, call_602171.host, call_602171.base,
                         call_602171.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602171, url, valid)

proc call*(call_602172: Call_DeleteConfigurationSetEventDestination_602159;
          ConfigurationSetName: string; EventDestinationName: string): Recallable =
  ## deleteConfigurationSetEventDestination
  ## <p>Delete an event destination.</p> <p> <i>Events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   EventDestinationName: string (required)
  ##                       : <p>The name of an event destination.</p> <p> <i>Events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  var path_602173 = newJObject()
  add(path_602173, "ConfigurationSetName", newJString(ConfigurationSetName))
  add(path_602173, "EventDestinationName", newJString(EventDestinationName))
  result = call_602172.call(path_602173, nil, nil, nil, nil)

var deleteConfigurationSetEventDestination* = Call_DeleteConfigurationSetEventDestination_602159(
    name: "deleteConfigurationSetEventDestination", meth: HttpMethod.HttpDelete,
    host: "email.amazonaws.com", route: "/v2/email/configuration-sets/{ConfigurationSetName}/event-destinations/{EventDestinationName}",
    validator: validate_DeleteConfigurationSetEventDestination_602160, base: "/",
    url: url_DeleteConfigurationSetEventDestination_602161,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDedicatedIpPool_602174 = ref object of OpenApiRestCall_601389
proc url_DeleteDedicatedIpPool_602176(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "PoolName" in path, "`PoolName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/email/dedicated-ip-pools/"),
               (kind: VariableSegment, value: "PoolName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDedicatedIpPool_602175(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Delete a dedicated IP pool.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   PoolName: JString (required)
  ##           : The name of a dedicated IP pool.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `PoolName` field"
  var valid_602177 = path.getOrDefault("PoolName")
  valid_602177 = validateParameter(valid_602177, JString, required = true,
                                 default = nil)
  if valid_602177 != nil:
    section.add "PoolName", valid_602177
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602178 = header.getOrDefault("X-Amz-Signature")
  valid_602178 = validateParameter(valid_602178, JString, required = false,
                                 default = nil)
  if valid_602178 != nil:
    section.add "X-Amz-Signature", valid_602178
  var valid_602179 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602179 = validateParameter(valid_602179, JString, required = false,
                                 default = nil)
  if valid_602179 != nil:
    section.add "X-Amz-Content-Sha256", valid_602179
  var valid_602180 = header.getOrDefault("X-Amz-Date")
  valid_602180 = validateParameter(valid_602180, JString, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "X-Amz-Date", valid_602180
  var valid_602181 = header.getOrDefault("X-Amz-Credential")
  valid_602181 = validateParameter(valid_602181, JString, required = false,
                                 default = nil)
  if valid_602181 != nil:
    section.add "X-Amz-Credential", valid_602181
  var valid_602182 = header.getOrDefault("X-Amz-Security-Token")
  valid_602182 = validateParameter(valid_602182, JString, required = false,
                                 default = nil)
  if valid_602182 != nil:
    section.add "X-Amz-Security-Token", valid_602182
  var valid_602183 = header.getOrDefault("X-Amz-Algorithm")
  valid_602183 = validateParameter(valid_602183, JString, required = false,
                                 default = nil)
  if valid_602183 != nil:
    section.add "X-Amz-Algorithm", valid_602183
  var valid_602184 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602184 = validateParameter(valid_602184, JString, required = false,
                                 default = nil)
  if valid_602184 != nil:
    section.add "X-Amz-SignedHeaders", valid_602184
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602185: Call_DeleteDedicatedIpPool_602174; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a dedicated IP pool.
  ## 
  let valid = call_602185.validator(path, query, header, formData, body)
  let scheme = call_602185.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602185.url(scheme.get, call_602185.host, call_602185.base,
                         call_602185.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602185, url, valid)

proc call*(call_602186: Call_DeleteDedicatedIpPool_602174; PoolName: string): Recallable =
  ## deleteDedicatedIpPool
  ## Delete a dedicated IP pool.
  ##   PoolName: string (required)
  ##           : The name of a dedicated IP pool.
  var path_602187 = newJObject()
  add(path_602187, "PoolName", newJString(PoolName))
  result = call_602186.call(path_602187, nil, nil, nil, nil)

var deleteDedicatedIpPool* = Call_DeleteDedicatedIpPool_602174(
    name: "deleteDedicatedIpPool", meth: HttpMethod.HttpDelete,
    host: "email.amazonaws.com", route: "/v2/email/dedicated-ip-pools/{PoolName}",
    validator: validate_DeleteDedicatedIpPool_602175, base: "/",
    url: url_DeleteDedicatedIpPool_602176, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEmailIdentity_602188 = ref object of OpenApiRestCall_601389
proc url_GetEmailIdentity_602190(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "EmailIdentity" in path, "`EmailIdentity` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/email/identities/"),
               (kind: VariableSegment, value: "EmailIdentity")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetEmailIdentity_602189(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Provides information about a specific identity, including the identity's verification status, its DKIM authentication status, and its custom Mail-From settings.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   EmailIdentity: JString (required)
  ##                : The email identity that you want to retrieve details for.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `EmailIdentity` field"
  var valid_602191 = path.getOrDefault("EmailIdentity")
  valid_602191 = validateParameter(valid_602191, JString, required = true,
                                 default = nil)
  if valid_602191 != nil:
    section.add "EmailIdentity", valid_602191
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602192 = header.getOrDefault("X-Amz-Signature")
  valid_602192 = validateParameter(valid_602192, JString, required = false,
                                 default = nil)
  if valid_602192 != nil:
    section.add "X-Amz-Signature", valid_602192
  var valid_602193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602193 = validateParameter(valid_602193, JString, required = false,
                                 default = nil)
  if valid_602193 != nil:
    section.add "X-Amz-Content-Sha256", valid_602193
  var valid_602194 = header.getOrDefault("X-Amz-Date")
  valid_602194 = validateParameter(valid_602194, JString, required = false,
                                 default = nil)
  if valid_602194 != nil:
    section.add "X-Amz-Date", valid_602194
  var valid_602195 = header.getOrDefault("X-Amz-Credential")
  valid_602195 = validateParameter(valid_602195, JString, required = false,
                                 default = nil)
  if valid_602195 != nil:
    section.add "X-Amz-Credential", valid_602195
  var valid_602196 = header.getOrDefault("X-Amz-Security-Token")
  valid_602196 = validateParameter(valid_602196, JString, required = false,
                                 default = nil)
  if valid_602196 != nil:
    section.add "X-Amz-Security-Token", valid_602196
  var valid_602197 = header.getOrDefault("X-Amz-Algorithm")
  valid_602197 = validateParameter(valid_602197, JString, required = false,
                                 default = nil)
  if valid_602197 != nil:
    section.add "X-Amz-Algorithm", valid_602197
  var valid_602198 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602198 = validateParameter(valid_602198, JString, required = false,
                                 default = nil)
  if valid_602198 != nil:
    section.add "X-Amz-SignedHeaders", valid_602198
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602199: Call_GetEmailIdentity_602188; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information about a specific identity, including the identity's verification status, its DKIM authentication status, and its custom Mail-From settings.
  ## 
  let valid = call_602199.validator(path, query, header, formData, body)
  let scheme = call_602199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602199.url(scheme.get, call_602199.host, call_602199.base,
                         call_602199.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602199, url, valid)

proc call*(call_602200: Call_GetEmailIdentity_602188; EmailIdentity: string): Recallable =
  ## getEmailIdentity
  ## Provides information about a specific identity, including the identity's verification status, its DKIM authentication status, and its custom Mail-From settings.
  ##   EmailIdentity: string (required)
  ##                : The email identity that you want to retrieve details for.
  var path_602201 = newJObject()
  add(path_602201, "EmailIdentity", newJString(EmailIdentity))
  result = call_602200.call(path_602201, nil, nil, nil, nil)

var getEmailIdentity* = Call_GetEmailIdentity_602188(name: "getEmailIdentity",
    meth: HttpMethod.HttpGet, host: "email.amazonaws.com",
    route: "/v2/email/identities/{EmailIdentity}",
    validator: validate_GetEmailIdentity_602189, base: "/",
    url: url_GetEmailIdentity_602190, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEmailIdentity_602202 = ref object of OpenApiRestCall_601389
proc url_DeleteEmailIdentity_602204(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "EmailIdentity" in path, "`EmailIdentity` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/email/identities/"),
               (kind: VariableSegment, value: "EmailIdentity")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteEmailIdentity_602203(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Deletes an email identity. An identity can be either an email address or a domain name.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   EmailIdentity: JString (required)
  ##                : The identity (that is, the email address or domain) that you want to delete.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `EmailIdentity` field"
  var valid_602205 = path.getOrDefault("EmailIdentity")
  valid_602205 = validateParameter(valid_602205, JString, required = true,
                                 default = nil)
  if valid_602205 != nil:
    section.add "EmailIdentity", valid_602205
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602206 = header.getOrDefault("X-Amz-Signature")
  valid_602206 = validateParameter(valid_602206, JString, required = false,
                                 default = nil)
  if valid_602206 != nil:
    section.add "X-Amz-Signature", valid_602206
  var valid_602207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602207 = validateParameter(valid_602207, JString, required = false,
                                 default = nil)
  if valid_602207 != nil:
    section.add "X-Amz-Content-Sha256", valid_602207
  var valid_602208 = header.getOrDefault("X-Amz-Date")
  valid_602208 = validateParameter(valid_602208, JString, required = false,
                                 default = nil)
  if valid_602208 != nil:
    section.add "X-Amz-Date", valid_602208
  var valid_602209 = header.getOrDefault("X-Amz-Credential")
  valid_602209 = validateParameter(valid_602209, JString, required = false,
                                 default = nil)
  if valid_602209 != nil:
    section.add "X-Amz-Credential", valid_602209
  var valid_602210 = header.getOrDefault("X-Amz-Security-Token")
  valid_602210 = validateParameter(valid_602210, JString, required = false,
                                 default = nil)
  if valid_602210 != nil:
    section.add "X-Amz-Security-Token", valid_602210
  var valid_602211 = header.getOrDefault("X-Amz-Algorithm")
  valid_602211 = validateParameter(valid_602211, JString, required = false,
                                 default = nil)
  if valid_602211 != nil:
    section.add "X-Amz-Algorithm", valid_602211
  var valid_602212 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602212 = validateParameter(valid_602212, JString, required = false,
                                 default = nil)
  if valid_602212 != nil:
    section.add "X-Amz-SignedHeaders", valid_602212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602213: Call_DeleteEmailIdentity_602202; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an email identity. An identity can be either an email address or a domain name.
  ## 
  let valid = call_602213.validator(path, query, header, formData, body)
  let scheme = call_602213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602213.url(scheme.get, call_602213.host, call_602213.base,
                         call_602213.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602213, url, valid)

proc call*(call_602214: Call_DeleteEmailIdentity_602202; EmailIdentity: string): Recallable =
  ## deleteEmailIdentity
  ## Deletes an email identity. An identity can be either an email address or a domain name.
  ##   EmailIdentity: string (required)
  ##                : The identity (that is, the email address or domain) that you want to delete.
  var path_602215 = newJObject()
  add(path_602215, "EmailIdentity", newJString(EmailIdentity))
  result = call_602214.call(path_602215, nil, nil, nil, nil)

var deleteEmailIdentity* = Call_DeleteEmailIdentity_602202(
    name: "deleteEmailIdentity", meth: HttpMethod.HttpDelete,
    host: "email.amazonaws.com", route: "/v2/email/identities/{EmailIdentity}",
    validator: validate_DeleteEmailIdentity_602203, base: "/",
    url: url_DeleteEmailIdentity_602204, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSuppressedDestination_602216 = ref object of OpenApiRestCall_601389
proc url_GetSuppressedDestination_602218(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "EmailAddress" in path, "`EmailAddress` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/email/suppression/addresses/"),
               (kind: VariableSegment, value: "EmailAddress")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSuppressedDestination_602217(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves information about a specific email address that's on the suppression list for your account.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   EmailAddress: JString (required)
  ##               : The email address that's on the account suppression list.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `EmailAddress` field"
  var valid_602219 = path.getOrDefault("EmailAddress")
  valid_602219 = validateParameter(valid_602219, JString, required = true,
                                 default = nil)
  if valid_602219 != nil:
    section.add "EmailAddress", valid_602219
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602220 = header.getOrDefault("X-Amz-Signature")
  valid_602220 = validateParameter(valid_602220, JString, required = false,
                                 default = nil)
  if valid_602220 != nil:
    section.add "X-Amz-Signature", valid_602220
  var valid_602221 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602221 = validateParameter(valid_602221, JString, required = false,
                                 default = nil)
  if valid_602221 != nil:
    section.add "X-Amz-Content-Sha256", valid_602221
  var valid_602222 = header.getOrDefault("X-Amz-Date")
  valid_602222 = validateParameter(valid_602222, JString, required = false,
                                 default = nil)
  if valid_602222 != nil:
    section.add "X-Amz-Date", valid_602222
  var valid_602223 = header.getOrDefault("X-Amz-Credential")
  valid_602223 = validateParameter(valid_602223, JString, required = false,
                                 default = nil)
  if valid_602223 != nil:
    section.add "X-Amz-Credential", valid_602223
  var valid_602224 = header.getOrDefault("X-Amz-Security-Token")
  valid_602224 = validateParameter(valid_602224, JString, required = false,
                                 default = nil)
  if valid_602224 != nil:
    section.add "X-Amz-Security-Token", valid_602224
  var valid_602225 = header.getOrDefault("X-Amz-Algorithm")
  valid_602225 = validateParameter(valid_602225, JString, required = false,
                                 default = nil)
  if valid_602225 != nil:
    section.add "X-Amz-Algorithm", valid_602225
  var valid_602226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602226 = validateParameter(valid_602226, JString, required = false,
                                 default = nil)
  if valid_602226 != nil:
    section.add "X-Amz-SignedHeaders", valid_602226
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602227: Call_GetSuppressedDestination_602216; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about a specific email address that's on the suppression list for your account.
  ## 
  let valid = call_602227.validator(path, query, header, formData, body)
  let scheme = call_602227.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602227.url(scheme.get, call_602227.host, call_602227.base,
                         call_602227.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602227, url, valid)

proc call*(call_602228: Call_GetSuppressedDestination_602216; EmailAddress: string): Recallable =
  ## getSuppressedDestination
  ## Retrieves information about a specific email address that's on the suppression list for your account.
  ##   EmailAddress: string (required)
  ##               : The email address that's on the account suppression list.
  var path_602229 = newJObject()
  add(path_602229, "EmailAddress", newJString(EmailAddress))
  result = call_602228.call(path_602229, nil, nil, nil, nil)

var getSuppressedDestination* = Call_GetSuppressedDestination_602216(
    name: "getSuppressedDestination", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com",
    route: "/v2/email/suppression/addresses/{EmailAddress}",
    validator: validate_GetSuppressedDestination_602217, base: "/",
    url: url_GetSuppressedDestination_602218, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSuppressedDestination_602230 = ref object of OpenApiRestCall_601389
proc url_DeleteSuppressedDestination_602232(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "EmailAddress" in path, "`EmailAddress` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/email/suppression/addresses/"),
               (kind: VariableSegment, value: "EmailAddress")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteSuppressedDestination_602231(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes an email address from the suppression list for your account.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   EmailAddress: JString (required)
  ##               : The suppressed email destination to remove from the account suppression list.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `EmailAddress` field"
  var valid_602233 = path.getOrDefault("EmailAddress")
  valid_602233 = validateParameter(valid_602233, JString, required = true,
                                 default = nil)
  if valid_602233 != nil:
    section.add "EmailAddress", valid_602233
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602234 = header.getOrDefault("X-Amz-Signature")
  valid_602234 = validateParameter(valid_602234, JString, required = false,
                                 default = nil)
  if valid_602234 != nil:
    section.add "X-Amz-Signature", valid_602234
  var valid_602235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602235 = validateParameter(valid_602235, JString, required = false,
                                 default = nil)
  if valid_602235 != nil:
    section.add "X-Amz-Content-Sha256", valid_602235
  var valid_602236 = header.getOrDefault("X-Amz-Date")
  valid_602236 = validateParameter(valid_602236, JString, required = false,
                                 default = nil)
  if valid_602236 != nil:
    section.add "X-Amz-Date", valid_602236
  var valid_602237 = header.getOrDefault("X-Amz-Credential")
  valid_602237 = validateParameter(valid_602237, JString, required = false,
                                 default = nil)
  if valid_602237 != nil:
    section.add "X-Amz-Credential", valid_602237
  var valid_602238 = header.getOrDefault("X-Amz-Security-Token")
  valid_602238 = validateParameter(valid_602238, JString, required = false,
                                 default = nil)
  if valid_602238 != nil:
    section.add "X-Amz-Security-Token", valid_602238
  var valid_602239 = header.getOrDefault("X-Amz-Algorithm")
  valid_602239 = validateParameter(valid_602239, JString, required = false,
                                 default = nil)
  if valid_602239 != nil:
    section.add "X-Amz-Algorithm", valid_602239
  var valid_602240 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602240 = validateParameter(valid_602240, JString, required = false,
                                 default = nil)
  if valid_602240 != nil:
    section.add "X-Amz-SignedHeaders", valid_602240
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602241: Call_DeleteSuppressedDestination_602230; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an email address from the suppression list for your account.
  ## 
  let valid = call_602241.validator(path, query, header, formData, body)
  let scheme = call_602241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602241.url(scheme.get, call_602241.host, call_602241.base,
                         call_602241.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602241, url, valid)

proc call*(call_602242: Call_DeleteSuppressedDestination_602230;
          EmailAddress: string): Recallable =
  ## deleteSuppressedDestination
  ## Removes an email address from the suppression list for your account.
  ##   EmailAddress: string (required)
  ##               : The suppressed email destination to remove from the account suppression list.
  var path_602243 = newJObject()
  add(path_602243, "EmailAddress", newJString(EmailAddress))
  result = call_602242.call(path_602243, nil, nil, nil, nil)

var deleteSuppressedDestination* = Call_DeleteSuppressedDestination_602230(
    name: "deleteSuppressedDestination", meth: HttpMethod.HttpDelete,
    host: "email.amazonaws.com",
    route: "/v2/email/suppression/addresses/{EmailAddress}",
    validator: validate_DeleteSuppressedDestination_602231, base: "/",
    url: url_DeleteSuppressedDestination_602232,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccount_602244 = ref object of OpenApiRestCall_601389
proc url_GetAccount_602246(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAccount_602245(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Obtain information about the email-sending status and capabilities of your Amazon SES account in the current AWS Region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602247 = header.getOrDefault("X-Amz-Signature")
  valid_602247 = validateParameter(valid_602247, JString, required = false,
                                 default = nil)
  if valid_602247 != nil:
    section.add "X-Amz-Signature", valid_602247
  var valid_602248 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602248 = validateParameter(valid_602248, JString, required = false,
                                 default = nil)
  if valid_602248 != nil:
    section.add "X-Amz-Content-Sha256", valid_602248
  var valid_602249 = header.getOrDefault("X-Amz-Date")
  valid_602249 = validateParameter(valid_602249, JString, required = false,
                                 default = nil)
  if valid_602249 != nil:
    section.add "X-Amz-Date", valid_602249
  var valid_602250 = header.getOrDefault("X-Amz-Credential")
  valid_602250 = validateParameter(valid_602250, JString, required = false,
                                 default = nil)
  if valid_602250 != nil:
    section.add "X-Amz-Credential", valid_602250
  var valid_602251 = header.getOrDefault("X-Amz-Security-Token")
  valid_602251 = validateParameter(valid_602251, JString, required = false,
                                 default = nil)
  if valid_602251 != nil:
    section.add "X-Amz-Security-Token", valid_602251
  var valid_602252 = header.getOrDefault("X-Amz-Algorithm")
  valid_602252 = validateParameter(valid_602252, JString, required = false,
                                 default = nil)
  if valid_602252 != nil:
    section.add "X-Amz-Algorithm", valid_602252
  var valid_602253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602253 = validateParameter(valid_602253, JString, required = false,
                                 default = nil)
  if valid_602253 != nil:
    section.add "X-Amz-SignedHeaders", valid_602253
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602254: Call_GetAccount_602244; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Obtain information about the email-sending status and capabilities of your Amazon SES account in the current AWS Region.
  ## 
  let valid = call_602254.validator(path, query, header, formData, body)
  let scheme = call_602254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602254.url(scheme.get, call_602254.host, call_602254.base,
                         call_602254.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602254, url, valid)

proc call*(call_602255: Call_GetAccount_602244): Recallable =
  ## getAccount
  ## Obtain information about the email-sending status and capabilities of your Amazon SES account in the current AWS Region.
  result = call_602255.call(nil, nil, nil, nil, nil)

var getAccount* = Call_GetAccount_602244(name: "getAccount",
                                      meth: HttpMethod.HttpGet,
                                      host: "email.amazonaws.com",
                                      route: "/v2/email/account",
                                      validator: validate_GetAccount_602245,
                                      base: "/", url: url_GetAccount_602246,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBlacklistReports_602256 = ref object of OpenApiRestCall_601389
proc url_GetBlacklistReports_602258(protocol: Scheme; host: string; base: string;
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

proc validate_GetBlacklistReports_602257(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Retrieve a list of the blacklists that your dedicated IP addresses appear on.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   BlacklistItemNames: JArray (required)
  ##                     : A list of IP addresses that you want to retrieve blacklist information about. You can only specify the dedicated IP addresses that you use to send email using Amazon SES or Amazon Pinpoint.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `BlacklistItemNames` field"
  var valid_602259 = query.getOrDefault("BlacklistItemNames")
  valid_602259 = validateParameter(valid_602259, JArray, required = true, default = nil)
  if valid_602259 != nil:
    section.add "BlacklistItemNames", valid_602259
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602260 = header.getOrDefault("X-Amz-Signature")
  valid_602260 = validateParameter(valid_602260, JString, required = false,
                                 default = nil)
  if valid_602260 != nil:
    section.add "X-Amz-Signature", valid_602260
  var valid_602261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602261 = validateParameter(valid_602261, JString, required = false,
                                 default = nil)
  if valid_602261 != nil:
    section.add "X-Amz-Content-Sha256", valid_602261
  var valid_602262 = header.getOrDefault("X-Amz-Date")
  valid_602262 = validateParameter(valid_602262, JString, required = false,
                                 default = nil)
  if valid_602262 != nil:
    section.add "X-Amz-Date", valid_602262
  var valid_602263 = header.getOrDefault("X-Amz-Credential")
  valid_602263 = validateParameter(valid_602263, JString, required = false,
                                 default = nil)
  if valid_602263 != nil:
    section.add "X-Amz-Credential", valid_602263
  var valid_602264 = header.getOrDefault("X-Amz-Security-Token")
  valid_602264 = validateParameter(valid_602264, JString, required = false,
                                 default = nil)
  if valid_602264 != nil:
    section.add "X-Amz-Security-Token", valid_602264
  var valid_602265 = header.getOrDefault("X-Amz-Algorithm")
  valid_602265 = validateParameter(valid_602265, JString, required = false,
                                 default = nil)
  if valid_602265 != nil:
    section.add "X-Amz-Algorithm", valid_602265
  var valid_602266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602266 = validateParameter(valid_602266, JString, required = false,
                                 default = nil)
  if valid_602266 != nil:
    section.add "X-Amz-SignedHeaders", valid_602266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602267: Call_GetBlacklistReports_602256; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a list of the blacklists that your dedicated IP addresses appear on.
  ## 
  let valid = call_602267.validator(path, query, header, formData, body)
  let scheme = call_602267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602267.url(scheme.get, call_602267.host, call_602267.base,
                         call_602267.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602267, url, valid)

proc call*(call_602268: Call_GetBlacklistReports_602256;
          BlacklistItemNames: JsonNode): Recallable =
  ## getBlacklistReports
  ## Retrieve a list of the blacklists that your dedicated IP addresses appear on.
  ##   BlacklistItemNames: JArray (required)
  ##                     : A list of IP addresses that you want to retrieve blacklist information about. You can only specify the dedicated IP addresses that you use to send email using Amazon SES or Amazon Pinpoint.
  var query_602269 = newJObject()
  if BlacklistItemNames != nil:
    query_602269.add "BlacklistItemNames", BlacklistItemNames
  result = call_602268.call(nil, query_602269, nil, nil, nil)

var getBlacklistReports* = Call_GetBlacklistReports_602256(
    name: "getBlacklistReports", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v2/email/deliverability-dashboard/blacklist-report#BlacklistItemNames",
    validator: validate_GetBlacklistReports_602257, base: "/",
    url: url_GetBlacklistReports_602258, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDedicatedIp_602270 = ref object of OpenApiRestCall_601389
proc url_GetDedicatedIp_602272(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "IP" in path, "`IP` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/email/dedicated-ips/"),
               (kind: VariableSegment, value: "IP")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDedicatedIp_602271(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Get information about a dedicated IP address, including the name of the dedicated IP pool that it's associated with, as well information about the automatic warm-up process for the address.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   IP: JString (required)
  ##     : An IPv4 address.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `IP` field"
  var valid_602273 = path.getOrDefault("IP")
  valid_602273 = validateParameter(valid_602273, JString, required = true,
                                 default = nil)
  if valid_602273 != nil:
    section.add "IP", valid_602273
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602274 = header.getOrDefault("X-Amz-Signature")
  valid_602274 = validateParameter(valid_602274, JString, required = false,
                                 default = nil)
  if valid_602274 != nil:
    section.add "X-Amz-Signature", valid_602274
  var valid_602275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602275 = validateParameter(valid_602275, JString, required = false,
                                 default = nil)
  if valid_602275 != nil:
    section.add "X-Amz-Content-Sha256", valid_602275
  var valid_602276 = header.getOrDefault("X-Amz-Date")
  valid_602276 = validateParameter(valid_602276, JString, required = false,
                                 default = nil)
  if valid_602276 != nil:
    section.add "X-Amz-Date", valid_602276
  var valid_602277 = header.getOrDefault("X-Amz-Credential")
  valid_602277 = validateParameter(valid_602277, JString, required = false,
                                 default = nil)
  if valid_602277 != nil:
    section.add "X-Amz-Credential", valid_602277
  var valid_602278 = header.getOrDefault("X-Amz-Security-Token")
  valid_602278 = validateParameter(valid_602278, JString, required = false,
                                 default = nil)
  if valid_602278 != nil:
    section.add "X-Amz-Security-Token", valid_602278
  var valid_602279 = header.getOrDefault("X-Amz-Algorithm")
  valid_602279 = validateParameter(valid_602279, JString, required = false,
                                 default = nil)
  if valid_602279 != nil:
    section.add "X-Amz-Algorithm", valid_602279
  var valid_602280 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602280 = validateParameter(valid_602280, JString, required = false,
                                 default = nil)
  if valid_602280 != nil:
    section.add "X-Amz-SignedHeaders", valid_602280
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602281: Call_GetDedicatedIp_602270; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get information about a dedicated IP address, including the name of the dedicated IP pool that it's associated with, as well information about the automatic warm-up process for the address.
  ## 
  let valid = call_602281.validator(path, query, header, formData, body)
  let scheme = call_602281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602281.url(scheme.get, call_602281.host, call_602281.base,
                         call_602281.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602281, url, valid)

proc call*(call_602282: Call_GetDedicatedIp_602270; IP: string): Recallable =
  ## getDedicatedIp
  ## Get information about a dedicated IP address, including the name of the dedicated IP pool that it's associated with, as well information about the automatic warm-up process for the address.
  ##   IP: string (required)
  ##     : An IPv4 address.
  var path_602283 = newJObject()
  add(path_602283, "IP", newJString(IP))
  result = call_602282.call(path_602283, nil, nil, nil, nil)

var getDedicatedIp* = Call_GetDedicatedIp_602270(name: "getDedicatedIp",
    meth: HttpMethod.HttpGet, host: "email.amazonaws.com",
    route: "/v2/email/dedicated-ips/{IP}", validator: validate_GetDedicatedIp_602271,
    base: "/", url: url_GetDedicatedIp_602272, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDedicatedIps_602284 = ref object of OpenApiRestCall_601389
proc url_GetDedicatedIps_602286(protocol: Scheme; host: string; base: string;
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

proc validate_GetDedicatedIps_602285(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## List the dedicated IP addresses that are associated with your AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : A token returned from a previous call to <code>GetDedicatedIps</code> to indicate the position of the dedicated IP pool in the list of IP pools.
  ##   PageSize: JInt
  ##           : The number of results to show in a single call to <code>GetDedicatedIpsRequest</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  ##   PoolName: JString
  ##           : The name of a dedicated IP pool.
  section = newJObject()
  var valid_602287 = query.getOrDefault("NextToken")
  valid_602287 = validateParameter(valid_602287, JString, required = false,
                                 default = nil)
  if valid_602287 != nil:
    section.add "NextToken", valid_602287
  var valid_602288 = query.getOrDefault("PageSize")
  valid_602288 = validateParameter(valid_602288, JInt, required = false, default = nil)
  if valid_602288 != nil:
    section.add "PageSize", valid_602288
  var valid_602289 = query.getOrDefault("PoolName")
  valid_602289 = validateParameter(valid_602289, JString, required = false,
                                 default = nil)
  if valid_602289 != nil:
    section.add "PoolName", valid_602289
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602290 = header.getOrDefault("X-Amz-Signature")
  valid_602290 = validateParameter(valid_602290, JString, required = false,
                                 default = nil)
  if valid_602290 != nil:
    section.add "X-Amz-Signature", valid_602290
  var valid_602291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602291 = validateParameter(valid_602291, JString, required = false,
                                 default = nil)
  if valid_602291 != nil:
    section.add "X-Amz-Content-Sha256", valid_602291
  var valid_602292 = header.getOrDefault("X-Amz-Date")
  valid_602292 = validateParameter(valid_602292, JString, required = false,
                                 default = nil)
  if valid_602292 != nil:
    section.add "X-Amz-Date", valid_602292
  var valid_602293 = header.getOrDefault("X-Amz-Credential")
  valid_602293 = validateParameter(valid_602293, JString, required = false,
                                 default = nil)
  if valid_602293 != nil:
    section.add "X-Amz-Credential", valid_602293
  var valid_602294 = header.getOrDefault("X-Amz-Security-Token")
  valid_602294 = validateParameter(valid_602294, JString, required = false,
                                 default = nil)
  if valid_602294 != nil:
    section.add "X-Amz-Security-Token", valid_602294
  var valid_602295 = header.getOrDefault("X-Amz-Algorithm")
  valid_602295 = validateParameter(valid_602295, JString, required = false,
                                 default = nil)
  if valid_602295 != nil:
    section.add "X-Amz-Algorithm", valid_602295
  var valid_602296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602296 = validateParameter(valid_602296, JString, required = false,
                                 default = nil)
  if valid_602296 != nil:
    section.add "X-Amz-SignedHeaders", valid_602296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602297: Call_GetDedicatedIps_602284; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the dedicated IP addresses that are associated with your AWS account.
  ## 
  let valid = call_602297.validator(path, query, header, formData, body)
  let scheme = call_602297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602297.url(scheme.get, call_602297.host, call_602297.base,
                         call_602297.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602297, url, valid)

proc call*(call_602298: Call_GetDedicatedIps_602284; NextToken: string = "";
          PageSize: int = 0; PoolName: string = ""): Recallable =
  ## getDedicatedIps
  ## List the dedicated IP addresses that are associated with your AWS account.
  ##   NextToken: string
  ##            : A token returned from a previous call to <code>GetDedicatedIps</code> to indicate the position of the dedicated IP pool in the list of IP pools.
  ##   PageSize: int
  ##           : The number of results to show in a single call to <code>GetDedicatedIpsRequest</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  ##   PoolName: string
  ##           : The name of a dedicated IP pool.
  var query_602299 = newJObject()
  add(query_602299, "NextToken", newJString(NextToken))
  add(query_602299, "PageSize", newJInt(PageSize))
  add(query_602299, "PoolName", newJString(PoolName))
  result = call_602298.call(nil, query_602299, nil, nil, nil)

var getDedicatedIps* = Call_GetDedicatedIps_602284(name: "getDedicatedIps",
    meth: HttpMethod.HttpGet, host: "email.amazonaws.com",
    route: "/v2/email/dedicated-ips", validator: validate_GetDedicatedIps_602285,
    base: "/", url: url_GetDedicatedIps_602286, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDeliverabilityDashboardOption_602312 = ref object of OpenApiRestCall_601389
proc url_PutDeliverabilityDashboardOption_602314(protocol: Scheme; host: string;
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

proc validate_PutDeliverabilityDashboardOption_602313(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Enable or disable the Deliverability dashboard. When you enable the Deliverability dashboard, you gain access to reputation, deliverability, and other metrics for the domains that you use to send email. You also gain the ability to perform predictive inbox placement tests.</p> <p>When you use the Deliverability dashboard, you pay a monthly subscription charge, in addition to any other fees that you accrue by using Amazon SES and other AWS services. For more information about the features and cost of a Deliverability dashboard subscription, see <a href="http://aws.amazon.com/ses/pricing/">Amazon SES Pricing</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
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
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602323: Call_PutDeliverabilityDashboardOption_602312;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Enable or disable the Deliverability dashboard. When you enable the Deliverability dashboard, you gain access to reputation, deliverability, and other metrics for the domains that you use to send email. You also gain the ability to perform predictive inbox placement tests.</p> <p>When you use the Deliverability dashboard, you pay a monthly subscription charge, in addition to any other fees that you accrue by using Amazon SES and other AWS services. For more information about the features and cost of a Deliverability dashboard subscription, see <a href="http://aws.amazon.com/ses/pricing/">Amazon SES Pricing</a>.</p>
  ## 
  let valid = call_602323.validator(path, query, header, formData, body)
  let scheme = call_602323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602323.url(scheme.get, call_602323.host, call_602323.base,
                         call_602323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602323, url, valid)

proc call*(call_602324: Call_PutDeliverabilityDashboardOption_602312;
          body: JsonNode): Recallable =
  ## putDeliverabilityDashboardOption
  ## <p>Enable or disable the Deliverability dashboard. When you enable the Deliverability dashboard, you gain access to reputation, deliverability, and other metrics for the domains that you use to send email. You also gain the ability to perform predictive inbox placement tests.</p> <p>When you use the Deliverability dashboard, you pay a monthly subscription charge, in addition to any other fees that you accrue by using Amazon SES and other AWS services. For more information about the features and cost of a Deliverability dashboard subscription, see <a href="http://aws.amazon.com/ses/pricing/">Amazon SES Pricing</a>.</p>
  ##   body: JObject (required)
  var body_602325 = newJObject()
  if body != nil:
    body_602325 = body
  result = call_602324.call(nil, nil, nil, nil, body_602325)

var putDeliverabilityDashboardOption* = Call_PutDeliverabilityDashboardOption_602312(
    name: "putDeliverabilityDashboardOption", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v2/email/deliverability-dashboard",
    validator: validate_PutDeliverabilityDashboardOption_602313, base: "/",
    url: url_PutDeliverabilityDashboardOption_602314,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeliverabilityDashboardOptions_602300 = ref object of OpenApiRestCall_601389
proc url_GetDeliverabilityDashboardOptions_602302(protocol: Scheme; host: string;
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

proc validate_GetDeliverabilityDashboardOptions_602301(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieve information about the status of the Deliverability dashboard for your account. When the Deliverability dashboard is enabled, you gain access to reputation, deliverability, and other metrics for the domains that you use to send email. You also gain the ability to perform predictive inbox placement tests.</p> <p>When you use the Deliverability dashboard, you pay a monthly subscription charge, in addition to any other fees that you accrue by using Amazon SES and other AWS services. For more information about the features and cost of a Deliverability dashboard subscription, see <a href="http://aws.amazon.com/ses/pricing/">Amazon SES Pricing</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602303 = header.getOrDefault("X-Amz-Signature")
  valid_602303 = validateParameter(valid_602303, JString, required = false,
                                 default = nil)
  if valid_602303 != nil:
    section.add "X-Amz-Signature", valid_602303
  var valid_602304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602304 = validateParameter(valid_602304, JString, required = false,
                                 default = nil)
  if valid_602304 != nil:
    section.add "X-Amz-Content-Sha256", valid_602304
  var valid_602305 = header.getOrDefault("X-Amz-Date")
  valid_602305 = validateParameter(valid_602305, JString, required = false,
                                 default = nil)
  if valid_602305 != nil:
    section.add "X-Amz-Date", valid_602305
  var valid_602306 = header.getOrDefault("X-Amz-Credential")
  valid_602306 = validateParameter(valid_602306, JString, required = false,
                                 default = nil)
  if valid_602306 != nil:
    section.add "X-Amz-Credential", valid_602306
  var valid_602307 = header.getOrDefault("X-Amz-Security-Token")
  valid_602307 = validateParameter(valid_602307, JString, required = false,
                                 default = nil)
  if valid_602307 != nil:
    section.add "X-Amz-Security-Token", valid_602307
  var valid_602308 = header.getOrDefault("X-Amz-Algorithm")
  valid_602308 = validateParameter(valid_602308, JString, required = false,
                                 default = nil)
  if valid_602308 != nil:
    section.add "X-Amz-Algorithm", valid_602308
  var valid_602309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602309 = validateParameter(valid_602309, JString, required = false,
                                 default = nil)
  if valid_602309 != nil:
    section.add "X-Amz-SignedHeaders", valid_602309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602310: Call_GetDeliverabilityDashboardOptions_602300;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Retrieve information about the status of the Deliverability dashboard for your account. When the Deliverability dashboard is enabled, you gain access to reputation, deliverability, and other metrics for the domains that you use to send email. You also gain the ability to perform predictive inbox placement tests.</p> <p>When you use the Deliverability dashboard, you pay a monthly subscription charge, in addition to any other fees that you accrue by using Amazon SES and other AWS services. For more information about the features and cost of a Deliverability dashboard subscription, see <a href="http://aws.amazon.com/ses/pricing/">Amazon SES Pricing</a>.</p>
  ## 
  let valid = call_602310.validator(path, query, header, formData, body)
  let scheme = call_602310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602310.url(scheme.get, call_602310.host, call_602310.base,
                         call_602310.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602310, url, valid)

proc call*(call_602311: Call_GetDeliverabilityDashboardOptions_602300): Recallable =
  ## getDeliverabilityDashboardOptions
  ## <p>Retrieve information about the status of the Deliverability dashboard for your account. When the Deliverability dashboard is enabled, you gain access to reputation, deliverability, and other metrics for the domains that you use to send email. You also gain the ability to perform predictive inbox placement tests.</p> <p>When you use the Deliverability dashboard, you pay a monthly subscription charge, in addition to any other fees that you accrue by using Amazon SES and other AWS services. For more information about the features and cost of a Deliverability dashboard subscription, see <a href="http://aws.amazon.com/ses/pricing/">Amazon SES Pricing</a>.</p>
  result = call_602311.call(nil, nil, nil, nil, nil)

var getDeliverabilityDashboardOptions* = Call_GetDeliverabilityDashboardOptions_602300(
    name: "getDeliverabilityDashboardOptions", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v2/email/deliverability-dashboard",
    validator: validate_GetDeliverabilityDashboardOptions_602301, base: "/",
    url: url_GetDeliverabilityDashboardOptions_602302,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeliverabilityTestReport_602326 = ref object of OpenApiRestCall_601389
proc url_GetDeliverabilityTestReport_602328(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ReportId" in path, "`ReportId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/v2/email/deliverability-dashboard/test-reports/"),
               (kind: VariableSegment, value: "ReportId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDeliverabilityTestReport_602327(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieve the results of a predictive inbox placement test.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ReportId: JString (required)
  ##           : A unique string that identifies a Deliverability dashboard report.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ReportId` field"
  var valid_602329 = path.getOrDefault("ReportId")
  valid_602329 = validateParameter(valid_602329, JString, required = true,
                                 default = nil)
  if valid_602329 != nil:
    section.add "ReportId", valid_602329
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602330 = header.getOrDefault("X-Amz-Signature")
  valid_602330 = validateParameter(valid_602330, JString, required = false,
                                 default = nil)
  if valid_602330 != nil:
    section.add "X-Amz-Signature", valid_602330
  var valid_602331 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602331 = validateParameter(valid_602331, JString, required = false,
                                 default = nil)
  if valid_602331 != nil:
    section.add "X-Amz-Content-Sha256", valid_602331
  var valid_602332 = header.getOrDefault("X-Amz-Date")
  valid_602332 = validateParameter(valid_602332, JString, required = false,
                                 default = nil)
  if valid_602332 != nil:
    section.add "X-Amz-Date", valid_602332
  var valid_602333 = header.getOrDefault("X-Amz-Credential")
  valid_602333 = validateParameter(valid_602333, JString, required = false,
                                 default = nil)
  if valid_602333 != nil:
    section.add "X-Amz-Credential", valid_602333
  var valid_602334 = header.getOrDefault("X-Amz-Security-Token")
  valid_602334 = validateParameter(valid_602334, JString, required = false,
                                 default = nil)
  if valid_602334 != nil:
    section.add "X-Amz-Security-Token", valid_602334
  var valid_602335 = header.getOrDefault("X-Amz-Algorithm")
  valid_602335 = validateParameter(valid_602335, JString, required = false,
                                 default = nil)
  if valid_602335 != nil:
    section.add "X-Amz-Algorithm", valid_602335
  var valid_602336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602336 = validateParameter(valid_602336, JString, required = false,
                                 default = nil)
  if valid_602336 != nil:
    section.add "X-Amz-SignedHeaders", valid_602336
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602337: Call_GetDeliverabilityTestReport_602326; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve the results of a predictive inbox placement test.
  ## 
  let valid = call_602337.validator(path, query, header, formData, body)
  let scheme = call_602337.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602337.url(scheme.get, call_602337.host, call_602337.base,
                         call_602337.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602337, url, valid)

proc call*(call_602338: Call_GetDeliverabilityTestReport_602326; ReportId: string): Recallable =
  ## getDeliverabilityTestReport
  ## Retrieve the results of a predictive inbox placement test.
  ##   ReportId: string (required)
  ##           : A unique string that identifies a Deliverability dashboard report.
  var path_602339 = newJObject()
  add(path_602339, "ReportId", newJString(ReportId))
  result = call_602338.call(path_602339, nil, nil, nil, nil)

var getDeliverabilityTestReport* = Call_GetDeliverabilityTestReport_602326(
    name: "getDeliverabilityTestReport", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com",
    route: "/v2/email/deliverability-dashboard/test-reports/{ReportId}",
    validator: validate_GetDeliverabilityTestReport_602327, base: "/",
    url: url_GetDeliverabilityTestReport_602328,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainDeliverabilityCampaign_602340 = ref object of OpenApiRestCall_601389
proc url_GetDomainDeliverabilityCampaign_602342(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "CampaignId" in path, "`CampaignId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/v2/email/deliverability-dashboard/campaigns/"),
               (kind: VariableSegment, value: "CampaignId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDomainDeliverabilityCampaign_602341(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieve all the deliverability data for a specific campaign. This data is available for a campaign only if the campaign sent email by using a domain that the Deliverability dashboard is enabled for.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   CampaignId: JString (required)
  ##             : The unique identifier for the campaign. The Deliverability dashboard automatically generates and assigns this identifier to a campaign.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `CampaignId` field"
  var valid_602343 = path.getOrDefault("CampaignId")
  valid_602343 = validateParameter(valid_602343, JString, required = true,
                                 default = nil)
  if valid_602343 != nil:
    section.add "CampaignId", valid_602343
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602344 = header.getOrDefault("X-Amz-Signature")
  valid_602344 = validateParameter(valid_602344, JString, required = false,
                                 default = nil)
  if valid_602344 != nil:
    section.add "X-Amz-Signature", valid_602344
  var valid_602345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602345 = validateParameter(valid_602345, JString, required = false,
                                 default = nil)
  if valid_602345 != nil:
    section.add "X-Amz-Content-Sha256", valid_602345
  var valid_602346 = header.getOrDefault("X-Amz-Date")
  valid_602346 = validateParameter(valid_602346, JString, required = false,
                                 default = nil)
  if valid_602346 != nil:
    section.add "X-Amz-Date", valid_602346
  var valid_602347 = header.getOrDefault("X-Amz-Credential")
  valid_602347 = validateParameter(valid_602347, JString, required = false,
                                 default = nil)
  if valid_602347 != nil:
    section.add "X-Amz-Credential", valid_602347
  var valid_602348 = header.getOrDefault("X-Amz-Security-Token")
  valid_602348 = validateParameter(valid_602348, JString, required = false,
                                 default = nil)
  if valid_602348 != nil:
    section.add "X-Amz-Security-Token", valid_602348
  var valid_602349 = header.getOrDefault("X-Amz-Algorithm")
  valid_602349 = validateParameter(valid_602349, JString, required = false,
                                 default = nil)
  if valid_602349 != nil:
    section.add "X-Amz-Algorithm", valid_602349
  var valid_602350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602350 = validateParameter(valid_602350, JString, required = false,
                                 default = nil)
  if valid_602350 != nil:
    section.add "X-Amz-SignedHeaders", valid_602350
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602351: Call_GetDomainDeliverabilityCampaign_602340;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieve all the deliverability data for a specific campaign. This data is available for a campaign only if the campaign sent email by using a domain that the Deliverability dashboard is enabled for.
  ## 
  let valid = call_602351.validator(path, query, header, formData, body)
  let scheme = call_602351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602351.url(scheme.get, call_602351.host, call_602351.base,
                         call_602351.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602351, url, valid)

proc call*(call_602352: Call_GetDomainDeliverabilityCampaign_602340;
          CampaignId: string): Recallable =
  ## getDomainDeliverabilityCampaign
  ## Retrieve all the deliverability data for a specific campaign. This data is available for a campaign only if the campaign sent email by using a domain that the Deliverability dashboard is enabled for.
  ##   CampaignId: string (required)
  ##             : The unique identifier for the campaign. The Deliverability dashboard automatically generates and assigns this identifier to a campaign.
  var path_602353 = newJObject()
  add(path_602353, "CampaignId", newJString(CampaignId))
  result = call_602352.call(path_602353, nil, nil, nil, nil)

var getDomainDeliverabilityCampaign* = Call_GetDomainDeliverabilityCampaign_602340(
    name: "getDomainDeliverabilityCampaign", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com",
    route: "/v2/email/deliverability-dashboard/campaigns/{CampaignId}",
    validator: validate_GetDomainDeliverabilityCampaign_602341, base: "/",
    url: url_GetDomainDeliverabilityCampaign_602342,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainStatisticsReport_602354 = ref object of OpenApiRestCall_601389
proc url_GetDomainStatisticsReport_602356(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Domain" in path, "`Domain` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/v2/email/deliverability-dashboard/statistics-report/"),
               (kind: VariableSegment, value: "Domain"),
               (kind: ConstantSegment, value: "#StartDate&EndDate")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDomainStatisticsReport_602355(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieve inbox placement and engagement rates for the domains that you use to send email.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   Domain: JString (required)
  ##         : The domain that you want to obtain deliverability metrics for.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `Domain` field"
  var valid_602357 = path.getOrDefault("Domain")
  valid_602357 = validateParameter(valid_602357, JString, required = true,
                                 default = nil)
  if valid_602357 != nil:
    section.add "Domain", valid_602357
  result.add "path", section
  ## parameters in `query` object:
  ##   EndDate: JString (required)
  ##          : The last day (in Unix time) that you want to obtain domain deliverability metrics for. The <code>EndDate</code> that you specify has to be less than or equal to 30 days after the <code>StartDate</code>.
  ##   StartDate: JString (required)
  ##            : The first day (in Unix time) that you want to obtain domain deliverability metrics for.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `EndDate` field"
  var valid_602358 = query.getOrDefault("EndDate")
  valid_602358 = validateParameter(valid_602358, JString, required = true,
                                 default = nil)
  if valid_602358 != nil:
    section.add "EndDate", valid_602358
  var valid_602359 = query.getOrDefault("StartDate")
  valid_602359 = validateParameter(valid_602359, JString, required = true,
                                 default = nil)
  if valid_602359 != nil:
    section.add "StartDate", valid_602359
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602360 = header.getOrDefault("X-Amz-Signature")
  valid_602360 = validateParameter(valid_602360, JString, required = false,
                                 default = nil)
  if valid_602360 != nil:
    section.add "X-Amz-Signature", valid_602360
  var valid_602361 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602361 = validateParameter(valid_602361, JString, required = false,
                                 default = nil)
  if valid_602361 != nil:
    section.add "X-Amz-Content-Sha256", valid_602361
  var valid_602362 = header.getOrDefault("X-Amz-Date")
  valid_602362 = validateParameter(valid_602362, JString, required = false,
                                 default = nil)
  if valid_602362 != nil:
    section.add "X-Amz-Date", valid_602362
  var valid_602363 = header.getOrDefault("X-Amz-Credential")
  valid_602363 = validateParameter(valid_602363, JString, required = false,
                                 default = nil)
  if valid_602363 != nil:
    section.add "X-Amz-Credential", valid_602363
  var valid_602364 = header.getOrDefault("X-Amz-Security-Token")
  valid_602364 = validateParameter(valid_602364, JString, required = false,
                                 default = nil)
  if valid_602364 != nil:
    section.add "X-Amz-Security-Token", valid_602364
  var valid_602365 = header.getOrDefault("X-Amz-Algorithm")
  valid_602365 = validateParameter(valid_602365, JString, required = false,
                                 default = nil)
  if valid_602365 != nil:
    section.add "X-Amz-Algorithm", valid_602365
  var valid_602366 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602366 = validateParameter(valid_602366, JString, required = false,
                                 default = nil)
  if valid_602366 != nil:
    section.add "X-Amz-SignedHeaders", valid_602366
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602367: Call_GetDomainStatisticsReport_602354; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve inbox placement and engagement rates for the domains that you use to send email.
  ## 
  let valid = call_602367.validator(path, query, header, formData, body)
  let scheme = call_602367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602367.url(scheme.get, call_602367.host, call_602367.base,
                         call_602367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602367, url, valid)

proc call*(call_602368: Call_GetDomainStatisticsReport_602354; EndDate: string;
          Domain: string; StartDate: string): Recallable =
  ## getDomainStatisticsReport
  ## Retrieve inbox placement and engagement rates for the domains that you use to send email.
  ##   EndDate: string (required)
  ##          : The last day (in Unix time) that you want to obtain domain deliverability metrics for. The <code>EndDate</code> that you specify has to be less than or equal to 30 days after the <code>StartDate</code>.
  ##   Domain: string (required)
  ##         : The domain that you want to obtain deliverability metrics for.
  ##   StartDate: string (required)
  ##            : The first day (in Unix time) that you want to obtain domain deliverability metrics for.
  var path_602369 = newJObject()
  var query_602370 = newJObject()
  add(query_602370, "EndDate", newJString(EndDate))
  add(path_602369, "Domain", newJString(Domain))
  add(query_602370, "StartDate", newJString(StartDate))
  result = call_602368.call(path_602369, query_602370, nil, nil, nil)

var getDomainStatisticsReport* = Call_GetDomainStatisticsReport_602354(
    name: "getDomainStatisticsReport", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v2/email/deliverability-dashboard/statistics-report/{Domain}#StartDate&EndDate",
    validator: validate_GetDomainStatisticsReport_602355, base: "/",
    url: url_GetDomainStatisticsReport_602356,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeliverabilityTestReports_602371 = ref object of OpenApiRestCall_601389
proc url_ListDeliverabilityTestReports_602373(protocol: Scheme; host: string;
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

proc validate_ListDeliverabilityTestReports_602372(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Show a list of the predictive inbox placement tests that you've performed, regardless of their statuses. For predictive inbox placement tests that are complete, you can use the <code>GetDeliverabilityTestReport</code> operation to view the results.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : A token returned from a previous call to <code>ListDeliverabilityTestReports</code> to indicate the position in the list of predictive inbox placement tests.
  ##   PageSize: JInt
  ##           : <p>The number of results to show in a single call to <code>ListDeliverabilityTestReports</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.</p> <p>The value you specify has to be at least 0, and can be no more than 1000.</p>
  section = newJObject()
  var valid_602374 = query.getOrDefault("NextToken")
  valid_602374 = validateParameter(valid_602374, JString, required = false,
                                 default = nil)
  if valid_602374 != nil:
    section.add "NextToken", valid_602374
  var valid_602375 = query.getOrDefault("PageSize")
  valid_602375 = validateParameter(valid_602375, JInt, required = false, default = nil)
  if valid_602375 != nil:
    section.add "PageSize", valid_602375
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602376 = header.getOrDefault("X-Amz-Signature")
  valid_602376 = validateParameter(valid_602376, JString, required = false,
                                 default = nil)
  if valid_602376 != nil:
    section.add "X-Amz-Signature", valid_602376
  var valid_602377 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602377 = validateParameter(valid_602377, JString, required = false,
                                 default = nil)
  if valid_602377 != nil:
    section.add "X-Amz-Content-Sha256", valid_602377
  var valid_602378 = header.getOrDefault("X-Amz-Date")
  valid_602378 = validateParameter(valid_602378, JString, required = false,
                                 default = nil)
  if valid_602378 != nil:
    section.add "X-Amz-Date", valid_602378
  var valid_602379 = header.getOrDefault("X-Amz-Credential")
  valid_602379 = validateParameter(valid_602379, JString, required = false,
                                 default = nil)
  if valid_602379 != nil:
    section.add "X-Amz-Credential", valid_602379
  var valid_602380 = header.getOrDefault("X-Amz-Security-Token")
  valid_602380 = validateParameter(valid_602380, JString, required = false,
                                 default = nil)
  if valid_602380 != nil:
    section.add "X-Amz-Security-Token", valid_602380
  var valid_602381 = header.getOrDefault("X-Amz-Algorithm")
  valid_602381 = validateParameter(valid_602381, JString, required = false,
                                 default = nil)
  if valid_602381 != nil:
    section.add "X-Amz-Algorithm", valid_602381
  var valid_602382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602382 = validateParameter(valid_602382, JString, required = false,
                                 default = nil)
  if valid_602382 != nil:
    section.add "X-Amz-SignedHeaders", valid_602382
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602383: Call_ListDeliverabilityTestReports_602371; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Show a list of the predictive inbox placement tests that you've performed, regardless of their statuses. For predictive inbox placement tests that are complete, you can use the <code>GetDeliverabilityTestReport</code> operation to view the results.
  ## 
  let valid = call_602383.validator(path, query, header, formData, body)
  let scheme = call_602383.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602383.url(scheme.get, call_602383.host, call_602383.base,
                         call_602383.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602383, url, valid)

proc call*(call_602384: Call_ListDeliverabilityTestReports_602371;
          NextToken: string = ""; PageSize: int = 0): Recallable =
  ## listDeliverabilityTestReports
  ## Show a list of the predictive inbox placement tests that you've performed, regardless of their statuses. For predictive inbox placement tests that are complete, you can use the <code>GetDeliverabilityTestReport</code> operation to view the results.
  ##   NextToken: string
  ##            : A token returned from a previous call to <code>ListDeliverabilityTestReports</code> to indicate the position in the list of predictive inbox placement tests.
  ##   PageSize: int
  ##           : <p>The number of results to show in a single call to <code>ListDeliverabilityTestReports</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.</p> <p>The value you specify has to be at least 0, and can be no more than 1000.</p>
  var query_602385 = newJObject()
  add(query_602385, "NextToken", newJString(NextToken))
  add(query_602385, "PageSize", newJInt(PageSize))
  result = call_602384.call(nil, query_602385, nil, nil, nil)

var listDeliverabilityTestReports* = Call_ListDeliverabilityTestReports_602371(
    name: "listDeliverabilityTestReports", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com",
    route: "/v2/email/deliverability-dashboard/test-reports",
    validator: validate_ListDeliverabilityTestReports_602372, base: "/",
    url: url_ListDeliverabilityTestReports_602373,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDomainDeliverabilityCampaigns_602386 = ref object of OpenApiRestCall_601389
proc url_ListDomainDeliverabilityCampaigns_602388(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "SubscribedDomain" in path,
        "`SubscribedDomain` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/v2/email/deliverability-dashboard/domains/"),
               (kind: VariableSegment, value: "SubscribedDomain"),
               (kind: ConstantSegment, value: "/campaigns#StartDate&EndDate")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDomainDeliverabilityCampaigns_602387(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieve deliverability data for all the campaigns that used a specific domain to send email during a specified time range. This data is available for a domain only if you enabled the Deliverability dashboard for the domain.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   SubscribedDomain: JString (required)
  ##                   : The domain to obtain deliverability data for.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `SubscribedDomain` field"
  var valid_602389 = path.getOrDefault("SubscribedDomain")
  valid_602389 = validateParameter(valid_602389, JString, required = true,
                                 default = nil)
  if valid_602389 != nil:
    section.add "SubscribedDomain", valid_602389
  result.add "path", section
  ## parameters in `query` object:
  ##   EndDate: JString (required)
  ##          : The last day, in Unix time format, that you want to obtain deliverability data for. This value has to be less than or equal to 30 days after the value of the <code>StartDate</code> parameter.
  ##   NextToken: JString
  ##            : A token that’s returned from a previous call to the <code>ListDomainDeliverabilityCampaigns</code> operation. This token indicates the position of a campaign in the list of campaigns.
  ##   PageSize: JInt
  ##           : The maximum number of results to include in response to a single call to the <code>ListDomainDeliverabilityCampaigns</code> operation. If the number of results is larger than the number that you specify in this parameter, the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  ##   StartDate: JString (required)
  ##            : The first day, in Unix time format, that you want to obtain deliverability data for.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `EndDate` field"
  var valid_602390 = query.getOrDefault("EndDate")
  valid_602390 = validateParameter(valid_602390, JString, required = true,
                                 default = nil)
  if valid_602390 != nil:
    section.add "EndDate", valid_602390
  var valid_602391 = query.getOrDefault("NextToken")
  valid_602391 = validateParameter(valid_602391, JString, required = false,
                                 default = nil)
  if valid_602391 != nil:
    section.add "NextToken", valid_602391
  var valid_602392 = query.getOrDefault("PageSize")
  valid_602392 = validateParameter(valid_602392, JInt, required = false, default = nil)
  if valid_602392 != nil:
    section.add "PageSize", valid_602392
  var valid_602393 = query.getOrDefault("StartDate")
  valid_602393 = validateParameter(valid_602393, JString, required = true,
                                 default = nil)
  if valid_602393 != nil:
    section.add "StartDate", valid_602393
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602394 = header.getOrDefault("X-Amz-Signature")
  valid_602394 = validateParameter(valid_602394, JString, required = false,
                                 default = nil)
  if valid_602394 != nil:
    section.add "X-Amz-Signature", valid_602394
  var valid_602395 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602395 = validateParameter(valid_602395, JString, required = false,
                                 default = nil)
  if valid_602395 != nil:
    section.add "X-Amz-Content-Sha256", valid_602395
  var valid_602396 = header.getOrDefault("X-Amz-Date")
  valid_602396 = validateParameter(valid_602396, JString, required = false,
                                 default = nil)
  if valid_602396 != nil:
    section.add "X-Amz-Date", valid_602396
  var valid_602397 = header.getOrDefault("X-Amz-Credential")
  valid_602397 = validateParameter(valid_602397, JString, required = false,
                                 default = nil)
  if valid_602397 != nil:
    section.add "X-Amz-Credential", valid_602397
  var valid_602398 = header.getOrDefault("X-Amz-Security-Token")
  valid_602398 = validateParameter(valid_602398, JString, required = false,
                                 default = nil)
  if valid_602398 != nil:
    section.add "X-Amz-Security-Token", valid_602398
  var valid_602399 = header.getOrDefault("X-Amz-Algorithm")
  valid_602399 = validateParameter(valid_602399, JString, required = false,
                                 default = nil)
  if valid_602399 != nil:
    section.add "X-Amz-Algorithm", valid_602399
  var valid_602400 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602400 = validateParameter(valid_602400, JString, required = false,
                                 default = nil)
  if valid_602400 != nil:
    section.add "X-Amz-SignedHeaders", valid_602400
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602401: Call_ListDomainDeliverabilityCampaigns_602386;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieve deliverability data for all the campaigns that used a specific domain to send email during a specified time range. This data is available for a domain only if you enabled the Deliverability dashboard for the domain.
  ## 
  let valid = call_602401.validator(path, query, header, formData, body)
  let scheme = call_602401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602401.url(scheme.get, call_602401.host, call_602401.base,
                         call_602401.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602401, url, valid)

proc call*(call_602402: Call_ListDomainDeliverabilityCampaigns_602386;
          EndDate: string; SubscribedDomain: string; StartDate: string;
          NextToken: string = ""; PageSize: int = 0): Recallable =
  ## listDomainDeliverabilityCampaigns
  ## Retrieve deliverability data for all the campaigns that used a specific domain to send email during a specified time range. This data is available for a domain only if you enabled the Deliverability dashboard for the domain.
  ##   EndDate: string (required)
  ##          : The last day, in Unix time format, that you want to obtain deliverability data for. This value has to be less than or equal to 30 days after the value of the <code>StartDate</code> parameter.
  ##   NextToken: string
  ##            : A token that’s returned from a previous call to the <code>ListDomainDeliverabilityCampaigns</code> operation. This token indicates the position of a campaign in the list of campaigns.
  ##   SubscribedDomain: string (required)
  ##                   : The domain to obtain deliverability data for.
  ##   PageSize: int
  ##           : The maximum number of results to include in response to a single call to the <code>ListDomainDeliverabilityCampaigns</code> operation. If the number of results is larger than the number that you specify in this parameter, the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  ##   StartDate: string (required)
  ##            : The first day, in Unix time format, that you want to obtain deliverability data for.
  var path_602403 = newJObject()
  var query_602404 = newJObject()
  add(query_602404, "EndDate", newJString(EndDate))
  add(query_602404, "NextToken", newJString(NextToken))
  add(path_602403, "SubscribedDomain", newJString(SubscribedDomain))
  add(query_602404, "PageSize", newJInt(PageSize))
  add(query_602404, "StartDate", newJString(StartDate))
  result = call_602402.call(path_602403, query_602404, nil, nil, nil)

var listDomainDeliverabilityCampaigns* = Call_ListDomainDeliverabilityCampaigns_602386(
    name: "listDomainDeliverabilityCampaigns", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v2/email/deliverability-dashboard/domains/{SubscribedDomain}/campaigns#StartDate&EndDate",
    validator: validate_ListDomainDeliverabilityCampaigns_602387, base: "/",
    url: url_ListDomainDeliverabilityCampaigns_602388,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutSuppressedDestination_602423 = ref object of OpenApiRestCall_601389
proc url_PutSuppressedDestination_602425(protocol: Scheme; host: string;
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

proc validate_PutSuppressedDestination_602424(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds an email address to the suppression list for your account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602426 = header.getOrDefault("X-Amz-Signature")
  valid_602426 = validateParameter(valid_602426, JString, required = false,
                                 default = nil)
  if valid_602426 != nil:
    section.add "X-Amz-Signature", valid_602426
  var valid_602427 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602427 = validateParameter(valid_602427, JString, required = false,
                                 default = nil)
  if valid_602427 != nil:
    section.add "X-Amz-Content-Sha256", valid_602427
  var valid_602428 = header.getOrDefault("X-Amz-Date")
  valid_602428 = validateParameter(valid_602428, JString, required = false,
                                 default = nil)
  if valid_602428 != nil:
    section.add "X-Amz-Date", valid_602428
  var valid_602429 = header.getOrDefault("X-Amz-Credential")
  valid_602429 = validateParameter(valid_602429, JString, required = false,
                                 default = nil)
  if valid_602429 != nil:
    section.add "X-Amz-Credential", valid_602429
  var valid_602430 = header.getOrDefault("X-Amz-Security-Token")
  valid_602430 = validateParameter(valid_602430, JString, required = false,
                                 default = nil)
  if valid_602430 != nil:
    section.add "X-Amz-Security-Token", valid_602430
  var valid_602431 = header.getOrDefault("X-Amz-Algorithm")
  valid_602431 = validateParameter(valid_602431, JString, required = false,
                                 default = nil)
  if valid_602431 != nil:
    section.add "X-Amz-Algorithm", valid_602431
  var valid_602432 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602432 = validateParameter(valid_602432, JString, required = false,
                                 default = nil)
  if valid_602432 != nil:
    section.add "X-Amz-SignedHeaders", valid_602432
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602434: Call_PutSuppressedDestination_602423; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds an email address to the suppression list for your account.
  ## 
  let valid = call_602434.validator(path, query, header, formData, body)
  let scheme = call_602434.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602434.url(scheme.get, call_602434.host, call_602434.base,
                         call_602434.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602434, url, valid)

proc call*(call_602435: Call_PutSuppressedDestination_602423; body: JsonNode): Recallable =
  ## putSuppressedDestination
  ## Adds an email address to the suppression list for your account.
  ##   body: JObject (required)
  var body_602436 = newJObject()
  if body != nil:
    body_602436 = body
  result = call_602435.call(nil, nil, nil, nil, body_602436)

var putSuppressedDestination* = Call_PutSuppressedDestination_602423(
    name: "putSuppressedDestination", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v2/email/suppression/addresses",
    validator: validate_PutSuppressedDestination_602424, base: "/",
    url: url_PutSuppressedDestination_602425, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSuppressedDestinations_602405 = ref object of OpenApiRestCall_601389
proc url_ListSuppressedDestinations_602407(protocol: Scheme; host: string;
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

proc validate_ListSuppressedDestinations_602406(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of email addresses that are on the suppression list for your account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   EndDate: JString
  ##          : Used to filter the list of suppressed email destinations so that it only includes addresses that were added to the list before a specific date. The date that you specify should be in Unix time format.
  ##   NextToken: JString
  ##            : A token returned from a previous call to <code>ListSuppressedDestinations</code> to indicate the position in the list of suppressed email addresses.
  ##   Reason: JArray
  ##         : The factors that caused the email address to be added to .
  ##   PageSize: JInt
  ##           : The number of results to show in a single call to <code>ListSuppressedDestinations</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  ##   StartDate: JString
  ##            : Used to filter the list of suppressed email destinations so that it only includes addresses that were added to the list after a specific date. The date that you specify should be in Unix time format.
  section = newJObject()
  var valid_602408 = query.getOrDefault("EndDate")
  valid_602408 = validateParameter(valid_602408, JString, required = false,
                                 default = nil)
  if valid_602408 != nil:
    section.add "EndDate", valid_602408
  var valid_602409 = query.getOrDefault("NextToken")
  valid_602409 = validateParameter(valid_602409, JString, required = false,
                                 default = nil)
  if valid_602409 != nil:
    section.add "NextToken", valid_602409
  var valid_602410 = query.getOrDefault("Reason")
  valid_602410 = validateParameter(valid_602410, JArray, required = false,
                                 default = nil)
  if valid_602410 != nil:
    section.add "Reason", valid_602410
  var valid_602411 = query.getOrDefault("PageSize")
  valid_602411 = validateParameter(valid_602411, JInt, required = false, default = nil)
  if valid_602411 != nil:
    section.add "PageSize", valid_602411
  var valid_602412 = query.getOrDefault("StartDate")
  valid_602412 = validateParameter(valid_602412, JString, required = false,
                                 default = nil)
  if valid_602412 != nil:
    section.add "StartDate", valid_602412
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602413 = header.getOrDefault("X-Amz-Signature")
  valid_602413 = validateParameter(valid_602413, JString, required = false,
                                 default = nil)
  if valid_602413 != nil:
    section.add "X-Amz-Signature", valid_602413
  var valid_602414 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602414 = validateParameter(valid_602414, JString, required = false,
                                 default = nil)
  if valid_602414 != nil:
    section.add "X-Amz-Content-Sha256", valid_602414
  var valid_602415 = header.getOrDefault("X-Amz-Date")
  valid_602415 = validateParameter(valid_602415, JString, required = false,
                                 default = nil)
  if valid_602415 != nil:
    section.add "X-Amz-Date", valid_602415
  var valid_602416 = header.getOrDefault("X-Amz-Credential")
  valid_602416 = validateParameter(valid_602416, JString, required = false,
                                 default = nil)
  if valid_602416 != nil:
    section.add "X-Amz-Credential", valid_602416
  var valid_602417 = header.getOrDefault("X-Amz-Security-Token")
  valid_602417 = validateParameter(valid_602417, JString, required = false,
                                 default = nil)
  if valid_602417 != nil:
    section.add "X-Amz-Security-Token", valid_602417
  var valid_602418 = header.getOrDefault("X-Amz-Algorithm")
  valid_602418 = validateParameter(valid_602418, JString, required = false,
                                 default = nil)
  if valid_602418 != nil:
    section.add "X-Amz-Algorithm", valid_602418
  var valid_602419 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602419 = validateParameter(valid_602419, JString, required = false,
                                 default = nil)
  if valid_602419 != nil:
    section.add "X-Amz-SignedHeaders", valid_602419
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602420: Call_ListSuppressedDestinations_602405; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of email addresses that are on the suppression list for your account.
  ## 
  let valid = call_602420.validator(path, query, header, formData, body)
  let scheme = call_602420.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602420.url(scheme.get, call_602420.host, call_602420.base,
                         call_602420.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602420, url, valid)

proc call*(call_602421: Call_ListSuppressedDestinations_602405;
          EndDate: string = ""; NextToken: string = ""; Reason: JsonNode = nil;
          PageSize: int = 0; StartDate: string = ""): Recallable =
  ## listSuppressedDestinations
  ## Retrieves a list of email addresses that are on the suppression list for your account.
  ##   EndDate: string
  ##          : Used to filter the list of suppressed email destinations so that it only includes addresses that were added to the list before a specific date. The date that you specify should be in Unix time format.
  ##   NextToken: string
  ##            : A token returned from a previous call to <code>ListSuppressedDestinations</code> to indicate the position in the list of suppressed email addresses.
  ##   Reason: JArray
  ##         : The factors that caused the email address to be added to .
  ##   PageSize: int
  ##           : The number of results to show in a single call to <code>ListSuppressedDestinations</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  ##   StartDate: string
  ##            : Used to filter the list of suppressed email destinations so that it only includes addresses that were added to the list after a specific date. The date that you specify should be in Unix time format.
  var query_602422 = newJObject()
  add(query_602422, "EndDate", newJString(EndDate))
  add(query_602422, "NextToken", newJString(NextToken))
  if Reason != nil:
    query_602422.add "Reason", Reason
  add(query_602422, "PageSize", newJInt(PageSize))
  add(query_602422, "StartDate", newJString(StartDate))
  result = call_602421.call(nil, query_602422, nil, nil, nil)

var listSuppressedDestinations* = Call_ListSuppressedDestinations_602405(
    name: "listSuppressedDestinations", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v2/email/suppression/addresses",
    validator: validate_ListSuppressedDestinations_602406, base: "/",
    url: url_ListSuppressedDestinations_602407,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_602437 = ref object of OpenApiRestCall_601389
proc url_ListTagsForResource_602439(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_602438(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Retrieve a list of the tags (keys and values) that are associated with a specified resource. A <i>tag</i> is a label that you optionally define and associate with a resource. Each tag consists of a required <i>tag key</i> and an optional associated <i>tag value</i>. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ResourceArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the resource that you want to retrieve tag information for.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ResourceArn` field"
  var valid_602440 = query.getOrDefault("ResourceArn")
  valid_602440 = validateParameter(valid_602440, JString, required = true,
                                 default = nil)
  if valid_602440 != nil:
    section.add "ResourceArn", valid_602440
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602441 = header.getOrDefault("X-Amz-Signature")
  valid_602441 = validateParameter(valid_602441, JString, required = false,
                                 default = nil)
  if valid_602441 != nil:
    section.add "X-Amz-Signature", valid_602441
  var valid_602442 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602442 = validateParameter(valid_602442, JString, required = false,
                                 default = nil)
  if valid_602442 != nil:
    section.add "X-Amz-Content-Sha256", valid_602442
  var valid_602443 = header.getOrDefault("X-Amz-Date")
  valid_602443 = validateParameter(valid_602443, JString, required = false,
                                 default = nil)
  if valid_602443 != nil:
    section.add "X-Amz-Date", valid_602443
  var valid_602444 = header.getOrDefault("X-Amz-Credential")
  valid_602444 = validateParameter(valid_602444, JString, required = false,
                                 default = nil)
  if valid_602444 != nil:
    section.add "X-Amz-Credential", valid_602444
  var valid_602445 = header.getOrDefault("X-Amz-Security-Token")
  valid_602445 = validateParameter(valid_602445, JString, required = false,
                                 default = nil)
  if valid_602445 != nil:
    section.add "X-Amz-Security-Token", valid_602445
  var valid_602446 = header.getOrDefault("X-Amz-Algorithm")
  valid_602446 = validateParameter(valid_602446, JString, required = false,
                                 default = nil)
  if valid_602446 != nil:
    section.add "X-Amz-Algorithm", valid_602446
  var valid_602447 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602447 = validateParameter(valid_602447, JString, required = false,
                                 default = nil)
  if valid_602447 != nil:
    section.add "X-Amz-SignedHeaders", valid_602447
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602448: Call_ListTagsForResource_602437; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a list of the tags (keys and values) that are associated with a specified resource. A <i>tag</i> is a label that you optionally define and associate with a resource. Each tag consists of a required <i>tag key</i> and an optional associated <i>tag value</i>. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.
  ## 
  let valid = call_602448.validator(path, query, header, formData, body)
  let scheme = call_602448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602448.url(scheme.get, call_602448.host, call_602448.base,
                         call_602448.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602448, url, valid)

proc call*(call_602449: Call_ListTagsForResource_602437; ResourceArn: string): Recallable =
  ## listTagsForResource
  ## Retrieve a list of the tags (keys and values) that are associated with a specified resource. A <i>tag</i> is a label that you optionally define and associate with a resource. Each tag consists of a required <i>tag key</i> and an optional associated <i>tag value</i>. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.
  ##   ResourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource that you want to retrieve tag information for.
  var query_602450 = newJObject()
  add(query_602450, "ResourceArn", newJString(ResourceArn))
  result = call_602449.call(nil, query_602450, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_602437(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v2/email/tags#ResourceArn",
    validator: validate_ListTagsForResource_602438, base: "/",
    url: url_ListTagsForResource_602439, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAccountDedicatedIpWarmupAttributes_602451 = ref object of OpenApiRestCall_601389
proc url_PutAccountDedicatedIpWarmupAttributes_602453(protocol: Scheme;
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

proc validate_PutAccountDedicatedIpWarmupAttributes_602452(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Enable or disable the automatic warm-up feature for dedicated IP addresses.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602454 = header.getOrDefault("X-Amz-Signature")
  valid_602454 = validateParameter(valid_602454, JString, required = false,
                                 default = nil)
  if valid_602454 != nil:
    section.add "X-Amz-Signature", valid_602454
  var valid_602455 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602455 = validateParameter(valid_602455, JString, required = false,
                                 default = nil)
  if valid_602455 != nil:
    section.add "X-Amz-Content-Sha256", valid_602455
  var valid_602456 = header.getOrDefault("X-Amz-Date")
  valid_602456 = validateParameter(valid_602456, JString, required = false,
                                 default = nil)
  if valid_602456 != nil:
    section.add "X-Amz-Date", valid_602456
  var valid_602457 = header.getOrDefault("X-Amz-Credential")
  valid_602457 = validateParameter(valid_602457, JString, required = false,
                                 default = nil)
  if valid_602457 != nil:
    section.add "X-Amz-Credential", valid_602457
  var valid_602458 = header.getOrDefault("X-Amz-Security-Token")
  valid_602458 = validateParameter(valid_602458, JString, required = false,
                                 default = nil)
  if valid_602458 != nil:
    section.add "X-Amz-Security-Token", valid_602458
  var valid_602459 = header.getOrDefault("X-Amz-Algorithm")
  valid_602459 = validateParameter(valid_602459, JString, required = false,
                                 default = nil)
  if valid_602459 != nil:
    section.add "X-Amz-Algorithm", valid_602459
  var valid_602460 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602460 = validateParameter(valid_602460, JString, required = false,
                                 default = nil)
  if valid_602460 != nil:
    section.add "X-Amz-SignedHeaders", valid_602460
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602462: Call_PutAccountDedicatedIpWarmupAttributes_602451;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Enable or disable the automatic warm-up feature for dedicated IP addresses.
  ## 
  let valid = call_602462.validator(path, query, header, formData, body)
  let scheme = call_602462.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602462.url(scheme.get, call_602462.host, call_602462.base,
                         call_602462.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602462, url, valid)

proc call*(call_602463: Call_PutAccountDedicatedIpWarmupAttributes_602451;
          body: JsonNode): Recallable =
  ## putAccountDedicatedIpWarmupAttributes
  ## Enable or disable the automatic warm-up feature for dedicated IP addresses.
  ##   body: JObject (required)
  var body_602464 = newJObject()
  if body != nil:
    body_602464 = body
  result = call_602463.call(nil, nil, nil, nil, body_602464)

var putAccountDedicatedIpWarmupAttributes* = Call_PutAccountDedicatedIpWarmupAttributes_602451(
    name: "putAccountDedicatedIpWarmupAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v2/email/account/dedicated-ips/warmup",
    validator: validate_PutAccountDedicatedIpWarmupAttributes_602452, base: "/",
    url: url_PutAccountDedicatedIpWarmupAttributes_602453,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAccountSendingAttributes_602465 = ref object of OpenApiRestCall_601389
proc url_PutAccountSendingAttributes_602467(protocol: Scheme; host: string;
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

proc validate_PutAccountSendingAttributes_602466(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Enable or disable the ability of your account to send email.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602468 = header.getOrDefault("X-Amz-Signature")
  valid_602468 = validateParameter(valid_602468, JString, required = false,
                                 default = nil)
  if valid_602468 != nil:
    section.add "X-Amz-Signature", valid_602468
  var valid_602469 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602469 = validateParameter(valid_602469, JString, required = false,
                                 default = nil)
  if valid_602469 != nil:
    section.add "X-Amz-Content-Sha256", valid_602469
  var valid_602470 = header.getOrDefault("X-Amz-Date")
  valid_602470 = validateParameter(valid_602470, JString, required = false,
                                 default = nil)
  if valid_602470 != nil:
    section.add "X-Amz-Date", valid_602470
  var valid_602471 = header.getOrDefault("X-Amz-Credential")
  valid_602471 = validateParameter(valid_602471, JString, required = false,
                                 default = nil)
  if valid_602471 != nil:
    section.add "X-Amz-Credential", valid_602471
  var valid_602472 = header.getOrDefault("X-Amz-Security-Token")
  valid_602472 = validateParameter(valid_602472, JString, required = false,
                                 default = nil)
  if valid_602472 != nil:
    section.add "X-Amz-Security-Token", valid_602472
  var valid_602473 = header.getOrDefault("X-Amz-Algorithm")
  valid_602473 = validateParameter(valid_602473, JString, required = false,
                                 default = nil)
  if valid_602473 != nil:
    section.add "X-Amz-Algorithm", valid_602473
  var valid_602474 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602474 = validateParameter(valid_602474, JString, required = false,
                                 default = nil)
  if valid_602474 != nil:
    section.add "X-Amz-SignedHeaders", valid_602474
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602476: Call_PutAccountSendingAttributes_602465; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enable or disable the ability of your account to send email.
  ## 
  let valid = call_602476.validator(path, query, header, formData, body)
  let scheme = call_602476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602476.url(scheme.get, call_602476.host, call_602476.base,
                         call_602476.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602476, url, valid)

proc call*(call_602477: Call_PutAccountSendingAttributes_602465; body: JsonNode): Recallable =
  ## putAccountSendingAttributes
  ## Enable or disable the ability of your account to send email.
  ##   body: JObject (required)
  var body_602478 = newJObject()
  if body != nil:
    body_602478 = body
  result = call_602477.call(nil, nil, nil, nil, body_602478)

var putAccountSendingAttributes* = Call_PutAccountSendingAttributes_602465(
    name: "putAccountSendingAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v2/email/account/sending",
    validator: validate_PutAccountSendingAttributes_602466, base: "/",
    url: url_PutAccountSendingAttributes_602467,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAccountSuppressionAttributes_602479 = ref object of OpenApiRestCall_601389
proc url_PutAccountSuppressionAttributes_602481(protocol: Scheme; host: string;
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

proc validate_PutAccountSuppressionAttributes_602480(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Change the settings for the account-level suppression list.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602482 = header.getOrDefault("X-Amz-Signature")
  valid_602482 = validateParameter(valid_602482, JString, required = false,
                                 default = nil)
  if valid_602482 != nil:
    section.add "X-Amz-Signature", valid_602482
  var valid_602483 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602483 = validateParameter(valid_602483, JString, required = false,
                                 default = nil)
  if valid_602483 != nil:
    section.add "X-Amz-Content-Sha256", valid_602483
  var valid_602484 = header.getOrDefault("X-Amz-Date")
  valid_602484 = validateParameter(valid_602484, JString, required = false,
                                 default = nil)
  if valid_602484 != nil:
    section.add "X-Amz-Date", valid_602484
  var valid_602485 = header.getOrDefault("X-Amz-Credential")
  valid_602485 = validateParameter(valid_602485, JString, required = false,
                                 default = nil)
  if valid_602485 != nil:
    section.add "X-Amz-Credential", valid_602485
  var valid_602486 = header.getOrDefault("X-Amz-Security-Token")
  valid_602486 = validateParameter(valid_602486, JString, required = false,
                                 default = nil)
  if valid_602486 != nil:
    section.add "X-Amz-Security-Token", valid_602486
  var valid_602487 = header.getOrDefault("X-Amz-Algorithm")
  valid_602487 = validateParameter(valid_602487, JString, required = false,
                                 default = nil)
  if valid_602487 != nil:
    section.add "X-Amz-Algorithm", valid_602487
  var valid_602488 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602488 = validateParameter(valid_602488, JString, required = false,
                                 default = nil)
  if valid_602488 != nil:
    section.add "X-Amz-SignedHeaders", valid_602488
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602490: Call_PutAccountSuppressionAttributes_602479;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Change the settings for the account-level suppression list.
  ## 
  let valid = call_602490.validator(path, query, header, formData, body)
  let scheme = call_602490.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602490.url(scheme.get, call_602490.host, call_602490.base,
                         call_602490.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602490, url, valid)

proc call*(call_602491: Call_PutAccountSuppressionAttributes_602479; body: JsonNode): Recallable =
  ## putAccountSuppressionAttributes
  ## Change the settings for the account-level suppression list.
  ##   body: JObject (required)
  var body_602492 = newJObject()
  if body != nil:
    body_602492 = body
  result = call_602491.call(nil, nil, nil, nil, body_602492)

var putAccountSuppressionAttributes* = Call_PutAccountSuppressionAttributes_602479(
    name: "putAccountSuppressionAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v2/email/account/suppression",
    validator: validate_PutAccountSuppressionAttributes_602480, base: "/",
    url: url_PutAccountSuppressionAttributes_602481,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConfigurationSetDeliveryOptions_602493 = ref object of OpenApiRestCall_601389
proc url_PutConfigurationSetDeliveryOptions_602495(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
        "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/email/configuration-sets/"),
               (kind: VariableSegment, value: "ConfigurationSetName"),
               (kind: ConstantSegment, value: "/delivery-options")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutConfigurationSetDeliveryOptions_602494(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Associate a configuration set with a dedicated IP pool. You can use dedicated IP pools to create groups of dedicated IP addresses for sending specific types of email.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : <p>The name of a configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_602496 = path.getOrDefault("ConfigurationSetName")
  valid_602496 = validateParameter(valid_602496, JString, required = true,
                                 default = nil)
  if valid_602496 != nil:
    section.add "ConfigurationSetName", valid_602496
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602497 = header.getOrDefault("X-Amz-Signature")
  valid_602497 = validateParameter(valid_602497, JString, required = false,
                                 default = nil)
  if valid_602497 != nil:
    section.add "X-Amz-Signature", valid_602497
  var valid_602498 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602498 = validateParameter(valid_602498, JString, required = false,
                                 default = nil)
  if valid_602498 != nil:
    section.add "X-Amz-Content-Sha256", valid_602498
  var valid_602499 = header.getOrDefault("X-Amz-Date")
  valid_602499 = validateParameter(valid_602499, JString, required = false,
                                 default = nil)
  if valid_602499 != nil:
    section.add "X-Amz-Date", valid_602499
  var valid_602500 = header.getOrDefault("X-Amz-Credential")
  valid_602500 = validateParameter(valid_602500, JString, required = false,
                                 default = nil)
  if valid_602500 != nil:
    section.add "X-Amz-Credential", valid_602500
  var valid_602501 = header.getOrDefault("X-Amz-Security-Token")
  valid_602501 = validateParameter(valid_602501, JString, required = false,
                                 default = nil)
  if valid_602501 != nil:
    section.add "X-Amz-Security-Token", valid_602501
  var valid_602502 = header.getOrDefault("X-Amz-Algorithm")
  valid_602502 = validateParameter(valid_602502, JString, required = false,
                                 default = nil)
  if valid_602502 != nil:
    section.add "X-Amz-Algorithm", valid_602502
  var valid_602503 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602503 = validateParameter(valid_602503, JString, required = false,
                                 default = nil)
  if valid_602503 != nil:
    section.add "X-Amz-SignedHeaders", valid_602503
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602505: Call_PutConfigurationSetDeliveryOptions_602493;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associate a configuration set with a dedicated IP pool. You can use dedicated IP pools to create groups of dedicated IP addresses for sending specific types of email.
  ## 
  let valid = call_602505.validator(path, query, header, formData, body)
  let scheme = call_602505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602505.url(scheme.get, call_602505.host, call_602505.base,
                         call_602505.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602505, url, valid)

proc call*(call_602506: Call_PutConfigurationSetDeliveryOptions_602493;
          ConfigurationSetName: string; body: JsonNode): Recallable =
  ## putConfigurationSetDeliveryOptions
  ## Associate a configuration set with a dedicated IP pool. You can use dedicated IP pools to create groups of dedicated IP addresses for sending specific types of email.
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   body: JObject (required)
  var path_602507 = newJObject()
  var body_602508 = newJObject()
  add(path_602507, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_602508 = body
  result = call_602506.call(path_602507, nil, nil, nil, body_602508)

var putConfigurationSetDeliveryOptions* = Call_PutConfigurationSetDeliveryOptions_602493(
    name: "putConfigurationSetDeliveryOptions", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v2/email/configuration-sets/{ConfigurationSetName}/delivery-options",
    validator: validate_PutConfigurationSetDeliveryOptions_602494, base: "/",
    url: url_PutConfigurationSetDeliveryOptions_602495,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConfigurationSetReputationOptions_602509 = ref object of OpenApiRestCall_601389
proc url_PutConfigurationSetReputationOptions_602511(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
        "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/email/configuration-sets/"),
               (kind: VariableSegment, value: "ConfigurationSetName"),
               (kind: ConstantSegment, value: "/reputation-options")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutConfigurationSetReputationOptions_602510(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Enable or disable collection of reputation metrics for emails that you send using a particular configuration set in a specific AWS Region.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : <p>The name of a configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_602512 = path.getOrDefault("ConfigurationSetName")
  valid_602512 = validateParameter(valid_602512, JString, required = true,
                                 default = nil)
  if valid_602512 != nil:
    section.add "ConfigurationSetName", valid_602512
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602513 = header.getOrDefault("X-Amz-Signature")
  valid_602513 = validateParameter(valid_602513, JString, required = false,
                                 default = nil)
  if valid_602513 != nil:
    section.add "X-Amz-Signature", valid_602513
  var valid_602514 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602514 = validateParameter(valid_602514, JString, required = false,
                                 default = nil)
  if valid_602514 != nil:
    section.add "X-Amz-Content-Sha256", valid_602514
  var valid_602515 = header.getOrDefault("X-Amz-Date")
  valid_602515 = validateParameter(valid_602515, JString, required = false,
                                 default = nil)
  if valid_602515 != nil:
    section.add "X-Amz-Date", valid_602515
  var valid_602516 = header.getOrDefault("X-Amz-Credential")
  valid_602516 = validateParameter(valid_602516, JString, required = false,
                                 default = nil)
  if valid_602516 != nil:
    section.add "X-Amz-Credential", valid_602516
  var valid_602517 = header.getOrDefault("X-Amz-Security-Token")
  valid_602517 = validateParameter(valid_602517, JString, required = false,
                                 default = nil)
  if valid_602517 != nil:
    section.add "X-Amz-Security-Token", valid_602517
  var valid_602518 = header.getOrDefault("X-Amz-Algorithm")
  valid_602518 = validateParameter(valid_602518, JString, required = false,
                                 default = nil)
  if valid_602518 != nil:
    section.add "X-Amz-Algorithm", valid_602518
  var valid_602519 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602519 = validateParameter(valid_602519, JString, required = false,
                                 default = nil)
  if valid_602519 != nil:
    section.add "X-Amz-SignedHeaders", valid_602519
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602521: Call_PutConfigurationSetReputationOptions_602509;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Enable or disable collection of reputation metrics for emails that you send using a particular configuration set in a specific AWS Region.
  ## 
  let valid = call_602521.validator(path, query, header, formData, body)
  let scheme = call_602521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602521.url(scheme.get, call_602521.host, call_602521.base,
                         call_602521.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602521, url, valid)

proc call*(call_602522: Call_PutConfigurationSetReputationOptions_602509;
          ConfigurationSetName: string; body: JsonNode): Recallable =
  ## putConfigurationSetReputationOptions
  ## Enable or disable collection of reputation metrics for emails that you send using a particular configuration set in a specific AWS Region.
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   body: JObject (required)
  var path_602523 = newJObject()
  var body_602524 = newJObject()
  add(path_602523, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_602524 = body
  result = call_602522.call(path_602523, nil, nil, nil, body_602524)

var putConfigurationSetReputationOptions* = Call_PutConfigurationSetReputationOptions_602509(
    name: "putConfigurationSetReputationOptions", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v2/email/configuration-sets/{ConfigurationSetName}/reputation-options",
    validator: validate_PutConfigurationSetReputationOptions_602510, base: "/",
    url: url_PutConfigurationSetReputationOptions_602511,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConfigurationSetSendingOptions_602525 = ref object of OpenApiRestCall_601389
proc url_PutConfigurationSetSendingOptions_602527(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
        "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/email/configuration-sets/"),
               (kind: VariableSegment, value: "ConfigurationSetName"),
               (kind: ConstantSegment, value: "/sending")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutConfigurationSetSendingOptions_602526(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Enable or disable email sending for messages that use a particular configuration set in a specific AWS Region.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : <p>The name of a configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_602528 = path.getOrDefault("ConfigurationSetName")
  valid_602528 = validateParameter(valid_602528, JString, required = true,
                                 default = nil)
  if valid_602528 != nil:
    section.add "ConfigurationSetName", valid_602528
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602529 = header.getOrDefault("X-Amz-Signature")
  valid_602529 = validateParameter(valid_602529, JString, required = false,
                                 default = nil)
  if valid_602529 != nil:
    section.add "X-Amz-Signature", valid_602529
  var valid_602530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602530 = validateParameter(valid_602530, JString, required = false,
                                 default = nil)
  if valid_602530 != nil:
    section.add "X-Amz-Content-Sha256", valid_602530
  var valid_602531 = header.getOrDefault("X-Amz-Date")
  valid_602531 = validateParameter(valid_602531, JString, required = false,
                                 default = nil)
  if valid_602531 != nil:
    section.add "X-Amz-Date", valid_602531
  var valid_602532 = header.getOrDefault("X-Amz-Credential")
  valid_602532 = validateParameter(valid_602532, JString, required = false,
                                 default = nil)
  if valid_602532 != nil:
    section.add "X-Amz-Credential", valid_602532
  var valid_602533 = header.getOrDefault("X-Amz-Security-Token")
  valid_602533 = validateParameter(valid_602533, JString, required = false,
                                 default = nil)
  if valid_602533 != nil:
    section.add "X-Amz-Security-Token", valid_602533
  var valid_602534 = header.getOrDefault("X-Amz-Algorithm")
  valid_602534 = validateParameter(valid_602534, JString, required = false,
                                 default = nil)
  if valid_602534 != nil:
    section.add "X-Amz-Algorithm", valid_602534
  var valid_602535 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602535 = validateParameter(valid_602535, JString, required = false,
                                 default = nil)
  if valid_602535 != nil:
    section.add "X-Amz-SignedHeaders", valid_602535
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602537: Call_PutConfigurationSetSendingOptions_602525;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Enable or disable email sending for messages that use a particular configuration set in a specific AWS Region.
  ## 
  let valid = call_602537.validator(path, query, header, formData, body)
  let scheme = call_602537.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602537.url(scheme.get, call_602537.host, call_602537.base,
                         call_602537.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602537, url, valid)

proc call*(call_602538: Call_PutConfigurationSetSendingOptions_602525;
          ConfigurationSetName: string; body: JsonNode): Recallable =
  ## putConfigurationSetSendingOptions
  ## Enable or disable email sending for messages that use a particular configuration set in a specific AWS Region.
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   body: JObject (required)
  var path_602539 = newJObject()
  var body_602540 = newJObject()
  add(path_602539, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_602540 = body
  result = call_602538.call(path_602539, nil, nil, nil, body_602540)

var putConfigurationSetSendingOptions* = Call_PutConfigurationSetSendingOptions_602525(
    name: "putConfigurationSetSendingOptions", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com",
    route: "/v2/email/configuration-sets/{ConfigurationSetName}/sending",
    validator: validate_PutConfigurationSetSendingOptions_602526, base: "/",
    url: url_PutConfigurationSetSendingOptions_602527,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConfigurationSetSuppressionOptions_602541 = ref object of OpenApiRestCall_601389
proc url_PutConfigurationSetSuppressionOptions_602543(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
        "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/email/configuration-sets/"),
               (kind: VariableSegment, value: "ConfigurationSetName"),
               (kind: ConstantSegment, value: "/suppression-options")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutConfigurationSetSuppressionOptions_602542(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Specify the account suppression list preferences for a configuration set.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : <p>The name of a configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_602544 = path.getOrDefault("ConfigurationSetName")
  valid_602544 = validateParameter(valid_602544, JString, required = true,
                                 default = nil)
  if valid_602544 != nil:
    section.add "ConfigurationSetName", valid_602544
  result.add "path", section
  section = newJObject()
  result.add "query", section
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
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602553: Call_PutConfigurationSetSuppressionOptions_602541;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Specify the account suppression list preferences for a configuration set.
  ## 
  let valid = call_602553.validator(path, query, header, formData, body)
  let scheme = call_602553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602553.url(scheme.get, call_602553.host, call_602553.base,
                         call_602553.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602553, url, valid)

proc call*(call_602554: Call_PutConfigurationSetSuppressionOptions_602541;
          ConfigurationSetName: string; body: JsonNode): Recallable =
  ## putConfigurationSetSuppressionOptions
  ## Specify the account suppression list preferences for a configuration set.
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   body: JObject (required)
  var path_602555 = newJObject()
  var body_602556 = newJObject()
  add(path_602555, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_602556 = body
  result = call_602554.call(path_602555, nil, nil, nil, body_602556)

var putConfigurationSetSuppressionOptions* = Call_PutConfigurationSetSuppressionOptions_602541(
    name: "putConfigurationSetSuppressionOptions", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v2/email/configuration-sets/{ConfigurationSetName}/suppression-options",
    validator: validate_PutConfigurationSetSuppressionOptions_602542, base: "/",
    url: url_PutConfigurationSetSuppressionOptions_602543,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConfigurationSetTrackingOptions_602557 = ref object of OpenApiRestCall_601389
proc url_PutConfigurationSetTrackingOptions_602559(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
        "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/email/configuration-sets/"),
               (kind: VariableSegment, value: "ConfigurationSetName"),
               (kind: ConstantSegment, value: "/tracking-options")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutConfigurationSetTrackingOptions_602558(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Specify a custom domain to use for open and click tracking elements in email that you send.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : <p>The name of a configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_602560 = path.getOrDefault("ConfigurationSetName")
  valid_602560 = validateParameter(valid_602560, JString, required = true,
                                 default = nil)
  if valid_602560 != nil:
    section.add "ConfigurationSetName", valid_602560
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602561 = header.getOrDefault("X-Amz-Signature")
  valid_602561 = validateParameter(valid_602561, JString, required = false,
                                 default = nil)
  if valid_602561 != nil:
    section.add "X-Amz-Signature", valid_602561
  var valid_602562 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602562 = validateParameter(valid_602562, JString, required = false,
                                 default = nil)
  if valid_602562 != nil:
    section.add "X-Amz-Content-Sha256", valid_602562
  var valid_602563 = header.getOrDefault("X-Amz-Date")
  valid_602563 = validateParameter(valid_602563, JString, required = false,
                                 default = nil)
  if valid_602563 != nil:
    section.add "X-Amz-Date", valid_602563
  var valid_602564 = header.getOrDefault("X-Amz-Credential")
  valid_602564 = validateParameter(valid_602564, JString, required = false,
                                 default = nil)
  if valid_602564 != nil:
    section.add "X-Amz-Credential", valid_602564
  var valid_602565 = header.getOrDefault("X-Amz-Security-Token")
  valid_602565 = validateParameter(valid_602565, JString, required = false,
                                 default = nil)
  if valid_602565 != nil:
    section.add "X-Amz-Security-Token", valid_602565
  var valid_602566 = header.getOrDefault("X-Amz-Algorithm")
  valid_602566 = validateParameter(valid_602566, JString, required = false,
                                 default = nil)
  if valid_602566 != nil:
    section.add "X-Amz-Algorithm", valid_602566
  var valid_602567 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602567 = validateParameter(valid_602567, JString, required = false,
                                 default = nil)
  if valid_602567 != nil:
    section.add "X-Amz-SignedHeaders", valid_602567
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602569: Call_PutConfigurationSetTrackingOptions_602557;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Specify a custom domain to use for open and click tracking elements in email that you send.
  ## 
  let valid = call_602569.validator(path, query, header, formData, body)
  let scheme = call_602569.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602569.url(scheme.get, call_602569.host, call_602569.base,
                         call_602569.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602569, url, valid)

proc call*(call_602570: Call_PutConfigurationSetTrackingOptions_602557;
          ConfigurationSetName: string; body: JsonNode): Recallable =
  ## putConfigurationSetTrackingOptions
  ## Specify a custom domain to use for open and click tracking elements in email that you send.
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p> <i>Configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   body: JObject (required)
  var path_602571 = newJObject()
  var body_602572 = newJObject()
  add(path_602571, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_602572 = body
  result = call_602570.call(path_602571, nil, nil, nil, body_602572)

var putConfigurationSetTrackingOptions* = Call_PutConfigurationSetTrackingOptions_602557(
    name: "putConfigurationSetTrackingOptions", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v2/email/configuration-sets/{ConfigurationSetName}/tracking-options",
    validator: validate_PutConfigurationSetTrackingOptions_602558, base: "/",
    url: url_PutConfigurationSetTrackingOptions_602559,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDedicatedIpInPool_602573 = ref object of OpenApiRestCall_601389
proc url_PutDedicatedIpInPool_602575(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "IP" in path, "`IP` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/email/dedicated-ips/"),
               (kind: VariableSegment, value: "IP"),
               (kind: ConstantSegment, value: "/pool")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutDedicatedIpInPool_602574(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Move a dedicated IP address to an existing dedicated IP pool.</p> <note> <p>The dedicated IP address that you specify must already exist, and must be associated with your AWS account. </p> <p>The dedicated IP pool you specify must already exist. You can create a new pool by using the <code>CreateDedicatedIpPool</code> operation.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   IP: JString (required)
  ##     : An IPv4 address.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `IP` field"
  var valid_602576 = path.getOrDefault("IP")
  valid_602576 = validateParameter(valid_602576, JString, required = true,
                                 default = nil)
  if valid_602576 != nil:
    section.add "IP", valid_602576
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602577 = header.getOrDefault("X-Amz-Signature")
  valid_602577 = validateParameter(valid_602577, JString, required = false,
                                 default = nil)
  if valid_602577 != nil:
    section.add "X-Amz-Signature", valid_602577
  var valid_602578 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602578 = validateParameter(valid_602578, JString, required = false,
                                 default = nil)
  if valid_602578 != nil:
    section.add "X-Amz-Content-Sha256", valid_602578
  var valid_602579 = header.getOrDefault("X-Amz-Date")
  valid_602579 = validateParameter(valid_602579, JString, required = false,
                                 default = nil)
  if valid_602579 != nil:
    section.add "X-Amz-Date", valid_602579
  var valid_602580 = header.getOrDefault("X-Amz-Credential")
  valid_602580 = validateParameter(valid_602580, JString, required = false,
                                 default = nil)
  if valid_602580 != nil:
    section.add "X-Amz-Credential", valid_602580
  var valid_602581 = header.getOrDefault("X-Amz-Security-Token")
  valid_602581 = validateParameter(valid_602581, JString, required = false,
                                 default = nil)
  if valid_602581 != nil:
    section.add "X-Amz-Security-Token", valid_602581
  var valid_602582 = header.getOrDefault("X-Amz-Algorithm")
  valid_602582 = validateParameter(valid_602582, JString, required = false,
                                 default = nil)
  if valid_602582 != nil:
    section.add "X-Amz-Algorithm", valid_602582
  var valid_602583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602583 = validateParameter(valid_602583, JString, required = false,
                                 default = nil)
  if valid_602583 != nil:
    section.add "X-Amz-SignedHeaders", valid_602583
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602585: Call_PutDedicatedIpInPool_602573; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Move a dedicated IP address to an existing dedicated IP pool.</p> <note> <p>The dedicated IP address that you specify must already exist, and must be associated with your AWS account. </p> <p>The dedicated IP pool you specify must already exist. You can create a new pool by using the <code>CreateDedicatedIpPool</code> operation.</p> </note>
  ## 
  let valid = call_602585.validator(path, query, header, formData, body)
  let scheme = call_602585.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602585.url(scheme.get, call_602585.host, call_602585.base,
                         call_602585.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602585, url, valid)

proc call*(call_602586: Call_PutDedicatedIpInPool_602573; IP: string; body: JsonNode): Recallable =
  ## putDedicatedIpInPool
  ## <p>Move a dedicated IP address to an existing dedicated IP pool.</p> <note> <p>The dedicated IP address that you specify must already exist, and must be associated with your AWS account. </p> <p>The dedicated IP pool you specify must already exist. You can create a new pool by using the <code>CreateDedicatedIpPool</code> operation.</p> </note>
  ##   IP: string (required)
  ##     : An IPv4 address.
  ##   body: JObject (required)
  var path_602587 = newJObject()
  var body_602588 = newJObject()
  add(path_602587, "IP", newJString(IP))
  if body != nil:
    body_602588 = body
  result = call_602586.call(path_602587, nil, nil, nil, body_602588)

var putDedicatedIpInPool* = Call_PutDedicatedIpInPool_602573(
    name: "putDedicatedIpInPool", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v2/email/dedicated-ips/{IP}/pool",
    validator: validate_PutDedicatedIpInPool_602574, base: "/",
    url: url_PutDedicatedIpInPool_602575, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDedicatedIpWarmupAttributes_602589 = ref object of OpenApiRestCall_601389
proc url_PutDedicatedIpWarmupAttributes_602591(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "IP" in path, "`IP` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/email/dedicated-ips/"),
               (kind: VariableSegment, value: "IP"),
               (kind: ConstantSegment, value: "/warmup")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutDedicatedIpWarmupAttributes_602590(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p/>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   IP: JString (required)
  ##     : An IPv4 address.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `IP` field"
  var valid_602592 = path.getOrDefault("IP")
  valid_602592 = validateParameter(valid_602592, JString, required = true,
                                 default = nil)
  if valid_602592 != nil:
    section.add "IP", valid_602592
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602593 = header.getOrDefault("X-Amz-Signature")
  valid_602593 = validateParameter(valid_602593, JString, required = false,
                                 default = nil)
  if valid_602593 != nil:
    section.add "X-Amz-Signature", valid_602593
  var valid_602594 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602594 = validateParameter(valid_602594, JString, required = false,
                                 default = nil)
  if valid_602594 != nil:
    section.add "X-Amz-Content-Sha256", valid_602594
  var valid_602595 = header.getOrDefault("X-Amz-Date")
  valid_602595 = validateParameter(valid_602595, JString, required = false,
                                 default = nil)
  if valid_602595 != nil:
    section.add "X-Amz-Date", valid_602595
  var valid_602596 = header.getOrDefault("X-Amz-Credential")
  valid_602596 = validateParameter(valid_602596, JString, required = false,
                                 default = nil)
  if valid_602596 != nil:
    section.add "X-Amz-Credential", valid_602596
  var valid_602597 = header.getOrDefault("X-Amz-Security-Token")
  valid_602597 = validateParameter(valid_602597, JString, required = false,
                                 default = nil)
  if valid_602597 != nil:
    section.add "X-Amz-Security-Token", valid_602597
  var valid_602598 = header.getOrDefault("X-Amz-Algorithm")
  valid_602598 = validateParameter(valid_602598, JString, required = false,
                                 default = nil)
  if valid_602598 != nil:
    section.add "X-Amz-Algorithm", valid_602598
  var valid_602599 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602599 = validateParameter(valid_602599, JString, required = false,
                                 default = nil)
  if valid_602599 != nil:
    section.add "X-Amz-SignedHeaders", valid_602599
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602601: Call_PutDedicatedIpWarmupAttributes_602589; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p/>
  ## 
  let valid = call_602601.validator(path, query, header, formData, body)
  let scheme = call_602601.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602601.url(scheme.get, call_602601.host, call_602601.base,
                         call_602601.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602601, url, valid)

proc call*(call_602602: Call_PutDedicatedIpWarmupAttributes_602589; IP: string;
          body: JsonNode): Recallable =
  ## putDedicatedIpWarmupAttributes
  ## <p/>
  ##   IP: string (required)
  ##     : An IPv4 address.
  ##   body: JObject (required)
  var path_602603 = newJObject()
  var body_602604 = newJObject()
  add(path_602603, "IP", newJString(IP))
  if body != nil:
    body_602604 = body
  result = call_602602.call(path_602603, nil, nil, nil, body_602604)

var putDedicatedIpWarmupAttributes* = Call_PutDedicatedIpWarmupAttributes_602589(
    name: "putDedicatedIpWarmupAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v2/email/dedicated-ips/{IP}/warmup",
    validator: validate_PutDedicatedIpWarmupAttributes_602590, base: "/",
    url: url_PutDedicatedIpWarmupAttributes_602591,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEmailIdentityDkimAttributes_602605 = ref object of OpenApiRestCall_601389
proc url_PutEmailIdentityDkimAttributes_602607(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "EmailIdentity" in path, "`EmailIdentity` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/email/identities/"),
               (kind: VariableSegment, value: "EmailIdentity"),
               (kind: ConstantSegment, value: "/dkim")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutEmailIdentityDkimAttributes_602606(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Used to enable or disable DKIM authentication for an email identity.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   EmailIdentity: JString (required)
  ##                : The email identity that you want to change the DKIM settings for.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `EmailIdentity` field"
  var valid_602608 = path.getOrDefault("EmailIdentity")
  valid_602608 = validateParameter(valid_602608, JString, required = true,
                                 default = nil)
  if valid_602608 != nil:
    section.add "EmailIdentity", valid_602608
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602609 = header.getOrDefault("X-Amz-Signature")
  valid_602609 = validateParameter(valid_602609, JString, required = false,
                                 default = nil)
  if valid_602609 != nil:
    section.add "X-Amz-Signature", valid_602609
  var valid_602610 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602610 = validateParameter(valid_602610, JString, required = false,
                                 default = nil)
  if valid_602610 != nil:
    section.add "X-Amz-Content-Sha256", valid_602610
  var valid_602611 = header.getOrDefault("X-Amz-Date")
  valid_602611 = validateParameter(valid_602611, JString, required = false,
                                 default = nil)
  if valid_602611 != nil:
    section.add "X-Amz-Date", valid_602611
  var valid_602612 = header.getOrDefault("X-Amz-Credential")
  valid_602612 = validateParameter(valid_602612, JString, required = false,
                                 default = nil)
  if valid_602612 != nil:
    section.add "X-Amz-Credential", valid_602612
  var valid_602613 = header.getOrDefault("X-Amz-Security-Token")
  valid_602613 = validateParameter(valid_602613, JString, required = false,
                                 default = nil)
  if valid_602613 != nil:
    section.add "X-Amz-Security-Token", valid_602613
  var valid_602614 = header.getOrDefault("X-Amz-Algorithm")
  valid_602614 = validateParameter(valid_602614, JString, required = false,
                                 default = nil)
  if valid_602614 != nil:
    section.add "X-Amz-Algorithm", valid_602614
  var valid_602615 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602615 = validateParameter(valid_602615, JString, required = false,
                                 default = nil)
  if valid_602615 != nil:
    section.add "X-Amz-SignedHeaders", valid_602615
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602617: Call_PutEmailIdentityDkimAttributes_602605; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Used to enable or disable DKIM authentication for an email identity.
  ## 
  let valid = call_602617.validator(path, query, header, formData, body)
  let scheme = call_602617.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602617.url(scheme.get, call_602617.host, call_602617.base,
                         call_602617.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602617, url, valid)

proc call*(call_602618: Call_PutEmailIdentityDkimAttributes_602605;
          EmailIdentity: string; body: JsonNode): Recallable =
  ## putEmailIdentityDkimAttributes
  ## Used to enable or disable DKIM authentication for an email identity.
  ##   EmailIdentity: string (required)
  ##                : The email identity that you want to change the DKIM settings for.
  ##   body: JObject (required)
  var path_602619 = newJObject()
  var body_602620 = newJObject()
  add(path_602619, "EmailIdentity", newJString(EmailIdentity))
  if body != nil:
    body_602620 = body
  result = call_602618.call(path_602619, nil, nil, nil, body_602620)

var putEmailIdentityDkimAttributes* = Call_PutEmailIdentityDkimAttributes_602605(
    name: "putEmailIdentityDkimAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com",
    route: "/v2/email/identities/{EmailIdentity}/dkim",
    validator: validate_PutEmailIdentityDkimAttributes_602606, base: "/",
    url: url_PutEmailIdentityDkimAttributes_602607,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEmailIdentityDkimSigningAttributes_602621 = ref object of OpenApiRestCall_601389
proc url_PutEmailIdentityDkimSigningAttributes_602623(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "EmailIdentity" in path, "`EmailIdentity` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/identities/"),
               (kind: VariableSegment, value: "EmailIdentity"),
               (kind: ConstantSegment, value: "/dkim/signing")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutEmailIdentityDkimSigningAttributes_602622(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Used to configure or change the DKIM authentication settings for an email domain identity. You can use this operation to do any of the following:</p> <ul> <li> <p>Update the signing attributes for an identity that uses Bring Your Own DKIM (BYODKIM).</p> </li> <li> <p>Change from using no DKIM authentication to using Easy DKIM.</p> </li> <li> <p>Change from using no DKIM authentication to using BYODKIM.</p> </li> <li> <p>Change from using Easy DKIM to using BYODKIM.</p> </li> <li> <p>Change from using BYODKIM to using Easy DKIM.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   EmailIdentity: JString (required)
  ##                : The email identity that you want to configure DKIM for.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `EmailIdentity` field"
  var valid_602624 = path.getOrDefault("EmailIdentity")
  valid_602624 = validateParameter(valid_602624, JString, required = true,
                                 default = nil)
  if valid_602624 != nil:
    section.add "EmailIdentity", valid_602624
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602625 = header.getOrDefault("X-Amz-Signature")
  valid_602625 = validateParameter(valid_602625, JString, required = false,
                                 default = nil)
  if valid_602625 != nil:
    section.add "X-Amz-Signature", valid_602625
  var valid_602626 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602626 = validateParameter(valid_602626, JString, required = false,
                                 default = nil)
  if valid_602626 != nil:
    section.add "X-Amz-Content-Sha256", valid_602626
  var valid_602627 = header.getOrDefault("X-Amz-Date")
  valid_602627 = validateParameter(valid_602627, JString, required = false,
                                 default = nil)
  if valid_602627 != nil:
    section.add "X-Amz-Date", valid_602627
  var valid_602628 = header.getOrDefault("X-Amz-Credential")
  valid_602628 = validateParameter(valid_602628, JString, required = false,
                                 default = nil)
  if valid_602628 != nil:
    section.add "X-Amz-Credential", valid_602628
  var valid_602629 = header.getOrDefault("X-Amz-Security-Token")
  valid_602629 = validateParameter(valid_602629, JString, required = false,
                                 default = nil)
  if valid_602629 != nil:
    section.add "X-Amz-Security-Token", valid_602629
  var valid_602630 = header.getOrDefault("X-Amz-Algorithm")
  valid_602630 = validateParameter(valid_602630, JString, required = false,
                                 default = nil)
  if valid_602630 != nil:
    section.add "X-Amz-Algorithm", valid_602630
  var valid_602631 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602631 = validateParameter(valid_602631, JString, required = false,
                                 default = nil)
  if valid_602631 != nil:
    section.add "X-Amz-SignedHeaders", valid_602631
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602633: Call_PutEmailIdentityDkimSigningAttributes_602621;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Used to configure or change the DKIM authentication settings for an email domain identity. You can use this operation to do any of the following:</p> <ul> <li> <p>Update the signing attributes for an identity that uses Bring Your Own DKIM (BYODKIM).</p> </li> <li> <p>Change from using no DKIM authentication to using Easy DKIM.</p> </li> <li> <p>Change from using no DKIM authentication to using BYODKIM.</p> </li> <li> <p>Change from using Easy DKIM to using BYODKIM.</p> </li> <li> <p>Change from using BYODKIM to using Easy DKIM.</p> </li> </ul>
  ## 
  let valid = call_602633.validator(path, query, header, formData, body)
  let scheme = call_602633.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602633.url(scheme.get, call_602633.host, call_602633.base,
                         call_602633.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602633, url, valid)

proc call*(call_602634: Call_PutEmailIdentityDkimSigningAttributes_602621;
          EmailIdentity: string; body: JsonNode): Recallable =
  ## putEmailIdentityDkimSigningAttributes
  ## <p>Used to configure or change the DKIM authentication settings for an email domain identity. You can use this operation to do any of the following:</p> <ul> <li> <p>Update the signing attributes for an identity that uses Bring Your Own DKIM (BYODKIM).</p> </li> <li> <p>Change from using no DKIM authentication to using Easy DKIM.</p> </li> <li> <p>Change from using no DKIM authentication to using BYODKIM.</p> </li> <li> <p>Change from using Easy DKIM to using BYODKIM.</p> </li> <li> <p>Change from using BYODKIM to using Easy DKIM.</p> </li> </ul>
  ##   EmailIdentity: string (required)
  ##                : The email identity that you want to configure DKIM for.
  ##   body: JObject (required)
  var path_602635 = newJObject()
  var body_602636 = newJObject()
  add(path_602635, "EmailIdentity", newJString(EmailIdentity))
  if body != nil:
    body_602636 = body
  result = call_602634.call(path_602635, nil, nil, nil, body_602636)

var putEmailIdentityDkimSigningAttributes* = Call_PutEmailIdentityDkimSigningAttributes_602621(
    name: "putEmailIdentityDkimSigningAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com",
    route: "/v1/email/identities/{EmailIdentity}/dkim/signing",
    validator: validate_PutEmailIdentityDkimSigningAttributes_602622, base: "/",
    url: url_PutEmailIdentityDkimSigningAttributes_602623,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEmailIdentityFeedbackAttributes_602637 = ref object of OpenApiRestCall_601389
proc url_PutEmailIdentityFeedbackAttributes_602639(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "EmailIdentity" in path, "`EmailIdentity` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/email/identities/"),
               (kind: VariableSegment, value: "EmailIdentity"),
               (kind: ConstantSegment, value: "/feedback")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutEmailIdentityFeedbackAttributes_602638(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Used to enable or disable feedback forwarding for an identity. This setting determines what happens when an identity is used to send an email that results in a bounce or complaint event.</p> <p>If the value is <code>true</code>, you receive email notifications when bounce or complaint events occur. These notifications are sent to the address that you specified in the <code>Return-Path</code> header of the original email.</p> <p>You're required to have a method of tracking bounces and complaints. If you haven't set up another mechanism for receiving bounce or complaint notifications (for example, by setting up an event destination), you receive an email notification when these events occur (even if this setting is disabled).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   EmailIdentity: JString (required)
  ##                : The email identity that you want to configure bounce and complaint feedback forwarding for.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `EmailIdentity` field"
  var valid_602640 = path.getOrDefault("EmailIdentity")
  valid_602640 = validateParameter(valid_602640, JString, required = true,
                                 default = nil)
  if valid_602640 != nil:
    section.add "EmailIdentity", valid_602640
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602641 = header.getOrDefault("X-Amz-Signature")
  valid_602641 = validateParameter(valid_602641, JString, required = false,
                                 default = nil)
  if valid_602641 != nil:
    section.add "X-Amz-Signature", valid_602641
  var valid_602642 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602642 = validateParameter(valid_602642, JString, required = false,
                                 default = nil)
  if valid_602642 != nil:
    section.add "X-Amz-Content-Sha256", valid_602642
  var valid_602643 = header.getOrDefault("X-Amz-Date")
  valid_602643 = validateParameter(valid_602643, JString, required = false,
                                 default = nil)
  if valid_602643 != nil:
    section.add "X-Amz-Date", valid_602643
  var valid_602644 = header.getOrDefault("X-Amz-Credential")
  valid_602644 = validateParameter(valid_602644, JString, required = false,
                                 default = nil)
  if valid_602644 != nil:
    section.add "X-Amz-Credential", valid_602644
  var valid_602645 = header.getOrDefault("X-Amz-Security-Token")
  valid_602645 = validateParameter(valid_602645, JString, required = false,
                                 default = nil)
  if valid_602645 != nil:
    section.add "X-Amz-Security-Token", valid_602645
  var valid_602646 = header.getOrDefault("X-Amz-Algorithm")
  valid_602646 = validateParameter(valid_602646, JString, required = false,
                                 default = nil)
  if valid_602646 != nil:
    section.add "X-Amz-Algorithm", valid_602646
  var valid_602647 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602647 = validateParameter(valid_602647, JString, required = false,
                                 default = nil)
  if valid_602647 != nil:
    section.add "X-Amz-SignedHeaders", valid_602647
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602649: Call_PutEmailIdentityFeedbackAttributes_602637;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Used to enable or disable feedback forwarding for an identity. This setting determines what happens when an identity is used to send an email that results in a bounce or complaint event.</p> <p>If the value is <code>true</code>, you receive email notifications when bounce or complaint events occur. These notifications are sent to the address that you specified in the <code>Return-Path</code> header of the original email.</p> <p>You're required to have a method of tracking bounces and complaints. If you haven't set up another mechanism for receiving bounce or complaint notifications (for example, by setting up an event destination), you receive an email notification when these events occur (even if this setting is disabled).</p>
  ## 
  let valid = call_602649.validator(path, query, header, formData, body)
  let scheme = call_602649.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602649.url(scheme.get, call_602649.host, call_602649.base,
                         call_602649.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602649, url, valid)

proc call*(call_602650: Call_PutEmailIdentityFeedbackAttributes_602637;
          EmailIdentity: string; body: JsonNode): Recallable =
  ## putEmailIdentityFeedbackAttributes
  ## <p>Used to enable or disable feedback forwarding for an identity. This setting determines what happens when an identity is used to send an email that results in a bounce or complaint event.</p> <p>If the value is <code>true</code>, you receive email notifications when bounce or complaint events occur. These notifications are sent to the address that you specified in the <code>Return-Path</code> header of the original email.</p> <p>You're required to have a method of tracking bounces and complaints. If you haven't set up another mechanism for receiving bounce or complaint notifications (for example, by setting up an event destination), you receive an email notification when these events occur (even if this setting is disabled).</p>
  ##   EmailIdentity: string (required)
  ##                : The email identity that you want to configure bounce and complaint feedback forwarding for.
  ##   body: JObject (required)
  var path_602651 = newJObject()
  var body_602652 = newJObject()
  add(path_602651, "EmailIdentity", newJString(EmailIdentity))
  if body != nil:
    body_602652 = body
  result = call_602650.call(path_602651, nil, nil, nil, body_602652)

var putEmailIdentityFeedbackAttributes* = Call_PutEmailIdentityFeedbackAttributes_602637(
    name: "putEmailIdentityFeedbackAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com",
    route: "/v2/email/identities/{EmailIdentity}/feedback",
    validator: validate_PutEmailIdentityFeedbackAttributes_602638, base: "/",
    url: url_PutEmailIdentityFeedbackAttributes_602639,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEmailIdentityMailFromAttributes_602653 = ref object of OpenApiRestCall_601389
proc url_PutEmailIdentityMailFromAttributes_602655(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "EmailIdentity" in path, "`EmailIdentity` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v2/email/identities/"),
               (kind: VariableSegment, value: "EmailIdentity"),
               (kind: ConstantSegment, value: "/mail-from")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutEmailIdentityMailFromAttributes_602654(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Used to enable or disable the custom Mail-From domain configuration for an email identity.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   EmailIdentity: JString (required)
  ##                : The verified email identity that you want to set up the custom MAIL FROM domain for.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `EmailIdentity` field"
  var valid_602656 = path.getOrDefault("EmailIdentity")
  valid_602656 = validateParameter(valid_602656, JString, required = true,
                                 default = nil)
  if valid_602656 != nil:
    section.add "EmailIdentity", valid_602656
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602657 = header.getOrDefault("X-Amz-Signature")
  valid_602657 = validateParameter(valid_602657, JString, required = false,
                                 default = nil)
  if valid_602657 != nil:
    section.add "X-Amz-Signature", valid_602657
  var valid_602658 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602658 = validateParameter(valid_602658, JString, required = false,
                                 default = nil)
  if valid_602658 != nil:
    section.add "X-Amz-Content-Sha256", valid_602658
  var valid_602659 = header.getOrDefault("X-Amz-Date")
  valid_602659 = validateParameter(valid_602659, JString, required = false,
                                 default = nil)
  if valid_602659 != nil:
    section.add "X-Amz-Date", valid_602659
  var valid_602660 = header.getOrDefault("X-Amz-Credential")
  valid_602660 = validateParameter(valid_602660, JString, required = false,
                                 default = nil)
  if valid_602660 != nil:
    section.add "X-Amz-Credential", valid_602660
  var valid_602661 = header.getOrDefault("X-Amz-Security-Token")
  valid_602661 = validateParameter(valid_602661, JString, required = false,
                                 default = nil)
  if valid_602661 != nil:
    section.add "X-Amz-Security-Token", valid_602661
  var valid_602662 = header.getOrDefault("X-Amz-Algorithm")
  valid_602662 = validateParameter(valid_602662, JString, required = false,
                                 default = nil)
  if valid_602662 != nil:
    section.add "X-Amz-Algorithm", valid_602662
  var valid_602663 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602663 = validateParameter(valid_602663, JString, required = false,
                                 default = nil)
  if valid_602663 != nil:
    section.add "X-Amz-SignedHeaders", valid_602663
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602665: Call_PutEmailIdentityMailFromAttributes_602653;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Used to enable or disable the custom Mail-From domain configuration for an email identity.
  ## 
  let valid = call_602665.validator(path, query, header, formData, body)
  let scheme = call_602665.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602665.url(scheme.get, call_602665.host, call_602665.base,
                         call_602665.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602665, url, valid)

proc call*(call_602666: Call_PutEmailIdentityMailFromAttributes_602653;
          EmailIdentity: string; body: JsonNode): Recallable =
  ## putEmailIdentityMailFromAttributes
  ## Used to enable or disable the custom Mail-From domain configuration for an email identity.
  ##   EmailIdentity: string (required)
  ##                : The verified email identity that you want to set up the custom MAIL FROM domain for.
  ##   body: JObject (required)
  var path_602667 = newJObject()
  var body_602668 = newJObject()
  add(path_602667, "EmailIdentity", newJString(EmailIdentity))
  if body != nil:
    body_602668 = body
  result = call_602666.call(path_602667, nil, nil, nil, body_602668)

var putEmailIdentityMailFromAttributes* = Call_PutEmailIdentityMailFromAttributes_602653(
    name: "putEmailIdentityMailFromAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com",
    route: "/v2/email/identities/{EmailIdentity}/mail-from",
    validator: validate_PutEmailIdentityMailFromAttributes_602654, base: "/",
    url: url_PutEmailIdentityMailFromAttributes_602655,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendEmail_602669 = ref object of OpenApiRestCall_601389
proc url_SendEmail_602671(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SendEmail_602670(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Sends an email message. You can use the Amazon SES API v2 to send two types of messages:</p> <ul> <li> <p> <b>Simple</b> – A standard email message. When you create this type of message, you specify the sender, the recipient, and the message body, and Amazon SES assembles the message for you.</p> </li> <li> <p> <b>Raw</b> – A raw, MIME-formatted email message. When you send this type of email, you have to specify all of the message headers, as well as the message body. You can use this message type to send messages that contain attachments. The message that you specify has to be a valid MIME message.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602672 = header.getOrDefault("X-Amz-Signature")
  valid_602672 = validateParameter(valid_602672, JString, required = false,
                                 default = nil)
  if valid_602672 != nil:
    section.add "X-Amz-Signature", valid_602672
  var valid_602673 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602673 = validateParameter(valid_602673, JString, required = false,
                                 default = nil)
  if valid_602673 != nil:
    section.add "X-Amz-Content-Sha256", valid_602673
  var valid_602674 = header.getOrDefault("X-Amz-Date")
  valid_602674 = validateParameter(valid_602674, JString, required = false,
                                 default = nil)
  if valid_602674 != nil:
    section.add "X-Amz-Date", valid_602674
  var valid_602675 = header.getOrDefault("X-Amz-Credential")
  valid_602675 = validateParameter(valid_602675, JString, required = false,
                                 default = nil)
  if valid_602675 != nil:
    section.add "X-Amz-Credential", valid_602675
  var valid_602676 = header.getOrDefault("X-Amz-Security-Token")
  valid_602676 = validateParameter(valid_602676, JString, required = false,
                                 default = nil)
  if valid_602676 != nil:
    section.add "X-Amz-Security-Token", valid_602676
  var valid_602677 = header.getOrDefault("X-Amz-Algorithm")
  valid_602677 = validateParameter(valid_602677, JString, required = false,
                                 default = nil)
  if valid_602677 != nil:
    section.add "X-Amz-Algorithm", valid_602677
  var valid_602678 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602678 = validateParameter(valid_602678, JString, required = false,
                                 default = nil)
  if valid_602678 != nil:
    section.add "X-Amz-SignedHeaders", valid_602678
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602680: Call_SendEmail_602669; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sends an email message. You can use the Amazon SES API v2 to send two types of messages:</p> <ul> <li> <p> <b>Simple</b> – A standard email message. When you create this type of message, you specify the sender, the recipient, and the message body, and Amazon SES assembles the message for you.</p> </li> <li> <p> <b>Raw</b> – A raw, MIME-formatted email message. When you send this type of email, you have to specify all of the message headers, as well as the message body. You can use this message type to send messages that contain attachments. The message that you specify has to be a valid MIME message.</p> </li> </ul>
  ## 
  let valid = call_602680.validator(path, query, header, formData, body)
  let scheme = call_602680.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602680.url(scheme.get, call_602680.host, call_602680.base,
                         call_602680.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602680, url, valid)

proc call*(call_602681: Call_SendEmail_602669; body: JsonNode): Recallable =
  ## sendEmail
  ## <p>Sends an email message. You can use the Amazon SES API v2 to send two types of messages:</p> <ul> <li> <p> <b>Simple</b> – A standard email message. When you create this type of message, you specify the sender, the recipient, and the message body, and Amazon SES assembles the message for you.</p> </li> <li> <p> <b>Raw</b> – A raw, MIME-formatted email message. When you send this type of email, you have to specify all of the message headers, as well as the message body. You can use this message type to send messages that contain attachments. The message that you specify has to be a valid MIME message.</p> </li> </ul>
  ##   body: JObject (required)
  var body_602682 = newJObject()
  if body != nil:
    body_602682 = body
  result = call_602681.call(nil, nil, nil, nil, body_602682)

var sendEmail* = Call_SendEmail_602669(name: "sendEmail", meth: HttpMethod.HttpPost,
                                    host: "email.amazonaws.com",
                                    route: "/v2/email/outbound-emails",
                                    validator: validate_SendEmail_602670,
                                    base: "/", url: url_SendEmail_602671,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_602683 = ref object of OpenApiRestCall_601389
proc url_TagResource_602685(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_602684(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Add one or more tags (keys and values) to a specified resource. A <i>tag</i> is a label that you optionally define and associate with a resource. Tags can help you categorize and manage resources in different ways, such as by purpose, owner, environment, or other criteria. A resource can have as many as 50 tags.</p> <p>Each tag consists of a required <i>tag key</i> and an associated <i>tag value</i>, both of which you define. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602686 = header.getOrDefault("X-Amz-Signature")
  valid_602686 = validateParameter(valid_602686, JString, required = false,
                                 default = nil)
  if valid_602686 != nil:
    section.add "X-Amz-Signature", valid_602686
  var valid_602687 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602687 = validateParameter(valid_602687, JString, required = false,
                                 default = nil)
  if valid_602687 != nil:
    section.add "X-Amz-Content-Sha256", valid_602687
  var valid_602688 = header.getOrDefault("X-Amz-Date")
  valid_602688 = validateParameter(valid_602688, JString, required = false,
                                 default = nil)
  if valid_602688 != nil:
    section.add "X-Amz-Date", valid_602688
  var valid_602689 = header.getOrDefault("X-Amz-Credential")
  valid_602689 = validateParameter(valid_602689, JString, required = false,
                                 default = nil)
  if valid_602689 != nil:
    section.add "X-Amz-Credential", valid_602689
  var valid_602690 = header.getOrDefault("X-Amz-Security-Token")
  valid_602690 = validateParameter(valid_602690, JString, required = false,
                                 default = nil)
  if valid_602690 != nil:
    section.add "X-Amz-Security-Token", valid_602690
  var valid_602691 = header.getOrDefault("X-Amz-Algorithm")
  valid_602691 = validateParameter(valid_602691, JString, required = false,
                                 default = nil)
  if valid_602691 != nil:
    section.add "X-Amz-Algorithm", valid_602691
  var valid_602692 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602692 = validateParameter(valid_602692, JString, required = false,
                                 default = nil)
  if valid_602692 != nil:
    section.add "X-Amz-SignedHeaders", valid_602692
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602694: Call_TagResource_602683; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Add one or more tags (keys and values) to a specified resource. A <i>tag</i> is a label that you optionally define and associate with a resource. Tags can help you categorize and manage resources in different ways, such as by purpose, owner, environment, or other criteria. A resource can have as many as 50 tags.</p> <p>Each tag consists of a required <i>tag key</i> and an associated <i>tag value</i>, both of which you define. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.</p>
  ## 
  let valid = call_602694.validator(path, query, header, formData, body)
  let scheme = call_602694.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602694.url(scheme.get, call_602694.host, call_602694.base,
                         call_602694.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602694, url, valid)

proc call*(call_602695: Call_TagResource_602683; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Add one or more tags (keys and values) to a specified resource. A <i>tag</i> is a label that you optionally define and associate with a resource. Tags can help you categorize and manage resources in different ways, such as by purpose, owner, environment, or other criteria. A resource can have as many as 50 tags.</p> <p>Each tag consists of a required <i>tag key</i> and an associated <i>tag value</i>, both of which you define. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.</p>
  ##   body: JObject (required)
  var body_602696 = newJObject()
  if body != nil:
    body_602696 = body
  result = call_602695.call(nil, nil, nil, nil, body_602696)

var tagResource* = Call_TagResource_602683(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "email.amazonaws.com",
                                        route: "/v2/email/tags",
                                        validator: validate_TagResource_602684,
                                        base: "/", url: url_TagResource_602685,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_602697 = ref object of OpenApiRestCall_601389
proc url_UntagResource_602699(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_602698(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Remove one or more tags (keys and values) from a specified resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   TagKeys: JArray (required)
  ##          : <p>The tags (tag keys) that you want to remove from the resource. When you specify a tag key, the action removes both that key and its associated tag value.</p> <p>To remove more than one tag from the resource, append the <code>TagKeys</code> parameter and argument for each additional tag to remove, separated by an ampersand. For example: 
  ## <code>/v2/email/tags?ResourceArn=ResourceArn&amp;TagKeys=Key1&amp;TagKeys=Key2</code> </p>
  ##   ResourceArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the resource that you want to remove one or more tags from.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `TagKeys` field"
  var valid_602700 = query.getOrDefault("TagKeys")
  valid_602700 = validateParameter(valid_602700, JArray, required = true, default = nil)
  if valid_602700 != nil:
    section.add "TagKeys", valid_602700
  var valid_602701 = query.getOrDefault("ResourceArn")
  valid_602701 = validateParameter(valid_602701, JString, required = true,
                                 default = nil)
  if valid_602701 != nil:
    section.add "ResourceArn", valid_602701
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_602702 = header.getOrDefault("X-Amz-Signature")
  valid_602702 = validateParameter(valid_602702, JString, required = false,
                                 default = nil)
  if valid_602702 != nil:
    section.add "X-Amz-Signature", valid_602702
  var valid_602703 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602703 = validateParameter(valid_602703, JString, required = false,
                                 default = nil)
  if valid_602703 != nil:
    section.add "X-Amz-Content-Sha256", valid_602703
  var valid_602704 = header.getOrDefault("X-Amz-Date")
  valid_602704 = validateParameter(valid_602704, JString, required = false,
                                 default = nil)
  if valid_602704 != nil:
    section.add "X-Amz-Date", valid_602704
  var valid_602705 = header.getOrDefault("X-Amz-Credential")
  valid_602705 = validateParameter(valid_602705, JString, required = false,
                                 default = nil)
  if valid_602705 != nil:
    section.add "X-Amz-Credential", valid_602705
  var valid_602706 = header.getOrDefault("X-Amz-Security-Token")
  valid_602706 = validateParameter(valid_602706, JString, required = false,
                                 default = nil)
  if valid_602706 != nil:
    section.add "X-Amz-Security-Token", valid_602706
  var valid_602707 = header.getOrDefault("X-Amz-Algorithm")
  valid_602707 = validateParameter(valid_602707, JString, required = false,
                                 default = nil)
  if valid_602707 != nil:
    section.add "X-Amz-Algorithm", valid_602707
  var valid_602708 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602708 = validateParameter(valid_602708, JString, required = false,
                                 default = nil)
  if valid_602708 != nil:
    section.add "X-Amz-SignedHeaders", valid_602708
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602709: Call_UntagResource_602697; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove one or more tags (keys and values) from a specified resource.
  ## 
  let valid = call_602709.validator(path, query, header, formData, body)
  let scheme = call_602709.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602709.url(scheme.get, call_602709.host, call_602709.base,
                         call_602709.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602709, url, valid)

proc call*(call_602710: Call_UntagResource_602697; TagKeys: JsonNode;
          ResourceArn: string): Recallable =
  ## untagResource
  ## Remove one or more tags (keys and values) from a specified resource.
  ##   TagKeys: JArray (required)
  ##          : <p>The tags (tag keys) that you want to remove from the resource. When you specify a tag key, the action removes both that key and its associated tag value.</p> <p>To remove more than one tag from the resource, append the <code>TagKeys</code> parameter and argument for each additional tag to remove, separated by an ampersand. For example: 
  ## <code>/v2/email/tags?ResourceArn=ResourceArn&amp;TagKeys=Key1&amp;TagKeys=Key2</code> </p>
  ##   ResourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource that you want to remove one or more tags from.
  var query_602711 = newJObject()
  if TagKeys != nil:
    query_602711.add "TagKeys", TagKeys
  add(query_602711, "ResourceArn", newJString(ResourceArn))
  result = call_602710.call(nil, query_602711, nil, nil, nil)

var untagResource* = Call_UntagResource_602697(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "email.amazonaws.com",
    route: "/v2/email/tags#ResourceArn&TagKeys",
    validator: validate_UntagResource_602698, base: "/", url: url_UntagResource_602699,
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

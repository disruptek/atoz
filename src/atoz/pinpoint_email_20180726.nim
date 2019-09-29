
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Pinpoint Email Service
## version: 2018-07-26
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon Pinpoint Email Service</fullname> <p>This document contains reference information for the <a href="https://aws.amazon.com/pinpoint">Amazon Pinpoint</a> Email API, version 1.0. This document is best used in conjunction with the <a href="https://docs.aws.amazon.com/pinpoint/latest/developerguide/welcome.html">Amazon Pinpoint Developer Guide</a>.</p> <p>The Amazon Pinpoint Email API is available in several AWS Regions and it provides an endpoint for each of these Regions. For a list of all the Regions and endpoints where the API is currently available, see <a href="https://docs.aws.amazon.com/general/latest/gr/rande.html#pinpoint_region">AWS Regions and Endpoints</a> in the <i>Amazon Web Services General Reference</i>.</p> <p>In each Region, AWS maintains multiple Availability Zones. These Availability Zones are physically isolated from each other, but are united by private, low-latency, high-throughput, and highly redundant network connections. These Availability Zones enable us to provide very high levels of availability and redundancy, while also minimizing latency. To learn more about the number of Availability Zones that are available in each Region, see <a href="http://aws.amazon.com/about-aws/global-infrastructure/">AWS Global Infrastructure</a>.</p>
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

  OpenApiRestCall_593421 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593421](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593421): Option[Scheme] {.used.} =
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
  awsServiceName = "pinpoint-email"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateConfigurationSet_594015 = ref object of OpenApiRestCall_593421
proc url_CreateConfigurationSet_594017(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateConfigurationSet_594016(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Create a configuration set. <i>Configuration sets</i> are groups of rules that you can apply to the emails you send using Amazon Pinpoint. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594018 = header.getOrDefault("X-Amz-Date")
  valid_594018 = validateParameter(valid_594018, JString, required = false,
                                 default = nil)
  if valid_594018 != nil:
    section.add "X-Amz-Date", valid_594018
  var valid_594019 = header.getOrDefault("X-Amz-Security-Token")
  valid_594019 = validateParameter(valid_594019, JString, required = false,
                                 default = nil)
  if valid_594019 != nil:
    section.add "X-Amz-Security-Token", valid_594019
  var valid_594020 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594020 = validateParameter(valid_594020, JString, required = false,
                                 default = nil)
  if valid_594020 != nil:
    section.add "X-Amz-Content-Sha256", valid_594020
  var valid_594021 = header.getOrDefault("X-Amz-Algorithm")
  valid_594021 = validateParameter(valid_594021, JString, required = false,
                                 default = nil)
  if valid_594021 != nil:
    section.add "X-Amz-Algorithm", valid_594021
  var valid_594022 = header.getOrDefault("X-Amz-Signature")
  valid_594022 = validateParameter(valid_594022, JString, required = false,
                                 default = nil)
  if valid_594022 != nil:
    section.add "X-Amz-Signature", valid_594022
  var valid_594023 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594023 = validateParameter(valid_594023, JString, required = false,
                                 default = nil)
  if valid_594023 != nil:
    section.add "X-Amz-SignedHeaders", valid_594023
  var valid_594024 = header.getOrDefault("X-Amz-Credential")
  valid_594024 = validateParameter(valid_594024, JString, required = false,
                                 default = nil)
  if valid_594024 != nil:
    section.add "X-Amz-Credential", valid_594024
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594026: Call_CreateConfigurationSet_594015; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a configuration set. <i>Configuration sets</i> are groups of rules that you can apply to the emails you send using Amazon Pinpoint. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email. 
  ## 
  let valid = call_594026.validator(path, query, header, formData, body)
  let scheme = call_594026.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594026.url(scheme.get, call_594026.host, call_594026.base,
                         call_594026.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594026, url, valid)

proc call*(call_594027: Call_CreateConfigurationSet_594015; body: JsonNode): Recallable =
  ## createConfigurationSet
  ## Create a configuration set. <i>Configuration sets</i> are groups of rules that you can apply to the emails you send using Amazon Pinpoint. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email. 
  ##   body: JObject (required)
  var body_594028 = newJObject()
  if body != nil:
    body_594028 = body
  result = call_594027.call(nil, nil, nil, nil, body_594028)

var createConfigurationSet* = Call_CreateConfigurationSet_594015(
    name: "createConfigurationSet", meth: HttpMethod.HttpPost,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets",
    validator: validate_CreateConfigurationSet_594016, base: "/",
    url: url_CreateConfigurationSet_594017, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigurationSets_593758 = ref object of OpenApiRestCall_593421
proc url_ListConfigurationSets_593760(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListConfigurationSets_593759(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>List all of the configuration sets associated with your Amazon Pinpoint account in the current region.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageSize: JInt
  ##           : The number of results to show in a single call to <code>ListConfigurationSets</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  ##   NextToken: JString
  ##            : A token returned from a previous call to <code>ListConfigurationSets</code> to indicate the position in the list of configuration sets.
  section = newJObject()
  var valid_593872 = query.getOrDefault("PageSize")
  valid_593872 = validateParameter(valid_593872, JInt, required = false, default = nil)
  if valid_593872 != nil:
    section.add "PageSize", valid_593872
  var valid_593873 = query.getOrDefault("NextToken")
  valid_593873 = validateParameter(valid_593873, JString, required = false,
                                 default = nil)
  if valid_593873 != nil:
    section.add "NextToken", valid_593873
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_593874 = header.getOrDefault("X-Amz-Date")
  valid_593874 = validateParameter(valid_593874, JString, required = false,
                                 default = nil)
  if valid_593874 != nil:
    section.add "X-Amz-Date", valid_593874
  var valid_593875 = header.getOrDefault("X-Amz-Security-Token")
  valid_593875 = validateParameter(valid_593875, JString, required = false,
                                 default = nil)
  if valid_593875 != nil:
    section.add "X-Amz-Security-Token", valid_593875
  var valid_593876 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593876 = validateParameter(valid_593876, JString, required = false,
                                 default = nil)
  if valid_593876 != nil:
    section.add "X-Amz-Content-Sha256", valid_593876
  var valid_593877 = header.getOrDefault("X-Amz-Algorithm")
  valid_593877 = validateParameter(valid_593877, JString, required = false,
                                 default = nil)
  if valid_593877 != nil:
    section.add "X-Amz-Algorithm", valid_593877
  var valid_593878 = header.getOrDefault("X-Amz-Signature")
  valid_593878 = validateParameter(valid_593878, JString, required = false,
                                 default = nil)
  if valid_593878 != nil:
    section.add "X-Amz-Signature", valid_593878
  var valid_593879 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593879 = validateParameter(valid_593879, JString, required = false,
                                 default = nil)
  if valid_593879 != nil:
    section.add "X-Amz-SignedHeaders", valid_593879
  var valid_593880 = header.getOrDefault("X-Amz-Credential")
  valid_593880 = validateParameter(valid_593880, JString, required = false,
                                 default = nil)
  if valid_593880 != nil:
    section.add "X-Amz-Credential", valid_593880
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593903: Call_ListConfigurationSets_593758; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>List all of the configuration sets associated with your Amazon Pinpoint account in the current region.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ## 
  let valid = call_593903.validator(path, query, header, formData, body)
  let scheme = call_593903.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593903.url(scheme.get, call_593903.host, call_593903.base,
                         call_593903.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593903, url, valid)

proc call*(call_593974: Call_ListConfigurationSets_593758; PageSize: int = 0;
          NextToken: string = ""): Recallable =
  ## listConfigurationSets
  ## <p>List all of the configuration sets associated with your Amazon Pinpoint account in the current region.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   PageSize: int
  ##           : The number of results to show in a single call to <code>ListConfigurationSets</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  ##   NextToken: string
  ##            : A token returned from a previous call to <code>ListConfigurationSets</code> to indicate the position in the list of configuration sets.
  var query_593975 = newJObject()
  add(query_593975, "PageSize", newJInt(PageSize))
  add(query_593975, "NextToken", newJString(NextToken))
  result = call_593974.call(nil, query_593975, nil, nil, nil)

var listConfigurationSets* = Call_ListConfigurationSets_593758(
    name: "listConfigurationSets", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets",
    validator: validate_ListConfigurationSets_593759, base: "/",
    url: url_ListConfigurationSets_593760, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConfigurationSetEventDestination_594057 = ref object of OpenApiRestCall_593421
proc url_CreateConfigurationSetEventDestination_594059(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
        "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/configuration-sets/"),
               (kind: VariableSegment, value: "ConfigurationSetName"),
               (kind: ConstantSegment, value: "/event-destinations")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_CreateConfigurationSetEventDestination_594058(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Create an event destination. In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p> <p>A single configuration set can include more than one event destination.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_594060 = path.getOrDefault("ConfigurationSetName")
  valid_594060 = validateParameter(valid_594060, JString, required = true,
                                 default = nil)
  if valid_594060 != nil:
    section.add "ConfigurationSetName", valid_594060
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594061 = header.getOrDefault("X-Amz-Date")
  valid_594061 = validateParameter(valid_594061, JString, required = false,
                                 default = nil)
  if valid_594061 != nil:
    section.add "X-Amz-Date", valid_594061
  var valid_594062 = header.getOrDefault("X-Amz-Security-Token")
  valid_594062 = validateParameter(valid_594062, JString, required = false,
                                 default = nil)
  if valid_594062 != nil:
    section.add "X-Amz-Security-Token", valid_594062
  var valid_594063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594063 = validateParameter(valid_594063, JString, required = false,
                                 default = nil)
  if valid_594063 != nil:
    section.add "X-Amz-Content-Sha256", valid_594063
  var valid_594064 = header.getOrDefault("X-Amz-Algorithm")
  valid_594064 = validateParameter(valid_594064, JString, required = false,
                                 default = nil)
  if valid_594064 != nil:
    section.add "X-Amz-Algorithm", valid_594064
  var valid_594065 = header.getOrDefault("X-Amz-Signature")
  valid_594065 = validateParameter(valid_594065, JString, required = false,
                                 default = nil)
  if valid_594065 != nil:
    section.add "X-Amz-Signature", valid_594065
  var valid_594066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594066 = validateParameter(valid_594066, JString, required = false,
                                 default = nil)
  if valid_594066 != nil:
    section.add "X-Amz-SignedHeaders", valid_594066
  var valid_594067 = header.getOrDefault("X-Amz-Credential")
  valid_594067 = validateParameter(valid_594067, JString, required = false,
                                 default = nil)
  if valid_594067 != nil:
    section.add "X-Amz-Credential", valid_594067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594069: Call_CreateConfigurationSetEventDestination_594057;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Create an event destination. In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p> <p>A single configuration set can include more than one event destination.</p>
  ## 
  let valid = call_594069.validator(path, query, header, formData, body)
  let scheme = call_594069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594069.url(scheme.get, call_594069.host, call_594069.base,
                         call_594069.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594069, url, valid)

proc call*(call_594070: Call_CreateConfigurationSetEventDestination_594057;
          ConfigurationSetName: string; body: JsonNode): Recallable =
  ## createConfigurationSetEventDestination
  ## <p>Create an event destination. In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p> <p>A single configuration set can include more than one event destination.</p>
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   body: JObject (required)
  var path_594071 = newJObject()
  var body_594072 = newJObject()
  add(path_594071, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_594072 = body
  result = call_594070.call(path_594071, nil, nil, nil, body_594072)

var createConfigurationSetEventDestination* = Call_CreateConfigurationSetEventDestination_594057(
    name: "createConfigurationSetEventDestination", meth: HttpMethod.HttpPost,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets/{ConfigurationSetName}/event-destinations",
    validator: validate_CreateConfigurationSetEventDestination_594058, base: "/",
    url: url_CreateConfigurationSetEventDestination_594059,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfigurationSetEventDestinations_594029 = ref object of OpenApiRestCall_593421
proc url_GetConfigurationSetEventDestinations_594031(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
        "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/configuration-sets/"),
               (kind: VariableSegment, value: "ConfigurationSetName"),
               (kind: ConstantSegment, value: "/event-destinations")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetConfigurationSetEventDestinations_594030(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieve a list of event destinations that are associated with a configuration set.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_594046 = path.getOrDefault("ConfigurationSetName")
  valid_594046 = validateParameter(valid_594046, JString, required = true,
                                 default = nil)
  if valid_594046 != nil:
    section.add "ConfigurationSetName", valid_594046
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594047 = header.getOrDefault("X-Amz-Date")
  valid_594047 = validateParameter(valid_594047, JString, required = false,
                                 default = nil)
  if valid_594047 != nil:
    section.add "X-Amz-Date", valid_594047
  var valid_594048 = header.getOrDefault("X-Amz-Security-Token")
  valid_594048 = validateParameter(valid_594048, JString, required = false,
                                 default = nil)
  if valid_594048 != nil:
    section.add "X-Amz-Security-Token", valid_594048
  var valid_594049 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594049 = validateParameter(valid_594049, JString, required = false,
                                 default = nil)
  if valid_594049 != nil:
    section.add "X-Amz-Content-Sha256", valid_594049
  var valid_594050 = header.getOrDefault("X-Amz-Algorithm")
  valid_594050 = validateParameter(valid_594050, JString, required = false,
                                 default = nil)
  if valid_594050 != nil:
    section.add "X-Amz-Algorithm", valid_594050
  var valid_594051 = header.getOrDefault("X-Amz-Signature")
  valid_594051 = validateParameter(valid_594051, JString, required = false,
                                 default = nil)
  if valid_594051 != nil:
    section.add "X-Amz-Signature", valid_594051
  var valid_594052 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594052 = validateParameter(valid_594052, JString, required = false,
                                 default = nil)
  if valid_594052 != nil:
    section.add "X-Amz-SignedHeaders", valid_594052
  var valid_594053 = header.getOrDefault("X-Amz-Credential")
  valid_594053 = validateParameter(valid_594053, JString, required = false,
                                 default = nil)
  if valid_594053 != nil:
    section.add "X-Amz-Credential", valid_594053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594054: Call_GetConfigurationSetEventDestinations_594029;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Retrieve a list of event destinations that are associated with a configuration set.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ## 
  let valid = call_594054.validator(path, query, header, formData, body)
  let scheme = call_594054.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594054.url(scheme.get, call_594054.host, call_594054.base,
                         call_594054.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594054, url, valid)

proc call*(call_594055: Call_GetConfigurationSetEventDestinations_594029;
          ConfigurationSetName: string): Recallable =
  ## getConfigurationSetEventDestinations
  ## <p>Retrieve a list of event destinations that are associated with a configuration set.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  var path_594056 = newJObject()
  add(path_594056, "ConfigurationSetName", newJString(ConfigurationSetName))
  result = call_594055.call(path_594056, nil, nil, nil, nil)

var getConfigurationSetEventDestinations* = Call_GetConfigurationSetEventDestinations_594029(
    name: "getConfigurationSetEventDestinations", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets/{ConfigurationSetName}/event-destinations",
    validator: validate_GetConfigurationSetEventDestinations_594030, base: "/",
    url: url_GetConfigurationSetEventDestinations_594031,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDedicatedIpPool_594088 = ref object of OpenApiRestCall_593421
proc url_CreateDedicatedIpPool_594090(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDedicatedIpPool_594089(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Create a new pool of dedicated IP addresses. A pool can include one or more dedicated IP addresses that are associated with your Amazon Pinpoint account. You can associate a pool with a configuration set. When you send an email that uses that configuration set, Amazon Pinpoint sends it using only the IP addresses in the associated pool.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594091 = header.getOrDefault("X-Amz-Date")
  valid_594091 = validateParameter(valid_594091, JString, required = false,
                                 default = nil)
  if valid_594091 != nil:
    section.add "X-Amz-Date", valid_594091
  var valid_594092 = header.getOrDefault("X-Amz-Security-Token")
  valid_594092 = validateParameter(valid_594092, JString, required = false,
                                 default = nil)
  if valid_594092 != nil:
    section.add "X-Amz-Security-Token", valid_594092
  var valid_594093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594093 = validateParameter(valid_594093, JString, required = false,
                                 default = nil)
  if valid_594093 != nil:
    section.add "X-Amz-Content-Sha256", valid_594093
  var valid_594094 = header.getOrDefault("X-Amz-Algorithm")
  valid_594094 = validateParameter(valid_594094, JString, required = false,
                                 default = nil)
  if valid_594094 != nil:
    section.add "X-Amz-Algorithm", valid_594094
  var valid_594095 = header.getOrDefault("X-Amz-Signature")
  valid_594095 = validateParameter(valid_594095, JString, required = false,
                                 default = nil)
  if valid_594095 != nil:
    section.add "X-Amz-Signature", valid_594095
  var valid_594096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594096 = validateParameter(valid_594096, JString, required = false,
                                 default = nil)
  if valid_594096 != nil:
    section.add "X-Amz-SignedHeaders", valid_594096
  var valid_594097 = header.getOrDefault("X-Amz-Credential")
  valid_594097 = validateParameter(valid_594097, JString, required = false,
                                 default = nil)
  if valid_594097 != nil:
    section.add "X-Amz-Credential", valid_594097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594099: Call_CreateDedicatedIpPool_594088; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new pool of dedicated IP addresses. A pool can include one or more dedicated IP addresses that are associated with your Amazon Pinpoint account. You can associate a pool with a configuration set. When you send an email that uses that configuration set, Amazon Pinpoint sends it using only the IP addresses in the associated pool.
  ## 
  let valid = call_594099.validator(path, query, header, formData, body)
  let scheme = call_594099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594099.url(scheme.get, call_594099.host, call_594099.base,
                         call_594099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594099, url, valid)

proc call*(call_594100: Call_CreateDedicatedIpPool_594088; body: JsonNode): Recallable =
  ## createDedicatedIpPool
  ## Create a new pool of dedicated IP addresses. A pool can include one or more dedicated IP addresses that are associated with your Amazon Pinpoint account. You can associate a pool with a configuration set. When you send an email that uses that configuration set, Amazon Pinpoint sends it using only the IP addresses in the associated pool.
  ##   body: JObject (required)
  var body_594101 = newJObject()
  if body != nil:
    body_594101 = body
  result = call_594100.call(nil, nil, nil, nil, body_594101)

var createDedicatedIpPool* = Call_CreateDedicatedIpPool_594088(
    name: "createDedicatedIpPool", meth: HttpMethod.HttpPost,
    host: "email.amazonaws.com", route: "/v1/email/dedicated-ip-pools",
    validator: validate_CreateDedicatedIpPool_594089, base: "/",
    url: url_CreateDedicatedIpPool_594090, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDedicatedIpPools_594073 = ref object of OpenApiRestCall_593421
proc url_ListDedicatedIpPools_594075(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDedicatedIpPools_594074(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## List all of the dedicated IP pools that exist in your Amazon Pinpoint account in the current AWS Region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageSize: JInt
  ##           : The number of results to show in a single call to <code>ListDedicatedIpPools</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  ##   NextToken: JString
  ##            : A token returned from a previous call to <code>ListDedicatedIpPools</code> to indicate the position in the list of dedicated IP pools.
  section = newJObject()
  var valid_594076 = query.getOrDefault("PageSize")
  valid_594076 = validateParameter(valid_594076, JInt, required = false, default = nil)
  if valid_594076 != nil:
    section.add "PageSize", valid_594076
  var valid_594077 = query.getOrDefault("NextToken")
  valid_594077 = validateParameter(valid_594077, JString, required = false,
                                 default = nil)
  if valid_594077 != nil:
    section.add "NextToken", valid_594077
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594078 = header.getOrDefault("X-Amz-Date")
  valid_594078 = validateParameter(valid_594078, JString, required = false,
                                 default = nil)
  if valid_594078 != nil:
    section.add "X-Amz-Date", valid_594078
  var valid_594079 = header.getOrDefault("X-Amz-Security-Token")
  valid_594079 = validateParameter(valid_594079, JString, required = false,
                                 default = nil)
  if valid_594079 != nil:
    section.add "X-Amz-Security-Token", valid_594079
  var valid_594080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594080 = validateParameter(valid_594080, JString, required = false,
                                 default = nil)
  if valid_594080 != nil:
    section.add "X-Amz-Content-Sha256", valid_594080
  var valid_594081 = header.getOrDefault("X-Amz-Algorithm")
  valid_594081 = validateParameter(valid_594081, JString, required = false,
                                 default = nil)
  if valid_594081 != nil:
    section.add "X-Amz-Algorithm", valid_594081
  var valid_594082 = header.getOrDefault("X-Amz-Signature")
  valid_594082 = validateParameter(valid_594082, JString, required = false,
                                 default = nil)
  if valid_594082 != nil:
    section.add "X-Amz-Signature", valid_594082
  var valid_594083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594083 = validateParameter(valid_594083, JString, required = false,
                                 default = nil)
  if valid_594083 != nil:
    section.add "X-Amz-SignedHeaders", valid_594083
  var valid_594084 = header.getOrDefault("X-Amz-Credential")
  valid_594084 = validateParameter(valid_594084, JString, required = false,
                                 default = nil)
  if valid_594084 != nil:
    section.add "X-Amz-Credential", valid_594084
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594085: Call_ListDedicatedIpPools_594073; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List all of the dedicated IP pools that exist in your Amazon Pinpoint account in the current AWS Region.
  ## 
  let valid = call_594085.validator(path, query, header, formData, body)
  let scheme = call_594085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594085.url(scheme.get, call_594085.host, call_594085.base,
                         call_594085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594085, url, valid)

proc call*(call_594086: Call_ListDedicatedIpPools_594073; PageSize: int = 0;
          NextToken: string = ""): Recallable =
  ## listDedicatedIpPools
  ## List all of the dedicated IP pools that exist in your Amazon Pinpoint account in the current AWS Region.
  ##   PageSize: int
  ##           : The number of results to show in a single call to <code>ListDedicatedIpPools</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  ##   NextToken: string
  ##            : A token returned from a previous call to <code>ListDedicatedIpPools</code> to indicate the position in the list of dedicated IP pools.
  var query_594087 = newJObject()
  add(query_594087, "PageSize", newJInt(PageSize))
  add(query_594087, "NextToken", newJString(NextToken))
  result = call_594086.call(nil, query_594087, nil, nil, nil)

var listDedicatedIpPools* = Call_ListDedicatedIpPools_594073(
    name: "listDedicatedIpPools", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/dedicated-ip-pools",
    validator: validate_ListDedicatedIpPools_594074, base: "/",
    url: url_ListDedicatedIpPools_594075, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeliverabilityTestReport_594102 = ref object of OpenApiRestCall_593421
proc url_CreateDeliverabilityTestReport_594104(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDeliverabilityTestReport_594103(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Create a new predictive inbox placement test. Predictive inbox placement tests can help you predict how your messages will be handled by various email providers around the world. When you perform a predictive inbox placement test, you provide a sample message that contains the content that you plan to send to your customers. Amazon Pinpoint then sends that message to special email addresses spread across several major email providers. After about 24 hours, the test is complete, and you can use the <code>GetDeliverabilityTestReport</code> operation to view the results of the test.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594105 = header.getOrDefault("X-Amz-Date")
  valid_594105 = validateParameter(valid_594105, JString, required = false,
                                 default = nil)
  if valid_594105 != nil:
    section.add "X-Amz-Date", valid_594105
  var valid_594106 = header.getOrDefault("X-Amz-Security-Token")
  valid_594106 = validateParameter(valid_594106, JString, required = false,
                                 default = nil)
  if valid_594106 != nil:
    section.add "X-Amz-Security-Token", valid_594106
  var valid_594107 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594107 = validateParameter(valid_594107, JString, required = false,
                                 default = nil)
  if valid_594107 != nil:
    section.add "X-Amz-Content-Sha256", valid_594107
  var valid_594108 = header.getOrDefault("X-Amz-Algorithm")
  valid_594108 = validateParameter(valid_594108, JString, required = false,
                                 default = nil)
  if valid_594108 != nil:
    section.add "X-Amz-Algorithm", valid_594108
  var valid_594109 = header.getOrDefault("X-Amz-Signature")
  valid_594109 = validateParameter(valid_594109, JString, required = false,
                                 default = nil)
  if valid_594109 != nil:
    section.add "X-Amz-Signature", valid_594109
  var valid_594110 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594110 = validateParameter(valid_594110, JString, required = false,
                                 default = nil)
  if valid_594110 != nil:
    section.add "X-Amz-SignedHeaders", valid_594110
  var valid_594111 = header.getOrDefault("X-Amz-Credential")
  valid_594111 = validateParameter(valid_594111, JString, required = false,
                                 default = nil)
  if valid_594111 != nil:
    section.add "X-Amz-Credential", valid_594111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594113: Call_CreateDeliverabilityTestReport_594102; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new predictive inbox placement test. Predictive inbox placement tests can help you predict how your messages will be handled by various email providers around the world. When you perform a predictive inbox placement test, you provide a sample message that contains the content that you plan to send to your customers. Amazon Pinpoint then sends that message to special email addresses spread across several major email providers. After about 24 hours, the test is complete, and you can use the <code>GetDeliverabilityTestReport</code> operation to view the results of the test.
  ## 
  let valid = call_594113.validator(path, query, header, formData, body)
  let scheme = call_594113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594113.url(scheme.get, call_594113.host, call_594113.base,
                         call_594113.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594113, url, valid)

proc call*(call_594114: Call_CreateDeliverabilityTestReport_594102; body: JsonNode): Recallable =
  ## createDeliverabilityTestReport
  ## Create a new predictive inbox placement test. Predictive inbox placement tests can help you predict how your messages will be handled by various email providers around the world. When you perform a predictive inbox placement test, you provide a sample message that contains the content that you plan to send to your customers. Amazon Pinpoint then sends that message to special email addresses spread across several major email providers. After about 24 hours, the test is complete, and you can use the <code>GetDeliverabilityTestReport</code> operation to view the results of the test.
  ##   body: JObject (required)
  var body_594115 = newJObject()
  if body != nil:
    body_594115 = body
  result = call_594114.call(nil, nil, nil, nil, body_594115)

var createDeliverabilityTestReport* = Call_CreateDeliverabilityTestReport_594102(
    name: "createDeliverabilityTestReport", meth: HttpMethod.HttpPost,
    host: "email.amazonaws.com", route: "/v1/email/deliverability-dashboard/test",
    validator: validate_CreateDeliverabilityTestReport_594103, base: "/",
    url: url_CreateDeliverabilityTestReport_594104,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEmailIdentity_594131 = ref object of OpenApiRestCall_593421
proc url_CreateEmailIdentity_594133(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateEmailIdentity_594132(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Verifies an email identity for use with Amazon Pinpoint. In Amazon Pinpoint, an identity is an email address or domain that you use when you send email. Before you can use an identity to send email with Amazon Pinpoint, you first have to verify it. By verifying an address, you demonstrate that you're the owner of the address, and that you've given Amazon Pinpoint permission to send email from the address.</p> <p>When you verify an email address, Amazon Pinpoint sends an email to the address. Your email address is verified as soon as you follow the link in the verification email. </p> <p>When you verify a domain, this operation provides a set of DKIM tokens, which you can convert into CNAME tokens. You add these CNAME tokens to the DNS configuration for your domain. Your domain is verified when Amazon Pinpoint detects these records in the DNS configuration for your domain. It usually takes around 72 hours to complete the domain verification process.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594134 = header.getOrDefault("X-Amz-Date")
  valid_594134 = validateParameter(valid_594134, JString, required = false,
                                 default = nil)
  if valid_594134 != nil:
    section.add "X-Amz-Date", valid_594134
  var valid_594135 = header.getOrDefault("X-Amz-Security-Token")
  valid_594135 = validateParameter(valid_594135, JString, required = false,
                                 default = nil)
  if valid_594135 != nil:
    section.add "X-Amz-Security-Token", valid_594135
  var valid_594136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594136 = validateParameter(valid_594136, JString, required = false,
                                 default = nil)
  if valid_594136 != nil:
    section.add "X-Amz-Content-Sha256", valid_594136
  var valid_594137 = header.getOrDefault("X-Amz-Algorithm")
  valid_594137 = validateParameter(valid_594137, JString, required = false,
                                 default = nil)
  if valid_594137 != nil:
    section.add "X-Amz-Algorithm", valid_594137
  var valid_594138 = header.getOrDefault("X-Amz-Signature")
  valid_594138 = validateParameter(valid_594138, JString, required = false,
                                 default = nil)
  if valid_594138 != nil:
    section.add "X-Amz-Signature", valid_594138
  var valid_594139 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594139 = validateParameter(valid_594139, JString, required = false,
                                 default = nil)
  if valid_594139 != nil:
    section.add "X-Amz-SignedHeaders", valid_594139
  var valid_594140 = header.getOrDefault("X-Amz-Credential")
  valid_594140 = validateParameter(valid_594140, JString, required = false,
                                 default = nil)
  if valid_594140 != nil:
    section.add "X-Amz-Credential", valid_594140
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594142: Call_CreateEmailIdentity_594131; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Verifies an email identity for use with Amazon Pinpoint. In Amazon Pinpoint, an identity is an email address or domain that you use when you send email. Before you can use an identity to send email with Amazon Pinpoint, you first have to verify it. By verifying an address, you demonstrate that you're the owner of the address, and that you've given Amazon Pinpoint permission to send email from the address.</p> <p>When you verify an email address, Amazon Pinpoint sends an email to the address. Your email address is verified as soon as you follow the link in the verification email. </p> <p>When you verify a domain, this operation provides a set of DKIM tokens, which you can convert into CNAME tokens. You add these CNAME tokens to the DNS configuration for your domain. Your domain is verified when Amazon Pinpoint detects these records in the DNS configuration for your domain. It usually takes around 72 hours to complete the domain verification process.</p>
  ## 
  let valid = call_594142.validator(path, query, header, formData, body)
  let scheme = call_594142.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594142.url(scheme.get, call_594142.host, call_594142.base,
                         call_594142.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594142, url, valid)

proc call*(call_594143: Call_CreateEmailIdentity_594131; body: JsonNode): Recallable =
  ## createEmailIdentity
  ## <p>Verifies an email identity for use with Amazon Pinpoint. In Amazon Pinpoint, an identity is an email address or domain that you use when you send email. Before you can use an identity to send email with Amazon Pinpoint, you first have to verify it. By verifying an address, you demonstrate that you're the owner of the address, and that you've given Amazon Pinpoint permission to send email from the address.</p> <p>When you verify an email address, Amazon Pinpoint sends an email to the address. Your email address is verified as soon as you follow the link in the verification email. </p> <p>When you verify a domain, this operation provides a set of DKIM tokens, which you can convert into CNAME tokens. You add these CNAME tokens to the DNS configuration for your domain. Your domain is verified when Amazon Pinpoint detects these records in the DNS configuration for your domain. It usually takes around 72 hours to complete the domain verification process.</p>
  ##   body: JObject (required)
  var body_594144 = newJObject()
  if body != nil:
    body_594144 = body
  result = call_594143.call(nil, nil, nil, nil, body_594144)

var createEmailIdentity* = Call_CreateEmailIdentity_594131(
    name: "createEmailIdentity", meth: HttpMethod.HttpPost,
    host: "email.amazonaws.com", route: "/v1/email/identities",
    validator: validate_CreateEmailIdentity_594132, base: "/",
    url: url_CreateEmailIdentity_594133, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEmailIdentities_594116 = ref object of OpenApiRestCall_593421
proc url_ListEmailIdentities_594118(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListEmailIdentities_594117(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns a list of all of the email identities that are associated with your Amazon Pinpoint account. An identity can be either an email address or a domain. This operation returns identities that are verified as well as those that aren't.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageSize: JInt
  ##           : <p>The number of results to show in a single call to <code>ListEmailIdentities</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.</p> <p>The value you specify has to be at least 0, and can be no more than 1000.</p>
  ##   NextToken: JString
  ##            : A token returned from a previous call to <code>ListEmailIdentities</code> to indicate the position in the list of identities.
  section = newJObject()
  var valid_594119 = query.getOrDefault("PageSize")
  valid_594119 = validateParameter(valid_594119, JInt, required = false, default = nil)
  if valid_594119 != nil:
    section.add "PageSize", valid_594119
  var valid_594120 = query.getOrDefault("NextToken")
  valid_594120 = validateParameter(valid_594120, JString, required = false,
                                 default = nil)
  if valid_594120 != nil:
    section.add "NextToken", valid_594120
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594121 = header.getOrDefault("X-Amz-Date")
  valid_594121 = validateParameter(valid_594121, JString, required = false,
                                 default = nil)
  if valid_594121 != nil:
    section.add "X-Amz-Date", valid_594121
  var valid_594122 = header.getOrDefault("X-Amz-Security-Token")
  valid_594122 = validateParameter(valid_594122, JString, required = false,
                                 default = nil)
  if valid_594122 != nil:
    section.add "X-Amz-Security-Token", valid_594122
  var valid_594123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594123 = validateParameter(valid_594123, JString, required = false,
                                 default = nil)
  if valid_594123 != nil:
    section.add "X-Amz-Content-Sha256", valid_594123
  var valid_594124 = header.getOrDefault("X-Amz-Algorithm")
  valid_594124 = validateParameter(valid_594124, JString, required = false,
                                 default = nil)
  if valid_594124 != nil:
    section.add "X-Amz-Algorithm", valid_594124
  var valid_594125 = header.getOrDefault("X-Amz-Signature")
  valid_594125 = validateParameter(valid_594125, JString, required = false,
                                 default = nil)
  if valid_594125 != nil:
    section.add "X-Amz-Signature", valid_594125
  var valid_594126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594126 = validateParameter(valid_594126, JString, required = false,
                                 default = nil)
  if valid_594126 != nil:
    section.add "X-Amz-SignedHeaders", valid_594126
  var valid_594127 = header.getOrDefault("X-Amz-Credential")
  valid_594127 = validateParameter(valid_594127, JString, required = false,
                                 default = nil)
  if valid_594127 != nil:
    section.add "X-Amz-Credential", valid_594127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594128: Call_ListEmailIdentities_594116; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all of the email identities that are associated with your Amazon Pinpoint account. An identity can be either an email address or a domain. This operation returns identities that are verified as well as those that aren't.
  ## 
  let valid = call_594128.validator(path, query, header, formData, body)
  let scheme = call_594128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594128.url(scheme.get, call_594128.host, call_594128.base,
                         call_594128.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594128, url, valid)

proc call*(call_594129: Call_ListEmailIdentities_594116; PageSize: int = 0;
          NextToken: string = ""): Recallable =
  ## listEmailIdentities
  ## Returns a list of all of the email identities that are associated with your Amazon Pinpoint account. An identity can be either an email address or a domain. This operation returns identities that are verified as well as those that aren't.
  ##   PageSize: int
  ##           : <p>The number of results to show in a single call to <code>ListEmailIdentities</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.</p> <p>The value you specify has to be at least 0, and can be no more than 1000.</p>
  ##   NextToken: string
  ##            : A token returned from a previous call to <code>ListEmailIdentities</code> to indicate the position in the list of identities.
  var query_594130 = newJObject()
  add(query_594130, "PageSize", newJInt(PageSize))
  add(query_594130, "NextToken", newJString(NextToken))
  result = call_594129.call(nil, query_594130, nil, nil, nil)

var listEmailIdentities* = Call_ListEmailIdentities_594116(
    name: "listEmailIdentities", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/identities",
    validator: validate_ListEmailIdentities_594117, base: "/",
    url: url_ListEmailIdentities_594118, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfigurationSet_594145 = ref object of OpenApiRestCall_593421
proc url_GetConfigurationSet_594147(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
        "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/configuration-sets/"),
               (kind: VariableSegment, value: "ConfigurationSetName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetConfigurationSet_594146(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Get information about an existing configuration set, including the dedicated IP pool that it's associated with, whether or not it's enabled for sending email, and more.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_594148 = path.getOrDefault("ConfigurationSetName")
  valid_594148 = validateParameter(valid_594148, JString, required = true,
                                 default = nil)
  if valid_594148 != nil:
    section.add "ConfigurationSetName", valid_594148
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594149 = header.getOrDefault("X-Amz-Date")
  valid_594149 = validateParameter(valid_594149, JString, required = false,
                                 default = nil)
  if valid_594149 != nil:
    section.add "X-Amz-Date", valid_594149
  var valid_594150 = header.getOrDefault("X-Amz-Security-Token")
  valid_594150 = validateParameter(valid_594150, JString, required = false,
                                 default = nil)
  if valid_594150 != nil:
    section.add "X-Amz-Security-Token", valid_594150
  var valid_594151 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594151 = validateParameter(valid_594151, JString, required = false,
                                 default = nil)
  if valid_594151 != nil:
    section.add "X-Amz-Content-Sha256", valid_594151
  var valid_594152 = header.getOrDefault("X-Amz-Algorithm")
  valid_594152 = validateParameter(valid_594152, JString, required = false,
                                 default = nil)
  if valid_594152 != nil:
    section.add "X-Amz-Algorithm", valid_594152
  var valid_594153 = header.getOrDefault("X-Amz-Signature")
  valid_594153 = validateParameter(valid_594153, JString, required = false,
                                 default = nil)
  if valid_594153 != nil:
    section.add "X-Amz-Signature", valid_594153
  var valid_594154 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594154 = validateParameter(valid_594154, JString, required = false,
                                 default = nil)
  if valid_594154 != nil:
    section.add "X-Amz-SignedHeaders", valid_594154
  var valid_594155 = header.getOrDefault("X-Amz-Credential")
  valid_594155 = validateParameter(valid_594155, JString, required = false,
                                 default = nil)
  if valid_594155 != nil:
    section.add "X-Amz-Credential", valid_594155
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594156: Call_GetConfigurationSet_594145; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Get information about an existing configuration set, including the dedicated IP pool that it's associated with, whether or not it's enabled for sending email, and more.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ## 
  let valid = call_594156.validator(path, query, header, formData, body)
  let scheme = call_594156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594156.url(scheme.get, call_594156.host, call_594156.base,
                         call_594156.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594156, url, valid)

proc call*(call_594157: Call_GetConfigurationSet_594145;
          ConfigurationSetName: string): Recallable =
  ## getConfigurationSet
  ## <p>Get information about an existing configuration set, including the dedicated IP pool that it's associated with, whether or not it's enabled for sending email, and more.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  var path_594158 = newJObject()
  add(path_594158, "ConfigurationSetName", newJString(ConfigurationSetName))
  result = call_594157.call(path_594158, nil, nil, nil, nil)

var getConfigurationSet* = Call_GetConfigurationSet_594145(
    name: "getConfigurationSet", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com",
    route: "/v1/email/configuration-sets/{ConfigurationSetName}",
    validator: validate_GetConfigurationSet_594146, base: "/",
    url: url_GetConfigurationSet_594147, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfigurationSet_594159 = ref object of OpenApiRestCall_593421
proc url_DeleteConfigurationSet_594161(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
        "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/configuration-sets/"),
               (kind: VariableSegment, value: "ConfigurationSetName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteConfigurationSet_594160(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Delete an existing configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_594162 = path.getOrDefault("ConfigurationSetName")
  valid_594162 = validateParameter(valid_594162, JString, required = true,
                                 default = nil)
  if valid_594162 != nil:
    section.add "ConfigurationSetName", valid_594162
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594163 = header.getOrDefault("X-Amz-Date")
  valid_594163 = validateParameter(valid_594163, JString, required = false,
                                 default = nil)
  if valid_594163 != nil:
    section.add "X-Amz-Date", valid_594163
  var valid_594164 = header.getOrDefault("X-Amz-Security-Token")
  valid_594164 = validateParameter(valid_594164, JString, required = false,
                                 default = nil)
  if valid_594164 != nil:
    section.add "X-Amz-Security-Token", valid_594164
  var valid_594165 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594165 = validateParameter(valid_594165, JString, required = false,
                                 default = nil)
  if valid_594165 != nil:
    section.add "X-Amz-Content-Sha256", valid_594165
  var valid_594166 = header.getOrDefault("X-Amz-Algorithm")
  valid_594166 = validateParameter(valid_594166, JString, required = false,
                                 default = nil)
  if valid_594166 != nil:
    section.add "X-Amz-Algorithm", valid_594166
  var valid_594167 = header.getOrDefault("X-Amz-Signature")
  valid_594167 = validateParameter(valid_594167, JString, required = false,
                                 default = nil)
  if valid_594167 != nil:
    section.add "X-Amz-Signature", valid_594167
  var valid_594168 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594168 = validateParameter(valid_594168, JString, required = false,
                                 default = nil)
  if valid_594168 != nil:
    section.add "X-Amz-SignedHeaders", valid_594168
  var valid_594169 = header.getOrDefault("X-Amz-Credential")
  valid_594169 = validateParameter(valid_594169, JString, required = false,
                                 default = nil)
  if valid_594169 != nil:
    section.add "X-Amz-Credential", valid_594169
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594170: Call_DeleteConfigurationSet_594159; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Delete an existing configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ## 
  let valid = call_594170.validator(path, query, header, formData, body)
  let scheme = call_594170.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594170.url(scheme.get, call_594170.host, call_594170.base,
                         call_594170.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594170, url, valid)

proc call*(call_594171: Call_DeleteConfigurationSet_594159;
          ConfigurationSetName: string): Recallable =
  ## deleteConfigurationSet
  ## <p>Delete an existing configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  var path_594172 = newJObject()
  add(path_594172, "ConfigurationSetName", newJString(ConfigurationSetName))
  result = call_594171.call(path_594172, nil, nil, nil, nil)

var deleteConfigurationSet* = Call_DeleteConfigurationSet_594159(
    name: "deleteConfigurationSet", meth: HttpMethod.HttpDelete,
    host: "email.amazonaws.com",
    route: "/v1/email/configuration-sets/{ConfigurationSetName}",
    validator: validate_DeleteConfigurationSet_594160, base: "/",
    url: url_DeleteConfigurationSet_594161, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConfigurationSetEventDestination_594173 = ref object of OpenApiRestCall_593421
proc url_UpdateConfigurationSetEventDestination_594175(protocol: Scheme;
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
    segments = @[(kind: ConstantSegment, value: "/v1/email/configuration-sets/"),
               (kind: VariableSegment, value: "ConfigurationSetName"),
               (kind: ConstantSegment, value: "/event-destinations/"),
               (kind: VariableSegment, value: "EventDestinationName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UpdateConfigurationSetEventDestination_594174(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Update the configuration of an event destination for a configuration set.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   EventDestinationName: JString (required)
  ##                       : <p>The name of an event destination.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_594176 = path.getOrDefault("ConfigurationSetName")
  valid_594176 = validateParameter(valid_594176, JString, required = true,
                                 default = nil)
  if valid_594176 != nil:
    section.add "ConfigurationSetName", valid_594176
  var valid_594177 = path.getOrDefault("EventDestinationName")
  valid_594177 = validateParameter(valid_594177, JString, required = true,
                                 default = nil)
  if valid_594177 != nil:
    section.add "EventDestinationName", valid_594177
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594178 = header.getOrDefault("X-Amz-Date")
  valid_594178 = validateParameter(valid_594178, JString, required = false,
                                 default = nil)
  if valid_594178 != nil:
    section.add "X-Amz-Date", valid_594178
  var valid_594179 = header.getOrDefault("X-Amz-Security-Token")
  valid_594179 = validateParameter(valid_594179, JString, required = false,
                                 default = nil)
  if valid_594179 != nil:
    section.add "X-Amz-Security-Token", valid_594179
  var valid_594180 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594180 = validateParameter(valid_594180, JString, required = false,
                                 default = nil)
  if valid_594180 != nil:
    section.add "X-Amz-Content-Sha256", valid_594180
  var valid_594181 = header.getOrDefault("X-Amz-Algorithm")
  valid_594181 = validateParameter(valid_594181, JString, required = false,
                                 default = nil)
  if valid_594181 != nil:
    section.add "X-Amz-Algorithm", valid_594181
  var valid_594182 = header.getOrDefault("X-Amz-Signature")
  valid_594182 = validateParameter(valid_594182, JString, required = false,
                                 default = nil)
  if valid_594182 != nil:
    section.add "X-Amz-Signature", valid_594182
  var valid_594183 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594183 = validateParameter(valid_594183, JString, required = false,
                                 default = nil)
  if valid_594183 != nil:
    section.add "X-Amz-SignedHeaders", valid_594183
  var valid_594184 = header.getOrDefault("X-Amz-Credential")
  valid_594184 = validateParameter(valid_594184, JString, required = false,
                                 default = nil)
  if valid_594184 != nil:
    section.add "X-Amz-Credential", valid_594184
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594186: Call_UpdateConfigurationSetEventDestination_594173;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Update the configuration of an event destination for a configuration set.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ## 
  let valid = call_594186.validator(path, query, header, formData, body)
  let scheme = call_594186.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594186.url(scheme.get, call_594186.host, call_594186.base,
                         call_594186.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594186, url, valid)

proc call*(call_594187: Call_UpdateConfigurationSetEventDestination_594173;
          ConfigurationSetName: string; body: JsonNode; EventDestinationName: string): Recallable =
  ## updateConfigurationSetEventDestination
  ## <p>Update the configuration of an event destination for a configuration set.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   body: JObject (required)
  ##   EventDestinationName: string (required)
  ##                       : <p>The name of an event destination.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  var path_594188 = newJObject()
  var body_594189 = newJObject()
  add(path_594188, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_594189 = body
  add(path_594188, "EventDestinationName", newJString(EventDestinationName))
  result = call_594187.call(path_594188, nil, nil, nil, body_594189)

var updateConfigurationSetEventDestination* = Call_UpdateConfigurationSetEventDestination_594173(
    name: "updateConfigurationSetEventDestination", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets/{ConfigurationSetName}/event-destinations/{EventDestinationName}",
    validator: validate_UpdateConfigurationSetEventDestination_594174, base: "/",
    url: url_UpdateConfigurationSetEventDestination_594175,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfigurationSetEventDestination_594190 = ref object of OpenApiRestCall_593421
proc url_DeleteConfigurationSetEventDestination_594192(protocol: Scheme;
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
    segments = @[(kind: ConstantSegment, value: "/v1/email/configuration-sets/"),
               (kind: VariableSegment, value: "ConfigurationSetName"),
               (kind: ConstantSegment, value: "/event-destinations/"),
               (kind: VariableSegment, value: "EventDestinationName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteConfigurationSetEventDestination_594191(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Delete an event destination.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   EventDestinationName: JString (required)
  ##                       : <p>The name of an event destination.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_594193 = path.getOrDefault("ConfigurationSetName")
  valid_594193 = validateParameter(valid_594193, JString, required = true,
                                 default = nil)
  if valid_594193 != nil:
    section.add "ConfigurationSetName", valid_594193
  var valid_594194 = path.getOrDefault("EventDestinationName")
  valid_594194 = validateParameter(valid_594194, JString, required = true,
                                 default = nil)
  if valid_594194 != nil:
    section.add "EventDestinationName", valid_594194
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594195 = header.getOrDefault("X-Amz-Date")
  valid_594195 = validateParameter(valid_594195, JString, required = false,
                                 default = nil)
  if valid_594195 != nil:
    section.add "X-Amz-Date", valid_594195
  var valid_594196 = header.getOrDefault("X-Amz-Security-Token")
  valid_594196 = validateParameter(valid_594196, JString, required = false,
                                 default = nil)
  if valid_594196 != nil:
    section.add "X-Amz-Security-Token", valid_594196
  var valid_594197 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594197 = validateParameter(valid_594197, JString, required = false,
                                 default = nil)
  if valid_594197 != nil:
    section.add "X-Amz-Content-Sha256", valid_594197
  var valid_594198 = header.getOrDefault("X-Amz-Algorithm")
  valid_594198 = validateParameter(valid_594198, JString, required = false,
                                 default = nil)
  if valid_594198 != nil:
    section.add "X-Amz-Algorithm", valid_594198
  var valid_594199 = header.getOrDefault("X-Amz-Signature")
  valid_594199 = validateParameter(valid_594199, JString, required = false,
                                 default = nil)
  if valid_594199 != nil:
    section.add "X-Amz-Signature", valid_594199
  var valid_594200 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594200 = validateParameter(valid_594200, JString, required = false,
                                 default = nil)
  if valid_594200 != nil:
    section.add "X-Amz-SignedHeaders", valid_594200
  var valid_594201 = header.getOrDefault("X-Amz-Credential")
  valid_594201 = validateParameter(valid_594201, JString, required = false,
                                 default = nil)
  if valid_594201 != nil:
    section.add "X-Amz-Credential", valid_594201
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594202: Call_DeleteConfigurationSetEventDestination_594190;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Delete an event destination.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ## 
  let valid = call_594202.validator(path, query, header, formData, body)
  let scheme = call_594202.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594202.url(scheme.get, call_594202.host, call_594202.base,
                         call_594202.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594202, url, valid)

proc call*(call_594203: Call_DeleteConfigurationSetEventDestination_594190;
          ConfigurationSetName: string; EventDestinationName: string): Recallable =
  ## deleteConfigurationSetEventDestination
  ## <p>Delete an event destination.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   EventDestinationName: string (required)
  ##                       : <p>The name of an event destination.</p> <p>In Amazon Pinpoint, <i>events</i> include message sends, deliveries, opens, clicks, bounces, and complaints. <i>Event destinations</i> are places that you can send information about these events to. For example, you can send event data to Amazon SNS to receive notifications when you receive bounces or complaints, or you can use Amazon Kinesis Data Firehose to stream data to Amazon S3 for long-term storage.</p>
  var path_594204 = newJObject()
  add(path_594204, "ConfigurationSetName", newJString(ConfigurationSetName))
  add(path_594204, "EventDestinationName", newJString(EventDestinationName))
  result = call_594203.call(path_594204, nil, nil, nil, nil)

var deleteConfigurationSetEventDestination* = Call_DeleteConfigurationSetEventDestination_594190(
    name: "deleteConfigurationSetEventDestination", meth: HttpMethod.HttpDelete,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets/{ConfigurationSetName}/event-destinations/{EventDestinationName}",
    validator: validate_DeleteConfigurationSetEventDestination_594191, base: "/",
    url: url_DeleteConfigurationSetEventDestination_594192,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDedicatedIpPool_594205 = ref object of OpenApiRestCall_593421
proc url_DeleteDedicatedIpPool_594207(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "PoolName" in path, "`PoolName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/dedicated-ip-pools/"),
               (kind: VariableSegment, value: "PoolName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteDedicatedIpPool_594206(path: JsonNode; query: JsonNode;
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
  var valid_594208 = path.getOrDefault("PoolName")
  valid_594208 = validateParameter(valid_594208, JString, required = true,
                                 default = nil)
  if valid_594208 != nil:
    section.add "PoolName", valid_594208
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594209 = header.getOrDefault("X-Amz-Date")
  valid_594209 = validateParameter(valid_594209, JString, required = false,
                                 default = nil)
  if valid_594209 != nil:
    section.add "X-Amz-Date", valid_594209
  var valid_594210 = header.getOrDefault("X-Amz-Security-Token")
  valid_594210 = validateParameter(valid_594210, JString, required = false,
                                 default = nil)
  if valid_594210 != nil:
    section.add "X-Amz-Security-Token", valid_594210
  var valid_594211 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594211 = validateParameter(valid_594211, JString, required = false,
                                 default = nil)
  if valid_594211 != nil:
    section.add "X-Amz-Content-Sha256", valid_594211
  var valid_594212 = header.getOrDefault("X-Amz-Algorithm")
  valid_594212 = validateParameter(valid_594212, JString, required = false,
                                 default = nil)
  if valid_594212 != nil:
    section.add "X-Amz-Algorithm", valid_594212
  var valid_594213 = header.getOrDefault("X-Amz-Signature")
  valid_594213 = validateParameter(valid_594213, JString, required = false,
                                 default = nil)
  if valid_594213 != nil:
    section.add "X-Amz-Signature", valid_594213
  var valid_594214 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594214 = validateParameter(valid_594214, JString, required = false,
                                 default = nil)
  if valid_594214 != nil:
    section.add "X-Amz-SignedHeaders", valid_594214
  var valid_594215 = header.getOrDefault("X-Amz-Credential")
  valid_594215 = validateParameter(valid_594215, JString, required = false,
                                 default = nil)
  if valid_594215 != nil:
    section.add "X-Amz-Credential", valid_594215
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594216: Call_DeleteDedicatedIpPool_594205; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a dedicated IP pool.
  ## 
  let valid = call_594216.validator(path, query, header, formData, body)
  let scheme = call_594216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594216.url(scheme.get, call_594216.host, call_594216.base,
                         call_594216.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594216, url, valid)

proc call*(call_594217: Call_DeleteDedicatedIpPool_594205; PoolName: string): Recallable =
  ## deleteDedicatedIpPool
  ## Delete a dedicated IP pool.
  ##   PoolName: string (required)
  ##           : The name of a dedicated IP pool.
  var path_594218 = newJObject()
  add(path_594218, "PoolName", newJString(PoolName))
  result = call_594217.call(path_594218, nil, nil, nil, nil)

var deleteDedicatedIpPool* = Call_DeleteDedicatedIpPool_594205(
    name: "deleteDedicatedIpPool", meth: HttpMethod.HttpDelete,
    host: "email.amazonaws.com", route: "/v1/email/dedicated-ip-pools/{PoolName}",
    validator: validate_DeleteDedicatedIpPool_594206, base: "/",
    url: url_DeleteDedicatedIpPool_594207, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEmailIdentity_594219 = ref object of OpenApiRestCall_593421
proc url_GetEmailIdentity_594221(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "EmailIdentity" in path, "`EmailIdentity` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/identities/"),
               (kind: VariableSegment, value: "EmailIdentity")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetEmailIdentity_594220(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Provides information about a specific identity associated with your Amazon Pinpoint account, including the identity's verification status, its DKIM authentication status, and its custom Mail-From settings.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   EmailIdentity: JString (required)
  ##                : The email identity that you want to retrieve details for.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `EmailIdentity` field"
  var valid_594222 = path.getOrDefault("EmailIdentity")
  valid_594222 = validateParameter(valid_594222, JString, required = true,
                                 default = nil)
  if valid_594222 != nil:
    section.add "EmailIdentity", valid_594222
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594223 = header.getOrDefault("X-Amz-Date")
  valid_594223 = validateParameter(valid_594223, JString, required = false,
                                 default = nil)
  if valid_594223 != nil:
    section.add "X-Amz-Date", valid_594223
  var valid_594224 = header.getOrDefault("X-Amz-Security-Token")
  valid_594224 = validateParameter(valid_594224, JString, required = false,
                                 default = nil)
  if valid_594224 != nil:
    section.add "X-Amz-Security-Token", valid_594224
  var valid_594225 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594225 = validateParameter(valid_594225, JString, required = false,
                                 default = nil)
  if valid_594225 != nil:
    section.add "X-Amz-Content-Sha256", valid_594225
  var valid_594226 = header.getOrDefault("X-Amz-Algorithm")
  valid_594226 = validateParameter(valid_594226, JString, required = false,
                                 default = nil)
  if valid_594226 != nil:
    section.add "X-Amz-Algorithm", valid_594226
  var valid_594227 = header.getOrDefault("X-Amz-Signature")
  valid_594227 = validateParameter(valid_594227, JString, required = false,
                                 default = nil)
  if valid_594227 != nil:
    section.add "X-Amz-Signature", valid_594227
  var valid_594228 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594228 = validateParameter(valid_594228, JString, required = false,
                                 default = nil)
  if valid_594228 != nil:
    section.add "X-Amz-SignedHeaders", valid_594228
  var valid_594229 = header.getOrDefault("X-Amz-Credential")
  valid_594229 = validateParameter(valid_594229, JString, required = false,
                                 default = nil)
  if valid_594229 != nil:
    section.add "X-Amz-Credential", valid_594229
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594230: Call_GetEmailIdentity_594219; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information about a specific identity associated with your Amazon Pinpoint account, including the identity's verification status, its DKIM authentication status, and its custom Mail-From settings.
  ## 
  let valid = call_594230.validator(path, query, header, formData, body)
  let scheme = call_594230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594230.url(scheme.get, call_594230.host, call_594230.base,
                         call_594230.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594230, url, valid)

proc call*(call_594231: Call_GetEmailIdentity_594219; EmailIdentity: string): Recallable =
  ## getEmailIdentity
  ## Provides information about a specific identity associated with your Amazon Pinpoint account, including the identity's verification status, its DKIM authentication status, and its custom Mail-From settings.
  ##   EmailIdentity: string (required)
  ##                : The email identity that you want to retrieve details for.
  var path_594232 = newJObject()
  add(path_594232, "EmailIdentity", newJString(EmailIdentity))
  result = call_594231.call(path_594232, nil, nil, nil, nil)

var getEmailIdentity* = Call_GetEmailIdentity_594219(name: "getEmailIdentity",
    meth: HttpMethod.HttpGet, host: "email.amazonaws.com",
    route: "/v1/email/identities/{EmailIdentity}",
    validator: validate_GetEmailIdentity_594220, base: "/",
    url: url_GetEmailIdentity_594221, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEmailIdentity_594233 = ref object of OpenApiRestCall_593421
proc url_DeleteEmailIdentity_594235(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "EmailIdentity" in path, "`EmailIdentity` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/identities/"),
               (kind: VariableSegment, value: "EmailIdentity")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteEmailIdentity_594234(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Deletes an email identity that you previously verified for use with Amazon Pinpoint. An identity can be either an email address or a domain name.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   EmailIdentity: JString (required)
  ##                : The identity (that is, the email address or domain) that you want to delete from your Amazon Pinpoint account.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `EmailIdentity` field"
  var valid_594236 = path.getOrDefault("EmailIdentity")
  valid_594236 = validateParameter(valid_594236, JString, required = true,
                                 default = nil)
  if valid_594236 != nil:
    section.add "EmailIdentity", valid_594236
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594237 = header.getOrDefault("X-Amz-Date")
  valid_594237 = validateParameter(valid_594237, JString, required = false,
                                 default = nil)
  if valid_594237 != nil:
    section.add "X-Amz-Date", valid_594237
  var valid_594238 = header.getOrDefault("X-Amz-Security-Token")
  valid_594238 = validateParameter(valid_594238, JString, required = false,
                                 default = nil)
  if valid_594238 != nil:
    section.add "X-Amz-Security-Token", valid_594238
  var valid_594239 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594239 = validateParameter(valid_594239, JString, required = false,
                                 default = nil)
  if valid_594239 != nil:
    section.add "X-Amz-Content-Sha256", valid_594239
  var valid_594240 = header.getOrDefault("X-Amz-Algorithm")
  valid_594240 = validateParameter(valid_594240, JString, required = false,
                                 default = nil)
  if valid_594240 != nil:
    section.add "X-Amz-Algorithm", valid_594240
  var valid_594241 = header.getOrDefault("X-Amz-Signature")
  valid_594241 = validateParameter(valid_594241, JString, required = false,
                                 default = nil)
  if valid_594241 != nil:
    section.add "X-Amz-Signature", valid_594241
  var valid_594242 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594242 = validateParameter(valid_594242, JString, required = false,
                                 default = nil)
  if valid_594242 != nil:
    section.add "X-Amz-SignedHeaders", valid_594242
  var valid_594243 = header.getOrDefault("X-Amz-Credential")
  valid_594243 = validateParameter(valid_594243, JString, required = false,
                                 default = nil)
  if valid_594243 != nil:
    section.add "X-Amz-Credential", valid_594243
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594244: Call_DeleteEmailIdentity_594233; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an email identity that you previously verified for use with Amazon Pinpoint. An identity can be either an email address or a domain name.
  ## 
  let valid = call_594244.validator(path, query, header, formData, body)
  let scheme = call_594244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594244.url(scheme.get, call_594244.host, call_594244.base,
                         call_594244.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594244, url, valid)

proc call*(call_594245: Call_DeleteEmailIdentity_594233; EmailIdentity: string): Recallable =
  ## deleteEmailIdentity
  ## Deletes an email identity that you previously verified for use with Amazon Pinpoint. An identity can be either an email address or a domain name.
  ##   EmailIdentity: string (required)
  ##                : The identity (that is, the email address or domain) that you want to delete from your Amazon Pinpoint account.
  var path_594246 = newJObject()
  add(path_594246, "EmailIdentity", newJString(EmailIdentity))
  result = call_594245.call(path_594246, nil, nil, nil, nil)

var deleteEmailIdentity* = Call_DeleteEmailIdentity_594233(
    name: "deleteEmailIdentity", meth: HttpMethod.HttpDelete,
    host: "email.amazonaws.com", route: "/v1/email/identities/{EmailIdentity}",
    validator: validate_DeleteEmailIdentity_594234, base: "/",
    url: url_DeleteEmailIdentity_594235, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccount_594247 = ref object of OpenApiRestCall_593421
proc url_GetAccount_594249(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAccount_594248(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Obtain information about the email-sending status and capabilities of your Amazon Pinpoint account in the current AWS Region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594250 = header.getOrDefault("X-Amz-Date")
  valid_594250 = validateParameter(valid_594250, JString, required = false,
                                 default = nil)
  if valid_594250 != nil:
    section.add "X-Amz-Date", valid_594250
  var valid_594251 = header.getOrDefault("X-Amz-Security-Token")
  valid_594251 = validateParameter(valid_594251, JString, required = false,
                                 default = nil)
  if valid_594251 != nil:
    section.add "X-Amz-Security-Token", valid_594251
  var valid_594252 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594252 = validateParameter(valid_594252, JString, required = false,
                                 default = nil)
  if valid_594252 != nil:
    section.add "X-Amz-Content-Sha256", valid_594252
  var valid_594253 = header.getOrDefault("X-Amz-Algorithm")
  valid_594253 = validateParameter(valid_594253, JString, required = false,
                                 default = nil)
  if valid_594253 != nil:
    section.add "X-Amz-Algorithm", valid_594253
  var valid_594254 = header.getOrDefault("X-Amz-Signature")
  valid_594254 = validateParameter(valid_594254, JString, required = false,
                                 default = nil)
  if valid_594254 != nil:
    section.add "X-Amz-Signature", valid_594254
  var valid_594255 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594255 = validateParameter(valid_594255, JString, required = false,
                                 default = nil)
  if valid_594255 != nil:
    section.add "X-Amz-SignedHeaders", valid_594255
  var valid_594256 = header.getOrDefault("X-Amz-Credential")
  valid_594256 = validateParameter(valid_594256, JString, required = false,
                                 default = nil)
  if valid_594256 != nil:
    section.add "X-Amz-Credential", valid_594256
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594257: Call_GetAccount_594247; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Obtain information about the email-sending status and capabilities of your Amazon Pinpoint account in the current AWS Region.
  ## 
  let valid = call_594257.validator(path, query, header, formData, body)
  let scheme = call_594257.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594257.url(scheme.get, call_594257.host, call_594257.base,
                         call_594257.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594257, url, valid)

proc call*(call_594258: Call_GetAccount_594247): Recallable =
  ## getAccount
  ## Obtain information about the email-sending status and capabilities of your Amazon Pinpoint account in the current AWS Region.
  result = call_594258.call(nil, nil, nil, nil, nil)

var getAccount* = Call_GetAccount_594247(name: "getAccount",
                                      meth: HttpMethod.HttpGet,
                                      host: "email.amazonaws.com",
                                      route: "/v1/email/account",
                                      validator: validate_GetAccount_594248,
                                      base: "/", url: url_GetAccount_594249,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBlacklistReports_594259 = ref object of OpenApiRestCall_593421
proc url_GetBlacklistReports_594261(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetBlacklistReports_594260(path: JsonNode; query: JsonNode;
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
  ##                     : A list of IP addresses that you want to retrieve blacklist information about. You can only specify the dedicated IP addresses that you use to send email using Amazon Pinpoint or Amazon SES.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `BlacklistItemNames` field"
  var valid_594262 = query.getOrDefault("BlacklistItemNames")
  valid_594262 = validateParameter(valid_594262, JArray, required = true, default = nil)
  if valid_594262 != nil:
    section.add "BlacklistItemNames", valid_594262
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594263 = header.getOrDefault("X-Amz-Date")
  valid_594263 = validateParameter(valid_594263, JString, required = false,
                                 default = nil)
  if valid_594263 != nil:
    section.add "X-Amz-Date", valid_594263
  var valid_594264 = header.getOrDefault("X-Amz-Security-Token")
  valid_594264 = validateParameter(valid_594264, JString, required = false,
                                 default = nil)
  if valid_594264 != nil:
    section.add "X-Amz-Security-Token", valid_594264
  var valid_594265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594265 = validateParameter(valid_594265, JString, required = false,
                                 default = nil)
  if valid_594265 != nil:
    section.add "X-Amz-Content-Sha256", valid_594265
  var valid_594266 = header.getOrDefault("X-Amz-Algorithm")
  valid_594266 = validateParameter(valid_594266, JString, required = false,
                                 default = nil)
  if valid_594266 != nil:
    section.add "X-Amz-Algorithm", valid_594266
  var valid_594267 = header.getOrDefault("X-Amz-Signature")
  valid_594267 = validateParameter(valid_594267, JString, required = false,
                                 default = nil)
  if valid_594267 != nil:
    section.add "X-Amz-Signature", valid_594267
  var valid_594268 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594268 = validateParameter(valid_594268, JString, required = false,
                                 default = nil)
  if valid_594268 != nil:
    section.add "X-Amz-SignedHeaders", valid_594268
  var valid_594269 = header.getOrDefault("X-Amz-Credential")
  valid_594269 = validateParameter(valid_594269, JString, required = false,
                                 default = nil)
  if valid_594269 != nil:
    section.add "X-Amz-Credential", valid_594269
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594270: Call_GetBlacklistReports_594259; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a list of the blacklists that your dedicated IP addresses appear on.
  ## 
  let valid = call_594270.validator(path, query, header, formData, body)
  let scheme = call_594270.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594270.url(scheme.get, call_594270.host, call_594270.base,
                         call_594270.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594270, url, valid)

proc call*(call_594271: Call_GetBlacklistReports_594259;
          BlacklistItemNames: JsonNode): Recallable =
  ## getBlacklistReports
  ## Retrieve a list of the blacklists that your dedicated IP addresses appear on.
  ##   BlacklistItemNames: JArray (required)
  ##                     : A list of IP addresses that you want to retrieve blacklist information about. You can only specify the dedicated IP addresses that you use to send email using Amazon Pinpoint or Amazon SES.
  var query_594272 = newJObject()
  if BlacklistItemNames != nil:
    query_594272.add "BlacklistItemNames", BlacklistItemNames
  result = call_594271.call(nil, query_594272, nil, nil, nil)

var getBlacklistReports* = Call_GetBlacklistReports_594259(
    name: "getBlacklistReports", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/deliverability-dashboard/blacklist-report#BlacklistItemNames",
    validator: validate_GetBlacklistReports_594260, base: "/",
    url: url_GetBlacklistReports_594261, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDedicatedIp_594273 = ref object of OpenApiRestCall_593421
proc url_GetDedicatedIp_594275(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "IP" in path, "`IP` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/dedicated-ips/"),
               (kind: VariableSegment, value: "IP")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetDedicatedIp_594274(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Get information about a dedicated IP address, including the name of the dedicated IP pool that it's associated with, as well information about the automatic warm-up process for the address.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   IP: JString (required)
  ##     : A dedicated IP address that is associated with your Amazon Pinpoint account.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `IP` field"
  var valid_594276 = path.getOrDefault("IP")
  valid_594276 = validateParameter(valid_594276, JString, required = true,
                                 default = nil)
  if valid_594276 != nil:
    section.add "IP", valid_594276
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594277 = header.getOrDefault("X-Amz-Date")
  valid_594277 = validateParameter(valid_594277, JString, required = false,
                                 default = nil)
  if valid_594277 != nil:
    section.add "X-Amz-Date", valid_594277
  var valid_594278 = header.getOrDefault("X-Amz-Security-Token")
  valid_594278 = validateParameter(valid_594278, JString, required = false,
                                 default = nil)
  if valid_594278 != nil:
    section.add "X-Amz-Security-Token", valid_594278
  var valid_594279 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594279 = validateParameter(valid_594279, JString, required = false,
                                 default = nil)
  if valid_594279 != nil:
    section.add "X-Amz-Content-Sha256", valid_594279
  var valid_594280 = header.getOrDefault("X-Amz-Algorithm")
  valid_594280 = validateParameter(valid_594280, JString, required = false,
                                 default = nil)
  if valid_594280 != nil:
    section.add "X-Amz-Algorithm", valid_594280
  var valid_594281 = header.getOrDefault("X-Amz-Signature")
  valid_594281 = validateParameter(valid_594281, JString, required = false,
                                 default = nil)
  if valid_594281 != nil:
    section.add "X-Amz-Signature", valid_594281
  var valid_594282 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594282 = validateParameter(valid_594282, JString, required = false,
                                 default = nil)
  if valid_594282 != nil:
    section.add "X-Amz-SignedHeaders", valid_594282
  var valid_594283 = header.getOrDefault("X-Amz-Credential")
  valid_594283 = validateParameter(valid_594283, JString, required = false,
                                 default = nil)
  if valid_594283 != nil:
    section.add "X-Amz-Credential", valid_594283
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594284: Call_GetDedicatedIp_594273; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get information about a dedicated IP address, including the name of the dedicated IP pool that it's associated with, as well information about the automatic warm-up process for the address.
  ## 
  let valid = call_594284.validator(path, query, header, formData, body)
  let scheme = call_594284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594284.url(scheme.get, call_594284.host, call_594284.base,
                         call_594284.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594284, url, valid)

proc call*(call_594285: Call_GetDedicatedIp_594273; IP: string): Recallable =
  ## getDedicatedIp
  ## Get information about a dedicated IP address, including the name of the dedicated IP pool that it's associated with, as well information about the automatic warm-up process for the address.
  ##   IP: string (required)
  ##     : A dedicated IP address that is associated with your Amazon Pinpoint account.
  var path_594286 = newJObject()
  add(path_594286, "IP", newJString(IP))
  result = call_594285.call(path_594286, nil, nil, nil, nil)

var getDedicatedIp* = Call_GetDedicatedIp_594273(name: "getDedicatedIp",
    meth: HttpMethod.HttpGet, host: "email.amazonaws.com",
    route: "/v1/email/dedicated-ips/{IP}", validator: validate_GetDedicatedIp_594274,
    base: "/", url: url_GetDedicatedIp_594275, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDedicatedIps_594287 = ref object of OpenApiRestCall_593421
proc url_GetDedicatedIps_594289(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDedicatedIps_594288(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## List the dedicated IP addresses that are associated with your Amazon Pinpoint account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageSize: JInt
  ##           : The number of results to show in a single call to <code>GetDedicatedIpsRequest</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  ##   NextToken: JString
  ##            : A token returned from a previous call to <code>GetDedicatedIps</code> to indicate the position of the dedicated IP pool in the list of IP pools.
  ##   PoolName: JString
  ##           : The name of a dedicated IP pool.
  section = newJObject()
  var valid_594290 = query.getOrDefault("PageSize")
  valid_594290 = validateParameter(valid_594290, JInt, required = false, default = nil)
  if valid_594290 != nil:
    section.add "PageSize", valid_594290
  var valid_594291 = query.getOrDefault("NextToken")
  valid_594291 = validateParameter(valid_594291, JString, required = false,
                                 default = nil)
  if valid_594291 != nil:
    section.add "NextToken", valid_594291
  var valid_594292 = query.getOrDefault("PoolName")
  valid_594292 = validateParameter(valid_594292, JString, required = false,
                                 default = nil)
  if valid_594292 != nil:
    section.add "PoolName", valid_594292
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594293 = header.getOrDefault("X-Amz-Date")
  valid_594293 = validateParameter(valid_594293, JString, required = false,
                                 default = nil)
  if valid_594293 != nil:
    section.add "X-Amz-Date", valid_594293
  var valid_594294 = header.getOrDefault("X-Amz-Security-Token")
  valid_594294 = validateParameter(valid_594294, JString, required = false,
                                 default = nil)
  if valid_594294 != nil:
    section.add "X-Amz-Security-Token", valid_594294
  var valid_594295 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594295 = validateParameter(valid_594295, JString, required = false,
                                 default = nil)
  if valid_594295 != nil:
    section.add "X-Amz-Content-Sha256", valid_594295
  var valid_594296 = header.getOrDefault("X-Amz-Algorithm")
  valid_594296 = validateParameter(valid_594296, JString, required = false,
                                 default = nil)
  if valid_594296 != nil:
    section.add "X-Amz-Algorithm", valid_594296
  var valid_594297 = header.getOrDefault("X-Amz-Signature")
  valid_594297 = validateParameter(valid_594297, JString, required = false,
                                 default = nil)
  if valid_594297 != nil:
    section.add "X-Amz-Signature", valid_594297
  var valid_594298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594298 = validateParameter(valid_594298, JString, required = false,
                                 default = nil)
  if valid_594298 != nil:
    section.add "X-Amz-SignedHeaders", valid_594298
  var valid_594299 = header.getOrDefault("X-Amz-Credential")
  valid_594299 = validateParameter(valid_594299, JString, required = false,
                                 default = nil)
  if valid_594299 != nil:
    section.add "X-Amz-Credential", valid_594299
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594300: Call_GetDedicatedIps_594287; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the dedicated IP addresses that are associated with your Amazon Pinpoint account.
  ## 
  let valid = call_594300.validator(path, query, header, formData, body)
  let scheme = call_594300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594300.url(scheme.get, call_594300.host, call_594300.base,
                         call_594300.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594300, url, valid)

proc call*(call_594301: Call_GetDedicatedIps_594287; PageSize: int = 0;
          NextToken: string = ""; PoolName: string = ""): Recallable =
  ## getDedicatedIps
  ## List the dedicated IP addresses that are associated with your Amazon Pinpoint account.
  ##   PageSize: int
  ##           : The number of results to show in a single call to <code>GetDedicatedIpsRequest</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  ##   NextToken: string
  ##            : A token returned from a previous call to <code>GetDedicatedIps</code> to indicate the position of the dedicated IP pool in the list of IP pools.
  ##   PoolName: string
  ##           : The name of a dedicated IP pool.
  var query_594302 = newJObject()
  add(query_594302, "PageSize", newJInt(PageSize))
  add(query_594302, "NextToken", newJString(NextToken))
  add(query_594302, "PoolName", newJString(PoolName))
  result = call_594301.call(nil, query_594302, nil, nil, nil)

var getDedicatedIps* = Call_GetDedicatedIps_594287(name: "getDedicatedIps",
    meth: HttpMethod.HttpGet, host: "email.amazonaws.com",
    route: "/v1/email/dedicated-ips", validator: validate_GetDedicatedIps_594288,
    base: "/", url: url_GetDedicatedIps_594289, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDeliverabilityDashboardOption_594315 = ref object of OpenApiRestCall_593421
proc url_PutDeliverabilityDashboardOption_594317(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutDeliverabilityDashboardOption_594316(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Enable or disable the Deliverability dashboard for your Amazon Pinpoint account. When you enable the Deliverability dashboard, you gain access to reputation, deliverability, and other metrics for the domains that you use to send email using Amazon Pinpoint. You also gain the ability to perform predictive inbox placement tests.</p> <p>When you use the Deliverability dashboard, you pay a monthly subscription charge, in addition to any other fees that you accrue by using Amazon Pinpoint. For more information about the features and cost of a Deliverability dashboard subscription, see <a href="http://aws.amazon.com/pinpoint/pricing/">Amazon Pinpoint Pricing</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594318 = header.getOrDefault("X-Amz-Date")
  valid_594318 = validateParameter(valid_594318, JString, required = false,
                                 default = nil)
  if valid_594318 != nil:
    section.add "X-Amz-Date", valid_594318
  var valid_594319 = header.getOrDefault("X-Amz-Security-Token")
  valid_594319 = validateParameter(valid_594319, JString, required = false,
                                 default = nil)
  if valid_594319 != nil:
    section.add "X-Amz-Security-Token", valid_594319
  var valid_594320 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594320 = validateParameter(valid_594320, JString, required = false,
                                 default = nil)
  if valid_594320 != nil:
    section.add "X-Amz-Content-Sha256", valid_594320
  var valid_594321 = header.getOrDefault("X-Amz-Algorithm")
  valid_594321 = validateParameter(valid_594321, JString, required = false,
                                 default = nil)
  if valid_594321 != nil:
    section.add "X-Amz-Algorithm", valid_594321
  var valid_594322 = header.getOrDefault("X-Amz-Signature")
  valid_594322 = validateParameter(valid_594322, JString, required = false,
                                 default = nil)
  if valid_594322 != nil:
    section.add "X-Amz-Signature", valid_594322
  var valid_594323 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594323 = validateParameter(valid_594323, JString, required = false,
                                 default = nil)
  if valid_594323 != nil:
    section.add "X-Amz-SignedHeaders", valid_594323
  var valid_594324 = header.getOrDefault("X-Amz-Credential")
  valid_594324 = validateParameter(valid_594324, JString, required = false,
                                 default = nil)
  if valid_594324 != nil:
    section.add "X-Amz-Credential", valid_594324
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594326: Call_PutDeliverabilityDashboardOption_594315;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Enable or disable the Deliverability dashboard for your Amazon Pinpoint account. When you enable the Deliverability dashboard, you gain access to reputation, deliverability, and other metrics for the domains that you use to send email using Amazon Pinpoint. You also gain the ability to perform predictive inbox placement tests.</p> <p>When you use the Deliverability dashboard, you pay a monthly subscription charge, in addition to any other fees that you accrue by using Amazon Pinpoint. For more information about the features and cost of a Deliverability dashboard subscription, see <a href="http://aws.amazon.com/pinpoint/pricing/">Amazon Pinpoint Pricing</a>.</p>
  ## 
  let valid = call_594326.validator(path, query, header, formData, body)
  let scheme = call_594326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594326.url(scheme.get, call_594326.host, call_594326.base,
                         call_594326.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594326, url, valid)

proc call*(call_594327: Call_PutDeliverabilityDashboardOption_594315;
          body: JsonNode): Recallable =
  ## putDeliverabilityDashboardOption
  ## <p>Enable or disable the Deliverability dashboard for your Amazon Pinpoint account. When you enable the Deliverability dashboard, you gain access to reputation, deliverability, and other metrics for the domains that you use to send email using Amazon Pinpoint. You also gain the ability to perform predictive inbox placement tests.</p> <p>When you use the Deliverability dashboard, you pay a monthly subscription charge, in addition to any other fees that you accrue by using Amazon Pinpoint. For more information about the features and cost of a Deliverability dashboard subscription, see <a href="http://aws.amazon.com/pinpoint/pricing/">Amazon Pinpoint Pricing</a>.</p>
  ##   body: JObject (required)
  var body_594328 = newJObject()
  if body != nil:
    body_594328 = body
  result = call_594327.call(nil, nil, nil, nil, body_594328)

var putDeliverabilityDashboardOption* = Call_PutDeliverabilityDashboardOption_594315(
    name: "putDeliverabilityDashboardOption", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/deliverability-dashboard",
    validator: validate_PutDeliverabilityDashboardOption_594316, base: "/",
    url: url_PutDeliverabilityDashboardOption_594317,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeliverabilityDashboardOptions_594303 = ref object of OpenApiRestCall_593421
proc url_GetDeliverabilityDashboardOptions_594305(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeliverabilityDashboardOptions_594304(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieve information about the status of the Deliverability dashboard for your Amazon Pinpoint account. When the Deliverability dashboard is enabled, you gain access to reputation, deliverability, and other metrics for the domains that you use to send email using Amazon Pinpoint. You also gain the ability to perform predictive inbox placement tests.</p> <p>When you use the Deliverability dashboard, you pay a monthly subscription charge, in addition to any other fees that you accrue by using Amazon Pinpoint. For more information about the features and cost of a Deliverability dashboard subscription, see <a href="http://aws.amazon.com/pinpoint/pricing/">Amazon Pinpoint Pricing</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594313: Call_GetDeliverabilityDashboardOptions_594303;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Retrieve information about the status of the Deliverability dashboard for your Amazon Pinpoint account. When the Deliverability dashboard is enabled, you gain access to reputation, deliverability, and other metrics for the domains that you use to send email using Amazon Pinpoint. You also gain the ability to perform predictive inbox placement tests.</p> <p>When you use the Deliverability dashboard, you pay a monthly subscription charge, in addition to any other fees that you accrue by using Amazon Pinpoint. For more information about the features and cost of a Deliverability dashboard subscription, see <a href="http://aws.amazon.com/pinpoint/pricing/">Amazon Pinpoint Pricing</a>.</p>
  ## 
  let valid = call_594313.validator(path, query, header, formData, body)
  let scheme = call_594313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594313.url(scheme.get, call_594313.host, call_594313.base,
                         call_594313.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594313, url, valid)

proc call*(call_594314: Call_GetDeliverabilityDashboardOptions_594303): Recallable =
  ## getDeliverabilityDashboardOptions
  ## <p>Retrieve information about the status of the Deliverability dashboard for your Amazon Pinpoint account. When the Deliverability dashboard is enabled, you gain access to reputation, deliverability, and other metrics for the domains that you use to send email using Amazon Pinpoint. You also gain the ability to perform predictive inbox placement tests.</p> <p>When you use the Deliverability dashboard, you pay a monthly subscription charge, in addition to any other fees that you accrue by using Amazon Pinpoint. For more information about the features and cost of a Deliverability dashboard subscription, see <a href="http://aws.amazon.com/pinpoint/pricing/">Amazon Pinpoint Pricing</a>.</p>
  result = call_594314.call(nil, nil, nil, nil, nil)

var getDeliverabilityDashboardOptions* = Call_GetDeliverabilityDashboardOptions_594303(
    name: "getDeliverabilityDashboardOptions", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/deliverability-dashboard",
    validator: validate_GetDeliverabilityDashboardOptions_594304, base: "/",
    url: url_GetDeliverabilityDashboardOptions_594305,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeliverabilityTestReport_594329 = ref object of OpenApiRestCall_593421
proc url_GetDeliverabilityTestReport_594331(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ReportId" in path, "`ReportId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/v1/email/deliverability-dashboard/test-reports/"),
               (kind: VariableSegment, value: "ReportId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetDeliverabilityTestReport_594330(path: JsonNode; query: JsonNode;
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
  var valid_594332 = path.getOrDefault("ReportId")
  valid_594332 = validateParameter(valid_594332, JString, required = true,
                                 default = nil)
  if valid_594332 != nil:
    section.add "ReportId", valid_594332
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594333 = header.getOrDefault("X-Amz-Date")
  valid_594333 = validateParameter(valid_594333, JString, required = false,
                                 default = nil)
  if valid_594333 != nil:
    section.add "X-Amz-Date", valid_594333
  var valid_594334 = header.getOrDefault("X-Amz-Security-Token")
  valid_594334 = validateParameter(valid_594334, JString, required = false,
                                 default = nil)
  if valid_594334 != nil:
    section.add "X-Amz-Security-Token", valid_594334
  var valid_594335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594335 = validateParameter(valid_594335, JString, required = false,
                                 default = nil)
  if valid_594335 != nil:
    section.add "X-Amz-Content-Sha256", valid_594335
  var valid_594336 = header.getOrDefault("X-Amz-Algorithm")
  valid_594336 = validateParameter(valid_594336, JString, required = false,
                                 default = nil)
  if valid_594336 != nil:
    section.add "X-Amz-Algorithm", valid_594336
  var valid_594337 = header.getOrDefault("X-Amz-Signature")
  valid_594337 = validateParameter(valid_594337, JString, required = false,
                                 default = nil)
  if valid_594337 != nil:
    section.add "X-Amz-Signature", valid_594337
  var valid_594338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594338 = validateParameter(valid_594338, JString, required = false,
                                 default = nil)
  if valid_594338 != nil:
    section.add "X-Amz-SignedHeaders", valid_594338
  var valid_594339 = header.getOrDefault("X-Amz-Credential")
  valid_594339 = validateParameter(valid_594339, JString, required = false,
                                 default = nil)
  if valid_594339 != nil:
    section.add "X-Amz-Credential", valid_594339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594340: Call_GetDeliverabilityTestReport_594329; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve the results of a predictive inbox placement test.
  ## 
  let valid = call_594340.validator(path, query, header, formData, body)
  let scheme = call_594340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594340.url(scheme.get, call_594340.host, call_594340.base,
                         call_594340.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594340, url, valid)

proc call*(call_594341: Call_GetDeliverabilityTestReport_594329; ReportId: string): Recallable =
  ## getDeliverabilityTestReport
  ## Retrieve the results of a predictive inbox placement test.
  ##   ReportId: string (required)
  ##           : A unique string that identifies a Deliverability dashboard report.
  var path_594342 = newJObject()
  add(path_594342, "ReportId", newJString(ReportId))
  result = call_594341.call(path_594342, nil, nil, nil, nil)

var getDeliverabilityTestReport* = Call_GetDeliverabilityTestReport_594329(
    name: "getDeliverabilityTestReport", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com",
    route: "/v1/email/deliverability-dashboard/test-reports/{ReportId}",
    validator: validate_GetDeliverabilityTestReport_594330, base: "/",
    url: url_GetDeliverabilityTestReport_594331,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainDeliverabilityCampaign_594343 = ref object of OpenApiRestCall_593421
proc url_GetDomainDeliverabilityCampaign_594345(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "CampaignId" in path, "`CampaignId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/v1/email/deliverability-dashboard/campaigns/"),
               (kind: VariableSegment, value: "CampaignId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetDomainDeliverabilityCampaign_594344(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieve all the deliverability data for a specific campaign. This data is available for a campaign only if the campaign sent email by using a domain that the Deliverability dashboard is enabled for (<code>PutDeliverabilityDashboardOption</code> operation).
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   CampaignId: JString (required)
  ##             : The unique identifier for the campaign. Amazon Pinpoint automatically generates and assigns this identifier to a campaign. This value is not the same as the campaign identifier that Amazon Pinpoint assigns to campaigns that you create and manage by using the Amazon Pinpoint API or the Amazon Pinpoint console.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `CampaignId` field"
  var valid_594346 = path.getOrDefault("CampaignId")
  valid_594346 = validateParameter(valid_594346, JString, required = true,
                                 default = nil)
  if valid_594346 != nil:
    section.add "CampaignId", valid_594346
  result.add "path", section
  section = newJObject()
  result.add "query", section
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

proc call*(call_594354: Call_GetDomainDeliverabilityCampaign_594343;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieve all the deliverability data for a specific campaign. This data is available for a campaign only if the campaign sent email by using a domain that the Deliverability dashboard is enabled for (<code>PutDeliverabilityDashboardOption</code> operation).
  ## 
  let valid = call_594354.validator(path, query, header, formData, body)
  let scheme = call_594354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594354.url(scheme.get, call_594354.host, call_594354.base,
                         call_594354.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594354, url, valid)

proc call*(call_594355: Call_GetDomainDeliverabilityCampaign_594343;
          CampaignId: string): Recallable =
  ## getDomainDeliverabilityCampaign
  ## Retrieve all the deliverability data for a specific campaign. This data is available for a campaign only if the campaign sent email by using a domain that the Deliverability dashboard is enabled for (<code>PutDeliverabilityDashboardOption</code> operation).
  ##   CampaignId: string (required)
  ##             : The unique identifier for the campaign. Amazon Pinpoint automatically generates and assigns this identifier to a campaign. This value is not the same as the campaign identifier that Amazon Pinpoint assigns to campaigns that you create and manage by using the Amazon Pinpoint API or the Amazon Pinpoint console.
  var path_594356 = newJObject()
  add(path_594356, "CampaignId", newJString(CampaignId))
  result = call_594355.call(path_594356, nil, nil, nil, nil)

var getDomainDeliverabilityCampaign* = Call_GetDomainDeliverabilityCampaign_594343(
    name: "getDomainDeliverabilityCampaign", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com",
    route: "/v1/email/deliverability-dashboard/campaigns/{CampaignId}",
    validator: validate_GetDomainDeliverabilityCampaign_594344, base: "/",
    url: url_GetDomainDeliverabilityCampaign_594345,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDomainStatisticsReport_594357 = ref object of OpenApiRestCall_593421
proc url_GetDomainStatisticsReport_594359(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "Domain" in path, "`Domain` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/v1/email/deliverability-dashboard/statistics-report/"),
               (kind: VariableSegment, value: "Domain"),
               (kind: ConstantSegment, value: "#StartDate&EndDate")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetDomainStatisticsReport_594358(path: JsonNode; query: JsonNode;
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
  var valid_594360 = path.getOrDefault("Domain")
  valid_594360 = validateParameter(valid_594360, JString, required = true,
                                 default = nil)
  if valid_594360 != nil:
    section.add "Domain", valid_594360
  result.add "path", section
  ## parameters in `query` object:
  ##   EndDate: JString (required)
  ##          : The last day (in Unix time) that you want to obtain domain deliverability metrics for. The <code>EndDate</code> that you specify has to be less than or equal to 30 days after the <code>StartDate</code>.
  ##   StartDate: JString (required)
  ##            : The first day (in Unix time) that you want to obtain domain deliverability metrics for.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `EndDate` field"
  var valid_594361 = query.getOrDefault("EndDate")
  valid_594361 = validateParameter(valid_594361, JString, required = true,
                                 default = nil)
  if valid_594361 != nil:
    section.add "EndDate", valid_594361
  var valid_594362 = query.getOrDefault("StartDate")
  valid_594362 = validateParameter(valid_594362, JString, required = true,
                                 default = nil)
  if valid_594362 != nil:
    section.add "StartDate", valid_594362
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594363 = header.getOrDefault("X-Amz-Date")
  valid_594363 = validateParameter(valid_594363, JString, required = false,
                                 default = nil)
  if valid_594363 != nil:
    section.add "X-Amz-Date", valid_594363
  var valid_594364 = header.getOrDefault("X-Amz-Security-Token")
  valid_594364 = validateParameter(valid_594364, JString, required = false,
                                 default = nil)
  if valid_594364 != nil:
    section.add "X-Amz-Security-Token", valid_594364
  var valid_594365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594365 = validateParameter(valid_594365, JString, required = false,
                                 default = nil)
  if valid_594365 != nil:
    section.add "X-Amz-Content-Sha256", valid_594365
  var valid_594366 = header.getOrDefault("X-Amz-Algorithm")
  valid_594366 = validateParameter(valid_594366, JString, required = false,
                                 default = nil)
  if valid_594366 != nil:
    section.add "X-Amz-Algorithm", valid_594366
  var valid_594367 = header.getOrDefault("X-Amz-Signature")
  valid_594367 = validateParameter(valid_594367, JString, required = false,
                                 default = nil)
  if valid_594367 != nil:
    section.add "X-Amz-Signature", valid_594367
  var valid_594368 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594368 = validateParameter(valid_594368, JString, required = false,
                                 default = nil)
  if valid_594368 != nil:
    section.add "X-Amz-SignedHeaders", valid_594368
  var valid_594369 = header.getOrDefault("X-Amz-Credential")
  valid_594369 = validateParameter(valid_594369, JString, required = false,
                                 default = nil)
  if valid_594369 != nil:
    section.add "X-Amz-Credential", valid_594369
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594370: Call_GetDomainStatisticsReport_594357; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve inbox placement and engagement rates for the domains that you use to send email.
  ## 
  let valid = call_594370.validator(path, query, header, formData, body)
  let scheme = call_594370.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594370.url(scheme.get, call_594370.host, call_594370.base,
                         call_594370.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594370, url, valid)

proc call*(call_594371: Call_GetDomainStatisticsReport_594357; Domain: string;
          EndDate: string; StartDate: string): Recallable =
  ## getDomainStatisticsReport
  ## Retrieve inbox placement and engagement rates for the domains that you use to send email.
  ##   Domain: string (required)
  ##         : The domain that you want to obtain deliverability metrics for.
  ##   EndDate: string (required)
  ##          : The last day (in Unix time) that you want to obtain domain deliverability metrics for. The <code>EndDate</code> that you specify has to be less than or equal to 30 days after the <code>StartDate</code>.
  ##   StartDate: string (required)
  ##            : The first day (in Unix time) that you want to obtain domain deliverability metrics for.
  var path_594372 = newJObject()
  var query_594373 = newJObject()
  add(path_594372, "Domain", newJString(Domain))
  add(query_594373, "EndDate", newJString(EndDate))
  add(query_594373, "StartDate", newJString(StartDate))
  result = call_594371.call(path_594372, query_594373, nil, nil, nil)

var getDomainStatisticsReport* = Call_GetDomainStatisticsReport_594357(
    name: "getDomainStatisticsReport", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/deliverability-dashboard/statistics-report/{Domain}#StartDate&EndDate",
    validator: validate_GetDomainStatisticsReport_594358, base: "/",
    url: url_GetDomainStatisticsReport_594359,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeliverabilityTestReports_594374 = ref object of OpenApiRestCall_593421
proc url_ListDeliverabilityTestReports_594376(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDeliverabilityTestReports_594375(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Show a list of the predictive inbox placement tests that you've performed, regardless of their statuses. For predictive inbox placement tests that are complete, you can use the <code>GetDeliverabilityTestReport</code> operation to view the results.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PageSize: JInt
  ##           : <p>The number of results to show in a single call to <code>ListDeliverabilityTestReports</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.</p> <p>The value you specify has to be at least 0, and can be no more than 1000.</p>
  ##   NextToken: JString
  ##            : A token returned from a previous call to <code>ListDeliverabilityTestReports</code> to indicate the position in the list of predictive inbox placement tests.
  section = newJObject()
  var valid_594377 = query.getOrDefault("PageSize")
  valid_594377 = validateParameter(valid_594377, JInt, required = false, default = nil)
  if valid_594377 != nil:
    section.add "PageSize", valid_594377
  var valid_594378 = query.getOrDefault("NextToken")
  valid_594378 = validateParameter(valid_594378, JString, required = false,
                                 default = nil)
  if valid_594378 != nil:
    section.add "NextToken", valid_594378
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594379 = header.getOrDefault("X-Amz-Date")
  valid_594379 = validateParameter(valid_594379, JString, required = false,
                                 default = nil)
  if valid_594379 != nil:
    section.add "X-Amz-Date", valid_594379
  var valid_594380 = header.getOrDefault("X-Amz-Security-Token")
  valid_594380 = validateParameter(valid_594380, JString, required = false,
                                 default = nil)
  if valid_594380 != nil:
    section.add "X-Amz-Security-Token", valid_594380
  var valid_594381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594381 = validateParameter(valid_594381, JString, required = false,
                                 default = nil)
  if valid_594381 != nil:
    section.add "X-Amz-Content-Sha256", valid_594381
  var valid_594382 = header.getOrDefault("X-Amz-Algorithm")
  valid_594382 = validateParameter(valid_594382, JString, required = false,
                                 default = nil)
  if valid_594382 != nil:
    section.add "X-Amz-Algorithm", valid_594382
  var valid_594383 = header.getOrDefault("X-Amz-Signature")
  valid_594383 = validateParameter(valid_594383, JString, required = false,
                                 default = nil)
  if valid_594383 != nil:
    section.add "X-Amz-Signature", valid_594383
  var valid_594384 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594384 = validateParameter(valid_594384, JString, required = false,
                                 default = nil)
  if valid_594384 != nil:
    section.add "X-Amz-SignedHeaders", valid_594384
  var valid_594385 = header.getOrDefault("X-Amz-Credential")
  valid_594385 = validateParameter(valid_594385, JString, required = false,
                                 default = nil)
  if valid_594385 != nil:
    section.add "X-Amz-Credential", valid_594385
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594386: Call_ListDeliverabilityTestReports_594374; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Show a list of the predictive inbox placement tests that you've performed, regardless of their statuses. For predictive inbox placement tests that are complete, you can use the <code>GetDeliverabilityTestReport</code> operation to view the results.
  ## 
  let valid = call_594386.validator(path, query, header, formData, body)
  let scheme = call_594386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594386.url(scheme.get, call_594386.host, call_594386.base,
                         call_594386.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594386, url, valid)

proc call*(call_594387: Call_ListDeliverabilityTestReports_594374;
          PageSize: int = 0; NextToken: string = ""): Recallable =
  ## listDeliverabilityTestReports
  ## Show a list of the predictive inbox placement tests that you've performed, regardless of their statuses. For predictive inbox placement tests that are complete, you can use the <code>GetDeliverabilityTestReport</code> operation to view the results.
  ##   PageSize: int
  ##           : <p>The number of results to show in a single call to <code>ListDeliverabilityTestReports</code>. If the number of results is larger than the number you specified in this parameter, then the response includes a <code>NextToken</code> element, which you can use to obtain additional results.</p> <p>The value you specify has to be at least 0, and can be no more than 1000.</p>
  ##   NextToken: string
  ##            : A token returned from a previous call to <code>ListDeliverabilityTestReports</code> to indicate the position in the list of predictive inbox placement tests.
  var query_594388 = newJObject()
  add(query_594388, "PageSize", newJInt(PageSize))
  add(query_594388, "NextToken", newJString(NextToken))
  result = call_594387.call(nil, query_594388, nil, nil, nil)

var listDeliverabilityTestReports* = Call_ListDeliverabilityTestReports_594374(
    name: "listDeliverabilityTestReports", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com",
    route: "/v1/email/deliverability-dashboard/test-reports",
    validator: validate_ListDeliverabilityTestReports_594375, base: "/",
    url: url_ListDeliverabilityTestReports_594376,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDomainDeliverabilityCampaigns_594389 = ref object of OpenApiRestCall_593421
proc url_ListDomainDeliverabilityCampaigns_594391(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "SubscribedDomain" in path,
        "`SubscribedDomain` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment,
                value: "/v1/email/deliverability-dashboard/domains/"),
               (kind: VariableSegment, value: "SubscribedDomain"),
               (kind: ConstantSegment, value: "/campaigns#StartDate&EndDate")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListDomainDeliverabilityCampaigns_594390(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieve deliverability data for all the campaigns that used a specific domain to send email during a specified time range. This data is available for a domain only if you enabled the Deliverability dashboard (<code>PutDeliverabilityDashboardOption</code> operation) for the domain.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   SubscribedDomain: JString (required)
  ##                   : The domain to obtain deliverability data for.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `SubscribedDomain` field"
  var valid_594392 = path.getOrDefault("SubscribedDomain")
  valid_594392 = validateParameter(valid_594392, JString, required = true,
                                 default = nil)
  if valid_594392 != nil:
    section.add "SubscribedDomain", valid_594392
  result.add "path", section
  ## parameters in `query` object:
  ##   EndDate: JString (required)
  ##          : The last day, in Unix time format, that you want to obtain deliverability data for. This value has to be less than or equal to 30 days after the value of the <code>StartDate</code> parameter.
  ##   PageSize: JInt
  ##           : The maximum number of results to include in response to a single call to the <code>ListDomainDeliverabilityCampaigns</code> operation. If the number of results is larger than the number that you specify in this parameter, the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  ##   NextToken: JString
  ##            : A token that’s returned from a previous call to the <code>ListDomainDeliverabilityCampaigns</code> operation. This token indicates the position of a campaign in the list of campaigns.
  ##   StartDate: JString (required)
  ##            : The first day, in Unix time format, that you want to obtain deliverability data for.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `EndDate` field"
  var valid_594393 = query.getOrDefault("EndDate")
  valid_594393 = validateParameter(valid_594393, JString, required = true,
                                 default = nil)
  if valid_594393 != nil:
    section.add "EndDate", valid_594393
  var valid_594394 = query.getOrDefault("PageSize")
  valid_594394 = validateParameter(valid_594394, JInt, required = false, default = nil)
  if valid_594394 != nil:
    section.add "PageSize", valid_594394
  var valid_594395 = query.getOrDefault("NextToken")
  valid_594395 = validateParameter(valid_594395, JString, required = false,
                                 default = nil)
  if valid_594395 != nil:
    section.add "NextToken", valid_594395
  var valid_594396 = query.getOrDefault("StartDate")
  valid_594396 = validateParameter(valid_594396, JString, required = true,
                                 default = nil)
  if valid_594396 != nil:
    section.add "StartDate", valid_594396
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594397 = header.getOrDefault("X-Amz-Date")
  valid_594397 = validateParameter(valid_594397, JString, required = false,
                                 default = nil)
  if valid_594397 != nil:
    section.add "X-Amz-Date", valid_594397
  var valid_594398 = header.getOrDefault("X-Amz-Security-Token")
  valid_594398 = validateParameter(valid_594398, JString, required = false,
                                 default = nil)
  if valid_594398 != nil:
    section.add "X-Amz-Security-Token", valid_594398
  var valid_594399 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594399 = validateParameter(valid_594399, JString, required = false,
                                 default = nil)
  if valid_594399 != nil:
    section.add "X-Amz-Content-Sha256", valid_594399
  var valid_594400 = header.getOrDefault("X-Amz-Algorithm")
  valid_594400 = validateParameter(valid_594400, JString, required = false,
                                 default = nil)
  if valid_594400 != nil:
    section.add "X-Amz-Algorithm", valid_594400
  var valid_594401 = header.getOrDefault("X-Amz-Signature")
  valid_594401 = validateParameter(valid_594401, JString, required = false,
                                 default = nil)
  if valid_594401 != nil:
    section.add "X-Amz-Signature", valid_594401
  var valid_594402 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594402 = validateParameter(valid_594402, JString, required = false,
                                 default = nil)
  if valid_594402 != nil:
    section.add "X-Amz-SignedHeaders", valid_594402
  var valid_594403 = header.getOrDefault("X-Amz-Credential")
  valid_594403 = validateParameter(valid_594403, JString, required = false,
                                 default = nil)
  if valid_594403 != nil:
    section.add "X-Amz-Credential", valid_594403
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594404: Call_ListDomainDeliverabilityCampaigns_594389;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieve deliverability data for all the campaigns that used a specific domain to send email during a specified time range. This data is available for a domain only if you enabled the Deliverability dashboard (<code>PutDeliverabilityDashboardOption</code> operation) for the domain.
  ## 
  let valid = call_594404.validator(path, query, header, formData, body)
  let scheme = call_594404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594404.url(scheme.get, call_594404.host, call_594404.base,
                         call_594404.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594404, url, valid)

proc call*(call_594405: Call_ListDomainDeliverabilityCampaigns_594389;
          EndDate: string; SubscribedDomain: string; StartDate: string;
          PageSize: int = 0; NextToken: string = ""): Recallable =
  ## listDomainDeliverabilityCampaigns
  ## Retrieve deliverability data for all the campaigns that used a specific domain to send email during a specified time range. This data is available for a domain only if you enabled the Deliverability dashboard (<code>PutDeliverabilityDashboardOption</code> operation) for the domain.
  ##   EndDate: string (required)
  ##          : The last day, in Unix time format, that you want to obtain deliverability data for. This value has to be less than or equal to 30 days after the value of the <code>StartDate</code> parameter.
  ##   PageSize: int
  ##           : The maximum number of results to include in response to a single call to the <code>ListDomainDeliverabilityCampaigns</code> operation. If the number of results is larger than the number that you specify in this parameter, the response includes a <code>NextToken</code> element, which you can use to obtain additional results.
  ##   NextToken: string
  ##            : A token that’s returned from a previous call to the <code>ListDomainDeliverabilityCampaigns</code> operation. This token indicates the position of a campaign in the list of campaigns.
  ##   SubscribedDomain: string (required)
  ##                   : The domain to obtain deliverability data for.
  ##   StartDate: string (required)
  ##            : The first day, in Unix time format, that you want to obtain deliverability data for.
  var path_594406 = newJObject()
  var query_594407 = newJObject()
  add(query_594407, "EndDate", newJString(EndDate))
  add(query_594407, "PageSize", newJInt(PageSize))
  add(query_594407, "NextToken", newJString(NextToken))
  add(path_594406, "SubscribedDomain", newJString(SubscribedDomain))
  add(query_594407, "StartDate", newJString(StartDate))
  result = call_594405.call(path_594406, query_594407, nil, nil, nil)

var listDomainDeliverabilityCampaigns* = Call_ListDomainDeliverabilityCampaigns_594389(
    name: "listDomainDeliverabilityCampaigns", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/deliverability-dashboard/domains/{SubscribedDomain}/campaigns#StartDate&EndDate",
    validator: validate_ListDomainDeliverabilityCampaigns_594390, base: "/",
    url: url_ListDomainDeliverabilityCampaigns_594391,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_594408 = ref object of OpenApiRestCall_593421
proc url_ListTagsForResource_594410(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsForResource_594409(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Retrieve a list of the tags (keys and values) that are associated with a specified resource. A <i>tag</i> is a label that you optionally define and associate with a resource in Amazon Pinpoint. Each tag consists of a required <i>tag key</i> and an optional associated <i>tag value</i>. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.
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
  var valid_594411 = query.getOrDefault("ResourceArn")
  valid_594411 = validateParameter(valid_594411, JString, required = true,
                                 default = nil)
  if valid_594411 != nil:
    section.add "ResourceArn", valid_594411
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594412 = header.getOrDefault("X-Amz-Date")
  valid_594412 = validateParameter(valid_594412, JString, required = false,
                                 default = nil)
  if valid_594412 != nil:
    section.add "X-Amz-Date", valid_594412
  var valid_594413 = header.getOrDefault("X-Amz-Security-Token")
  valid_594413 = validateParameter(valid_594413, JString, required = false,
                                 default = nil)
  if valid_594413 != nil:
    section.add "X-Amz-Security-Token", valid_594413
  var valid_594414 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594414 = validateParameter(valid_594414, JString, required = false,
                                 default = nil)
  if valid_594414 != nil:
    section.add "X-Amz-Content-Sha256", valid_594414
  var valid_594415 = header.getOrDefault("X-Amz-Algorithm")
  valid_594415 = validateParameter(valid_594415, JString, required = false,
                                 default = nil)
  if valid_594415 != nil:
    section.add "X-Amz-Algorithm", valid_594415
  var valid_594416 = header.getOrDefault("X-Amz-Signature")
  valid_594416 = validateParameter(valid_594416, JString, required = false,
                                 default = nil)
  if valid_594416 != nil:
    section.add "X-Amz-Signature", valid_594416
  var valid_594417 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594417 = validateParameter(valid_594417, JString, required = false,
                                 default = nil)
  if valid_594417 != nil:
    section.add "X-Amz-SignedHeaders", valid_594417
  var valid_594418 = header.getOrDefault("X-Amz-Credential")
  valid_594418 = validateParameter(valid_594418, JString, required = false,
                                 default = nil)
  if valid_594418 != nil:
    section.add "X-Amz-Credential", valid_594418
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594419: Call_ListTagsForResource_594408; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a list of the tags (keys and values) that are associated with a specified resource. A <i>tag</i> is a label that you optionally define and associate with a resource in Amazon Pinpoint. Each tag consists of a required <i>tag key</i> and an optional associated <i>tag value</i>. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.
  ## 
  let valid = call_594419.validator(path, query, header, formData, body)
  let scheme = call_594419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594419.url(scheme.get, call_594419.host, call_594419.base,
                         call_594419.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594419, url, valid)

proc call*(call_594420: Call_ListTagsForResource_594408; ResourceArn: string): Recallable =
  ## listTagsForResource
  ## Retrieve a list of the tags (keys and values) that are associated with a specified resource. A <i>tag</i> is a label that you optionally define and associate with a resource in Amazon Pinpoint. Each tag consists of a required <i>tag key</i> and an optional associated <i>tag value</i>. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.
  ##   ResourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource that you want to retrieve tag information for.
  var query_594421 = newJObject()
  add(query_594421, "ResourceArn", newJString(ResourceArn))
  result = call_594420.call(nil, query_594421, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_594408(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "email.amazonaws.com", route: "/v1/email/tags#ResourceArn",
    validator: validate_ListTagsForResource_594409, base: "/",
    url: url_ListTagsForResource_594410, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAccountDedicatedIpWarmupAttributes_594422 = ref object of OpenApiRestCall_593421
proc url_PutAccountDedicatedIpWarmupAttributes_594424(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutAccountDedicatedIpWarmupAttributes_594423(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594425 = header.getOrDefault("X-Amz-Date")
  valid_594425 = validateParameter(valid_594425, JString, required = false,
                                 default = nil)
  if valid_594425 != nil:
    section.add "X-Amz-Date", valid_594425
  var valid_594426 = header.getOrDefault("X-Amz-Security-Token")
  valid_594426 = validateParameter(valid_594426, JString, required = false,
                                 default = nil)
  if valid_594426 != nil:
    section.add "X-Amz-Security-Token", valid_594426
  var valid_594427 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594427 = validateParameter(valid_594427, JString, required = false,
                                 default = nil)
  if valid_594427 != nil:
    section.add "X-Amz-Content-Sha256", valid_594427
  var valid_594428 = header.getOrDefault("X-Amz-Algorithm")
  valid_594428 = validateParameter(valid_594428, JString, required = false,
                                 default = nil)
  if valid_594428 != nil:
    section.add "X-Amz-Algorithm", valid_594428
  var valid_594429 = header.getOrDefault("X-Amz-Signature")
  valid_594429 = validateParameter(valid_594429, JString, required = false,
                                 default = nil)
  if valid_594429 != nil:
    section.add "X-Amz-Signature", valid_594429
  var valid_594430 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594430 = validateParameter(valid_594430, JString, required = false,
                                 default = nil)
  if valid_594430 != nil:
    section.add "X-Amz-SignedHeaders", valid_594430
  var valid_594431 = header.getOrDefault("X-Amz-Credential")
  valid_594431 = validateParameter(valid_594431, JString, required = false,
                                 default = nil)
  if valid_594431 != nil:
    section.add "X-Amz-Credential", valid_594431
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594433: Call_PutAccountDedicatedIpWarmupAttributes_594422;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Enable or disable the automatic warm-up feature for dedicated IP addresses.
  ## 
  let valid = call_594433.validator(path, query, header, formData, body)
  let scheme = call_594433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594433.url(scheme.get, call_594433.host, call_594433.base,
                         call_594433.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594433, url, valid)

proc call*(call_594434: Call_PutAccountDedicatedIpWarmupAttributes_594422;
          body: JsonNode): Recallable =
  ## putAccountDedicatedIpWarmupAttributes
  ## Enable or disable the automatic warm-up feature for dedicated IP addresses.
  ##   body: JObject (required)
  var body_594435 = newJObject()
  if body != nil:
    body_594435 = body
  result = call_594434.call(nil, nil, nil, nil, body_594435)

var putAccountDedicatedIpWarmupAttributes* = Call_PutAccountDedicatedIpWarmupAttributes_594422(
    name: "putAccountDedicatedIpWarmupAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/account/dedicated-ips/warmup",
    validator: validate_PutAccountDedicatedIpWarmupAttributes_594423, base: "/",
    url: url_PutAccountDedicatedIpWarmupAttributes_594424,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAccountSendingAttributes_594436 = ref object of OpenApiRestCall_593421
proc url_PutAccountSendingAttributes_594438(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutAccountSendingAttributes_594437(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594439 = header.getOrDefault("X-Amz-Date")
  valid_594439 = validateParameter(valid_594439, JString, required = false,
                                 default = nil)
  if valid_594439 != nil:
    section.add "X-Amz-Date", valid_594439
  var valid_594440 = header.getOrDefault("X-Amz-Security-Token")
  valid_594440 = validateParameter(valid_594440, JString, required = false,
                                 default = nil)
  if valid_594440 != nil:
    section.add "X-Amz-Security-Token", valid_594440
  var valid_594441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594441 = validateParameter(valid_594441, JString, required = false,
                                 default = nil)
  if valid_594441 != nil:
    section.add "X-Amz-Content-Sha256", valid_594441
  var valid_594442 = header.getOrDefault("X-Amz-Algorithm")
  valid_594442 = validateParameter(valid_594442, JString, required = false,
                                 default = nil)
  if valid_594442 != nil:
    section.add "X-Amz-Algorithm", valid_594442
  var valid_594443 = header.getOrDefault("X-Amz-Signature")
  valid_594443 = validateParameter(valid_594443, JString, required = false,
                                 default = nil)
  if valid_594443 != nil:
    section.add "X-Amz-Signature", valid_594443
  var valid_594444 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594444 = validateParameter(valid_594444, JString, required = false,
                                 default = nil)
  if valid_594444 != nil:
    section.add "X-Amz-SignedHeaders", valid_594444
  var valid_594445 = header.getOrDefault("X-Amz-Credential")
  valid_594445 = validateParameter(valid_594445, JString, required = false,
                                 default = nil)
  if valid_594445 != nil:
    section.add "X-Amz-Credential", valid_594445
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594447: Call_PutAccountSendingAttributes_594436; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Enable or disable the ability of your account to send email.
  ## 
  let valid = call_594447.validator(path, query, header, formData, body)
  let scheme = call_594447.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594447.url(scheme.get, call_594447.host, call_594447.base,
                         call_594447.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594447, url, valid)

proc call*(call_594448: Call_PutAccountSendingAttributes_594436; body: JsonNode): Recallable =
  ## putAccountSendingAttributes
  ## Enable or disable the ability of your account to send email.
  ##   body: JObject (required)
  var body_594449 = newJObject()
  if body != nil:
    body_594449 = body
  result = call_594448.call(nil, nil, nil, nil, body_594449)

var putAccountSendingAttributes* = Call_PutAccountSendingAttributes_594436(
    name: "putAccountSendingAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/account/sending",
    validator: validate_PutAccountSendingAttributes_594437, base: "/",
    url: url_PutAccountSendingAttributes_594438,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConfigurationSetDeliveryOptions_594450 = ref object of OpenApiRestCall_593421
proc url_PutConfigurationSetDeliveryOptions_594452(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
        "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/configuration-sets/"),
               (kind: VariableSegment, value: "ConfigurationSetName"),
               (kind: ConstantSegment, value: "/delivery-options")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PutConfigurationSetDeliveryOptions_594451(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Associate a configuration set with a dedicated IP pool. You can use dedicated IP pools to create groups of dedicated IP addresses for sending specific types of email.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_594453 = path.getOrDefault("ConfigurationSetName")
  valid_594453 = validateParameter(valid_594453, JString, required = true,
                                 default = nil)
  if valid_594453 != nil:
    section.add "ConfigurationSetName", valid_594453
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594454 = header.getOrDefault("X-Amz-Date")
  valid_594454 = validateParameter(valid_594454, JString, required = false,
                                 default = nil)
  if valid_594454 != nil:
    section.add "X-Amz-Date", valid_594454
  var valid_594455 = header.getOrDefault("X-Amz-Security-Token")
  valid_594455 = validateParameter(valid_594455, JString, required = false,
                                 default = nil)
  if valid_594455 != nil:
    section.add "X-Amz-Security-Token", valid_594455
  var valid_594456 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594456 = validateParameter(valid_594456, JString, required = false,
                                 default = nil)
  if valid_594456 != nil:
    section.add "X-Amz-Content-Sha256", valid_594456
  var valid_594457 = header.getOrDefault("X-Amz-Algorithm")
  valid_594457 = validateParameter(valid_594457, JString, required = false,
                                 default = nil)
  if valid_594457 != nil:
    section.add "X-Amz-Algorithm", valid_594457
  var valid_594458 = header.getOrDefault("X-Amz-Signature")
  valid_594458 = validateParameter(valid_594458, JString, required = false,
                                 default = nil)
  if valid_594458 != nil:
    section.add "X-Amz-Signature", valid_594458
  var valid_594459 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594459 = validateParameter(valid_594459, JString, required = false,
                                 default = nil)
  if valid_594459 != nil:
    section.add "X-Amz-SignedHeaders", valid_594459
  var valid_594460 = header.getOrDefault("X-Amz-Credential")
  valid_594460 = validateParameter(valid_594460, JString, required = false,
                                 default = nil)
  if valid_594460 != nil:
    section.add "X-Amz-Credential", valid_594460
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594462: Call_PutConfigurationSetDeliveryOptions_594450;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Associate a configuration set with a dedicated IP pool. You can use dedicated IP pools to create groups of dedicated IP addresses for sending specific types of email.
  ## 
  let valid = call_594462.validator(path, query, header, formData, body)
  let scheme = call_594462.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594462.url(scheme.get, call_594462.host, call_594462.base,
                         call_594462.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594462, url, valid)

proc call*(call_594463: Call_PutConfigurationSetDeliveryOptions_594450;
          ConfigurationSetName: string; body: JsonNode): Recallable =
  ## putConfigurationSetDeliveryOptions
  ## Associate a configuration set with a dedicated IP pool. You can use dedicated IP pools to create groups of dedicated IP addresses for sending specific types of email.
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   body: JObject (required)
  var path_594464 = newJObject()
  var body_594465 = newJObject()
  add(path_594464, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_594465 = body
  result = call_594463.call(path_594464, nil, nil, nil, body_594465)

var putConfigurationSetDeliveryOptions* = Call_PutConfigurationSetDeliveryOptions_594450(
    name: "putConfigurationSetDeliveryOptions", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets/{ConfigurationSetName}/delivery-options",
    validator: validate_PutConfigurationSetDeliveryOptions_594451, base: "/",
    url: url_PutConfigurationSetDeliveryOptions_594452,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConfigurationSetReputationOptions_594466 = ref object of OpenApiRestCall_593421
proc url_PutConfigurationSetReputationOptions_594468(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
        "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/configuration-sets/"),
               (kind: VariableSegment, value: "ConfigurationSetName"),
               (kind: ConstantSegment, value: "/reputation-options")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PutConfigurationSetReputationOptions_594467(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Enable or disable collection of reputation metrics for emails that you send using a particular configuration set in a specific AWS Region.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_594469 = path.getOrDefault("ConfigurationSetName")
  valid_594469 = validateParameter(valid_594469, JString, required = true,
                                 default = nil)
  if valid_594469 != nil:
    section.add "ConfigurationSetName", valid_594469
  result.add "path", section
  section = newJObject()
  result.add "query", section
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594478: Call_PutConfigurationSetReputationOptions_594466;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Enable or disable collection of reputation metrics for emails that you send using a particular configuration set in a specific AWS Region.
  ## 
  let valid = call_594478.validator(path, query, header, formData, body)
  let scheme = call_594478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594478.url(scheme.get, call_594478.host, call_594478.base,
                         call_594478.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594478, url, valid)

proc call*(call_594479: Call_PutConfigurationSetReputationOptions_594466;
          ConfigurationSetName: string; body: JsonNode): Recallable =
  ## putConfigurationSetReputationOptions
  ## Enable or disable collection of reputation metrics for emails that you send using a particular configuration set in a specific AWS Region.
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   body: JObject (required)
  var path_594480 = newJObject()
  var body_594481 = newJObject()
  add(path_594480, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_594481 = body
  result = call_594479.call(path_594480, nil, nil, nil, body_594481)

var putConfigurationSetReputationOptions* = Call_PutConfigurationSetReputationOptions_594466(
    name: "putConfigurationSetReputationOptions", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets/{ConfigurationSetName}/reputation-options",
    validator: validate_PutConfigurationSetReputationOptions_594467, base: "/",
    url: url_PutConfigurationSetReputationOptions_594468,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConfigurationSetSendingOptions_594482 = ref object of OpenApiRestCall_593421
proc url_PutConfigurationSetSendingOptions_594484(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
        "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/configuration-sets/"),
               (kind: VariableSegment, value: "ConfigurationSetName"),
               (kind: ConstantSegment, value: "/sending")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PutConfigurationSetSendingOptions_594483(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Enable or disable email sending for messages that use a particular configuration set in a specific AWS Region.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_594485 = path.getOrDefault("ConfigurationSetName")
  valid_594485 = validateParameter(valid_594485, JString, required = true,
                                 default = nil)
  if valid_594485 != nil:
    section.add "ConfigurationSetName", valid_594485
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594486 = header.getOrDefault("X-Amz-Date")
  valid_594486 = validateParameter(valid_594486, JString, required = false,
                                 default = nil)
  if valid_594486 != nil:
    section.add "X-Amz-Date", valid_594486
  var valid_594487 = header.getOrDefault("X-Amz-Security-Token")
  valid_594487 = validateParameter(valid_594487, JString, required = false,
                                 default = nil)
  if valid_594487 != nil:
    section.add "X-Amz-Security-Token", valid_594487
  var valid_594488 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594488 = validateParameter(valid_594488, JString, required = false,
                                 default = nil)
  if valid_594488 != nil:
    section.add "X-Amz-Content-Sha256", valid_594488
  var valid_594489 = header.getOrDefault("X-Amz-Algorithm")
  valid_594489 = validateParameter(valid_594489, JString, required = false,
                                 default = nil)
  if valid_594489 != nil:
    section.add "X-Amz-Algorithm", valid_594489
  var valid_594490 = header.getOrDefault("X-Amz-Signature")
  valid_594490 = validateParameter(valid_594490, JString, required = false,
                                 default = nil)
  if valid_594490 != nil:
    section.add "X-Amz-Signature", valid_594490
  var valid_594491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594491 = validateParameter(valid_594491, JString, required = false,
                                 default = nil)
  if valid_594491 != nil:
    section.add "X-Amz-SignedHeaders", valid_594491
  var valid_594492 = header.getOrDefault("X-Amz-Credential")
  valid_594492 = validateParameter(valid_594492, JString, required = false,
                                 default = nil)
  if valid_594492 != nil:
    section.add "X-Amz-Credential", valid_594492
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594494: Call_PutConfigurationSetSendingOptions_594482;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Enable or disable email sending for messages that use a particular configuration set in a specific AWS Region.
  ## 
  let valid = call_594494.validator(path, query, header, formData, body)
  let scheme = call_594494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594494.url(scheme.get, call_594494.host, call_594494.base,
                         call_594494.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594494, url, valid)

proc call*(call_594495: Call_PutConfigurationSetSendingOptions_594482;
          ConfigurationSetName: string; body: JsonNode): Recallable =
  ## putConfigurationSetSendingOptions
  ## Enable or disable email sending for messages that use a particular configuration set in a specific AWS Region.
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   body: JObject (required)
  var path_594496 = newJObject()
  var body_594497 = newJObject()
  add(path_594496, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_594497 = body
  result = call_594495.call(path_594496, nil, nil, nil, body_594497)

var putConfigurationSetSendingOptions* = Call_PutConfigurationSetSendingOptions_594482(
    name: "putConfigurationSetSendingOptions", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com",
    route: "/v1/email/configuration-sets/{ConfigurationSetName}/sending",
    validator: validate_PutConfigurationSetSendingOptions_594483, base: "/",
    url: url_PutConfigurationSetSendingOptions_594484,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConfigurationSetTrackingOptions_594498 = ref object of OpenApiRestCall_593421
proc url_PutConfigurationSetTrackingOptions_594500(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ConfigurationSetName" in path,
        "`ConfigurationSetName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/configuration-sets/"),
               (kind: VariableSegment, value: "ConfigurationSetName"),
               (kind: ConstantSegment, value: "/tracking-options")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PutConfigurationSetTrackingOptions_594499(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Specify a custom domain to use for open and click tracking elements in email that you send using Amazon Pinpoint.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ConfigurationSetName: JString (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ConfigurationSetName` field"
  var valid_594501 = path.getOrDefault("ConfigurationSetName")
  valid_594501 = validateParameter(valid_594501, JString, required = true,
                                 default = nil)
  if valid_594501 != nil:
    section.add "ConfigurationSetName", valid_594501
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594502 = header.getOrDefault("X-Amz-Date")
  valid_594502 = validateParameter(valid_594502, JString, required = false,
                                 default = nil)
  if valid_594502 != nil:
    section.add "X-Amz-Date", valid_594502
  var valid_594503 = header.getOrDefault("X-Amz-Security-Token")
  valid_594503 = validateParameter(valid_594503, JString, required = false,
                                 default = nil)
  if valid_594503 != nil:
    section.add "X-Amz-Security-Token", valid_594503
  var valid_594504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594504 = validateParameter(valid_594504, JString, required = false,
                                 default = nil)
  if valid_594504 != nil:
    section.add "X-Amz-Content-Sha256", valid_594504
  var valid_594505 = header.getOrDefault("X-Amz-Algorithm")
  valid_594505 = validateParameter(valid_594505, JString, required = false,
                                 default = nil)
  if valid_594505 != nil:
    section.add "X-Amz-Algorithm", valid_594505
  var valid_594506 = header.getOrDefault("X-Amz-Signature")
  valid_594506 = validateParameter(valid_594506, JString, required = false,
                                 default = nil)
  if valid_594506 != nil:
    section.add "X-Amz-Signature", valid_594506
  var valid_594507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594507 = validateParameter(valid_594507, JString, required = false,
                                 default = nil)
  if valid_594507 != nil:
    section.add "X-Amz-SignedHeaders", valid_594507
  var valid_594508 = header.getOrDefault("X-Amz-Credential")
  valid_594508 = validateParameter(valid_594508, JString, required = false,
                                 default = nil)
  if valid_594508 != nil:
    section.add "X-Amz-Credential", valid_594508
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594510: Call_PutConfigurationSetTrackingOptions_594498;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Specify a custom domain to use for open and click tracking elements in email that you send using Amazon Pinpoint.
  ## 
  let valid = call_594510.validator(path, query, header, formData, body)
  let scheme = call_594510.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594510.url(scheme.get, call_594510.host, call_594510.base,
                         call_594510.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594510, url, valid)

proc call*(call_594511: Call_PutConfigurationSetTrackingOptions_594498;
          ConfigurationSetName: string; body: JsonNode): Recallable =
  ## putConfigurationSetTrackingOptions
  ## Specify a custom domain to use for open and click tracking elements in email that you send using Amazon Pinpoint.
  ##   ConfigurationSetName: string (required)
  ##                       : <p>The name of a configuration set.</p> <p>In Amazon Pinpoint, <i>configuration sets</i> are groups of rules that you can apply to the emails you send. You apply a configuration set to an email by including a reference to the configuration set in the headers of the email. When you apply a configuration set to an email, all of the rules in that configuration set are applied to the email.</p>
  ##   body: JObject (required)
  var path_594512 = newJObject()
  var body_594513 = newJObject()
  add(path_594512, "ConfigurationSetName", newJString(ConfigurationSetName))
  if body != nil:
    body_594513 = body
  result = call_594511.call(path_594512, nil, nil, nil, body_594513)

var putConfigurationSetTrackingOptions* = Call_PutConfigurationSetTrackingOptions_594498(
    name: "putConfigurationSetTrackingOptions", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/configuration-sets/{ConfigurationSetName}/tracking-options",
    validator: validate_PutConfigurationSetTrackingOptions_594499, base: "/",
    url: url_PutConfigurationSetTrackingOptions_594500,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDedicatedIpInPool_594514 = ref object of OpenApiRestCall_593421
proc url_PutDedicatedIpInPool_594516(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "IP" in path, "`IP` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/dedicated-ips/"),
               (kind: VariableSegment, value: "IP"),
               (kind: ConstantSegment, value: "/pool")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PutDedicatedIpInPool_594515(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Move a dedicated IP address to an existing dedicated IP pool.</p> <note> <p>The dedicated IP address that you specify must already exist, and must be associated with your Amazon Pinpoint account. </p> <p>The dedicated IP pool you specify must already exist. You can create a new pool by using the <code>CreateDedicatedIpPool</code> operation.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   IP: JString (required)
  ##     : A dedicated IP address that is associated with your Amazon Pinpoint account.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `IP` field"
  var valid_594517 = path.getOrDefault("IP")
  valid_594517 = validateParameter(valid_594517, JString, required = true,
                                 default = nil)
  if valid_594517 != nil:
    section.add "IP", valid_594517
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594518 = header.getOrDefault("X-Amz-Date")
  valid_594518 = validateParameter(valid_594518, JString, required = false,
                                 default = nil)
  if valid_594518 != nil:
    section.add "X-Amz-Date", valid_594518
  var valid_594519 = header.getOrDefault("X-Amz-Security-Token")
  valid_594519 = validateParameter(valid_594519, JString, required = false,
                                 default = nil)
  if valid_594519 != nil:
    section.add "X-Amz-Security-Token", valid_594519
  var valid_594520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594520 = validateParameter(valid_594520, JString, required = false,
                                 default = nil)
  if valid_594520 != nil:
    section.add "X-Amz-Content-Sha256", valid_594520
  var valid_594521 = header.getOrDefault("X-Amz-Algorithm")
  valid_594521 = validateParameter(valid_594521, JString, required = false,
                                 default = nil)
  if valid_594521 != nil:
    section.add "X-Amz-Algorithm", valid_594521
  var valid_594522 = header.getOrDefault("X-Amz-Signature")
  valid_594522 = validateParameter(valid_594522, JString, required = false,
                                 default = nil)
  if valid_594522 != nil:
    section.add "X-Amz-Signature", valid_594522
  var valid_594523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594523 = validateParameter(valid_594523, JString, required = false,
                                 default = nil)
  if valid_594523 != nil:
    section.add "X-Amz-SignedHeaders", valid_594523
  var valid_594524 = header.getOrDefault("X-Amz-Credential")
  valid_594524 = validateParameter(valid_594524, JString, required = false,
                                 default = nil)
  if valid_594524 != nil:
    section.add "X-Amz-Credential", valid_594524
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594526: Call_PutDedicatedIpInPool_594514; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Move a dedicated IP address to an existing dedicated IP pool.</p> <note> <p>The dedicated IP address that you specify must already exist, and must be associated with your Amazon Pinpoint account. </p> <p>The dedicated IP pool you specify must already exist. You can create a new pool by using the <code>CreateDedicatedIpPool</code> operation.</p> </note>
  ## 
  let valid = call_594526.validator(path, query, header, formData, body)
  let scheme = call_594526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594526.url(scheme.get, call_594526.host, call_594526.base,
                         call_594526.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594526, url, valid)

proc call*(call_594527: Call_PutDedicatedIpInPool_594514; IP: string; body: JsonNode): Recallable =
  ## putDedicatedIpInPool
  ## <p>Move a dedicated IP address to an existing dedicated IP pool.</p> <note> <p>The dedicated IP address that you specify must already exist, and must be associated with your Amazon Pinpoint account. </p> <p>The dedicated IP pool you specify must already exist. You can create a new pool by using the <code>CreateDedicatedIpPool</code> operation.</p> </note>
  ##   IP: string (required)
  ##     : A dedicated IP address that is associated with your Amazon Pinpoint account.
  ##   body: JObject (required)
  var path_594528 = newJObject()
  var body_594529 = newJObject()
  add(path_594528, "IP", newJString(IP))
  if body != nil:
    body_594529 = body
  result = call_594527.call(path_594528, nil, nil, nil, body_594529)

var putDedicatedIpInPool* = Call_PutDedicatedIpInPool_594514(
    name: "putDedicatedIpInPool", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/dedicated-ips/{IP}/pool",
    validator: validate_PutDedicatedIpInPool_594515, base: "/",
    url: url_PutDedicatedIpInPool_594516, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDedicatedIpWarmupAttributes_594530 = ref object of OpenApiRestCall_593421
proc url_PutDedicatedIpWarmupAttributes_594532(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "IP" in path, "`IP` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/dedicated-ips/"),
               (kind: VariableSegment, value: "IP"),
               (kind: ConstantSegment, value: "/warmup")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PutDedicatedIpWarmupAttributes_594531(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p/>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   IP: JString (required)
  ##     : A dedicated IP address that is associated with your Amazon Pinpoint account.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `IP` field"
  var valid_594533 = path.getOrDefault("IP")
  valid_594533 = validateParameter(valid_594533, JString, required = true,
                                 default = nil)
  if valid_594533 != nil:
    section.add "IP", valid_594533
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594534 = header.getOrDefault("X-Amz-Date")
  valid_594534 = validateParameter(valid_594534, JString, required = false,
                                 default = nil)
  if valid_594534 != nil:
    section.add "X-Amz-Date", valid_594534
  var valid_594535 = header.getOrDefault("X-Amz-Security-Token")
  valid_594535 = validateParameter(valid_594535, JString, required = false,
                                 default = nil)
  if valid_594535 != nil:
    section.add "X-Amz-Security-Token", valid_594535
  var valid_594536 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594536 = validateParameter(valid_594536, JString, required = false,
                                 default = nil)
  if valid_594536 != nil:
    section.add "X-Amz-Content-Sha256", valid_594536
  var valid_594537 = header.getOrDefault("X-Amz-Algorithm")
  valid_594537 = validateParameter(valid_594537, JString, required = false,
                                 default = nil)
  if valid_594537 != nil:
    section.add "X-Amz-Algorithm", valid_594537
  var valid_594538 = header.getOrDefault("X-Amz-Signature")
  valid_594538 = validateParameter(valid_594538, JString, required = false,
                                 default = nil)
  if valid_594538 != nil:
    section.add "X-Amz-Signature", valid_594538
  var valid_594539 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594539 = validateParameter(valid_594539, JString, required = false,
                                 default = nil)
  if valid_594539 != nil:
    section.add "X-Amz-SignedHeaders", valid_594539
  var valid_594540 = header.getOrDefault("X-Amz-Credential")
  valid_594540 = validateParameter(valid_594540, JString, required = false,
                                 default = nil)
  if valid_594540 != nil:
    section.add "X-Amz-Credential", valid_594540
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594542: Call_PutDedicatedIpWarmupAttributes_594530; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p/>
  ## 
  let valid = call_594542.validator(path, query, header, formData, body)
  let scheme = call_594542.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594542.url(scheme.get, call_594542.host, call_594542.base,
                         call_594542.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594542, url, valid)

proc call*(call_594543: Call_PutDedicatedIpWarmupAttributes_594530; IP: string;
          body: JsonNode): Recallable =
  ## putDedicatedIpWarmupAttributes
  ## <p/>
  ##   IP: string (required)
  ##     : A dedicated IP address that is associated with your Amazon Pinpoint account.
  ##   body: JObject (required)
  var path_594544 = newJObject()
  var body_594545 = newJObject()
  add(path_594544, "IP", newJString(IP))
  if body != nil:
    body_594545 = body
  result = call_594543.call(path_594544, nil, nil, nil, body_594545)

var putDedicatedIpWarmupAttributes* = Call_PutDedicatedIpWarmupAttributes_594530(
    name: "putDedicatedIpWarmupAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com", route: "/v1/email/dedicated-ips/{IP}/warmup",
    validator: validate_PutDedicatedIpWarmupAttributes_594531, base: "/",
    url: url_PutDedicatedIpWarmupAttributes_594532,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEmailIdentityDkimAttributes_594546 = ref object of OpenApiRestCall_593421
proc url_PutEmailIdentityDkimAttributes_594548(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "EmailIdentity" in path, "`EmailIdentity` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/identities/"),
               (kind: VariableSegment, value: "EmailIdentity"),
               (kind: ConstantSegment, value: "/dkim")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PutEmailIdentityDkimAttributes_594547(path: JsonNode;
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
  var valid_594549 = path.getOrDefault("EmailIdentity")
  valid_594549 = validateParameter(valid_594549, JString, required = true,
                                 default = nil)
  if valid_594549 != nil:
    section.add "EmailIdentity", valid_594549
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594550 = header.getOrDefault("X-Amz-Date")
  valid_594550 = validateParameter(valid_594550, JString, required = false,
                                 default = nil)
  if valid_594550 != nil:
    section.add "X-Amz-Date", valid_594550
  var valid_594551 = header.getOrDefault("X-Amz-Security-Token")
  valid_594551 = validateParameter(valid_594551, JString, required = false,
                                 default = nil)
  if valid_594551 != nil:
    section.add "X-Amz-Security-Token", valid_594551
  var valid_594552 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594552 = validateParameter(valid_594552, JString, required = false,
                                 default = nil)
  if valid_594552 != nil:
    section.add "X-Amz-Content-Sha256", valid_594552
  var valid_594553 = header.getOrDefault("X-Amz-Algorithm")
  valid_594553 = validateParameter(valid_594553, JString, required = false,
                                 default = nil)
  if valid_594553 != nil:
    section.add "X-Amz-Algorithm", valid_594553
  var valid_594554 = header.getOrDefault("X-Amz-Signature")
  valid_594554 = validateParameter(valid_594554, JString, required = false,
                                 default = nil)
  if valid_594554 != nil:
    section.add "X-Amz-Signature", valid_594554
  var valid_594555 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594555 = validateParameter(valid_594555, JString, required = false,
                                 default = nil)
  if valid_594555 != nil:
    section.add "X-Amz-SignedHeaders", valid_594555
  var valid_594556 = header.getOrDefault("X-Amz-Credential")
  valid_594556 = validateParameter(valid_594556, JString, required = false,
                                 default = nil)
  if valid_594556 != nil:
    section.add "X-Amz-Credential", valid_594556
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594558: Call_PutEmailIdentityDkimAttributes_594546; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Used to enable or disable DKIM authentication for an email identity.
  ## 
  let valid = call_594558.validator(path, query, header, formData, body)
  let scheme = call_594558.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594558.url(scheme.get, call_594558.host, call_594558.base,
                         call_594558.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594558, url, valid)

proc call*(call_594559: Call_PutEmailIdentityDkimAttributes_594546;
          EmailIdentity: string; body: JsonNode): Recallable =
  ## putEmailIdentityDkimAttributes
  ## Used to enable or disable DKIM authentication for an email identity.
  ##   EmailIdentity: string (required)
  ##                : The email identity that you want to change the DKIM settings for.
  ##   body: JObject (required)
  var path_594560 = newJObject()
  var body_594561 = newJObject()
  add(path_594560, "EmailIdentity", newJString(EmailIdentity))
  if body != nil:
    body_594561 = body
  result = call_594559.call(path_594560, nil, nil, nil, body_594561)

var putEmailIdentityDkimAttributes* = Call_PutEmailIdentityDkimAttributes_594546(
    name: "putEmailIdentityDkimAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com",
    route: "/v1/email/identities/{EmailIdentity}/dkim",
    validator: validate_PutEmailIdentityDkimAttributes_594547, base: "/",
    url: url_PutEmailIdentityDkimAttributes_594548,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEmailIdentityFeedbackAttributes_594562 = ref object of OpenApiRestCall_593421
proc url_PutEmailIdentityFeedbackAttributes_594564(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "EmailIdentity" in path, "`EmailIdentity` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/identities/"),
               (kind: VariableSegment, value: "EmailIdentity"),
               (kind: ConstantSegment, value: "/feedback")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PutEmailIdentityFeedbackAttributes_594563(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Used to enable or disable feedback forwarding for an identity. This setting determines what happens when an identity is used to send an email that results in a bounce or complaint event.</p> <p>When you enable feedback forwarding, Amazon Pinpoint sends you email notifications when bounce or complaint events occur. Amazon Pinpoint sends this notification to the address that you specified in the Return-Path header of the original email.</p> <p>When you disable feedback forwarding, Amazon Pinpoint sends notifications through other mechanisms, such as by notifying an Amazon SNS topic. You're required to have a method of tracking bounces and complaints. If you haven't set up another mechanism for receiving bounce or complaint notifications, Amazon Pinpoint sends an email notification when these events occur (even if this setting is disabled).</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   EmailIdentity: JString (required)
  ##                : The email identity that you want to configure bounce and complaint feedback forwarding for.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `EmailIdentity` field"
  var valid_594565 = path.getOrDefault("EmailIdentity")
  valid_594565 = validateParameter(valid_594565, JString, required = true,
                                 default = nil)
  if valid_594565 != nil:
    section.add "EmailIdentity", valid_594565
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594566 = header.getOrDefault("X-Amz-Date")
  valid_594566 = validateParameter(valid_594566, JString, required = false,
                                 default = nil)
  if valid_594566 != nil:
    section.add "X-Amz-Date", valid_594566
  var valid_594567 = header.getOrDefault("X-Amz-Security-Token")
  valid_594567 = validateParameter(valid_594567, JString, required = false,
                                 default = nil)
  if valid_594567 != nil:
    section.add "X-Amz-Security-Token", valid_594567
  var valid_594568 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594568 = validateParameter(valid_594568, JString, required = false,
                                 default = nil)
  if valid_594568 != nil:
    section.add "X-Amz-Content-Sha256", valid_594568
  var valid_594569 = header.getOrDefault("X-Amz-Algorithm")
  valid_594569 = validateParameter(valid_594569, JString, required = false,
                                 default = nil)
  if valid_594569 != nil:
    section.add "X-Amz-Algorithm", valid_594569
  var valid_594570 = header.getOrDefault("X-Amz-Signature")
  valid_594570 = validateParameter(valid_594570, JString, required = false,
                                 default = nil)
  if valid_594570 != nil:
    section.add "X-Amz-Signature", valid_594570
  var valid_594571 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594571 = validateParameter(valid_594571, JString, required = false,
                                 default = nil)
  if valid_594571 != nil:
    section.add "X-Amz-SignedHeaders", valid_594571
  var valid_594572 = header.getOrDefault("X-Amz-Credential")
  valid_594572 = validateParameter(valid_594572, JString, required = false,
                                 default = nil)
  if valid_594572 != nil:
    section.add "X-Amz-Credential", valid_594572
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594574: Call_PutEmailIdentityFeedbackAttributes_594562;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Used to enable or disable feedback forwarding for an identity. This setting determines what happens when an identity is used to send an email that results in a bounce or complaint event.</p> <p>When you enable feedback forwarding, Amazon Pinpoint sends you email notifications when bounce or complaint events occur. Amazon Pinpoint sends this notification to the address that you specified in the Return-Path header of the original email.</p> <p>When you disable feedback forwarding, Amazon Pinpoint sends notifications through other mechanisms, such as by notifying an Amazon SNS topic. You're required to have a method of tracking bounces and complaints. If you haven't set up another mechanism for receiving bounce or complaint notifications, Amazon Pinpoint sends an email notification when these events occur (even if this setting is disabled).</p>
  ## 
  let valid = call_594574.validator(path, query, header, formData, body)
  let scheme = call_594574.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594574.url(scheme.get, call_594574.host, call_594574.base,
                         call_594574.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594574, url, valid)

proc call*(call_594575: Call_PutEmailIdentityFeedbackAttributes_594562;
          EmailIdentity: string; body: JsonNode): Recallable =
  ## putEmailIdentityFeedbackAttributes
  ## <p>Used to enable or disable feedback forwarding for an identity. This setting determines what happens when an identity is used to send an email that results in a bounce or complaint event.</p> <p>When you enable feedback forwarding, Amazon Pinpoint sends you email notifications when bounce or complaint events occur. Amazon Pinpoint sends this notification to the address that you specified in the Return-Path header of the original email.</p> <p>When you disable feedback forwarding, Amazon Pinpoint sends notifications through other mechanisms, such as by notifying an Amazon SNS topic. You're required to have a method of tracking bounces and complaints. If you haven't set up another mechanism for receiving bounce or complaint notifications, Amazon Pinpoint sends an email notification when these events occur (even if this setting is disabled).</p>
  ##   EmailIdentity: string (required)
  ##                : The email identity that you want to configure bounce and complaint feedback forwarding for.
  ##   body: JObject (required)
  var path_594576 = newJObject()
  var body_594577 = newJObject()
  add(path_594576, "EmailIdentity", newJString(EmailIdentity))
  if body != nil:
    body_594577 = body
  result = call_594575.call(path_594576, nil, nil, nil, body_594577)

var putEmailIdentityFeedbackAttributes* = Call_PutEmailIdentityFeedbackAttributes_594562(
    name: "putEmailIdentityFeedbackAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com",
    route: "/v1/email/identities/{EmailIdentity}/feedback",
    validator: validate_PutEmailIdentityFeedbackAttributes_594563, base: "/",
    url: url_PutEmailIdentityFeedbackAttributes_594564,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEmailIdentityMailFromAttributes_594578 = ref object of OpenApiRestCall_593421
proc url_PutEmailIdentityMailFromAttributes_594580(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "EmailIdentity" in path, "`EmailIdentity` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/email/identities/"),
               (kind: VariableSegment, value: "EmailIdentity"),
               (kind: ConstantSegment, value: "/mail-from")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PutEmailIdentityMailFromAttributes_594579(path: JsonNode;
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
  var valid_594581 = path.getOrDefault("EmailIdentity")
  valid_594581 = validateParameter(valid_594581, JString, required = true,
                                 default = nil)
  if valid_594581 != nil:
    section.add "EmailIdentity", valid_594581
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594582 = header.getOrDefault("X-Amz-Date")
  valid_594582 = validateParameter(valid_594582, JString, required = false,
                                 default = nil)
  if valid_594582 != nil:
    section.add "X-Amz-Date", valid_594582
  var valid_594583 = header.getOrDefault("X-Amz-Security-Token")
  valid_594583 = validateParameter(valid_594583, JString, required = false,
                                 default = nil)
  if valid_594583 != nil:
    section.add "X-Amz-Security-Token", valid_594583
  var valid_594584 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594584 = validateParameter(valid_594584, JString, required = false,
                                 default = nil)
  if valid_594584 != nil:
    section.add "X-Amz-Content-Sha256", valid_594584
  var valid_594585 = header.getOrDefault("X-Amz-Algorithm")
  valid_594585 = validateParameter(valid_594585, JString, required = false,
                                 default = nil)
  if valid_594585 != nil:
    section.add "X-Amz-Algorithm", valid_594585
  var valid_594586 = header.getOrDefault("X-Amz-Signature")
  valid_594586 = validateParameter(valid_594586, JString, required = false,
                                 default = nil)
  if valid_594586 != nil:
    section.add "X-Amz-Signature", valid_594586
  var valid_594587 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594587 = validateParameter(valid_594587, JString, required = false,
                                 default = nil)
  if valid_594587 != nil:
    section.add "X-Amz-SignedHeaders", valid_594587
  var valid_594588 = header.getOrDefault("X-Amz-Credential")
  valid_594588 = validateParameter(valid_594588, JString, required = false,
                                 default = nil)
  if valid_594588 != nil:
    section.add "X-Amz-Credential", valid_594588
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594590: Call_PutEmailIdentityMailFromAttributes_594578;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Used to enable or disable the custom Mail-From domain configuration for an email identity.
  ## 
  let valid = call_594590.validator(path, query, header, formData, body)
  let scheme = call_594590.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594590.url(scheme.get, call_594590.host, call_594590.base,
                         call_594590.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594590, url, valid)

proc call*(call_594591: Call_PutEmailIdentityMailFromAttributes_594578;
          EmailIdentity: string; body: JsonNode): Recallable =
  ## putEmailIdentityMailFromAttributes
  ## Used to enable or disable the custom Mail-From domain configuration for an email identity.
  ##   EmailIdentity: string (required)
  ##                : The verified email identity that you want to set up the custom MAIL FROM domain for.
  ##   body: JObject (required)
  var path_594592 = newJObject()
  var body_594593 = newJObject()
  add(path_594592, "EmailIdentity", newJString(EmailIdentity))
  if body != nil:
    body_594593 = body
  result = call_594591.call(path_594592, nil, nil, nil, body_594593)

var putEmailIdentityMailFromAttributes* = Call_PutEmailIdentityMailFromAttributes_594578(
    name: "putEmailIdentityMailFromAttributes", meth: HttpMethod.HttpPut,
    host: "email.amazonaws.com",
    route: "/v1/email/identities/{EmailIdentity}/mail-from",
    validator: validate_PutEmailIdentityMailFromAttributes_594579, base: "/",
    url: url_PutEmailIdentityMailFromAttributes_594580,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendEmail_594594 = ref object of OpenApiRestCall_593421
proc url_SendEmail_594596(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SendEmail_594595(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Sends an email message. You can use the Amazon Pinpoint Email API to send two types of messages:</p> <ul> <li> <p> <b>Simple</b> – A standard email message. When you create this type of message, you specify the sender, the recipient, and the message body, and Amazon Pinpoint assembles the message for you.</p> </li> <li> <p> <b>Raw</b> – A raw, MIME-formatted email message. When you send this type of email, you have to specify all of the message headers, as well as the message body. You can use this message type to send messages that contain attachments. The message that you specify has to be a valid MIME message.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594597 = header.getOrDefault("X-Amz-Date")
  valid_594597 = validateParameter(valid_594597, JString, required = false,
                                 default = nil)
  if valid_594597 != nil:
    section.add "X-Amz-Date", valid_594597
  var valid_594598 = header.getOrDefault("X-Amz-Security-Token")
  valid_594598 = validateParameter(valid_594598, JString, required = false,
                                 default = nil)
  if valid_594598 != nil:
    section.add "X-Amz-Security-Token", valid_594598
  var valid_594599 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594599 = validateParameter(valid_594599, JString, required = false,
                                 default = nil)
  if valid_594599 != nil:
    section.add "X-Amz-Content-Sha256", valid_594599
  var valid_594600 = header.getOrDefault("X-Amz-Algorithm")
  valid_594600 = validateParameter(valid_594600, JString, required = false,
                                 default = nil)
  if valid_594600 != nil:
    section.add "X-Amz-Algorithm", valid_594600
  var valid_594601 = header.getOrDefault("X-Amz-Signature")
  valid_594601 = validateParameter(valid_594601, JString, required = false,
                                 default = nil)
  if valid_594601 != nil:
    section.add "X-Amz-Signature", valid_594601
  var valid_594602 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594602 = validateParameter(valid_594602, JString, required = false,
                                 default = nil)
  if valid_594602 != nil:
    section.add "X-Amz-SignedHeaders", valid_594602
  var valid_594603 = header.getOrDefault("X-Amz-Credential")
  valid_594603 = validateParameter(valid_594603, JString, required = false,
                                 default = nil)
  if valid_594603 != nil:
    section.add "X-Amz-Credential", valid_594603
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594605: Call_SendEmail_594594; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sends an email message. You can use the Amazon Pinpoint Email API to send two types of messages:</p> <ul> <li> <p> <b>Simple</b> – A standard email message. When you create this type of message, you specify the sender, the recipient, and the message body, and Amazon Pinpoint assembles the message for you.</p> </li> <li> <p> <b>Raw</b> – A raw, MIME-formatted email message. When you send this type of email, you have to specify all of the message headers, as well as the message body. You can use this message type to send messages that contain attachments. The message that you specify has to be a valid MIME message.</p> </li> </ul>
  ## 
  let valid = call_594605.validator(path, query, header, formData, body)
  let scheme = call_594605.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594605.url(scheme.get, call_594605.host, call_594605.base,
                         call_594605.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594605, url, valid)

proc call*(call_594606: Call_SendEmail_594594; body: JsonNode): Recallable =
  ## sendEmail
  ## <p>Sends an email message. You can use the Amazon Pinpoint Email API to send two types of messages:</p> <ul> <li> <p> <b>Simple</b> – A standard email message. When you create this type of message, you specify the sender, the recipient, and the message body, and Amazon Pinpoint assembles the message for you.</p> </li> <li> <p> <b>Raw</b> – A raw, MIME-formatted email message. When you send this type of email, you have to specify all of the message headers, as well as the message body. You can use this message type to send messages that contain attachments. The message that you specify has to be a valid MIME message.</p> </li> </ul>
  ##   body: JObject (required)
  var body_594607 = newJObject()
  if body != nil:
    body_594607 = body
  result = call_594606.call(nil, nil, nil, nil, body_594607)

var sendEmail* = Call_SendEmail_594594(name: "sendEmail", meth: HttpMethod.HttpPost,
                                    host: "email.amazonaws.com",
                                    route: "/v1/email/outbound-emails",
                                    validator: validate_SendEmail_594595,
                                    base: "/", url: url_SendEmail_594596,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_594608 = ref object of OpenApiRestCall_593421
proc url_TagResource_594610(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_594609(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Add one or more tags (keys and values) to a specified resource. A <i>tag</i> is a label that you optionally define and associate with a resource in Amazon Pinpoint. Tags can help you categorize and manage resources in different ways, such as by purpose, owner, environment, or other criteria. A resource can have as many as 50 tags.</p> <p>Each tag consists of a required <i>tag key</i> and an associated <i>tag value</i>, both of which you define. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594619: Call_TagResource_594608; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Add one or more tags (keys and values) to a specified resource. A <i>tag</i> is a label that you optionally define and associate with a resource in Amazon Pinpoint. Tags can help you categorize and manage resources in different ways, such as by purpose, owner, environment, or other criteria. A resource can have as many as 50 tags.</p> <p>Each tag consists of a required <i>tag key</i> and an associated <i>tag value</i>, both of which you define. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.</p>
  ## 
  let valid = call_594619.validator(path, query, header, formData, body)
  let scheme = call_594619.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594619.url(scheme.get, call_594619.host, call_594619.base,
                         call_594619.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594619, url, valid)

proc call*(call_594620: Call_TagResource_594608; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Add one or more tags (keys and values) to a specified resource. A <i>tag</i> is a label that you optionally define and associate with a resource in Amazon Pinpoint. Tags can help you categorize and manage resources in different ways, such as by purpose, owner, environment, or other criteria. A resource can have as many as 50 tags.</p> <p>Each tag consists of a required <i>tag key</i> and an associated <i>tag value</i>, both of which you define. A tag key is a general label that acts as a category for more specific tag values. A tag value acts as a descriptor within a tag key.</p>
  ##   body: JObject (required)
  var body_594621 = newJObject()
  if body != nil:
    body_594621 = body
  result = call_594620.call(nil, nil, nil, nil, body_594621)

var tagResource* = Call_TagResource_594608(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "email.amazonaws.com",
                                        route: "/v1/email/tags",
                                        validator: validate_TagResource_594609,
                                        base: "/", url: url_TagResource_594610,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_594622 = ref object of OpenApiRestCall_593421
proc url_UntagResource_594624(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_594623(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Remove one or more tags (keys and values) from a specified resource.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ResourceArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the resource that you want to remove one or more tags from.
  ##   TagKeys: JArray (required)
  ##          : <p>The tags (tag keys) that you want to remove from the resource. When you specify a tag key, the action removes both that key and its associated tag value.</p> <p>To remove more than one tag from the resource, append the <code>TagKeys</code> parameter and argument for each additional tag to remove, separated by an ampersand. For example: 
  ## <code>/v1/email/tags?ResourceArn=ResourceArn&amp;TagKeys=Key1&amp;TagKeys=Key2</code> </p>
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ResourceArn` field"
  var valid_594625 = query.getOrDefault("ResourceArn")
  valid_594625 = validateParameter(valid_594625, JString, required = true,
                                 default = nil)
  if valid_594625 != nil:
    section.add "ResourceArn", valid_594625
  var valid_594626 = query.getOrDefault("TagKeys")
  valid_594626 = validateParameter(valid_594626, JArray, required = true, default = nil)
  if valid_594626 != nil:
    section.add "TagKeys", valid_594626
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_594627 = header.getOrDefault("X-Amz-Date")
  valid_594627 = validateParameter(valid_594627, JString, required = false,
                                 default = nil)
  if valid_594627 != nil:
    section.add "X-Amz-Date", valid_594627
  var valid_594628 = header.getOrDefault("X-Amz-Security-Token")
  valid_594628 = validateParameter(valid_594628, JString, required = false,
                                 default = nil)
  if valid_594628 != nil:
    section.add "X-Amz-Security-Token", valid_594628
  var valid_594629 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594629 = validateParameter(valid_594629, JString, required = false,
                                 default = nil)
  if valid_594629 != nil:
    section.add "X-Amz-Content-Sha256", valid_594629
  var valid_594630 = header.getOrDefault("X-Amz-Algorithm")
  valid_594630 = validateParameter(valid_594630, JString, required = false,
                                 default = nil)
  if valid_594630 != nil:
    section.add "X-Amz-Algorithm", valid_594630
  var valid_594631 = header.getOrDefault("X-Amz-Signature")
  valid_594631 = validateParameter(valid_594631, JString, required = false,
                                 default = nil)
  if valid_594631 != nil:
    section.add "X-Amz-Signature", valid_594631
  var valid_594632 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594632 = validateParameter(valid_594632, JString, required = false,
                                 default = nil)
  if valid_594632 != nil:
    section.add "X-Amz-SignedHeaders", valid_594632
  var valid_594633 = header.getOrDefault("X-Amz-Credential")
  valid_594633 = validateParameter(valid_594633, JString, required = false,
                                 default = nil)
  if valid_594633 != nil:
    section.add "X-Amz-Credential", valid_594633
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594634: Call_UntagResource_594622; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Remove one or more tags (keys and values) from a specified resource.
  ## 
  let valid = call_594634.validator(path, query, header, formData, body)
  let scheme = call_594634.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594634.url(scheme.get, call_594634.host, call_594634.base,
                         call_594634.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594634, url, valid)

proc call*(call_594635: Call_UntagResource_594622; ResourceArn: string;
          TagKeys: JsonNode): Recallable =
  ## untagResource
  ## Remove one or more tags (keys and values) from a specified resource.
  ##   ResourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource that you want to remove one or more tags from.
  ##   TagKeys: JArray (required)
  ##          : <p>The tags (tag keys) that you want to remove from the resource. When you specify a tag key, the action removes both that key and its associated tag value.</p> <p>To remove more than one tag from the resource, append the <code>TagKeys</code> parameter and argument for each additional tag to remove, separated by an ampersand. For example: 
  ## <code>/v1/email/tags?ResourceArn=ResourceArn&amp;TagKeys=Key1&amp;TagKeys=Key2</code> </p>
  var query_594636 = newJObject()
  add(query_594636, "ResourceArn", newJString(ResourceArn))
  if TagKeys != nil:
    query_594636.add "TagKeys", TagKeys
  result = call_594635.call(nil, query_594636, nil, nil, nil)

var untagResource* = Call_UntagResource_594622(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "email.amazonaws.com",
    route: "/v1/email/tags#ResourceArn&TagKeys",
    validator: validate_UntagResource_594623, base: "/", url: url_UntagResource_594624,
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

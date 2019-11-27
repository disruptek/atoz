
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon CloudSearch
## version: 2011-02-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon CloudSearch Configuration Service</fullname> <p>You use the configuration service to create, configure, and manage search domains. Configuration service requests are submitted using the AWS Query protocol. AWS Query requests are HTTP or HTTPS requests submitted via HTTP GET or POST with a query parameter named Action.</p> <p>The endpoint for configuration service requests is region-specific: cloudsearch.<i>region</i>.amazonaws.com. For example, cloudsearch.us-east-1.amazonaws.com. For a current list of supported regions and endpoints, see <a href="http://docs.aws.amazon.com/general/latest/gr/rande.html#cloudsearch_region">Regions and Endpoints</a>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/cloudsearch/
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

  OpenApiRestCall_599368 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599368](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599368): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "cloudsearch.ap-northeast-1.amazonaws.com", "ap-southeast-1": "cloudsearch.ap-southeast-1.amazonaws.com",
                           "us-west-2": "cloudsearch.us-west-2.amazonaws.com",
                           "eu-west-2": "cloudsearch.eu-west-2.amazonaws.com", "ap-northeast-3": "cloudsearch.ap-northeast-3.amazonaws.com", "eu-central-1": "cloudsearch.eu-central-1.amazonaws.com",
                           "us-east-2": "cloudsearch.us-east-2.amazonaws.com",
                           "us-east-1": "cloudsearch.us-east-1.amazonaws.com", "cn-northwest-1": "cloudsearch.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "cloudsearch.ap-south-1.amazonaws.com", "eu-north-1": "cloudsearch.eu-north-1.amazonaws.com", "ap-northeast-2": "cloudsearch.ap-northeast-2.amazonaws.com",
                           "us-west-1": "cloudsearch.us-west-1.amazonaws.com", "us-gov-east-1": "cloudsearch.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "cloudsearch.eu-west-3.amazonaws.com", "cn-north-1": "cloudsearch.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "cloudsearch.sa-east-1.amazonaws.com",
                           "eu-west-1": "cloudsearch.eu-west-1.amazonaws.com", "us-gov-west-1": "cloudsearch.us-gov-west-1.amazonaws.com", "ap-southeast-2": "cloudsearch.ap-southeast-2.amazonaws.com", "ca-central-1": "cloudsearch.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "cloudsearch.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "cloudsearch.ap-southeast-1.amazonaws.com",
      "us-west-2": "cloudsearch.us-west-2.amazonaws.com",
      "eu-west-2": "cloudsearch.eu-west-2.amazonaws.com",
      "ap-northeast-3": "cloudsearch.ap-northeast-3.amazonaws.com",
      "eu-central-1": "cloudsearch.eu-central-1.amazonaws.com",
      "us-east-2": "cloudsearch.us-east-2.amazonaws.com",
      "us-east-1": "cloudsearch.us-east-1.amazonaws.com",
      "cn-northwest-1": "cloudsearch.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "cloudsearch.ap-south-1.amazonaws.com",
      "eu-north-1": "cloudsearch.eu-north-1.amazonaws.com",
      "ap-northeast-2": "cloudsearch.ap-northeast-2.amazonaws.com",
      "us-west-1": "cloudsearch.us-west-1.amazonaws.com",
      "us-gov-east-1": "cloudsearch.us-gov-east-1.amazonaws.com",
      "eu-west-3": "cloudsearch.eu-west-3.amazonaws.com",
      "cn-north-1": "cloudsearch.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "cloudsearch.sa-east-1.amazonaws.com",
      "eu-west-1": "cloudsearch.eu-west-1.amazonaws.com",
      "us-gov-west-1": "cloudsearch.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "cloudsearch.ap-southeast-2.amazonaws.com",
      "ca-central-1": "cloudsearch.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "cloudsearch"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostCreateDomain_599976 = ref object of OpenApiRestCall_599368
proc url_PostCreateDomain_599978(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDomain_599977(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates a new search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_599979 = query.getOrDefault("Action")
  valid_599979 = validateParameter(valid_599979, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_599979 != nil:
    section.add "Action", valid_599979
  var valid_599980 = query.getOrDefault("Version")
  valid_599980 = validateParameter(valid_599980, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_599980 != nil:
    section.add "Version", valid_599980
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599981 = header.getOrDefault("X-Amz-Date")
  valid_599981 = validateParameter(valid_599981, JString, required = false,
                                 default = nil)
  if valid_599981 != nil:
    section.add "X-Amz-Date", valid_599981
  var valid_599982 = header.getOrDefault("X-Amz-Security-Token")
  valid_599982 = validateParameter(valid_599982, JString, required = false,
                                 default = nil)
  if valid_599982 != nil:
    section.add "X-Amz-Security-Token", valid_599982
  var valid_599983 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-Content-Sha256", valid_599983
  var valid_599984 = header.getOrDefault("X-Amz-Algorithm")
  valid_599984 = validateParameter(valid_599984, JString, required = false,
                                 default = nil)
  if valid_599984 != nil:
    section.add "X-Amz-Algorithm", valid_599984
  var valid_599985 = header.getOrDefault("X-Amz-Signature")
  valid_599985 = validateParameter(valid_599985, JString, required = false,
                                 default = nil)
  if valid_599985 != nil:
    section.add "X-Amz-Signature", valid_599985
  var valid_599986 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599986 = validateParameter(valid_599986, JString, required = false,
                                 default = nil)
  if valid_599986 != nil:
    section.add "X-Amz-SignedHeaders", valid_599986
  var valid_599987 = header.getOrDefault("X-Amz-Credential")
  valid_599987 = validateParameter(valid_599987, JString, required = false,
                                 default = nil)
  if valid_599987 != nil:
    section.add "X-Amz-Credential", valid_599987
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_599988 = formData.getOrDefault("DomainName")
  valid_599988 = validateParameter(valid_599988, JString, required = true,
                                 default = nil)
  if valid_599988 != nil:
    section.add "DomainName", valid_599988
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599989: Call_PostCreateDomain_599976; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new search domain.
  ## 
  let valid = call_599989.validator(path, query, header, formData, body)
  let scheme = call_599989.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599989.url(scheme.get, call_599989.host, call_599989.base,
                         call_599989.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599989, url, valid)

proc call*(call_599990: Call_PostCreateDomain_599976; DomainName: string;
          Action: string = "CreateDomain"; Version: string = "2011-02-01"): Recallable =
  ## postCreateDomain
  ## Creates a new search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_599991 = newJObject()
  var formData_599992 = newJObject()
  add(formData_599992, "DomainName", newJString(DomainName))
  add(query_599991, "Action", newJString(Action))
  add(query_599991, "Version", newJString(Version))
  result = call_599990.call(nil, query_599991, nil, formData_599992, nil)

var postCreateDomain* = Call_PostCreateDomain_599976(name: "postCreateDomain",
    meth: HttpMethod.HttpPost, host: "cloudsearch.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_PostCreateDomain_599977,
    base: "/", url: url_PostCreateDomain_599978,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDomain_599705 = ref object of OpenApiRestCall_599368
proc url_GetCreateDomain_599707(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDomain_599706(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Creates a new search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_599832 = query.getOrDefault("Action")
  valid_599832 = validateParameter(valid_599832, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_599832 != nil:
    section.add "Action", valid_599832
  var valid_599833 = query.getOrDefault("DomainName")
  valid_599833 = validateParameter(valid_599833, JString, required = true,
                                 default = nil)
  if valid_599833 != nil:
    section.add "DomainName", valid_599833
  var valid_599834 = query.getOrDefault("Version")
  valid_599834 = validateParameter(valid_599834, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_599834 != nil:
    section.add "Version", valid_599834
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599835 = header.getOrDefault("X-Amz-Date")
  valid_599835 = validateParameter(valid_599835, JString, required = false,
                                 default = nil)
  if valid_599835 != nil:
    section.add "X-Amz-Date", valid_599835
  var valid_599836 = header.getOrDefault("X-Amz-Security-Token")
  valid_599836 = validateParameter(valid_599836, JString, required = false,
                                 default = nil)
  if valid_599836 != nil:
    section.add "X-Amz-Security-Token", valid_599836
  var valid_599837 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599837 = validateParameter(valid_599837, JString, required = false,
                                 default = nil)
  if valid_599837 != nil:
    section.add "X-Amz-Content-Sha256", valid_599837
  var valid_599838 = header.getOrDefault("X-Amz-Algorithm")
  valid_599838 = validateParameter(valid_599838, JString, required = false,
                                 default = nil)
  if valid_599838 != nil:
    section.add "X-Amz-Algorithm", valid_599838
  var valid_599839 = header.getOrDefault("X-Amz-Signature")
  valid_599839 = validateParameter(valid_599839, JString, required = false,
                                 default = nil)
  if valid_599839 != nil:
    section.add "X-Amz-Signature", valid_599839
  var valid_599840 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599840 = validateParameter(valid_599840, JString, required = false,
                                 default = nil)
  if valid_599840 != nil:
    section.add "X-Amz-SignedHeaders", valid_599840
  var valid_599841 = header.getOrDefault("X-Amz-Credential")
  valid_599841 = validateParameter(valid_599841, JString, required = false,
                                 default = nil)
  if valid_599841 != nil:
    section.add "X-Amz-Credential", valid_599841
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599864: Call_GetCreateDomain_599705; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new search domain.
  ## 
  let valid = call_599864.validator(path, query, header, formData, body)
  let scheme = call_599864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599864.url(scheme.get, call_599864.host, call_599864.base,
                         call_599864.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599864, url, valid)

proc call*(call_599935: Call_GetCreateDomain_599705; DomainName: string;
          Action: string = "CreateDomain"; Version: string = "2011-02-01"): Recallable =
  ## getCreateDomain
  ## Creates a new search domain.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_599936 = newJObject()
  add(query_599936, "Action", newJString(Action))
  add(query_599936, "DomainName", newJString(DomainName))
  add(query_599936, "Version", newJString(Version))
  result = call_599935.call(nil, query_599936, nil, nil, nil)

var getCreateDomain* = Call_GetCreateDomain_599705(name: "getCreateDomain",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_GetCreateDomain_599706,
    base: "/", url: url_GetCreateDomain_599707, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineIndexField_600015 = ref object of OpenApiRestCall_599368
proc url_PostDefineIndexField_600017(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDefineIndexField_600016(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600018 = query.getOrDefault("Action")
  valid_600018 = validateParameter(valid_600018, JString, required = true,
                                 default = newJString("DefineIndexField"))
  if valid_600018 != nil:
    section.add "Action", valid_600018
  var valid_600019 = query.getOrDefault("Version")
  valid_600019 = validateParameter(valid_600019, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_600019 != nil:
    section.add "Version", valid_600019
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600020 = header.getOrDefault("X-Amz-Date")
  valid_600020 = validateParameter(valid_600020, JString, required = false,
                                 default = nil)
  if valid_600020 != nil:
    section.add "X-Amz-Date", valid_600020
  var valid_600021 = header.getOrDefault("X-Amz-Security-Token")
  valid_600021 = validateParameter(valid_600021, JString, required = false,
                                 default = nil)
  if valid_600021 != nil:
    section.add "X-Amz-Security-Token", valid_600021
  var valid_600022 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600022 = validateParameter(valid_600022, JString, required = false,
                                 default = nil)
  if valid_600022 != nil:
    section.add "X-Amz-Content-Sha256", valid_600022
  var valid_600023 = header.getOrDefault("X-Amz-Algorithm")
  valid_600023 = validateParameter(valid_600023, JString, required = false,
                                 default = nil)
  if valid_600023 != nil:
    section.add "X-Amz-Algorithm", valid_600023
  var valid_600024 = header.getOrDefault("X-Amz-Signature")
  valid_600024 = validateParameter(valid_600024, JString, required = false,
                                 default = nil)
  if valid_600024 != nil:
    section.add "X-Amz-Signature", valid_600024
  var valid_600025 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600025 = validateParameter(valid_600025, JString, required = false,
                                 default = nil)
  if valid_600025 != nil:
    section.add "X-Amz-SignedHeaders", valid_600025
  var valid_600026 = header.getOrDefault("X-Amz-Credential")
  valid_600026 = validateParameter(valid_600026, JString, required = false,
                                 default = nil)
  if valid_600026 != nil:
    section.add "X-Amz-Credential", valid_600026
  result.add "header", section
  ## parameters in `formData` object:
  ##   IndexField.UIntOptions: JString
  ##                         : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for an unsigned integer field. Present if <code>IndexFieldType</code> specifies the field is of type unsigned integer.
  ##   IndexField.TextOptions: JString
  ##                         : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for text field. Present if <code>IndexFieldType</code> specifies the field is of type text.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   IndexField.LiteralOptions: JString
  ##                            : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for literal field. Present if <code>IndexFieldType</code> specifies the field is of type literal.
  ##   IndexField.IndexFieldType: JString
  ##                            : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The type of field. Based on this type, exactly one of the <a>UIntOptions</a>, <a>LiteralOptions</a> or <a>TextOptions</a> must be present.
  ##   IndexField.IndexFieldName: JString
  ##                            : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The name of a field in the search index. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   IndexField.SourceAttributes: JArray
  ##                              : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## An optional list of source attributes that provide data for this index field. If not specified, the data is pulled from a source attribute with the same name as this <code>IndexField</code>. When one or more source attributes are specified, an optional data transformation can be applied to the source data when populating the index field. You can configure a maximum of 20 sources for an <code>IndexField</code>.
  section = newJObject()
  var valid_600027 = formData.getOrDefault("IndexField.UIntOptions")
  valid_600027 = validateParameter(valid_600027, JString, required = false,
                                 default = nil)
  if valid_600027 != nil:
    section.add "IndexField.UIntOptions", valid_600027
  var valid_600028 = formData.getOrDefault("IndexField.TextOptions")
  valid_600028 = validateParameter(valid_600028, JString, required = false,
                                 default = nil)
  if valid_600028 != nil:
    section.add "IndexField.TextOptions", valid_600028
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_600029 = formData.getOrDefault("DomainName")
  valid_600029 = validateParameter(valid_600029, JString, required = true,
                                 default = nil)
  if valid_600029 != nil:
    section.add "DomainName", valid_600029
  var valid_600030 = formData.getOrDefault("IndexField.LiteralOptions")
  valid_600030 = validateParameter(valid_600030, JString, required = false,
                                 default = nil)
  if valid_600030 != nil:
    section.add "IndexField.LiteralOptions", valid_600030
  var valid_600031 = formData.getOrDefault("IndexField.IndexFieldType")
  valid_600031 = validateParameter(valid_600031, JString, required = false,
                                 default = nil)
  if valid_600031 != nil:
    section.add "IndexField.IndexFieldType", valid_600031
  var valid_600032 = formData.getOrDefault("IndexField.IndexFieldName")
  valid_600032 = validateParameter(valid_600032, JString, required = false,
                                 default = nil)
  if valid_600032 != nil:
    section.add "IndexField.IndexFieldName", valid_600032
  var valid_600033 = formData.getOrDefault("IndexField.SourceAttributes")
  valid_600033 = validateParameter(valid_600033, JArray, required = false,
                                 default = nil)
  if valid_600033 != nil:
    section.add "IndexField.SourceAttributes", valid_600033
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600034: Call_PostDefineIndexField_600015; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ## 
  let valid = call_600034.validator(path, query, header, formData, body)
  let scheme = call_600034.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600034.url(scheme.get, call_600034.host, call_600034.base,
                         call_600034.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600034, url, valid)

proc call*(call_600035: Call_PostDefineIndexField_600015; DomainName: string;
          IndexFieldUIntOptions: string = ""; IndexFieldTextOptions: string = "";
          IndexFieldLiteralOptions: string = "";
          IndexFieldIndexFieldType: string = "";
          Action: string = "DefineIndexField";
          IndexFieldIndexFieldName: string = ""; Version: string = "2011-02-01";
          IndexFieldSourceAttributes: JsonNode = nil): Recallable =
  ## postDefineIndexField
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ##   IndexFieldUIntOptions: string
  ##                        : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for an unsigned integer field. Present if <code>IndexFieldType</code> specifies the field is of type unsigned integer.
  ##   IndexFieldTextOptions: string
  ##                        : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for text field. Present if <code>IndexFieldType</code> specifies the field is of type text.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   IndexFieldLiteralOptions: string
  ##                           : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for literal field. Present if <code>IndexFieldType</code> specifies the field is of type literal.
  ##   IndexFieldIndexFieldType: string
  ##                           : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The type of field. Based on this type, exactly one of the <a>UIntOptions</a>, <a>LiteralOptions</a> or <a>TextOptions</a> must be present.
  ##   Action: string (required)
  ##   IndexFieldIndexFieldName: string
  ##                           : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The name of a field in the search index. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Version: string (required)
  ##   IndexFieldSourceAttributes: JArray
  ##                             : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## An optional list of source attributes that provide data for this index field. If not specified, the data is pulled from a source attribute with the same name as this <code>IndexField</code>. When one or more source attributes are specified, an optional data transformation can be applied to the source data when populating the index field. You can configure a maximum of 20 sources for an <code>IndexField</code>.
  var query_600036 = newJObject()
  var formData_600037 = newJObject()
  add(formData_600037, "IndexField.UIntOptions", newJString(IndexFieldUIntOptions))
  add(formData_600037, "IndexField.TextOptions", newJString(IndexFieldTextOptions))
  add(formData_600037, "DomainName", newJString(DomainName))
  add(formData_600037, "IndexField.LiteralOptions",
      newJString(IndexFieldLiteralOptions))
  add(formData_600037, "IndexField.IndexFieldType",
      newJString(IndexFieldIndexFieldType))
  add(query_600036, "Action", newJString(Action))
  add(formData_600037, "IndexField.IndexFieldName",
      newJString(IndexFieldIndexFieldName))
  add(query_600036, "Version", newJString(Version))
  if IndexFieldSourceAttributes != nil:
    formData_600037.add "IndexField.SourceAttributes", IndexFieldSourceAttributes
  result = call_600035.call(nil, query_600036, nil, formData_600037, nil)

var postDefineIndexField* = Call_PostDefineIndexField_600015(
    name: "postDefineIndexField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineIndexField",
    validator: validate_PostDefineIndexField_600016, base: "/",
    url: url_PostDefineIndexField_600017, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineIndexField_599993 = ref object of OpenApiRestCall_599368
proc url_GetDefineIndexField_599995(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDefineIndexField_599994(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   IndexField.TextOptions: JString
  ##                         : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for text field. Present if <code>IndexFieldType</code> specifies the field is of type text.
  ##   IndexField.LiteralOptions: JString
  ##                            : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for literal field. Present if <code>IndexFieldType</code> specifies the field is of type literal.
  ##   IndexField.UIntOptions: JString
  ##                         : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for an unsigned integer field. Present if <code>IndexFieldType</code> specifies the field is of type unsigned integer.
  ##   IndexField.IndexFieldType: JString
  ##                            : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The type of field. Based on this type, exactly one of the <a>UIntOptions</a>, <a>LiteralOptions</a> or <a>TextOptions</a> must be present.
  ##   IndexField.SourceAttributes: JArray
  ##                              : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## An optional list of source attributes that provide data for this index field. If not specified, the data is pulled from a source attribute with the same name as this <code>IndexField</code>. When one or more source attributes are specified, an optional data transformation can be applied to the source data when populating the index field. You can configure a maximum of 20 sources for an <code>IndexField</code>.
  ##   IndexField.IndexFieldName: JString
  ##                            : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The name of a field in the search index. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  var valid_599996 = query.getOrDefault("IndexField.TextOptions")
  valid_599996 = validateParameter(valid_599996, JString, required = false,
                                 default = nil)
  if valid_599996 != nil:
    section.add "IndexField.TextOptions", valid_599996
  var valid_599997 = query.getOrDefault("IndexField.LiteralOptions")
  valid_599997 = validateParameter(valid_599997, JString, required = false,
                                 default = nil)
  if valid_599997 != nil:
    section.add "IndexField.LiteralOptions", valid_599997
  var valid_599998 = query.getOrDefault("IndexField.UIntOptions")
  valid_599998 = validateParameter(valid_599998, JString, required = false,
                                 default = nil)
  if valid_599998 != nil:
    section.add "IndexField.UIntOptions", valid_599998
  var valid_599999 = query.getOrDefault("IndexField.IndexFieldType")
  valid_599999 = validateParameter(valid_599999, JString, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "IndexField.IndexFieldType", valid_599999
  var valid_600000 = query.getOrDefault("IndexField.SourceAttributes")
  valid_600000 = validateParameter(valid_600000, JArray, required = false,
                                 default = nil)
  if valid_600000 != nil:
    section.add "IndexField.SourceAttributes", valid_600000
  var valid_600001 = query.getOrDefault("IndexField.IndexFieldName")
  valid_600001 = validateParameter(valid_600001, JString, required = false,
                                 default = nil)
  if valid_600001 != nil:
    section.add "IndexField.IndexFieldName", valid_600001
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600002 = query.getOrDefault("Action")
  valid_600002 = validateParameter(valid_600002, JString, required = true,
                                 default = newJString("DefineIndexField"))
  if valid_600002 != nil:
    section.add "Action", valid_600002
  var valid_600003 = query.getOrDefault("DomainName")
  valid_600003 = validateParameter(valid_600003, JString, required = true,
                                 default = nil)
  if valid_600003 != nil:
    section.add "DomainName", valid_600003
  var valid_600004 = query.getOrDefault("Version")
  valid_600004 = validateParameter(valid_600004, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_600004 != nil:
    section.add "Version", valid_600004
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600005 = header.getOrDefault("X-Amz-Date")
  valid_600005 = validateParameter(valid_600005, JString, required = false,
                                 default = nil)
  if valid_600005 != nil:
    section.add "X-Amz-Date", valid_600005
  var valid_600006 = header.getOrDefault("X-Amz-Security-Token")
  valid_600006 = validateParameter(valid_600006, JString, required = false,
                                 default = nil)
  if valid_600006 != nil:
    section.add "X-Amz-Security-Token", valid_600006
  var valid_600007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600007 = validateParameter(valid_600007, JString, required = false,
                                 default = nil)
  if valid_600007 != nil:
    section.add "X-Amz-Content-Sha256", valid_600007
  var valid_600008 = header.getOrDefault("X-Amz-Algorithm")
  valid_600008 = validateParameter(valid_600008, JString, required = false,
                                 default = nil)
  if valid_600008 != nil:
    section.add "X-Amz-Algorithm", valid_600008
  var valid_600009 = header.getOrDefault("X-Amz-Signature")
  valid_600009 = validateParameter(valid_600009, JString, required = false,
                                 default = nil)
  if valid_600009 != nil:
    section.add "X-Amz-Signature", valid_600009
  var valid_600010 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600010 = validateParameter(valid_600010, JString, required = false,
                                 default = nil)
  if valid_600010 != nil:
    section.add "X-Amz-SignedHeaders", valid_600010
  var valid_600011 = header.getOrDefault("X-Amz-Credential")
  valid_600011 = validateParameter(valid_600011, JString, required = false,
                                 default = nil)
  if valid_600011 != nil:
    section.add "X-Amz-Credential", valid_600011
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600012: Call_GetDefineIndexField_599993; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ## 
  let valid = call_600012.validator(path, query, header, formData, body)
  let scheme = call_600012.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600012.url(scheme.get, call_600012.host, call_600012.base,
                         call_600012.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600012, url, valid)

proc call*(call_600013: Call_GetDefineIndexField_599993; DomainName: string;
          IndexFieldTextOptions: string = ""; IndexFieldLiteralOptions: string = "";
          IndexFieldUIntOptions: string = ""; IndexFieldIndexFieldType: string = "";
          IndexFieldSourceAttributes: JsonNode = nil;
          IndexFieldIndexFieldName: string = "";
          Action: string = "DefineIndexField"; Version: string = "2011-02-01"): Recallable =
  ## getDefineIndexField
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ##   IndexFieldTextOptions: string
  ##                        : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for text field. Present if <code>IndexFieldType</code> specifies the field is of type text.
  ##   IndexFieldLiteralOptions: string
  ##                           : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for literal field. Present if <code>IndexFieldType</code> specifies the field is of type literal.
  ##   IndexFieldUIntOptions: string
  ##                        : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for an unsigned integer field. Present if <code>IndexFieldType</code> specifies the field is of type unsigned integer.
  ##   IndexFieldIndexFieldType: string
  ##                           : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The type of field. Based on this type, exactly one of the <a>UIntOptions</a>, <a>LiteralOptions</a> or <a>TextOptions</a> must be present.
  ##   IndexFieldSourceAttributes: JArray
  ##                             : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## An optional list of source attributes that provide data for this index field. If not specified, the data is pulled from a source attribute with the same name as this <code>IndexField</code>. When one or more source attributes are specified, an optional data transformation can be applied to the source data when populating the index field. You can configure a maximum of 20 sources for an <code>IndexField</code>.
  ##   IndexFieldIndexFieldName: string
  ##                           : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The name of a field in the search index. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_600014 = newJObject()
  add(query_600014, "IndexField.TextOptions", newJString(IndexFieldTextOptions))
  add(query_600014, "IndexField.LiteralOptions",
      newJString(IndexFieldLiteralOptions))
  add(query_600014, "IndexField.UIntOptions", newJString(IndexFieldUIntOptions))
  add(query_600014, "IndexField.IndexFieldType",
      newJString(IndexFieldIndexFieldType))
  if IndexFieldSourceAttributes != nil:
    query_600014.add "IndexField.SourceAttributes", IndexFieldSourceAttributes
  add(query_600014, "IndexField.IndexFieldName",
      newJString(IndexFieldIndexFieldName))
  add(query_600014, "Action", newJString(Action))
  add(query_600014, "DomainName", newJString(DomainName))
  add(query_600014, "Version", newJString(Version))
  result = call_600013.call(nil, query_600014, nil, nil, nil)

var getDefineIndexField* = Call_GetDefineIndexField_599993(
    name: "getDefineIndexField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineIndexField",
    validator: validate_GetDefineIndexField_599994, base: "/",
    url: url_GetDefineIndexField_599995, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineRankExpression_600056 = ref object of OpenApiRestCall_599368
proc url_PostDefineRankExpression_600058(protocol: Scheme; host: string;
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

proc validate_PostDefineRankExpression_600057(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600059 = query.getOrDefault("Action")
  valid_600059 = validateParameter(valid_600059, JString, required = true,
                                 default = newJString("DefineRankExpression"))
  if valid_600059 != nil:
    section.add "Action", valid_600059
  var valid_600060 = query.getOrDefault("Version")
  valid_600060 = validateParameter(valid_600060, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_600060 != nil:
    section.add "Version", valid_600060
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600061 = header.getOrDefault("X-Amz-Date")
  valid_600061 = validateParameter(valid_600061, JString, required = false,
                                 default = nil)
  if valid_600061 != nil:
    section.add "X-Amz-Date", valid_600061
  var valid_600062 = header.getOrDefault("X-Amz-Security-Token")
  valid_600062 = validateParameter(valid_600062, JString, required = false,
                                 default = nil)
  if valid_600062 != nil:
    section.add "X-Amz-Security-Token", valid_600062
  var valid_600063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600063 = validateParameter(valid_600063, JString, required = false,
                                 default = nil)
  if valid_600063 != nil:
    section.add "X-Amz-Content-Sha256", valid_600063
  var valid_600064 = header.getOrDefault("X-Amz-Algorithm")
  valid_600064 = validateParameter(valid_600064, JString, required = false,
                                 default = nil)
  if valid_600064 != nil:
    section.add "X-Amz-Algorithm", valid_600064
  var valid_600065 = header.getOrDefault("X-Amz-Signature")
  valid_600065 = validateParameter(valid_600065, JString, required = false,
                                 default = nil)
  if valid_600065 != nil:
    section.add "X-Amz-Signature", valid_600065
  var valid_600066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600066 = validateParameter(valid_600066, JString, required = false,
                                 default = nil)
  if valid_600066 != nil:
    section.add "X-Amz-SignedHeaders", valid_600066
  var valid_600067 = header.getOrDefault("X-Amz-Credential")
  valid_600067 = validateParameter(valid_600067, JString, required = false,
                                 default = nil)
  if valid_600067 != nil:
    section.add "X-Amz-Credential", valid_600067
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   RankExpression.RankName: JString
  ##                          : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## The name of a rank expression. Rank expression names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   RankExpression.RankExpression: JString
  ##                                : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## <p>The expression to evaluate for ranking or thresholding while processing a search request. The <code>RankExpression</code> syntax is based on JavaScript expressions and supports:</p> <ul> <li>Integer, floating point, hex and octal literals</li> <li>Shortcut evaluation of logical operators such that an expression <code>a || b</code> evaluates to the value <code>a</code>, if <code>a</code> is true, without evaluating <code>b</code> at all</li> <li>JavaScript order of precedence for operators</li> <li>Arithmetic operators: <code>+ - * / %</code> </li> <li>Boolean operators (including the ternary operator)</li> <li>Bitwise operators</li> <li>Comparison operators</li> <li>Common mathematic functions: <code>abs ceil erf exp floor lgamma ln log2 log10 max min sqrt pow</code> </li> <li>Trigonometric library functions: <code>acosh acos asinh asin atanh atan cosh cos sinh sin tanh tan</code> </li> <li>Random generation of a number between 0 and 1: <code>rand</code> </li> <li>Current time in epoch: <code>time</code> </li> <li>The <code>min max</code> functions that operate on a variable argument list</li> </ul> <p>Intermediate results are calculated as double precision floating point values. The final return value of a <code>RankExpression</code> is automatically converted from floating point to a 32-bit unsigned integer by rounding to the nearest integer, with a natural floor of 0 and a ceiling of max(uint32_t), 4294967295. Mathematical errors such as dividing by 0 will fail during evaluation and return a value of 0.</p> <p>The source data for a <code>RankExpression</code> can be the name of an <code>IndexField</code> of type uint, another <code>RankExpression</code> or the reserved name <i>text_relevance</i>. The text_relevance source is defined to return an integer from 0 to 1000 (inclusive) to indicate how relevant a document is to the search request, taking into account repetition of search terms in the document and proximity of search terms to each other in each matching <code>IndexField</code> in the document.</p> <p>For more information about using rank expressions to customize ranking, see the Amazon CloudSearch Developer Guide.</p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_600068 = formData.getOrDefault("DomainName")
  valid_600068 = validateParameter(valid_600068, JString, required = true,
                                 default = nil)
  if valid_600068 != nil:
    section.add "DomainName", valid_600068
  var valid_600069 = formData.getOrDefault("RankExpression.RankName")
  valid_600069 = validateParameter(valid_600069, JString, required = false,
                                 default = nil)
  if valid_600069 != nil:
    section.add "RankExpression.RankName", valid_600069
  var valid_600070 = formData.getOrDefault("RankExpression.RankExpression")
  valid_600070 = validateParameter(valid_600070, JString, required = false,
                                 default = nil)
  if valid_600070 != nil:
    section.add "RankExpression.RankExpression", valid_600070
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600071: Call_PostDefineRankExpression_600056; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ## 
  let valid = call_600071.validator(path, query, header, formData, body)
  let scheme = call_600071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600071.url(scheme.get, call_600071.host, call_600071.base,
                         call_600071.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600071, url, valid)

proc call*(call_600072: Call_PostDefineRankExpression_600056; DomainName: string;
          RankExpressionRankName: string = "";
          RankExpressionRankExpression: string = "";
          Action: string = "DefineRankExpression"; Version: string = "2011-02-01"): Recallable =
  ## postDefineRankExpression
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   RankExpressionRankName: string
  ##                         : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## The name of a rank expression. Rank expression names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   RankExpressionRankExpression: string
  ##                               : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## <p>The expression to evaluate for ranking or thresholding while processing a search request. The <code>RankExpression</code> syntax is based on JavaScript expressions and supports:</p> <ul> <li>Integer, floating point, hex and octal literals</li> <li>Shortcut evaluation of logical operators such that an expression <code>a || b</code> evaluates to the value <code>a</code>, if <code>a</code> is true, without evaluating <code>b</code> at all</li> <li>JavaScript order of precedence for operators</li> <li>Arithmetic operators: <code>+ - * / %</code> </li> <li>Boolean operators (including the ternary operator)</li> <li>Bitwise operators</li> <li>Comparison operators</li> <li>Common mathematic functions: <code>abs ceil erf exp floor lgamma ln log2 log10 max min sqrt pow</code> </li> <li>Trigonometric library functions: <code>acosh acos asinh asin atanh atan cosh cos sinh sin tanh tan</code> </li> <li>Random generation of a number between 0 and 1: <code>rand</code> </li> <li>Current time in epoch: <code>time</code> </li> <li>The <code>min max</code> functions that operate on a variable argument list</li> </ul> <p>Intermediate results are calculated as double precision floating point values. The final return value of a <code>RankExpression</code> is automatically converted from floating point to a 32-bit unsigned integer by rounding to the nearest integer, with a natural floor of 0 and a ceiling of max(uint32_t), 4294967295. Mathematical errors such as dividing by 0 will fail during evaluation and return a value of 0.</p> <p>The source data for a <code>RankExpression</code> can be the name of an <code>IndexField</code> of type uint, another <code>RankExpression</code> or the reserved name <i>text_relevance</i>. The text_relevance source is defined to return an integer from 0 to 1000 (inclusive) to indicate how relevant a document is to the search request, taking into account repetition of search terms in the document and proximity of search terms to each other in each matching <code>IndexField</code> in the document.</p> <p>For more information about using rank expressions to customize ranking, see the Amazon CloudSearch Developer Guide.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600073 = newJObject()
  var formData_600074 = newJObject()
  add(formData_600074, "DomainName", newJString(DomainName))
  add(formData_600074, "RankExpression.RankName",
      newJString(RankExpressionRankName))
  add(formData_600074, "RankExpression.RankExpression",
      newJString(RankExpressionRankExpression))
  add(query_600073, "Action", newJString(Action))
  add(query_600073, "Version", newJString(Version))
  result = call_600072.call(nil, query_600073, nil, formData_600074, nil)

var postDefineRankExpression* = Call_PostDefineRankExpression_600056(
    name: "postDefineRankExpression", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineRankExpression",
    validator: validate_PostDefineRankExpression_600057, base: "/",
    url: url_PostDefineRankExpression_600058, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineRankExpression_600038 = ref object of OpenApiRestCall_599368
proc url_GetDefineRankExpression_600040(protocol: Scheme; host: string; base: string;
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

proc validate_GetDefineRankExpression_600039(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   RankExpression.RankExpression: JString
  ##                                : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## <p>The expression to evaluate for ranking or thresholding while processing a search request. The <code>RankExpression</code> syntax is based on JavaScript expressions and supports:</p> <ul> <li>Integer, floating point, hex and octal literals</li> <li>Shortcut evaluation of logical operators such that an expression <code>a || b</code> evaluates to the value <code>a</code>, if <code>a</code> is true, without evaluating <code>b</code> at all</li> <li>JavaScript order of precedence for operators</li> <li>Arithmetic operators: <code>+ - * / %</code> </li> <li>Boolean operators (including the ternary operator)</li> <li>Bitwise operators</li> <li>Comparison operators</li> <li>Common mathematic functions: <code>abs ceil erf exp floor lgamma ln log2 log10 max min sqrt pow</code> </li> <li>Trigonometric library functions: <code>acosh acos asinh asin atanh atan cosh cos sinh sin tanh tan</code> </li> <li>Random generation of a number between 0 and 1: <code>rand</code> </li> <li>Current time in epoch: <code>time</code> </li> <li>The <code>min max</code> functions that operate on a variable argument list</li> </ul> <p>Intermediate results are calculated as double precision floating point values. The final return value of a <code>RankExpression</code> is automatically converted from floating point to a 32-bit unsigned integer by rounding to the nearest integer, with a natural floor of 0 and a ceiling of max(uint32_t), 4294967295. Mathematical errors such as dividing by 0 will fail during evaluation and return a value of 0.</p> <p>The source data for a <code>RankExpression</code> can be the name of an <code>IndexField</code> of type uint, another <code>RankExpression</code> or the reserved name <i>text_relevance</i>. The text_relevance source is defined to return an integer from 0 to 1000 (inclusive) to indicate how relevant a document is to the search request, taking into account repetition of search terms in the document and proximity of search terms to each other in each matching <code>IndexField</code> in the document.</p> <p>For more information about using rank expressions to customize ranking, see the Amazon CloudSearch Developer Guide.</p>
  ##   RankExpression.RankName: JString
  ##                          : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## The name of a rank expression. Rank expression names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600041 = query.getOrDefault("Action")
  valid_600041 = validateParameter(valid_600041, JString, required = true,
                                 default = newJString("DefineRankExpression"))
  if valid_600041 != nil:
    section.add "Action", valid_600041
  var valid_600042 = query.getOrDefault("RankExpression.RankExpression")
  valid_600042 = validateParameter(valid_600042, JString, required = false,
                                 default = nil)
  if valid_600042 != nil:
    section.add "RankExpression.RankExpression", valid_600042
  var valid_600043 = query.getOrDefault("RankExpression.RankName")
  valid_600043 = validateParameter(valid_600043, JString, required = false,
                                 default = nil)
  if valid_600043 != nil:
    section.add "RankExpression.RankName", valid_600043
  var valid_600044 = query.getOrDefault("DomainName")
  valid_600044 = validateParameter(valid_600044, JString, required = true,
                                 default = nil)
  if valid_600044 != nil:
    section.add "DomainName", valid_600044
  var valid_600045 = query.getOrDefault("Version")
  valid_600045 = validateParameter(valid_600045, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_600045 != nil:
    section.add "Version", valid_600045
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600046 = header.getOrDefault("X-Amz-Date")
  valid_600046 = validateParameter(valid_600046, JString, required = false,
                                 default = nil)
  if valid_600046 != nil:
    section.add "X-Amz-Date", valid_600046
  var valid_600047 = header.getOrDefault("X-Amz-Security-Token")
  valid_600047 = validateParameter(valid_600047, JString, required = false,
                                 default = nil)
  if valid_600047 != nil:
    section.add "X-Amz-Security-Token", valid_600047
  var valid_600048 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600048 = validateParameter(valid_600048, JString, required = false,
                                 default = nil)
  if valid_600048 != nil:
    section.add "X-Amz-Content-Sha256", valid_600048
  var valid_600049 = header.getOrDefault("X-Amz-Algorithm")
  valid_600049 = validateParameter(valid_600049, JString, required = false,
                                 default = nil)
  if valid_600049 != nil:
    section.add "X-Amz-Algorithm", valid_600049
  var valid_600050 = header.getOrDefault("X-Amz-Signature")
  valid_600050 = validateParameter(valid_600050, JString, required = false,
                                 default = nil)
  if valid_600050 != nil:
    section.add "X-Amz-Signature", valid_600050
  var valid_600051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600051 = validateParameter(valid_600051, JString, required = false,
                                 default = nil)
  if valid_600051 != nil:
    section.add "X-Amz-SignedHeaders", valid_600051
  var valid_600052 = header.getOrDefault("X-Amz-Credential")
  valid_600052 = validateParameter(valid_600052, JString, required = false,
                                 default = nil)
  if valid_600052 != nil:
    section.add "X-Amz-Credential", valid_600052
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600053: Call_GetDefineRankExpression_600038; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ## 
  let valid = call_600053.validator(path, query, header, formData, body)
  let scheme = call_600053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600053.url(scheme.get, call_600053.host, call_600053.base,
                         call_600053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600053, url, valid)

proc call*(call_600054: Call_GetDefineRankExpression_600038; DomainName: string;
          Action: string = "DefineRankExpression";
          RankExpressionRankExpression: string = "";
          RankExpressionRankName: string = ""; Version: string = "2011-02-01"): Recallable =
  ## getDefineRankExpression
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ##   Action: string (required)
  ##   RankExpressionRankExpression: string
  ##                               : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## <p>The expression to evaluate for ranking or thresholding while processing a search request. The <code>RankExpression</code> syntax is based on JavaScript expressions and supports:</p> <ul> <li>Integer, floating point, hex and octal literals</li> <li>Shortcut evaluation of logical operators such that an expression <code>a || b</code> evaluates to the value <code>a</code>, if <code>a</code> is true, without evaluating <code>b</code> at all</li> <li>JavaScript order of precedence for operators</li> <li>Arithmetic operators: <code>+ - * / %</code> </li> <li>Boolean operators (including the ternary operator)</li> <li>Bitwise operators</li> <li>Comparison operators</li> <li>Common mathematic functions: <code>abs ceil erf exp floor lgamma ln log2 log10 max min sqrt pow</code> </li> <li>Trigonometric library functions: <code>acosh acos asinh asin atanh atan cosh cos sinh sin tanh tan</code> </li> <li>Random generation of a number between 0 and 1: <code>rand</code> </li> <li>Current time in epoch: <code>time</code> </li> <li>The <code>min max</code> functions that operate on a variable argument list</li> </ul> <p>Intermediate results are calculated as double precision floating point values. The final return value of a <code>RankExpression</code> is automatically converted from floating point to a 32-bit unsigned integer by rounding to the nearest integer, with a natural floor of 0 and a ceiling of max(uint32_t), 4294967295. Mathematical errors such as dividing by 0 will fail during evaluation and return a value of 0.</p> <p>The source data for a <code>RankExpression</code> can be the name of an <code>IndexField</code> of type uint, another <code>RankExpression</code> or the reserved name <i>text_relevance</i>. The text_relevance source is defined to return an integer from 0 to 1000 (inclusive) to indicate how relevant a document is to the search request, taking into account repetition of search terms in the document and proximity of search terms to each other in each matching <code>IndexField</code> in the document.</p> <p>For more information about using rank expressions to customize ranking, see the Amazon CloudSearch Developer Guide.</p>
  ##   RankExpressionRankName: string
  ##                         : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## The name of a rank expression. Rank expression names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_600055 = newJObject()
  add(query_600055, "Action", newJString(Action))
  add(query_600055, "RankExpression.RankExpression",
      newJString(RankExpressionRankExpression))
  add(query_600055, "RankExpression.RankName", newJString(RankExpressionRankName))
  add(query_600055, "DomainName", newJString(DomainName))
  add(query_600055, "Version", newJString(Version))
  result = call_600054.call(nil, query_600055, nil, nil, nil)

var getDefineRankExpression* = Call_GetDefineRankExpression_600038(
    name: "getDefineRankExpression", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineRankExpression",
    validator: validate_GetDefineRankExpression_600039, base: "/",
    url: url_GetDefineRankExpression_600040, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDomain_600091 = ref object of OpenApiRestCall_599368
proc url_PostDeleteDomain_600093(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDomain_600092(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Permanently deletes a search domain and all of its data.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600094 = query.getOrDefault("Action")
  valid_600094 = validateParameter(valid_600094, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_600094 != nil:
    section.add "Action", valid_600094
  var valid_600095 = query.getOrDefault("Version")
  valid_600095 = validateParameter(valid_600095, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_600095 != nil:
    section.add "Version", valid_600095
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600096 = header.getOrDefault("X-Amz-Date")
  valid_600096 = validateParameter(valid_600096, JString, required = false,
                                 default = nil)
  if valid_600096 != nil:
    section.add "X-Amz-Date", valid_600096
  var valid_600097 = header.getOrDefault("X-Amz-Security-Token")
  valid_600097 = validateParameter(valid_600097, JString, required = false,
                                 default = nil)
  if valid_600097 != nil:
    section.add "X-Amz-Security-Token", valid_600097
  var valid_600098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600098 = validateParameter(valid_600098, JString, required = false,
                                 default = nil)
  if valid_600098 != nil:
    section.add "X-Amz-Content-Sha256", valid_600098
  var valid_600099 = header.getOrDefault("X-Amz-Algorithm")
  valid_600099 = validateParameter(valid_600099, JString, required = false,
                                 default = nil)
  if valid_600099 != nil:
    section.add "X-Amz-Algorithm", valid_600099
  var valid_600100 = header.getOrDefault("X-Amz-Signature")
  valid_600100 = validateParameter(valid_600100, JString, required = false,
                                 default = nil)
  if valid_600100 != nil:
    section.add "X-Amz-Signature", valid_600100
  var valid_600101 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600101 = validateParameter(valid_600101, JString, required = false,
                                 default = nil)
  if valid_600101 != nil:
    section.add "X-Amz-SignedHeaders", valid_600101
  var valid_600102 = header.getOrDefault("X-Amz-Credential")
  valid_600102 = validateParameter(valid_600102, JString, required = false,
                                 default = nil)
  if valid_600102 != nil:
    section.add "X-Amz-Credential", valid_600102
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_600103 = formData.getOrDefault("DomainName")
  valid_600103 = validateParameter(valid_600103, JString, required = true,
                                 default = nil)
  if valid_600103 != nil:
    section.add "DomainName", valid_600103
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600104: Call_PostDeleteDomain_600091; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes a search domain and all of its data.
  ## 
  let valid = call_600104.validator(path, query, header, formData, body)
  let scheme = call_600104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600104.url(scheme.get, call_600104.host, call_600104.base,
                         call_600104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600104, url, valid)

proc call*(call_600105: Call_PostDeleteDomain_600091; DomainName: string;
          Action: string = "DeleteDomain"; Version: string = "2011-02-01"): Recallable =
  ## postDeleteDomain
  ## Permanently deletes a search domain and all of its data.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600106 = newJObject()
  var formData_600107 = newJObject()
  add(formData_600107, "DomainName", newJString(DomainName))
  add(query_600106, "Action", newJString(Action))
  add(query_600106, "Version", newJString(Version))
  result = call_600105.call(nil, query_600106, nil, formData_600107, nil)

var postDeleteDomain* = Call_PostDeleteDomain_600091(name: "postDeleteDomain",
    meth: HttpMethod.HttpPost, host: "cloudsearch.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_PostDeleteDomain_600092,
    base: "/", url: url_PostDeleteDomain_600093,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDomain_600075 = ref object of OpenApiRestCall_599368
proc url_GetDeleteDomain_600077(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDomain_600076(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Permanently deletes a search domain and all of its data.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600078 = query.getOrDefault("Action")
  valid_600078 = validateParameter(valid_600078, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_600078 != nil:
    section.add "Action", valid_600078
  var valid_600079 = query.getOrDefault("DomainName")
  valid_600079 = validateParameter(valid_600079, JString, required = true,
                                 default = nil)
  if valid_600079 != nil:
    section.add "DomainName", valid_600079
  var valid_600080 = query.getOrDefault("Version")
  valid_600080 = validateParameter(valid_600080, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_600080 != nil:
    section.add "Version", valid_600080
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600081 = header.getOrDefault("X-Amz-Date")
  valid_600081 = validateParameter(valid_600081, JString, required = false,
                                 default = nil)
  if valid_600081 != nil:
    section.add "X-Amz-Date", valid_600081
  var valid_600082 = header.getOrDefault("X-Amz-Security-Token")
  valid_600082 = validateParameter(valid_600082, JString, required = false,
                                 default = nil)
  if valid_600082 != nil:
    section.add "X-Amz-Security-Token", valid_600082
  var valid_600083 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600083 = validateParameter(valid_600083, JString, required = false,
                                 default = nil)
  if valid_600083 != nil:
    section.add "X-Amz-Content-Sha256", valid_600083
  var valid_600084 = header.getOrDefault("X-Amz-Algorithm")
  valid_600084 = validateParameter(valid_600084, JString, required = false,
                                 default = nil)
  if valid_600084 != nil:
    section.add "X-Amz-Algorithm", valid_600084
  var valid_600085 = header.getOrDefault("X-Amz-Signature")
  valid_600085 = validateParameter(valid_600085, JString, required = false,
                                 default = nil)
  if valid_600085 != nil:
    section.add "X-Amz-Signature", valid_600085
  var valid_600086 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600086 = validateParameter(valid_600086, JString, required = false,
                                 default = nil)
  if valid_600086 != nil:
    section.add "X-Amz-SignedHeaders", valid_600086
  var valid_600087 = header.getOrDefault("X-Amz-Credential")
  valid_600087 = validateParameter(valid_600087, JString, required = false,
                                 default = nil)
  if valid_600087 != nil:
    section.add "X-Amz-Credential", valid_600087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600088: Call_GetDeleteDomain_600075; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes a search domain and all of its data.
  ## 
  let valid = call_600088.validator(path, query, header, formData, body)
  let scheme = call_600088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600088.url(scheme.get, call_600088.host, call_600088.base,
                         call_600088.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600088, url, valid)

proc call*(call_600089: Call_GetDeleteDomain_600075; DomainName: string;
          Action: string = "DeleteDomain"; Version: string = "2011-02-01"): Recallable =
  ## getDeleteDomain
  ## Permanently deletes a search domain and all of its data.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_600090 = newJObject()
  add(query_600090, "Action", newJString(Action))
  add(query_600090, "DomainName", newJString(DomainName))
  add(query_600090, "Version", newJString(Version))
  result = call_600089.call(nil, query_600090, nil, nil, nil)

var getDeleteDomain* = Call_GetDeleteDomain_600075(name: "getDeleteDomain",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_GetDeleteDomain_600076,
    base: "/", url: url_GetDeleteDomain_600077, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteIndexField_600125 = ref object of OpenApiRestCall_599368
proc url_PostDeleteIndexField_600127(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteIndexField_600126(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes an <code>IndexField</code> from the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600128 = query.getOrDefault("Action")
  valid_600128 = validateParameter(valid_600128, JString, required = true,
                                 default = newJString("DeleteIndexField"))
  if valid_600128 != nil:
    section.add "Action", valid_600128
  var valid_600129 = query.getOrDefault("Version")
  valid_600129 = validateParameter(valid_600129, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_600129 != nil:
    section.add "Version", valid_600129
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600130 = header.getOrDefault("X-Amz-Date")
  valid_600130 = validateParameter(valid_600130, JString, required = false,
                                 default = nil)
  if valid_600130 != nil:
    section.add "X-Amz-Date", valid_600130
  var valid_600131 = header.getOrDefault("X-Amz-Security-Token")
  valid_600131 = validateParameter(valid_600131, JString, required = false,
                                 default = nil)
  if valid_600131 != nil:
    section.add "X-Amz-Security-Token", valid_600131
  var valid_600132 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600132 = validateParameter(valid_600132, JString, required = false,
                                 default = nil)
  if valid_600132 != nil:
    section.add "X-Amz-Content-Sha256", valid_600132
  var valid_600133 = header.getOrDefault("X-Amz-Algorithm")
  valid_600133 = validateParameter(valid_600133, JString, required = false,
                                 default = nil)
  if valid_600133 != nil:
    section.add "X-Amz-Algorithm", valid_600133
  var valid_600134 = header.getOrDefault("X-Amz-Signature")
  valid_600134 = validateParameter(valid_600134, JString, required = false,
                                 default = nil)
  if valid_600134 != nil:
    section.add "X-Amz-Signature", valid_600134
  var valid_600135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600135 = validateParameter(valid_600135, JString, required = false,
                                 default = nil)
  if valid_600135 != nil:
    section.add "X-Amz-SignedHeaders", valid_600135
  var valid_600136 = header.getOrDefault("X-Amz-Credential")
  valid_600136 = validateParameter(valid_600136, JString, required = false,
                                 default = nil)
  if valid_600136 != nil:
    section.add "X-Amz-Credential", valid_600136
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   IndexFieldName: JString (required)
  ##                 : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_600137 = formData.getOrDefault("DomainName")
  valid_600137 = validateParameter(valid_600137, JString, required = true,
                                 default = nil)
  if valid_600137 != nil:
    section.add "DomainName", valid_600137
  var valid_600138 = formData.getOrDefault("IndexFieldName")
  valid_600138 = validateParameter(valid_600138, JString, required = true,
                                 default = nil)
  if valid_600138 != nil:
    section.add "IndexFieldName", valid_600138
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600139: Call_PostDeleteIndexField_600125; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code>IndexField</code> from the search domain.
  ## 
  let valid = call_600139.validator(path, query, header, formData, body)
  let scheme = call_600139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600139.url(scheme.get, call_600139.host, call_600139.base,
                         call_600139.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600139, url, valid)

proc call*(call_600140: Call_PostDeleteIndexField_600125; DomainName: string;
          IndexFieldName: string; Action: string = "DeleteIndexField";
          Version: string = "2011-02-01"): Recallable =
  ## postDeleteIndexField
  ## Removes an <code>IndexField</code> from the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   IndexFieldName: string (required)
  ##                 : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600141 = newJObject()
  var formData_600142 = newJObject()
  add(formData_600142, "DomainName", newJString(DomainName))
  add(formData_600142, "IndexFieldName", newJString(IndexFieldName))
  add(query_600141, "Action", newJString(Action))
  add(query_600141, "Version", newJString(Version))
  result = call_600140.call(nil, query_600141, nil, formData_600142, nil)

var postDeleteIndexField* = Call_PostDeleteIndexField_600125(
    name: "postDeleteIndexField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteIndexField",
    validator: validate_PostDeleteIndexField_600126, base: "/",
    url: url_PostDeleteIndexField_600127, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteIndexField_600108 = ref object of OpenApiRestCall_599368
proc url_GetDeleteIndexField_600110(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteIndexField_600109(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Removes an <code>IndexField</code> from the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   IndexFieldName: JString (required)
  ##                 : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `IndexFieldName` field"
  var valid_600111 = query.getOrDefault("IndexFieldName")
  valid_600111 = validateParameter(valid_600111, JString, required = true,
                                 default = nil)
  if valid_600111 != nil:
    section.add "IndexFieldName", valid_600111
  var valid_600112 = query.getOrDefault("Action")
  valid_600112 = validateParameter(valid_600112, JString, required = true,
                                 default = newJString("DeleteIndexField"))
  if valid_600112 != nil:
    section.add "Action", valid_600112
  var valid_600113 = query.getOrDefault("DomainName")
  valid_600113 = validateParameter(valid_600113, JString, required = true,
                                 default = nil)
  if valid_600113 != nil:
    section.add "DomainName", valid_600113
  var valid_600114 = query.getOrDefault("Version")
  valid_600114 = validateParameter(valid_600114, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_600114 != nil:
    section.add "Version", valid_600114
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600115 = header.getOrDefault("X-Amz-Date")
  valid_600115 = validateParameter(valid_600115, JString, required = false,
                                 default = nil)
  if valid_600115 != nil:
    section.add "X-Amz-Date", valid_600115
  var valid_600116 = header.getOrDefault("X-Amz-Security-Token")
  valid_600116 = validateParameter(valid_600116, JString, required = false,
                                 default = nil)
  if valid_600116 != nil:
    section.add "X-Amz-Security-Token", valid_600116
  var valid_600117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600117 = validateParameter(valid_600117, JString, required = false,
                                 default = nil)
  if valid_600117 != nil:
    section.add "X-Amz-Content-Sha256", valid_600117
  var valid_600118 = header.getOrDefault("X-Amz-Algorithm")
  valid_600118 = validateParameter(valid_600118, JString, required = false,
                                 default = nil)
  if valid_600118 != nil:
    section.add "X-Amz-Algorithm", valid_600118
  var valid_600119 = header.getOrDefault("X-Amz-Signature")
  valid_600119 = validateParameter(valid_600119, JString, required = false,
                                 default = nil)
  if valid_600119 != nil:
    section.add "X-Amz-Signature", valid_600119
  var valid_600120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600120 = validateParameter(valid_600120, JString, required = false,
                                 default = nil)
  if valid_600120 != nil:
    section.add "X-Amz-SignedHeaders", valid_600120
  var valid_600121 = header.getOrDefault("X-Amz-Credential")
  valid_600121 = validateParameter(valid_600121, JString, required = false,
                                 default = nil)
  if valid_600121 != nil:
    section.add "X-Amz-Credential", valid_600121
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600122: Call_GetDeleteIndexField_600108; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code>IndexField</code> from the search domain.
  ## 
  let valid = call_600122.validator(path, query, header, formData, body)
  let scheme = call_600122.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600122.url(scheme.get, call_600122.host, call_600122.base,
                         call_600122.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600122, url, valid)

proc call*(call_600123: Call_GetDeleteIndexField_600108; IndexFieldName: string;
          DomainName: string; Action: string = "DeleteIndexField";
          Version: string = "2011-02-01"): Recallable =
  ## getDeleteIndexField
  ## Removes an <code>IndexField</code> from the search domain.
  ##   IndexFieldName: string (required)
  ##                 : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_600124 = newJObject()
  add(query_600124, "IndexFieldName", newJString(IndexFieldName))
  add(query_600124, "Action", newJString(Action))
  add(query_600124, "DomainName", newJString(DomainName))
  add(query_600124, "Version", newJString(Version))
  result = call_600123.call(nil, query_600124, nil, nil, nil)

var getDeleteIndexField* = Call_GetDeleteIndexField_600108(
    name: "getDeleteIndexField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteIndexField",
    validator: validate_GetDeleteIndexField_600109, base: "/",
    url: url_GetDeleteIndexField_600110, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteRankExpression_600160 = ref object of OpenApiRestCall_599368
proc url_PostDeleteRankExpression_600162(protocol: Scheme; host: string;
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

proc validate_PostDeleteRankExpression_600161(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a <code>RankExpression</code> from the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600163 = query.getOrDefault("Action")
  valid_600163 = validateParameter(valid_600163, JString, required = true,
                                 default = newJString("DeleteRankExpression"))
  if valid_600163 != nil:
    section.add "Action", valid_600163
  var valid_600164 = query.getOrDefault("Version")
  valid_600164 = validateParameter(valid_600164, JString, required = true,
                                 default = newJString("2011-02-01"))
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
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   RankName: JString (required)
  ##           : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_600172 = formData.getOrDefault("DomainName")
  valid_600172 = validateParameter(valid_600172, JString, required = true,
                                 default = nil)
  if valid_600172 != nil:
    section.add "DomainName", valid_600172
  var valid_600173 = formData.getOrDefault("RankName")
  valid_600173 = validateParameter(valid_600173, JString, required = true,
                                 default = nil)
  if valid_600173 != nil:
    section.add "RankName", valid_600173
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600174: Call_PostDeleteRankExpression_600160; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a <code>RankExpression</code> from the search domain.
  ## 
  let valid = call_600174.validator(path, query, header, formData, body)
  let scheme = call_600174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600174.url(scheme.get, call_600174.host, call_600174.base,
                         call_600174.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600174, url, valid)

proc call*(call_600175: Call_PostDeleteRankExpression_600160; DomainName: string;
          RankName: string; Action: string = "DeleteRankExpression";
          Version: string = "2011-02-01"): Recallable =
  ## postDeleteRankExpression
  ## Removes a <code>RankExpression</code> from the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   RankName: string (required)
  ##           : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Version: string (required)
  var query_600176 = newJObject()
  var formData_600177 = newJObject()
  add(formData_600177, "DomainName", newJString(DomainName))
  add(query_600176, "Action", newJString(Action))
  add(formData_600177, "RankName", newJString(RankName))
  add(query_600176, "Version", newJString(Version))
  result = call_600175.call(nil, query_600176, nil, formData_600177, nil)

var postDeleteRankExpression* = Call_PostDeleteRankExpression_600160(
    name: "postDeleteRankExpression", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteRankExpression",
    validator: validate_PostDeleteRankExpression_600161, base: "/",
    url: url_PostDeleteRankExpression_600162, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteRankExpression_600143 = ref object of OpenApiRestCall_599368
proc url_GetDeleteRankExpression_600145(protocol: Scheme; host: string; base: string;
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

proc validate_GetDeleteRankExpression_600144(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a <code>RankExpression</code> from the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   RankName: JString (required)
  ##           : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `RankName` field"
  var valid_600146 = query.getOrDefault("RankName")
  valid_600146 = validateParameter(valid_600146, JString, required = true,
                                 default = nil)
  if valid_600146 != nil:
    section.add "RankName", valid_600146
  var valid_600147 = query.getOrDefault("Action")
  valid_600147 = validateParameter(valid_600147, JString, required = true,
                                 default = newJString("DeleteRankExpression"))
  if valid_600147 != nil:
    section.add "Action", valid_600147
  var valid_600148 = query.getOrDefault("DomainName")
  valid_600148 = validateParameter(valid_600148, JString, required = true,
                                 default = nil)
  if valid_600148 != nil:
    section.add "DomainName", valid_600148
  var valid_600149 = query.getOrDefault("Version")
  valid_600149 = validateParameter(valid_600149, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_600149 != nil:
    section.add "Version", valid_600149
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600150 = header.getOrDefault("X-Amz-Date")
  valid_600150 = validateParameter(valid_600150, JString, required = false,
                                 default = nil)
  if valid_600150 != nil:
    section.add "X-Amz-Date", valid_600150
  var valid_600151 = header.getOrDefault("X-Amz-Security-Token")
  valid_600151 = validateParameter(valid_600151, JString, required = false,
                                 default = nil)
  if valid_600151 != nil:
    section.add "X-Amz-Security-Token", valid_600151
  var valid_600152 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600152 = validateParameter(valid_600152, JString, required = false,
                                 default = nil)
  if valid_600152 != nil:
    section.add "X-Amz-Content-Sha256", valid_600152
  var valid_600153 = header.getOrDefault("X-Amz-Algorithm")
  valid_600153 = validateParameter(valid_600153, JString, required = false,
                                 default = nil)
  if valid_600153 != nil:
    section.add "X-Amz-Algorithm", valid_600153
  var valid_600154 = header.getOrDefault("X-Amz-Signature")
  valid_600154 = validateParameter(valid_600154, JString, required = false,
                                 default = nil)
  if valid_600154 != nil:
    section.add "X-Amz-Signature", valid_600154
  var valid_600155 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600155 = validateParameter(valid_600155, JString, required = false,
                                 default = nil)
  if valid_600155 != nil:
    section.add "X-Amz-SignedHeaders", valid_600155
  var valid_600156 = header.getOrDefault("X-Amz-Credential")
  valid_600156 = validateParameter(valid_600156, JString, required = false,
                                 default = nil)
  if valid_600156 != nil:
    section.add "X-Amz-Credential", valid_600156
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600157: Call_GetDeleteRankExpression_600143; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a <code>RankExpression</code> from the search domain.
  ## 
  let valid = call_600157.validator(path, query, header, formData, body)
  let scheme = call_600157.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600157.url(scheme.get, call_600157.host, call_600157.base,
                         call_600157.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600157, url, valid)

proc call*(call_600158: Call_GetDeleteRankExpression_600143; RankName: string;
          DomainName: string; Action: string = "DeleteRankExpression";
          Version: string = "2011-02-01"): Recallable =
  ## getDeleteRankExpression
  ## Removes a <code>RankExpression</code> from the search domain.
  ##   RankName: string (required)
  ##           : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_600159 = newJObject()
  add(query_600159, "RankName", newJString(RankName))
  add(query_600159, "Action", newJString(Action))
  add(query_600159, "DomainName", newJString(DomainName))
  add(query_600159, "Version", newJString(Version))
  result = call_600158.call(nil, query_600159, nil, nil, nil)

var getDeleteRankExpression* = Call_GetDeleteRankExpression_600143(
    name: "getDeleteRankExpression", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteRankExpression",
    validator: validate_GetDeleteRankExpression_600144, base: "/",
    url: url_GetDeleteRankExpression_600145, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAvailabilityOptions_600194 = ref object of OpenApiRestCall_599368
proc url_PostDescribeAvailabilityOptions_600196(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeAvailabilityOptions_600195(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600197 = query.getOrDefault("Action")
  valid_600197 = validateParameter(valid_600197, JString, required = true, default = newJString(
      "DescribeAvailabilityOptions"))
  if valid_600197 != nil:
    section.add "Action", valid_600197
  var valid_600198 = query.getOrDefault("Version")
  valid_600198 = validateParameter(valid_600198, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_600198 != nil:
    section.add "Version", valid_600198
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600199 = header.getOrDefault("X-Amz-Date")
  valid_600199 = validateParameter(valid_600199, JString, required = false,
                                 default = nil)
  if valid_600199 != nil:
    section.add "X-Amz-Date", valid_600199
  var valid_600200 = header.getOrDefault("X-Amz-Security-Token")
  valid_600200 = validateParameter(valid_600200, JString, required = false,
                                 default = nil)
  if valid_600200 != nil:
    section.add "X-Amz-Security-Token", valid_600200
  var valid_600201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600201 = validateParameter(valid_600201, JString, required = false,
                                 default = nil)
  if valid_600201 != nil:
    section.add "X-Amz-Content-Sha256", valid_600201
  var valid_600202 = header.getOrDefault("X-Amz-Algorithm")
  valid_600202 = validateParameter(valid_600202, JString, required = false,
                                 default = nil)
  if valid_600202 != nil:
    section.add "X-Amz-Algorithm", valid_600202
  var valid_600203 = header.getOrDefault("X-Amz-Signature")
  valid_600203 = validateParameter(valid_600203, JString, required = false,
                                 default = nil)
  if valid_600203 != nil:
    section.add "X-Amz-Signature", valid_600203
  var valid_600204 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600204 = validateParameter(valid_600204, JString, required = false,
                                 default = nil)
  if valid_600204 != nil:
    section.add "X-Amz-SignedHeaders", valid_600204
  var valid_600205 = header.getOrDefault("X-Amz-Credential")
  valid_600205 = validateParameter(valid_600205, JString, required = false,
                                 default = nil)
  if valid_600205 != nil:
    section.add "X-Amz-Credential", valid_600205
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_600206 = formData.getOrDefault("DomainName")
  valid_600206 = validateParameter(valid_600206, JString, required = true,
                                 default = nil)
  if valid_600206 != nil:
    section.add "DomainName", valid_600206
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600207: Call_PostDescribeAvailabilityOptions_600194;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_600207.validator(path, query, header, formData, body)
  let scheme = call_600207.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600207.url(scheme.get, call_600207.host, call_600207.base,
                         call_600207.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600207, url, valid)

proc call*(call_600208: Call_PostDescribeAvailabilityOptions_600194;
          DomainName: string; Action: string = "DescribeAvailabilityOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeAvailabilityOptions
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600209 = newJObject()
  var formData_600210 = newJObject()
  add(formData_600210, "DomainName", newJString(DomainName))
  add(query_600209, "Action", newJString(Action))
  add(query_600209, "Version", newJString(Version))
  result = call_600208.call(nil, query_600209, nil, formData_600210, nil)

var postDescribeAvailabilityOptions* = Call_PostDescribeAvailabilityOptions_600194(
    name: "postDescribeAvailabilityOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeAvailabilityOptions",
    validator: validate_PostDescribeAvailabilityOptions_600195, base: "/",
    url: url_PostDescribeAvailabilityOptions_600196,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAvailabilityOptions_600178 = ref object of OpenApiRestCall_599368
proc url_GetDescribeAvailabilityOptions_600180(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeAvailabilityOptions_600179(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600181 = query.getOrDefault("Action")
  valid_600181 = validateParameter(valid_600181, JString, required = true, default = newJString(
      "DescribeAvailabilityOptions"))
  if valid_600181 != nil:
    section.add "Action", valid_600181
  var valid_600182 = query.getOrDefault("DomainName")
  valid_600182 = validateParameter(valid_600182, JString, required = true,
                                 default = nil)
  if valid_600182 != nil:
    section.add "DomainName", valid_600182
  var valid_600183 = query.getOrDefault("Version")
  valid_600183 = validateParameter(valid_600183, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_600183 != nil:
    section.add "Version", valid_600183
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600184 = header.getOrDefault("X-Amz-Date")
  valid_600184 = validateParameter(valid_600184, JString, required = false,
                                 default = nil)
  if valid_600184 != nil:
    section.add "X-Amz-Date", valid_600184
  var valid_600185 = header.getOrDefault("X-Amz-Security-Token")
  valid_600185 = validateParameter(valid_600185, JString, required = false,
                                 default = nil)
  if valid_600185 != nil:
    section.add "X-Amz-Security-Token", valid_600185
  var valid_600186 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600186 = validateParameter(valid_600186, JString, required = false,
                                 default = nil)
  if valid_600186 != nil:
    section.add "X-Amz-Content-Sha256", valid_600186
  var valid_600187 = header.getOrDefault("X-Amz-Algorithm")
  valid_600187 = validateParameter(valid_600187, JString, required = false,
                                 default = nil)
  if valid_600187 != nil:
    section.add "X-Amz-Algorithm", valid_600187
  var valid_600188 = header.getOrDefault("X-Amz-Signature")
  valid_600188 = validateParameter(valid_600188, JString, required = false,
                                 default = nil)
  if valid_600188 != nil:
    section.add "X-Amz-Signature", valid_600188
  var valid_600189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600189 = validateParameter(valid_600189, JString, required = false,
                                 default = nil)
  if valid_600189 != nil:
    section.add "X-Amz-SignedHeaders", valid_600189
  var valid_600190 = header.getOrDefault("X-Amz-Credential")
  valid_600190 = validateParameter(valid_600190, JString, required = false,
                                 default = nil)
  if valid_600190 != nil:
    section.add "X-Amz-Credential", valid_600190
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600191: Call_GetDescribeAvailabilityOptions_600178; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_600191.validator(path, query, header, formData, body)
  let scheme = call_600191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600191.url(scheme.get, call_600191.host, call_600191.base,
                         call_600191.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600191, url, valid)

proc call*(call_600192: Call_GetDescribeAvailabilityOptions_600178;
          DomainName: string; Action: string = "DescribeAvailabilityOptions";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeAvailabilityOptions
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_600193 = newJObject()
  add(query_600193, "Action", newJString(Action))
  add(query_600193, "DomainName", newJString(DomainName))
  add(query_600193, "Version", newJString(Version))
  result = call_600192.call(nil, query_600193, nil, nil, nil)

var getDescribeAvailabilityOptions* = Call_GetDescribeAvailabilityOptions_600178(
    name: "getDescribeAvailabilityOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeAvailabilityOptions",
    validator: validate_GetDescribeAvailabilityOptions_600179, base: "/",
    url: url_GetDescribeAvailabilityOptions_600180,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDefaultSearchField_600227 = ref object of OpenApiRestCall_599368
proc url_PostDescribeDefaultSearchField_600229(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDefaultSearchField_600228(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the default search field configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600230 = query.getOrDefault("Action")
  valid_600230 = validateParameter(valid_600230, JString, required = true, default = newJString(
      "DescribeDefaultSearchField"))
  if valid_600230 != nil:
    section.add "Action", valid_600230
  var valid_600231 = query.getOrDefault("Version")
  valid_600231 = validateParameter(valid_600231, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_600231 != nil:
    section.add "Version", valid_600231
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600232 = header.getOrDefault("X-Amz-Date")
  valid_600232 = validateParameter(valid_600232, JString, required = false,
                                 default = nil)
  if valid_600232 != nil:
    section.add "X-Amz-Date", valid_600232
  var valid_600233 = header.getOrDefault("X-Amz-Security-Token")
  valid_600233 = validateParameter(valid_600233, JString, required = false,
                                 default = nil)
  if valid_600233 != nil:
    section.add "X-Amz-Security-Token", valid_600233
  var valid_600234 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600234 = validateParameter(valid_600234, JString, required = false,
                                 default = nil)
  if valid_600234 != nil:
    section.add "X-Amz-Content-Sha256", valid_600234
  var valid_600235 = header.getOrDefault("X-Amz-Algorithm")
  valid_600235 = validateParameter(valid_600235, JString, required = false,
                                 default = nil)
  if valid_600235 != nil:
    section.add "X-Amz-Algorithm", valid_600235
  var valid_600236 = header.getOrDefault("X-Amz-Signature")
  valid_600236 = validateParameter(valid_600236, JString, required = false,
                                 default = nil)
  if valid_600236 != nil:
    section.add "X-Amz-Signature", valid_600236
  var valid_600237 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600237 = validateParameter(valid_600237, JString, required = false,
                                 default = nil)
  if valid_600237 != nil:
    section.add "X-Amz-SignedHeaders", valid_600237
  var valid_600238 = header.getOrDefault("X-Amz-Credential")
  valid_600238 = validateParameter(valid_600238, JString, required = false,
                                 default = nil)
  if valid_600238 != nil:
    section.add "X-Amz-Credential", valid_600238
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_600239 = formData.getOrDefault("DomainName")
  valid_600239 = validateParameter(valid_600239, JString, required = true,
                                 default = nil)
  if valid_600239 != nil:
    section.add "DomainName", valid_600239
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600240: Call_PostDescribeDefaultSearchField_600227; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the default search field configured for the search domain.
  ## 
  let valid = call_600240.validator(path, query, header, formData, body)
  let scheme = call_600240.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600240.url(scheme.get, call_600240.host, call_600240.base,
                         call_600240.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600240, url, valid)

proc call*(call_600241: Call_PostDescribeDefaultSearchField_600227;
          DomainName: string; Action: string = "DescribeDefaultSearchField";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeDefaultSearchField
  ## Gets the default search field configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600242 = newJObject()
  var formData_600243 = newJObject()
  add(formData_600243, "DomainName", newJString(DomainName))
  add(query_600242, "Action", newJString(Action))
  add(query_600242, "Version", newJString(Version))
  result = call_600241.call(nil, query_600242, nil, formData_600243, nil)

var postDescribeDefaultSearchField* = Call_PostDescribeDefaultSearchField_600227(
    name: "postDescribeDefaultSearchField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeDefaultSearchField",
    validator: validate_PostDescribeDefaultSearchField_600228, base: "/",
    url: url_PostDescribeDefaultSearchField_600229,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDefaultSearchField_600211 = ref object of OpenApiRestCall_599368
proc url_GetDescribeDefaultSearchField_600213(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDefaultSearchField_600212(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the default search field configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600214 = query.getOrDefault("Action")
  valid_600214 = validateParameter(valid_600214, JString, required = true, default = newJString(
      "DescribeDefaultSearchField"))
  if valid_600214 != nil:
    section.add "Action", valid_600214
  var valid_600215 = query.getOrDefault("DomainName")
  valid_600215 = validateParameter(valid_600215, JString, required = true,
                                 default = nil)
  if valid_600215 != nil:
    section.add "DomainName", valid_600215
  var valid_600216 = query.getOrDefault("Version")
  valid_600216 = validateParameter(valid_600216, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_600216 != nil:
    section.add "Version", valid_600216
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600217 = header.getOrDefault("X-Amz-Date")
  valid_600217 = validateParameter(valid_600217, JString, required = false,
                                 default = nil)
  if valid_600217 != nil:
    section.add "X-Amz-Date", valid_600217
  var valid_600218 = header.getOrDefault("X-Amz-Security-Token")
  valid_600218 = validateParameter(valid_600218, JString, required = false,
                                 default = nil)
  if valid_600218 != nil:
    section.add "X-Amz-Security-Token", valid_600218
  var valid_600219 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600219 = validateParameter(valid_600219, JString, required = false,
                                 default = nil)
  if valid_600219 != nil:
    section.add "X-Amz-Content-Sha256", valid_600219
  var valid_600220 = header.getOrDefault("X-Amz-Algorithm")
  valid_600220 = validateParameter(valid_600220, JString, required = false,
                                 default = nil)
  if valid_600220 != nil:
    section.add "X-Amz-Algorithm", valid_600220
  var valid_600221 = header.getOrDefault("X-Amz-Signature")
  valid_600221 = validateParameter(valid_600221, JString, required = false,
                                 default = nil)
  if valid_600221 != nil:
    section.add "X-Amz-Signature", valid_600221
  var valid_600222 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600222 = validateParameter(valid_600222, JString, required = false,
                                 default = nil)
  if valid_600222 != nil:
    section.add "X-Amz-SignedHeaders", valid_600222
  var valid_600223 = header.getOrDefault("X-Amz-Credential")
  valid_600223 = validateParameter(valid_600223, JString, required = false,
                                 default = nil)
  if valid_600223 != nil:
    section.add "X-Amz-Credential", valid_600223
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600224: Call_GetDescribeDefaultSearchField_600211; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the default search field configured for the search domain.
  ## 
  let valid = call_600224.validator(path, query, header, formData, body)
  let scheme = call_600224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600224.url(scheme.get, call_600224.host, call_600224.base,
                         call_600224.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600224, url, valid)

proc call*(call_600225: Call_GetDescribeDefaultSearchField_600211;
          DomainName: string; Action: string = "DescribeDefaultSearchField";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeDefaultSearchField
  ## Gets the default search field configured for the search domain.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_600226 = newJObject()
  add(query_600226, "Action", newJString(Action))
  add(query_600226, "DomainName", newJString(DomainName))
  add(query_600226, "Version", newJString(Version))
  result = call_600225.call(nil, query_600226, nil, nil, nil)

var getDescribeDefaultSearchField* = Call_GetDescribeDefaultSearchField_600211(
    name: "getDescribeDefaultSearchField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeDefaultSearchField",
    validator: validate_GetDescribeDefaultSearchField_600212, base: "/",
    url: url_GetDescribeDefaultSearchField_600213,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDomains_600260 = ref object of OpenApiRestCall_599368
proc url_PostDescribeDomains_600262(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDomains_600261(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600263 = query.getOrDefault("Action")
  valid_600263 = validateParameter(valid_600263, JString, required = true,
                                 default = newJString("DescribeDomains"))
  if valid_600263 != nil:
    section.add "Action", valid_600263
  var valid_600264 = query.getOrDefault("Version")
  valid_600264 = validateParameter(valid_600264, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_600264 != nil:
    section.add "Version", valid_600264
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600265 = header.getOrDefault("X-Amz-Date")
  valid_600265 = validateParameter(valid_600265, JString, required = false,
                                 default = nil)
  if valid_600265 != nil:
    section.add "X-Amz-Date", valid_600265
  var valid_600266 = header.getOrDefault("X-Amz-Security-Token")
  valid_600266 = validateParameter(valid_600266, JString, required = false,
                                 default = nil)
  if valid_600266 != nil:
    section.add "X-Amz-Security-Token", valid_600266
  var valid_600267 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600267 = validateParameter(valid_600267, JString, required = false,
                                 default = nil)
  if valid_600267 != nil:
    section.add "X-Amz-Content-Sha256", valid_600267
  var valid_600268 = header.getOrDefault("X-Amz-Algorithm")
  valid_600268 = validateParameter(valid_600268, JString, required = false,
                                 default = nil)
  if valid_600268 != nil:
    section.add "X-Amz-Algorithm", valid_600268
  var valid_600269 = header.getOrDefault("X-Amz-Signature")
  valid_600269 = validateParameter(valid_600269, JString, required = false,
                                 default = nil)
  if valid_600269 != nil:
    section.add "X-Amz-Signature", valid_600269
  var valid_600270 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600270 = validateParameter(valid_600270, JString, required = false,
                                 default = nil)
  if valid_600270 != nil:
    section.add "X-Amz-SignedHeaders", valid_600270
  var valid_600271 = header.getOrDefault("X-Amz-Credential")
  valid_600271 = validateParameter(valid_600271, JString, required = false,
                                 default = nil)
  if valid_600271 != nil:
    section.add "X-Amz-Credential", valid_600271
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainNames: JArray
  ##              : A list of domain names.
  section = newJObject()
  var valid_600272 = formData.getOrDefault("DomainNames")
  valid_600272 = validateParameter(valid_600272, JArray, required = false,
                                 default = nil)
  if valid_600272 != nil:
    section.add "DomainNames", valid_600272
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600273: Call_PostDescribeDomains_600260; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ## 
  let valid = call_600273.validator(path, query, header, formData, body)
  let scheme = call_600273.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600273.url(scheme.get, call_600273.host, call_600273.base,
                         call_600273.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600273, url, valid)

proc call*(call_600274: Call_PostDescribeDomains_600260;
          DomainNames: JsonNode = nil; Action: string = "DescribeDomains";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeDomains
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600275 = newJObject()
  var formData_600276 = newJObject()
  if DomainNames != nil:
    formData_600276.add "DomainNames", DomainNames
  add(query_600275, "Action", newJString(Action))
  add(query_600275, "Version", newJString(Version))
  result = call_600274.call(nil, query_600275, nil, formData_600276, nil)

var postDescribeDomains* = Call_PostDescribeDomains_600260(
    name: "postDescribeDomains", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeDomains",
    validator: validate_PostDescribeDomains_600261, base: "/",
    url: url_PostDescribeDomains_600262, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDomains_600244 = ref object of OpenApiRestCall_599368
proc url_GetDescribeDomains_600246(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDomains_600245(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_600247 = query.getOrDefault("DomainNames")
  valid_600247 = validateParameter(valid_600247, JArray, required = false,
                                 default = nil)
  if valid_600247 != nil:
    section.add "DomainNames", valid_600247
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600248 = query.getOrDefault("Action")
  valid_600248 = validateParameter(valid_600248, JString, required = true,
                                 default = newJString("DescribeDomains"))
  if valid_600248 != nil:
    section.add "Action", valid_600248
  var valid_600249 = query.getOrDefault("Version")
  valid_600249 = validateParameter(valid_600249, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_600249 != nil:
    section.add "Version", valid_600249
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600250 = header.getOrDefault("X-Amz-Date")
  valid_600250 = validateParameter(valid_600250, JString, required = false,
                                 default = nil)
  if valid_600250 != nil:
    section.add "X-Amz-Date", valid_600250
  var valid_600251 = header.getOrDefault("X-Amz-Security-Token")
  valid_600251 = validateParameter(valid_600251, JString, required = false,
                                 default = nil)
  if valid_600251 != nil:
    section.add "X-Amz-Security-Token", valid_600251
  var valid_600252 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600252 = validateParameter(valid_600252, JString, required = false,
                                 default = nil)
  if valid_600252 != nil:
    section.add "X-Amz-Content-Sha256", valid_600252
  var valid_600253 = header.getOrDefault("X-Amz-Algorithm")
  valid_600253 = validateParameter(valid_600253, JString, required = false,
                                 default = nil)
  if valid_600253 != nil:
    section.add "X-Amz-Algorithm", valid_600253
  var valid_600254 = header.getOrDefault("X-Amz-Signature")
  valid_600254 = validateParameter(valid_600254, JString, required = false,
                                 default = nil)
  if valid_600254 != nil:
    section.add "X-Amz-Signature", valid_600254
  var valid_600255 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600255 = validateParameter(valid_600255, JString, required = false,
                                 default = nil)
  if valid_600255 != nil:
    section.add "X-Amz-SignedHeaders", valid_600255
  var valid_600256 = header.getOrDefault("X-Amz-Credential")
  valid_600256 = validateParameter(valid_600256, JString, required = false,
                                 default = nil)
  if valid_600256 != nil:
    section.add "X-Amz-Credential", valid_600256
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600257: Call_GetDescribeDomains_600244; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ## 
  let valid = call_600257.validator(path, query, header, formData, body)
  let scheme = call_600257.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600257.url(scheme.get, call_600257.host, call_600257.base,
                         call_600257.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600257, url, valid)

proc call*(call_600258: Call_GetDescribeDomains_600244;
          DomainNames: JsonNode = nil; Action: string = "DescribeDomains";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeDomains
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600259 = newJObject()
  if DomainNames != nil:
    query_600259.add "DomainNames", DomainNames
  add(query_600259, "Action", newJString(Action))
  add(query_600259, "Version", newJString(Version))
  result = call_600258.call(nil, query_600259, nil, nil, nil)

var getDescribeDomains* = Call_GetDescribeDomains_600244(
    name: "getDescribeDomains", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeDomains",
    validator: validate_GetDescribeDomains_600245, base: "/",
    url: url_GetDescribeDomains_600246, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeIndexFields_600294 = ref object of OpenApiRestCall_599368
proc url_PostDescribeIndexFields_600296(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeIndexFields_600295(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600297 = query.getOrDefault("Action")
  valid_600297 = validateParameter(valid_600297, JString, required = true,
                                 default = newJString("DescribeIndexFields"))
  if valid_600297 != nil:
    section.add "Action", valid_600297
  var valid_600298 = query.getOrDefault("Version")
  valid_600298 = validateParameter(valid_600298, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_600298 != nil:
    section.add "Version", valid_600298
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600299 = header.getOrDefault("X-Amz-Date")
  valid_600299 = validateParameter(valid_600299, JString, required = false,
                                 default = nil)
  if valid_600299 != nil:
    section.add "X-Amz-Date", valid_600299
  var valid_600300 = header.getOrDefault("X-Amz-Security-Token")
  valid_600300 = validateParameter(valid_600300, JString, required = false,
                                 default = nil)
  if valid_600300 != nil:
    section.add "X-Amz-Security-Token", valid_600300
  var valid_600301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600301 = validateParameter(valid_600301, JString, required = false,
                                 default = nil)
  if valid_600301 != nil:
    section.add "X-Amz-Content-Sha256", valid_600301
  var valid_600302 = header.getOrDefault("X-Amz-Algorithm")
  valid_600302 = validateParameter(valid_600302, JString, required = false,
                                 default = nil)
  if valid_600302 != nil:
    section.add "X-Amz-Algorithm", valid_600302
  var valid_600303 = header.getOrDefault("X-Amz-Signature")
  valid_600303 = validateParameter(valid_600303, JString, required = false,
                                 default = nil)
  if valid_600303 != nil:
    section.add "X-Amz-Signature", valid_600303
  var valid_600304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600304 = validateParameter(valid_600304, JString, required = false,
                                 default = nil)
  if valid_600304 != nil:
    section.add "X-Amz-SignedHeaders", valid_600304
  var valid_600305 = header.getOrDefault("X-Amz-Credential")
  valid_600305 = validateParameter(valid_600305, JString, required = false,
                                 default = nil)
  if valid_600305 != nil:
    section.add "X-Amz-Credential", valid_600305
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   FieldNames: JArray
  ##             : Limits the <code>DescribeIndexFields</code> response to the specified fields.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_600306 = formData.getOrDefault("DomainName")
  valid_600306 = validateParameter(valid_600306, JString, required = true,
                                 default = nil)
  if valid_600306 != nil:
    section.add "DomainName", valid_600306
  var valid_600307 = formData.getOrDefault("FieldNames")
  valid_600307 = validateParameter(valid_600307, JArray, required = false,
                                 default = nil)
  if valid_600307 != nil:
    section.add "FieldNames", valid_600307
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600308: Call_PostDescribeIndexFields_600294; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ## 
  let valid = call_600308.validator(path, query, header, formData, body)
  let scheme = call_600308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600308.url(scheme.get, call_600308.host, call_600308.base,
                         call_600308.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600308, url, valid)

proc call*(call_600309: Call_PostDescribeIndexFields_600294; DomainName: string;
          Action: string = "DescribeIndexFields"; FieldNames: JsonNode = nil;
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeIndexFields
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   FieldNames: JArray
  ##             : Limits the <code>DescribeIndexFields</code> response to the specified fields.
  ##   Version: string (required)
  var query_600310 = newJObject()
  var formData_600311 = newJObject()
  add(formData_600311, "DomainName", newJString(DomainName))
  add(query_600310, "Action", newJString(Action))
  if FieldNames != nil:
    formData_600311.add "FieldNames", FieldNames
  add(query_600310, "Version", newJString(Version))
  result = call_600309.call(nil, query_600310, nil, formData_600311, nil)

var postDescribeIndexFields* = Call_PostDescribeIndexFields_600294(
    name: "postDescribeIndexFields", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeIndexFields",
    validator: validate_PostDescribeIndexFields_600295, base: "/",
    url: url_PostDescribeIndexFields_600296, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeIndexFields_600277 = ref object of OpenApiRestCall_599368
proc url_GetDescribeIndexFields_600279(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeIndexFields_600278(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   FieldNames: JArray
  ##             : Limits the <code>DescribeIndexFields</code> response to the specified fields.
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  var valid_600280 = query.getOrDefault("FieldNames")
  valid_600280 = validateParameter(valid_600280, JArray, required = false,
                                 default = nil)
  if valid_600280 != nil:
    section.add "FieldNames", valid_600280
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600281 = query.getOrDefault("Action")
  valid_600281 = validateParameter(valid_600281, JString, required = true,
                                 default = newJString("DescribeIndexFields"))
  if valid_600281 != nil:
    section.add "Action", valid_600281
  var valid_600282 = query.getOrDefault("DomainName")
  valid_600282 = validateParameter(valid_600282, JString, required = true,
                                 default = nil)
  if valid_600282 != nil:
    section.add "DomainName", valid_600282
  var valid_600283 = query.getOrDefault("Version")
  valid_600283 = validateParameter(valid_600283, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_600283 != nil:
    section.add "Version", valid_600283
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600284 = header.getOrDefault("X-Amz-Date")
  valid_600284 = validateParameter(valid_600284, JString, required = false,
                                 default = nil)
  if valid_600284 != nil:
    section.add "X-Amz-Date", valid_600284
  var valid_600285 = header.getOrDefault("X-Amz-Security-Token")
  valid_600285 = validateParameter(valid_600285, JString, required = false,
                                 default = nil)
  if valid_600285 != nil:
    section.add "X-Amz-Security-Token", valid_600285
  var valid_600286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600286 = validateParameter(valid_600286, JString, required = false,
                                 default = nil)
  if valid_600286 != nil:
    section.add "X-Amz-Content-Sha256", valid_600286
  var valid_600287 = header.getOrDefault("X-Amz-Algorithm")
  valid_600287 = validateParameter(valid_600287, JString, required = false,
                                 default = nil)
  if valid_600287 != nil:
    section.add "X-Amz-Algorithm", valid_600287
  var valid_600288 = header.getOrDefault("X-Amz-Signature")
  valid_600288 = validateParameter(valid_600288, JString, required = false,
                                 default = nil)
  if valid_600288 != nil:
    section.add "X-Amz-Signature", valid_600288
  var valid_600289 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600289 = validateParameter(valid_600289, JString, required = false,
                                 default = nil)
  if valid_600289 != nil:
    section.add "X-Amz-SignedHeaders", valid_600289
  var valid_600290 = header.getOrDefault("X-Amz-Credential")
  valid_600290 = validateParameter(valid_600290, JString, required = false,
                                 default = nil)
  if valid_600290 != nil:
    section.add "X-Amz-Credential", valid_600290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600291: Call_GetDescribeIndexFields_600277; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ## 
  let valid = call_600291.validator(path, query, header, formData, body)
  let scheme = call_600291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600291.url(scheme.get, call_600291.host, call_600291.base,
                         call_600291.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600291, url, valid)

proc call*(call_600292: Call_GetDescribeIndexFields_600277; DomainName: string;
          FieldNames: JsonNode = nil; Action: string = "DescribeIndexFields";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeIndexFields
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ##   FieldNames: JArray
  ##             : Limits the <code>DescribeIndexFields</code> response to the specified fields.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_600293 = newJObject()
  if FieldNames != nil:
    query_600293.add "FieldNames", FieldNames
  add(query_600293, "Action", newJString(Action))
  add(query_600293, "DomainName", newJString(DomainName))
  add(query_600293, "Version", newJString(Version))
  result = call_600292.call(nil, query_600293, nil, nil, nil)

var getDescribeIndexFields* = Call_GetDescribeIndexFields_600277(
    name: "getDescribeIndexFields", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeIndexFields",
    validator: validate_GetDescribeIndexFields_600278, base: "/",
    url: url_GetDescribeIndexFields_600279, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeRankExpressions_600329 = ref object of OpenApiRestCall_599368
proc url_PostDescribeRankExpressions_600331(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeRankExpressions_600330(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600332 = query.getOrDefault("Action")
  valid_600332 = validateParameter(valid_600332, JString, required = true, default = newJString(
      "DescribeRankExpressions"))
  if valid_600332 != nil:
    section.add "Action", valid_600332
  var valid_600333 = query.getOrDefault("Version")
  valid_600333 = validateParameter(valid_600333, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_600333 != nil:
    section.add "Version", valid_600333
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600334 = header.getOrDefault("X-Amz-Date")
  valid_600334 = validateParameter(valid_600334, JString, required = false,
                                 default = nil)
  if valid_600334 != nil:
    section.add "X-Amz-Date", valid_600334
  var valid_600335 = header.getOrDefault("X-Amz-Security-Token")
  valid_600335 = validateParameter(valid_600335, JString, required = false,
                                 default = nil)
  if valid_600335 != nil:
    section.add "X-Amz-Security-Token", valid_600335
  var valid_600336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600336 = validateParameter(valid_600336, JString, required = false,
                                 default = nil)
  if valid_600336 != nil:
    section.add "X-Amz-Content-Sha256", valid_600336
  var valid_600337 = header.getOrDefault("X-Amz-Algorithm")
  valid_600337 = validateParameter(valid_600337, JString, required = false,
                                 default = nil)
  if valid_600337 != nil:
    section.add "X-Amz-Algorithm", valid_600337
  var valid_600338 = header.getOrDefault("X-Amz-Signature")
  valid_600338 = validateParameter(valid_600338, JString, required = false,
                                 default = nil)
  if valid_600338 != nil:
    section.add "X-Amz-Signature", valid_600338
  var valid_600339 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600339 = validateParameter(valid_600339, JString, required = false,
                                 default = nil)
  if valid_600339 != nil:
    section.add "X-Amz-SignedHeaders", valid_600339
  var valid_600340 = header.getOrDefault("X-Amz-Credential")
  valid_600340 = validateParameter(valid_600340, JString, required = false,
                                 default = nil)
  if valid_600340 != nil:
    section.add "X-Amz-Credential", valid_600340
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   RankNames: JArray
  ##            : Limits the <code>DescribeRankExpressions</code> response to the specified fields.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_600341 = formData.getOrDefault("DomainName")
  valid_600341 = validateParameter(valid_600341, JString, required = true,
                                 default = nil)
  if valid_600341 != nil:
    section.add "DomainName", valid_600341
  var valid_600342 = formData.getOrDefault("RankNames")
  valid_600342 = validateParameter(valid_600342, JArray, required = false,
                                 default = nil)
  if valid_600342 != nil:
    section.add "RankNames", valid_600342
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600343: Call_PostDescribeRankExpressions_600329; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ## 
  let valid = call_600343.validator(path, query, header, formData, body)
  let scheme = call_600343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600343.url(scheme.get, call_600343.host, call_600343.base,
                         call_600343.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600343, url, valid)

proc call*(call_600344: Call_PostDescribeRankExpressions_600329;
          DomainName: string; Action: string = "DescribeRankExpressions";
          RankNames: JsonNode = nil; Version: string = "2011-02-01"): Recallable =
  ## postDescribeRankExpressions
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   RankNames: JArray
  ##            : Limits the <code>DescribeRankExpressions</code> response to the specified fields.
  ##   Version: string (required)
  var query_600345 = newJObject()
  var formData_600346 = newJObject()
  add(formData_600346, "DomainName", newJString(DomainName))
  add(query_600345, "Action", newJString(Action))
  if RankNames != nil:
    formData_600346.add "RankNames", RankNames
  add(query_600345, "Version", newJString(Version))
  result = call_600344.call(nil, query_600345, nil, formData_600346, nil)

var postDescribeRankExpressions* = Call_PostDescribeRankExpressions_600329(
    name: "postDescribeRankExpressions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeRankExpressions",
    validator: validate_PostDescribeRankExpressions_600330, base: "/",
    url: url_PostDescribeRankExpressions_600331,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeRankExpressions_600312 = ref object of OpenApiRestCall_599368
proc url_GetDescribeRankExpressions_600314(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeRankExpressions_600313(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   RankNames: JArray
  ##            : Limits the <code>DescribeRankExpressions</code> response to the specified fields.
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  var valid_600315 = query.getOrDefault("RankNames")
  valid_600315 = validateParameter(valid_600315, JArray, required = false,
                                 default = nil)
  if valid_600315 != nil:
    section.add "RankNames", valid_600315
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600316 = query.getOrDefault("Action")
  valid_600316 = validateParameter(valid_600316, JString, required = true, default = newJString(
      "DescribeRankExpressions"))
  if valid_600316 != nil:
    section.add "Action", valid_600316
  var valid_600317 = query.getOrDefault("DomainName")
  valid_600317 = validateParameter(valid_600317, JString, required = true,
                                 default = nil)
  if valid_600317 != nil:
    section.add "DomainName", valid_600317
  var valid_600318 = query.getOrDefault("Version")
  valid_600318 = validateParameter(valid_600318, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_600318 != nil:
    section.add "Version", valid_600318
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600319 = header.getOrDefault("X-Amz-Date")
  valid_600319 = validateParameter(valid_600319, JString, required = false,
                                 default = nil)
  if valid_600319 != nil:
    section.add "X-Amz-Date", valid_600319
  var valid_600320 = header.getOrDefault("X-Amz-Security-Token")
  valid_600320 = validateParameter(valid_600320, JString, required = false,
                                 default = nil)
  if valid_600320 != nil:
    section.add "X-Amz-Security-Token", valid_600320
  var valid_600321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600321 = validateParameter(valid_600321, JString, required = false,
                                 default = nil)
  if valid_600321 != nil:
    section.add "X-Amz-Content-Sha256", valid_600321
  var valid_600322 = header.getOrDefault("X-Amz-Algorithm")
  valid_600322 = validateParameter(valid_600322, JString, required = false,
                                 default = nil)
  if valid_600322 != nil:
    section.add "X-Amz-Algorithm", valid_600322
  var valid_600323 = header.getOrDefault("X-Amz-Signature")
  valid_600323 = validateParameter(valid_600323, JString, required = false,
                                 default = nil)
  if valid_600323 != nil:
    section.add "X-Amz-Signature", valid_600323
  var valid_600324 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600324 = validateParameter(valid_600324, JString, required = false,
                                 default = nil)
  if valid_600324 != nil:
    section.add "X-Amz-SignedHeaders", valid_600324
  var valid_600325 = header.getOrDefault("X-Amz-Credential")
  valid_600325 = validateParameter(valid_600325, JString, required = false,
                                 default = nil)
  if valid_600325 != nil:
    section.add "X-Amz-Credential", valid_600325
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600326: Call_GetDescribeRankExpressions_600312; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ## 
  let valid = call_600326.validator(path, query, header, formData, body)
  let scheme = call_600326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600326.url(scheme.get, call_600326.host, call_600326.base,
                         call_600326.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600326, url, valid)

proc call*(call_600327: Call_GetDescribeRankExpressions_600312; DomainName: string;
          RankNames: JsonNode = nil; Action: string = "DescribeRankExpressions";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeRankExpressions
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ##   RankNames: JArray
  ##            : Limits the <code>DescribeRankExpressions</code> response to the specified fields.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_600328 = newJObject()
  if RankNames != nil:
    query_600328.add "RankNames", RankNames
  add(query_600328, "Action", newJString(Action))
  add(query_600328, "DomainName", newJString(DomainName))
  add(query_600328, "Version", newJString(Version))
  result = call_600327.call(nil, query_600328, nil, nil, nil)

var getDescribeRankExpressions* = Call_GetDescribeRankExpressions_600312(
    name: "getDescribeRankExpressions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeRankExpressions",
    validator: validate_GetDescribeRankExpressions_600313, base: "/",
    url: url_GetDescribeRankExpressions_600314,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeServiceAccessPolicies_600363 = ref object of OpenApiRestCall_599368
proc url_PostDescribeServiceAccessPolicies_600365(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeServiceAccessPolicies_600364(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600366 = query.getOrDefault("Action")
  valid_600366 = validateParameter(valid_600366, JString, required = true, default = newJString(
      "DescribeServiceAccessPolicies"))
  if valid_600366 != nil:
    section.add "Action", valid_600366
  var valid_600367 = query.getOrDefault("Version")
  valid_600367 = validateParameter(valid_600367, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_600367 != nil:
    section.add "Version", valid_600367
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600368 = header.getOrDefault("X-Amz-Date")
  valid_600368 = validateParameter(valid_600368, JString, required = false,
                                 default = nil)
  if valid_600368 != nil:
    section.add "X-Amz-Date", valid_600368
  var valid_600369 = header.getOrDefault("X-Amz-Security-Token")
  valid_600369 = validateParameter(valid_600369, JString, required = false,
                                 default = nil)
  if valid_600369 != nil:
    section.add "X-Amz-Security-Token", valid_600369
  var valid_600370 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600370 = validateParameter(valid_600370, JString, required = false,
                                 default = nil)
  if valid_600370 != nil:
    section.add "X-Amz-Content-Sha256", valid_600370
  var valid_600371 = header.getOrDefault("X-Amz-Algorithm")
  valid_600371 = validateParameter(valid_600371, JString, required = false,
                                 default = nil)
  if valid_600371 != nil:
    section.add "X-Amz-Algorithm", valid_600371
  var valid_600372 = header.getOrDefault("X-Amz-Signature")
  valid_600372 = validateParameter(valid_600372, JString, required = false,
                                 default = nil)
  if valid_600372 != nil:
    section.add "X-Amz-Signature", valid_600372
  var valid_600373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600373 = validateParameter(valid_600373, JString, required = false,
                                 default = nil)
  if valid_600373 != nil:
    section.add "X-Amz-SignedHeaders", valid_600373
  var valid_600374 = header.getOrDefault("X-Amz-Credential")
  valid_600374 = validateParameter(valid_600374, JString, required = false,
                                 default = nil)
  if valid_600374 != nil:
    section.add "X-Amz-Credential", valid_600374
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_600375 = formData.getOrDefault("DomainName")
  valid_600375 = validateParameter(valid_600375, JString, required = true,
                                 default = nil)
  if valid_600375 != nil:
    section.add "DomainName", valid_600375
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600376: Call_PostDescribeServiceAccessPolicies_600363;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ## 
  let valid = call_600376.validator(path, query, header, formData, body)
  let scheme = call_600376.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600376.url(scheme.get, call_600376.host, call_600376.base,
                         call_600376.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600376, url, valid)

proc call*(call_600377: Call_PostDescribeServiceAccessPolicies_600363;
          DomainName: string; Action: string = "DescribeServiceAccessPolicies";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeServiceAccessPolicies
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600378 = newJObject()
  var formData_600379 = newJObject()
  add(formData_600379, "DomainName", newJString(DomainName))
  add(query_600378, "Action", newJString(Action))
  add(query_600378, "Version", newJString(Version))
  result = call_600377.call(nil, query_600378, nil, formData_600379, nil)

var postDescribeServiceAccessPolicies* = Call_PostDescribeServiceAccessPolicies_600363(
    name: "postDescribeServiceAccessPolicies", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeServiceAccessPolicies",
    validator: validate_PostDescribeServiceAccessPolicies_600364, base: "/",
    url: url_PostDescribeServiceAccessPolicies_600365,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeServiceAccessPolicies_600347 = ref object of OpenApiRestCall_599368
proc url_GetDescribeServiceAccessPolicies_600349(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeServiceAccessPolicies_600348(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600350 = query.getOrDefault("Action")
  valid_600350 = validateParameter(valid_600350, JString, required = true, default = newJString(
      "DescribeServiceAccessPolicies"))
  if valid_600350 != nil:
    section.add "Action", valid_600350
  var valid_600351 = query.getOrDefault("DomainName")
  valid_600351 = validateParameter(valid_600351, JString, required = true,
                                 default = nil)
  if valid_600351 != nil:
    section.add "DomainName", valid_600351
  var valid_600352 = query.getOrDefault("Version")
  valid_600352 = validateParameter(valid_600352, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_600352 != nil:
    section.add "Version", valid_600352
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600353 = header.getOrDefault("X-Amz-Date")
  valid_600353 = validateParameter(valid_600353, JString, required = false,
                                 default = nil)
  if valid_600353 != nil:
    section.add "X-Amz-Date", valid_600353
  var valid_600354 = header.getOrDefault("X-Amz-Security-Token")
  valid_600354 = validateParameter(valid_600354, JString, required = false,
                                 default = nil)
  if valid_600354 != nil:
    section.add "X-Amz-Security-Token", valid_600354
  var valid_600355 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600355 = validateParameter(valid_600355, JString, required = false,
                                 default = nil)
  if valid_600355 != nil:
    section.add "X-Amz-Content-Sha256", valid_600355
  var valid_600356 = header.getOrDefault("X-Amz-Algorithm")
  valid_600356 = validateParameter(valid_600356, JString, required = false,
                                 default = nil)
  if valid_600356 != nil:
    section.add "X-Amz-Algorithm", valid_600356
  var valid_600357 = header.getOrDefault("X-Amz-Signature")
  valid_600357 = validateParameter(valid_600357, JString, required = false,
                                 default = nil)
  if valid_600357 != nil:
    section.add "X-Amz-Signature", valid_600357
  var valid_600358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600358 = validateParameter(valid_600358, JString, required = false,
                                 default = nil)
  if valid_600358 != nil:
    section.add "X-Amz-SignedHeaders", valid_600358
  var valid_600359 = header.getOrDefault("X-Amz-Credential")
  valid_600359 = validateParameter(valid_600359, JString, required = false,
                                 default = nil)
  if valid_600359 != nil:
    section.add "X-Amz-Credential", valid_600359
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600360: Call_GetDescribeServiceAccessPolicies_600347;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ## 
  let valid = call_600360.validator(path, query, header, formData, body)
  let scheme = call_600360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600360.url(scheme.get, call_600360.host, call_600360.base,
                         call_600360.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600360, url, valid)

proc call*(call_600361: Call_GetDescribeServiceAccessPolicies_600347;
          DomainName: string; Action: string = "DescribeServiceAccessPolicies";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeServiceAccessPolicies
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_600362 = newJObject()
  add(query_600362, "Action", newJString(Action))
  add(query_600362, "DomainName", newJString(DomainName))
  add(query_600362, "Version", newJString(Version))
  result = call_600361.call(nil, query_600362, nil, nil, nil)

var getDescribeServiceAccessPolicies* = Call_GetDescribeServiceAccessPolicies_600347(
    name: "getDescribeServiceAccessPolicies", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeServiceAccessPolicies",
    validator: validate_GetDescribeServiceAccessPolicies_600348, base: "/",
    url: url_GetDescribeServiceAccessPolicies_600349,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeStemmingOptions_600396 = ref object of OpenApiRestCall_599368
proc url_PostDescribeStemmingOptions_600398(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeStemmingOptions_600397(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the stemming dictionary configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600399 = query.getOrDefault("Action")
  valid_600399 = validateParameter(valid_600399, JString, required = true, default = newJString(
      "DescribeStemmingOptions"))
  if valid_600399 != nil:
    section.add "Action", valid_600399
  var valid_600400 = query.getOrDefault("Version")
  valid_600400 = validateParameter(valid_600400, JString, required = true,
                                 default = newJString("2011-02-01"))
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
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_600408 = formData.getOrDefault("DomainName")
  valid_600408 = validateParameter(valid_600408, JString, required = true,
                                 default = nil)
  if valid_600408 != nil:
    section.add "DomainName", valid_600408
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600409: Call_PostDescribeStemmingOptions_600396; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the stemming dictionary configured for the search domain.
  ## 
  let valid = call_600409.validator(path, query, header, formData, body)
  let scheme = call_600409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600409.url(scheme.get, call_600409.host, call_600409.base,
                         call_600409.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600409, url, valid)

proc call*(call_600410: Call_PostDescribeStemmingOptions_600396;
          DomainName: string; Action: string = "DescribeStemmingOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeStemmingOptions
  ## Gets the stemming dictionary configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600411 = newJObject()
  var formData_600412 = newJObject()
  add(formData_600412, "DomainName", newJString(DomainName))
  add(query_600411, "Action", newJString(Action))
  add(query_600411, "Version", newJString(Version))
  result = call_600410.call(nil, query_600411, nil, formData_600412, nil)

var postDescribeStemmingOptions* = Call_PostDescribeStemmingOptions_600396(
    name: "postDescribeStemmingOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeStemmingOptions",
    validator: validate_PostDescribeStemmingOptions_600397, base: "/",
    url: url_PostDescribeStemmingOptions_600398,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeStemmingOptions_600380 = ref object of OpenApiRestCall_599368
proc url_GetDescribeStemmingOptions_600382(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeStemmingOptions_600381(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the stemming dictionary configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600383 = query.getOrDefault("Action")
  valid_600383 = validateParameter(valid_600383, JString, required = true, default = newJString(
      "DescribeStemmingOptions"))
  if valid_600383 != nil:
    section.add "Action", valid_600383
  var valid_600384 = query.getOrDefault("DomainName")
  valid_600384 = validateParameter(valid_600384, JString, required = true,
                                 default = nil)
  if valid_600384 != nil:
    section.add "DomainName", valid_600384
  var valid_600385 = query.getOrDefault("Version")
  valid_600385 = validateParameter(valid_600385, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_600385 != nil:
    section.add "Version", valid_600385
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600386 = header.getOrDefault("X-Amz-Date")
  valid_600386 = validateParameter(valid_600386, JString, required = false,
                                 default = nil)
  if valid_600386 != nil:
    section.add "X-Amz-Date", valid_600386
  var valid_600387 = header.getOrDefault("X-Amz-Security-Token")
  valid_600387 = validateParameter(valid_600387, JString, required = false,
                                 default = nil)
  if valid_600387 != nil:
    section.add "X-Amz-Security-Token", valid_600387
  var valid_600388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600388 = validateParameter(valid_600388, JString, required = false,
                                 default = nil)
  if valid_600388 != nil:
    section.add "X-Amz-Content-Sha256", valid_600388
  var valid_600389 = header.getOrDefault("X-Amz-Algorithm")
  valid_600389 = validateParameter(valid_600389, JString, required = false,
                                 default = nil)
  if valid_600389 != nil:
    section.add "X-Amz-Algorithm", valid_600389
  var valid_600390 = header.getOrDefault("X-Amz-Signature")
  valid_600390 = validateParameter(valid_600390, JString, required = false,
                                 default = nil)
  if valid_600390 != nil:
    section.add "X-Amz-Signature", valid_600390
  var valid_600391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600391 = validateParameter(valid_600391, JString, required = false,
                                 default = nil)
  if valid_600391 != nil:
    section.add "X-Amz-SignedHeaders", valid_600391
  var valid_600392 = header.getOrDefault("X-Amz-Credential")
  valid_600392 = validateParameter(valid_600392, JString, required = false,
                                 default = nil)
  if valid_600392 != nil:
    section.add "X-Amz-Credential", valid_600392
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600393: Call_GetDescribeStemmingOptions_600380; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the stemming dictionary configured for the search domain.
  ## 
  let valid = call_600393.validator(path, query, header, formData, body)
  let scheme = call_600393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600393.url(scheme.get, call_600393.host, call_600393.base,
                         call_600393.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600393, url, valid)

proc call*(call_600394: Call_GetDescribeStemmingOptions_600380; DomainName: string;
          Action: string = "DescribeStemmingOptions"; Version: string = "2011-02-01"): Recallable =
  ## getDescribeStemmingOptions
  ## Gets the stemming dictionary configured for the search domain.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_600395 = newJObject()
  add(query_600395, "Action", newJString(Action))
  add(query_600395, "DomainName", newJString(DomainName))
  add(query_600395, "Version", newJString(Version))
  result = call_600394.call(nil, query_600395, nil, nil, nil)

var getDescribeStemmingOptions* = Call_GetDescribeStemmingOptions_600380(
    name: "getDescribeStemmingOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeStemmingOptions",
    validator: validate_GetDescribeStemmingOptions_600381, base: "/",
    url: url_GetDescribeStemmingOptions_600382,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeStopwordOptions_600429 = ref object of OpenApiRestCall_599368
proc url_PostDescribeStopwordOptions_600431(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeStopwordOptions_600430(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the stopwords configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600432 = query.getOrDefault("Action")
  valid_600432 = validateParameter(valid_600432, JString, required = true, default = newJString(
      "DescribeStopwordOptions"))
  if valid_600432 != nil:
    section.add "Action", valid_600432
  var valid_600433 = query.getOrDefault("Version")
  valid_600433 = validateParameter(valid_600433, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_600433 != nil:
    section.add "Version", valid_600433
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600434 = header.getOrDefault("X-Amz-Date")
  valid_600434 = validateParameter(valid_600434, JString, required = false,
                                 default = nil)
  if valid_600434 != nil:
    section.add "X-Amz-Date", valid_600434
  var valid_600435 = header.getOrDefault("X-Amz-Security-Token")
  valid_600435 = validateParameter(valid_600435, JString, required = false,
                                 default = nil)
  if valid_600435 != nil:
    section.add "X-Amz-Security-Token", valid_600435
  var valid_600436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600436 = validateParameter(valid_600436, JString, required = false,
                                 default = nil)
  if valid_600436 != nil:
    section.add "X-Amz-Content-Sha256", valid_600436
  var valid_600437 = header.getOrDefault("X-Amz-Algorithm")
  valid_600437 = validateParameter(valid_600437, JString, required = false,
                                 default = nil)
  if valid_600437 != nil:
    section.add "X-Amz-Algorithm", valid_600437
  var valid_600438 = header.getOrDefault("X-Amz-Signature")
  valid_600438 = validateParameter(valid_600438, JString, required = false,
                                 default = nil)
  if valid_600438 != nil:
    section.add "X-Amz-Signature", valid_600438
  var valid_600439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600439 = validateParameter(valid_600439, JString, required = false,
                                 default = nil)
  if valid_600439 != nil:
    section.add "X-Amz-SignedHeaders", valid_600439
  var valid_600440 = header.getOrDefault("X-Amz-Credential")
  valid_600440 = validateParameter(valid_600440, JString, required = false,
                                 default = nil)
  if valid_600440 != nil:
    section.add "X-Amz-Credential", valid_600440
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_600441 = formData.getOrDefault("DomainName")
  valid_600441 = validateParameter(valid_600441, JString, required = true,
                                 default = nil)
  if valid_600441 != nil:
    section.add "DomainName", valid_600441
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600442: Call_PostDescribeStopwordOptions_600429; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the stopwords configured for the search domain.
  ## 
  let valid = call_600442.validator(path, query, header, formData, body)
  let scheme = call_600442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600442.url(scheme.get, call_600442.host, call_600442.base,
                         call_600442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600442, url, valid)

proc call*(call_600443: Call_PostDescribeStopwordOptions_600429;
          DomainName: string; Action: string = "DescribeStopwordOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeStopwordOptions
  ## Gets the stopwords configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600444 = newJObject()
  var formData_600445 = newJObject()
  add(formData_600445, "DomainName", newJString(DomainName))
  add(query_600444, "Action", newJString(Action))
  add(query_600444, "Version", newJString(Version))
  result = call_600443.call(nil, query_600444, nil, formData_600445, nil)

var postDescribeStopwordOptions* = Call_PostDescribeStopwordOptions_600429(
    name: "postDescribeStopwordOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeStopwordOptions",
    validator: validate_PostDescribeStopwordOptions_600430, base: "/",
    url: url_PostDescribeStopwordOptions_600431,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeStopwordOptions_600413 = ref object of OpenApiRestCall_599368
proc url_GetDescribeStopwordOptions_600415(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeStopwordOptions_600414(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the stopwords configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600416 = query.getOrDefault("Action")
  valid_600416 = validateParameter(valid_600416, JString, required = true, default = newJString(
      "DescribeStopwordOptions"))
  if valid_600416 != nil:
    section.add "Action", valid_600416
  var valid_600417 = query.getOrDefault("DomainName")
  valid_600417 = validateParameter(valid_600417, JString, required = true,
                                 default = nil)
  if valid_600417 != nil:
    section.add "DomainName", valid_600417
  var valid_600418 = query.getOrDefault("Version")
  valid_600418 = validateParameter(valid_600418, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_600418 != nil:
    section.add "Version", valid_600418
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600419 = header.getOrDefault("X-Amz-Date")
  valid_600419 = validateParameter(valid_600419, JString, required = false,
                                 default = nil)
  if valid_600419 != nil:
    section.add "X-Amz-Date", valid_600419
  var valid_600420 = header.getOrDefault("X-Amz-Security-Token")
  valid_600420 = validateParameter(valid_600420, JString, required = false,
                                 default = nil)
  if valid_600420 != nil:
    section.add "X-Amz-Security-Token", valid_600420
  var valid_600421 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600421 = validateParameter(valid_600421, JString, required = false,
                                 default = nil)
  if valid_600421 != nil:
    section.add "X-Amz-Content-Sha256", valid_600421
  var valid_600422 = header.getOrDefault("X-Amz-Algorithm")
  valid_600422 = validateParameter(valid_600422, JString, required = false,
                                 default = nil)
  if valid_600422 != nil:
    section.add "X-Amz-Algorithm", valid_600422
  var valid_600423 = header.getOrDefault("X-Amz-Signature")
  valid_600423 = validateParameter(valid_600423, JString, required = false,
                                 default = nil)
  if valid_600423 != nil:
    section.add "X-Amz-Signature", valid_600423
  var valid_600424 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600424 = validateParameter(valid_600424, JString, required = false,
                                 default = nil)
  if valid_600424 != nil:
    section.add "X-Amz-SignedHeaders", valid_600424
  var valid_600425 = header.getOrDefault("X-Amz-Credential")
  valid_600425 = validateParameter(valid_600425, JString, required = false,
                                 default = nil)
  if valid_600425 != nil:
    section.add "X-Amz-Credential", valid_600425
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600426: Call_GetDescribeStopwordOptions_600413; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the stopwords configured for the search domain.
  ## 
  let valid = call_600426.validator(path, query, header, formData, body)
  let scheme = call_600426.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600426.url(scheme.get, call_600426.host, call_600426.base,
                         call_600426.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600426, url, valid)

proc call*(call_600427: Call_GetDescribeStopwordOptions_600413; DomainName: string;
          Action: string = "DescribeStopwordOptions"; Version: string = "2011-02-01"): Recallable =
  ## getDescribeStopwordOptions
  ## Gets the stopwords configured for the search domain.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_600428 = newJObject()
  add(query_600428, "Action", newJString(Action))
  add(query_600428, "DomainName", newJString(DomainName))
  add(query_600428, "Version", newJString(Version))
  result = call_600427.call(nil, query_600428, nil, nil, nil)

var getDescribeStopwordOptions* = Call_GetDescribeStopwordOptions_600413(
    name: "getDescribeStopwordOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeStopwordOptions",
    validator: validate_GetDescribeStopwordOptions_600414, base: "/",
    url: url_GetDescribeStopwordOptions_600415,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeSynonymOptions_600462 = ref object of OpenApiRestCall_599368
proc url_PostDescribeSynonymOptions_600464(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeSynonymOptions_600463(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the synonym dictionary configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600465 = query.getOrDefault("Action")
  valid_600465 = validateParameter(valid_600465, JString, required = true,
                                 default = newJString("DescribeSynonymOptions"))
  if valid_600465 != nil:
    section.add "Action", valid_600465
  var valid_600466 = query.getOrDefault("Version")
  valid_600466 = validateParameter(valid_600466, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_600466 != nil:
    section.add "Version", valid_600466
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600467 = header.getOrDefault("X-Amz-Date")
  valid_600467 = validateParameter(valid_600467, JString, required = false,
                                 default = nil)
  if valid_600467 != nil:
    section.add "X-Amz-Date", valid_600467
  var valid_600468 = header.getOrDefault("X-Amz-Security-Token")
  valid_600468 = validateParameter(valid_600468, JString, required = false,
                                 default = nil)
  if valid_600468 != nil:
    section.add "X-Amz-Security-Token", valid_600468
  var valid_600469 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600469 = validateParameter(valid_600469, JString, required = false,
                                 default = nil)
  if valid_600469 != nil:
    section.add "X-Amz-Content-Sha256", valid_600469
  var valid_600470 = header.getOrDefault("X-Amz-Algorithm")
  valid_600470 = validateParameter(valid_600470, JString, required = false,
                                 default = nil)
  if valid_600470 != nil:
    section.add "X-Amz-Algorithm", valid_600470
  var valid_600471 = header.getOrDefault("X-Amz-Signature")
  valid_600471 = validateParameter(valid_600471, JString, required = false,
                                 default = nil)
  if valid_600471 != nil:
    section.add "X-Amz-Signature", valid_600471
  var valid_600472 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600472 = validateParameter(valid_600472, JString, required = false,
                                 default = nil)
  if valid_600472 != nil:
    section.add "X-Amz-SignedHeaders", valid_600472
  var valid_600473 = header.getOrDefault("X-Amz-Credential")
  valid_600473 = validateParameter(valid_600473, JString, required = false,
                                 default = nil)
  if valid_600473 != nil:
    section.add "X-Amz-Credential", valid_600473
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_600474 = formData.getOrDefault("DomainName")
  valid_600474 = validateParameter(valid_600474, JString, required = true,
                                 default = nil)
  if valid_600474 != nil:
    section.add "DomainName", valid_600474
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600475: Call_PostDescribeSynonymOptions_600462; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the synonym dictionary configured for the search domain.
  ## 
  let valid = call_600475.validator(path, query, header, formData, body)
  let scheme = call_600475.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600475.url(scheme.get, call_600475.host, call_600475.base,
                         call_600475.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600475, url, valid)

proc call*(call_600476: Call_PostDescribeSynonymOptions_600462; DomainName: string;
          Action: string = "DescribeSynonymOptions"; Version: string = "2011-02-01"): Recallable =
  ## postDescribeSynonymOptions
  ## Gets the synonym dictionary configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600477 = newJObject()
  var formData_600478 = newJObject()
  add(formData_600478, "DomainName", newJString(DomainName))
  add(query_600477, "Action", newJString(Action))
  add(query_600477, "Version", newJString(Version))
  result = call_600476.call(nil, query_600477, nil, formData_600478, nil)

var postDescribeSynonymOptions* = Call_PostDescribeSynonymOptions_600462(
    name: "postDescribeSynonymOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeSynonymOptions",
    validator: validate_PostDescribeSynonymOptions_600463, base: "/",
    url: url_PostDescribeSynonymOptions_600464,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeSynonymOptions_600446 = ref object of OpenApiRestCall_599368
proc url_GetDescribeSynonymOptions_600448(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeSynonymOptions_600447(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the synonym dictionary configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600449 = query.getOrDefault("Action")
  valid_600449 = validateParameter(valid_600449, JString, required = true,
                                 default = newJString("DescribeSynonymOptions"))
  if valid_600449 != nil:
    section.add "Action", valid_600449
  var valid_600450 = query.getOrDefault("DomainName")
  valid_600450 = validateParameter(valid_600450, JString, required = true,
                                 default = nil)
  if valid_600450 != nil:
    section.add "DomainName", valid_600450
  var valid_600451 = query.getOrDefault("Version")
  valid_600451 = validateParameter(valid_600451, JString, required = true,
                                 default = newJString("2011-02-01"))
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600459: Call_GetDescribeSynonymOptions_600446; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the synonym dictionary configured for the search domain.
  ## 
  let valid = call_600459.validator(path, query, header, formData, body)
  let scheme = call_600459.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600459.url(scheme.get, call_600459.host, call_600459.base,
                         call_600459.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600459, url, valid)

proc call*(call_600460: Call_GetDescribeSynonymOptions_600446; DomainName: string;
          Action: string = "DescribeSynonymOptions"; Version: string = "2011-02-01"): Recallable =
  ## getDescribeSynonymOptions
  ## Gets the synonym dictionary configured for the search domain.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_600461 = newJObject()
  add(query_600461, "Action", newJString(Action))
  add(query_600461, "DomainName", newJString(DomainName))
  add(query_600461, "Version", newJString(Version))
  result = call_600460.call(nil, query_600461, nil, nil, nil)

var getDescribeSynonymOptions* = Call_GetDescribeSynonymOptions_600446(
    name: "getDescribeSynonymOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeSynonymOptions",
    validator: validate_GetDescribeSynonymOptions_600447, base: "/",
    url: url_GetDescribeSynonymOptions_600448,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostIndexDocuments_600495 = ref object of OpenApiRestCall_599368
proc url_PostIndexDocuments_600497(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostIndexDocuments_600496(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600498 = query.getOrDefault("Action")
  valid_600498 = validateParameter(valid_600498, JString, required = true,
                                 default = newJString("IndexDocuments"))
  if valid_600498 != nil:
    section.add "Action", valid_600498
  var valid_600499 = query.getOrDefault("Version")
  valid_600499 = validateParameter(valid_600499, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_600499 != nil:
    section.add "Version", valid_600499
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600500 = header.getOrDefault("X-Amz-Date")
  valid_600500 = validateParameter(valid_600500, JString, required = false,
                                 default = nil)
  if valid_600500 != nil:
    section.add "X-Amz-Date", valid_600500
  var valid_600501 = header.getOrDefault("X-Amz-Security-Token")
  valid_600501 = validateParameter(valid_600501, JString, required = false,
                                 default = nil)
  if valid_600501 != nil:
    section.add "X-Amz-Security-Token", valid_600501
  var valid_600502 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600502 = validateParameter(valid_600502, JString, required = false,
                                 default = nil)
  if valid_600502 != nil:
    section.add "X-Amz-Content-Sha256", valid_600502
  var valid_600503 = header.getOrDefault("X-Amz-Algorithm")
  valid_600503 = validateParameter(valid_600503, JString, required = false,
                                 default = nil)
  if valid_600503 != nil:
    section.add "X-Amz-Algorithm", valid_600503
  var valid_600504 = header.getOrDefault("X-Amz-Signature")
  valid_600504 = validateParameter(valid_600504, JString, required = false,
                                 default = nil)
  if valid_600504 != nil:
    section.add "X-Amz-Signature", valid_600504
  var valid_600505 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600505 = validateParameter(valid_600505, JString, required = false,
                                 default = nil)
  if valid_600505 != nil:
    section.add "X-Amz-SignedHeaders", valid_600505
  var valid_600506 = header.getOrDefault("X-Amz-Credential")
  valid_600506 = validateParameter(valid_600506, JString, required = false,
                                 default = nil)
  if valid_600506 != nil:
    section.add "X-Amz-Credential", valid_600506
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_600507 = formData.getOrDefault("DomainName")
  valid_600507 = validateParameter(valid_600507, JString, required = true,
                                 default = nil)
  if valid_600507 != nil:
    section.add "DomainName", valid_600507
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600508: Call_PostIndexDocuments_600495; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ## 
  let valid = call_600508.validator(path, query, header, formData, body)
  let scheme = call_600508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600508.url(scheme.get, call_600508.host, call_600508.base,
                         call_600508.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600508, url, valid)

proc call*(call_600509: Call_PostIndexDocuments_600495; DomainName: string;
          Action: string = "IndexDocuments"; Version: string = "2011-02-01"): Recallable =
  ## postIndexDocuments
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600510 = newJObject()
  var formData_600511 = newJObject()
  add(formData_600511, "DomainName", newJString(DomainName))
  add(query_600510, "Action", newJString(Action))
  add(query_600510, "Version", newJString(Version))
  result = call_600509.call(nil, query_600510, nil, formData_600511, nil)

var postIndexDocuments* = Call_PostIndexDocuments_600495(
    name: "postIndexDocuments", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=IndexDocuments",
    validator: validate_PostIndexDocuments_600496, base: "/",
    url: url_PostIndexDocuments_600497, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIndexDocuments_600479 = ref object of OpenApiRestCall_599368
proc url_GetIndexDocuments_600481(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetIndexDocuments_600480(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600482 = query.getOrDefault("Action")
  valid_600482 = validateParameter(valid_600482, JString, required = true,
                                 default = newJString("IndexDocuments"))
  if valid_600482 != nil:
    section.add "Action", valid_600482
  var valid_600483 = query.getOrDefault("DomainName")
  valid_600483 = validateParameter(valid_600483, JString, required = true,
                                 default = nil)
  if valid_600483 != nil:
    section.add "DomainName", valid_600483
  var valid_600484 = query.getOrDefault("Version")
  valid_600484 = validateParameter(valid_600484, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_600484 != nil:
    section.add "Version", valid_600484
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600485 = header.getOrDefault("X-Amz-Date")
  valid_600485 = validateParameter(valid_600485, JString, required = false,
                                 default = nil)
  if valid_600485 != nil:
    section.add "X-Amz-Date", valid_600485
  var valid_600486 = header.getOrDefault("X-Amz-Security-Token")
  valid_600486 = validateParameter(valid_600486, JString, required = false,
                                 default = nil)
  if valid_600486 != nil:
    section.add "X-Amz-Security-Token", valid_600486
  var valid_600487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600487 = validateParameter(valid_600487, JString, required = false,
                                 default = nil)
  if valid_600487 != nil:
    section.add "X-Amz-Content-Sha256", valid_600487
  var valid_600488 = header.getOrDefault("X-Amz-Algorithm")
  valid_600488 = validateParameter(valid_600488, JString, required = false,
                                 default = nil)
  if valid_600488 != nil:
    section.add "X-Amz-Algorithm", valid_600488
  var valid_600489 = header.getOrDefault("X-Amz-Signature")
  valid_600489 = validateParameter(valid_600489, JString, required = false,
                                 default = nil)
  if valid_600489 != nil:
    section.add "X-Amz-Signature", valid_600489
  var valid_600490 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600490 = validateParameter(valid_600490, JString, required = false,
                                 default = nil)
  if valid_600490 != nil:
    section.add "X-Amz-SignedHeaders", valid_600490
  var valid_600491 = header.getOrDefault("X-Amz-Credential")
  valid_600491 = validateParameter(valid_600491, JString, required = false,
                                 default = nil)
  if valid_600491 != nil:
    section.add "X-Amz-Credential", valid_600491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600492: Call_GetIndexDocuments_600479; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ## 
  let valid = call_600492.validator(path, query, header, formData, body)
  let scheme = call_600492.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600492.url(scheme.get, call_600492.host, call_600492.base,
                         call_600492.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600492, url, valid)

proc call*(call_600493: Call_GetIndexDocuments_600479; DomainName: string;
          Action: string = "IndexDocuments"; Version: string = "2011-02-01"): Recallable =
  ## getIndexDocuments
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_600494 = newJObject()
  add(query_600494, "Action", newJString(Action))
  add(query_600494, "DomainName", newJString(DomainName))
  add(query_600494, "Version", newJString(Version))
  result = call_600493.call(nil, query_600494, nil, nil, nil)

var getIndexDocuments* = Call_GetIndexDocuments_600479(name: "getIndexDocuments",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=IndexDocuments", validator: validate_GetIndexDocuments_600480,
    base: "/", url: url_GetIndexDocuments_600481,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateAvailabilityOptions_600529 = ref object of OpenApiRestCall_599368
proc url_PostUpdateAvailabilityOptions_600531(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateAvailabilityOptions_600530(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600532 = query.getOrDefault("Action")
  valid_600532 = validateParameter(valid_600532, JString, required = true, default = newJString(
      "UpdateAvailabilityOptions"))
  if valid_600532 != nil:
    section.add "Action", valid_600532
  var valid_600533 = query.getOrDefault("Version")
  valid_600533 = validateParameter(valid_600533, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_600533 != nil:
    section.add "Version", valid_600533
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600534 = header.getOrDefault("X-Amz-Date")
  valid_600534 = validateParameter(valid_600534, JString, required = false,
                                 default = nil)
  if valid_600534 != nil:
    section.add "X-Amz-Date", valid_600534
  var valid_600535 = header.getOrDefault("X-Amz-Security-Token")
  valid_600535 = validateParameter(valid_600535, JString, required = false,
                                 default = nil)
  if valid_600535 != nil:
    section.add "X-Amz-Security-Token", valid_600535
  var valid_600536 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600536 = validateParameter(valid_600536, JString, required = false,
                                 default = nil)
  if valid_600536 != nil:
    section.add "X-Amz-Content-Sha256", valid_600536
  var valid_600537 = header.getOrDefault("X-Amz-Algorithm")
  valid_600537 = validateParameter(valid_600537, JString, required = false,
                                 default = nil)
  if valid_600537 != nil:
    section.add "X-Amz-Algorithm", valid_600537
  var valid_600538 = header.getOrDefault("X-Amz-Signature")
  valid_600538 = validateParameter(valid_600538, JString, required = false,
                                 default = nil)
  if valid_600538 != nil:
    section.add "X-Amz-Signature", valid_600538
  var valid_600539 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600539 = validateParameter(valid_600539, JString, required = false,
                                 default = nil)
  if valid_600539 != nil:
    section.add "X-Amz-SignedHeaders", valid_600539
  var valid_600540 = header.getOrDefault("X-Amz-Credential")
  valid_600540 = validateParameter(valid_600540, JString, required = false,
                                 default = nil)
  if valid_600540 != nil:
    section.add "X-Amz-Credential", valid_600540
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   MultiAZ: JBool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_600541 = formData.getOrDefault("DomainName")
  valid_600541 = validateParameter(valid_600541, JString, required = true,
                                 default = nil)
  if valid_600541 != nil:
    section.add "DomainName", valid_600541
  var valid_600542 = formData.getOrDefault("MultiAZ")
  valid_600542 = validateParameter(valid_600542, JBool, required = true, default = nil)
  if valid_600542 != nil:
    section.add "MultiAZ", valid_600542
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600543: Call_PostUpdateAvailabilityOptions_600529; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_600543.validator(path, query, header, formData, body)
  let scheme = call_600543.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600543.url(scheme.get, call_600543.host, call_600543.base,
                         call_600543.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600543, url, valid)

proc call*(call_600544: Call_PostUpdateAvailabilityOptions_600529;
          DomainName: string; MultiAZ: bool;
          Action: string = "UpdateAvailabilityOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postUpdateAvailabilityOptions
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   MultiAZ: bool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600545 = newJObject()
  var formData_600546 = newJObject()
  add(formData_600546, "DomainName", newJString(DomainName))
  add(formData_600546, "MultiAZ", newJBool(MultiAZ))
  add(query_600545, "Action", newJString(Action))
  add(query_600545, "Version", newJString(Version))
  result = call_600544.call(nil, query_600545, nil, formData_600546, nil)

var postUpdateAvailabilityOptions* = Call_PostUpdateAvailabilityOptions_600529(
    name: "postUpdateAvailabilityOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateAvailabilityOptions",
    validator: validate_PostUpdateAvailabilityOptions_600530, base: "/",
    url: url_PostUpdateAvailabilityOptions_600531,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateAvailabilityOptions_600512 = ref object of OpenApiRestCall_599368
proc url_GetUpdateAvailabilityOptions_600514(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateAvailabilityOptions_600513(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MultiAZ: JBool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `MultiAZ` field"
  var valid_600515 = query.getOrDefault("MultiAZ")
  valid_600515 = validateParameter(valid_600515, JBool, required = true, default = nil)
  if valid_600515 != nil:
    section.add "MultiAZ", valid_600515
  var valid_600516 = query.getOrDefault("Action")
  valid_600516 = validateParameter(valid_600516, JString, required = true, default = newJString(
      "UpdateAvailabilityOptions"))
  if valid_600516 != nil:
    section.add "Action", valid_600516
  var valid_600517 = query.getOrDefault("DomainName")
  valid_600517 = validateParameter(valid_600517, JString, required = true,
                                 default = nil)
  if valid_600517 != nil:
    section.add "DomainName", valid_600517
  var valid_600518 = query.getOrDefault("Version")
  valid_600518 = validateParameter(valid_600518, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_600518 != nil:
    section.add "Version", valid_600518
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600519 = header.getOrDefault("X-Amz-Date")
  valid_600519 = validateParameter(valid_600519, JString, required = false,
                                 default = nil)
  if valid_600519 != nil:
    section.add "X-Amz-Date", valid_600519
  var valid_600520 = header.getOrDefault("X-Amz-Security-Token")
  valid_600520 = validateParameter(valid_600520, JString, required = false,
                                 default = nil)
  if valid_600520 != nil:
    section.add "X-Amz-Security-Token", valid_600520
  var valid_600521 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600521 = validateParameter(valid_600521, JString, required = false,
                                 default = nil)
  if valid_600521 != nil:
    section.add "X-Amz-Content-Sha256", valid_600521
  var valid_600522 = header.getOrDefault("X-Amz-Algorithm")
  valid_600522 = validateParameter(valid_600522, JString, required = false,
                                 default = nil)
  if valid_600522 != nil:
    section.add "X-Amz-Algorithm", valid_600522
  var valid_600523 = header.getOrDefault("X-Amz-Signature")
  valid_600523 = validateParameter(valid_600523, JString, required = false,
                                 default = nil)
  if valid_600523 != nil:
    section.add "X-Amz-Signature", valid_600523
  var valid_600524 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600524 = validateParameter(valid_600524, JString, required = false,
                                 default = nil)
  if valid_600524 != nil:
    section.add "X-Amz-SignedHeaders", valid_600524
  var valid_600525 = header.getOrDefault("X-Amz-Credential")
  valid_600525 = validateParameter(valid_600525, JString, required = false,
                                 default = nil)
  if valid_600525 != nil:
    section.add "X-Amz-Credential", valid_600525
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600526: Call_GetUpdateAvailabilityOptions_600512; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_600526.validator(path, query, header, formData, body)
  let scheme = call_600526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600526.url(scheme.get, call_600526.host, call_600526.base,
                         call_600526.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600526, url, valid)

proc call*(call_600527: Call_GetUpdateAvailabilityOptions_600512; MultiAZ: bool;
          DomainName: string; Action: string = "UpdateAvailabilityOptions";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateAvailabilityOptions
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   MultiAZ: bool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_600528 = newJObject()
  add(query_600528, "MultiAZ", newJBool(MultiAZ))
  add(query_600528, "Action", newJString(Action))
  add(query_600528, "DomainName", newJString(DomainName))
  add(query_600528, "Version", newJString(Version))
  result = call_600527.call(nil, query_600528, nil, nil, nil)

var getUpdateAvailabilityOptions* = Call_GetUpdateAvailabilityOptions_600512(
    name: "getUpdateAvailabilityOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateAvailabilityOptions",
    validator: validate_GetUpdateAvailabilityOptions_600513, base: "/",
    url: url_GetUpdateAvailabilityOptions_600514,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateDefaultSearchField_600564 = ref object of OpenApiRestCall_599368
proc url_PostUpdateDefaultSearchField_600566(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateDefaultSearchField_600565(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600567 = query.getOrDefault("Action")
  valid_600567 = validateParameter(valid_600567, JString, required = true, default = newJString(
      "UpdateDefaultSearchField"))
  if valid_600567 != nil:
    section.add "Action", valid_600567
  var valid_600568 = query.getOrDefault("Version")
  valid_600568 = validateParameter(valid_600568, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_600568 != nil:
    section.add "Version", valid_600568
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600569 = header.getOrDefault("X-Amz-Date")
  valid_600569 = validateParameter(valid_600569, JString, required = false,
                                 default = nil)
  if valid_600569 != nil:
    section.add "X-Amz-Date", valid_600569
  var valid_600570 = header.getOrDefault("X-Amz-Security-Token")
  valid_600570 = validateParameter(valid_600570, JString, required = false,
                                 default = nil)
  if valid_600570 != nil:
    section.add "X-Amz-Security-Token", valid_600570
  var valid_600571 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600571 = validateParameter(valid_600571, JString, required = false,
                                 default = nil)
  if valid_600571 != nil:
    section.add "X-Amz-Content-Sha256", valid_600571
  var valid_600572 = header.getOrDefault("X-Amz-Algorithm")
  valid_600572 = validateParameter(valid_600572, JString, required = false,
                                 default = nil)
  if valid_600572 != nil:
    section.add "X-Amz-Algorithm", valid_600572
  var valid_600573 = header.getOrDefault("X-Amz-Signature")
  valid_600573 = validateParameter(valid_600573, JString, required = false,
                                 default = nil)
  if valid_600573 != nil:
    section.add "X-Amz-Signature", valid_600573
  var valid_600574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600574 = validateParameter(valid_600574, JString, required = false,
                                 default = nil)
  if valid_600574 != nil:
    section.add "X-Amz-SignedHeaders", valid_600574
  var valid_600575 = header.getOrDefault("X-Amz-Credential")
  valid_600575 = validateParameter(valid_600575, JString, required = false,
                                 default = nil)
  if valid_600575 != nil:
    section.add "X-Amz-Credential", valid_600575
  result.add "header", section
  ## parameters in `formData` object:
  ##   DefaultSearchField: JString (required)
  ##                     : The text field to search if the search request does not specify which field to search. The default search field is used when search terms are specified with the <code>q</code> parameter, or if a match expression specified with the <code>bq</code> parameter does not constrain the search to a particular field. The default is an empty string, which automatically searches all text fields.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DefaultSearchField` field"
  var valid_600576 = formData.getOrDefault("DefaultSearchField")
  valid_600576 = validateParameter(valid_600576, JString, required = true,
                                 default = nil)
  if valid_600576 != nil:
    section.add "DefaultSearchField", valid_600576
  var valid_600577 = formData.getOrDefault("DomainName")
  valid_600577 = validateParameter(valid_600577, JString, required = true,
                                 default = nil)
  if valid_600577 != nil:
    section.add "DomainName", valid_600577
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600578: Call_PostUpdateDefaultSearchField_600564; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ## 
  let valid = call_600578.validator(path, query, header, formData, body)
  let scheme = call_600578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600578.url(scheme.get, call_600578.host, call_600578.base,
                         call_600578.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600578, url, valid)

proc call*(call_600579: Call_PostUpdateDefaultSearchField_600564;
          DefaultSearchField: string; DomainName: string;
          Action: string = "UpdateDefaultSearchField";
          Version: string = "2011-02-01"): Recallable =
  ## postUpdateDefaultSearchField
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ##   DefaultSearchField: string (required)
  ##                     : The text field to search if the search request does not specify which field to search. The default search field is used when search terms are specified with the <code>q</code> parameter, or if a match expression specified with the <code>bq</code> parameter does not constrain the search to a particular field. The default is an empty string, which automatically searches all text fields.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600580 = newJObject()
  var formData_600581 = newJObject()
  add(formData_600581, "DefaultSearchField", newJString(DefaultSearchField))
  add(formData_600581, "DomainName", newJString(DomainName))
  add(query_600580, "Action", newJString(Action))
  add(query_600580, "Version", newJString(Version))
  result = call_600579.call(nil, query_600580, nil, formData_600581, nil)

var postUpdateDefaultSearchField* = Call_PostUpdateDefaultSearchField_600564(
    name: "postUpdateDefaultSearchField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateDefaultSearchField",
    validator: validate_PostUpdateDefaultSearchField_600565, base: "/",
    url: url_PostUpdateDefaultSearchField_600566,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateDefaultSearchField_600547 = ref object of OpenApiRestCall_599368
proc url_GetUpdateDefaultSearchField_600549(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateDefaultSearchField_600548(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   DefaultSearchField: JString (required)
  ##                     : The text field to search if the search request does not specify which field to search. The default search field is used when search terms are specified with the <code>q</code> parameter, or if a match expression specified with the <code>bq</code> parameter does not constrain the search to a particular field. The default is an empty string, which automatically searches all text fields.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600550 = query.getOrDefault("Action")
  valid_600550 = validateParameter(valid_600550, JString, required = true, default = newJString(
      "UpdateDefaultSearchField"))
  if valid_600550 != nil:
    section.add "Action", valid_600550
  var valid_600551 = query.getOrDefault("DomainName")
  valid_600551 = validateParameter(valid_600551, JString, required = true,
                                 default = nil)
  if valid_600551 != nil:
    section.add "DomainName", valid_600551
  var valid_600552 = query.getOrDefault("DefaultSearchField")
  valid_600552 = validateParameter(valid_600552, JString, required = true,
                                 default = nil)
  if valid_600552 != nil:
    section.add "DefaultSearchField", valid_600552
  var valid_600553 = query.getOrDefault("Version")
  valid_600553 = validateParameter(valid_600553, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_600553 != nil:
    section.add "Version", valid_600553
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600554 = header.getOrDefault("X-Amz-Date")
  valid_600554 = validateParameter(valid_600554, JString, required = false,
                                 default = nil)
  if valid_600554 != nil:
    section.add "X-Amz-Date", valid_600554
  var valid_600555 = header.getOrDefault("X-Amz-Security-Token")
  valid_600555 = validateParameter(valid_600555, JString, required = false,
                                 default = nil)
  if valid_600555 != nil:
    section.add "X-Amz-Security-Token", valid_600555
  var valid_600556 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600556 = validateParameter(valid_600556, JString, required = false,
                                 default = nil)
  if valid_600556 != nil:
    section.add "X-Amz-Content-Sha256", valid_600556
  var valid_600557 = header.getOrDefault("X-Amz-Algorithm")
  valid_600557 = validateParameter(valid_600557, JString, required = false,
                                 default = nil)
  if valid_600557 != nil:
    section.add "X-Amz-Algorithm", valid_600557
  var valid_600558 = header.getOrDefault("X-Amz-Signature")
  valid_600558 = validateParameter(valid_600558, JString, required = false,
                                 default = nil)
  if valid_600558 != nil:
    section.add "X-Amz-Signature", valid_600558
  var valid_600559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600559 = validateParameter(valid_600559, JString, required = false,
                                 default = nil)
  if valid_600559 != nil:
    section.add "X-Amz-SignedHeaders", valid_600559
  var valid_600560 = header.getOrDefault("X-Amz-Credential")
  valid_600560 = validateParameter(valid_600560, JString, required = false,
                                 default = nil)
  if valid_600560 != nil:
    section.add "X-Amz-Credential", valid_600560
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600561: Call_GetUpdateDefaultSearchField_600547; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ## 
  let valid = call_600561.validator(path, query, header, formData, body)
  let scheme = call_600561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600561.url(scheme.get, call_600561.host, call_600561.base,
                         call_600561.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600561, url, valid)

proc call*(call_600562: Call_GetUpdateDefaultSearchField_600547;
          DomainName: string; DefaultSearchField: string;
          Action: string = "UpdateDefaultSearchField";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateDefaultSearchField
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   DefaultSearchField: string (required)
  ##                     : The text field to search if the search request does not specify which field to search. The default search field is used when search terms are specified with the <code>q</code> parameter, or if a match expression specified with the <code>bq</code> parameter does not constrain the search to a particular field. The default is an empty string, which automatically searches all text fields.
  ##   Version: string (required)
  var query_600563 = newJObject()
  add(query_600563, "Action", newJString(Action))
  add(query_600563, "DomainName", newJString(DomainName))
  add(query_600563, "DefaultSearchField", newJString(DefaultSearchField))
  add(query_600563, "Version", newJString(Version))
  result = call_600562.call(nil, query_600563, nil, nil, nil)

var getUpdateDefaultSearchField* = Call_GetUpdateDefaultSearchField_600547(
    name: "getUpdateDefaultSearchField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateDefaultSearchField",
    validator: validate_GetUpdateDefaultSearchField_600548, base: "/",
    url: url_GetUpdateDefaultSearchField_600549,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateServiceAccessPolicies_600599 = ref object of OpenApiRestCall_599368
proc url_PostUpdateServiceAccessPolicies_600601(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateServiceAccessPolicies_600600(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600602 = query.getOrDefault("Action")
  valid_600602 = validateParameter(valid_600602, JString, required = true, default = newJString(
      "UpdateServiceAccessPolicies"))
  if valid_600602 != nil:
    section.add "Action", valid_600602
  var valid_600603 = query.getOrDefault("Version")
  valid_600603 = validateParameter(valid_600603, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_600603 != nil:
    section.add "Version", valid_600603
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600604 = header.getOrDefault("X-Amz-Date")
  valid_600604 = validateParameter(valid_600604, JString, required = false,
                                 default = nil)
  if valid_600604 != nil:
    section.add "X-Amz-Date", valid_600604
  var valid_600605 = header.getOrDefault("X-Amz-Security-Token")
  valid_600605 = validateParameter(valid_600605, JString, required = false,
                                 default = nil)
  if valid_600605 != nil:
    section.add "X-Amz-Security-Token", valid_600605
  var valid_600606 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600606 = validateParameter(valid_600606, JString, required = false,
                                 default = nil)
  if valid_600606 != nil:
    section.add "X-Amz-Content-Sha256", valid_600606
  var valid_600607 = header.getOrDefault("X-Amz-Algorithm")
  valid_600607 = validateParameter(valid_600607, JString, required = false,
                                 default = nil)
  if valid_600607 != nil:
    section.add "X-Amz-Algorithm", valid_600607
  var valid_600608 = header.getOrDefault("X-Amz-Signature")
  valid_600608 = validateParameter(valid_600608, JString, required = false,
                                 default = nil)
  if valid_600608 != nil:
    section.add "X-Amz-Signature", valid_600608
  var valid_600609 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600609 = validateParameter(valid_600609, JString, required = false,
                                 default = nil)
  if valid_600609 != nil:
    section.add "X-Amz-SignedHeaders", valid_600609
  var valid_600610 = header.getOrDefault("X-Amz-Credential")
  valid_600610 = validateParameter(valid_600610, JString, required = false,
                                 default = nil)
  if valid_600610 != nil:
    section.add "X-Amz-Credential", valid_600610
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   AccessPolicies: JString (required)
  ##                 : <p>An IAM access policy as described in <a 
  ## href="http://docs.aws.amazon.com/IAM/latest/UserGuide/index.html?AccessPolicyLanguage.html" target="_blank">The Access Policy Language</a> in <i>Using AWS Identity and Access Management</i>. The maximum size of an access policy document is 100 KB.</p> <p>Example: <code>{"Statement": [{"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:search/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }}, {"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:documents/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }} ] }</code></p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_600611 = formData.getOrDefault("DomainName")
  valid_600611 = validateParameter(valid_600611, JString, required = true,
                                 default = nil)
  if valid_600611 != nil:
    section.add "DomainName", valid_600611
  var valid_600612 = formData.getOrDefault("AccessPolicies")
  valid_600612 = validateParameter(valid_600612, JString, required = true,
                                 default = nil)
  if valid_600612 != nil:
    section.add "AccessPolicies", valid_600612
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600613: Call_PostUpdateServiceAccessPolicies_600599;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ## 
  let valid = call_600613.validator(path, query, header, formData, body)
  let scheme = call_600613.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600613.url(scheme.get, call_600613.host, call_600613.base,
                         call_600613.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600613, url, valid)

proc call*(call_600614: Call_PostUpdateServiceAccessPolicies_600599;
          DomainName: string; AccessPolicies: string;
          Action: string = "UpdateServiceAccessPolicies";
          Version: string = "2011-02-01"): Recallable =
  ## postUpdateServiceAccessPolicies
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   AccessPolicies: string (required)
  ##                 : <p>An IAM access policy as described in <a 
  ## href="http://docs.aws.amazon.com/IAM/latest/UserGuide/index.html?AccessPolicyLanguage.html" target="_blank">The Access Policy Language</a> in <i>Using AWS Identity and Access Management</i>. The maximum size of an access policy document is 100 KB.</p> <p>Example: <code>{"Statement": [{"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:search/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }}, {"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:documents/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }} ] }</code></p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600615 = newJObject()
  var formData_600616 = newJObject()
  add(formData_600616, "DomainName", newJString(DomainName))
  add(formData_600616, "AccessPolicies", newJString(AccessPolicies))
  add(query_600615, "Action", newJString(Action))
  add(query_600615, "Version", newJString(Version))
  result = call_600614.call(nil, query_600615, nil, formData_600616, nil)

var postUpdateServiceAccessPolicies* = Call_PostUpdateServiceAccessPolicies_600599(
    name: "postUpdateServiceAccessPolicies", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateServiceAccessPolicies",
    validator: validate_PostUpdateServiceAccessPolicies_600600, base: "/",
    url: url_PostUpdateServiceAccessPolicies_600601,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateServiceAccessPolicies_600582 = ref object of OpenApiRestCall_599368
proc url_GetUpdateServiceAccessPolicies_600584(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateServiceAccessPolicies_600583(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   AccessPolicies: JString (required)
  ##                 : <p>An IAM access policy as described in <a 
  ## href="http://docs.aws.amazon.com/IAM/latest/UserGuide/index.html?AccessPolicyLanguage.html" target="_blank">The Access Policy Language</a> in <i>Using AWS Identity and Access Management</i>. The maximum size of an access policy document is 100 KB.</p> <p>Example: <code>{"Statement": [{"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:search/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }}, {"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:documents/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }} ] }</code></p>
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600585 = query.getOrDefault("Action")
  valid_600585 = validateParameter(valid_600585, JString, required = true, default = newJString(
      "UpdateServiceAccessPolicies"))
  if valid_600585 != nil:
    section.add "Action", valid_600585
  var valid_600586 = query.getOrDefault("AccessPolicies")
  valid_600586 = validateParameter(valid_600586, JString, required = true,
                                 default = nil)
  if valid_600586 != nil:
    section.add "AccessPolicies", valid_600586
  var valid_600587 = query.getOrDefault("DomainName")
  valid_600587 = validateParameter(valid_600587, JString, required = true,
                                 default = nil)
  if valid_600587 != nil:
    section.add "DomainName", valid_600587
  var valid_600588 = query.getOrDefault("Version")
  valid_600588 = validateParameter(valid_600588, JString, required = true,
                                 default = newJString("2011-02-01"))
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

proc call*(call_600596: Call_GetUpdateServiceAccessPolicies_600582; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ## 
  let valid = call_600596.validator(path, query, header, formData, body)
  let scheme = call_600596.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600596.url(scheme.get, call_600596.host, call_600596.base,
                         call_600596.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600596, url, valid)

proc call*(call_600597: Call_GetUpdateServiceAccessPolicies_600582;
          AccessPolicies: string; DomainName: string;
          Action: string = "UpdateServiceAccessPolicies";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateServiceAccessPolicies
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ##   Action: string (required)
  ##   AccessPolicies: string (required)
  ##                 : <p>An IAM access policy as described in <a 
  ## href="http://docs.aws.amazon.com/IAM/latest/UserGuide/index.html?AccessPolicyLanguage.html" target="_blank">The Access Policy Language</a> in <i>Using AWS Identity and Access Management</i>. The maximum size of an access policy document is 100 KB.</p> <p>Example: <code>{"Statement": [{"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:search/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }}, {"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:documents/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }} ] }</code></p>
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_600598 = newJObject()
  add(query_600598, "Action", newJString(Action))
  add(query_600598, "AccessPolicies", newJString(AccessPolicies))
  add(query_600598, "DomainName", newJString(DomainName))
  add(query_600598, "Version", newJString(Version))
  result = call_600597.call(nil, query_600598, nil, nil, nil)

var getUpdateServiceAccessPolicies* = Call_GetUpdateServiceAccessPolicies_600582(
    name: "getUpdateServiceAccessPolicies", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateServiceAccessPolicies",
    validator: validate_GetUpdateServiceAccessPolicies_600583, base: "/",
    url: url_GetUpdateServiceAccessPolicies_600584,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateStemmingOptions_600634 = ref object of OpenApiRestCall_599368
proc url_PostUpdateStemmingOptions_600636(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateStemmingOptions_600635(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600637 = query.getOrDefault("Action")
  valid_600637 = validateParameter(valid_600637, JString, required = true,
                                 default = newJString("UpdateStemmingOptions"))
  if valid_600637 != nil:
    section.add "Action", valid_600637
  var valid_600638 = query.getOrDefault("Version")
  valid_600638 = validateParameter(valid_600638, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_600638 != nil:
    section.add "Version", valid_600638
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600639 = header.getOrDefault("X-Amz-Date")
  valid_600639 = validateParameter(valid_600639, JString, required = false,
                                 default = nil)
  if valid_600639 != nil:
    section.add "X-Amz-Date", valid_600639
  var valid_600640 = header.getOrDefault("X-Amz-Security-Token")
  valid_600640 = validateParameter(valid_600640, JString, required = false,
                                 default = nil)
  if valid_600640 != nil:
    section.add "X-Amz-Security-Token", valid_600640
  var valid_600641 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600641 = validateParameter(valid_600641, JString, required = false,
                                 default = nil)
  if valid_600641 != nil:
    section.add "X-Amz-Content-Sha256", valid_600641
  var valid_600642 = header.getOrDefault("X-Amz-Algorithm")
  valid_600642 = validateParameter(valid_600642, JString, required = false,
                                 default = nil)
  if valid_600642 != nil:
    section.add "X-Amz-Algorithm", valid_600642
  var valid_600643 = header.getOrDefault("X-Amz-Signature")
  valid_600643 = validateParameter(valid_600643, JString, required = false,
                                 default = nil)
  if valid_600643 != nil:
    section.add "X-Amz-Signature", valid_600643
  var valid_600644 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600644 = validateParameter(valid_600644, JString, required = false,
                                 default = nil)
  if valid_600644 != nil:
    section.add "X-Amz-SignedHeaders", valid_600644
  var valid_600645 = header.getOrDefault("X-Amz-Credential")
  valid_600645 = validateParameter(valid_600645, JString, required = false,
                                 default = nil)
  if valid_600645 != nil:
    section.add "X-Amz-Credential", valid_600645
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Stems: JString (required)
  ##        : Maps terms to their stems, serialized as a JSON document. The document has a single object with one property "stems" whose value is an object mapping terms to their stems. The maximum size of a stemming document is 500 KB. Example: <code>{ "stems": {"people": "person", "walking": "walk"} }</code>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_600646 = formData.getOrDefault("DomainName")
  valid_600646 = validateParameter(valid_600646, JString, required = true,
                                 default = nil)
  if valid_600646 != nil:
    section.add "DomainName", valid_600646
  var valid_600647 = formData.getOrDefault("Stems")
  valid_600647 = validateParameter(valid_600647, JString, required = true,
                                 default = nil)
  if valid_600647 != nil:
    section.add "Stems", valid_600647
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600648: Call_PostUpdateStemmingOptions_600634; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ## 
  let valid = call_600648.validator(path, query, header, formData, body)
  let scheme = call_600648.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600648.url(scheme.get, call_600648.host, call_600648.base,
                         call_600648.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600648, url, valid)

proc call*(call_600649: Call_PostUpdateStemmingOptions_600634; DomainName: string;
          Stems: string; Action: string = "UpdateStemmingOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postUpdateStemmingOptions
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Stems: string (required)
  ##        : Maps terms to their stems, serialized as a JSON document. The document has a single object with one property "stems" whose value is an object mapping terms to their stems. The maximum size of a stemming document is 500 KB. Example: <code>{ "stems": {"people": "person", "walking": "walk"} }</code>
  ##   Version: string (required)
  var query_600650 = newJObject()
  var formData_600651 = newJObject()
  add(formData_600651, "DomainName", newJString(DomainName))
  add(query_600650, "Action", newJString(Action))
  add(formData_600651, "Stems", newJString(Stems))
  add(query_600650, "Version", newJString(Version))
  result = call_600649.call(nil, query_600650, nil, formData_600651, nil)

var postUpdateStemmingOptions* = Call_PostUpdateStemmingOptions_600634(
    name: "postUpdateStemmingOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateStemmingOptions",
    validator: validate_PostUpdateStemmingOptions_600635, base: "/",
    url: url_PostUpdateStemmingOptions_600636,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateStemmingOptions_600617 = ref object of OpenApiRestCall_599368
proc url_GetUpdateStemmingOptions_600619(protocol: Scheme; host: string;
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

proc validate_GetUpdateStemmingOptions_600618(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Stems: JString (required)
  ##        : Maps terms to their stems, serialized as a JSON document. The document has a single object with one property "stems" whose value is an object mapping terms to their stems. The maximum size of a stemming document is 500 KB. Example: <code>{ "stems": {"people": "person", "walking": "walk"} }</code>
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600620 = query.getOrDefault("Action")
  valid_600620 = validateParameter(valid_600620, JString, required = true,
                                 default = newJString("UpdateStemmingOptions"))
  if valid_600620 != nil:
    section.add "Action", valid_600620
  var valid_600621 = query.getOrDefault("Stems")
  valid_600621 = validateParameter(valid_600621, JString, required = true,
                                 default = nil)
  if valid_600621 != nil:
    section.add "Stems", valid_600621
  var valid_600622 = query.getOrDefault("DomainName")
  valid_600622 = validateParameter(valid_600622, JString, required = true,
                                 default = nil)
  if valid_600622 != nil:
    section.add "DomainName", valid_600622
  var valid_600623 = query.getOrDefault("Version")
  valid_600623 = validateParameter(valid_600623, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_600623 != nil:
    section.add "Version", valid_600623
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600624 = header.getOrDefault("X-Amz-Date")
  valid_600624 = validateParameter(valid_600624, JString, required = false,
                                 default = nil)
  if valid_600624 != nil:
    section.add "X-Amz-Date", valid_600624
  var valid_600625 = header.getOrDefault("X-Amz-Security-Token")
  valid_600625 = validateParameter(valid_600625, JString, required = false,
                                 default = nil)
  if valid_600625 != nil:
    section.add "X-Amz-Security-Token", valid_600625
  var valid_600626 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600626 = validateParameter(valid_600626, JString, required = false,
                                 default = nil)
  if valid_600626 != nil:
    section.add "X-Amz-Content-Sha256", valid_600626
  var valid_600627 = header.getOrDefault("X-Amz-Algorithm")
  valid_600627 = validateParameter(valid_600627, JString, required = false,
                                 default = nil)
  if valid_600627 != nil:
    section.add "X-Amz-Algorithm", valid_600627
  var valid_600628 = header.getOrDefault("X-Amz-Signature")
  valid_600628 = validateParameter(valid_600628, JString, required = false,
                                 default = nil)
  if valid_600628 != nil:
    section.add "X-Amz-Signature", valid_600628
  var valid_600629 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600629 = validateParameter(valid_600629, JString, required = false,
                                 default = nil)
  if valid_600629 != nil:
    section.add "X-Amz-SignedHeaders", valid_600629
  var valid_600630 = header.getOrDefault("X-Amz-Credential")
  valid_600630 = validateParameter(valid_600630, JString, required = false,
                                 default = nil)
  if valid_600630 != nil:
    section.add "X-Amz-Credential", valid_600630
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600631: Call_GetUpdateStemmingOptions_600617; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ## 
  let valid = call_600631.validator(path, query, header, formData, body)
  let scheme = call_600631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600631.url(scheme.get, call_600631.host, call_600631.base,
                         call_600631.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600631, url, valid)

proc call*(call_600632: Call_GetUpdateStemmingOptions_600617; Stems: string;
          DomainName: string; Action: string = "UpdateStemmingOptions";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateStemmingOptions
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ##   Action: string (required)
  ##   Stems: string (required)
  ##        : Maps terms to their stems, serialized as a JSON document. The document has a single object with one property "stems" whose value is an object mapping terms to their stems. The maximum size of a stemming document is 500 KB. Example: <code>{ "stems": {"people": "person", "walking": "walk"} }</code>
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_600633 = newJObject()
  add(query_600633, "Action", newJString(Action))
  add(query_600633, "Stems", newJString(Stems))
  add(query_600633, "DomainName", newJString(DomainName))
  add(query_600633, "Version", newJString(Version))
  result = call_600632.call(nil, query_600633, nil, nil, nil)

var getUpdateStemmingOptions* = Call_GetUpdateStemmingOptions_600617(
    name: "getUpdateStemmingOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateStemmingOptions",
    validator: validate_GetUpdateStemmingOptions_600618, base: "/",
    url: url_GetUpdateStemmingOptions_600619, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateStopwordOptions_600669 = ref object of OpenApiRestCall_599368
proc url_PostUpdateStopwordOptions_600671(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateStopwordOptions_600670(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600672 = query.getOrDefault("Action")
  valid_600672 = validateParameter(valid_600672, JString, required = true,
                                 default = newJString("UpdateStopwordOptions"))
  if valid_600672 != nil:
    section.add "Action", valid_600672
  var valid_600673 = query.getOrDefault("Version")
  valid_600673 = validateParameter(valid_600673, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_600673 != nil:
    section.add "Version", valid_600673
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600674 = header.getOrDefault("X-Amz-Date")
  valid_600674 = validateParameter(valid_600674, JString, required = false,
                                 default = nil)
  if valid_600674 != nil:
    section.add "X-Amz-Date", valid_600674
  var valid_600675 = header.getOrDefault("X-Amz-Security-Token")
  valid_600675 = validateParameter(valid_600675, JString, required = false,
                                 default = nil)
  if valid_600675 != nil:
    section.add "X-Amz-Security-Token", valid_600675
  var valid_600676 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600676 = validateParameter(valid_600676, JString, required = false,
                                 default = nil)
  if valid_600676 != nil:
    section.add "X-Amz-Content-Sha256", valid_600676
  var valid_600677 = header.getOrDefault("X-Amz-Algorithm")
  valid_600677 = validateParameter(valid_600677, JString, required = false,
                                 default = nil)
  if valid_600677 != nil:
    section.add "X-Amz-Algorithm", valid_600677
  var valid_600678 = header.getOrDefault("X-Amz-Signature")
  valid_600678 = validateParameter(valid_600678, JString, required = false,
                                 default = nil)
  if valid_600678 != nil:
    section.add "X-Amz-Signature", valid_600678
  var valid_600679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600679 = validateParameter(valid_600679, JString, required = false,
                                 default = nil)
  if valid_600679 != nil:
    section.add "X-Amz-SignedHeaders", valid_600679
  var valid_600680 = header.getOrDefault("X-Amz-Credential")
  valid_600680 = validateParameter(valid_600680, JString, required = false,
                                 default = nil)
  if valid_600680 != nil:
    section.add "X-Amz-Credential", valid_600680
  result.add "header", section
  ## parameters in `formData` object:
  ##   Stopwords: JString (required)
  ##            : Lists stopwords serialized as a JSON document. The document has a single object with one property "stopwords" whose value is an array of strings. The maximum size of a stopwords document is 10 KB. Example: <code>{ "stopwords": ["a", "an", "the", "of"] }</code>
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Stopwords` field"
  var valid_600681 = formData.getOrDefault("Stopwords")
  valid_600681 = validateParameter(valid_600681, JString, required = true,
                                 default = nil)
  if valid_600681 != nil:
    section.add "Stopwords", valid_600681
  var valid_600682 = formData.getOrDefault("DomainName")
  valid_600682 = validateParameter(valid_600682, JString, required = true,
                                 default = nil)
  if valid_600682 != nil:
    section.add "DomainName", valid_600682
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600683: Call_PostUpdateStopwordOptions_600669; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ## 
  let valid = call_600683.validator(path, query, header, formData, body)
  let scheme = call_600683.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600683.url(scheme.get, call_600683.host, call_600683.base,
                         call_600683.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600683, url, valid)

proc call*(call_600684: Call_PostUpdateStopwordOptions_600669; Stopwords: string;
          DomainName: string; Action: string = "UpdateStopwordOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postUpdateStopwordOptions
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ##   Stopwords: string (required)
  ##            : Lists stopwords serialized as a JSON document. The document has a single object with one property "stopwords" whose value is an array of strings. The maximum size of a stopwords document is 10 KB. Example: <code>{ "stopwords": ["a", "an", "the", "of"] }</code>
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600685 = newJObject()
  var formData_600686 = newJObject()
  add(formData_600686, "Stopwords", newJString(Stopwords))
  add(formData_600686, "DomainName", newJString(DomainName))
  add(query_600685, "Action", newJString(Action))
  add(query_600685, "Version", newJString(Version))
  result = call_600684.call(nil, query_600685, nil, formData_600686, nil)

var postUpdateStopwordOptions* = Call_PostUpdateStopwordOptions_600669(
    name: "postUpdateStopwordOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateStopwordOptions",
    validator: validate_PostUpdateStopwordOptions_600670, base: "/",
    url: url_PostUpdateStopwordOptions_600671,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateStopwordOptions_600652 = ref object of OpenApiRestCall_599368
proc url_GetUpdateStopwordOptions_600654(protocol: Scheme; host: string;
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

proc validate_GetUpdateStopwordOptions_600653(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Stopwords: JString (required)
  ##            : Lists stopwords serialized as a JSON document. The document has a single object with one property "stopwords" whose value is an array of strings. The maximum size of a stopwords document is 10 KB. Example: <code>{ "stopwords": ["a", "an", "the", "of"] }</code>
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600655 = query.getOrDefault("Action")
  valid_600655 = validateParameter(valid_600655, JString, required = true,
                                 default = newJString("UpdateStopwordOptions"))
  if valid_600655 != nil:
    section.add "Action", valid_600655
  var valid_600656 = query.getOrDefault("Stopwords")
  valid_600656 = validateParameter(valid_600656, JString, required = true,
                                 default = nil)
  if valid_600656 != nil:
    section.add "Stopwords", valid_600656
  var valid_600657 = query.getOrDefault("DomainName")
  valid_600657 = validateParameter(valid_600657, JString, required = true,
                                 default = nil)
  if valid_600657 != nil:
    section.add "DomainName", valid_600657
  var valid_600658 = query.getOrDefault("Version")
  valid_600658 = validateParameter(valid_600658, JString, required = true,
                                 default = newJString("2011-02-01"))
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600666: Call_GetUpdateStopwordOptions_600652; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ## 
  let valid = call_600666.validator(path, query, header, formData, body)
  let scheme = call_600666.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600666.url(scheme.get, call_600666.host, call_600666.base,
                         call_600666.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600666, url, valid)

proc call*(call_600667: Call_GetUpdateStopwordOptions_600652; Stopwords: string;
          DomainName: string; Action: string = "UpdateStopwordOptions";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateStopwordOptions
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ##   Action: string (required)
  ##   Stopwords: string (required)
  ##            : Lists stopwords serialized as a JSON document. The document has a single object with one property "stopwords" whose value is an array of strings. The maximum size of a stopwords document is 10 KB. Example: <code>{ "stopwords": ["a", "an", "the", "of"] }</code>
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_600668 = newJObject()
  add(query_600668, "Action", newJString(Action))
  add(query_600668, "Stopwords", newJString(Stopwords))
  add(query_600668, "DomainName", newJString(DomainName))
  add(query_600668, "Version", newJString(Version))
  result = call_600667.call(nil, query_600668, nil, nil, nil)

var getUpdateStopwordOptions* = Call_GetUpdateStopwordOptions_600652(
    name: "getUpdateStopwordOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateStopwordOptions",
    validator: validate_GetUpdateStopwordOptions_600653, base: "/",
    url: url_GetUpdateStopwordOptions_600654, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateSynonymOptions_600704 = ref object of OpenApiRestCall_599368
proc url_PostUpdateSynonymOptions_600706(protocol: Scheme; host: string;
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

proc validate_PostUpdateSynonymOptions_600705(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600707 = query.getOrDefault("Action")
  valid_600707 = validateParameter(valid_600707, JString, required = true,
                                 default = newJString("UpdateSynonymOptions"))
  if valid_600707 != nil:
    section.add "Action", valid_600707
  var valid_600708 = query.getOrDefault("Version")
  valid_600708 = validateParameter(valid_600708, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_600708 != nil:
    section.add "Version", valid_600708
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600709 = header.getOrDefault("X-Amz-Date")
  valid_600709 = validateParameter(valid_600709, JString, required = false,
                                 default = nil)
  if valid_600709 != nil:
    section.add "X-Amz-Date", valid_600709
  var valid_600710 = header.getOrDefault("X-Amz-Security-Token")
  valid_600710 = validateParameter(valid_600710, JString, required = false,
                                 default = nil)
  if valid_600710 != nil:
    section.add "X-Amz-Security-Token", valid_600710
  var valid_600711 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600711 = validateParameter(valid_600711, JString, required = false,
                                 default = nil)
  if valid_600711 != nil:
    section.add "X-Amz-Content-Sha256", valid_600711
  var valid_600712 = header.getOrDefault("X-Amz-Algorithm")
  valid_600712 = validateParameter(valid_600712, JString, required = false,
                                 default = nil)
  if valid_600712 != nil:
    section.add "X-Amz-Algorithm", valid_600712
  var valid_600713 = header.getOrDefault("X-Amz-Signature")
  valid_600713 = validateParameter(valid_600713, JString, required = false,
                                 default = nil)
  if valid_600713 != nil:
    section.add "X-Amz-Signature", valid_600713
  var valid_600714 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600714 = validateParameter(valid_600714, JString, required = false,
                                 default = nil)
  if valid_600714 != nil:
    section.add "X-Amz-SignedHeaders", valid_600714
  var valid_600715 = header.getOrDefault("X-Amz-Credential")
  valid_600715 = validateParameter(valid_600715, JString, required = false,
                                 default = nil)
  if valid_600715 != nil:
    section.add "X-Amz-Credential", valid_600715
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Synonyms: JString (required)
  ##           : Maps terms to their synonyms, serialized as a JSON document. The document has a single object with one property "synonyms" whose value is an object mapping terms to their synonyms. Each synonym is a simple string or an array of strings. The maximum size of a stopwords document is 100 KB. Example: <code>{ "synonyms": {"cat": ["feline", "kitten"], "puppy": "dog"} }</code>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_600716 = formData.getOrDefault("DomainName")
  valid_600716 = validateParameter(valid_600716, JString, required = true,
                                 default = nil)
  if valid_600716 != nil:
    section.add "DomainName", valid_600716
  var valid_600717 = formData.getOrDefault("Synonyms")
  valid_600717 = validateParameter(valid_600717, JString, required = true,
                                 default = nil)
  if valid_600717 != nil:
    section.add "Synonyms", valid_600717
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600718: Call_PostUpdateSynonymOptions_600704; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ## 
  let valid = call_600718.validator(path, query, header, formData, body)
  let scheme = call_600718.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600718.url(scheme.get, call_600718.host, call_600718.base,
                         call_600718.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600718, url, valid)

proc call*(call_600719: Call_PostUpdateSynonymOptions_600704; DomainName: string;
          Synonyms: string; Action: string = "UpdateSynonymOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postUpdateSynonymOptions
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Synonyms: string (required)
  ##           : Maps terms to their synonyms, serialized as a JSON document. The document has a single object with one property "synonyms" whose value is an object mapping terms to their synonyms. Each synonym is a simple string or an array of strings. The maximum size of a stopwords document is 100 KB. Example: <code>{ "synonyms": {"cat": ["feline", "kitten"], "puppy": "dog"} }</code>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600720 = newJObject()
  var formData_600721 = newJObject()
  add(formData_600721, "DomainName", newJString(DomainName))
  add(formData_600721, "Synonyms", newJString(Synonyms))
  add(query_600720, "Action", newJString(Action))
  add(query_600720, "Version", newJString(Version))
  result = call_600719.call(nil, query_600720, nil, formData_600721, nil)

var postUpdateSynonymOptions* = Call_PostUpdateSynonymOptions_600704(
    name: "postUpdateSynonymOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateSynonymOptions",
    validator: validate_PostUpdateSynonymOptions_600705, base: "/",
    url: url_PostUpdateSynonymOptions_600706, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateSynonymOptions_600687 = ref object of OpenApiRestCall_599368
proc url_GetUpdateSynonymOptions_600689(protocol: Scheme; host: string; base: string;
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

proc validate_GetUpdateSynonymOptions_600688(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Synonyms: JString (required)
  ##           : Maps terms to their synonyms, serialized as a JSON document. The document has a single object with one property "synonyms" whose value is an object mapping terms to their synonyms. Each synonym is a simple string or an array of strings. The maximum size of a stopwords document is 100 KB. Example: <code>{ "synonyms": {"cat": ["feline", "kitten"], "puppy": "dog"} }</code>
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600690 = query.getOrDefault("Action")
  valid_600690 = validateParameter(valid_600690, JString, required = true,
                                 default = newJString("UpdateSynonymOptions"))
  if valid_600690 != nil:
    section.add "Action", valid_600690
  var valid_600691 = query.getOrDefault("Synonyms")
  valid_600691 = validateParameter(valid_600691, JString, required = true,
                                 default = nil)
  if valid_600691 != nil:
    section.add "Synonyms", valid_600691
  var valid_600692 = query.getOrDefault("DomainName")
  valid_600692 = validateParameter(valid_600692, JString, required = true,
                                 default = nil)
  if valid_600692 != nil:
    section.add "DomainName", valid_600692
  var valid_600693 = query.getOrDefault("Version")
  valid_600693 = validateParameter(valid_600693, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_600693 != nil:
    section.add "Version", valid_600693
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600694 = header.getOrDefault("X-Amz-Date")
  valid_600694 = validateParameter(valid_600694, JString, required = false,
                                 default = nil)
  if valid_600694 != nil:
    section.add "X-Amz-Date", valid_600694
  var valid_600695 = header.getOrDefault("X-Amz-Security-Token")
  valid_600695 = validateParameter(valid_600695, JString, required = false,
                                 default = nil)
  if valid_600695 != nil:
    section.add "X-Amz-Security-Token", valid_600695
  var valid_600696 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600696 = validateParameter(valid_600696, JString, required = false,
                                 default = nil)
  if valid_600696 != nil:
    section.add "X-Amz-Content-Sha256", valid_600696
  var valid_600697 = header.getOrDefault("X-Amz-Algorithm")
  valid_600697 = validateParameter(valid_600697, JString, required = false,
                                 default = nil)
  if valid_600697 != nil:
    section.add "X-Amz-Algorithm", valid_600697
  var valid_600698 = header.getOrDefault("X-Amz-Signature")
  valid_600698 = validateParameter(valid_600698, JString, required = false,
                                 default = nil)
  if valid_600698 != nil:
    section.add "X-Amz-Signature", valid_600698
  var valid_600699 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600699 = validateParameter(valid_600699, JString, required = false,
                                 default = nil)
  if valid_600699 != nil:
    section.add "X-Amz-SignedHeaders", valid_600699
  var valid_600700 = header.getOrDefault("X-Amz-Credential")
  valid_600700 = validateParameter(valid_600700, JString, required = false,
                                 default = nil)
  if valid_600700 != nil:
    section.add "X-Amz-Credential", valid_600700
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600701: Call_GetUpdateSynonymOptions_600687; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ## 
  let valid = call_600701.validator(path, query, header, formData, body)
  let scheme = call_600701.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600701.url(scheme.get, call_600701.host, call_600701.base,
                         call_600701.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600701, url, valid)

proc call*(call_600702: Call_GetUpdateSynonymOptions_600687; Synonyms: string;
          DomainName: string; Action: string = "UpdateSynonymOptions";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateSynonymOptions
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ##   Action: string (required)
  ##   Synonyms: string (required)
  ##           : Maps terms to their synonyms, serialized as a JSON document. The document has a single object with one property "synonyms" whose value is an object mapping terms to their synonyms. Each synonym is a simple string or an array of strings. The maximum size of a stopwords document is 100 KB. Example: <code>{ "synonyms": {"cat": ["feline", "kitten"], "puppy": "dog"} }</code>
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_600703 = newJObject()
  add(query_600703, "Action", newJString(Action))
  add(query_600703, "Synonyms", newJString(Synonyms))
  add(query_600703, "DomainName", newJString(DomainName))
  add(query_600703, "Version", newJString(Version))
  result = call_600702.call(nil, query_600703, nil, nil, nil)

var getUpdateSynonymOptions* = Call_GetUpdateSynonymOptions_600687(
    name: "getUpdateSynonymOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateSynonymOptions",
    validator: validate_GetUpdateSynonymOptions_600688, base: "/",
    url: url_GetUpdateSynonymOptions_600689, schemes: {Scheme.Https, Scheme.Http})
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

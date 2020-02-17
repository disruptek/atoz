
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

  OpenApiRestCall_610658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610658): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
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
  if js == nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

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
  Call_PostCreateDomain_611267 = ref object of OpenApiRestCall_610658
proc url_PostCreateDomain_611269(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDomain_611268(path: JsonNode; query: JsonNode;
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
  var valid_611270 = query.getOrDefault("Action")
  valid_611270 = validateParameter(valid_611270, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_611270 != nil:
    section.add "Action", valid_611270
  var valid_611271 = query.getOrDefault("Version")
  valid_611271 = validateParameter(valid_611271, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_611271 != nil:
    section.add "Version", valid_611271
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
  var valid_611272 = header.getOrDefault("X-Amz-Signature")
  valid_611272 = validateParameter(valid_611272, JString, required = false,
                                 default = nil)
  if valid_611272 != nil:
    section.add "X-Amz-Signature", valid_611272
  var valid_611273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611273 = validateParameter(valid_611273, JString, required = false,
                                 default = nil)
  if valid_611273 != nil:
    section.add "X-Amz-Content-Sha256", valid_611273
  var valid_611274 = header.getOrDefault("X-Amz-Date")
  valid_611274 = validateParameter(valid_611274, JString, required = false,
                                 default = nil)
  if valid_611274 != nil:
    section.add "X-Amz-Date", valid_611274
  var valid_611275 = header.getOrDefault("X-Amz-Credential")
  valid_611275 = validateParameter(valid_611275, JString, required = false,
                                 default = nil)
  if valid_611275 != nil:
    section.add "X-Amz-Credential", valid_611275
  var valid_611276 = header.getOrDefault("X-Amz-Security-Token")
  valid_611276 = validateParameter(valid_611276, JString, required = false,
                                 default = nil)
  if valid_611276 != nil:
    section.add "X-Amz-Security-Token", valid_611276
  var valid_611277 = header.getOrDefault("X-Amz-Algorithm")
  valid_611277 = validateParameter(valid_611277, JString, required = false,
                                 default = nil)
  if valid_611277 != nil:
    section.add "X-Amz-Algorithm", valid_611277
  var valid_611278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611278 = validateParameter(valid_611278, JString, required = false,
                                 default = nil)
  if valid_611278 != nil:
    section.add "X-Amz-SignedHeaders", valid_611278
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_611279 = formData.getOrDefault("DomainName")
  valid_611279 = validateParameter(valid_611279, JString, required = true,
                                 default = nil)
  if valid_611279 != nil:
    section.add "DomainName", valid_611279
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611280: Call_PostCreateDomain_611267; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new search domain.
  ## 
  let valid = call_611280.validator(path, query, header, formData, body)
  let scheme = call_611280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611280.url(scheme.get, call_611280.host, call_611280.base,
                         call_611280.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611280, url, valid)

proc call*(call_611281: Call_PostCreateDomain_611267; DomainName: string;
          Action: string = "CreateDomain"; Version: string = "2011-02-01"): Recallable =
  ## postCreateDomain
  ## Creates a new search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611282 = newJObject()
  var formData_611283 = newJObject()
  add(formData_611283, "DomainName", newJString(DomainName))
  add(query_611282, "Action", newJString(Action))
  add(query_611282, "Version", newJString(Version))
  result = call_611281.call(nil, query_611282, nil, formData_611283, nil)

var postCreateDomain* = Call_PostCreateDomain_611267(name: "postCreateDomain",
    meth: HttpMethod.HttpPost, host: "cloudsearch.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_PostCreateDomain_611268,
    base: "/", url: url_PostCreateDomain_611269,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDomain_610996 = ref object of OpenApiRestCall_610658
proc url_GetCreateDomain_610998(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDomain_610997(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Creates a new search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_611110 = query.getOrDefault("DomainName")
  valid_611110 = validateParameter(valid_611110, JString, required = true,
                                 default = nil)
  if valid_611110 != nil:
    section.add "DomainName", valid_611110
  var valid_611124 = query.getOrDefault("Action")
  valid_611124 = validateParameter(valid_611124, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_611124 != nil:
    section.add "Action", valid_611124
  var valid_611125 = query.getOrDefault("Version")
  valid_611125 = validateParameter(valid_611125, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_611125 != nil:
    section.add "Version", valid_611125
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
  var valid_611126 = header.getOrDefault("X-Amz-Signature")
  valid_611126 = validateParameter(valid_611126, JString, required = false,
                                 default = nil)
  if valid_611126 != nil:
    section.add "X-Amz-Signature", valid_611126
  var valid_611127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611127 = validateParameter(valid_611127, JString, required = false,
                                 default = nil)
  if valid_611127 != nil:
    section.add "X-Amz-Content-Sha256", valid_611127
  var valid_611128 = header.getOrDefault("X-Amz-Date")
  valid_611128 = validateParameter(valid_611128, JString, required = false,
                                 default = nil)
  if valid_611128 != nil:
    section.add "X-Amz-Date", valid_611128
  var valid_611129 = header.getOrDefault("X-Amz-Credential")
  valid_611129 = validateParameter(valid_611129, JString, required = false,
                                 default = nil)
  if valid_611129 != nil:
    section.add "X-Amz-Credential", valid_611129
  var valid_611130 = header.getOrDefault("X-Amz-Security-Token")
  valid_611130 = validateParameter(valid_611130, JString, required = false,
                                 default = nil)
  if valid_611130 != nil:
    section.add "X-Amz-Security-Token", valid_611130
  var valid_611131 = header.getOrDefault("X-Amz-Algorithm")
  valid_611131 = validateParameter(valid_611131, JString, required = false,
                                 default = nil)
  if valid_611131 != nil:
    section.add "X-Amz-Algorithm", valid_611131
  var valid_611132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611132 = validateParameter(valid_611132, JString, required = false,
                                 default = nil)
  if valid_611132 != nil:
    section.add "X-Amz-SignedHeaders", valid_611132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611155: Call_GetCreateDomain_610996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new search domain.
  ## 
  let valid = call_611155.validator(path, query, header, formData, body)
  let scheme = call_611155.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611155.url(scheme.get, call_611155.host, call_611155.base,
                         call_611155.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611155, url, valid)

proc call*(call_611226: Call_GetCreateDomain_610996; DomainName: string;
          Action: string = "CreateDomain"; Version: string = "2011-02-01"): Recallable =
  ## getCreateDomain
  ## Creates a new search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611227 = newJObject()
  add(query_611227, "DomainName", newJString(DomainName))
  add(query_611227, "Action", newJString(Action))
  add(query_611227, "Version", newJString(Version))
  result = call_611226.call(nil, query_611227, nil, nil, nil)

var getCreateDomain* = Call_GetCreateDomain_610996(name: "getCreateDomain",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_GetCreateDomain_610997,
    base: "/", url: url_GetCreateDomain_610998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineIndexField_611306 = ref object of OpenApiRestCall_610658
proc url_PostDefineIndexField_611308(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDefineIndexField_611307(path: JsonNode; query: JsonNode;
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
  var valid_611309 = query.getOrDefault("Action")
  valid_611309 = validateParameter(valid_611309, JString, required = true,
                                 default = newJString("DefineIndexField"))
  if valid_611309 != nil:
    section.add "Action", valid_611309
  var valid_611310 = query.getOrDefault("Version")
  valid_611310 = validateParameter(valid_611310, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_611310 != nil:
    section.add "Version", valid_611310
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
  var valid_611311 = header.getOrDefault("X-Amz-Signature")
  valid_611311 = validateParameter(valid_611311, JString, required = false,
                                 default = nil)
  if valid_611311 != nil:
    section.add "X-Amz-Signature", valid_611311
  var valid_611312 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611312 = validateParameter(valid_611312, JString, required = false,
                                 default = nil)
  if valid_611312 != nil:
    section.add "X-Amz-Content-Sha256", valid_611312
  var valid_611313 = header.getOrDefault("X-Amz-Date")
  valid_611313 = validateParameter(valid_611313, JString, required = false,
                                 default = nil)
  if valid_611313 != nil:
    section.add "X-Amz-Date", valid_611313
  var valid_611314 = header.getOrDefault("X-Amz-Credential")
  valid_611314 = validateParameter(valid_611314, JString, required = false,
                                 default = nil)
  if valid_611314 != nil:
    section.add "X-Amz-Credential", valid_611314
  var valid_611315 = header.getOrDefault("X-Amz-Security-Token")
  valid_611315 = validateParameter(valid_611315, JString, required = false,
                                 default = nil)
  if valid_611315 != nil:
    section.add "X-Amz-Security-Token", valid_611315
  var valid_611316 = header.getOrDefault("X-Amz-Algorithm")
  valid_611316 = validateParameter(valid_611316, JString, required = false,
                                 default = nil)
  if valid_611316 != nil:
    section.add "X-Amz-Algorithm", valid_611316
  var valid_611317 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611317 = validateParameter(valid_611317, JString, required = false,
                                 default = nil)
  if valid_611317 != nil:
    section.add "X-Amz-SignedHeaders", valid_611317
  result.add "header", section
  ## parameters in `formData` object:
  ##   IndexField.UIntOptions: JString
  ##                         : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for an unsigned integer field. Present if <code>IndexFieldType</code> specifies the field is of type unsigned integer.
  ##   IndexField.SourceAttributes: JArray
  ##                              : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## An optional list of source attributes that provide data for this index field. If not specified, the data is pulled from a source attribute with the same name as this <code>IndexField</code>. When one or more source attributes are specified, an optional data transformation can be applied to the source data when populating the index field. You can configure a maximum of 20 sources for an <code>IndexField</code>.
  ##   IndexField.IndexFieldType: JString
  ##                            : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The type of field. Based on this type, exactly one of the <a>UIntOptions</a>, <a>LiteralOptions</a> or <a>TextOptions</a> must be present.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   IndexField.TextOptions: JString
  ##                         : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for text field. Present if <code>IndexFieldType</code> specifies the field is of type text.
  ##   IndexField.LiteralOptions: JString
  ##                            : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for literal field. Present if <code>IndexFieldType</code> specifies the field is of type literal.
  ##   IndexField.IndexFieldName: JString
  ##                            : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The name of a field in the search index. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  section = newJObject()
  var valid_611318 = formData.getOrDefault("IndexField.UIntOptions")
  valid_611318 = validateParameter(valid_611318, JString, required = false,
                                 default = nil)
  if valid_611318 != nil:
    section.add "IndexField.UIntOptions", valid_611318
  var valid_611319 = formData.getOrDefault("IndexField.SourceAttributes")
  valid_611319 = validateParameter(valid_611319, JArray, required = false,
                                 default = nil)
  if valid_611319 != nil:
    section.add "IndexField.SourceAttributes", valid_611319
  var valid_611320 = formData.getOrDefault("IndexField.IndexFieldType")
  valid_611320 = validateParameter(valid_611320, JString, required = false,
                                 default = nil)
  if valid_611320 != nil:
    section.add "IndexField.IndexFieldType", valid_611320
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_611321 = formData.getOrDefault("DomainName")
  valid_611321 = validateParameter(valid_611321, JString, required = true,
                                 default = nil)
  if valid_611321 != nil:
    section.add "DomainName", valid_611321
  var valid_611322 = formData.getOrDefault("IndexField.TextOptions")
  valid_611322 = validateParameter(valid_611322, JString, required = false,
                                 default = nil)
  if valid_611322 != nil:
    section.add "IndexField.TextOptions", valid_611322
  var valid_611323 = formData.getOrDefault("IndexField.LiteralOptions")
  valid_611323 = validateParameter(valid_611323, JString, required = false,
                                 default = nil)
  if valid_611323 != nil:
    section.add "IndexField.LiteralOptions", valid_611323
  var valid_611324 = formData.getOrDefault("IndexField.IndexFieldName")
  valid_611324 = validateParameter(valid_611324, JString, required = false,
                                 default = nil)
  if valid_611324 != nil:
    section.add "IndexField.IndexFieldName", valid_611324
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611325: Call_PostDefineIndexField_611306; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ## 
  let valid = call_611325.validator(path, query, header, formData, body)
  let scheme = call_611325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611325.url(scheme.get, call_611325.host, call_611325.base,
                         call_611325.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611325, url, valid)

proc call*(call_611326: Call_PostDefineIndexField_611306; DomainName: string;
          IndexFieldUIntOptions: string = "";
          IndexFieldSourceAttributes: JsonNode = nil;
          IndexFieldIndexFieldType: string = ""; IndexFieldTextOptions: string = "";
          IndexFieldLiteralOptions: string = "";
          Action: string = "DefineIndexField";
          IndexFieldIndexFieldName: string = ""; Version: string = "2011-02-01"): Recallable =
  ## postDefineIndexField
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ##   IndexFieldUIntOptions: string
  ##                        : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for an unsigned integer field. Present if <code>IndexFieldType</code> specifies the field is of type unsigned integer.
  ##   IndexFieldSourceAttributes: JArray
  ##                             : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## An optional list of source attributes that provide data for this index field. If not specified, the data is pulled from a source attribute with the same name as this <code>IndexField</code>. When one or more source attributes are specified, an optional data transformation can be applied to the source data when populating the index field. You can configure a maximum of 20 sources for an <code>IndexField</code>.
  ##   IndexFieldIndexFieldType: string
  ##                           : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The type of field. Based on this type, exactly one of the <a>UIntOptions</a>, <a>LiteralOptions</a> or <a>TextOptions</a> must be present.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   IndexFieldTextOptions: string
  ##                        : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for text field. Present if <code>IndexFieldType</code> specifies the field is of type text.
  ##   IndexFieldLiteralOptions: string
  ##                           : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for literal field. Present if <code>IndexFieldType</code> specifies the field is of type literal.
  ##   Action: string (required)
  ##   IndexFieldIndexFieldName: string
  ##                           : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The name of a field in the search index. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Version: string (required)
  var query_611327 = newJObject()
  var formData_611328 = newJObject()
  add(formData_611328, "IndexField.UIntOptions", newJString(IndexFieldUIntOptions))
  if IndexFieldSourceAttributes != nil:
    formData_611328.add "IndexField.SourceAttributes", IndexFieldSourceAttributes
  add(formData_611328, "IndexField.IndexFieldType",
      newJString(IndexFieldIndexFieldType))
  add(formData_611328, "DomainName", newJString(DomainName))
  add(formData_611328, "IndexField.TextOptions", newJString(IndexFieldTextOptions))
  add(formData_611328, "IndexField.LiteralOptions",
      newJString(IndexFieldLiteralOptions))
  add(query_611327, "Action", newJString(Action))
  add(formData_611328, "IndexField.IndexFieldName",
      newJString(IndexFieldIndexFieldName))
  add(query_611327, "Version", newJString(Version))
  result = call_611326.call(nil, query_611327, nil, formData_611328, nil)

var postDefineIndexField* = Call_PostDefineIndexField_611306(
    name: "postDefineIndexField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineIndexField",
    validator: validate_PostDefineIndexField_611307, base: "/",
    url: url_PostDefineIndexField_611308, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineIndexField_611284 = ref object of OpenApiRestCall_610658
proc url_GetDefineIndexField_611286(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDefineIndexField_611285(path: JsonNode; query: JsonNode;
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
  ##   IndexField.IndexFieldType: JString
  ##                            : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The type of field. Based on this type, exactly one of the <a>UIntOptions</a>, <a>LiteralOptions</a> or <a>TextOptions</a> must be present.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   IndexField.IndexFieldName: JString
  ##                            : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The name of a field in the search index. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   IndexField.UIntOptions: JString
  ##                         : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for an unsigned integer field. Present if <code>IndexFieldType</code> specifies the field is of type unsigned integer.
  ##   IndexField.SourceAttributes: JArray
  ##                              : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## An optional list of source attributes that provide data for this index field. If not specified, the data is pulled from a source attribute with the same name as this <code>IndexField</code>. When one or more source attributes are specified, an optional data transformation can be applied to the source data when populating the index field. You can configure a maximum of 20 sources for an <code>IndexField</code>.
  ##   Action: JString (required)
  ##   IndexField.LiteralOptions: JString
  ##                            : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for literal field. Present if <code>IndexFieldType</code> specifies the field is of type literal.
  ##   Version: JString (required)
  section = newJObject()
  var valid_611287 = query.getOrDefault("IndexField.TextOptions")
  valid_611287 = validateParameter(valid_611287, JString, required = false,
                                 default = nil)
  if valid_611287 != nil:
    section.add "IndexField.TextOptions", valid_611287
  var valid_611288 = query.getOrDefault("IndexField.IndexFieldType")
  valid_611288 = validateParameter(valid_611288, JString, required = false,
                                 default = nil)
  if valid_611288 != nil:
    section.add "IndexField.IndexFieldType", valid_611288
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_611289 = query.getOrDefault("DomainName")
  valid_611289 = validateParameter(valid_611289, JString, required = true,
                                 default = nil)
  if valid_611289 != nil:
    section.add "DomainName", valid_611289
  var valid_611290 = query.getOrDefault("IndexField.IndexFieldName")
  valid_611290 = validateParameter(valid_611290, JString, required = false,
                                 default = nil)
  if valid_611290 != nil:
    section.add "IndexField.IndexFieldName", valid_611290
  var valid_611291 = query.getOrDefault("IndexField.UIntOptions")
  valid_611291 = validateParameter(valid_611291, JString, required = false,
                                 default = nil)
  if valid_611291 != nil:
    section.add "IndexField.UIntOptions", valid_611291
  var valid_611292 = query.getOrDefault("IndexField.SourceAttributes")
  valid_611292 = validateParameter(valid_611292, JArray, required = false,
                                 default = nil)
  if valid_611292 != nil:
    section.add "IndexField.SourceAttributes", valid_611292
  var valid_611293 = query.getOrDefault("Action")
  valid_611293 = validateParameter(valid_611293, JString, required = true,
                                 default = newJString("DefineIndexField"))
  if valid_611293 != nil:
    section.add "Action", valid_611293
  var valid_611294 = query.getOrDefault("IndexField.LiteralOptions")
  valid_611294 = validateParameter(valid_611294, JString, required = false,
                                 default = nil)
  if valid_611294 != nil:
    section.add "IndexField.LiteralOptions", valid_611294
  var valid_611295 = query.getOrDefault("Version")
  valid_611295 = validateParameter(valid_611295, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_611295 != nil:
    section.add "Version", valid_611295
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
  var valid_611296 = header.getOrDefault("X-Amz-Signature")
  valid_611296 = validateParameter(valid_611296, JString, required = false,
                                 default = nil)
  if valid_611296 != nil:
    section.add "X-Amz-Signature", valid_611296
  var valid_611297 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611297 = validateParameter(valid_611297, JString, required = false,
                                 default = nil)
  if valid_611297 != nil:
    section.add "X-Amz-Content-Sha256", valid_611297
  var valid_611298 = header.getOrDefault("X-Amz-Date")
  valid_611298 = validateParameter(valid_611298, JString, required = false,
                                 default = nil)
  if valid_611298 != nil:
    section.add "X-Amz-Date", valid_611298
  var valid_611299 = header.getOrDefault("X-Amz-Credential")
  valid_611299 = validateParameter(valid_611299, JString, required = false,
                                 default = nil)
  if valid_611299 != nil:
    section.add "X-Amz-Credential", valid_611299
  var valid_611300 = header.getOrDefault("X-Amz-Security-Token")
  valid_611300 = validateParameter(valid_611300, JString, required = false,
                                 default = nil)
  if valid_611300 != nil:
    section.add "X-Amz-Security-Token", valid_611300
  var valid_611301 = header.getOrDefault("X-Amz-Algorithm")
  valid_611301 = validateParameter(valid_611301, JString, required = false,
                                 default = nil)
  if valid_611301 != nil:
    section.add "X-Amz-Algorithm", valid_611301
  var valid_611302 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611302 = validateParameter(valid_611302, JString, required = false,
                                 default = nil)
  if valid_611302 != nil:
    section.add "X-Amz-SignedHeaders", valid_611302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611303: Call_GetDefineIndexField_611284; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ## 
  let valid = call_611303.validator(path, query, header, formData, body)
  let scheme = call_611303.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611303.url(scheme.get, call_611303.host, call_611303.base,
                         call_611303.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611303, url, valid)

proc call*(call_611304: Call_GetDefineIndexField_611284; DomainName: string;
          IndexFieldTextOptions: string = ""; IndexFieldIndexFieldType: string = "";
          IndexFieldIndexFieldName: string = ""; IndexFieldUIntOptions: string = "";
          IndexFieldSourceAttributes: JsonNode = nil;
          Action: string = "DefineIndexField";
          IndexFieldLiteralOptions: string = ""; Version: string = "2011-02-01"): Recallable =
  ## getDefineIndexField
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ##   IndexFieldTextOptions: string
  ##                        : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for text field. Present if <code>IndexFieldType</code> specifies the field is of type text.
  ##   IndexFieldIndexFieldType: string
  ##                           : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The type of field. Based on this type, exactly one of the <a>UIntOptions</a>, <a>LiteralOptions</a> or <a>TextOptions</a> must be present.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   IndexFieldIndexFieldName: string
  ##                           : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The name of a field in the search index. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   IndexFieldUIntOptions: string
  ##                        : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for an unsigned integer field. Present if <code>IndexFieldType</code> specifies the field is of type unsigned integer.
  ##   IndexFieldSourceAttributes: JArray
  ##                             : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## An optional list of source attributes that provide data for this index field. If not specified, the data is pulled from a source attribute with the same name as this <code>IndexField</code>. When one or more source attributes are specified, an optional data transformation can be applied to the source data when populating the index field. You can configure a maximum of 20 sources for an <code>IndexField</code>.
  ##   Action: string (required)
  ##   IndexFieldLiteralOptions: string
  ##                           : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for literal field. Present if <code>IndexFieldType</code> specifies the field is of type literal.
  ##   Version: string (required)
  var query_611305 = newJObject()
  add(query_611305, "IndexField.TextOptions", newJString(IndexFieldTextOptions))
  add(query_611305, "IndexField.IndexFieldType",
      newJString(IndexFieldIndexFieldType))
  add(query_611305, "DomainName", newJString(DomainName))
  add(query_611305, "IndexField.IndexFieldName",
      newJString(IndexFieldIndexFieldName))
  add(query_611305, "IndexField.UIntOptions", newJString(IndexFieldUIntOptions))
  if IndexFieldSourceAttributes != nil:
    query_611305.add "IndexField.SourceAttributes", IndexFieldSourceAttributes
  add(query_611305, "Action", newJString(Action))
  add(query_611305, "IndexField.LiteralOptions",
      newJString(IndexFieldLiteralOptions))
  add(query_611305, "Version", newJString(Version))
  result = call_611304.call(nil, query_611305, nil, nil, nil)

var getDefineIndexField* = Call_GetDefineIndexField_611284(
    name: "getDefineIndexField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineIndexField",
    validator: validate_GetDefineIndexField_611285, base: "/",
    url: url_GetDefineIndexField_611286, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineRankExpression_611347 = ref object of OpenApiRestCall_610658
proc url_PostDefineRankExpression_611349(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDefineRankExpression_611348(path: JsonNode; query: JsonNode;
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
  var valid_611350 = query.getOrDefault("Action")
  valid_611350 = validateParameter(valid_611350, JString, required = true,
                                 default = newJString("DefineRankExpression"))
  if valid_611350 != nil:
    section.add "Action", valid_611350
  var valid_611351 = query.getOrDefault("Version")
  valid_611351 = validateParameter(valid_611351, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_611351 != nil:
    section.add "Version", valid_611351
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
  var valid_611352 = header.getOrDefault("X-Amz-Signature")
  valid_611352 = validateParameter(valid_611352, JString, required = false,
                                 default = nil)
  if valid_611352 != nil:
    section.add "X-Amz-Signature", valid_611352
  var valid_611353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611353 = validateParameter(valid_611353, JString, required = false,
                                 default = nil)
  if valid_611353 != nil:
    section.add "X-Amz-Content-Sha256", valid_611353
  var valid_611354 = header.getOrDefault("X-Amz-Date")
  valid_611354 = validateParameter(valid_611354, JString, required = false,
                                 default = nil)
  if valid_611354 != nil:
    section.add "X-Amz-Date", valid_611354
  var valid_611355 = header.getOrDefault("X-Amz-Credential")
  valid_611355 = validateParameter(valid_611355, JString, required = false,
                                 default = nil)
  if valid_611355 != nil:
    section.add "X-Amz-Credential", valid_611355
  var valid_611356 = header.getOrDefault("X-Amz-Security-Token")
  valid_611356 = validateParameter(valid_611356, JString, required = false,
                                 default = nil)
  if valid_611356 != nil:
    section.add "X-Amz-Security-Token", valid_611356
  var valid_611357 = header.getOrDefault("X-Amz-Algorithm")
  valid_611357 = validateParameter(valid_611357, JString, required = false,
                                 default = nil)
  if valid_611357 != nil:
    section.add "X-Amz-Algorithm", valid_611357
  var valid_611358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611358 = validateParameter(valid_611358, JString, required = false,
                                 default = nil)
  if valid_611358 != nil:
    section.add "X-Amz-SignedHeaders", valid_611358
  result.add "header", section
  ## parameters in `formData` object:
  ##   RankExpression.RankName: JString
  ##                          : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## The name of a rank expression. Rank expression names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   RankExpression.RankExpression: JString
  ##                                : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## <p>The expression to evaluate for ranking or thresholding while processing a search request. The <code>RankExpression</code> syntax is based on JavaScript expressions and supports:</p> <ul> <li>Integer, floating point, hex and octal literals</li> <li>Shortcut evaluation of logical operators such that an expression <code>a || b</code> evaluates to the value <code>a</code>, if <code>a</code> is true, without evaluating <code>b</code> at all</li> <li>JavaScript order of precedence for operators</li> <li>Arithmetic operators: <code>+ - * / %</code> </li> <li>Boolean operators (including the ternary operator)</li> <li>Bitwise operators</li> <li>Comparison operators</li> <li>Common mathematic functions: <code>abs ceil erf exp floor lgamma ln log2 log10 max min sqrt pow</code> </li> <li>Trigonometric library functions: <code>acosh acos asinh asin atanh atan cosh cos sinh sin tanh tan</code> </li> <li>Random generation of a number between 0 and 1: <code>rand</code> </li> <li>Current time in epoch: <code>time</code> </li> <li>The <code>min max</code> functions that operate on a variable argument list</li> </ul> <p>Intermediate results are calculated as double precision floating point values. The final return value of a <code>RankExpression</code> is automatically converted from floating point to a 32-bit unsigned integer by rounding to the nearest integer, with a natural floor of 0 and a ceiling of max(uint32_t), 4294967295. Mathematical errors such as dividing by 0 will fail during evaluation and return a value of 0.</p> <p>The source data for a <code>RankExpression</code> can be the name of an <code>IndexField</code> of type uint, another <code>RankExpression</code> or the reserved name <i>text_relevance</i>. The text_relevance source is defined to return an integer from 0 to 1000 (inclusive) to indicate how relevant a document is to the search request, taking into account repetition of search terms in the document and proximity of search terms to each other in each matching <code>IndexField</code> in the document.</p> <p>For more information about using rank expressions to customize ranking, see the Amazon CloudSearch Developer Guide.</p>
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  var valid_611359 = formData.getOrDefault("RankExpression.RankName")
  valid_611359 = validateParameter(valid_611359, JString, required = false,
                                 default = nil)
  if valid_611359 != nil:
    section.add "RankExpression.RankName", valid_611359
  var valid_611360 = formData.getOrDefault("RankExpression.RankExpression")
  valid_611360 = validateParameter(valid_611360, JString, required = false,
                                 default = nil)
  if valid_611360 != nil:
    section.add "RankExpression.RankExpression", valid_611360
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_611361 = formData.getOrDefault("DomainName")
  valid_611361 = validateParameter(valid_611361, JString, required = true,
                                 default = nil)
  if valid_611361 != nil:
    section.add "DomainName", valid_611361
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611362: Call_PostDefineRankExpression_611347; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ## 
  let valid = call_611362.validator(path, query, header, formData, body)
  let scheme = call_611362.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611362.url(scheme.get, call_611362.host, call_611362.base,
                         call_611362.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611362, url, valid)

proc call*(call_611363: Call_PostDefineRankExpression_611347; DomainName: string;
          RankExpressionRankName: string = "";
          RankExpressionRankExpression: string = "";
          Action: string = "DefineRankExpression"; Version: string = "2011-02-01"): Recallable =
  ## postDefineRankExpression
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ##   RankExpressionRankName: string
  ##                         : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## The name of a rank expression. Rank expression names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   RankExpressionRankExpression: string
  ##                               : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## <p>The expression to evaluate for ranking or thresholding while processing a search request. The <code>RankExpression</code> syntax is based on JavaScript expressions and supports:</p> <ul> <li>Integer, floating point, hex and octal literals</li> <li>Shortcut evaluation of logical operators such that an expression <code>a || b</code> evaluates to the value <code>a</code>, if <code>a</code> is true, without evaluating <code>b</code> at all</li> <li>JavaScript order of precedence for operators</li> <li>Arithmetic operators: <code>+ - * / %</code> </li> <li>Boolean operators (including the ternary operator)</li> <li>Bitwise operators</li> <li>Comparison operators</li> <li>Common mathematic functions: <code>abs ceil erf exp floor lgamma ln log2 log10 max min sqrt pow</code> </li> <li>Trigonometric library functions: <code>acosh acos asinh asin atanh atan cosh cos sinh sin tanh tan</code> </li> <li>Random generation of a number between 0 and 1: <code>rand</code> </li> <li>Current time in epoch: <code>time</code> </li> <li>The <code>min max</code> functions that operate on a variable argument list</li> </ul> <p>Intermediate results are calculated as double precision floating point values. The final return value of a <code>RankExpression</code> is automatically converted from floating point to a 32-bit unsigned integer by rounding to the nearest integer, with a natural floor of 0 and a ceiling of max(uint32_t), 4294967295. Mathematical errors such as dividing by 0 will fail during evaluation and return a value of 0.</p> <p>The source data for a <code>RankExpression</code> can be the name of an <code>IndexField</code> of type uint, another <code>RankExpression</code> or the reserved name <i>text_relevance</i>. The text_relevance source is defined to return an integer from 0 to 1000 (inclusive) to indicate how relevant a document is to the search request, taking into account repetition of search terms in the document and proximity of search terms to each other in each matching <code>IndexField</code> in the document.</p> <p>For more information about using rank expressions to customize ranking, see the Amazon CloudSearch Developer Guide.</p>
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611364 = newJObject()
  var formData_611365 = newJObject()
  add(formData_611365, "RankExpression.RankName",
      newJString(RankExpressionRankName))
  add(formData_611365, "RankExpression.RankExpression",
      newJString(RankExpressionRankExpression))
  add(formData_611365, "DomainName", newJString(DomainName))
  add(query_611364, "Action", newJString(Action))
  add(query_611364, "Version", newJString(Version))
  result = call_611363.call(nil, query_611364, nil, formData_611365, nil)

var postDefineRankExpression* = Call_PostDefineRankExpression_611347(
    name: "postDefineRankExpression", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineRankExpression",
    validator: validate_PostDefineRankExpression_611348, base: "/",
    url: url_PostDefineRankExpression_611349, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineRankExpression_611329 = ref object of OpenApiRestCall_610658
proc url_GetDefineRankExpression_611331(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDefineRankExpression_611330(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   RankExpression.RankName: JString
  ##                          : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## The name of a rank expression. Rank expression names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   RankExpression.RankExpression: JString
  ##                                : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## <p>The expression to evaluate for ranking or thresholding while processing a search request. The <code>RankExpression</code> syntax is based on JavaScript expressions and supports:</p> <ul> <li>Integer, floating point, hex and octal literals</li> <li>Shortcut evaluation of logical operators such that an expression <code>a || b</code> evaluates to the value <code>a</code>, if <code>a</code> is true, without evaluating <code>b</code> at all</li> <li>JavaScript order of precedence for operators</li> <li>Arithmetic operators: <code>+ - * / %</code> </li> <li>Boolean operators (including the ternary operator)</li> <li>Bitwise operators</li> <li>Comparison operators</li> <li>Common mathematic functions: <code>abs ceil erf exp floor lgamma ln log2 log10 max min sqrt pow</code> </li> <li>Trigonometric library functions: <code>acosh acos asinh asin atanh atan cosh cos sinh sin tanh tan</code> </li> <li>Random generation of a number between 0 and 1: <code>rand</code> </li> <li>Current time in epoch: <code>time</code> </li> <li>The <code>min max</code> functions that operate on a variable argument list</li> </ul> <p>Intermediate results are calculated as double precision floating point values. The final return value of a <code>RankExpression</code> is automatically converted from floating point to a 32-bit unsigned integer by rounding to the nearest integer, with a natural floor of 0 and a ceiling of max(uint32_t), 4294967295. Mathematical errors such as dividing by 0 will fail during evaluation and return a value of 0.</p> <p>The source data for a <code>RankExpression</code> can be the name of an <code>IndexField</code> of type uint, another <code>RankExpression</code> or the reserved name <i>text_relevance</i>. The text_relevance source is defined to return an integer from 0 to 1000 (inclusive) to indicate how relevant a document is to the search request, taking into account repetition of search terms in the document and proximity of search terms to each other in each matching <code>IndexField</code> in the document.</p> <p>For more information about using rank expressions to customize ranking, see the Amazon CloudSearch Developer Guide.</p>
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_611332 = query.getOrDefault("DomainName")
  valid_611332 = validateParameter(valid_611332, JString, required = true,
                                 default = nil)
  if valid_611332 != nil:
    section.add "DomainName", valid_611332
  var valid_611333 = query.getOrDefault("Action")
  valid_611333 = validateParameter(valid_611333, JString, required = true,
                                 default = newJString("DefineRankExpression"))
  if valid_611333 != nil:
    section.add "Action", valid_611333
  var valid_611334 = query.getOrDefault("Version")
  valid_611334 = validateParameter(valid_611334, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_611334 != nil:
    section.add "Version", valid_611334
  var valid_611335 = query.getOrDefault("RankExpression.RankName")
  valid_611335 = validateParameter(valid_611335, JString, required = false,
                                 default = nil)
  if valid_611335 != nil:
    section.add "RankExpression.RankName", valid_611335
  var valid_611336 = query.getOrDefault("RankExpression.RankExpression")
  valid_611336 = validateParameter(valid_611336, JString, required = false,
                                 default = nil)
  if valid_611336 != nil:
    section.add "RankExpression.RankExpression", valid_611336
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
  var valid_611337 = header.getOrDefault("X-Amz-Signature")
  valid_611337 = validateParameter(valid_611337, JString, required = false,
                                 default = nil)
  if valid_611337 != nil:
    section.add "X-Amz-Signature", valid_611337
  var valid_611338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611338 = validateParameter(valid_611338, JString, required = false,
                                 default = nil)
  if valid_611338 != nil:
    section.add "X-Amz-Content-Sha256", valid_611338
  var valid_611339 = header.getOrDefault("X-Amz-Date")
  valid_611339 = validateParameter(valid_611339, JString, required = false,
                                 default = nil)
  if valid_611339 != nil:
    section.add "X-Amz-Date", valid_611339
  var valid_611340 = header.getOrDefault("X-Amz-Credential")
  valid_611340 = validateParameter(valid_611340, JString, required = false,
                                 default = nil)
  if valid_611340 != nil:
    section.add "X-Amz-Credential", valid_611340
  var valid_611341 = header.getOrDefault("X-Amz-Security-Token")
  valid_611341 = validateParameter(valid_611341, JString, required = false,
                                 default = nil)
  if valid_611341 != nil:
    section.add "X-Amz-Security-Token", valid_611341
  var valid_611342 = header.getOrDefault("X-Amz-Algorithm")
  valid_611342 = validateParameter(valid_611342, JString, required = false,
                                 default = nil)
  if valid_611342 != nil:
    section.add "X-Amz-Algorithm", valid_611342
  var valid_611343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611343 = validateParameter(valid_611343, JString, required = false,
                                 default = nil)
  if valid_611343 != nil:
    section.add "X-Amz-SignedHeaders", valid_611343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611344: Call_GetDefineRankExpression_611329; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ## 
  let valid = call_611344.validator(path, query, header, formData, body)
  let scheme = call_611344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611344.url(scheme.get, call_611344.host, call_611344.base,
                         call_611344.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611344, url, valid)

proc call*(call_611345: Call_GetDefineRankExpression_611329; DomainName: string;
          Action: string = "DefineRankExpression"; Version: string = "2011-02-01";
          RankExpressionRankName: string = "";
          RankExpressionRankExpression: string = ""): Recallable =
  ## getDefineRankExpression
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   RankExpressionRankName: string
  ##                         : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## The name of a rank expression. Rank expression names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   RankExpressionRankExpression: string
  ##                               : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## <p>The expression to evaluate for ranking or thresholding while processing a search request. The <code>RankExpression</code> syntax is based on JavaScript expressions and supports:</p> <ul> <li>Integer, floating point, hex and octal literals</li> <li>Shortcut evaluation of logical operators such that an expression <code>a || b</code> evaluates to the value <code>a</code>, if <code>a</code> is true, without evaluating <code>b</code> at all</li> <li>JavaScript order of precedence for operators</li> <li>Arithmetic operators: <code>+ - * / %</code> </li> <li>Boolean operators (including the ternary operator)</li> <li>Bitwise operators</li> <li>Comparison operators</li> <li>Common mathematic functions: <code>abs ceil erf exp floor lgamma ln log2 log10 max min sqrt pow</code> </li> <li>Trigonometric library functions: <code>acosh acos asinh asin atanh atan cosh cos sinh sin tanh tan</code> </li> <li>Random generation of a number between 0 and 1: <code>rand</code> </li> <li>Current time in epoch: <code>time</code> </li> <li>The <code>min max</code> functions that operate on a variable argument list</li> </ul> <p>Intermediate results are calculated as double precision floating point values. The final return value of a <code>RankExpression</code> is automatically converted from floating point to a 32-bit unsigned integer by rounding to the nearest integer, with a natural floor of 0 and a ceiling of max(uint32_t), 4294967295. Mathematical errors such as dividing by 0 will fail during evaluation and return a value of 0.</p> <p>The source data for a <code>RankExpression</code> can be the name of an <code>IndexField</code> of type uint, another <code>RankExpression</code> or the reserved name <i>text_relevance</i>. The text_relevance source is defined to return an integer from 0 to 1000 (inclusive) to indicate how relevant a document is to the search request, taking into account repetition of search terms in the document and proximity of search terms to each other in each matching <code>IndexField</code> in the document.</p> <p>For more information about using rank expressions to customize ranking, see the Amazon CloudSearch Developer Guide.</p>
  var query_611346 = newJObject()
  add(query_611346, "DomainName", newJString(DomainName))
  add(query_611346, "Action", newJString(Action))
  add(query_611346, "Version", newJString(Version))
  add(query_611346, "RankExpression.RankName", newJString(RankExpressionRankName))
  add(query_611346, "RankExpression.RankExpression",
      newJString(RankExpressionRankExpression))
  result = call_611345.call(nil, query_611346, nil, nil, nil)

var getDefineRankExpression* = Call_GetDefineRankExpression_611329(
    name: "getDefineRankExpression", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineRankExpression",
    validator: validate_GetDefineRankExpression_611330, base: "/",
    url: url_GetDefineRankExpression_611331, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDomain_611382 = ref object of OpenApiRestCall_610658
proc url_PostDeleteDomain_611384(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDomain_611383(path: JsonNode; query: JsonNode;
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
  var valid_611385 = query.getOrDefault("Action")
  valid_611385 = validateParameter(valid_611385, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_611385 != nil:
    section.add "Action", valid_611385
  var valid_611386 = query.getOrDefault("Version")
  valid_611386 = validateParameter(valid_611386, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_611386 != nil:
    section.add "Version", valid_611386
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
  var valid_611387 = header.getOrDefault("X-Amz-Signature")
  valid_611387 = validateParameter(valid_611387, JString, required = false,
                                 default = nil)
  if valid_611387 != nil:
    section.add "X-Amz-Signature", valid_611387
  var valid_611388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611388 = validateParameter(valid_611388, JString, required = false,
                                 default = nil)
  if valid_611388 != nil:
    section.add "X-Amz-Content-Sha256", valid_611388
  var valid_611389 = header.getOrDefault("X-Amz-Date")
  valid_611389 = validateParameter(valid_611389, JString, required = false,
                                 default = nil)
  if valid_611389 != nil:
    section.add "X-Amz-Date", valid_611389
  var valid_611390 = header.getOrDefault("X-Amz-Credential")
  valid_611390 = validateParameter(valid_611390, JString, required = false,
                                 default = nil)
  if valid_611390 != nil:
    section.add "X-Amz-Credential", valid_611390
  var valid_611391 = header.getOrDefault("X-Amz-Security-Token")
  valid_611391 = validateParameter(valid_611391, JString, required = false,
                                 default = nil)
  if valid_611391 != nil:
    section.add "X-Amz-Security-Token", valid_611391
  var valid_611392 = header.getOrDefault("X-Amz-Algorithm")
  valid_611392 = validateParameter(valid_611392, JString, required = false,
                                 default = nil)
  if valid_611392 != nil:
    section.add "X-Amz-Algorithm", valid_611392
  var valid_611393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611393 = validateParameter(valid_611393, JString, required = false,
                                 default = nil)
  if valid_611393 != nil:
    section.add "X-Amz-SignedHeaders", valid_611393
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_611394 = formData.getOrDefault("DomainName")
  valid_611394 = validateParameter(valid_611394, JString, required = true,
                                 default = nil)
  if valid_611394 != nil:
    section.add "DomainName", valid_611394
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611395: Call_PostDeleteDomain_611382; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes a search domain and all of its data.
  ## 
  let valid = call_611395.validator(path, query, header, formData, body)
  let scheme = call_611395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611395.url(scheme.get, call_611395.host, call_611395.base,
                         call_611395.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611395, url, valid)

proc call*(call_611396: Call_PostDeleteDomain_611382; DomainName: string;
          Action: string = "DeleteDomain"; Version: string = "2011-02-01"): Recallable =
  ## postDeleteDomain
  ## Permanently deletes a search domain and all of its data.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611397 = newJObject()
  var formData_611398 = newJObject()
  add(formData_611398, "DomainName", newJString(DomainName))
  add(query_611397, "Action", newJString(Action))
  add(query_611397, "Version", newJString(Version))
  result = call_611396.call(nil, query_611397, nil, formData_611398, nil)

var postDeleteDomain* = Call_PostDeleteDomain_611382(name: "postDeleteDomain",
    meth: HttpMethod.HttpPost, host: "cloudsearch.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_PostDeleteDomain_611383,
    base: "/", url: url_PostDeleteDomain_611384,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDomain_611366 = ref object of OpenApiRestCall_610658
proc url_GetDeleteDomain_611368(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDomain_611367(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Permanently deletes a search domain and all of its data.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_611369 = query.getOrDefault("DomainName")
  valid_611369 = validateParameter(valid_611369, JString, required = true,
                                 default = nil)
  if valid_611369 != nil:
    section.add "DomainName", valid_611369
  var valid_611370 = query.getOrDefault("Action")
  valid_611370 = validateParameter(valid_611370, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_611370 != nil:
    section.add "Action", valid_611370
  var valid_611371 = query.getOrDefault("Version")
  valid_611371 = validateParameter(valid_611371, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_611371 != nil:
    section.add "Version", valid_611371
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
  var valid_611372 = header.getOrDefault("X-Amz-Signature")
  valid_611372 = validateParameter(valid_611372, JString, required = false,
                                 default = nil)
  if valid_611372 != nil:
    section.add "X-Amz-Signature", valid_611372
  var valid_611373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611373 = validateParameter(valid_611373, JString, required = false,
                                 default = nil)
  if valid_611373 != nil:
    section.add "X-Amz-Content-Sha256", valid_611373
  var valid_611374 = header.getOrDefault("X-Amz-Date")
  valid_611374 = validateParameter(valid_611374, JString, required = false,
                                 default = nil)
  if valid_611374 != nil:
    section.add "X-Amz-Date", valid_611374
  var valid_611375 = header.getOrDefault("X-Amz-Credential")
  valid_611375 = validateParameter(valid_611375, JString, required = false,
                                 default = nil)
  if valid_611375 != nil:
    section.add "X-Amz-Credential", valid_611375
  var valid_611376 = header.getOrDefault("X-Amz-Security-Token")
  valid_611376 = validateParameter(valid_611376, JString, required = false,
                                 default = nil)
  if valid_611376 != nil:
    section.add "X-Amz-Security-Token", valid_611376
  var valid_611377 = header.getOrDefault("X-Amz-Algorithm")
  valid_611377 = validateParameter(valid_611377, JString, required = false,
                                 default = nil)
  if valid_611377 != nil:
    section.add "X-Amz-Algorithm", valid_611377
  var valid_611378 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611378 = validateParameter(valid_611378, JString, required = false,
                                 default = nil)
  if valid_611378 != nil:
    section.add "X-Amz-SignedHeaders", valid_611378
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611379: Call_GetDeleteDomain_611366; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes a search domain and all of its data.
  ## 
  let valid = call_611379.validator(path, query, header, formData, body)
  let scheme = call_611379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611379.url(scheme.get, call_611379.host, call_611379.base,
                         call_611379.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611379, url, valid)

proc call*(call_611380: Call_GetDeleteDomain_611366; DomainName: string;
          Action: string = "DeleteDomain"; Version: string = "2011-02-01"): Recallable =
  ## getDeleteDomain
  ## Permanently deletes a search domain and all of its data.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611381 = newJObject()
  add(query_611381, "DomainName", newJString(DomainName))
  add(query_611381, "Action", newJString(Action))
  add(query_611381, "Version", newJString(Version))
  result = call_611380.call(nil, query_611381, nil, nil, nil)

var getDeleteDomain* = Call_GetDeleteDomain_611366(name: "getDeleteDomain",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_GetDeleteDomain_611367,
    base: "/", url: url_GetDeleteDomain_611368, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteIndexField_611416 = ref object of OpenApiRestCall_610658
proc url_PostDeleteIndexField_611418(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteIndexField_611417(path: JsonNode; query: JsonNode;
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
  var valid_611419 = query.getOrDefault("Action")
  valid_611419 = validateParameter(valid_611419, JString, required = true,
                                 default = newJString("DeleteIndexField"))
  if valid_611419 != nil:
    section.add "Action", valid_611419
  var valid_611420 = query.getOrDefault("Version")
  valid_611420 = validateParameter(valid_611420, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_611420 != nil:
    section.add "Version", valid_611420
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
  var valid_611421 = header.getOrDefault("X-Amz-Signature")
  valid_611421 = validateParameter(valid_611421, JString, required = false,
                                 default = nil)
  if valid_611421 != nil:
    section.add "X-Amz-Signature", valid_611421
  var valid_611422 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611422 = validateParameter(valid_611422, JString, required = false,
                                 default = nil)
  if valid_611422 != nil:
    section.add "X-Amz-Content-Sha256", valid_611422
  var valid_611423 = header.getOrDefault("X-Amz-Date")
  valid_611423 = validateParameter(valid_611423, JString, required = false,
                                 default = nil)
  if valid_611423 != nil:
    section.add "X-Amz-Date", valid_611423
  var valid_611424 = header.getOrDefault("X-Amz-Credential")
  valid_611424 = validateParameter(valid_611424, JString, required = false,
                                 default = nil)
  if valid_611424 != nil:
    section.add "X-Amz-Credential", valid_611424
  var valid_611425 = header.getOrDefault("X-Amz-Security-Token")
  valid_611425 = validateParameter(valid_611425, JString, required = false,
                                 default = nil)
  if valid_611425 != nil:
    section.add "X-Amz-Security-Token", valid_611425
  var valid_611426 = header.getOrDefault("X-Amz-Algorithm")
  valid_611426 = validateParameter(valid_611426, JString, required = false,
                                 default = nil)
  if valid_611426 != nil:
    section.add "X-Amz-Algorithm", valid_611426
  var valid_611427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611427 = validateParameter(valid_611427, JString, required = false,
                                 default = nil)
  if valid_611427 != nil:
    section.add "X-Amz-SignedHeaders", valid_611427
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   IndexFieldName: JString (required)
  ##                 : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_611428 = formData.getOrDefault("DomainName")
  valid_611428 = validateParameter(valid_611428, JString, required = true,
                                 default = nil)
  if valid_611428 != nil:
    section.add "DomainName", valid_611428
  var valid_611429 = formData.getOrDefault("IndexFieldName")
  valid_611429 = validateParameter(valid_611429, JString, required = true,
                                 default = nil)
  if valid_611429 != nil:
    section.add "IndexFieldName", valid_611429
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611430: Call_PostDeleteIndexField_611416; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code>IndexField</code> from the search domain.
  ## 
  let valid = call_611430.validator(path, query, header, formData, body)
  let scheme = call_611430.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611430.url(scheme.get, call_611430.host, call_611430.base,
                         call_611430.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611430, url, valid)

proc call*(call_611431: Call_PostDeleteIndexField_611416; DomainName: string;
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
  var query_611432 = newJObject()
  var formData_611433 = newJObject()
  add(formData_611433, "DomainName", newJString(DomainName))
  add(formData_611433, "IndexFieldName", newJString(IndexFieldName))
  add(query_611432, "Action", newJString(Action))
  add(query_611432, "Version", newJString(Version))
  result = call_611431.call(nil, query_611432, nil, formData_611433, nil)

var postDeleteIndexField* = Call_PostDeleteIndexField_611416(
    name: "postDeleteIndexField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteIndexField",
    validator: validate_PostDeleteIndexField_611417, base: "/",
    url: url_PostDeleteIndexField_611418, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteIndexField_611399 = ref object of OpenApiRestCall_610658
proc url_GetDeleteIndexField_611401(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteIndexField_611400(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Removes an <code>IndexField</code> from the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   IndexFieldName: JString (required)
  ##                 : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_611402 = query.getOrDefault("DomainName")
  valid_611402 = validateParameter(valid_611402, JString, required = true,
                                 default = nil)
  if valid_611402 != nil:
    section.add "DomainName", valid_611402
  var valid_611403 = query.getOrDefault("Action")
  valid_611403 = validateParameter(valid_611403, JString, required = true,
                                 default = newJString("DeleteIndexField"))
  if valid_611403 != nil:
    section.add "Action", valid_611403
  var valid_611404 = query.getOrDefault("IndexFieldName")
  valid_611404 = validateParameter(valid_611404, JString, required = true,
                                 default = nil)
  if valid_611404 != nil:
    section.add "IndexFieldName", valid_611404
  var valid_611405 = query.getOrDefault("Version")
  valid_611405 = validateParameter(valid_611405, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_611405 != nil:
    section.add "Version", valid_611405
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
  var valid_611406 = header.getOrDefault("X-Amz-Signature")
  valid_611406 = validateParameter(valid_611406, JString, required = false,
                                 default = nil)
  if valid_611406 != nil:
    section.add "X-Amz-Signature", valid_611406
  var valid_611407 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611407 = validateParameter(valid_611407, JString, required = false,
                                 default = nil)
  if valid_611407 != nil:
    section.add "X-Amz-Content-Sha256", valid_611407
  var valid_611408 = header.getOrDefault("X-Amz-Date")
  valid_611408 = validateParameter(valid_611408, JString, required = false,
                                 default = nil)
  if valid_611408 != nil:
    section.add "X-Amz-Date", valid_611408
  var valid_611409 = header.getOrDefault("X-Amz-Credential")
  valid_611409 = validateParameter(valid_611409, JString, required = false,
                                 default = nil)
  if valid_611409 != nil:
    section.add "X-Amz-Credential", valid_611409
  var valid_611410 = header.getOrDefault("X-Amz-Security-Token")
  valid_611410 = validateParameter(valid_611410, JString, required = false,
                                 default = nil)
  if valid_611410 != nil:
    section.add "X-Amz-Security-Token", valid_611410
  var valid_611411 = header.getOrDefault("X-Amz-Algorithm")
  valid_611411 = validateParameter(valid_611411, JString, required = false,
                                 default = nil)
  if valid_611411 != nil:
    section.add "X-Amz-Algorithm", valid_611411
  var valid_611412 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611412 = validateParameter(valid_611412, JString, required = false,
                                 default = nil)
  if valid_611412 != nil:
    section.add "X-Amz-SignedHeaders", valid_611412
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611413: Call_GetDeleteIndexField_611399; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code>IndexField</code> from the search domain.
  ## 
  let valid = call_611413.validator(path, query, header, formData, body)
  let scheme = call_611413.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611413.url(scheme.get, call_611413.host, call_611413.base,
                         call_611413.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611413, url, valid)

proc call*(call_611414: Call_GetDeleteIndexField_611399; DomainName: string;
          IndexFieldName: string; Action: string = "DeleteIndexField";
          Version: string = "2011-02-01"): Recallable =
  ## getDeleteIndexField
  ## Removes an <code>IndexField</code> from the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   IndexFieldName: string (required)
  ##                 : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Version: string (required)
  var query_611415 = newJObject()
  add(query_611415, "DomainName", newJString(DomainName))
  add(query_611415, "Action", newJString(Action))
  add(query_611415, "IndexFieldName", newJString(IndexFieldName))
  add(query_611415, "Version", newJString(Version))
  result = call_611414.call(nil, query_611415, nil, nil, nil)

var getDeleteIndexField* = Call_GetDeleteIndexField_611399(
    name: "getDeleteIndexField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteIndexField",
    validator: validate_GetDeleteIndexField_611400, base: "/",
    url: url_GetDeleteIndexField_611401, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteRankExpression_611451 = ref object of OpenApiRestCall_610658
proc url_PostDeleteRankExpression_611453(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteRankExpression_611452(path: JsonNode; query: JsonNode;
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
  var valid_611454 = query.getOrDefault("Action")
  valid_611454 = validateParameter(valid_611454, JString, required = true,
                                 default = newJString("DeleteRankExpression"))
  if valid_611454 != nil:
    section.add "Action", valid_611454
  var valid_611455 = query.getOrDefault("Version")
  valid_611455 = validateParameter(valid_611455, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_611455 != nil:
    section.add "Version", valid_611455
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
  var valid_611456 = header.getOrDefault("X-Amz-Signature")
  valid_611456 = validateParameter(valid_611456, JString, required = false,
                                 default = nil)
  if valid_611456 != nil:
    section.add "X-Amz-Signature", valid_611456
  var valid_611457 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611457 = validateParameter(valid_611457, JString, required = false,
                                 default = nil)
  if valid_611457 != nil:
    section.add "X-Amz-Content-Sha256", valid_611457
  var valid_611458 = header.getOrDefault("X-Amz-Date")
  valid_611458 = validateParameter(valid_611458, JString, required = false,
                                 default = nil)
  if valid_611458 != nil:
    section.add "X-Amz-Date", valid_611458
  var valid_611459 = header.getOrDefault("X-Amz-Credential")
  valid_611459 = validateParameter(valid_611459, JString, required = false,
                                 default = nil)
  if valid_611459 != nil:
    section.add "X-Amz-Credential", valid_611459
  var valid_611460 = header.getOrDefault("X-Amz-Security-Token")
  valid_611460 = validateParameter(valid_611460, JString, required = false,
                                 default = nil)
  if valid_611460 != nil:
    section.add "X-Amz-Security-Token", valid_611460
  var valid_611461 = header.getOrDefault("X-Amz-Algorithm")
  valid_611461 = validateParameter(valid_611461, JString, required = false,
                                 default = nil)
  if valid_611461 != nil:
    section.add "X-Amz-Algorithm", valid_611461
  var valid_611462 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611462 = validateParameter(valid_611462, JString, required = false,
                                 default = nil)
  if valid_611462 != nil:
    section.add "X-Amz-SignedHeaders", valid_611462
  result.add "header", section
  ## parameters in `formData` object:
  ##   RankName: JString (required)
  ##           : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RankName` field"
  var valid_611463 = formData.getOrDefault("RankName")
  valid_611463 = validateParameter(valid_611463, JString, required = true,
                                 default = nil)
  if valid_611463 != nil:
    section.add "RankName", valid_611463
  var valid_611464 = formData.getOrDefault("DomainName")
  valid_611464 = validateParameter(valid_611464, JString, required = true,
                                 default = nil)
  if valid_611464 != nil:
    section.add "DomainName", valid_611464
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611465: Call_PostDeleteRankExpression_611451; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a <code>RankExpression</code> from the search domain.
  ## 
  let valid = call_611465.validator(path, query, header, formData, body)
  let scheme = call_611465.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611465.url(scheme.get, call_611465.host, call_611465.base,
                         call_611465.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611465, url, valid)

proc call*(call_611466: Call_PostDeleteRankExpression_611451; RankName: string;
          DomainName: string; Action: string = "DeleteRankExpression";
          Version: string = "2011-02-01"): Recallable =
  ## postDeleteRankExpression
  ## Removes a <code>RankExpression</code> from the search domain.
  ##   RankName: string (required)
  ##           : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611467 = newJObject()
  var formData_611468 = newJObject()
  add(formData_611468, "RankName", newJString(RankName))
  add(formData_611468, "DomainName", newJString(DomainName))
  add(query_611467, "Action", newJString(Action))
  add(query_611467, "Version", newJString(Version))
  result = call_611466.call(nil, query_611467, nil, formData_611468, nil)

var postDeleteRankExpression* = Call_PostDeleteRankExpression_611451(
    name: "postDeleteRankExpression", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteRankExpression",
    validator: validate_PostDeleteRankExpression_611452, base: "/",
    url: url_PostDeleteRankExpression_611453, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteRankExpression_611434 = ref object of OpenApiRestCall_610658
proc url_GetDeleteRankExpression_611436(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteRankExpression_611435(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a <code>RankExpression</code> from the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   RankName: JString (required)
  ##           : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_611437 = query.getOrDefault("DomainName")
  valid_611437 = validateParameter(valid_611437, JString, required = true,
                                 default = nil)
  if valid_611437 != nil:
    section.add "DomainName", valid_611437
  var valid_611438 = query.getOrDefault("RankName")
  valid_611438 = validateParameter(valid_611438, JString, required = true,
                                 default = nil)
  if valid_611438 != nil:
    section.add "RankName", valid_611438
  var valid_611439 = query.getOrDefault("Action")
  valid_611439 = validateParameter(valid_611439, JString, required = true,
                                 default = newJString("DeleteRankExpression"))
  if valid_611439 != nil:
    section.add "Action", valid_611439
  var valid_611440 = query.getOrDefault("Version")
  valid_611440 = validateParameter(valid_611440, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_611440 != nil:
    section.add "Version", valid_611440
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
  var valid_611441 = header.getOrDefault("X-Amz-Signature")
  valid_611441 = validateParameter(valid_611441, JString, required = false,
                                 default = nil)
  if valid_611441 != nil:
    section.add "X-Amz-Signature", valid_611441
  var valid_611442 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611442 = validateParameter(valid_611442, JString, required = false,
                                 default = nil)
  if valid_611442 != nil:
    section.add "X-Amz-Content-Sha256", valid_611442
  var valid_611443 = header.getOrDefault("X-Amz-Date")
  valid_611443 = validateParameter(valid_611443, JString, required = false,
                                 default = nil)
  if valid_611443 != nil:
    section.add "X-Amz-Date", valid_611443
  var valid_611444 = header.getOrDefault("X-Amz-Credential")
  valid_611444 = validateParameter(valid_611444, JString, required = false,
                                 default = nil)
  if valid_611444 != nil:
    section.add "X-Amz-Credential", valid_611444
  var valid_611445 = header.getOrDefault("X-Amz-Security-Token")
  valid_611445 = validateParameter(valid_611445, JString, required = false,
                                 default = nil)
  if valid_611445 != nil:
    section.add "X-Amz-Security-Token", valid_611445
  var valid_611446 = header.getOrDefault("X-Amz-Algorithm")
  valid_611446 = validateParameter(valid_611446, JString, required = false,
                                 default = nil)
  if valid_611446 != nil:
    section.add "X-Amz-Algorithm", valid_611446
  var valid_611447 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611447 = validateParameter(valid_611447, JString, required = false,
                                 default = nil)
  if valid_611447 != nil:
    section.add "X-Amz-SignedHeaders", valid_611447
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611448: Call_GetDeleteRankExpression_611434; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a <code>RankExpression</code> from the search domain.
  ## 
  let valid = call_611448.validator(path, query, header, formData, body)
  let scheme = call_611448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611448.url(scheme.get, call_611448.host, call_611448.base,
                         call_611448.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611448, url, valid)

proc call*(call_611449: Call_GetDeleteRankExpression_611434; DomainName: string;
          RankName: string; Action: string = "DeleteRankExpression";
          Version: string = "2011-02-01"): Recallable =
  ## getDeleteRankExpression
  ## Removes a <code>RankExpression</code> from the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   RankName: string (required)
  ##           : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611450 = newJObject()
  add(query_611450, "DomainName", newJString(DomainName))
  add(query_611450, "RankName", newJString(RankName))
  add(query_611450, "Action", newJString(Action))
  add(query_611450, "Version", newJString(Version))
  result = call_611449.call(nil, query_611450, nil, nil, nil)

var getDeleteRankExpression* = Call_GetDeleteRankExpression_611434(
    name: "getDeleteRankExpression", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteRankExpression",
    validator: validate_GetDeleteRankExpression_611435, base: "/",
    url: url_GetDeleteRankExpression_611436, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAvailabilityOptions_611485 = ref object of OpenApiRestCall_610658
proc url_PostDescribeAvailabilityOptions_611487(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeAvailabilityOptions_611486(path: JsonNode;
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
  var valid_611488 = query.getOrDefault("Action")
  valid_611488 = validateParameter(valid_611488, JString, required = true, default = newJString(
      "DescribeAvailabilityOptions"))
  if valid_611488 != nil:
    section.add "Action", valid_611488
  var valid_611489 = query.getOrDefault("Version")
  valid_611489 = validateParameter(valid_611489, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_611489 != nil:
    section.add "Version", valid_611489
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
  var valid_611490 = header.getOrDefault("X-Amz-Signature")
  valid_611490 = validateParameter(valid_611490, JString, required = false,
                                 default = nil)
  if valid_611490 != nil:
    section.add "X-Amz-Signature", valid_611490
  var valid_611491 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611491 = validateParameter(valid_611491, JString, required = false,
                                 default = nil)
  if valid_611491 != nil:
    section.add "X-Amz-Content-Sha256", valid_611491
  var valid_611492 = header.getOrDefault("X-Amz-Date")
  valid_611492 = validateParameter(valid_611492, JString, required = false,
                                 default = nil)
  if valid_611492 != nil:
    section.add "X-Amz-Date", valid_611492
  var valid_611493 = header.getOrDefault("X-Amz-Credential")
  valid_611493 = validateParameter(valid_611493, JString, required = false,
                                 default = nil)
  if valid_611493 != nil:
    section.add "X-Amz-Credential", valid_611493
  var valid_611494 = header.getOrDefault("X-Amz-Security-Token")
  valid_611494 = validateParameter(valid_611494, JString, required = false,
                                 default = nil)
  if valid_611494 != nil:
    section.add "X-Amz-Security-Token", valid_611494
  var valid_611495 = header.getOrDefault("X-Amz-Algorithm")
  valid_611495 = validateParameter(valid_611495, JString, required = false,
                                 default = nil)
  if valid_611495 != nil:
    section.add "X-Amz-Algorithm", valid_611495
  var valid_611496 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611496 = validateParameter(valid_611496, JString, required = false,
                                 default = nil)
  if valid_611496 != nil:
    section.add "X-Amz-SignedHeaders", valid_611496
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_611497 = formData.getOrDefault("DomainName")
  valid_611497 = validateParameter(valid_611497, JString, required = true,
                                 default = nil)
  if valid_611497 != nil:
    section.add "DomainName", valid_611497
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611498: Call_PostDescribeAvailabilityOptions_611485;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_611498.validator(path, query, header, formData, body)
  let scheme = call_611498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611498.url(scheme.get, call_611498.host, call_611498.base,
                         call_611498.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611498, url, valid)

proc call*(call_611499: Call_PostDescribeAvailabilityOptions_611485;
          DomainName: string; Action: string = "DescribeAvailabilityOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeAvailabilityOptions
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611500 = newJObject()
  var formData_611501 = newJObject()
  add(formData_611501, "DomainName", newJString(DomainName))
  add(query_611500, "Action", newJString(Action))
  add(query_611500, "Version", newJString(Version))
  result = call_611499.call(nil, query_611500, nil, formData_611501, nil)

var postDescribeAvailabilityOptions* = Call_PostDescribeAvailabilityOptions_611485(
    name: "postDescribeAvailabilityOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeAvailabilityOptions",
    validator: validate_PostDescribeAvailabilityOptions_611486, base: "/",
    url: url_PostDescribeAvailabilityOptions_611487,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAvailabilityOptions_611469 = ref object of OpenApiRestCall_610658
proc url_GetDescribeAvailabilityOptions_611471(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeAvailabilityOptions_611470(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_611472 = query.getOrDefault("DomainName")
  valid_611472 = validateParameter(valid_611472, JString, required = true,
                                 default = nil)
  if valid_611472 != nil:
    section.add "DomainName", valid_611472
  var valid_611473 = query.getOrDefault("Action")
  valid_611473 = validateParameter(valid_611473, JString, required = true, default = newJString(
      "DescribeAvailabilityOptions"))
  if valid_611473 != nil:
    section.add "Action", valid_611473
  var valid_611474 = query.getOrDefault("Version")
  valid_611474 = validateParameter(valid_611474, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_611474 != nil:
    section.add "Version", valid_611474
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
  var valid_611475 = header.getOrDefault("X-Amz-Signature")
  valid_611475 = validateParameter(valid_611475, JString, required = false,
                                 default = nil)
  if valid_611475 != nil:
    section.add "X-Amz-Signature", valid_611475
  var valid_611476 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611476 = validateParameter(valid_611476, JString, required = false,
                                 default = nil)
  if valid_611476 != nil:
    section.add "X-Amz-Content-Sha256", valid_611476
  var valid_611477 = header.getOrDefault("X-Amz-Date")
  valid_611477 = validateParameter(valid_611477, JString, required = false,
                                 default = nil)
  if valid_611477 != nil:
    section.add "X-Amz-Date", valid_611477
  var valid_611478 = header.getOrDefault("X-Amz-Credential")
  valid_611478 = validateParameter(valid_611478, JString, required = false,
                                 default = nil)
  if valid_611478 != nil:
    section.add "X-Amz-Credential", valid_611478
  var valid_611479 = header.getOrDefault("X-Amz-Security-Token")
  valid_611479 = validateParameter(valid_611479, JString, required = false,
                                 default = nil)
  if valid_611479 != nil:
    section.add "X-Amz-Security-Token", valid_611479
  var valid_611480 = header.getOrDefault("X-Amz-Algorithm")
  valid_611480 = validateParameter(valid_611480, JString, required = false,
                                 default = nil)
  if valid_611480 != nil:
    section.add "X-Amz-Algorithm", valid_611480
  var valid_611481 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611481 = validateParameter(valid_611481, JString, required = false,
                                 default = nil)
  if valid_611481 != nil:
    section.add "X-Amz-SignedHeaders", valid_611481
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611482: Call_GetDescribeAvailabilityOptions_611469; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_611482.validator(path, query, header, formData, body)
  let scheme = call_611482.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611482.url(scheme.get, call_611482.host, call_611482.base,
                         call_611482.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611482, url, valid)

proc call*(call_611483: Call_GetDescribeAvailabilityOptions_611469;
          DomainName: string; Action: string = "DescribeAvailabilityOptions";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeAvailabilityOptions
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611484 = newJObject()
  add(query_611484, "DomainName", newJString(DomainName))
  add(query_611484, "Action", newJString(Action))
  add(query_611484, "Version", newJString(Version))
  result = call_611483.call(nil, query_611484, nil, nil, nil)

var getDescribeAvailabilityOptions* = Call_GetDescribeAvailabilityOptions_611469(
    name: "getDescribeAvailabilityOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeAvailabilityOptions",
    validator: validate_GetDescribeAvailabilityOptions_611470, base: "/",
    url: url_GetDescribeAvailabilityOptions_611471,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDefaultSearchField_611518 = ref object of OpenApiRestCall_610658
proc url_PostDescribeDefaultSearchField_611520(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDefaultSearchField_611519(path: JsonNode;
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
  var valid_611521 = query.getOrDefault("Action")
  valid_611521 = validateParameter(valid_611521, JString, required = true, default = newJString(
      "DescribeDefaultSearchField"))
  if valid_611521 != nil:
    section.add "Action", valid_611521
  var valid_611522 = query.getOrDefault("Version")
  valid_611522 = validateParameter(valid_611522, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_611522 != nil:
    section.add "Version", valid_611522
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
  var valid_611523 = header.getOrDefault("X-Amz-Signature")
  valid_611523 = validateParameter(valid_611523, JString, required = false,
                                 default = nil)
  if valid_611523 != nil:
    section.add "X-Amz-Signature", valid_611523
  var valid_611524 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611524 = validateParameter(valid_611524, JString, required = false,
                                 default = nil)
  if valid_611524 != nil:
    section.add "X-Amz-Content-Sha256", valid_611524
  var valid_611525 = header.getOrDefault("X-Amz-Date")
  valid_611525 = validateParameter(valid_611525, JString, required = false,
                                 default = nil)
  if valid_611525 != nil:
    section.add "X-Amz-Date", valid_611525
  var valid_611526 = header.getOrDefault("X-Amz-Credential")
  valid_611526 = validateParameter(valid_611526, JString, required = false,
                                 default = nil)
  if valid_611526 != nil:
    section.add "X-Amz-Credential", valid_611526
  var valid_611527 = header.getOrDefault("X-Amz-Security-Token")
  valid_611527 = validateParameter(valid_611527, JString, required = false,
                                 default = nil)
  if valid_611527 != nil:
    section.add "X-Amz-Security-Token", valid_611527
  var valid_611528 = header.getOrDefault("X-Amz-Algorithm")
  valid_611528 = validateParameter(valid_611528, JString, required = false,
                                 default = nil)
  if valid_611528 != nil:
    section.add "X-Amz-Algorithm", valid_611528
  var valid_611529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611529 = validateParameter(valid_611529, JString, required = false,
                                 default = nil)
  if valid_611529 != nil:
    section.add "X-Amz-SignedHeaders", valid_611529
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_611530 = formData.getOrDefault("DomainName")
  valid_611530 = validateParameter(valid_611530, JString, required = true,
                                 default = nil)
  if valid_611530 != nil:
    section.add "DomainName", valid_611530
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611531: Call_PostDescribeDefaultSearchField_611518; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the default search field configured for the search domain.
  ## 
  let valid = call_611531.validator(path, query, header, formData, body)
  let scheme = call_611531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611531.url(scheme.get, call_611531.host, call_611531.base,
                         call_611531.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611531, url, valid)

proc call*(call_611532: Call_PostDescribeDefaultSearchField_611518;
          DomainName: string; Action: string = "DescribeDefaultSearchField";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeDefaultSearchField
  ## Gets the default search field configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611533 = newJObject()
  var formData_611534 = newJObject()
  add(formData_611534, "DomainName", newJString(DomainName))
  add(query_611533, "Action", newJString(Action))
  add(query_611533, "Version", newJString(Version))
  result = call_611532.call(nil, query_611533, nil, formData_611534, nil)

var postDescribeDefaultSearchField* = Call_PostDescribeDefaultSearchField_611518(
    name: "postDescribeDefaultSearchField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeDefaultSearchField",
    validator: validate_PostDescribeDefaultSearchField_611519, base: "/",
    url: url_PostDescribeDefaultSearchField_611520,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDefaultSearchField_611502 = ref object of OpenApiRestCall_610658
proc url_GetDescribeDefaultSearchField_611504(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDefaultSearchField_611503(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the default search field configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_611505 = query.getOrDefault("DomainName")
  valid_611505 = validateParameter(valid_611505, JString, required = true,
                                 default = nil)
  if valid_611505 != nil:
    section.add "DomainName", valid_611505
  var valid_611506 = query.getOrDefault("Action")
  valid_611506 = validateParameter(valid_611506, JString, required = true, default = newJString(
      "DescribeDefaultSearchField"))
  if valid_611506 != nil:
    section.add "Action", valid_611506
  var valid_611507 = query.getOrDefault("Version")
  valid_611507 = validateParameter(valid_611507, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_611507 != nil:
    section.add "Version", valid_611507
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
  var valid_611508 = header.getOrDefault("X-Amz-Signature")
  valid_611508 = validateParameter(valid_611508, JString, required = false,
                                 default = nil)
  if valid_611508 != nil:
    section.add "X-Amz-Signature", valid_611508
  var valid_611509 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611509 = validateParameter(valid_611509, JString, required = false,
                                 default = nil)
  if valid_611509 != nil:
    section.add "X-Amz-Content-Sha256", valid_611509
  var valid_611510 = header.getOrDefault("X-Amz-Date")
  valid_611510 = validateParameter(valid_611510, JString, required = false,
                                 default = nil)
  if valid_611510 != nil:
    section.add "X-Amz-Date", valid_611510
  var valid_611511 = header.getOrDefault("X-Amz-Credential")
  valid_611511 = validateParameter(valid_611511, JString, required = false,
                                 default = nil)
  if valid_611511 != nil:
    section.add "X-Amz-Credential", valid_611511
  var valid_611512 = header.getOrDefault("X-Amz-Security-Token")
  valid_611512 = validateParameter(valid_611512, JString, required = false,
                                 default = nil)
  if valid_611512 != nil:
    section.add "X-Amz-Security-Token", valid_611512
  var valid_611513 = header.getOrDefault("X-Amz-Algorithm")
  valid_611513 = validateParameter(valid_611513, JString, required = false,
                                 default = nil)
  if valid_611513 != nil:
    section.add "X-Amz-Algorithm", valid_611513
  var valid_611514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611514 = validateParameter(valid_611514, JString, required = false,
                                 default = nil)
  if valid_611514 != nil:
    section.add "X-Amz-SignedHeaders", valid_611514
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611515: Call_GetDescribeDefaultSearchField_611502; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the default search field configured for the search domain.
  ## 
  let valid = call_611515.validator(path, query, header, formData, body)
  let scheme = call_611515.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611515.url(scheme.get, call_611515.host, call_611515.base,
                         call_611515.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611515, url, valid)

proc call*(call_611516: Call_GetDescribeDefaultSearchField_611502;
          DomainName: string; Action: string = "DescribeDefaultSearchField";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeDefaultSearchField
  ## Gets the default search field configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611517 = newJObject()
  add(query_611517, "DomainName", newJString(DomainName))
  add(query_611517, "Action", newJString(Action))
  add(query_611517, "Version", newJString(Version))
  result = call_611516.call(nil, query_611517, nil, nil, nil)

var getDescribeDefaultSearchField* = Call_GetDescribeDefaultSearchField_611502(
    name: "getDescribeDefaultSearchField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeDefaultSearchField",
    validator: validate_GetDescribeDefaultSearchField_611503, base: "/",
    url: url_GetDescribeDefaultSearchField_611504,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDomains_611551 = ref object of OpenApiRestCall_610658
proc url_PostDescribeDomains_611553(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDomains_611552(path: JsonNode; query: JsonNode;
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
  var valid_611554 = query.getOrDefault("Action")
  valid_611554 = validateParameter(valid_611554, JString, required = true,
                                 default = newJString("DescribeDomains"))
  if valid_611554 != nil:
    section.add "Action", valid_611554
  var valid_611555 = query.getOrDefault("Version")
  valid_611555 = validateParameter(valid_611555, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_611555 != nil:
    section.add "Version", valid_611555
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
  var valid_611556 = header.getOrDefault("X-Amz-Signature")
  valid_611556 = validateParameter(valid_611556, JString, required = false,
                                 default = nil)
  if valid_611556 != nil:
    section.add "X-Amz-Signature", valid_611556
  var valid_611557 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611557 = validateParameter(valid_611557, JString, required = false,
                                 default = nil)
  if valid_611557 != nil:
    section.add "X-Amz-Content-Sha256", valid_611557
  var valid_611558 = header.getOrDefault("X-Amz-Date")
  valid_611558 = validateParameter(valid_611558, JString, required = false,
                                 default = nil)
  if valid_611558 != nil:
    section.add "X-Amz-Date", valid_611558
  var valid_611559 = header.getOrDefault("X-Amz-Credential")
  valid_611559 = validateParameter(valid_611559, JString, required = false,
                                 default = nil)
  if valid_611559 != nil:
    section.add "X-Amz-Credential", valid_611559
  var valid_611560 = header.getOrDefault("X-Amz-Security-Token")
  valid_611560 = validateParameter(valid_611560, JString, required = false,
                                 default = nil)
  if valid_611560 != nil:
    section.add "X-Amz-Security-Token", valid_611560
  var valid_611561 = header.getOrDefault("X-Amz-Algorithm")
  valid_611561 = validateParameter(valid_611561, JString, required = false,
                                 default = nil)
  if valid_611561 != nil:
    section.add "X-Amz-Algorithm", valid_611561
  var valid_611562 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611562 = validateParameter(valid_611562, JString, required = false,
                                 default = nil)
  if valid_611562 != nil:
    section.add "X-Amz-SignedHeaders", valid_611562
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainNames: JArray
  ##              : A list of domain names.
  section = newJObject()
  var valid_611563 = formData.getOrDefault("DomainNames")
  valid_611563 = validateParameter(valid_611563, JArray, required = false,
                                 default = nil)
  if valid_611563 != nil:
    section.add "DomainNames", valid_611563
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611564: Call_PostDescribeDomains_611551; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ## 
  let valid = call_611564.validator(path, query, header, formData, body)
  let scheme = call_611564.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611564.url(scheme.get, call_611564.host, call_611564.base,
                         call_611564.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611564, url, valid)

proc call*(call_611565: Call_PostDescribeDomains_611551;
          DomainNames: JsonNode = nil; Action: string = "DescribeDomains";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeDomains
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611566 = newJObject()
  var formData_611567 = newJObject()
  if DomainNames != nil:
    formData_611567.add "DomainNames", DomainNames
  add(query_611566, "Action", newJString(Action))
  add(query_611566, "Version", newJString(Version))
  result = call_611565.call(nil, query_611566, nil, formData_611567, nil)

var postDescribeDomains* = Call_PostDescribeDomains_611551(
    name: "postDescribeDomains", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeDomains",
    validator: validate_PostDescribeDomains_611552, base: "/",
    url: url_PostDescribeDomains_611553, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDomains_611535 = ref object of OpenApiRestCall_610658
proc url_GetDescribeDomains_611537(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDomains_611536(path: JsonNode; query: JsonNode;
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
  var valid_611538 = query.getOrDefault("DomainNames")
  valid_611538 = validateParameter(valid_611538, JArray, required = false,
                                 default = nil)
  if valid_611538 != nil:
    section.add "DomainNames", valid_611538
  var valid_611539 = query.getOrDefault("Action")
  valid_611539 = validateParameter(valid_611539, JString, required = true,
                                 default = newJString("DescribeDomains"))
  if valid_611539 != nil:
    section.add "Action", valid_611539
  var valid_611540 = query.getOrDefault("Version")
  valid_611540 = validateParameter(valid_611540, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_611540 != nil:
    section.add "Version", valid_611540
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
  var valid_611541 = header.getOrDefault("X-Amz-Signature")
  valid_611541 = validateParameter(valid_611541, JString, required = false,
                                 default = nil)
  if valid_611541 != nil:
    section.add "X-Amz-Signature", valid_611541
  var valid_611542 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611542 = validateParameter(valid_611542, JString, required = false,
                                 default = nil)
  if valid_611542 != nil:
    section.add "X-Amz-Content-Sha256", valid_611542
  var valid_611543 = header.getOrDefault("X-Amz-Date")
  valid_611543 = validateParameter(valid_611543, JString, required = false,
                                 default = nil)
  if valid_611543 != nil:
    section.add "X-Amz-Date", valid_611543
  var valid_611544 = header.getOrDefault("X-Amz-Credential")
  valid_611544 = validateParameter(valid_611544, JString, required = false,
                                 default = nil)
  if valid_611544 != nil:
    section.add "X-Amz-Credential", valid_611544
  var valid_611545 = header.getOrDefault("X-Amz-Security-Token")
  valid_611545 = validateParameter(valid_611545, JString, required = false,
                                 default = nil)
  if valid_611545 != nil:
    section.add "X-Amz-Security-Token", valid_611545
  var valid_611546 = header.getOrDefault("X-Amz-Algorithm")
  valid_611546 = validateParameter(valid_611546, JString, required = false,
                                 default = nil)
  if valid_611546 != nil:
    section.add "X-Amz-Algorithm", valid_611546
  var valid_611547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611547 = validateParameter(valid_611547, JString, required = false,
                                 default = nil)
  if valid_611547 != nil:
    section.add "X-Amz-SignedHeaders", valid_611547
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611548: Call_GetDescribeDomains_611535; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ## 
  let valid = call_611548.validator(path, query, header, formData, body)
  let scheme = call_611548.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611548.url(scheme.get, call_611548.host, call_611548.base,
                         call_611548.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611548, url, valid)

proc call*(call_611549: Call_GetDescribeDomains_611535;
          DomainNames: JsonNode = nil; Action: string = "DescribeDomains";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeDomains
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611550 = newJObject()
  if DomainNames != nil:
    query_611550.add "DomainNames", DomainNames
  add(query_611550, "Action", newJString(Action))
  add(query_611550, "Version", newJString(Version))
  result = call_611549.call(nil, query_611550, nil, nil, nil)

var getDescribeDomains* = Call_GetDescribeDomains_611535(
    name: "getDescribeDomains", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeDomains",
    validator: validate_GetDescribeDomains_611536, base: "/",
    url: url_GetDescribeDomains_611537, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeIndexFields_611585 = ref object of OpenApiRestCall_610658
proc url_PostDescribeIndexFields_611587(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeIndexFields_611586(path: JsonNode; query: JsonNode;
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
  var valid_611588 = query.getOrDefault("Action")
  valid_611588 = validateParameter(valid_611588, JString, required = true,
                                 default = newJString("DescribeIndexFields"))
  if valid_611588 != nil:
    section.add "Action", valid_611588
  var valid_611589 = query.getOrDefault("Version")
  valid_611589 = validateParameter(valid_611589, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_611589 != nil:
    section.add "Version", valid_611589
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
  var valid_611590 = header.getOrDefault("X-Amz-Signature")
  valid_611590 = validateParameter(valid_611590, JString, required = false,
                                 default = nil)
  if valid_611590 != nil:
    section.add "X-Amz-Signature", valid_611590
  var valid_611591 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611591 = validateParameter(valid_611591, JString, required = false,
                                 default = nil)
  if valid_611591 != nil:
    section.add "X-Amz-Content-Sha256", valid_611591
  var valid_611592 = header.getOrDefault("X-Amz-Date")
  valid_611592 = validateParameter(valid_611592, JString, required = false,
                                 default = nil)
  if valid_611592 != nil:
    section.add "X-Amz-Date", valid_611592
  var valid_611593 = header.getOrDefault("X-Amz-Credential")
  valid_611593 = validateParameter(valid_611593, JString, required = false,
                                 default = nil)
  if valid_611593 != nil:
    section.add "X-Amz-Credential", valid_611593
  var valid_611594 = header.getOrDefault("X-Amz-Security-Token")
  valid_611594 = validateParameter(valid_611594, JString, required = false,
                                 default = nil)
  if valid_611594 != nil:
    section.add "X-Amz-Security-Token", valid_611594
  var valid_611595 = header.getOrDefault("X-Amz-Algorithm")
  valid_611595 = validateParameter(valid_611595, JString, required = false,
                                 default = nil)
  if valid_611595 != nil:
    section.add "X-Amz-Algorithm", valid_611595
  var valid_611596 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611596 = validateParameter(valid_611596, JString, required = false,
                                 default = nil)
  if valid_611596 != nil:
    section.add "X-Amz-SignedHeaders", valid_611596
  result.add "header", section
  ## parameters in `formData` object:
  ##   FieldNames: JArray
  ##             : Limits the <code>DescribeIndexFields</code> response to the specified fields.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  var valid_611597 = formData.getOrDefault("FieldNames")
  valid_611597 = validateParameter(valid_611597, JArray, required = false,
                                 default = nil)
  if valid_611597 != nil:
    section.add "FieldNames", valid_611597
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_611598 = formData.getOrDefault("DomainName")
  valid_611598 = validateParameter(valid_611598, JString, required = true,
                                 default = nil)
  if valid_611598 != nil:
    section.add "DomainName", valid_611598
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611599: Call_PostDescribeIndexFields_611585; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ## 
  let valid = call_611599.validator(path, query, header, formData, body)
  let scheme = call_611599.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611599.url(scheme.get, call_611599.host, call_611599.base,
                         call_611599.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611599, url, valid)

proc call*(call_611600: Call_PostDescribeIndexFields_611585; DomainName: string;
          FieldNames: JsonNode = nil; Action: string = "DescribeIndexFields";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeIndexFields
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ##   FieldNames: JArray
  ##             : Limits the <code>DescribeIndexFields</code> response to the specified fields.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611601 = newJObject()
  var formData_611602 = newJObject()
  if FieldNames != nil:
    formData_611602.add "FieldNames", FieldNames
  add(formData_611602, "DomainName", newJString(DomainName))
  add(query_611601, "Action", newJString(Action))
  add(query_611601, "Version", newJString(Version))
  result = call_611600.call(nil, query_611601, nil, formData_611602, nil)

var postDescribeIndexFields* = Call_PostDescribeIndexFields_611585(
    name: "postDescribeIndexFields", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeIndexFields",
    validator: validate_PostDescribeIndexFields_611586, base: "/",
    url: url_PostDescribeIndexFields_611587, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeIndexFields_611568 = ref object of OpenApiRestCall_610658
proc url_GetDescribeIndexFields_611570(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeIndexFields_611569(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   FieldNames: JArray
  ##             : Limits the <code>DescribeIndexFields</code> response to the specified fields.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_611571 = query.getOrDefault("DomainName")
  valid_611571 = validateParameter(valid_611571, JString, required = true,
                                 default = nil)
  if valid_611571 != nil:
    section.add "DomainName", valid_611571
  var valid_611572 = query.getOrDefault("Action")
  valid_611572 = validateParameter(valid_611572, JString, required = true,
                                 default = newJString("DescribeIndexFields"))
  if valid_611572 != nil:
    section.add "Action", valid_611572
  var valid_611573 = query.getOrDefault("Version")
  valid_611573 = validateParameter(valid_611573, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_611573 != nil:
    section.add "Version", valid_611573
  var valid_611574 = query.getOrDefault("FieldNames")
  valid_611574 = validateParameter(valid_611574, JArray, required = false,
                                 default = nil)
  if valid_611574 != nil:
    section.add "FieldNames", valid_611574
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
  var valid_611575 = header.getOrDefault("X-Amz-Signature")
  valid_611575 = validateParameter(valid_611575, JString, required = false,
                                 default = nil)
  if valid_611575 != nil:
    section.add "X-Amz-Signature", valid_611575
  var valid_611576 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611576 = validateParameter(valid_611576, JString, required = false,
                                 default = nil)
  if valid_611576 != nil:
    section.add "X-Amz-Content-Sha256", valid_611576
  var valid_611577 = header.getOrDefault("X-Amz-Date")
  valid_611577 = validateParameter(valid_611577, JString, required = false,
                                 default = nil)
  if valid_611577 != nil:
    section.add "X-Amz-Date", valid_611577
  var valid_611578 = header.getOrDefault("X-Amz-Credential")
  valid_611578 = validateParameter(valid_611578, JString, required = false,
                                 default = nil)
  if valid_611578 != nil:
    section.add "X-Amz-Credential", valid_611578
  var valid_611579 = header.getOrDefault("X-Amz-Security-Token")
  valid_611579 = validateParameter(valid_611579, JString, required = false,
                                 default = nil)
  if valid_611579 != nil:
    section.add "X-Amz-Security-Token", valid_611579
  var valid_611580 = header.getOrDefault("X-Amz-Algorithm")
  valid_611580 = validateParameter(valid_611580, JString, required = false,
                                 default = nil)
  if valid_611580 != nil:
    section.add "X-Amz-Algorithm", valid_611580
  var valid_611581 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611581 = validateParameter(valid_611581, JString, required = false,
                                 default = nil)
  if valid_611581 != nil:
    section.add "X-Amz-SignedHeaders", valid_611581
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611582: Call_GetDescribeIndexFields_611568; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ## 
  let valid = call_611582.validator(path, query, header, formData, body)
  let scheme = call_611582.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611582.url(scheme.get, call_611582.host, call_611582.base,
                         call_611582.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611582, url, valid)

proc call*(call_611583: Call_GetDescribeIndexFields_611568; DomainName: string;
          Action: string = "DescribeIndexFields"; Version: string = "2011-02-01";
          FieldNames: JsonNode = nil): Recallable =
  ## getDescribeIndexFields
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   FieldNames: JArray
  ##             : Limits the <code>DescribeIndexFields</code> response to the specified fields.
  var query_611584 = newJObject()
  add(query_611584, "DomainName", newJString(DomainName))
  add(query_611584, "Action", newJString(Action))
  add(query_611584, "Version", newJString(Version))
  if FieldNames != nil:
    query_611584.add "FieldNames", FieldNames
  result = call_611583.call(nil, query_611584, nil, nil, nil)

var getDescribeIndexFields* = Call_GetDescribeIndexFields_611568(
    name: "getDescribeIndexFields", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeIndexFields",
    validator: validate_GetDescribeIndexFields_611569, base: "/",
    url: url_GetDescribeIndexFields_611570, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeRankExpressions_611620 = ref object of OpenApiRestCall_610658
proc url_PostDescribeRankExpressions_611622(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeRankExpressions_611621(path: JsonNode; query: JsonNode;
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
  var valid_611623 = query.getOrDefault("Action")
  valid_611623 = validateParameter(valid_611623, JString, required = true, default = newJString(
      "DescribeRankExpressions"))
  if valid_611623 != nil:
    section.add "Action", valid_611623
  var valid_611624 = query.getOrDefault("Version")
  valid_611624 = validateParameter(valid_611624, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_611624 != nil:
    section.add "Version", valid_611624
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
  var valid_611625 = header.getOrDefault("X-Amz-Signature")
  valid_611625 = validateParameter(valid_611625, JString, required = false,
                                 default = nil)
  if valid_611625 != nil:
    section.add "X-Amz-Signature", valid_611625
  var valid_611626 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611626 = validateParameter(valid_611626, JString, required = false,
                                 default = nil)
  if valid_611626 != nil:
    section.add "X-Amz-Content-Sha256", valid_611626
  var valid_611627 = header.getOrDefault("X-Amz-Date")
  valid_611627 = validateParameter(valid_611627, JString, required = false,
                                 default = nil)
  if valid_611627 != nil:
    section.add "X-Amz-Date", valid_611627
  var valid_611628 = header.getOrDefault("X-Amz-Credential")
  valid_611628 = validateParameter(valid_611628, JString, required = false,
                                 default = nil)
  if valid_611628 != nil:
    section.add "X-Amz-Credential", valid_611628
  var valid_611629 = header.getOrDefault("X-Amz-Security-Token")
  valid_611629 = validateParameter(valid_611629, JString, required = false,
                                 default = nil)
  if valid_611629 != nil:
    section.add "X-Amz-Security-Token", valid_611629
  var valid_611630 = header.getOrDefault("X-Amz-Algorithm")
  valid_611630 = validateParameter(valid_611630, JString, required = false,
                                 default = nil)
  if valid_611630 != nil:
    section.add "X-Amz-Algorithm", valid_611630
  var valid_611631 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611631 = validateParameter(valid_611631, JString, required = false,
                                 default = nil)
  if valid_611631 != nil:
    section.add "X-Amz-SignedHeaders", valid_611631
  result.add "header", section
  ## parameters in `formData` object:
  ##   RankNames: JArray
  ##            : Limits the <code>DescribeRankExpressions</code> response to the specified fields.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  var valid_611632 = formData.getOrDefault("RankNames")
  valid_611632 = validateParameter(valid_611632, JArray, required = false,
                                 default = nil)
  if valid_611632 != nil:
    section.add "RankNames", valid_611632
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_611633 = formData.getOrDefault("DomainName")
  valid_611633 = validateParameter(valid_611633, JString, required = true,
                                 default = nil)
  if valid_611633 != nil:
    section.add "DomainName", valid_611633
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611634: Call_PostDescribeRankExpressions_611620; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ## 
  let valid = call_611634.validator(path, query, header, formData, body)
  let scheme = call_611634.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611634.url(scheme.get, call_611634.host, call_611634.base,
                         call_611634.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611634, url, valid)

proc call*(call_611635: Call_PostDescribeRankExpressions_611620;
          DomainName: string; RankNames: JsonNode = nil;
          Action: string = "DescribeRankExpressions"; Version: string = "2011-02-01"): Recallable =
  ## postDescribeRankExpressions
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ##   RankNames: JArray
  ##            : Limits the <code>DescribeRankExpressions</code> response to the specified fields.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611636 = newJObject()
  var formData_611637 = newJObject()
  if RankNames != nil:
    formData_611637.add "RankNames", RankNames
  add(formData_611637, "DomainName", newJString(DomainName))
  add(query_611636, "Action", newJString(Action))
  add(query_611636, "Version", newJString(Version))
  result = call_611635.call(nil, query_611636, nil, formData_611637, nil)

var postDescribeRankExpressions* = Call_PostDescribeRankExpressions_611620(
    name: "postDescribeRankExpressions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeRankExpressions",
    validator: validate_PostDescribeRankExpressions_611621, base: "/",
    url: url_PostDescribeRankExpressions_611622,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeRankExpressions_611603 = ref object of OpenApiRestCall_610658
proc url_GetDescribeRankExpressions_611605(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeRankExpressions_611604(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   RankNames: JArray
  ##            : Limits the <code>DescribeRankExpressions</code> response to the specified fields.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_611606 = query.getOrDefault("DomainName")
  valid_611606 = validateParameter(valid_611606, JString, required = true,
                                 default = nil)
  if valid_611606 != nil:
    section.add "DomainName", valid_611606
  var valid_611607 = query.getOrDefault("RankNames")
  valid_611607 = validateParameter(valid_611607, JArray, required = false,
                                 default = nil)
  if valid_611607 != nil:
    section.add "RankNames", valid_611607
  var valid_611608 = query.getOrDefault("Action")
  valid_611608 = validateParameter(valid_611608, JString, required = true, default = newJString(
      "DescribeRankExpressions"))
  if valid_611608 != nil:
    section.add "Action", valid_611608
  var valid_611609 = query.getOrDefault("Version")
  valid_611609 = validateParameter(valid_611609, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_611609 != nil:
    section.add "Version", valid_611609
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
  var valid_611610 = header.getOrDefault("X-Amz-Signature")
  valid_611610 = validateParameter(valid_611610, JString, required = false,
                                 default = nil)
  if valid_611610 != nil:
    section.add "X-Amz-Signature", valid_611610
  var valid_611611 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611611 = validateParameter(valid_611611, JString, required = false,
                                 default = nil)
  if valid_611611 != nil:
    section.add "X-Amz-Content-Sha256", valid_611611
  var valid_611612 = header.getOrDefault("X-Amz-Date")
  valid_611612 = validateParameter(valid_611612, JString, required = false,
                                 default = nil)
  if valid_611612 != nil:
    section.add "X-Amz-Date", valid_611612
  var valid_611613 = header.getOrDefault("X-Amz-Credential")
  valid_611613 = validateParameter(valid_611613, JString, required = false,
                                 default = nil)
  if valid_611613 != nil:
    section.add "X-Amz-Credential", valid_611613
  var valid_611614 = header.getOrDefault("X-Amz-Security-Token")
  valid_611614 = validateParameter(valid_611614, JString, required = false,
                                 default = nil)
  if valid_611614 != nil:
    section.add "X-Amz-Security-Token", valid_611614
  var valid_611615 = header.getOrDefault("X-Amz-Algorithm")
  valid_611615 = validateParameter(valid_611615, JString, required = false,
                                 default = nil)
  if valid_611615 != nil:
    section.add "X-Amz-Algorithm", valid_611615
  var valid_611616 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611616 = validateParameter(valid_611616, JString, required = false,
                                 default = nil)
  if valid_611616 != nil:
    section.add "X-Amz-SignedHeaders", valid_611616
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611617: Call_GetDescribeRankExpressions_611603; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ## 
  let valid = call_611617.validator(path, query, header, formData, body)
  let scheme = call_611617.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611617.url(scheme.get, call_611617.host, call_611617.base,
                         call_611617.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611617, url, valid)

proc call*(call_611618: Call_GetDescribeRankExpressions_611603; DomainName: string;
          RankNames: JsonNode = nil; Action: string = "DescribeRankExpressions";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeRankExpressions
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   RankNames: JArray
  ##            : Limits the <code>DescribeRankExpressions</code> response to the specified fields.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611619 = newJObject()
  add(query_611619, "DomainName", newJString(DomainName))
  if RankNames != nil:
    query_611619.add "RankNames", RankNames
  add(query_611619, "Action", newJString(Action))
  add(query_611619, "Version", newJString(Version))
  result = call_611618.call(nil, query_611619, nil, nil, nil)

var getDescribeRankExpressions* = Call_GetDescribeRankExpressions_611603(
    name: "getDescribeRankExpressions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeRankExpressions",
    validator: validate_GetDescribeRankExpressions_611604, base: "/",
    url: url_GetDescribeRankExpressions_611605,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeServiceAccessPolicies_611654 = ref object of OpenApiRestCall_610658
proc url_PostDescribeServiceAccessPolicies_611656(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeServiceAccessPolicies_611655(path: JsonNode;
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
  var valid_611657 = query.getOrDefault("Action")
  valid_611657 = validateParameter(valid_611657, JString, required = true, default = newJString(
      "DescribeServiceAccessPolicies"))
  if valid_611657 != nil:
    section.add "Action", valid_611657
  var valid_611658 = query.getOrDefault("Version")
  valid_611658 = validateParameter(valid_611658, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_611658 != nil:
    section.add "Version", valid_611658
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
  var valid_611659 = header.getOrDefault("X-Amz-Signature")
  valid_611659 = validateParameter(valid_611659, JString, required = false,
                                 default = nil)
  if valid_611659 != nil:
    section.add "X-Amz-Signature", valid_611659
  var valid_611660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611660 = validateParameter(valid_611660, JString, required = false,
                                 default = nil)
  if valid_611660 != nil:
    section.add "X-Amz-Content-Sha256", valid_611660
  var valid_611661 = header.getOrDefault("X-Amz-Date")
  valid_611661 = validateParameter(valid_611661, JString, required = false,
                                 default = nil)
  if valid_611661 != nil:
    section.add "X-Amz-Date", valid_611661
  var valid_611662 = header.getOrDefault("X-Amz-Credential")
  valid_611662 = validateParameter(valid_611662, JString, required = false,
                                 default = nil)
  if valid_611662 != nil:
    section.add "X-Amz-Credential", valid_611662
  var valid_611663 = header.getOrDefault("X-Amz-Security-Token")
  valid_611663 = validateParameter(valid_611663, JString, required = false,
                                 default = nil)
  if valid_611663 != nil:
    section.add "X-Amz-Security-Token", valid_611663
  var valid_611664 = header.getOrDefault("X-Amz-Algorithm")
  valid_611664 = validateParameter(valid_611664, JString, required = false,
                                 default = nil)
  if valid_611664 != nil:
    section.add "X-Amz-Algorithm", valid_611664
  var valid_611665 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611665 = validateParameter(valid_611665, JString, required = false,
                                 default = nil)
  if valid_611665 != nil:
    section.add "X-Amz-SignedHeaders", valid_611665
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_611666 = formData.getOrDefault("DomainName")
  valid_611666 = validateParameter(valid_611666, JString, required = true,
                                 default = nil)
  if valid_611666 != nil:
    section.add "DomainName", valid_611666
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611667: Call_PostDescribeServiceAccessPolicies_611654;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ## 
  let valid = call_611667.validator(path, query, header, formData, body)
  let scheme = call_611667.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611667.url(scheme.get, call_611667.host, call_611667.base,
                         call_611667.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611667, url, valid)

proc call*(call_611668: Call_PostDescribeServiceAccessPolicies_611654;
          DomainName: string; Action: string = "DescribeServiceAccessPolicies";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeServiceAccessPolicies
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611669 = newJObject()
  var formData_611670 = newJObject()
  add(formData_611670, "DomainName", newJString(DomainName))
  add(query_611669, "Action", newJString(Action))
  add(query_611669, "Version", newJString(Version))
  result = call_611668.call(nil, query_611669, nil, formData_611670, nil)

var postDescribeServiceAccessPolicies* = Call_PostDescribeServiceAccessPolicies_611654(
    name: "postDescribeServiceAccessPolicies", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeServiceAccessPolicies",
    validator: validate_PostDescribeServiceAccessPolicies_611655, base: "/",
    url: url_PostDescribeServiceAccessPolicies_611656,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeServiceAccessPolicies_611638 = ref object of OpenApiRestCall_610658
proc url_GetDescribeServiceAccessPolicies_611640(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeServiceAccessPolicies_611639(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_611641 = query.getOrDefault("DomainName")
  valid_611641 = validateParameter(valid_611641, JString, required = true,
                                 default = nil)
  if valid_611641 != nil:
    section.add "DomainName", valid_611641
  var valid_611642 = query.getOrDefault("Action")
  valid_611642 = validateParameter(valid_611642, JString, required = true, default = newJString(
      "DescribeServiceAccessPolicies"))
  if valid_611642 != nil:
    section.add "Action", valid_611642
  var valid_611643 = query.getOrDefault("Version")
  valid_611643 = validateParameter(valid_611643, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_611643 != nil:
    section.add "Version", valid_611643
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
  var valid_611644 = header.getOrDefault("X-Amz-Signature")
  valid_611644 = validateParameter(valid_611644, JString, required = false,
                                 default = nil)
  if valid_611644 != nil:
    section.add "X-Amz-Signature", valid_611644
  var valid_611645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611645 = validateParameter(valid_611645, JString, required = false,
                                 default = nil)
  if valid_611645 != nil:
    section.add "X-Amz-Content-Sha256", valid_611645
  var valid_611646 = header.getOrDefault("X-Amz-Date")
  valid_611646 = validateParameter(valid_611646, JString, required = false,
                                 default = nil)
  if valid_611646 != nil:
    section.add "X-Amz-Date", valid_611646
  var valid_611647 = header.getOrDefault("X-Amz-Credential")
  valid_611647 = validateParameter(valid_611647, JString, required = false,
                                 default = nil)
  if valid_611647 != nil:
    section.add "X-Amz-Credential", valid_611647
  var valid_611648 = header.getOrDefault("X-Amz-Security-Token")
  valid_611648 = validateParameter(valid_611648, JString, required = false,
                                 default = nil)
  if valid_611648 != nil:
    section.add "X-Amz-Security-Token", valid_611648
  var valid_611649 = header.getOrDefault("X-Amz-Algorithm")
  valid_611649 = validateParameter(valid_611649, JString, required = false,
                                 default = nil)
  if valid_611649 != nil:
    section.add "X-Amz-Algorithm", valid_611649
  var valid_611650 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611650 = validateParameter(valid_611650, JString, required = false,
                                 default = nil)
  if valid_611650 != nil:
    section.add "X-Amz-SignedHeaders", valid_611650
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611651: Call_GetDescribeServiceAccessPolicies_611638;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ## 
  let valid = call_611651.validator(path, query, header, formData, body)
  let scheme = call_611651.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611651.url(scheme.get, call_611651.host, call_611651.base,
                         call_611651.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611651, url, valid)

proc call*(call_611652: Call_GetDescribeServiceAccessPolicies_611638;
          DomainName: string; Action: string = "DescribeServiceAccessPolicies";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeServiceAccessPolicies
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611653 = newJObject()
  add(query_611653, "DomainName", newJString(DomainName))
  add(query_611653, "Action", newJString(Action))
  add(query_611653, "Version", newJString(Version))
  result = call_611652.call(nil, query_611653, nil, nil, nil)

var getDescribeServiceAccessPolicies* = Call_GetDescribeServiceAccessPolicies_611638(
    name: "getDescribeServiceAccessPolicies", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeServiceAccessPolicies",
    validator: validate_GetDescribeServiceAccessPolicies_611639, base: "/",
    url: url_GetDescribeServiceAccessPolicies_611640,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeStemmingOptions_611687 = ref object of OpenApiRestCall_610658
proc url_PostDescribeStemmingOptions_611689(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeStemmingOptions_611688(path: JsonNode; query: JsonNode;
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
  var valid_611690 = query.getOrDefault("Action")
  valid_611690 = validateParameter(valid_611690, JString, required = true, default = newJString(
      "DescribeStemmingOptions"))
  if valid_611690 != nil:
    section.add "Action", valid_611690
  var valid_611691 = query.getOrDefault("Version")
  valid_611691 = validateParameter(valid_611691, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_611691 != nil:
    section.add "Version", valid_611691
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
  var valid_611692 = header.getOrDefault("X-Amz-Signature")
  valid_611692 = validateParameter(valid_611692, JString, required = false,
                                 default = nil)
  if valid_611692 != nil:
    section.add "X-Amz-Signature", valid_611692
  var valid_611693 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611693 = validateParameter(valid_611693, JString, required = false,
                                 default = nil)
  if valid_611693 != nil:
    section.add "X-Amz-Content-Sha256", valid_611693
  var valid_611694 = header.getOrDefault("X-Amz-Date")
  valid_611694 = validateParameter(valid_611694, JString, required = false,
                                 default = nil)
  if valid_611694 != nil:
    section.add "X-Amz-Date", valid_611694
  var valid_611695 = header.getOrDefault("X-Amz-Credential")
  valid_611695 = validateParameter(valid_611695, JString, required = false,
                                 default = nil)
  if valid_611695 != nil:
    section.add "X-Amz-Credential", valid_611695
  var valid_611696 = header.getOrDefault("X-Amz-Security-Token")
  valid_611696 = validateParameter(valid_611696, JString, required = false,
                                 default = nil)
  if valid_611696 != nil:
    section.add "X-Amz-Security-Token", valid_611696
  var valid_611697 = header.getOrDefault("X-Amz-Algorithm")
  valid_611697 = validateParameter(valid_611697, JString, required = false,
                                 default = nil)
  if valid_611697 != nil:
    section.add "X-Amz-Algorithm", valid_611697
  var valid_611698 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611698 = validateParameter(valid_611698, JString, required = false,
                                 default = nil)
  if valid_611698 != nil:
    section.add "X-Amz-SignedHeaders", valid_611698
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_611699 = formData.getOrDefault("DomainName")
  valid_611699 = validateParameter(valid_611699, JString, required = true,
                                 default = nil)
  if valid_611699 != nil:
    section.add "DomainName", valid_611699
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611700: Call_PostDescribeStemmingOptions_611687; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the stemming dictionary configured for the search domain.
  ## 
  let valid = call_611700.validator(path, query, header, formData, body)
  let scheme = call_611700.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611700.url(scheme.get, call_611700.host, call_611700.base,
                         call_611700.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611700, url, valid)

proc call*(call_611701: Call_PostDescribeStemmingOptions_611687;
          DomainName: string; Action: string = "DescribeStemmingOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeStemmingOptions
  ## Gets the stemming dictionary configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611702 = newJObject()
  var formData_611703 = newJObject()
  add(formData_611703, "DomainName", newJString(DomainName))
  add(query_611702, "Action", newJString(Action))
  add(query_611702, "Version", newJString(Version))
  result = call_611701.call(nil, query_611702, nil, formData_611703, nil)

var postDescribeStemmingOptions* = Call_PostDescribeStemmingOptions_611687(
    name: "postDescribeStemmingOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeStemmingOptions",
    validator: validate_PostDescribeStemmingOptions_611688, base: "/",
    url: url_PostDescribeStemmingOptions_611689,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeStemmingOptions_611671 = ref object of OpenApiRestCall_610658
proc url_GetDescribeStemmingOptions_611673(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeStemmingOptions_611672(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the stemming dictionary configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_611674 = query.getOrDefault("DomainName")
  valid_611674 = validateParameter(valid_611674, JString, required = true,
                                 default = nil)
  if valid_611674 != nil:
    section.add "DomainName", valid_611674
  var valid_611675 = query.getOrDefault("Action")
  valid_611675 = validateParameter(valid_611675, JString, required = true, default = newJString(
      "DescribeStemmingOptions"))
  if valid_611675 != nil:
    section.add "Action", valid_611675
  var valid_611676 = query.getOrDefault("Version")
  valid_611676 = validateParameter(valid_611676, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_611676 != nil:
    section.add "Version", valid_611676
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
  var valid_611677 = header.getOrDefault("X-Amz-Signature")
  valid_611677 = validateParameter(valid_611677, JString, required = false,
                                 default = nil)
  if valid_611677 != nil:
    section.add "X-Amz-Signature", valid_611677
  var valid_611678 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611678 = validateParameter(valid_611678, JString, required = false,
                                 default = nil)
  if valid_611678 != nil:
    section.add "X-Amz-Content-Sha256", valid_611678
  var valid_611679 = header.getOrDefault("X-Amz-Date")
  valid_611679 = validateParameter(valid_611679, JString, required = false,
                                 default = nil)
  if valid_611679 != nil:
    section.add "X-Amz-Date", valid_611679
  var valid_611680 = header.getOrDefault("X-Amz-Credential")
  valid_611680 = validateParameter(valid_611680, JString, required = false,
                                 default = nil)
  if valid_611680 != nil:
    section.add "X-Amz-Credential", valid_611680
  var valid_611681 = header.getOrDefault("X-Amz-Security-Token")
  valid_611681 = validateParameter(valid_611681, JString, required = false,
                                 default = nil)
  if valid_611681 != nil:
    section.add "X-Amz-Security-Token", valid_611681
  var valid_611682 = header.getOrDefault("X-Amz-Algorithm")
  valid_611682 = validateParameter(valid_611682, JString, required = false,
                                 default = nil)
  if valid_611682 != nil:
    section.add "X-Amz-Algorithm", valid_611682
  var valid_611683 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611683 = validateParameter(valid_611683, JString, required = false,
                                 default = nil)
  if valid_611683 != nil:
    section.add "X-Amz-SignedHeaders", valid_611683
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611684: Call_GetDescribeStemmingOptions_611671; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the stemming dictionary configured for the search domain.
  ## 
  let valid = call_611684.validator(path, query, header, formData, body)
  let scheme = call_611684.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611684.url(scheme.get, call_611684.host, call_611684.base,
                         call_611684.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611684, url, valid)

proc call*(call_611685: Call_GetDescribeStemmingOptions_611671; DomainName: string;
          Action: string = "DescribeStemmingOptions"; Version: string = "2011-02-01"): Recallable =
  ## getDescribeStemmingOptions
  ## Gets the stemming dictionary configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611686 = newJObject()
  add(query_611686, "DomainName", newJString(DomainName))
  add(query_611686, "Action", newJString(Action))
  add(query_611686, "Version", newJString(Version))
  result = call_611685.call(nil, query_611686, nil, nil, nil)

var getDescribeStemmingOptions* = Call_GetDescribeStemmingOptions_611671(
    name: "getDescribeStemmingOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeStemmingOptions",
    validator: validate_GetDescribeStemmingOptions_611672, base: "/",
    url: url_GetDescribeStemmingOptions_611673,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeStopwordOptions_611720 = ref object of OpenApiRestCall_610658
proc url_PostDescribeStopwordOptions_611722(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeStopwordOptions_611721(path: JsonNode; query: JsonNode;
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
  var valid_611723 = query.getOrDefault("Action")
  valid_611723 = validateParameter(valid_611723, JString, required = true, default = newJString(
      "DescribeStopwordOptions"))
  if valid_611723 != nil:
    section.add "Action", valid_611723
  var valid_611724 = query.getOrDefault("Version")
  valid_611724 = validateParameter(valid_611724, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_611724 != nil:
    section.add "Version", valid_611724
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
  var valid_611725 = header.getOrDefault("X-Amz-Signature")
  valid_611725 = validateParameter(valid_611725, JString, required = false,
                                 default = nil)
  if valid_611725 != nil:
    section.add "X-Amz-Signature", valid_611725
  var valid_611726 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611726 = validateParameter(valid_611726, JString, required = false,
                                 default = nil)
  if valid_611726 != nil:
    section.add "X-Amz-Content-Sha256", valid_611726
  var valid_611727 = header.getOrDefault("X-Amz-Date")
  valid_611727 = validateParameter(valid_611727, JString, required = false,
                                 default = nil)
  if valid_611727 != nil:
    section.add "X-Amz-Date", valid_611727
  var valid_611728 = header.getOrDefault("X-Amz-Credential")
  valid_611728 = validateParameter(valid_611728, JString, required = false,
                                 default = nil)
  if valid_611728 != nil:
    section.add "X-Amz-Credential", valid_611728
  var valid_611729 = header.getOrDefault("X-Amz-Security-Token")
  valid_611729 = validateParameter(valid_611729, JString, required = false,
                                 default = nil)
  if valid_611729 != nil:
    section.add "X-Amz-Security-Token", valid_611729
  var valid_611730 = header.getOrDefault("X-Amz-Algorithm")
  valid_611730 = validateParameter(valid_611730, JString, required = false,
                                 default = nil)
  if valid_611730 != nil:
    section.add "X-Amz-Algorithm", valid_611730
  var valid_611731 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611731 = validateParameter(valid_611731, JString, required = false,
                                 default = nil)
  if valid_611731 != nil:
    section.add "X-Amz-SignedHeaders", valid_611731
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_611732 = formData.getOrDefault("DomainName")
  valid_611732 = validateParameter(valid_611732, JString, required = true,
                                 default = nil)
  if valid_611732 != nil:
    section.add "DomainName", valid_611732
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611733: Call_PostDescribeStopwordOptions_611720; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the stopwords configured for the search domain.
  ## 
  let valid = call_611733.validator(path, query, header, formData, body)
  let scheme = call_611733.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611733.url(scheme.get, call_611733.host, call_611733.base,
                         call_611733.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611733, url, valid)

proc call*(call_611734: Call_PostDescribeStopwordOptions_611720;
          DomainName: string; Action: string = "DescribeStopwordOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeStopwordOptions
  ## Gets the stopwords configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611735 = newJObject()
  var formData_611736 = newJObject()
  add(formData_611736, "DomainName", newJString(DomainName))
  add(query_611735, "Action", newJString(Action))
  add(query_611735, "Version", newJString(Version))
  result = call_611734.call(nil, query_611735, nil, formData_611736, nil)

var postDescribeStopwordOptions* = Call_PostDescribeStopwordOptions_611720(
    name: "postDescribeStopwordOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeStopwordOptions",
    validator: validate_PostDescribeStopwordOptions_611721, base: "/",
    url: url_PostDescribeStopwordOptions_611722,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeStopwordOptions_611704 = ref object of OpenApiRestCall_610658
proc url_GetDescribeStopwordOptions_611706(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeStopwordOptions_611705(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the stopwords configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_611707 = query.getOrDefault("DomainName")
  valid_611707 = validateParameter(valid_611707, JString, required = true,
                                 default = nil)
  if valid_611707 != nil:
    section.add "DomainName", valid_611707
  var valid_611708 = query.getOrDefault("Action")
  valid_611708 = validateParameter(valid_611708, JString, required = true, default = newJString(
      "DescribeStopwordOptions"))
  if valid_611708 != nil:
    section.add "Action", valid_611708
  var valid_611709 = query.getOrDefault("Version")
  valid_611709 = validateParameter(valid_611709, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_611709 != nil:
    section.add "Version", valid_611709
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
  var valid_611710 = header.getOrDefault("X-Amz-Signature")
  valid_611710 = validateParameter(valid_611710, JString, required = false,
                                 default = nil)
  if valid_611710 != nil:
    section.add "X-Amz-Signature", valid_611710
  var valid_611711 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611711 = validateParameter(valid_611711, JString, required = false,
                                 default = nil)
  if valid_611711 != nil:
    section.add "X-Amz-Content-Sha256", valid_611711
  var valid_611712 = header.getOrDefault("X-Amz-Date")
  valid_611712 = validateParameter(valid_611712, JString, required = false,
                                 default = nil)
  if valid_611712 != nil:
    section.add "X-Amz-Date", valid_611712
  var valid_611713 = header.getOrDefault("X-Amz-Credential")
  valid_611713 = validateParameter(valid_611713, JString, required = false,
                                 default = nil)
  if valid_611713 != nil:
    section.add "X-Amz-Credential", valid_611713
  var valid_611714 = header.getOrDefault("X-Amz-Security-Token")
  valid_611714 = validateParameter(valid_611714, JString, required = false,
                                 default = nil)
  if valid_611714 != nil:
    section.add "X-Amz-Security-Token", valid_611714
  var valid_611715 = header.getOrDefault("X-Amz-Algorithm")
  valid_611715 = validateParameter(valid_611715, JString, required = false,
                                 default = nil)
  if valid_611715 != nil:
    section.add "X-Amz-Algorithm", valid_611715
  var valid_611716 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611716 = validateParameter(valid_611716, JString, required = false,
                                 default = nil)
  if valid_611716 != nil:
    section.add "X-Amz-SignedHeaders", valid_611716
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611717: Call_GetDescribeStopwordOptions_611704; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the stopwords configured for the search domain.
  ## 
  let valid = call_611717.validator(path, query, header, formData, body)
  let scheme = call_611717.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611717.url(scheme.get, call_611717.host, call_611717.base,
                         call_611717.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611717, url, valid)

proc call*(call_611718: Call_GetDescribeStopwordOptions_611704; DomainName: string;
          Action: string = "DescribeStopwordOptions"; Version: string = "2011-02-01"): Recallable =
  ## getDescribeStopwordOptions
  ## Gets the stopwords configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611719 = newJObject()
  add(query_611719, "DomainName", newJString(DomainName))
  add(query_611719, "Action", newJString(Action))
  add(query_611719, "Version", newJString(Version))
  result = call_611718.call(nil, query_611719, nil, nil, nil)

var getDescribeStopwordOptions* = Call_GetDescribeStopwordOptions_611704(
    name: "getDescribeStopwordOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeStopwordOptions",
    validator: validate_GetDescribeStopwordOptions_611705, base: "/",
    url: url_GetDescribeStopwordOptions_611706,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeSynonymOptions_611753 = ref object of OpenApiRestCall_610658
proc url_PostDescribeSynonymOptions_611755(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeSynonymOptions_611754(path: JsonNode; query: JsonNode;
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
  var valid_611756 = query.getOrDefault("Action")
  valid_611756 = validateParameter(valid_611756, JString, required = true,
                                 default = newJString("DescribeSynonymOptions"))
  if valid_611756 != nil:
    section.add "Action", valid_611756
  var valid_611757 = query.getOrDefault("Version")
  valid_611757 = validateParameter(valid_611757, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_611757 != nil:
    section.add "Version", valid_611757
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
  var valid_611758 = header.getOrDefault("X-Amz-Signature")
  valid_611758 = validateParameter(valid_611758, JString, required = false,
                                 default = nil)
  if valid_611758 != nil:
    section.add "X-Amz-Signature", valid_611758
  var valid_611759 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611759 = validateParameter(valid_611759, JString, required = false,
                                 default = nil)
  if valid_611759 != nil:
    section.add "X-Amz-Content-Sha256", valid_611759
  var valid_611760 = header.getOrDefault("X-Amz-Date")
  valid_611760 = validateParameter(valid_611760, JString, required = false,
                                 default = nil)
  if valid_611760 != nil:
    section.add "X-Amz-Date", valid_611760
  var valid_611761 = header.getOrDefault("X-Amz-Credential")
  valid_611761 = validateParameter(valid_611761, JString, required = false,
                                 default = nil)
  if valid_611761 != nil:
    section.add "X-Amz-Credential", valid_611761
  var valid_611762 = header.getOrDefault("X-Amz-Security-Token")
  valid_611762 = validateParameter(valid_611762, JString, required = false,
                                 default = nil)
  if valid_611762 != nil:
    section.add "X-Amz-Security-Token", valid_611762
  var valid_611763 = header.getOrDefault("X-Amz-Algorithm")
  valid_611763 = validateParameter(valid_611763, JString, required = false,
                                 default = nil)
  if valid_611763 != nil:
    section.add "X-Amz-Algorithm", valid_611763
  var valid_611764 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611764 = validateParameter(valid_611764, JString, required = false,
                                 default = nil)
  if valid_611764 != nil:
    section.add "X-Amz-SignedHeaders", valid_611764
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_611765 = formData.getOrDefault("DomainName")
  valid_611765 = validateParameter(valid_611765, JString, required = true,
                                 default = nil)
  if valid_611765 != nil:
    section.add "DomainName", valid_611765
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611766: Call_PostDescribeSynonymOptions_611753; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the synonym dictionary configured for the search domain.
  ## 
  let valid = call_611766.validator(path, query, header, formData, body)
  let scheme = call_611766.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611766.url(scheme.get, call_611766.host, call_611766.base,
                         call_611766.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611766, url, valid)

proc call*(call_611767: Call_PostDescribeSynonymOptions_611753; DomainName: string;
          Action: string = "DescribeSynonymOptions"; Version: string = "2011-02-01"): Recallable =
  ## postDescribeSynonymOptions
  ## Gets the synonym dictionary configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611768 = newJObject()
  var formData_611769 = newJObject()
  add(formData_611769, "DomainName", newJString(DomainName))
  add(query_611768, "Action", newJString(Action))
  add(query_611768, "Version", newJString(Version))
  result = call_611767.call(nil, query_611768, nil, formData_611769, nil)

var postDescribeSynonymOptions* = Call_PostDescribeSynonymOptions_611753(
    name: "postDescribeSynonymOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeSynonymOptions",
    validator: validate_PostDescribeSynonymOptions_611754, base: "/",
    url: url_PostDescribeSynonymOptions_611755,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeSynonymOptions_611737 = ref object of OpenApiRestCall_610658
proc url_GetDescribeSynonymOptions_611739(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeSynonymOptions_611738(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the synonym dictionary configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_611740 = query.getOrDefault("DomainName")
  valid_611740 = validateParameter(valid_611740, JString, required = true,
                                 default = nil)
  if valid_611740 != nil:
    section.add "DomainName", valid_611740
  var valid_611741 = query.getOrDefault("Action")
  valid_611741 = validateParameter(valid_611741, JString, required = true,
                                 default = newJString("DescribeSynonymOptions"))
  if valid_611741 != nil:
    section.add "Action", valid_611741
  var valid_611742 = query.getOrDefault("Version")
  valid_611742 = validateParameter(valid_611742, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_611742 != nil:
    section.add "Version", valid_611742
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
  var valid_611743 = header.getOrDefault("X-Amz-Signature")
  valid_611743 = validateParameter(valid_611743, JString, required = false,
                                 default = nil)
  if valid_611743 != nil:
    section.add "X-Amz-Signature", valid_611743
  var valid_611744 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611744 = validateParameter(valid_611744, JString, required = false,
                                 default = nil)
  if valid_611744 != nil:
    section.add "X-Amz-Content-Sha256", valid_611744
  var valid_611745 = header.getOrDefault("X-Amz-Date")
  valid_611745 = validateParameter(valid_611745, JString, required = false,
                                 default = nil)
  if valid_611745 != nil:
    section.add "X-Amz-Date", valid_611745
  var valid_611746 = header.getOrDefault("X-Amz-Credential")
  valid_611746 = validateParameter(valid_611746, JString, required = false,
                                 default = nil)
  if valid_611746 != nil:
    section.add "X-Amz-Credential", valid_611746
  var valid_611747 = header.getOrDefault("X-Amz-Security-Token")
  valid_611747 = validateParameter(valid_611747, JString, required = false,
                                 default = nil)
  if valid_611747 != nil:
    section.add "X-Amz-Security-Token", valid_611747
  var valid_611748 = header.getOrDefault("X-Amz-Algorithm")
  valid_611748 = validateParameter(valid_611748, JString, required = false,
                                 default = nil)
  if valid_611748 != nil:
    section.add "X-Amz-Algorithm", valid_611748
  var valid_611749 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611749 = validateParameter(valid_611749, JString, required = false,
                                 default = nil)
  if valid_611749 != nil:
    section.add "X-Amz-SignedHeaders", valid_611749
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611750: Call_GetDescribeSynonymOptions_611737; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the synonym dictionary configured for the search domain.
  ## 
  let valid = call_611750.validator(path, query, header, formData, body)
  let scheme = call_611750.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611750.url(scheme.get, call_611750.host, call_611750.base,
                         call_611750.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611750, url, valid)

proc call*(call_611751: Call_GetDescribeSynonymOptions_611737; DomainName: string;
          Action: string = "DescribeSynonymOptions"; Version: string = "2011-02-01"): Recallable =
  ## getDescribeSynonymOptions
  ## Gets the synonym dictionary configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611752 = newJObject()
  add(query_611752, "DomainName", newJString(DomainName))
  add(query_611752, "Action", newJString(Action))
  add(query_611752, "Version", newJString(Version))
  result = call_611751.call(nil, query_611752, nil, nil, nil)

var getDescribeSynonymOptions* = Call_GetDescribeSynonymOptions_611737(
    name: "getDescribeSynonymOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeSynonymOptions",
    validator: validate_GetDescribeSynonymOptions_611738, base: "/",
    url: url_GetDescribeSynonymOptions_611739,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostIndexDocuments_611786 = ref object of OpenApiRestCall_610658
proc url_PostIndexDocuments_611788(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostIndexDocuments_611787(path: JsonNode; query: JsonNode;
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
  var valid_611789 = query.getOrDefault("Action")
  valid_611789 = validateParameter(valid_611789, JString, required = true,
                                 default = newJString("IndexDocuments"))
  if valid_611789 != nil:
    section.add "Action", valid_611789
  var valid_611790 = query.getOrDefault("Version")
  valid_611790 = validateParameter(valid_611790, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_611790 != nil:
    section.add "Version", valid_611790
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
  var valid_611791 = header.getOrDefault("X-Amz-Signature")
  valid_611791 = validateParameter(valid_611791, JString, required = false,
                                 default = nil)
  if valid_611791 != nil:
    section.add "X-Amz-Signature", valid_611791
  var valid_611792 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611792 = validateParameter(valid_611792, JString, required = false,
                                 default = nil)
  if valid_611792 != nil:
    section.add "X-Amz-Content-Sha256", valid_611792
  var valid_611793 = header.getOrDefault("X-Amz-Date")
  valid_611793 = validateParameter(valid_611793, JString, required = false,
                                 default = nil)
  if valid_611793 != nil:
    section.add "X-Amz-Date", valid_611793
  var valid_611794 = header.getOrDefault("X-Amz-Credential")
  valid_611794 = validateParameter(valid_611794, JString, required = false,
                                 default = nil)
  if valid_611794 != nil:
    section.add "X-Amz-Credential", valid_611794
  var valid_611795 = header.getOrDefault("X-Amz-Security-Token")
  valid_611795 = validateParameter(valid_611795, JString, required = false,
                                 default = nil)
  if valid_611795 != nil:
    section.add "X-Amz-Security-Token", valid_611795
  var valid_611796 = header.getOrDefault("X-Amz-Algorithm")
  valid_611796 = validateParameter(valid_611796, JString, required = false,
                                 default = nil)
  if valid_611796 != nil:
    section.add "X-Amz-Algorithm", valid_611796
  var valid_611797 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611797 = validateParameter(valid_611797, JString, required = false,
                                 default = nil)
  if valid_611797 != nil:
    section.add "X-Amz-SignedHeaders", valid_611797
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_611798 = formData.getOrDefault("DomainName")
  valid_611798 = validateParameter(valid_611798, JString, required = true,
                                 default = nil)
  if valid_611798 != nil:
    section.add "DomainName", valid_611798
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611799: Call_PostIndexDocuments_611786; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ## 
  let valid = call_611799.validator(path, query, header, formData, body)
  let scheme = call_611799.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611799.url(scheme.get, call_611799.host, call_611799.base,
                         call_611799.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611799, url, valid)

proc call*(call_611800: Call_PostIndexDocuments_611786; DomainName: string;
          Action: string = "IndexDocuments"; Version: string = "2011-02-01"): Recallable =
  ## postIndexDocuments
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611801 = newJObject()
  var formData_611802 = newJObject()
  add(formData_611802, "DomainName", newJString(DomainName))
  add(query_611801, "Action", newJString(Action))
  add(query_611801, "Version", newJString(Version))
  result = call_611800.call(nil, query_611801, nil, formData_611802, nil)

var postIndexDocuments* = Call_PostIndexDocuments_611786(
    name: "postIndexDocuments", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=IndexDocuments",
    validator: validate_PostIndexDocuments_611787, base: "/",
    url: url_PostIndexDocuments_611788, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIndexDocuments_611770 = ref object of OpenApiRestCall_610658
proc url_GetIndexDocuments_611772(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetIndexDocuments_611771(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_611773 = query.getOrDefault("DomainName")
  valid_611773 = validateParameter(valid_611773, JString, required = true,
                                 default = nil)
  if valid_611773 != nil:
    section.add "DomainName", valid_611773
  var valid_611774 = query.getOrDefault("Action")
  valid_611774 = validateParameter(valid_611774, JString, required = true,
                                 default = newJString("IndexDocuments"))
  if valid_611774 != nil:
    section.add "Action", valid_611774
  var valid_611775 = query.getOrDefault("Version")
  valid_611775 = validateParameter(valid_611775, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_611775 != nil:
    section.add "Version", valid_611775
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
  var valid_611776 = header.getOrDefault("X-Amz-Signature")
  valid_611776 = validateParameter(valid_611776, JString, required = false,
                                 default = nil)
  if valid_611776 != nil:
    section.add "X-Amz-Signature", valid_611776
  var valid_611777 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611777 = validateParameter(valid_611777, JString, required = false,
                                 default = nil)
  if valid_611777 != nil:
    section.add "X-Amz-Content-Sha256", valid_611777
  var valid_611778 = header.getOrDefault("X-Amz-Date")
  valid_611778 = validateParameter(valid_611778, JString, required = false,
                                 default = nil)
  if valid_611778 != nil:
    section.add "X-Amz-Date", valid_611778
  var valid_611779 = header.getOrDefault("X-Amz-Credential")
  valid_611779 = validateParameter(valid_611779, JString, required = false,
                                 default = nil)
  if valid_611779 != nil:
    section.add "X-Amz-Credential", valid_611779
  var valid_611780 = header.getOrDefault("X-Amz-Security-Token")
  valid_611780 = validateParameter(valid_611780, JString, required = false,
                                 default = nil)
  if valid_611780 != nil:
    section.add "X-Amz-Security-Token", valid_611780
  var valid_611781 = header.getOrDefault("X-Amz-Algorithm")
  valid_611781 = validateParameter(valid_611781, JString, required = false,
                                 default = nil)
  if valid_611781 != nil:
    section.add "X-Amz-Algorithm", valid_611781
  var valid_611782 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611782 = validateParameter(valid_611782, JString, required = false,
                                 default = nil)
  if valid_611782 != nil:
    section.add "X-Amz-SignedHeaders", valid_611782
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611783: Call_GetIndexDocuments_611770; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ## 
  let valid = call_611783.validator(path, query, header, formData, body)
  let scheme = call_611783.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611783.url(scheme.get, call_611783.host, call_611783.base,
                         call_611783.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611783, url, valid)

proc call*(call_611784: Call_GetIndexDocuments_611770; DomainName: string;
          Action: string = "IndexDocuments"; Version: string = "2011-02-01"): Recallable =
  ## getIndexDocuments
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611785 = newJObject()
  add(query_611785, "DomainName", newJString(DomainName))
  add(query_611785, "Action", newJString(Action))
  add(query_611785, "Version", newJString(Version))
  result = call_611784.call(nil, query_611785, nil, nil, nil)

var getIndexDocuments* = Call_GetIndexDocuments_611770(name: "getIndexDocuments",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=IndexDocuments", validator: validate_GetIndexDocuments_611771,
    base: "/", url: url_GetIndexDocuments_611772,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateAvailabilityOptions_611820 = ref object of OpenApiRestCall_610658
proc url_PostUpdateAvailabilityOptions_611822(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateAvailabilityOptions_611821(path: JsonNode; query: JsonNode;
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
  var valid_611823 = query.getOrDefault("Action")
  valid_611823 = validateParameter(valid_611823, JString, required = true, default = newJString(
      "UpdateAvailabilityOptions"))
  if valid_611823 != nil:
    section.add "Action", valid_611823
  var valid_611824 = query.getOrDefault("Version")
  valid_611824 = validateParameter(valid_611824, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_611824 != nil:
    section.add "Version", valid_611824
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
  var valid_611825 = header.getOrDefault("X-Amz-Signature")
  valid_611825 = validateParameter(valid_611825, JString, required = false,
                                 default = nil)
  if valid_611825 != nil:
    section.add "X-Amz-Signature", valid_611825
  var valid_611826 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611826 = validateParameter(valid_611826, JString, required = false,
                                 default = nil)
  if valid_611826 != nil:
    section.add "X-Amz-Content-Sha256", valid_611826
  var valid_611827 = header.getOrDefault("X-Amz-Date")
  valid_611827 = validateParameter(valid_611827, JString, required = false,
                                 default = nil)
  if valid_611827 != nil:
    section.add "X-Amz-Date", valid_611827
  var valid_611828 = header.getOrDefault("X-Amz-Credential")
  valid_611828 = validateParameter(valid_611828, JString, required = false,
                                 default = nil)
  if valid_611828 != nil:
    section.add "X-Amz-Credential", valid_611828
  var valid_611829 = header.getOrDefault("X-Amz-Security-Token")
  valid_611829 = validateParameter(valid_611829, JString, required = false,
                                 default = nil)
  if valid_611829 != nil:
    section.add "X-Amz-Security-Token", valid_611829
  var valid_611830 = header.getOrDefault("X-Amz-Algorithm")
  valid_611830 = validateParameter(valid_611830, JString, required = false,
                                 default = nil)
  if valid_611830 != nil:
    section.add "X-Amz-Algorithm", valid_611830
  var valid_611831 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611831 = validateParameter(valid_611831, JString, required = false,
                                 default = nil)
  if valid_611831 != nil:
    section.add "X-Amz-SignedHeaders", valid_611831
  result.add "header", section
  ## parameters in `formData` object:
  ##   MultiAZ: JBool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `MultiAZ` field"
  var valid_611832 = formData.getOrDefault("MultiAZ")
  valid_611832 = validateParameter(valid_611832, JBool, required = true, default = nil)
  if valid_611832 != nil:
    section.add "MultiAZ", valid_611832
  var valid_611833 = formData.getOrDefault("DomainName")
  valid_611833 = validateParameter(valid_611833, JString, required = true,
                                 default = nil)
  if valid_611833 != nil:
    section.add "DomainName", valid_611833
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611834: Call_PostUpdateAvailabilityOptions_611820; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_611834.validator(path, query, header, formData, body)
  let scheme = call_611834.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611834.url(scheme.get, call_611834.host, call_611834.base,
                         call_611834.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611834, url, valid)

proc call*(call_611835: Call_PostUpdateAvailabilityOptions_611820; MultiAZ: bool;
          DomainName: string; Action: string = "UpdateAvailabilityOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postUpdateAvailabilityOptions
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   MultiAZ: bool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611836 = newJObject()
  var formData_611837 = newJObject()
  add(formData_611837, "MultiAZ", newJBool(MultiAZ))
  add(formData_611837, "DomainName", newJString(DomainName))
  add(query_611836, "Action", newJString(Action))
  add(query_611836, "Version", newJString(Version))
  result = call_611835.call(nil, query_611836, nil, formData_611837, nil)

var postUpdateAvailabilityOptions* = Call_PostUpdateAvailabilityOptions_611820(
    name: "postUpdateAvailabilityOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateAvailabilityOptions",
    validator: validate_PostUpdateAvailabilityOptions_611821, base: "/",
    url: url_PostUpdateAvailabilityOptions_611822,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateAvailabilityOptions_611803 = ref object of OpenApiRestCall_610658
proc url_GetUpdateAvailabilityOptions_611805(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateAvailabilityOptions_611804(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   MultiAZ: JBool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_611806 = query.getOrDefault("DomainName")
  valid_611806 = validateParameter(valid_611806, JString, required = true,
                                 default = nil)
  if valid_611806 != nil:
    section.add "DomainName", valid_611806
  var valid_611807 = query.getOrDefault("Action")
  valid_611807 = validateParameter(valid_611807, JString, required = true, default = newJString(
      "UpdateAvailabilityOptions"))
  if valid_611807 != nil:
    section.add "Action", valid_611807
  var valid_611808 = query.getOrDefault("MultiAZ")
  valid_611808 = validateParameter(valid_611808, JBool, required = true, default = nil)
  if valid_611808 != nil:
    section.add "MultiAZ", valid_611808
  var valid_611809 = query.getOrDefault("Version")
  valid_611809 = validateParameter(valid_611809, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_611809 != nil:
    section.add "Version", valid_611809
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
  var valid_611810 = header.getOrDefault("X-Amz-Signature")
  valid_611810 = validateParameter(valid_611810, JString, required = false,
                                 default = nil)
  if valid_611810 != nil:
    section.add "X-Amz-Signature", valid_611810
  var valid_611811 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611811 = validateParameter(valid_611811, JString, required = false,
                                 default = nil)
  if valid_611811 != nil:
    section.add "X-Amz-Content-Sha256", valid_611811
  var valid_611812 = header.getOrDefault("X-Amz-Date")
  valid_611812 = validateParameter(valid_611812, JString, required = false,
                                 default = nil)
  if valid_611812 != nil:
    section.add "X-Amz-Date", valid_611812
  var valid_611813 = header.getOrDefault("X-Amz-Credential")
  valid_611813 = validateParameter(valid_611813, JString, required = false,
                                 default = nil)
  if valid_611813 != nil:
    section.add "X-Amz-Credential", valid_611813
  var valid_611814 = header.getOrDefault("X-Amz-Security-Token")
  valid_611814 = validateParameter(valid_611814, JString, required = false,
                                 default = nil)
  if valid_611814 != nil:
    section.add "X-Amz-Security-Token", valid_611814
  var valid_611815 = header.getOrDefault("X-Amz-Algorithm")
  valid_611815 = validateParameter(valid_611815, JString, required = false,
                                 default = nil)
  if valid_611815 != nil:
    section.add "X-Amz-Algorithm", valid_611815
  var valid_611816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611816 = validateParameter(valid_611816, JString, required = false,
                                 default = nil)
  if valid_611816 != nil:
    section.add "X-Amz-SignedHeaders", valid_611816
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611817: Call_GetUpdateAvailabilityOptions_611803; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_611817.validator(path, query, header, formData, body)
  let scheme = call_611817.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611817.url(scheme.get, call_611817.host, call_611817.base,
                         call_611817.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611817, url, valid)

proc call*(call_611818: Call_GetUpdateAvailabilityOptions_611803;
          DomainName: string; MultiAZ: bool;
          Action: string = "UpdateAvailabilityOptions";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateAvailabilityOptions
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   MultiAZ: bool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   Version: string (required)
  var query_611819 = newJObject()
  add(query_611819, "DomainName", newJString(DomainName))
  add(query_611819, "Action", newJString(Action))
  add(query_611819, "MultiAZ", newJBool(MultiAZ))
  add(query_611819, "Version", newJString(Version))
  result = call_611818.call(nil, query_611819, nil, nil, nil)

var getUpdateAvailabilityOptions* = Call_GetUpdateAvailabilityOptions_611803(
    name: "getUpdateAvailabilityOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateAvailabilityOptions",
    validator: validate_GetUpdateAvailabilityOptions_611804, base: "/",
    url: url_GetUpdateAvailabilityOptions_611805,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateDefaultSearchField_611855 = ref object of OpenApiRestCall_610658
proc url_PostUpdateDefaultSearchField_611857(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateDefaultSearchField_611856(path: JsonNode; query: JsonNode;
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
  var valid_611858 = query.getOrDefault("Action")
  valid_611858 = validateParameter(valid_611858, JString, required = true, default = newJString(
      "UpdateDefaultSearchField"))
  if valid_611858 != nil:
    section.add "Action", valid_611858
  var valid_611859 = query.getOrDefault("Version")
  valid_611859 = validateParameter(valid_611859, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_611859 != nil:
    section.add "Version", valid_611859
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
  var valid_611860 = header.getOrDefault("X-Amz-Signature")
  valid_611860 = validateParameter(valid_611860, JString, required = false,
                                 default = nil)
  if valid_611860 != nil:
    section.add "X-Amz-Signature", valid_611860
  var valid_611861 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611861 = validateParameter(valid_611861, JString, required = false,
                                 default = nil)
  if valid_611861 != nil:
    section.add "X-Amz-Content-Sha256", valid_611861
  var valid_611862 = header.getOrDefault("X-Amz-Date")
  valid_611862 = validateParameter(valid_611862, JString, required = false,
                                 default = nil)
  if valid_611862 != nil:
    section.add "X-Amz-Date", valid_611862
  var valid_611863 = header.getOrDefault("X-Amz-Credential")
  valid_611863 = validateParameter(valid_611863, JString, required = false,
                                 default = nil)
  if valid_611863 != nil:
    section.add "X-Amz-Credential", valid_611863
  var valid_611864 = header.getOrDefault("X-Amz-Security-Token")
  valid_611864 = validateParameter(valid_611864, JString, required = false,
                                 default = nil)
  if valid_611864 != nil:
    section.add "X-Amz-Security-Token", valid_611864
  var valid_611865 = header.getOrDefault("X-Amz-Algorithm")
  valid_611865 = validateParameter(valid_611865, JString, required = false,
                                 default = nil)
  if valid_611865 != nil:
    section.add "X-Amz-Algorithm", valid_611865
  var valid_611866 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611866 = validateParameter(valid_611866, JString, required = false,
                                 default = nil)
  if valid_611866 != nil:
    section.add "X-Amz-SignedHeaders", valid_611866
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   DefaultSearchField: JString (required)
  ##                     : The text field to search if the search request does not specify which field to search. The default search field is used when search terms are specified with the <code>q</code> parameter, or if a match expression specified with the <code>bq</code> parameter does not constrain the search to a particular field. The default is an empty string, which automatically searches all text fields.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_611867 = formData.getOrDefault("DomainName")
  valid_611867 = validateParameter(valid_611867, JString, required = true,
                                 default = nil)
  if valid_611867 != nil:
    section.add "DomainName", valid_611867
  var valid_611868 = formData.getOrDefault("DefaultSearchField")
  valid_611868 = validateParameter(valid_611868, JString, required = true,
                                 default = nil)
  if valid_611868 != nil:
    section.add "DefaultSearchField", valid_611868
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611869: Call_PostUpdateDefaultSearchField_611855; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ## 
  let valid = call_611869.validator(path, query, header, formData, body)
  let scheme = call_611869.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611869.url(scheme.get, call_611869.host, call_611869.base,
                         call_611869.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611869, url, valid)

proc call*(call_611870: Call_PostUpdateDefaultSearchField_611855;
          DomainName: string; DefaultSearchField: string;
          Action: string = "UpdateDefaultSearchField";
          Version: string = "2011-02-01"): Recallable =
  ## postUpdateDefaultSearchField
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   DefaultSearchField: string (required)
  ##                     : The text field to search if the search request does not specify which field to search. The default search field is used when search terms are specified with the <code>q</code> parameter, or if a match expression specified with the <code>bq</code> parameter does not constrain the search to a particular field. The default is an empty string, which automatically searches all text fields.
  ##   Version: string (required)
  var query_611871 = newJObject()
  var formData_611872 = newJObject()
  add(formData_611872, "DomainName", newJString(DomainName))
  add(query_611871, "Action", newJString(Action))
  add(formData_611872, "DefaultSearchField", newJString(DefaultSearchField))
  add(query_611871, "Version", newJString(Version))
  result = call_611870.call(nil, query_611871, nil, formData_611872, nil)

var postUpdateDefaultSearchField* = Call_PostUpdateDefaultSearchField_611855(
    name: "postUpdateDefaultSearchField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateDefaultSearchField",
    validator: validate_PostUpdateDefaultSearchField_611856, base: "/",
    url: url_PostUpdateDefaultSearchField_611857,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateDefaultSearchField_611838 = ref object of OpenApiRestCall_610658
proc url_GetUpdateDefaultSearchField_611840(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateDefaultSearchField_611839(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   DefaultSearchField: JString (required)
  ##                     : The text field to search if the search request does not specify which field to search. The default search field is used when search terms are specified with the <code>q</code> parameter, or if a match expression specified with the <code>bq</code> parameter does not constrain the search to a particular field. The default is an empty string, which automatically searches all text fields.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_611841 = query.getOrDefault("DomainName")
  valid_611841 = validateParameter(valid_611841, JString, required = true,
                                 default = nil)
  if valid_611841 != nil:
    section.add "DomainName", valid_611841
  var valid_611842 = query.getOrDefault("DefaultSearchField")
  valid_611842 = validateParameter(valid_611842, JString, required = true,
                                 default = nil)
  if valid_611842 != nil:
    section.add "DefaultSearchField", valid_611842
  var valid_611843 = query.getOrDefault("Action")
  valid_611843 = validateParameter(valid_611843, JString, required = true, default = newJString(
      "UpdateDefaultSearchField"))
  if valid_611843 != nil:
    section.add "Action", valid_611843
  var valid_611844 = query.getOrDefault("Version")
  valid_611844 = validateParameter(valid_611844, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_611844 != nil:
    section.add "Version", valid_611844
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
  var valid_611845 = header.getOrDefault("X-Amz-Signature")
  valid_611845 = validateParameter(valid_611845, JString, required = false,
                                 default = nil)
  if valid_611845 != nil:
    section.add "X-Amz-Signature", valid_611845
  var valid_611846 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611846 = validateParameter(valid_611846, JString, required = false,
                                 default = nil)
  if valid_611846 != nil:
    section.add "X-Amz-Content-Sha256", valid_611846
  var valid_611847 = header.getOrDefault("X-Amz-Date")
  valid_611847 = validateParameter(valid_611847, JString, required = false,
                                 default = nil)
  if valid_611847 != nil:
    section.add "X-Amz-Date", valid_611847
  var valid_611848 = header.getOrDefault("X-Amz-Credential")
  valid_611848 = validateParameter(valid_611848, JString, required = false,
                                 default = nil)
  if valid_611848 != nil:
    section.add "X-Amz-Credential", valid_611848
  var valid_611849 = header.getOrDefault("X-Amz-Security-Token")
  valid_611849 = validateParameter(valid_611849, JString, required = false,
                                 default = nil)
  if valid_611849 != nil:
    section.add "X-Amz-Security-Token", valid_611849
  var valid_611850 = header.getOrDefault("X-Amz-Algorithm")
  valid_611850 = validateParameter(valid_611850, JString, required = false,
                                 default = nil)
  if valid_611850 != nil:
    section.add "X-Amz-Algorithm", valid_611850
  var valid_611851 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611851 = validateParameter(valid_611851, JString, required = false,
                                 default = nil)
  if valid_611851 != nil:
    section.add "X-Amz-SignedHeaders", valid_611851
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611852: Call_GetUpdateDefaultSearchField_611838; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ## 
  let valid = call_611852.validator(path, query, header, formData, body)
  let scheme = call_611852.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611852.url(scheme.get, call_611852.host, call_611852.base,
                         call_611852.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611852, url, valid)

proc call*(call_611853: Call_GetUpdateDefaultSearchField_611838;
          DomainName: string; DefaultSearchField: string;
          Action: string = "UpdateDefaultSearchField";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateDefaultSearchField
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   DefaultSearchField: string (required)
  ##                     : The text field to search if the search request does not specify which field to search. The default search field is used when search terms are specified with the <code>q</code> parameter, or if a match expression specified with the <code>bq</code> parameter does not constrain the search to a particular field. The default is an empty string, which automatically searches all text fields.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611854 = newJObject()
  add(query_611854, "DomainName", newJString(DomainName))
  add(query_611854, "DefaultSearchField", newJString(DefaultSearchField))
  add(query_611854, "Action", newJString(Action))
  add(query_611854, "Version", newJString(Version))
  result = call_611853.call(nil, query_611854, nil, nil, nil)

var getUpdateDefaultSearchField* = Call_GetUpdateDefaultSearchField_611838(
    name: "getUpdateDefaultSearchField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateDefaultSearchField",
    validator: validate_GetUpdateDefaultSearchField_611839, base: "/",
    url: url_GetUpdateDefaultSearchField_611840,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateServiceAccessPolicies_611890 = ref object of OpenApiRestCall_610658
proc url_PostUpdateServiceAccessPolicies_611892(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateServiceAccessPolicies_611891(path: JsonNode;
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
  var valid_611893 = query.getOrDefault("Action")
  valid_611893 = validateParameter(valid_611893, JString, required = true, default = newJString(
      "UpdateServiceAccessPolicies"))
  if valid_611893 != nil:
    section.add "Action", valid_611893
  var valid_611894 = query.getOrDefault("Version")
  valid_611894 = validateParameter(valid_611894, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_611894 != nil:
    section.add "Version", valid_611894
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
  var valid_611895 = header.getOrDefault("X-Amz-Signature")
  valid_611895 = validateParameter(valid_611895, JString, required = false,
                                 default = nil)
  if valid_611895 != nil:
    section.add "X-Amz-Signature", valid_611895
  var valid_611896 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611896 = validateParameter(valid_611896, JString, required = false,
                                 default = nil)
  if valid_611896 != nil:
    section.add "X-Amz-Content-Sha256", valid_611896
  var valid_611897 = header.getOrDefault("X-Amz-Date")
  valid_611897 = validateParameter(valid_611897, JString, required = false,
                                 default = nil)
  if valid_611897 != nil:
    section.add "X-Amz-Date", valid_611897
  var valid_611898 = header.getOrDefault("X-Amz-Credential")
  valid_611898 = validateParameter(valid_611898, JString, required = false,
                                 default = nil)
  if valid_611898 != nil:
    section.add "X-Amz-Credential", valid_611898
  var valid_611899 = header.getOrDefault("X-Amz-Security-Token")
  valid_611899 = validateParameter(valid_611899, JString, required = false,
                                 default = nil)
  if valid_611899 != nil:
    section.add "X-Amz-Security-Token", valid_611899
  var valid_611900 = header.getOrDefault("X-Amz-Algorithm")
  valid_611900 = validateParameter(valid_611900, JString, required = false,
                                 default = nil)
  if valid_611900 != nil:
    section.add "X-Amz-Algorithm", valid_611900
  var valid_611901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611901 = validateParameter(valid_611901, JString, required = false,
                                 default = nil)
  if valid_611901 != nil:
    section.add "X-Amz-SignedHeaders", valid_611901
  result.add "header", section
  ## parameters in `formData` object:
  ##   AccessPolicies: JString (required)
  ##                 : <p>An IAM access policy as described in <a 
  ## href="http://docs.aws.amazon.com/IAM/latest/UserGuide/index.html?AccessPolicyLanguage.html" target="_blank">The Access Policy Language</a> in <i>Using AWS Identity and Access Management</i>. The maximum size of an access policy document is 100 KB.</p> <p>Example: <code>{"Statement": [{"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:search/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }}, {"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:documents/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }} ] }</code></p>
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AccessPolicies` field"
  var valid_611902 = formData.getOrDefault("AccessPolicies")
  valid_611902 = validateParameter(valid_611902, JString, required = true,
                                 default = nil)
  if valid_611902 != nil:
    section.add "AccessPolicies", valid_611902
  var valid_611903 = formData.getOrDefault("DomainName")
  valid_611903 = validateParameter(valid_611903, JString, required = true,
                                 default = nil)
  if valid_611903 != nil:
    section.add "DomainName", valid_611903
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611904: Call_PostUpdateServiceAccessPolicies_611890;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ## 
  let valid = call_611904.validator(path, query, header, formData, body)
  let scheme = call_611904.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611904.url(scheme.get, call_611904.host, call_611904.base,
                         call_611904.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611904, url, valid)

proc call*(call_611905: Call_PostUpdateServiceAccessPolicies_611890;
          AccessPolicies: string; DomainName: string;
          Action: string = "UpdateServiceAccessPolicies";
          Version: string = "2011-02-01"): Recallable =
  ## postUpdateServiceAccessPolicies
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ##   AccessPolicies: string (required)
  ##                 : <p>An IAM access policy as described in <a 
  ## href="http://docs.aws.amazon.com/IAM/latest/UserGuide/index.html?AccessPolicyLanguage.html" target="_blank">The Access Policy Language</a> in <i>Using AWS Identity and Access Management</i>. The maximum size of an access policy document is 100 KB.</p> <p>Example: <code>{"Statement": [{"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:search/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }}, {"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:documents/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }} ] }</code></p>
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611906 = newJObject()
  var formData_611907 = newJObject()
  add(formData_611907, "AccessPolicies", newJString(AccessPolicies))
  add(formData_611907, "DomainName", newJString(DomainName))
  add(query_611906, "Action", newJString(Action))
  add(query_611906, "Version", newJString(Version))
  result = call_611905.call(nil, query_611906, nil, formData_611907, nil)

var postUpdateServiceAccessPolicies* = Call_PostUpdateServiceAccessPolicies_611890(
    name: "postUpdateServiceAccessPolicies", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateServiceAccessPolicies",
    validator: validate_PostUpdateServiceAccessPolicies_611891, base: "/",
    url: url_PostUpdateServiceAccessPolicies_611892,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateServiceAccessPolicies_611873 = ref object of OpenApiRestCall_610658
proc url_GetUpdateServiceAccessPolicies_611875(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateServiceAccessPolicies_611874(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   AccessPolicies: JString (required)
  ##                 : <p>An IAM access policy as described in <a 
  ## href="http://docs.aws.amazon.com/IAM/latest/UserGuide/index.html?AccessPolicyLanguage.html" target="_blank">The Access Policy Language</a> in <i>Using AWS Identity and Access Management</i>. The maximum size of an access policy document is 100 KB.</p> <p>Example: <code>{"Statement": [{"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:search/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }}, {"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:documents/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }} ] }</code></p>
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_611876 = query.getOrDefault("DomainName")
  valid_611876 = validateParameter(valid_611876, JString, required = true,
                                 default = nil)
  if valid_611876 != nil:
    section.add "DomainName", valid_611876
  var valid_611877 = query.getOrDefault("Action")
  valid_611877 = validateParameter(valid_611877, JString, required = true, default = newJString(
      "UpdateServiceAccessPolicies"))
  if valid_611877 != nil:
    section.add "Action", valid_611877
  var valid_611878 = query.getOrDefault("Version")
  valid_611878 = validateParameter(valid_611878, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_611878 != nil:
    section.add "Version", valid_611878
  var valid_611879 = query.getOrDefault("AccessPolicies")
  valid_611879 = validateParameter(valid_611879, JString, required = true,
                                 default = nil)
  if valid_611879 != nil:
    section.add "AccessPolicies", valid_611879
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
  var valid_611880 = header.getOrDefault("X-Amz-Signature")
  valid_611880 = validateParameter(valid_611880, JString, required = false,
                                 default = nil)
  if valid_611880 != nil:
    section.add "X-Amz-Signature", valid_611880
  var valid_611881 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611881 = validateParameter(valid_611881, JString, required = false,
                                 default = nil)
  if valid_611881 != nil:
    section.add "X-Amz-Content-Sha256", valid_611881
  var valid_611882 = header.getOrDefault("X-Amz-Date")
  valid_611882 = validateParameter(valid_611882, JString, required = false,
                                 default = nil)
  if valid_611882 != nil:
    section.add "X-Amz-Date", valid_611882
  var valid_611883 = header.getOrDefault("X-Amz-Credential")
  valid_611883 = validateParameter(valid_611883, JString, required = false,
                                 default = nil)
  if valid_611883 != nil:
    section.add "X-Amz-Credential", valid_611883
  var valid_611884 = header.getOrDefault("X-Amz-Security-Token")
  valid_611884 = validateParameter(valid_611884, JString, required = false,
                                 default = nil)
  if valid_611884 != nil:
    section.add "X-Amz-Security-Token", valid_611884
  var valid_611885 = header.getOrDefault("X-Amz-Algorithm")
  valid_611885 = validateParameter(valid_611885, JString, required = false,
                                 default = nil)
  if valid_611885 != nil:
    section.add "X-Amz-Algorithm", valid_611885
  var valid_611886 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611886 = validateParameter(valid_611886, JString, required = false,
                                 default = nil)
  if valid_611886 != nil:
    section.add "X-Amz-SignedHeaders", valid_611886
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611887: Call_GetUpdateServiceAccessPolicies_611873; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ## 
  let valid = call_611887.validator(path, query, header, formData, body)
  let scheme = call_611887.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611887.url(scheme.get, call_611887.host, call_611887.base,
                         call_611887.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611887, url, valid)

proc call*(call_611888: Call_GetUpdateServiceAccessPolicies_611873;
          DomainName: string; AccessPolicies: string;
          Action: string = "UpdateServiceAccessPolicies";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateServiceAccessPolicies
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   AccessPolicies: string (required)
  ##                 : <p>An IAM access policy as described in <a 
  ## href="http://docs.aws.amazon.com/IAM/latest/UserGuide/index.html?AccessPolicyLanguage.html" target="_blank">The Access Policy Language</a> in <i>Using AWS Identity and Access Management</i>. The maximum size of an access policy document is 100 KB.</p> <p>Example: <code>{"Statement": [{"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:search/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }}, {"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:documents/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }} ] }</code></p>
  var query_611889 = newJObject()
  add(query_611889, "DomainName", newJString(DomainName))
  add(query_611889, "Action", newJString(Action))
  add(query_611889, "Version", newJString(Version))
  add(query_611889, "AccessPolicies", newJString(AccessPolicies))
  result = call_611888.call(nil, query_611889, nil, nil, nil)

var getUpdateServiceAccessPolicies* = Call_GetUpdateServiceAccessPolicies_611873(
    name: "getUpdateServiceAccessPolicies", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateServiceAccessPolicies",
    validator: validate_GetUpdateServiceAccessPolicies_611874, base: "/",
    url: url_GetUpdateServiceAccessPolicies_611875,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateStemmingOptions_611925 = ref object of OpenApiRestCall_610658
proc url_PostUpdateStemmingOptions_611927(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateStemmingOptions_611926(path: JsonNode; query: JsonNode;
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
  var valid_611928 = query.getOrDefault("Action")
  valid_611928 = validateParameter(valid_611928, JString, required = true,
                                 default = newJString("UpdateStemmingOptions"))
  if valid_611928 != nil:
    section.add "Action", valid_611928
  var valid_611929 = query.getOrDefault("Version")
  valid_611929 = validateParameter(valid_611929, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_611929 != nil:
    section.add "Version", valid_611929
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
  var valid_611930 = header.getOrDefault("X-Amz-Signature")
  valid_611930 = validateParameter(valid_611930, JString, required = false,
                                 default = nil)
  if valid_611930 != nil:
    section.add "X-Amz-Signature", valid_611930
  var valid_611931 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611931 = validateParameter(valid_611931, JString, required = false,
                                 default = nil)
  if valid_611931 != nil:
    section.add "X-Amz-Content-Sha256", valid_611931
  var valid_611932 = header.getOrDefault("X-Amz-Date")
  valid_611932 = validateParameter(valid_611932, JString, required = false,
                                 default = nil)
  if valid_611932 != nil:
    section.add "X-Amz-Date", valid_611932
  var valid_611933 = header.getOrDefault("X-Amz-Credential")
  valid_611933 = validateParameter(valid_611933, JString, required = false,
                                 default = nil)
  if valid_611933 != nil:
    section.add "X-Amz-Credential", valid_611933
  var valid_611934 = header.getOrDefault("X-Amz-Security-Token")
  valid_611934 = validateParameter(valid_611934, JString, required = false,
                                 default = nil)
  if valid_611934 != nil:
    section.add "X-Amz-Security-Token", valid_611934
  var valid_611935 = header.getOrDefault("X-Amz-Algorithm")
  valid_611935 = validateParameter(valid_611935, JString, required = false,
                                 default = nil)
  if valid_611935 != nil:
    section.add "X-Amz-Algorithm", valid_611935
  var valid_611936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611936 = validateParameter(valid_611936, JString, required = false,
                                 default = nil)
  if valid_611936 != nil:
    section.add "X-Amz-SignedHeaders", valid_611936
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Stems: JString (required)
  ##        : Maps terms to their stems, serialized as a JSON document. The document has a single object with one property "stems" whose value is an object mapping terms to their stems. The maximum size of a stemming document is 500 KB. Example: <code>{ "stems": {"people": "person", "walking": "walk"} }</code>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_611937 = formData.getOrDefault("DomainName")
  valid_611937 = validateParameter(valid_611937, JString, required = true,
                                 default = nil)
  if valid_611937 != nil:
    section.add "DomainName", valid_611937
  var valid_611938 = formData.getOrDefault("Stems")
  valid_611938 = validateParameter(valid_611938, JString, required = true,
                                 default = nil)
  if valid_611938 != nil:
    section.add "Stems", valid_611938
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611939: Call_PostUpdateStemmingOptions_611925; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ## 
  let valid = call_611939.validator(path, query, header, formData, body)
  let scheme = call_611939.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611939.url(scheme.get, call_611939.host, call_611939.base,
                         call_611939.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611939, url, valid)

proc call*(call_611940: Call_PostUpdateStemmingOptions_611925; DomainName: string;
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
  var query_611941 = newJObject()
  var formData_611942 = newJObject()
  add(formData_611942, "DomainName", newJString(DomainName))
  add(query_611941, "Action", newJString(Action))
  add(formData_611942, "Stems", newJString(Stems))
  add(query_611941, "Version", newJString(Version))
  result = call_611940.call(nil, query_611941, nil, formData_611942, nil)

var postUpdateStemmingOptions* = Call_PostUpdateStemmingOptions_611925(
    name: "postUpdateStemmingOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateStemmingOptions",
    validator: validate_PostUpdateStemmingOptions_611926, base: "/",
    url: url_PostUpdateStemmingOptions_611927,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateStemmingOptions_611908 = ref object of OpenApiRestCall_610658
proc url_GetUpdateStemmingOptions_611910(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateStemmingOptions_611909(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Stems: JString (required)
  ##        : Maps terms to their stems, serialized as a JSON document. The document has a single object with one property "stems" whose value is an object mapping terms to their stems. The maximum size of a stemming document is 500 KB. Example: <code>{ "stems": {"people": "person", "walking": "walk"} }</code>
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Stems` field"
  var valid_611911 = query.getOrDefault("Stems")
  valid_611911 = validateParameter(valid_611911, JString, required = true,
                                 default = nil)
  if valid_611911 != nil:
    section.add "Stems", valid_611911
  var valid_611912 = query.getOrDefault("DomainName")
  valid_611912 = validateParameter(valid_611912, JString, required = true,
                                 default = nil)
  if valid_611912 != nil:
    section.add "DomainName", valid_611912
  var valid_611913 = query.getOrDefault("Action")
  valid_611913 = validateParameter(valid_611913, JString, required = true,
                                 default = newJString("UpdateStemmingOptions"))
  if valid_611913 != nil:
    section.add "Action", valid_611913
  var valid_611914 = query.getOrDefault("Version")
  valid_611914 = validateParameter(valid_611914, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_611914 != nil:
    section.add "Version", valid_611914
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
  var valid_611915 = header.getOrDefault("X-Amz-Signature")
  valid_611915 = validateParameter(valid_611915, JString, required = false,
                                 default = nil)
  if valid_611915 != nil:
    section.add "X-Amz-Signature", valid_611915
  var valid_611916 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611916 = validateParameter(valid_611916, JString, required = false,
                                 default = nil)
  if valid_611916 != nil:
    section.add "X-Amz-Content-Sha256", valid_611916
  var valid_611917 = header.getOrDefault("X-Amz-Date")
  valid_611917 = validateParameter(valid_611917, JString, required = false,
                                 default = nil)
  if valid_611917 != nil:
    section.add "X-Amz-Date", valid_611917
  var valid_611918 = header.getOrDefault("X-Amz-Credential")
  valid_611918 = validateParameter(valid_611918, JString, required = false,
                                 default = nil)
  if valid_611918 != nil:
    section.add "X-Amz-Credential", valid_611918
  var valid_611919 = header.getOrDefault("X-Amz-Security-Token")
  valid_611919 = validateParameter(valid_611919, JString, required = false,
                                 default = nil)
  if valid_611919 != nil:
    section.add "X-Amz-Security-Token", valid_611919
  var valid_611920 = header.getOrDefault("X-Amz-Algorithm")
  valid_611920 = validateParameter(valid_611920, JString, required = false,
                                 default = nil)
  if valid_611920 != nil:
    section.add "X-Amz-Algorithm", valid_611920
  var valid_611921 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611921 = validateParameter(valid_611921, JString, required = false,
                                 default = nil)
  if valid_611921 != nil:
    section.add "X-Amz-SignedHeaders", valid_611921
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611922: Call_GetUpdateStemmingOptions_611908; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ## 
  let valid = call_611922.validator(path, query, header, formData, body)
  let scheme = call_611922.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611922.url(scheme.get, call_611922.host, call_611922.base,
                         call_611922.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611922, url, valid)

proc call*(call_611923: Call_GetUpdateStemmingOptions_611908; Stems: string;
          DomainName: string; Action: string = "UpdateStemmingOptions";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateStemmingOptions
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ##   Stems: string (required)
  ##        : Maps terms to their stems, serialized as a JSON document. The document has a single object with one property "stems" whose value is an object mapping terms to their stems. The maximum size of a stemming document is 500 KB. Example: <code>{ "stems": {"people": "person", "walking": "walk"} }</code>
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611924 = newJObject()
  add(query_611924, "Stems", newJString(Stems))
  add(query_611924, "DomainName", newJString(DomainName))
  add(query_611924, "Action", newJString(Action))
  add(query_611924, "Version", newJString(Version))
  result = call_611923.call(nil, query_611924, nil, nil, nil)

var getUpdateStemmingOptions* = Call_GetUpdateStemmingOptions_611908(
    name: "getUpdateStemmingOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateStemmingOptions",
    validator: validate_GetUpdateStemmingOptions_611909, base: "/",
    url: url_GetUpdateStemmingOptions_611910, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateStopwordOptions_611960 = ref object of OpenApiRestCall_610658
proc url_PostUpdateStopwordOptions_611962(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateStopwordOptions_611961(path: JsonNode; query: JsonNode;
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
  var valid_611963 = query.getOrDefault("Action")
  valid_611963 = validateParameter(valid_611963, JString, required = true,
                                 default = newJString("UpdateStopwordOptions"))
  if valid_611963 != nil:
    section.add "Action", valid_611963
  var valid_611964 = query.getOrDefault("Version")
  valid_611964 = validateParameter(valid_611964, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_611964 != nil:
    section.add "Version", valid_611964
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
  var valid_611965 = header.getOrDefault("X-Amz-Signature")
  valid_611965 = validateParameter(valid_611965, JString, required = false,
                                 default = nil)
  if valid_611965 != nil:
    section.add "X-Amz-Signature", valid_611965
  var valid_611966 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611966 = validateParameter(valid_611966, JString, required = false,
                                 default = nil)
  if valid_611966 != nil:
    section.add "X-Amz-Content-Sha256", valid_611966
  var valid_611967 = header.getOrDefault("X-Amz-Date")
  valid_611967 = validateParameter(valid_611967, JString, required = false,
                                 default = nil)
  if valid_611967 != nil:
    section.add "X-Amz-Date", valid_611967
  var valid_611968 = header.getOrDefault("X-Amz-Credential")
  valid_611968 = validateParameter(valid_611968, JString, required = false,
                                 default = nil)
  if valid_611968 != nil:
    section.add "X-Amz-Credential", valid_611968
  var valid_611969 = header.getOrDefault("X-Amz-Security-Token")
  valid_611969 = validateParameter(valid_611969, JString, required = false,
                                 default = nil)
  if valid_611969 != nil:
    section.add "X-Amz-Security-Token", valid_611969
  var valid_611970 = header.getOrDefault("X-Amz-Algorithm")
  valid_611970 = validateParameter(valid_611970, JString, required = false,
                                 default = nil)
  if valid_611970 != nil:
    section.add "X-Amz-Algorithm", valid_611970
  var valid_611971 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611971 = validateParameter(valid_611971, JString, required = false,
                                 default = nil)
  if valid_611971 != nil:
    section.add "X-Amz-SignedHeaders", valid_611971
  result.add "header", section
  ## parameters in `formData` object:
  ##   Stopwords: JString (required)
  ##            : Lists stopwords serialized as a JSON document. The document has a single object with one property "stopwords" whose value is an array of strings. The maximum size of a stopwords document is 10 KB. Example: <code>{ "stopwords": ["a", "an", "the", "of"] }</code>
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Stopwords` field"
  var valid_611972 = formData.getOrDefault("Stopwords")
  valid_611972 = validateParameter(valid_611972, JString, required = true,
                                 default = nil)
  if valid_611972 != nil:
    section.add "Stopwords", valid_611972
  var valid_611973 = formData.getOrDefault("DomainName")
  valid_611973 = validateParameter(valid_611973, JString, required = true,
                                 default = nil)
  if valid_611973 != nil:
    section.add "DomainName", valid_611973
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611974: Call_PostUpdateStopwordOptions_611960; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ## 
  let valid = call_611974.validator(path, query, header, formData, body)
  let scheme = call_611974.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611974.url(scheme.get, call_611974.host, call_611974.base,
                         call_611974.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611974, url, valid)

proc call*(call_611975: Call_PostUpdateStopwordOptions_611960; Stopwords: string;
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
  var query_611976 = newJObject()
  var formData_611977 = newJObject()
  add(formData_611977, "Stopwords", newJString(Stopwords))
  add(formData_611977, "DomainName", newJString(DomainName))
  add(query_611976, "Action", newJString(Action))
  add(query_611976, "Version", newJString(Version))
  result = call_611975.call(nil, query_611976, nil, formData_611977, nil)

var postUpdateStopwordOptions* = Call_PostUpdateStopwordOptions_611960(
    name: "postUpdateStopwordOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateStopwordOptions",
    validator: validate_PostUpdateStopwordOptions_611961, base: "/",
    url: url_PostUpdateStopwordOptions_611962,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateStopwordOptions_611943 = ref object of OpenApiRestCall_610658
proc url_GetUpdateStopwordOptions_611945(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateStopwordOptions_611944(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Stopwords: JString (required)
  ##            : Lists stopwords serialized as a JSON document. The document has a single object with one property "stopwords" whose value is an array of strings. The maximum size of a stopwords document is 10 KB. Example: <code>{ "stopwords": ["a", "an", "the", "of"] }</code>
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Stopwords` field"
  var valid_611946 = query.getOrDefault("Stopwords")
  valid_611946 = validateParameter(valid_611946, JString, required = true,
                                 default = nil)
  if valid_611946 != nil:
    section.add "Stopwords", valid_611946
  var valid_611947 = query.getOrDefault("DomainName")
  valid_611947 = validateParameter(valid_611947, JString, required = true,
                                 default = nil)
  if valid_611947 != nil:
    section.add "DomainName", valid_611947
  var valid_611948 = query.getOrDefault("Action")
  valid_611948 = validateParameter(valid_611948, JString, required = true,
                                 default = newJString("UpdateStopwordOptions"))
  if valid_611948 != nil:
    section.add "Action", valid_611948
  var valid_611949 = query.getOrDefault("Version")
  valid_611949 = validateParameter(valid_611949, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_611949 != nil:
    section.add "Version", valid_611949
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
  var valid_611950 = header.getOrDefault("X-Amz-Signature")
  valid_611950 = validateParameter(valid_611950, JString, required = false,
                                 default = nil)
  if valid_611950 != nil:
    section.add "X-Amz-Signature", valid_611950
  var valid_611951 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611951 = validateParameter(valid_611951, JString, required = false,
                                 default = nil)
  if valid_611951 != nil:
    section.add "X-Amz-Content-Sha256", valid_611951
  var valid_611952 = header.getOrDefault("X-Amz-Date")
  valid_611952 = validateParameter(valid_611952, JString, required = false,
                                 default = nil)
  if valid_611952 != nil:
    section.add "X-Amz-Date", valid_611952
  var valid_611953 = header.getOrDefault("X-Amz-Credential")
  valid_611953 = validateParameter(valid_611953, JString, required = false,
                                 default = nil)
  if valid_611953 != nil:
    section.add "X-Amz-Credential", valid_611953
  var valid_611954 = header.getOrDefault("X-Amz-Security-Token")
  valid_611954 = validateParameter(valid_611954, JString, required = false,
                                 default = nil)
  if valid_611954 != nil:
    section.add "X-Amz-Security-Token", valid_611954
  var valid_611955 = header.getOrDefault("X-Amz-Algorithm")
  valid_611955 = validateParameter(valid_611955, JString, required = false,
                                 default = nil)
  if valid_611955 != nil:
    section.add "X-Amz-Algorithm", valid_611955
  var valid_611956 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611956 = validateParameter(valid_611956, JString, required = false,
                                 default = nil)
  if valid_611956 != nil:
    section.add "X-Amz-SignedHeaders", valid_611956
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611957: Call_GetUpdateStopwordOptions_611943; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ## 
  let valid = call_611957.validator(path, query, header, formData, body)
  let scheme = call_611957.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611957.url(scheme.get, call_611957.host, call_611957.base,
                         call_611957.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611957, url, valid)

proc call*(call_611958: Call_GetUpdateStopwordOptions_611943; Stopwords: string;
          DomainName: string; Action: string = "UpdateStopwordOptions";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateStopwordOptions
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ##   Stopwords: string (required)
  ##            : Lists stopwords serialized as a JSON document. The document has a single object with one property "stopwords" whose value is an array of strings. The maximum size of a stopwords document is 10 KB. Example: <code>{ "stopwords": ["a", "an", "the", "of"] }</code>
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611959 = newJObject()
  add(query_611959, "Stopwords", newJString(Stopwords))
  add(query_611959, "DomainName", newJString(DomainName))
  add(query_611959, "Action", newJString(Action))
  add(query_611959, "Version", newJString(Version))
  result = call_611958.call(nil, query_611959, nil, nil, nil)

var getUpdateStopwordOptions* = Call_GetUpdateStopwordOptions_611943(
    name: "getUpdateStopwordOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateStopwordOptions",
    validator: validate_GetUpdateStopwordOptions_611944, base: "/",
    url: url_GetUpdateStopwordOptions_611945, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateSynonymOptions_611995 = ref object of OpenApiRestCall_610658
proc url_PostUpdateSynonymOptions_611997(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateSynonymOptions_611996(path: JsonNode; query: JsonNode;
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
  var valid_611998 = query.getOrDefault("Action")
  valid_611998 = validateParameter(valid_611998, JString, required = true,
                                 default = newJString("UpdateSynonymOptions"))
  if valid_611998 != nil:
    section.add "Action", valid_611998
  var valid_611999 = query.getOrDefault("Version")
  valid_611999 = validateParameter(valid_611999, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_611999 != nil:
    section.add "Version", valid_611999
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
  var valid_612000 = header.getOrDefault("X-Amz-Signature")
  valid_612000 = validateParameter(valid_612000, JString, required = false,
                                 default = nil)
  if valid_612000 != nil:
    section.add "X-Amz-Signature", valid_612000
  var valid_612001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612001 = validateParameter(valid_612001, JString, required = false,
                                 default = nil)
  if valid_612001 != nil:
    section.add "X-Amz-Content-Sha256", valid_612001
  var valid_612002 = header.getOrDefault("X-Amz-Date")
  valid_612002 = validateParameter(valid_612002, JString, required = false,
                                 default = nil)
  if valid_612002 != nil:
    section.add "X-Amz-Date", valid_612002
  var valid_612003 = header.getOrDefault("X-Amz-Credential")
  valid_612003 = validateParameter(valid_612003, JString, required = false,
                                 default = nil)
  if valid_612003 != nil:
    section.add "X-Amz-Credential", valid_612003
  var valid_612004 = header.getOrDefault("X-Amz-Security-Token")
  valid_612004 = validateParameter(valid_612004, JString, required = false,
                                 default = nil)
  if valid_612004 != nil:
    section.add "X-Amz-Security-Token", valid_612004
  var valid_612005 = header.getOrDefault("X-Amz-Algorithm")
  valid_612005 = validateParameter(valid_612005, JString, required = false,
                                 default = nil)
  if valid_612005 != nil:
    section.add "X-Amz-Algorithm", valid_612005
  var valid_612006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612006 = validateParameter(valid_612006, JString, required = false,
                                 default = nil)
  if valid_612006 != nil:
    section.add "X-Amz-SignedHeaders", valid_612006
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Synonyms: JString (required)
  ##           : Maps terms to their synonyms, serialized as a JSON document. The document has a single object with one property "synonyms" whose value is an object mapping terms to their synonyms. Each synonym is a simple string or an array of strings. The maximum size of a stopwords document is 100 KB. Example: <code>{ "synonyms": {"cat": ["feline", "kitten"], "puppy": "dog"} }</code>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_612007 = formData.getOrDefault("DomainName")
  valid_612007 = validateParameter(valid_612007, JString, required = true,
                                 default = nil)
  if valid_612007 != nil:
    section.add "DomainName", valid_612007
  var valid_612008 = formData.getOrDefault("Synonyms")
  valid_612008 = validateParameter(valid_612008, JString, required = true,
                                 default = nil)
  if valid_612008 != nil:
    section.add "Synonyms", valid_612008
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612009: Call_PostUpdateSynonymOptions_611995; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ## 
  let valid = call_612009.validator(path, query, header, formData, body)
  let scheme = call_612009.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612009.url(scheme.get, call_612009.host, call_612009.base,
                         call_612009.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612009, url, valid)

proc call*(call_612010: Call_PostUpdateSynonymOptions_611995; DomainName: string;
          Synonyms: string; Action: string = "UpdateSynonymOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postUpdateSynonymOptions
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Synonyms: string (required)
  ##           : Maps terms to their synonyms, serialized as a JSON document. The document has a single object with one property "synonyms" whose value is an object mapping terms to their synonyms. Each synonym is a simple string or an array of strings. The maximum size of a stopwords document is 100 KB. Example: <code>{ "synonyms": {"cat": ["feline", "kitten"], "puppy": "dog"} }</code>
  ##   Version: string (required)
  var query_612011 = newJObject()
  var formData_612012 = newJObject()
  add(formData_612012, "DomainName", newJString(DomainName))
  add(query_612011, "Action", newJString(Action))
  add(formData_612012, "Synonyms", newJString(Synonyms))
  add(query_612011, "Version", newJString(Version))
  result = call_612010.call(nil, query_612011, nil, formData_612012, nil)

var postUpdateSynonymOptions* = Call_PostUpdateSynonymOptions_611995(
    name: "postUpdateSynonymOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateSynonymOptions",
    validator: validate_PostUpdateSynonymOptions_611996, base: "/",
    url: url_PostUpdateSynonymOptions_611997, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateSynonymOptions_611978 = ref object of OpenApiRestCall_610658
proc url_GetUpdateSynonymOptions_611980(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateSynonymOptions_611979(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Synonyms: JString (required)
  ##           : Maps terms to their synonyms, serialized as a JSON document. The document has a single object with one property "synonyms" whose value is an object mapping terms to their synonyms. Each synonym is a simple string or an array of strings. The maximum size of a stopwords document is 100 KB. Example: <code>{ "synonyms": {"cat": ["feline", "kitten"], "puppy": "dog"} }</code>
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Synonyms` field"
  var valid_611981 = query.getOrDefault("Synonyms")
  valid_611981 = validateParameter(valid_611981, JString, required = true,
                                 default = nil)
  if valid_611981 != nil:
    section.add "Synonyms", valid_611981
  var valid_611982 = query.getOrDefault("DomainName")
  valid_611982 = validateParameter(valid_611982, JString, required = true,
                                 default = nil)
  if valid_611982 != nil:
    section.add "DomainName", valid_611982
  var valid_611983 = query.getOrDefault("Action")
  valid_611983 = validateParameter(valid_611983, JString, required = true,
                                 default = newJString("UpdateSynonymOptions"))
  if valid_611983 != nil:
    section.add "Action", valid_611983
  var valid_611984 = query.getOrDefault("Version")
  valid_611984 = validateParameter(valid_611984, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_611984 != nil:
    section.add "Version", valid_611984
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
  var valid_611985 = header.getOrDefault("X-Amz-Signature")
  valid_611985 = validateParameter(valid_611985, JString, required = false,
                                 default = nil)
  if valid_611985 != nil:
    section.add "X-Amz-Signature", valid_611985
  var valid_611986 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611986 = validateParameter(valid_611986, JString, required = false,
                                 default = nil)
  if valid_611986 != nil:
    section.add "X-Amz-Content-Sha256", valid_611986
  var valid_611987 = header.getOrDefault("X-Amz-Date")
  valid_611987 = validateParameter(valid_611987, JString, required = false,
                                 default = nil)
  if valid_611987 != nil:
    section.add "X-Amz-Date", valid_611987
  var valid_611988 = header.getOrDefault("X-Amz-Credential")
  valid_611988 = validateParameter(valid_611988, JString, required = false,
                                 default = nil)
  if valid_611988 != nil:
    section.add "X-Amz-Credential", valid_611988
  var valid_611989 = header.getOrDefault("X-Amz-Security-Token")
  valid_611989 = validateParameter(valid_611989, JString, required = false,
                                 default = nil)
  if valid_611989 != nil:
    section.add "X-Amz-Security-Token", valid_611989
  var valid_611990 = header.getOrDefault("X-Amz-Algorithm")
  valid_611990 = validateParameter(valid_611990, JString, required = false,
                                 default = nil)
  if valid_611990 != nil:
    section.add "X-Amz-Algorithm", valid_611990
  var valid_611991 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611991 = validateParameter(valid_611991, JString, required = false,
                                 default = nil)
  if valid_611991 != nil:
    section.add "X-Amz-SignedHeaders", valid_611991
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611992: Call_GetUpdateSynonymOptions_611978; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ## 
  let valid = call_611992.validator(path, query, header, formData, body)
  let scheme = call_611992.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611992.url(scheme.get, call_611992.host, call_611992.base,
                         call_611992.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611992, url, valid)

proc call*(call_611993: Call_GetUpdateSynonymOptions_611978; Synonyms: string;
          DomainName: string; Action: string = "UpdateSynonymOptions";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateSynonymOptions
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ##   Synonyms: string (required)
  ##           : Maps terms to their synonyms, serialized as a JSON document. The document has a single object with one property "synonyms" whose value is an object mapping terms to their synonyms. Each synonym is a simple string or an array of strings. The maximum size of a stopwords document is 100 KB. Example: <code>{ "synonyms": {"cat": ["feline", "kitten"], "puppy": "dog"} }</code>
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_611994 = newJObject()
  add(query_611994, "Synonyms", newJString(Synonyms))
  add(query_611994, "DomainName", newJString(DomainName))
  add(query_611994, "Action", newJString(Action))
  add(query_611994, "Version", newJString(Version))
  result = call_611993.call(nil, query_611994, nil, nil, nil)

var getUpdateSynonymOptions* = Call_GetUpdateSynonymOptions_611978(
    name: "getUpdateSynonymOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateSynonymOptions",
    validator: validate_GetUpdateSynonymOptions_611979, base: "/",
    url: url_GetUpdateSynonymOptions_611980, schemes: {Scheme.Https, Scheme.Http})
export
  rest

type
  EnvKind = enum
    BakeIntoBinary = "Baking $1 into the binary",
    FetchFromEnv = "Fetch $1 from the environment"
template sloppyConst(via: EnvKind; name: untyped): untyped =
  import
    macros

  const
    name {.strdefine.}: string = case via
    of BakeIntoBinary:
      getEnv(astToStr(name), "")
    of FetchFromEnv:
      ""
  static :
    let msg = block:
      if name == "":
        "Missing $1 in the environment"
      else:
        $via
    warning msg % [astToStr(name)]

sloppyConst FetchFromEnv, AWS_ACCESS_KEY_ID
sloppyConst FetchFromEnv, AWS_SECRET_ACCESS_KEY
sloppyConst BakeIntoBinary, AWS_REGION
sloppyConst FetchFromEnv, AWS_ACCOUNT_ID
proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", AWS_ACCESS_KEY_ID)
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", AWS_SECRET_ACCESS_KEY)
    region = os.getEnv("AWS_REGION", AWS_REGION)
  assert secret != "", "need $AWS_SECRET_ACCESS_KEY in environment"
  assert access != "", "need $AWS_ACCESS_KEY_ID in environment"
  assert region != "", "need $AWS_REGION in environment"
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

type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  headers[$ContentSha256] = hash(text, SHA256)
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
